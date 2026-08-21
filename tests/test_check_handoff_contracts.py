"""Guard scripts/check_handoff_contracts.py's pure DDL/CTE parsing helpers.

That script is a BLOCKING ci.yml gate whose three checks all rest on a hand-rolled scan of
bigquery/*.sql text: CHECK A diffs ops/handoff_contracts.yaml against the `allowed_map` CTE in
bigquery/180, and CHECK B derives each write target's NOT NULL/no-default column list from a
CREATE TABLE body. Every one of those scans FAILS OPEN when it mis-parses — a swallowed column is
simply a column the plan is no longer required to name, with nothing printed — so the parsers need
their own regression net rather than only the end-to-end "the real repo still passes" signal.

The specific rot these pin: `strip_sql_comments()` (whose output all of these consume) copies string
literals through verbatim by design, so a single `>` or `)` inside an OPTIONS(description="...")
free-text used to be counted as structure and made every column after it invisible. This repo's
descriptions already carry parentheses and its prose uses `>=`/`->` constantly, so that was a live
near-miss, not a hypothetical.

Bodies here are small synthetic fixtures, so no assertion depends on the real tree's evolving
contents — except the one live guard, which pins only that the real bigquery/180 still parses into a
non-empty lane map.
"""
from conftest import load_module_from_path

ch = load_module_from_path("check_handoff_contracts", "scripts", "check_handoff_contracts.py")


# ---- _find_matching_paren -------------------------------------------------------------------

def test_find_matching_paren_simple_and_nested():
    assert ch._find_matching_paren("(a)", 0) == 2
    text = "x (a, (b, c), d) y"
    assert ch._find_matching_paren(text, 2) == 15


def test_find_matching_paren_returns_minus_one_when_never_closed():
    assert ch._find_matching_paren("(a, (b)", 0) == -1


def test_find_matching_paren_ignores_parens_inside_string_literals():
    # An unbalanced `)` in a quoted description used to close the body early and truncate it.
    text = 'CREATE TABLE t (a STRING OPTIONS(description="close ) paren"), b STRING)'
    open_idx = text.index("(")
    assert ch._find_matching_paren(text, open_idx) == len(text) - 1
    single = "t ('a ( ( b', c)"
    assert ch._find_matching_paren(single, 2) == len(single) - 1


def test_find_matching_paren_handles_escaped_and_triple_quotes():
    text = 'f("a \\" ) still in the literal", b)'
    assert ch._find_matching_paren(text, 1) == len(text) - 1
    triple = 'f("""a ) b "" c""", d)'
    assert ch._find_matching_paren(triple, 1) == len(triple) - 1


# ---- _split_top_level_commas ----------------------------------------------------------------

def test_split_top_level_commas_treats_parens_brackets_and_generics_as_nesting():
    parts = [p.strip() for p in ch._split_top_level_commas(
        "a INT64, b STRUCT<x INT64, y STRING>, c ARRAY<STRING>, d NUMERIC(10, 2)")]
    assert parts == ["a INT64", "b STRUCT<x INT64, y STRING>", "c ARRAY<STRING>", "d NUMERIC(10, 2)"]


def test_split_top_level_commas_is_quote_aware():
    body = ('a STRING OPTIONS(description="fires when drawdown > 20% (of NAV) [sic]"), '
            'b STRING, c STRING')
    parts = [p.strip() for p in ch._split_top_level_commas(body)]
    assert len(parts) == 3
    assert parts[1] == "b STRING"
    assert parts[2] == "c STRING"


def test_split_top_level_commas_survives_an_apostrophe_inside_a_double_quoted_literal():
    # An odd number of single quotes: a naive open/close toggle would swallow the rest of the body.
    body = 'a STRING OPTIONS(description="don\'t drop the tail"), b STRING, c STRING'
    parts = [p.strip() for p in ch._split_top_level_commas(body)]
    assert parts[1] == "b STRING"
    assert parts[2] == "c STRING"


# ---- required_not_null_columns --------------------------------------------------------------

BODY = """
  event_id STRING NOT NULL,
  note STRING OPTIONS(description="fires when drawdown > 20% of NAV"),
  strategy_code STRING NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  nullable_col STRING,
  payload STRUCT<a INT64, b STRING> NOT NULL,
  change_key STRING NOT NULL,
  PRIMARY KEY (event_id) NOT ENFORCED
"""


def test_required_not_null_columns_over_a_synthetic_body():
    assert ch.required_not_null_columns(BODY) == [
        "event_id", "strategy_code", "payload", "change_key",
    ]


def test_required_not_null_columns_ignores_constraint_words_inside_a_description():
    body = ('a STRING OPTIONS(description="this column is NOT NULL by convention and has no DEFAULT"), '
            'b STRING NOT NULL')
    assert ch.required_not_null_columns(body) == ["b"]


# ---- parse_allowed_map ----------------------------------------------------------------------

def _sql(tmp_path, text):
    path = tmp_path / "180_fixture.sql"
    path.write_text(text, encoding="utf-8")
    return str(path)


ALLOWED_MAP_SQL = """
CREATE OR REPLACE VIEW `stock-trading-498512.state.queue_venue_claim_unwired` AS
WITH allowed_map AS (
  SELECT 'lane map ) with a stray paren in a literal' AS why, *
  FROM UNNEST([
    STRUCT('PENDING_X' AS queue, ['R1', 'R2'] AS allowed_drainers),
    STRUCT('PENDING_Y' AS queue, ['R3'] AS allowed_drainers)
  ])
)
SELECT STRUCT('PENDING_DECOY' AS queue, ['R9'] AS allowed_drainers) AS decoy FROM allowed_map;
"""


def test_parse_allowed_map_reads_the_cte_and_ignores_structs_outside_it(tmp_path):
    # The stray `)` inside the literal used to end the block before either STRUCT was seen; the
    # decoy after the CTE proves the scan is still scoped to the block, not the whole file.
    assert ch.parse_allowed_map(_sql(tmp_path, ALLOWED_MAP_SQL)) == {
        "PENDING_X": ["R1", "R2"],
        "PENDING_Y": ["R3"],
    }


def test_parse_allowed_map_returns_none_without_a_cte(tmp_path):
    assert ch.parse_allowed_map(_sql(tmp_path, "SELECT 1;\n")) is None


def test_parse_allowed_map_returns_none_on_an_unclosed_cte(tmp_path):
    # CHECK A reports a None return as "could not locate an allowed_map CTE" — a loud failure,
    # rather than silently parsing the rest of the file as though it were the block.
    text = "WITH allowed_map AS (\n  SELECT * FROM UNNEST([\n"
    assert ch.parse_allowed_map(_sql(tmp_path, text)) is None


# ---- the live guard -------------------------------------------------------------------------

def test_real_allowed_map_source_still_parses():
    live = ch.parse_allowed_map(ch.ALLOWED_MAP_SOURCE)
    assert live, "bigquery/180's allowed_map CTE no longer parses — CHECK A's live source is broken"
    assert all(isinstance(drainers, list) and drainers for drainers in live.values())

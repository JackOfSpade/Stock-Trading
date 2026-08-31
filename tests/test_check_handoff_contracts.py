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
import re

from conftest import load_module_from_path
from lib.textio import read_text

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


# ---- CREATE_TABLE_RE / parse_create_table_bodies ---------------------------------------------

def test_parse_create_table_bodies_covers_every_dataset_the_check_scopes(tmp_path):
    """BUG FIX regression (2026-08-31 code-quality pass, contracts#0): CREATE_TABLE_RE used to be
    hardcoded to the (events|ops) dataset alternation, so a state/analytics/perf CREATE TABLE was
    structurally invisible to CHECK B's completeness sweep (a live instance: state.param_change_
    provenance's change_key/param_key/change_type NOT NULL columns could never be flagged). Pin that
    every dataset this check now scopes actually parses, so a future narrowing of the alternation
    fails here rather than silently reopening the gap the widened regex was written to close."""
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_fixture.sql").write_text(
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.e_fixture` (a STRING NOT NULL);\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.o_fixture` (a STRING NOT NULL);\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.s_fixture` (a STRING NOT NULL);\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.analytics.a_fixture` (a STRING NOT NULL);\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.perf.p_fixture` (a STRING NOT NULL);\n",
        encoding="utf-8",
    )
    bodies = ch.parse_create_table_bodies(str(d))
    assert set(bodies) == {
        ("events", "e_fixture"), ("ops", "o_fixture"), ("state", "s_fixture"),
        ("analytics", "a_fixture"), ("perf", "p_fixture"),
    }


def test_parse_create_table_bodies_ignores_create_table_as_select(tmp_path):
    """CREATE ... TABLE ... AS SELECT (a CTAS -- e.g. the real analytics.review_embeddings /
    analytics.decision_embeddings) has no parenthesized column list, so widening CREATE_TABLE_RE's
    dataset alternation must not start matching it: there is no column list for this check to read a
    NOT NULL/no-default column out of, and the real repo relies on that (neither table is classified
    in ops/handoff_contracts.yaml)."""
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_fixture.sql").write_text(
        "CREATE OR REPLACE TABLE `stock-trading-498512.analytics.ctas_fixture` AS SELECT 1 AS a;\n",
        encoding="utf-8",
    )
    assert ch.parse_create_table_bodies(str(d)) == {}


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


# =================================================================================================
# QUALITY PASS 2026-08-22 -- coverage for the CHECK A/C predicate matchers.
#
# The suite above pins the pure DDL/CTE parsing helpers. These pin the other half of the script:
# the regexes that decide whether a routine's PROSE contains a real drain-close instruction
# (CHECK A) and a real discovery predicate (CHECK C). Same fail-open argument -- a regex that
# quietly stops matching turns a blocking gate into a vacuous pass with nothing printed.
# =================================================================================================
# ---- terminal_status_pattern: the hyphenated-compound trap the module docstring names -----------
def test_terminal_status_pattern_matches_only_the_two_safe_forms():
    pat = ch.terminal_status_pattern("complete")
    assert pat.search("... 'complete' ...")             # quote-delimited
    assert pat.search("... status = 'complete' ...")    # after status =
    assert pat.search("... status: complete ...")       # after status:
    assert pat.search('... "complete" ...')
    assert pat.search("... `complete` ...")


def test_terminal_status_pattern_does_not_match_a_hyphenated_compound_status():
    """Why a bare \\bvalue\\b scan is unsafe: 'attacker-complete' is a DIFFERENT status and must not
    satisfy a contract that pins 'complete'."""
    pat = ch.terminal_status_pattern("complete")
    assert not pat.search("set the lane to attacker-complete when the attacker finishes")


# ---- has_close_instruction: all three tokens must share ONE physical line -----------------------
def test_has_close_instruction_requires_all_three_tokens_on_one_line():
    body = "Then INSERT INTO events.queue_events ... status = 'complete' ... to close the lane.\n"
    assert ch.has_close_instruction(body, "complete")


def test_has_close_instruction_rejects_tokens_split_across_lines():
    """Co-location on one line is the point: an 'insert' in one paragraph and a 'complete' three
    paragraphs later is prose, not a drain-close instruction."""
    body = "INSERT INTO events.queue_events (...)\nLater on, mark it status = 'complete'.\n"
    assert not ch.has_close_instruction(body, "complete")


# ---- CHECK C: the discovery predicate must bind the NAMED column --------------------------------
_DISCOVERY_BODY = (
    "Step 3. Find newly terminated strategies:\n"
    "SELECT l.strategy_code\n"
    "FROM `stock-trading-498512.events.strategy_lifecycle` l\n"
    "WHERE l.to_state = 'TERMINATED'\n"
    "  AND l.event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);\n"
)


def test_has_discovery_query_accepts_a_predicate_on_the_named_column():
    assert ch.has_discovery_query(
        _DISCOVERY_BODY, "events.strategy_lifecycle", "to_state", "TERMINATED")


def test_has_discovery_query_rejects_a_predicate_on_the_wrong_column():
    """REGRESSION (quality pass 2026-08-22). has_discovery_query() never read the `discovery_column`
    field ops/handoff_contracts.yaml has always carried, and matched the value next to ANY '=' (or
    merely quote-delimited anywhere in the 800-char window). So mutating SL5's real, correct
    `l.to_state = 'TERMINATED'` to the semantically-backwards `l.from_state = 'TERMINATED'` --
    finding rows transitioning FROM Terminated rather than TO it -- still satisfied CHECK C. The
    check exists to stop a consumer naming an input without pinning a runnable predicate; this
    closes the sibling gap where the pinned predicate does not mean what the contract says."""
    mutated = _DISCOVERY_BODY.replace("l.to_state = 'TERMINATED'", "l.from_state = 'TERMINATED'")
    assert not ch.has_discovery_query(
        mutated, "events.strategy_lifecycle", "to_state", "TERMINATED")


def test_has_discovery_query_rejects_a_bare_prose_mention_of_the_value():
    """The original CHECK C contract: a prose mention is not a predicate."""
    prose = ("SELECT something FROM `stock-trading-498512.events.strategy_lifecycle`\n"
             "-- when a strategy reaches TERMINATED, deregister it\n")
    assert not ch.has_discovery_query(
        prose, "events.strategy_lifecycle", "to_state", "TERMINATED")


def test_has_discovery_query_accepts_an_in_set_membership_form():
    """`IN ('TERMINATED', ...)` is a legitimate way to write the same predicate and must not force
    a rewrite."""
    body = ("SELECT l.strategy_code FROM `stock-trading-498512.events.strategy_lifecycle` l\n"
            "WHERE l.to_state IN ('TERMINATED', 'RETIRED')\n")
    assert ch.has_discovery_query(body, "events.strategy_lifecycle", "to_state", "TERMINATED")


def test_has_discovery_query_requires_the_table_in_the_same_window():
    """A predicate on the right column against some OTHER table is not this handoff."""
    body = "SELECT x FROM `stock-trading-498512.events.something_else` l WHERE l.to_state = 'TERMINATED'\n"
    assert not ch.has_discovery_query(
        body, "events.strategy_lifecycle", "to_state", "TERMINATED")


# ---- CHECK C wiring ----------------------------------------------------------------------------
def test_check_c_requires_discovery_column_on_every_entry():
    """`discovery_column` became REQUIRED alongside the tightened matcher, so a future entry cannot
    quietly opt out of the column binding by omitting the field."""
    spec = {"row_handoffs": [{
        "table": "events.strategy_lifecycle",
        "discovery_value": "TERMINATED",
        "consumer": "SL5",
        "producers": ["SL3"],
        "pinned_columns": ["strategy_code"],
        "why": "because",
    }]}
    errors = []
    ch.check_c(spec, {"SL5": _DISCOVERY_BODY}, errors)
    assert len(errors) == 1 and "discovery_column" in errors[0]


def test_check_c_flags_a_consumer_that_is_not_a_routine_section():
    spec = {"row_handoffs": [{
        "table": "events.strategy_lifecycle",
        "discovery_column": "to_state",
        "discovery_value": "TERMINATED",
        "consumer": "NOT_A_ROUTINE",
        "producers": ["SL3"],
        "pinned_columns": ["strategy_code"],
        "why": "because",
    }]}
    errors = []
    ch.check_c(spec, {"SL5": _DISCOVERY_BODY}, errors)
    assert any("is NOT a routine section" in e for e in errors)


# ---- end-to-end + live guards ------------------------------------------------------------------
def test_real_repo_handoff_contracts_pass():
    """The committed ops/handoff_contracts.yaml + Claude_Task_Plan.md + bigquery/*.sql must satisfy
    every check -- the standing equivalent of the module header's one-off manual runs, and what
    catches a regex tightening that starts rejecting the real, correct tree."""
    assert ch.main() == 0


def test_query_window_is_wide_enough_for_the_real_pinned_predicate():
    """QUERY_WINDOW_CHARS is sized to a generous single statement (SL5's predicate is ~430 chars).
    Pin that the real consumer body still resolves inside it, so a future shrink shows up here
    rather than as a mystery CHECK C failure."""
    bodies = ch.routine_bodies(read_text(ch.TASK_PLAN_PATH))
    assert ch.has_discovery_query(
        bodies["SL5"], "events.strategy_lifecycle", "to_state", "TERMINATED")
    assert ch.QUERY_WINDOW_CHARS >= 500


def test_sql_keyword_regexes_are_case_insensitive():
    """SQL keywords are case-insensitive; a case-SENSITIVE token regex would silently stop matching
    a lowercase `select` in a future hand-written plan snippet."""
    assert ch.SELECT_TOKEN.flags & re.IGNORECASE
    assert ch.terminal_status_pattern("complete").flags & re.IGNORECASE

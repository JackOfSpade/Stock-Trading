"""Guard scripts/check_sql_dryrun.py's classify() — the load-bearing decision that turns a
`bq query --dry_run` result into block / tolerate / ok (2026-07-17 audit follow-up) — and
no_from_where_violations() — the credential-free static lint added 2026-08-03 for the blind spot
`classify()`/`bq --dry_run` structurally cannot see (a leading DDL statement in a bigquery/*.sql
script suppresses BigQuery's OWN semantic analysis of everything after it; see check_sql_dryrun.py's
module docstring KNOWN, VERIFIED LIMITATION section).

The gate must BLOCK on a parse-class error (the mode=''manual'' class that reached live apply) and must
TOLERATE the permission/reference messages a READ-ONLY SA legitimately gets when dry-running DDL — a
regression either way silently breaks the gate (false-blocks every merge, or never catches a syntax
bug). Pure offline unit tests (no warehouse, no bq) — runs in the always-on `test` job.
"""
import glob
import os

from conftest import load_module_from_path

csd = load_module_from_path("check_sql_dryrun", "scripts", "check_sql_dryrun.py")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_133 = os.path.join(ROOT, "bigquery", "133_sl1_research_leads_and_record_corrections.sql")
BIGQUERY_151 = os.path.join(ROOT, "bigquery", "151_connector_tool_inventory.sql")


def test_exit_zero_is_ok():
    assert csd.classify(0, "Query successfully validated. ... 0 bytes ...") == "ok"


def test_the_actual_2026_07_17_bug_blocks():
    # BigQuery's exact wording for the mode=''manual'' bug.
    msg = ("Error in query string: Syntax error: concatenated string literals must be separated by "
           "whitespace or comments at [779:38]")
    assert csd.classify(1, msg) == "syntax"


def test_generic_syntax_errors_block():
    for msg in [
        "Syntax error: Unexpected keyword FROM at [3:1]",
        "Syntax error: Expected end of input but got identifier",
        "Syntax error: Illegal input character",
    ]:
        assert csd.classify(1, msg) == "syntax", msg


def test_readonly_sa_permission_denied_on_ddl_is_tolerated():
    # A syntactically-VALID CREATE the read-only SA cannot perform — NOT a syntax bug.
    msg = ("Access Denied: Table stock-trading-498512:state.foo: User does not have permission to "
           "update/create ...")
    assert csd.classify(1, msg) == "tolerated"


def test_not_yet_live_sibling_reference_is_tolerated():
    # A new object created later in the same change — reference resolution fails, not a syntax bug.
    for msg in [
        "Not found: Table stock-trading-498512:state.brand_new_view was not found in location US",
        "Unrecognized name: breach_hard at [12:9]",
    ]:
        assert csd.classify(1, msg) == "tolerated", msg


def test_transient_infra_error_is_unknown_not_blocking():
    # A network/quota hiccup must not false-block a merge — it is inconclusive, not a syntax error.
    assert csd.classify(1, "harness-error: bq query timed out after 180s") == "unknown"
    assert csd.classify(1, "Exceeded rate limits: too many api requests") == "unknown"


def test_syntax_wins_over_tolerate_when_both_present():
    # Parse failures surface before authorization, but be explicit: a syntax marker must win.
    msg = "Syntax error: unexpected keyword; also the user does not have permission"
    assert csd.classify(1, msg) == "syntax"


# ---- is_template(): fill-in-the-blanks files are unparseable BY DESIGN --------------------------
# 2026-07-18, first full-repo sweep (82 files): the ONLY "syntax error" was
# bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql, whose header says "TEMPLATE, NOT
# auto-applied ... fill in the 5 placeholders below" and which carries literal <TRANSFER_DATE>
# markers. BigQuery rejects it with `Unexpected "<"` — correctly. Blocking CI on it is a false
# positive AND a latent landmine: the path-gated CI step only sees the file once someone edits it
# (even a comment), so the build would red on a file that is correct by design.


def test_template_files_are_recognised():
    assert csd.is_template("bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql") is True
    assert csd.is_template("56_park_policy_voo_manual_cutover_TEMPLATE.sql") is True
    # case-insensitive on the suffix
    assert csd.is_template("bigquery/99_thing_template.sql") is True


def test_ordinary_sql_files_are_not_treated_as_templates():
    # The guard must be narrow: a normal file must still be dry-run and still be able to FAIL.
    for path in ("bigquery/34_alert_lifecycle.sql",
                 "bigquery/78_book_drawdown_rebase_and_staleness_gate.sql",
                 "bigquery/03_twr_engine.sql",
                 "bigquery/template_helpers.sql"):        # 'template' not as the _TEMPLATE suffix
        assert csd.is_template(path) is False, path


def test_template_detection_is_filename_based_not_placeholder_based():
    # Deliberate design choice: a <PLACEHOLDER>-marker regex would also match BigQuery's own type
    # syntax (ARRAY<STRING>, STRUCT<a INT64>) and would silently skip REAL files. Pin that a file
    # containing such type syntax in its NAME-less form is never auto-skipped.
    assert csd.is_template("bigquery/40_options_marks.sql") is False


def test_main_skips_templates_without_failing(monkeypatch, capsys):
    # A template-only invocation must exit 0, and must PRINT the skip (never silent — a template must
    # not be able to hide breakage).
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    called = []
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: called.append(sql_path) or (0, "ok"))
    rc = csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql"])
    out = capsys.readouterr().out
    assert rc == 0
    assert called == [], "a template must never be sent to bq --dry_run"
    assert "skipped" in out and "TEMPLATE" in out


def test_canary_failure_fails_closed(monkeypatch, capsys):
    # 2026-07-18 audit: if the environment can't detect a KNOWN syntax error, a "clean" pass over the
    # real files proves nothing — the gate must exit 1, not print a warning and green-light the merge
    # (the pre-fix behavior). Same discipline as dbt_parity's checked==0 fail-closed guard.
    monkeypatch.setattr(csd, "canary_ok", lambda: False)
    called = []
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: called.append(sql_path) or (0, "ok"))
    rc = csd.main(["check_sql_dryrun.py", "bigquery/34_real.sql"])
    out = capsys.readouterr().out
    assert rc == 1
    assert "FAILS CLOSED" in out
    assert called == [], "no point dry-running files in an environment proven unable to catch errors"


def test_canary_not_consulted_when_nothing_to_check(monkeypatch):
    # Vacuous invocations (template-only / empty) exit 0 without spending a canary call — there is no
    # clean-pass claim to verify, so a broken environment must not red an empty change.
    monkeypatch.setattr(csd, "canary_ok", lambda: (_ for _ in ()).throw(AssertionError("must not run")))
    assert csd.main(["check_sql_dryrun.py"]) == 0
    assert csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql"]) == 0


def test_main_still_blocks_a_real_syntax_error_alongside_a_template(monkeypatch, capsys):
    # The skip must not become a hole: a genuine syntax error in a NON-template file still blocks,
    # even when a template rides along in the same invocation.
    monkeypatch.setattr(csd, "canary_ok", lambda: True)

    def fake(sql_path):
        return (1, 'Error in query string: Syntax error: Unexpected "(" at [21:18]')
    monkeypatch.setattr(csd, "_bq_dry_run", fake)
    rc = csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql", "bigquery/34_real.sql"])
    out = capsys.readouterr().out
    assert rc == 1
    assert "34_real.sql" in out and "SYNTAX ERROR" in out


# ==== no_from_where_violations(): the 2026-08-03 static-lint blind-spot fix ==========================
#
# bigquery/133 was reported "0 SYNTAX ERRORS" by classify()/bq --dry_run while containing two
# `INSERT INTO ... SELECT <bare literals> WHERE NOT EXISTS (...)` statements illegal in GoogleSQL
# ("Query without FROM clause cannot have a WHERE clause"), because the file's own leading
# `CREATE TABLE IF NOT EXISTS` suppresses BigQuery's semantic analysis of every later statement in the
# same script dry-run. These tests guard the credential-free static lint that catches this shape
# directly from the SQL text, with no `bq` call involved.

BROKEN_INSERT_NO_FROM = """
INSERT INTO `stock-trading-498512.events.strategy_research_leads`
  (lead_id, event_type, source_routine, archetype, mechanism, cited_edges, cited_disadvantages,
   target_regime_cells, evidence_status, blocker, next_step, source_decision_entry_id, note)
SELECT
  'sl1-2026-08-disclosure-information-surprise', 'OPEN', 'SL1',
  'disclosure-information-surprise',
  'LLM-modeled information surprise in public-company disclosures.',
  ['1.6','1.1'], [], ['DOWN/LOW','DOWN/NORMAL','DOWN/HIGH'],
  'Magnitude, holding period, and cost robustness unverified.',
  'The RFS-track regression tables were unavailable.',
  'Obtain and inspect the actual regression tables.',
  '789de922-da85-4451-bf9c-340c0a52ee57',
  'Preserved instead of synthesizing: default-REJECT would force immediate rejection.'
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.strategy_research_leads`
  WHERE lead_id = 'sl1-2026-08-disclosure-information-surprise'
);
"""

FIXED_INSERT_WITH_FROM = BROKEN_INSERT_NO_FROM.replace(
    "'Preserved instead of synthesizing: default-REJECT would force immediate rejection.'\nWHERE NOT EXISTS (",
    "'Preserved instead of synthesizing: default-REJECT would force immediate rejection.'\n"
    "FROM (SELECT 1)\nWHERE NOT EXISTS (",
)

CORRECT_INSERT_WITH_TABLE_FROM = """
INSERT INTO `stock-trading-498512.events.cash_flows` (flow_date, flow_type, amount, strategy, note, source)
SELECT * FROM UNNEST([
  STRUCT(DATE '2026-04-17' AS flow_date, 'DEPOSIT' AS flow_type, 2000.0 AS amount,
         CAST(NULL AS STRING) AS strategy, 'seed' AS note, 'backfill-2026-07-03' AS source)
])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.cash_flows` WHERE source = 'backfill-2026-07-03'
);
"""


def test_broken_no_from_shape_is_flagged():
    # "FROM (SELECT 1)" is absent — reproduces the real bigquery/133 defect: WHERE follows a bare
    # literal list with no FROM anywhere at the statement's own top level.
    violations = csd.no_from_where_violations(BROKEN_INSERT_NO_FROM)
    assert len(violations) == 1
    line_number, excerpt = violations[0]
    assert isinstance(line_number, int) and line_number > 0
    # The reported line must be the actual line the WHERE token sits on in the ORIGINAL text.
    assert BROKEN_INSERT_NO_FROM.splitlines()[line_number - 1].strip().startswith("WHERE NOT EXISTS")
    assert "WHERE NOT EXISTS" in excerpt


def test_fixed_form_with_from_select_1_is_not_flagged():
    assert "FROM (SELECT 1)" in FIXED_INSERT_WITH_FROM  # sanity: the fixture actually differs
    assert csd.no_from_where_violations(FIXED_INSERT_WITH_FROM) == []


def test_correct_insert_select_from_table_is_not_flagged():
    assert csd.no_from_where_violations(CORRECT_INSERT_WITH_TABLE_FROM) == []


def test_insert_values_statement_is_not_flagged():
    # An INSERT ... VALUES statement is a different shape entirely (no SELECT at all) — must never be
    # misread as a no-FROM violation. Since 2026-08-08, no_from_where_violations() drives its scan from
    # every top-level `SELECT` keyword in the file (see _scan_select_clause) rather than from
    # `INSERT INTO`, so a VALUES-only INSERT is trivially skipped: it has no SELECT keyword anywhere,
    # so it never triggers a scan at all, and the loop over _SELECT_KEYWORD_RE matches simply finds
    # none for this statement.
    sql = """
    INSERT INTO `stock-trading-498512.ops.run_log` (routine, run_date, status)
    VALUES ('D1', CURRENT_DATE(), 'started');
    """
    assert csd.no_from_where_violations(sql) == []


def test_nested_where_not_exists_with_from_does_not_confuse_the_outer_check():
    # The idempotency guard's OWN inner SELECT has a FROM+WHERE one paren level deeper than the outer
    # statement -- that must never be mistaken for the outer SELECT's own top-level FROM/WHERE.
    sql = """
    INSERT INTO `stock-trading-498512.ops.trading_control` (halt_all, mode, reason, set_by)
    SELECT FALSE, 'manual', 'seed', 'backfill'
    FROM (SELECT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.trading_control`);
    """
    assert csd.no_from_where_violations(sql) == []


def test_cte_based_insert_select_is_not_flagged():
    # WITH r AS (SELECT ... FROM ...), ... SELECT ... FROM r -- each CTE's own SELECT/FROM is sealed
    # inside the CTE's parens; only the CTE clause's FINAL outer SELECT is visible at depth 0, and it
    # has a real FROM.
    sql = """
    INSERT INTO `stock-trading-498512.perf.strategy_daily`
    (as_of_date, strategy)
    WITH r AS (
      SELECT sdr.as_of_date, sdr.strategy
      FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
    )
    SELECT r.as_of_date, r.strategy FROM r;
    """
    assert csd.no_from_where_violations(sql) == []


def test_prose_containing_from_and_where_does_not_cause_a_false_positive():
    # A quoted decision note routinely contains the plain English words "from" and "where" -- a naive
    # substring/keyword scan over raw text (not comment+literal-blanked text) would misfire on this.
    sql = """
    INSERT INTO `stock-trading-498512.events.decision_log` (entry_date, note)
    SELECT DATE '2026-08-03',
      'Retraction of the joint conclusion drawn from prior evidence: where fractional shorting was
       assumed infeasible, it is not; see rail (a) for the applicable ground.'
    FROM (SELECT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.decision_log` WHERE entry_date = DATE '2026-08-03');
    """
    assert csd.no_from_where_violations(sql) == []


def test_bare_doubled_quote_style_note_with_literal_parens_does_not_corrupt_depth_tracking():
    # A note like "Missing citation (see appendix" carries a literal, genuinely UNBALANCED paren
    # inside a string literal (an open paren with no matching close anywhere in the same literal) --
    # this must be blanked away, or naive paren-depth tracking over raw text would miscount: the
    # unmatched "(" would push depth to 1 with nothing left in the statement to bring it back to 0,
    # so the real top-level WHERE below would be misread as nested (depth != 0) and never flagged,
    # masking a real no-FROM-WHERE violation. (Mutation-proofed 2026-08-03: with string-literal
    # blanking disabled, this statement's depth never returns to 0, so the scan finds no top-level
    # WHERE and this test's assertion fails -- see the module docstring / adversarial audit notes.)
    sql = """
    INSERT INTO `stock-trading-498512.events.strategy_research_leads` (lead_id, note)
    SELECT 'x', 'Missing citation (see appendix for detail'
    WHERE NOT EXISTS (
      SELECT 1 FROM `stock-trading-498512.events.strategy_research_leads` WHERE lead_id = 'x'
    );
    """
    violations = csd.no_from_where_violations(sql)
    assert len(violations) == 1


# ==== 2026-08-08 WIDENING: the shape is not only under INSERT INTO ... SELECT ========================
#
# bigquery/151_connector_tool_inventory.sql was rejected at real apply time by the exact
# "Query without FROM clause cannot have a WHERE clause" error, inside a `CREATE OR REPLACE VIEW ...
# AS` body's SECOND `UNION ALL` arm — no `INSERT INTO` anywhere in the statement. The old lint keyed
# off `_INSERT_INTO_RE.finditer()`, so it never even looked at this statement and reported zero
# violations. no_from_where_violations() now drives its scan from every top-level `SELECT` keyword
# (`_scan_select_clause`), so it catches the shape in a UNION/INTERSECT/EXCEPT arm, a bare statement, or
# a CREATE VIEW/CREATE TABLE ... AS body, in addition to the original INSERT INTO ... SELECT case.

BROKEN_UNION_ARM_NO_FROM = """
CREATE OR REPLACE VIEW `stock-trading-498512.state.connector_tool_inventory_stale` AS
SELECT connector, last_good_run_date, days_stale, CURRENT_TIMESTAMP() AS checked_at
FROM per_connector
WHERE last_good_run_date IS NULL
   OR days_stale > 2
UNION ALL
SELECT
  'ALL' AS connector, CAST(NULL AS DATE) AS last_good_run_date,
  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 2 DAY)
);
"""

FIXED_UNION_ARM_WITH_FROM_UNNEST = BROKEN_UNION_ARM_NO_FROM.replace(
    "  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at\nWHERE NOT EXISTS (",
    "  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at\n"
    "FROM UNNEST([1])\nWHERE NOT EXISTS (",
)

BARE_NO_FROM_SELECT_WHERE = "SELECT 'x' AS a WHERE NOT EXISTS (SELECT 1);\n"


def test_bigquery_151_union_arm_no_from_shape_is_flagged():
    # Reproduces the exact escaped bug: the SECOND UNION ALL arm of a CREATE VIEW body has no FROM of
    # its own before its WHERE NOT EXISTS guard. The FIRST arm (real FROM + WHERE) and the NESTED
    # `SELECT 1 FROM ... WHERE ...` inside NOT EXISTS(...) are both legal and must not add extra hits.
    violations = csd.no_from_where_violations(BROKEN_UNION_ARM_NO_FROM)
    assert len(violations) == 1
    line_number, excerpt = violations[0]
    assert BROKEN_UNION_ARM_NO_FROM.splitlines()[line_number - 1].strip().startswith("WHERE NOT EXISTS")
    assert "WHERE NOT EXISTS" in excerpt


def test_bigquery_151_fixed_from_unnest_form_is_not_flagged():
    # The real fix landed 2026-08-08: `FROM UNNEST([1])` gives the second arm's literal-only row a
    # one-row source to hang its WHERE off, exactly like `FROM (SELECT 1)` does for the INSERT case.
    assert "FROM UNNEST([1])" in FIXED_UNION_ARM_WITH_FROM_UNNEST  # sanity: fixture actually differs
    assert csd.no_from_where_violations(FIXED_UNION_ARM_WITH_FROM_UNNEST) == []


def test_bare_no_from_select_where_with_no_insert_at_all_is_flagged():
    # The module docstring's own minimal repro (no INSERT, no CREATE, just a lone statement): a bare
    # top-level `SELECT <literal> WHERE ...` with no FROM anywhere. Must be caught even though there is
    # no INSERT INTO in sight.
    violations = csd.no_from_where_violations(BARE_NO_FROM_SELECT_WHERE)
    assert len(violations) == 1


def test_real_bigquery_151_file_has_zero_violations():
    # The FIXED, live file — must stay clean.
    with open(BIGQUERY_151, encoding="utf-8") as fh:
        text = fh.read()
    assert csd.no_from_where_violations(text) == []


def test_bigquery_151_reintroduced_bug_is_caught_end_to_end():
    # MUTATION PROOF: strip the real fix's own "FROM UNNEST([1])" guard line back out of the REAL live
    # file's text (the explanatory comment sits earlier, right after UNION ALL, not adjacent to this
    # line, so only the FROM line itself needs removing to reproduce the pre-fix shape) and confirm the
    # lint flags the regressed UNION ALL arm.
    with open(BIGQUERY_151, encoding="utf-8") as fh:
        text = fh.read()
    # 2 occurrences: the real code line, plus the explanatory comment above it that also spells out
    # "FROM UNNEST([1])" in prose -- only the CODE line is targeted by the replace below (anchored on
    # the surrounding CAST(...)/WHERE NOT EXISTS context, which the comment text doesn't share).
    assert text.count("FROM UNNEST([1])") == 2, "fixture assumption changed -- re-check bigquery/151"
    mutated = text.replace(
        "CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at\nFROM UNNEST([1])\nWHERE NOT EXISTS (",
        "CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at\nWHERE NOT EXISTS (",
    )
    assert mutated.count("FROM UNNEST([1])") == 1, "the CODE line should be gone, only the comment remains"
    violations = csd.no_from_where_violations(mutated)
    assert len(violations) == 1


# ---- False-positive guards: shapes that must NEVER be flagged (2026-08-08 widening) ----------------
# The widened scan drives off every top-level SELECT rather than only ones following INSERT INTO, so
# these pin down that ordinary, fully-legal SQL shapes stay clean under the new, broader trigger.


def test_trivial_selects_without_where_are_clean():
    assert csd.no_from_where_violations("SELECT 1;") == []
    assert csd.no_from_where_violations("SELECT COUNT(*) FROM t WHERE x = 1;") == []


def test_window_and_correlated_subquery_expressions_with_own_where_stay_clean():
    # A correlated scalar subquery AND a window/analytic function both appear in the SELECT list, each
    # with their own parens; the outer statement's real FROM/WHERE must still be found correctly.
    sql = """
    SELECT
      a,
      (SELECT COUNT(*) FROM other WHERE other.a = outer_tbl.a) AS match_count,
      RANK() OVER (PARTITION BY a ORDER BY b DESC) AS rnk
    FROM outer_tbl
    WHERE a IS NOT NULL;
    """
    assert csd.no_from_where_violations(sql) == []


def test_from_unnest_with_where_is_clean():
    # FROM UNNEST(...) is a real FROM clause -- legal, must never be flagged.
    sql = "SELECT x FROM UNNEST([1, 2, 3]) AS x WHERE x > 1;"
    assert csd.no_from_where_violations(sql) == []


def test_exists_scalar_in_select_list_is_clean():
    # EXISTS (SELECT 1 FROM t WHERE ...) used as an ordinary scalar expression in the SELECT list.
    sql = """
    SELECT a, EXISTS(SELECT 1 FROM t WHERE t.id = outer_tbl.a) AS has_match
    FROM outer_tbl;
    """
    assert csd.no_from_where_violations(sql) == []


def test_case_when_with_from_and_where_is_clean_and_when_is_never_mistaken_for_where():
    sql = """
    SELECT CASE WHEN x = 1 THEN 'a' WHEN x = 2 THEN 'b' ELSE 'c' END AS y
    FROM t
    WHERE y = 'a';
    """
    assert csd.no_from_where_violations(sql) == []


def test_case_when_with_no_from_still_correctly_flags_the_real_where_not_a_when():
    # A multi-WHEN CASE expression with a genuinely missing FROM: the real top-level WHERE must still
    # be found (exactly once), proving WHEN tokens are never mistaken for WHERE and never suppress or
    # duplicate detection of the actual violation.
    sql = """
    SELECT CASE WHEN x = 1 THEN 'a' WHEN x = 2 THEN 'b' ELSE 'c' END AS y
    WHERE NOT EXISTS (SELECT 1 FROM t WHERE t.a = y);
    """
    violations = csd.no_from_where_violations(sql)
    assert len(violations) == 1


def test_having_and_qualify_clauses_are_clean():
    sql = """
    SELECT a, COUNT(*) AS c
    FROM t
    WHERE a IS NOT NULL
    GROUP BY a
    HAVING COUNT(*) > 1
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a ORDER BY c DESC) = 1;
    """
    assert csd.no_from_where_violations(sql) == []


# ==== _blank_string_literals(): backtick-quoted identifiers (2026-08-03 adversarial self-audit) ====
#
# `_blank_string_literals` used to track only `'` and `"` as literal delimiters, so a backtick-quoted
# identifier's CONTENTS were read as ordinary text. GoogleSQL gives backticks no escape mechanism at
# all (an identifier just ends at the next backtick), so an apostrophe/quote/semicolon embedded in one
# is NOT a real string delimiter or statement terminator -- but the old code treated it as one, in both
# directions: a FALSE POSITIVE (an embedded `'` opened a fake string literal that swallowed the real
# top-level FROM) and a FALSE NEGATIVE (an embedded `;` was misread as ending the statement, so the
# scan stopped before it reached the real, illegal WHERE).


def test_backtick_identifier_with_embedded_apostrophe_is_not_a_false_positive():
    # Reproduces the exact false positive: `o'clock`'s apostrophe used to open a fake string literal
    # that swallowed the real top-level FROM, wrongly flagging this legal SQL as a no-FROM-WHERE
    # violation.
    sql = ("INSERT INTO t (a)\n"
           "SELECT `o'clock` AS a FROM src\n"
           "WHERE NOT EXISTS (SELECT 1 FROM t WHERE t.a = src.a);\n")
    assert csd.no_from_where_violations(sql) == []


def test_backtick_identifier_with_embedded_semicolon_is_not_a_false_negative():
    # Reproduces the exact false negative: `c;d`'s semicolon used to be read as a top-level statement
    # terminator, so the scan stopped before it ever reached the real (illegal, no-FROM) WHERE.
    sql = ("INSERT INTO `p.d.t` (a)\n"
           "SELECT 'x' AS `c;d`\n"
           "WHERE NOT EXISTS (SELECT 1);\n")
    violations = csd.no_from_where_violations(sql)
    assert len(violations) == 1


def test_blank_string_literals_preserves_length_and_newlines_with_backticks_and_triple_quotes():
    # The length/newline-preserving contract is load-bearing for line numbers -- it must hold across a
    # mix of a backtick identifier, a triple-quoted string, and an escaped \' inside a single-quoted
    # string, all in the same text.
    text = (
        "INSERT INTO `p.d.t` (a)\n"
        "SELECT 'x' AS `c;d`,\n"
        '  """a\n'
        "multi\n"
        'line""" AS b,\n'
        "  'escaped \\' quote' AS c\n"
        "WHERE NOT EXISTS (SELECT 1);\n"
    )
    masked = csd._blank_string_literals(text)
    assert len(masked) == len(text)
    original_newlines = [i for i, ch in enumerate(text) if ch == "\n"]
    masked_newlines = [i for i, ch in enumerate(masked) if ch == "\n"]
    assert original_newlines == masked_newlines


def test_correlated_subquery_in_select_list_with_no_outer_from_is_flagged():
    # A parenthesised correlated subquery in the SELECT list (its OWN FROM+WHERE one paren level
    # deeper) must not be mistaken for the outer statement's top-level FROM/WHERE. Here the OUTER
    # statement has no top-level FROM at all, so the top-level WHERE that follows IS the illegal
    # no-FROM-WHERE shape -- correctly finding it depends entirely on depth tracking staying accurate
    # across the nested "(...)" region. (Mutation-proofed 2026-08-03: with paren-depth tracking
    # disabled, the scan instead matches the SUBQUERY's own inner FROM as if it were top-level and
    # returns "ok", so this test's assertion fails.)
    sql = """
    INSERT INTO `stock-trading-498512.events.decision_log` (entry_date, related_id, note)
    SELECT DATE '2026-08-03',
      (SELECT id FROM `stock-trading-498512.events.decision_log` d
       WHERE d.entry_date = DATE '2026-08-02' LIMIT 1),
      'note'
    WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.decision_log`
                       WHERE entry_date = DATE '2026-08-03');
    """
    violations = csd.no_from_where_violations(sql)
    assert len(violations) == 1


def test_correlated_subquery_in_select_list_with_outer_from_is_not_flagged():
    # Mirror of the case above: the OUTER statement DOES have its own top-level FROM after the same
    # kind of nested correlated subquery -- must not be flagged. Together with the violation case
    # above, this pins that the nested subquery's own FROM/WHERE never leaks into the outer
    # statement's classification in either direction.
    sql = """
    INSERT INTO `stock-trading-498512.events.decision_log` (entry_date, related_id, note)
    SELECT DATE '2026-08-03',
      (SELECT id FROM `stock-trading-498512.events.decision_log` d
       WHERE d.entry_date = DATE '2026-08-02' LIMIT 1),
      'note'
    FROM (SELECT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.decision_log`
                       WHERE entry_date = DATE '2026-08-03');
    """
    assert csd.no_from_where_violations(sql) == []


def test_real_bigquery_133_file_has_zero_violations():
    # The FIXED, live file -- must stay clean.
    with open(BIGQUERY_133, encoding="utf-8") as fh:
        text = fh.read()
    assert csd.no_from_where_violations(text) == []


def test_bigquery_133_reintroduced_bug_is_caught_end_to_end():
    # MUTATION PROOF: strip the fix's own "FROM (SELECT 1)" guard lines back out of the REAL live
    # file's text and confirm the lint flags both idempotency-guard INSERTs that regress to.
    with open(BIGQUERY_133, encoding="utf-8") as fh:
        text = fh.read()
    assert text.count("FROM (SELECT 1)") == 2, "fixture assumption changed -- re-check bigquery/133"
    mutated = text.replace(
        "-- One-row source. A SELECT of bare literals cannot carry a WHERE clause in GoogleSQL\n"
        "-- (\"Query without FROM clause cannot have a WHERE clause\"), so the idempotency guard needs a FROM.\n"
        "FROM (SELECT 1)\n",
        "",
    ).replace("FROM (SELECT 1)\n", "")
    assert "FROM (SELECT 1)" not in mutated
    violations = csd.no_from_where_violations(mutated)
    assert len(violations) == 2


def test_every_current_bigquery_sql_file_has_zero_static_lint_violations():
    # Anti-false-positive regression guard: run the lint across the WHOLE repo's live bigquery/*.sql
    # (skipping fill-in-the-blanks TEMPLATE files, which are unparseable by design). Any hit here means
    # the detector is too broad and must be tightened without weakening its ability to catch the real
    # bug (see test_bigquery_133_reintroduced_bug_is_caught_end_to_end above).
    bigquery_dir = os.path.join(ROOT, "bigquery")
    paths = sorted(glob.glob(os.path.join(bigquery_dir, "*.sql")))
    assert len(paths) > 100, "sanity check that we actually found the real bigquery/ directory"
    offenders = []
    for path in paths:
        if csd.is_template(path):
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for line_number, excerpt in csd.no_from_where_violations(text):
            offenders.append((os.path.basename(path), line_number, excerpt))
    assert offenders == []


def test_main_blocks_on_static_lint_violation_before_any_bq_call(tmp_path, monkeypatch, capsys):
    # The static lint must run BEFORE canary_ok()/_bq_dry_run() -- it needs no credentials and must
    # still protect a push when `bq` is unavailable or the dry-run job is skipped.
    bad_file = tmp_path / "999_bad.sql"
    bad_file.write_text(BROKEN_INSERT_NO_FROM, encoding="utf-8")

    def must_not_be_called(*args, **kwargs):
        raise AssertionError("bq must never be invoked once the static lint has already failed")
    monkeypatch.setattr(csd, "canary_ok", must_not_be_called)
    monkeypatch.setattr(csd, "_bq_dry_run", must_not_be_called)

    rc = csd.main(["check_sql_dryrun.py", str(bad_file)])
    out = capsys.readouterr().out
    assert rc == 1
    assert "::error::" in out
    assert "NO-FROM-WHERE" in out
    assert "FROM (SELECT 1)" in out  # the fix is named explicitly
    assert str(bad_file) in out


def test_main_passes_through_to_dry_run_when_lint_is_clean(tmp_path, monkeypatch, capsys):
    good_file = tmp_path / "999_good.sql"
    good_file.write_text(FIXED_INSERT_WITH_FROM, encoding="utf-8")
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: (0, "Query successfully validated."))

    rc = csd.main(["check_sql_dryrun.py", str(good_file)])
    out = capsys.readouterr().out
    assert rc == 0
    assert "1 parse-validated" in out


def test_summary_line_says_parse_validated_not_validated(tmp_path, monkeypatch, capsys):
    # Change 2: "validated" reads as "safe to apply" -- exactly the false confidence that let
    # bigquery/133 reach live apply. The summary must claim only parse-class validity.
    good_file = tmp_path / "999_good.sql"
    good_file.write_text(FIXED_INSERT_WITH_FROM, encoding="utf-8")
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: (0, "Query successfully validated."))

    rc = csd.main(["check_sql_dryrun.py", str(good_file)])
    out = capsys.readouterr().out
    assert rc == 0
    assert "parse-validated" in out
    assert " validated," not in out  # the old, overclaiming wording (space, not "parse-") must be gone


def test_ddl_caveat_line_printed_when_a_clean_file_contains_a_ddl_statement(tmp_path, monkeypatch, capsys):
    ddl_file = tmp_path / "999_ddl.sql"
    ddl_file.write_text(
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.foo` (a STRING);\n"
        "INSERT INTO `stock-trading-498512.state.foo` (a)\n"
        "SELECT 'x' FROM (SELECT 1) WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.foo`);\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: (0, "Query successfully validated."))

    rc = csd.main(["check_sql_dryrun.py", str(ddl_file)])
    out = capsys.readouterr().out
    assert rc == 0
    assert "DDL" in out
    assert "does NOT semantically analyze" in out


def test_no_ddl_caveat_line_when_no_file_contains_ddl(tmp_path, monkeypatch, capsys):
    good_file = tmp_path / "999_good.sql"
    good_file.write_text(FIXED_INSERT_WITH_FROM, encoding="utf-8")
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: (0, "Query successfully validated."))

    rc = csd.main(["check_sql_dryrun.py", str(good_file)])
    out = capsys.readouterr().out
    assert rc == 0
    assert "does NOT semantically analyze" not in out


def test_main_reads_missing_file_gracefully_instead_of_crashing(monkeypatch, capsys):
    # A path that can't be opened (e.g. a stale argv entry) must degrade like _bq_dry_run's own
    # harness-error handling, not raise -- consistent fail-soft treatment either way.
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: (0, "ok"))
    rc = csd.main(["check_sql_dryrun.py", "bigquery/does_not_exist_999.sql"])
    out = capsys.readouterr().out
    assert rc == 0
    assert "static lint skipped" in out

"""Offline tests for scripts/check_live_sql_parity.py's repo-side extraction (no BigQuery needed).

Locks in the two properties verified by hand while writing this script: (1) apply-in-order
resolution picks the LAST bigquery/NN_*.sql file that CREATE OR REPLACEs a given object, and (2) an
indented CREATE OR REPLACE embedded inside a FORMAT() string literal (bigquery/17_restore_drill.sql)
must never be mistaken for a real top-level statement.
"""
import json
import os
import sys

import pytest

from conftest import load_module_from_path

clsp = load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")


def test_parses_the_real_repo_without_crashing():
    final = clsp.find_final_definitions()
    assert len(final) > 100  # 137 at time of writing; a generous floor so new files don't break this


def test_apply_order_last_file_wins_for_a_known_redefinition():
    final = clsp.find_final_definitions()
    # bigquery/107 (2026-07-26 halt-echo missed_run exclusion) supersedes 97, which superseded 78,
    # which superseded 47, which superseded 34, which superseded 23, for state.trading_enabled.
    _, _, source_file, _ = final[("state", "trading_enabled")]
    assert source_file == "107_halt_echo_missed_run_gate.sql"
    # bigquery/107 also supersedes 97's/78's/34's state.trading_enabled_mechanical (same gate cluster).
    _, _, source_file2, _ = final[("state", "trading_enabled_mechanical")]
    assert source_file2 == "107_halt_echo_missed_run_gate.sql"


def test_real_repo_known_dropped_park_and_calibration_views_are_absent():
    # REGRESSION TEST for the DROP-awareness bug (2026-07-28): before the fix,
    # find_final_definitions() ignored bigquery/104's and bigquery/108's DROP VIEW statements
    # entirely, so these four deliberately-retired views stayed in the expected set forever even
    # though bigquery/92's/103's own comments say "DO NOT re-create live -- 104/108 drops it." Live
    # is exactly correct here; the checker used to be wrong.
    final = clsp.find_final_definitions()
    for dataset, name in [
        ("analytics", "calibration_return_shrunk"),
        ("state", "park_allocator_promotion_readiness"),
        ("state", "park_switch_budget"),
        ("state", "park_control_latest"),
    ]:
        assert (dataset, name) not in final, f"{dataset}.{name} should be DROP-excluded from the expected set"


# ---- DROP-awareness (2026-07-28 fix): find_final_definitions() must remove a DROPped object from
# the expected set, and must resolve a DROP/CREATE mix on the SAME object within a single file by
# TEXTUAL order (not "all creates then all drops"). -------------------------------------------------
def test_drop_in_later_file_removes_object_from_expected_set(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_drop.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") not in clsp.find_final_definitions()


def test_drop_then_create_same_file_leaves_object_expected(tmp_path, monkeypatch):
    # A file that drops an object and recreates it LATER in the SAME file (textually after the
    # DROP) must leave it expected -- this is exactly what apply-in-order does to the live object.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_drop_then_recreate.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n\n"
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 2 AS x;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    final = clsp.find_final_definitions()
    assert ("state", "foo") in final
    _ot, _p, src, body = final[("state", "foo")]
    assert src == "02_drop_then_recreate.sql"
    assert "2 AS x" in body


def test_create_then_drop_same_file_leaves_object_not_expected(tmp_path, monkeypatch):
    # The mirror case: CREATE then DROP later in the SAME file must leave it NOT expected. If this
    # were resolved by statement TYPE ("all creates, then all drops") instead of textual order, both
    # this test and the one above would get the SAME (wrong) answer for whichever one doesn't match
    # file-order-of-statement-kind processing.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create_then_drop.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n\n"
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") not in clsp.find_final_definitions()


def test_drop_earlier_file_create_later_file_leaves_object_expected(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_drop.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    (d / "02_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    final = clsp.find_final_definitions()
    assert ("state", "foo") in final
    _ot, _p, src, _body = final[("state", "foo")]
    assert src == "02_create.sql"


def test_drop_stmt_matches_every_real_object_type_form():
    cases = [
        ("DROP VIEW `stock-trading-498512.state.foo`;",
         "VIEW", "state", "foo"),
        ("DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;",
         "VIEW", "state", "foo"),
        ("DROP TABLE `stock-trading-498512.ops.foo`;",
         "TABLE", "ops", "foo"),
        ("DROP TABLE IF EXISTS `stock-trading-498512.ops.foo`;",
         "TABLE", "ops", "foo"),
        ("DROP PROCEDURE `stock-trading-498512.ops.sp_foo`;",
         "PROCEDURE", "ops", "sp_foo"),
        ("DROP PROCEDURE IF EXISTS `stock-trading-498512.ops.sp_foo`;",
         "PROCEDURE", "ops", "sp_foo"),
        ("DROP FUNCTION `stock-trading-498512.analytics.fn_foo`;",
         "FUNCTION", "analytics", "fn_foo"),
        ("DROP FUNCTION IF EXISTS `stock-trading-498512.analytics.fn_foo`;",
         "FUNCTION", "analytics", "fn_foo"),
        ("DROP MATERIALIZED VIEW `stock-trading-498512.analytics.mv_foo`;",
         "MATERIALIZED VIEW", "analytics", "mv_foo"),
        ("DROP MATERIALIZED VIEW IF EXISTS `stock-trading-498512.analytics.mv_foo`;",
         "MATERIALIZED VIEW", "analytics", "mv_foo"),
    ]
    for txt, expected_type, expected_dataset, expected_name in cases:
        m = clsp.DROP_STMT.search(txt)
        assert m is not None, f"DROP_STMT did not match: {txt}"
        obj_type, project, dataset, name = m.groups()
        assert " ".join(obj_type.split()) == expected_type, txt
        assert (project, dataset, name) == ("stock-trading-498512", expected_dataset, expected_name), txt


def test_drop_stmt_matches_partially_backtick_quoted_identifier():
    # bigquery/104's and bigquery/108's real DROP statements fully backtick-quote the identifier
    # (`` `project.dataset.name` ``), but this repo also writes the PARTIALLY-quoted form elsewhere
    # (backticks around the project id only) -- DROP_STMT must accept both.
    txt = "DROP VIEW IF EXISTS `stock-trading-498512`.state.foo;"
    m = clsp.DROP_STMT.search(txt)
    assert m is not None
    assert m.groups() == ("VIEW", "stock-trading-498512", "state", "foo")


def test_drop_word_inside_comment_or_string_literal_does_not_remove_object(tmp_path, monkeypatch):
    # A "DROP" that is NOT a genuine top-level statement -- inside a `--` comment, or inside a
    # string literal passed to EXECUTE IMMEDIATE/FORMAT() (mirroring bigquery/17_restore_drill.sql's
    # embedded CREATE) -- must never remove the object from the expected set. Both cases here are
    # safe for the SAME reason CREATE_STMT already is: the DROP text is not at column 0.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_not_a_real_drop.sql").write_text(
        "-- DROP VIEW IF EXISTS `stock-trading-498512.state.foo`; (do NOT actually drop this)\n"
        "BEGIN\n"
        "  EXECUTE IMMEDIATE FORMAT(\n"
        "      \"DROP VIEW IF EXISTS `stock-trading-498512.state.foo`\");\n"
        "END;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") in clsp.find_final_definitions()


def test_embedded_format_string_create_statement_is_not_a_false_positive():
    # bigquery/17_restore_drill.sql contains an indented "CREATE OR REPLACE TABLE ..." inside a
    # FORMAT() string literal passed to EXECUTE IMMEDIATE — the column-0-anchored regex must skip it.
    final = clsp.find_final_definitions()
    assert ("events_restore_drill", "%s__typed") not in final
    assert not any("events_restore_drill" in name for (_, name) in final)


def test_extract_body_strips_view_preamble_and_trailing_semicolon():
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"


def test_extract_body_retains_procedure_begin_end_wrapper():
    # Fixed 2026-07-16 (live-sql-parity self-heal audit, RES-3 step 0a): live
    # INFORMATION_SCHEMA.ROUTINES.routine_definition for a PROCEDURE INCLUDES the outer
    # BEGIN...END wrapper (verified live on ops.sp_log_decision, definition starts 'BEGIN\n'), so
    # the repo-side extraction must keep it too -- stripping it (the old behavior this test used to
    # assert) made every procedure spuriously DRIFT against the live body, the ~24-object
    # false-positive class behind issue #10.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  SELECT x;\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == "BEGIN\n  SELECT x;\nEND"


def test_normalize_tail_matches_repo_extraction_despite_live_trailing_comments():
    # A live-style body (INFORMATION_SCHEMA definition retaining a trailing comment/blank line the
    # repo-side next-statement boundary already excludes) must normalize to the same text as the
    # repo-extracted body once normalize_tail is applied to both (RES-3 step 0b).
    repo_txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
    )
    m = clsp.CREATE_STMT.search(repo_txt)
    repo_body = clsp.extract_body(repo_txt, m.start(), "VIEW")

    live_style_body = "SELECT 1 AS x\nFROM bar;\n-- trailing live comment\n\n"
    assert clsp.normalize_tail(live_style_body) == repo_body


def test_view_body_stops_at_a_following_non_compared_create(monkeypatch):
    # 2026-07-17 audit: CREATE_STMT only recognizes VIEW/PROCEDURE/TABLE FUNCTION, so when one of
    # those is followed by a top-level CREATE TABLE / scalar CREATE FUNCTION / CREATE MODEL /
    # CREATE SCHEMA, the older boundary (CREATE_STMT.search) skipped past it and BLED that foreign
    # DDL into the object's extracted body -> permanent false DRIFT. The boundary now stops at ANY
    # top-level CREATE (NEXT_TOP_LEVEL).
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
        "\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.sink` (\n"
        "  id INT64\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"
    assert "CREATE TABLE" not in body


def test_procedure_body_stops_at_a_following_create_table(monkeypatch):
    # Same boundary bug, PROCEDURE side: sp_log_run's body used to swallow the CREATE TABLE
    # IF NOT EXISTS ops.alerts that follows its own END; (bigquery/10_observability.sql).
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  SELECT x;\n"
        "END;\n"
        "\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.alerts` (\n"
        "  id INT64\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == "BEGIN\n  SELECT x;\nEND"
    assert "CREATE TABLE" not in body


def test_inline_as_select_header_is_not_sliced_by_a_column_alias(monkeypatch):
    # 2026-07-17 audit: an inline `... AS SELECT` header (AS and SELECT on one line) with a later
    # `expr AS\n` column alias used to make the old first-branch (`AS\s*\n`) match the alias instead
    # of the header AS, dropping `SELECT ... AS` off the front. Using the first standalone AS fixes it.
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS SELECT\n"
        "  a AS\n"
        "  b\n"
        "FROM t;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body.startswith("SELECT")
    assert body == "SELECT\n  a AS\n  b\nFROM t"


def test_no_object_in_the_real_tree_bleeds_a_foreign_statement_into_its_body():
    # Strong invariant guarding the boundary fix against regression: no extracted body may contain a
    # column-0 top-level statement (CREATE *or* a DML/DDL statement like MERGE/INSERT/... that follows
    # the object). The old guard only rejected a bled ^CREATE, so it could not catch the ci_findings_open
    # MERGE bleed (2026-07-17 HIGH); this broadened set matches NEXT_TOP_LEVEL's own keyword list so any
    # bled top-level statement fails the invariant.
    import re
    top = re.compile(r"^(CREATE|INSERT|MERGE|UPDATE|DELETE|TRUNCATE|DROP|ALTER|GRANT|REVOKE|CALL|EXPORT|ASSERT)\b",
                     re.MULTILINE)
    final = clsp.find_final_definitions()
    bled = [f"{ds}.{nm}" for (ds, nm), (_ot, _p, _src, body) in final.items() if top.search(body)]
    assert bled == [], f"objects bleeding a foreign top-level statement into their body: {bled}"


def test_view_body_stops_at_a_following_top_level_merge():
    # 2026-07-17 HIGH regression: bigquery/67 ends `CREATE OR REPLACE VIEW state.ci_findings_open AS
    # SELECT … ;` then runs a standalone `MERGE …` registry bump. A CREATE-only boundary swept the
    # MERGE into the view body -> permanent false DRIFT vs the live view_definition (just the SELECT).
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
        "\n"
        "-- a standalone registry-bump comment\n"
        "MERGE `stock-trading-498512.state.reg` T\n"
        "USING (SELECT 'a' AS k) S ON T.k = S.k\n"
        "WHEN NOT MATCHED THEN INSERT (k) VALUES (S.k);\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"
    assert "MERGE" not in body


def test_ci_findings_open_real_body_has_no_bled_merge():
    # Direct lock on the real object behind the HIGH finding: its final-effective body must be only the
    # SELECT, never the trailing MERGE from bigquery/67_ci_findings_bridge.sql. Since 2026-07-18 the
    # canonical definition is bigquery/86 (adds episode-aware first_detected); the synthetic bleed test
    # above still locks the 67-shaped statement-boundary behavior itself.
    final = clsp.find_final_definitions()
    _ot, _p, src, body = final[("state", "ci_findings_open")]
    assert src == "86_ci_findings_first_detected.sql"
    assert "MERGE" not in body
    assert body.strip().endswith("ON e.workflow = o.workflow AND e.finding_key = o.finding_key")


# ---- extract_body: TABLE FUNCTION branch (single AS ( ... ) wrapper) ------------------------------
def test_extract_body_table_function_strips_outer_paren_wrapper():
    # All live TABLE FUNCTIONs in this repo are a single `AS ( SELECT ... )` wrapper; extract_body
    # drops the one outer paren pair. Exercised only against live BigQuery before now.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS (\n"
        "  SELECT p AS y\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "SELECT p AS y"


def test_extract_body_table_function_no_outer_wrapper_is_left_intact():
    # 2026-07-18 audit fix: a body shaped `(SELECT a) UNION ALL (SELECT b)` — no extra outer wrap —
    # merely starts/ends with a paren, but the leading "(" is NOT matched by the trailing ")". The
    # old naive startswith/endswith strip corrupted this into unbalanced garbage; the paren-depth
    # guard must leave both inner paren pairs intact.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS\n"
        "  (SELECT p AS y) UNION ALL (SELECT p + 1 AS y)\n"
        ";\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "(SELECT p AS y) UNION ALL (SELECT p + 1 AS y)"


def test_extract_body_table_function_genuine_wrapper_around_union_stays_correct():
    # The genuine-wrapper counterpart: an actual `AS ( ... )` wrapper around a union of parenthesized
    # subqueries must still have exactly its own outer pair stripped, since paren depth here DOES
    # return to 0 only at the final character.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS (\n"
        "  (SELECT p AS y) UNION ALL (SELECT p + 1 AS y)\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "(SELECT p AS y) UNION ALL (SELECT p + 1 AS y)"


# ---- bq(): thin delegation to lib/bq_json.run_bq_query -- the shared subprocess-invoke/JSON-parse/
# returncode/timeout contract is proven ONCE on run_bq_query itself (tests/test_bq_json.py); this
# just pins that THIS caller forwards sql/project with no extra fixed args (plain delegation, unlike
# roster/dbt_parity/alert_relay's max_rows=N) (C3 dedup, 2026-07-20 audit).
def test_bq_delegates_to_run_bq_query_with_no_extra_fixed_args(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project):
        captured["sql"], captured["project"] = sql, project
        return [{"view_definition": "SELECT 1"}]
    monkeypatch.setattr(clsp, "run_bq_query", fake_run_bq_query)
    assert clsp.bq("SELECT 1", "proj") == [{"view_definition": "SELECT 1"}]
    assert captured == {"sql": "SELECT 1", "project": "proj"}


# ---- live_definition(): per-object-type query shape + key extraction ------------------------------
def test_live_definition_view_reads_views_and_returns_view_definition(monkeypatch):
    seen = {}

    def fake_bq(sql, project):
        seen["sql"], seen["project"] = sql, project
        return [{"view_definition": "SELECT 1 AS x"}]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    assert clsp.live_definition("proj", "state", "foo", "VIEW") == "SELECT 1 AS x"
    assert "INFORMATION_SCHEMA.VIEWS" in seen["sql"] and "table_name = 'foo'" in seen["sql"]
    assert seen["project"] == "proj"


def test_live_definition_procedure_reads_routines_with_type_filter(monkeypatch):
    def fake_bq(sql, project):
        assert "INFORMATION_SCHEMA.ROUTINES" in sql and "routine_type = 'PROCEDURE'" in sql
        return [{"routine_definition": "BEGIN SELECT 1; END"}]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    assert clsp.live_definition("proj", "ops", "sp_foo", "PROCEDURE") == "BEGIN SELECT 1; END"


def test_live_definition_table_function_reads_routines_with_type_filter(monkeypatch):
    def fake_bq(sql, project):
        assert "INFORMATION_SCHEMA.ROUTINES" in sql and "routine_type = 'TABLE FUNCTION'" in sql
        return [{"routine_definition": "SELECT 1"}]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    assert clsp.live_definition("proj", "analytics", "fn_x", "TABLE FUNCTION") == "SELECT 1"


def test_live_definition_returns_none_when_no_rows(monkeypatch):
    monkeypatch.setattr(clsp, "bq", lambda sql, project: [])
    assert clsp.live_definition("proj", "state", "missing", "VIEW") is None


# ---- main(): --project CLI-flag plumbing through to live_definition()/bq() ------------------------
def test_main_passes_project_flag_through(monkeypatch):
    # Locks the exact bug class the code comment at main()'s live_definition() call site guards
    # against ("a parsed-but-ignored argument") -- mirrors
    # test_check_live_roster_parity.py's test_main_passes_project_flag_through.
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--project", "custom-proj-9"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_live_definition(project, ds, nm, ot):
        captured["project"] = project
        return "SELECT 1 AS x"
    monkeypatch.setattr(clsp, "live_definition", fake_live_definition)
    assert clsp.main() == 0
    assert captured["project"] == "custom-proj-9"


def test_main_passes_project_flag_through_gnu_equals_form(monkeypatch):
    # Same lock as test_main_passes_project_flag_through above, but pins the GNU `--project=X`
    # single-token form specifically. This is the half of the 2026-07-20 fix the two-token form alone
    # doesn't cover: the OLD hand-rolled argv loop only matched `--project X` (two tokens), so
    # `--project=X` silently kept the hardcoded default project -- a test using only the two-token
    # form would have passed against that old buggy code too and missed the regression entirely.
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--project=custom-proj-9"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_live_definition(project, ds, nm, ot):
        captured["project"] = project
        return "SELECT 1 AS x"
    monkeypatch.setattr(clsp, "live_definition", fake_live_definition)
    assert clsp.main() == 0
    assert captured["project"] == "custom-proj-9"


def test_main_unrecognized_flag_is_hard_error(monkeypatch):
    # argparse turns an unknown flag into a hard SystemExit (argparse's usage-error exit) instead of
    # the old hand-rolled argv loop's silent no-op -- pins the other half of the 2026-07-20 fix.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--bogus"])
    with pytest.raises(SystemExit):
        clsp.main()


def test_main_default_project_is_stock_trading(monkeypatch):
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_live_definition(project, ds, nm, ot):
        captured["project"] = project
        return "SELECT 1 AS x"
    monkeypatch.setattr(clsp, "live_definition", fake_live_definition)
    assert clsp.main() == 0
    assert captured["project"] == "stock-trading-498512"


# ---- main(): offline flag, drift/clean exit codes, and the missing-live skip ----------------------
def test_main_offline_returns_0_without_touching_bq(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--offline"])

    def _forbidden(*a, **k):
        raise AssertionError("live_definition must not be called in --offline mode")
    monkeypatch.setattr(clsp, "live_definition", _forbidden)
    assert clsp.main() == 0
    assert "offline" in capsys.readouterr().out.lower()


def test_main_reports_ok_when_live_matches_after_whitespace_collapse(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})
    # Live body differs only by whitespace -> collapse() equalizes -> no drift.
    monkeypatch.setattr(clsp, "live_definition", lambda project, ds, nm, ot: "SELECT   1   AS x")
    assert clsp.main() == 0
    assert "OK:" in capsys.readouterr().out


def test_main_reports_drift_and_exits_1(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})
    monkeypatch.setattr(clsp, "live_definition", lambda *a: "SELECT 2 AS x")
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "DRIFT" in out and "state.foo" in out


def test_main_missing_object_is_a_distinct_finding_and_fails_the_run(monkeypatch, capsys):
    # FIX 2 (2026-07-28): a live lookup that SUCCEEDS with zero rows is POSITIVE evidence of
    # absence for an object the repo's final-effective bigquery/*.sql still expects -- distinct
    # from a lookup FAILURE (exception, tested separately below) -- and must fail the run, not be
    # silently swallowed as an inconclusive skip the way it used to be.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "present"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })

    def fake_live(project, ds, nm, ot):
        return None if nm == "gone" else "SELECT 1 AS x"   # 'present' matches; 'gone' not found live
    monkeypatch.setattr(clsp, "live_definition", fake_live)
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "MISSING" in out and "state.gone" in out and "no live object found" in out
    assert "DRIFT" not in out   # a genuine absence is not a text-mismatch drift


def test_main_lookup_exception_is_a_skip_and_does_not_fail_the_run_alone(monkeypatch, capsys):
    # The OTHER half of FIX 2: an exception during lookup (transient/auth/timeout) must stay a
    # SKIP -- never promoted to missing_objects or findings -- and must not, by itself, fail an
    # otherwise-clean run (a second object still verifies clean, so checked>0).
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "present"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "flaky"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })

    def fake_live(project, ds, nm, ot):
        if nm == "flaky":
            raise RuntimeError("timeout")
        return "SELECT 1 AS x"
    monkeypatch.setattr(clsp, "live_definition", fake_live)
    assert clsp.main() == 0
    out = capsys.readouterr().out
    assert "skipped" in out and "state.flaky" in out and "live lookup failed" in out
    assert "MISSING" not in out


def test_main_fails_closed_when_every_object_is_skipped(monkeypatch, capsys):
    # 2026-07-17 parallel-refactor audit: a systemic live-read failure (every live_definition raises —
    # WIF/auth broken) sends ALL objects to missing_live, checked stays 0. Reporting OK would be a
    # vacuous green on zero comparisons that hides a completely broken gate; must fail closed instead.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "a"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "b"): ("VIEW", "proj", "02.sql", "SELECT 2 AS y"),
    })

    def boom(*a):
        raise RuntimeError("bq auth error: could not refresh WIF token")
    monkeypatch.setattr(clsp, "live_definition", boom)
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED" in out and "zero comparisons" in out


def test_main_json_out_writes_findings_skips_and_missing_objects(tmp_path, monkeypatch):
    # FIX 2/3 (2026-07-28): three distinct outcomes across three objects -- a real mismatch (a
    # "findings" re-apply self-heal candidate), a lookup exception (a "skipped" inconclusive read),
    # and a genuine absence (a "missing_objects" CREATE self-heal candidate as of the 2026-07-28
    # owner directive -- non-zero exit, but its own category, NEVER merged into "findings", because
    # the two categories drive different self-heal actions -- re-apply vs. create; see
    # write_json_out()'s docstring).
    out_path = tmp_path / "findings.json"
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--json-out", str(out_path)])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "drifted"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
        ("state", "flaky"): ("VIEW", "proj", "03.sql", "SELECT 3 AS w"),
    })

    def fake_live(project, ds, nm, ot):
        if nm == "gone":
            return None                    # lookup succeeded, zero rows -> missing_objects
        if nm == "flaky":
            raise RuntimeError("timeout")  # lookup failed -> skipped
        return "SELECT 2 AS x"             # drifted mismatches -> findings
    monkeypatch.setattr(clsp, "live_definition", fake_live)
    assert clsp.main() == 1
    payload = json.loads(out_path.read_text())
    assert [f["name"] for f in payload["findings"]] == ["drifted"]     # only the real mismatch is a finding
    assert not any("gone" in f["name"] for f in payload["findings"])   # absence never lands in "findings"
                                                                        # (own key -> own self-heal action,
                                                                        # not "never a self-heal candidate")
    assert any("flaky" in s for s in payload["skipped"])               # the lookup failure is a skip
    assert not any("gone" in s for s in payload["skipped"])            # ...and absence is no longer a skip
    assert any("gone" in s for s in payload["missing_objects"])        # absence gets its own category
    assert "checked_at" in payload


# ---- write_json_out(): structured findings/skipped/missing_objects payload ------------------------
def test_write_json_out_shape(tmp_path):
    out_path = tmp_path / "f.json"
    clsp.write_json_out(str(out_path),
                        [{"dataset": "state", "name": "foo", "object_type": "VIEW", "source_file": "01.sql"}],
                        ["state.bar (02.sql): live lookup failed: timeout"],
                        ["state.baz (03.sql): no live object found -- repo's final-effective "
                         "bigquery/*.sql expects this object but live has none (lookup succeeded, "
                         "zero rows)"])
    payload = json.loads(out_path.read_text())
    assert payload["findings"][0]["name"] == "foo"
    assert payload["skipped"] == ["state.bar (02.sql): live lookup failed: timeout"]
    assert payload["missing_objects"] == [
        "state.baz (03.sql): no live object found -- repo's final-effective bigquery/*.sql expects "
        "this object but live has none (lookup succeeded, zero rows)"]
    assert payload["checked_at"].endswith("Z")


# ---- numbered_sql_files(): NUMERIC (not lexical) apply-order --------------------------------------
def test_numbered_sql_files_sorts_numerically_not_lexically(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    for fn in ("2_b.sql", "10_c.sql", "1_a.sql", "notes.md", "readme_no_number.sql"):
        (d / fn).write_text("-- x\n")
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    got = [os.path.basename(p) for p in clsp.numbered_sql_files()]
    assert got == ["1_a.sql", "2_b.sql", "10_c.sql"]   # numeric order; unnumbered/non-sql excluded


# ---- canonicalize(): compare MEANING, not formatting (2026-07-18) -----------------------------
# BigQuery RE-SERIALIZES stored view/routine definitions: comments stripped, whitespace next to
# punctuation removed, backticks dropped, string-quote style normalized. The old raw-text compare
# (collapse) therefore reported 70 of 179 objects as DRIFT when only 5 differed in meaning — a 93%
# false-positive rate on the very gate meant to catch the 2026-07-11 silent trading_enabled revert.
# Each test below pins one measured false-positive class; the LAST group pins that real drift still
# fires, so the fix cannot blind the check.

def _same(a, b):
    return clsp.canonicalize(a) == clsp.canonicalize(b)


def test_canonicalize_ignores_comments_the_live_definition_does_not_keep():
    repo = "SELECT a,  -- why this column exists\n       b\nFROM t"
    live = "SELECT a, b FROM t"
    assert _same(repo, live)


def test_canonicalize_ignores_whitespace_adjacent_to_punctuation():
    # The single most common shape: repo `AS (\n  SELECT`, live `AS (SELECT`.
    assert _same("WITH c AS (\n  SELECT 1\n)\nSELECT * FROM c", "WITH c AS (SELECT 1)SELECT * FROM c")
    assert _same("COALESCE(( SELECT 1 ), 0)", "COALESCE((SELECT 1),0)")


def test_canonicalize_ignores_identifier_backticks():
    assert _same("SELECT * FROM `proj.ds.tbl`", "SELECT * FROM proj.ds.tbl")


def test_canonicalize_ignores_string_quote_style():
    assert _same("WHERE series = 'deployed_unit_value'", 'WHERE series = "deployed_unit_value"')


def test_canonicalize_merges_whitespace_left_behind_by_a_removed_comment():
    # Stripping a comment leaves whitespace on BOTH sides; unmerged it yields "wins  FROM" (two
    # spaces) and never matches live. This was the bug that kept 24 objects "drifted" mid-fix.
    assert _same("SELECT wins   -- note\n   FROM t", "SELECT wins FROM t")


def test_canonicalize_keeps_whitespace_that_separates_words():
    # Must NOT fuse tokens: `SELECT x` is not `SELECTx`.
    assert not _same("SELECT x", "SELECTx")
    assert clsp.canonicalize("SELECT   x") == "SELECT x"


# ---- the check must still SEE real drift ------------------------------------------------------

def test_canonicalize_still_detects_an_added_predicate():
    # The measured ops.sp_assert_deps / state.cadence_watch finding: live carries a 14-day window
    # the repo lacks. This is real drift and must survive canonicalization.
    repo = "WHERE r.routine=d AND r.status='completed')"
    live = "WHERE r.routine=d AND r.status='completed' AND r.run_date>=DATE_SUB(in_run_date,INTERVAL 14 DAY))"
    assert not _same(repo, live)


def test_canonicalize_still_detects_an_added_statement():
    # The measured gate-procedure finding: live has a self-heal CALL block the repo lacks.
    repo = "BEGIN DECLARE v BOOL; SET v=(SELECT x FROM t); END"
    live = ("BEGIN DECLARE v BOOL; BEGIN CALL ops.sp_auto_resolve_alerts(); "
            "EXCEPTION WHEN ERROR THEN SELECT @@error.message; END; SET v=(SELECT x FROM t); END")
    assert not _same(repo, live)


def test_canonicalize_treats_string_CONTENT_as_significant():
    # A `--`, an em-dash, or extra spacing INSIDE a literal is content, not formatting. The measured
    # ops.sp_score_theater finding (em-dash vs hyphen in a prompt string) must NOT be swallowed.
    assert not _same("SELECT 'diverges from the attacker — rather than'",
                     "SELECT 'diverges from the attacker - rather than'")
    assert not _same("SELECT 'a  b'", "SELECT 'a b'")
    assert not _same("SELECT 'keep -- this'", "SELECT 'keep'")


def test_canonicalize_handles_empty_and_none():
    assert clsp.canonicalize("") == ""
    assert clsp.canonicalize(None) is None

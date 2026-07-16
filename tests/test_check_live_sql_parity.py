"""Offline tests for scripts/check_live_sql_parity.py's repo-side extraction (no BigQuery needed).

Locks in the two properties verified by hand while writing this script: (1) apply-in-order
resolution picks the LAST bigquery/NN_*.sql file that CREATE OR REPLACEs a given object, and (2) an
indented CREATE OR REPLACE embedded inside a FORMAT() string literal (bigquery/17_restore_drill.sql)
must never be mistaken for a real top-level statement.
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_live_sql_parity.py")
    spec = importlib.util.spec_from_file_location("check_live_sql_parity", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


clsp = _load()


def test_parses_the_real_repo_without_crashing():
    final = clsp.find_final_definitions()
    assert len(final) > 100  # 137 at time of writing; a generous floor so new files don't break this


def test_apply_order_last_file_wins_for_a_known_redefinition():
    final = clsp.find_final_definitions()
    # bigquery/47 supersedes 34, which supersedes 23, for state.trading_enabled.
    _, _, source_file, _ = final[("state", "trading_enabled")]
    assert source_file == "47_trading_enabled_resync.sql"
    # bigquery/34 is still the final (unsuperseded) definition of trading_enabled_mechanical.
    _, _, source_file2, _ = final[("state", "trading_enabled_mechanical")]
    assert source_file2 == "34_alert_lifecycle.sql"


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


def test_collapse_normalizes_whitespace_for_comparison():
    assert clsp.collapse("SELECT   1\nFROM  bar") == "SELECT 1 FROM bar"

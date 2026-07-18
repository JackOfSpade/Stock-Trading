"""Offline tests for scripts/check_live_sql_parity.py's repo-side extraction (no BigQuery needed).

Locks in the two properties verified by hand while writing this script: (1) apply-in-order
resolution picks the LAST bigquery/NN_*.sql file that CREATE OR REPLACEs a given object, and (2) an
indented CREATE OR REPLACE embedded inside a FORMAT() string literal (bigquery/17_restore_drill.sql)
must never be mistaken for a real top-level statement.
"""
import importlib.util
import json
import os
import sys
import types

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_live_sql_parity.py")
    spec = importlib.util.spec_from_file_location("check_live_sql_parity", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


clsp = _load()


def _fake_run(returncode, stdout, stderr=""):
    def run(cmd, capture_output=None, text=None, timeout=None):
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


def test_parses_the_real_repo_without_crashing():
    final = clsp.find_final_definitions()
    assert len(final) > 100  # 137 at time of writing; a generous floor so new files don't break this


def test_apply_order_last_file_wins_for_a_known_redefinition():
    final = clsp.find_final_definitions()
    # bigquery/78 (2026-07-17 audit C1 + staleness-gate rebase) supersedes 47, which superseded 34,
    # which superseded 23, for state.trading_enabled.
    _, _, source_file, _ = final[("state", "trading_enabled")]
    assert source_file == "78_book_drawdown_rebase_and_staleness_gate.sql"
    # bigquery/78 also supersedes 34's state.trading_enabled_mechanical (same gate rebase).
    _, _, source_file2, _ = final[("state", "trading_enabled_mechanical")]
    assert source_file2 == "78_book_drawdown_rebase_and_staleness_gate.sql"


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
    # SELECT, never the trailing MERGE from bigquery/67_ci_findings_bridge.sql.
    final = clsp.find_final_definitions()
    _ot, _p, src, body = final[("state", "ci_findings_open")]
    assert src == "67_ci_findings_bridge.sql"
    assert "MERGE" not in body
    assert body.strip().endswith("status = 'open'")


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


# ---- bq(): the subprocess/JSON-slice wrapper (same regressed class as dbt_parity.bq) --------------
def test_bq_parses_banner_prefixed_json(monkeypatch):
    monkeypatch.setattr(clsp.subprocess, "run",
                        _fake_run(0, 'Waiting on bqjob [RUNNING]\n[{"view_definition": "SELECT 1"}]'))
    assert clsp.bq("SELECT 1", "proj") == [{"view_definition": "SELECT 1"}]


def test_bq_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(clsp.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(RuntimeError):
        clsp.bq("SELECT 1", "proj")


def test_bq_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise clsp.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(clsp.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        clsp.bq("SELECT 1", "proj")


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


def test_main_skips_a_missing_live_object_without_reporting_drift(monkeypatch, capsys):
    # A single missing-live object among otherwise-verified objects is a SKIP, not a DRIFT. (A second
    # object that verifies cleanly keeps checked>0 so the checked==0 fail-closed guard doesn't fire —
    # that guard only trips when NOTHING was verified.)
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "present"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })

    def fake_live(project, ds, nm, ot):
        return None if nm == "gone" else "SELECT 1 AS x"   # 'present' matches; 'gone' not found live
    monkeypatch.setattr(clsp, "live_definition", fake_live)
    assert clsp.main() == 0                                  # 'present' verified clean; a lookup miss is a skip
    assert "no live object found" in capsys.readouterr().out


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


def test_main_json_out_writes_findings_and_skips(tmp_path, monkeypatch):
    out_path = tmp_path / "findings.json"
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--json-out", str(out_path)])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "drifted"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })

    def fake_live(project, ds, nm, ot):
        return None if nm == "gone" else "SELECT 2 AS x"   # drifted mismatches, gone is a lookup miss
    monkeypatch.setattr(clsp, "live_definition", fake_live)
    assert clsp.main() == 1
    payload = json.loads(out_path.read_text())
    assert [f["name"] for f in payload["findings"]] == ["drifted"]   # only the real mismatch is a finding
    assert any("gone" in s for s in payload["skipped"])               # the lookup miss is a skip, never a finding
    assert "checked_at" in payload


# ---- write_json_out(): structured findings/skipped payload ----------------------------------------
def test_write_json_out_shape(tmp_path):
    out_path = tmp_path / "f.json"
    clsp.write_json_out(str(out_path),
                        [{"dataset": "state", "name": "foo", "object_type": "VIEW", "source_file": "01.sql"}],
                        ["state.bar (02.sql): no live object found"])
    payload = json.loads(out_path.read_text())
    assert payload["findings"][0]["name"] == "foo"
    assert payload["skipped"] == ["state.bar (02.sql): no live object found"]
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

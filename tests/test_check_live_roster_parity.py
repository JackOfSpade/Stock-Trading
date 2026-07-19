"""Offline tests for scripts/check_live_roster_parity.py (no BigQuery, no creds).

This safety-critical CI gate (.github/workflows/live-sql-parity.yml — exit 1 FAILS THE JOB) shipped with
ZERO dedicated tests, unlike its siblings dbt_parity.py (tests/test_dbt_parity.py) and
check_live_sql_parity.py (tests/test_check_live_sql_parity.py). It compares the live
state.active_strategy_codes set against strategy/roster.yaml's roster-active (probe/adopted) set and must
FAIL CLOSED on any live-read failure — a parity gate that reports OK on a swallowed exception or a
zero-vs-zero comparison is worse than no gate. These lock: bq()'s read-only argv + banner-tolerant JSON
parsing + returncode/timeout handling; roster_active_codes()'s probe/adopted filter (and its
docstring-promised parity with check_roster_consistency.py's R-A definition); live_active_codes()'s
extraction; and every main() branch (SKIP / OK / drift-FAIL / FAIL-CLOSED / both-empty-NOT-VERIFIED).

Added 2026-07-17 (parallel-refactor Part A) alongside the both-empty NOT-VERIFIED guard fix.
"""
import os
import sys

import pytest

from conftest import fake_subprocess_run as _fake_run
from conftest import load_module_from_path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

clrp = load_module_from_path("check_live_roster_parity", "scripts", "check_live_roster_parity.py")
# The other roster gate — imported only to lock the docstring-promised roster_active_codes() parity.
crc = load_module_from_path("check_roster_consistency", "scripts", "check_roster_consistency.py")


@pytest.fixture(autouse=True)
def _clean_argv(monkeypatch):
    # main() calls argparse.parse_args(), which reads sys.argv by default; under pytest that would be the
    # runner's args. Pin a clean argv so tests see the real defaults, not pytest's flags.
    monkeypatch.setattr(sys, "argv", ["check_live_roster_parity.py"])


def _write_roster(path, entries):
    """entries: list of (code, roster_state). Minimal valid roster.yaml body."""
    lines = ["strategies:"]
    for code, state in entries:
        lines += [f"  - code: {code}", f"    roster_state: {state}"]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ---- bq(): read-only argv + banner-tolerant JSON parse (the exact regressed bug class) ------------
def test_bq_parses_banner_prefixed_json(monkeypatch):
    fake = _fake_run(0, 'Welcome to BigQuery!\nUpdate available.\n[{"strategy_code":"A"}]')
    monkeypatch.setattr(clrp.subprocess, "run", fake)
    assert clrp.bq("SELECT 1", "proj") == [{"strategy_code": "A"}]


def test_bq_empty_when_no_array(monkeypatch):
    monkeypatch.setattr(clrp.subprocess, "run", _fake_run(0, "No rows.\n"))
    assert clrp.bq("SELECT 1", "proj") == []


def test_bq_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(clrp.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(RuntimeError, match="access denied"):
        clrp.bq("SELECT 1", "proj")


def test_bq_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise clrp.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(clrp.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        clrp.bq("SELECT 1", "proj")


def test_bq_uses_readonly_argv_and_timeout(monkeypatch):
    fake = _fake_run(0, "[]")
    monkeypatch.setattr(clrp.subprocess, "run", fake)
    clrp.bq("SELECT strategy_code FROM t", "myproj-123")
    cmd = fake.calls[0]["cmd"]
    assert cmd == ["bq", "--project_id=myproj-123", "--quiet", "--headless", "--format=json",
                   "query", "--use_legacy_sql=false", "--max_rows=100000",
                   "SELECT strategy_code FROM t"]
    assert fake.calls[0]["timeout"] == 600
    # read-only: no bq write/insert/load subcommand ever appears in the argv.
    assert not ({"insert", "load", "cp", "rm", "mk"} & set(cmd))


# ---- roster_active_codes(): probe/adopted only, case-insensitive, + R-A parity lock ---------------
def test_roster_active_codes_real_repo_is_a_e():
    assert clrp.roster_active_codes() == {"A", "B", "C", "D", "E"}


def test_roster_active_codes_matches_check_roster_consistency_r_a():
    # Docstring promise: this file's roster-active definition is IDENTICAL to check_roster_consistency.py's
    # R-A. Lock it so the two safety gates can never silently diverge on what "roster-active" means.
    assert clrp.roster_active_codes() == crc.roster_active_codes(crc.roster_doc())


def test_roster_active_codes_filters_and_is_case_insensitive(tmp_path, monkeypatch):
    roster = tmp_path / "roster.yaml"
    _write_roster(roster, [("A", "ADOPTED"), ("B", "Probe"), ("C", "candidate"),
                           ("D", "shadow"), ("E", "retired")])
    monkeypatch.setattr(clrp, "ROSTER", str(roster))
    assert clrp.roster_active_codes() == {"A", "B"}     # only probe/adopted, any case


def test_roster_active_codes_no_active_is_empty_set(tmp_path, monkeypatch):
    roster = tmp_path / "roster.yaml"
    _write_roster(roster, [("A", "candidate"), ("B", "shadow")])
    monkeypatch.setattr(clrp, "ROSTER", str(roster))
    assert clrp.roster_active_codes() == set()


# ---- live_active_codes(): extraction + query target + empty/malformed handling -------------------
def test_live_active_codes_extracts_codes_and_targets_active_view(monkeypatch):
    captured = {}

    def fake_bq(sql, project):
        captured["sql"], captured["project"] = sql, project
        return [{"strategy_code": "A"}, {"strategy_code": "B"}]
    monkeypatch.setattr(clrp, "bq", fake_bq)
    assert clrp.live_active_codes("myproj") == {"A", "B"}
    assert "myproj" in captured["sql"] and "state.active_strategy_codes" in captured["sql"]
    assert captured["project"] == "myproj"


def test_live_active_codes_empty_result_is_empty_set(monkeypatch):
    monkeypatch.setattr(clrp, "bq", lambda sql, project: [])
    assert clrp.live_active_codes("proj") == set()


def test_live_active_codes_row_missing_strategy_code_raises(monkeypatch):
    # A malformed row (no strategy_code) must raise, not silently drop — main() turns it into FAIL-CLOSED.
    monkeypatch.setattr(clrp, "bq", lambda sql, project: [{"unexpected": "x"}])
    with pytest.raises(KeyError):
        clrp.live_active_codes("proj")


# ---- main(): SKIP / OK / drift-FAIL / FAIL-CLOSED / both-empty -----------------------------------
def test_main_skips_when_roster_absent(monkeypatch, capsys):
    monkeypatch.setattr(clrp, "ROSTER", os.path.join(ROOT, "strategy", "does_not_exist.yaml"))
    assert clrp.main() == 0
    assert "SKIP" in capsys.readouterr().out


def test_main_ok_when_live_matches_roster(monkeypatch, capsys):
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C", "D", "E"})
    monkeypatch.setattr(clrp, "live_active_codes", lambda project: {"A", "B", "C", "D", "E"})
    assert clrp.main() == 0
    assert "LIVE ROSTER PARITY: OK" in capsys.readouterr().out


def test_main_fails_on_drift_naming_both_directions(monkeypatch, capsys):
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C"})
    monkeypatch.setattr(clrp, "live_active_codes", lambda project: {"A", "B", "D"})
    assert clrp.main() == 1
    out = capsys.readouterr().out
    assert "FAIL" in out
    assert "'C'" in out                          # in roster.yaml but NOT live
    assert "'D'" in out                          # LIVE but NOT in roster.yaml


def test_main_fails_closed_when_live_read_raises(monkeypatch, capsys):
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C", "D", "E"})

    def boom(project):
        raise RuntimeError("bq auth error")
    monkeypatch.setattr(clrp, "live_active_codes", boom)
    assert clrp.main() == 1
    assert "NOT VERIFIED" in capsys.readouterr().out


def test_main_fails_closed_when_live_rows_are_malformed(monkeypatch, capsys):
    # End-to-end fail-closed: real live_active_codes() raising KeyError inside main()'s try becomes a
    # NOT VERIFIED / return 1, never a vacuous OK.
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C", "D", "E"})
    monkeypatch.setattr(clrp, "bq", lambda sql, project: [{"no_code_here": 1}])
    assert clrp.main() == 1
    assert "NOT VERIFIED" in capsys.readouterr().out


def test_main_both_empty_is_not_verified(monkeypatch, capsys):
    # 2026-07-17 fix: a PRESENT roster with zero probe/adopted codes AND an empty live set is not a real
    # comparison (violates the SISA N>=2 floor) — must fail closed, not report a vacuous OK on ([]).
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: set())
    monkeypatch.setattr(clrp, "live_active_codes", lambda project: set())
    assert clrp.main() == 1
    assert "NOT VERIFIED" in capsys.readouterr().out


def test_main_passes_project_flag_through(monkeypatch):
    captured = {}

    def cap(project):
        captured["project"] = project
        return {"A", "B", "C", "D", "E"}
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C", "D", "E"})
    monkeypatch.setattr(clrp, "live_active_codes", cap)
    monkeypatch.setattr(sys, "argv", ["check_live_roster_parity.py", "--project", "custom-proj-9"])
    assert clrp.main() == 0
    assert captured["project"] == "custom-proj-9"


def test_main_default_project_is_stock_trading(monkeypatch):
    captured = {}

    def cap(project):
        captured["project"] = project
        return {"A", "B", "C", "D", "E"}
    monkeypatch.setattr(clrp, "roster_active_codes", lambda: {"A", "B", "C", "D", "E"})
    monkeypatch.setattr(clrp, "live_active_codes", cap)
    assert clrp.main() == 0
    assert captured["project"] == "stock-trading-498512"


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))

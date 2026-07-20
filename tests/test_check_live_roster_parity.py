"""Offline tests for scripts/check_live_roster_parity.py (no BigQuery, no creds).

This safety-critical CI gate (.github/workflows/live-sql-parity.yml — exit 1 FAILS THE JOB) shipped with
ZERO dedicated tests, unlike its siblings dbt_parity.py (tests/test_dbt_parity.py) and
check_live_sql_parity.py (tests/test_check_live_sql_parity.py). It compares the live
state.active_strategy_codes set against strategy/roster.yaml's roster-active (probe/adopted) set and must
FAIL CLOSED on any live-read failure — a parity gate that reports OK on a swallowed exception or a
zero-vs-zero comparison is worse than no gate. These lock: bq()'s thin delegation to lib/bq_json.py's
run_bq_query with its own fixed max_rows=100000 (the shared subprocess-invoke/JSON-parse/returncode/
timeout contract itself is proven once in tests/test_bq_json.py, C3 dedup 2026-07-20);
roster_active_codes()'s probe/adopted filter (and its docstring-promised parity with
check_roster_consistency.py's R-A definition); live_active_codes()'s extraction; and every main()
branch (SKIP / OK / drift-FAIL / FAIL-CLOSED / both-empty-NOT-VERIFIED).

Added 2026-07-17 (parallel-refactor Part A) alongside the both-empty NOT-VERIFIED guard fix.
"""
import os
import sys

import pytest

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


# ---- bq(): thin delegation to lib/bq_json.run_bq_query -- the shared subprocess-invoke/JSON-parse/
# returncode/timeout contract is proven ONCE on run_bq_query itself (tests/test_bq_json.py); this
# just pins that THIS caller forwards its own fixed max_rows=100000 (C3 dedup, 2026-07-20 audit).
def test_bq_delegates_to_run_bq_query_with_max_rows_100000(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project, max_rows=None):
        captured["sql"], captured["project"], captured["max_rows"] = sql, project, max_rows
        return [{"strategy_code": "A"}]
    monkeypatch.setattr(clrp, "run_bq_query", fake_run_bq_query)
    assert clrp.bq("SELECT 1", "proj") == [{"strategy_code": "A"}]
    assert captured == {"sql": "SELECT 1", "project": "proj", "max_rows": 100000}


# ---- roster_active_codes(): probe/adopted only, case-insensitive, + R-A parity lock ---------------
def test_roster_active_codes_real_repo_meets_n_min_floor():
    # C2 (2026-07-20 audit): NOT an exact-set pin. Strategy roster membership is fully autonomous
    # (SISA, owner directive 2026-07-10) -- SL1-SL5 grow/shrink it with no human review/approval step
    # anywhere in the add/delete path, so an exact {"A","B","C","D","E"} literal would red-line CI on
    # a correct, unattended SL2 adoption or SL5 retirement. Assert only the structural floor the
    # roster itself is policy-bound to (rails.n_min in strategy/roster.yaml) -- the parity test right
    # below plus test_roster_active_codes_filters_and_is_case_insensitive's synthetic fixture already
    # lock the actual filtering/parsing behavior.
    assert len(clrp.roster_active_codes()) >= 2


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

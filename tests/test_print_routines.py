"""Guard scripts/print_routines.py's routine-list reconstruction + --write manifest generation.

print_routines.py reconstructs the canonical routine/trigger list from Claude_Task_Plan.md headings
+ ops/cadence.yaml, and (via --write) emits ops/triggers.json — the committed artifact
scripts/check_cadence_consistency.py's check F asserts is never stale (tests/test_cadence_consistency.py
covers that generator's duplicate copy). This file had NO test coverage at all before now. These tests
run entirely against tmp_path fixtures (never the real Claude_Task_Plan.md / ops/cadence.yaml /
ops/triggers.json), so a --write test can never touch the real committed ops/triggers.json.
"""
import json
import sys

from conftest import load_module_from_path

pr = load_module_from_path("print_routines", "scripts", "print_routines.py")


# ---- heading_to_id: the id-extraction rule (same contract as check_cadence_consistency.py's copy) --
def test_heading_to_id_handles_all_id_shapes():
    assert pr.heading_to_id("D1. Market Development Scan — deep research") == "D1"
    assert pr.heading_to_id("M1a. Strategy-Blind Regime Scoring — deep research") == "M1a"
    assert pr.heading_to_id("Adversarial Review Attacker — regular routine") == "AR_att"
    assert pr.heading_to_id("Adversarial Review Orchestrator — regular routine") == "AR_orc"
    assert pr.heading_to_id("no leading id here") is None


# ---- routine_headings(): only "## " headings ending in the routine-type suffix count -------------
def test_routine_headings_filters_by_suffix(tmp_path, monkeypatch):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "# Preamble\n"
        "Some intro text, not a heading.\n\n"
        "## D1. Market Development Scan — deep research\n"
        "body...\n\n"
        "## Queue schema — not a routine\n"
        "body...\n\n"
        "## D2. Daily Action Conversion — regular routine\n"
        "body...\n"
    )
    monkeypatch.setattr(pr, "PLAN", str(plan))
    assert pr.routine_headings() == [
        "D1. Market Development Scan — deep research",
        "D2. Daily Action Conversion — regular routine",
    ]


# ---- load_cadence(): {id: row} + top-level timezone -----------------------------------------------
def test_load_cadence_reads_timezone_and_routines(tmp_path, monkeypatch):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    schedule: \"after_close trading_day\"\n"
        "    depends_on: []\n"
    )
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    tz, cad = pr.load_cadence()
    assert tz == "America/Denver"
    assert cad == {"D1": {"id": "D1", "monitor_class": "daily_trading",
                          "schedule": "after_close trading_day", "depends_on": []}}


def test_load_cadence_empty_file_is_empty_not_a_crash(tmp_path, monkeypatch):
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("")
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    tz, cad = pr.load_cadence()
    assert tz == "?"
    assert cad == {}


def test_load_cadence_bare_routines_key_is_empty_not_a_crash(tmp_path, monkeypatch):
    # 2026-07-29: `routines:` with nothing under it parses to {"routines": None} (YAML), not a missing
    # key -- `doc.get("routines", [])`'s default only fires when the KEY is absent, so this exact shape
    # crashed load_cadence() with TypeError: 'NoneType' object is not iterable pre-fix (confirmed live
    # against the pre-fix idiom). load_cadence() now routes through lib.routine_manifest.
    # cadence_routines(), which guards the None case.
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("timezone: America/Denver\nroutines:\n")
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    tz, cad = pr.load_cadence()
    assert tz == "America/Denver"
    assert cad == {}


# ---- main(): drift warnings + printout (no --write) ------------------------------------------------
def _write_fixture(tmp_path):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "## D1. Market Development Scan — deep research\n"
        "body...\n\n"
        "## D2. Daily Action Conversion — regular routine\n"
        "body...\n"
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    schedule: \"after_close trading_day\"\n"
        "  - id: D2\n"
        "    monitor_class: daily_trading\n"
        "    schedule: \"after D1 trading_day\"\n"
    )
    return plan, cadence


def test_main_reports_ok_when_headings_and_cadence_match(tmp_path, monkeypatch, capsys):
    plan, cadence = _write_fixture(tmp_path)
    triggers = tmp_path / "triggers.json"
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(sys, "argv", ["print_routines.py"])
    assert pr.main() == 0
    out = capsys.readouterr().out
    assert "OK: every routine heading maps 1:1" in out
    assert not triggers.exists()  # no --write -> ops/triggers.json (tmp copy) untouched


def test_main_warns_on_cadence_id_with_no_heading(tmp_path, monkeypatch, capsys):
    plan, cadence = _write_fixture(tmp_path)
    # Add a cadence routine with no matching Claude_Task_Plan.md heading -> drift warning.
    cadence.write_text(cadence.read_text() + "  - id: ZZ\n    monitor_class: daily_trading\n")
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(tmp_path / "triggers.json"))
    monkeypatch.setattr(sys, "argv", ["print_routines.py"])
    assert pr.main() == 0  # print_routines.py only WARNS; it does not fail the build (unlike check_cadence_consistency.py)
    out = capsys.readouterr().out
    assert "WARNING" in out and "ZZ" in out


def test_main_warns_on_heading_with_no_cadence_id(tmp_path, monkeypatch, capsys):
    # Reverse direction of test_main_warns_on_cadence_id_with_no_heading: a well-formed plan
    # heading id with no matching ops/cadence.yaml routine at all. Previously this left
    # missing_heading empty, "?" not in seen, and dup_ids empty, so the final gate fired and
    # printed a false "OK: every routine heading maps 1:1" (2026-07-18 audit finding).
    plan, cadence = _write_fixture(tmp_path)
    plan.write_text(plan.read_text() + "\n## ZZ. Ghost Routine — deep research\nbody...\n")
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(tmp_path / "triggers.json"))
    monkeypatch.setattr(sys, "argv", ["print_routines.py"])
    assert pr.main() == 0  # print_routines.py only WARNS; it does not fail the build
    out = capsys.readouterr().out
    assert "WARNING" in out and "ZZ" in out
    assert "OK: every routine heading maps 1:1" not in out


def test_main_warns_on_duplicate_heading_same_id(tmp_path, monkeypatch, capsys):
    # Two DIFFERENT headings deriving the SAME id (a copy-pasted heading) used to leave `seen`
    # (a set) looking identical to the clean single-heading case, printing a false "OK: every
    # routine heading maps 1:1" (2026-07-14 audit finding).
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "## D1. Duplicate Heading Same Id — deep research\nbody\n"
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("timezone: America/Denver\nroutines:\n  - id: D1\n    monitor_class: daily_trading\n")
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(tmp_path / "triggers.json"))
    monkeypatch.setattr(sys, "argv", ["print_routines.py"])
    pr.main()
    out = capsys.readouterr().out
    assert "WARNING" in out and "D1" in out
    assert "OK: every routine heading maps 1:1" not in out


# ---- main(--write): the versioned trigger manifest (self-improvement audit WO-2) -------------------
def test_main_write_generates_expected_triggers_manifest(tmp_path, monkeypatch, capsys):
    plan, cadence = _write_fixture(tmp_path)
    triggers = tmp_path / "triggers.json"
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(sys, "argv", ["print_routines.py", "--write"])
    assert pr.main() == 0
    written = json.loads(triggers.read_text())
    assert written == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1 — deep research."},
        "D2": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D2 — regular routine."},
    }
    assert "Wrote" in capsys.readouterr().out


def test_main_write_excludes_ids_not_in_cadence(tmp_path, monkeypatch):
    # A plan heading whose id has no ops/cadence.yaml routine must NOT appear in the written manifest
    # (matches check_cadence_consistency.py's generate_triggers_manifest "if rid in cad" filter).
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "## D1. Market Development Scan — deep research\n"
        "## ZZ. Ghost Routine — deep research\n"
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("timezone: America/Denver\nroutines:\n  - id: D1\n    monitor_class: daily_trading\n")
    triggers = tmp_path / "triggers.json"
    monkeypatch.setattr(pr, "PLAN", str(plan))
    monkeypatch.setattr(pr, "CADENCE", str(cadence))
    monkeypatch.setattr(pr, "TRIGGERS_JSON", str(triggers))
    monkeypatch.setattr(sys, "argv", ["print_routines.py", "--write"])
    pr.main()
    written = json.loads(triggers.read_text())
    assert set(written) == {"D1"}

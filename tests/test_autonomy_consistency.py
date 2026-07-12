"""Guard scripts/check_autonomy_consistency.py's own citation-scraping regex + drift comparison.

Same discipline as tests/test_cadence_consistency.py (which guards check_cadence_consistency.py's
SQL/YAML parsers): a benign reformat of a "<STAGE> per ops/autonomy_levels.yaml, loop `<id>`" citation
must not make the regex silently stop matching (a vacuous pass) — these tests feed known-good and
deliberately-reformatted fixtures and assert the parser + main() behave.

No warehouse, no creds — pure offline fixture tests (run in the always-on `test` job).
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_autonomy_consistency.py")
    spec = importlib.util.spec_from_file_location("check_autonomy_consistency", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


ac = _load()


# ---- load_stages(): {loop id: stage} from ops/autonomy_levels.yaml -------------------------------
def test_load_stages_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "autonomy_levels.yaml"
    f.write_text(
        "loops:\n"
        "  - id: process_reliability\n"
        "    stage: dormant\n"
        "  - id: strategy_playbook\n"
        "    stage: shadow\n"
    )
    monkeypatch.setattr(ac, "AUTONOMY", str(f))
    assert ac.load_stages() == {"process_reliability": "dormant", "strategy_playbook": "shadow"}


# ---- CITATION_RE / find_citations(): the two real citation styles in this repo -------------------
def test_find_citations_matches_prose_style(tmp_path):
    f = tmp_path / "Claude_Task_Plan.md"
    f.write_text(
        "- **REVIEW (2026-07-03 — DORMANT per `ops/autonomy_levels.yaml`, loop "
        "`process_reliability`; read-only).** Read the scorecard.\n"
    )
    assert ac.find_citations(str(f)) == [("DORMANT", "process_reliability")]


def test_find_citations_matches_sql_style(tmp_path):
    f = tmp_path / "27.sql"
    f.write_text(
        "-- STATUS: DORMANT per ops/autonomy_levels.yaml (loop id `process_reliability`). This file\n"
        "-- builds ONLY the measurement view.\n"
    )
    assert ac.find_citations(str(f)) == [("DORMANT", "process_reliability")]


def test_find_citations_empty_on_reformat_is_caught(tmp_path):
    # A restructure that drops the "loop `<id>`" phrasing entirely (e.g. moves the loop id to a
    # separate sentence) must yield [] — main() then flags "expected >=1 ... citation ... found none"
    # for a KNOWN_CITATION_FILES entry, NOT a vacuous pass.
    f = tmp_path / "reformatted.md"
    f.write_text(
        "- DORMANT (see ops/autonomy_levels.yaml). The loop id is process_reliability.\n"
    )
    assert ac.find_citations(str(f)) == []


def test_find_citations_empty_file_is_empty_not_a_crash(tmp_path):
    f = tmp_path / "empty.md"
    f.write_text("Nothing to see here.\n")
    assert ac.find_citations(str(f)) == []


def test_find_citations_missing_file_is_empty(tmp_path):
    assert ac.find_citations(str(tmp_path / "does_not_exist.md")) == []


# ---- main(): end-to-end drift detection -----------------------------------------------------------
def test_main_ok_when_citations_match_stage(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: dormant\n")
    known = tmp_path / "known.md"
    known.write_text("DORMANT per `ops/autonomy_levels.yaml`, loop `process_reliability`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    assert ac.main() == 0


def test_main_fails_when_citation_is_stale(tmp_path, monkeypatch):
    # The loop was promoted (stage now shadow) but this citation was never updated -> DRIFT.
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: shadow\n")
    known = tmp_path / "known.md"
    known.write_text("DORMANT per `ops/autonomy_levels.yaml`, loop `process_reliability`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    assert ac.main() == 1


def test_main_fails_when_known_citation_file_has_no_citation(tmp_path, monkeypatch):
    # A KNOWN_CITATION_FILES entry that suddenly yields zero matches (regex rotted OR citation quietly
    # deleted) must fail loud, not silently pass with "0 citations checked, all fine".
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: dormant\n")
    known = tmp_path / "known.md"
    known.write_text("This file no longer mentions autonomy stages at all.\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    assert ac.main() == 1


def test_main_fails_on_citation_to_unknown_loop_id(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: dormant\n")
    known = tmp_path / "known.md"
    known.write_text("DORMANT per `ops/autonomy_levels.yaml`, loop `renamed_loop_id`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    assert ac.main() == 1


def test_main_against_real_repo_files_is_clean():
    # End-to-end sanity check against the actual committed files (no monkeypatching) — locks in that
    # today's real citations are consistent, so this test starts failing the moment a real drift lands.
    assert ac.main() == 0


# ---- check_stage_ceiling_invariant: a loop's stage may never exceed its own ceiling ----------------
def test_check_stage_ceiling_invariant_flags_stage_above_ceiling():
    loops = [{"id": "foo", "stage": "active_auto", "ceiling": "shadow"}]
    errs = ac.check_stage_ceiling_invariant(loops)
    assert len(errs) == 1
    assert "foo" in errs[0] and "EXCEEDS its ceiling" in errs[0]


def test_check_stage_ceiling_invariant_flags_unknown_vocabulary():
    errs = ac.check_stage_ceiling_invariant([{"id": "foo", "stage": "bogus_stage", "ceiling": "shadow"}])
    assert any("unknown stage" in e for e in errs)
    errs2 = ac.check_stage_ceiling_invariant([{"id": "foo", "stage": "shadow", "ceiling": "bogus_ceiling"}])
    assert any("unknown ceiling" in e for e in errs2)


def test_check_stage_ceiling_invariant_clean_cases_are_silent():
    loops = [
        {"id": "a", "stage": "dormant", "ceiling": "active_auto"},
        {"id": "b", "stage": "active_auto", "ceiling": "active_auto"},
        {"id": "c", "stage": "shadow", "ceiling": None},  # no ceiling declared yet — not itself an error
    ]
    assert ac.check_stage_ceiling_invariant(loops) == []


def test_check_stage_ceiling_invariant_against_real_autonomy_levels_is_clean():
    doc = ac.yaml.safe_load(open(ac.AUTONOMY, encoding="utf-8")) or {}
    assert ac.check_stage_ceiling_invariant(doc.get("loops", [])) == []


# ---- active_auto_loops / cadence_heartbeat_loops / _check_cadence_heartbeat_coverage ----------------
def test_active_auto_loops_filters_by_stage(tmp_path, monkeypatch):
    f = tmp_path / "autonomy_levels.yaml"
    f.write_text(
        "loops:\n"
        "  - id: promoted\n    stage: active_auto\n"
        "  - id: not_promoted\n    stage: shadow\n"
    )
    monkeypatch.setattr(ac, "AUTONOMY", str(f))
    assert ac.active_auto_loops() == {"promoted"}


def test_cadence_heartbeat_loops_parses_loop_literals(tmp_path, monkeypatch):
    f = tmp_path / "cadence_check.sql"
    f.write_text("SELECT 1 FROM UNNEST(['loop:process_reliability','loop:strategy_playbook']) AS loop_source")
    monkeypatch.setattr(ac, "CADENCE_SQL", str(f))
    assert ac.cadence_heartbeat_loops() == {"process_reliability", "strategy_playbook"}


def test_cadence_heartbeat_loops_returns_none_when_file_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "does_not_exist.sql"))
    assert ac.cadence_heartbeat_loops() is None


def test_cadence_heartbeat_coverage_flags_unmonitored_active_auto_loop(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: unmonitored_loop\n    stage: active_auto\n")
    cadence_sql = tmp_path / "cadence_check.sql"
    cadence_sql.write_text("SELECT 1 FROM UNNEST(['loop:some_other_loop']) AS loop_source")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "CADENCE_SQL", str(cadence_sql))
    monkeypatch.setattr(ac, "HEARTBEAT_SELF_MONITORED_LOOPS", set())
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert len(errors) == 1
    assert "unmonitored_loop" in errors[0]


def test_cadence_heartbeat_coverage_respects_self_monitored_exemption(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: self_monitored\n    stage: active_auto\n")
    cadence_sql = tmp_path / "cadence_check.sql"
    cadence_sql.write_text("SELECT 1")  # no 'loop:<id>' literals at all
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "CADENCE_SQL", str(cadence_sql))
    monkeypatch.setattr(ac, "HEARTBEAT_SELF_MONITORED_LOOPS", {"self_monitored"})
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert errors == []


def test_cadence_heartbeat_coverage_no_op_when_sql_file_missing(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: some_loop\n    stage: active_auto\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "does_not_exist.sql"))
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert errors == []


def test_cadence_heartbeat_coverage_against_real_repo_files_is_clean():
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert errors == []

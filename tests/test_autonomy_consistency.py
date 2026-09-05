"""Guard scripts/check_autonomy_consistency.py's own citation-scraping regex + drift comparison.

Same discipline as tests/test_cadence_consistency.py (which guards check_cadence_consistency.py's
SQL/YAML parsers): a benign reformat of a "<STAGE> per ops/autonomy_levels.yaml, loop `<id>`" citation
must not make the regex silently stop matching (a vacuous pass) — these tests feed known-good and
deliberately-reformatted fixtures and assert the parser + main() behave.

No warehouse, no creds — pure offline fixture tests (run in the always-on `test` job).
"""
import os

from conftest import load_module_from_path

ac = load_module_from_path("check_autonomy_consistency", "scripts", "check_autonomy_consistency.py")


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


# ---- CITATION_RE / find_citations(): the three real citation styles in this repo ------------------
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


def test_find_citations_matches_reversed_order_sql_style(tmp_path):
    # roster-group bug, 2026-09-04: the third real style writes the LOOP ID first and the stage second,
    # which CITATION_RE structurally cannot match (its tail requires the id AFTER the filename). This is
    # bigquery/129_cadence_watch_deadline_autotune.sql's exact WHY-header shape — the one citation in the
    # scanned corpus that went unvalidated (9 mentions of "per ops/autonomy_levels.yaml", 8 matched).
    f = tmp_path / "129.sql"
    f.write_text(
        "-- WHY (W5 2026-08-03, self-improvement loop `process_reliability`, active_auto per "
        "ops/autonomy_levels.yaml): autotune the cadence-watch deadline.\n"
    )
    assert ac.find_citations(str(f)) == [("active_auto", "process_reliability")]


def test_find_citations_reversed_order_stage_is_case_insensitive(tmp_path):
    # The stage half is matched case-insensitively on purpose: every FORWARD citation in the repo spells
    # the stage UPPERCASE, bigquery/129 spells it lowercase. A lowercase-only reversed pattern would
    # close exactly today's instance and leave the uppercase spelling invisible — a half-closed hole.
    # The loop-id class stays lowercase (ids are lowercase by convention in ops/autonomy_levels.yaml).
    f = tmp_path / "future.sql"
    f.write_text("-- loop `process_reliability`, ACTIVE_AUTO per ops/autonomy_levels.yaml\n")
    assert ac.find_citations(str(f)) == [("ACTIVE_AUTO", "process_reliability")]


def test_find_citations_reversed_order_does_not_match_ordinary_prose(tmp_path):
    # The reversed pattern reads right-to-left, so its stage capture is NOT anchored by what follows it
    # (unlike CITATION_RE's). It is therefore restricted to the STAGE_ORDER vocabulary: an ordinary
    # sentence word sitting before "per ops/autonomy_levels.yaml" must NOT be captured and reported as
    # DRIFT. A [A-Za-z_]+ stage class here would match "documented" below.
    f = tmp_path / "prose.md"
    f.write_text("The loop `process_reliability` is documented per `ops/autonomy_levels.yaml`.\n")
    assert ac.find_citations(str(f)) == []


def test_stale_reversed_order_citation_is_caught(tmp_path, monkeypatch):
    # End-to-end: a reversed-order citation that has gone stale must FAIL, not merely be counted. Before
    # 2026-09-04 this file produced zero matches and the drift was invisible.
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: active_auto\n")
    bq = tmp_path / "bigquery"
    bq.mkdir()
    (bq / "129.sql").write_text(
        "-- WHY (loop `process_reliability`, dormant per ops/autonomy_levels.yaml): stale citation\n")
    known = tmp_path / "known.md"
    known.write_text("active_auto per `ops/autonomy_levels.yaml`, loop `process_reliability`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [str(bq / "*.sql")])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "no_cadence.sql"))
    assert ac.main() == 1


def test_find_citations_matches_digit_bearing_loop_id(tmp_path):
    # #4 (2026-07-17 audit): the loop-id class includes digits, so a citation to a loop id containing
    # a digit (plausible given the D1/SL1-SL5/W5 routine namespace) is matched, not silently skipped
    # (which would be a vacuous pass — a stale citation to such a loop never flagged).
    f = tmp_path / "Claude_Task_Plan.md"
    f.write_text(
        "- **DORMANT per `ops/autonomy_levels.yaml`, loop `sl2_probe`.** Read the scorecard.\n"
    )
    assert ac.find_citations(str(f)) == [("DORMANT", "sl2_probe")]


def test_cadence_heartbeat_loops_matches_digit_bearing_loop_id(tmp_path, monkeypatch):
    # Twin parser: the cadence-heartbeat 'loop:<id>' extraction must also accept a digit-bearing id,
    # or _check_cadence_heartbeat_coverage would false-positive a missing dead-man's switch for it.
    f = tmp_path / "cadence_check.sql"
    f.write_text("WHEN literal IN ('loop:sl2_probe','loop:process_reliability') THEN 1\n")
    monkeypatch.setattr(ac, "CADENCE_SQL", str(f))
    assert ac.cadence_heartbeat_loops() == {"sl2_probe", "process_reliability"}


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


# ---- duplicate_loop_ids: a copy-pasted `- id:` block is valid YAML and loads without error -----------
def test_duplicate_loop_ids_flags_repeated_id():
    loops = [
        {"id": "foo", "stage": "dormant"},
        {"id": "bar", "stage": "shadow"},
        {"id": "foo", "stage": "active_auto"},
    ]
    assert ac.duplicate_loop_ids(loops) == ["foo"]


def test_duplicate_loop_ids_clean_case_is_silent():
    loops = [{"id": "foo", "stage": "dormant"}, {"id": "bar", "stage": "shadow"}]
    assert ac.duplicate_loop_ids(loops) == []


def test_duplicate_loop_ids_against_real_autonomy_levels_is_clean():
    doc = ac.yaml.safe_load(open(ac.AUTONOMY, encoding="utf-8")) or {}
    assert ac.duplicate_loop_ids(doc.get("loops", [])) == []


def test_main_fails_on_duplicate_loop_id(tmp_path, monkeypatch, capsys):
    # Two `- id: dup` entries -- load_stages()'s dict comprehension would otherwise silently keep only
    # the second entry's stage with zero signal.
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text(
        "loops:\n"
        "  - id: dup\n    stage: dormant\n"
        "  - id: dup\n    stage: active_auto\n"
    )
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "no_cadence.sql"))  # heartbeat check no-ops
    assert ac.main() == 1
    out = capsys.readouterr().out
    assert "ops/autonomy_levels.yaml: loop 'dup' id is duplicated in the loops list" in out


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


# =====================================================================================================
# 2026-07-17 parallel-refactor coverage additions (adversarial-audit findings).
# =====================================================================================================

# ---- main() integration: the register-self-consistency + heartbeat checks were only tested in
#      isolation; nothing asserted main() RETURNS 1 when they fire (2026-07-17 audit) ----
def test_main_fails_on_stage_above_ceiling(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: over\n    stage: active_auto\n    ceiling: shadow\n")
    known = tmp_path / "known.md"                          # cite the true stage so only the ceiling fails
    known.write_text("active_auto per `ops/autonomy_levels.yaml`, loop `over`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "no_cadence.sql"))  # heartbeat check no-ops
    assert ac.main() == 1


def test_main_fails_on_unmonitored_active_auto_loop(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: promoted\n    stage: active_auto\n    ceiling: active_auto\n")
    known = tmp_path / "known.md"
    known.write_text("active_auto per `ops/autonomy_levels.yaml`, loop `promoted`\n")
    cadence = tmp_path / "cadence_check.sql"
    cadence.write_text("SELECT 1 FROM UNNEST(['loop:some_other_loop']) AS loop_source\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(cadence))
    monkeypatch.setattr(ac, "HEARTBEAT_SELF_MONITORED_LOOPS", set())
    assert ac.main() == 1


# ---- the dedicated fail-loud 'no loop: literals found' rot branch (SQL present but empty) ----
def test_cadence_heartbeat_coverage_flags_rotted_empty_list(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: promoted\n    stage: active_auto\n")
    cadence = tmp_path / "cadence_check.sql"
    cadence.write_text("SELECT 1\n")                       # content, but zero 'loop:<id>' literals
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "CADENCE_SQL", str(cadence))
    monkeypatch.setattr(ac, "HEARTBEAT_SELF_MONITORED_LOOPS", set())
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert len(errors) == 1
    assert "found no" in errors[0] and "does NOT monitor" not in errors[0]


# ---- 2026-07-17 fix: coverage requires DETECTION-list membership, not mere union — a loop present only
#      in the message-text UNNEST literal (not the IF EXISTS detection literal that fires the alarm) has
#      no working dead-man's switch and must still be flagged ----
def test_cadence_heartbeat_coverage_flags_detection_only_divergence(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text(
        "loops:\n"
        "  - id: covered\n    stage: active_auto\n"
        "  - id: msgonly\n    stage: active_auto\n"
    )
    cadence = tmp_path / "cadence_check.sql"
    cadence.write_text(
        "IF EXISTS (SELECT 1 FROM UNNEST(['loop:covered']) AS s) THEN SELECT 1; END IF;\n"
        "SELECT STRING_AGG(x) FROM UNNEST(['loop:covered','loop:msgonly']) AS s;\n"
    )
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "CADENCE_SQL", str(cadence))
    monkeypatch.setattr(ac, "HEARTBEAT_SELF_MONITORED_LOOPS", set())
    # union (cadence_heartbeat_loops) contains msgonly; intersection (cadence_detection_loops) does not.
    assert ac.cadence_heartbeat_loops() == {"covered", "msgonly"}
    assert ac.cadence_detection_loops() == {"covered"}
    errors = []
    ac._check_cadence_heartbeat_coverage(errors)
    assert len(errors) == 1 and "msgonly" in errors[0]


# ---- 2026-07-17 fix: a loop that declares a ceiling but has no 'stage' (the register's core field) is
#      flagged; a stage-present/ceiling-absent loop is NOT (that is a valid not-yet-capped entry) ----
def test_check_stage_ceiling_invariant_flags_stageless_loop_with_ceiling():
    errs = ac.check_stage_ceiling_invariant([{"id": "x", "ceiling": "active_auto"}])
    assert len(errs) == 1 and "x" in errs[0] and "no 'stage'" in errs[0]
    # stage present, ceiling absent stays silent (the existing clean-cases test relies on this too).
    assert ac.check_stage_ceiling_invariant([{"id": "y", "stage": "shadow", "ceiling": None}]) == []


def test_main_fails_on_citation_to_stageless_loop(tmp_path, monkeypatch):
    # _check_citations distinguishes a KNOWN loop whose stage is None from an unknown loop id.
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: p\n")             # id present, no stage key -> stage None
    known = tmp_path / "known.md"
    known.write_text("dormant per `ops/autonomy_levels.yaml`, loop `p`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "no_cadence.sql"))
    assert ac.main() == 1


def test_cadence_detection_loops_returns_none_when_file_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "does_not_exist.sql"))
    assert ac.cadence_detection_loops() is None


def test_cadence_detection_loops_matches_real_repo_detection_list():
    # The real canonical ops.sp_sq_cadence_check body carries identical detection + message lists today,
    # so intersection == union. (Comment corrected 2026-09-04: this used to say "the real bigquery/75",
    # which stopped being the canonical definition once bigquery/111 superseded it — the resolved winner
    # is now bigquery/205. Measured: all 15 definitions yield the same 7-loop set, so the assertion is
    # unchanged either way, but the file it is actually reading is not the one this comment named.)
    assert ac.cadence_detection_loops() == ac.cadence_heartbeat_loops()


# ---- canonical_cadence_sql(): the dead-man's-switch gate must read the APPLY-IN-ORDER winning
#      definition of ops.sp_sq_cadence_check, not the bigquery/75 it was hard-pinned to in 2026-07-16.
#      15 files define that procedure now; validating a body 14 supersessions stale can fail OPEN (a
#      loop dropped from the detection literal in a later file goes unseen) or false-FAIL (a newly
#      promoted loop's literal lands in a NEW superseding file per bigquery/111's header rule).
#      (roster-group bug, 2026-09-04 — the sibling check_sq_version_registry.py already resolved the
#      winner for this same procedure family; this checker had never been given the same treatment.) ----
_PROC_DDL_FIXTURE = (
    "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()\n"
    "BEGIN\n"
    "  IF EXISTS (SELECT 1 FROM UNNEST([{literals}]) AS s) THEN SELECT 1; END IF;\n"
    "END;\n"
)


def _write_cadence_def(directory, filename, loops):
    literals = ",".join(f"'loop:{lid}'" for lid in loops)
    (directory / filename).write_text(_PROC_DDL_FIXTURE.format(literals=literals))


def test_canonical_cadence_sql_resolves_the_highest_numbered_definition(tmp_path, monkeypatch):
    _write_cadence_def(tmp_path, "75_wrappers.sql", ["old_loop"])
    _write_cadence_def(tmp_path, "205_supersession.sql", ["new_loop"])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "75_wrappers.sql"))
    path, errors = ac.canonical_cadence_sql()
    assert errors == []
    assert os.path.basename(path) == "205_supersession.sql"
    # And the loop readers follow it: the STALE pin's literal must NOT be what the gate compares against.
    assert ac.cadence_heartbeat_loops() == {"new_loop"}
    assert ac.cadence_detection_loops() == {"new_loop"}


def test_canonical_cadence_sql_ignores_lexical_order_across_digit_widths(tmp_path, monkeypatch):
    # numbered_sql_files() sorts by the parsed integer, not lexically — `sorted(os.listdir())` would put
    # "111_" before "75_" and pick the WRONG (older) body. See scripts/lib/sql_files.py's own header.
    _write_cadence_def(tmp_path, "75_wrappers.sql", ["old_loop"])
    _write_cadence_def(tmp_path, "111_supersession.sql", ["new_loop"])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "75_wrappers.sql"))
    assert os.path.basename(ac.canonical_cadence_sql()[0]) == "111_supersession.sql"


def test_canonical_cadence_sql_falls_back_to_the_pin_when_nothing_is_numbered(tmp_path, monkeypatch):
    # The fallback is what keeps every CADENCE_SQL monkeypatch in this file working: a tmp fixture file
    # carries no `NN_` prefix, so numbered_sql_files() finds no definition and the pinned path is used.
    f = tmp_path / "cadence_check.sql"
    f.write_text("SELECT 1 FROM UNNEST(['loop:patched']) AS s\n")
    monkeypatch.setattr(ac, "CADENCE_SQL", str(f))
    assert ac.canonical_cadence_sql() == (str(f), [])
    assert ac.cadence_heartbeat_loops() == {"patched"}


def test_canonical_cadence_sql_reports_a_duplicate_number_collision(tmp_path, monkeypatch):
    # resolve_canonical()'s contract: two DIFFERENT files can share a leading number (114 x2 and 185 x2
    # exist in bigquery/ today), so a caller must never index [0] on the tied set. Here both tied files
    # define the procedure, so the winner is genuinely ambiguous -> (None, [error]), and the gate FAILS
    # rather than silently validating whichever file happened to sort first.
    _write_cadence_def(tmp_path, "205_alpha.sql", ["loop_a"])
    _write_cadence_def(tmp_path, "205_beta.sql", ["loop_b"])
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "205_alpha.sql"))
    path, errors = ac.canonical_cadence_sql()
    assert path is None
    assert len(errors) == 1 and "AMBIGUOUS" in errors[0]
    assert "205_alpha.sql" in errors[0] and "205_beta.sql" in errors[0]
    assert ac.cadence_heartbeat_loops() is None          # unresolvable -> nothing to compare
    collected = []
    ac._check_cadence_heartbeat_coverage(collected)
    assert len(collected) == 1 and "AMBIGUOUS" in collected[0]


def test_canonical_cadence_sql_ignores_a_commented_out_definition(tmp_path, monkeypatch):
    # A `-- CREATE OR REPLACE PROCEDURE ...` line inside a doc comment is not a definition (the exact
    # class lib/sql_files.py's strip_sql_comments() exists for, confirmed live at bigquery/02:23 for a
    # sibling checker). A superseded-marker comment quoting the DDL must not hijack the resolution.
    _write_cadence_def(tmp_path, "75_wrappers.sql", ["real_loop"])
    (tmp_path / "205_note.sql").write_text(
        "-- SUPERSEDED NOTE: this file's predecessor ran\n"
        "--   CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()\n"
        "-- with UNNEST(['loop:retired_loop']) in its detection list.\n"
        "SELECT 1;\n")
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "75_wrappers.sql"))
    assert os.path.basename(ac.canonical_cadence_sql()[0]) == "75_wrappers.sql"
    assert ac.cadence_heartbeat_loops() == {"real_loop"}


def test_canonical_cadence_sql_on_the_real_repo_is_past_the_stale_pin():
    # Regression lock on the finding itself: the resolved file must be the highest-numbered real
    # definition, and must NOT be the bigquery/75 this gate was pinned to for ~7 weeks of supersessions.
    path, errors = ac.canonical_cadence_sql()
    assert errors == []
    assert os.path.basename(path) != "75_scheduled_query_wrappers.sql"
    # MONOTONE FLOOR, not an identity pin (review correction 2026-09-04). This line used to be
    # `startswith("205_")`, which pins the identity of TODAY's canonical definer -- a value that
    # changes roughly every 3 days as ordinary correct work (14 supersessions in the 46 days to
    # 2026-08-31; bigquery/111's standing header rule makes a NEW superseding file the normal
    # landing path for a promoted loop's heartbeat literal). canonical_cadence_sql() re-derives the
    # winner by scanning bigquery/ at call time, so no human ever has to re-point anything -- the
    # pin bought no coverage (the highest-numbered-wins property is pinned non-vacuously on tmp
    # fixtures by test_canonical_cadence_sql_resolves_the_highest_numbered_definition and
    # ...ignores_lexical_order_across_digit_widths) and would have red-lined ci.yml's blocking
    # pytest step on an unattended routine's branch with nothing actually wrong. Leading numbers
    # only ever grow, so a floor cannot expire the way `startswith` does.
    num = int(os.path.basename(path).split("_", 1)[0])
    assert num >= 205, (
        f"canonical sp_sq_cadence_check resolved to bigquery/{os.path.basename(path)} (number {num}), "
        f"lower than the 205 that was canonical on 2026-09-04 -- resolution has gone backwards; "
        f"check canonical_cadence_sql()'s numbered_sql_files scan.")


# ---- 2026-07-17 (owner direction): EXTRA_SCAN_GLOBS now covers bigquery/*.md, so a stage citation in
#      bigquery/README.md is checked. A live-stale DORMANT citation there (for a now-active_auto loop)
#      previously went entirely unscanned — a vacuous pass in a drift guard. ----
def test_extra_scan_globs_includes_bigquery_md():
    assert any(g.endswith(os.path.join("bigquery", "*.md")) for g in ac.EXTRA_SCAN_GLOBS)


def test_stale_citation_in_a_bigquery_md_file_is_caught(tmp_path, monkeypatch):
    autonomy = tmp_path / "autonomy_levels.yaml"
    autonomy.write_text("loops:\n  - id: process_reliability\n    stage: active_auto\n")
    bq = tmp_path / "bigquery"
    bq.mkdir()
    (bq / "README.md").write_text(
        "STATUS: DORMANT per `ops/autonomy_levels.yaml` (loop id `process_reliability`)\n")
    known = tmp_path / "known.md"
    known.write_text("active_auto per `ops/autonomy_levels.yaml`, loop `process_reliability`\n")
    monkeypatch.setattr(ac, "AUTONOMY", str(autonomy))
    monkeypatch.setattr(ac, "KNOWN_CITATION_FILES", [str(known)])
    monkeypatch.setattr(ac, "EXTRA_SCAN_GLOBS", [str(bq / "*.md")])   # the class the real glob now covers
    monkeypatch.setattr(ac, "CADENCE_SQL", str(tmp_path / "no_cadence.sql"))
    assert ac.main() == 1                                            # the DORMANT bigquery/*.md drift fails

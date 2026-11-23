"""Guard scripts/gen_routine_lists.py's 9th generated region -- bigquery/280's
state.routine_canonical_full_instruction rows (the FULL canonical trigger instruction per fleet
routine, from ops/routine_backup.json) -- and the full-text evidence classifier bigquery/280's
state.instruction_drift applies (2026-11-23).

Why it matters: state.instruction_drift used to compare only the first line of each trigger, so owner
commit 6c01e91's SEARCH GUARD edit sat un-rolled-out on all 33 live triggers for a week while the
nightly check read "0 drifted". The full-text half only works if (a) the generated canonical tracks
routine_backup.json -- `gen_routine_lists.py --check` must FAIL when it does not -- and (b) the
placeholder pattern that separates complete transcriptions from summaries stays identical in the
generator and in the SQL.

Every --write test runs against tmp_path fixtures; the real-repo tests only READ.
"""
import json
import os
import re
import sys

import pytest

from conftest import load_module_from_path

gr = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_280 = os.path.join(REPO, "bigquery", "280_instruction_drift_full_text.sql")

CORE = "Read Claude_Task_Plan.md. Perform D1 — deep research."
FULL = (CORE + "\n\nSpawn Sonnet sub-agents.\n\nSEARCH GUARD. This routine's name is D1 — deep research. "
        "Send one email with subject [Routine paused] Parallel Search unavailable.")


# ---- real repo: the committed region is current and complete ------------------------------------
def test_real_repo_280_is_a_build_target_and_current():
    targets = dict(gr.build_targets())
    assert gr.FULL_INSTRUCTION_SQL in targets, "bigquery/280 is not validated by --check"
    assert gr.current_region(gr.FULL_INSTRUCTION_SQL) == gr.wanted_region(targets[gr.FULL_INSTRUCTION_SQL])


def test_real_repo_280_carries_every_fleet_routine_verbatim_and_no_personal_trigger():
    with open(os.path.join(REPO, "ops", "trigger_ids.json"), encoding="utf-8") as f:
        fleet = [k for k in json.load(f) if k != "_meta"]
    with open(os.path.join(REPO, "ops", "routine_backup.json"), encoding="utf-8") as f:
        backup = json.load(f)["routines"]
    parsed = gr.parse_full_since(SQL_280)
    assert list(parsed) == fleet
    assert not any(k.startswith("personal_") for k in parsed)
    for rid, (instr, since, sup) in parsed.items():
        assert instr == backup[rid]["instruction"], rid
        assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", since)
        assert sup is None or (sup != instr and "SEARCH GUARD" in sup), rid


def test_placeholder_pattern_is_identical_in_generator_and_sql():
    # The view's REGEXP_CONTAINS literal must be the generator's PLACEHOLDER_PATTERN byte-for-byte, or the
    # generator's "no canonical text looks like a placeholder" guarantee says nothing about the SQL.
    with open(SQL_280, encoding="utf-8") as f:
        sql = f.read()
    assert "REGEXP_CONTAINS(live_instruction, r'" + gr.PLACEHOLDER_PATTERN + "')" in sql


# ---- the evidence classifier's placeholder half, on the measured shapes --------------------------
@pytest.mark.parametrize("sample", [
    "... and move on. SEARCH GUARD. [...Parallel search guard paragraph per trigger...]",
    "... and move on. SEARCH GUARD. [Parallel Search guard paragraph per stored trigger]",
    "This routine's name is D2 — regular routine. [Parallel Search guard paragraph]",
    "SEARCH GUARD. [...]",
    "SEARCH GUARD. […]",
    "[remaining paragraphs omitted]",
    "[text truncated]",
])
def test_placeholder_pattern_matches_measured_summaries(sample):
    assert gr.PLACEHOLDER_RE.search(sample)


def test_placeholder_pattern_does_not_match_any_real_canonical():
    for rid, instr in gr.load_full_instructions():
        assert "[Routine paused]" in instr          # the canonical's own bracket -- must NOT trip it
        assert not gr.PLACEHOLDER_RE.search(instr), rid


# ---- gen_280_region: since-date preservation (same contract as gen_15_region) -------------------
def test_gen_280_region_preserves_since_when_text_unchanged():
    got = gr.gen_280_region([("D1", FULL)], prior={"D1": (FULL, "2026-11-23", None)}, today="2026-12-01")
    assert "DATE '2026-11-23' AS canonical_full_since" in got


def test_gen_280_region_restamps_since_when_text_changes():
    got = gr.gen_280_region([("D1", FULL + " One more sentence.")],
                            prior={"D1": (FULL, "2026-11-23", None)}, today="2026-12-01")
    assert "DATE '2026-12-01' AS canonical_full_since" in got


def test_gen_280_region_seeds_since_for_a_new_routine():
    got = gr.gen_280_region([("D1", FULL), ("W9", FULL)], prior={"D1": (FULL, "2026-11-23", None)},
                            today="2026-12-01")
    lines = got.splitlines()
    assert "DATE '2026-11-23'" in got and "STRUCT('W9' AS routine" in got
    assert got.rstrip().endswith("DATE '2026-12-01' AS canonical_full_since, "
                                 "CAST(NULL AS STRING) AS superseded_full_instruction)")
    assert not got.rstrip().endswith(",")
    assert lines[0].startswith("  STRUCT('D1' AS routine, r'''")


def test_gen_280_region_round_trips_through_parse_full_since(tmp_path):
    body = gr.gen_280_region([("D1", FULL), ("OPS0", FULL.replace("D1", "OPS0"))],
                             prior={}, today="2026-11-23")
    p = tmp_path / "280.sql"
    p.write_text("SELECT * FROM UNNEST([\n" + gr.BEGIN_MARKER + gr.wanted_region(body)
                 + gr.END_MARKER + "\n]);\n", encoding="utf-8")
    assert gr.parse_full_since(str(p)) == {
        "D1": (FULL, "2026-11-23", None), "OPS0": (FULL.replace("D1", "OPS0"), "2026-11-23", None)}


def test_parse_full_since_missing_file_is_empty(tmp_path):
    assert gr.parse_full_since(str(tmp_path / "nope.sql")) == {}


@pytest.mark.parametrize("bad", [
    FULL + " a '''quoted''' bit",
    FULL + " ends in a quote'",
    FULL + " back\\slash",
    FULL + " carriage\r\nreturn",
    FULL + " [rest of guard paragraph]",
])
def test_gen_280_region_refuses_text_it_cannot_emit_or_that_looks_like_a_placeholder(bad):
    with pytest.raises(SystemExit):
        gr.gen_280_region([("D1", bad)], prior={}, today="2026-11-23")


# ---- load_full_instructions: fleet = trigger_ids.json minus _meta / personal_* ------------------
def _write_json(tmp_path, ids, routines):
    ids_p = tmp_path / "trigger_ids.json"
    ids_p.write_text(json.dumps(ids), encoding="utf-8")
    bk_p = tmp_path / "routine_backup.json"
    bk_p.write_text(json.dumps({"_meta": {}, "routines": routines}), encoding="utf-8")
    return str(bk_p), str(ids_p)


def test_load_full_instructions_order_and_exclusions(tmp_path):
    bk, ids = _write_json(
        tmp_path,
        {"_meta": {}, "W1": "trig_w1", "D1": "trig_d1", "personal_x": "trig_p"},
        {"D1": {"instruction": "d1"}, "W1": {"instruction": "w1"}, "personal_x": {"instruction": "p"}})
    assert gr.load_full_instructions(bk, ids) == [("W1", "w1"), ("D1", "d1")]


def test_load_full_instructions_refuses_a_fleet_routine_with_no_instruction(tmp_path):
    bk, ids = _write_json(tmp_path, {"_meta": {}, "D1": "t"}, {"D1": {"instruction": "  "}})
    with pytest.raises(SystemExit):
        gr.load_full_instructions(bk, ids)


# ---- main(): --check FAILS when routine_backup.json moves without a --write -----------------------
def _wire_full_fixture(tmp_path, monkeypatch):
    """All nine targets redirected into tmp_path (so the 280 PAIRED-PATH GUARD keeps the target), with a
    one-routine roster. Mirrors tests/test_gen_routine_lists.py::_wire_fixture."""
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text("## D1. Market Development Scan — deep research\nbody\n", encoding="utf-8")
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text("timezone: America/Denver\nroutines:\n  - id: D1\n    monitor_class: daily_trading\n",
                       encoding="utf-8")
    region = ("CREATE OR REPLACE VIEW `x.y.z` AS\nSELECT * FROM UNNEST([\n" + gr.BEGIN_MARKER
              + "\nSTALE\n  " + gr.END_MARKER + "\n]);\n")
    names = {"CADENCE_MONITOR_SQL": "12", "ROUTINE_CATALOG_SQL": "15", "PERIOD_WATCH_SQL": "24",
             "ROUTINE_CATCHUP_SQL": "105", "DEP_GATE_SQL": "114", "QUEUE_SILENCE_SQL": "132",
             "ALERT_MSG_STABILITY_SQL": "205", "QUEUE_DRIVEN_MISSED_FIRE_SQL": "241",
             "FULL_INSTRUCTION_SQL": "280"}
    for attr, num in names.items():
        f = tmp_path / f"{num}.sql"
        f.write_text(region, encoding="utf-8")
        monkeypatch.setattr(gr, attr, str(f))
    bk, ids = _write_json(tmp_path, {"_meta": {}, "D1": "trig_d1"}, {"D1": {"instruction": FULL}})
    monkeypatch.setattr(gr, "PLAN", str(plan))
    monkeypatch.setattr(gr, "CADENCE", str(cadence))
    monkeypatch.setattr(gr, "ROUTINE_BACKUP_JSON", bk)
    monkeypatch.setattr(gr, "TRIGGER_IDS_JSON", ids)
    return tmp_path / "280.sql", bk


def test_main_check_fails_after_backup_instruction_mutated_then_write_restamps(tmp_path, monkeypatch, capsys):
    f280, bk = _wire_full_fixture(tmp_path, monkeypatch)
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 0
    first_since = gr.parse_full_since(str(f280))["D1"][1]
    # Backdate the stored date so a restamp is observable whatever day the test runs.
    f280.write_text(f280.read_text(encoding="utf-8").replace(first_since, "2026-01-01"), encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 0, "unchanged text must PRESERVE the stored date, not restamp it"
    assert gr.parse_full_since(str(f280))["D1"][1] == "2026-01-01"

    # The incident shape: a sentence added to the SEARCH GUARD in routine_backup.json only.
    with open(bk, encoding="utf-8") as f:
        doc = json.load(f)
    doc["routines"]["D1"]["instruction"] = FULL + " A Bash curl fetch is not a web tool."
    with open(bk, "w", encoding="utf-8") as f:
        json.dump(doc, f)
    capsys.readouterr()
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 1
    assert "280.sql" in capsys.readouterr().out

    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    instr, since, sup = gr.parse_full_since(str(f280))["D1"]
    assert instr.endswith("A Bash curl fetch is not a web tool.")
    assert since != "2026-01-01", "a changed text must re-stamp canonical_full_since"
    assert sup == FULL, "the replaced canonical must be kept as superseded_full_instruction"
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 0


def test_build_targets_skips_280_when_only_the_catalog_is_redirected(tmp_path, monkeypatch):
    """PAIRED-PATH GUARD: a fixture that moves bigquery/15 into tmp_path but leaves FULL_INSTRUCTION_SQL
    on the real file must DROP the 280 target, never let a --write reach the real bigquery/280."""
    _wire_full_fixture(tmp_path, monkeypatch)
    monkeypatch.setattr(gr, "FULL_INSTRUCTION_SQL", SQL_280)
    names = [os.path.basename(p) for p, _ in gr.build_targets()]
    assert "280_instruction_drift_full_text.sql" not in names and len(names) == 8


# ---- adversarial-review additions (2026-11-23) ---------------------------------------------------
def test_real_repo_280_superseded_seed_is_pre_6c01e91_text():
    # Every fleet routine's superseded text is its current text minus 6c01e91's one sentence.
    sentence = " A Bash curl fetch of a key-less endpoint that the plan pins is not a web tool and stays allowed."
    for rid, (instr, _since, sup) in gr.parse_full_since(SQL_280).items():
        assert sup == instr.replace(sentence, ""), rid


def test_gen_280_region_keeps_superseded_while_unchanged_and_rolls_it_on_change():
    v1, v2, v3 = FULL, FULL + " Two.", FULL + " Two. Three."
    got = gr.gen_280_region([("D1", v2)], prior={"D1": (v2, "2026-11-23", v1)}, today="2026-12-01")
    assert got.endswith("DATE '2026-11-23' AS canonical_full_since, r\'\'\'" + v1
                        + "\'\'\' AS superseded_full_instruction)")
    got = gr.gen_280_region([("D1", v3)], prior={"D1": (v2, "2026-11-23", v1)}, today="2026-12-01")
    assert "DATE '2026-12-01'" in got and got.endswith("r\'\'\'" + v2 + "\'\'\' AS superseded_full_instruction)")


def test_gen_280_region_new_routine_has_null_superseded_and_round_trips(tmp_path):
    body = gr.gen_280_region([("D1", FULL)], prior={}, today="2026-11-23")
    assert body.endswith("CAST(NULL AS STRING) AS superseded_full_instruction)")
    p = tmp_path / "280.sql"
    p.write_text(gr.BEGIN_MARKER + gr.wanted_region(body) + gr.END_MARKER, encoding="utf-8")
    assert gr.parse_full_since(str(p)) == {"D1": (FULL, "2026-11-23", None)}


def test_gen_280_region_since_floor_raises_never_lowers():
    prior = {"D1": (FULL, "2026-11-23", None), "D2": (FULL, "2026-12-09", None)}
    got = gr.gen_280_region([("D1", FULL), ("D2", FULL)], prior=prior, today="2026-12-10",
                            since_floor="2026-12-05")
    _, d1, d2 = got.split("STRUCT(")
    assert "DATE '2026-12-05'" in d1 and "DATE '2026-12-09'" in d2


def test_gen_280_region_refuses_an_unemittable_superseded_text():
    with pytest.raises(SystemExit):
        gr.gen_280_region([("D1", FULL)], prior={"D1": (FULL + " back\\slash", "2026-11-23", None)},
                          today="2026-12-01")


def test_main_bad_instruction_fails_only_280_and_still_checks_the_rest(tmp_path, monkeypatch, capsys):
    f280, bk = _wire_full_fixture(tmp_path, monkeypatch)
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    out = capsys.readouterr().out
    assert "bigquery/280 landing, in order" in out and "gen_dbt_port.py" in out
    with open(bk, encoding="utf-8") as f:
        doc = json.load(f)
    doc["routines"]["D1"]["instruction"] = FULL + " back\\slash"
    with open(bk, "w", encoding="utf-8") as f:
        json.dump(doc, f)
    # Stale one of the other regions too: --check must still report it, not abort on the 280 error.
    f15 = tmp_path / "15.sql"
    f15.write_text(f15.read_text(encoding="utf-8").replace("STRUCT(", "STRUCT( ", 1), encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 1
    out = capsys.readouterr().out
    assert "280.sql: CANNOT GENERATE" in out and "15.sql: GENERATED ROUTINE LIST region is STALE" in out


def test_main_full_since_requires_write(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check", "--full-since", "2026-12-01"])
    with pytest.raises(SystemExit):
        gr.main()


def test_sql_folds_quotes_and_uses_superseded_and_corroboration():
    with open(SQL_280, encoding="utf-8") as f:
        sql = f.read()
    body = sql[sql.index("CREATE OR REPLACE VIEW `stock-trading-498512.state.instruction_drift`"):]
    assert body.count(r"r'[\x{27}\x{22}\x{60}\x{2018}\x{2019}\x{201C}\x{201D}]'") == 4
    assert "n_identical_since >= 2" in body and "matches_superseded_full" in body

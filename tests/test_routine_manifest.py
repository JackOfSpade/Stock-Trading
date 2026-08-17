"""Direct unit coverage for the shared lib scripts/lib/routine_manifest.py.

This module is the de-duplicated single implementation that BOTH scripts/print_routines.py and
scripts/check_cadence_consistency.py import (2026-07-14 audit) — its public surface (ROUTINE_SUFFIX,
heading_to_id, parse_routine_headings, build_triggers_manifest) must stay byte-stable because those
two call sites, and ops/triggers.json, depend on identical output. It was only ever exercised
TRANSITIVELY (via test_print_routines.py / test_cadence_consistency.py); these pin the contract
directly so an interface-preserving refactor of the lib has a first-class guard.
"""
import json
import os

from conftest import ROOT, load_module_from_path
from lib.routine_manifest import (
    ROUTINE_SUFFIX,
    build_triggers_manifest,
    cadence_routines,
    heading_to_id,
    instruction_text,
    parse_routine_headings,
)
from lib.textio import load_yaml

rb = load_module_from_path("routine_backup", "scripts", "routine_backup.py")

CADENCE_YAML = os.path.join(ROOT, "ops", "cadence.yaml")
TRIGGERS_JSON = os.path.join(ROOT, "ops", "triggers.json")
ROUTINE_BACKUP_JSON = os.path.join(ROOT, "ops", "routine_backup.json")


# ---- ROUTINE_SUFFIX: only headings ending in the two routine-type tags count -----------------------
def test_routine_suffix_matches_the_two_type_tags_only():
    assert ROUTINE_SUFFIX.search("D1. Market Development Scan — deep research")
    assert ROUTINE_SUFFIX.search("D2. Daily Action Conversion — regular routine")
    # A preamble / queue-schema heading (no type tag) must NOT match.
    assert not ROUTINE_SUFFIX.search("Queue schema — not a routine")
    assert not ROUTINE_SUFFIX.search("D1. Market Development Scan")


# ---- heading_to_id: id extraction, incl. the two named-routine special cases ----------------------
def test_heading_to_id_covers_numeric_alpha_and_named_forms():
    assert heading_to_id("D1. X — deep research") == "D1"
    assert heading_to_id("M1a. X — deep research") == "M1a"
    assert heading_to_id("Q4. X — regular routine") == "Q4"
    assert heading_to_id("Adversarial Review Attacker — regular routine") == "AR_att"
    assert heading_to_id("Adversarial Review Orchestrator — regular routine") == "AR_orc"
    assert heading_to_id("no leading id and not a named routine") is None


# ---- parse_routine_headings: ordered, "## "-prefixed, suffix-filtered ------------------------------
def test_parse_routine_headings_filters_and_preserves_order(tmp_path):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "# Title\n"
        "intro, not a heading\n\n"
        "## D1. First — deep research\nbody\n\n"
        "## Not A Routine Heading\nbody\n\n"
        "## D2. Second — regular routine\nbody\n\n"
        "### D9. Sub-heading level, ignored — deep research\n"   # not a "## " top heading
    )
    assert parse_routine_headings(str(plan)) == [
        "D1. First — deep research",
        "D2. Second — regular routine",
    ]


# ---- parse_routine_headings: a '## ...' line inside a fenced code block is example text, not a real
# heading -- scripts/split_task_plan.py's split() already fence-masks the identical heading test, so
# this function disagreeing with it would make split_task_plan.py's own docstring claim ("a slice can
# never disagree with the trigger manifest about what a routine heading is") false (2026-08-08 fix).
def test_parse_routine_headings_ignores_fenced_heading_lookalike(tmp_path):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "# Title\n"
        "## D1. First — deep research\nbody\n\n"
        "```\n"
        "## D9. Fake, inside a fence — deep research\n"
        "```\n\n"
        "## D2. Second — regular routine\nbody\n"
    )
    assert parse_routine_headings(str(plan)) == [
        "D1. First — deep research",
        "D2. Second — regular routine",
    ]


# ---- instruction_text: the single template shared by build_triggers_manifest, gen_routine_lists.py's
# gen_15_region (bigquery/15 canonical_instruction), and print_routines.py's display line -------------
def test_instruction_text_exact_template():
    # Pin the literal template string byte-for-byte: ops/triggers.json's `instruction`, bigquery/15's
    # `canonical_instruction`, and print_routines.py's printed line all must render identically to this
    # (2026-07-20 audit finding: the same f-string was independently re-literalized in 3 places).
    # GENERIC FORM (2026-08-17): a coded heading's description clause is dropped -- only the id + type
    # tag remain, so a description-only rename (the W2/W4 case that motivated this) never needs a live
    # RemoteTrigger push again for the instruction half.
    assert instruction_text("D1. Market Development Scan — deep research") == (
        "Read Claude_Task_Plan.md. Perform D1 — deep research."
    )


def test_instruction_text_uncoded_heading_keeps_full_text():
    # AR_att/AR_orc have no "<id>. " prefix in their heading -- the heading itself IS the only
    # identifying text, so it is kept verbatim (not generified).
    assert instruction_text("Adversarial Review Attacker — regular routine") == (
        "Read Claude_Task_Plan.md. Perform Adversarial Review Attacker — regular routine."
    )


# ---- cadence_routines: doc.get("routines", []) crashes on a bare `routines:` key (2026-07-29) ------
def test_cadence_routines_handles_populated_list():
    doc = {"routines": [{"id": "D1"}, {"id": "W1"}]}
    assert cadence_routines(doc) == [{"id": "D1"}, {"id": "W1"}]


def test_cadence_routines_missing_key_is_empty_list():
    assert cadence_routines({}) == []


def test_cadence_routines_bare_key_does_not_crash():
    # A bare `routines:` key with nothing under it parses to `{"routines": None}` (YAML), not a
    # missing key -- dict.get's default only fires when the KEY itself is absent, so the old
    # `doc.get("routines", [])` idiom crashed with TypeError: 'NoneType' object is not iterable on
    # this exact shape. Reproduced live: yaml.safe_load("routines:\n") == {"routines": None}, and
    # `{r["id"]: r for r in {"routines": None}.get("routines", [])}` raises TypeError pre-fix.
    doc = {"routines": None}
    assert cadence_routines(doc) == []


# ---- build_triggers_manifest: the {id: {monitor_class, instruction}} contract ---------------------
def test_build_triggers_manifest_shape_and_cadence_filter():
    headings = ["D1. First — deep research", "ZZ. Ghost — deep research"]
    cad = {"D1": {"monitor_class": "daily_trading"}}   # ZZ absent -> excluded (matches "if rid in cad")
    assert build_triggers_manifest(headings, cad) == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1 — deep research."},
    }


def test_build_triggers_manifest_monitor_class_none_when_missing_in_cad_row():
    # rid present in cad but the row has no monitor_class -> instruction still emitted, class None.
    got = build_triggers_manifest(["D1. First — deep research"], {"D1": {}})
    assert got == {"D1": {"monitor_class": None,
                          "instruction": "Read Claude_Task_Plan.md. Perform D1 — deep research."}}


def test_build_triggers_manifest_duplicate_id_resolves_last_heading_wins():
    # The module's stated purpose is byte-identical ops/triggers.json between its two importers, which
    # feed it DIFFERENTLY-shaped inputs: print_routines passes the RAW heading list (can hold two
    # headings for one id), check_cadence passes an already-deduped list. Convergence depends on this
    # dict-comprehension "last write wins" resolution — pin it so an interface-preserving refactor
    # can't quietly change which heading survives for a colliding id (2026-07-17 parallel-refactor audit).
    # Both headings generify to the identical instruction (Alpha/Bravo is the dropped description), so
    # this now pins "last write wins" via the underlying dict resolution rather than a visible text diff
    # -- the type tag is varied instead so the two candidate outputs are still distinguishable.
    headings = ["D1. Alpha — deep research", "D1. Bravo — regular routine"]
    cad = {"D1": {"monitor_class": "daily_trading"}}
    got = build_triggers_manifest(headings, cad)
    assert got == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1 — regular routine."},
    }


# ---- instruction_note: per-routine justification appended to the generated instruction (owner
# directive, 2026-08-17) -- OPS2 is the only routine carrying one today, see ops/cadence.yaml's OPS2
# block. --------------------------------------------------------------------------------------------
def test_build_triggers_manifest_without_note_is_the_exact_legacy_string():
    # BUG THIS CLOSES (2026-08-17): adding the optional `instruction_note` field must not touch the
    # other 31 routines that don't set it -- their generated instruction has to stay byte-for-byte the
    # legacy string: no trailing whitespace, and no stray "\n\n" appended when there is nothing to add.
    headings = ["D1. Market Development Scan — deep research"]
    cad = {"D1": {"monitor_class": "daily_trading"}}   # no instruction_note key at all
    got = build_triggers_manifest(headings, cad)["D1"]["instruction"]
    assert got == "Read Claude_Task_Plan.md. Perform D1 — deep research."
    assert not got.endswith("\n")
    assert "\n\n" not in got


def test_build_triggers_manifest_appends_note_separated_by_exactly_one_blank_line():
    # BUG THIS CLOSES (2026-08-17): a routine WITH an instruction_note must get exactly
    # "Read Claude_Task_Plan.md. Perform <id> — <type>." + "\n\n" + <note> -- not zero blank lines
    # (note runs into the sentence) and not two blank lines (a stray "\n\n\n").
    headings = ["OPS2. Catch-up Executor — regular routine"]
    cad = {"OPS2": {"monitor_class": "daily_sun_thu", "instruction_note": "NOTE — an example note."}}
    got = build_triggers_manifest(headings, cad)["OPS2"]["instruction"]
    assert got == "Read Claude_Task_Plan.md. Perform OPS2 — regular routine.\n\nNOTE — an example note."
    assert "\n\n\n" not in got


# ---- integration: the REAL ops/cadence.yaml + Claude_Task_Plan.md + committed ops/triggers.json /
# ops/routine_backup.json (read-only -- never written by these tests) -------------------------------
def _real_triggers():
    with open(TRIGGERS_JSON, encoding="utf-8") as f:
        return json.load(f)


def test_ops2_generated_instruction_ends_with_note_separated_by_one_blank_line():
    # BUG THIS CLOSES (2026-08-17): OPS2's LIVE generated instruction (committed ops/triggers.json,
    # produced by `python scripts/print_routines.py --write`) must end with its cadence.yaml
    # instruction_note, separated from the base instruction by exactly "\n\n", with no triple newline
    # anywhere in the string.
    cad = {r["id"]: r for r in cadence_routines(load_yaml(CADENCE_YAML))}
    note = cad["OPS2"]["instruction_note"]
    assert note   # sanity: OPS2 must actually carry a note today, or this test proves nothing
    instr = _real_triggers()["OPS2"]["instruction"]
    assert instr.endswith(note)
    assert instr[: -len(note)].endswith("\n\n")
    assert "\n\n\n" not in instr


def test_ops2_generated_instruction_first_line_unchanged_by_the_note():
    # LOAD-BEARING (2026-08-17): state.instruction_drift (BigQuery) compares ONLY the first line
    # (REGEXP_EXTRACT(instruction, r'^[^\n]*')) and state.routine_last_instruction filters on
    # `LIKE 'Read Claude_Task_Plan.md. Perform %'` -- appending the note must never change OPS2's first
    # line, or both would silently stop tracking/matching OPS2 (ops/cadence.yaml's OPS2 block).
    first_line = _real_triggers()["OPS2"]["instruction"].split("\n", 1)[0]
    assert first_line == "Read Claude_Task_Plan.md. Perform OPS2 — regular routine."


def test_ops2_generated_instruction_round_trips_through_routine_backup_json():
    # BUG THIS CLOSES (2026-08-17): ops/routine_backup.json already holds the VERIFIED LIVE OPS2
    # trigger instruction (the owner applied the NOTE to the live claude.ai trigger before this repo
    # change existed). OPS2 carries no ADDENDUM (scripts/routine_backup.py's OPS2_NO_ADDENDUM_ID), so
    # check()'s want = want_core + SCOPE_ADDENDUM -- the freshly generated ops/triggers.json
    # instruction (want_core) plus SCOPE_ADDENDUM must equal the stored live snapshot exactly, or
    # `python scripts/routine_backup.py check` fails.
    want_core = _real_triggers()["OPS2"]["instruction"]
    with open(ROUTINE_BACKUP_JSON, encoding="utf-8") as f:
        stored = json.load(f)["routines"]["OPS2"]["instruction"]
    assert want_core + rb.SCOPE_ADDENDUM == stored

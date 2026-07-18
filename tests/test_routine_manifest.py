"""Direct unit coverage for the shared lib scripts/lib/routine_manifest.py.

This module is the de-duplicated single implementation that BOTH scripts/print_routines.py and
scripts/check_cadence_consistency.py import (2026-07-14 audit) — its public surface (ROUTINE_SUFFIX,
heading_to_id, parse_routine_headings, build_triggers_manifest) must stay byte-stable because those
two call sites, and ops/triggers.json, depend on identical output. It was only ever exercised
TRANSITIVELY (via test_print_routines.py / test_cadence_consistency.py); these pin the contract
directly so an interface-preserving refactor of the lib has a first-class guard.
"""
from scripts.lib.routine_manifest import (
    ROUTINE_SUFFIX,
    build_triggers_manifest,
    heading_to_id,
    parse_routine_headings,
)


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


# ---- build_triggers_manifest: the {id: {monitor_class, instruction}} contract ---------------------
def test_build_triggers_manifest_shape_and_cadence_filter():
    headings = ["D1. First — deep research", "ZZ. Ghost — deep research"]
    cad = {"D1": {"monitor_class": "daily_trading"}}   # ZZ absent -> excluded (matches "if rid in cad")
    assert build_triggers_manifest(headings, cad) == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1. First — deep research."},
    }


def test_build_triggers_manifest_monitor_class_none_when_missing_in_cad_row():
    # rid present in cad but the row has no monitor_class -> instruction still emitted, class None.
    got = build_triggers_manifest(["D1. First — deep research"], {"D1": {}})
    assert got == {"D1": {"monitor_class": None,
                          "instruction": "Read Claude_Task_Plan.md. Perform D1. First — deep research."}}


def test_build_triggers_manifest_duplicate_id_resolves_last_heading_wins():
    # The module's stated purpose is byte-identical ops/triggers.json between its two importers, which
    # feed it DIFFERENTLY-shaped inputs: print_routines passes the RAW heading list (can hold two
    # headings for one id), check_cadence passes an already-deduped list. Convergence depends on this
    # dict-comprehension "last write wins" resolution — pin it so an interface-preserving refactor
    # can't quietly change which heading survives for a colliding id (2026-07-17 parallel-refactor audit).
    headings = ["D1. Alpha — deep research", "D1. Bravo — deep research"]
    cad = {"D1": {"monitor_class": "daily_trading"}}
    got = build_triggers_manifest(headings, cad)
    assert got == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1. Bravo — deep research."},
    }

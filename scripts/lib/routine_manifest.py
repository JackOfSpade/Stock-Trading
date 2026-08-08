"""Shared Claude_Task_Plan.md heading-parsing + triggers-manifest generation logic.

scripts/print_routines.py (the hand-run tool that reconstructs the canonical routine list) and
scripts/check_cadence_consistency.py (the CI checker whose "check F" asserts ops/triggers.json is
not stale) each maintained an independent, byte-identical copy of ROUTINE_SUFFIX / heading parsing /
heading_to_id / the triggers-manifest shape. Since CI never actually invokes print_routines.py, that
duplication meant "ops/triggers.json is current" really meant "matches check_cadence_consistency.py's
OWN reimplementation of the generator" — a bug fixed in one copy and not the other would silently
desync the two, and check F would keep passing on the desynced pair (2026-07-14 audit finding).
Consolidated here so there is exactly one implementation both scripts import.
"""
import re

from lib.md_fence import fence_mask

# A routine section heading ends with its type tag; this excludes preamble/queue-schema headings.
ROUTINE_SUFFIX = re.compile(r"—\s*(deep research|regular routine)\s*$")


def parse_routine_headings(plan_path):
    """Ordered list of routine section headings from the given Claude_Task_Plan.md path.

    A `## ...` line inside a fenced code block (``` or ~~~ at column 0) is example text, not a real
    heading -- without fence_mask this function disagreed with scripts/split_task_plan.py's own
    `split()`, which already fence-masks the identical heading test. split_task_plan.py's docstring
    claims a slice "can never disagree with the trigger manifest about what a routine heading is"
    BECAUSE both import this module -- that claim was false until this matched split()'s idiom
    (2026-08-08 audit finding).
    """
    with open(plan_path, encoding="utf-8") as f:
        lines = f.readlines()
    mask = fence_mask(lines)
    out = []
    for ln, in_fence in zip(lines, mask, strict=True):  # fence_mask() returns exactly one entry per input line
        if not in_fence and ln.startswith("## "):
            h = ln[3:].strip()
            if ROUTINE_SUFFIX.search(h):
                out.append(h)
    return out


def cadence_routines(doc):
    """Ordered list of routine dicts from a parsed ops/cadence.yaml document.

    `doc.get("routines", [])` is NOT enough: a bare `routines:` key with no items under it parses to
    None (YAML), and dict.get's default only fires when the KEY is missing entirely, not when its
    value is None -- so that idiom crashes with `TypeError: 'NoneType' object is not iterable` on that
    shape. scripts/gen_routine_lists.py's load_cadence_routines() already carried the `or []` guard;
    scripts/check_cadence_consistency.py's load_cadence() / cadence_duplicate_ids() and
    scripts/print_routines.py's load_cadence() did not -- the fix existed in exactly one of the four
    call sites and never propagated to the other three (2026-07-29, reproduced live against a fixture
    ops/cadence.yaml with a bare `routines:` key). One shared accessor closes all four at once."""
    return doc.get("routines", []) or []


def heading_to_id(h):
    """Map a heading to its ops/cadence.yaml id."""
    m = re.match(r"([A-Za-z0-9]+)\.\s", h)   # "D1. ...", "M1a. ...", "Q4. ..."
    if m:
        return m.group(1)
    if "Attacker" in h:
        return "AR_att"
    if "Orchestrator" in h:
        return "AR_orc"
    return None


def instruction_text(heading):
    """The canonical trigger-instruction string for a Claude_Task_Plan.md routine heading -- the
    single source for a template that is otherwise the load-bearing contract for ops/triggers.json's
    `instruction` field, bigquery/15's `canonical_instruction` column, and print_routines.py's
    display, all of which MUST agree byte-for-byte (2026-07-20 audit finding: this exact f-string was
    independently re-literalized in 3 places with no test cross-checking them)."""
    return f"Read Claude_Task_Plan.md. Perform {heading}."


def build_triggers_manifest(headings, cad):
    """The canonical {id: {monitor_class, instruction}} map — the same shape
    print_routines.py --write emits to ops/triggers.json and
    check_cadence_consistency.py's check F verifies against."""
    return {
        rid: {
            "monitor_class": cad.get(rid, {}).get("monitor_class"),
            "instruction": instruction_text(h),
        }
        for h in headings
        for rid in [heading_to_id(h)]
        if rid in cad
    }

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
from lib.textio import read_text

# A routine section heading ends with its type tag; this excludes preamble/queue-schema headings.
ROUTINE_SUFFIX = re.compile(r"—\s*(deep research|regular routine)\s*$")

# The leading "<id>. " a coded routine heading (e.g. "W1. Catalyst Calendar ... — deep research")
# starts with. AR_att/AR_orc have no such prefix (heading_to_id resolves them via substring match
# instead) -- see instruction_text()'s use of this below.
HEADING_ID_PREFIX = re.compile(r"^([A-Za-z0-9]+)\.\s")


def parse_routine_headings(plan_path):
    """Ordered list of routine section headings from the given Claude_Task_Plan.md path.

    A `## ...` line inside a fenced code block (``` or ~~~ at column 0) is example text, not a real
    heading -- without fence_mask this function disagreed with scripts/split_task_plan.py's own
    `split()`, which already fence-masks the identical heading test. split_task_plan.py's docstring
    claims a slice "can never disagree with the trigger manifest about what a routine heading is"
    BECAUSE both import this module -- that claim was false until this matched split()'s idiom
    (2026-08-08 audit finding). The line split must stay `splitlines(keepends=True)` for the same
    reason: readlines() breaks on \\n only, so any of the Unicode line separators splitlines() also
    honours (\\x0b, \\x0c, \\x85, U+2028, ...) would shift this function's lines out of alignment
    with split()'s.
    """
    lines = read_text(plan_path).splitlines(keepends=True)
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
    m = HEADING_ID_PREFIX.match(h)   # "D1. ...", "M1a. ...", "Q4. ..."
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
    independently re-literalized in 3 places with no test cross-checking them).

    GENERIC FORM (2026-08-17, Tavily-efficiency-session follow-up): a coded heading's DESCRIPTION
    clause is the part that changes on a scope/ownership redesign (e.g. W2's "Post-Event Screen" ->
    "Post-Event Enrichment" the same day this was written) -- every rename previously had to be
    pushed by hand to the live claude.ai RemoteTrigger object (no CI/script can reach that API), and
    the W2/W4 rename landed in this repo's generated artifacts without ever reaching the live
    triggers until caught and fixed manually. The instruction only needs the routine ID (to find the
    right `## <id>.` section) and its type tag (deep research vs regular routine); the description is
    for the human-facing `name` field only (see ops/routine_backup.json's per-routine `name`, updated
    separately, NOT by this generator). Dropping the description here means a future rename never
    needs a live trigger push for the INSTRUCTION half again -- only `name` still does. AR_att/
    AR_orc have no coded id prefix, so their heading itself IS the necessary identifying text and is
    kept verbatim (the HEADING_ID_PREFIX match fails for them, falling through below)."""
    prefix = HEADING_ID_PREFIX.match(heading)
    suffix = ROUTINE_SUFFIX.search(heading)
    if prefix and suffix:
        return f"Read Claude_Task_Plan.md. Perform {prefix.group(1)} — {suffix.group(1)}."
    return f"Read Claude_Task_Plan.md. Perform {heading}."


def build_triggers_manifest(headings, cad):
    """The canonical {id: {monitor_class, instruction}} map — the same shape
    print_routines.py --write emits to ops/triggers.json and
    check_cadence_consistency.py's check F verifies against.

    PER-ROUTINE INSTRUCTION NOTE (owner directive, 2026-08-17). A cadence.yaml routine row may carry an
    optional `instruction_note` string; when non-empty it is appended to instruction_text()'s output,
    separated by exactly one blank line ("\n\n"). This lives HERE rather than inside instruction_text()
    itself because instruction_text(heading) has two other callers that must keep emitting the bare
    legacy string: check_cadence_consistency.py's check B compares it against bigquery/15's
    canonical_instruction (a description-catalog concern, unrelated to a live trigger's operator-facing
    note) and print_routines.py prints it per-heading with no `cad` row in scope. Today the only routine
    with a note is OPS2 -- its live trigger deliberately omits the standing Sonnet-delegation addendum
    (ops/cadence.yaml's OPS2 block), and since claude.ai's routine-review UI cannot see this repo's
    comments, the justification is now carried INLINE in the instruction itself so a manual review does
    not keep re-flagging the omission as a defect."""
    manifest = {}
    for h in headings:
        rid = heading_to_id(h)
        if rid not in cad:
            continue
        row = cad.get(rid, {})
        instr = instruction_text(h)
        note = row.get("instruction_note")
        if note:
            instr = f"{instr}\n\n{note}"
        manifest[rid] = {"monitor_class": row.get("monitor_class"), "instruction": instr}
    return manifest

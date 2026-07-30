#!/usr/bin/env python3
"""Generate per-routine slices of Claude_Task_Plan.md (DEF-2, architecture — SAFE phase).

PROBLEM: Claude_Task_Plan.md is ~2.3k lines and every scheduled routine loads the WHOLE plan at
session start just to reach its own ~50-100 line section — token cost + latency — mirroring the
Strategy.md problem that scripts/split_strategy.py already solved (P3-1). A routine only needs the
shared binding preamble (OPERATING MODEL + FILE CONVENTIONS, which carry the Observability, Calendar
and IBKR usage rules) plus its own section; the other ~40 sibling routines are pure context bloat.

THIS SCRIPT splits Claude_Task_Plan.md into task_plan/<ID>.md, each = the shared preamble + that
routine's group header + that routine's own section. IDs are the ops/cadence.yaml ids (D1, D2a,
OPS0, AR_att, SL3, ...) so a slice is addressable by the same key the trigger manifest uses.

SAFETY / PARALLEL-RUN (monolith stays CANONICAL): Claude_Task_Plan.md remains the single source of
truth. These slices are GENERATED artifacts (regenerate after any plan edit) carrying a DO-NOT-EDIT
header. Re-pointing routine trigger-instructions at the slices (ops/triggers.json) is a SEPARATE,
owner-gated live-ops cutover, deliberately OUT OF SCOPE here — exactly how the .md->BigQuery
migration was staged (parallel-run first, flip later). Until then nothing breaks: routines keep
reading Claude_Task_Plan.md; the slices are an available, verified-identical read-optimized view.

Parsing (shared with scripts/lib/routine_manifest.py — the same ROUTINE_SUFFIX / heading_to_id used
by print_routines.py + check_cadence_consistency.py, so a slice can never disagree with the trigger
manifest about what a routine heading is):
  * preamble  = everything before the first cadence-group header (`# DAILY ...`) — i.e. the title,
    ROUTINE INVENTORY, OPERATING MODEL and FILE CONVENTIONS top-level sections. Shared by every slice.
  * group intro = a cadence group's `# ...` header + any text before its first routine (e.g. the
    ADVERSARIAL REVIEWS queue-schema block) — prepended to every routine slice in that group.
  * section   = a routine `## <ID>. ... — (deep research|regular routine)` heading through the next
    routine heading or next cadence-group header.

Usage:  python scripts/split_task_plan.py          # (re)generates task_plan/*.md + task_plan/INDEX.md
        python scripts/split_task_plan.py --check   # verify slices match the plan (CI-friendly)
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.md_fence import fence_mask  # noqa: E402
from lib.routine_manifest import ROUTINE_SUFFIX, heading_to_id  # noqa: E402
from lib.slice_writer import check_or_write_slices, slugify  # noqa: E402
from lib.textio import read_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Claude_Task_Plan.md")
OUTDIR = os.path.join(ROOT, "task_plan")
HEADER = ("<!-- GENERATED from Claude_Task_Plan.md by scripts/split_task_plan.py — DO NOT EDIT.\n"
          "     Claude_Task_Plan.md is canonical; regenerate after editing it. -->\n\n")
# Hand-maintained files in task_plan/ that this script does not generate and must never flag as orphans.
HAND_MAINTAINED = {"README.md"}


def slug(title: str) -> str:
    return slugify(title)


def split(text):
    """Return (preamble, [(id, title, group_intro, body), ...]).

    A `#`/`##` line inside a fenced code block (``` or ~~~ at column 0) is body text, not a heading —
    the plan's routine sections embed markdown/SQL examples with column-0 hashes, and treating one as
    a heading would split a code block across two slices and silently truncate a section. `--check`
    proves today's tree is byte-identical.
    """
    lines = text.splitlines(keepends=True)
    fence = fence_mask(lines)

    def is_group(i):
        return (not fence[i]) and re.match(r"^# ", lines[i]) is not None

    def is_routine(i):
        return (not fence[i]) and lines[i].startswith("## ") and ROUTINE_SUFFIX.search(lines[i][3:].strip())

    first_routine = next((i for i in range(len(lines)) if is_routine(i)), None)
    if first_routine is None:
        return text, []
    # Preamble ends at the cadence-group header that opens the routines region (the last `# ...`
    # top-level heading at or before the first routine — `# DAILY ...`).
    group_headers = [i for i in range(first_routine + 1) if is_group(i)]
    if not group_headers:
        # Routines always live under a `# <CADENCE>` group header. If the plan is ever restructured so
        # the first routine precedes every top-level `# ` header, fail with an actionable message
        # instead of an opaque `max() arg is an empty sequence` ValueError from the max() below.
        raise ValueError(
            "Claude_Task_Plan.md: the first routine heading has no preceding `# ` cadence-group "
            "header (routines must sit under a `# DAILY`/`# WEEKLY`/... group). Fix the plan structure."
        )
    group_start = max(group_headers)
    preamble = "".join(lines[:group_start])

    routines = []
    group_intro = ""
    cur = None
    for i in range(group_start, len(lines)):
        if is_group(i):
            if cur:
                routines.append(cur)
                cur = None
            group_intro = lines[i]
        elif is_routine(i):
            if cur:
                routines.append(cur)
            title = lines[i][3:].strip()
            rid = heading_to_id(title) or slug(title)
            cur = [rid, title, group_intro, lines[i]]
        elif cur is not None:
            cur[3] += lines[i]
        else:
            # cur is None here iff no routine has been seen since the last group header (or since
            # group_start) — i.e. we are inside a group's intro region — so accumulate the intro.
            group_intro += lines[i]
    if cur:
        routines.append(cur)
    return preamble, routines


def build():
    text = read_text(SRC)
    preamble, routines = split(text)
    files = {"00_preamble.md": HEADER + preamble}
    index = ["# Claude_Task_Plan.md — generated routine-slice index\n",
             "\nRead-optimized slices of the canonical `Claude_Task_Plan.md`. Each `<ID>.md` is the "
             "shared preamble (OPERATING MODEL + FILE CONVENTIONS) + that routine's own section. Load "
             "only the slice a routine needs; the monolith stays authoritative.\n\n",
             "| Routine ID | Section | File |\n|---|---|---|\n",
             "| _(shared)_ | preamble: OPERATING MODEL + FILE CONVENTIONS | `00_preamble.md` |\n"]
    used = set()
    for rid, title, group_intro, body in routines:
        name = f"{rid}.md"
        while name in used:   # defensive: a duplicate cadence id would otherwise clobber a sibling slice
            name = name[:-3] + "_.md"
        used.add(name)
        files[name] = HEADER + preamble + group_intro + body
        index.append(f"| {rid} | {title} | `{name}` |\n")
    files["INDEX.md"] = "".join(index)
    return files


def main(argv):
    check = "--check" in argv
    files = build()
    return check_or_write_slices(
        files,
        outdir=OUTDIR,
        check=check,
        hand_maintained=HAND_MAINTAINED,
        stale_message="STALE slices (run scripts/split_task_plan.py): ",
        orphan_message=(
            "ORPHANED slice file(s) — no longer produced by any current Claude_Task_Plan.md heading "
            "(a routine was likely renamed/removed; delete these or the check will keep failing): "
        ),
        orphan_warning="WARNING: orphaned slice file(s) present (not written by this run, not hand-maintained): ",
        ok_message="task_plan/ slices are in sync with Claude_Task_Plan.md",
        wrote_message=f"Wrote {len(files)} files to task_plan/",
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

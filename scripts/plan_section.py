#!/usr/bin/env python3
"""Print ONE routine's own section of Claude_Task_Plan.md in a few bounded parts.

WHY (run-log audit 2026-11-16). A routine finds its section in a 1.6 MB plan by exploring: `grep -n
'^## '`, then `sed`/`awk` line ranges, then re-reads of outputs that spilled to a file. Measured over
the 30 fleet runs of 2026-11-15..17: 7 to 31 such calls per run, one message each, and every message
re-reads the whole context. This prints the same text deterministically, in parts small enough to come
back inline, so a routine issues all the part commands in ONE message.

The section is the routine's cadence-group intro plus its own `## <ID>. ...` body, exactly as
scripts/split_task_plan.py slices it; the shared preamble is NOT included (use --preamble-toc and read
the ranges you need from task_plan/00_preamble.md).

Usage:
  python3 scripts/plan_section.py D1                 # list the parts: number, lines, bytes, first words
  python3 scripts/plan_section.py D1 --part 2        # print part 2
  python3 scripts/plan_section.py --preamble-toc     # headings of the shared preamble, with line numbers
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import split_task_plan as stp
from lib.textio import read_text_preserving_newlines

# A Bash result of about 27,000 characters came back inline in the audited runs and ones over 30,000
# spilled to a file that then cost further Read calls, so parts stay under this.
PART_CHARS = 24000


def parts_of(text, limit=PART_CHARS):
    """Split text into consecutive parts of whole lines, each at most `limit` characters unless a
    single line is longer (a line is never cut, so every rule stays intact)."""
    out, cur, size = [], [], 0
    for line in text.splitlines(keepends=True):
        if cur and size + len(line) > limit:
            out.append("".join(cur))
            cur, size = [], 0
        cur.append(line)
        size += len(line)
    if cur:
        out.append("".join(cur))
    return out


def section(routine_id, text):
    """The group intro + own body for routine_id, or None when the plan has no such routine."""
    _, routines = stp.split(text)
    for rid, _title, group_intro, body in routines:
        if rid == routine_id:
            return group_intro + body
    return None


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("routine", nargs="?")
    ap.add_argument("--part", type=int)
    ap.add_argument("--preamble-toc", action="store_true")
    args = ap.parse_args(argv)
    text = read_text_preserving_newlines(stp.SRC)

    if args.preamble_toc:
        preamble, _ = stp.split(text)
        # Line numbers are those of task_plan/00_preamble.md, which carries the generated header first.
        offset = stp.HEADER.count("\n")
        for n, line in enumerate(preamble.splitlines(), start=1 + offset):
            if line.startswith("#"):
                print(f"{n}\t{line[:110]}")
        return 0

    if not args.routine:
        ap.error("give a routine id, or --preamble-toc")
    sec = section(args.routine, text)
    if sec is None:
        _, routines = stp.split(text)
        print(f"no routine {args.routine!r}; ids: {' '.join(r[0] for r in routines)}", file=sys.stderr)
        return 2
    parts = parts_of(sec)
    if args.part is None:
        print(f"{args.routine}: {len(sec)} characters in {len(parts)} parts. Issue all of these in ONE message:")
        for i, p in enumerate(parts, start=1):
            first = p.lstrip().splitlines()[0][:70] if p.strip() else ""
            print(f"  python3 scripts/plan_section.py {args.routine} --part {i}\t# {len(p)} chars: {first}")
        return 0
    if not 1 <= args.part <= len(parts):
        print(f"part {args.part} out of range 1..{len(parts)}", file=sys.stderr)
        return 2
    sys.stdout.write(parts[args.part - 1])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

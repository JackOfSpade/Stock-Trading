#!/usr/bin/env python3
"""Generate per-section slices of Strategy.md (P3-1).

PROBLEM: Strategy.md is ~339 KB and every strategy routine loads the whole thing at session
start — token cost + latency — and the architectural "blinding" (M1a must not read strategy
sections; an attacker must not read beyond its scope) is enforced only by *instruction*, which
the analysis flagged as a recurring "remember-to" fragility.

THIS SCRIPT splits Strategy.md on its top-level `## ` headings into strategy/<slug>.md slices,
so a routine can load ONLY its section + the shared preamble. That cuts context AND lets the
blinding become a hard file-boundary instead of a soft rule.

SAFETY / PARALLEL-RUN: Strategy.md stays the single canonical source. These slices are GENERATED
(regenerate after any Strategy.md edit) and carry a DO-NOT-EDIT header. Re-pointing routine
read-instructions at the slices is a SEPARATE, owner-gated cutover (exactly how the system did
its .md->BigQuery migration: parallel-run first, flip later). Until then nothing breaks: routines
keep reading Strategy.md; the slices are an available, verified-identical view.

Usage:  python scripts/split_strategy.py          # (re)generates strategy/*.md + strategy/INDEX.md
        python scripts/split_strategy.py --check   # verify slices match Strategy.md (CI-friendly)
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.md_fence import fence_mask  # noqa: E402
from lib.slice_writer import check_or_write_slices, slugify  # noqa: E402
from lib.textio import read_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Strategy.md")
OUTDIR = os.path.join(ROOT, "strategy")
HEADER = ("<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.\n"
          "     Strategy.md is canonical; regenerate after editing it. -->\n\n")
# Hand-maintained files in strategy/ that this script does not generate and must never flag as orphans.
HAND_MAINTAINED = {"README.md"}


def slug(title: str) -> str:
    s = title.strip().lower()
    # Anchored (^): this rewrite is only for a section TITLE that STARTS with "Strategy <letter>:"
    # (e.g. "Strategy C: ..." -> strategy_c). Unanchored, a title merely MENTIONING "Strategy A:"
    # mid-line (e.g. "Notes on Strategy A: results") would match and silently truncate everything
    # after it. Byte-identical for every current heading (all real ones begin with the phrase).
    s = re.sub(r"^strategy ([a-e]):.*", r"strategy_\1", s)
    return slugify(s)


def split(text: str):
    """Return (preamble, [(title, body_including_heading), ...]) split on top-level '## '.

    A `## ` line INSIDE a fenced code block (``` or ~~~ at column 0) is body text, NOT a section
    heading. Strategy.md sections are machine-authored (SISA SL2) and can carry markdown examples
    with column-0 '## ' lines; treating one as a heading would split a code block across two slices
    and silently truncate the real section (2026-07-17 audit). The current Strategy.md has no such
    case, so this is byte-identical for today's tree — verify with `--check`."""
    lines = text.splitlines(keepends=True)
    fence = fence_mask(lines)
    idx = []
    for i, ln in enumerate(lines):
        if not fence[i] and re.match(r"^## ", ln):
            idx.append(i)
    preamble = "".join(lines[: idx[0]]) if idx else text
    sections = []
    for n, start in enumerate(idx):
        end = idx[n + 1] if n + 1 < len(idx) else len(lines)
        title = lines[start][3:].strip()
        sections.append((title, "".join(lines[start:end])))
    return preamble, sections


def build():
    text = read_text(SRC)
    preamble, sections = split(text)
    files = {"00_preamble.md": HEADER + preamble}
    index = ["# Strategy.md — generated section index\n",
             "\nThese are read-optimized slices of the canonical `Strategy.md` "
             "(see `strategy/README.md`). Load only what a routine needs.\n\n",
             "| Section | File |\n|---|---|\n",
             "| _(preamble: title + intro)_ | `00_preamble.md` |\n"]
    used = set()
    for i, (title, body) in enumerate(sections, 1):
        name = f"{i:02d}_{slug(title)}.md"
        while name in used:
            name = name[:-3] + "_.md"
        used.add(name)
        files[name] = HEADER + body
        index.append(f"| {title} | `{name}` |\n")
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
        stale_message="STALE slices (run scripts/split_strategy.py): ",
        orphan_message=(
            "ORPHANED slice file(s) — no longer produced by any current Strategy.md heading "
            "(a section was likely renamed/removed; delete these or the check will keep failing): "
        ),
        orphan_warning="WARNING: orphaned slice file(s) present (not written by this run, not hand-maintained): ",
        ok_message="strategy/ slices are in sync with Strategy.md",
        wrote_message=f"Wrote {len(files)} files to strategy/",
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

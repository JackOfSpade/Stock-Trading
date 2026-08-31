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
from lib.md_fence import fence_mask
from lib.slice_writer import dedupe_slice_name, run_split_cli, slugify
from lib.textio import read_text_preserving_newlines

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
    # Any single letter, not just the A-E roster of today: the SISA lifecycle adopts strategies
    # autonomously up to roster.yaml's n_max, and a code past E must still slug to `strategy_<x>`
    # so check_roster_consistency.py's SLICE_FILE_REF (`\d+_strategy_([a-z]{1,3})\.md`) can resolve
    # the generated slice filename back to a roster code.
    s = re.sub(r"^strategy ([a-z]):.*", r"strategy_\1", s)
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
    # BUG FIX (tooling-misc#2, code-quality pass 2026-08-31): read_text() would silently normalize a
    # CRLF/bare-\r source line to \n before split() ever sees it, undermining this script's own
    # "byte-identical for today's tree" claim above -- the exact bug class
    # scripts/adversarial_review_storage.py::parse_legacy_review already found and fixed for its own
    # reader. Paired with lib/slice_writer.py's newline="" read/write.
    text = read_text_preserving_newlines(SRC)
    preamble, sections = split(text)
    # A '## Strategy <code> [CANDIDATE]' section generates NO slice AND does not consume a slice
    # number (added 2026-08-25, SL5 diligence sweep). This mirrors check_roster_consistency.py's
    # headings_in(), which has always excluded '[CANDIDATE]' from the roster-active heading set --
    # this generator was the half of that pair that never learned the rule.
    #
    # WHY IT IS LOAD-BEARING, not tidying: SL5 branch (1) SHADOW-register is REQUIRED to add the
    # '## Strategy <code> [CANDIDATE]' section (its golden fixtures name Strategy.md as the file the
    # newcomer's rules live in at that stage) and is equally REQUIRED not to run the repo-view fanout
    # ("No repo-view fanout yet (still candidate-namespace, zero capital)"). Without this filter those
    # two instructions contradict each other: the new '## ' heading alone makes every on-disk slice
    # stale and orphans the tail, so `split_strategy.py --check` -- a blocking, no-continue-on-error
    # step of ci.yml -- fails on the arsenal's first-ever SHADOW registration. Auto-merge is
    # fail-closed and retries a tip SHA exactly once, so the registering session, which has ended,
    # could never fix its own stranded branch. Measured 2026-08-25 by simulating the branch-(1)
    # commit in a scratch copy: `STALE slices (run scripts/split_strategy.py): 08_strategy_f_candidate
    # ....md, 09_pre_mortems.md, ... INDEX.md` plus three ORPHANED files, and the failure is
    # placement-independent (appending the section at end-of-file still trips it).
    #
    # Skipping the number too (rather than generating nothing at a consumed index) is what keeps the
    # rest of the tail byte-identical, so a CANDIDATE section is a genuine no-op on the generated
    # tree. That also keeps R-F's SHARED_LOCKED_OPERATIONAL_PROSE -- which still hardcodes
    # '09_regime_scoring_strategy_blind_monthly.md' BY NUMBER -- from breaking when a candidate is
    # authored above that section, the second failure the same measurement surfaced.
    #
    # The candidate's slice is created later, by branch (2) PROBE-register, which first renames the
    # heading to plain '## Strategy <code>' and then runs this script -- exactly as branch (2)'s
    # "split_strategy.py first creates it" already promises. Provably a no-op on today's tree:
    # Strategy.md carries zero '[CANDIDATE]' headings, so --check stays green on this commit.
    sections = [(t, b) for t, b in sections if "[CANDIDATE]" not in t.upper()]
    files = {"00_preamble.md": HEADER + preamble}
    index = ["# Strategy.md — generated section index\n",
             "\nThese are read-optimized slices of the canonical `Strategy.md` "
             "(see `strategy/README.md`). Load only what a routine needs.\n\n",
             "| Section | File |\n|---|---|\n",
             "| _(preamble: title + intro)_ | `00_preamble.md` |\n"]
    used = set()
    for i, (title, body) in enumerate(sections, 1):
        # dedupe_slice_name: shared with split_task_plan.py's identical collision guard
        # (tooling-misc#0) -- see test_build_collision_suffix_loop_is_never_triggered_by_the_index_prefix
        # for why the index prefix already makes this loop unreachable via the normal build() path.
        name = dedupe_slice_name(f"{i:02d}_{slug(title)}.md", used)
        files[name] = HEADER + body
        index.append(f"| {title} | `{name}` |\n")
    files["INDEX.md"] = "".join(index)
    return files


def main(argv):
    # CLEANUP (tooling-misc#0, code-quality pass 2026-08-31): this check/build/write dispatch used to
    # be hand-written here AND in split_task_plan.py's main(), identically except for five message
    # strings — now the one shared body, in lib/slice_writer.py, parameterized by this script's own
    # identity.
    return run_split_cli(
        argv,
        build,
        outdir=OUTDIR,
        outdir_label="strategy/",
        source_name="Strategy.md",
        script_name="split_strategy.py",
        unit_noun="section",
        hand_maintained=HAND_MAINTAINED,
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

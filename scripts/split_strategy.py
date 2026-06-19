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

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Strategy.md")
OUTDIR = os.path.join(ROOT, "strategy")
HEADER = ("<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.\n"
          "     Strategy.md is canonical; regenerate after editing it. -->\n\n")


def slug(title: str) -> str:
    s = title.strip().lower()
    s = re.sub(r"strategy ([a-e]):.*", r"strategy_\1", s)   # "Strategy C: ..." -> strategy_c
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    return s or "section"


def split(text: str):
    """Return (preamble, [(title, body_including_heading), ...]) split on top-level '## '."""
    lines = text.splitlines(keepends=True)
    idx = [i for i, ln in enumerate(lines) if re.match(r"^## ", ln)]
    preamble = "".join(lines[: idx[0]]) if idx else text
    sections = []
    for n, start in enumerate(idx):
        end = idx[n + 1] if n + 1 < len(idx) else len(lines)
        title = lines[start][3:].strip()
        sections.append((title, "".join(lines[start:end])))
    return preamble, sections


def build():
    with open(SRC) as f:
        text = f.read()
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
    os.makedirs(OUTDIR, exist_ok=True)
    drift = []
    for name, content in files.items():
        path = os.path.join(OUTDIR, name)
        existing = open(path).read() if os.path.exists(path) else None
        if check:
            if existing != content:
                drift.append(name)
        else:
            with open(path, "w") as f:
                f.write(content)
    if check:
        if drift:
            print("STALE slices (run scripts/split_strategy.py): " + ", ".join(sorted(drift)), file=sys.stderr)
            return 1
        print("strategy/ slices are in sync with Strategy.md")
        return 0
    print(f"Wrote {len(files)} files to strategy/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

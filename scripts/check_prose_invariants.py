#!/usr/bin/env python3
"""Fail CI if routine-executed prose re-instructs RETIRED behavior (finding H6, 2026-07-17).

WHY THIS EXISTS. The scheduled Claude routines READ AND ACT ON the prose in Claude_Task_Plan.md,
Operating_Protocols.md, Watchlist.md, README.md, and AI_Trading_Foundation.md. When a mechanism is
retired (the 2026-06-06 `.md`->BigQuery cutover; the 2026-07-09 calendar-scope narrowing; the D2/D2a
Step-0 cutover; the SGOV->VOO park cutover), the changelog + the §15 redirect map get updated but a
stray IMPERATIVE instruction elsewhere in the same file can keep telling a routine to do the retired
thing (write to Portfolio_Ledger.md, hand-carry a router state from Regime_State.md, drop an order
confirmation into a calendar event, apply a pinned SQL range). Nothing cross-checked the prose, so
those lingered. This check makes ops/prose_invariants.yaml the source of truth and turns each retired-
instruction class into a machine-checked invariant — a future revision that re-introduces the retired
phrasing (silent non-propagation) fails the build with a file:line diff, exactly as
scripts/check_cadence_consistency.py / check_roster_consistency.py guard their own domains.

RULE SEMANTICS (ops/prose_invariants.yaml `invariants:` list):
  files             : file(s) the rule scans (repo-relative).
  forbid_regex      : FAIL for every non-exempt line matching it (a retired instruction re-appeared).
  require_regex     : FAIL if NO line in the file matches it (a load-bearing correct phrasing vanished).
  ignorecase        : optional bool; case-insensitive match.
  exempt_line_regex : optional; a line matching this is SKIPPED for forbid_regex (sanctioned passages —
                      the §15 map, dated changelog lines, explicit "retired"/"there is no <file>" notes).
  exempt_sections   : optional list of markdown-heading substrings; a forbid match under a heading
                      containing one of them is skipped.
  reason / source_of_truth : printed on failure so the fix is self-evident.

Exactly one of forbid_regex / require_regex per rule. The forbid_regex-es are deliberately tight to the
retired IMPERATIVE phrasing (not the bare filename), so the many legitimate references (the redirect
map, "Portfolio_Ledger.md retired, §15") do not trip them.

Usage:  python scripts/check_prose_invariants.py        # exit 0 if all invariants hold, 1 + diff if not
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "ops", "prose_invariants.yaml")

HEADING = re.compile(r"^#{1,6}\s+(.*\S)")
FENCE = re.compile(r"^(```|~~~)")


def load_spec():
    with open(SPEC, encoding="utf-8") as f:
        doc = yaml.safe_load(f) or {}
    return doc.get("invariants", [])


def fence_mask(lines):
    """Per-line bool: True where the line sits INSIDE a fenced code block (``` or ~~~ at column 0).
    A column-0 '#'/'##' inside a fence is a code comment, not a markdown heading — the same fence
    handling scripts/split_task_plan.py / split_strategy.py already use. Used by nearest_heading so
    exempt_sections attributes a forbid match to the right REAL heading, not a stray code-comment."""
    mask = [False] * len(lines)
    in_fence = False
    for i, ln in enumerate(lines):
        if FENCE.match(ln):
            in_fence = not in_fence
        mask[i] = in_fence
    return mask


def files_for(rule):
    if rule.get("files"):
        return list(rule["files"])
    if rule.get("file"):
        return [rule["file"]]
    return []


def nearest_heading(lines, idx, in_fence=None):
    """The text of the closest markdown heading at or before line index `idx` (0-based), or ''.
    Lines inside a fenced code block (per `in_fence` from fence_mask) are skipped: a '# comment'
    inside a ```-fence is not a heading, and treating it as one would mis-attribute a forbid match to
    the wrong section (breaking exempt_sections)."""
    for j in range(idx, -1, -1):
        if in_fence is not None and in_fence[j]:
            continue
        m = HEADING.match(lines[j])
        if m:
            return m.group(1)
    return ""


def check_rule(rule, errors):
    rid = rule.get("id", "<unnamed>")
    has_forbid = "forbid_regex" in rule
    has_require = "require_regex" in rule
    if has_forbid == has_require:
        errors.append(f"[{rid}] rule must have EXACTLY ONE of forbid_regex / require_regex")
        return
    flags = re.IGNORECASE if rule.get("ignorecase") else 0
    targets = files_for(rule)
    if not targets:
        errors.append(f"[{rid}] rule names no files (need `files:` or `file:`)")
        return

    exempt_line = re.compile(rule["exempt_line_regex"], flags) if rule.get("exempt_line_regex") else None
    exempt_sections = rule.get("exempt_sections") or []

    # Each rule matches one PHYSICAL LINE at a time (pat.search(ln) below over read().split("\n")),
    # so `^`/`$` already anchor to the line's ends and a cross-line regex is unsupported by design —
    # no re.MULTILINE (it would be inert here and only imply cross-line matching that does not exist).
    pat = re.compile(rule["forbid_regex" if has_forbid else "require_regex"], flags)

    for rel in targets:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            errors.append(f"[{rid}] {rel}: file not found (rule targets a missing file)")
            continue
        with open(path, encoding="utf-8") as f:
            lines = f.read().split("\n")

        if has_require:
            if not any(pat.search(ln) for ln in lines):
                errors.append(f"[{rid}] {rel}: REQUIRED phrasing not found — /{rule['require_regex']}/\n"
                              f"        reason: {(rule.get('reason') or '').strip()}\n"
                              f"        source of truth: {rule.get('source_of_truth', '?')}")
            continue

        # forbid: report every non-exempt matching line. The fence mask is only needed for
        # exempt_sections (nearest_heading) and is computed once per file, lazily.
        in_fence = fence_mask(lines) if exempt_sections else None
        for i, ln in enumerate(lines):
            m = pat.search(ln)
            if not m:
                continue
            if exempt_line and exempt_line.search(ln):
                continue
            if exempt_sections:
                head = nearest_heading(lines, i, in_fence)
                if any(sub in head for sub in exempt_sections):
                    continue
            errors.append(
                f"[{rid}] {rel}:{i + 1}: RETIRED instruction re-appeared — matched "
                f"{m.group(0)!r}\n"
                f"        reason: {(rule.get('reason') or '').strip()}\n"
                f"        source of truth: {rule.get('source_of_truth', '?')}")


def main():
    rules = load_spec()
    if not rules:
        print("PROSE INVARIANTS: no rules found in ops/prose_invariants.yaml — nothing to check.")
        return 1
    errors = []
    seen_ids = set()
    for rule in rules:
        rid = rule.get("id")
        if not rid:
            errors.append("a rule is missing its `id`")
        elif rid in seen_ids:
            errors.append(f"duplicate rule id: {rid}")
        else:
            seen_ids.add(rid)
        check_rule(rule, errors)

    if errors:
        print("PROSE INVARIANTS: FAIL\n")
        for e in errors:
            print(" - " + e)
        print("\nFix the prose (redirect the retired instruction per Operating_Protocols.md §15 / the "
              "relevant cutover), OR — if the mechanism genuinely changed — update ops/prose_invariants.yaml "
              "in the SAME commit. See that file's header.")
        return 1

    n_files = sum(len(files_for(r)) for r in rules)
    print(f"PROSE INVARIANTS: OK — {len(rules)} invariants checked across {n_files} file-targets; "
          f"no retired-instruction phrasing present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

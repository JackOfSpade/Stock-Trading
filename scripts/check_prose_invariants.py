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
  ignore_strikethrough : optional bool; remove paired `~~struck-through~~` spans before matching.
                      It applies to BOTH forbid and require rules, preserves line numbers, and supports
                      valid multi-line Markdown spans.  An active instruction elsewhere on the same
                      physical line remains visible to the guard.
  match_paragraph   : optional bool; match consecutive non-blank Markdown lines as one normalized
                      paragraph. Newlines are replaced with one space and failures report the first
                      physical line. This closes soft-wrap bypasses while keeping line mode default.
  match_wrapped_lines : optional bool; after checking physical lines, also check each pair of adjacent
                      non-blank lines joined by one space. This is the preferred narrow defense against
                      ordinary Markdown soft wrapping when unrelated clauses may share a long paragraph.
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
    import yaml  # noqa: F401 — kept only for this early, actionable failure message; the actual
    # parsing below goes through lib.textio.load_yaml() (2026-07-29), which imports yaml itself and
    # would raise the SAME missing-dependency error, just as a bare traceback instead of this one.
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.md_fence import fence_mask  # noqa: E402
from lib.textio import load_yaml, read_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "ops", "prose_invariants.yaml")

HEADING = re.compile(r"^#{1,6}\s+(.*\S)")
LIST_ITEM = re.compile(r"^\s*(?:[-+*]|\d+[.)])\s+")


def wrapped_line_boundary(left, right):
    """Whether two non-blank lines must remain separate match units.

    A soft-wrapped continuation is safe to join, but sibling list items, headings, fenced-code
    delimiters, blockquotes, and table rows are independent Markdown constructs.  Joining either
    side of those constructs would synthesize an instruction that readers never see.
    """
    left = left.strip()
    right = right.strip()
    return (
        bool(HEADING.match(left) or HEADING.match(right))
        or bool(LIST_ITEM.match(right))
        or left.startswith(("```", "~~~", ">", "|"))
        or right.startswith(("```", "~~~", ">", "|"))
    )


def load_spec():
    return load_yaml(SPEC).get("invariants", [])


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


def without_strikethrough(lines):
    """Return ``lines`` with paired Markdown ``~~...~~`` spans blanked out.

    Markdown permits a strikethrough span to cross a physical line.  Matching each line with
    ``re.sub(r"~~.*?~~", ...)`` therefore leaked the middle of a valid multi-line historical quote
    into a forbid rule, and (worse) let a struck-only required doctrine satisfy a require rule.
    This scanner removes only *paired* delimiters, preserves every newline/line index, and leaves an
    unmatched delimiter visible as ordinary text instead of guessing that active prose is historical.
    Blanking with spaces rather than joining text also prevents two live words separated by a struck
    span from being accidentally concatenated into a new regex match.
    """
    text = "\n".join(lines)
    visible = list(text)
    cursor = 0
    while True:
        start = text.find("~~", cursor)
        if start < 0:
            break
        end = text.find("~~", start + 2)
        if end < 0:
            break
        for idx in range(start, end + 2):
            if visible[idx] != "\n":
                visible[idx] = " "
        cursor = end + 2
    return "".join(visible).split("\n")


def match_units(lines, paragraph_mode=False, wrapped_lines=False):
    """Yield ``(start_line_index, end_line_index, text)`` units for regex matching.

    Line mode preserves the checker's original behavior. Paragraph mode joins consecutive non-blank
    Markdown lines with a single space, so an editor's harmless soft wrap cannot split a retired
    instruction into two individually-safe lines. The first physical index is retained for diagnostics
    and heading attribution. Blank lines remain hard boundaries, preventing unrelated sections from
    being combined into one synthetic match.
    """
    if not paragraph_mode:
        for i, line in enumerate(lines):
            yield i, i, line
        if wrapped_lines:
            for i in range(len(lines) - 1):
                if (lines[i].strip() and lines[i + 1].strip()
                        and not wrapped_line_boundary(lines[i], lines[i + 1])):
                    yield i, i + 1, f"{lines[i].strip()} {lines[i + 1].strip()}"
        return

    start = None
    parts = []
    for i, line in enumerate(lines):
        if line.strip():
            if start is None:
                start = i
            parts.append(line.strip())
            continue
        if start is not None:
            yield start, i - 1, " ".join(parts)
            start = None
            parts = []
    if start is not None:
        yield start, len(lines) - 1, " ".join(parts)


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
    ignore_strikethrough = rule.get("ignore_strikethrough", False)
    paragraph_mode = rule.get("match_paragraph", False)
    wrapped_lines = rule.get("match_wrapped_lines", False)

    # Line matching remains the default. A rule that opts into match_paragraph normalizes consecutive
    # non-blank lines first; neither mode uses re.MULTILINE, so ^/$ anchor to the complete match unit.
    pat = re.compile(rule["forbid_regex" if has_forbid else "require_regex"], flags)

    for rel in targets:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            errors.append(f"[{rid}] {rel}: file not found (rule targets a missing file)")
            continue
        lines = read_text(path).split("\n")
        match_lines = without_strikethrough(lines) if ignore_strikethrough else lines
        units = list(match_units(match_lines, paragraph_mode, wrapped_lines))

        if has_require:
            if not any(pat.search(text) for _, _, text in units):
                errors.append(f"[{rid}] {rel}: REQUIRED phrasing not found — /{rule['require_regex']}/\n"
                              f"        reason: {(rule.get('reason') or '').strip()}\n"
                              f"        source of truth: {rule.get('source_of_truth', '?')}")
            continue

        # forbid: report every non-exempt matching line. The fence mask is only needed for
        # exempt_sections (nearest_heading) and is computed once per file, lazily.
        in_fence = fence_mask(lines) if exempt_sections else None
        reported_lines = set()
        for i, end_i, match_line in units:
            m = pat.search(match_line)
            if not m:
                continue
            # Physical-line units are yielded first. Do not duplicate the same finding when a later
            # two-line soft-wrap window overlaps a line already reported on its own.
            if any(line_i in reported_lines for line_i in range(i, end_i + 1)):
                continue
            if exempt_line and exempt_line.search(match_line):
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
            reported_lines.update(range(i, end_i + 1))


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

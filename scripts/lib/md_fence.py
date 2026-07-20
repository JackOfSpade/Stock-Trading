"""Shared markdown fenced-code-block line-mask.

scripts/check_prose_invariants.py, scripts/split_task_plan.py, and scripts/split_strategy.py each
independently tracked "is this line inside a ``` / ~~~ fence" — check_prose_invariants.py's own
fence_mask() docstring literally cited the other two scripts' logic instead of importing it.
Consolidated here so a future fence-handling fix (e.g. supporting indented fences) lands in one
place instead of three (2026-07-18 audit finding, cluster "dedup-sweep").
"""
import re

FENCE = re.compile(r"^(```|~~~)")


def fence_mask(lines):
    """Per-line bool: True where the line sits INSIDE a fenced code block (``` or ~~~ at column 0).
    A column-0 '#'/'##' inside a fence is a code comment, not a markdown heading — the same fence
    handling scripts/split_task_plan.py / split_strategy.py already use. Used by nearest_heading so
    exempt_sections attributes a forbid match to the right REAL heading, not a stray code-comment.

    CommonMark requires a fence to be closed by the SAME delimiter character that opened it (a
    ``` block is not closed by ~~~, and vice versa) — a column-0 line using the OTHER marker while
    a fence is open is ordinary fenced content, not a close. Track which marker opened the current
    fence so that case doesn't mis-toggle back to "outside" mid-block. (Closing-fence length
    matching, the other half of CommonMark's fence rule, is out of scope here — no known call site
    depends on it.)"""
    mask = [False] * len(lines)
    open_marker = None
    for i, ln in enumerate(lines):
        m = FENCE.match(ln)
        if m:
            marker = m.group(1)
            if open_marker is None:
                open_marker = marker
            elif marker == open_marker:
                open_marker = None
        mask[i] = open_marker is not None
    return mask

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
    exempt_sections attributes a forbid match to the right REAL heading, not a stray code-comment."""
    mask = [False] * len(lines)
    in_fence = False
    for i, ln in enumerate(lines):
        if FENCE.match(ln):
            in_fence = not in_fence
        mask[i] = in_fence
    return mask

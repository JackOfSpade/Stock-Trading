"""Shared markdown fenced-code-block line-mask.

scripts/check_prose_invariants.py, scripts/split_task_plan.py, and scripts/split_strategy.py each
independently tracked "is this line inside a ``` / ~~~ fence" — check_prose_invariants.py's own
fence_mask() docstring literally cited the other two scripts' logic instead of importing it.
Consolidated here so a future fence-handling fix (e.g. supporting indented fences) lands in one
place instead of three (2026-07-18 audit finding, cluster "dedup-sweep").
"""
import re

# Column-0 ``` / ~~~ markers, capturing the FULL run length and the info string, which the
# depth-stack in fence_mask() needs in order to tell an opener from a closer (codebase audit
# 2026-07-26). \r belongs in the trailing class, not in the info-string capture: on CRLF input a
# captured "\r" is a truthy info string, so every bare closer would open a fence instead of
# closing one and no fence would ever close.
#
# This is the ONLY fence-marker regex in this module. A second, weaker one (`FENCE`, `^(```|~~~)`,
# no run-length and no info-string capture) sat beside it with no production consumer at all --
# every importer (split_task_plan.py, split_strategy.py, routine_manifest.py, check_routine_scope.py,
# check_prose_invariants.py, check_roster_consistency.py) imports fence_mask only. Keeping two
# near-identical marker regexes side by side invited a future fence fix into the dead one, leaving
# the live parser (which uses THIS regex) untouched behind a green test.
FENCE_LINE = re.compile(r"^(`{3,}|~{3,})[ \t]*(.*?)[ \t\r]*$")


def fence_mask(lines):
    """Per-line bool: True where the line sits INSIDE a fenced code block (``` or ~~~ at column 0).
    A column-0 '#'/'##' inside a fence is a code comment, not a markdown heading — the same fence
    handling scripts/split_task_plan.py / split_strategy.py already use. Used by nearest_heading so
    exempt_sections attributes a forbid match to the right REAL heading, not a stray code-comment.

    Implemented as a DEPTH STACK rather than a single open/closed flag (codebase audit 2026-07-26).
    Three CommonMark rules decide whether a marker line opens, closes, or is just content:
      * a fence closes only on the SAME delimiter CHARACTER that opened it (a ``` block is not
        closed by ~~~, and vice versa);
      * a closing run must be AT LEAST as long as the opening run, so a bare ``` inside an open
        ```` block is content, not a close; and
      * a closing line carries NO info string — ```yaml can only ever OPEN a block.

    WHY A STACK. The previous flat flag toggled on any column-0 same-character marker, info string
    or not. That is wrong in both directions and this repo's own corpus hits it: Claude_Task_Plan.md
    nests a ```yaml d1_actions block inside an outer ``` fence (lines 491/613/618/622) without
    bumping the outer fence to four backticks. The flat flag read line 613's ```yaml as CLOSING the
    line-491 fence, so lines 614-617 were classified OUTSIDE a fence they are plainly inside. It
    happened to cause no damage only because those four lines carry no column-0 '#': had anyone
    added a '## ' example line there, split_task_plan.py would have treated it as a real routine
    heading, split the section early, and silently truncated the rest of that routine's slice —
    exactly the failure the split scripts' own docstrings say fence handling exists to prevent.

    The obvious "fix" — require a bare closer, and otherwise keep the flat flag — is far WORSE, and
    was measured before being rejected: it leaves the line-491 fence open for the rest of the file,
    collapsing Claude_Task_Plan.md's outside-of-fence heading count from 51 `## ` / 11 `# ` to
    20 / 5. Thirty-one real routine headings vanish, taking 31 slices with them.

    A stack resolves both, because this function only reports "inside ANY fence" (depth > 0), and
    depth is what nesting actually changes. On legal CommonMark the stack agrees with a strict
    parser line for line; on the corpus's technically-invalid equal-length nesting it also does the
    obviously-intended thing, since the inner block's own closer pops the level it pushed. Measured
    across all 83 markdown files in the repo, this changes exactly five lines — 613-617, the ones
    that were misclassified — and leaves every heading count identical, so the splitters' byte-for-
    byte `--check` guarantees are unaffected.

    One deliberate divergence remains: an info-string line while a same-character, EQUAL-LENGTH
    fence is open (the ```yaml-inside-``` case) PUSHES instead of being read as content. Strict
    CommonMark would call it content; the corpus means it as a nested block, and treating it as one
    is what keeps the heading counts right. It is scoped as narrowly as possible — a DIFFERENT
    delimiter character with an info string is still ordinary content (per the first rule above),
    and so is a DIFFERENT-LENGTH run.

    THE EQUAL-LENGTH CONDITION IS LOAD-BEARING (quality pass 2026-08-22). It previously read
    `stack[-1][0] == char` with no length test, which let an info-string marker of ANY length nest
    under an open same-character fence — and that silently broke the mask in both directions, each
    time by swallowing every heading to EOF:
      * ```` open, then ```yaml (shorter): the inner frame is pushed, the real ```` closer pops
        only that phantom inner frame, and the outer ('`', 4) stays open forever. This is exactly
        the LEGAL CommonMark way to display a ```yaml opener inside a documentation block, so the
        first doc to use it would have lost every subsequent routine heading.
      * ``` open, then ````yaml (longer): the pushed ('`', 4) frame can never be popped by the
        outer's own bare ``` closer (3 < 4), with the same swallow-to-EOF result.
    Requiring equal length collapses both to ordinary content, matching a strict parser, while the
    corpus's equal-length nesting (3 == 3) still pushes. Verified byte-identical: 0 mask diffs
    across all 101 markdown files in the repo, and Claude_Task_Plan.md's heading counts unchanged
    at 52 `## ` / 11 `# `. Both regressions are pinned by tests in tests/test_md_fence.py."""
    mask = [False] * len(lines)
    stack = []                                      # (delimiter char, run length) per open fence
    for i, ln in enumerate(lines):
        m = FENCE_LINE.match(ln)
        if m:
            run, info = m.group(1), m.group(2)
            char, length = run[0], len(run)
            if info:
                # Carries an info string -> can only OPEN. Nest it only under the SAME delimiter
                # character AND an equal run length; a ~~~lang line inside an open ``` block is
                # content, not a new block, and so is a run of a different length (see the
                # docstring's EQUAL-LENGTH paragraph — either mismatch strands the outer fence
                # open to EOF and swallows every heading after it).
                if not stack or (stack[-1][0] == char and length == stack[-1][1]):
                    stack.append((char, length))
            elif stack and stack[-1][0] == char and length >= stack[-1][1]:
                stack.pop()                         # valid closer: same char, long enough, bare
            elif not stack:
                stack.append((char, length))        # bare marker with nothing open -> opens
            # else: wrong char, or too short to close the current fence -> ordinary content
        mask[i] = bool(stack)
    return mask

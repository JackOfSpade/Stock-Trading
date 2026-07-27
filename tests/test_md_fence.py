"""Direct unit coverage for the shared lib scripts/lib/md_fence.py.

This module is the de-duplicated single implementation that scripts/check_prose_invariants.py,
scripts/split_task_plan.py, and scripts/split_strategy.py all import (2026-07-18 audit finding,
cluster "dedup-sweep") — its public surface (fence_mask) must stay byte-stable since all three
call sites, and their respective `--check` byte-identical-output guarantees, depend on identical
per-line fence classification. It was previously only ever exercised TRANSITIVELY (via
tests/test_check_prose_invariants.py's cpi.fence_mask, and the split scripts' fence-straddling
fixtures); these pin the contract directly so an interface-preserving refactor of the lib has a
first-class guard.

CODEBASE AUDIT 2026-07-26 — fence_mask() is a DEPTH STACK; do not flatten it back to one flag.
The original implementation tracked a single open/closed flag and toggled it on any column-0 line
starting with the open fence's delimiter character, info string or not. That is wrong in both
directions, and this repo's corpus hits it: Claude_Task_Plan.md nests a ```yaml d1_actions block
inside an outer ``` fence (lines 491/613/618/622) without bumping the outer fence to four
backticks, so the flat flag read line 613's ```yaml as CLOSING the line-491 fence and reported
lines 614-617 as OUTSIDE a fence they are plainly inside.

Two "fixes" were considered. Requiring a BARE closing line while keeping the flat flag is the
obvious one and is CATASTROPHIC — measured against this file, outside-of-fence heading counts
collapse from 52 `## ` / 11 `# ` to 20 / 5, because the line-491 fence then never closes and eats
31 real routine headings (and with them 31 slices, plus gen_routine_lists.py and the cadence gate
downstream). The stack is the actual fix: since this function only reports "inside ANY fence"
(depth > 0), nesting collapses to depth, so it satisfies CommonMark's delimiter/length/info-string
rules AND the corpus's technically-invalid equal-length nesting at the same time. Measured across
all 83 markdown files it changed exactly the five previously-misclassified lines and left every
heading count identical.

So: the counts pinned below are NOT a fingerprint of the old permissive rule — both the old flat
flag and the current stack produce them. A sharp drop toward 20/5 means someone reintroduced the
strict-bare-closer-plus-flat-flag combination. Before touching the toggle logic at all, run
`python scripts/split_task_plan.py --check` and re-derive these counts.
"""
import pathlib

from lib.md_fence import FENCE, fence_mask

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
TASK_PLAN_PATH = REPO_ROOT / "Claude_Task_Plan.md"


# ---- FENCE: the ``` / ~~~ column-0 marker regex -------------------------------------------------
def test_fence_regex_matches_backtick_and_tilde_markers_at_column_zero():
    assert FENCE.match("```")
    assert FENCE.match("```python")
    assert FENCE.match("~~~")
    assert not FENCE.match("  ```")   # not at column 0
    assert not FENCE.match("text ``` mid-line")


# ---- fence_mask(): per-line inside/outside classification ---------------------------------------
def test_fence_mask_marks_lines_inside_a_fence():
    lines = ["## Heading", "```", "# fake", "```", "after"]
    assert fence_mask(lines) == [False, True, True, False, False]


def test_fence_mask_supports_tilde_fences():
    lines = ["intro", "~~~", "inside", "~~~", "outside"]
    assert fence_mask(lines) == [False, True, True, False, False]


def test_fence_mask_unterminated_fence_stays_open_to_end_of_file():
    lines = ["before", "```", "inside 1", "inside 2"]
    assert fence_mask(lines) == [False, True, True, True]


def test_fence_mask_empty_lines_list_returns_empty_list():
    assert fence_mask([]) == []


def test_fence_mask_no_fences_is_all_false():
    lines = ["plain", "text", "no fences here"]
    assert fence_mask(lines) == [False, False, False]


def test_fence_mask_adjacent_fences_toggle_independently():
    # Two back-to-back fenced blocks: the mask must re-open after closing, not stay closed forever.
    lines = ["```", "a", "```", "```", "b", "```", "after"]
    assert fence_mask(lines) == [True, True, False, True, True, False, False]


def test_fence_mask_tilde_inside_backtick_fence_is_content_not_a_close():
    # CommonMark: a fence is closed only by the SAME delimiter that opened it. A column-0 ~~~
    # line while a ``` fence is open is fence-internal content, not a close.
    lines = ["x", "```", "code line 1", "~~~", "still code?", "```", "after"]
    assert fence_mask(lines) == [False, True, True, True, True, False, False]


def test_fence_mask_backtick_inside_tilde_fence_is_content_not_a_close():
    # The mirror case: a column-0 ``` line while a ~~~ fence is open must not close it either.
    lines = ["x", "~~~", "code line 1", "```", "still code?", "~~~", "after"]
    assert fence_mask(lines) == [False, True, True, True, True, False, False]


# ---- nesting: an info-string marker OPENS, it never closes -------------------------------------
def test_fence_mask_info_string_marker_nests_instead_of_closing():
    """The corpus shape: a ```yaml block nested inside an outer ``` block (codebase audit
    2026-07-26). A line carrying an info string can only OPEN — CommonMark closers carry none — so
    the outer fence must stay open across the whole inner block, and everything between the two
    outer markers is inside a fence.

    The flat open/closed flag this replaced read the ```yaml line as CLOSING the outer fence, so
    the inner block's body came back as OUTSIDE any fence. That is how a '## ' example line inside
    such a block would have been mistaken for a real routine heading by split_task_plan.py."""
    lines = ["outside", "```", "inside 1", "```yaml some-info-string", "inside 2", "```", "```", "after"]
    #          F         T      T           T (nests, does not close)   T          T (pops inner)
    #                                                                              F (pops outer)
    assert fence_mask(lines) == [False, True, True, True, True, True, False, False]


def test_fence_mask_longer_outer_fence_nests_legally_per_commonmark():
    """The VALID way to write the case above: a four-backtick outer fence around a three-backtick
    inner one. Must behave identically to the equal-length corpus shape (codebase audit
    2026-07-26)."""
    lines = ["````", "```yaml", "x", "```", "````", "after"]
    assert fence_mask(lines) == [True, True, True, True, False, False]


def test_fence_mask_short_bare_marker_cannot_close_a_longer_fence():
    """CommonMark's closing-run-length rule: a bare ``` inside an open ```` block is content, not a
    close — that is the whole point of opening with a longer run. The flat flag closed on it, then
    treated the real ```` closer as a fresh opener, inverting the mask for everything after
    (codebase audit 2026-07-26)."""
    lines = ["````", "```", "x", "````", "after"]
    assert fence_mask(lines) == [True, True, True, False, False]


def test_fence_mask_info_string_with_the_other_delimiter_is_content():
    """The divergence stays narrow: nesting on an info-string line applies only to the SAME
    delimiter character. A ~~~lang line while a ``` fence is open is ordinary content, exactly as
    the bare-~~~ case already is (codebase audit 2026-07-26)."""
    lines = ["```", "~~~yaml", "x", "```", "after"]
    assert fence_mask(lines) == [True, True, True, False, False]


# ---- corpus-level regression pin: real routine headings must stay outside fences ----------------
def test_claude_task_plan_corpus_heading_counts():
    """Pin fence_mask()'s classification of Claude_Task_Plan.md's real routine headings.

    codebase audit 2026-07-26: a strict-CommonMark bare-closer fix layered onto the old flat
    open/closed flag was measured against this exact file and collapses the outside-of-fence
    heading counts from 52 `## ` / 11 `# ` down to 20 / 5 — 32 routine headings silently swallowed
    into a phantom never-closed fence, which would cascade into split_task_plan.py dropping 31
    routine slices and poisoning gen_routine_lists.py and the cadence gate downstream. The
    depth-stack fence_mask() now in place satisfies CommonMark's rules WITHOUT that collapse (see
    module docstring), and reproduces these counts exactly.

    If this test fails:
      - If the counts DROPPED sharply (toward ~20/~5) and nobody intentionally restructured the
        file's fences: this is the regression above — someone has reintroduced a flat open/closed
        flag in place of the depth stack; revert whatever touched it.
      - If the counts changed by a small amount that matches routine headings you (or another
        session) deliberately added/removed/renamed in Claude_Task_Plan.md in this same change:
        that is a legitimate content edit — update the hard-coded expected counts below to match,
        with a comment noting which routine(s) changed.
    A large drop is the fingerprint of a fence-parsing regression; a small, explainable delta that
    tracks a real edit to the .md is not.
    """
    lines = TASK_PLAN_PATH.read_text().splitlines()
    mask = fence_mask(lines)
    h2_headings = sum(1 for i, ln in enumerate(lines) if ln.startswith("## ") and not mask[i])
    h1_headings = sum(
        1 for i, ln in enumerate(lines) if ln.startswith("# ") and not ln.startswith("## ") and not mask[i]
    )
    # Derived 2026-07-26 against the current Claude_Task_Plan.md (see docstring above for how to
    # tell a legitimate content edit from a fence-parsing regression if this ever fails).
    # 52 as of 2026-07-27: +1 for the new `## OPS2.` (Catch-up Executor) routine heading.
    assert h2_headings == 52
    assert h1_headings == 11

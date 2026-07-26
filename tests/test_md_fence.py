"""Direct unit coverage for the shared lib scripts/lib/md_fence.py.

This module is the de-duplicated single implementation that scripts/check_prose_invariants.py,
scripts/split_task_plan.py, and scripts/split_strategy.py all import (2026-07-18 audit finding,
cluster "dedup-sweep") — its public surface (fence_mask) must stay byte-stable since all three
call sites, and their respective `--check` byte-identical-output guarantees, depend on identical
per-line fence classification. It was previously only ever exercised TRANSITIVELY (via
tests/test_check_prose_invariants.py's cpi.fence_mask, and the split scripts' fence-straddling
fixtures); these pin the contract directly so an interface-preserving refactor of the lib has a
first-class guard.

CODEBASE AUDIT 2026-07-26 — do NOT "fix" fence_mask() to require a bare closing marker.
An audit pass claimed fence_mask()'s "any column-0 marker-with-same-character toggles the fence,
even one carrying an info string like ```yaml" is a CommonMark bug, and proposed requiring a BARE
closing line (no info string) to close a fence. The orchestrator measured that exact "fix" against
this repo's real corpus and it is a catastrophic regression: Claude_Task_Plan.md currently yields
51 `## ` headings and 11 `# ` headings outside fences under the CURRENT permissive mask; under the
strict-bare-closer fix it yields 20 and 5 — 31 real routine headings get swallowed into a phantom
never-closed fence. Root cause: Claude_Task_Plan.md legitimately nests a ```yaml d1_actions``` fence
inside an outer ``` fence (around lines 491/613/618/622 — the outer fence opens at line 491 and the
document's author never bumped it to 4 backticks around the inner ```yaml block, so it is not valid
CommonMark). The CURRENT permissive rule ("any column-0 same-marker line toggles, info string or
not") recovers correct heading parity by the next real marker; strict CommonMark instead keeps the
line-491 fence open for the rest of the file and eats every heading after it. The current behavior
is therefore load-bearing and CORRECT FOR THIS CORPUS, not a bug — this file pins it so a future
session doesn't "correct" it back into the outage. Before touching fence_mask()'s toggle logic,
run `python scripts/split_task_plan.py --check` and re-derive the heading counts below; if they
still don't match, the .md changed (see the corpus test's own failure-message diagnosis), not the
fence logic.
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


# ---- deliberate non-CommonMark divergence: marker-with-info-string closes an open fence ---------
def test_fence_mask_marker_with_info_string_closes_an_open_fence_deliberately_non_commonmark():
    """DELIBERATE divergence from CommonMark — codebase audit 2026-07-26.

    CommonMark says a fence is closed only by a BARE closing-marker line (no info string); a line
    like ```yaml while a ``` fence is already open would, under strict CommonMark, be ordinary
    fenced content (you can't "re-open" what's already open) and the original fence would stay
    open. fence_mask() instead treats ANY column-0 line starting with the open fence's marker
    character as a toggle, info string or not — so it closes the outer fence right there.

    This is intentional, not an oversight: Claude_Task_Plan.md nests a ```yaml d1_actions``` fence
    inside an outer ``` fence (lines 491/613/618/622) without bumping the outer fence to 4
    backticks, which is not valid CommonMark. The permissive toggle-on-any-marker rule recovers
    correct heading parity at the next real marker; a strict bare-closer "fix" was measured on
    2026-07-26 to keep the line-491 fence open through the rest of the file, dropping 31 of the
    file's 51 `## ` routine headings (see test_claude_task_plan_corpus_heading_counts below and
    the module docstring). Anyone tempted to require a bare closer here MUST re-run
    `python scripts/split_task_plan.py --check` and the corpus heading-count test first.
    """
    lines = ["outside", "```", "inside 1", "```yaml some-info-string", "inside 2", "```", "after"]
    # The info-string line at index 3 CLOSES the fence opened at index 1 (permissive toggle);
    # "inside 2" is then classified OUTSIDE, and the ``` at index 5 opens a fresh, unterminated
    # fence that (per the "unterminated fence stays open to end of file" contract) swallows "after".
    assert fence_mask(lines) == [False, True, True, False, False, True, True]


# ---- corpus-level regression pin: real routine headings must stay outside fences ----------------
def test_claude_task_plan_corpus_heading_counts():
    """Pin fence_mask()'s classification of Claude_Task_Plan.md's real routine headings.

    codebase audit 2026-07-26: an auditor proposed a strict-CommonMark bare-closer fix to
    fence_mask() (see module docstring and the synthetic test above) that, measured against this
    exact file, collapses the outside-of-fence heading counts from 51 `## ` / 11 `# ` down to
    20 / 5 — 31 routine headings silently swallowed into a phantom never-closed fence, which would
    cascade into split_task_plan.py dropping 31 routine slices and poisoning gen_routine_lists.py
    and the cadence gate downstream.

    If this test fails:
      - If the counts DROPPED sharply (toward ~20/~5) and nobody intentionally restructured the
        file's fences: this is the regression above — do NOT change fence_mask()'s toggle logic;
        revert whatever touched it.
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
    assert h2_headings == 51
    assert h1_headings == 11

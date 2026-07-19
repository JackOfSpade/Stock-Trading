"""Direct unit coverage for the shared lib scripts/lib/md_fence.py.

This module is the de-duplicated single implementation that scripts/check_prose_invariants.py,
scripts/split_task_plan.py, and scripts/split_strategy.py all import (2026-07-18 audit finding,
cluster "dedup-sweep") — its public surface (fence_mask) must stay byte-stable since all three
call sites, and their respective `--check` byte-identical-output guarantees, depend on identical
per-line fence classification. It was previously only ever exercised TRANSITIVELY (via
tests/test_check_prose_invariants.py's cpi.fence_mask, and the split scripts' fence-straddling
fixtures); these pin the contract directly so an interface-preserving refactor of the lib has a
first-class guard.
"""
from scripts.lib.md_fence import FENCE, fence_mask


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

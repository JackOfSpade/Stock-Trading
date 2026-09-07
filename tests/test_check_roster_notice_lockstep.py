"""Guard scripts/check_roster_notice_lockstep.py — the four-place SISA roster-notice category checker.

The checker itself exists because ops/monitoring/alert_emailer.gs has carried an unenforced comment
since 2026-08-04 ("Keep this list in lockstep ... A category in only one of the three places is
inert"), and 2026-09-07 added a fourth copy — scripts/alert_relay.py's NO_PUSH_CATEGORIES, the ntfy
suppression list — whose failure mode is a category being SILENTLY never pushed to the phone.

What these tests are really for: a lockstep checker is exactly the kind of guard that can rot into a
permanent no-op. If any one of its four extractors stops matching (a reformatted array, a renamed
constant, a superseding SQL file that words Rule 5 differently), a naive implementation would return
an empty set — and an empty set compares EQUAL to another empty set, so the checker would pass while
verifying nothing. So the extraction-failure tests below matter more than the happy path: they pin
that a broken anchor is a loud FAILURE, never a vacuous pass. Same rule alert-relay.yml's own cron
self-check states for itself ("fail loud instead of letting it pass vacuously").

Convention matches the other tests/test_check_*.py files: synthetic inputs built inline, plus one
"the real repo agrees" test.
"""
import pytest

from conftest import load_module_from_path

cs = load_module_from_path("check_roster_notice_lockstep", "scripts", "check_roster_notice_lockstep.py")

SIX = {
    "strategy_shadow_registered",
    "strategy_probe_registered",
    "strategy_graduated",
    "retirement_proposed",
    "strategy_deregistered",
    "roster_below_floor",
}


# ---- each extractor finds the six on realistic input -----------------------------------------

def test_extract_py_tuple():
    src = (
        "WEBHOOK_URL = os.environ.get('WEBHOOK_URL', '').strip()\n"
        "NO_PUSH_CATEGORIES = (\n"
        "    'strategy_shadow_registered',   # SL5\n"
        "    'strategy_probe_registered',    # SL5\n"
        "    'strategy_graduated',           # M4\n"
        "    'retirement_proposed',          # SL4\n"
        "    'strategy_deregistered',        # SL5\n"
        "    'roster_below_floor',           # SL1\n"
        ")\n"
    )
    assert cs._extract_py_tuple(src) == SIX


def test_extract_gs_array():
    src = (
        "const ROSTER_NOTICE_CATEGORIES = [\n"
        "  'strategy_shadow_registered',\n  'strategy_probe_registered',\n  'strategy_graduated',\n"
        "  'retirement_proposed',\n  'strategy_deregistered',\n  'roster_below_floor'\n];\n"
    )
    assert cs._extract_gs_array(src) == SIX


def test_extract_sql_rule5_skips_unrelated_category_in_lists():
    # sp_auto_resolve_alerts contains several other `category IN (...)` / `category = '...'` tests.
    # Matching the FIRST one would compare an unrelated list and then pass or fail for entirely the
    # wrong reason — a false green being the dangerous direction. The extractor anchors on the two
    # categories that appear only in the roster list.
    src = (
        "WHERE NOT resolved AND category IN ('staleness', 'missed_run')\n"
        "...\n"
        "AND category IN ('strategy_shadow_registered', 'strategy_probe_registered', 'strategy_graduated',\n"
        "                 'retirement_proposed', 'strategy_deregistered', 'roster_below_floor')\n"
    )
    assert cs._extract_sql_rule5(src) == SIX


def test_extract_task_plan():
    src = (
        "- **ROSTER-CHANGE NOTICES (owner directive 2026-08-04).** blah blah. These six categories — "
        "`strategy_shadow_registered`, `strategy_probe_registered`, `strategy_graduated`, "
        "`retirement_proposed`, `strategy_deregistered`, `roster_below_floor` — are raised at "
        "**`warning`**, never `info`."
    )
    assert cs._extract_task_plan(src) == SIX


# ---- a broken anchor must FAIL, never return an empty set ------------------------------------

@pytest.mark.parametrize("fn", [
    "_extract_py_tuple", "_extract_gs_array", "_extract_sql_rule5", "_extract_task_plan",
])
def test_missing_anchor_raises_rather_than_returning_empty(fn):
    with pytest.raises(ValueError):
        getattr(cs, fn)("nothing resembling the expected structure here")


def test_sql_extractor_rejects_a_category_list_that_is_not_the_roster_one():
    # A `category IN (...)` that exists but is the WRONG list must raise, not silently return it.
    with pytest.raises(ValueError):
        cs._extract_sql_rule5("WHERE category IN ('staleness', 'missed_run', 'routine_stalled')")


# ---- the real repo agrees ---------------------------------------------------------------------

def test_real_repo_all_four_sources_agree():
    assert cs.main() == 0


def test_real_repo_uses_the_apply_in_order_winner_for_rule5():
    # Rule 5's home has moved repeatedly (34 -> 78 -> 94 -> 97 -> 107 -> 130 -> 134 -> 148). The
    # checker resolves the highest-numbered file defining ops.sp_auto_resolve_alerts rather than
    # hardcoding one, so it cannot silently start checking a superseded definition.
    name, text = cs._sql_canonical_rule5()
    assert name.endswith(".sql")
    assert "PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`" in text
    assert cs._extract_sql_rule5(text) == SIX

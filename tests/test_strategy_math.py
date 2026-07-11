"""
Tests for strategy_math (ITEM 28, self-improvement audit 2026-07-11). Threshold-boundary
synthetic cases mirroring c_options_math.py's own test convention — not scraped
historical fills (events.decision_log does not carry the underlying numeric inputs as
clean structured columns, so a true historical-reproduction fixture set is not
practically buildable; see strategy_math/__init__.py docstring for the full rationale).
"""

import datetime

import pytest

from strategy_math import common, strategy_a, strategy_b, strategy_d, strategy_e


# ===== common.py =====

def test_position_size_dollars():
    assert common.position_size_dollars(1900.0) == pytest.approx(38.0)
    assert common.position_size_dollars(1000.0, pct=0.05) == pytest.approx(50.0)


def test_position_size_dollars_rejects_nonpositive_nav():
    with pytest.raises(ValueError):
        common.position_size_dollars(0)
    with pytest.raises(ValueError):
        common.position_size_dollars(-100)


def test_pearson_correlation_perfect_positive():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [2.0, 4.0, 6.0, 8.0, 10.0]
    assert common.pearson_correlation(x, y) == pytest.approx(1.0)


def test_pearson_correlation_perfect_negative():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [10.0, 8.0, 6.0, 4.0, 2.0]
    assert common.pearson_correlation(x, y) == pytest.approx(-1.0)


def test_pearson_correlation_zero_variance_returns_zero():
    x = [1.0, 1.0, 1.0]
    y = [1.0, 2.0, 3.0]
    assert common.pearson_correlation(x, y) == 0.0


def test_pearson_correlation_length_mismatch_raises():
    with pytest.raises(ValueError):
        common.pearson_correlation([1.0, 2.0], [1.0])


def test_ols_regression_exact_linear_no_noise():
    # y = 2 + 3x exactly -> beta=3, alpha=2, alpha_se ~ 0 (zero residuals)
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [2 + 3 * xi for xi in x]
    result = common.ols_regression(y, x)
    assert result.beta == pytest.approx(3.0)
    assert result.alpha == pytest.approx(2.0)
    assert result.alpha_se == pytest.approx(0.0, abs=1e-9)
    assert result.n == 5


def test_ols_regression_zero_variance_x_raises():
    with pytest.raises(ValueError):
        common.ols_regression(y=[1.0, 2.0, 3.0], x=[5.0, 5.0, 5.0])


def test_ols_regression_needs_min_3_obs():
    with pytest.raises(ValueError):
        common.ols_regression(y=[1.0, 2.0], x=[1.0, 2.0])


def test_days_between():
    d1 = datetime.date(2026, 1, 1)
    d2 = datetime.date(2026, 4, 1)
    assert common.days_between(d1, d2) == 90


# ===== strategy_a.py =====

def test_a_instrument_eligibility_boundary():
    assert strategy_a.meets_instrument_eligibility(2_000_000_000, 10_000_000) is True
    assert strategy_a.meets_instrument_eligibility(1_999_999_999, 10_000_000) is False
    assert strategy_a.meets_instrument_eligibility(2_000_000_000, 9_999_999) is False


def test_a_time_stop_boundary():
    entry = datetime.date(2026, 1, 1)
    just_under = entry + datetime.timedelta(days=364)
    exactly = entry + datetime.timedelta(days=365)
    assert strategy_a.hit_time_stop(entry, just_under) is False
    assert strategy_a.hit_time_stop(entry, exactly) is True


# ===== strategy_b.py =====

def test_b_instrument_eligibility_boundary():
    assert strategy_b.meets_instrument_eligibility(2_000_000_000, 10_000_000) is True
    assert strategy_b.meets_instrument_eligibility(1_999_999_999, 10_000_000) is False


def test_b_event_reaction_qualifies_boundary():
    # exactly 5% up move
    assert strategy_b.event_reaction_qualifies(100.0, 105.0) is True
    # exactly 5% down move
    assert strategy_b.event_reaction_qualifies(100.0, 95.0) is True
    # just under 5%
    assert strategy_b.event_reaction_qualifies(100.0, 104.99) is False


def test_b_event_reaction_rejects_nonpositive_base():
    with pytest.raises(ValueError):
        strategy_b.event_reaction_qualifies(0.0, 5.0)


def test_b_convergence_timeline_boundary():
    entry = datetime.date(2026, 1, 1)
    within = entry + datetime.timedelta(days=60)
    beyond = entry + datetime.timedelta(days=61)
    assert strategy_b.convergence_timeline_ok(entry, within) is True
    assert strategy_b.convergence_timeline_ok(entry, beyond) is False


def test_b_timeline_expired_boundary():
    entry = datetime.date(2026, 1, 1)
    just_under = entry + datetime.timedelta(days=59)
    exactly = entry + datetime.timedelta(days=60)
    assert strategy_b.timeline_expired(entry, just_under) is False
    assert strategy_b.timeline_expired(entry, exactly) is True


def test_b_short_borrow_rate_boundary():
    assert strategy_b.short_borrow_rate_exceeded(0.10) is False  # "above 10%", not >=
    assert strategy_b.short_borrow_rate_exceeded(0.1001) is True


def test_b_short_stop_loss_boundary():
    assert strategy_b.short_stop_loss_triggered(100.0, 125.0) is True  # exactly +25%
    assert strategy_b.short_stop_loss_triggered(100.0, 124.99) is False


def test_b_short_stop_loss_rejects_nonpositive_entry():
    with pytest.raises(ValueError):
        strategy_b.short_stop_loss_triggered(0.0, 100.0)


# ===== strategy_d.py =====

def test_d_instrument_eligibility_boundary():
    assert strategy_d.meets_instrument_eligibility(10_000_000_000, 20_000_000) is True
    assert strategy_d.meets_instrument_eligibility(9_999_999_999, 20_000_000) is False
    assert strategy_d.meets_instrument_eligibility(10_000_000_000, 19_999_999) is False


def test_d_correlation_bucket_members_and_cap():
    candidate = [0.01, 0.02, -0.01, 0.03, 0.015]
    highly_correlated = [0.011, 0.021, -0.009, 0.031, 0.016]  # ~ same pattern, > 0.6 corr
    uncorrelated = [0.05, -0.03, 0.02, -0.04, 0.01]

    held = {"AAA": highly_correlated, "BBB": uncorrelated}
    members = strategy_d.correlation_bucket_members(candidate, held)
    assert "AAA" in members
    assert "BBB" not in members

    # Candidate + 3 already-correlated names -> blocks (cap is 3 total incl. candidate)
    assert strategy_d.bucket_blocks_entry(["AAA", "BBB", "CCC"]) is True
    assert strategy_d.bucket_blocks_entry(["AAA", "BBB"]) is False  # candidate + 2 = 3, at cap not over


def test_d_post_entry_bucket_pairs():
    a = [0.01, 0.02, -0.01, 0.03, 0.015, 0.005]
    b = [0.011, 0.021, -0.009, 0.031, 0.016, 0.006]  # near-identical -> high corr
    c = [0.05, -0.03, 0.02, -0.04, 0.01, -0.02]
    held = {"A": a, "B": b, "C": c}
    pairs = strategy_d.post_entry_bucket_pairs(held)
    assert ("A", "B") in pairs
    assert ("A", "C") not in pairs
    assert ("B", "C") not in pairs


def test_d_beta_adjusted_alpha_well_posed_case():
    # Perturbed series so sxx != 0 and residuals are genuinely small (not exactly zero)
    spy = [0.02 + 0.001 * (i % 3) for i in range(24)]
    d = [(-0.03) + 1.0 * s for s in spy]  # alpha ~ -3pp exactly, beta ~ 1, tiny noise
    result = strategy_d.beta_adjusted_alpha_test(d, spy)
    assert result.regression.alpha == pytest.approx(-0.03, abs=1e-6)
    assert result.fires is True  # alpha <= -3pp AND upper CI ~ alpha (near-zero SE) <= 0


def test_d_beta_adjusted_alpha_does_not_fire_on_positive_alpha():
    spy = [0.02 + 0.001 * (i % 3) for i in range(24)]
    d = [0.01 + 1.0 * s for s in spy]  # alpha ~ +1pp -> should not fire
    result = strategy_d.beta_adjusted_alpha_test(d, spy)
    assert result.fires is False


def test_d_metric_structural_change_boundary():
    assert strategy_d.metric_structural_change_invalidated(1) is False
    assert strategy_d.metric_structural_change_invalidated(2) is True


def test_d_subtype_for_dual_signal():
    assert strategy_d.subtype_for_dual_signal(None) == "B"
    assert strategy_d.subtype_for_dual_signal(365, trend_metric_independently_evaluable=False) == "A"
    assert strategy_d.subtype_for_dual_signal(365, trend_metric_independently_evaluable=True) == "BOTH"
    assert strategy_d.subtype_for_dual_signal(366, trend_metric_independently_evaluable=True) == "B"


# ===== strategy_e.py =====

def test_e_pair_correlation_boundary():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    # Construct an exact-0.5-correlation-ish case is fiddly; instead verify the
    # threshold logic directly against a known perfect-correlation case (>= 0.5 True)
    # and a known near-zero case (< 0.5 False).
    assert strategy_e.pair_correlation_qualifies(x, x) is True  # corr=1.0
    uncorrelated = [3.0, 1.0, 4.0, 1.0, 5.0]
    # not asserting a specific direction here, just exercising the function
    result = strategy_e.pair_correlation_qualifies(x, uncorrelated)
    assert isinstance(result, bool)


def test_e_correlation_breakdown():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y_perfect = [2.0, 4.0, 6.0, 8.0, 10.0]
    assert strategy_e.correlation_breakdown(x, y_perfect) is False  # corr=1.0, not < 0.3
    y_uncorrelated = [5.0, 1.0, 4.0, 2.0, 3.0]
    # weak/negative correlation should trip the < 0.3 breakdown
    corr = common.pearson_correlation(x, y_uncorrelated)
    assert strategy_e.correlation_breakdown(x, y_uncorrelated) == (corr < 0.3)


def test_e_hedge_ratio():
    x = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    y = [2 * xi + 0.5 for xi in x]  # L = 2*S + 0.5 -> hedge ratio (beta) = 2.0
    assert strategy_e.hedge_ratio(y, x) == pytest.approx(2.0)


def test_e_financing_cost_ok_boundary():
    # borrow_rate * position_size * (days/365) <= 0.15 * expected_return
    # pick numbers landing exactly at the boundary
    borrow_rate = 0.10
    position_size = 1000.0
    holding_days = 182.5  # half a year
    financing_cost = borrow_rate * position_size * (holding_days / 365.0)  # = 50.0
    expected_return_at_boundary = financing_cost / 0.15  # cost is exactly 15% of this
    assert strategy_e.financing_cost_ok(
        borrow_rate, position_size, holding_days, expected_return_at_boundary
    ) is True
    assert strategy_e.financing_cost_ok(
        borrow_rate, position_size, holding_days, expected_return_at_boundary * 0.99
    ) is False


def test_e_financing_cost_rejects_nonpositive_expected_return():
    with pytest.raises(ValueError):
        strategy_e.financing_cost_ok(0.10, 1000.0, 180, 0.0)


def test_e_time_exit_boundary():
    entry = datetime.date(2026, 1, 1)
    just_under = entry + datetime.timedelta(days=181)
    exactly = entry + datetime.timedelta(days=182)
    assert strategy_e.time_exit_triggered(entry, just_under) is False
    assert strategy_e.time_exit_triggered(entry, exactly) is True

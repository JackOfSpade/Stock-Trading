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
    # Rev 39: pct is the thesis's risk budget and is REQUIRED — the old 0.02
    # default was removed so a forgetful caller cannot silently reinstate a flat 2%.
    assert common.position_size_dollars(1900.0, pct=0.02) == pytest.approx(38.0)
    assert common.position_size_dollars(1000.0, pct=0.05) == pytest.approx(50.0)
    # Thesis-scaled: the same NAV supports different budgets on different theses.
    assert common.position_size_dollars(1900.0, pct=0.01) == pytest.approx(19.0)
    assert common.position_size_dollars(1900.0, pct=0.10) == pytest.approx(190.0)


def test_position_size_dollars_requires_explicit_budget():
    """Rev 39: no default pct. Omitting it is a TypeError, not a silent 2%."""
    with pytest.raises(TypeError):
        common.position_size_dollars(1900.0)


def test_position_size_dollars_allows_any_budget_up_to_full_nav():
    """Owner directive 2026-08-05: both hard CaR envelopes RETIRED — no sizing ceiling.

    This test previously asserted the opposite (that pct>0.10 raised, under the Rev 43
    per-name 10% envelope). It is inverted deliberately, not deleted, so that
    reintroducing a numeric ceiling fails loudly here instead of silently narrowing
    sizing freedom the owner explicitly granted.
    """
    assert common.position_size_dollars(1900.0, pct=0.11) == pytest.approx(209.0)
    assert common.position_size_dollars(1900.0, pct=0.50) == pytest.approx(950.0)
    assert common.position_size_dollars(1900.0, pct=1.0) == pytest.approx(1900.0)


def test_position_size_dollars_still_rejects_out_of_domain_pct():
    """The (0, 1] bound is a domain sanity check, NOT a risk envelope — it stays."""
    with pytest.raises(ValueError):
        common.position_size_dollars(1900.0, pct=1.01)
    with pytest.raises(ValueError):
        common.position_size_dollars(1900.0, pct=0.0)
    with pytest.raises(ValueError):
        common.position_size_dollars(1900.0, pct=-0.05)


def test_position_size_dollars_rejects_nonpositive_nav():
    with pytest.raises(ValueError):
        common.position_size_dollars(0, pct=0.02)
    with pytest.raises(ValueError):
        common.position_size_dollars(-100, pct=0.02)


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


def test_pearson_correlation_too_few_observations_raises():
    # A separate guard from the length-mismatch check above: equal-length inputs that are still
    # too short (n < 2) to compute a correlation.
    with pytest.raises(ValueError):
        common.pearson_correlation([1.0], [1.0])


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


def test_ols_regression_alpha_se_nonzero_known_case():
    # Hand-computed: x=[0,1,2], y=[0,0,3] -> Sxx=2, beta=1.5, alpha=-0.5,
    # residuals=[0.5,-1.0,0.5], SSres=1.5, dof=1, s=sqrt(1.5);
    # alpha_se = s * sqrt(1/3 + 1/2) = sqrt(1.5 * 5/6) = sqrt(1.25) = 1.11803399
    result = common.ols_regression(y=[0.0, 0.0, 3.0], x=[0.0, 1.0, 2.0])
    assert result.beta == pytest.approx(1.5)
    assert result.alpha == pytest.approx(-0.5)
    assert result.alpha_se == pytest.approx(1.11803399, abs=1e-7)
    assert result.n == 3


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
    past = entry - datetime.timedelta(days=1)
    assert strategy_b.convergence_timeline_ok(entry, past) is False
    assert strategy_b.convergence_timeline_ok(entry, entry) is True


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


def test_d_concurrent_position_floor_boundary():
    # codebase audit 2026-07-26: MIN_CONCURRENT_POSITIONS was defined but had no
    # consuming predicate (unlike every sibling constant in this module) — this test
    # guards the floor's boundary (4 fails, 5 and 6 pass) now that
    # meets_concurrent_position_floor exists.
    assert strategy_d.meets_concurrent_position_floor(4) is False
    assert strategy_d.meets_concurrent_position_floor(5) is True
    assert strategy_d.meets_concurrent_position_floor(6) is True
    # zero open positions means D hasn't deployed yet — the floor's own text
    # ("minimum 5 when any are held") only binds once some exposure exists, so this
    # is vacuously floor-satisfied, not a violation.
    assert strategy_d.meets_concurrent_position_floor(0) is True


def test_d_correlation_bucket_members_monitoring_only():
    # Rev 35 (owner directive): the bucket-size cap and entry-blocking behavior were
    # removed — correlation_bucket_members is now monitoring/informational only
    # (Section 6), so this only asserts the membership arithmetic, not a cap.
    candidate = [0.01, 0.02, -0.01, 0.03, 0.015]
    highly_correlated = [0.011, 0.021, -0.009, 0.031, 0.016]  # ~ same pattern, > 0.6 corr
    uncorrelated = [0.05, -0.03, 0.02, -0.04, 0.01]

    held = {"AAA": highly_correlated, "BBB": uncorrelated}
    members = strategy_d.correlation_bucket_members(candidate, held)
    assert "AAA" in members
    assert "BBB" not in members


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


def test_d_beta_adjusted_alpha_ci_gate_blocks_a_noisy_point_estimate():
    # Regression guard (adversarial self-audit, rev 2026-07-11): the two tests above both use
    # near-zero-noise series, so alpha_se is always tiny there and `fires` tracks the point estimate
    # alone -- neither test can tell whether the CI-gate (upper_ci_95 <= 0) is doing anything beyond a
    # bare "alpha <= -3pp" check, which is the ENTIRE point of making this trigger CI-gated. This test
    # constructs a genuinely noisy series where the point estimate crosses -3pp but the confidence
    # interval is too wide to be statistically confident alpha is actually negative -- fires must be
    # False despite the point estimate alone "passing".
    n = 24
    spy = [0.01 * i - 0.1 for i in range(n)]
    d = [-0.05 + 1.0 * spy[i] + (0.20 if i % 2 == 0 else -0.20) for i in range(n)]
    result = strategy_d.beta_adjusted_alpha_test(d, spy)
    assert result.regression.alpha <= strategy_d.BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD, (
        "test fixture assumption broken: point estimate must cross -3pp for this test to be meaningful"
    )
    assert result.upper_ci_95 > 0, (
        "test fixture assumption broken: upper CI must be positive (statistically uncertain) for this "
        "test to actually exercise the CI-gate rather than the point-estimate check alone"
    )
    assert result.fires is False  # point estimate alone would fire; the CI-gate correctly blocks it


def test_d_beta_adjusted_alpha_upper_ci_uses_z_multiplier():
    # Pin the CI construction so a change to ALPHA_TEST_Z_95 (or the alpha/alpha_se wiring) is caught.
    spy = [0.02 + 0.001 * (i % 3) for i in range(24)]
    d = [(-0.03) + 1.0 * s for s in spy]
    result = strategy_d.beta_adjusted_alpha_test(d, spy)
    expected = result.regression.alpha + strategy_d.ALPHA_TEST_Z_95 * result.regression.alpha_se
    assert result.upper_ci_95 == pytest.approx(expected)
    assert strategy_d.ALPHA_TEST_Z_95 == pytest.approx(1.645)


def test_d_metric_structural_change_boundary():
    assert strategy_d.metric_structural_change_invalidated(1) is False
    assert strategy_d.metric_structural_change_invalidated(2) is True


def test_d_subtype_for_dual_signal():
    assert strategy_d.subtype_for_dual_signal(None) == "B"
    assert strategy_d.subtype_for_dual_signal(365, trend_metric_independently_evaluable=False) == "A"
    assert strategy_d.subtype_for_dual_signal(365, trend_metric_independently_evaluable=True) == "BOTH"
    assert strategy_d.subtype_for_dual_signal(366, trend_metric_independently_evaluable=True) == "B"


def test_d_subtype_for_dual_signal_requires_the_fact_when_it_matters():
    # Regression guard (adversarial self-audit, rev 2026-07-11): omitting
    # trend_metric_independently_evaluable must RAISE, not silently resolve to 'A', whenever the
    # catalyst is within the 365-day window (the one case where this fact actually changes the
    # outcome) — it used to default to False, indistinguishable from an explicit False.
    with pytest.raises(ValueError):
        strategy_d.subtype_for_dual_signal(365)
    with pytest.raises(ValueError):
        strategy_d.subtype_for_dual_signal(1)
    # Outside that window (or no catalyst at all), the fact is genuinely irrelevant — omitting it
    # must NOT raise, so a caller isn't burdened with a fact that doesn't change the outcome.
    assert strategy_d.subtype_for_dual_signal(None) == "B"
    assert strategy_d.subtype_for_dual_signal(366) == "B"


# ===== strategy_e.py =====

def test_e_pair_correlation_boundary():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    assert strategy_e.pair_correlation_qualifies(x, x) is True  # corr=1.0, well above threshold

    # Regression guard (adversarial self-audit, rev 2026-07-11): the two series below are
    # constructed (via Gram-Schmidt against x's own deviation vector, cos_theta=0.5 / 0.4999) to sit
    # RIGHT at the >= 0.5 entry threshold, not merely "clearly correlated" vs "clearly not" — this is
    # what actually exercises the boundary the >= comparison implements, unlike a perfect-correlation
    # case which would pass even with a bug that used > instead of >=.
    at_threshold = [2.163118, 1.154275, 3.815591, 5.253520, 2.613496]      # corr ~= 0.500000133
    just_under = [2.163329, 1.154285, 3.815645, 5.253537, 2.613203]       # corr ~= 0.499900002
    assert common.pearson_correlation(x, at_threshold) >= strategy_e.MIN_PAIR_CORRELATION_ENTRY, (
        "test fixture assumption broken: at_threshold must be >= 0.5 for this test to be meaningful"
    )
    assert common.pearson_correlation(x, just_under) < strategy_e.MIN_PAIR_CORRELATION_ENTRY, (
        "test fixture assumption broken: just_under must be < 0.5 for this test to be meaningful"
    )
    assert strategy_e.pair_correlation_qualifies(x, at_threshold) is True
    assert strategy_e.pair_correlation_qualifies(x, just_under) is False


def test_e_correlation_breakdown():
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y_perfect = [2.0, 4.0, 6.0, 8.0, 10.0]
    assert strategy_e.correlation_breakdown(x, y_perfect) is False  # corr=1.0, not < 0.3
    y_uncorrelated = [5.0, 1.0, 4.0, 2.0, 3.0]
    # weak/negative correlation should trip the < 0.3 breakdown. Assert the OUTCOME plus the constant
    # itself rather than recomputing the implementation's own `corr < THRESHOLD` expression, which would
    # stay green for any threshold above -0.3 and so pin nothing.
    corr = common.pearson_correlation(x, y_uncorrelated)
    assert corr < 0.3  # fixture assumption
    assert strategy_e.correlation_breakdown(x, y_uncorrelated) is True
    assert strategy_e.CORRELATION_BREAKDOWN_THRESHOLD == pytest.approx(0.3)


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

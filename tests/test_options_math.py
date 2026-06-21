"""Regression suite for c_options_math.py — Strategy C's defined-risk engine.

WHY THIS EXISTS (read before deleting a test):
  Strategy.md flags a bug in this module as the experiment's *highest-leverage
  failure mode*: "A bug in the P&L scenario generator or max-loss check converts
  the entire defined-risk premise into an undefined-risk position while Claude
  believes the structure is bounded." The runtime dual-path verification clause
  (closed-form vs Monte-Carlo, agree within $1) is a safety net, but a *shared*
  bug across both paths defeats it. This suite is the missing guard: it pins the
  numbers so a future edit cannot silently break max-loss math and merge to main.

It mirrors and extends the module's own `__main__` self-test (16 checks) as
proper pytest cases, and adds edge cases (unbounded rejection, S=0 worst case,
multi-expiration rejection, IV non-convergence, sizing deferral).

Pure stdlib — no scipy/numpy. Runs in seconds with zero infra.
"""
import math
import random

import pytest

from c_options_math import (
    ATMOption, OptionInputs, OptionLeg, Structure, CONTRACT_MULTIPLIER,
    UnboundedMaxLossError, MaxLossDualPathDisagreement,
    price_bsm, greeks_bsm, implied_vol,
    long_call, long_put,
    debit_call_spread, debit_put_spread,
    credit_call_spread, credit_put_spread,
    iron_condor, long_call_butterfly, long_put_butterfly,
    verify_max_loss_dual_path, cascade_max_loss, size_position,
    realized_volatility_30d, probability_weighted_payoff,
)


# ---------------------------------------------------------------------------
# Pricing & Greeks
# ---------------------------------------------------------------------------
def test_optioninputs_alias_is_intact():
    # ATMOption is the documented backward-compat alias for OptionInputs; callers
    # and this suite still use the old name. Pin the alias so a rename can't quietly
    # break it.
    assert OptionInputs is ATMOption


def test_bsm_call_price_hull_textbook():
    # Hull: S=42, K=40, r=0.10, T=0.5, sigma=0.20 -> Call = 4.7594
    opt = ATMOption(42, 40, int(0.5 * 365), 0.10, 0.20, 'call')
    assert price_bsm(opt) == pytest.approx(4.7594, abs=0.01)


def test_put_call_parity():
    call = ATMOption(100, 100, 30, 0.045, 0.30, 'call')
    put = ATMOption(100, 100, 30, 0.045, 0.30, 'put')
    lhs = price_bsm(call) - price_bsm(put)
    rhs = 100 - 100 * math.exp(-0.045 * 30 / 365)
    assert lhs == pytest.approx(rhs, abs=1e-3)


def test_greek_signs_and_symmetry():
    call = ATMOption(100, 100, 30, 0.045, 0.30, 'call')
    put = ATMOption(100, 100, 30, 0.045, 0.30, 'put')
    gc, gp = greeks_bsm(call), greeks_bsm(put)
    assert 0 < gc['delta'] < 1
    assert -1 < gp['delta'] < 0
    assert gc['gamma'] > 0
    assert gc['gamma'] == pytest.approx(gp['gamma'], abs=1e-10)  # gamma is type-independent
    assert gc['theta'] < 0 and gp['theta'] < 0
    assert gc['vega'] > 0
    assert gc['vega'] == pytest.approx(gp['vega'], abs=1e-10)  # vega is type-independent


def test_implied_vol_round_trip():
    target = 0.35
    opt = ATMOption(100, 100, 30, 0.045, target, 'call')
    px = price_bsm(opt)
    solved = implied_vol(px, 100, 100, 30, 0.045, 'call')
    assert solved is not None
    assert solved == pytest.approx(target, abs=1e-4)


def test_implied_vol_returns_none_on_unsolvable():
    # A price below intrinsic / outside the no-arbitrage band has no IV solution.
    # The solver must return None rather than a bogus number that flows into sizing.
    deep_itm_below_intrinsic = 0.01
    assert implied_vol(deep_itm_below_intrinsic, 200, 100, 30, 0.045, 'call') is None


# ---------------------------------------------------------------------------
# Structure max-loss — the safety-critical path
# ---------------------------------------------------------------------------
def test_long_call_max_loss_equals_debit():
    lc = long_call(100, strike=100, days_to_expiration=30,
                   risk_free_rate=0.045, volatility=0.30, contracts=1)
    assert lc.net_debit() == pytest.approx(lc.max_loss_closed_form(), abs=0.01)


def test_debit_call_spread_max_loss_and_max_profit():
    dcs = debit_call_spread(100, long_strike=100, short_strike=105,
                            days_to_expiration=30, risk_free_rate=0.045,
                            volatility_long=0.30, volatility_short=0.28, contracts=1)
    debit = dcs.net_debit()
    assert debit == pytest.approx(dcs.max_loss_closed_form(), abs=0.01)
    # Max profit at/above the short strike = width*100 - debit
    assert dcs.pnl_at_expiration(110) == pytest.approx(5 * CONTRACT_MULTIPLIER - debit, abs=0.01)


def test_iron_condor_max_loss_closed_form():
    ic = iron_condor(100, long_put_strike=90, short_put_strike=95,
                     short_call_strike=105, long_call_strike=110,
                     days_to_expiration=30, risk_free_rate=0.045,
                     vol_long_put=0.30, vol_short_put=0.30,
                     vol_short_call=0.30, vol_long_call=0.30, contracts=1)
    credit = -ic.net_debit()
    assert ic.max_loss_closed_form() == pytest.approx(5 * CONTRACT_MULTIPLIER - credit, abs=0.01)


@pytest.mark.parametrize("builder,kwargs", [
    (long_call, dict(strike=100, days_to_expiration=30, risk_free_rate=0.045, volatility=0.30, contracts=1)),
    (long_put, dict(strike=100, days_to_expiration=30, risk_free_rate=0.045, volatility=0.30, contracts=1)),
    (debit_call_spread, dict(long_strike=100, short_strike=105, days_to_expiration=30, risk_free_rate=0.045, volatility_long=0.30, volatility_short=0.28, contracts=1)),
    (debit_put_spread, dict(long_strike=100, short_strike=95, days_to_expiration=30, risk_free_rate=0.045, volatility_long=0.30, volatility_short=0.28, contracts=1)),
    (credit_call_spread, dict(short_strike=105, long_strike=110, days_to_expiration=30, risk_free_rate=0.045, volatility_short=0.30, volatility_long=0.30, contracts=1)),
    (credit_put_spread, dict(short_strike=95, long_strike=90, days_to_expiration=30, risk_free_rate=0.045, volatility_short=0.30, volatility_long=0.30, contracts=1)),
    (long_call_butterfly, dict(lower_strike=95, middle_strike=100, upper_strike=105, days_to_expiration=30, risk_free_rate=0.045, vol_lower=0.30, vol_middle=0.30, vol_upper=0.30, contracts=1)),
    (long_put_butterfly, dict(lower_strike=95, middle_strike=100, upper_strike=105, days_to_expiration=30, risk_free_rate=0.045, vol_lower=0.30, vol_middle=0.30, vol_upper=0.30, contracts=1)),
])
def test_bounded_structures_dual_path_agree(builder, kwargs):
    """Every bounded structure's two independent max-loss paths must agree within $1.
    This is the runtime safety clause; if it ever fails in CI, the engine is unsafe."""
    struct = builder(100, **kwargs)
    cf = struct.max_loss_closed_form()
    mc = struct.max_loss_monte_carlo(n_paths=50000)
    verify_max_loss_dual_path(cf, mc, tolerance=1.00)  # raises MaxLossDualPathDisagreement if off


def test_naked_short_put_captures_s0_worst_case():
    naked_put = Structure(
        legs=[OptionLeg(option=ATMOption(100, 95, 30, 0.045, 0.30, 'put'), quantity=-1)],
        name='Naked short put', structure_type='naked_put')
    cf = naked_put.max_loss_closed_form()
    expected = 95 * CONTRACT_MULTIPLIER - (-naked_put.net_debit())
    assert cf == pytest.approx(expected, abs=0.01)
    verify_max_loss_dual_path(cf, naked_put.max_loss_monte_carlo(n_paths=50000), tolerance=1.00)


# ---------------------------------------------------------------------------
# Refusals — the whole point of UnboundedMaxLossError is to NOT return a number
# ---------------------------------------------------------------------------
@pytest.mark.parametrize("legs,name", [
    ([OptionLeg(option=ATMOption(100, 105, 30, 0.045, 0.30, 'call'), quantity=-1)], 'naked_call'),
    ([OptionLeg(option=ATMOption(100, 100, 30, 0.045, 0.30, 'call'), quantity=1),
      OptionLeg(option=ATMOption(100, 110, 30, 0.045, 0.30, 'call'), quantity=-2)], 'ratio_call_spread'),
])
@pytest.mark.parametrize("method", ['max_loss_closed_form', 'max_loss_monte_carlo'])
def test_net_short_call_rejected_by_both_paths(legs, name, method):
    """Net-short-call structures have unbounded upside loss. BOTH max-loss paths
    must raise rather than return a finite, silently understated number into sizing."""
    struct = Structure(legs=legs, name=name, structure_type=name)
    with pytest.raises(UnboundedMaxLossError):
        getattr(struct, method)()


def test_multi_expiration_rejected():
    legs = [
        OptionLeg(option=ATMOption(100, 100, 30, 0.045, 0.30, 'call'), quantity=1),
        OptionLeg(option=ATMOption(100, 100, 60, 0.045, 0.30, 'call'), quantity=-1),
    ]
    with pytest.raises(NotImplementedError):
        Structure(legs=legs, name='Calendar', structure_type='calendar')


def test_dual_path_disagreement_raises():
    with pytest.raises(MaxLossDualPathDisagreement):
        verify_max_loss_dual_path(100.0, 105.0, tolerance=1.00)


# ---------------------------------------------------------------------------
# Cascade, sizing, realized vol, payoff
# ---------------------------------------------------------------------------
def test_cascade_max_loss_is_finite_for_credit_put_spread():
    cps = credit_put_spread(100, short_strike=95, long_strike=90,
                            days_to_expiration=30, risk_free_rate=0.045,
                            volatility_short=0.30, volatility_long=0.30, contracts=1)
    cascade = cascade_max_loss(cps, 100, 30, implied_move_full_horizon=0.05)
    assert math.isfinite(cascade) and cascade >= 0


def test_size_position_defers_when_no_integer_fits():
    contracts, defer = size_position(50.0, 1389.37, 0.02)  # 2% of 1389 = ~27.8 < 50
    assert contracts == 0 and defer is True


def test_size_position_fits_one_contract():
    contracts, defer = size_position(20.0, 1389.37, 0.02)
    assert contracts == 1 and defer is False


def test_size_position_rejects_zero_max_loss():
    with pytest.raises(ValueError):
        size_position(0, 1389.37, 0.02)


def test_realized_vol_recovers_known_sigma():
    rng = random.Random(42)
    prices = [100.0]
    sigma_annual = 0.30
    daily_vol = sigma_annual / math.sqrt(252)
    for _ in range(200):
        z = rng.gauss(0, 1)
        prices.append(prices[-1] * math.exp(-0.5 * daily_vol ** 2 + daily_vol * z))
    rv = realized_volatility_30d(prices)
    assert rv == pytest.approx(sigma_annual, abs=0.10)


def test_realized_vol_rejects_too_few_prices():
    # A sample variance (ddof=1) needs >= 2 log returns, i.e. >= 3 prices. With
    # exactly 2 prices the old guard let one return through and divided by (n-1)=0,
    # raising an opaque ZeroDivisionError. It must raise a clear ValueError instead.
    with pytest.raises(ValueError):
        realized_volatility_30d([100.0])
    with pytest.raises(ValueError):
        realized_volatility_30d([100.0, 101.0])
    # 3 prices is the minimum that must succeed (returns a finite number).
    rv = realized_volatility_30d([100.0, 101.0, 100.5])
    assert math.isfinite(rv) and rv >= 0


def test_probability_weighted_payoff_keys_present():
    dcs = debit_call_spread(100, long_strike=100, short_strike=105,
                            days_to_expiration=30, risk_free_rate=0.045,
                            volatility_long=0.30, volatility_short=0.28, contracts=1)
    pwp = probability_weighted_payoff(dcs, n_paths=20000)
    assert isinstance(pwp, dict) and len(pwp) > 0

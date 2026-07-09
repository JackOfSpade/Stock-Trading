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


# ---------------------------------------------------------------------------
# OptionInputs.__post_init__ validation (2026-07-04 audit finding: a negative
# days_to_expiration used to be silently priced as "already expired" instead
# of rejected as invalid input).
# ---------------------------------------------------------------------------
def test_optioninputs_rejects_negative_days_to_expiration():
    with pytest.raises(ValueError):
        ATMOption(100.0, 100.0, -5, 0.045, 0.30, 'call')


def test_optioninputs_rejects_nonpositive_underlying_price():
    with pytest.raises(ValueError):
        ATMOption(0.0, 100.0, 30, 0.045, 0.30, 'call')
    with pytest.raises(ValueError):
        ATMOption(-10.0, 100.0, 30, 0.045, 0.30, 'call')


def test_optioninputs_rejects_nonpositive_strike():
    with pytest.raises(ValueError):
        ATMOption(100.0, 0.0, 30, 0.045, 0.30, 'call')
    with pytest.raises(ValueError):
        ATMOption(100.0, -50.0, 30, 0.045, 0.30, 'call')


def test_optioninputs_rejects_negative_volatility():
    with pytest.raises(ValueError):
        ATMOption(100.0, 100.0, 30, 0.045, -0.1, 'call')


def test_optioninputs_allows_zero_volatility():
    # Zero vol is a legitimate degenerate input, handled explicitly by price_bsm/
    # greeks_bsm's own volatility<=0 branch — must NOT be rejected by the guard.
    opt = ATMOption(100.0, 100.0, 30, 0.045, 0.0, 'call')
    assert opt.volatility == 0.0


def test_optioninputs_allows_zero_days_to_expiration():
    # Exactly-expired is a legitimate input (the intrinsic-value branch) — must
    # NOT be rejected.
    opt = ATMOption(100.0, 100.0, 0, 0.045, 0.30, 'call')
    assert opt.days_to_expiration == 0


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
# Zero-volatility branch (2026-07-04 audit finding: this branch was added to
# fix a real, previously-shipped ~2x mispricing for ITM options — see the
# comment in price_bsm — but had zero test coverage pinning it).
# ---------------------------------------------------------------------------
def test_price_bsm_zero_volatility_matches_discounted_forward():
    S, K, r, q, days = 105.0, 100.0, 0.045, 0.02, 30
    T = days / 365.0
    call = ATMOption(S, K, days, r, 0.0, 'call', dividend_yield=q)
    fwd = S * math.exp(-q * T)
    kpv = K * math.exp(-r * T)
    assert price_bsm(call) == pytest.approx(max(fwd - kpv, 0.0), abs=1e-9)

    # OTM put at the same inputs: intrinsic is 0 on the losing side.
    otm_put = ATMOption(S, K, days, r, 0.0, 'put', dividend_yield=q)
    assert price_bsm(otm_put) == pytest.approx(max(kpv - fwd, 0.0), abs=1e-9)

    # ITM put (S below K): non-zero discounted intrinsic.
    itm_put = ATMOption(90.0, K, days, r, 0.0, 'put', dividend_yield=q)
    fwd2 = 90.0 * math.exp(-q * T)
    assert price_bsm(itm_put) == pytest.approx(max(kpv - fwd2, 0.0), abs=1e-9)
    assert price_bsm(itm_put) > 0.0


def test_greeks_bsm_zero_volatility_is_finite_and_correctly_signed():
    itm_call = ATMOption(105.0, 100.0, 30, 0.045, 0.0, 'call')
    itm_put = ATMOption(95.0, 100.0, 30, 0.045, 0.0, 'put')
    gc = greeks_bsm(itm_call)
    gp = greeks_bsm(itm_put)

    assert math.isfinite(gc['delta']) and 0 <= gc['delta'] <= 1 and gc['delta'] > 0
    assert math.isfinite(gp['delta']) and -1 <= gp['delta'] <= 0 and gp['delta'] < 0
    for greeks in (gc, gp):
        assert greeks['gamma'] == 0.0
        assert greeks['vega'] == 0.0
        assert greeks['theta'] == 0.0


# ---------------------------------------------------------------------------
# dividend_yield (2026-07-04 audit finding: every pre-existing test relied on
# the default dividend_yield=0.0, so the exp(-qT) term used throughout pricing
# and Greeks had zero regression coverage).
# ---------------------------------------------------------------------------
def test_put_call_parity_with_dividend_yield():
    S, K, r, q, days = 100.0, 100.0, 0.045, 0.02, 30
    T = days / 365.0
    call = ATMOption(S, K, days, r, 0.30, 'call', dividend_yield=q)
    put = ATMOption(S, K, days, r, 0.30, 'put', dividend_yield=q)
    lhs = price_bsm(call) - price_bsm(put)
    rhs = S * math.exp(-q * T) - K * math.exp(-r * T)
    assert lhs == pytest.approx(rhs, abs=1e-3)


def test_greeks_bsm_call_delta_decreases_with_dividend_yield():
    no_div = ATMOption(100.0, 100.0, 30, 0.045, 0.30, 'call', dividend_yield=0.0)
    with_div = ATMOption(100.0, 100.0, 30, 0.045, 0.30, 'call', dividend_yield=0.03)
    assert greeks_bsm(with_div)['delta'] < greeks_bsm(no_div)['delta']


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


# ---------------------------------------------------------------------------
# Structure cross-leg quote consistency (2026-07-04 audit finding: legs quoted
# at different underlying_price/risk_free_rate/dividend_yield used to silently
# corrupt net_debit()/max_loss_closed_form() with no error, since only shared
# expiration was enforced).
# ---------------------------------------------------------------------------
def test_structure_rejects_mismatched_underlying_price_across_legs():
    legs = [
        OptionLeg(option=ATMOption(100.0, 100, 30, 0.045, 0.30, 'call'), quantity=1),
        OptionLeg(option=ATMOption(100.5, 105, 30, 0.045, 0.30, 'call'), quantity=-1),
    ]
    with pytest.raises(ValueError):
        Structure(legs=legs, name='mismatched_dcs', structure_type='debit_call_spread')


def test_structure_rejects_mismatched_risk_free_rate_across_legs():
    legs = [
        OptionLeg(option=ATMOption(100.0, 100, 30, 0.045, 0.30, 'call'), quantity=1),
        OptionLeg(option=ATMOption(100.0, 105, 30, 0.05, 0.30, 'call'), quantity=-1),
    ]
    with pytest.raises(ValueError):
        Structure(legs=legs, name='mismatched_rate', structure_type='debit_call_spread')


def test_structure_rejects_mismatched_dividend_yield_across_legs():
    legs = [
        OptionLeg(option=ATMOption(100.0, 100, 30, 0.045, 0.30, 'call', dividend_yield=0.0), quantity=1),
        OptionLeg(option=ATMOption(100.0, 105, 30, 0.045, 0.30, 'call', dividend_yield=0.02), quantity=-1),
    ]
    with pytest.raises(ValueError):
        Structure(legs=legs, name='mismatched_div', structure_type='debit_call_spread')


def test_structure_accepts_matched_legs_across_all_shared_fields():
    # Sanity check the new guard doesn't false-positive on a normal, correctly
    # quoted multi-leg structure (every sanctioned constructor already does this).
    legs = [
        OptionLeg(option=ATMOption(100.0, 100, 30, 0.045, 0.30, 'call', dividend_yield=0.01), quantity=1),
        OptionLeg(option=ATMOption(100.0, 105, 30, 0.045, 0.28, 'call', dividend_yield=0.01), quantity=-1),
    ]
    struct = Structure(legs=legs, name='ok_dcs', structure_type='debit_call_spread')
    assert struct.underlying_price == 100.0


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
    cascade = cascade_max_loss(cps, implied_move_full_horizon=0.05)
    assert math.isfinite(cascade) and cascade >= 0


def test_cascade_max_loss_rejects_a_separate_underlying_price_argument():
    # Regression guard (2026-07-09 fix): cascade_max_loss used to accept a
    # separate underlying_price/days_to_expiration that could silently diverge
    # from the structure's own entry price/expiration with no error — e.g.
    # passing a live/current quote instead of the entry price used to build
    # the structure produced a silently wrong (sometimes silently ZERO)
    # cascade figure. Pinning the signature to (structure,
    # implied_move_full_horizon) — sourcing the price from
    # structure.underlying_price — closes that footgun by construction; this
    # test fails loudly if the parameter is ever reintroduced.
    cps = credit_put_spread(100, short_strike=95, long_strike=90,
                             days_to_expiration=30, risk_free_rate=0.045,
                             volatility_short=0.30, volatility_long=0.30, contracts=1)
    with pytest.raises(TypeError):
        cascade_max_loss(cps, underlying_price=150, implied_move_full_horizon=0.05)


# ---------------------------------------------------------------------------
# Golden / worked-example tests for cascade_max_loss (2026-07-03 self-improvement
# audit finding: the existing suite only asserted isfinite()/>=0, so a sign-flip
# or wrong-leg-selected bug in cascade_max_loss's control flow — the load-bearing
# bound for Strategy C's 2% sizing on short-leg structures — would pass silently.
# These hand-compute the rev-20 formula independently (not by calling
# cascade_max_loss's internals) and assert equality, catching that class of bug.
# ---------------------------------------------------------------------------
def test_cascade_max_loss_golden_credit_call_spread_call_side_assigned():
    ccs = credit_call_spread(100, short_strike=100, long_strike=105,
                              days_to_expiration=30, risk_free_rate=0.045,
                              volatility_short=0.30, volatility_long=0.30, contracts=1)
    implied_move = 0.05
    cascade = cascade_max_loss(ccs, implied_move_full_horizon=implied_move)
    # Rev 20: adverse move = 2x implied move; call side adverse direction is UP.
    adverse_mark = 100 * (1 + 2 * implied_move)
    assert adverse_mark == pytest.approx(110.0)
    assignment_loss = max(adverse_mark - 100, 0.0) * CONTRACT_MULTIPLIER   # short call K=100
    long_payoff = max(adverse_mark - 105, 0.0) * CONTRACT_MULTIPLIER      # long call K=105
    expected = max(0.0, assignment_loss - long_payoff + ccs.net_debit())
    assert expected > 100.0  # sanity: not a vacuous near-zero golden value
    assert cascade == pytest.approx(expected, abs=0.01)


def test_cascade_max_loss_golden_credit_put_spread_put_side_assigned():
    cps = credit_put_spread(100, short_strike=95, long_strike=90,
                             days_to_expiration=30, risk_free_rate=0.045,
                             volatility_short=0.30, volatility_long=0.30, contracts=1)
    implied_move = 0.05
    cascade = cascade_max_loss(cps, implied_move_full_horizon=implied_move)
    # Put side adverse direction is DOWN.
    adverse_mark = 100 * (1 - 2 * implied_move)
    assert adverse_mark == pytest.approx(90.0)
    assignment_loss = max(95 - adverse_mark, 0.0) * CONTRACT_MULTIPLIER   # short put K=95
    long_payoff = max(90 - adverse_mark, 0.0) * CONTRACT_MULTIPLIER       # long put K=90 -> 0 at S=90
    expected = max(0.0, assignment_loss - long_payoff + cps.net_debit())
    assert expected > 100.0  # sanity: not a vacuous near-zero golden value
    assert cascade == pytest.approx(expected, abs=0.01)


def test_cascade_max_loss_golden_iron_condor_picks_worse_side_not_last_leg():
    # Constructed so the PUT side's cascade loss is materially larger than the CALL
    # side's (short_call is far OTM and never gets reached by the adverse move) —
    # while iron_condor's leg order always places the short CALL leg last in
    # structure.legs. A "pick whichever short leg is iterated last" bug would
    # therefore return the smaller (near-zero) call-side loss; correct behavior
    # (max across short legs) must return the larger put-side loss.
    ic = iron_condor(100, long_put_strike=80, short_put_strike=95,
                      short_call_strike=130, long_call_strike=150,
                      days_to_expiration=30, risk_free_rate=0.045,
                      vol_long_put=0.30, vol_short_put=0.30,
                      vol_short_call=0.30, vol_long_call=0.30, contracts=1)
    implied_move = 0.05
    cascade = cascade_max_loss(ic, implied_move_full_horizon=implied_move)

    adverse_mark_up = 100 * (1 + 2 * implied_move)     # 110
    adverse_mark_dn = 100 * (1 - 2 * implied_move)     # 90
    cascade_call_side = max(0.0,
        max(adverse_mark_up - 130, 0.0) * CONTRACT_MULTIPLIER    # short call K=130 -> 0 (110<130)
        - max(adverse_mark_up - 150, 0.0) * CONTRACT_MULTIPLIER  # long call K=150 -> 0
        + ic.net_debit())
    cascade_put_side = max(0.0,
        max(95 - adverse_mark_dn, 0.0) * CONTRACT_MULTIPLIER     # short put K=95 -> 500
        - max(80 - adverse_mark_dn, 0.0) * CONTRACT_MULTIPLIER   # long put K=80 -> 0
        + ic.net_debit())
    expected = max(cascade_call_side, cascade_put_side)
    assert cascade_put_side > cascade_call_side + 1.0  # confirms the test actually discriminates
    assert cascade == pytest.approx(expected, abs=0.01)


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

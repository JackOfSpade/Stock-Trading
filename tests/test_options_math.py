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
    _atm_nearest_leg_volatility,
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
# implied_vol iteration-0 false-convergence (codebase audit 2026-07-26):
# a vega-degenerate point (deep-OTM / $0.00-priced leg) must never be accepted
# as "solved," even trivially on the very first Newton iteration. Deep-OTM legs
# are routine in the iron condors and wide credit spreads this module builds, so
# this is not a contrived edge case -- it is a real input shape.
# ---------------------------------------------------------------------------
def test_implied_vol_deep_otm_zero_price_returns_none():
    # S=100, K=150, 5 DTE call: massively OTM with almost no time value at any
    # sane vol, so target_price=0.0 sits in a flat, near-zero-vega pricing
    # region. The old code's abs(diff) < tolerance check ran BEFORE the
    # vega-degeneracy guard and accepted this trivially on iteration 0.
    assert implied_vol(0.0, 100, 150, 5, 0.045, 'call') is None


def test_implied_vol_deep_otm_zero_price_independent_of_initial_guess():
    # The bug's smoking gun: varying ONLY initial_guess changed the "solved" IV
    # (0.05 -> 0.05, 0.10 -> 0.10, 0.50 -> 0.50 on the unfixed code) -- proof the
    # solver was not solving anything, just echoing back whatever guess it was
    # handed. A correctly-guarded solver must return None regardless of guess.
    # 0.80 is in this list deliberately: an intermediate fix that only moved a
    # `vega_per_unit < 1e-6` guard ahead of the accept-check still fabricated
    # 0.7011 at initial_guess=0.80, because vega there is 2.3e-10 -- above the
    # 1e-10 divide-by-zero floor but economically meaningless. Only deciding
    # identifiability from the TARGET PRICE (the bracket check) closes it for
    # every guess.
    for guess in (0.05, 0.10, 0.30, 0.50, 0.80):
        result = implied_vol(0.0, 100, 150, 5, 0.045, 'call', initial_guess=guess)
        assert result is None, (
            f"implied_vol should defer (None) for this unidentifiable input "
            f"regardless of initial_guess, but initial_guess={guess} gave {result}"
        )


def test_implied_vol_deep_itm_at_intrinsic_floor_returns_none():
    """Second false-convergence class (codebase audit 2026-07-26): a deep-ITM
    quote sitting AT the discounted-intrinsic floor prices within `tolerance` of
    that floor for a wide band of sigma, so the old accept-check fired there too.
    A randomized 20k-quote sweep found 2278 such fabricated IVs. The quote does
    not identify a vol, so the contract says defer."""
    S, K, days, r = 487.3, 875.6, 1, 0.0045
    floor_price = price_bsm(ATMOption(S, K, days, r, 0.001, 'put'))
    assert implied_vol(floor_price, S, K, days, r, 'put') is None


def test_implied_vol_when_it_returns_a_value_that_value_reprices_to_the_target():
    """The property that actually matters, and the one that separates a genuine
    root from a fabrication: whatever implied_vol returns must reproduce the
    input price. The pre-fix failure mode returned `initial_guess` unchanged,
    which does NOT reprice; deep-ITM quotes whose IV is only loosely pinned still
    do reprice, which is why they are legitimately solved rather than deferred."""
    cases = [
        (100.0, 100.0, 30, 0.045, 0.35, 'call'),
        (535.3, 911.5, 21, 0.03, 0.4357, 'put'),
        (527.4, 303.3, 90, 0.05, 0.2305, 'call'),
        (59.3, 78.7, 3, 0.02, 0.6636, 'put'),
    ]
    for S, K, days, r, vol, kind in cases:
        target = price_bsm(ATMOption(S, K, days, r, vol, kind))
        solved = implied_vol(target, S, K, days, r, kind)
        if solved is None:
            continue  # deferral is always an acceptable answer; a wrong number is not
        repriced = price_bsm(ATMOption(S, K, days, r, solved, kind))
        assert repriced == pytest.approx(target, abs=1e-6), (
            f"implied_vol returned {solved} for a {kind} priced {target}, but that "
            f"vol reprices to {repriced} — not a root of the equation it claims to solve"
        )


def test_implied_vol_genuine_solve_still_round_trips_at_various_guesses():
    # Guard against an overzealous degeneracy fix breaking real convergence: a
    # solvable, reasonably-priced option must still round-trip its IV no matter
    # which initial_guess the caller happens to pass.
    target = 0.35
    opt = ATMOption(100, 100, 30, 0.045, target, 'call')
    px = price_bsm(opt)
    for guess in (0.05, 0.10, 0.50, 1.0):
        solved = implied_vol(px, 100, 100, 30, 0.045, 'call', initial_guess=guess)
        assert solved is not None, f"genuine solve wrongly deferred at initial_guess={guess}"
        assert solved == pytest.approx(target, abs=1e-4)


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
    assert 0.0 <= pwp['prob_profit'] <= 1.0
    assert 0.0 <= pwp['prob_max_loss'] <= 1.0
    assert pwp['expected_payoff'] >= 0.0  # a debit call spread's payoff (pre-debit) is >= 0
    assert pwp['expected_pnl'] >= -dcs.max_loss_closed_form() - 0.01  # can't lose more than defined max loss


# ---------------------------------------------------------------------------
# probability_weighted_payoff's volatility source (codebase audit 2026-07-26):
# it used to take structure.legs[0].option.volatility unconditionally. For
# iron_condor(...), legs[0] is always the long put -- the WING, never the body
# -- so with realistic skew that silently drove the terminal-price simulation
# off the wrong leg's vol. Unlike underlying_price/risk_free_rate/dividend_yield
# (enforced uniform by Structure.__post_init__), volatility is deliberately
# per-leg, so "just take legs[0]" grabbed exactly the one field most likely to
# differ from what the underlying's own risk-neutral vol should be.
# ---------------------------------------------------------------------------
def test_atm_nearest_leg_volatility_selects_near_the_money_leg_not_legs0():
    # short_call strike=99 is nearest to underlying_price=100 (distance 1) vs.
    # short_put strike=95 (distance 5), so its vol (0.40) must be selected --
    # NOT legs[0]'s vol, which iron_condor always builds as the long put (the
    # wing, vol=0.60 here).
    ic = iron_condor(100, long_put_strike=80, short_put_strike=95,
                      short_call_strike=99, long_call_strike=120,
                      days_to_expiration=30, risk_free_rate=0.045,
                      vol_long_put=0.60, vol_short_put=0.55,
                      vol_short_call=0.40, vol_long_call=0.65, contracts=1)
    assert ic.legs[0].option.volatility == pytest.approx(0.60)  # sanity: legs[0] IS the wing
    assert _atm_nearest_leg_volatility(ic) == pytest.approx(0.40)


def test_atm_nearest_leg_volatility_tie_break_is_deterministic():
    # Symmetric iron condor: short_put (95) and short_call (105) are exactly
    # equidistant from underlying_price=100. The tie-break (lower strike) must
    # be deterministic so the result never depends on leg list order.
    ic = iron_condor(100, long_put_strike=90, short_put_strike=95,
                      short_call_strike=105, long_call_strike=110,
                      days_to_expiration=30, risk_free_rate=0.045,
                      vol_long_put=0.60, vol_short_put=0.42,
                      vol_short_call=0.48, vol_long_call=0.65, contracts=1)
    assert _atm_nearest_leg_volatility(ic) == pytest.approx(0.42)


def test_probability_weighted_payoff_uses_atm_vol_not_legs0_wing_vol():
    wing_vol, atm_vol = 0.60, 0.40
    shared = dict(long_put_strike=80, short_put_strike=95, short_call_strike=99,
                  long_call_strike=120, days_to_expiration=30, risk_free_rate=0.045,
                  contracts=1)
    # Skewed structure: wing legs at 0.60/0.55/0.65, near-the-money short_call at 0.40.
    ic = iron_condor(100, vol_long_put=wing_vol, vol_short_put=0.55,
                      vol_short_call=atm_vol, vol_long_call=0.65, **shared)
    # Comparison structures: same strikes/quantities (so IDENTICAL expiration
    # payoff function), but every leg quoted at one uniform vol.
    ic_at_atm_vol = iron_condor(100, vol_long_put=atm_vol, vol_short_put=atm_vol,
                                 vol_short_call=atm_vol, vol_long_call=atm_vol, **shared)
    ic_at_wing_vol = iron_condor(100, vol_long_put=wing_vol, vol_short_put=wing_vol,
                                  vol_short_call=wing_vol, vol_long_call=wing_vol, **shared)
    seed = 7
    pwp = probability_weighted_payoff(ic, n_paths=20000, seed=seed)
    pwp_atm = probability_weighted_payoff(ic_at_atm_vol, n_paths=20000, seed=seed)
    pwp_wing = probability_weighted_payoff(ic_at_wing_vol, n_paths=20000, seed=seed)
    # expected_payoff depends ONLY on the terminal-price distribution (driven by
    # sigma) and the strikes/quantities used to price the expiration payoff
    # (identical across all three variants) -- net_debit (which does differ per
    # variant, since each leg's premium depends on its own quoted vol) never
    # enters expected_payoff. So with the same seed, the skewed structure must
    # match the uniform-ATM-vol run's expected_payoff exactly if (and only if)
    # the simulation is sampling with the ATM-nearest leg's vol as fixed here.
    assert pwp['expected_payoff'] == pytest.approx(pwp_atm['expected_payoff'], abs=1e-6)
    assert pwp['expected_payoff'] != pytest.approx(pwp_wing['expected_payoff'], abs=1e-6)


def test_breakeven_points_long_call_and_debit_spread():
    # Long call: single breakeven at strike + premium-per-share.
    lc = long_call(100, strike=100, days_to_expiration=30,
                   risk_free_rate=0.045, volatility=0.30, contracts=1)
    bes = lc.breakeven_points()
    assert len(bes) == 1
    assert bes[0] == pytest.approx(100 + lc.net_debit() / CONTRACT_MULTIPLIER, abs=0.05)
    # Debit call spread: single breakeven at long_strike + net-debit-per-share.
    dcs = debit_call_spread(100, long_strike=100, short_strike=105,
                            days_to_expiration=30, risk_free_rate=0.045,
                            volatility_long=0.30, volatility_short=0.28, contracts=1)
    bes2 = dcs.breakeven_points()
    assert len(bes2) == 1
    assert bes2[0] == pytest.approx(100 + dcs.net_debit() / CONTRACT_MULTIPLIER, abs=0.05)


def test_realized_vol_uses_only_trailing_31_closes():
    # Only the last 31 prices (30 returns) may influence the result; prepending
    # wildly different older closes must not change it. Guards the [-31:] slice.
    rng = random.Random(7)
    core = [100.0]
    dv = 0.30 / math.sqrt(252)
    for _ in range(40):  # 41 closes total, so the last 31 are unaffected by a prefix
        core.append(core[-1] * math.exp(dv * rng.gauss(0, 1)))
    rv_core = realized_volatility_30d(core)
    rv_prefixed = realized_volatility_30d([1.0, 5000.0, 0.5, 9999.0] + core)
    assert rv_prefixed == pytest.approx(rv_core, abs=1e-12)


def test_scenario_pnl_grid_anchors_on_underlying_and_matches_pnl():
    dcs = debit_call_spread(100, long_strike=100, short_strike=105,
                            days_to_expiration=30, risk_free_rate=0.045,
                            volatility_long=0.30, volatility_short=0.28, contracts=1)
    grid = dcs.scenario_pnl_grid()
    assert set(grid) == {
        'reference_plus_10pct', 'reference_plus_5pct', 'reference',
        'reference_minus_5pct', 'reference_minus_10pct'}
    debit = dcs.net_debit()
    # +10% -> S=110 (>= short strike): max profit = width*100 - debit.
    assert grid['reference_plus_10pct'] == pytest.approx(5 * CONTRACT_MULTIPLIER - debit, abs=0.01)
    # -10% -> S=90 (both legs OTM): max loss = -debit.
    assert grid['reference_minus_10pct'] == pytest.approx(-debit, abs=0.01)


def test_size_position_exact_multiple_not_dropped_by_float_error():
    # nav_cap = 0.02 * 240.0 = 4.8; 4.8 / 1.6 == 2.9999999999999996 in binary
    # float, so math.floor WITHOUT the +1e-9 epsilon would under-size 3 -> 2.
    # The epsilon on c_options_math.py:1301 must keep this exact integer multiple
    # at 3 contracts. NOTE: values like (5.0, 1000.0) give 20/5 == 4.0 exactly and
    # therefore do NOT exercise the epsilon (they pass with or without it).
    assert math.floor(4.8 / 1.6) == 2  # sentinel: raw float underestimates
    contracts, defer = size_position(1.6, 240.0, 0.02)
    assert contracts == 3 and defer is False


# ---------------------------------------------------------------------------
# 2026-07-14 self-improvement audit fixes: input validation + expiration Greeks
# ---------------------------------------------------------------------------
def test_cascade_max_loss_rejects_non_positive_implied_move():
    # A negative implied_move_full_horizon used to silently flip the adverse-move
    # direction (a 100/105 credit call spread's cascade went from 306.26 to 0.0),
    # understating total_max_loss = max(closed_form, cascade). Must raise instead.
    ccs = credit_call_spread(100, short_strike=100, long_strike=105,
                              days_to_expiration=30, risk_free_rate=0.045,
                              volatility_short=0.30, volatility_long=0.30, contracts=1)
    for bad in (-0.05, 0.0, float('nan'), float('inf')):
        with pytest.raises(ValueError):
            cascade_max_loss(ccs, implied_move_full_horizon=bad)


def test_butterfly_rejects_non_ascending_or_equal_strikes():
    # The equidistant check alone is vacuously true for identical/reversed strikes
    # (both differences are equal), which used to silently build a degenerate
    # zero-net-payoff "butterfly" that both dual-path checks agree on.
    for lo, mid, hi in [(100, 100, 100), (105, 100, 95)]:
        with pytest.raises(ValueError):
            long_call_butterfly(100, lower_strike=lo, middle_strike=mid, upper_strike=hi,
                                 days_to_expiration=30, risk_free_rate=0.045,
                                 vol_lower=0.30, vol_middle=0.30, vol_upper=0.30, contracts=1)


def test_butterfly_rejects_non_equidistant_strikes():
    with pytest.raises(ValueError):
        long_put_butterfly(100, lower_strike=90, middle_strike=100, upper_strike=115,
                            days_to_expiration=30, risk_free_rate=0.045,
                            vol_lower=0.30, vol_middle=0.30, vol_upper=0.30, contracts=1)


@pytest.mark.parametrize("bad", [-1, 0, 2.5])
def test_constructors_reject_invalid_contracts(bad):
    # A negative/fractional contracts count used to be silently accepted (e.g.
    # long_put(..., contracts=-1) built a naked short put ~30x the real max loss,
    # still labeled 'long_put'), sailing through dual-path verification with no
    # error. All 8 constructors must now reject it.
    with pytest.raises(ValueError):
        long_call(100, strike=100, days_to_expiration=30, risk_free_rate=0.045,
                   volatility=0.30, contracts=bad)
    with pytest.raises(ValueError):
        long_put(100, strike=100, days_to_expiration=30, risk_free_rate=0.045,
                  volatility=0.30, contracts=bad)
    with pytest.raises(ValueError):
        debit_call_spread(100, long_strike=100, short_strike=105, days_to_expiration=30,
                           risk_free_rate=0.045, volatility_long=0.30, volatility_short=0.28,
                           contracts=bad)
    with pytest.raises(ValueError):
        debit_put_spread(100, long_strike=105, short_strike=100, days_to_expiration=30,
                          risk_free_rate=0.045, volatility_long=0.30, volatility_short=0.28,
                          contracts=bad)
    with pytest.raises(ValueError):
        credit_call_spread(100, short_strike=100, long_strike=105, days_to_expiration=30,
                            risk_free_rate=0.045, volatility_short=0.30, volatility_long=0.28,
                            contracts=bad)
    with pytest.raises(ValueError):
        credit_put_spread(100, short_strike=100, long_strike=95, days_to_expiration=30,
                           risk_free_rate=0.045, volatility_short=0.30, volatility_long=0.28,
                           contracts=bad)
    with pytest.raises(ValueError):
        iron_condor(100, long_put_strike=85, short_put_strike=90, short_call_strike=110,
                    long_call_strike=115, days_to_expiration=30, risk_free_rate=0.045,
                    vol_long_put=0.30, vol_short_put=0.30, vol_short_call=0.30,
                    vol_long_call=0.30, contracts=bad)
    with pytest.raises(ValueError):
        long_call_butterfly(100, lower_strike=90, middle_strike=100, upper_strike=110,
                             days_to_expiration=30, risk_free_rate=0.045,
                             vol_lower=0.30, vol_middle=0.30, vol_upper=0.30, contracts=bad)


def test_price_bsm_at_expiration_returns_intrinsic_value():
    itm_call = ATMOption(110, 100, 0, 0.045, 0.30, 'call')
    otm_call = ATMOption(90, 100, 0, 0.045, 0.30, 'call')
    itm_put = ATMOption(90, 100, 0, 0.045, 0.30, 'put')
    otm_put = ATMOption(110, 100, 0, 0.045, 0.30, 'put')
    assert price_bsm(itm_call) == pytest.approx(10.0)
    assert price_bsm(otm_call) == 0.0
    assert price_bsm(itm_put) == pytest.approx(10.0)
    assert price_bsm(otm_put) == 0.0


def test_greeks_bsm_at_expiration_delta_reflects_moneyness():
    # T<=0 used to unconditionally return delta=0.0 regardless of moneyness, even
    # though an ITM option's value at expiration moves $1-for-$1 with the underlying
    # (price_bsm's own T<=0 branch returns pure intrinsic value with that exact slope).
    assert greeks_bsm(ATMOption(110, 100, 0, 0.045, 0.30, 'call'))['delta'] == 1.0
    assert greeks_bsm(ATMOption(90, 100, 0, 0.045, 0.30, 'call'))['delta'] == 0.0
    assert greeks_bsm(ATMOption(90, 100, 0, 0.045, 0.30, 'put'))['delta'] == -1.0
    assert greeks_bsm(ATMOption(110, 100, 0, 0.045, 0.30, 'put'))['delta'] == 0.0


def test_greeks_bsm_at_expiration_other_greeks_still_zero():
    for opt in (ATMOption(110, 100, 0, 0.045, 0.30, 'call'), ATMOption(90, 100, 0, 0.045, 0.30, 'put')):
        g = greeks_bsm(opt)
        assert g['gamma'] == 0.0 and g['theta'] == 0.0 and g['vega'] == 0.0 and g['rho'] == 0.0

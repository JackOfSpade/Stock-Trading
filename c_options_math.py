"""
Strategy C — Options-Math Scaffolding (Step 5 from original 6-step plan)

Per Strategy.md Strategy C "Classical-method delegation (all numerical work goes
to code per 2.11 and 2.12)" — this module implements all the numerical work that
must NOT be done by Claude's reasoning.

Implements:
- Black-Scholes-Merton pricing + all Greeks (delta, gamma, theta, vega, rho)
- Implied volatility solver (Newton-Raphson on price)
- Multi-leg structure construction (long calls, long puts, debit spreads,
  credit spreads, iron condors, butterflies)
- Breakeven calculation per structure
- Max-loss closed-form computation per structure
- Max-loss Monte Carlo verification (dual-path requirement per Strategy.md
  rev 19 dual-path verification clause; both paths must agree to within $1)
- Early-assignment cascade max-loss (per rev 20 conventions:
  mark-to-market at assignment instant; 2x implied-move scaled to full
  structure expiration; multi-expiration variants excluded)
- Position sizing arithmetic (2% NAV → contract count, with deferral rule
  if no integer count fits)
- IV at entry vs trailing-30-day realized volatility comparison
- Probability-weighted payoff under market-implied risk-neutral distribution

DESIGN CONSTRAINTS:
- Pure Python stdlib + math only (no scipy/numpy assumed available; uses
  math.erf for the cumulative normal which is exact-enough for our purposes)
- All inputs explicit; no implicit assumptions about future volatility
- All max-loss computations include early-assignment cascade scenarios
  (per Strategy.md rev 19 + rev 20)
- Multi-expiration structures (calendars, diagonals) raise NotImplementedError
  (per Strategy.md rev 20 — explicitly excluded)
- Max-loss computation REFUSES net-short-call structures (total call quantity
  < 0 → loss unbounded as the underlying rises) by raising
  UnboundedMaxLossError, instead of returning a silently finite — and
  therefore understated — number into the 2%-NAV sizing. Net-short-put
  exposure is bounded (worst case at underlying = 0) and is computed exactly.
- Dual-path agreement enforced with $1 tolerance per structure
- All Greeks computed analytically (closed-form), not via finite difference

USAGE:
    from c_options_math import (
        OptionInputs, OptionLeg, Structure,
        price_bsm, greeks_bsm, implied_vol,
        long_call, long_put,
        debit_call_spread, debit_put_spread,
        credit_call_spread, credit_put_spread,
        iron_condor, long_call_butterfly, long_put_butterfly,
        verify_max_loss_dual_path,
        cascade_max_loss,
        size_position,
        scenario_pnl_grid,
    )

    # Example: NVDA Jan 17 2025 expiration, FOMC event 2026-01-28
    inputs = OptionInputs(
        underlying_price=120.00,
        strike=120,
        days_to_expiration=21,
        risk_free_rate=0.045,
        volatility=0.45,  # IV at entry, retrieved from market
        option_type='call',
    )
    p = price_bsm(inputs)
    g = greeks_bsm(inputs)
    print(f"Call price: ${p:.4f}")
    print(f"Delta: {g['delta']:.4f}, Gamma: {g['gamma']:.6f}")

    # Build a debit call spread (keyword-only args after underlying_price
    # to prevent silent positional-argument bugs)
    structure = debit_call_spread(
        120.00,  # underlying_price (positional)
        long_strike=120,
        short_strike=125,
        days_to_expiration=21,
        risk_free_rate=0.045,
        volatility_long=0.45,
        volatility_short=0.42,  # short strike has lower IV in the smile
        contracts=1,
    )

    # Verify max loss via dual path
    closed_form_loss = structure.max_loss_closed_form()
    mc_loss = structure.max_loss_monte_carlo(n_paths=100000)
    verify_max_loss_dual_path(closed_form_loss, mc_loss, tolerance=1.00)

    # Compute early-assignment cascade max loss
    cascade_loss = cascade_max_loss(
        structure,
        underlying_price=120.00,
        days_to_expiration=21,
        implied_move_full_horizon=0.07,  # +/- 7% implied through expiration
    )

    # Total max loss = max(closed_form, cascade) per Strategy.md
    total_max_loss = max(closed_form_loss, cascade_loss)

    # Size position (raises ValueError if max_loss <= 0; that signals an
    # upstream bug, not a sizing edge case)
    contracts, defer = size_position(
        max_loss_per_contract=total_max_loss / 1,  # 1-contract reference
        strategy_nav=1389.37,
        max_pct_nav=0.02,
    )
    if defer:
        print("DEFER: no integer contract count fits 2% NAV cap")
    else:
        print(f"Sized to {contracts} contracts")
"""

import math
from dataclasses import dataclass
from typing import List, Optional, Literal, Dict, Tuple
import random


# =============================================================================
# Module constants
# =============================================================================

# US equity options multiplier: each contract represents 100 shares of underlying.
# Strategy C is currently scoped to US-listed equity options (per Strategy.md
# instrument eligibility rule). If C is ever extended to instruments with
# different multipliers (e.g., some index products, futures options), this
# constant needs to be parameterized into structure pricing and payoff
# computations. Per cycle 4 critical-eval warning [4].
CONTRACT_MULTIPLIER = 100


# =============================================================================
# Black-Scholes-Merton primitives
# =============================================================================

def _norm_cdf(x: float) -> float:
    """Standard normal CDF using math.erf (exact in stdlib)."""
    return 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))


def _norm_pdf(x: float) -> float:
    """Standard normal PDF."""
    return math.exp(-0.5 * x * x) / math.sqrt(2.0 * math.pi)


@dataclass
class OptionInputs:
    """Inputs for a single European-style option under BSM.

    Renamed from ATMOption (which was misleading since this class is used for
    any moneyness — ITM, ATM, or OTM). Per cycle 4 critical-eval warning [3].
    The old name ATMOption remains as an alias for backward compatibility.

    Per Strategy.md — Strategy C uses American-style equity options in practice,
    but for max-loss bounding under the early-assignment cascade rule, the BSM
    European pricing is conservative (American options are worth ≥ European,
    so BSM-priced max loss bounds the actual American max loss).
    """
    underlying_price: float
    strike: float
    days_to_expiration: int
    risk_free_rate: float  # annualized, decimal (e.g., 0.045 = 4.5%)
    volatility: float  # annualized IV, decimal (e.g., 0.45 = 45%)
    option_type: Literal['call', 'put']
    dividend_yield: float = 0.0  # continuous, annualized

    @property
    def time_to_expiration(self) -> float:
        """Years to expiration (using 365 calendar days; matches the IV
        convention used in retail options chains and aligns with realized
        vol annualization in realized_volatility_30d)."""
        return self.days_to_expiration / 365.0

    @property
    def d1(self) -> float:
        T = self.time_to_expiration
        if T <= 0 or self.volatility <= 0:
            return 0.0
        return (
            math.log(self.underlying_price / self.strike)
            + (self.risk_free_rate - self.dividend_yield + 0.5 * self.volatility ** 2) * T
        ) / (self.volatility * math.sqrt(T))

    @property
    def d2(self) -> float:
        T = self.time_to_expiration
        return self.d1 - self.volatility * math.sqrt(T)


# Backward-compatibility alias. New code should use OptionInputs.
ATMOption = OptionInputs


def price_bsm(opt: OptionInputs) -> float:
    """Black-Scholes-Merton price for European call or put."""
    if opt.time_to_expiration <= 0:
        # At expiration, intrinsic value only
        if opt.option_type == 'call':
            return max(opt.underlying_price - opt.strike, 0.0)
        else:
            return max(opt.strike - opt.underlying_price, 0.0)

    if opt.volatility <= 0:
        # Zero/negative vol: no time value, so the option is worth its
        # DISCOUNTED intrinsic (forward vs discounted strike). Without this
        # guard d1/d2 collapse to 0 and N(0)=0.5 returns 0.5*(S-K) — a ~2x
        # mispricing for ITM options that silently corrupts net_debit, max-loss
        # and sizing whenever any leg vol is passed as 0.
        fwd = opt.underlying_price * math.exp(-opt.dividend_yield * opt.time_to_expiration)
        kpv = opt.strike * math.exp(-opt.risk_free_rate * opt.time_to_expiration)
        if opt.option_type == 'call':
            return max(fwd - kpv, 0.0)
        else:
            return max(kpv - fwd, 0.0)

    S = opt.underlying_price
    K = opt.strike
    r = opt.risk_free_rate
    q = opt.dividend_yield
    T = opt.time_to_expiration
    d1 = opt.d1
    d2 = opt.d2

    if opt.option_type == 'call':
        return S * math.exp(-q * T) * _norm_cdf(d1) - K * math.exp(-r * T) * _norm_cdf(d2)
    else:
        return K * math.exp(-r * T) * _norm_cdf(-d2) - S * math.exp(-q * T) * _norm_cdf(-d1)


def greeks_bsm(opt: OptionInputs) -> Dict[str, float]:
    """Closed-form Greeks for European call or put under BSM.

    Returns dict with keys: delta, gamma, theta, vega, rho.

    Conventions:
    - delta: per $1 underlying move (range: 0..1 call, -1..0 put)
    - gamma: per $1 underlying move (always positive for long options)
    - theta: per CALENDAR DAY (negative for long options); divide annual theta
      by 365.
    - vega: per 1 vol-point move (i.e., per 0.01 in volatility decimal)
    - rho: per 1 rate-point move (i.e., per 0.01 in r decimal)
    """
    if opt.time_to_expiration <= 0:
        return {'delta': 0.0, 'gamma': 0.0, 'theta': 0.0, 'vega': 0.0, 'rho': 0.0}

    if opt.volatility <= 0:
        # Zero/negative vol: gamma/vega/theta divide by sigma → guard against
        # ZeroDivisionError. Greeks are degenerate; return finite sentinels with
        # delta from discounted-forward moneyness (price is handled in price_bsm).
        T0 = opt.time_to_expiration
        fwd = opt.underlying_price * math.exp(-opt.dividend_yield * T0)
        kpv = opt.strike * math.exp(-opt.risk_free_rate * T0)
        dq = math.exp(-opt.dividend_yield * T0)
        if opt.option_type == 'call':
            delta = dq if fwd > kpv else 0.0
        else:
            delta = -dq if fwd < kpv else 0.0
        return {'delta': delta, 'gamma': 0.0, 'theta': 0.0, 'vega': 0.0, 'rho': 0.0}

    S = opt.underlying_price
    K = opt.strike
    r = opt.risk_free_rate
    q = opt.dividend_yield
    sigma = opt.volatility
    T = opt.time_to_expiration
    d1 = opt.d1
    d2 = opt.d2
    sqrtT = math.sqrt(T)

    # Common terms
    nd1_pdf = _norm_pdf(d1)
    discount = math.exp(-r * T)
    div_discount = math.exp(-q * T)

    if opt.option_type == 'call':
        delta = div_discount * _norm_cdf(d1)
        # Theta annual
        theta_annual = (
            -S * nd1_pdf * sigma * div_discount / (2.0 * sqrtT)
            - r * K * discount * _norm_cdf(d2)
            + q * S * div_discount * _norm_cdf(d1)
        )
        rho = K * T * discount * _norm_cdf(d2) * 0.01  # per 1% rate move
    else:
        delta = -div_discount * _norm_cdf(-d1)
        theta_annual = (
            -S * nd1_pdf * sigma * div_discount / (2.0 * sqrtT)
            + r * K * discount * _norm_cdf(-d2)
            - q * S * div_discount * _norm_cdf(-d1)
        )
        rho = -K * T * discount * _norm_cdf(-d2) * 0.01

    # Greeks shared between call and put
    gamma = div_discount * nd1_pdf / (S * sigma * sqrtT)
    vega = S * div_discount * nd1_pdf * sqrtT * 0.01  # per 1% vol move
    theta_per_day = theta_annual / 365.0

    return {
        'delta': delta,
        'gamma': gamma,
        'theta': theta_per_day,
        'vega': vega,
        'rho': rho,
    }


def implied_vol(
    target_price: float,
    underlying_price: float,
    strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    option_type: Literal['call', 'put'],
    dividend_yield: float = 0.0,
    initial_guess: float = 0.30,
    tolerance: float = 1e-6,
    max_iter: int = 100,
) -> Optional[float]:
    """Solve for implied volatility via Newton-Raphson on Black-Scholes price.

    Returns None if no solution converges within max_iter (caller must handle
    deferral). Per Strategy.md, code-execution failures defer the thesis; they
    do NOT prompt Claude to estimate IV from reasoning.
    """
    sigma = initial_guess

    for _ in range(max_iter):
        opt = ATMOption(
            underlying_price=underlying_price,
            strike=strike,
            days_to_expiration=days_to_expiration,
            risk_free_rate=risk_free_rate,
            volatility=sigma,
            option_type=option_type,
            dividend_yield=dividend_yield,
        )
        price = price_bsm(opt)
        diff = price - target_price

        if abs(diff) < tolerance:
            return sigma

        # Vega for Newton step (vega is in /1% units, so multiply by 100 for /1)
        vega_per_unit = greeks_bsm(opt)['vega'] * 100.0
        if vega_per_unit < 1e-10:
            return None  # Vega too small; no convergence

        sigma = sigma - diff / vega_per_unit

        # Bound to reasonable range
        if sigma < 0.001:
            sigma = 0.001
        elif sigma > 5.0:
            sigma = 5.0

    return None  # Did not converge


# =============================================================================
# Multi-leg structure abstraction
# =============================================================================

@dataclass
class OptionLeg:
    """One leg of an option structure.

    Sign convention:
    - quantity > 0 = long
    - quantity < 0 = short

    All legs in a single Structure share the same expiration per Strategy.md
    rev 20 (multi-expiration structures excluded). The Structure class enforces
    this.
    """
    option: ATMOption
    quantity: int  # positive = long, negative = short

    def price(self) -> float:
        """Price of this leg (signed by quantity). Positive = position cost,
        negative = credit received.

        Multiplied by CONTRACT_MULTIPLIER (100 for US equity options) to convert
        per-share BSM price to per-contract dollar amount.
        """
        return price_bsm(self.option) * self.quantity * CONTRACT_MULTIPLIER

    def payoff_at_expiration(self, underlying_price_at_exp: float) -> float:
        """Per-contract payoff at expiration (signed by quantity)."""
        if self.option.option_type == 'call':
            intrinsic = max(underlying_price_at_exp - self.option.strike, 0.0)
        else:
            intrinsic = max(self.option.strike - underlying_price_at_exp, 0.0)
        return intrinsic * self.quantity * CONTRACT_MULTIPLIER


class UnboundedMaxLossError(Exception):
    """Raised when a structure's maximum loss is unbounded: net short call
    exposure (total call quantity < 0) makes the expiration payoff fall without
    limit as the underlying rises, so no finite max-loss number exists.
    Returning one anyway would silently understate risk and corrupt the 2%-NAV
    sizing. Such structures are not Strategy.md-permitted (defined-risk only);
    the constructors in this module never build one — this guards direct
    Structure(...) assembly."""
    pass


@dataclass
class Structure:
    """Multi-leg options structure with shared expiration."""
    legs: List[OptionLeg]
    name: str
    structure_type: str  # 'long_call', 'debit_call_spread', 'iron_condor', etc.

    def __post_init__(self):
        # Enforce single-expiration per Strategy.md rev 20
        expirations = {leg.option.days_to_expiration for leg in self.legs}
        if len(expirations) > 1:
            raise NotImplementedError(
                f"Multi-expiration structures excluded per Strategy.md rev 20 "
                f"(found {len(expirations)} distinct expirations: {expirations}). "
                f"Permitted: long calls, long puts, debit spreads, credit spreads, "
                f"iron condors, butterflies, single-expiration variants only."
            )

    @property
    def days_to_expiration(self) -> int:
        return self.legs[0].option.days_to_expiration

    @property
    def underlying_price(self) -> float:
        return self.legs[0].option.underlying_price

    def _net_quantity(self, option_type: str) -> int:
        """Signed total quantity across legs of one option type. The sign
        determines the payoff slope beyond the outermost strikes: net calls
        < 0 → loss unbounded upward; net puts < 0 → loss grows until S = 0."""
        return sum(leg.quantity for leg in self.legs
                   if leg.option.option_type == option_type)

    def net_debit(self) -> float:
        """Net cost to enter (positive = debit/cost, negative = credit/income)."""
        return sum(leg.price() for leg in self.legs)

    def payoff_at_expiration(self, underlying_price_at_exp: float) -> float:
        """Total payoff at expiration across all legs."""
        return sum(leg.payoff_at_expiration(underlying_price_at_exp) for leg in self.legs)

    def pnl_at_expiration(self, underlying_price_at_exp: float) -> float:
        """P&L at expiration = payoff − initial debit."""
        return self.payoff_at_expiration(underlying_price_at_exp) - self.net_debit()

    def breakeven_points(self) -> List[float]:
        """Find breakeven point(s) by scanning a wide grid + bisection refinement.

        Generic implementation works for any payoff diagram. Returns underlying
        prices at which P&L crosses zero at expiration.
        """
        S0 = self.underlying_price
        # Grid bounds derived from the STRIKES (not just S0): a long put's
        # breakeven can sit far below 0.5*S0 and a wide structure's breakeven far
        # above 2.0*S0, so an S0-relative window silently drops them. Span from
        # near-zero to well above the highest strike (and above S0).
        strikes = [leg.option.strike for leg in self.legs]
        hi = max(max(strikes), S0) * 3.0
        lo = 0.001
        n = 30000
        prices = [lo + (hi - lo) * i / n for i in range(n + 1)]
        pnls = [self.pnl_at_expiration(p) for p in prices]

        breakevens = []
        for i in range(len(prices) - 1):
            if (pnls[i] <= 0 < pnls[i + 1]) or (pnls[i] >= 0 > pnls[i + 1]):
                # Bisect for accuracy
                lo, hi = prices[i], prices[i + 1]
                for _ in range(50):
                    mid = (lo + hi) / 2
                    if self.pnl_at_expiration(mid) * pnls[i] < 0:
                        hi = mid
                    else:
                        lo = mid
                breakevens.append(round((lo + hi) / 2, 4))
        return breakevens

    def max_loss_closed_form(self) -> float:
        """Maximum loss at expiration, computed by scanning expiration payoff
        across a fine grid of underlying prices.

        For all permitted Strategy C structures (long calls, long puts, debit
        spreads, credit spreads, iron condors, butterflies — all single
        expiration), max loss is bounded and occurs at one of the strikes or
        at zero / very large underlying. Scan covers all those cases.

        Raises UnboundedMaxLossError for net-short-call structures (payoff
        slope above the highest strike is negative, so the loss grows without
        bound as the underlying rises and no finite scan can represent it).
        Net-short-put structures ARE handled: their worst case is at S = 0,
        which the grid evaluates exactly.

        Returns positive number = magnitude of max loss in dollars (NOT signed).
        """
        if self._net_quantity('call') < 0:
            raise UnboundedMaxLossError(
                f"{self.name}: net call quantity {self._net_quantity('call')} < 0 — "
                f"max loss is UNBOUNDED above the highest strike. Not a "
                f"defined-risk structure; per Strategy.md the thesis must defer."
            )

        S0 = self.underlying_price

        # Test prices: zero, all strikes, well-above-highest-strike, and a
        # fine grid in between. This is exact for piecewise-linear expiration
        # payoffs (which all permitted structures have).
        strikes = sorted({leg.option.strike for leg in self.legs})
        max_strike = max(strikes)
        test_prices = (
            [0.0, 0.001]  # exact zero (worst case for net-short puts) + near-zero
            + strikes
            + [s - 0.01 for s in strikes]  # just below each strike
            + [s + 0.01 for s in strikes]  # just above each strike
            + [max_strike * 5]  # far above
            + [S0 * (0.1 + 0.001 * i) for i in range(2901)]  # 0.1 to 3.0 of S0
        )

        worst_pnl = min(self.pnl_at_expiration(p) for p in test_prices)
        # max_loss is magnitude of worst case (negative pnl → positive loss)
        return max(0.0, -worst_pnl)

    def max_loss_monte_carlo(
        self,
        n_paths: int = 100000,
        adverse_move_stdev: float = 4.0,
        seed: Optional[int] = 42,
    ) -> float:
        """Monte Carlo verification of max loss.

        Per Strategy.md rev 19 dual-path verification clause: "max-loss
        verification must be performed by two independent code paths — closed-form
        formula computation AND Monte Carlo P&L scenario simulation across the
        structure's expiration grid — and both must agree to within $1 per
        structure before entry is permitted."

        This MC path samples terminal prices UNIFORMLY across a range that is
        guaranteed to span below the lowest strike and above the highest strike
        (widened to at least the realistic +/- adverse_move_stdev lognormal
        cone). For every permitted defined-risk structure the max-loss region is
        a FLAT zone beyond the outermost strike, so a range that reaches past all
        strikes will land in it and reproduce the closed-form bound.

        Why not the old lognormal +/-4-sigma sampler: for low-IV / short-DTE
        structures the 4-sigma cone never reaches the protective long strikes
        (e.g. a 7-DTE, 15%-vol iron condor only spans ~+/-8%), so MC returned $0
        while closed-form returned the true max loss — a spurious
        MaxLossDualPathDisagreement (or, if a caller trusted the lower MC value,
        an UNDER-stated risk and over-sized position). Uniform price-space
        sampling is an independent computation from the closed-form deterministic
        grid yet robust across the whole input space (any sigma/T).

        Raises UnboundedMaxLossError for net-short-call structures (no finite
        scan range can represent an unbounded loss). For net-short-PUT
        structures the below-lowest-strike zone is NOT flat — the loss keeps
        growing to S = 0 — so the range is extended to 0 there. The range
        endpoints are also evaluated deterministically: every bounded
        structure's flat-zone worst case sits at an endpoint, so pinning them
        removes the ~range/n_paths sampling gap against the closed-form path.
        """
        if self._net_quantity('call') < 0:
            raise UnboundedMaxLossError(
                f"{self.name}: net call quantity {self._net_quantity('call')} < 0 — "
                f"max loss is UNBOUNDED above the highest strike. Not a "
                f"defined-risk structure; per Strategy.md the thesis must defer."
            )

        rng = random.Random(seed)
        S0 = self.underlying_price
        T = self.days_to_expiration / 365.0
        # Scan vol from the first leg, used only to widen the range to at least
        # the realistic adverse cone (the expiration payoff itself uses no vol).
        sigma = self.legs[0].option.volatility

        strikes = sorted({leg.option.strike for leg in self.legs})
        # Range guaranteed to reach the flat max-loss zones beyond all strikes —
        # or, for net-short-put structures (no flat zone below), all the way to 0.
        lo_target = 0.0 if self._net_quantity('put') < 0 else min(strikes[0], S0) * 0.5
        hi_target = max(strikes[-1], S0) * 1.5
        if sigma > 0 and T > 0:
            move = sigma * math.sqrt(T) * adverse_move_stdev
            cone_lo = S0 * math.exp(-0.5 * sigma ** 2 * T - move)
            cone_hi = S0 * math.exp(-0.5 * sigma ** 2 * T + move)
        else:
            cone_lo = cone_hi = S0
        low = max(0.0, min(lo_target, cone_lo))
        high = max(hi_target, cone_hi)

        # Pin the range endpoints exactly (see docstring), then sample.
        worst_pnl = min(self.pnl_at_expiration(low), self.pnl_at_expiration(high))
        for _ in range(n_paths):
            S_T = rng.uniform(low, high)
            pnl = self.pnl_at_expiration(S_T)
            if pnl < worst_pnl:
                worst_pnl = pnl

        return max(0.0, -worst_pnl)

    def scenario_pnl_grid(self, reference_price: Optional[float] = None) -> Dict[str, float]:
        """P&L at the 5 standard outcome scenarios per Strategy.md entry
        criterion 4: reference + 10%, +5%, reference, -5%, -10%.

        Args:
            reference_price: the price around which the +/- 5%/10% grid is
                computed. If None, defaults to the underlying_price at entry,
                which is the most common interpretation of "strike" for
                ATM-anchored single-strike structures and the only
                non-ambiguous choice for multi-strike structures (debit/credit
                spreads, iron condors, butterflies). Caller may pass a specific
                strike (e.g., the long-strike for a DCS) if a strike-anchored
                grid is more useful.

        Returns:
            Dict mapping scenario names to P&L values.

        Per cycle 4 critical-eval warning [1]: previous behavior used the
        arithmetic mean of all strikes as the reference, which gave nonsensical
        grids for asymmetric structures (e.g., a DCS 100/105 had +5% scenario
        at 102.5*1.05 = 107.625, well above both strikes). Defaulting to
        underlying_price is unambiguous and matches the natural reading of
        Strategy.md entry criterion 4 for the at-entry P&L scan.
        """
        if reference_price is None:
            reference_price = self.underlying_price

        scenarios = {
            'reference_plus_10pct': reference_price * 1.10,
            'reference_plus_5pct': reference_price * 1.05,
            'reference': reference_price,
            'reference_minus_5pct': reference_price * 0.95,
            'reference_minus_10pct': reference_price * 0.90,
        }

        return {name: round(self.pnl_at_expiration(price), 2)
                for name, price in scenarios.items()}


# =============================================================================
# Structure constructors (only Strategy.md-permitted variants)
# =============================================================================

def long_call(
    underlying_price: float,
    *,
    strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Long call structure.

    Keyword-only arguments after underlying_price for consistency with multi-leg
    constructors and prevention of positional-argument bugs.
    """
    leg = OptionLeg(
        option=ATMOption(
            underlying_price=underlying_price,
            strike=strike,
            days_to_expiration=days_to_expiration,
            risk_free_rate=risk_free_rate,
            volatility=volatility,
            option_type='call',
            dividend_yield=dividend_yield,
        ),
        quantity=contracts,
    )
    return Structure(
        legs=[leg],
        name=f'Long {contracts}x {strike}C {days_to_expiration}DTE',
        structure_type='long_call',
    )


def long_put(
    underlying_price: float,
    *,
    strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Long put structure.

    Keyword-only arguments after underlying_price for consistency with multi-leg
    constructors.
    """
    leg = OptionLeg(
        option=ATMOption(
            underlying_price=underlying_price,
            strike=strike,
            days_to_expiration=days_to_expiration,
            risk_free_rate=risk_free_rate,
            volatility=volatility,
            option_type='put',
            dividend_yield=dividend_yield,
        ),
        quantity=contracts,
    )
    return Structure(
        legs=[leg],
        name=f'Long {contracts}x {strike}P {days_to_expiration}DTE',
        structure_type='long_put',
    )


def debit_call_spread(
    underlying_price: float,
    *,
    long_strike: float,
    short_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility_long: float,
    volatility_short: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Bull call spread: long lower-strike call, short higher-strike call.

    Keyword-only arguments after underlying_price prevent silent argument-order
    bugs (e.g., swapping long_strike and short_strike). Caller must use named
    arguments. Per cycle 4 critical-eval warning [5].
    """
    if long_strike >= short_strike:
        raise ValueError(
            f"Bull call spread requires long_strike < short_strike "
            f"(got long={long_strike}, short={short_strike}). "
            f"For a bear call spread (long > short), use credit_call_spread."
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_long, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_short, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Debit Call Spread {long_strike}/{short_strike} {days_to_expiration}DTE x{contracts}',
        structure_type='debit_call_spread',
    )


def debit_put_spread(
    underlying_price: float,
    *,
    long_strike: float,
    short_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility_long: float,
    volatility_short: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Bear put spread: long higher-strike put, short lower-strike put.

    Keyword-only arguments after underlying_price prevent silent argument-order
    bugs. Caller must use named arguments.
    """
    if long_strike <= short_strike:
        raise ValueError(
            f"Bear put spread requires long_strike > short_strike "
            f"(got long={long_strike}, short={short_strike}). "
            f"For a bull put spread (short > long), use credit_put_spread."
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_long, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_short, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Debit Put Spread {long_strike}/{short_strike} {days_to_expiration}DTE x{contracts}',
        structure_type='debit_put_spread',
    )


def credit_call_spread(
    underlying_price: float,
    *,
    short_strike: float,
    long_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility_short: float,
    volatility_long: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Bear call spread: short lower-strike call, long higher-strike call.

    Keyword-only arguments after underlying_price prevent silent argument-order
    bugs. Caller must use named arguments.
    """
    if short_strike >= long_strike:
        raise ValueError(
            f"Bear call spread requires short_strike < long_strike "
            f"(got short={short_strike}, long={long_strike}). "
            f"For a bull call spread (long < short), use debit_call_spread."
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_short, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_long, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Credit Call Spread {short_strike}/{long_strike} {days_to_expiration}DTE x{contracts}',
        structure_type='credit_call_spread',
    )


def credit_put_spread(
    underlying_price: float,
    *,
    short_strike: float,
    long_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    volatility_short: float,
    volatility_long: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Bull put spread: short higher-strike put, long lower-strike put.

    Keyword-only arguments after underlying_price prevent silent argument-order
    bugs. Caller must use named arguments.
    """
    if short_strike <= long_strike:
        raise ValueError(
            f"Bull put spread requires short_strike > long_strike "
            f"(got short={short_strike}, long={long_strike}). "
            f"For a bear put spread (long > short), use debit_put_spread."
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_short, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=volatility_long, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Credit Put Spread {short_strike}/{long_strike} {days_to_expiration}DTE x{contracts}',
        structure_type='credit_put_spread',
    )


def iron_condor(
    underlying_price: float,
    *,
    long_put_strike: float,
    short_put_strike: float,
    short_call_strike: float,
    long_call_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    vol_long_put: float,
    vol_short_put: float,
    vol_short_call: float,
    vol_long_call: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Iron condor: long lower put, short higher put, short lower call, long higher call.
    Strike order: long_put < short_put < short_call < long_call.

    Keyword-only arguments after underlying_price prevent silent argument-order bugs.
    """
    strikes = [long_put_strike, short_put_strike, short_call_strike, long_call_strike]
    if not (long_put_strike < short_put_strike < short_call_strike < long_call_strike):
        raise ValueError(
            f"Iron condor requires strict ordering: "
            f"long_put({long_put_strike}) < short_put({short_put_strike}) "
            f"< short_call({short_call_strike}) < long_call({long_call_strike})"
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_put_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_long_put, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_put_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_short_put, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=short_call_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_short_call, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=-contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=long_call_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_long_call, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Iron Condor {long_put_strike}/{short_put_strike}/{short_call_strike}/{long_call_strike} '
             f'{days_to_expiration}DTE x{contracts}',
        structure_type='iron_condor',
    )


def long_call_butterfly(
    underlying_price: float,
    *,
    lower_strike: float,
    middle_strike: float,
    upper_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    vol_lower: float,
    vol_middle: float,
    vol_upper: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Long call butterfly: long 1 lower call, short 2 middle calls, long 1 upper call.
    Strikes must be equidistant: middle - lower = upper - middle.

    Keyword-only arguments after underlying_price prevent silent argument-order bugs.
    """
    if not math.isclose(middle_strike - lower_strike, upper_strike - middle_strike, abs_tol=0.01):
        raise ValueError(
            f"Butterfly requires equidistant strikes: "
            f"middle - lower ({middle_strike - lower_strike}) "
            f"!= upper - middle ({upper_strike - middle_strike})"
        )
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=lower_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_lower, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=middle_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_middle, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=-2 * contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=upper_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_upper, option_type='call',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Long Call Butterfly {lower_strike}/{middle_strike}/{upper_strike} '
             f'{days_to_expiration}DTE x{contracts}',
        structure_type='long_call_butterfly',
    )


def long_put_butterfly(
    underlying_price: float,
    *,
    lower_strike: float,
    middle_strike: float,
    upper_strike: float,
    days_to_expiration: int,
    risk_free_rate: float,
    vol_lower: float,
    vol_middle: float,
    vol_upper: float,
    contracts: int = 1,
    dividend_yield: float = 0.0,
) -> Structure:
    """Long put butterfly: long 1 upper put, short 2 middle puts, long 1 lower put.
    Strikes must be equidistant.

    Keyword-only arguments after underlying_price prevent silent argument-order bugs.
    """
    if not math.isclose(middle_strike - lower_strike, upper_strike - middle_strike, abs_tol=0.01):
        raise ValueError("Butterfly requires equidistant strikes")
    legs = [
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=lower_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_lower, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=middle_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_middle, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=-2 * contracts,
        ),
        OptionLeg(
            option=ATMOption(
                underlying_price=underlying_price, strike=upper_strike,
                days_to_expiration=days_to_expiration, risk_free_rate=risk_free_rate,
                volatility=vol_upper, option_type='put',
                dividend_yield=dividend_yield,
            ),
            quantity=contracts,
        ),
    ]
    return Structure(
        legs=legs,
        name=f'Long Put Butterfly {lower_strike}/{middle_strike}/{upper_strike} '
             f'{days_to_expiration}DTE x{contracts}',
        structure_type='long_put_butterfly',
    )


# =============================================================================
# Verification and sizing
# =============================================================================

class MaxLossDualPathDisagreement(Exception):
    """Raised when closed-form and Monte Carlo max-loss disagree by more than
    the tolerance. Per Strategy.md rev 19, this defers the thesis."""
    pass


def verify_max_loss_dual_path(
    closed_form_loss: float,
    monte_carlo_loss: float,
    tolerance: float = 1.00,
) -> None:
    """Per Strategy.md rev 19 dual-path verification clause. Raises
    MaxLossDualPathDisagreement if the two paths disagree by more than
    `tolerance` ($1.00 default per Strategy.md).
    """
    diff = abs(closed_form_loss - monte_carlo_loss)
    if diff > tolerance:
        raise MaxLossDualPathDisagreement(
            f"Max-loss dual-path verification failed: "
            f"closed-form={closed_form_loss:.4f}, monte_carlo={monte_carlo_loss:.4f}, "
            f"diff={diff:.4f}, tolerance={tolerance:.4f}. "
            f"Per Strategy.md rev 19, thesis must defer."
        )


def cascade_max_loss(
    structure: Structure,
    underlying_price: float,
    days_to_expiration: int,
    implied_move_full_horizon: float,
) -> float:
    """Compute early-assignment cascade max loss per Strategy.md rev 20.

    Conventions (rev 20 pinned):
    - Mark-to-market reference point: at the assignment instant.
    - Implied-move horizon for the 2x scaling: full structure expiration
      horizon (i.e., 2× the at-entry implied-move computed for the underlying
      through the structure's expiration).
    - Multi-expiration variants excluded (enforced in Structure.__post_init__).

    For structures with short legs, this estimates the worst-case loss if a
    short leg is assigned at the worst-plausible-adverse mark and the operator
    closes the resulting equity exposure immediately at that mark.

    Returns positive number = magnitude of cascade max loss in dollars.
    """
    # Identify short legs
    short_legs = [leg for leg in structure.legs if leg.quantity < 0]
    long_legs = [leg for leg in structure.legs if leg.quantity > 0]

    if not short_legs:
        # Long-options-only structure: no early assignment possible
        return 0.0  # Cascade not applicable; max_loss_closed_form is the bound

    # 2x implied-move scaled to full structure expiration
    adverse_move_pct = 2.0 * implied_move_full_horizon

    # Compute worst-case loss: at the assignment instant, the underlying has
    # moved adversely by 2x the implied move, the short leg is assigned, the
    # operator closes the resulting equity exposure at that adverse mark.
    # The long leg is assumed held to expiration (per rev 20 convention).
    #
    # For a short leg of quantity Q (Q<0) at strike K_short, type T_short:
    # - If T_short = call and assigned: operator delivers 100*|Q| shares at K_short,
    #   buying at adverse-up-mark = S0*(1+adverse_move_pct).
    #   Loss per contract = (S0*(1+adverse_move_pct) - K_short) * 100  [if positive]
    # - If T_short = put and assigned: operator buys 100*|Q| shares at K_short,
    #   selling at adverse-down-mark = S0*(1-adverse_move_pct).
    #   Loss per contract = (K_short - S0*(1-adverse_move_pct)) * 100  [if positive]
    #
    # The long leg is held to expiration. At expiration, with the underlying
    # having moved adversely (still at S0*(1+/-adverse_move_pct)), the long
    # leg's payoff at expiration partially offsets.

    worst_cascade_loss = 0.0

    for short_leg in short_legs:
        K_short = short_leg.option.strike
        n_short = abs(short_leg.quantity)

        if short_leg.option.option_type == 'call':
            # Adverse direction is UP (short call gets assigned ITM)
            adverse_mark = underlying_price * (1.0 + adverse_move_pct)
            # Cost to deliver shares: buy at adverse_mark, sell at K_short
            assignment_loss_per_contract = max(adverse_mark - K_short, 0.0) * CONTRACT_MULTIPLIER
            # Long-leg payoff at expiration assuming underlying stays at adverse_mark
            long_payoff_at_adverse = sum(
                leg.payoff_at_expiration(adverse_mark) for leg in long_legs
            )
            # Net cascade loss = assignment loss - long leg gains - net debit paid
            # (debit paid was already used for entry; we count it as part of total loss)
            # Per the convention: long leg is "held to expiration" so gains are realized
            cascade_loss = (
                assignment_loss_per_contract * n_short
                - long_payoff_at_adverse
                + structure.net_debit()  # add back debit if positive (we paid it)
            )

        else:  # put
            # Adverse direction is DOWN (short put gets assigned ITM)
            adverse_mark = underlying_price * (1.0 - adverse_move_pct)
            adverse_mark = max(adverse_mark, 0.001)  # underlying floored at near-zero
            assignment_loss_per_contract = max(K_short - adverse_mark, 0.0) * CONTRACT_MULTIPLIER
            long_payoff_at_adverse = sum(
                leg.payoff_at_expiration(adverse_mark) for leg in long_legs
            )
            cascade_loss = (
                assignment_loss_per_contract * n_short
                - long_payoff_at_adverse
                + structure.net_debit()
            )

        if cascade_loss > worst_cascade_loss:
            worst_cascade_loss = cascade_loss

    return max(0.0, worst_cascade_loss)


def size_position(
    max_loss_per_contract: float,
    strategy_nav: float,
    max_pct_nav: float = 0.02,
) -> Tuple[int, bool]:
    """Compute integer contract count for 2% NAV cap.

    Returns (contracts, defer_flag).
    - If defer_flag = True, no integer contract count fits within max_pct_nav.
      Per Strategy.md, the thesis defers; portfolio remains in SGOV.
    - If defer_flag = False, contracts is the largest integer count where
      contracts * max_loss_per_contract <= max_pct_nav * strategy_nav.

    Raises ValueError if max_loss_per_contract <= 0 (no real options structure
    has zero or negative max loss; a zero indicates an upstream computational
    bug, not a sizing edge case). Per cycle 4 critical-eval warning [2].
    """
    if max_loss_per_contract <= 0:
        raise ValueError(
            f"max_loss_per_contract = {max_loss_per_contract} (must be > 0). "
            f"Real options structures have positive max loss; a zero or negative "
            f"value indicates an upstream computational bug. Defer the thesis "
            f"and audit the max-loss computation rather than treating this as "
            f"a sizing edge case."
        )

    nav_cap = strategy_nav * max_pct_nav
    # Small epsilon so an exact integer multiple (cap == N * loss) doesn't drop
    # to N-1 from binary floating-point representation error.
    contracts = math.floor(nav_cap / max_loss_per_contract + 1e-9)

    if contracts < 1:
        return (0, True)  # Defer

    return (contracts, False)


def realized_volatility_30d(
    daily_close_prices: List[float],
) -> float:
    """Compute 30-day realized volatility from trailing daily closing prices.
    Returns annualized vol (decimal).

    Windowing: uses the most recent 31 closes (→ 30 log returns). Earlier
    behaviour ignored the window entirely and used the whole input series, so a
    longer history silently produced the wrong realized-vol figure; the trailing
    slice is now applied here rather than left to the caller. If fewer than 31
    prices are supplied, all available are used (>= 2 required).

    Annualization: trading-day log-return vol is scaled by sqrt(252) — the
    number of trading-day RETURNS per year. This is correct even though
    price_bsm uses T = days/365: a calendar year holds ~252 trading-day returns,
    so an option's implied vol (annualized) corresponds to daily_vol * sqrt(252),
    NOT sqrt(365). Annualizing realized vol by sqrt(365) over-states it by
    sqrt(365/252) ≈ 1.20x and makes IV look cheap vs realized. BSM's day-count
    governs time-decay discounting, a separate quantity from vol annualization.
    """
    if len(daily_close_prices) < 2:
        raise ValueError("Need at least 2 prices for vol calc")

    # Trailing 30-day window: the last 31 prices yield 30 returns.
    window = daily_close_prices[-31:]

    log_returns = []
    for i in range(1, len(window)):
        log_returns.append(math.log(window[i] / window[i - 1]))

    n = len(log_returns)
    mean_lr = sum(log_returns) / n
    variance = sum((lr - mean_lr) ** 2 for lr in log_returns) / (n - 1)
    daily_vol = math.sqrt(variance)
    # Annualize trading-day return vol by sqrt(252) (trading-day returns/year).
    annualized_vol = daily_vol * math.sqrt(252)
    return annualized_vol


def probability_weighted_payoff(
    structure: Structure,
    n_paths: int = 100000,
    seed: Optional[int] = 42,
) -> Dict[str, float]:
    """Compute probability-weighted payoff using market-implied risk-neutral
    distribution (lognormal under BSM with the structure's IV).

    Per Strategy.md: "with the explicit caveat that these probabilities are
    price-derived, not Claude-forecasted, per 2.13."

    Returns dict with: expected_payoff, expected_pnl, prob_profit, prob_max_loss,
    note.
    """
    rng = random.Random(seed)
    S0 = structure.underlying_price
    T = structure.days_to_expiration / 365.0
    sigma = structure.legs[0].option.volatility
    r = structure.legs[0].option.risk_free_rate
    q = structure.legs[0].option.dividend_yield

    # Risk-neutral drift = r - q
    drift = r - q

    payoffs = []
    pnls = []
    for _ in range(n_paths):
        z = rng.gauss(0, 1)
        S_T = S0 * math.exp((drift - 0.5 * sigma ** 2) * T + sigma * math.sqrt(T) * z)
        payoff = structure.payoff_at_expiration(S_T)
        pnl = payoff - structure.net_debit()
        payoffs.append(payoff)
        pnls.append(pnl)

    expected_payoff = sum(payoffs) / n_paths
    expected_pnl = sum(pnls) / n_paths
    prob_profit = sum(1 for pnl in pnls if pnl > 0) / n_paths
    # Probability of realizing (within $0.01 of) the structure's defined max loss.
    max_loss = structure.max_loss_closed_form()
    prob_max_loss = sum(1 for pnl in pnls if pnl <= -(max_loss - 0.01)) / n_paths

    return {
        'expected_payoff': round(expected_payoff, 4),
        'expected_pnl': round(expected_pnl, 4),
        'prob_profit': round(prob_profit, 4),
        'prob_max_loss': round(prob_max_loss, 4),
        'note': 'Probabilities are market-implied (price-derived), not Claude-forecasted (per 2.13).',
    }


# =============================================================================
# Self-test
# =============================================================================

if __name__ == '__main__':
    print("=" * 70)
    print("Strategy C Options-Math Scaffolding — Self-Test")
    print("=" * 70)

    # Test 1: Basic BSM call price (well-known textbook case)
    # Hull example: S=42, K=40, r=0.10, T=0.5, sigma=0.20 → Call = 4.7594
    test_opt = ATMOption(
        underlying_price=42, strike=40, days_to_expiration=int(0.5 * 365),
        risk_free_rate=0.10, volatility=0.20, option_type='call',
    )
    p = price_bsm(test_opt)
    print(f"\n[1] BSM call price (Hull textbook): {p:.4f} (expected ~4.7594)")
    assert abs(p - 4.7594) < 0.01, f"BSM price mismatch: {p}"

    # Test 2: Put-call parity
    call_opt = ATMOption(
        underlying_price=100, strike=100, days_to_expiration=30,
        risk_free_rate=0.045, volatility=0.30, option_type='call',
    )
    put_opt = ATMOption(
        underlying_price=100, strike=100, days_to_expiration=30,
        risk_free_rate=0.045, volatility=0.30, option_type='put',
    )
    c = price_bsm(call_opt)
    p_ = price_bsm(put_opt)
    # Put-call parity: C - P = S - K*e^(-rT)
    parity_lhs = c - p_
    parity_rhs = 100 - 100 * math.exp(-0.045 * 30 / 365)
    print(f"\n[2] Put-call parity: C - P = {parity_lhs:.4f}, S - Ke^(-rT) = {parity_rhs:.4f}")
    assert abs(parity_lhs - parity_rhs) < 0.001, "Put-call parity violated"

    # Test 3: Greeks signs
    g_call = greeks_bsm(call_opt)
    g_put = greeks_bsm(put_opt)
    print(f"\n[3] Greeks signs check:")
    print(f"    Call delta = {g_call['delta']:.4f} (expected 0..1)")
    print(f"    Put delta = {g_put['delta']:.4f} (expected -1..0)")
    print(f"    Call gamma = {g_call['gamma']:.6f} (expected positive)")
    print(f"    Put gamma = {g_put['gamma']:.6f} (expected positive, equal to call's)")
    print(f"    Call theta = {g_call['theta']:.4f} (expected negative)")
    print(f"    Put theta = {g_put['theta']:.4f} (expected negative)")
    print(f"    Call vega = {g_call['vega']:.4f} (expected positive)")
    print(f"    Put vega = {g_put['vega']:.4f} (expected positive, equal to call's)")
    assert 0 < g_call['delta'] < 1
    assert -1 < g_put['delta'] < 0
    assert g_call['gamma'] > 0
    assert abs(g_call['gamma'] - g_put['gamma']) < 1e-10
    assert g_call['theta'] < 0
    assert g_put['theta'] < 0
    assert g_call['vega'] > 0
    assert abs(g_call['vega'] - g_put['vega']) < 1e-10

    # Test 4: Implied vol round-trip
    target_iv = 0.35
    test_opt2 = ATMOption(
        underlying_price=100, strike=100, days_to_expiration=30,
        risk_free_rate=0.045, volatility=target_iv, option_type='call',
    )
    target_price = price_bsm(test_opt2)
    solved_iv = implied_vol(target_price, 100, 100, 30, 0.045, 'call')
    print(f"\n[4] IV round-trip: target={target_iv:.4f}, solved={solved_iv:.4f}")
    assert solved_iv is not None and abs(solved_iv - target_iv) < 1e-4

    # Test 5: Long call structure max loss = premium paid
    lc = long_call(
        100,  # underlying_price
        strike=100, days_to_expiration=30,
        risk_free_rate=0.045, volatility=0.30, contracts=1,
    )
    debit = lc.net_debit()
    max_loss_cf = lc.max_loss_closed_form()
    print(f"\n[5] Long call: net debit = {debit:.4f}, max loss closed-form = {max_loss_cf:.4f}")
    print(f"    (Max loss should equal net debit for long-only structures)")
    assert abs(debit - max_loss_cf) < 0.01, f"Max loss mismatch: debit={debit}, max_loss={max_loss_cf}"

    # Test 6: Debit call spread max loss = net debit, max profit = (long-short width) - debit
    dcs = debit_call_spread(
        100,  # underlying_price
        long_strike=100, short_strike=105,
        days_to_expiration=30, risk_free_rate=0.045,
        volatility_long=0.30, volatility_short=0.28, contracts=1,
    )
    debit_spread = dcs.net_debit()
    max_loss_dcs = dcs.max_loss_closed_form()
    print(f"\n[6] Debit call spread 100/105: net debit = {debit_spread:.4f}, "
          f"max loss = {max_loss_dcs:.4f} (expected = net debit)")
    assert abs(debit_spread - max_loss_dcs) < 0.01

    # Max profit at S=105+: payoff = (105-100)*100 = 500, minus debit
    max_profit_at_high = dcs.pnl_at_expiration(110)
    expected_max_profit = 5 * 100 - debit_spread
    print(f"    Max profit at S=110: {max_profit_at_high:.4f}, expected {expected_max_profit:.4f}")
    assert abs(max_profit_at_high - expected_max_profit) < 0.01

    # Test 7: Iron condor max loss (well-known closed form)
    # Symmetric IC: long 90 put / short 95 put / short 105 call / long 110 call
    # Wing widths = 5; expected max loss = (5*100) - net credit (where net credit = -net_debit)
    ic = iron_condor(
        100,  # underlying_price
        long_put_strike=90, short_put_strike=95,
        short_call_strike=105, long_call_strike=110,
        days_to_expiration=30, risk_free_rate=0.045,
        vol_long_put=0.30, vol_short_put=0.30,
        vol_short_call=0.30, vol_long_call=0.30,
        contracts=1,
    )
    ic_debit = ic.net_debit()  # negative for credit structure
    ic_credit = -ic_debit
    ic_max_loss = ic.max_loss_closed_form()
    expected_ic_max_loss = 5 * 100 - ic_credit
    print(f"\n[7] Iron condor 90/95/105/110: net credit = {ic_credit:.4f}, "
          f"max loss = {ic_max_loss:.4f}, expected = {expected_ic_max_loss:.4f}")
    assert abs(ic_max_loss - expected_ic_max_loss) < 0.01

    # Test 8: Dual-path verification
    cf_loss = ic.max_loss_closed_form()
    mc_loss = ic.max_loss_monte_carlo(n_paths=50000)
    print(f"\n[8] Dual-path: closed-form = {cf_loss:.4f}, Monte Carlo = {mc_loss:.4f}")
    try:
        verify_max_loss_dual_path(cf_loss, mc_loss, tolerance=1.00)
        print(f"    PASS: agreed within $1 tolerance")
    except MaxLossDualPathDisagreement as e:
        print(f"    FAIL: {e}")
        raise

    # Test 9: Cascade max loss for credit put spread
    cps = credit_put_spread(
        100,  # underlying_price
        short_strike=95, long_strike=90,
        days_to_expiration=30, risk_free_rate=0.045,
        volatility_short=0.30, volatility_long=0.30, contracts=1,
    )
    cps_credit = -cps.net_debit()
    cps_cf_loss = cps.max_loss_closed_form()
    cps_cascade = cascade_max_loss(cps, 100, 30, implied_move_full_horizon=0.05)
    print(f"\n[9] Credit put spread 95/90: net credit = {cps_credit:.4f}, "
          f"closed-form max loss = {cps_cf_loss:.4f}, cascade max loss = {cps_cascade:.4f}")
    print(f"    Total bound max loss = max of two = {max(cps_cf_loss, cps_cascade):.4f}")

    # Test 10: Position sizing with deferral and zero-max-loss rejection
    contracts_ok, defer_ok = size_position(50.0, 1389.37, 0.02)
    print(f"\n[10] Sizing $50/contract @ $1389.37 NAV @ 2%: {contracts_ok} contracts, "
          f"defer = {defer_ok}")
    assert contracts_ok == 0 and defer_ok is True, "Should defer"

    contracts_ok2, defer_ok2 = size_position(20.0, 1389.37, 0.02)
    print(f"     Sizing $20/contract @ $1389.37 NAV @ 2%: {contracts_ok2} contracts, "
          f"defer = {defer_ok2}")
    assert contracts_ok2 == 1 and defer_ok2 is False, "Should fit 1 contract"

    # Defensive: zero or negative max_loss raises (no real options structure has this)
    try:
        size_position(0, 1389.37, 0.02)
        print(f"     FAIL: zero max-loss should raise ValueError")
        raise AssertionError("Zero max-loss did not raise")
    except ValueError as e:
        print(f"     PASS: zero max-loss correctly raises: {str(e)[:80]}...")

    # Test 11: Realized volatility
    # Synthesize a price series with a known annualized sigma = 0.30 on the
    # trading-day basis, i.e. daily vol = 0.30 / sqrt(252). The function should
    # recover ~0.30, since it annualizes trading-day return vol by sqrt(252)
    # (the count of trading-day returns per year — see the function docstring).
    rng = random.Random(42)
    prices = [100.0]
    sigma_annual = 0.30
    daily_vol = sigma_annual / math.sqrt(252)
    for _ in range(200):
        z = rng.gauss(0, 1)
        prices.append(prices[-1] * math.exp(-0.5 * daily_vol**2 + daily_vol * z))
    rv = realized_volatility_30d(prices)
    print(f"\n[11] Realized vol from synthetic series with annualized sigma=0.30: {rv:.4f}")
    print(f"    (Should be ~0.30; realized vol annualizes trading-day vol by sqrt(252))")
    # Only the trailing 30 returns are used now, so sampling error is wider
    # (~1/sqrt(2*29) ≈ 13%); tolerance 0.10.
    assert abs(rv - sigma_annual) < 0.10, f"Realized vol off: got {rv}, expected ~{sigma_annual}"

    # Test 12: Multi-expiration rejection
    print(f"\n[12] Multi-expiration rejection test:")
    try:
        bad_legs = [
            OptionLeg(option=ATMOption(100, 100, 30, 0.045, 0.30, 'call'), quantity=1),
            OptionLeg(option=ATMOption(100, 100, 60, 0.045, 0.30, 'call'), quantity=-1),
        ]
        bad_struct = Structure(legs=bad_legs, name='Calendar', structure_type='calendar')
        print(f"    FAIL: should have raised NotImplementedError")
        raise AssertionError("Multi-expiration was not rejected")
    except NotImplementedError as e:
        print(f"    PASS: rejected with: {str(e)[:120]}...")

    # Test 13: Probability-weighted payoff
    pwp = probability_weighted_payoff(dcs, n_paths=20000)
    print(f"\n[13] Probability-weighted payoff for 100/105 debit call spread:")
    for k, v in pwp.items():
        print(f"     {k}: {v}")

    # Test 14: Scenario PnL grid
    grid = dcs.scenario_pnl_grid()
    print(f"\n[14] Scenario PnL grid for 100/105 debit call spread:")
    for k, v in grid.items():
        print(f"     {k}: ${v}")

    # Test 15: Unbounded-max-loss rejection (net short calls). A naked short
    # call and a 1x2 ratio call spread have UNBOUNDED loss; both max-loss paths
    # must refuse rather than return a finite, silently understated number.
    print(f"\n[15] Unbounded-risk rejection (net short calls):")
    naked_call = Structure(
        legs=[OptionLeg(option=ATMOption(100, 105, 30, 0.045, 0.30, 'call'), quantity=-1)],
        name='Naked short call', structure_type='naked_call')
    ratio_spread = Structure(
        legs=[OptionLeg(option=ATMOption(100, 100, 30, 0.045, 0.30, 'call'), quantity=1),
              OptionLeg(option=ATMOption(100, 110, 30, 0.045, 0.30, 'call'), quantity=-2)],
        name='1x2 ratio call spread', structure_type='ratio_call_spread')
    for bad in (naked_call, ratio_spread):
        for method in ('max_loss_closed_form', 'max_loss_monte_carlo'):
            try:
                getattr(bad, method)()
                raise AssertionError(f"{bad.name}.{method} did not raise UnboundedMaxLossError")
            except UnboundedMaxLossError:
                pass
        print(f"    PASS: {bad.name} rejected by both max-loss paths")

    # Test 16: Net-short-PUT structures are bounded (worst case at S=0) and the
    # two max-loss paths must agree there (MC range extends to 0 for these).
    naked_put = Structure(
        legs=[OptionLeg(option=ATMOption(100, 95, 30, 0.045, 0.30, 'put'), quantity=-1)],
        name='Naked short put', structure_type='naked_put')
    np_cf = naked_put.max_loss_closed_form()
    np_mc = naked_put.max_loss_monte_carlo(n_paths=50000)
    np_expected = 95 * CONTRACT_MULTIPLIER - (-naked_put.net_debit())
    print(f"\n[16] Naked short put 95: closed-form = {np_cf:.4f}, MC = {np_mc:.4f}, "
          f"expected (K*100 - credit) = {np_expected:.4f}")
    assert abs(np_cf - np_expected) < 0.01, f"closed-form missed the S=0 worst case: {np_cf}"
    verify_max_loss_dual_path(np_cf, np_mc, tolerance=1.00)
    print(f"    PASS: S=0 worst case captured; dual paths agree within $1")

    print("\n" + "=" * 70)
    print("ALL SELF-TESTS PASSED")
    print("=" * 70)

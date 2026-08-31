"""
strategy_math.strategy_e — Strategy E (market-neutral narrative-divergence pairs)
mechanical rules. Source: strategy/07_strategy_e.md (GENERATED from Strategy.md).
"""

from __future__ import annotations

from .common import days_between, ols_regression, pearson_correlation, require_finite_positive

# Entry criterion 3 — "L-S correlation over trailing 252 trading days >= 0.5"
MIN_PAIR_CORRELATION_ENTRY = 0.5

# Exit — "Correlation breakdown: rolling 60-day correlation... falls below 0.3"
CORRELATION_BREAKDOWN_THRESHOLD = 0.3

# Exit — "Time-based exit at 6 months from entry" (approximated as 182 days per the
# spec's own 1-6 month holding-period framing; 6 calendar months ~= 182-183 days)
TIME_EXIT_DAYS = 182

# Entry criterion 5 — "financing cost... is <= 15% of thesis expected return"
MAX_FINANCING_COST_PCT_OF_EXPECTED_RETURN = 0.15


def pair_correlation_qualifies(l_returns: list[float], s_returns: list[float]) -> bool:
    """Entry criterion 3: L-S correlation over the trailing 252 trading days must be
    >= 0.5. strategy/07_strategy_e.md: "pairs with lower correlation are not pairs —
    they are two independent bets." Caller passes exactly 252 trading days of paired
    daily returns.
    """
    return pearson_correlation(l_returns, s_returns) >= MIN_PAIR_CORRELATION_ENTRY


def correlation_breakdown(l_returns_60d: list[float], s_returns_60d: list[float]) -> bool:
    """Exit rule: rolling 60-day L-S correlation falling below 0.3 means "the pair
    relationship has broken; thesis is no longer market-neutral." Caller passes the
    trailing 60 trading days of paired daily returns.
    """
    return pearson_correlation(l_returns_60d, s_returns_60d) < CORRELATION_BREAKDOWN_THRESHOLD


def hedge_ratio(l_returns: list[float], s_returns: list[float]) -> float:
    """Beta-adjusted leg sizing (Classical-method delegation): "regression L returns
    on S returns, use hedge ratio" — the OLS slope of L on S, used to size the short
    leg relative to the long leg when L and S have materially different volatilities.
    """
    return ols_regression(y=l_returns, x=s_returns).beta


def financing_cost_ok(
    borrow_rate_annualized: float,
    position_size_dollars: float,
    expected_holding_period_days: float,
    thesis_expected_return_dollars: float,
) -> bool:
    """Entry criterion 5: "Short-financing cost for the S leg (borrow rate x position
    size x expected holding period) is computed by code and is <= 15% of thesis
    expected return — otherwise financing eats the alpha." Financing cost is
    annualized borrow rate pro-rated over the expected holding period (days/365).

    NUMERICS HARDENING (2026-08-31, owner-authorized code-quality pass): `borrow_rate_
    annualized`, `position_size_dollars`, and `expected_holding_period_days` previously
    flowed into the financing_cost formula completely unvalidated. A sign-flipped input
    on any of the three (e.g. a negative borrow rate reaching this function from an
    upstream data/arithmetic bug — this repo has hit exactly this bug class before at
    the SQL layer, see CLAUDE.md's "one dbt sign error stranded EVERY branch") silently
    flipped this gate from correctly BLOCKING an entry to wrongly PASSING it, with no
    error raised anywhere. All three are now required to be finite and non-negative
    (a value of exactly 0 — e.g. a same-day flip's `expected_holding_period_days=0`, or
    a genuinely free borrow — is not itself invalid, only a negative or non-finite one
    is), mirroring `thesis_expected_return_dollars`'s pre-existing guard below.
    """
    # NUMERICS HARDENING (2026-08-31): require_finite_positive also rejects NaN/inf,
    # not just <= 0 -- see that function's docstring.
    require_finite_positive(
        thesis_expected_return_dollars, "thesis_expected_return_dollars",
        detail="A non-positive expected return means there is no expected alpha for financing to eat.",
    )
    require_finite_positive(borrow_rate_annualized, "borrow_rate_annualized", allow_zero=True)
    require_finite_positive(position_size_dollars, "position_size_dollars", allow_zero=True)
    require_finite_positive(
        expected_holding_period_days, "expected_holding_period_days", allow_zero=True)
    financing_cost = borrow_rate_annualized * position_size_dollars * (expected_holding_period_days / 365.0)
    return (financing_cost / thesis_expected_return_dollars) <= MAX_FINANCING_COST_PCT_OF_EXPECTED_RETURN


def time_exit_triggered(entry_date, as_of_date) -> bool:
    """Exit rule: "Time-based exit at 6 months from entry: thesis is stale;
    short-financing costs accumulating; exit regardless of P&L."
    """
    return days_between(entry_date, as_of_date) >= TIME_EXIT_DAYS

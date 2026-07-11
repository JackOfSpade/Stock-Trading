"""
strategy_math.common — shared numeric primitives used across strategies A/B/D/E.

Position sizing (2% of strategy portfolio, Strategy.md universal rule) and the
correlation/regression math D (correlation buckets, beta-adjusted alpha) and E
(pair correlation, hedge-ratio leg sizing) both need. Pure stdlib.
"""

from __future__ import annotations

import math
from dataclasses import dataclass


def position_size_dollars(sub_portfolio_nav: float, pct: float = 0.02) -> float:
    """2%-of-strategy-portfolio position sizing (Strategy.md universal rule,
    reaffirmed per-strategy in every A/B/D/E Instrument eligibility rule section).
    `sub_portfolio_nav` is the STRATEGY's own sub-portfolio NAV (analytics.strategy_nav
    .sizing_base_2pct upstream), never whole-account net-liquidation — Operating_
    Protocols.md's "Sizing and analysis on live data" tripwire.
    """
    if sub_portfolio_nav <= 0:
        raise ValueError(f"sub_portfolio_nav = {sub_portfolio_nav} (must be > 0).")
    if not (0 < pct <= 1):
        raise ValueError(f"pct = {pct} (must be in (0, 1]).")
    return sub_portfolio_nav * pct


def pearson_correlation(x: list[float], y: list[float]) -> float:
    """Pearson correlation coefficient over paired return series (trailing-window
    correlation — Strategy D's >0.6 correlation-bucket test, Strategy E's L/S pair
    correlation >=0.5 entry / <0.3 breakdown tests). Both series must be equal length
    and represent the SAME trailing window (e.g. 252 trading days of daily returns).
    """
    n = len(x)
    if n != len(y):
        raise ValueError(f"x and y must be equal length (got {n} and {len(y)}).")
    if n < 2:
        raise ValueError(f"need at least 2 observations to compute correlation (got {n}).")
    mean_x = sum(x) / n
    mean_y = sum(y) / n
    cov = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, y))
    var_x = sum((xi - mean_x) ** 2 for xi in x)
    var_y = sum((yi - mean_y) ** 2 for yi in y)
    denom = math.sqrt(var_x * var_y)
    if denom == 0:
        return 0.0
    return cov / denom


@dataclass(frozen=True)
class RegressionResult:
    """OLS y = alpha + beta*x, plus the standard error on alpha (the intercept) —
    Strategy D's rev-30 CI-gated beta-adjusted-alpha test needs the SE to build its
    95% upper confidence bound, not just the point estimate.
    """
    beta: float
    alpha: float
    alpha_se: float
    n: int


def ols_regression(y: list[float], x: list[float]) -> RegressionResult:
    """Simple OLS regression of y on x (e.g. strategy monthly returns on SPY monthly
    returns — Strategy D's beta-adjusted-alpha test; Strategy E's hedge-ratio leg
    sizing, L returns regressed on S returns). Closed-form (no matrix libs needed for
    single-predictor OLS): beta = Cov(x,y)/Var(x), alpha = mean(y) - beta*mean(x).
    alpha_se uses the standard simple-linear-regression intercept standard-error
    formula: SE(alpha) = s * sqrt(1/n + mean_x^2/Sxx), where s is the residual
    standard error and Sxx = sum((x_i - mean_x)^2).
    """
    n = len(x)
    if n != len(y):
        raise ValueError(f"x and y must be equal length (got {n} and {len(y)}).")
    if n < 3:
        # need >=3 to have a meaningful residual-based SE (n-2 degrees of freedom)
        raise ValueError(f"need at least 3 observations for a regression with SE (got {n}).")
    mean_x = sum(x) / n
    mean_y = sum(y) / n
    sxx = sum((xi - mean_x) ** 2 for xi in x)
    if sxx == 0:
        raise ValueError("x has zero variance — cannot regress (all observations identical).")
    sxy = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, y))
    beta = sxy / sxx
    alpha = mean_y - beta * mean_x
    residuals = [yi - (alpha + beta * xi) for xi, yi in zip(x, y)]
    ss_res = sum(r * r for r in residuals)
    dof = n - 2
    s2 = ss_res / dof if dof > 0 else 0.0
    s = math.sqrt(s2)
    alpha_se = s * math.sqrt(1.0 / n + (mean_x ** 2) / sxx)
    return RegressionResult(beta=beta, alpha=alpha, alpha_se=alpha_se, n=n)


def days_between(start_date, as_of_date) -> int:
    """Calendar days between two date objects (datetime.date or datetime.datetime).
    Used for every strategy's time-based exit/invalidation checks (A's 12-month hard
    stop, B's 60-day convergence timeline, E's 6-month time exit). Callers pass
    datetime.date objects — this module does no date PARSING (no implicit "today").
    """
    delta = as_of_date - start_date
    return delta.days

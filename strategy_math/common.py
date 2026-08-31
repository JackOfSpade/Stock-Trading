"""
strategy_math.common — shared numeric primitives used across strategies A/B/D/E.

Position sizing (thesis-scaled risk budgeting per Experiment_Parameters.md rev 18 —
the caller supplies the risk-budget fraction; there is no universal 2% rule as of
Strategy.md Rev 43, owner directive 2026-07-28) and the correlation/regression math
D (correlation buckets, beta-adjusted alpha) and E (pair correlation, hedge-ratio
leg sizing) both need. Pure stdlib.
"""

from __future__ import annotations

import math
from dataclasses import dataclass


def require_finite_positive(
    value: float, name: str, *, allow_zero: bool = False, detail: str = ""
) -> None:
    """Reject a NaN, +/-inf, negative (or, unless `allow_zero`, zero) numeric input
    with a clear, named ValueError.

    NUMERICS HARDENING (2026-08-31, owner-authorized code-quality pass): every
    "must be a positive number" guard in this package used to be a direct one-sided
    float comparison (e.g. `if sub_portfolio_nav <= 0: raise ...`). Python's
    `<`/`<=`/`>`/`>=` are all non-ordering for NaN — `float('nan') <= 0` and
    `float('nan') > 0` are BOTH False — so a bare one-sided guard let a NaN input
    sail straight through instead of being rejected, and the bad value then
    propagated as NaN through whatever sizing/entry math it fed, surfacing (if at
    all) as a cryptic, unattributed crash somewhere downstream instead of a clear
    error at the point of entry. This helper closes that gap once, for every call
    site, instead of hand-adding `math.isfinite(...)` at each one.

    Does not change behavior on any already-valid (finite, in-range) input — only a
    previously-silent-wrong-answer NaN/inf/out-of-range input now raises here.

    c_options_math.py mirrors this as its own local, non-imported
    `_require_finite_positive` — that module deliberately has no shared-module
    dependency (scripts/check_roster_consistency.py's spec_hash_inputs() hashes C
    as [c_options_math.py] alone; importing strategy_math would make that input
    list wrong).
    """
    ok = (value >= 0) if allow_zero else (value > 0)
    if not math.isfinite(value) or not ok:
        bound = ">= 0" if allow_zero else "> 0"
        suffix = f" {detail}" if detail else ""
        raise ValueError(f"{name} = {value} (must be a finite number {bound}).{suffix}")


def position_size_dollars(sub_portfolio_nav: float, pct: float) -> float:
    """Thesis-scaled position sizing: `pct` is THIS THESIS's risk budget as a
    fraction of the strategy's own sub-portfolio NAV.

    `pct` is REQUIRED and has no default (Rev 43, owner directive 2026-07-28).
    It previously defaulted to 0.02 under the retired universal 2% rule; the
    default was removed deliberately so that a caller which forgets to supply a
    budget fails loudly instead of silently reinstating the old flat 2%.

    The caller sets `pct` per Experiment_Parameters.md §Position size: justified
    against the seven-factor list, recorded in the thesis's decision-log entry,
    and adversarially attacked on size as well as direction. Conviction enters as
    an ordinal tier only — never as a probability multiplied into this call
    (AI_Trading_Foundation.md 3a.1, 2.26).

    `sub_portfolio_nav` is the STRATEGY's own sub-portfolio NAV, never whole-account
    net-liquidation — Operating_Protocols.md's "Sizing and analysis on live data"
    tripwire.

    NO SIZING CEILING (owner directive 2026-08-05 — both Rev 43 hard CaR envelopes
    RETIRED). This function previously rejected any `pct` above 0.10, the per-name
    Capital-at-Risk envelope. That rejection is GONE: the per-name <=10% and
    per-strategy deployed <=75% envelopes are both retired, and the AI has complete
    freedom in sizing. The owner's reasoning: this experiment runs no stop-losses, so
    size IS the risk-management lever, and a ceiling the judgment is trusted to set
    should not be second-guessed by a constant in a helper function.

    Do NOT reintroduce a ceiling here. The surviving discipline is procedural, not
    numeric — the seven-factor justification, the mandatory adversarial attack on the
    SIZE as well as the direction, and the per-strategy kill triggers
    (Experiment_Parameters.md §Position size). The `0 < pct <= 1` check below is a
    domain sanity bound (a budget cannot be negative, and cannot exceed the whole
    sub-portfolio), NOT a risk envelope — keep it.
    """
    # NUMERICS HARDENING (2026-08-31): require_finite_positive also rejects NaN/inf,
    # not just <= 0 -- see that function's docstring. The `pct` check just below was
    # already NaN-safe (a chained `0 < pct <= 1` evaluates False, not True, for NaN),
    # so it is unchanged.
    require_finite_positive(sub_portfolio_nav, "sub_portfolio_nav")
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

"""
strategy_math.strategy_d — Strategy D (long-horizon narrative-screened equity core)
mechanical rules. Source: strategy/06_strategy_d.md (GENERATED from Strategy.md).

Includes the rev-30 CI-gated beta-adjusted-alpha edge-decay test — the SAME
methodology this session's Item 10 (bigquery/39_beta_adjusted_alpha.sql) generalized
into the SGOV-relative kill gates; this module is D's OWN spec-defined version of that
math, computed here as the strategy's committed classical-method delegation, distinct
from (but philosophically the same regression as) the cross-strategy SQL component.
"""

from __future__ import annotations

from .common import RegressionResult, ols_regression, pearson_correlation

# Instrument eligibility rule
MIN_MARKET_CAP_USD = 10_000_000_000
MIN_ADV_30D_USD = 20_000_000
MIN_CONCURRENT_POSITIONS = 5  # floor, retained; no ceiling (Rev 35, owner directive)

# Entry criterion 5 — correlation-bucket test
ENTRY_CORRELATION_BUCKET_THRESHOLD = 0.6
POST_ENTRY_CORRELATION_THRESHOLD = 0.7  # rev 28 post-entry monitoring, tighter margin
MAX_POSITIONS_PER_BUCKET = 3

# Mark-to-market underperformance trigger — rev 28/30 beta-adjusted, CI-gated
BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD = -0.03  # "-3pp" point estimate
BETA_ADJUSTED_ALPHA_CI_UPPER_BOUND = 0.0  # "95% upper CI bound on alpha <= 0pp"
ALPHA_TEST_Z_95 = 1.645  # one-sided 95% z (upper-bound test, not two-sided 1.96)

# Metric-immutability auto-invalidation (rev 30) — "2 consecutive quarters"
METRIC_CHANGE_INVALIDATION_QUARTERS = 2


def meets_instrument_eligibility(market_cap_usd: float, adv_30d_usd: float) -> bool:
    """Market cap >= $10B AND 30-day ADV >= $20M — the higher bar than A/B, per
    strategy/06_strategy_d.md: "higher threshold than A/B because D's multi-year
    horizons expose it to more business-risk drift in smaller names."
    """
    return market_cap_usd >= MIN_MARKET_CAP_USD and adv_30d_usd >= MIN_ADV_30D_USD


def correlation_bucket_members(
    candidate_returns: list[float],
    held_positions_returns: dict[str, list[float]],
    threshold: float = ENTRY_CORRELATION_BUCKET_THRESHOLD,
) -> list[str]:
    """Entry criterion 5: which currently-held tickers share a correlation bucket with
    the candidate (trailing-252-day daily-return correlation > threshold). Returns the
    list of held-position tickers that would join the candidate's bucket; the caller
    checks `len(result) + 1 > MAX_POSITIONS_PER_BUCKET` (candidate counts as the +1) to
    decide whether the entry is blocked. strategy/06_strategy_d.md: "for any two
    currently-held positions with trailing-252-day daily-return correlation > 0.6, both
    count toward the same correlation bucket. No more than 3 positions may share any
    correlation bucket."
    """
    return [
        ticker
        for ticker, returns in held_positions_returns.items()
        if pearson_correlation(candidate_returns, returns) > threshold
    ]


def bucket_blocks_entry(bucket_members: list[str], cap: int = MAX_POSITIONS_PER_BUCKET) -> bool:
    """The candidate (counted as the +1) plus its bucket_members must not exceed the
    cap. strategy/06_strategy_d.md Entry criterion 5.
    """
    return (len(bucket_members) + 1) > cap


def post_entry_bucket_pairs(
    held_positions_returns: dict[str, list[float]],
    threshold: float = POST_ENTRY_CORRELATION_THRESHOLD,
) -> list[tuple[str, str]]:
    """rev 28 post-entry monitoring: recomputed monthly across ALL held-position pairs.
    Returns pairs exceeding the tighter 0.7 post-entry threshold — each such pair is
    treated as its own 2-position bucket for the purpose of blocking a FUTURE third
    entry (does not force an exit on the already-held pair). strategy/06_strategy_d.md:
    "If any held-position pair exceeds 0.7 daily-return correlation post-entry... the
    pair is treated as a 2-position correlation bucket for the purposes of subsequent
    entry decisions."
    """
    tickers = sorted(held_positions_returns)
    pairs = []
    for i in range(len(tickers)):
        for j in range(i + 1, len(tickers)):
            a, b = tickers[i], tickers[j]
            if pearson_correlation(held_positions_returns[a], held_positions_returns[b]) > threshold:
                pairs.append((a, b))
    return pairs


class AlphaTestResult:
    """Result of the rev-30 CI-gated beta-adjusted-alpha edge-decay test."""

    __slots__ = ("regression", "upper_ci_95", "fires")

    def __init__(self, regression: RegressionResult, upper_ci_95: float, fires: bool):
        self.regression = regression
        self.upper_ci_95 = upper_ci_95
        self.fires = fires


def beta_adjusted_alpha_test(
    d_monthly_returns: list[float], spy_monthly_returns: list[float]
) -> AlphaTestResult:
    """Strategy D's own mark-to-market underperformance trigger (rolling 24-month,
    beta-adjusted, CI-gated — strategy/06_strategy_d.md Classical-method delegation,
    rev 27/28/30):

    "regress monthly D-deployed-TWR on monthly SPY returns over 24-month window to
    estimate beta_hat; construct synthetic = beta_hat x SPY; alpha = TWR - synthetic;
    ...also compute SE on the alpha estimate via the regression intercept's standard
    error and the 95% upper CI bound; alpha-test fires only when alpha point estimate
    <= -3pp AND 95% upper CI bound on alpha <= 0pp."

    Both series must be the SAME trailing window (24 months of MONTHLY returns per the
    spec — the caller is responsible for windowing; this function does the regression
    + CI-gate arithmetic only, mirroring exactly how ols_regression separates the
    windowing decision from the math).
    """
    reg = ols_regression(y=d_monthly_returns, x=spy_monthly_returns)
    upper_ci_95 = reg.alpha + ALPHA_TEST_Z_95 * reg.alpha_se
    fires = reg.alpha <= BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD and upper_ci_95 <= BETA_ADJUSTED_ALPHA_CI_UPPER_BOUND
    return AlphaTestResult(regression=reg, upper_ci_95=upper_ci_95, fires=fires)


def metric_structural_change_invalidated(consecutive_non_conforming_quarters: int) -> bool:
    """rev 30 metric-immutability auto-invalidation rule (Subtype B theses only): if
    the trend metric's reportable category structurally changes such that it is no
    longer reported in its original form for >= 2 consecutive quarters, the thesis
    auto-invalidates as of the date the second non-conforming report is released.
    """
    return consecutive_non_conforming_quarters >= METRIC_CHANGE_INVALIDATION_QUARTERS


def subtype_for_dual_signal(
    catalyst_resolution_days_from_formation: int | None,
    trend_metric_independently_evaluable: bool = False,
) -> str:
    """rev 30 typing rule for dual-signal theses (both a future-dated catalyst AND a
    quantifiable trend metric present): mechanism-enforced via date arithmetic against
    the 12-month (365-day) forward-verification window. Returns 'A', 'B', or 'BOTH'.
    Pass catalyst_resolution_days_from_formation=None if no future-dated catalyst is
    present (Subtype B only — not a dual-signal case; this function should not be
    invoked in that case, but None is handled defensively).

    INTERPRETATION NOTE: strategy/06_strategy_d.md's three bullets are not a clean
    three-way date partition on their face — bullets 1/2 alone already partition every
    case by the 365-day boundary, yet bullet 3 describes a third "BOTH" outcome. Read
    literally in combination, bullet 3's "catalyst date falls within 12-month window"
    clause is the SAME condition as bullet 1, distinguished by the SEPARATE, non-date
    fact "trend metric's threshold can be evaluated independently of catalyst
    resolution" — i.e. within the catalyst<=365-day sub-case, typing is 'A' if the
    trend metric is NOT independently evaluable, else 'BOTH' (the stricter, union-of-
    both-invalidation-menus outcome). `trend_metric_independently_evaluable` is
    therefore a required THESIS-LEVEL fact the calling routine must supply (it is not
    itself derivable from pure date arithmetic) — verify this reading against
    strategy/06_strategy_d.md / Strategy.md directly before relying on it for a real
    typing decision; the source text's own three-bullet structure is ambiguous enough
    that this is a best-effort mechanical reading, not a restatement beyond dispute.
    """
    if catalyst_resolution_days_from_formation is None:
        return "B"
    if catalyst_resolution_days_from_formation <= 365:
        return "BOTH" if trend_metric_independently_evaluable else "A"
    return "B"

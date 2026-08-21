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

# Entry criterion 5 — correlation-bucket MONITORING (Rev 35, owner directive: the count cap and
# the post-entry entry-blocking behavior are REMOVED; bucket membership is now informational only,
# per Section 6 — see strategy/06_strategy_d.md and Strategy.md's Rev 35 changelog).
ENTRY_CORRELATION_BUCKET_THRESHOLD = 0.6
POST_ENTRY_CORRELATION_THRESHOLD = 0.7  # rev 28 post-entry monitoring, tighter margin

# Mark-to-market underperformance trigger — rev 28/30 beta-adjusted, CI-gated
BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD = -0.03  # "-3pp cumulative over 24 months" point estimate
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


def meets_concurrent_position_floor(open_position_count: int) -> bool:
    """Concurrent-position-count floor (strategy/06_strategy_d.md Instrument eligibility
    rule: "Concurrent position count: minimum 5 (floor retained ... Rev 40 ... a
    multi-tranche name counts as ONE position toward this floor, not one per add");
    Concentration-as-design-decision section: "the concurrent-position floor (minimum
    5 when any are held)". Boundary: minimum-N floor language reads as >= per the
    module's other floor/threshold predicates (meets_instrument_eligibility above uses
    >= for both its "minimum" constants), so 5 itself satisfies the floor — not just 6+.

    codebase audit 2026-07-26: this constant was defined but consumed nowhere in the
    repo (unlike every sibling spec constant in this module, each backed by exactly one
    predicate) even though strategy/06_strategy_d.md's Classical-method delegation
    section lists "Concurrent-position count and sector concentration checks" as
    something code should compute. Added to close that completeness gap.

    `open_position_count` must already be collapsed to DISTINCT NAMES held, per Rev
    40's "a multi-tranche name counts as ONE position toward this floor, not one per
    add" — the caller, not this function, is responsible for that collapse (mirrors
    beta_adjusted_alpha_test's windowing-is-the-caller's-job split above).

    The floor's own text ("minimum 5 when any are held") only binds once D has SOME
    exposure — an undeployed D (zero positions, e.g. before its first entry, or
    between full-exit and a fresh entry) is not "floor-violating," it simply hasn't
    started deploying yet. So count == 0 is treated as floor-satisfied (vacuously);
    1-4 is the actual violation zone the floor exists to catch.
    """
    if open_position_count == 0:
        return True
    return open_position_count >= MIN_CONCURRENT_POSITIONS


def correlation_bucket_members(
    candidate_returns: list[float],
    held_positions_returns: dict[str, list[float]],
) -> list[str]:
    """Entry criterion 5 (Rev 35, owner directive — MONITORING ONLY, not entry-blocking):
    which currently-held tickers share a correlation bucket with the candidate
    (trailing-252-day daily-return correlation > ENTRY_CORRELATION_BUCKET_THRESHOLD).
    Returns the list of held-position tickers that would join the candidate's bucket,
    for Section 6 informational reporting; the count is no longer capped and does not
    block entry. strategy/06_strategy_d.md: "for any two currently-held positions with
    trailing-252-day daily-return correlation > 0.6, both count toward the same
    correlation bucket" — the former "no more than 3 positions" cap was removed by
    Rev 35.
    """
    return [
        ticker
        for ticker, returns in held_positions_returns.items()
        if pearson_correlation(candidate_returns, returns) > ENTRY_CORRELATION_BUCKET_THRESHOLD
    ]


def post_entry_bucket_pairs(
    held_positions_returns: dict[str, list[float]],
) -> list[tuple[str, str]]:
    """rev 28 post-entry monitoring, informational only since Rev 35 (owner directive):
    recomputed monthly across ALL held-position pairs. Returns pairs exceeding the
    tighter 0.7 post-entry threshold (POST_ENTRY_CORRELATION_THRESHOLD) for Section 6
    reporting; no longer treated as a bucket for blocking a future entry and does not
    force an exit on the already-held pair. strategy/06_strategy_d.md: "If any
    held-position pair exceeds 0.7 daily-return correlation post-entry..." — the former
    entry-blocking consequence was removed by Rev 35.
    """
    tickers = sorted(held_positions_returns)
    pairs = []
    for i in range(len(tickers)):
        for j in range(i + 1, len(tickers)):
            a, b = tickers[i], tickers[j]
            if pearson_correlation(held_positions_returns[a], held_positions_returns[b]) > POST_ENTRY_CORRELATION_THRESHOLD:
                pairs.append((a, b))
    return pairs


class AlphaTestResult:
    """Result of the rev-30 CI-gated beta-adjusted-alpha edge-decay test.

    `regression.alpha` is the OLS intercept on MONTHLY returns (mean alpha per month);
    `cumulative_alpha` is the spec's own alpha-test METRIC — "the alpha differential
    (Jensen's alpha equivalent at 24 months)" — i.e. the quantity the -3pp threshold is
    stated against. Both are carried so a reporting caller quotes the spec's scale rather
    than re-deriving it.
    """

    __slots__ = ("regression", "cumulative_alpha", "upper_ci_95", "fires")

    def __init__(self, regression: RegressionResult, cumulative_alpha: float,
                 upper_ci_95: float, fires: bool):
        self.regression = regression
        self.cumulative_alpha = cumulative_alpha
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

    The metric that -3pp is stated against is the CUMULATIVE 24-month differential, not
    the per-month intercept — Strategy.md's §D Edge-decay indicators bullet (= the
    Strategy D segment of strategy/08_pre_mortems.md, rev 5) spells the same computation
    out at full length: "(iii) compare cumulative deployed TWR to cumulative synthetic;
    (iv) the alpha differential (Jensen's alpha equivalent at 24 months) is the
    alpha-test metric", with the threshold "(a) alpha point estimate <= -3pp cumulative
    over 24 months". The same section's SE figure is on that scale too ("SE +/-4.5pp
    (typical beta_hat noise of +/-0.2 SE x cumulative SPY return ~0.22)").

    Both series must be the SAME trailing window (24 months of MONTHLY returns per the
    spec — the caller is responsible for windowing; this function does the regression
    + CI-gate arithmetic only, mirroring exactly how ols_regression separates the
    windowing decision from the math).
    """
    reg = ols_regression(y=d_monthly_returns, x=spy_monthly_returns)
    # "cumulative deployed TWR minus cumulative synthetic" IS n x the intercept under the
    # spec's arithmetic aggregation: OLS residuals sum to zero, so
    # sum(TWR) - beta_hat*sum(SPY) == n*alpha exactly. Condition (a) is therefore tested
    # against this, the spec's own 24-month-scale metric.
    cumulative_alpha = reg.alpha * reg.n
    # Condition (b) is the SIGN test "95% upper CI bound on alpha <= 0pp", which is
    # invariant under the positive-n rescale — so the bound stays on the regression's own
    # per-month scale, where alpha and alpha_se are directly comparable.
    upper_ci_95 = reg.alpha + ALPHA_TEST_Z_95 * reg.alpha_se
    fires = cumulative_alpha <= BETA_ADJUSTED_ALPHA_FIRE_THRESHOLD and upper_ci_95 <= BETA_ADJUSTED_ALPHA_CI_UPPER_BOUND
    return AlphaTestResult(
        regression=reg, cumulative_alpha=cumulative_alpha, upper_ci_95=upper_ci_95, fires=fires)


def metric_structural_change_invalidated(consecutive_non_conforming_quarters: int) -> bool:
    """rev 30 metric-immutability auto-invalidation rule (Subtype B theses only): if
    the trend metric's reportable category structurally changes such that it is no
    longer reported in its original form for >= 2 consecutive quarters, the thesis
    auto-invalidates as of the date the second non-conforming report is released.
    """
    return consecutive_non_conforming_quarters >= METRIC_CHANGE_INVALIDATION_QUARTERS


def subtype_for_dual_signal(
    catalyst_resolution_days_from_formation: int | None,
    trend_metric_independently_evaluable: bool | None = None,
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

    BUG FIX (rev 2026-07-11, adversarial self-audit): `trend_metric_independently_
    evaluable` used to default to `False` — since `False` and `None` (never explicitly
    supplied) look IDENTICAL to a caller who reads a `False` return, a caller that
    forgot to determine this thesis-level fact would silently get the LESS STRICT 'A'
    typing instead of an error telling them they forgot something the docstring itself
    calls "required". The default is now `None`, a sentinel with no typing meaning of
    its own — see below, it RAISES rather than silently resolves to 'A' in the one
    branch (catalyst <= 365 days) where this fact actually matters. When the catalyst
    is None or beyond the 365-day window, the fact is genuinely irrelevant to the
    outcome and the caller is not burdened with supplying it.
    """
    if catalyst_resolution_days_from_formation is None:
        return "B"
    if catalyst_resolution_days_from_formation <= 365:
        if trend_metric_independently_evaluable is None:
            raise ValueError(
                "trend_metric_independently_evaluable is required when "
                "catalyst_resolution_days_from_formation <= 365 — this is a thesis-level fact "
                "not derivable from date arithmetic alone (see this function's docstring). "
                "Determine it before calling, rather than defaulting to a typing outcome."
            )
        return "BOTH" if trend_metric_independently_evaluable else "A"
    return "B"

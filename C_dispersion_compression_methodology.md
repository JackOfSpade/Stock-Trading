# C Dispersion Compression Empirical Check — Methodology

**Per:** Strategy C divergence review M2 follow-up commitment (Decision_Log 2026-04-25 entry "Strategy C divergence review", line 336).
**Initiated:** 2026-04-26 (this document).
**Applied:** 2026-05-01 M2 fundamental update.
**Purpose:** Empirically verify (or refute) the fundamental analyst's 2026-04-23 claim that "cross-sectional dispersion compression in stagflation-squeeze regimes" justifies maintaining DO-NOT-ACTIVATE on corporate earnings event types within Strategy C.

---

## Why this empirical check is required

The 2026-04-23 fundamental DNA reasoning asserted dispersion compression as a structural feature of the current regime. The 2026-04-25 divergence-review attacker flagged this as "accepted without empirical pressure." Theater-check CONVERGENT but with explicit acknowledgment that the claim was reasoned, not measured. M2 commits to measuring it.

The check matters because:
- If dispersion is genuinely compressed → corporate earnings event reactions tend toward muted/uniform, which dampens C's directional-thesis edge per pre-mortem rev 9 failure mode 2 (low-dispersion event regime). DO-NOT-ACTIVATE on earnings remains appropriate.
- If dispersion is normal or elevated → the fundamental DNA reasoning's premise fails, the HYBRID-FOMC-only restriction loses its empirical justification on the earnings leg, and earnings re-routing should be reconsidered at M2.

---

## Metric definition: what counts as "dispersion compression"

**Primary metric: cross-sectional standard deviation of single-day equity returns on earnings-reaction days** within S&P 500 constituents that reported earnings during the measurement window.

For each trading day `t` during the measurement window, the metric is computed as:

```
N(t) = number of S&P 500 constituents reporting earnings AMC on day t-1 OR BMO on day t
returns(t) = {close-to-close % return on day t for each name in N(t)}
σ_xs(t) = stdev(returns(t))    -- cross-sectional st.dev across earnings reactors
```

The aggregate measure for the window is the **median of σ_xs(t)** across all days t with N(t) ≥ 5. Median rather than mean because individual mega-cap reactions (e.g., NOW −18% on Apr 23) skew the mean.

**Interpretation:**
- High σ_xs: large dispersion within the same earnings cohort → individual-name fundamentals differentiate the moves → C's directional edge is meaningful per name
- Low σ_xs: small dispersion → all earnings reactors moving similarly regardless of fundamentals → individual-thesis quality drowned by common factor

---

## Comparison baselines

**Baseline 1: Trailing-5-year median of the same metric, same calendar season.**

Computed over the analogous window for prior years 2021-2025. Specifically: take March + early April calendar-day windows (1-week-before-FOMC-decision through FOMC-decision-day) for each of 2021-2025 to construct an in-distribution prior. Median of those 5 annual windows = baseline.

This compares "now" against "what the same calendar window looked like in prior years across both compressed and dispersed regimes."

**Baseline 2: Long-horizon (10+ year) regime distribution.**

Median σ_xs across all earnings-reactor days from 2014-2024 (10 years), partitioned by SPY-trend regime (UP / NEUTRAL / DOWN per Strategy.md Section 2 anchors). Compare current measurement to the NEUTRAL-regime median.

This compares "now" against "what dispersion looks like across all NEUTRAL-trend regimes historically, factoring out trend-state effects."

**Baseline 3 (sanity check): dispersion in known compressed regimes.**

Compute σ_xs in known low-dispersion regimes (e.g., late 2017 indiscriminate risk-on; March 2020 indiscriminate risk-off; mid-2022 inflation-shock uniformity) and known high-dispersion regimes (e.g., post-COVID-vaccine rotation Q4 2020; rate-shock 2018 Q4). Confirms metric behaves as expected.

---

## Decision threshold

The fundamental DNA claim is **supported** if:
- Current-window median σ_xs is **at or below** the trailing-5-year same-season baseline (Baseline 1), AND
- Current-window median σ_xs is **at or below** the NEUTRAL-trend long-horizon median (Baseline 2)

The claim is **not supported** if either condition fails by ≥ 20% (i.e., current σ_xs ≥ 1.20 × baseline).

The claim is **inconclusive** if results fall between (one baseline supports, other contradicts; or differences are < 20%).

**Pre-committed action per outcome:**
- **Supported:** Earnings DNA stays DO-NOT-ACTIVATE. Re-check at next M2 (June 1).
- **Not supported:** Reopen earnings DNA at M2. Specifically: re-examine whether the 2026-04-23 fundamental reasoning's premise survives the data refutation, and whether the divergence-review verdict on the corporate-earnings scope leg should be reconsidered. If so, follow Strategy.md rev 9 pre-mortem KL #12 gate (post-HYBRID fundamental update reasoning required to authorize scope widening to earnings; subject to single-session adversarial review + in-conversation orchestrator review).
- **Inconclusive:** Document as inconclusive; earnings DNA stays DO-NOT-ACTIVATE by default-on-ambiguity rule (Experiment_Parameters.md). Re-check at M2 with extended window.

---

## Data sources

**Primary:**
- S&P 500 constituent list as of measurement window start (Wikipedia or iShares IVV holdings file).
- Earnings calendar: company IR pages, Earnings Whisper, or Yahoo Finance earnings calendar (cross-checked across two sources).
- Daily OHLC: Yahoo Finance, StockAnalysis, or Investing.com historical-data tables.

**Computation:** Pure Python; can run in this environment. No paid data feeds required. Sample-size considerations: a 5-trading-day measurement window typically yields 50-150 earnings reactors at peak season; minimum N(t) ≥ 5 per day to compute σ_xs.

**Window timing:**
- Current measurement window: 2026-03-09 through 2026-04-25 (~ 6 weeks, capturing Mag7 prints + sector breadth).
- Same-season baseline windows: 2021/2022/2023/2024/2025 March 9 - April 25 each.

---

## What I can do now (this session) vs. what waits for M2

**Now (this session):**
- ✅ Document methodology (this file)
- ✅ Specify metric, baselines, thresholds, decision rules — all numerical and pre-committed
- Optional: pre-fetch the S&P 500 constituent list and earnings calendar for the current window so M2 application is faster

**Waits for M2 (2026-05-01):**
- Actually fetching the daily price data for ~50-150 constituents × ~30 trading days
- Computing the metric and baselines
- Producing the decision

The decision itself is M2-pacing per the original commitment. What I'm doing now is **removing methodology-judgment-under-time-pressure** from the M2 work. On May 1, the test mechanically applies; the only judgment call is on inconclusive cases.

---

## Theater-check on this methodology

**Q: Is this methodology designed to support the existing DNA verdict, or to test it honestly?**

The threshold (≥ 20% above baseline → "not supported") is asymmetric in favor of the DNA verdict — i.e., dispersion has to be visibly higher than baseline to overturn DO-NOT-ACTIVATE. This is intentional and conservative: per Experiment_Parameters.md default-on-ambiguity, unclear evidence stays DO-NOT-ACTIVATE. But the threshold is documented and pre-committed; if dispersion comes in at, say, 1.5× baseline, the methodology forces the reopen.

**Q: Does the metric capture what the fundamental DNA reasoning actually claimed?**

The DNA claim was about "cross-sectional dispersion compression in stagflation-squeeze regimes" — specifically about earnings event reactions. The metric measures σ_xs across earnings reactors, which is the direct empirical analogue. Not a perfect match (regime characterization is multi-dimensional) but the most direct mechanical proxy.

**Q: Is the 5-trading-day per-window computation plus 5-year same-season baseline statistically meaningful?**

For a single window, sample sizes of 50-150 names give σ_xs estimates with ~15-20% sampling error per the standard variance-of-stdev formula. Comparing across 5 baseline years partially absorbs this. The 20% decision threshold is calibrated against this uncertainty: differences smaller than 20% are within sampling noise and properly classified as inconclusive.

---

## Pre-committed actions on M2 application

1. **2026-05-01 morning:** Fetch S&P 500 list and earnings calendar for the current window AND for each of the 5 baseline years. Document exact data sources used.
2. **Compute σ_xs(t) per day** for current window and each baseline year window. Verify N(t) ≥ 5 per day; exclude days with insufficient earnings reactors.
3. **Aggregate to median σ_xs per window.** Compute Baseline 1 (5-year same-season median) and Baseline 2 (NEUTRAL-regime long-horizon median if data available; otherwise document gap).
4. **Apply threshold:** is current ≥ 1.20× max(Baseline 1, Baseline 2)? If yes → not supported. If current ≤ 0.83× min(Baseline 1, Baseline 2)? If yes → supported. Else inconclusive.
5. **Document outcome** in Decision_Log entry "C dispersion-compression check 2026-05-01" with the actual numbers, methodology choices made, and decision per pre-committed action.
6. **If "not supported":** trigger the rev 9 KL #12 scope-widening gate evaluation as a separate Decision_Log entry with single-session attacker + orchestrator review, per the inline-specified mechanism.

---

## Cross-references

- Strategy.md line 1175 (rev 9 KL #12 gate text — the formal scope-widening adjudication mechanism).
- Decision_Log 2026-04-25 entry "Strategy C divergence review" lines 330-345 (M2 follow-up commitment).
- Strategy.md lines 1084-1087 (pre-mortem rev 9 failure modes 1 and 4 — low-dispersion regimes).
- AI_Trading_Foundation.md disadvantage 2.6 (binding behavior on earnings/PDUFA event types — the residual the dispersion check operationalizes).

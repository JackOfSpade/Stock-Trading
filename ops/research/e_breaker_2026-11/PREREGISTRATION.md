# Strategy E re-exemption breaker: pre-registration (2026-11-07)

Research file, not policy. It fixes the gate's shape, the threshold-derivation rule, the replay windows and
the pass criteria BEFORE any replay statistic is computed. Written in an interactive owner session while
`replay_data.py` was fetching prices; no row of `series/pair_stats_weekly.csv` had been read when this was
committed to the working tree. Nothing here changes the live register: E BINDS until an owner revision lands
a gate in `strategy/02_regime_router.md` and its runtime mirror together, and that revision survives
adversarial review (Rev 53).

## What the gate must satisfy

The three Rev 53 re-exemption requirements (router, "Re-exemption requirements for a SPREAD row"), plus the
items the cycle-2 orchestrator of `premortem-router-2026-a1` (2026-10-27) graded valid and said must be carried
into the first revision that proposes an exempting gate: W1 (fail-closed read wording), W2 (cross-column
invariant in the lockstep check), W3 (machinery able to express the legs), W4 (per-group unit, statistic,
min-n, pooling, leg sharing), W5 (low-side population, aggregate, trigger, survivorship), W6 (windows fixed
before thresholds, substantive trip, lead time, false-bind ceiling, held-out window), W10 (cadence and M2
before M1b).

## Gate shape (fixed here)

**Unit.** GICS **industry**, the 6-digit level. E's spec says "industry group (6-digit GICS level)"; the
6-digit GICS level is named *industry*, so the gate uses the 6-digit code and names it correctly. Codes come
from `pairs_gics.csv` after verification.

**Population P(t).** Every pair that is in M2's ≥ 0.50 floor population (252-day correlation ≥ 0.50) at
measurement t, OR was in it at any of the three previous monthly measurements (sticky membership, so a pair
that falls out of the population because it is breaking down still counts: W5 survivorship). In the replay a
"monthly measurement" is the last weekly row of each calendar month.

**Group membership.** A group is the pairs of P(t) sharing a 6-digit industry. Its size is counted in
DISTINCT tickers, not pairs (W4 leg sharing). A group with fewer than 3 distinct tickers or fewer than 2 pairs
is pooled into its 4-digit parent; a parent that is still below that floor contributes its pairs to the
population-wide legs only.

**Leg H, per-group high side (requirement i).** For each group: median 60-day correlation of its pairs.
TRIPS if any group's median ≥ T_H.

**Leg L, low side (requirement ii), keyed to E's breakdown invalidation (60-day L-S correlation < 0.3).**
Two parts; either trips the leg:
- L-pop: the share of P(t) pairs with 60-day correlation < 0.3 is ≥ S_L.
- L-group: in any group (after pooling) at least half of its pairs have 60-day correlation < 0.3.

**Leg A, measurement integrity (fail-closed).** Trips when the measurement is missing, older than its maximum
age, or P(t) has fewer than 20 pairs. Leg A is NOT a substantive trip for requirement (iii).

**Breaker.** `breaker_tripped = H OR L OR A`; any leg that cannot be computed counts as tripped.

## Threshold derivation (fixed here; no threshold is chosen by hand)

- Calibration window: weekly rows from the first week with at least 40 pairs carrying a 252-day value, through
  2021-12-31.
- T_H = the 90th percentile, over all calibration months, of the month's MAXIMUM per-group median 60-day
  correlation. Rounded to 2 decimals.
- S_L = the 90th percentile, over all calibration months, of the month's L-pop share. Rounded to 2 decimals.
- Both thresholds are frozen after computation. The held-out window is never used to set or adjust them.
  This is a one-time derivation from an external price history, not a re-tune: the router's 24-month
  commitment governs re-derivation from M2's own published series, and this file records that the first
  thresholds came from a pre-registered percentile rule instead.

## Outcome measure (what a "loss environment" is)

E's failure mode is a pair spread that keeps diverging instead of reconverging. For each pair and week t:
`blowout(t) = |z252(t+4 weeks)| - |z252(t)| > 1.0`. A month's outcome is the share of P(t) pairs that blow out
over the 4 weeks after its measurement; a group's outcome is the same share within the group. A **stress
month** is a month whose population outcome is at or above the 90th percentile of all months in the full
sample, or in which any group with at least 3 distinct tickers has a group outcome of at least 0.5.

## Named windows (fixed here, before any statistic is seen)

Calibration (inside the threshold window): W-2018Q4 (2018-10-01 to 2018-12-31, broad sell-off);
W-2020COVID (2020-02-15 to 2020-04-30).

Held out: W-2022 (2022-02-15 to 2022-06-30, Russia/energy and the rate shock); W-2023BANKS (2023-03-01 to
2023-05-31, the US regional-bank run, a shock confined to one industry); W-2025TARIFF (2025-03-25 to
2025-05-15); W-2026GULF (2026-02-28 to 2026-10-31, the oil shocks graded acute).

## Pass criteria (all must hold; the replay reports each)

1. Substantive trips: the breaker trips on leg H or leg L (not leg A) in at least one month of each
   calibration window, and in at least 3 of the 4 held-out windows.
2. Group-local power: in W-2023BANKS the per-group leg H or L-group trips on the Banks industry while the
   population-wide statistics alone (median 60-day correlation below T_H, L-pop below S_L) would not. This is
   the case requirement (i) exists for.
3. Lead time: for at least half of the held-out stress months, the breaker was already tripped at the
   measurement that opens that month (it trips before the outcome window, not after it).
4. False-bind ceiling: the breaker is tripped in at most 40% of held-out months. A gate that is almost always
   tripped is as vacuous as one that never trips.
5. Discrimination: in the held-out window, the mean population outcome in tripped months exceeds the mean in
   clear months.

Clarification recorded 2026-11-07, after the replay code was written and BEFORE it was first run on the real
series: "held-out months" in criteria 3-5 means every monthly measurement dated after 2021-12-31 (the
held-out period), not only the months inside the named windows; criteria 1 and 2 read the named windows. A
leg counts as substantive in criterion 1 only when it tripped on a computed statistic, not because no group
or population existed.

If any criterion fails, the result is reported as a failure and E stays bound. The shape and the thresholds
are not re-fit to make a failing replay pass; a changed design would need a new pre-registration with new
held-out data.

## Cadence and runtime (proposal, recorded for the revision; not part of the replay)

- M2 currently runs at 13:00 UTC on the first trading day and M1b at 12:00 UTC (`ops/cadence.yaml`), so M1b
  reads a measurement about a month old. The revision would move M2 ahead of M1b, keep a 35-day maximum age,
  and let an out-of-cycle M1R scoring read the latest measurement.
- The replay is run on monthly measurements, the cadence the runtime would actually have, and also reports
  the weekly version for comparison only.
- Data caveats: Nasdaq closes, split-adjusted, not dividend-adjusted; history starts 2016-11, so the first
  252-day correlations appear in late 2017; today's pair list is applied backwards (survivorship); GICS codes
  are model-assigned until verified.

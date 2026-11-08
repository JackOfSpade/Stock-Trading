# Strategy E re-exemption breaker v2 (spread divergence): forward-test pre-registration (2026-11-07)

Research file, not policy. E BINDS under the acute-shock override, and stays bound whatever this test returns,
until an owner revision lands a gate in `strategy/02_regime_router.md` and its runtime mirror together and that
revision survives adversarial review (Rev 53). This file only fixes, before the data exists, how a candidate
gate will be judged.

## Why v2, and why a forward test

v1 (`PREREGISTRATION.md`, result in `README.md`) failed. Its legs read pair CORRELATION, and in the 2023
regional-bank run bank pair correlations stayed near 0.81 while the pair SPREADS diverged sharply. E loses
money when a spread keeps widening, so v2 adds legs that read spread divergence directly.

v2 was designed AFTER seeing 2017-11 to 2026-11 data, so that period cannot test it. Its thresholds are fixed
from that period by a stated rule, and the gate is judged ONLY on weeks after this file is committed. The git
commit that adds this file is the timestamp; nothing in it may change afterwards. A correction needs a new,
separately dated file and restarts the forward clock.

## Inputs

- Pairs: the 76 pairs hard-coded in `replay_data.py` (`PAIRS`), frozen as of this file.
- Industries: `pairs_gics.csv` as committed with this file.
- Prices: Nasdaq daily closes via `replay_data.py` (split-adjusted, not dividend-adjusted), re-fetched with a
  later end date at scoring time. Weekly rows are the last trading date of each ISO week.
- Per pair and week t: `c60`, `c252` (60- and 252-day return correlations) and `z252` (log price ratio
  standardized over its trailing 252 days), exactly as `replay_data.py` computes them.
- A measurement is an ISO week. Every row is keyed to its ISO week (dated by the latest row date in that week
  across all pairs), so a pair whose legs missed the week's last session still belongs to that week. A
  non-finite value counts as missing; a duplicate (week, pair) row is an input error.
- Scoring reads only rows dated on or before the scoring date; the in-sample replay and the thresholds read only
  rows dated on or before 2026-11-06. The weekly row of a scoring date's own unfinished ISO week is dropped.

## Gate v2 (weekly measurement)

**Population P(t).** Pairs with c252 >= 0.50 at t or at any of the 12 previous weekly measurements (sticky, so a
pair dropping out because it is breaking down still counts), and with c60 at t, z252 at t and z252 four weekly
rows earlier.

**Groups.** 6-digit GICS industry from `pairs_gics.csv` (a pair whose 6-digit cell is empty uses its 4-digit
code). A group needs at least 3 distinct tickers and at least 2 pairs; a group below that is pooled with the
other below-floor groups of the same 4-digit parent; a pool still below the floor contributes only to the
population-wide legs.

**Widening.** For pair p at week t: `w(p,t) = |z252(t)| - |z252(t-4)|`, where t-4 is the weekly row four rows
earlier for that pair. Positive means the spread moved further from its mean over the last four weeks.

**Legs** (each trips on its own; `breaker_tripped` = any leg):
- **D, per-industry divergence (meets Rev 53 requirement (i)):** the median w over a group's pairs; trips if
  any group's median >= T_D.
- **DP, population divergence:** the share of P(t) pairs with w > 1.0; trips if >= S_DP.
- **H, per-industry correlation rise (kept so the letter of requirement (i) is met):** the median c60 over a
  group's pairs; trips if any group's median >= T_H.
- **L, correlation breakdown (requirement (ii), keyed to E's 60-day < 0.3 invalidation):** L-pop trips if
  the share of P(t) pairs with c60 < 0.3 is >= S_L; L-group trips if a group has at least 2 pairs with
  c60 < 0.3 AND those are at least half of its pairs.
- **A, integrity (fail-closed, never substantive):** trips if the measurement is missing or P(t) has fewer than
  20 pairs. Any leg that cannot be computed counts as tripped.

**Thresholds (fixed by rule, not chosen).** Over every weekly measurement from the first week with at least 40
pairs carrying c252 through 2026-11-06 ("history"): T_D, S_DP, T_H and S_L are each the 95th percentile of that
leg's weekly statistic (for D and H the week's MAXIMUM group median), using Python
`statistics.quantiles(values, n=100, method='inclusive')[94]`, rounded to 2 decimals. They are computed once,
written to `results_v2/thresholds.json`, and frozen. Percentile 95 rather than v1's 90 because v2 has four
substantive legs and v1 was bound too often.

## Outcome

Forward blowout share for week t: the share of P(t) pairs with `|z252(t+4)| - |z252(t)| > 1.0`, where t+4 is
the weekly row four rows later (pairs without it are excluded from the denominator).

A **stress week** is one where the blowout share is >= B90, the 90th percentile of the weekly blowout share
over history (same quantile call, index 89, not rounded, frozen in `thresholds.json`), OR some group of at
least 3 pairs has at least 3 pairs with an outcome and at least two thirds of those blowing out.

## In-sample replay (requirement (iii); in-sample, so it proves non-vacuity only)

Reported over history, and required before the gate can be proposed at all:
- S1: leg D or DP trips in at least one week of W-2020COVID (2020-02-15 to 2020-04-30).
- S2: leg D trips on the Banks industry (401010) in at least one week of W-2023BANKS (2023-03-01 to
  2023-05-31).
- S3: report, without a pass mark, the share of history weeks bound and the mean outcome in bound vs clear
  weeks. These are in-sample and are not evidence of power.

## Forward test (the real test)

**Forward weeks:** every weekly measurement dated 2026-11-09 or later whose outcome window has closed.

**Scoring dates:** the first score on or after 2027-06-07 (about 26 forward weeks with closed outcomes). If it
is INCONCLUSIVE, re-score on or after 2027-09-06 and 2027-12-06; the 2027-12-06 score is final whatever it says.

**Scoring discipline (enforced by the scorer):**
- A score is refused if the real date is before the scoring date it claims, or if the claimed date is not a
  valid ISO date. Before 2027-06-07 only a clearly labelled peek is possible; a peek is written to a separate
  `peek_*.json` file, is never a score, and every peek is appended to `results_v2/scoring_log.jsonl`.
- Every score is appended to `results_v2/scoring_log.jsonl`. A score is refused once a PASS or FAIL exists, or
  once a score dated on or after 2027-12-06 exists. After an INCONCLUSIVE, the next score must be on or after the
  next scheduled date (2027-09-06, then 2027-12-06). An existing score file is never overwritten.
- `thresholds.json` carries a SHA-256 of the history rows it was computed from. Each score recomputes that
  digest from the re-fetched file and reports `history_revised` if it differs; a revised history is reported,
  not silently absorbed, and the frozen thresholds are still used.
- There is no option to recompute the thresholds.

**Criteria (all must hold for PASS):**
- F1 enough data: at least 26 forward weeks with an outcome and at least 3 forward stress weeks. If not, the
  result is INCONCLUSIVE, never PASS.
- F2 false-bind ceiling: bound in at most 35% of forward weeks.
- F3 lead time: bound at the measurement of at least half of the forward stress weeks.
- F4 discrimination: the mean blowout share in bound forward weeks exceeds the mean in clear forward weeks.

PASS on F1-F4 means only that the gate earned an owner revision proposal, which still needs the runtime work
below and its own adversarial review. FAIL closes v2. Thresholds, legs and criteria are never changed to turn a
FAIL into a PASS.

## Runtime notes for any later revision (not part of the test)

The gate is weekly; M2 is monthly and runs at 13:00 UTC, after M1b at 12:00 UTC on the first trading day
(`ops/cadence.yaml`). A runtime version needs a weekly measurement step that runs before any reader, a 10-day
maximum age, fail-closed reads ("apply the override unless `override_applies` is explicitly FALSE"), the
lockstep check's cross-column invariant, and new register columns for the D, DP, H and L thresholds (review
items W1, W2, W3 and W10 from `premortem-router-2026-a1` cycle 2).

-- 218_park_ladder_shadow.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 1 (record-only).
-- Project: stock-trading-498512. Creates analytics.park_ladder_shadow: what the graded ladder WOULD
-- have held, priced against what the book actually did and against never-switching VOO.
-- Apply after 216 (state.park_axis_daily) and 217 (Brent feed).
--
-- RECORD-ONLY. This view moves no capital and is read by no gate. It is the evidence gate for
-- Phase 3, which is held behind owner word plus a written checklist (design doc §4). The operative
-- rail remains the landed binary DE-RISK EVIDENCE CARDINALITY rule and fixture PA-07.
--
-- ============================ WHAT IT IMPLEMENTS (design doc §2.3) =============================
-- cap        = LEAST(100, 25 * standing_defensive_count), from 216.
-- STRICT decay confirmation: the cap steps DOWN only on the first session at which the lower
--   standing count has ALREADY held on the two preceding measured sessions — three consecutive
--   readings, step on the third. Implemented as MAX(cap_raw) OVER (2 PRECEDING .. CURRENT ROW),
--   which is exactly equivalent and needs no recursion: the running MAX cannot fall until the low
--   value occupies all three slots, while a cap INCREASE enters the MAX immediately (increases are
--   never delayed, per §2.3). The looser reading — counting the drop session itself as confirming
--   session #1 — was simulated over 284 sessions and produces 36 f-changes / 72 taps / 7
--   sub-2-session round trips against STRICT's 31 / 62 / 4, and re-creates the 2026-07-21 flap.
-- CRISIS OVERRIDE: SPY single-session return <= -2.5% OR VIX >= 28 lifts the cap to 100 that
--   session; crisis_recent (crisis today or in the prior 2 sessions) exempts f from the clamp,
--   which is the 2-session dwell.
-- ENTRY GATE: >= 1 fresh firing AND standing >= 2 (from 216). A single standing axis never
--   engages an increase — the landed cardinality floor, preserved.
-- CONVICTION SIZING: target = the step NEAREST to conviction_pct x cap, ties round DOWN, capped at
--   cap. Implemented as CEIL((target_pct - 12.5)/25), which is the ties-down nearest-step rule.
--   Worked: conviction 60 x cap 50 = 30 -> 25. 95 x 100 = 95 -> 100. 85 x 100 = 85 -> 75.
-- CLAMP: f above cap unwinds ONE step per session while f >= 50; a clamp crossing only 25->0
--   executes immediately; crisis_recent suspends the clamp entirely.
-- RE-RISK: decreasing f is always allowed and never delayed.
--
-- CONVICTION SOURCE. The actual logged conviction_pct for that session's park-allocation call where
-- one exists, else 60 (the modal logged value). Stated because it is a modelling choice: on days the
-- allocator logged no call the shadow assumes a typical conviction rather than skipping the day.
--
-- RETURN CHAIN. r_ladder(d) = (1 - f(d-1)) * r_risk(d) + f(d-1) * r_def(d) — the weight set by the
-- call on session d-1 is what the book earns on session d, because D1 calls at 16:00, D2 converts
-- that evening, and the fill lands at the NEXT open. This is bigquery/179's prev-lag idiom and it
-- carries 179's own accepted residual: a record-only benchmark has no fill price to anchor to, so
-- all arms sit on one close-to-close ruler. Do not "fix" it into a fill-anchored chain without
-- re-reading 179's header — the arms would stop being comparable.
--
-- TOTAL RETURNS, NOT PRICE RETURNS — this is load-bearing and was a real bug caught in testing.
-- r = (close + dividend) / prior_close - 1 for BOTH sleeves. SGOV's entire return IS its dividend:
-- its price is near-flat and DROPS on each ex-date (0.307098 on 2026-09-01 alone), so a price-only
-- chain reports the defensive sleeve LOSING money (-0.18% over the AI era) when it actually earns
-- the bill yield. Since 2026-06-01 the curated marks carry 4 SGOV dividend rows (1.209167 total)
-- and 1 VOO row (1.9622), so both arms must be grossed up or the comparison is meaningless.
-- Any future arm added here (a rule-table shadow, a third sleeve) must use the same convention.
--
-- ============================ WINDOW AND HONESTY BOUNDS ========================================
-- Starts 2026-06-01: state.park_signal_daily.shock_overlay is non-NULL only from that date, so
-- before it the shock axis cannot be evaluated at all and a "5-axis" shadow would silently be a
-- 4-axis one. ladder_index_ai_era is NULL before 2026-07-24 (the allocator's own era anchor, per
-- bigquery/212) so the graded and grading series never sit on different footings — the exact defect
-- 212 fixed for the scorecard.
--
-- TWO STRUCTURAL BLIND SPOTS, stated rather than discovered later:
--  1. The shadow computes from the SAME axis view the ladder would consume, so it is blind to
--     frozen-axis stuck states — it cannot tell you that an axis stopped updating, only what the
--     rules do given the axis states it sees. 216's sessions_since_measured is where that lives.
--  2. It validates only the TESTABLE axis subset. rates is UNTESTABLE by documented property
--     (FMP economics is plan-gated), so this is a five-axis shadow of a six-axis design, and
--     axis_set_fingerprint on 216 records which set produced any given row.
--
-- ============================ MEASURED RESULT AT LANDING (the re-pin) ==========================
-- Per the design doc's re-pin rule, landing the Brent feed CHANGED the pinned replay and these are
-- the re-derived numbers, against the FIVE-axis set now live:
--   2026-09-01  standing 2 (breadth, volatility)          cap 50  conviction 60 -> f = 25
--   2026-09-02  standing 3 (breadth, shock, volatility)   cap 75  conviction 60 -> f = 50
--   2026-09-03  standing 1 (shock)  cap held 75 by STRICT confirmation           f = 50
--   2026-09-04  standing 1 (shock)  cap held 75 (second low reading)             f = 50
-- The THREE-axis baseline the design doc originally pinned (f = 25, 25, 0) is SUPERSEDED. Two
-- findings follow and both run AGAINST the ladder, which is why they are recorded here rather than
-- smoothed:
--  (a) The shock axis fired on 2026-09-02 — a session the equity tape RECOVERED (SPY 761.78 ->
--      765.16) — because Brent crossed 95. The axis is measuring an oil price, and its overlay limb
--      had been standing 'acute' for three weeks, so the composite fired on the commodity alone.
--      Whether that is signal or a spurious cross-asset trigger is exactly what more shadow
--      observations must settle before Phase 3.
--  (b) STRICT confirmation, which is correct for suppressing the 07-21 flap class, holds f at 50
--      through 09-03 — the session VOO rallied ~1.04%. Suppressing whipsaw and reacting quickly to
--      a genuine all-clear are in direct tension, and this episode is the tension made concrete.
-- On the one live EPISODE the richer axis set makes the ladder look worse than the 3-axis replay did.
-- That is the finding Phase 1 exists to surface before any capital moves, and it is a reason to keep
-- Phase 3 held, not a reason to retune the axes until the numbers flatter the design.
--
-- ============================ FOUR-ARM RESULT, ONE RULER (AI era 07-24..09-04, 31 sessions) =====
-- All four arms are close-to-close TOTAL-return chains computed inside this view, so nothing here is
-- a cross-ruler comparison (that was a real trap: analytics.park_counterfactuals is FILL-anchored per
-- bigquery/179, so its AI figure of +1.073% is NOT directly comparable to these):
--     never-switch VOO        +4.732%
--     GRADED LADDER           +2.995%     <- 3 f-changes, engaged on 35.5% of sessions
--     actual binary allocator +0.758%
--     always SGOV             +0.432%
-- The ladder recovers +2.237pp of the allocator's shortfall — roughly 57% of the 3.974pp gap between
-- what the book actually did and never switching — while still trailing never-switching by 1.737pp.
-- READ THAT HONESTLY IN BOTH DIRECTIONS. It is real evidence that GRADING the response beats the
-- binary all-or-nothing switch, which is the owner's proportional-sizing thesis. It is NOT evidence
-- that the allocator should be de-risking at all: never-switching still wins by a wide margin over
-- this window, and the single cheapest intervention on the measured record remains "de-risk less".
-- n = 31 sessions and ONE de-risk episode. This is a direction, not a verdict, and Phase 3 stays held
-- until the shadow has accumulated genuinely independent episodes.
-- Cross-check that validated the total-return fix: always-SGOV here (+0.432%) reproduces
-- park_counterfactuals' independently-computed SGOV leg (+0.402% to 09-03) to within the extra
-- session and the ruler difference.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_ladder_shadow` AS
WITH RECURSIVE
ax AS (
  SELECT as_of_date,
         ANY_VALUE(standing_defensive_count) AS standing,
         ANY_VALUE(firing_count)             AS firing,
         ANY_VALUE(cap_pct)                  AS cap_raw,
         ANY_VALUE(increase_gate_open)       AS gate,
         ANY_VALUE(testable_axes)            AS testable_axes,
         ANY_VALUE(axis_set_fingerprint)     AS axis_set_fingerprint
  FROM `stock-trading-498512.state.park_axis_daily`
  WHERE as_of_date >= DATE '2026-06-01'
  GROUP BY as_of_date
),
mk AS (
  SELECT mark_date,
         MAX(IF(ticker = 'SPY',  close, NULL)) AS spy,
         MAX(IF(ticker = '^VIX', close, NULL)) AS vix,
         MAX(IF(ticker = 'VOO',  close, NULL)) AS voo,
         MAX(IF(ticker = 'SGOV', close, NULL)) AS sgov,
         MAX(IF(ticker = 'VOO',  IFNULL(dividend, 0), NULL)) AS voo_div,
         MAX(IF(ticker = 'SGOV', IFNULL(dividend, 0), NULL)) AS sgov_div
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker IN ('SPY', '^VIX', 'VOO', 'SGOV') AND mark_date >= DATE '2026-05-20'
  GROUP BY mark_date
),
mkr AS (
  SELECT mark_date, vix,
         SAFE_DIVIDE(spy,  LAG(spy)  OVER (ORDER BY mark_date)) - 1 AS spy_ret,
         SAFE_DIVIDE(voo  + voo_div,  LAG(voo)  OVER (ORDER BY mark_date)) - 1 AS r_risk,
         SAFE_DIVIDE(sgov + sgov_div, LAG(sgov) OVER (ORDER BY mark_date)) - 1 AS r_def
  FROM mk
),
conv AS (
  SELECT entry_date, MAX(conviction_pct) AS conviction_pct
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'park-allocation' AND conviction_pct IS NOT NULL
  GROUP BY entry_date
),
-- The book's ACTUAL defensive weight, on the IDENTICAL ruler, so the comparison is not cross-ruler.
-- park_policy_changes is append-only and 2026-09-03 carries a CORRECTED REPLACEMENT row for the same
-- vehicle/date, so the vehicle is taken from the LATEST event_ts per effective_date.
pol AS (
  SELECT effective_date, vehicle
  FROM `stock-trading-498512.events.park_policy_changes`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY effective_date ORDER BY event_ts DESC) = 1
),
base AS (
  SELECT a.as_of_date, a.standing, a.firing, a.cap_raw, a.gate, a.testable_axes,
         a.axis_set_fingerprint,
         IF(p.vehicle = 'VOO', 0, 100) AS actual_f_pct,
         COALESCE(c.conviction_pct, 60) AS conviction,
         COALESCE(m.spy_ret <= -0.025 OR m.vix >= 28, FALSE) AS crisis,
         m.r_risk, m.r_def
  FROM ax a
  LEFT JOIN mkr  m ON m.mark_date  = a.as_of_date
  LEFT JOIN conv c ON c.entry_date = a.as_of_date
  -- Range join, not an equality join: policy effective_dates are NOT always trading days
  -- (2026-07-26 is a Sunday), so "the policy in force on this session" is the latest row at or
  -- before it, never a same-day match.
  LEFT JOIN pol p ON p.effective_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.as_of_date ORDER BY p.effective_date DESC) = 1
),
seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY as_of_date) AS n, as_of_date, standing, firing, gate,
         conviction, crisis, r_risk, r_def, testable_axes, axis_set_fingerprint, actual_f_pct,
         GREATEST(
           CAST(MAX(cap_raw) OVER (ORDER BY as_of_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
                / 25 AS INT64),
           IF(crisis, 4, 0)) AS cap_idx,
         COALESCE(crisis
                  OR LAG(crisis, 1) OVER (ORDER BY as_of_date)
                  OR LAG(crisis, 2) OVER (ORDER BY as_of_date), FALSE) AS crisis_recent
  FROM base
),
seq2 AS (
  SELECT n, as_of_date, standing, firing, gate, conviction, crisis, crisis_recent, cap_idx,
         r_risk, r_def, testable_axes, axis_set_fingerprint, actual_f_pct,
         LEAST(cap_idx,
               GREATEST(0, CAST(CEIL((conviction * cap_idx * 25 / 100 - 12.5) / 25) AS INT64)))
           AS target_idx
  FROM seq
),
walk AS (
  SELECT n, CAST(IF(gate AND target_idx > 0, target_idx, 0) AS INT64) AS f_idx
  FROM seq2 WHERE n = 1
  UNION ALL
  SELECT s.n,
    CASE
      WHEN s.gate AND s.target_idx > w.f_idx      THEN LEAST(s.target_idx, s.cap_idx)
      WHEN w.f_idx > s.cap_idx AND s.crisis_recent THEN w.f_idx
      WHEN w.f_idx > s.cap_idx AND w.f_idx >= 2    THEN w.f_idx - 1
      WHEN w.f_idx > s.cap_idx                     THEN s.cap_idx
      ELSE w.f_idx
    END AS f_idx
  FROM walk w JOIN seq2 s ON s.n = w.n + 1
),
joined AS (
  SELECT s.as_of_date, s.standing, s.firing, s.gate, s.conviction, s.crisis, s.crisis_recent,
         s.testable_axes, s.axis_set_fingerprint, s.r_risk, s.r_def, s.actual_f_pct,
         LAG(s.actual_f_pct) OVER (ORDER BY s.as_of_date) AS actual_f_prev_pct,
         s.cap_idx * 25 AS cap_pct,
         s.target_idx * 25 AS conviction_target_pct,
         w.f_idx * 25 AS f_pct,
         LAG(w.f_idx * 25) OVER (ORDER BY s.as_of_date) AS f_prev_pct
  FROM seq2 s JOIN walk w ON w.n = s.n
),
priced AS (
  SELECT *,
         -- The weight set on the PRIOR session is what the book earns today (179's prev-lag idiom).
         SAFE_MULTIPLY(1 - f_prev_pct / 100, r_risk)
           + SAFE_MULTIPLY(f_prev_pct / 100, r_def) AS r_ladder,
         SAFE_MULTIPLY(1 - actual_f_prev_pct / 100, r_risk)
           + SAFE_MULTIPLY(actual_f_prev_pct / 100, r_def) AS r_actual
  FROM joined
)
SELECT
  as_of_date,
  standing                                   AS standing_defensive_count,
  firing                                     AS firing_count,
  gate                                       AS increase_gate_open,
  crisis,
  crisis_recent,
  conviction                                 AS conviction_pct,
  cap_pct,
  conviction_target_pct,
  f_pct,
  f_prev_pct,
  r_risk,
  r_def,
  r_ladder,
  -- The ACTUAL book weight and its return, on the identical ruler — this is what makes the
  -- ladder-vs-actual comparison honest rather than cross-ruler.
  actual_f_pct,
  actual_f_prev_pct,
  r_actual,
  -- Flap counters (§2.7): a step change in f, and a conviction sitting within 5 points of the
  -- cap-100 step boundary at 62.5, which is dead centre of the allocator's empirical 50-76 range.
  (f_pct != f_prev_pct)                      AS f_changed,
  (ABS(conviction - 62.5) <= 5)              AS conviction_near_step_boundary,
  testable_axes,
  axis_set_fingerprint,
  DATE '2026-06-01'                          AS ladder_start_date,
  -- NULL before the allocator's own era anchor, so graded and grading series share a footing.
  IF(as_of_date >= DATE '2026-07-24', r_ladder, NULL) AS r_ladder_ai_era
FROM priced;

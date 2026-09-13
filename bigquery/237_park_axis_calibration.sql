-- 237_park_axis_calibration.sql (2026-09-13) — PARK ALLOCATOR v4: axis calibration drift watch.
-- Project: stock-trading-498512. Creates state.park_axis_calibration. Apply after 216.
--
-- WHY THIS EXISTS. Every axis in state.park_axis_daily is a threshold against a moving world, and a
-- threshold that was sensible when written can silently stop carrying information without anything
-- failing, erroring, or alerting. Nothing in this stack measured that until now: the axes were
-- calibrated once (bigquery/216's header records the credit sweep) and never re-checked.
--
-- THE CONCRETE CASE THAT MOTIVATED IT (2026-09-13). The RATES axis fires at `10Y >= 4.90`, an ABSOLUTE
-- level on an UNBOUNDED, non-stationary series. Over the 288 sessions backfilled by bigquery/236 it
-- fires on 2 (0.69%). That was measured and DELIBERATELY KEPT — re-calibrating it to the stationary
-- form the other axes use (10Y >= its own 20d SMA + 10bp) was replayed through the full ladder and
-- came out 0.921pp WORSE over the AI era, because the extra sensitivity doubles defensive weight
-- straight through the 07-27..08-04 SGOV excursion that is the worst measured episode on the tape.
-- See PARK_ALLOCATOR_V4_DESIGN.md §2.2's threshold note for the full study.
--
-- But "kept on evidence" is not "safe forever". An absolute yield level is the one axis definition
-- here whose firing rate depends entirely on the prevailing RATE REGIME rather than on market stress:
-- at a 3% 10Y it can never fire, at a 6% 10Y it can never stop. Either state is silent. This view is
-- the missing instrument for that, and it generalises to all six axes for free.
--
-- WHAT IT FLAGS, AND WHAT IT DELIBERATELY DOES NOT. `degenerate` is TRUE only at the EXTREMES — an
-- axis that has fired on NONE of its testable sessions in the trailing 252, or on ALL of them. Those
-- are the states in which an axis provably carries zero information, whatever its threshold says.
-- It is NOT a "this axis looks rare" warning: rates at 0.69% is rare BY DECISION and is not flagged,
-- because a detector that is red from the day it ships is a detector nobody reads (and this project
-- has the scar tissue to prove it). The point is to catch the axis going fully dead or fully pinned,
-- which is exactly how a non-stationary threshold fails.
--
-- 252 sessions ~= one trading year: long enough that an ordinary quiet stretch does not trip it, short
-- enough that a genuine regime shift surfaces within a year rather than never.
--
-- NO ALERT CATEGORY, BY DESIGN. This is read by W5's PARK SCORECARD step, which already runs weekly,
-- already reads this exact machinery, and already has a reporting channel (`events.decision_log`
-- `entry_type='park-scorecard'`). Adding a new ops.alerts category would need its own closure path for
-- a condition whose only sane response is a human re-calibration decision — the weekly scorecard IS
-- that review. Do not wire this into sp_sq_cadence_check.

CREATE OR REPLACE VIEW `stock-trading-498512.state.park_axis_calibration` AS
WITH ranked AS (
  SELECT axis, as_of_date, testable, is_defensive, is_firing,
         ROW_NUMBER() OVER (PARTITION BY axis ORDER BY as_of_date DESC) AS rn
  FROM `stock-trading-498512.state.park_axis_daily`
),
win AS (
  SELECT * FROM ranked WHERE rn <= 252
)
SELECT
  axis,
  COUNT(*)                                    AS sessions_in_window,
  COUNTIF(testable)                           AS testable_sessions,
  COUNTIF(is_defensive)                       AS defensive_sessions,
  COUNTIF(is_firing)                          AS firing_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(is_defensive), NULLIF(COUNTIF(testable), 0)) * 100, 2)
                                              AS defensive_pct_of_testable,
  MIN(as_of_date)                             AS window_start,
  MAX(as_of_date)                             AS window_end,
  -- Degenerate ONLY at the extremes, and only once the axis has a meaningful testable sample:
  -- fewer than 60 testable sessions is a young or recently-blanked axis, not a dead one.
  (COUNTIF(testable) >= 60
     AND (COUNTIF(is_defensive) = 0 OR COUNTIF(is_defensive) = COUNTIF(testable)))
                                              AS degenerate,
  CASE
    WHEN COUNTIF(testable) < 60 THEN 'insufficient-sample'
    WHEN COUNTIF(is_defensive) = 0 THEN 'DEAD: never defensive in the trailing window - threshold may have drifted out of reach of the current regime'
    WHEN COUNTIF(is_defensive) = COUNTIF(testable) THEN 'PINNED: defensive on every testable session - threshold may have been overtaken by the current regime'
    ELSE 'ok'
  END                                         AS verdict,
  CURRENT_TIMESTAMP()                         AS checked_at
FROM win
GROUP BY axis

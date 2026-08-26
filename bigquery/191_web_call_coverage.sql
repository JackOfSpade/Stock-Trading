-- ===== 191: state.web_call_coverage — make the ops.web_calls telemetry gap SELF-DETECTING =====
-- (2026-08-21, owner-directed — usage-cost audit finding apis-1.)
--
-- WHY: ops.web_calls (bigquery/174) is the fleet's only per-routine attribution substrate for
-- metered external calls, and ADOPTION is its failure mode: measured 2026-08-21, exactly 7 of 219
-- completed August runs carried any web_calls row (3.2%), all from D1 or W3 — so
-- state.web_spend_month's per-routine numbers read like totals while being floors (~15x under the
-- provider dashboard's account total), and NOTHING mechanically noticed a run that omitted its
-- logging. The obligation itself is already correctly pinned at the run-logging template immediately
-- before sp_routine_end (2026-08-19) — restating it again is not the fix; this view is the missing
-- mechanical notice. Its consumer is OPS0's daily EXTERNAL-CALL TELEMETRY SWEEP (STEP 5, added the
-- same day), which raises a WARNING ops.alerts row off missing_telemetry — warning class only, per
-- the standing rule that no per-routine credit cap may be set from spend alone.
--
-- expected_metered: the routines whose Claude_Task_Plan.md prose names a metered surface (shared
-- rule "Metered external calls" + per-routine steps, enumerated 2026-08-21): D1, D2a, W1, W2, W3,
-- W5, M1a, M2, M3, Q2, Q3, SL1, OPS1, OPS2. A routine outside this list that logs anyway is fine —
-- expected_metered=FALSE and missing_telemetry can never fire for it. The list is a curated literal,
-- not derived from prose at query time; when a routine gains/loses a metered surface, update it here
-- via a superseding redefinition (apply-in-order discipline).
--
-- Trailing 45 days: covers a monthly routine's full cadence gap while keeping the scan bounded on
-- both partitioned sources (run_log and web_calls are PARTITION BY run_date).
--
-- RECORD-ONLY: no cap, no gate, nothing blocks on this view. Additive — new object, supersedes
-- nothing, no existing definition replaced.
--
-- SUPERSEDED LIVE by bigquery/200_web_call_coverage_obligation_floor.sql (2026-08-26) — that file is
-- the CURRENT canonical definition of state.web_call_coverage; it floors run_date at the 2026-08-17
-- telemetry obligation date so pre-obligation runs (SL1, M1a, M2, M3) are not flagged as gaps.
-- Do NOT re-apply this file's view in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.web_call_coverage` AS
WITH runs AS (
  SELECT routine, run_date
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY routine, run_date
),
logged AS (
  SELECT routine, run_date, COUNT(*) AS logged_row_count
  FROM `stock-trading-498512.ops.web_calls`
  WHERE run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY routine, run_date
)
SELECT
  r.routine,
  r.run_date,
  COALESCE(l.logged_row_count, 0) AS logged_row_count,
  r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
    AS expected_metered,
  -- PROVEN gap: a completed run of a routine the prose obliges to log, with zero rows logged for
  -- that (routine, run_date). This is the only column OPS0's STEP 5 raise reads.
  (r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
     AND l.routine IS NULL) AS missing_telemetry,
  CURRENT_TIMESTAMP() AS checked_at
FROM runs r
LEFT JOIN logged l
  ON l.routine = r.routine AND l.run_date = r.run_date;

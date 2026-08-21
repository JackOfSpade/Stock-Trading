-- ===== 192: state.fmp_daily_budget — count FMP requests against the 250/day account-wide cap =====
-- (2026-08-21, owner-directed — usage-cost audit finding apis-5.)
--
-- WHY: FMP's free tier is 250 requests/day ACCOUNT-WIDE, and blowing it does not error cleanly —
-- `quote` returns "Limit Reach", batch endpoints return HTTP 200 with denied symbols silently
-- dropped (measured 2026-08-20: 18 symbols requested, 3 returned), and some filters are accepted
-- and ignored. The failure mode is SILENT EVIDENCE LOSS, not a bill: on 2026-08-17 the cap blew and
-- cost the fleet a $64B-cap decliner (Claude_Task_Plan.md's shared metered-calls rule records the
-- incident). Weekday exposure is small (12 requests measured 2026-08-20 = 4.8% of cap); the
-- exposure is SUNDAY, when the weekly fleet stacks on the dailies. Until now nothing counted.
--
-- HONEST FLOOR, NOT A METER: this counts ops.web_calls rows with provider='fmp', so it sees only
-- LOGGED calls — bigquery/191 (state.web_call_coverage) is the enabler that makes unlogged runs
-- visible; while adoption is incomplete, pct_consumed is a lower bound. fan_out_day flags dates
-- where more than one FAN-OUT-AUTHORIZED routine completed (D1, W1, M2, Q2, A1 — the set the
-- 2026-08-17 W2 de-fan-out note explicitly leaves authorized), keyed off actual ops.run_log
-- completions, not an assumed calendar alignment.
--
-- Consumer: OPS0's daily EXTERNAL-CALL TELEMETRY SWEEP (STEP 5) raises a WARNING at >= 60% of cap
-- (150 logged requests) — early enough for a late-Sunday routine to degrade deliberately and say so,
-- instead of discovering the ceiling by hitting it. RECORD-ONLY here: no cap enforcement, no gate,
-- no throttle — consistent with the standing no-spend-knob-ahead-of-evidence rule.
--
-- Trailing 45 days, matching 191; both sources are PARTITION BY run_date. Additive — new object,
-- supersedes nothing.
CREATE OR REPLACE VIEW `stock-trading-498512.state.fmp_daily_budget` AS
WITH fmp AS (
  SELECT run_date, COUNT(*) AS logged_fmp_requests
  FROM `stock-trading-498512.ops.web_calls`
  WHERE provider = 'fmp'
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
),
fanout AS (
  SELECT run_date, COUNT(DISTINCT routine) AS fan_out_routines_completed
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
    AND routine IN ('D1','W1','M2','Q2','A1')
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
)
SELECT
  run_date,
  COALESCE(f.logged_fmp_requests, 0) AS logged_fmp_requests,
  250 AS daily_cap,
  ROUND(COALESCE(f.logged_fmp_requests, 0) / 250 * 100, 1) AS pct_consumed,
  COALESCE(fo.fan_out_routines_completed, 0) AS fan_out_routines_completed,
  COALESCE(fo.fan_out_routines_completed, 0) > 1 AS fan_out_day,
  CURRENT_TIMESTAMP() AS checked_at
FROM fmp f
FULL OUTER JOIN fanout fo USING (run_date);

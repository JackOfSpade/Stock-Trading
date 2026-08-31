-- PERIOD-AWARE DEPENDENCY GATE (2026-07-28 interactive session; surfaced by the SL1 + SL4 off-slot
-- catch-up runs of 2026-07-27). Project: stock-trading-498512.
-- Apply after 48_cadence_monitor_unbounded.sql, 38_run_log_selfheal.sql, 113_never_completed_watch_fix.sql.
--
-- PROBLEM: ops.sp_assert_deps matches an upstream on the EXACT calendar day (`r.run_date = in_run_date`,
-- plus a before-noon midnight-crossing grace). That is right for a DAILY dependency, but every
-- period-cadence dependency edge in ops/cadence.yaml is day-keyed against an upstream that only ever
-- runs on its period's FIRST TRADING DAY. The gate therefore only passes when the downstream happens to
-- run on the very same calendar day as its upstream -- true by luck for a same-cadence pair on their
-- shared slot, and FALSE the moment the downstream runs on any other day.
--
-- Both SISA routines hit this independently on 2026-07-27 and had to work around it BY HAND, differently:
--   * SL1 (deps Q1, Q3 -- both correctly completed 2026-07-01, the quarter's FTD) called the gate, took a
--     FALSE-POSITIVE `missing_dependency` CRITICAL (alert 177646a6), and then had to recognize and clear
--     its own alert as a known false positive before proceeding.
--   * SL4 (dep M4 -- correctly completed 2026-07-01, the month's FTD) DELIBERATELY SKIPPED the gate
--     entirely, documenting in its run note that calling it would raise a blocking critical which would
--     persist ~2 days across the 2026-07-28 thesis-entry deadlines.
-- Neither was wrong; both were forced to hand-reason around a load-bearing FATAL gate, which is exactly
-- the situation a mechanical gate exists to prevent. This recurs on EVERY off-slot catch-up of a period
-- routine -- and bigquery/113_never_completed_watch_fix.sql makes those catch-ups MORE frequent, since
-- surfacing missed period runs is now precisely its job. Fixing the gate is the other half of 113.
--
-- ALSO FIXES a pre-existing latent bug on the WEEKLY edges, found by the verification harness below and
-- unrelated to catch-up: ops/cadence.yaml documents weeklies as tolerating "Sunday OR Monday", but the
-- day-keyed gate only forgives a one-day lag BEFORE NOON. A W4 running Monday AFTERNOON against W1/W2/W3
-- that correctly completed Sunday was a false-positive blocking critical waiting to happen. MEASURED on
-- live data at 2026-07-01 (a Wednesday): all four weekly edges (W4<-W1/W2/W3, W5<-W4) read false-missing
-- under the old rule and satisfied under the new one.
--
-- FIX: resolve each dependency's own cadence class, then ask the period-correct question --
--   * period dep (weekly_sun / monthly_ftd / quarterly_ftd / annual_ftd): satisfied by ANY completed run
--     inside in_run_date's OWN period (period_start .. in_run_date). A monthly upstream that ran on the
--     1st IS satisfied for a downstream running on the 27th of the same month -- its output is that
--     month's output, not stale.
--   * daily / queue_driven / unrecognized dep: EXACTLY the previous predicate, byte-for-byte (exact
--     run_date + the before-noon midnight-crossing grace). Unrecognized deps deliberately fall here so a
--     typo'd or newly-added id fails SAFE (strict) rather than silently widening.
--
-- STRICTLY A SUPERSET -- it can only ever turn a FALSE "missing" into "satisfied", never the reverse:
-- the period branch's window [period_start, in_run_date] CONTAINS the old exact-day match, and the
-- non-period branch is unchanged. It cannot mask a genuinely missing upstream: a dep with NO completion
-- anywhere in the current period is still reported missing, still raises the same `missing_dependency`
-- critical, and still RAISEs. VERIFIED against live ops.run_log across all 22 real dependency edges x 3
-- dates (2026-07-01 / 07-27 / 07-28) before applying: 0 regressions; all 18 daily/queue evaluations
-- identical; period edges changed ONLY in the false-missing -> satisfied direction. Negative control
-- held: A3<-A1/A2 evaluated at 2026-07-01 and 07-27 (before A1/A2 had ever completed) stayed MISSING
-- under both rules, and flipped to satisfied only on 07-28 once they genuinely completed.
--
-- DELIBERATELY UNCHANGED (do not "fix" these -- each is load-bearing):
--   * The self-bootstrapping `monitored` gate (`ever` CTE): a dep that has NEVER completed is treated as
--     satisfied, so a research feeder that has not yet adopted run-logging cannot permanently block its
--     downstream. This is the OPPOSITE of what 113 did to the WATCH views, and both are correct: an
--     ALARM should fire for a never-run routine (nobody is blocked by an alarm), while a FATAL GATE must
--     not deadlock the whole chain behind one never-adopted upstream. Q1/Q3 vs SL1 is the worked case --
--     see the SL1 slice's DEPENDENCY GATE line.
--   * The `sp_backfill_run_log_from_markers` best-effort call, the `missing_dependency` critical, the
--     RAISE, and both message formats -- byte-identical, so alert dedup/auto-resolve behavior is untouched.
--   * No runtime dependency on any VIEW. The class list is embedded, not joined from
--     state.cadence_period_watch: this procedure is FATAL and unwrapped, so widening its runtime surface
--     from ops.run_log to a view chain (trading_day_today + market_calendar) would let a view fault abort
--     every gated routine. The embedded list is GENERATED and CI-CHECKED instead (below).
--
-- The `period_class` CTE below is GENERATED (scripts/gen_routine_lists.py --write; this file is that
-- script's 5th target) from ops/cadence.yaml, using the SAME rows as bigquery/24's region -- do NOT
-- hand-edit between the markers. `gen_routine_lists.py --check` in CI fails the build if it drifts.
--
-- SUPERSEDES the ops.sp_assert_deps PROCEDURE in 48_cadence_monitor_unbounded.sql (48's
-- state.cadence_watch VIEW was already superseded by 113; between them, nothing in 48 is live any more,
-- but 48 stays in the repo unmodified as DR-rebuild apply-in-order reference).

-- SUPERSEDED (2026-08-31) by bigquery/205_alert_message_stability.sql, the current canonical
-- definition of this procedure. 205 changes MESSAGE TEXT ONLY: the missing_dependency alert message
-- embedded in_run_date, so a dependency block lasting n days raised n separate CRITICAL alerts
-- instead of one -- the same defect bigquery/85 fixed for the sibling trading_halted gate in
-- 2026-07-04, never ported here. run_date stays in the payload and in the RAISE. No predicate or
-- control flow differs. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_deps`(
  in_routine STRING, in_deps ARRAY<STRING>, in_run_date DATE
)
BEGIN
  DECLARE missing STRING;

  BEGIN
    CALL `stock-trading-498512.ops.sp_backfill_run_log_from_markers`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Expressed as plain CTEs + joins with NO correlated subqueries: BigQuery cannot de-correlate a
  -- correlated EXISTS that references another table alongside several sibling correlated subqueries
  -- ("Correlated subqueries that reference other tables are not supported unless they can be
  -- de-correlated"), the exact failure bigquery/59_catchup_autofire.sql hit at QUERY time (not DDL time)
  -- and had to rewrite as LEFT JOIN + IS NULL. Same shape used here so this can never surface that way.
  SET missing = (
    WITH period_class AS (
      SELECT * FROM UNNEST([
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W2' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W3' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W4' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W5' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('M1a' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M1b' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M2' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M3' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M4' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M5' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('SL4' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('Q1' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q2' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q3' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q4' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('SL1' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('A1' AS routine, 'annual_ftd' AS monitor_class),
    STRUCT('A2' AS routine, 'annual_ftd' AS monitor_class),
    STRUCT('A3' AS routine, 'annual_ftd' AS monitor_class)
  -- END GENERATED ROUTINE LIST
      ])
    ),
    -- One row per DISTINCT declared dependency, carrying the lower bound of the window that satisfies
    -- it. period_start IS NULL marks the daily/queue/unrecognized (strict, unchanged) branch.
    -- DAYOFWEEK is 1=Sunday, so (dow - 1) is exactly the offset back to that week's Sunday -- the same
    -- expression bigquery/24_cadence_period_watch.sql uses for weekly period_start.
    dep_win AS (
      SELECT DISTINCT
        d AS routine,
        CASE pc.monitor_class
          WHEN 'weekly_sun'    THEN DATE_SUB(in_run_date, INTERVAL (EXTRACT(DAYOFWEEK FROM in_run_date) - 1) DAY)
          WHEN 'monthly_ftd'   THEN DATE_TRUNC(in_run_date, MONTH)
          WHEN 'quarterly_ftd' THEN DATE_TRUNC(in_run_date, QUARTER)
          WHEN 'annual_ftd'    THEN DATE_TRUNC(in_run_date, YEAR)
        END AS period_start
      FROM UNNEST(in_deps) AS d
      LEFT JOIN period_class pc ON pc.routine = d
    ),
    -- monitored = has EVER logged a completed run (no rolling window -- bigquery/48's unbounded fix).
    -- Self-bootstrapping: a dep absent from here is treated as satisfied, never blocking. See header.
    ever AS (
      SELECT DISTINCT routine
      FROM `stock-trading-498512.ops.run_log`
      WHERE status = 'completed'
    ),
    satisfied AS (
      SELECT DISTINCT w.routine
      FROM dep_win w
      JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = w.routine AND r.status = 'completed'
      WHERE (
        -- period dep: any completion inside in_run_date's own period
        (w.period_start IS NOT NULL AND r.run_date BETWEEN w.period_start AND in_run_date)
        -- daily / queue_driven / unrecognized dep: previous predicate, byte-for-byte
        OR (w.period_start IS NULL AND (
              r.run_date = in_run_date
              OR (
                r.run_date = DATE_SUB(in_run_date, INTERVAL 1 DAY)
                AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') < DATETIME(in_run_date, TIME '12:00:00')
              )
           ))
      )
    )
    SELECT STRING_AGG(w.routine, ', ' ORDER BY w.routine)
    FROM dep_win w
    JOIN ever e ON e.routine = w.routine              -- monitored deps only (self-bootstrapping)
    LEFT JOIN satisfied s ON s.routine = w.routine
    WHERE s.routine IS NULL                           -- ...that are NOT satisfied in their own window
  );

  IF missing IS NOT NULL AND missing != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'missing_dependency',
      FORMAT('%s blocked: upstream not completed for %t: %s', in_routine, in_run_date, missing),
      TO_JSON_STRING(STRUCT(in_routine AS routine, CAST(in_run_date AS STRING) AS run_date, missing AS missing_deps)));
    RAISE USING MESSAGE = FORMAT(
      '%s dependency check FAILED (run_date %t): missing completed upstream: %s', in_routine, in_run_date, missing);
  END IF;
END;

-- 173_freshness_cadence_aware.sql (2026-08-15)
-- Project: stock-trading-498512. Apply after 172_run_log_unpaired_terminal.sql.
--
-- APPLY TOGETHER with bigquery/63_scheduled_query_version_registry.sql's MERGE seed, which this
-- change bumps to daily_freshness_check='v4' in the same commit -- or apply the PROCEDURE FIRST.
-- Applying only the registry sets expected_version=v4 while a live v3 procedure keeps beating v3,
-- and state.scheduled_query_version_drift then raises a scheduled_query_version_drift warning every
-- night until the pair is reconciled. That partial-apply trap is documented at length in bigquery/63.
--
-- ALSO APPLY dbt/models/state/freshness.sql + dbt/models/state/system_health.sql in the same commit:
-- both are parallel-run ports of the two views below and scripts/dbt_parity.py compares them ROW BY
-- ROW against live. A new column on the live view that the dbt port lacks is exactly the schema drift
-- that check fails closed on.
--
-- ===== WHY =====
-- Triage of alert 903e505e-1215-4c6d-aad0-4df74499cc15 (critical, scheduled.freshness/staleness,
-- raised 2026-08-15 05:00 UTC): marks_fresh=false, engine_fresh=false, last_mark_date=2026-08-13,
-- last_trading_day=2026-08-14.
--
-- Nothing was broken. This is the 2026-08-08 Sun-Thu consolidation (ops/cadence.yaml) meeting a
-- dead-man's switch that was never updated for it, and it is a STRUCTURAL, EVERY-WEEK false positive:
--
--   * state.freshness asserted  MAX(events.daily_marks.mark_date) >= last_trading_day.
--   * last_trading_day comes from the MARKET calendar (bigquery/09) -- Mon-Fri minus holidays. Friday
--     is an ordinary trading day there and always will be.
--   * D2a -- the ONLY writer of events.daily_marks and (via ops.sp_daily_refresh) perf.strategy_daily
--     -- no longer runs Friday or Saturday. It recovers Friday on its SUNDAY run via the missed-day
--     backfill (task_plan/D2a.md step 1; get_price_history is a dated-bar pull, so Friday's close is
--     genuinely fetchable on Sunday).
--
-- So from Friday 22:40 UTC (when last_trading_day rolls to Friday) until Sunday's D2a completes,
-- the marks CANNOT cover last_trading_day, by design. The check ran anyway and fired. 2026-08-14 was
-- the FIRST Friday under the new cadence -- Friday 2026-08-07 has marks, Friday 2026-08-14 does not
-- -- which is why this had not surfaced before.
--
-- Left alone this recurs indefinitely: one critical staleness alert + operator email per weekend, and
-- TWO failed daily_freshness_check DTS runs per weekend (Sat and Sun 05:00 UTC both RAISE), each
-- firing the transfer config's own email-on-failure. A dead-man's switch that cries wolf every
-- weekend is worse than no switch -- the same reasoning bigquery/172's own header applies to scope.
--
-- ===== THE FIX, AND WHY IT IS SHAPED THIS WAY =====
-- The switch's expectation was wrong, not its strictness. What it should assert is:
--
--     marks/engine cover every trading day a SCHEDULED daily-tier run has already had the
--     opportunity to ingest.
--
-- New state.freshness column marks_due_through = the last trading day at or before the most recent
-- ELAPSED D2a slot, where the slot set is D2a's own cron (40 22 * * 0,1,2,3,4 -- ops/cadence.yaml).
-- marks_current / engine_current compare against that instead of last_trading_day.
--
-- SCHEDULE-derived, deliberately NOT RUN-derived. bigquery/155 solved the same Fri/Sat problem for
-- state.book_drawdown_watch.snapshot_stale with an EXISTS(D2a completed for last_trading_day) guard,
-- which is right for an ANOMALY detector but would be fatal here: this IS the dead-man's switch for
-- D2a, and keying it on "did D2a run" makes it vacuous exactly when D2a has stopped running. Under
-- the definition below the slots keep elapsing whether or not D2a fires, so a D2a that dies still
-- trips the switch. Worked through:
--   * Sat 05:00 UTC -- last elapsed slot Thu; due_through = Thu; marks = Thu  -> GREEN (was: false-fire)
--   * Sun 05:00 UTC -- last elapsed slot Thu; due_through = Thu; marks = Thu  -> GREEN (was: false-fire)
--   * Mon 05:00 UTC -- last elapsed slot Sun; due_through = FRI; marks must now include Friday. If
--     Sunday's D2a did not run, or ran but failed to backfill Friday, this FIRES -- correctly, and
--     within ~6h of the failure. The teeth are intact; only the false window is gone.
--   * Thanksgiving-shaped weeks work too: a Thursday holiday leaves due_through = Wed on Fri/Sat, and
--     the half-day Friday (is_trading_day = TRUE) only becomes due after Sunday's slot, as it should.
--
-- marks_fresh / engine_fresh / d2_ran_last_trading_day / last_trading_day are left BYTE-IDENTICAL and
-- keep their old meaning. That is deliberate: state.trading_enabled, state.trading_enabled_mechanical
-- and state.b3_trading_enabled_check (canonical bigquery/107) read marks_fresh/engine_fresh directly
-- as hard AND-terms, and this change must not loosen the order-staging gate by one inch. Those gates
-- stay exactly as strict as they are today -- FALSE Friday evening through Sunday's D2a, which is
-- harmless because D2 (the only order-crafting routine) is itself Sun-Thu and runs 35 min AFTER D2a.
-- d2_ran_last_trading_day is also unchanged: it is informational (never an all_green term), and
-- "D2 did not run on the last trading day" is a TRUE statement on a Saturday, not a defect.
--
-- all_green DOES move to the cadence-aware terms. It is display-only now -- bigquery/23's
-- state.trading_enabled (its last gate consumer) was superseded by bigquery/107, which reads
-- state.freshness directly and never touches all_green. Remaining readers are the dashboard banner
-- (ops/dashboard/generate_dashboard.py:159) and ops/weekly_report/weekly_report.gs's "may be stale"
-- caveat. W1 runs Sunday 07:30 UTC, inside the old false window, so that caveat has been printing on
-- the weekly report every week since 2026-08-08. This fixes that too.
--
-- ===== THE CLASS, SWEPT =====
-- Every other detector comparing a data-recency date against the market calendar was checked. The
-- 2026-08-08 consolidation had already hardened them -- bigquery/112 (catchup readiness, rebuilt on
-- DAYOFWEEK), bigquery/132 (9-day window, re-derived for this gap), bigquery/151 (2->4 days),
-- bigquery/153/155/157 (snapshot gap + D2a-completed guard), bigquery/12/142 (cadence_watch is pure
-- DAYOFWEEK), and the park_allocator heartbeat block in bigquery/172 (trading-day COUNTS, immune by
-- construction). state.freshness was the one that got missed.
--
-- ONE other live instance was found and is fixed below: state.park_reconciliation.park_mark_fresh
-- (bigquery/92) carried the identical `>= last_trading_day` predicate off the same D2a-written marks.
-- It gates nothing and raises nothing, but it is NOT dead prose -- Operating_Protocols.md 13.A cites
-- it by name as the staleness guard on the event-sourced park holding, and ops/RUNBOOK.md:2997 already
-- records a session having to reason past a park_mark_fresh=false that was expected. Leaving it would
-- make a GENUINE park-mark staleness indistinguishable from the weekly artifact. Repointed to the same
-- marks_due_through so there is one definition of "as fresh as it should be". The frozen SGOV-only
-- sibling state.sgov_reconciliation (bigquery/54, historical record since the 2026-07-15 VOO cutover)
-- is deliberately NOT touched.
--
-- ops.sp_auto_resolve_alerts is deliberately NOT touched. Its Rule 4 live_would_clear still reads
-- marks_fresh/engine_fresh, which is STRICTER than the new raise predicate (marks_fresh=TRUE implies
-- marks_current=TRUE), so there is no raise-without-possible-clear deadlock -- only a clear that can
-- lag by hours in the rare genuine case. Reproducing that 15KB procedure to shave that latency is not
-- worth the transcription risk on a load-bearing alert-lifecycle path. Its echo arm reads the payload
-- keys $.marks_fresh/$.engine_fresh, which remain in the payload and keep their old meaning, so it
-- cannot mis-resolve either. The ops.alert_policy resolve_rule TEXT is updated below so the written
-- rule matches the new raise basis.

-- ============================================================================
-- 1. state.freshness -- SUPERSEDES bigquery/10_observability.sql:121-144.
--    Adds marks_due_through / marks_current / engine_current. Every pre-existing column is unchanged.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.freshness` AS
WITH ltd AS (SELECT last_trading_day, is_trading_day, today FROM `stock-trading-498512.state.trading_day_today`),
-- The daily-tier serving schedule, derived from D2a's cron: 40 22 * * 0,1,2,3,4 (ops/cadence.yaml).
-- DAYOFWEEK is 1=Sunday..7=Saturday, so NOT IN (6,7) is Sunday-Thursday -- the same encoding
-- bigquery/12's daily_sun_thu CASE uses. Slot instants are stamped in UTC because the cron is UTC and
-- fixed (the fleet is 100% fixed-UTC by design, so DST moves the Denver wall clock, never the cron);
-- at 22:40 UTC the Denver date equals the UTC date year-round (22:40 minus 6h or 7h is the same day),
-- so generating Denver dates and stamping them at 22:40 UTC introduces no seam.
slot AS (
  SELECT MAX(sd) AS last_elapsed_slot_date
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 28 DAY),
                                  CURRENT_DATE('America/Denver'))) AS sd
  WHERE EXTRACT(DAYOFWEEK FROM sd) NOT IN (6, 7)
    AND TIMESTAMP(DATETIME(sd, TIME '22:40:00')) <= CURRENT_TIMESTAMP()
),
due AS (
  SELECT MAX(mc.cal_date) AS v
  FROM `stock-trading-498512.state.market_calendar` mc
  WHERE mc.is_trading_day
    AND mc.cal_date <= (SELECT last_elapsed_slot_date FROM slot)
),
m  AS (SELECT MAX(mark_date)   AS v FROM `stock-trading-498512.events.daily_marks`),
e  AS (SELECT MAX(as_of_date)  AS v FROM `stock-trading-498512.perf.strategy_daily`),
d  AS (SELECT MAX(entry_date)  AS v FROM `stock-trading-498512.events.decision_log`),
d2 AS (SELECT MAX(run_date)    AS v FROM `stock-trading-498512.ops.run_log` WHERE routine = 'D2' AND status = 'completed')
SELECT
  (SELECT last_trading_day FROM ltd) AS last_trading_day,
  (SELECT v FROM m)  AS last_mark_date,
  (SELECT v FROM e)  AS engine_through,
  (SELECT v FROM d)  AS last_decision_date,
  (SELECT v FROM d2) AS last_d2_run_date,
  -- The last trading day a SCHEDULED D2a run has already had the opportunity to ingest. On Mon-Thu
  -- evenings this equals last_trading_day; on Friday/Saturday it stays at Thursday, and it advances
  -- to Friday only once Sunday's 22:40 UTC slot has elapsed. NULL-safe by the same fail-loud rule
  -- below: if the market calendar is exhausted this goes NULL and both _current flags read FALSE.
  (SELECT v FROM due) AS marks_due_through,
  -- COALESCE -> FALSE so the dead-man's switch fails LOUD, never silent: if a source table is
  -- empty, or last_trading_day is NULL (e.g. state.market_calendar's GENERATE_DATE_ARRAY upper
  -- bound -- 2030-12-31 per bigquery/09_market_calendar.sql -- is reached because the W5
  -- auto-extend routine has stopped running; the separate holiday-seed accuracy runs out after
  -- 2029 and causes a different symptom -- a real holiday silently misclassified as a trading
  -- day, not a NULL last_trading_day), a bare `>=` would yield NULL -> all_green NULL -> the
  -- freshness check's `IF NOT all_green` would NOT fire. FALSE instead makes it alert (and nags
  -- to extend the calendar).
  COALESCE((SELECT v FROM m) >= (SELECT last_trading_day FROM ltd), FALSE) AS marks_fresh,
  COALESCE((SELECT v FROM e) >= (SELECT last_trading_day FROM ltd), FALSE) AS engine_fresh,
  COALESCE((SELECT v FROM d2) >= (SELECT last_trading_day FROM ltd), FALSE) AS d2_ran_last_trading_day,
  -- CADENCE-AWARE pair (2026-08-15). These are what the daily_freshness_check dead-man now reads.
  -- marks_fresh/engine_fresh above are STRICTLY STRONGER (they demand coverage of a trading day no
  -- scheduled run has reached yet on Fri/Sat) and are retained unchanged because the trading gates in
  -- bigquery/107 read them -- do not "simplify" the two pairs into one.
  COALESCE((SELECT v FROM m) >= (SELECT v FROM due), FALSE) AS marks_current,
  COALESCE((SELECT v FROM e) >= (SELECT v FROM due), FALSE) AS engine_current,
  CURRENT_TIMESTAMP() AS checked_at;

-- ============================================================================
-- 2. state.system_health -- SUPERSEDES bigquery/23_trading_control.sql:411-434.
--    Passes the three new columns through (so the staleness alert PAYLOAD carries them -- the payload
--    is TO_JSON_STRING of this view) and moves all_green onto the cadence-aware terms. The alert-count
--    and position-drift terms of all_green are unchanged.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.system_health` AS
WITH alerts_summary AS (
  -- Computed once and reused below (2026-07-04 audit finding: open_critical_alerts and the
  -- identical subquery embedded in all_green were two hand-kept copies of the same COUNTIF,
  -- requiring them to be kept in sync by hand in this load-bearing one-row health rollup).
  SELECT
    COUNTIF(NOT resolved AND severity = 'critical') AS open_critical_alerts,
    COUNTIF(NOT resolved) AS open_alerts
  FROM `stock-trading-498512.ops.alerts`
)
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  f.marks_due_through, f.marks_current, f.engine_current,
  eh.is_healthy AS embeddings_healthy,
  a.open_critical_alerts,
  a.open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM `stock-trading-498512.perf.kill_flags`) AS firing_kill_flags,
  COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE) AS position_drift_detected,
  -- CADENCE-AWARE as of 2026-08-15 (bigquery/173): was marks_fresh AND engine_fresh, which read FALSE
  -- every Friday evening through Sunday's D2a purely because the daily tier is Sun-Thu. all_green is
  -- display-only now (bigquery/107's trading gates read state.freshness directly and never read this
  -- column), so this makes the dashboard banner and the W1 weekly-report staleness caveat honest.
  (f.marks_current AND f.engine_current AND eh.is_healthy
     AND a.open_critical_alerts = 0
     AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh, alerts_summary a;

-- ============================================================================
-- 3. state.park_reconciliation -- SUPERSEDES bigquery/92_park_allocator.sql:440-483.
--    IDENTICAL to bigquery/92 except park_mark_fresh's basis: last_trading_day -> marks_due_through.
--    Nothing else in the view changes; no consumer of any other column is affected.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_reconciliation` AS
WITH p AS (SELECT * FROM `stock-trading-498512.state.park_position_current`),
dm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
sm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
mark AS (
  SELECT
    p.ticker,
    COALESCE(dm.park_close, sm.park_close)         AS park_close,
    COALESCE(dm.park_mark_date, sm.park_mark_date) AS park_mark_date
  FROM p
  LEFT JOIN dm ON dm.ticker = p.ticker
  LEFT JOIN sm ON sm.ticker = p.ticker
)
SELECT
  p.ticker                    AS park_ticker,
  p.events_shares              AS events_park_shares,
  p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash,
  p.parking_commissions_total,
  mark.park_close,
  mark.park_mark_date,
  -- COALESCE to 0 (2026-07-19 fix): the CASH policy vehicle has no price series in either marks
  -- source (mark.park_close is NULL for ticker='CASH'), so 0 shares * NULL close would otherwise
  -- surface as NULL, not 0, on a CASH-parked day. A CASH-parked day correctly shows $0 instrument
  -- value here — the real cash lives in state.account_latest.total_cash, not this column.
  ROUND(p.events_shares * COALESCE(mark.park_close, 0), 2) AS events_park_market_value,
  -- BASIS CHANGED 2026-08-15 (bigquery/173): was `>= last_trading_day`, which read FALSE every
  -- Friday/Saturday under the Sun-Thu daily tier because state.daily_marks_curated is D2a-written.
  -- marks_due_through is "as fresh as the schedule allows", so a FALSE here is once again a real
  -- signal. Operating_Protocols.md 13.A cites this column by name as the park staleness guard.
  COALESCE(mark.park_mark_date >= (SELECT marks_due_through FROM `stock-trading-498512.state.freshness`),
           FALSE)                                   AS park_mark_fresh,
  p.is_policy_vehicle,
  CURRENT_TIMESTAMP()                                AS checked_at
FROM p
LEFT JOIN mark ON mark.ticker = p.ticker;

-- ============================================================================
-- 4. ops.sp_sq_daily_freshness_check -- SUPERSEDES bigquery/75_scheduled_query_wrappers.sql:68-98.
--    SQ_VERSION v3 -> v4. Repoints the RAISE predicate onto the cadence-aware components. No other
--    behaviour changes: it still raises the same category at the same severity with the same payload,
--    and it still RAISEs so the DTS transfer config's email-on-failure fires on a GENUINE fault.
--    PAIRED with the bigquery/63 registry bump to 'v4' -- apply this procedure first, or both together.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_daily_freshness_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_freshness_check', 'v4', 'daily_freshness_check.sql ran');
  BEGIN
    -- STALENESS PART-3 (MON, 2026-07-17 source-echo suppression) narrowed this dead-man to the genuine
    -- DATA-STALENESS COMPONENTS only -- dropping state.system_health.all_green's open_critical_alerts
    -- term, which had made this an alert-on-alert ECHO: any open critical flipped all_green FALSE and
    -- re-raised a content-free 'staleness' critical here, and a staleness echo of a since-healed
    -- overnight transient then kept trading disabled all day while D2a hit a FATAL gate whose clear
    -- condition needed the very marks D2a would ingest (the 2026-07-14/07-17 circular deadlock;
    -- bigquery/78 broke it at the GATE layer, this stopped it at the SOURCE).
    --
    -- v4 (2026-08-15, bigquery/173) keeps that shape and only changes the two freshness components
    -- from marks_fresh/engine_fresh to marks_current/engine_current -- i.e. from "covers the last
    -- MARKET trading day" to "covers every trading day a SCHEDULED D2a run has already had the chance
    -- to ingest". Under the Sun-Thu daily tier the old form was structurally unsatisfiable from Friday
    -- 22:40 UTC until Sunday's D2a, so this fired -- and failed this DTS job -- twice every weekend
    -- with nothing wrong. See bigquery/173's header for the full derivation and for why the fix is
    -- schedule-derived rather than keyed on D2a having actually run (that would make the dead-man's
    -- switch vacuous precisely when D2a has stopped). embeddings_healthy and position_drift_detected
    -- are unchanged; neither is cadence-coupled.
    IF (SELECT NOT (marks_current AND engine_current AND embeddings_healthy AND NOT position_drift_detected)
        FROM `stock-trading-498512.state.system_health`) THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'critical', 'scheduled.freshness', 'staleness',
        'Daily freshness check: a data-staleness component (marks/engine freshness, embedding health, or position reconciliation) is not green',
        (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.system_health` t));
      RAISE USING MESSAGE = CONCAT(
        'STOCK-TRADING freshness check FAILED (data-staleness component not green): ',
        (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.system_health` t));
    END IF;
  END;
END;

-- ============================================================================
-- 5. ops.alert_policy -- the WRITTEN resolve rule for 'staleness' still described the pre-2026-08-15
--    raise basis. The procedure is unchanged (see this file's header for why ops.sp_auto_resolve_alerts
--    is deliberately left alone); only the documentation of what raises and what clears is corrected,
--    so a future triage session is not sent to the wrong predicate. latching stays FALSE.
-- ============================================================================
MERGE `stock-trading-498512.ops.alert_policy` T
USING (
  SELECT 'staleness' AS category, FALSE AS latching,
         'RAISED (bigquery/173, 2026-08-15) on state.system_health.marks_current AND engine_current AND embeddings_healthy AND NOT position_drift_detected -- the CADENCE-AWARE components, which expect marks/engine to cover only trading days a scheduled D2a run has already been able to ingest (state.freshness.marks_due_through). The older marks_fresh/engine_fresh basis expected coverage of the last MARKET trading day and so was structurally unsatisfiable every Friday/Saturday under the Sun-Thu daily tier. RESOLVED by ops.sp_auto_resolve_alerts Rule 4, which is deliberately UNCHANGED and still re-checks the STRICTER live state.freshness.marks_fresh AND engine_fresh, plus state.embedding_health.is_healthy, NOT state.position_reconciliation drift, and zero OTHER open criticals (excluding this category AND trading_halted, mirroring the trading_enabled gate views). marks_fresh=TRUE implies marks_current=TRUE, so there is no raise-without-possible-clear deadlock -- a genuine alert can only clear later than the fault healed, never not at all.' AS resolve_rule
) S
ON T.category = S.category
WHEN MATCHED THEN
  UPDATE SET latching = S.latching, resolve_rule = S.resolve_rule, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (category, latching, resolve_rule) VALUES (S.category, S.latching, S.resolve_rule);

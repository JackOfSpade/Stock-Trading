-- Alert-lifecycle policy: verified auto-resolution for self-healing criticals, latching preserved
-- for capital classes (2026-07-07, full-system self-improvement/self-execution audit WP2).
-- Project: stock-trading-498512. Apply after 12_cadence_monitor.sql, 23_trading_control.sql,
-- 33_gate_ordering_fix.sql.
--
-- WHY THIS EXISTS. Every critical alert in this system is deliberately never auto-resolved
-- (cadence_check.sql's #14 auto-age only ever touched WARNING self-healing classes) -- on the
-- theory that a human should review a critical before clearing it. That discipline is correct for
-- capital-affecting classes (cash_tripwire, order_guard_block, connector, twr_bad_mark) but wrong
-- for classes whose truth is a MECHANICALLY RE-CHECKABLE fact about ops.run_log / live view state
-- (missing_dependency, missed_run, the freshness staleness echo, a stalled run since superseded) --
-- for those, "never auto-resolve" just means every transient becomes a standing block on
-- state.trading_enabled until a human runs a bare UPDATE, which is exactly the toil this file
-- removes. Live proof this is not hypothetical (verified 2026-07-07): D1 stranded on 2026-07-06
-- (session started, never completed, branch never pushed); D2 correctly halted on the missing
-- dependency; but the resulting missing_dependency + missed_run + staleness criticals will persist
-- and keep state.trading_enabled = FALSE even AFTER D1/D2 legitimately complete tonight, unless
-- something proves the underlying condition healed and resolves them.
--
-- DESIGN: ops.alert_policy is a FAIL-CLOSED allowlist -- a category absent from it (or explicitly
-- marked latching=TRUE) is NEVER touched by ops.sp_auto_resolve_alerts, preserving the existing
-- asymmetric-clearing discipline (bigquery/23_trading_control.sql's own comment: "an AUTO halt
-- should NOT be cleared by a bare flip back to FALSE without a human reviewing why it fired
-- first") for every capital-affecting class. Only categories explicitly whitelisted latching=FALSE
-- are eligible, and each is resolved only against a MECHANICALLY VERIFIED condition (never a bare
-- age-out), stamped in resolved_note so the resolution is auditable after the fact. A monthly fire
-- drill (ops.sp_fire_drill_alert_latch) proves a non-whitelisted category is never touched, mirroring
-- the existing "an untested breaker is theater" discipline (ops.sp_fire_drill_order_guard,
-- 23_trading_control.sql).
--
-- SEPARATELY, this file also fixes the "gate self-latches" defect: ops.sp_assert_trading_enabled(
-- _mechanical) raises its OWN critical alert (category='trading_halted') when the gate trips -- and
-- both state.trading_enabled and state.trading_enabled_mechanical then count THAT alert against
-- their own open-critical-alert check, so a transient trip can never self-clear even once its root
-- cause heals; it takes a human UPDATE every time. The fix: both gate views now count blocking
-- criticals EXCLUDING category='trading_halted' (computed directly from ops.alerts, not via
-- state.system_health.open_critical_alerts, which keeps showing the TRUE total for honest
-- diagnostics/dashboards -- only the two gate decisions change). state.system_health itself is
-- UNCHANGED by this file.

-- ===== ops.alert_policy — fail-closed auto-resolution allowlist =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.alert_policy` (
  category STRING NOT NULL,
  latching BOOL NOT NULL,        -- TRUE = human-only clear (default posture for anything not seeded FALSE)
  resolve_rule STRING,           -- human-readable description of the mechanical condition, if latching=FALSE
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  note STRING
) OPTIONS(description='Fail-closed allowlist for ops.sp_auto_resolve_alerts. A category absent from this table is latching by construction (the procedure only ever queries WHERE category IN (SELECT category FROM this table WHERE NOT latching)) — adding a row is the only way to make a class auto-resolvable, and removing/flipping a row back to latching=TRUE takes effect on the next call with no code change.');

-- Seed exactly once. Only the three classes this file's procedure actually resolves are latching=FALSE;
-- every other category that has ever been raised in this repo (cash_tripwire, order_guard_block,
-- order_guard_fire_drill_failed, twr_bad_mark, connector, dual_path, embedding, merge_conflict,
-- missed_confirmation, staging, trading_halted, kill_flag_firing, gate_ordering, instruction_drift,
-- trigger_missing, period_missed, position_drift, calendar_runway_low, restore_stale, ddl_drift,
-- backup_stale, ops_backup_stale, automation_heartbeat) stays latching=TRUE by simple ABSENCE — no
-- need to enumerate them here; the allowlist shape makes silence the safe default.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('missing_dependency' AS category, FALSE AS latching,
    'every routine named in the alert payload has a completed ops.run_log row with run_date >= the blocked run_date, OR the blocked run_date is >1 calendar day stale (America/Denver) — recovery for a closed operating day is owned by missed_run/catch-up, not a standing freeze on future days' AS resolve_rule,
    'seeded 2026-07-07, self-improvement audit WP2' AS note),
  STRUCT('missed_run', FALSE,
    'every routine named in the alert payload array has a completed ops.run_log row with run_date >= that routine''s payload date, OR the alert is >1 calendar day stale',
    'seeded 2026-07-07, self-improvement audit WP2'),
  STRUCT('routine_stalled', FALSE,
    'the stalled routine has since logged ANY terminal status (completed/failed/halted) for the same run_date, OR the alert is >1 calendar day stale — mirrors the existing 7-day auto-age in cadence_check.sql #14 but resolves faster once the system has demonstrably moved on',
    'seeded 2026-07-07, self-improvement audit WP2; routine_stalled is warning-severity and does not gate trading_enabled on its own, but resolving it promptly keeps the alert digest honest'),
  STRUCT('staleness', FALSE,
    'state.freshness.marks_fresh AND engine_fresh, state.embedding_health.is_healthy, NOT state.position_reconciliation drift, and zero OTHER open criticals (excluding this alert''s own category) are all currently true — i.e. all_green would read TRUE right now if this alert did not count against itself',
    'seeded 2026-07-07, self-improvement audit WP2; self-referential like the trading_halted gate-exclusion below, so it is resolved by live re-check, not by an ops.run_log lookback')
])
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alert_policy`);

-- ===== ops.sp_auto_resolve_alerts — mechanized, evidence-based clearing of whitelisted classes =====
-- Call this BEST-EFFORT at the start of every routine's Observability preamble (alongside the
-- existing best-effort run-logging calls) and/or from a scheduled query — see Claude_Task_Plan.md
-- "Observability" for the wiring. Never gates, never aborts a routine; purely a cleanup pass.
--
-- IMPLEMENTATION NOTE (confirmed live 2026-07-07): BigQuery rejects a subquery that is DOUBLY
-- correlated to an outer TABLE row -- a NOT EXISTS nested inside another NOT EXISTS that both
-- reference the same outer ops.alerts row -- with "Correlated subqueries that reference other
-- tables are not supported unless they can be de-correlated". This is stricter than
-- ops.sp_assert_deps's pattern (12_cadence_monitor.sql), which only has ONE level of correlation
-- (EXISTS/NOT EXISTS as AND-ed siblings, not nested inside each other) against an UNNEST'd
-- scripting ARRAY PARAMETER, not a live table. The supported de-correlation, verified live: flatten
-- the per-item check into a CROSS JOIN UNNEST(...) + LEFT JOIN against ops.run_log (matching
-- condition in the JOIN's ON clause, never WHERE, so a non-match surfaces as NULL rather than
-- dropping the row) + GROUP BY alert_id + HAVING LOGICAL_AND(<per-row satisfied-or-stale
-- expression>) -- an "efficient JOIN" per BigQuery's own error message, with no correlated
-- subquery anywhere. A subquery that merely SELF-references ops.alerts (Rule 4's own
-- open-critical-count) hits the same restriction even with no row correlation at all, so that
-- count is computed as an independent scripting variable FIRST, then used as a plain boolean.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`()
BEGIN
  DECLARE eligible_dep, eligible_run, eligible_stalled, eligible_stale ARRAY<STRING>;
  DECLARE staleness_would_clear BOOL;

  -- Rule 1: missing_dependency.
  SET eligible_dep = (
    SELECT ARRAY_AGG(a.alert_id)
    FROM `stock-trading-498512.ops.alerts` a
    CROSS JOIN UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
    LEFT JOIN `stock-trading-498512.ops.run_log` r
      ON r.routine = dep AND r.status = 'completed'
         AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
    WHERE NOT a.resolved AND a.category = 'missing_dependency'
      AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
    GROUP BY a.alert_id
    HAVING LOGICAL_AND(r.routine IS NOT NULL)
        OR SAFE.PARSE_DATE('%Y-%m-%d', ANY_VALUE(JSON_VALUE(a.payload, '$.run_date'))) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: dependency satisfied or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_dep, []));

  -- Rule 2: missed_run (payload is a JSON array of {routine, schedule, today}).
  SET eligible_run = (
    SELECT ARRAY_AGG(a.alert_id)
    FROM `stock-trading-498512.ops.alerts` a
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
    LEFT JOIN `stock-trading-498512.ops.run_log` r
      ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
         AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
    WHERE NOT a.resolved AND a.category = 'missed_run'
      AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
    GROUP BY a.alert_id
    HAVING LOGICAL_AND(
      r.routine IS NOT NULL
      OR SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today')) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: named routine(s) since completed or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_run, []));

  -- Rule 3: routine_stalled (payload is a JSON array of {routine, run_date, hours_since_started}).
  SET eligible_stalled = (
    SELECT ARRAY_AGG(a.alert_id)
    FROM `stock-trading-498512.ops.alerts` a
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
    LEFT JOIN `stock-trading-498512.ops.run_log` r
      ON r.routine = JSON_VALUE(item, '$.routine')
         AND r.run_date = SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.run_date'))
         AND r.status IN ('completed', 'failed', 'halted')
    WHERE NOT a.resolved AND a.category = 'routine_stalled'
      AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
    GROUP BY a.alert_id
    HAVING LOGICAL_AND(
      r.routine IS NOT NULL
      OR SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.run_date')) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: stalled run(s) since reached a terminal status, or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stalled, []));

  -- Rule 4: staleness — self-referential (resolve iff all_green's OTHER components are already true
  -- and no OTHER open critical remains; run last so rules 1-3 above have already cleared what they can
  -- within this same call, and their resolutions are visible to this rule's own open-critical count).
  -- The open-critical count is computed FIRST as its own variable (a bare SELECT with no correlation)
  -- because a subquery that self-references ops.alerts from within a query that also filters
  -- ops.alerts hits the same de-correlation restriction, even with zero row-level correlation.
  -- EXCLUDES category='trading_halted', mirroring state.trading_enabled/trading_enabled_mechanical's own
  -- exclusion above -- gap found 2026-07-09 (self-improvement audit): without it, a lingering trading_halted
  -- echo (itself just a symptom of the SAME criticals this procedure already resolves) kept staleness
  -- latched even after missing_dependency/missed_run legitimately cleared, which in turn kept
  -- state.trading_enabled FALSE forever -- staleness IS counted by the gates' own blocking-critical query,
  -- unlike trading_halted -- the identical self-latch this file's header already describes fixing for the
  -- two gate views, just missed in this rule. Live incident: the 2026-07-06/07 D1-stranding cascade needed
  -- three separate manual ops.alerts UPDATEs (trading_halted, then missed_run x2) to unwind on 2026-07-08/09,
  -- when resolving trading_halted alone should have let this rule finish the job mechanically.
  SET staleness_would_clear = (
    SELECT f.marks_fresh AND f.engine_fresh AND eh.is_healthy
      AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
      AND (SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('staleness', 'trading_halted')) FROM `stock-trading-498512.ops.alerts`) = 0
    FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh
  );
  SET eligible_stale = (
    SELECT ARRAY_AGG(alert_id)
    FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved AND category = 'staleness'
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND COALESCE(staleness_would_clear, FALSE)
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: underlying freshness/health conditions verified green, no other open critical (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stale, []));
END;

-- ===== ops.sp_fire_drill_alert_latch — proves a non-whitelisted category is NEVER auto-resolved =====
-- Mirrors ops.sp_fire_drill_order_guard's discipline (23_trading_control.sql): an untested breaker is
-- theater. Inserts a synthetic critical in a class that must NEVER auto-resolve (cash_tripwire),
-- calls the resolver, asserts it is still unresolved, then ALWAYS cleans up the synthetic row
-- (never leaves a fake critical open, whichever way the assertion goes). Call periodically (e.g.
-- monthly, alongside the order-guard drill) or ad hoc after any edit to this file.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_alert_latch`()
BEGIN
  DECLARE test_id STRING DEFAULT GENERATE_UUID();
  DECLARE still_unresolved BOOL;

  INSERT INTO `stock-trading-498512.ops.alerts` (alert_id, severity, source, category, message, payload)
  VALUES (test_id, 'critical', 'ops.sp_fire_drill_alert_latch', 'cash_tripwire',
    CONCAT('FIRE DRILL — latch test (synthetic, auto-cleaned) id=', test_id),
    PARSE_JSON(TO_JSON_STRING(STRUCT(TRUE AS synthetic, test_id AS drill_id))));

  CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();

  SET still_unresolved = (SELECT NOT resolved FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id);

  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('fire-drill cleanup (synthetic test row; latch_held=', CAST(still_unresolved AS STRING), ')')
  WHERE alert_id = test_id;

  IF NOT still_unresolved THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_alert_latch', 'alert_latch_fire_drill_failed',
      'The alert-latch fire drill found ops.sp_auto_resolve_alerts clearing a category it MUST NEVER touch (cash_tripwire) — the fail-closed allowlist is not load-bearing. Investigate ops.alert_policy / ops.sp_auto_resolve_alerts immediately before trusting it.',
      TO_JSON_STRING(STRUCT(test_id AS drill_id)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`('FIRE_DRILL_ALERT_LATCH', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, 1, NULL, 'cash_tripwire correctly stayed latched through ops.sp_auto_resolve_alerts.');
  END IF;
END;

-- ===== ops.sp_fire_drill_alert_resolve — proves a whitelisted class WITH a satisfied condition IS resolved =====
-- Positive-path companion to ops.sp_fire_drill_alert_latch (which only proves a non-whitelisted class is NEVER
-- touched). This proves that a whitelisted class (missing_dependency) whose mechanical condition is satisfied IS
-- in fact auto-resolved by ops.sp_auto_resolve_alerts — guarding against silent payload-shape drift between the
-- producers (ops.sp_assert_deps in 12_cadence_monitor.sql; scheduled_queries/cadence_check.sql) and this file's
-- Rule 1 JSON paths. If a producer renames a payload key or changes the array/object shape, the resolver stops
-- matching, whitelisted criticals latch forever, and state.trading_enabled stays FALSE — a failure no offline
-- test can catch (the suite has no live BigQuery). Inserts a synthetic completed run_log dependency row + a
-- synthetic critical missing_dependency alert whose payload is built EXACTLY as ops.sp_assert_deps builds it
-- (STRUCT(routine, run_date, missing_deps)), calls the resolver, records whether the synthetic alert cleared,
-- then ALWAYS deletes BOTH synthetic rows (the delete runs BEFORE the assert-and-raise, so a failed drill still
-- cleans up). FIRE_DRILL_DEP is a throwaway routine name used nowhere else, so the run_log DELETE is precise.
-- Call periodically (e.g. monthly, alongside the latch + order-guard drills) or ad hoc after any edit to this file.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_alert_resolve`()
BEGIN
  DECLARE test_id STRING DEFAULT GENERATE_UUID();
  DECLARE drill_date DATE DEFAULT CURRENT_DATE('America/Denver');
  DECLARE did_resolve BOOL;

  -- (a) synthetic completed dependency run — the mechanical fact Rule 1 checks for.
  INSERT INTO `stock-trading-498512.ops.run_log` (routine, run_date, status, note)
  VALUES ('FIRE_DRILL_DEP', drill_date, 'completed',
    CONCAT('FIRE DRILL — resolve test (synthetic, auto-cleaned) id=', test_id));

  -- (b) synthetic critical missing_dependency alert; payload shaped EXACTLY as ops.sp_assert_deps builds it
  --     (12_cadence_monitor.sql), naming FIRE_DRILL_DEP as the now-satisfied upstream.
  INSERT INTO `stock-trading-498512.ops.alerts` (alert_id, severity, source, category, message, payload)
  VALUES (test_id, 'critical', 'ops.sp_fire_drill_alert_resolve', 'missing_dependency',
    CONCAT('FIRE DRILL — resolve test (synthetic, auto-cleaned) id=', test_id),
    PARSE_JSON(TO_JSON_STRING(STRUCT(
      'FIRE_DRILL_DEP_CONSUMER' AS routine,
      CAST(drill_date AS STRING) AS run_date,
      'FIRE_DRILL_DEP' AS missing_deps))));

  -- (c) run the resolver, then (d) capture whether the synthetic alert cleared.
  CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  SET did_resolve = (SELECT resolved FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id);

  -- (e) ALWAYS clean up BOTH synthetic rows, BEFORE the assert-and-raise, so a failed drill leaves nothing behind.
  DELETE FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id;
  DELETE FROM `stock-trading-498512.ops.run_log` WHERE routine = 'FIRE_DRILL_DEP';

  -- (f) verdict.
  IF NOT COALESCE(did_resolve, FALSE) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_alert_resolve', 'alert_resolve_fire_drill_failed',
      'The alert-resolve fire drill found ops.sp_auto_resolve_alerts FAILED to clear a whitelisted class (missing_dependency) whose mechanical condition was satisfied — likely payload-shape drift between ops.sp_assert_deps / scheduled_queries/cadence_check.sql and ops.sp_auto_resolve_alerts. Auto-resolution is silently disabled: whitelisted criticals will latch and keep state.trading_enabled FALSE. Investigate ops.sp_auto_resolve_alerts payload paths immediately.',
      TO_JSON_STRING(STRUCT(test_id AS drill_id)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`('FIRE_DRILL_ALERT_RESOLVE', drill_date, 'completed', NULL, NULL, 1, NULL,
      'missing_dependency correctly auto-resolved by ops.sp_auto_resolve_alerts once its mechanical condition was satisfied.');
  END IF;
END;

-- ===== state.trading_enabled — REDEFINED to exclude the gate's own trading_halted echo =====
-- Same composition as 23_trading_control.sql's original (halt_all / marks_fresh / engine_fresh /
-- embeddings_healthy / zero open criticals / no position drift / no drawdown breach) but computes
-- blocking criticals directly from ops.alerts EXCLUDING category='trading_halted', instead of going
-- through state.system_health.open_critical_alerts (which still reports the TRUE total, unchanged,
-- for honest diagnostics/dashboards — only this gate's OWN decision changes). Without this, a
-- transient trip's own alert would keep the gate closed forever after the root cause heals, since
-- critical alerts are (correctly, for every other class) never auto-resolved.
--
-- SUPERSEDED LIVE by bigquery/47_trading_enabled_resync.sql (2026-07-14) — this definition was
-- silently clobbered live on 2026-07-11 when 23_trading_control.sql was re-applied in isolation to
-- add the snapshot_stale term (ITEM 16), reverting this view to the pre-fix self-latching formula
-- for 3+ days. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE OR REPLACE VIEW statement live in isolation — see 47's header.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT drawdown_breach, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND COALESCE(eh.is_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.drawdown_breach, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN NOT COALESCE(eh.is_healthy, FALSE) THEN
      'state.embedding_health.is_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding the trading_halted gate echo) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, eh, al, pr, dd;

-- ===== state.trading_enabled_mechanical — REDEFINED, same trading_halted exclusion =====
-- Mirrors 33_gate_ordering_fix.sql's original composition (halt_all / embeddings_healthy / zero
-- open criticals / no position drift / no drawdown breach — deliberately still excludes marks_fresh/
-- engine_fresh, D2a's own same-run-circular term) but with the same blocking-criticals fix as above.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled_mechanical` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (
  SELECT embeddings_healthy, position_drift_detected
  FROM `stock-trading-498512.state.system_health`
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
dd AS (SELECT drawdown_breach, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.embeddings_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.drawdown_breach, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.embeddings_healthy, FALSE) THEN
      'state.system_health.embeddings_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding the trading_halted gate echo) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd;

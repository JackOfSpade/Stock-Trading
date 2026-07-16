-- SCHEDULED QUERY (fix A3 + 2026-06-22 automation-health additions): the cadence / control-plane
-- dead-man's switch. Complements daily_freshness_check.sql (which catches a stale ENGINE / D2 data work).
-- This one catches the things that "ran or didn't" rather than "data is current":
--   * missed_run            — a MONITORED routine expected today logged no 'completed' run (state.cadence_watch)
--   * backup_stale          — the events.* GCS backup has gone silent (state.backup_health; 16_automation_health.sql)
--   * automation_heartbeat  — an out-of-band Apps Script (alert_emailer / weekly_report) went silent (state.automation_heartbeat)
--   * instruction_drift     — a routine's live web-UI trigger differs from the canonical catalog (state.instruction_drift; W2)
--
-- SELF-BOOTSTRAPPING (see bigquery/12 + 16): every signal here only fires once a routine/backup/script has
-- demonstrably started logging, so this never false-alarms on something not yet adopted.
--
-- RECORD-THEN-RAISE: every condition writes a durable, idempotent ops.alerts row FIRST (so no condition
-- masks another), then a SINGLE consolidated RAISE at the end fires BigQuery's built-in "Send email
-- notifications on failure" — an identity-independent channel that delivers even when the thing that
-- failed is the alert emailer itself. instruction_drift is a config bug to FIX, not a halt, so it records
-- a warning but does NOT contribute to the RAISE (matching the prior behaviour).
--
-- TIMING: BigQuery schedules are UTC. Run ~05:15 UTC (≈ 22:45 MDT / 21:45 MST) — same Denver evening,
-- after D2/D3, like the freshness check. APPLY ORDER: bigquery/16_automation_health.sql must be applied
-- BEFORE re-pasting this query (it references state.backup_health + state.automation_heartbeat). See
-- ops/RUNBOOK.md "Scheduled queries". Also apply bigquery/34_alert_lifecycle.sql before re-pasting
-- (it defines ops.sp_auto_resolve_alerts, called below — self-improvement audit WP2, 2026-07-07), and
-- bigquery/38_run_log_selfheal.sql before re-pasting (it defines ops.sp_backfill_run_log_from_markers,
-- called FIRST below — RUNBOOK section 38 self-heal, ITEM 3). Also apply
-- bigquery/45_monitor_promotion.sql before re-pasting (it CREATEs ops.monitor_health_history, the
-- table this query's MERGE statements below target — 2026-07-14 audit finding: this dependency was
-- never listed here even though the MERGEs have needed it since it was added).
--
-- NOTE (repo vs live): this query's LIVE scheduled-query body still ran without the
-- sp_auto_resolve_alerts call as of this file's edit — the repo copy needs a console re-paste
-- (RUNBOOK "Scheduled queries" console procedure) to take effect. The routine-level wiring in
-- Claude_Task_Plan.md's Observability preamble (`CALL ops.sp_auto_resolve_alerts()` at the top of
-- every routine run) is the primary, already-live path; this scheduled-query call is defense in
-- depth for days with zero routine runs.
BEGIN
  DECLARE raise_msg STRING DEFAULT '';

  -- RUNBOOK section 38 self-heal (ITEM 3, bigquery/38_run_log_selfheal.sql): backfill any
  -- ops.run_log completion row whose routine already has a landed-commit marker in
  -- ops.routine_commit_markers, BEFORE evaluating missed_run/missing_dependency below, so a
  -- landed-but-unlogged strand self-heals the same night instead of tripping the dead-man's
  -- switch. (This proc also calls sp_auto_resolve_alerts() itself once it backfills anything,
  -- so the general call right below is defense-in-depth for unrelated alerts, not redundant
  -- plumbing.) Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_backfill_run_log_from_markers`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Mechanized alert auto-resolve (WP2, defense-in-depth alongside the routine-level call above).
  -- Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Auto-resolve STALE self-healing WARNING rows (2026-06-28, #14) so the weekly digest's "N open alerts"
  -- reflects live issues, not warnings the owner never manually closed (e.g. a 4-day-old self-healed
  -- stranded_session warning keeping the digest red). Targets only the self-CLEARING classes, warning
  -- severity, older than 7 days. A condition that is STILL true is simply re-raised by the checks below
  -- (sp_raise_alert_once), so this can only durably clear a row whose underlying condition has actually
  -- healed. Critical rows and the persistent-DRIFT classes (position_drift / ddl_drift /
  -- append_only_violation / restore_fidelity) are deliberately left untouched. Runs first, before any RAISE
  -- (which would abort the script). all_green keys only on open CRITICAL alerts, so this is purely a
  -- digest-quality fix, not a dead-man's-switch change.
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE,
      resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-aged (>7d self-healing warning; cadence_check.sql #14). ', COALESCE(resolved_note, ''))
  WHERE NOT resolved
    AND severity = 'warning'
    -- trigger_missing added 2026-07-04 (audit finding): its message used to embed a daily-changing
    -- day-count, defeating sp_raise_alert_once's dedup and letting undeduped rows accumulate
    -- indefinitely since it was the one self-healing class missing from this auto-age list. The
    -- message fix below (stable text) restores real dedup; this stays as defense-in-depth.
    AND category IN ('stranded_session', 'instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing')
    AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);

  -- missed_run (critical) — a monitored routine expected today did not complete.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'missed_run',
      CONCAT('Cadence check: monitored routine(s) expected today did not complete: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, schedule, today)))
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
    SET raise_msg = raise_msg || CONCAT('[missed_run] ',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention), '; ');
  END IF;

  -- backup_stale (critical) — events.* GCS backup has not logged a success in >2 days (16_automation_health.sql).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'backup_stale',
      'Backup check: events.* GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.backup_health`);
  END IF;

  -- ops_backup_stale (critical, 2026-06-28 #2) — the ops.* (audit/control-plane) GCS backup has gone
  -- silent (>2 days). ops.* is IRREPLACEABLE append-only history with no upstream, so a stalled ops
  -- backup is as serious as a stalled events backup. Self-bootstrapping (state.ops_backup_health.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ops_backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'ops_backup_stale',
      'Backup check: ops.* (audit/control-plane) GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.ops_backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[ops_backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.ops_backup_health`);
  END IF;

  -- automation_heartbeat (critical) — an out-of-band Apps Script went silent (16_automation_health.sql).
  -- Delivered via THIS query's DTS failure-email, NOT via the (possibly-dead) alert emailer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'automation_heartbeat',
      CONCAT('Heartbeat check: out-of-band automation went silent: ',
             (SELECT STRING_AGG(source, ', ' ORDER BY source)
              FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(source, age_hours, max_age_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale));
    SET raise_msg = raise_msg || CONCAT('[automation_heartbeat] ',
      (SELECT STRING_AGG(source, ', ' ORDER BY source)
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale), '; ');
  END IF;

  -- instruction_drift (WARNING, non-raising). The schedule/instruction live only in the web UI;
  -- state.instruction_drift (bigquery/15_routine_catalog.sql) diffs each routine's LIVE logged trigger
  -- against the canonical catalog. A drift is a config bug to fix, not a halt — so it records but does
  -- NOT contribute to the RAISE.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'instruction_drift',
      CONCAT('Trigger drift: routine(s) whose live web-UI trigger differs from the canonical catalog: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, drifted, unknown_routine, live_instruction, canonical_instruction)))
       FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine));
  END IF;

  -- ====================================================================================
  -- 2026-06-24 stack-review additions (all WARNING, record-only — like instruction_drift —
  -- so they NEVER flip all_green and NEVER add to the DTS RAISE; delivered by the alert
  -- emailer / out-of-band relay, which both forward 'warning' rows). They reference views in
  -- bigquery/18_stack_review_fixes.sql — APPLY 18 BEFORE re-pasting this query. All read only
  -- ops.run_log + state views (no extra IAM); the JOBS-based append-only guard lives in the
  -- separate integrity_check.sql (it needs roles/bigquery.resourceViewer). RUNBOOK §25.
  -- ====================================================================================

  -- trigger_missing (D2) — a calendar-predictable routine the cadence ALARM deliberately excludes
  -- (weekly/monthly/quarterly/annual) has logged NO completed run across its cadence window: a DELETED
  -- (vs edited) web-UI trigger, which instruction_drift cannot see (it needs a run to log). Self-
  -- bootstrapping: only flags routines that have completed before (state.trigger_attestation.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_since_completed (which changes
    -- daily while a routine stays overdue) defeated sp_raise_alert_once's exact-match dedup, creating
    -- a fresh open alert row every day the condition persisted. Per-routine day counts are still fully
    -- visible in the payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'trigger_missing',
      CONCAT('Trigger attestation: routine(s) overdue beyond their cadence window (deleted/disabled web-UI trigger?): ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue),
             '. See payload for per-routine day counts.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, days_since_completed, max_gap_days, last_completed)))
       FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue));
  END IF;

  -- period_missed (warning, 2026-07-03 self-improvement audit WO-1/B-6-obs) — a weekly/monthly/quarterly/
  -- annual routine has not logged 'completed' anywhere in the CURRENT period (ISO week / month / quarter /
  -- year) and Denver wall-clock is past that period's grace deadline (bigquery/24_cadence_period_watch.sql
  -- — placed strictly after the documented Sun-or-Mon weekly tolerance / the 3rd-or-5th trading day for
  -- longer periods). Closes the gap where trigger_missing's coarse 14/70/200/400-day window could leave a
  -- single missed weekly routine unflagged for up to ~2 weeks. Self-bootstrapping (state.cadence_period_
  -- watch.monitored) and WARNING-only (a missed weekly is not a same-night trading halt) — promote to a
  -- RAISE-contributing critical only after a clean period confirms no false fire.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'period_missed',
      CONCAT('Cadence period check: routine(s) have not completed in the current period past their grace deadline: ',
             (SELECT STRING_AGG(CONCAT(routine, ' (', monitor_class, ', period ', CAST(period_start AS STRING), ')'), ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, monitor_class, period_start, grace_deadline)))
       FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed));
  END IF;

  -- routine_stalled (marginal) — a routine logged 'started' but never a terminal status past its per-class
  -- threshold (2026-06-28 #11: now ALL run-logged routines, not just D1/D2/D3): a session that died after
  -- sp_routine_start but before sp_routine_end (the run-log-blind slice).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.stalled_runs`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'routine_stalled',
      CONCAT('Stalled run(s): a routine started but never logged a terminal status: ',
             (SELECT STRING_AGG(CONCAT(routine, '/', CAST(run_date AS STRING)), ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.stalled_runs`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, hours_since_started)))
       FROM `stock-trading-498512.state.stalled_runs`));
  END IF;

  -- position_drift (B4) — the two open-position representations (state.current_positions vs
  -- analytics.position_lifecycle) disagree on open shares beyond tolerance for some (strategy,ticker).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'position_drift',
      CONCAT('Position reconciliation: current_positions vs position_lifecycle open-share drift: ',
             (SELECT STRING_AGG(CONCAT(strategy, ':', ticker), ', ' ORDER BY strategy, ticker)
              FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy, ticker, current_positions_shares, lifecycle_open_shares, share_diff)))
       FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted));
  END IF;

  -- calendar_runway_low (FMP auto-extend liveness) — the trading-calendar horizon has fallen below the
  -- W5 FMP auto-extend trigger and stayed there, an EARLY signal the auto-extend (likely the FMP grant)
  -- is failing, well before the calendar exhausts and the freshness COALESCE→FALSE backstop trips.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.market_calendar_horizon` WHERE runway_low) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_of_runway/calendar_through (both
    -- change daily while the condition persists) defeated sp_raise_alert_once's exact-match dedup,
    -- creating a fresh open alert row every day the runway stayed low. Full detail is still in the
    -- payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'calendar_runway_low',
      'Market-calendar runway low — W5 FMP auto-extend may be failing. See payload for runway/through-date detail.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.market_calendar_horizon` t));
  END IF;

  -- ====================================================================================
  -- 2026-06-28 stack-review #2 additions (all WARNING, record-only — never flip all_green / RAISE).
  -- Reference views in bigquery/17_restore_drill.sql (state.restore_health) and
  -- bigquery/19_stack_review_fixes_2.sql (state.ddl_drift) — APPLY 17 + 19 BEFORE re-pasting this query.
  -- ====================================================================================

  -- restore_stale (warning, #4) — the monthly restore drill has not completed in >40 days OR its last run
  -- did not pass. A drill that writes nothing on success is otherwise invisible (state.restore_health off
  -- ops.drill_log). A silently-paused DR drill means "DR verified monthly" is a belief, not a fact. (A dead
  -- drill SCHEDULER is additionally caught by the Cloud Monitoring absence policy in monitoring.tf.)
  -- MONITOR-PROMOTION HISTORY (ITEM 24, 2026-07-11): logged UNCONDITIONALLY (pass or fail), regardless of
  -- whether the WARNING below fires -- state.ddl_drift_promotion_readiness / state.restore_stale_
  -- promotion_readiness (bigquery/45_monitor_promotion.sql) need this history to evaluate "N consecutive
  -- clean runs", which the plain live views above cannot provide on their own.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, not plain INSERT -- a plain INSERT
  -- let a same-day re-run of this query (off-schedule/manual/duplicate, the exact class the 2026-06-25
  -- cadence deadline-guard fix already had to account for) write a second row for the same (check_id,
  -- check_date), which the NOT-ENFORCED primary key does not prevent -- breaking the "14 consecutive
  -- DISTINCT logged days" promotion bar this history table exists to support (bigquery/45's readiness
  -- views also defend against any pre-existing duplicate independently).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'restore_stale' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT COALESCE(stale, TRUE) AS clean
    FROM `stock-trading-498512.state.restore_health`
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.restore_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'restore_stale',
      (SELECT CONCAT('Restore-drill health: last drill ', CAST(last_drill_date AS STRING),
                     ' (passed=', CAST(last_drill_passed AS STRING), ') — stale or failing')
       FROM `stock-trading-498512.state.restore_health`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.restore_health` t));
  END IF;

  -- ddl_drift (warning, #7) — a live events.* audit table's STRUCTURE (NOT NULL / type / partition /
  -- cluster) diverged from the canonical bigquery/01_schema.sql spec (a silent out-of-band ALTER the
  -- idempotent CREATE-IF-NOT-EXISTS spec will not re-assert; invisible to the DML-only append_only_integrity
  -- and to dbt not_null DATA tests). Staged-rollout record-only until a clean baseline is confirmed.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, same rationale as the restore_stale
  -- write above.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'ddl_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ddl_drift',
      CONCAT('DDL drift: events.* base-table structure differs from bigquery/01_schema.sql: ',
             (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
                     ORDER BY table_name, column_name)
              FROM `stock-trading-498512.state.ddl_drift`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(table_name, column_name, drift_reasons, expected_type, live_type)))
       FROM `stock-trading-498512.state.ddl_drift`));
  END IF;

  -- script_version_drift (warning, item 23 -- Apps Script drift detection). A deployed .gs (alert_emailer
  -- / weekly_report) is running a version other than the repo's expected one, or has stopped reporting a
  -- version at all after previously doing so -- almost always a Claude-side .gs fix that was never re-
  -- pasted by the owner (script.google.com is unreachable from Claude). Self-bootstrapping
  -- (state.script_version_drift.monitored) so this never fires before the owner has pasted the version-
  -- emitting .gs diff at least once. Delivered via THIS query's DTS failure-email path is deliberately
  -- NOT used for delivery (kept WARNING, record-only, like instruction_drift/ddl_drift) since alert_emailer
  -- itself is one of the two monitored scripts -- routing this alarm through it would be circular; the
  -- warning still reaches the owner via the alert emailer's own periodic poll of ops.alerts, which is a
  -- SEPARATE mechanism from "this script being the delivery channel for its own drift" (see 43_script_
  -- version_registry.sql header). Staged-rollout WARNING until a clean baseline confirms no false fire,
  -- matching the ddl_drift / restore_stale precedent above.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.script_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'script_version_drift',
      CONCAT('Script version drift: deployed Apps Script(s) running an unexpected/missing version: ',
             (SELECT STRING_AGG(CONCAT(script_name, ' (expected ', expected_version, ', reported ',
                     COALESCE(last_reported_version, 'NONE'), ')'), ', ' ORDER BY script_name)
              FROM `stock-trading-498512.state.script_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(script_name, expected_version, last_reported_version, last_beat_ts)))
       FROM `stock-trading-498512.state.script_version_drift` WHERE drift));
  END IF;

  -- constant_tuning_loop_heartbeat_missing (warning, item 11 -- self-improvement audit 2026-07-11).
  -- meta_monitoring_heartbeat (ops/autonomy_levels.yaml) documents every active_auto/shadow loop should
  -- write an "evaluated this cycle" heartbeat with a scheduled-query dead-man's switch alerting on
  -- absence -- LIVE today for strategy_arsenal (SL1/SL3/SL4) but the four constant-tuning loops
  -- (process_reliability, strategy_playbook, execution_quality_tuning, calibration_parameter_carveout)
  -- had NEITHER a heartbeat write NOR a routine that ever evaluated them at all until Claude_Task_Plan.md's
  -- W5 section was extended (item 11) to write ops.heartbeat(source='loop:<id>') every W5 firing,
  -- regardless of whether that loop's own readiness view fired. cross_model_referee_independence (added
  -- 2026-07-15, promoted dormant->shadow) joins the same list, same W5 bullet pattern. Self-bootstrapping:
  -- a loop with ZERO ops.heartbeat rows ever (never yet evaluated even once post-deployment) does not
  -- alarm -- only a loop that HAS reported at least once and then goes quiet trips this, exactly the
  -- state.script_version_drift / instruction_drift self-bootstrapping convention above. W5 runs weekly;
  -- the ~10-day window tolerates one missed cycle before alarming. Staged-rollout WARNING (record-only),
  -- matching every other self-bootstrapping monitor in this file.
  IF EXISTS (
    SELECT 1 FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                           'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                           'loop:cross_model_referee_independence']) AS loop_source
    WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
      AND NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
        WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY))
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
      CONCAT('Constant-tuning loop(s) previously reporting a weekly W5 heartbeat have gone quiet >10 days: ',
             (SELECT STRING_AGG(loop_source, ', ')
              FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                            'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                            'loop:cross_model_referee_independence']) AS loop_source
              WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
                AND NOT EXISTS (
                  SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
                  WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)))),
      TO_JSON_STRING(STRUCT(CURRENT_TIMESTAMP() AS checked_at)));
  END IF;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;

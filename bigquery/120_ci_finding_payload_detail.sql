-- ci_finding alert payload: include finding detail (2026-07-30).
-- Project: stock-trading-498512. Apply AFTER 111_cadence_check_version_drift_autoage.sql.
-- SUPERSEDED LIVE by bigquery/128_b3_drift_promotion.sql (2026-08-03) — current single source of truth
-- for THIS PROCEDURE. When written, this file superseded
-- bigquery/111_cadence_check_version_drift_autoage.sql; 128 has since superseded it in turn (D3
-- MONITOR-PROMOTION SELF-FLIP: heartbeat 'v10' -> 'v11' and b3_trading_enabled_drift promoted
-- WARNING->CRITICAL + joined to raise_msg). Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. Do not re-apply this CREATE statement live in isolation — doing so would silently
-- demote b3_trading_enabled_drift back to a non-blocking warning.
--
-- ============================ WHAT CHANGED ============================
-- Byte-for-byte identical to the CREATE statement in bigquery/111_cadence_check_version_drift_autoage.sql
-- EXCEPT:
--   1. the heartbeat version marker 'v9' -> 'v10' (bigquery/63's registry entry is updated to match);
--   2. the `ci_finding` alert payload STRUCT now includes `detail` before `run_url`, so CI finding
--      detail text reaches the operator alert email.
-- No check logic, thresholds, severity, or alert routing is otherwise altered.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:cadence_check', 'v10', 'cadence_check.sql ran');

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
  -- instruction_drift warning keeping the digest red). Targets only the self-CLEARING classes, warning
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
    -- immediate_action_flagged + process_scorecard_signal added 2026-07-16 (consumption-closure): point-in-time W3/M3/W5 signals, consumed autonomously by W4/M4 within days; 7-day age-out stops forever-open dashboard rows. A persisting condition is simply re-raised.
    -- scheduled_query_version_drift added 2026-07-27 (bigquery/111): the SAME self-healing shape as
    -- scheduled_query_stale directly above. A version marker only reports what a scheduled query said
    -- the LAST time it ran, so a mid-day wrapper bump leaves the prior version as the freshest beat
    -- until that query's own next run -- and this proc evaluates ~05:15 UTC, ahead of most of them
    -- (daily_staging_cap_check ~05:25). The gap is therefore a routine bootstrapping-window race that
    -- heals itself within one cycle, exactly like a resumed beat, but it was the one such class absent
    -- from this list -- so every wrapper version bump left a permanently-open row needing a manual
    -- UPDATE (embed_pending 2026-07-17/18; daily_staging_cap_check v3->v4 2026-07-27, alert 0c2b631a).
    -- A STILL-drifted query is simply re-raised by the scheduled_query_version_drift check below, so a
    -- genuinely unapplied wrapper cannot be aged away silently.
    -- scheduled_query_stale + ci_findings_bridge_stale + control_plane_insert added 2026-07-17 (MON H2/H4/H5): self-healing warnings (a resumed beat / a re-armed bridge / an aged-out control INSERT event stop being true) whose stable-message rows would otherwise linger open after the condition heals; a STILL-true condition is simply re-raised below (bridge_stale/scheduled_query_stale in THIS proc, control_plane_insert by safety_critical_dml_watch).
    -- 'stranded_session' REMOVED 2026-07-29, because the Operating_Protocols.md §17 never-pushed-branch
    -- detector that raised it was RETIRED 2026-07-29 (commit a9a029b) and nothing in the tree can raise
    -- the category any more -- verified 2026-07-30: every remaining mention is either an auto-age
    -- allowlist (here and bigquery/75's superseded copy) or RUNBOOK prose describing one. A dead entry in
    -- a fail-closed allowlist reads as coverage that does not exist; dropped with §17.
    -- CORRECTION 2026-07-30: this comment previously justified the removal by asserting the category "was
    -- never once raised anywhere in this repo's entire git history" and "existed only in this allowlist".
    -- Both are FALSE, and the live table is the authority: ops.alerts holds exactly one stranded_session
    -- row -- raised 2026-06-24 22:41:49 by D2 for session sess-d1-20260624 (RUNBOOK §20 never-pushed
    -- strand) -- and THIS auto-age rule is what resolved it, on 2026-07-02 05:15:10, with
    -- resolved_note 'auto-aged (>7d self-healing warning; cadence_check.sql #14)'. So the entry was live
    -- coverage that demonstrably fired once; it is dead only PROSPECTIVELY, now that its raiser is gone.
    -- The removal stands (nothing can raise it, and the one historical row is long resolved, so no open
    -- alert is stranded by dropping it) -- but do not re-derive "never raised" from the old wording.
    -- CAUTION for any future allowlist edit: before dropping a category from this FAIL-CLOSED list,
    -- query ops.alerts for OPEN rows in it. An open row in a removed category never auto-ages again.
    AND category IN ('instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing', 'immediate_action_flagged', 'process_scorecard_signal', 'scheduled_query_stale', 'ci_findings_bridge_stale', 'control_plane_insert', 'scheduled_query_version_drift')
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
  -- 2026-06-28 stack-review #2 additions (originally all WARNING, record-only. restore_stale was PROMOTED
  -- to CRITICAL + RAISE-contributing on 2026-07-11, and ddl_drift on 2026-07-26, each by D3's
  -- monitor-promotion self-flip once its readiness view fired — ITEM 24).
  -- Reference views in bigquery/17_restore_drill.sql (state.restore_health) and
  -- bigquery/19_stack_review_fixes_2.sql (state.ddl_drift) — APPLY 17 + 19 BEFORE re-pasting this query.
  -- ====================================================================================

  -- restore_stale (CRITICAL as of 2026-07-11, promoted from warning per ITEM 24 — see the self-flip note
  -- at the IF block below; #4) — the monthly restore drill has not completed in >40 days OR its last run
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

  -- PROMOTED WARNING->CRITICAL (2026-07-11, D3 monitor-promotion self-flip per ITEM 24): once
  -- state.restore_stale_promotion_readiness.ready=TRUE (monitored=TRUE AND last drill passed — the
  -- RUNBOOK's own stated bar), D3 self-applies this promotion. Now a RAISE-contributing critical,
  -- wired into raise_msg like backup_stale/automation_heartbeat above (a silently-stale DR drill is a
  -- capital-safety fact, not a buried warning). ops.monitor_promotion_log guards idempotency.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.restore_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'restore_stale',
      (SELECT CONCAT('Restore-drill health: last drill ', CAST(last_drill_date AS STRING),
                     ' (passed=', CAST(last_drill_passed AS STRING), ') — stale or failing')
       FROM `stock-trading-498512.state.restore_health`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.restore_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[restore_stale] last_drill=',
      CAST(last_drill_date AS STRING), ' passed=', CAST(last_drill_passed AS STRING), '; ')
      FROM `stock-trading-498512.state.restore_health`);
  END IF;

  -- ddl_drift (CRITICAL as of 2026-07-26, promoted from warning per ITEM 24 — D3 monitor-promotion
  -- self-flip once state.ddl_drift_promotion_readiness.ready=TRUE (14 consecutive clean logged days);
  -- #7) — a live events.* audit table's STRUCTURE (NOT NULL / type / partition /
  -- cluster) diverged from the canonical bigquery/01_schema.sql spec (a silent out-of-band ALTER the
  -- idempotent CREATE-IF-NOT-EXISTS spec will not re-assert; invisible to the DML-only append_only_integrity
  -- and to dbt not_null DATA tests). Now a RAISE-contributing critical, wired into raise_msg like
  -- restore_stale above. ops.monitor_promotion_log guards idempotency.
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
      'critical', 'scheduled.cadence', 'ddl_drift',
      CONCAT('DDL drift: events.* base-table structure differs from bigquery/01_schema.sql: ',
             (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
                     ORDER BY table_name, column_name)
              FROM `stock-trading-498512.state.ddl_drift`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(table_name, column_name, drift_reasons, expected_type, live_type)))
       FROM `stock-trading-498512.state.ddl_drift`));
    SET raise_msg = raise_msg || CONCAT('[ddl_drift] ',
      (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
              ORDER BY table_name, column_name)
       FROM `stock-trading-498512.state.ddl_drift`), '; ');
  END IF;

  -- b3_trading_enabled_drift (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- dbt-b3-coverage-advisory-only). state.b3_trading_enabled_check (bigquery/64_b3_live_invariants.sql)
  -- recomputes state.trading_enabled's formula independently and flags LIVE drift -- the exact
  -- 2026-07-11 incident class (an in-place scheduled-query re-apply silently clobbered a gate
  -- AND-term for days with zero CI/live signal, bigquery/47_trading_enabled_resync.sql), now checked
  -- daily instead of only in an advisory-only dbt test.
  -- MONITOR-PROMOTION HISTORY for b3_trading_enabled_drift (MON M2, 2026-07-17). Mirrors the
  -- ddl_drift/restore_stale MERGE-upsert above and the append_only_integrity one in integrity_check.sql
  -- (ITEM 24/31): logged UNCONDITIONALLY every run (clean = zero drift rows in
  -- state.b3_trading_enabled_check) so state.b3_promotion_readiness (bigquery/79_b3_promotion.sql) can
  -- evaluate the 14-consecutive-clean-DISTINCT-day bar the plain live view cannot provide on its own —
  -- bigquery/64's header promised this promotion path but nothing wrote the history until now. MERGE
  -- (not INSERT) so a same-day off-schedule/manual re-run never double-logs one day (same rationale as
  -- the ddl_drift/restore_stale writes). Does NOT change this check's alerting: still the WARNING-only
  -- IF block below. Because b3_trading_enabled_drift lives in THIS file (which HAS the raise_msg
  -- accumulator, unlike append_only_integrity), D3's MONITOR-PROMOTION SELF-FLIP promotes it by flipping
  -- the 'warning' literal below to 'critical' AND appending to raise_msg — see bigquery/79's header.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'b3_trading_enabled_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'b3_trading_enabled_drift',
      (SELECT CONCAT('state.trading_enabled formula drift: live=', CAST(live_value AS STRING),
                     ' but independently-recomputed expected=', CAST(expected_value AS STRING),
                     ' -- a gate AND-term may have been silently clobbered (see bigquery/47_trading_enabled_resync.sql)')
       FROM `stock-trading-498512.state.b3_trading_enabled_check`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.b3_trading_enabled_check` t));
  END IF;

  -- backup_per_table_row_drop (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- backup-per-table-rows-write-only). state.backup_per_table_health (bigquery/65_backup_per_table_
  -- health.sql) was write-only (RUNBOOK B2's per-table row-count evidence, INSERTed but never read).
  -- Every backed-up table is append-only by design, so a day-over-day row-count DROP can only mean an
  -- out-of-band deletion or a backup-query regression -- never legitimate activity.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'backup_per_table_row_drop',
      CONCAT('Backup per-table row-count DROP detected (append-only table(s) should never shrink): ',
             (SELECT STRING_AGG(CONCAT(dataset, '.', table_name, ' ', CAST(prior_rows AS STRING), '->', CAST(latest_rows AS STRING)), ', ' ORDER BY dataset, table_name)
              FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(dataset, table_name, prior_run_date, prior_rows, latest_run_date, latest_rows)))
       FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped));
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

  -- scheduled_query_version_drift (warning, consumption-closure audit 2026-07-16 -- bigquery/63's
  -- drift view previously had NO automated reader anywhere; verbatim mirror of the script_version_drift
  -- block directly above, same self-bootstrapping convention: monitored=FALSE rows can never fire.
  -- Self-reference caveat: this block cannot report THIS query's own regression -- a regressed body
  -- lacks the block -- so Claude_Task_Plan.md's D3 UNWIRED-MONITOR BRIDGE bullet also raises this
  -- category for cadence_check itself (self-retiring once this body's own heartbeat matches v5 —
  -- comment updated 2026-07-16 by the ARCH-1 wrapper migration's v4->v5 bump; no logic change).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_version_drift',
      CONCAT('Scheduled-query body drift (live console body != repo SQ_VERSION): ',
        (SELECT STRING_AGG(CONCAT(sq_name,' (expected ',expected_version,', reported ',COALESCE(last_reported_version,'NONE'),')'), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, expected_version, last_reported_version, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift));
  END IF;

  -- scheduled_query_stale (warning, MON H5, 2026-07-17). state.scheduled_query_version_drift detects only
  -- a VERSION mismatch among sources that have EVER beaten; a DTS config that silently STOPS forever (7 of
  -- the 12 can), or one registered but never once beaten, is invisible to it — nothing watched beat AGE.
  -- bigquery/63 now carries expected_interval_hours per query + a grace factor and exposes two new columns:
  --   * stale_beat        — monitored (has beaten >=1x) AND last_beat_ts older than interval x grace.
  --   * never_beat_overdue — NOT monitored AND the registry row was declared > 7 days ago (self-
  --                          bootstrapping grace: a freshly-registered query stays quiet for a week).
  -- Record-only, no RAISE (promotion-eligible via the bigquery/45 ladder later, like ddl_drift): a stalled
  -- scheduled query is also caught by its own DTS email-on-failure and the Cloud Monitoring absence policy;
  -- this is the in-band, digest-visible backstop. DEDUP-CRITICAL: the message lists ONLY sq_names +
  -- which failure mode (stable while the stalled set is stable, per the order_guard_omitted convention);
  -- daily-changing ages live ONLY in the JSON payload.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_stale',
      CONCAT('Scheduled-query beat-age dead-man — DTS config(s) overdue past their expected interval (x grace) or never-beat window: ',
        (SELECT STRING_AGG(CONCAT(sq_name, IF(never_beat_overdue, ' (NEVER beat)', ' (stale beat)')), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, monitored, stale_beat, never_beat_overdue, expected_interval_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts) ORDER BY sq_name))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue));
  END IF;

  -- probe_funding_stalled (warning, consumption-closure audit 2026-07-16) -- state.strategy_probe_
  -- funding_stalled (bigquery/62_probe_stake_funding.sql) flags a PROBE-phase newcomer frozen below
  -- the $2,000 floor for >=90 days; previously had no automated reader at all.
  -- DEDUP-CRITICAL: message lists ONLY strategy codes (stable while the stalled set is stable); the
  -- daily-changing numbers (funding_gap_dollars, days_since_probe_entry) live ONLY in the JSON
  -- payload, because ops.sp_raise_alert_once dedups on exact unresolved (category, message) -- a
  -- day-counter in the message would insert a new unresolved warning row + email EVERY night per
  -- stalled newcomer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.strategy_probe_funding_stalled`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','probe_funding_stalled',
      CONCAT('PROBE newcomer(s) frozen below the $2,000 floor >=90 days: ',
        (SELECT STRING_AGG(strategy_code, ', ' ORDER BY strategy_code)
         FROM `stock-trading-498512.state.strategy_probe_funding_stalled`),
        ' — a deposit (sanctioned residual touch) or FIFO redistribution priority check is needed; per-strategy gap/days in payload'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy_code, funding_gap_dollars, days_since_probe_entry)))
       FROM `stock-trading-498512.state.strategy_probe_funding_stalled`));
  END IF;

  -- cash_flows_backfill_broken (warning, consumption-closure audit 2026-07-16) -- state.cash_flows_
  -- backfill_check (bigquery/68_cash_flows_backfill_check_dated.sql, date-scoped redefinition of the
  -- bigquery/22 apply-time gate) flags a backdated/duplicate/typo events.cash_flows row dated
  -- <= 2026-07-03 that shifts the NAV/sizing baseline every downstream consumer relies on. A future
  -- legitimate deposit cannot flip this (view is date-scoped), so it is now safe to poll nightly.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cash_flows_backfill_check` WHERE NOT reconciled) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','cash_flows_backfill_broken',
      'events.cash_flows rows dated <= 2026-07-03 no longer sum to the 9446.86 seed total — a backdated/duplicate/typo flow has shifted the NAV/sizing baseline; investigate before trusting analytics.strategy_nav (bigquery/68)',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.cash_flows_backfill_check` t));
  END IF;

  -- ci_finding (warning, self-improvement audit 2026-07-16, CC-1 -- CI-findings consumption-closure
  -- bridge, bigquery/67_ci_findings_bridge.sql). Four CI guards (live-sql-parity, keyless-sa-audit,
  -- wif-binding-audit, guard-config-audit) each open/refresh a deduped GitHub issue on a finding, but
  -- nothing previously read those issues -- this closes the loop by raising/auto-resolving off
  -- state.ci_findings_open, so a finding reaches the monitored alert-emailer channel even on a day
  -- nobody manually reads GitHub Issues. AUTO-RESOLVE FIRST (matching the RECORD-THEN-RAISE convention
  -- above): once state.ci_findings_open is empty, clear any still-open ci_finding alert -- this also
  -- covers the case where the underlying workflow's next clean run wrote its unconditional resolved
  -- row (see live-sql-parity.yml's "Close finding issue if resolved" step) after a manually-closed GH
  -- issue would otherwise have stranded it. Record-only (does NOT join raise_msg), matching
  -- script_version_drift / ddl_drift / restore_stale above -- an open CI finding is a config/drift bug
  -- to fix, not a trading halt.
  UPDATE `stock-trading-498512.ops.alerts`
     SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
         resolved_note = CONCAT('auto-resolved: state.ci_findings_open empty. ', COALESCE(resolved_note, ''))
   WHERE NOT resolved AND category = 'ci_finding'
     AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_finding',
      CONCAT('Open CI guard finding(s): ',
             (SELECT STRING_AGG(CONCAT(workflow, '/', finding_key), ', ' ORDER BY workflow)
              FROM `stock-trading-498512.state.ci_findings_open`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(workflow, finding_key, CAST(finding_ts AS STRING) AS finding_ts, detail, run_url)))
       FROM `stock-trading-498512.state.ci_findings_open`));
  END IF;

  -- ci_findings_bridge_stale (warning, MON H2, 2026-07-17). The ci_finding block above only ever fires
  -- when the bridge DELIVERS a finding — but ops.ci_findings is the DECLARED single delivery path for
  -- live-sql-parity drift (bigquery/67 / Claude_Task_Plan.md D3), and a DEAD bridge is indistinguishable
  -- from a clean one: zero rows reads identically to "no drift" while objects could sit drifted invisibly.
  -- As of 2026-07-17 the bridge has delivered ZERO live-sql-parity rows EVER (the workflow's INSERT was
  -- swallowed by `|| echo ::warning::` inside an otherwise-green run — fixed in live-sql-parity.yml this
  -- same pass). This dead-man fires when the newest live-sql-parity finding_ts is older than ~40h (the
  -- daily workflow cadence + one missed run of grace) OR — critically — when NONE has EVER been delivered
  -- (MAX over empty = NULL; COALESCE to the epoch makes the never-delivered state fire, which is the
  -- current state and exactly the never-armed failure the swallowed INSERT produced). Record-only, does
  -- NOT join raise_msg (a stalled plumbing bridge is a config fix, not a trading halt), matching
  -- ci_finding/ddl_drift. DEDUP-CRITICAL: the message is fully static (no timestamps/counts); detail is in
  -- the payload — so a persisting dead bridge dedups to a single open warning, not a fresh row every run.
  IF (
    SELECT COALESCE(MAX(finding_ts), TIMESTAMP '1970-01-01 00:00:00 UTC')
             < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 40 HOUR)
    FROM `stock-trading-498512.ops.ci_findings`
    WHERE workflow = 'live-sql-parity'
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_findings_bridge_stale',
      'ops.ci_findings has NO live-sql-parity row newer than ~40h (or none has EVER been delivered) — the DECLARED single delivery path for live-sql-parity drift (bigquery/67) may be dead. A dead bridge reads identically to "no drift", so drifted objects could sit unsurfaced. Verify the daily live-sql-parity.yml run: the WIF vars (GCP_WIF_PROVIDER/SERVICE_ACCOUNT) must be set AND the gh-ci-runner@ dataEditor grant on ops.ci_findings must be live, and the INSERT step must now fail-loud on error (fixed 2026-07-17). See payload for row count / last finding_ts.',
      (SELECT TO_JSON_STRING(STRUCT(
         (SELECT COUNT(*) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS live_sql_parity_rows,
         (SELECT CAST(MAX(finding_ts) AS STRING) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS last_finding_ts,
         CAST(CURRENT_TIMESTAMP() AS STRING) AS checked_at))));
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
  -- matching every other self-bootstrapping monitor in this file. park_allocator (added 2026-07-26, PARK
  -- v3 immediate-binding redesign, shadow->active_auto) joins this list too, per
  -- scripts/check_autonomy_consistency.py's coverage requirement -- but its REAL primary coverage is the
  -- dedicated, tighter, trading-day-aware block immediately below (this flat 10-calendar-day window is a
  -- required belt-and-suspenders membership for a loop whose actual cadence is daily, not weekly).
  IF EXISTS (
    SELECT 1 FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                           'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                           'loop:cross_model_referee_independence','loop:research_quality_feedback',
                           'loop:park_allocator']) AS loop_source
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
                            'loop:cross_model_referee_independence','loop:research_quality_feedback',
                            'loop:park_allocator']) AS loop_source
              WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
                AND NOT EXISTS (
                  SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
                  WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)))),
      TO_JSON_STRING(STRUCT(CURRENT_TIMESTAMP() AS checked_at)));
  END IF;

  -- park_allocator daily-heartbeat staleness (warning, PARK v3 immediate-binding redesign, owner
  -- directive 2026-07-26). loop:park_allocator (ops/autonomy_levels.yaml) converted shadow->active_auto
  -- in this same change and is written DAILY by D1's PARK ALLOCATION CALL (every trading day) -- NOT
  -- weekly like the constant-tuning loops in the generic block above. Folding it only into that block's
  -- flat 10-CALENDAR-day window would be semantically wrong two ways: (1) 10 calendar days is far looser
  -- than appropriate for a nominally-daily loop; (2) because D1's daily beat and W5's own weekly
  -- belt-and-suspenders beat write the IDENTICAL heartbeat source, a real multi-day D1 outage could be
  -- invisibly papered over by W5's once-a-week write resetting the shared clock before the generic
  -- 10-day window ever trips -- defeating the point of watching a daily loop at all. This dedicated block
  -- uses a TRADING-day count via state.market_calendar (same idiom as bigquery/92_park_allocator.sql's
  -- 2026-07-19 park_switch_budget cooldown fix and bigquery/76_owner_confirmation_liveness.sql's
  -- trading_days_since_last_fill -- NOT a naive calendar-day DATE_DIFF, the exact bug class that fix
  -- removed) and a tighter >=3-trading-day threshold. Self-bootstrapping: park_last_beat IS NULL (no
  -- heartbeat row ever) skips the whole block -- no alarm before the loop's first-ever beat; park_allocator
  -- has beaten daily since 2026-07-19, so this arms immediately on apply. Deliberately expressed via a
  -- scalar `source = 'loop:park_allocator'` equality, NEVER an UNNEST(['loop:...']) literal -- adding a
  -- THIRD, single-member UNNEST literal here would shrink
  -- scripts/check_autonomy_consistency.py's cadence_detection_loops() intersection-of-UNNEST-lists to
  -- {park_allocator} alone and false-flag every other constant-tuning loop above as unmonitored. Reuses
  -- the same category ('constant_tuning_loop_heartbeat_missing') as the generic block so it rides the
  -- same emailer/auto-resolve wiring; sp_raise_alert_once dedups on (category, message), so the message
  -- text below is held stable (keyed on the frozen last-beat timestamp, not on the day this check runs)
  -- while the staleness persists, and is distinct from the generic block's message (which never names
  -- park_allocator, since park_allocator's own beats keep it out of that block's stale-source list under
  -- normal operation).
  BEGIN
    DECLARE park_last_beat TIMESTAMP;
    DECLARE park_trading_days_since_beat INT64;
    SET park_last_beat = (
      SELECT MAX(beat_ts) FROM `stock-trading-498512.ops.heartbeat` WHERE source = 'loop:park_allocator');
    IF park_last_beat IS NOT NULL THEN
      SET park_trading_days_since_beat = (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(park_last_beat, 'America/Denver')
          AND mc.cal_date <= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`));
      IF park_trading_days_since_beat >= 3 THEN
        CALL `stock-trading-498512.ops.sp_raise_alert_once`(
          'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
          CONCAT('loop:park_allocator (active_auto, daily D1 heartbeat) has gone quiet >=3 trading days ',
                 '-- last beat ', CAST(park_last_beat AS STRING), '. This is the DEDICATED trading-day-aware ',
                 'check (not the flat 10-calendar-day window above) because D1 writes this heartbeat every ',
                 'trading day, not weekly.'),
          TO_JSON_STRING(STRUCT(park_last_beat AS last_beat,
                                 park_trading_days_since_beat AS trading_days_since_beat,
                                 CURRENT_TIMESTAMP() AS checked_at)));
      END IF;
    END IF;
  END;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;

-- bigquery/75_scheduled_query_wrappers.sql
-- ARCH-1 (self-improvement audit, consolidated pass): freeze all 12 scheduled-query console bodies
-- as one-line `CALL ops.sp_sq_<name>()` wrappers over the stored procedures defined below. Kills the
-- recurring owner re-paste class (bigquery/scheduled_queries/README.md's bump-and-re-paste discipline)
-- for every FUTURE edit: change the check logic HERE (bump this procedure's sp_beat_heartbeat version
-- literal + the matching bigquery/63 state.expected_scheduled_query_versions row in the same commit),
-- apply the CREATE OR REPLACE PROCEDURE live via the BigQuery MCP, and the console body never needs a
-- re-paste again (it is a permanent one-line CALL, bigquery/scheduled_queries/<name>.sql).
--
-- PROVENANCE: each procedure body below is the VERBATIM executable content of the corresponding
-- bigquery/scheduled_queries/<name>.sql as it stood immediately before this migration (2026-07-16) —
-- no check logic altered, only (a) wrapped in `CREATE OR REPLACE PROCEDURE ... BEGIN ... END;` where
-- the file was bare top-level statements, and (b) the sp_beat_heartbeat version literal bumped one
-- step (this migration counts as one body edit, same convention as any other edit). The full
-- historical/explanatory header comment for each check (schedule rationale, IAM notes, posture
-- rationale, etc.) remains in the now-frozen bigquery/scheduled_queries/<name>.sql file — not
-- duplicated here to avoid two sources of truth for prose that never executes.
--
-- PRE-FLIGHT VERIFICATION STATUS (IMPORTANT — read before applying this file live): the two platform
-- questions this migration depends on — (a) can `EXPORT DATA` (via `EXECUTE IMMEDIATE FORMAT(...)`)
-- run inside a stored PROCEDURE body (backup_events_export / ops_export), and (b) can `CREATE TEMP
-- TABLE` run inside a stored PROCEDURE body (safety_critical_dml_watch) — were NOT exercised live in
-- the session that wrote this file: that session operated under a hard rule forbidding ALL BigQuery
-- MCP tool calls (see OWNER_ACTIONS.md / the routine's own operating constraints for this pass). Both
-- are believed to work (they are standard BigQuery *scripting*-language statements, and a PROCEDURE
-- body is itself defined as a script — dynamic SQL via EXECUTE IMMEDIATE and session-scoped CREATE TEMP
-- TABLE are not procedure-specific edge cases), but this is a documented BELIEF, not a live-confirmed
-- fact. (c) RAISE-inside-a-procedure propagating to and failing the calling DTS job IS already
-- live-proven precedent (ops.sp_restore_drill, bigquery/17_restore_drill.sql, under a bare-CALL
-- scheduled query — ops.drill_log 2026-07-01 06:01:21Z monthly run; also FIRE_DRILL_ORDER_GUARD
-- 2026-07-11 / FIRE_DRILL_ALERT_LATCH 2026-07-15 in ops.run_log) — no new test needed for (c).
--
-- REQUIRED BEFORE APPLYING THIS FILE LIVE (a future MCP-enabled session must do this FIRST):
--   1. Scratch-test (a): a throwaway procedure that runs `EXECUTE IMMEDIATE 'EXPORT DATA ...'` against
--      a scratch GCS prefix. If REJECTED: exclude ops.sp_sq_backup_events_export and
--      ops.sp_sq_ops_export from this file (leave backup_events_export.sql / ops_export.sql inline,
--      unfrozen — do not replace their console bodies with a CALL wrapper) and note it in
--      bigquery/scheduled_queries/README.md.
--   2. Scratch-test (b): a throwaway procedure that runs `CREATE TEMP TABLE ... AS SELECT ...`. If
--      REJECTED: either rewrite ops.sp_sq_safety_critical_dml_watch's one `CREATE TEMP TABLE hits`
--      statement as a temp-table-free CTE/subquery equivalent (same predicate, same output shape used
--      by the two SELECTs below it), or exclude it from this file the same way as (1).
--   3. Only after (1)/(2) pass (or the excluded files are pulled out and documented): apply this file's
--      CREATE OR REPLACE PROCEDURE statements live, THEN paste the new one-line console bodies
--      (OWNER_ACTIONS.md §B), per the SEQUENCING requirement (apply procedures before the owner pastes,
--      so a paste-before-apply just gets a CALL error + failure email — fail-visible either way, never
--      a silent regression).
--
-- All project refs: `stock-trading-498512`.

-- =====================================================================================================
-- ops.sp_sq_embed_pending   (was bigquery/scheduled_queries/embed_pending.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_embed_pending`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:embed_pending', 'v2', 'embed_pending.sql ran');
  CALL `stock-trading-498512.ops.sp_embed_pending`();
END;

-- =====================================================================================================
-- ops.sp_sq_daily_freshness_check   (was bigquery/scheduled_queries/daily_freshness_check.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v3 (bumped
-- from v2 by MON STALENESS PART-3, 2026-07-17 — source-echo suppression: RAISE predicate narrowed
-- from all_green to the data-staleness component conjunction only; see the inline note below).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_daily_freshness_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_freshness_check', 'v3', 'daily_freshness_check.sql ran');
  BEGIN
    -- STALENESS PART-3 (MON, 2026-07-17 source-echo suppression). This dead-man now RAISEs on the genuine
    -- DATA-STALENESS COMPONENTS only — marks_fresh AND engine_fresh AND embeddings_healthy AND NOT
    -- position_drift_detected — i.e. state.system_health.all_green MINUS its open_critical_alerts=0 term.
    -- WHY drop that term: it made this check an alert-on-alert ECHO. Any open critical (each of which
    -- already has its own delivery channel) flipped all_green FALSE and re-raised a content-free
    -- 'staleness' critical here; both gates then counted 'staleness' as blocking, so a staleness echo of a
    -- since-healed overnight transient kept trading disabled all day and D2a hit a FATAL gate whose clear
    -- condition (marks_fresh) needs the very marks D2a would ingest — the 2026-07-14/07-17 circular
    -- deadlock. bigquery/78 broke that circularity at the GATE layer (excluding 'staleness' from
    -- blocking_criticals); this stops the echo at its SOURCE so the redundant critical is not raised in
    -- the first place. d2_ran_last_trading_day / a backup-freshness term are deliberately NOT added: neither
    -- is an all_green term today (d2_ran_last_trading_day is FALSE at this 05:00 UTC run on a normal day —
    -- verified live 2026-07-17 with all_green=TRUE — so adding it would false-fire every morning; backup
    -- staleness has its own cadence_check backup_stale critical). Behaviourally INERT on apply day (the
    -- component conjunction reads TRUE right now, same as all_green).
    IF (SELECT NOT (marks_fresh AND engine_fresh AND embeddings_healthy AND NOT position_drift_detected)
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

-- =====================================================================================================
-- ops.sp_sq_cadence_check   (was bigquery/scheduled_queries/cadence_check.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v8 (bumped
-- from v7 by the PARK v3 immediate-binding redesign, 2026-07-26, owner directive: park_allocator
-- converted shadow->active_auto (ops/autonomy_levels.yaml) in the same change, so its daily
-- `loop:park_allocator` heartbeat now needs active_auto dead-man's-switch coverage per
-- scripts/check_autonomy_consistency.py's `_check_cadence_heartbeat_coverage` — added to BOTH
-- constant_tuning_loop_heartbeat_missing UNNEST literals below, PLUS a new dedicated
-- `park_allocator daily-heartbeat staleness` block with its own 3-trading-day window (see inline
-- comment there for why the generic list's flat 10-calendar-day window alone would be too loose/
-- maskable for a daily loop). v7 was bumped from v6 by D3's monitor-promotion self-flip, 2026-07-26:
-- ddl_drift promoted WARNING->CRITICAL + joined raise_msg per ITEM 24 once
-- state.ddl_drift_promotion_readiness fired. v6, MON 2026-07-17: added the ci_findings_bridge_stale
-- dead-man (H2), the scheduled_query_stale beat-age dead-man (H5), and the unconditional
-- b3_trading_enabled_drift monitor-health-history MERGE (M2)).
--
-- HISTORY (no longer the current-truth claim — see the live banner below): bigquery/128_b3_drift_
-- promotion.sql (2026-08-03) redefined THIS PROCEDURE ONLY in turn (every other sp_sq_* wrapper in
-- this file is still canonical here); 128 has since itself been superseded (see below), so it is no
-- longer the current single source of truth either. The chain is 75 -> 111 -> 120 -> 128 -> 142: 111
-- added the v9 auto-age fixes, 120 bumped the heartbeat marker to 'v10' and included `detail` in the
-- ci_finding alert payload, 128 (D3 MONITOR-PROMOTION SELF-FLIP) bumped it to 'v11' and promoted
-- b3_trading_enabled_drift WARNING->CRITICAL + raise_msg, and 142 (see below) bumps it to 'v12'.
-- Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation —
-- doing so silently reverts that auto-age fix and every future wrapper version bump again leaves a
-- permanently-open alert row that only a manual UPDATE ops.alerts can clear.
-- =====================================================================================================
-- SUPERSEDED LIVE by bigquery/153_account_snapshot_gap_watch.sql — current single
-- source of truth for ops.sp_sq_cadence_check (supersedes bigquery/128 above, per the chain noted
-- there). Intermediate link: bigquery/132_queue_driven_silence_watch.sql added the queue_driven_silent
-- check; bigquery/142 bumps the heartbeat to v12 and adds the process_constant_evidence_invalidated
-- WARNING block; bigquery/147 bumps the heartbeat to v13 and adds the run_log_note_missing record-only
-- check; bigquery/149 bumps the heartbeat to v14 and adds script_version_drift to the #14 auto-age
-- category list; bigquery/150 bumps the heartbeat to v15 and adds 'connector' + 'strategy_revised' to
-- the #14 auto-age category list; bigquery/153 bumps the heartbeat to v17 and adds the
-- account_snapshot_gap record-only WARNING block (+ 'account_snapshot_gap' to the #14 auto-age list).
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
-- SUPERSEDED (2026-08-09) by bigquery/157_account_snapshot_gap_recoverable.sql (SQ_VERSION v18) --
-- the current canonical definition of this procedure. 157 retracts a FALSEHOOD carried by every
-- version from v17 down: the account_snapshot_gap alert message claimed the gap days could never be
-- backfilled because IBKR exposes no historical-NAV endpoint. It does -- get_pa_performance_all_periods
-- returns parallel dates[]/nav[] arrays, and D2a Step 0b already calls it but keeps only the last
-- element. 157 changes exactly three strings (heartbeat v17->v18, that message, one comment) and no
-- check logic. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:cadence_check', 'v8', 'cadence_check.sql ran');

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
    -- immediate_action_flagged + process_scorecard_signal added 2026-07-16 (consumption-closure): point-in-time W3/M3/W5 signals, consumed autonomously by W4/M4 within days; 7-day age-out stops forever-open dashboard rows. A persisting condition is simply re-raised.
    -- scheduled_query_stale + ci_findings_bridge_stale + control_plane_insert added 2026-07-17 (MON H2/H4/H5): self-healing warnings (a resumed beat / a re-armed bridge / an aged-out control INSERT event stop being true) whose stable-message rows would otherwise linger open after the condition heals; a STILL-true condition is simply re-raised below (bridge_stale/scheduled_query_stale in THIS proc, control_plane_insert by safety_critical_dml_watch).
    AND category IN ('stranded_session', 'instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing', 'immediate_action_flagged', 'process_scorecard_signal', 'scheduled_query_stale', 'ci_findings_bridge_stale', 'control_plane_insert')
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
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(workflow, finding_key, CAST(finding_ts AS STRING) AS finding_ts, run_url)))
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

-- =====================================================================================================
-- ops.sp_sq_integrity_check   (was bigquery/scheduled_queries/integrity_check.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
-- SUPERSEDED LIVE by bigquery/141_append_only_halt_scope.sql — current single source of truth for
-- ops.sp_sq_integrity_check (141 scopes the monitor_health_history `clean` expression to
-- state.append_only_integrity_haltable so a bb21c91-sanctioned adversarial_reviews repair cannot
-- veto the promotion clock; the WARNING alerting body is unchanged). Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_integrity_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:integrity_check', 'v2', 'integrity_check.sql ran');

  -- MONITOR-PROMOTION HISTORY (self-improvement audit ITEM 31, 2026-07-15): logged UNCONDITIONALLY
  -- (pass or fail) every run, mirroring cadence_check.sql's ddl_drift/restore_stale MERGE-upsert
  -- pattern (bigquery/45_monitor_promotion.sql, ITEM 24) — state.append_only_integrity_promotion_
  -- readiness (bigquery/57_append_only_integrity_promotion.sql) needs this history to evaluate "14
  -- consecutive clean logged days", which state.append_only_integrity (a today-only, 2-day-lookback
  -- snapshot) cannot provide on its own. This does NOT change this query's alerting behavior at all —
  -- still WARNING-only, no RAISE, until D3's MONITOR-PROMOTION SELF-FLIP later promotes it (see
  -- bigquery/57's header for the exact future promoted body). MERGE, not INSERT, so a same-day re-run
  -- never double-logs one day (same rationale as cadence_check.sql's 2026-07-11 adversarial-self-audit
  -- fix).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'append_only_integrity' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.integrity', 'append_only_violation',
      CONCAT('Append-only integrity: out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
             (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
              FROM `stock-trading-498512.state.append_only_integrity`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
       FROM `stock-trading-498512.state.append_only_integrity`));
  END IF;
END;

-- =====================================================================================================
-- ops.sp_sq_safety_critical_dml_watch   (was bigquery/scheduled_queries/safety_critical_dml_watch.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v4 (bumped
-- from v3 by the control_plane_insert re-raise-noise fix, 2026-07-20: the WARNING-tier control_plane_
-- insert check near the bottom now uses a per-target-table WATERMARK instead of a flat 24h EXISTS —
-- fixes both a re-raise-after-resolve noise bug and a swallowed-second-insert detection gap; see the
-- inline comment on that check for the full incident/rationale. The three CRITICAL conditions (
-- safety_critical_dml / safety_critical_control_insert / safety_critical_lifecycle_insert) are
-- deliberately unchanged by this fix — see the same inline comment for why. v3 was bumped from v2 by
-- MON H4, 2026-07-17: INSERT-aware extension — ops.trading_control / ops.arsenal_control /
-- events.strategy_lifecycle change state by INSERT (append-only), which the UPDATE/DELETE/MERGE/TRUNCATE
-- filter could not see; the mutation-class watch is unchanged, and a single consolidated RAISE at the end
-- now folds in the two new CRITICAL conditions. See the inline INSERT block below).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_safety_critical_dml_watch`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';   -- H4: accumulate so all conditions RECORD before one final RAISE
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:safety_critical_dml_watch', 'v4', 'safety_critical_dml_watch.sql ran');

  -- Computed once, reused below (same "compute once, reuse" discipline as state.system_health's
  -- alerts_summary CTE) — avoids scanning INFORMATION_SCHEMA three times for one check.
  CREATE TEMP TABLE hits AS
  SELECT
    job_id,
    user_email,
    statement_type,
    destination_table.dataset_id AS target_dataset,
    destination_table.table_id   AS target_table,
    creation_time,
    SUBSTR(query, 0, 400) AS query_preview
  FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND state = 'DONE'
    AND error_result IS NULL
    AND statement_type IN ('UPDATE', 'DELETE', 'MERGE', 'TRUNCATE_TABLE')
    -- exactly the 4 safety-critical tables (ops.alerts deliberately excluded — see header).
    AND (
      (destination_table.dataset_id = 'ops'    AND destination_table.table_id = 'trading_control')
      OR (destination_table.dataset_id = 'ops'    AND destination_table.table_id = 'arsenal_control')
      OR (destination_table.dataset_id = 'events' AND destination_table.table_id = 'strategy_lifecycle')
      OR (destination_table.dataset_id = 'perf'   AND destination_table.table_id = 'strategy_daily')
    )
    -- ONE sanctioned exception: ops.sp_recompute_engine()'s nightly wholesale rebuild of
    -- perf.strategy_daily (03_twr_engine.sql) — an exact-text DELETE FROM ... WHERE TRUE with no other
    -- condition. Any other DELETE/UPDATE/MERGE/TRUNCATE on this table still fires. See header caveat.
    AND NOT (
      destination_table.dataset_id = 'perf' AND destination_table.table_id = 'strategy_daily'
      AND statement_type = 'DELETE'
      AND REGEXP_CONTAINS(
            query,
            r'(?i)^\s*delete\s+from\s+`?stock-trading-498512\.perf\.strategy_daily`?\s+where\s+true\s*;?\s*$'
          )
    );

  IF EXISTS (SELECT 1 FROM hits) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.safety_critical_dml', 'safety_critical_dml',
      CONCAT(
        'Safety-critical DML watch: out-of-band UPDATE/DELETE/MERGE/TRUNCATE detected on a safety-',
        'critical table in the last 24h (ops.trading_control / ops.arsenal_control / ',
        'events.strategy_lifecycle / perf.strategy_daily). See payload for job/table detail. This is a ',
        'DETECTIVE control (RUNBOOK item 6 / §15 shared-OAuth finding) — the mutation already happened; ',
        'investigate the job_id/user_email in the payload and, if unauthorized, restore the affected ',
        'table from its last known-good state (see the backup/restore-drill machinery, RUNBOOK §2/§27) ',
        'and reset the affected control table via a fresh sanctioned INSERT.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(
          job_id, user_email, statement_type, target_dataset, target_table, creation_time, query_preview
        ) ORDER BY creation_time))
       FROM hits));
    -- H4: RECORD then accumulate (was an immediate RAISE) so the two INSERT-aware CRITICALs below also
    -- record their own ops.alerts row before the single consolidated RAISE at the bottom fires.
    SET raise_msg = raise_msg || CONCAT('[safety_critical_dml] ',
      (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_dataset, '.', target_table), ', '
              ORDER BY CONCAT(statement_type, ' ', target_dataset, '.', target_table))
       FROM hits), '; ');
  END IF;

  -- =====================================================================================================
  -- INSERT-AWARE EXTENSION (MON H4, 2026-07-17). The mutation-class watch above filters
  -- statement_type IN (UPDATE/DELETE/MERGE/TRUNCATE) — but the three append-only CONTROL tables change
  -- state by INSERT: a halt-clear (ops.trading_control), a kill-switch clear (ops.arsenal_control), and a
  -- roster add/transition (events.strategy_lifecycle) are all INSERTs, and were therefore invisible.
  -- INSERT is the NORMAL way these tables change (unlike UPDATE/DELETE, which are definitionally wrong on
  -- an append-only table), so a bare INSERT is only WARNING-tier visibility (rare — a handful/month —
  -- hence high-signal); two CONTENT-specific anomalies escalate to CRITICAL + RAISE. perf.strategy_daily
  -- is deliberately NOT in this INSERT set: the nightly engine rebuild re-INSERTs it every day (its DELETE
  -- is the watched anomaly, already handled with the WHERE-TRUE exception above).
  CREATE TEMP TABLE control_inserts AS
  SELECT
    job_id, user_email,
    destination_table.dataset_id AS target_dataset,
    destination_table.table_id   AS target_table,
    creation_time
  FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND state = 'DONE'
    AND error_result IS NULL
    AND statement_type = 'INSERT'
    AND (
      (destination_table.dataset_id = 'ops'    AND destination_table.table_id IN ('trading_control', 'arsenal_control'))
      OR (destination_table.dataset_id = 'events' AND destination_table.table_id = 'strategy_lifecycle')
    );

  -- CRITICAL 1 — SPOOFED OPERATOR HALT-CLEAR. A trading_control INSERT landed in the last 24h AND a
  -- trading_control row with control_ts in that window reads halt_all=FALSE, mode='manual' — i.e. trading
  -- was re-enabled as if by the operator. Under the shared-OAuth model (RUNBOOK §15) BigQuery job metadata
  -- cannot distinguish a genuine operator clear from a spoofed one, so this DETECTIVE control alerts on
  -- EVERY manual re-enable and requires the operator to recognise their own action — a re-enable they did
  -- NOT perform is an intrusion. (Correlated as two independent EXISTS, not a job↔row time-join, because a
  -- correlated subquery with only an inequality condition is rejected by BigQuery; both live in the same
  -- 24h window, which is sufficient for detection.)
  IF ( EXISTS (SELECT 1 FROM control_inserts WHERE target_table = 'trading_control')
       AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.trading_control`
                   WHERE NOT halt_all AND mode = 'manual'
                     AND control_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)) ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.safety_critical_dml', 'safety_critical_control_insert',
      CONCAT('Safety-critical control INSERT: a trading_control INSERT in the last 24h re-enabled trading ',
             '(halt_all=FALSE, mode=manual) — a manual halt-clear. If YOU did not just re-enable ',
             'trading, this is a spoofed operator clear (shared-OAuth, RUNBOOK §15): re-assert the halt via ',
             'a fresh sanctioned INSERT and investigate the job_id/user_email in the payload.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, target_dataset, target_table, creation_time) ORDER BY creation_time))
       FROM control_inserts WHERE target_table = 'trading_control'));
    SET raise_msg = raise_msg || '[safety_critical_control_insert] trading_control manual halt-clear; ';
  END IF;

  -- CRITICAL 2 — UNKNOWN-STRATEGY LIFECYCLE INSERT. A strategy_lifecycle INSERT in the last 24h carries a
  -- strategy_code that entered NEITHER the SISA candidate funnel (state.strategy_candidates) NOR any prior
  -- lifecycle history (a code first seen >24h ago) — i.e. a strategy that materialised in the roster truth
  -- table without passing through the graduation pipeline. This is the live-detectable complement to the
  -- repo↔live roster parity check (scripts/check_live_roster_parity.py, which authoritatively diffs live
  -- vs strategy/roster.yaml in CI): SQL cannot read the repo YAML, so the "known set" here is the two live
  -- sources every legitimate code passes through — a legitimate transition of an existing strategy (A–E or
  -- a graduate) has prior history; a legitimate new probe was a candidate first. A garbage/spoofed code is
  -- in neither.
  IF ( EXISTS (SELECT 1 FROM control_inserts WHERE target_table = 'strategy_lifecycle')
       AND EXISTS (
         SELECT 1 FROM `stock-trading-498512.events.strategy_lifecycle` sl
         WHERE sl.event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
           AND sl.strategy_code NOT IN (
             SELECT strategy_code FROM `stock-trading-498512.events.strategy_lifecycle`
               WHERE event_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
             UNION DISTINCT
             SELECT candidate_code FROM `stock-trading-498512.state.strategy_candidates`
           )) ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.safety_critical_dml', 'safety_critical_lifecycle_insert',
      CONCAT('Safety-critical control INSERT: a strategy_lifecycle INSERT in the last 24h added a ',
             'strategy_code that never entered the SISA candidate funnel and has no prior lifecycle history ',
             '— a roster membership change that bypassed the graduation pipeline. Codes: ',
             (SELECT STRING_AGG(DISTINCT sl.strategy_code, ', ' ORDER BY sl.strategy_code)
              FROM `stock-trading-498512.events.strategy_lifecycle` sl
              WHERE sl.event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
                AND sl.strategy_code NOT IN (
                  SELECT strategy_code FROM `stock-trading-498512.events.strategy_lifecycle`
                    WHERE event_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
                  UNION DISTINCT
                  SELECT candidate_code FROM `stock-trading-498512.state.strategy_candidates`)),
             '. Investigate the job/user in the payload; verify against strategy/roster.yaml.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sl.strategy_code, sl.from_state, sl.to_state, sl.driver_routine, sl.event_ts) ORDER BY sl.event_ts))
       FROM `stock-trading-498512.events.strategy_lifecycle` sl
       WHERE sl.event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
         AND sl.strategy_code NOT IN (
           SELECT strategy_code FROM `stock-trading-498512.events.strategy_lifecycle`
             WHERE event_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
           UNION DISTINCT
           SELECT candidate_code FROM `stock-trading-498512.state.strategy_candidates`)));
    SET raise_msg = raise_msg || '[safety_critical_lifecycle_insert] strategy_lifecycle unknown code; ';
  END IF;

  -- WARNING (record-only, no RAISE) — general control-plane INSERT visibility, per-target-table WATERMARK
  -- (2026-07-20 fix, control_plane_insert re-raise-noise investigation). The PREVIOUS version keyed the
  -- message on the DISTINCT table@Denver-date set — stable across this query's 6-hourly re-runs of the
  -- same day's activity — but sp_raise_alert_once (bigquery/10_observability.sql) dedups ONLY on
  -- (NOT resolved AND category = ... AND message = ...). Once the operator RESOLVED the alert, the very
  -- next 6-hourly run rebuilt the byte-identical message (the source job was still inside its 24h
  -- INFORMATION_SCHEMA window) and RE-RAISED it. Observed live 2026-07-19: alert 578320a6 (16:59 MT,
  -- resolved 20:05 MT) then da8dd8c1 (22:59 MT, identical text) for ONE sanctioned D2a ops.trading_control
  -- INSERT. A WARNING channel crying wolf every 6h post-resolution trains the operator to ignore exactly
  -- the alert class that escalates to CRITICAL above. The same table@date keying ALSO SWALLOWED a
  -- genuinely SECOND sanctioned INSERT to the same table the same day whenever the first alert was still
  -- open (identical message + unresolved => sp_raise_alert_once blocks it) — a real missed-detection risk,
  -- not just noise.
  --
  -- FIX: only surface hits newer than the last time THIS target table's control-plane activity was
  -- raised-or-resolved — a PER-TARGET-TABLE watermark, never global (a quick resolution on one table must
  -- never mask another table's unsurfaced insert). Watermarked on job creation_time (monotonic at
  -- submission), not a date string, so a genuinely second same-day insert on the same table still clears
  -- the watermark and re-raises. COALESCE(resolved_ts, alert_ts) so a raised-but-never-resolved alert still
  -- advances the watermark (otherwise this would re-raise every 6h regardless — the same defect, just
  -- shifted forward). Defaults to epoch when no prior alert exists for a table, so that table's first-ever
  -- insert still raises loud. Correlating via `message LIKE '%dataset.table%'` (rather than a structured
  -- join column — ops.alerts has none) is safe here specifically because control_inserts.target_table is
  -- restricted, by the CTE above, to just the 3 known control tables — no ambiguity between e.g.
  -- 'ops.trading_control' and 'ops.arsenal_control' substrings, and this LIKE pattern matches BOTH the old
  -- and new message formats (verified against the two live 2026-07-19 alert rows), so the watermark is
  -- correct on the very first run after this fix deploys, not just going forward. Only the NEW hits feed
  -- the message/payload (not the whole 24h set), so the message text itself changes whenever something
  -- genuinely new happened; the newest new job's creation_time is folded in too, making consecutive alerts
  -- for the same table self-distinguishing (deterministic within one run — MAX() over a materialized temp
  -- table, not a live-changing source).
  CREATE TEMP TABLE new_control_inserts AS
  SELECT ci.*
  FROM control_inserts ci
  WHERE ci.creation_time > (
    SELECT COALESCE(MAX(COALESCE(a.resolved_ts, a.alert_ts)), TIMESTAMP('1970-01-01'))
    FROM `stock-trading-498512.ops.alerts` a
    WHERE a.source = 'scheduled.safety_critical_dml' AND a.category = 'control_plane_insert'
      AND a.message LIKE CONCAT('%', ci.target_dataset, '.', ci.target_table, '%')
  );

  IF EXISTS (SELECT 1 FROM new_control_inserts) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.safety_critical_dml', 'control_plane_insert',
      CONCAT('Control-plane INSERT(s) on append-only safety table(s) newer than the last raised-or-resolved ',
             'alert for that table (rare — confirm each was a sanctioned operator/routine action): ',
             (SELECT STRING_AGG(DISTINCT CONCAT(target_dataset, '.', target_table), ', '
                     ORDER BY CONCAT(target_dataset, '.', target_table))
              FROM new_control_inserts),
             '. Newest: ', (SELECT CAST(MAX(creation_time) AS STRING) FROM new_control_inserts)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, target_dataset, target_table, creation_time) ORDER BY creation_time))
       FROM new_control_inserts));
  END IF;

  -- Single consolidated RAISE — fires the DTS failure-email once, AFTER every CRITICAL above is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING safety-critical DML/INSERT watch FAILED — ', raise_msg,
      'See ops.alerts (source=scheduled.safety_critical_dml) for job_id/user_email detail.');
  END IF;
END;

-- =====================================================================================================
-- ops.sp_sq_daily_staging_cap_check   (was bigquery/scheduled_queries/daily_staging_cap_check.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v5 (bumped from
-- v4, 2026-08-04: order_guard_omitted now excludes ADOPTED dust liquidations -- see the ADOPTED-DUST
-- EXCLUSION paragraph on that check below. Review/alerting scope only; no trading behavior changes.
-- v4 was bumped from
-- v3, 2026-07-26, owner directive -- the daily order-count/notional cap is retired: dropped the
-- daily_cap_breach IF block below. daily_cap_breach was the ONLY consumer of state.daily_staging_totals's
-- now-removed max_daily_notional/max_daily_orders fields (bigquery/109_retire_daily_staging_cap.sql);
-- it was a RECORD-ONLY WARNING alert that never blocked any order craft, so this changes review/
-- alerting only, not trading behavior. order_guard_omitted / order_guard_verdict_mismatch below are
-- UNRELATED per-order guard-record checks and are unchanged. v3 bumped from v2 by DEF-3, 2026-07-17:
-- added the order_guard_verdict_mismatch RECOMPUTE backstop below; v2 was the ARCH-1 wrapper
-- migration, 2026-07-16).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_daily_staging_cap_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_staging_cap_check', 'v5', 'daily_staging_cap_check.sql ran');

  -- order_guard_omitted (CRITICAL, not staged-rollout -- ITEM 15, self-improvement audit 2026-07-11).
  -- fn_order_guard / fn_order_guard_options is a per-order obligation on the calling routine, with no
  -- mechanical enforcement possible (no BigQuery stored procedure can gate a call to a DIFFERENT MCP
  -- tool, create_order_instruction) -- compliance depended entirely on the routine's markdown instructions
  -- being followed verbatim. state.open_orders.guard_passed (bigquery/01_schema.sql) now surfaces whether
  -- the guard's own result was embedded in the ORDER_STAGED payload; a row STAGED TODAY with guard_passed
  -- IS NULL means either the guard never ran, or it ran and the routine didn't record it -- either way
  -- the safety envelope was bypassed for that order, not merely undocumented. Unlike a soft aggregate-
  -- level warning (the now-retired daily_cap_breach check, bigquery/109_retire_daily_staging_cap.sql --
  -- 2026-07-26), a missing guard record is unambiguous -- CRITICAL immediately, no staged-rollout
  -- warning period.
  --
  -- QUERIES events.queue_events DIRECTLY, NOT state.open_orders (adversarial self-audit fix, rev
  -- 2026-07-11): state.open_orders is a PENDING-ONLY view (WHERE status='pending'), so an order staged
  -- WITHOUT the guard that then FILLED or was reconciled the same Denver day drops out of it before this
  -- check runs at ~05:25 UTC -- exactly the worst case this control exists to catch (capital deployed
  -- outside the risk envelope) silently escaping detection. queue_events is append-only: the original
  -- 'pending' ORDER_STAGED row for an order staged today is never overwritten by its later terminal-status
  -- row (a separate row, same item_key), so filtering the raw table on status='pending' still finds every
  -- staging event from today regardless of what happened to the order afterward.
  -- MESSAGE EMBEDS THE AFFECTED item_keys (adversarial self-audit fix, rev 2026-07-11): ops.sp_raise_alert_once
  -- dedupes on (category, message) WHERE NOT resolved (bigquery/10_observability.sql). A fully static message
  -- would mean that once this CRITICAL opens and is left unresolved, a LATER day's guard-omission on a
  -- DIFFERENT, newly-affected order would silently fail to re-alert (the dedup guard blocks the INSERT before
  -- the fresh payload evidence is even recorded) -- exactly the kind of new information this check exists to
  -- surface. Embedding the sorted, comma-joined item_keys makes the message (and so the dedup key) change
  -- whenever the SET of affected orders changes, while an unchanged set (the same still-open omission, re-
  -- evaluated on a later run) still correctly dedupes to a single alert, not a new one every run.
  --
  -- ADOPTED-DUST EXCLUSION (2026-08-04, alert ebfbff4e-f491-4763-81a9-ef360744cbc5 -- this check's FIRST
  -- ever firing, and a false positive). The premise above -- "guard_passed IS NULL means the guard never ran
  -- or the routine didn't record it, either way the envelope was bypassed" -- has exactly one legitimate
  -- exception, and it is not a bypass at all: an ADOPTED dust liquidation. Per Claude_Task_Plan.md's
  -- "ADOPTION OF AN UNREGISTERED DUST LIQUIDATION — PRE-FILL PATH ONLY (2026-08-02)" branch, a dust SELL can
  -- already be live at the connector with no queue_events row (operator-tapped, pre-registry, or hand-placed);
  -- D2a ADOPTS it rather than declining. D2a never calls create_order_instruction for such an order, so there
  -- is NO pre-craft moment at which fn_order_guard could have been called -- and D2a records that honestly as
  -- guard_passed=NULL with guard_reasons=[n/a - adopted, not crafted by D2a], never as a fabricated TRUE.
  -- Flagging that honest, self-documented null as a bypassed risk envelope is a category error, and an
  -- expensive one: order_guard_omitted is CRITICAL, and an open CRITICAL is itself a trading-gate input
  -- (state.trading_enabled_mechanical's blocking_criticals branch), so the false positive HALTED all order
  -- staging over two adopted dust SELLs totalling ~$0.20 of risk-REDUCING notional (IBM 0.0007sh, HCA 0.0001sh).
  -- The exclusion is deliberately narrow -- item_type='drip-dust-liquidation' AND payload.adopted='true'
  -- TOGETHER. A NORMAL D2a-CRAFTED dust SELL (same item_type, adopted absent/false) still runs the spec's
  -- STANDARD GUARD step and must still be caught here if its guard_passed is missing; and payload.adopted is
  -- written on no other order class (verified live 2026-08-04), so this cannot become a loophole elsewhere.
  --
  -- WRAPPED IN COALESCE(..., FALSE) DELIBERATELY -- this is a fail-CLOSED exclusion, and the bare form is a
  -- LIVE FAIL-OPEN BUG (caught in same-session self-review, 2026-08-04, before it could bite). Written bare as
  -- `AND NOT (item_type = '...' AND JSON_VALUE(...) = 'true')`, the inner AND evaluates to NULL whenever
  -- item_type IS NULL, NOT NULL is NULL, and WHERE NULL DROPS THE ROW -- silently excluding it from a CRITICAL
  -- detector. events.queue_events DOES carry ORDER_STAGED rows with NULL item_type (verified live: item_key
  -- 'entry-TSM-D-20260717', 2026-07-20, 1 of 82 ORDER_STAGED rows), so this is reachable, not theoretical: a
  -- future NULL-item_type order staged WITHOUT a guard -- precisely the bypass this check exists to catch --
  -- would have been swallowed. COALESCE(..., FALSE) makes the exclusion fire ONLY when both conjuncts are
  -- provably TRUE; anything unknown stays IN the detector and gets flagged. When adding any future exclusion
  -- here, keep that polarity: an exclusion on a safety check must never be able to evaluate to NULL.
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.events.queue_events`
    WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
      AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
      AND JSON_VALUE(payload, '$.guard_passed') IS NULL
      -- ADOPTED-DUST EXCLUSION -- see the paragraph above. Kept byte-identical across all three
      -- predicates below so the message/payload can never disagree with this gate.
      AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.staging_cap', 'order_guard_omitted',
      (SELECT FORMAT(
          'One or more orders staged today have no recorded fn_order_guard/fn_order_guard_options result -- the pre-craft risk envelope may have been bypassed for these orders: %s.',
          -- COALESCE defends against FORMAT('%s', NULL) returning a hard SQL NULL (verified) if this ever
          -- somehow evaluated over zero rows despite the IF EXISTS above having matched -- ops.alerts.message
          -- is NOT NULL, so an unguarded NULL here would error the whole scheduled query (adversarial
          -- self-audit fix, rev 2026-07-11; confirmed not currently reachable -- this predicate is
          -- byte-identical to the IF EXISTS guard and events.queue_events is append-only -- but free to close).
          COALESCE(STRING_AGG(DISTINCT item_key, ', ' ORDER BY item_key), 'UNKNOWN'))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL
         AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(
          item_key, strategy, ticker,
          UPPER(JSON_VALUE(payload, '$.side')) AS side,
          CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) AS qty,
          CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS limit_price,
          event_ts AS staged_ts)))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL
         AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)));
  END IF;

  -- order_guard_verdict_mismatch (CRITICAL, DEF-3 order-guard TRUTHFULNESS backstop -- defense-in-depth,
  -- 2026-07-17; recompute updated 2026-07-22 for the pre-trade-rail strip, bigquery/104_strip_pretrade_
  -- rails.sql). The order_guard_omitted check directly above is the sole detective backstop, but it only
  -- verifies that payload.guard_passed IS PRESENT -- never that it is TRUTHFUL. A routine could stage an
  -- order carrying guard_passed=true beside a malformed qty/limit_price/order_type the guard would
  -- actually REJECT, and order_guard_omitted (which keys only on the field's presence) would wave it
  -- through. This check RECOMPUTES the market-only, 5-arg analytics.fn_order_guard (owner directive
  -- 2026-07-22, bigquery/104_strip_pretrade_rails.sql -- ALL liquidity + sizing pre-trade rails removed;
  -- was the 9-arg expected-shortfall guard of bigquery/100_market_only_order_guard.sql) from each row's
  -- OWN payload: strategy, side, qty, limit_price (passed as p_ref_price -- there is no limit price left
  -- to band against), order_type hardcoded to 'MARKET' (this recompute always checks what a market-only
  -- order must have been). There are no liquidity inputs left to read: adv_usd/spread_bps/sigma_daily and
  -- p_is_park are no longer guard parameters at all (the ADV/participation/expected-shortfall gate and the
  -- park 1.10x-NAV magnitude backstop are both gone) -- every staged equity/park row is recomputed
  -- identically, a market-only + qty/ref-price sanity check, with no park-vs-non-park distinction left to
  -- draw. RAISEs CRITICAL when the recomputed verdict is FALSE (the guard would have rejected), whether
  -- the row carried a forged guard_passed=true, an honest guard_passed=false the routine staged anyway, or
  -- no guard record at all.
  --
  -- HONEST LIMITATION (read before trusting this as a gate). BigQuery has NO independent source of order
  -- truth: the REAL order goes to IBKR via a DIFFERENT MCP tool (create_order_instruction) that no
  -- BigQuery stored procedure can see or gate (the same 'no SP can gate a call to a different MCP tool'
  -- limitation the order_guard_omitted header states). This recompute therefore catches an INCONSISTENT
  -- forgery -- guard_passed=true left beside HONEST qty/limit_price/order_type the guard would reject, a
  -- guard that returned FALSE but the order was staged, or a guard never called on a malformed order -- but
  -- it CANNOT catch a fully-COHERENT forgery that ALSO fakes qty/limit_price in the payload to match the
  -- fabricated guard_passed=true (the recompute would then read the faked-consistent numbers and pass). It
  -- raises the bar (an attacker must now forge the order fields consistently, not just the flag); it is NOT
  -- a complete gate. Queries events.queue_events DIRECTLY (append-only), same rationale as
  -- order_guard_omitted: a same-day-filled order must not drop out of a pending-only view before this runs.
  BEGIN
    DECLARE mismatch_keys STRING DEFAULT '';
    DECLARE mismatch_json STRING DEFAULT '';
    DECLARE v_passed BOOL;
    DECLARE v_reasons STRING;
    FOR rec IN (
      SELECT
        item_key,
        strategy,
        COALESCE(UPPER(JSON_VALUE(payload, '$.side')), 'BUY') AS side,
        SAFE_CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) AS qty,
        SAFE_CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS limit_price,
        JSON_VALUE(payload, '$.guard_passed') AS recorded_guard_passed
      FROM `stock-trading-498512.events.queue_events`
      WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
        AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
        -- qty/limit_price IS NOT NULL both sanity-filters malformed payloads AND is the only remaining
        -- thing that distinguishes an equity ORDER_STAGED row (qty/limit_price) from an options one
        -- (contracts/ref_premium/max_loss_dollars -- a different payload shape this recompute does not
        -- touch, left to order_guard_omitted's presence-only check above). No adv/liquidity/park-based
        -- eligibility filter remains -- with no liquidity or park-NAV rail left (owner directive
        -- 2026-07-22, bigquery/104_strip_pretrade_rails.sql), every staged equity/park row is recomputed
        -- identically, so there is no longer a distinct eligibility condition to gate the recompute on.
        AND SAFE_CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) IS NOT NULL
        AND SAFE_CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) IS NOT NULL
    ) DO
      -- Per-row recompute. rec.* are scripting-variable field accesses (constant per iteration), a valid
      -- table-function argument form (verified: fn_order_guard accepts non-constant scalar arguments).
      -- order_type is hardcoded to 'MARKET' -- this recompute always checks what a market-only order must
      -- have been (owner directive 2026-07-21, bigquery/100_market_only_order_guard.sql), independent of
      -- whatever order_type (if any) the original payload recorded. The guard call itself is the 5-arg
      -- bigquery/104_strip_pretrade_rails.sql signature (owner directive 2026-07-22): no is_park / adv_usd
      -- / spread_bps / sigma_daily arguments remain to pass.
      SET (v_passed, v_reasons) = (
        SELECT AS STRUCT passed, TO_JSON_STRING(reasons)
        FROM `stock-trading-498512.analytics.fn_order_guard`(
          rec.strategy, rec.side, rec.qty, rec.limit_price, 'MARKET')
      );
      IF NOT COALESCE(v_passed, FALSE) THEN
        SET mismatch_keys = mismatch_keys || IF(mismatch_keys = '', '', ', ') || rec.item_key;
        SET mismatch_json = mismatch_json || IF(mismatch_json = '', '', ',') ||
          TO_JSON_STRING(STRUCT(
            rec.item_key AS item_key, rec.strategy AS strategy, rec.side AS side,
            rec.qty AS qty, rec.limit_price AS limit_price,
            rec.recorded_guard_passed AS recorded_guard_passed,
            v_passed AS recomputed_passed, v_reasons AS recomputed_reasons));
      END IF;
    END FOR;
    -- DEDUP-CRITICAL, same convention as order_guard_omitted above: the message embeds the sorted set of
    -- affected item_keys so ops.sp_raise_alert_once's (category, message) dedup re-alerts when the SET of
    -- offending orders changes, but collapses an unchanged still-open mismatch to one row. mismatch_keys is
    -- accumulated in the FOR loop's own iteration order (item_key); daily-changing detail lives in payload.
    IF mismatch_keys != '' THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'critical', 'scheduled.staging_cap', 'order_guard_verdict_mismatch',
        CONCAT('Order-guard verdict RECOMPUTE mismatch -- order(s) staged today whose OWN payload ',
               '(strategy/qty/limit_price) independently re-run through analytics.fn_order_guard return ',
               'FALSE (the guard would REJECT), yet the order was staged -- in some cases beside a recorded ',
               'guard_passed=true. This is an INCONSISTENT order-guard record (a forged/omitted guard left ',
               'beside honest order fields), not merely an undocumented one: ', mismatch_keys,
               '. See payload for per-order recomputed reasons.'),
        CONCAT('[', mismatch_json, ']'));
    END IF;
  END;
END;

-- =====================================================================================================
-- ops.sp_sq_backup_events_export   (was bigquery/scheduled_queries/backup_events_export.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_backup_events_export`()
BEGIN
  DECLARE failed STRING DEFAULT '';
  DECLARE n_ok INT64 DEFAULT 0;   -- tables exported successfully this run (-> ops.backup_log marker)
  DECLARE row_json STRING DEFAULT '';  -- accumulates {"table": rows, ...} per exported table (B2)
  DECLARE tbl_rows INT64;
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:backup_events_export', 'v2', 'backup_events_export.sql ran');

  FOR rec IN (
    SELECT table_name
    FROM `stock-trading-498512.events.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'BASE TABLE'
    ORDER BY table_name
  ) DO
    BEGIN
      EXECUTE IMMEDIATE FORMAT("""
        EXPORT DATA OPTIONS(
          uri='gs://stock-trading-backups/events/%s/dt=%s/*.parquet',
          format='PARQUET', compression='SNAPPY', overwrite=true
        ) AS SELECT %s FROM `stock-trading-498512.events.%s`
      """,
        rec.table_name,
        CAST(CURRENT_DATE('America/Denver') AS STRING),
        -- per-table column list: JSON -> TO_JSON_STRING(col) AS col; everything else verbatim
        (SELECT STRING_AGG(
                  IF(data_type = 'JSON',
                     FORMAT('TO_JSON_STRING(`%s`) AS `%s`', column_name, column_name),
                     FORMAT('`%s`', column_name)),
                  ', ' ORDER BY ordinal_position)
         FROM `stock-trading-498512.events.INFORMATION_SCHEMA.COLUMNS`
         WHERE table_name = rec.table_name),
        rec.table_name);
      SET n_ok = n_ok + 1;   -- counted only if the EXPORT above succeeded (else we jump to EXCEPTION)
      -- B2: record this table's source row count in the backup marker (per_table_rows). EXPORT DATA is
      -- atomic — a non-empty source either fully exports or RAISEs — so this is the row-count evidence
      -- the §3 restore drill asserts, captured at WRITE time: auditable day-over-day (an append-only
      -- table's count only grows; a drop = deletion or a future predicate regression) and a forensic
      -- anchor for a restore. (hf_capability_captures = 0 is legitimately empty.)
      EXECUTE IMMEDIATE FORMAT(
        "SELECT COUNT(*) FROM `stock-trading-498512.events.%s`", rec.table_name) INTO tbl_rows;
      SET row_json = row_json || FORMAT('%s"%s":%d', IF(row_json = '', '', ','), rec.table_name, tbl_rows);
    EXCEPTION WHEN ERROR THEN
      -- isolate the failure; keep backing up the remaining tables
      SET failed = failed || FORMAT('%s (%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  -- Surface any failures: durable alert + RAISE so the scheduled query's email-on-failure fires.
  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.backup', 'backup_export',
      CONCAT('events backup: some tables failed to export: ', failed),
      TO_JSON_STRING(STRUCT(failed AS failed_tables)));
    RAISE USING MESSAGE = CONCAT('events-backup-daily: table export failures: ', failed);
  ELSE
    -- Success marker (bigquery/16_automation_health.sql): records that the backup ran, so
    -- state.backup_health / cadence_check.sql can detect a SILENTLY-STALLED backup (one that simply
    -- stops running) — which the data-side freshness switch cannot see. Only on a full-success run.
    -- per_table_rows carries the B2 per-table source counts (bigquery/18_stack_review_fixes.sql adds
    -- the column; apply 18 before re-pasting this query). SAFE.PARSE_JSON so a malformed map degrades
    -- to NULL rather than aborting the marker write.
    -- dataset='events' (2026-06-28): distinguishes this marker from the sibling ops_export.sql's
    -- dataset='ops' marker so state.backup_health (events) and state.ops_backup_health (ops) watch the two
    -- backups independently, and the restore drill keeps anchoring its drill-date on the events snapshot.
    INSERT INTO `stock-trading-498512.ops.backup_log` (run_date, tables_exported, per_table_rows, dataset, note)
    VALUES (CURRENT_DATE('America/Denver'), n_ok,
            SAFE.PARSE_JSON('{' || row_json || '}'), 'events', 'events.* export OK');
  END IF;
END;

-- =====================================================================================================
-- ops.sp_sq_ops_export   (was bigquery/scheduled_queries/ops_export.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_ops_export`()
BEGIN
  DECLARE failed STRING DEFAULT '';
  DECLARE n_ok INT64 DEFAULT 0;
  DECLARE row_json STRING DEFAULT '';
  DECLARE tbl_rows INT64;
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:ops_export', 'v2', 'ops_export.sql ran');

  FOR rec IN (
    SELECT table_name
    FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'BASE TABLE'   -- excludes procedures, remote models (text_embed/gemini), and views
    ORDER BY table_name
  ) DO
    BEGIN
      EXECUTE IMMEDIATE FORMAT("""
        EXPORT DATA OPTIONS(
          uri='gs://stock-trading-backups/ops/%s/dt=%s/*.parquet',
          format='PARQUET', compression='SNAPPY', overwrite=true
        ) AS SELECT %s FROM `stock-trading-498512.ops.%s`
      """,
        rec.table_name,
        CAST(CURRENT_DATE('America/Denver') AS STRING),
        (SELECT STRING_AGG(
                  IF(data_type = 'JSON',
                     FORMAT('TO_JSON_STRING(`%s`) AS `%s`', column_name, column_name),
                     FORMAT('`%s`', column_name)),
                  ', ' ORDER BY ordinal_position)
         FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.COLUMNS`
         WHERE table_name = rec.table_name),
        rec.table_name);
      SET n_ok = n_ok + 1;
      EXECUTE IMMEDIATE FORMAT(
        "SELECT COUNT(*) FROM `stock-trading-498512.ops.%s`", rec.table_name) INTO tbl_rows;
      SET row_json = row_json || FORMAT('%s"%s":%d', IF(row_json = '', '', ','), rec.table_name, tbl_rows);
    EXCEPTION WHEN ERROR THEN
      SET failed = failed || FORMAT('%s (%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.backup', 'ops_backup_export',
      CONCAT('ops backup: some tables failed to export: ', failed),
      TO_JSON_STRING(STRUCT(failed AS failed_tables)));
    RAISE USING MESSAGE = CONCAT('ops-backup-daily: table export failures: ', failed);
  ELSE
    -- dataset='ops' marker so state.ops_backup_health (16_automation_health.sql) can detect a stalled
    -- ops backup. SAFE.PARSE_JSON so a malformed map degrades to NULL rather than aborting the marker.
    INSERT INTO `stock-trading-498512.ops.backup_log` (run_date, tables_exported, per_table_rows, dataset, note)
    VALUES (CURRENT_DATE('America/Denver'), n_ok,
            SAFE.PARSE_JSON('{' || row_json || '}'), 'ops', 'ops.* export OK');
  END IF;
END;

-- =====================================================================================================
-- ops.sp_sq_delivery_canary   (was bigquery/scheduled_queries/delivery_canary.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_delivery_canary`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:delivery_canary', 'v2', 'delivery_canary.sql ran');

  -- 1. Emit this week's canary FIRST (resolved + unnotified so it is forwarded-and-stamped but never
  -- an open alert). Reordered ahead of the assertion below (2026-07-04 audit finding): the assertion's
  -- RAISE previously ran first and — RAISE terminating the script — aborted before this INSERT ran,
  -- so a SUSTAINED delivery outage skipped emitting a fresh canary every other week, halving the
  -- canary's effective detection cadence. This INSERT is independent of the assertion below, so
  -- running it unconditionally first means it always happens, RAISE or not.
  INSERT INTO `stock-trading-498512.ops.alerts`
    (severity, source, category, message, payload, resolved, resolved_ts, notified_ts)
  VALUES (
    'warning', 'scheduled.canary', 'delivery_canary',
    CONCAT('[CANARY] Weekly alert-delivery self-test — no action needed (', CAST(CURRENT_DATE('America/Denver') AS STRING), ').'),
    SAFE.PARSE_JSON('{"canary":true}'),
    TRUE, CURRENT_TIMESTAMP(), NULL);

  -- 2. Assert the prior week's canary was delivered (notified_ts stamped).
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.alerts`
    WHERE source = 'scheduled.canary' AND category = 'delivery_canary'
      AND notified_ts IS NULL
      AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
      AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 9 DAY)
  ) THEN
    -- Also record it durably (so the relay/digest see it too), then RAISE for the DTS failure-email.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.canary', 'delivery_failure',
      'Alert-delivery canary: the prior weekly canary was never delivered (notified_ts still NULL after >2 days) — the alert_emailer is not stamping/sending. Verify the Apps Script BigQuery+Gmail scopes and trigger.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(alert_id, CAST(alert_ts AS STRING) AS alert_ts)))
       FROM `stock-trading-498512.ops.alerts`
       WHERE source = 'scheduled.canary' AND category = 'delivery_canary' AND notified_ts IS NULL
         AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
         AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 9 DAY)));
    RAISE USING MESSAGE = 'STOCK-TRADING delivery canary FAILED — prior weekly canary undelivered (notified_ts NULL).';
  END IF;
END;

-- =====================================================================================================
-- ops.sp_sq_restore_drill   (was bigquery/scheduled_queries/restore_drill.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_restore_drill`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:restore_drill', 'v2', 'restore_drill.sql ran');
  CALL `stock-trading-498512.ops.sp_restore_drill`();
END;

-- =====================================================================================================
-- ops.sp_sq_fire_drill_order_guard   (was bigquery/scheduled_queries/fire_drill_order_guard.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_fire_drill_order_guard`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:fire_drill_order_guard', 'v2', 'fire_drill_order_guard.sql ran');
  CALL `stock-trading-498512.ops.sp_fire_drill_order_guard`();
END;

-- =====================================================================================================
-- ops.sp_sq_fire_drill_alert_lifecycle   (was bigquery/scheduled_queries/fire_drill_alert_lifecycle.sql; that file is now a frozen one-line
-- CALL wrapper — full historical header/rationale comments remain there. SQ_VERSION v2 (bumped
-- from v1 by this ARCH-1 wrapper migration, 2026-07-16 — no check logic changed).
-- SUPERSEDED LIVE by bigquery/134_roster_change_notifications.sql — current single source of truth
-- for this procedure. 134 bumps SQ_VERSION v2 -> v3 and adds a third drill call,
-- ops.sp_fire_drill_roster_notice. Kept here, unmodified, for DR-rebuild apply-in-order reference
-- only. DO NOT re-apply this CREATE OR REPLACE PROCEDURE statement live in isolation.
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_fire_drill_alert_lifecycle`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:fire_drill_alert_lifecycle', 'v2', 'fire_drill_alert_lifecycle.sql ran');
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_latch`();
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_resolve`();
END;

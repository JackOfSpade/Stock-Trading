-- ============================================================================
-- 205 — ALERT MESSAGE STABILITY: stop `sp_raise_alert_once` degenerating into
--       a plain `sp_raise_alert` on five persisting conditions.
--
-- WHY (message-stability class sweep, 2026-08-31 interactive session).
-- `ops.sp_raise_alert_once` (bigquery/10_observability.sql) dedups with exactly:
--     IF NOT EXISTS (SELECT 1 FROM ops.alerts
--                    WHERE NOT resolved AND category = in_category AND message = in_message)
-- That is EXACT STRING EQUALITY on `message`, and nothing else. So any caller whose
-- message embeds a value that MOVES between runs -- a run date, an elapsed-day count,
-- a row count, a dollar figure, a live percentage -- can never match its own prior
-- open row. `_once` silently becomes `sp_raise_alert`, and a condition that PERSISTS
-- raises a NEW alert every run, each with notified_ts NULL and therefore separately
-- emailed. That is the precise alarm fatigue `_once` was chosen to prevent, arriving
-- exactly when the operator most needs a clean board.
--
-- This is a KNOWN, RECURRING defect class in this repo, not a new theory:
--   * `probe_funding_stalled`  -- found + corrected in prose by SL3, 2026-08-26.
--   * `queue_item_stale`       -- found + corrected in prose (D3 QUEUE HYGIENE), 2026-08-31.
--   * `trading_halted`         -- fixed 2026-07-04 in bigquery/85 for this exact reason.
--   * `calendar_runway_low`, `trigger_missing`, `position_reconciliation_lag` -- all
--     previously fixed the same way.
-- A sweep of every live `sp_raise_alert_once` call site (~95 distinct) found the five
-- below still carrying the defect. Every other site is stable and was left alone.
--
-- WHAT CHANGES: the `message` TEXT ONLY. No predicate, no threshold, no severity, no
-- gate semantics and no control flow is touched by this file. Every value removed from
-- a message was ALREADY present in that call's payload (or in a named view), so no
-- information is lost -- it moves from a field that breaks dedup to one that does not.
--
--  (1) ops.sp_assert_deps            -- `missing_dependency` (CRITICAL). Dropped `in_run_date`.
--      The worst of the five: severity critical, called by EVERY routine, and a
--      dependency block that lasts n days emailed n critical alerts. The sibling
--      `trading_halted` gate in bigquery/85 was explicitly fixed for this in 2026-07-04
--      ("either one varying the message text defeats sp_raise_alert_once's exact-match
--      dedup"); that fix was simply never ported here. The RAISE below it still carries
--      the run_date -- RAISE is the abort path, not deduped, and is unchanged.
--  (2) ops.sp_sq_cadence_check       -- `queue_driven_silent`. Dropped `last_run_date`
--      and `days_silent` (the latter increments daily by construction). This check
--      watches AR_att/AR_orc/SL2/SL5, which sit outside the cadence nets -- so the
--      condition it reports is exactly the long-persisting kind.
--  (3) ops.sp_sq_cadence_check       -- `backup_per_table_row_drop`. Dropped
--      `prior_rows`->`latest_rows`; a table that keeps shrinking moved both every day.
--  (4) ops.sp_sq_cadence_check       -- `process_constant_evidence_invalidated`. Dropped
--      the two 0-3 threat-streak counters, which are recomputed fresh each run. This
--      category is deliberately ABSENT from #14's auto-age allowlist so it stays open as
--      ONE row until a human closes it -- which a drifting message made impossible.
--  (5) state.entry_staging_allowed   -- `book_drawdown_soft_breach` (the `block_reason`
--      column D2a passes to sp_raise_alert_once). Was FORMAT(...) interpolating
--      `drawdown_from_peak`, which moves with NAV every day the book stays in soft
--      breach -- while the plan text next to the call claimed "a persisting breach does
--      not re-email daily". Now a fixed literal; the live figure stays available on
--      state.book_drawdown_watch.drawdown_from_peak. LATENT, never fired (breach_soft
--      is FALSE), so no live disposition changes. Verified before editing: nothing in
--      bigquery/, dbt/, scripts/ or ops/ parses block_reason text (no LIKE / REGEXP /
--      STARTS_WITH / equality) -- it is pass-through and display only. The
--      `owner_confirmation_stale` branch of the same CASE is deliberately UNCHANGED: it
--      also varies, but Claude_Task_Plan.md gates its RAISE on "only if no unresolved
--      owner_confirmation_stale alert already exists", an external guard that already
--      neutralises it. Do not "fix" that branch without removing the guard in the same pass.
--
-- CANONICITY, verified before this file was written: sp_assert_deps' highest-numbered
-- definition is 114 (also in 12, 48); sp_sq_cadence_check's is 186 (also in 13 earlier
-- files); state.entry_staging_allowed exists ONLY in 78 and carries no
-- "do NOT re-apply in isolation" header, unlike its neighbours book_drawdown_watch and
-- trading_enabled in that same file. Each body below is the canonical one, copied
-- programmatically (not retyped) with only the message substitutions above applied.
-- Re-run safe (CREATE OR REPLACE).
--
-- APPLY STATE — COMPLETE. All three objects are live and verified.
-- Applied from an interactive operator session on 2026-08-31:
--   * state.entry_staging_allowed  — APPLIED and VERIFIED. entries_allowed read TRUE /
--     block_reason NULL both immediately before and immediately after the replace, so the gate
--     did not move.
--   * ops.sp_assert_deps           — APPLIED (job_P3cvAum_OSXpFpefRlxheR7bKMgf).
--   * ops.sp_sq_cadence_check      — APPLIED (job_Ze-ievkIO1KlrFMAaxRFVo88cav5).
-- VERIFIED END-TO-END by `scripts/check_live_sql_parity.py`: 247 objects compared against live
-- BigQuery, **0 mismatched, 0 missing, 0 unchecked**. That checker — not this comment — is the
-- authority on repo==live; re-run it rather than trusting this note if the two ever disagree.
--
-- HISTORICAL, kept because it explains the odd statement ORDER in this file and a ~40-minute
-- window of real drift: the BigQuery OAuth token expired part-way through the original apply,
-- after the first two objects and ON sp_sq_cadence_check. That is why sp_sq_cadence_check is
-- listed LAST here, and why the commit that introduced this file (1b26ce0) described the apply
-- as partial. The connector was re-authorized and the procedure applied verbatim from this
-- file's own copy in the same session; parity then came back clean. No re-apply is owed.
-- ============================================================================

-- ===== (1) ops.sp_assert_deps — canonical body from bigquery/114, message stabilised =====
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
      FORMAT('%s blocked: upstream dependency not completed: %s', in_routine, missing),
      TO_JSON_STRING(STRUCT(in_routine AS routine, CAST(in_run_date AS STRING) AS run_date, missing AS missing_deps)));
    RAISE USING MESSAGE = FORMAT(
      '%s dependency check FAILED (run_date %t): missing completed upstream: %s', in_routine, in_run_date, missing);
  END IF;
END;
-- ===== (2)(3)(4) ops.sp_sq_cadence_check — canonical body from bigquery/186, 3 messages stabilised =====
-- SUPERSEDED (2026-09-06) by bigquery/227_alert_message_stability_ordering.sql, the current
-- canonical definition of this procedure. 227 changes ORDER BY CLAUSES ONLY, on four
-- sp_raise_alert_once messages (ci_finding, routine_stalled, process_constant_evidence_invalidated,
-- constant_tuning_loop_heartbeat_missing) whose STRING_AGG ordering was NARROWER than the fields the
-- message prints -- or absent outright -- so tied rows could permute and render the SAME condition as
-- a DIFFERENT string, defeating that procedure's own exact-message dedup and re-alerting on an
-- UNCHANGED condition (measured twice live: 2026-07-24/25 and 2026-07-31 05:00/05:16, identical open
-- sets, duplicate rows and duplicate emails). No predicate, threshold, severity or control flow
-- differs. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:cadence_check', 'v21', 'cadence_check.sql ran');

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
      resolved_note = CONCAT('auto-aged (>7d self-healing warning/info; cadence_check.sql #14). ', COALESCE(resolved_note, ''))
  WHERE NOT resolved
    AND severity IN ('warning', 'info')
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
    -- connector_tool_inventory_stale added 2026-08-08 (same v16 change that adds the check block below,
    -- bigquery/151_connector_tool_inventory.sql): the identical self-healing shape as scheduled_query_
    -- version_drift / script_version_drift above -- state.connector_tool_inventory_stale reports only what
    -- the LAST enumeration run observed, so once OPS1 resumes a trustworthy sweep the condition clears on
    -- its own. It has no ops.alert_policy row either, so leaving it off this list would reproduce the exact
    -- connector/strategy_revised bug this file exists to fix, for a third category, in the same commit.
    -- monitor_promoted added 2026-08-19 (bigquery/186, by the D3 run that had just raised one) -- the SAME
    -- structural bug as strategy_revised, which bigquery/150 added and bigquery/159 finally made effective.
    -- It is an info-severity COMPLETED-ACTION RECORD ("check X promoted WARNING->CRITICAL, no owner action
    -- required"), so at info severity it is filtered out of both alert_emailer.gs's and scripts/
    -- alert_relay.py's notification queries before ever reaching notified_ts, and Rule 5's on-delivery
    -- resolve path never sees it. It also has no ops.alert_policy row. Between those two facts NO automated
    -- mechanism could ever close one, and the live table proves the cost was already being paid by hand:
    -- all three prior rows (ddl_drift 2026-07-12, park_allocator/ddl_drift 2026-07-26, b3_trading_enabled_
    -- drift 2026-08-03) were each closed manually in a later interactive triage session, days after the
    -- change they announced had completed. SAFER TO AGE OUT THAN ANY OTHER ENTRY ON THIS LIST: a promotion
    -- is idempotent by construction (ops.monitor_promotion_log makes the readiness view's
    -- not_already_promoted FALSE forever after), so unlike every self-healing class above there is no
    -- underlying condition that could still be true and no re-raise to rely on -- the row is a receipt for
    -- something already done, and aging it can hide nothing. The promotion itself stays permanently
    -- queryable in ops.monitor_promotion_log and events.decision_log (entry_type='monitor-promotion'),
    -- which are the durable records; ops.alerts is only the announcement.
    AND category IN ('instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing', 'immediate_action_flagged', 'process_scorecard_signal', 'scheduled_query_stale', 'ci_findings_bridge_stale', 'control_plane_insert', 'scheduled_query_version_drift', 'script_version_drift', 'queue_driven_silent', 'run_log_note_missing', 'run_log_start_row_missing', 'connector', 'strategy_revised', 'connector_tool_inventory_stale', 'account_snapshot_gap', 'trigger_drift_corrected', 'monitor_promoted')
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

  -- queue_driven_silent (warning) — a queue_driven routine has logged no completed run for longer
  -- than any gap in its own history. THIS IS THE ONLY NET THAT COVERS THEM: monitor_class
  -- queue_driven is excluded from state.cadence_expected_today, which BOTH state.cadence_watch and
  -- state.cadence_period_watch are built on, so AR_att/AR_orc/SL2/SL5 have never had a cadence
  -- signal of any kind. Measured 2026-08-03: SL2 and SL5 went dark after 2026-07-30 when their
  -- triggers were disabled, and NOTHING alerted on the silence — the only surfacing was D3's
  -- queue_item_stale, a downstream symptom whose own text had to flag the root cause as INFERRED
  -- because it could not verify it.
  --
  -- WARNING, deliberately NOT critical, and it must stay that way. state.trading_enabled ANDs
  -- `blocking_criticals = 0`, so a critical here would HALT ORDER STAGING every time a SISA
  -- lifecycle routine went quiet. That is exactly the failure mode of the 2026-08-01..03 incident
  -- this file's sibling (bigquery/130) exists to prevent; do not promote this category.
  --
  -- Record-only, like instruction_drift: does NOT append to raise_msg and so does not contribute to
  -- the DTS failure-email RAISE. Auto-ages after 7d via the allowlist above and re-raises on the
  -- next run while the condition persists.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'queue_driven_silent',
      CONCAT('Queue-driven routine(s) silent past threshold — these sit OUTSIDE the cadence nets, so a disabled or dead trigger here produces no other signal. Check the trigger is enabled in claude.ai before assuming an empty queue: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, last_run_date, days_silent,
                                              silence_threshold_days, never_completed) ORDER BY routine))
       FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent));
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

  -- run_log_note_missing (audit of the 2026-08-07 daily runs) — a routine logged a TERMINAL row
  -- (completed/failed/halted) carrying NO note, so the run left no account of itself. ops.run_log.note is
  -- the ONLY durable narrative record of what a routine decided and why: the routine's own reasoning is
  -- otherwise unrecoverable once the session ends. MEASURED before shipping this check, over the trailing
  -- 30 days: 8 terminal rows of 368 (~0.27/day) — rare enough that each firing means something, which is
  -- why this is scoped to the note gap and NOT extended to a missing `instruction`. An absent instruction
  -- looks similar but is NOT the same signal: 322 of 324 completed rows legitimately carry no instruction
  -- (it belongs on the paired 'started' row), and 46 of 330 'started' rows lack one, so alarming on it
  -- would fire ~14% of the time and train the operator to ignore this category.
  --
  -- WHY IT MATTERS, from the run that prompted it: D2/2026-08-07 logged completed with note NULL, ran
  -- 5m34s against a 12-22min norm, and logged rows_written=5 while writing exactly ONE BigQuery row —
  -- the other 4 were Watchlist.md ticker edits counted as though they were rows. The work itself was
  -- substantively correct (its decision_log entry and commit 77c8c85 both check out), so nothing was
  -- broken; but an abbreviated run left no explanation of itself and no monitor noticed, because nothing
  -- in this stack has ever read run_log.note or rows_written. This is that reader.
  --
  -- RECORD-ONLY (no raise_msg join), deliberately: a missing note is an audit-hygiene defect, not a
  -- reason to fail the nightly check or halt anything. It is also NOT REPAIRABLE after the fact — the row
  -- is history and ops.run_log is not rewritten — so the category is in the #14 auto-age allowlist above
  -- and closes itself once the 3-day view window rolls past the offending row.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.run_log_content_gaps`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'run_log_note_missing',
      -- DEDUP-CRITICAL — the message is a FIXED STRING and must stay one. sp_raise_alert_once dedups on
      -- exact (category, message) while the prior row is unresolved, so ANY per-row detail here (the
      -- routine/date list, or even a count) changes the text every time the 3-day window's membership
      -- shifts — a gap entering OR an older one aging out — and opens a NEW row each time instead of
      -- collapsing onto one. Walked against the real 30-day history, an aggregated message would have
      -- produced 6 distinct open rows for the 4 gaps between 07-08 and 07-18. Same convention as the
      -- trigger_missing / calendar_runway_low / probe_funding_stalled / scheduled_query_stale blocks
      -- in this procedure: identity in the message, detail in the payload only.
      'Terminal run_log row(s) with no note in the trailing 3 days — a routine logged completed/failed/halted without recording what it did. See payload for the affected routine/run_date rows.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, status, run_id)))
       FROM `stock-trading-498512.state.run_log_content_gaps`));
  END IF;

  -- run_log_start_row_missing — a routine logged a TERMINAL row for a run_date with no paired
  -- 'started' row. Sibling of run_log_note_missing above and deliberately the same shape: record-only
  -- (no raise_msg join), fixed message, detail in the payload, 3-day window, #14 auto-age allowlist.
  --
  -- WHAT IT CATCHES that nothing else did. state.stalled_runs is the mirror check — started with no
  -- terminal — and ops.run_log has no key linking the two rows (run_id is GENERATE_UUID() per INSERT;
  -- the pair is only (routine, run_date)), so a terminal row whose start was never logged was covered
  -- by no monitor at all. It matters because the 'started' row is where `instruction` lives: without
  -- it state.routine_last_instruction has no sample for that run, so state.instruction_drift is blind
  -- to a drifted web-UI trigger for exactly that day, and state.stalled_runs can never see the run.
  --
  -- MEASURED over the trailing 120 days before shipping: 2 firings, both on 2026-07-18 (SL2 and D3,
  -- both 'halted'), i.e. ~0.017/day. That is an order of magnitude quieter than run_log_note_missing
  -- was at its own ship date (~0.27/day), so it clears the bar this file's v13 note sets: a check that
  -- fires often enough to be ignored is worse than no check.
  --
  -- TWO EXCLUSIONS, both load-bearing — WITHOUT THEM this fires 12 times instead of 2, and the noise
  -- would be entirely false positives:
  --   * FIRE_DRILL% / SELFHEAL_RUN_LOG call ops.sp_log_run DIRECTLY and never call sp_routine_start.
  --     They are procedures recording that they fired, not sessions with a start. 30 such rows in 120d.
  --   * Rows written by ops.sp_backfill_run_log_from_markers (RUNBOOK §38 self-heal) reconstruct a
  --     COMPLETED row from a git commit marker for a run that never logged anything — so a missing
  --     'started' row is the PREMISE of that mechanism, not a defect in it. Matched on the same
  --     '^(auto-)?backfilled' prefix bigquery/89 already anchors on; keep the two in step if either
  --     changes. These accounted for every one of the 9 apparent D1 cases in the raw 120-day count.
  --
  -- The routine-id comparison is separator-normalised, matching state.instruction_drift and
  -- state.routine_catchup_window, so the legacy middle-dot ids (AR·att/AR·orc, written 2026-06-19..
  -- 2026-07-01) fold onto their ASCII form instead of pairing a terminal row against nothing.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.run_log_unpaired_terminal`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'run_log_start_row_missing',
      -- DEDUP-CRITICAL — fixed string, same convention and same reason as the run_log_note_missing
      -- block directly above: per-row detail here would open a new alert row every time the 3-day
      -- window's membership shifts, instead of collapsing onto one.
      'Terminal run_log row(s) with no paired started row in the trailing 3 days — a routine logged completed/failed/halted for a run_date it never logged a start for. See payload for the affected routine/run_date rows.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, status, run_id)))
       FROM `stock-trading-498512.state.run_log_unpaired_terminal`));
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
      'critical', 'scheduled.cadence', 'b3_trading_enabled_drift',
      (SELECT CONCAT('state.trading_enabled formula drift: live=', CAST(live_value AS STRING),
                     ' but independently-recomputed expected=', CAST(expected_value AS STRING),
                     ' -- a gate AND-term may have been silently clobbered (see bigquery/47_trading_enabled_resync.sql)')
       FROM `stock-trading-498512.state.b3_trading_enabled_check`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.b3_trading_enabled_check` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[b3_trading_enabled_drift] live=', CAST(live_value AS STRING),
      ' expected=', CAST(expected_value AS STRING), '; ') FROM `stock-trading-498512.state.b3_trading_enabled_check`);
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
             (SELECT STRING_AGG(CONCAT(dataset, '.', table_name), ', ' ORDER BY dataset, table_name)
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

  -- process_constant_evidence_invalidated (warning, bigquery/142_cadence_deadline_revert_and_evidence_
  -- drift.sql, 2026-08-06). state.process_constant_evidence_drift re-validates an ALREADY-APPLIED W5
  -- process_reliability autotune against the metric-view predicate set its justification depended on,
  -- recomputed as of TODAY — closing a gap state.process_constant_oos_watch (bigquery/72) structurally
  -- cannot reach: that fail-safe only detects that the change did not work (a persisted POST-change
  -- threat); this detects that the evidence was never real (a persisted PRE-change threat manufactured
  -- by a metric formula later corrected — see bigquery/89, 2026-08-04, backfilled-row exclusion, which
  -- is exactly what happened to the D1 2026-08-03 cadence_watch_deadline_local autotune; see bigquery/142
  -- header for the full account). Record-only, like instruction_drift/ddl_drift/ci_finding above: does
  -- NOT join raise_msg (an invalidated-evidence finding needs human adjudication — re-read the view,
  -- decide whether to revert the constant or accept the change on other grounds — it is not a same-night
  -- trading halt). Deliberately ABSENT from the #14 auto-age allowlist above: unlike a self-healing
  -- transient, a genuinely invalidated evidence trail does not become false again on its own, so this must
  -- stay open until a human closes it by hand — see ops.alert_policy.resolve_rule for this category
  -- (bigquery/142).
  -- BEST-EFFORT GUARD, same pattern this procedure already applies to sp_backfill_run_log_from_markers
  -- and sp_auto_resolve_alerts above. BigQuery binds a procedure's referenced objects LAZILY, at CALL
  -- time rather than CREATE time, so applying this v12 body BEFORE bigquery/142's Statement 2 would not
  -- fail on creation — it would abort the NEXT nightly run mid-body with `Not found:
  -- state.process_constant_evidence_drift`, silently killing every check BELOW this point
  -- (scheduled_query_stale, probe_funding_stalled, cash_flows_backfill_broken, ci_finding,
  -- ci_findings_bridge_stale, constant_tuning_loop_heartbeat_missing, park_allocator heartbeat) for that
  -- run and every run after. Applying the file top to bottom makes that impossible, but a partial or
  -- reordered apply must never be able to take down the fleet's dead-man switch over one advisory check.
  BEGIN
    IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated) THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.cadence', 'process_constant_evidence_invalidated',
        CONCAT('Process-constant autotune evidence INVALIDATED by a later metric-formula correction — ',
               '90-day trailing p90 completion-minute-of-day; see payload for the persisted vs recomputed threat streaks: ',
               (SELECT STRING_AGG(
                  CONCAT(routine, '/', deadline_key, ' change ', old_value, '->', new_value),
                  '; ' ORDER BY routine)
                FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated)),
        (SELECT TO_JSON_STRING(ARRAY_AGG(t))
         FROM `stock-trading-498512.state.process_constant_evidence_drift` t WHERE evidence_invalidated));
    END IF;
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

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

  -- Connector tool-inventory staleness (2026-08-08, bigquery/151_connector_tool_inventory.sql).
  -- OPS1's TOOL-INVENTORY DRIFT CHECK diffs the live per-connector tool roster against
  -- ops/connector_tools.yaml so a vendor-added tool -- which arrives as ask/needs-approval in the
  -- claude.ai connectors UI and would silently stall an unattended routine that calls it -- is caught
  -- the morning it appears. That check is SELF-REPORTED, and a self-reported check cannot detect its
  -- own omission: OPS1 could complete normally, log a clean note, and simply never have run the step
  -- (prompt drift, a skipped sub-agent, a truncated session). This block is the independent witness.
  -- It reads only the observation table's recency, so it stays true regardless of what OPS1 claims.
  -- RECORD-ONLY, WARNING, self-healing: once OPS1 resumes a trustworthy sweep the underlying condition
  -- clears on its own, so this category is in the #14 auto-age allowlist above (it has no ops.alert_
  -- policy row) rather than getting its own resolve-on-heal UPDATE, matching the connector /
  -- strategy_revised / script_version_drift convention this file already uses.
  -- DEDUP-CRITICAL: the message lists ONLY the affected connector names (stable while the stale set
  -- itself is stable, matching the trigger_missing / probe_funding_stalled / scheduled_query_stale
  -- convention elsewhere in this procedure) -- days_stale changes daily while a connector stays stale
  -- and lives in the payload only, per the exact bug this file's own #14 comment records for
  -- trigger_missing ("its message used to embed a daily-changing day-count, defeating
  -- sp_raise_alert_once's dedup").
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.connector_tool_inventory_stale`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'connector_tool_inventory_stale',
      CONCAT('Connector tool-inventory observations are stale for: ',
             (SELECT STRING_AGG(connector, ', ' ORDER BY connector)
              FROM `stock-trading-498512.state.connector_tool_inventory_stale`),
             '. OPS1 completed without recording a trustworthy tool sweep, so the morning clean bill of health for connector tool drift is void. See payload for per-connector day counts.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(connector, last_good_run_date, days_stale) ORDER BY connector))
       FROM `stock-trading-498512.state.connector_tool_inventory_stale`));
  END IF;

  -- Account-snapshot gap watch (2026-08-08, bigquery/153_account_snapshot_gap_watch.sql). ops.
  -- account_snapshot holds one measured NAV/cash row per snapshot_date, written by D2a Step 0b for a
  -- single day per run -- there is no loop, so a trading day D2a does not run on is missing until it is
  -- explicitly backfilled (2026-07-23/24, the two days that prompted this file, were backfilled
  -- 2026-08-09 and the view is empty again). state.book_drawdown_watch's flow-adjusted peak_gain (bigquery/78) is a running MAX over
  -- whatever snapshot_date rows exist, so a missing day's NAV never enters that max -- if the gap day
  -- was a peak, peak_gain (and therefore peak_nav) is PERMANENTLY UNDERSTATED, and the -15% soft /
  -- -40% hard drawdown breaker under-triggers -- the fail-dangerous direction. snapshot_stale
  -- (bigquery/78) only catches a missing TODAY; it is structurally blind to a historical gap. BACKFILL
  -- IS POSSIBLE (v18, 2026-08-09 -- this REPLACES the v17 claim that it was impossible and must not be
  -- attempted). get_pa_performance_all_periods returns parallel dates[]/nav[] arrays per period, about a
  -- year of daily NAV, and D2a Step 0b already calls it but keeps only the last element. The v17 claim
  -- came from over-generalising events.cash_flows' 2026-08-05 deposit note, which correctly records that
  -- IBKR has no cash-transaction/statement ITEMISATION endpoint -- a different, narrower thing. Only nav
  -- is recoverable this way; cash/TWR columns are absent from that response and must stay NULL. This
  -- block is DETECTION plus a RECOVERY POINTER: a record-only WARNING naming every trading day between
  -- the first and last
  -- ops.account_snapshot row that has no row of its own (state.account_snapshot_gap,
  -- bigquery/153_account_snapshot_gap_watch.sql). RECORD-ONLY, WARNING, NEVER a halt -- does NOT join
  -- raise_msg, and bigquery/153's redefinition of state.book_drawdown_watch adds an OBSERVABILITY-ONLY
  -- peak_window_gap_days column with no new gate term, so state.trading_enabled behaves exactly as it
  -- did before this file. SELF-HEALING SHAPE for auto-age purposes, now genuinely
  -- so rather than only nominally (a gap day is no longer permanent): the check re-evaluates state.account_snapshot_gap fresh every run and simply re-raises
  -- (same stable message, deduped) for as long as it is non-empty, exactly like connector_tool_
  -- inventory_stale above -- it has no ops.alert_policy row, so it rides the #14 auto-age allowlist
  -- below (added alongside connector / strategy_revised / connector_tool_inventory_stale) rather than
  -- sitting open forever once raised.
  -- DEDUP-CRITICAL: the message lists ONLY the gap dates -- stable while the gap set is stable, which
  -- it is except when a NEW day goes missing. NOTE (v18): the set CAN now shrink, because gap days are
  -- backfillable (see this file's header); a shrink changes the message and therefore starts a NEW
  -- alert row rather than deduping onto the old one -- harmless, since the usual shrink is to empty,
  -- which raises nothing at all. Day counts and the surrounding prior/next NAV context live in the payload
  -- only, per the trigger_missing / probe_funding_stalled / connector_tool_inventory_stale convention
  -- elsewhere in this procedure.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.account_snapshot_gap`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'account_snapshot_gap',
      CONCAT('ops.account_snapshot is missing a snapshot on trading day(s) that D2a never wrote -- the flow-adjusted peak in state.book_drawdown_watch may be understated until they are filled. THESE ARE RECOVERABLE: IBKR get_pa_performance_all_periods returns parallel dates[]/nav[] arrays (1M/YTD/1Y) covering roughly a year, so the missing nav can be read straight out of the endpoint D2a Step 0b already calls -- insert with source=ibkr-pa-history-backfill and leave cash/TWR columns NULL (they are not in that response). Gap day(s): ',
             (SELECT STRING_AGG(CAST(gap_date AS STRING), ', ' ORDER BY gap_date)
              FROM `stock-trading-498512.state.account_snapshot_gap`),
             '. See payload for per-gap surrounding NAV context.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(gap_date, prior_snapshot_date, prior_nav, next_snapshot_date, next_nav) ORDER BY gap_date))
       FROM `stock-trading-498512.state.account_snapshot_gap`));
  END IF;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;
-- ===== (5) state.entry_staging_allowed — canonical body from bigquery/78, block_reason stabilised =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.entry_staging_allowed` AS
WITH bdw AS (SELECT breach_soft, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`),
ocl AS (SELECT entries_halted, trading_days_since_last_fill, n_pending_instructions FROM `stock-trading-498512.state.owner_confirmation_liveness`)
SELECT
  (NOT COALESCE(bdw.breach_soft, TRUE) AND NOT COALESCE(ocl.entries_halted, TRUE)) AS entries_allowed,
  COALESCE(bdw.breach_soft, FALSE) AS book_drawdown_soft_breach,
  COALESCE(ocl.entries_halted, FALSE) AS owner_confirmation_entries_halted,
  CASE
    WHEN COALESCE(bdw.breach_soft, TRUE) THEN
      'book_drawdown_soft_breach: NAV below flow-adjusted peak exceeds the -15% soft threshold — NEW-entry staging paused; exits / kill-trigger terminations / park cover UNAFFECTED (see state.book_drawdown_watch.drawdown_from_peak for the live figure)'
    WHEN COALESCE(ocl.entries_halted, TRUE) THEN
      FORMAT('owner_confirmation_stale: %d pending instruction(s), %d trading day(s) since last fill — NEW-entry staging paused (76)', ocl.n_pending_instructions, ocl.trading_days_since_last_fill)
    ELSE NULL
  END AS block_reason
FROM bdw, ocl;
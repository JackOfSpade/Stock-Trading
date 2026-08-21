-- ===== 194: safety-critical DML watch v5 -- a zero-row INSERT is not a control-plane change =====
-- (2026-08-21, alert triage of the live WARNING control_plane_insert row 675c4542.)
--
-- SUPERSEDES the ops.sp_sq_safety_critical_dml_watch definition in
-- bigquery/75_scheduled_query_wrappers.sql (SQ_VERSION v4). Chain: 75 (v2/v3/v4) -> 194 (v5).
-- The original file-level header, rationale and scope notes remain in
-- bigquery/scheduled_queries/safety_critical_dml_watch.sql and in bigquery/75's banner -- read those
-- first; only the delta is described here.
--
-- WHAT TRIGGERED THIS. On 2026-08-21 the WARNING control_plane_insert lane raised alert 675c4542
-- naming THREE events.strategy_lifecycle INSERT jobs (03:26:47, 03:37:19, 04:05:59 UTC). Investigated
-- against INFORMATION_SCHEMA.JOBS_BY_PROJECT.dml_statistics:
--   * 03:26:47 -- inserted_row_count = 1. The sanctioned provenance repair from bigquery/190: candidate
--     H's missing NULL->CANDIDATE creation row, reconstructed at its true event_ts 2026-08-03
--     22:11:04+00 so it precedes SL1's CANDIDATE->REJECTED row (22:11:05) and the audit trail is
--     coherent again. Verified live: H now has exactly those two rows, ending REJECTED -- H is NOT in
--     the roster, and no roster membership changed.
--   * 03:37:19 -- inserted_row_count = 0, query text 'idempotency probe -- must never land'.
--   * 04:05:59 -- inserted_row_count = 0, query text 'correlated-guard idempotency probe -- must never
--     land'.
-- So two thirds of the alert's evidence was jobs that changed nothing, and the one real row was an
-- already-reviewed, already-landed repair. No unsanctioned mutation, no security event.
--
-- THE DEFECT THIS FIXES. The control_inserts CTE keyed on the EXISTENCE of a DONE INSERT job, never on
-- whether the job wrote anything. v5 filters on dml_statistics.inserted_row_count, fail-loud on a NULL
-- statistic. See the inline comment on that predicate for the full reasoning, the fail direction, and
-- why the two CRITICAL lanes are strengthened rather than weakened by it.
--
-- DELIBERATELY UNCHANGED: the mutation-class watch (UPDATE/DELETE/MERGE/TRUNCATE -> CRITICAL, with the
-- sp_recompute_engine WHERE-TRUE exception), CRITICAL 1 (spoofed manual halt-clear), CRITICAL 2
-- (unknown-code lifecycle insert), the v4 per-target-table watermark, the single consolidated RAISE,
-- and the 4-table scope. Only the WARNING lane's input set narrows, plus inserted_rows is added to its
-- payload so the next confirming read starts from the row count instead of re-deriving it by hand.
--
-- APPLY: live via the BigQuery MCP (CREATE OR REPLACE PROCEDURE, idempotent), together with
-- bigquery/63's registry seed row bumped v4 -> v5 in the same unit of work
-- (scripts/check_sq_version_registry.py is a blocking CI gate on that pairing).

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_safety_critical_dml_watch`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';   -- H4: accumulate so all conditions RECORD before one final RAISE
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:safety_critical_dml_watch', 'v5', 'safety_critical_dml_watch.sql ran');

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
    creation_time,
    dml_statistics.inserted_row_count AS inserted_rows
  FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND state = 'DONE'
    AND error_result IS NULL
    AND statement_type = 'INSERT'
    -- ZERO-ROW INSERT SUPPRESSION (v5, 2026-08-21). A guarded idempotent INSERT
    -- (INSERT ... SELECT ... WHERE NOT EXISTS) that matches nothing still completes as a DONE INSERT
    -- job with no error, and was therefore indistinguishable here from a real control-plane change --
    -- but it mutated NOTHING, so by definition it is not one. Observed live: alert 675c4542
    -- (2026-08-21) carried three events.strategy_lifecycle INSERT jobs of which only ONE wrote a row
    -- (the sanctioned bigquery/190 provenance repair of candidate H's creation row); the other two were
    -- the repair's own idempotency probes, whose query text literally reads 'must never land' and whose
    -- inserted_row_count is 0. Flagging a no-op as a control-plane change is the same crying-wolf
    -- failure the v4 watermark fix was written to stop ("trains the operator to ignore exactly the
    -- alert class that escalates to CRITICAL above"), and the repo has since institutionalised guarded
    -- INSERT + probe pairs on these tables, so it would recur on every future repair.
    -- COALESCE(..., 1) is the FAIL-LOUD direction: dml_statistics is populated for query-issued DML,
    -- but if it is ever absent/NULL the job is treated as a real insert and still alerts. A missing
    -- statistic must never silently drop a genuine control-plane INSERT from a safety watch.
    -- The two CRITICAL conditions below read this same set; that is correct and slightly strengthens
    -- them -- a job that wrote zero rows cannot have created a spoofed halt-clear row or an
    -- unknown-code lifecycle row, and each CRITICAL independently re-checks the TABLE's own rows.
    AND COALESCE(dml_statistics.inserted_row_count, 1) > 0
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
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, target_dataset, target_table, creation_time, inserted_rows) ORDER BY creation_time))
       FROM new_control_inserts));
  END IF;

  -- Single consolidated RAISE — fires the DTS failure-email once, AFTER every CRITICAL above is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING safety-critical DML/INSERT watch FAILED — ', raise_msg,
      'See ops.alerts (source=scheduled.safety_critical_dml) for job_id/user_email detail.');
  END IF;
END;

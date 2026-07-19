-- Catchup-refire-blocked alert policy: formalizes the ad-hoc 'catchup_refire_blocked' warning OPS0
-- raised on 2026-07-18 (alert eadf89c4-185d-4bec-be19-38652d1d4adb, miss_key 'D3|2026-07-18') when
-- the RemoteTrigger tool was absent from its session and it could not attempt D3's auto-refire.
-- Project: stock-trading-498512. Root cause (every routine trigger's allowed_tools missing
-- RemoteTrigger) identified 2026-07-19; the fix itself (adding RemoteTrigger to every routine
-- trigger's allowed_tools) is owner-gated -- interactive RemoteTrigger update calls are
-- classifier-blocked, so it needs the owner or an owner-approved session -- see OWNER_ACTIONS.md's
-- 2026-07-19 item. This file is the durable policy row + mechanical resolution rule + procedure-
-- side implementation for that incident category, and a repo-catchup fix for an unrelated stale
-- seed text (see below).
--
-- SUPERSEDES the ops.sp_auto_resolve_alerts definition in bigquery/78_book_drawdown_rebase_and_staleness_gate.sql
-- (which superseded bigquery/34). Every OTHER object in bigquery/78 is UNCHANGED and remains
-- canonical there.
--
-- Apply after bigquery/78. Apply the whole file live via the BigQuery MCP (execute_sql), same
-- apply-in-order discipline as bigquery/01..NN.

-- ===== ops.alert_policy — seed the catchup_refire_blocked row (guarded insert, one row; matches =====
-- ===== bigquery/34:57-72's INSERT ... SELECT ... FROM UNNEST([STRUCT(...)]) WHERE NOT EXISTS idiom, =====
-- ===== scoped to this one category since the table is already populated with other categories =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('catchup_refire_blocked' AS category, FALSE AS latching,
    'the payload routine has a completed ops.run_log row with run_date >= the date part of miss_key (a later completed run supersedes the miss for catchup-safe routines), OR an ops.catchup_refire_log row exists for the exact miss_key (refire attempted or trigger self-registered), OR the alert is >1 calendar day old America/Denver (nightly OPS0 sweeps re-raise while the blockage persists, so age-out cannot hide an ongoing condition)' AS resolve_rule,
    'seeded 2026-07-19 after the 2026-07-18 blocked-refire incident (D3|2026-07-18): OPS0 could not call RemoteTrigger (tool absent from session allowed_tools); root-cause fix (adding RemoteTrigger to every routine trigger allowed_tools) is owner-gated - see OWNER_ACTIONS.md 2026-07-19 item; rule implemented in bigquery/94 (sp_auto_resolve_alerts)' AS note)
])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` WHERE category = 'catchup_refire_blocked'
);

-- ===== ops.alert_policy — repo catch-up for the staleness row (documentation only; the live row =====
-- was edited LIVE-ONLY on 2026-07-09, RUNBOOK section 38 era, adding the trading_halted exclusion
-- to resolve_rule/note; the repo seed text in bigquery/34 was never updated to match. This UPDATE
-- reproduces the live text here so a DR rebuild starts from the actual live row instead of the
-- stale 2026-07-07 seed. Applying it live is a deliberate no-op: the WHERE clause's
-- `resolve_rule != <live text>` guard means it only ever matches if the live row has drifted from
-- what is spliced below, which it has not as of the 2026-07-19 read this was copied from.
UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = 'state.freshness.marks_fresh AND engine_fresh, state.embedding_health.is_healthy, NOT state.position_reconciliation drift, and zero OTHER open criticals (excluding this alert\'s own category AND trading_halted, mirroring the two trading_enabled gate views\' exclusion -- fixed 2026-07-09, RUNBOOK section 38) are all currently true',
    note = 'seeded 2026-07-07, self-improvement audit WP2; self-referential like the trading_halted gate-exclusion below, so it is resolved by live re-check, not by an ops.run_log lookback | 2026-07-09: resolve_rule text updated to reflect the trading_halted exclusion added to the live procedure (RUNBOOK section 38).',
    updated_ts = updated_ts
WHERE category = 'staleness'
  AND resolve_rule != 'state.freshness.marks_fresh AND engine_fresh, state.embedding_health.is_healthy, NOT state.position_reconciliation drift, and zero OTHER open criticals (excluding this alert\'s own category AND trading_halted, mirroring the two trading_enabled gate views\' exclusion -- fixed 2026-07-09, RUNBOOK section 38) are all currently true';

-- ===== ops.sp_auto_resolve_alerts — adds Rule 3b (catchup_refire_blocked); SUPERSEDES bigquery/78 =====
-- (which superseded bigquery/34). Rules 1, 2, 3, and 4 below are byte-identical to bigquery/78's
-- committed body. The only changes are the DECLARE line (extended with eligible_refire_blocked)
-- and the new Rule 3b block inserted between Rule 3's UPDATE and Rule 4's no_other_criticals setup.
--
-- SUPERSEDED (2026-07-19): this definition of ops.sp_auto_resolve_alerts is now superseded by
-- bigquery/97_halt_echo_dependency_gate.sql, which reproduces this exact procedure body (Rules 1,
-- 2, 3, 3b and 4) and additionally excludes halt-echo missing_dependency alerts (pure same-day
-- fallout of a still-open trading halt) from Rule 4's no_other_criticals count. Re-applying the
-- CREATE OR REPLACE PROCEDURE below live in isolation would REGRESS that halt-echo exclusion.
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE OR REPLACE PROCEDURE statement live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`()
BEGIN
  DECLARE eligible_dep, eligible_run, eligible_stalled, eligible_stale, eligible_refire_blocked ARRAY<STRING>;
  DECLARE live_would_clear BOOL;
  DECLARE no_other_criticals BOOL;

  -- Rule 1: missing_dependency.
  SET eligible_dep = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
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
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: dependency satisfied or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_dep, []));

  -- Rule 2: missed_run.
  SET eligible_run = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
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
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: named routine(s) since completed or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_run, []));

  -- Rule 3: routine_stalled.
  SET eligible_stalled = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
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
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: stalled run(s) since reached a terminal status, or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stalled, []));

  -- Rule 3b — catchup_refire_blocked (WARNING, raised by OPS0 STEP 2 when the RemoteTrigger
  -- tool is absent from its session): resolves when the miss recovered (the payload routine
  -- has a completed run_log row with run_date >= the date part of miss_key — a later
  -- completed run supersedes the miss for catchup-safe routines), OR a refire attempt was
  -- durably logged for the exact miss_key, OR the alert itself is >1 calendar day old
  -- (nightly OPS0 sweeps re-raise while the blockage persists, so age-out cannot hide an
  -- ongoing condition). Payload is a flat JSON object (see 2026-07-18 incident alert).
  SET eligible_refire_blocked = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a
      LEFT JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = JSON_VALUE(a.payload, '$.routine')
           AND r.status = 'completed'
           AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', SPLIT(JSON_VALUE(a.payload, '$.miss_key'), '|')[SAFE_OFFSET(1)])
      LEFT JOIN `stock-trading-498512.ops.catchup_refire_log` l
        ON l.miss_key = JSON_VALUE(a.payload, '$.miss_key')
      WHERE NOT a.resolved AND a.category = 'catchup_refire_blocked'
        AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      GROUP BY a.alert_id, a.alert_ts
      HAVING LOGICAL_OR(r.routine IS NOT NULL)
          OR LOGICAL_OR(l.miss_key IS NOT NULL)
          OR DATE(a.alert_ts, 'America/Denver') < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: miss recovered by a later completed run, refire attempt logged for the miss_key, or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_refire_blocked, []));

  -- Rule 4: staleness — strict live-recheck OR pure-echo (payload-aware). Both require that no OTHER
  -- critical (excluding staleness/trading_halted) remains open. Computed as independent variables
  -- first to avoid the self-reference de-correlation restriction documented in 34.
  SET no_other_criticals = (
    (SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('staleness', 'trading_halted')) FROM `stock-trading-498512.ops.alerts`) = 0
  );
  SET live_would_clear = (
    SELECT f.marks_fresh AND f.engine_fresh AND eh.is_healthy
      AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
    FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh
  );
  SET eligible_stale = (
    SELECT ARRAY_AGG(alert_id)
    FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved AND category = 'staleness'
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND COALESCE(no_other_criticals, FALSE)
      AND (
        COALESCE(live_would_clear, FALSE)                                    -- strict: genuinely stale at raise, now healed
        OR (JSON_VALUE(payload, '$.marks_fresh') = 'true'                    -- echo: freshness was already green at raise time
            AND JSON_VALUE(payload, '$.engine_fresh') = 'true')
      )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: freshness verified green (or payload shows it was green at raise — pure alert-on-alert echo), no other open critical (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stale, []));
END;

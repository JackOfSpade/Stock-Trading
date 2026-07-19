-- Halt-echo dependency-gate exclusion (2026-07-19): missing_dependency criticals that are pure
-- same-day fallout of a still-open trading halt no longer count as blocking criticals in the
-- trading-enable gate cluster. Project: stock-trading-498512. Apply AFTER
-- 78_book_drawdown_rebase_and_staleness_gate.sql and 94_catchup_refire_blocked_policy.sql.
-- This file is the NEW single source of truth for state.trading_enabled,
-- state.trading_enabled_mechanical, state.b3_trading_enabled_check and ops.sp_auto_resolve_alerts;
-- it SUPERSEDES the three view definitions in bigquery/78_book_drawdown_rebase_and_staleness_gate.sql
-- and the ops.sp_auto_resolve_alerts definition in bigquery/94_catchup_refire_blocked_policy.sql
-- (94 had superseded 78's procedure, which superseded 34's). Per 47's header rule, any future change
-- to this gate cluster must land as a NEW numbered file that supersedes THIS one — never re-apply an
-- earlier file's CREATE OR REPLACE for these objects in isolation.
--
-- ============================ WHY (the 2026-07-19 deadlock) ============================
-- W5's critical missing_dependency alert 46dcc5fd fired because its dependency W4 had not completed —
-- W4 was HALTED by a still-open trading_halted alert (source = W4, same Denver day). Both trading
-- gates counted that missing_dependency alert as a blocking critical, so the gates stayed FALSE.
-- But sp_auto_resolve_alerts Rule 1's ONLY heal for a missing_dependency alert is the named dep
-- completing (a run_log 'completed' row with run_date >= the alert's run_date) — i.e. W4 completing,
-- which the alert itself blocks by holding the gates closed. A circular deadlock: the echo of the
-- halt outlives every legitimate reason to block, resolvable only by Rule 1's >1-day age-out or a
-- human. The missing_dependency alert carries ZERO information the gates don't already have — the
-- halt itself is category='trading_halted', which the gates have excluded since bigquery/34 for
-- exactly this alert-on-alert reason (and 'staleness' since 78). Excluding the halt's
-- missing_dependency ECHOES — and only those — removes no real protection and breaks the circle.
--
-- ============================ THE FAIL-CLOSED PREDICATE ============================
-- An open critical missing_dependency alert is a "halt-echo" IFF EVERY routine named in its
-- payload.missing_deps has an OPEN (NOT resolved) trading_halted alert (ops.alerts.source = dep)
-- whose DATE(alert_ts,'America/Denver') equals SAFE.PARSE_DATE('%Y-%m-%d', payload.run_date).
-- Fail-closed: a NULL/malformed payload, an empty missing_deps, an unparseable run_date, or ANY
-- dep without a matching open same-day trading_halted alert means NOT an echo — the alert still
-- blocks, exactly as today. Only the unambiguous every-dep-halted-today case is excluded.
--
-- !! Do NOT widen the predicate to RESOLVED trading_halted alerts — that would be FAIL-OPEN: a
-- healed halt's stale missing_dependency echo would stop blocking even though the dep never ran,
-- silently un-gating on a condition nobody re-verified. The predicate must stay OPEN-halt-only.
--
-- ============================ ACCEPTED LIMITATIONS (adversarial review 2026-07-19) ============================
-- Both degrade to the STATUS-QUO blocking behaviour (fail-closed), never to fail-open:
--   (i)  sp_raise_alert_once dedups trading_halted on exact message, so only the FIRST-halted
--        routine per episode gets a trading_halted row, and a halt spanning Denver midnight has no
--        day-2 trading_halted row at all. Echo relief therefore reaches only that first routine's
--        downstreams, on the same Denver day. Day-2 deadlocks re-form and age out via Rule 1's
--        >1-day fallback — the pre-97 behaviour, no worse.
--   (ii) While a same-day trading_halted alert stays open (it is human-latching), a dep that
--        re-runs and fails for a NEW, unrelated reason keeps its missing_dependency echo suppressed
--        until the halt is cleared or Denver midnight passes. Backstopped by the ~23:15 MT cadence
--        watchdog's missed_run, which is not suppressed by this exclusion.

-- ===== state.trading_enabled — REDEFINED (SUPERSEDES bigquery/78) =====
-- Sole change vs 78: blocking_criticals additionally excludes halt-echo missing_dependency alerts
-- (halt_echo_md CTE below), and the blocking-criticals halt_reason branch names the new exclusion.
-- Everything else byte-identical to 78's committed body.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, drawdown_from_peak, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND COALESCE(eh.is_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.breach_hard, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN NOT COALESCE(eh.is_healthy, FALSE) THEN
      'state.embedding_health.is_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo-dependency gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt); the -15%% soft tier pauses new entries only', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot not refreshed for the current trading day — the breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, eh, al, pr, dd;

-- ===== state.trading_enabled_mechanical — REDEFINED (SUPERSEDES bigquery/78) =====
-- Same sole change as state.trading_enabled above (halt_echo_md exclusion + halt_reason wording).
-- Still deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-circular term, per 33's
-- header). Everything else byte-identical to 78's committed body.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled_mechanical` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (
  SELECT embeddings_healthy, position_drift_detected
  FROM `stock-trading-498512.state.system_health`
),
halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
dd AS (SELECT breach_hard, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.embeddings_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.breach_hard, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.embeddings_healthy, FALSE) THEN
      'state.system_health.embeddings_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo-dependency gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt)', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd;

-- ===== state.b3_trading_enabled_check — REDEFINED (SUPERSEDES bigquery/78) =====
-- The live formula self-check must track the gate it mirrors, or it false-fires drift. Updated to
-- carry the same halt_echo_md exclusion in its blocking-criticals recomputation. Everything else
-- byte-identical to 78's committed body.
CREATE OR REPLACE VIEW `stock-trading-498512.state.b3_trading_enabled_check` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`),
expected AS (
  SELECT
    NOT COALESCE(ctrl.latest.halt_all, FALSE)
    AND COALESCE(f.marks_fresh, FALSE)
    AND COALESCE(f.engine_fresh, FALSE)
    AND COALESCE(eh.is_healthy, FALSE)
    AND al.blocking_criticals = 0
    AND NOT pr.drift
    AND NOT COALESCE(dd.breach_hard, FALSE)
    AND NOT COALESCE(dd.snapshot_stale, FALSE) AS v
  FROM ctrl, f, eh, al, pr, dd
)
SELECT
  t.trading_enabled AS live_value,
  e.v AS expected_value,
  (t.trading_enabled IS DISTINCT FROM e.v) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.trading_enabled` t, expected e;

-- ===== ops.sp_auto_resolve_alerts — Rule 4's no_other_criticals made halt-echo-aware (SUPERSEDES bigquery/94) =====
-- (94 superseded 78's procedure, which superseded 34's.) Rules 1, 2, 3, 3b and Rule 4's
-- live_would_clear/eligible_stale logic below are byte-identical to bigquery/94's committed body.
-- The ONLY change is Rule 4's SET no_other_criticals: its COUNTIF now also excludes halt-echo
-- missing_dependency alerts (inline halt_echo_md WITH, same fail-closed predicate as the views
-- above), so a pure halt-echo cannot keep an otherwise-clearable staleness echo latched open.
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
  -- critical (excluding staleness/trading_halted, and — since bigquery/97 — halt-echo
  -- missing_dependency alerts) remains open. Computed as independent variables first to avoid the
  -- self-reference de-correlation restriction documented in 34.
  SET no_other_criticals = (
    (WITH halt_echo_md AS (
      -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
      -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
      -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
      -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
      -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
      -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
      -- sp_auto_resolve_alerts Rule 1's SPLIT.
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a,
           UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
      LEFT JOIN `stock-trading-498512.ops.alerts` th
        ON th.category = 'trading_halted'
       AND NOT th.resolved
       AND th.source = dep
       AND DATE(th.alert_ts, 'America/Denver') =
           SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
      WHERE a.alert_id IS NOT NULL
        AND NOT a.resolved
        AND a.severity = 'critical'
        AND a.category = 'missing_dependency'
      GROUP BY a.alert_id
      HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
    )
    SELECT COUNTIF(NOT resolved AND severity = 'critical'
      AND category NOT IN ('staleness', 'trading_halted')
      AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md))
    FROM `stock-trading-498512.ops.alerts`) = 0
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

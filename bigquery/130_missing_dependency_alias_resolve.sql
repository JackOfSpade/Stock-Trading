-- 130_missing_dependency_alias_resolve.sql (2026-08-03)
-- Project: stock-trading-498512. Apply AFTER 107_halt_echo_missed_run_gate.sql.
--
-- SUPERSEDES bigquery/107_halt_echo_missed_run_gate.sql's definition of ops.sp_auto_resolve_alerts,
-- and ONLY that object. 107's other three objects (state.trading_enabled,
-- state.trading_enabled_mechanical, state.b3_trading_enabled_check) are UNCHANGED and deliberately
-- NOT re-issued here -- per bigquery/47's header rule, re-applying an old file's CREATE in isolation
-- is the exact action that caused the 47 regression. This file's CREATE OR REPLACE PROCEDURE is the
-- only new live-sql-parity object.
--
-- ============================ WHY ============================
-- Rule 1 ("missing_dependency") has, since bigquery/34, matched an alert's dependency names with
-- EXACTLY:  UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', '))
-- i.e. the comma-joined STRING shape that ops.sp_assert_deps writes via STRING_AGG(d, ', ').
--
-- That is fine for MACHINE-raised alerts. But routines also HAND-AUTHOR missing_dependency alerts
-- from their prose task-plan steps, and those choose their own payload key. MEASURED live 2026-08-03:
--
--   alert_id                              source  payload key            shape
--   8aa15de2-1ef6-4cd8-b8a7-7744de93b775  M1b     "missing_upstream"     scalar STRING  "M1a"
--   750d06e7-0344-4e50-ab3e-814037525507  M4      "unsatisfied_deps"     JSON ARRAY     ["M1b"]
--   b4649827-caf5-496f-9a8b-11740a9b553b  M1b     "missing_deps"         scalar STRING  "M1a"   (canonical)
--   25edc802-aa0a-4eca-a015-4d0ced5e387a  M4      "missing_deps"         scalar STRING  "M1b"   (canonical)
--
-- The two canonical-key rows auto-resolved normally on 2026-08-03. The two alias-key rows were
-- STRUCTURALLY INCAPABLE of ever auto-resolving: JSON_VALUE(payload,'$.missing_deps') is NULL when the
-- key is absent, SPLIT(NULL, ', ') is NULL, and CROSS JOIN UNNEST(NULL) contributes ZERO ROWS -- so the
-- alert_id vanishes from Rule 1's FROM clause entirely and is never a candidate, for either the
-- dependency-satisfied test or the >1-day age-out fallback.
--
-- CONSEQUENCE, not hypothetical: those two rows stayed open 2026-08-01 -> 2026-08-03 and held
-- state.trading_enabled's blocking_criticals at 3 (the gate ANDs `blocking_criticals = 0`). That kept
-- trading_enabled FALSE, which is why W4 2026-W32 could not stage the W3-recommended MTZ
-- thesis-invalidation exit and had to hand it to D2 "at first gate-clear". Two unresolvable alert rows
-- halted order staging for two days. They were cleared by hand in an interactive session; this file
-- stops the next recurrence.
--
-- ============================ HOW ============================
-- Rule 1's dep expression now COALESCEs over both key aliases AND both encodings:
--   JSON_VALUE_ARRAY  first (handles the JSON-array shape, e.g. unsatisfied_deps: ["M1b"])
--   then SPLIT(JSON_VALUE(...))  (handles the comma-joined scalar-string shape)
--
-- The array-first ordering is safe because JSON_VALUE_ARRAY returns SQL NULL -- not an error, not an
-- empty array -- when the path resolves to a SCALAR. Verified live 2026-08-03 with explicit IS NULL
-- probes across all four payload shapes, so COALESCE reliably falls through to the SPLIT branch for
-- scalar payloads.
--
-- ============================ FAIL-CLOSED ARGUMENT ============================
-- This procedure permanently resolves CRITICAL alerts that gate live trading, so a FALSE RESOLVE is
-- strictly worse than a missed resolve. Every degenerate input fails toward NOT resolving:
--   * payload has none of the three keys -> COALESCE is NULL -> UNNEST(NULL) yields 0 rows -> the
--     alert_id never appears -> not resolved. (Identical to today's behaviour.)
--   * unsatisfied_deps: []            -> UNNEST([]) yields 0 rows            -> not resolved.
--   * missing_deps: ""                -> SPLIT('', ', ') = [''] -> one row with dep = '' -> the
--     LEFT JOIN finds no ops.run_log row with routine = '' -> r.routine IS NULL ->
--     LOGICAL_AND(r.routine IS NOT NULL) is FALSE -> not resolved.
-- No new input shape can make Rule 1 resolve an alert whose named dependency has not actually
-- completed. The only behaviour change is that alias-keyed alerts whose dependency HAS completed
-- become eligible -- which is precisely the fix.
--
-- ============================ SCOPE (residual, deliberate) ============================
-- The same missing_deps-only expression survives at four OTHER sites, all left untouched here:
-- the halt_echo_md CTE in each of 107's three state.trading_enabled* views, plus an inline copy in
-- this procedure's own Rule 4 no_other_criticals subquery. Those sites perform a TEMPORARY, real-time
-- halt-echo EXCLUSION from blocking_criticals; they never write `resolved`. An alias-keyed alert is
-- therefore not treated as a halt-echo for the window between being raised and Rule 1's next pass --
-- bounded to roughly one routine invocation, since ops.sp_auto_resolve_alerts is called best-effort in
-- nearly every routine's Observability preamble (Claude_Task_Plan.md), not on a scheduled-query
-- cadence. That is a bounded cosmetic lag, not the multi-day stall this file closes. Flagged as a
-- candidate follow-up rather than silently widened, because touching the three trading-gate views
-- carries materially more risk than touching one procedure.
--
-- The durable alternative -- making every routine write the canonical key -- was considered and
-- rejected: routines author payloads from prose, so key drift is the expected steady state, and a
-- convention note cannot enforce it. Reader-side tolerance is the only version that actually holds.

-- SUPERSEDED LIVE by bigquery/148_audit_2026_08_08_fixes.sql — current single source of truth
-- for ops.sp_auto_resolve_alerts (chain: 94 -> 97 -> 107 -> 130 -> 134 -> 148). 134 adds Rule 5: the six
-- roster-change notice categories auto-resolve once notified_ts is stamped, i.e. once the operator
-- email has actually been delivered. Rules 1-4 below are unchanged and were copied byte-identical
-- into 134, and 134 was in turn superseded by 148, which fixed Rule 4's staleness echo arm to
-- re-check all four state.system_health components instead of two. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE PROCEDURE
-- statement live in isolation.
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
      CROSS JOIN UNNEST(COALESCE(
             JSON_VALUE_ARRAY(a.payload, '$.missing_deps'),
             JSON_VALUE_ARRAY(a.payload, '$.unsatisfied_deps'),
             JSON_VALUE_ARRAY(a.payload, '$.missing_upstream'),
             SPLIT(COALESCE(JSON_VALUE(a.payload, '$.missing_deps'),
                            JSON_VALUE(a.payload, '$.unsatisfied_deps'),
                            JSON_VALUE(a.payload, '$.missing_upstream')), ', ')
           )) AS dep
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
  -- missing_dependency alerts, and — since bigquery/107 — halt-echo missed_run alerts) remains open.
  -- Computed as independent variables first to avoid the self-reference de-correlation restriction
  -- documented in 34.
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
    ),
    halt_echo_mr AS (
      -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt.
      -- See this file's header for the full predicate + rationale.
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a,
           UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
      LEFT JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
           AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
      LEFT JOIN (
        SELECT routine, MAX(log_ts) AS last_halt_ts
        FROM `stock-trading-498512.ops.run_log`
        WHERE status = 'halted'
        GROUP BY routine
      ) hr ON hr.routine = JSON_VALUE(item, '$.routine')
      LEFT JOIN `stock-trading-498512.ops.alerts` th
        ON th.category = 'trading_halted'
           AND hr.last_halt_ts IS NOT NULL
           AND ABS(TIMESTAMP_DIFF(th.alert_ts, hr.last_halt_ts, HOUR)) <= 24
      WHERE a.alert_id IS NOT NULL
        AND NOT a.resolved
        AND a.severity = 'critical'
        AND a.category = 'missed_run'
      GROUP BY a.alert_id
      HAVING LOGICAL_AND(r.routine IS NOT NULL OR th.alert_id IS NOT NULL)
    )
    SELECT COUNTIF(NOT resolved AND severity = 'critical'
      AND category NOT IN ('staleness', 'trading_halted')
      AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
      AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr))
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

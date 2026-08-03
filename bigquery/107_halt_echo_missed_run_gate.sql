-- Halt-echo missed_run exclusion (2026-07-26): critical 'missed_run' alerts that are pure fallout
-- of an already-known trading-gate halt no longer count as blocking criticals in the trading-enable
-- gate cluster. Project: stock-trading-498512. Apply AFTER 106_retire_dashboard_heartbeat.sql. This
-- file is the NEW single source of truth for state.trading_enabled, state.trading_enabled_mechanical,
-- state.b3_trading_enabled_check and ops.sp_auto_resolve_alerts; it SUPERSEDES bigquery/97's
-- definitions of all four. Per 47's header rule, any future change to this gate cluster must land as
-- a NEW numbered file that supersedes THIS one — never re-apply an earlier file's CREATE OR REPLACE
-- for these objects in isolation.
--
-- ============================ WHY (the 2026-07-25/26 deadlock) ============================
-- A compound platform-trigger outage (07-23/24) caused D1/D2/D2a/D3/OPS0/OPS1/SL3 to miss their
-- scheduled runs. state.cadence_watch correctly raised a critical 'missed_run' alert naming all 7
-- (07-24) and, the next day, a second one naming only D3 (07-25). By 07-25, 5 of the 7 (D1, D2a,
-- OPS0, OPS1, SL3) had independently recovered and completed. D2 fired on schedule but HALTED
-- (ops.run_log status='halted') because state.trading_enabled was FALSE due to an UNRELATED root
-- cause (a latching automation_heartbeat alert about a retired 'dashboard' heartbeat source — fixed
-- same day via bigquery/106). D3 then also halted, blocked on D2's same-day output.
--
-- Once the root cause was fixed, BOTH missed_run alerts stayed open and kept blocking_criticals > 0:
-- sp_auto_resolve_alerts Rule 2 only clears a missed_run alert once EVERY named routine in its
-- payload shows a completed run_log row (or the item's date is >1 day stale) — D2/D2a not completing
-- kept both alerts open. A genuine circular deadlock: D2 won't run while trading_enabled=FALSE (it
-- checks the gate itself and halts) -> the missed_run alerts about D2/D3 not completing stay open ->
-- which is EXACTLY what kept trading_enabled=FALSE. Broken only by an operator-authorized interactive
-- session directly UPDATE-ing ops.alerts to resolve those two specific rows.
--
-- This is the SAME class of bug bigquery/97 already fixed for 'missing_dependency' alerts (see that
-- file's own header: W5's missing_dependency echo of W4's halt deadlocked identically). 97's own
-- ACCEPTED LIMITATIONS (ii) explicitly named missed_run as an unsuppressed BACKSTOP for its own gap
-- ("Backstopped by the ~23:15 MT cadence watchdog's missed_run, which is not suppressed by this
-- exclusion") — this incident is proof that backstop is insufficient on its own: Rule 2's >1-day
-- age-out means trading can stay needlessly halted for 1-2+ days after the TRUE root cause is fixed,
-- until a human manually intervenes or the staleness window finally passes.
--
-- ============================ THE FAIL-CLOSED PREDICATE ============================
-- A critical 'missed_run' alert (payload = ARRAY<STRUCT<routine, schedule, today>>, bigquery/75
-- ~line162) is a "halt-echo" IFF EVERY named item is explained by EITHER:
--   (A) the routine has SINCE completed (run_log 'completed', run_date >= item.today) — the exact
--       same test Rule 2 already uses to fully resolve the alert; included here too so the item
--       stops blocking in REAL TIME (the live view recomputes every read) rather than waiting for
--       Rule 2's own next scheduled pass, OR
--   (B) "halt-fallout": the routine's MOST RECENT ops.run_log row is status='halted' (it tried, and
--       voluntarily deferred to the gate, as opposed to a platform outage where it never fired at
--       all), and a category='trading_halted' alert was raised within 24 HOURS of that halted row's
--       log_ts — proof the account-wide gate was actually tripped closed around the same time as
--       this specific attempt, not an unrelated coincidence.
--
-- WHY A TIME WINDOW, NOT bigquery/97's "th.source = dep AND same Denver day" test:
--   (i)   sp_raise_alert_once dedups trading_halted on EXACT message text. The two canonical call
--         sites (bigquery/85 lines ~73/~108) use a fixed boilerplate string, and ad-hoc diagnostic
--         narratives from monitoring routines (e.g. OPS0) use their own distinct text — so at most
--         one row per distinct phrasing survives, credited to whichever routine/path reached the
--         gate (or noticed it) first, NOT one row per source. A strict source=routine match (97's
--         dep-alert idiom) would only ever explain that one credited routine, never a routine sharing
--         the same halt episode via a differently-worded or differently-sourced alert — exactly the
--         D2/D2a split observed in this incident (a35dcba0 source=D2a critical boilerplate;
--         29eb4bae source=D2 warning narrative — two different messages, two different rows, one
--         underlying gate closure).
--   (ii)  trading_halted is human-latching with NO auto-resolve rule anywhere in this procedure —
--         gating on "NOT th.resolved" (97's approach for missing_dependency) is not a safe bound
--         here: these rows routinely sit open for days with no forcing function to clear them (both
--         a35dcba0 and 29eb4bae were STILL open hours after the root cause was fixed and manually
--         verified as such during this fix's design). A 24h window on WHEN the corroborating alert
--         fired — not whether it has since been resolved — is the actual, bounded correlation.
--   (iii) missed_run's own catch-up lag means a routine can first attempt (and halt) days after its
--         item.today; the halt evidence and the alert must correlate to EACH OTHER's timing, not to
--         the stale expected-date, or the predicate never fires for exactly the multi-day case this
--         incident is.
--
-- FAIL-CLOSED: a routine with no run_log row of ANY status (the true platform-outage no-show) keeps
-- blocking, exactly as today — hr's routine-keyed MAX(log_ts) is NULL, so both (A) and (B) are FALSE.
-- A routine that halts again for a genuinely NEW, unrelated reason is required BY CONVENTION
-- (Claude_Task_Plan.md "Failure alerts": "any condition that halts a routine... MUST be surfaced") to
-- raise ITS OWN alert in a non-trading_halted category — never excluded here, so it keeps blocking on
-- its own regardless of this CTE. A NULL alert_id is excluded outright (same reason as halt_echo_md:
-- left in, the downstream blocking-criticals NOT IN would return NULL for every row and fail OPEN).
-- Validated against this incident's actual data before landing: both real alerts (07-24's 7-routine
-- bundle and 07-25's D3-only alert) independently verify as fully explained under this predicate —
-- 5 items via (A), D2/D3 via (B) with corroborating trading_halted alerts 8-133 minutes away, well
-- inside the 24h window.
--
-- !! Do NOT widen condition (B) to an unbounded date match or to "any open trading_halted alert
-- ever" — that is the exact failure mode this file's own adversarial review rejected: an old,
-- forgotten, still-open trading_halted row could otherwise vouch for an unrelated halt far in the
-- future. The 24h window is the load-bearing bound; do not remove it without a replacement of
-- equivalent rigor.
--
-- ============================ ACCEPTED LIMITATIONS ============================
-- Both degrade to the STATUS-QUO blocking behaviour (fail-closed), never to fail-open:
--   (i)  If a routine's most recent halted attempt and the nearest trading_halted alert are more
--        than 24h apart (a very slow-to-notice, long-running episode), the item is NOT excused and
--        stays blocking — same as today, not worse. Rule 2's existing >1-day age-out remains the
--        ultimate backstop for this case.
--   (ii) A routine that halts TWICE in the same 24h window — once for the gate (excused) and once
--        for a second, different, ALSO-unalerted reason — is not distinguishable by this predicate
--        alone; it relies on the "Failure alerts" convention that any hard-stop raises its own alert.
--        This is the same reliance every other rule in this procedure already places on that
--        convention (e.g. Rule 1/Rule 2's own existing tests assume a named dependency's completion
--        or absence is the whole story); not a new risk introduced here.
--   (iii) Scope, like 97, is EXCLUSION from blocking_criticals/no_other_criticals only — the
--        underlying missed_run alert ROW is left untouched (Rule 2 still owns its actual resolution),
--        so it remains visible in ops.alerts for audit and still ages out via Rule 2's existing rule.

-- ===== state.trading_enabled — REDEFINED (SUPERSEDES bigquery/97) =====
-- Sole change vs 97: blocking_criticals additionally excludes halt-echo missed_run alerts
-- (halt_echo_mr CTE below), alongside the existing halt_echo_md, and the blocking-criticals
-- halt_reason branch names the new exclusion. Everything else byte-identical to 97's committed body.
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
halt_echo_mr AS (
  -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt. See
  -- this file's header for the full predicate + rationale. (A) reuses Rule 2's own completion test;
  -- (B) correlates the routine's latest halted attempt to a trading_halted alert within 24h.
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
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
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
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt); the -15%% soft tier pauses new entries only', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot not refreshed for the current trading day — the breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, eh, al, pr, dd;

-- ===== state.trading_enabled_mechanical — REDEFINED (SUPERSEDES bigquery/97) =====
-- Same sole change as state.trading_enabled above (halt_echo_mr exclusion + halt_reason wording).
-- Still deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-circular term, per 33's
-- header). Everything else byte-identical to 97's committed body.
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
halt_echo_mr AS (
  -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt. See
  -- this file's header for the full predicate + rationale.
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
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
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
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt)', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd;

-- ===== state.b3_trading_enabled_check — REDEFINED (SUPERSEDES bigquery/97) =====
-- The live formula self-check must track the gate it mirrors, or it false-fires drift. Updated to
-- carry the same halt_echo_mr exclusion (alongside the existing halt_echo_md) in its
-- blocking-criticals recomputation. Everything else byte-identical to 97's committed body.
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
halt_echo_mr AS (
  -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt. See
  -- this file's header for the full predicate + rationale.
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
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
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

-- SUPERSEDED LIVE by bigquery/130_missing_dependency_alias_resolve.sql — current single source of
-- truth for ops.sp_auto_resolve_alerts. 130 makes Rule 1's dependency match tolerant of the
-- missing_upstream / unsatisfied_deps payload-key aliases and of the JSON-array encoding; the
-- missing_deps-only expression below can never auto-resolve a routine-hand-authored
-- missing_dependency alert, which held blocking_criticals non-zero for two days on 2026-08-01..03.
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE OR REPLACE PROCEDURE statement live in isolation.
--
-- ===== ops.sp_auto_resolve_alerts — Rule 4's no_other_criticals made halt-echo-aware for missed_run
-- too (SUPERSEDES bigquery/97) =====
-- Rules 1, 2, 3, 3b and Rule 4's live_would_clear/eligible_stale logic below are byte-identical to
-- bigquery/97's committed body. The ONLY change is Rule 4's SET no_other_criticals: its COUNTIF now
-- also excludes halt-echo missed_run alerts (inline halt_echo_mr WITH, same fail-closed predicate as
-- the views above, alongside the existing halt_echo_md), so a pure halt-echo missed_run cannot keep
-- an otherwise-clearable staleness echo latched open.
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

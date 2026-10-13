-- bigquery/255_trading_halted_auto_resolve.sql (2026-10-13)
-- Project: stock-trading-498512. Apply after bigquery/249_scheduled_query_stale_recovery_resolve.sql (the
-- definition of ops.sp_auto_resolve_alerts this file supersedes) and bigquery/34_alert_lifecycle.sql
-- (ops.alert_policy). Closes W5 SPEC-DEFECT NOTICE 97fa4b79-428a-4466-a139-9b388c0e14cd
-- (trading_halted_stale_row_swallows_future_raises) by OWNER DIRECTIVE 2026-10-13: the owner chose, in an
-- interactive session, "register a SQL auto-resolve rule" over a routine-owned D2a heal or keeping the
-- class human-only.
--
-- TWO STATEMENTS:
--   1. MERGE ops.alert_policy: trading_halted becomes latching = FALSE, with its resolve_rule written out.
--   2. CREATE OR REPLACE PROCEDURE ops.sp_auto_resolve_alerts: Rules 1, 2, 3, 3b, 4, 5 and 6 carried
--      forward BYTE-IDENTICAL from bigquery/249 -- verified 2026-10-13 by md5 of the live
--      INFORMATION_SCHEMA.ROUTINES routine_definition (18517 chars, 34bbf92d...) against the
--      repo-extracted bigquery/249 body: equal. The ONLY change is one appended block, Rule 7,
--      immediately before the closing END.
--
-- ===== THE DEFECT, MEASURED 2026-10-13 =====
-- trading_halted was human-only by ABSENCE from the fail-closed ops.alert_policy allowlist (bigquery/34
-- seeded only four classes). All 17 trading_halted rows ever raised (2026-07-07 .. 2026-10-01) were closed
-- by hand, open 0.4h to 80.1h (median ~19h), and every one of them was closed only after someone verified
-- the gate had gone green again -- i.e. the closing act was a mechanical re-check performed by a human.
-- While each sat open it was not neutral: every gate site raises trading_halted with the SAME pinned
-- message ('Order staging blocked: trading is HALTED. See payload for the triggering routine and reason.')
-- and ops.sp_raise_alert_once dedups on exact (category, message) over UNRESOLVED rows, so a genuine LATER
-- halt from any routine (halt_all, cash_tripwire, order_guard_block, the -40% breaker) minted no row and
-- sent no email. Claude_Task_Plan.md's PRE-REFRESH HALT DISPOSITION already named this hazard; D2a's
-- notice 97fa4b79 (2026-09-23, on stale row 1b917c51) asked for a resolve path; W5 held it two cycles as
-- owner_decision.
--
-- ===== THE FIX: RULE 7, RESOLVE WHEN THE GATE IS GREEN (positive evidence) =====
-- Resolve every NOT-resolved trading_halted row when, at call time, ALL of:
--   (a) state.trading_enabled has exactly one row, trading_enabled TRUE, halt_reason NULL;
--   (b) state.trading_enabled_mechanical has exactly one row, trading_enabled TRUE, halt_reason NULL;
--   (c) no unresolved critical missing_dependency alert exists;
--   (d) ops.alert_policy lists trading_halted with latching = FALSE (statement 1).
-- WHY (c) IS LOAD-BEARING -- the trap a naive "gate is TRUE -> resolve" rule falls into. Both gate views
-- compute blocking_criticals EXCLUDING any critical missing_dependency whose every missing dep has a
-- same-day OPEN trading_halted from that dep (CTE halt_echo_md, bigquery/97). So the gate can read TRUE
-- precisely BECAUSE a trading_halted row is open; closing it un-excludes the echo and flips the gate back
-- to FALSE. While any critical missing_dependency is open, Rule 7 therefore does nothing (exactly the
-- pre-255 behaviour). Rule 1 (missing_dependency resolve) runs earlier in the SAME call, so a dependency
-- that has genuinely recovered is closed before (c) is read. halt_echo_mr (bigquery/107) matches
-- trading_halted rows regardless of resolved state, so resolving them cannot disturb that exclusion.
-- (a) is the freshness-inclusive gate, so a pre-refresh artifact (bigquery/206) never satisfies it: a
-- halt raised in the ~16.5h pre-refresh window closes only after D2a's 22:40 UTC refresh.
-- CANNOT CLOSE A LIVE HALT: every halt cause that matters (halt_all in ops.trading_control, any blocking
-- critical incl. cash_tripwire / order_guard_block, position drift, the -40% book breaker, a stale
-- account snapshot) makes (a) or (b) FALSE. A halt that recurs after this rule closes the old row now
-- mints a FRESH row and a fresh email -- which is the point.
-- KILL SWITCH: UPDATE ops.alert_policy SET latching = TRUE WHERE category = 'trading_halted' disables
-- Rule 7 on the next call with no code change (term (d)), the same switch Rules 1-4 honour.
-- FIRE DRILL UNAFFECTED: ops.sp_fire_drill_alert_latch (bigquery/34) drills cash_tripwire, which stays
-- absent from the allowlist.
-- BEST-EFFORT nested block, as Rule 6 (bigquery/249 explains the trade-off): it reads two state.* views
-- that BigQuery binds lazily at CALL time, and must never throw out of the resolver every routine
-- pre-flight calls. Rule 7 is last, so a swallowed failure loses only its own resolve.
-- The note starts 'auto-resolved:' because alert_emailer.gs tags a resolved row [AUTO-RESOLVED] only on
-- that exact prefix.
--
-- ===== NOT CHANGED =====
-- The gate views, sp_raise_alert_once, the pinned message, every gate/craft-site raise, and the
-- PRE-REFRESH HALT DISPOSITION are untouched. The gate is exactly as strict as before; only how a
-- CLEARED halt's alert row gets closed changes.
--
-- ===== VERIFICATION (read-only) =====
-- Pre-apply 2026-10-13: the Rule 7 predicate read gate_green = TRUE with 0 open trading_halted rows, so
-- applying this file closes nothing today. The dryRun of a procedure holding Rule 7's block compiled.

-- ===== STATEMENT 1: ops.alert_policy registration =====
MERGE `stock-trading-498512.ops.alert_policy` T
USING (
  SELECT p.category, p.latching, p.resolve_rule, p.note
  FROM UNNEST([
    STRUCT(
      'trading_halted' AS category,
      FALSE AS latching,
      CONCAT(
        'ops.sp_auto_resolve_alerts Rule 7 (bigquery/255): resolve when state.trading_enabled AND ',
        'state.trading_enabled_mechanical each return exactly one row with trading_enabled = TRUE and ',
        'halt_reason NULL, AND no unresolved critical missing_dependency alert exists (the halt_echo_md ',
        'exclusion would otherwise flip the gate back to FALSE once the trading_halted row closed). Any live ',
        'halt cause makes the gate FALSE, so this cannot close a live halt.'
      ) AS resolve_rule,
      CONCAT(
        'Moved from human-only (absent) to auto-resolvable by OWNER DIRECTIVE 2026-10-13, closing W5 ',
        'spec-defect notice 97fa4b79: all 17 trading_halted rows to date were closed by hand after the gate ',
        'went green (open 0.4-80.1h, median ~19h), and each open row swallowed every later trading_halted ',
        'raise via sp_raise_alert_once exact-message dedup. Set latching = TRUE to disable Rule 7.'
      ) AS note)
  ]) AS p
) S
ON T.category = S.category
WHEN MATCHED THEN
  UPDATE SET latching = S.latching, resolve_rule = S.resolve_rule, note = S.note, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (category, latching, resolve_rule, note) VALUES (S.category, S.latching, S.resolve_rule, S.note);

-- ============================================================================
-- STATEMENT 2: ops.sp_auto_resolve_alerts -- SUPERSEDES the definition in
-- bigquery/249_scheduled_query_stale_recovery_resolve.sql (chain: 94 -> 97 -> 107 -> 130 -> 134 -> 148 ->
-- 249 -> 255). Rules 1-6 are byte-identical to bigquery/249; Rule 7 is new. Do NOT re-apply bigquery/249,
-- 148, 134, 130, 107, 97, 94, 78 or 34's CREATE of this procedure live in isolation -- that would
-- silently remove Rule 7 (and, for the pre-249 files, Rule 6).
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`()
BEGIN
  DECLARE eligible_dep, eligible_run, eligible_stalled, eligible_stale, eligible_refire_blocked ARRAY<STRING>;
  DECLARE eligible_roster_notice ARRAY<STRING>;
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
        -- echo (FIXED, bigquery/148, 2026-08-08 audit): re-checks ALL FOUR components
        -- state.system_health's staleness raise condition depends on -- marks_fresh, engine_fresh,
        -- embeddings_healthy, position_drift_detected -- not just the first two. The old 2-of-4 form let
        -- an alert raised because embeddings_healthy=FALSE (or position_drift_detected=TRUE) carry a
        -- payload where marks_fresh/engine_fresh were BOTH 'true', and auto-resolve here while the real
        -- fault persisted -- the only ops.alerts channel that surfaces embedding_health.is_healthy=FALSE
        -- at critical severity during routine cadence checks. Under the CURRENT (already-narrowed)
        -- staleness raise condition (NOT (marks_fresh AND engine_fresh AND embeddings_healthy AND NOT
        -- position_drift_detected)), an alert whose payload satisfies all four of THESE tests is, by
        -- construction, not one the raise condition would have fired on -- so this arm can now never
        -- actually match, which is CORRECT: Rule 4 should rely on live_would_clear's genuine live
        -- re-check, not a payload echo. Left in place (not deleted) so a future reader does not
        -- "simplify" it back to the 2-of-4 form that reopened this gap.
        OR (JSON_VALUE(payload, '$.marks_fresh') = 'true'
            AND JSON_VALUE(payload, '$.engine_fresh') = 'true'
            AND JSON_VALUE(payload, '$.embeddings_healthy') = 'true'
            AND JSON_VALUE(payload, '$.position_drift_detected') != 'true')
      )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: freshness verified green (or payload shows it was green at raise — pure alert-on-alert echo), no other open critical (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stale, []));

  -- Rule 5 (NEW, bigquery/134, owner directive 2026-08-04): ROSTER-CHANGE NOTICES resolve on DELIVERY.
  --
  -- These six categories are notifications, not conditions. There is no "unhealthy state" to re-check --
  -- the alert's entire purpose is to carry one roster-membership fact to the operator's inbox, so the
  -- fact that it was delivered IS the completion condition. ops.alerts.notified_ts has exactly one
  -- writer in the system (alert_emailer.gs stampNotified_, which runs only after a successful
  -- GmailApp.sendEmail), so this predicate means "the email went out" and can mean nothing else.
  --
  -- Fail-closed and deliberately so: an UNDELIVERED notice stays open. If the emailer is dead, revoked,
  -- or its severity filter regresses, these rows accumulate visibly rather than ageing away silently --
  -- which is the opposite of what a time-based rule would do, and is the point. Unlike Rules 1-4 there
  -- is no age-out escape hatch here for exactly that reason.
  --
  -- The severity these are raised at ('warning') is what makes them visible to alert_emailer.gs at all;
  -- see this file's header. Keep the list below in lockstep with the Part 1 policy rows AND with the
  -- Claude_Task_Plan.md preamble contract -- a category in only one of the three places is inert.
  --
  -- The `severity = 'warning'` term is DEFENSE IN DEPTH, added 2026-08-04 after an adversarial review
  -- of this file. Every raise site for these six categories is 'warning' today, so it is dormant --
  -- but without it the rule is enforced by prose alone, and the failure mode is fail-OPEN on the
  -- trading gate: if some future edit ever raised one of these categories at 'critical', that critical
  -- would count toward state.trading_enabled's blocking_criticals (halting order staging) AND would be
  -- silently auto-resolved here the instant any poll delivered it -- un-halting trading on a rule whose
  -- entire premise is that it only ever touches informational rows. Scoping to 'warning' makes the
  -- mismatch fail closed instead: a mis-raised critical stays open and visible.
  SET eligible_roster_notice = (
    SELECT ARRAY_AGG(alert_id)
    FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved
      AND severity = 'warning'
      AND category IN ('strategy_shadow_registered', 'strategy_probe_registered', 'strategy_graduated',
                       'retirement_proposed', 'strategy_deregistered', 'roster_below_floor')
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND notified_ts IS NOT NULL
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: roster-change notice delivered to the operator (notified_ts stamped by alert_emailer.gs); notification-only alert, nothing to act on (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_roster_notice, []));

  -- Rule 6 (NEW, bigquery/249, 2026-09-30): scheduled_query_stale RESOLVES ON RECOVERY.
  --
  -- ops.sp_sq_cadence_check raises this warning when state.scheduled_query_version_drift shows a config
  -- with stale_beat OR never_beat_overdue. Until this rule, its only closure was the 7-day auto-age, and
  -- the stuck row jammed its own detector: ops.sp_raise_alert_once dedups on exact (category, message)
  -- over UNRESOLVED rows and this message lists only sq_names, so a re-stall of the same config inside
  -- the window minted no new alert and no email. See this file's header for the incident
  -- (715b5439-3d31-436b-8d30-9453d9794a99, backup_events_export, 2026-09-30).
  --
  -- Predicate: the payload (a JSON array of structs keyed by sq_name) names at least one sq_name, EVERY
  -- element has a non-null sq_name, EVERY named sq_name still HAS a row in
  -- state.scheduled_query_version_drift (known_sq), and NONE of them is currently stale_beat OR
  -- never_beat_overdue there. The known_sq term is what makes this positive evidence: a config whose
  -- registry row vanished (renamed, deleted, partial DR rebuild, an empty view) is absent from stale_sq
  -- too, and without known_sq its absence would read as "recovered". Fail-closed: an unreadable payload
  -- or an unknown config stays open for the 7-day age-out. severity = 'warning' is Rule 5's
  -- defence-in-depth scoping. The note starts 'auto-resolved:' because alert_emailer.gs tags a
  -- resolved row [AUTO-RESOLVED] only on that exact prefix (startsWith('auto-resolved:')).
  --
  -- The stale set is materialized into stale_sq FIRST because a correlated subquery against a JOINed
  -- view inside UPDATE ... WHERE is rejected by BigQuery ("correlated subquery needs a join-less
  -- source"); the UPDATE below correlates only against UNNEST of the row's own payload and that array.
  -- Nested BEGIN block: DECLARE must open a block. Best-effort (EXCEPTION), unlike Rules 1-5, because it
  -- is the first rule to read a view from another file that BigQuery binds lazily at CALL time.
  BEGIN
    DECLARE stale_sq ARRAY<STRING> DEFAULT (
      SELECT COALESCE(ARRAY_AGG(sq_name IGNORE NULLS), [])
      FROM `stock-trading-498512.state.scheduled_query_version_drift`
      WHERE stale_beat OR never_beat_overdue
    );
    DECLARE known_sq ARRAY<STRING> DEFAULT (
      SELECT COALESCE(ARRAY_AGG(sq_name IGNORE NULLS), [])
      FROM `stock-trading-498512.state.scheduled_query_version_drift`
    );
    UPDATE `stock-trading-498512.ops.alerts`
    SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
        resolved_note = CONCAT('auto-resolved: beat recovered -- every sq_name in this alert has a row that is neither stale_beat nor never_beat_overdue in state.scheduled_query_version_drift; no sq_name in this alert is stale_beat/never_beat_overdue in state.scheduled_query_version_drift (sp_auto_resolve_alerts Rule 6, bigquery/249). ', COALESCE(resolved_note, ''))
    WHERE NOT resolved
      AND category = 'scheduled_query_stale'
      AND severity = 'warning'
      AND ARRAY_LENGTH(JSON_QUERY_ARRAY(payload)) >= 1
      AND NOT EXISTS (
        SELECT 1 FROM UNNEST(JSON_QUERY_ARRAY(payload)) AS e
        WHERE JSON_VALUE(e, '$.sq_name') IS NULL
           OR JSON_VALUE(e, '$.sq_name') IN UNNEST(stale_sq)
           OR JSON_VALUE(e, '$.sq_name') NOT IN UNNEST(known_sq)
      );
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;
  -- Rule 7 (NEW, bigquery/255, owner directive 2026-10-13): trading_halted RESOLVES WHEN THE GATE IS
  -- GREEN AGAIN. See bigquery/255's header for the defect (three manual closes, each one swallowing
  -- every later trading_halted raise via sp_raise_alert_once's exact-message dedup while it sat open).
  --
  -- Predicate, all on POSITIVE evidence read at call time:
  --   (a) state.trading_enabled returns exactly one row with trading_enabled = TRUE and halt_reason NULL
  --       (the freshness-inclusive staging gate -- so a pre-refresh artifact never satisfies it);
  --   (b) state.trading_enabled_mechanical returns exactly one row with trading_enabled = TRUE and
  --       halt_reason NULL;
  --   (c) NO unresolved critical missing_dependency alert exists. This term is load-bearing: both gate
  --       views exclude a missing_dependency critical from blocking_criticals while a same-day OPEN
  --       trading_halted from that dependency exists (halt_echo_md). Closing the trading_halted row
  --       would un-exclude that echo and flip the gate FALSE again -- so while any such alert is open,
  --       Rule 7 leaves trading_halted alone (today's behaviour). Rule 1 runs first in this same call,
  --       so a dependency that has recovered is already closed before this term is read.
  --   (d) the category is in ops.alert_policy with latching = FALSE -- the same kill switch Rules 1-4
  --       honour: flipping the trading_halted row back to latching = TRUE disables this rule with no
  --       code change.
  -- A genuine halt (halt_all, cash_tripwire or any other blocking critical, position drift, the -40%
  -- breaker, a stale snapshot) makes (a) or (b) FALSE, so this rule can never close a live halt.
  -- Best-effort nested block, as Rule 6: it reads two state.* views bound lazily at CALL time, and a
  -- failure here must never throw out of the resolver every routine pre-flight depends on.
  BEGIN
    DECLARE gate_green BOOL DEFAULT (
      SELECT COUNT(*) = 1 AND LOGICAL_AND(COALESCE(trading_enabled, FALSE) AND halt_reason IS NULL)
      FROM `stock-trading-498512.state.trading_enabled`
    ) AND (
      SELECT COUNT(*) = 1 AND LOGICAL_AND(COALESCE(trading_enabled, FALSE) AND halt_reason IS NULL)
      FROM `stock-trading-498512.state.trading_enabled_mechanical`
    ) AND NOT EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.alerts`
      WHERE NOT resolved AND severity = 'critical' AND category = 'missing_dependency'
    );
    UPDATE `stock-trading-498512.ops.alerts`
    SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
        resolved_note = CONCAT('auto-resolved: trading gate green again -- state.trading_enabled and state.trading_enabled_mechanical both read TRUE with halt_reason NULL and no critical missing_dependency is open (sp_auto_resolve_alerts Rule 7, bigquery/255). ', COALESCE(resolved_note, ''))
    WHERE NOT resolved
      AND category = 'trading_halted'
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND COALESCE(gate_green, FALSE);
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;
END;

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The policy row:
--    SELECT category, latching FROM `stock-trading-498512.ops.alert_policy` WHERE category = 'trading_halted';
--    (expect latching = FALSE).
-- 2. Rule 7's predicate as a SELECT (expect gate_green TRUE on a healthy day):
--    SELECT
--      (SELECT COUNT(*) = 1 AND LOGICAL_AND(COALESCE(trading_enabled, FALSE) AND halt_reason IS NULL)
--         FROM `stock-trading-498512.state.trading_enabled`)
--      AND (SELECT COUNT(*) = 1 AND LOGICAL_AND(COALESCE(trading_enabled, FALSE) AND halt_reason IS NULL)
--         FROM `stock-trading-498512.state.trading_enabled_mechanical`)
--      AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alerts`
--         WHERE NOT resolved AND severity = 'critical' AND category = 'missing_dependency') AS gate_green;
-- 3. The live body carries Rule 7 and still carries Rules 1-6: run scripts/check_live_sql_parity.py.

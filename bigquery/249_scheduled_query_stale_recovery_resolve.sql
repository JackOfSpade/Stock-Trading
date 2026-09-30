-- bigquery/249_scheduled_query_stale_recovery_resolve.sql (2026-09-30)
-- Project: stock-trading-498512. Apply after bigquery/148_audit_2026_08_08_fixes.sql (the definition of
-- ops.sp_auto_resolve_alerts this file supersedes), bigquery/232_sq_version_drift_bootstrap_grace.sql
-- (the current state.scheduled_query_version_drift Rule 6 reads) and bigquery/241_queue_driven_per_day_
-- missed_fire.sql (the current ops.sp_sq_cadence_check, whose raise block is the writer of the category).
--
-- ONE STATEMENT: CREATE OR REPLACE PROCEDURE ops.sp_auto_resolve_alerts. It SUPERSEDES bigquery/148's
-- definition. Rules 1, 2, 3, 3b, 4 and 5 are carried forward BYTE-IDENTICAL -- verified 2026-09-30 by
-- md5 of the live INFORMATION_SCHEMA.ROUTINES routine_definition (15076 chars, 13d852e2...) against the
-- repo-extracted bigquery/148 body: equal, so 148 was exactly what was live before this file. The ONLY
-- change is one appended block, Rule 6, immediately before the closing END. No alert_policy row, no
-- ops.sp_sq_cadence_check change (scheduled_query_stale stays on its 7-day age-out allowlist as the
-- backstop), no SQ_VERSION bump (this procedure is not an ops.sp_sq_* wrapper).
--
-- ===== THE DEFECT, MEASURED 2026-09-30 =====
-- Alert 715b5439-3d31-436b-8d30-9453d9794a99 (scheduled_query_stale, warning, payload
-- [{"sq_name":"backup_events_export","stale_beat":true,...}]) was raised 2026-09-30 05:17 UTC after the
-- backup_events_export DTS config skipped ONE run (2026-09-29 05:30 UTC; last beat 2026-09-28 05:30:12).
-- The 2026-09-30 05:30:07 run beat, and state.scheduled_query_version_drift now reads stale_beat = false
-- and never_beat_overdue = false for all 12 registered configs -- but the row stayed OPEN. Its only
-- closure was ops.sp_sq_cadence_check's 7-day auto-age allowlist (it would have closed ~2026-10-08
-- 05:15), and ops.sp_auto_resolve_alerts carried no rule for the category.
--
-- WHY THAT IS A DETECTOR-JAMMING BUG AND NOT JUST TIDINESS. ops.sp_raise_alert_once dedups on the exact
-- (category, message) over UNRESOLVED rows, and this alert deliberately keeps its message stable: it
-- lists only the sq_names and their failure mode ("backup_events_export (stale beat)"), with the
-- daily-changing ages confined to the payload (see bigquery/241, the "scheduled_query_stale (warning,
-- MON H5" raise block). So if backup_events_export stalls AGAIN inside the 8-day window, the identical
-- message dedups into the stale open row: no new row, no email, no push. The stuck row silences the
-- very detector that raised it. This is the same bug class the repo has already fixed for sibling
-- categories (OWNER_ACTIONS.md's connector_tool_enumeration_failed entry: "the stuck row jams its own
-- detector"). Both earlier scheduled_query_stale rows had to be resolved BY HAND: 58ddf688 (2026-07-18,
-- embed_pending) and be440801 (2026-07-25, fire_drill_order_guard + restore_drill).
--
-- ===== THE FIX: RULE 6, RESOLVE ON RECOVERY (a positive-evidence rule) =====
-- Resolve a NOT-resolved scheduled_query_stale row when its payload names at least one sq_name AND NONE
-- of the payload's sq_names is currently (stale_beat OR never_beat_overdue) in
-- state.scheduled_query_version_drift -- the exact predicate the raise block itself uses -- AND every
-- named sq_name still HAS a row in that view. Evidence is POSITIVE: the view row for each named config
-- exists and says "not stale"; a config with NO row (renamed, deleted, partial DR rebuild, empty view) is
-- never read as recovered, because its absence from the stale set is not evidence of health. Four
-- fail-closed properties:
--   * a named sq_name with no row in the view keeps the alert open (the known_sq term);
--   * a payload with no parsable sq_name (NULL payload, non-array, empty array, or ANY element lacking
--     sq_name) is never resolved -- an unreadable row stays open for the age-out rather than being
--     closed on the strength of an empty predicate;
--   * a multi-name alert is resolved only when ALL its names have recovered (one still-stale name keeps
--     it open); the raise block then mints a separate row for the remaining stalled set;
--   * scoped to severity = 'warning', the only severity the raise block ever uses (Rule 5's
--     defence-in-depth idiom: a mis-raised critical would count toward blocking_criticals, so it must
--     fail closed here, not be auto-resolved).
-- No ops.alert_policy latching gate (Rules 1-5's `category IN (SELECT ... WHERE NOT latching)`) is
-- applied, because ops.alert_policy has NO row for scheduled_query_stale (queried 2026-09-30: zero rows
-- for the category; the only stale-ish rows are staleness and premortem_preamble_stale) and none is added
-- here. bigquery/241's own note that this class "has no ops.alert_policy row" is the convention for the
-- auto-age-allowlisted categories; the absent row means not-latching by default, which is the behaviour
-- Rule 6 encodes explicitly through its own predicate.
--
-- ORDERING -- WHY THIS CANNOT CHURN (resolve then immediately re-mint). bigquery/241's
-- ops.sp_sq_cadence_check runs, in this order: sp_beat_heartbeat; sp_backfill_run_log_from_markers
-- (best-effort); CALL ops.sp_auto_resolve_alerts() (best-effort; the "Mechanized alert auto-resolve (WP2"
-- block); the #14 7-day auto-age UPDATE; and only THEN, much further down, the scheduled_query_stale
-- raise block ("scheduled_query_stale (warning, MON H5, 2026-07-17)"). So the resolver evaluates the
-- view BEFORE the raise block reads it, in the same run. A condition that is STILL stale makes Rule 6's
-- predicate false, the row stays open, and the raise block dedups into it exactly as today. A condition
-- that HEALED is resolved first, so a later stall raises a fresh row. Both rules read the same view
-- within seconds of each other; neither can disagree except on a boundary crossing inside that window,
-- and even then the worst case is one extra identical raise on the next run, never a lost alert.
-- Other callers of sp_auto_resolve_alerts (the routine pre-flight blocks, sp_backfill_run_log_from_
-- markers) simply resolve earlier; the predicate is the same.
--
-- THE BIGQUERY TRAP RULE 6 IS SHAPED AROUND. The obvious form,
--   UPDATE ops.alerts a SET ... WHERE NOT EXISTS (SELECT 1 FROM UNNEST(JSON_QUERY_ARRAY(a.payload)) e
--     JOIN state.scheduled_query_version_drift v ON v.sq_name = JSON_VALUE(e, '$.sq_name')
--     WHERE v.stale_beat OR v.never_beat_overdue)
-- is a correlated subquery over a JOINed view inside UPDATE ... WHERE, which BigQuery rejects ("correlated
-- subquery needs a join-less source"; the same family of rejection bigquery/234 hit and rewrote). So the
-- currently-stale set is MATERIALIZED FIRST into a variable, stale_sq ARRAY<STRING>, and the UPDATE
-- correlates only against UNNEST of that row's own payload and the array variable -- a join-less source.
-- The variable needs its own nested BEGIN ... END block because BigQuery requires DECLARE to be the
-- first statement of a block, and this procedure's own DECLAREs are already at the top with Rules 1-5
-- interleaved below them.
--
-- BEST-EFFORT WRAP (a deliberate deviation from Rules 1-5, which are unwrapped). Rule 6 is the first rule
-- here to read a state.* view defined in a different file (bigquery/232), and BigQuery binds a
-- procedure's referenced objects LAZILY, at CALL time. ops.sp_auto_resolve_alerts is called from every
-- routine's pre-flight and from ops.sp_backfill_run_log_from_markers, so an un-caught failure in an
-- appended advisory rule (view missing after a partial DR rebuild, a schema change, a transient error)
-- would throw out of a resolver that every routine start depends on. The nested block therefore catches
-- ERROR and surfaces the message with SELECT @@error.message, the pattern ops.sp_sq_cadence_check already
-- applies to this very procedure. Rule 6 is last, so a swallowed failure loses only its own resolve,
-- never Rules 1-5, and the 7-day age-out remains the backstop. The wrap is a real trade-off, not free:
-- a persistent failure here is quiet (a result set nobody reads) and would degrade back to the pre-249
-- behaviour rather than alert.
--
-- ===== NOT CHANGED, AND WHY =====
-- bigquery/241's #14 age-out allowlist keeps scheduled_query_stale: it is the backstop when this rule
-- cannot fire (view error, unparsable payload). ops.sp_sq_cadence_check is deliberately untouched, so no
-- SQ_VERSION bump or registry MERGE is owed (bigquery/63).
--
-- ===== CORRECTION OF A FALSE COMMENT (bigquery/232) =====
-- The beat-age comment in bigquery/232's state.scheduled_query_version_drift said GRACE_FACTOR = 1.5
-- means "a daily query tolerates one missed run before flagging". That is false for a DAILY query whose
-- detector is ops.sp_sq_cadence_check. That procedure runs at 05:15 UTC, BEFORE the 05:25-05:40 beats
-- of the daily queries, so at 05:15 the newest beat of a daily config is the previous day's, and a
-- SINGLE skipped daily run makes the last beat ~47.75 h old at the next 05:15 pass (2026-09-28 05:30:12
-- to 2026-09-30 05:17 is 47.8 h) -- past the 36 h limit (24 h x 1.5) -- so ONE missed backup DOES raise
-- the next morning, exactly as it did today. That behaviour is intended and unchanged (one missed
-- backup should warn); only the sentence was wrong. Whether comments in a view body take part in
-- parity was checked in scripts/check_live_sql_parity.py: canonicalize() runs the body through
-- sql_tokens(), which consumes `--` and `/* */` comments silently, and BigQuery itself does not
-- preserve them, so comment text never participates in the parity comparison. The correction was
-- therefore made IN PLACE in bigquery/232 (a dated CORRECTED note, no code change) and mirrored in the
-- dbt port, rather than only here.
--
-- ===== VERIFICATION (read-only; run before/after apply) =====
-- Rule 6's predicate, run as a SELECT over ops.alerts on 2026-09-30, selected exactly 715b5439 and no
-- other row. It is reproduced in the trailing `--` VERIFICATION block at the end of this file.
-- After apply: `CALL ops.sp_auto_resolve_alerts()` closes 715b5439 with a resolved_note beginning
-- "auto-resolved: beat recovered". The 'auto-resolved:' prefix is load-bearing: alert_emailer.gs labels a
-- resolved row [AUTO-RESOLVED] only when resolved_note startsWith('auto-resolved:').
--
-- ============================================================================
-- ops.sp_auto_resolve_alerts -- SUPERSEDES the definition in bigquery/148_audit_2026_08_08_fixes.sql
-- (chain: 94 -> 97 -> 107 -> 130 -> 134 -> 148 -> 249). Rules 1-5 are byte-identical to bigquery/148;
-- Rule 6 is new. Do NOT re-apply bigquery/148, 134, 130, 107, 97, 94, 78 or 34's CREATE of this
-- procedure live in isolation -- that would silently remove Rule 6.
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
END;

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Rule 6's predicate as a SELECT (same shape as the UPDATE; the stale set is a subquery here because a
--    bare SELECT cannot DECLARE). Expect ZERO rows once alert 715b5439 is resolved, and on 2026-09-30
--    before the first post-apply resolver call EXACTLY ONE row, 715b5439-3d31-436b-8d30-9453d9794a99:
--    SELECT alert_id, message
--    FROM `stock-trading-498512.ops.alerts`
--    WHERE NOT resolved AND category = 'scheduled_query_stale' AND severity = 'warning'
--      AND ARRAY_LENGTH(JSON_QUERY_ARRAY(payload)) >= 1
--      AND NOT EXISTS (
--        SELECT 1 FROM UNNEST(JSON_QUERY_ARRAY(payload)) AS e
--        WHERE JSON_VALUE(e, '$.sq_name') IS NULL
--           OR JSON_VALUE(e, '$.sq_name') IN (
--                SELECT sq_name FROM `stock-trading-498512.state.scheduled_query_version_drift`
--                WHERE stale_beat OR never_beat_overdue)
--           OR JSON_VALUE(e, '$.sq_name') NOT IN (
--                SELECT sq_name FROM `stock-trading-498512.state.scheduled_query_version_drift`
--                WHERE sq_name IS NOT NULL));
--
-- 2. After CALL ops.sp_auto_resolve_alerts(): the row is closed by this rule.
--    SELECT alert_id, resolved, LEFT(resolved_note, 60) FROM `stock-trading-498512.ops.alerts`
--    WHERE alert_id = '715b5439-3d31-436b-8d30-9453d9794a99';
--    (expect resolved = TRUE, note beginning 'auto-resolved: beat recovered').
--
-- 3. The live body carries Rule 6 and still carries Rules 1-5: run scripts/check_live_sql_parity.py.

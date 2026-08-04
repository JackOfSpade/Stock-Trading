-- 134_roster_change_notifications.sql (2026-08-04)
-- Project: stock-trading-498512. Apply AFTER 130_missing_dependency_alias_resolve.sql.
--
-- SUPERSEDES bigquery/130's definition of ops.sp_auto_resolve_alerts (adds Rule 5) and bigquery/75's
-- definition of ops.sp_sq_fire_drill_alert_lifecycle (adds the third drill + SQ_VERSION v3), and ONLY
-- those two objects. Every other object in 130 and 75 is UNCHANGED and deliberately NOT re-issued here
-- -- per bigquery/47's header rule, re-applying an old file's CREATE in isolation is the exact action
-- that caused the 47 regression.
--
-- ============================ WHY ============================
-- OWNER DIRECTIVE 2026-08-04: "although i let ai dictate when to add/drop strategies, i still want to be
-- notified by email when it does so."
--
-- Strategy add/delete has been fully autonomous since the 2026-07-10 SISA conversion, and stays that way
-- -- this file adds NO approval step, NO gate, and NO human touchpoint to the add/delete path. It closes
-- a pure OBSERVABILITY hole: the roster could change without the owner ever being told.
--
-- MEASURED 2026-08-04, before this change:
--   * SL5 raised its three roster-membership events at severity='info'
--     (strategy_shadow_registered / strategy_adopted / strategy_deregistered), as did SL4
--     (retirement_proposed) and SL1 (roster_below_floor).
--   * ops/monitoring/alert_emailer.gs selects `severity IN ('critical','warning')` (SEVERITIES const)
--     and scripts/alert_relay.py selects `severity IN ('critical','warning')` -- BOTH filter info out.
--   * Therefore an info-severity roster change reached NO push channel at all. Confirmed empirically:
--     every severity='info' row ever written to ops.alerts has notified_ts IS NULL. Zero exceptions,
--     across the whole live history of the table.
--   * The PROBE->ADOPTED transition (the 30-trade graduation gate, M4 section H) raised NO alert of any
--     severity -- the one roster event with no record in ops.alerts whatsoever.
--   * ops/RUNBOOK.md section 39 told the owner to "watch for the info-severity strategy_adopted /
--     retirement rows in ops.alerts" -- describing a pull that could only ever work by going looking,
--     and bigquery/36's seed asserted those rows were "delivered by alert_emailer.gs", which was false.
--
-- The fix is severity, not a new channel: raise the six roster-MEMBERSHIP categories at 'warning' so the
-- already-proven, already-deduped 2-hourly emailer delivers them. The full contract (which categories,
-- which payload keys, why not 'critical') lives in the Claude_Task_Plan.md shared preamble under
-- ROSTER-CHANGE NOTICES, so every routine slice carries it.
--
-- ============================ WHY 'warning' AND NOT 'critical' ============================
-- Verified statically across bigquery/ + dbt/models/, and live against INFORMATION_SCHEMA.VIEWS /
-- .ROUTINES (no drift): EVERY trading gate counts severity='critical' ONLY --
--   state.trading_enabled / state.trading_enabled_mechanical : COUNTIF(NOT resolved AND severity='critical' ...)
--   state.system_health.all_green                            : COUNTIF(NOT resolved AND severity='critical')
--   ops.sp_assert_trading_enabled(_mechanical)               : read the two views above
--   analytics.fn_order_guard(_options)                       : does not read ops.alerts at all
-- A 'warning' is structurally incapable of halting order staging. A 'critical' would halt it on every
-- healthy autonomous roster change -- which is why these MUST NOT be raised at 'critical'.
-- Precedent: consumption-closure CC-7 (2026-07-16) bumped immediate_action_flagged and
-- process_scorecard_signal info->warning for this identical reason.
--
-- ============================ WHY RULE 5 EXISTS ============================
-- A bare severity bump would leave every roster notice open forever: ops.alert_policy is a fail-closed
-- allowlist, so a category absent from it is latching by construction and needs a human UPDATE. Over
-- years that turns the notification channel into board noise, and CC-7 had to pair its own bump with an
-- auto-age entry for exactly this reason.
--
-- Rule 5 resolves a roster notice when, and only when, `notified_ts IS NOT NULL` -- i.e. the moment the
-- email was actually delivered. This is a mechanically-verified condition, not an age-out:
-- ops.alerts.notified_ts has exactly ONE writer in the entire system, alert_emailer.gs's
-- stampNotified_(), which runs only after a successful GmailApp.sendEmail (grepped across bigquery/,
-- scripts/, and *.gs to confirm exclusivity; alert_relay.py deliberately does not write it, and
-- sp_sq_delivery_canary only leaves it NULL for the emailer to stamp).
--
-- That exclusivity gives the design a free dead-man's switch, and it is the reason this rule is better
-- than a timer: an OPEN roster notice means "the owner has not been told yet." If the emailer dies, the
-- notice stays open and visible instead of quietly ageing away. Fail-closed in the direction that
-- matters.
--
-- ============================ SCOPE (residual, deliberate) ============================
-- Six categories only, all roster-MEMBERSHIP changes. Deliberately NOT included: candidate generation /
-- qualification / rejection culls (SL1 rejected F, G and H in 2026-08 with zero roster impact) and the
-- zero-capital SHADOW->PAPER promotion. Those stay info-severity audit rows in ops.alerts, queryable via
-- events.strategy_lifecycle and the weekly W5 arsenal-digest. Rationale: at the rails' rate limits (one
-- adoption per rolling 90 days, k_incubate=2, cooldowns) the six chosen categories total roughly 5-12
-- emails/year, which stays readable. Adding candidate churn would roughly quadruple it with events that
-- never touch the owner's money -- and an ignored channel notifies nobody.
--
-- ADDING A SEVENTH CATEGORY LATER requires BOTH: a row in ops.alert_policy (Part 1) AND the literal in
-- Rule 5's IN list (Part 2). The policy row alone is inert -- it makes a category eligible in principle,
-- but no code path computes an eligible_* array for it. This mirrors how all four existing rules work.

-- =====================================================================================================
-- PART 1 -- ops.alert_policy: register the six roster-change notices as NON-LATCHING.
-- Table created in bigquery/34_alert_lifecycle.sql; this file only INSERTs, never re-creates it.
-- Guarded so re-applying this file is a no-op (the repo-wide idempotency discipline).
-- Kept FIRST, ahead of every CREATE in this file: check_sql_dryrun.py's documented blind spot is that a
-- leading DDL statement suppresses BigQuery's semantic analysis of everything after it in the same
-- script dry-run, so the one statement that benefits most from real column resolution goes first.
-- The `SELECT * FROM UNNEST([...])` shape (rather than `SELECT <literals> WHERE NOT EXISTS`) is required:
-- a WHERE with no FROM is illegal GoogleSQL and is what broke bigquery/133 live.
-- =====================================================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT('strategy_shadow_registered' AS category, FALSE AS latching,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent' AS resolve_rule,
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). SL5: a candidate entered SHADOW and was added to strategy/roster.yaml. Zero capital at risk; spec frozen. Notification-only -- resolves on delivery, never needs a human UPDATE.' AS note),
  STRUCT('strategy_probe_registered', FALSE,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent',
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). SL5: PAPER->PROBE, the first time an autonomously-adopted strategy takes REAL capital. Renamed from strategy_adopted on 2026-08-04 -- that name fired here, at PROBE registration, while ADOPTED is a strictly later state reached at the 30-trade gate, so the old category name would have told the operator a strategy had graduated when it had merely taken its first stake. Safe to rename: SL5 had never fired, so no historical ops.alerts row carries the old value.'),
  STRUCT('strategy_graduated', FALSE,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent',
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). M4 section H: PROBE->ADOPTED, the 30-trade gate cleared on post-tax/post-inflation excess >= 0. NEW category -- this transition previously raised no alert of any severity, so the single moment a strategy proved itself and moved to full sizing had no operator-facing signal at all.'),
  STRUCT('retirement_proposed', FALSE,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent',
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). SL4: ADOPTED->RETIREMENT_PROPOSED on edge decay / redundancy / dominated-by-newcomer / probe-stuck. A pending drop; AR_orc adjudicates with conservative default KEEP.'),
  STRUCT('strategy_deregistered', FALSE,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent',
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). SL5: the canonical strategy-was-dropped event -- roster.yaml marked retired after a TERMINATED lifecycle row. Distinct from the critical termination_close_staged tap, which is about CONFIRMING a liquidating order, not about the roster losing a member.'),
  STRUCT('roster_below_floor', FALSE,
         'ops.alerts.notified_ts IS NOT NULL -- stamped by alert_emailer.gs stampNotified_ once the operator email is sent',
         'ROSTER-CHANGE NOTICE (owner directive 2026-08-04). SL1: the active roster is at the n_min=2 floor and successor-candidate generation has been forced. Structural health of the arsenal.')
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` ap WHERE ap.category = p.category
);

-- =====================================================================================================
-- PART 2 -- ops.sp_auto_resolve_alerts: SUPERSEDES bigquery/130.
-- Rules 1, 2, 3, 3b and 4 below are copied BYTE-IDENTICAL from bigquery/130's committed body (verified
-- against the live INFORMATION_SCHEMA.ROUTINES text before copying). The ONLY change is the new Rule 5
-- and its eligible_roster_notice declaration.
-- =====================================================================================================
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
        OR (JSON_VALUE(payload, '$.marks_fresh') = 'true'                    -- echo: freshness was already green at raise time
            AND JSON_VALUE(payload, '$.engine_fresh') = 'true')
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
  SET eligible_roster_notice = (
    SELECT ARRAY_AGG(alert_id)
    FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved
      AND category IN ('strategy_shadow_registered', 'strategy_probe_registered', 'strategy_graduated',
                       'retirement_proposed', 'strategy_deregistered', 'roster_below_floor')
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND notified_ts IS NOT NULL
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: roster-change notice delivered to the operator (notified_ts stamped by alert_emailer.gs); notification-only alert, nothing to act on (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_roster_notice, []));
END;

-- =====================================================================================================
-- PART 3 -- ops.sp_fire_drill_roster_notice (NEW): proves the Rule 5 path in BOTH directions.
--
-- Mirrors the sp_fire_drill_alert_resolve pattern (synthetic row -> call the real resolver -> assert ->
-- ALWAYS clean up -> raise a critical on failure, log a completed run on success), but two-phase,
-- because Rule 5's condition has a before and an after on the SAME row rather than needing a separate
-- run_log fixture:
--   PHASE 1  notified_ts IS NULL      -> the notice MUST stay open   (delivery has not happened)
--   PHASE 2  notified_ts stamped      -> the notice MUST clear       (delivery happened)
-- A drill that only tested phase 2 would pass even if Rule 5 resolved everything unconditionally, which
-- would silently destroy the undelivered-notice-stays-visible property the header argues for.
--
-- The synthetic row carries payload.synthetic = TRUE, which alert_emailer.gs v5's isTest_ recognizes --
-- so in the millisecond-wide race where a 2-hourly poll lands mid-drill, the operator sees a row plainly
-- tagged TEST rather than a fabricated "strategy ZZ entered PROBE" notice.
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_roster_notice`()
BEGIN
  DECLARE test_id STRING DEFAULT GENERATE_UUID();
  DECLARE drill_date DATE DEFAULT CURRENT_DATE('America/Denver');
  DECLARE held_before_delivery BOOL;
  DECLARE cleared_after_delivery BOOL;

  -- (a) synthetic roster-change notice, NOT yet delivered.
  INSERT INTO `stock-trading-498512.ops.alerts` (alert_id, severity, source, category, message, payload)
  VALUES (test_id, 'warning', 'ops.sp_fire_drill_roster_notice', 'strategy_probe_registered',
    CONCAT('FIRE DRILL — roster-change-notice delivery test (synthetic, auto-cleaned) id=', test_id),
    PARSE_JSON(TO_JSON_STRING(STRUCT(
      TRUE AS synthetic, test_id AS drill_id,
      'ZZ' AS strategy_code, 'FIRE DRILL synthetic strategy' AS strategy_name,
      'PAPER' AS from_state, 'PROBE' AS to_state))));

  -- (b) PHASE 1 — undelivered MUST stay open.
  CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  SET held_before_delivery = (
    SELECT NOT resolved FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id);

  -- (c) simulate alert_emailer.gs stampNotified_ having sent the email.
  UPDATE `stock-trading-498512.ops.alerts`
  SET notified_ts = CURRENT_TIMESTAMP()
  WHERE alert_id = test_id;

  -- (d) PHASE 2 — delivered MUST now clear.
  CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  SET cleared_after_delivery = (
    SELECT resolved FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id);

  -- (e) ALWAYS clean up the synthetic row, whatever the verdict.
  DELETE FROM `stock-trading-498512.ops.alerts` WHERE alert_id = test_id;

  -- (f) verdict
  IF NOT COALESCE(held_before_delivery, FALSE) OR NOT COALESCE(cleared_after_delivery, FALSE) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_roster_notice', 'roster_notice_fire_drill_failed',
      CONCAT('The roster-change-notice fire drill FAILED (held_before_delivery=',
             CAST(COALESCE(held_before_delivery, FALSE) AS STRING),
             ', cleared_after_delivery=', CAST(COALESCE(cleared_after_delivery, FALSE) AS STRING),
             '). Strategy add/drop notifications may be silently undelivered or silently self-clearing before delivery. Investigate ops.sp_auto_resolve_alerts Rule 5 and ops.alert_policy before trusting the roster-change email channel.'),
      TO_JSON_STRING(STRUCT(test_id AS drill_id,
                            COALESCE(held_before_delivery, FALSE) AS held_before_delivery,
                            COALESCE(cleared_after_delivery, FALSE) AS cleared_after_delivery)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`('FIRE_DRILL_ROSTER_NOTICE', drill_date, 'completed', NULL, NULL, 1, NULL,
      'Roster-change notice correctly stayed open while undelivered and auto-resolved once notified_ts was stamped.');
  END IF;
END;

-- =====================================================================================================
-- PART 4 -- ops.sp_sq_fire_drill_alert_lifecycle: SUPERSEDES bigquery/75's definition.
-- Body copied verbatim from bigquery/75 with TWO changes: SQ_VERSION v2 -> v3, and the new
-- sp_fire_drill_roster_notice call. No other drill logic changed.
-- Runs monthly (~06:20 UTC on the 1st) via the frozen one-line console body in
-- bigquery/scheduled_queries/fire_drill_alert_lifecycle.sql -- that file needs NO re-paste, since it
-- already just CALLs this wrapper.
-- The matching expected-version bump lives in bigquery/63_scheduled_query_version_registry.sql; apply
-- that MERGE too, or state.scheduled_query_version_drift reports a drift on the next cadence_check
-- (self-healing since bigquery/111 added the category to the #14 auto-age list, but avoidable noise).
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_fire_drill_alert_lifecycle`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:fire_drill_alert_lifecycle', 'v3', 'fire_drill_alert_lifecycle.sql ran');
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_latch`();
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_resolve`();
  CALL `stock-trading-498512.ops.sp_fire_drill_roster_notice`();
END;

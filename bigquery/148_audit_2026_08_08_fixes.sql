-- 148_audit_2026_08_08_fixes.sql (2026-08-08)
-- Project: stock-trading-498512. Five surgical fixes from a canonical-SQL audit of live objects
-- (each object's canonical body was pulled and re-read against its own stated behavior). Every
-- statement below is a byte-for-byte copy of the object's CURRENT canonical definition with exactly
-- one targeted edit -- nothing else in any of the five bodies is reformatted, reworded, or reordered.
-- Apply after bigquery/18_stack_review_fixes.sql, 30_confirm_attestation.sql,
-- 68_cash_flows_backfill_check_dated.sql, 134_roster_change_notifications.sql,
-- 143_adversarial_review_correction_path.sql -- the five files whose canonical bodies this supersedes.
--
-- REGISTRY NOTE: none of the five objects below is in the bigquery/63 scheduled-query version registry
-- (that registry only tracks ops.sp_sq_* wrapper procedures via SQ_VERSION heartbeats -- verified by
-- grep against 63's body: the only hit for these five names is a passing prose mention of
-- sp_auto_resolve_alerts inside an unrelated comment, not a registry row). So this file has NO co-apply
-- MERGE / version-bump requirement the way bigquery/147 does for ops.sp_sq_cadence_check.
--
-- ===== WHY (one paragraph per statement) =====
-- STATEMENT 1 (state.staged_without_confirm, bigquery/30): the view re-filters state.open_orders with
-- `WHERE o.status = 'pending'`, a case-sensitive comparison. state.open_orders itself (bigquery/01)
-- filters on `LOWER(status) = 'pending'` but projects the RAW status column, so a row physically written
-- as 'PENDING' or 'Pending' passes into open_orders yet is silently dropped by this view's
-- case-sensitive re-filter -- defeating D3's confirm_event_gap early-warning entirely for that row, with
-- no error and no alert.
--
-- STATEMENT 2 (state.cash_flows_backfill_check, bigquery/68): `reconciled` is a bare equality over
-- `SUM(amount)`. SUM over zero matching rows is NULL, not zero, so if the backfill rows were ever fully
-- deleted, `reconciled` reads NULL rather than FALSE. The consumer (cadence_check's
-- cash_flows_backfill_broken raise) tests `WHERE NOT reconciled`; `NOT NULL` is NULL, the row is
-- silently dropped from the result set, and the alert never raises -- so this check fails OPEN in
-- exactly the total-loss corruption case. A partial corruption (some rows survive, SUM is a real wrong
-- number) still correctly flips `reconciled` to FALSE, which is why this has gone unnoticed.
--
-- STATEMENT 3 (state.stalled_runs, bigquery/18): the hand-maintained `cls` UNNEST table enumerates every
-- routine the view classifies, and is INNER JOINed via `JOIN cls c USING (routine)` -- so any routine id
-- absent from the table is dropped before the terminal-row anti-join or the elapsed-hours threshold are
-- ever evaluated. OPS0, OPS1 and OPS2 are all in ops/cadence.yaml and all log 'started' rows via
-- ops.sp_routine_start, but none is in `cls` (last edited 2026-07-10; OPS0/OPS1/OPS2 were created
-- 2026-07-15 / 2026-07-19 / 2026-07-27, all after that edit). A hung OPS0/OPS1/OPS2 therefore never
-- raises routine_stalled, no matter how long it hangs.
--
-- STATEMENT 4 (ops.sp_auto_resolve_alerts, bigquery/134): Rule 4's staleness echo arm re-validates only
-- 2 of the 4 conditions the alert can be raised on. ops.sp_sq_daily_freshness_check raises 'staleness'
-- when `NOT (marks_fresh AND engine_fresh AND embeddings_healthy AND NOT position_drift_detected)`, with
-- payload = TO_JSON_STRING(state.system_health) -- but the echo arm only re-checks marks_fresh and
-- engine_fresh. So an alert raised because embeddings_healthy=FALSE (or position_drift_detected=TRUE)
-- carries a payload where marks_fresh/engine_fresh are BOTH 'true', and auto-resolves on the very next
-- run while the real fault persists. This is the ONLY ops.alerts channel that surfaces
-- embedding_health.is_healthy=FALSE at critical severity during routine cadence checks -- a real
-- resolve-path defect (HIGH), not a cosmetic one.
--
-- STATEMENT 5 (ops.sp_score_cross_model_referee, bigquery/143): the "already scored" guards key on
-- review_id + role only, with no cycle_number term, so the referee scores a case once and never
-- re-evaluates it after AR_orc returns REVISION REQUIRED and SL2 re-drafts (routine, up to a documented
-- soft cap of 5 cycles). Its sibling ops.sp_score_theater, defined in the SAME bigquery/143 file, is
-- already cycle-aware (`COALESCE(tj.cycle_number, -1) >= p.cycle_number`); this statement mirrors that
-- exact idiom onto both of sp_score_cross_model_referee's guards, which were dormant only because none
-- of its four gated review_types had reached a second cycle yet (HIGH).
--
-- ===== KNOWN FOLLOW-UP OUTSIDE THIS FILE'S SCOPE (documented, not applied here) =====
-- This drafting task was scoped to ONLY this new file -- no edits to bigquery/18, 30, 68, 134, 143, or
-- to scripts/. Two repo-convention gaps this creates, for whoever lands this file next:
--   (a) scripts/check_superseded_markers.py requires every NON-canonical prior definition of an object
--       to carry a "SUPERSEDED LIVE by bigquery/<canonical>" pointer in its own preceding comment/header
--       (see bigquery/142's ops.sp_sq_cadence_check banner pointing at bigquery/147 for the house
--       pattern). Once this file lands, bigquery/18 (state.stalled_runs), bigquery/30
--       (state.staged_without_confirm), bigquery/68 (state.cash_flows_backfill_check), bigquery/134
--       (ops.sp_auto_resolve_alerts) and bigquery/143 (ops.sp_score_cross_model_referee) each need a
--       one-line forward-pointing banner added atop their superseded CREATE statement, naming
--       bigquery/148, or the checker will report new violations for all five.
--   (b) scripts/check_superseded_by_discipline.py's ALLOWLIST has a key
--       ("143_adversarial_review_correction_path.sql", "ops.sp_score_cross_model_referee") explaining
--       why that procedure's outer duplicate-guard is allowed to read the raw events.adversarial_reviews
--       table instead of state.adversarial_reviews_current. Once bigquery/148 is canonical for that
--       object, that key goes stale (wrong filename) and needs to become
--       ("148_audit_2026_08_08_fixes.sql", "ops.sp_score_cross_model_referee") with the same reason --
--       Statement 5 below deliberately preserves the raw-table read on the outer guard, unchanged, for
--       the identical must-never-double-write reason the existing entry states.

-- ===== STATEMENT 1: state.staged_without_confirm (supersedes bigquery/30) =====
-- Copied verbatim from bigquery/30_confirm_attestation.sql with exactly one change: the case-sensitive
-- `o.status = 'pending'` filter below is wrapped in LOWER(), matching state.open_orders' own filter
-- (bigquery/01_schema.sql), so a row physically written as 'PENDING'/'Pending' is no longer silently
-- dropped from this view. See the WHY section above for the full defect.
-- state.staged_without_confirm — a pending staged order with either NO recent attestation (D3 has not
-- checked it in >30h, covering a skipped/failed D3 run) or an attestation that found no confirm event
-- (D3 checked and its own repair may itself have failed, e.g. a Calendar connector outage mid-run).
-- Self-bootstrapping (same philosophy as state.cadence_watch / state.stalled_runs): a row staged in the
-- last 30h is NEVER flagged here even with zero attestation history — it is simply too new for a D3
-- cycle to have reached it yet, which is expected, not a finding.
-- CRAFTABILITY SCOPING (2026-07-20, closes D3's 2026-07-19 confirm_event_gap finding 9dd23ed4): this
-- view predated the 2026-07-09 rescoping under which a CRAFTABLE order (equity/ETF/single-leg-options
-- instruction crafted via create_order_instruction) has NO confirm-order calendar event by design —
-- the instruction's own IBKR notification is its human confirm surface — so calendar attestation only
-- applies to NON-craftable (manual-entry) orders. The craftability marker is the recorded
-- payload.instruction_id (state.open_orders.instruction_id): a crafted order always records it at
-- staging (STAGING ATOMICITY gate), so its presence = craftable = exempt from calendar attestation.
-- Fail-closed on the interesting failure: a craft that never recorded an instruction_id (atomicity
-- breach, or a genuinely manual order) still flags here exactly as before. Liveness of the crafted
-- instruction itself is NOT this view's job — that is owned by D2a's registry reconciliation + D3's
-- instruction-verify/persist-and-wait re-craft (a DAY instruction expiring nightly is designed, not
-- drift).
CREATE OR REPLACE VIEW `stock-trading-498512.state.staged_without_confirm` AS
SELECT
  o.item_key, o.ticker, o.side, o.entry_window_close, o.staged_ts,
  c.snapshot_ts AS last_attested_ts,
  c.confirm_event_found,
  CASE
    WHEN c.snapshot_id IS NULL THEN 'never_attested'
    WHEN NOT c.confirm_event_found THEN 'confirm_event_missing'
    ELSE 'attestation_stale'
  END AS flag_reason
FROM `stock-trading-498512.state.open_orders` o
LEFT JOIN `stock-trading-498512.state.confirm_event_latest` c USING (item_key)
WHERE LOWER(o.status) = 'pending'
  AND o.instruction_id IS NULL   -- craftability scoping (2026-07-20): see header note above
  AND o.staged_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR)
  AND (c.snapshot_id IS NULL
       OR NOT c.confirm_event_found
       OR c.snapshot_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR));

-- ===== STATEMENT 2: state.cash_flows_backfill_check (supersedes bigquery/68) =====
-- Copied verbatim from bigquery/68_cash_flows_backfill_check_dated.sql with exactly one change: the
-- `reconciled` column's bare equality is wrapped in COALESCE(..., FALSE) so a SUM over zero matching
-- rows (NULL) reads as broken (FALSE) instead of NULL. See the WHY section above for the full defect --
-- `WHERE NOT reconciled` silently drops a NULL row, so the total-loss corruption case previously raised
-- no alert at all.
-- Date-scoped redefinition of state.cash_flows_backfill_check (consumption-closure audit 2026-07-16,
-- CC-3). Project: stock-trading-498512. Apply after 22_cash_flows.sql.
--
-- WHY: bigquery/22_cash_flows.sql's original state.cash_flows_backfill_check compares the SUM of
-- ALL events.cash_flows rows to the 9446.86 backfill-seed literal -- an apply-time gate meant to be
-- read once, by hand, right after the 2026-07-03 backfill landed. It was never wired to anything
-- automated, and it CANNOT be wired as-written: any future legitimate deposit/withdrawal (a single
-- INSERT per Operating_Protocols.md §13.C) would immediately flip `reconciled` to FALSE forever, so
-- polling it from cadence_check.sql would false-fire on ordinary account activity. This redefinition
-- DATE-SCOPES the comparison to `flow_date <= DATE '2026-07-03'` (the backfill's own effective date) so
-- it keeps testing exactly what it always tested -- "did the 2026-07-03 backfill reproduce the
-- pre-existing $9,446.86 total exactly" -- while becoming safe to poll nightly: a backdated, duplicate,
-- or typo'd flow dated on/before the cutover (which WOULD corrupt the NAV baseline every downstream
-- consumer relies on) still flips it to FALSE, but a legitimate future deposit provably cannot, since
-- it is dated after the cutover and excluded from the SUM by construction.
--
-- VERIFIED LIVE 2026-07-16: zero events.cash_flows rows exist with flow_date > 2026-07-03, so the
-- scoped and unscoped totals are identical (both 9446.86) as of this file's creation -- this
-- redefinition is semantics-preserving on apply day, not a silent behavior change.
--
-- Same view name as bigquery/22_cash_flows.sql's CREATE OR REPLACE VIEW (retroactive-redefine
-- convention, same pattern as bigquery/18/19_stack_review_fixes*.sql) -- this file's body is the
-- one that should be live after both are applied in order.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flows_backfill_check` AS
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
   WHERE flow_date <= DATE '2026-07-03') AS cash_flows_total_asof_backfill,
  CAST(9446.86 AS NUMERIC) AS expected_total,
  COALESCE((SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
            WHERE flow_date <= DATE '2026-07-03') = CAST(9446.86 AS NUMERIC), FALSE) AS reconciled;

-- ===== STATEMENT 3: state.stalled_runs (supersedes bigquery/18) =====
-- Copied verbatim from bigquery/18_stack_review_fixes.sql with exactly one change: three new STRUCT
-- entries (OPS0, OPS1, OPS2) added to the `cls` UNNEST table at the 6-hour tier, placed directly after
-- the D1/D2a/D2/D3 line since OPS0/OPS1/OPS2 are same-day daily-ops routines of the same shape. See the
-- WHY section above -- without an entry here, `JOIN cls c USING (routine)` drops these three routines
-- before the stall check ever runs, so a hung OPS0/OPS1/OPS2 can never raise routine_stalled.
-- (marginal) state.stalled_runs — a routine logged 'started' but never a terminal status.
-- A session that dies AFTER sp_routine_start but BEFORE sp_routine_end (the documented §20 abnormal-end
-- mode: usage-limit cutoff / container reclamation) leaves a stuck 'started' row that NOTHING reads — the
-- completed-run landing check (OPS0 STEP 4(f)) keys on status='completed' and is structurally blind to it.
-- (This line used to cite "the §17 stranded-session detector"; Operating_Protocols.md §17 was RETIRED
--  2026-07-29 as orphaned prose that was never wired into any routine. OPS0 STEP 4(f) is its successor.)
--
-- 2026-06-28 stack review #2 (#11): GENERALIZED beyond D1/D2/D3 to all run-logged routines via a per-class
-- min_stale_hours table (mirrors trigger_attestation's cls CTE), with the lookback widened from 3→7 days so
-- a low-frequency 'started' row does not age out before it crosses its threshold. This keys off each
-- routine's OWN logged 'started' row (no calendar prediction), so it cannot false-fire on an inferred
-- trigger-day — the concern that originally limited it to the daily set. Previously a weekly/monthly/
-- quarterly/annual or AR session that died after start could sit unnoticed for up to a full cadence period
-- (the only backstop was trigger_attestation's coarse 14/70/200/400-day windows). Warning, record-only.
CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS
WITH cls AS (
  -- fast tier (~6h): daily, adversarial, and action-conversion routines (same-day work).
  -- slow tier (~18h): deep-research weeklies/monthlies/quarterlies/annuals (longer legitimate runtime).
  -- AR ids are ASCII AR_att/AR_orc (2026-07-01, RUNBOOK §28), matching ops/cadence.yaml + the plan table.
  -- (This threshold table joins ops.run_log by EXACT id — USING(routine) — so future AR runs must self-log
  -- the ASCII id to be classified here; legacy middle-dot 'started' rows age out of the 7-day window.)
  -- D2a (added 2026-07-03, self-improvement audit WO-3): NOT YET ACTIVE, no live web-UI trigger yet;
  -- listed here so once it starts logging it is already correctly classified fast-tier.
  SELECT * FROM UNNEST([
    STRUCT('D1' AS routine, 6 AS min_stale_hours), STRUCT('D2a', 6), STRUCT('D2', 6), STRUCT('D3', 6),
    -- OPS0/OPS1/OPS2 added (2026-08-08 audit of the 2026-08-08 canonical bodies): all three are in
    -- ops/cadence.yaml and log 'started' rows via ops.sp_routine_start, but this table was last edited
    -- 2026-07-10, before OPS0/OPS1/OPS2 existed (created 2026-07-15/07-19/07-27) — so a hung OPS0/OPS1/
    -- OPS2 never raised routine_stalled no matter how long it hung.
    STRUCT('OPS0', 6), STRUCT('OPS1', 6), STRUCT('OPS2', 6),
    STRUCT('AR_att', 6), STRUCT('AR_orc', 6),
    STRUCT('W4', 6), STRUCT('M4', 6), STRUCT('Q4', 6), STRUCT('A3', 6),
    -- SISA fast tier (rev 2026-07-10): SL3 daily monitor, SL4 monthly scanner, SL5 registrar — all
    -- same-day work (no multi-hour deep research), so a >6h 'started' with no terminal row is stalled.
    STRUCT('SL3', 6), STRUCT('SL4', 6), STRUCT('SL5', 6),
    STRUCT('W1', 18), STRUCT('W2', 18), STRUCT('W3', 18), STRUCT('W5', 18),
    STRUCT('M1a', 18), STRUCT('M1b', 18), STRUCT('M2', 18), STRUCT('M3', 18), STRUCT('M5', 18),
    STRUCT('Q1', 18), STRUCT('Q2', 18), STRUCT('Q3', 18),
    STRUCT('A1', 18), STRUCT('A2', 18),
    -- SISA slow tier (rev 2026-07-10): SL1 quarterly deep-research synthesis + SL2 authoring/revision
    -- are legitimately long-running (like the deep-research weeklies/monthlies), so 18h before stalled.
    STRUCT('SL1', 18), STRUCT('SL2', 18)
  ])
),
started AS (
  SELECT routine, run_date, MAX(log_ts) AS last_started_ts
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'started'
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
  GROUP BY routine, run_date
),
terminal AS (
  SELECT DISTINCT routine, run_date
  FROM `stock-trading-498512.ops.run_log`
  WHERE status IN ('completed', 'failed', 'halted')
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
)
SELECT
  s.routine, s.run_date, s.last_started_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.last_started_ts, HOUR) AS hours_since_started,
  c.min_stale_hours,
  CURRENT_TIMESTAMP() AS checked_at
FROM started s
JOIN cls c USING (routine)   -- classify (and bound to) known routines; an unknown id is not flagged
LEFT JOIN terminal t USING (routine, run_date)
WHERE t.routine IS NULL
  AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.last_started_ts, HOUR) >= c.min_stale_hours;

-- ===== STATEMENT 4: ops.sp_auto_resolve_alerts (supersedes bigquery/134) =====
-- Copied verbatim from bigquery/134_roster_change_notifications.sql with exactly one change: Rule 4's
-- staleness echo arm now re-checks all FOUR components state.system_health's staleness raise condition
-- depends on (marks_fresh, engine_fresh, embeddings_healthy, position_drift_detected) instead of just
-- the first two. Confirmed live against `SELECT TO_JSON_STRING(t) FROM state.system_health t` on
-- 2026-08-08: the payload keys are exactly marks_fresh, engine_fresh, embeddings_healthy and
-- position_drift_detected (all four spelled as expected below; no rename needed). See the WHY section
-- above for the full defect.
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
END;

-- ===== STATEMENT 5: ops.sp_score_cross_model_referee (supersedes bigquery/143) =====
-- Copied verbatim from bigquery/143_adversarial_review_correction_path.sql with exactly one change:
-- both "already scored" guards now carry a cycle_number term, mirroring the exact idiom this file's
-- sibling ops.sp_score_theater already uses (`COALESCE(tj.cycle_number, -1) >= p.cycle_number`). Without
-- this, the referee scored a review_id once and never re-evaluated it after AR_orc returned REVISION
-- REQUIRED and SL2 re-drafted at a later cycle_number (routine, up to a documented soft cap of 5
-- cycles) -- dormant only because none of the four gated review_types had reached a second cycle yet.
-- The outer guard's raw-table read (events.adversarial_reviews, not state.adversarial_reviews_current)
-- is preserved UNCHANGED and on purpose: it must refuse to insert a second referee_gemini row when ANY
-- referee row exists for that (review_id, role, cycle) — superseded or not — which is strictly more
-- conservative than reading the filtered view, exactly as bigquery/143's own header for this statement
-- already argued.
-- ============================================================================
-- (5) ops.sp_score_cross_model_referee -- SUPERSEDES the definition in bigquery/44_cross_model_referee.sql.
-- Changes from bigquery/44: reads state.adversarial_reviews_current; the attacker candidate set is
-- reduced to ONE row per review_id (newest cycle) by QUALIFY, closing the duplicate-referee_gemini
-- path. Both original idempotency guards are preserved verbatim (inner NOT EXISTS avoids re-billing
-- Gemini; outer NOT EXISTS on (review_id, role) is unchanged), and it remains INSERT-only -- no MERGE
-- -- so it still cannot trip state.append_only_integrity (bigquery/44's 2026-07-20 fix, preserved).
-- The Gemini prompt text is byte-identical to bigquery/44's.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_cross_model_referee`()
BEGIN
  INSERT INTO `stock-trading-498512.events.adversarial_reviews`
    (review_id, role, review_type, strategy, review_date, cycle_number, verdict, theater_check, weaknesses, artifact_path, body_md)
  SELECT
    S.review_id, S.role, S.review_type, S.strategy, S.review_date, S.cycle_number, S.verdict, S.theater_check, S.weaknesses, S.artifact_path, S.body_md
  FROM (
    SELECT
      g.review_id, 'referee_gemini' AS role, g.review_type, g.strategy, g.review_date, g.cycle_number,
      g.verdict_out AS verdict,
      CAST(NULL AS STRING) AS theater_check,
      TO_JSON(STRUCT(g.reasoning AS reasoning)) AS weaknesses,
      CAST(NULL AS STRING) AS artifact_path,
      g.reasoning AS body_md
    FROM AI.GENERATE_TABLE(
      MODEL `stock-trading-498512.ops.gemini`,
      (
        SELECT a.review_id, a.review_type, a.strategy, a.review_date, a.cycle_number,
          CONCAT(
            'You are an INDEPENDENT cross-model referee for a capital-binding autonomous-trading-system ',
            'decision. You have NOT seen any other reviewer opinion or verdict -- form your own from ',
            'first principles against the case below only. Return the SAME verdict vocabulary the review ',
            'type uses (SUFFICIENT/INSUFFICIENT for strategy-adoption; RETIRE/KEEP for strategy-retirement; ',
            'TERMINATE/CONTINUE/CONSTRAINT_RELAXATION for foundation-change-assessment; ',
            'ACTIVATE/DO-NOT-ACTIVATE/HYBRID for divergence-review). Begin your answer with the single ',
            'verdict token. Default on genuine ',
            'ambiguity: ',
            CASE a.review_type
              WHEN 'strategy-adoption' THEN 'INSUFFICIENT (reject)'
              WHEN 'strategy-retirement' THEN 'KEEP'
              WHEN 'divergence-review' THEN 'DO-NOT-ACTIVATE (keep the new-entry block)'
              ELSE 'CONTINUE' END,
            '.\n\nReview type: ', a.review_type,
            '\n\n=== CASE (attacker submission only -- no orchestrator text shown) ===\n',
            SUBSTR(COALESCE(a.body_md,''), 1, 6000)
          ) AS prompt
        FROM `stock-trading-498512.state.adversarial_reviews_current` a
        WHERE a.role = 'attacker'
          AND a.review_type IN ('strategy-adoption','strategy-retirement','foundation-change-assessment','divergence-review')
          AND NOT EXISTS (
            SELECT 1 FROM `stock-trading-498512.state.adversarial_reviews_current` r
            WHERE r.review_id = a.review_id AND r.role = 'referee_gemini'
              AND COALESCE(r.cycle_number, -1) >= a.cycle_number)
        -- ONE attacker row per review_id (newest cycle). Without this, two attacker rows sharing a
        -- review_id both pass the outer NOT EXISTS below -- which is evaluated against the
        -- pre-statement snapshot and so cannot see its own sibling inserts -- and two referee_gemini
        -- rows land for one review. Same idiom state.strategy_retirement_readiness's referee CTE
        -- already uses, applied at the WRITE path instead of only at a downstream read path.
        QUALIFY ROW_NUMBER() OVER (PARTITION BY a.review_id ORDER BY a.cycle_number DESC, a.event_ts DESC) = 1
      ),
      STRUCT('verdict_out STRING, reasoning STRING' AS output_schema, 0.0 AS temperature)
    ) g
  ) S
  WHERE NOT EXISTS (
    SELECT 1 FROM `stock-trading-498512.events.adversarial_reviews` T
    WHERE T.review_id = S.review_id AND T.role = S.role
      AND COALESCE(T.cycle_number, -1) >= S.cycle_number
  );
END;

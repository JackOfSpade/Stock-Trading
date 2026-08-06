-- Stack-review fixes (2026-06-24). Project: stock-trading-498512.
-- Additive, idempotent BigQuery objects implementing the verified deltas from the
-- 2026-06-24 stack review (ops/RUNBOOK.md §25). NOTHING here changes an existing object's
-- behaviour — only NEW views + two additive ALTER ADD COLUMN IF NOT EXISTS. Apply via the
-- BigQuery MCP execute_sql AFTER 09/10/12/15/16; and BEFORE re-pasting the scheduled queries
-- cadence_check.sql (references state.trigger_attestation / state.stalled_runs /
-- state.position_reconciliation / state.market_calendar_horizon) and the NEW integrity_check.sql
-- (references state.append_only_integrity).
--
-- Contents:
--   B2  ops.backup_log.per_table_rows         — per-table source row counts in the backup marker
--   B3  state.append_only_integrity           — out-of-band UPDATE/DELETE/MERGE on events.* (governance)
--   B4  state.position_reconciliation          — current_positions vs position_lifecycle open-share drift
--   D2  state.trigger_attestation              — a low-frequency routine whose trigger went silent (deleted)
--   D3  state.go_without_order                 — a GO decision that never produced a staged order/fill
--   (marginal) state.stalled_runs              — a DAILY routine 'started' but never logged a terminal status
--   (marginal) state.market_calendar_horizon   — calendar runway left (FMP auto-extend liveness)
--   (marginal) state.embedding_scale_watch     — decision_log proximity to the 5k VECTOR INDEX threshold
--   (marginal) ops.alerts.notified_ts          — make "was the human told?" a queryable fact

-- ============================================================================
-- B2 — record per-table source row counts in the backup marker.
-- Additive column on ops.backup_log (16_automation_health.sql). The daily export
-- (scheduled_queries/backup_events_export.sql) now writes a {table: rows} JSON here, so a
-- backup marker carries the same row-count evidence the restore drill asserts — auditable
-- day-over-day and a forensic anchor for the §3 restore path. CREATE TABLE IF NOT EXISTS in
-- 16 will NOT add a column to a pre-existing table, so this explicit ALTER is the upgrade path.
-- ============================================================================
ALTER TABLE `stock-trading-498512.ops.backup_log` ADD COLUMN IF NOT EXISTS per_table_rows JSON;

-- ============================================================================
-- (marginal) ops.alerts.notified_ts — make "was the human told?" a queryable fact instead of
-- hidden Apps Script Script Properties. The out-of-session relay / alert_emailer stamps it on a
-- successful send and CLEARS it on resolve, preserving the intentional re-fire-on-reopen design.
-- ============================================================================
ALTER TABLE `stock-trading-498512.ops.alerts` ADD COLUMN IF NOT EXISTS notified_ts TIMESTAMP;

-- ============================================================================
-- B3 — state.append_only_integrity (data-governance dead-man's switch).
-- The IMMUTABLE AUDIT TRAIL (decisions/outcomes/lifecycle) must be INSERT-only — corrections are new
-- rows + superseded_by (RUNBOOK §21). This view surfaces any completed UPDATE/DELETE/MERGE/TRUNCATE job
-- that touched one of those AUDIT-TRUTH tables in the last 2 days, turning the prose invariant into a
-- detected-within-a-day tripwire (integrity_check.sql records a warning on it). Empty result = clean.
--
-- SCOPE — audit-truth tables ONLY (NOT all of events.*). Verified live (2026-06-24) that the
-- REFERENCE / MARKET-DATA feeds are legitimately maintained by in-place DML BY DESIGN and must NOT be
-- flagged: events.market_holidays via MERGE (the W5 FMP calendar auto-extend, RUNBOOK §8 / bigquery/09),
-- events.daily_marks via DELETE+re-insert (a day's marks re-ingest; consumers read the curated dedup
-- view). macro_fred / macro_series are likewise refreshed feeds. So the watch-list is the decision /
-- position / trade / queue / review / parking / capability streams, where immutability is the invariant.
--
-- The ONE sanctioned exception WITHIN the watch-list (RUNBOOK §21): an in-place UPDATE of ONLY
-- decision_log.sub_pattern by W5 (the taxonomy owner), recorded with an old→new audit trail in
-- B_Sub_Pattern_Taxonomy.md — suppressed below.
--
-- POSTURE: integrity_check.sql records this as a WARNING (delivered via the emailer/relay), NOT a
-- critical RAISE — a staged rollout (like dbt-parity advisory→block) so a heuristic false positive on a
-- novel monitor cannot flip all_green / storm the DTS email. Promote to critical+RAISE once a clean
-- baseline is confirmed.
--
-- CAVEATS (documented, accepted): (1) reading JOBS_BY_PROJECT (all identities' jobs) needs
-- bigquery.jobs.listAll — granted via roles/bigquery.resourceViewer on the integrity_check run-as SA
-- (job METADATA only, not data; RUNBOOK §25). (2) JOBS gives statement_type + destination/target
-- reliably but not always the exact modified-column set, so the W5 sub_pattern suppression is a
-- query-text heuristic (an unusual WHERE clause naming an immutable column could false-positive — a
-- resolvable warning, not a halt). (3) a Storage-Write-API mutation would not surface as a DML job —
-- acceptable, the live write path is INSERT-DML via the MCP. (4) JOBS_BY_PROJECT retains ~180 days, so
-- this detects forward, never retroactively (a tripwire, not a forensic log).
CREATE OR REPLACE VIEW `stock-trading-498512.state.append_only_integrity` AS
SELECT
  job_id,
  user_email,
  statement_type,
  destination_table.dataset_id AS target_dataset,
  destination_table.table_id   AS target_table,
  creation_time,
  end_time,
  SUBSTR(query, 0, 400) AS query_preview
FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
  AND state = 'DONE'
  AND error_result IS NULL
  AND statement_type IN ('UPDATE', 'DELETE', 'MERGE', 'TRUNCATE_TABLE')
  AND destination_table.dataset_id = 'events'
  -- AUDIT-TRUTH watch-list only (reference/market-data feeds deliberately excluded — see header).
  AND destination_table.table_id IN (
    'decision_log', 'position_events', 'trade_fills', 'regime_events',
    'queue_events', 'adversarial_reviews', 'parking_events', 'hf_capability_captures'
  )
  -- Suppress the ONE sanctioned exception: an UPDATE that sets ONLY decision_log.sub_pattern, on a
  -- day W5 (the taxonomy owner) logged a completed run. Anything else — any other column, any other
  -- watched table, any DELETE/MERGE/TRUNCATE — is a violation.
  AND NOT (
    statement_type = 'UPDATE'
    AND destination_table.table_id = 'decision_log'
    AND REGEXP_CONTAINS(query, r'(?i)set\s+sub_pattern\s*=')
    AND NOT REGEXP_CONTAINS(query,
          r'(?i)set[\s\S]*\b(decision|conviction|conviction_pct|body_md|title|entry_type|entry_date|strategy|ticker|fields|refs|tags|theater_check)\b\s*=')
    AND EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.run_log` r
      WHERE r.routine = 'W5' AND r.status = 'completed'
        AND r.run_date = DATE(creation_time, 'America/Denver')
    )
  );

-- ============================================================================
-- B4 — state.position_reconciliation (open-position drift guard).
-- Two independent open-position representations exist: state.current_positions (← events.position_events,
-- hand-written by D2; the path analytics.strategy_nav / 2%-sizing reads) and analytics.position_lifecycle
-- (← authoritative state.trade_fills_curated; the path the TWR engine / §13 read). They can diverge with
-- NO existing monitor watching position_events. This flags a MATERIAL per-(strategy,ticker) open-share
-- difference; the tolerance ignores sub-cent dividend-reinvest fractional shares (the live ~$0.20 drift).
-- Latest-wins leg-splits are handled by SUM on both sides.
--
-- NOTE (2026-07-27): the "Advisory (warning), NOT part of all_green" wording this block used to carry
-- had been stale since 2026-07-03, when bigquery/23_trading_control.sql:402-434 (self-improvement audit
-- B-5-exec / B-6-data) promoted `drifted` to a BLOCKING term of state.system_health.all_green — and
-- thus of state.trading_enabled. It is not advisory; it halts trading.
--
-- SUPERSEDED LIVE by bigquery/126_dust_operational_hardening.sql (2026-08-02) — current single
-- source of truth for this view. 126 retains 110's pending-order-aware predicate and additionally
-- excludes audited dust lots. 110 keeps this predicate verbatim as `drifted_raw` and redefines
-- `drifted` to measure the residual AFTER netting a (strategy,ticker)'s still-working BUY quantity from
-- state.open_orders, because the comparison below is structurally guaranteed to fire on any
-- staged-but-unfilled BUY (state.current_positions is written at ORDER-STAGING time;
-- analytics.position_lifecycle only ever sees FILLED shares). Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation — doing so
-- reintroduces the 2026-07-26 self-latching trading halt.
-- NOTE: this marker supersedes ONLY state.position_reconciliation. Every other object defined in this
-- file is still canonical here.
CREATE OR REPLACE VIEW `stock-trading-498512.state.position_reconciliation` AS
WITH cp AS (
  SELECT strategy, ticker, SUM(shares) AS current_positions_shares
  FROM `stock-trading-498512.state.current_positions`
  WHERE strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
lc AS (
  SELECT strategy, ticker, SUM(shares) AS lifecycle_open_shares
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE exit_date IS NULL AND strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
)
SELECT
  strategy,
  ticker,
  COALESCE(cp.current_positions_shares, 0) AS current_positions_shares,
  COALESCE(lc.lifecycle_open_shares, 0)    AS lifecycle_open_shares,
  COALESCE(cp.current_positions_shares, 0) - COALESCE(lc.lifecycle_open_shares, 0) AS share_diff,
  -- tolerance 0.01 share: ignores fractional dividend-reinvest noise; catches a whole position
  -- present in one representation but not the other (a real 2%-sleeve position is >0.1 share).
  ABS(COALESCE(cp.current_positions_shares, 0) - COALESCE(lc.lifecycle_open_shares, 0)) > 0.01 AS drifted,
  CURRENT_TIMESTAMP() AS checked_at
FROM cp FULL OUTER JOIN lc USING (strategy, ticker);

-- ============================================================================
-- D2 — state.trigger_attestation (deleted-trigger detector for low-frequency routines).
-- state.instruction_drift fires only AFTER a routine runs (drift = edited trigger); a silently
-- DELETED trigger produces NO run and NO drift signal. state.cadence_watch ALARMS only the daily
-- routines (weekly/monthly/quarterly/annual are "visible, not alarmed"). So a deleted W/M/Q/A trigger
-- can go unnoticed for up to a full cadence period — the worst case for the un-versioned-trigger SPOF
-- (RUNBOOK §15). This flags a calendar-predictable routine that has logged NO completed run across a
-- window sized to its cadence. SELF-BOOTSTRAPPING: monitored = it has EVER completed (a routine that
-- never adopted run-logging never alarms; it arms itself the first time it logs).
CREATE OR REPLACE VIEW `stock-trading-498512.state.trigger_attestation` AS
WITH cls AS (
  -- max_gap_days ≈ ~2 cadence periods (annual ≈ 1 year + slack). Coarse thresholds, NOT exact
  -- schedules, so they do not need to track ops/cadence.yaml precisely. Daily routines are omitted
  -- (already alarmed by state.cadence_watch); AR_att/AR_orc are queue-driven (no calendar prediction).
  SELECT * FROM UNNEST([
    STRUCT('W1'  AS routine,  14 AS max_gap_days), STRUCT('W2', 14), STRUCT('W3', 14),
    STRUCT('W4', 14),                              STRUCT('W5', 14),
    STRUCT('M1a', 70), STRUCT('M1b', 70), STRUCT('M2', 70), STRUCT('M3', 70),
    STRUCT('M4', 70),  STRUCT('M5', 70),
    STRUCT('SL4', 70),   -- SL4 monthly discretionary-retirement scanner (rev 2026-07-10 — SISA)
    STRUCT('Q1', 200), STRUCT('Q2', 200), STRUCT('Q3', 200), STRUCT('Q4', 200),
    STRUCT('SL1', 200),   -- SL1 quarterly candidate synthesis/qualification (rev 2026-07-10 — SISA). SL3 is
                          -- daily (already alarmed by cadence_watch) and SL2/SL5 are queue-driven (no
                          -- calendar prediction), so — like the daily/AR routines — they are omitted here.
    STRUCT('A1', 400), STRUCT('A2', 400), STRUCT('A3', 400)
  ])
),
lastrun AS (
  SELECT routine, MAX(run_date) AS last_completed
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
  GROUP BY routine
),
td AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  c.routine,
  c.max_gap_days,
  l.last_completed,
  td.today,
  DATE_DIFF(td.today, l.last_completed, DAY) AS days_since_completed,
  (l.last_completed IS NOT NULL) AS monitored,
  COALESCE(l.last_completed IS NOT NULL
           AND DATE_DIFF(td.today, l.last_completed, DAY) > c.max_gap_days, FALSE) AS overdue,
  CURRENT_TIMESTAMP() AS checked_at
FROM cls c
CROSS JOIN td
LEFT JOIN lastrun l ON l.routine = c.routine;

-- ============================================================================
-- D3 — state.go_without_order (staging-completeness surface).
-- The registry-centric reconciliations (D2 Step-0, D3) walk FROM state.open_orders outward, so a GO
-- that ops.sp_log_decision wrote atomically but whose ORDER_STAGED row was never written (session died
-- mid-step) is invisible to them. This anchors on the GO decision instead: a recent GO with NO matching
-- staged-order row AND no fill. Surfacing-only — D3 (the routine) adjudicates each candidate (a GO can be
-- analytical / deferred), and raises go_without_order only for a genuine missing order (RUNBOOK §25 / D3).
--
-- SUPERSEDED LIVE by bigquery/144_decision_log_correction_consumers.sql — current single source of
-- truth for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. Two later changes are missing from the definition
-- below: (a) the 2026-07-25 catch-up-window rework (owner directive) anchored the window to D3's own
-- last completed ops.run_log run, floored at this file's original ~36h/2-day lookback via GREATEST,
-- instead of the fixed 2-day cutoff below — re-applying this would silently reintroduce the
-- missed-catch-up gap that rework exists to close; (b) 144 DELETES the `AND superseded_by IS NULL`
-- line below, which is EXACTLY BACKWARDS (it keeps the OBSOLETE row and drops the CORRECTION — see
-- bigquery/122:43) and which the 2026-07-25 rework copied forward verbatim.
CREATE OR REPLACE VIEW `stock-trading-498512.state.go_without_order` AS
WITH go_decisions AS (
  SELECT entry_id, entry_date, strategy, ticker, entry_type, title
  FROM `stock-trading-498512.events.decision_log`
  WHERE decision = 'GO'
    AND superseded_by IS NULL
    AND entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 2 DAY)
)
SELECT
  g.entry_id, g.entry_date, g.strategy, g.ticker, g.entry_type, g.title,
  CURRENT_TIMESTAMP() AS checked_at
FROM go_decisions g
-- no staged order references this decision (by ref, else by ticker+strategy on/after the decision day).
-- DATE(..., 'America/Denver') — NOT the bare (UTC-default) form — because g.entry_date is the
-- Denver OPERATING day decision_log stamps; a bare UTC date is always >= the Denver date, so an
-- order/fill actually staged the PRIOR Denver evening (>=~17:00 MT = already the next UTC day) could
-- wrongly satisfy this match and suppress a genuine go-without-order candidate (false negative only;
-- 2026-07 report-system fix).
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.queue_events` q
  WHERE q.queue = 'ORDER_STAGED'
    AND (JSON_VALUE(q.payload, '$.source_decision_ref') = g.entry_id
         OR (q.ticker = g.ticker AND q.strategy = g.strategy AND DATE(q.event_ts, 'America/Denver') >= g.entry_date))
)
-- and no fill recorded for that strategy/ticker on/after the decision day
AND NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.trade_fills` f
  WHERE f.ticker = g.ticker AND f.strategy = g.strategy
    AND DATE(f.fill_ts, 'America/Denver') >= g.entry_date
);

-- ============================================================================
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

-- ============================================================================
-- (marginal) state.market_calendar_horizon — calendar runway + FMP auto-extend liveness.
-- W5 auto-extends events.market_holidays from the FMP connector when the horizon falls within ~120
-- days (RUNBOOK §8). FMP is otherwise rarely exercised, so this is its one cheap liveness signal: if
-- the trading-calendar horizon DROPS BELOW the auto-extend trigger and STAYS there, the auto-extend
-- (hence likely the FMP grant) is failing — an EARLY warning, well before the calendar exhausts and the
-- freshness COALESCE→FALSE backstop trips. Advisory; cadence_check warns when runway < 100 days.
CREATE OR REPLACE VIEW `stock-trading-498512.state.market_calendar_horizon` AS
WITH h AS (
  SELECT MAX(cal_date) AS calendar_through
  FROM `stock-trading-498512.state.market_calendar`
),
td AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  h.calendar_through,
  td.today,
  DATE_DIFF(h.calendar_through, td.today, DAY) AS days_of_runway,
  -- warn well below the ~120-day auto-extend trigger, so this only fires once W5's FMP extend has
  -- demonstrably failed to keep ahead (not on a single missed extend).
  COALESCE(DATE_DIFF(h.calendar_through, td.today, DAY) < 100, TRUE) AS runway_low,
  CURRENT_TIMESTAMP() AS checked_at
FROM h, td;

-- ============================================================================
-- (marginal) state.embedding_scale_watch — proximity to the 5,000-row VECTOR INDEX threshold.
-- analytics.decision_embeddings deliberately has no VECTOR INDEX (BigQuery needs ≥5,000 rows; brute
-- force over ~250 rows is instant — 02_ai_layer.sql). At ~1 entry/day the threshold is ~13 years out,
-- so this is a near-free advisory mirroring state.gate_watch — a SIGNAL to revisit the index + the §23
-- chunking work rather than relying on memory. Watch-only, NOT part of all_green.
-- CHUNKING FIX (self-improvement audit B-8-data, 2026-07-03): the 5,000-row VECTOR INDEX threshold
-- applies to analytics.decision_embeddings (the table VECTOR_SEARCH scans), which now holds MULTIPLE
-- chunk rows per decision_log entry (RUNBOOK §23) -- tracking decision_log's row count alone
-- understated how close the searched table is to the threshold (825 embedding rows vs 289 decision_log
-- rows at the 2026-07-03 cutover, a ~2.85x ratio). Track the embeddings table directly.
-- ORPHAN-DOC (self-improvement audit 2026-07-16 cleanup pass): advisory, cited by RUNBOOK passes,
-- no scheduled reader by design -- not orphaned, just human-read rather than machine-polled.
CREATE OR REPLACE VIEW `stock-trading-498512.state.embedding_scale_watch` AS
WITH n AS (SELECT COUNT(*) AS decision_log_rows FROM `stock-trading-498512.events.decision_log`),
e AS (SELECT COUNT(*) AS embedding_rows FROM `stock-trading-498512.analytics.decision_embeddings`)
SELECT
  n.decision_log_rows,
  e.embedding_rows,
  5000 AS vector_index_threshold,
  GREATEST(0, 5000 - e.embedding_rows) AS rows_to_index_threshold,
  e.embedding_rows >= 4000 AS approaching_index_threshold,
  CURRENT_TIMESTAMP() AS checked_at
FROM n, e;

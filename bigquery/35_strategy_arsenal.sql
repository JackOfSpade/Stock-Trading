-- Self-Improving Strategy Arsenal (SISA) — autonomous strategy-lifecycle substrate (rev 2026-07-10 —
-- Strategy Arsenal autonomy conversion, owner directive). Project: stock-trading-498512.
--
-- WHY: on 2026-07-10 the owner directed that strategy addition/deletion become COMPLETELY AUTONOMOUS —
-- no human review/approval/chat anywhere in the path (residuals allowed: the system-wide IBKR order-
-- confirm tap + deposits). This file is the BigQuery home for every object the five new lifecycle
-- routines (SL1 synthesise/qualify, SL2 author/revise/post-mortem, SL3 incubation monitor/graduation,
-- SL4 discretionary retirement, SL5 register/roster-sync) read and write. It reuses, verbatim, the D2a
-- autonomous-cutover skeleton (bigquery/32_d2a_cutover_readiness.sql): an OBJECTIVE readiness view +
-- a durable BigQuery idempotency marker (ops.roster_change_log, the ops.d2a_cutover_log analog) + a
-- self-execute repo commit + an info-severity audit alert — never a chat question (RUNBOOK §36; the
-- "chat is unmonitored" invariant honoured throughout). The owner kill-switch (ops.arsenal_control +
-- ops.sp_assert_arsenal_enabled) is the exact analog of the trading-halt gate
-- (ops.trading_control / ops.sp_assert_trading_enabled, bigquery/23_trading_control.sql).
--
-- IMMUTABILITY REFRAME (Experiment_Parameters.md:6, immutability_rewrite): roster MEMBERSHIP becomes
-- VERSIONED POLICY (the roster analog of the 2026-06 capital-allocation pivot); each strategy's own
-- machinery stays immutable for its life, FROZEN AT SHADOW ENTRY (spec_locked_since) so the forward
-- test measures a fixed ruleset, with the official edge-measurement clock (immutable_since) starting at
-- its first PROBE trade. strategy/roster.yaml is the checked-in single source of truth; this file's
-- event-sourced events.strategy_lifecycle -> state.strategy_roster -> state.active_strategy_codes chain
-- is the runtime read surface; scripts/check_roster_consistency.py (CI) asserts they never disagree.
--
-- APPLY ORDER (CRITICAL — read before a DR rebuild). This file depends ONLY on objects created in
-- 01_schema.sql, 03_twr_engine.sql, 09_market_calendar.sql, 10_observability.sql and
-- 21_strategy_vs_park.sql, so it is applied AFTER 21. But 22_cash_flows.sql and 26_process_metrics.sql
-- are REFACTORED to read state.active_strategy_codes / state.strategy_roster defined HERE, so on a full
-- rebuild this file MUST be applied BEFORE (re-)applying 22 and 26 — i.e. the sequence is 01..21, then
-- 35, then 22, 23, ..., 34. The live BigQuery-MCP apply order is: 12,15,18,24,31,35 THEN 22,26 (seed
-- the roster rows below FIRST so the refactored views return the identical founding A-E set on first
-- read — verified via dbt-parity EXCEPT-DISTINCT + check_roster_consistency). Idempotent (CREATE OR
-- REPLACE / CREATE TABLE IF NOT EXISTS / guarded seed INSERT); safe to re-run.

-- ============================================================================
-- events.strategy_lifecycle — append-only transition log (the single audit trail + idempotency
-- substrate; mirrors events.regime_events -> state.current_regime). Every roster transition is exactly
-- one row, written by exactly one driver routine against exactly one objective readiness view.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.strategy_lifecycle` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  strategy_code STRING NOT NULL,
  from_state STRING,
  -- to_state domain: CANDIDATE|QUALIFYING|AUTHORING|UNDER_REVIEW|SHADOW|PAPER|PROBE|ADOPTED|
  --                  RETIREMENT_PROPOSED|TERMINATED|POST_MORTEM|REJECTED
  to_state STRING NOT NULL,
  driver_routine STRING,               -- SL1..SL5 / D1 / Q1 / Q3 / A1 / backfill
  review_id STRING,                    -- events.adversarial_reviews.review_id for review-gated transitions
  git_commit STRING,
  material_structural_difference STRING,
  evidence_json JSON,
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY DATE(event_ts) CLUSTER BY strategy_code, to_state
OPTIONS(description='Append-only strategy-lifecycle transition log (SISA, 2026-07-10). Latest row per strategy_code = state.strategy_roster. A transition NEVER advances on judgment or a chat question — always on an objective readiness view + an ops.roster_change_log idempotency row.');

-- Seed the five founding strategies A-E as ADOPTED at experiment start (2026-04-23). state.strategy_roster
-- derives spec_locked_since / immutable_since / adopted_date from this history (all = 2026-04-23 for the
-- founding batch, since they have only an ADOPTED row). This seed MUST land before 22/26 are refactored
-- so the roster-derived enumeration returns exactly {A,B,C,D,E} on first read (roster_single_source
-- bootstrapping). check_roster_consistency.py asserts this seed set == strategy/roster.yaml active set
-- == Strategy.md '## Strategy' sections == strategy/ slices == the plan slice-map rows.
--
-- NOT a one-time-only block (rev 2026-07-10b, bug fix — code-review finding #2). check_roster_consistency.py
-- R-A parses THIS FILE's text to determine the "seed" side of that comparison; the LIVE events.
-- strategy_lifecycle table is not queryable from CI. So every subsequent SL5 adoption/termination MUST
-- append its own guarded, idempotent INSERT here (same NOT-EXISTS shape as the founding batch below) in
-- the SAME commit that updates strategy/roster.yaml — see Claude_Task_Plan.md SL5 steps (2)/(3). Without
-- that append, R-A permanently disagrees for the new/retired code and the adoption/termination commit can
-- never reach green CI / auto-merge. This section is therefore an append-only historical ledger mirror of
-- events.strategy_lifecycle, not a founding-only bootstrap.
INSERT INTO `stock-trading-498512.events.strategy_lifecycle`
  (event_ts, strategy_code, from_state, to_state, driver_routine, note)
SELECT TIMESTAMP(DATE '2026-04-23'), code, CAST(NULL AS STRING), 'ADOPTED', 'seed-2026-07-10',
  'Founding-batch seed (SISA conversion, 2026-07-10): the five live strategies were ADOPTED at experiment inception 2026-04-23. spec_locked_since / immutable_since / adopted_date all resolve to 2026-04-23 for these rows.'
FROM UNNEST(['A','B','C','D','E']) AS code
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.strategy_lifecycle` WHERE driver_routine = 'seed-2026-07-10');

-- ============================================================================
-- ops.arsenal_control — owner kill-switch (analog of ops.trading_control). A single out-of-band INSERT
-- freezes candidate generation / graduation / retirement WITHOUT disturbing live trading. Append-only,
-- latest row wins. incubation_frozen halts SHADOW/PAPER/PROBE promotions but leaves ADOPTED strategies
-- (and their mechanical kills) untouched.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.arsenal_control` (
  control_id STRING DEFAULT GENERATE_UUID(),
  control_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  enabled BOOL NOT NULL,               -- FALSE = SL1..SL5 abort at their sp_assert_arsenal_enabled gate
  incubation_frozen BOOL NOT NULL,     -- TRUE = SL1..SL5 ALSO abort at the shared gate (candidate
                                        --   generation, graduation, AND retirement-candidacy all stop;
                                        --   fixed rev 2026-07-10b, code-review finding #3 — the shared
                                        --   gate previously checked only `enabled`, not this column)
  reason STRING,
  set_by STRING,                       -- 'operator' | routine id
  PRIMARY KEY (control_id) NOT ENFORCED
) PARTITION BY DATE(control_ts)
OPTIONS(description='Append-only arsenal kill-switch (SISA, 2026-07-10; analog of ops.trading_control). Latest row by control_ts wins (state.arsenal_enabled). Seeded enabled=TRUE / incubation_frozen=FALSE so the loop starts in a known-open state; flip with a manual INSERT.');

-- Seed exactly once so the table is never empty (state.arsenal_enabled fails SAFE — disabled — if it ever is).
INSERT INTO `stock-trading-498512.ops.arsenal_control` (enabled, incubation_frozen, reason, set_by)
SELECT TRUE, FALSE, 'Initial seed — Strategy Arsenal loop authorised at active_auto by the 2026-07-10 owner directive.', 'seed-2026-07-10'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.arsenal_control`);

-- state.arsenal_enabled — latest control row, never zero rows (ARRAY_AGG single-row guarantee, same
-- defensive pattern as state.trading_enabled). Defaults FAIL-SAFE (enabled=FALSE / incubation_frozen=TRUE)
-- on an impossible empty table, so the loop can only run when explicitly enabled.
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(enabled, incubation_frozen, reason) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.arsenal_control`
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  COALESCE(ctrl.latest.incubation_frozen, TRUE) AS incubation_frozen,
  ctrl.latest.reason AS reason
FROM ctrl;

-- ops.sp_assert_arsenal_enabled — FATAL top-of-routine gate for SL1..SL5 (mirrors ops.sp_assert_trading_enabled).
-- CALL FIRST, unwrapped: a disabled OR incubation-frozen arsenal must abort the routine, raise + dedup a
-- single critical alert. BUG FIX (rev 2026-07-10b, code-review finding #3): the original version checked
-- only `enabled`, never `incubation_frozen`, contradicting its own documented contract (Claude_Task_Plan.md
-- SL1's "ARSENAL KILL-SWITCH GATE" text states it aborts on EITHER condition) and the header comment above
-- ("freezes candidate generation / graduation / retirement"). Only graduation was actually protected (via
-- the separate `arsenal_ok` component each of state.strategy_adoption_readiness / strategy_shadow_readiness /
-- strategy_paper_readiness computes) — SL1's candidate generation and SL4's retirement-candidacy generation
-- had no incubation_frozen check anywhere and would have continued regardless of the owner's freeze.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_arsenal_enabled`(in_routine STRING)
BEGIN
  DECLARE v_enabled BOOL;
  DECLARE v_incubation_frozen BOOL;
  DECLARE v_reason STRING;
  SET (v_enabled, v_incubation_frozen, v_reason) = (
    SELECT AS STRUCT enabled, incubation_frozen, reason FROM `stock-trading-498512.state.arsenal_enabled`
  );
  IF NOT v_enabled OR v_incubation_frozen THEN
    -- STABLE message text (not folding in in_routine / v_reason) so sp_raise_alert_once's exact-match
    -- dedup collapses a sustained disable to ONE alert across SL1..SL5 — same rationale as the
    -- trading_halted gate (23_trading_control.sql). The dynamic detail rides the payload + RAISE.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'arsenal_disabled',
      'Strategy Arsenal loop is DISABLED or INCUBATION-FROZEN (ops.arsenal_control). SL routine aborted. See payload for the routine, which condition fired, and reason.',
      TO_JSON_STRING(STRUCT(in_routine AS routine, v_enabled AS enabled, v_incubation_frozen AS incubation_frozen, v_reason AS reason)));
    RAISE USING MESSAGE = FORMAT(
      '%s: arsenal disabled or incubation-frozen (enabled=%t, incubation_frozen=%t, reason=%s) — SL routine aborted. Investigate state.arsenal_enabled / ops.arsenal_control before re-enabling.',
      in_routine, v_enabled, v_incubation_frozen, COALESCE(v_reason, 'unspecified'));
  END IF;
END;

-- ============================================================================
-- ops.roster_change_log — durable per-change idempotency marker (the ops.d2a_cutover_log analog).
-- Presence of a row for change_key = that roster transition is DONE, so SL5 can never double-apply a
-- fanout and no readiness view can re-fire a completed transition. change_key convention:
-- '<code>:<FROM>-><TO>' e.g. 'F:UNDER_REVIEW->SHADOW', 'F:PAPER->PROBE', 'F:ADOPTED->TERMINATED'.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.roster_change_log` (
  change_id STRING DEFAULT GENERATE_UUID(),
  change_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  change_key STRING NOT NULL,
  strategy_code STRING,
  from_state STRING,
  to_state STRING,
  git_commit STRING,
  note STRING,
  PRIMARY KEY (change_id) NOT ENFORCED
) PARTITION BY DATE(change_ts)
OPTIONS(description='Durable roster-transition idempotency markers (SISA, 2026-07-10; ops.d2a_cutover_log analog). One row per change_key = that transition already applied.');

-- ============================================================================
-- state.strategy_candidates — candidate intake registry (written by the scouting routines D1/Q1/Q3/A1
-- + SL1; SL1 qualifies/rejects). Carries derivation provenance for the anti-inheritance restart check.
-- A mutable registry (status flips NEW -> QUALIFYING -> PROMOTED|REJECTED), so a table, not a view.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.strategy_candidates` (
  candidate_code STRING NOT NULL,      -- provisional (e.g. 'F')
  source_routine STRING,               -- D1 | Q1 | Q3 | A1 | SL1
  status STRING,                       -- NEW | QUALIFYING | REJECTED | PROMOTED
  archetype STRING,
  cited_edges ARRAY<STRING>,           -- foundation edge refs (1.x)
  cited_disadvantages ARRAY<STRING>,   -- compensated Part-2 disadvantage refs (2.x)
  thesis_md STRING,
  instruments STRING,
  sizing_method STRING,
  kill_structure STRING,
  target_regime_cells ARRAY<STRING>,
  declared_frequency STRING,
  derivation_provenance JSON,          -- SL2 fresh-derivation record; SL1 anti-inheritance check reads it
  is_restart_of STRING,                -- terminated strategy_code this restarts, or NULL
  reject_reason STRING,
  cooldown_until DATE,
  created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) OPTIONS(description='Candidate intake registry (SISA, 2026-07-10). Written by D1/Q1/Q3/A1 + SL1; qualified/rejected by SL1 with default-REJECT on ambiguity.');

-- ADDITIVE MIGRATION (ITEM 9, 2026-07-11): a NUMERIC best-estimate of declared_frequency's prose, so
-- state.strategy_paper_readiness can be archetype-aware instead of hardcoding one trade-count bar that
-- structurally excludes low-turnover archetypes (Strategy D's 3-8 trades/yr counting entries+exits
-- separately implies ~1.5-4 closed round-trips/yr — the PAPER graduation gate could never be satisfied
-- inside any realistic window under the old single fixed threshold). NULL is the safe default: a
-- candidate SL1 could not estimate a frequency for falls back to the strict fast-archetype bar (>=10
-- trades) in the readiness view below, never the loosened slow-archetype path — fail-closed toward MORE
-- evidence required, not less. CREATE TABLE IF NOT EXISTS above is a no-op on an existing table, so this
-- ALTER is required for the column to actually land on a table created before this revision.
ALTER TABLE `stock-trading-498512.state.strategy_candidates`
  ADD COLUMN IF NOT EXISTS declared_annual_roundtrips FLOAT64;

-- ============================================================================
-- events.strategy_postmortems — structured termination post-mortems (SL2-authored). The precondition
-- for any restart: SL1 refuses a restart whose post-mortem is missing or silent on the structural diff.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.strategy_postmortems` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  strategy_code STRING NOT NULL,
  retired_date DATE,
  trigger STRING,                      -- drawdown | gate_fail | foundation_change | m2m | runaway | discretionary_retire
  what_revealed STRING,
  what_unresolved STRING,
  material_diff_required_for_restart STRING,
  body_md STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY retired_date CLUSTER BY strategy_code
OPTIONS(description='Structured termination post-mortems (SISA, 2026-07-10; SL2-authored). Enforces the material-structural-difference articulation that gates any SL1 restart.');

-- ============================================================================
-- events.shadow_positions — signals / simulated-fill ledger for SHADOW/PAPER strategies (mirrors
-- events.position_events, is_paper=TRUE). ZERO capital, ZERO orders — deliberately excluded from every
-- live capital / kill view (state.current_positions, analytics.strategy_nav, perf.*).
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.shadow_positions` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  strategy_code STRING NOT NULL,
  event_type STRING,                   -- OPEN | CLOSE | SIGNAL
  ticker STRING,
  shares NUMERIC,
  price NUMERIC,
  commission NUMERIC,                  -- modeled IBKR commission (PAPER only)
  is_paper BOOL DEFAULT TRUE,
  regime_cell STRING,
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY DATE(event_ts) CLUSTER BY strategy_code
OPTIONS(description='Signals / simulated-fill ledger for SHADOW/PAPER strategies (SISA, 2026-07-10). is_paper=TRUE; never touches live capital/kill views.');

-- ============================================================================
-- analytics.strategy_incubation_perf — daily forward-test series for SHADOW/PAPER strategies (SL3
-- maintains it). Reuses the value-weighted-TWR engine shape; a table (procedure-rebuilt), not a view.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.analytics.strategy_incubation_perf` (
  strategy_code STRING NOT NULL,
  phase STRING NOT NULL,               -- 'shadow' | 'paper'
  incubation_day DATE NOT NULL,
  sim_twr NUMERIC,                     -- simulated deployed-TWR-equivalent index
  sgov_twr NUMERIC,                    -- SGOV benchmark index over the same window
  excess NUMERIC,                      -- sim_twr / sgov_twr - 1
  peak_to_trough NUMERIC,              -- incubation drawdown
  sim_closed_trades INT64,             -- cumulative simulated closed round-trips (PAPER)
  signals_generated INT64,             -- cumulative would-be signals (SHADOW activity proxy)
  scaffolding_faults INT64,            -- classical-method / router scaffolding faults observed (SHADOW)
  regime_cell STRING,                  -- regime cell the day's simulated activity fell in
  computed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY incubation_day CLUSTER BY strategy_code, phase
OPTIONS(description='Daily SHADOW/PAPER forward-test series (SISA, 2026-07-10; SL3-maintained). Feeds the shadow/paper readiness views + arsenal_regime_coverage. Modeled commissions + conservative slippage vs SGOV in the paper phase.');

-- ============================================================================
-- state.strategy_roster — latest-row-per-code state view (mirrors state.current_regime). spec_locked_since
-- = first entry into the spec-frozen lifecycle (SHADOW onward); immutable_since = first PROBE/live trade;
-- adopted_date = first ADOPTED transition (NULL until adopted). is_active = PROBE|ADOPTED (touches
-- capital); is_incubating = SHADOW|PAPER (zero capital).
--
-- SUPERSEDED LIVE by bigquery/51_strategy_roster_dates_tz.sql (2026-07-14) — adopted_date/
-- retired_date below truncate event_ts to a bare UTC date, misdating any transition an SL5 evening
-- write logs during the Denver-UTC rollover window. 51 fixes the derivation (keyed off
-- driver_routine so the founding-batch seed rows are unaffected) while leaving every other column
-- unchanged. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_roster` AS
WITH latest AS (
  SELECT strategy_code, to_state AS current_state, event_ts AS state_since,
         driver_routine, review_id, git_commit
  FROM `stock-trading-498512.events.strategy_lifecycle`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY event_ts DESC, event_id DESC) = 1
),
stamps AS (
  SELECT strategy_code,
    MIN(IF(to_state IN ('SHADOW','PAPER','PROBE','ADOPTED'), event_ts, NULL)) AS spec_locked_since,
    MIN(IF(to_state IN ('PROBE','ADOPTED'), event_ts, NULL)) AS immutable_since,
    MIN(IF(to_state = 'ADOPTED', DATE(event_ts), NULL)) AS adopted_date,
    MAX(IF(to_state = 'TERMINATED', DATE(event_ts), NULL)) AS retired_date
  FROM `stock-trading-498512.events.strategy_lifecycle`
  GROUP BY strategy_code
)
SELECT
  l.strategy_code,
  l.current_state,
  l.current_state IN ('PROBE','ADOPTED') AS is_active,
  l.current_state IN ('SHADOW','PAPER')  AS is_incubating,
  s.spec_locked_since,
  s.immutable_since,
  s.adopted_date,
  s.retired_date,
  l.state_since,
  l.driver_routine,
  l.review_id,
  l.git_commit
FROM latest l JOIN stamps s USING (strategy_code);

-- state.active_strategy_codes — thin view the roster-derived enumeration sites read (bigquery/22,26 +
-- dbt strategy_nav). is_active = PROBE|ADOPTED.
CREATE OR REPLACE VIEW `stock-trading-498512.state.active_strategy_codes` AS
SELECT strategy_code
FROM `stock-trading-498512.state.strategy_roster`
WHERE is_active;

-- ============================================================================
-- state.arsenal_regime_coverage — regime-cell coverage matrix operationalising "ready to deploy into
-- any regime". SPY trend x VIX regime cross-product; a cell is COVERED by a strategy that DEMONSTRATED
-- positive paper excess in it (measured, not forecast — 2.14 recency guard). is_gap biases SL1 toward
-- zero-coverage cells and lets SL3's paper graduation fill a gap even with < k_regime positive cells.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_regime_coverage` AS
WITH cells AS (
  SELECT trend, vix, CONCAT(trend, '/', vix) AS regime_cell
  FROM UNNEST(['UPTREND','RANGE','DOWNTREND']) AS trend
  CROSS JOIN UNNEST(['LOW_VIX','ELEVATED_VIX','HIGH_VIX']) AS vix
),
demonstrated AS (
  SELECT p.strategy_code, p.regime_cell, LOGICAL_OR(p.excess >= 0) AS positive_excess
  FROM `stock-trading-498512.analytics.strategy_incubation_perf` p
  WHERE p.phase = 'paper' AND p.regime_cell IS NOT NULL
  GROUP BY p.strategy_code, p.regime_cell
),
cov AS (
  SELECT d.regime_cell,
    COUNTIF(r.is_active AND d.positive_excess) AS covered_active_count,
    COUNTIF(r.is_incubating AND d.positive_excess) AS covered_incubating_count
  FROM demonstrated d
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = d.strategy_code
  GROUP BY d.regime_cell
)
SELECT
  c.regime_cell, c.trend, c.vix,
  COALESCE(cov.covered_active_count, 0) AS covered_active_count,
  COALESCE(cov.covered_incubating_count, 0) AS covered_incubating_count,
  COALESCE(cov.covered_active_count, 0) = 0 AS is_gap
FROM cells c LEFT JOIN cov ON cov.regime_cell = c.regime_cell;

-- ============================================================================
-- state.arsenal_rails — computed anti-churn rail state (the roster.yaml rails block, mirrored here as
-- SQL constants and cross-checked by scripts/check_roster_consistency.py, exactly as the cadence
-- deadline literal is mirrored in 12_cadence_monitor.sql and checked by check_cadence_consistency.py).
-- One row. adoption_rate_window_days is inlined as 90 in the probes_in_window count below (same value).
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_rails` AS
WITH consts AS (
  SELECT
    2  AS n_min,                       -- roster floor (blocks SL4 below it; a hit forces SL1 generation)
    8  AS n_max,                       -- roster ceiling (~$10k account cost discipline)
    2  AS k_incubate,                  -- max concurrent SHADOW+PAPER strategies
    3  AS k_regime,                    -- regime-coverage target
    90 AS adoption_rate_window_days,   -- <= 1 PROBE per rolling 90 days
    90 AS reject_cooldown_days,
    180 AS terminate_cooldown_days,
    90 AS keep_cooldown_days
),
counts AS (
  -- single scan of state.strategy_roster for both counts (rev 2026-07-10b, cleanup, code-review finding #9;
  -- was two separate correlated subqueries each re-evaluating the whole view).
  SELECT
    (SELECT AS STRUCT COUNTIF(is_active) AS active_count, COUNTIF(is_incubating) AS incubating_count
       FROM `stock-trading-498512.state.strategy_roster`) AS roster,
    (SELECT COUNT(*) FROM `stock-trading-498512.events.strategy_lifecycle`
       WHERE to_state = 'PROBE'
         AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS probes_in_window
)
SELECT
  c.n_min, c.n_max, c.k_incubate, c.k_regime, c.adoption_rate_window_days,
  c.reject_cooldown_days, c.terminate_cooldown_days, c.keep_cooldown_days,
  n.roster.active_count AS active_count, n.roster.incubating_count AS incubating_count, n.probes_in_window,
  n.roster.active_count <= c.n_min      AS at_or_below_floor,
  n.roster.active_count >= c.n_max      AS at_ceiling,
  n.roster.incubating_count >= c.k_incubate AS incubation_cap_reached,
  n.probes_in_window = 0         AS adoption_window_open
FROM consts c CROSS JOIN counts n;

-- ============================================================================
-- Readiness views (one per autonomous transition, D2a pattern). Each returns a boolean `ready` = AND of
-- the objective rail components AND a NOT-EXISTS-later-state idempotency guard vs ops.roster_change_log,
-- plus arsenal_ok (kill-switch/incubation-freeze). Default-not-advance: a component that cannot be
-- computed reads FALSE, so the loop never advances on ambiguity.
-- ============================================================================

-- state.strategy_adoption_readiness — UNDER_REVIEW -> SHADOW. Clears on a SUFFICIENT strategy-adoption
-- orchestrator verdict (SL5 then inserts the SHADOW row + roster.yaml entry, spec-locking the strategy)
-- AND (ITEM 7, 2026-07-11) an objective theater-judge check that the orchestrator verdict was reached
-- independently, not an echo of the attacker's own text (bigquery/11_theater_judge.sql). Before this fix,
-- the exact mechanism built to catch adversarial-review rubber-stamping was never consulted by the ONE
-- gate it should most protect — a strategy could reach SHADOW off a self-certified-but-echo-suspect
-- review, days before W5's weekly audit ever inspected it. Fail-closed: a not-yet-scored review reads
-- theater_ok=FALSE (judge_independent defaults NULL/not-TRUE), so `ready` cannot fire on an unscored
-- review — SL5 calling ops.sp_score_theater() synchronously (Claude_Task_Plan.md SL5) is what clears this
-- in practice rather than waiting on W5's weekly cadence.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_adoption_readiness` AS
WITH latest_verdict AS (
  SELECT strategy AS strategy_code, verdict, review_id
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type = 'strategy-adoption' AND role = 'orchestrator'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, event_ts DESC) = 1
),
theater AS (
  SELECT review_id, judge_independent
  FROM `stock-trading-498512.analytics.theater_judge`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  v.verdict,
  v.verdict = 'SUFFICIENT' AS review_sufficient,
  COALESCE(t.judge_independent, FALSE) AS theater_ok,
  NOT rails.incubation_cap_reached AS caps_ok,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW')) AS not_already_transitioned,
  (v.verdict = 'SUFFICIENT'
   AND COALESCE(t.judge_independent, FALSE)
   AND NOT rails.incubation_cap_reached
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest_verdict v USING (strategy_code)
LEFT JOIN theater t ON t.review_id = v.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'UNDER_REVIEW';

-- state.strategy_shadow_readiness — SHADOW -> PAPER. min shadow trading days + signals generated within
-- band + zero scaffolding faults. min_shadow_trading_days = 20 (policy constant, added to
-- roster.yaml's rails block 2026-07-14 — this comment previously claimed it was already mirrored
-- there, which was false).
--
-- SUPERSEDED LIVE by bigquery/52_shadow_readiness_band.sql (2026-07-14) — signal_rate_ok below is a
-- bare floor (>= 1) with no upper bound despite being documented as a "band"; a strategy firing
-- hundreds of spurious signals in the 20-day window passes identically to one firing once. 52 adds
-- an archetype-aware ceiling (same declared_annual_roundtrips scaling as strategy_paper_readiness's
-- `freq` CTE). Kept here, unmodified, for DR-rebuild apply-in-order reference only.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_shadow_readiness` AS
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS shadow_days,
    SUM(signals_generated) AS signals_generated,
    SUM(scaffolding_faults) AS scaffolding_faults
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'shadow'
  GROUP BY strategy_code
),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.shadow_days, 0) AS shadow_days,
  COALESCE(a.signals_generated, 0) AS signals_generated,
  COALESCE(a.scaffolding_faults, 0) AS scaffolding_faults,
  COALESCE(a.shadow_days, 0) >= 20 AS days_met,
  COALESCE(a.signals_generated, 0) >= 1 AS signal_rate_ok,
  COALESCE(a.scaffolding_faults, 0) = 0 AS scaffolding_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER')) AS not_already_transitioned,
  (COALESCE(a.shadow_days, 0) >= 20
   AND COALESCE(a.signals_generated, 0) >= 1
   AND COALESCE(a.scaffolding_faults, 0) = 0
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN agg a USING (strategy_code)
CROSS JOIN ars
WHERE r.current_state = 'SHADOW';

-- state.strategy_paper_readiness — PAPER -> PROBE. >= ~60 paper trading days AND an ARCHETYPE-AWARE
-- simulated-closed-trade count AND SUSTAINED (not single-day) paper excess-vs-SGOV AND regime coverage
-- (>= 2 positive cells OR fills a zero-coverage arsenal gap) AND adoption-rate window open AND roster
-- below N_max.
--
-- FIX (ITEM 9, 2026-07-11): trades_met was a single hardcoded `>= 10` bar for every archetype. Strategy
-- D's own spec declares 3-8 trades/yr COUNTING ENTRIES+EXITS SEPARATELY (~1.5-4 closed round-trips/yr) —
-- at that pace, 10 closed round-trips takes ~2.5-6.5 YEARS, with no time-based cull, meaning SISA could
-- structurally never graduate a second D-like long-horizon candidate (exactly the defect D's own live spec
-- already documents making its 30-trade GATE "effectively inactive" — this recreated the same defect one
-- layer earlier). trades_met now scales the bar against state.strategy_candidates.declared_annual_
-- roundtrips: fast archetypes (NULL or >=10 declared round-trips/yr) keep the original `>=10` bar
-- unchanged; a declared slow archetype needs only `GREATEST(3, CEIL(declared_annual_roundtrips/2))` closed
-- round-trips — still a real bar (never below 3), just not a structurally-unreachable one. `stuck` (paired
-- with Claude_Task_Plan.md SL3's new PAPER time-cull) distinguishes "stuck" from "slow": paper_days >= 400
-- with trades_met still FALSE culls to REJECTED rather than occupying a k_incubate slot forever.
--
-- FIX (ITEM 8, 2026-07-11): excess_met read only the SINGLE MOST RECENT day's cumulative excess
-- (`ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 1)`), re-evaluated fresh by SL3 every day — a
-- candidate cumulative-negative for 59 of 60+ paper days could graduate to LIVE CAPITAL purely because SL3
-- happened to check on a day with a favorable mark. excess_met now requires the trailing 10 incubation
-- days to be ALL non-negative AND non-NULL (a NULL excess day, e.g. a missing sim_twr/sgov_twr input,
-- counts as a failure, not a skip — fail-closed) — a sustained-positive requirement, matching the
-- Wilson-interval small-sample discipline this codebase already applies elsewhere (analytics.
-- calibration_shrunk) instead of trusting a single lucky reading at the highest-stakes PAPER->PROBE gate.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_paper_readiness` AS
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS paper_days,
    MAX(sim_closed_trades) AS sim_closed_trades,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest_excess,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10) AS trailing_excess,
    ARRAY_LENGTH(ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10)) AS trailing_n
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper'
  GROUP BY strategy_code
),
positive_cells AS (
  SELECT strategy_code, COUNT(DISTINCT regime_cell) AS n_positive_cells
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper' AND excess >= 0 AND regime_cell IS NOT NULL
  GROUP BY strategy_code
),
gap_fill AS (
  SELECT DISTINCT p.strategy_code
  FROM `stock-trading-498512.analytics.strategy_incubation_perf` p
  JOIN `stock-trading-498512.state.arsenal_regime_coverage` c ON c.regime_cell = p.regime_cell
  WHERE p.phase = 'paper' AND p.excess >= 0 AND c.is_gap
),
freq AS (
  -- trades_threshold computed ONCE here (adversarial self-audit fix, rev 2026-07-11) — the same CASE
  -- expression used to be duplicated 4x below (trades_met_threshold, trades_met, stuck, ready), inviting
  -- silent divergence if only some copies were ever edited. Semantics-preserving; the frequency-scaled
  -- trade-count floor for a slow-cadence strategy (declared_annual_roundtrips < 10), floored at 3.
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS trades_threshold
  FROM `stock-trading-498512.state.strategy_candidates`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.paper_days, 0) AS paper_days,
  COALESCE(a.sim_closed_trades, 0) AS sim_closed_trades,
  a.latest_excess,
  fr.declared_annual_roundtrips,
  COALESCE(fr.trades_threshold, 10) AS trades_met_threshold,
  COALESCE(pc.n_positive_cells, 0) AS n_positive_cells,
  COALESCE(a.paper_days, 0) >= 60 AS days_met,
  COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10) AS trades_met,
  (COALESCE(a.trailing_n, 0) >= 10
   AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0) AS excess_met,
  (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL) AS regime_met,
  rails.adoption_window_open AS rate_limit_clear,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE')) AS not_already_transitioned,
  -- stuck (ITEM 9): paper_days has run long enough that trades_met should be assessed against the 400-day
  -- time-cull, independent of `ready` below — read by Claude_Task_Plan.md SL3 STEP 4, not itself a
  -- component of `ready` (a stuck candidate is culled to REJECTED, not promoted).
  (COALESCE(a.paper_days, 0) >= 400
   AND NOT COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)) AS stuck,
  (COALESCE(a.paper_days, 0) >= 60
   AND COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
   AND (COALESCE(a.trailing_n, 0) >= 10
        AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
   AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   AND rails.adoption_window_open
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN positive_cells pc USING (strategy_code)
LEFT JOIN gap_fill gf USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'PAPER';

-- state.strategy_retirement_candidacy — ADOPTED -> RETIREMENT_PROPOSED. Fires ONLY on an OBJECTIVE
-- sustained edge-decay signal (>= ~252 deployed days AND latest engine excess-vs-SGOV < 0), NEVER below
-- the N>=2 floor, respecting a per-strategy post-KEEP re-proposal cooldown. It can only move in the
-- fail-safe direction (propose retiring an edge-decayed strategy); the ADVERSARIAL review that follows
-- is default-KEEP (affirmative RETIRE required), so a fired candidacy is a proposal, not a retirement.
-- Redundancy / dominated-by-newcomer are documented additional SL4 signals; edge-decay is the encoded
-- objective one here (correlation/dominance need cross-strategy per-cell attribution not yet in perf.*).
-- !! RUNTIME OVERRIDE — this is NOT the live definition. bigquery/39_beta_adjusted_alpha.sql is applied
-- AFTER this file and CREATE OR REPLACEs state.strategy_retirement_candidacy, folding a beta-adjusted
-- suppression into edge_decay_signal + candidacy_fired (all thresholds copied verbatim; 39 also adds a
-- beta column and LEFT JOIN). At runtime 39's definition wins. ANY change below MUST be mirrored into
-- bigquery/39_beta_adjusted_alpha.sql or it is silently dead. No CI gate enforces this — sync by hand.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_retirement_candidacy` AS
WITH latest AS (
  SELECT strategy AS strategy_code, excess_vs_sgov, deployed_days
  FROM `stock-trading-498512.perf.strategy_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
-- defense-in-depth (rev 2026-07-10b, code-review finding #3): SL4 is now blocked entirely at the shared
-- ops.sp_assert_arsenal_enabled gate when incubation_frozen=TRUE, but this view ALSO folds it in here,
-- matching its 3 siblings (strategy_adoption_readiness / strategy_shadow_readiness / strategy_paper_readiness),
-- so it stays internally safe even if ever queried without that gate having run first.
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  l.excess_vs_sgov,
  l.deployed_days,
  (l.deployed_days >= 252 AND l.excess_vs_sgov < 0) AS edge_decay_signal,
  rails.active_count,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = r.strategy_code
                AND cl.to_state = 'RETIREMENT_PROPOSED'
                AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS cooldown_clear,
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = r.strategy_code
                     AND cl.to_state = 'RETIREMENT_PROPOSED'
                     AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY))) AS candidacy_fired
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest l USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'ADOPTED';

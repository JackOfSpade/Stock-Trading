-- BigQuery analytics layer — part 2 (regime scoring + adversarial independence).
-- Project: stock-trading-498512. Builds on 01_schema.sql + 02_ai_layer.sql.

-- ===== Monthly fundamental regime scoring (M1a 5-axis scores) =====
-- Migrated from Monthly_Fundamental_RegimeScore.md into regime_events with a new
-- scope='FUNDAMENTAL_AXIS', so the conviction/calibration layer can regime-condition
-- outcomes on the 5 axes. (Loaded 2026-06-05 for the May 2026 cycle; see INSERT in
-- the migration history. Going forward, M1a writes one row per axis per month.)
-- Keys: growth_momentum, inflation_trend, policy_stance, risk_sentiment, shock_overlay,
--       _integrative. Values are the categorical scores (decelerating, reaccelerating, ...).
-- state.current_regime already surfaces these as the latest per (scope,key).

-- ===== Adversarial-review independence (theater-check measurement) =====
-- Embeds each attacker + orchestrator transcript, then scores attacker-vs-orchestrator
-- semantic similarity per review. Operationalizes router pre-mortem indicators 9.2/9.4.
--
-- SUPERSEDED BY analytics.theater_judge / analytics.theater_check_calibration (bigquery/11_theater_judge.sql
-- — an AI.GENERATE_BOOL judge over the paired transcripts, per the P2 refinement noted below). No routine
-- reads review_embeddings or theater_independence anymore (self-improvement audit 2026-07-15 cleanup pass
-- confirmed zero live consumers). RETAINED, not dropped — matches this repo's established convention for
-- superseded analytics objects (see ops/weekly_report/weekly_report.gs's own "retain, don't delete" note for
-- its superseded views); review_embeddings is also a materialized ML.GENERATE_EMBEDDING table, so dropping
-- it would additionally discard real Vertex AI embedding spend for zero benefit over just leaving it alone.
CREATE OR REPLACE TABLE `stock-trading-498512.analytics.review_embeddings` AS
SELECT review_id, role, strategy, theater_check, verdict, review_date,
       ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `stock-trading-498512.ops.text_embed`,
  (SELECT review_id, role, strategy, theater_check, verdict, review_date,
          SUBSTR(body_md, 1, 6000) AS content
   FROM `stock-trading-498512.events.adversarial_reviews`),
  STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type));

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.theater_independence` AS
WITH a AS (SELECT review_id, strategy, embedding FROM `stock-trading-498512.analytics.review_embeddings` WHERE role='attacker'),
     o AS (SELECT review_id, theater_check, verdict, embedding FROM `stock-trading-498512.analytics.review_embeddings` WHERE role='orchestrator')
SELECT a.review_id, a.strategy, o.theater_check,
       ROUND(1 - ML.DISTANCE(a.embedding, o.embedding, 'COSINE'), 4) AS attacker_orch_similarity,
       o.verdict
FROM a JOIN o USING (review_id);

-- FINDING (2026-06-05): full-transcript similarity is topically saturated (~0.95-0.97 across
-- all 3 reviews regardless of theater-check flag), so raw cosine is NOT a sharp CONVERGENT
-- detector. P2 refinement: embed only the verdict/reasoning sections, OR add an
-- AI.GENERATE_BOOL("did the orchestrator surface independent disagreement?") judge over the
-- paired transcripts and track its rate vs the self-certified theater_check flag.

-- ===== decision_log.ticker backfill (2026-06-06) — APPLIED one-time migration, kept as history =====
-- The decision_log migration left ticker NULL (the parser never extracted it). Backfilled from the
-- title: (1) "Strategy X — TICKER (..." / "EXCHANGE: TICKER" clean formats, plus (2) for GO entries,
-- match the known traded-ticker set (false-positive-free). This populated ALL 10 GO theses
-- (IBM/HCA/META/ZBRA/BRC/TJX/AZO/MDT/RTX/DIS) + the clean-format NO-GO subset, which is what
-- thesis_outcomes needs. The freeform NO-GO titles ("INTU session", "post-WHR-NO-GO MT, FLEX
-- session", ...) that a regex can't safely parse (would false-positive on FY27/MT/GO) were then
-- backfilled via AI.GENERATE_TABLE (Gemini `ops.gemini`; see 02_ai_layer.sql) -- 68/68 valid
-- extractions correct, 0 false positives, primary-ticker disambiguation correct. Coverage: 97/112
-- theses (the rest are genuinely multi-ticker / session-end entries -> correctly NULL). The
-- DECISION-LOG PARSER must add ticker extraction going forward so new entries land tickered.
-- (NB: BURL's GO was folded into a NO-GO entry, so it has no thesis row -- a known gap; its +0.87
-- realized P&L is in trade_fills regardless.)
-- COMMENTED OUT (2026-06-12): this UPDATE was a one-time migration, already applied. Left live, a
-- re-run of this file would re-execute it against FUTURE NULL-ticker rows (which are legitimately
-- NULL — multi-ticker / session-end entries) using the stale hardcoded GO-ticker list, silently
-- mis-tagging any entry whose title merely mentions one of those tickers.
--   UPDATE `stock-trading-498512.events.decision_log`
--   SET ticker = COALESCE(
--     REGEXP_EXTRACT(title, r'Strategy [A-E] [—-] ([A-Z]{1,5})\b'),
--     REGEXP_EXTRACT(title, r'(?:NASDAQ|NYSE|NYSEARCA|AMEX|BATS)\s*:\s*([A-Z]{1,5})'),
--     IF(decision='GO', REGEXP_EXTRACT(title, r'\b(IBM|HCA|META|ZBRA|BRC|TJX|AZO|BURL|RTX|DIS)\b'), NULL))
--   WHERE ticker IS NULL;

-- ===== analytics.thesis_outcomes — the conviction/calibration foundation =====
-- One row per thesis-construction decision, joined to its position outcome (realized P&L from the
-- curated fills) + the prevailing fundamental regime. `was_profitable` is the supervised label for
-- the future conviction model -- NULL until the position CLOSES (open positions are unknown, not
-- "unprofitable"; the buy fill's realized_pnl=0 must not be read as a loss). As of 2026-06-06 the
-- 3 closed B GO theses (IBM/META/BRC) are 3/3 profitable gross -- the first calibration signal;
-- the conviction model itself stays deferred until ~30 closed trades.
--
-- REGIME-AS-OF FIX (2026-07-03, self-improvement audit S-1/B-1). Was: `regime_now` selected the
-- single LATEST `_integrative` regime value and back-stamped it onto EVERY historical thesis
-- (`MAX(...)` with no entry_date correlation) -- look-ahead label leakage that silently re-labels
-- every past thesis each time the regime flips, and non-reproducible month over month. Fixed to an
-- as-of lookup: the regime in effect ON OR BEFORE the thesis's entry_date. A thesis predating any
-- regime_events row now correctly gets NULL (unknown), not a fabricated future value. Implemented
-- as a DECORRELATED join + QUALIFY (same pattern as state.account_nav_7d_ago) -- BigQuery views do
-- not support a same-row correlated subquery against another table.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcomes` AS
WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, sub_pattern, decision, title
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'thesis-construction'
),
regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope='FUNDAMENTAL_AXIS' AND key='_integrative'
),
thesis_regime AS (
  SELECT t.entry_id, ra.regime_state
  FROM theses t
  LEFT JOIN regime_axis ra ON ra.as_of_date <= t.entry_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY t.entry_id ORDER BY ra.as_of_date DESC) = 1
)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  tr.regime_state,
  pl.exit_date IS NOT NULL AS position_closed,
  IF(pl.exit_date IS NOT NULL, pl.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pl.exit_date IS NULL THEN NULL          -- position still open -> outcome unknown (not a loss)
       WHEN pl.realized_pnl IS NULL THEN NULL
       ELSE pl.realized_pnl > 0 END AS was_profitable,
  t.title
FROM theses t
LEFT JOIN thesis_regime tr ON tr.entry_id = t.entry_id
LEFT JOIN `stock-trading-498512.analytics.position_lifecycle` pl
  ON pl.strategy = t.strategy AND pl.ticker = t.ticker
-- Pair each thesis to ITS round-trip: a re-traded ticker has >1 position, so pick
-- the one whose entry_date is nearest the thesis date and take realized_pnl from
-- THAT position (the old ticker-wide SUM over all fills conflated round-trips and
-- fanned the thesis row out once per round-trip).
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY t.entry_id
  ORDER BY ABS(DATE_DIFF(pl.entry_date, t.entry_date, DAY)) NULLS LAST
) = 1;

-- ===== Structured macro series (2026-06-06) =====
-- Headline macro indicators extracted from Monthly_Macro_Data_*.md (M1a audit inputs; "not read
-- by M1b"). Gives a queryable/forecastable numeric series alongside the categorical regime axes in
-- regime_events. M1a writes forward (one row per metric per release). Once this carries enough
-- history, AI.FORECAST / regime-conditioning can run on actual macro values, not just labels.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.macro_series` (
  event_id STRING DEFAULT GENERATE_UUID(),
  ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  release_date DATE, reference_period STRING, metric STRING,
  value NUMERIC, unit STRING, source_month STRING, note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY release_date CLUSTER BY metric
OPTIONS(description='Structured macro indicators (from Monthly_Macro_Data_*.md, M1a audit inputs). M1a writes forward.');
-- Seeded 2026-06-06 from the 2026-04 + 2026-05 macro files (CPI/core, PPI, retail sales, NFP, U-3,
-- AHE, GDP) — 19 rows / 12 metrics. Trend captured: CPI 3.3->3.8 YoY, PPI 4.0->6.0, GDP +2.0->+1.6
-- (Q1 second est revised down), retail MoM 1.7->0.5. (Insert literals in the migration commit.)

-- ===== Conviction / calibration layer (cold-start-ready, 2026-06-06) =====
-- The supervised layer: does conviction (+ regime / sub-pattern) predict GO-thesis profitability?
-- BUILT NOW but GATED — its OUTPUTS are not acted upon until >=30 closed GO trades (B is at 4); with a
-- handful of closed trades any model overfits noise. The substrate is live so it accrues signal now.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.conviction_features` AS
SELECT entry_id, entry_date, strategy, ticker, decision, conviction,
  CASE UPPER(conviction)
    WHEN 'LOW' THEN 1 WHEN 'MEDIUM-LOW' THEN 2 WHEN 'MEDIUM' THEN 3
    WHEN 'MEDIUM-HIGH' THEN 4 WHEN 'HIGH' THEN 5 WHEN 'HIGHEST' THEN 6 ELSE NULL END AS conviction_ordinal,
  sub_pattern, regime_state, position_closed, realized_pnl, was_profitable
FROM `stock-trading-498512.analytics.thesis_outcomes`
WHERE decision = 'GO';

-- Cold-start-SAFE calibration: per conviction tier, closed count / win-rate / avg realized P&L. Works
-- at any N (sparse now: 3 closed, all wins). This is what the routine reads for conviction-calibration
-- UNTIL the model below is trustworthy.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.calibration_summary` AS
SELECT COALESCE(conviction,'(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
  COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins,
  ROUND(SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)), 3) AS win_rate,
  ROUND(AVG(IF(position_closed, realized_pnl, NULL)), 3) AS avg_realized_pnl
FROM `stock-trading-498512.analytics.conviction_features`
GROUP BY conviction ORDER BY ord;

-- DEPRECATED (2026-07-03, self-improvement audit S-2/B-2) — do NOT build this model, even once >=30
-- closed GO theses accrue. A LOGISTIC_REG fit on ~30 fee-dominated, single-class-until-recently,
-- non-independent (one market regime, correlated names/timing) binary outcomes with 4 categorical
-- features and no cross-validation / walk-forward would overfit -- the exact hazard this project's own
-- foundation doc warns against. analytics.calibration_shrunk (bigquery/25_calibration_shrinkage.sql) is
-- the replacement: a Beta-Binomial shrinkage estimate + Wilson interval that is honest from trade 1,
-- needs no both-classes precondition, and dominates a fitted logistic model at this sample size. Left
-- here (commented) as a historical record of what was considered and rejected, not a TODO:
--   CREATE OR REPLACE MODEL `stock-trading-498512.ops.conviction_model`
--     OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['was_profitable'], auto_class_weights=TRUE) AS
--   SELECT conviction_ordinal, strategy, sub_pattern, regime_state, was_profitable
--   FROM `stock-trading-498512.analytics.conviction_features`
--   WHERE position_closed AND was_profitable IS NOT NULL;
-- The routine reads analytics.calibration_shrunk (per-tier posterior + interval + trustworthy_edge),
-- never analytics.calibration_summary.win_rate alone and never a fitted model's output.

-- ===== Per-strategy NAV / 2%-sizing base (2026-06-06) — the last Portfolio_Ledger data domain =====
-- NAV_strategy = equal-split deposits ($9,446.86/5) + realized P&L (trade_fills) + unrealized (open
-- positions marked at the latest daily_marks close) + held-stock dividends. Gives the **2%-sizing base**
-- (sizing_base_2pct ≈ $37.7/strategy) + available-funds (NAV − deployed MV) — the figures the routines
-- previously read from Portfolio_Ledger.md. Σ NAV ≈ $9,442 vs connector NLV ≈ $9,461 (~0.2% light: the
-- shared SGOV park is held at deposit par here). NOTE (RESOLVED 2026-06-19): the per-strategy SGOV-share
-- allocation "attribution debt" is DISSOLVED — the SGOV park is account-level (events.parking_events has
-- no strategy tag), so there is no per-strategy split to reconcile. The §13 cash-tripwire reads the
-- event-sourced TOTAL SGOV holding from state.sgov_reconciliation (13_sgov_reconciliation.sql), and
-- per-strategy budget = this view's available_funds. Portfolio_Ledger.md is retired (not kept).
-- (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive.) DEAD / SUPERSEDED: this
-- strategy_nav is redefined downstream by bigquery/22_cash_flows.sql (CREATE OR REPLACE, applied later),
-- which reads events.cash_flows and the ROSTER-DERIVED active set + as-of-flow-date divisor. The bare
-- ['A'..'E'] literal and CAST(1889.372) deposits below are the pre-cash_flows / pre-roster artifact and
-- are deliberately left unchanged — they are never the live definition. scripts/check_roster_consistency.py
-- scopes its no-bare-literal / no-/5 assertion to the LIVE files (bigquery/22, 26, dbt strategy_nav), NOT this one.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_nav` AS
WITH dep AS (SELECT s AS strategy, CAST(1889.372 AS NUMERIC) AS deposits FROM UNNEST(['A','B','C','D','E']) s),
realized AS (SELECT strategy, SUM(realized_pnl) AS realized_pnl FROM `stock-trading-498512.state.trade_fills_curated` GROUP BY strategy),
latest_close AS (SELECT ticker, close FROM `stock-trading-498512.state.daily_marks_curated`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC)=1),
open_pos AS (SELECT cp.strategy, SUM(cp.shares*lc.close) AS open_mv, SUM(cp.cost_basis) AS open_cost
  FROM `stock-trading-498512.state.current_positions` cp JOIN latest_close lc USING (ticker)
  WHERE cp.status='OPEN' GROUP BY cp.strategy),
divs AS (SELECT l.strategy, SUM(l.shares*m.dividend) AS dividends
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.daily_marks_curated` m ON m.ticker=l.ticker AND m.dividend IS NOT NULL
   AND m.mark_date>=l.entry_date AND (l.exit_date IS NULL OR m.mark_date<=l.exit_date)
  GROUP BY l.strategy)
SELECT d.strategy, d.deposits,
  ROUND(COALESCE(r.realized_pnl,0),2) AS realized_pnl,
  ROUND(COALESCE(o.open_mv-o.open_cost,0),2) AS unrealized_pnl,
  ROUND(COALESCE(dv.dividends,0),2) AS dividends_held,
  ROUND(COALESCE(o.open_mv,0),2) AS deployed_mv,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0),2) AS nav,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)-COALESCE(o.open_mv,0),2) AS available_funds,
  ROUND(0.02*(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)),2) AS sizing_base_2pct
FROM dep d LEFT JOIN realized r USING(strategy) LEFT JOIN open_pos o USING(strategy) LEFT JOIN divs dv USING(strategy);

-- ===== §13 account-integrity (2026-06-06) — replaces Portfolio_Ledger's per-strategy SGOV-share ledger =====
-- The §13 cash/SGOV reconciliation, reframed ACCOUNT-LEVEL: this view is the events-side expected total;
-- D2 Step 0 compares it (+ the connector's live SGOV mark) to the connector NLV / SGOV shares / cash and
-- flags any residual > ~$1 (Operating_Protocols §13). Per-strategy budget = analytics.strategy_nav
-- (available_funds). No per-strategy SGOV-share hand-ledger — that ledger mechanic (the attribution debt)
-- is dissolved; account integrity + per-strategy NAV cover §13's two purposes.
-- DEAD / SUPERSEDED (matching the strategy_nav marker above): this account_reconciliation — including the
-- hardcoded CAST(9446.86 AS NUMERIC) total_deposits below — is redefined by bigquery/22_cash_flows.sql
-- (CREATE OR REPLACE, applied later) to read events.cash_flows dynamically. This definition is dead at
-- runtime; do NOT hand-edit the 9446.86 literal here expecting a live effect — record a new flow via an
-- events.cash_flows INSERT (Operating_Protocols §13.C).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.account_reconciliation` AS
SELECT
  CAST(9446.86 AS NUMERIC) AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl),2) FROM `stock-trading-498512.state.trade_fills_curated`) AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS deployed_total,
  (SELECT ROUND(SUM(available_funds),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS undeployed_total;

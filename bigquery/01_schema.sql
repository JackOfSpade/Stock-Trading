-- BigQuery schema for the Stock-Trading experiment data layer (v2 redesign).
-- Project: stock-trading-498512 (US multi-region). Event-sourced, append-only.
-- Apply with the BigQuery MCP execute_sql or `bq query --use_legacy_sql=false`.
-- See BigQuery_System_Redesign_v2.md §3, §11. Idempotent (IF NOT EXISTS / OR REPLACE).

-- ===== Datasets =====
CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.events`    OPTIONS(location='US', description='Append-only source of truth. INSERT/Storage-Write only; never UPDATE/DELETE.');
CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.state`     OPTIONS(location='US', description='Current-state projections: standard views taking the latest event per entity.');
CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.perf`      OPTIONS(location='US', description='Deployed-TWR engine outputs + gate/kill flags (scheduled-procedure built).');
CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.analytics` OPTIONS(location='US', description='BQML models, embeddings, calibration, attribution, screens, rollups.');
CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.ops`       OPTIONS(location='US', description='Remote models, stored procedures, audit/export, connections.');

-- ===== Event tables (append-only) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.decision_log` (
  entry_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  entry_date DATE NOT NULL,
  entry_type STRING NOT NULL,
  strategy STRING, ticker STRING,
  decision STRING, conviction STRING, conviction_pct NUMERIC,
  sub_pattern STRING, theater_check STRING,
  title STRING, body_md STRING,
  fields JSON, refs ARRAY<STRING>, tags ARRAY<STRING>,
  superseded_by STRING, source_session STRING,
  PRIMARY KEY (entry_id) NOT ENFORCED
) PARTITION BY entry_date CLUSTER BY strategy, entry_type, ticker
OPTIONS(description='Append-only decision audit. Corrections are new rows with superseded_by; never UPDATE/DELETE.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.trade_fills` (
  trade_id STRING NOT NULL,
  order_id STRING, contract_id INT64,
  ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  fill_ts TIMESTAMP,
  strategy STRING, ticker STRING, side STRING,
  shares NUMERIC, price NUMERIC, commission NUMERIC, realized_pnl NUMERIC,
  source_thesis_ref STRING, raw JSON,
  PRIMARY KEY (trade_id) NOT ENFORCED
) PARTITION BY DATE(fill_ts) CLUSTER BY strategy, ticker
OPTIONS(description='IBKR fills. Idempotent by trade_id (dedup in state.trade_fills_curated).');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.position_events` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  position_key STRING NOT NULL,
  event_type STRING NOT NULL,
  status STRING,
  strategy STRING, ticker STRING, contract_id INT64,
  cost_basis NUMERIC, shares NUMERIC,
  convergence_target NUMERIC, time_exit_date DATE, ltcg_date DATE,
  invalidation_status JSON,
  conviction STRING, model_at_entry STRING,
  source_thesis_ref STRING, note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY DATE(event_ts) CLUSTER BY strategy, ticker, event_type
OPTIONS(description='Position lifecycle events → state.current_positions.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.regime_events` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  as_of_date DATE NOT NULL,
  scope STRING NOT NULL,
  key STRING NOT NULL,
  value STRING, numeric_value NUMERIC,
  divergence_id STRING, theater_check STRING,
  rationale STRING, source_review_ref STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY as_of_date CLUSTER BY scope, key
OPTIONS(description='Technical signals + per-strategy activation events → state.current_regime.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.queue_events` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  queue STRING NOT NULL,
  item_key STRING NOT NULL,
  item_type STRING,
  status STRING NOT NULL,
  strategy STRING, ticker STRING, due_date DATE,
  conservative_default STRING, artifact_path STRING,
  payload JSON, note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY DATE(event_ts) CLUSTER BY queue, status
OPTIONS(description='Queue status-transition events → state.open_queue.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.adversarial_reviews` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  review_id STRING NOT NULL,
  review_type STRING, strategy STRING, role STRING,
  review_date DATE, cycle_number INT64,
  verdict STRING, theater_check STRING,
  weaknesses JSON, artifact_path STRING, body_md STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY review_date CLUSTER BY review_type, strategy
OPTIONS(description='Adversarial attacker/orchestrator outputs; paired view feeds theater-independence analytics.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.parking_events` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  action_date DATE NOT NULL,
  strategy STRING, action STRING,
  shares NUMERIC, price NUMERIC, commission NUMERIC, gross NUMERIC,
  order_id STRING, note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY action_date CLUSTER BY strategy, action
OPTIONS(description='SGOV parking activity for per-strategy cash attribution (§13 tripwire).');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.hf_capability_captures` (
  capture_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  capture_date DATE NOT NULL,
  source STRING, title STRING, body_md STRING,
  foundation_ref STRING, refs ARRAY<STRING>,
  PRIMARY KEY (capture_id) NOT ENFORCED
) PARTITION BY capture_date
OPTIONS(description='HF frontier-LLM capability captures (D1 / Q3).');

-- ===== State views (latest-wins) =====
-- Note on latest-wins ordering (the discriminator must be the TRANSITION time):
--   * regime_events: as_of_date IS the observation date, so a newer as_of_date is
--     a newer reading -> ORDER BY as_of_date DESC, event_ts DESC (correct).
--   * queue_events: due_date is a TARGET date, NOT a transition time. Ordering by
--     it lets an older 'created' event outrank a later 'complete'/'superseded'
--     event whenever that later event carries a NULL or earlier due_date — so a
--     closed item wrongly stays in the open queue (or a reopened one hides).
--     Use event_ts DESC, the actual INSERT-time transition order (event_ts is a
--     DEFAULT CURRENT_TIMESTAMP() on these rows).
--   * position_events: event_ts is set explicitly in the parser, so event_ts DESC
--     alone is correct there.
CREATE OR REPLACE VIEW `stock-trading-498512.state.current_positions` AS
SELECT * FROM (
  SELECT * FROM `stock-trading-498512.events.position_events`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC) = 1
) WHERE event_type <> 'CLOSE';

CREATE OR REPLACE VIEW `stock-trading-498512.state.current_regime` AS
SELECT * FROM `stock-trading-498512.events.regime_events`
QUALIFY ROW_NUMBER() OVER (PARTITION BY scope, key ORDER BY as_of_date DESC, event_ts DESC) = 1;

-- Queue current-state, two layers:
--   * open_queue_detail — full latest-wins projection INCLUDING the bulky payload JSON + note;
--     read item context here (e.g. SELECT payload, note FROM state.open_queue_detail WHERE item_key=…).
--   * open_queue — routing/identity scalar columns ONLY (no payload, no note), so `SELECT *` is
--     always compact and tabular no matter how verbose an item is; has_note/has_payload flag where
--     the prose lives. This is the view drain routines (D2/D3) and state.daily_briefing read.
CREATE OR REPLACE VIEW `stock-trading-498512.state.open_queue_detail` AS
SELECT * FROM (
  SELECT * FROM `stock-trading-498512.events.queue_events`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY queue, item_key
    ORDER BY event_ts DESC
  ) = 1
) WHERE status NOT IN ('complete','superseded','COMPLETE','DROPPED');

CREATE OR REPLACE VIEW `stock-trading-498512.state.open_queue` AS
SELECT event_id, event_ts, queue, item_key, item_type, status, strategy, ticker,
       due_date, conservative_default, artifact_path,
       note IS NOT NULL AS has_note,
       payload IS NOT NULL AS has_payload
FROM `stock-trading-498512.state.open_queue_detail`;

CREATE OR REPLACE VIEW `stock-trading-498512.state.trade_fills_curated` AS
SELECT * FROM `stock-trading-498512.events.trade_fills`
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC) = 1;

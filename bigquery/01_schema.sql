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
OPTIONS(description='Append-only decision audit. decision/conviction/body_md/title/outcome fields: corrections are NEW rows with superseded_by — never UPDATE/DELETE. EXCEPTION (2026-06-21): the pure-classification metadata column sub_pattern MAY be normalized in place by W5 (taxonomy owner) with an old->new audit trail in B_Sub_Pattern_Taxonomy.md — see ops/RUNBOOK.md §21.');

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
OPTIONS(description='Queue status-transition events → state.open_queue. Lanes: WATCHLIST, PENDING_ANALYSIS, PENDING_REVIEW, and ORDER_STAGED (the durable persist-and-wait registry → state.open_orders; statuses pending|filled|expired|abandoned).');

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
-- event_id DESC is a deterministic tiebreaker: two events can share (as_of_date, event_ts) for the
-- same (scope, key) (e.g. STRATEGY_ACTIVATION C on 2026-06-03), and without it ROW_NUMBER picks one
-- arbitrarily, so the resolved regime could flip between query runs.
QUALIFY ROW_NUMBER() OVER (PARTITION BY scope, key ORDER BY as_of_date DESC, event_ts DESC, event_id DESC) = 1;

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
)
-- Case-normalized terminal-status filter: the agent-written status column has
-- already drifted case once ('complete' vs 'COMPLETE'), and a mixed-case
-- terminal row slipping past a case-sensitive list would keep a closed item
-- in the open queue forever. 'filled','expired','abandoned' are the
-- ORDER_STAGED terminal statuses (staged-order registry; state.open_orders).
WHERE UPPER(status) NOT IN ('COMPLETE','SUPERSEDED','DROPPED',
                            'FILLED','EXPIRED','ABANDONED');

CREATE OR REPLACE VIEW `stock-trading-498512.state.open_queue` AS
SELECT event_id, event_ts, queue, item_key, item_type, status, strategy, ticker,
       due_date, conservative_default, artifact_path,
       note IS NOT NULL AS has_note,
       payload IS NOT NULL AS has_payload
FROM `stock-trading-498512.state.open_queue_detail`;

-- state.open_orders — the durable STAGED-ORDER REGISTRY (persist-and-wait intent).
-- Problem it closes: under the DAY-only TIF policy (Operating_Protocols §11) a Claude-crafted order
-- is ephemeral — it expires every session and is re-crafted fresh — so between sessions a GO'd-but-
-- unfilled entry (or a resting exit) has NO live order/instruction. Before this registry that intent
-- lived only in Decision_Log prose + an expired DAY order + a calendar event, all of which lapse
-- independently; on 2026-06-08 an MDT entry was silently de-funded (its earmarked cash swept to SGOV)
-- because §13's free_cash keyed off live get_order_instructions (empty) and the persist-and-wait
-- re-craft sweep had no durable list to iterate. This view is that durable list.
--   * One ORDER_STAGED row per intended order, written when a GO/exit is staged; item_key is stable
--     across the daily DAY re-crafts (only payload.instruction_id changes). Statuses: pending (no
--     logged terminal decision yet), filled / expired / abandoned (terminal — and only a logged
--     terminal decision may set them).
--   * WARNING (2026-08-03): 'pending' is a RECONCILIATION state, NOT a broker state. It does NOT mean
--     the order is working at the broker, and it does NOT mean the order did not fill — a row that
--     filled at this morning's open stays 'pending' until D2a Step 0 reconciles it, so the entire
--     overnight block sees 'pending' on already-filled orders. Never infer fill state from this
--     column; read get_account_trades / get_account_orders / get_account_positions instead. (An
--     earlier revision of this comment read 'pending (live)', which invited exactly that misreading.)
--   * due_date carries the entry-window-close (entries) / exit deadline; D2 detects window expiry off it.
--   * reserved_cash = cash a still-pending BUY consumes if it fills (resting SELL reserves nothing);
--     §13.E free_cash subtracts SUM(reserved_cash) so a sweep can never de-fund a staged entry.
-- Reconciled every D2 Step 0 (Claude_Task_Plan D2): fill -> filled + position_events OPEN;
-- window open + unfilled -> re-craft DAY + refresh confirm event; window closed -> expired + logged
-- missed-entry decision. D3 reconciles confirm-order calendar events against this view.
CREATE OR REPLACE VIEW `stock-trading-498512.state.open_orders` AS
SELECT
  item_key,
  item_type,
  strategy,
  ticker,
  status,
  due_date AS entry_window_close,
  CAST(JSON_VALUE(payload,'$.contract_id') AS INT64)         AS contract_id,
  UPPER(JSON_VALUE(payload,'$.side'))                         AS side,
  CAST(JSON_VALUE(payload,'$.qty') AS NUMERIC)               AS qty,
  CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC)       AS limit_price,
  COALESCE(JSON_VALUE(payload,'$.tif'),'DAY')                AS tif,
  CAST(JSON_VALUE(payload,'$.convergence_target') AS NUMERIC) AS convergence_target,
  SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(payload,'$.time_exit_date')) AS time_exit_date,
  JSON_VALUE(payload,'$.instruction_id')                     AS instruction_id,
  JSON_VALUE(payload,'$.source_decision_ref')                AS source_decision_ref,
  -- paired_sell_item_key / paired_buy_item_key (paired-rotation redesign, owner directive 2026-07-26,
  -- Operating_Protocols.md §13.E PAIRED-ROTATION EXCEPTION): when D2 crafts both legs of a capital
  -- rotation in one session, each leg names its sibling so the pair is reconstructable FROM THIS VIEW --
  -- previously the keys were written into the payload but never projected, so §13.C's paired-rotation
  -- attribution branch ("verify both legs exist") could only reach them by hand-parsing raw JSON off
  -- events.queue_events. Deliberately JSON_VALUE (STRING passthrough) with NO cast: convergence_target
  -- above is a hard CAST(... AS NUMERIC), and on 2026-07-26 a ticker string written into that field made
  -- every SELECT * against this view fail with "Invalid NUMERIC value" -- an uncastable value in a
  -- payload field must never be able to break the whole registry again.
  JSON_VALUE(payload,'$.paired_sell_item_key')               AS paired_sell_item_key,
  JSON_VALUE(payload,'$.paired_buy_item_key')                AS paired_buy_item_key,
  -- guard_passed/guard_reasons (self-improvement audit ITEM 15, 2026-07-11): the routine-side
  -- fn_order_guard/fn_order_guard_options check was documented as an obligation on the caller with no
  -- mechanical enforcement -- nothing stopped an ORDER_STAGED row from landing without the guard ever
  -- having run. Embedding its own result in the payload makes the omission a queryable, detectable fact
  -- (bigquery/scheduled_queries/daily_staging_cap_check.sql flags any today's row missing it as CRITICAL)
  -- instead of a silent trust assumption. NULL guard_passed on an OLDER row (pre-ITEM-15) is expected and
  -- not itself an anomaly -- only a MISSING value on a row staged TODAY, after this convention took effect.
  CAST(JSON_VALUE(payload,'$.guard_passed') AS BOOL)         AS guard_passed,
  JSON_VALUE(payload,'$.guard_reasons')                       AS guard_reasons,
  CASE WHEN UPPER(JSON_VALUE(payload,'$.side')) = 'BUY'
       THEN ROUND(CAST(JSON_VALUE(payload,'$.qty') AS NUMERIC)
                  * CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC)
                  -- options stage in CONTRACTS with a per-share-premium limit_price; a debit fill
                  -- consumes premium*100*contracts. OCC-symbol ticker => x100 (same convention as
                  -- bigquery/40,41); equity/ETF => x1. Regex inlined (not analytics.fn_is_occ_option_symbol,
                  -- which is defined later in file 40) to keep 01 self-contained in DR-rebuild apply-order.
                  * IF(REGEXP_CONTAINS(ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$'), 100, 1)
                  + 0.35, 2)
       ELSE 0 END                                            AS reserved_cash,
  event_ts AS staged_ts,
  note
FROM (
  SELECT * FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
)
WHERE LOWER(status) = 'pending';

-- SUPERSEDED LIVE by bigquery/53_curated_view_tiebreak_fix.sql (2026-07-14) — adds trade_id as a
-- secondary tiebreaker (defense-in-depth; trade_id is already unique per fill, lower-risk than
-- daily_marks_curated's tie, but fixed for consistency). Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trade_fills_curated` AS
SELECT * FROM `stock-trading-498512.events.trade_fills`
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC) = 1;

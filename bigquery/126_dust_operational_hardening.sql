-- DRIP-dust operational hardening (2026-08-02).
-- Apply AFTER 125_dust_excluded_from_twr.sql.
--
-- SUPERSEDES bigquery/110 for state.position_reconciliation and bigquery/73 for
-- state.strategy_probe_progress. Classified dust remains visible in the fill-derived lifecycle for
-- auditability, but is not a strategy position for reconciliation or PROBE progress. This also adds
-- the singleton mutex used by D2a to serialize the connector-create + ORDER_STAGED handoff; BigQuery
-- primary keys are NOT ENFORCED, so an item-key precheck alone is not a concurrency control.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.order_stage_mutex` (
  lock_name STRING NOT NULL,
  owner_token STRING,
  item_key STRING,
  lease_expires_at TIMESTAMP,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (lock_name) NOT ENFORCED
)
CLUSTER BY lock_name
OPTIONS(description='Pre-seeded singleton mutex rows for serializing external order craft plus durable staging.');

ALTER TABLE `stock-trading-498512.events.queue_events`
SET OPTIONS(description='Queue status-transition events → state.open_queue. ORDER_STAGED supports a dust-only crafting status written before the external connector call, then pending|filled|expired|abandoned.');

MERGE `stock-trading-498512.ops.order_stage_mutex` t
USING (SELECT 'drip-dust-liquidation' AS lock_name) s
ON t.lock_name = s.lock_name
WHEN NOT MATCHED THEN
  INSERT (lock_name, owner_token, item_key, lease_expires_at, updated_at)
  VALUES (s.lock_name, NULL, NULL, NULL, CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_acquire_dust_order_mutex`(
  in_owner_token STRING,
  in_item_key STRING,
  OUT out_acquired BOOL
)
BEGIN
  IF in_owner_token IS NULL OR in_owner_token = '' OR in_item_key IS NULL OR in_item_key = '' THEN
    RAISE USING MESSAGE = 'owner_token and item_key are required';
  END IF;

  SET out_acquired = FALSE;
  BEGIN TRANSACTION;
  UPDATE `stock-trading-498512.ops.order_stage_mutex`
  SET owner_token = in_owner_token,
      item_key = in_item_key,
      lease_expires_at = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 10 MINUTE),
      updated_at = CURRENT_TIMESTAMP()
  WHERE lock_name = 'drip-dust-liquidation'
    -- Expiry is diagnostic, not permission to steal the mutex: a stalled prior process could resume
    -- after creating at the connector. D2a may release a stale owner only after its connector/registry
    -- recovery read proves that no orphaned SELL exists.
    AND (owner_token IS NULL OR owner_token = in_owner_token);

  SET out_acquired = EXISTS (
    SELECT 1
    FROM `stock-trading-498512.ops.order_stage_mutex`
    WHERE lock_name = 'drip-dust-liquidation'
      AND owner_token = in_owner_token
      AND item_key = in_item_key
      AND lease_expires_at > CURRENT_TIMESTAMP()
  );
  COMMIT TRANSACTION;
END;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_release_dust_order_mutex`(
  in_owner_token STRING,
  in_item_key STRING
)
BEGIN
  UPDATE `stock-trading-498512.ops.order_stage_mutex`
  SET owner_token = NULL,
      item_key = NULL,
      lease_expires_at = NULL,
      updated_at = CURRENT_TIMESTAMP()
  WHERE lock_name = 'drip-dust-liquidation'
    AND owner_token = in_owner_token
    AND item_key = in_item_key;
END;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_recover_expired_dust_order_mutex`(
  in_expected_owner_token STRING,
  in_expected_item_key STRING,
  OUT out_released BOOL
)
BEGIN
  SET out_released = FALSE;
  BEGIN TRANSACTION;
  UPDATE `stock-trading-498512.ops.order_stage_mutex`
  SET owner_token = NULL,
      item_key = NULL,
      lease_expires_at = NULL,
      updated_at = CURRENT_TIMESTAMP()
  WHERE lock_name = 'drip-dust-liquidation'
    AND owner_token = in_expected_owner_token
    AND item_key = in_expected_item_key
    AND lease_expires_at <= CURRENT_TIMESTAMP();
  SET out_released = EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.order_stage_mutex`
    WHERE lock_name = 'drip-dust-liquidation' AND owner_token IS NULL
  );
  COMMIT TRANSACTION;
END;

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
  WHERE exit_date IS NULL
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy, ticker
),
pend AS (
  SELECT
    strategy,
    ticker,
    SUM(qty) AS pending_buy_shares,
    ARRAY_AGG(item_key ORDER BY item_key) AS pending_buy_item_keys
  FROM `stock-trading-498512.state.open_orders`
  WHERE side = 'BUY'
    AND qty > 0
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND (
      (entry_window_close IS NOT NULL AND entry_window_close >= CURRENT_DATE('America/Denver'))
      OR staged_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    )
  GROUP BY strategy, ticker
),
joined AS (
  SELECT
    strategy,
    ticker,
    COALESCE(cp.current_positions_shares, 0) AS current_positions_shares,
    COALESCE(lc.lifecycle_open_shares, 0) AS lifecycle_open_shares,
    COALESCE(cp.current_positions_shares, 0) - COALESCE(lc.lifecycle_open_shares, 0) AS share_diff
  FROM cp FULL OUTER JOIN lc USING (strategy, ticker)
),
netted AS (
  SELECT
    j.strategy,
    j.ticker,
    j.current_positions_shares,
    j.lifecycle_open_shares,
    j.share_diff,
    COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)) AS pending_buy_shares,
    COALESCE(p.pending_buy_item_keys, []) AS pending_buy_item_keys,
    IF(j.share_diff > 0,
       GREATEST(j.share_diff - COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)), CAST(0 AS NUMERIC)),
       j.share_diff) AS residual_share_diff
  FROM joined j
  LEFT JOIN pend p USING (strategy, ticker)
)
SELECT
  strategy,
  ticker,
  current_positions_shares,
  lifecycle_open_shares,
  share_diff,
  pending_buy_shares,
  pending_buy_item_keys,
  residual_share_diff,
  ABS(share_diff) > 0.01 AS drifted_raw,
  ABS(share_diff) > 0.01 AND ABS(residual_share_diff) <= 0.01 AS explained_by_pending_buy,
  ABS(residual_share_diff) > 0.01 AS drifted,
  CURRENT_TIMESTAMP() AS checked_at
FROM netted;

CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_probe_progress` AS
WITH probe AS (
  SELECT strategy_code, immutable_since
  FROM `stock-trading-498512.state.strategy_roster`
  WHERE current_state = 'PROBE'
),
trades AS (
  SELECT strategy AS strategy_code, closed_trades
  FROM `stock-trading-498512.perf.strategy_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
openpos AS (
  SELECT strategy AS strategy_code, COUNT(*) AS n_open
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE exit_date IS NULL AND NOT COALESCE(is_dust, FALSE)
  GROUP BY 1
)
SELECT
  p.strategy_code,
  DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) AS probe_days,
  COALESCE(fg.funding_gap_dollars, 0) AS funding_gap_dollars,
  COALESCE(t.closed_trades, 0) AS closed_trades,
  COALESCE(o.n_open, 0) AS n_open_positions,
  (DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) >= 400
   AND COALESCE(fg.funding_gap_dollars, 0) = 0
   AND COALESCE(t.closed_trades, 0) = 0
   AND COALESCE(o.n_open, 0) = 0
   AND NOT EXISTS (
     SELECT 1
     FROM `stock-trading-498512.ops.roster_change_log` cl
     WHERE cl.strategy_code = p.strategy_code
       AND cl.to_state = 'RETIREMENT_PROPOSED'
       AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
   )) AS stuck
FROM probe p
LEFT JOIN `stock-trading-498512.state.strategy_probe_funding_gap` fg USING (strategy_code)
LEFT JOIN trades t USING (strategy_code)
LEFT JOIN openpos o USING (strategy_code);

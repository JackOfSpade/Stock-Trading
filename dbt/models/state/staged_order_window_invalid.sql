-- Parallel-run dbt port of bigquery/233_staged_order_window_dead_on_arrival.sql:state.staged_order_window_invalid — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH scoped AS (
  SELECT
    o.item_key,
    o.item_type,
    o.strategy,
    o.ticker,
    o.side,
    o.qty,
    o.limit_price,
    o.instruction_id,
    o.staged_ts,
    o.entry_window_close,
    TIMESTAMP(
      DATETIME(o.entry_window_close,
               IF(COALESCE(mc.is_early_close, FALSE), TIME '13:00:00', TIME '16:00:00')),
      'America/New_York') AS window_close_instant
  FROM {{ ref('open_orders') }} o
  LEFT JOIN {{ ref('market_calendar') }} mc
    ON mc.cal_date = o.entry_window_close
  WHERE o.entry_window_close IS NOT NULL
)
SELECT * FROM scoped
WHERE staged_ts >= window_close_instant

-- Parallel-run dbt port of bigquery/01_schema.sql:state.open_orders — canonical source is that file until owner cutover.
-- The durable STAGED-ORDER REGISTRY (persist-and-wait intent). One pending ORDER_STAGED
-- row per intended order; item_key is stable across daily DAY re-crafts.
--
-- reserved_cash = cash a still-pending BUY consumes if it fills (resting SELL reserves 0);
-- §13.E free_cash subtracts SUM(reserved_cash) so a sweep can never de-fund a staged entry.
-- This view exists because on 2026-06-08 an MDT entry was silently de-funded (earmarked cash
-- swept to SGOV) when free_cash keyed off live order instructions (empty) with no durable list.
-- reserved_cash formula (BUY): ROUND(qty*limit_price + 0.35, 2) — the documented commission pad.
--
-- guard_passed/guard_reasons added (rev 2026-07-11, ITEM 15 self-improvement audit; adversarial
-- self-audit fix — these two columns were missing from the dbt mirror entirely, which made
-- scripts/dbt_parity.py's row-level compare error out on the column and get silently reported as
-- "skipped" rather than "diffs", masking the drift class this parity check exists to catch. See
-- bigquery/01_schema.sql:state.open_orders for the live definition this mirrors.

SELECT
  item_key,
  item_type,
  strategy,
  ticker,
  status,
  due_date AS entry_window_close,
  CAST(JSON_VALUE(payload,'$.contract_id') AS INT64)          AS contract_id,
  UPPER(JSON_VALUE(payload,'$.side'))                          AS side,
  CAST(JSON_VALUE(payload,'$.qty') AS NUMERIC)                AS qty,
  CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC)        AS limit_price,
  COALESCE(JSON_VALUE(payload,'$.tif'),'DAY')                 AS tif,
  CAST(JSON_VALUE(payload,'$.convergence_target') AS NUMERIC) AS convergence_target,
  SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(payload,'$.time_exit_date')) AS time_exit_date,
  JSON_VALUE(payload,'$.instruction_id')                      AS instruction_id,
  JSON_VALUE(payload,'$.source_decision_ref')                 AS source_decision_ref,
  CAST(JSON_VALUE(payload,'$.guard_passed') AS BOOL)          AS guard_passed,
  JSON_VALUE(payload,'$.guard_reasons')                        AS guard_reasons,
  CASE WHEN UPPER(JSON_VALUE(payload,'$.side')) = 'BUY'
       THEN ROUND(CAST(JSON_VALUE(payload,'$.qty') AS NUMERIC)
                  * CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC) + 0.35, 2)
       ELSE 0 END                                             AS reserved_cash,
  event_ts AS staged_ts,
  note
FROM (
  SELECT *
  FROM {{ source('events', 'queue_events') }}
  WHERE queue = 'ORDER_STAGED'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
)
WHERE status = 'pending'

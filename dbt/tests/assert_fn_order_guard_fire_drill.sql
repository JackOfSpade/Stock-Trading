-- Singular test (passes when ZERO rows): analytics.fn_order_guard must reject 3 known-bad orders —
-- an oversized notional, an off-band limit price, and a non-positive qty.
--
-- Added 2026-07-04 (audit finding, HIGH-severity test-gap): fn_order_guard is a PARAMETERIZED
-- BigQuery table function, so it cannot be added to the standard row-parity mechanism
-- (scripts/dbt_parity.py diffs one dbt model against one live view by name — there is no fixed row
-- set to diff for a function of its call arguments). This ports ops.sp_fire_drill_order_guard's
-- exact 3 fire-drill cases (bigquery/23_trading_control.sql) as a dbt test instead, extending the
-- existing parity/test-coverage pattern to this object on its own terms rather than proposing dbt own
-- it. Read-only: fn_order_guard itself never crafts an order or writes to ops.trading_control.
SELECT case_name, passed
FROM UNNEST([
  STRUCT(
    'oversize' AS case_name,
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 500.00, FALSE)) AS passed),
  STRUCT(
    'offband',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 1, 150.00, 100.00, FALSE))),
  STRUCT(
    'negative_qty',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 100.00, FALSE)))
])
WHERE passed

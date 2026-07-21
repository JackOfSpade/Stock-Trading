-- Singular test (passes when ZERO rows): analytics.fn_order_guard must reject 2 known-bad orders — an
-- oversized notional and a non-positive qty — and must PASS-WITH-ADVISORY (not block) a 3rd, an
-- off-band limit price, per the 2026-07-20 owner-directed LIMIT DECISION redesign
-- (bigquery/99_ai_limit_decision_order_guard.sql): the equity 0.5%-off-last band is now advisory, so
-- a bad order there is a blocked craft that should have been allowed to advise (or an advisory that
-- silently never fired), not a `passed=FALSE` that should have stayed FALSE.
--
-- Added 2026-07-04 (audit finding, HIGH-severity test-gap): fn_order_guard is a PARAMETERIZED
-- BigQuery table function, so it cannot be added to the standard row-parity mechanism
-- (scripts/dbt_parity.py diffs one dbt model against one live view by name — there is no fixed row
-- set to diff for a function of its call arguments). This ports ops.sp_fire_drill_order_guard's
-- exact fire-drill cases (bigquery/99_ai_limit_decision_order_guard.sql, was
-- bigquery/23_trading_control.sql prior to the 2026-07-20 redesign) as a dbt test instead, extending
-- the existing parity/test-coverage pattern to this object on its own terms rather than proposing dbt
-- own it. Read-only: fn_order_guard itself never crafts an order or writes to ops.trading_control.
--
-- offband vector (v2, 2026-07-20): the old ('B','BUY',1,150.00,100.00,FALSE) also tripped the $50
-- notional backstop (1 sh @ $150 = $150 > $50), so it never isolated the price band on its own — see
-- bigquery/99_ai_limit_decision_order_guard.sql's fire-drill comment for the same fix applied there.
-- qty NUMERIC '0.1' keeps notional at $15 (well under both the $50 backstop and any plausible 1.5x
-- sizing_base) while keeping the same 50%-off-last ($150 limit vs $100 last).
SELECT case_name, passed, advisories
FROM UNNEST([
  STRUCT(
    'oversize' AS case_name,
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 500.00, FALSE)) AS passed,
    (SELECT advisories FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 500.00, FALSE)) AS advisories),
  STRUCT(
    'offband',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 100.00, FALSE)),
    (SELECT advisories FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 100.00, FALSE))),
  STRUCT(
    'negative_qty',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 100.00, FALSE)),
    (SELECT advisories FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 100.00, FALSE)))
])
WHERE
  -- oversize / negative_qty: a bad order that PASSED is a failure (unchanged semantics).
  (case_name IN ('oversize', 'negative_qty') AND passed)
  -- offband: either it got hard-blocked (passed=FALSE, the pre-2026-07-20 behavior reintroduced) or
  -- it passed with no advisory (the LIMIT DECISION would have nothing to weigh) — either is a failure.
  OR (case_name = 'offband' AND (NOT passed OR ARRAY_LENGTH(advisories) = 0))

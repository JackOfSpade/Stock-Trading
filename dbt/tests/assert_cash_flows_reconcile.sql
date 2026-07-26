-- Singular test (passes when ZERO rows): SUM(events.cash_flows.amount) must equal
-- SUM(analytics.strategy_nav.deposits) — i.e. strategy_nav's attributed allocation never drops or
-- double-counts a flow. Self-improvement audit B-1-exec. COUNT-AGNOSTIC (rev 2026-07-10 — Strategy
-- Arsenal autonomy conversion, owner directive): strategy_nav now enumerates the roster-derived active
-- set and splits each NULL-strategy (equal-split) flow by the AS-OF-FLOW-DATE active count, so this
-- aggregate identity holds for ANY roster size — a NULL flow allocatable to k active-on-that-date
-- strategies contributes k*(amount/k)=amount, and a strategy-tagged flow contributes its full amount.
-- The reconciliation therefore no longer depends on a fixed strategy count; it catches a genuine
-- mis-split or dropped flow under any add/retire. (A flow tagged to a since-terminated strategy is out
-- of scope — deposits are NULL-tagged equal-split by standing methodology, Operating_Protocols §13.C.)
-- scripts/check_roster_consistency.py asserts this file hardcodes no strategy count.

-- BigQuery rejects a HAVING clause on a SELECT with no FROM/GROUP BY (even referencing only its own
-- SELECT-list aliases), so the comparison has to live in an outer WHERE over a wrapped subquery.
SELECT *
FROM (
  SELECT
    (SELECT ROUND(SUM(amount), 2) FROM {{ source('events', 'cash_flows') }}) AS cash_flows_total,
    (SELECT ROUND(SUM(deposits), 2) FROM {{ ref('strategy_nav') }}) AS strategy_nav_deposits_total
)
WHERE cash_flows_total != strategy_nav_deposits_total

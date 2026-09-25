-- bigquery/246_nomadic_borrow_blocked_alert.sql (2026-09-22)
-- Project: stock-trading-498512. Apply after bigquery/168_nomadic_capital_fixes.sql (defines
-- analytics.fn_nomadic_capital_restore_plan and state.strategy_nomadic_status, both read below) and
-- bigquery/215_regime_sweep_blocked_no_recipient.sql (the exact SWEEP-side sibling pattern this file
-- extends to the BORROW side of the same capital rail).
--
-- Found 2026-09-22 while investigating an interactive-session spec-defect notice about Strategy C
-- (139 days capital-idle, 5 consecutive FOMC entry-criterion-2 rejections). The criterion itself
-- turned out sound on inspection -- 4 of 5 rejections declined to trade against an already-priced-in
-- near-certainty (86.7-98%), and the 5th (2026-09-08, a genuinely two-sided market) correctly read
-- available borrow capacity as zero. But THAT read was correct only by luck: it came from a one-off
-- W3 alert (nomadic_borrow_blocked_unsignalled) that has since been retired, not a repeatable
-- mechanism. Tracing the borrow path found the actual gap, in two parts:
--
-- CORRECTION 2026-09-24 (interactive triage of the 2026-09-23 alert cluster, after this monitor's
-- FIRST firing; re-measured against events.decision_log rather than against this header's own summary).
-- Two claims above are wrong, and both OVERSTATE what the borrow side has cost:
--   (a) THREE of the five rejections declined against an already-priced-in near-certainty -- 2026-06-08
--       (96.7% hold), 2026-06-15 (~98%), 2026-07-20 (86.7%) -- not four. The 2026-07-27 rejection faced
--       a genuinely two-sided 62-67% hold / 33-38% hike and declined on different reasoning entirely:
--       "the oil move is already priced in -- there is no informational lag to exploit."
--   (b) The 2026-09-08 entry did NOT turn on a borrow-capacity read. Its own decision_log row records
--       that the gates "were not the reason and were all open," and its candidate structures priced at
--       $5-$14 per contract -- inside C's own $23.64, so no borrow was ever required. The zero-capacity
--       measurement belongs to the SEPARATE 2026-09-07 `correction` entry ("nomadic-borrow recheck for
--       Strategy C: reachable borrow capacity is ZERO at every requested size").
-- NET: criterion 2, not funding, is the proximate cause of 5 of 5 rejections; C has never opened a
-- position (zero rows in events.position_events) and the REALIZED cost of the blocked borrow is $0.
-- This does NOT make the monitor redundant -- the exposure is forward-looking, since a criterion-2 GO
-- could still be capped out of the richer $26-$65 structures this history has twice priced, while the
-- cheapest deep-OTM wings remain affordable on C's own cash. But do NOT cite this file as evidence
-- that a trade has been lost to zero donor capacity. None has.
--
--   1. analytics.fn_nomadic_capital_restore_plan (bigquery/167, redefined 168) returns ZERO ROWS when
--      a nomadic strategy has NO eligible donor at all (the `donors` CTE is empty, so `dt.total` is
--      NULL, so the `WHERE dt.total > 0` guard on `funded` drops the whole result). A real borrow
--      request that finds no donor is therefore indistinguishable, to any caller, from a request that
--      was never made -- the exact ambiguous-empty-result class bigquery/168 FIX5 already fixed once
--      for the sibling SWEEP view (state.nomadic_capital_sync_pending's blocked_no_recipient row).
--      This file adds the same fix here: an explicit blocked_no_donor=TRUE row instead of silence.
--
--   2. The SWEEP side of the capital rail has a STANDING daily check (state.nomadic_capital_sync_pending,
--      scanned by D2a every run) with a registered alert (nomadic_sweep_blocked, bigquery/168 FIX5b).
--      The BORROW side has neither -- fn_nomadic_capital_restore_plan is parameterized and only ever
--      evaluated on demand, by whichever routine happens to be sizing a specific trade that specific
--      day, so there is no proactive signal that a nomadic strategy currently has zero borrow capacity
--      until something actually tries to borrow and (pre-fix-1-above) fails silently. This file adds
--      that standing check as state.nomadic_borrow_capacity_watch, read daily by D2a exactly the way
--      the sweep side already is (task_plan/D2a.md edit is a separate, non-SQL change alongside this
--      file), and registers the new nomadic_borrow_blocked category to report it.
--
-- Both fixes are additive and read-only against existing tables -- no object this file touches has any
-- real ledger history to preserve (this is detection/reporting layer only; no cash movement changes).

-- ===== 1. analytics.fn_nomadic_capital_restore_plan -- explicit blocked_no_donor row on an empty
-- donor pool, instead of zero rows. SUPERSEDES bigquery/168_nomadic_capital_fixes.sql's definition.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`(
  p_strategy STRING, p_amount_needed NUMERIC
)
AS (
  WITH ctrl AS (
    SELECT enabled AS control_enabled FROM `stock-trading-498512.state.nomadic_capital_control_latest`
  ),
  donors AS (
    SELECT e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
    FROM `stock-trading-498512.state.strategy_capital_enablement` e
    JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = e.strategy_code
    WHERE e.capital_enabled
      AND e.strategy_code != p_strategy
      AND e.strategy_code NOT IN (
        SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
        WHERE is_low_frequency_by_design
      )
      AND nv.available_funds > 0
  ),
  dt AS (SELECT SUM(donor_capacity) AS total FROM donors),
  funded AS (
    -- The amount actually sourceable RIGHT NOW. p_amount_needed is the AI's own seven-factor-justified
    -- size and is never second-guessed here -- but it CAN exceed what the pool holds, and the caller
    -- must be able to see that (bigquery/168 FIX6, unchanged here).
    SELECT LEAST(p_amount_needed, dt.total) AS funded_amount, dt.total AS donor_total
    FROM dt WHERE dt.total > 0
  ),
  alloc AS (
    SELECT
      d.donor_strategy,
      d.donor_capacity,
      f.funded_amount,
      ROUND(f.funded_amount * d.donor_capacity / f.donor_total, 2)  AS raw_amount,
      ROW_NUMBER() OVER (ORDER BY d.donor_strategy)                 AS rn,
      COUNT(*)     OVER ()                                          AS n_d,
      SUM(ROUND(f.funded_amount * d.donor_capacity / f.donor_total, 2))
        OVER (ORDER BY d.donor_strategy ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_sum
    FROM donors d
    CROSS JOIN funded f
  ),
  funded_rows AS (
    SELECT
      p_strategy                                                      AS strategy,
      a.donor_strategy                                                AS donor_strategy,
      a.donor_capacity                                                AS donor_capacity,
      -- Last donor absorbs the residual so SUM(pull_amount) == plan_total exactly (bigquery/168 FIX3).
      CASE WHEN a.rn = a.n_d THEN a.funded_amount - COALESCE(a.prior_sum, CAST(0 AS NUMERIC))
           ELSE a.raw_amount END                                      AS pull_amount,
      a.funded_amount                                                 AS plan_total,
      p_amount_needed                                                 AS requested_amount,
      (a.funded_amount >= p_amount_needed)                            AS is_fully_funded,
      FALSE                                                            AS blocked_no_donor
    FROM alloc a
  ),
  -- NEW. When the donor pool is entirely empty, `funded` (and therefore `alloc`) return zero rows --
  -- silently identical, to any caller, to "nothing was needed." A real borrow request that finds no
  -- donor at all must surface as a ROW, never as silence.
  blocked_rows AS (
    SELECT
      p_strategy                    AS strategy,
      CAST(NULL AS STRING)          AS donor_strategy,
      CAST(NULL AS NUMERIC)         AS donor_capacity,
      CAST(NULL AS NUMERIC)         AS pull_amount,
      CAST(0 AS NUMERIC)            AS plan_total,
      p_amount_needed                AS requested_amount,
      FALSE                          AS is_fully_funded,
      TRUE                           AS blocked_no_donor
    FROM (SELECT 1) AS one_row
    WHERE p_amount_needed > 0 AND NOT EXISTS (SELECT 1 FROM donors)
  )
  SELECT r.*, ctrl.control_enabled
  FROM (SELECT * FROM funded_rows UNION ALL SELECT * FROM blocked_rows) AS r
  CROSS JOIN ctrl
);

-- ===== 2. state.nomadic_borrow_capacity_watch -- the STANDING daily check the sweep side already had
-- (state.nomadic_capital_sync_pending) and the borrow side never got. One row per currently-nomadic,
-- capital-enabled strategy; borrow_blocked=TRUE when every OTHER capital-enabled, non-nomadic strategy
-- is itself at zero/negative available_funds, computed fresh every read (no p_amount_needed parameter
-- -- this is a capacity check, not a specific-request check, so it is true or false independent of
-- whether any routine happened to ask for money today).
CREATE OR REPLACE VIEW `stock-trading-498512.state.nomadic_borrow_capacity_watch` AS
WITH nomadic_strategies AS (
  SELECT strategy_code
  FROM `stock-trading-498512.state.strategy_nomadic_status`
  WHERE is_nomadic AND capital_enabled
),
nav AS (
  SELECT strategy, available_funds FROM `stock-trading-498512.analytics.strategy_nav`
),
low_freq AS (
  SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
  WHERE is_low_frequency_by_design
),
donors AS (
  -- Same eligibility predicate as fn_nomadic_capital_restore_plan's own `donors` CTE above, applied
  -- per potential borrower rather than for one parameterized call.
  SELECT ns.strategy_code AS borrower, e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
  FROM nomadic_strategies ns
  CROSS JOIN `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN nav nv ON nv.strategy = e.strategy_code
  WHERE e.capital_enabled
    AND e.strategy_code != ns.strategy_code
    AND e.strategy_code NOT IN (SELECT strategy_code FROM low_freq)
    AND nv.available_funds > 0
)
SELECT
  ns.strategy_code                                       AS strategy,
  COALESCE(SUM(d.donor_capacity), CAST(0 AS NUMERIC))    AS donor_capacity_total,
  COUNT(d.donor_strategy)                                AS donor_count,
  COALESCE(SUM(d.donor_capacity), CAST(0 AS NUMERIC)) <= 0 AS borrow_blocked
FROM nomadic_strategies ns
LEFT JOIN donors d ON d.borrower = ns.strategy_code
GROUP BY ns.strategy_code;

-- ===== 3. Register the alert category the blocked-borrow row is reported through -- the exact
-- BORROW-side sibling of nomadic_sweep_blocked (bigquery/168 FIX5b). Guarded INSERT, same idempotent
-- shape bigquery/163, bigquery/164 and bigquery/168 use.
--
-- WARNING, never critical, and deliberately so, for the identical reason nomadic_sweep_blocked is a
-- warning: bigquery/176_decouple_embedding_health_from_trading_gate.sql's blocking_criticals CASE
-- counts severity='critical' rows and freezes ALL order staging system-wide (bigquery/107 carried this
-- logic originally but is SUPERSEDED LIVE by 176 as of 2026-08-17 -- cite 176, not 107, going forward).
-- A capital-ROUTING condition must never halt trading -- a blocked borrow just means the AI must size
-- within its own idle cash for now, the same discipline every other (non-nomadic) strategy carries.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'nomadic_borrow_blocked' AS category,
    FALSE AS latching,
    'Auto-resolves when state.nomadic_borrow_capacity_watch stops reporting borrow_blocked=TRUE for this strategy -- i.e. when at least one other capital-ENABLED, NON-NOMADIC strategy holds positive available_funds again (a router re-enable, a roster change, or a position closing).' AS resolve_rule,
    'A NOMADIC strategy (holds no standing capital by design, borrows on-demand pro-rata from other enabled strategies) currently has ZERO eligible donors -- every other capital-enabled strategy is itself nomadic, disabled, or at zero available_funds. A borrow attempt right now would return no fundable amount. Registered 2026-09-22 alongside bigquery/246, which also fixed analytics.fn_nomadic_capital_restore_plan to return an explicit blocked_no_donor=TRUE row instead of silently returning zero rows on an empty donor pool. This is the BORROW-side sibling of nomadic_sweep_blocked (bigquery/168): the capital rail had a raise-and-heal path for stranded idle cash on the sweep side but none for a blocked borrow -- found while investigating a Strategy C spec-defect notice (2026-09-08 FOMC entry, which happened to get a correct zero-donor read that day via a since-retired one-off alert, not a repeatable mechanism). WARNING by design, never critical -- would otherwise enter bigquery/176 blocking_criticals and halt all order staging over a pure capital-routing condition.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Borrow plan now always returns a row for a real request, blocked or funded:
--    SELECT * FROM `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`('C', 500.00);
--    -> if any donor exists, unchanged prior behavior (funded/partially-funded rows, blocked_no_donor
--       FALSE on every row). If no donor exists, exactly ONE row: donor_strategy NULL, plan_total 0,
--       is_fully_funded FALSE, blocked_no_donor TRUE.
--    SELECT * FROM `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`('C', 0.00);
--    -> zero rows still expected for a non-positive request (unchanged -- nothing to fund).
--
-- 2. Standing watch reports one row per nomadic+enabled strategy today:
--    SELECT * FROM `stock-trading-498512.state.nomadic_borrow_capacity_watch` ORDER BY strategy;
--
-- 3. New category registered exactly once:
--    SELECT * FROM `stock-trading-498512.ops.alert_policy` WHERE category = 'nomadic_borrow_blocked';
--    -> expect exactly 1 row, latching FALSE.

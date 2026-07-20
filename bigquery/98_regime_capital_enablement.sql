-- 98_regime_capital_enablement.sql — Regime-Capital Enablement (owner directive 2026-07-19 evening)
--
-- A regime-router DO-NOT-ACTIVATE strategy is CAPITAL-DISABLED: it receives zero capital allocation
-- and its previously allocated capital sweeps to the capital-enabled strategies (AI capital-allocation
-- call, trigger='regime_disable'); a mechanical debt-tracked RESTORE returns the swept capital when the
-- strategy re-enables (trigger='regime_enable'). Canonical prose: Operating_Protocols.md §16
-- REGIME-CAPITAL SYNC + §13.C; executor: D2a Step 0 REGIME-CAPITAL SYNC substep (Claude_Task_Plan.md).
-- Movements are atomic $0-sum events.cash_flows double-entries tagged source='regime_capital_sweep' /
-- 'regime_capital_restore' (the `source` column exists since bigquery/22).
--
-- RECONSTRUCTION NOTE (W5 2026-07-19): the 2026-07-19 evening session APPLIED these objects live via
-- the BigQuery MCP and executed the first sweep (A → B/C/D/E, $1,889.37), but its repo edits were
-- stranded (no branch ever pushed). This file was reconstructed by W5 from the live
-- INFORMATION_SCHEMA.TABLES ddl of the five objects, verbatim except CREATE TABLE IF NOT EXISTS /
-- guarded seed. Apply-in-order safe: re-running is a no-op against the live state.
--
-- Objects:
--   ops.capital_control                    — append-only kill-switch (latest row wins)
--   state.capital_control_latest           — latest-row view of the switch
--   state.strategy_capital_enablement      — per-strategy capital_enabled/capital_disabled predicate
--   state.regime_capital_debt              — swept-out minus restored, per strategy
--   state.regime_capital_sync_pending      — pre-computed SWEEP/RESTORE movements for D2a

-- Kill-switch (analog of ops.park_control / ops.arsenal_control / ops.trading_control).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.capital_control`
(
  control_id STRING DEFAULT GENERATE_UUID(),
  control_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  enabled BOOL NOT NULL,
  reason STRING,
  set_by STRING,
  PRIMARY KEY (control_id) NOT ENFORCED
)
PARTITION BY DATE(control_ts)
OPTIONS(
  description="Append-only regime-capital-sync kill-switch (owner directive 2026-07-19 Regime-Capital Enablement; analog of ops.park_control / ops.arsenal_control / ops.trading_control). Latest row by control_ts wins (state.capital_control_latest). enabled=FALSE means the D2a REGIME-CAPITAL SYNC substep records what it would have moved and moves nothing; deposit-routing rules in Operating_Protocols section 13.C are unaffected by this switch. No pin column -- there is no vehicle/strategy analog to pin. Seeded enabled=TRUE so the loop starts open; flip with a manual INSERT. No stored-procedure gate on this table by design -- see bigquery/98_regime_capital_enablement.sql."
);

-- Seed: loop starts open. Guarded so re-apply never duplicates (the live seed row already exists).
INSERT INTO `stock-trading-498512.ops.capital_control` (enabled, reason, set_by)
SELECT TRUE, 'seed — regime-capital sync enabled (owner directive 2026-07-19)', 'bigquery/98 seed'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.capital_control`);

CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_control_latest`
AS WITH ctrl AS (
  SELECT ARRAY_AGG(
           STRUCT(enabled, reason, set_by, control_ts)
           ORDER BY control_ts DESC LIMIT 1
         )[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.capital_control`
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  ctrl.latest.reason                   AS reason,
  ctrl.latest.set_by                   AS set_by,
  ctrl.latest.control_ts               AS control_ts
FROM ctrl;

-- Per-strategy predicate. 1-session before-today cutoff: only STRATEGY_ACTIVATION rows with event_ts
-- BEFORE today (America/Denver) qualify, so a same-day router flip never triggers a same-session
-- capital move.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_capital_enablement`
AS WITH td AS (
  SELECT today FROM `stock-trading-498512.state.trading_day_today`
),
qualifying AS (
  SELECT re.key AS strategy_code, re.value, re.event_ts
  FROM `stock-trading-498512.events.regime_events` re
  CROSS JOIN td
  WHERE re.scope = 'STRATEGY_ACTIVATION'
    AND DATE(re.event_ts, 'America/Denver') < td.today
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY re.key
    ORDER BY re.as_of_date DESC, re.event_ts DESC, re.event_id DESC
  ) = 1
)
SELECT
  r.strategy_code,
  q.value                                                      AS latest_activation_value,
  q.event_ts                                                   AS latest_activation_ts,
  COALESCE(UPPER(q.value) LIKE '%DO-NOT-ACTIVATE%', FALSE)     AS capital_disabled,
  NOT COALESCE(UPPER(q.value) LIKE '%DO-NOT-ACTIVATE%', FALSE) AS capital_enabled
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN qualifying q ON q.strategy_code = r.strategy_code
WHERE r.is_active;

-- Debt ledger: what regime sweeps took out of each strategy minus what restores gave back.
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_capital_debt`
AS WITH swept AS (
  SELECT strategy, -SUM(amount) AS swept_out_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'regime_capital_sweep' AND amount < 0
  GROUP BY strategy
),
restored AS (
  SELECT strategy, SUM(amount) AS restored_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'regime_capital_restore' AND amount > 0
  GROUP BY strategy
)
SELECT
  r.strategy_code                                                               AS strategy,
  COALESCE(sw.swept_out_total, 0)                                               AS swept_out_total,
  COALESCE(rs.restored_total, 0)                                                AS restored_total,
  GREATEST(0, COALESCE(sw.swept_out_total, 0) - COALESCE(rs.restored_total, 0)) AS outstanding_debt
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN swept    sw ON sw.strategy = r.strategy_code
LEFT JOIN restored rs ON rs.strategy = r.strategy_code;

-- Pending-movement surface for the D2a substep. SWEEP rows: a capital-disabled strategy holding
-- available_funds >= $25 (counterparty rows carry the equal-share baseline the AI call starts from).
-- RESTORE rows: a re-enabled debtor's outstanding debt, pro-rata across enabled donors' available_funds
-- (capped at donor capacity; >= $25-or-full-debt floor). D2a executes ONE movement per read
-- (Operating_Protocols.md §16 — stale-snapshot rule).
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_capital_sync_pending`
AS WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_control_latest`
),
enablement AS (
  SELECT * FROM `stock-trading-498512.state.strategy_capital_enablement`
),
enabled_set AS (
  SELECT strategy_code FROM enablement WHERE capital_enabled
),
n_enabled AS (
  SELECT COUNT(*) AS n FROM enabled_set
),
nav AS (
  SELECT strategy, ROUND(available_funds, 2) AS available_funds
  FROM `stock-trading-498512.analytics.strategy_nav`
),
sweep_candidates AS (
  SELECT e.strategy_code AS strategy, nv.available_funds AS amount
  FROM enablement e
  JOIN nav nv ON nv.strategy = e.strategy_code
  WHERE e.capital_disabled AND nv.available_funds >= 25
),
sweep_rows AS (
  SELECT
    'SWEEP'                     AS action,
    sc.strategy,
    sc.amount,
    es.strategy_code            AS counterparty_strategy,
    ROUND(sc.amount / n.n, 2)   AS counterparty_baseline_amount
  FROM sweep_candidates sc
  CROSS JOIN n_enabled n
  CROSS JOIN enabled_set es
),
debt AS (
  SELECT strategy, outstanding_debt
  FROM `stock-trading-498512.state.regime_capital_debt`
  WHERE outstanding_debt > 0
),
restore_candidates AS (
  SELECT es.strategy_code AS strategy, d.outstanding_debt
  FROM enabled_set es
  JOIN debt d ON d.strategy = es.strategy_code
),
donors AS (
  SELECT rc.strategy AS debtor, nv.strategy AS donor_strategy, nv.available_funds AS donor_capacity
  FROM restore_candidates rc
  JOIN enabled_set es ON es.strategy_code != rc.strategy
  JOIN nav nv ON nv.strategy = es.strategy_code
  WHERE nv.available_funds > 0
),
donor_totals AS (
  SELECT debtor, SUM(donor_capacity) AS total_donor_capacity
  FROM donors
  GROUP BY debtor
),
restore_payable AS (
  SELECT
    rc.strategy,
    rc.outstanding_debt,
    LEAST(rc.outstanding_debt, COALESCE(dt.total_donor_capacity, 0)) AS payable
  FROM restore_candidates rc
  LEFT JOIN donor_totals dt ON dt.debtor = rc.strategy
),
restore_rows AS (
  SELECT
    'RESTORE'                                                          AS action,
    rp.strategy,
    ROUND(rp.payable, 2)                                               AS amount,
    dn.donor_strategy                                                  AS counterparty_strategy,
    ROUND(rp.payable * dn.donor_capacity / dt.total_donor_capacity, 2) AS counterparty_baseline_amount
  FROM restore_payable rp
  JOIN donor_totals dt ON dt.debtor = rp.strategy
  JOIN donors dn ON dn.debtor = rp.strategy
  WHERE rp.payable >= LEAST(25, rp.outstanding_debt)
)
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, ctrl.control_enabled
FROM sweep_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, ctrl.control_enabled
FROM restore_rows CROSS JOIN ctrl
ORDER BY action, strategy, counterparty_strategy;

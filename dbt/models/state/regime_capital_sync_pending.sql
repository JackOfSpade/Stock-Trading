-- Parallel-run dbt port of bigquery/168_nomadic_capital_fixes.sql:state.regime_capital_sync_pending — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH ctrl AS (
  SELECT enabled AS control_enabled FROM {{ ref('capital_control_latest') }}
),
enablement AS (
  SELECT * FROM {{ ref('strategy_capital_enablement') }}
),
nomadic AS (
  SELECT strategy_code FROM {{ source('state_external', 'strategy_declared_frequency') }}
  WHERE is_low_frequency_by_design
),
-- Who may RECEIVE a regime sweep, and who may DONATE to a regime restore: nomadic strategies excluded,
-- because a nomadic strategy holds no standing capital (it would only have to be swept out again).
enabled_recipients AS (
  SELECT strategy_code FROM enablement e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (SELECT strategy_code FROM nomadic)
),
-- Who may be REPAID a pre-existing regime debt: bigquery/98's ORIGINAL, nomadic-INCLUSIVE semantics.
-- Being nomadic must never make an existing debt unrestorable -- that was the bigquery/167 defect
-- (FIX 7). A nomadic debtor is repaid normally; its own sweep may then move that capital on, which is
-- a one-time hand-off from the regime ledger to the nomadic ledger, not a loop.
enabled_debtors AS (
  SELECT strategy_code FROM enablement e WHERE e.capital_enabled
),
n_enabled AS (
  SELECT COUNT(*) AS n FROM enabled_recipients
),
nav AS (
  SELECT strategy, ROUND(available_funds, 2) AS available_funds
  FROM {{ ref('strategy_nav') }}
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
  CROSS JOIN enabled_recipients es
),
debt AS (
  SELECT strategy, outstanding_debt
  FROM {{ ref('regime_capital_debt') }}
  WHERE outstanding_debt > 0
),
restore_candidates AS (
  SELECT es.strategy_code AS strategy, d.outstanding_debt
  FROM enabled_debtors es
  JOIN debt d ON d.strategy = es.strategy_code
),
donors AS (
  SELECT rc.strategy AS debtor, nv.strategy AS donor_strategy, nv.available_funds AS donor_capacity
  FROM restore_candidates rc
  JOIN enabled_recipients es ON es.strategy_code != rc.strategy
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
ORDER BY action, strategy, counterparty_strategy

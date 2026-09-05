-- Parallel-run dbt port of bigquery/223_regime_restore_blocked_zero_payable.sql:state.regime_capital_sync_pending — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
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
enabled_recipients AS (
  SELECT strategy_code FROM enablement e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (SELECT strategy_code FROM nomadic)
),
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
    ROUND(sc.amount / n.n, 2)   AS counterparty_baseline_amount,
    FALSE                       AS blocked_no_recipient,
    CAST(NULL AS STRING)        AS blocked_reason
  FROM sweep_candidates sc
  CROSS JOIN n_enabled n
  CROSS JOIN enabled_recipients es
),
-- bigquery/215: capital to sweep, but every capital-enabled strategy is itself nomadic, so there is
-- nowhere legal to put it. Without this branch the CROSS JOIN above yields zero rows and a
-- whole-roster deactivation is indistinguishable from the healthy empty-view steady state.
sweep_blocked AS (
  SELECT
    'SWEEP'                     AS action,
    sc.strategy,
    sc.amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_baseline_amount,
    TRUE                        AS blocked_no_recipient,
    'no_eligible_recipient'     AS blocked_reason
  FROM sweep_candidates sc
  WHERE NOT EXISTS (SELECT 1 FROM enabled_recipients)
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
-- bigquery/223: how many ELIGIBLE recipients OTHER THAN the debtor itself exist, per restore
-- candidate. This is the only thing that separates the two ways a restore can reach payable = 0, and
-- they call for different operator responses: zero others means the roster has collapsed to the
-- debtor (a router/roster question), while others exist but hold no funds means the book is fully
-- deployed (a capital question that clears itself as positions close). LEFT JOIN + COUNTIF rather
-- than a correlated EXISTS: BigQuery rejects a correlated subquery over another relation unless it
-- can de-correlate it.
restore_recipient_reach AS (
  SELECT rc.strategy, COUNTIF(es.strategy_code IS NOT NULL) AS other_recipients
  FROM restore_candidates rc
  LEFT JOIN enabled_recipients es ON es.strategy_code != rc.strategy
  GROUP BY rc.strategy
),
restore_rows AS (
  SELECT
    'RESTORE'                                                          AS action,
    rp.strategy,
    ROUND(rp.payable, 2)                                               AS amount,
    dn.donor_strategy                                                  AS counterparty_strategy,
    ROUND(rp.payable * dn.donor_capacity / dt.total_donor_capacity, 2) AS counterparty_baseline_amount,
    FALSE                                                              AS blocked_no_recipient,
    CAST(NULL AS STRING)                                               AS blocked_reason
  FROM restore_payable rp
  JOIN donor_totals dt ON dt.debtor = rp.strategy
  JOIN donors dn ON dn.debtor = rp.strategy
  WHERE rp.payable >= LEAST(25, rp.outstanding_debt)
),
-- bigquery/223: the mirror image of sweep_blocked, keyed on the condition that actually silences a
-- restore. bigquery/215 keyed this on an empty enabled_recipients -- the SWEEP's exact complement,
-- but strictly narrower than the restore's: `donors` self-excludes the debtor and requires positive
-- available_funds, so payable reaches 0 with a NON-empty recipient set whenever the only eligible
-- recipient IS the debtor, or every recipient is fully deployed. payable = 0 subsumes the empty
-- set (no recipients -> no donors -> payable 0), so this REPLACES that guard rather than joining it:
-- two branches would emit two rows for one candidate. Mutually exclusive with restore_rows by
-- construction -- restore_candidates admits only outstanding_debt > 0, so LEAST(25, outstanding_debt)
-- is strictly positive and payable = 0 can never clear it. A nonzero payable below that floor is a
-- THROTTLE, not a block, and is deliberately not reported here (see this file's header).
restore_blocked AS (
  SELECT
    'RESTORE'                   AS action,
    rp.strategy,
    rp.outstanding_debt         AS amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_baseline_amount,
    TRUE                        AS blocked_no_recipient,
    CASE WHEN rr.other_recipients = 0 THEN 'no_eligible_recipient'
         ELSE 'no_donor_capacity' END AS blocked_reason
  FROM restore_payable rp
  JOIN restore_recipient_reach rr ON rr.strategy = rp.strategy
  WHERE rp.payable = 0
)
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM sweep_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM sweep_blocked CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM restore_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM restore_blocked CROSS JOIN ctrl
ORDER BY action, strategy, counterparty_strategy

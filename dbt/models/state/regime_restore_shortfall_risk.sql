-- Parallel-run dbt port of bigquery/168_nomadic_capital_fixes.sql:state.regime_restore_shortfall_risk — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH donors AS (
  -- Donor capacity is the capital-ENABLED strategies' undeployed cash -- the same figure bigquery/98's
  -- restore_payable caps against. NOMADIC strategies are excluded (bigquery/168 FIX 8) to stay aligned
  -- with state.regime_capital_sync_pending's donor set, which excluded them as of bigquery/167: a
  -- nomadic strategy holds ~$0 under steady state, so counting it as donor capacity would overstate
  -- how much of a debt could actually be honoured.
  SELECT ROUND(COALESCE(SUM(GREATEST(n.available_funds, 0)), 0), 2) AS donor_capacity
  FROM {{ ref('strategy_capital_enablement') }} e
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = e.strategy_code
  LEFT JOIN {{ ref('strategy_nav') }} n ON n.strategy = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
    AND e.strategy_code NOT IN (
      SELECT strategy_code FROM {{ source('state_external', 'strategy_declared_frequency') }}
      WHERE is_low_frequency_by_design
    )
),
debt AS (
  SELECT d.strategy, ROUND(d.outstanding_debt, 2) AS outstanding_debt
  FROM {{ ref('regime_capital_debt') }} d
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = d.strategy
  -- A TERMINATED strategy's debt is extinguished by unreachability (Operating_Protocols.md: RESTORE
  -- targets the enabled set, which filters WHERE is_active), so an inactive strategy's nominal debt
  -- must not be counted here or this view over-reports risk the moment the first termination lands.
  WHERE r.is_active AND d.outstanding_debt > 0
),
-- THE THIRD AND FOURTH CLAIMS ON THE SAME POOL. Independent mechanisms draw on the capital-enabled
-- strategies' idle cash and none of them can see the others: regime-debt RESTORE (above), the SISA
-- PENDING-NEWCOMER probe-stake fill (bigquery/62), external WITHDRAWALS (bigquery/161), and -- added
-- 2026-08-11, bigquery/167 -- a NOMADIC strategy's on-demand BORROW, which draws pro-rata from this
-- same non-nomadic donor pool at order-craft time. The borrow is not pre-declarable (it happens only
-- when a thesis needs it) so it cannot be added as a standing claim column here; it is called out so a
-- reader knows the headroom below is an upper bound that a nomadic borrow can consume without notice.
newcomer AS (
  SELECT ROUND(COALESCE(SUM(GREATEST(funding_gap_dollars, 0)), 0), 2) AS pending_newcomer_claim
  FROM {{ ref('strategy_probe_funding_gap') }}
)
SELECT
  debt.strategy,
  ROUND(COALESCE(debt.outstanding_debt, 0), 2) AS outstanding_debt,
  donors.donor_capacity,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS total_outstanding_debt,
  newcomer.pending_newcomer_claim,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim, 2)
    AS total_claims_on_idle_pool,
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS aggregate_headroom,
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0)
        - newcomer.pending_newcomer_claim, 2) AS headroom_after_all_claims,
  ROUND(LEAST(COALESCE(debt.outstanding_debt, 0), donors.donor_capacity), 2) AS would_restore_today,
  ROUND(GREATEST(COALESCE(debt.outstanding_debt, 0) - donors.donor_capacity, 0), 2) AS shortfall_if_alone,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0)) AS aggregate_at_risk,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim)
    AS at_risk_including_newcomer_claim,
  (donors.donor_capacity < COALESCE(debt.outstanding_debt, 0)) AS individually_at_risk,
  debt.strategy IS NULL AS is_all_clear_row
FROM donors CROSS JOIN newcomer LEFT JOIN debt ON TRUE

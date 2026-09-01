-- Parallel-run dbt port of bigquery/161_withdrawal_after_the_fact.sql:state.withdrawal_capacity — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH base AS (
  SELECT
    sn.strategy,
    ROUND(sn.available_funds, 2) AS available_funds,
    ROUND(sn.nav, 2) AS nav,
    ROUND(sn.deployed_mv, 2) AS deployed_mv,
    COALESCE(pg.funding_gap_dollars, 0) AS probe_funding_gap,
    COALESCE(ce.capital_disabled, FALSE) AS capital_disabled,
    COALESCE(sr.is_active, FALSE) AS roster_active,
    -- Debt owed to a TERMINATED strategy is extinguished (Operating_Protocols.md:553) -- but by
    -- UNREACHABILITY, not by a zeroing write: state.regime_capital_debt itself has no is_active or
    -- retired_date filter, so a terminated strategy keeps reporting outstanding_debt forever even
    -- though bigquery/98's RESTORE can never fire for it again (RESTORE targets enabled_set, which
    -- filters WHERE r.is_active). Summing the raw column here would therefore over-report the debt
    -- the moment the first termination lands, making restore headroom look worse than it is. Zero it
    -- for an inactive strategy so this view stays true after a termination.
    CASE WHEN COALESCE(sr.is_active, FALSE) THEN COALESCE(rd.outstanding_debt, 0) ELSE 0 END
      AS outstanding_regime_debt
  FROM {{ ref('strategy_nav') }} sn
  LEFT JOIN {{ ref('strategy_probe_funding_gap') }} pg
    ON pg.strategy_code = sn.strategy
  LEFT JOIN {{ ref('strategy_capital_enablement') }} ce
    ON ce.strategy_code = sn.strategy
  LEFT JOIN {{ ref('regime_capital_debt') }} rd
    ON rd.strategy = sn.strategy
  LEFT JOIN {{ source('state_external', 'strategy_roster') }} sr
    ON sr.strategy_code = sn.strategy
),
scored AS (
  SELECT *,
    -- nav_basis = the share of the withdrawal this strategy SHOULD bear (its size in the portfolio).
    -- cap = the most it CAN actually pay (its idle cash). The two differ for a deployed strategy, and
    -- the procedure's waterfall reconciles them by redistributing whatever a strategy cannot absorb.
    -- A PROBE newcomer still below its stake floor is zeroed on BOTH: it neither bears a share nor
    -- donates cash, mirroring the deposit-side newcomer-first-claim that built that stake up.
    CASE WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 0 ELSE GREATEST(nav, 0) END AS nav_basis,
    CASE WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 0 ELSE GREATEST(available_funds, 0) END AS cap,
    -- A donor must hold idle cash AND not be a newcomer below its probe-stake floor. capital_disabled
    -- is deliberately NOT a disqualifier: a disabled strategy has already been swept to zero idle, so
    -- its cap is 0 and it saturates immediately -- while keying on the FLAG would refuse every
    -- withdrawal in the reachable state where every strategy is DO-NOT-ACTIVATE at once (bigquery/98's
    -- sweep CROSS JOINs enabled_set and silently produces zero rows, leaving the capital sitting in
    -- the disabled strategies' own balances).
    (available_funds > 0 AND COALESCE(probe_funding_gap, 0) <= 0) AS is_donor,
    CASE
      WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 'PROBE newcomer below its 2000.00 stake floor - protected'
      WHEN available_funds <= 0 AND nav > 0 THEN 'bears a share by NAV but holds no idle cash - clamps to zero, share redistributes'
      WHEN available_funds <= 0 THEN 'no idle cash'
      ELSE NULL
    END AS exclusion_reason
  FROM base
)
SELECT
  strategy,
  available_funds,
  nav,
  deployed_mv,
  capital_disabled,
  roster_active,
  probe_funding_gap,
  nav_basis,
  cap,
  is_donor,
  exclusion_reason,
  ROUND(SUM(cap) OVER (), 2) AS total_donor_capacity,
  ROUND(SUM(nav_basis) OVER (), 2) AS total_nav_basis,
  -- Unclamped NAV-proportional target, for inspection only. The procedure's waterfall clamps this to
  -- `cap` and redistributes the overflow, so a strategy's actual charge can be less than this (never
  -- more). Where cap >= this target for every strategy, the two coincide.
  SAFE_DIVIDE(nav_basis, SUM(nav_basis) OVER ()) AS nav_share,
  outstanding_regime_debt,
  ROUND(SUM(outstanding_regime_debt) OVER (), 2) AS total_outstanding_regime_debt,
  -- What would remain to service the regime-capital debt if the full donor capacity were withdrawn.
  -- Negative means a full-capacity withdrawal would leave bigquery/98's RESTORE unable to repay the
  -- disabled strategies in full. Reported, never enforced (owner decision 2026-08-10).
  ROUND(SUM(cap) OVER () - SUM(outstanding_regime_debt) OVER (), 2)
    AS restore_headroom_after_full_capacity
FROM scored

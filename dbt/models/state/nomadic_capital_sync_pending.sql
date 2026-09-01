-- Parallel-run dbt port of bigquery/168_nomadic_capital_fixes.sql:state.nomadic_capital_sync_pending — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH ctrl AS (
  SELECT enabled AS control_enabled FROM {{ ref('nomadic_capital_control_latest') }}
),
sns AS (
  SELECT strategy_code, is_nomadic, capital_enabled, sweep_now, sweepable_amount
  FROM {{ ref('strategy_nomadic_status') }}
),
-- The >=25 floor is a de-minimis MOVEMENT threshold (avoids dust cash_flows rows), NOT a retained
-- reserve: it is the same figure bigquery/98's regime sweep uses. Below it, the balance simply waits.
-- Documented as such in Operating_Protocols.md §16 -- the earlier "no floor whatsoever" wording was
-- corrected in the same change (audit findings 8/17).
sweeping AS (
  SELECT strategy_code, sweepable_amount FROM sns WHERE sweep_now AND sweepable_amount >= 25
),
recipients AS (
  SELECT s.strategy_code, GREATEST(nv.available_funds, CAST(0 AS NUMERIC)) AS available_funds
  FROM sns s
  JOIN {{ ref('strategy_nav') }} nv ON nv.strategy = s.strategy_code
  WHERE s.capital_enabled AND NOT s.is_nomadic
),
rt AS (SELECT SUM(available_funds) AS total, COUNT(*) AS n FROM recipients),
weights AS (
  SELECT r.strategy_code,
    CASE
      -- Plain pro-rata to each recipient's own available_funds (owner directive: "borrows
      -- proportionally from all other enabled strategies", applied symmetrically to the sweep-out leg).
      WHEN rt.total > 0 THEN r.available_funds / rt.total
      -- Equal split ONLY when every eligible recipient reads exactly $0. CAST keeps the CASE NUMERIC
      -- (a bare `1.0` literal is FLOAT64 and silently retyped the whole money column -- FIX 4).
      ELSE CAST(1 AS NUMERIC) / CAST(rt.n AS NUMERIC)
    END AS share
  FROM recipients r CROSS JOIN rt
),
alloc AS (
  SELECT
    s.strategy_code                                              AS strategy,
    s.sweepable_amount                                           AS amount,
    w.strategy_code                                              AS counterparty_strategy,
    ROUND(s.sweepable_amount * w.share, 2)                       AS raw_amount,
    ROW_NUMBER() OVER (PARTITION BY s.strategy_code ORDER BY w.strategy_code) AS rn,
    COUNT(*)     OVER (PARTITION BY s.strategy_code)             AS n_cp,
    SUM(ROUND(s.sweepable_amount * w.share, 2))
      OVER (PARTITION BY s.strategy_code ORDER BY w.strategy_code
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)    AS prior_sum
  FROM sweeping s
  CROSS JOIN weights w
),
allocated AS (
  SELECT
    'SWEEP'                     AS action,
    strategy,
    amount,
    counterparty_strategy,
    -- LAST recipient absorbs the rounding residual, so SUM(counterparty_amount) == amount EXACTLY,
    -- for any recipient count. Same convention as bigquery/98's regime sweep (FIX 3).
    CASE WHEN rn = n_cp THEN amount - COALESCE(prior_sum, CAST(0 AS NUMERIC)) ELSE raw_amount END
                                AS counterparty_amount,
    FALSE                       AS blocked_no_recipient
  FROM alloc
),
-- FIX 5: capital to sweep but nowhere legal to put it. Without this the view returns zero rows, which
-- the executor cannot distinguish from the healthy steady state.
blocked AS (
  SELECT
    'SWEEP'                     AS action,
    s.strategy_code             AS strategy,
    s.sweepable_amount          AS amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_amount,
    TRUE                        AS blocked_no_recipient
  FROM sweeping s
  WHERE NOT EXISTS (SELECT 1 FROM weights)
)
-- Alias is `mv` (movement), NOT `rows` -- ROWS is a reserved keyword in BigQuery and aliasing a
-- subquery to it fails with "Unexpected keyword ROWS" (hit live while applying this file).
SELECT mv.*, ctrl.control_enabled
FROM (SELECT * FROM allocated UNION ALL SELECT * FROM blocked) AS mv
CROSS JOIN ctrl
ORDER BY strategy, counterparty_strategy

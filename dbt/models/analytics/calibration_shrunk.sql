-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql:analytics.calibration_shrunk — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH canonical_tiers AS (
  -- The ordinal vocabulary of Experiment_Parameters.md / conviction_features' CASE, plus the
  -- '(unscored)' bucket calibration_summary and find_precedents both already key on (NULL conviction
  -- has no ordinal, so ord is NULL and it sorts first, exactly as before).
  SELECT * FROM UNNEST([
    STRUCT('(unscored)'  AS conviction, CAST(NULL AS INT64) AS ord),
    STRUCT('LOW'         AS conviction, 1                   AS ord),
    STRUCT('MEDIUM-LOW'  AS conviction, 2                   AS ord),
    STRUCT('MEDIUM'      AS conviction, 3                   AS ord),
    STRUCT('MEDIUM-HIGH' AS conviction, 4                   AS ord),
    STRUCT('HIGH'        AS conviction, 5                   AS ord),
    STRUCT('HIGHEST'     AS conviction, 6                   AS ord)
  ])
),
observed AS (
  SELECT COALESCE(conviction, '(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
    COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins
    -- was_profitable is realized_pnl > 0 (analytics.thesis_outcomes <- analytics.position_campaigns
    -- <- state.trade_fills_curated.realized_pnl), which is the BROKER's net-of-commission realized
    -- P&L per fill -- already the NET label the self-improvement audit's S-4 fix asked calibration to
    -- consume; no separate net conversion needed here.
  FROM {{ ref('conviction_features') }}
  GROUP BY conviction
),
base AS (
  SELECT
    COALESCE(ct.conviction, ob.conviction) AS conviction,
    COALESCE(ob.ord, ct.ord) AS ord,
    COALESCE(ob.go_theses, 0) AS go_theses,
    COALESCE(ob.closed, 0) AS closed,
    COALESCE(ob.wins, 0) AS wins
  FROM canonical_tiers ct
  FULL OUTER JOIN observed ob ON ob.conviction = ct.conviction
),
prior AS (SELECT 2.0 AS prior_a, 2.0 AS prior_b),
wilson AS (
  SELECT b.*, p.prior_a, p.prior_b,
    SAFE_DIVIDE(b.wins, b.closed) AS p_hat,
    -- Wilson score interval (z=1.96), the standard honest-at-low-N interval -- distinct from the
    -- shrunk point estimate (shrinkage and interval width are two separate small-sample corrections).
    --
    -- 2026-07-04 audit finding (HIGH): every division by b.closed below is SAFE_DIVIDE, not just the
    -- outermost one. BigQuery evaluates a SAFE_DIVIDE call's ARGUMENTS before the call itself guards
    -- anything, so a raw `/closed` nested inside an outer SAFE_DIVIDE still hard-errored the whole
    -- query when closed=0 -- and closed=0 is now the NORMAL case for LOW/HIGHEST (which this rebuild
    -- deliberately materializes), not just a transient empty-tier edge case, so this matters more here
    -- than it did in bigquery/25.
    SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) + SAFE_DIVIDE(1.96*1.96, 2*b.closed),
                1 + SAFE_DIVIDE(1.96*1.96, b.closed)) AS wilson_center,
    SAFE_DIVIDE(
      1.96 * SQRT(SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) * (1 - SAFE_DIVIDE(b.wins, b.closed)), b.closed)
                  + SAFE_DIVIDE(1.96*1.96, 4*b.closed*b.closed)),
      1 + SAFE_DIVIDE(1.96*1.96, b.closed)
    ) AS wilson_margin
  FROM base b, prior p
)
SELECT
  conviction, ord, go_theses, closed, wins,
  ROUND(p_hat, 3) AS win_rate,   -- raw MLE -- DO NOT read this alone; see wilson_low / trustworthy_edge
  ROUND(SAFE_DIVIDE(wins + prior_a, closed + prior_a + prior_b), 3) AS win_rate_shrunk,
  -- closed=0 has no Wilson interval to compute (n=0); represent it as maximal uncertainty [0,1]
  -- rather than NULL, which would read as "couldn't compute" instead of "known to be uninformative".
  ROUND(GREATEST(0.0, COALESCE(wilson_center - wilson_margin, 0.0)), 3) AS wilson_low,
  ROUND(LEAST(1.0, COALESCE(wilson_center + wilson_margin, 1.0)), 3) AS wilson_high,
  -- trustworthy_edge: the ONLY gate that may change behavior off this view. >=15 closed is still a
  -- directional-signal bar, not the foundation doc's stated >=30/200 for statistical proof -- deliberately
  -- conservative pending real volume. Below it, consumers read win_rate_shrunk as a lightly-informative
  -- prior-anchored estimate, never as a directive.
  (closed >= 15 AND COALESCE(wilson_center - wilson_margin, 0.0) > 0.55) AS trustworthy_edge
FROM wilson
ORDER BY ord

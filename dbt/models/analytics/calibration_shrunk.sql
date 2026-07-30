-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql section (D):
-- analytics.calibration_shrunk — canonical source is that file until owner cutover (was
-- bigquery/25_calibration_shrinkage.sql). Self-improvement audit S-2/B-2 (2026-07-03):
-- Beta-Binomial shrinkage (fixed Beta(2,2) prior, NOT the pooled sample rate — see the canonical
-- file's header for why) + Wilson 95% interval + a trustworthy_edge hard gate. Supersedes reading
-- calibration_summary.win_rate alone; deprecates the gated BQML conviction_model entirely.
--
-- REBUILT 2026-07-30 (bigquery/116 section (D)): `base` now enumerates ALL SEVEN canonical
-- conviction tiers instead of only those observed among GO-family theses. WHY: a tier with no closed
-- GO trade was previously ABSENT from this view, so find_precedents' LEFT JOIN returned four NULLs
-- for it -- reading as "couldn't compute" on precisely the HIGHEST-conviction precedents the
-- mandatory-interval guardrail (bigquery/29's header) exists to temper. The view already knows how to
-- say "known to be uninformative" for closed=0 (the COALESCE to [0,1] below); it just never got the
-- row. FULL OUTER JOIN, deliberately, not a LEFT JOIN from the tier list: a LEFT JOIN would guarantee
-- the seven canonical tiers but SILENTLY DROP any non-canonical conviction string a future drift
-- introduces -- the exact bug class bigquery/116 exists to fix. FULL OUTER guarantees both
-- directions: every canonical tier always appears, and an unexpected value stays visible instead of
-- vanishing.
--
-- DBT-INTERNAL DIFFERENCE (2026-07-04 audit finding, PRESERVED by this rebuild, not reversed): the
-- `observed` CTE below reads {{ ref('calibration_summary') }} instead of recomputing the identical
-- per-conviction-tier aggregation directly off conviction_features -- calibration_summary already
-- exposes conviction/ord/go_theses/closed/wins from the same {{ ref('conviction_features') }} source,
-- so recomputing it here would just be duplicated logic with its own chance to drift. This still lines
-- up correctly against the new canonical_tiers FULL OUTER JOIN because calibration_summary's own
-- COALESCE(conviction, '(unscored)') already keys the unscored bucket under the exact same string
-- canonical_tiers uses below -- verified column-for-column: calibration_summary emits conviction, ord,
-- go_theses, closed, wins (plus win_rate/avg_realized_pnl, unused here), which is exactly the shape
-- `observed` needs. (The live bigquery/116 view instead builds `observed` straight off
-- analytics.conviction_features, since it has no calibration_summary-equivalent object to dedupe
-- against; the dbt port keeps its own pre-existing ref(calibration_summary) shortcut. Either
-- construction is row-identical once conviction_features' own GO-family filter change — section (C) —
-- has propagated through: calibration_summary is not being redefined by this rebuild, it inherits the
-- fix automatically via ref().)

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
  -- ref() calibration_summary instead of recomputing the identical per-conviction-tier aggregation
  -- (2026-07-04 audit finding, dbt-internal only) -- see file header for why this still lines up with
  -- canonical_tiers below.
  SELECT conviction, ord, go_theses, closed, wins
  FROM {{ ref('calibration_summary') }}
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
    -- 2026-07-04 audit finding (HIGH, mirrored live in bigquery/25_calibration_shrinkage.sql, now
    -- bigquery/116 section (D)): every division by b.closed below is SAFE_DIVIDE, not just the
    -- outermost one. BigQuery evaluates a SAFE_DIVIDE call's ARGUMENTS before the call itself guards
    -- anything, so a raw `/closed` nested inside an outer SAFE_DIVIDE still hard-errors the whole
    -- query when closed=0 -- and closed=0 is now the NORMAL case for LOW/HIGHEST (which this rebuild
    -- deliberately materializes), not just a transient empty-tier edge case, so this matters more here
    -- than it used to.
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
  -- directional-signal bar, not the foundation doc's stated >=30/200 for statistical proof --
  -- deliberately conservative pending real volume. Below it, consumers read win_rate_shrunk as a
  -- lightly-informative prior-anchored estimate, never as a directive.
  (closed >= 15 AND COALESCE(wilson_center - wilson_margin, 0.0) > 0.55) AS trustworthy_edge
FROM wilson
ORDER BY ord

-- Parallel-run dbt port of bigquery/46_weekly_benchmarks.sql:analytics.deployed_book_vs_benchmarks — canonical source is that file until owner cutover.
-- One row: the weekly email's new headline block. Same-days book vs SGOV vs VOO, percent AND dollar
-- ("same amount, same time") legs. SGOV forward-fills a missing mark (cash-like accrual); VOO
-- COALESCEs a missing mark to 0 HERE (correct: the aggregate percent legs are invariant to how a
-- gap's return mass is distributed). NB: analytics.voo_cumulative no longer does this in its OUTPUT —
-- since the 2026-07-17 audit it NULLs a missing mark so the chart shows a gap and the staleness note
-- can fire; only this aggregate view still COALESCEs-to-0 internally. n_voo_mark_days / voo_last_mark_date are
-- data-presence signals the email gates its VOO rendering on — every VOO-derived column is NULL when
-- zero VOO marks exist in the window, so a skipped backfill renders "Not enough data", never a
-- confident "VOO +0.00%".
--
-- VOO GAP-SPAN CAPITAL AVERAGING (adversarial self-audit, 2026-07-13) — see the live file's header
-- for the full rationale: r_voo on a resume day after an ingest gap is a multi-day catch-up return,
-- so the DOLLAR legs (percent legs are unaffected — geometric compounding is order-invariant) price
-- that return against the AVERAGE capital across the whole gap-span (voo_span_end / voo_span_avg_capital
-- below), not just the resume day's own snapshot. A mathematically exact no-op when there is no gap.

WITH agg AS (
  SELECT as_of_date,
         SAFE_DIVIDE(SUM(deployed_capital * r_deployed), SUM(deployed_capital)) AS r_agg,
         SUM(deployed_capital) AS capital,
         SUM(deployed_capital * r_deployed) AS pnl_dollars
  FROM {{ ref('strategy_daily_returns') }}
  GROUP BY as_of_date
),
j AS (
  SELECT a.as_of_date, a.r_agg, a.capital, a.pnl_dollars,
    GREATEST({{ sgov_forward_fill('sg.r_sgov', 'a.as_of_date') }}, -0.9999) AS r_sgov,
    GREATEST(COALESCE(v.r_voo, 0), -0.9999) AS r_voo,
    v.r_voo IS NOT NULL AS has_voo,
    -- Nearest as_of_date >= this row with a real VOO mark — see the live file's header.
    MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER (
      ORDER BY a.as_of_date ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS voo_span_end
  FROM agg a
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
  LEFT JOIN {{ ref('voo_daily_return') }}  v  USING (as_of_date)
),
voo_span AS (
  SELECT *, AVG(capital) OVER (PARTITION BY voo_span_end) AS voo_span_avg_capital
  FROM j
)
SELECT
  MIN(as_of_date)                       AS first_deployed_date,
  MAX(as_of_date)                       AS as_of_date,
  COUNT(*)                              AS n_deployed_days,
  COUNTIF(has_voo)                      AS n_voo_mark_days,
  MAX(CASE WHEN has_voo THEN as_of_date END) AS voo_last_mark_date,
  EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) - 1 AS book_return,
  EXP(SUM(LN(1 + r_sgov))) - 1                   AS sgov_return,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE EXP(SUM(LN(1 + r_voo))) - 1 END      AS voo_return,
  EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) / EXP(SUM(LN(1 + r_sgov))) - 1
                                                 AS excess_vs_sgov_pct,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) / EXP(SUM(LN(1 + r_voo))) - 1
       END                                       AS excess_vs_voo_pct,
  SUM(pnl_dollars)                               AS deployed_pnl_dollars,
  SUM(capital * r_sgov)                          AS sgov_counterfactual_dollars,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE SUM(voo_span_avg_capital * r_voo) END AS voo_counterfactual_dollars,
  SUM(pnl_dollars) - SUM(capital * r_sgov)       AS edge_vs_sgov_dollars,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE SUM(pnl_dollars) - SUM(voo_span_avg_capital * r_voo) END AS edge_vs_voo_dollars
FROM voo_span

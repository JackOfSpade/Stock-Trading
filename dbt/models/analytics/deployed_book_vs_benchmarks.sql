-- Parallel-run dbt port of bigquery/46_weekly_benchmarks.sql:analytics.deployed_book_vs_benchmarks — canonical source is that file until owner cutover.
-- One row: the weekly email's new headline block. Same-days book vs SGOV vs VOO, percent AND dollar
-- ("same amount, same time") legs. SGOV forward-fills a missing mark (cash-like accrual); VOO
-- COALESCEs a missing mark to 0 (see voo_cumulative.sql). n_voo_mark_days / voo_last_mark_date are
-- data-presence signals the email gates its VOO rendering on — every VOO-derived column is NULL when
-- zero VOO marks exist in the window, so a skipped backfill renders "Not enough data", never a
-- confident "VOO +0.00%".

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
    {{ sgov_forward_fill('sg.r_sgov', 'a.as_of_date') }} AS r_sgov,
    GREATEST(COALESCE(v.r_voo, 0), -0.9999) AS r_voo,
    v.r_voo IS NOT NULL AS has_voo
  FROM agg a
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
  LEFT JOIN {{ ref('voo_daily_return') }}  v  USING (as_of_date)
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
       ELSE SUM(capital * r_voo) END             AS voo_counterfactual_dollars,
  SUM(pnl_dollars) - SUM(capital * r_sgov)       AS edge_vs_sgov_dollars,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE SUM(pnl_dollars) - SUM(capital * r_voo) END AS edge_vs_voo_dollars
FROM j

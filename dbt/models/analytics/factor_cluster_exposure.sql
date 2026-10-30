-- Parallel-run dbt port of bigquery/272_factor_cluster_exposure.sql:analytics.factor_cluster_exposure — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH membership AS (
  SELECT m.cluster, m.ticker
  FROM UNNEST(ARRAY<STRUCT<cluster STRING, ticker STRING>>[
    -- Hyperscalers.
    ('AI_CAPEX', 'AMZN'), ('AI_CAPEX', 'GOOGL'), ('AI_CAPEX', 'GOOG'),
    ('AI_CAPEX', 'MSFT'), ('AI_CAPEX', 'META'), ('AI_CAPEX', 'ORCL'),
    -- AI semis + foundry.
    ('AI_CAPEX', 'NVDA'), ('AI_CAPEX', 'AVGO'), ('AI_CAPEX', 'AMD'), ('AI_CAPEX', 'TSM'),
    -- AI power.
    ('AI_CAPEX', 'GEV')
  ]) AS m
),
by_name AS (
  SELECT
    p.strategy,
    p.ticker,
    SUM(p.shares) AS shares,
    SUM(p.cost_basis) AS cost_basis
  FROM {{ ref('current_positions') }} AS p
  WHERE p.strategy IS NOT NULL
  GROUP BY p.strategy, p.ticker
),
latest_marks AS (
  SELECT dm.ticker, dm.mark_date, dm.close
  FROM {{ ref('daily_marks_curated') }} AS dm
  QUALIFY ROW_NUMBER() OVER (PARTITION BY dm.ticker ORDER BY dm.mark_date DESC) = 1
),
marked_positions AS (
  SELECT
    p.strategy,
    p.ticker,
    p.cost_basis,
    p.shares * lm.close AS market_value,
    lm.mark_date,
    lm.close
  FROM by_name AS p
  LEFT JOIN latest_marks AS lm ON lm.ticker = p.ticker
),
book_totals AS (
  SELECT
    IF(GROUPING(p.strategy) = 1, 'ALL', p.strategy) AS strategy,
    SUM(p.market_value) AS book_market_value
  FROM marked_positions AS p
  GROUP BY GROUPING SETS ((p.strategy), ())
),
cluster_totals AS (
  SELECT
    m.cluster,
    IF(GROUPING(p.strategy) = 1, 'ALL', p.strategy) AS strategy,
    COUNT(DISTINCT p.ticker) AS n_cluster_names,
    STRING_AGG(DISTINCT p.ticker, ', ' ORDER BY p.ticker) AS cluster_tickers,
    SUM(p.cost_basis) AS cluster_cost_basis,
    SUM(p.market_value) AS cluster_market_value,
    MIN(p.mark_date) AS latest_mark_date,
    COUNT(DISTINCT IF(p.close IS NULL, p.ticker, NULL)) AS names_missing_mark
  FROM marked_positions AS p
  JOIN membership AS m ON m.ticker = p.ticker
  GROUP BY GROUPING SETS ((m.cluster, p.strategy), (m.cluster))
),
clusters AS (
  SELECT DISTINCT m.cluster FROM membership AS m
)
SELECT
  k.cluster,
  b.strategy,
  CURRENT_DATE('America/Denver') AS as_of_date,
  COALESCE(c.n_cluster_names, 0) AS n_cluster_names,
  COALESCE(c.cluster_tickers, '') AS cluster_tickers,
  ROUND(IF(c.n_cluster_names IS NULL, 0, c.cluster_cost_basis), 2) AS cluster_cost_basis,
  ROUND(IF(c.n_cluster_names IS NULL, 0, c.cluster_market_value), 2) AS cluster_market_value,
  ROUND(b.book_market_value, 2) AS book_market_value,
  IF(c.n_cluster_names IS NULL, 0,
     ROUND(100 * SAFE_DIVIDE(c.cluster_market_value, b.book_market_value), 2)) AS cluster_share_of_book_pct,
  ROUND(a.nav, 2) AS account_nav,
  IF(c.n_cluster_names IS NULL, 0,
     ROUND(100 * SAFE_DIVIDE(c.cluster_market_value, a.nav), 2)) AS cluster_share_of_account_pct,
  c.latest_mark_date,
  COALESCE(c.names_missing_mark, 0) AS names_missing_mark
FROM clusters AS k
CROSS JOIN book_totals AS b
LEFT JOIN cluster_totals AS c ON c.cluster = k.cluster AND c.strategy = b.strategy
LEFT JOIN {{ ref('account_latest') }} AS a ON TRUE

-- Cross-sector AI-capex cluster exposure. Project: stock-trading-498512. Date: 2026-10-30.
--
-- WHY THIS EXISTS. Monthly D deep-dive finding F-9 recorded AMZN, GOOGL, TSM and GEV at
-- 66% of Strategy D's book across different GICS sectors: sector reporting missed the shared
-- AI-capex driver. On 2026-10-29 GOOGL fell 12.6% on its Q3 print; the cluster leader moved
-- without a queryable measure of the cohort. This view measures direct holdings, not correlation.
-- Informational, record-only reporting: no threshold, cap, gate, block or alert attaches to it.
--
-- MEMBERSHIP IS A VERSIONED LITERAL. AI_CAPEX membership below is fixed by this numbered file;
-- changing membership requires a new numbered SQL file, not an edit to this historical definition.
-- The VOO/SGOV park is NOT looked through: index look-through weights are not in the warehouse.
-- Park exposure to cluster names is excluded from the numerator; every reader must state this.
-- Account NAV still includes the park. Any separately estimated look-through is approximate.
--
-- POINT-IN-TIME, NOT A SERIES. Sum position tranches by strategy/ticker, then value all names at
-- each ticker's latest curated close. NULL-strategy rows are excluded. ALL combines strategies,
-- counting a ticker only once even when held in several strategies. Empty cluster holdings have
-- zero exposure; unmarked holdings are not assigned a price (SUM may be partial or NULL).
-- names_missing_mark counts distinct held cluster tickers without a usable close; latest_mark_date
-- is the oldest of the held cluster tickers' latest mark dates, not a common valuation date.
--
-- Defines ONE read-only view and nothing else. Requires state.current_positions,
-- state.daily_marks_curated and state.account_latest. Re-apply safe (CREATE OR REPLACE).

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.factor_cluster_exposure` AS
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
  FROM `stock-trading-498512.state.current_positions` AS p
  WHERE p.strategy IS NOT NULL
  GROUP BY p.strategy, p.ticker
),
latest_marks AS (
  SELECT dm.ticker, dm.mark_date, dm.close
  FROM `stock-trading-498512.state.daily_marks_curated` AS dm
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
LEFT JOIN `stock-trading-498512.state.account_latest` AS a ON TRUE;

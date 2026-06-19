-- Parallel-run dbt port of bigquery/09_market_calendar.sql:state.trading_day_today — canonical source is that file until owner cutover.
-- "Today" in the experiment's operating timezone (America/Denver) — the single source
-- every routine/view should read instead of bespoke TZ math.
--   last_trading_day = most recent trading day <= today (today itself if it is one).
--   next_trading_day = soonest trading day strictly after today.
-- Ported because state.freshness refs it.

WITH today AS (SELECT CURRENT_DATE('America/Denver') AS d)
SELECT
  t.d AS today,
  (SELECT mc.is_trading_day FROM {{ ref('market_calendar') }} mc WHERE mc.cal_date = t.d) AS is_trading_day,
  (SELECT MAX(mc.cal_date) FROM {{ ref('market_calendar') }} mc
     WHERE mc.cal_date <= t.d AND mc.is_trading_day) AS last_trading_day,
  (SELECT MIN(mc.cal_date) FROM {{ ref('market_calendar') }} mc
     WHERE mc.cal_date > t.d AND mc.is_trading_day) AS next_trading_day
FROM today t

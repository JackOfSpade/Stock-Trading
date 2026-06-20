-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.weekly_activity — canonical source is that file until owner cutover.
-- Last-7-day activity counts for the weekly self-email. Relative window (America/Denver), so a view.
SELECT
  (SELECT COUNT(*) FROM {{ ref('trade_fills_curated') }}
     WHERE DATE(fill_ts) >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM {{ source('events', 'decision_log') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM {{ source('events', 'decision_log') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM {{ ref('open_queue') }}
     WHERE queue = 'ORDER_STAGED') AS pending_orders

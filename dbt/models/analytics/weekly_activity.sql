-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.weekly_activity — canonical source is that file until owner cutover.
-- Last-7-day activity counts. Relative window (America/Denver), so a view. Retained for
-- history — no longer read by the weekly self-email (2026-07 redesign).
SELECT
  -- DATE(fill_ts, 'America/Denver') — see bigquery/14_weekly_report.sql for why the bare (UTC-default)
  -- form mis-ages a late-Denver-evening fill by one day against this Denver-anchored window.
  (SELECT COUNT(*) FROM {{ ref('trade_fills_curated') }}
     WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM {{ source('events', 'decision_log') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM {{ source('events', 'decision_log') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM {{ ref('open_queue') }}
     WHERE queue = 'ORDER_STAGED') AS pending_orders

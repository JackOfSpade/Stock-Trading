-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.weekly_activity — canonical source
-- is bigquery/144_decision_log_correction_consumers.sql section (8) (which SUPERSEDES 14's definition
-- of the go_7d/nogo_7d counters, see below) until owner cutover.
-- Last-7-day activity counts. Relative window (America/Denver), so a view. Retained for
-- history — no longer read by the weekly self-email (2026-07 redesign).
-- BUG FIX (2026-08-31 code-quality pass, dbt#0): go_7d/nogo_7d read state.decision_log_current, not
-- raw events.decision_log — bigquery/144 (2026-08-06) moved the canonical body onto the anti-joined
-- view so a GO/NO-GO corrected inside this trailing-7-day window is counted once, not twice; this dbt
-- port had been left reading the raw table for 25 days (scripts/check_superseded_by_discipline.py only
-- scans bigquery/, so it never saw the gap; dbt_parity.py would only have caught it as row-level DRIFT
-- the next time a correction happened to fall inside this window).
SELECT
  -- DATE(fill_ts, 'America/Denver') — see bigquery/14_weekly_report.sql for why the bare (UTC-default)
  -- form mis-ages a late-Denver-evening fill by one day against this Denver-anchored window.
  (SELECT COUNT(*) FROM {{ ref('trade_fills_curated') }}
     WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM {{ source('state_external', 'decision_log_current') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM {{ source('state_external', 'decision_log_current') }}
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM {{ ref('open_queue') }}
     WHERE queue = 'ORDER_STAGED') AS pending_orders

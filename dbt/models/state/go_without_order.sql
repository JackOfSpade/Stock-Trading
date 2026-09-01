-- Parallel-run dbt port of bigquery/144_decision_log_correction_consumers.sql:state.go_without_order — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH d3_last_completed AS (
  -- D3's own last completed ops.run_log run -- the anchor for how far back this view's evidence window
  -- needs to reach.
  SELECT MAX(log_ts) AS d3_last_completed_ts
  FROM {{ source('ops', 'run_log') }}
  WHERE routine = 'D3' AND status = 'completed'
),
go_decisions AS (
  SELECT entry_id, entry_date, strategy, ticker, entry_type, title
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE decision = 'GO'
    AND entry_date >= DATE_SUB(
      CURRENT_DATE('America/Denver'),
      -- FLOORED at the original fixed 2-day (~36h) lookback (GREATEST semantics): never narrower than
      -- bigquery/18's original definition, but widens to D3's own last-completion gap when that is
      -- bigger -- see the file-level comment above this CREATE statement.
      INTERVAL (
        SELECT GREATEST(
          2,
          COALESCE(
            DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(d3_last_completed_ts, 'America/Denver'), DAY),
            2
          )
        )
        FROM d3_last_completed
      ) DAY
    )
)
SELECT
  g.entry_id, g.entry_date, g.strategy, g.ticker, g.entry_type, g.title,
  CURRENT_TIMESTAMP() AS checked_at
FROM go_decisions g
-- no staged order references this decision (by ref, else by ticker+strategy on/after the decision day).
-- DATE(..., 'America/Denver') — NOT the bare (UTC-default) form — because g.entry_date is the
-- Denver OPERATING day decision_log stamps; a bare UTC date is always >= the Denver date, so an
-- order/fill actually staged the PRIOR Denver evening (>=~17:00 MT = already the next UTC day) could
-- wrongly satisfy this match and suppress a genuine go-without-order candidate (false negative only;
-- 2026-07 report-system fix).
WHERE NOT EXISTS (
  SELECT 1 FROM {{ source('events', 'queue_events') }} q
  WHERE q.queue = 'ORDER_STAGED'
    AND (JSON_VALUE(q.payload, '$.source_decision_ref') = g.entry_id
         OR (q.ticker = g.ticker AND q.strategy = g.strategy AND DATE(q.event_ts, 'America/Denver') >= g.entry_date))
)
-- and no fill recorded for that strategy/ticker on/after the decision day
AND NOT EXISTS (
  SELECT 1 FROM {{ source('events', 'trade_fills') }} f
  WHERE f.ticker = g.ticker AND f.strategy = g.strategy
    AND DATE(f.fill_ts, 'America/Denver') >= g.entry_date
)

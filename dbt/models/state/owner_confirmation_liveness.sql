-- Parallel-run dbt port of bigquery/76_owner_confirmation_liveness.sql:state.owner_confirmation_liveness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM {{ ref('open_orders') }}
  WHERE status = 'pending'
),
last_fill AS (
  SELECT MAX(fill_ts) AS last_fill_ts
  FROM {{ source('events', 'trade_fills') }}
),
ltd AS (
  SELECT last_trading_day FROM {{ ref('trading_day_today') }}
),
stale AS (
  SELECT
    CASE
      WHEN lf.last_fill_ts IS NULL THEN 999  -- no fill has EVER been recorded — fail-safe maximally stale
      ELSE (
        SELECT COUNT(*)
        FROM {{ ref('market_calendar') }} mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(lf.last_fill_ts, 'America/Denver')
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_since_last_fill
  FROM last_fill lf, ltd
)
SELECT
  p.n_pending_instructions,
  lf.last_fill_ts,
  s.trading_days_since_last_fill,
  ltd.last_trading_day AS as_of_trading_day,
  -- entries_halted: >=1 pending staged instruction (something IS waiting on a tap) AND >=3 trading
  -- days have elapsed with zero fills reconciled. 3 trading days is a POLICY INVARIANT (not fitted) —
  -- long enough that a single busy/traveling day never false-trips, short enough that a real multi-day
  -- absence is caught well before a week-plus pile-up. Review alongside book growth like the other
  -- policy invariants in bigquery/23_trading_control.sql.
  (p.n_pending_instructions > 0 AND s.trading_days_since_last_fill >= 3) AS entries_halted
FROM pending p, last_fill lf, stale s, ltd

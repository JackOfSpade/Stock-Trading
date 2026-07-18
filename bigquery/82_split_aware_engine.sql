-- Split-aware TWR engine + mark-discontinuity tripwire (2026-07-17 whole-system deep audit,
-- finding C2 [data-integrity, CRITICAL]). Project: stock-trading-498512. Apply AFTER
-- 03_twr_engine.sql, 40_options_marks.sql, 53_curated_view_tiebreak_fix.sql. SUPERSEDES
-- analytics.strategy_daily_returns from bigquery/40 (the option-aware rebuild — this file preserves
-- that file's option leg byte-for-byte and adds the split factor to the EQUITY leg only; options do
-- not carry an events.daily_marks split_ratio). Per the supersede-only discipline, any later change
-- to this view lands as a new numbered file.
--
-- WHY. events.daily_marks carries split_ratio but NOTHING consumes it (grep: only 03's DDL/comments
-- + the dbt source decl). The engine computes mv = shares * close with shares from fill-derived
-- position_lifecycle (pre-split) against an append-only marks table. So a 2:1 split on a held name
-- halves the ingested close while stored shares stay pre-split -> a phantom ~-50% daily return
-- (-75% for 4:1) -> perf.strategy_daily.current_drawdown <= -0.50 -> drawdown_kill fires -> D2
-- converts it to IMMEDIATE termination (ITEM 16: the kill sweep is judgment-free, so no session can
-- spare the healthy strategy). Every alarm layer is blind: IBKR NLV is split-invariant, and
-- state.position_reconciliation compares two fill-derived views (structurally blind to a broker-side
-- share change with no fill). The held book is exactly the split-prone mega-cap class (AMZN/GOOGL
-- both split 20:1 in 2022). Verified inert on apply day 2026-07-17: every events.daily_marks row has
-- split_ratio NULL or 1.0, so eff_split_since_entry == 1 everywhere and r_deployed is unchanged.
--
-- FIX 1 (this file): make the engine split-aware using the existing column. For each held position,
-- scale the fill-derived share count by the cumulative split factor accrued SINCE ENTRY:
--   eff_split_since_entry(t) = product of split_ratio over marks with entry_date < mark_date <= t
-- On a 2:1 split day the factor doubles exactly as the ingested close halves, so mv (and the
-- dividend leg) are continuous across the split — no phantom return. The entry-day baseline
-- (shares*entry_price) is the cost basis and is left pre-split (correct). Read-side only, no data
-- migration; keeps the exact output columns (as_of_date, strategy, r_deployed, deployed_capital,
-- n_positions) so downstream perf.strategy_daily / dbt parity are unaffected.
--
-- FIX 2 (this file): state.mark_discontinuity_watch — a D2a ingest tripwire that flags any held or
-- benchmark ticker whose latest close jumps >25% day-over-day WITHOUT a recorded split (split_ratio=1)
-- and not explained by a same-day dividend. That is exactly the residual dangerous case FIX 1 cannot
-- repair on its own: a bad print, or a REAL split the connector failed to record in split_ratio (so
-- the factor stays 1 and the phantom -50% survives). D2a raises a CRITICAL 'mark_discontinuity' on a
-- non-empty latest-day flag, which (being a non-excluded critical) forces state.system_health.all_green
-- FALSE and blocks D2's rigid termination conversion until adjudicated — the twr_bad_mark pattern at a
-- realistic 25% threshold (the existing LN-domain clamp only fires at -99.99%, 200x too coarse). A
-- correctly-recorded split (split_ratio != 1) is NOT flagged — FIX 1 already handles it cleanly.
-- The D2a routine wiring (raise-on-flag + the events.position_events 'SPLIT_ADJUST' share-sync row on
-- split_ratio!=1) lives in Claude_Task_Plan.md's D2a section.

-- ===== analytics.strategy_daily_returns — SPLIT-AWARE (SUPERSEDES bigquery/40) =====
-- Structure mirrors bigquery/40 (equity_held UNION ALL option_held; multiplier threaded into the
-- entry-day baseline). The ONLY change vs 40 is the equity leg: shares are scaled by a per-position
-- running split factor (eff_split_since_entry) so a post-entry split on a held stock keeps mv and the
-- dividend leg continuous. The option leg is byte-identical to 40 (options have no daily_marks split_ratio).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_daily_returns` AS
WITH equity_marked AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, l.exit_price, l.exit_date,
         CAST(1 AS INT64) AS multiplier, m.close, COALESCE(m.dividend, 0) AS dividend,
         COALESCE(NULLIF(m.split_ratio, 0), 1) AS day_split
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.daily_marks_curated` m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
equity_runprod AS (
  -- running product of daily split_ratio within the hold window (BigQuery forbids nesting an analytic
  -- inside another, so running-product and FIRST_VALUE normalisation are split across two CTEs).
  SELECT *, EXP(SUM(LN(day_split)) OVER (PARTITION BY position_key ORDER BY mark_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS rp
  FROM equity_marked
),
equity_held AS (
  -- eff_split_since_entry = running split product normalised to 1.0 on the first held day, so a split
  -- strictly AFTER entry scales shares from that day forward (a same-day-as-entry split is left to the
  -- broker fill count). Output columns match option_held for the UNION ALL.
  SELECT mark_date, strategy, position_key, shares, entry_price, multiplier,
    shares * eff * IF(mark_date = exit_date, exit_price, close) AS mv,
    shares * eff * dividend AS div_cash
  FROM (
    SELECT *, SAFE_DIVIDE(rp, FIRST_VALUE(rp) OVER (PARTITION BY position_key ORDER BY mark_date)) AS eff
    FROM equity_runprod
  )
),
option_held AS (
  SELECT om.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         om.multiplier,
         l.shares * om.multiplier * IF(om.mark_date = l.exit_date, l.exit_price, om.premium_close) AS mv,
         CAST(0 AS NUMERIC) AS div_cash   -- options carry no dividend
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.option_marks_curated` om
    ON om.occ_symbol = l.ticker
   AND om.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR om.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
held AS (
  SELECT * FROM equity_held
  UNION ALL
  SELECT * FROM option_held
),
lagged AS (
  -- entry-day baseline threads the options multiplier (1 for equities), matching mv's own scaling —
  -- see bigquery/40's fix note. Split factor is deliberately NOT applied to the baseline (cost basis).
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares * multiplier * entry_price) AS prev_mv
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       SUM(prev_mv) AS deployed_capital,
       COUNT(*) AS n_positions
FROM lagged
GROUP BY mark_date, strategy;

-- ===== state.mark_discontinuity_watch — bad-print / missed-split tripwire (NEW) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.mark_discontinuity_watch` AS
WITH watched AS (
  SELECT DISTINCT ticker FROM `stock-trading-498512.state.current_positions` WHERE ticker IS NOT NULL
  UNION DISTINCT SELECT 'SGOV' UNION DISTINCT SELECT 'VOO' UNION DISTINCT SELECT 'SPY'
),
seq AS (
  SELECT ticker, mark_date, close,
         COALESCE(dividend, 0) AS dividend,
         COALESCE(NULLIF(split_ratio, 0), 1) AS split_ratio,
         LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker IN (SELECT ticker FROM watched)
)
SELECT
  ticker, mark_date, close, prev_close, split_ratio, dividend,
  SAFE_DIVIDE(close, prev_close) - 1 AS raw_move,
  (prev_close IS NOT NULL
   AND ABS(SAFE_DIVIDE(close, prev_close) - 1) > 0.25   -- >25% day-over-day jump
   AND split_ratio = 1                                  -- NOT a recorded split (a recorded split is handled by the engine)
   AND ABS(SAFE_DIVIDE(dividend, prev_close)) < 0.25     -- NOT explained by a same-day dividend
  ) AS is_discontinuity
FROM seq;

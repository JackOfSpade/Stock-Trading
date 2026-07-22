-- Options mark-to-market path (ITEM 12, self-improvement audit 2026-07-11; finding C-3). Project:
-- stock-trading-498512. Apply after 03_twr_engine.sql (events.daily_marks, analytics.position_lifecycle,
-- analytics.strategy_daily_returns, perf.kill_flags — this file supersedes strategy_daily_returns'
-- definition) and 01_schema.sql (events.trade_fills, state.trade_fills_curated).
--
-- WHY: analytics.strategy_daily_returns' `held` CTE joins positions to daily marks strictly
-- `ON m.ticker = l.ticker` and values every position `shares * close` — a stock/ETF-shaped valuation
-- with no branch for an option contract's own daily premium. Strategy C is options-only, sized in
-- integer CONTRACT counts (c_options_math.py size_position()), and is roster-ADOPTED with an active
-- router path today, not hypothetical. Two failure modes without this fix: (a) if a filled option's
-- `ticker` holds its OCC symbol, the join finds no matching row and the position never appears in
-- deployed capital / drawdown / kill-trigger inputs for its entire life; (b) if `ticker` holds the
-- underlying's equity symbol, the engine marks it `contracts * underlying_close` — off by roughly the
-- strike price. Either way, the numbers feeding the mechanical kill triggers are silently wrong.
--
-- DESIGN (deliberately surgical — no schema change to events.trade_fills / events.position_events):
-- an option fill's `ticker` field is expected to hold its OCC option symbol (IBKR's own convention for
-- get_account_trades / search_contracts on an option contract — root symbol padded to 6 chars, then
-- YYMMDD expiry, then C/P, then an 8-digit strike*1000). is_occ_option_symbol() recognizes this format
-- via REGEXP_CONTAINS — a read-only pattern match requiring NO new ingest-time metadata anywhere,
-- since equity tickers can never match an OCC symbol's fixed shape. This is both the standard industry
-- symbol convention (not an invented one) and the smallest change that lets the SAME `ticker`-keyed join
-- pattern events.daily_marks already uses branch cleanly between an equity/ETF mark and an option mark.
--
-- ANOMALY GUARD: a held option-format position lacking a same-day mark is EXCLUDED from that
-- strategy-day's contribution to perf.strategy_daily (not silently zero-valued, not left to null the
-- whole chain) and raises a warning alert — a missing/bad option mark must never single-handedly fire a
-- mechanical kill trigger on garbage data. Idempotent (CREATE OR REPLACE / CREATE TABLE IF NOT EXISTS);
-- safe to re-run.

-- ============================================================================
-- events.option_marks — per-contract daily premium marks. Mirrors events.daily_marks' shape/contract.
-- Populated by D2a's mark-ingest step (Claude_Task_Plan.md D2a STEP 1) via IBKR get_option_data (an
-- FMP options-chain quote as fallback), for every OPEN option-format position.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.option_marks` (
  mark_date DATE NOT NULL,
  occ_symbol STRING NOT NULL,          -- the option's OCC symbol (== events.trade_fills.ticker for this leg)
  underlying STRING,                   -- informational only (not used in the join); parsed at ingest time
  strike NUMERIC,                      -- informational only
  expiry DATE,                         -- informational only
  option_right STRING,                 -- 'C' | 'P', informational only
  premium_close NUMERIC,               -- per-share premium (multiply by multiplier for per-contract value)
  multiplier INT64 DEFAULT 100,        -- US equity options: 100 shares/contract (c_options_math.py convention)
  source STRING DEFAULT 'connector',
  ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY mark_date CLUSTER BY occ_symbol
OPTIONS(description='Daily per-contract option premium marks (ITEM 12). Consumers read state.option_marks_curated (latest ingest per occ_symbol/day), exactly mirroring state.daily_marks_curated.');

-- Dedup view — identical convention to state.daily_marks_curated (bigquery/03).
CREATE OR REPLACE VIEW `stock-trading-498512.state.option_marks_curated` AS
SELECT * FROM `stock-trading-498512.events.option_marks`
QUALIFY ROW_NUMBER() OVER (PARTITION BY occ_symbol, mark_date ORDER BY ingest_ts DESC) = 1;

-- ============================================================================
-- analytics.fn_is_occ_option_symbol — OCC option symbol format recognizer. Standard shape: a root symbol
-- (1-6 letters, IBKR right-pads with spaces to 6 but this also accepts the unpadded form), a 6-digit
-- YYMMDD expiry, a single C or P, and an 8-digit strike (strike * 1000, zero-padded). Deliberately a pure
-- function (no table access) so it can be used in a WHERE/CASE branch cheaply.
-- ============================================================================
CREATE OR REPLACE FUNCTION `stock-trading-498512.analytics.fn_is_occ_option_symbol`(ticker STRING) AS (
  ticker IS NOT NULL AND REGEXP_CONTAINS(ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$')
);

-- ============================================================================
-- analytics.strategy_daily_returns — REBUILD (supersedes bigquery/03_twr_engine.sql's definition) with an
-- option-aware valuation branch in the `held` CTE. Equity/ETF legs are byte-identical to before
-- (`shares * close`, joined to state.daily_marks_curated); an OCC-format leg instead joins
-- state.option_marks_curated and values at `contracts * multiplier * premium_close`. A held option-format
-- position with NO same-day option mark is EXCLUDED from that day's contribution (not zero-valued, not
-- silently dropped from the whole chain) — see the anomaly-guard note below.
--
-- SUPERSEDED LIVE by bigquery/82_split_aware_engine.sql — the CURRENT single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_daily_returns` AS
WITH equity_held AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         CAST(1 AS INT64) AS multiplier,
         l.shares * IF(m.mark_date = l.exit_date, l.exit_price, m.close) AS mv,
         l.shares * COALESCE(m.dividend,0) AS div_cash
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.daily_marks_curated` m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
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
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): the entry-day fallback (LAG(mv) IS NULL on the
  -- first held row of a position_key) previously used the bare `shares*entry_price`, which is correct
  -- for equities but omits the options contract multiplier that `mv` itself applies via `om.multiplier`
  -- above -- understating an option position's entry-day baseline by ~100x, which overstates that day's
  -- r_deployed by the same factor and permanently corrupts the compounding deployed_unit_value/peak
  -- chain (perf.strategy_daily), silently defeating drawdown_kill for any strategy that trades options.
  -- `multiplier` is now carried through `held` (1 for equities, om.multiplier for options) precisely so
  -- this fallback can apply it too, matching `mv`'s own scaling.
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares*multiplier*entry_price) AS prev_mv
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       SUM(prev_mv) AS deployed_capital,
       COUNT(*) AS n_positions
FROM lagged
GROUP BY mark_date, strategy;

-- ============================================================================
-- state.option_mark_anomalies — ANOMALY GUARD (ITEM 12). Flags every (strategy, position_key, held_date)
-- where an OCC-format position was open on a trading day but analytics.strategy_daily_returns' option_held
-- branch has NO matching row for it that day (no option_marks_curated entry yet, or the join otherwise
-- missed it) — the exact case that must NOT silently zero-value or null-corrupt the TWR chain. Self-
-- bootstrapping: empty until the first option position + a genuinely missing mark co-occur.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.option_mark_anomalies` AS
WITH option_positions AS (
  SELECT l.strategy, l.position_key, l.ticker, l.entry_date, l.exit_date
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  WHERE l.strategy IS NOT NULL
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
trading_days AS (
  SELECT DISTINCT mark_date FROM `stock-trading-498512.state.daily_marks_curated`
),
expected AS (
  SELECT p.strategy, p.position_key, p.ticker, td.mark_date
  FROM option_positions p
  JOIN trading_days td
    ON td.mark_date >= p.entry_date
   AND (p.exit_date IS NULL OR td.mark_date <= p.exit_date)
)
SELECT e.strategy, e.position_key, e.ticker AS occ_symbol, e.mark_date
FROM expected e
LEFT JOIN `stock-trading-498512.state.option_marks_curated` om
  ON om.occ_symbol = e.ticker AND om.mark_date = e.mark_date
WHERE om.occ_symbol IS NULL;

-- ============================================================================
-- ops.sp_recompute_engine — REBUILD (supersedes bigquery/03_twr_engine.sql's definition) with ONE
-- addition: raise a warning alert when state.option_mark_anomalies is non-empty, BEFORE the recompute
-- (informational — the recompute itself already safely excludes an unmarked option-day via the option_held
-- join above, so this is detection, not a blocking gate). Everything else is byte-for-byte identical to
-- the superseded definition; keep the two files' comments in sync if either changes.
--
-- SUPERSEDED LIVE by bigquery/102_pyramid_aware_lifecycle.sql (2026-07-21 — pyramid-aware lots +
-- campaigns; the closed_trades / gate_n subqueries now COUNT off analytics.position_campaigns instead
-- of analytics.position_lifecycle so a partial-exit pyramid counts as one closed trade, not many).
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE
-- statement live in isolation.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_recompute_engine`()
BEGIN
  DECLARE bad_mark_count INT64;
  DECLARE option_anomaly_count INT64;

  SET option_anomaly_count = (SELECT COUNT(*) FROM `stock-trading-498512.state.option_mark_anomalies`);
  IF option_anomaly_count > 0 THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'ops.sp_recompute_engine', 'option_mark_missing',
      'One or more held option-format positions are missing a same-day option mark -- those strategy-days are excluded from the TWR chain (not zero-valued), not a silent corruption, but the underlying mark gap needs D2a follow-up.',
      TO_JSON_STRING(STRUCT(option_anomaly_count AS anomaly_count, CURRENT_TIMESTAMP() AS detected_ts)));
  END IF;

  SET bad_mark_count = (
    SELECT COUNT(*)
    FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
    LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
    WHERE sdr.r_deployed <= -0.9999 OR sg.r_sgov <= -0.9999
  );
  IF bad_mark_count > 0 THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'ops.sp_recompute_engine', 'twr_bad_mark',
      'A strategy-day had r_deployed or r_sgov <= -99.99% -- clamped to avoid NULL-corrupting the TWR chain; underlying mark likely bad, needs correction.',
      TO_JSON_STRING(STRUCT(bad_mark_count AS bad_mark_count, CURRENT_TIMESTAMP() AS detected_ts)));
  END IF;

  BEGIN TRANSACTION;

  DELETE FROM `stock-trading-498512.perf.strategy_daily` WHERE TRUE;
  INSERT INTO `stock-trading-498512.perf.strategy_daily`
  (as_of_date, strategy, deployed_unit_value, peak_unit_value, current_drawdown, sgov_index, excess_vs_sgov, deployed_days, closed_trades, gate_n, method, note)
  WITH r AS (
    SELECT sdr.as_of_date, sdr.strategy,
      GREATEST(sdr.r_deployed, -0.9999) AS r_deployed,
      GREATEST(COALESCE(
        sg.r_sgov,
        LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
          PARTITION BY sdr.strategy ORDER BY sdr.as_of_date
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        0), -0.9999) AS r_sgov
    FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
    LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
  ),
  chained AS (
    SELECT as_of_date, strategy,
      EXP(SUM(LN(1+r_deployed)) OVER w) AS duv,
      EXP(SUM(LN(1+r_sgov)) OVER w) AS sgovidx,
      ROW_NUMBER() OVER w AS dday
    FROM r WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date)
  ),
  peaked AS (
    SELECT *, GREATEST(1.0, MAX(duv) OVER (PARTITION BY strategy ORDER BY as_of_date)) AS peak
    FROM chained
  )
  SELECT p.as_of_date, p.strategy,
    CAST(p.duv AS NUMERIC), CAST(p.peak AS NUMERIC), CAST(p.duv/p.peak-1 AS NUMERIC),
    CAST(p.sgovidx AS NUMERIC), CAST(p.duv/p.sgovidx-1 AS NUMERIC), p.dday,
    (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_lifecycle` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date),
    GREATEST(0, 30 - (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_lifecycle` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date)),
    'value-weighted-daily-TWR-gross-v3',
    'PROFITABILITY metric: GROSS of commissions (scale artifact at ~$30 positions), total return, SGOV actual total-return benchmark. Cash/NAV accounting tracks commissions exactly + separately.'
  FROM peaked p;

  COMMIT TRANSACTION;
END;

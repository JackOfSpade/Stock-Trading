-- Dust excluded from closed-trade statistics (2026-08-02).
-- Project: stock-trading-498512. Apply AFTER 123_drip_dust_campaign_exclusion.sql (re-applied in the
-- same change -- its is_dust gate is now an audited fill-level classification; see that file's header).
--
-- SUPERSEDES bigquery/102_pyramid_aware_lifecycle.sql's ops.sp_recompute_engine (the closed_trades /
-- gate_n subqueries only -- see the SUPERSEDED marker left in 102 pointing here). This is the current
-- single source of truth for that procedure. Keep 102 for DR-rebuild history; do not re-apply its
-- definition of this object in isolation.
--
-- WHAT THIS FIXES. bigquery/123 makes analytics.position_campaigns.is_dust an immutable audited
-- source-fill classification written by D2a. It remains TRUE after the two live residuals, B:IBM:2
-- (~$0.19) and B:HCA:2 (~$0.039), are sold; a consumer that filters only exit_date IS NOT NULL would
-- otherwise treat either closed phantom as a real trade.
-- Two such consumers do exactly that filter: ops.sp_recompute_engine's closed_trades / gate_n counters
-- (bigquery/102, fixed here) and analytics.calibration_return_shrunk's `camp` CTE (bigquery/103) --
-- see the SCOPE note below for why only the first is actually fixed in this file.
--
-- WHY IT MATTERS, CONCRETELY. Priced against each ticker's current mark: B:IBM:2 cost $0.189987 (0.0007
-- sh @ $271.41) vs. a $223.65 mark (~$0.157) = -17.6% realized return; B:HCA:2 cost $0.038977 (0.0001
-- sh @ $389.77) vs. a $402.59 mark (~$0.0403) = +3.3%. Neither number reflects an actual investment
-- decision -- both are DRIP reinvestment residue landing after the real position already closed (see
-- bigquery/123's header for why a DRIP predicate can't be used instead of the notional gate). Without
-- this fix, the moment either is liquidated it would silently enter ops.sp_recompute_engine's
-- closed_trades / gate_n as ONE MORE closed trade for strategy B, averaged EQUALLY with real $27-50
-- campaigns and counted toward the 30-trade gate -- a phantom trade materially skewing a live
-- performance/gating statistic with zero underlying economic decision behind it.
--
-- THE FIX. Both closed_trades / gate_n subqueries use `AND NOT COALESCE(l.is_dust,FALSE)` alongside
-- `l.exit_date IS NOT NULL`; NULL fails open as non-dust instead of silently dropping a real campaign.
-- Everything else in the
-- procedure -- the option-mark-anomaly / bad-TWR-mark alert checks, the DELETE+INSERT rebuild of
-- perf.strategy_daily, the value-weighted daily-TWR chain, deployed_days -- is byte-for-byte unchanged
-- from bigquery/102.
--
-- SCOPE -- analytics.calibration_return_shrunk (bigquery/103) is DELIBERATELY NOT TOUCHED HERE, unlike
-- what a naive read of "two consumers filter exit_date IS NOT NULL" would suggest. Verified live before
-- writing this file: analytics.calibration_return_shrunk does not exist (INFORMATION_SCHEMA.TABLES
-- returns zero rows for it in the analytics dataset). bigquery/104_strip_pretrade_rails.sql DROPPED it
-- outright on 2026-07-22 (owner directive stripping every liquidity/sizing pre-trade rail down to
-- market-only + malformed-input sanity) with, by that file's own words, "no successor object -- they
-- are simply gone." scripts/check_live_sql_parity.py's find_final_definitions() is explicitly DROP-aware
-- of this exact object for this exact reason (see its 2026-07-28 comment) and expects it to stay absent.
-- Re-issuing a CREATE OR REPLACE VIEW for it here would silently resurrect a deliberately retired object
-- that no longer has any reader (analytics.fn_order_guard's current, bigquery/104 body never queries
-- it) -- reverting an explicit owner directive rather than fixing a live bug. If a future change brings
-- back an edge-relative shortfall budget fed by closed-campaign returns, ITS gate should filter dust as
-- part of standing it back up, not retroactively via this file.
--
-- Companion decision record: events.decision_log entry_id d154fcec-d434-4c4a-8f27-89b16be6e166
-- (2026-08-02 correction, same entry bigquery/123 cites).
--
-- No dbt port: ops.sp_recompute_engine is a PROCEDURE, verified against INFORMATION_SCHEMA.ROUTINES by
-- scripts/check_live_sql_parity.py, not ported to a dbt model (dbt/models covers VIEWs queried directly;
-- see dbt/README.md's procedure list). No dbt file changes needed for this fix.

-- ============================================================================
-- ops.sp_recompute_engine -- REBUILD. Byte-for-byte identical to the current canonical body
-- (bigquery/102_pyramid_aware_lifecycle.sql:305-373, itself byte-for-byte identical to bigquery/40_
-- options_marks.sql's version except for the option_mark_anomalies warning block, which was itself
-- byte-for-byte identical to bigquery/03_twr_engine.sql's original) with ONE change: the closed_trades
-- / gate_n subqueries now also exclude post-close DRIP-dust campaigns (`AND NOT COALESCE(l.is_dust,FALSE)`, gated by
-- analytics.position_campaigns.is_dust, bigquery/123_drip_dust_campaign_exclusion.sql), so a liquidated
-- dust lot can never count as a real closed trade. Nothing else in this procedure changed -- keep
-- bigquery/03/40/102/124's comments in sync if any of the four is ever edited again (per bigquery/40's
-- own note).
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
    -- Repointed to analytics.position_campaigns (Tier 2): campaign-level closed count, so a
    -- partial-exit pyramid counts as ONE closed trade, not one per FIFO lot.
    (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date AND NOT COALESCE(l.is_dust, FALSE)),
    GREATEST(0, 30 - (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date AND NOT COALESCE(l.is_dust, FALSE))),
    'value-weighted-daily-TWR-gross-v3',
    'PROFITABILITY metric: GROSS of commissions (scale artifact at ~$30 positions), total return, SGOV actual total-return benchmark. Cash/NAV accounting tracks commissions exactly + separately.'
  FROM peaked p;

  COMMIT TRANSACTION;
END;


-- VERIFICATION (run after apply).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- CREATE causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Filter is a no-op TODAY (dust is not yet sold, so exit_date IS NULL for both live dust rows and
--    closed_trades/gate_n cannot see them either way):
--    SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns`
--    WHERE exit_date IS NOT NULL AND NOT is_dust;
--    SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns`
--    WHERE exit_date IS NOT NULL;
--    -> expect both equal (live: 8 = 8).
--
-- 2. Filter becomes load-bearing only once a dust residual is liquidated (exit_date populated) --
--    at that point the first query above must stay LOWER than the second by exactly the number of
--    dust campaigns sold. This is the entire point of applying the fix now, before liquidation.

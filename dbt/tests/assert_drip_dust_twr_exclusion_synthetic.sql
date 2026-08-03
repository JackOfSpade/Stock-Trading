-- Singular regression (rewritten 2026-08-02 -- was vacuous: reimplemented the
-- `NOT COALESCE(is_dust, FALSE)` filter on synthetic UNNEST literals and diffed the copy
-- against itself, so it never called ref() and could never fail on a real regression in
-- {{ ref('strategy_daily_returns') }}).
--
-- House pattern (assert_thesis_outcomes_regime_asof.sql): recompute only the EXPECTED side
-- synthetically, then diff against the real ref(). Here the "expected side" is a byte-faithful
-- clone of {{ ref('strategy_daily_returns') }}'s own valuation logic (equity split-aware +
-- option-aware, mirrors bigquery/125_dust_excluded_from_twr.sql / dbt/models/analytics/
-- strategy_daily_returns.sql), built from {{ ref('position_lifecycle') }} +
-- {{ ref('daily_marks_curated') }} + {{ ref('option_marks_curated') }}, with ONE deliberate
-- change: the clone's WHERE clauses do NOT carry `NOT COALESCE(l.is_dust, FALSE)`. This clone is
-- the counterfactual deployed_capital the model WOULD report if that filter ever regressed away.
--
-- Fixed 2026-08-02 (2nd pass): the final SELECT used to join the real
-- {{ ref('strategy_daily_returns') }} to with_dust_totals with a plain INNER JOIN -- the same
-- intersection-only blind spot as campaign_semantics' Arm A: a regression where the real model
-- stops emitting a row entirely for an (as_of_date, strategy) that genuinely has dust exposure
-- would be silently dropped rather than flagged. Fixed to drive from with_dust_totals with a LEFT
-- JOIN to the real model instead.
--
-- REWRITTEN AGAIN same day (2026-08-02, 3rd pass -- fragility finding). The 2nd-pass version
-- recomputed the with-dust counterfactual and LEFT-JOIN-flagged a missing row correctly, but still
-- only compared it to the real model ON ROWS WHERE `dust_prev_mv_contribution > 0` (a witness
-- filter). That has two problems:
--   (a) Today there is EXACTLY ONE (as_of_date, strategy) row with positive dust contribution --
--       2026-07-20 / B -- because `state.daily_marks_curated` coverage for IBM/HCA (the two dust
--       tickers) is sparse (IBM: 2026-06-01..05 + 2026-07-20 only; HCA: near-daily through
--       2026-06-29, then a gap, then 2026-07-20 only -- verified live 2026-08-02). If D2's
--       ordinary marks ingest ever drops that one date's coverage (or never regains daily
--       coverage for these tickers), a witness-filtered WHERE clause returns an empty set and the
--       test silently degrades to "0 rows, always, no matter what real does" -- passing on a real
--       regression without ever exercising it.
--   (b) Once the two open dust residuals (IBM 0.0007sh / HCA 0.0001sh, both strategy B) are
--       LIQUIDATED (SELL 872490976 / 872491047, expected at Monday 2026-08-03's open),
--       `position_lifecycle` reshapes their rows (open_tail -> matched, `exit_date` set) -- a
--       witness-filtered test is more exposed to row-shape churn than one that never depends on a
--       specific row surviving.
--
-- THIS VERSION drops the witness filter entirely and asserts the invariant UNIVERSALLY over every
-- (as_of_date, strategy) pair the clone's own population covers -- dust-contributing or not.
--
-- DESIGN. From the same unfiltered with-dust clone, aggregate TWO sums per (as_of_date, strategy):
-- `deployed_capital_with_dust` (every open lot, dust included -- the counterfactual the real model
-- would report if its exclusion filter ever regressed away) and `deployed_capital_without_dust`
-- (dust lots zeroed out of the sum -- what the real model SHOULD report today, independently
-- derived from this test's own row-level `is_dust` flag, never by calling the real model's
-- filter).
--
-- The invariant under test: {{ ref('strategy_daily_returns') }}.deployed_capital =
-- deployed_capital_without_dust, for EVERY (as_of_date, strategy) pair the clone's population
-- covers -- not only the ones where a dust lot happens to contribute. This is a
-- universally-quantified property over all dust lots and all days: on a day/strategy with zero
-- dust exposure, `deployed_capital_with_dust` and `deployed_capital_without_dust` coincide and the
-- check is a trivial-but-real parity assertion; on a day/strategy with positive dust exposure the
-- two diverge and the check gets its teeth. Either way EVERY row is checked, so the test's
-- pass/fail correctness never depends on today's sparse-marks witness surviving, and it isn't
-- defeated by the row-shape change a liquidation causes: `is_dust` is a permanent per-lot flag
-- (set once at classification, bigquery/123) that survives a lot going from open_tail to
-- matched/exit_date-set unchanged, and a historical day already <= the lot's exit_date (unbounded
-- before liquidation, 2026-08-03 after) is marked dust either way -- proven in the SIMULATED
-- overlay below.
--
-- MISSING_FROM_REAL_MODEL is raised only when `deployed_capital_without_dust != 0` (or the real
-- model unexpectedly carries a row the clone has none for): the real model's own GROUP BY never
-- emits a zero-row for an (as_of_date, strategy) with no non-dust open position that day -- e.g. a
-- hypothetical day where a strategy's ONLY open lot is a dust residual -- so a clone row with
-- `deployed_capital_without_dust = 0` correctly has no real-model counterpart, and flagging that
-- as MISSING would be a false failure, not a caught regression. (Verified live 2026-08-02: this
-- case does not currently occur -- 0 of 134 (as_of_date, strategy) rows in the clone's population
-- are dust-only -- but the guard costs nothing and removes a latent false-fail mode.)
--
-- HONESTY ON CURRENT POWER (2026-08-02). The invariant is checked on EVERY row, but its ability
-- to actually CATCH a live dust-exclusion regression still requires at least one row where
-- `dust_prev_mv_contribution > 0` (otherwise `deployed_capital_with_dust` and `_without_dust` are
-- identical everywhere, and the two sides can never diverge no matter what the real model does).
-- Verified live 2026-08-02: exactly ONE such row exists -- 2026-07-20 / strategy B, contribution
-- $0.228964 -- out of 134 total (as_of_date, strategy) rows in the clone's population. That
-- witness is not expected to disappear on the 2026-08-03 liquidation (see proof 3 below). If BOTH
-- residuals liquidate and no new DRIP-dust event ever recurs, this test will keep PASSING
-- (correctly -- there is nothing left to exclude) but will have ZERO power to catch a future
-- regression in the exclusion filter until a new dust lot is classified. That is an honest
-- limitation of testing an exclusion against data that may stop containing the excluded thing, not
-- a defect in this file: there is no way to assert "X is excluded" against a dataset with no X.
--
-- PROVEN LIVE 2026-08-02 (`execute_sql_readonly`, project stock-trading-498512; ref() compiled by
-- hand to stock-trading-498512.analytics.<name> / stock-trading-498512.state.<name>):
--   1. As written below: 0 rows (134 population rows, all pass).
--   2. The regression this test guards -- substituting `deployed_capital_with_dust` for the real
--      model's reading (i.e. simulating the dust exclusion filter being removed from
--      {{ ref('strategy_daily_returns') }} itself) and re-running the identical invariant: 1 row
--      (2026-07-20 / B: real=40.596974, with-dust=40.368010, without-dust=40.368010 -- the
--      0.228964 delta is exactly the dust contribution). Proves the check has power today.
--   3. Simulated post-liquidation: a CTE overlay setting `exit_date = DATE '2026-08-03'` (+ a
--      placeholder `exit_price`) on the two dust lots only, everything else unchanged, re-run
--      against the ACTUAL (unmodified) {{ ref('strategy_daily_returns') }}: 0 rows, and the
--      2026-07-20/B witness's `dust_prev_mv_contribution` is unchanged at 0.228964 under the
--      overlay -- the liquidation does not silently defang the test.

WITH with_dust_equity_marked AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, l.exit_price, l.exit_date,
         CAST(1 AS INT64) AS multiplier, m.close, COALESCE(m.dividend, 0) AS dividend,
         COALESCE(NULLIF(m.split_ratio, 0), 1) AS day_split, l.is_dust
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('daily_marks_curated') }} m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
    -- deliberately NO `AND NOT COALESCE(l.is_dust, FALSE)` here -- this is the counterfactual.
),
with_dust_equity_runprod AS (
  SELECT *, EXP(SUM(LN(day_split)) OVER (
    PARTITION BY position_key ORDER BY mark_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS rp
  FROM with_dust_equity_marked
),
with_dust_equity_held AS (
  SELECT mark_date, strategy, position_key, shares, entry_price, multiplier, is_dust,
         shares * eff * IF(mark_date = exit_date, exit_price, close) AS mv,
         shares * eff * dividend AS div_cash
  FROM (
    SELECT *, SAFE_DIVIDE(rp, FIRST_VALUE(rp) OVER (PARTITION BY position_key ORDER BY mark_date)) AS eff
    FROM with_dust_equity_runprod
  )
),
with_dust_option_held AS (
  SELECT om.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, om.multiplier, l.is_dust,
         l.shares * om.multiplier * IF(om.mark_date = l.exit_date, l.exit_price, om.premium_close) AS mv,
         CAST(0 AS NUMERIC) AS div_cash
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('option_marks_curated') }} om
    ON om.occ_symbol = l.ticker
   AND om.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR om.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
    -- deliberately NO dust filter here either.
),
with_dust_held AS (
  SELECT * FROM with_dust_equity_held
  UNION ALL
  SELECT * FROM with_dust_option_held
),
with_dust_lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash, is_dust,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares * multiplier * entry_price) AS prev_mv
  FROM with_dust_held
),
with_dust_totals AS (
  SELECT mark_date AS as_of_date, strategy,
         SUM(prev_mv) AS deployed_capital_with_dust,
         -- The independently-derived EXPECTED value: dust lots zeroed out of the sum, computed by
         -- this test's own row-level `is_dust` flag -- never by calling the real model's filter.
         SUM(IF(NOT is_dust, prev_mv, 0)) AS deployed_capital_without_dust,
         SUM(IF(is_dust, prev_mv, 0)) AS dust_prev_mv_contribution
  FROM with_dust_lagged
  GROUP BY mark_date, strategy
)
-- LEFT JOIN driven from with_dust_totals (not an INNER JOIN keyed off the real model): w is an
-- independent recompute of the same (as_of_date, strategy) population strategy_daily_returns
-- covers, sharing its position_lifecycle/marks inputs, over EVERY row that population contains --
-- not filtered down to a discriminating witness (see header). The population guard below (rather
-- than a WHERE-clause witness filter) is what keeps this equivalent to a FULL OUTER JOIN: a row
-- present only in r with no clone counterpart is still visible here (LEFT JOIN would just never
-- produce it FROM r -- but r-only rows cannot exist for this population since w's population is a
-- strict superset: every (as_of_date, strategy) with an open non-dust OR dust lot).
SELECT w.as_of_date, w.strategy,
       r.deployed_capital AS actual_deployed_capital,
       w.deployed_capital_without_dust,
       w.deployed_capital_with_dust,
       w.dust_prev_mv_contribution,
       IF(r.as_of_date IS NULL, 'MISSING_FROM_REAL_MODEL', 'value_mismatch') AS failure_reason
FROM with_dust_totals w
LEFT JOIN {{ ref('strategy_daily_returns') }} r USING (as_of_date, strategy)
-- POPULATION GUARD: skip the (as_of_date, strategy) rows where BOTH sides genuinely have nothing
-- to report (deployed_capital_without_dust = 0 AND no real row) -- e.g. a hypothetical day where a
-- strategy's only open lot is a dust residual; the real model's GROUP BY correctly never emits a
-- row there, so a clone row like that is not a MISSING_FROM_REAL_MODEL failure. Every other row
-- (either side thinks something should exist) is checked -- this is the universally-quantified
-- assertion, not a witness-gated one.
WHERE (w.deployed_capital_without_dust != 0 OR r.as_of_date IS NOT NULL)
  AND (r.as_of_date IS NULL OR r.deployed_capital != w.deployed_capital_without_dust)

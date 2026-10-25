-- ===== 267: PAPER->PROBE regime coverage gate made real (W5 trigger of 2026-08-30) =====
-- Project: stock-trading-498512. Apply after 266. FOUR statements, all CREATE OR REPLACE VIEW, in dependency order:
--   1. state.technical_regime_daily        NEW
--   2. state.strategy_paper_regime_cells   NEW
--   3. state.arsenal_regime_coverage       SUPERSEDES bigquery/35
--   4. state.strategy_paper_readiness      SUPERSEDES bigquery/189 (chain 35 -> 189 -> 267)
-- Prose: Claude_Task_Plan.md SL3 STEP 2 (the `regime_met` pins), LIVE_RAMP_DESIGN.md section 9.
--
-- ===== THE DEFECT =====
-- state.strategy_paper_readiness.regime_met is `n_positive_cells >= 2 OR <gap_fill matched>`. Before this file:
--   * n_positive_cells counted the candidate's distinct SL3-stamped regime_cells carrying ANY paper day with
--     cumulative excess >= 0;
--   * gap_fill matched if ANY such day landed in a state.arsenal_regime_coverage cell with is_gap = TRUE;
--   * every cell is is_gap = TRUE until the first SISA-grown strategy reaches PROBE (the founding members
--     A-E were seeded straight to ADOPTED and never enter the coverage view's paper-only `demonstrated` CTE).
-- So on the FIRST graduation the term reduced to "one paper day with cumulative excess >= 0", which
-- excess_met already implies. Measured live 2026-10-25: all 9 cells covered_active_count = 0 / is_gap = TRUE,
-- analytics.strategy_incubation_perf 0 rows, 0 PAPER members. W5 accepted the finding on 2026-08-30 and ruled
-- the durable fix a BUILD (a technical-regime daily series plus a gate that requires demonstrated coverage),
-- due before the first PAPER->PROBE `probe-register` enqueue. Rev 21 (bigquery/266) made that enqueue
-- reachable again, about 65 trading days after the first new SHADOW registration.
--
-- A second, independent weakness in the same evidence: `excess` is the CUMULATIVE paper excess index
-- (sim_twr / sgov_twr - 1). Its sign on a day says how the whole paper run stands, not how the strategy did
-- in that day's regime. A candidate up 3% from an UP/LOW stretch keeps "positive excess" through a losing
-- NEUTRAL/NORMAL week, and would have been credited with both cells.
--
-- ===== THE FIX =====
-- 1. state.technical_regime_daily: one row per as_of_date from D2a's events.regime_events
--    scope='TECHNICAL_SIGNAL' SPY_TREND / VIX_REGIME rows (latest event_ts per date and key; the live table
--    carries an occasional same-day re-write, e.g. 2026-09-21 VIX_REGIME x2). regime_cell is the
--    strategy/01 two-token key `SPY_TREND/VIX_REGIME`, NULL unless both tokens are present and in the
--    shared vocabulary (scripts/check_roster_consistency.py R-J checks these IN lists). This is the series
--    bigquery/35's coverage header said "does not yet exist". Measured 2026-10-25: complete pairs on every
--    trading day from 2026-07-31; 3 cells observed (UP/NORMAL 37 days, UP/LOW 15, NEUTRAL/NORMAL 7).
-- 2. state.strategy_paper_regime_cells: per (strategy_code, regime_cell), each paper day is assigned the
--    SERIES cell for incubation_day (not SL3's stamped regime_cell, which the SL3 2026-08-27 pin showed can
--    be resolved off the wrong day), and the day's MARGINAL excess is the change in the cumulative index
--    since the previous non-NULL paper day: (1 + excess_t) / (1 + excess_prev) - 1, with excess_prev = 0 on
--    the first paper day. A cell is DEMONSTRATED when the candidate has >= 5 such days in it (one trading
--    week, the SHADOW floor) and the compounded marginal excess over those days is >= 0. A day whose ratio
--    cannot be logged (1 + excess <= 0) fails its cell closed. Days with no series row, or NULL excess,
--    carry no cell; their change rolls into the next non-NULL day, so no loss is dropped.
-- 3. state.arsenal_regime_coverage: `demonstrated` reads (2), so a cell is covered by an active strategy only
--    if that strategy demonstrated it under the same rule. Output columns unchanged.
-- 4. state.strategy_paper_readiness: n_positive_cells now counts DEMONSTRATED cells from (2), and gap_fill
--    counts only once the arsenal has at least one covered cell (coverage_measured). Every column expression
--    is byte-identical to bigquery/189; only the positive_cells / gap_fill CTEs change, plus the new
--    coverage_measured CTE. Net effect on regime_met:
--      * first graduation (no covered cell anywhere): >= 2 demonstrated cells, i.e. >= 10 paper days split
--        across two regimes with non-negative in-regime excess in each. One positive day cannot pass.
--      * later graduations: >= 2 demonstrated cells, OR one demonstrated cell the active arsenal does not
--        cover (the original gap-fill intent, now backed by >= 5 days of in-cell evidence).
--
-- ===== DIRECTION =====
-- Strictly tighter: every demonstrated cell had a paper day with excess >= 0 in some stamped cell, but not
-- conversely, and gap_fill now has an extra conjunct. `ready` can only flip TRUE -> FALSE; `stuck` (which
-- includes regime_met under NOT) can only flip FALSE -> TRUE, at paper_days >= 400. A candidate that holds
-- a single regime for its whole PAPER run waits (not culled) until the regime moves or the 400-day cull;
-- that is the breadth the gate was written to demand. Zero migration burden: no PAPER member and no
-- incubation rows exist today.
--
-- ===== BLAST RADIUS =====
-- state.strategy_paper_readiness: read by SL3 STEP 2 only (bigquery/189 header, re-grepped 2026-10-25).
-- state.arsenal_regime_coverage: read by this view's gap_fill, SL1's zero-coverage synthesis bias and SL3
-- STEP 5. With no active strategy ever having had a PAPER run, all 9 cells stay is_gap = TRUE after this
-- file, so SL1's bias is unchanged today.

-- 1. state.technical_regime_daily -------------------------------------------------------------------------
CREATE OR REPLACE VIEW `stock-trading-498512.state.technical_regime_daily` AS
WITH latest AS (
  SELECT as_of_date, key, value, event_ts
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope = 'TECHNICAL_SIGNAL' AND key IN ('SPY_TREND', 'VIX_REGIME')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY as_of_date, key ORDER BY event_ts DESC, event_id DESC) = 1
),
pivoted AS (
  SELECT as_of_date,
    MAX(IF(key = 'SPY_TREND', value, NULL)) AS spy_trend,
    MAX(IF(key = 'VIX_REGIME', value, NULL)) AS vix_regime,
    MAX(event_ts) AS latest_event_ts
  FROM latest
  GROUP BY as_of_date
)
SELECT
  as_of_date, spy_trend, vix_regime,
  IF(spy_trend IN ('UP', 'NEUTRAL', 'DOWN') AND vix_regime IN ('LOW', 'NORMAL', 'HIGH'),
     CONCAT(spy_trend, '/', vix_regime), NULL) AS regime_cell,
  latest_event_ts
FROM pivoted;

-- 2. state.strategy_paper_regime_cells --------------------------------------------------------------------
-- SUPERSEDED LIVE by bigquery/268_paper_regime_cells_carry_forward.sql (2026-10-25): a paper day with excess but no
-- regime cell had its change dropped instead of carried to the next kept day. DO NOT re-apply this CREATE live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_paper_regime_cells` AS
WITH paper AS (
  -- One row per (strategy_code, incubation_day): SL3's idempotency guard should already make it unique;
  -- newest computed_ts wins if it does not.
  SELECT strategy_code, incubation_day, CAST(excess AS FLOAT64) AS excess
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code, incubation_day ORDER BY computed_ts DESC) = 1
),
marginal AS (
  SELECT strategy_code, incubation_day, excess,
    COALESCE(LAST_VALUE(excess IGNORE NULLS) OVER (
      PARTITION BY strategy_code ORDER BY incubation_day
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prior_excess
  FROM paper
),
daily AS (
  SELECT m.strategy_code, m.incubation_day, t.regime_cell,
    SAFE.LN(SAFE_DIVIDE(1 + m.excess, 1 + m.prior_excess)) AS log_rel_excess
  FROM marginal m
  JOIN `stock-trading-498512.state.technical_regime_daily` t ON t.as_of_date = m.incubation_day
  WHERE m.excess IS NOT NULL AND t.regime_cell IS NOT NULL
)
SELECT
  strategy_code, regime_cell,
  COUNT(*) AS paper_days_in_cell,
  COUNTIF(log_rel_excess IS NULL) AS unloggable_days,
  EXP(SUM(log_rel_excess)) - 1 AS cell_excess,
  (COUNT(*) >= 5 AND COUNTIF(log_rel_excess IS NULL) = 0 AND SUM(log_rel_excess) >= 0) AS demonstrated
FROM daily
GROUP BY strategy_code, regime_cell;

-- 3. state.arsenal_regime_coverage ------------------------------------------------------------------------
-- Change from bigquery/35: `demonstrated` reads state.strategy_paper_regime_cells (series-assigned cells,
-- >= 5 days, compounded in-cell excess >= 0) instead of LOGICAL_OR(excess >= 0) over SL3-stamped cells.
-- The 9-cell grid, the cov CTE and every output column are byte-identical.
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_regime_coverage` AS
WITH cells AS (
  SELECT spy_trend, vix_regime, CONCAT(spy_trend, '/', vix_regime) AS regime_cell
  FROM UNNEST(['UP','NEUTRAL','DOWN']) AS spy_trend
  CROSS JOIN UNNEST(['LOW','NORMAL','HIGH']) AS vix_regime
),
demonstrated AS (
  SELECT p.strategy_code, p.regime_cell, p.demonstrated AS positive_excess
  FROM `stock-trading-498512.state.strategy_paper_regime_cells` p
),
cov AS (
  SELECT d.regime_cell,
    COUNTIF(r.is_active AND d.positive_excess) AS covered_active_count,
    COUNTIF(r.is_incubating AND d.positive_excess) AS covered_incubating_count
  FROM demonstrated d
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = d.strategy_code
  GROUP BY d.regime_cell
)
SELECT
  c.regime_cell, c.spy_trend, c.vix_regime,
  COALESCE(cov.covered_active_count, 0) AS covered_active_count,
  COALESCE(cov.covered_incubating_count, 0) AS covered_incubating_count,
  COALESCE(cov.covered_active_count, 0) = 0 AS is_gap
FROM cells c LEFT JOIN cov ON cov.regime_cell = c.regime_cell;

-- 4. state.strategy_paper_readiness -----------------------------------------------------------------------
-- Change from bigquery/189: positive_cells counts DEMONSTRATED cells; gap_fill requires a demonstrated gap
-- cell AND coverage_measured (some cell is covered by an active strategy). Every column expression, including
-- the four copies of the regime_met expression in regime_met / stuck / stuck_reason / ready, is
-- byte-identical (only the inline comments were shortened).
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_paper_readiness` AS
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS paper_days,
    MAX(sim_closed_trades) AS sim_closed_trades,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest_excess,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10) AS trailing_excess,
    ARRAY_LENGTH(ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10)) AS trailing_n
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper'
  GROUP BY strategy_code
),
positive_cells AS (
  -- Name kept so SL3's prose and the n_positive_cells column keep their meaning of "cells that count";
  -- since bigquery/267 a cell counts only if DEMONSTRATED (state.strategy_paper_regime_cells).
  SELECT strategy_code, COUNTIF(demonstrated) AS n_positive_cells
  FROM `stock-trading-498512.state.strategy_paper_regime_cells`
  GROUP BY strategy_code
),
coverage_measured AS (
  -- TRUE once any cell is covered by an active strategy. Until then every cell is a gap and a gap-fill
  -- disjunct would only restate "one demonstrated cell", so the >= 2 breadth bar must bind.
  SELECT LOGICAL_OR(NOT is_gap) AS any_cell_covered
  FROM `stock-trading-498512.state.arsenal_regime_coverage`
),
gap_fill AS (
  SELECT DISTINCT p.strategy_code
  FROM `stock-trading-498512.state.strategy_paper_regime_cells` p
  JOIN `stock-trading-498512.state.arsenal_regime_coverage` c ON c.regime_cell = p.regime_cell
  CROSS JOIN coverage_measured m
  WHERE p.demonstrated AND c.is_gap AND m.any_cell_covered
),
freq AS (
  -- trades_threshold computed ONCE here (adversarial self-audit fix, rev 2026-07-11) — the same CASE
  -- expression used to be duplicated 4x below (trades_met_threshold, trades_met, stuck, ready), inviting
  -- silent divergence if only some copies were ever edited. Semantics-preserving; the frequency-scaled
  -- trade-count floor for a slow-cadence strategy (declared_annual_roundtrips < 10), floored at 3.
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS trades_threshold
  FROM `stock-trading-498512.state.strategy_candidates`
  -- Defense-in-depth (2026-07-18 audit): candidate_code has no enforced uniqueness (NOT ENFORCED PK
  -- world) and four independent routines write NEW rows. A duplicate code here would fan out the
  -- LEFT JOIN below into duplicate readiness rows, corrupting the single `ready`/`stuck` boolean SL3
  -- keys transitions off. Newest row wins.
  QUALIFY ROW_NUMBER() OVER (PARTITION BY candidate_code ORDER BY created_ts DESC) = 1
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.paper_days, 0) AS paper_days,
  COALESCE(a.sim_closed_trades, 0) AS sim_closed_trades,
  a.latest_excess,
  fr.declared_annual_roundtrips,
  COALESCE(fr.trades_threshold, 10) AS trades_met_threshold,
  COALESCE(pc.n_positive_cells, 0) AS n_positive_cells,
  COALESCE(a.paper_days, 0) >= 60 AS days_met,
  COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10) AS trades_met,
  (COALESCE(a.trailing_n, 0) >= 10
   AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0) AS excess_met,
  (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL) AS regime_met,
  rails.adoption_window_open AS rate_limit_clear,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE')) AS not_already_transitioned,
  -- stuck (ITEM 9, 2026-07-11; WIDENED 2026-08-20 by bigquery/189 to cover all three PAPER dead-ends,
  -- mirroring bigquery/60's SHADOW flag): paper_days has run long enough (>=400) that continuing to wait
  -- is no longer reasonable, and at least one CANDIDATE-side gate term is still unmet. Read by
  -- Claude_Task_Plan.md SL3 STEP 4's PAPER TIME-CULL, not itself a component of `ready` below. Arsenal-state
  -- terms (rate_limit_clear / ceiling_ok / arsenal_ok / not_already_transitioned) are DELIBERATELY excluded.
  (COALESCE(a.paper_days, 0) >= 400
   AND NOT (
     COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
     AND (COALESCE(a.trailing_n, 0) >= 10
          AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
     AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   )) AS stuck,
  -- stuck_reason (2026-08-20): the '+'-joined list of failed candidate-side terms. NULL exactly when
  -- `stuck` is FALSE — `stuck_reason IS NOT NULL` <=> `stuck`, always.
  CASE WHEN COALESCE(a.paper_days, 0) < 400 THEN NULL
       ELSE NULLIF(ARRAY_TO_STRING(ARRAY_CONCAT(
              IF(NOT (COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)),
                 ['trades'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(a.trailing_n, 0) >= 10
                      AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0),
                 ['excess'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL),
                 ['regime'], ARRAY<STRING>[])
            ), '+'), '')
  END AS stuck_reason,
  (COALESCE(a.paper_days, 0) >= 60
   AND COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
   AND (COALESCE(a.trailing_n, 0) >= 10
        AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
   AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   AND rails.adoption_window_open
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN positive_cells pc USING (strategy_code)
LEFT JOIN gap_fill gf USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'PAPER';

-- VOO (Vanguard S&P 500 ETF) benchmark substrate for the weekly self-email (owner directive
-- 2026-07-13: compare deployed gain/loss vs SGOV AND vs VOO, same dollars/same days, with average
-- monthly and average yearly). Project: stock-trading-498512. Apply after 03_twr_engine.sql
-- (events.daily_marks, state.daily_marks_curated, analytics.strategy_daily_returns,
-- analytics.sgov_daily_return) and 21_strategy_vs_park.sql (analytics.strategy_vs_park_daily, the
-- date axis voo_cumulative mirrors).
--
-- WHY VOO IS A SEPARATE LEG FROM SGOV, NOT A REPLACEMENT: SGOV stays the sanctioned kill/gate
-- benchmark (perf.strategy_daily.excess_vs_sgov — UNTOUCHED by this file, per the ADDITIVE-ONLY
-- discipline established by 39_beta_adjusted_alpha.sql). VOO is a second, purely informational
-- "what if this had been left in the S&P 500 instead" comparison for the weekly email only. It does
-- NOT feed perf.kill_flags, state.strategy_retirement_candidacy, or any other live decision surface.
--
-- METHODOLOGY (design doc, chat handoff 2026-07-13): three legs computed over the deployed book's
-- OWN trading-day set (analytics.strategy_daily_returns), start = the book's first deployed day,
-- end = the latest deployed mark date (both derived dynamically, never hardcoded):
--   * Book   — capital-weighted daily return across strategies, compounded.
--   * SGOV   — analytics.sgov_daily_return, existing forward-fill convention (a missing mark repeats
--     the last known RATE — correct for a cash-like accrual).
--   * VOO    — analytics.voo_daily_return, COALESCE-to-0 on a gap (deliberately NOT forward-filled —
--     repeating a stale rate is right for cash, wrong for a volatile equity index; since r_voo LAGs
--     over VOO's OWN marks, the next real mark after a gap still spans it exactly).
-- Percent legs are geometric compounded returns; the "same dollars, same days" dollar legs re-base
-- the counterfactual to the book's ACTUAL deployed capital each day and sum arithmetically (the
-- established analytics.strategy_vs_park_daily.edge_dollars_day convention) — deliberately NOT a
-- compounding buy-and-hold hypothetical, which would answer a different question. Average
-- monthly/yearly stays a JS-side computation in weekly_report.gs (periodAvg_), not SQL, to keep that
-- one tested convention single-sourced.
--
-- VOO INGEST: one-time backfill via IBKR get_price_history(include_corporate_actions: true) for
-- 2026-04-17 (matching SGOV's series start) through the latest trading day, INSERT INTO
-- events.daily_marks (source='connector-backfill'); ongoing ingest added to D2a STEP 1
-- (Claude_Task_Plan.md) alongside the existing unconditional SGOV/SPY pulls. NOT a SPY backfill —
-- SPY intentionally stays at its current thin history (it feeds the live beta/alpha kill-suppression
-- in 39_beta_adjusted_alpha.sql; retroactively deepening it would change a live signal input).
--
-- NULL-vs-ZERO DISCIPLINE: deployed_book_vs_benchmarks exposes n_voo_mark_days / voo_last_mark_date
-- and NULLs every VOO-derived column when zero VOO marks exist in the window, specifically so the
-- weekly email's "not enough data" fallback path is reachable — a plain COALESCE-to-0 on the
-- aggregate would otherwise render a confident "VOO +0.00%" if the backfill were ever skipped.

-- ===== analytics.voo_daily_return — VOO's ACTUAL total return (close + dividend) =====
-- Byte-parallel to analytics.sgov_daily_return / analytics.spy_daily_return (03_twr_engine.sql,
-- 39_beta_adjusted_alpha.sql).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.voo_daily_return` AS
WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker = 'VOO'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_voo
FROM s WHERE prev_close IS NOT NULL;

-- ===== analytics.voo_cumulative — VOO's own cumulative total return, aligned to the deployed axis =====
-- Mirrors analytics.sgov_cumulative's date axis (DISTINCT as_of_date FROM strategy_vs_park_daily) so
-- the weekly email's chart plots SGOV and VOO on identical x-axes.
--
-- NULL-ON-GAP (2026-07-17 audit fix): voo_cum_return is NULL on ANY axis day with no real VOO mark —
-- both BEFORE VOO's first observed mark (first_voo_date) AND on any interior/trailing ingest gap
-- (r_voo IS NULL). The running cumulative is still chained internally with COALESCE(r_voo,0), so the
-- LEVEL is preserved across a gap and resumes exactly right on the next real mark (r_voo LAGs over
-- VOO's OWN marks, so the resume day's return spans the gap in full); only the OUTPUT on gap days is
-- hidden. WHY the change: the prior version emitted the COALESCE-to-0 cumulative on gap days too, which
-- (a) drew VOO as a confident FLAT line through a data gap — the "false flat" it was meant to avoid —
-- and (b) made vooLastMarkDate (derived in weekly_report.gs from the last non-null voo_cum_return)
-- structurally equal to as_of_date, so the email's "⚠ VOO data through <date>" staleness warning could
-- never fire. Emitting NULL on gap days fixes BOTH: the chart shows a genuine break, and the last
-- non-null day again equals the true last VOO mark, reviving the staleness guard. A VOO-only ingest
-- stall does NOT trip the all-ticker marks_fresh predicate, so this in-band signal is the only warning.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.voo_cumulative` AS
WITH axis AS (
  SELECT DISTINCT as_of_date
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
),
j AS (
  SELECT a.as_of_date, v.r_voo,
         MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER () AS first_voo_date
  FROM axis a
  LEFT JOIN `stock-trading-498512.analytics.voo_daily_return` v USING (as_of_date)
)
SELECT as_of_date,
  CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL  -- before VOO's first mark
       WHEN r_voo IS NULL THEN NULL  -- interior/trailing ingest gap: break the line, don't carry a false 0
       ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                OVER (ORDER BY as_of_date)) - 1  -- level chained across gaps via COALESCE, hidden above
  END AS voo_cum_return
FROM j;

-- ===== analytics.deployed_book_vs_benchmarks — ONE row: the weekly email's new headline block =====
-- Same-days book vs SGOV vs VOO, percent AND dollar ("same amount, same time") legs. n_voo_mark_days
-- / voo_last_mark_date are the data-presence signals the email gates its VOO rendering on (chart
-- line, headline row, subject fragment) — see the NULL-vs-ZERO note above.
--
-- VOO GAP-SPAN CAPITAL AVERAGING (adversarial self-audit, 2026-07-13): analytics.voo_daily_return's
-- r_voo is LAG'd over VOO's OWN sparse mark sequence, so the day VOO data resumes after any ingest
-- gap, r_voo is a MULTI-DAY catch-up return, not a one-day rate. The PERCENT legs (voo_return,
-- excess_vs_voo_pct) are unaffected by this — EXP(SUM(LN(1+r))) is invariant to how the return mass
-- is distributed across days, so a multi-day catch-up return chains in exactly the same as if it had
-- landed as several smaller daily returns. The DOLLAR legs are NOT invariant: pricing that whole
-- catch-up return against only the resume day's SINGLE-day deployed_capital snapshot misattributes it
-- to whichever capital level happened to be on record when data resumed, rather than the capital that
-- was actually deployed across the gap (this book's deployed_capital can move >2x day to day). Fix:
-- group every gap day with the resume day that closes it out (the nearest as_of_date >= it with a
-- real VOO mark, via voo_span_end below — the standard "gaps and islands" grouping), then price the
-- resume day's catch-up return against the AVERAGE capital across that whole span instead of its own
-- single day's snapshot. When there is no gap (every day has its own VOO mark, the case as of
-- 2026-07-13), every span is a singleton and voo_span_avg_capital == capital exactly — a mathematically
-- exact no-op, so this changes nothing about any figure already computed/emailed to date.
--
-- RETAINED, no longer read (v3 redesign, 2026-07-15; self-improvement audit 2026-07-16 orphan-doc
-- pass): this view was built as "the weekly email's new headline block" for the 2026-07-13 VOO
-- addition, but the 2026-07-15 v3 redesign removed that headline section entirely (see
-- ops/weekly_report/weekly_report.gs's own header: "the prior 'Deployed Book Since...' headline
-- section is gone entirely" — this view is explicitly on the .gs's "Retained but no longer read"
-- list). The email now reads analytics.strategy_scorecard + analytics.strategy_vs_park_daily +
-- analytics.voo_cumulative directly instead. Kept per this repo's "retain, don't delete" convention
-- for superseded analytics objects (see bigquery/04_analytics.sql's analytics.review_embeddings note).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.deployed_book_vs_benchmarks` AS
WITH agg AS (
  SELECT as_of_date,
         SAFE_DIVIDE(SUM(deployed_capital * r_deployed), SUM(deployed_capital)) AS r_agg,
         SUM(deployed_capital) AS capital,
         SUM(deployed_capital * r_deployed) AS pnl_dollars
  FROM `stock-trading-498512.analytics.strategy_daily_returns`
  GROUP BY as_of_date
),
j AS (
  SELECT a.as_of_date, a.r_agg, a.capital, a.pnl_dollars,
    GREATEST(COALESCE(sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY a.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0), -0.9999) AS r_sgov,
    GREATEST(COALESCE(v.r_voo, 0), -0.9999) AS r_voo,
    v.r_voo IS NOT NULL AS has_voo,
    -- Nearest as_of_date >= this row with a real VOO mark — the resume day this row's gap-span
    -- (if any) closes out on. A day WITH its own VOO mark maps to itself (a singleton span).
    MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER (
      ORDER BY a.as_of_date ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS voo_span_end
  FROM agg a
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
  LEFT JOIN `stock-trading-498512.analytics.voo_daily_return`  v  USING (as_of_date)
),
voo_span AS (
  SELECT *, AVG(capital) OVER (PARTITION BY voo_span_end) AS voo_span_avg_capital
  FROM j
)
SELECT
  MIN(as_of_date)                       AS first_deployed_date,
  MAX(as_of_date)                       AS as_of_date,
  COUNT(*)                              AS n_deployed_days,
  COUNTIF(has_voo)                      AS n_voo_mark_days,
  MAX(CASE WHEN has_voo THEN as_of_date END) AS voo_last_mark_date,
  EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) - 1 AS book_return,
  EXP(SUM(LN(1 + r_sgov))) - 1                   AS sgov_return,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE EXP(SUM(LN(1 + r_voo))) - 1 END      AS voo_return,
  EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) / EXP(SUM(LN(1 + r_sgov))) - 1
                                                 AS excess_vs_sgov_pct,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE EXP(SUM(LN(1 + GREATEST(r_agg, -0.9999)))) / EXP(SUM(LN(1 + r_voo))) - 1
       END                                       AS excess_vs_voo_pct,
  SUM(pnl_dollars)                               AS deployed_pnl_dollars,
  SUM(capital * r_sgov)                          AS sgov_counterfactual_dollars,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE SUM(voo_span_avg_capital * r_voo) END AS voo_counterfactual_dollars,
  SUM(pnl_dollars) - SUM(capital * r_sgov)       AS edge_vs_sgov_dollars,
  CASE WHEN COUNTIF(has_voo) = 0 THEN NULL
       ELSE SUM(pnl_dollars) - SUM(voo_span_avg_capital * r_voo) END AS edge_vs_voo_dollars
FROM voo_span;

-- bigquery/91_park_signal_layer.sql
-- PARK_ROUTER_DESIGN.md v2 §6 (evidence layer): events.signal_marks -- an isolated evidence layer
-- for the (future) AI park allocator. This file lands DATA plumbing only -- the allocator's own
-- decision logic (D1 PARK ALLOCATION CALL, D2 conversion, ops.park_control, menu/risk_tier, PENDING
-- concurrence, budgets) is out of scope here and is tracked separately (design doc §12,
-- bigquery/92_park_allocator.sql).
--
-- PROBLEM (recon_regime.md §3/§5, read before authoring this file): no daily VIX series exists
-- anywhere in BigQuery -- only a monthly month-end level in events.macro_fred (metric='vix', one
-- point per calendar month). No bond/credit ETF ticker (LQD/TLT/IEF/GOVT/MUB/HYG/PFF/AOR/VTI) has
-- ever been ingested into any table. The only SPY history that exists (events.daily_marks) is
-- INTENTIONALLY thin (6 rows as of this writing) -- bigquery/46_weekly_benchmarks.sql explicitly
-- forbids deepening it there because it is a live kill-signal / beta-adjustment input
-- (analytics.strategy_beta, bigquery/39_beta_adjusted_alpha.sql). A park allocator's briefing needs
-- real trend/vol/drawdown context for the menu + SPY + VIX that cannot be built on top of any
-- existing table without either corrupting a spec-frozen consumer or fabricating history that was
-- never actually ingested.
--
-- DESIGN: mirror events.daily_marks' shape + ingest contract exactly (same columns, same
-- PARTITION/CLUSTER, same idempotent latest-ingest-wins curated view) so this slots into the
-- existing D2a STEP 1 ingest pattern with zero new plumbing concepts -- a second table, ingested by
-- the same routine via the same connector fallback chain (IBKR primary / FMP fallback -- ^VIX
-- specifically has no cached IBKR contract_id per recon_regime.md §4, so ^VIX rows are expected to
-- land source='FMP-fallback' until/unless a contract_id is ever resolved and cached). Deliberately
-- and permanently SEPARATE from events.daily_marks -- not a superset, not a shared table with a
-- purpose flag -- so daily_marks' spec-frozen consumers (the deployed-TWR engine, perf.kill_flags,
-- the thin-SPY beta input) are structurally unable to see anything landed here. SPY may carry deep
-- history in THIS table (a 2-year backfill is fine) with zero effect on daily_marks' live signal.
--
-- Ticker population itself (SPY ~2y backfill, VIX ~1y backfill, 12 menu tickers going forward) is a
-- ONE-TIME OPERATIONAL step per PARK_ROUTER_DESIGN.md v2 §10 Phase 0 ("apply SQL; backfill
-- signal_marks; onboard all 12 menu tickers") -- NOT a SQL migration and NOT included in this file.
-- state.park_signal_daily below is therefore required to return zero rows, no error, against an
-- EMPTY events.signal_marks -- this file ships strictly before that backfill runs, and every CTE
-- below is written to degrade to "no matching rows" rather than error on an empty base table.
--
-- DEVIATION FROM TASK SPEC (recorded per HARD RULES -- follow repo reality over a conflicting spec
-- when they disagree, and record the deviation prominently): the assigned column list for
-- events.signal_marks (mark_date/ticker/close/dividend/split_ratio/source/ingest_ts) reproduces
-- events.daily_marks' ORIGINAL bigquery/03_twr_engine.sql text. LIVE events.daily_marks (confirmed
-- via get_table_info against project stock-trading-498512, 2026-07-18) has SINCE gained a
-- `row_uid STRING DEFAULT GENERATE_UUID()` column via bigquery/53_curated_view_tiebreak_fix.sql,
-- added specifically because ROW_NUMBER()'s tiebreak in a "latest ingest_ts wins" curated view is
-- UNDEFINED when two rows from the SAME multi-row INSERT share an identical ingest_ts (BigQuery
-- evaluates CURRENT_TIMESTAMP() once per query, not once per row). state.signal_marks_curated below
-- is the identical latest-ingest-wins dedup shape as state.daily_marks_curated and is exposed to the
-- exact same failure mode on a same-session catch-up re-ingest. Rather than reproduce a bug class
-- this repo has already found and fixed once, events.signal_marks is defined here WITH row_uid from
-- CREATE TABLE time (cheap -- this is a brand-new table, so none of 53's ALTER-split dance is
-- needed), and state.signal_marks_curated's ORDER BY carries the same `ingest_ts DESC, row_uid DESC`
-- tiebreaker as the fixed state.daily_marks_curated. This is "exact mirror of events.daily_marks
-- shape" taken at the LIVE shape, not the superseded file text -- mirror the pattern, not the stale
-- literal column list.
--
-- Apply after bigquery/90_catchup_inprogress_guard.sql.

-- ===== events.signal_marks — isolated park-allocator evidence layer =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.signal_marks` (
  mark_date DATE NOT NULL, ticker STRING NOT NULL, close NUMERIC,
  dividend NUMERIC, split_ratio NUMERIC,
  source STRING DEFAULT 'connector', ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  row_uid STRING DEFAULT GENERATE_UUID()
) PARTITION BY mark_date CLUSTER BY ticker
OPTIONS(description='Isolated signal/evidence layer for the park allocator (PARK_ROUTER_DESIGN.md v2 section 6) -- deliberately SEPARATE from events.daily_marks so that table spec-frozen consumers (the deployed-TWR engine, perf.kill_flags, the thin-SPY beta input to analytics.strategy_beta) are untouched by anything landed here. Holds daily closes for the 12-ticker park menu (CASH has no market price and is never a row here) plus SPY (deep history is OK in THIS table -- daily_marks SPY stays deliberately thin, see bigquery/46_weekly_benchmarks.sql) plus ^VIX. Same column shape and ingest contract as events.daily_marks, including the row_uid tiebreak column added there by bigquery/53. Consumers read state.signal_marks_curated (latest ingest wins per ticker/day), never this raw table directly.');

-- Dedup view (latest ingest wins per ticker/day) -- byte-identical pattern to the FIXED
-- state.daily_marks_curated (bigquery/53_curated_view_tiebreak_fix.sql), including the row_uid
-- secondary tiebreaker for an exact ingest_ts tie within one multi-row catch-up INSERT. ALL
-- consumers (state.park_signal_daily below, and any future allocator routine reading a non-SPY
-- menu ticker's price directly) must read THIS view, never events.signal_marks directly.
CREATE OR REPLACE VIEW `stock-trading-498512.state.signal_marks_curated` AS
SELECT * FROM `stock-trading-498512.events.signal_marks`
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC) = 1;

-- ===== state.park_signal_daily — SPY-anchored daily signal briefing substrate =====
-- One row per mark_date present for SPY in state.signal_marks_curated (the driving/anchor series;
-- a mark_date with no SPY row -- e.g. before backfill, or a gap -- produces no output row at all,
-- by design: there is nothing to compute trend/drawdown context FOR on that date). Every other
-- menu ticker's own price series lives in state.signal_marks_curated and is read directly by
-- whatever future routine needs it (this view does not attempt to be a general per-ticker signal
-- table -- only the task-specified SPY/VIX/regime substrate below).
--
-- vix_med3: "a real median" of the 3 most recent available ^VIX closes AS OF each SPY mark_date
-- (not a same-calendar-day window -- VIX and SPY need not share an ingest date), implemented as the
-- sorted middle element of an exactly-3-element array (the true median for an odd count, no
-- interpolation ambiguity) -- NULL unless 3 distinct prior-or-same-date ^VIX observations actually
-- exist yet (mirrors the >=50 / >=200 obs floors on the SPY DMAs below, and is deliberately stricter
-- than "average of however many are available," which would silently mislabel a 1- or 2-obs figure
-- as a "3-close median").
--
-- shock_overlay / inflation_trend / growth_momentum / policy_stance / risk_sentiment: AS-OF (not
-- current-only) lookups against events.regime_events scope='FUNDAMENTAL_AXIS' -- the same
-- decorrelated-join + QUALIFY as-of pattern already established by analytics.thesis_outcomes
-- (bigquery/04_analytics.sql: "the regime in effect ON OR BEFORE" the row's own date), extended
-- with event_id DESC as a third tiebreaker to match state.current_regime's own canonical ordering
-- (bigquery/01_schema.sql) exactly -- a mark_date predating the first FUNDAMENTAL_AXIS row correctly
-- surfaces NULL for all 5 axes rather than silently borrowing a future value or erroring.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_signal_daily` AS
WITH spy AS (
  SELECT mark_date, close AS spy_close
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker = 'SPY'
),
spy_windowed AS (
  SELECT
    mark_date, spy_close,
    AVG(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 49  PRECEDING AND CURRENT ROW) AS spy_50dma_raw,
    COUNT(*)       OVER (ORDER BY mark_date ROWS BETWEEN 49  PRECEDING AND CURRENT ROW) AS n50,
    AVG(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) AS spy_200dma_raw,
    COUNT(*)       OVER (ORDER BY mark_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) AS n200,
    -- trailing 252-obs high INCLUDING the current row -- day 1 of history correctly yields dd=0
    -- (today's close IS the trailing high on day 1), not an error or a fabricated floor; no
    -- separate obs-count gate here (unlike the DMAs) because the task spec does not ask for one and
    -- the degenerate early-history value is honest, not misleading.
    MAX(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 251 PRECEDING AND CURRENT ROW) AS spy_252d_high
  FROM spy
),
spy_dma AS (
  SELECT
    mark_date, spy_close, spy_252d_high,
    IF(n50  >= 50,  spy_50dma_raw,  NULL) AS spy_50dma,
    IF(n200 >= 200, spy_200dma_raw, NULL) AS spy_200dma
  FROM spy_windowed
),
vix_all AS (
  SELECT mark_date, close AS vix_close
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker = '^VIX'
),
vix_asof3 AS (
  -- Decorrelated as-of join: for every SPY mark_date, the up-to-3 most recent ^VIX closes on or
  -- before that date. LEFT JOIN so a SPY date preceding any ^VIX history still gets a row (an empty
  -- array after IGNORE NULLS), never a dropped mark_date.
  SELECT
    sd.mark_date,
    ARRAY_AGG(v.vix_close IGNORE NULLS ORDER BY v.mark_date DESC LIMIT 3) AS last3_vix
  FROM spy_dma sd
  LEFT JOIN vix_all v ON v.mark_date <= sd.mark_date
  GROUP BY sd.mark_date
),
regime_axis AS (
  SELECT event_id, event_ts, as_of_date, key, value
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope = 'FUNDAMENTAL_AXIS'
    AND key IN ('shock_overlay', 'inflation_trend', 'growth_momentum', 'policy_stance', 'risk_sentiment')
),
regime_asof AS (
  SELECT sd.mark_date, ra.key, ra.value
  FROM spy_dma sd
  JOIN regime_axis ra ON ra.as_of_date <= sd.mark_date
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY sd.mark_date, ra.key
    ORDER BY ra.as_of_date DESC, ra.event_ts DESC, ra.event_id DESC
  ) = 1
),
regime_pivot AS (
  SELECT
    mark_date,
    MAX(IF(key = 'shock_overlay',   value, NULL)) AS shock_overlay,
    MAX(IF(key = 'inflation_trend', value, NULL)) AS inflation_trend,
    MAX(IF(key = 'growth_momentum', value, NULL)) AS growth_momentum,
    MAX(IF(key = 'policy_stance',   value, NULL)) AS policy_stance,
    MAX(IF(key = 'risk_sentiment',  value, NULL)) AS risk_sentiment
  FROM regime_asof
  GROUP BY mark_date
)
SELECT
  sd.mark_date,
  vx.vix_close,
  CASE WHEN ARRAY_LENGTH(v3.last3_vix) = 3
    THEN (SELECT arr[OFFSET(1)] FROM (SELECT ARRAY_AGG(x ORDER BY x) AS arr FROM UNNEST(v3.last3_vix) AS x))
    ELSE NULL
  END                                                                     AS vix_med3,
  sd.spy_close,
  sd.spy_50dma,
  sd.spy_200dma,
  CASE
    WHEN sd.spy_50dma IS NULL OR sd.spy_200dma IS NULL THEN NULL
    WHEN sd.spy_close > sd.spy_50dma AND sd.spy_50dma > sd.spy_200dma THEN 'UP'
    WHEN sd.spy_close < sd.spy_50dma AND sd.spy_50dma < sd.spy_200dma THEN 'DOWN'
    ELSE 'NEUTRAL'
  END                                                                     AS spy_trend,
  SAFE_DIVIDE(sd.spy_close, sd.spy_252d_high) - 1                        AS dd_from_252d_high,
  rp.shock_overlay,
  rp.inflation_trend,
  rp.growth_momentum,
  rp.policy_stance,
  rp.risk_sentiment
FROM spy_dma sd
LEFT JOIN vix_all vx      ON vx.mark_date = sd.mark_date
LEFT JOIN vix_asof3 v3    ON v3.mark_date = sd.mark_date
LEFT JOIN regime_pivot rp ON rp.mark_date = sd.mark_date
ORDER BY sd.mark_date;

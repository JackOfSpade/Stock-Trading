-- ITEM: state.strategy_shadow_readiness.signal_rate_ok has no upper bound despite being documented
-- (in this file and Claude_Task_Plan.md) as a "band" check (2026-07-14 self-improvement audit,
-- finding sql-late#4).
--
-- BUG: bigquery/35_strategy_arsenal.sql line ~434's own comment says "signals generated within
-- band"; Claude_Task_Plan.md's SL3 STEP 2 repeats it verbatim ("signal rate within the declared
-- band"). But the view only implements `COALESCE(a.signals_generated, 0) >= 1 AS signal_rate_ok` —
-- a bare FLOOR of 1 signal across the entire 20-day SHADOW window, with no ceiling and no reference
-- to state.strategy_candidates.declared_annual_roundtrips (both already exist and are used for
-- exactly this kind of archetype-aware scaling two views down, in state.strategy_paper_readiness's
-- `freq` CTE). A strategy whose signal logic is broken and fires hundreds of spurious signals in 20
-- days — the "too many" failure mode a band exists to catch — passes signal_rate_ok identically to
-- one that fired exactly once, advancing toward PAPER and eventually live PROBE capital with no
-- detection.
--
-- FIX: join state.strategy_candidates (same pattern as strategy_paper_readiness's `freq` CTE) and add
-- an upper bound scaled off declared_annual_roundtrips, pro-rated to the 20-trading-day shadow
-- window with a generous safety multiplier (a "signal" is a looser, more frequent router event than
-- an actual closed round-trip, so the multiplier is deliberately wide to avoid false-rejecting a
-- healthy candidate). CALIBRATION NOTE: the specific multiplier below (15x the pro-rated declared
-- rate, floored at 30) is a reasoned starting point, not something verified against live
-- analytics.strategy_incubation_perf history (no SHADOW candidate has produced this data yet as of
-- 2026-07-14) — sanity-check it against the first few real SHADOW candidates' signal counts before
-- treating a rejection near this ceiling as authoritative, and retune here (new numbered file) if
-- the real signal-to-roundtrip ratio turns out very different from this estimate.
--
-- Also corrects the false "min_shadow_trading_days = 20 (policy constant, mirrored in roster.yaml)"
-- claim in the original comment — grep confirms `min_shadow_trading_days` appears nowhere in
-- strategy/roster.yaml and is not among the constants scripts/check_roster_consistency.py's
-- RAIL_NAMES cross-checks. This file adds the constant to roster.yaml's rails block as a policy
-- record; wiring a full R-E-style CI cross-check for it (mirroring how arsenal_rails' other
-- constants are enforced) is a reasonable follow-up, not done here.
--
-- SUPERSEDES the state.strategy_shadow_readiness VIEW definition in bigquery/35_strategy_arsenal.sql.
-- No dbt mirror exists. Apply after 35_strategy_arsenal.sql, 46_weekly_benchmarks.sql.
--
-- SUPERSEDED LIVE in turn by bigquery/60_shadow_stuck_cull.sql — the CURRENT single source of truth
-- for this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_shadow_readiness` AS
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS shadow_days,
    SUM(signals_generated) AS signals_generated,
    SUM(scaffolding_faults) AS scaffolding_faults
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'shadow'
  GROUP BY strategy_code
),
-- Same archetype-aware scaling pattern as strategy_paper_readiness's `freq` CTE: a declared slow
-- archetype (< 10 annual round-trips) gets a proportionally lower signal-rate ceiling than the
-- fast-archetype fallback.
freq AS (
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS annualized_rate_floor
  FROM `stock-trading-498512.state.strategy_candidates`
),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.shadow_days, 0) AS shadow_days,
  COALESCE(a.signals_generated, 0) AS signals_generated,
  COALESCE(a.scaffolding_faults, 0) AS scaffolding_faults,
  fr.declared_annual_roundtrips,
  -- signal_rate_ceiling: GREATEST(30, 15x the declared annual rate pro-rated to a 20-trading-day
  -- (~252 trading days/yr) window) — see the file header calibration note.
  GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64)) AS signal_rate_ceiling,
  COALESCE(a.shadow_days, 0) >= 20 AS days_met,
  (COALESCE(a.signals_generated, 0) >= 1
   AND COALESCE(a.signals_generated, 0) <=
       GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64))
  ) AS signal_rate_ok,
  COALESCE(a.scaffolding_faults, 0) = 0 AS scaffolding_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER')) AS not_already_transitioned,
  (COALESCE(a.shadow_days, 0) >= 20
   AND COALESCE(a.signals_generated, 0) >= 1
   AND COALESCE(a.signals_generated, 0) <=
       GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64))
   AND COALESCE(a.scaffolding_faults, 0) = 0
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN ars
WHERE r.current_state = 'SHADOW';

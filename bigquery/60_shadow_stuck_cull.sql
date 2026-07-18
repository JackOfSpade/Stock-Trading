-- SHADOW time-based cull (self-improvement audit 2026-07-15 — CONFIRMED GAP
-- shadow-incubation-no-time-cull). Project: stock-trading-498512.
--
-- PROBLEM: SL3 STEP 4's cull instruction (Claude_Task_Plan.md) says "On a window-exceeded /
-- catastrophic break (SHADOW)... write a REJECTED events.strategy_lifecycle row" — but neither that
-- instruction, Experiment_Parameters.md, nor bigquery/52_shadow_readiness_band.sql numerically defines
-- "window-exceeded." Unlike PAPER, which got an explicit 400-day `stuck` flag (ITEM 9, 2026-07-11,
-- bigquery/35_strategy_arsenal.sql), SHADOW has no objective, SQL-encoded time-based cull at all — a
-- SHADOW candidate whose signal rate never clears the floor, breaches the ceiling, or whose
-- scaffolding fault never clears could sit indefinitely, permanently occupying one of the two
-- `k_incubate` slots another candidate could use.
--
-- FIX: mirror ITEM 9's PAPER `stuck` flag exactly, for SHADOW — one boolean covering all three SHADOW
-- dead-ends (signal floor never clears, signal ceiling breached, scaffolding fault never clears), using
-- the SAME 400-day constant PAPER already uses and that this file's own reasoning (below) supports.
--
-- CALIBRATION NOTE (matches bigquery/52's own precedent of documenting an estimate, not a proof): 400
-- days is PAPER's constant, reused here rather than inventing a SHADOW-specific one. SHADOW's own gate
-- (bigquery/52) requires only 20 trading days + >=1 signal — a MUCH lower bar than PAPER's 60-day/
-- archetype-scaled-trade-count gate — so a genuinely slow-but-healthy SHADOW candidate should clear
-- `ready` in well under 400 days for every declared archetype in this codebase (even Strategy D's
-- slowest-declared cadence, ~1.5-4 round-trips/yr, only needs >=1 SIGNAL — a looser, more frequent
-- router event than a closed round-trip — within a 20-trading-day window, not 400). 400 days is
-- therefore a deliberately generous backstop against a genuinely broken/dead candidate, not a bar any
-- healthy candidate should ever approach — sanity-check against the first real SHADOW candidate that
-- takes materially longer than 20 days to clear `ready` before assuming this constant needs its own
-- tuning pass (same caveat bigquery/52's header already carries for its signal-rate ceiling).
--
-- SUPERSEDES the state.strategy_shadow_readiness VIEW definition in bigquery/52_shadow_readiness_band.sql
-- (adds one new `stuck` column; every other column unchanged). Apply after 52_shadow_readiness_band.sql.
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
freq AS (
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS annualized_rate_floor
  FROM `stock-trading-498512.state.strategy_candidates`
  -- Defense-in-depth (2026-07-18 audit, mirrors state.strategy_paper_readiness's freq): candidate_code
  -- has no enforced uniqueness and four independent routines write NEW rows; a duplicate would fan out
  -- the LEFT JOIN into duplicate readiness rows and corrupt the `ready`/`stuck` booleans. Newest wins.
  QUALIFY ROW_NUMBER() OVER (PARTITION BY candidate_code ORDER BY created_ts DESC) = 1
),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  COALESCE(a.shadow_days, 0) AS shadow_days,
  COALESCE(a.signals_generated, 0) AS signals_generated,
  COALESCE(a.scaffolding_faults, 0) AS scaffolding_faults,
  fr.declared_annual_roundtrips,
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
  -- stuck (2026-07-15, mirrors PAPER's ITEM 9 `stuck` exactly): shadow_days has run long enough
  -- (>=400) that continuing to wait is no longer reasonable, independent of `ready` below — read by
  -- Claude_Task_Plan.md SL3 STEP 4's new SHADOW TIME-CULL, not itself a component of `ready` (a stuck
  -- candidate is culled to REJECTED, not promoted). Covers all three SHADOW dead-ends in one flag:
  -- signal_rate_ok FALSE because the floor (>=1) never cleared, OR because the ceiling was breached
  -- (a broken signal path firing spuriously), OR scaffolding_ok FALSE (a scaffolding fault never
  -- cleared).
  (COALESCE(a.shadow_days, 0) >= 400
   AND NOT (
     (COALESCE(a.signals_generated, 0) >= 1
      AND COALESCE(a.signals_generated, 0) <=
          GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64)))
     AND COALESCE(a.scaffolding_faults, 0) = 0
   )) AS stuck,
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

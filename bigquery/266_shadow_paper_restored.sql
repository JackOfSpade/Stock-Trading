-- ===== 266: SHADOW + PAPER incubation restored ahead of the live ramp (EP rev 21, owner directive 2026-10-25) =====
-- Project: stock-trading-498512. Apply after 265. THREE statements, all CREATE OR REPLACE VIEW, in dependency order:
--   1. state.arsenal_rails                  SUPERSEDES bigquery/259 (chain 35 -> 259 -> 266)
--   2. state.strategy_adoption_readiness    SUPERSEDES bigquery/259 (chain 35 -> 143 -> 259 -> 266)
--   3. state.strategy_shadow_readiness      SUPERSEDES bigquery/60  (chain 35 -> 52 -> 60 -> 266)
-- Each body is the superseded file's, extracted mechanically; the changes are listed per statement below.
-- Design record: LIVE_RAMP_DESIGN.md section 9. Prose: Experiment_Parameters.md rev 21, Strategy.md Rev 54,
-- Claude_Task_Plan.md SL3 / SL5.
--
-- ===== WHAT THE OWNER ASKED FOR =====
-- Rev 20 (bigquery/259, 2026-10-19) sent a candidate that cleared adversarial review straight into PROBE with
-- real capital. On 2026-10-25 the owner restored a no-capital forward test in front of it:
--   UNDER_REVIEW -> SHADOW (>= 5 trading days of signals, no orders)
--                -> PAPER  (>= 60 trading days, >= 10 simulated closed trades, sustained excess vs SGOV >= 0)
--                -> PROBE  (the rev 20 live ramp, unchanged: ramp floor, per-trade score, evidence kill)
--                -> ADOPTED (ramp score 1.0, unchanged)
-- and asked for more candidates in flight at once, since SHADOW and PAPER cost no capital.
--
-- ===== WHAT IS NOT CHANGED =====
-- state.strategy_paper_readiness (bigquery/189) is already exactly the PAPER gate above (60 days, the
-- archetype-scaled trade floor that is 10 for any candidate declaring >= 10 round-trips a year, the
-- trailing-10-day excess >= 0 test, regime coverage, adoption window, n_max, arsenal switch, marker
-- '<code>:PAPER->PROBE'), and it reads its window and ceiling from state.arsenal_rails, so it picks up the
-- new 30-day window through statement 1 with no redefinition. state.strategy_roster (bigquery/70) already
-- stamps spec_locked_since at SHADOW entry and immutable_since at PROBE entry, so the ramp's trade window
-- (analytics.strategy_ramp_trades, entry_date >= immutable_since) starts at PROBE, as it should: simulated
-- PAPER trades never count toward the ramp score. state.strategy_ramp, analytics.fn_ramp_path and
-- perf.kill_flags (bigquery/259) are untouched.

-- 1. state.arsenal_rails ----------------------------------------------------------------------------------
-- Changes from bigquery/259: (a) incubating_count counts SHADOW+PAPER again (state.strategy_roster.is_incubating,
-- the bigquery/35 expression), because incubation is once more the no-capital forward test; PROBE is live
-- capital and is bounded by n_max (active_count counts PROBE) and the adoption window instead. (b) k_incubate
-- 2 -> 6: six concurrent no-capital incubations. (c) adoption_rate_window_days 90 -> 30 and the matching
-- probes_in_window interval: at most one strategy enters live capital per rolling 30 days. n_min, n_max,
-- k_regime, the commission ceiling and the three cooldowns are byte-identical.
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_rails` AS
WITH consts AS (
  SELECT
    2  AS n_min,                       -- roster floor (blocks SL4 below it; a hit forces SL1 generation)
    8  AS n_max,                       -- roster ceiling (~$10k account cost discipline)
    6  AS k_incubate,                  -- max concurrent SHADOW+PAPER incubations (rev 21, 2026-10-25; was 2, PROBE-counted under rev 20)
    3  AS k_regime,                    -- regime-coverage target
    180 AS max_roundtrip_commission_bps, -- accepted probe-scale all-in round-trip ceiling (1.8%)
    30 AS adoption_rate_window_days,   -- <= 1 PROBE per rolling 30 days (rev 21, 2026-10-25; was 90)
    90 AS reject_cooldown_days,
    180 AS terminate_cooldown_days,
    90 AS keep_cooldown_days
),
counts AS (
  SELECT
    (SELECT AS STRUCT COUNTIF(is_active) AS active_count, COUNTIF(is_incubating) AS incubating_count
       FROM `stock-trading-498512.state.strategy_roster`) AS roster,
    (SELECT COUNT(*) FROM `stock-trading-498512.events.strategy_lifecycle`
       WHERE to_state = 'PROBE'
         AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)) AS probes_in_window
)
SELECT
  c.n_min, c.n_max, c.k_incubate, c.k_regime, c.max_roundtrip_commission_bps,
  c.max_roundtrip_commission_bps / NUMERIC '100' AS max_roundtrip_commission_pct,
  c.adoption_rate_window_days,
  c.reject_cooldown_days, c.terminate_cooldown_days, c.keep_cooldown_days,
  n.roster.active_count AS active_count, n.roster.incubating_count AS incubating_count, n.probes_in_window,
  n.roster.active_count <= c.n_min      AS at_or_below_floor,
  n.roster.active_count >= c.n_max      AS at_ceiling,
  n.roster.incubating_count >= c.k_incubate AS incubation_cap_reached,
  n.probes_in_window = 0         AS adoption_window_open
FROM consts c CROSS JOIN counts n;

-- 2. state.strategy_adoption_readiness --------------------------------------------------------------------
-- Change from bigquery/259: the idempotency marker is '<code>:UNDER_REVIEW->SHADOW' again (SL5 branch (1)
-- registers a SUFFICIENT candidate into SHADOW, the pre-rev-20 bigquery/143 literal). caps_ok now means
-- "an incubation slot is free" through statement 1. Every other term is byte-identical.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_adoption_readiness` AS
WITH latest_verdict AS (
  SELECT strategy AS strategy_code, verdict, review_id
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'strategy-adoption' AND role = 'orchestrator'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) = 1
),
theater AS (
  SELECT review_id, judge_independent
  FROM `stock-trading-498512.analytics.theater_judge`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  v.verdict,
  v.verdict = 'SUFFICIENT' AS review_sufficient,
  COALESCE(t.judge_independent, FALSE) AS theater_ok,
  NOT rails.incubation_cap_reached AS caps_ok,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW')) AS not_already_transitioned,
  (v.verdict = 'SUFFICIENT'
   AND COALESCE(t.judge_independent, FALSE)
   AND NOT rails.incubation_cap_reached
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->SHADOW'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest_verdict v USING (strategy_code)
LEFT JOIN theater t ON t.review_id = v.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'UNDER_REVIEW';

-- 3. state.strategy_shadow_readiness ----------------------------------------------------------------------
-- Change from bigquery/60: the shadow-day floor is 5 trading days (was 20), in days_met and in ready. The
-- signal-rate band, the scaffolding test, the arsenal switch, the '<code>:SHADOW->PAPER' marker and the
-- 400-day stuck cull are byte-identical. The ceiling keeps its 20-trading-day window term (20.0 / 252.0): it
-- is a broken-signal-path detector, floored at 30 signals, and a candidate graduating at day 5 can only be
-- held back by it if it fires more than 30 times in a week, which is the fault it exists to catch.
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
  COALESCE(a.shadow_days, 0) >= 5 AS days_met,
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
  (COALESCE(a.shadow_days, 0) >= 5
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

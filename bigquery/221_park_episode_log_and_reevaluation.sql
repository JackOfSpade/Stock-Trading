-- 221_park_episode_log_and_reevaluation.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 3 support.
-- Project: stock-trading-498512. Creates analytics.park_episode_log (one row per multi-axis
-- engagement episode, scored) and state.park_reevaluation_due (the forward-test countdown W5 reads).
-- Apply after 220.
--
-- ============================ WHY THIS EXISTS ==================================================
-- The owner activated the graded ladder on live capital 2026-09-04 with an explicit forward-test
-- plan: run it, accumulate 2-3 more multi-axis episodes, then re-evaluate. The re-evaluation must
-- NOT depend on anyone remembering — the owner said so directly. This file is the memory.
--
-- state.park_reevaluation_due counts EPISODES since activation and flips `due` at the threshold.
-- W5 (weekly, Sunday late — it already owns the PARK SCORECARD) reads it and raises a `warning`
-- alert, which reaches the operator by email through the existing path: ops.alerts ->
-- alert_emailer.gs (primary, POLL_HOURS=2) with scripts/alert_relay.py as the backup, both of which
-- filter `severity IN ('critical','warning')`. NO NEW CRON — the repo's cost discipline (CLAUDE.md)
-- makes a new scheduled workflow ~10x the price of riding an existing routine, and W5 already runs.
-- `warning` and not `critical` deliberately: critical enters blocking_criticals and would halt order
-- staging INCLUDING EXITS; `info` is filtered out of both notification paths and would be invisible.
--
-- ============================ WHAT AN EPISODE IS ===============================================
-- A maximal run of consecutive SESSIONS during which the ladder actually HELD a defensive position
-- (f_prev_pct > 0 in analytics.park_ladder_shadow — the lagged weight, i.e. what the book really
-- carried that session). Runs are numbered by the standard "count the gaps" idiom.
-- Episodes are scored on the SAME close-to-close total-return ruler the shadow uses, so nothing here
-- is a cross-ruler comparison, and each episode reports all three arms:
--   ladder_edge_vs_actual_pp  — the decision-relevant one. The alternative to the ladder is NOT
--                               "never de-risk", it is the binary all-or-nothing switch the book
--                               did before. This is the criterion the re-evaluation turns on.
--   ladder_edge_vs_never_pp   — reported every episode so the bigger question stays visible, but it
--                               deliberately does NOT gate: whether to de-risk AT ALL is a separate
--                               and larger decision than whether to grade the response.
--
-- ============================ HONESTY BOUND, STATED NOT BURIED =================================
-- Measured before activation over 15 historical engagement episodes (~13 months, the three
-- long-history axes), FORWARD-LOOKING with the execution lag applied: mean defensive edge
-- -0.638pp, SD 1.308pp, defensive won only 4 of 15. The contemporaneous version of the same
-- measurement looks excellent (+1.431pp, 14 of 15) and is a TRAP — the index axis fires BECAUSE the
-- market already fell, so measuring returns over the same window merely restates the trigger. Any
-- future re-derivation here must apply the lag or it will reach the flattering, wrong answer.
-- With SD ~2x the effect, 2-3 episodes CANNOT resolve the question statistically (that needs ~30
-- episodes, ~2.5 years). The forward test is therefore for STRUCTURAL discovery — does the shock
-- axis fire on real risk or on cross-asset noise, does STRICT decay hold too long — not for
-- statistical power. The threshold is set to the owner's stated plan, and this comment exists so the
-- re-evaluating session does not mistake it for a significance test.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_episode_log` AS
WITH s AS (
  SELECT as_of_date, f_prev_pct, r_ladder, r_actual, r_risk, r_def,
         standing_defensive_count, cap_pct, conviction_pct
  FROM `stock-trading-498512.analytics.park_ladder_shadow`
),
runs AS (
  SELECT *,
         COALESCE(f_prev_pct, 0) > 0 AS engaged,
         COUNTIF(NOT (COALESCE(f_prev_pct, 0) > 0)) OVER (ORDER BY as_of_date) AS grp
  FROM s
)
SELECT
  grp                                              AS episode_key,
  MIN(as_of_date)                                  AS episode_start,
  MAX(as_of_date)                                  AS episode_end,
  COUNT(*)                                         AS sessions,
  MAX(f_prev_pct)                                  AS peak_defensive_pct,
  MAX(standing_defensive_count)                    AS peak_standing,
  ROUND((EXP(SUM(LN(1 + IFNULL(r_ladder, 0)))) - 1) * 100, 4) AS ladder_pct,
  ROUND((EXP(SUM(LN(1 + IFNULL(r_actual, 0)))) - 1) * 100, 4) AS actual_pct,
  ROUND((EXP(SUM(LN(1 + IFNULL(r_risk,   0)))) - 1) * 100, 4) AS never_switch_pct,
  ROUND(((EXP(SUM(LN(1 + IFNULL(r_ladder, 0)))) - 1)
       - (EXP(SUM(LN(1 + IFNULL(r_actual, 0)))) - 1)) * 100, 4) AS ladder_edge_vs_actual_pp,
  ROUND(((EXP(SUM(LN(1 + IFNULL(r_ladder, 0)))) - 1)
       - (EXP(SUM(LN(1 + IFNULL(r_risk,   0)))) - 1)) * 100, 4) AS ladder_edge_vs_never_pp
FROM runs
WHERE engaged
GROUP BY grp;

-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_reevaluation_due` AS
WITH cfg AS (
  -- Activation date and threshold are PINNED here, not computed, so the countdown cannot drift.
  -- Owner directive 2026-09-04: execute now, forward-test, re-evaluate after 2-3 more episodes.
  SELECT DATE '2026-09-04' AS activation_date, 3 AS episodes_required
),
eps AS (
  SELECT e.*
  FROM `stock-trading-498512.analytics.park_episode_log` e, cfg
  -- Strict > : an episode already underway at activation is NOT a forward-test observation.
  WHERE e.episode_start > cfg.activation_date
)
SELECT
  cfg.activation_date,
  cfg.episodes_required,
  (SELECT COUNT(*) FROM eps)                                        AS episodes_since_activation,
  (SELECT COUNT(*) FROM eps) >= cfg.episodes_required               AS due,
  (SELECT MAX(episode_end) FROM eps)                                AS latest_episode_end,
  (SELECT ROUND(AVG(ladder_edge_vs_actual_pp), 4) FROM eps)         AS mean_edge_vs_actual_pp,
  (SELECT ROUND(AVG(ladder_edge_vs_never_pp), 4)  FROM eps)         AS mean_edge_vs_never_pp,
  (SELECT COUNTIF(ladder_edge_vs_actual_pp > 0) FROM eps)           AS episodes_ladder_beat_actual
FROM cfg;

-- Post-condition: the countdown starts at zero on activation day and is not already due.
ASSERT (
  SELECT episodes_since_activation = 0 AND NOT due
  FROM `stock-trading-498512.state.park_reevaluation_due`
) AS '221: the forward-test countdown must start at zero episodes on activation day.';

-- ============================ ACTIVATION MARKER (Phase 3 go-live) ==============================
-- Writing this row flips state.park_policy_current.graded_enabled to TRUE, which is what permits D2
-- to convert a target_f_pct outside {0,100}. It is a POLICY-TABLE row rather than a control table on
-- purpose: the owner retired ops.park_control on 2026-07-26 ("human would never do this manually.
-- remove this feature"), so no new control surface is introduced here. It carries the CURRENT policy
-- verbatim (VOO, f=0) so it is a pure no-op on the book — it changes what is PERMITTED, never what is
-- HELD, and state.park_policy_current still resolves to exactly the same allocation afterwards.
-- Guarded so a DR replay does not write a second marker.
IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.park_policy_changes`
  WHERE note LIKE 'PARK-V4-SCHEMA-VERSION%'
) THEN
  INSERT INTO `stock-trading-498512.events.park_policy_changes`
    (effective_date, vehicle, note, target_f_pct, risk_sleeve, defensive_sleeve)
  SELECT
    p.effective_date, p.vehicle,
    'PARK-V4-SCHEMA-VERSION v4.0 (2026-09-04) — graded two-sleeve allocation ACTIVATED on live idle '
    || 'capital by owner directive. This row is a NO-OP on the book: it restates the policy in force '
    || '(vehicle ' || p.vehicle || ', target_f_pct ' || CAST(p.target_f_pct AS STRING) || ', risk '
    || p.risk_sleeve || ' / defensive ' || p.defensive_sleeve || ') and exists only to flip '
    || 'state.park_policy_current.graded_enabled, which is the mechanical Phase-2 pin D2 reads before '
    || 'converting any target_f_pct outside {0,100}. Activated against a measured record that does '
    || 'NOT flatter the design and was shown to the owner first: across 15 historical episodes the '
    || 'defensive signal had mean FORWARD edge -0.638pp (SD 1.308) and won only 4 of 15, and across '
    || 'the three shadow episodes the ladder beat the binary path every time (+1.62/+1.56/+0.84pp) '
    || 'while trailing never-switching every time (-1.09/-0.91/-0.63pp). The owner accepted that '
    || 'grading beats the all-or-nothing switch while de-risking at all still costs against holding '
    || 'VOO, and chose to run it forward. W5 PARK FORWARD-TEST COUNTDOWN '
    || '(state.park_reevaluation_due) forces re-evaluation after 3 post-activation episodes.',
    p.target_f_pct, p.risk_sleeve, p.defensive_sleeve
  FROM `stock-trading-498512.state.park_policy_current` p;
END IF;

-- Post-conditions: the marker flips the pin, and it did NOT move the book.
ASSERT (
  SELECT graded_enabled FROM `stock-trading-498512.state.park_policy_current`
) AS '221: graded_enabled must be TRUE after the activation marker lands.';

ASSERT (
  SELECT target_f_pct = 0 AND vehicle = 'VOO'
  FROM `stock-trading-498512.state.park_policy_current`
) AS '221: the activation marker must be a NO-OP on the book (policy still VOO at f=0).';

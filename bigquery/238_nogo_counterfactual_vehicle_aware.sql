-- 238_nogo_counterfactual_vehicle_aware.sql (2026-09-13) — NO-GO counterfactual: score against the
-- PARK THE CAPITAL WAS ACTUALLY IN, not a hardcoded SGOV ticker.
-- Project: stock-trading-498512. Supersedes the analytics.nogo_counterfactual and
-- analytics.nogo_counterfactual_by_primary definitions in
-- bigquery/152_nogo_counterfactual_asof_and_primary_grouping.sql. Apply after bigquery/152 and after
-- bigquery/93_park_accounting.sql (canonical analytics.park_nav_daily, the benchmark source this file
-- introduces). analytics.nogo_counterfactual_summary (bigquery/28_nogo_shadow.sql, raw-sub_pattern grain)
-- is NOT redefined here and is deliberately left untouched — but note it reads
-- would_nogo_have_been_correct_long_framing from the view below, so it inherits the corrected benchmark
-- automatically. That is intended: there must not be two live scorings of the same rows.
--
-- REGISTRY / PORT NOTES. Neither object is in the bigquery/63 scheduled-query version registry (both are
-- plain views read by the W5 routine), so no registry MERGE accompanies this file. bigquery/152's header
-- also recorded "There is no dbt model for either object" — THAT IS NOW STALE and must not be carried
-- forward: the 2026-09-01 dbt view-coverage burn-down added dbt/models/analytics/nogo_counterfactual.sql,
-- nogo_counterfactual_by_primary.sql and nogo_counterfactual_summary.sql, and
-- scripts/check_dbt_view_coverage.py + scripts/dbt_parity.py are blocking in ci.yml. Both ports are
-- regenerated from the bodies below in the same commit via scripts/gen_dbt_port.py and re-proved with
-- scripts/verify_dbt_port.py.
--
-- ================================ WHY THIS EXISTS ================================
-- Raised by W5 2026-09-06 as ops.alerts `nogo_counterfactual_benchmark_stale` and as the warning block at
-- the top of B_Sub_Pattern_Taxonomy.md; W5 2026-09-13 is the fix. bigquery/152's benchmark CTE is
-- `WHERE ticker = 'SGOV'`, and its own comments call it "the SGOV park". **SGOV stopped being the shared
-- idle-capital park vehicle on 2026-07-15** (owner Rev 38; Operating_Protocols.md §13), and since the v4
-- graded ladder went live on capital 2026-09-04 the park is not even a single ticker — it is a VOO/SGOV
-- blend at a target fraction f that moves (f=0 on 09-03, 25 on 09-08, 50 on 09-10). A hardcoded ticker
-- cannot express that and will go wrong again on the next vehicle change.
--
-- The counterfactual asks one question: the money we did NOT put into the declined name sat in the park —
-- did declining beat that? So the hurdle is the PARK'S OWN REALIZED RETURN over the same window. That
-- series already exists and is already vehicle- and blend-aware, because it is computed from real fills:
-- analytics.park_nav_daily.twr_index (bigquery/93_park_accounting.sql), the same object
-- analytics.park_counterfactuals reads as its `ai_index` ground-truth leg. This file simply uses it,
-- rather than reconstructing a blend from events.park_policy_changes — the reconstruction would be a
-- second, independently-driftable model of a number the system already measures.
--
-- ---------------------------- MEASURED IMPACT (2026-09-13, all 40 closed rows) ----------------------
-- Re-scoring every row against the actual park changes TWO rows, in OPPOSITE directions, and both by
-- less than half a percentage point:
--   IONS  (PatternN [overlay: SP5], 07-12 -> 08-03): ticker -0.33%, park -0.724% => excess +0.394pp,
--         correct -> INCORRECT.
--   GLW   (SP6-negative [overlay: PatternN], 07-28 -> 08-30): ticker +1.03%, park +1.144% =>
--         excess -0.117pp, incorrect -> CORRECT.
-- Per-token, closed-out (vs SGOV -> vs PARK): SP4 5/17 -> 5/17 (unchanged), SP1 3/9 -> 3/9 (unchanged),
-- PatternN 4/7 -> 3/7, SP6 1/4 -> 2/4, SP10 1/2 -> 1/2, SP5 0/1 -> 0/1. Mean park return across the
-- closed windows is ~1.0-1.6% against SGOV's ~0.03%.
--
-- **THIS REFUTES THE SIZE OF THE EFFECT W5 2026-09-06 PREDICTED, AND THE CORRECTION MATTERS MORE THAN THE
-- REPAIR.** That cycle re-scored against a PURE-VOO leg (~3.0% over the same windows) and reported six
-- one-directional flips with SP4 moving 5/17 -> 8/17, "from clearly below chance to essentially at
-- chance". Pure VOO was the wrong counterfactual: the park was SGOV for most of the July cohort's
-- windows, switched to VOO only on 2026-08-03, and switched back for 09-01..09-03. Against the vehicle
-- the capital was ACTUALLY in, SP4 and SP1 do not move at all. So the benchmark defect was real and is
-- fixed here, but it was NOT masking SP4's below-chance reading — that reading survives the repair, and a
-- future cycle must not cite the superseded "benchmark artifact" framing as a reason to discount it.
-- PatternN's 2026-08-30 sign change does not survive: at 3/7 it is back below chance on 7 observations.
--
-- ---------------------------- WHAT IS AND IS NOT CHANGED ----------------------------
-- CHANGED: would_nogo_have_been_correct_long_framing now tests excess_return_vs_park. Repointing the
--   EXISTING column (rather than adding a parallel one and leaving the old one live) is deliberate:
--   analytics.nogo_counterfactual_summary reads it, and two simultaneously-live scorings of the same rows
--   is precisely the "the file must not fork from the view" hazard the taxonomy warning block named.
-- ADDED:   park_ref_index / park_forward_index / park_ref_date / park_forward_date / park_forward_return /
--   excess_return_vs_park, and would_nogo_have_been_correct_vs_sgov — the legacy reading, kept queryable
--   by name so the published SGOV-scored tallies in B_Sub_Pattern_Taxonomy.md remain reproducible and the
--   delta above stays auditable rather than being asserted in a comment.
-- KEPT AS-IS: every bigquery/152 column, including sgov_ref_price / sgov_forward_price / sgov_ref_date /
--   sgov_forward_date / sgov_forward_return / excess_return_vs_sgov. Nothing is dropped or renamed, so no
--   downstream consumer breaks.
-- KEPT AS-IS, deliberately: the AS-OF join shape (bigquery/152 DEFECT 1) — the park leg uses the identical
--   most-recent-on-or-before rule, and needs it for the same reason plus one more: analytics.park_nav_daily
--   legitimately has no row on Fridays and Saturdays since the 2026-08-08 daily_sun_thu consolidation, so
--   an exact-date join would silently NULL those rows exactly as the SGOV leg once did. Also kept: the
--   entry_ref_price anchor convention (price at W5 logging time, not at the decision date) — a real
--   measurement weakness shared by all 40 rows, and re-anchoring one cycle would make the series
--   incomparable with itself.
--
-- The N>=20 self-apply gate in W5's taxonomy-demotion bullet reads
-- analytics.nogo_counterfactual_by_primary. As of this file it reads a correctly-benchmarked tally, which
-- is the precondition the taxonomy warning block set for letting that gate fire at all.

-- ===== analytics.nogo_counterfactual — per-shadow-row excess return vs the REALIZED PARK =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual` AS
WITH sgov AS (
  SELECT mark_date, close FROM `stock-trading-498512.state.daily_marks_curated` WHERE ticker = 'SGOV'
),
-- The park's own realized chained TWR index, already vehicle- and blend-aware because it is computed from
-- actual park fills. This is the benchmark; the SGOV legs below survive only as the legacy reading.
park AS (
  SELECT as_of_date, twr_index FROM `stock-trading-498512.analytics.park_nav_daily`
),
shadow AS (
  SELECT * FROM `stock-trading-498512.events.nogo_shadow`
),
-- AS-OF reference leg: most recent SGOV mark on or before nogo_date. A shadow row whose nogo_date falls
-- on a weekend or market holiday resolves to the prior trading day's mark instead of NULL.
sgov_entry AS (
  SELECT s.event_id, g.close AS sgov_close, g.mark_date AS sgov_mark_date
  FROM shadow s
  JOIN sgov g ON g.mark_date <= s.nogo_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.event_id ORDER BY g.mark_date DESC) = 1
),
-- AS-OF forward leg: same rule against forward_price_date. Still NULL for an un-closed row, because the
-- `g.mark_date <= NULL` predicate matches nothing — an open shadow row must not score.
sgov_fwd AS (
  SELECT s.event_id, g.close AS sgov_close, g.mark_date AS sgov_mark_date
  FROM shadow s
  JOIN sgov g ON g.mark_date <= s.forward_price_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.event_id ORDER BY g.mark_date DESC) = 1
),
-- Park legs, same AS-OF rule for the same two reasons: non-trading nogo_date / forward_price_date, and
-- the Friday/Saturday holes the daily_sun_thu cadence leaves in analytics.park_nav_daily.
park_entry AS (
  SELECT s.event_id, p.twr_index AS park_index, p.as_of_date AS park_date
  FROM shadow s
  JOIN park p ON p.as_of_date <= s.nogo_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.event_id ORDER BY p.as_of_date DESC) = 1
),
park_fwd AS (
  SELECT s.event_id, p.twr_index AS park_index, p.as_of_date AS park_date
  FROM shadow s
  JOIN park p ON p.as_of_date <= s.forward_price_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.event_id ORDER BY p.as_of_date DESC) = 1
)
SELECT
  s.event_id, s.decision_log_entry_id, s.ticker, s.sub_pattern, s.nogo_date, s.horizon_days,
  s.entry_ref_price, s.forward_price, s.forward_price_date,
  s.forward_price IS NOT NULL AS closed_out,
  -- Primary token per B_Sub_Pattern_Taxonomy.md's canonical grouping regex, widened to tolerate the
  -- `Pattern N` with-space spelling. NULL sub_pattern and any unrecognised prefix fall through as NULL.
  REGEXP_REPLACE(
    REGEXP_EXTRACT(s.sub_pattern, r'^(SP[0-9]+|Pattern ?N|Mechanical)'), r'\s+', ''
  ) AS sub_pattern_primary,
  sgov_entry.sgov_close AS sgov_ref_price,
  sgov_fwd.sgov_close AS sgov_forward_price,
  -- Exposed so the as-of resolution is auditable: a large gap between these and nogo_date /
  -- forward_price_date means a long market closure, not a silent mis-join.
  sgov_entry.sgov_mark_date AS sgov_ref_date,
  sgov_fwd.sgov_mark_date AS sgov_forward_date,
  park_entry.park_index AS park_ref_index,
  park_fwd.park_index AS park_forward_index,
  park_entry.park_date AS park_ref_date,
  park_fwd.park_date AS park_forward_date,
  SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1 AS ticker_forward_return,
  SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1 AS sgov_forward_return,
  -- twr_index is a CUMULATIVE return anchored at park inception, so the window return is the ratio of the
  -- two wealth relatives, not the difference of the two index levels.
  SAFE_DIVIDE(1 + park_fwd.park_index, 1 + park_entry.park_index) - 1 AS park_forward_return,
  (SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1) AS excess_return_vs_sgov,
  (SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(1 + park_fwd.park_index, 1 + park_entry.park_index) - 1) AS excess_return_vs_park,
  -- B is long-biased by construction (Strategy.md) -- for the dominant long-framed NO-GO, avoiding a name
  -- that then underperformed the park the capital actually sat in (excess <= 0) means the avoidance was
  -- directionally correct. A short-framed NO-GO would invert this reading; sub_pattern/note should flag
  -- that case for manual re-interpretation rather than trusting this column blindly.
  ((SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(1 + park_fwd.park_index, 1 + park_entry.park_index) - 1)) <= 0
    AS would_nogo_have_been_correct_long_framing,
  -- The legacy SGOV-benchmarked reading, kept by name so the tallies already published in
  -- B_Sub_Pattern_Taxonomy.md stay reproducible and the benchmark delta stays measurable.
  ((SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1)) <= 0
    AS would_nogo_have_been_correct_vs_sgov
FROM shadow s
LEFT JOIN sgov_entry ON sgov_entry.event_id = s.event_id
LEFT JOIN sgov_fwd ON sgov_fwd.event_id = s.event_id
LEFT JOIN park_entry ON park_entry.event_id = s.event_id
LEFT JOIN park_fwd ON park_fwd.event_id = s.event_id;

-- ===== analytics.nogo_counterfactual_by_primary — same tally at the DOCUMENTED primary-token grain =====
-- Additive sibling of analytics.nogo_counterfactual_summary (which stays at the raw decorated-string
-- grain). This is the view W5's taxonomy-demotion bullet reads for min_n_met: the >=5-closed-out floor is
-- reachable here and is not at the raw grain. Still a raw tally, never a rate to act on at low N -- the
-- N-floor caveat in the W5 prompt body, and the N>=20 self-apply bar pinned by W5 2026-08-30, govern
-- unchanged.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual_by_primary` AS
SELECT
  COALESCE(sub_pattern_primary, '(unclassified)') AS sub_pattern_primary,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Guards against the exact silent-zero that hid bigquery/152's DEFECT 1: a closed row whose excess
  -- return could not be computed is counted here rather than vanishing between n_correct and n_incorrect.
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NULL) AS n_closed_unscored,
  -- Legacy SGOV-benchmarked counts, carried alongside so a reader can see exactly how much of any tally
  -- is attributable to the 2026-09-13 benchmark correction rather than to new evidence.
  COUNTIF(closed_out AND would_nogo_have_been_correct_vs_sgov) AS n_correct_vs_sgov,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_vs_sgov) AS n_incorrect_vs_sgov,
  (COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NOT NULL) >= 5) AS min_n_met
FROM `stock-trading-498512.analytics.nogo_counterfactual`
GROUP BY sub_pattern_primary
ORDER BY n_shadowed DESC;

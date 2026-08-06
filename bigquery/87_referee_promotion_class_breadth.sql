-- Referee promotion: single-review-type evidence must not clear the bar (2026-07-18 audit).
-- Project: stock-trading-498512. Apply after 84_referee_promotion.sql, whose
-- state.referee_promotion_readiness definition this SUPERSEDES (86 is the highest-numbered file at
-- time of writing in this branch; a concurrently-landing 85 does not touch these objects).
--
-- PROBLEM: bigquery/84's three declared bars (quarter_elapsed, sample_floor_met n_scored>=6,
-- concurrence_met >=0.80) are all computed over analytics.referee_concurrence_calibration's pooled
-- '__ALL__' rollup. The referee's scored set is dominated by 'divergence-review' (the only class
-- with historical volume — DEF-5 Part 1 widened scoring to it precisely because the other classes
-- were empty; SL4's first retirement proposal cannot exist before ~2027-04 and foundation-change
-- assessments are rare). So the promotion bar would inevitably first be met using evidence drawn
-- ENTIRELY from divergence-review — a reversible, activation-level class — yet the promotion folds
-- referee_concurs into state.strategy_adoption_readiness / strategy_retirement_readiness /
-- foundation_change_termination_readiness as a fail-closed AND-term, i.e. it starts gating three
-- UNRELATED, irreversible decision classes on which the referee has zero observed track record.
--
-- FIX (conservative, evidence-widening — NOT a human gate; SISA autonomy posture unchanged, see
-- CLAUDE.md "Settled decisions"): a fourth declared bar, class_breadth_met — the calibration must
-- show >= 2 DISTINCT review_types each with n_scored >= 2 (excluding the '__ALL__' rollup row)
-- before ready_for_promotion can go TRUE. Cross-class generalization then rests on at least two
-- observed classes rather than one. Realistic satisfaction path: divergence-review (ongoing) plus
-- strategy-adoption (SL1's next adoption attempt — quarterly cadence), i.e. reachable within a
-- couple of quarters, unlike requiring the rare classes themselves. The bar is declared and
-- adjustable by a future evidence-cited edit, exactly like 84's other three.
--
-- Everything else — the 90-day event_ts clock, the >=6 pooled sample floor, the 0.80 concurrence
-- threshold, the loop_promotion_log single-shot guard, fail-closed-on-empty — is copied verbatim
-- from bigquery/84. INERT ON APPLY: referee_rows=0 today, every bar already FALSE.

-- SUPERSEDED LIVE by bigquery/143_adversarial_review_correction_path.sql — that file is the current
-- single source of truth for state.referee_promotion_readiness. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation: first_ref
-- below reads events.adversarial_reviews directly, so it would count a superseded correction target.
-- Every threshold and all five bars are unchanged in 143.
CREATE OR REPLACE VIEW `stock-trading-498512.state.referee_promotion_readiness` AS
WITH first_ref AS (
  -- MIN(event_ts) = the actual INSERTION time of the earliest referee_gemini row, deliberately NOT its
  -- review_date (bigquery/44 backdates review_date to the original attacker submission; keying the
  -- 90-day burn-in on it would satisfy the quarter clock retroactively — see bigquery/84's note).
  SELECT MIN(event_ts) AS first_referee_ts, COUNT(*) AS referee_rows
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE role = 'referee_gemini'
),
concur_rollup AS (
  SELECT COALESCE(n_scored, 0) AS n_scored, concurrence_rate
  FROM `stock-trading-498512.analytics.referee_concurrence_calibration`
  WHERE review_type = '__ALL__'
),
class_breadth AS (
  -- Distinct review_types with a non-trivial per-class sample (n_scored >= 2). Empty calibration
  -- => COUNT(*)=0 => the bar stays FALSE — fail-closed, same as every other bar here.
  SELECT COUNT(*) AS n_types_with_evidence
  FROM `stock-trading-498512.analytics.referee_concurrence_calibration`
  WHERE review_type != '__ALL__' AND n_scored >= 2
)
SELECT
  fr.first_referee_ts,
  fr.referee_rows,
  r.n_scored,
  r.concurrence_rate,
  cb.n_types_with_evidence,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) AS days_since_first_referee,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90) AS quarter_elapsed,
  (r.n_scored >= 6) AS sample_floor_met,
  (COALESCE(r.concurrence_rate, 0.0) >= 0.80) AS concurrence_met,
  (cb.n_types_with_evidence >= 2) AS class_breadth_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
              WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90
   AND r.n_scored >= 6
   AND COALESCE(r.concurrence_rate, 0.0) >= 0.80
   AND cb.n_types_with_evidence >= 2
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
                   WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM first_ref fr CROSS JOIN concur_rollup r CROSS JOIN class_breadth cb;
-- Returns exactly one row. ready_for_promotion stays FALSE until (a) >=90 days of observed referee
-- scoring, (b) >=6 paired scored reviews pooled, (c) pooled concurrence_rate >=0.80, AND
-- (d) >=2 distinct review_types each with >=2 scored pairs — AND no
-- cross_model_referee_independence->active_auto row exists in ops.loop_promotion_log (single-shot).

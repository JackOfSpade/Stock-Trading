-- 152_nogo_counterfactual_asof_and_primary_grouping.sql (2026-08-09)
-- Project: stock-trading-498512. Repairs the NO-GO counterfactual shadow-tracking loop (self-improvement
-- audit S-3), which has been live since 2026-07-19 and has produced ZERO scored observations across every
-- closed-out row. Two independent defects, both found by W5 2026-W33 while reading
-- analytics.nogo_counterfactual_summary for its weekly taxonomy-demotion check.
-- Apply after bigquery/28_nogo_shadow.sql (the file whose analytics.nogo_counterfactual definition this
-- supersedes) and bigquery/03_twr_engine.sql + bigquery/53_curated_view_tiebreak_fix.sql (canonical
-- state.daily_marks_curated, the SGOV mark source both statements read).
--
-- REGISTRY NOTE: neither object below is in the bigquery/63 scheduled-query version registry (they are
-- plain views, read by the W5 routine, not by any scheduled query), so no registry MERGE accompanies this
-- file. There is no dbt model for either object (verified: zero hits for `nogo_counterfactual` under
-- dbt/), so scripts/dbt_parity.py does not cover them and nothing under dbt/ needs mirroring.
--
-- ============================ DEFECT 1 — exact-date SGOV join (STATEMENT 1) ============================
-- MEASURED 2026-08-09: all 5 closed-out rows in events.nogo_shadow carry sgov_ref_price = NULL while
-- sgov_forward_price is populated (100.42). The cause is the join, not the data: bigquery/28 joins the
-- SGOV mark on `sgov_entry.mark_date = s.nogo_date` — an EXACT-date equality against
-- state.daily_marks_curated, which holds trading-day rows only (verified live: EXTRACT(DAYOFWEEK) over
-- recent SGOV rows returns 2..6 exclusively; it is a latest-wins dedup over events.daily_marks with no
-- calendar fill-forward). All 5 closed rows share nogo_date 2026-07-12, a SUNDAY, so the reference leg
-- resolves to no row at all.
--
-- A NULL sgov_ref_price NULLs sgov_forward_return, which NULLs excess_return_vs_sgov, which NULLs
-- would_nogo_have_been_correct_long_framing. nogo_counterfactual_summary then counts that row in NEITHER
-- n_correct NOR n_incorrect, because `COUNTIF(closed_out AND x)` and `COUNTIF(closed_out AND NOT x)` are
-- BOTH false when x IS NULL. The loop therefore reports n_closed_out = 5 alongside n_correct = 0 and
-- n_incorrect = 0 — a reading that looks like "scored, no signal yet" but is actually "never scored".
-- That silent-zero is why this survived three W5 cycles unnoticed.
--
-- The FORWARD leg has the identical flaw and is fixed in the same statement: W5's close-out step stamps
-- forward_price_date = CURRENT_DATE('America/Denver'), and W5 runs on SUNDAYS. The 2026-08-03 close-out
-- batch only resolved because that W5 ran on a Monday; this cycle (2026-08-09, a Sunday) would have
-- written a second unscoreable cohort. Fixing only the reference leg would have masked that.
--
-- FIX: both legs become AS-OF joins — the most recent SGOV mark on or before the target date. The
-- resolved mark dates are now EXPOSED as sgov_ref_date / sgov_forward_date so the as-of resolution is
-- auditable from the view itself rather than being an invisible assumption. Semantics are unchanged on
-- any row that already resolved (an exact match is trivially its own most-recent-on-or-before).
--
-- ============================ DEFECT 2 — grouping key over-specified (STATEMENT 2) ====================
-- MEASURED 2026-08-09: 37 shadow rows carry 33 DISTINCT raw sub_pattern strings but only 13 distinct
-- PRIMARY tokens, because the controlled vocabulary decorates the primary with variant letters, a
-- ` (candidate)` suffix and ` [overlay: ...]` composites (B_Sub_Pattern_Taxonomy.md, "Sub_pattern
-- canonical vocabulary"). nogo_counterfactual_summary groups on the RAW string, so almost every bucket
-- has n=1 and its `COUNTIF(closed_out) >= 5` min_n floor is not merely unmet — it is STRUCTURALLY
-- UNREACHABLE. W5's taxonomy-demotion bullet gates on exactly that flag, so that branch could never fire.
--
-- This is not a judgement call about the right granularity: B_Sub_Pattern_Taxonomy.md already documents
-- the canonical primary-token grouping verbatim — "To group by primary pattern:
-- REGEXP_EXTRACT(sub_pattern, r'^(SP[0-9]+|PatternN|Mechanical)')". The summary view simply never applied
-- it. STATEMENT 2 adds a SIBLING view at that documented granularity and DELIBERATELY LEAVES
-- nogo_counterfactual_summary untouched, so no existing consumer's semantics change and the fine-grained
-- raw tally stays available; the new view is purely additive.
--
-- The regex is widened by one character versus the taxonomy's text — `Pattern ?N` rather than `PatternN`
-- — to absorb the `Pattern N` (with-space) spelling that drifted into 2 decision_log rows and 2
-- nogo_shadow rows. W5 2026-W33 conformed those 4 rows in place under the RUNBOOK §21 sub_pattern
-- exception in the same session, so the tolerance is belt-and-braces against recurrence, not a
-- workaround for live bad data.
--
-- NOT CHANGED, deliberately: the entry_ref_price ANCHOR. W5's spec fetches "the ticker's current price"
-- at logging time, so a NO-GO dated mid-week gets an anchor from the following Friday's close (CTRI:
-- NO-GO 2026-08-04 at 21.88, anchored 2026-08-07 at 23.85). That lag is a real measurement weakness, but
-- it is a SPEC convention shared by all 37 existing rows, and silently re-anchoring one cycle's rows
-- would make the series incomparable with itself. Recorded as an observation for a future spec change;
-- not touched here.

-- ===== analytics.nogo_counterfactual — per-shadow-row excess return vs SGOV, as-of SGOV legs =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual` AS
WITH sgov AS (
  SELECT mark_date, close FROM `stock-trading-498512.state.daily_marks_curated` WHERE ticker = 'SGOV'
),
shadow AS (
  SELECT * FROM `stock-trading-498512.events.nogo_shadow`
),
-- AS-OF reference leg: most recent SGOV mark on or before nogo_date. A shadow row whose nogo_date falls
-- on a weekend or market holiday now resolves to the prior trading day's mark instead of NULL.
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
  SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1 AS ticker_forward_return,
  SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1 AS sgov_forward_return,
  (SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1) AS excess_return_vs_sgov,
  -- B is long-biased by construction (Strategy.md) -- for the dominant long-framed NO-GO, avoiding a
  -- name that then underperformed the SGOV park (excess <= 0) means the avoidance was directionally
  -- correct. A short-framed NO-GO would invert this reading; sub_pattern/note should flag that case for
  -- manual re-interpretation rather than trusting this column blindly.
  ((SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.sgov_close, sgov_entry.sgov_close) - 1)) <= 0
    AS would_nogo_have_been_correct_long_framing
FROM shadow s
LEFT JOIN sgov_entry ON sgov_entry.event_id = s.event_id
LEFT JOIN sgov_fwd ON sgov_fwd.event_id = s.event_id;

-- ===== analytics.nogo_counterfactual_by_primary — same tally at the DOCUMENTED primary-token grain =====
-- Additive sibling of analytics.nogo_counterfactual_summary (which is deliberately left as-is, at the raw
-- decorated-string grain). This is the view W5's taxonomy-demotion bullet should read for min_n_met: the
-- >=5-closed-out floor is reachable here and is not at the raw grain. Still a raw tally, never a rate to
-- act on at low N -- the N-floor caveat in the W5 prompt body governs unchanged.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual_by_primary` AS
SELECT
  COALESCE(sub_pattern_primary, '(unclassified)') AS sub_pattern_primary,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Guards against the exact silent-zero that hid DEFECT 1: a closed row whose excess return could not be
  -- computed is counted here rather than vanishing between n_correct and n_incorrect.
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NULL) AS n_closed_unscored,
  (COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NOT NULL) >= 5) AS min_n_met
FROM `stock-trading-498512.analytics.nogo_counterfactual`
GROUP BY sub_pattern_primary
ORDER BY n_shadowed DESC;

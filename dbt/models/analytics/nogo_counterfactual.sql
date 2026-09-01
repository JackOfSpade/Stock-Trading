-- Parallel-run dbt port of bigquery/152_nogo_counterfactual_asof_and_primary_grouping.sql:analytics.nogo_counterfactual — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH sgov AS (
  SELECT mark_date, close FROM {{ ref('daily_marks_curated') }} WHERE ticker = 'SGOV'
),
shadow AS (
  SELECT * FROM {{ source('events', 'nogo_shadow') }}
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
LEFT JOIN sgov_fwd ON sgov_fwd.event_id = s.event_id

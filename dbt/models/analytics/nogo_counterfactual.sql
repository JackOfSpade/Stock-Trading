-- Parallel-run dbt port of bigquery/238_nogo_counterfactual_vehicle_aware.sql:analytics.nogo_counterfactual — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH sgov AS (
  SELECT mark_date, close FROM {{ ref('daily_marks_curated') }} WHERE ticker = 'SGOV'
),
-- The park's own realized chained TWR index, already vehicle- and blend-aware because it is computed from
-- actual park fills. This is the benchmark; the SGOV legs below survive only as the legacy reading.
park AS (
  SELECT as_of_date, twr_index FROM {{ ref('park_nav_daily') }}
),
shadow AS (
  SELECT * FROM {{ source('events', 'nogo_shadow') }}
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
LEFT JOIN park_fwd ON park_fwd.event_id = s.event_id

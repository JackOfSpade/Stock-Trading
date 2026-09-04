-- Parallel-run dbt port of bigquery/221_park_episode_log_and_reevaluation.sql:state.park_reevaluation_due — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH cfg AS (
  -- Activation date and threshold are PINNED here, not computed, so the countdown cannot drift.
  -- Owner directive 2026-09-04: execute now, forward-test, re-evaluate after 2-3 more episodes.
  SELECT DATE '2026-09-04' AS activation_date, 3 AS episodes_required
),
eps AS (
  SELECT e.*
  FROM {{ ref('park_episode_log') }} e, cfg
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
FROM cfg

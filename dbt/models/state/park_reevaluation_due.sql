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
  -- SELF-TERMINATING. Without the second conjunct this flag is MONOTONE — cfg is pinned literals and
  -- the episode count never falls — so W5 would re-raise the identical warning every week FOREVER
  -- after the owner had already answered it. sp_raise_alert_once dedupes only on an UNRESOLVED row,
  -- so resolving it simply licences the next raise. The closure path is therefore made machine-
  -- readable here rather than left to prose: once a park-ladder-reevaluation decision has been
  -- recorded after activation, the reminder has served its purpose and stops.
  (SELECT COUNT(*) FROM eps) >= cfg.episodes_required
    AND NOT (SELECT COUNT(*) > 0
             FROM {{ source('state_external', 'decision_log_current') }}
             WHERE entry_type = 'park-ladder-reevaluation'
               AND entry_date >= cfg.activation_date)                AS due,
  (SELECT COUNT(*) > 0
   FROM {{ source('state_external', 'decision_log_current') }}
   WHERE entry_type = 'park-ladder-reevaluation'
     AND entry_date >= cfg.activation_date)                          AS already_reevaluated,
  (SELECT MAX(episode_end) FROM eps)                                AS latest_episode_end,
  (SELECT ROUND(AVG(ladder_edge_vs_actual_pp), 4) FROM eps)         AS mean_edge_vs_actual_pp,
  (SELECT ROUND(AVG(ladder_edge_vs_never_pp), 4)  FROM eps)         AS mean_edge_vs_never_pp,
  (SELECT COUNTIF(ladder_edge_vs_actual_pp > 0) FROM eps)           AS episodes_ladder_beat_actual,
  (SELECT ROUND(AVG(ladder_edge_vs_binary_pp), 4) FROM eps)        AS mean_edge_vs_binary_pp,
  (SELECT COUNTIF(ladder_edge_vs_binary_pp > 0) FROM eps)          AS episodes_ladder_beat_binary
FROM cfg

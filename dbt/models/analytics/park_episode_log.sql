-- Parallel-run dbt port of bigquery/221_park_episode_log_and_reevaluation.sql:analytics.park_episode_log — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH s AS (
  SELECT as_of_date, f_prev_pct, r_ladder, r_actual, r_binary, r_risk, r_def,
         standing_defensive_count, confirmed_cap_pct, conviction_pct
  FROM {{ ref('park_ladder_shadow') }}
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
       - (EXP(SUM(LN(1 + IFNULL(r_risk,   0)))) - 1)) * 100, 4) AS ladder_edge_vs_never_pp,
  -- THE DECISION-RELEVANT CRITERION once the book follows the ladder. ladder_edge_vs_actual_pp goes
  -- to ~0 then (shadow and book are the same thing, which is correct, not failure); this is the arm
  -- that keeps answering "does grading beat the all-or-nothing switch it replaced".
  ROUND((EXP(SUM(LN(1 + IFNULL(r_binary, 0)))) - 1) * 100, 4)    AS binary_pct,
  ROUND(((EXP(SUM(LN(1 + IFNULL(r_ladder, 0)))) - 1)
       - (EXP(SUM(LN(1 + IFNULL(r_binary, 0)))) - 1)) * 100, 4) AS ladder_edge_vs_binary_pp
FROM runs
WHERE engaged
GROUP BY grp

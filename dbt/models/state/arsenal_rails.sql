-- Parallel-run dbt port of bigquery/35_strategy_arsenal.sql:state.arsenal_rails — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH consts AS (
  SELECT
    2  AS n_min,                       -- roster floor (blocks SL4 below it; a hit forces SL1 generation)
    8  AS n_max,                       -- roster ceiling (~$10k account cost discipline)
    2  AS k_incubate,                  -- max concurrent SHADOW+PAPER strategies
    3  AS k_regime,                    -- regime-coverage target
    180 AS max_roundtrip_commission_bps, -- accepted probe-scale all-in round-trip ceiling (1.8%)
    90 AS adoption_rate_window_days,   -- <= 1 PROBE per rolling 90 days
    90 AS reject_cooldown_days,
    180 AS terminate_cooldown_days,
    90 AS keep_cooldown_days
),
counts AS (
  -- single scan of state.strategy_roster for both counts (rev 2026-07-10b, cleanup, code-review finding #9;
  -- was two separate correlated subqueries each re-evaluating the whole view).
  SELECT
    (SELECT AS STRUCT COUNTIF(is_active) AS active_count, COUNTIF(is_incubating) AS incubating_count
       FROM {{ source('state_external', 'strategy_roster') }}) AS roster,
    (SELECT COUNT(*) FROM {{ source('events', 'strategy_lifecycle') }}
       WHERE to_state = 'PROBE'
         AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS probes_in_window
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
FROM consts c CROSS JOIN counts n

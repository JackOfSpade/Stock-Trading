-- Parallel-run dbt port of bigquery/257_shock_transmission_register.sql:state.shock_transmission_status — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH register AS (
  -- Latest row per strategy code. A later re-registration (a new Strategy.md revision, or a newcomer's
  -- row re-authored before PROBE) appends; it never updates in place.
  SELECT *
  FROM {{ source('ops', 'shock_transmission_register') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code
                             ORDER BY effective_date DESC, registered_ts DESC) = 1
),
measurement AS (
  -- M2's latest published pair-correlation measurement. decision_log_current excludes superseded rows,
  -- so a corrected M2 row never wins over its correction. Dated by the measurement's own as-of, falling
  -- back to the row's entry_date when M2 omitted it.
  SELECT
    entry_id AS measurement_entry_id,
    COALESCE(SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(fields, '$.e_corr_as_of')), entry_date) AS measurement_as_of,
    SAFE_CAST(JSON_VALUE(fields, '$.e_corr_median_60d')       AS NUMERIC) AS e_corr_median_60d,
    SAFE_CAST(JSON_VALUE(fields, '$.e_corr_share_60d_ge_080') AS NUMERIC) AS e_corr_share_60d_ge_080,
    SAFE_CAST(JSON_VALUE(fields, '$.e_corr_population_n')     AS INT64)   AS e_corr_population_n
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE entry_type = 'research-screen'
    AND JSON_VALUE(fields, '$.screen') = 'pair-divergence'
    AND SAFE_CAST(JSON_VALUE(fields, '$.e_corr_median_60d') AS NUMERIC) IS NOT NULL
    AND SAFE_CAST(JSON_VALUE(fields, '$.e_corr_share_60d_ge_080') AS NUMERIC) IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (ORDER BY measurement_as_of DESC, event_ts DESC, entry_id DESC) = 1
),
today AS (
  SELECT today FROM {{ ref('trading_day_today') }}
),
evaluated AS (
  SELECT
    r.strategy_code,
    r.current_state,
    r.is_active,
    r.is_incubating,
    COALESCE(g.transmission_class, 'UNREGISTERED')          AS transmission_class,
    COALESCE(g.exempt_by_class, FALSE)                       AS exempt_by_class,
    g.horizon_class,
    g.rev                                                    AS register_rev,
    g.effective_date                                         AS register_effective_date,
    g.gate_median_60d_max,
    g.gate_share_ge_080_max,
    g.gate_max_age_days,
    (g.gate_median_60d_max IS NOT NULL
     OR g.gate_share_ge_080_max IS NOT NULL
     OR g.gate_max_age_days IS NOT NULL)                     AS gate_defined,
    m.measurement_entry_id,
    m.measurement_as_of,
    m.e_corr_median_60d,
    m.e_corr_share_60d_ge_080,
    m.e_corr_population_n,
    DATE_DIFF(t.today, m.measurement_as_of, DAY)             AS measurement_age_days,
    -- Each leg is NULL where it is not defined on the row, TRUE/FALSE where it is. A NULL measurement
    -- makes a defined leg FALSE (fail closed), never NULL.
    CASE WHEN g.gate_max_age_days IS NULL THEN NULL
         ELSE COALESCE(DATE_DIFF(t.today, m.measurement_as_of, DAY) <= g.gate_max_age_days, FALSE) END
                                                             AS measurement_fresh,
    CASE WHEN g.gate_median_60d_max IS NULL THEN NULL
         ELSE COALESCE(m.e_corr_median_60d < g.gate_median_60d_max, FALSE) END
                                                             AS leg_median_ok,
    CASE WHEN g.gate_share_ge_080_max IS NULL THEN NULL
         ELSE COALESCE(m.e_corr_share_60d_ge_080 < g.gate_share_ge_080_max, FALSE) END
                                                             AS leg_share_ok
  FROM {{ source('state_external', 'strategy_roster') }} r
  LEFT JOIN register g USING (strategy_code)
  CROSS JOIN today t
  LEFT JOIN measurement m ON TRUE
)
SELECT
  * EXCEPT (gate_defined),
  gate_defined,
  -- The breaker trips when any DEFINED leg fails. A gateless exempt row (SHOCK-NATIVE) never trips.
  gate_defined AND NOT (COALESCE(measurement_fresh, TRUE)
                        AND COALESCE(leg_median_ok, TRUE)
                        AND COALESCE(leg_share_ok, TRUE))    AS breaker_tripped,
  -- THE ONE COLUMN M1b READS. TRUE = apply the acute rule to this strategy's raw ACTIVATE exactly as
  -- before Rev 50. FALSE = the rule does not apply; the raw call stands as M1b made it.
  NOT (exempt_by_class
       AND NOT (gate_defined AND NOT (COALESCE(measurement_fresh, TRUE)
                                      AND COALESCE(leg_median_ok, TRUE)
                                      AND COALESCE(leg_share_ok, TRUE))))
                                                             AS override_applies,
  CASE
    WHEN transmission_class = 'UNREGISTERED' THEN 'binds: no register row (default)'
    WHEN NOT exempt_by_class THEN CONCAT('binds: class ', transmission_class)
    WHEN NOT gate_defined THEN CONCAT('exempt: class ', transmission_class, ', no gate')
    WHEN measurement_entry_id IS NULL THEN CONCAT('binds: class ', transmission_class, ', gate measurement absent')
    WHEN NOT COALESCE(measurement_fresh, TRUE) THEN CONCAT('binds: class ', transmission_class, ', gate measurement stale (', CAST(measurement_age_days AS STRING), 'd > ', CAST(gate_max_age_days AS STRING), 'd)')
    WHEN NOT COALESCE(leg_median_ok, TRUE) THEN CONCAT('binds: class ', transmission_class, ', breaker tripped on median 60d corr ', CAST(e_corr_median_60d AS STRING), ' >= ', CAST(gate_median_60d_max AS STRING))
    WHEN NOT COALESCE(leg_share_ok, TRUE) THEN CONCAT('binds: class ', transmission_class, ', breaker tripped on share >= 0.80 ', CAST(e_corr_share_60d_ge_080 AS STRING), ' >= ', CAST(gate_share_ge_080_max AS STRING))
    ELSE CONCAT('exempt: class ', transmission_class, ', gate clear (median ', CAST(e_corr_median_60d AS STRING), ', share>=0.80 ', CAST(e_corr_share_60d_ge_080 AS STRING), ', age ', CAST(measurement_age_days AS STRING), 'd)')
  END AS basis
FROM evaluated

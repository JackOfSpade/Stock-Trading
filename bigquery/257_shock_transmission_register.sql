-- ===== 257: ops.shock_transmission_register + state.shock_transmission_status -- the acute-shock override's per-strategy transmission term, measured =====
-- (Rev 50, owner directive 2026-10-19. Companion to the Strategy.md `## Regime router` -> M1a / M1b
-- reconciliation rules amendment and its `Shock Transmission Register` table landed in the same change.)
--
-- WHAT THIS IS FOR. Until Rev 50 the first reconciliation rule read "If M1a scores shock_overlay = acute
-- AND M1b returns ACTIVATE for any strategy -> override to DO-NOT-ACTIVATE", uniformly. ops.alerts
-- 18196168 (AR_orc, 2026-09-03, the div-*-202608-1 cohort) recorded that the rule carried no per-strategy
-- transmission term, otr-router-shock-override-2026 HELD it on 2026-09-09 without affirming the design,
-- and Quarterly_Regime.md's 2026-Q3 Flag 2 recorded that the acute-shock cell was therefore uncoverable
-- by any present or future roster member. Rev 50 makes the rule bind BY DEFAULT and lets a per-strategy
-- register exempt a strategy whose mechanism the shock is not transmitted into. This file is the
-- register's runtime mirror: the TABLE holds the rows (one per strategy, latest row per code wins) and
-- the VIEW evaluates them against M2's published pair-correlation measurement into one boolean per
-- strategy, `override_applies`, which M1b step 2 reads when it applies the rule.
--
-- THE TABLE IS A MIRROR OF PROSE, AND THE PROSE IS CANONICAL. Strategy.md's register table is the spec;
-- scripts/check_shock_register_lockstep.py (blocking CI) asserts that the seed rows below agree with it
-- column for column, so a row is changed in both places or in neither -- the roster.yaml <->
-- state.strategy_roster discipline, applied here. A newcomer's row is authored by SL2 with its candidate
-- section (default: binds) and inserted by SL5 at PROBE registration; the view treats a strategy with NO
-- row as UNREGISTERED and binds it. That is the default-REJECT posture every SISA gate carries.
--
-- WHY THE GATE IS A CIRCUIT-BREAKER AND NOT A MONTHLY TEST. The first draft of this amendment gated E's
-- exemption on "fewer than 50% of M2's pairs have 60d correlation above 252d". A read-only replay on
-- 2026-10-19 (Yahoo daily closes, validated to four decimals against M2's own 2026-10-01 per-pair table,
-- 64/64 agreement on the sign of 60d - 252d) showed that statistic reads 67-70% in the `latent` months of
-- June and July 2026, 69-70% inside the Gulf shock graded `acute` from 2026-08-01, and 37.5% inside the
-- 2026-02-28 Iran-war shock -- the biggest in the series. It is base rate, not transmission, and wrong-
-- signed as a detector; a one-day shift of the window moves it up to 9.4 points. It is NOT used here.
-- What the same replay measured on E's actually-named failure channel ("within-sector correlations
-- collapse toward 1 ... breaks pair mechanics", Strategy E's router rationale) was: median 60-day pair
-- correlation 0.70-0.75 and at most 37.5% of pairs at >= 0.80 on every monthly date from 2026-04-01 to
-- 2026-10-16, across both shocks. The channel never tripped. So the E row carries a TAIL RAIL on that
-- channel -- median >= 0.85 OR share-at->=0.80 >= 60% re-binds the rule -- pre-registered outside the
-- observed range by design, to be re-derived once >= 24 months of M2 history exist and not before, and
-- never tuned after a loss (judgment-native machinery requirement (d): criteria drift under loss
-- pressure). A gate that always passes in the sample is the honest consequence of that evidence, which
-- is why Strategy.md names E "exempt by class" and calls this a breaker, not a discriminator.
--
-- MEASUREMENT SOURCE, AND WHY IT FAILS CLOSED. M2 (Claude_Task_Plan.md `## M2`) publishes, in its monthly
-- `research-screen` decision-log row (screen = 'pair-divergence'), the fields `e_corr_median_60d`,
-- `e_corr_share_60d_ge_080`, `e_corr_population_n` and `e_corr_as_of` over its >= 0.50-floor population.
-- The view reads the latest such row from state.decision_log_current (so a superseded correction never
-- wins) and dates it by `e_corr_as_of`, falling back to the row's entry_date. A strategy whose row defines
-- a gate but for which the measurement is MISSING, or older than the row's `gate_max_age_days` as of
-- state.trading_day_today.today, trips the breaker: `measurement_fresh` FALSE -> `breaker_tripped` TRUE
-- -> `override_applies` TRUE. Absence is not evidence that the channel is quiet (the liveness-needs-
-- positive-evidence rule), so the breaker fails CLOSED, in the override's direction. Until M2 publishes
-- the fields for the first time (its 2026-11 run), the E row therefore binds exactly as before Rev 50 --
-- the amendment cannot loosen anything on landing day by construction.
--
-- A GATELESS EXEMPT ROW IS EXEMPT UNCONDITIONALLY. A SHOCK-NATIVE strategy (none on the roster today)
-- carries exempt_by_class TRUE and NULL gate columns: the acute grade is its activation input, there is
-- nothing to reconcile, and `gate_defined` FALSE keeps the measurement legs out of its row entirely.
--
-- WHAT THIS VIEW DOES NOT DO. It does not read breadth (E's own technical rule), any M1a input, or any
-- STRATEGY_ACTIVATION row; it never decides a call. It evaluates one attribute of one rule. One-
-- directionality is untouched: `override_applies` FALSE means the rule does not APPLY to M1b's raw
-- call, which stands as M1b made it -- a raw DO-NOT-ACTIVATE is never turned into ACTIVATE.
--
-- APPLY: live via the BigQuery MCP, together with the generated dbt mirror
-- (dbt/models/state/shock_transmission_status.sql; the table is a declared `ops` source). Apply after
-- 256. The table is CREATE IF NOT EXISTS + a NOT-EXISTS-guarded seed, so re-applying is idempotent.

-- ===== ops.shock_transmission_register =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.shock_transmission_register` (
  strategy_code          STRING    NOT NULL,  -- roster code; the view joins state.strategy_roster on it
  transmission_class     STRING    NOT NULL,  -- DIRECTIONAL-LONG | DIRECTIONAL-LONG-BIASED | DEFINED-RISK | SPREAD | SHOCK-NATIVE
  exempt_by_class        BOOL      NOT NULL,  -- FALSE = the acute rule applies; TRUE = it applies only through the gate
  gate_median_60d_max    NUMERIC,             -- breaker leg: median 60d pair correlation at or above this re-binds (NULL = no leg)
  gate_share_ge_080_max  NUMERIC,             -- breaker leg: share of pairs with 60d corr >= 0.80 at or above this re-binds (NULL = no leg)
  gate_max_age_days      INT64,               -- breaker leg: a measurement older than this (or absent) re-binds (NULL = no leg)
  horizon_class          STRING    NOT NULL,  -- limb (b) column, pinned to strategy holding horizon; 'status-quo' until measured
  rev                    STRING    NOT NULL,  -- the Strategy.md revision that wrote this row
  effective_date         DATE      NOT NULL,  -- latest (effective_date, registered_ts) per code wins
  note                   STRING,
  registered_ts          TIMESTAMP NOT NULL
)
OPTIONS(description='Shock Transmission Register (Strategy.md Rev 50, 2026-10-19): per-strategy attributes of the shock_overlay=acute reconciliation rule. Mirror of the Strategy.md register table; scripts/check_shock_register_lockstep.py asserts the seed in bigquery/257 agrees with it. Latest row per strategy_code wins. Read by state.shock_transmission_status.');

-- Seed: the five founding rows, verbatim from Strategy.md's register table. Idempotent on (strategy_code, rev).
INSERT INTO `stock-trading-498512.ops.shock_transmission_register`
  (strategy_code, transmission_class, exempt_by_class, gate_median_60d_max, gate_share_ge_080_max, gate_max_age_days,
   horizon_class, rev, effective_date, note, registered_ts)
SELECT r.strategy_code, r.transmission_class, r.exempt_by_class, r.gate_median_60d_max, r.gate_share_ge_080_max,
       r.gate_max_age_days, r.horizon_class, 'Rev 50', DATE '2026-10-19', r.note, CURRENT_TIMESTAMP()
FROM UNNEST([
  STRUCT('A' AS strategy_code, 'DIRECTIONAL-LONG'        AS transmission_class, FALSE AS exempt_by_class, CAST(NULL AS NUMERIC) AS gate_median_60d_max, CAST(NULL AS NUMERIC) AS gate_share_ge_080_max, CAST(NULL AS INT64) AS gate_max_age_days, 'status-quo' AS horizon_class, 'Long-only, 1-12 month holds; a shock prices into the index level A is long. BINDS.' AS note),
  STRUCT('B', 'DIRECTIONAL-LONG-BIASED', FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Long-biased by construction (0 of ~108 theses ever short); no measured event-reaction-dispersion series exists to gate on. Default-REJECT: BINDS until one does.'),
  STRUCT('C', 'DEFINED-RISK',            FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Loss bounded by structure (2.18); C carries its own HYBRID FOMC-only scope, which this register neither duplicates nor widens. BINDS.'),
  STRUCT('D', 'DIRECTIONAL-LONG',        FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Long-only, multi-year; entering at shock-elevated levels is the 2.7 exposure. BINDS. Its horizon row is the live limb (b) question.'),
  STRUCT('E', 'SPREAD',                  TRUE,  NUMERIC '0.85',         NUMERIC '0.60',         35,                  'status-quo', 'Market factor netted by construction; the gate measures the failure channel E itself names (within-industry-group correlation collapse) on the M2 >= 0.50-floor population. Thresholds pre-registered outside the 2026-04..2026-10 observed range (median 0.70-0.75, share >= 0.80 at most 37.5%).')
]) AS r
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.shock_transmission_register` x
  WHERE x.strategy_code = r.strategy_code AND x.rev = 'Rev 50'
);

-- ===== state.shock_transmission_status =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.shock_transmission_status` AS
WITH register AS (
  -- Latest row per strategy code. A later re-registration (a new Strategy.md revision, or a newcomer's
  -- row re-authored before PROBE) appends; it never updates in place.
  SELECT *
  FROM `stock-trading-498512.ops.shock_transmission_register`
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
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'research-screen'
    AND JSON_VALUE(fields, '$.screen') = 'pair-divergence'
    AND SAFE_CAST(JSON_VALUE(fields, '$.e_corr_median_60d') AS NUMERIC) IS NOT NULL
    AND SAFE_CAST(JSON_VALUE(fields, '$.e_corr_share_60d_ge_080') AS NUMERIC) IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (ORDER BY measurement_as_of DESC, event_ts DESC, entry_id DESC) = 1
),
today AS (
  SELECT today FROM `stock-trading-498512.state.trading_day_today`
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
  FROM `stock-trading-498512.state.strategy_roster` r
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
FROM evaluated;

-- ============================================================================================
-- 226_park_rule_shadow_inflation_token.sql (2026-09-05)
--
-- ONE CHANGE, ONE TOKEN: state.park_rule_shadow's RISK_OFF sub-branch keys on
-- `inflation_trend IN ('disinflationary', 'stable')`, and `'disinflationary'` is not a token M1a has
-- ever written. The operative enum says `disinflating`. Nothing else in the view changes -- the
-- first-match-wins tier order, the has_signals "no data, no claim" gate, the de-risk-safe
-- IF(...) IEF/SGOV resolution and every threshold are carried forward byte-identical.
--
-- WHY IT IS A SEPARATE FILE AND NOT PART OF THE VOCABULARY WORK. Found during the R6 consumer
-- mapping of the shock-override package (2026-09-05), which enumerated every exact-string consumer of
-- a drifted regime token. This one is an out-of-scope defect the sweep happened to walk past, fixed
-- here under the standing instruction to fix what is found rather than hand it back as a note.
--
-- THIS VIEW NEVER TRADES, AND THAT IS THE WHOLE SEVERITY ASSESSMENT. state.park_rule_shadow is v1's
-- deterministic regime->vehicle lookup table, kept RECORD-ONLY as counterfactual benchmark #3 that
-- the AI Park Allocator's judgment is measured against (owner-rejected as decision-maker 2026-07-18;
-- PARK_ROUTER_DESIGN.md v2 sections 1/9/11). Nothing in the live decision path reads it. The defect
-- could only ever have mis-scored the BENCHMARK -- it could never have moved capital.
--
-- MEASURED, before writing, so the severity is a fact rather than a posture:
--   * The full census of inflation_trend values ever present in the series is
--     NULL (467 days, through 2026-05-29) / reaccelerating (43) / stable (21) / disinflating (3,
--     from 2026-09-01). The literal `'disinflationary'` has NEVER appeared, so no historical row is
--     re-scored by this change and no benchmark number moves retroactively.
--   * The branch is inside the RISK_OFF tier, and rule_regime = 'RISK_OFF' occurs on ZERO of the 534
--     rows the view has ever produced. The IEF-vs-SGOV choice this token gates has therefore never
--     been reached even once.
-- So the defect is LATENT, not realized -- which is exactly the class this repo treats as a countdown
-- rather than a non-issue: the moment the RISK_OFF tier fires on a disinflating month, the benchmark
-- silently picks SGOV where the v1 rule table says IEF, and the AI allocator is then measured against
-- a counterfactual that is not the rule it claims to be.
--
-- SUPERSEDES `state.park_rule_shadow` in bigquery/92_park_allocator.sql (its only prior definition;
-- bigquery/92's marker is added in the same commit). Do NOT re-apply bigquery/92's definition in
-- isolation: it restores the unreachable token. bigquery/92's other objects are untouched and remain
-- canonical there.
--
-- NO dbt WORK: state.park_rule_shadow is a declared dbt SOURCE (dbt/models/sources.yml), deliberately
-- not a ported model -- the whole of bigquery/92 was out of scope for the 2026-09-01 dbt-port pass --
-- so scripts/check_dbt_view_coverage.py already counts it covered and there is no mirror to
-- regenerate. Its source description's file citation is repointed to this file in the same commit.
--
-- APPLY: live via the BigQuery MCP, after 225. Defines exactly one view; creates, redefines or drops
-- nothing else.
-- ============================================================================================

-- ===== state.park_rule_shadow =====
-- SUPERSEDES the definition in bigquery/92_park_allocator.sql (chain: 92 -> 226).
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_rule_shadow` AS
WITH sig AS (
  SELECT
    mark_date,
    shock_overlay, vix_close, vix_med3, dd_from_252d_high,
    spy_trend, spy_close, spy_200dma, inflation_trend
  FROM `stock-trading-498512.state.park_signal_daily`
),
classified AS (
  SELECT
    *,
    (shock_overlay IS NOT NULL AND vix_close IS NOT NULL AND vix_med3 IS NOT NULL
     AND dd_from_252d_high IS NOT NULL AND spy_trend IS NOT NULL
     AND spy_close IS NOT NULL AND spy_200dma IS NOT NULL) AS has_signals
  FROM sig
)
SELECT
  mark_date,
  CASE
    WHEN NOT has_signals THEN NULL
    WHEN shock_overlay = 'acute' OR vix_close >= 30 OR dd_from_252d_high <= -0.15 THEN 'CRISIS'
    WHEN vix_med3 >= 25 OR dd_from_252d_high <= -0.10 OR spy_trend = 'DOWN'        THEN 'RISK_OFF'
    WHEN vix_med3 >= 20 OR dd_from_252d_high <= -0.05 OR spy_close < spy_200dma    THEN 'CAUTION'
    ELSE 'RISK_ON'
  END AS rule_regime,
  CASE
    WHEN NOT has_signals THEN NULL
    WHEN shock_overlay = 'acute' OR vix_close >= 30 OR dd_from_252d_high <= -0.15 THEN 'SGOV'
    WHEN vix_med3 >= 25 OR dd_from_252d_high <= -0.10 OR spy_trend = 'DOWN'
      THEN IF(inflation_trend IN ('disinflating', 'stable'), 'IEF', 'SGOV')
    WHEN vix_med3 >= 20 OR dd_from_252d_high <= -0.05 OR spy_close < spy_200dma    THEN 'AOR'
    ELSE 'VOO'
  END AS rule_vehicle,
  shock_overlay, vix_close, vix_med3, dd_from_252d_high,
  spy_trend, spy_close, spy_200dma, inflation_trend
FROM classified;

-- VERIFICATION (run after apply; read-only).
-- SELECT inflation_trend, COUNT(*) AS days, COUNTIF(rule_regime = 'RISK_OFF') AS risk_off_days,
--        COUNTIF(rule_vehicle = 'IEF') AS ief_days
-- FROM `stock-trading-498512.state.park_rule_shadow` GROUP BY inflation_trend ORDER BY inflation_trend;
--   -- 2026-09-05: identical to the pre-apply read -- NULL 467 / disinflating 3 / reaccelerating 43 /
--   -- stable 21, risk_off_days 0 and ief_days 0 throughout. A no-change apply BY CONSTRUCTION: the
--   -- token this file replaces was never present in the data and its branch was never reached.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

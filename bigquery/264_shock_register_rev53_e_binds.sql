-- ===== 264: ops.shock_transmission_register Rev 53 re-registration -- Strategy E binds until its gate is revised =====
-- Project: stock-trading-498512. Apply after 263. APPENDS rows only -- CREATES NO OBJECT, REPLACES NO VIEW.
-- state.shock_transmission_status (bigquery/257) is unchanged: it already takes the latest row per strategy_code.
--
-- WHY (owner directive 2026-10-23, interactive session). Router amendment review premortem-router-2026-a1 cycle 1
-- (AR_orc 2026-10-22, orchestrator event a9543d56-3d07-4f29-90b6-6b0ce5e54efc) returned TIER 1 DEFECT - REVISION
-- REQUIRED on the Rev 50 register. T1-1: E's exemption sat behind a median / share breaker computed over M2's whole
-- >= 0.50-floor population, which cannot register a shock confined to one industry group, had no low-side
-- (correlation-breakdown) leg, and never tripped in-sample. The owner directed the recommended revision to land as
-- written: E is no longer exempt (exempt_by_class FALSE, no gate) until a revised gate meets the three
-- re-exemption requirements in Strategy.md's register section. A-D are restated unchanged.
--
-- LIVE EFFECT: none. Before this file E already read override_applies TRUE because its measurement had never been
-- published (the breaker fails closed). After it, E reads TRUE by class. Nothing can loosen.
--
-- THIS FILE IS THE REGISTER'S MIRROR FROM NOW ON. scripts/check_shock_register_lockstep.py compares Strategy.md's
-- register table with the highest-numbered bigquery/NNN_*.sql carrying the register INSERT, so the UNNEST block
-- below restates ALL five rows. Only rows whose content differs from the live latest row are inserted (E alone
-- today), so A-D get no redundant Rev 53 rows; re-applying is idempotent on (strategy_code, rev).
INSERT INTO `stock-trading-498512.ops.shock_transmission_register`
  (strategy_code, transmission_class, exempt_by_class, gate_median_60d_max, gate_share_ge_080_max, gate_max_age_days,
   horizon_class, rev, effective_date, note, registered_ts)
SELECT r.strategy_code, r.transmission_class, r.exempt_by_class, r.gate_median_60d_max, r.gate_share_ge_080_max,
       r.gate_max_age_days, r.horizon_class, 'Rev 53', DATE '2026-10-23', r.note, CURRENT_TIMESTAMP()
FROM UNNEST([
  STRUCT('A' AS strategy_code, 'DIRECTIONAL-LONG'        AS transmission_class, FALSE AS exempt_by_class, CAST(NULL AS NUMERIC) AS gate_median_60d_max, CAST(NULL AS NUMERIC) AS gate_share_ge_080_max, CAST(NULL AS INT64) AS gate_max_age_days, 'status-quo' AS horizon_class, 'Long-only, 1-12 month holds; a shock prices into the index level A is long. BINDS.' AS note),
  STRUCT('B', 'DIRECTIONAL-LONG-BIASED', FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Long-biased by construction (0 of ~108 theses ever short); no measured event-reaction-dispersion series exists to gate on. Default-REJECT: BINDS until one does.'),
  STRUCT('C', 'DEFINED-RISK',            FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Loss bounded by structure (2.18); C carries its own HYBRID FOMC-only scope, which this register neither duplicates nor widens. BINDS.'),
  STRUCT('D', 'DIRECTIONAL-LONG',        FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Long-only, multi-year; entering at shock-elevated levels is the 2.7 exposure. BINDS. Its horizon row is the live limb (b) question.'),
  STRUCT('E', 'SPREAD',                  FALSE, CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS INT64), 'status-quo', 'Rev 53 (owner directive 2026-10-23, router review premortem-router-2026-a1 cycle 1 T1-1): exemption withdrawn. The Rev 50 breaker read population-wide statistics a group-local shock does not move, had no low-side leg and never tripped in-sample. Default-REJECT: BINDS until a gate with a per-industry-group leg, a low-side leg and a stress replay showing it trips is landed by owner revision and survives adversarial review.')
]) AS r
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.shock_transmission_register` x
  WHERE x.strategy_code = r.strategy_code AND x.rev = 'Rev 53'
)
AND NOT EXISTS (
  SELECT 1
  FROM (
    SELECT * FROM `stock-trading-498512.ops.shock_transmission_register`
    QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_date DESC, registered_ts DESC) = 1
  ) l
  WHERE l.strategy_code = r.strategy_code
    AND l.transmission_class = r.transmission_class
    AND l.exempt_by_class = r.exempt_by_class
    AND l.gate_median_60d_max IS NOT DISTINCT FROM r.gate_median_60d_max
    AND l.gate_share_ge_080_max IS NOT DISTINCT FROM r.gate_share_ge_080_max
    AND l.gate_max_age_days IS NOT DISTINCT FROM r.gate_max_age_days
    AND l.horizon_class = r.horizon_class
);

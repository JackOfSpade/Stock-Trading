-- Parallel-run dbt port of bigquery/189_paper_stuck_completeness.sql:state.strategy_paper_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS paper_days,
    MAX(sim_closed_trades) AS sim_closed_trades,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest_excess,
    ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10) AS trailing_excess,
    ARRAY_LENGTH(ARRAY_AGG(excess ORDER BY incubation_day DESC LIMIT 10)) AS trailing_n
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }}
  WHERE phase = 'paper'
  GROUP BY strategy_code
),
positive_cells AS (
  SELECT strategy_code, COUNT(DISTINCT regime_cell) AS n_positive_cells
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }}
  WHERE phase = 'paper' AND excess >= 0 AND regime_cell IS NOT NULL
  GROUP BY strategy_code
),
gap_fill AS (
  SELECT DISTINCT p.strategy_code
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }} p
  JOIN {{ ref('arsenal_regime_coverage') }} c ON c.regime_cell = p.regime_cell
  WHERE p.phase = 'paper' AND p.excess >= 0 AND c.is_gap
),
freq AS (
  -- trades_threshold computed ONCE here (adversarial self-audit fix, rev 2026-07-11) — the same CASE
  -- expression used to be duplicated 4x below (trades_met_threshold, trades_met, stuck, ready), inviting
  -- silent divergence if only some copies were ever edited. Semantics-preserving; the frequency-scaled
  -- trade-count floor for a slow-cadence strategy (declared_annual_roundtrips < 10), floored at 3.
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS trades_threshold
  FROM {{ source('state_external', 'strategy_candidates') }}
  -- Defense-in-depth (2026-07-18 audit): candidate_code has no enforced uniqueness (NOT ENFORCED PK
  -- world) and four independent routines write NEW rows. A duplicate code here would fan out the
  -- LEFT JOIN below into duplicate readiness rows, corrupting the single `ready`/`stuck` boolean SL3
  -- keys transitions off. Newest row wins.
  QUALIFY ROW_NUMBER() OVER (PARTITION BY candidate_code ORDER BY created_ts DESC) = 1
),
rails AS (SELECT * FROM {{ ref('arsenal_rails') }}),
ars AS (SELECT enabled, incubation_frozen FROM {{ ref('arsenal_enabled') }})
SELECT
  r.strategy_code,
  COALESCE(a.paper_days, 0) AS paper_days,
  COALESCE(a.sim_closed_trades, 0) AS sim_closed_trades,
  a.latest_excess,
  fr.declared_annual_roundtrips,
  COALESCE(fr.trades_threshold, 10) AS trades_met_threshold,
  COALESCE(pc.n_positive_cells, 0) AS n_positive_cells,
  COALESCE(a.paper_days, 0) >= 60 AS days_met,
  COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10) AS trades_met,
  (COALESCE(a.trailing_n, 0) >= 10
   AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0) AS excess_met,
  (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL) AS regime_met,
  rails.adoption_window_open AS rate_limit_clear,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE')) AS not_already_transitioned,
  -- stuck (ITEM 9, 2026-07-11; WIDENED 2026-08-20 by this file to cover all three PAPER dead-ends,
  -- mirroring bigquery/60's SHADOW flag properly — see this file's header): paper_days has run long
  -- enough (>=400) that continuing to wait is no longer reasonable, and at least one CANDIDATE-side
  -- gate term is still unmet. Read by Claude_Task_Plan.md SL3 STEP 4's PAPER TIME-CULL, not itself a
  -- component of `ready` below (a stuck candidate is culled to REJECTED, not promoted). The three
  -- covered dead-ends: too few simulated closed round-trips (the original ITEM 9 case), persistently
  -- negative/NULL trailing excess-vs-SGOV, and regime coverage never demonstrated. Arsenal-state terms
  -- (rate_limit_clear / ceiling_ok / arsenal_ok / not_already_transitioned) are DELIBERATELY excluded —
  -- a candidate blocked only by a roster ceiling, a closed adoption window or the owner's freeze is
  -- healthy and must not be culled for it.
  (COALESCE(a.paper_days, 0) >= 400
   AND NOT (
     COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
     AND (COALESCE(a.trailing_n, 0) >= 10
          AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
     AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   )) AS stuck,
  -- stuck_reason (NEW 2026-08-20): the '+'-joined list of failed candidate-side terms, so SL3 STEP 4's
  -- required `reject_reason` is READ from the view rather than composed as free text at the write site.
  -- NULL exactly when `stuck` is FALSE — `stuck_reason IS NOT NULL` <=> `stuck`, always; never read the
  -- two as independent signals.
  CASE WHEN COALESCE(a.paper_days, 0) < 400 THEN NULL
       ELSE NULLIF(ARRAY_TO_STRING(ARRAY_CONCAT(
              IF(NOT (COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)),
                 ['trades'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(a.trailing_n, 0) >= 10
                      AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0),
                 ['excess'], ARRAY<STRING>[]),
              IF(NOT (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL),
                 ['regime'], ARRAY<STRING>[])
            ), '+'), '')
  END AS stuck_reason,
  (COALESCE(a.paper_days, 0) >= 60
   AND COALESCE(a.sim_closed_trades, 0) >= COALESCE(fr.trades_threshold, 10)
   AND (COALESCE(a.trailing_n, 0) >= 10
        AND (SELECT COUNT(*) FROM UNNEST(a.trailing_excess) AS e WHERE e IS NULL OR e < 0) = 0)
   AND (COALESCE(pc.n_positive_cells, 0) >= 2 OR gf.strategy_code IS NOT NULL)
   AND rails.adoption_window_open
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':PAPER->PROBE'))) AS ready
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN positive_cells pc USING (strategy_code)
LEFT JOIN gap_fill gf USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'PAPER'

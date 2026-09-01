-- Parallel-run dbt port of bigquery/164_capital_utilisation_and_restore_integrity.sql:state.capital_utilisation_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH enabled AS (
  SELECT e.strategy_code
  FROM {{ ref('strategy_capital_enablement') }} e
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
),
-- Last real deployment. Dust lots are excluded (bigquery/125's audited is_dust), NULL failing open as
-- non-dust so a real lot can never be silently dropped -- the same predicate every other
-- position_lifecycle reader uses.
deploy AS (
  SELECT strategy AS strategy_code,
    MAX(entry_date) AS last_entry_date,
    COUNTIF(exit_date IS NULL) AS open_positions
  FROM {{ ref('position_lifecycle') }}
  WHERE NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy
),
-- Evaluation liveness. entry_type='thesis-construction' is the canonical "this strategy was assessed
-- for a trade" record, GO or NO-GO alike -- a NO-GO is a successful evaluation, not a missing one.
-- Reads state.decision_log_current (bigquery/144), NOT events.decision_log raw: a corrected decision
-- is recorded append-only as a NEW row whose superseded_by names the obsolete one, so a raw read would
-- count both the superseded row and its replacement and overstate evaluation liveness -- which, in
-- this view, would wrongly clear a genuinely stranded strategy. Enforced by
-- scripts/check_superseded_by_discipline.py, which failed this file on the first attempt.
evals AS (
  SELECT strategy AS strategy_code,
    COUNTIF(entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 60 DAY)) AS evaluations_60d,
    MAX(entry_date) AS last_evaluation_date
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE entry_type = 'thesis-construction' AND strategy IS NOT NULL
  GROUP BY strategy
),
base AS (
  SELECT
    en.strategy_code,
    ROUND(COALESCE(n.available_funds, 0), 2) AS idle_capital,
    ROUND(COALESCE(n.nav, 0), 2) AS nav,
    ROUND(COALESCE(n.deployed_mv, 0), 2) AS deployed_mv,
    COALESCE(d.open_positions, 0) AS open_positions,
    d.last_entry_date,
    -- NULL last_entry_date means NEVER deployed; measure from capital-eligibility instead so a
    -- never-deployed strategy still gets a real age rather than a NULL that sorts as "fine".
    COALESCE(
      DATE_DIFF(CURRENT_DATE('America/Denver'), d.last_entry_date, DAY),
      DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(r.immutable_since, 'America/Denver'), DAY)
    ) AS days_since_deployment,
    d.last_entry_date IS NULL AS never_deployed,
    COALESCE(ev.evaluations_60d, 0) AS evaluations_60d,
    ev.last_evaluation_date
  FROM enabled en
  LEFT JOIN {{ ref('strategy_nav') }} n ON n.strategy = en.strategy_code
  LEFT JOIN deploy d ON d.strategy_code = en.strategy_code
  LEFT JOIN evals ev ON ev.strategy_code = en.strategy_code
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = en.strategy_code
)
SELECT *,
  CASE
    WHEN idle_capital < 1000 THEN 'immaterial - under the 1000.00 reporting floor'
    WHEN days_since_deployment < 90 THEN 'deploying - within 90 days of its last entry'
    WHEN evaluations_60d > 0 THEN 'idle but ACTIVELY EVALUATED - healthy per Operating_Protocols section 16 (merely idle keeps its capital)'
    ELSE 'STRANDED - material idle capital, no deployment, and no thesis-construction evaluation in 60 days'
  END AS posture,
  -- The ONLY condition that alerts. Everything else is reported for visibility and stays silent.
  (idle_capital >= 1000 AND days_since_deployment >= 90 AND COALESCE(evaluations_60d, 0) = 0)
    AS is_stranded
FROM base

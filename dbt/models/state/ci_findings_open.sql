-- Parallel-run dbt port of bigquery/86_ci_findings_first_detected.sql:state.ci_findings_open — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY workflow, finding_key ORDER BY finding_ts DESC) rn
  FROM {{ source('ops', 'ci_findings') }}
),
open_now AS (
  SELECT workflow, finding_key, finding_ts, detail, run_url
  FROM latest
  WHERE rn = 1 AND status = 'open'
),
last_resolved AS (
  SELECT workflow, finding_key, MAX(finding_ts) AS last_resolved_ts
  FROM {{ source('ops', 'ci_findings') }}
  WHERE status = 'resolved'
  GROUP BY workflow, finding_key
),
-- Earliest open row of the current episode. Every open_now key is guaranteed a row here: its own
-- latest row is 'open' and (by ORDER BY finding_ts DESC) newer than any resolved row for the key.
episode_start AS (
  SELECT c.workflow, c.finding_key, MIN(c.finding_ts) AS first_open_ts
  FROM {{ source('ops', 'ci_findings') }} c
  LEFT JOIN last_resolved r
    ON r.workflow = c.workflow AND r.finding_key = c.finding_key
  WHERE c.status = 'open'
    AND (r.last_resolved_ts IS NULL OR c.finding_ts > r.last_resolved_ts)
  GROUP BY c.workflow, c.finding_key
)
SELECT
  o.workflow,
  o.finding_key,
  o.finding_ts,
  o.detail,
  o.run_url,
  DATE(e.first_open_ts, 'America/Denver') AS first_detected
FROM open_now o
JOIN episode_start e
  ON e.workflow = o.workflow AND e.finding_key = o.finding_key

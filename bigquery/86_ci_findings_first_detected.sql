-- ci_findings bridge: per-object findings need an episode-aware first_detected (2026-07-18 audit).
-- Project: stock-trading-498512. Apply after 67_ci_findings_bridge.sql (whose state.ci_findings_open
-- definition this SUPERSEDES) and after 85_gate_selfheal_repo_catchup.sql (highest-numbered file at
-- time of writing; if 85 lands later, order between them is immaterial — different objects).
--
-- PROBLEM (two halves, one fix):
--  1. live-sql-parity.yml collapsed EVERY drifted object into ONE ops.ci_findings row
--     (finding_key='live_sql_parity', detail=head -c 4000 of the whole run output) — on a high-drift
--     day most objects were silently truncated out of the DECLARED single delivery path for D3's
--     self-heal (confirmed live 2026-07-18: ops.sp_score_theater was genuinely drifted but absent
--     from the stored detail). The workflow now writes ONE ROW PER DRIFTED OBJECT
--     (finding_key='<dataset>.<name>', from the checker's --json-out), auto-resolves per-object keys
--     that stop drifting, and keeps the aggregate 'live_sql_parity' key only for the
--     zero-verification fail-closed case (checked==0 — systemic bq/WIF failure, no per-object data).
--  2. D3's CI-FINDINGS ADJUDICATION step (Claude_Task_Plan.md) and ops.parity_selfheal_log
--     (bigquery/69) both key their one-day-lag / oldest-first / latch logic on a per-object
--     `first_detected` that state.ci_findings_open (bigquery/67) never provided. The table is
--     append-only, so the full history is already there — this view now computes it.
--
-- first_detected = MIN(finding_ts) over the CURRENT unbroken-open EPISODE for that
-- (workflow, finding_key): open rows AFTER the most recent 'resolved' row (or all open rows if the
-- key never resolved). A key that re-drifts after a resolution correctly restarts its clock — the
-- one-day self-heal lag must re-arm, not inherit a months-old first sighting. DATE (not TIMESTAMP)
-- to match ops.parity_selfheal_log.first_detected (bigquery/69).
--
-- Additive change only (existing columns unchanged) — the other consumer, sp_sq_cadence_check's
-- ci_finding raise/auto-resolve block (bigquery/75), selects existing columns and is unaffected.

CREATE OR REPLACE VIEW `stock-trading-498512.state.ci_findings_open` AS
WITH latest AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY workflow, finding_key ORDER BY finding_ts DESC) rn
  FROM `stock-trading-498512.ops.ci_findings`
),
open_now AS (
  SELECT workflow, finding_key, finding_ts, detail, run_url
  FROM latest
  WHERE rn = 1 AND status = 'open'
),
last_resolved AS (
  SELECT workflow, finding_key, MAX(finding_ts) AS last_resolved_ts
  FROM `stock-trading-498512.ops.ci_findings`
  WHERE status = 'resolved'
  GROUP BY workflow, finding_key
),
-- Earliest open row of the current episode. Every open_now key is guaranteed a row here: its own
-- latest row is 'open' and (by ORDER BY finding_ts DESC) newer than any resolved row for the key.
episode_start AS (
  SELECT c.workflow, c.finding_key, MIN(c.finding_ts) AS first_open_ts
  FROM `stock-trading-498512.ops.ci_findings` c
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
  DATE(e.first_open_ts) AS first_detected
FROM open_now o
JOIN episode_start e
  ON e.workflow = o.workflow AND e.finding_key = o.finding_key;

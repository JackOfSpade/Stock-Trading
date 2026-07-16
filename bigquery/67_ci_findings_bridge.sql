-- CI-findings consumption-closure bridge (self-improvement audit 2026-07-16, CC-1).
-- Project: stock-trading-498512. Apply after 63_scheduled_query_version_registry.sql.
--
-- PROBLEM: four CI guards (live-sql-parity daily, keyless-sa-audit + wif-binding-audit monthly,
-- guard-config-audit monthly) each open/refresh a deduped GitHub issue on a finding, but nothing
-- automated ever reads those issues -- live-sql-parity's own Actions run even stays green on drift
-- (issue #10 "Live SQL parity: needs attention", opened 2026-07-16T09:34Z, sat unconsumed while run
-- 29487150663 concluded 'success'). This is the exact 2026-07-11 state.trading_enabled-clobber drift
-- class (bigquery/47_trading_enabled_resync.sql) -- re-applying the repo definition via the BigQuery
-- MCP is something any routine session can already do, but no wire existed between the GH-issue
-- finding and a BigQuery-side consumer, and none of these findings ever reached ops.alerts/email.
--
-- FIX: ops.ci_findings is an append-only marker table the four workflows INSERT into (open/resolved
-- rows), state.ci_findings_open is the latest-wins "what's still open" view, and D3
-- (Claude_Task_Plan.md) + cadence_check.sql are the two consumers -- D3 adjudicates live-sql-parity
-- drift objects (re-apply vs. commit-as-hotfix) and logs events.decision_log; cadence_check.sql
-- raises/auto-resolves a `ci_finding` warning alert off state.ci_findings_open, so the finding reaches
-- the monitored alert-emailer channel even on a day nobody manually reads GitHub Issues.
--
-- WRITE PATH: gh-ci-runner@ is read-only today (RUNBOOK section 6/15) so the workflow INSERTs are a
-- table-scoped `roles/bigquery.dataEditor` grant on exactly `ops.ci_findings` -- the same class of
-- narrow, table-scoped exception already proven live for `ops.routine_commit_markers`
-- (OWNER_ACTIONS.md item 3 / auto-merge-claude.yml:208-226, rows source='auto-merge-claude.yml'
-- verified live 2026-07-14/07-15). Until that grant lands, every INSERT below is wrapped
-- `|| echo "::warning::..."` in the workflow YAML -- non-fatal, GH-issue path unaffected.
--
-- status='open'|'resolved'; latest row per (workflow, finding_key) wins (ROW_NUMBER() latest-wins,
-- the same convention as every other state.* view in this repo). A clean run writes an unconditional
-- resolved row even when no GH issue was open to close -- harmless (the view only cares about the
-- latest row), and it is what prevents a manually-closed GH issue from stranding an open
-- ops.ci_findings row / stuck cadence_check alert (see live-sql-parity.yml's "Close finding issue if
-- resolved" step, now unconditional).

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.ci_findings` (
  finding_ts  TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  workflow    STRING NOT NULL,
  finding_key STRING NOT NULL,
  status      STRING NOT NULL,
  detail      STRING,
  run_url     STRING
)
PARTITION BY DATE(finding_ts)
OPTIONS(description='Append-only CI-guard finding markers (consumption-closure 2026-07-16). Written by GitHub Actions via a table-scoped gh-ci-runner@ dataEditor grant (ops.routine_commit_markers precedent, OWNER_ACTIONS.md §3 / auto-merge-claude.yml:208). status=open|resolved; latest row per (workflow,finding_key) wins. Clean runs write unconditional resolved rows — harmless, the view takes the latest.');

CREATE OR REPLACE VIEW `stock-trading-498512.state.ci_findings_open` AS
SELECT workflow, finding_key, finding_ts, detail, run_url
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY workflow, finding_key ORDER BY finding_ts DESC) rn
  FROM `stock-trading-498512.ops.ci_findings`
)
WHERE rn = 1 AND status = 'open';

-- Registry bump (bigquery/63_scheduled_query_version_registry.sql): cadence_check.sql's body gains
-- the ci_finding raise/auto-resolve block below, v3 -> v4. Standalone of the rest of this file.
MERGE `stock-trading-498512.state.expected_scheduled_query_versions` T
USING (SELECT 'cadence_check' AS sq_name, 'v4' AS expected_version,
              'v4, 2026-07-16: added ci_finding raise/auto-resolve (bigquery/67_ci_findings_bridge.sql)' AS git_note) S
ON T.sq_name = S.sq_name
WHEN MATCHED THEN UPDATE SET expected_version = S.expected_version, git_note = S.git_note, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (sq_name, expected_version, git_note) VALUES (S.sq_name, S.expected_version, S.git_note);

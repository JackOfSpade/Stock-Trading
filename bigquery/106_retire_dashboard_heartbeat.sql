-- Retire 'dashboard' from state.automation_heartbeat's watched sources (incident 2026-07-25:
-- automation_heartbeat critical 0220d792 latched the D2/D2a trading-enable gate closed, and per
-- ops/RUNBOOK.md §16 was NEVER going to mechanically self-heal). Project: stock-trading-498512.
-- Apply after bigquery/58_dashboard_heartbeat.sql (which this supersedes for the automation_heartbeat
-- view only -- 58's ops.heartbeat table + generate_dashboard.py's write-on-build stay unchanged).
--
-- ROOT CAUSE. dashboard.yml is double-gated OFF by design (vars.PUBLISH_DASHBOARD is unset; confirmed
-- via `gh variable list` -- it does not exist as a repo variable, and every one of its ~36 scheduled
-- runs to date completes in 9-36s, the guard-skip path, never the full Python+BigQuery+Pages build).
-- That is CORRECT, not a bug: RUNBOOK §16 (added 2026-06-20, i.e. BEFORE OWNER_ACTIONS.md item C's
-- 2026-07-17 IAM-grant note) says plainly that this repo's owner is a personal (non-Enterprise) GitHub
-- account, so Pages publishes PUBLICLY even for a private repo -- turning PUBLISH_DASHBOARD on would
-- expose live positions/NAV/alerts to the open internet. So dashboard.yml's CI path can never
-- legitimately write ops.heartbeat(source='dashboard') on this repo, ever -- there is no live CI
-- build for it to prove.
--
-- The heartbeat still went "monitored" and then stale anyway because ad-hoc LOCAL runs of
-- ops/dashboard/generate_dashboard.py (the RUNBOOK §16-recommended way to view it, since Pages is
-- off) write the exact same ops.heartbeat(source='dashboard') row a real CI build would -- and
-- bigquery/58's view takes ANY beat as proof of life, with no filter for the `' (ci)'` tag
-- generate_dashboard.py already stamps on genuine GITHUB_ACTIONS runs (OAE-5, 2026-07-16). A cluster
-- of 10 such local runs on 2026-07-25 04:34-04:38 MT (note='index.html generated', no ' (ci)' suffix)
-- kept the view fresh for a while, then aged past `dashboard`'s 56h threshold -- the SAME session-window
-- contamination pattern OWNER_ACTIONS.md item C already hand-cleaned once before (240 rows deleted
-- around 2026-07-18). Since automation_heartbeat is latching=TRUE by construction (absent from
-- ops.alert_policy -- bigquery/34_alert_lifecycle.sql), no mechanical rule ever clears it; it will
-- keep recurring, on no fixed schedule, for as long as 'dashboard' stays a watched source with no real
-- CI signal behind it.
--
-- FIX: stop watching a source that can never legitimately beat. Removes exactly the one UNNEST row
-- 58 added; back to bigquery/16_automation_health.sql's original two sources. ops.heartbeat keeps
-- logging source='dashboard' rows (generate_dashboard.py's write is unchanged and harmless) -- they
-- are simply no longer read by this view. Idempotent (CREATE OR REPLACE VIEW); safe to re-run.
--
-- Companion action (not in this file, requires owner/session judgment call, done once alongside this
-- migration): UPDATE ops.alerts SET resolved=TRUE ... WHERE alert_id='0220d792-...' -- latching means
-- the existing alert row needs an explicit human-authorized clear even after its watched source is
-- retired; see OWNER_ACTIONS.md item C addendum.
CREATE OR REPLACE VIEW `stock-trading-498512.state.automation_heartbeat` AS
WITH expected AS (
  SELECT * FROM UNNEST([
    STRUCT('alert_emailer' AS source, 8   AS max_age_hours),   -- polls every ~2h; stale after ~4 misses (jitter-tolerant)
    STRUCT('weekly_report' AS source, 216 AS max_age_hours)    -- weekly; stale after ~9 days (1 missed week + slack)
  ])
),
last AS (
  SELECT source, MAX(beat_ts) AS last_beat_ts
  FROM `stock-trading-498512.ops.heartbeat`
  -- A 'poll-error' beat (alert_emailer.gs beat_(false) on a PERSISTENT BigQuery failure) is NOT proof
  -- of life; excluding it from the liveness MAX lets a sustained emailer outage age out and trip the
  -- DTS instead of the error-beat keeping the source "fresh" forever (2026-07-18 audit). Kept in
  -- lockstep with bigquery/16_automation_health.sql's identical `last` CTE.
  WHERE note IS DISTINCT FROM 'poll-error'
  GROUP BY source
)
SELECT
  e.source,
  e.max_age_hours,
  l.last_beat_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) AS age_hours,
  (l.last_beat_ts IS NOT NULL) AS monitored,
  COALESCE(l.last_beat_ts IS NOT NULL
           AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) > e.max_age_hours, FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM expected e
LEFT JOIN last l USING (source);

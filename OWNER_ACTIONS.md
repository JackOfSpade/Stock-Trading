# Owner actions — 2026-07-11 self-improvement audit (Items 1-30)

Everything Claude could apply without you (schema, views, procedures, scheduled-query SQL bodies,
repo docs) is already applied live and merged to `main`. This file is the complete list of the
handful of things only you can do — a GCP console click, a `bq`/`gcloud` command run with your own
credentials, an Apps Script paste (`script.google.com` isn't reachable from here), or a tax election
with your broker. Nothing in this system is blocked or unsafe while these are outstanding — every
item below is explicitly designed to fail closed / no-op / stay on its existing fallback until you
act. Ordered roughly by how soon you'd want to get to it.

---

## 0. URGENT — GitHub Actions billing is currently failing (blocks ALL merges)

**Symptom (as of 2026-07-11):** every CI job on the working branch fails immediately with *"The job
was not started because recent account payments have failed or your spending limit needs to be
increased."* This is not a code or workflow problem — it's your GitHub account's billing state.

**Action:** GitHub → **Settings → Billing & plans** → fix the payment method / raise the spending
limit. Nothing is broken in the meantime: the auto-merge gate correctly reads a billing-failed run as
CI failure and skips the merge (fail-closed, per `tests/test_auto_merge_logic.sh`), so no commit gets
merged without green CI. One commit (`d58c7cc`, the Item 29 closing note — documentation only, zero
schema/live-data impact) is currently stuck on the branch waiting for this fix. Once billing is
resolved, either re-run the failed workflow from the Actions tab, or push an empty/trivial commit to
retrigger CI — it should merge cleanly on the next green run.

---

## 1. Apps Script re-pastes (script.google.com — Claude cannot reach this surface)

Two scripts changed this session. Both are in the **"Stock-Trading Automation"** Apps Script project
(see `ops/RUNBOOK.md` / memory `reference_apps_script_project`). For each, open the project at
script.google.com, open the named file, select all, paste the repo's current version, save, and
(if prompted) redeploy. Prefer pasting the **whole file** over hand-editing — the repo copy is the
source of truth and a partial edit risks drifting from it.

- **`ops/monitoring/alert_emailer.gs`** — two changes bundled in:
  1. **(Item 17)** A new recurring re-select for `termination_close_staged` alerts: unlike every other
     alert (emailed once via `notified_ts`), a staged DRAWDOWN/m2m-termination close order now keeps
     re-appearing in the ~2h poll (distinct subject marker) until D2a's fill reconciliation resolves
     it — so a dismissed/missed push notification for a termination close can't go silently unfollowed
     the way it could before this session.
  2. **(Item 23)** A `SCRIPT_VERSION = 'v1'` constant, reported in the script's existing
     `ops.heartbeat` beat. Lets `state.script_version_drift` (see item 2 below) detect if a future
     repo change to this file is ever deployed *without* being re-pasted.
  - Verified: `node --check` clean on the repo copy.

- **`ops/weekly_report/weekly_report.gs`** — **(Item 23)** the same `SCRIPT_VERSION = 'v1'` constant +
  heartbeat report, no other functional change this pass.

**Why this matters if skipped:** nothing breaks — `state.script_version_drift` just won't have
anything to compare against yet (self-bootstrapping: it never fires until a script has reported a
version at least once), and Item 17's stronger termination-close alerting simply doesn't take effect
until the paste happens. The existing one-shot alert still fires either way.

---

## 2. Register a new scheduled query — `safety_critical_dml_watch.sql` (Item 6)

**What it does:** every 6h, RAISEs (fails the job → BigQuery's built-in failure email) and writes a
critical `ops.alerts` row if anything ran a raw `UPDATE`/`DELETE`/`MERGE`/`TRUNCATE` against
`ops.trading_control`, `ops.arsenal_control`, `events.strategy_lifecycle`, or `perf.strategy_daily` in
the last 24h — the four tables that are supposed to be mutated only by `INSERT` (or, for
`perf.strategy_daily`, only by the one named nightly rebuild). This is the compensating detective
control for the fact that every routine shares one owner-OAuth principal, so IAM alone can't prevent
an out-of-band mutation.

**Action (BigQuery Studio → Scheduled queries → Create, same flow as every other scheduled query in
`ops/RUNBOOK.md` §1):**
1. Paste `bigquery/scheduled_queries/safety_critical_dml_watch.sql`.
2. Schedule: every 6 hours. Location: US.
3. Run as: the **same service account you already use for `integrity_check.sql`** — it needs
   `roles/bigquery.resourceViewer`, which that SA should already have, so **no new IAM grant is
   needed if you register it under the same identity**.
4. Under Notifications, enable **"Send email on failure"** — the query RAISEs on a real hit, so that
   email *is* the alert.

**Optional, one-time hardening — independent 2nd alert channel (Cloud Monitoring):** so a dead/broken
scheduler can't also silence the DML alarm. Full 5-step console procedure (enable BigQuery Data
Access audit logs → build the Logs Explorer filter → create a logs-based alert policy → optional
fire-drill to confirm the exact audit-log field names → document the finished policy in
`infra/terraform/monitoring.tf` as spec) is written out in `ops/RUNBOOK.md` §15, "2nd channel (owner
action, one-time, Cloud Monitoring console)". Not required for the primary channel (step 1-4 above) to
work; do this whenever convenient.

---

## 3. GCP IAM grant — let CI self-heal a missed `ops.run_log` write (Item 3, RUNBOOK §38)

**What it's for:** closes the 2026-07-06..08 incident class where a routine's real output lands on
`main` but its `ops.run_log` completion write never happens (harness session-lifecycle issue, not a
repo bug — root cause is outside this repo's visibility). The fix already runs today as a **manual**
backfill when caught; this grant lets CI do it **automatically** on every merge instead.

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.routine_commit_markers
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*`
(it already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds
write access to exactly one table). It cannot reach `ops.run_log` or `ops.alerts` directly — only
`ops.sp_backfill_run_log_from_markers()` (run under your own identity, like every other procedure)
actually writes those, off the marker rows this grant lets CI insert.

**If skipped:** no functional loss today. `auto-merge-claude.yml`'s marker-write step no-ops/warns
cleanly without this grant, and the existing manual-backfill fallback (`ops.sp_backfill_run_log_from_markers()`
called by hand, or by the nightly `cadence_check.sql` pass) is fully intact either way — this grant
only removes the "manual" part.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_routine_commit_markers_editor`, purely so its blast
radius is reviewable in-repo before you run the command above — per the standing Terraform-is-spec-only
decision (`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

---

## 4. Elect (or confirm) your IBKR cost-basis method (Item 18)

**What changed:** `analytics.tax_lots` / `state.wash_sale_exposure`
(`bigquery/41_tax_lots.sql`) now detect account-wide wash sales (a same-ticker BUY within 30 calendar
days of ANY strategy's loss-realizing SELL — checked across strategies, not just within one, since the
IRS wash-sale rule is a taxpayer-level rule and this system now runs up to 8 independent strategies
that can legitimately trade the same ticker). This is **detection/reporting only** — IBKR's own
1099-B, computed off your account's actual elected method, remains the authoritative tax figure.

**Action:** this repo's lot construction assumes **FIFO** (the typical IBKR default) purely to build
its own internal lots. If you have elected — or ever elect — a different method with IBKR (e.g.
specific-lot ID), say so explicitly (in chat, or by editing `Experiment_Parameters.md`'s tax-lot
caveat note directly) — otherwise `analytics.tax_lots` will silently diverge from your broker's own
lot-by-lot 1099-B accounting (total shares/proceeds still reconcile either way, just not lot-by-lot).
If you're already on FIFO / haven't touched the election, no action needed — this is a "confirm or
correct an assumption," not a blocking requirement.

---

## 5. Read and decide — Agent SDK / headless-harness migration (Item 26, informational)

`ops/spikes/agent-sdk-orchestration-2026Q3.md` is a feasibility report (no repo/live changes) on
moving routines off the interactive claude.ai web-UI onto a headless, scheduled harness. Bottom line:
**conditional GO for a D1-only pilot** (read/judgment-only, no IBKR orders), **unconditional NO-GO**
for anything that calls the IBKR connector until a separate spike resolves headless IBKR auth (no
first-party OAuth path exists today; the unofficial local-execution-only community IBKR MCP servers
are explicitly unsuited for real-money order placement without a dedicated security review this spike
doesn't attempt). This is a **decision for you, not an action required** — nothing changes unless you
say to proceed with the D1 pilot. Item 29 (a "thin order gateway" for mechanically enforcing the
order-guard before every IBKR order) is downstream of this and stays closed (see `ops/RUNBOOK.md` §40)
until this spike's IBKR gap is separately resolved.

---

## Not an owner action — flagged for the record

- **Item 30b** (deferred, not attempted this pass): collapsing the routine-list hand-copy-then-CI-check
  pattern across `bigquery/12/15/24` + `Claude_Task_Plan.md`'s ROUTINE INVENTORY table into a
  generator off `ops/cadence.yaml`. Genuine refactor with real risk of breaking the cadence-consistency
  CI gate if rushed — explicitly scoped as a future engineering follow-up, not something you need to
  do or decide.
- **`AI_Trading_Foundation.md`'s in-use-Claude-version field** (Item 30a) is now flagged rather than
  silently overwritten (this repo can't query which model a web-UI session actually ran on) — it will
  resolve itself via the document's own existing version-change protocol at the next Q3/A1 cycle; no
  action needed from you specifically.

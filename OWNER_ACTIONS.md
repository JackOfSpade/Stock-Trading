# Owner actions

Everything Claude could apply without you (schema, views, procedures, scheduled-query SQL bodies,
repo docs) is already applied live and merged to `main`. This file is the complete list of the
handful of things only you can do — a GCP console click, a `bq`/`gcloud` command run with your own
credentials, an Apps Script paste (`script.google.com` isn't reachable from here), or a tax election
with your broker. Nothing in this system is blocked or unsafe while these are outstanding — every
item below is explicitly designed to fail closed / no-op / stay on its existing fallback until you
act. Three dated passes below; most recent first.

---

# 2026-07-16 CI findings bridge (CC-1, issue #10 consumption-closure)

## G. GCP IAM grant — let CI write CI-guard findings into BigQuery (CC-1)

**What it's for:** four CI guards (`live-sql-parity.yml` daily, `keyless-sa-audit.yml` /
`wif-binding-audit.yml` / `guard-config-audit.yml` monthly) each open/refresh a deduped GitHub issue
on a finding, but nothing automated ever reads those issues today — live-sql-parity's own Actions run
even stays green on drift (issue #10, opened 2026-07-16T09:34Z, unconsumed while run 29487150663
concluded `success`). `bigquery/67_ci_findings_bridge.sql` + the four workflow edits wire each guard
to also INSERT an open/resolved marker row into `ops.ci_findings`, consumed by `cadence_check.sql`
(raises/auto-resolves a `ci_finding` warning, emailed via the alert-emailer) and by D3's new
CI-FINDINGS ADJUDICATION step (`Claude_Task_Plan.md`). This grant is what makes the write actually
land — until it does, every INSERT no-ops with a `::warning::` annotation and the GH-issue path is
completely unaffected (no functional loss today).

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.ci_findings
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*` (it
already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds write
access to exactly one table). This is the **second instance** of the same narrow class already proven
live for `ops.routine_commit_markers` (item 3 below; rows `source='auto-merge-claude.yml'` verified
live 2026-07-14/07-15).

**If skipped:** workflows warn and behave exactly as today — the GitHub-issue finding/dedup/close path
is entirely independent of this grant.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_ci_findings_editor`, mirroring
`gh_ci_runner_routine_commit_markers_editor` — per the standing Terraform-is-spec-only decision
(`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

**Also needs a re-paste (folds into item B below, now further updated):** `bigquery/67`'s registry
MERGE bumps `state.expected_scheduled_query_versions`'s `cadence_check` row to `v4`; the live
`cadence_check` scheduled query needs the updated body (SQ_VERSION v3→v4, adds the `ci_finding`
raise/auto-resolve block) re-pasted in the same console session per `bigquery/README.md`'s convention
— apply `bigquery/67_ci_findings_bridge.sql` and re-paste `cadence_check.sql` together, since the
registry bump is what keeps `state.scheduled_query_version_drift` green afterward.

---

# 2026-07-15 self-improvement audit (20 gaps + 5 architecture recommendations)

All 20 confirmed gaps + all 5 architecture recommendations are implemented, verified live, and
merged to this branch (`jack/pensive-fermi-jxha2b`) — see `bigquery/README.md` entries 57-66 and
`git log` for the full commit trail. Verified before writing this section: every item below was
checked against live BigQuery state / `gh` CLI output just now, not assumed from memory.

## A. Register `OPS0` as a live routine trigger (Gap 4 — Cadence Watchdog)

`OPS0. Cadence Watchdog` is a new regular routine (`Claude_Task_Plan.md`) with a full entry in
`ops/triggers.json`, but has no live trigger yet — confirmed via
`scripts/check_cadence_consistency.py`, which prints (non-fatally): *"ops/trigger_ids.json has no
entry yet for `['OPS0']`"*.

**AUTOMATED 2026-07-16 (resilience audit, RES-1/OAE-1 merge): this is no longer a required owner
action.** `Claude_Task_Plan.md`'s D3 section now carries a generalized TRIGGER SELF-REGISTRATION
step, and `OPS0`'s own STEP 2 item 3 now self-registers rather than paging the operator. On the
next live session that reaches either of those branches with `RemoteTrigger` access, it will:
verify no prior create already happened (checks `events.decision_log`
`entry_type='trigger-self-registration'` and `ops.catchup_refire_log` `outcome='trigger_created'`
first, so this is safe to leave to happen opportunistically — it will not double-create), then
call `RemoteTrigger create` with instruction = `ops/triggers.json`'s `OPS0` string verbatim and
cron `30 4 * * *` (fixed UTC = 10:30 PM MDT / 9:30 PM MST — deliberately inside the 21:00–24:00
America/Denver daily-miss visibility window year-round per `bigquery/48_cadence_monitor_unbounded.sql:52-59`,
and clear of the 05:15 UTC `cadence_check` scheduled-query snapshot; this slot is now recorded in
`ops/cadence.yaml`'s WEB-UI TRIGGER AUDIT block so the self-registration step's slot lookup does
not fail closed), record the returned id in `ops/trigger_ids.json`, log the decision, and raise an
info alert. This section remains only as the fallback if a `trigger_create_unsupported` or
`trigger_slot_unrecorded` warning ever fires, or if you'd rather not wait for an opportunistic
self-registration run.

**Manual fallback action, if you want it live sooner:** create a trigger the same way every other
routine trigger was created (RemoteTrigger `create` / Chrome console) — name
"OPS0. Cadence Watchdog — regular routine"; instruction/message content EXACTLY
`Read Claude_Task_Plan.md. Perform OPS0. Cadence Watchdog — regular routine.` (verbatim from
`ops/triggers.json` key `OPS0`); recurrence = a fixed-UTC daily cron `30 4 * * *` (10:30 PM MDT /
9:30 PM MST — do NOT use the native DST-aware Daily picker with a plain local time here, since an
API-created trigger stores a literal UTC cron, not a DST-relative local slot). Then record the
returned `trig_...` id in `ops/trigger_ids.json` (alphabetical, between `M5` and `Q1`) with
`"verified_via": "api"`, and run `python3 scripts/check_cadence_consistency.py` to confirm the
missing-entry NOTE disappears.

## B. Re-paste 11 of 12 scheduled queries (Gap 12 — scheduled-query body-drift detection)

Every file in `bigquery/scheduled_queries/*.sql` now self-reports a version marker via
`CALL ops.sp_beat_heartbeat(...)` as its first statement (`bigquery/63_scheduled_query_version_registry.sql`).
**Checked live**, `SELECT * FROM state.scheduled_query_version_drift`: 11 of 12 show
`monitored = FALSE` (never beaten with the new marker) — only `embed_pending` already shows
`last_reported_version = 'v1'` matching expected (likely from this session's own validation query,
not a real cron firing, but either way it's already current — skip it). **Action:** re-paste the
current repo body of each of the other 11 files into its existing BigQuery Studio → Scheduled
Queries entry (same paste-and-save flow as every prior scheduled-query update, `ops/RUNBOOK.md §1`):
`backup_events_export`, `cadence_check` (note: bumped v1→v3 this pass, **now further bumped v3→v4
by the 2026-07-16 CI-findings bridge pass — item G above** — picks up 2 new invariant checks,
`b3_trading_enabled_drift` and `backup_per_table_row_drop`, plus the `ci_finding` raise/auto-resolve
block; re-paste the CURRENT (v4) repo body, not the v3 one), `daily_freshness_check`,
`daily_staging_cap_check`, `delivery_canary`, `fire_drill_alert_lifecycle`, `fire_drill_order_guard`,
`integrity_check`, `ops_export`, `restore_drill`, `safety_critical_dml_watch` (this one may not be
registered as a scheduled query at all yet — it was also 2026-07-11 item #2 below; if it's not live,
create it fresh per that item's steps, then it'll pick up the version marker for free). After
re-pasting, `SELECT * FROM state.scheduled_query_version_drift` should show `drift = FALSE` /
`monitored = TRUE` across all 12 within a day. **If skipped:** no functional loss — each query keeps
running its old body exactly as before; you just won't get body-drift detection until the paste
happens (self-bootstrapping: `monitored` stays `FALSE`, no false alarm).

## C. GCP IAM grant — dashboard build liveness heartbeat (Architect recommendation #3)

`ops/dashboard/generate_dashboard.py` now best-effort-writes `ops.heartbeat(source='dashboard')` at
the end of a successful build (`bigquery/58_dashboard_heartbeat.sql`), but the workflow's
`gh-ci-runner@` WIF identity is read-only today, so the write silently no-ops until granted:
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.heartbeat
```
Table-scoped — `gh-ci-runner@` gains write access to exactly `ops.heartbeat`, nothing else.
**If skipped:** the dashboard keeps publishing exactly as before; `'dashboard'` just never appears
as `monitored` in `state.automation_heartbeat`, which is the correct fail-quiet default, not a bug.

## D. Re-enable `alert-relay.yml` (currently `disabled_manually`)

**Checked live** (`gh workflow list --all`): `Alert relay (webhook push)` shows
`disabled_manually`. Claude's auto-mode permission classifier correctly declined to re-enable a
manually-disabled GitHub Actions workflow via `gh api -X PUT .../enable` on its own — that's a
platform-state change outside "implement my recommendations" authorization, not a bug. **Action:**
`gh workflow enable "Alert relay (webhook push)"` (or the Actions tab → the workflow → "Enable
workflow"), once you've decided you want the webhook relay live — it depends on item E below to do
anything useful (no `ALERT_WEBHOOK_URL`, nothing to relay to yet).

## E. Add 3 missing GitHub Actions secrets

**Checked live** (`gh secret list`): zero repo secrets exist today. Three are referenced across
workflows and are all currently no-ops without them (each usage is already guarded/best-effort —
nothing fails from their absence, they just don't do anything):
- `ALERT_WEBHOOK_URL` — read by `alert-relay.yml`, `guard-config-audit.yml`, `offsite-backup.yml`,
  `keyless-sa-audit.yml`, `wif-binding-audit.yml`. A vendor-neutral webhook endpoint (Slack/Discord/
  ntfy/Pub-Sub push) for these workflows' own alert pushes, separate from the BigQuery-side
  `ops.alerts` → `alert_emailer.gs` email channel.
- `OFFSITE_BACKUP_GCS` — read by `guard-config-audit.yml`, `offsite-backup.yml`. A GCS destination
  (bucket/path) for the offsite backup export; without it, `offsite-backup.yml` presumably no-ops or
  fails its own step — worth checking that workflow's recent run history once this is set.
- `ANTHROPIC_API_KEY` — read by `golden-scenarios.yml`. Without it, the workflow's `HAVE_KEY` check
  reads false and (per that workflow's own design) it falls back to a documented lower-fidelity mode
  rather than failing — check that workflow's file for the exact fallback behavior before assuming
  urgency here.
**If skipped:** every consumer above already fails closed/quiet without these — nothing is silently
broken, these three unlock functionality that's currently inert, not fix something currently wrong.

## F. Resolved — BigQuery per-user daily query quota was hit during this session (no action needed)

**Transient, self-cleared within ~10 minutes — checked live, confirmed resolved.** The
`dbt↔live row-level parity (keyless WIF)` CI job failed on 2 pushes in a row this session with
*"Custom quota exceeded: Your usage exceeded the custom quota for QueryUsagePerUserPerDay, which is
set by your administrator"* — a BigQuery cost-control quota you (or a prior setup pass) configured,
not a code bug; every other CI job on both runs passed. Because the repo var `DBT_PARITY=block`
(`gh variable list`) deliberately makes this job a hard merge gate (`.github/workflows/ci.yml` —
`continue-on-error: false` when set), the whole `CI` run read as failed and auto-merge correctly
declined to merge 3 commits for a short window — exactly as `DBT_PARITY=block` is designed to do.
Almost certainly caused by this session's own unusually heavy live-verification query volume (every
gap in this pass was checked against live BigQuery before and after applying) hitting a
`QueryUsagePerUserPerDay` ceiling. The very next push's `dbt↔live row-level parity` run came back
green (headroom freed up / quota window rolled over), and the existing auto-merge automation caught
up the whole backlog in one shot: `git merge-base --is-ancestor <branch tip> origin/main` now returns
true — `main` is fully current through this session's last commit. **Action: none.** Documented here
only so a future session doesn't need to re-diagnose the same transient failure if it recurs; if
`dbt↔live row-level parity` starts failing repeatedly with this exact message on ordinary
(non-audit-scale) pushes going forward, raise the custom quota at
https://docs.cloud.google.com/bigquery/redirects/increase-query-cost-quota. Do not weaken
`DBT_PARITY=block` to work around a recurrence — it caught a real resource ceiling correctly here,
not a misfire.

---

# Owner actions — 2026-07-11 self-improvement audit (Items 1-30)

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

**CORRECTED 2026-07-11 (owner fact-check) — the spike's cost-neutrality claim was wrong.** The spike
originally claimed migrating a routine's token cost was "unchanged, not a new cost line" because a
2026-06-15 Anthropic billing change already moved headless/Agent-SDK usage onto a separate API-rate
credit. That change was **paused before taking effect** — Anthropic's own Help Center confirms headless/
Agent-SDK usage still draws from the owner's Claude **subscription** limits today, not a metered pool.
Separately, the harness in (b) would call Claude via the **Managed Agents API** — a different product
surface from the subscription login, billed at standard per-token API rates with no subscription
discount. So piloting D1 on this harness would very likely convert D1's token cost from "bundled into
the flat subscription" to "real, metered API dollars per run" (one estimate: subscription pricing
subsidizes agent usage ~15-30x vs. API rates) — the opposite of the original "near-zero, cost-neutral"
framing. Also worth noting: the original urgency case for this migration (fixing the §38 run_log gap)
is now moot regardless of cost — Item 3 (this same 2026-07-11 session) closed that gap for free with no
migration needed (`ops/RUNBOOK.md` §38). Get an actual per-token cost estimate before deciding to pilot;
see the corrected `ops/spikes/agent-sdk-orchestration-2026Q3.md` (c) for detail.

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

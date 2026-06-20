# Owner / Claude-in-Chrome action queue

Everything that can't be done from a Claude **remote routine** (no GCP console, no terminal,
no Apps Script deploy from here) — with a ready-to-paste **Claude-in-Chrome** prompt where a
browser can do it, and owner/terminal steps where it can't. Ordered by leverage. Detail for
each lives in `ops/RUNBOOK.md` (section refs below).

Escalation order (your rule): _remote Claude → Claude-in-Chrome → you_. Items marked
**[Chrome-able]** can be driven by Claude-in-Chrome logged into your Google/GitHub; items marked
**[Terminal]** need `terraform`/`gcloud` from your machine (a browser can't run them).

---

## 1. Deploy the weekly report email  ·  [Chrome-able or you, ~3 min]  ·  RUNBOOK §18
The infographic you approved. Self-contained Apps Script — reads BigQuery, self-emails weekly,
no drafts, no Claude routine. Files: `ops/weekly_report/`.

Steps (full version in `ops/weekly_report/README.md`):
1. script.google.com → New project → paste `ops/weekly_report/weekly_report.gs`.
2. Editor → **Services (+)** → add **BigQuery API**.
3. Project Settings → set timezone **America/Denver**.
4. Run `testReport` → approve BigQuery + Gmail scopes → confirm the email arrives.
5. Run `installWeeklyTrigger` (Sunday 07:00). Done.

**Claude-in-Chrome prompt:**
```
Open script.google.com and create a new Apps Script project named "Stock-Trading Weekly Report".
Replace Code.gs with the contents of ops/weekly_report/weekly_report.gs from my Stock-Trading repo
(github.com/JackOfSpade/Stock-Trading). Add the BigQuery advanced service (Services → BigQuery API).
Set the project timezone to America/Denver in Project Settings. Run testReport(), authorize the
BigQuery + Gmail scopes when prompted, and confirm the test email arrived in my inbox. Then run
installWeeklyTrigger() to schedule the Sunday 07:00 send. Report back the trigger it created.
```
> Delete the one sample draft I created earlier (Gmail → Drafts) — the connector has no delete tool. The live design never creates drafts.

## 2. Deploy the alert emailer (A2 — real alert delivery)  ·  [Chrome-able or you, ~2 min]  ·  RUNBOOK §7
Polls `ops.alerts` every 2h and emails you on a new unresolved critical/warning (push channel
between routines; complements the [Claude] ATTENTION calendar events). File:
`ops/monitoring/alert_emailer.gs`. Same setup as #1 (can be a 2nd file in the SAME script project).

**Claude-in-Chrome prompt:**
```
In my "Stock-Trading Weekly Report" Apps Script project, add a new file alert_emailer.gs with the
contents of ops/monitoring/alert_emailer.gs from my Stock-Trading repo. Run testAlertCheck() to
authorize, confirm it logs "No new alerts" (or emails any open ones), then run installAlertTrigger()
to schedule the every-2-hours check. Report the trigger created.
```

## 3. Arm the control plane — scheduled queries (A0)  ·  [Terminal preferred; Chrome fallback]  ·  RUNBOOK §1
**Highest-leverage automation item.** The 4 dead-man's-switch queries (freshness 05:00, cadence
05:15, embed 06:00, backup 05:30 UTC) only run when armed. Today they fire only if a session calls
them — a skipped session is silent drift.

**[Terminal] (owns it cleanly via IaC):**
```
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars   # set project_id, schedules, notification email
terraform init
terraform apply    # creates freshness_check, cadence_check, embed_pending, backup_export
```
Then verify in BigQuery → Scheduled queries that all 4 exist and `enable_failure_email=true`.

**[Chrome-able] fallback (no terraform):** create the 4 scheduled queries by hand in the BigQuery
console, pasting each body from `bigquery/scheduled_queries/*.sql`, schedule per the headers, and
tick "Send email notifications" on failure.
```
Open console.cloud.google.com BigQuery → Scheduled queries (project stock-trading-498512). Create
four scheduled queries, one per file in bigquery/scheduled_queries/ of my repo: daily_freshness_check.sql
(daily 05:00 UTC), cadence_check.sql (daily 05:15), embed_pending.sql (daily 06:00),
backup_events_export.sql (daily 05:30). Region US. Paste each file's SQL as the query. Enable
"Send email notification on failure". Confirm all four are created and Enabled.
```

## 4. Split operational identity (A1)  ·  [Terminal/Console]  ·  RUNBOOK §15
Today the watchdog queries would run under the single human OAuth identity — the alarm dies with
the thing it watches. Run the scheduled queries under a dedicated **service account** instead.
1. Create SA `bq-scheduler@stock-trading-498512.iam.gserviceaccount.com`; grant `roles/bigquery.dataEditor`
   + `roles/bigquery.jobUser` (+ `roles/storage.objectAdmin` on the backup bucket for the export).
2. Set `var.backup_transfer_service_account` (and the same on the other configs) and re-`terraform apply`,
   OR in the console set each scheduled query's "Service account" to it.
Detail + the WIF variant in RUNBOOK §15.

## 5. Terraform remote state backend (A3)  ·  [Terminal]  ·  RUNBOOK §12
State currently lives on local disk only — an SPOF for the IaC↔live-datasets mapping.
```
gsutil mb -l US -b on gs://stock-trading-tfstate && gsutil versioning set on gs://stock-trading-tfstate
# then uncomment the backend "gcs" block in infra/terraform/versions.tf (bucket = that name) and:
cd infra/terraform && terraform init -migrate-state
```
(The commented block is already in `versions.tf` with these exact instructions.)

## 6. Looker Studio dashboard (A4)  ·  [Chrome-able]  ·  RUNBOOK §16
Keep GitHub Pages publishing OFF (`vars.PUBLISH_DASHBOARD` unset — a personal repo's Pages is
public even when the repo is private). Use Looker Studio (Google-auth gated) instead.
```
Open lookerstudio.google.com → Create → Data source → BigQuery → project stock-trading-498512.
Build a private dashboard with: state.system_health (one-row health), analytics.strategy_scorecard
(per-strategy table), state.account_latest (NAV/TWR), perf.strategy_daily (TWR time series),
ops.alerts (unresolved). Keep sharing restricted to my account only. Send me the report link.
```

## 7. Heartbeat-of-the-heartbeat (A5)  ·  [Chrome-able]  ·  RUNBOOK §1
The freshness email proves liveness only if the scheduler runs at all. Add a Cloud Monitoring
alert on the *absence* of the daily run so silent scheduler death is itself an alarm.
```
Open Cloud Monitoring (console.cloud.google.com/monitoring, project stock-trading-498512). Create
a log-based metric on the freshness scheduled-query job completion, then an alert policy that fires
if the metric is ABSENT for >26 hours. Notification channel: email to me. Also create an alert policy
on a log-based metric counting rows in ops.alerts where severity=critical AND not resolved.
```

## 9. Re-paste cadence_check.sql — activate W2 trigger-drift detection  ·  [Chrome-able, 1 min]  ·  RUNBOOK §1
`bigquery/scheduled_queries/cadence_check.sql` was extended to also alert on web-UI trigger drift
(via `state.instruction_drift` / `ops.routine_catalog`, both already live). The live "cadence-check-daily"
scheduled query still has the old body, so re-paste the updated file once.
```
Open BigQuery → Scheduled queries (project stock-trading-498512) → cadence-check-daily → Edit. Replace
its query with the current contents of
github.com/JackOfSpade/Stock-Trading/raw/main/bigquery/scheduled_queries/cadence_check.sql and Save.
(It gains a warning-level alert when a routine's live trigger text drifts from the canonical catalog.)
```

## 10. (Optional) dbt row-level parity CI — finish D1  ·  [Terminal/CI]  ·  RUNBOOK §6/§14
The dbt mirrors for all views (incl. the 4 new ones) are committed and `dbt parse` validates them
structurally in CI. To add *row-level* parity (catch logic drift between `bigquery/*.sql` and the dbt
models), add a CI job — gated on the WIF repo vars like the dashboard workflow — that, with **read-only**
WIF, `dbt compile`s each model and runs `(compiled SELECT) EXCEPT DISTINCT (live view)` **both ways**,
expecting 0 rows. Use compile+EXCEPT (read-only), NOT `dbt build` to the live datasets — the
`generate_schema_name` override pins models to the bare `state`/`perf`/`analytics` datasets, so a build
would overwrite live objects. Owner bit: set `GCP_WIF_PROVIDER` + `GCP_WIF_SERVICE_ACCOUNT` (read-only SA).

## 8. Disaster-recovery mirror for the event store (D5)  ·  [Terminal/Console]  ·  RUNBOOK §3
Backups are Parquet to one US-multiregion bucket. Add a second-location mirror + do one restore drill.
1. Create a bucket in a different location (e.g. `gs://stock-trading-backups-eu`, EU) with versioning.
2. Add a daily transfer (Storage Transfer Service) from the primary backup bucket to it, OR a second
   `backup_events_export` config writing there.
3. **Restore drill (once):** load one Parquet day back into a scratch dataset and diff row counts vs
   `events.*`. Document the result in RUNBOOK §3.
(HF-dataset mirror was considered but the HF connector is read-only — no upload tool — so GCS-to-GCS
is the practical path.)

---

## Repo-side fixes — now DONE (committed to the branch)
All repo-implementable findings are shipped; only the owner micro-actions above remain to fully activate them:

- ✅ **W1 + W3 — routine prompts modernized** (BigQuery-native; redirect map retired; single date
  source `state.trading_day_today`, bash/`currentDate` fallbacks removed).
- ✅ **W5 — order-intent invariant** — dbt tests `assert_open_orders_no_stale_pending` +
  `assert_open_orders_actionable` guard the staged-order registry; D3 already reconciles registry↔calendar.
- ✅ **W2 — trigger-drift alarm** — `ops.routine_catalog` + `state.instruction_drift` (live);
  `cadence_check.sql` extended to alert on drift. **Activate via #9 above** (re-paste the body).
- ✅ **D1 — dbt mirrors** for the 4 new views (`strategy_scorecard`, `weekly_activity`,
  `account_latest`, `account_snapshot` source) + schema/tests; `dbt parse` validates structure.
  **Optional #10 above** adds row-level parity.

## Findings NOT actioned (by design)
- **D4 (un-ignore `state_snapshots/`)** — REJECTED. The `.gitignore` entry is a deliberate security
  control (committing it would expose live positions/NAV if repo visibility ever changed). The
  immutable change-trail already exists in the BigQuery event tables. Leave gitignored.

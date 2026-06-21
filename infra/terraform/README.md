# Terraform — Stock-Trading GCP infrastructure (IaC)

Codifies the GCP infrastructure for the BigQuery-based trading system as
version-controlled Terraform (analysis recommendations **A1 + A4**: move the
scheduled queries and the GCP resources out of the Console and into IaC).

Project: **`stock-trading-498512`** · BigQuery/GCS location: **US** (multi-region).

Cross-reference: **`ops/RUNBOOK.md`** (the manual Console steps this replaces:
scheduled queries §1, budget §2, GCS backup bucket §3) and
**`bigquery/scheduled_queries/README.md`** (the scheduled-query bodies + UTC-timing
rationale, reproduced below).

> **STATUS (2026-06-21): declared spec / reference only — NOT applied.** This module has
> never been imported or applied (`terraform state list` against the backend is empty),
> and per a deliberate decision (**RUNBOOK §12**, **CLAUDE.md "Settled decisions"**) it
> stays that way — the live infra is managed out-of-band via the BigQuery MCP + console.
> Read the import/apply instructions below as the reference procedure for a *hypothetical
> future* adoption, **not** as a recommended next step.

---

## What this codifies

| File | Resource(s) | Notes |
|---|---|---|
| `versions.tf` | Terraform `>= 1.5`, `google` + `google-beta` `~> 5.0`, providers; **backend commented out** | Owner picks the GCS state bucket. |
| `variables.tf` | All inputs (project, region, schedules, budget, emails) | Defaults encode the known project facts. |
| `datasets.tf` | `events`, `state`, `perf`, `analytics`, `ops` BigQuery datasets | **Already exist — import.** `prevent_destroy`. |
| `connection.tf` | `us.vertex` CLOUD_RESOURCE connection | **Already exists — import.** Outputs its SA. |
| `scheduled_queries.tf` | 4 scheduled queries (freshness, embed, backup, **new** cadence) | SQL bodies single-sourced via `file()`. Run under `var.scheduled_query_service_account` (RUNBOOK §15). |
| `storage.tf` | `gs://stock-trading-backups` bucket (400-day lifecycle) | **Already exists — import.** `prevent_destroy`. |
| `budget.tf` | Billing budget + email channels | **Optional** (guarded on `billing_account`). |
| `monitoring.tf` | `freshness_scheduled_run` log metric + "scheduler absent >25h" alert | **Already exists in Console — import.** Identity-agnostic filter (RUNBOOK §19). |
| `iam.tf` | `storage.objectAdmin` on the bucket for the backup SA | Only for the dedicated-SA backup path. |
| `terraform.tfvars.example` | Example values | Copy to `terraform.tfvars`. |

### Dashboard (RUNBOOK §4) — not a Terraform resource

The operator dashboard is **built in CI / served from GitHub Pages**, not by
Terraform. There is intentionally no `dashboard.tf`: `ops/dashboard/generate_dashboard.py`
produces a self-contained `ops/dashboard/index.html` (or use a Looker Studio report
over `state.system_health` etc.). See `ops/RUNBOOK.md §4`. If a Looker Studio data
source or Pages config ever needs codifying, add it here, but today there is
nothing GCP-side to manage.

---

## Most resources ALREADY EXIST — import first

This module is written to **adopt** the live infrastructure, not rebuild it. The
datasets, the Vertex connection, and the backup bucket were created out-of-band
(via `bigquery/01_schema.sql`, `02_ai_layer.sql`, and RUNBOOK §3). Run these
`terraform import` commands **before** the first `plan`/`apply` so Terraform takes
over the existing objects instead of trying to create duplicates:

```bash
cd infra/terraform
terraform init

# Datasets (id = projects/<project>/datasets/<dataset_id>)
terraform import google_bigquery_dataset.events    projects/stock-trading-498512/datasets/events
terraform import google_bigquery_dataset.state     projects/stock-trading-498512/datasets/state
terraform import google_bigquery_dataset.perf      projects/stock-trading-498512/datasets/perf
terraform import google_bigquery_dataset.analytics projects/stock-trading-498512/datasets/analytics
terraform import google_bigquery_dataset.ops       projects/stock-trading-498512/datasets/ops

# Vertex CLOUD_RESOURCE connection (note: lowercase "us" in the path)
terraform import google_bigquery_connection.vertex \
  projects/stock-trading-498512/locations/us/connections/vertex

# GCS backup bucket (id = bucket name)
terraform import google_storage_bucket.backups stock-trading-backups
```

If you ALSO already created the scheduled queries in the Console, either import
each one or delete the Console copies so Terraform owns them (avoids duplicate
configs). Find their ids and import:

```bash
bq ls --transfer_config --transfer_location=us            # list config ids
terraform import google_bigquery_data_transfer_config.freshness_check \
  projects/<PROJECT_NUMBER>/locations/us/transferConfigs/<config-id>
# ...repeat for embed_pending / backup_export / cadence_check
```

The Console-built **heartbeat monitor** (`monitoring.tf`) is also pre-existing —
adopt it so Terraform owns the fix for the 2026-06-20 false alarm (RUNBOOK §19).
Easiest path is the helper (idempotent; discovers the policy/channel ids via
`gcloud`), run after `terraform import google_bigquery_data_transfer_config.freshness_check …`
(monitoring.tf derives the metric's `config_id` from it) and after setting
`notification_emails` in `terraform.tfvars`:

```bash
./import_monitoring.sh && terraform plan        # expect 0 changes
```

Or import the three resources by hand:

```bash
terraform import google_logging_metric.freshness_scheduled_run freshness_scheduled_run
# find the policy id: gcloud alpha monitoring policies list --format='value(name)'
terraform import google_monitoring_alert_policy.freshness_scheduler_absent \
  projects/<PROJECT_NUMBER>/alertPolicies/<policy-id>
# find the channel id: gcloud alpha monitoring channels list --format='value(name)'
terraform import 'google_monitoring_notification_channel.scheduler_alert_email["jacksterwu@gmail.com"]' \
  projects/<PROJECT_NUMBER>/notificationChannels/<channel-id>
```

> **The metric should now import CLEAN** (no diff): the live filter was repointed to
> the terminal-agnostic `^Summary: succeeded` marker on 2026-06-21 (RUNBOOK §19), which
> is exactly what `monitoring.tf` declares. The policy is a PromQL
> `absent_over_time(...[25h])` condition — codified as such. If `plan` still proposes a
> diff, reconcile the `.tf` to the live value rather than the reverse (the live monitor
> is the verified-good state).

After importing, a clean run shows **~no changes**:

```bash
terraform plan      # expect: 0 to change for imported resources
                    #         (new resources: only the scheduled queries you did
                    #          NOT already create, + budget/iam if enabled)
terraform apply
```

> If `plan` proposes changing an imported dataset/bucket (e.g. a lifecycle age or
> a description), reconcile by editing the `.tf` to match what is live — the goal
> is idempotent adoption, not mutation of the trading data substrate.

---

## SQL bodies are single-sourced

The scheduled-query SQL is **never** duplicated into Terraform. `scheduled_queries.tf`
reads each body with `file()`:

- freshness → `../../bigquery/scheduled_queries/daily_freshness_check.sql`
- embed     → `../../bigquery/scheduled_queries/embed_pending.sql`
- backup    → `../../bigquery/scheduled_queries/backup_events_export.sql`
- cadence   → `../../bigquery/scheduled_queries/cadence_check.sql` (the NEW A1/A4
  query; its backing view `state.cadence_watch` is in `bigquery/12_cadence_monitor.sql`)

So editing a body in `bigquery/scheduled_queries/` and re-applying updates the live
scheduled query — one source of truth.

### Email on failure

The freshness, backup, and cadence queries RAISE on a problem. Each config sets
`email_preferences { enable_failure_email = true }`, which is the Terraform
equivalent of the Console's "Send email on failure" toggle (RUNBOOK §1). This is
**not** Pub/Sub — `notification_pubsub_topic` is deliberately left unset; the RAISE
+ failure-email is the whole alert path (no extra infra).

---

## Why 05:00 UTC for the freshness check (UTC-timing rationale)

> Copied from `bigquery/scheduled_queries/README.md`:
>
> **BigQuery schedules run in UTC** (the Console's local-time label is misleading).
> The freshness check must run in the **Denver evening, after D2** has ingested the
> close. `05:00 UTC ≈ 22:30 MDT / 21:30 MST` — same Denver day, after D2, in both
> DST regimes. Do **NOT** use `21:30 UTC` (= 15:30 MDT = *before* D2):
> `state.system_health` keys off `CURRENT_DATE('America/Denver')`, so a pre-D2 run
> would see today's marks missing and false-alarm every trading day. On
> weekends/holidays it stays green automatically (`last_trading_day` is the prior
> close, already ingested).

The other UTC schedules follow from this: embed ~06:00 (timing irrelevant —
idempotent), backup ~05:30 (after the freshness check), cadence ~05:15 (between the
two, same evening-after-D2 logic — it no-ops on non-trading days).

---

## Caveats / owner decisions

- **`billing_account`** has no default — supply it (or leave `""` to skip the
  budget). The budget is otherwise fully optional.
- **State backend** (`versions.tf`) is commented out — pick a private, versioned
  GCS bucket; module state references live trading datasets, keep it out of git.
- **Backup identity** (`iam.tf`): the default/simplest path runs the backup under
  the **owner's own credentials** (no IAM needed). The `storage.objectAdmin`
  member is only for a dedicated-SA path; set `backup_transfer_service_account` to
  use it.
- **Vertex connection IAM** (`roles/aiplatform.user`) is granted out-of-band per
  `02_ai_layer.sql` and is **not** managed here, to avoid fighting the existing setup.

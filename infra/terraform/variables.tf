###############################################################################
# Input variables
#
# Defaults encode the known PROJECT FACTS for stock-trading-498512 so a plain
# `terraform plan` works out of the box. The only value with no default is
# `billing_account` (owner-specific) — the budget in budget.tf is guarded so the
# module still plans/applies without it.
###############################################################################

variable "project_id" {
  description = "GCP project id that owns the BigQuery + GCS trading infrastructure."
  type        = string
  default     = "stock-trading-498512"
}

variable "region" {
  description = <<-EOT
    BigQuery / GCS multi-region location. The whole system lives in the US
    multi-region (see bigquery/01_schema.sql and bigquery/README.md). This is a
    BigQuery LOCATION ("US"), not a single compute region like "us-central1".
  EOT
  type        = string
  default     = "US"
}

variable "backup_bucket_name" {
  description = <<-EOT
    Name (no gs:// prefix) of the GCS bucket the events backup export writes to.
    Matches gs://stock-trading-backups from ops/RUNBOOK.md §3.
  EOT
  type        = string
  default     = "stock-trading-backups"
}

variable "budget_amount_usd" {
  description = <<-EOT
    Monthly budget cap (USD) for the project. Vertex embeddings / Gemini /
    AI.FORECAST are the only billed pieces and are pennies, but the unattended
    scheduled jobs should be capped (ops/RUNBOOK.md §2). Used only when
    billing_account is set.
  EOT
  type        = number
  default     = 5
}

variable "billing_account" {
  description = <<-EOT
    Billing account id (format "XXXXXX-XXXXXX-XXXXXX") the project is billed to.
    REQUIRED to create the budget — there is no sensible default, so when this is
    "" the entire budget.tf is skipped (count = 0). Find it with:
      gcloud billing projects describe stock-trading-498512 \
        --format='value(billingAccountName)'
  EOT
  type        = string
  # no default — owner must supply it (or leave "" to skip the budget).
  default = ""
}

variable "notification_emails" {
  description = <<-EOT
    Email addresses that receive budget threshold alerts. Each becomes a Cloud
    Monitoring email notification channel wired into the budget's all_updates_rule.
    Leave empty to create the budget with no extra channels (billing-account
    admins still get the default Billing Console alerts).
  EOT
  type        = list(string)
  default     = []
}

variable "scheduled_query_location" {
  description = <<-EOT
    Location for the BigQuery Data Transfer (scheduled query) configs. Must match
    the dataset location — US — or the scheduled queries cannot read the datasets.
  EOT
  type        = string
  default     = "US"
}

variable "scheduled_query_service_account" {
  description = <<-EOT
    Email (WITHOUT the "serviceAccount:" prefix) of the dedicated service account
    the MONITOR scheduled queries (freshness, embed, cadence) run as. Leave "" to
    run them under the config creator's own OAuth credentials.

    WHY THIS EXISTS (ops/RUNBOOK.md §15 + §19): the dead-man's switches must NOT
    depend on the interactive agent's OAuth identity — if that grant lapses, the
    monitor would die silently *with* the thing it is supposed to watch. Running
    them as an autonomous SA (e.g. "bq-scheduler@stock-trading-498512.iam.gserviceaccount.com")
    keeps the alarm able to fire when the agent identity is the failure.

    NOTE: the backup export has its OWN identity var (var.backup_transfer_service_account)
    because it also needs roles/storage.objectAdmin on the bucket (iam.tf). To put
    ALL four scheduled queries on the same SA — the live 2026-06-19 state — set both
    this and backup_transfer_service_account to the same SA email.
  EOT
  type        = string
  default     = ""
}

# --- Scheduled-query schedules ------------------------------------------------
# BigQuery scheduled-query schedules run in UTC (the Console's local-time label is
# misleading). See bigquery/scheduled_queries/README.md for the UTC-timing
# rationale, especially for the freshness check. Format is BigQuery's
# human-readable schedule string, e.g. "every day 05:00".

variable "freshness_schedule" {
  description = <<-EOT
    Schedule (UTC) for the dead-man's-switch freshness check. 05:00 UTC lands in
    the Denver EVENING after D2 has ingested the close (≈ 22:30 MDT / 21:30 MST) in
    both DST regimes. Do NOT move it earlier (e.g. 21:30 UTC = 15:30 MDT, before
    D2) — system_health keys off CURRENT_DATE('America/Denver') and would
    false-alarm every trading day. See bigquery/scheduled_queries/README.md.
  EOT
  type        = string
  default     = "every day 05:00"
}

variable "embed_schedule" {
  description = <<-EOT
    Schedule (UTC) for the embedding heal. Timing is irrelevant — ops.sp_embed_pending
    is idempotent. 06:00 UTC by default.
  EOT
  type        = string
  default     = "every day 06:00"
}

variable "backup_schedule" {
  description = <<-EOT
    Schedule (UTC) for the events backup export. 05:30 UTC runs after the 05:00
    freshness check. See ops/RUNBOOK.md §3.
  EOT
  type        = string
  default     = "every day 05:30"
}

variable "cadence_schedule" {
  description = <<-EOT
    Schedule (UTC) for the NEW cadence check (the missed-run dead-man's switch:
    alerts when a monitored routine that was expected to run today logged no
    'completed' run — state.cadence_watch.needs_attention, from
    bigquery/12_cadence_monitor.sql). 05:15 UTC runs between the freshness check
    (05:00) and the backup (05:30), same Denver-evening-after-D2 window.
  EOT
  type        = string
  default     = "every day 05:15"
}

###############################################################################
# BigQuery scheduled queries (Data Transfer configs, data_source_id="scheduled_query")
#
# Four configs:
#   (a) freshness check  — the dead-man's switch (daily_freshness_check.sql)
#   (b) embed pending    — embedding heal        (embed_pending.sql)
#   (c) events backup    — EXPORT DATA to GCS    (backup_events_export.sql)
#   (d) cadence check    — NEW; missed-run guard (cadence_check.sql)
#
# SINGLE-SOURCING: every SQL body is read with file() straight from
# bigquery/scheduled_queries/ so the scheduled-query text in BigQuery and the
# paste-ready bodies in the repo can never drift. The cadence check (d) is the
# A1/A4 NEW query; its body + backing view live in bigquery/ (cadence_check.sql,
# backed by bigquery/12_cadence_monitor.sql -> state.cadence_watch).
#
# EMAIL ON FAILURE: the freshness, backup, and cadence queries RAISE on a problem.
# `email_preferences { enable_failure_email = true }` (a real field in the google
# provider's google_bigquery_data_transfer_config) makes BigQuery email the config
# owner when a run fails — this replaces the per-config Console "Send email on
# failure" toggle described in ops/RUNBOOK.md §1. It is NOT a Pub/Sub topic;
# notification_pubsub_topic is intentionally left unset (we want owner email, not
# a Pub/Sub fan-out).
#
# IMPORT: scheduled queries are generated resources; if the owner already created
# them in the Console, either import by their transfer-config id
#   terraform import google_bigquery_data_transfer_config.freshness_check \
#     projects/<num>/locations/us/transferConfigs/<config-id>
# (find ids: `bq ls --transfer_config --transfer_location=us`) or delete the
# Console ones and let Terraform own them. Re-importing avoids a duplicate config.
#
# location = US (var.scheduled_query_location): must match the dataset location.
###############################################################################

# (a) Dead-man's-switch freshness check — emails the owner when system_health is not green.
resource "google_bigquery_data_transfer_config" "freshness_check" {
  project        = var.project_id
  display_name   = "freshness-check-daily"
  location       = var.scheduled_query_location
  data_source_id = "scheduled_query"
  schedule       = var.freshness_schedule

  params = {
    query = file("${path.module}/../../bigquery/scheduled_queries/daily_freshness_check.sql")
    # No destination_table_name_template / write_disposition: this is a scripting
    # body (BEGIN...END) with no SELECT result to land.
  }

  email_preferences {
    enable_failure_email = true
  }
}

# (b) Embedding heal — idempotent; timing irrelevant; no failure email needed.
resource "google_bigquery_data_transfer_config" "embed_pending" {
  project        = var.project_id
  display_name   = "embed-pending-daily"
  location       = var.scheduled_query_location
  data_source_id = "scheduled_query"
  schedule       = var.embed_schedule

  params = {
    query = file("${path.module}/../../bigquery/scheduled_queries/embed_pending.sql")
  }
}

# (c) Events backup export — writes Parquet to gs://stock-trading-backups.
# The transfer SA needs roles/storage.objectAdmin on the bucket (see iam.tf).
resource "google_bigquery_data_transfer_config" "backup_export" {
  project        = var.project_id
  display_name   = "events-backup-daily"
  location       = var.scheduled_query_location
  data_source_id = "scheduled_query"
  schedule       = var.backup_schedule

  params = {
    query = file("${path.module}/../../bigquery/scheduled_queries/backup_events_export.sql")
  }

  email_preferences {
    enable_failure_email = true
  }

  # Run the export under a dedicated SA (the one granted objectAdmin in iam.tf) when
  # var.backup_transfer_service_account is set; otherwise (default "") it runs under
  # the config creator's credentials — the owner-credentials path in RUNBOOK §3.
  service_account_name = var.backup_transfer_service_account != "" ? var.backup_transfer_service_account : null

  # The bucket + the SA's objectAdmin grant must exist before the first run.
  depends_on = [
    google_storage_bucket.backups,
    google_storage_bucket_iam_member.backup_export_object_admin,
  ]
}

# (d) NEW cadence check — alerts when an expected daily routine logged no completed run.
resource "google_bigquery_data_transfer_config" "cadence_check" {
  project        = var.project_id
  display_name   = "cadence-check-daily"
  location       = var.scheduled_query_location
  data_source_id = "scheduled_query"
  schedule       = var.cadence_schedule

  params = {
    query = file("${path.module}/../../bigquery/scheduled_queries/cadence_check.sql")
  }

  email_preferences {
    enable_failure_email = true
  }
}

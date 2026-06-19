###############################################################################
# BigQuery datasets — events / state / perf / analytics / ops
#
# !!! THESE ALMOST CERTAINLY ALREADY EXIST !!!
# They were created by bigquery/01_schema.sql and hold irreplaceable, live trading
# data. Terraform must ADOPT them, never recreate them:
#
#   terraform import google_bigquery_dataset.events    projects/stock-trading-498512/datasets/events
#   terraform import google_bigquery_dataset.state     projects/stock-trading-498512/datasets/state
#   terraform import google_bigquery_dataset.perf      projects/stock-trading-498512/datasets/perf
#   terraform import google_bigquery_dataset.analytics projects/stock-trading-498512/datasets/analytics
#   terraform import google_bigquery_dataset.ops       projects/stock-trading-498512/datasets/ops
#
# After import, `terraform plan` should show ~no changes. Descriptions/location
# below are copied verbatim from 01_schema.sql so the plan stays clean.
#
# SAFETY: prevent_destroy = true (Terraform refuses to delete these) and
# delete_contents_on_destroy = false (a dataset delete would never silently drop
# tables). To intentionally remove one you must first edit out prevent_destroy.
###############################################################################

resource "google_bigquery_dataset" "events" {
  project                    = var.project_id
  dataset_id                 = "events"
  location                   = var.region
  description                = "Append-only source of truth. INSERT/Storage-Write only; never UPDATE/DELETE."
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_dataset" "state" {
  project                    = var.project_id
  dataset_id                 = "state"
  location                   = var.region
  description                = "Current-state projections: standard views taking the latest event per entity."
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_dataset" "perf" {
  project                    = var.project_id
  dataset_id                 = "perf"
  location                   = var.region
  description                = "Deployed-TWR engine outputs + gate/kill flags (scheduled-procedure built)."
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_dataset" "analytics" {
  project                    = var.project_id
  dataset_id                 = "analytics"
  location                   = var.region
  description                = "BQML models, embeddings, calibration, attribution, screens, rollups."
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_dataset" "ops" {
  project                    = var.project_id
  dataset_id                 = "ops"
  location                   = var.region
  description                = "Remote models, stored procedures, audit/export, connections."
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

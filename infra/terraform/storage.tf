###############################################################################
# GCS backup bucket — gs://stock-trading-backups
#
# Holds the daily Parquet snapshots of the events.* store written by the backup
# scheduled query (backup_events_export.sql). US multi-region, uniform bucket-level
# access, lifecycle: delete objects older than 400 days (ops/RUNBOOK.md §3).
#
# !!! THIS BUCKET ALREADY EXISTS (RUNBOOK §3: "Bucket + lifecycle are DONE") !!!
# Import it before plan/apply so Terraform adopts rather than recreates:
#   terraform import google_storage_bucket.backups stock-trading-backups
# (bucket import id is just the bucket name.) After import, plan should show
# ~no changes; if it wants to change the lifecycle rule, align the age below with
# what the Console shows.
#
# SAFETY: prevent_destroy = true and force_destroy = false so Terraform can never
# delete the backup bucket (it is the off-BigQuery copy of the source of truth).
###############################################################################

resource "google_storage_bucket" "backups" {
  project                     = var.project_id
  name                        = var.backup_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  # Match the time-travel/retention intent: age out snapshots > 400 days.
  lifecycle_rule {
    condition {
      age = 400
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "backup_bucket_url" {
  description = "gs:// URL of the events backup bucket."
  value       = "gs://${google_storage_bucket.backups.name}"
}

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

  # Object Versioning (stack review 2026-06-24, RUNBOOK §25 B1). The daily export writes with
  # overwrite=true into a FIXED per-date path (dt=<date>/), so a corrupt/partial same-day re-run would
  # otherwise overwrite that day's only copy IN PLACE and the monthly restore drill validates only the
  # latest snapshot — the overwritten object would be unrecoverable. Versioning keeps the prior object
  # as a noncurrent version so a bad overwrite is recoverable. (The tfstate bucket already enables this;
  # this brings the irreplaceable-truth bucket to parity.)
  versioning {
    enabled = true
  }

  # Match the time-travel/retention intent: age out CURRENT snapshots > 400 days.
  lifecycle_rule {
    condition {
      age = 400
    }
    action {
      type = "Delete"
    }
  }

  # Bound noncurrent-version growth: keep recent overwrites recoverable without unbounded storage.
  # A bad in-place overwrite is caught within days (next restore drill / day-over-day per_table_rows),
  # so 3 noncurrent versions / 30 days is ample.
  lifecycle_rule {
    condition {
      num_newer_versions   = 3
      days_since_noncurrent = 30
      with_state           = "ARCHIVED"
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

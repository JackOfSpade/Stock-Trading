###############################################################################
# IAM — let the backup scheduled query write to the GCS backup bucket
#
# CONTEXT (ops/RUNBOOK.md §3 + backup_events_export.sql header): the SIMPLEST path
# is to create the backup scheduled query under the OWNER's own credentials — the
# owner already owns gs://stock-trading-backups, so no extra IAM is needed and this
# whole file is optional.
#
# This member is for the DEDICATED-SA path: when the scheduled query runs as the
# BigQuery Data Transfer service identity (or a custom run SA) instead of the
# owner, that identity needs roles/storage.objectAdmin on the bucket to EXPORT DATA.
#
# var.backup_transfer_service_account selects which principal gets the grant:
#   - "" (default): use the project's BigQuery Data Transfer Service agent
#     (service-<PROJECT_NUMBER>@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com).
#     We resolve the project number via the google_project data source.
#   - any other value: that exact "serviceAccount:..."-less email (we prefix it).
#
# If you keep the owner-credentials path, set count to 0 by leaving the SA as ""
# AND commenting this resource out, or simply ignore it — the export still works
# under owner creds without it.
###############################################################################

variable "backup_transfer_service_account" {
  description = <<-EOT
    Email of the service account the backup scheduled query runs as, WITHOUT the
    "serviceAccount:" prefix. Leave "" to grant the default BigQuery Data Transfer
    service agent. Only used if you run the backup under a dedicated SA rather than
    the owner's own credentials (the RUNBOOK §3 default path).
  EOT
  type        = string
  default     = ""
}

data "google_project" "this" {
  project_id = var.project_id
}

locals {
  # Default to the BigQuery Data Transfer Service agent when no explicit SA is given.
  backup_transfer_sa_email = (
    var.backup_transfer_service_account != ""
    ? var.backup_transfer_service_account
    : "service-${data.google_project.this.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
  )
}

resource "google_storage_bucket_iam_member" "backup_export_object_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.backup_transfer_sa_email}"
}

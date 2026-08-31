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
# This resource is GUARDED by count: it is created ONLY when a dedicated SA is set
# (var.backup_transfer_service_account != ""). On the default owner-credentials path
# (SA = "") count = 0, so no IAM is granted — the export runs under owner creds and
# needs none. So you can leave everything default and this file is a no-op.
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
  # Only grant when a dedicated run SA is configured; the owner-credentials default
  # path (SA = "") needs no IAM, so count = 0 there. (scheduled_queries.tf's
  # backup_export depends_on tolerates the empty tuple when count = 0.)
  count  = var.backup_transfer_service_account != "" ? 1 : 0
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.backup_transfer_sa_email}"
}

###############################################################################
# gh-ci-runner@ table-scoped write grant -- ops.routine_commit_markers ONLY
# (RUNBOOK section 38 self-heal, ITEM 3, bigquery/38_run_log_selfheal.sql)
#
# SPEC-ONLY (RUNBOOK settled decision / CLAUDE.md "Terraform / full IaC adoption" --
# this repo's terraform/ tree is a declared spec, never imported/applied into live
# state). The live grant is made via the exact `bq add-iam-policy-binding` command in
# the ITEM 3 packet's owner_actions, NOT via `terraform apply`. This resource exists so
# the grant's SCOPE is reviewable in-repo, matching wif.tf's own documentation-only style.
#
# WHY TABLE-SCOPED, NOT DATASET/PROJECT-SCOPED: gh-ci-runner@ is READ-ONLY today
# (RUNBOOK section 6/15: jobUser + dataViewer + connectionUser, no write anywhere).
# auto-merge-claude.yml needs to INSERT exactly one row into exactly one table
# (ops.routine_commit_markers) after a merge lands; it does not need write access to
# any other ops.* table. BigQuery table-level IAM (google_bigquery_table_iam_member)
# scopes the write grant to that ONE table, so a compromised/buggy CI run still cannot
# write anywhere else in ops.* -- in particular nowhere near ops.run_log or ops.alerts
# themselves; only ops.sp_backfill_run_log_from_markers (run under the operator's own
# identity, like every other stored procedure here) actually writes those.
###############################################################################
resource "google_bigquery_table_iam_member" "gh_ci_runner_routine_commit_markers_editor" {
  project    = var.project_id
  dataset_id = "ops"
  table_id   = "routine_commit_markers"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

###############################################################################
# gh-ci-runner@ table-scoped write grant -- ops.ci_findings ONLY
# (self-improvement audit 2026-07-16, CC-1 / issue #10, bigquery/67_ci_findings_bridge.sql)
#
# SPEC-ONLY, same convention as gh_ci_runner_routine_commit_markers_editor above -- declare only,
# never `terraform apply` (CLAUDE.md "Terraform / full IaC adoption" settled decision). The live
# grant is the exact `bq add-iam-policy-binding` command in OWNER_ACTIONS.md, not this resource.
#
# WHY TABLE-SCOPED: every WIF-authenticated CI workflow that needs to record a CI finding writes
# open/resolved marker rows into exactly one table (ops.ci_findings) -- nowhere else in ops.*, in
# particular nowhere near ops.run_log or ops.alerts themselves (those stay written only by
# BigQuery-side procedures/routines under the operator's own identity, same boundary as the
# routine_commit_markers grant above). COUNT CORRECTED (2026-08-31 code-quality pass): this used to
# say "four" (live-sql-parity, keyless-sa-audit, wif-binding-audit, guard-config-audit); the true
# count is 9 -- the 4 above plus alert-relay, auto-merge-claude, offsite-backup,
# stranded-branch-check, sql-dryrun-sweep -- all authenticating as the same
# var.ci_service_account_email (gh-ci-runner@) via WIF, so the grant itself was never
# under-scoped, only the comment's count was stale. VERIFICATION COMMAND CORRECTED (same pass,
# stale on arrival): this comment used to cite plain
# `grep -rl 'INSERT INTO.*ops\.ci_findings' .github/workflows/*.yml` to reproduce the 9 -- but this
# same uncommitted change set's scripts/ci_finding.sh extraction (17 of 25 call sites moved to the
# shared script; see its header) deleted the literal INSERT text from 3 of the 9 --
# guard-config-audit.yml, keyless-sa-audit.yml, wif-binding-audit.yml -- so that grep now finds
# only 6. The count did NOT change (moving shared SQL into a script relocates callers, it doesn't
# add or remove one); only the detection method needed widening to also match a real script
# invocation, not just the leftover literal INSERTs (live-sql-parity.yml, stranded-branch-check.yml
# and sql-dryrun-sweep.yml keep a literal SELECT-based auto-resolve INSERT alongside their script
# calls -- ci_finding.sh's header explains why those sites were left untouched):
#   grep -rlE 'INSERT INTO.*ops\.ci_findings|scripts/ci_finding\.sh "' .github/workflows/*.yml
# (verified 2026-08-31: returns exactly the 9 workflows named above.) Match on the literal
# `scripts/ci_finding\.sh "` -- the script name immediately followed by its first quoted arg --
# rather than a bare filename mention: ci.yml's `tests/test_ci_finding.sh` step name and comments
# also contain the substring "ci_finding.sh" but never call the script to write a row, so an
# OR-in-the-filename-alone pattern overcounts to 10. Re-run the grep above, not either hardcoded
# number here, if a future pass adds a 10th caller or converts one of the three remaining
# SELECT-based sites to the script.
###############################################################################
resource "google_bigquery_table_iam_member" "gh_ci_runner_ci_findings_editor" {
  project    = var.project_id
  dataset_id = "ops"
  table_id   = "ci_findings"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

###############################################################################
# Workload Identity Federation trust binding — keyless GitHub Actions → GCP
# (stack review 2026-06-24, RUNBOOK §25 E1)
#
# WHY THIS FILE EXISTS. RUNBOOK §6 documents that WIF "is set up (provider
# github-pool/github-provider, SA gh-ci-runner@…)" and powers dbt-parity + the
# dashboard. But the single most important least-privilege control on keyless CI —
# the provider's attribute_condition and the roles/iam.workloadIdentityUser binding
# that decides WHICH GitHub repo (and ideally ref) may impersonate gh-ci-runner@ —
# lived ONLY in the live Console, undocumented and unverifiable from the repo. An
# unconditioned or fork-permissive binding would let ANY repo's Actions mint a token
# for gh-ci-runner@ and read all live trading data (dataViewer/jobUser). This is the
# exact §19 "control-plane config living only in a Console, un-reviewable" anti-pattern
# — applied here to a strictly HIGHER-privilege piece of config than the monitoring
# metric §19 already codified.
#
# SPEC-ONLY (RUNBOOK §12 settled decision). Like the rest of infra/terraform/, this is
# a reviewable DECLARED SPEC — it is deliberately NOT imported or applied into live
# state. Adopting it is out of scope; the value here is (1) a reviewable record of what
# the trust boundary SHOULD be, and (2) the verification step below.
#
# VERIFY THE LIVE BINDING (do this once, the way §19 recorded the live monitor config via
# Chrome inspection — read-only, no change):
#   gcloud iam workload-identity-pools providers describe github-provider \
#     --location=global --workload-identity-pool=github-pool \
#     --project=stock-trading-498512 --format='value(attributeCondition)'
#   gcloud iam service-accounts get-iam-policy \
#     gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com \
#     --project=stock-trading-498512 --format=json
# CONFIRM: the provider attribute_condition pins assertion.repository to this repo (and
# ideally that the workloadIdentityUser member is a principalSet scoped to
# attribute.repository/<owner>/<repo> — NOT the whole pool, which would let any repo
# impersonate the SA). Record the verified result in RUNBOOK §25 E1.
#
# IF IT IS ALREADY CORRECTLY SCOPED (likely, given the maturity here) this file is pure
# documentation. If it is NOT (e.g. no attribute_condition, or a pool-wide binding),
# that is the high-severity finding to fix in the Console.
###############################################################################

variable "github_repository" {
  description = <<-EOT
    The "owner/repo" allowed to impersonate the CI service account via WIF. The
    provider attribute_condition + the SA's workloadIdentityUser principalSet MUST pin
    to this, so a fork or any other repo cannot mint a token for gh-ci-runner@.
  EOT
  type        = string
  default     = "JackOfSpade/Stock-Trading"
}

variable "wif_pool_id" {
  description = "Workload Identity Pool id (live: github-pool, RUNBOOK §6)."
  type        = string
  default     = "github-pool"
}

variable "wif_provider_id" {
  description = "WIF provider id under the pool (live: github-provider, RUNBOOK §6)."
  type        = string
  default     = "github-provider"
}

variable "ci_service_account_email" {
  description = "The keyless CI service account WIF impersonates (read-only: jobUser + dataViewer + connectionUser, RUNBOOK §6)."
  type        = string
  default     = "gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com"
}

# data.google_project.this is declared in iam.tf (provides .number for the principalSet).

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions"
  description               = "Keyless OIDC federation for the Stock-Trading GitHub Actions (RUNBOOK §6)."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # THE load-bearing control: only tokens issued to THIS repo are accepted. Without an
  # attribute_condition the provider would accept ANY GitHub repo's OIDC token.
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Bind impersonation to a principalSet SCOPED TO THIS REPO (not the whole pool), so even
# within an accepted token only this repo's runs can act as gh-ci-runner@.
resource "google_service_account_iam_member" "ci_wif_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.ci_service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member = "principalSet://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/attribute.repository/${var.github_repository}"
}

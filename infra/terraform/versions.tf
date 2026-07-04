###############################################################################
# Provider + Terraform version constraints
#
# Pins Terraform >= 1.5 and the google / google-beta providers to the 5.x line.
# google-beta is required for google_billing_budget (budget.tf).
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # -------------------------------------------------------------------------
  # REMOTE STATE BACKEND — configured (NOT commented out); enabled per A3.
  #
  # State for this module contains references to live trading datasets, so it
  # lives in a private, versioned GCS bucket (NOT in this git repo) rather than
  # the default local `terraform.tfstate`.
  #
  # The bucket gs://stock-trading-tfstate must already exist (US, versioned)
  # before `terraform init` — it was created once with:
  #   gsutil mb -l US -b on gs://stock-trading-tfstate && gsutil versioning set on gs://stock-trading-tfstate
  # then `terraform init -migrate-state` (or a plain `terraform init` against an
  # already-initialized backend). NOTE: CI does not run terraform, so this block
  # only affects an owner running terraform locally / in Cloud Shell.
  #
  # IMPORTANT: "backend configured" is orthogonal to "module applied". Per the
  # project's settled decision (CLAUDE.md "Settled decisions", ops/RUNBOOK.md §12),
  # this module is deliberately never imported/applied — `terraform state list`
  # against this backend is verified EMPTY. Live infra stays managed out-of-band
  # via the BigQuery MCP + console; this backend block only makes a *hypothetical*
  # future `terraform init`/`plan` point somewhere sane, it is not an invitation to
  # apply.
  backend "gcs" {
    bucket = "stock-trading-tfstate"
    prefix = "infra/terraform"
  }
  # -------------------------------------------------------------------------
}

provider "google" {
  project = var.project_id
  # `region`/`zone` deliberately unset: BigQuery here is US multi-region (not a
  # single compute region), so resources set `location = "US"` explicitly.
}

provider "google-beta" {
  project = var.project_id
}

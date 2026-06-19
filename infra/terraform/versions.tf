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
  # REMOTE STATE BACKEND — intentionally left COMMENTED OUT.
  #
  # The owner picks the GCS bucket that holds this module's Terraform state.
  # State for this module contains references to live trading datasets, so it
  # should live in a private, versioned GCS bucket (NOT in this git repo).
  #
  # To enable: create a bucket (e.g. gs://stock-trading-tfstate, US, versioned),
  # uncomment the block below, set `bucket`, then run `terraform init -migrate-state`.
  #
  # backend "gcs" {
  #   bucket = "REPLACE-ME-tfstate-bucket"   # owner decision — must already exist
  #   prefix = "infra/terraform"
  # }
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

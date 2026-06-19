###############################################################################
# Billing budget + email notification channels (ops/RUNBOOK.md §2)
#
# Caps unattended spend (Vertex embeddings / Gemini / AI.FORECAST — pennies, but
# the scheduled jobs run unattended). Thresholds at 50% / 90% / 100% of
# var.budget_amount_usd, emailed via Cloud Monitoring notification channels.
#
# OPTIONAL: the whole file is guarded by `count = var.billing_account == "" ? 0 : 1`
# so the module plans/applies cleanly before the owner supplies a billing account.
# Set var.billing_account (and optionally var.notification_emails) to enable it.
#
# Provider note: google_billing_budget lives in google-beta (declared in versions.tf).
###############################################################################

locals {
  budget_enabled = var.billing_account == "" ? 0 : 1
}

# One email notification channel per address in var.notification_emails.
resource "google_monitoring_notification_channel" "budget_email" {
  for_each = local.budget_enabled == 1 ? toset(var.notification_emails) : toset([])

  project      = var.project_id
  display_name = "Budget alert: ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

resource "google_billing_budget" "project_budget" {
  count    = local.budget_enabled
  provider = google-beta

  billing_account = var.billing_account
  display_name    = "stock-trading monthly budget"

  budget_filter {
    projects = ["projects/${data.google_project.this.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      # `units` is the WHOLE-currency amount as a string in the provider schema.
      units = tostring(var.budget_amount_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      for c in google_monitoring_notification_channel.budget_email : c.id
    ]
    # Also email the billing-account admins/users on every threshold crossing.
    disable_default_iam_recipients = false
  }
}

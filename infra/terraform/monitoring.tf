###############################################################################
# Heartbeat monitor for the freshness dead-man's switch (ops/RUNBOOK.md §15, §19)
#
# WHY THIS FILE EXISTS — the 2026-06-20 false alarm.
#   The freshness scheduled query (scheduled_queries.tf (a)) RAISEs + emails on a
#   RED system. But that failure-email path canNOT signal a *dead* scheduler: a
#   query that never runs sends no failure email. The only thing that catches a
#   silent scheduler death is a Cloud Monitoring *metric-absence* alert on a
#   heartbeat the run emits — RUNBOOK §15 "Heartbeat".
#
#   That heartbeat metric + alert policy were created by hand in the Console and
#   were NEVER version-controlled. On 2026-06-19 the scheduled queries were moved
#   off the owner's OAuth onto the dedicated SA (scheduled_queries.tf,
#   var.scheduled_query_service_account — the §15 fix). The hand-built log metric's
#   filter was pinned to the OLD identity (principalEmail), so it stopped counting
#   the SA-run executions, went absent, and on 2026-06-20 23:41 UTC the
#   "Freshness scheduler absent >25h" policy fired — even though the freshness
#   check had run & succeeded at 05:00 and 19:29 UTC that day. A FALSE ALARM whose
#   root cause was an un-versioned monitor pinning a now-stale identity.
#
# THE FIX (this file):
#   1. Codify the metric + policy so they are reviewable and survive (the §12 IaC
#      principle the rest of this module already applies).
#   2. Make the metric filter IDENTITY-AGNOSTIC: key it on the freshness transfer
#      config_id (carried straight from the freshness_check resource below), NOT on
#      principalEmail. An identity migration then can never break it again. It only
#      needs re-pointing if the config is deleted+recreated (new id) — and because
#      the id is derived from the resource, Terraform re-points it automatically.
#   3. Count run COMPLETION (success OR failure), not success-only: liveness is
#      "did the scheduler fire", which is orthogonal to green/red. Red is already
#      signalled by the freshness query's failure email; folding red into the
#      absence alert would double-signal one problem as a different one.
#
# ADOPT, DON'T DUPLICATE — these already exist in the Console. Import them first
# (see infra/terraform/README.md), then `terraform plan` and reconcile:
#   terraform import google_logging_metric.freshness_scheduled_run freshness_scheduled_run
#   terraform import google_monitoring_alert_policy.freshness_scheduler_absent \
#     projects/stock-trading-498512/alertPolicies/<POLICY_ID>
#   # channels: projects/<proj>/notificationChannels/<ID>
# EXPECT A PLAN DIFF on import — that diff IS the bug: the live metric filter pins
# the old identity (and the live policy may be a PromQL/MQL condition, per the
# alert email's "PromQL query"). Reconcile TO this identity-agnostic definition
# (i.e. let Terraform overwrite the stale filter) — that is what un-breaks the alert.
###############################################################################

# Freshness transfer config_id, extracted from the resource so the metric tracks
# whatever config Terraform manages (survives a recreate; immune to identity swaps).
# .name is "projects/<p>/locations/<loc>/transferConfigs/<config_id>".
locals {
  freshness_config_id = regex("[^/]+$", google_bigquery_data_transfer_config.freshness_check.name)
}

# --- Heartbeat: count each freshness scheduled-query RUN (success or failure) ----
resource "google_logging_metric" "freshness_scheduled_run" {
  project = var.project_id
  name    = "freshness_scheduled_run" # -> metric.type logging.googleapis.com/user/freshness_scheduled_run

  # BigQuery Data Transfer (scheduled query) run logs. Keyed on the freshness
  # config_id ONLY — deliberately NO principalEmail / authenticationInfo, so the
  # owner-OAuth -> bq-scheduler@ migration (and any future one) keeps matching.
  # The message regex keeps it to the per-run terminal summary line (both outcomes)
  # rather than every intermediate log line.
  #
  # RECONCILE ON IMPORT: resource.type and the exact terminal-message wording were
  # set out-of-band; verify against a live entry in Logs Explorer
  #   (resource.type="bigquery_dts_config" resource.labels.config_id="<id>")
  # and adjust the regex if the DTS summary wording differs in this project.
  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${local.freshness_config_id}"
    severity>=INFO
    jsonPayload.message=~"(?i)(succeeded|completed|failed)"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# --- Email channels for the absence alert (independent of the budget channels) ---
# Separate from budget.tf's channels (those are guarded on var.billing_account; a
# scheduler-death alert must work with or without a billing account). Reuses the
# same var.notification_emails address list.
resource "google_monitoring_notification_channel" "scheduler_alert_email" {
  for_each = toset(var.notification_emails)

  project      = var.project_id
  display_name = "Scheduler-absence alert: ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

# --- Alert: the freshness heartbeat has been ABSENT for >25h (silent scheduler death) ---
resource "google_monitoring_alert_policy" "freshness_scheduler_absent" {
  project      = var.project_id
  display_name = "Freshness scheduler absent >25h"
  combiner     = "OR"

  conditions {
    display_name = "No freshness run in 26h"

    # Metric-absence on the heartbeat: fires when no freshness run has been counted
    # for the duration window. 86400s = 24h is the API max for a classic
    # MetricAbsence duration (a fresh apply rejects >24h) — slightly tighter than the
    # live policy's >25h, which it likely achieves via a PromQL `absent_over_time(...[26h])`
    # condition (cf. the alert email's "PromQL query"). Reconcile the FORM on import;
    # the load-bearing fix is the identity-agnostic metric above, not the condition syntax.
    condition_absent {
      filter   = "resource.type=\"bigquery_dts_config\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.freshness_scheduled_run.name}\""
      duration = "86400s"

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [
    for c in google_monitoring_notification_channel.scheduler_alert_email : c.id
  ]

  documentation {
    content = join(" ", [
      "The freshness dead-man's switch has not emitted a run heartbeat in >25h.",
      "FIRST verify it is real, not a repeat of the 2026-06-20 false alarm:",
      "check INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% jobs",
      "running the freshness body (see ops/RUNBOOK.md §19). If runs ARE present, the",
      "heartbeat metric filter has drifted from the run identity/config — fix the",
      "metric, not the scheduler. If NO runs are present, the scheduler is genuinely",
      "down (paused config, lapsed run-SA, or DTS outage)."
    ])
    mime_type = "text/markdown"
  }
}

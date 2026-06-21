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
#   var.scheduled_query_service_account — the §15 fix). During that cutover the
#   heartbeat metric had no matching sample for >25h, so on 2026-06-20 23:41 UTC the
#   "Freshness scheduler absent >25h" policy fired — even though the freshness check
#   had run & succeeded at 05:00 and 19:29 UTC that day. A FALSE ALARM.
#
#   VERIFIED LIVE CONFIG (Claude-in-Chrome console inspection, 2026-06-21 — this
#   corrects an earlier guess that the filter pinned principalEmail; it does NOT):
#     - metric filter (live): resource.type="bigquery_dts_config",
#       resource.labels.config_id="6a9c1592-0000-2caa-86b1-089e08214038" (the freshness
#       config, running as bq-scheduler@), jsonPayload.message:"completed successfully".
#       NO identity label, NO principalEmail pin. The DEFECT is the message clause:
#       "completed successfully" matches only the per-JOB success line, so it is
#       SUCCESS-ONLY and missed the cutover window. A red run (RAISE) emits
#       "...failed with error..." / "Summary: succeeded 0 jobs, failed 1 jobs." and
#       would ALSO go uncounted — conflating "system red" with "scheduler dead".
#     - policy (live): a PromQL condition, NOT classic MetricAbsence:
#         absent_over_time(logging_googleapis_com:user_freshness_scheduled_run[25h])
#       no group-by, no label selector. The "__missing__" in the alert email was just
#       the metric having ZERO series during the absence, not an identity label.
#     - The incident auto-resolved 2026-06-21 06:40 UTC once the 05:00 run was counted.
#
# THE FIX (this file):
#   1. Codify the metric + policy so they are reviewable and survive (the §12 IaC
#      principle the rest of this module already applies).
#   2. Keep the metric filter IDENTITY-AGNOSTIC (config_id, carried straight from the
#      freshness_check resource below — never principalEmail). A recreate re-points it
#      automatically; an identity swap can't break it.
#   3. Count run COMPLETION via the DTS per-run "Summary:" line (emitted on BOTH
#      success and failure) instead of the success-only "completed successfully" line.
#      Liveness is "did the scheduler fire", orthogonal to green/red — red is already
#      signalled by the freshness query's failure email; folding it into the absence
#      alert would double-signal one problem as a different one.
#
# ADOPT, DON'T DUPLICATE — these already exist in the Console. Import them first
# (see infra/terraform/README.md), then `terraform plan` and reconcile:
#   terraform import google_logging_metric.freshness_scheduled_run freshness_scheduled_run
#   terraform import google_monitoring_alert_policy.freshness_scheduler_absent \
#     projects/stock-trading-498512/alertPolicies/<POLICY_ID>
#   # channels: projects/<proj>/notificationChannels/<ID>
# EXPECT A PLAN DIFF on import — the metric-filter diff swaps the success-only
# "completed successfully" clause for the terminal-agnostic "Summary:" marker.
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
  #
  # The DTS emits exactly one "Summary: succeeded N jobs, failed M jobs." line per
  # run, on BOTH success ("succeeded 1") and failure ("succeeded 0, failed 1") —
  # verified against live logs (2026-06-21). Matching it gives one terminal heartbeat
  # per run, independent of green/red. (The live metric used "completed successfully",
  # which is success-only and missed the migration cutover — see header.)
  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${local.freshness_config_id}"
    jsonPayload.message=~"^Summary: succeeded"
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
    display_name = "No successful freshness run in 26h"

    # VERIFIED LIVE FORM (2026-06-21): a PromQL condition, NOT classic MetricAbsence
    # (which caps at 24h and so cannot express the >25h window). absent_over_time(...)
    # returns 1 when the heartbeat metric has had no sample in the lookback, firing the
    # alert. The PromQL metric name is the Monitoring mapping of the log-metric type
    # (logging.googleapis.com/user/<name> -> logging_googleapis_com:user_<name>), built
    # from the resource so the two never drift. duration/evaluation_interval are sane
    # defaults — reconcile to the live values on import if they differ.
    condition_prometheus_query_language {
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.freshness_scheduled_run.name}[25h])"
      duration            = "0s"
      evaluation_interval = "60s"
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
      "heartbeat metric filter has drifted from the live config_id / DTS message wording",
      "— fix the metric, not the scheduler. If NO runs are present, the scheduler is",
      "genuinely down (paused config, lapsed run-SA, or DTS outage)."
    ])
    mime_type = "text/markdown"
  }
}

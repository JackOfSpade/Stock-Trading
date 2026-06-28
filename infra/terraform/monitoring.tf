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
  backup_config_id    = regex("[^/]+$", google_bigquery_data_transfer_config.backup_export.name)
  cadence_config_id   = regex("[^/]+$", google_bigquery_data_transfer_config.cadence_check.name)
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

# --- SECOND, DIFFERENT-CLASS channel (stack review 2026-06-24, RUNBOOK §25 A1) ----
# Every alert path today converges on ONE Gmail inbox / ONE Google account, so a single
# inbox/OAuth/account failure can black-hole all of them at once. A webhook channel whose
# failure mode is uncorrelated with that Google account (Slack/Discord/ntfy/Pub/Sub-push)
# breaks the correlation. GUARDED: created only when var.alert_webhook_url is set; otherwise
# count = 0 and the policies fall back to email-only (no behaviour change). The receiver must
# accept Cloud Monitoring's webhook JSON (use a proxy/Cloud Function if pointing at a chat
# webhook that expects a {text} body).
resource "google_monitoring_notification_channel" "scheduler_alert_webhook" {
  count = var.alert_webhook_url != "" ? 1 : 0

  project      = var.project_id
  display_name = "Scheduler-absence alert: webhook (non-Google channel)"
  type         = "webhook_tokenauth"

  labels = {
    url = var.alert_webhook_url
  }
}

locals {
  # Email channels + the optional different-class webhook channel. The absence policies notify
  # ALL of these, so a single-inbox failure cannot silence the scheduler-death alarm.
  scheduler_alert_channels = concat(
    [for c in google_monitoring_notification_channel.scheduler_alert_email : c.id],
    google_monitoring_notification_channel.scheduler_alert_webhook[*].id,
  )
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

  notification_channels = local.scheduler_alert_channels

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

###############################################################################
# Same heartbeat coverage for the OTHER two RAISE-ing scheduled queries — the
# events backup export and the cadence check (added 2026-06-21).
#
# Same rationale as freshness above: they email on FAILURE, but a silently-dead
# scheduler sends nothing — only a metric-absence alert catches it. The BACKUP one
# is the most consequential: a silent death means the irreplaceable append-only
# event store stops being backed up, unnoticed. Both run daily, so the same 25h
# absence window applies. config_ids are carried from the resources (identity- and
# recreate-agnostic); the filter matches the per-run DTS "Summary:" line, which is
# emitted on success AND failure (liveness, decoupled from green/red).
#
# Live config_ids (verified in the Console 2026-06-21):
#   backup  events-backup-daily  6a509810-0000-2279-a65e-f4f5e80c4144
#   cadence cadence-check-daily  6a44a3d9-0000-2837-8b7b-883d24f5c8b8
#
# CREATION CAVEAT (no backfill): a new log metric only counts logs arriving after it
# exists, so an absent_over_time alert built on a brand-new empty metric fires until
# the next run lands a point. When standing these up live, create the metric, trigger
# one run to seed a data point, verify it, THEN create the policy. (A terraform apply
# would hit the same transient — but per RUNBOOK §12 this module is spec-only.)
###############################################################################

# --- Backup export heartbeat -------------------------------------------------
resource "google_logging_metric" "backup_scheduled_run" {
  project = var.project_id
  name    = "backup_scheduled_run"

  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${local.backup_config_id}"
    jsonPayload.message=~"^Summary: succeeded"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "backup_scheduler_absent" {
  project      = var.project_id
  display_name = "Backup scheduler absent >25h"
  combiner     = "OR"

  conditions {
    display_name = "No events-backup run in 25h"
    condition_prometheus_query_language {
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.backup_scheduled_run.name}[25h])"
      duration            = "0s"
      evaluation_interval = "60s"
    }
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "The events-backup scheduled query has emitted no run heartbeat in >25h — the append-only event store may be silently un-backed-up. Triage per ops/RUNBOOK.md §19: check region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% backup runs. Runs present -> the metric drifted (fix the metric). No runs -> the backup scheduler is down (paused config, lapsed run-SA, or DTS outage)."
    mime_type = "text/markdown"
  }
}

# --- Cadence check heartbeat -------------------------------------------------
resource "google_logging_metric" "cadence_scheduled_run" {
  project = var.project_id
  name    = "cadence_scheduled_run"

  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${local.cadence_config_id}"
    jsonPayload.message=~"^Summary: succeeded"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "cadence_scheduler_absent" {
  project      = var.project_id
  display_name = "Cadence scheduler absent >25h"
  combiner     = "OR"

  conditions {
    display_name = "No cadence-check run in 25h"
    condition_prometheus_query_language {
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.cadence_scheduled_run.name}[25h])"
      duration            = "0s"
      evaluation_interval = "60s"
    }
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "The cadence-check scheduled query has emitted no run heartbeat in >25h — missed-routine detection (state.cadence_watch) may be silently down. Triage per ops/RUNBOOK.md §19; note state.freshness still independently catches data staleness, so this is lower-severity than the freshness/backup absences."
    mime_type = "text/markdown"
  }
}

###############################################################################
# 2026-06-28 stack review #2 (#4): scheduler-absence coverage for the TWO newest
# RAISE-ing scheduled queries — the monthly RESTORE DRILL and the daily INTEGRITY
# CHECK. Same who-watches-the-watchers gap as §19, re-opened for the checkers added in
# the 2026-06-24 review: both write nothing on a clean run, so a silently-paused schedule
# leaves you believing DR/governance is verified when it has not run. The restore drill is
# the worst place to have it (its value is realized only when you need it).
#
# These two were created OUT-OF-BAND (owner console, RUNBOOK §3/§25), not via
# scheduled_queries.tf, so their config_ids are NOT derivable from a TF resource. Supply
# them via the variables below; each metric+policy is created only when its config_id is set
# (count guard) — spec stays inert until the owner records the live ids. Same no-backfill
# caveat as above: create the metric, seed one run, verify, THEN attach the policy.
###############################################################################

variable "restore_drill_config_id" {
  description = "BigQuery Data Transfer config_id of the monthly restore-drill scheduled query (Console → Scheduled queries → the restore_drill job → its transferConfig id). Empty = skip the absence metric/policy."
  type        = string
  default     = ""
}

variable "integrity_check_config_id" {
  description = "BigQuery Data Transfer config_id of the daily integrity_check scheduled query. Empty = skip the absence metric/policy."
  type        = string
  default     = ""
}

# --- Restore-drill heartbeat (monthly; ~33d absence window, NOT 25h) ----------
resource "google_logging_metric" "restore_drill_scheduled_run" {
  count   = var.restore_drill_config_id != "" ? 1 : 0
  project = var.project_id
  name    = "restore_drill_scheduled_run"

  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${var.restore_drill_config_id}"
    jsonPayload.message=~"^Summary: succeeded"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "restore_drill_scheduler_absent" {
  count        = var.restore_drill_config_id != "" ? 1 : 0
  project      = var.project_id
  display_name = "Restore-drill scheduler absent >33d"
  combiner     = "OR"

  conditions {
    display_name = "No restore-drill run in 33 days"
    condition_prometheus_query_language {
      # Monthly cadence + slack. PromQL accepts a long range; 792h = 33d.
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.restore_drill_scheduled_run[0].name}[792h])"
      duration            = "0s"
      evaluation_interval = "300s"
    }
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "The monthly backup RESTORE DRILL (ops.sp_restore_drill) has emitted no run heartbeat in >33 days — DR verification may be silently paused, so 'we can recover' is unproven. state.restore_health (off ops.drill_log) additionally flags a stale/failing drill via cadence_check. Triage per ops/RUNBOOK.md §19."
    mime_type = "text/markdown"
  }
}

# --- Integrity-check heartbeat (daily; 25h window) ----------------------------
resource "google_logging_metric" "integrity_check_scheduled_run" {
  count   = var.integrity_check_config_id != "" ? 1 : 0
  project = var.project_id
  name    = "integrity_check_scheduled_run"

  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${var.integrity_check_config_id}"
    jsonPayload.message=~"^Summary: succeeded"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "integrity_check_scheduler_absent" {
  count        = var.integrity_check_config_id != "" ? 1 : 0
  project      = var.project_id
  display_name = "Integrity-check scheduler absent >25h"
  combiner     = "OR"

  conditions {
    display_name = "No integrity-check run in 25h"
    condition_prometheus_query_language {
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.integrity_check_scheduled_run[0].name}[25h])"
      duration            = "0s"
      evaluation_interval = "60s"
    }
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "The daily append-only INTEGRITY check (state.append_only_integrity) has emitted no run heartbeat in >25h. It is record-only (writes a warning, never RAISEs), so a DEAD scheduler writes nothing at all — this absence policy is the ONLY thing that catches it. Triage per ops/RUNBOOK.md §19; confirm the resourceViewer grant + that view 18 is applied."
    mime_type = "text/markdown"
  }
}

###############################################################################
# 2026-06-28 stack review #2 (#6): alert on CreateServiceAccountKey for the two
# keyless SAs. The whole CI/automation security model rests on gh-ci-runner@ and
# bq-scheduler@ holding ZERO downloadable keys (§6/§15). keyless-sa-audit.yml is a
# MONTHLY state assertion AND is OFF by default — so a `gcloud iam service-accounts
# keys create` could silently reintroduce a long-lived exportable credential and go
# unnoticed for up to a month. This detects the key-CREATION event itself, in real time,
# from the Admin Activity audit log (on by default), needing NO serviceAccountKeys.list
# grant. The preventive org policy (iam.disableServiceAccountKeyCreation) stays deferred
# for the no-Org reason as §17 — this detection alert is the actionable-today control.
###############################################################################

resource "google_logging_metric" "sa_key_created" {
  project = var.project_id
  name    = "sa_key_created"

  # Admin Activity audit log for a user-initiated key creation on either keyless SA.
  filter = <<-EOT
    logName="projects/${var.project_id}/logs/cloudaudit.googleapis.com%2Factivity"
    protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
    (protoPayload.resourceName=~"gh-ci-runner@" OR protoPayload.resourceName=~"bq-scheduler@")
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "sa_key_created" {
  project      = var.project_id
  display_name = "Service-account key created on a keyless SA"
  combiner     = "OR"

  conditions {
    display_name = "A user-managed key was created on gh-ci-runner@/bq-scheduler@"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_key_created.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      trigger { count = 1 }
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "A user-managed (downloadable) key was just created on gh-ci-runner@ or bq-scheduler@ — both are supposed to be keyless (WIF, RUNBOOK §6/§15/§25). If you did not intend this, DELETE the key immediately (gcloud iam service-accounts keys delete) and investigate who created it. Pairs with the monthly keyless-sa-audit.yml state assertion."
    mime_type = "text/markdown"
  }
}

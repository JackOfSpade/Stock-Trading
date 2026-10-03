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
#   terraform import 'google_logging_metric.scheduler_run["freshness"]' freshness_scheduled_run
#   terraform import 'google_monitoring_alert_policy.scheduler_absent["freshness"]' \
#     projects/stock-trading-498512/alertPolicies/<POLICY_ID>
#   # channels: projects/<proj>/notificationChannels/<ID>
# (The freshness/backup/cadence/integrity_check/ops_export log metric + alert policy
# resources below are generated via a single `for_each` over `local.scheduler_absence_monitors`
# — see "REFACTOR (2026-07-04)" further down — so their addresses are now
# `google_logging_metric.scheduler_run["<key>"]` / `google_monitoring_alert_policy.scheduler_absent["<key>"]`,
# NOT the old per-monitor resource names. import_monitoring.sh reflects this.)
# EXPECT A PLAN DIFF on import — the metric-filter diff swaps the success-only
# "completed successfully" clause for the terminal-agnostic "Summary:" marker.
###############################################################################

# Freshness/backup/cadence transfer config_ids, extracted from their resources so the
# metrics track whatever config Terraform manages (survives a recreate; immune to
# identity swaps). .name is "projects/<p>/locations/<loc>/transferConfigs/<config_id>".
locals {
  freshness_config_id = regex("[^/]+$", google_bigquery_data_transfer_config.freshness_check.name)
  backup_config_id    = regex("[^/]+$", google_bigquery_data_transfer_config.backup_export.name)
  cadence_config_id   = regex("[^/]+$", google_bigquery_data_transfer_config.cadence_check.name)
}

###############################################################################
# 2026-06-28 stack review #2 (#4): scheduler-absence coverage extended to the OTHER
# RAISE-ing / record-only scheduled queries — the events backup export, the cadence
# check, the daily INTEGRITY CHECK, and (2026-06-28 ops-export symmetry) the ops.*
# backup export. Same who-watches-the-watchers gap as freshness above: some of these
# (backup, cadence) email on FAILURE but a silently-dead scheduler sends nothing;
# integrity_check is record-only (writes a warning, never RAISEs) so a dead scheduler
# writes no alert of its own — this absence policy is the FAST detector (25h); the in-warehouse
# beat-age watch (cadence_check -> scheduled_query_stale, ~36h) is the independent backstop. All
# four run daily, so the same 25h absence window applies. config_ids are either
# derived from a Terraform-managed resource's .name (freshness/backup/cadence — see
# the locals above) or a hardcoded var (integrity_check/ops_export — see the two
# variable blocks below, and finding context there for why). The filter matches the
# per-run DTS "Summary:" line, which is emitted on success AND failure (liveness,
# decoupled from green/red).
#
# Live config_ids (verified in the Console 2026-06-21 / 2026-06-29):
#   backup           events-backup-daily    6a509810-0000-2279-a65e-f4f5e80c4144
#   cadence          cadence-check-daily    6a44a3d9-0000-2837-8b7b-883d24f5c8b8
#   integrity_check  integrity-check-daily  6a4d603d-0000-2d5d-b9af-14223bafe266
#   ops_export       ops-export-daily       6a43d4f7-0000-276c-b1fb-7474463ce22d
#
# CREATION CAVEAT (no backfill): a new log metric only counts logs arriving after it
# exists, so an absent_over_time alert built on a brand-new empty metric fires until
# the next run lands a point. When standing these up live, create the metric, trigger
# one run to seed a data point, verify it, THEN create the policy. (A terraform apply
# would hit the same transient — but per RUNBOOK §12 this module is spec-only.)
#
# RESTORE-DRILL absence is deliberately NOT a Cloud Monitoring metric (corrected
# 2026-06-29) and so has NO entry in the map below. The drill is MONTHLY, but Cloud
# Monitoring PromQL alerting caps the absence lookback at ~25h (verified live
# 2026-06-29 — a >25h window is rejected for log-based metrics in every condition
# type), and a 25h window on a monthly job would FALSE-FIRE every day. The correct
# monthly-cadence liveness mechanism is the in-warehouse state.restore_health (40-day
# window off ops.drill_log), surfaced via cadence_check 'restore_stale' — already
# applied (RUNBOOK §27). So there is no restore_drill absence policy here, by design.
###############################################################################

# The integrity_check and ops_export config_ids below are HARDCODED DEFAULTS rather
# than `regex(...)`-derived from a resource's `.name` like freshness_config_id /
# backup_config_id / cadence_config_id above. That is intentional, not an
# inconsistency to "fix": both scheduled queries were created OUT-OF-BAND (RUNBOOK
# §25/§27) and have no corresponding `google_bigquery_data_transfer_config` resource
# in this module for either one, so there is no resource `.name` to derive from. Do
# not change these to the derived pattern without first adding real transfer-config
# resources for these two queries — a separate, deliberate scope decision this
# comment does not make.
variable "integrity_check_config_id" {
  description = "BigQuery Data Transfer config_id of the daily integrity_check scheduled query (live: integrity-check-daily 6a4d603d-…, RUNBOOK §27). Empty = skip the absence metric/policy. Hardcoded (not regex-derived) — see comment above."
  type        = string
  default     = "6a4d603d-0000-2d5d-b9af-14223bafe266"
}

variable "ops_export_config_id" {
  description = "BigQuery Data Transfer config_id of the daily ops.* backup export scheduled query (live: ops-export-daily, RUNBOOK §27). Empty = skip this absence metric/policy. Hardcoded (not regex-derived) — see comment above."
  type        = string
  default     = "6a43d4f7-0000-276c-b1fb-7474463ce22d"
}

###############################################################################
# REFACTOR (2026-07-04): the five scheduler-absence monitors above (freshness,
# backup, cadence, integrity_check, ops_export) were previously five near-identical
# copy-pasted `google_logging_metric` + `google_monitoring_alert_policy` resource
# pairs (~340 lines), differing only in config_id / metric name / display text /
# documentation body. Collapsed into one `for_each` over this map — SAME metric
# filters, SAME alert conditions/thresholds, SAME documentation text as before; only
# the resource addressing changed (now `google_logging_metric.scheduler_run["<key>"]`
# / `google_monitoring_alert_policy.scheduler_absent["<key>"]` instead of five
# separate resource names — see import_monitoring.sh and README.md for the updated
# import addresses). The separate `sa_key_created` metric/policy pair at the bottom
# of this file is structurally different (condition_threshold, not
# condition_prometheus_query_language) and is deliberately NOT part of this map.
#
# A map entry is active (produces a metric + policy) iff its `config_id` is
# non-empty — freshness/backup/cadence always are (derived from real resources);
# integrity_check/ops_export are only when their var is set, preserving the original
# per-resource `count = var.X_config_id != "" ? 1 : 0` guards.
###############################################################################

# 2026-10-03: a transient Cloud Monitoring EVALUATION-side blip has opened SIX incidents on FOUR of the
# five absence policies since 2026-08-17 (Monitoring alerts API: ops-export 08-17 19:51Z, cadence 08-17
# 19:53Z and 08-18 01:22Z, backup 08-18 05:25Z, integrity-check 09-18 18:21Z and 10-01 03:58Z), every
# one with a valid heartbeat sample already inside the 25h window and nothing wrong underneath
# (RUNBOOK §49, §56). Each closed itself in 3m39s-4m33s; the one REAL absence on record (freshness,
# 2026-06-20) stayed open 6h59m50s. Replaying each policy's own PromQL against the stored series shows
# no gap, so the data is fine and the single evaluation that flipped to "absent" was wrong. A real
# absence is not transient: once the last sample is >25h old the condition stays true until the next
# run lands, i.e. for hours. So requiring it to HOLD for 30 minutes before the incident opens removes
# the blip class at zero detection cost (the window is 25h; 30 min is ~2% of it).
locals {
  scheduler_absence_duration = "1800s"

  # Appended to every monitor's documentation so the alert email itself carries the triage rule
  # (the live policies had EMPTY documentation, so the email said nothing actionable).
  scheduler_absence_triage = " FALSE-ALARM CHECK FIRST (6 false alarms on 4 policies since 2026-08-17, ops/RUNBOOK.md section 56): the scheduler is usually fine. (1) Incident length: a blip auto-closes in ~4 min, a real absence stays open for hours. (2) Warehouse: `SELECT sq_name, last_beat_ts, stale_beat FROM state.scheduled_query_version_drift` -- this monitor's last_beat_ts within 24h and stale_beat=false means it is alive (a real death also raises a scheduled_query_stale warning in ops.alerts within ~36-60h). (3) Logs: `gcloud logging read 'resource.type=\"bigquery_dts_config\" AND resource.labels.config_id=\"<id>\" AND jsonPayload.message=~\"^Summary: succeeded\"' --freshness=2d` -- a 'Summary: succeeded 1 jobs' line inside 25h means the alert was an evaluation-side blip (a 'failed 1 jobs' Summary is a failing run, not a dead scheduler: see the DTS failure email and ops.alerts). Blip => no action."
}

locals {
  scheduler_absence_monitors = {
    for key, monitor in {
      freshness = {
        config_id             = local.freshness_config_id
        evaluation_interval   = "1800s"
        metric_name           = "freshness_scheduled_run"
        alert_display_name    = "Freshness scheduler absent >25h"
        condition_display_name = "No freshness run in 25h"
        documentation = join(" ", [
          "The freshness dead-man's switch has not emitted a run heartbeat in >25h.",
          "FIRST verify it is real, not a repeat of the 2026-06-20 false alarm:",
          "check INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% jobs",
          "running the freshness body (see ops/RUNBOOK.md §19). If runs ARE present, the",
          "heartbeat metric filter has drifted from the live config_id / DTS message wording",
          "— fix the metric, not the scheduler. If NO runs are present, the scheduler is",
          "genuinely down (paused config, lapsed run-SA, or DTS outage)."
        ])
      }
      backup = {
        config_id             = local.backup_config_id
        evaluation_interval   = "30s"
        metric_name           = "backup_scheduled_run"
        alert_display_name    = "Backup scheduler absent >25h"
        condition_display_name = "No events-backup run in 25h"
        documentation         = "The events-backup scheduled query has emitted no run heartbeat in >25h — the append-only event store may be silently un-backed-up. Triage per ops/RUNBOOK.md §19: check region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT for recent scheduled_query% backup runs. Runs present -> the metric drifted (fix the metric). No runs -> the backup scheduler is down (paused config, lapsed run-SA, or DTS outage)."
      }
      cadence = {
        config_id             = local.cadence_config_id
        evaluation_interval   = "30s"
        metric_name           = "cadence_scheduled_run"
        alert_display_name    = "Cadence scheduler absent >25h"
        condition_display_name = "No cadence-check run in 25h"
        documentation         = "The cadence-check scheduled query has emitted no run heartbeat in >25h — missed-routine detection (state.cadence_watch) may be silently down. Triage per ops/RUNBOOK.md §19; note state.freshness still independently catches data staleness, so this is lower-severity than the freshness/backup absences."
      }
      integrity_check = {
        config_id             = var.integrity_check_config_id
        evaluation_interval   = "30s"
        metric_name           = "integrity_check_scheduled_run"
        alert_display_name    = "Integrity-check scheduler absent >25h"
        condition_display_name = "No integrity-check run in 25h"
        documentation         = "The daily append-only INTEGRITY check (state.append_only_integrity) has emitted no run heartbeat in >25h. It is record-only (writes a warning, never RAISEs), so a DEAD scheduler writes no alert of its own — this policy is the fast (25h) detector, and cadence_check independently raises a scheduled_query_stale warning via ops.alerts if no sq:integrity_check heartbeat lands for 36h, so a real death is double-covered. Triage per ops/RUNBOOK.md §19; confirm the resourceViewer grant + that view 18 is applied."
      }
      ops_export = {
        config_id             = var.ops_export_config_id
        evaluation_interval   = "30s"
        metric_name           = "ops_export_scheduled_run"
        alert_display_name    = "ops-export scheduler absent >25h"
        condition_display_name = "No ops.* backup run in 25h"
        documentation         = "The ops.* backup export (ops-export-daily) has emitted no run heartbeat in >25h — the irreplaceable run_log/alerts/backup_log/heartbeat/drill_log audit history may be silently un-backed-up. state.ops_backup_health additionally flags this via cadence_check. Triage per ops/RUNBOOK.md §19/§27."
      }
    } : key => monitor if monitor.config_id != ""
  }
}

# --- Email channels for the absence alerts (independent of the budget channels) ---
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

# --- Heartbeat: count each monitored scheduled-query RUN (success or failure) ----
# One log-based metric per active entry in local.scheduler_absence_monitors (see the
# REFACTOR comment above for what this replaces).
resource "google_logging_metric" "scheduler_run" {
  for_each = local.scheduler_absence_monitors

  project = var.project_id
  name    = each.value.metric_name # -> metric.type logging.googleapis.com/user/<metric_name>

  # BigQuery Data Transfer (scheduled query) run logs. Keyed on the monitor's
  # config_id ONLY — deliberately NO principalEmail / authenticationInfo, so an
  # owner-OAuth -> bq-scheduler@ migration (and any future one) keeps matching.
  #
  # The DTS emits exactly one "Summary: succeeded N jobs, failed M jobs." line per
  # run, on BOTH success ("succeeded 1") and failure ("succeeded 0, failed 1") —
  # verified against live logs (2026-06-21). Matching it gives one terminal heartbeat
  # per run, independent of green/red. (The live freshness metric originally used
  # "completed successfully", which is success-only and missed the migration
  # cutover — see the file header.)
  filter = <<-EOT
    resource.type="bigquery_dts_config"
    resource.labels.config_id="${each.value.config_id}"
    jsonPayload.message=~"^Summary: succeeded"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# --- Alert: a monitored heartbeat has been ABSENT for >25h (silent scheduler death) ---
resource "google_monitoring_alert_policy" "scheduler_absent" {
  for_each = local.scheduler_absence_monitors

  project      = var.project_id
  display_name = each.value.alert_display_name
  combiner     = "OR"

  conditions {
    display_name = each.value.condition_display_name

    # VERIFIED LIVE FORM (2026-06-21, freshness): a PromQL condition, NOT classic
    # MetricAbsence (which caps at 24h and so cannot express the >25h window).
    # absent_over_time(...) returns 1 when the heartbeat metric has had no sample in
    # the lookback, firing the alert. The PromQL metric name is the Monitoring
    # mapping of the log-metric type (logging.googleapis.com/user/<name> ->
    # logging_googleapis_com:user_<name>), built from the resource so the two never
    # drift. evaluation_interval is per monitor and matches the LIVE policies (30s; freshness
    # 1800s); duration is the §56 pending period.
    condition_prometheus_query_language {
      query               = "absent_over_time(logging_googleapis_com:user_${google_logging_metric.scheduler_run[each.key].name}[25h])"
      duration            = local.scheduler_absence_duration
      evaluation_interval = each.value.evaluation_interval
    }
  }

  # Live: notificationPrompts = [OPENED] only, i.e. no "resolved" email by design.
  alert_strategy {
    notification_prompts = ["OPENED"]
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = "${each.value.documentation}${replace(local.scheduler_absence_triage, "<id>", each.value.config_id)}"
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
#
# NOTE: structurally different from the five monitors above (an EVENT detector — increase(...) > 0 —
# not an absence detector) — deliberately left OUT of the scheduler_absence_monitors for_each/map
# refactor, and its duration stays 0s: increase()>0 is only true for ~10 min after the event, so a
# pending period would let a real key creation expire before it ever opened an incident.
# (Corrected 2026-10-03: the spec below used to be a condition_threshold that never matched the LIVE
# policy, which is the PromQL form with display names as written here and, until the §56 apply, EMPTY
# documentation.)
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

locals {
  sa_key_created_documentation = "A user-managed (downloadable) key was just created on gh-ci-runner@ or bq-scheduler@ — both are supposed to be keyless (WIF, RUNBOOK §6/§15/§25). If you did not intend this, DELETE the key immediately (gcloud iam service-accounts keys delete) and investigate who created it. Pairs with the monthly keyless-sa-audit.yml state assertion."
}

resource "google_monitoring_alert_policy" "sa_key_created" {
  project      = var.project_id
  display_name = "SA key created on gh-ci-runner or bq-scheduler"
  combiner     = "OR"

  conditions {
    display_name = "SA key created (should always be 0)"
    condition_prometheus_query_language {
      # Log-based metrics surface under resource.type="global" in this project (see the 2026-07-17
      # fire-drill note further down), hence the monitored_resource selector.
      query               = "increase(logging_googleapis_com:user_${google_logging_metric.sa_key_created.name}{monitored_resource=\"global\"}[10m]) > 0"
      duration            = "0s"
      evaluation_interval = "30s"
    }
  }

  alert_strategy {
    notification_prompts = ["OPENED"]
  }

  notification_channels = local.scheduler_alert_channels

  documentation {
    content   = local.sa_key_created_documentation
    mime_type = "text/markdown"
  }
}

###############################################################################
# SPEC ONLY — NOT VERIFIED LIVE, NOT APPLIED (self-improvement audit ITEM 6, 2026-07-11).
# 2nd notification channel for bigquery/scheduled_queries/safety_critical_dml_watch.sql (the primary
# channel: a scheduled query that RAISEs + writes a critical ops.alerts row on any out-of-band
# UPDATE/DELETE/MERGE/TRUNCATE on ops.trading_control / ops.arsenal_control /
# events.strategy_lifecycle / perf.strategy_daily — RUNBOOK §15). This sketch is DELIBERATELY LEFT
# APPLIED LIVE 2026-07-17 (via the Monitoring API + gcloud, NOT Terraform — this module stays spec-only
# per RUNBOOK's "Settled decisions"; the block below documents the live resources). The earlier draft
# here was a metric+threshold spec using the LEGACY protoPayload.serviceData.jobCompletedEvent.* audit
# shape and an unverified filter. The 2026-07-17 fire-drill (§15) finally verified it against a live
# sample and found TWO things that would have made the old spec silently never fire:
#   (1) this project emits the MODERN BigQueryAuditMetadata shape
#       (protoPayload.metadata.jobChange.job.jobConfig.queryConfig.*), NOT the legacy serviceData shape;
#   (2) this project's log-based *metrics* surface under resource.type="global" (see sa_key_created's
#       PromQL query), so a metric-threshold condition with a naive resource.type would also miss.
# The live policy therefore uses a conditionMatchedLog (log-match — alerts directly on the log entry, no
# metric indirection) with the VERIFIED modern filter, and it REPLICATES the primary watch's one
# sanctioned exclusion (the nightly `DELETE FROM perf.strategy_daily WHERE TRUE` rebuild) so it does not
# false-alarm nightly. Data Access (DATA_WRITE only, not DATA_READ — cost) audit logging was enabled via
# the auditConfig below. Live: alert policy "Safety-critical DML detected" id 466668310285526135,
# notifying the two scheduler-absence email channels.
#
# resource "google_project_iam_audit_config" "bigquery_data_write" {
#   project = var.project_id
#   service = "bigquery.googleapis.com"
#   audit_log_config { log_type = "DATA_WRITE" }
# }
#
# resource "google_monitoring_alert_policy" "safety_critical_dml" {
#   project      = var.project_id
#   display_name = "Safety-critical DML detected"
#   combiner     = "OR"
#   conditions {
#     display_name = "UPDATE/DELETE/MERGE/TRUNCATE on trading_control/arsenal_control/strategy_lifecycle/strategy_daily"
#     condition_matched_log {
#       filter = <<-EOT
#         resource.type="bigquery_project"
#         protoPayload.methodName="google.cloud.bigquery.v2.JobService.InsertJob"
#         protoPayload.metadata.jobChange.job.jobConfig.queryConfig.statementType=("UPDATE" OR "DELETE" OR "MERGE" OR "TRUNCATE_TABLE")
#         (
#           protoPayload.metadata.jobChange.job.jobConfig.queryConfig.destinationTable="projects/stock-trading-498512/datasets/ops/tables/trading_control"
#           OR protoPayload.metadata.jobChange.job.jobConfig.queryConfig.destinationTable="projects/stock-trading-498512/datasets/ops/tables/arsenal_control"
#           OR protoPayload.metadata.jobChange.job.jobConfig.queryConfig.destinationTable="projects/stock-trading-498512/datasets/events/tables/strategy_lifecycle"
#           OR protoPayload.metadata.jobChange.job.jobConfig.queryConfig.destinationTable="projects/stock-trading-498512/datasets/perf/tables/strategy_daily"
#         )
#         NOT (
#           protoPayload.metadata.jobChange.job.jobConfig.queryConfig.destinationTable="projects/stock-trading-498512/datasets/perf/tables/strategy_daily"
#           AND protoPayload.metadata.jobChange.job.jobConfig.queryConfig.statementType="DELETE"
#           AND protoPayload.metadata.jobChange.job.jobConfig.queryConfig.query=~"(?i)delete\s+from.*perf.strategy_daily.*where\s+true"
#         )
#       EOT
#     }
#   }
#   alert_strategy { notification_rate_limit { period = "300s" } }
#   notification_channels = local.scheduler_alert_channels
#   documentation {
#     content   = "Out-of-band UPDATE/DELETE/MERGE/TRUNCATE on an INSERT-only safety-critical table (ops.trading_control / ops.arsenal_control / events.strategy_lifecycle / perf.strategy_daily), excluding the sanctioned nightly perf.strategy_daily rebuild. 2nd, scheduler-independent channel for bigquery/scheduled_queries/safety_critical_dml_watch.sql (RUNBOOK item 6/§15). Investigate the triggering job in region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT immediately."
#     mime_type = "text/markdown"
#   }
# }
###############################################################################

#!/usr/bin/env bash
# Adopt the Console-created scheduler heartbeat monitors into Terraform state, so
# infra/terraform/monitoring.tf OWNS the log metrics + alert policies + email channel
# (freshness, backup, cadence) that previously lived ONLY in the Console — the exact
# gap that caused the 2026-06-20 false alarm (ops/RUNBOOK.md §19). Idempotent: an
# address already in state is skipped, and a failed single import does not abort the rest.
#
# WHERE TO RUN: from infra/terraform/, in a GCP-authenticated shell with Terraform +
# gcloud installed (e.g. Cloud Shell). It CANNOT run in a Claude session container
# (no terraform/gcloud, no GCS state backend creds).
#
# PREREQS (in order):
#   1. terraform init                         # connects to the gs://stock-trading-tfstate backend
#   2. Import the scheduled-query configs the metrics derive their config_id from
#      (regex over .name), so they're in state first — freshness, backup, cadence:
#        PN=$(gcloud projects describe stock-trading-498512 --format='value(projectNumber)')
#        terraform import google_bigquery_data_transfer_config.freshness_check projects/$PN/locations/us/transferConfigs/6a9c1592-0000-2caa-86b1-089e08214038
#        terraform import google_bigquery_data_transfer_config.backup_export    projects/$PN/locations/us/transferConfigs/6a509810-0000-2279-a65e-f4f5e80c4144
#        terraform import google_bigquery_data_transfer_config.cadence_check    projects/$PN/locations/us/transferConfigs/6a44a3d9-0000-2837-8b7b-883d24f5c8b8
#   3. Set notification_emails in terraform.tfvars to include CHANNEL_EMAIL below,
#      or the channel's for_each key won't exist in config and its import is skipped:
#        notification_emails = ["jacksterwu@gmail.com"]
#
# Then: ./import_monitoring.sh && terraform plan   # expect NO changes (clean adoption).
set -uo pipefail

PROJECT_ID="${PROJECT_ID:-stock-trading-498512}"
CHANNEL_EMAIL="${CHANNEL_EMAIL:-jacksterwu@gmail.com}"

cd "$(dirname "$0")"

import_if_absent() { # $1 = terraform address, $2 = import id
  local addr="$1" id="$2"
  if terraform state show "$addr" >/dev/null 2>&1; then
    echo "✓ already in state: $addr"
  elif [[ -z "$id" ]]; then
    echo "!! could not resolve an import id for $addr — skipping (resolve + import manually)" >&2
  elif terraform import "$addr" "$id"; then
    echo "✓ imported: $addr"
  else
    echo "!! import FAILED for $addr (id: $id) — continuing; resolve manually" >&2
  fi
}

import_policy() { # $1 = terraform address, $2 = policy display_name
  local addr="$1" disp="$2" name
  name="$(gcloud alpha monitoring policies list --project="$PROJECT_ID" \
    --filter="displayName=\"$disp\"" --format='value(name)' 2>/dev/null | head -n1 || true)"
  import_if_absent "$addr" "$name"
}

# 1) Log-based metrics — import id is just the metric name.
import_if_absent google_logging_metric.freshness_scheduled_run freshness_scheduled_run
import_if_absent google_logging_metric.backup_scheduled_run    backup_scheduled_run
import_if_absent google_logging_metric.cadence_scheduled_run   cadence_scheduled_run

# 2) Alert policies — resolved to projects/<num>/alertPolicies/<id> by display name.
import_policy google_monitoring_alert_policy.freshness_scheduler_absent "Freshness scheduler absent >25h"
import_policy google_monitoring_alert_policy.backup_scheduler_absent    "Backup scheduler absent >25h"
import_policy google_monitoring_alert_policy.cadence_scheduler_absent   "Cadence scheduler absent >25h"

# 3) Email notification channel — resolved by email label, shared by all three policies.
channel_name="$(gcloud alpha monitoring channels list \
  --project="$PROJECT_ID" \
  --filter="type=email AND labels.email_address=\"$CHANNEL_EMAIL\"" \
  --format='value(name)' 2>/dev/null | head -n1 || true)"
import_if_absent "google_monitoring_notification_channel.scheduler_alert_email[\"$CHANNEL_EMAIL\"]" "$channel_name"

echo
echo "Now verify a clean adoption (expect 0 changes to the monitoring resources):"
echo "  terraform plan"

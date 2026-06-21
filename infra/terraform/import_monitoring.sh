#!/usr/bin/env bash
# Adopt the Console-created freshness heartbeat monitor into Terraform state, so
# infra/terraform/monitoring.tf OWNS the log metric + alert policy + email channel
# that previously lived ONLY in the Console — the exact gap that caused the
# 2026-06-20 false alarm (ops/RUNBOOK.md §19). Idempotent: an address already in
# state is skipped, and a failed single import does not abort the rest.
#
# WHERE TO RUN: from infra/terraform/, in a GCP-authenticated shell with Terraform +
# gcloud installed (e.g. Cloud Shell). It CANNOT run in a Claude session container
# (no terraform/gcloud, no GCS state backend creds).
#
# PREREQS (in order):
#   1. terraform init                         # connects to the gs://stock-trading-tfstate backend
#   2. Import the freshness scheduled query — monitoring.tf derives the metric's
#      config_id from it (regex over .name), so it must be in state first:
#        terraform import google_bigquery_data_transfer_config.freshness_check \
#          projects/<PROJECT_NUMBER>/locations/us/transferConfigs/6a9c1592-0000-2caa-86b1-089e08214038
#      (find <PROJECT_NUMBER>: gcloud projects describe stock-trading-498512 \
#          --format='value(projectNumber)')
#   3. Set notification_emails in terraform.tfvars to include CHANNEL_EMAIL below,
#      or the channel's for_each key won't exist in config and its import is skipped:
#        notification_emails = ["jacksterwu@gmail.com"]
#
# Then: ./import_monitoring.sh && terraform plan   # expect NO changes (clean adoption).
set -uo pipefail

PROJECT_ID="${PROJECT_ID:-stock-trading-498512}"
METRIC_NAME="${METRIC_NAME:-freshness_scheduled_run}"
POLICY_DISPLAY="${POLICY_DISPLAY:-Freshness scheduler absent >25h}"
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

# 1) Log-based metric — import id is just the metric name.
import_if_absent google_logging_metric.freshness_scheduled_run "$METRIC_NAME"

# 2) Alert policy — resolve its resource name (projects/<num>/alertPolicies/<id>) by display name.
policy_name="$(gcloud alpha monitoring policies list \
  --project="$PROJECT_ID" \
  --filter="displayName=\"$POLICY_DISPLAY\"" \
  --format='value(name)' 2>/dev/null | head -n1 || true)"
import_if_absent google_monitoring_alert_policy.freshness_scheduler_absent "$policy_name"

# 3) Email notification channel — resolve (projects/<num>/notificationChannels/<id>) by email label.
channel_name="$(gcloud alpha monitoring channels list \
  --project="$PROJECT_ID" \
  --filter="type=email AND labels.email_address=\"$CHANNEL_EMAIL\"" \
  --format='value(name)' 2>/dev/null | head -n1 || true)"
import_if_absent "google_monitoring_notification_channel.scheduler_alert_email[\"$CHANNEL_EMAIL\"]" "$channel_name"

echo
echo "Now verify a clean adoption (expect 0 changes to these 3 resources):"
echo "  terraform plan"

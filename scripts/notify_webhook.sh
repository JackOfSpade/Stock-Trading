#!/usr/bin/env bash
# Shared best-effort webhook notifier (2026-07-04, code-quality audit).
#
# WHY: the "POST a failure message to the webhook, JSON-escape it, warn-not-fail on a curl error"
# snippet was duplicated across offsite-backup.yml, keyless-sa-audit.yml, and wif-binding-audit.yml —
# and keyless-sa-audit.yml used a more convoluted JSON-escaping idiom (printf '{"text":%s}' wrapping a
# separately-escaped string) than the other two's single `python3 -c json.dumps({"text": ...})` call.
# This consolidates all three onto the simpler, canonical idiom.
#
# Usage:  WEBHOOK_URL=https://... scripts/notify_webhook.sh "message text"
#
# If WEBHOOK_URL is unset/empty this is a silent no-op — every call site already treats the webhook
# post itself as optional/best-effort. A curl failure prints a ::warning:: but NEVER exits non-zero:
# the caller's own failure (a drift/audit/backup finding) is the real result of the run; a dead
# notification channel must not mask it or replace it as the reported failure.
set -euo pipefail

msg="${1:?Usage: WEBHOOK_URL=... notify_webhook.sh <message>}"

if [ -z "${WEBHOOK_URL:-}" ]; then
  exit 0
fi

curl -fsS -X POST -H 'Content-Type: application/json' \
  --data "$(printf '%s' "$msg" | python3 -c 'import json,sys;print(json.dumps({"text":sys.stdin.read()}))')" \
  "$WEBHOOK_URL" || echo "::warning::webhook post failed (the caller's own failure still stands)."

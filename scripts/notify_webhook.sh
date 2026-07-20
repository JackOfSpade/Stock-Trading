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
#
# OAE-6 (2026-07-16, self-provisioned ntfy.sh second channel): unlike scripts/alert_relay.py's post(),
# this script is NOT given a plain-text branch — on an ntfy.sh WEBHOOK_URL the JSON body below still
# arrives as a literal '{"text": "..."}' string in the push notification rather than rendered plain
# text. These are best-effort CI-failure notices (offsite-backup / keyless-sa-audit / wif-binding-
# audit), so a slightly ugly-but-legible JSON string still delivers the finding; not worth the extra
# code path for this file. The optional branch below exists purely for readability if you want it.
set -euo pipefail

msg="${1:?Usage: WEBHOOK_URL=... notify_webhook.sh <message>}"

if [ -z "${WEBHOOK_URL:-}" ]; then
  exit 0
fi

case "$WEBHOOK_URL" in
  *ntfy.sh*)
    # BUG FIX (2026-07-20 code-review, C18): --data-raw, not --data. curl gives --data a special
    # meaning when its value starts with the literal character '@' (read the POST body from a file
    # of that name instead of sending the string) -- an interpolated message ($offenders, $problems,
    # etc.) that happens to start with '@' would silently fail (file not found) or, worse, send an
    # unrelated local file's bytes instead. --data-raw sends every input, including a leading '@',
    # literally -- a drop-in, behavior-preserving fix for every message sent so far.
    curl -fsS -X POST -H 'Title: Stock-Trading' --data-raw "$msg" "$WEBHOOK_URL" \
      || echo "::warning::webhook post failed (the caller's own failure still stands)."
    ;;
  *)
    curl -fsS -X POST -H 'Content-Type: application/json' \
      --data "$(printf '%s' "$msg" | python3 -c 'import json,sys;print(json.dumps({"text":sys.stdin.read()}))')" \
      "$WEBHOOK_URL" || echo "::warning::webhook post failed (the caller's own failure still stands)."
    ;;
esac

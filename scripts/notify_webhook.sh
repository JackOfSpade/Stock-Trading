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
# ntfy.sh accepts a plain-text body; other endpoints receive {"text": ...} JSON.
# Match the parsed hostname so an unrelated endpoint containing ntfy.sh in its path,
# query, or credentials is never sent the wrong payload format.
set -euo pipefail

# `${1-}` (unset -> empty), NOT `${1:?...}`: the `:?` form also rejects an EMPTY first argument with a
# non-zero exit, contradicting the never-exits-non-zero contract above (same null-vs-unset class
# scripts/ci_finding.sh documents for its `detail` argument; 2026-10-31). An empty message is a no-op.
msg="${1-}"
if [ -z "$msg" ]; then
  echo "::warning::notify_webhook.sh called with an empty message (nothing posted; the caller's own failure still stands)."
  exit 0
fi

if [ -z "${WEBHOOK_URL:-}" ]; then
  exit 0
fi

if ! webhook_host="$(python3 -c 'import sys,urllib.parse; print((urllib.parse.urlsplit(sys.argv[1]).hostname or "").removesuffix("."))' "$WEBHOOK_URL" 2>/dev/null)"; then
  echo "::warning::webhook URL could not be parsed (the caller's own failure still stands)."
  exit 0
fi
case "$webhook_host" in
  ntfy.sh)
    # BUG FIX (2026-07-20 code-review, C18): --data-raw, not --data. curl gives --data a special
    # meaning when its value starts with the literal character '@' (read the POST body from a file
    # of that name instead of sending the string) -- an interpolated message ($offenders, $problems,
    # etc.) that happens to start with '@' would silently fail (file not found) or, worse, send an
    # unrelated local file's bytes instead. --data-raw sends every input, including a leading '@',
    # literally -- a drop-in, behavior-preserving fix for every message sent so far.
    curl -fsS -X POST -H 'Title: Stock-Trading' --data-raw "$msg" \
      --connect-timeout 10 --max-time 30 -- "$WEBHOOK_URL" \
      || echo "::warning::webhook post failed (the caller's own failure still stands)."
    ;;
  *)
    curl -fsS -X POST -H 'Content-Type: application/json' \
      --data "$(printf '%s' "$msg" | python3 -c 'import json,sys;print(json.dumps({"text":sys.stdin.read()}))')" \
      --connect-timeout 10 --max-time 30 -- "$WEBHOOK_URL" \
      || echo "::warning::webhook post failed (the caller's own failure still stands)."
    ;;
esac

#!/usr/bin/env bash
# Functional tests for scripts/notify_webhook.sh -- the shared CI-failure webhook notifier used by
# keyless-sa-audit.yml, wif-binding-audit.yml, offsite-backup.yml, and sql-dryrun-sweep.yml
# (2026-07-20 code-review, C19 -- narrowed scope). Mirrors tests/test_auto_merge_logic.sh's pattern:
# this script previously had ZERO functional coverage, only shellcheck syntax-level checks (the same
# gap class that precedent was created to close). Deliberately out of scope: backup_events.sh,
# restore_drill.sh, state_snapshot.sh -- not covered here.
#
# curl is stubbed via a PATH shim that captures its full argv (NUL-separated, so an embedded space or
# newline in the message can't be mistaken for an argument boundary) to a file and exits 0. NO real
# network call is made anywhere in this test.
#
# Scenarios covered:
#   * the ntfy.sh branch's curl invocation uses --data-raw (not --data) and sends the message literally
#     (the C18 fix -- curl's --data gives a leading '@' a special "read this filename" meaning)
#   * the default/JSON branch builds a {"text": ...} body via python3 and sends it via --data (the
#     JSON body always starts with '{', so it was never exposed to the --data/'@' quirk)
#   * a message starting with '@' reaches curl byte-for-byte literal on the ntfy.sh branch, still via
#     --data-raw -- this pins the exact regression C18 fixed
#
# Run:  bash tests/test_notify_webhook.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail=0
pass_count=0

assert_eq() {     # assert_eq <description> <actual> <expected>
  local desc="$1" actual="$2" expected="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (expected '$expected', got '$actual')"
    fail=1
  fi
}

SCRATCH="$(mktemp -d)"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

mkdir -p "$SCRATCH/bin"
CAPTURE="$SCRATCH/curl_argv"

# Stub curl: captures its own argv (NUL-separated) to $CURL_CAPTURE_FILE and exits 0 -- never touches
# the network. notify_webhook.sh's unqualified `curl` call resolves to this stub because $SCRATCH/bin
# is prepended to PATH (see run_notify below), ahead of the real curl.
cat > "$SCRATCH/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" > "${CURL_CAPTURE_FILE:?CURL_CAPTURE_FILE must be set}"
exit 0
STUB
chmod +x "$SCRATCH/bin/curl"

run_notify() {   # run_notify <webhook_url> <message> -- invokes the real script under test
  CURL_CAPTURE_FILE="$CAPTURE" WEBHOOK_URL="$1" PATH="$SCRATCH/bin:$PATH" \
    bash "$ROOT/scripts/notify_webhook.sh" "$2"
}

read_argv() {    # populates the global `argv` array from the NUL-separated capture file
  argv=()
  while IFS= read -r -d '' a; do argv+=("$a"); done < "$CAPTURE"
}

# ---- ntfy.sh branch: --data-raw, message sent literally (the C18 fix) -----------------------------

msg="a plain ntfy message"
run_notify "https://ntfy.sh/some-topic" "$msg"
read_argv
assert_eq "ntfy.sh branch: curl -fsS is present" "${argv[0]:-}" "-fsS"
assert_eq "ntfy.sh branch: -H Title header is sent unquoted-literal" "${argv[4]:-}" "Title: Stock-Trading"
assert_eq "ntfy.sh branch: uses --data-raw (not --data), the C18 fix" "${argv[5]:-}" "--data-raw"
assert_eq "ntfy.sh branch: message body is sent literally" "${argv[6]:-}" "$msg"
assert_eq "ntfy.sh branch: WEBHOOK_URL is the last arg" "${argv[7]:-}" "https://ntfy.sh/some-topic"

# ---- default/JSON branch: {"text": ...} body via --data ------------------------------------------

msg='a generic webhook message with "quotes" and a
newline in it'
run_notify "https://hooks.example.com/generic" "$msg"
read_argv
assert_eq "default branch: uses --data (JSON body always starts with '{', unaffected by the @ bug)" \
  "${argv[5]:-}" "--data"
expected_json="$(printf '%s' "$msg" | python3 -c 'import json,sys;print(json.dumps({"text":sys.stdin.read()}))')"
assert_eq "default branch: JSON body matches {\"text\": <message>} exactly" "${argv[6]:-}" "$expected_json"
assert_eq "default branch: WEBHOOK_URL is the last arg" "${argv[7]:-}" "https://hooks.example.com/generic"

# ---- message starting with '@': the exact C18 regression ------------------------------------------
# A stubbed curl can't reproduce real curl's own "--data '@x' reads file x" parsing quirk directly, but
# it CAN pin the two things that quirk depends on: (a) --data-raw is the flag actually used (not
# --data), and (b) the leading '@' reaches curl as part of the literal argv value, untouched by any
# shell-level stripping/reinterpretation in notify_webhook.sh itself.
msg="@problems: dbt-parity found 3 offenders"
run_notify "https://ntfy.sh/some-topic" "$msg"
read_argv
assert_eq "leading-'@' message: still --data-raw, not --data" "${argv[5]:-}" "--data-raw"
assert_eq "leading-'@' message: body reaches curl byte-for-byte literal, '@' and all" "${argv[6]:-}" "$msg"

echo
if [ "$fail" -ne 0 ]; then
  echo "notify_webhook tests: FAILED"
  exit 1
fi
echo "notify_webhook tests: all $pass_count assertions passed"

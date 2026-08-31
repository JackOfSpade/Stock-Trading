#!/usr/bin/env bash
# Functional tests for scripts/ci_finding.sh -- the shared ops.ci_findings VALUES-row writer used
# by alert-relay.yml, auto-merge-claude.yml, guard-config-audit.yml, keyless-sa-audit.yml,
# live-sql-parity.yml, sql-dryrun-sweep.yml, stranded-branch-check.yml, and wif-binding-audit.yml
# (2026-08-31, code-quality pass, shell-workflows#0). Mirrors tests/test_notify_webhook.sh's
# pattern exactly: this script previously had ZERO coverage (it didn't exist -- the 25 call sites
# it replaces had zero functional coverage of their own, only YAML syntax validity via actionlint).
#
# bq is stubbed via a PATH shim that captures its full argv (NUL-separated, so an embedded space
# or newline in a detail string can't be mistaken for an argument boundary) to a file. NO real
# network call and NO real BigQuery credentials are touched anywhere in this test.
#
# Scenarios covered:
#   * the emitted bq invocation: --project_id, --use_legacy_sql=false, the 5 named @p_* parameters
#     (workflow/key/status/detail/url) each typed STRING, and the exact INSERT...VALUES SQL text
#   * run_url is built from GitHub Actions' own default env vars (GITHUB_SERVER_URL /
#     GITHUB_REPOSITORY / GITHUB_RUN_ID), not passed as a 5th positional argument
#   * a detail value containing embedded spaces, quotes, and a newline reaches bq byte-for-byte
#     literal (pins the exact shape live-sql-parity.yml's `head -c 4000 /tmp/parity_out.txt` and
#     sql-dryrun-sweep.yml's multi-line finding details rely on)
#   * a non-fatal bq failure: the script's own exit code propagates bq's exit status (it does NOT
#     swallow it into a warning itself, unlike notify_webhook.sh) -- the fail-loud vs fail-soft
#     choice stays with the CALLER, matching the 25 call sites' own `|| echo ::warning::` vs
#     `if ! ...; then ...; exit 1; fi` split
#   * missing-argument usage errors exit non-zero with a usage message, for each of the 4 required args
#   * REGRESSION (2026-08-31 code-quality pass, fixing a bug from earlier in this same pass): an
#     EMPTY detail is a valid VALUE (bq is still invoked, with an empty p_detail:STRING: parameter),
#     NOT a missing argument -- `${4:?msg}` used to conflate the two and silently drop the row; and a
#     genuinely wrong arg COUNT (3 args, 5 args) still fails with the usage error either way
#
# Run:  bash tests/test_ci_finding.sh
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

assert_status() {  # assert_status <description> <actual_exit> <expected_exit>
  assert_eq "$1" "$2" "$3"
}

SCRATCH="$(mktemp -d)"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

mkdir -p "$SCRATCH/bin"
CAPTURE="$SCRATCH/bq_argv"

# Stub bq: captures its own argv (NUL-separated) to $BQ_CAPTURE_FILE and exits with
# $BQ_STUB_EXIT_CODE (default 0) -- never touches the network or real BigQuery credentials.
# ci_finding.sh's unqualified `bq` call resolves to this stub because $SCRATCH/bin is prepended
# to PATH (see run_ci_finding below), ahead of the real bq.
cat > "$SCRATCH/bin/bq" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" > "${BQ_CAPTURE_FILE:?BQ_CAPTURE_FILE must be set}"
exit "${BQ_STUB_EXIT_CODE:-0}"
STUB
chmod +x "$SCRATCH/bin/bq"

run_ci_finding() {   # run_ci_finding <workflow> <key> <status> <detail> -- invokes the real script
  BQ_CAPTURE_FILE="$CAPTURE" \
    GITHUB_SERVER_URL="https://github.example" \
    GITHUB_REPOSITORY="jacksterwu/Stock-Trading" \
    GITHUB_RUN_ID="123456789" \
    PATH="$SCRATCH/bin:$PATH" \
    bash "$ROOT/scripts/ci_finding.sh" "$1" "$2" "$3" "$4"
}

read_argv() {    # populates the global `argv` array from the NUL-separated capture file
  argv=()
  while IFS= read -r -d '' a; do argv+=("$a"); done < "$CAPTURE"
}

# ---- happy path: the exact bq invocation shape -----------------------------------------------

set +e
run_ci_finding "guard-config-audit" "guard_config" "open" "the WIF vars are unset"
rc=$?
set -e
assert_status "happy path: script exits 0 when bq exits 0" "$rc" "0"

read_argv
assert_eq "argv[0]: query subcommand" "${argv[0]:-}" "query"
assert_eq "argv[1]: --project_id pinned to the live project" "${argv[1]:-}" "--project_id=stock-trading-498512"
assert_eq "argv[2]: --use_legacy_sql=false" "${argv[2]:-}" "--use_legacy_sql=false"
assert_eq "argv[3]: p_workflow parameter, typed STRING, carries the workflow arg" \
  "${argv[3]:-}" "--parameter=p_workflow:STRING:guard-config-audit"
assert_eq "argv[4]: p_key parameter carries the finding_key arg" \
  "${argv[4]:-}" "--parameter=p_key:STRING:guard_config"
assert_eq "argv[5]: p_status parameter carries the status arg" \
  "${argv[5]:-}" "--parameter=p_status:STRING:open"
assert_eq "argv[6]: p_detail parameter carries the detail arg" \
  "${argv[6]:-}" "--parameter=p_detail:STRING:the WIF vars are unset"
assert_eq "argv[7]: p_url parameter built from GITHUB_SERVER_URL/REPOSITORY/RUN_ID, not a 5th arg" \
  "${argv[7]:-}" "--parameter=p_url:STRING:https://github.example/jacksterwu/Stock-Trading/actions/runs/123456789"
assert_eq "argv[8]: the INSERT...VALUES SQL text, named-parameter placeholders only" \
  "${argv[8]:-}" 'INSERT INTO `stock-trading-498512.ops.ci_findings` (workflow, finding_key, status, detail, run_url) VALUES (@p_workflow, @p_key, @p_status, @p_detail, @p_url)'
assert_eq "argv has exactly 9 elements (no stray trailing arg)" "${#argv[@]}" "9"

# ---- a resolved-row call (literal detail, matching e.g. keyless-sa-audit.yml's clean path) ----

run_ci_finding "keyless-sa-audit" "keyless_sa" "resolved" "audit clean this run"
read_argv
assert_eq "resolved call: p_status carries 'resolved'" "${argv[5]:-}" "--parameter=p_status:STRING:resolved"
assert_eq "resolved call: p_detail carries the literal clean-run message" \
  "${argv[6]:-}" "--parameter=p_detail:STRING:audit clean this run"

# ---- a detail value with embedded spaces, a double-quote, and a newline reaches bq literal -----
# (pins the exact shape a `head -c 4000 /tmp/parity_out.txt`-derived detail, or a per-file
# "parse error on dry-run: ..." detail, relies on -- no re-quoting/escaping happens in between)

msg='live definition does NOT match the final-effective definition in 02_x.sql (view)
second line with a "quoted" phrase and a colon: like this'
run_ci_finding "live-sql-parity" "state.gone" "open" "$msg"
read_argv
assert_eq "multiline/quoted detail: p_detail reaches bq byte-for-byte literal" \
  "${argv[6]:-}" "--parameter=p_detail:STRING:${msg}"

# ---- a finding_key built from shell interpolation (e.g. alert-relay.yml's relay_\${MODE}) ------

run_ci_finding "alert-relay" "relay_heartbeat" "open" "relay run failed — see issue/run"
read_argv
assert_eq "interpolated finding_key: p_key carries the composed key" \
  "${argv[4]:-}" "--parameter=p_key:STRING:relay_heartbeat"
assert_eq "em-dash detail survives untouched" \
  "${argv[6]:-}" "--parameter=p_detail:STRING:relay run failed — see issue/run"

# ---- bq failure: exit status propagates, NOT swallowed into a warning by this script itself ---

set +e
BQ_STUB_EXIT_CODE=1 run_ci_finding "wif-binding-audit" "wif_binding" "open" "some finding"
rc=$?
set -e
assert_status "bq failure: script propagates bq's non-zero exit (caller decides fail-loud/soft)" "$rc" "1"

# ---- missing-argument usage errors ------------------------------------------------------------

for n in 1 2 3 4; do
  args=(workflow key status detail)
  usage_err="$SCRATCH/usage_err"
  # Truncate the arg list to n-1 args so the nth (1-indexed) required arg is the one that's missing.
  set +e
  case "$n" in
    1) BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" bash "$ROOT/scripts/ci_finding.sh" 2>"$usage_err" ;;
    2) BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" bash "$ROOT/scripts/ci_finding.sh" "${args[0]}" 2>"$usage_err" ;;
    3) BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" bash "$ROOT/scripts/ci_finding.sh" "${args[0]}" "${args[1]}" 2>"$usage_err" ;;
    4) BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" bash "$ROOT/scripts/ci_finding.sh" "${args[0]}" "${args[1]}" "${args[2]}" 2>"$usage_err" ;;
  esac
  rc=$?
  set -e
  assert_status "missing arg #$n: exits non-zero" "$rc" "1"
  if ! grep -q "Usage: ci_finding.sh" "$usage_err"; then
    echo "FAIL: missing arg #$n: stderr should carry the Usage message (got: $(cat "$usage_err"))"
    fail=1
  else
    echo "PASS: missing arg #$n: stderr carries the Usage message"
    pass_count=$((pass_count + 1))
  fi
done

# ---- REGRESSION (2026-08-31 code-quality pass): empty detail is a VALUE, not a missing arg -----
# The bug: `${4:?msg}` fires on an empty string, not just an unset/omitted arg, so it used to abort
# before bq was ever invoked -- silently dropping an ops.ci_findings row the inline `bq query
# --parameter="p_detail:STRING:${detail}" ...` call this script replaced would have written (an empty
# STRING parameter is a perfectly valid insert). Reachable via sql-dryrun-sweep.yml's
# `check_sql_dryrun.py | tee sweep.txt` (no `2>&1`): a checker crash before any stdout output leaves
# sweep.txt 0 bytes, so `detail=$(head -c 4000 sweep.txt)` is "".

set +e
run_ci_finding "sql-dryrun-sweep" "sql_dryrun_sweep" "open" ""
rc=$?
set -e
assert_status "empty detail: script still exits 0 -- bq is invoked, not short-circuited" "$rc" "0"
read_argv
assert_eq "empty detail: p_detail parameter carries an EMPTY value, not omitted" \
  "${argv[6]:-}" "--parameter=p_detail:STRING:"
assert_eq "empty detail: argv still has exactly 9 elements (bq really was invoked)" "${#argv[@]}" "9"

# ---- a genuinely wrong arg COUNT (not just a trailing arg omitted) still fails with usage error --
# Distinguishes "$# != 4" (a real usage error) from "one of the 4 args is empty" (a valid call,
# asserted above) -- the fix must not conflate them in either direction.

for desc_n in "3 args" "5 args"; do
  usage_err="$SCRATCH/usage_err_${desc_n// /_}"
  set +e
  case "$desc_n" in
    "3 args") BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" \
      bash "$ROOT/scripts/ci_finding.sh" "workflow" "key" "status" 2>"$usage_err" ;;
    "5 args") BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" \
      bash "$ROOT/scripts/ci_finding.sh" "workflow" "key" "status" "detail" "extra" 2>"$usage_err" ;;
  esac
  rc=$?
  set -e
  assert_status "$desc_n: exits non-zero" "$rc" "1"
  if ! grep -q "Usage: ci_finding.sh" "$usage_err"; then
    echo "FAIL: $desc_n: stderr should carry the Usage message (got: $(cat "$usage_err"))"
    fail=1
  else
    echo "PASS: $desc_n: stderr carries the Usage message"
    pass_count=$((pass_count + 1))
  fi
done

echo
if [ "$fail" -ne 0 ]; then
  echo "ci_finding tests: FAILED"
  exit 1
fi
echo "ci_finding tests: all $pass_count assertions passed"

#!/usr/bin/env bash
# Functional tests for scripts/bq_csv.sh -- the bq CSV-query helpers shared by
# scripts/backup_events.sh, scripts/restore_drill.sh, and scripts/state_snapshot.sh (extracted
# 2026-08-31, code-quality pass -- shell-workflows#1: the invocation and the events.*
# table-enumeration SQL had been hand-typed near-identically in all three).
#
# `bq` is stubbed via a PATH shim that captures its full argv (NUL-separated, so an embedded
# space in the SQL text can't be mistaken for an argument boundary) and prints canned CSV, mirroring
# tests/test_notify_webhook.sh's curl-stub pattern. NO real network/BigQuery call is made anywhere
# in this test.
#
# Scenarios covered:
#   * bq_csv_query passes the exact flag set/order (--project_id=, query, --use_legacy_sql=false,
#     --format=csv, --quiet, --headless, --max_rows=100000, <sql>) all three production call sites
#     rely on, and returns the CSV WITH its header row -- what state_snapshot.sh's dump() needs
#   * bq_csv_query_headless strips exactly the header row, nothing else
#   * bq_list_events_tables builds the same INFORMATION_SCHEMA.TABLES query backup_events.sh and
#     restore_drill.sh both used to hand-type, and returns table names header-stripped
#
# Run:  bash tests/test_bq_csv.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/bq_csv.sh
source "$ROOT/scripts/bq_csv.sh"

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
CAPTURE="$SCRATCH/bq_argv"

# Stub bq: captures its own argv (NUL-separated) to $BQ_CAPTURE_FILE, then prints canned CSV
# depending on whether the (always-last) SQL argument targets INFORMATION_SCHEMA.TABLES -- so a
# single stub covers both the table-enumeration query and an arbitrary SELECT.
cat > "$SCRATCH/bin/bq" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\0' "$@" > "${BQ_CAPTURE_FILE:?BQ_CAPTURE_FILE must be set}"
sql="${*: -1}"
if [[ "$sql" == *"INFORMATION_SCHEMA.TABLES"* ]]; then
  printf 'table_name\nalpha\nbeta\ngamma\n'
else
  printf 'col_a,col_b\n1,2\n3,4\n'
fi
STUB
chmod +x "$SCRATCH/bin/bq"

read_argv() {    # populates the global `argv` array from the NUL-separated capture file
  argv=()
  while IFS= read -r -d '' a; do argv+=("$a"); done < "$CAPTURE"
}

run_stubbed() {  # run_stubbed <fn> <args...> -- invokes the real function under a stubbed `bq`
  BQ_CAPTURE_FILE="$CAPTURE" PATH="$SCRATCH/bin:$PATH" "$@"
}

# ---- bq_csv_query: exact flag set/order, header row retained ---------------------------------

out="$(run_stubbed bq_csv_query "my-proj" "SELECT 1")"
read_argv
assert_eq "bq_csv_query: --project_id is the first arg" "${argv[0]:-}" "--project_id=my-proj"
assert_eq "bq_csv_query: query is the second arg" "${argv[1]:-}" "query"
assert_eq "bq_csv_query: --use_legacy_sql=false" "${argv[2]:-}" "--use_legacy_sql=false"
assert_eq "bq_csv_query: --format=csv" "${argv[3]:-}" "--format=csv"
assert_eq "bq_csv_query: --quiet" "${argv[4]:-}" "--quiet"
assert_eq "bq_csv_query: --headless" "${argv[5]:-}" "--headless"
assert_eq "bq_csv_query: --max_rows=100000" "${argv[6]:-}" "--max_rows=100000"
assert_eq "bq_csv_query: SQL is the last arg, untouched" "${argv[7]:-}" "SELECT 1"
assert_eq "bq_csv_query: header row is present in the output" "$out" "$(printf 'col_a,col_b\n1,2\n3,4')"

# ---- bq_csv_query_headless: same invocation, header row stripped -----------------------------

out="$(run_stubbed bq_csv_query_headless "my-proj" "SELECT 1")"
read_argv
assert_eq "bq_csv_query_headless: same --project_id as bq_csv_query" "${argv[0]:-}" "--project_id=my-proj"
assert_eq "bq_csv_query_headless: header row is stripped" "$out" "$(printf '1,2\n3,4')"

# ---- bq_list_events_tables: builds the INFORMATION_SCHEMA.TABLES query, header stripped -------

out="$(run_stubbed bq_list_events_tables "my-proj")"
read_argv
sql="${argv[7]:-}"
case "$sql" in
  *'`my-proj.events.INFORMATION_SCHEMA.TABLES`'*) : ;;
  *) echo "FAIL: bq_list_events_tables: SQL targets my-proj.events.INFORMATION_SCHEMA.TABLES (got: $sql)"; fail=1 ;;
esac
case "$sql" in
  *"table_type='BASE TABLE'"*) : ;;
  *) echo "FAIL: bq_list_events_tables: SQL filters WHERE table_type='BASE TABLE' (got: $sql)"; fail=1 ;;
esac
case "$sql" in
  *'ORDER BY table_name'*) : ;;
  *) echo "FAIL: bq_list_events_tables: SQL orders by table_name (got: $sql)"; fail=1 ;;
esac
assert_eq "bq_list_events_tables: table names, header stripped" "$out" "$(printf 'alpha\nbeta\ngamma')"

echo
if [ "$fail" -ne 0 ]; then
  echo "bq_csv tests: FAILED"
  exit 1
fi
echo "bq_csv tests: all $pass_count assertions passed"

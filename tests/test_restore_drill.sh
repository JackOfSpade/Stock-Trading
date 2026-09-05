#!/usr/bin/env bash
# Regression test for scripts/restore_drill.sh's resolve_backup_date() -- the snapshot-DATE
# auto-resolution used whenever the drill is run without DATE= pinned.
#
# BUG THIS GUARDS (2026-09-02 audit finding): the pre-fix loop walked TABLES (alphabetical order,
# via bq_list_events_tables) and `break`d at the FIRST table with ANY dt= partition, using THAT
# table's own newest partition as the global DATE -- never comparing against later tables. A table
# whose daily EXTRACT started silently erroring days ago (bigquery/scheduled_queries/
# backup_events_export.sql isolates each table's export in its own BEGIN/EXCEPTION block specifically
# so one failing table can't abort the rest -- so this is a real, designed failure mode, not a
# hypothetical) but that still has an OLD partition sitting in GCS would silently anchor the WHOLE
# drill at its own stale date the instant it sorts alphabetically first, even though every other
# table has a much fresher snapshot the loop never even looks at.
#
# `resolve_backup_date` is extracted (not sourced whole -- the parent script has top-level
# `set -euo pipefail` side effects, a `bq`/`gcloud` presence check, and a live TABLES query that would
# make it unsourceable in isolation) straight out of the live scripts/restore_drill.sh via sed, so this
# test exercises the ACTUAL shipped function, not a hand-copied mirror that could drift from it.
#
# Run:  bash tests/test_restore_drill.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRILL="$ROOT/scripts/restore_drill.sh"

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

# Extract resolve_backup_date() verbatim out of the live script and load it into THIS shell -- proves
# the test runs against what actually ships, not a copy that could go stale the way the bug's own
# 2026-08-08 predecessor comment already warns about elsewhere in that file.
func_src="$(sed -n '/^resolve_backup_date() {/,/^}/p' "$DRILL")"
if [ -z "$func_src" ]; then
  echo "FAIL: could not extract resolve_backup_date() out of $DRILL -- has its shape changed?"
  exit 1
fi
eval "$func_src"

# Stub `gcloud storage ls <bucket>/events/<table>/` per fixture table, driven entirely by an env var
# naming the scenario so no real gcloud/network call is ever made. Mirrors tests/test_bq_csv.sh's `bq`
# PATH-shim pattern for the same reason (a real CLI stub is more honest than reimplementing the parsing
# `sed` line a second time in the test).
SCRATCH="$(mktemp -d)"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT
mkdir -p "$SCRATCH/bin"

# ---- Scenario 1: the exact bug shape -- a table that sorts alphabetically FIRST has only a STALE
#      partition, a middle table has NO partitions at all (a brand-new table, or a one-off gap -- the
#      2026-08-08 fix's own original case, which must still be tolerated), and the alphabetically LAST
#      table has the true freshest partition. The old "stop at the first hit" loop would return
#      2026-08-20 (aaa_stale's own newest); the fix must return 2026-08-30 (the true global max).
cat > "$SCRATCH/bin/gcloud" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
# args: storage ls <bucket>/events/<table>/
path="${3:-}"
case "$path" in
  */events/aaa_stale/)  printf 'gs://x/events/aaa_stale/dt=2026-08-18/f.parquet\ngs://x/events/aaa_stale/dt=2026-08-20/f.parquet\n' ;;
  */events/mmm_empty/)  : ;;  # no output at all -- a table with zero snapshots yet
  */events/zzz_fresh/)  printf 'gs://x/events/zzz_fresh/dt=2026-08-29/f.parquet\ngs://x/events/zzz_fresh/dt=2026-08-30/f.parquet\n' ;;
  *) echo "unexpected gcloud storage ls path: $path" >&2; exit 1 ;;
esac
STUB
chmod +x "$SCRATCH/bin/gcloud"

out="$(PATH="$SCRATCH/bin:$PATH" resolve_backup_date "gs://x" aaa_stale mmm_empty zzz_fresh)"
assert_eq "resolve_backup_date: true global max (2026-08-30), NOT the alphabetically-first table's stale date (2026-08-20)" \
  "$out" "2026-08-30"

# ---- Scenario 2 (regression guard against re-breaking the ORIGINAL, pre-2026-08-08 bug): TABLES[0]
#      alone having zero snapshots must not make the whole thing resolve empty when a later table has a
#      perfectly good one.
cat > "$SCRATCH/bin/gcloud" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
path="${3:-}"
case "$path" in
  */events/aaa_empty/) : ;;
  */events/bbb_ok/)     printf 'gs://x/events/bbb_ok/dt=2026-07-01/f.parquet\n' ;;
  *) echo "unexpected gcloud storage ls path: $path" >&2; exit 1 ;;
esac
STUB
out="$(PATH="$SCRATCH/bin:$PATH" resolve_backup_date "gs://x" aaa_empty bbb_ok)"
assert_eq "resolve_backup_date: a table with zero snapshots is skipped, not fatal (2026-08-08 fix's own intent, preserved)" \
  "$out" "2026-07-01"

# ---- Scenario 3: every table empty -> resolves to the empty string (caller's existing
#      `[ -n "${DATE:-}" ] || { ... exit 1; }` guard is what turns this into a hard failure, unchanged
#      by this fix; resolve_backup_date itself just reports "found nothing").
cat > "$SCRATCH/bin/gcloud" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
out="$(PATH="$SCRATCH/bin:$PATH" resolve_backup_date "gs://x" only_empty)"
assert_eq "resolve_backup_date: no table has any snapshot -> empty string, not a false date" "$out" ""

# ---- Discrimination check: literally run the OLD (pre-fix) "stop at the first hit" loop shape against
#      Scenario 1's fixture and confirm it DOES return the wrong (stale) date -- proving this fixture
#      actually distinguishes old buggy behavior from the fix, not just asserting the new answer in a
#      vacuum. This is the exact loop body restore_drill.sh carried before this finding's fix, kept here
#      ONLY as a frozen reference for this one assertion (never as a "helper" anything else calls).
old_buggy_resolve() {
  local bucket="$1"; shift
  local date=""
  for t in "$@"; do
    date="$(gcloud storage ls "$bucket/events/$t/" 2>/dev/null \
              | sed -n 's#.*/dt=\([0-9-]\{10\}\)/.*#\1#p' | sort -u | tail -1 || true)"
    [ -n "$date" ] && break
  done
  printf '%s' "$date"
}
cat > "$SCRATCH/bin/gcloud" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
path="${3:-}"
case "$path" in
  */events/aaa_stale/)  printf 'gs://x/events/aaa_stale/dt=2026-08-18/f.parquet\ngs://x/events/aaa_stale/dt=2026-08-20/f.parquet\n' ;;
  */events/mmm_empty/)  : ;;
  */events/zzz_fresh/)  printf 'gs://x/events/zzz_fresh/dt=2026-08-29/f.parquet\ngs://x/events/zzz_fresh/dt=2026-08-30/f.parquet\n' ;;
  *) echo "unexpected gcloud storage ls path: $path" >&2; exit 1 ;;
esac
STUB
old_out="$(PATH="$SCRATCH/bin:$PATH" old_buggy_resolve "gs://x" aaa_stale mmm_empty zzz_fresh)"
assert_eq "discrimination check: the OLD stop-at-first-hit loop DOES get this wrong (anchors on aaa_stale's 2026-08-20)" \
  "$old_out" "2026-08-20"

echo
# Banner names THIS file (2026-09-04 quality pass). It previously self-identified as
# "test_restore_drill_date_resolution", a filename that has never existed here -- ci.yml and
# auto-merge-claude.yml both invoke `bash tests/test_restore_drill.sh`, so the banner sent a reader
# chasing a non-existent file. Cosmetic only: both callers check the exit status, nothing greps this
# text (verified across .github/ and scripts/).
if [ "$fail" -ne 0 ]; then
  echo "test_restore_drill: FAILED"
  exit 1
fi
echo "test_restore_drill: all $pass_count assertions passed"

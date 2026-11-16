#!/usr/bin/env bash
# Functional tests for scripts/finding_issue.sh -- the shared "one open issue per finding" helper the
# scheduled guard workflows call (2026-11-16). `gh` is a PATH shim that records each invocation's argv
# (one line per call, args joined by '|') and plays back a canned issue list; no network is touched.
#
# Pins: comment vs edit vs create on `open`; comment-and-close on `close`; the title PREFIX is matched
# as data (a prefix containing quotes cannot break the filter); and -- the reason the helper exists --
# every gh failure is a ::warning:: with exit 0, so the ops.ci_findings write after it always runs.
#
# Run:  bash tests/test_finding_issue.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail=0
pass_count=0
check() {     # check <description> <actual> <expected-substring, or "" for exactly empty>
  local desc="$1" actual="$2" want="$3"
  if { [ -z "$want" ] && [ -z "$actual" ]; } || { [ -n "$want" ] && [[ "$actual" == *"$want"* ]]; }; then
    echo "PASS: $desc"; pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (wanted '$want' in '$actual')"; fail=1
  fi
}

mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'SHIM'
#!/usr/bin/env bash
( IFS='|'; echo "$*" ) >> "$GH_LOG"
if [ "$1 $2" = "issue list" ]; then
  [ "${GH_FAIL:-}" = "list" ] && exit 1
  cat "$GH_ISSUES"
  exit 0
fi
[ "${GH_FAIL:-}" = "write" ] && exit 1
exit 0
SHIM
chmod +x "$WORK/bin/gh"
export PATH="$WORK/bin:$PATH" GH_LOG="$WORK/gh.log" GH_ISSUES="$WORK/issues.json" GITHUB_REPOSITORY="o/r"
echo "body" > "$WORK/body.md"

run() { : > "$GH_LOG"; out="$("$ROOT/scripts/finding_issue.sh" "$@" 2>&1)"; rc=$?; calls="$(grep -v '^issue|list' "$GH_LOG" || true)"; }

echo '[{"number":7,"title":"⚠️ Sweep: needs attention"},{"number":9,"title":"other"}]' > "$GH_ISSUES"
run open "⚠️ Sweep:" "⚠️ Sweep: needs attention" "$WORK/body.md"
check "open comments on the existing issue" "$calls" "issue|comment|7|--repo|o/r|--body-file|$WORK/body.md"
run open "⚠️ Sweep:" "⚠️ Sweep: needs attention" "$WORK/body.md" edit
check "open (edit) replaces the existing issue's body" "$calls" "issue|edit|7|--repo|o/r|--body-file|$WORK/body.md"
run close "⚠️ Sweep:" "Resolved. Closing."
check "close comments and closes in one call" "$calls" "issue|close|7|--repo|o/r|--comment|Resolved. Closing."
check "list raises the default 30-issue limit" "$(cat "$GH_LOG")" "--limit|500"

run open "⚠️ Nope:" "⚠️ Nope: new" "$WORK/body.md"
check "open creates when no title matches the prefix" "$calls" "issue|create|--repo|o/r|--title|⚠️ Nope: new|--body-file|$WORK/body.md"
run close "⚠️ Nope:" "x"
check "close with nothing open makes no write call" "$calls" ""

echo '[{"number":3,"title":"say \"hi\" (now): x"}]' > "$GH_ISSUES"
run open 'say "hi" (now):' "t" "$WORK/body.md"
check "a prefix with quotes and parens is matched as data" "$calls" "issue|comment|3|"

GH_FAIL="list" run open "⚠️ Sweep:" "t" "$WORK/body.md"
check "a failed list exits 0" "$rc" "0"
check "a failed list warns" "$out" "::warning::finding_issue.sh: could not list open issues"
check "a failed list never creates a duplicate issue" "$calls" ""
echo '[]' > "$GH_ISSUES"
GH_FAIL="write" run open "⚠️ Sweep:" "t" "$WORK/body.md"
check "a failed create exits 0" "$rc" "0"
check "a failed create warns" "$out" "::warning::finding_issue.sh: could not create"
run open "⚠️ Sweep:" "t" "$WORK/missing.md"
check "a missing body file exits 0 with a warning" "$rc$out" "0::warning::finding_issue.sh open: missing title or body file"
GITHUB_REPOSITORY="" run open "p" "t" "$WORK/body.md"
check "an unset GITHUB_REPOSITORY exits 0 with a warning" "$rc$out" "0::warning::finding_issue.sh: usage"

echo
echo "$pass_count assertion(s) passed."
exit "$fail"

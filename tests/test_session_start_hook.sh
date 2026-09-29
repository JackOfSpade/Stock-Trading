#!/usr/bin/env bash
# Functional tests for .claude/session-start.sh — the SessionStart hook every remote
# routine session runs before its first tool call (registered in .claude/settings.json).
#
# WHY THIS FILE EXISTS (2026-09-08). The hook gained a best-effort `git fetch --unshallow`
# that closes the fleet-wide `shallow_clone_git_attribution` exposure SL2 raised that day:
# the routine container clones SHALLOW, and on a shallow clone `git log -S/-L`, `git blame`,
# `git log --since` and `git merge-base --is-ancestor` return confidently WRONG answers
# rather than errors. That deepen is the MECHANICAL half of the fix (the prose half is
# Claude_Task_Plan.md §Execution environment's HISTORY-DEPTH PRECHECK), and until now the
# hook had no test at all — it was only ever exercised by a live routine session, which is
# the one place a regression is both invisible and unfixable after the fact.
#
# Testing approach mirrors tests/test_auto_merge_logic.sh and tests/test_resolve_diff_base.sh:
# a scratch git repo with a real local `origin` remote (file:// so `--depth` actually
# truncates — the local-path transport hardlinks the whole object store and silently
# produces a COMPLETE clone, which would make the central assertion here vacuous).
#
# Run:  bash tests/test_session_start_hook.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.claude/session-start.sh"

[ -f "$HOOK" ] || { echo "FAIL: hook not found at $HOOK"; exit 1; }

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

assert_contains() {   # assert_contains <description> <haystack> <needle>
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (expected to find '$needle' in: $haystack)"
    fail=1
  fi
}

assert_not_contains() {   # assert_not_contains <description> <haystack> <needle>
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (did NOT expect '$needle' in: $haystack)"
    fail=1
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Run from the scratch dir, never from the checkout. Every git command below targets a fixture repo
# under $TMP, so none may depend on the checkout being a healthy repo -- and under the global
# `act push` pre-push hook it is not: the hook checks the pushed SHA out as a `git worktree`, whose
# `.git` is a pointer file to a host path the container cannot see, so ANY git call whose cwd is that
# checkout (even `git config --global`) dies `fatal: not a git repository: (null)` (exit 128). That
# failed this step under the hook while passing on GitHub's real clone (2026-09-29). $ROOT/$HOOK are
# already absolute, so nothing below needs the old cwd.
cd "$TMP"

# Keep the fixture repos out of the developer's own git identity/config.
export GIT_CONFIG_NOSYSTEM=1
export HOME="$TMP/home"
mkdir -p "$HOME"
git config --global user.email "test@example.com"
git config --global user.name "Session Start Test"
git config --global init.defaultBranch main
git config --global protocol.file.allow always

# ---------------------------------------------------------------------------
# Fixture: an "origin" with 12 commits on main, served over file:// so that
# --depth genuinely truncates.
# ---------------------------------------------------------------------------
ORIGIN="$TMP/origin"
mkdir -p "$ORIGIN"
(
  cd "$ORIGIN"
  git init -q
  for i in $(seq 1 12); do
    echo "line $i" >> history.txt
    git add history.txt
    git commit -q -m "commit $i"
  done
) >/dev/null
ORIGIN_URL="file://$ORIGIN"
TOTAL_COMMITS="$(cd "$ORIGIN" && git rev-list --count HEAD)"
assert_eq "fixture origin has 12 commits" "$TOTAL_COMMITS" "12"

# run_hook <repo dir> -> the hook's STDERR in HOOK_ERR, its exit code in HOOK_RC.
# Deliberately not a command substitution: that runs in a subshell, so HOOK_RC would
# never reach the caller (and under `set -u` it reads as an unbound variable instead
# of failing visibly — this test caught exactly that on its first run).
run_hook() {
  local dir="$1"
  local errfile="$TMP/hook-stderr.$$"
  set +e
  env CLAUDE_CODE_REMOTE=true CLAUDE_PROJECT_DIR="$dir" \
      bash "$HOOK" >/dev/null 2>"$errfile"
  HOOK_RC=$?
  set -e
  HOOK_ERR="$(cat "$errfile")"
  rm -f "$errfile"
}

# ---------------------------------------------------------------------------
# 1. THE CENTRAL CASE — a shallow clone is deepened to full history.
#    This is the routine container's actual state (measured 83 commits / boundary
#    e4e611c on 2026-09-08), and the whole point of the hook change.
# ---------------------------------------------------------------------------
SHALLOW="$TMP/shallow"
git clone -q --depth 1 --branch main "$ORIGIN_URL" "$SHALLOW"
assert_eq "fixture clone starts SHALLOW" \
  "$(cd "$SHALLOW" && git rev-parse --is-shallow-repository)" "true"
assert_eq "fixture clone starts truncated to 1 commit" \
  "$(cd "$SHALLOW" && git rev-list --count HEAD)" "1"

run_hook "$SHALLOW"; err="$HOOK_ERR"
assert_eq "hook exits 0 on the shallow-clone path" "$HOOK_RC" "0"
assert_eq "clone is no longer shallow after the hook" \
  "$(cd "$SHALLOW" && git rev-parse --is-shallow-repository)" "false"
assert_eq "full history is present after the hook" \
  "$(cd "$SHALLOW" && git rev-list --count HEAD)" "$TOTAL_COMMITS"
assert_contains "hook reports the deepen on stderr" "$err" "deepened shallow clone to full history"

# The deepen must not have broken what the hook already did: HEAD is reset to origin/main.
assert_eq "HEAD still equals origin/main after the hook" \
  "$(cd "$SHALLOW" && git rev-parse HEAD)" \
  "$(cd "$SHALLOW" && git rev-parse origin/main)"

# And the depth-sensitive command that motivated all of this now answers correctly:
# on the shallow clone `git log -S` could only ever have named the boundary commit.
assert_eq "git log -S resolves a pre-boundary change to its REAL commit, not the boundary" \
  "$(cd "$SHALLOW" && git log --format=%s -S 'line 3' -- history.txt)" "commit 3"

# ---------------------------------------------------------------------------
# 2. A COMPLETE clone must NOT be sent through --unshallow.
#    `git fetch --unshallow` on a complete repository is a hard error
#    (`fatal: --unshallow on a complete repository does not make sense`), so an
#    unguarded deepen would print a failure on every healthy session — and the
#    hook's own WARNING line would then be a lie about the history state.
# ---------------------------------------------------------------------------
FULL="$TMP/full"
git clone -q --branch main "$ORIGIN_URL" "$FULL"
assert_eq "fixture full clone is not shallow" \
  "$(cd "$FULL" && git rev-parse --is-shallow-repository)" "false"

run_hook "$FULL"; err="$HOOK_ERR"
assert_eq "hook exits 0 on the already-complete path" "$HOOK_RC" "0"
assert_not_contains "no deepen is attempted on a complete clone" "$err" "deepened shallow clone"
assert_not_contains "no --unshallow WARNING on a complete clone" "$err" "still SHALLOW"
assert_not_contains "no git 'fatal:' leaks from an unguarded --unshallow" "$err" "fatal:"
assert_eq "complete clone still has full history" \
  "$(cd "$FULL" && git rev-list --count HEAD)" "$TOTAL_COMMITS"

# ---------------------------------------------------------------------------
# 3. A FAILING deepen must warn loudly and still exit 0 — never block session start.
#    In practice this is a network blip or GitHub rate-limiting the deepen. The hazard
#    is that a failed deepen is SILENT — the clone stays truncated and every history
#    command keeps answering confidently and wrongly — which is what the WARNING line
#    exists to prevent, so it is worth a deterministic test.
#
#    Injected with a `git` shim earlier on PATH that fails ONLY `fetch --unshallow` and
#    delegates everything else to the real git. Deliberately not simulated by damaging
#    the fixture's object store: every way of doing that also breaks the plain
#    `git fetch origin main` above it, so the hook would exit at that earlier guard and
#    the branch under test would never run — a vacuous pass. (The first cut of this test
#    did exactly that and reported the deepen SUCCEEDING.)
# ---------------------------------------------------------------------------
BROKEN="$TMP/broken"
git clone -q --depth 1 --branch main "$ORIGIN_URL" "$BROKEN"
assert_eq "broken-deepen fixture starts SHALLOW" \
  "$(cd "$BROKEN" && git rev-parse --is-shallow-repository)" "true"

SHIMDIR="$TMP/shim"
mkdir -p "$SHIMDIR"
REAL_GIT="$(command -v git)"
cat > "$SHIMDIR/git" <<SHIM
#!/usr/bin/env bash
# Fails only \`git fetch --unshallow ...\`; everything else is the real git.
if [ "\${1:-}" = "fetch" ] && [ "\${2:-}" = "--unshallow" ]; then
  echo "fatal: simulated deepen failure (test shim)" >&2
  exit 128
fi
exec "$REAL_GIT" "\$@"
SHIM
chmod +x "$SHIMDIR/git"

set +e
env CLAUDE_CODE_REMOTE=true CLAUDE_PROJECT_DIR="$BROKEN" PATH="$SHIMDIR:$PATH" \
    bash "$HOOK" >/dev/null 2>"$TMP/broken-stderr"
rc=$?
set -e
err="$(cat "$TMP/broken-stderr")"
assert_eq "hook still exits 0 when the deepen fails" "$rc" "0"
assert_contains "a failed deepen is reported, not swallowed" "$err" "still SHALLOW"
assert_contains "the failure names the commands that are now untrustworthy" "$err" "git blame"
assert_not_contains "a failed deepen never claims success" "$err" "deepened shallow clone"
assert_eq "history stays shallow when the deepen fails" \
  "$(cd "$BROKEN" && git rev-parse --is-shallow-repository)" "true"
assert_eq "the rest of the hook still ran: HEAD reset to origin/main" \
  "$(cd "$BROKEN" && git rev-parse HEAD)" "$(cd "$BROKEN" && git rev-parse origin/main)"

# ---------------------------------------------------------------------------
# 4. LOCAL (non-remote) sessions are untouched. The hook is scoped to
#    CLAUDE_CODE_REMOTE=true; a developer's local CLI checkout must not be
#    hard-reset or re-fetched by it.
# ---------------------------------------------------------------------------
LOCAL="$TMP/local"
git clone -q --depth 1 --branch main "$ORIGIN_URL" "$LOCAL"
before="$(cd "$LOCAL" && git rev-list --count HEAD)"
set +e
env -u CLAUDE_CODE_REMOTE CLAUDE_PROJECT_DIR="$LOCAL" bash "$HOOK" >/dev/null 2>&1
rc=$?
set -e
assert_eq "hook exits 0 when CLAUDE_CODE_REMOTE is unset" "$rc" "0"
assert_eq "a local checkout is left exactly as found" \
  "$(cd "$LOCAL" && git rev-list --count HEAD)" "$before"
assert_eq "a local checkout is still shallow (hook did not deepen it)" \
  "$(cd "$LOCAL" && git rev-parse --is-shallow-repository)" "true"

# ---------------------------------------------------------------------------
# 5. A repo with no remote at all must exit 0 before touching anything.
# ---------------------------------------------------------------------------
NOREMOTE="$TMP/noremote"
mkdir -p "$NOREMOTE"
(
  cd "$NOREMOTE"
  git init -q
  echo x > f.txt
  git add f.txt
  git commit -q -m "only commit"
) >/dev/null
run_hook "$NOREMOTE"; err="$HOOK_ERR"
assert_eq "hook exits 0 with no remote configured" "$HOOK_RC" "0"
assert_eq "no-remote repo is left alone" "$(cd "$NOREMOTE" && git rev-list --count HEAD)" "1"

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass_count session-start hook assertions passed."
else
  echo "session-start hook tests FAILED"
fi
exit "$fail"

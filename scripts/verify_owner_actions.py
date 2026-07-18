#!/usr/bin/env python3
"""Machine-verifiable OWNER_ACTIONS.md auto-closer (OAE-5, 2026-07-16 owner-selfservice audit).

WHY: OWNER_ACTIONS.md drifts stale in both directions — a completed item keeps reading as open
(nobody edits the file once they've done the console click), and a claim can go stale the other way
too. Nothing detected completion before this; every close was a manual owner/session edit.

WHAT THIS DOES: parses ```verify fenced blocks appended to OWNER_ACTIONS.md items (see the fence
format below), runs a small, hand-written, read-only PROBE per known `id` (the probe/done_when text
inside the fence is retained as the human-readable spec of what each probe checks — it documents
intent for a reader, but the ACTUAL check run is the corresponding Python function in the PROBES
registry below; the heterogeneous mix of bq-scalar / gh-json / env-bool / git-ancestor / composite
conditions in the spec is not a single executable mini-language, so each id gets its own small,
explicit, reviewable check function instead of a generic interpreter), and — for any id whose check
newly PASSES and whose heading is not already flipped — rewrites that item's heading/bullet in place
to `[DONE <UTC date> — auto-verified] <original text>` plus one inserted evidence line.

GUARDS (see fence block below + Claude_Task_Plan.md / OWNER_ACTIONS.md OAE-5 packet):
  * Fail-open, always: ANY probe error (missing `bq`/`gh` binary, timeout, non-zero exit, unexpected
    output shape, network error) is treated as "still open" — this script must NEVER raise, and a
    probe failure must never be mistaken for "owner action needed" vs. "verifier itself is broken";
    both print as OPEN with the error text as the reason.
  * Auto-close only, NEVER auto-reopen: once a heading contains "[DONE", this script does not touch
    it again (regression detection is the drift views' / guard-config-audit's job, not this file's).
  * Single-file commit surface: this script only ever rewrites OWNER_ACTIONS.md.
  * Always exits 0 — a probe outcome must never fail the CI run that calls this (see
    .github/workflows/owner-actions-verify.yml).

Env (all optional — used by the bq/gh probes when present; falls back to OPEN if a probe's
prerequisite env/binary is unavailable, per fail-open above):
  BQ_PROJECT (default stock-trading-498512), GH_TOKEN / GITHUB_TOKEN (gh CLI auth),
  GITHUB_REPOSITORY (owner/repo — used by the D probe; falls back to `gh repo view`),
  HAS_ALERT_WEBHOOK_URL / HAS_OFFSITE_BACKUP_GCS / HAS_ANTHROPIC_API_KEY / HAS_GEMINI_API_KEY ('true'/'false' — the
  workflow exports these from `secrets.X != ''` since a workflow token cannot `gh secret list`).

Stdlib only.
"""
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from lib.bq_json import parse_bq_json_stdout

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OWNER_ACTIONS_PATH = os.path.join(ROOT, "OWNER_ACTIONS.md")
PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
TIMEOUT = 120

FENCE_RE = re.compile(
    r"```verify\n"
    r"id:\s*(?P<id>\S+)\s*\n"
    r"type:\s*(?P<type>\S+)\s*\n"
    r"probe:\s*(?P<probe>.*?)\s*\n"
    r"done_when:\s*(?P<done_when>.*?)\s*\n"
    r"```",
    re.DOTALL,
)


# ---------------------------------------------------------------------------
# Low-level runners — every subprocess call goes through these two, both of
# which convert ANY failure mode into a (False, reason) pair, never a raise.
# ---------------------------------------------------------------------------

def _run(cmd):
    """Run cmd with a bounded timeout. Returns (ok, stdout, reason). Never raises."""
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT)
    except FileNotFoundError as e:
        return False, "", f"binary not found: {e}"
    except subprocess.TimeoutExpired:
        return False, "", f"timed out after {TIMEOUT}s: {' '.join(cmd)[:120]}"
    except Exception as e:  # pragma: no cover — defensive, fail-open catch-all
        return False, "", f"unexpected error running {' '.join(cmd)[:80]}: {e}"
    if out.returncode != 0:
        return False, out.stdout, (out.stderr.strip() or out.stdout.strip() or f"exit {out.returncode}")
    return True, out.stdout, ""


def _bq_scalar(sql, key="n"):
    """Run a bq query expected to return exactly one row with column `key`. Returns (ok, value, reason)."""
    ok, stdout, reason = _run([
        "bq", "--project_id=" + PROJECT, "--quiet", "--headless", "--format=json",
        "query", "--use_legacy_sql=false", "--max_rows=10", sql,
    ])
    if not ok:
        return False, None, reason
    try:
        rows = parse_bq_json_stdout(stdout)
        return True, rows[0][key], ""
    except Exception as e:
        return False, None, f"could not parse bq result: {e}"


def _bq_count(sql, key="n"):
    """Run a COUNT-style bq scalar and normalize BigQuery JSON's stringified INT64 values."""
    ok, value, reason = _bq_scalar(sql, key)
    if not ok:
        return False, None, reason
    try:
        return True, int(value), ""
    except (TypeError, ValueError):
        return False, None, f"expected integer column {key}, got {value!r}"


# ---------------------------------------------------------------------------
# Per-id probes. Each returns (passed: bool, evidence: str) and never raises.
# ---------------------------------------------------------------------------

def check_A():
    ok, n, reason = _bq_count(
        "SELECT COUNT(*) n FROM `%s.ops.run_log` "
        "WHERE routine='OPS0' AND status='completed'" % PROJECT
    )
    if not ok:
        return False, f"bq probe error: {reason}"
    trigger_ids_path = os.path.join(ROOT, "ops", "trigger_ids.json")
    try:
        with open(trigger_ids_path, encoding="utf-8") as f:
            has_ops0 = '"OPS0"' in f.read()
    except (OSError, ValueError) as e:
        # ValueError catches UnicodeDecodeError (a non-UTF-8 file) — NOT an OSError subclass — so a
        # corrupt trigger_ids.json reads as OPEN rather than crashing this fail-open probe (2026-07-17).
        return False, f"could not read ops/trigger_ids.json: {e}"
    if n and n > 0 and has_ops0:
        return True, f"ops.run_log has {n} completed OPS0 run(s); ops/trigger_ids.json has an OPS0 entry"
    return False, f"ops.run_log completed-OPS0 count={n}, trigger_ids.json has OPS0 entry={has_ops0}"


def check_B():
    ok, n, reason = _bq_count(
        "SELECT COUNTIF(monitored AND NOT drift) n FROM `%s.state.scheduled_query_version_drift`" % PROJECT
    )
    if not ok:
        return False, f"bq probe error: {reason}"
    if n == 12:
        return True, f"state.scheduled_query_version_drift: {n}/12 monitored+non-drifted wrappers"
    return False, f"state.scheduled_query_version_drift: monitored+non-drifted count={n} (want 12)"


def check_C():
    ok, n, reason = _bq_count(
        "SELECT COUNT(*) n FROM `%s.ops.heartbeat` "
        "WHERE source='dashboard' AND note LIKE '%% (ci)%%' "
        "AND beat_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)" % PROJECT
    )
    if not ok:
        return False, f"bq probe error: {reason}"
    if n and n > 0:
        return True, f"ops.heartbeat has {n} dashboard '(ci)' beat(s) in the last 7 days"
    return False, f"ops.heartbeat dashboard '(ci)' beat count (7d)={n}"


def check_D():
    repo = os.environ.get("GITHUB_REPOSITORY", "").strip()
    if not repo:
        ok, stdout, reason = _run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
        if not ok:
            return False, f"could not determine GITHUB_REPOSITORY: {reason}"
        repo = stdout.strip()
    ok, stdout, reason = _run([
        "gh", "api", f"repos/{repo}/actions/workflows",
        "--jq", '.workflows[] | select(.path==".github/workflows/alert-relay.yml") | .state',
    ])
    if not ok:
        return False, f"gh probe error: {reason}"
    state = stdout.strip()
    if state == "active":
        return True, "alert-relay.yml workflow state=active"
    return False, f"alert-relay.yml workflow state={state or '(not found)'}"


def _check_env_true(var_name, human):
    val = os.environ.get(var_name, "").strip().lower()
    if val == "true":
        return True, f"{var_name}=true ({human} secret is set)"
    return False, f"{var_name}={val or '(unset)'}"


def check_E_webhook():
    return _check_env_true("HAS_ALERT_WEBHOOK_URL", "ALERT_WEBHOOK_URL")


def check_E_offsite():
    return _check_env_true("HAS_OFFSITE_BACKUP_GCS", "OFFSITE_BACKUP_GCS")


def check_E_anthropic():
    # 2026-07-17: golden-scenarios' live eval was swapped to Gemini's FREE tier as the SOLE provider
    # (no Anthropic fallback), so this item is satisfied by GEMINI_API_KEY. (The id keeps its historical
    # 'E-anthropic' name for traceability against the original owner-actions list.)
    return _check_env_true("HAS_GEMINI_API_KEY", "GEMINI_API_KEY")


def check_sq_dml_watch():
    ok, n, reason = _bq_count(
        "SELECT COUNTIF(monitored) n FROM `%s.state.scheduled_query_version_drift` "
        "WHERE sq_name='safety_critical_dml_watch'" % PROJECT
    )
    if not ok:
        return False, f"bq probe error: {reason}"
    if n == 1:
        return True, "safety_critical_dml_watch is registered and monitored=TRUE"
    return False, f"safety_critical_dml_watch monitored count={n} (want 1)"


def check_F_quota():
    ok, _, reason = _run(["git", "-C", ROOT, "fetch", "origin", "main", "--quiet"])
    if not ok:
        return False, f"git fetch failed: {reason}"
    ok, _, reason = _run(["git", "-C", ROOT, "merge-base", "--is-ancestor", "85c18c1", "origin/main"])
    if ok:
        return True, "commit 85c18c1 is an ancestor of origin/main (backlog merged)"
    return False, f"85c18c1 not yet an ancestor of origin/main ({reason or 'exit 1'})"


PROBES = {
    "A": check_A,
    "B": check_B,
    "C": check_C,
    "D": check_D,
    "E-webhook": check_E_webhook,
    "E-offsite": check_E_offsite,
    "E-anthropic": check_E_anthropic,
    "sq-dml-watch": check_sq_dml_watch,
    "F-quota": check_F_quota,
}


# ---------------------------------------------------------------------------
# OWNER_ACTIONS.md parsing + in-place rewrite
# ---------------------------------------------------------------------------

def find_anchor_line_index(lines, fence_start_idx):
    """Nearest preceding non-blank line that starts a heading (`## `) or a bullet (`- `) — the
    generic anchor rule this file's fences rely on (see OWNER_ACTIONS.md's OAE-5 packet)."""
    i = fence_start_idx - 1
    while i >= 0:
        stripped = lines[i].strip()
        if stripped == "":
            i -= 1
            continue
        if lines[i].lstrip().startswith("## ") or lines[i].lstrip().startswith("- "):
            return i
        i -= 1
    return None


def already_done(line):
    return "[DONE" in line


def flip_heading(line, today):
    indent = line[: len(line) - len(line.lstrip())]
    rest = line.lstrip()
    if rest.startswith("## "):
        title = rest[len("## "):].rstrip("\n")
        return f"{indent}## [DONE {today} — auto-verified] {title}\n"
    if rest.startswith("- "):
        body = rest[len("- "):].rstrip("\n")
        return f"{indent}- **[DONE {today} — auto-verified]** {body}\n"
    return line  # pragma: no cover — anchor rule guarantees one of the above


def main():
    try:
        with open(OWNER_ACTIONS_PATH, encoding="utf-8") as f:
            text = f.read()
    except (OSError, ValueError) as e:
        # ValueError catches a non-UTF-8 OWNER_ACTIONS.md (UnicodeDecodeError isn't an OSError) — the
        # script's contract is to ALWAYS exit 0, never raise (2026-07-17 audit).
        print(f"verify_owner_actions: could not read {OWNER_ACTIONS_PATH}: {e}")
        return 0

    lines = text.splitlines(keepends=True)
    # Map each fence to the (start, end) line-index span and its parsed fields, plus its anchor.
    results = []
    changed = False
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # Work from the end of the file backwards so earlier edits don't shift indices for
    # not-yet-processed matches.
    matches = list(FENCE_RE.finditer(text))
    for m in reversed(matches):
        fence_id = m.group("id").strip()
        fence_start_char = m.start()
        # Convert char offset to line index.
        fence_start_line = text.count("\n", 0, fence_start_char)

        probe_fn = PROBES.get(fence_id)
        if probe_fn is None:
            results.append((fence_id, "OPEN", "no probe implementation for this id"))
            continue

        anchor_idx = find_anchor_line_index(lines, fence_start_line)
        if anchor_idx is None:
            results.append((fence_id, "OPEN", "could not locate an anchor heading/bullet"))
            continue

        if already_done(lines[anchor_idx]):
            results.append((fence_id, "DONE", "already flipped — not re-checked (no auto-reopen)"))
            continue

        # Guard the probe so a single raising probe can never abort the whole pass (leaving other
        # fences unevaluated and the process exiting non-zero with a traceback) — the module's
        # documented contract is fail-open / always-exit-0 (2026-07-17 audit).
        try:
            passed, evidence = probe_fn()
        except Exception as e:
            results.append((fence_id, "OPEN", f"probe raised (fail-open): {e}"))
            continue
        if not passed:
            results.append((fence_id, "OPEN", evidence))
            continue

        # Newly passing: flip the heading/bullet and insert one evidence line after it.
        lines[anchor_idx] = flip_heading(lines[anchor_idx], today)
        evidence_line = f"  *(auto-verified {today}: {evidence})*\n"
        lines.insert(anchor_idx + 1, evidence_line)
        changed = True
        results.append((fence_id, "PASS (closed just now)", evidence))

    if changed:
        try:
            with open(OWNER_ACTIONS_PATH, "w", encoding="utf-8") as f:
                f.writelines(lines)
        except (OSError, ValueError) as e:
            # Fail-open, mirroring the read path (269-276) and the module's "never raise / always
            # exit 0" contract: a write failure (read-only FS / disk full) must not crash this
            # always-green CI verifier. The auto-close is idempotent — the next run recomputes the
            # same flip and re-attempts the write — so a transient failure is retried, not lost.
            # Print a clear notice so the un-persisted flip is visible, never silently assumed written.
            print(f"verify_owner_actions: could not write {OWNER_ACTIONS_PATH}: {e} "
                  f"(flip NOT persisted; will retry next run)")

    print("verify_owner_actions summary:")
    for fence_id, status, evidence in sorted(results, key=lambda r: r[0]):
        print(f"  [{status}] {fence_id}: {evidence}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

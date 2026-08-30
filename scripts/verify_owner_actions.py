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
  * Malformed fences are LOUD, not silent (codebase audit 2026-07-26): FENCE_RE requires an exact
    4-line id/type/probe/done_when shape right after ```verify, so any deviation (a case-typo'd
    field name, trailing text on the id line, an extra field inserted between fields, or — before
    the \r? tolerance added here — CRLF line endings) used to make the whole fence match NOTHING,
    silently dropping the item from the run with no OPEN, no diagnostic, and a normal-looking exit-0
    summary. main() now also scans for every bare ```verify opening line and prints a WARNING naming
    the line number for any not covered by a successful FENCE_RE match — still exit 0, still no
    change to flip/anchor behavior, purely an added diagnostic.
  * Duplicate ids are also LOUD (bug found 2026-08-08): PROBES is keyed by id only, so two
    well-formed fences sharing one `id` (a copy-pasted fence whose `id:` line didn't get updated)
    silently share ONE probe between two unrelated items — each fence still resolves its OWN nearby
    anchor via find_anchor_line_index, but both get evaluated against a probe written for only one
    of them, so the copy-pasted item can auto-close on a completion condition that has nothing to do
    with what it actually requires, with no OPEN, no diagnostic. main() now prints a WARNING naming
    every line number a duplicated id appears at — still exit 0, still no change to which fence(s)
    get evaluated or how they're anchored, purely an added diagnostic.

Env (all optional — used by the bq/gh probes when present; falls back to OPEN if a probe's
prerequisite env/binary is unavailable, per fail-open above):
  BQ_PROJECT (default stock-trading-498512), GH_TOKEN / GITHUB_TOKEN (gh CLI auth),
  GITHUB_REPOSITORY (owner/repo — used by the D probe; falls back to `gh repo view`),
  HAS_ALERT_WEBHOOK_URL / HAS_OFFSITE_BACKUP_GCS / HAS_ANTHROPIC_API_KEY ('true'/'false' — the
  workflow exports these from `secrets.X != ''` since a workflow token cannot `gh secret list`).

Stdlib only.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from lib.bq_json import run_bq_query

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OWNER_ACTIONS_PATH = os.path.join(ROOT, "OWNER_ACTIONS.md")
PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
TIMEOUT = 120

# probe/done_when are confined to `[^\r\n]*` per line (NOT `.` under DOTALL) so a fence body can never
# cross a fence boundary (bug found + fixed 2026-07-29, reproduced live): with `.*?` + re.DOTALL, `.`
# matches newlines, so a malformed fence missing its literal `done_when:` line (e.g. a `donewhen:`
# typo) let the lazy probe/done_when groups keep expanding PAST the fence's own closing ``` — through
# any prose — into the NEXT well-formed ```verify block, taking ITS id/type/probe lines as part of
# THIS fence's corrupted, now-multi-line probe and its done_when from the wrong item. Two harms: the
# second item silently vanished from the run (no OPEN, no diagnostic — FENCE_RE simply never matched
# it), and the first item's "probe" became a corrupted multi-line string that got executed as SQL. See
# test_fence_re_malformed_donewhen_typo_does_not_leak_into_next_fence in tests/test_verify_owner_actions.py.
#
# BUT a strictly single-line `[^\r\n]*?` (2026-07-29's first fix) went too far: two PRE-EXISTING,
# well-formed OWNER_ACTIONS.md fences (ids W, X) wrap a long `done_when` value onto a 2-space-indented
# continuation line — a normal hand-editing convention for a 120KB prose file — and a single-line
# field can't match that at all, so W/X's fences silently matched NOTHING (same silent-drop failure
# mode the fence-crossing fix was trying to eliminate, just via a different trigger). The fix below:
# probe/done_when may each be followed by zero or more CONTINUATION lines, but every continuation line
# — like every field line (`id:`/`type:`/`probe:`/`done_when:`) and the closing ``` — MUST be
# re-anchored: `\r?\n[ \t]+[^\r\n]*` requires at least one leading space/tab before a continuation
# line's content. This is what keeps the fence-crossing fix intact: `id:`, `type:`, `probe:`,
# `done_when:` and ``` all sit at COLUMN 0 in this format (see OWNER_ACTIONS.md — every fence in the
# file), so `[ \t]+` structurally can never match the start of one of those lines, meaning the
# continuation repetition CANNOT absorb a sibling field, a closing ``` fence, or the next ```verify
# block's opening line — it simply stops (0 more repetitions) the instant it meets an unindented line,
# regardless of greediness or backtracking. A malformed fence (missing/typo'd field) still therefore
# matches nothing at all, caught by the FENCE_OPEN_RE malformed-fence counter below, exactly as before
# — see test_fence_re_malformed_donewhen_typo_does_not_leak_into_next_fence AND its new companion
# test_fence_re_malformed_donewhen_typo_does_not_leak_into_wrapped_next_fence (a malformed fence
# immediately followed by a WRAPPED well-formed one — the new interaction this change introduces). A
# continuation line typo'd back to column 0 (no leading whitespace) is also proven NOT to be absorbed
# — see test_fence_re_unindented_continuation_is_not_absorbed.
#
# Normalization decision: the captured probe/done_when text keeps its embedded `\n` + indent verbatim
# (NOT collapsed to a single space). Checked first: neither group is actually read anywhere in main()
# today — only `m.group("id")` is (see main() below) — probe/done_when exist purely as the
# human-readable spec/description retained in the source for a reader (see module docstring), so there
# is no live consumer whose formatting needs deciding for. With no live consumer to argue for
# normalizing, behavior-preservation vs. the OLD (pre-2026-07-29) re.DOTALL parser is the tie-breaker,
# and the OLD parser's `.*?` captured the raw text INCLUDING the newline+indent for these same two
# fences. Verified byte-for-byte: replaying OLD FENCE_RE (git show c49da9a) against the real
# OWNER_ACTIONS.md and comparing every field of every one of the file's 17 fences against this new
# regex's captures shows zero differences, W/X included.
FENCE_RE = re.compile(
    r"```verify\r?\n"
    r"id:\s*(?P<id>\S+)\s*\r?\n"
    r"type:\s*(?P<type>\S+)\s*\r?\n"
    r"probe:\s*(?P<probe>[^\r\n]*(?:\r?\n[ \t]+[^\r\n]*)*)\r?\n"
    r"done_when:\s*(?P<done_when>[^\r\n]*(?:\r?\n[ \t]+[^\r\n]*)*)\r?\n"
    r"```"
)

# Any bare ```verify opening line, used only to detect a fence whose body does NOT match FENCE_RE
# above (codebase audit 2026-07-26). A malformed fence body — case-typo'd field name, trailing text
# on the id line, an extra field inserted between the four required ones, (pre-\r? fix) CRLF line
# endings, or a probe/done_when continuation line that lost its required leading indent — makes
# FENCE_RE match NOTHING for that block, and the item silently vanishes from the run: no OPEN line,
# no diagnostic, exit 0, a normal-looking summary. Every OTHER failure mode in this script
# (unregistered id, anchor-not-found, probe exception) prints a visible diagnostic; this was the one
# silent path, and OWNER_ACTIONS.md is a 120KB hand-maintained file people edit by hand, so a
# malformed fence is a realistic way for an item to drop out of tracking with nobody noticing.
FENCE_OPEN_RE = re.compile(r"^```verify\s*$", re.MULTILINE)


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
    except Exception as e:  # noqa: BLE001 - defensive fail-open catch-all (this helper never raises)  # pragma: no cover
        return False, "", f"unexpected error running {' '.join(cmd)[:80]}: {e}"
    if out.returncode != 0:
        return False, out.stdout, (out.stderr.strip() or out.stdout.strip() or f"exit {out.returncode}")
    return True, out.stdout, ""


def _bq_scalar(sql, key="n"):
    """Run a bq query expected to return exactly one row with column `key`. Returns (ok, value, reason).

    Delegates to lib/bq_json.py's run_bq_query, the shared invoke wrapper this module's own bq-CLI
    copy is consolidated into (2026-07-29 dedup — this file had already adopted parse_bq_json_stdout
    for the parse half but kept reimplementing the subprocess-invoke half that alert_relay.py /
    dbt_parity.py / check_live_roster_parity.py / generate_dashboard.py were all migrated onto).
    run_bq_query raises RuntimeError for a subprocess-level failure (nonzero exit, timeout) but a
    missing `bq` binary (FileNotFoundError) and malformed JSON output (ValueError/JSONDecodeError from
    parse_bq_json_stdout) are NOT wrapped — both propagate raw, so this module's fail-open contract
    (every probe error reads OPEN, never raises) requires catching all three explicitly here, not just
    RuntimeError (see generate_dashboard.py's q() docstring for the same exception-contract note).
    """
    try:
        rows = run_bq_query(sql, PROJECT, max_rows=10, timeout=TIMEOUT)
    except RuntimeError as e:
        return False, None, str(e)
    except FileNotFoundError as e:
        return False, None, f"binary not found: {e}"
    except Exception as e:  # noqa: BLE001 - covers ValueError/JSONDecodeError from parse_bq_json_stdout per this function's docstring
        return False, None, f"could not parse bq result: {e}"
    try:
        return True, rows[0][key], ""
    except (IndexError, KeyError) as e:
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


def check_S():
    # Item S (2026-07-18): the forgotten per-user 32 GiB/day query-usage override must be GONE.
    # Read-only Service Usage GET under the owner's gcloud credentials; classifier policy makes the
    # DELETE itself owner-only, but this verification read is fine from any session (RUNBOOK §2).
    ok, token, reason = _run(["gcloud", "auth", "print-access-token"])
    if not ok:
        return False, f"gcloud token unavailable: {reason}"
    ok, stdout, reason = _run([
        "curl", "-sf", "-H", "Authorization: Bearer " + token.strip(),
        "https://serviceusage.googleapis.com/v1beta1/projects/%s/services/"
        "bigquery.googleapis.com/consumerQuotaMetrics" % PROJECT,
    ])
    if not ok:
        return False, f"serviceusage GET failed: {reason}"
    try:
        overrides = [
            bucket["consumerOverride"]
            for metric in json.loads(stdout).get("metrics", [])
            if metric.get("metric") == "bigquery.googleapis.com/quota/query/usage"
            for limit in metric.get("consumerQuotaLimits", [])
            if limit.get("unit") == "1/d/{project}/{user}"
            for bucket in limit.get("quotaBuckets", [])
            if bucket.get("consumerOverride")
        ]
    except (ValueError, KeyError, TypeError) as e:
        return False, f"could not parse consumerQuotaMetrics response: {e}"
    if not overrides:
        return True, "per-user query/usage limit has no consumerOverride (default unlimited)"
    vals = ",".join(o.get("overrideValue", "?") for o in overrides)
    return False, f"per-user consumerOverride still present (MiB: {vals})"


PROBES = {
    "A": check_A,
    "B": check_B,
    "C": check_C,
    "D": check_D,
    "E-webhook": check_E_webhook,
    "E-offsite": check_E_offsite,
    "sq-dml-watch": check_sq_dml_watch,
    "F-quota": check_F_quota,
    "S": check_S,
}


# ---------------------------------------------------------------------------
# OWNER_ACTIONS.md parsing + in-place rewrite
# ---------------------------------------------------------------------------

def _heading_label(line):
    """Extract a `## ` heading's own leading item-label ('A', 'E-2', ...) from its `<LABEL>. ` prefix,
    first stripping any bracket auto-flip/decided marker this script (or an owner edit) may already
    have inserted right after `## ` — otherwise an already-flipped heading like
    `## [DONE 2026-07-18 — auto-verified] F. Resolved ...` would misparse `[DONE` as the label.
    Returns None for headings that don't follow the convention (e.g. this doc's numbered sub-items,
    `## 2. Register a new scheduled query ...`) — those skip the id/label cross-check below rather
    than being forced through a comparison that was never meaningful for them."""
    rest = line.lstrip()
    if not rest.startswith("## "):
        return None
    rest = rest[len("## "):]
    rest = re.sub(r"^\[[^\]]*\]\s*", "", rest)  # strip a leading "[DONE ...]"/"[DECIDED ...]" marker
    # The hyphen segment repeats (`*`, not `?`) — quality pass 2026-08-22. With `?` the label could
    # carry at most ONE hyphen, so a heading spelling out a multi-hyphen id in full parsed as None:
    # `## sq-dml-watch. ...` (a live registered id in this very file) returned None while
    # `## WR-2. ...` parsed fine. That silently DEFEATS the sibling mis-anchor guard rather than
    # tripping it, because find_anchor_line_index() treats a None label as "convention not followed,
    # skip the cross-check" — so a fence for `sq-dml-watch` sitting under a DIFFERENT, unrelated
    # spelled-out sibling heading resolved to that wrong heading instead of failing closed. That is
    # exactly the E-anthropic mis-anchor class the 2026-07-20 fix was built to close, just for ids
    # with two or more hyphens. Numbered sub-item headings (`## 2. Register ...`) still return None,
    # unchanged — they never start with a letter.
    m = re.match(r"([A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)*)\.", rest)
    return m.group(1).lower() if m else None


def _id_labels(fence_id):
    """The heading labels a fence id may legitimately live under, compared against a candidate
    heading's own label (see _heading_label) to catch a fence that resolves to a DIFFERENT, sibling
    item's heading rather than its own. Two forms are accepted because both conventions are in use:
    the id's leading segment, for a suffixed id filed under its parent's heading ('E-anthropic' ->
    '## E.', one heading owning a bullet per secret), and the FULL id, for one filed under a heading
    that spells it out ('WR-2' -> '## WR-2.'). Accepting only the leading segment would fail an id
    of the second shape closed against its OWN heading — safe, but a silent trap for whoever adds
    the next hyphenated item."""
    return {fence_id.split("-", 1)[0].lower(), fence_id.lower()}


def _skip_fenced_block_upward(lines, closing_idx):
    """`lines[closing_idx]` is a bare ``` ``` ``` closing delimiter found while scanning upward;
    locate its matching OPEN delimiter (the nearest ```-prefixed line further up — content lines
    inside a fence can never themselves start with ``` , or they'd close the block early, so this is
    unambiguous) and return `(opening_idx, tag)`, tag being the word right after the backticks
    ('verify', 'bash', ...). Returns `(None, None)` for an unterminated/malformed fence."""
    j = closing_idx - 1
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("```"):
            return j, s[3:].strip()
        j -= 1
    return None, None


def find_anchor_line_index(lines, fence_start_idx, fence_id):
    """Nearest preceding anchor for a fence — a heading (`## `) or bullet (`- `) — but FAILS CLOSED
    (returns None, the existing 'could not locate an anchor' / OPEN path) instead of trusting the
    nearest match whenever the walk is ambiguous. Three live/reachable OWNER_ACTIONS.md shapes make a
    naive nearest-match walk misattribute an item's status (2026-07-20 fix):
      * MORE THAN ONE bullet sits between the fence and its enclosing `## ` section heading — e.g.
        two unrelated action-list bullets inside the SAME item's own body (id V's live mis-anchor,
        which resolved to an unrelated '- Or let Monday's ...' bullet instead of V's own heading).
        A heading-boundary stop alone does not catch this: the walk hits a bullet before it ever
        reaches a heading, so there is no heading boundary in play at all.
      * ZERO bullets are found before the enclosing heading, but that heading's own label doesn't
        match the fence id's label — the fence physically sits after a DIFFERENT, sibling item's
        heading (id E-anthropic's mis-anchor AS OF THE 2026-07-20 FIX: its fence followed item E-2's
        heading instead of item E's own `ANTHROPIC_API_KEY` bullet, and E-2's heading already read
        '[DONE', permanently short-circuiting E-anthropic's probe. Retained as the worked example for
        this shape; note that E-anthropic's probe was REMOVED on 2026-08-30 when the Gemini key was
        retired, so that particular id no longer has a probe to short-circuit — the anchor-resolution
        rule below is unchanged and still applies to every other id).
      * EXACTLY ONE bullet is found before the walk stops at a heading boundary, and that heading's
        own label doesn't match the fence id's label either — a single stray bullet (e.g. a sibling
        item's own bullet) sitting between the fence and a DIFFERENT item's heading must not be
        trusted just because there's only one of it; the enclosing heading still has to check out.
    All three shapes now resolve to None rather than guessing. A single bullet enclosed by a heading
    that DOES match (or an unlabeled heading, e.g. this doc's numbered sub-items — see
    _heading_label) still resolves to the bullet, same as when the walk instead stops at a
    verify-block boundary (heading_idx never gets set at all) — neither of those is ambiguous.

    A fourth shape needs care but is NOT an anchor at all: an item's own prose can embed an unrelated
    sample code block (```bash, ```sql, ...) before its verify fence (id B's migration instructions),
    and a SIBLING item's bullet can each own its own already-closed ```verify block immediately above
    ours (item E's 3 secrets). Walking upward, both first appear as a bare ``` closing line, so we
    look up its matching open tag: a sibling's closed ```verify block is a real section boundary
    (stop, don't walk into ITS bullet/heading); a non-verify block (```bash, ...) is just inline
    prose for OUR OWN item and is skipped over whole, so the walk continues past it undisturbed.
    """
    bullets = []
    heading_idx = None
    i = fence_start_idx - 1
    while i >= 0:
        stripped = lines[i].strip()
        if stripped == "":
            i -= 1
            continue
        if stripped == "```":
            opening_idx, tag = _skip_fenced_block_upward(lines, i)
            if opening_idx is None or tag == "verify":
                break  # unterminated fence, or a sibling item's own verify block — section boundary
            i = opening_idx - 1  # a same-item inline sample (```bash, ```sql, ...) — skip over it
            continue
        if stripped.startswith("```"):
            break  # a stray fence-open reached before its own close — treat as a boundary too
        lstripped = lines[i].lstrip()
        if lstripped.startswith("## "):
            heading_idx = i
            break  # a heading always bounds the section — stop the walk here
        if lstripped.startswith("- "):
            bullets.append(i)
        i -= 1

    if len(bullets) > 1:
        return None  # ambiguous: more than one candidate bullet before the section boundary
    if heading_idx is not None:
        # The walk stopped at a heading boundary (whether or not a bullet was collected on the way)
        # — a label mismatch means this whole section, bullet included, belongs to a sibling item.
        heading_label = _heading_label(lines[heading_idx])
        if heading_label is not None and heading_label not in _id_labels(fence_id):
            return None  # this heading belongs to a different, sibling item — not our own anchor
    if bullets:
        return bullets[0]
    if heading_idx is None:
        return None  # nothing found at all
    return heading_idx


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

    # Loud diagnostic for two well-formed fences sharing the same id (bug found 2026-08-08): PROBES
    # is keyed by id only, so a copy-pasted fence whose `id:` line didn't get updated silently shares
    # ONE probe between two unrelated items — each fence still resolves its OWN nearby anchor below,
    # but both get evaluated against a probe written for only one of them, so the copy-pasted item
    # can auto-close on a completion condition that has nothing to do with what it actually requires,
    # with no OPEN, no diagnostic, and a normal-looking exit-0 summary. Purely additive: this only
    # ever prints a WARNING before the flip/anchor loop runs; it does not change which fence(s) get
    # evaluated or how they're anchored.
    ids_by_line = {}
    for m in matches:
        line_no = text.count("\n", 0, m.start()) + 1
        ids_by_line.setdefault(m.group("id").strip(), []).append(line_no)
    for fence_id, line_numbers in sorted(ids_by_line.items()):
        if len(line_numbers) > 1:
            print(
                f"verify_owner_actions: WARNING — duplicate id {fence_id!r} used by "
                f"{len(line_numbers)} well-formed ```verify fences, at lines "
                f"{', '.join(str(n) for n in line_numbers)}: they will ALL be evaluated against the "
                "SAME registered probe (PROBES is keyed by id only), so this can auto-close an item "
                "whose own actual requirement was never checked — check for a copy-pasted id."
            )

    # Loud diagnostic for a malformed fence (codebase audit 2026-07-26 — see FENCE_OPEN_RE above):
    # every bare ```verify opening line that FENCE_RE did NOT consume as part of a successful match
    # gets its own warning naming the line number, instead of silently vanishing from the run. This
    # runs before the fail-open/exit-0 contract is exercised below and never changes it — it only
    # ever adds a printed line; no flip/anchor behavior is touched.
    matched_open_offsets = {m.start() for m in matches}
    for open_m in FENCE_OPEN_RE.finditer(text):
        if open_m.start() not in matched_open_offsets:
            line_no = text.count("\n", 0, open_m.start()) + 1
            print(
                f"verify_owner_actions: WARNING — malformed ```verify fence at line {line_no}: "
                "did not match the expected id/type/probe/done_when shape (4 lines, in that order, "
                "no extra/renamed fields. If probe or done_when wraps onto another line, EVERY "
                "continuation line must start with at least one leading space or tab — a wrapped "
                "value left at column 0 will not be recognized as part of the field and breaks the "
                "fence) — this item will NOT be tracked or auto-closed."
            )

    for m in reversed(matches):
        fence_id = m.group("id").strip()
        fence_start_char = m.start()
        # Convert char offset to line index.
        fence_start_line = text.count("\n", 0, fence_start_char)

        anchor_idx = find_anchor_line_index(lines, fence_start_line, fence_id)
        if anchor_idx is None:
            results.append((fence_id, "OPEN", "could not locate an anchor heading/bullet"))
            continue

        if already_done(lines[anchor_idx]):
            results.append((fence_id, "DONE", "already flipped — not re-checked (no auto-reopen)"))
            continue

        # Anchor lookup + already_done() run before the probe-registration check (2026-07-18 fix):
        # an already-flipped item with no PROBES entry now reports DONE via already_done() above
        # instead of permanently misreporting OPEN "no probe implementation for this id".
        probe_fn = PROBES.get(fence_id)
        if probe_fn is None:
            results.append((fence_id, "OPEN", "no probe implementation for this id"))
            continue

        # Guard the probe so a single raising probe can never abort the whole pass (leaving other
        # fences unevaluated and the process exiting non-zero with a traceback) — the module's
        # documented contract is fail-open / always-exit-0 (2026-07-17 audit).
        try:
            passed, evidence = probe_fn()
        except Exception as e:  # noqa: BLE001 - a single raising probe must not abort the pass; module contract is fail-open
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

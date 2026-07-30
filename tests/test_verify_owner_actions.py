"""Guard scripts/verify_owner_actions.py's fence-parsing, anchor-rewrite, and fail-open contract
(OAE-5, 2026-07-16 owner-selfservice audit). Offline only — no `bq`/`gh` network calls; every probe
is monkeypatched or exercised via a faked subprocess.run so this suite never touches live infra.
"""
import subprocess
import types

from conftest import load_module_from_path

voa = load_module_from_path("verify_owner_actions", "scripts", "verify_owner_actions.py")


SAMPLE_DOC = """# Owner actions

## A. Register something (Gap 4)

Some prose about A.

```verify
id: A
type: bq
probe: SELECT 1
done_when: n>0
```

---

## B. Already done thing

Some prose about B, already handled.

```verify
id: B
type: bq
probe: SELECT 1
done_when: n=12
```
"""

SAMPLE_DOC_ALREADY_DONE = """# Owner actions

## [DONE 2026-07-10 — auto-verified] A. Register something (Gap 4)
  *(auto-verified 2026-07-10: evidence here)*

Some prose about A.

```verify
id: A
type: bq
probe: SELECT 1
done_when: n>0
```
"""

SAMPLE_DOC_BULLET = """# Owner actions

## E. Add 3 missing secrets

- `ALERT_WEBHOOK_URL` — some description.

```verify
id: E-webhook
type: env
probe: read HAS_ALERT_WEBHOOK_URL
done_when: == 'true'
```
"""

# Reproduces the live OWNER_ACTIONS.md shape behind id V's mis-anchor (2026-07-20 finding): the
# item's own heading is already DONE, but TWO unrelated action-list bullets sit between it and the
# item's own fence. A naive nearest-match walk hits the second bullet first and misreports it as the
# anchor; the fix must fail closed (None / OPEN) instead of trusting either bullet.
SAMPLE_DOC_INTERPOSED_BULLETS = """# Owner actions

## V. Some urgent item — `[DONE 2026-07-19 — owner done]`

**Action:** re-auth the thing. After that:
- Either ask an interactive session to run the recovery chain.
- Or let Monday's already-scheduled self-heal pick it up on its own.

```verify
id: V
type: ibkr
probe: some probe
done_when: some condition
```
"""

# Reproduces the live shape behind id E-anthropic's mis-anchor: the item's own fence physically sits
# AFTER a DIFFERENT, sibling item's `## ` heading (Y) rather than right after its own bullet (X's).
# Walking upward finds Y's heading first with zero intervening bullets, so a bare heading-boundary
# stop alone would credit Y's (already-DONE) heading to X's fence. The fix must fail closed instead.
SAMPLE_DOC_INTERPOSED_HEADING = """# Owner actions

## X. Add missing secrets

- `SOME_TOKEN` — X's own secret, described here.

## Y. An unrelated, later item — `[DONE 2026-07-10 — owner confirmed]`

Some unrelated prose about Y, nothing to do with X's secret.

```verify
id: X-token
type: env
probe: read HAS_SOME_TOKEN
done_when: == 'true'
```
"""

# A third mis-anchor shape: exactly ONE stray bullet (belonging to a DIFFERENT, sibling item, R)
# sits between the fence and the heading boundary the walk stops at. A single collected bullet must
# not be trusted just because there's only one of it — the enclosing heading's own label still has
# to match the fence id, and here it doesn't (R != Q).
SAMPLE_DOC_STRAY_BULLET_UNDER_SIBLING_HEADING = """# Owner actions

## R. Some other item

- A stray bullet belonging to R, not Q.

```verify
id: Q
type: bq
probe: SELECT 1
done_when: n>0
```
"""

# Reproduces id B's live shape: an item's OWN prose embeds an unrelated inline sample code block
# (```bash, not ```verify) before its own verify fence. This must NOT be mistaken for a sibling
# item's already-closed verify block — the walk should skip straight over it to the item's own
# heading, with no bullets in the way.
SAMPLE_DOC_EMBEDDED_CODE_SAMPLE = """# Owner actions

## B. Apply the migration

Run this:

```bash
echo hello
```

Then confirm.

```verify
id: B
type: bq
probe: SELECT 1
done_when: n>0
```
"""


def _fake_run_factory(returncode=0, stdout="", stderr=""):
    def run(cmd, capture_output=None, text=None, timeout=None):
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


# ---- _run() / _bq_scalar(): fail-open on every error mode ----------------------------------

def test_run_missing_binary_is_fail_open_not_raise(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise FileNotFoundError("no such file: bq")
    monkeypatch.setattr(voa.subprocess, "run", _boom)
    ok, out, reason = voa._run(["bq", "query", "SELECT 1"])
    assert ok is False
    assert "not found" in reason


def test_run_timeout_is_fail_open_not_raise(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(voa.subprocess, "run", _boom)
    ok, out, reason = voa._run(["bq", "query", "SELECT 1"])
    assert ok is False
    assert "timed out" in reason


def test_run_nonzero_exit_is_fail_open(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run", _fake_run_factory(1, "", "permission denied"))
    ok, out, reason = voa._run(["bq", "query", "SELECT 1"])
    assert ok is False
    assert "permission denied" in reason


def test_bq_scalar_parses_banner_prefixed_json(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run",
                        _fake_run_factory(0, 'Welcome to BigQuery!\n[{"n": 3}]'))
    ok, value, reason = voa._bq_scalar("SELECT COUNT(*) n FROM t")
    assert ok is True
    assert value == 3


def test_bq_scalar_empty_result_is_fail_open(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run", _fake_run_factory(0, "No rows.\n"))
    ok, value, reason = voa._bq_scalar("SELECT COUNT(*) n FROM t")
    assert ok is False


def test_bq_count_accepts_bigquery_stringified_int64(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run", _fake_run_factory(0, '[{"n": "12"}]'))
    ok, value, reason = voa._bq_count("SELECT COUNT(*) n FROM t")
    assert ok is True
    assert value == 12
    assert reason == ""


def test_bq_count_non_integer_is_fail_open(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run", _fake_run_factory(0, '[{"n": "not-a-count"}]'))
    ok, value, reason = voa._bq_count("SELECT COUNT(*) n FROM t")
    assert ok is False
    assert value is None
    assert "expected integer" in reason


# ---- per-id probes: each must be fail-open (never raise) on a probe error ------------------

def test_check_A_fails_open_when_bq_unavailable(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run",
                        lambda *a, **k: (_ for _ in ()).throw(FileNotFoundError("no bq")))
    passed, evidence = voa.check_A()
    assert passed is False
    assert "bq probe error" in evidence


def test_check_D_fails_open_when_gh_unavailable(monkeypatch):
    monkeypatch.delenv("GITHUB_REPOSITORY", raising=False)
    monkeypatch.setattr(voa.subprocess, "run",
                        lambda *a, **k: (_ for _ in ()).throw(FileNotFoundError("no gh")))
    passed, evidence = voa.check_D()
    assert passed is False


def test_check_E_webhook_true(monkeypatch):
    monkeypatch.setenv("HAS_ALERT_WEBHOOK_URL", "true")
    passed, evidence = voa.check_E_webhook()
    assert passed is True


def test_check_E_webhook_false_when_unset(monkeypatch):
    monkeypatch.delenv("HAS_ALERT_WEBHOOK_URL", raising=False)
    passed, evidence = voa.check_E_webhook()
    assert passed is False


def test_check_B_accepts_bq_count_string(monkeypatch):
    monkeypatch.setattr(voa, "_bq_scalar", lambda sql, key="n": (True, "12", ""))
    passed, evidence = voa.check_B()
    assert passed is True
    assert "12/12" in evidence


def test_check_C_accepts_positive_bq_count_string(monkeypatch):
    monkeypatch.setattr(voa, "_bq_scalar", lambda sql, key="n": (True, "1", ""))
    passed, evidence = voa.check_C()
    assert passed is True
    assert "1 dashboard" in evidence


def test_check_sq_dml_watch_accepts_bq_count_string(monkeypatch):
    monkeypatch.setattr(voa, "_bq_scalar", lambda sql, key="n": (True, "1", ""))
    passed, evidence = voa.check_sq_dml_watch()
    assert passed is True
    assert "monitored=TRUE" in evidence


def test_check_F_quota_fails_open_on_git_error(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run",
                        lambda *a, **k: (_ for _ in ()).throw(FileNotFoundError("no git")))
    passed, evidence = voa.check_F_quota()
    assert passed is False


# ---- anchor-finding + heading/bullet rewrite -----------------------------------------------

def test_find_anchor_prefers_heading(tmp_path):
    lines = ["## A. Title\n", "\n", "prose\n", "```verify\n", "id: A\n", "```\n"]
    idx = voa.find_anchor_line_index(lines, 3, "A")
    assert idx == 0


# ---- ambiguity fail-closed: the two live OWNER_ACTIONS.md mis-anchor shapes (2026-07-20 finding) ---

def test_find_anchor_none_when_two_unrelated_bullets_interpose(tmp_path):
    # id V's live shape: two unrelated action-list bullets sit between the fence and V's own
    # (already-DONE) heading. Must fail closed to None rather than trusting either bullet.
    lines = SAMPLE_DOC_INTERPOSED_BULLETS.splitlines(keepends=True)
    fence_start = next(i for i, ln in enumerate(lines) if ln.startswith("```verify"))
    idx = voa.find_anchor_line_index(lines, fence_start, "V")
    assert idx is None


def test_main_reports_open_not_done_for_interposed_bullets(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_INTERPOSED_BULLETS)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    before = doc.read_text()
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "OPEN] V: could not locate an anchor" in out
    # V's own heading already reads [DONE — must not be (mis)credited, and nothing gets rewritten.
    assert doc.read_text() == before


def test_find_anchor_none_when_fence_follows_a_sibling_heading(tmp_path):
    # id E-anthropic's live shape: the fence physically sits after a DIFFERENT, sibling item's own
    # heading (Y) instead of its own bullet (X's). Zero bullets intervene, so a bare heading-boundary
    # stop alone would credit Y's heading to X's fence; the label cross-check must fail closed instead.
    lines = SAMPLE_DOC_INTERPOSED_HEADING.splitlines(keepends=True)
    fence_start = next(i for i, ln in enumerate(lines) if ln.startswith("```verify"))
    idx = voa.find_anchor_line_index(lines, fence_start, "X-token")
    assert idx is None


def test_main_reports_open_not_done_for_interposed_heading(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_INTERPOSED_HEADING)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "X-token", lambda: (True, "HAS_SOME_TOKEN=true"))
    before = doc.read_text()
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "OPEN] X-token: could not locate an anchor" in out
    # Y's unrelated heading must never be flipped/credited on X's behalf, even though X's own probe
    # would otherwise pass right now — this is the "never let a probe auto-flip the wrong section"
    # guard the finding's ADJUST called for.
    assert doc.read_text() == before


def test_find_anchor_none_when_single_stray_bullet_under_sibling_heading(tmp_path):
    # id Q's fence sits under a DIFFERENT item's heading (R) with exactly one stray bullet (R's own)
    # intervening. A single bullet alone must not bypass the heading-label cross-check.
    lines = SAMPLE_DOC_STRAY_BULLET_UNDER_SIBLING_HEADING.splitlines(keepends=True)
    fence_start = next(i for i, ln in enumerate(lines) if ln.startswith("```verify"))
    idx = voa.find_anchor_line_index(lines, fence_start, "Q")
    assert idx is None


def test_find_anchor_accepts_a_heading_spelling_out_a_hyphenated_id(tmp_path):
    # Both id/heading conventions are in use: a suffixed id filed under its parent's heading
    # ('E-anthropic' under '## E.') and one filed under a heading that spells it out in full. The
    # label check must accept BOTH forms — matching only the leading segment would fail a
    # 'WR-2'-shaped id closed against its OWN heading (fail-safe, but a silent trap for the next
    # hyphenated item added to OWNER_ACTIONS.md).
    doc = (
        "## WR-2. Redeploy the weekly report\n"
        "\n"
        "Some prose about the redeploy.\n"
        "\n"
        "```verify id=WR-2\n"
        "probe\n"
        "```\n"
    )
    lines = doc.splitlines(keepends=True)
    fence_start = next(i for i, ln in enumerate(lines) if ln.startswith("```verify"))
    assert voa.find_anchor_line_index(lines, fence_start, "WR-2") == 0
    # A genuinely different sibling item's heading is still rejected, both segment and full form.
    assert voa.find_anchor_line_index(lines, fence_start, "WR-3") is None


def test_find_anchor_skips_embedded_non_verify_code_sample(tmp_path):
    # id B's live shape: an inline ```bash sample inside the item's OWN prose, before its own verify
    # fence. Must be skipped over (not mistaken for a sibling's closed ```verify block) so the walk
    # reaches B's own heading with zero (correctly) intervening bullets.
    lines = SAMPLE_DOC_EMBEDDED_CODE_SAMPLE.splitlines(keepends=True)
    fence_start = next(i for i, ln in enumerate(lines) if ln.startswith("```verify"))
    idx = voa.find_anchor_line_index(lines, fence_start, "B")
    assert lines[idx].strip() == "## B. Apply the migration"


def test_flip_heading_rewrites_heading_form():
    out = voa.flip_heading("## A. Register OPS0\n", "2026-07-20")
    assert out == "## [DONE 2026-07-20 — auto-verified] A. Register OPS0\n"


def test_flip_heading_rewrites_bullet_form():
    out = voa.flip_heading("- `ALERT_WEBHOOK_URL` — description.\n", "2026-07-20")
    assert out.startswith("- **[DONE 2026-07-20 — auto-verified]**")
    assert "`ALERT_WEBHOOK_URL`" in out


def test_already_done_detects_flipped_heading():
    assert voa.already_done("## [DONE 2026-07-10 — auto-verified] A. Foo\n") is True
    assert voa.already_done("## A. Foo\n") is False


# ---- main(): end-to-end against a fake OWNER_ACTIONS.md, no live infra --------------------

def test_main_closes_newly_passing_id_and_leaves_open_untouched(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "A", lambda: (True, "run_log has 1 completed row"))
    monkeypatch.setitem(voa.PROBES, "B", lambda: (False, "count=0 (want 12)"))

    rc = voa.main()
    assert rc == 0

    out = doc.read_text()
    assert "[DONE" in out and "A. Register something" in out
    assert "run_log has 1 completed row" in out
    # B stays untouched — still open.
    assert "## B. Already done thing\n" in out
    assert "[DONE" not in out.split("## B.")[1].split("```verify")[0]

    summary = capsys.readouterr().out
    assert "PASS (closed just now)] A:" in summary
    assert "OPEN] B:" in summary


def test_main_never_reopens_a_done_item(tmp_path, monkeypatch):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_ALREADY_DONE)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    # Even if the probe would now report False (regression), main() must not touch a DONE heading —
    # regression detection is out of scope for this file.
    monkeypatch.setitem(voa.PROBES, "A", lambda: (False, "regressed"))

    before = doc.read_text()
    rc = voa.main()
    assert rc == 0
    after = doc.read_text()
    assert before == after


def test_main_handles_bullet_anchor(tmp_path, monkeypatch):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_BULLET)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "E-webhook", lambda: (True, "HAS_ALERT_WEBHOOK_URL=true"))

    rc = voa.main()
    assert rc == 0
    out = doc.read_text()
    assert "[DONE" in out
    assert "`ALERT_WEBHOOK_URL`" in out


def test_main_unknown_id_reports_open_without_crashing(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text("""## Z. Unknown

```verify
id: Z-does-not-exist
type: bq
probe: SELECT 1
done_when: n>0
```
""")
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    rc = voa.main()
    assert rc == 0
    assert "no probe implementation" in capsys.readouterr().out


def test_main_reports_done_for_already_flipped_item_with_no_registered_probe(tmp_path, monkeypatch, capsys):
    # Anchor lookup + already_done() must run before the probe-registration check, so an
    # already-[DONE]-flipped item whose id has no PROBES entry reports DONE, not OPEN
    # "no probe implementation for this id" (2026-07-18 fix).
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text("""## [DONE 2026-07-16 — auto-verified] Z. Unknown but already done

```verify
id: Z-does-not-exist
type: bq
probe: SELECT 1
done_when: n>0
```
""")
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    before = doc.read_text()
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "no probe implementation" not in out
    assert "DONE" in out
    after = doc.read_text()
    assert before == after


def test_main_missing_file_exits_zero_not_raise(monkeypatch, capsys):
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", "/nonexistent/path/OWNER_ACTIONS.md")
    rc = voa.main()
    assert rc == 0
    assert "could not read" in capsys.readouterr().out


def test_main_non_utf8_owner_actions_exits_zero_not_raise(tmp_path, monkeypatch, capsys):
    # #9 (2026-07-17): a non-UTF-8 OWNER_ACTIONS.md raises UnicodeDecodeError (a ValueError, NOT an
    # OSError), which the old `except OSError` missed — crashing the always-exit-0 verifier. The
    # broadened handler now reads it as "could not read" and exits 0.
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_bytes(b"## A. x\n\n\xff\xfe not valid utf-8\n")
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    rc = voa.main()
    assert rc == 0
    assert "could not read" in capsys.readouterr().out


def test_main_raising_probe_is_fail_open_not_crash(tmp_path, monkeypatch, capsys):
    # #9 (2026-07-17): a probe that raises must be caught and reported OPEN, never abort the whole
    # pass with a traceback / non-zero exit (the module's fail-open / always-exit-0 contract).
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))

    def boom():
        raise RuntimeError("unexpected probe explosion")
    monkeypatch.setitem(voa.PROBES, "A", boom)
    monkeypatch.setitem(voa.PROBES, "B", lambda: (False, "count=0"))
    rc = voa.main()
    assert rc == 0
    assert "probe raised (fail-open)" in capsys.readouterr().out
    assert "[DONE" not in doc.read_text()   # nothing flipped; A raised, B open


# ==================================================================================================
# Coverage added by the parallel refactor (2026-07-17, Part B): probe SUCCESS paths and the
# trigger_ids.json read branch — previously only the fail-open/error arms were exercised. All
# offline: bq/gh are monkeypatched at _bq_count / _run / subprocess.run, never invoked for real.
# ==================================================================================================

# ---- check_A: the bq-count + ops/trigger_ids.json compound success path and its read fail-open ----
def test_check_A_success_when_run_logged_and_trigger_id_present(tmp_path, monkeypatch):
    (tmp_path / "ops").mkdir()
    (tmp_path / "ops" / "trigger_ids.json").write_text('{"OPS0": {"trigger_id": "t1"}}')
    monkeypatch.setattr(voa, "ROOT", str(tmp_path))
    monkeypatch.setattr(voa, "_bq_count", lambda sql, key="n": (True, 3, ""))
    passed, evidence = voa.check_A()
    assert passed is True
    assert "3 completed OPS0 run(s)" in evidence and "OPS0 entry" in evidence


def test_check_A_open_when_run_logged_but_no_trigger_entry(tmp_path, monkeypatch):
    (tmp_path / "ops").mkdir()
    (tmp_path / "ops" / "trigger_ids.json").write_text('{"D1": {"trigger_id": "t1"}}')  # no OPS0
    monkeypatch.setattr(voa, "ROOT", str(tmp_path))
    monkeypatch.setattr(voa, "_bq_count", lambda sql, key="n": (True, 5, ""))
    passed, evidence = voa.check_A()
    assert passed is False
    assert "entry=False" in evidence


def test_check_A_fail_open_when_trigger_ids_unreadable(tmp_path, monkeypatch):
    # bq succeeds, but ops/trigger_ids.json does not exist -> OSError -> read as OPEN, never raises.
    monkeypatch.setattr(voa, "ROOT", str(tmp_path))  # no ops/trigger_ids.json created
    monkeypatch.setattr(voa, "_bq_count", lambda sql, key="n": (True, 3, ""))
    passed, evidence = voa.check_A()
    assert passed is False
    assert "could not read ops/trigger_ids.json" in evidence


# ---- check_D: the active / inactive states and the gh-repo-view fallback (only the no-gh arm was hit) ----
def test_check_D_active_with_repo_from_env(monkeypatch):
    monkeypatch.setenv("GITHUB_REPOSITORY", "owner/repo")
    monkeypatch.setattr(voa, "_run", lambda cmd: (True, "active\n", ""))
    passed, evidence = voa.check_D()
    assert passed is True
    assert "state=active" in evidence


def test_check_D_inactive_state_reads_open(monkeypatch):
    monkeypatch.setenv("GITHUB_REPOSITORY", "owner/repo")
    monkeypatch.setattr(voa, "_run", lambda cmd: (True, "disabled_manually\n", ""))
    passed, evidence = voa.check_D()
    assert passed is False
    assert "disabled_manually" in evidence


def test_check_D_repo_view_fallback_when_env_unset(monkeypatch):
    monkeypatch.delenv("GITHUB_REPOSITORY", raising=False)
    calls = []

    def fake_run(cmd):
        calls.append(cmd)
        if "repo" in cmd and "view" in cmd:
            return True, "owner/repo\n", ""
        return True, "active\n", ""
    monkeypatch.setattr(voa, "_run", fake_run)
    passed, evidence = voa.check_D()
    assert passed is True
    assert len(calls) == 2  # gh repo view (fallback), then the workflows api call


# ---- _bq_scalar: a row present but missing the expected column (KeyError arm of the try/except) ----
def test_bq_scalar_row_missing_column_is_fail_open(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run", _fake_run_factory(0, '[{"other": 5}]'))
    ok, value, reason = voa._bq_scalar("SELECT COUNT(*) n FROM t")
    assert ok is False
    assert value is None
    assert "could not parse bq result" in reason


# ---- check_E_anthropic: satisfied by GEMINI_API_KEY (the 2026-07-17 free-tier swap) ----
def test_check_E_anthropic_true_via_gemini_key(monkeypatch):
    monkeypatch.setenv("HAS_GEMINI_API_KEY", "true")
    passed, evidence = voa.check_E_anthropic()
    assert passed is True
    assert "GEMINI_API_KEY" in evidence


def test_check_E_anthropic_false_when_unset(monkeypatch):
    monkeypatch.delenv("HAS_GEMINI_API_KEY", raising=False)
    passed, evidence = voa.check_E_anthropic()
    assert passed is False


# ---- write path: fail-open when persisting the flip fails (never raise / always exit 0) ----
# ---- malformed ```verify fences must be LOUD, not silent (codebase audit 2026-07-26) -------
#
# FENCE_RE requires an exact 4-line id/type/probe/done_when shape right after ```verify. Any
# deviation makes the whole fence match NOTHING, so before this fix the item would silently
# vanish from the run — no OPEN, no diagnostic, exit 0, a normal-looking summary. These four cases
# reproduce the four malformed shapes an auditor found live: a case-typo'd field name, trailing
# text on the id line, an extra field inserted between fields, and CRLF line endings (the last one
# is now tolerated by FENCE_RE itself via `\r?`, so it must NOT warn — see the CRLF case below).

SAMPLE_DOC_CASE_TYPO_FIELD = """## A. thing

```verify
id: A
type: bq
probe: SELECT 1
Done_when: n>0
```
"""

SAMPLE_DOC_TRAILING_TEXT_ON_ID = """## A. thing

```verify
id: A  (registered under Gap 4)
type: bq
probe: SELECT 1
done_when: n>0
```
"""

SAMPLE_DOC_EXTRA_FIELD = """## A. thing

```verify
id: A
type: bq
severity: high
probe: SELECT 1
done_when: n>0
```
"""

SAMPLE_DOC_CRLF = (
    "## A. thing\r\n"
    "\r\n"
    "```verify\r\n"
    "id: A\r\n"
    "type: bq\r\n"
    "probe: SELECT 1\r\n"
    "done_when: n>0\r\n"
    "```\r\n"
)


def test_fence_re_rejects_case_typo_field_name():
    assert list(voa.FENCE_RE.finditer(SAMPLE_DOC_CASE_TYPO_FIELD)) == []


def test_fence_re_rejects_trailing_text_on_id_line():
    assert list(voa.FENCE_RE.finditer(SAMPLE_DOC_TRAILING_TEXT_ON_ID)) == []


def test_fence_re_rejects_extra_inserted_field():
    assert list(voa.FENCE_RE.finditer(SAMPLE_DOC_EXTRA_FIELD)) == []


def test_fence_re_tolerates_crlf_line_endings():
    # \r? tolerance added 2026-07-26 — CRLF alone is not a shape violation, just a line-ending
    # difference, so it must still match (and therefore must NOT warn — see below).
    matches = list(voa.FENCE_RE.finditer(SAMPLE_DOC_CRLF))
    assert len(matches) == 1
    assert matches[0].group("id") == "A"


def test_main_warns_with_line_number_for_case_typo_field(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_CASE_TYPO_FIELD)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" in out
    assert "line 3" in out
    # No item was ever registered/tracked — the malformed fence produced no OPEN/DONE/PASS row.
    assert "id/type/probe/done_when" in out


def test_main_warns_with_line_number_for_trailing_text_on_id(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_TRAILING_TEXT_ON_ID)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" in out and "line 3" in out


def test_main_warns_with_line_number_for_extra_field(tmp_path, monkeypatch, capsys):
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_EXTRA_FIELD)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" in out and "line 3" in out


def test_main_does_not_warn_for_crlf_fence(tmp_path, monkeypatch, capsys):
    # CRLF is now tolerated by FENCE_RE, so it is a normal successfully-parsed fence — no warning,
    # and it participates in the ordinary OPEN/DONE/PASS flow like any other well-formed fence.
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_bytes(SAMPLE_DOC_CRLF.encode("utf-8"))
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "A", lambda: (False, "still open"))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" not in out
    assert "OPEN] A:" in out


def test_main_does_not_warn_for_a_well_formed_fence(tmp_path, monkeypatch, capsys):
    # Sanity check that the new scan doesn't false-positive-warn on every normal fence.
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "A", lambda: (False, "still open"))
    monkeypatch.setitem(voa.PROBES, "B", lambda: (False, "still open"))
    rc = voa.main()
    assert rc == 0
    assert "WARNING" not in capsys.readouterr().out


def test_main_warning_does_not_change_flip_behavior_of_other_items(tmp_path, monkeypatch, capsys):
    # A malformed fence for one item must not affect a well-formed sibling fence's normal
    # OPEN/DONE/PASS flip behavior elsewhere in the same document.
    # Well-formed fence FIRST, malformed one SECOND: FENCE_RE's non-greedy DOTALL probe/done_when
    # groups can otherwise "leak" past an unterminated malformed fence into a LATER well-formed
    # fence's own done_when line (a separate, pre-existing quirk of this regex, not something this
    # unit changes) — ordering avoids that so this test isolates the warning-vs-flip interaction.
    doc_text = SAMPLE_DOC_BULLET + "\n" + SAMPLE_DOC_CASE_TYPO_FIELD
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(doc_text)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "E-webhook", lambda: (True, "HAS_ALERT_WEBHOOK_URL=true"))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" in out
    assert "PASS (closed just now)] E-webhook:" in out
    assert "[DONE" in doc.read_text()


# ---- FIX 1 (2026-07-29, HIGH bug, reproduced live): a malformed fence's lazy DOTALL probe/done_when
# groups must never cross into the NEXT fence's own body -------------------------------------------
#
# Pre-fix, FENCE_RE used `.*?` under re.DOTALL for probe/done_when — `.` matches newlines, so a fence
# missing its literal `done_when:` line (here: `donewhen:`, a typo) let the lazy match keep expanding
# PAST its own closing ``` and through any prose until it found a LATER `done_when:` line — the next
# well-formed fence's own. That produced exactly one match: id=ITEM-A with a probe field corrupted
# into a multi-line string spanning ITEM-A's own line, the prose between the fences, and ITEM-B's
# id/type/probe lines, with done_when taken from ITEM-B. Two harms: ITEM-B silently vanished from the
# run (no OPEN, no diagnostic — FENCE_RE never matched it at all), and ITEM-A's "probe" became a
# corrupted multi-line string that would get executed as SQL by a `type: bq` probe. Confirmed this
# reproduces against the pre-fix pattern by constructing FENCE_RE with `.*?` probe/done_when groups
# and re.DOTALL (the exact prior definition) and re-running test_fence_re_malformed_donewhen_typo_
# does_not_leak_into_next_fence below against it: it fails, yielding exactly the corrupted single
# match this test now asserts does NOT happen.

SAMPLE_DOC_DONEWHEN_TYPO_CROSSES_FENCE_BOUNDARY = """```verify
id: ITEM-A
type: bq
probe: SELECT 1
donewhen: rows > 0
```

Some prose.

```verify
id: ITEM-B
type: sql
probe: SELECT 2
done_when: rows > 0
```
"""


def test_fence_re_malformed_donewhen_typo_does_not_leak_into_next_fence():
    matches = list(voa.FENCE_RE.finditer(SAMPLE_DOC_DONEWHEN_TYPO_CROSSES_FENCE_BOUNDARY))
    # ITEM-A's malformed fence matches NOTHING (caught by the FENCE_OPEN_RE malformed-fence counter,
    # not silently absorbed) — the only match is ITEM-B's own, untouched fence.
    assert len(matches) == 1
    assert matches[0].group("id") == "ITEM-B"
    assert matches[0].group("type") == "sql"
    assert matches[0].group("probe") == "SELECT 2"
    assert matches[0].group("done_when") == "rows > 0"


SAMPLE_DOC_DONEWHEN_TYPO_WITH_ANCHORS = """## ITEM-A. thing with a typo'd field

```verify
id: ITEM-A
type: bq
probe: SELECT 1
donewhen: rows > 0
```

Some prose between items.

## ITEM-B. a well-formed sibling

```verify
id: ITEM-B
type: sql
probe: SELECT 2
done_when: rows > 0
```
"""


def test_main_tracks_well_formed_sibling_despite_earlier_malformed_donewhen_typo(tmp_path, monkeypatch, capsys):
    # main()-level companion to the FENCE_RE test above: ITEM-A's malformed fence is reported as
    # malformed (not silently dropped), and ITEM-B is evaluated on its own probe/evidence — not
    # consumed by ITEM-A's would-be leak.
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC_DONEWHEN_TYPO_WITH_ANCHORS)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "ITEM-B", lambda: (False, "still open"))
    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "WARNING" in out
    assert "OPEN] ITEM-B: still open" in out


def test_main_write_failure_is_fail_open_not_crash(tmp_path, monkeypatch, capsys):
    # A passing probe makes changed=True; if persisting the flip fails (read-only FS / disk full),
    # main() must fail-open — print a clear notice and exit 0, matching the read path and the module's
    # documented "never raise / always exit 0" contract — not unwind with a traceback + non-zero exit.
    doc = tmp_path / "OWNER_ACTIONS.md"
    doc.write_text(SAMPLE_DOC)
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", str(doc))
    monkeypatch.setitem(voa.PROBES, "A", lambda: (True, "closed just now"))
    monkeypatch.setitem(voa.PROBES, "B", lambda: (False, "still open"))

    real_open = open

    def failing_write_open(path, mode="r", *args, **kwargs):
        if "w" in mode:
            raise OSError("simulated read-only filesystem")
        return real_open(path, mode, *args, **kwargs)
    monkeypatch.setattr("builtins.open", failing_write_open)

    rc = voa.main()
    assert rc == 0
    out = capsys.readouterr().out
    assert "could not write" in out
    assert "will retry next run" in out

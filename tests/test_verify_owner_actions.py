"""Guard scripts/verify_owner_actions.py's fence-parsing, anchor-rewrite, and fail-open contract
(OAE-5, 2026-07-16 owner-selfservice audit). Offline only — no `bq`/`gh` network calls; every probe
is monkeypatched or exercised via a faked subprocess.run so this suite never touches live infra.
"""
import importlib.util
import os
import subprocess
import types

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "verify_owner_actions.py")
    spec = importlib.util.spec_from_file_location("verify_owner_actions", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


voa = _load()


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


def test_check_F_quota_fails_open_on_git_error(monkeypatch):
    monkeypatch.setattr(voa.subprocess, "run",
                        lambda *a, **k: (_ for _ in ()).throw(FileNotFoundError("no git")))
    passed, evidence = voa.check_F_quota()
    assert passed is False


# ---- anchor-finding + heading/bullet rewrite -----------------------------------------------

def test_find_anchor_prefers_heading(tmp_path):
    lines = ["## A. Title\n", "\n", "prose\n", "```verify\n", "id: A\n", "```\n"]
    idx = voa.find_anchor_line_index(lines, 3)
    assert idx == 0


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


def test_main_missing_file_exits_zero_not_raise(monkeypatch, capsys):
    monkeypatch.setattr(voa, "OWNER_ACTIONS_PATH", "/nonexistent/path/OWNER_ACTIONS.md")
    rc = voa.main()
    assert rc == 0
    assert "could not read" in capsys.readouterr().out

"""The autouse `bq`/`gcloud` guard in conftest.py must cover EVERY subprocess entry point (2026-07-29).

WHY THIS FILE EXISTS. The guard was added after `pytest` was found writing real rows into production
`ops.heartbeat` (ops/dashboard/generate_dashboard.py's main() -> beat_heartbeat() -> the real `bq`
CLI, unpatched by four tests in test_generate_dashboard.py). Its first version patched
`subprocess.run` only, and extracted the program name with `os.path.basename(str(cmd))` — which meant
it silently missed two whole families of call:

  - `subprocess.call` / `check_call` / `check_output` / a direct `Popen(...)`, none of which route
    through `subprocess.run`; and
  - `subprocess.run("bq ... ", shell=True)`, where the command is one STRING and basename() of it is
    the entire command line, matching neither "bq" nor "gcloud".

A guard that covers only part of the class it advertises is the same kind of defect as the bug it was
written to stop — it reads as protection at the call site while leaving the hole open. These tests
pin the whole surface so a future narrowing of the guard fails loudly here.

Each blocked-path test asserts the guard's OWN failure (pytest's `Failed`), not merely "something was
raised": letting the real `bq` run and raising CalledProcessError would satisfy a bare
`pytest.raises(BaseException)`, making every one of these vacuous.
"""
import subprocess

import pytest

GUARD_MSG = "reached the live"


# ---- blocked: every entry point must trip the guard ----------------------------------------------

def test_run_with_list_argv_is_blocked():
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run(["bq", "--version"], capture_output=True)


def test_run_with_shell_string_is_blocked():
    # basename("bq --version") is the whole string; only shell-token splitting finds "bq" here.
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run("bq --version", shell=True, capture_output=True)


def test_check_output_is_blocked():
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.check_output(["bq", "--version"])


def test_call_is_blocked():
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.call(["gcloud", "--version"])


def test_direct_popen_is_blocked():
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.Popen(["bq", "--version"], stdout=subprocess.PIPE)


def test_absolute_path_to_the_binary_is_blocked():
    # The real call site would be a bare "bq", but a PATH-resolved absolute path must not slip past.
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run(["/opt/homebrew/bin/bq", "--version"], capture_output=True)


# ---- allowed: the guard must not break ordinary subprocess use -----------------------------------

def test_unrelated_command_still_runs():
    assert subprocess.run(["echo", "hi"], capture_output=True, text=True).stdout.strip() == "hi"


def test_unrelated_shell_command_still_runs():
    assert subprocess.run("echo hi", shell=True, capture_output=True, text=True).stdout.strip() == "hi"


def test_unrelated_check_output_still_runs():
    assert subprocess.check_output(["echo", "ok"], text=True).strip() == "ok"


def test_a_tests_own_monkeypatch_still_wins(monkeypatch):
    """A test that deliberately fakes subprocess.run must override the autouse guard, not fight it —
    otherwise every existing test that mocks a `bq` call would start failing. The autouse fixture and
    the test share one function-scoped monkeypatch stack, so the later setattr wins."""
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: "faked")
    assert subprocess.run(["bq", "query", "SELECT 1"]) == "faked"

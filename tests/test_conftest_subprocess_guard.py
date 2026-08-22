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

2026-07-30 HARDENING PASS. An adversarial review, using a stub `bq` placed on PATH, proved three more
holes in the guard itself (not just in this test file's coverage of it):
  (1) an OFF-BY-ONE in guarded_popen_init's positional-arg reading of Popen's `shell` parameter
      (rest[6] instead of rest[7]) that let a positional `shell=True` string command slip past
      entirely;
  (2) argv[0]-only inspection missing `bq`/`gcloud` invoked through a shell or exec wrapper
      (`env bq`, `sh -c "bq ..."`, `bash -lc "bq ..."`, `xargs bq`, nested `env sh -c 'bq ...'`); and
  (3) subprocess.run/Popen.__init__ being the ONLY patched entry points, missing os.system,
      os.posix_spawn, and os.spawnv/os.spawnve.
See tests/conftest.py's fixture docstring for the full writeup of each fix and its accepted residuals
(a symlinked binary, os.exec*/spawn*p/pty.spawn, and multiprocessing's 'spawn' start method).

Every test below that exercises a BLOCKED path also puts a harmless stub `bq`/`gcloud` on PATH first
(see `stub_cli_path`) purely as a blast-radius backstop: the guard is expected to raise before any
real process ever spawns, so the stub should never actually execute, but per this session's explicit
instructions these tests must never be able to reach the real CLI even if the fix under test has a
bug.
"""
import os
import shutil
import stat
import subprocess

import pytest

GUARD_MSG = "reached the live"


@pytest.fixture
def stub_cli_path(tmp_path, monkeypatch):
    """Put no-op stub `bq`/`gcloud` executables on PATH ahead of anything real. Purely a backstop: the
    guard under test is expected to intercept every call below before it ever reaches a real process,
    so these stubs should never actually run -- but IF a fix under test has a bug and a call gets
    through, it lands on this harmless stub instead of a real `bq`/`gcloud` that could write to
    production BigQuery."""
    bin_dir = tmp_path / "stub_bin"
    bin_dir.mkdir()
    for name in ("bq", "gcloud"):
        stub = bin_dir / name
        stub.write_text("#!/bin/sh\nexit 0\n")
        stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    monkeypatch.setenv("PATH", f"{bin_dir}{os.pathsep}{os.environ.get('PATH', '')}")
    return bin_dir


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


# ---- blocked: the 2026-07-30 hardening pass (off-by-one, wrapper indirection, os-level spawn) ----

def test_positional_shell_arg_popen_is_blocked(stub_cli_path):
    """The exact off-by-one repro: Popen's `shell` parameter passed POSITIONALLY as the 9th argument
    after self (args, bufsize, executable, stdin, stdout, stderr, preexec_fn, close_fds, shell). The
    old guard read `close_fds` (rest[6]) instead of `shell` (rest[7]) here, saw shell=False, and
    treated the whole string 'bq --version' as a literal (nonexistent) program name -- so the real
    `bq` would have run for real via /bin/sh. Must now be blocked."""
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.Popen("bq --version", -1, None, None, None, None, None, False, True)


@pytest.mark.parametrize("argv", [
    ["env", "bq", "--version"],
    ["sh", "-c", "bq --version"],
    ["/bin/sh", "-c", "bq --version"],
    ["bash", "-c", "bq --version"],
    ["bash", "-lc", "bq --version"],
    ["xargs", "bq", "--version"],
], ids=["env", "sh_c", "abs_sh_c", "bash_c", "bash_lc", "xargs"])
def test_wrapper_indirection_forms_are_blocked(stub_cli_path, argv):
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run(argv, capture_output=True)


def test_nested_env_sh_c_is_blocked(stub_cli_path):
    """`env sh -c 'bq ...'` chains a transparent wrapper (env) into a shell wrapper (sh -c) into the
    blocked program -- the scan must recurse through both layers, not just the first."""
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run(["env", "sh", "-c", "bq --version"], capture_output=True)


def test_shell_chained_command_after_wrapper_is_blocked(stub_cli_path):
    """`sh -c "cd /x && bq ..."` -- bq isn't argv[0] of the -c string, it's chained after `&&`. The
    guard must scan every token of a shell -c command line, not just the first."""
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run(["sh", "-c", "cd /tmp && bq --version"], capture_output=True)


def test_untokenizable_shell_string_fails_closed(stub_cli_path):
    """An unbalanced quote makes shlex.split raise ValueError. Deliberately chosen so a NAIVE
    whitespace split (the pre-2026-07-30 extraction) would see argv[0]="bash" and miss the "bq"
    entirely -- only a fail-CLOSED fallback (a raw substring scan of the untokenizable text) still
    catches it. `bash -c` with an unbalanced quote errors out immediately on syntax ("unexpected EOF
    while looking for matching `''") rather than hanging waiting for more input, so this is safe to
    exercise even if the guard under test fails to block it."""
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        subprocess.run("bash -c 'bq --version", shell=True, capture_output=True)


def test_os_system_is_blocked(stub_cli_path):
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        os.system("bq --version")


def test_os_posix_spawn_is_blocked(stub_cli_path):
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        os.posix_spawn(str(stub_cli_path / "bq"), ["bq", "--version"], os.environ.copy())


def test_os_spawnv_is_blocked(stub_cli_path):
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        os.spawnv(os.P_WAIT, str(stub_cli_path / "gcloud"), ["gcloud", "--version"])


def test_os_spawnve_is_blocked(stub_cli_path):
    with pytest.raises(pytest.fail.Exception, match=GUARD_MSG):
        os.spawnve(os.P_WAIT, str(stub_cli_path / "bq"), ["bq", "--version"], os.environ.copy())


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


def test_unrelated_program_still_works_through_every_entry_point():
    """The critical regression guard for the 2026-07-30 hardening pass: an over-broad fix that blocks
    everything (or anything not named bq/gcloud) would be worse than the bugs it fixes. Exercises a
    genuinely unrelated program (echo/true) through every entry point patched in this pass, including
    the new os-level ones, and confirms none of them are touched by the wrapper-indirection scan
    either (a wrapper invoking a non-blocked program must not be flagged)."""
    # subprocess.run / Popen (list and shell-string forms).
    assert subprocess.run(["echo", "hi"], capture_output=True, text=True).stdout.strip() == "hi"
    assert subprocess.run("echo hi", shell=True, capture_output=True, text=True).stdout.strip() == "hi"
    with subprocess.Popen(["echo", "hi"], stdout=subprocess.PIPE, text=True) as p:
        assert p.communicate()[0].strip() == "hi"

    # A non-blocked program reached THROUGH a wrapper must not be flagged either.
    assert subprocess.run(["env", "echo", "hi"], capture_output=True, text=True).stdout.strip() == "hi"
    assert subprocess.run(["sh", "-c", "echo hi"], capture_output=True, text=True).stdout.strip() == "hi"

    # os-level entry points patched in this pass.
    assert os.system("true") == 0
    echo_path = shutil.which("echo")
    true_path = shutil.which("true")
    assert echo_path is not None and true_path is not None

    pid = os.posix_spawn(echo_path, ["echo", "hi"], os.environ.copy())
    _, status = os.waitpid(pid, 0)
    assert os.waitstatus_to_exitcode(status) == 0

    assert os.spawnv(os.P_WAIT, true_path, ["true"]) == 0
    assert os.spawnve(os.P_WAIT, true_path, ["true"], os.environ.copy()) == 0


# ---- subprocess.run's documented `args=` KEYWORD form (quality pass 2026-08-22) -----------------
def test_run_keyword_args_form_is_guarded_not_a_typeerror():
    """`subprocess.run(args=[...])` is valid, documented Python -- CPython's real signature is
    `run(*popenargs, ...)`, so `args` binds by keyword. conftest's guarded_run was hand-written as
    `guarded_run(cmd, *args, **kwargs)` with `cmd` REQUIRED and POSITIONAL, so this form never
    reached the guard at all: it raised `TypeError: guarded_run() missing 1 required positional
    argument: 'cmd'` -- an unrelated, misleading error rather than a pass-through or the intended
    pytest.fail.

    guarded_popen_init was already hardened against exactly this class by binding the real Popen
    signature (see "THE OFF-BY-ONE" in conftest.py's module docstring); guarded_run was the one
    entry point that never got the same treatment. It failed SAFE -- a loud crash, never a silent
    leak to the real CLI -- but it left the guard blind to part of its own calling surface."""
    assert subprocess.run(args=["echo", "hi"], capture_output=True, text=True).stdout.strip() == "hi"
    # check_output routes through the module-level run(*popenargs, **kwargs) this fixture patches.
    assert subprocess.check_output(args=["echo", "ok"], text=True).strip() == "ok"


def test_run_keyword_args_form_still_blocks_a_real_bq_call():
    """...and covering the keyword form must not weaken what gets blocked: a `bq` invocation passed
    via `args=` is caught exactly like the positional form."""
    with pytest.raises(BaseException) as excinfo:
        subprocess.run(args=["bq", "query", "SELECT 1"], capture_output=True)
    assert "live `bq` CLI" in str(excinfo.value)

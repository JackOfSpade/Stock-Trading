"""Shared test-infra helpers for tests/test_*.py (code-quality audit 2026-07-18).

scripts/*.py (and ops/dashboard/generate_dashboard.py, tests/golden_scenarios/run_golden.py) are not
importable packages (no __init__.py), so every test file that exercises one dynamically loads it via
importlib.util.spec_from_file_location. That loader — and the subprocess.run mock factory reused by
several of those files — used to be copy-pasted near-identically ~21 times across tests/test_*.py.
This collects both in one place instead.
"""
import importlib.util
import os
import subprocess
import sys
import types

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ONE import convention for scripts/lib/* across the whole repo: `from lib.X import ...`.
#
# Production scripts must use `from lib.X import ...` — they run as `python scripts/foo.py` from the
# repo root (see .github/workflows/ci.yml), so sys.path[0] is scripts/ and `lib` is the only name
# that resolves. Tests used to import the SAME files a second way (`from scripts.lib.X import ...`,
# via pyproject's pythonpath=["."] + implicit namespace packages), which loaded every lib module
# TWICE under two distinct identities in one pytest process — `lib.md_fence is not
# scripts.lib.md_fence`, with separate function objects and separate module-level state.
#
# That was harmless only by accident: the lib modules happen to hold nothing mutable. The first
# memoization cache, counter, or custom exception class added to any scripts/lib/*.py would have
# silently split in two — a monkeypatch applied to one identity would not be seen by the code
# importing the other. Putting scripts/ on sys.path here, once, lets tests use the same `lib.X`
# spelling as production so exactly one module object exists (codebase audit 2026-07-26).
if os.path.join(ROOT, "scripts") not in sys.path:
    sys.path.insert(0, os.path.join(ROOT, "scripts"))


def load_module_from_path(name, *rel_parts):
    """Dynamically load ROOT/<rel_parts...> as a module registered under `name`."""
    path = os.path.join(ROOT, *rel_parts)
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fake_subprocess_run(returncode, stdout, stderr=""):
    """subprocess.run monkeypatch factory: returns a callable that produces a
    types.SimpleNamespace(returncode, stdout, stderr) and records each call on .calls."""
    def run(cmd, capture_output=None, text=None, timeout=None):
        run.calls.append({"cmd": cmd, "timeout": timeout})
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    run.calls = []
    return run


# ---- autouse guard: no test may reach the real `bq` / `gcloud` CLI (2026-07-29) -------------------
#
# tests/test_generate_dashboard.py's four gd.main()-calling tests monkeypatched gd.q and
# gd.get_user_tz but NOT beat_heartbeat/gd.subprocess.run — main() calls beat_heartbeat()
# unconditionally at the end, which shells out to the REAL `bq` CLI and INSERTs a row into
# production `ops.heartbeat` (source='dashboard'). Confirmed live: rows arriving in bursts of 3
# (one per unpatched main()-calling test), timestamped to each local pytest run — silently spoofing
# the dashboard's own liveness dead-man's switch and adding ~10s of real network round-trips to the
# suite. That specific call site is now also patched per-test (see test_generate_dashboard.py); this
# fixture is the systemic backstop so the whole CLASS of bug — any test anywhere that forgets to fake
# out a `bq`/`gcloud` subprocess call — fails loudly instead of silently writing to prod.
#
# pytest.fail() (not a plain exception) is deliberate: beat_heartbeat wraps its subprocess.run call
# in a bare `except Exception: pass` (by design — a missing `bq` binary must never break a real
# dashboard build), which would silently swallow a plain RuntimeError/AssertionError raised from
# inside guarded_run and defeat this guard for exactly the call site it exists to catch. pytest's
# Failed exception (raised by pytest.fail()) subclasses BaseException, not Exception, specifically so
# it survives a broad `except Exception` in the code under test.
#
# Ordering: autouse fixtures run their setup before the test body executes, using the SAME
# function-scoped `monkeypatch` instance a test's own `monkeypatch` parameter receives (requested
# here as a normal fixture dependency, not constructed separately) — so a test that explicitly does
# `monkeypatch.setattr(gd.subprocess, "run", fake)` (or patches `gd.beat_heartbeat` itself) from
# inside its own body still wins: that setattr lands on the same monkeypatch undo-stack, after this
# fixture's, and monkeypatch always keeps the LAST assignment to a given attribute live until
# teardown unwinds everything in reverse. Verified in
# tests/test_generate_dashboard.py::test_autouse_guard_is_overridden_by_a_tests_own_monkeypatch.
# Guarding subprocess.run ALONE is not enough, and a guard that only half-covers its stated class is
# the same defect it exists to prevent (2026-07-29 review). Two holes closed here:
#   - OTHER ENTRY POINTS. subprocess.call/check_call/check_output — and any direct Popen(...) — never
#     go through subprocess.run. All of them, run() included, funnel through Popen.__init__, so that
#     is the real choke point and the guard is installed there. run() is ALSO still wrapped, purely so
#     the common case reports the friendlier "subprocess.run(...)" wording; either layer alone would
#     catch the call.
#   - shell=True STRING COMMANDS. With a string cmd, `os.path.basename(str(cmd))` returns the whole
#     command line (nothing to split on), which matches neither "bq" nor "gcloud" — so
#     `subprocess.run("bq ... query ...", shell=True)` sailed straight through the first version of
#     this guard. _program_name() now takes the first shell token in that case.
_REAL_SUBPROCESS_RUN = subprocess.run
_REAL_POPEN_INIT = subprocess.Popen.__init__

_BLOCKED_PROGRAMS = ("bq", "gcloud")


def _program_name(cmd, shell=False):
    """Best-effort program name for a subprocess argv, for both list and string command forms.

    A list/tuple argv names the program in element 0. A bare string is the program itself when
    shell=False, but a whole shell command line when shell=True — take its first token there, since
    that is what the shell will actually exec."""
    if isinstance(cmd, (list, tuple)):
        prog = cmd[0] if cmd else ""
    elif shell:
        parts = str(cmd).strip().split()
        prog = parts[0] if parts else ""
    else:
        prog = cmd
    return os.path.basename(str(prog))


@pytest.fixture(autouse=True)
def _block_real_bq_gcloud_calls(monkeypatch):
    def _fail(prog_name, cmd, entry_point):
        pytest.fail(
            f"real {entry_point} reached the live `{prog_name}` CLI during a test (cmd={cmd!r}) — "
            f"this can write to production BigQuery. The test (or a module it calls) is missing a "
            f"subprocess/beat_heartbeat monkeypatch (2026-07-29: ops.heartbeat spoofing incident — "
            f"see this fixture's docstring)."
        )

    def guarded_run(cmd, *args, **kwargs):
        prog_name = _program_name(cmd, kwargs.get("shell", False))
        if prog_name in _BLOCKED_PROGRAMS:
            _fail(prog_name, cmd, "subprocess.run(...)")
        return _REAL_SUBPROCESS_RUN(cmd, *args, **kwargs)

    def guarded_popen_init(self, args=(), *rest, **kwargs):
        shell = kwargs.get("shell", False)
        # shell is Popen's 8th positional parameter after self/args; a positional caller is rare but
        # must not slip past the guard.
        if not shell and len(rest) >= 7:
            shell = rest[6]
        prog_name = _program_name(args, shell)
        if prog_name in _BLOCKED_PROGRAMS:
            _fail(prog_name, args, "subprocess.Popen(...)")
        return _REAL_POPEN_INIT(self, args, *rest, **kwargs)

    monkeypatch.setattr(subprocess, "run", guarded_run)
    monkeypatch.setattr(subprocess.Popen, "__init__", guarded_popen_init)

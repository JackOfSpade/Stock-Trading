"""Shared test-infra helpers for tests/test_*.py (code-quality audit 2026-07-18).

scripts/*.py (and ops/dashboard/generate_dashboard.py, tests/golden_scenarios/run_golden.py) are not
importable packages (no __init__.py), so every test file that exercises one dynamically loads it via
importlib.util.spec_from_file_location. That loader — and the subprocess.run mock factory reused by
several of those files — used to be copy-pasted near-identically ~21 times across tests/test_*.py.
This collects both in one place instead.

The loader's importlib body moved once more in the 2026-09-04 quality pass, to scripts/lib/dynload.py:
it had acquired two further hand-copies OUTSIDE tests/ (scripts/verify_dbt_port.py,
scripts/gen_dbt_port.py), and neither could import this module for it without taking on a hard pytest
dependency (see that file's own header). load_module_from_path() below stays exactly where and what
the 35 test modules importing it expect — same name, same (name, *rel_parts) signature, same
ROOT-relative resolution — and only delegates its four statements.
"""
import inspect
import os
import re
import shlex
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

# MUST stay below that insert (hence the E402 suppression, the same shape
# ops/dashboard/generate_dashboard.py uses for its own post-sys.path lib imports): `lib` only resolves
# once scripts/ is on sys.path, and this file is the thing that puts it there.
from lib.dynload import load_module_from_path as _load_from_abs_path  # noqa: E402


def load_module_from_path(name, *rel_parts):
    """Dynamically load ROOT/<rel_parts...> as a module registered under `name`.

    The importlib recipe itself lives in scripts/lib/dynload.py since the 2026-09-04 quality pass —
    it had three independent hand-copies (here, scripts/verify_dbt_port.py, scripts/gen_dbt_port.py).
    This remains the TEST suite's front door and keeps the ROOT-relative `(name, *rel_parts)` shape
    that 35 test modules call with (`load_module_from_path("check_x", "scripts", "check_x.py")`), so
    the extraction is invisible to every one of them; only the four statements moved. Like the copy it
    replaces, the loaded module is NOT registered in sys.modules — see lib/dynload.py's header for
    what that guarantees."""
    return _load_from_abs_path(name, os.path.join(ROOT, *rel_parts))


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
# (one per unpatched main()-calling test), timestamped to each local pytest run. The residual harm is
# real but narrower than this note used to claim: `state.automation_heartbeat` stopped watching the
# 'dashboard' source on 2026-07-25 (bigquery/106_retire_dashboard_heartbeat.sql — dashboard.yml's CI
# path can never legitimately beat it, since PUBLISH_DASHBOARD is permanently unset there; reverified
# live 2026-07-30 via BigQuery — `state.automation_heartbeat` only watches alert_emailer/weekly_report
# now), so this leak does NOT spoof any liveness dead-man's switch. What it still does, and reason
# enough on its own: writes junk rows into a PRODUCTION ops table on every unguarded run and adds real
# network round-trips to the suite. That specific call site is now also patched per-test (see
# test_generate_dashboard.py); this fixture is the systemic backstop so the whole CLASS of bug — any
# test anywhere that forgets to fake out a `bq`/`gcloud` subprocess call, through ANY entry point —
# fails loudly instead of silently writing to prod.
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
#
# Guarding subprocess.run ALONE is not enough, and a guard that only half-covers its stated class is
# the same defect it exists to prevent. Holes closed here (2026-07-29 review; 2026-07-30 hardening
# pass after an adversarial review proved three more with a stub `bq` on PATH):
#   - OTHER PYTHON ENTRY POINTS. subprocess.call/check_call/check_output — and any direct Popen(...) —
#     never go through subprocess.run. All of them, run() included, funnel through Popen.__init__, so
#     that is the real choke point and the guard is installed there too. run() is ALSO still wrapped,
#     purely so the common case reports the friendlier "subprocess.run(...)" wording; either layer
#     alone would catch the call. `os.popen` and `asyncio.create_subprocess_exec` are ALREADY caught
#     by that same Popen.__init__ patch with no extra code needed: CPython implements both by
#     constructing a `subprocess.Popen(...)` internally — verified against the CPython stdlib source
#     for the interpreter that actually runs this suite, not just assumed (re-verified 2026-09-04 on
#     the 3.13 repo venv; the earlier "this repo's Python 3.14" label named an interpreter neither the
#     venv nor CI ever runs — every workflow pins python-version 3.11): `os.popen()` calls
#     `subprocess.Popen(cmd, shell=True, ...)`,
#     and `asyncio.unix_events._UnixSubprocessTransport._start` calls
#     `subprocess.Popen(args, shell=shell, ...)` — both reference the very `subprocess` module object
#     this fixture patches, so both see the patched `__init__`.
#   - shell=True STRING COMMANDS. With a string cmd, `os.path.basename(str(cmd))` returns the whole
#     command line (nothing to split on), which matches neither "bq" nor "gcloud" — so
#     `subprocess.run("bq ... query ...", shell=True)` sailed straight through the first version of
#     this guard. Program-name extraction now shell-tokenizes (shlex) a shell-mode string instead of
#     naively whitespace-splitting it.
#   - shell=True SEQUENCE COMMANDS (2026-09-04). The other half of the bullet directly above, left
#     open when it was written: `_blocked_program_in` branched on TYPE first and dropped the `shell`
#     flag entirely for a list/tuple, so `subprocess.run(["bq query 'SELECT 1'"], shell=True)`
#     returned None and really did execute the command line (POSIX Popen prepends ['/bin/sh','-c'],
#     making element 0 the whole command line and the rest $0/$1/...). `shell` is now honoured for
#     sequences too: element 0 is tokenized exactly like the bare-string shell=True case.
#   - BYTES ARGV (2026-09-04). subprocess accepts str, bytes and os.PathLike argv elements, but the
#     normalization here was `str(a)`, whose result for bytes is the REPR `"b'bq'"` — matching no
#     program name — so `subprocess.run([b"bq", b"--version"])` and `subprocess.run(b"bq --version",
#     shell=True)` both sailed through. Normalization is now `os.fsdecode` (see `_as_text`), which
#     round-trips all three forms to the real name.
#   - THE OFF-BY-ONE (2026-07-30). `guarded_popen_init` used to read `shell` out of Popen's positional
#     args by hand (`rest[6]`, where `rest` starts at `bufsize`) against a signature whose real
#     `shell` parameter is `rest[7]` — confirmed via `inspect.signature(subprocess.Popen.__init__)`
#     on the interpreter running this suite (self, args, bufsize, executable, stdin, stdout, stderr,
#     preexec_fn, close_fds, shell, ...; re-confirmed unchanged on the 3.13 repo venv 2026-09-04, and
#     the binding below is re-derived at import time so it tracks whatever version is live) — so a
#     POSITIONAL `shell=True` call read `close_fds` instead and was
#     silently treated as shell=False. Fixed by binding the actual call against
#     `inspect.signature(_REAL_POPEN_INIT)` — captured ONCE at import time, from the real bound
#     method, not hardcoded — via `Signature.bind_partial()` instead of hand-indexing a tuple, so a
#     future CPython reordering of Popen's parameters cannot silently reintroduce this: the binding
#     always reflects whatever signature is actually live in the interpreter running the tests.
#   - WRAPPER / INDIRECTION BYPASS (2026-07-30). Checking only argv[0] misses `bq` invoked through a
#     shell or exec wrapper: `env bq`, `sh -c "bq ..."`, `bash -lc "bq ..."`, `xargs bq`, and nested
#     combinations like `env sh -c 'bq ...'`. `_find_blocked_program` now looks through a fixed set of
#     known wrappers (sh, bash, zsh, dash, env, xargs, nohup, stdbuf, time, nice, timeout),
#     shell-tokenizing a `-c`/`-lc`/`-ic` command string and recursing so nested wrapping is still
#     caught, and scanning every token of a wrapper's own body (not just its argv[0]) so
#     `env FOO=1 bq ...` and `sh -c "cd /x && bq ..."` are both caught. A `-c` command string that
#     shlex can't tokenize (e.g. an unbalanced quote) is NOT silently allowed through: it falls back
#     to a raw substring scan of the untokenizable text and still blocks on a match — fails CLOSED,
#     not open.
#     ACCEPTED RESIDUAL: a symlink to the real `bq`/`gcloud` binary filed under any OTHER name is
#     invisible to every check here — there is no name left anywhere to match against. This guard is
#     a name-based ACCIDENT catcher, not a sandbox; a test actively trying to defeat it can always
#     find a way. It exists to catch the class of bug this fixture was written for (a forgotten
#     monkeypatch), not to resist deliberate evasion.
#   - OS-LEVEL SPAWN BYPASS (2026-07-30). Patching subprocess.run/Popen.__init__ alone misses
#     os.system, os.posix_spawn, and os.spawnv/os.spawnve — which os.spawnl/os.spawnle are
#     implemented in terms of via a plain module-global name lookup on every call, so patching
#     os.spawnv/os.spawnve transparently covers those two as well. All four are now patched the same
#     way as subprocess: check, then delegate to the real function captured at import time. This is
#     not purely redundant with the Popen patch either: subprocess.Popen has a POSIX fast path that
#     calls `os.posix_spawn(...)` internally, so any call routed that way passes back through this
#     patched function, bq/gcloud or not.
#     CORRECTED 2026-09-04 (this bullet previously claimed an ordinary, allowed
#     `subprocess.run(["echo", ...])` in this suite "already passes back through" that patch today —
#     measured FALSE on the repo venv, and a reviewer disproves it in one command). Instrumenting
#     `os.posix_spawn` recorded ZERO calls for `subprocess.run(["echo","hi"])`,
#     `subprocess.run(["/bin/echo","hi"])` and `subprocess.run(["echo hi"], shell=True)`. CPython
#     takes that fast path only when `os.path.dirname(executable)` is non-empty AND
#     `(not close_fds or subprocess._HAVE_POSIX_SPAWN_CLOSEFROM)`; `_HAVE_POSIX_SPAWN_CLOSEFROM` is
#     False on this macOS build, so the default `close_fds=True` skips it — only an absolute path
#     WITH `close_fds=False` actually routes through (verified: that one case does hit the patch).
#     So the patch guards a path this suite does not currently reach VIA subprocess, plus any DIRECT
#     `os.posix_spawn` caller — still worth having, but it is not the always-on backstop the old
#     wording implied. Confirmed it does not break ordinary calls either way (see
#     test_unrelated_command_still_runs and friends, and
#     test_unrelated_program_still_works_through_every_entry_point).
#     DELIBERATELY NOT PATCHED: os.execv/os.execve/os.execvp/os.execvpe, os.spawnvp/os.spawnlp (the
#     PATH-searching spawn* variants, which call execvp/execvpe directly rather than going through
#     os.spawnv/os.spawnve), and pty.spawn (which forks then calls os.execlp in the child). Every one
#     of these either REPLACES the calling process image on success (the exec* family never returns)
#     or forks first and only execs in the child. Patching exec* directly is unsafe to validate in
#     THIS suite: calling the REAL exec for an ALLOWED program from the main pytest process would
#     replace the pytest process itself instead of returning, so there is no safe way to write the
#     "still runs normally" regression test this fixture's own tests require for every other entry
#     point without forking inside the test process first — its own source of flakiness (fork-after-
#     threads hazards) this suite does not otherwise take on. `grep`-confirmed 2026-07-30: no file
#     under scripts/, ops/, tests/, or the repo-root Python surface calls any exec*/spawn*p/pty.spawn
#     today, so the marginal protection is low relative to that risk. If that ever changes, patch
#     these the same way (capture the real function at import time, check, delegate) and extend the
#     regression test using a fork, not a direct call from the main test process.
#   - MULTIPROCESSING 'spawn' HOLE (accepted residual, NOT fixed here). `multiprocessing` /
#     `ProcessPoolExecutor` with the macOS-default 'spawn' start method launches a FRESH interpreter
#     process for the worker, which re-imports `subprocess`/`os` from scratch — unpatched, because
#     `monkeypatch.setattr` only mutates attributes on the module OBJECTS living in THIS process's
#     memory, not anything a brand-new child interpreter loads for itself. A worker function that
#     itself shells out to `bq`/`gcloud` would not be caught by anything in this file. No test in this
#     repo currently uses multiprocessing; if one starts to, it needs its own explicit monkeypatch
#     inside the worker function, same as any other process boundary this fixture cannot see across.
_REAL_SUBPROCESS_RUN = subprocess.run
_REAL_POPEN_INIT = subprocess.Popen.__init__
_POPEN_INIT_SIG = inspect.signature(_REAL_POPEN_INIT)
_REAL_OS_SYSTEM = os.system
_REAL_OS_POSIX_SPAWN = os.posix_spawn
_REAL_OS_SPAWNV = os.spawnv
_REAL_OS_SPAWNVE = os.spawnve

_BLOCKED_PROGRAMS = ("bq", "gcloud")

# Known shell/exec wrappers to look THROUGH when argv[0] isn't the blocked program itself but might be
# invoking it indirectly (finding #2, 2026-07-30 review).
_SHELL_NAMES = frozenset({"sh", "bash", "zsh", "dash"})
_SHELL_C_FLAGS = frozenset({"-c", "-lc", "-ic"})
_TRANSPARENT_WRAPPERS = frozenset({"env", "xargs", "nohup", "stdbuf", "time", "nice", "timeout"})
_WRAPPER_NAMES = _SHELL_NAMES | _TRANSPARENT_WRAPPERS

_BLOCKED_RE = re.compile(
    r"(?<![\w./-])(?:" + "|".join(re.escape(p) for p in _BLOCKED_PROGRAMS) + r")(?![\w./-])"
)


def _shell_tokenize_or_none(command_str):
    """shlex-tokenize a shell command string. Returns None (never raises) on an unbalanced-quote-style
    ValueError, so callers can fail CLOSED — still block, via a substring scan — instead of silently
    letting an unparseable string through unchecked."""
    try:
        return shlex.split(command_str)
    except ValueError:
        return None


def _as_text(value):
    """argv elements may be str, bytes, or os.PathLike — subprocess accepts all three. `str()` on a
    bytes element yields its REPR ("b'bq'"), which matches no program name, so a bytes argv sailed
    straight through every name check here (BYTES ARGV hole, 2026-09-04). os.fsdecode round-trips all
    three to the real name (bytes via surrogateescape, which is what a name-based check wants)."""
    try:
        return os.fsdecode(value)
    except TypeError:
        return str(value)


def _scan_wrapper_body(tokens):
    """Scan a wrapper's own argv (everything after its own name) for the blocked program it actually
    invokes. Unlike `_find_blocked_program`, every token is checked directly, not just position 0:
    a wrapper's remaining argv is not "opaque arguments to an unrelated program" the way an ordinary
    program's argv is. For a transparent wrapper it structurally IS the next command
    (`env FOO=1 bq ...`); for a shell it may chain several commands in one string
    (`sh -c "cd /x && bq ..."`). A `-c`/`-lc`/`-ic` token anywhere is treated as introducing a shell
    command string in the token right after it, which is shell-tokenized and recursed into — so
    nested wrapping (`env sh -c 'bq ...'`) is still caught. An unparseable command string fails
    CLOSED (a raw substring scan), never open."""
    tokens = [_as_text(t) for t in tokens]
    for i, tok in enumerate(tokens):
        head = os.path.basename(tok)
        if head in _BLOCKED_PROGRAMS:
            return head
        if tok in _SHELL_C_FLAGS and i + 1 < len(tokens):
            command_str = tokens[i + 1]
            sub_tokens = _shell_tokenize_or_none(command_str)
            if sub_tokens is None:
                m = _BLOCKED_RE.search(command_str)
                return m.group(0) if m else None
            found = _scan_wrapper_body(sub_tokens)
            if found:
                return found
    return None


def _find_blocked_program(argv):
    """Best-effort blocked-program check for a real argv (list/tuple), where argv[0] is structurally
    THE program and the rest are its literal arguments — a filename, a branch name, a SQL string are
    opaque data, not further commands, so only argv[0] itself is matched directly here. If argv[0] is
    a known shell/exec wrapper, descend into `_scan_wrapper_body` instead, since a wrapper's own
    "arguments" are (or embed) the command it will actually run.

    Returns the blocked program name found, or None.

    ACCEPTED RESIDUAL: a symlink to the real `bq`/`gcloud` binary filed under another name is
    invisible to this (or any) name-based check — see the fixture docstring above."""
    argv = [_as_text(a) for a in argv]
    if not argv:
        return None
    head = os.path.basename(argv[0])
    if head in _BLOCKED_PROGRAMS:
        return head
    if head in _WRAPPER_NAMES:
        return _scan_wrapper_body(argv[1:])
    return None


def _blocked_program_in(cmd, shell):
    """Blocked-program check for either argv form subprocess/os accept: a list/tuple argv, or a bare
    string (the program itself when shell=False, a whole shell command line — to be tokenized — when
    shell=True). Fails CLOSED when a shell=True string can't be shlex-tokenized.

    SHELL-FLAG-AWARE FOR SEQUENCES (2026-09-04). This used to branch on TYPE alone and drop `shell`
    entirely for a list/tuple, handing it to `_find_blocked_program`, which reads element 0 as a
    program NAME. That is wrong precisely when shell=True: on POSIX, Popen prepends
    ['/bin/sh', '-c'], so element 0 is the whole shell COMMAND LINE (the remaining elements become
    $0/$1/... for that shell), not a program name — the same structural case the bare-string
    shell=True branch below already tokenizes. Verified pre-fix:
    `subprocess.run(["bq query 'SELECT 1'"], shell=True)` returned None here and really did execute.
    It is the sequence half of the "shell=True STRING COMMANDS" hole the fixture docstring above
    already claims to have closed."""
    if isinstance(cmd, (list, tuple)):
        if shell:
            # Only element 0 is inspected: under shell=True the rest are $0/$1/... positional
            # parameters for the shell, not part of the command line it executes. An EMPTY sequence
            # must NOT IndexError here — it has to pass through to subprocess, which owns that case
            # and does two different things with it (shell=True runs `/bin/sh -c` with no argument
            # and returns 2; shell=False raises IndexError). This guard must never substitute an
            # error of its own for either. Pinned by
            # test_shell_true_sequence_and_bytes_argv_do_not_over_block.
            return _blocked_program_in(cmd[0], True) if cmd else None
        return _find_blocked_program(cmd)
    cmd_str = _as_text(cmd)
    if not shell:
        # Not shell=True: the ENTIRE string is the literal program name/path (no shell parsing) —
        # mirrors what subprocess itself does when given a bare string with shell=False.
        return _find_blocked_program([cmd_str])
    tokens = _shell_tokenize_or_none(cmd_str)
    if tokens is None:
        m = _BLOCKED_RE.search(cmd_str)
        return m.group(0) if m else None
    return _find_blocked_program(tokens)


@pytest.fixture(autouse=True)
def _block_real_bq_gcloud_calls(monkeypatch):
    def _fail(prog_name, cmd, entry_point):
        pytest.fail(
            f"real {entry_point} reached the live `{prog_name}` CLI during a test (cmd={cmd!r}) — "
            f"this can write to production BigQuery. The test (or a module it calls) is missing a "
            f"subprocess/beat_heartbeat monkeypatch (2026-07-29: ops.heartbeat spoofing incident — "
            f"see this fixture's docstring)."
        )

    def guarded_run(*popenargs, **kwargs):
        # Matches subprocess.run's REAL signature -- `run(*popenargs, ...)` in CPython, documented
        # as `run(args, ...)` -- rather than a hand-written `run(cmd, *args, **kwargs)` positional
        # (quality pass 2026-08-22). With a required positional `cmd`, the perfectly valid
        # documented keyword form `subprocess.run(args=[...])` did not reach the guard at all: it
        # raised `TypeError: guarded_run() missing 1 required positional argument: 'cmd'`, an
        # unrelated, misleading error instead of either a clean pass-through or the intended
        # pytest.fail. subprocess.check_output(args=[...]) inherited the same crash, since CPython's
        # check_output calls the module-level run(*popenargs, **kwargs) this fixture patches.
        #
        # This is the same class of bug guarded_popen_init below was already hardened against by
        # binding the real signature (see "THE OFF-BY-ONE" in the module docstring); guarded_run was
        # the one entry point that never got the same treatment. It failed SAFE (a loud crash, not a
        # leak through to real bq/gcloud), and no call site in the repo uses the keyword form today,
        # so it was latent -- but it left the guard blind to part of its own calling surface.
        cmd = popenargs[0] if popenargs else kwargs.get("args", ())
        prog_name = _blocked_program_in(cmd, kwargs.get("shell", False))
        if prog_name:
            _fail(prog_name, cmd, "subprocess.run(...)")
        return _REAL_SUBPROCESS_RUN(*popenargs, **kwargs)

    def guarded_popen_init(self, *args, **kwargs):
        # Bind against the REAL Popen.__init__ signature (captured at import time, from the real
        # bound method) instead of hand-indexing positional args, so `shell` — and everything else —
        # is read correctly no matter which position it lands at for a given CPython version. See
        # "THE OFF-BY-ONE" in the module docstring above for the bug this replaces.
        bound = _POPEN_INIT_SIG.bind_partial(self, *args, **kwargs)
        bound.apply_defaults()
        cmd = bound.arguments.get("args", ())
        shell = bound.arguments.get("shell", False)
        prog_name = _blocked_program_in(cmd, shell)
        if prog_name:
            _fail(prog_name, cmd, "subprocess.Popen(...)")
        return _REAL_POPEN_INIT(self, *args, **kwargs)

    def guarded_system(command):
        # os.system always runs its argument through a subshell (`sh -c`), regardless of the
        # argument's own contents, so this is always a shell=True-style check.
        prog_name = _blocked_program_in(command, True)
        if prog_name:
            _fail(prog_name, command, "os.system(...)")
        return _REAL_OS_SYSTEM(command)

    def guarded_posix_spawn(path, argv, env, *args, **kwargs):
        prog_name = _find_blocked_program([path, *argv])
        if prog_name:
            _fail(prog_name, argv, "os.posix_spawn(...)")
        return _REAL_OS_POSIX_SPAWN(path, argv, env, *args, **kwargs)

    def guarded_spawnv(mode, file, args):
        prog_name = _find_blocked_program([file, *args])
        if prog_name:
            _fail(prog_name, args, "os.spawnv(...)")
        return _REAL_OS_SPAWNV(mode, file, args)

    def guarded_spawnve(mode, file, args, env):
        prog_name = _find_blocked_program([file, *args])
        if prog_name:
            _fail(prog_name, args, "os.spawnve(...)")
        return _REAL_OS_SPAWNVE(mode, file, args, env)

    monkeypatch.setattr(subprocess, "run", guarded_run)
    monkeypatch.setattr(subprocess.Popen, "__init__", guarded_popen_init)
    monkeypatch.setattr(os, "system", guarded_system)
    monkeypatch.setattr(os, "posix_spawn", guarded_posix_spawn)
    # os.spawnl/os.spawnle are implemented (in the stdlib) purely in terms of os.spawnv/os.spawnve via
    # a plain module-global name lookup on every call, so patching these two transparently covers all
    # four spawn*-without-a-'p' variants — verified against the CPython stdlib source for the
    # interpreter running this suite (re-verified 2026-09-04 on the 3.13 repo venv; the earlier
    # "this repo's Python 3.14" label named an interpreter neither the venv nor CI, pinned at 3.11,
    # ever runs).
    monkeypatch.setattr(os, "spawnv", guarded_spawnv)
    monkeypatch.setattr(os, "spawnve", guarded_spawnve)

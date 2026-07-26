"""Shared test-infra helpers for tests/test_*.py (code-quality audit 2026-07-18).

scripts/*.py (and ops/dashboard/generate_dashboard.py, tests/golden_scenarios/run_golden.py) are not
importable packages (no __init__.py), so every test file that exercises one dynamically loads it via
importlib.util.spec_from_file_location. That loader — and the subprocess.run mock factory reused by
several of those files — used to be copy-pasted near-identically ~21 times across tests/test_*.py.
This collects both in one place instead.
"""
import importlib.util
import os
import sys
import types

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

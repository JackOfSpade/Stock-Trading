# scripts/lib/

Shared helpers for the top-level `scripts/*.py` CLI tools (YAML/text IO, BigQuery query
plumbing, the shared SQL-file/routine-manifest parsers the CI gates build on, the by-path module
loader `dynload.py` those tools use to reach into each other, etc.). It is a
namespace package — no `__init__.py`, and none should be added; that would change how `lib`
resolves for no benefit today.

## Why every `scripts/*.py` does `from lib.X import ...` with no `sys.path` line

CPython puts the running script's own directory at `sys.path[0]` automatically whenever it is
invoked as `python <path>/script.py` — from any cwd, absolute or relative path, no flags needed.
Every call site in this repo (`ci.yml`, `auto-merge-claude.yml`, `alert-relay.yml`,
`live-sql-parity.yml`, `sql-dryrun-sweep.yml`, `owner-actions-verify.yml`, and manual/local runs)
invokes scripts exactly that way: `python scripts/<name>.py [args]`. That puts `scripts/` itself at
`sys.path[0]`, which is exactly where `lib/` lives, so `import lib.X` just resolves — no path
manipulation required.

**This is why every workflow call site must keep invoking scripts as `python scripts/<name>.py`.**
Two changes would break it silently:
- **`python -m scripts.<name>`** puts the *current working directory* at `sys.path[0]` instead of
  the script's directory — `lib` would no longer resolve unless the cwd happened to be `scripts/`.
- **`PYTHONSAFEPATH=1` / `python -P`** suppresses the automatic `sys.path[0]` insertion entirely.
  Do not set either for these scripts.

## pytest is different, and already handled

pytest does not run these files as `python scripts/foo.py` — it loads them via
`importlib.util.spec_from_file_location`, which does not touch `sys.path` at all. `tests/conftest.py`
covers that gap with its own single, central `sys.path.insert(0, ...)` for `scripts/`, done once, before
any test module imports. That insert is genuinely load-bearing — leave it alone.

That by-path loading recipe is itself `lib/dynload.py` as of 2026-09-04: it had three independent
hand-copies (`tests/conftest.py`, `scripts/verify_dbt_port.py`, `scripts/gen_dbt_port.py`) and now has
one owner. It lives here rather than in `tests/conftest.py` because two of the three callers are
production checkers and `tests/conftest.py` does `import pytest` at module scope — see that module's
header for the full rationale, and note it is the one `lib` module `tests/conftest.py` imports
(necessarily *after* the `sys.path` insert above, hence its `# noqa: E402`).

## History

Until 2026-09-02, 28 of the 30 top-level scripts each carried their own redundant
`sys.path.insert(0, ...)` before their `lib.X` imports (in four different spellings, one of them
—a bare `os.path.join()` with a single argument — an accidental no-op even by its own logic). Every
one was a provable no-op given the invocation path above; `check_routine_scope.py` and
`check_sql_dryrun.py` had already been running for a while with no such line and no `lib` import
failure, proving it in production. The 2026-09-02 sweep deleted all 28 lines. If you're looking for
where that idiom went: it didn't move, it was dead weight — see the reasoning above instead.

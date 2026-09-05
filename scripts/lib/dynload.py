"""The ONE "load a repo .py file as a module by path" loader (cross-cutting dedup, quality pass
2026-09-04).

WHY THIS EXISTS. scripts/*.py (and ops/dashboard/generate_dashboard.py,
tests/golden_scenarios/run_golden.py) are not importable packages -- no __init__.py, and the top-level
scripts/ directory deliberately has none -- so anything that needs to reach INTO one of them, whether a
test exercising a checker or a checker reusing a sibling checker's parser, has to load it by PATH via
importlib.util.spec_from_file_location. That four-statement recipe (spec_from_file_location ->
module_from_spec -> exec_module -> return) had grown three independent hand-copies with no shared
owner:

  * tests/conftest.py's       load_module_from_path(name, *rel_parts)  -- the test suite's front door,
                                                                          used by 35 test modules
  * scripts/verify_dbt_port.py's _load_module_from_path(name, *rel_parts)
  * scripts/gen_dbt_port.py's    _load(name, *rel)

All three were the same four statements and none of them registered the result in sys.modules, so
this extraction is a pure MOVE, not a behavior change. The copies had not drifted yet -- the benefit
is preventive, and the bar is the one lib/mcp_tokens.py was extracted under: a comment that NAMES the
coupling without SHARING the code is the point at which the third copy earns a lib module. Two of the
three call sites are load-bearing wiring rather than scaffolding (scripts/verify_dbt_port.py is a
BLOCKING ci.yml step and loads check_live_sql_parity.py to get the canonical-body resolver;
scripts/gen_dbt_port.py loads check_live_sql_parity.py AND check_dbt_view_coverage.py).

WHY THE OWNER LIVES IN scripts/lib/ AND NOT IN tests/conftest.py. scripts/verify_dbt_port.py's copy
carried the rationale below, kept VERBATIM here because it is still exactly why the shared owner had
to land on this side of the repo:

    "Local copy of tests/conftest.py's load_module_from_path (bug fix, 2026-08-31 code-quality
     pass): this was previously `from conftest import load_module_from_path` after inserting
     tests/ onto sys.path, making this the only scripts/ file that reaches into tests/ -- and
     tests/conftest.py does `import pytest` at module scope, so it pulled in a hard pytest
     dependency purely as a side effect of wanting this ~6-line helper. Every sibling checker
     (check_live_sql_parity.py, dbt_parity.py, check_dbt_view_coverage.py, check_sql_dryrun.py) is
     self-contained; this restores that."

scripts/lib/ imports nothing but the stdlib here, so nothing about that fix is undone: a checker
importing this does NOT acquire a pytest dependency. It also resolves for both sides with no new
sys.path line -- production scripts get scripts/ at sys.path[0] from CPython itself (`python
scripts/<name>.py`), and tests get it from tests/conftest.py's single central insert. See
scripts/lib/README.md for both halves of that convention.

DELIBERATELY NOT REGISTERED IN sys.modules -- preserved from all three copies, which likewise did not.
Two consequences the call sites are written against: each call re-EXECUTES the file and returns a
FRESH, independent module object (tests/test_cadence_consistency.py loads gen_routine_lists.py four
separate times in one pytest process, and a monkeypatch on one of those objects cannot leak into
another), and a plain `import <name>` elsewhere in the process is unaffected -- loading a script under
a name that happens to collide with a real importable module cannot shadow it. Adding a sys.modules
registration would change both; do not add one without re-checking every call site.
"""
import importlib.util


def load_module_from_path(name, path):
    """Load the Python file at `path` (an ABSOLUTE path) as a module named `name`, and return it.

    The module is executed immediately, so anything its module scope does -- imports, path constants,
    a `P = load_module_from_path(...)` of its own -- happens during this call, and any exception it
    raises propagates. A `path` that does not exist raises FileNotFoundError out of exec_module()
    rather than returning an empty module: loading a file that is not there must fail LOUDLY, since
    every caller here is resolving a checker it is about to depend on.

    Callers pass an absolute path, not repo-relative parts, so this helper owns no notion of where the
    repo root is -- each call site keeps its own os.path.join(REPO/ROOT, ...) exactly as it had
    before the extraction (tests/conftest.py's (name, *rel_parts) front door is the one wrapper that
    still joins, because 35 test modules import THAT signature by name).
    """
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

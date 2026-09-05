"""Unit tests for scripts/lib/dynload.py — the ONE by-path module loader (cross-cutting dedup,
quality pass 2026-09-04).

This helper is load-bearing wiring, not scaffolding. tests/conftest.py's load_module_from_path() is
how 35 test modules reach their subject; scripts/verify_dbt_port.py (a BLOCKING ci.yml step) uses it
to borrow check_live_sql_parity.py's canonical-body resolver; scripts/gen_dbt_port.py uses it for two
checkers. While it lived as three hand-copies it had no direct test at all — its behaviour was only
ever exercised implicitly, at pytest collection time, where a regression would surface as a confusing
collection error rather than a named failure. These pin the four properties the call sites actually
depend on: the file is EXECUTED, the returned object carries the requested `name`, an absent path
fails LOUDLY, and nothing is registered in sys.modules.

No warehouse, no creds — pure offline.
"""
import os
import sys

import pytest

from conftest import ROOT, load_module_from_path
from lib.dynload import load_module_from_path as load_from_abs_path

DYNLOAD_PARTS = ("scripts", "lib", "dynload.py")


def _write_probe(tmp_path, name="probe.py", value=7):
    p = tmp_path / name
    p.write_text(
        f"VALUE = {value}\n"
        "SIDE_EFFECT = []\n"
        "SIDE_EFFECT.append('module scope ran')\n"
        "def doubled():\n"
        "    return VALUE * 2\n",
        encoding="utf-8",
    )
    return p


def test_module_scope_is_executed_and_the_name_is_honoured(tmp_path):
    mod = load_from_abs_path("dynload_probe_alpha", str(_write_probe(tmp_path)))
    assert mod.VALUE == 7
    assert mod.doubled() == 14              # the def ran, and closes over the module's own globals
    assert mod.SIDE_EFFECT == ["module scope ran"]
    assert mod.__name__ == "dynload_probe_alpha"


def test_loaded_module_is_not_registered_in_sys_modules(tmp_path):
    # Preserved from all three pre-extraction copies, and depended on: a script loaded under a name
    # that collides with a real importable module must not shadow it process-wide.
    name = "dynload_probe_unregistered"
    assert name not in sys.modules
    load_from_abs_path(name, str(_write_probe(tmp_path)))
    assert name not in sys.modules


def test_each_call_returns_an_independent_module_object(tmp_path):
    # tests/test_cadence_consistency.py loads gen_routine_lists.py four separate times in one pytest
    # process; a monkeypatch (or any mutation) applied to one of those objects must not leak into
    # another. Re-executing per call is what gives that.
    probe = _write_probe(tmp_path)
    first = load_from_abs_path("dynload_probe_one", str(probe))
    second = load_from_abs_path("dynload_probe_two", str(probe))
    assert first is not second
    first.VALUE = 99
    assert second.VALUE == 7
    assert second.doubled() == 14


def test_absent_path_raises_rather_than_returning_an_empty_module(tmp_path):
    # Fails CLOSED. Every caller is resolving a checker it is about to depend on, so a silently empty
    # module would surface much later as a mystifying AttributeError on the first use.
    with pytest.raises(FileNotFoundError):
        load_from_abs_path("dynload_probe_absent", str(tmp_path / "not_here.py"))


def test_an_exception_from_module_scope_propagates(tmp_path):
    bad = tmp_path / "bad.py"
    bad.write_text("raise RuntimeError('module scope blew up')\n", encoding="utf-8")
    with pytest.raises(RuntimeError, match="module scope blew up"):
        load_from_abs_path("dynload_probe_bad", str(bad))


def test_conftest_wrapper_resolves_rel_parts_under_the_repo_root():
    # The test suite's front door takes ROOT-relative PARTS; the shared owner takes ONE absolute path.
    # Loading the same real repo file both ways must land on the same file — this is the join the
    # wrapper is the last remaining holder of (35 test modules call that signature by name).
    via_wrapper = load_module_from_path("dynload_via_wrapper", *DYNLOAD_PARTS)
    via_abs = load_from_abs_path("dynload_via_abs", os.path.join(ROOT, *DYNLOAD_PARTS))
    assert via_wrapper.__file__ == via_abs.__file__ == os.path.join(ROOT, *DYNLOAD_PARTS)
    assert via_wrapper.__name__ == "dynload_via_wrapper"
    # Same source, independently executed: the two module objects hold equal but distinct functions.
    assert via_wrapper.load_module_from_path is not via_abs.load_module_from_path
    assert via_wrapper.load_module_from_path.__doc__ == via_abs.load_module_from_path.__doc__


def test_the_three_call_sites_all_route_through_this_one_owner():
    # The dedup itself, pinned: the point of the extraction is that none of the three sites it touched
    # grows the recipe back. Matched on the CALL form `spec_from_file_location(` rather than the bare
    # name, deliberately — all three still discuss the recipe in prose (comments are load-bearing
    # here), and a comment mentioning it is not a re-implementation of it. A fourth copy appearing in
    # some OTHER file is out of this test's reach by design; a repo-wide grep test would match this
    # file's own prose and every checker's comments.
    for parts in [("tests", "conftest.py"), ("scripts", "verify_dbt_port.py"),
                  ("scripts", "gen_dbt_port.py")]:
        with open(os.path.join(ROOT, *parts), encoding="utf-8") as fh:
            text = fh.read()
        assert "spec_from_file_location(" not in text, parts
        assert "from lib.dynload import load_module_from_path" in text, parts

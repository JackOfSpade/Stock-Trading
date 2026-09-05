"""Guard scripts/verify_dbt_port.py's normalize() — the comparison that decides "faithful port".

WHY. verify_dbt_port.py is the offline proof that a dbt model re-expresses its bigquery/*.sql view
EXACTLY, used in place of (and ahead of) scripts/dbt_parity.py's credentialed, per-model live query.
Its whole verdict rests on normalize(): if that ever became too lenient, an unfaithful port would be
reported OK and the parallel-run layer would silently stop mirroring the canonical SQL.

normalize() and resolve_profiles_dir() are exercised here — the rest of main() shells out to
`dbt compile`, which is covered end-to-end by actually running it during a porting pass, not by a
unit test that would make the suite depend on a dbt invocation. resolve_profiles_dir() is pure
filesystem/env logic (no subprocess), so it is unit-testable without that dependency.
"""
import os
import shutil

from conftest import load_module_from_path

vp = load_module_from_path("verify_dbt_port", "scripts", "verify_dbt_port.py")
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def test_normalize_unifies_the_two_identifier_quoting_styles():
    """The whole reason a raw string compare will not do: the repo writes `proj.ds.name` while dbt
    renders ref()/source() as `proj`.`ds`.`name`. Both must normalize to one token."""
    repo_style = "SELECT a FROM `stock-trading-498512.state.foo`"
    dbt_style = "SELECT a FROM `stock-trading-498512`.`state`.`foo`"
    assert vp.normalize(repo_style) == vp.normalize(dbt_style)


def test_normalize_ignores_comments_and_whitespace():
    """A port carries an added header comment and may be re-indented; neither changes the SQL."""
    canonical = "SELECT a,\n  b\nFROM t"
    ported = ("-- Parallel-run dbt port of bigquery/99_x.sql:state.y — canonical source is that file.\n"
              "SELECT   a, b   FROM t\n")
    assert vp.normalize(canonical) == vp.normalize(ported)


def test_normalize_is_case_insensitive_for_keywords_but_not_for_string_literals():
    """SQL keywords are case-insensitive, so `select`/`SELECT` must compare equal — but a string
    LITERAL is data: 'TERMINATED' and 'terminated' are different values and must NOT."""
    assert vp.normalize("select a from t") == vp.normalize("SELECT A FROM T")
    assert vp.normalize("WHERE s = 'TERMINATED'") != vp.normalize("WHERE s = 'terminated'")


def test_normalize_detects_a_real_semantic_change():
    """The property that makes the check worth running: a changed column, predicate, or table is a
    different token stream. These are the mutations an unfaithful port actually produces."""
    base = "SELECT a FROM `stock-trading-498512.state.foo` WHERE x = 1"
    assert vp.normalize(base) != vp.normalize("SELECT b FROM `stock-trading-498512.state.foo` WHERE x = 1")
    assert vp.normalize(base) != vp.normalize("SELECT a FROM `stock-trading-498512.state.bar` WHERE x = 1")
    assert vp.normalize(base) != vp.normalize("SELECT a FROM `stock-trading-498512.state.foo` WHERE x = 2")
    assert vp.normalize(base) != vp.normalize("SELECT a FROM `stock-trading-498512.state.foo`")


def test_normalize_does_not_collapse_two_column_lists_that_differ_only_in_order():
    """Column ORDER is part of a view's contract (SELECT * consumers depend on it), so a reordered
    projection must not normalize equal."""
    assert vp.normalize("SELECT a, b FROM t") != vp.normalize("SELECT b, a FROM t")


# ---- compiled_path() — regression test for the hand-copied dataset tuple (2026-09-02 audit) -------
#
# BUG: compiled_path() hardcoded `for ds in ("state", "analytics", "perf")` instead of reusing
# DBT_DATASETS -- the SAME constant all_model_names() (below, in this same file) already imports.
# Order is provably irrelevant to compiled_path() (it just tests os.path.exists per (ds, model) and
# returns on the first hit), so this was a pure, latent duplication -- until a dataset is ever added
# to DBT_DATASETS: all_model_names() would enumerate models under the new folder correctly, but
# compiled_path() would never look there, silently misdiagnosing every model in the new dataset as
# FAIL "no compiled output found" even after a correct `dbt compile`.

def test_compiled_path_uses_dbt_datasets_not_a_hardcoded_tuple(monkeypatch, tmp_path):
    """Pre-fix: FAILS -- compiled_path() only ever looks under state/analytics/perf, so a compiled
    artifact under a dataset added to DBT_DATASETS (here, a 4th "warehouse" folder) is invisible and
    (None, None) comes back regardless of what's actually on disk.
    Post-fix: compiled_path() iterates DBT_DATASETS directly, so it finds the artifact."""
    monkeypatch.setattr(vp, "REPO", str(tmp_path))
    monkeypatch.setattr(vp, "DBT_DATASETS", ("state", "perf", "analytics", "warehouse"))
    d = tmp_path / "dbt" / "target" / "compiled" / "stock_trading" / "models" / "warehouse"
    d.mkdir(parents=True)
    (d / "new_model.sql").write_text("SELECT 1")
    ds, path = vp.compiled_path("new_model")
    assert ds == "warehouse"
    assert path == str(d / "new_model.sql")


def test_compiled_path_still_finds_models_under_the_three_original_datasets(monkeypatch, tmp_path):
    # Non-regression control: the ordinary case (a model under one of the pre-existing three
    # datasets) must keep working exactly as before.
    monkeypatch.setattr(vp, "REPO", str(tmp_path))
    d = tmp_path / "dbt" / "target" / "compiled" / "stock_trading" / "models" / "perf"
    d.mkdir(parents=True)
    (d / "some_model.sql").write_text("SELECT 1")
    ds, path = vp.compiled_path("some_model")
    assert ds == "perf"
    assert path == str(d / "some_model.sql")


# ---- resolve_profiles_dir() — regression test for the /tmp/dbtprof bug (2026-08-31) --------------
#
# BUG: main() used to hardcode DBT_PROFILES_DIR="/tmp/dbtprof", a path nothing in the repo created,
# so `dbt compile` failed with "Invalid value for '--profiles-dir'" on any checkout without a
# coincidentally pre-existing /tmp/dbtprof. These pin the fix: an already-set env var is respected,
# and otherwise dbt/profiles.ci.yml -- ci.yml's own single checked-in source for this profile -- is
# materialized into a fresh tempdir as profiles.yml.
#
# RETURN SHAPE CHANGED (2026-09-02 audit, tempdir-leak fix): resolve_profiles_dir() now returns
# (profiles_dir, owned) instead of a bare str, so main() can rmtree only the tempdir it created
# itself and never a caller-supplied DBT_PROFILES_DIR. `owned` is asserted explicitly below in both
# directions -- False for an already-set env var (main() must NOT delete a directory it doesn't
# own), True for a freshly materialized tempdir (main() SHOULD clean this one up).

def test_resolve_profiles_dir_respects_an_already_set_env_var(monkeypatch):
    monkeypatch.setenv("DBT_PROFILES_DIR", "/some/preexisting/profiles/dir")
    profiles_dir, owned = vp.resolve_profiles_dir()
    assert profiles_dir == "/some/preexisting/profiles/dir"
    assert owned is False  # not created by this call -- main() must never rmtree it


def test_resolve_profiles_dir_materializes_profiles_ci_yml_when_unset(monkeypatch):
    monkeypatch.delenv("DBT_PROFILES_DIR", raising=False)
    profiles_dir, owned = vp.resolve_profiles_dir()
    try:
        assert owned is True  # freshly created by this call -- main() should clean this one up
        written = os.path.join(profiles_dir, "profiles.yml")
        assert os.path.isfile(written)
        with open(written, encoding="utf-8") as f:
            got = f.read()
        with open(os.path.join(REPO, "dbt", "profiles.ci.yml"), encoding="utf-8") as f:
            want = f.read()
        assert got == want  # dbt/profiles.ci.yml is the single checked-in source -- byte-identical, not re-derived
    finally:
        # owned=True hands ownership to the CALLER (main() does exactly this in its own `finally`).
        # Calling the function DIRECTLY means taking on the same duty, or this test leaks one
        # /tmp/dbtprof-XXXXXXXX per pytest run, unbounded -- the very leak the sibling test below,
        # test_resolve_profiles_dir_tempdir_is_cleaned_up_by_main_when_owned, exists to pin
        # (measured 2026-09-04: 124 orphaned dirs had piled up on this machine, +1 per run of this
        # test; after the fix, before==after across a targeted run).
        # Guarded on `owned` so a caller-supplied DBT_PROFILES_DIR could never be removed here.
        if owned:
            shutil.rmtree(profiles_dir, ignore_errors=True)


def test_resolve_profiles_dir_tempdir_is_cleaned_up_by_main_when_owned(monkeypatch):
    """Regression test for the leak itself (2026-09-02 audit): resolve_profiles_dir() creates a
    tempdir via mkdtemp() with nothing to remove it, so the interactive porting workflow this
    function exists for accumulated one orphaned /tmp/dbtprof-XXXXXXXX/ per invocation, forever.
    This drives main() end to end (with --use-compiled OMITTED, so it takes the resolve_profiles_dir
    branch) and asserts the tempdir is gone afterward -- FAILS against the pre-fix code (which never
    called shutil.rmtree at all, so the directory survives) and PASSES against the fix."""
    monkeypatch.delenv("DBT_PROFILES_DIR", raising=False)
    created = {}
    # resolve_profiles_dir() itself calls tempfile.mkdtemp() with no cleanup hook of its own -- the
    # cleanup is main()'s job (see the "finally: if owned: shutil.rmtree(...)" this test pins). Watch
    # the real mkdtemp so the test can see exactly which directory gets created, while everything
    # else about profiles-dir resolution stays real (no need to fake dbt/profiles.ci.yml too).
    real_mkdtemp = vp.tempfile.mkdtemp

    def watched_mkdtemp(*a, **kw):
        d = real_mkdtemp(*a, **kw)
        created["dir"] = d
        return d
    monkeypatch.setattr(vp.tempfile, "mkdtemp", watched_mkdtemp)
    monkeypatch.setattr(vp, "all_model_names", lambda: ["some_model"])
    monkeypatch.setattr(vp, "compiled_path", lambda m: (None, None))  # short-circuits before any dbt/BQ work

    def fake_run(cmd, cwd=None, env=None, capture_output=None, text=None, timeout=None):
        import types
        return types.SimpleNamespace(returncode=0, stdout="", stderr="")
    monkeypatch.setattr(vp.subprocess, "run", fake_run)

    vp.main(["some_model"])  # --use-compiled NOT passed -> takes the resolve_profiles_dir() branch
    assert "dir" in created, "tempfile.mkdtemp was never called -- test setup didn't exercise the branch"
    assert not os.path.isdir(created["dir"]), "owned profiles tempdir was not cleaned up by main()"


def test_help_flag_prints_usage_without_touching_dbt(monkeypatch, capsys):
    """FLAG HANDLING (2026-09-04 quality pass): `--help` used to fall through the membership tests
    with no positional model and therefore silently mean --all — a real ~186-model `dbt compile`
    instead of the Usage block the docstring advertises. Pin the fixed behavior: usage on stdout,
    exit 0, and NO subprocess/compile work of any kind."""
    def exploding_run(*a, **k):  # any dbt invocation is a test failure
        raise AssertionError("main(--help) must not shell out")
    monkeypatch.setattr(vp.subprocess, "run", exploding_run)
    monkeypatch.setattr(vp, "all_model_names", lambda: (_ for _ in ()).throw(AssertionError("must not enumerate models")))
    assert vp.main(["--help"]) == 0
    assert "Usage:" in capsys.readouterr().out


def test_unknown_flag_is_a_loud_exit_2_not_a_silent_full_fleet_run(monkeypatch, capsys):
    """A typo like `--al` used to be ignored and, with no positional model, silently widened the run
    to every model — the same fail-open shape the module's own --use-compiled note rejects. Now it
    must name the bad flag, print usage, and exit 2 without enumerating or compiling anything."""
    def exploding_run(*a, **k):
        raise AssertionError("main(unknown flag) must not shell out")
    monkeypatch.setattr(vp.subprocess, "run", exploding_run)
    monkeypatch.setattr(vp, "all_model_names", lambda: (_ for _ in ()).throw(AssertionError("must not enumerate models")))
    assert vp.main(["--al"]) == 2
    out = capsys.readouterr().out
    assert "--al" in out and "Usage:" in out

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


# ---- resolve_profiles_dir() — regression test for the /tmp/dbtprof bug (2026-08-31) --------------
#
# BUG: main() used to hardcode DBT_PROFILES_DIR="/tmp/dbtprof", a path nothing in the repo created,
# so `dbt compile` failed with "Invalid value for '--profiles-dir'" on any checkout without a
# coincidentally pre-existing /tmp/dbtprof. These pin the fix: an already-set env var is respected,
# and otherwise dbt/profiles.ci.yml -- ci.yml's own single checked-in source for this profile -- is
# materialized into a fresh tempdir as profiles.yml.

def test_resolve_profiles_dir_respects_an_already_set_env_var(monkeypatch):
    monkeypatch.setenv("DBT_PROFILES_DIR", "/some/preexisting/profiles/dir")
    assert vp.resolve_profiles_dir() == "/some/preexisting/profiles/dir"


def test_resolve_profiles_dir_materializes_profiles_ci_yml_when_unset(monkeypatch):
    monkeypatch.delenv("DBT_PROFILES_DIR", raising=False)
    profiles_dir = vp.resolve_profiles_dir()
    written = os.path.join(profiles_dir, "profiles.yml")
    assert os.path.isfile(written)
    with open(written, encoding="utf-8") as f:
        got = f.read()
    with open(os.path.join(REPO, "dbt", "profiles.ci.yml"), encoding="utf-8") as f:
        want = f.read()
    assert got == want  # dbt/profiles.ci.yml is the single checked-in source -- byte-identical, not re-derived

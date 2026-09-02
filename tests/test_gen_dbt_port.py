"""Guard scripts/gen_dbt_port.py — the mechanical bigquery/*.sql VIEW -> dbt model porter.

WHY. gen_dbt_port.py's whole value proposition is that a generated port is FAITHFUL: the only edit
it makes to a canonical view body is substituting ref()/source() for fully-qualified names, and
anything it can't resolve is reported UNRESOLVED and never written (see its own module docstring).
If that guarantee breaks — a written model referencing a ref() that doesn't exist on disk — the
next `dbt compile`/`dbt parse` (including scripts/verify_dbt_port.py's own compile step and CI's
`dbt` job) fails, and nothing in this script's own output points at the file that will break.

substitute() and resolvable_targets()/_structurally_eligible() are exercised directly here — the
rest of main() shells out to two other scripts via _load() and does real file I/O, which the last
test below exercises end-to-end with everything monkeypatched (no bigquery/ scan, no real dbt/
models/ writes outside tmp_path).
"""
import sys

from conftest import load_module_from_path

gdp = load_module_from_path("gen_dbt_port", "scripts", "gen_dbt_port.py")


# ---- substitute() -----------------------------------------------------------------------------

def test_substitute_rewrites_a_known_model_to_ref():
    body = f"SELECT a FROM `{gdp.PROJECT}.state.foo`"
    new_body, unresolved = gdp.substitute(body, {"foo"}, {}, self_name="bar")
    assert new_body == "SELECT a FROM {{ ref('foo') }}"
    assert unresolved == set()


def test_substitute_rewrites_a_declared_source_to_source_macro():
    body = f"SELECT a FROM `{gdp.PROJECT}.raw.orders`"
    new_body, unresolved = gdp.substitute(body, set(), {("raw", "orders"): "raw_src"}, self_name="bar")
    assert new_body == "SELECT a FROM {{ source('raw_src', 'orders') }}"
    assert unresolved == set()


def test_substitute_never_rewrites_the_objects_own_name():
    # A view's body legitimately re-mentions its own fully-qualified name (e.g. inside a comment or
    # a self-referential CTE alias) — substitute() must never rewrite that occurrence to ref('foo')
    # even though "foo" is itself a "known" model, since ref()'ing yourself would make dbt see a
    # (nonexistent) self-dependency. The self-guard routes it to the UNRESOLVED path instead (it is
    # not declared as a source either), leaving the original text untouched — a self-referencing
    # view is exactly the case gen_dbt_port.py's docstring says to report rather than mis-port.
    body = f"SELECT a FROM `{gdp.PROJECT}.state.foo` -- see state.foo above"
    new_body, unresolved = gdp.substitute(body, {"foo"}, {}, self_name="foo")
    assert "ref(" not in new_body
    assert new_body == body  # left completely untouched, not partially rewritten
    assert unresolved == {"state.foo"}


def test_substitute_leaves_a_udf_passthrough_fully_qualified():
    body = f"SELECT `{gdp.PROJECT}.analytics.fn_is_occ_option_symbol`(sym) AS is_occ FROM t"
    new_body, unresolved = gdp.substitute(body, {"fn_is_occ_option_symbol"}, {}, self_name="bar")
    assert "ref(" not in new_body
    assert f"`{gdp.PROJECT}.analytics.fn_is_occ_option_symbol`" in new_body
    assert unresolved == set()


def test_substitute_reports_unresolved_for_a_name_that_is_neither_known_nor_a_source():
    body = f"SELECT a FROM `{gdp.PROJECT}.state.mystery`"
    new_body, unresolved = gdp.substitute(body, set(), {}, self_name="bar")
    assert unresolved == {"state.mystery"}
    assert new_body == body  # left untouched, not partially rewritten


def test_substitute_handles_both_bigquery_quoting_styles():
    dotted = f"SELECT a FROM `{gdp.PROJECT}.state.foo`"
    split = f"SELECT a FROM `{gdp.PROJECT}`.`state`.`foo`"
    a, _ = gdp.substitute(dotted, {"foo"}, {}, self_name="bar")
    b, _ = gdp.substitute(split, {"foo"}, {}, self_name="bar")
    assert a == b == "SELECT a FROM {{ ref('foo') }}"


# ---- resolvable_targets() / _structurally_eligible() ------------------------------------------
#
# REGRESSION (2026-09-02 audit, finding gen-dbt-port-known-set-includes-skipped-targets). `known`
# used to be built from every name in `targets` unconditionally — `model_names() | {v.split(".", 1)[1]
# for v in targets}` — before the per-target loop had checked whether each target actually survives
# its OWN skip branches (NOT_PORTED, no CREATE, not a VIEW). So a same-batch view that gets skipped
# for one of those reasons still ended up "known", and any OTHER same-batch view that referenced it
# had that reference rewritten to a ref() pointing at a model that is never written to disk.
# resolvable_targets() is the fix: it pre-filters to the targets that will actually survive those
# three skip branches, so a skipped target can never leak into `known`.

def test_structurally_eligible_excludes_not_ported():
    final = {("analytics", "theater_independence"): ("VIEW", gdp.PROJECT, "bigquery/1_x.sql", "SELECT 1")}
    assert ("analytics", "theater_independence") in gdp.NOT_PORTED
    assert gdp._structurally_eligible("analytics.theater_independence", final) is False


def test_structurally_eligible_excludes_missing_create():
    final = {}  # no CREATE anywhere in bigquery/*.sql for this name
    assert gdp._structurally_eligible("state.nonexistent", final) is False


def test_structurally_eligible_excludes_non_view_object_types():
    for kind in ("TABLE", "PROCEDURE", "FUNCTION", "MATERIALIZED VIEW", "TABLE FUNCTION"):
        final = {("state", "foo"): (kind, gdp.PROJECT, "bigquery/1_x.sql", "SELECT 1")}
        assert gdp._structurally_eligible("state.foo", final) is False, kind


def test_structurally_eligible_accepts_a_real_view():
    final = {("state", "foo"): ("VIEW", gdp.PROJECT, "bigquery/1_x.sql", "SELECT 1")}
    assert gdp._structurally_eligible("state.foo", final) is True


def test_resolvable_targets_filters_the_batch_to_eligible_names_only():
    final = {
        ("state", "foo_helper"): ("TABLE", gdp.PROJECT, "bigquery/1_x.sql", "SELECT 1"),  # not a VIEW
        ("state", "foo_derived"): ("VIEW", gdp.PROJECT, "bigquery/2_y.sql", "SELECT 1"),
        ("analytics", "theater_independence"): ("VIEW", gdp.PROJECT, "bigquery/3_z.sql", "SELECT 1"),  # NOT_PORTED
        # "state.ghost" is deliberately absent from `final` — no CREATE anywhere in bigquery/*.sql.
    }
    targets = ["state.foo_helper", "state.foo_derived", "analytics.theater_independence", "state.ghost"]
    assert gdp.resolvable_targets(targets, final) == ["state.foo_derived"]


# ---- end-to-end: main() must never write a dangling ref() to a same-batch skip ----------------

def test_gen_dbt_port_does_not_write_a_dangling_ref_to_a_skipped_same_batch_view(monkeypatch, tmp_path, capsys):
    """The concrete failure scenario the finding describes, run through the REAL main().

    A batch of state.foo_helper (a TABLE, so it hits the "not a VIEW" skip) and state.foo_derived
    (a VIEW whose canonical body references foo_helper). Pre-fix, `known` contained "foo_helper"
    regardless of its own skip, so substitute() rewrote foo_derived's reference to
    `{{ ref('foo_helper') }}` and foo_derived was WRITTEN to disk with a ref() to a model that
    itself is never written — exactly the dangling ref `dbt compile`/`dbt parse` chokes on.

    Pre-fix: this test FAILS — dbt/models/state/foo_derived.sql exists and contains
    `ref('foo_helper')`, and "state.foo_derived" never appears in the SKIP output.
    Post-fix: foo_helper is excluded from `known` (resolvable_targets() filters it out as not a
    VIEW), so foo_derived's reference resolves to UNRESOLVED (no source declared either) and
    foo_derived is skipped too — no dangling ref is ever written.
    """
    models_root = tmp_path / "dbt_models"
    (models_root / "state").mkdir(parents=True)  # pre-fix must be able to WRITE here to prove the bug
    monkeypatch.setattr(gdp, "MODELS_ROOT", str(models_root))
    monkeypatch.setattr(gdp, "source_index", dict)  # no sources.yml entries in play

    final = {
        ("state", "foo_helper"): ("TABLE", gdp.PROJECT, "bigquery/999_x.sql", "SELECT 1 AS x"),
        ("state", "foo_derived"): (
            "VIEW", gdp.PROJECT, "bigquery/1000_y.sql",
            f"SELECT x FROM `{gdp.PROJECT}.state.foo_helper`",
        ),
    }

    class _FakeClsp:
        @staticmethod
        def find_final_definitions():
            return final

    class _FakeCov:
        # --all/--list are not passed in this invocation, so these are never actually called —
        # present only because main() calls _load() for this module unconditionally.
        @staticmethod
        def dbt_model_names():
            return set()

        @staticmethod
        def dbt_source_names():
            return set()

        @staticmethod
        def live_views():
            return set()

    def fake_load(name, *rel):
        return {"check_live_sql_parity": _FakeClsp, "check_dbt_view_coverage": _FakeCov}[name]

    monkeypatch.setattr(gdp, "_load", fake_load)
    monkeypatch.setattr(sys, "argv", ["gen_dbt_port.py", "state.foo_helper", "state.foo_derived"])

    rc = gdp.main()
    out = capsys.readouterr().out

    assert "SKIP  state.foo_helper: not a VIEW (TABLE)" in out
    # THE regression check: foo_derived must be skipped too (its ref is unresolved), never written.
    assert "SKIP  state.foo_derived: unresolved refs: state.foo_helper" in out
    assert not (models_root / "state" / "foo_derived.sql").exists()
    assert rc == 1  # both targets skipped -> non-zero exit

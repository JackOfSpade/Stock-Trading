"""Guard the dbt↔live parity gate's column-typing helper (stack review 2026-06-24, RUNBOOK §25 C2).

scripts/dbt_parity.py builds the EXCEPT DISTINCT row-compare per column. col_expr() decides whether a
column is set-comparable directly (scalars) or must be serialized (JSON/ARRAY/STRUCT can't be set-
compared). If that logic regresses, the parity gate would error or silently skip columns. This exercises
it offline (no warehouse, no creds).

dbt_parity.py's own bq() delegates to lib/bq_json.py's run_bq_query (2026-07-18 dedup-sweep), the
shared subprocess-invoke/JSON-slice/returncode/timeout contract that already caused a production bug
HERE (commit "parse bq JSON, not CSV — KeyError on first run" — see also tests/test_alert_relay.py and
tests/test_generate_dashboard.py for the sibling copies). That contract is now proven ONCE on
run_bq_query itself (tests/test_bq_json.py); this file only needs a thin delegation assertion pinning
its own fixed args (C3 dedup, 2026-07-20 audit).
"""
import re
import threading
from pathlib import Path

import pytest

from conftest import load_module_from_path
from lib.sql_files import strip_sql_comments

dp = load_module_from_path("dbt_parity", "scripts", "dbt_parity.py")
# Captured BEFORE the autouse _no_live_scope_by_default fixture below can replace the attribute, so
# the one test that must exercise the REAL live_scope() can restore it (2026-09-04 quality pass —
# without this, that test called the fixture's `lambda: None` and could not fail; see it for the
# vacuity it closes).
REAL_LIVE_SCOPE = dp.live_scope
ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(autouse=True)
def _no_live_scope_by_default(monkeypatch):
    """Neutralize dbt/parity_live_scope.yml for every test in this module unless it says otherwise.

    Added 2026-09-01 with the view-coverage burn-down. main() now filters the compared set through
    live_scope(); every test written before that assumed "no scope file, so compare every compiled
    model", and they monkeypatch compiled_models() with FAKE names like m1/foo/bar. Read against the
    REAL scope file those names are all out of scope, so main() would compare ZERO models — which
    made four tests fail outright and, more dangerously, could make others pass for the WRONG reason
    (several assert main() == 1, which a zero-model run also returns via the partial-compile guard).
    Defaulting to None keeps each test asserting what it was written to assert. The scope-specific
    tests at the end of this file override this themselves and a later setattr wins — three install
    their own fake live_scope, and test_live_scope_missing_file_compares_everything restores the REAL
    one via REAL_LIVE_SCOPE. (Count corrected 2026-09-04: this said "two" and had gone stale, which
    mattered more than a miscount — a scope test that does NOT re-patch silently reads the lambda
    instead of the function it means to exercise, which is exactly what that fourth test was doing.)"""
    monkeypatch.setattr(dp, "live_scope", lambda: None)


def _normalized_halt_echo_mr_cte(sql, end_pattern):
    """The 176 CTE should mirror byte-for-byte (after comment/whitespace normalization).
    `end_pattern` is whatever text immediately follows the CTE's closing `),` in `sql`.

    REQUIRED, no default (2026-09-04 quality pass). It used to default to a pattern matching `al AS`,
    justified as "the next CTE in every model's WITH clause" — a premise the 2026-08-31 halt_echo
    dedup invalidated: that inline CTE text was deleted from all three models, which now carry only
    `{{ halt_echo() }}` (asserted by half (b) of the test below), so a model can no longer be a valid
    input to this helper at all and the default was dead — the single call site always passes
    `{%- endmacro %}` explicitly. The two texts that still DO contain the CTE end differently:
    dbt/macros/halt_echo.sql's copy is followed by `{%- endmacro %}`, and canonical bigquery/176's by
    `al AS`, which the test matches with its own re.findall rather than through this helper."""
    code = strip_sql_comments(sql)
    match = re.search(rf"halt_echo_mr\s+AS\s*\((.*?)\n\),\s*\n{end_pattern}", code, re.DOTALL)
    assert match, "halt_echo_mr CTE missing"
    return " ".join(match.group(1).split())


def _normalized_halt_echo_md_cte(sql):
    """Companion to _normalized_halt_echo_mr_cte, for the OTHER half of the shared pair (reviewer
    finding, 2026-08-31 code-quality pass: the original rewrite of this module byte-compared ONLY
    halt_echo_mr, so a corrupted halt_echo_md -- e.g. its day-match flipped from `=` to `!=`, which
    would invert the fail-closed missing_dependency echo-suppression -- left this whole file green).
    Unlike halt_echo_mr, whose next text differs by input (canonical bigquery/176's `al AS`; the
    macro's `{%- endmacro %}` — the models carry neither since the 2026-08-31 dedup, see that
    helper's docstring), halt_echo_md is ALWAYS immediately followed by halt_echo_mr -- in canonical
    176, in the macro body, and in every pre-dedup inline copy (the macro emits both back-to-back) --
    so no end_pattern parameter is needed here."""
    code = strip_sql_comments(sql)
    match = re.search(r"halt_echo_md\s+AS\s*\((.*?)\n\),\s*\nhalt_echo_mr\s+AS", code, re.DOTALL)
    assert match, "halt_echo_md CTE missing"
    return " ".join(match.group(1).split())


def _render_macro_sources(text):
    """Fold `{{ source('ds', 'tbl') }}` into the literal backtick-qualified form the canonical
    bigquery/*.sql files write directly (`` `PROJECT.ds.tbl` ``) — dbt only ever compiles source()
    to a fully-qualified 3-part identifier for this project, so the substitution is exact, not an
    approximation. Re-derived here rather than shelling out to a real `dbt compile`
    (scripts/verify_dbt_port.py already does that, at porting time) so this stays a pure, offline
    text comparison like the rest of this module — no dbt CLI, no warehouse, no creds."""
    return re.sub(
        r"\{\{\s*source\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)\s*\}\}",
        lambda m: f"`{dp.PROJECT}.{m.group(1)}.{m.group(2)}`",
        text,
    )


# The three models that carried the byte-identical halt_echo_md/halt_echo_mr CTE pair before the
# 2026-08-31 dedup (code-quality pass, dbt#2) extracted it into dbt/macros/halt_echo.sql, mirroring
# dbt/macros/sgov_forward_fill.sql's precedent. Named explicitly (not derived from a `dbt list`) so
# any one of them silently dropping its macro call is caught directly, whether or not it leaves
# behind any trace to grep for; test_halt_echo_model_enumeration_is_exhaustive below separately
# guards against a genuinely NEW model joining this cluster without being added here too.
TRADING_ENABLED = ROOT / "dbt" / "models" / "state" / "trading_enabled.sql"
TRADING_ENABLED_MECHANICAL = ROOT / "dbt" / "models" / "state" / "trading_enabled_mechanical.sql"
B3_TRADING_ENABLED_CHECK = ROOT / "dbt" / "models" / "state" / "b3_trading_enabled_check.sql"
HALT_ECHO_MODELS = [TRADING_ENABLED, TRADING_ENABLED_MECHANICAL, B3_TRADING_ENABLED_CHECK]


def test_trading_gate_dbt_ports_mirror_final_176_halt_echo_missed_run_logic():
    canonical = (ROOT / "bigquery" / "176_decouple_embedding_health_from_trading_gate.sql").read_text()
    canonical_ctes = re.findall(
        r"halt_echo_mr\s+AS\s*\((.*?)\n\),\s*\nal\s+AS",
        strip_sql_comments(canonical),
        re.DOTALL,
    )
    assert len(canonical_ctes) == 3  # trading_enabled, mechanical, and the B3 self-check
    canonical_ctes = [" ".join(c.split()) for c in canonical_ctes]
    # A single shared macro can only be a faithful replacement for all three inline copies if those
    # three copies were already identical to begin with — pin that premise explicitly.
    assert canonical_ctes[0] == canonical_ctes[1] == canonical_ctes[2]

    # Companion extraction for halt_echo_md (2026-08-31, same pass: reviewer finding — this test used
    # to check ONLY halt_echo_mr, so a corrupted halt_echo_md was invisible here). Same premise check:
    # the three pre-dedup inline copies must have already been identical before a shared macro can be
    # a faithful replacement for all three.
    canonical_md_ctes = re.findall(
        r"halt_echo_md\s+AS\s*\((.*?)\n\),\s*\nhalt_echo_mr\s+AS",
        strip_sql_comments(canonical),
        re.DOTALL,
    )
    assert len(canonical_md_ctes) == 3
    canonical_md_ctes = [" ".join(c.split()) for c in canonical_md_ctes]
    assert canonical_md_ctes[0] == canonical_md_ctes[1] == canonical_md_ctes[2]

    # ASSERTION MOVED (2026-08-31 code-quality pass, dbt#2): this used to compare each model's own
    # inline CTE text to canonical, but the dedup deleted that inline text from every model — it now
    # lives once, in dbt/macros/halt_echo.sql. Checking the macro alone would silently stop proving
    # anything about the MODELS the moment one of them stopped calling it (a regression the old,
    # inline-only version of this test could never have missed, since the CTE text lived right there
    # in the model). So this is now two halves: (a) the macro's own CTE text still mirrors canonical
    # 176 — below — and (b) every model that used to carry that CTE still actually INVOKES the macro
    # — in the loop after.
    #
    # (a) macro vs. canonical. The macro body writes `{{ source('ops', 'alerts') }}` /
    # `{{ source('ops', 'run_log') }}` where the canonical file (and, before the dedup, every inline
    # copy) writes a hardcoded backtick literal for the same two tables — the one respect in which
    # the macro's raw text is no longer byte-for-byte with canonical. _render_macro_sources() folds
    # those Jinja calls back to the literal form dbt compiles them to before the comparison, so
    # equality here still means byte-identical executable text, exactly as it did pre-dedup.
    macro_sql = (ROOT / "dbt" / "macros" / "halt_echo.sql").read_text()
    macro_cte = _normalized_halt_echo_mr_cte(_render_macro_sources(macro_sql), end_pattern=r"\{%-\s*endmacro")
    assert macro_cte == canonical_ctes[0]

    # Same check for halt_echo_md — the gap the reviewer found: without this, flipping the CTE's
    # day-match from `=` to `!=` (inverting the fail-closed missing_dependency echo-suppression) would
    # leave every assertion in this file green.
    macro_md_cte = _normalized_halt_echo_md_cte(_render_macro_sources(macro_sql))
    assert macro_md_cte == canonical_md_ctes[0]

    # (b) every model still calls the macro. Without this half, a model that dropped
    # `{{ halt_echo() }}` entirely (e.g. reverted to hand-writing its own `al` CTE with no
    # halt-echo exclusion at all) would leave (a) passing — the macro itself would still be fine —
    # while the live gate silently stopped excluding halt-echo alerts for that one model.
    for model in HALT_ECHO_MODELS:
        text = model.read_text()
        code = strip_sql_comments(text)
        assert re.search(r"\{\{\s*halt_echo\(\)\s*\}\}", code), f"{model.name} no longer calls halt_echo()"
        assert "AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)" in code
        assert "AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)" in code
        assert "bigquery/176_decouple_embedding_health_from_trading_gate.sql" in text

    # The wording assertion stays scoped to the two models whose halt_reason CASE actually emits this
    # phrase — b3_trading_enabled_check.sql has no halt_reason column at all (its `expected` CTE is a
    # bare boolean), so canonical 176 itself only contains this phrase twice, not three times.
    for model in (TRADING_ENABLED, TRADING_ENABLED_MECHANICAL):
        assert "halt-echo dependency+missed_run gate echoes" in strip_sql_comments(model.read_text())


def test_halt_echo_model_enumeration_is_exhaustive():
    # Cross-check for HALT_ECHO_MODELS above: every dbt/models/**/*.sql file that still mentions
    # halt_echo_md/halt_echo_mr or invokes the shared macro must be EXACTLY that hand-picked list —
    # so a future model joining this gate cluster (or one of the three being renamed/moved) fails
    # here loudly instead of silently falling outside test_trading_gate_dbt_ports_mirror_final_176_
    # halt_echo_missed_run_logic's coverage (2026-08-31 code-quality pass, dbt#2).
    referencing = sorted(
        p for p in (ROOT / "dbt" / "models").rglob("*.sql")
        if any(tok in p.read_text() for tok in ("halt_echo_md", "halt_echo_mr", "halt_echo()"))
    )
    assert referencing == sorted(HALT_ECHO_MODELS)


# ---- bq(): thin delegation to lib/bq_json.run_bq_query -- pins THIS caller's fixed max_rows=100000 -
def test_bq_delegates_to_run_bq_query_with_project_and_max_rows_100000(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project, max_rows=None):
        captured["sql"], captured["project"], captured["max_rows"] = sql, project, max_rows
        return [{"severity": "critical"}]
    monkeypatch.setattr(dp, "run_bq_query", fake_run_bq_query)
    assert dp.bq("SELECT 1") == [{"severity": "critical"}]
    assert captured == {"sql": "SELECT 1", "project": dp.PROJECT, "max_rows": 100000}


def test_scalar_columns_compare_directly():
    a = dp.PARITY_ALIAS
    assert dp.col_expr({"column_name": "as_of_date", "data_type": "DATE"}) == f"{a}.`as_of_date`"
    assert dp.col_expr({"column_name": "shares", "data_type": "NUMERIC"}) == f"{a}.`shares`"
    assert dp.col_expr({"column_name": "strategy", "data_type": "STRING"}) == f"{a}.`strategy`"


def test_non_set_comparable_types_are_serialized():
    # JSON / ARRAY<...> / STRUCT<...> can't be set-compared — must be wrapped identically on both sides.
    a = dp.PARITY_ALIAS
    assert dp.col_expr({"column_name": "payload", "data_type": "JSON"}) == f"TO_JSON_STRING({a}.`payload`)"
    assert dp.col_expr({"column_name": "refs", "data_type": "ARRAY<STRING>"}) == f"TO_JSON_STRING({a}.`refs`)"
    assert dp.col_expr({"column_name": "f", "data_type": "STRUCT<a INT64>"}) == f"TO_JSON_STRING({a}.`f`)"


def test_geography_interval_range_columns_are_safe_cast_to_string():
    # C9 (2026-07-20 audit): GEOGRAPHY/INTERVAL/RANGE hit the same "cannot be used in set operations"
    # problem as JSON/ARRAY/STRUCT, but TO_JSON_STRING() doesn't accept them — BigQuery supports an
    # explicit CAST to STRING for all three, so col_expr() must route them through SAFE_CAST instead.
    # RANGE reports as `RANGE<DATE>` etc. in INFORMATION_SCHEMA.COLUMNS, not a bare `RANGE` literal,
    # so this also pins the prefix check (mirroring the existing ARRAY/STRUCT prefix checks).
    a = dp.PARITY_ALIAS
    assert dp.col_expr({"column_name": "loc", "data_type": "GEOGRAPHY"}) == f"SAFE_CAST({a}.`loc` AS STRING)"
    assert dp.col_expr({"column_name": "dur", "data_type": "INTERVAL"}) == f"SAFE_CAST({a}.`dur` AS STRING)"
    assert (dp.col_expr({"column_name": "win", "data_type": "RANGE<DATE>"})
            == f"SAFE_CAST({a}.`win` AS STRING)")


def test_every_column_reference_is_alias_qualified_on_both_except_sides(monkeypatch):
    # REGRESSION (2026-07-18 CI red): a BARE `col` is ambiguous when a view's NAME equals one of its
    # COLUMN names. In `SELECT trading_enabled FROM <p>.state.trading_enabled`, BigQuery resolves the
    # identifier to the TABLE's implicit range variable — the WHOLE ROW as a STRUCT — not the BOOL
    # column (verified live). The other EXCEPT side is an anonymous subquery with no such range
    # variable, so it resolved to the column, and the query died with "Column 1 in EXCEPT DISTINCT has
    # incompatible types: BOOL, STRUCT<trading_enabled BOOL, halt_reason STRING>". Since "incompatible
    # types" is a SCHEMA_DRIFT_MARKER, that fail-closed as NOT VERIFIED and red-lit CI, reporting
    # phantom drift on a model whose port and live view match column-for-column. Both sides must carry
    # the alias so every reference is unambiguously a COLUMN.
    a = dp.PARITY_ALIAS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "trading_enabled", "SELECT TRUE AS trading_enabled")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "trading_enabled")})
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "trading_enabled", "data_type": "BOOL"}])
    seen = {}

    def fake_bq(sql):
        seen["sql"] = sql
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0
    sql = seen["sql"]
    # The column is only ever referenced through the alias — never bare.
    assert f"{a}.`trading_enabled`" in sql
    assert "`trading_enabled`" not in sql.replace(f"{a}.`trading_enabled`", "")
    # BOTH sides are aliased: the compiled subquery AND the live table (2 EXCEPTs x 2 sides = 4).
    assert sql.count(f"AS {a}") == 4


def test_volatile_cols_constant_present():
    # checked_at (CURRENT_TIMESTAMP) must stay excluded from the compare or every view "drifts".
    assert "checked_at" in dp.VOLATILE_COLS


def test_volatile_column_is_actually_dropped_from_the_parity_query(monkeypatch):
    # Behavioral counterpart to the constant-presence check above: prove main() really EXCLUDES a
    # VOLATILE_COLS column from the EXCEPT compare (not just that the constant contains the name). A
    # left-in checked_at (CURRENT_TIMESTAMP, fresh each eval) would make every view falsely drift.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1 AS as_of_date")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "foo")})
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "checked_at", "data_type": "TIMESTAMP"},
                                                {"column_name": "as_of_date", "data_type": "DATE"}])
    seen = {}

    def fake_bq(sql):
        seen["sql"] = sql
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0
    assert "checked_at" not in seen["sql"]        # volatile col excluded from the EXCEPT
    assert "`as_of_date`" in seen["sql"]           # the real column is compared


def test_main_fails_closed_on_incompatible_types_query_error(monkeypatch, capsys):
    # 2026-07-17 parallel-refactor audit: a column whose TYPE differs between the dbt port and the
    # live view makes EXCEPT DISTINCT error "... has incompatible types: INT64, STRING". That is real
    # schema drift `dbt parse` cannot catch, yet it matched none of the old SCHEMA_DRIFT_MARKERS and
    # was mis-routed to a tolerant skip that passed green. It must now FAIL CLOSED on the ERROR path.
    #
    # A SECOND, cleanly-comparing model is essential to make this a true regression catcher: with only
    # the errored model, checked==0 would make main() return 1 via the "everything skipped" guard even
    # WITHOUT the marker fix. The clean model keeps checked>0, so the ONLY way main() reaches exit 1 +
    # the "schema-shaped" errors path is the marker routing the error to `errors` instead of `skipped`.
    assert "incompatible types" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "typed", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "typed" in sql:
            raise RuntimeError("Column 1 in EXCEPT DISTINCT has incompatible types: INT64, STRING at [1:8]")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out   # the ERRORS path (fail-closed), not the benign-skip path


# C10 (2026-07-20 audit): SCHEMA_DRIFT_MARKERS has 6 entries but only "unrecognized name" and
# "incompatible types" were ever proven to actually route to the fail-closed `errors` path. A wording
# mismatch against real BigQuery error text for any of the other 4 would silently regress to the
# tolerant-skip path this module's own history says has happened before — one test per marker below,
# mirroring test_main_fails_closed_on_incompatible_types_query_error's two-model pattern.

def test_main_fails_closed_on_set_operations_query_error(monkeypatch, capsys):
    assert "set operations" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "geo", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "geo" in sql:
            raise RuntimeError("Column 1 in EXCEPT DISTINCT cannot be used in set operations at [1:8]")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out


def test_main_fails_closed_on_not_groupable_query_error(monkeypatch, capsys):
    assert "not groupable" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "notgroup", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "notgroup" in sql:
            raise RuntimeError("Grouping by expressions of type ARRAY is not groupable at [1:1]")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out


def test_main_fails_closed_on_no_matching_signature_query_error(monkeypatch, capsys):
    assert "no matching signature" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "nosig", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "nosig" in sql:
            raise RuntimeError("No matching signature for operator = for argument types: INT64, STRING")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out


def test_main_fails_closed_on_does_not_have_a_column_query_error(monkeypatch, capsys):
    assert "does not have a column" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "nocol", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "nocol" in sql:
            raise RuntimeError("Table stock-trading-498512.state.nocol does not have a column named 'a'")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out


def test_main_fails_closed_on_name_not_found_inside_query_error(monkeypatch, capsys):
    # 2026-08-09: THIRD occurrence of the marker-wording class (after "incompatible types" in the
    # 2026-07-17 audit and the C10 sweep above). A missing column does NOT always say "Unrecognized
    # name": when the reference is ALIAS-QUALIFIED against a subquery — exactly the shape check_one_model
    # builds, `SELECT <col> FROM (compiled) AS parity_src` — BigQuery says "Name <col> not found inside
    # <alias>" instead. state.book_drawdown_watch (dbt port missing peak_window_gap_days, added live by
    # bigquery/153/155) hit this and was routed to a tolerant SKIP that counted as a pass; that CI run
    # only went red because an UNRELATED model drifted the same day. The error text below is the REAL
    # one from CI run 31294544565, not a paraphrase.
    assert "not found inside" in dp.SCHEMA_DRIFT_MARKERS
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "missingcol", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "missingcol" in sql:
            raise RuntimeError("Name peak_window_gap_days not found inside parity_src at [1:320]")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "schema-shaped" in out   # the ERRORS path (fail-closed), not the benign-skip path


def test_main_does_not_flag_identical_geography_column_as_drift(monkeypatch):
    # C9 (2026-07-20 audit): before col_expr() serialized GEOGRAPHY, an identical GEOGRAPHY column on
    # both sides would hit "cannot be used in set operations" (a SCHEMA_DRIFT_MARKER) and fail closed
    # as phantom drift, even though the dbt port and live view match column-for-column. With the fix,
    # the column is routed through SAFE_CAST(...AS STRING) instead and the model compares clean.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "geo", "SELECT ST_GEOGPOINT(0, 0) AS loc")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "geo")})
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "loc", "data_type": "GEOGRAPHY"}])
    seen = {}

    def fake_bq(sql):
        seen["sql"] = sql
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0
    assert "SAFE_CAST" in seen["sql"]
    assert "loc` AS STRING)" in seen["sql"]


# ---- main() exit-code / job-count guards (2026-07-14 audit findings) ----------------------

def test_main_returns_1_when_every_model_is_skipped_due_to_bq_error(monkeypatch, capsys):
    # live_columns_all() is forced to None so this exercises the PER-MODEL fallback path deliberately
    # (2026-07-30): without it, main() would reach the real bq CLI for the batched metadata query — a
    # unit test must not do live I/O, and tests/conftest.py's subprocess guard would trip on it.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1")]))
    monkeypatch.setattr(dp, "live_columns_all", lambda: None)

    def boom(dataset, table):
        raise RuntimeError("bq auth error")
    monkeypatch.setattr(dp, "live_columns", boom)
    rc = dp.main()
    assert rc == 1
    assert "PARITY NOT VERIFIED" in capsys.readouterr().out


def test_main_fails_closed_when_live_columns_returns_zero_rows(monkeypatch, capsys):
    # C8 (2026-07-20 audit): BigQuery's INFORMATION_SCHEMA.COLUMNS does NOT error on a `table_name`
    # filter that matches nothing — it returns zero rows, not an exception — so a live view that was
    # deleted or renamed must NOT be silently folded into the same tolerant-skip bucket used for a
    # genuinely-existing view whose only columns happen to be volatile. A second, cleanly-comparing
    # model keeps checked>0, so the ONLY way main() reaches exit 1 here is the raw_cols==0 case
    # routing to the fail-closed `errors` list instead of `skipped`.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "gone", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "gone"), ("state", "good")})

    def fake_live_columns(dataset, table):
        if table == "gone":
            return []
        return [{"column_name": "a", "data_type": "STRING"}]
    monkeypatch.setattr(dp, "live_columns", fake_live_columns)
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED" in out
    assert "state.gone" in out


def test_main_returns_0_when_nothing_ported_yet(monkeypatch):
    # total==0 is legitimately OK only when there are ALSO no model sources (nothing ported yet).
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([]))
    monkeypatch.setattr(dp, "model_source_count", lambda: 0)
    assert dp.main() == 0


def test_main_returns_1_when_sources_exist_but_zero_compiled(monkeypatch, capsys):
    # #8 (2026-07-17): 0 compiled models WHILE model sources exist = stale COMPILED_ROOT / renamed
    # project / empty compile — must NOT report OK (the checked==0 guard couldn't fire at total==0).
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([]))
    monkeypatch.setattr(dp, "model_source_count", lambda: 40)
    assert dp.main() == 1
    assert "PARITY NOT VERIFIED" in capsys.readouterr().out


def test_main_returns_1_on_schema_shaped_query_error(monkeypatch, capsys):
    # #7 (2026-07-17): a parity query that errors on a schema-shaped cause (dbt port missing a live
    # column -> "Unrecognized name") must FAIL CLOSED, not be swallowed as a benign skip.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"},
                                                {"column_name": "c", "data_type": "STRING"}])

    def boom(sql):
        raise RuntimeError("Unrecognized name: c at [1:8]")
    monkeypatch.setattr(dp, "bq", boom)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED" in out


def test_main_skips_transient_query_error_but_still_reports_other_models(monkeypatch):
    # A genuinely transient error (timeout/network) on one model stays a tolerant SKIP; as long as
    # another model compares cleanly (checked>0, no drift), main() reports OK — the transient error
    # must NOT fail closed the way a schema-shaped error does (#7's other direction).
    models = iter([("state", "flaky", "SELECT 1 AS a"), ("state", "good", "SELECT 1 AS a")])
    monkeypatch.setattr(dp, "compiled_models", lambda: models)
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "flaky"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: [{"column_name": "a", "data_type": "STRING"}])

    def fake_bq(sql):
        if "flaky" in sql:
            raise RuntimeError("bq query timed out after 600s")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0


def test_main_uses_a_single_combined_bq_call_per_model(monkeypatch):
    # Original intent (2026-07-14): the two EXCEPT directions must share ONE bq job per model, not two,
    # because this job's BigQuery job volume once tripped the project's DTS consumer rate-quota.
    # Restated per-CLASS 2026-07-30, when live_columns_all() added a batched metadata job: counting ALL
    # bq calls would now be 2 (1 metadata + 1 parity) and asserting == 1 would fail for a reason that has
    # nothing to do with what this test guards. Counting the PARITY calls specifically keeps the original
    # guarantee exact, and the second assertion additionally pins the metadata cost at "one job for ALL
    # models" — so a regression back to per-model metadata lookups fails here too.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1 AS x")]))
    monkeypatch.setattr(dp, "live_columns", lambda dataset, table: [{"column_name": "x", "data_type": "STRING"}])
    calls = []

    def fake_bq(sql):
        calls.append(sql)
        return [{"n_missing": 0, "n_extra": 3}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    rc = dp.main()
    parity_calls = [s for s in calls if "EXCEPT DISTINCT" in s]
    meta_calls = [s for s in calls if "INFORMATION_SCHEMA.COLUMNS" in s]
    assert len(parity_calls) == 1     # one COMBINED parity query per model, not two
    assert len(meta_calls) <= 1       # metadata is ONE batched job for every model, never per-model
    assert rc == 1                    # n_extra=3 -> drift detected end to end


# ---- live_columns_all(): batched metadata (2026-07-30 Actions cost audit) --------------------

def _meta_row(ds, table, col, dtype, pos):
    return {"ds": ds, "table_name": table, "column_name": col, "data_type": dtype,
            "ordinal_position": pos}


def test_live_columns_all_issues_one_query_covering_every_dataset(monkeypatch):
    # The whole point of the batch: ONE bq invocation, and it must not silently cover only some of the
    # datasets dbt_parity compares (a partial batch would report real models as "deleted or renamed").
    calls = []

    def fake_bq(sql):
        calls.append(sql)
        return [_meta_row("state", "foo", "a", "STRING", 1)]
    monkeypatch.setattr(dp, "bq", fake_bq)
    dp.live_columns_all()
    assert len(calls) == 1
    for ds in dp.DATASET_FOLDERS:
        assert f"`{dp.PROJECT}`.{ds}.INFORMATION_SCHEMA.COLUMNS" in calls[0]


def test_live_columns_all_groups_by_dataset_and_table_preserving_column_order(monkeypatch):
    # Column ORDER matters: main() builds one `exprs` string used on BOTH sides of the EXCEPT, so a
    # reordering would still compare like-for-like, but the batch must not interleave tables.
    rows = [
        _meta_row("state", "foo", "a", "STRING", 1),
        _meta_row("state", "foo", "b", "INT64", 2),
        _meta_row("state", "bar", "z", "BOOL", 1),
        _meta_row("analytics", "foo", "q", "DATE", 1),
    ]
    monkeypatch.setattr(dp, "bq", lambda sql: rows)
    out = dp.live_columns_all()
    assert out[("state", "foo")] == [{"column_name": "a", "data_type": "STRING"},
                                     {"column_name": "b", "data_type": "INT64"}]
    assert out[("state", "bar")] == [{"column_name": "z", "data_type": "BOOL"}]
    # same table NAME in a different dataset must be a distinct key, not merged
    assert out[("analytics", "foo")] == [{"column_name": "q", "data_type": "DATE"}]


def test_live_columns_all_returns_none_on_query_error(monkeypatch):
    # Fail SOFT to the per-model path — never mass-report every model as broken because one batch died.
    def boom(sql):
        raise RuntimeError("bq auth error")
    monkeypatch.setattr(dp, "bq", boom)
    assert dp.live_columns_all() is None


def test_live_columns_all_returns_none_on_unexpected_row_shape(monkeypatch):
    # A row missing the expected keys means the query/response contract changed — do not guess, fall back.
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.live_columns_all() is None
    monkeypatch.setattr(dp, "bq", lambda sql: [])
    assert dp.live_columns_all() is None


def test_main_uses_the_batch_and_does_not_call_live_columns_per_model(monkeypatch):
    # Non-vacuity guard for the optimization itself: if main() ever regressed to per-model metadata
    # lookups while the batch was available, this fails.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "foo", "SELECT 1 AS a"),
                                      ("state", "bar", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "foo"), ("state", "bar")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", "foo"): [{"column_name": "a", "data_type": "STRING"}],
                                 ("state", "bar"): [{"column_name": "a", "data_type": "STRING"}]})
    per_model = []
    monkeypatch.setattr(dp, "live_columns",
                        lambda dataset, table: per_model.append((dataset, table)) or [])
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 0
    assert per_model == []      # the batch served both models; zero per-model metadata jobs


def test_main_fails_closed_when_model_is_absent_from_a_successful_batch(monkeypatch, capsys):
    # EQUIVALENCE with the per-model path's zero-row case (test_main_fails_closed_when_live_columns_
    # returns_zero_rows): a model missing from a SUCCESSFUL batch means the live object does not exist,
    # which must route to the fail-closed "deleted or renamed" branch — NOT to a tolerant skip. A second,
    # cleanly-comparing model keeps checked>0 so exit 1 can only come from that branch.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "gone", "SELECT 1 AS a"),
                                      ("state", "good", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "gone"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", "good"): [{"column_name": "a", "data_type": "STRING"}]})
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED" in out
    assert "state.gone" in out


def test_parity_concurrency_defaults_to_four(monkeypatch):
    monkeypatch.delenv("DBT_PARITY_CONCURRENCY", raising=False)
    assert dp.parity_concurrency() == dp.DEFAULT_PARITY_CONCURRENCY == 4


def test_parity_concurrency_honours_env_override(monkeypatch):
    monkeypatch.setenv("DBT_PARITY_CONCURRENCY", "7")
    assert dp.parity_concurrency() == 7
    # 1 = fully serial, the documented escape hatch if the 2026-06-29 rate-quota is ever pressured again.
    monkeypatch.setenv("DBT_PARITY_CONCURRENCY", "1")
    assert dp.parity_concurrency() == 1


def test_parity_concurrency_is_clamped_and_tolerates_garbage(monkeypatch):
    # A typo'd env var must never crash a CI gate, and must NEVER silently widen concurrency past the
    # ceiling — the whole point of the ceiling is the rate-quota incident.
    for bad in ("", "   ", "abc", "4.5", "None"):
        monkeypatch.setenv("DBT_PARITY_CONCURRENCY", bad)
        assert dp.parity_concurrency() == dp.DEFAULT_PARITY_CONCURRENCY
    monkeypatch.setenv("DBT_PARITY_CONCURRENCY", "0")
    assert dp.parity_concurrency() == 1          # clamped up: 0 workers would compare nothing
    monkeypatch.setenv("DBT_PARITY_CONCURRENCY", "-5")
    assert dp.parity_concurrency() == 1
    monkeypatch.setenv("DBT_PARITY_CONCURRENCY", "9999")
    assert dp.parity_concurrency() == dp.MAX_PARITY_CONCURRENCY == 16


def test_report_order_follows_model_order_not_completion_order(monkeypatch, capsys):
    # THE correctness risk of parallelising the loop: with shared accumulator lists, the report would be
    # ordered by whichever query finished first, so CI output would differ run to run on identical inputs
    # and log diffs would be meaningless. Here the FIRST model is forced to finish LAST (it blocks on an
    # event the LAST model sets), so a completion-ordered report would come out d,b,c,a — the assertion
    # pins it to a,b,c,d. Without positional collection in main(), this test fails.
    names = ["a", "b", "c", "d"]
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", n, f"SELECT 1 AS x -- {n}") for n in names]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", n) for n in names})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", n): [{"column_name": "x", "data_type": "STRING"}]
                                 for n in names})
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 4)
    last_done = threading.Event()

    def fake_bq(sql):
        if "-- d" in sql:
            last_done.set()
        elif "-- a" in sql:
            assert last_done.wait(timeout=10), "model d never ran"
        return [{"n_missing": 1, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    drift_lines = [ln for ln in capsys.readouterr().out.splitlines() if "DRIFT" in ln]
    got = [ln.split("state.")[1].split(":")[0] for ln in drift_lines]
    assert got == names, f"report order {got} is completion-ordered, not model-ordered"


def test_concurrent_run_preserves_fail_closed_error_routing(monkeypatch, capsys):
    # The schema-shaped -> `errors` (fail closed) vs transient -> `skipped` (tolerant) split must survive
    # being moved into a worker thread. One model hits each path; a third compares cleanly.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "schema", "SELECT 1 AS x -- schema"),
                                      ("state", "flaky", "SELECT 1 AS x -- flaky"),
                                      ("state", "good", "SELECT 1 AS x -- good")]))
    monkeypatch.setattr(dp, "model_source_names",
                        lambda: {("state", "schema"), ("state", "flaky"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", n): [{"column_name": "x", "data_type": "STRING"}]
                                 for n in ("schema", "flaky", "good")})
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 3)

    def fake_bq(sql):
        if "-- schema" in sql:
            raise RuntimeError("Unrecognized name: x at [1:8]")
        if "-- flaky" in sql:
            raise RuntimeError("bq query timed out after 600s")
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED state.schema" in out      # fail closed
    assert "skipped state.flaky" in out            # tolerant
    assert "1 models compared" in out              # state.good still counted


def test_unexpected_worker_exception_fails_closed_without_losing_other_models(monkeypatch, capsys):
    # A bug inside check_one_model (it catches its own expected failures) must not kill the whole report
    # nor be swallowed as a tolerant skip.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "boom", "SELECT 1"), ("state", "good", "SELECT 1")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "boom"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns_all", dict)
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 2)
    real = dp.check_one_model

    def sometimes_broken(dataset, name, compiled, batch_cols):
        if name == "boom":
            raise MemoryError("simulated bug inside the worker")
        return real(dataset, name, compiled, batch_cols)
    monkeypatch.setattr(dp, "check_one_model", sometimes_broken)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "unexpected worker failure" in out
    assert "state.good" in out            # the other model was still reported, not lost


def test_transient_skip_under_concurrency_is_retried_serially(monkeypatch, capsys):
    # Concurrency's coverage hazard: a transient failure becomes a TOLERANT skip, and skips still allow
    # exit 0 — so more concurrency could mean fewer real comparisons while CI stays green. The retry turns
    # a first-attempt flake into a real comparison. Here the model fails once then succeeds.
    attempts = {"n": 0}
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "flaky", "SELECT 1 AS x -- flaky"),
                                      ("state", "good", "SELECT 1 AS x -- good")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "flaky"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", n): [{"column_name": "x", "data_type": "STRING"}]
                                 for n in ("flaky", "good")})
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 2)

    def fake_bq(sql):
        if "-- flaky" in sql:
            attempts["n"] += 1
            if attempts["n"] == 1:
                raise RuntimeError("bq query timed out after 600s")   # transient, first attempt only
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0
    out = capsys.readouterr().out
    assert attempts["n"] == 2                  # retried
    assert "2 models compared, 0 skipped" in out   # the flake became a REAL comparison, not a hole


def test_retry_keeps_fail_closed_verdict_and_does_not_mask_a_persistent_skip(monkeypatch, capsys):
    # Two directions the retry must NOT get wrong: (a) if the retry surfaces a schema-shaped error it must
    # be kept (fail closed), and (b) a model that skips on BOTH attempts must stay skipped, not vanish.
    calls = {"n": 0}
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "schema", "SELECT 1 AS x -- schema"),
                                      ("state", "dead", "SELECT 1 AS x -- dead"),
                                      ("state", "good", "SELECT 1 AS x -- good")]))
    monkeypatch.setattr(dp, "model_source_names",
                        lambda: {("state", "schema"), ("state", "dead"), ("state", "good")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", n): [{"column_name": "x", "data_type": "STRING"}]
                                 for n in ("schema", "dead", "good")})
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 3)

    def fake_bq(sql):
        if "-- schema" in sql:
            calls["n"] += 1
            # transient first, then a schema-shaped error the retry must adopt as fail-closed
            raise RuntimeError("bq query timed out after 600s" if calls["n"] == 1
                               else "Unrecognized name: x at [1:8]")
        if "-- dead" in sql:
            raise RuntimeError("bq query timed out after 600s")   # always transient
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED state.schema" in out       # (a) retry's fail-closed verdict kept
    assert "skipped state.dead" in out              # (b) persistent skip still reported


def test_serial_path_is_used_when_concurrency_is_one(monkeypatch):
    # DBT_PARITY_CONCURRENCY=1 must take the plain loop, not a 1-worker pool — the documented rollback.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "a", "SELECT 1 AS x"), ("state", "b", "SELECT 1 AS x")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "a"), ("state", "b")})
    monkeypatch.setattr(dp, "live_columns_all",
                        lambda: {("state", n): [{"column_name": "x", "data_type": "STRING"}]
                                 for n in ("a", "b")})
    monkeypatch.setattr(dp, "parity_concurrency", lambda: 1)
    threads = set()

    def fake_bq(sql):
        threads.add(threading.current_thread().name)
        return [{"n_missing": 0, "n_extra": 0}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    assert dp.main() == 0
    assert threads == {"MainThread"}      # nothing was dispatched to a pool thread


def test_main_skips_the_batch_query_entirely_when_no_models_compiled(monkeypatch):
    # The total==0 / no-sources guards must not cost a BigQuery job.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([]))
    monkeypatch.setattr(dp, "model_source_count", lambda: 0)
    calls = []
    monkeypatch.setattr(dp, "bq", lambda sql: calls.append(sql) or [])
    assert dp.main() == 0
    assert calls == []


# ---- partial-compile guard (2026-07-17 parallel-refactor audit) -----------------------------------

def test_main_fails_closed_when_a_source_model_was_never_compiled(monkeypatch, capsys):
    # Every COMPILED model compared cleanly, but a model SOURCE has no compiled artifact (a partial
    # `dbt compile`), so it was never verified. Reporting full parity OK would leave it silently
    # unchecked — fail closed and name the uncompiled model instead.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "compiled_one", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names",
                        lambda: {("state", "compiled_one"), ("state", "never_compiled")})
    monkeypatch.setattr(dp, "live_columns", lambda ds, t: [{"column_name": "a", "data_type": "STRING"}])
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 1
    out = capsys.readouterr().out
    assert "PARITY NOT VERIFIED" in out
    assert "state.never_compiled" in out
    assert "state.compiled_one" not in out.split("PARITY NOT VERIFIED")[1]   # the compiled one isn't listed


def test_main_ok_when_every_source_has_a_compiled_artifact(monkeypatch):
    # Positive control: a FULL compile (compiled set == source set) with clean parity -> OK, exit 0.
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "m1", "SELECT 1 AS a"), ("perf", "m2", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "m1"), ("perf", "m2")})
    monkeypatch.setattr(dp, "live_columns", lambda ds, t: [{"column_name": "a", "data_type": "STRING"}])
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 0


def test_model_source_count_is_len_of_model_source_names(monkeypatch):
    # model_source_count() is now derived from model_source_names(); pin the invariant so the two can
    # never disagree (the total==0 branch uses the count, the partial guard uses the names).
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "a"), ("state", "b"), ("perf", "c")})
    assert dp.model_source_count() == 3


def test_live_scope_bounds_the_live_comparison_without_hiding_models(monkeypatch, capsys):
    """dbt/parity_live_scope.yml selects which models get the EXPENSIVE live row comparison.

    Added 2026-09-01 with the view-coverage burn-down: 101 newly ported models are gated by the
    OFFLINE token-identity check (scripts/verify_dbt_port.py) rather than by one live BigQuery job
    each, which would have roughly tripled the warehouse-validation job. Two properties matter and
    are pinned here: (1) an out-of-scope model is EXCLUDED from the live comparison and never
    queried, and (2) it is NOT counted as uncompiled — narrowing compiled_names alongside `models`
    would make the partial-compile guard fire on every deferred model and print PARITY NOT VERIFIED
    for models that compiled perfectly well."""
    monkeypatch.setattr(dp, "compiled_models",
                        lambda: iter([("state", "in_scope", "SELECT 1 AS a"),
                                      ("state", "deferred", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "in_scope"), ("state", "deferred")})
    monkeypatch.setattr(dp, "orphan_compiled_artifacts", set)
    monkeypatch.setattr(dp, "live_scope", lambda: {"in_scope"})
    seen = []

    def fake_live_columns(ds, tbl):
        seen.append(tbl)
        return [{"column_name": "a", "data_type": "STRING"}]

    monkeypatch.setattr(dp, "live_columns", fake_live_columns)
    monkeypatch.setattr(dp, "live_columns_all", lambda: None)   # force the per-model path, so `seen` is meaningful
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 0
    out = capsys.readouterr().out
    assert "1 models compared" in out
    assert "1 deferred to the offline token-identity gate" in out
    assert "PARITY NOT VERIFIED" not in out       # deferred is not the same as uncompiled
    assert seen == ["in_scope"]                    # the deferred model was never queried


def test_live_scope_missing_file_compares_everything(monkeypatch, tmp_path):
    """A missing or unreadable scope file must fall back to the STRICTER behaviour (compare every
    compiled model), never fail open. A typo in the filename must not silently disable the live gate."""
    # VACUITY FIX (2026-09-04 quality pass): _no_live_scope_by_default had already replaced
    # dp.live_scope with `lambda: None`, which satisfies the assertion below no matter what the real
    # function does — the test passed even with LIVE_SCOPE_YML pointed at the real, parseable scope
    # file, so inverting live_scope()'s `except` to fail OPEN would have left it green. Restore the
    # function captured at import (REAL_LIVE_SCOPE) so the REAL one runs; it reads the module-global
    # LIVE_SCOPE_YML, so the setattr below still steers it.
    monkeypatch.setattr(dp, "live_scope", REAL_LIVE_SCOPE)
    monkeypatch.setattr(dp, "LIVE_SCOPE_YML", str(tmp_path / "nope.yml"))
    assert dp.live_scope() is None
    # Non-vacuity control, in the same test so the two can never drift apart: pointed at the REAL
    # dbt/parity_live_scope.yml the same function must return a non-empty set. Without this, a
    # live_scope() that returned None unconditionally (the other way to break the gate — every model
    # compared, the expensive path the file exists to bound) would still pass the assertion above.
    monkeypatch.setattr(dp, "LIVE_SCOPE_YML", str(ROOT / "dbt" / "parity_live_scope.yml"))
    names = dp.live_scope()
    assert names and len(names) > 0


# ---- stale-name guard on dbt/parity_live_scope.yml (2026-09-02 audit) -------------------------
#
# BUG (finding parity-live-scope-no-name-validation): live_scope() trusts every name in
# dbt/parity_live_scope.yml with no check against a real dbt model name. A future rename/typo in
# that YAML never matches anything, so the model it was meant to select for the expensive LIVE row
# comparison just silently falls into `deferred` (the cheaper offline-only path) instead — no error,
# no warning, no count discrepancy anywhere, and the run still prints "OK: every compared dbt model
# matches its live view row-for-row" for the smaller set it actually compared.

def test_live_scope_warns_about_a_stale_name_with_no_matching_model(monkeypatch, capsys):
    """Pre-fix: FAILS -- no warning is ever printed; "renamed_away" is silently swallowed and the
    run reports plain OK with no trace that a scope entry didn't resolve to anything.
    Post-fix: main() diffs `scope` against model_source_names() and prints a loud, non-fatal
    WARNING naming every unmatched entry — advisory only (main() still returns 0), since a stale
    scope entry is a config hygiene issue, not proof of live data drift."""
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "in_scope", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "in_scope")})
    monkeypatch.setattr(dp, "orphan_compiled_artifacts", set)
    # "renamed_away" is a stale/typo'd scope entry with no matching model anywhere.
    monkeypatch.setattr(dp, "live_scope", lambda: {"in_scope", "renamed_away"})
    monkeypatch.setattr(dp, "live_columns", lambda ds, tbl: [{"column_name": "a", "data_type": "STRING"}])
    monkeypatch.setattr(dp, "live_columns_all", lambda: None)  # force the per-model fallback path
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 0  # advisory: a stale scope name must not fail the run
    out = capsys.readouterr().out
    assert "WARNING" in out
    assert "renamed_away" in out


def test_live_scope_prints_no_warning_when_every_name_matches_a_model(monkeypatch, capsys):
    # Non-vacuity control for the guard above: a fully valid scope file must print nothing extra.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "in_scope", "SELECT 1 AS a")]))
    monkeypatch.setattr(dp, "model_source_names", lambda: {("state", "in_scope")})
    monkeypatch.setattr(dp, "orphan_compiled_artifacts", set)
    monkeypatch.setattr(dp, "live_scope", lambda: {"in_scope"})
    monkeypatch.setattr(dp, "live_columns", lambda ds, tbl: [{"column_name": "a", "data_type": "STRING"}])
    monkeypatch.setattr(dp, "live_columns_all", lambda: None)
    monkeypatch.setattr(dp, "bq", lambda sql: [{"n_missing": 0, "n_extra": 0}])
    assert dp.main() == 0
    assert "WARNING" not in capsys.readouterr().out

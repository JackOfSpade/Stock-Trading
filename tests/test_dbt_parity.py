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
from conftest import load_module_from_path

dp = load_module_from_path("dbt_parity", "scripts", "dbt_parity.py")


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
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1")]))

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
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1 AS x")]))
    monkeypatch.setattr(dp, "live_columns", lambda dataset, table: [{"column_name": "x", "data_type": "STRING"}])
    calls = []

    def fake_bq(sql):
        calls.append(sql)
        return [{"n_missing": 0, "n_extra": 3}]
    monkeypatch.setattr(dp, "bq", fake_bq)
    rc = dp.main()
    assert len(calls) == 1          # one combined query, not two
    assert rc == 1                   # n_extra=3 -> drift detected end to end


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

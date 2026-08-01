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

from conftest import load_module_from_path
from lib.sql_files import strip_sql_comments

dp = load_module_from_path("dbt_parity", "scripts", "dbt_parity.py")
ROOT = Path(__file__).resolve().parents[1]


def _normalized_halt_echo_mr_cte(sql):
    """The 107 CTE has no dbt refs, so its executable text should mirror byte-for-byte."""
    code = strip_sql_comments(sql)
    match = re.search(r"halt_echo_mr\s+AS\s*\((.*?)\n\),\s*\nal\s+AS", code, re.DOTALL)
    assert match, "halt_echo_mr CTE missing"
    return " ".join(match.group(1).split())


def test_trading_gate_dbt_ports_mirror_final_107_halt_echo_missed_run_logic():
    canonical = (ROOT / "bigquery" / "107_halt_echo_missed_run_gate.sql").read_text()
    canonical_ctes = re.findall(
        r"halt_echo_mr\s+AS\s*\((.*?)\n\),\s*\nal\s+AS",
        strip_sql_comments(canonical),
        re.DOTALL,
    )
    assert len(canonical_ctes) == 3  # trading_enabled, mechanical, and the B3 self-check

    models = [
        ROOT / "dbt" / "models" / "state" / "trading_enabled.sql",
        ROOT / "dbt" / "models" / "state" / "trading_enabled_mechanical.sql",
    ]
    for model, canonical_cte in zip(models, canonical_ctes[:2]):
        sql = model.read_text()
        code = strip_sql_comments(sql)
        assert _normalized_halt_echo_mr_cte(sql) == " ".join(canonical_cte.split())
        assert "AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)" in code
        assert "halt-echo dependency+missed_run gate echoes" in code
        assert "bigquery/107_halt_echo_missed_run_gate.sql" in sql


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
    monkeypatch.setattr(dp, "live_columns_all", lambda: {})
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

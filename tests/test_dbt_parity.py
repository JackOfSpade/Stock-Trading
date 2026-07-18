"""Guard the dbt↔live parity gate's column-typing helper (stack review 2026-06-24, RUNBOOK §25 C2).

scripts/dbt_parity.py builds the EXCEPT DISTINCT row-compare per column. col_expr() decides whether a
column is set-comparable directly (scalars) or must be serialized (JSON/ARRAY/STRUCT can't be set-
compared). If that logic regresses, the parity gate would error or silently skip columns. This exercises
it offline (no warehouse, no creds).

dbt_parity.py's own bq() re-implements the same bq-stdout->JSON slice pattern that already caused a
production bug HERE (commit "parse bq JSON, not CSV — KeyError on first run" — see also
tests/test_alert_relay.py and tests/test_generate_dashboard.py for the sibling copies), yet had zero
test coverage of that exact regression class. These lock the banner-tolerant parsing.
"""
import importlib.util
import os
import types

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "dbt_parity.py")
    spec = importlib.util.spec_from_file_location("dbt_parity", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


dp = _load()


def _fake_run(returncode, stdout, stderr=""):
    def run(cmd, capture_output=None, text=None, timeout=None):
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


# ---- bq() JSON-slice helper (the exact regressed bug class) -------------------------------

def test_bq_parses_banner_prefixed_json(monkeypatch):
    # bq prints a human banner before the JSON array; bq() must slice from the first '['.
    monkeypatch.setattr(dp.subprocess, "run",
                        _fake_run(0, 'Welcome to BigQuery!\nUpdate available.\n[{"severity":"critical"}]'))
    assert dp.bq("SELECT 1") == [{"severity": "critical"}]


def test_bq_empty_when_no_array(monkeypatch):
    # No JSON array in stdout (e.g. an empty result printed as nothing) -> [], not a crash.
    monkeypatch.setattr(dp.subprocess, "run", _fake_run(0, "No rows.\n"))
    assert dp.bq("SELECT 1") == []


def test_bq_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(dp.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(RuntimeError):
        dp.bq("SELECT 1")


def test_scalar_columns_compare_directly():
    assert dp.col_expr({"column_name": "as_of_date", "data_type": "DATE"}) == "`as_of_date`"
    assert dp.col_expr({"column_name": "shares", "data_type": "NUMERIC"}) == "`shares`"
    assert dp.col_expr({"column_name": "strategy", "data_type": "STRING"}) == "`strategy`"


def test_non_set_comparable_types_are_serialized():
    # JSON / ARRAY<...> / STRUCT<...> can't be set-compared — must be wrapped identically on both sides.
    assert dp.col_expr({"column_name": "payload", "data_type": "JSON"}) == "TO_JSON_STRING(`payload`)"
    assert dp.col_expr({"column_name": "refs", "data_type": "ARRAY<STRING>"}) == "TO_JSON_STRING(`refs`)"
    assert dp.col_expr({"column_name": "f", "data_type": "STRUCT<a INT64>"}) == "TO_JSON_STRING(`f`)"


def test_volatile_cols_constant_present():
    # checked_at (CURRENT_TIMESTAMP) must stay excluded from the compare or every view "drifts".
    assert "checked_at" in dp.VOLATILE_COLS


def test_volatile_column_is_actually_dropped_from_the_parity_query(monkeypatch):
    # Behavioral counterpart to the constant-presence check above: prove main() really EXCLUDES a
    # VOLATILE_COLS column from the EXCEPT compare (not just that the constant contains the name). A
    # left-in checked_at (CURRENT_TIMESTAMP, fresh each eval) would make every view falsely drift.
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1 AS as_of_date")]))
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


def test_bq_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise dp.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(dp.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        dp.bq("SELECT 1")


# ---- main() exit-code / job-count guards (2026-07-14 audit findings) ----------------------

def test_main_returns_1_when_every_model_is_skipped_due_to_bq_error(monkeypatch, capsys):
    monkeypatch.setattr(dp, "compiled_models", lambda: iter([("state", "foo", "SELECT 1")]))

    def boom(dataset, table):
        raise RuntimeError("bq auth error")
    monkeypatch.setattr(dp, "live_columns", boom)
    rc = dp.main()
    assert rc == 1
    assert "PARITY NOT VERIFIED" in capsys.readouterr().out


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

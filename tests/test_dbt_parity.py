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
    def run(cmd, capture_output=None, text=None):
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

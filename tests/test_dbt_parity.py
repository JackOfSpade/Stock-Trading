"""Guard the dbt↔live parity gate's column-typing helper (stack review 2026-06-24, RUNBOOK §25 C2).

scripts/dbt_parity.py builds the EXCEPT DISTINCT row-compare per column. col_expr() decides whether a
column is set-comparable directly (scalars) or must be serialized (JSON/ARRAY/STRUCT can't be set-
compared). If that logic regresses, the parity gate would error or silently skip columns. This exercises
it offline (no warehouse, no creds).
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "dbt_parity.py")
    spec = importlib.util.spec_from_file_location("dbt_parity", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


dp = _load()


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

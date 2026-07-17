import json

import pytest

from scripts.lib.bq_json import parse_bq_json_stdout


def test_parse_bq_json_stdout_accepts_clean_json_array():
    assert parse_bq_json_stdout('[{"x": "1"}]') == [{"x": "1"}]


def test_parse_bq_json_stdout_accepts_empty_stdout_as_no_rows():
    assert parse_bq_json_stdout("") == []
    assert parse_bq_json_stdout("No rows.\n") == []


def test_parse_bq_json_stdout_skips_bracketed_status_text_before_json():
    stdout = "Waiting on bqjob [RUNNING]\nStill waiting [2s]\n[{\"x\": \"1\"}]"
    assert parse_bq_json_stdout(stdout) == [{"x": "1"}]


def test_parse_bq_json_stdout_raises_when_bracketed_output_never_becomes_json():
    with pytest.raises(json.JSONDecodeError):
        parse_bq_json_stdout("Waiting on bqjob [RUNNING]\n")


def test_parse_bq_json_stdout_rejects_non_object_rows():
    with pytest.raises(ValueError):
        parse_bq_json_stdout("[1]")

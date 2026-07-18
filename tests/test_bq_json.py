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


def test_parse_bq_json_stdout_skips_a_wellformed_json_bracket_before_the_real_array():
    # The scan tries EVERY '['; correctness when a banner's bracketed text is ITSELF valid JSON rests
    # entirely on json.loads rejecting the whole trailing string ("Extra data") for the wrong '['.
    # Every existing banner fixture uses INVALID JSON ([RUNNING], [2s]), so nothing pins this case: a
    # raw_decode-style refactor (a natural way to drop the O(n^2) full-tail re-scan) would return the
    # WRONG early array here. These lock the whole-string requirement (2026-07-17 parallel-refactor audit).
    assert parse_bq_json_stdout('Preview: [1, 2]\n[{"x": "1"}]') == [{"x": "1"}]
    assert parse_bq_json_stdout('[{"a": "1"}] is the schema\n[{"x": "1"}]') == [{"x": "1"}]

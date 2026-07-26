import json

import pytest

import lib.bq_json as bq_json
from lib.bq_json import parse_bq_json_stdout, run_bq_query

from conftest import fake_subprocess_run as _fake_run


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


# ---- run_bq_query(): the shared subprocess-invoke half of the bq()-wrapper pattern (argv shape,
# banner-prefixed JSON parse, nonzero-returncode/timeout -> RuntimeError). This was independently
# re-tested identically in each of the 4 callers' own test files (test_check_live_sql_parity.py,
# test_check_live_roster_parity.py, test_dbt_parity.py, test_alert_relay.py) even after the
# production code itself was consolidated onto this one function (2026-07-18 dedup-sweep) -- proven
# here ONCE so each caller's test file only needs a thin delegation assertion pinning its own fixed
# args (max_rows, project) rather than re-verifying the subprocess/JSON contract four times (C3,
# 2026-07-20 audit).
def test_run_bq_query_parses_banner_prefixed_json(monkeypatch):
    monkeypatch.setattr(bq_json.subprocess, "run",
                        _fake_run(0, 'Waiting on bqjob [RUNNING]\n[{"view_definition": "SELECT 1"}]'))
    assert run_bq_query("SELECT 1", "proj") == [{"view_definition": "SELECT 1"}]


def test_run_bq_query_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(bq_json.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(RuntimeError, match="access denied"):
        run_bq_query("SELECT 1", "proj")


def test_run_bq_query_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise bq_json.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(bq_json.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        run_bq_query("SELECT 1", "proj")


def test_run_bq_query_uses_readonly_argv_and_default_timeout_when_max_rows_omitted(monkeypatch):
    fake = _fake_run(0, "[]")
    monkeypatch.setattr(bq_json.subprocess, "run", fake)
    run_bq_query("SELECT strategy_code FROM t", "myproj-123")
    cmd = fake.calls[0]["cmd"]
    # No max_rows given -> no --max_rows flag at all (matches check_live_sql_parity.py's no-flag
    # behavior, the reference shape run_bq_query's own docstring commits to).
    assert cmd == ["bq", "--project_id=myproj-123", "--quiet", "--headless", "--format=json",
                   "query", "--use_legacy_sql=false", "SELECT strategy_code FROM t"]
    assert fake.calls[0]["timeout"] == 600
    # read-only: no bq write/insert/load subcommand ever appears in the argv.
    assert not ({"insert", "load", "cp", "rm", "mk"} & set(cmd))


def test_run_bq_query_appends_max_rows_flag_when_given(monkeypatch):
    fake = _fake_run(0, "[]")
    monkeypatch.setattr(bq_json.subprocess, "run", fake)
    run_bq_query("SELECT 1", "proj", max_rows=100000)
    cmd = fake.calls[0]["cmd"]
    assert "--max_rows=100000" in cmd
    assert cmd[-1] == "SELECT 1"  # the sql stays the final argv element even with the flag inserted


def test_run_bq_query_honors_a_caller_supplied_timeout(monkeypatch):
    fake = _fake_run(0, "[]")
    monkeypatch.setattr(bq_json.subprocess, "run", fake)
    run_bq_query("SELECT 1", "proj", timeout=30)
    assert fake.calls[0]["timeout"] == 30

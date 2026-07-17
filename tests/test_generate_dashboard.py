"""Guard the health dashboard's bq-JSON parsing + rendering helpers (code-quality audit 2026-07).

ops/dashboard/generate_dashboard.py's q() re-implements the same bq-stdout->JSON slice pattern
that already caused production bugs in its siblings (scripts/dbt_parity.py, scripts/alert_relay.py
— see tests/test_alert_relay.py). These offline tests (no warehouse, no `bq` CLI) lock q()'s
banner-tolerant parsing, fmt_ts()'s timezone rendering/fallback, and table()'s HTML escaping.
"""
import importlib.util
import os
import subprocess
import types
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "ops", "dashboard", "generate_dashboard.py")
    spec = importlib.util.spec_from_file_location("generate_dashboard", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gd = _load()


def _fake_run(returncode, stdout, stderr=""):
    def run(cmd, capture_output=None, text=None, check=None, timeout=None):
        if check and returncode != 0:
            raise subprocess.CalledProcessError(returncode, cmd, output=stdout, stderr=stderr)
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


# ---- beat_heartbeat(): CI-vs-session note suffix (OAE-5, 2026-07-16) ----------------------

def test_beat_heartbeat_plain_note_outside_ci(monkeypatch):
    monkeypatch.delenv("GITHUB_ACTIONS", raising=False)
    captured = {}

    def _fake_run(cmd, capture_output=None, text=None, timeout=None):
        captured["cmd"] = cmd
        return types.SimpleNamespace(returncode=0, stdout="", stderr="")

    monkeypatch.setattr(gd.subprocess, "run", _fake_run)
    gd.beat_heartbeat()
    assert "index.html generated'" in captured["cmd"][-1]
    assert "(ci)" not in captured["cmd"][-1]


def test_beat_heartbeat_ci_suffixed_note_under_github_actions(monkeypatch):
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    captured = {}

    def _fake_run(cmd, capture_output=None, text=None, timeout=None):
        captured["cmd"] = cmd
        return types.SimpleNamespace(returncode=0, stdout="", stderr="")

    monkeypatch.setattr(gd.subprocess, "run", _fake_run)
    gd.beat_heartbeat()
    assert "index.html generated (ci)'" in captured["cmd"][-1]


def test_beat_heartbeat_never_raises_on_subprocess_error(monkeypatch):
    monkeypatch.setenv("GITHUB_ACTIONS", "true")

    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise OSError("bq not found")

    monkeypatch.setattr(gd.subprocess, "run", _boom)
    gd.beat_heartbeat()  # must not raise


# ---- q() bq-JSON parsing (the exact regressed bug class) ----------------------------------

def test_q_parses_banner_prefixed_json(monkeypatch):
    # bq prints a human banner before the JSON array; q() must slice from the first '['.
    monkeypatch.setattr(gd.subprocess, "run",
                        _fake_run(0, 'Welcome to BigQuery!\nUpdate available.\n[{"strategy":"A"}]'))
    assert gd.q("SELECT 1") == [{"strategy": "A"}]


def test_q_empty_when_no_array(monkeypatch):
    # No JSON array in stdout (e.g. an empty result printed as nothing) -> [], not a crash.
    monkeypatch.setattr(gd.subprocess, "run", _fake_run(0, "No rows.\n"))
    assert gd.q("SELECT 1") == []


def test_q_empty_stdout(monkeypatch):
    monkeypatch.setattr(gd.subprocess, "run", _fake_run(0, ""))
    assert gd.q("SELECT 1") == []


def test_q_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(gd.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(subprocess.CalledProcessError):
        gd.q("SELECT 1")


def test_q_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, check=None, timeout=None):
        raise gd.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)

    monkeypatch.setattr(gd.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        gd.q("SELECT 1")


# ---- fmt_ts(): timezone rendering / fallback ------------------------------------------------

def test_fmt_ts_z_suffixed_timestamp_renders_in_target_tz():
    result = gd.fmt_ts("2026-07-04T12:00:00Z", "America/Denver")
    expected_dt = datetime(2026, 7, 4, 12, 0, 0, tzinfo=timezone.utc).astimezone(ZoneInfo("America/Denver"))
    expected = expected_dt.strftime("%Y-%m-%d %H:%M") + " (America/Denver)"
    assert result == expected


def test_fmt_ts_empty_value_passthrough():
    assert gd.fmt_ts("", "America/Denver") == ""
    assert gd.fmt_ts(None, "America/Denver") is None


def test_fmt_ts_malformed_string_falls_back_to_utc_label():
    assert gd.fmt_ts("not-a-timestamp", "America/Denver") == "not-a-timestamp (UTC)"


def test_fmt_ts_space_utc_suffixed_timestamp_renders_same_as_z_suffixed():
    # bq's stringified TIMESTAMP wire form ends in " UTC", not "Z" (adversarial self-audit fix,
    # rev 2026-07-11 — the sibling scripts/alert_relay.py already stripped it; this file did not).
    z_result = gd.fmt_ts("2026-07-04T12:00:00Z", "America/Denver")
    utc_result = gd.fmt_ts("2026-07-04 12:00:00 UTC", "America/Denver")
    assert utc_result == z_result


# ---- table(): HTML escaping -----------------------------------------------------------------

def test_table_no_rows():
    assert gd.table([]) == "<p class='muted'>(no rows)</p>"


def test_table_escapes_script_and_ampersand():
    rows = [{"message": "<script>alert(1)</script>", "note": "A & B"}]
    out = gd.table(rows)
    assert "<script>alert(1)</script>" not in out
    assert "&lt;script&gt;alert(1)&lt;/script&gt;" in out
    assert "A &amp; B" in out


def test_table_renders_null_cell_as_empty_not_the_string_none():
    # r.get(c, '') only substitutes '' when the KEY is absent — a key present with a SQL NULL value
    # (r.get(c) is None) still hits the default-less branch and renders the literal text "None"
    # (adversarial self-audit fix, rev 2026-07-11).
    rows = [{"message": None, "note": "ok"}]
    out = gd.table(rows)
    assert "<td>None</td>" not in out
    assert "<td></td>" in out


# ---- main() query-failure error message (2026-07-14 audit finding: CalledProcessError's default
#      __str__ never includes bq's actual stderr, even though check=True already populated it) ----

def test_main_reports_bq_stderr_on_query_failure(monkeypatch, capsys):
    monkeypatch.setattr(gd.subprocess, "run",
                        _fake_run(1, "", "ERROR: Not found: Table perf.kill_flags"))
    assert gd.main() == 1
    assert "Not found: Table perf.kill_flags" in capsys.readouterr().err


# ---- main(): banner selection, error-return path, full-page assembly (2026-07-14 audit finding:
#      previously the module's only real branching logic had zero test coverage) -----------------

def _fake_q_all(rows_by_table):
    def fake_q(sql):
        for needle, rows in rows_by_table.items():
            if needle in sql:
                return rows
        return []
    return fake_q


def test_main_returns_1_on_query_failure(monkeypatch, capsys):
    monkeypatch.setattr(gd.subprocess, "run", _fake_run(1, "", "boom"))
    assert gd.main() == 1
    assert "Query failed" in capsys.readouterr().err


def test_main_returns_1_on_query_timeout(monkeypatch, capsys):
    def _boom(cmd, capture_output=None, text=None, check=None, timeout=None):
        raise gd.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)

    monkeypatch.setattr(gd.subprocess, "run", _boom)
    assert gd.main() == 1
    assert "timed out" in capsys.readouterr().err


def test_main_all_green_banner(monkeypatch, tmp_path):
    monkeypatch.setattr(gd, "get_user_tz", lambda: "America/Denver")
    monkeypatch.setattr(gd, "q", _fake_q_all({"state.system_health": [{"all_green": "true"}]}))
    out = tmp_path / "index.html"
    monkeypatch.setattr(gd, "OUT", str(out))
    assert gd.main() == 0
    body = out.read_text()
    assert "ALL GREEN" in body and "ATTENTION" not in body


def test_main_attention_banner_when_not_all_green(monkeypatch, tmp_path):
    monkeypatch.setattr(gd, "get_user_tz", lambda: "America/Denver")
    monkeypatch.setattr(gd, "q", _fake_q_all({"state.system_health": [{"all_green": "false"}]}))
    out = tmp_path / "index.html"
    monkeypatch.setattr(gd, "OUT", str(out))
    assert gd.main() == 0
    body = out.read_text()
    assert "ATTENTION" in body


def test_main_attention_banner_when_health_query_empty(monkeypatch, tmp_path):
    # health = [] (e.g. a rollup CROSS JOIN yielding zero rows) must fail CLOSED to ATTENTION,
    # not crash.
    monkeypatch.setattr(gd, "get_user_tz", lambda: "America/Denver")
    monkeypatch.setattr(gd, "q", _fake_q_all({}))
    out = tmp_path / "index.html"
    monkeypatch.setattr(gd, "OUT", str(out))
    assert gd.main() == 0
    assert "ATTENTION" in out.read_text()


def test_page_header_escapes_project(monkeypatch, tmp_path):
    monkeypatch.setattr(gd, "get_user_tz", lambda: "America/Denver")
    monkeypatch.setattr(gd, "q", lambda sql: [])
    monkeypatch.setattr(gd, "PROJECT", 'proj"><script>alert(1)</script>')
    out = tmp_path / "index.html"
    monkeypatch.setattr(gd, "OUT", str(out))
    gd.main()
    assert "<script>alert(1)</script>" not in out.read_text()

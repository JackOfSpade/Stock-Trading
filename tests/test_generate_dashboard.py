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
    def run(cmd, capture_output=None, text=None, check=None):
        if check and returncode != 0:
            raise subprocess.CalledProcessError(returncode, cmd, output=stdout, stderr=stderr)
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


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

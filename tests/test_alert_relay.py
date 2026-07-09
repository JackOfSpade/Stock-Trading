"""Guard the out-of-session alert/order relay's bq-JSON parsing + message formatting (2026-06-28 #8).

scripts/alert_relay.py is the off-Google-inbox alert + staged-order delivery channel (RUNBOOK §25 A2/A3).
It re-implements the SAME bq-stdout->JSON slice helper that already caused a production bug in its sibling
(scripts/dbt_parity.py, commit "parse bq JSON, not CSV — KeyError on first run"), and its main()'s broad
`except` returns 0, so a parse/format regression fails SILENTLY — alerts/orders simply stop being POSTed
with no red CI. These offline tests (no warehouse, no creds) lock the helper + the row-shape contract.
"""
import importlib.util
import os
import types

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "alert_relay.py")
    spec = importlib.util.spec_from_file_location("alert_relay", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


ar = _load()


def _fake_run(returncode, stdout, stderr=""):
    def run(cmd, capture_output=None, text=None):
        return types.SimpleNamespace(returncode=returncode, stdout=stdout, stderr=stderr)
    return run


# ---- bq() JSON-slice helper (the exact regressed bug class) -------------------------------

def test_bq_parses_banner_prefixed_json(monkeypatch):
    # bq prints a human banner before the JSON array; bq() must slice from the first '['.
    monkeypatch.setattr(ar.subprocess, "run",
                        _fake_run(0, 'Welcome to BigQuery!\nUpdate available.\n[{"severity":"critical"}]'))
    assert ar.bq("SELECT 1") == [{"severity": "critical"}]


def test_bq_empty_when_no_array(monkeypatch):
    # No JSON array in stdout (e.g. an empty result printed as nothing) -> [], not a crash.
    monkeypatch.setattr(ar.subprocess, "run", _fake_run(0, "No rows.\n"))
    assert ar.bq("SELECT 1") == []


def test_bq_raises_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(ar.subprocess, "run", _fake_run(1, "", "ERROR: access denied"))
    with pytest.raises(RuntimeError):
        ar.bq("SELECT 1")


# ---- fmt_ts(): bad-timezone fallback must never raise (ZoneInfoNotFoundError is a KeyError, not a
#      ValueError) — a bogus state.user_tz (no upstream validation from the Calendar connector) must
#      degrade to a bare "... UTC" string, never escape into main()'s outer except and drop the batch.
def test_fmt_ts_bogus_timezone_falls_back_gracefully():
    v = "2026-06-28 05:00:00 UTC"
    assert ar.fmt_ts(v, "Not/A_Real_Zone") == f"{v} UTC"


def test_fmt_ts_valid_timezone_still_formats():
    # Regression guard: the widened except must not swallow the happy path.
    out = ar.fmt_ts("2026-06-28 05:00:00 UTC", "America/Denver")
    assert "(America/Denver)" in out
    assert out != "2026-06-28 05:00:00 UTC UTC"


def test_fmt_ts_real_bigquery_wire_format():
    # The REAL `CAST(alert_ts AS STRING)` shape (verified against live BigQuery, 2026-07-09):
    # "YYYY-MM-DD HH:MM:SS[.ffffff]+00" — no literal "UTC" suffix at all. The " UTC"-suffixed
    # fixtures used elsewhere in this file are not what BigQuery actually emits; this pins the
    # real contract.
    out = ar.fmt_ts("2026-07-09 18:26:21.157141+00", "America/Denver")
    assert out == "2026-07-09 12:26 (America/Denver)"


# ---- relay_alerts() / relay_orders(): row-shape contract + no-spurious-post ----------------

def test_relay_alerts_empty_does_not_post(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_alerts()
    assert posted == []  # no alerts in window -> never POST


def test_relay_alerts_posts_and_formats(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"alert_ts": "2026-06-28 05:00:00 UTC", "severity": "critical",
         "source": "scheduled.cadence", "category": "missed_run", "message": "D2 missed"},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_alerts()
    assert len(posted) == 1
    assert "1 critical" in posted[0]
    assert "missed_run" in posted[0] and "D2 missed" in posted[0]


def test_relay_alerts_missing_column_raises_not_silent(monkeypatch):
    # A renamed/dropped column must surface (KeyError), not vanish — main() decides best-effort, not the
    # formatter. This is the regression guard: if ops.alerts columns are renamed, CI shows it.
    monkeypatch.setattr(ar, "bq", lambda sql: [{"severity": "critical"}])  # missing source/category/message/alert_ts
    monkeypatch.setattr(ar, "post", lambda text: None)
    with pytest.raises(KeyError):
        ar.relay_alerts()


def test_relay_orders_empty_does_not_post(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_orders()
    assert posted == []


def test_relay_orders_posts_and_formats(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"item_key": "k1", "strategy": "B", "ticker": "KMX", "side": "BUY",
         "qty": "10", "limit_price": "70.00", "window_close": "2026-06-30"},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_orders()
    assert len(posted) == 1
    assert "KMX" in posted[0] and "BUY" in posted[0]


def test_relay_orders_missing_column_raises_not_silent(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [{"ticker": "KMX"}])  # missing side/qty/etc.
    monkeypatch.setattr(ar, "post", lambda text: None)
    with pytest.raises(KeyError):
        ar.relay_orders()


# ---- relay_catchup(): WO-8 part 1, distinct "no-rush" notice --------------------------------

def test_relay_catchup_empty_does_not_post(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_catchup()
    assert posted == []


def test_relay_catchup_posts_and_formats(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"routine": "D1", "today": "2026-07-03"},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_catchup()
    assert len(posted) == 1
    assert "D1" in posted[0] and "safe to catch up" in posted[0]


def test_relay_catchup_missing_column_raises_not_silent(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [{"routine": "D1"}])  # missing "today"
    monkeypatch.setattr(ar, "post", lambda text: None)
    with pytest.raises(KeyError):
        ar.relay_catchup()


# ---- relay_heartbeat(): the ONE mode that must NOT swallow a POST failure ------------------

def test_relay_heartbeat_posts_once(monkeypatch):
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text) or 200)
    ar.relay_heartbeat()
    assert len(posted) == 1
    assert "heartbeat" in posted[0].lower()


def test_relay_heartbeat_propagates_post_failure(monkeypatch):
    # Unlike relay_alerts/relay_orders, a broken heartbeat webhook must raise — it is the only
    # mode guaranteed to run even when there is nothing else to say, so it is the sole mechanism
    # that can ever catch a dead channel (main()'s best-effort except only wraps alerts/orders).
    def _boom(text):
        raise OSError("connection refused")
    monkeypatch.setattr(ar, "post", _boom)
    with pytest.raises(OSError):
        ar.relay_heartbeat()


def test_main_heartbeat_mode_failure_is_not_swallowed(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "heartbeat")

    def _boom(text):
        raise OSError("connection refused")
    monkeypatch.setattr(ar, "post", _boom)
    with pytest.raises(OSError):
        ar.main()


def test_main_heartbeat_mode_success_returns_zero(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "heartbeat")
    monkeypatch.setattr(ar, "post", lambda text: 200)
    assert ar.main() == 0

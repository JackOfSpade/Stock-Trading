"""Guard the out-of-session alert/order relay's bq-JSON parsing + message formatting (2026-06-28 #8).

scripts/alert_relay.py is the off-Google-inbox alert + staged-order delivery channel (RUNBOOK §25 A2/A3).
It re-implements the SAME bq-stdout->JSON slice helper that already caused a production bug in its sibling
(scripts/dbt_parity.py, commit "parse bq JSON, not CSV — KeyError on first run"), and its main()'s broad
`except` returns 0, so a parse/format regression fails SILENTLY — alerts/orders simply stop being POSTed
with no red CI. These offline tests (no warehouse, no creds) lock the helper + the row-shape contract.
"""
import importlib.util
import json
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
    def run(cmd, capture_output=None, text=None, timeout=None):
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


# (relay_catchup + its tests RETIRED 2026-07-18 — subsumed by OPS0's autonomous catch-up
#  auto-refire, bigquery/59_catchup_autofire.sql; see scripts/alert_relay.py's module docstring.)

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


# ---- post(): ntfy.sh gets a plain-text body, everything else keeps the JSON shape (OAE-6) -------

def test_post_ntfy_url_sends_plain_text_body(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    captured = {}

    class _FakeResp:
        status = 200
        def __enter__(self):
            return self
        def __exit__(self, *a):
            return False

    def _fake_urlopen(req, timeout=None):
        captured["data"] = req.data
        captured["headers"] = dict(req.header_items())
        return _FakeResp()

    monkeypatch.setattr(ar.urllib.request, "urlopen", _fake_urlopen)
    status = ar.post("hello from the test")
    assert status == 200
    assert captured["data"] == b"hello from the test"
    assert captured["headers"]["Content-type"].startswith("text/plain")


def test_post_non_ntfy_url_still_sends_json_body(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    captured = {}

    class _FakeResp:
        status = 200
        def __enter__(self):
            return self
        def __exit__(self, *a):
            return False

    def _fake_urlopen(req, timeout=None):
        captured["data"] = req.data
        captured["headers"] = dict(req.header_items())
        return _FakeResp()

    monkeypatch.setattr(ar.urllib.request, "urlopen", _fake_urlopen)
    ar.post("hello")
    assert json.loads(captured["data"]) == {"text": "hello"}
    assert captured["headers"]["Content-type"] == "application/json"


def test_bq_raises_runtime_error_on_timeout(monkeypatch):
    def _boom(cmd, capture_output=None, text=None, timeout=None):
        raise ar.subprocess.TimeoutExpired(cmd=cmd, timeout=timeout)
    monkeypatch.setattr(ar.subprocess, "run", _boom)
    with pytest.raises(RuntimeError):
        ar.bq("SELECT 1")


# ---- main()'s "best-effort — swallow the exception, return 0" contract for alerts/orders
#      (2026-07-14 audit finding: only exercised indirectly before, never through main()) --

def test_main_alerts_mode_swallows_exception_and_returns_zero(monkeypatch, capsys):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "alerts")

    def _boom(sql):
        raise RuntimeError("bq error")
    monkeypatch.setattr(ar, "bq", _boom)
    rc = ar.main()
    assert rc == 0
    assert "relay error (non-fatal)" in capsys.readouterr().err


def test_main_orders_mode_swallows_exception_and_returns_zero(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "orders")

    def _boom(sql):
        raise RuntimeError("bq error")
    monkeypatch.setattr(ar, "bq", _boom)
    assert ar.main() == 0


def test_main_no_webhook_is_a_clean_noop(monkeypatch, capsys):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "")
    assert ar.main() == 0
    assert "clean no-op" in capsys.readouterr().out


# ---- get_user_tz(): happy path + documented "falls back to America/Denver" contract -----------
#      (the value feeds fmt_ts for every rendered alert timestamp; previously untested.)

def test_get_user_tz_happy_path(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [{"tz": "Europe/London"}])
    assert ar.get_user_tz() == "Europe/London"


def test_get_user_tz_null_value_falls_back_to_denver(monkeypatch):
    # A NULL state.user_tz.tz (row present, value None) must coalesce to Denver — returning None here
    # would make fmt_ts(v, None) raise TypeError and, via main()'s swallow, drop the whole alert batch.
    monkeypatch.setattr(ar, "bq", lambda sql: [{"tz": None}])
    assert ar.get_user_tz() == "America/Denver"


def test_get_user_tz_empty_result_falls_back_to_denver(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [])   # IndexError -> fallback
    assert ar.get_user_tz() == "America/Denver"


def test_get_user_tz_bq_error_falls_back_to_denver(monkeypatch):
    def _boom(sql):
        raise RuntimeError("bq down")
    monkeypatch.setattr(ar, "bq", _boom)
    assert ar.get_user_tz() == "America/Denver"


# ---- fmt_ts(): a None/empty tz must stay cosmetic (never raise) -------------------------------

def test_fmt_ts_none_timezone_falls_back_without_raising():
    # ZoneInfo(None) raises TypeError (neither ValueError nor ZoneInfoNotFoundError). The top-of-fn
    # `not tz_name` guard degrades it to the cosmetic "... UTC" string instead of letting it escape.
    assert ar.fmt_ts("2026-07-09 18:26:21+00", None) == "2026-07-09 18:26:21+00 UTC"


def test_fmt_ts_empty_timezone_falls_back():
    assert ar.fmt_ts("2026-07-09 18:26:21+00", "") == "2026-07-09 18:26:21+00 UTC"


def test_relay_alerts_still_posts_when_user_tz_is_null(monkeypatch):
    # End-to-end regression: a NULL state.user_tz.tz previously crashed fmt_ts (TypeError) inside
    # relay_alerts -> main()'s best-effort except swallowed it -> the alert batch silently vanished.
    def _fake_bq(sql):
        if "user_tz" in sql:
            return [{"tz": None}]
        return [{"alert_ts": "2026-07-09 18:26:21+00", "severity": "critical",
                 "source": "s", "category": "c", "message": "m"}]
    monkeypatch.setattr(ar, "bq", _fake_bq)
    posted = []
    monkeypatch.setattr(ar, "post", lambda t: posted.append(t))
    ar.relay_alerts()
    assert len(posted) == 1 and "s/c" in posted[0]   # batch delivered, not dropped

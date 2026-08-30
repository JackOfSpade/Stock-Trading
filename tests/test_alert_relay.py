"""Guard the out-of-session alert/order relay's bq-JSON parsing + message formatting (2026-06-28 #8).

scripts/alert_relay.py is the off-Google-inbox alert + staged-order delivery channel (RUNBOOK §25 A2/A3).
Its bq() delegates to lib/bq_json.py's run_bq_query (2026-07-18 dedup-sweep), the shared subprocess-
invoke/JSON-slice/returncode/timeout contract that already caused a production bug in its sibling
(scripts/dbt_parity.py, commit "parse bq JSON, not CSV — KeyError on first run"). That contract is now
proven ONCE on run_bq_query itself (tests/test_bq_json.py); this file only pins its own fixed args
(C3 dedup, 2026-07-20 audit). main()'s broad `except` returns 0, so a parse/format regression fails
SILENTLY — alerts/orders simply stop being POSTed with no red CI. These offline tests (no warehouse,
no creds) lock the row-shape contract.
"""
import json
import os
import re

import pytest

from conftest import load_module_from_path

ar = load_module_from_path("alert_relay", "scripts", "alert_relay.py")


# ---- bq(): thin delegation to lib/bq_json.run_bq_query -- pins THIS caller's fixed max_rows=1000 ---
def test_bq_delegates_to_run_bq_query_with_max_rows_1000(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project, max_rows=None):
        captured["sql"], captured["project"], captured["max_rows"] = sql, project, max_rows
        return [{"severity": "critical"}]
    monkeypatch.setattr(ar, "run_bq_query", fake_run_bq_query)
    assert ar.bq("SELECT 1") == [{"severity": "critical"}]
    assert captured == {"sql": "SELECT 1", "project": ar.PROJECT, "max_rows": 1000}


# ---- fmt_ts(): bad-timezone fallback must never raise (ZoneInfoNotFoundError is a KeyError, not a
#      ValueError) — a bogus state.user_tz (no upstream validation from the Calendar connector) must
#      degrade to a bare "... UTC" string, never escape into main()'s outer except and drop the batch.
def test_fmt_ts_bogus_timezone_falls_back_gracefully():
    v = "2026-06-28 05:00:00 UTC"
    assert ar.fmt_ts(v, "Not/A_Real_Zone") == f"{v} UTC"


# ---- WINDOW_MIN >= alerts cron interval (codebase audit 2026-07-26) -----------------------------
# The module docstring's DE-DUP paragraph now claims (correctly) at-least-once delivery with a
# bounded duplicate window, and explicitly warns that WINDOW_MIN must stay >= the alerts cron
# interval — shrinking it to match the cron exactly would reopen the "late run leaves a permanent
# hole" failure mode the margin exists to prevent. This test converts that prose claim
# into a checked invariant: it reads the REAL cron from .github/workflows/alert-relay.yml (the
# `0 */2 * * *` alerts schedule — read-only, this file does not own the workflow) so a future
# edit to either the cron or WINDOW_MIN that violates the margin fails loudly here instead of
# silently reopening the coverage gap.
def _alerts_cron_interval_minutes():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    workflow_path = os.path.join(repo_root, ".github", "workflows", "alert-relay.yml")
    with open(workflow_path) as f:
        text = f.read()
    # The alerts (best-effort backup) schedule is the only INTERVAL-style cron in this workflow
    # (the other two crons are the daily orders reminder and the weekly heartbeat, both fixed times,
    # not intervals) — match that shape rather than assuming list position. Two forms are accepted so
    # a future retune in EITHER direction stays guarded instead of failing on the regex:
    #   `*/N * * * *`  -> every N MINUTES   (the pre-2026-08-30 shape, N=30)
    #   `M */N * * *` or `M A-B/N * * *` -> every N HOURS (current: `0 */2 * * *` -> 120 min)
    m = re.search(r"cron:\s*'(?:\*|\d+(?:-\d+)?)/(\d+) \* \* \* \*'", text)
    if m:
        return int(m.group(1))
    m = re.search(r"cron:\s*'\d+ (?:\*|\d+-\d+)/(\d+) \* \* \*'", text)
    assert m, "could not find the alerts interval cron in alert-relay.yml — did its schedule change?"
    return int(m.group(1)) * 60


def test_window_min_covers_cron_interval_with_margin():
    cron_interval = _alerts_cron_interval_minutes()
    assert cron_interval == 120, "documented/assumed alerts cron interval changed — re-check the margin"
    # >= is the bare minimum (no coverage gap on an on-time run); WINDOW_MIN=130 keeps a 10-minute
    # margin on top of that, mirroring the workflow's own `gap + 10` sizing. Real scheduler lateness is much larger than 5 minutes, which is why the
    # workflow overrides RELAY_WINDOW_MIN per run from the actual gap since its last successful run —
    # this module default is the floor for an override-less (local/manual) invocation. Either
    # regressing WINDOW_MIN below the cron interval, or widening the cron interval past WINDOW_MIN,
    # reopens the missed-alert hole this test guards.
    assert ar.WINDOW_MIN >= cron_interval


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
         "qty": "10", "limit_price": "70.00", "window_close": "2026-06-30", "instruction_id": None},
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


# ---- relay_orders(): craftability-aware wording (2026-07-20 fix — see scripts/alert_relay.py
#      relay_orders' docstring). A craftable order (instruction_id set) never gets a
#      `[Claude] Confirm order` calendar event by design (2026-07-09 policy) — telling the operator
#      to tap one that doesn't exist is misleading, especially on a row already confirmed via IBKR's
#      own notification days ago and just resting unfilled. Only a non-craftable/manual-entry row
#      (instruction_id NULL) actually has that calendar event.

def test_relay_orders_craftable_row_does_not_mention_calendar_event(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"item_key": "entry-TSM-D-20260717", "strategy": "D", "ticker": "TSM", "side": "BUY",
         "qty": "0.0946", "limit_price": "399.3", "window_close": "2026-07-24", "instruction_id": "100"},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_orders()
    assert "[Claude] Confirm order" not in posted[0]
    assert "IBKR's own order notification" in posted[0]


def test_relay_orders_manual_entry_row_still_mentions_calendar_event(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"item_key": "k2", "strategy": "B", "ticker": "SPX 260918C05500000", "side": "BUY",
         "qty": "1", "limit_price": "12.50", "window_close": "2026-07-30", "instruction_id": None},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_orders()
    assert "tap the [Claude] Confirm order event" in posted[0]


def test_relay_orders_mixed_rows_annotate_independently(monkeypatch):
    monkeypatch.setattr(ar, "bq", lambda sql: [
        {"item_key": "k1", "strategy": "D", "ticker": "ISRG", "side": "BUY", "qty": "0.1091",
         "limit_price": "346.3", "window_close": "2026-07-24", "instruction_id": "101"},
        {"item_key": "k2", "strategy": "B", "ticker": "MANUAL", "side": "SELL", "qty": "1",
         "limit_price": "10.00", "window_close": "2026-07-24", "instruction_id": None},
    ])
    posted = []
    monkeypatch.setattr(ar, "post", lambda text: posted.append(text))
    ar.relay_orders()
    lines = posted[0].splitlines()
    isrg_line = next(line for line in lines if "ISRG" in line)
    manual_line = next(line for line in lines if "MANUAL" in line)
    assert "IBKR's own order notification" in isrg_line
    assert "tap the [Claude] Confirm order event" in manual_line


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

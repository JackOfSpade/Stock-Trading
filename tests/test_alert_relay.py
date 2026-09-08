"""Guard the out-of-session alert/order relay's bq-JSON parsing + message formatting (2026-06-28 #8).

scripts/alert_relay.py is the off-Google-inbox ops.alerts delivery channel (RUNBOOK §25 A2).
Its bq() delegates to lib/bq_json.py's run_bq_query (2026-07-18 dedup-sweep), the shared subprocess-
invoke/JSON-slice/returncode/timeout contract that already caused a production bug in its sibling
(scripts/dbt_parity.py, commit "parse bq JSON, not CSV — KeyError on first run"). That contract is now
proven ONCE on run_bq_query itself (tests/test_bq_json.py); this file only pins its own fixed args
(C3 dedup, 2026-07-20 audit). main()'s broad `except` returns 0, so a parse/format regression fails
SILENTLY — alerts simply stop being POSTed with no red CI. These offline tests (no warehouse,
no creds) lock the row-shape contract.

Also pins the two 2026-09-07 owner-directed delivery rules the module enforces (see its docstring):
RULE 1 every push has an email counterpart, RULE 2 ntfy is for action-needed only. Both are one-line
code changes to undo and neither has any runtime signal when broken — a suppressed push is invisible
and an email-less push looks identical to one with email — so the tests below are the only thing
standing between a well-meaning future edit and a silently re-broken channel.
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
    # (the only other cron is the weekly heartbeat, a fixed time, not an interval; the daily orders
    # reminder was retired 2026-09-07) — match that shape rather than assuming list position. Two forms
    # are accepted so
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
    # margin on top of that. That is the module-level FLOOR only — the workflow's own per-run sizing
    # is `gap + 130`: a full alerts interval (120 min) plus 10 min slack, NOT a flat `gap + 10`
    # (2026-08-30 revision — see scripts/alert_relay.py's DE-DUP paragraph and alert-relay.yml's
    # "Size the alerts lookback window" step; brute-forced over independent per-run delays, margin=10
    # left an 80-min PERMANENT hole and margin=130 leaves zero). Real scheduler lateness far exceeds
    # the 10-minute margin, which is why the workflow overrides RELAY_WINDOW_MIN per run from the
    # actual gap since its last successful run — this module default is the floor for an
    # override-less (local/manual) invocation. Either regressing WINDOW_MIN below the cron interval,
    # or widening the cron interval past WINDOW_MIN, reopens the missed-alert hole this test guards.
    # (Corrected 2026-09-04: this comment claimed the workflow mirrored a `gap + 10` sizing and cited
    # a "5 minute" lateness figure — both left over from the pre-retune `*/30` cron + WINDOW_MIN=35
    # era, and `gap + 10` is exactly the margin the 2026-08-30 retune REVERTED. Commit 23307d4 moved
    # the values and the cron regex in this file but not this prose.)
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


# ---- relay_alerts(): row-shape contract + no-spurious-post ---------------------------------

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


# ---- relay_heartbeat(): the ONE mode that must NOT swallow a POST failure ------------------

def test_relay_heartbeat_posts_once(monkeypatch):
    posted = []
    monkeypatch.setattr(ar, "post", lambda text, silent=False: posted.append(text) or 200)
    ar.relay_heartbeat()
    assert len(posted) == 1
    # Wording changed 2026-09-07 ("heartbeat" -> "liveness probe") when the canary went silent;
    # what this pins is that exactly ONE post happens and that its text identifies the channel it
    # is probing, so a maintainer hand-inspecting the ntfy topic can tell what the message is.
    assert "alert-relay" in posted[0].lower()
    assert "liveness probe" in posted[0].lower()


def test_relay_heartbeat_propagates_post_failure(monkeypatch):
    # Unlike relay_alerts, a broken heartbeat webhook must raise — it is the only
    # mode guaranteed to run even when there is nothing else to say, so it is the sole mechanism
    # that can ever catch a dead channel (main()'s best-effort except only wraps alerts).
    def _boom(text, silent=False):
        raise OSError("connection refused")
    monkeypatch.setattr(ar, "post", _boom)
    with pytest.raises(OSError):
        ar.relay_heartbeat()


def test_main_heartbeat_mode_failure_is_not_swallowed(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "heartbeat")

    def _boom(text, silent=False):
        raise OSError("connection refused")
    monkeypatch.setattr(ar, "post", _boom)
    with pytest.raises(OSError):
        ar.main()


def test_main_heartbeat_mode_success_returns_zero(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    monkeypatch.setattr(ar, "MODE", "heartbeat")
    monkeypatch.setattr(ar, "post", lambda text, silent=False: 200)
    assert ar.main() == 0


# ---- post(): ntfy.sh gets a plain-text body, everything else keeps the JSON shape (OAE-6) -------

# DEDUP FIX (2026-08-31 code-quality pass): the two tests below each used to define their own
# byte-identical local `_FakeResp` class + `_fake_urlopen` closure. Hoisted to module level, one
# definition reused by both -- mirroring tests/test_golden_scenarios_runner.py's module-level
# `_FakeResp`, which solves this same "fake the urlopen() response" problem the same way.
class _FakeResp:
    status = 200
    def __enter__(self):
        return self
    def __exit__(self, *a):
        return False


def _capturing_urlopen(captured):
    def _fake_urlopen(req, timeout=None):
        captured["data"] = req.data
        captured["headers"] = dict(req.header_items())
        return _FakeResp()
    return _fake_urlopen


def test_post_ntfy_url_sends_plain_text_body(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    captured = {}
    monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
    status = ar.post("hello from the test")
    assert status == 200
    assert captured["data"] == b"hello from the test"
    assert captured["headers"]["Content-type"].startswith("text/plain")


def test_post_non_ntfy_url_still_sends_json_body(monkeypatch):
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    captured = {}
    monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
    ar.post("hello")
    assert json.loads(captured["data"]) == {"text": "hello"}
    assert captured["headers"]["Content-type"] == "application/json"


# ---- main()'s "best-effort — swallow the exception, return 0" contract for alerts
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


# ---- 2026-09-07 owner directive: RULE 1 (every push has an email counterpart) and
#      RULE 2 (ntfy is for action-needed only). See scripts/alert_relay.py's module docstring.
#      Both rules are enforced only by code that is easy to "simplify" away and produces NO runtime
#      signal when broken — a suppressed push is indistinguishable from a quiet week, and an
#      email-less push looks exactly like one with email. These tests are the entire guard.

def test_orders_mode_is_retired_and_never_posts(monkeypatch, capsys):
    # RULE 1. The `orders` mode read state.open_orders — a view NO email channel queries — so it was
    # the one push in the system with no email counterpart. It is retired; the fact is now raised as
    # the staged_order_awaiting_confirm ops.alerts row by bigquery/229, which reaches email AND ntfy.
    # Pinned as an explicit no-op rather than deleted-and-forgotten because a stale dispatch, an old
    # re-run, or a leftover cron would otherwise fall through to relay_alerts() and silently relay
    # ALERTS while reporting itself as "orders".
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    monkeypatch.setattr(ar, "MODE", "orders")
    posted = []
    monkeypatch.setattr(ar, "post", lambda *a, **k: posted.append(a) or 200)
    # bq must never be reached either — the retired mode does no warehouse work at all.
    monkeypatch.setattr(ar, "bq", lambda sql: pytest.fail("retired orders mode queried BigQuery"))
    assert ar.main() == 0
    assert posted == [], "retired orders mode must not POST anything"
    assert "RETIRED" in capsys.readouterr().out


def test_relay_orders_function_is_gone():
    # The mode is retired at BOTH layers. Leaving the function behind would invite a future edit to
    # re-wire it (re-breaking RULE 1) without touching the workflow or the docstring that explain why
    # it must not exist.
    assert not hasattr(ar, "relay_orders")


def test_alerts_query_excludes_every_no_push_category(monkeypatch):
    # RULE 2. The six SISA roster-change notices are completed, healthy, fully-autonomous actions that
    # need no operator action; alert_emailer.gs already renders them in a non-fault lane. They must be
    # filtered OUT of the push — and, critically, filtered in the QUERY, so the exclusion is visible
    # in one place rather than smeared across the formatting code.
    seen = {}

    def _bq(sql):
        seen["sql"] = sql
        return []
    monkeypatch.setattr(ar, "bq", _bq)
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    sql = seen["sql"]
    assert "category NOT IN (" in sql
    for cat in ar.NO_PUSH_CATEGORIES:
        assert f"'{cat}'" in sql, f"{cat} is in NO_PUSH_CATEGORIES but absent from the relay query"


def test_alerts_query_excludes_every_email_only_category(monkeypatch):
    # 2026-09-08, bigquery/230_run_outcome_notification.sql / spec P5 (C4). 'routine_run_warning' is
    # EMAIL ONLY: the run completed, nothing is blocked, so it must be filtered out of the push while
    # (per test_no_push_categories_does_not_touch_severity_or_resolved_filter's reasoning, which
    # applies identically here) staying unresolved and still emailed. Mirrors
    # test_alerts_query_excludes_every_no_push_category for the second suppression tuple.
    seen = {}

    def _bq(sql):
        seen["sql"] = sql
        return []
    monkeypatch.setattr(ar, "bq", _bq)
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    sql = seen["sql"]
    assert "category NOT IN (" in sql
    for cat in ar.EMAIL_ONLY_CATEGORIES:
        assert f"'{cat}'" in sql, f"{cat} is in EMAIL_ONLY_CATEGORIES but absent from the relay query"


def test_routine_run_failed_and_run_log_problem_unalerted_still_push(monkeypatch):
    # The other two categories bigquery/230 introduces are NOT suppressed — they denote a state the
    # owner may need to act on (a run that did not complete; the notification path itself dropping
    # something) and must keep reaching the phone. Pinned as an explicit negative so a future reflexive
    # "add the new run-outcome categories to the suppression list" edit fails a test instead of
    # silently going unpushed.
    seen = {}
    monkeypatch.setattr(ar, "bq", lambda sql: seen.setdefault("sql", sql) and [] or [])
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    sql = seen["sql"]
    assert "'routine_run_failed'" not in sql
    assert "'run_log_problem_unalerted'" not in sql
    assert "routine_run_failed" not in ar.NO_PUSH_CATEGORIES and "routine_run_failed" not in ar.EMAIL_ONLY_CATEGORIES
    assert ("run_log_problem_unalerted" not in ar.NO_PUSH_CATEGORIES
            and "run_log_problem_unalerted" not in ar.EMAIL_ONLY_CATEGORIES)


def test_no_push_categories_does_not_touch_severity_or_resolved_filter(monkeypatch):
    # The suppression is a CHANNEL filter and nothing else. It must never become a severity change or
    # a resolve — the rows stay unresolved criticals/warnings on the alert board, still emailed, still
    # counted by every state.* view and trading gate that reads ops.alerts. Silencing a verifier by
    # editing its input is the failure mode this pins against.
    seen = {}
    monkeypatch.setattr(ar, "bq", lambda sql: seen.setdefault("sql", sql) and [] or [])
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    sql = seen["sql"]
    assert "NOT resolved" in sql
    assert "severity IN ('critical','warning')" in sql


def test_no_push_categories_matches_alert_emailer_roster_lane():
    # Four-place lockstep, checked here too (not only by scripts/check_roster_notice_lockstep.py) so a
    # drift fails in the ordinary pytest run a developer actually watches, not just in the dedicated
    # guard step.
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    gs = open(os.path.join(repo_root, "ops", "monitoring", "alert_emailer.gs")).read()
    block = re.search(r"ROSTER_NOTICE_CATEGORIES\s*=\s*\[(.*?)\]", gs, re.DOTALL)
    assert block, "could not find ROSTER_NOTICE_CATEGORIES in alert_emailer.gs"
    emailer = set(re.findall(r"'([a-z0-9_]+)'", block.group(1)))
    assert set(ar.NO_PUSH_CATEGORIES) == emailer


def test_relay_heartbeat_publishes_silently(monkeypatch):
    # RULE 2, the literal all-clear case: this was a weekly "✓ channel alive, no action needed" buzz.
    # It must still POST (that round-trip is the entire liveness proof) but must not notify.
    calls = []
    monkeypatch.setattr(ar, "post", lambda text, silent=False: calls.append((text, silent)) or 200)
    ar.relay_heartbeat()
    assert len(calls) == 1
    text, silent = calls[0]
    assert silent is True, "the weekly canary must publish silently"
    assert "no action needed" in text.lower()


def test_post_silent_sets_every_ntfy_suppression_header(monkeypatch):
    # All three headers were probed live against ntfy.sh (2026-09-07) before being used. Priority:min
    # is the documented "no vibration or sound, under the fold" level; Cache:no keeps the canary out of
    # topic history (verified by a follow-up poll returning nothing); Firebase:no keeps it off the FCM
    # Android delivery path.
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    captured = {}
    monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
    ar.post("canary", silent=True)
    h = captured["headers"]
    assert h.get("Priority") == "min"
    assert h.get("Cache") == "no"
    assert h.get("Firebase") == "no"
    assert h.get("Tags") == "heartbeat"


def test_post_default_is_loud_so_a_real_alert_still_notifies(monkeypatch):
    # The inverse guard, and the one that actually matters for safety: `silent` must default to False
    # so a drawdown-kill or missed-run alert can never inherit the canary's min priority. A regression
    # here would be invisible — the POST still returns 200 and CI stays green while the phone goes
    # quiet for real alerts.
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    captured = {}
    monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
    ar.post("a real alert")
    h = captured["headers"]
    assert "Priority" not in h
    assert "Cache" not in h
    assert "Firebase" not in h


def test_post_never_sends_an_email_header(monkeypatch):
    # ntfy.sh REJECTS the Email: forwarding header on this anonymous capability-URL topic — probed
    # live 2026-09-07: HTTP 400 {"code":40053,"error":"anonymous email sending is not allowed"}. A
    # future attempt to satisfy RULE 1 by adding it here would not merely fail to send mail, it would
    # 400 the POST and take the whole push channel (and the liveness canary with it) permanently red.
    # Email parity comes from ops.alerts -> alert_emailer.gs instead.
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://ntfy.sh/stock-trading-testtopic")
    for silent in (False, True):
        captured = {}
        monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
        ar.post("x", silent=silent)
        assert not any(k.lower() in ("email", "e-mail", "mail") for k in captured["headers"])


def test_silent_headers_are_ntfy_only_and_never_reach_a_generic_webhook(monkeypatch):
    # A Slack/Discord/Pub-Sub endpoint has no notion of these headers; the JSON shape must stay
    # byte-identical to what it has always been so a non-ntfy destination is unaffected by RULE 2.
    monkeypatch.setattr(ar, "WEBHOOK_URL", "https://example.invalid/hook")
    captured = {}
    monkeypatch.setattr(ar.urllib.request, "urlopen", _capturing_urlopen(captured))
    ar.post("hello", silent=True)
    assert json.loads(captured["data"]) == {"text": "hello"}
    assert captured["headers"]["Content-type"] == "application/json"
    assert "Priority" not in captured["headers"]


def test_suppression_clause_is_null_safe(monkeypatch):
    # ops.alerts.category is nullable, and `NULL NOT IN (...)` evaluates to NULL, which WHERE treats
    # as false — so a bare NOT IN would silently drop a NULL-category alert from the PUSH while it is
    # still emailed. COALESCE(..., TRUE) points the unknown case at delivery. Suppression must be
    # provably TRUE, never merely not-provably-false.
    seen = {}
    monkeypatch.setattr(ar, "bq", lambda sql: seen.setdefault("sql", sql) and [] or [])
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    assert "COALESCE(category NOT IN (" in seen["sql"]
    assert "), TRUE)" in seen["sql"]


def test_empty_no_push_tuple_degrades_to_no_filter_not_a_syntax_error(monkeypatch):
    # `category NOT IN ()` is a BigQuery SYNTAX ERROR, not an empty filter — and relay_alerts() runs
    # inside main()'s best-effort except, so the failure would NOT go red. It would silently stop the
    # ENTIRE alerts push (criticals included) forever, leaving one stderr line as the only evidence.
    # An emptied list must degrade to "push everything".
    #
    # BOTH suppression tuples are patched empty here (2026-09-08, EMAIL_ONLY_CATEGORIES added
    # alongside NO_PUSH_CATEGORIES): relay_alerts() builds ONE combined set from
    # NO_PUSH_CATEGORIES + EMAIL_ONLY_CATEGORIES, so emptying only NO_PUSH_CATEGORIES no longer
    # empties the combined set — EMAIL_ONLY_CATEGORIES's 'routine_run_warning' alone would still make
    # `suppressed_categories` non-empty and this test would stop exercising the guard it exists to
    # pin. See test_no_push_categories_alone_going_empty_does_not_empty_combined_set below for the
    # complementary case (one tuple emptied, the other not) that this note warns about.
    seen = {}
    monkeypatch.setattr(ar, "NO_PUSH_CATEGORIES", ())
    monkeypatch.setattr(ar, "EMAIL_ONLY_CATEGORIES", ())
    monkeypatch.setattr(ar, "bq", lambda sql: seen.setdefault("sql", sql) and [] or [])
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    assert "NOT IN ()" not in seen["sql"]
    assert "category NOT IN" not in seen["sql"]
    # the rest of the query must still be intact and well-formed
    assert "NOT resolved" in seen["sql"]
    assert "severity IN ('critical','warning')" in seen["sql"]


def test_no_push_categories_alone_going_empty_does_not_empty_combined_set(monkeypatch):
    # The complementary case to the test above, and the one the spec explicitly calls out: patching
    # only ONE of the two suppression tuples to empty must NOT trip the empty-tuple guard, because the
    # combined set is still non-empty. If this regressed to "any single tuple going empty degrades to
    # no filter", a future incident that zeroes out NO_PUSH_CATEGORIES alone (e.g. a bad roster-notice
    # sweep) would silently ALSO stop suppressing routine_run_warning from the push — the opposite of
    # what RULE 2 requires, and invisible until the phone starts buzzing for a category the owner was
    # told stays email-only.
    seen = {}
    monkeypatch.setattr(ar, "NO_PUSH_CATEGORIES", ())
    monkeypatch.setattr(ar, "bq", lambda sql: seen.setdefault("sql", sql) and [] or [])
    monkeypatch.setattr(ar, "get_user_tz", lambda: "America/Denver")
    ar.relay_alerts()
    sql = seen["sql"]
    assert "category NOT IN (" in sql, "combined set must still be non-empty and filtered"
    assert "'routine_run_warning'" in sql

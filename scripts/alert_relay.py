#!/usr/bin/env python3
"""Out-of-session alert / staged-order relay to a vendor-neutral webhook (stack review 2026-06-24).

WHY (RUNBOOK §25 A1/A2/A3). Alert DELIVERY today funnels into one Gmail inbox on one Google account
(the DTS failure-emails + both Apps Scripts), and the two Apps Scripts live ONLY in script.google.com
(un-versioned). This relay is a version-controlled, scheduled GitHub Action that reads BigQuery via the
EXISTING read-only WIF SA (gh-ci-runner@, no new grant) and POSTs to a webhook whose failure mode is
uncorrelated with the owner's Google account. It COMPLEMENTS — does not replace — the alert_emailer
(the reliable ~2h-poll, de-duped channel) and the DTS failure-email (the identity-independent channel
for a dead emailer). This relay is the FAST, BEST-EFFORT channel.

DE-DUP is stateless: alerts mode posts only ops.alerts raised in the last RELAY_WINDOW_MIN minutes
(≈ the cron interval), so a given alert is posted at most once. A skipped run is backstopped by the
2h emailer, so no durable cursor is needed (which keeps this read-only — no notified_ts write).

Modes (env RELAY_MODE):
  * alerts    — recent unresolved critical/warning ops.alerts rows (default).
  * orders    — pending staged orders (state.open_orders): the A3 same-day confirm reminder, run once
                daily so a silenced 07:00 calendar alarm is not the ONLY notice of an order to confirm.
  * heartbeat — weekly liveness canary (self-improvement audit 2026-07-03, guard-config-audit companion).
                alerts/orders are best-effort BY DESIGN (main() swallows a POST failure so a transient
                webhook hiccup never adds CI noise on top of the reliable emailer) — but that same design
                means a permanently DEAD webhook (revoked, URL typo'd, endpoint decommissioned) would
                never surface: it only has to fire when there happens to be an alert or a staged order.
                heartbeat is the one mode that does NOT swallow the POST failure, specifically so a dead
                diversification channel is caught by its own weekly run rather than discovered the day a
                real alert silently fails to arrive.
  (RETIRED 2026-07-18: `catchup` — the daily "no-rush, fire the trigger yourself" notice over
  state.catchup_available (WO-8 part 1, 2026-07-03). OPS0's autonomous catch-up auto-refire
  (bigquery/59_catchup_autofire.sql + Claude_Task_Plan.md OPS0, 2026-07-15) reads the same underlying
  signal and fires the trigger ITSELF via RemoteTrigger on the identical catchup-safe set, in the same
  04:30 UTC slot — asking a human to do it manually became duplicate noise. The one residual case that
  DOES need a human (no live trigger id) already alerts via bigquery/59's catchup_refire_no_trigger_id
  warning through the standard ops.alerts -> relay_alerts path.)

Env: WEBHOOK_URL (required — else clean no-op), RELAY_MODE, RELAY_WINDOW_MIN (default 35),
     BQ_PROJECT (default stock-trading-498512). Stdlib only.
"""
import json
import os
import subprocess  # noqa: F401 — kept so tests can monkeypatch subprocess.run/TimeoutExpired at the module level
import sys
import urllib.request
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
except ImportError:  # pragma: no cover — stdlib since 3.9; CI/runners pin >=3.9
    ZoneInfo = None
    ZoneInfoNotFoundError = KeyError

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import run_bq_query

PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
MODE = os.environ.get("RELAY_MODE", "alerts")
WINDOW_MIN = int(os.environ.get("RELAY_WINDOW_MIN", "35"))
WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "").strip()


def bq(sql):
    # 600s timeout: a stalled bq CLI call (network partition / hung query poll) would otherwise
    # block this job indefinitely, and this relay's `concurrency: cancel-in-progress: false`
    # setting means a hung run also queues (blocks) every subsequent scheduled trigger for hours
    # (2026-07-14 audit finding). Delegates to lib/bq_json.py's run_bq_query — the shared invoke
    # wrapper this module's copy was consolidated into (2026-07-18 dedup-sweep audit).
    return run_bq_query(sql, PROJECT, max_rows=1000)


def get_user_tz():
    """Detected DISPLAY timezone (state.user_tz — bigquery/20_user_prefs.sql). Cosmetic only — never
    fails the relay: any error (including a monkeypatched `bq` returning an unrelated row shape in
    tests) falls back to America/Denver silently.

    The `or "America/Denver"` coalesce makes the documented fallback hold for a NULL/empty tz value
    too, not just for an exception. state.user_tz already COALESCEs NULL -> 'America/Denver' at the
    view, so this is defense-in-depth — but without it a NULL tz would return None, and fmt_ts(v, None)
    raises TypeError (ZoneInfo(None)), which is neither ValueError nor ZoneInfoNotFoundError, so it
    escapes fmt_ts's cosmetic-fallback and — via main()'s outer `except Exception` — silently drops the
    whole alert batch. Returning a real tz string here keeps a bad/absent tz strictly cosmetic."""
    try:
        rows = bq(f"SELECT tz FROM `{PROJECT}.state.user_tz`")
        return rows[0]["tz"] or "America/Denver"
    except Exception:
        return "America/Denver"


def fmt_ts(v, tz_name):
    """Render a BigQuery `CAST(alert_ts AS STRING)` value in tz_name, labeled — previously always
    rendered as a bare "... UTC" string regardless of where the operator actually is.

    Real wire format (verified against live BigQuery, 2026-07-09): "YYYY-MM-DD HH:MM:SS[.ffffff]+00"
    — it never contains the literal string "UTC". The `endswith(" UTC")` strip below is harmless
    defense-in-depth (e.g. hand-constructed test fixtures or a future BigQuery format change), not a
    reflection of what CAST(... AS STRING) actually emits today."""
    # `not tz_name` guards a None/empty tz: ZoneInfo(None) raises TypeError (not caught below), which
    # would escape into main()'s outer `except Exception` and drop the whole batch — exactly what this
    # function's contract forbids. get_user_tz() already coalesces to a real tz, so this is belt-and-
    # suspenders; for tz_name == "" it returns the same "... UTC" string the except-branch would.
    if not v or not tz_name or ZoneInfo is None:
        return f"{v} UTC"
    try:
        s = str(v).strip()
        if s.endswith(" UTC"):
            s = s[:-4]
        dt = datetime.fromisoformat(s.replace(" ", "T", 1)).replace(tzinfo=timezone.utc)
        return dt.astimezone(ZoneInfo(tz_name)).strftime("%Y-%m-%d %H:%M") + f" ({tz_name})"
    except (ValueError, ZoneInfoNotFoundError):
        # ZoneInfoNotFoundError (a KeyError subclass, NOT a ValueError) is raised by ZoneInfo(tz_name)
        # for a bad/unsupported IANA tz string — e.g. state.user_tz populated from the Google Calendar
        # connector with no upstream validation. tz problems are cosmetic only (get_user_tz()'s own
        # contract) — never let one raise uncaught and drop the whole alert batch (main()'s outer
        # `except Exception` would otherwise be the only thing stopping it).
        return f"{v} UTC"


def post(text):
    """POST the alert text. Two shapes, branched on the destination:
      * ntfy.sh (OAE-6, 2026-07-16 self-provisioned second channel — see RUNBOOK §25 A2/A3): ntfy
        renders the raw request BODY as the push message, so a JSON-wrapped body would show up as a
        literal '{"text": "..."}' string on the phone — send the plain text instead, with the ntfy
        `Title` header for a readable notification title.
      * everything else (Slack/Discord/mattermost incoming webhooks, a generic Pub/Sub-push proxy):
        {text: ...} JSON, unchanged.
    Never raises into CI noise on a transient webhook error (callers decide best-effort vs. not —
    see relay_heartbeat's docstring)."""
    if "ntfy.sh" in WEBHOOK_URL:
        req = urllib.request.Request(WEBHOOK_URL, data=text.encode("utf-8"),
                                     headers={"Title": "Stock-Trading",
                                              "Content-Type": "text/plain; charset=utf-8"})
    else:
        body = json.dumps({"text": text}).encode("utf-8")
        req = urllib.request.Request(WEBHOOK_URL, data=body,
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.status


def relay_alerts():
    tz = get_user_tz()
    rows = bq(f"""
        SELECT CAST(alert_ts AS STRING) AS alert_ts, severity, source, category, message
        FROM `{PROJECT}.ops.alerts`
        WHERE NOT resolved AND severity IN ('critical','warning')
          AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {WINDOW_MIN} MINUTE)
        ORDER BY alert_ts DESC
    """)
    if not rows:
        print("alerts: none in window")
        return
    crit = sum(1 for r in rows if r["severity"] == "critical")
    lines = [f"⚠ Stock-Trading — {len(rows)} new alert(s){f' ({crit} critical)' if crit else ''}:"]
    for r in rows:
        lines.append(f"[{r['severity'].upper()}] {r['source']}/{r['category']}: {r['message']} ({fmt_ts(r['alert_ts'], tz)})")
    post("\n".join(lines))
    print(f"alerts: posted {len(rows)}")


def relay_orders():
    # entry_window_close is a DATE (state.open_orders — bigquery/01_schema.sql queue_events.due_date),
    # not a TIMESTAMP, so it has no time-of-day/timezone component to render — "2026-06-30" is
    # unambiguous regardless of where the operator is. No tz conversion needed here.
    rows = bq(f"""
        SELECT item_key, strategy, ticker, side, CAST(qty AS STRING) AS qty,
               CAST(limit_price AS STRING) AS limit_price, CAST(entry_window_close AS STRING) AS window_close
        FROM `{PROJECT}.state.open_orders`
        ORDER BY ticker
    """)
    if not rows:
        print("orders: none pending")
        return
    lines = [f"☑ Stock-Trading — {len(rows)} staged order(s) awaiting confirmation (tap the [Claude] Confirm order event):"]
    for r in rows:
        lines.append(f"{r['side']} {r['qty']} {r['ticker']} ({r['strategy']}) @ {r['limit_price']} — window to {r['window_close']}")
    post("\n".join(lines))
    print(f"orders: posted {len(rows)}")


def relay_heartbeat():
    """Weekly canary POST. Deliberately NOT wrapped in the best-effort try/except main() uses for
    alerts/orders — here a POST failure IS the finding (channel diversity is only real if the second
    channel is actually alive), so it must propagate to a non-zero exit / red CI run."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    status = post(f"✓ Stock-Trading alert-relay heartbeat — channel alive, no action needed ({now}).")
    print(f"heartbeat: posted (HTTP {status})")


def main():
    if not WEBHOOK_URL:
        print("WEBHOOK_URL not set — relay is a clean no-op.")
        return 0
    if MODE == "heartbeat":
        relay_heartbeat()
        return 0
    try:
        if MODE == "orders":
            relay_orders()
        else:
            relay_alerts()
    except Exception as e:  # best-effort: never fail CI on a transient bq/webhook hiccup
        print(f"relay error (non-fatal): {e}", file=sys.stderr)
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

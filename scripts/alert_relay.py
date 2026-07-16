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
  * catchup   — daily "no-rush" notice (self-improvement audit WO-8 part 1, 2026-07-03) for
                state.catchup_available: routines that missed today's cadence deadline but carry no
                intraday-price dependency (currently D1/D3 only — see bigquery/31_catchup_notify.sql),
                so firing the trigger late recovers full same-day value. Deliberately worded and delivered
                separately from the existing missed_run CRITICAL (relay_alerts, via ops.alerts) — that one
                still fires for every miss including D2, where a late catch-up does NOT recover full value;
                conflating the two would wrongly tell the operator "no rush" about a D2 miss too.

Env: WEBHOOK_URL (required — else clean no-op), RELAY_MODE, RELAY_WINDOW_MIN (default 35),
     BQ_PROJECT (default stock-trading-498512). Stdlib only.
"""
import json
import os
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
except ImportError:  # pragma: no cover — stdlib since 3.9; CI/runners pin >=3.9
    ZoneInfo = None
    ZoneInfoNotFoundError = KeyError

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import parse_bq_json_stdout

PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
MODE = os.environ.get("RELAY_MODE", "alerts")
WINDOW_MIN = int(os.environ.get("RELAY_WINDOW_MIN", "35"))
WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "").strip()


def bq(sql):
    # 600s timeout: a stalled bq CLI call (network partition / hung query poll) would otherwise
    # block this job indefinitely, and this relay's `concurrency: cancel-in-progress: false`
    # setting means a hung run also queues (blocks) every subsequent scheduled trigger for hours
    # (2026-07-14 audit finding).
    try:
        out = subprocess.run(
            ["bq", "--project_id=" + PROJECT, "--quiet", "--headless", "--format=json",
             "query", "--use_legacy_sql=false", "--max_rows=1000", sql],
            capture_output=True, text=True, timeout=600,
        )
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s: {sql[:120]}") from e
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return parse_bq_json_stdout(out.stdout)


def get_user_tz():
    """Detected DISPLAY timezone (state.user_tz — bigquery/20_user_prefs.sql). Cosmetic only — never
    fails the relay: any error (including a monkeypatched `bq` returning an unrelated row shape in
    tests) falls back to America/Denver silently."""
    try:
        rows = bq(f"SELECT tz FROM `{PROJECT}.state.user_tz`")
        return rows[0]["tz"]
    except Exception:
        return "America/Denver"


def fmt_ts(v, tz_name):
    """Render a BigQuery `CAST(alert_ts AS STRING)` value in tz_name, labeled — previously always
    rendered as a bare "... UTC" string regardless of where the operator actually is.

    Real wire format (verified against live BigQuery, 2026-07-09): "YYYY-MM-DD HH:MM:SS[.ffffff]+00"
    — it never contains the literal string "UTC". The `endswith(" UTC")` strip below is harmless
    defense-in-depth (e.g. hand-constructed test fixtures or a future BigQuery format change), not a
    reflection of what CAST(... AS STRING) actually emits today."""
    if not v or ZoneInfo is None:
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


def relay_catchup():
    """Daily "no-rush" notice for state.catchup_available (WO-8 part 1) — best-effort like
    relay_alerts/relay_orders (a transient bq/webhook hiccup here should not fail CI; the existing
    missed_run CRITICAL via relay_alerts already covers the underlying miss regardless)."""
    rows = bq(f"""
        SELECT routine, CAST(today AS STRING) AS today
        FROM `{PROJECT}.state.catchup_available`
    """)
    if not rows:
        print("catchup: none available")
        return
    lines = [f"↻ Stock-Trading — {len(rows)} routine(s) missed today's window but are safe to catch up now (no live-price dependency):"]
    for r in rows:
        lines.append(f"{r['routine']} ({r['today']}) — fire its trigger whenever convenient; a late run recovers full value.")
    post("\n".join(lines))
    print(f"catchup: posted {len(rows)}")


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
        elif MODE == "catchup":
            relay_catchup()
        else:
            relay_alerts()
    except Exception as e:  # best-effort: never fail CI on a transient bq/webhook hiccup
        print(f"relay error (non-fatal): {e}", file=sys.stderr)
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

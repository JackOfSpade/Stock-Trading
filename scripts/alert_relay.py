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
  * alerts  — recent unresolved critical/warning ops.alerts rows (default).
  * orders  — pending staged orders (state.open_orders): the A3 same-day confirm reminder, run once
              daily so a silenced 07:00 calendar alarm is not the ONLY notice of an order to confirm.

Env: WEBHOOK_URL (required — else clean no-op), RELAY_MODE, RELAY_WINDOW_MIN (default 35),
     BQ_PROJECT (default stock-trading-498512). Stdlib only.
"""
import json
import os
import subprocess
import sys
import urllib.request

PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
MODE = os.environ.get("RELAY_MODE", "alerts")
WINDOW_MIN = int(os.environ.get("RELAY_WINDOW_MIN", "35"))
WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "").strip()


def bq(sql):
    out = subprocess.run(
        ["bq", "--project_id=" + PROJECT, "--quiet", "--headless", "--format=json",
         "query", "--use_legacy_sql=false", "--max_rows=1000", sql],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    s = out.stdout.strip()
    i = s.find("[")
    return json.loads(s[i:]) if i != -1 else []


def post(text):
    """POST {text: ...} — the shape Slack/Discord/mattermost incoming webhooks accept; generic enough
    for ntfy / a Pub/Sub-push proxy too. Never raises into CI noise on a transient webhook error."""
    body = json.dumps({"text": text}).encode("utf-8")
    req = urllib.request.Request(WEBHOOK_URL, data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.status


def relay_alerts():
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
        lines.append(f"[{r['severity'].upper()}] {r['source']}/{r['category']}: {r['message']} ({r['alert_ts']} UTC)")
    post("\n".join(lines))
    print(f"alerts: posted {len(rows)}")


def relay_orders():
    rows = bq(f"""
        SELECT item_key, strategy, ticker, side, CAST(qty AS STRING) AS qty,
               CAST(limit_price AS STRING) AS limit_price, CAST(entry_window_close AS STRING) AS window_close
        FROM `{PROJECT}.state.open_orders`
        ORDER BY ticker
    """)
    if not rows:
        print("orders: none pending")
        return
    lines = [f"📋 Stock-Trading — {len(rows)} staged order(s) awaiting confirmation (tap the [Claude] Confirm order event):"]
    for r in rows:
        lines.append(f"{r['side']} {r['qty']} {r['ticker']} ({r['strategy']}) @ {r['limit_price']} — window to {r['window_close']}")
    post("\n".join(lines))
    print(f"orders: posted {len(rows)}")


def main():
    if not WEBHOOK_URL:
        print("WEBHOOK_URL not set — relay is a clean no-op.")
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

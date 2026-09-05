#!/usr/bin/env python3
"""Out-of-session alert / staged-order relay to a vendor-neutral webhook (stack review 2026-06-24).

WHY (RUNBOOK §25 A1/A2/A3). Alert DELIVERY today funnels into one Gmail inbox on one Google account
(the DTS failure-emails + both Apps Scripts), and the two Apps Scripts live ONLY in script.google.com
(un-versioned). This relay is a version-controlled, scheduled GitHub Action that reads BigQuery via the
EXISTING read-only WIF SA (gh-ci-runner@, no new grant) and POSTs to a webhook whose failure mode is
uncorrelated with the owner's Google account. It COMPLEMENTS — does not replace — the alert_emailer
(the reliable ~2h-poll, de-duped channel) and the DTS failure-email (the identity-independent channel
for a dead emailer). This relay is the FAST, BEST-EFFORT channel.

DE-DUP is stateless and is AT-LEAST-ONCE, not "at most once" (codebase audit 2026-07-26 —
correcting a prior version of this paragraph that claimed the latter). alerts mode posts every
ops.alerts row raised in the last RELAY_WINDOW_MIN minutes, and a stateless relay with no
notified_ts write has no way to exclude a row it already posted in the prior run's window, so any
row falling in the overlap between two consecutive runs' windows is POSTed twice — a bounded,
known duplicate, not a bug to "fix" by tightening the window down to the cron interval. The window
must stay WIDER than the real spacing between runs, which is NOT the nominal cron: GitHub scheduled
delivery is best-effort and routinely runs late. Historical `*/30`-era measurement (2026-08-21, before
the 2026-08-30 move to `0 */2 * * *`): a median gap of 52.6 min and a max of 89.5 min against a
nominal 30-min interval (sampled over the workflow's own run history at the time). A window narrower
than the actual gap leaves a permanent hole — an alert raised between where the last run's window
ended and the late run's actual (delayed) start is never posted at all, on a channel whose whole job
is fast, best-effort delivery of things like drawdown-kill and missed-run alerts. So the workflow
does not rely on this module's default: .github/workflows/alert-relay.yml computes RELAY_WINDOW_MIN
per run from the ACTUAL elapsed time since its own last successful run (+130 min margin, clamped to
[130, 1440]; a fixed 240 if that lookup fails). The margin is a full alerts interval (120 min) plus
10 min slack, not a flat +10 (2026-08-30 revision): `gap` is measured from the last SUCCESSFUL run of
ANY mode, and the daily orders run (13:05 UTC) and the Monday heartbeat (13:15 UTC) relay NO alerts
yet still reset that anchor — when one of them is the anchor, a flat +10 margin understates how far
back coverage must reach by up to a full alerts interval, silently dropping every alert raised in
between (this relay is stateless — a skipped row is never retried, so a hole is permanent).
Brute-forced over independent per-run delays: margin=10 left an 80-min permanent hole; margin=130
leaves zero. The 130 here doubles as the FLOOR for a run with no env override (local/manual
invocation) — floor and margin are the same number by construction, since a zero-or-negative gap
clamps to the margin itself. The accepted cost is ~2.1x duplicate ntfy pushes (was ~1.1x under the
old +10 margin) — for THIS channel a duplicate ping is a nuisance; a silently missed critical alert
is a safety failure, so the tradeoff is not close. The reliable, de-duped channel is the ~2h
alert_emailer (RUNBOOK §25 A1) — that is where "exactly once" is guaranteed, by a real notified_ts
cursor this module deliberately does not carry. If a future audit re-flags "WINDOW_MIN=130 > cron
interval=120, tighten it to 120": that is this same false claim recurring — don't. See
test_window_min_covers_cron_interval_with_margin in tests/test_alert_relay.py, which pins
WINDOW_MIN >= the alerts cron interval as an invariant.

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

Env: WEBHOOK_URL (required — else clean no-op), RELAY_MODE, RELAY_WINDOW_MIN (default 130),
     BQ_PROJECT (default stock-trading-498512). Stdlib only.
"""
import json
import os
import sys
import urllib.request
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
except ImportError:  # pragma: no cover — stdlib since 3.9; CI/runners pin >=3.9
    ZoneInfo = None
    ZoneInfoNotFoundError = KeyError

from lib.bq_json import run_bq_query
from lib import tz_render

PROJECT = os.environ.get("BQ_PROJECT", "stock-trading-498512")
MODE = os.environ.get("RELAY_MODE", "alerts")
# Deliberately > the alerts cron interval (0 */2 * * *, i.e. 120 min, in
# .github/workflows/alert-relay.yml), never a value to "tighten down to 120" (codebase audit
# 2026-07-26). This 130 is the FLOOR, used only when nothing sets RELAY_WINDOW_MIN: the workflow
# itself passes a window sized from the real gap since its last successful run, because GitHub's
# actual delivery spacing runs wider than the nominal cron (see the module docstring's DE-DUP
# paragraph, and test_window_min_covers_cron_interval_with_margin for the pinned invariant).
WINDOW_MIN = int(os.environ.get("RELAY_WINDOW_MIN", "130"))
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

    Thin wrapper over the shared core (scripts/lib/tz_render.py, 2026-07-20 dedup consolidation —
    this exact NULL/empty/error-falls-back-to-Denver logic had independently drifted from
    ops/dashboard/generate_dashboard.py's copy). Passes `bq` itself, not a query result, so a test's
    `monkeypatch.setattr(ar, "bq", ...)` is honored — the core calls back into whatever `bq` resolves
    to in this module at call time."""
    return tz_render.get_display_tz(bq, PROJECT)


def fmt_ts(v, tz_name):
    """Render a BigQuery `CAST(alert_ts AS STRING)` value in tz_name, labeled — previously always
    rendered as a bare "... UTC" string regardless of where the operator actually is.

    Real wire format (verified against live BigQuery, 2026-07-09): "YYYY-MM-DD HH:MM:SS[.ffffff]+00"
    — it never contains the literal string "UTC". The parse/localize half is the shared core
    (scripts/lib/tz_render.py); this wrapper keeps the falsy-v/falsy-tz_name guard and this site's
    own "{v} UTC" fallback label, which generate_dashboard.py's sibling deliberately does NOT match
    (it returns `v` unchanged for a falsy v, and labels its fallback "(UTC)")."""
    # `not tz_name` guards a None/empty tz: ZoneInfo(None) raises TypeError (not caught below), which
    # would escape into main()'s outer `except Exception` and drop the whole batch — exactly what this
    # function's contract forbids. get_user_tz() already coalesces to a real tz, so this is belt-and-
    # suspenders; for tz_name == "" it returns the same "... UTC" string the except-branch would.
    if not v or not tz_name or ZoneInfo is None:
        return f"{v} UTC"
    try:
        return tz_render.render_ts(v, tz_name)
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
               CAST(limit_price AS STRING) AS limit_price, CAST(entry_window_close AS STRING) AS window_close,
               instruction_id
        FROM `{PROJECT}.state.open_orders`
        ORDER BY ticker
    """)
    if not rows:
        print("orders: none pending")
        return
    # Craftability-aware wording (2026-07-20 — mirrors the same fix already applied to
    # bigquery/30_confirm_attestation.sql's state.staged_without_confirm view). Before this, every
    # row got the same "tap the [Claude] Confirm order event" instruction — but per the 2026-07-09
    # calendar-scope narrowing (Claude_Task_Plan.md D2 order-craft discipline), a CRAFTABLE order
    # (equity/ETF/single-leg-options, staged with instruction_id set) never gets a `[Claude] Confirm
    # order` calendar event at all — its confirm surface is create_order_instruction's own IBKR
    # order-created notification. Telling the operator to go tap a calendar event that does not exist
    # is simply false, and reads as "you still need to confirm this" even on a row the operator
    # already confirmed via IBKR days ago and that is now just resting unfilled (`status='pending'`
    # here means "not yet filled + reconciled", not "not yet confirmed" — this relay has no live IBKR
    # read, so it cannot tell those two apart; the wording must not imply it can). Only a genuinely
    # non-craftable/manual-entry row (instruction_id NULL) actually has a `[Claude] Confirm order`
    # event to tap.
    # Wording note (2026-08-03): this MUST NOT assert "not yet filled". `status='pending'` is a
    # reconciliation state — a row that filled at this morning's open stays `pending` until D2a
    # Step 0 runs that evening — and this relay fires ~07:05 MT, i.e. inside the window where a
    # just-filled order is most likely to still read `pending`. The old wording ("still pending
    # (not yet filled)") asserted a broker fact this job cannot observe, contradicting the comment
    # directly above it. Say only what the registry actually knows: unreconciled.
    lines = [f"☑ Stock-Trading — {len(rows)} staged order(s) not yet reconciled "
             "(registry status 'pending'; may already have filled — IBKR is authoritative):"]
    # Wording note (market-only cutover 2026-07-21, label corrected here 2026-09-04): the row line
    # below MUST NOT render limit_price as `@ <price>`. Since the cutover, payload.limit_price is a
    # REFERENCE price (last, or bid/ask mid) kept for reserved-cash / notional-guard math ONLY —
    # bigquery/100_market_only_order_guard.sql: "only its meaning changes from 'order limit' to
    # 'reference price'"; bigquery/101: "no `limit_price` argument transmitted ... no marketable-limit
    # fallback". Every live order is MARKET, so an `@ <price>` label asserts an order price no live
    # order carries. This is a label fix, not a proposal about limit orders — the market-only cutover
    # is settled. This push is the only operator-facing surface that renders the column at all
    # (scripts/state_snapshot.sh just dumps the bare value), so nothing else repeats the claim.
    for r in rows:
        note = ("tap the [Claude] Confirm order event"
                if not r["instruction_id"] else
                "craftable order — confirm surface is IBKR's own order notification, not a calendar event")
        lines.append(f"{r['side']} {r['qty']} {r['ticker']} ({r['strategy']}) ref ~{r['limit_price']} "
                     f"— window to {r['window_close']} — {note}")
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
    except Exception as e:  # noqa: BLE001 - best-effort: never fail CI on a transient bq/webhook hiccup
        print(f"relay error (non-fatal): {e}", file=sys.stderr)
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

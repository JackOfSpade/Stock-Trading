#!/usr/bin/env python3
"""Out-of-session ops.alerts relay to a vendor-neutral webhook (stack review 2026-06-24).

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
ANY mode, and the Monday heartbeat (13:15 UTC) relays NO alerts yet still resets that anchor — when it
is the anchor, a flat +10 margin understates how far
back coverage must reach by up to a full alerts interval, silently dropping every alert raised in
between (this relay is stateless — a skipped row is never retried, so a hole is permanent).
(The daily 13:05 UTC `orders` run used to be a second such anchor; it was retired 2026-09-07 — see
the Modes list. That REMOVES one non-alerts anchor and so can only shrink the hole this margin
covers, never widen it. The margin stays at 130 regardless: the heartbeat anchor alone still
justifies it, and the brute-force result below was never sensitive to how MANY non-alerts runs
exist, only to whether at least one does.)
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

TWO DELIVERY RULES, both owner-directed 2026-09-07, both enforced HERE because this module is the
only code that decides what reaches the phone:

  RULE 1 — EVERY ntfy PUSH MUST HAVE AN EMAIL COUNTERPART. There is exactly one email channel in this
  system: `ops.alerts` -> ops/monitoring/alert_emailer.gs (a ~2h Gmail poll under the owner's own
  Google identity). GitHub Actions CANNOT send mail on its own — verified 2026-09-07: no SMTP/mail
  secret exists (`gh secret list` = ALERT_WEBHOOK_URL + OFFSITE_BACKUP_GCS only), no mail-sending
  action is `uses:`'d anywhere, and ntfy.sh's own `Email:` forwarding header is REJECTED for this
  topic (`HTTP 400 {"code":40053,"error":"anonymous email sending is not allowed"}` — probed live
  against ntfy.sh; the feature now requires an authenticated ntfy account, which this capability-URL
  topic deliberately is not). So the rule reduces to a structural invariant:

      **this relay may only push events that are rows in `ops.alerts`.**

  An event sourced from anywhere else (a bare `state.*` view, a CI step, a fixed canary string) is
  by construction email-less and must NOT be pushed. That is exactly why `orders` was retired below.
  Do NOT re-add a push that reads some other table "just to be helpful" — it silently violates RULE 1.

  RULE 2 — ntfy IS FOR THINGS NEEDING OPERATOR ACTION, NOT FOR STATUS. An all-clear ping teaches the
  operator to ignore the channel (RUNBOOK §19 alert fatigue), which is a safety failure dressed up as
  diligence. Anything that fires while the system is HEALTHY either stops pushing (heartbeat, below)
  or is filtered out of the push (NO_PUSH_CATEGORIES, below) while STILL being emailed. Note the
  asymmetry: this rule removes things from ntfy, never from email — the emailer's
  notification-complete contract (every alert emailed exactly once, RUNBOOK §20/§25) is unchanged.

Modes (env RELAY_MODE):
  * alerts    — recent unresolved critical/warning ops.alerts rows (default). Satisfies RULE 1 by
                construction (the source table IS the email bus). NO_PUSH_CATEGORIES applies.
  * heartbeat — weekly liveness canary (self-improvement audit 2026-07-03, guard-config-audit companion).
                alerts is best-effort BY DESIGN (main() swallows a POST failure so a transient
                webhook hiccup never adds CI noise on top of the reliable emailer) — but that same design
                means a permanently DEAD webhook (revoked, URL typo'd, endpoint decommissioned) would
                never surface: it only has to fire when there happens to be an alert.
                heartbeat is the one mode that does NOT swallow the POST failure, specifically so a dead
                diversification channel is caught by its own weekly run rather than discovered the day a
                real alert silently fails to arrive. Since 2026-09-07 it is SILENT on the phone (RULE 2)
                — see relay_heartbeat's docstring for why that costs the check nothing.
  (RETIRED 2026-09-07: `orders` — the daily ~07:05 MT staged-order confirm reminder over
  state.open_orders (A3, RUNBOOK §25). It violated BOTH rules at once. RULE 1: state.open_orders is a
  view, not an alert, so this push was the one operator-facing notice in the whole system with NO email
  counterpart of any kind (confirmed by an exhaustive sweep of both Apps Scripts — neither ever queries
  state.open_orders). RULE 2: its query had no WHERE clause beyond the view's own `status='pending'`,
  so it re-listed EVERY unreconciled order EVERY day — and per this file's own craftability note (2026-07-20)
  and RUNBOOK §25, a craftable order's confirm surface is IBKR's own notification, so for the normal case
  the operator had already tapped days earlier and the daily re-push asked for nothing. `pending` here means
  "not yet filled + reconciled", never "not yet confirmed", and this relay has no live IBKR read to tell
  those apart — so it could not even in principle push only the rows that needed action.
  REPLACED BY, not dropped: bigquery/229_staged_order_confirm_notice.sql raises the same fact as a
  `staged_order_awaiting_confirm` WARNING in ops.alerts from ops.sp_sq_daily_staging_cap_check — a DAILY
  scheduled query (05:25 UTC, 7 days a week, so it covers the Fri/Sat weekend hole D3's 5x/week Sun–Thu
  cadence leaves). That single row now reaches BOTH channels automatically: email via alert_emailer.gs
  (RULE 1 satisfied) and ntfy via `alerts` mode above. It dedups on the sorted item_key SET via
  sp_raise_alert_once, so a NEW order to confirm re-alerts while an unchanged pile stays quiet
  (RULE 2 satisfied), and it auto-resolves when the orders reconcile. Same retire-a-duplicate-notice
  precedent as `catchup` below.)
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

# RULE 2 (see the module docstring): categories that are EMAILED but never PUSHED.
#
# These six are the SISA roster-membership notices. They are raised at 'warning' rather than 'info'
# for one reason only — `info` is filtered out by BOTH alert_emailer.gs's SEVERITIES list and this
# module's own query, so an 'info' roster change reached NO channel at all before 2026-08-04. The
# severity is a routing device, not a judgement: these are COMPLETED, healthy, fully-autonomous
# actions of the strategy-arsenal loop (CLAUDE.md's SISA note — there is deliberately no human
# approval step anywhere in the add/delete path), and alert_emailer.gs already says so in code, by
# splitting them into their own non-fault visual lane with their own subject line rather than
# rendering them as "⚠ ALERT". Its comment states the cost of getting this wrong exactly: "an
# operator who is emailed '⚠ ALERT' every time a healthy autonomous action completes learns to
# ignore the channel."  A phone push is the sharpest version of that same mistake, so they stay in
# email (where the operator reads them at leisure, in their own lane) and stop buzzing the phone.
#
# SCOPE IS DELIBERATELY NARROW — this is a suppression list on a SAFETY channel, so it reuses an
# existing, owner-blessed classification instead of inventing a new taxonomy. It is exactly
# alert_emailer.gs's ROSTER_NOTICE_CATEGORIES, no more. Other categories that are likewise raised at
# 'warning' to reach a channel (process_scorecard_signal, immediate_action_flagged,
# handoff_contract_unpinned, park_conversion_refused_evidence_mismatch, ...) are NOT listed here and
# keep pushing: some of them plainly do need action, and mis-suppressing one is a silent safety
# failure while an extra push is only a nuisance. Do not extend this list to "things that felt noisy
# this week" — extend it only in lockstep with the roster-notice contract below.
#
# FOUR-PLACE LOCKSTEP, now machine-checked. alert_emailer.gs's own comment already warned that this
# category list lives in three places ("Keep this list in lockstep with Rule 5's IN list in
# bigquery/134 and the ROSTER-CHANGE NOTICE contract in the Claude_Task_Plan.md preamble. A category
# in only one of the three places is inert.") with nothing enforcing it. This constant makes it four.
# Rather than add a fourth unchecked copy, scripts/check_roster_notice_lockstep.py (new, 2026-09-07,
# wired into ci.yml) now asserts all four agree — so the drift hazard that comment describes is
# smaller after this change than before it, not larger.
NO_PUSH_CATEGORIES = (
    "strategy_shadow_registered",   # SL5: entered SHADOW, added to roster.yaml, zero capital
    "strategy_probe_registered",    # SL5: PAPER->PROBE, first real capital
    "strategy_graduated",           # M4 section H: PROBE->ADOPTED, 30-trade gate cleared
    "retirement_proposed",          # SL4: a drop is pending AR_orc adjudication
    "strategy_deregistered",        # SL5: dropped from the roster
    "roster_below_floor",           # SL1: active roster is at the n_min=2 floor
)


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


def post(text, silent=False):
    """POST the alert text. Two shapes, branched on the destination:
      * ntfy.sh (OAE-6, 2026-07-16 self-provisioned second channel — see RUNBOOK §25 A2/A3): ntfy
        renders the raw request BODY as the push message, so a JSON-wrapped body would show up as a
        literal '{"text": "..."}' string on the phone — send the plain text instead, with the ntfy
        `Title` header for a readable notification title.
      * everything else (Slack/Discord/mattermost incoming webhooks, a generic Pub/Sub-push proxy):
        {text: ...} JSON, unchanged.
    Never raises into CI noise on a transient webhook error (callers decide best-effort vs. not —
    see relay_heartbeat's docstring).

    silent=True (RULE 2, 2026-09-07) publishes WITHOUT notifying the operator, for the one message
    that must be SENT to prove the channel works but must never buzz a phone. The three headers were
    each probed live against ntfy.sh before being used here (2026-09-07) — do not assume, re-probe if
    you change them:
      * `Priority: min`   — ntfy priority 1. Documented verbatim as "No vibration or sound. The
                            notification will be under the fold in 'Other notifications'." The
                            response echoed `"priority":1`, confirming it parsed.
      * `Cache: no`       — not stored in the topic's message history. VERIFIED, not assumed: a
                            follow-up `GET /<topic>/json?poll=1&since=all` returned nothing at all,
                            so the canary leaves no residue for the operator to scroll past either.
      * `Firebase: no`    — not forwarded to Firebase/FCM, which is the Android delivery path.
    All three were accepted together with HTTP 200. Deliberately NOT used: ntfy's `Email:` header —
    it 400s on this topic ("anonymous email sending is not allowed"), and a 400 would fail the POST
    and so turn the liveness canary permanently red. See the module docstring's RULE 1.

    Headers are ntfy-specific and are simply absent on the generic-webhook branch; a Slack/Discord
    endpoint has no equivalent, so on such an endpoint the heartbeat stays audible. That is accepted
    and not worth a second code path: the live channel is ntfy (RUNBOOK §25 A2/A3, OAE-6), and the
    fallback direction is the safe one (an extra ping, never a missed alert)."""
    if "ntfy.sh" in WEBHOOK_URL:
        headers = {"Title": "Stock-Trading", "Content-Type": "text/plain; charset=utf-8"}
        if silent:
            headers.update({"Priority": "min", "Tags": "heartbeat",
                            "Cache": "no", "Firebase": "no"})
        req = urllib.request.Request(WEBHOOK_URL, data=text.encode("utf-8"), headers=headers)
    else:
        body = json.dumps({"text": text}).encode("utf-8")
        req = urllib.request.Request(WEBHOOK_URL, data=body,
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.status


def relay_alerts():
    tz = get_user_tz()
    # The NOT IN filter is RULE 2's push-side suppression (see NO_PUSH_CATEGORIES). It is applied
    # HERE, in the relay's own query, and deliberately NOWHERE ELSE: the rows still exist unresolved
    # in ops.alerts, still flow to alert_emailer.gs, and still count toward every state.* view and
    # trading gate that reads the alert board. This is a channel filter, not a severity change and
    # not a resolve — the failure mode of "silence a verifier by editing its input" (and of an
    # alert that is quietly never raised) is exactly what it must not become.
    # Literals are interpolated from the Python tuple rather than retyped, so the constant above is
    # the single source for this file; the category strings are code-owned identifiers, never user
    # input, so there is no injection surface to parameterize away.
    #
    # TWO FAIL-SAFE PROPERTIES, both deliberate, both pinned by tests — because EVERY failure mode of
    # this clause is silent. relay_alerts() runs inside main()'s best-effort `except`, so a broken
    # query does not go red; it prints one stderr line and the phone simply stops ringing.
    #   1. EMPTY-TUPLE GUARD. `category NOT IN ()` is a BigQuery SYNTAX ERROR, not an empty filter.
    #      An accidentally-emptied NO_PUSH_CATEGORIES would therefore kill the ENTIRE alerts push —
    #      drawdown-kill and missed-run criticals included — permanently, rather than merely stopping
    #      the six suppressions. Degrade to "no filter at all" instead: for a delivery channel, pushing
    #      too much is a nuisance and pushing nothing is a safety failure.
    #   2. NULL-SAFE POLARITY. ops.alerts.category is nullable (no NOT NULL constraint, no dbt
    #      not_null test), and SQL three-valued logic makes `NULL NOT IN (...)` evaluate to NULL, which
    #      WHERE treats as false — silently dropping a NULL-category alert from the push while it is
    #      still emailed. COALESCE(..., TRUE) makes an unknown category PUSH rather than vanish. This
    #      is the same rule bigquery/75's ADOPTED-DUST exclusion states for itself ("an exclusion on a
    #      safety check must never be able to evaluate to NULL"), with the polarity pointed at
    #      delivery: suppression must be provably TRUE, never merely not-provably-false.
    no_push_clause = (
        "AND COALESCE(category NOT IN ({}), TRUE)".format(
            ",".join(f"'{c}'" for c in NO_PUSH_CATEGORIES))
        if NO_PUSH_CATEGORIES else ""
    )
    rows = bq(f"""
        SELECT CAST(alert_ts AS STRING) AS alert_ts, severity, source, category, message
        FROM `{PROJECT}.ops.alerts`
        WHERE NOT resolved AND severity IN ('critical','warning')
          {no_push_clause}
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


def relay_heartbeat():
    """Weekly canary POST. Deliberately NOT wrapped in the best-effort try/except main() uses for
    alerts — here a POST failure IS the finding (channel diversity is only real if the second
    channel is actually alive), so it must propagate to a non-zero exit / red CI run.

    SILENT SINCE 2026-09-07 (RULE 2). This was the system's one literal all-clear ping: a weekly
    "✓ … channel alive, no action needed" buzz on the phone, by construction firing when nothing was
    wrong. It now publishes with silent=True — see post() for the three probed headers.

    THIS COSTS THE CHECK NOTHING, and that is the whole reason it is done this way rather than by
    deleting the mode. What this canary actually detects is a dead endpoint: a revoked topic, a
    typo'd URL, a decommissioned host. That detection lives entirely in whether the POST to the REAL,
    CONFIGURED WEBHOOK_URL returns success — it is the HTTP round-trip, never the phone buzz, that is
    the evidence. A silent publish exercises the identical code path against the identical URL and
    fails identically on a dead one. Two tempting "simplifications" that WOULD break it, for whoever
    reads this next: (a) posting to some other//dev/null topic instead — ntfy returns 200 for ANY
    topic name, including a typo'd one, so that proves only that ntfy.sh is up, which is not the
    thing being checked; (b) replacing the POST with a GET/poll of the topic — same defect, a
    nonexistent topic reads as an empty topic, so a wrong URL passes. Keep the real POST.

    The message text is kept human-legible anyway: `Cache: no` means it is not retained in topic
    history, but a future maintainer probing the topic by hand should still see what it is."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    status = post(f"Stock-Trading alert-relay liveness probe — silent by design, no action needed ({now}).",
                  silent=True)
    print(f"heartbeat: posted silently (HTTP {status})")


def main():
    if not WEBHOOK_URL:
        print("WEBHOOK_URL not set — relay is a clean no-op.")
        return 0
    if MODE == "heartbeat":
        relay_heartbeat()
        return 0
    if MODE == "orders":
        # RETIRED 2026-09-07 (see the module docstring's Modes list). Handled EXPLICITLY rather than
        # falling through to the `else: relay_alerts()` default below, because a silent fallthrough
        # is the worse failure: a stale `workflow_dispatch -f mode=orders`, a bookmarked re-run of an
        # old run, or a cron literal left behind in a fork would quietly relay ALERTS under the name
        # "orders" and look green while doing something other than what was asked. Exit 0 (not an
        # error) — an operator asking for a retired reminder has done nothing wrong, and this job's
        # failure signal is reserved for a genuinely dead channel (see relay_heartbeat).
        print("orders: mode RETIRED 2026-09-07 — the staged-order confirm reminder is now the "
              "`staged_order_awaiting_confirm` ops.alerts warning raised daily by "
              "ops.sp_sq_daily_staging_cap_check (bigquery/229_staged_order_confirm_notice.sql), "
              "which reaches BOTH email (alert_emailer.gs) and this relay's `alerts` mode. "
              "Nothing to do here.")
        return 0
    try:
        relay_alerts()
    except Exception as e:  # noqa: BLE001 - best-effort: never fail CI on a transient bq/webhook hiccup
        print(f"relay error (non-fatal): {e}", file=sys.stderr)
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

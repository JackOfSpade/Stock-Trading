/**
 * Stock-Trading — Alert emailer (real-time-ish alert delivery, self-email).
 * =========================================================================
 * Fixes "alerts are unmonitored between routines" (A2). ops.alerts is the durable hard-stop /
 * anomaly sink (cash tripwire, dual-path disagreement, embedding unhealthy, stale data, missed
 * order confirmation, ...). Routines also create [Claude] ATTENTION calendar events, but a
 * calendar entry is easy to miss. This Apps Script polls ops.alerts on a short trigger (e.g.
 * every 2 hours) and EMAILS you ONCE for every alert that was ever raised — including a
 * self-healing one that already auto-resolved between two polls — a genuine push channel, with
 * no Cloud Monitoring / Pub/Sub console wiring.
 *
 * NOTIFICATION-COMPLETE (2026-06-24): the poll selects on `notified_ts IS NULL`, NOT `NOT resolved`.
 * The old `NOT resolved` filter silently dropped any alert created-and-resolved inside one 2h poll
 * window (the self-healing class — e.g. a stranded-session warning, a cadence missed_run that the next
 * run cleared) so the owner was never told it had happened. Keying on `notified_ts` means every alert
 * is emailed exactly once and then stamped; resolved-since-raise alerts are still sent, tagged
 * AUTO-RESOLVED when the auto-resolver closed it, or RESOLVED when a human did (v7, 2026-08-05:
 * the tag previously keyed on `resolved` alone and so mislabelled every hand-closed alert as
 * self-healed). (RUNBOOK §20 / §25.)
 *
 * DELIVERY IS NOT THE SAME THING AS LIVENESS (v6, 2026-08-04). Two related gaps, both found by an
 * adversarial review of v5 rather than by anything failing in production:
 *   - LOOKBACK_HOURS is a CLIFF, not a window. alert_ts is fixed while CURRENT_TIMESTAMP() advances, so
 *     an un-notified alert that passes the bound leaves the ONLY query that ever stamps notified_ts,
 *     permanently. Tolerable for a condition that re-raises; silently destructive for a one-shot roster
 *     fact that nothing ever re-raises. The six roster categories are now exempt from that bound.
 *   - The heartbeat proves the SCRIPT ran, not that anything was DELIVERED. checkAlerts_ swallows every
 *     exception and beat_() runs outside that try, so a render throw or a Gmail quota rejection leaves a
 *     green heartbeat and zero delivered alerts, indefinitely. After 3 consecutive failed polls the
 *     script now escalates over two channels that do not depend on the failing one — an ops.alerts row
 *     that alert_relay.py pushes to ntfy from GitHub Actions, and a direct Gmail send.
 *
 * ACCEPTED IS NOT DELIVERED (v8, 2026-08-07). The third and last link in that same chain. v6 covers a
 * send that THROWS; it cannot cover a send that SUCCEEDS and is then routed away from the Inbox by a
 * Gmail-side rule, because nothing here looked at where the message landed. Measured 2026-08-07: all
 * 50 Stock-Trading threads from 2026-07-14 onward — alert digests, CRITICAL cascades, and every weekly
 * delivery canary — sit in TRASH with no INBOX label, while the heartbeat, notified_ts, the
 * alert_delivery_failing escalation and the canary all read green, because sending never failed. A
 * post-send probe now verifies the message actually acquired the INBOX label and escalates a streak
 * over ntfy only (emailing someone to say their email is not arriving defeats itself). See
 * verifyInboxDelivery_.
 *
 * ROSTER-CHANGE NOTICES (v5, 2026-08-04, owner directive "although i let ai dictate when to add/drop
 * strategies, i still want to be notified by email when it does so"): the autonomous SISA loop
 * (SL1-SL5) previously raised its roster-membership events at 'info', which the SEVERITIES filter below
 * excludes — so a strategy could be added to or dropped from the live roster and reach NO channel at
 * all. Verified empirically before the change: every 'info' row ever written to ops.alerts had
 * notified_ts IS NULL, without exception. Those six categories now raise at 'warning'
 * (bigquery/134_roster_change_notifications.sql) and arrive here. They are rendered in their OWN lane —
 * separate subject, separate section, structured payload detail — because a completed autonomous action
 * is not a fault, and an operator emailed "⚠ ALERT" for healthy expected behavior stops reading the
 * channel that also carries the real ones. This adds NO approval step: add/drop stays fully autonomous.
 *
 * Like the weekly report, it runs on Google's servers as you (from you, to you): no SMTP, app
 * password, or API key. It de-dupes via Script Properties so you're emailed ONCE per alert,
 * not every run, and it tells you when previously-open alerts have been resolved.
 *
 * SETUP (one time): a second file in the SAME script.google.com project as the weekly report
 * (ops/weekly_report/README.md) — NOT a separate project. This file has no manifest of its own
 * (ops/monitoring/ carries no appsscript.json) because it shares weekly_report.gs's one project and
 * top-level scope, which is exactly why the version const below is named ALERT_SCRIPT_VERSION rather
 * than SCRIPT_VERSION — see that comment. (Corrected 2026-08-08: this note used to offer "new
 * script.google.com project" as an equally valid alternative, which contradicted that comment and
 * does not match the live setup, "Stock-Trading Automation," which holds both files.) Add the
 * BigQuery advanced service, set RECIPIENT, run testAlertCheck() once to authorize, then run
 * installAlertTrigger() to schedule it.
 */

// ===== CONFIG =====
const ALERT_PROJECT_ID = 'stock-trading-498512';
const ALERT_RECIPIENT  = Session.getActiveUser().getEmail(); // self-email
const ALERT_SENDER     = 'Stock-Trading Alerts';
const SEVERITIES       = ['critical', 'warning']; // set to ['critical'] for criticals only
const POLL_HOURS       = 2;                        // how often to check
const ALERT_SCRIPT_VERSION = 'v8';                 // bump on every functional change to this file; read by state.script_version_drift (bigquery/43_script_version_registry.sql) -- keep bigquery/43's MERGE seed in lockstep. Named ALERT_SCRIPT_VERSION (not SCRIPT_VERSION) because this file and weekly_report.gs share ONE Apps Script project's top-level scope -- a same-named const in both would throw a project-wide SyntaxError on the next paste (2026-07-14 audit finding).

// ROSTER-CHANGE NOTICES (owner directive 2026-08-04, bigquery/134_roster_change_notifications.sql).
// The autonomous SISA loop (SL1-SL5) adds and removes trading strategies with no human approval step --
// that stays true. But until 2026-08-04 it did so with no operator-facing signal either: the six
// categories below were raised at 'info', which the SEVERITIES filter above excludes, so a roster change
// reached NO channel. They are now raised at 'warning' and therefore arrive here like any other alert.
//
// They are NOT faults, and rendering them as faults would be its own bug -- an operator who is emailed
// "⚠ ALERT" every time a healthy autonomous action completes learns to ignore the channel. So this file
// splits them into their own visual lane with their own subject line, and renders the structured payload
// (which strategy, which transition, how much capital, why) instead of just the message string.
//
// Keep this list in lockstep with Rule 5's IN list in bigquery/134 and the ROSTER-CHANGE NOTICE contract
// in the Claude_Task_Plan.md preamble. A category in only one of the three places is inert.
const ROSTER_NOTICE_CATEGORIES = [
  'strategy_shadow_registered',   // SL5: entered SHADOW, added to roster.yaml, zero capital
  'strategy_probe_registered',    // SL5: PAPER->PROBE, FIRST REAL CAPITAL (renamed from strategy_adopted)
  'strategy_graduated',           // M4 section H: PROBE->ADOPTED, 30-trade gate cleared
  'retirement_proposed',          // SL4: a drop is pending AR_orc adjudication
  'strategy_deregistered',        // SL5: dropped from the roster
  'roster_below_floor'            // SL1: active roster is at the n_min=2 floor
];
// LOOKBACK_HOURS bounds the notified_ts IS NULL scan. Was 48h — if the emailer itself is dead longer
// than the lookback (revoked token / deleted trigger), alerts raised early in the outage permanently
// keep notified_ts NULL and are never emailed by ANY code path on recovery (the webhook relay's window
// is only ~35min and non-email; the delivery canary only proves the channel, it doesn't backfill).
// The automation_heartbeat dead-man's switch fires at 8h of silence, so 168h (1 week) gives ample
// margin for any realistic recovery lag at negligible extra query cost (2026-07 report-system fix).
const LOOKBACK_HOURS   = 168;
// Human-readable label derived from LOOKBACK_HOURS, used by htmlAlerts_/plainAlerts_ so the copy never
// drifts out of sync with the actual window (days when evenly divisible, else "Nh"). Scoped ONLY to the
// newly-un-notified count in those footers -- the recurring termination_close_staged re-sends (checkAlerts_)
// have no LOOKBACK_HOURS bound (their query is `WHERE ... AND NOT resolved`, unbounded), so labelling them
// "in the last LOOKBACK_LABEL" too would misstate their window. (2026-07-29: the prior new-vs-recurring
// rewrite dropped this callout from both footers entirely, going dead-code here as a side effect --
// restored, correctly scoped, rather than deleting LOOKBACK_LABEL, since the operator needs the window.)
const LOOKBACK_LABEL   = (LOOKBACK_HOURS % 24 === 0) ? `${LOOKBACK_HOURS / 24}d` : `${LOOKBACK_HOURS}h`;

// ===== ENTRY POINTS =====
function testAlertCheck()   { checkAlerts_(); }
function runAlertCheck()    { checkAlerts_(); }

function installAlertTrigger() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'runAlertCheck')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('runAlertCheck').timeBased().everyHours(POLL_HOURS).create();
  Logger.log('Installed alert trigger: every %s h', POLL_HOURS);
}

// ===== MAIN =====
function checkAlerts_() {
  // 2026-07-04: the query below (and everything that depends on its result) is wrapped so a
  // BigQuery-side failure — observed live on 2026-07-03 as a GoogleJsonResponseException /
  // "QueryUsagePerDay ... custom quota exceeded" — is logged distinctly and skips only THIS poll's
  // alert check, rather than throwing uncaught and also skipping beat_() below. A quota error is
  // usually transient (next poll ~2h later typically succeeds), but if it recurred every poll for
  // long enough to also suppress the heartbeat, cadence_check.sql's automation_heartbeat dead-man's
  // switch could misdiagnose a live, working emailer as dead.
  let pollOk = false;
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) {
    // A concurrent/manual run owns delivery. Skipping is safe because its
    // successful stamp or the next scheduled poll will pick up every alert.
    Logger.log('Alert delivery already running; skipping this poll.');
    beat_(true);
    return;
  }
  try {
    const sevList = SEVERITIES.map(s => `'${s}'`).join(',');
    // NOTIFICATION-COMPLETE: select un-notified alerts (notified_ts IS NULL), NOT `NOT resolved`, so an
    // alert that self-healed between polls is still emailed exactly once. notified_ts is the durable
    // de-dup; Script Properties is a secondary guard so a failed stamp doesn't re-send next poll.
    // alert_ms (UNIX_MILLIS) lets the renderer format alert_ts in the DETECTED display timezone
    // (state.user_tz) instead of raw unlabeled UTC — alert_ts (STRING) is kept too as a UTC fallback.
    // payload (v5) is selected for the ROSTER CHANGE lane, which renders the structured transition
    // detail (strategy, states, roster count, capital, reason) rather than only the message string, and
    // for isTest_'s payload.synthetic check. Every consumer parses it defensively via pl_() -- a NULL,
    // absent, or malformed payload degrades to the message-only rendering and never throws. Kept
    // identical in the recurring query below so both result sets have the same shape.
    // ROSTER NOTICES ARE EXEMPT FROM LOOKBACK_HOURS (v6, 2026-08-04). LOOKBACK_HOURS is a CLIFF, not a
    // window: alert_ts is fixed and CURRENT_TIMESTAMP() only advances, so the instant an un-notified
    // alert turns 168h old it leaves this WHERE clause FOREVER — and this query is the only code path
    // in the entire system that stamps notified_ts. Raising the bound 48h->168h (see LOOKBACK_HOURS
    // above) moved that cliff; it did not remove it.
    //
    // For an ordinary alert that is tolerable: the condition either recurs and re-raises, or it healed.
    // A roster notice is different in kind. It reports a one-shot, irreversible fact — a strategy was
    // added to or dropped from the live roster — that is never re-raised by anything. Losing one is the
    // exact failure this whole feature exists to prevent, and it would fail SILENTLY: with notified_ts
    // permanently NULL, bigquery/134's Rule 5 never resolves it either, so it sits open forever, visible
    // only to someone who happens to query ops.alerts directly.
    // Six rare categories (~5-12 rows/year, rate-limited by the SISA anti-churn rails) are exempted from
    // the time bound entirely, so a delivery outage of any length DELAYS a roster notice instead of
    // destroying it. LIMIT 500 and the Script Properties dedup still bound the result either way.
    const rosterList = ROSTER_NOTICE_CATEGORIES.map(c => `'${c}'`).join(',');
    const rows = bqAlerts_(`
      SELECT alert_id, CAST(alert_ts AS STRING) AS alert_ts, UNIX_MILLIS(alert_ts) AS alert_ms,
             severity, source, category, message, resolved, resolved_note, TO_JSON_STRING(payload) AS payload
      FROM \`${ALERT_PROJECT_ID}.ops.alerts\`
      WHERE notified_ts IS NULL AND severity IN (${sevList})
        AND (alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${LOOKBACK_HOURS} HOUR)
             OR category IN (${rosterList}))
      ORDER BY alert_ts DESC
      LIMIT 500`);

    const props = PropertiesService.getScriptProperties();
    // Guard the parse: a corrupt/non-JSON notified_alert_ids property (manual edit, truncated write,
    // tampering) would otherwise throw here on EVERY poll before any send, permanently suppressing ALL
    // alert delivery. Degrade to an empty Set (at worst a re-send, never permanent silence) — matching
    // the defensive posture of the setProperty write below (2026-07-18 audit fix).
    let seen;
    try {
      seen = new Set(JSON.parse(props.getProperty('notified_alert_ids') || '[]'));
    } catch (e) {
      Logger.log('notified_alert_ids parse failed (corrupt property?) — treating as empty: ' + e);
      seen = new Set();
    }
    const fresh = rows.filter(r => !seen.has(r.alert_id));

    // RECURRING RE-NOTIFY for termination_close_staged (ITEM 17, self-improvement audit 2026-07-11): a
    // kill-trigger liquidation close order is urgent from hour 1 -- the notified_ts-once semantics above
    // would deliver exactly one email and then go silent even if it sits unconfirmed for days. This
    // SEPARATE query re-selects still-UNRESOLVED termination_close_staged alerts on EVERY poll,
    // independent of notified_ts, so it re-appears in the email every ~2h until D2a's Step 0 fill
    // reconciliation resolves it. Merged into the send batch but intentionally NOT stamped via
    // stampNotified_ below -- that stamp would remove it from this recurring query's own future
    // selections, defeating the point. De-duped against `fresh` so an alert on its FIRST poll (already
    // in `fresh` via the normal notified_ts IS NULL path) is not emailed twice in the same batch.
    let recurring = [];
    try {
      recurring = bqAlerts_(`
        SELECT alert_id, CAST(alert_ts AS STRING) AS alert_ts, UNIX_MILLIS(alert_ts) AS alert_ms,
               severity, source, category, message, resolved, resolved_note, TO_JSON_STRING(payload) AS payload
        FROM \`${ALERT_PROJECT_ID}.ops.alerts\`
        WHERE category = 'termination_close_staged' AND NOT resolved
        ORDER BY alert_ts DESC
        LIMIT 50`);
    } catch (e) { Logger.log('termination_close_staged recurring re-notify query skipped: ' + e); }
    const freshIds = new Set(fresh.map(r => r.alert_id));
    const combined = fresh.concat(recurring.filter(r => !freshIds.has(r.alert_id)));

    if (combined.length) {
      // Split the alert-delivery self-test (canary) from real alerts so a weekly probe is never
      // disguised as an incident in the subject — and, conversely, a real alert that happens to ride
      // in the same poll batch is never softened to "[TEST]". (RUNBOOK §15 / delivery_canary.sql.)
      // recurringCount is the ONE place this poll's newly-un-notified/recurring split is computed
      // (2026-07-29): alertSubject_, htmlAlerts_, plainAlerts_, and this Logger.log line used to each
      // recompute it independently and had already drifted once (one call site passed rows.length --
      // the pre-Set-dedup query result -- where the others used fresh.length). Compute it once here and
      // thread the SAME number to every consumer so it cannot diverge again.
      const recurringCount = combined.length - fresh.length;
      const subject = alertSubject_(fresh, recurringCount);
      GmailApp.sendEmail(ALERT_RECIPIENT, subject, plainAlerts_(combined, fresh.length, recurringCount),
        { htmlBody: htmlAlerts_(combined, fresh.length, recurringCount), name: ALERT_SENDER });
      Logger.log('Emailed %s new alerts (%s recurring termination-close)', combined.length, recurringCount);
      stampNotified_(fresh.map(r => r.alert_id)); // recurring termination_close_staged rows NEVER stamped
      // Bounded de-dup guard for ids we just emailed (in case the notified_ts stamp failed).
      const keep = [...seen, ...fresh.map(r => r.alert_id)].slice(-500);
      try {
        props.setProperty('notified_alert_ids', JSON.stringify(keep));
      } catch (e) { Logger.log('notified_alert_ids property write skipped: ' + e); }
      // POST-SEND INBOX VERIFICATION (v8, 2026-08-07). sendEmail() returning without throwing proves
      // Gmail ACCEPTED the message, not that it reached the Inbox. See verifyInboxDelivery_ below.
      verifyInboxDelivery_();
    } else {
      // Message must name BOTH halves of the query's WHERE clause: LOOKBACK_HOURS no longer describes
      // the full selection, since roster-change notices are exempt from that bound (see the query).
      // Saying only "in the last 168 h" would misdescribe a quiet poll as having checked a narrower
      // set than it did — and this line is the sole evidence a human reads when confirming a paste.
      Logger.log('No un-notified alerts (last %s h, plus roster-change notices of any age)', LOOKBACK_HOURS);
    }
    pollOk = true;
  } catch (e) {
    Logger.log('checkAlerts_ query failed (BigQuery quota or transient error?) — skipping this cycle: ' + e);
    escalateDeliveryFailure_(e);
  } finally {
    lock.releaseLock();
  }
  if (pollOk) resetDeliveryFailureStreak_();

  // Liveness beat (ops.heartbeat -> state.automation_heartbeat). Lets cadence_check.sql detect a
  // SILENTLY-DEAD emailer (revoked token / deleted trigger) via the independent DTS failure-email —
  // a dead emailer obviously can't email that it is dead. Best-effort: never block the run on it.
  // Runs regardless of the try/catch above (outside it) so a query-level failure never also
  // suppresses the heartbeat. pollOk distinguishes "polled and worked" from "polled and permanently
  // erroring" (2026-07-14 audit finding) -- a PERMANENT query failure would otherwise keep beating
  // 'poll' forever while zero real alerts get delivered, invisible to state.automation_heartbeat
  // (which only checks MAX(beat_ts), never `note`).
  beat_(pollOk);
}

// ===== notified_ts stamp (stack review 2026-06-24, RUNBOOK §25) =====
// Make "was the human told?" a queryable fact on ops.alerts instead of state hidden in Script
// Properties. Best-effort — never blocks delivery. De-dup STILL uses Script Properties (this is purely
// for auditability + the out-of-band relay). Re-fire-on-reopen is preserved: a reopened condition is a
// NEW alert_id (sp_raise_alert_once), so its notified_ts starts NULL. Needs the column from
// bigquery/18_stack_review_fixes.sql (apply 18 before re-pasting this script).
function stampNotified_(ids) {
  if (!ids || !ids.length) return;
  try {
    const idList = ids.map(id => `'${String(id).replace(/'/g, '')}'`).join(',');
    BigQuery.Jobs.query({
      query: `UPDATE \`${ALERT_PROJECT_ID}.ops.alerts\` SET notified_ts = CURRENT_TIMESTAMP() ` +
             `WHERE alert_id IN (${idList}) AND notified_ts IS NULL`,
      useLegacySql: false, timeoutMs: 30000
    }, ALERT_PROJECT_ID);
  } catch (e) { Logger.log('notified_ts stamp skipped: ' + e); }
}

// ===== heartbeat =====
// ===== DELIVERY-FAILURE ESCALATION (v6, 2026-08-04) =====
// Closes a blind spot found by an adversarial review of the v5 change. Everything inside checkAlerts_'s
// try — the query, the render, GmailApp.sendEmail, stampNotified_ — is caught and swallowed, and then
// beat_() runs OUTSIDE that try and writes a heartbeat regardless. That was deliberate (see the comment
// at the top of checkAlerts_: a transient BigQuery quota error must not be mistaken for a dead emailer),
// but it means liveness of the SCRIPT is being used as a proxy for liveness of DELIVERY, and the two
// come apart precisely when it matters:
//
//   * BigQuery itself is down  -> the beat_ INSERT also fails, no beat is written, and
//     state.automation_heartbeat's 8h dead-man DOES fire. Already covered.
//   * BigQuery is HEALTHY but delivery is not -> a render exception, a Gmail daily-quota rejection, a
//     revoked Gmail scope. beat_ succeeds, note='poll-error' is written, and NOTHING reads `note`
//     (automation_heartbeat reads only MAX(beat_ts) — its own comment says so). The heartbeat is green,
//     the dashboard is green, and zero alerts reach the operator. Indefinitely. NOT covered before v6.
//
// So escalate on a streak, over two channels that do NOT depend on the thing that is broken:
//   1. ops.alerts via sp_raise_alert_once — this row cannot be emailed by the very emailer that is
//      failing, but scripts/alert_relay.py relays critical+warning to the ntfy.sh push topic from
//      GitHub Actions every 30 minutes, entirely outside Apps Script and Gmail. That is the channel
//      that actually gets through. sp_raise_alert_once (not sp_raise_alert) so repeated escalations
//      collapse onto one open row instead of accumulating.
//   2. A direct GmailApp.sendEmail with no BigQuery involved — written on the assumption that mail
//      delivery is the common/working case and the query is usually what's broken. That assumption is
//      now KNOWN FALSE (see ACCEPTED IS NOT DELIVERED / v8 above, 2026-08-07): every Stock-Trading
//      thread measured, including this exact escalation class, was landing in TRASH with no INBOX
//      label, cause still unknown. Left in place regardless — it still fires and the message still
//      gets sent even when BigQuery is the broken half, and a future fix to the Trash-routing cause
//      makes it work again with no code change here — but do not read a quiet inbox as proof this
//      channel got through.
// Each is independently try/caught: whichever channel is alive still gets the message out.
//
// Raised at 'warning', NOT 'critical', deliberately: a critical would count toward
// state.trading_enabled's blocking_criticals and HALT ORDER STAGING on what may be a Gmail quota
// hiccup. Halting live trading because an email failed is a worse outcome than the failure. The ntfy
// push plus a stuck-open warning row is loud enough.
const DELIVERY_FAIL_ESCALATE_AFTER = 3;    // ~6h at POLL_HOURS=2 — under automation_heartbeat's 8h bar
const DELIVERY_FAIL_REESCALATE_EVERY = 12; // then roughly daily, so a long outage keeps reminding

function resetDeliveryFailureStreak_() {
  try {
    const props = PropertiesService.getScriptProperties();
    if (props.getProperty('poll_fail_streak')) props.deleteProperty('poll_fail_streak');
  } catch (e) { Logger.log('could not reset poll_fail_streak: ' + e); }
}

function escalateDeliveryFailure_(err) {
  let streak = 0;
  try {
    const props = PropertiesService.getScriptProperties();
    streak = (parseInt(props.getProperty('poll_fail_streak'), 10) || 0) + 1;
    props.setProperty('poll_fail_streak', String(streak));
  } catch (e) {
    Logger.log('could not track poll_fail_streak: ' + e);
    return; // without a durable streak we cannot tell a blip from an outage; stay quiet rather than spam
  }
  const due = (streak === DELIVERY_FAIL_ESCALATE_AFTER) ||
              (streak > DELIVERY_FAIL_ESCALATE_AFTER && streak % DELIVERY_FAIL_REESCALATE_EVERY === 0);
  if (!due) return;
  const hours = streak * POLL_HOURS;
  const msg = 'Stock-Trading ALERT DELIVERY IS FAILING: ' + streak + ' consecutive polls (~' + hours +
              'h) ended in an error, so NO alert emails are being sent. The heartbeat may still look ' +
              'green — it only proves the script ran, not that anything was delivered.';
  // Channel 1: ops.alerts -> alert_relay.py -> ntfy push (independent of Apps Script and Gmail).
  // The error text is NOT interpolated into SQL — it is arbitrary text from an exception and would be a
  // quoting/injection hazard. It goes in the email body instead; the payload carries structured facts.
  try {
    BigQuery.Jobs.query({
      query: `CALL \`${ALERT_PROJECT_ID}.ops.sp_raise_alert_once\`('warning','alert_emailer',` +
             `'alert_delivery_failing','${msg.replace(/'/g, '')}',` +
             `TO_JSON_STRING(STRUCT(${streak} AS consecutive_failures, ${hours} AS approx_hours, ` +
             `'${ALERT_SCRIPT_VERSION}' AS script_version)))`,
      useLegacySql: false, timeoutMs: 30000
    }, ALERT_PROJECT_ID);
  } catch (e) { Logger.log('escalation alert raise failed (BigQuery likely down too): ' + e); }
  // Channel 2: direct mail, no BigQuery in the path.
  try {
    GmailApp.sendEmail(ALERT_RECIPIENT, '⛔ Stock-Trading — ALERT DELIVERY IS FAILING (' + streak + ' polls)',
      msg + '\n\nLast error:\n' + String(err) +
      '\n\nWhat to check: the Apps Script execution log for alert_emailer, the BigQuery quota, and the ' +
      'Gmail daily send quota. Until this clears, treat the alert channel as DOWN and query ops.alerts ' +
      'directly:\n  SELECT * FROM ops.alerts WHERE notified_ts IS NULL AND severity IN (\'critical\',\'warning\') ORDER BY alert_ts DESC' +
      '\n\nRoster-change notices are exempt from the lookback window and will be delivered once this ' +
      'recovers, however long it takes. Other alert classes older than ' + LOOKBACK_LABEL + ' will not be.',
      { name: ALERT_SENDER });
  } catch (e) { Logger.log('escalation email failed (Gmail likely the broken component): ' + e); }
}

// ===== POST-SEND INBOX VERIFICATION (v8, 2026-08-07) =====
// Closes the last gap in the "delivery is not the same thing as liveness" chain, found by an audit of
// the 2026-08-07 daily runs rather than by anything erroring. v6 (escalateDeliveryFailure_) covers the
// case where SENDING fails: an exception inside checkAlerts_'s try. It cannot cover the case where
// sending SUCCEEDS and the message is then routed away from the Inbox by a Gmail-side rule, because
// nothing in this script ever looks at where the message landed.
//
// MEASURED 2026-08-07: every one of the last 50 Stock-Trading threads (alert digests AND the weekly
// report), spanning 2026-07-14 through 2026-08-07, carries labelIds ["TRASH","SENT"] and NOT ONE
// carries "INBOX". `subject:Stock-Trading in:inbox` returns zero threads; `is:unread` returns zero.
// That window includes CRITICAL digests (the 2026-08-01 M1a/M1b/M4/M5/SL4/D3 missing_dependency
// cascade, the 2026-08-03/04 trading_halted rows) and every weekly delivery canary. So the operator's
// entirely reasonable inference — "no alert email arrived, so nothing was wrong" — was unsound for
// weeks, and EVERY existing guard read green throughout:
//   * ops.heartbeat: 15 consecutive 'poll' beats, never 'poll-error'.
//   * notified_ts: stamped normally (the send genuinely succeeded).
//   * alert_delivery_failing: never raised, not once, because no exception ever occurred.
//   * the weekly delivery_canary: asserts the canary row was delivered+STAMPED — and stamping happens
//     here, in this script, immediately after sendEmail(). It proves the loop ran, not that a human
//     could see the result. The canary was itself in Trash the whole time.
// Nothing in this repo trashes the mail (grep: no moveToTrash / moveThreadToTrash anywhere), so the
// cause is Gmail-side — most likely a filter with a Delete action matching the self-send or the
// ALERT_SENDER display-name override. That is an account setting only the operator can change; what
// this script owes them is to NOTICE, over a channel that does not depend on the broken one.
//
// PROBE, and why it is three searches and not one. A just-sent message can lag Gmail's search index by
// seconds, so "not found in:inbox" alone is ambiguous between "misrouted" and "not indexed yet" —
// exactly the ambiguity that would make this check either noisy or useless. Searching in:anywhere
// first disambiguates: found-anywhere-but-not-in-inbox is a POSITIVE misroute observation; not found
// anywhere is inconclusive and deliberately leaves the streak untouched. The unquoted single-token
// `subject:Stock-Trading` is intentional — every subject this script and weekly_report.gs emit
// contains that token, and it avoids quoting the ⚠ / ⚗ / — characters that appear in the real
// subjects. from:me scopes it to our own self-sent mail.
//
// ESCALATION reuses the v6 streak idiom (a single indexing-lag miss must not page anyone) but sends
// over the ntfy channel ONLY: emailing a human to tell them their email is not arriving is a
// self-defeating design, so there is deliberately no Channel-2 direct-mail twin here. Raised at
// 'warning', not 'critical', for the same reason v6 is: a critical counts toward
// state.trading_enabled's blocking_criticals and would HALT ORDER STAGING over a mail-routing rule.
// NOTE the ntfy relay (scripts/alert_relay.py, */30 GitHub Action) is a clean no-op unless WEBHOOK_URL
// is set — if it is not, this row still lands in ops.alerts and is visible to any routine's board read.
const INBOX_FAIL_ESCALATE_AFTER   = 3;   // ~6h at POLL_HOURS=2 — matches DELIVERY_FAIL_ESCALATE_AFTER
const INBOX_FAIL_REESCALATE_EVERY = 12;  // then roughly daily

// PROBE WINDOW, in seconds, expressed with `after:<unix-epoch-seconds>` and NOT with `newer_than:`.
// Gmail's newer_than/older_than accept ONLY d/m/y units — there is no `h`. `newer_than:1h` is not a
// 1-hour filter; it is an unrecognised clause, so the query degrades to an UNSCOPED "any self-sent
// Stock-Trading message, ever". That would have made this check fire on a perfectly healthy pipeline
// the moment the operator archived the last alert mail: archived mail has no INBOX label but is still
// found by the in:anywhere probe, so `anywhere>0 && inbox===0` — a permanent false alarm that punishes
// a tidy inbox. `after:` takes a real epoch-second timestamp. 10 minutes is generous for Gmail's
// search-index lag while staying far too short for a human to have archived the message we just sent.
const INBOX_PROBE_WINDOW_SEC = 600;

function verifyInboxDelivery_() {
  let anywhere, inbox, trashed, spammed;
  const base = 'from:me subject:Stock-Trading after:' +
               (Math.floor(Date.now() / 1000) - INBOX_PROBE_WINDOW_SEC);
  try {
    // in:anywhere spans Trash and Spam, which GmailApp.search() otherwise excludes by default.
    anywhere = GmailApp.search(base + ' in:anywhere', 0, 5).length;
    if (!anywhere) {
      // Inconclusive: the message we just sent is not indexed yet (or search is degraded). Do NOT
      // touch the streak — treating a lagging index as a delivery failure is how this check would
      // turn into the noise that gets it ignored.
      Logger.log('inbox probe inconclusive: no indexed Stock-Trading mail in the last hour yet');
      return;
    }
    inbox   = GmailApp.search(base + ' in:inbox', 0, 5).length;
    trashed = GmailApp.search(base + ' in:trash', 0, 5).length;
    spammed = GmailApp.search(base + ' in:spam', 0, 5).length;
  } catch (e) {
    Logger.log('inbox probe skipped (Gmail search failed): ' + e);
    return; // never let the probe break a poll that already delivered
  }
  if (inbox > 0) {
    try {
      const props = PropertiesService.getScriptProperties();
      if (props.getProperty('inbox_fail_streak')) props.deleteProperty('inbox_fail_streak');
    } catch (e) { Logger.log('could not reset inbox_fail_streak: ' + e); }
    return;
  }
  // Positive misroute observation: indexed, but not in the Inbox.
  let streak = 0;
  try {
    const props = PropertiesService.getScriptProperties();
    streak = (parseInt(props.getProperty('inbox_fail_streak'), 10) || 0) + 1;
    props.setProperty('inbox_fail_streak', String(streak));
  } catch (e) {
    Logger.log('could not track inbox_fail_streak: ' + e);
    return; // without a durable streak we cannot tell a blip from an outage; stay quiet rather than spam
  }
  const where = trashed ? 'TRASH' : (spammed ? 'SPAM' : 'neither Inbox, Trash nor Spam (archived?)');
  Logger.log('inbox probe: sent mail landed in %s, not Inbox (streak %s)', where, streak);
  const due = (streak === INBOX_FAIL_ESCALATE_AFTER) ||
              (streak > INBOX_FAIL_ESCALATE_AFTER && streak % INBOX_FAIL_REESCALATE_EVERY === 0);
  if (!due) return;
  // FIXED MESSAGE — no streak, and no `where` either. sp_raise_alert_once dedups on exact
  // (category, message) while the prior row is unresolved, so ANY varying token defeats the collapse.
  // The streak is obvious; `where` is the subtle one: if the destination flips between escalations
  // (Trash emptied mid-outage, or mail starts landing in Spam instead) the text changes and a second
  // row opens. Both facts live in the payload, which is not part of the dedup key.
  const msg = 'Stock-Trading ALERT EMAIL IS NOT REACHING THE INBOX: alert emails are being accepted by ' +
              'Gmail and then routed away from the Inbox. Sending is healthy, so no delivery-failure ' +
              'alert fired and notified_ts was stamped normally - the alert channel is silently DARK. ' +
              'Check Gmail Settings > Filters and Blocked Addresses for a rule matching the self-send or ' +
              'the sender name, and check Trash for the missed alerts. Until it clears, read ops.alerts ' +
              'directly. See the payload for where the mail landed and the consecutive-misroute count.';
  // Channel: ops.alerts -> scripts/alert_relay.py -> ntfy push, entirely outside Apps Script and Gmail.
  // No direct-mail twin, by design.
  //
  // WHICH PROCEDURE, and why it is not always _once. sp_raise_alert_once is a pure conditional INSERT:
  // it will not re-raise, re-stamp or bump alert_ts while a matching unresolved row exists. alert_relay.py
  // only POSTs rows with alert_ts inside its ~35-minute window, so a _once-only design would ping ntfy
  // EXACTLY ONCE ever — in the ~35min after the first escalation, roughly 6h into an outage — and then
  // stay silent no matter how long the channel stayed dark, making INBOX_FAIL_REESCALATE_EVERY dead code.
  // So: the FIRST escalation uses _once (collapse onto one row if something already opened it), and the
  // periodic reminders use plain sp_raise_alert, whose fresh row is precisely what re-enters the relay
  // window and re-pings the phone. Roughly one extra row per day of a genuine outage, which is the
  // intended cost of not going quiet on the one failure that hides every other alert.
  const proc = (streak === INBOX_FAIL_ESCALATE_AFTER) ? 'sp_raise_alert_once' : 'sp_raise_alert';
  try {
    BigQuery.Jobs.query({
      query: `CALL \`${ALERT_PROJECT_ID}.ops.${proc}\`('warning','alert_emailer',` +
             `'alert_not_reaching_inbox','${msg.replace(/'/g, '')}',` +
             `TO_JSON_STRING(STRUCT(${streak} AS consecutive_misroutes, '${where}' AS landed_in, ` +
             `${trashed} AS trash_hits, ${spammed} AS spam_hits, ` +
             `'${ALERT_SCRIPT_VERSION}' AS script_version)))`,
      useLegacySql: false, timeoutMs: 30000
    }, ALERT_PROJECT_ID);
  } catch (e) { Logger.log('inbox-misroute alert raise failed: ' + e); }
}

function beat_(pollOk) {
  const note = (pollOk === false) ? 'poll-error' : 'poll';
  try {
    BigQuery.Jobs.query({
      query: `INSERT INTO \`${ALERT_PROJECT_ID}.ops.heartbeat\` (source, note, version) VALUES ('alert_emailer', '${note}', '${ALERT_SCRIPT_VERSION}')`,
      useLegacySql: false, timeoutMs: 30000
    }, ALERT_PROJECT_ID);
  } catch (e) { Logger.log('heartbeat write skipped: ' + e); }
}

// ===== BigQuery =====
function bqAlerts_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000, maxResults: 10000 }, ALERT_PROJECT_ID);
  let g = 0;
  while (!res.jobComplete && g++ < 10) { Utilities.sleep(1000); res = BigQuery.Jobs.getQueryResults(ALERT_PROJECT_ID, res.jobReference.jobId); }
  // A query that never completes must FAIL the send (no heartbeat -> dead-man's switch), not render empty.
  if (!res.jobComplete) throw new Error('BigQuery job did not complete after 10s poll: ' + sql.slice(0, 120));
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  const rows = res.rows || [];
  let pageToken = res.pageToken;
  while (pageToken) {
    const page = BigQuery.Jobs.getQueryResults(ALERT_PROJECT_ID, res.jobReference.jobId,
      { pageToken: pageToken, maxResults: 10000 });
    rows.push.apply(rows, page.rows || []);
    pageToken = page.pageToken;
  }
  return rows.map(r => { const o = {}; r.f.forEach((c, i) => o[fields[i]] = c.v); return o; });
}

// Detected DISPLAY timezone (state.user_tz — bigquery/20_user_prefs.sql). Purely cosmetic: it changes
// how a timestamp is RENDERED to the operator, never any alert logic. Falls back to America/Denver on
// any error so a BigQuery hiccup on this read can never block delivery.
let _alertTzCache = null;
function getUserTzAlerts_() {
  if (_alertTzCache) return _alertTzCache;
  try {
    _alertTzCache = (bqAlerts_(`SELECT tz FROM \`${ALERT_PROJECT_ID}.state.user_tz\``)[0] || {}).tz || 'America/Denver';
  } catch (e) {
    Logger.log('getUserTzAlerts_ failed, defaulting to America/Denver: ' + e);
    _alertTzCache = 'America/Denver';
  }
  return _alertTzCache;
}

function fmtAlertTs_(a) {
  const tz = getUserTzAlerts_();
  if (a.alert_ms != null) {
    return Utilities.formatDate(new Date(Number(a.alert_ms)), tz, 'MMM d, h:mm a') + ` (${tz})`;
  }
  return a.alert_ts + ' UTC';  // fallback if UNIX_MILLIS was unavailable
}

// ===== rendering =====
// KEEP IN SYNC MANUALLY with esc_() in ops/weekly_report/weekly_report.gs — byte-for-byte identical on
// purpose (separate Apps Script projects can't share a module), also copied verbatim into
// ops/weekly_report/test_pure_helpers.js. A future escaping fix (e.g. backticks for a template-literal
// context) applied to one twin must be applied to both, or one of the two operator-facing HTML emails
// silently stops getting it (2026-07-09 code-review finding).
function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

// Parse an alert's payload JSON defensively (v5). ops.alerts.payload is free-shape JSON authored by
// routines from prose, so key drift and malformed payloads are the EXPECTED steady state, not the
// exception (this is the same reasoning bigquery/130 used when it made Rule 1 tolerant of payload-key
// aliases rather than trying to enforce one canonical key). Every caller here treats the payload as
// enrichment only: on NULL/absent/corrupt input this returns {}, each renderer omits the fields it
// cannot find, and the alert still delivers with its message string intact. A payload must never be
// able to suppress an alert email.
function pl_(a) {
  try {
    const o = JSON.parse((a && a.payload) || '{}');
    return (o && typeof o === 'object') ? o : {};
  } catch (e) { return {}; }
}

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
// v5 adds payload.synthetic: the fire drills (ops.sp_fire_drill_roster_notice, and any future drill
// following the same convention) insert a synthetic row, call the real resolver, and delete it again
// within one procedure. That window is milliseconds wide but nonzero, so a 2-hourly poll CAN in
// principle land inside it — and a drill row in the roster categories would otherwise render as a
// fabricated "strategy ZZ entered PROBE" notice. Matching on payload.synthetic rather than on a source
// prefix is deliberate: a drill FAILURE alert (roster_notice_fire_drill_failed, alert_latch_fire_drill_failed,
// alert_resolve_fire_drill_failed) is a genuine critical incident raised by the same procedures, and
// carries no synthetic key — so it correctly stays a real alert.
function isTest_(a) {
  if (a.source === 'scheduled.canary' || a.category === 'delivery_canary') return true;
  return pl_(a).synthetic === true;
}

// ===== roster-change notices (v5) =====
// A roster notice reports a COMPLETED autonomous action, not a problem. Strategy add/drop has had no
// human approval step since the 2026-07-10 SISA conversion and this channel does not reintroduce one —
// it exists so the owner LEARNS of a roster change instead of having to query state.strategy_roster.
function isRosterNotice_(a) { return ROSTER_NOTICE_CATEGORIES.indexOf(a.category) !== -1; }

// A roster notice that is not itself a fire-drill row. Used everywhere the two lanes are split, so a
// synthetic drill row stays in the TEST lane instead of being rendered as a real roster change.
function isRealRosterNotice_(a) { return !isTest_(a) && isRosterNotice_(a); }

// One-line headline for the subject, e.g. "F PAPER→PROBE". Falls back through progressively less
// specific forms so a payload-less notice still produces something meaningful.
function rosterHeadline_(a) {
  const p = pl_(a);
  // Stripped of CR/LF because this is the ONLY payload-derived value that reaches the email SUBJECT
  // (everything else payload-derived is confined to the escaped HTML body). A stray newline in a
  // subject is a header-injection shape; these fields are short system tokens today, but the payload
  // is routine-authored free-shape JSON, so do not rely on that.
  const clean = s => String(s).replace(/[\r\n]+/g, ' ').trim();
  if (p.strategy_code && p.from_state && p.to_state) return `${clean(p.strategy_code)} ${clean(p.from_state)}→${clean(p.to_state)}`;
  if (p.strategy_code) return `${clean(p.strategy_code)} · ${a.category}`;
  return a.category;
}

// Money/percent formatting without locale APIs (Apps Script's locale is the script's, not the reader's).
function money_(v) {
  const n = Number(v);
  if (!isFinite(n)) return String(v);
  return '$' + Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Ordered [label, value] pairs for the fields the ROSTER-CHANGE NOTICE contract defines
// (Claude_Task_Plan.md preamble). Missing keys are omitted rather than rendered blank, so a partial
// payload degrades gracefully instead of producing a card full of empty rows.
function rosterDetail_(a) {
  const p = pl_(a);
  const out = [];
  const push = (label, v) => {
    if (v === undefined || v === null || String(v) === '') return;
    out.push([label, String(v)]);
  };
  push('Strategy', [p.strategy_code, p.strategy_name].filter(x => x !== undefined && x !== null && x !== '').join(' — '));
  if (p.from_state && p.to_state) push('Transition', `${p.from_state} → ${p.to_state}`);
  if (p.roster_active_before !== undefined && p.roster_active_after !== undefined) {
    push('Roster active', `${p.roster_active_before} → ${p.roster_active_after}`);
  }
  if (p.capital_usd !== undefined && p.capital_usd !== null) {
    const pct = (p.pct_nav !== undefined && p.pct_nav !== null && String(p.pct_nav) !== '') ? ` (${p.pct_nav}% NAV)` : '';
    push('Capital', Number(p.capital_usd) === 0 ? 'none — zero capital at risk' : money_(p.capital_usd) + pct);
  }
  push('Trigger', p.kill_trigger);
  push('Why', p.reason);
  push('Commit', p.git_commit);
  return out;
}

// Email subject for one poll batch. `fresh` = alerts newly notified this poll (real incidents +
// any canary); `recurringCount` = the count of non-duplicate recurring termination_close_staged
// re-sends riding in the same batch (combined.length - fresh.length). Computed ONCE by the caller
// (checkAlerts_) and passed in — NOT re-derived from a `combined` array here — so this count can never
// diverge from what htmlAlerts_/plainAlerts_/the Logger.log line report for the same poll (2026-07-29
// collapse; this had already drifted once, see bigquery/43's git_note). "new" must count only
// genuinely-new alerts (from `fresh`), NOT the recurring re-sends — otherwise the subject over-reports
// new incidents (e.g. "3 new" when 2 are new + 1 is a recurring re-notify) and mis-attributes the
// recurring critical to the "(N critical)" new-count. Pure (no Apps-Script-service calls) — mirrored
// verbatim in ops/weekly_report/test_pure_helpers.js; keep both in sync.
function alertSubject_(fresh, recurringCount) {
  const rosterNew = fresh.filter(isRealRosterNotice_);                        // completed autonomous roster changes
  const newReal = fresh.filter(r => !isTest_(r) && !isRosterNotice_(r));      // genuinely new, non-test INCIDENTS
  const testCount = fresh.length - newReal.length - rosterNew.length;         // test canaries + synthetic drill rows
  if (newReal.length === 0 && recurringCount === 0 && rosterNew.length === 0) {
    // Batch is ONLY the alert-delivery self-test → unmistakable test subject, no ⚠.
    return '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed';
  }
  if (newReal.length === 0 && recurringCount === 0) {
    // Batch is ONLY roster changes (the common case — the rails rate-limit these to roughly 5-12/year,
    // and they rarely coincide with an incident). A completed autonomous action is not a fault, so this
    // subject deliberately carries no ⚠ and does not say ALERT: an operator emailed "⚠ ALERT" every time
    // the system does something healthy and expected stops reading the channel, which would undermine
    // the genuine alerts that share it.
    const label = rosterNew.length === 1
      ? `ROSTER CHANGE: ${rosterHeadline_(rosterNew[0])}`
      : `${rosterNew.length} ROSTER CHANGES`;
    return `📋 Stock-Trading — ${label}` + (testCount ? ` (+${testCount} test)` : '');
  }
  // Mixed batch: an incident outranks a roster change, so the ⚠ subject leads and roster changes are
  // appended as a count. They are NOT folded into the "N new" figure — that figure means incidents, and
  // inflating it with healthy roster events would repeat the 2026-07-29 over-reporting bug in a new form.
  const crit = newReal.filter(r => r.severity === 'critical').length;
  return '⚠ Stock-Trading ALERT' +
            (newReal.length ? ` — ${newReal.length} new${crit ? ` (${crit} critical)` : ''}` : '') +
            (recurringCount ? ` — ${recurringCount} UNCONFIRMED TERMINATION CLOSE (recurring)` : '') +
            (rosterNew.length ? ` — +${rosterNew.length} roster change${rosterNew.length > 1 ? 's' : ''}` : '') +
            (testCount ? ` (+${testCount} test)` : '');
}

function htmlAlerts_(batch, newlyUnnotifiedCount, recurringCount) {
  const allTest = batch.length > 0 && batch.every(isTest_);
  const roster = batch.filter(isRealRosterNotice_);
  const incidents = batch.filter(a => !isRealRosterNotice_(a));
  // realIncidents excludes canary/fire-drill rows. The HEADER must key on this, not on
  // incidents.length: a batch of {real roster notice + weekly canary} has incidents.length === 1, which
  // would print the "⚠ unresolved alerts" header under a subject that correctly reads
  // "📋 ROSTER CHANGE" — the exact alarming-framing-for-a-healthy-event this lane exists to prevent.
  // alertSubject_ already filters tests out via isTest_; this keeps the two in agreement.
  const realIncidents = incidents.filter(a => !isTest_(a));
  // Payload rendering is the only part of this file that parses routine-authored free-shape JSON, so
  // it is the only part with a plausible unknown-unknown. It is fenced off because the outer catch in
  // checkAlerts_ swallows exceptions and beat_() still stamps a fresh beat_ts — meaning a PERSISTENT
  // throw anywhere in this function would silently stop ALL alert delivery forever while
  // state.automation_heartbeat (which reads only MAX(beat_ts), never the note) stays green. Degrading
  // one roster card to message-only is always preferable to blacking out the whole channel.
  let rosterHtml;
  try {
    rosterHtml = roster.map(a => {
      const detail = rosterDetail_(a).map(kv =>
        `<tr><td style="font-size:12px;color:#5b6b7a;padding:1px 10px 1px 0;white-space:nowrap;vertical-align:top;">${esc2_(kv[0])}</td>` +
        `<td style="font-size:12px;color:#1f2d3d;padding:1px 0;">${esc2_(kv[1])}</td></tr>`).join('');
      return `<tr><td style="padding:0;">
      <div style="border-left:4px solid #1e7f5c;background-color:#eaf6f0;border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:#1e7f5c;">ROSTER CHANGE · ${esc2_(a.source)} · ${esc2_(a.category)}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        ${detail ? `<table role="presentation" cellpadding="0" cellspacing="0" style="margin-top:7px;">${detail}</table>` : ''}
        <div style="font-size:11px;color:#8a96a3;margin-top:5px;">${esc2_(fmtAlertTs_(a))}</div>
      </div></td></tr>`;
    }).join('');
  } catch (e) {
    rosterHtml = roster.map(a => `<tr><td style="padding:0;">
      <div style="border-left:4px solid #1e7f5c;background-color:#eaf6f0;border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:#1e7f5c;">ROSTER CHANGE · ${esc2_(a.source)} · ${esc2_(a.category)}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:5px;">(detail unavailable — payload render failed: ${esc2_(String(e))})</div>
      </div></td></tr>`).join('');
  }
  const rosterSection = roster.length ? `
      <tr><td style="font-size:14px;font-weight:700;color:#1e7f5c;padding:12px 0 2px;">📋 Autonomous roster change${roster.length > 1 ? 's' : ''} — no action needed</td></tr>
      ${rosterHtml}
      <tr><td style="font-size:11px;color:#8a96a3;padding-top:6px;">Strategy add/drop is fully autonomous by design (SISA, owner directive 2026-07-10) — this is a notification, not a request. These notices resolve themselves once delivered, so no <code>UPDATE ops.alerts</code> is needed. Full history: <code>state.strategy_roster</code>, <code>ops.roster_change_log</code>, <code>events.strategy_lifecycle</code>. To pause the whole add/drop loop: INSERT an <code>enabled = FALSE</code> row into <code>ops.arsenal_control</code> — live trading is unaffected.</td></tr>` : '';
  const rowsHtml = incidents.map(a => {
    const test = isTest_(a);
    const isCrit = a.severity === 'critical';
    const bar = test ? '#2c6e9b' : (isCrit ? '#c0392b' : '#b9770e');
    const bg  = test ? '#eaf2f8' : (isCrit ? '#fcebea' : '#fdf3e3');
    const tag = test
      ? ' · <span style="color:#2c6e9b;font-weight:700;">⚗ TEST — no action needed</span>'
      : ((String(a.resolved) === 'true')
          ? (String(a.resolved_note || '').startsWith('auto-resolved:')
              ? ' · <span style="color:#2e7d32;">AUTO-RESOLVED</span>'
              : ' · <span style="color:#2e7d32;">RESOLVED</span>')
          : '');
    return `<tr><td style="padding:0;">
      <div style="border-left:4px solid ${bar};background-color:${bg};border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:${bar};">${esc2_(a.severity.toUpperCase())} · ${esc2_(a.source)} · ${esc2_(a.category)}${tag}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:3px;">${esc2_(fmtAlertTs_(a))}</div>
      </div></td></tr>`;
  }).join('');
  const header = allTest
    ? '⚗ Stock-Trading — alert-delivery self-test (TEST · no action needed)'
    : (realIncidents.length === 0 && recurringCount === 0
        ? `📋 Stock-Trading — autonomous roster change${roster.length > 1 ? 's' : ''}`
        : '⚠ Stock-Trading — unresolved alerts');
  // The incident section is suppressed entirely on a roster-only batch, so a healthy autonomous action
  // never renders under an "unresolved alerts" heading with a resolve-by-hand instruction that does not
  // apply to it (Rule 5 clears these on delivery).
  const incidentSection = incidents.length ? `
      ${rowsHtml}
      <tr><td style="font-size:11px;color:#8a96a3;padding-top:10px;">This section contains ${incidents.length} alert(s): ${newlyUnnotifiedCount - roster.length} newly un-notified in the last ${LOOKBACK_LABEL} and ${recurringCount} recurring.${roster.length ? ` ${roster.length} roster change(s) follow below and need no action.` : ''} Resolve via <code>UPDATE ops.alerts SET resolved=TRUE WHERE alert_id='...'</code> — always scope by alert_id, never run this unfiltered. This channel complements the [Claude] ATTENTION calendar events.</td></tr>` : '';
  return `<!DOCTYPE html><html><body style="margin:0;padding:18px;background-color:#eef1f5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:auto;background:#fff;border-radius:12px;padding:18px;">
      <tr><td style="font-size:16px;font-weight:700;color:#0f2747;padding-bottom:8px;">${header}</td></tr>
      ${incidentSection}
      ${rosterSection}
    </table></body></html>`;
}

function plainAlerts_(batch, newlyUnnotifiedCount, recurringCount) {
  const allTest = batch.length > 0 && batch.every(isTest_);
  const roster = batch.filter(isRealRosterNotice_);
  const incidents = batch.filter(a => !isRealRosterNotice_(a));
  const realIncidents = incidents.filter(a => !isTest_(a));   // see htmlAlerts_ for why the header keys on this
  let s = allTest
    ? `[TEST] Stock-Trading — alert-delivery self-test, no action needed:\n\n`
    : (realIncidents.length === 0 && recurringCount === 0
        ? `Stock-Trading — ${roster.length} autonomous roster change(s), no action needed:\n\n`
        : `Stock-Trading — ${incidents.length} alert(s) (${newlyUnnotifiedCount - roster.length} newly un-notified in the last ${LOOKBACK_LABEL}, ${recurringCount} recurring)${roster.length ? ` + ${roster.length} roster change(s) below` : ''}:\n\n`);
  incidents.forEach(a => {
    const tag = isTest_(a) ? '[TEST] '
      : (String(a.resolved) === 'true'
          ? (String(a.resolved_note || '').startsWith('auto-resolved:') ? '[AUTO-RESOLVED] ' : '[RESOLVED] ')
          : '');
    s += `[${a.severity.toUpperCase()}] ${tag}${a.source}/${a.category}: ${a.message}  (${fmtAlertTs_(a)})\n`;
  });
  if (incidents.length) {
    s += `\nResolve via UPDATE ops.alerts SET resolved=TRUE WHERE alert_id='...' — always scope by alert_id, never run this unfiltered. Complements the [Claude] ATTENTION calendar events.\n`;
  }
  if (roster.length) {
    s += `\n=== ROSTER CHANGE${roster.length > 1 ? 'S' : ''} (no action needed) ===\n`;
    roster.forEach(a => {
      s += `\n[ROSTER CHANGE] ${a.source}/${a.category}: ${a.message}  (${fmtAlertTs_(a)})\n`;
      rosterDetail_(a).forEach(kv => { s += `    ${kv[0]}: ${kv[1]}\n`; });
    });
    s += `\nStrategy add/drop is fully autonomous by design (SISA, owner directive 2026-07-10) — this is a notification, not a request. These notices resolve themselves once delivered; no UPDATE is needed. Full history: state.strategy_roster, ops.roster_change_log, events.strategy_lifecycle. To pause the whole add/drop loop: INSERT an enabled = FALSE row into ops.arsenal_control — live trading is unaffected.`;
  }
  return s;
}

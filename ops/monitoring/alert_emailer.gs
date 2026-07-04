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
 * AUTO-RESOLVED so you know it self-healed. (RUNBOOK §20 / §25.)
 *
 * Like the weekly report, it runs on Google's servers as you (from you, to you): no SMTP, app
 * password, or API key. It de-dupes via Script Properties so you're emailed ONCE per alert,
 * not every run, and it tells you when previously-open alerts have been resolved.
 *
 * SETUP (one time): same as the weekly report (ops/weekly_report/README.md) — new script.google.com
 * project (or a second file in the same project), add the BigQuery advanced service, set RECIPIENT,
 * run testAlertCheck() once to authorize, then run installAlertTrigger() to schedule it.
 */

// ===== CONFIG =====
const ALERT_PROJECT_ID = 'stock-trading-498512';
const ALERT_RECIPIENT  = Session.getActiveUser().getEmail(); // self-email
const ALERT_SENDER     = 'Stock-Trading Alerts';
const SEVERITIES       = ['critical', 'warning']; // set to ['critical'] for criticals only
const POLL_HOURS       = 2;                        // how often to check
// LOOKBACK_HOURS bounds the notified_ts IS NULL scan. Was 48h — if the emailer itself is dead longer
// than the lookback (revoked token / deleted trigger), alerts raised early in the outage permanently
// keep notified_ts NULL and are never emailed by ANY code path on recovery (the webhook relay's window
// is only ~35min and non-email; the delivery canary only proves the channel, it doesn't backfill).
// The automation_heartbeat dead-man's switch fires at 8h of silence, so 168h (1 week) gives ample
// margin for any realistic recovery lag at negligible extra query cost (2026-07 report-system fix).
const LOOKBACK_HOURS   = 168;

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
  try {
    const sevList = SEVERITIES.map(s => `'${s}'`).join(',');
    // NOTIFICATION-COMPLETE: select un-notified alerts (notified_ts IS NULL), NOT `NOT resolved`, so an
    // alert that self-healed between polls is still emailed exactly once. notified_ts is the durable
    // de-dup; Script Properties is a secondary guard so a failed stamp doesn't re-send next poll.
    // alert_ms (UNIX_MILLIS) lets the renderer format alert_ts in the DETECTED display timezone
    // (state.user_tz) instead of raw unlabeled UTC — alert_ts (STRING) is kept too as a UTC fallback.
    const rows = bqAlerts_(`
      SELECT alert_id, CAST(alert_ts AS STRING) AS alert_ts, UNIX_MILLIS(alert_ts) AS alert_ms,
             severity, source, category, message, resolved
      FROM \`${ALERT_PROJECT_ID}.ops.alerts\`
      WHERE notified_ts IS NULL AND severity IN (${sevList})
        AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${LOOKBACK_HOURS} HOUR)
      ORDER BY alert_ts DESC
      LIMIT 500`);

    const props = PropertiesService.getScriptProperties();
    const seen = new Set(JSON.parse(props.getProperty('notified_alert_ids') || '[]'));
    const fresh = rows.filter(r => !seen.has(r.alert_id));

    if (fresh.length) {
      // Split the alert-delivery self-test (canary) from real alerts so a weekly probe is never
      // disguised as an incident in the subject — and, conversely, a real alert that happens to ride
      // in the same poll batch is never softened to "[TEST]". (RUNBOOK §15 / delivery_canary.sql.)
      const realFresh = fresh.filter(r => !isTest_(r));
      const testCount = fresh.length - realFresh.length;
      let subject;
      if (realFresh.length === 0) {
        // Batch is ONLY the alert-delivery self-test → unmistakable test subject, no ⚠.
        subject = '🧪 [TEST] Stock-Trading alert-delivery self-test — no action needed';
      } else {
        const crit = realFresh.filter(r => r.severity === 'critical').length;
        subject = `⚠ Stock-Trading ALERT — ${realFresh.length} new${crit ? ` (${crit} critical)` : ''}` +
                  (testCount ? ` (+${testCount} test)` : '');
      }
      GmailApp.sendEmail(ALERT_RECIPIENT, subject, plainAlerts_(fresh, rows.length),
        { htmlBody: htmlAlerts_(fresh, rows.length), name: ALERT_SENDER });
      Logger.log('Emailed %s new alerts', fresh.length);
      stampNotified_(fresh.map(r => r.alert_id));
      // Bounded de-dup guard for ids we just emailed (in case the notified_ts stamp failed).
      const keep = [...seen, ...fresh.map(r => r.alert_id)].slice(-500);
      try {
        props.setProperty('notified_alert_ids', JSON.stringify(keep));
      } catch (e) { Logger.log('notified_alert_ids property write skipped: ' + e); }
    } else {
      Logger.log('No un-notified alerts in the last %s h', LOOKBACK_HOURS);
    }
  } catch (e) {
    Logger.log('checkAlerts_ query failed (BigQuery quota or transient error?) — skipping this cycle: ' + e);
  }

  // Liveness beat (ops.heartbeat -> state.automation_heartbeat). Lets cadence_check.sql detect a
  // SILENTLY-DEAD emailer (revoked token / deleted trigger) via the independent DTS failure-email —
  // a dead emailer obviously can't email that it is dead. Best-effort: never block the run on it.
  // Runs regardless of the try/catch above (outside it) so a query-level failure never also
  // suppresses the heartbeat.
  beat_();
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
function beat_() {
  try {
    BigQuery.Jobs.query({
      query: `INSERT INTO \`${ALERT_PROJECT_ID}.ops.heartbeat\` (source, note) VALUES ('alert_emailer', 'poll')`,
      useLegacySql: false, timeoutMs: 30000
    }, ALERT_PROJECT_ID);
  } catch (e) { Logger.log('heartbeat write skipped: ' + e); }
}

// ===== BigQuery =====
function bqAlerts_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000 }, ALERT_PROJECT_ID);
  let g = 0;
  while (!res.jobComplete && g++ < 10) { Utilities.sleep(1000); res = BigQuery.Jobs.getQueryResults(ALERT_PROJECT_ID, res.jobReference.jobId); }
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  return (res.rows || []).map(r => { const o = {}; r.f.forEach((c, i) => o[fields[i]] = c.v); return o; });
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
function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
function isTest_(a) { return a.source === 'scheduled.canary' || a.category === 'delivery_canary'; }

function htmlAlerts_(fresh, totalOpen) {
  const allTest = fresh.length > 0 && fresh.every(isTest_);
  const rowsHtml = fresh.map(a => {
    const test = isTest_(a);
    const isCrit = a.severity === 'critical';
    const bar = test ? '#2c6e9b' : (isCrit ? '#c0392b' : '#b9770e');
    const bg  = test ? '#eaf2f8' : (isCrit ? '#fcebea' : '#fdf3e3');
    const tag = test
      ? ' · <span style="color:#2c6e9b;font-weight:700;">🧪 TEST — no action needed</span>'
      : ((String(a.resolved) === 'true') ? ' · <span style="color:#2e7d32;">AUTO-RESOLVED</span>' : '');
    return `<tr><td style="padding:0;">
      <div style="border-left:4px solid ${bar};background-color:${bg};border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:${bar};">${esc2_(a.severity.toUpperCase())} · ${esc2_(a.source)} · ${esc2_(a.category)}${tag}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:3px;">${esc2_(fmtAlertTs_(a))}</div>
      </div></td></tr>`;
  }).join('');
  const header = allTest
    ? '🧪 Stock-Trading — alert-delivery self-test (TEST · no action needed)'
    : '⚠ Stock-Trading — unresolved alerts';
  return `<!DOCTYPE html><html><body style="margin:0;padding:18px;background-color:#eef1f5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:auto;background:#fff;border-radius:12px;padding:18px;">
      <tr><td style="font-size:16px;font-weight:700;color:#0f2747;padding-bottom:8px;">${header}</td></tr>
      ${rowsHtml}
      <tr><td style="font-size:11px;color:#8a96a3;padding-top:10px;">${totalOpen} un-notified alert(s) in the last week. Resolve via <code>UPDATE ops.alerts SET resolved=TRUE …</code>. This channel complements the [Claude] ATTENTION calendar events.</td></tr>
    </table></body></html>`;
}

function plainAlerts_(fresh, totalOpen) {
  const allTest = fresh.length > 0 && fresh.every(isTest_);
  let s = allTest
    ? `[TEST] Stock-Trading — alert-delivery self-test, no action needed:\n\n`
    : `Stock-Trading — ${fresh.length} new unresolved alert(s) (${totalOpen} un-notified in the last week):\n\n`;
  fresh.forEach(a => {
    const tag = isTest_(a) ? '[TEST] ' : (String(a.resolved) === 'true' ? '[AUTO-RESOLVED] ' : '');
    s += `[${a.severity.toUpperCase()}] ${tag}${a.source}/${a.category}: ${a.message}  (${fmtAlertTs_(a)})\n`;
  });
  s += `\nResolve via UPDATE ops.alerts SET resolved=TRUE WHERE ... . Complements the [Claude] ATTENTION calendar events.`;
  return s;
}

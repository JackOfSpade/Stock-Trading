/**
 * Stock-Trading — Alert emailer (real-time-ish alert delivery, self-email).
 * =========================================================================
 * Fixes "alerts are unmonitored between routines" (A2). ops.alerts is the durable hard-stop /
 * anomaly sink (cash tripwire, dual-path disagreement, embedding unhealthy, stale data, missed
 * order confirmation, ...). Routines also create [Claude] ATTENTION calendar events, but a
 * calendar entry is easy to miss. This Apps Script polls ops.alerts on a short trigger (e.g.
 * every 2 hours) and EMAILS you the moment a new unresolved critical (or warning) appears —
 * a genuine push channel, with no Cloud Monitoring / Pub/Sub console wiring.
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
  const sevList = SEVERITIES.map(s => `'${s}'`).join(',');
  const rows = bqAlerts_(`
    SELECT alert_id, CAST(alert_ts AS STRING) AS alert_ts, severity, source, category, message
    FROM \`${ALERT_PROJECT_ID}.ops.alerts\`
    WHERE NOT resolved AND severity IN (${sevList})
    ORDER BY alert_ts DESC`);

  const props = PropertiesService.getScriptProperties();
  const seen = new Set(JSON.parse(props.getProperty('notified_alert_ids') || '[]'));
  const currentIds = rows.map(r => r.alert_id);
  const fresh = rows.filter(r => !seen.has(r.alert_id));
  const resolvedCount = [...seen].filter(id => !currentIds.includes(id)).length;

  if (fresh.length) {
    const crit = fresh.filter(r => r.severity === 'critical').length;
    const subject = `⚠ Stock-Trading ALERT — ${fresh.length} new${crit ? ` (${crit} critical)` : ''}`;
    GmailApp.sendEmail(ALERT_RECIPIENT, subject, plainAlerts_(fresh, rows.length),
      { htmlBody: htmlAlerts_(fresh, rows.length), name: ALERT_SENDER });
    Logger.log('Emailed %s new alerts', fresh.length);
  } else {
    Logger.log('No new alerts (%s open, %s resolved since last run)', rows.length, resolvedCount);
  }
  // Persist the current open set so resolved alerts can re-fire later if reopened.
  props.setProperty('notified_alert_ids', JSON.stringify(currentIds));
}

// ===== BigQuery =====
function bqAlerts_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000 }, ALERT_PROJECT_ID);
  let g = 0;
  while (!res.jobComplete && g++ < 10) { Utilities.sleep(1000); res = BigQuery.Jobs.getQueryResults(ALERT_PROJECT_ID, res.jobReference.jobId); }
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  return (res.rows || []).map(r => { const o = {}; r.f.forEach((c, i) => o[fields[i]] = c.v); return o; });
}

// ===== rendering =====
function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

function htmlAlerts_(fresh, totalOpen) {
  const rowsHtml = fresh.map(a => {
    const isCrit = a.severity === 'critical';
    const bar = isCrit ? '#c0392b' : '#b9770e';
    return `<tr><td style="padding:0;">
      <div style="border-left:4px solid ${bar};background-color:${isCrit ? '#fcebea' : '#fdf3e3'};border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:${bar};">${esc2_(a.severity.toUpperCase())} · ${esc2_(a.source)} · ${esc2_(a.category)}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:3px;">${esc2_(a.alert_ts)} UTC</div>
      </div></td></tr>`;
  }).join('');
  return `<!DOCTYPE html><html><body style="margin:0;padding:18px;background-color:#eef1f5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:auto;background:#fff;border-radius:12px;padding:18px;">
      <tr><td style="font-size:16px;font-weight:700;color:#0f2747;padding-bottom:8px;">⚠ Stock-Trading — unresolved alerts</td></tr>
      ${rowsHtml}
      <tr><td style="font-size:11px;color:#8a96a3;padding-top:10px;">${totalOpen} total open alert(s) in ops.alerts. Resolve via <code>UPDATE ops.alerts SET resolved=TRUE …</code>. This channel complements the [Claude] ATTENTION calendar events.</td></tr>
    </table></body></html>`;
}

function plainAlerts_(fresh, totalOpen) {
  let s = `Stock-Trading — ${fresh.length} new unresolved alert(s) (${totalOpen} open total):\n\n`;
  fresh.forEach(a => { s += `[${a.severity.toUpperCase()}] ${a.source}/${a.category}: ${a.message}  (${a.alert_ts} UTC)\n`; });
  s += `\nResolve via UPDATE ops.alerts SET resolved=TRUE WHERE ... . Complements the [Claude] ATTENTION calendar events.`;
  return s;
}

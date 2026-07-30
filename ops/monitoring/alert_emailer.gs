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
const ALERT_SCRIPT_VERSION = 'v4';                 // bump on every functional change to this file; read by state.script_version_drift (bigquery/43_script_version_registry.sql) -- keep bigquery/43's MERGE seed in lockstep. Named ALERT_SCRIPT_VERSION (not SCRIPT_VERSION) because this file and weekly_report.gs share ONE Apps Script project's top-level scope -- a same-named const in both would throw a project-wide SyntaxError on the next paste (2026-07-14 audit finding).
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
    const rows = bqAlerts_(`
      SELECT alert_id, CAST(alert_ts AS STRING) AS alert_ts, UNIX_MILLIS(alert_ts) AS alert_ms,
             severity, source, category, message, resolved
      FROM \`${ALERT_PROJECT_ID}.ops.alerts\`
      WHERE notified_ts IS NULL AND severity IN (${sevList})
        AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${LOOKBACK_HOURS} HOUR)
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
               severity, source, category, message, resolved
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
    } else {
      Logger.log('No un-notified alerts in the last %s h', LOOKBACK_HOURS);
    }
    pollOk = true;
  } catch (e) {
    Logger.log('checkAlerts_ query failed (BigQuery quota or transient error?) — skipping this cycle: ' + e);
  } finally {
    lock.releaseLock();
  }

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

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
function isTest_(a) { return a.source === 'scheduled.canary' || a.category === 'delivery_canary'; }

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
  const newReal = fresh.filter(r => !isTest_(r));         // genuinely new, non-test alerts this poll
  const testCount = fresh.length - newReal.length;         // test canaries among the new alerts
  if (newReal.length === 0 && recurringCount === 0) {
    // Batch is ONLY the alert-delivery self-test → unmistakable test subject, no ⚠.
    return '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed';
  }
  const crit = newReal.filter(r => r.severity === 'critical').length;
  return '⚠ Stock-Trading ALERT' +
            (newReal.length ? ` — ${newReal.length} new${crit ? ` (${crit} critical)` : ''}` : '') +
            (recurringCount ? ` — ${recurringCount} UNCONFIRMED TERMINATION CLOSE (recurring)` : '') +
            (testCount ? ` (+${testCount} test)` : '');
}

function htmlAlerts_(batch, newlyUnnotifiedCount, recurringCount) {
  const allTest = batch.length > 0 && batch.every(isTest_);
  const rowsHtml = batch.map(a => {
    const test = isTest_(a);
    const isCrit = a.severity === 'critical';
    const bar = test ? '#2c6e9b' : (isCrit ? '#c0392b' : '#b9770e');
    const bg  = test ? '#eaf2f8' : (isCrit ? '#fcebea' : '#fdf3e3');
    const tag = test
      ? ' · <span style="color:#2c6e9b;font-weight:700;">⚗ TEST — no action needed</span>'
      : ((String(a.resolved) === 'true') ? ' · <span style="color:#2e7d32;">AUTO-RESOLVED</span>' : '');
    return `<tr><td style="padding:0;">
      <div style="border-left:4px solid ${bar};background-color:${bg};border-radius:6px;padding:10px 12px;margin:6px 0;">
        <div style="font-size:13px;font-weight:700;color:${bar};">${esc2_(a.severity.toUpperCase())} · ${esc2_(a.source)} · ${esc2_(a.category)}${tag}</div>
        <div style="font-size:13px;color:#1f2d3d;margin-top:3px;">${esc2_(a.message)}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:3px;">${esc2_(fmtAlertTs_(a))}</div>
      </div></td></tr>`;
  }).join('');
  const header = allTest
    ? '⚗ Stock-Trading — alert-delivery self-test (TEST · no action needed)'
    : '⚠ Stock-Trading — unresolved alerts';
  return `<!DOCTYPE html><html><body style="margin:0;padding:18px;background-color:#eef1f5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:auto;background:#fff;border-radius:12px;padding:18px;">
      <tr><td style="font-size:16px;font-weight:700;color:#0f2747;padding-bottom:8px;">${header}</td></tr>
      ${rowsHtml}
      <tr><td style="font-size:11px;color:#8a96a3;padding-top:10px;">This email contains ${batch.length} alert(s): ${newlyUnnotifiedCount} newly un-notified in the last ${LOOKBACK_LABEL} and ${recurringCount} recurring. Resolve via <code>UPDATE ops.alerts SET resolved=TRUE WHERE alert_id='...'</code> — always scope by alert_id, never run this unfiltered. This channel complements the [Claude] ATTENTION calendar events.</td></tr>
    </table></body></html>`;
}

function plainAlerts_(batch, newlyUnnotifiedCount, recurringCount) {
  const allTest = batch.length > 0 && batch.every(isTest_);
  let s = allTest
    ? `[TEST] Stock-Trading — alert-delivery self-test, no action needed:\n\n`
    : `Stock-Trading — ${batch.length} alert(s) (${newlyUnnotifiedCount} newly un-notified in the last ${LOOKBACK_LABEL}, ${recurringCount} recurring):\n\n`;
  batch.forEach(a => {
    const tag = isTest_(a) ? '[TEST] ' : (String(a.resolved) === 'true' ? '[AUTO-RESOLVED] ' : '');
    s += `[${a.severity.toUpperCase()}] ${tag}${a.source}/${a.category}: ${a.message}  (${fmtAlertTs_(a)})\n`;
  });
  s += `\nResolve via UPDATE ops.alerts SET resolved=TRUE WHERE alert_id='...' — always scope by alert_id, never run this unfiltered. Complements the [Claude] ATTENTION calendar events.`;
  return s;
}

/**
 * Stock-Trading — Weekly System Report (self-email, fully automatic).
 * =================================================================
 * Runs on GOOGLE'S servers (Apps Script), NOT on Claude's remote-routine server and
 * NOT via the Gmail connector. The official Gmail connector can only DRAFT, not send —
 * so weekly delivery is owned by this script instead. Because you are both sender and
 * recipient (from you, to you), Apps Script is the ideal tool: it runs AS YOU, so
 * GmailApp.sendEmail() needs no SMTP server, no app password, no API key, and no
 * separate sender identity. It builds the HTML and sends in one shot — nothing ever
 * lands in Drafts.
 *
 * DATA: read straight from BigQuery (project stock-trading-498512) — the same views the
 * trading routines maintain. No Claude involvement at send time.
 *   - analytics.strategy_scorecard   (per-strategy activation + budget + deployed-TWR + 7d-Δ)
 *   - state.current_regime           (regime axes + technical signals)
 *   - state.system_health            (green/red ops rollup)
 *   - state.account_latest           (account NAV / cash / TWR — written daily by D2 Step 0b)
 *   - state.account_nav_7d_ago       (exact 7-day-ago NAV for a flow-immune dollar delta)
 *   - analytics.account_reconciliation (NAV fallback if no snapshot yet)
 *   - analytics.weekly_activity      (last-7-day fills / GO / NO-GO / pending)
 *   - analytics.weekly_fills / analytics.weekly_nogos (detail lists)
 *   - state.open_positions_summary   (current book)
 *   - state.next_7_days              (forward-looking queue/exit/order-window items)
 *   - state.automation_heartbeat / state.backup_health / state.ops_backup_health / state.cadence_watch
 *   - state.user_tz                  (detected DISPLAY timezone — never the operating/trading-day tz)
 *
 * SETUP (one time, ~3 min) — see ops/weekly_report/README.md:
 *   1. script.google.com → New project → paste this file.
 *   2. Project Settings → check "Show appsscript.json"; ensure V8 runtime (default).
 *   3. Editor → Services (+) → add "BigQuery API" (identifier: BigQuery).
 *   4. Set RECIPIENT below to your address (defaults to the project owner's email).
 *   5. Run testReport() once → authorize the BigQuery + Gmail scopes when prompted →
 *      confirm the email arrives.
 *   6. Run installWeeklyTrigger() once → installs the Sunday 07:00 (script tz) trigger.
 * That's it. It now emails you every week forever.
 */

// ===== CONFIG =====
const PROJECT_ID   = 'stock-trading-498512';
const RECIPIENT    = Session.getActiveUser().getEmail(); // self-email; or hardcode 'jacksterwu@gmail.com'
const SENDER_NAME  = 'Stock-Trading Bot';                // friendly From display name (still your address)
const LABEL_NAME   = 'Trading/Weekly';                   // applied to the received copy; '' to disable
const SEND_HOUR    = 7;                                   // weekly trigger hour, script timezone
const SEND_WEEKDAY = ScriptApp.WeekDay.SUNDAY;           // weekly trigger day

// ===== ENTRY POINTS =====
function testReport()          { sendWeeklyReport_(); }            // run once to test now
function runWeeklyReport()     { sendWeeklyReport_(); }            // the trigger target

function installWeeklyTrigger() {
  // Remove any prior triggers for this function so re-running doesn't stack duplicates.
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'runWeeklyReport')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('runWeeklyReport')
    .timeBased().onWeekDay(SEND_WEEKDAY).atHour(SEND_HOUR).create();
  Logger.log('Installed weekly trigger: %s @ %s:00 (%s)', SEND_WEEKDAY, SEND_HOUR, Session.getScriptTimeZone());
}

// ===== MAIN =====
function sendWeeklyReport_() {
  const d = gatherData_();
  const subject = `Stock-Trading · Weekly System Report — ${d.dateLabel} · ${d.healthBadge.text}${d.subjectPerf}`;
  const html = buildHtml_(d);
  const plain = buildPlain_(d);

  // From you, to you: runs as the authorized account, so no SMTP/app-password needed.
  GmailApp.sendEmail(RECIPIENT, subject, plain, { htmlBody: html, name: SENDER_NAME });

  // Optional: label the received copy so weekly reports are filed together.
  if (LABEL_NAME) {
    try {
      const label = GmailApp.getUserLabelByName(LABEL_NAME) || GmailApp.createLabel(LABEL_NAME);
      Utilities.sleep(3000); // let the self-delivered message land
      GmailApp.search(`subject:"Weekly System Report — ${d.dateLabel}" newer_than:1d`, 0, 5)
        .forEach(t => t.addLabel(label));
    } catch (e) { Logger.log('Label step skipped: ' + e); }
  }

  // Liveness beat (ops.heartbeat -> state.automation_heartbeat): lets cadence_check.sql detect a
  // silently-dead weekly report (revoked token / deleted trigger). Best-effort — never block the send.
  try {
    BigQuery.Jobs.query({
      query: `INSERT INTO \`${PROJECT_ID}.ops.heartbeat\` (source, note) VALUES ('weekly_report', 'sent')`,
      useLegacySql: false, timeoutMs: 30000
    }, PROJECT_ID);
  } catch (e) { Logger.log('heartbeat write skipped: ' + e); }

  Logger.log('Weekly report sent to %s', RECIPIENT);
}

// ===== DATA =====
function gatherData_() {
  const tz = getUserTz_();

  const scorecard = bq_(`
    SELECT strategy, activation, is_active, nav, sizing_base_2pct, deployed_mv,
           deployed_unit_value, current_drawdown, excess_vs_sgov, twr_7d, closed_trades,
           closed_to_gate, any_kill_flag, has_open_exposure
    FROM \`${PROJECT_ID}.analytics.strategy_scorecard\` ORDER BY strategy`);

  const regimeRows = bq_(`
    SELECT scope, key, value, rationale FROM \`${PROJECT_ID}.state.current_regime\`
    WHERE scope IN ('FUNDAMENTAL_AXIS','TECHNICAL_SIGNAL')`);

  const health = bq_(`SELECT * FROM \`${PROJECT_ID}.state.system_health\``)[0] || {};
  const activity = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.weekly_activity\``)[0] || {};
  const acct = bq_(`SELECT * FROM \`${PROJECT_ID}.state.account_latest\``)[0] || null;
  const navPrior = bq_(`SELECT nav FROM \`${PROJECT_ID}.state.account_nav_7d_ago\``)[0] || {};
  const recon = bq_(`SELECT events_side_nav_total AS nav FROM \`${PROJECT_ID}.analytics.account_reconciliation\``)[0] || {};

  const fills = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.weekly_fills\``);
  const nogos = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.weekly_nogos\``);
  const positions = bq_(`SELECT * FROM \`${PROJECT_ID}.state.open_positions_summary\``);
  const next7 = bq_(`SELECT * FROM \`${PROJECT_ID}.state.next_7_days\``);

  // Monitoring coverage (2026-07 addition): these previously reached the operator ONLY via the
  // independent DTS failure-email when cadence_check.sql RAISEs — never surfaced in the weekly digest.
  const automation = bq_(`SELECT source, stale FROM \`${PROJECT_ID}.state.automation_heartbeat\``);
  const backups = bq_(`SELECT stale FROM \`${PROJECT_ID}.state.backup_health\``)[0] || {};
  const opsBackups = bq_(`SELECT stale FROM \`${PROJECT_ID}.state.ops_backup_health\``)[0] || {};
  const cadenceAttn = bq_(`SELECT COUNT(*) AS n FROM \`${PROJECT_ID}.state.cadence_watch\` WHERE needs_attention`)[0] || {};

  // Regime: pull the integrative label + the 5 axes + technical signals.
  const fund = {}; const tech = {};
  regimeRows.forEach(r => { (r.scope === 'FUNDAMENTAL_AXIS' ? fund : tech)[r.key] = r; });
  const integrative = (fund['_integrative'] || {});

  // Account header: prefer the daily IBKR snapshot; fall back to the BigQuery reconciliation NAV —
  // per-FIELD fallback (F13), not per-row: a snapshot row can exist with a NULL nav cell (e.g. a
  // partial write), and `acct ? ... : ...` (row-existence only) would then render an em-dash instead
  // of using the perfectly good reconciliation NAV.
  const nav = (acct ? num_(acct.nav) : null) != null ? num_(acct.nav) : num_(recon.nav);
  const twr7 = acct ? num_(acct.twr_7d) : null;
  // Exact flow-immune dollar delta from snapshot history (F2c) — TWR strips cash flows, so backing
  // the delta out of `nav - nav/(1+twr7)` mis-states any week with a deposit/withdrawal.
  const navDelta = (nav != null && num_(navPrior.nav) != null) ? nav - num_(navPrior.nav) : null;

  // all_green recomputed from the SAME component signals the ops strip renders (F4) — the SQL
  // state.system_health.all_green excludes firing kill-flags and non-critical alerts, so using it
  // for the header badge could show "ALL GREEN" while the strip below shows red items.
  const marksFresh = String(health.marks_fresh) === 'true';
  const engineFresh = String(health.engine_fresh) === 'true';
  const embOK = String(health.embeddings_healthy) === 'true';
  const openAlerts = num_(health.open_alerts) || 0;
  const kills = num_(health.firing_kill_flags) || 0;
  const allGreen = marksFresh && engineFresh && embOK && openAlerts === 0 && kills === 0;
  const healthBadge = allGreen
    ? { text: 'ALL GREEN', bg: '#13402e', fg: '#54e0a3', dot: '●' }
    : { text: 'ATTENTION', bg: '#4a1f1a', fg: '#ff9b8a', dot: '▲' };

  const dateLabel = Utilities.formatDate(new Date(), tz, 'MMM d, yyyy');

  // NAV staleness (F6): the header must never silently show a days-old NAV as if it were current.
  const navStale = !!(acct && health.last_trading_day && acct.snapshot_date < health.last_trading_day);

  // Subject-line perf tag: the ACCOUNT week TWR (F5) — the prior best-deployed-sleeve tag always
  // advertised the best performer and never the worst, a survivorship-biased one-line summary.
  const subjectPerf = twr7 != null ? ` · wk ${signPct_(twr7 * 100)}` : '';

  return { scorecard, fund, tech, integrative, health, activity, acct, nav, navDelta, navStale,
           twr7, fills, nogos, positions, next7, automation, backups, opsBackups, cadenceAttn,
           marksFresh, engineFresh, embOK, openAlerts, kills,
           allGreen, healthBadge, dateLabel, subjectPerf, tz };
}

// ===== BigQuery helper =====
function bq_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000 }, PROJECT_ID);
  // Poll if the job did not finish synchronously (rare for these small queries).
  let guard = 0;
  while (!res.jobComplete && guard++ < 10) {
    Utilities.sleep(1000);
    res = BigQuery.Jobs.getQueryResults(PROJECT_ID, res.jobReference.jobId);
  }
  // A query that never completes must FAIL the send, not silently render as empty data (F3) — an
  // aborted send leaves no heartbeat, so the existing automation_heartbeat dead-man's switch catches it.
  if (!res.jobComplete) {
    throw new Error('BigQuery job did not complete after 10s poll: ' + sql.slice(0, 120));
  }
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  return (res.rows || []).map(r => {
    const o = {};
    r.f.forEach((cell, i) => { o[fields[i]] = cell.v; });
    return o;
  });
}

// Detected DISPLAY timezone (state.user_tz — see bigquery/20_user_prefs.sql). Falls back to
// America/Denver on any error so a BigQuery hiccup on this read can never block the send.
let _tzCache = null;
function getUserTz_() {
  if (_tzCache) return _tzCache;
  try {
    _tzCache = (bq_(`SELECT tz FROM \`${PROJECT_ID}.state.user_tz\``)[0] || {}).tz || 'America/Denver';
  } catch (e) {
    _tzCache = 'America/Denver';
  }
  return _tzCache;
}

// ===== formatting =====
function num_(v)  { return (v === null || v === undefined || v === '') ? null : Number(v); }
function money0_(v){ return v == null ? '—' : (v < 0 ? '−$' : '$') + Math.round(Math.abs(v)).toLocaleString('en-US'); }
function money2_(v){ return v == null ? '—' : (v < 0 ? '−$' : '$') + Math.abs(Number(v)).toFixed(2); }
function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; }      // unicode minus
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }
function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function okFail_(b){ return b ? 'OK' : 'FAIL'; }

// ===== HTML =====
function buildHtml_(d) {
  const card = (label, big, sub, color) => `
    <td width="25%" style="padding:4px;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f7fa;border-radius:10px;"><tr><td style="padding:12px 10px;text-align:center;">
        <div style="font-size:11px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.5px;">${label}</div>
        <div style="font-size:20px;font-weight:700;color:${color};margin-top:4px;">${big}</div>
        <div style="font-size:11px;color:#8a96a3;margin-top:2px;">${sub}</div>
      </td></tr></table>
    </td>`;

  // F1: MTD/YTD null-guarded like week (a NULL cell must render '—', not "+0.00%" in green —
  // null*100===0 and clr_(null) reads >=0 as true in plain JS).
  const week = d.twr7 != null ? signPct_(d.twr7 * 100) : '—';
  const mtdVal = d.acct ? num_(d.acct.twr_mtd) : null;
  const ytdVal = d.acct ? num_(d.acct.twr_ytd) : null;
  const mtd = mtdVal != null ? signPct_(mtdVal * 100) : '—';
  const ytd = ytdVal != null ? signPct_(ytdVal * 100) : '—';

  // F2: sign-aware arrow + color instead of a hardcoded up-triangle (a down week must not show ▲).
  let navSub = 'account';
  if (d.navDelta != null) {
    const arrow = d.navDelta >= 0 ? '▲' : '▼';
    navSub = `${arrow} ${money2_(d.navDelta)} wk`;
  }
  const navSubColor = d.navDelta != null ? clr_(d.navDelta) : '#8a96a3';
  // F6: never silently show a stale NAV as current — append the as-of date (+ STALE chip) to the delta.
  const navAsOf = d.acct
    ? `${navSub} · as of ${esc_(d.acct.snapshot_date)}${d.navStale ? ' <span style="color:#b9770e;font-weight:700;">STALE</span>' : ''}`
    : navSub;

  const statCards =
    card('Total NAV', money0_(d.nav), navAsOf, navSubColor === '#8a96a3' ? '#0f2747' : navSubColor) +
    card('Week TWR', week, 'account', d.twr7 != null ? clr_(d.twr7) : '#0f2747') +
    card('MTD TWR', mtd, 'account', mtdVal != null ? clr_(mtdVal) : '#0f2747') +
    card('YTD TWR', ytd, 'account', ytdVal != null ? clr_(ytdVal) : '#0f2747');

  const axisChip = k => d.fund[k]
    ? `<span style="display:inline-block;background-color:#eef1f5;color:#3d4a59;font-size:11px;padding:5px 10px;border-radius:14px;margin:2px;">${esc_(label_(k))}: <b>${esc_(d.fund[k].value)}</b></span>` : '';
  const techStr = ['EQUITY_BREADTH','SPY_TREND','SUSTAINED_INVERSION']
    .filter(k => d.tech[k]).map(k => `${label_(k)} <b>${esc_(d.tech[k].value)}</b>`).join(' · ');

  const scRows = d.scorecard.map(s => {
    const inactive = String(s.is_active) !== 'true';
    const duv = num_(s.deployed_unit_value);
    const hasPerf = duv != null;
    const twr = hasPerf ? signPct_((duv - 1) * 100) : '—';
    const wk7 = num_(s.twr_7d);
    const wk7Str = wk7 != null ? signPct_(wk7 * 100) : '—';
    const exc = num_(s.excess_vs_sgov) != null ? signPct_(num_(s.excess_vs_sgov) * 100) : '—';
    const badge = badge_(s);
    const rowBg = inactive ? '#fafbfc' : '#ffffff';
    const txt = inactive ? '#8a96a3' : '#0f2747';
    return `
      <tr style="background-color:${rowBg};">
        <td style="padding:9px 8px;font-weight:700;color:${txt};">${esc_(s.strategy)}</td>
        <td style="padding:9px 8px;">${badge}</td>
        <td style="padding:9px 8px;text-align:right;color:${inactive ? '#8a96a3' : '#1f2d3d'};">${money0_(num_(s.nav))} · ${money2_(num_(s.sizing_base_2pct))}</td>
        <td style="padding:9px 8px;text-align:right;color:${inactive ? '#8a96a3' : '#1f2d3d'};">${num_(s.deployed_mv) > 0 ? money2_(num_(s.deployed_mv)) : '—'}</td>
        <td style="padding:9px 8px;text-align:right;font-weight:${hasPerf ? 700 : 400};color:${hasPerf ? clr_(duv - 1) : '#8a96a3'};">${twr}</td>
        <td style="padding:9px 8px;text-align:right;color:${wk7 != null ? clr_(wk7) : '#8a96a3'};">${wk7Str}</td>
        <td style="padding:9px 8px;text-align:right;color:${num_(s.excess_vs_sgov) != null ? clr_(num_(s.excess_vs_sgov)) : '#8a96a3'};">${exc}</td>
        <td style="padding:9px 8px;text-align:right;color:${inactive ? '#8a96a3' : '#1f2d3d'};">${hasPerf ? esc_(s.closed_trades) + '/30' : '—'}</td>
      </tr>`;
  }).join('');

  // F7: glyph follows side (BUY ▲ green / SELL ▼ red) instead of a hardcoded up-triangle for every fill.
  const fillsHtml = d.fills.length
    ? d.fills.map(f => {
        const isBuy = String(f.side).toUpperCase() === 'BUY';
        const glyph = isBuy ? '▲' : '▼';
        const glyphColor = isBuy ? '#1a7f5a' : '#c0392b';
        const dateStr = f.fill_ts_ms != null
          ? Utilities.formatDate(new Date(Number(f.fill_ts_ms)), d.tz, 'MMM d')
          : esc_(f.fill_date);
        return `<div style="padding:4px 0;"><span style="color:${glyphColor};">${glyph}</span> <b>${esc_(f.ticker)}</b> ${esc_(f.side)} ${esc_(Number(f.shares).toFixed(3))} sh @ ${money2_(num_(f.price))} — Strategy ${esc_(f.strategy)} (${dateStr})</div>`;
      }).join('')
    : '<div style="padding:4px 0;color:#8a96a3;">No fills this week.</div>';
  const nogoHtml = d.nogos.length
    ? `<div style="padding:4px 0;color:#8a96a3;">✕ NO-GO: ${d.nogos.map(n => esc_(n.ticker) + ' (' + esc_(n.strategy) + ')').join(', ')}</div>` : '';

  const hb = d.healthBadge;
  const hk = b => b ? '✓' : '✕';
  const backupsOk = !(String(d.backups.stale) === 'true' || String(d.opsBackups.stale) === 'true');
  const automationOk = d.automation.every(a => String(a.stale) !== 'true');
  const cadenceOk = (num_(d.cadenceAttn.n) || 0) === 0;

  // F8: append an ellipsis when the rationale was actually cut (don't truncate mid-word silently).
  const rationaleRaw = d.integrative.rationale || '';
  const rationale = rationaleRaw.length > 320 ? rationaleRaw.slice(0, 320) + '…' : rationaleRaw;

  // Part 4.1 — open positions (the biggest prior content gap: the current book was not in the email).
  const posRows = d.positions.length
    ? d.positions.map(p => {
        const upct = num_(p.unrealized_pct);
        return `
      <tr>
        <td style="padding:8px;font-weight:700;color:#0f2747;">${esc_(p.ticker)}</td>
        <td style="padding:8px;">${esc_(p.strategy)}</td>
        <td style="padding:8px;text-align:right;">${money2_(num_(p.mark))}</td>
        <td style="padding:8px;text-align:right;font-weight:700;color:${upct != null ? clr_(upct) : '#8a96a3'};">${upct != null ? signPct_(upct * 100) : '—'}</td>
        <td style="padding:8px;text-align:right;color:#3d4a59;">${p.convergence_target != null ? money2_(num_(p.convergence_target)) : '—'}</td>
        <td style="padding:8px;text-align:right;color:#3d4a59;">${p.time_exit_date || '—'}</td>
      </tr>`;
      }).join('')
    : '';
  const positionsSection = d.positions.length ? `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Open Positions</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;">Ticker</td><td style="padding:8px;">Strat</td>
        <td style="padding:8px;text-align:right;">Mark</td><td style="padding:8px;text-align:right;">Unrl %</td>
        <td style="padding:8px;text-align:right;">Target</td><td style="padding:8px;text-align:right;">Time-exit</td>
      </tr>${posRows}
    </table>
  </td></tr>` : '';

  // Part 4.2 — forward-looking 7-day strip (queue items / time-exits / order windows due soon).
  const catLabel = { QUEUE_DUE: 'Queue', TIME_EXIT: 'Time-exit', ORDER_WINDOW: 'Order window' };
  const next7Html = d.next7.length
    ? d.next7.map(n => `<div style="padding:3px 0;">▸ ${esc_(n.due_date)} — <b>${esc_(catLabel[n.category] || n.category)}</b> ${esc_(n.ticker || '')} ${n.strategy ? '(' + esc_(n.strategy) + ')' : ''}</div>`).join('')
    : '<div style="padding:3px 0;color:#8a96a3;">Nothing due in the next 7 days.</div>';
  const next7Section = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Next 7 Days</div>
    <div style="margin-top:8px;font-size:12px;color:#3d4a59;">${next7Html}</div>
  </td></tr>`;

  return `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#eef1f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1f2d3d;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#eef1f5;padding:18px 0;"><tr><td align="center">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:600px;background-color:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 1px 4px rgba(15,39,71,0.10);">

  <tr><td style="background-color:#0f2747;padding:22px 26px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
      <td style="color:#ffffff;font-size:19px;font-weight:700;">Stock-Trading · Weekly System Report</td>
      <td align="right" style="color:#9fb3cc;font-size:12px;">Week ending<br><span style="color:#ffffff;font-size:13px;font-weight:600;">${esc_(d.dateLabel)}</span></td>
    </tr></table>
    <div style="margin-top:12px;">
      <span style="display:inline-block;background-color:${hb.bg};color:${hb.fg};font-size:12px;font-weight:700;padding:6px 12px;border-radius:20px;">${hb.dot} SYSTEM ${esc_(hb.text)}</span>
      <span style="display:inline-block;color:#9fb3cc;font-size:12px;padding:6px 4px;">last close ${esc_(d.health.last_mark_date || '—')} · ${d.scorecard.length} strategies</span>
    </div>
  </td></tr>

  <tr><td style="padding:20px 18px 6px 18px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>${statCards}</tr></table>
    <div style="font-size:11px;color:#8a96a3;padding:4px 6px 0 6px;">Account is ~98% SGOV park; the deployed sleeves below carry the strategy edge.</div>
  </td></tr>

  <tr><td style="padding:14px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Regime</div>
    <div style="margin-top:8px;background-color:#fdf3e3;border-left:4px solid #b9770e;border-radius:8px;padding:12px 14px;">
      <div style="font-size:16px;font-weight:700;color:#7a4d07;">◆ ${esc_(d.integrative.value || 'n/a')}</div>
      <div style="font-size:12px;color:#6b5a3a;margin-top:4px;">${esc_(rationale)}</div>
    </div>
    <div style="margin-top:10px;">
      ${['growth_momentum','inflation_trend','policy_stance','risk_sentiment','shock_overlay'].map(axisChip).join('')}
    </div>
    <div style="margin-top:6px;font-size:11px;color:#8a96a3;">Technical: ${techStr || 'n/a'}</div>
  </td></tr>

  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Strategy Scorecard</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;">Strat</td><td style="padding:8px;">Status</td>
        <td style="padding:8px;text-align:right;">Budget (2%)</td><td style="padding:8px;text-align:right;">Deployed</td>
        <td style="padding:8px;text-align:right;">TWR</td><td style="padding:8px;text-align:right;">Δ Wk</td>
        <td style="padding:8px;text-align:right;">vs SGOV</td><td style="padding:8px;text-align:right;">Gate</td>
      </tr>${scRows}
    </table>
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">TWR = deployed total-return unit value since inception (gross of commissions). Δ Wk = deployed TWR change over the trailing 7 days. Gate = closed trades toward the 30-trade calibration gate.</div>
  </td></tr>
${positionsSection}
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">This Week's Activity</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:8px;"><tr>
      ${actCard_(String(d.activity.fills_7d == null ? 0 : d.activity.fills_7d), 'orders filled', '#1a7f5a', '#e6f4ee')}
      ${actCard_(`${d.activity.go_7d == null ? 0 : d.activity.go_7d} · ${d.activity.nogo_7d == null ? 0 : d.activity.nogo_7d}`, 'GO · NO-GO', '#0f2747', '#f5f7fa')}
      ${actCard_(String(d.activity.pending_orders == null ? 0 : d.activity.pending_orders), 'orders pending', '#0f2747', '#f5f7fa')}
    </tr></table>
    <div style="margin-top:8px;font-size:12px;color:#3d4a59;">${fillsHtml}${nogoHtml}</div>
  </td></tr>
${next7Section}
  <tr><td style="padding:12px 22px 8px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Operational Health</div>
    <div style="margin-top:8px;background-color:#f5f7fa;border-radius:8px;padding:12px 14px;font-size:12px;color:#3d4a59;">
      <span style="margin-right:14px;">${hk(d.marksFresh)} Marks fresh</span>
      <span style="margin-right:14px;">${hk(d.engineFresh)} Engine fresh</span>
      <span style="margin-right:14px;">${hk(d.embOK)} Embeddings</span>
      <span style="margin-right:14px;">${hk(d.openAlerts === 0)} ${d.openAlerts} open alerts</span>
      <span style="margin-right:14px;">${hk(d.kills === 0)} ${d.kills} kill-flags</span>
      <span style="margin-right:14px;">${hk(backupsOk)} Backups</span>
      <span style="margin-right:14px;">${hk(automationOk)} Automation</span>
      <span>${hk(cadenceOk)} Cadence</span>
    </div>
  </td></tr>

  <tr><td style="padding:16px 22px 22px 22px;">
    <hr style="border:none;border-top:1px solid #e3e8ee;margin:0 0 12px 0;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">
      Auto-generated weekly from BigQuery (<code>analytics.strategy_scorecard</code>, <code>state.current_regime</code>, <code>state.system_health</code>, <code>state.account_latest</code>). Profitability figures are gross of commissions; cash/NAV accounting tracks commissions exactly. Times shown in ${esc_(d.tz)} (detected). Informational — no action required.
    </div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

function actCard_(big, label, color, bg) {
  return `<td width="33%" style="padding:4px;"><table role="presentation" width="100%" style="background-color:${bg};border-radius:8px;"><tr><td style="padding:10px;text-align:center;">
    <div style="font-size:22px;font-weight:700;color:${color};">${big}</div><div style="font-size:11px;color:#3d4a59;">${label}</div></td></tr></table></td>`;
}

function badge_(s) {
  const active = String(s.is_active) === 'true';
  const a = String(s.activation || '');
  let bg, fg, text;
  if (!active) { bg = '#edf0f3'; fg = '#8a96a3'; text = 'INACTIVE'; }
  else if (/HYBRID/i.test(a)) { bg = '#fdf3e3'; fg = '#b9770e'; text = 'HYBRID'; }
  // F11: the router-active-but-idle state gets its OWN label instead of an unexplained amber "ACTIVE"
  // that reads identically to the green "ACTIVE" badge but means something different (router active,
  // $0 currently deployed). (The prior `/defer/i.test(activation_note)` branch was dead code — the
  // scorecard SELECT above never fetches activation_note — so it never actually fired; removed.)
  else if (num_(s.deployed_mv) === 0) { bg = '#fdf3e3'; fg = '#b9770e'; text = 'ACTIVE · idle'; }
  else { bg = '#e6f4ee'; fg = '#1a7f5a'; text = 'ACTIVE'; }
  return `<span style="display:inline-block;background-color:${bg};color:${fg};font-size:10px;font-weight:700;padding:3px 8px;border-radius:10px;">${text}</span>`;
}

function label_(k) {
  const m = { growth_momentum:'Growth', inflation_trend:'Inflation', policy_stance:'Policy',
    risk_sentiment:'Sentiment', shock_overlay:'Shock', EQUITY_BREADTH:'breadth',
    SPY_TREND:'SPY trend', SUSTAINED_INVERSION:'inversion' };
  return m[k] || k;
}

// ===== plain-text fallback =====
// F10: rebuilt to mirror EVERY section buildHtml_ renders (MTD/YTD, excess-vs-SGOV, gate, Δ Wk,
// regime axes/technical signals, fills/positions/next-7 detail, full ops strip) from the SAME `d`
// object, with explicit OK/FAIL booleans — the prior version silently emitted literal "true"/"false"/
// "undefined" whenever a health field was absent or boolean-typed.
function buildPlain_(d) {
  let s = `Stock-Trading — Weekly System Report (${d.dateLabel})\n\n`;
  s += `SYSTEM: ${d.healthBadge.text}. Last close ${d.health.last_mark_date || '—'}.\n`;
  s += `ACCOUNT: NAV ${money0_(d.nav)}` + (d.acct ? ` (as of ${d.acct.snapshot_date}${d.navStale ? ' STALE' : ''})` : '') + '\n';
  s += `  Week ${d.twr7 != null ? signPct_(d.twr7 * 100) : '—'}` +
       ` · MTD ${d.acct && num_(d.acct.twr_mtd) != null ? signPct_(num_(d.acct.twr_mtd) * 100) : '—'}` +
       ` · YTD ${d.acct && num_(d.acct.twr_ytd) != null ? signPct_(num_(d.acct.twr_ytd) * 100) : '—'}\n\n`;

  s += `REGIME: ${d.integrative.value || 'n/a'}\n`;
  ['growth_momentum','inflation_trend','policy_stance','risk_sentiment','shock_overlay'].forEach(k => {
    if (d.fund[k]) s += `  ${label_(k)}: ${d.fund[k].value}\n`;
  });
  const techStr = ['EQUITY_BREADTH','SPY_TREND','SUSTAINED_INVERSION']
    .filter(k => d.tech[k]).map(k => `${label_(k)} ${d.tech[k].value}`).join(' · ');
  s += `  Technical: ${techStr || 'n/a'}\n\n`;

  s += `STRATEGIES:\n`;
  d.scorecard.forEach(x => {
    const duv = num_(x.deployed_unit_value);
    const wk7 = num_(x.twr_7d);
    s += `  ${x.strategy}  ${String(x.is_active) === 'true' ? (/HYBRID/i.test(x.activation) ? 'HYBRID' : (num_(x.deployed_mv) === 0 ? 'ACTIVE-idle' : 'ACTIVE')) : 'INACTIVE'}  ` +
         `budget ${money0_(num_(x.nav))}/${money2_(num_(x.sizing_base_2pct))}  ` +
         `deployed ${num_(x.deployed_mv) > 0 ? money2_(num_(x.deployed_mv)) : '—'}  ` +
         `TWR ${duv != null ? signPct_((duv - 1) * 100) : '—'}  ` +
         `ΔWk ${wk7 != null ? signPct_(wk7 * 100) : '—'}  ` +
         `vsSGOV ${num_(x.excess_vs_sgov) != null ? signPct_(num_(x.excess_vs_sgov) * 100) : '—'}  ` +
         `gate ${x.closed_trades != null ? x.closed_trades : '—'}/30\n`;
  });

  if (d.positions.length) {
    s += `\nOPEN POSITIONS:\n`;
    d.positions.forEach(p => {
      const upct = num_(p.unrealized_pct);
      s += `  ${p.ticker} (${p.strategy})  mark ${money2_(num_(p.mark))}  unrl ${upct != null ? signPct_(upct * 100) : '—'}  ` +
           `target ${p.convergence_target != null ? money2_(num_(p.convergence_target)) : '—'}  exit ${p.time_exit_date || '—'}\n`;
    });
  }

  s += `\nACTIVITY (7d): ${d.activity.fills_7d || 0} filled, ${d.activity.go_7d || 0} GO, ${d.activity.nogo_7d || 0} NO-GO, ${d.activity.pending_orders || 0} pending.\n`;
  if (d.fills.length) {
    d.fills.forEach(f => { s += `  ${f.side} ${Number(f.shares).toFixed(3)} ${f.ticker} @ ${money2_(num_(f.price))} — ${f.strategy} (${f.fill_date})\n`; });
  }
  if (d.nogos.length) {
    s += `  NO-GO: ${d.nogos.map(n => n.ticker + ' (' + n.strategy + ')').join(', ')}\n`;
  }

  if (d.next7.length) {
    s += `\nNEXT 7 DAYS:\n`;
    d.next7.forEach(n => { s += `  ${n.due_date} — ${n.category} ${n.ticker || ''} ${n.strategy ? '(' + n.strategy + ')' : ''}\n`; });
  }

  s += `\nOPS: marks ${okFail_(d.marksFresh)}, engine ${okFail_(d.engineFresh)}, embeddings ${okFail_(d.embOK)}, ` +
       `${d.openAlerts} alerts, ${d.kills} kill-flags, backups ${okFail_(!(String(d.backups.stale) === 'true' || String(d.opsBackups.stale) === 'true'))}, ` +
       `automation ${okFail_(d.automation.every(a => String(a.stale) !== 'true'))}, cadence ${okFail_((num_(d.cadenceAttn.n) || 0) === 0)}.\n`;
  return s;
}

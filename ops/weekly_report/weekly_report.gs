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
 *   - analytics.strategy_scorecard   (per-strategy activation + budget + deployed-TWR)
 *   - state.current_regime           (regime axes + technical signals)
 *   - state.system_health            (green/red ops rollup)
 *   - state.account_latest           (account NAV / cash / TWR — written daily by D2 Step 0b)
 *   - analytics.account_reconciliation (NAV fallback if no snapshot yet)
 *   - analytics.weekly_activity      (last-7-day fills / GO / NO-GO / pending)
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
  const scorecard = bq_(`
    SELECT strategy, activation, is_active, nav, sizing_base_2pct, deployed_mv,
           deployed_unit_value, current_drawdown, excess_vs_sgov, closed_trades,
           closed_to_gate, any_kill_flag, has_open_exposure
    FROM \`${PROJECT_ID}.analytics.strategy_scorecard\` ORDER BY strategy`);

  const regimeRows = bq_(`
    SELECT scope, key, value, rationale FROM \`${PROJECT_ID}.state.current_regime\`
    WHERE scope IN ('FUNDAMENTAL_AXIS','TECHNICAL_SIGNAL')`);

  const health = bq_(`SELECT * FROM \`${PROJECT_ID}.state.system_health\``)[0] || {};
  const activity = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.weekly_activity\``)[0] || {};
  const acct = bq_(`SELECT * FROM \`${PROJECT_ID}.state.account_latest\``)[0] || null;
  const recon = bq_(`SELECT events_side_nav_total AS nav FROM \`${PROJECT_ID}.analytics.account_reconciliation\``)[0] || {};

  const fills = bq_(`
    SELECT ticker, side, shares, price, strategy, CAST(DATE(fill_ts) AS STRING) AS d
    FROM \`${PROJECT_ID}.state.trade_fills_curated\`
    WHERE DATE(fill_ts) >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
    ORDER BY fill_ts DESC LIMIT 6`);

  const nogos = bq_(`
    SELECT ticker, strategy FROM \`${PROJECT_ID}.events.decision_log\`
    WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
      AND UPPER(decision) = 'NO-GO' AND ticker IS NOT NULL
    ORDER BY entry_date DESC LIMIT 8`);

  // Regime: pull the integrative label + the 5 axes + technical signals.
  const fund = {}; const tech = {};
  regimeRows.forEach(r => { (r.scope === 'FUNDAMENTAL_AXIS' ? fund : tech)[r.key] = r; });
  const integrative = (fund['_integrative'] || {});

  // Account header: prefer the daily IBKR snapshot; fall back to the BigQuery reconciliation NAV.
  const nav = acct ? num_(acct.nav) : num_(recon.nav);
  const twr7 = acct ? num_(acct.twr_7d) : null;
  const navDelta = (acct && twr7 != null && nav != null) ? nav - nav / (1 + twr7) : null;

  const allGreen = String(health.all_green) === 'true';
  const healthBadge = allGreen
    ? { text: 'ALL GREEN', bg: '#13402e', fg: '#54e0a3', dot: '●' }
    : { text: 'ATTENTION', bg: '#4a1f1a', fg: '#ff9b8a', dot: '▲' };

  const tz = 'America/Denver';
  const dateLabel = Utilities.formatDate(new Date(), tz, 'MMM d, yyyy');

  // A small subject-line perf tag from the best deployed sleeve.
  let subjectPerf = '';
  const deployed = scorecard.filter(s => num_(s.deployed_unit_value) != null);
  if (deployed.length) {
    const best = deployed.reduce((a, b) =>
      num_(a.deployed_unit_value) >= num_(b.deployed_unit_value) ? a : b);
    subjectPerf = ` · ${best.strategy} ${signPct_((num_(best.deployed_unit_value) - 1) * 100)}`;
  }

  return { scorecard, fund, tech, integrative, health, activity, acct, nav, navDelta,
           twr7, fills, nogos, allGreen, healthBadge, dateLabel, subjectPerf, tz };
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
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  return (res.rows || []).map(r => {
    const o = {};
    r.f.forEach((cell, i) => { o[fields[i]] = cell.v; });
    return o;
  });
}

// ===== formatting =====
function num_(v)  { return (v === null || v === undefined || v === '') ? null : Number(v); }
function money0_(v){ return v == null ? '—' : '$' + Math.round(v).toLocaleString('en-US'); }
function money2_(v){ return v == null ? '—' : '$' + Number(v).toFixed(2); }
function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; }      // unicode minus
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }
function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

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

  const week = d.twr7 != null ? signPct_(d.twr7 * 100) : '—';
  const mtd  = d.acct ? signPct_(num_(d.acct.twr_mtd) * 100) : '—';
  const ytd  = d.acct ? signPct_(num_(d.acct.twr_ytd) * 100) : '—';
  const navSub = d.navDelta != null ? `▲ ${money2_(d.navDelta)} wk` : 'account';

  const statCards =
    card('Total NAV', money0_(d.nav), navSub, '#0f2747') +
    card('Week TWR', week, 'account', d.twr7 != null ? clr_(d.twr7) : '#0f2747') +
    card('MTD TWR', mtd, 'account', (d.acct ? clr_(num_(d.acct.twr_mtd)) : '#0f2747')) +
    card('YTD TWR', ytd, 'account', (d.acct ? clr_(num_(d.acct.twr_ytd)) : '#0f2747'));

  const axisChip = k => d.fund[k]
    ? `<span style="display:inline-block;background-color:#eef1f5;color:#3d4a59;font-size:11px;padding:5px 10px;border-radius:14px;margin:2px;">${esc_(label_(k))}: <b>${esc_(d.fund[k].value)}</b></span>` : '';
  const techStr = ['EQUITY_BREADTH','SPY_TREND','SUSTAINED_INVERSION']
    .filter(k => d.tech[k]).map(k => `${label_(k)} <b>${esc_(d.tech[k].value)}</b>`).join(' · ');

  const scRows = d.scorecard.map(s => {
    const inactive = String(s.is_active) !== 'true';
    const duv = num_(s.deployed_unit_value);
    const hasPerf = duv != null;
    const twr = hasPerf ? signPct_((duv - 1) * 100) : '—';
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
        <td style="padding:9px 8px;text-align:right;color:${num_(s.excess_vs_sgov) != null ? clr_(num_(s.excess_vs_sgov)) : '#8a96a3'};">${exc}</td>
        <td style="padding:9px 8px;text-align:right;color:${inactive ? '#8a96a3' : '#1f2d3d'};">${hasPerf ? esc_(s.closed_trades) + '/30' : '—'}</td>
      </tr>`;
  }).join('');

  const fillsHtml = d.fills.length
    ? d.fills.map(f => `<div style="padding:4px 0;">▲ <b>${esc_(f.ticker)}</b> ${esc_(f.side)} ${esc_(Number(f.shares).toFixed(3))} sh @ ${money2_(num_(f.price))} — Strategy ${esc_(f.strategy)} (${esc_(f.d)})</div>`).join('')
    : '<div style="padding:4px 0;color:#8a96a3;">No fills this week.</div>';
  const nogoHtml = d.nogos.length
    ? `<div style="padding:4px 0;color:#8a96a3;">✕ NO-GO: ${d.nogos.map(n => esc_(n.ticker) + ' (' + esc_(n.strategy) + ')').join(', ')}</div>` : '';

  const hb = d.healthBadge;
  const hk = b => b ? '✓' : '✕';
  const marksFresh = String(d.health.marks_fresh) === 'true';
  const engineFresh = String(d.health.engine_fresh) === 'true';
  const embOK = String(d.health.embeddings_healthy) === 'true';
  const openAlerts = num_(d.health.open_alerts) || 0;
  const kills = num_(d.health.firing_kill_flags) || 0;

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
      <div style="font-size:12px;color:#6b5a3a;margin-top:4px;">${esc_((d.integrative.rationale || '').slice(0, 320))}</div>
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
        <td style="padding:8px;text-align:right;">TWR</td><td style="padding:8px;text-align:right;">vs SGOV</td>
        <td style="padding:8px;text-align:right;">Gate</td>
      </tr>${scRows}
    </table>
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">TWR = deployed total-return unit value since inception (gross of commissions). Gate = closed trades toward the 30-trade calibration gate.</div>
  </td></tr>

  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">This Week's Activity</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:8px;"><tr>
      ${actCard_(d.activity.fills_7d, 'orders filled', '#1a7f5a', '#e6f4ee')}
      ${actCard_(d.activity.nogo_7d, 'NO-GO screens', '#0f2747', '#f5f7fa')}
      ${actCard_(d.activity.pending_orders, 'orders pending', '#0f2747', '#f5f7fa')}
    </tr></table>
    <div style="margin-top:8px;font-size:12px;color:#3d4a59;">${fillsHtml}${nogoHtml}</div>
  </td></tr>

  <tr><td style="padding:12px 22px 8px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Operational Health</div>
    <div style="margin-top:8px;background-color:#f5f7fa;border-radius:8px;padding:12px 14px;font-size:12px;color:#3d4a59;">
      <span style="margin-right:14px;">${hk(marksFresh)} Marks fresh</span>
      <span style="margin-right:14px;">${hk(engineFresh)} Engine fresh</span>
      <span style="margin-right:14px;">${hk(embOK)} Embeddings</span>
      <span style="margin-right:14px;">${hk(openAlerts === 0)} ${openAlerts} open alerts</span>
      <span>${hk(kills === 0)} ${kills} kill-flags</span>
    </div>
  </td></tr>

  <tr><td style="padding:16px 22px 22px 22px;">
    <hr style="border:none;border-top:1px solid #e3e8ee;margin:0 0 12px 0;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">
      Auto-generated weekly from BigQuery (<code>analytics.strategy_scorecard</code>, <code>state.current_regime</code>, <code>state.system_health</code>, <code>state.account_latest</code>). Profitability figures are gross of commissions; cash/NAV accounting tracks commissions exactly. Informational — no action required.
    </div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

function actCard_(n, label, color, bg) {
  return `<td width="33%" style="padding:4px;"><table role="presentation" width="100%" style="background-color:${bg};border-radius:8px;"><tr><td style="padding:10px;text-align:center;">
    <div style="font-size:22px;font-weight:700;color:${color};">${n == null ? 0 : n}</div><div style="font-size:11px;color:#3d4a59;">${label}</div></td></tr></table></td>`;
}

function badge_(s) {
  const active = String(s.is_active) === 'true';
  const a = String(s.activation || '');
  let bg, fg, text;
  if (!active) { bg = '#edf0f3'; fg = '#8a96a3'; text = 'INACTIVE'; }
  else if (/HYBRID/i.test(a)) { bg = '#fdf3e3'; fg = '#b9770e'; text = 'HYBRID'; }
  else if (/defer/i.test(String(s.activation_note || '')) || num_(s.deployed_mv) === 0) { bg = '#fdf3e3'; fg = '#b9770e'; text = 'ACTIVE'; }
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
function buildPlain_(d) {
  let s = `Stock-Trading — Weekly System Report (${d.dateLabel})\n\n`;
  s += `SYSTEM: ${d.healthBadge.text}. Last close ${d.health.last_mark_date}.\n`;
  s += `ACCOUNT: NAV ${money0_(d.nav)}` + (d.twr7 != null ? ` (week ${signPct_(d.twr7 * 100)})` : '') + `\n\n`;
  s += `REGIME: ${d.integrative.value || 'n/a'}\n`;
  s += `STRATEGIES:\n`;
  d.scorecard.forEach(x => {
    const duv = num_(x.deployed_unit_value);
    s += `  ${x.strategy}  ${String(x.is_active) === 'true' ? (/HYBRID/i.test(x.activation) ? 'HYBRID' : 'ACTIVE') : 'INACTIVE'}  ` +
         `budget ${money0_(num_(x.nav))}/${money2_(num_(x.sizing_base_2pct))}  ` +
         `deployed ${num_(x.deployed_mv) > 0 ? money2_(num_(x.deployed_mv)) : '—'}  ` +
         `TWR ${duv != null ? signPct_((duv - 1) * 100) : '—'}\n`;
  });
  s += `\nACTIVITY (7d): ${d.activity.fills_7d || 0} filled, ${d.activity.nogo_7d || 0} NO-GO, ${d.activity.pending_orders || 0} pending.\n`;
  s += `OPS: marks ${d.health.marks_fresh}, engine ${d.health.engine_fresh}, embeddings ${d.health.embeddings_healthy}, ` +
       `${num_(d.health.open_alerts) || 0} alerts, ${num_(d.health.firing_kill_flags) || 0} kill-flags.\n`;
  return s;
}

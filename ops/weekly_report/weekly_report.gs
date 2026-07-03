/**
 * Stock-Trading — Weekly System Report: "Strategies vs SGOV" (self-email, fully automatic).
 * =================================================================
 * Runs on GOOGLE'S servers (Apps Script), NOT on Claude's remote-routine server and NOT via the
 * Gmail connector (which can only draft, not send). Runs AS YOU (self-email), so no SMTP / app
 * password / API key. Builds the HTML and sends in one shot — nothing lands in Drafts.
 *
 * PURPOSE: answer one question per strategy — is it beating SGOV? — as a percentage.
 *   * A returns chart: each deployed strategy's cumulative total return + SGOV's own return line.
 *   * A per-strategy table: AVERAGE return vs SGOV per week / month / year — a geometric per-period
 *     rate over ACTIVE (deployed) time only, so idle stretches never dilute it ("Not enough data"
 *     until that much deployed history exists), plus SGOV's own average-return row.
 * Everything else (combined aggregate, verdict labels, dollar figures, weekly-Δ, gate counts,
 * regime, account NAV, positions, activity, ops strip) is intentionally omitted.
 *
 * DATA (BigQuery, project stock-trading-498512):
 *   - analytics.strategy_scorecard     (the A-E list + activation, for the not-deployed reason)
 *   - analytics.strategy_vs_park_daily (per strategy-day: deployed_unit_value + cumulative excess_vs_sgov)
 *   - analytics.sgov_cumulative        (SGOV's own cumulative total return, aligned to the same dates)
 *   - state.system_health              (marks/engine freshness + kill-flags + critical alerts — data-trust)
 *   - state.user_tz                    (detected DISPLAY timezone — never the operating/trading-day tz)
 *   - perf.kill_flags / ops.alerts     (queried lazily, only when system_health flags something)
 *
 * CHART: Apps Script Charts service PNG, inline via cid (Gmail supports no inline SVG / data-URI
 * images). Falls back to plain HTML bars if the build throws; the send must never fail over a chart.
 *
 * SETUP (one time) — see ops/weekly_report/README.md. Deploy an update: re-paste this file, run
 * testReport(); no scope change since 2026-07 (bigquery + gmail.modify already granted).
 */

// ===== CONFIG =====
const PROJECT_ID   = 'stock-trading-498512';
const RECIPIENT    = Session.getActiveUser().getEmail(); // self-email; or hardcode 'jacksterwu@gmail.com'
const SENDER_NAME  = 'Stock-Trading Bot';
const LABEL_NAME   = 'Trading/Weekly';
const SEND_HOUR    = 7;
const SEND_WEEKDAY = ScriptApp.WeekDay.SUNDAY;

// Fixed per-strategy identity colors (CVD-validated) — never reassigned by rank/presence. SGOV is gray.
const CHART_COLORS = { A: '#1baf7a', B: '#2a78d6', C: '#4a3aa7', D: '#eb6834', E: '#e87ba4' };
const SGOV_GRAY = '#898781';

// Trading days per period — the denominator basis for the per-period average return (week=5,
// month=21, year=252 trading days). Also the min deployed history required to state each average.
const TRADING_DAYS_PER = { week: 5, month: 21, year: 252 };

// ===== ENTRY POINTS =====
function testReport()      { sendWeeklyReport_(); }
function runWeeklyReport() { sendWeeklyReport_(); }

function installWeeklyTrigger() {
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
  const subject = buildSubject_(d);
  const chartResult = buildReturnChart_(d);
  const html = buildHtml_(d, chartResult);
  const plain = buildPlain_(d);

  const opts = { htmlBody: html, name: SENDER_NAME };
  if (chartResult) opts.inlineImages = { returnchart: chartResult.blob };
  GmailApp.sendEmail(RECIPIENT, subject, plain, opts);

  if (LABEL_NAME) {
    try {
      const label = GmailApp.getUserLabelByName(LABEL_NAME) || GmailApp.createLabel(LABEL_NAME);
      Utilities.sleep(3000);
      // NOTE: search string coupled to the subject format in buildSubject_ — update both together.
      GmailApp.search(`subject:"Strategies vs SGOV — ${d.dateLabel}" newer_than:1d`, 0, 5)
        .forEach(t => t.addLabel(label));
    } catch (e) { Logger.log('Label step skipped: ' + e); }
  }

  // Liveness beat — lets cadence_check.sql detect a silently-dead weekly report. Best-effort.
  try {
    BigQuery.Jobs.query({
      query: `INSERT INTO \`${PROJECT_ID}.ops.heartbeat\` (source, note) VALUES ('weekly_report', 'sent')`,
      useLegacySql: false, timeoutMs: 30000
    }, PROJECT_ID);
  } catch (e) { Logger.log('heartbeat write skipped: ' + e); }

  Logger.log('Weekly report sent to %s', RECIPIENT);
}

function buildSubject_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const tag = !deployed.length
    ? 'all parked'
    : deployed.map(r => `${r.strategy} ${signPct_(r.returnPct * 100)}`).join(' · ')
        + ` · SGOV ${signPct_(d.sgov.returnPct * 100)}`;
  const warn = d.green ? '' : ' · ⚠ check data';
  return `Stock-Trading · Strategies vs SGOV — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== DATA =====
function gatherData_() {
  const tz = getUserTz_();

  const scorecard = bq_(`
    SELECT strategy, activation
    FROM \`${PROJECT_ID}.analytics.strategy_scorecard\` ORDER BY strategy`);

  const dailyRows = bq_(`
    SELECT as_of_date, strategy, deployed_unit_value, excess_vs_sgov
    FROM \`${PROJECT_ID}.analytics.strategy_vs_park_daily\`
    ORDER BY strategy, as_of_date`);

  const sgovRows = bq_(`
    SELECT as_of_date, sgov_cum_return
    FROM \`${PROJECT_ID}.analytics.sgov_cumulative\`
    ORDER BY as_of_date`);

  const health = bq_(`SELECT * FROM \`${PROJECT_ID}.state.system_health\``)[0] || {};

  const dateLabel = Utilities.formatDate(new Date(), tz, 'MMM d, yyyy');

  // Data-trust predicate: marks/engine fresh + no firing kill-flags + no critical alerts.
  const marksFresh = String(health.marks_fresh) === 'true';
  const engineFresh = String(health.engine_fresh) === 'true';
  const firingKillFlags = num_(health.firing_kill_flags) || 0;
  const openCriticalAlerts = num_(health.open_critical_alerts) || 0;
  const green = marksFresh && engineFresh && firingKillFlags === 0 && openCriticalAlerts === 0;

  const killFlagDetails = firingKillFlags > 0 ? bq_(`
    SELECT strategy, drawdown_kill, runaway_review, m2m_underperf_review
    FROM \`${PROJECT_ID}.perf.kill_flags\`
    WHERE drawdown_kill OR runaway_review OR m2m_underperf_review`) : [];
  const criticalAlerts = openCriticalAlerts > 0 ? bq_(`
    SELECT category, message FROM \`${PROJECT_ID}.ops.alerts\`
    WHERE NOT resolved AND severity = 'critical' ORDER BY alert_ts DESC LIMIT 3`) : [];
  const healthReasons = green ? [] :
    buildHealthReasons_(health, marksFresh, engineFresh, firingKillFlags, killFlagDetails, openCriticalAlerts, criticalAlerts);

  // Per-strategy daily series: cumulative return (deployed_unit_value) + cumulative excess vs SGOV.
  const dailyByStrategy = {};
  dailyRows.forEach(r => {
    const s = r.strategy;
    if (!dailyByStrategy[s]) dailyByStrategy[s] = [];
    dailyByStrategy[s].push({ as_of_date: r.as_of_date, duv: num_(r.deployed_unit_value), excess: num_(r.excess_vs_sgov) });
  });

  // SGOV's own cumulative return series (same date axis).
  const sgovSeries = sgovRows.map(r => ({ as_of_date: r.as_of_date, cum: num_(r.sgov_cum_return) }));
  const sgovByDate = {};
  sgovSeries.forEach(p => { sgovByDate[p.as_of_date] = p.cum; });

  // One row per strategy, always all five, fixed A→E order.
  const rows = scorecard.map(s => {
    const pts = dailyByStrategy[s.strategy] || [];
    const deployed = pts.length > 0;
    const lastExcess = deployed ? pts[pts.length - 1].excess : null;   // cumulative excess vs SGOV
    const lastDuv = deployed ? pts[pts.length - 1].duv : null;
    // strategy_vs_park_daily has a row ONLY for days the sleeve was deployed, so this count is
    // active-time — idle days are absent and never dilute the average.
    const deployedDays = pts.length;
    return {
      strategy: s.strategy, deployed,
      returnPct: (deployed && lastDuv != null) ? lastDuv - 1 : null,   // cumulative actual return (chart/subject)
      excessCum: lastExcess,                                            // cumulative vs SGOV
      // average return vs SGOV per week/month/year — geometric per-period rate over active days only;
      // null = fewer deployed days than the period (not enough history to state that average).
      w1: periodAvg_(lastExcess, deployedDays, TRADING_DAYS_PER.week),
      w1m: periodAvg_(lastExcess, deployedDays, TRADING_DAYS_PER.month),
      w1y: periodAvg_(lastExcess, deployedDays, TRADING_DAYS_PER.year),
      notDeployedReason: deployed ? null : notDeployedReason_(s.activation)
    };
  });

  const sgovLast = sgovSeries.length ? sgovSeries[sgovSeries.length - 1].cum : null;
  const sgovDays = sgovSeries.length;   // SGOV axis = union of deployed days (same active window)
  const sgov = {
    returnPct: sgovLast,
    w1: periodAvg_(sgovLast, sgovDays, TRADING_DAYS_PER.week),
    w1m: periodAvg_(sgovLast, sgovDays, TRADING_DAYS_PER.month),
    w1y: periodAvg_(sgovLast, sgovDays, TRADING_DAYS_PER.year)
  };

  const deployedStrategies = rows.filter(r => r.deployed).map(r => r.strategy);
  const firstDate = sgovSeries.length ? sgovSeries[0].as_of_date : null;

  return { rows, sgov, deployedStrategies, dailyByStrategy, sgovByDate,
           firstDate, health, green, healthReasons, dateLabel, tz };
}

function notDeployedReason_(activation) {
  const a = String(activation || '');
  if (/DO-NOT/i.test(a)) return 'not deployed — router: do-not-activate';
  if (/HYBRID/i.test(a)) return 'not deployed — hybrid, awaiting a qualifying event';
  return 'not deployed — awaiting first deployment';
}

// Geometric AVERAGE return per period, over ACTIVE (deployed) days only. `cum` is the cumulative
// return fraction accrued across `deployedDays` deployed observations; idle days are absent from the
// series so they never enter the denominator (they don't dilute the rate toward 0). Converts that
// whole-window return into an equivalent constant per-period rate:
//   (1 + cum) ^ (tradingDaysPerPeriod / deployedDays) − 1.
// null when deployedDays < the period — not enough deployed history to state that average.
function periodAvg_(cum, deployedDays, tradingDaysPerPeriod) {
  if (cum == null || !deployedDays || deployedDays < tradingDaysPerPeriod) return null;
  return Math.pow(1 + cum, tradingDaysPerPeriod / deployedDays) - 1;
}

// ===== "Why might these numbers be stale?" — only when the data-trust predicate fails =====
function buildHealthReasons_(health, marksFresh, engineFresh, firingKillFlags, killFlagDetails, openCriticalAlerts, criticalAlerts) {
  const reasons = [];
  if (!marksFresh || !engineFresh) {
    const d2Ran = String(health.d2_ran_last_trading_day) === 'true';
    reasons.push(d2Ran
      ? `marks/engine still stale even though D2 logged complete for ${health.last_trading_day} — check state.freshness directly`
      : `today's evening data batch (D2) hasn't completed yet for ${health.last_trading_day} — normal before ~22:30 MT, not a fault by itself`);
  }
  if (firingKillFlags > 0) {
    const shown = killFlagDetails.map(f => {
      const names = ['drawdown_kill', 'runaway_review', 'm2m_underperf_review'].filter(n => String(f[n]) === 'true');
      return `${f.strategy} (${names.join(', ')})`;
    }).join('; ');
    reasons.push(`${firingKillFlags} firing kill-flag(s): ${shown}`);
  }
  if (openCriticalAlerts > 0) {
    const shown = criticalAlerts.map(a => `[${a.category}] ${a.message}`).join('; ');
    const more = openCriticalAlerts > criticalAlerts.length ? ` (+${openCriticalAlerts - criticalAlerts.length} more)` : '';
    reasons.push(`${openCriticalAlerts} critical alert(s): ${shown}${more}`);
  }
  return reasons;
}

// ===== BigQuery helper =====
function bq_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000 }, PROJECT_ID);
  let guard = 0;
  while (!res.jobComplete && guard++ < 10) {
    Utilities.sleep(1000);
    res = BigQuery.Jobs.getQueryResults(PROJECT_ID, res.jobReference.jobId);
  }
  // A query that never completes must FAIL the send (no heartbeat -> dead-man's switch), not render empty.
  if (!res.jobComplete) throw new Error('BigQuery job did not complete after 10s poll: ' + sql.slice(0, 120));
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  return (res.rows || []).map(r => {
    const o = {};
    r.f.forEach((cell, i) => { o[fields[i]] = cell.v; });
    return o;
  });
}

let _tzCache = null;
function getUserTz_() {
  if (_tzCache) return _tzCache;
  try {
    _tzCache = (bq_(`SELECT tz FROM \`${PROJECT_ID}.state.user_tz\``)[0] || {}).tz || 'America/Denver';
  } catch (e) { _tzCache = 'America/Denver'; }
  return _tzCache;
}

// ===== formatting =====
function num_(v)  { return (v === null || v === undefined || v === '') ? null : Number(v); }
function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; } // unicode minus
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }
function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// 'YYYY-MM-DD' -> local-midnight Date (never new Date('YYYY-MM-DD'), which is UTC midnight and
// renders as the previous day in a US-behind-UTC display timezone).
function parseIsoDateLocal_(iso) {
  const p = String(iso).split('-').map(Number);
  return new Date(p[0], p[1] - 1, p[2]);
}

// ===== chart: cumulative total return %, each strategy + SGOV =====
function downsampleDates_(sortedDates) {
  if (sortedDates.length <= 130) return sortedDates;
  const kept = [];
  for (let i = 6; i < sortedDates.length; i += 7) kept.push(sortedDates[i]);
  const last = sortedDates[sortedDates.length - 1];
  if (kept[kept.length - 1] !== last) kept.push(last);
  return kept;
}

function altTextFor_(d) {
  const parts = d.rows.filter(r => r.deployed).map(r => `${r.strategy} ${signPct_(r.returnPct * 100)}`);
  parts.push(`SGOV ${signPct_(d.sgov.returnPct * 100)}`);
  return 'Cumulative return: ' + parts.join(', ');
}

// Returns {blob} or null (caller falls back to HTML bars). Never throws out.
function buildReturnChart_(d) {
  try {
    if (!d.deployedStrategies.length) return null;
    const allDates = Object.keys(d.sgovByDate).sort();
    const keptDates = downsampleDates_(allDates);

    // strategy line = (deployed_unit_value − 1) forward-filled; 0 before its first day.
    const filled = {};
    d.deployedStrategies.forEach(s => {
      const pts = d.dailyByStrategy[s] || [];
      const map = {};
      pts.forEach(p => { if (p.duv != null) map[p.as_of_date] = (p.duv - 1) * 100; });
      const firstDate = pts.length ? pts[0].as_of_date : null;
      let last = 0;
      filled[s] = {};
      keptDates.forEach(iso => {
        if (firstDate == null || iso < firstDate) { filled[s][iso] = 0; return; }
        if (map[iso] != null) last = map[iso];
        filled[s][iso] = last;
      });
    });

    // SGOV first (gray, under the strategy lines).
    const dt = Charts.newDataTable().addColumn(Charts.ColumnType.DATE, 'Date');
    dt.addColumn(Charts.ColumnType.NUMBER, 'SGOV');
    d.deployedStrategies.forEach(s => dt.addColumn(Charts.ColumnType.NUMBER, 'Strategy ' + s));
    keptDates.forEach(iso => {
      const sgovVal = d.sgovByDate[iso] != null ? d.sgovByDate[iso] * 100 : 0;
      dt.addRow([parseIsoDateLocal_(iso), sgovVal].concat(d.deployedStrategies.map(s => filled[s][iso])));
    });

    const chart = Charts.newLineChart().setDataTable(dt.build())
      .setColors([SGOV_GRAY].concat(d.deployedStrategies.map(s => CHART_COLORS[s])))
      .setDimensions(1120, 400)
      .setLegendPosition(Charts.Position.BOTTOM)
      .setPointStyle(Charts.PointStyle.NONE)
      .setBackgroundColor('#fffffe') // opaque near-white; never transparent; PNG pixels aren't inverted by Gmail
      .setYAxisTitle('Cumulative return %')
      .build();
    return { blob: chart.getAs('image/png').setName('strategies_vs_sgov.png') };
  } catch (e) {
    Logger.log('chart build failed, using HTML fallback: ' + e);
    return null;
  }
}

// Gmail-safe fallback: one bar per deployed strategy (cumulative return), + a SGOV bar. Color: green
// if the strategy beat SGOV, red if not; SGOV bar gray.
function fallbackBarsHtml_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const items = deployed.map(r => ({ label: r.strategy, val: r.returnPct * 100, beat: r.returnPct > d.sgov.returnPct }))
    .concat([{ label: 'SGOV', val: d.sgov.returnPct * 100, sgov: true }]);
  const maxAbs = Math.max.apply(null, items.map(it => Math.abs(it.val)).concat([1.0]));
  return items.map(it => {
    const widthPx = Math.max(2, Math.round(Math.abs(it.val) / maxAbs * 240));
    const color = it.sgov ? SGOV_GRAY : (it.beat ? '#1a7f5a' : '#c0392b');
    return `<div style="padding:4px 0;font-size:12px;color:#1f2d3d;">` +
      `<span style="display:inline-block;width:40px;font-weight:700;">${esc_(it.label)}</span>` +
      `<span style="display:inline-block;background-color:${color};width:${widthPx}px;height:12px;vertical-align:middle;"></span>` +
      `<span style="margin-left:8px;color:${color};font-weight:700;">${signPct_(it.val)}</span></div>`;
  }).join('');
}

// ===== HTML =====
function pctCellHtml_(v, colorBySign) {
  if (v == null) return `<span style="color:#8a96a3;font-size:11px;">Not enough data</span>`;
  const color = colorBySign ? clr_(v) : '#3d4a59';
  return `<span style="color:${color};font-weight:${colorBySign ? 700 : 400};">${signPct_(v * 100)}</span>`;
}

function buildHtml_(d, chartResult) {
  const firstLabel = d.firstDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDate), d.tz, 'MMM d') : '—';

  const trustBlock = d.green ? '' : `
  <tr><td style="padding:14px 22px 0 22px;">
    <div style="background-color:#fdf3e3;border-left:4px solid #b9770e;border-radius:8px;padding:10px 14px;font-size:12px;color:#7a4d07;">
      ⚠ Numbers below may be stale — ${esc_(d.healthReasons.join(' · '))}
    </div>
  </td></tr>`;

  // Chart section.
  const notDeployed = d.rows.filter(r => !r.deployed).map(r => r.strategy);
  const notDeployedNote = notDeployed.length ? ` ${notDeployed.join(', ')} not deployed.` : '';
  let chartInner;
  if (!d.deployedStrategies.length) {
    chartInner = `<div style="margin-top:8px;font-size:12px;color:#8a96a3;">Nothing deployed yet — all cash held in SGOV.</div>`;
  } else if (chartResult) {
    chartInner = `<img src="cid:returnchart" width="560" alt="${esc_(altTextFor_(d))}" style="width:100%;max-width:560px;height:auto;display:block;margin-top:8px;">`;
  } else {
    chartInner = `<div style="margin-top:10px;">${fallbackBarsHtml_(d)}</div>`;
  }
  const chartSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Cumulative Return Since ${esc_(firstLabel)} (%)</div>
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">Each strategy's total return; SGOV in gray.${notDeployedNote}</div>
    ${chartInner}
  </td></tr>`;

  // Table: per strategy, average return vs SGOV per week / month / year (active days only); SGOV's own row.
  const strategyRows = d.rows.map(r => {
    const chip = `<span style="display:inline-block;width:10px;height:10px;background-color:${CHART_COLORS[r.strategy] || '#8a96a3'};border-radius:2px;"></span>`;
    if (!r.deployed) {
      return `
      <tr style="background-color:#fafbfc;">
        <td style="padding:9px 8px;">${chip}</td>
        <td style="padding:9px 8px;font-weight:700;color:#8a96a3;">${esc_(r.strategy)}</td>
        <td colspan="3" style="padding:9px 8px;font-size:11px;color:#8a96a3;font-style:italic;">${esc_(r.notDeployedReason)}</td>
      </tr>`;
    }
    return `
      <tr style="background-color:#fffffe;">
        <td style="padding:9px 8px;">${chip}</td>
        <td style="padding:9px 8px;font-weight:700;color:#0f2747;">${esc_(r.strategy)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(r.w1, true)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(r.w1m, true)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(r.w1y, true)}</td>
      </tr>`;
  }).join('');

  const sgovRow = `
      <tr style="background-color:#f5f7fa;">
        <td style="padding:9px 8px;"><span style="display:inline-block;width:10px;height:10px;background-color:${SGOV_GRAY};border-radius:2px;"></span></td>
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">SGOV<div style="font-size:10px;font-weight:400;color:#8a96a3;">own return</div></td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(d.sgov.w1, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(d.sgov.w1m, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(d.sgov.w1y, false)}</td>
      </tr>`;

  const tableSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Average Return vs SGOV</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;"></td>
        <td style="padding:8px;">Strategy</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;week</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;month</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;year</td>
      </tr>${strategyRows}${sgovRow}
    </table>
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">Strategy rows: average return above SGOV per period, measured over active (deployed) time only. SGOV row: its own average return.</div>
  </td></tr>`;

  return `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#eef1f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1f2d3d;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#eef1f5;padding:18px 0;"><tr><td align="center">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:600px;background-color:#fffffe;border-radius:14px;overflow:hidden;box-shadow:0 1px 4px rgba(15,39,71,0.10);">

  <tr><td style="background-color:#0f2747;padding:22px 26px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
      <td style="color:#ffffff;font-size:19px;font-weight:700;">Stock-Trading · Strategies vs SGOV</td>
      <td align="right" style="color:#9fb3cc;font-size:12px;">Week ending<br><span style="color:#ffffff;font-size:13px;font-weight:600;">${esc_(d.dateLabel)}</span></td>
    </tr></table>
    <div style="margin-top:12px;color:#9fb3cc;font-size:12px;">data through ${esc_(d.health.last_mark_date || '—')} close</div>
  </td></tr>
${trustBlock}${chartSection}${tableSection}
  <tr><td style="padding:12px 22px 22px 22px;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">Total return, gross of commissions; SGOV includes dividends. Times in ${esc_(d.tz)}.</div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

// ===== plain-text mirror =====
function buildPlain_(d) {
  const firstLabel = d.firstDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDate), d.tz, 'MMM d') : '—';
  let s = `Stock-Trading — Strategies vs SGOV (${d.dateLabel})\n\n`;
  s += `Data through ${d.health.last_mark_date || '—'} close.\n`;
  if (!d.green) s += `WARNING — numbers below may be stale: ${d.healthReasons.join(' | ')}\n`;
  s += '\n';

  if (!d.deployedStrategies.length) {
    s += `Nothing deployed yet — all cash held in SGOV.\n`;
  } else {
    s += `CUMULATIVE RETURN SINCE ${firstLabel}:\n`;
    d.rows.filter(r => r.deployed).forEach(r => { s += `  ${r.strategy}  ${signPct_(r.returnPct * 100)}\n`; });
    s += `  SGOV  ${signPct_(d.sgov.returnPct * 100)}\n`;
  }

  s += `\nAVERAGE RETURN VS SGOV (per active week / month / year):\n`;
  const fmt = v => (v == null ? 'Not enough data' : signPct_(v * 100));
  d.rows.forEach(r => {
    if (!r.deployed) { s += `  ${r.strategy}  ${r.notDeployedReason}\n`; return; }
    s += `  ${r.strategy}  avg/wk ${fmt(r.w1)}  avg/mo ${fmt(r.w1m)}  avg/yr ${fmt(r.w1y)}\n`;
  });
  s += `  SGOV (own return)  avg/wk ${fmt(d.sgov.w1)}  avg/mo ${fmt(d.sgov.w1m)}  avg/yr ${fmt(d.sgov.w1y)}\n`;

  s += `\nStrategy rows are the average return above SGOV per period, over active (deployed) time only; SGOV row is its own average return. Total return, gross of commissions; SGOV incl. dividends. Times in ${d.tz}.\n`;
  return s;
}

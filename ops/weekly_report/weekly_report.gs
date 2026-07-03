/**
 * Stock-Trading — Weekly System Report: "Strategies vs SGOV" (self-email, fully automatic).
 * =================================================================
 * Runs on GOOGLE'S servers (Apps Script), NOT on Claude's remote-routine server and
 * NOT via the Gmail connector. The official Gmail connector can only DRAFT, not send —
 * so weekly delivery is owned by this script instead. Because you are both sender and
 * recipient (from you, to you), Apps Script is the ideal tool: it runs AS YOU, so
 * GmailApp.sendEmail() needs no SMTP server, no app password, no API key, and no
 * separate sender identity. It builds the HTML and sends in one shot — nothing ever
 * lands in Drafts.
 *
 * PURPOSE (2026-07 redesign): answer exactly one question per strategy — is it beating
 * just parking the cash it was allocated in SGOV? Everything else (regime, account NAV/
 * MTD/YTD, open positions, next-7-days, weekly activity, the full ops-health strip) was
 * cut. See ops/weekly_report/README.md and ops/RUNBOOK.md §33.
 *
 * DATA: read straight from BigQuery (project stock-trading-498512) — the same views the
 * trading routines maintain. No Claude involvement at send time.
 *   - analytics.strategy_scorecard     (per-strategy activation + budget + deployed-slice excess % + gate)
 *   - analytics.strategy_vs_park       (latest $ edge + commissions per strategy — the secondary scale figure)
 *   - analytics.strategy_vs_park_daily (the chart's daily series: excess % PRIMARY + $ edge secondary)
 *   - analytics.deployed_book_vs_sgov  (combined value-weighted excess % — the hero headline)
 *   - state.system_health              (marks/engine freshness + kill-flags + critical alerts —
 *                                        the one surviving data-trust signal)
 *   - state.user_tz                    (detected DISPLAY timezone — never the operating/trading-day tz)
 *   - perf.kill_flags / ops.alerts     (queried lazily, only when system_health flags something)
 *
 * CHART: built server-side via the Apps Script Charts service (Charts.newLineChart()) and
 * embedded as an inline cid PNG — Gmail supports no inline SVG or data-URI images, so cid
 * attachment is the only self-contained image route. Falls back to plain HTML bar rows if
 * the chart build throws; the email must never fail to send because the chart failed.
 *
 * SETUP (one time, ~3 min) — see ops/weekly_report/README.md:
 *   1. script.google.com → New project → paste this file.
 *   2. Project Settings → check "Show appsscript.json"; ensure V8 runtime (default).
 *   3. Editor → Services (+) → add "BigQuery API" (identifier: BigQuery).
 *   4. Set RECIPIENT below to your address (defaults to the project owner's email).
 *   5. Run testReport() once → authorize the BigQuery + Gmail scopes when prompted →
 *      confirm the email arrives, with the line-chart PNG (not the bar fallback).
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

// Fixed per-strategy identity colors (CVD-validated 2026-07-02) — never reassigned by rank,
// presence, or performance. SGOV park is always the gray zero line.
const CHART_COLORS = { A: '#1baf7a', B: '#2a78d6', C: '#4a3aa7', D: '#eb6834', E: '#e87ba4' };
const SGOV_GRAY = '#898781';
const KILL_REVIEW_CHIP = '<span style="display:inline-block;background-color:#fdecea;color:#c0392b;font-size:10px;font-weight:700;padding:3px 8px;border-radius:10px;margin-left:4px;">KILL REVIEW</span>';

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
  const subject = buildSubject_(d);
  const chartResult = buildParkChart_(d.dailyByStrategy, d.deployedStrategies);
  const html = buildHtml_(d, chartResult);
  const plain = buildPlain_(d, chartResult);

  const opts = { htmlBody: html, name: SENDER_NAME };
  if (chartResult) opts.inlineImages = { parkchart: chartResult.blob };

  // From you, to you: runs as the authorized account, so no SMTP/app-password needed.
  GmailApp.sendEmail(RECIPIENT, subject, plain, opts);

  // Optional: label the received copy so weekly reports are filed together.
  if (LABEL_NAME) {
    try {
      const label = GmailApp.getUserLabelByName(LABEL_NAME) || GmailApp.createLabel(LABEL_NAME);
      Utilities.sleep(3000); // let the self-delivered message land
      // NOTE: this search string is coupled to the subject format built in buildSubject_ —
      // update both together.
      GmailApp.search(`subject:"Strategies vs SGOV — ${d.dateLabel}" newer_than:1d`, 0, 5)
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

function buildSubject_(d) {
  const deployedRows = d.rows.filter(r => r.deployed);
  const tag = !deployedRows.length
    ? 'all parked'
    : deployedRows.map(r => r.verdict.key === 'NEUTRAL' ? `${r.strategy} ≈even` : `${r.strategy} ${signPct_(r.excessPct * 100)}`).join(' · ');
  const warn = d.green ? '' : ' · ⚠ check data';
  return `Stock-Trading · Strategies vs SGOV — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== DATA =====
function gatherData_() {
  const tz = getUserTz_();

  const scorecard = bq_(`
    SELECT strategy, activation, is_active, nav, deployed_mv,
           excess_vs_sgov, closed_trades, any_kill_flag
    FROM \`${PROJECT_ID}.analytics.strategy_scorecard\` ORDER BY strategy`);

  const vsPark = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.strategy_vs_park\` ORDER BY strategy`);
  const dailyRows = bq_(`
    SELECT as_of_date, strategy, excess_vs_sgov, edge_dollars_cum
    FROM \`${PROJECT_ID}.analytics.strategy_vs_park_daily\`
    ORDER BY strategy, as_of_date`);
  // Combined deployed-book excess % — the hero's headline (percentages don't sum, so this is the
  // value-weighted aggregate book's own excess, not a sum of per-strategy percentages).
  const book = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.deployed_book_vs_sgov\``)[0] || {};
  const health = bq_(`SELECT * FROM \`${PROJECT_ID}.state.system_health\``)[0] || {};

  const dateLabel = Utilities.formatDate(new Date(), tz, 'MMM d, yyyy');

  // Green predicate: marks/engine freshness + firing kill-flags + CRITICAL alerts only
  // (open_critical_alerts, not open_alerts — a mere warning alert must not trip this).
  // Embeddings/backups/automation/cadence are deliberately excluded (dropped from the email).
  const marksFresh = String(health.marks_fresh) === 'true';
  const engineFresh = String(health.engine_fresh) === 'true';
  const firingKillFlags = num_(health.firing_kill_flags) || 0;
  const openCriticalAlerts = num_(health.open_critical_alerts) || 0;
  const green = marksFresh && engineFresh && firingKillFlags === 0 && openCriticalAlerts === 0;

  // Lazy detail queries — only run when the green predicate above says something needs explaining.
  const killFlagDetails = firingKillFlags > 0 ? bq_(`
    SELECT strategy, drawdown_kill, runaway_review, m2m_underperf_review
    FROM \`${PROJECT_ID}.perf.kill_flags\`
    WHERE drawdown_kill OR runaway_review OR m2m_underperf_review`) : [];
  const criticalAlerts = openCriticalAlerts > 0 ? bq_(`
    SELECT category, message FROM \`${PROJECT_ID}.ops.alerts\`
    WHERE NOT resolved AND severity = 'critical'
    ORDER BY alert_ts DESC LIMIT 3`) : [];

  const healthReasons = green ? [] :
    buildHealthReasons_(health, marksFresh, engineFresh, firingKillFlags, killFlagDetails, openCriticalAlerts, criticalAlerts);

  const vsParkByStrategy = {};
  vsPark.forEach(r => { vsParkByStrategy[r.strategy] = r; });

  // Per-strategy daily series: excess % (the chart's y-axis, PRIMARY) + cumulative $ edge (for the
  // secondary "for scale" note). Both keyed on as_of_date so the .gs can also derive the wk-Δ in pp.
  const dailyByStrategy = {};
  dailyRows.forEach(r => {
    const s = r.strategy;
    if (!dailyByStrategy[s]) dailyByStrategy[s] = [];
    dailyByStrategy[s].push({ as_of_date: r.as_of_date, excess: num_(r.excess_vs_sgov), edge: num_(r.edge_dollars_cum) });
  });

  // One row per strategy, always all five, fixed A→E order (scorecard is already ordered).
  const rows = scorecard.map(s => {
    const vp = vsParkByStrategy[s.strategy];
    const deployed = !!vp;
    const edge = deployed ? num_(vp.edge_dollars_cum) : null;       // $ edge, secondary/for-scale
    const commissions = deployed ? (num_(vp.commissions_to_date) || 0) : 0;
    const excessPct = num_(s.excess_vs_sgov);                        // deployed-slice excess %, PRIMARY
    const excessWkPp = deployed ? excessWkDelta_(dailyByStrategy[s.strategy] || []) : null; // Δ over 7d, fraction
    const closedTrades = num_(s.closed_trades);
    const anyKillFlag = String(s.any_kill_flag) === 'true';
    // Gate-reached derived in JS from closed_trades — do NOT add gate_reached to the
    // scorecard SELECT or query perf.kill_flags for it (perf.03_twr_engine.sql:154 definition).
    const gateReached = closedTrades != null && closedTrades >= 30;
    return {
      strategy: s.strategy, activation: s.activation, nav: num_(s.nav), deployedMv: num_(s.deployed_mv) || 0,
      deployed, edge, excessPct, excessWkPp, commissions, closedTrades, gateReached, anyKillFlag,
      killNames: anyKillFlag ? killFlagNamesFor_(killFlagDetails, s.strategy) : [],
      verdict: verdictFor_(excessPct),
      notDeployedReason: deployed ? null : notDeployedReason_(s.activation)
    };
  });

  const deployedRows = rows.filter(r => r.deployed);
  const deployedStrategies = deployedRows.map(r => r.strategy);
  const combinedEdge = deployedRows.reduce((sum, r) => sum + r.edge, 0);           // $ sum, for scale
  const combinedCommissions = deployedRows.reduce((sum, r) => sum + r.commissions, 0);

  return {
    rows, deployedStrategies, dailyByStrategy,
    combinedExcessPct: num_(book.combined_excess_pct),   // the hero headline %
    bookReturn: num_(book.book_return),
    sgovReturn: num_(book.sgov_return),
    combinedEdge, combinedCommissions,                   // $ sum, kept for the "for scale" note
    firstDeployedDate: book.first_deployed_date || null,
    health, green, healthReasons, dateLabel, tz
  };
}

// ===== per-strategy verdict / classification helpers =====

// Neutral band on the excess RETURN %: within ±1.0 percentage point of SGOV, an edge is too small
// to call "beating"/"trailing" at this sample size, so it reads "≈ even". Beyond the band, colour
// by sign. Earliness (a 0-closed-trade strategy that happens to be ahead) is conveyed separately by
// the gate column + the "provisional before the 30-trade gate" caption, not by masking the number.
const NEUTRAL_BAND_PP = 0.01; // 1.0 percentage point, expressed as a return fraction
function verdictFor_(excessPct) {
  if (excessPct == null) return { key: 'NOT_DEPLOYED', label: 'NOT DEPLOYED', bg: '#edf0f3', fg: '#8a96a3' };
  const rounded = Math.round(excessPct * 10000) / 10000; // to 2dp of a percent, matching the display
  if (rounded >= NEUTRAL_BAND_PP) return { key: 'BEATING', label: 'BEATING PARK', bg: '#e6f4ee', fg: '#1a7f5a' };
  if (rounded <= -NEUTRAL_BAND_PP) return { key: 'TRAILING', label: 'TRAILING PARK', bg: '#fdecea', fg: '#c0392b' };
  return { key: 'NEUTRAL', label: '≈ EVEN WITH PARK', bg: '#fdf3e3', fg: '#b9770e' };
}

// Δ over the trailing ~7 days, in return-fraction terms: latest excess minus the excess at the row
// nearest to (latest date − 7d), ties resolved toward the newer row (points arrive ascending, so a
// <= comparison keeps the later one — matching the SQL 7d-ago tie-break).
function excessWkDelta_(points) {
  if (!points.length) return null;
  const latest = points[points.length - 1];
  if (latest.excess == null) return null;
  const targetMs = parseIsoDateLocal_(latest.as_of_date).getTime() - 7 * 86400000;
  let best = null, bestDiff = Infinity;
  points.forEach(p => {
    const diff = Math.abs(parseIsoDateLocal_(p.as_of_date).getTime() - targetMs);
    if (diff <= bestDiff) { bestDiff = diff; best = p; }
  });
  return (best && best.excess != null) ? latest.excess - best.excess : null;
}

function notDeployedReason_(activation) {
  const a = String(activation || '');
  if (/DO-NOT/i.test(a)) return 'router: do-not-activate';
  if (/HYBRID/i.test(a)) return 'hybrid — awaiting qualifying event';
  return 'awaiting first deployment';
}

function killFlagNamesFor_(details, strategy) {
  let row = null;
  details.forEach(f => { if (f.strategy === strategy) row = f; });
  if (!row) return [];
  return ['drawdown_kill', 'runaway_review', 'm2m_underperf_review'].filter(n => String(row[n]) === 'true');
}

// ===== "Why might these numbers be stale?" — only called when the green predicate fails =====
function buildHealthReasons_(health, marksFresh, engineFresh, firingKillFlags, killFlagDetails, openCriticalAlerts, criticalAlerts) {
  const reasons = [];

  // marks_fresh/engine_fresh only compare dates (see bigquery/10_observability.sql), so a report
  // generated before the evening batch (D2, normally completes ~22:30 MT) will ALWAYS read stale —
  // that's expected same-day lag, not a fault. d2_ran_last_trading_day tells them apart.
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
  // Poll if the job did not finish synchronously (rare for these small queries).
  let guard = 0;
  while (!res.jobComplete && guard++ < 10) {
    Utilities.sleep(1000);
    res = BigQuery.Jobs.getQueryResults(PROJECT_ID, res.jobReference.jobId);
  }
  // A query that never completes must FAIL the send, not silently render as empty data — an
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
function signedMoney2_(v){ return (v >= 0 ? '+' : '−') + '$' + Math.abs(v).toFixed(2); }
function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; }      // unicode minus
function signedPp_(frac){ return (frac >= 0 ? '+' : '−') + Math.abs(frac * 100).toFixed(2) + 'pp'; } // Δ in percentage points
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }
function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// 'YYYY-MM-DD' -> local-midnight Date. Never new Date('YYYY-MM-DD') (UTC midnight — renders as
// the PREVIOUS day once formatted in a US-behind-UTC display timezone).
function parseIsoDateLocal_(iso) {
  const p = String(iso).split('-').map(Number);
  return new Date(p[0], p[1] - 1, p[2]);
}

// ===== chart =====

// Downsample an oversized date axis: keep every 7th trading day plus always the final date.
// Approximates "last date per ISO week" via index-chunking (marks are trading days, not
// calendar days, so calendar-week bucketing would be uneven anyway).
function downsampleDates_(sortedDates) {
  if (sortedDates.length <= 130) return sortedDates;
  const kept = [];
  for (let i = 6; i < sortedDates.length; i += 7) kept.push(sortedDates[i]);
  const last = sortedDates[sortedDates.length - 1];
  if (kept[kept.length - 1] !== last) kept.push(last);
  return kept;
}

function altTextFor_(rows) {
  const deployed = rows.filter(r => r.deployed);
  return 'Cumulative return vs SGOV park: ' + deployed.map(r => `${r.strategy} ${signPct_(r.excessPct * 100)}`).join(', ');
}

// Returns {blob} or null (caller falls back to HTML bars). Never throws out — a bad chart
// must not block the send; bad DATA (via bq_) still must.
function buildParkChart_(dailyByStrategy, deployedStrategies) {
  try {
    if (!deployedStrategies.length) return null;

    const dateSet = {};
    deployedStrategies.forEach(s => {
      (dailyByStrategy[s] || []).forEach(pt => { dateSet[pt.as_of_date] = true; });
    });
    const allDates = Object.keys(dateSet).sort();
    const keptDates = downsampleDates_(allDates);

    // Forward-fill each strategy's cumulative excess RETURN (%) onto the kept dates; 0 before its
    // first as_of_date (fully parked — no deployed slice, so excess vs the park is 0% by
    // construction), so every line spans the full axis. Value plotted is percentage points.
    const filled = {};
    deployedStrategies.forEach(s => {
      const pts = dailyByStrategy[s] || [];
      const map = {};
      pts.forEach(pt => { if (pt.excess != null) map[pt.as_of_date] = pt.excess * 100; });
      const firstDate = pts.length ? pts[0].as_of_date : null;
      let lastVal = 0;
      filled[s] = {};
      keptDates.forEach(iso => {
        if (firstDate == null || iso < firstDate) { filled[s][iso] = 0; return; }
        if (map[iso] != null) lastVal = map[iso];
        filled[s][iso] = lastVal;
      });
    });

    // SGOV park is the FIRST data column (and first setColors entry) so strategy lines draw
    // on top of the baseline — the near-0% region is where a noise-band strategy lives.
    const dt = Charts.newDataTable().addColumn(Charts.ColumnType.DATE, 'Date');
    dt.addColumn(Charts.ColumnType.NUMBER, 'SGOV park');
    deployedStrategies.forEach(s => dt.addColumn(Charts.ColumnType.NUMBER, 'Strategy ' + s));
    keptDates.forEach(iso => {
      const row = [parseIsoDateLocal_(iso), 0].concat(deployedStrategies.map(s => filled[s][iso]));
      dt.addRow(row);
    });

    const chart = Charts.newLineChart().setDataTable(dt.build())
      .setColors([SGOV_GRAY].concat(deployedStrategies.map(s => CHART_COLORS[s])))
      .setDimensions(1120, 400)
      .setLegendPosition(Charts.Position.BOTTOM)
      .setPointStyle(Charts.PointStyle.NONE)
      .setBackgroundColor('#fffffe') // baked opaque near-white; never transparent (dark axis
                                      // text vanishes on dark backgrounds); PNG pixels are
                                      // never inverted by Gmail's dark mode, only CSS colors.
      .setYAxisTitle('% vs SGOV')
      .build();

    return { blob: chart.getAs('image/png').setName('strategies_vs_park.png') };
  } catch (e) {
    Logger.log('chart build failed, using HTML fallback: ' + e);
    return null;
  }
}

// Gmail-safe fallback when the chart build throws: left-anchored magnitude bars sized by |excess %|,
// sign/verdict carried by color (legitimate here — the color MEANS the verdict), signed % beside.
function fallbackBarsHtml_(rows) {
  const deployed = rows.filter(r => r.deployed);
  const maxAbs = Math.max.apply(null, deployed.map(r => Math.abs((r.excessPct || 0) * 100)).concat([1.0]));
  return deployed.map(r => {
    const pctVal = (r.excessPct || 0) * 100;
    const widthPx = Math.max(2, Math.round(Math.abs(pctVal) / maxAbs * 240));
    const color = r.verdict.key === 'BEATING' ? '#1a7f5a' : r.verdict.key === 'TRAILING' ? '#c0392b' : '#b9770e';
    return `<div style="padding:4px 0;font-size:12px;color:#1f2d3d;">` +
      `<span style="display:inline-block;width:16px;font-weight:700;">${esc_(r.strategy)}</span>` +
      `<span style="display:inline-block;background-color:${color};width:${widthPx}px;height:12px;vertical-align:middle;"></span>` +
      `<span style="margin-left:8px;color:${color};font-weight:700;">${signPct_(pctVal)}</span>` +
      `</div>`;
  }).join('');
}

function chipHtml_(v) {
  return `<span style="display:inline-block;background-color:${v.bg};color:${v.fg};font-size:10px;font-weight:700;padding:3px 8px;border-radius:10px;">${esc_(v.label)}</span>`;
}

// ===== HTML =====
function buildHtml_(d, chartResult) {
  const notDeployedLetters = d.rows.filter(r => !r.deployed).map(r => r.strategy);
  const notAllDeployedCaption = (notDeployedLetters.length && d.deployedStrategies.length)
    ? ` ${notDeployedLetters.join(', ')} — never deployed; they sit on the 0% line.`
    : '';

  const trustBlock = d.green ? '' : `
  <tr><td style="padding:14px 22px 0 22px;">
    <div style="background-color:#fdf3e3;border-left:4px solid #b9770e;border-radius:8px;padding:10px 14px;font-size:12px;color:#7a4d07;">
      ⚠ Numbers below may be stale — ${esc_(d.healthReasons.join(' · '))}
    </div>
  </td></tr>`;

  let heroLabel, heroBig, heroSub, heroColor;
  if (!d.deployedStrategies.length) {
    heroLabel = 'ALL DEPLOYED CAPITAL COMBINED';
    heroBig = 'all sleeves parked in SGOV — no deployments yet';
    heroSub = '';
    heroColor = '#0f2747';
  } else {
    const firstLabel = d.firstDeployedDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDeployedDate), d.tz, 'MMM d') : '—';
    heroLabel = `ALL DEPLOYED CAPITAL COMBINED · SINCE FIRST DEPLOYMENT (${firstLabel})`;
    heroBig = d.combinedExcessPct != null ? `${signPct_(d.combinedExcessPct * 100)} vs SGOV` : '—';
    heroSub = `deployed capital returned ${d.bookReturn != null ? signPct_(d.bookReturn * 100) : '—'} vs the SGOV park's ${d.sgovReturn != null ? signPct_(d.sgovReturn * 100) : '—'} over this period (≈${signedMoney2_(d.combinedEdge)} in dollars, gross of ${money2_(d.combinedCommissions)} commissions).`;
    const combinedVerdict = verdictFor_(d.combinedExcessPct);
    heroColor = combinedVerdict.key === 'BEATING' ? '#1a7f5a' : combinedVerdict.key === 'TRAILING' ? '#c0392b' : '#0f2747';
  }

  const chartSectionHeader = `<div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Cumulative Return vs SGOV Park (%, deployed capital)</div>`;
  let chartSection;
  if (!d.deployedStrategies.length) {
    chartSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    ${chartSectionHeader}
    <div style="margin-top:8px;font-size:12px;color:#8a96a3;">Nothing has ever deployed — all sleeves fully parked (0% excess by construction).</div>
  </td></tr>`;
  } else if (chartResult) {
    chartSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    ${chartSectionHeader}
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">SGOV park = the gray 0% line. Above it = beating the park; flat = parked/idle.${notAllDeployedCaption}</div>
    <img src="cid:parkchart" width="560" alt="${esc_(altTextFor_(d.rows))}" style="width:100%;max-width:560px;height:auto;display:block;margin-top:8px;">
  </td></tr>`;
  } else {
    chartSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    ${chartSectionHeader}
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">SGOV park = the gray 0% line. Above it = beating the park; flat = parked/idle.${notAllDeployedCaption}</div>
    <div style="margin-top:10px;">${fallbackBarsHtml_(d.rows)}</div>
  </td></tr>`;
  }

  const killRows = d.rows.filter(r => r.anyKillFlag);
  const killDetailHtml = killRows.length
    ? `<div style="margin-top:8px;font-size:11px;color:#c0392b;">Kill review firing: ${esc_(killRows.map(r => `${r.strategy} (${r.killNames.join(', ')})`).join('; '))}</div>`
    : '';

  const tableRows = d.rows.map(r => {
    const chipColor = CHART_COLORS[r.strategy] || '#8a96a3';
    const subtextParts = [`alloc ${money0_(r.nav)}`];
    if (r.deployedMv > 0) subtextParts.push(`deployed ${money2_(r.deployedMv)}`);
    if (r.commissions > 0) subtextParts.push(`comm. ${money2_(r.commissions)}`);

    // PRIMARY numeric: the deployed-slice excess % (big), with the sleeve $ edge muted underneath
    // as the secondary "for scale" figure.
    const pctColor = r.verdict.key === 'NEUTRAL' ? '#8a96a3' : (r.excessPct >= 0 ? '#1a7f5a' : '#c0392b');
    const pctCell = r.deployed && r.excessPct != null
      ? `<div style="color:${pctColor};font-weight:700;">${signPct_(r.excessPct * 100)}</div>` +
        `<div style="font-size:10px;color:#8a96a3;">${signedMoney2_(r.edge)} vs park</div>`
      : `<span style="color:#8a96a3;">—</span>`;
    const wkCell = (r.deployed && r.excessWkPp != null)
      ? `<span style="color:${r.excessWkPp >= 0 ? '#1a7f5a' : '#c0392b'};">${signedPp_(r.excessWkPp)}</span>` : '—';
    const gateCell = r.deployed
      ? `${r.closedTrades != null ? r.closedTrades : '—'}/30${r.gateReached ? ' ✓' : ''}` : '—';
    const rowTextColor = r.deployed ? '#0f2747' : '#8a96a3';

    return `
      <tr style="background-color:${r.deployed ? '#fffffe' : '#fafbfc'};">
        <td style="padding:9px 8px;"><span style="display:inline-block;width:10px;height:10px;background-color:${chipColor};border-radius:2px;"></span></td>
        <td style="padding:9px 8px;">
          <div style="font-weight:700;color:${rowTextColor};">${esc_(r.strategy)}</div>
          <div style="font-size:10px;color:#8a96a3;">${esc_(subtextParts.join(' · '))}</div>
          ${!r.deployed ? `<div style="font-size:10px;color:#8a96a3;font-style:italic;">${esc_(r.notDeployedReason)}</div>` : ''}
        </td>
        <td style="padding:9px 8px;">${chipHtml_(r.verdict)}${r.anyKillFlag ? KILL_REVIEW_CHIP : ''}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCell}</td>
        <td style="padding:9px 8px;text-align:right;">${wkCell}</td>
        <td style="padding:9px 8px;text-align:right;color:${rowTextColor};">${gateCell}</td>
      </tr>`;
  }).join('');

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
${trustBlock}
  <tr><td style="padding:20px 18px 6px 18px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
      <td style="padding:4px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f7fa;border-radius:10px;"><tr><td style="padding:18px 16px;text-align:center;">
          <div style="font-size:11px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.5px;">${esc_(heroLabel)}</div>
          <div style="font-size:26px;font-weight:700;color:${heroColor};margin-top:6px;">${esc_(heroBig)}</div>
          ${heroSub ? `<div style="font-size:12px;color:#8a96a3;margin-top:6px;">${esc_(heroSub)}</div>` : ''}
        </td></tr></table>
      </td>
    </tr></table>
  </td></tr>
${chartSection}
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Strategy Verdicts</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;"></td>
        <td style="padding:8px;">Strategy</td>
        <td style="padding:8px;">Verdict</td>
        <td style="padding:8px;text-align:right;">vs SGOV %</td>
        <td style="padding:8px;text-align:right;">Δ wk</td>
        <td style="padding:8px;text-align:right;">Closed trades / 30</td>
      </tr>${tableRows}
    </table>
    ${killDetailHtml}
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">"vs SGOV %" is the deployed-slice excess return (the return on capital actually put to work, over SGOV); the small $ figure is the sleeve-level dollar edge for scale. Δ wk is the change in that excess over the trailing 7 days, in percentage points. Verdicts are provisional before a strategy's 30-trade gate (spec: ~30 closed trades is the first point an honest directional claim can be made).</div>
  </td></tr>

  <tr><td style="padding:16px 22px 22px 22px;">
    <hr style="border:none;border-top:1px solid #e3e8ee;margin:0 0 12px 0;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">
      vs SGOV % = deployed-TWR unit value ÷ SGOV index − 1, over the strategy's own deployed days (<code>perf.strategy_daily</code> — the kill/gate metric); the combined hero figure value-weights all deployed strategies into one book. The $ figures are the sleeve-level dollar edge = deployed dollars × (deployed return − SGOV total return), summed over deployed days (undeployed sleeve cash sits in the SGOV park, so its edge is 0 by construction). Figures are nominal, pre-tax/pre-inflation, and GROSS of commissions (owner directive 2026-06-05; per-sleeve commissions shown above). Benchmark = SGOV actual total return incl. monthly dividends. Auto-generated weekly from BigQuery; times in ${esc_(d.tz)} (detected).
    </div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

// ===== plain-text fallback =====
// Mirrors every section buildHtml_ renders from the SAME `d` object, same null-guarding
// discipline (NULL -> '—', never a bare "+0.00%").
function buildPlain_(d) {
  let s = `Stock-Trading — Strategies vs SGOV (${d.dateLabel})\n\n`;
  s += `Data through ${d.health.last_mark_date || '—'} close.\n`;
  if (!d.green) {
    s += `WARNING — numbers below may be stale: ${d.healthReasons.join(' | ')}\n`;
  }
  s += '\n';

  if (!d.deployedStrategies.length) {
    s += `ALL DEPLOYED CAPITAL COMBINED: all sleeves parked in SGOV — no deployments yet.\n\n`;
  } else {
    const firstLabel = d.firstDeployedDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDeployedDate), d.tz, 'MMM d') : '—';
    const combPct = d.combinedExcessPct != null ? signPct_(d.combinedExcessPct * 100) : '—';
    const bookR = d.bookReturn != null ? signPct_(d.bookReturn * 100) : '—';
    const sgovR = d.sgovReturn != null ? signPct_(d.sgovReturn * 100) : '—';
    s += `ALL DEPLOYED CAPITAL COMBINED (since first deployment ${firstLabel}): ${combPct} vs SGOV\n`;
    s += `  deployed capital returned ${bookR} vs the SGOV park's ${sgovR} over this period (≈${signedMoney2_(d.combinedEdge)} in dollars, gross of ${money2_(d.combinedCommissions)} commissions).\n\n`;
    s += `CHART DATA (cumulative % vs SGOV park): ${altTextFor_(d.rows).replace('Cumulative return vs SGOV park: ', '')}\n\n`;
  }

  s += `STRATEGY VERDICTS:\n`;
  d.rows.forEach(r => {
    if (!r.deployed) {
      s += `  ${r.strategy}  NOT DEPLOYED (${r.notDeployedReason})  alloc ${money0_(r.nav)}\n`;
    } else {
      const pct = r.excessPct != null ? signPct_(r.excessPct * 100) : '—';
      const wk = r.excessWkPp != null ? signedPp_(r.excessWkPp) : '—';
      const gate = `${r.closedTrades != null ? r.closedTrades : '—'}/30${r.gateReached ? ' (gate reached)' : ''}`;
      s += `  ${r.strategy}  ${r.verdict.label}  vs SGOV ${pct} (${signedMoney2_(r.edge)} $)  Δwk ${wk}  gate ${gate}` +
           `  alloc ${money0_(r.nav)} · deployed ${money2_(r.deployedMv)} · comm. ${money2_(r.commissions)}` +
           `${r.anyKillFlag ? '  [KILL REVIEW: ' + r.killNames.join(', ') + ']' : ''}\n`;
    }
  });
  s += `\nVerdicts are provisional before a strategy's 30-trade gate. "vs SGOV %" is the deployed-slice excess return; the $ figure is the sleeve-level dollar edge.\n`;

  s += `\nMETHODOLOGY: vs SGOV % = deployed-TWR unit value / SGOV index - 1, over the strategy's own deployed days (perf.strategy_daily); the combined figure value-weights all deployed strategies into one book. $ edge = deployed dollars x (deployed return - SGOV total return), summed over deployed days (undeployed sleeve cash sits in the SGOV park, edge 0 by construction). Figures are nominal, pre-tax/pre-inflation, and GROSS of commissions. Benchmark = SGOV actual total return incl. monthly dividends. Times in ${d.tz} (detected).\n`;

  return s;
}

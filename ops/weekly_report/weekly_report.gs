/**
 * Stock-Trading — Weekly System Report: "Deployed vs Benchmarks" (self-email, fully automatic).
 * =================================================================
 * Runs on GOOGLE'S servers (Apps Script), NOT on Claude's remote-routine server and NOT via the
 * Gmail connector (which can only draft, not send). Runs AS YOU (self-email), so no SMTP / app
 * password / API key. Builds the HTML and sends in one shot — nothing lands in Drafts.
 *
 * PURPOSE (2026-07-13 redesign, owner directive): answer two questions —
 *   1. Per strategy — is it beating SGOV? — as a percentage (unchanged from the 2026-07 redesign;
 *      still the sanctioned kill/gate metric, perf.strategy_daily.excess_vs_sgov).
 *   2. At the whole-deployed-book level — is deploying capital beating BOTH just parking it in SGOV
 *      AND just buying the S&P 500 (VOO), over the same dollars and the same days? A new headline
 *      block answers this directly: cumulative %, average/month, average/year, and dollars.
 *   * A returns chart: each deployed strategy's cumulative total return + SGOV's own return line +
 *     VOO's own return line (once VOO has backfilled history — see analytics.voo_cumulative).
 *   * A headline block: deployed book vs SGOV vs VOO — cumulative %, avg/month, avg/year (†
 *     = annualized from fewer than 252 deployed days — extrapolated), and the "same dollars, same
 *     days" $ edge (that day's actual deployed capital notionally earning the benchmark's return).
 *   * A per-strategy table: AVERAGE return vs SGOV per month / year — a geometric per-period rate
 *     over ACTIVE (deployed) time only, so idle stretches never dilute it ("Not enough data" until
 *     at least 21 deployed days exist for ANY period — MIN_AVG_DAYS, hardcoded inside periodAvg_),
 *     plus SGOV's and VOO's own average-return rows.
 * Everything else (combined aggregate beyond the headline, verdict labels, weekly-Δ, gate counts,
 * regime, account NAV, positions, activity, ops strip) is intentionally omitted.
 *
 * VOO IS PURELY INFORMATIONAL — it never feeds perf.kill_flags, state.strategy_retirement_candidacy,
 * or any other live decision surface. Only SGOV is the sanctioned kill/gate benchmark. See the header
 * of bigquery/46_weekly_benchmarks.sql for the full methodology (same deployed-day-set for all three
 * legs; SGOV forward-fills a missing mark, VOO reads a gap as 0% — see that file for why).
 *
 * DATA (BigQuery, project stock-trading-498512):
 *   - analytics.strategy_scorecard          (the A-E list + activation, for the not-deployed reason)
 *   - analytics.strategy_vs_park_daily      (per strategy-day: deployed_unit_value + cumulative excess_vs_sgov)
 *   - analytics.sgov_cumulative             (SGOV's own cumulative total return, aligned to the same dates)
 *   - analytics.voo_cumulative              (VOO's own cumulative total return, same date axis; NULL before its first mark)
 *   - analytics.deployed_book_vs_benchmarks (ONE row: book/SGOV/VOO % + "same dollars, same days" $ — the headline block)
 *   - state.system_health                   (marks/engine freshness + kill-flags + critical alerts — data-trust)
 *   - state.user_tz                         (detected DISPLAY timezone — never the operating/trading-day tz)
 *   - perf.kill_flags / ops.alerts          (queried lazily, only when system_health flags something)
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
const SCRIPT_VERSION = 'v2';                       // bump on every functional change to this file; read by state.script_version_drift (bigquery/43_script_version_registry.sql) -- keep bigquery/43's MERGE seed in lockstep
const SUBJECT_LABEL = 'Deployed vs Benchmarks';    // Single source for this phrase across buildSubject_, the post-send GmailApp.search() match, and the HTML/plain-text banners below. Edit only here on a rename (2026-07-14 audit finding -- this already drifted once by hand across 4 sites during the 2026-07-13 VOO rename).

// Fixed per-strategy identity colors (CVD-validated) — never reassigned by rank/presence. SGOV is
// gray; VOO is a distinct steel blue-gray chosen to not collide with Strategy B's blue or SGOV's gray.
const CHART_COLORS = { A: '#1baf7a', B: '#2a78d6', C: '#4a3aa7', D: '#eb6834', E: '#e87ba4' };
const SGOV_GRAY = '#898781';
const VOO_COLOR = '#5f7d95';

// Trading days per period — the denominator basis for the per-period average return (month=21,
// year=252 trading days). periodAvg_ additionally requires >=21 deployed days before stating ANY
// average (hardcoded inside periodAvg_ itself as MIN_AVG_DAYS) — below that even a monthly average
// is noise; this is also why per-week reporting was dropped in the 2026-07-13 redesign.
const TRADING_DAYS_PER = { month: 21, year: 252 };

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

  // Self-addressed mail (RECIPIENT === the sender) lands in the Inbox already marked READ — a Gmail
  // quirk where sending IS the read event when From/To are the same account. Force the just-sent
  // thread back to unread, and apply the label, in one lookup. Best-effort — must never fail the send.
  try {
    Utilities.sleep(3000);
    // Search string derives from SUBJECT_LABEL, same single source as buildSubject_ below.
    const threads = GmailApp.search(`subject:"${SUBJECT_LABEL} — ${d.dateLabel}" newer_than:1d`, 0, 5);
    threads.forEach(t => t.markUnread());
    if (LABEL_NAME) {
      const label = GmailApp.getUserLabelByName(LABEL_NAME) || GmailApp.createLabel(LABEL_NAME);
      threads.forEach(t => t.addLabel(label));
    }
  } catch (e) { Logger.log('Post-send thread housekeeping (unread/label) skipped: ' + e); }

  // Liveness beat — lets cadence_check.sql detect a silently-dead weekly report. Best-effort.
  try {
    BigQuery.Jobs.query({
      query: `INSERT INTO \`${PROJECT_ID}.ops.heartbeat\` (source, note, version) VALUES ('weekly_report', 'sent', '${SCRIPT_VERSION}')`,
      useLegacySql: false, timeoutMs: 30000
    }, PROJECT_ID);
  } catch (e) { Logger.log('heartbeat write skipped: ' + e); }

  Logger.log('Weekly report sent to %s', RECIPIENT);
}

function buildSubject_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  let tag;
  if (!deployed.length) {
    tag = 'all parked';
  } else {
    tag = deployed.map(r => `${r.strategy} ${signPct_(r.returnPct * 100)}`).join(' · ')
      + ` · SGOV ${signPct_(d.sgov.returnPct * 100)}`;
    // VOO fragment only in the deployed branch, and only once VOO has real data in the window —
    // never render a null through signPct_ (which would print "−NaN%").
    if (d.headline && d.headline.voo && d.headline.voo.returnPct != null) {
      tag += ` · VOO ${signPct_(d.headline.voo.returnPct * 100)}`;
    }
  }
  const warn = d.green ? '' : ' · ⚠ check data';
  return `Stock-Trading · ${SUBJECT_LABEL} — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== DATA =====
function gatherData_() {
  const tz = getUserTzWeekly_();

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

  const vooRows = bq_(`
    SELECT as_of_date, voo_cum_return
    FROM \`${PROJECT_ID}.analytics.voo_cumulative\`
    ORDER BY as_of_date`);

  const headlineRows = bq_(`SELECT * FROM \`${PROJECT_ID}.analytics.deployed_book_vs_benchmarks\``);

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

  // VOO's own cumulative return series (same date axis; NULL before VOO's first observed mark).
  const vooSeries = vooRows.map(r => ({ as_of_date: r.as_of_date, cum: num_(r.voo_cum_return) }));
  const vooByDate = {};
  vooSeries.forEach(p => { vooByDate[p.as_of_date] = p.cum; });

  // Headline block: deployed book vs SGOV vs VOO, over the SAME deployed-day set. One row, or an
  // all-NULL row when nothing has ever been deployed (COUNT(*) still returns 0, not a missing row).
  const headlineRaw = headlineRows[0] || {};
  const nDeployedDays = num_(headlineRaw.n_deployed_days) || 0;
  const nVooMarkDays = num_(headlineRaw.n_voo_mark_days) || 0;
  const headline = nDeployedDays > 0 ? {
    firstDeployedDate: headlineRaw.first_deployed_date,
    asOfDate: headlineRaw.as_of_date,
    nDeployedDays: nDeployedDays,
    nVooMarkDays: nVooMarkDays,
    vooLastMarkDate: headlineRaw.voo_last_mark_date || null,
    book: benchmarkRow_(num_(headlineRaw.book_return), nDeployedDays),
    sgov: benchmarkRow_(num_(headlineRaw.sgov_return), nDeployedDays),
    voo: nVooMarkDays > 0 ? benchmarkRow_(num_(headlineRaw.voo_return), nDeployedDays) : null,
    deployedPnlDollars: num_(headlineRaw.deployed_pnl_dollars),
    sgovCounterfactualDollars: num_(headlineRaw.sgov_counterfactual_dollars),
    vooCounterfactualDollars: num_(headlineRaw.voo_counterfactual_dollars),
    edgeVsSgovDollars: num_(headlineRaw.edge_vs_sgov_dollars),
    edgeVsVooDollars: num_(headlineRaw.edge_vs_voo_dollars)
  } : null;

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
      // average return vs SGOV per month/year — geometric per-period rate over active days only;
      // null = fewer than 21 deployed days (not enough history to state ANY average).
      avgMonth: periodAvg_(lastExcess, deployedDays, TRADING_DAYS_PER.month),
      avgYear: periodAvg_(lastExcess, deployedDays, TRADING_DAYS_PER.year),
      extrapolatedYear: isExtrapolated_(deployedDays, TRADING_DAYS_PER.year),
      notDeployedReason: deployed ? null : notDeployedReason_(s.activation)
    };
  });

  const sgovLast = sgovSeries.length ? sgovSeries[sgovSeries.length - 1].cum : null;
  const sgovDays = sgovSeries.length;   // SGOV axis = union of deployed days (same active window)
  const sgov = benchmarkRow_(sgovLast, sgovDays);

  const deployedStrategies = rows.filter(r => r.deployed).map(r => r.strategy);
  const firstDate = sgovSeries.length ? sgovSeries[0].as_of_date : null;

  return { rows, sgov, voo: headline ? headline.voo : null, headline,
           deployedStrategies, dailyByStrategy, sgovByDate, vooByDate,
           firstDate, health, green, healthReasons, dateLabel, tz };
}

function notDeployedReason_(activation) {
  const a = String(activation || '');
  if (/DO-NOT/i.test(a)) return 'not deployed — router: do-not-activate';
  if (/HYBRID/i.test(a)) return 'not deployed — hybrid, awaiting a qualifying event';
  if (/execution-feasibility-deferred/i.test(a)) return 'not deployed — execution-feasibility-deferred (book too small for single-share legs; needs ~$250k total book vs current ~$1.9k)';
  return 'not deployed — awaiting first deployment';
}

// Geometric AVERAGE return per period, over ACTIVE (deployed) days only. `cum` is the cumulative
// return fraction accrued across `deployedDays` deployed observations; idle days are absent from the
// series so they never enter the denominator (they don't dilute the rate toward 0). Converts that
// whole-window return into an equivalent constant per-period rate:
//   (1 + cum) ^ (tradingDaysPerPeriod / deployedDays) − 1.
// null when deployedDays < 21 (MIN_AVG_DAYS, hardcoded here so this stays a self-contained pure
// function) — below that, not enough deployed history to state ANY average, independent of which
// period was requested; a strategy/benchmark with exactly `tradingDaysPerPeriod` deployed days still
// needs to clear this floor before its whole-window rate is shown.
function periodAvg_(cum, deployedDays, tradingDaysPerPeriod) {
  if (cum == null || !deployedDays || deployedDays < 21) return null;
  return Math.pow(1 + cum, tradingDaysPerPeriod / deployedDays) - 1;
}

// True when there is at least one deployed day but fewer than a full period's worth — the avg/year
// (or avg/month) figure is a compounded EXTRAPOLATION from partial history, not a directly observed
// full-period rate. Marked with a † in the UI.
function isExtrapolated_(deployedDays, tradingDaysPerPeriod) {
  return deployedDays > 0 && deployedDays < tradingDaysPerPeriod;
}

// Shapes a benchmark's (or the deployed book's) OWN cumulative return into the {cumulative, avg/month,
// avg/year, extrapolated?} shape the headline block and the SGOV/VOO table rows share. Hardcodes
// 21/252 (matching TRADING_DAYS_PER.month/.year) rather than referencing that file-level const, so
// this stays a self-contained pure function safe to copy verbatim into test_pure_helpers.js.
function benchmarkRow_(returnPct, days) {
  return {
    returnPct: returnPct,
    avgMonth: periodAvg_(returnPct, days, 21),
    avgYear: periodAvg_(returnPct, days, 252),
    extrapolatedYear: isExtrapolated_(days, 252)
  };
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
function getUserTzWeekly_() {
  if (_tzCache) return _tzCache;
  try {
    _tzCache = (bq_(`SELECT tz FROM \`${PROJECT_ID}.state.user_tz\``)[0] || {}).tz || 'America/Denver';
  } catch (e) { Logger.log('getUserTzWeekly_ failed, defaulting to America/Denver: ' + e); _tzCache = 'America/Denver'; }
  return _tzCache;
}

// ===== formatting =====
function num_(v)  { return (v === null || v === undefined || v === '') ? null : Number(v); }
function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; } // unicode minus
function signDollar_(v) { return (v >= 0 ? '+$' : '−$') + Math.abs(v).toFixed(2); } // unicode minus
function fmtAbsDollars_(v) { return '$' + Math.abs(v).toFixed(2); }
function edgeWord_(v) { return v >= 0 ? 'beat' : 'trailed'; }
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }
// KEEP IN SYNC MANUALLY with esc2_() in ops/monitoring/alert_emailer.gs — byte-for-byte identical on
// purpose (separate Apps Script projects can't share a module), also copied verbatim into
// ops/weekly_report/test_pure_helpers.js. A future escaping fix (e.g. backticks for a template-literal
// context) applied to one twin must be applied to both, or one of the two operator-facing HTML emails
// silently stops getting it (2026-07-09 code-review finding).
function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

// 'YYYY-MM-DD' -> local-midnight Date (never new Date('YYYY-MM-DD'), which is UTC midnight and
// renders as the previous day in a US-behind-UTC display timezone).
function parseIsoDateLocal_(iso) {
  const p = String(iso).split('-').map(Number);
  return new Date(p[0], p[1] - 1, p[2]);
}

// ===== chart: cumulative total return %, each strategy + SGOV + VOO =====
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
  if (d.headline && d.headline.voo && d.headline.voo.returnPct != null) {
    parts.push(`VOO ${signPct_(d.headline.voo.returnPct * 100)}`);
  }
  return 'Cumulative return: ' + parts.join(', ');
}

// Returns {blob} or null (caller falls back to HTML bars). Never throws out.
function buildReturnChart_(d) {
  try {
    if (!d.deployedStrategies.length) return null;
    const allDates = Object.keys(d.sgovByDate).sort();
    const keptDates = downsampleDates_(allDates);
    const hasVoo = !!(d.headline && d.headline.nVooMarkDays > 0);

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

    // SGOV first (gray), VOO second (steel blue) if it has data — both under the strategy lines.
    const dt = Charts.newDataTable().addColumn(Charts.ColumnType.DATE, 'Date');
    dt.addColumn(Charts.ColumnType.NUMBER, 'SGOV');
    if (hasVoo) dt.addColumn(Charts.ColumnType.NUMBER, 'VOO');
    d.deployedStrategies.forEach(s => dt.addColumn(Charts.ColumnType.NUMBER, 'Strategy ' + s));
    keptDates.forEach(iso => {
      const sgovVal = d.sgovByDate[iso] != null ? d.sgovByDate[iso] * 100 : 0;
      const row = [parseIsoDateLocal_(iso), sgovVal];
      if (hasVoo) {
        const vooVal = d.vooByDate[iso];
        row.push(vooVal != null ? vooVal * 100 : null); // null -> a gap in the line, not a false 0
      }
      d.deployedStrategies.forEach(s => row.push(filled[s][iso]));
      dt.addRow(row);
    });

    const colors = [SGOV_GRAY].concat(hasVoo ? [VOO_COLOR] : []).concat(d.deployedStrategies.map(s => CHART_COLORS[s] || '#8a96a3'));
    const chart = Charts.newLineChart().setDataTable(dt.build())
      .setColors(colors)
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

// Gmail-safe fallback: one bar per deployed strategy (cumulative return), + a SGOV bar, + a VOO bar
// (if VOO has data). Color: green if the strategy beat SGOV, red if not; SGOV bar gray, VOO bar steel.
function fallbackBarsHtml_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const items = deployed.map(r => ({ label: r.strategy, val: r.returnPct * 100, beat: r.returnPct > d.sgov.returnPct }))
    .concat([{ label: 'SGOV', val: d.sgov.returnPct * 100, neutral: true }]);
  if (d.headline && d.headline.voo && d.headline.voo.returnPct != null) {
    items.push({ label: 'VOO', val: d.headline.voo.returnPct * 100, neutral: true, vooColor: true });
  }
  const maxAbs = Math.max.apply(null, items.map(it => Math.abs(it.val)).concat([1.0]));
  return items.map(it => {
    const widthPx = Math.max(2, Math.round(Math.abs(it.val) / maxAbs * 240));
    const color = it.vooColor ? VOO_COLOR : (it.neutral ? SGOV_GRAY : (it.beat ? '#1a7f5a' : '#c0392b'));
    return `<div style="padding:4px 0;font-size:12px;color:#1f2d3d;">` +
      `<span style="display:inline-block;width:40px;font-weight:700;">${esc_(it.label)}</span>` +
      `<span style="display:inline-block;background-color:${color};width:${widthPx}px;height:12px;vertical-align:middle;"></span>` +
      `<span style="margin-left:8px;color:${color};font-weight:700;">${signPct_(it.val)}</span></div>`;
  }).join('');
}

// ===== HTML =====
function pctCellHtml_(v, colorBySign, extrapolated) {
  if (v == null) return `<span style="color:#8a96a3;font-size:11px;">Not enough data</span>`;
  const color = colorBySign ? clr_(v) : '#3d4a59';
  const marker = extrapolated ? '†' : '';
  return `<span style="color:${color};font-weight:${colorBySign ? 700 : 400};">${signPct_(v * 100)}${marker}</span>`;
}

function dollarCellHtml_(v, colorBySign) {
  if (v == null) return `<span style="color:#8a96a3;font-size:11px;">Not enough data</span>`;
  const color = colorBySign ? clr_(v) : '#3d4a59';
  return `<span style="color:${color};font-weight:${colorBySign ? 700 : 400};">${signDollar_(v)}</span>`;
}

function headlineSectionHtml_(d) {
  if (!d.headline) return '';
  const h = d.headline;
  const firstLabel = h.firstDeployedDate ? Utilities.formatDate(parseIsoDateLocal_(h.firstDeployedDate), d.tz, 'MMM d') : '—';
  const voo = h.voo || { returnPct: null, avgMonth: null, avgYear: null, extrapolatedYear: false };

  const takeawayParts = [];
  if (h.edgeVsSgovDollars != null) takeawayParts.push(`${edgeWord_(h.edgeVsSgovDollars)} SGOV by ${fmtAbsDollars_(h.edgeVsSgovDollars)}`);
  if (h.edgeVsVooDollars != null) takeawayParts.push(`${edgeWord_(h.edgeVsVooDollars)} VOO by ${fmtAbsDollars_(h.edgeVsVooDollars)}`);
  const takeawayHtml = takeawayParts.length
    ? `<div style="margin-top:8px;font-size:12px;color:#3d4a59;">Deploying ${takeawayParts.join(' · ')} — over the same dollars and days.</div>`
    : '';

  const vooStale = h.voo && h.vooLastMarkDate && h.asOfDate && h.vooLastMarkDate < h.asOfDate;
  const vooStaleHtml = vooStale
    ? `<div style="margin-top:6px;font-size:11px;color:#b9770e;">⚠ VOO data through ${esc_(h.vooLastMarkDate)}.</div>`
    : '';

  return `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Deployed Book Since ${esc_(firstLabel)} (${h.nDeployedDays} trading days)</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;"></td>
        <td style="padding:8px;text-align:right;">cumulative</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;month</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;year</td>
        <td style="padding:8px;text-align:right;">$&nbsp;(same&nbsp;dollars,&nbsp;same&nbsp;days)</td>
      </tr>
      <tr style="background-color:#fffffe;">
        <td style="padding:9px 8px;font-weight:700;color:#0f2747;">Deployed book</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.book.returnPct, true)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.book.avgMonth, true)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.book.avgYear, true, h.book.extrapolatedYear)}</td>
        <td style="padding:9px 8px;text-align:right;">${dollarCellHtml_(h.deployedPnlDollars, false)}</td>
      </tr>
      <tr style="background-color:#f5f7fa;">
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">SGOV (parked)</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.sgov.returnPct, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.sgov.avgMonth, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(h.sgov.avgYear, false, h.sgov.extrapolatedYear)}</td>
        <td style="padding:9px 8px;text-align:right;">${dollarCellHtml_(h.sgovCounterfactualDollars, false)}</td>
      </tr>
      <tr style="background-color:#fffffe;">
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">VOO (S&amp;P 500)</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(voo.returnPct, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(voo.avgMonth, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(voo.avgYear, false, voo.extrapolatedYear)}</td>
        <td style="padding:9px 8px;text-align:right;">${dollarCellHtml_(h.vooCounterfactualDollars, false)}</td>
      </tr>
    </table>
    ${takeawayHtml}${vooStaleHtml}
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">$ = the book's actual deployed dollars each day, notionally earning the benchmark's return that day, summed (not a compounding buy-and-hold). † = annualized from fewer than 252 deployed days — extrapolated. Total return incl. dividends, gross of commissions.</div>
  </td></tr>`;
}

function buildHtml_(d, chartResult) {
  const firstLabel = d.firstDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDate), d.tz, 'MMM d') : '—';
  const hasVoo = !!(d.headline && d.headline.nVooMarkDays > 0);

  const trustBlock = d.green ? '' : `
  <tr><td style="padding:14px 22px 0 22px;">
    <div style="background-color:#fdf3e3;border-left:4px solid #b9770e;border-radius:8px;padding:10px 14px;font-size:12px;color:#7a4d07;">
      ⚠ Numbers below may be stale — ${esc_(d.healthReasons.join(' · '))}
    </div>
  </td></tr>`;

  const headlineSection = headlineSectionHtml_(d);

  // Chart section.
  const notDeployed = d.rows.filter(r => !r.deployed).map(r => esc_(r.strategy));
  const notDeployedNote = notDeployed.length ? ` ${notDeployed.join(', ')} not deployed.` : '';
  const benchmarkCaption = hasVoo ? 'SGOV (gray) and VOO (steel blue) benchmarks.' : 'SGOV in gray.';
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
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">Each strategy's total return; ${benchmarkCaption}${notDeployedNote}</div>
    ${chartInner}
  </td></tr>`;

  // Table: per strategy, average return vs SGOV per month / year (active days only); SGOV's + VOO's own rows.
  const strategyRows = d.rows.map(r => {
    const chip = `<span style="display:inline-block;width:10px;height:10px;background-color:${CHART_COLORS[r.strategy] || '#8a96a3'};border-radius:2px;"></span>`;
    if (!r.deployed) {
      return `
      <tr style="background-color:#fafbfc;">
        <td style="padding:9px 8px;">${chip}</td>
        <td style="padding:9px 8px;font-weight:700;color:#8a96a3;">${esc_(r.strategy)}</td>
        <td colspan="2" style="padding:9px 8px;font-size:11px;color:#8a96a3;font-style:italic;">${esc_(r.notDeployedReason)}</td>
      </tr>`;
    }
    return `
      <tr style="background-color:#fffffe;">
        <td style="padding:9px 8px;">${chip}</td>
        <td style="padding:9px 8px;font-weight:700;color:#0f2747;">${esc_(r.strategy)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(r.avgMonth, true)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(r.avgYear, true, r.extrapolatedYear)}</td>
      </tr>`;
  }).join('');

  const sgovRow = `
      <tr style="background-color:#f5f7fa;">
        <td style="padding:9px 8px;"><span style="display:inline-block;width:10px;height:10px;background-color:${SGOV_GRAY};border-radius:2px;"></span></td>
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">SGOV<div style="font-size:10px;font-weight:400;color:#8a96a3;">own return</div></td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(d.sgov.avgMonth, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(d.sgov.avgYear, false, d.sgov.extrapolatedYear)}</td>
      </tr>`;

  const vooOwn = d.voo || { avgMonth: null, avgYear: null, extrapolatedYear: false };
  const vooRow = `
      <tr style="background-color:#fffffe;">
        <td style="padding:9px 8px;"><span style="display:inline-block;width:10px;height:10px;background-color:${VOO_COLOR};border-radius:2px;"></span></td>
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">VOO<div style="font-size:10px;font-weight:400;color:#8a96a3;">own return</div></td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(vooOwn.avgMonth, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(vooOwn.avgYear, false, vooOwn.extrapolatedYear)}</td>
      </tr>`;

  const tableSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Average Return vs SGOV</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;"></td>
        <td style="padding:8px;">Strategy</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;month</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;year</td>
      </tr>${strategyRows}${sgovRow}${vooRow}
    </table>
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">Strategy rows: average return above SGOV per period, measured over active (deployed) time only. SGOV/VOO rows: their own average return. † = annualized from fewer than 252 deployed days — extrapolated.</div>
  </td></tr>`;

  return `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background-color:#eef1f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1f2d3d;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#eef1f5;padding:18px 0;"><tr><td align="center">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:600px;background-color:#fffffe;border-radius:14px;overflow:hidden;box-shadow:0 1px 4px rgba(15,39,71,0.10);">

  <tr><td style="background-color:#0f2747;padding:22px 26px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
      <td style="color:#ffffff;font-size:19px;font-weight:700;">Stock-Trading · ${SUBJECT_LABEL}</td>
      <td align="right" style="color:#9fb3cc;font-size:12px;">Week ending<br><span style="color:#ffffff;font-size:13px;font-weight:600;">${esc_(d.dateLabel)}</span></td>
    </tr></table>
    <div style="margin-top:12px;color:#9fb3cc;font-size:12px;">data through ${esc_(d.health.last_mark_date || '—')} close</div>
  </td></tr>
${trustBlock}${headlineSection}${chartSection}${tableSection}
  <tr><td style="padding:12px 22px 22px 22px;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">Total return, gross of commissions; SGOV and VOO include dividends. Times in ${esc_(d.tz)}.</div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

// ===== plain-text mirror =====
function buildPlain_(d) {
  const firstLabel = d.firstDate ? Utilities.formatDate(parseIsoDateLocal_(d.firstDate), d.tz, 'MMM d') : '—';
  const fmtP = (v, ex) => (v == null ? 'Not enough data' : signPct_(v * 100) + (ex ? '†' : ''));
  const fmtD = v => (v == null ? 'Not enough data' : signDollar_(v));

  let s = `Stock-Trading — ${SUBJECT_LABEL} (${d.dateLabel})\n\n`;
  s += `Data through ${d.health.last_mark_date || '—'} close.\n`;
  if (!d.green) s += `WARNING — numbers below may be stale: ${d.healthReasons.join(' | ')}\n`;
  s += '\n';

  if (d.headline) {
    const h = d.headline;
    const voo = h.voo || { returnPct: null, avgMonth: null, avgYear: null, extrapolatedYear: false };
    const hFirstLabel = h.firstDeployedDate ? Utilities.formatDate(parseIsoDateLocal_(h.firstDeployedDate), d.tz, 'MMM d') : '—';
    s += `DEPLOYED BOOK SINCE ${hFirstLabel} (${h.nDeployedDays} trading days):\n`;
    s += `  Book  cum ${fmtP(h.book.returnPct)}  avg/mo ${fmtP(h.book.avgMonth)}  avg/yr ${fmtP(h.book.avgYear, h.book.extrapolatedYear)}  $ ${fmtD(h.deployedPnlDollars)}\n`;
    s += `  SGOV  cum ${fmtP(h.sgov.returnPct)}  avg/mo ${fmtP(h.sgov.avgMonth)}  avg/yr ${fmtP(h.sgov.avgYear, h.sgov.extrapolatedYear)}  $ ${fmtD(h.sgovCounterfactualDollars)}\n`;
    s += `  VOO   cum ${fmtP(voo.returnPct)}  avg/mo ${fmtP(voo.avgMonth)}  avg/yr ${fmtP(voo.avgYear, voo.extrapolatedYear)}  $ ${fmtD(h.vooCounterfactualDollars)}\n`;
    const takeawayParts = [];
    if (h.edgeVsSgovDollars != null) takeawayParts.push(`${edgeWord_(h.edgeVsSgovDollars)} SGOV by ${fmtAbsDollars_(h.edgeVsSgovDollars)}`);
    if (h.edgeVsVooDollars != null) takeawayParts.push(`${edgeWord_(h.edgeVsVooDollars)} VOO by ${fmtAbsDollars_(h.edgeVsVooDollars)}`);
    if (takeawayParts.length) s += `  Deploying ${takeawayParts.join(' · ')} — over the same dollars and days.\n`;
    if (h.voo && h.vooLastMarkDate && h.asOfDate && h.vooLastMarkDate < h.asOfDate) {
      s += `  ⚠ VOO data through ${h.vooLastMarkDate}.\n`;
    }
    s += '\n';
  }

  if (!d.deployedStrategies.length) {
    s += `Nothing deployed yet — all cash held in SGOV.\n`;
  } else {
    s += `CUMULATIVE RETURN SINCE ${firstLabel}:\n`;
    d.rows.filter(r => r.deployed).forEach(r => { s += `  ${r.strategy}  ${signPct_(r.returnPct * 100)}\n`; });
    s += `  SGOV  ${signPct_(d.sgov.returnPct * 100)}\n`;
    if (d.headline && d.headline.voo && d.headline.voo.returnPct != null) {
      s += `  VOO  ${signPct_(d.headline.voo.returnPct * 100)}\n`;
    }
  }

  s += `\nAVERAGE RETURN VS SGOV (per active month / year):\n`;
  d.rows.forEach(r => {
    if (!r.deployed) { s += `  ${r.strategy}  ${r.notDeployedReason}\n`; return; }
    s += `  ${r.strategy}  avg/mo ${fmtP(r.avgMonth)}  avg/yr ${fmtP(r.avgYear, r.extrapolatedYear)}\n`;
  });
  s += `  SGOV (own return)  avg/mo ${fmtP(d.sgov.avgMonth)}  avg/yr ${fmtP(d.sgov.avgYear, d.sgov.extrapolatedYear)}\n`;
  const vooOwn = d.voo || { avgMonth: null, avgYear: null, extrapolatedYear: false };
  s += `  VOO (own return)  avg/mo ${fmtP(vooOwn.avgMonth)}  avg/yr ${fmtP(vooOwn.avgYear, vooOwn.extrapolatedYear)}\n`;

  s += `\nStrategy rows are the average return above SGOV per period, over active (deployed) time only; SGOV/VOO rows are their own average return. † = annualized from fewer than 252 deployed days. Total return, gross of commissions; SGOV/VOO incl. dividends. Times in ${d.tz}.\n`;
  return s;
}

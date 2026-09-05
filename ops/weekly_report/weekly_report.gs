/**
 * Stock-Trading — Weekly System Report: "Deployed vs Benchmarks" (self-email, fully automatic).
 * =================================================================
 * Runs on GOOGLE'S servers (Apps Script), NOT on Claude's remote-routine server and NOT via the
 * Gmail connector (which can only draft, not send). Runs AS YOU (self-email), so no SMTP / app
 * password / API key. Builds the HTML and sends in one shot — nothing lands in Drafts.
 *
 * PURPOSE (2026-07-15 redesign, owner directive): answer, for each strategy, "what's its own return
 * been?" — measured on deployed capital only, over active (deployed) time only — and show it next to
 * VOO's own return as a single informational reference point. No vs-SGOV comparison anywhere in this
 * email (SGOV was dropped from the subject line, chart, and table per the 2026-07-15 directive; the
 * prior "Deployed Book Since..." headline section is gone entirely).
 *   * A returns chart: each deployed strategy's cumulative total return + VOO's own cumulative return,
 *     each plotted as its own natural (non-rebased) line from its own first observed date — VOO is
 *     never zeroed/rebased to the deployed-book start date.
 *   * A per-strategy table ("Average Return"): each strategy's OWN average return per month / year — a
 *     geometric per-period rate over ACTIVE (deployed) time only, so idle stretches never dilute it
 *     ("Not enough data" until at least 21 deployed days exist for ANY period — MIN_AVG_DAYS, hardcoded
 *     inside periodAvg_), plus VOO's own average-return row for reference.
 * Everything else (a deployed-book-vs-benchmark headline block, $-edge figures, combined aggregate,
 * verdict labels, weekly-Δ, gate counts, regime, account NAV, positions, activity, ops strip) is
 * intentionally omitted.
 *
 * VOO IS PURELY INFORMATIONAL — it never feeds perf.kill_flags, state.strategy_retirement_candidacy,
 * or any other live decision surface. SGOV remains the sanctioned kill/gate benchmark internally
 * (perf.strategy_daily.excess_vs_sgov) — this email simply no longer DISPLAYS that comparison; the
 * kill/gate machinery itself is untouched by the 2026-07-15 directive (owner-directive scope: this
 * email + the idle-capital parking vehicle only — see events.decision_log 2026-07-15). See the header
 * of bigquery/46_weekly_benchmarks.sql for the full benchmark methodology.
 *
 * PARK SECTION (2026-07-18, PARK_ROUTER_DESIGN.md v2 §9 — the AI Park Allocator): a compact block
 * below the per-strategy table showing the park's current ALLOCATION, days in that allocation,
 * allocation changes in the last 30 days, and the park's own realized TWR vs the three
 * counterfactuals (100% SGOV, 100% VOO, and the record-only v1 rule-shadow) from
 * analytics.park_counterfactuals. Degrades gracefully (never fails the send) if bigquery/91-93 are
 * not yet applied live — see gatherParkData_.
 *   * v10 (2026-09-04) makes it PARK v4 aware. The book is a GRADED TWO-SLEEVE allocation as of
 *     bigquery/220 + 221 (live 2026-09-04), so "current vehicle" is no longer the book: `vehicle` is
 *     now written by D2 as the MAJORITY sleeve, and a real f=0→25→50 reallocation would have rendered
 *     as an unchanged "VOO · 0 switches / 30d". The section now renders the split and counts changes
 *     of the whole allocation — see gatherParkData_.
 *   * v10 also grades the allocator on the AI-ERA anchor bigquery/212 (2026-09-03) added, with the
 *     inception-anchored quartet demoted below it: the published inception series inherits the
 *     owner's 2026-07-15 SGOV→VOO cutover, and 212 measured that the sign of AI-vs-SGOV FLIPS between
 *     the two anchors. Every quartet states the anchor it was measured on.
 *
 * DATA (BigQuery, project stock-trading-498512):
 *   - analytics.strategy_scorecard          (the A-E list + activation, for the not-deployed reason)
 *   - analytics.strategy_vs_park_daily      (per strategy-day: deployed_unit_value — each strategy's
 *                                             own cumulative return; a row exists ONLY on deployed
 *                                             days, so idle time never dilutes the average)
 *   - analytics.voo_cumulative              (VOO's own cumulative total return, own date axis from its
 *                                             first observed mark; NULL before that mark, never rebased)
 *   - state.system_health                   (marks/engine freshness + kill-flags + critical alerts — data-trust;
 *                                             the CADENCE-AWARE marks_current/engine_current pair, bigquery/173)
 *   - state.user_tz                         (detected DISPLAY timezone — never the operating/trading-day tz)
 *   - perf.kill_flags / ops.alerts          (queried lazily, only when system_health flags something)
 *   - events.park_policy_changes / state.park_policy_current  (2026-07-18: current park allocation +
 *                                             tenure + change cadence, PARK section; v4 two-sleeve
 *                                             columns target_f_pct / risk_sleeve / defensive_sleeve
 *                                             since bigquery/220)
 *   - analytics.park_counterfactuals        (2026-07-18: park's own realized TWR vs SGOV / VOO /
 *                                             rule-shadow, PARK section — bigquery/93_park_accounting.sql;
 *                                             AI-era-anchored quartet since bigquery/212)
 *
 * Retained but no longer read by this email (matches this file's established "retain, don't delete"
 * convention for superseded views): analytics.sgov_cumulative, analytics.deployed_book_vs_benchmarks,
 * analytics.strategy_vs_park, analytics.park_baseline, analytics.deployed_book_vs_sgov.
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
const SCRIPT_VERSION = 'v10';                      // bump on every functional change to this file; read by state.script_version_drift (bigquery/43_script_version_registry.sql) -- keep bigquery/43's MERGE seed in lockstep
const SUBJECT_LABEL = 'Deployed vs Benchmarks';    // Single source for this phrase across buildSubject_, the post-send GmailApp.search() match, and the HTML/plain-text banners below. Edit only here on a rename (2026-07-14 audit finding -- this already drifted once by hand across 4 sites during the 2026-07-13 VOO rename).

// Fixed per-strategy identity colors (CVD-validated) — never reassigned by rank/presence. VOO is a
// distinct steel blue-gray chosen to not collide with Strategy B's blue. Complete to the SISA roster
// ceiling (strategy/roster.yaml n_max=8), not just today's members: the autonomous lifecycle can
// adopt F/G/H with no human step, and two strategies sharing the fallback gray would render as
// mutually indistinguishable lines in the chart, legend and table chip. F/G/H hues chosen to stay
// CVD-distinguishable from A–E, from each other, and from VOO_COLOR.
const CHART_COLORS = { A: '#1baf7a', B: '#2a78d6', C: '#4a3aa7', D: '#eb6834', E: '#e87ba4',
                       F: '#8a6d1f', G: '#00868b', H: '#8b2f6b' };
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
    tag = deployed.map(r => `${r.strategy} ${fmtRetPct_(r.returnPct)}`).join(' · ');
    // VOO fragment only in the deployed branch, and only once VOO has real data in the window —
    // never render a null through signPct_ (which would print "−NaN%").
    if (d.voo && d.voo.returnPct != null) {
      tag += ` · VOO ${signPct_(d.voo.returnPct * 100)}`;
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
    SELECT as_of_date, strategy, deployed_unit_value
    FROM \`${PROJECT_ID}.analytics.strategy_vs_park_daily\`
    ORDER BY strategy, as_of_date`);

  const vooRows = bq_(`
    SELECT as_of_date, voo_cum_return
    FROM \`${PROJECT_ID}.analytics.voo_cumulative\`
    ORDER BY as_of_date`);

  const health = bq_(`SELECT * FROM \`${PROJECT_ID}.state.system_health\``)[0] || {};

  const dateLabel = Utilities.formatDate(new Date(), tz, 'MMM d, yyyy');

  // Data-trust predicate: marks/engine current + no firing kill-flags + no critical alerts.
  // CADENCE-AWARE as of v10 (bigquery/173, 2026-08-15). marks_fresh / engine_fresh compare against the
  // MARKET last_trading_day, which on a Sunday is FRIDAY, while D2a (the only writer of
  // events.daily_marks) runs `40 22 * * 0,1,2,3,4` and backfills Friday only on its SUNDAY 22:40 UTC
  // run — so the strict pair is STRUCTURALLY FALSE from Friday evening through that Sunday D2a slot
  // under the Sun-Thu daily tier. This email sends at SEND_WEEKDAY=SUNDAY / SEND_HOUR=7 script-tz,
  // ~9h EARLIER, so `green` was false at EVERY send: the " · ⚠ check data" subject suffix and the
  // amber "numbers below may be stale" banner have printed on every weekly report since 2026-08-08,
  // making a genuinely stale week indistinguishable from a healthy one. marks_current /
  // engine_current use the schedule-derived state.freshness.marks_due_through basis instead — the
  // same terms state.system_health.all_green and the dashboard banner (ops/dashboard/
  // generate_dashboard.py) already moved to in 173; 173's own header claimed it had repointed this
  // caveat too, and only the dashboard half was actually done.
  // The strict pair stays as the FALLBACK, not as the basis: a pre-173 live view simply has no
  // marks_current column, which reads back undefined, so `!= null` is false and the old term is used.
  // Do NOT repurpose the strict pair here — bigquery/173 deliberately left it BYTE-IDENTICAL because
  // bigquery/107's trading gates read it directly and need the stricter meaning.
  const marksFresh  = String(health.marks_current  != null ? health.marks_current  : health.marks_fresh)  === 'true';
  const engineFresh = String(health.engine_current != null ? health.engine_current : health.engine_fresh) === 'true';
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

  // Per-strategy daily series: cumulative return (deployed_unit_value) only — no vs-SGOV excess.
  const dailyByStrategy = {};
  dailyRows.forEach(r => {
    const s = r.strategy;
    if (!dailyByStrategy[s]) dailyByStrategy[s] = [];
    dailyByStrategy[s].push({ as_of_date: r.as_of_date, duv: num_(r.deployed_unit_value) });
  });

  // VOO's own cumulative return series — its own axis, from its own first observed mark; NULL before
  // that first mark. Never rebased against any strategy's deployed-day window (directive 3: a natural,
  // independent line).
  const vooSeries = vooRows.map(r => ({ as_of_date: r.as_of_date, cum: num_(r.voo_cum_return) }));
  const vooByDate = {};
  vooSeries.forEach(p => { vooByDate[p.as_of_date] = p.cum; });
  const vooNonNull = vooSeries.filter(p => p.cum != null);
  const nVooMarkDays = vooNonNull.length;
  const vooLastMarkDate = nVooMarkDays ? vooNonNull[nVooMarkDays - 1].as_of_date : null;
  const voo = benchmarkRow_(nVooMarkDays ? vooNonNull[nVooMarkDays - 1].cum : null, nVooMarkDays);
  const asOfDate = vooSeries.length ? vooSeries[vooSeries.length - 1].as_of_date : null;
  const firstDate = vooSeries.length ? vooSeries[0].as_of_date : null;

  // One row per roster strategy, in code order (A→E today; up to n_max=8 under SISA).
  const rows = scorecard.map(s => {
    const pts = dailyByStrategy[s.strategy] || [];
    const deployed = pts.length > 0;
    const lastDuv = deployed ? pts[pts.length - 1].duv : null;
    // strategy_vs_park_daily has a row ONLY for days the sleeve was deployed, so this count is
    // active-time — idle days are absent and never dilute the average. This is also why returnPct/
    // avgMonth/avgYear below are already computed on deployed capital only, never idle-parked capital.
    const deployedDays = pts.length;
    const returnPct = (deployed && lastDuv != null) ? lastDuv - 1 : null;   // strategy's OWN cumulative return
    return {
      strategy: s.strategy, deployed,
      returnPct,
      // average OWN return per month/year — geometric per-period rate over active days only;
      // null = fewer than 21 deployed days (not enough history to state ANY average).
      avgMonth: periodAvg_(returnPct, deployedDays, TRADING_DAYS_PER.month),
      avgYear: periodAvg_(returnPct, deployedDays, TRADING_DAYS_PER.year),
      extrapolatedYear: isExtrapolated_(deployedDays, TRADING_DAYS_PER.year),
      notDeployedReason: deployed ? null : notDeployedReason_(s.activation)
    };
  });

  const deployedStrategies = rows.filter(r => r.deployed).map(r => r.strategy);

  const park = gatherParkData_();

  return { rows, voo, nVooMarkDays, vooLastMarkDate, deployedStrategies, dailyByStrategy, vooByDate,
           firstDate, asOfDate, health, green, healthReasons, dateLabel, tz, park };
}

// ===== PARK (AI Park Allocator, PARK_ROUTER_DESIGN.md v2 §9, 2026-07-18; PARK v4 since 2026-09-04) =====
// Two independently try/caught query LANES — bigquery/91_park_signal_layer.sql / 92_park_allocator.sql /
// 93_park_accounting.sql may not be applied live yet at the time this script is redeployed (the .gs
// re-paste and the SQL apply are two separate owner/routine actions), and a missing table here must
// never fail the whole weekly send, mirroring buildReturnChart_'s "chart must never fail the send"
// posture. Each lane degrades independently: an allocation-query failure still lets the counterfactuals
// render (and vice versa), and gatherData_'s caller renders "n/a"/"Not enough data" throughout when
// either half is unavailable — never a fabricated 0/undefined.
// v10 (2026-09-04) gives EACH lane its own inner legacy fallback rather than widening the one query.
// Both lanes now ask for columns that only exist post-bigquery/220 (target_f_pct / risk_sleeve /
// defensive_sleeve) and post-bigquery/212 (ai_era_start_date + the four *_ai_era columns), and a single
// widened query against an older live view would THROW and take the whole block down with it — losing
// output this file renders correctly today. The fallback re-issues the pre-v4 / pre-212 SELECT, so an
// unapplied SQL migration degrades to the OLD rendering instead of a missing section.
function gatherParkData_() {
  let vehicleRow = {};
  try {
    // current_vehicle/days_in_allocation from state.park_policy_current (bigquery/54 -> 220);
    // switches_30d counts every ACTUAL change of the FULL ALLOCATION (any direction —
    // de-risk/re-risk/lateral, unlike state.park_switch_budget's up/lateral-only scope) recorded in
    // events.park_policy_changes in the trailing 30 days, via the same LAG-over-event_ts "did it
    // actually change" idiom bigquery/92_park_allocator.sql's state.park_switch_budget view uses
    // (event_ts is the house transition-time discriminator — never effective_date, bigquery/54's
    // documented fix).
    // KEYED ON THE ALLOCATION, NOT ON `vehicle` (v10). Through v9 this LAGged `vehicle` and its comment
    // claimed to count "every ACTUAL vehicle change" — true for the binary book, false since PARK v4
    // went live on idle capital 2026-09-04 (bigquery/220 + 221). bigquery/220's header: `vehicle` STAYS
    // POPULATED and D2 keeps writing it as the MAJORITY sleeve, tie at f=50 going to the RISK sleeve —
    // so PARK_ALLOCATOR_V4_DESIGN.md's own replayed f=0→25→50 week has vehicle='VOO' throughout and
    // would have rendered as "VOO · 0 switches / 30d" while the book moved twice (and while
    // effective_date advanced on every conversion, so the same line also read "1 day"). alloc_key is
    // the whole allocation, so a graded move is a change and a no-op re-log is not.
    // The COALESCEs belong on the RAW events rows only: they replay bigquery/220's own legacy mapping
    // (target_f_pct NULL = a pre-v4 single-vehicle policy; vehicle 'VOO' means f=0, anything else means
    // f=100 with that vehicle AS the defensive sleeve) so pre-v4 history keys exactly as it always did.
    // `cur` needs none — state.park_policy_current already resolves that mapping itself.
    vehicleRow = bq_(`
      WITH keyed AS (
        SELECT event_ts,
               FORMAT('%s|%d|%s',
                      COALESCE(risk_sleeve, 'VOO'),
                      COALESCE(target_f_pct, IF(vehicle = 'VOO', 0, 100)),
                      COALESCE(defensive_sleeve, IF(vehicle = 'VOO', 'SGOV', vehicle))) AS alloc_key
        FROM \`${PROJECT_ID}.events.park_policy_changes\`
      ), ordered AS (
        SELECT event_ts, alloc_key,
               LAG(alloc_key) OVER (ORDER BY event_ts) AS prev_alloc_key
        FROM keyed
      ), cur AS (
        SELECT vehicle, effective_date, target_f_pct, risk_sleeve, defensive_sleeve
        FROM \`${PROJECT_ID}.state.park_policy_current\`
      )
      SELECT
        cur.vehicle AS current_vehicle,
        cur.target_f_pct,
        cur.risk_sleeve,
        cur.defensive_sleeve,
        DATE_DIFF(CURRENT_DATE('America/Denver'), cur.effective_date, DAY) AS days_in_allocation,
        (SELECT COUNT(*) FROM ordered
           WHERE prev_alloc_key IS NOT NULL AND alloc_key != prev_alloc_key
             AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)) AS switches_30d
      FROM cur`)[0] || {};
  } catch (e) {
    Logger.log('gatherParkData_ v4 allocation query failed (bigquery/220 not live?), retrying the pre-v4 vehicle query: ' + e);
    try {
      // Pre-v4 fallback: the v9 query verbatim, aliased to the same days_in_allocation key so the
      // renderers read one shape. target_f_pct/risk_sleeve/defensive_sleeve stay absent here, which is
      // exactly what buildParkSection_/buildPlain_ treat as "render the single-vehicle label".
      vehicleRow = bq_(`
        WITH ordered AS (
          SELECT event_ts, vehicle,
                 LAG(vehicle) OVER (ORDER BY event_ts) AS prev_vehicle
          FROM \`${PROJECT_ID}.events.park_policy_changes\`
        ), cur AS (
          SELECT vehicle, effective_date FROM \`${PROJECT_ID}.state.park_policy_current\`
        )
        SELECT
          cur.vehicle AS current_vehicle,
          DATE_DIFF(CURRENT_DATE('America/Denver'), cur.effective_date, DAY) AS days_in_allocation,
          (SELECT COUNT(*) FROM ordered
             WHERE prev_vehicle IS NOT NULL AND vehicle != prev_vehicle
               AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)) AS switches_30d
        FROM cur`)[0] || {};
    } catch (e2) { Logger.log('gatherParkData_ vehicle query skipped (bigquery/54 not live?): ' + e2); }
  }

  let cfRow = {};
  try {
    // Latest row of analytics.park_counterfactuals (bigquery/93_park_accounting.sql, redefined by
    // bigquery/212) — the park's own realized TWR (ai_index) alongside the three
    // PARK_ROUTER_DESIGN.md v2 §9 counterfactuals: 100% SGOV (sgov_index), 100% VOO (voo_index), and
    // the record-only v1 rule-shadow (rule_index).
    // AI-ERA QUARTET (v10, bigquery/212 2026-09-03). The five original columns are inception-anchored
    // (2026-04-17), and that window contains the OWNER's 2026-07-15 manual SGOV→VOO transfer, which is
    // not an allocator decision. 212 measured the decomposition: pre-AI −1.83pp, AI era +0.67pp,
    // published inception −1.17pp — "the published verdict is ENTIRELY inherited from the pre-AI
    // segment ... The sign flips." 212's own reader enumeration missed this file, so its corrected
    // columns were wired into W5's scorecard and not into the operator-facing email. They are selected
    // here so the AI-era quartet can LEAD the section, with the inception quartet kept and demoted.
    // NULL-by-design when no BOUND allocator call exists yet (212 emits ai_era_start_date NULL and all
    // four rebased columns NULL rather than anchoring at row zero); num_() maps that to null and
    // buildParkSection_ then renders the inception quartet alone.
    cfRow = bq_(`
      SELECT as_of_date, ai_index, sgov_index, voo_index, rule_index,
             ai_era_start_date, ai_index_ai_era, sgov_index_ai_era, voo_index_ai_era, rule_index_ai_era
      FROM \`${PROJECT_ID}.analytics.park_counterfactuals\`
      ORDER BY as_of_date DESC LIMIT 1`)[0] || {};
  } catch (e) {
    Logger.log('gatherParkData_ AI-era counterfactuals query failed (bigquery/212 not live?), retrying the pre-212 columns: ' + e);
    try {
      // Pre-212 fallback: the v9 five-column SELECT verbatim. The AI-era keys stay absent, so the
      // section degrades to exactly the v9 rendering rather than losing the whole table.
      cfRow = bq_(`
        SELECT as_of_date, ai_index, sgov_index, voo_index, rule_index
        FROM \`${PROJECT_ID}.analytics.park_counterfactuals\`
        ORDER BY as_of_date DESC LIMIT 1`)[0] || {};
    } catch (e2) { Logger.log('gatherParkData_ counterfactuals query skipped (bigquery/91-93 not live yet?): ' + e2); }
  }

  return {
    vehicle: vehicleRow.current_vehicle || null,
    // v4 two-sleeve fields; all null on the pre-v4 fallback path above.
    targetFPct: num_(vehicleRow.target_f_pct),
    riskSleeve: vehicleRow.risk_sleeve || null,
    defensiveSleeve: vehicleRow.defensive_sleeve || null,
    daysInAllocation: num_(vehicleRow.days_in_allocation),
    switches30d: num_(vehicleRow.switches_30d),
    asOfDate: cfRow.as_of_date || null,
    ai: num_(cfRow.ai_index),
    sgov: num_(cfRow.sgov_index),
    voo: num_(cfRow.voo_index),
    rule: num_(cfRow.rule_index),
    // AI-era-anchored quartet + the anchor date itself; all null pre-212 or before the first BOUND call.
    aiEraStart: cfRow.ai_era_start_date || null,
    aiEra: num_(cfRow.ai_index_ai_era),
    sgovEra: num_(cfRow.sgov_index_ai_era),
    vooEra: num_(cfRow.voo_index_ai_era),
    ruleEra: num_(cfRow.rule_index_ai_era)
  };
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

// Shapes a benchmark's OWN cumulative return into the {returnPct, avg/month, avg/year, extrapolated?}
// shape the VOO table row shares with the strategy rows. Hardcodes 21/252 (matching
// TRADING_DAYS_PER.month/.year) rather than referencing that file-level const, so this stays a
// self-contained pure function safe to copy verbatim into test_pure_helpers.js.
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
    // v10: marksFresh/engineFresh are the CADENCE-AWARE terms now (see gatherData_) — "marks cover every
    // trading day a scheduled D2a run has already been able to ingest", i.e. state.freshness.
    // marks_due_through, NOT the MARKET last_trading_day. The reason text must key on the same basis the
    // predicate did, or it misdirects: on a Sunday, last_trading_day is FRIDAY while marks_due_through is
    // Thursday, so the old wording would have named Friday (whose D2a slot has not arrived yet) for a gap
    // that is actually at Thursday — and worse, d2_ran_last_trading_day is FALSE every Sunday, so it would
    // have taken the benign "not a fault by itself" branch for a genuinely missed, already-elapsed slot.
    // A cadence-aware miss is BY CONSTRUCTION a slot that has already elapsed, so the benign branch cannot
    // apply to it. The pre-173 wording is kept below, unchanged, for a live view with no marks_due_through
    // column — there the predicate really did fall back to the strict last_trading_day pair, so its
    // last_trading_day / d2_ran_last_trading_day framing is the correct one.
    const dueThrough = health.marks_due_through;
    if (dueThrough != null && dueThrough !== '') {
      reasons.push(`marks/engine do not cover ${dueThrough} — the last trading day D2a was already scheduled to ingest, so this is a real gap, not the normal pre-22:30 MT wait — check state.freshness directly`);
    } else {
      const d2Ran = String(health.d2_ran_last_trading_day) === 'true';
      reasons.push(d2Ran
        ? `marks/engine still stale even though D2 logged complete for ${health.last_trading_day} — check state.freshness directly`
        : `today's evening data batch (D2) hasn't completed yet for ${health.last_trading_day} — normal before ~22:30 MT, not a fault by itself`);
    }
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
// KEEP IN SYNC MANUALLY with bqAlerts_() in ops/monitoring/alert_emailer.gs -- byte-for-byte identical
// on purpose (each file must keep working if re-pasted/redeployed independent of the other -- see
// ops/RUNBOOK.md's v9->v10 alert_emailer-only re-paste while this file stayed untouched, and
// alert_emailer.gs's own "independent of Apps Script and Gmail" channel-independence design). NOT
// merged into one shared helper despite both files sharing one Apps Script project's top-level scope
// (see alert_emailer.gs's SETUP note) -- a cross-file call would make one script's delivery depend on
// the OTHER script's copy staying correct, defeating the independent re-paste discipline. The actual
// drift guard is ops/weekly_report/test_pure_helpers.js's bq_/bqAlerts_ parity test, which stubs
// BigQuery.Jobs.query/getQueryResults deterministically and asserts both twins behave identically on a
// single-page response, a paginated response, and a permanently-incomplete job; this comment is only a
// pointer to it (2026-09-02 audit finding -- previously unguarded, unlike the esc_/esc2_ pair below).
function bq_(sql) {
  let res = BigQuery.Jobs.query({ query: sql, useLegacySql: false, timeoutMs: 30000, maxResults: 10000 }, PROJECT_ID);
  let guard = 0;
  while (!res.jobComplete && guard++ < 10) {
    Utilities.sleep(1000);
    res = BigQuery.Jobs.getQueryResults(PROJECT_ID, res.jobReference.jobId);
  }
  // A query that never completes must FAIL the send (no heartbeat -> dead-man's switch), not render empty.
  if (!res.jobComplete) throw new Error('BigQuery job did not complete after 10s poll: ' + sql.slice(0, 120));
  const fields = (res.schema && res.schema.fields) ? res.schema.fields.map(f => f.name) : [];
  const rows = res.rows || [];
  let pageToken = res.pageToken;
  while (pageToken) {
    const page = BigQuery.Jobs.getQueryResults(PROJECT_ID, res.jobReference.jobId,
      { pageToken: pageToken, maxResults: 10000 });
    rows.push.apply(rows, page.rows || []);
    pageToken = page.pageToken;
  }
  return rows.map(r => {
    const o = {};
    r.f.forEach((cell, i) => { o[fields[i]] = cell.v; });
    return o;
  });
}

// KEEP IN SYNC MANUALLY with getUserTzAlerts_() in ops/monitoring/alert_emailer.gs -- byte-for-byte
// identical on purpose, same reasons as the bq_/bqAlerts_ pair above (each caches into its own
// differently-named module-level variable, _tzCache here vs _alertTzCache there, so the two caches
// never collide despite sharing one Apps Script project's scope). Also covered by
// ops/weekly_report/test_pure_helpers.js's parity test (2026-09-02 audit finding).
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
function signPct_(p){ const s = Math.abs(p).toFixed(2); return (p >= 0 || s === '0.00' ? '+' : '−') + s + '%'; } // unicode minus; force '+' when the rounded magnitude is 0.00 (else a tiny loss prints "−0.00%")
// Renders a return FRACTION as a signed %, or 'n/a' when null. A DEPLOYED strategy can still have a
// null latest return (returnPct is set null when the latest deployed_unit_value is missing — a
// partial/failed D2 engine run, line ~210); signPct_(null*100) would otherwise print a confident,
// misleading "+0.00%" (2026-07-17 audit). Mirrors the `!= null` guard the VOO fragment already uses
// and the table's "Not enough data" cell — so subject / alt-text / plain-text never fabricate a 0.00%.
function fmtRetPct_(p){ return p == null ? 'n/a' : signPct_(p * 100); }
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

// ===== chart: cumulative total return %, each strategy + VOO, both natural (non-rebased) lines =====
function downsampleDates_(sortedDates) {
  if (sortedDates.length <= 130) return sortedDates;
  const kept = [];
  for (let i = 6; i < sortedDates.length; i += 7) kept.push(sortedDates[i]);
  const last = sortedDates[sortedDates.length - 1];
  if (kept[kept.length - 1] !== last) kept.push(last);
  return kept;
}

// Rounds x UP to the nearest "nice" number — 1, 2, 2.5, or 5 × a power of 10 — so an auto-derived
// y-axis gridline step reads cleanly (e.g. 2%, not 1.8333%). Non-positive input floors to 1.
function niceNum_(x) {
  if (!(x > 0)) return 1;
  const pow = Math.pow(10, Math.floor(Math.log(x) / Math.LN10));
  const f = x / pow;                                    // normalized to [1, 10)
  const nice = f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10;
  return nice * pow;
}

// Computes a tight, clean y-axis {min, max, step, gridlines} for the returns chart. Goals: (a) always
// include the 0 breakeven line so above/below-water stays readable; (b) fit closely to the data so the
// lines fill the plot instead of being squished into a thin band by the auto-range; (c) snap the bounds
// to a nice round step (targeting ~8 intervals) so labels and gridlines are legible. `values` is the
// list of ALL plotted points across every series (already ×100, in %); nulls/NaNs (line gaps) are
// ignored. Pure — mirrored in test_pure_helpers.js.
function niceYRange_(values) {
  const nums = (values || []).filter(v => v != null && isFinite(v));
  if (!nums.length) return { min: -1, max: 1, step: 1, gridlines: 3 };
  let lo = Math.min(0, Math.min.apply(null, nums));
  let hi = Math.max(0, Math.max.apply(null, nums));
  if (lo === hi) { lo -= 1; hi += 1; }                  // wholly-flat series guard (never a zero span)
  const step = niceNum_((hi - lo) / 8);
  lo = Math.floor(lo / step) * step;
  hi = Math.ceil(hi / step) * step;
  return { min: lo, max: hi, step: step, gridlines: Math.round((hi - lo) / step) + 1 };
}

function altTextFor_(d) {
  const parts = d.rows.filter(r => r.deployed).map(r => `${r.strategy} ${fmtRetPct_(r.returnPct)}`);
  if (d.voo && d.voo.returnPct != null) {
    parts.push(`VOO ${signPct_(d.voo.returnPct * 100)}`);
  }
  return 'Cumulative return: ' + parts.join(', ');
}

// Returns {blob} or null (caller falls back to HTML bars). Never throws out.
function buildReturnChart_(d) {
  try {
    if (!d.deployedStrategies.length) return null;
    // A VOO backfill gap must not make the strategy chart disappear. Use the
    // union so strategy-only dates remain visible, with VOO represented as a
    // deliberate gap until it has a mark.
    const dateSet = new Set(Object.keys(d.vooByDate));
    d.deployedStrategies.forEach(s => (d.dailyByStrategy[s] || [])
      .forEach(p => dateSet.add(p.as_of_date)));
    const allDates = [...dateSet].sort();
    const keptDates = downsampleDates_(allDates);
    const hasVoo = d.nVooMarkDays > 0;

    // Each strategy line = (deployed_unit_value − 1) × 100. Two deliberate choices:
    //  * Forward-filled over the FULL date axis first, THEN sampled at the (possibly downsampled) kept
    //    dates — so a weekly-downsampled point reflects the true last value AS OF that date, never a
    //    stale value frozen at the previous KEPT date (the pre-2026-07-17 bug: the fill only advanced on
    //    kept dates, so a mark landing between kept dates was skipped).
    //  * A GAP (null → a break in the line), never a flat 0, OUTSIDE the strategy's own data span:
    //    before its first deployed day and after its last mark. A flat-0 lead-in would read as
    //    "deployed and breakeven" for a strategy that simply wasn't live yet — the exact false-flat the
    //    VOO series was already written to avoid (2026-07-17 audit). Within [first, last], real values
    //    are forward-filled across genuinely idle days (cumulative return doesn't move while un-deployed).
    const filled = {};
    d.deployedStrategies.forEach(s => {
      const pts = d.dailyByStrategy[s] || [];
      const map = {};
      pts.forEach(p => { if (p.duv != null) map[p.as_of_date] = (p.duv - 1) * 100; });
      const firstDate = pts.length ? pts[0].as_of_date : null;
      const lastDate  = pts.length ? pts[pts.length - 1].as_of_date : null;
      let last = null;
      const full = {};
      allDates.forEach(iso => {
        if (firstDate == null || iso < firstDate || (lastDate != null && iso > lastDate)) {
          full[iso] = null; return;                     // outside this strategy's data span → gap
        }
        if (map[iso] != null) last = map[iso];
        full[iso] = last;
      });
      filled[s] = {};
      keptDates.forEach(iso => { filled[s][iso] = full[iso]; });
    });

    // VOO first (steel blue) if it has data, under the strategy lines. VOO's own series is used as-is:
    // analytics.voo_cumulative now emits NULL on ANY day it has no real mark (leading, mid, or trailing
    // ingest gap — 2026-07-17 audit), so a gap reads as a break in the line, never a false flat 0 — and
    // it's never rebased to line up with any strategy's start (VOO plots as its own natural line).
    const dt = Charts.newDataTable().addColumn(Charts.ColumnType.DATE, 'Date');
    if (hasVoo) dt.addColumn(Charts.ColumnType.NUMBER, 'VOO');
    d.deployedStrategies.forEach(s => dt.addColumn(Charts.ColumnType.NUMBER, 'Strategy ' + s));
    const yvals = [];                                    // every plotted point (%), for the y-axis fit
    keptDates.forEach(iso => {
      const row = [parseIsoDateLocal_(iso)];
      if (hasVoo) {
        const vooVal = d.vooByDate[iso];
        const v = vooVal != null ? vooVal * 100 : null;  // null -> a gap in the line, not a false 0
        row.push(v);
        if (v != null) yvals.push(v);
      }
      d.deployedStrategies.forEach(s => {
        const sv = filled[s][iso];
        row.push(sv);
        if (sv != null) yvals.push(sv);
      });
      dt.addRow(row);
    });

    // Fit the y-axis tightly to the data (0 always included) instead of the auto-range — this is what
    // stops the lines from being squished into a thin band and makes the gaps between them legible at a
    // glance. Taller canvas (600 vs the old 400) adds vertical room for the same effect.
    const yr = niceYRange_(yvals);
    const colors = (hasVoo ? [VOO_COLOR] : []).concat(d.deployedStrategies.map(s => CHART_COLORS[s] || '#8a96a3'));
    const chart = Charts.newLineChart().setDataTable(dt.build())
      .setColors(colors)
      .setDimensions(1120, 600)
      .setLegendPosition(Charts.Position.BOTTOM)
      .setPointStyle(Charts.PointStyle.NONE)
      .setBackgroundColor('#fffffe') // opaque near-white; never transparent; PNG pixels aren't inverted by Gmail
      .setYAxisTitle('Cumulative return %')
      .setRange(yr.min, yr.max);
    // Best-effort finer gridlines — the Charts service ignores unsupported options without throwing, and
    // the tight setRange + taller canvas already do the heavy lifting if this is a no-op.
    try { chart.setOption('vAxis.gridlines.count', yr.gridlines); } catch (eOpt) {}
    return { blob: chart.build().getAs('image/png').setName('cumulative_returns.png') };
  } catch (e) {
    Logger.log('chart build failed, using HTML fallback: ' + e);
    return null;
  }
}

// Gmail-safe fallback: one bar per deployed strategy (cumulative return), + a VOO bar (if VOO has
// data). Color: green if the strategy beat VOO's own return, red if not, neutral gray-blue if VOO has
// no data yet to compare against (never coerce a missing VOO return to 0 for the comparison — that
// would silently mis-color every positive-return strategy bar as "beating VOO").
function fallbackBarsHtml_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const hasVooReturn = !!(d.voo && d.voo.returnPct != null);
  const items = deployed.map(r => ({
    label: r.strategy,
    // null when the latest deployed_unit_value is missing (returnPct null) — render "no data", never a
    // false 0% bar; the beat-vs-VOO comparison is likewise only meaningful with a real return.
    val: r.returnPct != null ? r.returnPct * 100 : null,
    beat: (hasVooReturn && r.returnPct != null) ? (r.returnPct > d.voo.returnPct) : null
  }));
  if (hasVooReturn) {
    items.push({ label: 'VOO', val: d.voo.returnPct * 100, neutral: true, vooColor: true });
  }
  const maxAbs = Math.max.apply(null, items.filter(it => it.val != null).map(it => Math.abs(it.val)).concat([1.0]));
  return items.map(it => {
    if (it.val == null) {
      return `<div style="padding:4px 0;font-size:12px;color:#1f2d3d;">` +
        `<span style="display:inline-block;width:40px;font-weight:700;">${esc_(it.label)}</span>` +
        `<span style="color:#8a96a3;">no data</span></div>`;
    }
    const widthPx = Math.max(2, Math.round(Math.abs(it.val) / maxAbs * 240));
    const color = it.vooColor ? VOO_COLOR : ((it.neutral || it.beat === null) ? '#3d4a59' : (it.beat ? '#1a7f5a' : '#c0392b'));
    return `<div style="padding:4px 0;font-size:12px;color:#1f2d3d;">` +
      `<span style="display:inline-block;width:40px;font-weight:700;">${esc_(it.label)}</span>` +
      `<span style="display:inline-block;background-color:${color};width:${widthPx}px;height:12px;vertical-align:middle;"></span>` +
      `<span style="margin-left:8px;color:${color};font-weight:700;">${signPct_(it.val)}</span></div>`;
  }).join('');
}

// ===== HTML =====
function pctCellHtml_(v, colorBySign, extrapolated) {
  if (v == null) return `<span style="color:#8a96a3;font-size:11px;">Not enough data</span>`;
  // The swatch must agree with the sign glyph: signPct_ forces '+' whenever the rounded magnitude is
  // '0.00' (2026-07-17 GS-1), so a hairline negative (e.g. -0.00003) still reads '+0.00%'. clr_(v)
  // alone branches on v's raw sign and would paint that '+0.00%' loss-red — route the swatch through
  // the same rounded view signPct_ uses so the two can never disagree at this boundary.
  const roundedZero = Math.abs(v * 100).toFixed(2) === '0.00';
  const color = colorBySign ? (roundedZero ? '#1a7f5a' : clr_(v)) : '#3d4a59';
  const marker = extrapolated ? '†' : '';
  return `<span style="color:${color};font-weight:${colorBySign ? 700 : 400};">${signPct_(v * 100)}${marker}</span>`;
}

// Compact PARK section (2026-07-18, PARK_ROUTER_DESIGN.md v2 §9) — current allocation, tenure, change
// cadence, and the AI's own realized TWR vs the three counterfactuals (100% SGOV, 100% VOO, the
// record-only v1 rule-shadow). Reuses pctCellHtml_/esc_ exactly like the Average Return table above.
// Guards every field independently (never a bare "undefined"/fabricated 0%) — bigquery/91-93 may not
// be applied live yet, and neither may bigquery/220 / 212, see gatherParkData_.
function buildParkSection_(d) {
  const p = d.park || {};
  // PARK v4 (bigquery/220, live 2026-09-04): render the SPLIT, because the book is two sleeves at a
  // graded f. "Current vehicle: VOO" is the MAJORITY-sleeve label and is not the book — reporting it
  // alone is what made a real f=0→25→50 reallocation read as no change at all. Falls back to the
  // single-vehicle label when target_f_pct is absent (a pre-220 live view via gatherParkData_'s legacy
  // fallback, or genuinely no park data), which is exactly the v9 rendering.
  const graded = p.targetFPct != null && !!p.riskSleeve && !!p.defensiveSleeve;
  const allocLabel = graded
    ? `Current allocation: <b>${100 - p.targetFPct}% ${esc_(p.riskSleeve)} / ${p.targetFPct}% ${esc_(p.defensiveSleeve)}</b>`
    : `Current vehicle: <b>${p.vehicle ? esc_(p.vehicle) : 'unknown'}</b>`;
  const daysLabel = p.daysInAllocation != null ? `${p.daysInAllocation} day${p.daysInAllocation === 1 ? '' : 's'}` : 'n/a';
  const switchesLabel = p.switches30d != null ? `${p.switches30d} switch${p.switches30d === 1 ? '' : 'es'} / 30d` : 'n/a';

  const hasCf = p.ai != null || p.sgov != null || p.voo != null || p.rule != null;
  // AI-era quartet, present only once bigquery/212 is live AND a BOUND allocator call exists to anchor
  // on (212 emits ai_era_start_date NULL + four NULL columns otherwise, deliberately).
  const hasEraCf = p.aiEraStart != null &&
    (p.aiEra != null || p.sgovEra != null || p.vooEra != null || p.ruleEra != null);
  const cfRowHtml = (label, val, colorBySign) => `
      <tr>
        <td style="padding:6px 8px;color:#3d4a59;">${esc_(label)}</td>
        <td style="padding:6px 8px;text-align:right;">${pctCellHtml_(val, !!colorBySign)}</td>
      </tr>`;
  // One quartet + the anchor it was measured on, ALWAYS stated together. bigquery/212 measured the
  // sign of AI-vs-SGOV as anchor-dependent (published inception −1.17pp vs AI era +0.67pp), so an
  // unlabelled quartet is not a number the operator can act on; Claude_Task_Plan.md's W5 PARK SCORECARD
  // carries the same "state which anchor each number uses" rule.
  const cfBlock = (caption, ai, sgov, voo, rule) => `
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">${caption}</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:4px;border-collapse:collapse;font-size:12px;">
      ${cfRowHtml('AI (actual)', ai, true)}${cfRowHtml('100% SGOV', sgov, false)}${cfRowHtml('100% VOO', voo, false)}${cfRowHtml('Rule-shadow (record-only)', rule, false)}
    </table>`;
  // AI era LEADS when it exists; the inception quartet is kept (no number is removed — 212 left the
  // five original columns byte-identical) but demoted and labelled with what it inherits.
  const cfTable = hasEraCf
    ? cfBlock(`AI era — park TWR since ${esc_(p.aiEraStart)}, the allocator's own decisions only (bigquery/212).`,
              p.aiEra, p.sgovEra, p.vooEra, p.ruleEra) +
      cfBlock(`Since book inception 2026-04-17 — includes the owner's 2026-07-15 SGOV→VOO cutover, which the allocator did not decide.`,
              p.ai, p.sgov, p.voo, p.rule)
    : (hasCf
        ? cfBlock('Park TWR since book inception 2026-04-17.', p.ai, p.sgov, p.voo, p.rule)
        : `<div style="margin-top:8px;font-size:11px;color:#8a96a3;">Not enough data yet.</div>`);

  return `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Park (AI Allocator)</div>
    <div style="margin-top:6px;font-size:12px;color:#1f2d3d;">${allocLabel} · ${daysLabel} · ${switchesLabel}</div>
    ${cfTable}
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">Counterfactuals per PARK_ROUTER_DESIGN.md — SGOV never-left, VOO the prior static policy, rule-shadow the record-only v1 lookup table (owner-rejected as decision-maker). Each block states its own anchor: bigquery/212 measured AI-vs-SGOV as sign-flipping between them.</div>
  </td></tr>`;
}

function buildHtml_(d, chartResult) {
  const hasVoo = d.nVooMarkDays > 0;

  const trustBlock = d.green ? '' : `
  <tr><td style="padding:14px 22px 0 22px;">
    <div style="background-color:#fdf3e3;border-left:4px solid #b9770e;border-radius:8px;padding:10px 14px;font-size:12px;color:#7a4d07;">
      ⚠ Numbers below may be stale — ${esc_(d.healthReasons.join(' · '))}
    </div>
  </td></tr>`;

  // Chart section.
  const notDeployed = d.rows.filter(r => !r.deployed).map(r => esc_(r.strategy));
  const notDeployedNote = notDeployed.length ? ` ${notDeployed.join(', ')} not deployed.` : '';
  const vooStale = hasVoo && d.vooLastMarkDate && d.asOfDate && d.vooLastMarkDate < d.asOfDate;
  const vooStaleNote = vooStale ? ` ⚠ VOO data through ${esc_(d.vooLastMarkDate)}.` : '';
  const benchmarkCaption = hasVoo ? 'VOO (steel blue) benchmark.' : 'Benchmark pending VOO backfill.';
  let chartInner;
  if (!d.deployedStrategies.length) {
    chartInner = `<div style="margin-top:8px;font-size:12px;color:#8a96a3;">Nothing deployed yet — all cash is parked.</div>`;
  } else if (chartResult) {
    chartInner = `<img src="cid:returnchart" width="560" alt="${esc_(altTextFor_(d))}" style="width:100%;max-width:560px;height:auto;display:block;margin-top:8px;">`;
  } else {
    chartInner = `<div style="margin-top:10px;">${fallbackBarsHtml_(d)}</div>`;
  }
  const chartSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Cumulative Return (%)</div>
    <div style="margin-top:8px;font-size:11px;color:#8a96a3;">Each line from its own start — a strategy from its first deployed day, VOO from its first mark. ${benchmarkCaption}${notDeployedNote}${vooStaleNote}</div>
    ${chartInner}
  </td></tr>`;

  // Table: per strategy, own average return per month / year (active/deployed days only); VOO's own row.
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

  const vooOwn = d.voo || { avgMonth: null, avgYear: null, extrapolatedYear: false };
  const vooRow = `
      <tr style="background-color:#f5f7fa;">
        <td style="padding:9px 8px;"><span style="display:inline-block;width:10px;height:10px;background-color:${VOO_COLOR};border-radius:2px;"></span></td>
        <td style="padding:9px 8px;font-weight:700;color:#3d4a59;">VOO<div style="font-size:10px;font-weight:400;color:#8a96a3;">own return</div></td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(vooOwn.avgMonth, false)}</td>
        <td style="padding:9px 8px;text-align:right;">${pctCellHtml_(vooOwn.avgYear, false, vooOwn.extrapolatedYear)}</td>
      </tr>`;

  const tableSection = `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Average Return</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;border-collapse:collapse;font-size:12px;">
      <tr style="background-color:#0f2747;color:#ffffff;">
        <td style="padding:8px;"></td>
        <td style="padding:8px;">Strategy</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;month</td>
        <td style="padding:8px;text-align:right;">avg&nbsp;/&nbsp;year</td>
      </tr>${strategyRows}${vooRow}
    </table>
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">Strategy rows: each strategy's own average return, on deployed capital, measured over active (deployed) time only. VOO row: its own average return. † = annualized from fewer than 252 deployed days — extrapolated.</div>
  </td></tr>`;

  const parkSection = buildParkSection_(d);

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
${trustBlock}${chartSection}${tableSection}${parkSection}
  <tr><td style="padding:12px 22px 22px 22px;">
    <div style="font-size:11px;color:#9aa6b2;line-height:1.5;">Total return, gross of commissions; VOO includes dividends. Times in ${esc_(d.tz)}.</div>
  </td></tr>

</table>
<div style="font-size:10px;color:#aab4bf;padding:10px;">${esc_(PROJECT_ID)} · weekly digest</div>
</td></tr></table></body></html>`;
}

// ===== plain-text mirror =====
function buildPlain_(d) {
  const fmtP = (v, ex) => (v == null ? 'Not enough data' : signPct_(v * 100) + (ex ? '†' : ''));

  let s = `Stock-Trading — ${SUBJECT_LABEL} (${d.dateLabel})\n\n`;
  s += `Data through ${d.health.last_mark_date || '—'} close.\n`;
  if (!d.green) s += `WARNING — numbers below may be stale: ${d.healthReasons.join(' | ')}\n`;
  s += '\n';

  if (!d.deployedStrategies.length) {
    s += `Nothing deployed yet — all cash is parked.\n`;
  } else {
    s += `CUMULATIVE RETURN (each line from its own start — strategy since first deployed, VOO since first mark):\n`;
    d.rows.filter(r => r.deployed).forEach(r => { s += `  ${r.strategy}  ${fmtRetPct_(r.returnPct)}\n`; });
    if (d.voo && d.voo.returnPct != null) {
      s += `  VOO  ${signPct_(d.voo.returnPct * 100)}\n`;
    }
    if (d.nVooMarkDays > 0 && d.vooLastMarkDate && d.asOfDate && d.vooLastMarkDate < d.asOfDate) {
      s += `  ⚠ VOO data through ${d.vooLastMarkDate}.\n`;
    }
  }

  s += `\nAVERAGE RETURN (per active month / year):\n`;
  d.rows.forEach(r => {
    if (!r.deployed) { s += `  ${r.strategy}  ${r.notDeployedReason}\n`; return; }
    s += `  ${r.strategy}  avg/mo ${fmtP(r.avgMonth)}  avg/yr ${fmtP(r.avgYear, r.extrapolatedYear)}\n`;
  });
  const vooOwn = d.voo || { avgMonth: null, avgYear: null, extrapolatedYear: false };
  s += `  VOO (own return)  avg/mo ${fmtP(vooOwn.avgMonth)}  avg/yr ${fmtP(vooOwn.avgYear, vooOwn.extrapolatedYear)}\n`;

  s += `\nStrategy rows are each strategy's own average return, on deployed capital, over active (deployed) time only; VOO row is its own average return. † = annualized from fewer than 252 deployed days. Total return, gross of commissions; VOO incl. dividends. Times in ${d.tz}.\n`;

  // PARK (AI Allocator) — 2026-07-18, PARK_ROUTER_DESIGN.md v2 §9. Mirrors buildParkSection_, including
  // its v10 two-sleeve label and its dual-anchor quartets: the two renderings must never disagree about
  // what the book is or which anchor a number was measured on (the plain part is what a text-only client
  // shows, so a divergence here is invisible to anyone reading the HTML).
  const p = d.park || {};
  const graded = p.targetFPct != null && !!p.riskSleeve && !!p.defensiveSleeve;
  const allocLabel = graded
    ? `allocation=${100 - p.targetFPct}% ${p.riskSleeve} / ${p.targetFPct}% ${p.defensiveSleeve}`
    : `vehicle=${p.vehicle || 'unknown'}`;
  const daysLabel = p.daysInAllocation != null ? `${p.daysInAllocation} day${p.daysInAllocation === 1 ? '' : 's'}` : 'n/a';
  const switchesLabel = p.switches30d != null ? `${p.switches30d} switch${p.switches30d === 1 ? '' : 'es'} / 30d` : 'n/a';
  s += `\nPARK (AI Allocator): ${allocLabel}  ${daysLabel}  ${switchesLabel}\n`;
  const hasEraCf = p.aiEraStart != null &&
    (p.aiEra != null || p.sgovEra != null || p.vooEra != null || p.ruleEra != null);
  if (hasEraCf) {
    s += `  AI era (since ${p.aiEraStart}, allocator decisions only):  AI ${fmtRetPct_(p.aiEra)}  SGOV ${fmtRetPct_(p.sgovEra)}  VOO ${fmtRetPct_(p.vooEra)}  rule-shadow ${fmtRetPct_(p.ruleEra)}\n`;
    s += `  Since inception (2026-04-17, includes the owner's 2026-07-15 cutover):  AI ${fmtRetPct_(p.ai)}  SGOV ${fmtRetPct_(p.sgov)}  VOO ${fmtRetPct_(p.voo)}  rule-shadow ${fmtRetPct_(p.rule)}\n`;
  } else if (p.ai != null || p.sgov != null || p.voo != null || p.rule != null) {
    s += `  Since inception (2026-04-17):  AI ${fmtRetPct_(p.ai)}  SGOV ${fmtRetPct_(p.sgov)}  VOO ${fmtRetPct_(p.voo)}  rule-shadow ${fmtRetPct_(p.rule)}\n`;
  } else {
    s += `  Not enough data yet.\n`;
  }

  return s;
}

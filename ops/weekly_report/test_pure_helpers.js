#!/usr/bin/env node
/**
 * Plain-Node tests for the pure (no Apps-Script-service) helpers in weekly_report.gs and
 * ops/monitoring/alert_emailer.gs (code-quality audit 2026-07). This repo has no JS test runner
 * configured, so this is a minimal, self-contained, `assert`-based Node script — no npm install
 * required.
 *
 * WHY COPIED, NOT require()'d: both source files' CONFIG sections call
 * `Session.getActiveUser().getEmail()` at top-level module-load time (the RECIPIENT /
 * ALERT_RECIPIENT consts), which is an Apps Script global that doesn't exist under plain Node —
 * requiring either file as-is throws a ReferenceError before any function could be exported.
 * Guarding that (or the other Apps-Script-service globals the rest of the files touch) to make
 * the whole files require()-able would mean editing config/wiring outside the pure helpers this
 * fix targets, on live operational scripts — more risk than this test-coverage fix is scoped for.
 * So instead: the function bodies below are copied VERBATIM from their source files and
 * exercised standalone.
 *
 * KEEP IN SYNC MANUALLY with ops/weekly_report/weekly_report.gs and
 * ops/monitoring/alert_emailer.gs — if you change any of these functions there, update the
 * copies below in the same commit:
 *   - notDeployedReason_   (weekly_report.gs lines 197-202)
 *   - periodAvg_           (weekly_report.gs lines 210-213)
 *   - signPct_             (weekly_report.gs line 268)
 *   - parseIsoDateLocal_   (weekly_report.gs lines 274-277)
 *   - downsampleDates_     (weekly_report.gs lines 280-287)
 *   - buildHealthReasons_  (weekly_report.gs lines 216-237)
 *   - buildSubject_        (weekly_report.gs lines 97-105)
 *   - esc_                 (weekly_report.gs line 270)
 *   - isTest_              (alert_emailer.gs line 192)
 *   - esc2_                (alert_emailer.gs line 187)
 *
 * Run: node ops/weekly_report/test_pure_helpers.js   (exits 0 iff every assertion passes)
 */
'use strict';
const assert = require('assert');

// ===== copied verbatim from weekly_report.gs ================================================

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

function signPct_(p) { return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; } // unicode minus

// 'YYYY-MM-DD' -> local-midnight Date (never new Date('YYYY-MM-DD'), which is UTC midnight and
// renders as the previous day in a US-behind-UTC display timezone).
function parseIsoDateLocal_(iso) {
  const p = String(iso).split('-').map(Number);
  return new Date(p[0], p[1] - 1, p[2]);
}

function downsampleDates_(sortedDates) {
  if (sortedDates.length <= 130) return sortedDates;
  const kept = [];
  for (let i = 6; i < sortedDates.length; i += 7) kept.push(sortedDates[i]);
  const last = sortedDates[sortedDates.length - 1];
  if (kept[kept.length - 1] !== last) kept.push(last);
  return kept;
}

function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

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

function buildSubject_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const tag = !deployed.length
    ? 'all parked'
    : deployed.map(r => `${r.strategy} ${signPct_(r.returnPct * 100)}`).join(' · ')
        + ` · SGOV ${signPct_(d.sgov.returnPct * 100)}`;
  const warn = d.green ? '' : ' · ⚠ check data';
  return `Stock-Trading · Strategies vs SGOV — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== copied verbatim from ops/monitoring/alert_emailer.gs ==================================

function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
function isTest_(a) { return a.source === 'scheduled.canary' || a.category === 'delivery_canary'; }

// ===== tests ==================================================================================

let passed = 0;
function t(name, fn) {
  fn();
  passed++;
  console.log(`ok - ${name}`);
}

// ---- notDeployedReason_ ----
t('notDeployedReason_ flags a DO-NOT-ACTIVATE router activation', () => {
  assert.strictEqual(notDeployedReason_('DO-NOT-ACTIVATE'), 'not deployed — router: do-not-activate');
});
t('notDeployedReason_ flags a HYBRID activation', () => {
  assert.strictEqual(notDeployedReason_('HYBRID'), 'not deployed — hybrid, awaiting a qualifying event');
});
t('notDeployedReason_ falls back to "awaiting first deployment" for any other activation', () => {
  assert.strictEqual(notDeployedReason_('SOME-OTHER-STATE'), 'not deployed — awaiting first deployment');
});
t('notDeployedReason_ handles null/undefined activation without throwing', () => {
  assert.strictEqual(notDeployedReason_(null), 'not deployed — awaiting first deployment');
  assert.strictEqual(notDeployedReason_(undefined), 'not deployed — awaiting first deployment');
});

// ---- periodAvg_ ----
t('periodAvg_ returns null below the minimum-deployed-history threshold', () => {
  assert.strictEqual(periodAvg_(0.05, 3, 5), null); // 3 deployed days < 5 (the week threshold)
});
t('periodAvg_ returns null when deployedDays is 0/falsy', () => {
  assert.strictEqual(periodAvg_(0.05, 0, 5), null);
});
t('periodAvg_ returns null when cum is null', () => {
  assert.strictEqual(periodAvg_(null, 10, 5), null);
});
t('periodAvg_ returns the whole-window rate when deployedDays == the period', () => {
  const got = periodAvg_(0.10, 5, 5);
  assert.ok(Math.abs(got - 0.10) < 1e-9, `expected ~0.10, got ${got}`);
});
t('periodAvg_ converts a longer deployed window into the equivalent annual rate', () => {
  // 15% cumulative over 300 deployed days, expressed as a 252-trading-day (annual) rate.
  const got = periodAvg_(0.15, 300, 252);
  const expected = Math.pow(1.15, 252 / 300) - 1;
  assert.ok(Math.abs(got - expected) < 1e-9, `expected ~${expected}, got ${got}`);
});

// ---- signPct_ ----
t('signPct_ prefixes a positive value with +', () => {
  assert.strictEqual(signPct_(1.2345), '+1.23%');
});
t('signPct_ prefixes zero with + (not the unicode minus)', () => {
  assert.strictEqual(signPct_(0), '+0.00%');
});
t('signPct_ prefixes a negative value with the unicode minus and its absolute magnitude', () => {
  assert.strictEqual(signPct_(-2.5), '−2.50%');
});

// ---- parseIsoDateLocal_ ----
t('parseIsoDateLocal_ round-trips an ISO date string as LOCAL midnight (not UTC)', () => {
  const d = parseIsoDateLocal_('2026-07-04');
  assert.strictEqual(d.getFullYear(), 2026);
  assert.strictEqual(d.getMonth(), 6); // 0-indexed -> July
  assert.strictEqual(d.getDate(), 4);
  assert.strictEqual(d.getHours(), 0);
  assert.strictEqual(d.getMinutes(), 0);
  assert.strictEqual(d.getSeconds(), 0);
});

// ---- downsampleDates_ ----
t('downsampleDates_ returns the input unchanged at/under 130 entries', () => {
  const dates = Array.from({ length: 130 }, (_, i) => `d${i}`);
  assert.deepStrictEqual(downsampleDates_(dates), dates);
});
t('downsampleDates_ downsamples above 130 entries and always keeps the last date', () => {
  const dates = Array.from({ length: 200 }, (_, i) => `d${i}`);
  const kept = downsampleDates_(dates);
  assert.ok(kept.length < dates.length, `expected fewer than ${dates.length}, got ${kept.length}`);
  assert.strictEqual(kept[kept.length - 1], dates[dates.length - 1]);
});

// ---- esc_ ----
t('esc_ escapes &, <, >, and " (quote-escaping fix)', () => {
  assert.strictEqual(esc_('<b>&"'), '&lt;b&gt;&amp;&quot;');
});
t('esc_ handles null/undefined without throwing, returning the empty string', () => {
  assert.strictEqual(esc_(null), '');
  assert.strictEqual(esc_(undefined), '');
});

// ---- buildHealthReasons_ ----
t('buildHealthReasons_ returns no reasons when marks/engine are fresh and there are no flags/alerts (green case)', () => {
  const reasons = buildHealthReasons_({}, true, true, 0, [], 0, []);
  assert.deepStrictEqual(reasons, []);
});
t('buildHealthReasons_ flags stale marks with the "D2 not run yet" message when D2 has not completed', () => {
  const health = { d2_ran_last_trading_day: 'false', last_trading_day: '2026-07-08' };
  const reasons = buildHealthReasons_(health, false, true, 0, [], 0, []);
  assert.strictEqual(reasons.length, 1);
  assert.ok(reasons[0].includes("today's evening data batch (D2) hasn't completed yet for 2026-07-08"),
    `unexpected message: ${reasons[0]}`);
});
t('buildHealthReasons_ flags stale marks/engine with the "D2 ran but still stale" message when D2 already completed', () => {
  const health = { d2_ran_last_trading_day: 'true', last_trading_day: '2026-07-08' };
  const reasons = buildHealthReasons_(health, true, false, 0, [], 0, []);
  assert.strictEqual(reasons.length, 1);
  assert.ok(reasons[0].includes('marks/engine still stale even though D2 logged complete for 2026-07-08'),
    `unexpected message: ${reasons[0]}`);
});
t('buildHealthReasons_ lists firing kill-flags with strategy + the specific flag names', () => {
  const killFlagDetails = [{ strategy: 'B', drawdown_kill: 'true', runaway_review: 'false', m2m_underperf_review: 'true' }];
  const reasons = buildHealthReasons_({}, true, true, 1, killFlagDetails, 0, []);
  assert.strictEqual(reasons.length, 1);
  assert.strictEqual(reasons[0], '1 firing kill-flag(s): B (drawdown_kill, m2m_underperf_review)');
});
t('buildHealthReasons_ lists open critical alerts by category/message', () => {
  const criticalAlerts = [{ category: 'cash', message: 'tripwire breached' }];
  const reasons = buildHealthReasons_({}, true, true, 0, [], 1, criticalAlerts);
  assert.strictEqual(reasons.length, 1);
  assert.strictEqual(reasons[0], '1 critical alert(s): [cash] tripwire breached');
});
t('buildHealthReasons_ appends a "+N more" suffix when openCriticalAlerts exceeds the fetched sample', () => {
  const criticalAlerts = [{ category: 'cash', message: 'tripwire breached' }];
  const reasons = buildHealthReasons_({}, true, true, 0, [], 5, criticalAlerts);
  assert.strictEqual(reasons[0], '5 critical alert(s): [cash] tripwire breached (+4 more)');
});
t('buildHealthReasons_ can report all three reasons at once (stale + kill-flag + critical alert)', () => {
  const health = { d2_ran_last_trading_day: 'true', last_trading_day: '2026-07-08' };
  const killFlagDetails = [{ strategy: 'D', drawdown_kill: 'true', runaway_review: 'false', m2m_underperf_review: 'false' }];
  const criticalAlerts = [{ category: 'router', message: 'dual-path disagreement' }];
  const reasons = buildHealthReasons_(health, false, false, 1, killFlagDetails, 1, criticalAlerts);
  assert.strictEqual(reasons.length, 3);
});

// ---- buildSubject_ ----
t('buildSubject_ shows "all parked" when nothing is deployed', () => {
  const d = { rows: [{ strategy: 'A', deployed: false }, { strategy: 'B', deployed: false }],
    sgov: { returnPct: 0.01 }, green: true, dateLabel: 'Jul 6, 2026' };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Strategies vs SGOV — Jul 6, 2026 · all parked');
});
t('buildSubject_ lists only deployed strategies plus SGOV when strategies are mixed parked/deployed', () => {
  const d = {
    rows: [
      { strategy: 'A', deployed: true, returnPct: 0.0123 },
      { strategy: 'B', deployed: false },
      { strategy: 'C', deployed: true, returnPct: -0.005 }
    ],
    sgov: { returnPct: 0.002 }, green: true, dateLabel: 'Jul 6, 2026'
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Strategies vs SGOV — Jul 6, 2026 · A +1.23% · C −0.50% · SGOV +0.20%');
});
t('buildSubject_ omits the warning suffix when green is true', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.01 }],
    sgov: { returnPct: 0 }, green: true, dateLabel: 'Jul 6, 2026' };
  assert.ok(!buildSubject_(d).includes('check data'));
});
t('buildSubject_ appends the "⚠ check data" warning suffix when green is false', () => {
  const d = { rows: [{ strategy: 'A', deployed: false }], sgov: { returnPct: 0 }, green: false, dateLabel: 'Jul 6, 2026' };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Strategies vs SGOV — Jul 6, 2026 · all parked · ⚠ check data');
});

// ---- isTest_ (alert_emailer.gs) ----
t('isTest_ returns true for the canary source', () => {
  assert.strictEqual(isTest_({ source: 'scheduled.canary', category: 'other' }), true);
});
t('isTest_ returns true for the delivery_canary category', () => {
  assert.strictEqual(isTest_({ source: 'other', category: 'delivery_canary' }), true);
});
t('isTest_ returns false for a real (non-canary) alert', () => {
  assert.strictEqual(isTest_({ source: 'router', category: 'cash_tripwire' }), false);
});

// ---- esc2_ (alert_emailer.gs) ----
t('esc2_ escapes &, <, >, and " (quote-escaping fix)', () => {
  assert.strictEqual(esc2_('<b>&"'), '&lt;b&gt;&amp;&quot;');
});
t('esc2_ handles null/undefined without throwing, returning the empty string', () => {
  assert.strictEqual(esc2_(null), '');
  assert.strictEqual(esc2_(undefined), '');
});

console.log(`\n${passed} assertions passed.`);
process.exit(0);

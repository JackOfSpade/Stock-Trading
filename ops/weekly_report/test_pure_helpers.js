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
 *   - notDeployedReason_   (weekly_report.gs lines 256-262)
 *   - periodAvg_           (weekly_report.gs lines 273-276)
 *   - isExtrapolated_      (weekly_report.gs lines 281-283)
 *   - benchmarkRow_        (weekly_report.gs lines 289-296)
 *   - signPct_             (weekly_report.gs line 351)
 *   - signDollar_          (weekly_report.gs line 352)
 *   - fmtAbsDollars_       (weekly_report.gs line 353)
 *   - edgeWord_            (weekly_report.gs line 354)
 *   - parseIsoDateLocal_   (weekly_report.gs lines 365-368)
 *   - downsampleDates_     (weekly_report.gs lines 371-378)
 *   - buildHealthReasons_  (weekly_report.gs lines 299-320)
 *   - buildSubject_        (weekly_report.gs lines 119-135)
 *   - esc_                 (weekly_report.gs line 361)
 *   - isTest_              (alert_emailer.gs line 210)
 *   - esc2_                (alert_emailer.gs line 205)
 *   - alertSubject_        (alert_emailer.gs, defined immediately after isTest_)
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

function signPct_(p){ return (p >= 0 ? '+' : '−') + Math.abs(p).toFixed(2) + '%'; } // unicode minus
function signDollar_(v) { return (v >= 0 ? '+$' : '−$') + Math.abs(v).toFixed(2); } // unicode minus
function fmtAbsDollars_(v) { return '$' + Math.abs(v).toFixed(2); }
function edgeWord_(v) { return v >= 0 ? 'beat' : 'trailed'; }

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
  return `Stock-Trading · Deployed vs Benchmarks — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== copied verbatim from ops/monitoring/alert_emailer.gs ==================================

function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
function isTest_(a) { return a.source === 'scheduled.canary' || a.category === 'delivery_canary'; }

// Email subject for one poll batch. `fresh` = alerts newly notified this poll (real incidents +
// any canary); `combined` = fresh plus non-duplicate recurring termination_close_staged re-sends
// (see the call site). "new" must count only genuinely-new alerts (from `fresh`), NOT the recurring
// re-sends that also ride in `combined` — otherwise the subject over-reports new incidents (e.g.
// "3 new" when 2 are new + 1 is a recurring re-notify) and mis-attributes the recurring critical to
// the "(N critical)" new-count.
function alertSubject_(fresh, combined) {
  const newReal = fresh.filter(r => !isTest_(r));         // genuinely new, non-test alerts this poll
  const testCount = fresh.length - newReal.length;         // test canaries among the new alerts
  const recurringCount = combined.length - fresh.length;   // termination_close_staged re-sends this poll
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
t('notDeployedReason_ flags an execution-feasibility-deferred activation', () => {
  assert.strictEqual(
    notDeployedReason_('ACTIVATE (substantive) + execution-feasibility-deferred'),
    'not deployed — execution-feasibility-deferred (book too small for single-share legs; needs ~$250k total book vs current ~$1.9k)'
  );
});
t('notDeployedReason_ falls back to "awaiting first deployment" for any other activation', () => {
  assert.strictEqual(notDeployedReason_('SOME-OTHER-STATE'), 'not deployed — awaiting first deployment');
});
t('notDeployedReason_ handles null/undefined activation without throwing', () => {
  assert.strictEqual(notDeployedReason_(null), 'not deployed — awaiting first deployment');
  assert.strictEqual(notDeployedReason_(undefined), 'not deployed — awaiting first deployment');
});

// ---- periodAvg_ ----
t('periodAvg_ returns null when deployedDays is below the 21-day minimum, even if it equals the period', () => {
  assert.strictEqual(periodAvg_(0.10, 5, 5), null); // 5 < the 21-day floor -- not enough history to state ANY average, even a 5-day one
});
t('periodAvg_ returns null when deployedDays is 0/falsy', () => {
  assert.strictEqual(periodAvg_(0.05, 0, 5), null);
});
t('periodAvg_ returns null when cum is null', () => {
  assert.strictEqual(periodAvg_(null, 10, 5), null);
});
t('periodAvg_ enforces the 21-deployed-day floor regardless of the requested period', () => {
  assert.strictEqual(periodAvg_(0.05, 20, 252), null);
  assert.ok(periodAvg_(0.05, 21, 252) !== null);
});
t('periodAvg_ returns the whole-window rate once deployedDays meets both the period and the 21-day floor', () => {
  const got = periodAvg_(0.10, 21, 21);
  assert.ok(Math.abs(got - 0.10) < 1e-9, `expected ~0.10, got ${got}`);
});
t('periodAvg_ converts a longer deployed window into the equivalent annual rate', () => {
  // 15% cumulative over 300 deployed days, expressed as a 252-trading-day (annual) rate.
  const got = periodAvg_(0.15, 300, 252);
  const expected = Math.pow(1.15, 252 / 300) - 1;
  assert.ok(Math.abs(got - expected) < 1e-9, `expected ~${expected}, got ${got}`);
});

// ---- isExtrapolated_ ----
t('isExtrapolated_ is false with zero deployed days', () => {
  assert.strictEqual(isExtrapolated_(0, 252), false);
});
t('isExtrapolated_ is true with some but fewer than a full period of deployed days', () => {
  assert.strictEqual(isExtrapolated_(52, 252), true);
});
t('isExtrapolated_ is false once deployed days meet or exceed the period', () => {
  assert.strictEqual(isExtrapolated_(252, 252), false);
  assert.strictEqual(isExtrapolated_(300, 252), false);
});

// ---- benchmarkRow_ ----
t('benchmarkRow_ returns null avg/month and avg/year below the 21-day floor, but keeps returnPct', () => {
  const r = benchmarkRow_(0.05, 10);
  assert.strictEqual(r.returnPct, 0.05);
  assert.strictEqual(r.avgMonth, null);
  assert.strictEqual(r.avgYear, null);
  assert.strictEqual(r.extrapolatedYear, true);
});
t('benchmarkRow_ computes avg/month and avg/year once the 21-day floor is met, flagging avg/year extrapolated', () => {
  // Live-verified 2026-07-13: deployed book cum +7.3734277% over N=52 deployed days.
  const r = benchmarkRow_(0.073734277, 52);
  assert.ok(Math.abs(r.avgMonth - (Math.pow(1.073734277, 21 / 52) - 1)) < 1e-9);
  assert.ok(Math.abs(r.avgYear - (Math.pow(1.073734277, 252 / 52) - 1)) < 1e-9);
  assert.strictEqual(r.extrapolatedYear, true);
});
t('benchmarkRow_ marks avg/year not extrapolated once 252+ deployed days exist', () => {
  const r = benchmarkRow_(0.15, 300);
  assert.strictEqual(r.extrapolatedYear, false);
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

// ---- signDollar_ ----
t('signDollar_ prefixes a positive value with +$', () => {
  assert.strictEqual(signDollar_(16.09), '+$16.09');
});
t('signDollar_ prefixes zero with +$ (not the unicode minus)', () => {
  assert.strictEqual(signDollar_(0), '+$0.00');
});
t('signDollar_ prefixes a negative value with the unicode minus and its absolute magnitude', () => {
  assert.strictEqual(signDollar_(-4.5), '−$4.50');
});

// ---- fmtAbsDollars_ ----
t('fmtAbsDollars_ always renders an unsigned magnitude, positive input', () => {
  assert.strictEqual(fmtAbsDollars_(14.76), '$14.76');
});
t('fmtAbsDollars_ always renders an unsigned magnitude, negative input', () => {
  assert.strictEqual(fmtAbsDollars_(-14.76), '$14.76');
});

// ---- edgeWord_ ----
t('edgeWord_ returns "beat" for a positive edge', () => {
  assert.strictEqual(edgeWord_(8.28), 'beat');
});
t('edgeWord_ returns "beat" at the zero boundary (matching signPct_/signDollar_\'s zero-is-positive convention)', () => {
  assert.strictEqual(edgeWord_(0), 'beat');
});
t('edgeWord_ returns "trailed" for a negative edge', () => {
  assert.strictEqual(edgeWord_(-3.2), 'trailed');
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
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked');
});
t('buildSubject_ lists only deployed strategies plus SGOV when strategies are mixed parked/deployed, no headline', () => {
  const d = {
    rows: [
      { strategy: 'A', deployed: true, returnPct: 0.0123 },
      { strategy: 'B', deployed: false },
      { strategy: 'C', deployed: true, returnPct: -0.005 }
    ],
    sgov: { returnPct: 0.002 }, green: true, dateLabel: 'Jul 6, 2026'
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23% · C −0.50% · SGOV +0.20%');
});
t('buildSubject_ appends the VOO fragment after SGOV when headline.voo has a return', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: true, returnPct: 0.0123 }],
    sgov: { returnPct: 0.002 }, green: true, dateLabel: 'Jul 6, 2026',
    headline: { voo: { returnPct: 0.015 } }
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23% · SGOV +0.20% · VOO +1.50%');
});
t('buildSubject_ omits the VOO fragment when headline.voo.returnPct is null (VOO not backfilled yet)', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: true, returnPct: 0.0123 }],
    sgov: { returnPct: 0.002 }, green: true, dateLabel: 'Jul 6, 2026',
    headline: { voo: { returnPct: null } }
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23% · SGOV +0.20%');
});
t('buildSubject_ never appends the VOO fragment in the all-parked branch, even if headline.voo exists', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: false }],
    sgov: { returnPct: 0.002 }, green: true, dateLabel: 'Jul 6, 2026',
    headline: { voo: { returnPct: 0.015 } }
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked');
});
t('buildSubject_ omits the warning suffix when green is true', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.01 }],
    sgov: { returnPct: 0 }, green: true, dateLabel: 'Jul 6, 2026' };
  assert.ok(!buildSubject_(d).includes('check data'));
});
t('buildSubject_ appends the "⚠ check data" warning suffix when green is false', () => {
  const d = { rows: [{ strategy: 'A', deployed: false }], sgov: { returnPct: 0 }, green: false, dateLabel: 'Jul 6, 2026' };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked · ⚠ check data');
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

// ---- alertSubject_ (alert_emailer.gs) ----
t('alertSubject_: canary-only batch (no new real, no recurring) -> the [TEST] subject', () => {
  const fresh = [{ source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning' }];
  assert.strictEqual(alertSubject_(fresh, fresh), '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed');
});
t('alertSubject_: N new real alerts + 1 recurring termination-close -> "N new", not "N+1"', () => {
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'router', category: 'stale_data', severity: 'warning' },
  ];
  const recurring = [{ source: 'router', category: 'termination_close_staged', severity: 'warning' }];
  const combined = fresh.concat(recurring);
  assert.strictEqual(
    alertSubject_(fresh, combined),
    '⚠ Stock-Trading ALERT — 2 new (1 critical) — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: recurring-only batch (no new alerts this poll) -> no "new" segment', () => {
  const fresh = [];
  const recurring = [{ source: 'router', category: 'termination_close_staged', severity: 'warning' }];
  const combined = fresh.concat(recurring);
  assert.strictEqual(
    alertSubject_(fresh, combined),
    '⚠ Stock-Trading ALERT — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: a critical alert riding ONLY in the recurring set must not inflate "(N critical)"', () => {
  const fresh = [{ source: 'router', category: 'stale_data', severity: 'warning' }];
  const recurring = [{ source: 'router', category: 'termination_close_staged', severity: 'critical' }];
  const combined = fresh.concat(recurring);
  assert.strictEqual(
    alertSubject_(fresh, combined),
    '⚠ Stock-Trading ALERT — 1 new — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: a test canary alongside a real new alert -> "(+1 test)" suffix, real alert not softened', () => {
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning' },
  ];
  assert.strictEqual(
    alertSubject_(fresh, fresh),
    '⚠ Stock-Trading ALERT — 1 new (1 critical) (+1 test)'
  );
});

console.log(`\n${passed} assertions passed.`);
process.exit(0);

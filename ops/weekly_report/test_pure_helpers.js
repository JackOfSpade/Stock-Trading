#!/usr/bin/env node
/**
 * Offline regression tests for the actual weekly report and alert emailer sources.
 * Both .gs files run in one Apps Script global scope. Loading them together also
 * catches duplicate top-level declarations. Cloud and email services are stubbed;
 * unmocked queries fail, so no test can reach production.
 *
 * Run: node ops/weekly_report/test_pure_helpers.js
 */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const context = vm.createContext({
  require, __dirname, console, process,
  Session: { getActiveUser: () => ({ getEmail: () => 'offline@example.test' }) },
  ScriptApp: { WeekDay: { SUNDAY: 'SUNDAY' } },
  Logger: { log: () => {} },
  Utilities: { sleep: () => {}, formatDate: () => { throw new Error('Stub formatDate for this test'); } },
  BigQuery: { Jobs: {
    query: () => { throw new Error('Unstubbed BigQuery query'); },
    getQueryResults: () => { throw new Error('Unstubbed BigQuery results'); },
  } },
});
vm.runInContext('globalThis.global = globalThis;', context);
for (const filename of ['weekly_report.gs', '../monitoring/alert_emailer.gs']) {
  const absolutePath = path.resolve(__dirname, filename);
  vm.runInContext(fs.readFileSync(absolutePath, 'utf8'), context, { filename: absolutePath });
}
vm.runInContext(`(${runTests.toString()})();`, context, { filename: __filename });

function runTests() {
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

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

// ---- num_ (2026-07-29: zero-coverage BigQuery-value coercion; BigQuery Jobs.query returns every cell
//      as a STRING regardless of the column's declared type, and a SQL NULL comes back as JS null, not
//      a "null" string -- a wrong guard here silently propagates into every downstream %, kill-flag
//      count, and "n/a"/"Not enough data" branch this file computes) ----
t('num_ returns null (not NaN/0) for a real SQL NULL (JS null) and for undefined', () => {
  assert.strictEqual(num_(null), null);
  assert.strictEqual(num_(undefined), null);
});
t('num_ returns null for the empty string BigQuery can return for a NULL cell in some paths', () => {
  assert.strictEqual(num_(''), null);
});
t('num_ preserves zero -- a common false-negative bug is treating 0 as "missing" like null', () => {
  assert.strictEqual(num_(0), 0);
  assert.strictEqual(num_('0'), 0);
  assert.notStrictEqual(num_('0'), null, 'the string "0" must coerce to the number 0, not null');
});
t('num_ preserves negative values, including from a string cell', () => {
  assert.strictEqual(num_(-3.5), -3.5);
  assert.strictEqual(num_('-3.5'), -3.5);
});
t('num_ coerces a non-numeric string to NaN (JS Number() semantics) -- documents the propagation risk', () => {
  // BigQuery numeric/boolean columns should never actually emit a non-numeric string, so this is a
  // defensive/documentation case, not a fix: num_ is a thin Number() coercion, and NaN's own
  // falsiness is what keeps existing `num_(x) || 0` call sites (gatherData_'s firingKillFlags /
  // openCriticalAlerts) safe against it -- a call site that does NOT OR-default to 0, like
  // returnPct's `lastDuv - 1`, would still propagate a silent NaN. Pin the actual behavior here.
  assert.ok(Number.isNaN(num_('not-a-number')));
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
t('signPct_ shows +0.00% (not −0.00%) for a tiny loss that rounds to zero', () => {
  // 2026-07-17 audit GS-1: the sign came from raw p while the magnitude rounded via toFixed(2), so
  // any p in (-0.005, 0) printed the contradictory "−0.00%". Now the sign is '+' when the FORMATTED
  // magnitude is 0.00. Boundary preserved: -0.005 still rounds to a real "−0.01%".
  assert.strictEqual(signPct_(-0.004), '+0.00%');
  assert.strictEqual(signPct_(-0.001), '+0.00%');
  assert.strictEqual(signPct_(-0.005), '−0.01%');
});

// ---- fmtRetPct_ ----
t('fmtRetPct_ renders a real fraction as a signed % (same as signPct_(p*100))', () => {
  assert.strictEqual(fmtRetPct_(0.0123), '+1.23%');
  assert.strictEqual(fmtRetPct_(-0.05), '−5.00%');
  assert.strictEqual(fmtRetPct_(0), '+0.00%');
});
t('fmtRetPct_ renders null as "n/a" (not a misleading "+0.00%") — the 2026-07-17 null-return guard', () => {
  // A deployed strategy can have returnPct === null (missing latest deployed_unit_value); the old
  // unguarded signPct_(null*100) printed "+0.00%", fabricating a flat return. Must be 'n/a' now.
  assert.strictEqual(fmtRetPct_(null), 'n/a');
  assert.strictEqual(fmtRetPct_(undefined), 'n/a');
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

// ---- niceNum_ / niceYRange_ (chart y-axis fit) ----
t('niceNum_ rounds UP to a 1/2/2.5/5 × 10^k step', () => {
  assert.strictEqual(niceNum_(2.67), 5);
  assert.strictEqual(niceNum_(2), 2);
  assert.strictEqual(niceNum_(2.1), 2.5);
  assert.strictEqual(niceNum_(0.8), 1);
  assert.strictEqual(niceNum_(12.5), 20);
  assert.strictEqual(niceNum_(0.03), 0.05);
});
t('niceNum_ floors non-positive input to 1 (never a zero/negative step)', () => {
  assert.strictEqual(niceNum_(0), 1);
  assert.strictEqual(niceNum_(-5), 1);
});
t('niceYRange_ always brackets 0 and fits tightly around the data', () => {
  const r = niceYRange_([-5, 11, 2, -4]); // e.g. Strategy D low, Strategy B high
  assert.ok(r.min <= -5 && r.min <= 0, `min ${r.min} should be <= data min and <= 0`);
  assert.ok(r.max >= 11 && r.max >= 0, `max ${r.max} should be >= data max and >= 0`);
  // tighter than the old fixed -10..15 auto band
  assert.ok(r.min > -10 && r.max <= 15, `expected a tight band, got [${r.min}, ${r.max}]`);
  assert.ok(r.gridlines >= 3, 'should propose at least a few gridlines');
});
t('niceYRange_ includes 0 even when every value is positive (breakeven stays visible)', () => {
  const r = niceYRange_([3, 5, 8]);
  assert.strictEqual(r.min, 0);
  assert.ok(r.max >= 8);
});
t('niceYRange_ includes 0 even when every value is negative', () => {
  const r = niceYRange_([-3, -5, -8]);
  assert.strictEqual(r.max, 0);
  assert.ok(r.min <= -8);
});
t('niceYRange_ ignores nulls/NaN (line gaps) and guards an all-equal / empty series', () => {
  const r = niceYRange_([null, 4, NaN, 4]); // effectively a flat 4
  assert.ok(r.min <= 0 && r.max >= 4 && r.max > r.min, `bad flat-series range [${r.min}, ${r.max}]`);
  const empty = niceYRange_([]);
  assert.ok(empty.min < empty.max, 'empty series must still yield a non-zero span');
  const allNull = niceYRange_([null, undefined, NaN]);
  assert.ok(allNull.min < allNull.max, 'all-null series must still yield a non-zero span');
});
t('niceYRange_ snaps bounds to whole multiples of its step', () => {
  const r = niceYRange_([-5, 11]);
  assert.ok(Math.abs(r.min / r.step - Math.round(r.min / r.step)) < 1e-9, 'min not on a step boundary');
  assert.ok(Math.abs(r.max / r.step - Math.round(r.max / r.step)) < 1e-9, 'max not on a step boundary');
});

// ---- altTextFor_ (2026-07-29: zero-coverage -- the chart's <img alt> text, which is what a
//      screen-reader / images-off inbox shows in place of the chart, so a silent break here is
//      invisible to anyone viewing images normally) ----
t('altTextFor_ lists only deployed strategies with their formatted return', () => {
  const d = { rows: [
    { strategy: 'A', deployed: true, returnPct: 0.0123 },
    { strategy: 'B', deployed: false, returnPct: null },
  ], voo: { returnPct: null } };
  assert.strictEqual(altTextFor_(d), 'Cumulative return: A +1.23%');
});
t('altTextFor_ renders a deployed strategy with a null return as "n/a", not a false "+0.00%"', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: null }], voo: { returnPct: null } };
  assert.strictEqual(altTextFor_(d), 'Cumulative return: A n/a');
});
t('altTextFor_ appends VOO only when d.voo.returnPct is non-null', () => {
  const base = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.01 }] };
  assert.strictEqual(altTextFor_({ ...base, voo: { returnPct: 0.02 } }), 'Cumulative return: A +1.00%, VOO +2.00%');
  assert.strictEqual(altTextFor_({ ...base, voo: { returnPct: null } }), 'Cumulative return: A +1.00%');
  assert.strictEqual(altTextFor_({ ...base, voo: null }), 'Cumulative return: A +1.00%');
});
t('altTextFor_ degrades to the bare prefix when nothing is deployed and VOO has no data', () => {
  const d = { rows: [{ strategy: 'A', deployed: false, returnPct: null }], voo: { returnPct: null } };
  assert.strictEqual(altTextFor_(d), 'Cumulative return: ');
});

// ---- esc_ ----
t('esc_ escapes &, <, >, and " (quote-escaping fix)', () => {
  assert.strictEqual(esc_('<b>&"'), '&lt;b&gt;&amp;&quot;');
});
t('esc_ handles null/undefined without throwing, returning the empty string', () => {
  assert.strictEqual(esc_(null), '');
  assert.strictEqual(esc_(undefined), '');
});

// ---- clr_ (2026-07-29: previously only exercised indirectly through pctCellHtml_'s rounded-zero
//      routing, never pinned directly against its own raw-sign contract) ----
t('clr_ maps a non-negative value to the gain color, a negative value to the loss color', () => {
  assert.strictEqual(clr_(5), '#1a7f5a');
  assert.strictEqual(clr_(0), '#1a7f5a');
  assert.strictEqual(clr_(-0.0001), '#c0392b');
});

// ---- pctCellHtml_ / fallbackBarsHtml_ (the "chart must never fail the send" safety fallback and
//      its cell-renderer sibling — previously zero test coverage) ----
t('pctCellHtml_ returns "Not enough data" for null', () => {
  assert.ok(pctCellHtml_(null, true, false).includes('Not enough data'));
});
t('pctCellHtml_ colors by sign when colorBySign=true, neutral color when false', () => {
  const positive = pctCellHtml_(0.05, true, false);
  const negative = pctCellHtml_(-0.05, true, false);
  assert.ok(positive.includes('#1a7f5a'));
  assert.ok(negative.includes('#c0392b'));
  const neutral = pctCellHtml_(0.05, false, false);
  assert.ok(neutral.includes('#3d4a59'));
});
t('pctCellHtml_ swatch matches the sign glyph at the rounded-zero boundary (C25)', () => {
  // 2026-07-20 audit C25: the swatch used to branch on v's RAW sign (clr_(v)) while the text came
  // from signPct_(v*100), which forces '+' once the FORMATTED magnitude rounds to '0.00' (GS-1). A
  // hairline loss like -0.0000004 hit that gap: text read '+0.00%' but the swatch still painted
  // loss-red. Pin the boundary both ways — rounded-zero must be gain-green, and a real (non-rounding)
  // loss must still be loss-red.
  const hairlineLoss = pctCellHtml_(-0.0000004, true, false);
  assert.ok(hairlineLoss.includes('#1a7f5a'), 'rounded-zero cell must use the gain color');
  assert.ok(!hairlineLoss.includes('#c0392b'), 'rounded-zero cell must not use loss-red');
  assert.ok(hairlineLoss.includes('+0.00%'), 'rounded-zero cell text must still read +0.00%');
  const realLoss = pctCellHtml_(-0.05, true, false);
  assert.ok(realLoss.includes('#c0392b'), 'a real (non-rounding) loss must still render loss-red');
});
t('pctCellHtml_ appends the † marker when extrapolated=true', () => {
  assert.ok(pctCellHtml_(0.05, true, true).includes('†'));
  assert.ok(!pctCellHtml_(0.05, true, false).includes('†'));
});
t('fallbackBarsHtml_ colors a beating deployed strategy green and a trailing one red, both vs VOO', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.10 }, { strategy: 'B', deployed: true, returnPct: -0.02 }],
              voo: { returnPct: 0.01 } };
  const out = fallbackBarsHtml_(d);
  assert.ok(out.includes('#1a7f5a')); // A beat VOO (0.10 > 0.01)
  assert.ok(out.includes('#c0392b')); // B trailed VOO (-0.02 < 0.01)
});
t('fallbackBarsHtml_ never includes an SGOV bar (dropped in the 2026-07-15 redesign)', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.10 }], voo: { returnPct: 0.01 } };
  assert.ok(!fallbackBarsHtml_(d).includes('SGOV'));
});
t('fallbackBarsHtml_ includes a VOO bar colored VOO_COLOR only when d.voo.returnPct is non-null', () => {
  const base = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.10 }] };
  const withVoo = fallbackBarsHtml_({ ...base, voo: { returnPct: 0.03 } });
  const withoutVoo = fallbackBarsHtml_({ ...base, voo: { returnPct: null } });
  assert.ok(withVoo.includes(VOO_COLOR));
  assert.ok(!withoutVoo.includes(VOO_COLOR));
});
t('fallbackBarsHtml_ colors a strategy bar neutral (not red) when VOO has no data to compare against', () => {
  // Correctness guard: an unguarded `returnPct > undefined` would coerce to `> NaN` (false) in some
  // engines or silently misbehave; the guarded `beat: null` path must render the neutral color, not red.
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.10 }], voo: { returnPct: null } };
  const out = fallbackBarsHtml_(d);
  assert.ok(!out.includes('#c0392b'));
  assert.ok(out.includes('#3d4a59'));
});
t('fallbackBarsHtml_ respects the Math.max(2, ...) bar-width floor for a near-zero value', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.0001 }], voo: { returnPct: 0.10 } };
  const out = fallbackBarsHtml_(d);
  // Assert the floor directly: A's near-zero |val| (0.01, vs VOO 10 -> widthPx = max(2, round(0.24)) = 2)
  // must render at the 2px floor. The old `|| /width:\d+px/` disjunct made this vacuous — it matched the
  // VOO bar (width:240px) and even the 40px label spans, so a regression to width:0px on A would still pass.
  assert.ok(out.includes('width:2px'), 'strategy A near-zero bar must render at the Math.max(2,...) floor');
});
t('fallbackBarsHtml_ renders "no data" (not a false 0% bar) for a deployed strategy with null returnPct', () => {
  // 2026-07-17 null-return guard: an unguarded null*100 drew a confident 0.00% bar; must be "no data".
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: null }, { strategy: 'B', deployed: true, returnPct: 0.05 }],
              voo: { returnPct: 0.01 } };
  const out = fallbackBarsHtml_(d);
  assert.ok(out.includes('no data'), 'expected a "no data" row for the null-return strategy');
  assert.ok(!/A<\/span><span[^>]*background-color/.test(out), 'null-return strategy must not get a colored bar');
  assert.ok(out.includes('+5.00%'), 'the real-return strategy must still render its bar');
});

// ---- esc_ / esc2_ parity — closes the "KEEP IN SYNC MANUALLY" gap: the two blocks above only
//      prove each function is internally correct, never that the two hand-synced twins still agree ----
t('esc_ and esc2_ (the two hand-synced HTML-escape twins) agree for every input', () => {
  const cases = ['<b>&"', null, undefined, '', 'plain text', 'it\'s "quoted" <tag> & more', 0, false];
  cases.forEach(c => {
    assert.strictEqual(esc_(c), esc2_(c), `esc_/esc2_ diverged for input ${JSON.stringify(c)}`);
  });
});

// ---- bq_ / bqAlerts_ parity, and getUserTzWeekly_ / getUserTzAlerts_ parity — the SAME
//      "hand-synced twin with no sync comment and no parity test" gap the esc_/esc2_ test above closes,
//      found unguarded on the BigQuery job-poll-and-paginate helper (2026-09-02 audit finding).
//      bqAlerts_ (alert_emailer.gs) is a byte-near-identical copy of bq_ (weekly_report.gs) --
//      including the identical inline "no heartbeat -> dead-man's switch" comment word-for-word -- and
//      getUserTzAlerts_/getUserTzWeekly_ are the same pattern one layer up. Both pairs close over
//      Apps-Script-only globals (BigQuery, Utilities, Logger) that plain Node does not provide, so this
//      stubs them deterministically, covering the three response shapes that
//      matter: a normal single-page response, a paginated multi-page response, and a job that never
//      completes (must throw, not hang or render empty).
function withBqStubs_(stubs, fn) {
  const savedBQ = global.BigQuery, savedUtil = global.Utilities, savedLogger = global.Logger;
  global.BigQuery = { Jobs: { query: stubs.query, getQueryResults: stubs.getQueryResults } };
  // sleep is a no-op: a real 1s x10 sleep would make the "never completes" case slow. formatDate mimics
  // Apps Script's zone validation: it throws unless the zone is one of the few valid names these tests use.
  const validZones_ = ['America/Toronto', 'America/Denver'];
  global.Utilities = {
    sleep: () => {},
    formatDate: (date, tz, fmt) => {
      if (!validZones_.includes(tz)) throw new Error('Unknown timezone: ' + tz);
      return '2026';
    }
  };
  global.Logger = { log: () => {} };
  try {
    return fn();
  } finally {
    global.BigQuery = savedBQ; global.Utilities = savedUtil; global.Logger = savedLogger;
  }
}
function assertThrowsMessage_(fn, expectedMsg, label) {
  let threw = false;
  try { fn(); } catch (e) { threw = true; assert.strictEqual(e.message, expectedMsg, `${label}: unexpected error message`); }
  assert.ok(threw, `${label}: expected a throw and none occurred`);
}

t('bq_ and bqAlerts_ return identical rows for a normal single-page response', () => {
  const fields = [{ name: 'strategy' }, { name: 'activation' }];
  const rows = [{ f: [{ v: 'A' }, { v: 'ACTIVATE' }] }, { f: [{ v: 'B' }, { v: 'DO-NOT-ACTIVATE' }] }];
  const stubs = {
    query: (req, projectId) => {
      assert.ok([PROJECT_ID, ALERT_PROJECT_ID].includes(projectId), `unexpected projectId: ${projectId}`);
      return { jobComplete: true, schema: { fields }, rows, jobReference: { jobId: 'job-single' } };
    },
    // A single-page, already-complete job must never touch pagination/polling at all.
    getQueryResults: () => { throw new Error('getQueryResults must not be called for a single-page, already-complete job'); }
  };
  const expected = [{ strategy: 'A', activation: 'ACTIVATE' }, { strategy: 'B', activation: 'DO-NOT-ACTIVATE' }];
  withBqStubs_(stubs, () => {
    assert.deepStrictEqual(bq_('SELECT strategy, activation FROM x'), expected);
    assert.deepStrictEqual(bqAlerts_('SELECT strategy, activation FROM x'), expected);
  });
});

t('bq_ and bqAlerts_ walk pageToken identically and return the same combined rows for a paginated response', () => {
  const fields = [{ name: 'v' }];
  let getCalls;
  const stubs = {
    query: () => ({ jobComplete: true, schema: { fields }, rows: [{ f: [{ v: 'p1' }] }],
                     pageToken: 'tok-1', jobReference: { jobId: 'job-paged' } }),
    getQueryResults: (projectId, jobId, opts) => {
      getCalls++;
      assert.strictEqual(jobId, 'job-paged');
      if (getCalls === 1) {
        assert.strictEqual(opts.pageToken, 'tok-1');
        return { rows: [{ f: [{ v: 'p2' }] }], pageToken: 'tok-2' }; // a SECOND page, to prove the loop, not just one hop
      }
      assert.strictEqual(opts.pageToken, 'tok-2');
      return { rows: [{ f: [{ v: 'p3' }] }], pageToken: undefined };
    }
  };
  const expected = [{ v: 'p1' }, { v: 'p2' }, { v: 'p3' }];
  withBqStubs_(stubs, () => {
    getCalls = 0;
    assert.deepStrictEqual(bq_('SELECT v FROM x'), expected);
    getCalls = 0;
    assert.deepStrictEqual(bqAlerts_('SELECT v FROM x'), expected);
  });
});

t('bq_ and bqAlerts_ both throw the identical error, after the identical 10x1s poll guard, for a job that never completes', () => {
  let getCalls;
  const stubs = {
    query: () => ({ jobComplete: false, jobReference: { jobId: 'job-stuck' } }),
    getQueryResults: () => { getCalls++; return { jobComplete: false, jobReference: { jobId: 'job-stuck' } }; }
  };
  const sql = 'SELECT * FROM never_completes';
  const expectedMsg = 'BigQuery job did not complete after 10s poll: ' + sql.slice(0, 120);
  withBqStubs_(stubs, () => {
    getCalls = 0;
    assertThrowsMessage_(() => bq_(sql), expectedMsg, 'bq_');
    assert.strictEqual(getCalls, 10, 'bq_ must poll getQueryResults exactly 10 times (guard++ < 10) before giving up');
    getCalls = 0;
    assertThrowsMessage_(() => bqAlerts_(sql), expectedMsg, 'bqAlerts_');
    assert.strictEqual(getCalls, 10, 'bqAlerts_ must poll getQueryResults exactly 10 times (g++ < 10) before giving up');
  });
});

t('getUserTzWeekly_ and getUserTzAlerts_ return the same tz on a successful query, each caching independently', () => {
  _tzCache = null; _alertTzCache = null; // start both from a cold cache regardless of test order
  const fields = [{ name: 'tz' }];
  const stubs = {
    query: () => ({ jobComplete: true, schema: { fields }, rows: [{ f: [{ v: 'America/Toronto' }] }],
                     jobReference: { jobId: 'job-tz' } }),
    getQueryResults: () => { throw new Error('getQueryResults must not be called for a single-page, already-complete job'); }
  };
  withBqStubs_(stubs, () => {
    assert.strictEqual(getUserTzWeekly_(), 'America/Toronto');
    assert.strictEqual(getUserTzAlerts_(), 'America/Toronto');
  });
  // Cached: a second call with NO stub installed must still return the cached value -- a cache miss here
  // would throw "BigQuery is not defined" and fail the test, proving the cache actually short-circuits.
  assert.strictEqual(getUserTzWeekly_(), 'America/Toronto');
  assert.strictEqual(getUserTzAlerts_(), 'America/Toronto');
  _tzCache = null; _alertTzCache = null; // leave the module-level cache clean for any later test
});

t('getUserTzWeekly_ and getUserTzAlerts_ both fall back to America/Denver, without throwing, when the query fails', () => {
  _tzCache = null; _alertTzCache = null;
  const stubs = {
    query: () => { throw new Error('simulated BigQuery outage'); },
    getQueryResults: () => { throw new Error('simulated BigQuery outage'); }
  };
  withBqStubs_(stubs, () => {
    assert.strictEqual(getUserTzWeekly_(), 'America/Denver');
    assert.strictEqual(getUserTzAlerts_(), 'America/Denver');
  });
  _tzCache = null; _alertTzCache = null;
});

t('getUserTzWeekly_ and getUserTzAlerts_ both fall back to America/Denver, and cache that, when state.user_tz holds an invalid zone', () => {
  _tzCache = null; _alertTzCache = null;
  const fields = [{ name: 'tz' }];
  const stubs = {
    query: () => ({ jobComplete: true, schema: { fields }, rows: [{ f: [{ v: 'America/Torontoo' }] }],
                     jobReference: { jobId: 'job-bad-tz' } }),
    getQueryResults: () => { throw new Error('getQueryResults must not be called for a single-page, already-complete job'); }
  };
  withBqStubs_(stubs, () => {
    assert.strictEqual(getUserTzWeekly_(), 'America/Denver');
    assert.strictEqual(getUserTzAlerts_(), 'America/Denver');
  });
  // The cache must hold the validated fallback, never the bad zone (no stub installed: a cache miss would throw).
  assert.strictEqual(_tzCache, 'America/Denver');
  assert.strictEqual(_alertTzCache, 'America/Denver');
  assert.strictEqual(getUserTzWeekly_(), 'America/Denver');
  assert.strictEqual(getUserTzAlerts_(), 'America/Denver');
  _tzCache = null; _alertTzCache = null;
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
// v10 (2026-09-04): the reason text must key on the SAME basis gatherData_'s predicate keyed on. Once
// marksFresh/engineFresh came from the cadence-aware marks_current/engine_current pair (bigquery/173),
// naming last_trading_day pointed at a day whose D2a slot had not arrived yet, and the
// d2_ran_last_trading_day branch -- FALSE at every Sunday send -- would have labelled a genuinely missed,
// already-elapsed slot as "normal ... not a fault by itself". These two pin both halves.
t('buildHealthReasons_ names marks_due_through (not last_trading_day) and drops the benign framing when the cadence-aware basis is available', () => {
  // Sunday shape: last_trading_day is FRIDAY, marks_due_through is the Thursday slot D2a has already had.
  const health = { marks_due_through: '2026-09-03', last_trading_day: '2026-09-04', d2_ran_last_trading_day: 'false' };
  const reasons = buildHealthReasons_(health, false, true, 0, [], 0, []);
  assert.strictEqual(reasons.length, 1);
  assert.ok(reasons[0].includes('do not cover 2026-09-03'), `expected the due-through day, got: ${reasons[0]}`);
  assert.ok(!reasons[0].includes('2026-09-04'),
    'must not name last_trading_day: its D2a slot has not arrived yet, so it is not the gap');
  assert.ok(!reasons[0].includes('not a fault by itself'),
    'a cadence-aware miss is by construction an ALREADY-ELAPSED slot -- the benign pre-22:30 MT framing cannot apply');
});
t('buildHealthReasons_ keeps the pre-173 last_trading_day wording when marks_due_through is absent (pre-bigquery/173 live view)', () => {
  // gatherData_ falls back to the strict marks_fresh/engine_fresh pair against such a view, so the old
  // last_trading_day / d2_ran_last_trading_day framing is the CORRECT one there -- pinned so the v10
  // branch above cannot quietly swallow it.
  const noDueThrough = { last_trading_day: '2026-07-08', d2_ran_last_trading_day: 'false' };
  assert.ok(buildHealthReasons_(noDueThrough, false, true, 0, [], 0, [])[0]
    .includes("today's evening data batch (D2) hasn't completed yet for 2026-07-08"));
  const blankDueThrough = { marks_due_through: '', last_trading_day: '2026-07-08', d2_ran_last_trading_day: 'true' };
  assert.ok(buildHealthReasons_(blankDueThrough, false, true, 0, [], 0, [])[0]
    .includes('marks/engine still stale even though D2 logged complete for 2026-07-08'),
    'an empty-string cell (BigQuery can return one for a NULL) must take the fallback, not render a blank day');
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
    green: true, dateLabel: 'Jul 6, 2026' };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked');
});
t('buildSubject_ lists only deployed strategies when strategies are mixed parked/deployed, no VOO data', () => {
  const d = {
    rows: [
      { strategy: 'A', deployed: true, returnPct: 0.0123 },
      { strategy: 'B', deployed: false },
      { strategy: 'C', deployed: true, returnPct: -0.005 }
    ],
    green: true, dateLabel: 'Jul 6, 2026'
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23% · C −0.50%');
});
t('buildSubject_ appends the VOO fragment when d.voo has a return, and never mentions SGOV', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: true, returnPct: 0.0123 }],
    green: true, dateLabel: 'Jul 6, 2026',
    voo: { returnPct: 0.015 }
  };
  const subject = buildSubject_(d);
  assert.strictEqual(subject, 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23% · VOO +1.50%');
  assert.ok(!subject.includes('SGOV'));
});
t('buildSubject_ renders a deployed strategy with a null return as "n/a", not a false "+0.00%"', () => {
  const d = {
    rows: [
      { strategy: 'A', deployed: true, returnPct: 0.0123 },
      { strategy: 'B', deployed: true, returnPct: null }   // missing latest deployed_unit_value
    ],
    green: false, dateLabel: 'Jul 6, 2026'
  };
  const subject = buildSubject_(d);
  assert.ok(subject.includes('B n/a'), `expected "B n/a", got: ${subject}`);
  assert.ok(!subject.includes('B +0.00%'), 'must not fabricate a +0.00% for a null return');
});
t('buildSubject_ omits the VOO fragment when d.voo.returnPct is null (VOO not backfilled yet)', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: true, returnPct: 0.0123 }],
    green: true, dateLabel: 'Jul 6, 2026',
    voo: { returnPct: null }
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · A +1.23%');
});
t('buildSubject_ never appends the VOO fragment in the all-parked branch, even if d.voo exists', () => {
  const d = {
    rows: [{ strategy: 'A', deployed: false }],
    green: true, dateLabel: 'Jul 6, 2026',
    voo: { returnPct: 0.015 }
  };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked');
});
t('buildSubject_ omits the warning suffix when green is true', () => {
  const d = { rows: [{ strategy: 'A', deployed: true, returnPct: 0.01 }], green: true, dateLabel: 'Jul 6, 2026' };
  assert.ok(!buildSubject_(d).includes('check data'));
});
t('buildSubject_ appends the "⚠ check data" warning suffix when green is false', () => {
  const d = { rows: [{ strategy: 'A', deployed: false }], green: false, dateLabel: 'Jul 6, 2026' };
  assert.strictEqual(buildSubject_(d), 'Stock-Trading · Deployed vs Benchmarks — Jul 6, 2026 · all parked · ⚠ check data');
});

// ---- buildParkSection_ (2026-07-29: zero-coverage; a pluralization or "n/a" regression here (e.g.
//      "1 days") reads as normal prose to a skim and would be silent in the rendered email) ----
t('buildParkSection_ singularizes "1 day" / "1 switch" and pluralizes for any other count, including 0', () => {
  const one = buildParkSection_({ park: { vehicle: 'VOO', daysInAllocation: 1, switches30d: 1 } });
  assert.ok(one.includes('1 day ·'), 'expected singular "1 day", not "1 days"');
  assert.ok(one.includes('1 switch / 30d'), 'expected singular "1 switch", not "1 switches"');
  const zero = buildParkSection_({ park: { vehicle: 'VOO', daysInAllocation: 0, switches30d: 0 } });
  assert.ok(zero.includes('0 days ·'), 'expected plural "0 days" (0 is not "1")');
  assert.ok(zero.includes('0 switches / 30d'), 'expected plural "0 switches"');
  const many = buildParkSection_({ park: { vehicle: 'VOO', daysInAllocation: 5, switches30d: 2 } });
  assert.ok(many.includes('5 days ·'));
  assert.ok(many.includes('2 switches / 30d'));
});
t('buildParkSection_ renders "unknown" vehicle and "n/a" tenure/switches when park data is entirely absent', () => {
  const out = buildParkSection_({ park: {} });
  assert.ok(out.includes('<b>unknown</b>'));
  assert.ok(out.includes('n/a · n/a'));
  assert.ok(out.includes('Not enough data yet.'), 'no counterfactual fields -> the not-enough-data fallback, never a fabricated 0%');
});
t('buildParkSection_ falls back to the same "park" defaults when d.park itself is missing (bigquery/91-93 not applied)', () => {
  const out = buildParkSection_({});
  assert.ok(out.includes('<b>unknown</b>'));
  assert.ok(out.includes('Not enough data yet.'));
});
t('buildParkSection_ renders the counterfactual table once any of ai/sgov/voo/rule is non-null', () => {
  const out = buildParkSection_({ park: { vehicle: 'SGOV', daysInAllocation: 3, switches30d: 1, ai: 0.01, sgov: null, voo: null, rule: null } });
  assert.ok(!out.includes('Not enough data yet.'));
  assert.ok(out.includes('AI (actual)'));
  assert.ok(out.includes('+1.00%'));
});

// ---- buildParkSection_ under PARK v4 (v10, 2026-09-04) ----
// bigquery/220 made `vehicle` the MAJORITY sleeve, so the v9 "Current vehicle: X" line reported a
// graded book as if it were still binary: PARK_ALLOCATOR_V4_DESIGN.md's own replayed f=0->25->50 week
// has majority sleeve VOO at every step. These pin the SPLIT rendering and, just as importantly, that
// the pre-220 shape (no target_f_pct) still renders the v9 line rather than a blank or "undefined".
t('buildParkSection_ renders the two-sleeve SPLIT, not the majority-sleeve label, once target_f_pct is present', () => {
  const out = buildParkSection_({ park: { vehicle: 'VOO', targetFPct: 25, riskSleeve: 'VOO', defensiveSleeve: 'SGOV',
                                          daysInAllocation: 2, switches30d: 2 } });
  assert.ok(out.includes('Current allocation: <b>75% VOO / 25% SGOV</b>'),
    `expected the graded split, got: ${out}`);
  assert.ok(!out.includes('Current vehicle:'),
    'a graded book must not also print the binary "Current vehicle" line -- that label is the majority sleeve, not the book');
});
t('buildParkSection_ renders the f=50 tie as an explicit 50/50 split (where the "majority sleeve" label is most misleading)', () => {
  // bigquery/220: a 50/50 book reads vehicle='VOO' because the tie goes to the RISK sleeve. That is the
  // exact input where reporting `vehicle` alone claims a 100% VOO book that is half defensive.
  const out = buildParkSection_({ park: { vehicle: 'VOO', targetFPct: 50, riskSleeve: 'VOO', defensiveSleeve: 'SGOV',
                                          daysInAllocation: 1, switches30d: 1 } });
  assert.ok(out.includes('Current allocation: <b>50% VOO / 50% SGOV</b>'), `expected a 50/50 split, got: ${out}`);
});
t('buildParkSection_ degrades to the v9 single-vehicle label when the v4 columns are absent (pre-bigquery/220 live view)', () => {
  // gatherParkData_'s legacy fallback query returns no target_f_pct/risk_sleeve/defensive_sleeve, so
  // this shape must still render exactly what v9 rendered -- never a partial "undefined% ..." line.
  const out = buildParkSection_({ park: { vehicle: 'SGOV', daysInAllocation: 4, switches30d: 0 } });
  assert.ok(out.includes('Current vehicle: <b>SGOV</b>'), `expected the v9 vehicle label, got: ${out}`);
  assert.ok(!out.includes('undefined'), 'a pre-v4 row must never leak an undefined into the rendered line');
  assert.ok(!out.includes('Current allocation'), 'without target_f_pct there is no split to state');
});
t('buildParkSection_ leads with the AI-era quartet and STATES THE ANCHOR ON EACH block (bigquery/212)', () => {
  // bigquery/212 measured the AI-vs-SGOV sign as anchor-dependent (published inception -1.17pp vs AI era
  // +0.67pp), so a quartet rendered without its anchor is unactionable -- and with two quartets on the
  // page, an unlabelled one is worse than none. Claude_Task_Plan.md's W5 PARK SCORECARD carries the same
  // "state which anchor each number uses" rule; this is its email-side guard.
  const out = buildParkSection_({ park: {
    vehicle: 'VOO', targetFPct: 25, riskSleeve: 'VOO', defensiveSleeve: 'SGOV', daysInAllocation: 2, switches30d: 2,
    ai: 0.00196, sgov: 0.01369, voo: 0.08072, rule: 0.00470,
    aiEraStart: '2026-07-24', aiEra: 0.01063, sgovEra: 0.00392, vooEra: 0.03574, ruleEra: 0.02855 } });
  assert.ok(out.includes('2026-07-24'), 'the AI-era block must name its derived anchor date');
  assert.ok(out.includes('2026-04-17'), 'the demoted inception block must still name its own anchor');
  assert.ok(out.indexOf('2026-07-24') < out.indexOf('2026-04-17'),
    'the AI-era block must LEAD; the inception block is demoted below it');
  assert.ok(out.includes('+1.06%'), 'the AI-era AI figure must be rendered');
  assert.ok(out.includes('+0.20%'), 'the inception AI figure must be KEPT, not dropped (212 left it byte-identical)');
  // Two quartets -> exactly two "AI (actual)" rows, each under its own captioned anchor.
  assert.strictEqual((out.match(/AI \(actual\)/g) || []).length, 2,
    'expected exactly two quartets (AI era + inception) when the anchor is available');
});
t('buildParkSection_ renders ONE anchored quartet when ai_era_start_date is null (pre-212 view, or no BOUND call yet)', () => {
  // bigquery/212 emits ai_era_start_date NULL + four NULL rebased columns rather than anchoring at row
  // zero, and gatherParkData_'s pre-212 fallback omits the columns entirely. Both must degrade to the v9
  // rendering -- one quartet, still labelled with the inception anchor, never a blank or unlabelled row.
  const out = buildParkSection_({ park: { vehicle: 'VOO', daysInAllocation: 3, switches30d: 0,
                                          ai: 0.00196, sgov: 0.01369, voo: 0.08072, rule: 0.00470,
                                          aiEraStart: null, aiEra: null, sgovEra: null, vooEra: null, ruleEra: null } });
  assert.strictEqual((out.match(/AI \(actual\)/g) || []).length, 1, 'expected exactly one quartet without an anchor');
  assert.ok(out.includes('2026-04-17'), 'the single quartet must still state the anchor it was measured on');
  assert.ok(!out.includes('AI era'), 'no AI-era block may render without an anchor date to caption it');
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
t('isTest_ returns true for a synthetic fire-drill row (payload.synthetic === true), even in a roster category (v5)', () => {
  assert.strictEqual(isTest_({ source: 'ops.sp_fire_drill_roster_notice', category: 'strategy_probe_registered',
    payload: '{"synthetic":true,"strategy_code":"ZZ"}' }), true);
});
t('isTest_ returns false for a fire-drill FAILURE alert -- its payload carries no synthetic key, so it stays a real incident (v5)', () => {
  assert.strictEqual(isTest_({ source: 'ops.sp_fire_drill_roster_notice', category: 'roster_notice_fire_drill_failed',
    payload: '{"drill_id":"x","held_before_delivery":false}' }), false);
});
t('isTest_ uses strict equality on payload.synthetic -- boolean true is a test, the string "true" is not', () => {
  // pl_(a).synthetic === true is a strict-equality check by design: a routine that authored
  // synthetic:"true" (string) instead of synthetic:true (boolean) must NOT get silently treated as a
  // test row. Pinned separately from the boolean-true case (already covered via the fire-drill row
  // above) because the string-vs-boolean distinction is the actual behavior being guarded here.
  assert.strictEqual(isTest_({ source: 'router', category: 'cash_tripwire', payload: '{"synthetic":true}' }), true);
  assert.strictEqual(isTest_({ source: 'router', category: 'cash_tripwire', payload: '{"synthetic":"true"}' }), false);
});
t('isTest_ never silences a genuine critical incident that simply has no synthetic key at all', () => {
  // A real fire-drill FAILURE alert (no payload.synthetic key -- see the case above) is one instance of
  // this; this pins the general rule with a plain non-drill critical incident too, so the invariant
  // isn't accidentally scoped to only the fire-drill source/category pairing.
  assert.strictEqual(isTest_({ source: 'router', category: 'cash_tripwire', severity: 'critical', payload: null }), false);
  assert.strictEqual(isTest_({ source: 'router', category: 'cash_tripwire', severity: 'critical' }), false);
});

// ---- pl_ (alert_emailer.gs, v5) ----
t('pl_ returns {} for a null, undefined, or entirely missing payload, and never throws', () => {
  assert.deepStrictEqual(pl_({ payload: null }), {});
  assert.deepStrictEqual(pl_({ payload: undefined }), {});
  assert.deepStrictEqual(pl_({}), {});
  assert.deepStrictEqual(pl_(null), {});
  assert.deepStrictEqual(pl_(undefined), {});
});
t('pl_ returns {} for malformed JSON, without throwing', () => {
  assert.deepStrictEqual(pl_({ payload: '{not json' }), {});
});
t('pl_ returns {} for a JSON scalar payload (valid JSON that parses to a non-object)', () => {
  assert.deepStrictEqual(pl_({ payload: '42' }), {});
  assert.deepStrictEqual(pl_({ payload: '"a string"' }), {});
  assert.deepStrictEqual(pl_({ payload: 'null' }), {});
});
t('pl_ parses a well-formed object payload normally', () => {
  assert.deepStrictEqual(pl_({ payload: '{"strategy_code":"F","capital_usd":2000}' }), { strategy_code: 'F', capital_usd: 2000 });
});

// ---- isRosterNotice_ / isRealRosterNotice_ (alert_emailer.gs, v5) ----
t('isRosterNotice_ is true for each of the six roster-change categories, false for a non-roster category', () => {
  ROSTER_NOTICE_CATEGORIES.forEach(cat => {
    assert.strictEqual(isRosterNotice_({ category: cat }), true, `expected true for category ${cat}`);
  });
  assert.strictEqual(isRosterNotice_({ category: 'cash_tripwire' }), false);
  assert.strictEqual(isRosterNotice_({ category: 'roster_notice_fire_drill_failed' }), false);
});
t('isRealRosterNotice_ is true only for a genuine (non-synthetic) roster notice', () => {
  const real = { category: 'strategy_probe_registered', payload: '{"strategy_code":"F"}' };
  const synthetic = { category: 'strategy_probe_registered', payload: '{"synthetic":true,"strategy_code":"ZZ"}' };
  const nonRoster = { category: 'cash_tripwire', payload: null };
  assert.strictEqual(isRealRosterNotice_(real), true);
  assert.strictEqual(isRealRosterNotice_(synthetic), false);
  assert.strictEqual(isRealRosterNotice_(nonRoster), false);
});

// ---- rosterHeadline_ (alert_emailer.gs, v5) ----
t('rosterHeadline_ renders "code from→to" when the full transition is present', () => {
  assert.strictEqual(
    rosterHeadline_({ category: 'strategy_probe_registered', payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}' }),
    'F PAPER→PROBE'
  );
});
t('rosterHeadline_ falls back to "code · category" when only strategy_code is present', () => {
  assert.strictEqual(
    rosterHeadline_({ category: 'strategy_shadow_registered', payload: '{"strategy_code":"F"}' }),
    'F · strategy_shadow_registered'
  );
});
t('rosterHeadline_ falls back to the bare category when the payload has nothing usable', () => {
  assert.strictEqual(rosterHeadline_({ category: 'roster_below_floor', payload: null }), 'roster_below_floor');
  assert.strictEqual(rosterHeadline_({ category: 'roster_below_floor' }), 'roster_below_floor');
});

// ---- rosterHeadline_ CR/LF stripping (alert_emailer.gs, v6: the clean() helper) ----
t('rosterHeadline_ strips CR/LF from a payload-derived field so the SUBJECT can never carry an injected newline', () => {
  // strategy_code carrying an embedded "\nBOGUS: injected" line models a hostile/corrupt
  // routine-authored payload -- rosterHeadline_ feeds the SUBJECT directly (checkAlerts_ ->
  // alertSubject_ -> rosterHeadline_), so this is the header-injection shape the v6 clean() fix guards.
  const headline = rosterHeadline_({
    category: 'strategy_probe_registered',
    payload: JSON.stringify({ strategy_code: 'F\nBOGUS: injected', from_state: 'PAPER', to_state: 'PROBE' })
  });
  assert.ok(!/[\r\n]/.test(headline), `expected no CR/LF in the headline, got: ${JSON.stringify(headline)}`);
});
t('rosterHeadline_ fallback forms still hold post-v6 (clean() is a no-op absent CR/LF)', () => {
  // Regression pin, grouped: the three fallback tiers above must be unchanged now that clean() runs on
  // every payload field -- clean() only strips \r\n and trims, so ordinary tokens pass through as-is.
  assert.strictEqual(
    rosterHeadline_({ category: 'strategy_probe_registered', payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}' }),
    'F PAPER→PROBE'
  );
  assert.strictEqual(
    rosterHeadline_({ category: 'strategy_shadow_registered', payload: '{"strategy_code":"F"}' }),
    'F · strategy_shadow_registered'
  );
  assert.strictEqual(rosterHeadline_({ category: 'roster_below_floor', payload: null }), 'roster_below_floor');
  assert.strictEqual(rosterHeadline_({ category: 'roster_below_floor' }), 'roster_below_floor');
});

// ---- money_ / rosterDetail_ (alert_emailer.gs, v5) ----
t('money_ formats with a leading $ and thousands separators', () => {
  assert.strictEqual(money_(2000), '$2,000');
  assert.strictEqual(money_(1234567), '$1,234,567');
  assert.strictEqual(money_(950), '$950');
});
t('money_ falls back to String(v) for a non-finite value', () => {
  assert.strictEqual(money_(NaN), 'NaN');
  assert.strictEqual(money_('abc'), 'abc');
});
t('rosterDetail_ omits missing keys entirely -- a payload with only strategy_code yields exactly one row', () => {
  const rows = rosterDetail_({ payload: '{"strategy_code":"F"}' });
  assert.deepStrictEqual(rows, [['Strategy', 'F']]);
});
t('rosterDetail_ renders capital_usd: 0 as the "none — zero capital at risk" form', () => {
  const rows = rosterDetail_({ payload: '{"strategy_code":"F","capital_usd":0}' });
  const capital = rows.find(kv => kv[0] === 'Capital');
  assert.ok(capital, 'expected a Capital row');
  assert.strictEqual(capital[1], 'none — zero capital at risk');
});
t('rosterDetail_ renders a populated payload capital + pct_nav in money format with thousands separators', () => {
  const rows = rosterDetail_({ payload: '{"strategy_code":"F","capital_usd":2000,"pct_nav":1.8}' });
  const capital = rows.find(kv => kv[0] === 'Capital');
  assert.strictEqual(capital[1], '$2,000 (1.8% NAV)');
});
t('rosterDetail_ renders the full field set (transition, roster counts, trigger, reason, commit) in order', () => {
  const rows = rosterDetail_({ payload: JSON.stringify({
    strategy_code: 'F', strategy_name: 'Foo', from_state: 'PAPER', to_state: 'PROBE',
    roster_active_before: 4, roster_active_after: 5, capital_usd: 2000, pct_nav: 1.8,
    kill_trigger: 'drawdown_kill', reason: 'graduated', git_commit: 'abc123'
  }) });
  assert.deepStrictEqual(rows, [
    ['Strategy', 'F — Foo'],
    ['Transition', 'PAPER → PROBE'],
    ['Roster active', '4 → 5'],
    ['Capital', '$2,000 (1.8% NAV)'],
    ['Trigger', 'drawdown_kill'],
    ['Why', 'graduated'],
    ['Commit', 'abc123']
  ]);
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
  assert.strictEqual(alertSubject_(fresh, 0), '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed');
});
t('alertSubject_: N new real alerts + 1 recurring termination-close -> "N new", not "N+1"', () => {
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'router', category: 'stale_data', severity: 'warning' },
  ];
  assert.strictEqual(
    alertSubject_(fresh, 1),
    '⚠ Stock-Trading ALERT — 2 new (1 critical) — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: recurring-only batch (no new alerts this poll) -> no "new" segment', () => {
  const fresh = [];
  assert.strictEqual(
    alertSubject_(fresh, 1),
    '⚠ Stock-Trading ALERT — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: a critical alert riding ONLY in the recurring set must not inflate "(N critical)"', () => {
  const fresh = [{ source: 'router', category: 'stale_data', severity: 'warning' }];
  // The recurring critical (severity of the termination_close_staged row, not modeled in `fresh`) must
  // never enter the "(N critical)" count -- recurringCount is a plain number, it carries no severity.
  assert.strictEqual(
    alertSubject_(fresh, 1),
    '⚠ Stock-Trading ALERT — 1 new — 1 UNCONFIRMED TERMINATION CLOSE (recurring)'
  );
});
t('alertSubject_: a test canary alongside a real new alert -> "(+1 test)" suffix, real alert not softened', () => {
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning' },
  ];
  assert.strictEqual(
    alertSubject_(fresh, 0),
    '⚠ Stock-Trading ALERT — 1 new (1 critical) (+1 test)'
  );
});
t('alertSubject_: a canary-only batch still returns the [TEST] subject unchanged in v5 (regression guard: roster split must not touch this form)', () => {
  const fresh = [{ source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning' }];
  assert.strictEqual(alertSubject_(fresh, 0), '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed');
});
t('alertSubject_: roster-only batch with exactly 1 notice -> the 📋 ROSTER CHANGE subject, no ⚠/ALERT (v5)', () => {
  const fresh = [{ source: 'SL5', category: 'strategy_probe_registered', severity: 'warning',
    payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}' }];
  const subject = alertSubject_(fresh, 0);
  assert.ok(subject.startsWith('📋'), `expected the clipboard emoji, got: ${subject}`);
  assert.ok(subject.includes('ROSTER CHANGE:'), `expected "ROSTER CHANGE:", got: ${subject}`);
  assert.ok(subject.includes('F PAPER→PROBE'), `expected the headline, got: ${subject}`);
  assert.ok(!subject.includes('⚠'), 'a healthy roster notice must not carry the warning glyph');
  assert.ok(!subject.includes('ALERT'), 'a healthy roster notice must not say ALERT');
});
t('alertSubject_: roster-only batch with 2+ notices -> the "N ROSTER CHANGES" plural form (v5)', () => {
  const fresh = [
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning', payload: '{"strategy_code":"F"}' },
    { source: 'M4', category: 'strategy_graduated', severity: 'warning', payload: '{"strategy_code":"B"}' },
  ];
  assert.strictEqual(alertSubject_(fresh, 0), '📋 Stock-Trading — 2 ROSTER CHANGES');
});
t('alertSubject_: mixed batch (1 real critical incident + 1 roster notice) -> ⚠ ALERT leads, "1 new (1 critical)" excludes the roster row, "+1 roster change" appended (v5)', () => {
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning',
      payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}' },
  ];
  assert.strictEqual(
    alertSubject_(fresh, 0),
    '⚠ Stock-Trading ALERT — 1 new (1 critical) — +1 roster change'
  );
});
t('alertSubject_: a synthetic fire-drill row in a roster category renders as the TEST subject, not a roster subject (v5) -- proves a fire drill cannot fabricate a "strategy entered PROBE" email', () => {
  const drillRow = { source: 'ops.sp_fire_drill_roster_notice', category: 'strategy_probe_registered', severity: 'warning',
    payload: '{"synthetic":true,"strategy_code":"ZZ","from_state":"PAPER","to_state":"PROBE"}' };
  assert.strictEqual(isTest_(drillRow), true);
  assert.strictEqual(isRealRosterNotice_(drillRow), false);
  assert.strictEqual(
    alertSubject_([drillRow], 0),
    '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed'
  );
});
t('alertSubject_: a fire-drill FAILURE alert (no synthetic key in its payload) renders as a real critical incident, not a test (v5)', () => {
  const failRow = { source: 'ops.sp_fire_drill_roster_notice', category: 'roster_notice_fire_drill_failed', severity: 'critical',
    payload: '{"drill_id":"x","held_before_delivery":false}' };
  assert.strictEqual(isTest_(failRow), false);
  assert.strictEqual(alertSubject_([failRow], 0), '⚠ Stock-Trading ALERT — 1 new (1 critical)');
});
t('alertSubject_: 1 real roster notice + 1 canary row (recurringCount=0) -> calm 📋 ROSTER CHANGE subject with a "(+1 test)" suffix, no ⚠', () => {
  // This is the exact batch shape whose email BODY header was wrong in v5 (htmlAlerts_/plainAlerts_ used
  // to key the header on incidents.length, which counts the canary row too -- fixed to key on
  // realIncidents.length instead, so a {real roster notice + canary} batch renders the calm roster
  // header, not "⚠ unresolved alerts"). alertSubject_ (the SUBJECT) was always correct; this pins that
  // correctness so a future edit to alertSubject_ can never regress the two back out of agreement.
  // htmlAlerts_/plainAlerts_ themselves build the HTML/plain-text BODIES; the same body-header split is
  // now separately pinned below (2026-08-08 resync) once fmtAlertTs_ has a stand-in to exercise a
  // non-empty batch with -- see the "roster-vs-incident header split" tests near the footer-text block.
  const fresh = [
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning',
      payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}' },
    { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning' },
  ];
  const subject = alertSubject_(fresh, 0);
  assert.ok(subject.startsWith('📋'), `expected the clipboard emoji, got: ${subject}`);
  assert.ok(subject.includes('ROSTER CHANGE:'), `expected "ROSTER CHANGE:", got: ${subject}`);
  assert.ok(subject.includes('(+1 test)'), `expected a "(+1 test)" suffix, got: ${subject}`);
  assert.ok(!subject.includes('⚠'), 'a roster notice + canary batch must not carry the warning glyph');
});
t('alertSubject_: 2 real incidents + 3 roster notices (recurringCount=0) -> reports "2 new", never "5 new", and appends "+3 roster changes"', () => {
  // Pins that healthy roster events (rosterNew) never inflate the incident count (newReal) -- the exact
  // over-reporting bug class the 2026-07-29 fresh-vs-recurring split fixed, now guarded for the v5
  // roster split too: 2 real incidents + 3 roster notices must read "2 new", not "5 new".
  const fresh = [
    { source: 'router', category: 'cash_tripwire', severity: 'critical' },
    { source: 'router', category: 'stale_data', severity: 'warning' },
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning', payload: '{"strategy_code":"F"}' },
    { source: 'M4', category: 'strategy_graduated', severity: 'warning', payload: '{"strategy_code":"B"}' },
    { source: 'SL1', category: 'roster_below_floor', severity: 'warning' },
  ];
  const subject = alertSubject_(fresh, 0);
  assert.ok(subject.includes('2 new'), `expected "2 new", got: ${subject}`);
  assert.ok(!subject.includes('5 new'), `must not count roster notices as incidents, got: ${subject}`);
  assert.ok(subject.includes('+3 roster changes'), `expected "+3 roster changes", got: ${subject}`);
});

// ---- htmlAlerts_ / plainAlerts_ footer text (2026-07-29 regression fix) ----
// A 2026-07 rewrite that split newly-un-notified from recurring counts DROPPED the "in the last
// <LOOKBACK_LABEL>" window callout entirely from both footers as a side effect (LOOKBACK_LABEL went
// unused/dead). Confirmed this test fails without the fix: reverting htmlAlerts_'s footer line to the
// pre-fix `${newlyUnnotifiedCount} newly un-notified and ${recurringCount} recurring.` (no LOOKBACK_LABEL
// mention at all) makes `.includes('in the last')` false and this assertion throws; restoring the
// LOOKBACK_LABEL clause makes it pass again. Same check mirrored for plainAlerts_.
// A real (non-test, non-roster) incident row is used rather than batch=[] (2026-08-08): the v5 rewrite
// wraps the whole incident section, footer included, in `incidents.length ? ... : ''`, so an empty
// batch now renders NO footer at all in htmlAlerts_ and this assertion would never even reach the
// callout text it means to check.
const FOOTER_TEST_ROW = { source: 'router', category: 'cash_tripwire', severity: 'warning', message: 'm', resolved: 'false', alert_ts: '2026-08-08T00:00:00Z' };
t('htmlAlerts_ footer restores the "in the last <LOOKBACK_LABEL>" window callout on the newly-un-notified count', () => {
  const html = htmlAlerts_([FOOTER_TEST_ROW], 2, 3);
  assert.ok(html.includes(`2 newly un-notified in the last ${LOOKBACK_LABEL} and 3 recurring`),
    `expected the window callout in: ${html}`);
});
t('plainAlerts_ footer restores the "in the last <LOOKBACK_LABEL>" window callout on the newly-un-notified count', () => {
  const plain = plainAlerts_([FOOTER_TEST_ROW], 2, 3);
  assert.ok(plain.includes(`2 newly un-notified in the last ${LOOKBACK_LABEL}, 3 recurring`),
    `expected the window callout in: ${plain}`);
});

// ---- htmlAlerts_ / plainAlerts_ resolved/AUTO-RESOLVED/RESOLVED/TEST tag logic (v7, 2026-08-05) ----
// Ported 2026-08-08 from the pre-v7 shape (String(a.resolved) === 'true' -> always "AUTO-RESOLVED",
// with no RESOLVED branch at all) that these copies had silently kept since before v7 existed, because
// batch=[] can never invoke the per-row tag branch. Confirmed each of these fails against that pre-v7
// shape: it renders every resolved row as AUTO-RESOLVED regardless of resolved_note, so the "RESOLVED,
// not AUTO-RESOLVED" and "no AUTO-RESOLVED at all" assertions below both throw against it.
const TAG_TEST_TEST_ROW = { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning', message: 'm', resolved: 'false', alert_ts: 't' };
const TAG_TEST_AUTO_RESOLVED_ROW = { source: 'router', category: 'cash_tripwire', severity: 'warning', message: 'm', resolved: 'true', resolved_note: 'auto-resolved: cleared by next run', alert_ts: 't' };
const TAG_TEST_RESOLVED_ROW = { source: 'router', category: 'cash_tripwire', severity: 'warning', message: 'm', resolved: 'true', resolved_note: 'closed by operator 2026-08-08', alert_ts: 't' };
const TAG_TEST_OPEN_ROW = { source: 'router', category: 'cash_tripwire', severity: 'critical', message: 'm', resolved: 'false', alert_ts: 't' };
t('htmlAlerts_ tags a canary/test row TEST', () => {
  const html = htmlAlerts_([TAG_TEST_TEST_ROW], 1, 0);
  assert.ok(html.includes('⚗ TEST — no action needed'), `expected the TEST tag in: ${html}`);
});
t('htmlAlerts_ tags a resolved_note starting "auto-resolved:" as AUTO-RESOLVED', () => {
  const html = htmlAlerts_([TAG_TEST_AUTO_RESOLVED_ROW], 1, 0);
  assert.ok(html.includes('>AUTO-RESOLVED</span>'), `expected the AUTO-RESOLVED tag in: ${html}`);
});
t('htmlAlerts_ tags a human-closed row (resolved_note NOT starting "auto-resolved:") as RESOLVED, not AUTO-RESOLVED', () => {
  const html = htmlAlerts_([TAG_TEST_RESOLVED_ROW], 1, 0);
  assert.ok(html.includes('>RESOLVED</span>'), `expected the RESOLVED tag in: ${html}`);
  assert.ok(!html.includes('>AUTO-RESOLVED</span>'), `must not mislabel a hand-closed alert as self-healed: ${html}`);
});
t('htmlAlerts_ renders no resolution tag at all for an open (unresolved) incident', () => {
  const html = htmlAlerts_([TAG_TEST_OPEN_ROW], 1, 0);
  assert.ok(!html.includes('RESOLVED'), `an open incident must carry no RESOLVED/AUTO-RESOLVED tag: ${html}`);
  assert.ok(!html.includes('TEST'), `an open incident must carry no TEST tag: ${html}`);
});
t('plainAlerts_ tags a canary/test row [TEST]', () => {
  const plain = plainAlerts_([TAG_TEST_TEST_ROW], 1, 0);
  assert.ok(plain.includes('[TEST] '), `expected the [TEST] tag in: ${plain}`);
});
t('plainAlerts_ tags a resolved_note starting "auto-resolved:" as [AUTO-RESOLVED]', () => {
  const plain = plainAlerts_([TAG_TEST_AUTO_RESOLVED_ROW], 1, 0);
  assert.ok(plain.includes('[AUTO-RESOLVED] '), `expected the [AUTO-RESOLVED] tag in: ${plain}`);
});
t('plainAlerts_ tags a human-closed row as [RESOLVED], not [AUTO-RESOLVED]', () => {
  const plain = plainAlerts_([TAG_TEST_RESOLVED_ROW], 1, 0);
  assert.ok(plain.includes('[RESOLVED] '), `expected the [RESOLVED] tag in: ${plain}`);
  assert.ok(!plain.includes('[AUTO-RESOLVED] '), `must not mislabel a hand-closed alert as self-healed: ${plain}`);
});
t('plainAlerts_ renders no resolution tag at all for an open (unresolved) incident', () => {
  const plain = plainAlerts_([TAG_TEST_OPEN_ROW], 1, 0);
  assert.ok(!/\[(AUTO-)?RESOLVED\]/.test(plain), `an open incident must carry no tag: ${plain}`);
});

// ---- htmlAlerts_ / plainAlerts_ roster-vs-incident header split (v5, 2026-08-04) ----
// Same batch shape as the alertSubject_ test above ("1 real roster notice + 1 canary row"), now
// exercised against the BODY rather than just the subject -- closing the gap that test's own comment
// used to flag ("not re-tested here for the v5 body-header fix").
t('htmlAlerts_ renders the calm roster header, not "unresolved alerts", for a real-roster-notice + canary batch', () => {
  const fresh = [
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning', message: 'm',
      payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}', alert_ts: 't' },
    { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning', message: 'm', alert_ts: 't' },
  ];
  const html = htmlAlerts_(fresh, 2, 0);
  assert.ok(html.includes('📋 Stock-Trading — autonomous roster change'), `expected the calm roster header in: ${html}`);
  assert.ok(!html.includes('unresolved alerts'), `must not print the alarming header for a healthy roster batch: ${html}`);
});
t('plainAlerts_ renders the calm roster header, not an alert count, for a roster-only batch (test rows excluded)', () => {
  const fresh = [
    { source: 'SL5', category: 'strategy_probe_registered', severity: 'warning', message: 'm',
      payload: '{"strategy_code":"F","from_state":"PAPER","to_state":"PROBE"}', alert_ts: 't' },
    { source: 'scheduled.canary', category: 'delivery_canary', severity: 'warning', message: 'm', alert_ts: 't' },
  ];
  const plain = plainAlerts_(fresh, 2, 0);
  assert.ok(plain.startsWith('Stock-Trading — 1 autonomous roster change(s), no action needed'),
    `expected the calm roster header in: ${plain}`);
});

// The timestamp format must include a year for delayed roster notices.
t('fmtAlertTs_ passes the detected timezone, epoch and year-bearing format to Apps Script', () => {
  const savedUtilities = global.Utilities;
  _alertTzCache = 'America/Toronto';
  global.Utilities = { formatDate: (instant, timezone, format) => {
    assert.strictEqual(instant.getTime(), 1793318400000);
    assert.strictEqual(timezone, 'America/Toronto');
    assert.strictEqual(format, 'MMM d, yyyy, h:mm a');
    return 'Oct 29, 2026, 8:00 PM';
  } };
  try {
    assert.strictEqual(fmtAlertTs_({ alert_ms: '1793318400000' }),
      'Oct 29, 2026, 8:00 PM (America/Toronto)');
  } finally {
    global.Utilities = savedUtilities;
    _alertTzCache = null;
  }
});

// ---- v10 ALERT_PROBE_TOKEN contract -- read from the LIVE .gs sources, not mirrored ----
// verifyInboxDelivery_ (alert_emailer.gs) is the only thing in the system that would notice alert mail
// being ACCEPTED by Gmail and then routed away from the Inbox. Since v10 (2026-08-31) it rests on a
// three-part contract that spans two functions AND two files: the write end (checkAlerts_ appends
// ALERT_PROBE_TOKEN to the sent body), the read end (verifyInboxDelivery_'s search base uses that same
// const), and the disambiguation invariant the v10 comment states outright -- "weekly_report.gs never
// emits it". The v10 BUG was a broken version of exactly that contract: the probe searched
// subject:Stock-Trading, a token BOTH scripts emit, so a healthy weekly report sitting in the Inbox
// inside the 600s probe window satisfied `inbox > 0` just as well as this script's own alert mail
// would, resetting inbox_fail_streak while alert mail was silently landing in Trash.
// Both failure directions are SILENT: drop the send-site append and `anywhere` is permanently 0, which
// the probe treats as inconclusive and returns WITHOUT touching the streak (the v8 detector goes dark);
// re-introduce the token into weekly_report.gs and the v10 false-green is back. All three parts are
// impure/cross-file, so pin them by source read -- the same technique the ALERT_SCRIPT_VERSION and
// fmtAlertTs_ guards above use for the same reason.
t('alert_emailer.gs appends ALERT_PROBE_TOKEN at the send site and probes on that same const', () => {
  const gsPath = path.join(__dirname, '..', 'monitoring', 'alert_emailer.gs');
  const gs = fs.readFileSync(gsPath, 'utf8');
  // Anchored on the const NAME, not on its literal value, so a future token rename cannot silently make
  // these assertions vacuous. Whitespace-tolerant (\s*) like the neighbouring guards, so a reformat of
  // alert_emailer.gs produces no spurious red.
  assert.ok(/const\s+ALERT_PROBE_TOKEN\s*=\s*'([a-z0-9]+)'/.test(gs),
    'could not find ALERT_PROBE_TOKEN in alert_emailer.gs -- regex may need updating if the declaration shape changed');
  assert.ok(/plainBody\s*\+=\s*'\\n\\n'\s*\+\s*ALERT_PROBE_TOKEN/.test(gs),
    'the send site (checkAlerts_) must append ALERT_PROBE_TOKEN to the plain body, or the probe can never ' +
    'find its own mail: `anywhere` stays 0 forever, the probe takes its inconclusive branch, and the ' +
    'inbox-misroute detector is dark with no signal');
  assert.ok(/const\s+base\s*=\s*'from:me '\s*\+\s*ALERT_PROBE_TOKEN/.test(gs),
    "verifyInboxDelivery_'s search base must read the same const -- not a literal copy of it, and never a " +
    'subject substring the two .gs files share (that sharing WAS the v10 bug)');
});
t('weekly_report.gs never emits ALERT_PROBE_TOKEN (the v10 disambiguation invariant)', () => {
  const alertGs = fs.readFileSync(path.join(__dirname, '..', 'monitoring', 'alert_emailer.gs'), 'utf8');
  const m = /const\s+ALERT_PROBE_TOKEN\s*=\s*'([a-z0-9]+)'/.exec(alertGs);
  assert.ok(m, 'could not find ALERT_PROBE_TOKEN in alert_emailer.gs');
  const token = m[1];   // derived from the source, never hardcoded, so a rename re-points the check
  const weekly = fs.readFileSync(path.join(__dirname, 'weekly_report.gs'), 'utf8');
  // DELIBERATELY OVER-STRICT: this asserts the token appears NOWHERE in weekly_report.gs, comments
  // included, even though a comment is never emitted in mail. Scoping it to non-comment lines would
  // mean re-implementing JS comment parsing here to buy a maintainer the ability to mention the token
  // in passing; tripping instead forces a deliberate re-read of this invariant, which is the cheaper
  // failure. If you are here because a comment tripped it: state the token as ALERT_PROBE_TOKEN by
  // name, not by value.
  assert.ok(!weekly.includes(token),
    `weekly_report.gs must not contain '${token}' anywhere (comments included): if it ever EMITS the token, ` +
    "a healthy weekly report in the Inbox satisfies the probe exactly as one of alert_emailer.gs's own " +
    'alerts would -- the v10 false-green, reopened');
});

console.log(`\n${passed} assertions passed.`);
process.exit(0);

}

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
 * copies below in the same commit. Located by function NAME (grep the source), not by line number:
 * the sources grow and line numbers drift — six of these pointers had already gone stale by 2026-07-17
 * (e.g. fallbackBarsHtml_ had moved ~60 lines from where a "lines 418-436" pointer claimed) — whereas
 * the function name is a stable, grep-able locator that never rots.
 *   - notDeployedReason_   (weekly_report.gs)
 *   - periodAvg_           (weekly_report.gs)
 *   - isExtrapolated_      (weekly_report.gs)
 *   - benchmarkRow_        (weekly_report.gs)
 *   - num_                 (weekly_report.gs) -- 2026-07-29: was zero-coverage
 *   - signPct_             (weekly_report.gs)
 *   - fmtRetPct_           (weekly_report.gs)
 *   - parseIsoDateLocal_   (weekly_report.gs)
 *   - downsampleDates_     (weekly_report.gs)
 *   - niceNum_             (weekly_report.gs)
 *   - niceYRange_          (weekly_report.gs)
 *   - altTextFor_          (weekly_report.gs) -- 2026-07-29: was zero-coverage
 *   - buildHealthReasons_  (weekly_report.gs)
 *   - buildSubject_        (weekly_report.gs)
 *   - esc_                 (weekly_report.gs)
 *   - VOO_COLOR            (weekly_report.gs)
 *   - clr_                 (weekly_report.gs) -- 2026-07-29: was only exercised indirectly via pctCellHtml_
 *   - fallbackBarsHtml_    (weekly_report.gs)
 *   - pctCellHtml_         (weekly_report.gs)
 *   - buildParkSection_    (weekly_report.gs) -- 2026-07-29: was zero-coverage; pluralization bugs here
 *                           (e.g. "1 days") would be silent in the rendered email
 *   - esc2_                (alert_emailer.gs)
 *   - ROSTER_NOTICE_CATEGORIES (alert_emailer.gs) -- 2026-08-04 v5: new const, the six roster-change
 *                           alert categories; isRosterNotice_ depends on it
 *   - pl_                  (alert_emailer.gs) -- 2026-08-04 v5: new, defensive payload JSON parse
 *   - isTest_              (alert_emailer.gs) -- 2026-08-04 v5: CHANGED, now also true when
 *                           pl_(a).synthetic === true (fire-drill rows), not just canary source/category
 *   - isRosterNotice_      (alert_emailer.gs) -- 2026-08-04 v5: new
 *   - isRealRosterNotice_  (alert_emailer.gs) -- 2026-08-04 v5: new
 *   - rosterHeadline_      (alert_emailer.gs) -- 2026-08-04 v5: new
 *   - money_               (alert_emailer.gs) -- 2026-08-04 v5: new
 *   - rosterDetail_        (alert_emailer.gs) -- 2026-08-04 v5: new
 *   - alertSubject_        (alert_emailer.gs, defined immediately after isTest_/roster helpers;
 *                           signature changed 2026-07-29 from (fresh, combined) to
 *                           (fresh, recurringCount) -- see that file's checkAlerts_ for why. CHANGED
 *                           AGAIN 2026-08-04 v5: now splits roster notices out of the incident count
 *                           via rosterNew/isRealRosterNotice_ and adds a third subject form
 *                           (roster-only batch, no ⚠/ALERT) between the existing [TEST] and mixed forms)
 *   - htmlAlerts_          (alert_emailer.gs) -- 2026-07-29: copied ONLY to regression-test the
 *                           LOOKBACK_LABEL footer text; call with an EMPTY batch ONLY, see its own
 *                           comment above the copy. NOT re-synced for the v5 roster-section changes
 *                           (out of scope for the empty-batch-only footer regression this copy exists
 *                           to guard; alertSubject_ above is the v5-covered twin)
 *   - plainAlerts_         (alert_emailer.gs) -- same empty-batch-only caveat as htmlAlerts_, and
 *                           likewise not re-synced for v5's roster additions
 *
 * Note: signDollar_, fmtAbsDollars_, edgeWord_, dollarCellHtml_, SGOV_GRAY, and the headline-block
 * comparison logic in fallbackBarsHtml_/buildSubject_ were removed from weekly_report.gs in the
 * 2026-07-15 SGOV-removal redesign (the "Deployed Book Since..." section and all vs-SGOV comparisons
 * were dropped) — removed here too, with their now-obsolete tests.
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

function num_(v)  { return (v === null || v === undefined || v === '') ? null : Number(v); }
function signPct_(p){ const s = Math.abs(p).toFixed(2); return (p >= 0 || s === '0.00' ? '+' : '−') + s + '%'; } // unicode minus; force '+' when the rounded magnitude is 0.00 (else a tiny loss prints "−0.00%")
function fmtRetPct_(p){ return p == null ? 'n/a' : signPct_(p * 100); }

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

function niceNum_(x) {
  if (!(x > 0)) return 1;
  const pow = Math.pow(10, Math.floor(Math.log(x) / Math.LN10));
  const f = x / pow;                                    // normalized to [1, 10)
  const nice = f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10;
  return nice * pow;
}

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

function esc_(s)  { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

const VOO_COLOR = '#5f7d95';
function clr_(p)  { return p >= 0 ? '#1a7f5a' : '#c0392b'; }

// Gmail-safe fallback: one bar per deployed strategy (cumulative return), + a VOO bar (if VOO has
// data). Color: green if the strategy beat VOO's own return, red if not, neutral gray-blue if VOO has
// no data yet to compare against (never coerce a missing VOO return to 0 for the comparison — that
// would silently mis-color every positive-return strategy bar as "beating VOO").
function fallbackBarsHtml_(d) {
  const deployed = d.rows.filter(r => r.deployed);
  const hasVooReturn = !!(d.voo && d.voo.returnPct != null);
  const items = deployed.map(r => ({
    label: r.strategy,
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

// Compact PARK section (2026-07-18, PARK_ROUTER_DESIGN.md v2 §9) — current vehicle, tenure, switch
// cadence, and the AI's own realized TWR vs the three counterfactuals (100% SGOV, 100% VOO, the
// record-only v1 rule-shadow). Reuses pctCellHtml_/esc_ exactly like the Average Return table above.
// Guards every field independently (never a bare "undefined"/fabricated 0%) — bigquery/91-93 may not
// be applied live yet, see gatherParkData_.
function buildParkSection_(d) {
  const p = d.park || {};
  const vehicleLabel = p.vehicle ? esc_(p.vehicle) : 'unknown';
  const daysLabel = p.daysInVehicle != null ? `${p.daysInVehicle} day${p.daysInVehicle === 1 ? '' : 's'}` : 'n/a';
  const switchesLabel = p.switches30d != null ? `${p.switches30d} switch${p.switches30d === 1 ? '' : 'es'} / 30d` : 'n/a';

  const hasCf = p.ai != null || p.sgov != null || p.voo != null || p.rule != null;
  const cfRowHtml = (label, val, colorBySign) => `
      <tr>
        <td style="padding:6px 8px;color:#3d4a59;">${esc_(label)}</td>
        <td style="padding:6px 8px;text-align:right;">${pctCellHtml_(val, !!colorBySign)}</td>
      </tr>`;
  const cfTable = hasCf ? `
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:8px;border-collapse:collapse;font-size:12px;">
      ${cfRowHtml('AI (actual)', p.ai, true)}${cfRowHtml('100% SGOV', p.sgov, false)}${cfRowHtml('100% VOO', p.voo, false)}${cfRowHtml('Rule-shadow (record-only)', p.rule, false)}
    </table>` :
    `<div style="margin-top:8px;font-size:11px;color:#8a96a3;">Not enough data yet.</div>`;

  return `
  <tr><td style="padding:16px 22px 6px 22px;">
    <div style="font-size:12px;color:#8a96a3;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;">Park (AI Allocator)</div>
    <div style="margin-top:6px;font-size:12px;color:#1f2d3d;">Current vehicle: <b>${vehicleLabel}</b> · ${daysLabel} · ${switchesLabel}</div>
    ${cfTable}
    <div style="font-size:11px;color:#8a96a3;margin-top:6px;">Park TWR since 2026-04-17 vs. the three PARK_ROUTER_DESIGN.md counterfactuals — SGOV never-left, VOO the prior static policy, rule-shadow the record-only v1 lookup table (owner-rejected as decision-maker).</div>
  </td></tr>`;
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
  return `Stock-Trading · Deployed vs Benchmarks — ${d.dateLabel} · ${tag}${warn}`;
}

// ===== copied verbatim from ops/monitoring/alert_emailer.gs ==================================

function esc2_(s) { return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

// ROSTER-CHANGE NOTICES (owner directive 2026-08-04, bigquery/134_roster_change_notifications.sql).
// The autonomous SISA loop (SL1-SL5) adds and removes trading strategies with no human approval step --
// that stays true. But until 2026-08-04 it did so with no operator-facing signal either: the six
// categories below were raised at 'info', which the SEVERITIES filter above excludes, so a roster change
// reached NO channel. They are now raised at 'warning' and therefore arrive here like any other alert.
//
// They are NOT faults, and rendering them as faults would be its own bug -- an operator who is emailed
// "⚠ ALERT" every time a healthy autonomous action completes learns to ignore the channel. So this file
// splits them into their own visual lane with their own subject line, and renders the structured payload
// (which strategy, which transition, how much capital, why) instead of just the message string.
//
// Keep this list in lockstep with Rule 5's IN list in bigquery/134 and the ROSTER-CHANGE NOTICE contract
// in the Claude_Task_Plan.md preamble. A category in only one of the three places is inert.
const ROSTER_NOTICE_CATEGORIES = [
  'strategy_shadow_registered',   // SL5: entered SHADOW, added to roster.yaml, zero capital
  'strategy_probe_registered',    // SL5: PAPER->PROBE, FIRST REAL CAPITAL (renamed from strategy_adopted)
  'strategy_graduated',           // M4 section H: PROBE->ADOPTED, 30-trade gate cleared
  'retirement_proposed',          // SL4: a drop is pending AR_orc adjudication
  'strategy_deregistered',        // SL5: dropped from the roster
  'roster_below_floor'            // SL1: active roster is at the n_min=2 floor
];

// Parse an alert's payload JSON defensively (v5). ops.alerts.payload is free-shape JSON authored by
// routines from prose, so key drift and malformed payloads are the EXPECTED steady state, not the
// exception (this is the same reasoning bigquery/130 used when it made Rule 1 tolerant of payload-key
// aliases rather than trying to enforce one canonical key). Every caller here treats the payload as
// enrichment only: on NULL/absent/corrupt input this returns {}, each renderer omits the fields it
// cannot find, and the alert still delivers with its message string intact. A payload must never be
// able to suppress an alert email.
function pl_(a) {
  try {
    const o = JSON.parse((a && a.payload) || '{}');
    return (o && typeof o === 'object') ? o : {};
  } catch (e) { return {}; }
}

// A canary row is the weekly alert-delivery self-test (delivery_canary.sql), never a real incident.
// It is labelled [TEST] in both subject and body so it can't be mistaken for an alert — while still
// being delivered + notified_ts-stamped, so the canary's step-1 assertion stays valid.
// v5 adds payload.synthetic: the fire drills (ops.sp_fire_drill_roster_notice, and any future drill
// following the same convention) insert a synthetic row, call the real resolver, and delete it again
// within one procedure. That window is milliseconds wide but nonzero, so a 2-hourly poll CAN in
// principle land inside it — and a drill row in the roster categories would otherwise render as a
// fabricated "strategy ZZ entered PROBE" notice. Matching on payload.synthetic rather than on a source
// prefix is deliberate: a drill FAILURE alert (roster_notice_fire_drill_failed, alert_latch_fire_drill_failed,
// alert_resolve_fire_drill_failed) is a genuine critical incident raised by the same procedures, and
// carries no synthetic key — so it correctly stays a real alert.
function isTest_(a) {
  if (a.source === 'scheduled.canary' || a.category === 'delivery_canary') return true;
  return pl_(a).synthetic === true;
}

// ===== roster-change notices (v5) =====
// A roster notice reports a COMPLETED autonomous action, not a problem. Strategy add/drop has had no
// human approval step since the 2026-07-10 SISA conversion and this channel does not reintroduce one —
// it exists so the owner LEARNS of a roster change instead of having to query state.strategy_roster.
function isRosterNotice_(a) { return ROSTER_NOTICE_CATEGORIES.indexOf(a.category) !== -1; }

// A roster notice that is not itself a fire-drill row. Used everywhere the two lanes are split, so a
// synthetic drill row stays in the TEST lane instead of being rendered as a real roster change.
function isRealRosterNotice_(a) { return !isTest_(a) && isRosterNotice_(a); }

// One-line headline for the subject, e.g. "F PAPER→PROBE". Falls back through progressively less
// specific forms so a payload-less notice still produces something meaningful.
function rosterHeadline_(a) {
  const p = pl_(a);
  if (p.strategy_code && p.from_state && p.to_state) return `${p.strategy_code} ${p.from_state}→${p.to_state}`;
  if (p.strategy_code) return `${p.strategy_code} · ${a.category}`;
  return a.category;
}

// Money/percent formatting without locale APIs (Apps Script's locale is the script's, not the reader's).
function money_(v) {
  const n = Number(v);
  if (!isFinite(n)) return String(v);
  return '$' + Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Ordered [label, value] pairs for the fields the ROSTER-CHANGE NOTICE contract defines
// (Claude_Task_Plan.md preamble). Missing keys are omitted rather than rendered blank, so a partial
// payload degrades gracefully instead of producing a card full of empty rows.
function rosterDetail_(a) {
  const p = pl_(a);
  const out = [];
  const push = (label, v) => {
    if (v === undefined || v === null || String(v) === '') return;
    out.push([label, String(v)]);
  };
  push('Strategy', [p.strategy_code, p.strategy_name].filter(x => x !== undefined && x !== null && x !== '').join(' — '));
  if (p.from_state && p.to_state) push('Transition', `${p.from_state} → ${p.to_state}`);
  if (p.roster_active_before !== undefined && p.roster_active_after !== undefined) {
    push('Roster active', `${p.roster_active_before} → ${p.roster_active_after}`);
  }
  if (p.capital_usd !== undefined && p.capital_usd !== null) {
    const pct = (p.pct_nav !== undefined && p.pct_nav !== null && String(p.pct_nav) !== '') ? ` (${p.pct_nav}% NAV)` : '';
    push('Capital', Number(p.capital_usd) === 0 ? 'none — zero capital at risk' : money_(p.capital_usd) + pct);
  }
  push('Trigger', p.kill_trigger);
  push('Why', p.reason);
  push('Commit', p.git_commit);
  return out;
}

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
  const rosterNew = fresh.filter(isRealRosterNotice_);                        // completed autonomous roster changes
  const newReal = fresh.filter(r => !isTest_(r) && !isRosterNotice_(r));      // genuinely new, non-test INCIDENTS
  const testCount = fresh.length - newReal.length - rosterNew.length;         // test canaries + synthetic drill rows
  if (newReal.length === 0 && recurringCount === 0 && rosterNew.length === 0) {
    // Batch is ONLY the alert-delivery self-test → unmistakable test subject, no ⚠.
    return '⚗ [TEST] Stock-Trading alert-delivery self-test — no action needed';
  }
  if (newReal.length === 0 && recurringCount === 0) {
    // Batch is ONLY roster changes (the common case — the rails rate-limit these to roughly 5-12/year,
    // and they rarely coincide with an incident). A completed autonomous action is not a fault, so this
    // subject deliberately carries no ⚠ and does not say ALERT: an operator emailed "⚠ ALERT" every time
    // the system does something healthy and expected stops reading the channel, which would undermine
    // the genuine alerts that share it.
    const label = rosterNew.length === 1
      ? `ROSTER CHANGE: ${rosterHeadline_(rosterNew[0])}`
      : `${rosterNew.length} ROSTER CHANGES`;
    return `📋 Stock-Trading — ${label}` + (testCount ? ` (+${testCount} test)` : '');
  }
  // Mixed batch: an incident outranks a roster change, so the ⚠ subject leads and roster changes are
  // appended as a count. They are NOT folded into the "N new" figure — that figure means incidents, and
  // inflating it with healthy roster events would repeat the 2026-07-29 over-reporting bug in a new form.
  const crit = newReal.filter(r => r.severity === 'critical').length;
  return '⚠ Stock-Trading ALERT' +
            (newReal.length ? ` — ${newReal.length} new${crit ? ` (${crit} critical)` : ''}` : '') +
            (recurringCount ? ` — ${recurringCount} UNCONFIRMED TERMINATION CLOSE (recurring)` : '') +
            (rosterNew.length ? ` — +${rosterNew.length} roster change${rosterNew.length > 1 ? 's' : ''}` : '') +
            (testCount ? ` (+${testCount} test)` : '');
}

// htmlAlerts_ / plainAlerts_ are copied ONLY to regression-test the LOOKBACK_LABEL footer text
// (2026-07-29 fix) — call them with an EMPTY batch ONLY. Both are otherwise impure: their per-row
// map()/forEach() callback calls fmtAlertTs_(a), which needs Apps-Script globals (Session/BigQuery via
// getUserTzAlerts_) not present under plain Node. With batch=[], that callback is never invoked, so
// fmtAlertTs_ never needs to be defined -- JS resolves identifiers inside a function body lazily, at
// call time, not at parse time. Do NOT call these with a non-empty batch here; it will throw
// "fmtAlertTs_ is not defined".
const LOOKBACK_HOURS   = 168;
const LOOKBACK_LABEL   = (LOOKBACK_HOURS % 24 === 0) ? `${LOOKBACK_HOURS / 24}d` : `${LOOKBACK_HOURS}h`;

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
  const one = buildParkSection_({ park: { vehicle: 'VOO', daysInVehicle: 1, switches30d: 1 } });
  assert.ok(one.includes('1 day ·'), 'expected singular "1 day", not "1 days"');
  assert.ok(one.includes('1 switch / 30d'), 'expected singular "1 switch", not "1 switches"');
  const zero = buildParkSection_({ park: { vehicle: 'VOO', daysInVehicle: 0, switches30d: 0 } });
  assert.ok(zero.includes('0 days ·'), 'expected plural "0 days" (0 is not "1")');
  assert.ok(zero.includes('0 switches / 30d'), 'expected plural "0 switches"');
  const many = buildParkSection_({ park: { vehicle: 'VOO', daysInVehicle: 5, switches30d: 2 } });
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
  const out = buildParkSection_({ park: { vehicle: 'SGOV', daysInVehicle: 3, switches30d: 1, ai: 0.01, sgov: null, voo: null, rule: null } });
  assert.ok(!out.includes('Not enough data yet.'));
  assert.ok(out.includes('AI (actual)'));
  assert.ok(out.includes('+1.00%'));
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

// ---- htmlAlerts_ / plainAlerts_ footer text (2026-07-29 regression fix, empty-batch-only — see the
//      caveat above the copies) ----
// A 2026-07 rewrite that split newly-un-notified from recurring counts DROPPED the "in the last
// <LOOKBACK_LABEL>" window callout entirely from both footers as a side effect (LOOKBACK_LABEL went
// unused/dead). Confirmed this test fails without the fix: reverting htmlAlerts_'s footer line to the
// pre-fix `${newlyUnnotifiedCount} newly un-notified and ${recurringCount} recurring.` (no LOOKBACK_LABEL
// mention at all) makes `.includes('in the last')` false and this assertion throws; restoring the
// LOOKBACK_LABEL clause makes it pass again. Same check mirrored for plainAlerts_.
t('htmlAlerts_ footer restores the "in the last <LOOKBACK_LABEL>" window callout on the newly-un-notified count', () => {
  const html = htmlAlerts_([], 2, 3);
  assert.ok(html.includes(`2 newly un-notified in the last ${LOOKBACK_LABEL} and 3 recurring`),
    `expected the window callout in: ${html}`);
});
t('plainAlerts_ footer restores the "in the last <LOOKBACK_LABEL>" window callout on the newly-un-notified count', () => {
  const plain = plainAlerts_([], 2, 3);
  assert.ok(plain.includes(`2 newly un-notified in the last ${LOOKBACK_LABEL}, 3 recurring`),
    `expected the window callout in: ${plain}`);
});

console.log(`\n${passed} assertions passed.`);
process.exit(0);

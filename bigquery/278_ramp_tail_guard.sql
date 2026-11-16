-- bigquery/278_ramp_tail_guard.sql (2026-11-16)
-- Project: stock-trading-498512.
-- Apply after bigquery/259_live_ramp.sql (it redefines the analytics.fn_ramp_path that file creates).
--
-- SUPERSEDES bigquery/259's analytics.fn_ramp_path. This file is the current canonical definition.
--
-- WHY. The surprise threshold tail_loss_5pct is documented as a LOSS ("declared 5th-percentile campaign
-- return (< 0); NULL = mu - 1.645 * sigma", ops.strategy_ramp_params) but neither spelling was held to
-- that. With mu > 1.645 * sigma the derived default is POSITIVE, so an in-line winning trade below it
-- was scored as a surprise and halved the ramp score (mu=0.03, sigma=0.015, r=+0.004: surprise=TRUE,
-- score 0.4 -> 0.2); a declared tail >= 0 did the same. scripts/ramp_calc.py already refused a declared
-- tail >= 0 but not the derived one, so the two implementations also disagreed on that input.
--
-- WHAT CHANGES, and nothing else: one added line. An effective tail that is not < 0 is treated like the
-- other invalid declarations this function already guards (mu <= 0, sigma <= 0, calibration_trades <= 0):
-- it returns NO path rows, so state.strategy_ramp reads the strategy's opening_score and the score
-- neither ramps nor is cut until the declaration is corrected. scripts/ramp_calc.py raises ValueError on
-- the same input. Every other line of the body is byte-identical to bigquery/259's.
--
-- LIVE EFFECT TODAY: none. Measured 2026-11-16: ops.strategy_ramp_params has 0 rows and no
-- state.strategy_candidates row carries a declared mu, so no strategy's path changes.
--
-- Idempotent: CREATE OR REPLACE FUNCTION. One statement, as scripts/apply_sql_file.py requires.
CREATE OR REPLACE FUNCTION `stock-trading-498512.analytics.fn_ramp_path`(
  trades ARRAY<STRUCT<key STRING, entry_date STRING, exit_date STRING, r FLOAT64>>,
  mu FLOAT64, sigma FLOAT64, opening_score FLOAT64, tail_loss_5pct FLOAT64,
  calibration_trades FLOAT64, loss_asymmetry FLOAT64, surprise_cut FLOAT64, surprise_window_trades FLOAT64,
  sprt_alpha FLOAT64, sprt_beta FLOAT64)
RETURNS ARRAY<STRUCT<idx FLOAT64, key STRING, r FLOAT64, w FLOAT64, n_overlap FLOAT64, llr FLOAT64, cum_llr FLOAT64,
                     surprise BOOL, inc FLOAT64, score_after FLOAT64, evidence_kill BOOL, evidence_confirmed BOOL>>
LANGUAGE js AS r"""
  var out = [];
  if (!(mu > 0) || !(sigma > 0) || !(calibration_trades > 0) || opening_score === null || opening_score === undefined) { return out; }
  var tl = (tail_loss_5pct === null || tail_loss_5pct === undefined) ? (mu - 1.645 * sigma) : tail_loss_5pct;
  if (!(tl < 0)) { return out; }
  var ts = (trades || []).slice();
  ts.sort(function(a, b) {
    var ka = [a.exit_date || "", a.entry_date || "", a.key || ""];
    var kb = [b.exit_date || "", b.entry_date || "", b.key || ""];
    for (var q = 0; q < 3; q++) { if (ka[q] < kb[q]) return -1; if (ka[q] > kb[q]) return 1; }
    return 0;
  });
  var s = Math.min(1.0, Math.max(0.0, Number(opening_score)));
  var cum = 0.0;
  var lastSurprise = null;
  var lower = Math.log(sprt_beta / (1.0 - sprt_alpha));
  var upper = Math.log((1.0 - sprt_beta) / sprt_alpha);
  for (var i = 0; i < ts.length; i++) {
    var t = ts[i];
    var r = Number(t.r);
    var nov = 0;
    for (var j = 0; j < ts.length; j++) {
      if (j === i) continue;
      var u = ts[j];
      if ((u.entry_date || "") <= (t.exit_date || "") && (u.exit_date || "") >= (t.entry_date || "")) nov++;
    }
    var w = 1.0 / (1.0 + nov);
    var llr = (r * mu - mu * mu / 2.0) / (sigma * sigma);
    cum += llr;
    var idx = i + 1;
    var surprise = false;
    var inc = 0.0;
    if (r <= tl) {
      surprise = true;
      if (lastSurprise !== null && (idx - lastSurprise) <= surprise_window_trades) { s = 0.0; } else { s = s * surprise_cut; }
      lastSurprise = idx;
    } else {
      var raw = (r / mu) / calibration_trades;
      if (r < 0) raw = raw * loss_asymmetry;
      inc = w * Math.min(0.15, Math.max(-0.5, raw));
      s = Math.min(1.0, Math.max(0.0, s + inc));
    }
    out.push({idx: idx, key: t.key, r: r, w: w, n_overlap: nov, llr: llr, cum_llr: cum, surprise: surprise,
              inc: inc, score_after: s, evidence_kill: cum <= lower, evidence_confirmed: cum >= upper});
  }
  return out;
""";

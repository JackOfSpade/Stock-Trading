-- bigquery/259_live_ramp.sql — LIVE-RAMP SIZING FOR NEWCOMER STRATEGIES (owner directive 2026-10-19).
-- Project: stock-trading-498512. Apply after 258_router_amendment_notice_alert_policy.sql.
-- Design record: LIVE_RAMP_DESIGN.md (sections 3, 4, 7). Prose: Experiment_Parameters.md rev 20,
-- Strategy.md Rev 51, Claude_Task_Plan.md SL1 STEP 3 / SL3 / SL5 / M4 section H / D1 / D2.
--
-- WHAT THIS REPLACES. The SHADOW -> PAPER -> PROBE -> 30-trade-gate incubation pipeline. A candidate that
-- clears adversarial review now enters PROBE directly with real capital at a dynamic floor, and its
-- deployment cap grows continuously with per-trade evidence (the ramp score). Graduation PROBE -> ADOPTED
-- fires when the score reaches 1.0; the flat 30-trade gate is retired; the evidence kill (a sequential
-- probability ratio test on the declared edge) joins the mechanical kills.
--
-- OBJECTS (in apply order):
--   1. ops.strategy_ramp_params                 TABLE, append-only, latest row per code wins (SL5 writes it)
--   2. state.strategy_candidates                ALTER: the declared ramp parameters SL1 STEP 3 writes
--   3. analytics.fn_ramp_path                   JavaScript UDF: the exact sequential algorithm; mirrored
--                                               byte-for-byte by scripts/ramp_calc.py (tests/fixtures/ramp_vectors.json)
--   4. analytics.strategy_ramp_trades           VIEW: per closed campaign, the path (weight, increment, score after)
--   5. state.strategy_ramp                      VIEW: one row per PROBE strategy: score, cap, headroom, flags
--   6. state.strategy_ramp_calibration          VIEW: opening score vs realized score at calibration_trades
--   7. state.arsenal_rails                      REPLACE (supersedes bigquery/35): incubating_count counts PROBE
--   8. state.strategy_adoption_readiness        REPLACE (supersedes bigquery/143): marker UNDER_REVIEW->PROBE
--   9. perf.kill_flags                          REPLACE (supersedes bigquery/39): adds evidence_kill
--  10. ops.alert_policy                         rows for ramp_surprise_cut and ramp_cap_breached (SL3 notices)
--
-- JavaScript UDF, not SQL: the score update is sequential (a clip to [0,1] after every trade and a
-- multiplicative surprise cut), which a window sum cannot express. The JS body uses double-quoted strings
-- only (never a doubled single quote inside a BigQuery literal). INT64 is not a JavaScript UDF type, so
-- every number crosses the boundary as FLOAT64 and the view casts idx/n_overlap back.

-- 1. ops.strategy_ramp_params ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.strategy_ramp_params` (
  strategy_code          STRING    NOT NULL,
  mu_per_trade           FLOAT64   NOT NULL,                       -- declared expected net return per closed campaign (fraction of cost basis), > 0
  sigma_per_trade        FLOAT64   NOT NULL,                       -- declared per-campaign return standard deviation, > 0
  tail_loss_5pct         FLOAT64,                                  -- declared 5th-percentile campaign return (< 0); NULL = mu - 1.645 * sigma
  holding_horizon_days   INT64     NOT NULL,                       -- declared typical holding period
  opening_score          FLOAT64   NOT NULL,                       -- rubric output in [0, 0.4] (LIVE_RAMP_DESIGN.md section 5)
  calibration_trades INT64 DEFAULT 10 NOT NULL,            -- in-line trades from 0 to 1 at full weight
  loss_asymmetry FLOAT64 DEFAULT 2.0 NOT NULL,           -- multiplier on a losing trade decrement
  surprise_cut FLOAT64 DEFAULT 0.5 NOT NULL,           -- multiplier applied to the score on a surprise
  surprise_window_trades INT64 DEFAULT 5 NOT NULL,             -- second surprise within this many trades -> score 0
  floor_pct_nav FLOAT64 DEFAULT 0.02 NOT NULL,          -- NAV-relative floor
  cost_min_usd FLOAT64 DEFAULT 2000.0 NOT NULL,        -- cost-viability minimum under the floor
  sprt_alpha FLOAT64 DEFAULT 0.05 NOT NULL,
  sprt_beta FLOAT64 DEFAULT 0.20 NOT NULL,
  rubric_json            JSON,                                     -- the rubric components behind opening_score
  source_routine         STRING    NOT NULL,                       -- SL5 at PROBE registration (or an owner session)
  review_id              STRING,                                   -- the strategy-adoption review that authorized the registration
  note                   STRING,
  effective_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL
)
OPTIONS (description = 'Live-ramp parameters per strategy (LIVE_RAMP_DESIGN.md section 3.1). Append-only; the latest effective_ts row per strategy_code is in force. Written by SL5 branch (1) at PROBE registration from the candidate declarations SL1 STEP 3 recorded on state.strategy_candidates.');

-- 2. state.strategy_candidates: the declarations SL1 STEP 3 writes and SL2 cites ---------------------
ALTER TABLE `stock-trading-498512.state.strategy_candidates`
  ADD COLUMN IF NOT EXISTS declared_mu_per_trade FLOAT64,
  ADD COLUMN IF NOT EXISTS declared_sigma_per_trade FLOAT64,
  ADD COLUMN IF NOT EXISTS declared_tail_loss_5pct FLOAT64,
  ADD COLUMN IF NOT EXISTS declared_holding_horizon_days INT64,
  ADD COLUMN IF NOT EXISTS ramp_opening_score FLOAT64,
  ADD COLUMN IF NOT EXISTS ramp_rubric_json JSON;

-- 3. analytics.fn_ramp_path --------------------------------------------------------------------------
-- The contract (LIVE_RAMP_DESIGN.md section 3.3; scripts/ramp_calc.py is the reference implementation):
--   trades are sorted by (exit_date, entry_date, key); w = 1/(1+n_overlap) over OTHER trades whose
--   [entry_date, exit_date] intersects (inclusive, ISO-string comparison); then sequentially
--     llr = (r*mu - mu*mu/2)/sigma^2; cum_llr += llr
--     surprise (r <= tail_loss_5pct): score = 0 if a surprise happened within surprise_window_trades else score*surprise_cut
--     else raw = (r/mu)/calibration_trades, doubled by loss_asymmetry when r < 0, inc = w*clip(raw, -0.5, +0.15),
--          score = clip(score + inc, 0, 1)
--     evidence_kill = cum_llr <= ln(beta/(1-alpha)); evidence_confirmed = cum_llr >= ln((1-beta)/alpha)
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

-- 4. analytics.strategy_ramp_trades ------------------------------------------------------------------
-- A trade is a closed, non-dust analytics.position_campaigns row of a strategy that carries ramp params,
-- with entry_date on or after the strategy's PROBE entry (state.strategy_roster.immutable_since).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_ramp_trades` AS
WITH params AS (
  SELECT * FROM `stock-trading-498512.ops.strategy_ramp_params`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
roster AS (
  SELECT strategy_code, current_state, immutable_since FROM `stock-trading-498512.state.strategy_roster`
),
trades AS (
  SELECT
    c.strategy AS strategy_code,
    c.campaign_key,
    c.entry_date,
    c.exit_date,
    CAST(SAFE_DIVIDE(c.realized_pnl, c.entry_price * c.total_shares_bought) AS FLOAT64) AS r   -- the campaign columns are NUMERIC; the UDF struct field is FLOAT64
  FROM `stock-trading-498512.analytics.position_campaigns` c
  JOIN roster ro ON ro.strategy_code = c.strategy
  WHERE c.exit_date IS NOT NULL
    AND COALESCE(c.open_shares, 0) = 0
    AND NOT COALESCE(c.is_dust, FALSE)
    AND c.entry_price IS NOT NULL AND c.total_shares_bought IS NOT NULL AND c.total_shares_bought > 0
    AND (ro.immutable_since IS NULL OR c.entry_date >= DATE(ro.immutable_since, 'America/Denver'))
),
agg AS (
  SELECT strategy_code,
         ARRAY_AGG(STRUCT(campaign_key AS key, CAST(entry_date AS STRING) AS entry_date,
                          CAST(exit_date AS STRING) AS exit_date, r)
                   ORDER BY exit_date, entry_date, campaign_key) AS trades
  FROM trades
  WHERE r IS NOT NULL
  GROUP BY strategy_code
)
SELECT
  p.strategy_code,
  CAST(path.idx AS INT64)        AS idx,
  path.key                       AS campaign_key,
  path.r                         AS realized_return,
  path.w                         AS overlap_weight,
  CAST(path.n_overlap AS INT64)  AS n_overlap,
  path.llr,
  path.cum_llr,
  path.surprise,
  path.inc                       AS increment,
  path.score_after,
  path.evidence_kill,
  path.evidence_confirmed
FROM params p
JOIN agg a USING (strategy_code),   -- inner: a strategy with params but no closed trade has no path rows (state.strategy_ramp LEFT JOINs this view, so it still reads opening_score); BigQuery cannot IFNULL a typed empty array against ARRAY_AGG's struct type
UNNEST(`stock-trading-498512.analytics.fn_ramp_path`(
  a.trades,
  p.mu_per_trade, p.sigma_per_trade, p.opening_score, p.tail_loss_5pct,
  CAST(p.calibration_trades AS FLOAT64), p.loss_asymmetry, p.surprise_cut, CAST(p.surprise_window_trades AS FLOAT64),
  p.sprt_alpha, p.sprt_beta)) AS path;

-- 5. state.strategy_ramp -----------------------------------------------------------------------------
-- One row per strategy in PROBE that carries ramp params (LIVE_RAMP_DESIGN.md section 4):
--   floor_usd = GREATEST(cost_min_usd, floor_pct_nav * book_nav); full_usd = book_nav / active_count;
--   deployable_cap_usd = floor + score * GREATEST(0, full - floor); headroom_usd = cap - deployed_mv.
-- The cap bounds the strategy's TOTAL deployed market value; D2/D2a size a thesis to headroom_usd.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_ramp` AS
WITH params AS (
  SELECT * FROM `stock-trading-498512.ops.strategy_ramp_params`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
book AS (
  SELECT COALESCE(SUM(nav), 0) AS book_nav FROM `stock-trading-498512.analytics.strategy_nav`
),
rails AS (
  SELECT active_count FROM `stock-trading-498512.state.arsenal_rails`
),
path AS (
  SELECT strategy_code,
         ARRAY_AGG(STRUCT(idx, score_after, cum_llr, surprise, evidence_kill, evidence_confirmed) ORDER BY idx) AS p
  FROM `stock-trading-498512.analytics.strategy_ramp_trades`
  GROUP BY strategy_code
),
last_row AS (
  SELECT strategy_code,
         ARRAY_LENGTH(p) AS trades_n,
         p[ORDINAL(ARRAY_LENGTH(p))] AS l,
         (SELECT MAX(x.idx) FROM UNNEST(p) AS x WHERE x.surprise) AS last_surprise_idx
  FROM path
),
sized AS (
  SELECT
    r.strategy_code,
    r.current_state,
    r.immutable_since                                   AS probe_entry_ts,
    p.effective_ts                                      AS params_effective_ts,
    p.opening_score,
    COALESCE(l.l.score_after, p.opening_score)          AS score,
    COALESCE(l.trades_n, 0)                             AS trades_n,
    COALESCE(l.l.cum_llr, 0.0)                          AS cum_llr,
    COALESCE(l.l.evidence_kill, FALSE)                  AS evidence_kill,
    COALESCE(l.l.evidence_confirmed, FALSE)             AS evidence_confirmed,
    l.last_surprise_idx,
    b.book_nav,
    rails.active_count,
    GREATEST(p.cost_min_usd, p.floor_pct_nav * b.book_nav) AS floor_usd,
    SAFE_DIVIDE(b.book_nav, rails.active_count)            AS full_usd,
    COALESCE(n.deployed_mv, 0)                             AS deployed_mv
  FROM `stock-trading-498512.state.strategy_roster` r
  JOIN params p USING (strategy_code)
  LEFT JOIN last_row l USING (strategy_code)
  LEFT JOIN `stock-trading-498512.analytics.strategy_nav` n ON n.strategy = r.strategy_code
  CROSS JOIN book b
  CROSS JOIN rails
  WHERE r.current_state = 'PROBE'
),
capped AS (
  SELECT *, floor_usd + score * GREATEST(0.0, COALESCE(full_usd, 0.0) - floor_usd) AS deployable_cap_usd
  FROM sized
)
SELECT
  c.*,
  c.deployable_cap_usd - c.deployed_mv                 AS headroom_usd,
  c.deployed_mv > 1.05 * c.deployable_cap_usd           AS cap_breached,
  (ROUND(c.score, 10) >= 1.0   -- ten in-line increments of 0.1 sum to 0.9999999999999999 in binary floating point; the reference implementation rounds to 10 places too
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(c.strategy_code, ':PROBE->ADOPTED'))) AS graduation_ready
FROM capped c;

-- 6. state.strategy_ramp_calibration -----------------------------------------------------------------
-- The calibration log (LIVE_RAMP_DESIGN.md section 5): the opening score the rubric assigned versus the
-- score the strategy had actually earned after calibration_trades closed trades. W5 reads it.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_ramp_calibration` AS
WITH params AS (
  SELECT * FROM `stock-trading-498512.ops.strategy_ramp_params`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
at_cal AS (
  SELECT t.strategy_code, t.score_after AS score_at_calibration, t.cum_llr AS cum_llr_at_calibration
  FROM `stock-trading-498512.analytics.strategy_ramp_trades` t
  JOIN params p USING (strategy_code)
  WHERE t.idx = p.calibration_trades
),
latest AS (
  SELECT strategy_code, MAX(idx) AS trades_n, ARRAY_AGG(score_after ORDER BY idx DESC LIMIT 1)[OFFSET(0)] AS score_now
  FROM `stock-trading-498512.analytics.strategy_ramp_trades`
  GROUP BY strategy_code
)
SELECT
  p.strategy_code,
  r.current_state,
  p.effective_ts            AS params_effective_ts,
  p.source_routine,
  p.opening_score,
  p.rubric_json,
  p.calibration_trades,
  COALESCE(lt.trades_n, 0)  AS trades_n,
  COALESCE(lt.score_now, p.opening_score) AS score_now,
  c.score_at_calibration,
  c.cum_llr_at_calibration,
  c.score_at_calibration IS NOT NULL AS calibration_reached,
  c.score_at_calibration - p.opening_score AS realized_minus_opening
FROM params p
JOIN `stock-trading-498512.state.strategy_roster` r USING (strategy_code)
LEFT JOIN at_cal c USING (strategy_code)
LEFT JOIN latest lt USING (strategy_code);

-- 7. state.arsenal_rails: SUPERSEDES bigquery/35_strategy_arsenal.sql's definition ------------------
-- Only change: incubating_count counts strategies in PROBE (the live ramp) instead of SHADOW+PAPER
-- (state.strategy_roster.is_incubating, which no row will ever carry again), so k_incubate = 2 keeps
-- meaning "at most two concurrent incubations". Every constant and every other column is byte-identical.
-- SUPERSEDED AGAIN (2026-10-25): the current canonical definition is bigquery/266_shadow_paper_restored.sql (EP rev 21: incubating_count counts SHADOW+PAPER again, k_incubate 6, 30-day adoption window). DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.arsenal_rails` AS
WITH consts AS (
  SELECT
    2  AS n_min,                       -- roster floor (blocks SL4 below it; a hit forces SL1 generation)
    8  AS n_max,                       -- roster ceiling (~$10k account cost discipline)
    2  AS k_incubate,                  -- max concurrent PROBE (live-ramp) strategies (rev 20, 2026-10-19; was SHADOW+PAPER)
    3  AS k_regime,                    -- regime-coverage target
    180 AS max_roundtrip_commission_bps, -- accepted probe-scale all-in round-trip ceiling (1.8%)
    90 AS adoption_rate_window_days,   -- <= 1 PROBE per rolling 90 days
    90 AS reject_cooldown_days,
    180 AS terminate_cooldown_days,
    90 AS keep_cooldown_days
),
counts AS (
  SELECT
    (SELECT AS STRUCT COUNTIF(is_active) AS active_count, COUNTIF(current_state = 'PROBE') AS incubating_count
       FROM `stock-trading-498512.state.strategy_roster`) AS roster,
    (SELECT COUNT(*) FROM `stock-trading-498512.events.strategy_lifecycle`
       WHERE to_state = 'PROBE'
         AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS probes_in_window
)
SELECT
  c.n_min, c.n_max, c.k_incubate, c.k_regime, c.max_roundtrip_commission_bps,
  c.max_roundtrip_commission_bps / NUMERIC '100' AS max_roundtrip_commission_pct,
  c.adoption_rate_window_days,
  c.reject_cooldown_days, c.terminate_cooldown_days, c.keep_cooldown_days,
  n.roster.active_count AS active_count, n.roster.incubating_count AS incubating_count, n.probes_in_window,
  n.roster.active_count <= c.n_min      AS at_or_below_floor,
  n.roster.active_count >= c.n_max      AS at_ceiling,
  n.roster.incubating_count >= c.k_incubate AS incubation_cap_reached,
  n.probes_in_window = 0         AS adoption_window_open
FROM consts c CROSS JOIN counts n;

-- 8. state.strategy_adoption_readiness: SUPERSEDES bigquery/143_adversarial_review_correction_path.sql
-- Only change: the idempotency marker is '<code>:UNDER_REVIEW->PROBE' (SL5 branch (1) now registers a
-- SUFFICIENT candidate straight into PROBE). Everything else (the six AND-terms of ready, the fail-closed
-- theater_ok default, the correction-aware adversarial_reviews_current read) is unchanged.
-- SUPERSEDED AGAIN (2026-10-25): the current canonical definition is bigquery/266_shadow_paper_restored.sql (EP rev 21: marker UNDER_REVIEW->SHADOW again). DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_adoption_readiness` AS
WITH latest_verdict AS (
  SELECT strategy AS strategy_code, verdict, review_id
  FROM `stock-trading-498512.state.adversarial_reviews_current`
  WHERE review_type = 'strategy-adoption' AND role = 'orchestrator'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) = 1
),
theater AS (
  SELECT review_id, judge_independent
  FROM `stock-trading-498512.analytics.theater_judge`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  v.verdict,
  v.verdict = 'SUFFICIENT' AS review_sufficient,
  COALESCE(t.judge_independent, FALSE) AS theater_ok,
  NOT rails.incubation_cap_reached AS caps_ok,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->PROBE')) AS not_already_transitioned,
  (v.verdict = 'SUFFICIENT'
   AND COALESCE(t.judge_independent, FALSE)
   AND NOT rails.incubation_cap_reached
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->PROBE'))) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest_verdict v USING (strategy_code)
LEFT JOIN theater t ON t.review_id = v.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'UNDER_REVIEW';

-- 9. perf.kill_flags: SUPERSEDES bigquery/39_beta_adjusted_alpha.sql's definition ------------------
-- Only change: evidence_kill (state.strategy_ramp.evidence_kill, FALSE for a strategy without ramp
-- params) joins the flags D1's daily kill sweep and M4 section H act on. gate_reached stays for history
-- and drives nothing (the 30-trade gate is retired, Experiment_Parameters.md rev 20).
CREATE OR REPLACE VIEW `stock-trading-498512.perf.kill_flags` AS
SELECT
  k.strategy, k.as_of_date, k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
  k.excess_vs_sgov, k.deployed_days, k.closed_trades, k.gate_n,
  k.current_drawdown <= -0.50                                                AS drawdown_kill,        -- kill #1
  (k.deployed_unit_value >= 2 AND k.closed_trades < 30 AND k.deployed_days >= 30) AS runaway_review,   -- kill #3
  ((k.deployed_days >= 756 AND k.excess_vs_sgov <= -0.10)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS m2m_underperf_review, -- kill #4, beta-adjusted (ITEM 10)
  (k.closed_trades >= 30)                                                    AS gate_reached,         -- historical: the retired 30-trade gate
  ((k.deployed_days >= 90 AND k.excess_vs_sgov <= -0.15)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS interim_underperf_warning, -- beta-adjusted (ITEM 10)
  COALESCE(sr.evidence_kill, FALSE)                                          AS evidence_kill,        -- rev 20: SPRT lower boundary on the declared edge
  b.beta_hat, b.alpha_annualized, COALESCE(b.min_n_met, FALSE) AS beta_min_n_met
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
      FROM `stock-trading-498512.perf.strategy_daily`) k
LEFT JOIN `stock-trading-498512.analytics.strategy_beta_latest` b ON b.strategy = k.strategy
LEFT JOIN `stock-trading-498512.state.strategy_ramp` sr ON sr.strategy_code = k.strategy
WHERE k.rn = 1;

-- 10. ops.alert_policy: the two SL3 ramp notices --------------------------------------------------------
-- Both are NOTICES raised by SL3 via ops.sp_raise_alert_once with a fixed message naming the strategy code
-- and the trade index (identities, not measurements); both are email-only (scripts/alert_relay.py
-- EMAIL_ONLY_CATEGORIES): the system already acted, nothing is pending on the owner. Closed by SL3 on the
-- fire AFTER the one that raised them (alert_ts < this run start), the prose_regression_confirmed shape.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT category, latching, resolve_rule, note FROM UNNEST([
  STRUCT('ramp_surprise_cut' AS category, FALSE AS latching,
    'NOTICE closed by SL3 on the run AFTER the one that raised it: UPDATE ops.alerts SET resolved=TRUE ... WHERE category=ramp_surprise_cut AND NOT resolved AND alert_ts < this run start, BEFORE any new raise. Not condition-healed: the surprise cut already happened and is recorded in analytics.strategy_ramp_trades. Never critical; never pushed (EMAIL_ONLY_CATEGORIES); never in the bigquery/134 Rule 5 list.' AS resolve_rule,
    'LIVE-RAMP NOTICE (LIVE_RAMP_DESIGN.md section 3.3; registered 2026-10-19 before first firing). SL3 raises one per NEW surprise trade (a closed campaign at or below the declared tail_loss_5pct) on a PROBE strategy: the ramp score was halved, or floored on a second surprise within surprise_window_trades. Warning so the emailer delivers it; email-only because the de-ramp is automatic.' AS note),
  STRUCT('ramp_cap_breached', FALSE,
    'NOTICE closed by SL3 on the run AFTER the one that raised it, same shape as ramp_surprise_cut. If state.strategy_ramp.cap_breached is still TRUE on that later fire SL3 raises it again (sp_raise_alert_once dedups while the earlier row is open). Never critical; email-only.',
    'LIVE-RAMP NOTICE (LIVE_RAMP_DESIGN.md section 4; registered 2026-10-19 before first firing). SL3 raises it when a PROBE strategy deployed market value exceeds 1.05 x its deployable_cap_usd (state.strategy_ramp.cap_breached): a thesis was sized past headroom_usd, or the cap fell under open positions after a de-ramp. Nothing resizes an open position; D2/D2a size the NEXT entry to headroom.')
]) AS s
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alert_policy` p WHERE p.category = s.category);

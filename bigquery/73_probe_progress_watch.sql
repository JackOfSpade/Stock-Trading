-- PROBE stuck watch (loop-completeness audit 2026-07-16) — completes the SHADOW(60)/PAPER(35 ITEM 9)
-- 400-day stuck-flag family for the one lifecycle stage that had none. Deliberately zero-trade-only:
-- any closed trade or open position exempts, so a slow-but-alive archetype is never culled; routes
-- through SL4's default-KEEP adversarial retirement (real capital), not a direct SL3 cull. 90-day
-- roster_change_log cooldown mirrors bigquery/39's candidacy guard. Apply after 39, 62.
-- SUPERSEDED for state.strategy_probe_progress by bigquery/126_dust_operational_hardening.sql.
--
-- PROBLEM: SHADOW and PAPER both have 400-day 'stuck' culls (bigquery/60_shadow_stuck_cull.sql,
-- bigquery/35_strategy_arsenal.sql ITEM 9) executed by SL3. PROBE has nothing:
-- state.strategy_retirement_candidacy (bigquery/39_beta_adjusted_alpha.sql:183) filters
-- current_state='ADOPTED', excluding PROBE; the 30-trade gate (Claude_Task_Plan.md, D2/M4 §H) fires
-- only when gate_reached=TRUE (closed_trades>=30 — never reached by a signal-dead strategy); the
-- drawdown/m2m triggers need trades/deployed-days a zero-trade strategy never accrues. A PROBE
-- strategy whose signal path dies post-graduation would hold its $2,000 allocation invisibly forever.
--
-- FIX: an objective "stuck" flag for PROBE members, mirroring the SHADOW/PAPER 400-day family:
-- >=400 days in PROBE, fully funded (funding_gap_dollars=0), ZERO closed trades, ZERO open positions,
-- and no RETIREMENT_PROPOSED within the trailing 90 days (the same cooldown guard
-- state.strategy_retirement_candidacy uses, bigquery/39:170-175 — without it, a KEEP verdict would be
-- re-proposed by SL4 every month forever). Routes through SL4 STEP 1b (Claude_Task_Plan.md) into the
-- existing default-KEEP adversarial retirement review — never a direct cull, because PROBE strategies
-- trade real (if frozen/small) capital.
--
-- Column provenance (verified live 2026-07-16): perf.strategy_daily has as_of_date/strategy/
-- closed_trades (bigquery/03_twr_engine.sql:145-149); state.strategy_probe_funding_gap has
-- strategy_code/funding_gap_dollars (bigquery/62_probe_stake_funding.sql:40-46); state.strategy_roster
-- has immutable_since (bigquery/35_strategy_arsenal.sql:287, preserved by bigquery/51); an open
-- position is exit_date IS NULL on analytics.position_lifecycle (bigquery/03_twr_engine.sql:48, NOT
-- bigquery/04).
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_probe_progress` AS
WITH probe AS (
  SELECT strategy_code, immutable_since
  FROM `stock-trading-498512.state.strategy_roster`
  WHERE current_state = 'PROBE'
),
trades AS (
  SELECT strategy AS strategy_code, closed_trades
  FROM `stock-trading-498512.perf.strategy_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
openpos AS (
  SELECT strategy AS strategy_code, COUNT(*) AS n_open
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE exit_date IS NULL   -- verified: bigquery/03_twr_engine.sql:48 defines the view (NOT bigquery/04); an open position is exit_date IS NULL
  GROUP BY 1
)
SELECT
  p.strategy_code,
  DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) AS probe_days,
  COALESCE(fg.funding_gap_dollars, 0) AS funding_gap_dollars,
  COALESCE(t.closed_trades, 0) AS closed_trades,
  COALESCE(o.n_open, 0) AS n_open_positions,
  -- stuck: all four conditions AND the same 90-day post-proposal cooldown guard bigquery/39's
  -- retirement candidacy uses (bigquery/39_beta_adjusted_alpha.sql:170-175) — without it, a KEEP
  -- verdict would be re-proposed by SL4 every month forever (stuck never self-clears). The
  -- NOT EXISTS below is against a real backtick-quoted table (ops.roster_change_log), not a
  -- WITH-clause CTE, so it de-correlates fine at query time.
  (DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) >= 400
   AND COALESCE(fg.funding_gap_dollars, 0) = 0
   AND COALESCE(t.closed_trades, 0) = 0
   AND COALESCE(o.n_open, 0) = 0
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = p.strategy_code
                     AND cl.to_state = 'RETIREMENT_PROPOSED'
                     AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY))
  ) AS stuck
FROM probe p
LEFT JOIN `stock-trading-498512.state.strategy_probe_funding_gap` fg USING (strategy_code)
LEFT JOIN trades t USING (strategy_code)
LEFT JOIN openpos o USING (strategy_code);

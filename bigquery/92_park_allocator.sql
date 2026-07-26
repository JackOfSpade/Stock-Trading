-- bigquery/92_park_allocator.sql — AI Park Allocator: menu reference, owner kill-switch,
-- decision-log read views, anti-churn budget substrate, record-only rule-table shadow benchmark,
-- shadow-phase promotion readiness, and the GENERALIZED (multi-vehicle-capable) park position /
-- reconciliation / mark-discontinuity views. Project: stock-trading-498512.
--
-- Spec: PARK_ROUTER_DESIGN.md v2 (owner review 2026-07-18) — the AI makes the daily park-vehicle
-- call (D1 §3), D2 converts a bound SWITCH to an events.park_policy_changes row (unchanged
-- machinery, bigquery/54), and this file's views are the read/measurement/anti-churn substrate
-- around that judgment call. NO rule anywhere in this file CHOOSES a vehicle for real trading —
-- state.park_rule_shadow is an explicit record-only benchmark (design v2 §9.3), not a decision path.
--
-- SCOPE NOTE (do not extend without an explicit owner directive, same discipline as bigquery/54):
-- this file lands SCHEMA/PLUMBING ONLY. It does NOT wire D1's `## PARK ALLOCATION CALL` step, D2's
-- conversion clause, D2a's signal-ingest step, ops/cadence.yaml, ops/autonomy_levels.yaml's
-- `park_allocator` loop registration, or the golden-scenario fixtures — those are prose/YAML/test
-- changes tracked separately per PARK_ROUTER_DESIGN.md §12's change-inventory table and are OUT OF
-- SCOPE for this SQL-only pass.
--
-- DEPENDENCY NOTE (read before a DR rebuild or a live apply): state.park_signal_daily and
-- state.signal_marks_curated (referenced by state.park_rule_shadow, the generalized
-- state.park_reconciliation, and — as of the 2026-07-19 fix — state.mark_discontinuity_watch below)
-- are defined in bigquery/91_park_signal_layer.sql, NOT in this file. At the time this file's SQL
-- was drafted, bigquery/91 did not yet exist in the repo
-- (confirmed via `list_table_ids state` — no park_signal_daily/signal_marks_curated table live);
-- its column names were inferred from PARK_ROUTER_DESIGN.md §6/§9.3 and this file's own task spec.
-- bigquery/91 has since landed in this same worktree — cross-checked (read-only) against its final
-- text: state.park_signal_daily's actual output columns (mark_date, vix_close, vix_med3, spy_close,
-- spy_50dma, spy_200dma, spy_trend, dd_from_252d_high, shock_overlay, inflation_trend,
-- growth_momentum, policy_stance, risk_sentiment) and state.signal_marks_curated's (mirrors
-- events.signal_marks: mark_date, ticker, close, dividend, split_ratio, source, ingest_ts, row_uid)
-- match every name this file assumed exactly — no correction needed.
--
-- Idempotent throughout (CREATE OR REPLACE VIEW for every view; CREATE TABLE IF NOT EXISTS +
-- guarded INSERT ... WHERE NOT EXISTS for ops.park_control, same shape as ops.arsenal_control /
-- ops.trading_control). Apply via the BigQuery MCP execute_sql, in order top to bottom.
--
-- Apply after bigquery/91_park_signal_layer.sql (state.park_signal_daily, state.signal_marks_curated
-- — item 5 and part of item 7 below read these), bigquery/54_park_policy_voo_cutover.sql
-- (events.park_policy_changes, state.park_policy_current, state.park_position — items 4/7 read
-- these; items 7/8 below SUPERSEDE two of 54's views and one of bigquery/82's), bigquery/82_split_
-- aware_engine.sql (state.mark_discontinuity_watch — item 8 below supersedes it), bigquery/09_
-- market_calendar.sql (state.market_calendar, state.trading_day_today — items 4/6, item 4's
-- trading-day cooldown count added 2026-07-19), bigquery/01_schema.sql (events.decision_log —
-- items 3/4/6, item 4's allocator-epoch filter added 2026-07-19). Companion edits (same commit):
-- superseded-markers added into bigquery/54 and bigquery/82 pointing here.

-- ============================================================================
-- 1. state.park_menu — the owner-bounded allocation universe (PARK_ROUTER_DESIGN.md §4). An
-- allowlist RAIL, not a decision. CORRECTION (2026-07-19 adversarial review): membership is NOT an
-- fn_order_guard parameter — fn_order_guard has no menu-awareness. The actual mechanical enforcement
-- is a `SELECT COUNT(*) FROM state.park_menu WHERE ticker = '<vehicle>'` check inlined as the FIRST
-- checklist item in D2's PARK ALLOCATION CONVERSION step (Claude_Task_Plan.md) and as the first step
-- of every park-order craft in Operating_Protocols.md §13.E — an off-menu vehicle is HELD/blocked
-- there, before any order is crafted, not filtered by this table's own read. risk_tier is used ONLY
-- to classify a switch's direction (de-risk/re-risk/lateral) for the anti-churn rails (§7) — never to
-- pick a vehicle. Literal 12-row reference view, same UNNEST(ARRAY[STRUCT(...)]) literal-table idiom
-- as bigquery/09_market_calendar.sql's holiday seed.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_menu` AS
SELECT * FROM UNNEST([
  STRUCT('CASH' AS ticker, 'cash'              AS asset_class, 0 AS risk_tier),
  STRUCT('SGOV' AS ticker, 'tbill'             AS asset_class, 0 AS risk_tier),
  STRUCT('GOVT' AS ticker, 'govt_broad'        AS asset_class, 1 AS risk_tier),
  STRUCT('IEF'  AS ticker, 'govt_intermediate' AS asset_class, 1 AS risk_tier),
  STRUCT('MUB'  AS ticker, 'muni'              AS asset_class, 1 AS risk_tier),
  STRUCT('LQD'  AS ticker, 'ig_corp'           AS asset_class, 2 AS risk_tier),
  STRUCT('TLT'  AS ticker, 'govt_long'         AS asset_class, 2 AS risk_tier),
  STRUCT('HYG'  AS ticker, 'high_yield'        AS asset_class, 3 AS risk_tier),
  STRUCT('PFF'  AS ticker, 'preferred'         AS asset_class, 3 AS risk_tier),
  STRUCT('AOR'  AS ticker, 'balanced'          AS asset_class, 3 AS risk_tier),
  STRUCT('VOO'  AS ticker, 'equity_sp500'      AS asset_class, 4 AS risk_tier),
  STRUCT('VTI'  AS ticker, 'equity_total'      AS asset_class, 4 AS risk_tier)
]);

-- ============================================================================
-- 2. ops.park_control — owner kill-switch for the park allocator (append-only, latest-row-wins,
-- exact analog of ops.arsenal_control / ops.trading_control — same shape confirmed live via
-- get_table_info). enabled=FALSE means the allocator runs RECORD-ONLY: D1 still makes and logs the
-- daily call, but D2 never converts a bound SWITCH into an events.park_policy_changes row — the
-- book stays on its current vehicle and §13.E sweeps/covers continue uninterrupted (this is NOT a
-- trading halt). forced_vehicle, when set, pins the book to a specific menu ticker regardless of
-- what the AI calls that day; the AI still runs and logs its own call (and any disagreement) even
-- while pinned, so the record stays complete. Deliberately NO ops.sp_assert_park_router_enabled (or
-- any RAISE-based assert procedure) in this file — unlike ops.trading_control/ops.arsenal_control,
-- which gate routines that would otherwise take an irreversible action if not checked first, the
-- park-allocator's compensating control is D2's own conversion-clause prose reading
-- state.park_control_latest directly (record-only vs bind is a branch in D2's existing analysis-
-- >conversion step, not a fatal top-of-routine abort) — see PARK_ROUTER_DESIGN.md §8. This is a
-- deliberate scope choice for this file, not an oversight: do not add an assert procedure here
-- without updating the D2 conversion-clause prose in the same change.
-- DROPPED by bigquery/108_park_allocator_immediate_binding.sql (2026-07-26 — immediate-binding
-- redesign, owner directive: "human would never do this manually. remove this feature." No
-- replacement lever; owner recourse going forward is a direct instruction in any session, not a
-- control table). Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-create live — 108 drops both this table and state.park_control_latest below.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.park_control` (
  control_id STRING DEFAULT GENERATE_UUID(),
  control_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  enabled BOOL NOT NULL,          -- FALSE = allocator runs RECORD-ONLY; D2 never converts a bound
                                   --   SWITCH into events.park_policy_changes. Sweeps/covers on the
                                   --   CURRENT vehicle continue — this is not a trading halt.
  forced_vehicle STRING,          -- non-NULL = owner pins the book to this state.park_menu ticker;
                                   --   the AI still calls and logs daily (and may record disagreement).
  reason STRING,
  set_by STRING,                  -- 'operator' | routine id | 'seed'
  PRIMARY KEY (control_id) NOT ENFORCED
) PARTITION BY DATE(control_ts)
OPTIONS(description='Append-only park-allocator kill-switch/pin (PARK_ROUTER_DESIGN.md §8; analog of ops.arsenal_control / ops.trading_control). Latest row by control_ts wins (state.park_control_latest). enabled=FALSE = allocator records-only (D1 still calls and logs; D2 does not convert a bound SWITCH; existing sweep/cover on the current vehicle continues). forced_vehicle pins the book to a specific menu ticker. Seeded enabled=TRUE / forced_vehicle=NULL so the loop starts in a known-open, unpinned state; flip with a manual INSERT. No stored-procedure gate on this table by design — see the CREATE TABLE comment above.');

-- Seed exactly once so the table is never empty (state.park_control_latest below fails SAFE —
-- disabled — on an impossible empty table, same defensive pattern as state.arsenal_enabled).
INSERT INTO `stock-trading-498512.ops.park_control` (enabled, forced_vehicle, reason, set_by)
SELECT TRUE, NULL, 'Initial seed — park allocator kill-switch activated open/unpinned ahead of Phase 0/1 rollout (PARK_ROUTER_DESIGN.md §10). bigquery/92_park_allocator.sql.', 'seed'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.park_control`);

-- Latest-row-wins read view. Fail-safe defaults (enabled=FALSE, forced_vehicle/reason/set_by/
-- control_ts NULL) on an impossible empty table — same ARRAY_AGG-single-row-guarantee pattern as
-- state.arsenal_enabled / state.trading_control_latest.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_control_latest` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(
           STRUCT(enabled, forced_vehicle, reason, set_by, control_ts)
           ORDER BY control_ts DESC LIMIT 1
         )[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.park_control`
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  ctrl.latest.forced_vehicle           AS forced_vehicle,
  ctrl.latest.reason                   AS reason,
  ctrl.latest.set_by                   AS set_by,
  ctrl.latest.control_ts               AS control_ts
FROM ctrl;

-- ============================================================================
-- 3. state.park_allocation_recent / state.park_allocation_latest — the daily PARK ALLOCATION CALL
-- audit trail (PARK_ROUTER_DESIGN.md §3.4): every entry_type='park-allocation' events.decision_log
-- row (including daily KEEP no-change rows — the design's calibration substrate). vehicle,
-- conviction, conviction_pct, direction, and status are read out of the `fields` JSON structured-
-- readings snapshot D1 writes each call (not the native decision_log.conviction/conviction_pct
-- typed columns — the park call's own structured payload is the source of truth for this view,
-- per the task spec: "parsing fields JSON via JSON_VALUE"). Newest-first LIMIT 10, same
-- ORDER BY ... LIMIT N idiom as bigquery/02_ai_layer.sql's precedent-retrieval view.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_allocation_recent` AS
SELECT
  entry_id,
  entry_date,
  event_ts,
  decision,
  title,
  JSON_VALUE(fields, '$.vehicle')                               AS vehicle,
  JSON_VALUE(fields, '$.conviction')                            AS conviction,
  SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)  AS conviction_pct,
  JSON_VALUE(fields, '$.direction')                             AS direction,  -- 'de-risk' | 're-risk' | 'lateral' | 'keep'
  JSON_VALUE(fields, '$.status')                                AS status      -- 'PENDING' | 'BOUND' | 'RECORD_ONLY'
FROM `stock-trading-498512.events.decision_log`
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 10;

-- Top-of-stack convenience view (today's/most-recent call).
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_allocation_latest` AS
SELECT * FROM `stock-trading-498512.state.park_allocation_recent`
ORDER BY event_ts DESC
LIMIT 1;

-- ============================================================================
-- 4. state.park_switch_budget — anti-churn budget substrate for PARK_ROUTER_DESIGN.md §7.4/§7.5
-- (2-per-30-days re-risk/lateral budget; 5-trading-day de-risk cooldown). Record-only reference
-- view — no enforcement lives here, D2's conversion-clause prose reads it. Pairs each
-- events.park_policy_changes row with its predecessor by insertion order (event_ts, the house
-- transition-time discriminator — bigquery/01_schema.sql's queue_events note, bigquery/54's
-- park_policy_current fix — NEVER effective_date), joins state.park_menu twice for risk_tier, and
-- classifies the pair's direction. A "switch" is a pair whose vehicle actually changed; a
-- same-vehicle correction row (if one is ever inserted) is not a switch and does not classify.
--
-- FIXES (2026-07-19 adversarial review):
--  * HIGH — cooldown is now a TRADING-day count via state.market_calendar (same COUNT(*) pattern as
--    bigquery/76_owner_confirmation_liveness.sql's trading_days_since_last_fill), not a calendar-day
--    DATE_DIFF, which over-counted a weekend/holiday-spanning cooldown as satisfied early. The new
--    `outside_cooldown BOOL` column resolves the never-de-risked case to TRUE (NULL-safe) rather than
--    leaving callers to compare a NULL raw count against 5 (UNKNOWN, which would wrongly block the
--    very first re-risk) — `days_since_last_down_switch` (now trading days, same column name) is kept
--    alongside it for observability.
--  * MED — an "allocator epoch" filter (`switches` now only pairs events.park_policy_changes rows
--    from the first-ever entry_type='park-allocation' events.decision_log row forward) stops the
--    manual 2026-07-15 SGOV->VOO cutover (bigquery/54, NOT an AI park-allocator decision) from
--    pre-spending the AI's anti-churn budget/cooldown. NULL-safe: before the allocator's first real
--    call, epoch_start_ts is NULL, the `>=` filter is UNKNOWN for every row (matches nothing), and
--    this view correctly reads 0 switches / outside_cooldown=TRUE.
--
-- `budget` and `cooldown` are each independently-guaranteed single-row scalar aggregations (no
-- GROUP BY) — CROSS JOINed at the end (1 row x 1 row = 1 row) rather than aggregated together, so
-- the view keeps its "must return one sane row even with <2 policy rows, or 0 park-allocation calls
-- logged yet" contract without a GROUP BY/aggregation error on the non-aggregated cooldown columns.
-- DROPPED by bigquery/108_park_allocator_immediate_binding.sql (2026-07-26 — immediate-binding
-- redesign, owner directive: every SWITCH now binds same-day at any conviction, so there is no
-- budget/cooldown left to measure). Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-create live — 108 drops it.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_switch_budget` AS
WITH epoch AS (
  SELECT MIN(event_ts) AS epoch_start_ts
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'park-allocation'
),
ordered AS (
  SELECT
    event_ts,
    vehicle,
    LAG(vehicle) OVER (ORDER BY event_ts) AS prev_vehicle
  FROM `stock-trading-498512.events.park_policy_changes`
),
switches AS (
  SELECT
    o.event_ts,
    CASE
      WHEN m_new.risk_tier > m_old.risk_tier THEN 'up'       -- re-risk
      WHEN m_new.risk_tier < m_old.risk_tier THEN 'down'      -- de-risk
      ELSE 'lateral'
    END AS direction
  FROM ordered o
  JOIN `stock-trading-498512.state.park_menu` m_new ON m_new.ticker = o.vehicle
  JOIN `stock-trading-498512.state.park_menu` m_old ON m_old.ticker = o.prev_vehicle
  CROSS JOIN epoch e
  WHERE o.prev_vehicle IS NOT NULL
    AND o.vehicle != o.prev_vehicle
    AND o.event_ts >= e.epoch_start_ts   -- allocator-epoch exemption; UNKNOWN (excludes all rows) if e.epoch_start_ts IS NULL
),
budget AS (
  SELECT
    COUNTIF(direction IN ('up', 'lateral')
            AND event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)) AS n_up_or_lateral_30d,
    MAX(IF(direction = 'down', event_ts, NULL))                                   AS last_down_ts,
    MAX(event_ts)                                                                 AS last_switch_ts
  FROM switches
),
ltd AS (
  SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`
),
cooldown AS (
  SELECT
    b.last_down_ts,
    CASE
      WHEN b.last_down_ts IS NULL THEN NULL   -- no de-risk switch within the allocator epoch
      ELSE (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(b.last_down_ts, 'America/Denver')
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_since_last_down_switch
  FROM budget b, ltd
)
SELECT
  budget.n_up_or_lateral_30d,
  cooldown.trading_days_since_last_down_switch                                     AS days_since_last_down_switch,
  -- outside_cooldown: TRUE at >=5 trading days since the last de-risk switch, OR when no de-risk has
  -- ever occurred within the allocator epoch — NULL-safe ("never de-risked" reads TRUE, not UNKNOWN).
  (cooldown.trading_days_since_last_down_switch >= 5
   OR cooldown.trading_days_since_last_down_switch IS NULL)                        AS outside_cooldown,
  budget.last_switch_ts
FROM budget
CROSS JOIN cooldown;

-- ============================================================================
-- 5. state.park_rule_shadow — v1's deterministic regime->vehicle rule table, RECORD-ONLY, kept
-- solely as counterfactual benchmark #3 the AI's judgment is measured against (owner-rejected as
-- decision-maker 2026-07-18; PARK_ROUTER_DESIGN.md §1/§9/§11 — "if AI judgment can't beat a lookup
-- table, the owner should know"). This view never trades and nothing in the live decision path
-- reads it. First-match-wins CASE, exactly the v1 rule table from the task spec; rule_regime and
-- rule_vehicle walk the SAME branch order so they always agree on which tier fired.
-- "No data, no claim": if any of the seven core signals the rule table consults is NULL for a
-- mark_date, BOTH rule_regime and rule_vehicle are NULL for that date rather than silently falling
-- through to a lower (wrong) tier or defaulting to RISK_ON/VOO — SQL's CASE/OR NULL-propagation
-- would otherwise treat "unknown" the same as "condition false" and could misclassify a
-- data-outage day as RISK_ON. inflation_trend is consulted only inside the RISK_OFF sub-branch and
-- is NOT part of the has_signals gate: IF(inflation_trend IN (...), 'IEF', 'SGOV') already resolves
-- an unknown inflation_trend to the safer vehicle (SGOV) rather than blanking the whole row, which
-- is consistent with the rule table's own de-risk-safe posture.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_rule_shadow` AS
WITH sig AS (
  SELECT
    mark_date,
    shock_overlay, vix_close, vix_med3, dd_from_252d_high,
    spy_trend, spy_close, spy_200dma, inflation_trend
  FROM `stock-trading-498512.state.park_signal_daily`
),
classified AS (
  SELECT
    *,
    (shock_overlay IS NOT NULL AND vix_close IS NOT NULL AND vix_med3 IS NOT NULL
     AND dd_from_252d_high IS NOT NULL AND spy_trend IS NOT NULL
     AND spy_close IS NOT NULL AND spy_200dma IS NOT NULL) AS has_signals
  FROM sig
)
SELECT
  mark_date,
  CASE
    WHEN NOT has_signals THEN NULL
    WHEN shock_overlay = 'acute' OR vix_close >= 30 OR dd_from_252d_high <= -0.15 THEN 'CRISIS'
    WHEN vix_med3 >= 25 OR dd_from_252d_high <= -0.10 OR spy_trend = 'DOWN'        THEN 'RISK_OFF'
    WHEN vix_med3 >= 20 OR dd_from_252d_high <= -0.05 OR spy_close < spy_200dma    THEN 'CAUTION'
    ELSE 'RISK_ON'
  END AS rule_regime,
  CASE
    WHEN NOT has_signals THEN NULL
    WHEN shock_overlay = 'acute' OR vix_close >= 30 OR dd_from_252d_high <= -0.15 THEN 'SGOV'
    WHEN vix_med3 >= 25 OR dd_from_252d_high <= -0.10 OR spy_trend = 'DOWN'
      THEN IF(inflation_trend IN ('disinflationary', 'stable'), 'IEF', 'SGOV')
    WHEN vix_med3 >= 20 OR dd_from_252d_high <= -0.05 OR spy_close < spy_200dma    THEN 'AOR'
    ELSE 'VOO'
  END AS rule_vehicle,
  shock_overlay, vix_close, vix_med3, dd_from_252d_high,
  spy_trend, spy_close, spy_200dma, inflation_trend
FROM classified;

-- ============================================================================
-- 6. state.park_allocator_promotion_readiness — Phase-1 shadow -> active_auto mechanical
-- promotion gate (PARK_ROUTER_DESIGN.md §10): ready when >=10 distinct call-days exist AND every
-- trading day since the first call has one (0 gaps). Zero-row-safe: `calls`/`agg`/`missing` are
-- all scalar aggregations (no GROUP BY), so this view always returns exactly one row, with
-- n_call_days=0 and ready=FALSE when no park-allocation call has ever been logged (first_call_date
-- NULL in that case; NULL BETWEEN ... is UNKNOWN, so the `missing` CTE's COUNT(*) still safely
-- yields 0 over zero matched calendar rows rather than propagating NULL or vanishing).
-- DROPPED by bigquery/108_park_allocator_immediate_binding.sql (2026-07-26 — immediate-binding
-- redesign, owner directive). DEFECT ON RECORD: this gate required n_missing_trading_days = 0
-- over the ENTIRE window since first_call_date with no recovery/rolling mechanism — the
-- 2026-07-23/24 platform-trigger outage left 2 permanently-missing call days (verified live
-- 2026-07-26: n_call_days=5, n_missing_trading_days=2, ready=false), so ready could NEVER become
-- TRUE; the owner directive supersedes fixing it, the gate is removed rather than repaired. Kept
-- here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-create live — 108
-- drops it.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_allocator_promotion_readiness` AS
WITH calls AS (
  SELECT entry_date
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'park-allocation'
),
agg AS (
  SELECT MIN(entry_date) AS first_call_date, COUNT(DISTINCT entry_date) AS n_call_days
  FROM calls
),
bound AS (
  SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`
),
missing AS (
  SELECT COUNT(*) AS n_missing_trading_days
  FROM `stock-trading-498512.state.market_calendar` mc
  CROSS JOIN agg
  CROSS JOIN bound
  WHERE mc.is_trading_day
    AND mc.cal_date BETWEEN agg.first_call_date AND bound.last_trading_day
    AND mc.cal_date NOT IN (SELECT entry_date FROM calls)
)
SELECT
  agg.first_call_date,
  agg.n_call_days,
  missing.n_missing_trading_days,
  (agg.n_call_days >= 10 AND missing.n_missing_trading_days = 0) AS ready
FROM agg
CROSS JOIN missing;

-- ============================================================================
-- 7. state.park_position_current / state.park_reconciliation — SUPERSEDES the bigquery/54
-- definitions (superseded-markers added there in this commit, pointing here). Generalizes 54's
-- single-vehicle assumption for the multi-instrument menu (PARK_ROUTER_DESIGN.md §5: a switch
-- can leave the outgoing and incoming vehicle both held above-dust at once; as of the 2026-07-26
-- paired-rotation redesign D2 crafts BOTH legs in one session so this window is normally a single
-- open rather than the 1-2 sessions this comment originally described, but the residual-row union
-- below is unchanged and still required either way) WHILE PRESERVING every output column name/shape 54 established
-- (state.park_reconciliation feeds Operating_Protocols.md §13's tripwire prose and the weekly
-- report — this migration only ADDS is_policy_vehicle, never removes/renames a column).
--
-- park_position_current: one row per ticker with ABS(events_shares) > 0.0005 (dust floor) — EXCEPT
-- the current state.park_policy_current.vehicle row, which is ALWAYS present even at zero/dust
-- shares. That exception preserves 54's own bug-fix semantics verbatim (its "BUG FIX 2026-07-15"
-- comment: an INNER JOIN silently produced ZERO rows during the cutover gap before the first
-- parking_events leg landed; the fix drives FROM park_policy_current and LEFT JOINs OUT to
-- park_position so the vehicle-of-record is never silently absent). Any OTHER ticker holding
-- above-dust shares (a switch-in-progress leg not yet fully sold) is unioned in as a residual row
-- with is_policy_vehicle=FALSE.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_position_current` AS
WITH cur AS (SELECT vehicle FROM `stock-trading-498512.state.park_policy_current`),
policy_row AS (
  SELECT
    cur.vehicle                                 AS ticker,
    COALESCE(pp.events_shares, 0)                AS events_shares,
    COALESCE(pp.buy_shares, 0)                   AS buy_shares,
    COALESCE(pp.sell_shares, 0)                  AS sell_shares,
    COALESCE(pp.drip_shares, 0)                  AS drip_shares,
    COALESCE(pp.events_park_net_cash, 0)         AS events_park_net_cash,
    COALESCE(pp.parking_commissions_total, 0)    AS parking_commissions_total,
    COALESCE(pp.parking_event_count, 0)          AS parking_event_count,
    pp.last_parking_date                         AS last_parking_date,
    TRUE                                          AS is_policy_vehicle
  FROM cur
  LEFT JOIN `stock-trading-498512.state.park_position` pp ON pp.ticker = cur.vehicle
),
residual_rows AS (
  SELECT
    pp.ticker,
    pp.events_shares, pp.buy_shares, pp.sell_shares, pp.drip_shares,
    pp.events_park_net_cash, pp.parking_commissions_total, pp.parking_event_count, pp.last_parking_date,
    FALSE AS is_policy_vehicle
  FROM `stock-trading-498512.state.park_position` pp
  CROSS JOIN cur
  WHERE pp.ticker != cur.vehicle
    AND ABS(pp.events_shares) > 0.0005
)
SELECT * FROM policy_row
UNION ALL
SELECT * FROM residual_rows;

-- park_reconciliation: one row per state.park_position_current ticker, each marked against
-- COALESCE(daily_marks_curated, signal_marks_curated) — prefer daily_marks_curated (VOO/SGOV's
-- existing D2a-ingested history), fall back to signal_marks_curated (bigquery/91's menu-wide
-- ingest) for a menu ticker that has never traded as a strategy position or park vehicle before
-- (e.g. GOVT/IEF/TLT/LQD/MUB/HYG/PFF/AOR/VTI on first onboarding). Same LEFT-JOIN-driven-FROM-p
-- zero-row-gap-safe shape as 54's fix — every state.park_position_current row gets exactly one
-- output row here regardless of whether either marks source has data for it yet.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_reconciliation` AS
WITH p AS (SELECT * FROM `stock-trading-498512.state.park_position_current`),
dm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
sm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
mark AS (
  SELECT
    p.ticker,
    COALESCE(dm.park_close, sm.park_close)         AS park_close,
    COALESCE(dm.park_mark_date, sm.park_mark_date) AS park_mark_date
  FROM p
  LEFT JOIN dm ON dm.ticker = p.ticker
  LEFT JOIN sm ON sm.ticker = p.ticker
)
SELECT
  p.ticker                    AS park_ticker,
  p.events_shares              AS events_park_shares,
  p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash,
  p.parking_commissions_total,
  mark.park_close,
  mark.park_mark_date,
  -- COALESCE to 0 (2026-07-19 fix): the CASH policy vehicle has no price series in either marks
  -- source (mark.park_close is NULL for ticker='CASH'), so 0 shares * NULL close would otherwise
  -- surface as NULL, not 0, on a CASH-parked day. A CASH-parked day correctly shows $0 instrument
  -- value here — the real cash lives in state.account_latest.total_cash, not this column.
  ROUND(p.events_shares * COALESCE(mark.park_close, 0), 2) AS events_park_market_value,
  COALESCE(mark.park_mark_date >= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`),
           FALSE)                                   AS park_mark_fresh,
  p.is_policy_vehicle,
  CURRENT_TIMESTAMP()                                AS checked_at
FROM p
LEFT JOIN mark ON mark.ticker = p.ticker;

-- ============================================================================
-- 8. state.mark_discontinuity_watch — SUPERSEDES bigquery/82's definition (superseded-marker added
-- there in this commit, pointing here). IDENTICAL LOGIC to 82 (same >25% day-over-day threshold,
-- same split_ratio=1 / same-day-dividend exclusions) — the only change is the explicit benchmark
-- UNION DISTINCT list, extended from SGOV/VOO/SPY to the full 12-ticker park menu (+ SPY).
--
-- FIX (2026-07-19 adversarial review — resolves the OPEN FLAG this file previously recorded at this
-- exact spot): per-ticker closes now come from COALESCE(state.daily_marks_curated,
-- state.signal_marks_curated), preferring daily_marks_curated on a both-present (ticker, mark_date)
-- day — same src_priority pick idiom as item 7's park_reconciliation above and bigquery/93's
-- park_nav_daily combined_marks CTE, generalized here to a full per-ticker date series (not just the
-- latest close) since the day-over-day LAG needs the whole history. Previously this view queried
-- state.daily_marks_curated ONLY, so the 9 menu tickers whose closes land exclusively in
-- state.signal_marks_curated (bigquery/91 — GOVT/IEF/TLT/LQD/MUB/HYG/PFF/AOR/VTI, until one is
-- separately held as a live strategy position) produced zero watched rows here — inert, not
-- incorrect, but a real tripwire blind spot across 9 of the menu's 12 tickers.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.mark_discontinuity_watch` AS
WITH watched AS (
  SELECT DISTINCT ticker FROM `stock-trading-498512.state.current_positions` WHERE ticker IS NOT NULL
  UNION DISTINCT SELECT 'SGOV' UNION DISTINCT SELECT 'VOO'  UNION DISTINCT SELECT 'SPY'
  UNION DISTINCT SELECT 'GOVT' UNION DISTINCT SELECT 'IEF'  UNION DISTINCT SELECT 'TLT'
  UNION DISTINCT SELECT 'LQD'  UNION DISTINCT SELECT 'MUB'  UNION DISTINCT SELECT 'HYG'
  UNION DISTINCT SELECT 'PFF'  UNION DISTINCT SELECT 'AOR'  UNION DISTINCT SELECT 'VTI'
),
combined_marks AS (
  SELECT ticker, mark_date, close, dividend, split_ratio, 1 AS src_priority
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker IN (SELECT ticker FROM watched)
  UNION ALL
  SELECT ticker, mark_date, close, dividend, split_ratio, 2 AS src_priority
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker IN (SELECT ticker FROM watched)
),
marks AS (
  SELECT ticker, mark_date, close, dividend, split_ratio
  FROM combined_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY src_priority) = 1
),
seq AS (
  SELECT ticker, mark_date, close,
         COALESCE(dividend, 0) AS dividend,
         COALESCE(NULLIF(split_ratio, 0), 1) AS split_ratio,
         LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close
  FROM marks
)
SELECT
  ticker, mark_date, close, prev_close, split_ratio, dividend,
  SAFE_DIVIDE(close, prev_close) - 1 AS raw_move,
  (prev_close IS NOT NULL
   AND ABS(SAFE_DIVIDE(close, prev_close) - 1) > 0.25   -- >25% day-over-day jump
   AND split_ratio = 1                                  -- NOT a recorded split (the engine handles that)
   AND ABS(SAFE_DIVIDE(dividend, prev_close)) < 0.25     -- NOT explained by a same-day dividend
  ) AS is_discontinuity
FROM seq;

-- 144_decision_log_correction_consumers.sql (2026-08-06)
-- Project: stock-trading-498512. Close the events.decision_log superseded_by consumer gap that
-- bigquery/143's own header and scripts/check_superseded_by_discipline.py explicitly deferred.
-- Apply after 14_weekly_report.sql, 95_capital_allocator.sql, 96_research_screener.sql,
-- 105_routine_catchup_window.sql, 122_decision_correction_append_only.sql,
-- 123_drip_dust_campaign_exclusion.sql, 135_park_allocation_call_shape.sql, 143_*.sql.
--
-- ============================ WHY ================================================================
-- events.decision_log has carried the superseded_by correction convention since bigquery/122
-- (2026-08-01). NOTHING has ever enforced that its readers apply the anti-join, and bigquery/116 and
-- /118 both justified leaving it alone as "currently INERT either way -- superseded_by is populated on
-- 0 of 496 rows".
--
-- THAT IS NO LONGER TRUE. MEASURED 2026-08-06: THREE corrections exist and all three obsolete targets
-- are still in the table.
--   1. 38ff17a6 supersedes ba8a060c -- entry_type='thesis-construction', strategy B, MDT, a GO
--      (LONG 0.481 shares). A duplicated GO thesis corrupts outcome/attribution analytics.
--   2. 70d2da0d supersedes ef3cfdcf -- entry_type='arsenal-heartbeat' (SL1, bigquery/133).
--   3. 62ffe982 supersedes 789de922 -- entry_type='arsenal-heartbeat' (SL1, bigquery/133).
--
-- A full consumer audit (2026-08-06) found NOTHING is visibly double-counting TODAY -- but every
-- "clean today" is an ACCIDENT of an orthogonal predicate, not a filter:
--   * analytics.thesis_outcomes excludes obsolete ba8a060c only because that row was logged
--     entry_type='other' pre-correction, so it never entered the `WHERE entry_type IN
--     ('thesis-construction','thesis')` filter. The correction happened to be an entry-type-fix.
--     BOTH live arsenal-heartbeat corrections PRESERVED entry_type -- that is the NORMAL shape, and
--     the next entry-type-preserving correction to a thesis row WILL silently double a GO.
--   * analytics.weekly_activity/weekly_nogos are clean only because the MDT correction is 60+ days
--     outside their trailing 7-day window and the heartbeat corrections are decision='REJECT'.
-- Do not read "no double-count today" as "correctly filtered". This file makes it correct by design.
--
-- ============================ THE CRITICAL FIND: AN INVERTED PREDICATE, LIVE ====================
-- state.go_without_order -- canonical in bigquery/105_routine_catchup_window.sql:215 -- carries
--     AND superseded_by IS NULL
-- which is EXACTLY BACKWARDS. The correction row is the one whose superseded_by is populated, so this
-- predicate KEEPS the obsolete row and DROPS the correction -- the precise inversion
-- bigquery/122:43 warns against in terms ("Do NOT filter entry_id WHERE superseded_by IS NOT NULL:
-- that is the correction row itself"). It was copied byte-for-byte from bigquery/18:223 into 105
-- during the 2026-07-25 catch-up-window redefinition and never re-examined.
-- MEASURED: the view returns 0 rows today, so no live harm yet -- purely because no GO decision has
-- been corrected inside its 2-to-9-day window. D3's MISSED-ENTRY check reads it; the first in-window
-- GO correction would have shown D3 the stale decision and hidden the real one.
-- bigquery/116:571 carries the same inverted form but is fully superseded by /122 (DR history only,
-- verified) -- 105 was the live instance.
--
-- ============================ WHAT IS *NOT* FILTERED, AND WHY THAT IS CORRECT ===================
-- decision_log's consumer population is genuinely HETEROGENEOUS -- unlike events.adversarial_reviews,
-- where every reader wanted final-effective rows. These MUST keep reading the RAW table, and
-- scripts/check_superseded_by_discipline.py allowlists each with this reason:
--   * state.freshness -- dead-man's switch. A correction append IS proof the table was written; a
--     filtered read would report STALE on a day whose only write was a correction.
--   * state.embedding_health / state.embedding_scale_watch -- 1:1 row-count parity and capacity
--     against analytics.decision_embeddings. They need the TRUE physical row count.
--   * analytics.decision_embeddings / ops.sp_embed_pending -- the raw substrate VECTOR_SEARCH scans.
--     The anti-join correctly lives one layer up, INSIDE analytics.find_precedents' candidate pool
--     (bigquery/122). Filtering the substrate would also desync embedding_health's parity check.
--   * ops.sp_log_decision -- writer, not a reader.
-- ops.sp_restore_drill also reads raw (row-count restore fidelity) and is equally correct to do so,
-- but it is NOT in that allowlist and does not need to be: it reaches every events.* table through
-- EXECUTE IMMEDIATE FORMAT(...) dynamic SQL (bigquery/17:90), which the checker's static text scan
-- cannot see at all. That is a real blind spot in the checker, recorded in its own docstring -- not an
-- exemption it granted.
-- Forcing those onto the filtered view would break a dead-man's switch and a parity check. That is
-- why this file does NOT adopt bigquery/143's blanket "every canonical reader must use the _current
-- view" rule for decision_log -- the checker uses an allowlist instead.

-- ============================================================================
-- (1) state.decision_log_current -- THE canonical final-effective row set, mirroring
-- state.adversarial_reviews_current (bigquery/143). Direction per bigquery/122: the CORRECTION row
-- names the OBSOLETE row, so readers exclude the row that is NAMED. `WHERE superseded_by IS NULL` is
-- the WRONG predicate. NOT IN is safe: the subquery filters superseded_by IS NOT NULL, so it can
-- never yield a NULL.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.decision_log_current` AS
SELECT *
FROM `stock-trading-498512.events.decision_log`
WHERE entry_id NOT IN (
  SELECT superseded_by
  FROM `stock-trading-498512.events.decision_log`
  WHERE superseded_by IS NOT NULL
);

-- ============================================================================
-- (2) state.go_without_order -- SUPERSEDES bigquery/105_routine_catchup_window.sql.
-- THE INVERTED-PREDICATE FIX. Byte-identical to 105's definition except the go_decisions CTE now
-- reads state.decision_log_current instead of events.decision_log, and the backwards
-- `AND superseded_by IS NULL` line is DELETED (the view supplies the correct exclusion). The
-- D3-anchored widening window, the GREATEST(2, ...) floor, and both Denver-anchored NOT EXISTS
-- guards are unchanged.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.go_without_order` AS
WITH d3_last_completed AS (
  -- D3's own last completed ops.run_log run -- the anchor for how far back this view's evidence window
  -- needs to reach.
  SELECT MAX(log_ts) AS d3_last_completed_ts
  FROM `stock-trading-498512.ops.run_log`
  WHERE routine = 'D3' AND status = 'completed'
),
go_decisions AS (
  SELECT entry_id, entry_date, strategy, ticker, entry_type, title
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE decision = 'GO'
    AND entry_date >= DATE_SUB(
      CURRENT_DATE('America/Denver'),
      -- FLOORED at the original fixed 2-day (~36h) lookback (GREATEST semantics): never narrower than
      -- bigquery/18's original definition, but widens to D3's own last-completion gap when that is
      -- bigger -- see the file-level comment above this CREATE statement.
      INTERVAL (
        SELECT GREATEST(
          2,
          COALESCE(
            DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(d3_last_completed_ts, 'America/Denver'), DAY),
            2
          )
        )
        FROM d3_last_completed
      ) DAY
    )
)
SELECT
  g.entry_id, g.entry_date, g.strategy, g.ticker, g.entry_type, g.title,
  CURRENT_TIMESTAMP() AS checked_at
FROM go_decisions g
-- no staged order references this decision (by ref, else by ticker+strategy on/after the decision day).
-- DATE(..., 'America/Denver') — NOT the bare (UTC-default) form — because g.entry_date is the
-- Denver OPERATING day decision_log stamps; a bare UTC date is always >= the Denver date, so an
-- order/fill actually staged the PRIOR Denver evening (>=~17:00 MT = already the next UTC day) could
-- wrongly satisfy this match and suppress a genuine go-without-order candidate (false negative only;
-- 2026-07 report-system fix).
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.queue_events` q
  WHERE q.queue = 'ORDER_STAGED'
    AND (JSON_VALUE(q.payload, '$.source_decision_ref') = g.entry_id
         OR (q.ticker = g.ticker AND q.strategy = g.strategy AND DATE(q.event_ts, 'America/Denver') >= g.entry_date))
)
-- and no fill recorded for that strategy/ticker on/after the decision day
AND NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.trade_fills` f
  WHERE f.ticker = g.ticker AND f.strategy = g.strategy
    AND DATE(f.fill_ts, 'America/Denver') >= g.entry_date
);

-- ============================================================================
-- (3) analytics.thesis_outcomes -- SUPERSEDES bigquery/123_drip_dust_campaign_exclusion.sql.
-- THE ROOT SOURCE. Only change: the `theses` CTE reads state.decision_log_current. The exclusion MUST
-- live inside that CTE -- upstream of the position_campaigns LEFT JOIN and the final QUALIFY -- so an
-- obsolete row can never enter the campaign pairing at all (the bigquery/116 placement trap).
-- Fixing it here also fixes analytics.declared_vs_realized (bigquery/136), which aggregates this view
-- and needs NO edit of its own -- that view's header already establishes thesis_outcomes as its
-- single source for GO theses. Downstream reach: analytics.conviction_features,
-- calibration_summary/calibration_shrunk, thesis_outcome_summary, find_precedents' outcome
-- annotation, analytics.process_scorecard, and W5's process_scorecard_signal alert.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcomes` AS
WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, conviction_pct, sub_pattern, decision, title,
    -- GO-FAMILY TEST, used both to guard the campaign join and (by consumers) to filter to GO.
    -- Anchored ^GO\b: matches 'GO' and 'GO (add tranche)'; does NOT match 'NO-GO',
    -- 'NO-GO / DO-NOT-STAGE', 'NO-GO (no add; existing position runs)' (anchored, so a leading 'NO-'
    -- can never match) nor a hypothetical 'GOOD' (\b requires a non-word char after 'GO').
    -- VERIFIED live against all 164 NO-GO-flavored rows: zero false matches.
    REGEXP_CONTAINS(UPPER(TRIM(COALESCE(decision, ''))), r'^GO\b') AS is_go_family,
    -- Scale-normalized conviction probability. SEVEN historical rows stored a 0-1 fraction where the
    -- other 70 stored 0-100 percent (bigquery/116 header (6)); 0 is left alone (0 is 0 on either scale).
    IF(conviction_pct > 0 AND conviction_pct <= 1, conviction_pct * 100, conviction_pct) AS conviction_pct_normalized
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type IN ('thesis-construction', 'thesis')
),
regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope='FUNDAMENTAL_AXIS' AND key='_integrative'
),
thesis_regime AS (
  SELECT t.entry_id, ra.regime_state
  FROM theses t
  LEFT JOIN regime_axis ra ON ra.as_of_date <= t.entry_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY t.entry_id ORDER BY ra.as_of_date DESC) = 1
)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  tr.regime_state,
  pc.exit_date IS NOT NULL AS position_closed,
  IF(pc.exit_date IS NOT NULL, pc.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pc.exit_date IS NULL THEN NULL          -- position still open -> outcome unknown (not a loss)
       WHEN pc.realized_pnl IS NULL THEN NULL
       ELSE pc.realized_pnl > 0 END AS was_profitable,
  t.title,
  t.is_go_family,
  t.conviction_pct,
  t.conviction_pct_normalized,
  pc.campaign_key,
  -- TRUE when this thesis was paired to its campaign by the durable FK rather than by date proximity.
  -- A pairing-quality telemetry column: lets W5/self-improvement see how much of the corpus still
  -- rests on the heuristic without re-deriving it.
  (pc.opening_thesis_ref IS NOT NULL AND pc.opening_thesis_ref = t.entry_id) AS paired_by_fk
FROM theses t
LEFT JOIN thesis_regime tr ON tr.entry_id = t.entry_id
LEFT JOIN `stock-trading-498512.analytics.position_campaigns` pc
  ON pc.strategy = t.strategy AND pc.ticker = t.ticker
  -- GUARD (bigquery/116 header (3)): only a GO-family thesis may be paired to a position at all.
  AND t.is_go_family
  -- NEW 2026-08-02: a post-close DRIP-dust phantom is never a thesis's outcome. Without this, a GO
  -- thesis dated nearer its dust campaign than its real one mis-pairs by the nearest-date fallback.
  AND NOT COALESCE(pc.is_dust, FALSE)
-- Pair each thesis to ITS campaign. FK first: a campaign whose OPENING fill records this exact
-- entry_id wins outright. Otherwise the original heuristic -- a re-traded ticker has >1 campaign, so
-- pick the one whose entry_date is nearest the thesis date (an add's own thesis-construction entry
-- legitimately maps to the same campaign as the position's original entry).
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY t.entry_id
  ORDER BY
    IF(pc.opening_thesis_ref IS NOT NULL AND pc.opening_thesis_ref = t.entry_id, 0, 1),
    ABS(DATE_DIFF(pc.entry_date, t.entry_date, DAY)) NULLS LAST
) = 1;

-- ============================================================================
-- (4) analytics.dust_classified_fills -- SUPERSEDES bigquery/123_drip_dust_campaign_exclusion.sql.
-- Only change: the `decisions` CTE reads state.decision_log_current, upstream of the
-- priority/dust_id QUALIFY tie-break, which has no defined preference for a correction row.
-- Dormant today (no drip-dust classification has been corrected) -- structural hardening.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.dust_classified_fills` AS
WITH decisions AS (
  SELECT entry_id, entry_date, ticker, fields
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'drip-dust'
),
exact_classifications AS (
  SELECT JSON_VALUE(fields, '$.source_trade_id') AS trade_id,
    COALESCE(JSON_VALUE(fields, '$.dust_id'),
      CONCAT('source:', JSON_VALUE(fields, '$.source_trade_id'))) AS dust_id,
    'source-buy' AS fill_role,
    1 AS priority
  FROM decisions
  WHERE JSON_VALUE(fields, '$.record_type') = 'classification'
    AND JSON_VALUE(fields, '$.classification') = 'dust'
    AND JSON_VALUE(fields, '$.source_trade_id') IS NOT NULL
),
legacy_candidates AS (
  SELECT d.entry_id, f.trade_id
  FROM decisions d
  JOIN `stock-trading-498512.state.trade_fills_curated` f
    ON d.ticker = f.ticker
   AND SAFE_CAST(JSON_VALUE(d.fields, '$.fill_date') AS DATE)
       = DATE(f.fill_ts, 'America/New_York')
   AND SAFE_CAST(JSON_VALUE(d.fields, '$.shares') AS NUMERIC) = f.shares
  WHERE JSON_VALUE(d.fields, '$.record_type') IS NULL
    AND JSON_VALUE(d.fields, '$.classification') IS NULL
    AND JSON_VALUE(d.fields, '$.disposition') IS NULL
    AND f.side = 'BUY'
    AND f.strategy = 'B'
    AND (
      (d.ticker = 'IBM' AND DATE(f.fill_ts, 'America/New_York') = DATE '2026-06-11'
        AND f.shares = NUMERIC '0.0007' AND f.price = NUMERIC '271.41')
      OR
      (d.ticker = 'HCA' AND DATE(f.fill_ts, 'America/New_York') = DATE '2026-07-01'
        AND f.shares = NUMERIC '0.0001' AND f.price = NUMERIC '389.77')
    )
),
legacy_classifications AS (
  SELECT trade_id, CONCAT('legacy:', entry_id) AS dust_id,
    'source-buy' AS fill_role, 3 AS priority
  FROM legacy_candidates
  QUALIFY COUNT(*) OVER (PARTITION BY entry_id) = 1
),
liquidation_classifications AS (
  SELECT JSON_VALUE(sell_id) AS trade_id,
    JSON_VALUE(fields, '$.dust_id') AS dust_id,
    'liquidation-sell' AS fill_role,
    2 AS priority
  FROM decisions, UNNEST(JSON_QUERY_ARRAY(fields, '$.liquidation_trade_ids')) sell_id
  WHERE (JSON_VALUE(fields, '$.disposition') = 'filled'
      OR JSON_VALUE(fields, '$.record_type') = 'liquidation-fill')
    AND JSON_VALUE(fields, '$.dust_id') IS NOT NULL
  UNION ALL
  SELECT JSON_VALUE(fields, '$.liquidation_trade_id') AS trade_id,
    JSON_VALUE(fields, '$.dust_id') AS dust_id,
    'liquidation-sell' AS fill_role,
    2 AS priority
  FROM decisions
  WHERE (JSON_VALUE(fields, '$.disposition') = 'filled'
      OR JSON_VALUE(fields, '$.record_type') = 'liquidation-fill')
    AND JSON_VALUE(fields, '$.dust_id') IS NOT NULL
    AND JSON_VALUE(fields, '$.liquidation_trade_id') IS NOT NULL
)
SELECT trade_id, TRUE AS is_dust, dust_id, fill_role
FROM (
  SELECT * FROM exact_classifications
  UNION ALL
  SELECT * FROM liquidation_classifications
  UNION ALL
  SELECT * FROM legacy_classifications
)
WHERE trade_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY priority, dust_id) = 1;

-- ============================================================================
-- (5) state.capital_allocation_calls -- SUPERSEDES bigquery/95_capital_allocator.sql.
-- Only change: the `calls` CTE reads state.decision_log_current. W5's CAPITAL-ALLOCATION SCORECARD
-- reads deviation_pct off this view; a superseded call row would be scored twice.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_allocation_calls` AS
WITH calls AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                        AS rationale,
    JSON_VALUE(fields, '$.trigger')                                AS trigger,
    JSON_VALUE(fields, '$.conviction')                             AS conviction,
    SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)   AS conviction_pct,
    SAFE_CAST(JSON_VALUE(fields, '$.is_default_equal') AS BOOL)    AS is_default_equal,
    JSON_VALUE(fields, '$.winner_code')                            AS winner_code,
    JSON_VALUE(fields, '$.runner_up_code')                         AS runner_up_code,
    SAFE_CAST(JSON_VALUE(fields, '$.total_dollars') AS NUMERIC)    AS total_dollars,
    JSON_VALUE(fields, '$.invalidation')                           AS invalidation,
    JSON_VALUE(fields, '$.theater_check')                          AS theater_check,
    JSON_QUERY_ARRAY(fields, '$.allocations')                      AS allocations
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'capital-allocation'
)
-- One row per {call, survivor}. W5's CAPITAL-ALLOCATION SCORECARD bullet (Claude_Task_Plan.md) reads
-- `deviation_pct` — the call's own equal-split counterfactual, computed from THIS call's own
-- allocations-array length (the active-survivor count AS OF that historical call), never a live join
-- back to state.strategy_roster's CURRENT membership, which could differ from what this call actually
-- saw (a later termination/adoption must never revise an earlier call's counterfactual — the same
-- as-of-the-flow's-own-date discipline bigquery/22_cash_flows.sql's analytics.strategy_nav uses for
-- historical equal-split divisors).
SELECT
  entry_id,
  entry_date,
  event_ts,
  trigger,
  conviction,
  conviction_pct,
  is_default_equal,
  winner_code,
  runner_up_code,
  total_dollars,
  invalidation,
  theater_check,
  rationale,
  JSON_VALUE(alloc, '$.strategy_code')                                                  AS strategy_code,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC)                                        AS pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.dollars') AS NUMERIC)                                    AS dollars,
  100.0 / ARRAY_LENGTH(allocations)                                                       AS equal_share_pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC) - (100.0 / ARRAY_LENGTH(allocations))  AS deviation_pct
FROM calls, UNNEST(allocations) AS alloc;

-- ============================================================================
-- (6) analytics.research_screen_disagreements -- SUPERSEDES bigquery/96_research_screener.sql.
-- Only change: the LEFT JOIN's decision_log side reads state.decision_log_current. It MUST be the
-- join source (not an outer WHERE): the QUALIFY below picks the EARLIEST later thesis per flagged
-- item, so an obsolete row reaching the join could win that ORDER BY and be reported as the
-- "next look" verdict. Its `flagged` CTE reads state.research_screen_calls, which bigquery/122
-- already filters correctly.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.research_screen_disagreements` AS
WITH flagged AS (
  SELECT
    *,
    CASE
      WHEN side = 'rejected_notable' AND legacy_rule_pass       THEN 'rule_only'
      WHEN side = 'passed'           AND NOT legacy_rule_pass   THEN 'ai_only'
    END AS disagreement_class
  FROM `stock-trading-498512.state.research_screen_calls`
  WHERE (side = 'rejected_notable' AND legacy_rule_pass)
     OR (side = 'passed'           AND NOT legacy_rule_pass)
)
-- Pair (e.g. "AAPL/MSFT") and SECTOR names (e.g. "Technology") from M2 pair-divergence / D1 sector-move
-- items simply never match events.decision_log.ticker (populated for single-name thesis-construction
-- rows only) — expected NULLs on later_thesis_decision/later_thesis_date for those rows, not a join
-- bug. QUALIFY keeps at most the EARLIEST later thesis-construction row per flagged item (the "did the
-- very next look get it right" question, not every subsequent look) — when no later thesis row exists
-- at all, the LEFT JOIN still contributes exactly one (NULL-decision) row per flagged item, and
-- ROW_NUMBER() still assigns it 1, so no flagged item is ever dropped by this JOIN.
SELECT
  f.entry_id, f.entry_date, f.event_ts, f.routine, f.screen, f.population_rail, f.surfaced_count,
  f.legacy_rule, f.agreement_both, f.agreement_ai_only, f.agreement_rule_only, f.rationale,
  f.side, f.name, f.metric_pct, f.conviction, f.conviction_pct, f.reason, f.below_spec_floor,
  f.legacy_rule_pass, f.disagreement_class,
  t.decision   AS later_thesis_decision,
  t.entry_date AS later_thesis_date
FROM flagged f
LEFT JOIN `stock-trading-498512.state.decision_log_current` t
  ON t.ticker = f.name
 AND t.entry_type = 'thesis-construction'
 AND t.entry_date > f.entry_date
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY f.entry_id, f.side, f.name
  ORDER BY t.entry_date ASC
) = 1;

-- ============================================================================
-- (7) state.park_allocation_recent -- SUPERSEDES bigquery/135_park_allocation_call_shape.sql.
-- Only change: reads state.decision_log_current. The exclusion MUST precede the LIMIT 25 -- an
-- obsolete row inside the top-25 window would both consume a slot and, via state.park_allocation_latest
-- (which reads THIS view and takes the newest is_call row), be able to shadow the standing park call.
-- That is the same shadowing failure alert c5044046 recorded on 2026-08-03.
-- state.park_allocation_latest needs NO edit -- it inherits this fix.
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
  JSON_VALUE(fields, '$.status')                                AS status,     -- 'PENDING' | 'BOUND' | 'RECORD_ONLY'
  -- CALL-SHAPE FLAG (2026-08-04, alert c5044046-53da-4d91-be8d-4002d1882ec0). Every real D1 park call -- KEEP,
  -- DE-RISK and SWITCH alike -- carries a status; a row without one is some other kind of park event (today:
  -- D2a's COVER/sweep staging note) that happens to share this entry_type. Consumers that need "the standing
  -- allocation call" must filter on this; state.park_allocation_latest below does.
  JSON_VALUE(fields, '$.status') IS NOT NULL                    AS is_call
FROM `stock-trading-498512.state.decision_log_current`
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 25;

-- ============================================================================
-- (8) analytics.weekly_activity / analytics.weekly_nogos -- SUPERSEDE bigquery/14_weekly_report.sql.
-- Digest counters. Only change: the decision_log subqueries read state.decision_log_current, so a
-- GO/NO-GO corrected inside its own trailing 7-day window is counted once, not twice. Display-only
-- today, but unguarded. The Denver-anchored date derivations are unchanged.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_activity` AS
SELECT
  -- DATE(fill_ts, 'America/Denver') — NOT bare DATE(fill_ts) (defaults to UTC): a fill timestamped
  -- after ~17-18:00 Denver lands on the next UTC calendar day, mis-aging it by one day against this
  -- Denver-anchored 7-day window (2026-07 report-system fix; the count is display-only but the two
  -- date derivations must agree).
  (SELECT COUNT(*) FROM `stock-trading-498512.state.trade_fills_curated`
     WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.decision_log_current`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.decision_log_current`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.open_queue`
     WHERE queue = 'ORDER_STAGED') AS pending_orders;

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_nogos` AS
SELECT ticker, strategy, entry_date
FROM `stock-trading-498512.state.decision_log_current`
WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
  AND UPPER(decision) = 'NO-GO' AND ticker IS NOT NULL
ORDER BY entry_date DESC LIMIT 8;

-- VERIFICATION (run after apply; all must hold -- this changeset is preventive, so every number
-- below must be UNCHANGED from its pre-apply value).
-- 1. The anti-join view sees the 3 obsolete rows and nothing else:
--    SELECT (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`)
--         - (SELECT COUNT(*) FROM `stock-trading-498512.state.decision_log_current`);
--    -> expect exactly 3.
-- 2. No obsolete row survives into the fixed views:
--    SELECT COUNT(*) FROM `stock-trading-498512.analytics.thesis_outcomes`
--    WHERE entry_id IN ('ba8a060c-db69-403a-8b58-39436452a856',
--                       'ef3cfdcf-8da8-43f8-83a1-3619a66aaf62',
--                       '789de922-da85-4451-bf9c-340c0a52ee57');
--    -> expect 0.
-- 3. Scorecard inputs did not move (they were accidentally clean before, correct by design now).
--    NOTE the column is `strategy`, NOT `strategy_code` -- an earlier draft of this block said
--    strategy_code and threw "Unrecognized name" instead of comparing anything, which is how a stated
--    success criterion goes unrun. Verified executable 2026-08-06:
--    SELECT strategy, go_theses, positions_opened, go_minus_opened, min_n_met
--    FROM `stock-trading-498512.analytics.declared_vs_realized` ORDER BY strategy;
--    -> expect B: 13/13/0/TRUE and D: 13/13/0/TRUE, unchanged.
-- 4. state.go_without_order still returns 0 rows, now for the RIGHT reason.

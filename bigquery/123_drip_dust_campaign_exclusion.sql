-- Post-close DRIP-dust campaign exclusion (2026-08-02).
-- Project: stock-trading-498512. Apply AFTER 116_decision_record_analyzability.sql.
--
-- SUPERSEDES bigquery/116_decision_record_analyzability.sql sections (A) analytics.position_campaigns
-- and (B) analytics.thesis_outcomes. This is the current single source of truth for both objects.
-- Keep 116 for DR-rebuild history; do not re-apply its definitions of these two views in isolation.
-- (Same supersede convention bigquery/122 used for find_precedents / research_screen_calls /
-- add_candidate_reviews.) 116 section (C) onward is untouched and remains canonical.
--
-- WHAT THIS FIXES. The 2026-07-20 post-close DRIP-dust convention (D2a Step 0, $1 materiality gate)
-- kept dividend-reinvestment dust out of state.current_positions, and succeeded there. But
-- analytics.position_campaigns was rebuilt the NEXT day (2026-07-21 FIFO/campaign rebuild) and derives
-- straight from events.trade_fills, so it re-introduced the same dust as campaigns that can never
-- close: B:IBM:2 (entry 2026-06-11, 0.0007 sh, ~$0.19) and B:HCA:2 (entry 2026-07-01, 0.0001 sh,
-- ~$0.04). Both have open_shares > 0 and exit_date NULL forever. The convention predates the campaign
-- layer and never considered it.
--
-- WHY IT MATTERS (latent, not active). analytics.thesis_outcomes pairs a thesis to a campaign FK-first,
-- else by NEAREST entry_date. Neither dust campaign carries a UUID FK, so both sit in the nearest-date
-- pool competing with the real campaigns. Verified live 2026-08-02: both GO theses currently pair
-- CORRECTLY (b445e684 -> B:IBM:1, bdede0f6 -> B:HCA:1) but with paired_by_fk = FALSE -- they won on
-- date distance alone (2d vs 47d; 1d vs 65d). A future GO thesis on either ticker dated nearer its dust
-- campaign than its real one would mis-pair to a sub-dollar phantom and report position_closed = FALSE
-- with NULL realized P&L, which then flows into analytics.find_precedents -- the precedent corpus.
-- Consumers keyed on CLOSED campaigns (closed_trades / gate_n in ops.sp_recompute_engine, the adaptive
-- shortfall budget in bigquery/103, assert_campaign_lifecycle_reconciliation) are unaffected either
-- way, because a dust campaign never closes.
--
-- THE GATE. Dust is an audited fill-level fact written by D2a after it inspects authoritative connector
-- state: exact source trade id, STK asset type, positive long quantity, no strategy mirror, not a park
-- holding, and current market value <= $1. The view does not reconstruct those facts from BUY arithmetic.
-- That shortcut misclassifies options, open shorts, nullable prices, and values crossing $1 after purchase.
-- New records key directly on source_trade_id; a fail-closed compatibility branch maps the original
-- 2026-07-20 rows only when one of the two frozen BUY-fill signatures resolves to exactly one trade_id.
--
-- WHY NOT A DRIP PREDICATE -- two rejected alternatives, both actively harmful:
--   1. Excluding DRIP fills globally would CORRUPT reconciliation. A DRIP fill landing on an OPEN
--      position is legitimately part of it: D:RTX:1 = 0.1595 + 0.0006 DRIP = 0.1601 and
--      D:DIS:1 = 0.28 + 0.0022 = 0.2822, both matching the IBKR connector exactly. Dropping those
--      fills would make open_shares disagree with the broker and break position reconciliation.
--   2. There is no dependable DRIP predicate in events.trade_fills anyway. The B:IBM:2 fill row carries
--      raw.exchange = 'IBDRIPUS'; the B:HCA:2 fill row has NO exchange key at all (it is prose inside
--      raw.note). order_id = '0' is set on both, but the connector reports real order ids
--      (5300084300 / 5374247223). The structural + materiality test needs neither.
--
-- ADDITIVE ONLY for position_campaigns: is_dust is appended LAST, so row count, grouping, and existing
-- column order are unchanged. The only behavioral change in THIS file is in thesis_outcomes, which
-- drops dust from its pairing pool. closed_trades / gate_n / calibration are left alone here and are
-- filtered in bigquery/124_dust_excluded_from_closed_trades.sql -- required before any dust residual
-- is liquidated, because a SOLD dust lot does reach exit_date IS NOT NULL.
--
-- Companion decision record: events.decision_log entry_id d154fcec-d434-4c4a-8f27-89b16be6e166
-- (2026-08-02 correction -- the B:IBM:2 provenance note also states a wrong exit date, uncorrectable
-- in place because events.trade_fills is append-only with no correction mechanism).
--
-- Parallel-run dbt ports updated in lockstep (scripts/dbt_parity.py compares live view output to the
-- dbt model DISTINCT both ways, so these MUST land together):
--   dbt/models/analytics/position_campaigns.sql, dbt/models/analytics/thesis_outcomes.sql

-- ============================================================================
-- (A) analytics.dust_classified_fills -- durable fill-level classification bridge.
-- ============================================================================
-- SUPERSEDED LIVE by bigquery/144_decision_log_correction_consumers.sql — current single source of truth
-- for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation: its `decisions` CTE reads events.decision_log directly, so a superseded correction target would
-- reach the priority/dust_id QUALIFY tie-break, which has no defined preference for the correction.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.dust_classified_fills` AS
WITH decisions AS (
  SELECT entry_id, entry_date, ticker, fields
  FROM `stock-trading-498512.events.decision_log`
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
-- (B) analytics.position_campaigns -- REBUILD. Byte-identical to bigquery/116 section (A) except the
-- appended is_dust column and its fill-level classification join.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_campaigns` AS
WITH fills AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.contract_id,
    DATE(fill_ts, 'America/New_York') AS fill_date, fill_ts,
    side, price, shares, commission, realized_pnl,
    -- Carried through solely to survive the GROUP BY below as opening_thesis_ref.
    source_thesis_ref,
    COALESCE(dcf.is_dust, FALSE) AS fill_is_dust,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM `stock-trading-498512.state.trade_fills_curated` f
  LEFT JOIN `stock-trading-498512.analytics.dust_classified_fills` dcf USING (trade_id)
  WHERE ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
running AS (
  SELECT *,
    SUM(signed_shares) OVER w AS running_shares,
    -- prev_running_shares = the running position BEFORE this fill; COALESCE to 0 for each
    -- (strategy,ticker)'s very first fill (empty preceding-window), same construct as Tier 1's
    -- cum_start.
    COALESCE(SUM(signed_shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prev_running_shares
  FROM fills
  WINDOW w AS (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
),
seqd AS (
  SELECT *,
    -- campaign_seq increments exactly at a 0->nonzero transition (a NEW campaign's opening fill) and
    -- otherwise holds -- every fill from that opening fill through the fill that returns the position
    -- to 0 (inclusive) shares the same campaign_seq.
    COUNTIF(prev_running_shares = 0 AND running_shares != 0) OVER (
      PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS campaign_seq
  FROM running
),
tagged AS (
  SELECT *,
    -- The opening fill's contract_id/price, taken once per campaign via a window function ordered
    -- the same way campaign_seq was computed -- constant across every row of the campaign, so
    -- ANY_VALUE() after GROUP BY below is safe (not an arbitrary pick).
    FIRST_VALUE(contract_id) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_contract_id,
    FIRST_VALUE(price) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_entry_price,
    -- The OPENING fill's source_thesis_ref -- the decision-log entry_id that authorized the
    -- campaign, when the write path recorded it as a UUID (the convention adopted ~2026-07-26; older
    -- rows hold free text like 'D2 2026-07-17 TSM D GO' and are left exactly as they are -- no
    -- backfill, no rewriting of history). thesis_outcomes treats a non-UUID value as "no FK" and
    -- falls back to nearest-date, so mixed population degrades gracefully rather than breaking.
    FIRST_VALUE(source_thesis_ref) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_opening_thesis_ref,
    -- The ENDING running_shares of the campaign (0 if closed, nonzero if still open) -- the running
    -- position at the campaign's LAST fill by fill order.
    LAST_VALUE(running_shares) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_open_shares,
    -- The price of the fill that brought running_shares back to 0 (the closing fill), if any --
    -- within one campaign_seq group this condition can be true for at most one row (the terminal
    -- fill; hitting 0 mid-campaign would itself start a NEW campaign_seq on the next nonzero fill).
    LAST_VALUE(IF(running_shares = 0, price, NULL) IGNORE NULLS) OVER (
      PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_exit_price
  FROM seqd
)
SELECT
  CONCAT(strategy, ':', ticker, ':', CAST(campaign_seq AS STRING)) AS campaign_key,
  strategy, ticker,
  ANY_VALUE(campaign_contract_id) AS contract_id,
  MIN(fill_date) AS entry_date,
  ANY_VALUE(campaign_entry_price) AS entry_price,
  MAX(IF(running_shares = 0, fill_date, NULL)) AS exit_date,
  ANY_VALUE(campaign_exit_price) AS exit_price,
  SUM(IF(side = 'SELL', realized_pnl, 0)) AS realized_pnl,
  SUM(IF(side = 'BUY', shares, 0)) AS total_shares_bought,
  SUM(IF(side = 'SELL', shares, 0)) AS total_shares_sold,
  ANY_VALUE(campaign_open_shares) AS open_shares,
  SUM(commission) AS total_commission,
  COUNTIF(side = 'BUY') AS n_buy_fills,
  COUNTIF(side = 'SELL') AS n_sell_fills,
  ANY_VALUE(campaign_opening_thesis_ref) AS opening_thesis_ref,
  -- NEW 2026-08-02 (appended last: column-order stable). Post-close DRIP-dust marker: a dividend
  -- reinvestment that lands after its position already closed opens a campaign with no strategy, no
  -- thesis, and no real economic entry. Same $1 materiality gate as the D2a Step 0 dust convention.
  -- NOT a DRIP predicate by design -- DRIP fills on an OPEN position are load-bearing for connector
  -- reconciliation and must keep flowing through untouched (see this file's header).
  --
  -- A dust-only campaign stays flagged after its liquidation SELL. If a legitimate unclassified BUY
  -- occurs before the dust is cleared, the running-share campaign has become a real mixed campaign and
  -- must not be suppressed wholesale; Tier-1 still excludes only the classified dust BUY lot from TWR.
  COUNTIF(side = 'BUY' AND fill_is_dust) > 0
    AND COUNTIF(side = 'BUY' AND NOT fill_is_dust) = 0 AS is_dust
FROM tagged
GROUP BY strategy, ticker, campaign_seq;


-- ============================================================================
-- (C) analytics.thesis_outcomes -- REBUILD. Byte-identical to bigquery/116 section (B) except the
-- added `AND NOT pc.is_dust` join predicate. Kept in the LEFT JOIN's ON clause (not a WHERE) so an
-- otherwise-unpaired thesis still yields its row with a NULL campaign, exactly as before.
-- is_dust is non-nullable by construction; on a non-match pc.is_dust is NULL and the LEFT JOIN
-- handles it correctly (thesis survives, unpaired).
-- ============================================================================
-- SUPERSEDED LIVE by bigquery/144_decision_log_correction_consumers.sql — current single source of truth
-- for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation: chain 04 -> 102 -> 116 -> 123 -> 144; 144 repoints the `theses` CTE at
-- state.decision_log_current so a superseded GO thesis cannot be paired to a campaign twice.
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
  FROM `stock-trading-498512.events.decision_log`
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


-- VERIFICATION (run after apply; all four must hold).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last CREATE causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Exactly the two known dust campaigns are flagged, nothing else:
--    SELECT campaign_key, is_dust FROM `stock-trading-498512.analytics.position_campaigns`
--    WHERE is_dust ORDER BY campaign_key;
--    -> expect exactly B:HCA:2 and B:IBM:2.
--
-- 2. Existing thesis pairings are UNCHANGED (this fix is preventive, not corrective):
--    SELECT entry_id, ticker, campaign_key, position_closed, realized_pnl
--    FROM `stock-trading-498512.analytics.thesis_outcomes` WHERE ticker IN ('IBM','HCA');
--    -> expect bdede0f6 -> B:HCA:1 (-3.097259), b445e684 -> B:IBM:1 (+1.951085),
--       90ee44da (NO-GO) -> NULL campaign.
--
-- 3. Closed-campaign counts are untouched (closed_trades / gate_n must not move):
--    SELECT COUNTIF(exit_date IS NOT NULL) AS n_closed, COUNT(*) AS n_total
--    FROM `stock-trading-498512.analytics.position_campaigns`;
--    -> expect n_closed unchanged at 8, n_total unchanged at 22.
--
-- 4. Every flagged campaign has an audited source-fill classification; historical BUY cost is
--    diagnostic only and is not the eligibility predicate:
--    SELECT pc.campaign_key, dcf.trade_id
--    FROM `stock-trading-498512.analytics.position_campaigns` pc
--    JOIN `stock-trading-498512.state.trade_fills_curated` f
--      ON f.strategy=pc.strategy AND f.ticker=pc.ticker
--    JOIN `stock-trading-498512.analytics.dust_classified_fills` dcf USING (trade_id)
--    WHERE pc.is_dust AND f.side='BUY';
--    -> expect at least one exact classified BUY fill for each flagged campaign.
--    NOTE: do NOT assert "no dust campaign is closed". Dust CAN legitimately become closed once the
--    residual is liquidated -- that is precisely why the flag is persisted, and why bigquery/124
--    filters NOT is_dust in closed_trades / gate_n / calibration rather than relying on dust never
--    reaching exit_date IS NOT NULL.

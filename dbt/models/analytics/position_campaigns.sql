-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql section (A):
-- analytics.position_campaigns — canonical source is that file until owner cutover (was
-- bigquery/102_pyramid_aware_lifecycle.sql).
--
-- Per (strategy,ticker), a running signed-share position; a campaign spans the first BUY that takes
-- it from flat (0) to non-flat, through every add/partial-exit fill, to the fill that returns it to
-- flat (closed) or the book's latest fill (still open). A pyramid with 2 adds + a partial exit + a
-- final exit is ONE campaign, not several disconnected lots -- this is "a trade" for closed_trades /
-- gate_n (ops.sp_recompute_engine) / thesis_outcomes going forward. Long-only-correct: a campaign is
-- detected opening on a 0->nonzero transition, which for this system's traded book is always a BUY
-- (short-campaign detection is DEFERRED — see bigquery/102's header SCOPE note). SGOV excluded
-- verbatim (same rationale as position_lifecycle — see that model's header).
--
-- REBUILT 2026-07-30 (bigquery/116 section (A)): additive-only change — carries the opening fill's
-- source_thesis_ref forward as opening_thesis_ref (appended LAST; existing column order preserved).
-- WHY: thesis_outcomes pairs a rationale to its outcome by NEAREST CALENDAR DATE, not by key, because
-- this aggregation used to drop source_thesis_ref in its GROUP BY — there was no FK reachable at this
-- layer at all, even though state.trade_fills_curated (a SELECT * over events.trade_fills) has always
-- carried the column. Re-trades and same-position adds are both live features now and nothing tested
-- for a wrong nearest-date pairing, so the FK is surfaced here for thesis_outcomes to prefer when
-- present. Same FIRST_VALUE-over-the-campaign-window construct already used for
-- campaign_contract_id/campaign_entry_price, so ANY_VALUE() after the GROUP BY is safe (constant
-- within the group), not an arbitrary pick. Row count / grouping / existing columns are unchanged —
-- ops.sp_recompute_engine's closed_trades/gate_n COUNT off this view and must be unaffected.

WITH fills AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.contract_id,
    DATE(fill_ts, 'America/New_York') AS fill_date, fill_ts,
    side, price, shares, commission, realized_pnl,
    -- NEW: carried through solely to survive the GROUP BY below as opening_thesis_ref.
    source_thesis_ref,
    COALESCE(dcf.is_dust, FALSE) AS fill_is_dust,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM {{ ref('trade_fills_curated') }} f
  LEFT JOIN {{ ref('dust_classified_fills') }} dcf USING (trade_id)
  WHERE ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
running AS (
  SELECT *,
    SUM(signed_shares) OVER w AS running_shares,
    -- prev_running_shares = the running position BEFORE this fill; COALESCE to 0 for each
    -- (strategy,ticker)'s very first fill (empty preceding-window), same construct as
    -- position_lifecycle's cum_start.
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
    -- NEW: the OPENING fill's source_thesis_ref -- the decision-log entry_id that authorized the
    -- campaign, when the write path recorded it as a UUID (the convention adopted ~2026-07-26; older
    -- rows hold free text like 'D2 2026-07-17 TSM D GO' and are left exactly as they are -- no
    -- backfill, no rewriting of history). thesis_outcomes treats a non-UUID value as "no FK" and
    -- falls back to nearest-date, so mixed population degrades gracefully rather than breaking.
    FIRST_VALUE(source_thesis_ref) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_opening_thesis_ref,
    -- The ENDING running_shares of the campaign (0 if closed, nonzero if still open).
    LAST_VALUE(running_shares) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_open_shares,
    -- The price of the fill that brought running_shares back to 0 (the closing fill), if any.
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
  ANY_VALUE(campaign_opening_thesis_ref) AS opening_thesis_ref,  -- (appended: column-order stable)
  -- Fill-level classification is written by D2a after inspecting authoritative connector state.
  -- A dust-only campaign stays flagged after its SELL; an unclassified later BUY turns a still-open
  -- campaign into a real mixed campaign rather than suppressing the legitimate trade wholesale.
  COUNTIF(side = 'BUY' AND fill_is_dust) > 0
    AND COUNTIF(side = 'BUY' AND NOT fill_is_dust) = 0 AS is_dust
FROM tagged
GROUP BY strategy, ticker, campaign_seq

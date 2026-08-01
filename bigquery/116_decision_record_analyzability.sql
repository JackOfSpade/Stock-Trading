-- DECISION-RECORD ANALYZABILITY (2026-07-30 interactive session, owner directive "fix all").
-- Project: stock-trading-498512.
-- Apply after 04_analytics.sql, 08_ops_procedures.sql, 25_calibration_shrinkage.sql,
-- 29_precedent_outcomes.sql, 66_research_quality_feedback.sql, 102_pyramid_aware_lifecycle.sql.
--
-- SUPERSEDES the current canonical definitions of: analytics.position_campaigns (102),
-- analytics.thesis_outcomes (102), analytics.conviction_features (04), analytics.calibration_shrunk (25),
-- analytics.thesis_outcome_summary (66), analytics.find_precedents (29), ops.sp_log_decision (08).
-- THIS FILE is the new canonical definition of all seven. analytics.calibration_summary (04) is NOT
-- redefined -- it reads conviction_features by name and so inherits the GO-family fix automatically.
--
-- KNOWN, DELIBERATE DIVERGENCE created by that choice: calibration_summary does NOT inherit (D)'s
-- canonical-tier enumeration, so it has 5 rows while calibration_shrunk now has 7 (the extra two being
-- LOW and HIGHEST, which no GO thesis has ever carried). The two views used to agree tier-for-tier and
-- no longer do. This is intentional and harmless -- verified 2026-07-30 that NO SQL object joins them,
-- and W5 is instructed to read calibration_shrunk as the authoritative signal ("supersedes reading
-- calibration_summary alone"). The enumeration was added to calibration_shrunk specifically because
-- find_precedents LEFT JOINs it and a MISSING tier row rendered as four NULLs; calibration_summary has
-- no such consumer, so widening it would be churn. Do not "fix" the row-count difference.
--
-- ALSO NOT redefined, and a KNOWN RESIDUAL rather than an oversight: analytics.declared_vs_realized
-- (bigquery/26_process_metrics.sql) independently re-derives its own GO count with the same exact-match
-- `entry_type = 'thesis-construction' AND decision = 'GO'` filter this file fixes elsewhere, so as of
-- 2026-07-30 it reports 19 GO theses where thesis_outcomes reports 21 (missing f90e7c15 B:ISRG and
-- fd464178 D:GOOGL add-tranche). Its consumers are analytics.process_scorecard and
-- state.strategy_playbook_readiness.dvr_ok; no gate flips today (both B and D clear the >=5 floor
-- either way) but process_scorecard's go_minus_opened is measurably off by one per strategy. Left for a
-- separate change rather than widened here, because it is a different view family with its own
-- consumers -- see the audit note in this file's companion review.
--
-- ============================================================================================
-- PROBLEM. An audit of the trade-reasoning record (2026-07-30) found the CAPTURE side is sound --
-- append-only is tripwire-enforced, embeddings are healthy, precedent review is mandatory -- but the
-- READ side is a set of EXACT STRING MATCHES sitting on top of an UNENFORCED FREE-TEXT VOCABULARY.
-- ops.sp_log_decision takes in_entry_type / in_decision as raw STRINGs; BigQuery has no CHECK
-- constraint; no CI check validates either column (the one dbt accepted_values(['GO']) test is a
-- tautology on conviction_features' own already-filtered output, and `dbt test` never runs in CI --
-- only `dbt parse` and the dbt-parity row comparison). So a one-character drift silently and
-- permanently removes real reasoning from every learning view, with no error and no alert.
--
-- It has already happened, twice, on two different columns:
--
--   (1) entry_type. For exactly 2026-07-20..22, fourteen rows were logged entry_type='thesis'
--       instead of 'thesis-construction' (13 Strategy B + 1 Strategy C; self-corrected 07-26; never
--       backfilled, and it CANNOT be backfilled -- decision_log is append-only and only sub_pattern
--       carries a sanctioned UPDATE exception, ops/RUNBOOK.md 21). analytics.thesis_outcomes filters
--       entry_type = 'thesis-construction' exactly, so all 14 are invisible to thesis_outcomes ->
--       conviction_features -> calibration_summary/calibration_shrunk AND to thesis_outcome_summary.
--       MEASURED: 13 of the 14 are NO-GOs, whose counterfactual tracking (events.nogo_shadow) is
--       written directly by the routine and is therefore unaffected; the one GO among them
--       (f90e7c15-..., B:ISRG, 2026-07-20) sits on a campaign that is still OPEN. So today's
--       calibration output is numerically unchanged -- the harm is a TICKING one: ISRG's win/loss
--       would have been dropped silently and forever the moment its campaign closed.
--
--   (2) decision. analytics.conviction_features (04) and analytics.thesis_outcome_summary (66) both
--       filter decision = 'GO' exactly. The D:GOOGL add-tranche GO (fd464178-..., 2026-07-26) was
--       logged decision='GO (add tranche)' and is therefore excluded from calibration, while the
--       semantically identical D:TSM add-tranche GO (32042c0f-..., 2026-07-29, plain 'GO') is
--       included. That inconsistency is an ACCIDENT of string matching, not a design choice.
--
-- DESIGN DECISION on (2), made explicitly rather than left to a filter's side effect (owner directive
-- 2026-07-30 delegated the call): an add-tranche thesis COUNTS AS ITS OWN CONVICTION OBSERVATION
-- against the shared campaign outcome. Rationale, from the system's own documented intent -- D2's
-- ADD CANDIDATES step requires an add-tranche thesis be constructed "at the SAME rigor as a first
-- entry" and logged as its OWN decision-log row, and bigquery/102's header states a pyramid add's
-- thesis "legitimately maps to the SAME campaign ... not a separate per-lot row". Two independent
-- predictions were made and one outcome resolves both; that is two observations of the framework's
-- calibration, not one. (The alternative -- dedupe to one observation per campaign -- is defensible
-- and would need a QUALIFY latest-per-campaign in conviction_features; it is NOT what today's
-- accidental exclusion does either, so nothing is being "preserved" by leaving this alone.)
--
-- ALSO FIXED, found by adversarially verifying the entry_type widening BEFORE applying it (the
-- widening would otherwise have introduced a NEW corruption -- this is the empty-join/attribution
-- class this project has been bitten by before):
--
--   (3) thesis_outcomes LEFT JOINs position_campaigns on (strategy, ticker) for EVERY thesis row,
--       including NO-GOs, then picks one by nearest entry_date. A NO-GO never opens a position, so it
--       must never inherit one. Today all 138 NO-GO rows happen to show position_closed=false -- but
--       that is EMPIRICAL LUCK, not a guarantee: it holds only because no NO-GO in the current 172
--       shares a (strategy,ticker) with a traded campaign. MEASURED: among the 14 rows the entry_type
--       fix newly admits, B:IBM's 2026-07-20 NO-GO matches TWO campaigns -- B:IBM:1 (CLOSED
--       2026-05-27, with a realized_pnl) and B:IBM:2 (open). Widening entry_type without this guard
--       would have attached a real closed-trade P&L to a DECLINED trade and fed it to
--       analytics.find_precedents as that precedent's outcome. The campaign join is now guarded to
--       GO-family decisions in the ON clause (LEFT JOIN, so every thesis row still survives with a
--       NULL campaign), which also closes the latent hole for the pre-existing 172.
--
--   (4) analytics.calibration_shrunk enumerated only the conviction tiers that HAPPEN to appear among
--       closed GO theses -- live: 5 rows ((unscored), MEDIUM-LOW, MEDIUM, MEDIUM-HIGH, HIGH). LOW and
--       HIGHEST are absent because no GO thesis has ever carried them. But HIGHEST is actively used
--       on NO-GO theses (HPE and OKTA, both 2026-06-02), so when analytics.find_precedents surfaces a
--       HIGHEST-conviction precedent, its LEFT JOIN to calibration_shrunk finds no row and returns
--       tier_win_rate_shrunk / tier_wilson_low / tier_wilson_high / tier_trustworthy_edge as four
--       NULLs. bigquery/29's own header calls co-surfacing that interval "MANDATORY per the audit's
--       risk-officer critique", precisely to stop a session reading a few salient precedents as more
--       informative than the sample supports. The guardrail therefore silently FAILS TO RENDER on
--       exactly the highest-conviction precedents -- the case it exists for -- instead of rendering
--       the honest maximally-wide [0,1] interval the view's own closed=0 logic already knows how to
--       produce. Fixed by enumerating all seven canonical tiers.
--
--   (5) analytics.find_precedents had no awareness of decision_log.superseded_by, so a CORRECTED
--       entry stays eligible to surface as an undifferentiated precedent forever. Live example: the
--       ULTA gate-session NO-GO (66101419-...) baked in a close-to-close of +1.33% which was
--       corrected the SAME DAY to -4.78% by b08567a3-.... Both rows are embedded and retrievable;
--       nothing marked the first as stale.
--
--   (6) decision_log.conviction_pct mixes two scales: of 77 non-null rows, 70 are 0-100 percent and
--       SEVEN are 0-1 fractions (NKE 2026-07-01 = 0.8; IONS/ALHC/MRNA/LASR/BBIO all 2026-07-12; one
--       router-review 2026-07-12 = 0.7). Any calibration computed off the raw column reads those as
--       ~1% instead of ~80%. Fixed read-side (a normalized column) AND write-side (a non-mutating
--       warning alert from sp_log_decision, so the root cause surfaces instead of accreting).
--
-- SCOPE NOTE -- what this file deliberately does NOT do:
--   * It does NOT mutate any stored decision_log row. Every fix here is a VIEW/PROCEDURE change or an
--     additive column. The 14 mislabeled rows keep their entry_type='thesis' forever; the reader is
--     taught the synonym instead. Append-only is preserved absolutely (state.append_only_integrity's
--     tripwire would fire otherwise, and only sub_pattern has a sanctioned UPDATE exception).
--   * It does NOT multiply conviction_pct into sizing or EV math. Conviction stays ORDINAL for
--     sizing (AI_Trading_Foundation.md 2.13/2.26/3a.1). conviction_pct is used here ONLY to MEASURE
--     calibration retrospectively, which is the sanctioned outcome-based direction.
--   * It does NOT add a CI gate on entry_type/decision vocabulary. This repo's CI checkers are
--     static/offline text parsers with no live BigQuery access (only the keyless-WIF dbt-parity job
--     touches the warehouse), so a vocabulary check has to be ROUTINE-side. The canonical vocabulary
--     is recorded in Claude_Task_Plan.md's decision-log lifecycle section and W5 -- which already owns
--     taxonomy hygiene for sub_pattern per ops/RUNBOOK.md 21 -- gains the drift watch. The view-level
--     synonym tolerance below is the mechanical backstop that makes a future drift non-destructive.
-- ============================================================================================


-- ============================================================================
-- (A) analytics.position_campaigns -- REBUILD. Byte-for-byte identical to bigquery/102's canonical
-- body EXCEPT it now carries the opening fill's source_thesis_ref forward as opening_thesis_ref.
--
-- WHY: analytics.thesis_outcomes pairs a rationale to its realized outcome by NEAREST CALENDAR DATE,
-- not by key. The audit's original framing was "the FK exists but is dirty free text"; verifying it
-- showed something worse -- there is NO FK REACHABLE AT THAT LAYER AT ALL, because this aggregation
-- drops source_thesis_ref in its GROUP BY. So even a perfectly-populated
-- events.trade_fills.source_thesis_ref could not reach thesis_outcomes. (state.trade_fills_curated is
-- SELECT * over events.trade_fills, so the column is available here -- it was simply never selected.)
-- Nearest-date has not yet produced a wrong pairing (only B:HCA and B:IBM currently have >1 campaign
-- for one strategy+ticker, and each has a single matching thesis), but re-trades AND same-position
-- adds are both live features now, and nothing tested for it.
--
-- Same FIRST_VALUE-over-the-campaign-window construct already used for campaign_contract_id /
-- campaign_entry_price, so ANY_VALUE() after the GROUP BY is safe (constant within the group), not an
-- arbitrary pick. Additive only: no row count, grouping, or existing column changes -- ops.
-- sp_recompute_engine's closed_trades/gate_n COUNT off this view and MUST be unaffected (verified
-- below: 21 campaigns / 8 closed / MAX(gate_n)=30, unchanged).
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_campaigns` AS
WITH fills AS (
  SELECT trade_id, strategy, ticker, contract_id,
    DATE(fill_ts, 'America/New_York') AS fill_date, fill_ts,
    side, price, shares, commission, realized_pnl,
    -- NEW: carried through solely to survive the GROUP BY below as opening_thesis_ref.
    source_thesis_ref,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
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
    -- NEW: the OPENING fill's source_thesis_ref -- the decision-log entry_id that authorized the
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
  ANY_VALUE(campaign_opening_thesis_ref) AS opening_thesis_ref   -- NEW (appended last: column-order stable)
FROM tagged
GROUP BY strategy, ticker, campaign_seq;


-- ============================================================================
-- (B) analytics.thesis_outcomes -- REBUILD. Four changes from bigquery/102's canonical body:
--   1. entry_type synonym tolerance: IN ('thesis-construction','thesis'). Recovers the 14 rows of the
--      2026-07-20..22 drift incident. NOT a licence for new spellings -- 'thesis-construction' stays
--      the mandated token (Claude_Task_Plan.md); this is the mechanical backstop that makes the next
--      drift non-destructive instead of silent and permanent.
--   2. The campaign join is GUARDED to GO-family decisions in the ON clause, so a NO-GO can never
--      inherit a position outcome (see file header (3) -- B:IBM 2026-07-20 is the live case this
--      prevents). LEFT JOIN, so every thesis row still appears with a NULL campaign.
--   3. FK-PREFERRING pairing: when the campaign's opening_thesis_ref IS this thesis's entry_id, that
--      campaign wins outright; otherwise fall back to the existing nearest-entry_date heuristic.
--      Note an ADD-tranche thesis correctly does NOT FK-match (the campaign's OPENING ref is the
--      original entry's id), so it still resolves to the same campaign via nearest-date -- which is
--      the documented intent (bigquery/102 header), preserved deliberately.
--   4. conviction_pct is now surfaced, plus conviction_pct_normalized (the 0-1-vs-0-100 scale fix,
--      file header (6)) -- substrate for analytics.conviction_pct_calibration below.
-- Regime-as-of join and was_profitable NULL-until-closed semantics are unchanged.
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
    -- other 70 stored 0-100 percent (file header (6)); 0 is left alone (0 is 0 on either scale).
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
  -- NEW columns (appended: existing column order preserved for any positional consumer).
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
  -- GUARD (file header (3)): only a GO-family thesis may be paired to a position at all.
  AND t.is_go_family
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
-- (C) analytics.conviction_features -- REBUILD. Identical to bigquery/04's canonical body except the
-- GO filter is now the GO-FAMILY test (file header (2) + the explicit design decision recorded
-- there), and conviction_pct_normalized is passed through for the probabilistic-calibration view.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.conviction_features` AS
SELECT entry_id, entry_date, strategy, ticker, decision, conviction,
  CASE UPPER(conviction)
    WHEN 'LOW' THEN 1 WHEN 'MEDIUM-LOW' THEN 2 WHEN 'MEDIUM' THEN 3
    WHEN 'MEDIUM-HIGH' THEN 4 WHEN 'HIGH' THEN 5 WHEN 'HIGHEST' THEN 6 ELSE NULL END AS conviction_ordinal,
  sub_pattern, regime_state, position_closed, realized_pnl, was_profitable,
  conviction_pct_normalized
FROM `stock-trading-498512.analytics.thesis_outcomes`
WHERE is_go_family;


-- ============================================================================
-- (D) analytics.calibration_shrunk -- REBUILD. Identical to bigquery/25's canonical body (Beta(2,2)
-- prior, Wilson 95%, closed>=15 AND wilson_low>0.55 trustworthy_edge) except `base` now enumerates
-- ALL SEVEN canonical conviction tiers instead of only those observed among GO theses.
--
-- WHY (file header (4)): a tier with no closed GO trades was ABSENT, so find_precedents' LEFT JOIN
-- returned four NULLs for it -- reading as "couldn't compute" on precisely the HIGHEST-conviction
-- precedents the mandatory-interval guardrail exists to temper. The view already knows how to say
-- "known to be uninformative" for closed=0 (the COALESCE to [0,1] below); it just never got the row.
--
-- FULL OUTER, deliberately, NOT a LEFT JOIN from the tier list: a LEFT JOIN would guarantee the seven
-- canonical tiers but SILENTLY DROP any non-canonical conviction string a future drift introduces --
-- which is the exact bug class this whole file exists to fix. FULL OUTER guarantees both directions:
-- every canonical tier always appears, and an unexpected value stays visible instead of vanishing.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.calibration_shrunk` AS
WITH canonical_tiers AS (
  -- The ordinal vocabulary of Experiment_Parameters.md / conviction_features' CASE, plus the
  -- '(unscored)' bucket calibration_summary and find_precedents both already key on (NULL conviction
  -- has no ordinal, so ord is NULL and it sorts first, exactly as before).
  SELECT * FROM UNNEST([
    STRUCT('(unscored)'  AS conviction, CAST(NULL AS INT64) AS ord),
    STRUCT('LOW'         AS conviction, 1                   AS ord),
    STRUCT('MEDIUM-LOW'  AS conviction, 2                   AS ord),
    STRUCT('MEDIUM'      AS conviction, 3                   AS ord),
    STRUCT('MEDIUM-HIGH' AS conviction, 4                   AS ord),
    STRUCT('HIGH'        AS conviction, 5                   AS ord),
    STRUCT('HIGHEST'     AS conviction, 6                   AS ord)
  ])
),
observed AS (
  SELECT COALESCE(conviction, '(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
    COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins
    -- was_profitable is realized_pnl > 0 (analytics.thesis_outcomes <- analytics.position_campaigns
    -- <- state.trade_fills_curated.realized_pnl), which is the BROKER's net-of-commission realized
    -- P&L per fill -- already the NET label the self-improvement audit's S-4 fix asked calibration to
    -- consume; no separate net conversion needed here.
  FROM `stock-trading-498512.analytics.conviction_features`
  GROUP BY conviction
),
base AS (
  SELECT
    COALESCE(ct.conviction, ob.conviction) AS conviction,
    COALESCE(ob.ord, ct.ord) AS ord,
    COALESCE(ob.go_theses, 0) AS go_theses,
    COALESCE(ob.closed, 0) AS closed,
    COALESCE(ob.wins, 0) AS wins
  FROM canonical_tiers ct
  FULL OUTER JOIN observed ob ON ob.conviction = ct.conviction
),
prior AS (SELECT 2.0 AS prior_a, 2.0 AS prior_b),
wilson AS (
  SELECT b.*, p.prior_a, p.prior_b,
    SAFE_DIVIDE(b.wins, b.closed) AS p_hat,
    -- Wilson score interval (z=1.96), the standard honest-at-low-N interval -- distinct from the
    -- shrunk point estimate (shrinkage and interval width are two separate small-sample corrections).
    --
    -- 2026-07-04 audit finding (HIGH): every division by b.closed below is SAFE_DIVIDE, not just the
    -- outermost one. BigQuery evaluates a SAFE_DIVIDE call's ARGUMENTS before the call itself guards
    -- anything, so a raw `/closed` nested inside an outer SAFE_DIVIDE still hard-errored the whole
    -- query when closed=0 -- and closed=0 is now the NORMAL case for LOW/HIGHEST (which this rebuild
    -- deliberately materializes), not just a transient empty-tier edge case, so this matters more here
    -- than it did in bigquery/25.
    SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) + SAFE_DIVIDE(1.96*1.96, 2*b.closed),
                1 + SAFE_DIVIDE(1.96*1.96, b.closed)) AS wilson_center,
    SAFE_DIVIDE(
      1.96 * SQRT(SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) * (1 - SAFE_DIVIDE(b.wins, b.closed)), b.closed)
                  + SAFE_DIVIDE(1.96*1.96, 4*b.closed*b.closed)),
      1 + SAFE_DIVIDE(1.96*1.96, b.closed)
    ) AS wilson_margin
  FROM base b, prior p
)
SELECT
  conviction, ord, go_theses, closed, wins,
  ROUND(p_hat, 3) AS win_rate,   -- raw MLE -- DO NOT read this alone; see wilson_low / trustworthy_edge
  ROUND(SAFE_DIVIDE(wins + prior_a, closed + prior_a + prior_b), 3) AS win_rate_shrunk,
  -- closed=0 has no Wilson interval to compute (n=0); represent it as maximal uncertainty [0,1]
  -- rather than NULL, which would read as "couldn't compute" instead of "known to be uninformative".
  ROUND(GREATEST(0.0, COALESCE(wilson_center - wilson_margin, 0.0)), 3) AS wilson_low,
  ROUND(LEAST(1.0, COALESCE(wilson_center + wilson_margin, 1.0)), 3) AS wilson_high,
  -- trustworthy_edge: the ONLY gate that may change behavior off this view. >=15 closed is still a
  -- directional-signal bar, not the foundation doc's stated >=30/200 for statistical proof -- deliberately
  -- conservative pending real volume. Below it, consumers read win_rate_shrunk as a lightly-informative
  -- prior-anchored estimate, never as a directive.
  (closed >= 15 AND COALESCE(wilson_center - wilson_margin, 0.0) > 0.55) AS trustworthy_edge
FROM wilson
ORDER BY ord;


-- ============================================================================
-- (E) analytics.thesis_outcome_summary -- REBUILD. Identical to bigquery/66's canonical body except
-- the GO filter is the GO-family test (same leak as conviction_features -- file header (2)). This is
-- the per-(strategy, sub_pattern) mechanism-level rollup W5 reads weekly and logs as
-- entry_type='research-quality-digest' (ops/autonomy_levels.yaml loop research_quality_feedback,
-- stage=shadow). Record-only / non-gating: unchanged by this rebuild.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcome_summary` AS
SELECT
  strategy,
  COALESCE(sub_pattern, '(unclassified)') AS sub_pattern,
  COUNT(*) AS n_theses,
  COUNTIF(position_closed) AS n_closed,
  COUNTIF(position_closed AND was_profitable) AS n_profitable,
  COUNTIF(position_closed AND NOT was_profitable) AS n_unprofitable,
  -- Directional-only floor; below it, the tally is a data point, never a trigger (min_n=15 per the
  -- architect recommendation's own stated floor -- 3x nogo_counterfactual_summary's min_n=5, since a real
  -- position's realized P&L carries more weight per observation than a counterfactual SGOV-vs-price delta).
  (COUNTIF(position_closed) >= 15) AS min_n_met
FROM `stock-trading-498512.analytics.thesis_outcomes`
WHERE is_go_family
GROUP BY strategy, sub_pattern
ORDER BY strategy, n_theses DESC;


-- ============================================================================
-- (F) analytics.conviction_pct_calibration -- NEW. Probabilistic (not ordinal) calibration substrate:
-- do the framework's stated numeric confidences match realized frequencies -- do 45% calls happen
-- about 45% of the time?
--
-- Today decision_log.conviction_pct is CAPTURED (77 rows, e.g. D:TSM's 45) but structurally orphaned:
-- calibration_summary and calibration_shrunk both group by the CATEGORICAL conviction tier and never
-- reference conviction_pct at all, so this question was unanswerable.
--
-- COLD-START HONEST, and currently EMPTY OF SIGNAL BY DESIGN: of the GO-family theses carrying a
-- conviction_pct, none has a closed campaign yet, so every bucket reads closed=0 / NULL win rate.
-- That is the SAME "built but not yet exercised" state as events.nogo_shadow (0/21 closed until
-- 2026-08-02) and events.premortem_flags (0 rows) -- substrate accruing signal, NOT a defect, and it
-- must NOT be re-flagged as broken by a future audit. min_n_met carries the same >=15 floor as every
-- sibling calibration view so a thin bucket can never be over-read.
--
-- SCOPE: measurement only. conviction_pct is NEVER multiplied into sizing or EV math -- conviction
-- stays ordinal for sizing per AI_Trading_Foundation.md 2.13/2.26/3a.1. Outcome-based measurement is
-- the sanctioned direction (2.27: "compensation must be outcome-based ... never self-report").
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.conviction_pct_calibration` AS
WITH scored AS (
  SELECT
    -- Decile buckets on the NORMALIZED value, so the 7 fraction-scale rows land in the right bucket
    -- instead of reading as ~1%.
    CAST(FLOOR(conviction_pct_normalized / 10) * 10 AS INT64) AS pct_bucket_low,
    position_closed, was_profitable, conviction_pct_normalized
  FROM `stock-trading-498512.analytics.conviction_features`
  WHERE conviction_pct_normalized IS NOT NULL
)
SELECT
  pct_bucket_low,
  pct_bucket_low + 10 AS pct_bucket_high,
  COUNT(*) AS n_theses,
  COUNTIF(position_closed) AS closed,
  COUNTIF(was_profitable) AS wins,
  ROUND(AVG(conviction_pct_normalized), 2) AS mean_stated_pct,
  -- The calibration comparison itself: stated confidence vs realized frequency, both as percentages.
  ROUND(100 * SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)), 2) AS realized_win_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)) - AVG(conviction_pct_normalized), 2)
    AS calibration_gap_pct,   -- >0 = under-confident, <0 = over-confident. NULL until closed>0.
  (COUNTIF(position_closed) >= 15) AS min_n_met
FROM scored
GROUP BY pct_bucket_low
ORDER BY pct_bucket_low;


-- ============================================================================
-- (G) analytics.find_precedents -- REBUILD. Identical to bigquery/29's canonical body except it is
-- now aware of decision_log.superseded_by (file header (5)).
--
-- WHY: this TVF is MANDATORY before every GO/NO-GO call (task_plan/D2.md's OUTCOME-ANNOTATED
-- PRECEDENT REVIEW), and it had no way to know a precedent had been corrected. Live example: the ULTA
-- gate-session NO-GO (66101419-...) recorded a close-to-close of +1.33%, corrected the SAME DAY to
-- -4.78% by b08567a3-.... Both are embedded; the stale one was indistinguishable from current truth.
--
-- analytics.decision_embeddings does not carry superseded_by (verified against its live schema), so
-- the flag comes from a join back to events.decision_log. Superseded rows are EXCLUDED (a corrected
-- fact must not be read as a precedent) and the column is also surfaced so the exclusion is
-- self-evident to anyone reading the TVF's output rather than silently invisible. Note this makes the
-- result set <=10 rather than exactly 10 when a superseded row is retrieved -- correct, and preferable
-- to padding with a more distant precedent.
--
-- NOTE the exclusion is currently a NO-OP: superseded_by is populated on 0 of 496 rows today. The
-- forward-going write discipline that makes it real (correction callers passing in_superseded_by) is
-- specified in Claude_Task_Plan.md's decision-log lifecycle section by this same change. Historical
-- correction rows are NOT retro-linked -- that would require UPDATEs on an append-only table.
--
-- SUPERSEDED LIVE by bigquery/122_decision_correction_append_only.sql -- current single source of truth
-- for this object. 118 first moved the filter below inside the candidate pool; 122 additionally fixes
-- its direction, excluding the correction row's named target rather than the correction itself. A
-- same-day adversarial review of THIS file found the placement below is wrong: the superseded_by filter
-- is applied OUTSIDE the candidate subquery, i.e. AFTER `QUALIFY rn=1 ... LIMIT 10`, so once
-- superseded_by starts being populated a query whose nearest 10 include N superseded rows returns only
-- 10-N precedents to a set Claude_Task_Plan.md calls MANDATORY -- while up to 20
-- already-fetched, non-superseded candidates at ranks 11-30 (same single Vertex embedding call) are
-- discarded unused. The defence written below ("preferable to padding with a more distant precedent")
-- does not hold: those ranks cost nothing extra. 118 moves the filter inside the subquery and switches
-- LEFT JOIN -> NOT IN (which additionally cannot multiply rows on a duplicate entry_id).
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
-- ============================================================================
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.find_precedents`(query_text STRING)
AS (
  SELECT
    p.entry_id, p.entry_date, p.strategy, p.entry_type, p.sub_pattern,
    p.decision, p.conviction, p.ticker, p.title, p.distance,
    outc.position_closed, outc.was_profitable, outc.realized_pnl AS thesis_realized_pnl,
    ngo.excess_return_vs_sgov AS nogo_excess_return_vs_sgov,
    ngo.would_nogo_have_been_correct_long_framing AS nogo_was_correct_long_framing,
    cal.win_rate_shrunk AS tier_win_rate_shrunk,
    cal.wilson_low AS tier_wilson_low,
    cal.wilson_high AS tier_wilson_high,
    cal.trustworthy_edge AS tier_trustworthy_edge
  FROM (
    SELECT base.entry_id, base.entry_date, base.strategy, base.entry_type, base.sub_pattern,
           base.decision, base.conviction, base.ticker, base.title, distance,
           ROW_NUMBER() OVER (PARTITION BY base.entry_id ORDER BY distance) AS rn
    FROM VECTOR_SEARCH(
      TABLE `stock-trading-498512.analytics.decision_embeddings`, 'embedding',
      (SELECT ml_generate_embedding_result AS embedding FROM ML.GENERATE_EMBEDDING(
         MODEL `stock-trading-498512.ops.text_embed`,
         (SELECT query_text AS content),
         STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_QUERY' AS task_type))),
      top_k => 30, distance_type => 'COSINE')
    QUALIFY rn = 1
    ORDER BY distance
    LIMIT 10
  ) p
  LEFT JOIN `stock-trading-498512.analytics.thesis_outcomes` outc ON outc.entry_id = p.entry_id
  LEFT JOIN `stock-trading-498512.analytics.nogo_counterfactual` ngo ON ngo.decision_log_entry_id = p.entry_id
  -- COALESCE to '(unscored)' (2026-07-04 audit finding): NULL = NULL is never TRUE in SQL, so a raw
  -- `cal.conviction = p.conviction` equality join silently drops the mandated calibration interval for
  -- any precedent with NULL conviction — calibration_shrunk buckets those under the literal string
  -- '(unscored)' (bigquery/25_calibration_shrinkage.sql), never under NULL itself.
  LEFT JOIN `stock-trading-498512.analytics.calibration_shrunk` cal
    ON cal.conviction = COALESCE(p.conviction, '(unscored)')
  -- NEW: supersession awareness. INNER-equivalent filter expressed on a LEFT JOIN so a retrieved
  -- entry_id with no decision_log row (impossible today -- embeddings are built FROM decision_log --
  -- but harmless to be explicit about) is kept rather than silently dropped.
  LEFT JOIN `stock-trading-498512.events.decision_log` dl ON dl.entry_id = p.entry_id
  WHERE dl.superseded_by IS NULL
  ORDER BY p.distance
);


-- ============================================================================
-- (H) ops.sp_log_decision -- REBUILD. Byte-for-byte identical to bigquery/08's canonical body plus a
-- conviction_pct SCALE GUARD (file header (6)).
--
-- WHY here and not only on read: seven rows already stored a 0-1 fraction where the field means 0-100
-- percent. A normalize-on-read column (thesis_outcomes.conviction_pct_normalized) makes existing data
-- usable, but without a write-side signal the leak keeps adding drops forever.
--
-- DELIBERATELY NON-MUTATING and NON-BLOCKING, in that order:
--   * It does NOT rewrite the caller's value. This is an append-only audit log; storing 85 when the
--     caller passed 0.85 would make a future reader's reconstruction of what the session actually
--     asserted subtly wrong. The row lands exactly as passed; the ALERT is what gets someone to fix
--     the caller.
--   * It does NOT reject the write. A hard failure here would abort a routine mid-decision over a
--     units nit, on the single code path every trading decision in the system flows through. The
--     INSERT is already committed before the guard runs, and the guard is wrapped in an exception
--     handler that never rethrows -- same defensive shape (and same rationale) as the embed call
--     below it: never discard a durable decision because a derived/secondary step hiccuped.
-- Range note: 0 is excluded (0 is 0 on either scale) and so is NULL; only 0 < pct <= 1 is ambiguous,
-- and on the percent scale that range means "<=1% confidence", which no real thesis would assert.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_decision`(
  in_entry_date DATE, in_entry_type STRING, in_strategy STRING, in_ticker STRING,
  in_decision STRING, in_conviction STRING, in_conviction_pct NUMERIC,
  in_sub_pattern STRING, in_theater_check STRING, in_title STRING, in_body_md STRING,
  in_fields_json STRING, in_refs ARRAY<STRING>, in_tags ARRAY<STRING>,
  in_superseded_by STRING, in_source_session STRING
)
BEGIN
  -- 1) Durable append of the decision (source of truth; must always persist).
  INSERT INTO `stock-trading-498512.events.decision_log`
    (entry_date, entry_type, strategy, ticker, decision, conviction, conviction_pct,
     sub_pattern, theater_check, title, body_md, fields, refs, tags, superseded_by, source_session)
  VALUES
    (in_entry_date, in_entry_type, in_strategy, in_ticker, in_decision, in_conviction, in_conviction_pct,
     in_sub_pattern, in_theater_check, in_title, in_body_md,
     SAFE.PARSE_JSON(in_fields_json), in_refs, in_tags, in_superseded_by, in_source_session);

  -- 2) conviction_pct scale guard. Non-mutating, non-blocking (see header). Runs AFTER the durable
  --    append so it can never stand between a decision and its persistence.
  BEGIN
    IF in_conviction_pct IS NOT NULL AND in_conviction_pct > 0 AND in_conviction_pct <= 1 THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'ops.sp_log_decision', 'conviction_pct_scale',
        'A decision was logged with conviction_pct on the 0-1 FRACTION scale; the column means 0-100 PERCENT. The row was persisted exactly as passed (append-only; not rewritten) and analytics.thesis_outcomes.conviction_pct_normalized corrects it on read -- but the CALLER should pass e.g. 85 rather than 0.85. Seven historical rows carry this defect (bigquery/116 header (6)).',
        TO_JSON_STRING(STRUCT(
          in_conviction_pct AS passed_conviction_pct,
          in_entry_type AS entry_type, in_strategy AS strategy, in_ticker AS ticker,
          in_source_session AS source_session, CURRENT_TIMESTAMP() AS detected_ts)));
    END IF;
  EXCEPTION WHEN ERROR THEN
    SELECT FORMAT('sp_log_decision: decision persisted; conviction_pct scale guard skipped (%s)', @@error.message) AS warning;
  END;

  -- 3) Build the embedding in the SAME call. Never let an embedding failure discard the decision.
  BEGIN
    CALL `stock-trading-498512.ops.sp_embed_pending`();
  EXCEPTION WHEN ERROR THEN
    SELECT FORMAT('sp_log_decision: decision persisted; embedding deferred (%s)', @@error.message) AS warning;
  END;
END;


-- ============================================================================
-- (I) state.add_candidate_reviews -- NEW. Parsing view over the add-candidate-review fields JSON
-- contract, following the established write-time-contract + parsing-view pattern exactly
-- (bigquery/96_research_screener.sql's state.research_screen_calls is the model): one row per
-- {review, position}, with call-level fields carried on every position row so a consumer never has to
-- re-join to events.decision_log.
--
-- WHY: D1's ANALYSIS -- ADD-CANDIDATE CHECK performs a substantive judgment on every open A/B/D
-- position every day, and that reasoning previously existed ONLY in Daily.md -- which is wholesale
-- OVERWRITTEN by the next session rather than appended. MEASURED: 178 of 292 lines turned over between
-- the 2026-07-27 and 2026-07-28 commits. So a decline was unqueryable within ~24h and recoverable only
-- by `git show` archaeology. That is worse than a prose log: it is a prose log that deletes itself.
-- The declines are also where a systemic finding hides -- on 2026-07-28, D1 evaluated all 11 open A/B/D
-- positions and declined TWO (D:DIS, D:TSM) at the Rev-40 HARD GATE purely because their
-- invalidation_status was NULL, i.e. "unbreached" could not be affirmatively confirmed. That day's own
-- process note flagged it for W5 ("legacy position rows without a populated invalidation_status are
-- structurally ineligible for adds regardless of how good the case is") -- but no routine could see or
-- COUNT it, because the note lived only in a file that is overwritten the next day.
-- Claude_Task_Plan.md's D1 section now mandates one row per run.
--
-- EMPTY UNTIL D1's NEXT RUN, by construction -- no entry_type='add-candidate-review' row exists yet.
-- Same "substrate built, not yet exercised" state as events.nogo_shadow and events.premortem_flags;
-- NOT a defect, and must not be re-flagged as one by a future audit.
--
-- Volume note: ONE row per D1 run (~250/yr), not one per position (~4,000/yr against a table holding
-- under 500 today) -- the per-position detail lives in the UNNESTed array, which is what makes the
-- compact write and the granular read compatible.
-- ============================================================================
-- SUPERSEDED LIVE by bigquery/122_decision_correction_append_only.sql — current single source of
-- truth for this object. It preserves this parser and filters targets named by append-only replacement
-- rows. Kept here, unmodified, for DR-rebuild apply-in-order reference only. Do not re-apply in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.add_candidate_reviews` AS
WITH reviews AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                              AS process_note,
    source_session,
    SAFE_CAST(JSON_VALUE(fields, '$.n_evaluated') AS INT64)              AS n_evaluated,
    SAFE_CAST(JSON_VALUE(fields, '$.n_flagged') AS INT64)                AS n_flagged,
    SAFE_CAST(JSON_VALUE(fields, '$.n_declined_hard_gate') AS INT64)     AS n_declined_hard_gate,
    JSON_QUERY_ARRAY(fields, '$.positions')                              AS positions
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'add-candidate-review'
)
-- A review whose positions array is empty (or absent) contributes zero rows -- correct, not a bug: a
-- day with no open A/B/D position writes no row at all per D1's spec.
SELECT
  r.entry_id, r.entry_date, r.event_ts, r.source_session,
  r.n_evaluated, r.n_flagged, r.n_declined_hard_gate, r.process_note,
  JSON_VALUE(pos, '$.ticker')                                      AS ticker,
  JSON_VALUE(pos, '$.strategy')                                    AS strategy,
  SAFE_CAST(JSON_VALUE(pos, '$.mark_vs_cost_pct') AS NUMERIC)      AS mark_vs_cost_pct,
  JSON_VALUE(pos, '$.trigger_type')                                AS trigger_type,
  JSON_VALUE(pos, '$.disposition')                                 AS disposition,
  JSON_VALUE(pos, '$.reason')                                      AS reason,
  -- Legacy key retained for decision-record compatibility.  D1 switched its write
  -- contract on 2026-07-30; read the current key separately rather than treating
  -- its inverse semantics as a substitute for this historical field.
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_status_null') AS BOOL) AS invalidation_status_null,
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_criteria_evaluable') AS BOOL)
    AS invalidation_criteria_evaluable
FROM reviews r, UNNEST(r.positions) AS pos;


-- ============================================================================
-- VERIFICATION HARNESS. Run after applying. Every row must read PASS.
-- Baseline captured live 2026-07-30 immediately before this file was applied:
--   thesis_outcomes=172, conviction_features=19, calibration_shrunk=5, position_campaigns=21,
--   closed campaigns=8, MAX(perf.strategy_daily.gate_n)=30, conviction_pct fraction rows=7,
--   superseded_by populated=0.
-- ============================================================================
-- NOTE on this comment style: these verification queries are `--` comment lines, NOT a /* */
-- block. That is DELIBERATE and load-bearing. scripts/check_live_sql_parity.py's extract_body()
-- runs to END OF FILE when no further CREATE follows, and normalize_tail() strips trailing
-- blank/`--` lines but NOT a trailing /* */ block -- so a block comment here gets folded into the
-- object's EXPECTED body and can never match the live definition, reporting DRIFT forever and
-- sending D3's self-heal into a pointless re-apply loop. Measured 2026-07-30: these three files
-- were the ONLY ones in bigquery/ using a trailing /* */ harness, and it made
-- state.add_candidate_reviews and analytics.find_precedents drift permanently. Keep `--`.
-- WITH checks AS (
--   -- (1) The 14 drifted rows are recovered: 172 -> 186.
--   SELECT 'thesis_outcomes recovers the entry_type=thesis rows' AS check_name,
--          (SELECT COUNT(*) FROM `stock-trading-498512.analytics.thesis_outcomes`) = 186 AS ok
--   -- (2) The specific ISRG GO is now visible to the learning layer.
--   UNION ALL SELECT 'B:ISRG GO f90e7c15 is in thesis_outcomes',
--     EXISTS(SELECT 1 FROM `stock-trading-498512.analytics.thesis_outcomes`
--            WHERE entry_id = 'f90e7c15-cf35-4979-9549-dc15771aae99')
--   -- (3) ...and in conviction_features (it is a GO).
--   UNION ALL SELECT 'B:ISRG GO f90e7c15 is in conviction_features',
--     EXISTS(SELECT 1 FROM `stock-trading-498512.analytics.conviction_features`
--            WHERE entry_id = 'f90e7c15-cf35-4979-9549-dc15771aae99')
--   -- (4) The GO-family fix admits the GOOGL add-tranche: 19 -> 21.
--   UNION ALL SELECT 'conviction_features = 21 (GO + GO (add tranche))',
--     (SELECT COUNT(*) FROM `stock-trading-498512.analytics.conviction_features`) = 21
--   UNION ALL SELECT 'D:GOOGL add-tranche fd464178 is in conviction_features',
--     EXISTS(SELECT 1 FROM `stock-trading-498512.analytics.conviction_features`
--            WHERE entry_id = 'fd464178-8fa4-41e0-978a-52b53bcc0faa')
--   -- (5) THE CRITICAL GUARD: no NO-GO may ever carry a position outcome. B:IBM 2026-07-20 is the live
--   --     case -- it matches two campaigns, one CLOSED with realized P&L.
--   UNION ALL SELECT 'no non-GO thesis carries a campaign outcome',
--     (SELECT COUNTIF(NOT is_go_family AND (position_closed OR realized_pnl IS NOT NULL OR campaign_key IS NOT NULL))
--      FROM `stock-trading-498512.analytics.thesis_outcomes`) = 0
--   UNION ALL SELECT 'B:IBM 2026-07-20 NO-GO has NULL campaign specifically',
--     (SELECT COUNTIF(campaign_key IS NOT NULL) FROM `stock-trading-498512.analytics.thesis_outcomes`
--      WHERE strategy='B' AND ticker='IBM' AND entry_date='2026-07-20' AND NOT is_go_family) = 0
--   -- (6) All seven canonical tiers now materialize, incl. LOW and HIGHEST (5 -> 7).
--   UNION ALL SELECT 'calibration_shrunk has all 7 canonical tiers',
--     (SELECT COUNT(*) FROM `stock-trading-498512.analytics.calibration_shrunk`) = 7
--   UNION ALL SELECT 'HIGHEST tier renders a real [0,1] interval, not NULL',
--     (SELECT wilson_low = 0.0 AND wilson_high = 1.0 AND closed = 0 AND NOT trustworthy_edge
--      FROM `stock-trading-498512.analytics.calibration_shrunk` WHERE conviction = 'HIGHEST')
--   UNION ALL SELECT 'LOW tier also renders',
--     EXISTS(SELECT 1 FROM `stock-trading-498512.analytics.calibration_shrunk` WHERE conviction = 'LOW')
--   -- (7) trustworthy_edge must still be FALSE everywhere (materializing empty tiers must not
--   --     accidentally trip the ONLY gate that may change behavior).
--   UNION ALL SELECT 'trustworthy_edge still FALSE on every tier',
--     (SELECT COUNTIF(trustworthy_edge) FROM `stock-trading-498512.analytics.calibration_shrunk`) = 0
--   -- (8) REGRESSION: position_campaigns is additive only -- gate_n / closed_trades MUST be untouched.
--   UNION ALL SELECT 'position_campaigns row count unchanged (21)',
--     (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns`) = 21
--   UNION ALL SELECT 'closed campaigns unchanged (8)',
--     (SELECT COUNTIF(exit_date IS NOT NULL) FROM `stock-trading-498512.analytics.position_campaigns`) = 8
--   -- (9) The new FK column is present and populated for the rows whose write path used the UUID
--   --     convention (~2026-07-26 onward); older campaigns keep free text and pair by date.
--   UNION ALL SELECT 'opening_thesis_ref exists and >=1 campaign pairs by FK',
--     (SELECT COUNTIF(paired_by_fk) FROM `stock-trading-498512.analytics.thesis_outcomes`) >= 1
--   -- (10) Nothing lost the campaign it used to have: every GO that had an outcome still has one.
--   UNION ALL SELECT 'all 7 previously-scored GO outcomes still scored',
--     (SELECT COUNTIF(position_closed) FROM `stock-trading-498512.analytics.conviction_features`) = 7
--   -- (11) Scale normalization works on the 7 known fraction rows.
--   UNION ALL SELECT 'no normalized conviction_pct remains in the ambiguous 0-1 band',
--     (SELECT COUNTIF(conviction_pct_normalized > 0 AND conviction_pct_normalized <= 1)
--      FROM `stock-trading-498512.analytics.thesis_outcomes`) = 0
--   -- (12) The new probabilistic-calibration view builds and is honestly empty of signal.
--   UNION ALL SELECT 'conviction_pct_calibration builds, min_n_met FALSE everywhere',
--     (SELECT COUNTIF(min_n_met) FROM `stock-trading-498512.analytics.conviction_pct_calibration`) = 0
--   -- (13) find_precedents still returns rows and its mandatory tier interval is no longer NULL for a
--   --      HIGHEST-conviction precedent. (Costs one Vertex embedding call.)
--   UNION ALL SELECT 'find_precedents returns rows with non-NULL tier interval',
--     (SELECT COUNT(*) >= 1 FROM `stock-trading-498512.analytics.find_precedents`(
--        'Strategy B post-print aggressive sell-side PT raise ratification')
--      WHERE tier_wilson_high IS NOT NULL)
-- )
-- SELECT check_name, IF(ok, 'PASS', '*** FAIL ***') AS result FROM checks ORDER BY result DESC, check_name;

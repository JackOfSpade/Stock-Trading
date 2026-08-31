-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql section (B):
-- analytics.thesis_outcomes — canonical source is bigquery/144_decision_log_correction_consumers.sql
-- section (3) (which SUPERSEDES bigquery/123_drip_dust_campaign_exclusion.sql, which superseded 116,
-- which superseded bigquery/102_pyramid_aware_lifecycle.sql) until owner cutover.
-- One row per thesis-construction decision, joined to its position outcome (realized P&L from
-- the curated fills) + the prevailing fundamental regime. `was_profitable` is the supervised
-- label for the future conviction model — NULL until the position CLOSES (open positions are
-- unknown, not "unprofitable"; a buy fill's realized_pnl=0 must not read as a loss).
--
-- REGIME-AS-OF FIX (2026-07-03, self-improvement audit S-1/B-1): regime_state is the regime in
-- effect ON OR BEFORE entry_date, NOT the single latest value — the prior form back-stamped the
-- current regime onto every historical thesis (look-ahead leakage). Decorrelated join + QUALIFY
-- (BigQuery views do not support a same-row correlated subquery against another table).
--
-- REBUILT 2026-07-21 (pyramid-aware accounting rebuild): the LEFT JOIN target + the QUALIFY
-- nearest-entry_date window moved from position_lifecycle (Tier-1 lots) to position_campaigns
-- (Tier-2 campaigns) — a pyramid add's own thesis-construction entry legitimately maps to the SAME
-- campaign as the position's original entry, not a separate per-lot row.
--
-- REBUILT 2026-07-30 (bigquery/116 section (B)), four changes:
--   1. entry_type synonym tolerance: IN ('thesis-construction','thesis'). Recovers 14 rows dropped
--      by the 2026-07-20..22 drift incident, where the write path logged entry_type='thesis' instead
--      of the mandated 'thesis-construction' for that window. NOT a licence for new spellings --
--      'thesis-construction' stays the mandated token (Claude_Task_Plan.md); this is the mechanical
--      backstop that makes the next drift non-destructive instead of silent and permanent.
--   2. The campaign join is GUARDED to GO-family decisions in the ON clause, so a NO-GO can never
--      inherit a position outcome. Live case this prevents: B:IBM's 2026-07-20 NO-GO matches TWO
--      campaigns, one CLOSED with a realized P&L — widening entry_type without this guard would have
--      attached that closed-trade P&L to a DECLINED trade. LEFT JOIN, so every thesis row still
--      appears, with a NULL campaign.
--   3. FK-PREFERRING pairing: when the campaign's opening_thesis_ref IS this thesis's entry_id, that
--      campaign wins outright; otherwise fall back to the existing nearest-entry_date heuristic. An
--      ADD-tranche thesis correctly does NOT FK-match (the campaign's OPENING ref is the original
--      entry's id), so it still resolves to the same campaign via nearest-date -- the documented
--      intent, preserved deliberately.
--   4. conviction_pct is now surfaced, plus conviction_pct_normalized (a 0-1-vs-0-100 scale fix: of
--      77 non-null conviction_pct rows, seven stored a 0-1 fraction where the column means 0-100
--      percent) -- substrate for analytics.conviction_pct_calibration.
-- New columns are appended LAST (is_go_family, conviction_pct, conviction_pct_normalized,
-- campaign_key, paired_by_fk) so existing column order / any positional consumer is unaffected.
--
-- BUG FIX (2026-08-31 code-quality pass, dbt#0): the `theses` CTE reads state.decision_log_current,
-- not raw events.decision_log — bigquery/144 (2026-08-06) moved the canonical body onto the
-- anti-joined view specifically because an entry-type-preserving correction to a thesis-construction
-- row would otherwise double the GO it corrects (bigquery/144's header names the live 38ff17a6 /
-- ba8a060c MDT correction as the concrete case). This dbt port had been left reading the raw table
-- for 25 days with zero CI coverage of the gap (scripts/check_superseded_by_discipline.py only scans
-- bigquery/, never dbt/).

WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, conviction_pct, sub_pattern, decision, title,
    -- GO-FAMILY TEST, used both to guard the campaign join and (by consumers) to filter to GO.
    -- Anchored ^GO\b: matches 'GO' and 'GO (add tranche)'; does NOT match 'NO-GO',
    -- 'NO-GO / DO-NOT-STAGE', 'NO-GO (no add; existing position runs)' (anchored, so a leading 'NO-'
    -- can never match) nor a hypothetical 'GOOD' (\b requires a non-word char after 'GO').
    -- VERIFIED live against all 164 NO-GO-flavored rows: zero false matches.
    REGEXP_CONTAINS(UPPER(TRIM(COALESCE(decision, ''))), r'^GO\b') AS is_go_family,
    -- Scale-normalized conviction probability. SEVEN historical rows stored a 0-1 fraction where the
    -- other 70 stored 0-100 percent; 0 is left alone (0 is 0 on either scale).
    IF(conviction_pct > 0 AND conviction_pct <= 1, conviction_pct * 100, conviction_pct) AS conviction_pct_normalized
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE entry_type IN ('thesis-construction', 'thesis')
),
regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM {{ source('events', 'regime_events') }}
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
  CASE WHEN pc.exit_date IS NULL THEN NULL          -- still open -> outcome unknown (not a loss)
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
LEFT JOIN {{ ref('position_campaigns') }} pc
  ON pc.strategy = t.strategy AND pc.ticker = t.ticker
  -- GUARD: only a GO-family thesis may be paired to a position at all.
  AND t.is_go_family
  -- NEW 2026-08-02 (bigquery/123): a post-close DRIP-dust phantom is never a thesis's outcome.
  -- Without this, a GO thesis dated nearer its dust campaign than its real one mis-pairs via the
  -- nearest-date fallback below and reports position_closed = FALSE with NULL realized P&L. Kept in
  -- the ON clause (not a WHERE) so an otherwise-unpaired thesis still yields its row with a NULL
  -- campaign. is_dust is non-nullable by construction; on a non-match it is NULL and the LEFT JOIN
  -- handles that correctly.
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
) = 1

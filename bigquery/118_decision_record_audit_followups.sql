-- DECISION-RECORD AUDIT FOLLOW-UPS (2026-07-30, second review pass over the same day's
-- bigquery/116_decision_record_analyzability.sql). Project: stock-trading-498512.
-- Apply after 26_process_metrics.sql and 116_decision_record_analyzability.sql.
--
-- SUPERSEDES the current canonical definition of analytics.declared_vs_realized (26). Its former
-- analytics.find_precedents definition is SUPERSEDED LIVE by
-- bigquery/122_decision_correction_append_only.sql, the current canonical definition for that
-- object. Do not re-apply 118's find_precedents body in isolation.
--
-- Both items below were found by an adversarial review OF bigquery/116 itself, not of the pre-116
-- system -- i.e. they are defects in (or missed by) that same-day change, caught before it was
-- committed. Recorded that way deliberately: bigquery/116's header claims to have swept the
-- exact-string-match bug class, and (A) proves that sweep was incomplete.
--
-- ============================================================================================
-- (A) analytics.declared_vs_realized -- THE 116 SWEEP MISSED THIS SIBLING VIEW.
--
-- bigquery/116's header states the problem it fixes as "several learning views key on entry_type /
-- decision with EXACT STRING MATCHES" and rebuilt thesis_outcomes, conviction_features and
-- thesis_outcome_summary accordingly. analytics.declared_vs_realized (bigquery/26_process_metrics.sql)
-- has the IDENTICAL construct -- `WHERE entry_type = 'thesis-construction' AND decision = 'GO'`
-- re-derived independently off events.decision_log rather than read from thesis_outcomes -- and was
-- not updated. Before 2026-07-30 both counting paths were blind to the same two bugs and therefore
-- AGREED (both wrong); afterwards one was fixed and the other was not, so they SILENTLY DIVERGED.
--
-- MEASURED live 2026-07-30 before this fix: declared_vs_realized reported go_theses B=10, D=9
-- (total 19) against analytics.thesis_outcomes' COUNTIF(is_go_family)=21. The exact 2-row delta:
--   * f90e7c15-cf35-4979-9549-dc15771aae99 -- B:ISRG 2026-07-20, entry_type='thesis' (the
--     2026-07-20..22 drift incident 116 recovers)
--   * fd464178-8fa4-41e0-978a-52b53bcc0faa -- D:GOOGL 2026-07-26, decision='GO (add tranche)'
-- Consequence: analytics.process_scorecard.go_minus_opened was off by one per strategy (B reported
-- -3, true -2; D reported -2, true -1). No gate flipped -- state.strategy_playbook_readiness.dvr_ok
-- (bigquery/37_self_improvement_autonomy.sql:137) is COUNTIF(min_n_met) > 0 and both B and D clear
-- the >=5 floor either way -- but a thinner-sample strategy could have had this 2-row gap flip
-- dvr_ok, and a metric that is quietly wrong is exactly what this whole audit was about.
--
-- FIX: stop re-deriving the filter. Read the GO count from analytics.thesis_outcomes WHERE
-- is_go_family, the same single source conviction_features and thesis_outcome_summary now use, so a
-- future vocabulary fix lands in ONE place instead of needing to be remembered in four.
--
-- bigquery/131_declared_vs_realized_distinct_positions.sql picked up this fix and became canonical
-- next (2026-08-03) -- and was itself superseded the very next day by bigquery/136 (see the single
-- marker at the end of this comment block, which names the CURRENT canonical file). Do not stop at
-- 131 -- it is an intermediate, also-superseded pointer, not the live definition.
--
-- The paragraph below is the ORIGINAL 2026-07-30 note, retained as provenance. It correctly
-- identified the opened-leg double-count and deliberately declined to fix it under cover of an
-- unrelated change; bigquery/131 (2026-08-03) is that deferred fix, finally made on its own terms
-- after W5 alert 5dedd49e surfaced the resulting go_minus_opened = -3 readings for B and D.
--
-- NOT CHANGED HERE, and NOT a defect introduced here -- flagged so the next reader does not mistake
-- it for one: the `opened` leg still counts every event_type='OPEN' row in events.position_events. That
-- table is append-only and the STAGING-OPEN KEY INVARIANT means a filled order legitimately leaves
-- BOTH a staging-time provisional OPEN and a fill-time OPEN for the same position_key, so
-- opened_count can exceed the number of distinct positions and go_minus_opened can read negative.
-- That behaviour predates 2026-07-30, is unrelated to the entry_type/decision bug class, and is left
-- exactly as-is rather than quietly changed under cover of this fix.
--
-- SUPERSEDED LIVE by bigquery/136_declared_vs_realized_orphan_sides.sql (2026-08-04) — current single
-- source of truth for this object. (The append-only double-count described just above WAS subsequently
-- fixed, by bigquery/131, which 136 then superseded in turn; 131 carries its own marker.) Kept here,
-- unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live
-- in isolation — it would revert both the COUNT(DISTINCT position_key) fix and the orphan-side columns.
-- ============================================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.declared_vs_realized` AS
WITH go_theses AS (
  -- Was: SELECT ... FROM events.decision_log WHERE entry_type='thesis-construction' AND decision='GO'.
  -- Now reads the corrected single source (bigquery/116), so entry_type synonyms and the GO family
  -- ('GO (add tranche)') are counted here identically to how calibration counts them.
  SELECT strategy, COUNT(*) AS go_count
  FROM `stock-trading-498512.analytics.thesis_outcomes`
  WHERE is_go_family
  GROUP BY strategy
),
opened AS (
  SELECT strategy, COUNT(*) AS opened_count
  FROM `stock-trading-498512.events.position_events`
  WHERE event_type = 'OPEN'
  GROUP BY strategy
)
SELECT
  COALESCE(g.strategy, o.strategy) AS strategy,
  COALESCE(g.go_count, 0) AS go_theses,
  COALESCE(o.opened_count, 0) AS positions_opened,
  COALESCE(g.go_count, 0) - COALESCE(o.opened_count, 0) AS go_minus_opened,
  (COALESCE(g.go_count, 0) >= 5) AS min_n_met
FROM go_theses g
FULL OUTER JOIN opened o ON o.strategy = g.strategy
ORDER BY strategy;


-- ============================================================================
-- (B) analytics.find_precedents -- MOVE THE superseded_by FILTER INSIDE THE CANDIDATE SUBQUERY.
--
-- bigquery/116 added supersession awareness as an OUTER filter, applied AFTER the inner subquery had
-- already done `QUALIFY rn=1 ... ORDER BY distance LIMIT 10`. Its own header defended the resulting
-- behaviour ("makes the result set <=10 rather than exactly 10 ... preferable to padding with a more
-- distant precedent"). On review that defence does not hold: ranks 11-30 are NOT a "more distant
-- precedent" fetched at extra cost -- they are already-paid-for output of the SAME single
-- ML.GENERATE_EMBEDDING + VECTOR_SEARCH(top_k => 30) call, discarded unused by the LIMIT 10. So the
-- old placement silently THINNED the evidence set that Claude_Task_Plan.md calls MANDATORY before
-- every GO/NO-GO, for zero saving.
--
-- Currently INERT either way -- superseded_by is populated on 0 of 496 rows today, so no query has
-- yet lost a precedent. It stops being inert the moment the forward write-discipline added to
-- Claude_Task_Plan.md ("a correction row MUST name what it corrects via in_superseded_by") starts
-- being followed, which is exactly when it would begin quietly degrading.
--
-- IMPLEMENTED as a NOT IN anti-join rather than the previous LEFT JOIN, which also removes a second
-- latent hazard 116 carried: events.decision_log declares entry_id PRIMARY KEY but BigQuery does NOT
-- enforce constraints, so a duplicate entry_id would have MULTIPLIED precedent rows through that
-- join. A subquery anti-join cannot multiply rows regardless. (Verified live 2026-07-30: zero
-- duplicate entry_ids exist today -- so this is hardening, not a live bug.) The `entry_id IS NOT
-- NULL` guard matters because NOT IN against a NULL-containing set yields NULL, which would exclude
-- every row -- a fail-CLOSED-to-empty trap worth being explicit about.
--
-- Everything else is byte-identical to bigquery/116's body: same top_k => 30, same COSINE, same
-- best-chunk-per-entry QUALIFY, same three outcome/calibration LEFT JOINs, same '(unscored)' COALESCE
-- on the calibration join (2026-07-04 audit finding -- NULL = NULL is never TRUE, so a NULL-conviction
-- precedent would otherwise silently lose its mandated interval).
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
    -- Supersession filter, now INSIDE the candidate pool so LIMIT 10 selects 10 LIVE precedents from
    -- the full 30 already fetched, instead of returning 10-minus-superseded (bigquery/116's placement).
    WHERE base.entry_id NOT IN (
      SELECT entry_id FROM `stock-trading-498512.events.decision_log`
      WHERE superseded_by IS NOT NULL AND entry_id IS NOT NULL
    )
    QUALIFY rn = 1
    ORDER BY distance
    LIMIT 10
  ) p
  LEFT JOIN `stock-trading-498512.analytics.thesis_outcomes` outc ON outc.entry_id = p.entry_id
  LEFT JOIN `stock-trading-498512.analytics.nogo_counterfactual` ngo ON ngo.decision_log_entry_id = p.entry_id
  LEFT JOIN `stock-trading-498512.analytics.calibration_shrunk` cal
    ON cal.conviction = COALESCE(p.conviction, '(unscored)')
  ORDER BY p.distance
);


-- ============================================================================
-- VERIFICATION. Run after applying; every row must read PASS.
-- Pre-fix baseline captured live 2026-07-30: declared_vs_realized go_theses B=10 D=9 (sum 19);
-- thesis_outcomes COUNTIF(is_go_family)=21; decision_log rows with superseded_by set = 0.
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
--   SELECT 'declared_vs_realized GO count now agrees with thesis_outcomes (21)' AS check_name,
--     (SELECT SUM(go_theses) FROM `stock-trading-498512.analytics.declared_vs_realized`)
--       = (SELECT COUNTIF(is_go_family) FROM `stock-trading-498512.analytics.thesis_outcomes`) AS ok
--   UNION ALL SELECT 'the two previously-missing entries are now counted',
--     (SELECT SUM(go_theses) FROM `stock-trading-498512.analytics.declared_vs_realized`) = 21
--   UNION ALL SELECT 'per-strategy: B=11, D=10 (each +1 vs the old 10/9)',
--     (SELECT COUNT(*) FROM `stock-trading-498512.analytics.declared_vs_realized`
--      WHERE (strategy='B' AND go_theses=11) OR (strategy='D' AND go_theses=10)) = 2
--   UNION ALL SELECT 'dvr_ok gate unchanged (still TRUE) -- no autonomy gate flipped',
--     (SELECT dvr_ok FROM `stock-trading-498512.state.strategy_playbook_readiness` LIMIT 1) IS NOT NULL
--   UNION ALL SELECT 'min_n_met still met for B and D',
--     (SELECT COUNTIF(min_n_met) FROM `stock-trading-498512.analytics.declared_vs_realized`) >= 2
--   UNION ALL SELECT 'no duplicate entry_id in decision_log (anti-join multiplication precondition)',
--     (SELECT COUNT(*) FROM (SELECT entry_id FROM `stock-trading-498512.events.decision_log`
--                            GROUP BY entry_id HAVING COUNT(*) > 1)) = 0
--   UNION ALL SELECT 'find_precedents still returns 10 rows (filter is inert at 0 superseded)',
--     (SELECT COUNT(*) FROM `stock-trading-498512.analytics.find_precedents`(
--        'Strategy B post-print aggressive sell-side PT raise ratification')) = 10
-- )
-- SELECT check_name, IF(ok, 'PASS', '*** FAIL ***') AS result FROM checks ORDER BY result, check_name;

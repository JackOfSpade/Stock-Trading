-- Outcome-annotated precedent memory — the LLM-as-learner path (2026-07-03, self-improvement audit
-- S-6). Project: stock-trading-498512. Apply after 02_ai_layer.sql (analytics.find_precedents base
-- version, analytics.decision_embeddings), 04_analytics.sql (analytics.thesis_outcomes),
-- 25_calibration_shrinkage.sql (analytics.calibration_shrunk), 28_nogo_shadow.sql
-- (analytics.nogo_counterfactual).
--
-- WHY: find_precedents() retrieved semantically-similar prior decisions WITHOUT their realized
-- outcomes — a thesis-construction session saw "we discussed a similar name" but not "and it won/lost
-- net $X" or "the NO-GO'd name subsequently fell or didn't". Given the subject model will be swapped
-- over the experiment's multi-year horizon (numerical calibration won't transfer across model versions
-- per AI_Trading_Foundation.md), the chosen improving component is the LLM reading outcome-annotated
-- precedents in-context at thesis-construction time, NOT a fitted statistical model (the BQML
-- conviction_model is deprecated entirely, bigquery/04_analytics.sql).
--
-- Redefines analytics.find_precedents (the CHUNKED base version from 02_ai_layer.sql) to also surface:
-- (1) the realized outcome of a prior THESIS precedent (position_closed / was_profitable / net
--     realized_pnl, from analytics.thesis_outcomes);
-- (2) the realized counterfactual of a prior NO-GO precedent (excess return vs SGOV over the shadow
--     horizon, from analytics.nogo_counterfactual — self-improvement audit S-3);
-- (3) the retrieved precedent's conviction tier's shrunk posterior + Wilson interval (analytics.
--     calibration_shrunk — self-improvement audit S-2/B-2), MANDATORY per the audit's risk-officer
--     critique: co-surfacing the honest-wide interval alongside raw precedent outcomes is what stops a
--     thesis-construction session from reading 3 salient wins as more informative than an 8-trade
--     sample actually supports (the exact narrative/recency-overfit hazard AI_Trading_Foundation.md
--     flags). Claude_Task_Plan.md's NEW ENTRY CANDIDATES step requires reasoning about all three.
--
-- SUPERSEDED LIVE by bigquery/118_decision_record_audit_followups.sql — current single source of
-- truth for this object (bigquery/02_ai_layer.sql AND bigquery/116_decision_record_analyzability.sql
-- are both intermediate, also-superseded definitions — do not stop at either): 116 added exclusion of
-- rows whose decision_log.superseded_by is set, so a corrected entry cannot resurface as a precedent;
-- 118 then moved that filter INSIDE the top_k=>30 candidate subquery, ahead of LIMIT 10, so the
-- MANDATORY pre-GO/NO-GO evidence set still returns 10 live precedents instead of 10-minus-superseded.
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
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
  ORDER BY p.distance
);

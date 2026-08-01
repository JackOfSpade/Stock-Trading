-- Append-only decision-correction semantics (integrity incident 2026-08-01).
--
-- `events.decision_log` is immutable except for W5's documented `sub_pattern` taxonomy exception.
-- A late-discovered fact is corrected by INSERTING a complete replacement through
-- ops.sp_log_decision. The replacement PRESERVES the superseded row's semantic entry_type (for
-- example, `research-screen` or `add-candidate-review`), carries tag `correction`, and sets its
-- `superseded_by` to the older row's entry_id. The old row remains intact for audit; readers exclude
-- that TARGET, not the replacement row that names it. A standalone `entry_type='correction'` row is
-- only for a non-replacement note. No UPDATE, DELETE, or MERGE against events.decision_log is
-- permitted here.
--
-- SUPERSEDES bigquery/118_decision_record_audit_followups.sql's analytics.find_precedents definition,
-- bigquery/96_research_screener.sql's state.research_screen_calls definition, and
-- bigquery/116_decision_record_analyzability.sql's state.add_candidate_reviews definition. This is
-- the current single source of truth for all three objects. Keep the older files for DR-rebuild
-- history; do not re-apply those definitions in isolation.

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
    -- The correction row's `superseded_by` names the obsolete target. Filter that target inside
    -- the already-fetched candidate pool, so LIMIT 10 still returns ten final-effective records.
    -- Do NOT filter `entry_id WHERE superseded_by IS NOT NULL`: that is the correction row itself.
    WHERE base.entry_id NOT IN (
      SELECT superseded_by
      FROM `stock-trading-498512.events.decision_log`
      WHERE superseded_by IS NOT NULL
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


-- state.research_screen_calls: same parser as bigquery/96, but final-effective. A correction must
-- retain entry_type='research-screen' for this view to see its corrected payload; the anti-join
-- removes the named stale target before either array is expanded.
CREATE OR REPLACE VIEW `stock-trading-498512.state.research_screen_calls` AS
WITH calls AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                          AS rationale,
    JSON_VALUE(fields, '$.routine')                                  AS routine,
    JSON_VALUE(fields, '$.screen')                                   AS screen,
    JSON_VALUE(fields, '$.population_rail')                          AS population_rail,
    SAFE_CAST(JSON_VALUE(fields, '$.surfaced_count') AS INT64)       AS surfaced_count,
    JSON_VALUE(fields, '$.legacy_rule')                              AS legacy_rule,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.both') AS INT64)       AS agreement_both,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.ai_only') AS INT64)    AS agreement_ai_only,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.rule_only') AS INT64)  AS agreement_rule_only,
    JSON_QUERY_ARRAY(fields, '$.passed')                             AS passed,
    JSON_QUERY_ARRAY(fields, '$.rejected_notable')                   AS rejected_notable
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'research-screen'
    AND entry_id NOT IN (
      SELECT superseded_by
      FROM `stock-trading-498512.events.decision_log`
      WHERE superseded_by IS NOT NULL
    )
)
SELECT
  entry_id, entry_date, event_ts, routine, screen, population_rail, surfaced_count, legacy_rule,
  agreement_both, agreement_ai_only, agreement_rule_only, rationale,
  'passed'                                                      AS side,
  JSON_VALUE(item, '$.name')                                    AS name,
  SAFE_CAST(JSON_VALUE(item, '$.metric_pct') AS NUMERIC)        AS metric_pct,
  JSON_VALUE(item, '$.conviction')                              AS conviction,
  SAFE_CAST(JSON_VALUE(item, '$.conviction_pct') AS NUMERIC)    AS conviction_pct,
  JSON_VALUE(item, '$.reason')                                  AS reason,
  SAFE_CAST(JSON_VALUE(item, '$.below_spec_floor') AS BOOL)     AS below_spec_floor,
  SAFE_CAST(JSON_VALUE(item, '$.legacy_rule_pass') AS BOOL)     AS legacy_rule_pass
FROM calls, UNNEST(passed) AS item

UNION ALL

SELECT
  entry_id, entry_date, event_ts, routine, screen, population_rail, surfaced_count, legacy_rule,
  agreement_both, agreement_ai_only, agreement_rule_only, rationale,
  'rejected_notable'                                             AS side,
  JSON_VALUE(item, '$.name')                                    AS name,
  SAFE_CAST(JSON_VALUE(item, '$.metric_pct') AS NUMERIC)        AS metric_pct,
  JSON_VALUE(item, '$.conviction')                              AS conviction,
  SAFE_CAST(JSON_VALUE(item, '$.conviction_pct') AS NUMERIC)    AS conviction_pct,
  JSON_VALUE(item, '$.reason')                                  AS reason,
  SAFE_CAST(JSON_VALUE(item, '$.below_spec_floor') AS BOOL)     AS below_spec_floor,
  SAFE_CAST(JSON_VALUE(item, '$.legacy_rule_pass') AS BOOL)     AS legacy_rule_pass
FROM calls, UNNEST(rejected_notable) AS item;


-- state.add_candidate_reviews: same parser as bigquery/116, final-effective for a replacement
-- review whose semantic entry_type remains `add-candidate-review`.
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
    AND entry_id NOT IN (
      SELECT superseded_by
      FROM `stock-trading-498512.events.decision_log`
      WHERE superseded_by IS NOT NULL
    )
)
SELECT
  r.entry_id, r.entry_date, r.event_ts, r.source_session,
  r.n_evaluated, r.n_flagged, r.n_declined_hard_gate, r.process_note,
  JSON_VALUE(pos, '$.ticker')                                      AS ticker,
  JSON_VALUE(pos, '$.strategy')                                    AS strategy,
  SAFE_CAST(JSON_VALUE(pos, '$.mark_vs_cost_pct') AS NUMERIC)      AS mark_vs_cost_pct,
  JSON_VALUE(pos, '$.trigger_type')                                AS trigger_type,
  JSON_VALUE(pos, '$.disposition')                                 AS disposition,
  JSON_VALUE(pos, '$.reason')                                      AS reason,
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_status_null') AS BOOL) AS invalidation_status_null,
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_criteria_evaluable') AS BOOL)
    AS invalidation_criteria_evaluable
FROM reviews r, UNNEST(r.positions) AS pos;

-- VERIFICATION. Run after applying; every row must read PASS.
-- Comments remain `--` lines so scripts/check_live_sql_parity.py excludes this harness from the
-- stored object bodies.
-- WITH fixture AS (
--   SELECT 'old-screen' AS entry_id, 'research-screen' AS entry_type,
--          CAST(NULL AS STRING) AS superseded_by UNION ALL
--   SELECT 'new-screen', 'research-screen', 'old-screen' UNION ALL
--   SELECT 'old-add', 'add-candidate-review', NULL UNION ALL
--   SELECT 'new-add', 'add-candidate-review', 'old-add'
-- ), final_effective AS (
--   SELECT entry_id, entry_type FROM fixture
--   WHERE entry_id NOT IN (SELECT superseded_by FROM fixture WHERE superseded_by IS NOT NULL)
-- ), checks AS (
--   SELECT 'research-screen target excluded; replacement retained' AS check_name,
--          NOT EXISTS (SELECT 1 FROM final_effective WHERE entry_id = 'old-screen')
--          AND EXISTS (SELECT 1 FROM final_effective
--                      WHERE entry_id = 'new-screen' AND entry_type = 'research-screen') AS ok
--   UNION ALL SELECT 'add-candidate target excluded; replacement retained',
--          NOT EXISTS (SELECT 1 FROM final_effective WHERE entry_id = 'old-add')
--          AND EXISTS (SELECT 1 FROM final_effective
--                      WHERE entry_id = 'new-add' AND entry_type = 'add-candidate-review')
-- )
-- SELECT check_name, IF(ok, 'PASS', '*** FAIL ***') AS result FROM checks ORDER BY check_name;

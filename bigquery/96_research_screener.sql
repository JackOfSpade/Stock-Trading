-- bigquery/96_research_screener.sql — AI Research-Significance Screen: the read/audit views over the
-- rail-bounded AI significance judgment that replaces the fixed close-to-close/correlation bars in
-- D1's single-name and sector move screens, W2's post-event price-move screen, and M2's PART 1
-- correlation-pair population screen. Project: stock-trading-498512.
--
-- Spec: AI_DECISION_REDESIGN.md §3 Redesign C (owner verdict 2026-07-19 — initially DEFERRED, THEN
-- REVERSED the same day by direct in-session directive "Yes, implement it" after the owner asked for
-- and read a plain-language explanation of the redesign) — implements the two-layer screen structure
-- (mechanical population rail + AI significance judgment) described in Operating_Protocols.md §19 and
-- wired inline in Claude_Task_Plan.md's D1 DEVELOPMENTS/OPPORTUNITY CHECK, W2 PART 1, and M2 PART 1.
-- Every converted-screen call is logged as an events.decision_log row (entry_type='research-screen')
-- carrying a `fields` JSON payload; this file's ONLY objects are read views over that payload — no new
-- table, no new procedure, and NOTHING here decides significance for real: the AI judgment happens
-- in-session at screen time, and the frozen Strategy B/E entry criteria (spec-floor rail, §19) — not
-- this file — gate real entry-candidate routing. This mirrors bigquery/95_capital_allocator.sql's
-- "parse `fields` JSON via JSON_VALUE, one row per {call, sub-item}" convention, generalized here to
-- TWO parallel arrays per call (`passed` / `rejected_notable`, distinguished by a `side` column) since
-- a research-screen call must also carry forward every legacy-rule-passing item the AI rejected (the
-- disagreement surface §19's logging contract exists to capture), where a capital-allocation call has
-- only one array (its winning allocations).
--
-- fields JSON schema written by CALL ops.sp_log_decision(..., entry_type='research-screen', ...)
-- (Operating_Protocols.md §19 logging contract — document verbatim in both places):
--   {
--     "routine": "D1"|"W2"|"M2",
--     "screen": "single-name-move"|"sector-move"|"post-event"|"pair-divergence",
--     "population_rail": "<the Layer-1 net applied, e.g. 'move>=2% mktcap>=2B'>",
--     "surfaced_count": <int — Layer-1 population size>,
--     "legacy_rule": "move>=5%"|"sector>=2%"|"corr>=0.5",
--     "passed": [ {"name":"<TICKER | L/S pair | SECTOR>", "metric_pct": <number — the move %/corr>,
--                  "conviction":"low|medium|high", "conviction_pct": <30|45|60|75>,
--                  "reason":"<one sentence>", "below_spec_floor": <bool>,
--                  "legacy_rule_pass": <bool>} ],
--     "rejected_notable": [ same item shape — MUST include EVERY legacy-rule-passing item the AI
--                            rejected ],
--     "agreement": {"both": n, "ai_only": n, "rule_only": n}
--   }
-- `rationale` (the screen's judgment narrative) is the decision_log row's native `body_md` column, not
-- a fields key — same "exactly one payload is authoritative, never split redundantly across native
-- columns and JSON" discipline bigquery/95_capital_allocator.sql's header states for its own `rationale`.
-- `legacy_rule_pass` is computed MECHANICALLY in-session (metric vs. the old fixed bar) — the old rule
-- runs RECORD-ONLY inside every call as benchmark, the `park_rule_shadow` precedent (§13.F / §19),
-- never the decider. agreement counts: both = passed with legacy_rule_pass; ai_only = passed without;
-- rule_only = rejected_notable with legacy_rule_pass.
--
-- Zero-row-safe by construction: entry_type='research-screen' has never been written as of this file's
-- authoring — loop `research_screener` is registered directly `active_auto` in ops/autonomy_levels.yaml
-- (per §19's Loop paragraph) but its first D1/W2/M2 call has not yet fired — so `state.research_screen_
-- calls` and `analytics.research_screen_disagreements` are EXPECTED to read back empty today. That is
-- the correct, not-broken state; do not treat an empty read as a bug (verified live via the readonly
-- BigQuery MCP at authoring time: zero decision_log rows of this entry_type exist). A call with empty
-- `passed`/`rejected_notable` arrays (a quiet screen day) is equally zero-row-safe: UNNEST of an empty
-- (or NULL, via JSON_QUERY_ARRAY on a missing key) array contributes zero item rows for that side —
-- the call-level facts remain recoverable from any sibling row of the OTHER side's UNNEST for the same
-- entry_id, or directly from events.decision_log by entry_id if both sides are empty.
--
-- Apply after 95_capital_allocator.sql. Nothing in this file depends on 95 or is depended on by it —
-- both are independent read views over disjoint entry_type slices of events.decision_log — apply order
-- relative to each other is cosmetic (numbering-adjacent, not a dependency); apply either any time
-- after bigquery/01_schema.sql. Brand-new objects — no superseded markers needed.
-- ============================================================================

-- Object 1 — state.research_screen_calls: one row per {call, item}, UNION ALL over the two per-call
-- arrays (side='passed' / side='rejected_notable'). Call-level fields (routine/screen/population_rail/
-- surfaced_count/legacy_rule/agreement_*/rationale) are carried on every item row so a consumer never
-- has to re-join back to events.decision_log for them.
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
)
-- A call whose passed/rejected_notable array is empty (or absent) contributes zero rows for that side
-- — correct, not a bug (see header). No QUALIFY/dedup needed: each array element is already a distinct
-- item within its own call.
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

-- Object 2 — analytics.research_screen_disagreements: the "did the screen call it right" surface —
-- every item where the AI's significant/not-significant call DISAGREED with the mechanical legacy
-- rule, LEFT-JOINed to the earliest LATER thesis-construction decision_log row for the same name (the
-- screens-rejecting-winners check W5's RESEARCH-SCREEN SCORECARD reads — §19's W5 evaluation
-- paragraph). rule_only = the legacy rule would have surfaced it but the AI rejected it as noise;
-- ai_only = the AI surfaced it as significant even though it missed the legacy bar (frequently a
-- below_spec_floor context item — see the row's own below_spec_floor column).
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
LEFT JOIN `stock-trading-498512.events.decision_log` t
  ON t.ticker = f.name
 AND t.entry_type = 'thesis-construction'
 AND t.entry_date > f.entry_date
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY f.entry_id, f.side, f.name
  ORDER BY t.entry_date ASC
) = 1;

-- Parallel-run dbt port of bigquery/144_decision_log_correction_consumers.sql:analytics.research_screen_disagreements — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH flagged AS (
  SELECT
    *,
    CASE
      WHEN side = 'rejected_notable' AND legacy_rule_pass       THEN 'rule_only'
      WHEN side = 'passed'           AND NOT legacy_rule_pass   THEN 'ai_only'
    END AS disagreement_class
  FROM {{ ref('research_screen_calls') }}
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
LEFT JOIN {{ source('state_external', 'decision_log_current') }} t
  ON t.ticker = f.name
 AND t.entry_type = 'thesis-construction'
 AND t.entry_date > f.entry_date
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY f.entry_id, f.side, f.name
  ORDER BY t.entry_date ASC
) = 1

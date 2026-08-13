-- 169_position_metadata_carry_forward.sql (2026-08-12)
-- Apply after 168_nomadic_capital_fixes.sql.
--
-- Prevents a sparse lifecycle transition from erasing live position metadata. This is the data-layer
-- hardening for the second demonstrated omission in eight days: D2's 2026-08-11 EXIT_PENDING row for
-- B:ISRG:2026-07-21 omitted invalidation_status and ltcg_date, leaving both NULL in
-- state.current_positions for about 23 hours until D2a's CLOSE echoed them forward. The same raw-write
-- class affected GEV/MTZ/MDT on 2026-08-03/04 (bigquery/137).
--
-- Lifecycle fields and mutable/descriptive metadata remain latest-wins. Only the two fields implicated in
-- the incident carry forward: immutable invalidation_status and the LTCG tax anchor. This scope is
-- deliberate. A measured pre-deploy diff showed that blindly carrying every populated metadata field
-- would resurrect D:RTX's intentionally-cleared time_exit_date and an obsolete D:DIS source_thesis_ref.
-- A JSON null is treated like SQL NULL for invalidation_status. Raw events are never rewritten: the
-- existing dbt regression test still detects writer omissions, while live D1/M4/D2 consumers no longer
-- lose risk criteria or tax dates during the detection/repair interval.

CREATE OR REPLACE VIEW `stock-trading-498512.state.current_positions` AS
WITH enriched AS (
  SELECT
    p.*,
    LAST_VALUE(ltcg_date IGNORE NULLS) OVER w AS carried_ltcg_date,
    LAST_VALUE(
      CASE
        WHEN invalidation_status IS NULL OR TO_JSON_STRING(invalidation_status) = 'null' THEN NULL
        ELSE invalidation_status
      END IGNORE NULLS
    ) OVER w AS carried_invalidation_status,
    ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC, event_id DESC) AS rn
  FROM `stock-trading-498512.events.position_events` p
  WINDOW w AS (
    PARTITION BY position_key
    ORDER BY event_ts, event_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )
)
SELECT
  event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id,
  cost_basis, shares,
  convergence_target,
  time_exit_date,
  carried_ltcg_date AS ltcg_date,
  carried_invalidation_status AS invalidation_status,
  conviction,
  model_at_entry,
  source_thesis_ref,
  note
FROM enriched
WHERE rn = 1 AND event_type <> 'CLOSE';

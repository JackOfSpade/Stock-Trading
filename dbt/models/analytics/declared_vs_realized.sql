-- Parallel-run dbt port of bigquery/136_declared_vs_realized_orphan_sides.sql:analytics.declared_vs_realized — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH go_theses AS (
  -- Was: SELECT ... FROM events.decision_log WHERE entry_type='thesis-construction' AND decision='GO'.
  -- Now reads the corrected single source (bigquery/116), so entry_type synonyms and the GO family
  -- ('GO (add tranche)') are counted here identically to how calibration counts them.
  SELECT strategy, COUNT(*) AS go_count
  FROM {{ ref('thesis_outcomes') }}
  WHERE is_go_family
  GROUP BY strategy
),
opened AS (
  -- COUNT(DISTINCT position_key), NOT COUNT(*): the STAGING-OPEN KEY INVARIANT writes a provisional
  -- OPEN at staging and a second fill-reconciliation OPEN under the SAME position_key, and
  -- events.position_events is append-only so both persist. COUNT(*) double-counted every reconciled
  -- position. See bigquery/131's header for the adversarial checks proving DISTINCT does not
  -- under-count adds or re-opens (both mint their own position_key).
  SELECT strategy, COUNT(DISTINCT position_key) AS opened_count
  FROM {{ source('events', 'position_events') }}
  WHERE event_type = 'OPEN'
  GROUP BY strategy
),
-- Distinct (strategy, ticker) keys on each side, for the orphan anti-joins below. DISTINCT matters:
-- without it a ticker holding several positions (adds) would be counted once per position.
thesis_keys AS (
  SELECT DISTINCT strategy, UPPER(TRIM(ticker)) AS tkr
  FROM {{ ref('thesis_outcomes') }}
  WHERE is_go_family AND ticker IS NOT NULL
),
position_keys AS (
  SELECT DISTINCT strategy, UPPER(TRIM(ticker)) AS tkr
  FROM {{ source('events', 'position_events') }}
  WHERE event_type = 'OPEN' AND ticker IS NOT NULL
),
orphan_theses AS (
  SELECT t.strategy, COUNT(*) AS n
  FROM thesis_keys t
  LEFT JOIN position_keys p ON p.strategy = t.strategy AND p.tkr = t.tkr
  WHERE p.tkr IS NULL
  GROUP BY t.strategy
),
orphan_positions AS (
  SELECT p.strategy, COUNT(*) AS n
  FROM position_keys p
  LEFT JOIN thesis_keys t ON t.strategy = p.strategy AND t.tkr = p.tkr
  WHERE t.tkr IS NULL
  GROUP BY p.strategy
)
SELECT
  COALESCE(g.strategy, o.strategy) AS strategy,
  COALESCE(g.go_count, 0) AS go_theses,
  COALESCE(o.opened_count, 0) AS positions_opened,
  COALESCE(g.go_count, 0) - COALESCE(o.opened_count, 0) AS go_minus_opened,
  -- The two directions the net above cannot separate. n_positions_without_go_thesis is the
  -- capital-affecting one: a position opened with no decision of record.
  COALESCE(ot.n, 0) AS n_go_theses_without_position,
  COALESCE(op.n, 0) AS n_positions_without_go_thesis,
  (COALESCE(g.go_count, 0) >= 5) AS min_n_met
FROM go_theses g
FULL OUTER JOIN opened o ON o.strategy = g.strategy
LEFT JOIN orphan_theses ot ON ot.strategy = COALESCE(g.strategy, o.strategy)
LEFT JOIN orphan_positions op ON op.strategy = COALESCE(g.strategy, o.strategy)
ORDER BY strategy

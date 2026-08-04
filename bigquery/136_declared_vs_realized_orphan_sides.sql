-- 136_declared_vs_realized_orphan_sides.sql (2026-08-04)
-- Project: stock-trading-498512. Apply AFTER 131_declared_vs_realized_distinct_positions.sql.
--
-- WHY. `go_minus_opened` is a NET count: go_theses minus positions_opened. A net cannot distinguish
-- "every thesis has a position and every position has a thesis" from "one orphan on EACH side, which
-- happen to cancel". Strategy B is in exactly the second state as of today and the metric reads 0:
--   * OKTA 2026-05-31 — a GO thesis that never became a position (the benign direction the spec
--     already anticipates).
--   * BURL B:BURL:2026-05-29 — a position with NO GO thesis of record, ever. This is a real
--     decision-provenance gap, documented in events.decision_log by the 2026-08-04 correction entry.
-- Those two cancel to 0, so the surface that W5's process_scorecard_signal reads now looks clean while
-- a genuine gap sits underneath it. Before an unrelated 2026-08-04 correction (re-tagging MDT's GO
-- thesis, which had been written with entry_type='other' and so was invisible to thesis_outcomes),
-- the same metric read -1 and at least pointed AT something. Fixing one real defect therefore hid
-- another — which is a property of the metric, not of either fix.
--
-- WHAT CHANGES. Every existing column keeps its exact name, type and meaning; nothing is removed or
-- redefined, so existing readers are unaffected. Two columns are ADDED, decomposing the net into its
-- two independent failure directions:
--   n_go_theses_without_position  — GO theses with no opened position in the same strategy+ticker.
--                                   Usually benign (staged and never filled, or superseded).
--   n_positions_without_go_thesis — opened positions with no GO thesis. This is the direction that
--                                   matters: capital was deployed with no decision of record.
--
-- THE NET IS DELIBERATELY RETAINED, not replaced. The two are complementary and neither subsumes the
-- other. The orphan counts match on (strategy, ticker), so they CANNOT see a count mismatch WITHIN one
-- ticker — and that case is now live, because strategies A/B/D may ADD to an open same-strategy
-- position (owner directive 2026-07-21), so one ticker can legitimately carry several positions and
-- several add-tranche GO rows. If a ticker ever ends up with 2 positions but 1 thesis, both orphan
-- counts stay 0 and only `go_minus_opened` moves. Conversely the cancelling-orphans case moves only
-- the orphan counts. Read all three together; alert on either signal.
--
-- MEASURED LIVE 2026-08-04 immediately before this file was written — B: go_theses 13,
-- positions_opened 13, go_minus_opened 0, n_go_theses_without_position 1 (OKTA),
-- n_positions_without_go_thesis 1 (BURL). D: 12 / 12 / 0 / 0 / 0, fully reconciled.
--
-- Ticker comparison is UPPER(TRIM(...)) on both sides so a stray case/whitespace difference between
-- the decision-log and position-event spellings cannot manufacture a phantom orphan.

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
  -- COUNT(DISTINCT position_key), NOT COUNT(*): the STAGING-OPEN KEY INVARIANT writes a provisional
  -- OPEN at staging and a second fill-reconciliation OPEN under the SAME position_key, and
  -- events.position_events is append-only so both persist. COUNT(*) double-counted every reconciled
  -- position. See bigquery/131's header for the adversarial checks proving DISTINCT does not
  -- under-count adds or re-opens (both mint their own position_key).
  SELECT strategy, COUNT(DISTINCT position_key) AS opened_count
  FROM `stock-trading-498512.events.position_events`
  WHERE event_type = 'OPEN'
  GROUP BY strategy
),
-- Distinct (strategy, ticker) keys on each side, for the orphan anti-joins below. DISTINCT matters:
-- without it a ticker holding several positions (adds) would be counted once per position.
thesis_keys AS (
  SELECT DISTINCT strategy, UPPER(TRIM(ticker)) AS tkr
  FROM `stock-trading-498512.analytics.thesis_outcomes`
  WHERE is_go_family AND ticker IS NOT NULL
),
position_keys AS (
  SELECT DISTINCT strategy, UPPER(TRIM(ticker)) AS tkr
  FROM `stock-trading-498512.events.position_events`
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
ORDER BY strategy;

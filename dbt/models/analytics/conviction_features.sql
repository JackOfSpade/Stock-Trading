-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql section (C):
-- analytics.conviction_features — canonical source is that file until owner cutover (was
-- bigquery/04_analytics.sql).
-- The supervised conviction layer's feature view: GO-family theses with conviction mapped to an
-- ordinal. BUILT NOW but its OUTPUTS are GATED until >=30 closed GO trades (overfit risk).
--
-- REBUILT 2026-07-30 (bigquery/116 section (C)): the GO filter is now the GO-FAMILY test
-- (t.is_go_family, matching 'GO' and 'GO (add tranche)') instead of the exact string decision = 'GO'.
-- Design decision made explicitly (owner directive 2026-07-30, delegated call): an add-tranche
-- thesis counts as its OWN conviction observation against the shared campaign outcome — D2's ADD
-- CANDIDATES step requires an add-tranche thesis be constructed "at the SAME rigor as a first entry"
-- and logged as its own decision-log row, so two independent predictions were made and one outcome
-- resolves both; that is two observations of the framework's calibration, not one. Previously the
-- D:GOOGL add-tranche GO was silently excluded (logged decision='GO (add tranche)') while the
-- semantically identical D:TSM add-tranche GO (logged plain 'GO') was included -- an accident of
-- string matching, not a design choice.
-- conviction_pct_normalized is passed through, appended LAST, as substrate for the new
-- analytics.conviction_pct_calibration view.

SELECT entry_id, entry_date, strategy, ticker, decision, conviction,
  CASE UPPER(conviction)
    WHEN 'LOW' THEN 1 WHEN 'MEDIUM-LOW' THEN 2 WHEN 'MEDIUM' THEN 3
    WHEN 'MEDIUM-HIGH' THEN 4 WHEN 'HIGH' THEN 5 WHEN 'HIGHEST' THEN 6 ELSE NULL END AS conviction_ordinal,
  sub_pattern, regime_state, position_closed, realized_pnl, was_profitable,
  conviction_pct_normalized
FROM {{ ref('thesis_outcomes') }}
WHERE is_go_family

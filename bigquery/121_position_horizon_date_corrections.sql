-- Position horizon-date corrections (2026-08-01).
-- Project: stock-trading-498512. Apply AFTER 117_invalidation_status_backfill.sql.
--
-- ONE-TIME DML, deliberately append-only. This migration corrects two metadata defects
-- diagnosed by M3 in Monthly_D_Position_Deep_Dive.md §F-4, without changing either
-- historical event or the authorizing thesis record:
--   * D:RTX:2026-04-27: time_exit_date=2027-04-27 / ltcg_date=NULL was transposed.
--     Strategy D has no maximum hold; 2027-04-27 is the passive LTCG marker.
--   * D:DIS:2026-05-07: ltcg_date was omitted; its authorizing entry specifies 2027-05-08.
--
-- Canonical decision-record provenance:
--   * RTX: events.decision_log.entry_id a98bc693-85e4-495d-bf16-ec10cddcc52d (2026-04-26 GO).
--   * DIS: events.decision_log.entry_id 86df19dd-654c-4222-a554-8e77c3a5b7c6 (2026-05-07 GO).
-- The decision log is immutable evidence, so this migration NEVER UPDATEs it. It also NEVER
-- UPDATEs or DELETEs events.position_events: a full-row ADJUST event is the only correction path.
--
-- Why full-row carry-forward matters: state.current_positions is latest-event-wins for EVERY
-- column (bigquery/01_schema.sql). An adjustment containing only the date fields would silently
-- NULL cost basis, shares, contract_id, invalidation_status, and other position metadata. Each
-- INSERT therefore selects the entire captured current row and substitutes only the diagnosed date
-- value(s).
--
-- Re-run behavior: before any write, each target must be exactly either its documented defective
-- state or its documented corrected state. A successful re-run sees both corrected states and
-- inserts zero rows. Any other state (including a closed/missing target or a divergent correction)
-- fails closed before DML, requiring investigation rather than overwriting an intervening event.

DECLARE correction_run_id STRING DEFAULT GENERATE_UUID();
DECLARE correction_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
DECLARE rtx_needs_correction BOOL;
DECLARE dis_needs_correction BOOL;

CREATE TEMP TABLE preflight AS
SELECT *
FROM `stock-trading-498512.state.current_positions`
WHERE position_key IN ('D:RTX:2026-04-27', 'D:DIS:2026-05-07');

-- Both targets must be open and represented exactly once by the latest-wins projection.
ASSERT (SELECT COUNT(*) FROM preflight) = 2
  AS 'Position-horizon correction refused: RTX and DIS must each have one open current-position row.';
ASSERT (SELECT COUNTIF(position_key = 'D:RTX:2026-04-27') FROM preflight) = 1
  AS 'Position-horizon correction refused: expected exactly one current RTX target row.';
ASSERT (SELECT COUNTIF(position_key = 'D:DIS:2026-05-07') FROM preflight) = 1
  AS 'Position-horizon correction refused: expected exactly one current DIS target row.';
ASSERT (SELECT COUNTIF(status = 'OPEN') FROM preflight) = 2
  AS 'Position-horizon correction refused: both target rows must be OPEN; closed positions are never adjusted.';

-- Confirm the immutable authorizing records still exist and match the documented identities.
ASSERT (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_id = 'a98bc693-85e4-495d-bf16-ec10cddcc52d'
    AND entry_date = DATE '2026-04-26'
    AND strategy = 'D'
    AND ticker = 'RTX'
    AND decision = 'GO'
) AS 'Position-horizon correction refused: RTX authorizing decision record is absent or does not match provenance.';
ASSERT (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_id = '86df19dd-654c-4222-a554-8e77c3a5b7c6'
    AND entry_date = DATE '2026-05-07'
    AND strategy = 'D'
    AND ticker = 'DIS'
    AND decision = 'GO'
) AS 'Position-horizon correction refused: DIS authorizing decision record is absent or does not match provenance.';

-- Fail closed unless the live row is the known defect or the exact desired result from a prior run.
ASSERT (
  SELECT COUNTIF(
    position_key = 'D:RTX:2026-04-27'
    AND (
      (time_exit_date = DATE '2027-04-27' AND ltcg_date IS NULL)
      OR (time_exit_date IS NULL AND ltcg_date = DATE '2027-04-27')
    )
  ) = 1
  FROM preflight
) AS 'Position-horizon correction refused: RTX dates are neither the documented defect nor the approved correction.';
ASSERT (
  SELECT COUNTIF(
    position_key = 'D:DIS:2026-05-07'
    AND (ltcg_date IS NULL OR ltcg_date = DATE '2027-05-08')
  ) = 1
  FROM preflight
) AS 'Position-horizon correction refused: DIS LTCG date is neither the documented defect nor the approved correction.';

SET rtx_needs_correction = (
  SELECT time_exit_date = DATE '2027-04-27' AND ltcg_date IS NULL
  FROM preflight
  WHERE position_key = 'D:RTX:2026-04-27'
);
SET dis_needs_correction = (
  SELECT ltcg_date IS NULL
  FROM preflight
  WHERE position_key = 'D:DIS:2026-05-07'
);

-- The two appends and ALL postconditions are atomic together. There is intentionally no
-- UPDATE/DELETE/MERGE on events.*. BigQuery transaction reads include this transaction's own INSERTs,
-- so the assertions below validate the projected ADJUST rows before they can commit.
BEGIN TRANSACTION;

-- Do not overwrite an adjustment appended after the preflight snapshot. The event identity must still
-- be the snapshot's identity immediately before either correction is written.
ASSERT (
  SELECT COUNT(*) = 2
  FROM `stock-trading-498512.state.current_positions` cp
  JOIN preflight pf USING (position_key)
  WHERE cp.event_id = pf.event_id
    AND cp.event_ts = pf.event_ts
    AND cp.status = 'OPEN'
) AS 'Position-horizon correction refused: a target position changed after preflight; re-run from a fresh snapshot.';

INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT
  GENERATE_UUID(), correction_ts, position_key, 'ADJUST', status, strategy, ticker, contract_id,
  cost_basis, shares, convergence_target,
  NULL AS time_exit_date,
  DATE '2027-04-27' AS ltcg_date,
  invalidation_status, conviction, model_at_entry, source_thesis_ref,
  CONCAT(
    'Append-only horizon-date correction (bigquery/121; run_id=', correction_run_id,
    '): RTX entry a98bc693-85e4-495d-bf16-ec10cddcc52d specifies no maximum hold. ',
    'Moved erroneous 2027-04-27 time_exit_date to ltcg_date; all non-date fields echoed unchanged.'
  )
FROM preflight
WHERE position_key = 'D:RTX:2026-04-27'
  AND time_exit_date = DATE '2027-04-27'
  AND ltcg_date IS NULL;

INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT
  GENERATE_UUID(), correction_ts, position_key, 'ADJUST', status, strategy, ticker, contract_id,
  cost_basis, shares, convergence_target,
  time_exit_date,
  DATE '2027-05-08' AS ltcg_date,
  invalidation_status, conviction, model_at_entry, source_thesis_ref,
  CONCAT(
    'Append-only horizon-date correction (bigquery/121; run_id=', correction_run_id,
    '): DIS entry 86df19dd-654c-4222-a554-8e77c3a5b7c6 specifies LTCG eligibility 2027-05-08. ',
    'Set only ltcg_date; all other fields echoed unchanged.'
  )
FROM preflight
WHERE position_key = 'D:DIS:2026-05-07'
  AND ltcg_date IS NULL;

-- Postconditions: latest projection contains the intended date values and all carried metadata agrees
-- with the captured preflight row. These checks run before COMMIT, so any failure rolls back both appends.
ASSERT (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.state.current_positions` cp
  JOIN preflight pf USING (position_key)
  WHERE cp.position_key = 'D:RTX:2026-04-27'
    AND cp.time_exit_date IS NULL
    AND cp.ltcg_date = DATE '2027-04-27'
    AND cp.status IS NOT DISTINCT FROM pf.status
    AND cp.strategy IS NOT DISTINCT FROM pf.strategy
    AND cp.ticker IS NOT DISTINCT FROM pf.ticker
    AND cp.contract_id IS NOT DISTINCT FROM pf.contract_id
    AND cp.cost_basis IS NOT DISTINCT FROM pf.cost_basis
    AND cp.shares IS NOT DISTINCT FROM pf.shares
    AND cp.convergence_target IS NOT DISTINCT FROM pf.convergence_target
    AND TO_JSON_STRING(cp.invalidation_status) IS NOT DISTINCT FROM TO_JSON_STRING(pf.invalidation_status)
    AND cp.conviction IS NOT DISTINCT FROM pf.conviction
    AND cp.model_at_entry IS NOT DISTINCT FROM pf.model_at_entry
    AND cp.source_thesis_ref IS NOT DISTINCT FROM pf.source_thesis_ref
) AS 'Position-horizon correction failed postcondition: RTX state is not the full-row carry-forward with corrected dates.';
ASSERT (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.state.current_positions` cp
  JOIN preflight pf USING (position_key)
  WHERE cp.position_key = 'D:DIS:2026-05-07'
    AND cp.time_exit_date IS NOT DISTINCT FROM pf.time_exit_date
    AND cp.ltcg_date = DATE '2027-05-08'
    AND cp.status IS NOT DISTINCT FROM pf.status
    AND cp.strategy IS NOT DISTINCT FROM pf.strategy
    AND cp.ticker IS NOT DISTINCT FROM pf.ticker
    AND cp.contract_id IS NOT DISTINCT FROM pf.contract_id
    AND cp.cost_basis IS NOT DISTINCT FROM pf.cost_basis
    AND cp.shares IS NOT DISTINCT FROM pf.shares
    AND cp.convergence_target IS NOT DISTINCT FROM pf.convergence_target
    AND TO_JSON_STRING(cp.invalidation_status) IS NOT DISTINCT FROM TO_JSON_STRING(pf.invalidation_status)
    AND cp.conviction IS NOT DISTINCT FROM pf.conviction
    AND cp.model_at_entry IS NOT DISTINCT FROM pf.model_at_entry
    AND cp.source_thesis_ref IS NOT DISTINCT FROM pf.source_thesis_ref
) AS 'Position-horizon correction failed postcondition: DIS state is not the full-row carry-forward with corrected LTCG date.';

-- If this run performed a correction, prove the corresponding append exists exactly once. On a clean
-- re-run rtx_needs_correction/dis_needs_correction are FALSE and no additional event is expected.
ASSERT NOT rtx_needs_correction OR (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.events.position_events`
  WHERE position_key = 'D:RTX:2026-04-27'
    AND event_type = 'ADJUST'
    AND event_ts = correction_ts
    AND note LIKE CONCAT('Append-only horizon-date correction (bigquery/121; run_id=', correction_run_id, '):%')
) AS 'Position-horizon correction failed postcondition: RTX ADJUST event was not appended exactly once.';
ASSERT NOT dis_needs_correction OR (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.events.position_events`
  WHERE position_key = 'D:DIS:2026-05-07'
    AND event_type = 'ADJUST'
    AND event_ts = correction_ts
    AND note LIKE CONCAT('Append-only horizon-date correction (bigquery/121; run_id=', correction_run_id, '):%')
) AS 'Position-horizon correction failed postcondition: DIS ADJUST event was not appended exactly once.';

COMMIT TRANSACTION;

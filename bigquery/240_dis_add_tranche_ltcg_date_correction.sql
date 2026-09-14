-- 240_dis_add_tranche_ltcg_date_correction.sql (2026-09-14)
-- Project: stock-trading-498512. Apply AFTER 237_park_axis_calibration.sql.
-- ONE-TIME DML, append-only. Mints the missing ltcg_date on D:DIS:2026-08-05, closing
-- ops.alerts 4ed7f677-52c4-44fa-9fd6-241b2aeb221e (M3, ltcg_date_missing, 2026-09-01).
--
-- THERE IS STILL NO STANDING MINTER, AND THAT IS THE SEPARATE FINDING THIS FILE DOES NOT CLOSE
-- (ops.alerts 790db3fa-697c-4d0c-bcb5-472b5836ea92, D3, ltcg_repair_names_nonexistent_d3_step).
-- That notice is correct: alert 4ed7f677 named its owning surface as "bigquery/121 ... via D3
-- self-heal sweep", and NO such route exists -- bigquery/121 is a closed one-time two-key DML
-- (D:RTX:2026-04-27, D:DIS:2026-05-07) and D3 has no horizon-date self-heal step at all; sweeping
-- every bigquery/*.sql that writes ltcg_date (01, 117, 121, 169, and now this file) plus all 34
-- task_plan slices finds no routine step that MINTS a missing one. bigquery/169 carries an
-- ALREADY-POPULATED value forward; it cannot originate one. So the class is repaired
-- PER INSTANCE, by a numbered file like this one, and a future reader should expect exactly that
-- rather than hunting for a sweep that was never built. Do NOT cite a D3 self-heal for this class.
--
-- WHY NULL: the 2026-08-05 staging OPEN never set ltcg_date (its authorizing entry,
-- events.decision_log 3021cbf0-f821-43ae-8c9f-5498f028243a, has no LTCG-date field). The
-- 2026-08-06 D2a fill-reconciliation row (ad1b980b-78eb-4d34-964f-fd48af23d0d1) correctly
-- echoed that NULL rather than inventing a value -- minting a horizon date is not D2a job.
--
-- WHY 2027-08-06, not the fill+1y+1day value an earlier draft of this fix proposed: an
-- adversarial review of that draft was verified live 2026-09-14 and its objections held:
--   * D:GEV:2026-08-03 (ltcg_date 2027-08-04) is NOT corroboration for +1 day. All 5 of its
--     own events.decision_log entries and its own staging-time position_events note
--     (1a9138ab-c2fe-4a38-aa13-23905f4ccad2) were read directly; none contain any LTCG-date
--     text. It is an unexplained number, not a traceable derivation.
--   * bigquery/121 -- the exact append-only mechanism this file replicates -- corrected RTX
--     (a position whose own authorizing decision_log entry a98bc693 carries no explicit LTCG
--     date, the same situation as this row) to fill+1y EXACT (2027-04-27) by RELABELING a
--     pre-existing mistagged time_exit_date value, per bigquery/121 own header. It applied no
--     formula at all, so it supports neither +1 day nor +1y-exact as a derivation precedent --
--     but it does mean the mechanism this file reuses has never produced a +1-day value.
--   * The book has a real, dominant, and -- unlike GEV -- explicitly documented convention:
--     three independent D2a fill-reconciliation notes state ltcg_date was set to the actual
--     fill date plus exactly one calendar year: D:AMZN:2026-07-30 ("ltcg_date 2027-07-31 set
--     from the ACTUAL fill date"), D:GOOGL:2026-07-26 ("No max hold; LTCG 2027-07-27"), and
--     D:TSM:2026-07-29 ("ltcg_date set from the ACTUAL fill date... (2027-07-30)"). D:DIS:
--     2026-08-05 own fill (2026-08-06, per the D2a note on ad1b980b) sits in the identical
--     D2a Step 0 fill-reconciliation context as those three, so the same literal rule applies:
--     2026-08-06 + 1y = 2027-08-06.
--   * This is one day short of IRS literal "held more than one year" LTCG test, and that
--     imprecision already sits unchallenged on 8-9 of the other 11 populated Strategy D
--     ltcg_date rows. strategy/06_strategy_d.md only ever describes the marker as a plain
--     "12-month" line (never a day-precise threshold), and the field only live consuming
--     reader (Claude_Task_Plan.md D2 EXITS TRIGGERED step: "within 30 days of 12-month
--     qualification") uses a 30-day window, so the exact day is inert to every wired gate.
--     Reconciling the book-wide fill+1y-exact-vs-+1-day split is a separate, deliberately
--     out-of-scope question; this file conforms the one NULL row to the dominant,
--     best-evidenced convention rather than inventing a new one.
--
-- Canonical decision-record provenance:
--   * Add-tranche thesis: events.decision_log.entry_id 3021cbf0-f821-43ae-8c9f-5498f028243a
--     (2026-08-05 GO, MEDIUM-HIGH conviction) -- confirms this IS the correct, live, OPEN
--     Strategy D DIS add-tranche position; it carries no LTCG-date text of its own, so the
--     value below comes from the sibling D2a convention re-verified below, not from this entry.
--
-- Never UPDATEs events.position_events or events.decision_log: a full-row ADJUST event is the
-- only correction path (bigquery/121 pattern). Re-run: before any write the target must be
-- exactly its documented defect (ltcg_date NULL) or its documented correction (=2027-08-06); a
-- clean re-run inserts zero rows; any other state fails closed before DML.

DECLARE correction_run_id STRING DEFAULT GENERATE_UUID();
DECLARE correction_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
DECLARE needs_correction BOOL;

CREATE TEMP TABLE preflight AS
SELECT * FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:DIS:2026-08-05';

ASSERT (SELECT COUNT(*) FROM preflight) = 1
  AS 'ltcg_date correction refused: expected exactly one current D:DIS:2026-08-05 row.';
ASSERT (SELECT status FROM preflight) = 'OPEN'
  AS 'ltcg_date correction refused: D:DIS:2026-08-05 must be OPEN.';

ASSERT (
  SELECT COUNT(*) = 1 FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_id = '3021cbf0-f821-43ae-8c9f-5498f028243a'
    AND entry_date = DATE '2026-08-05' AND strategy = 'D' AND ticker = 'DIS' AND decision = 'GO'
) AS 'ltcg_date correction refused: add-tranche authorizing decision record absent or mismatched.';

-- The value below rests on a live, repeated, explicitly-documented convention, not a one-time
-- citation: re-verify all three sibling notes still say what this file relies on before writing
-- anything. If the convention has drifted, fail closed rather than mint a stale value.
ASSERT (
  SELECT COUNT(*) = 3 FROM `stock-trading-498512.events.position_events`
  WHERE event_type = 'OPEN'
    AND (
      (position_key = 'D:AMZN:2026-07-30' AND ltcg_date = DATE '2027-07-31'
        AND note LIKE '%set from the ACTUAL fill date%')
      OR (position_key = 'D:GOOGL:2026-07-26' AND ltcg_date = DATE '2027-07-27'
        AND note LIKE '%LTCG 2027-07-27%')
      OR (position_key = 'D:TSM:2026-07-29' AND ltcg_date = DATE '2027-07-30'
        AND note LIKE '%set from the ACTUAL fill date%')
    )
) AS 'ltcg_date correction refused: the fill-date-plus-one-year sibling convention this file relies on (AMZN/GOOGL/TSM D2a notes) no longer reads as documented; re-derive before applying.';

ASSERT (SELECT ltcg_date IS NULL OR ltcg_date = DATE '2027-08-06' FROM preflight)
  AS 'ltcg_date correction refused: ltcg_date is neither the documented defect nor the approved fix.';

SET needs_correction = (SELECT ltcg_date IS NULL FROM preflight);

BEGIN TRANSACTION;

ASSERT (
  SELECT COUNT(*) = 1 FROM `stock-trading-498512.state.current_positions` cp
  JOIN preflight pf USING (position_key)
  WHERE cp.event_id = pf.event_id AND cp.event_ts = pf.event_ts AND cp.status = 'OPEN'
) AS 'ltcg_date correction refused: target changed after preflight; re-run from a fresh snapshot.';

INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT
  GENERATE_UUID(), correction_ts, position_key, 'ADJUST', status, strategy, ticker, contract_id,
  cost_basis, shares, convergence_target, time_exit_date,
  DATE '2027-08-06' AS ltcg_date,
  invalidation_status, conviction, model_at_entry, source_thesis_ref,
  CONCAT(
    'Append-only horizon-date correction (bigquery/240; run_id=', correction_run_id,
    '): mints ltcg_date from this tranche own fill date (2026-08-06, D2a note on event ',
    'ad1b980b-78eb-4d34-964f-fd48af23d0d1) plus exactly one calendar year, matching the ',
    'fill-date-plus-one-year convention documented in the D2a fill-reconciliation notes on ',
    'D:AMZN:2026-07-30, D:GOOGL:2026-07-26 and D:TSM:2026-07-29 -- the same Step 0 context this ',
    'fill sits in. Does NOT use fill+1y+1day: the only two live rows with that value are ',
    'D:DIS:2026-05-07 (a one-off derivation stated in decision_log 86df19dd prose) and ',
    'D:GEV:2026-08-03 (verified 2026-09-14 to have NO citable LTCG derivation in any of its 5 ',
    'decision_log entries or its own staging note). Repairs ops.alerts ',
    '4ed7f677-52c4-44fa-9fd6-241b2aeb221e. All non-date fields echoed unchanged.'
  )
FROM preflight WHERE ltcg_date IS NULL;

ASSERT (
  SELECT COUNT(*) = 1 FROM `stock-trading-498512.state.current_positions` cp
  JOIN preflight pf USING (position_key)
  WHERE cp.position_key = 'D:DIS:2026-08-05' AND cp.ltcg_date = DATE '2027-08-06'
    AND cp.time_exit_date IS NOT DISTINCT FROM pf.time_exit_date
    AND cp.status IS NOT DISTINCT FROM pf.status AND cp.strategy IS NOT DISTINCT FROM pf.strategy
    AND cp.ticker IS NOT DISTINCT FROM pf.ticker AND cp.contract_id IS NOT DISTINCT FROM pf.contract_id
    AND cp.cost_basis IS NOT DISTINCT FROM pf.cost_basis AND cp.shares IS NOT DISTINCT FROM pf.shares
    AND cp.convergence_target IS NOT DISTINCT FROM pf.convergence_target
    AND TO_JSON_STRING(cp.invalidation_status) IS NOT DISTINCT FROM TO_JSON_STRING(pf.invalidation_status)
    AND cp.conviction IS NOT DISTINCT FROM pf.conviction AND cp.model_at_entry IS NOT DISTINCT FROM pf.model_at_entry
    AND cp.source_thesis_ref IS NOT DISTINCT FROM pf.source_thesis_ref
) AS 'ltcg_date correction failed postcondition: not a full-row carry-forward with corrected ltcg_date.';
ASSERT NOT needs_correction OR (
  SELECT COUNT(*) = 1 FROM `stock-trading-498512.events.position_events`
  WHERE position_key = 'D:DIS:2026-08-05' AND event_type = 'ADJUST' AND event_ts = correction_ts
    AND note LIKE CONCAT('Append-only horizon-date correction (bigquery/240; run_id=', correction_run_id, ')%')
) AS 'ltcg_date correction failed postcondition: ADJUST event not appended exactly once.';

COMMIT TRANSACTION;

-- Post-apply verification:
--
-- SELECT position_key, event_type, status, ltcg_date, cost_basis, shares
-- FROM `stock-trading-498512.state.current_positions`
-- WHERE position_key = 'D:DIS:2026-08-05';
-- -- EXPECT: event_type ADJUST, status OPEN, ltcg_date 2027-08-06, cost_basis 45.89389582
-- -- (unchanged), shares 0.4422 (unchanged).
--
-- After live apply + scripts/check_live_sql_parity.py green, resolve the alert:
--
-- UPDATE `stock-trading-498512.ops.alerts`
-- SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
--     resolved_note = 'repaired by bigquery/240: ltcg_date minted 2027-08-06 (fill 2026-08-06 plus exactly one calendar year, matching the explicit D2a fill-reconciliation convention on D:AMZN:2026-07-30/D:GOOGL:2026-07-26/D:TSM:2026-07-29; the originally-proposed fill+1y+1day value was rejected on review -- its only two live instances, D:DIS:2026-05-07 and D:GEV:2026-08-03, are a one-off decision-log prose date and an undocumented number respectively, not a repeated convention)'
-- WHERE alert_id = '4ed7f677-52c4-44fa-9fd6-241b2aeb221e';

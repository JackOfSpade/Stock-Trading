-- INVALIDATION_STATUS MIRROR BACKFILL (2026-07-30 interactive session, owner directive "fix all").
-- Project: stock-trading-498512. Apply after 116_decision_record_analyzability.sql.
--
-- ONE-TIME DML, not DDL. This file INSERTs rows; it does not define objects. It is nonetheless SAFE TO
-- RE-RUN (see IDEMPOTENCE below), so a DR replay of bigquery/*.sql in order will not duplicate anything.
--
-- ============================================================================================
-- PROBLEM. state.current_positions.invalidation_status (JSON) is the structured mirror of a position's
-- AT-ENTRY thesis-invalidation criteria. It was populated for only 4 of 14 open positions -- the ones
-- opened 2026-07-26 or later, i.e. only since the field started being written. The other 10 were NULL,
-- with their criteria reachable only by reading the authorizing decision_log entry's body_md prose.
--
-- The system self-flagged this live: the 2026-07-29 D:TSM add-tranche entry
-- (32042c0f-ee93-45db-9e4a-8c76b0ffc497) states verbatim "state.current_positions.invalidation_status is
-- NULL on this row -- a mirroring gap, not an absence of criteria", and its own populated JSON says its
-- criteria are "inherited unmodified from parent tranche D:TSM:2026-07-21" -- while that PARENT row was
-- itself NULL. On 2026-07-28, D1's ADD-CANDIDATE CHECK evaluated all 11 open A/B/D positions and
-- declined TWO of them (D:DIS, D:TSM) at the Rev-40 HARD GATE citing exactly this NULL -- the other 9
-- declines that day turned on ordinary merits (no dip, time-stop imminent, churn), NOT on the gate.
-- That day's own process note is the primary source: "two declines (D:DIS, D:TSM) turned on *missing*
-- recorded invalidation criteria rather than on the merits ... legacy position rows without a populated
-- invalidation_status are structurally ineligible for adds regardless of how good the case is."
--
-- IMPORTANT SCOPE LIMIT -- this is a CONVENIENCE MIRROR, not a correctness fix. The Rev-40 HARD GATE
-- that actually decides whether an add is permitted reads the criteria from the position's ORIGINAL
-- ENTRY RECORD, independent of this field, and has been proven to do so correctly on D:RTX (2026-07-26)
-- and D:TSM (2026-07-29) precisely while this field was NULL. Nothing was mis-gated. What the NULLs cost
-- was QUERYABILITY: "how many open theses have breached their own stated invalidation criteria" silently
-- surfaced only the 4 newest positions.
--
-- ============================================================================================
-- METHOD -- TRANSCRIPTION, NOT DERIVATION. Every criterion below was read from the decision_log entry
-- that states it, by a dedicated per-position extraction pass (2026-07-30), and each is recorded with
-- the exact source entry_id it came from so any reader can re-verify against the authoritative record.
-- NOTHING WAS INVENTED, inferred, or reconstructed.
--
-- PRECISE FIDELITY CLAIM (do not overstate it -- an audit of this file on 2026-07-30 caught the original
-- wording claiming more than is true): the criteria are CONTENT-VERBATIM with ASCII-NORMALIZED
-- PUNCTUATION, not byte-identical. Four typographic characters in the source bodies were transcribed as
-- ASCII: U+2265 '>=' , U+2264 '<=' , em dash '--' , and Greek epsilon spelled '(epsilon)'. This affects
-- exactly the two long-form sources that contain non-ASCII punctuation, D:RTX (a98bc693) and D:DIS
-- (86df19dd); TSM/AMZN/CRM/UBER/GOOGL/ISRG sources are pure ASCII and match byte-for-byte. Reversing
-- those four substitutions makes every stored criterion an exact substring of its cited body_md, which
-- is the check a future auditor should run -- NOT a raw character-for-character diff, which will show
-- these four differences and must not be read as content having been altered. No criterion was dropped,
-- added, reworded, split, merged or truncated.
--
-- Specifically NOT done:
--   * No criterion was synthesized for a position whose entry did not state one (see the two Strategy B
--     rows below, which get an explicit NOT_DISCRETELY_RECORDED_AT_ENTRY marker instead).
--   * No BREACH STATUS is asserted. This backfill did NOT evaluate any criterion against today's data,
--     so every row carries breach_status='NOT_ASSESSED_BY_THIS_BACKFILL'. Writing "unbreached" would be
--     a judgment this pass never made -- and the existing D:GOOGL:2026-07-26 row's per-criterion
--     "unbreached" values were written by a session that DID evaluate them at the time. Do not
--     retro-fit that shape here.
--   * Where an entry stated a reassessment milestone or time-exit DISTINCT from its invalidation
--     criteria (D:RTX's Q1'27 falsifiable-milestone reassessment), it is recorded separately rather than
--     folded in as a criterion -- the entry itself draws that distinction ("runs to thesis-invalidation
--     by (i)-(vi) above OR negative outcome on the falsifiable-milestone reassessment").
--   * D:RTX's earlier DRAFT included a SEVENTH, price-based criterion ("stock breaks $130 on heavy
--     volume") which that same entry explicitly records as DROPPED for contradicting Strategy D's
--     no-stop design. It is correctly ABSENT below. Six criteria, not seven.
--
-- THE TWO STRATEGY B POSITIONS GET NO CRITERIA, DELIBERATELY. B:MDT:2026-06-17 and B:ISRG:2026-07-21
-- both pre-date the 2026-07-21 Rev-40 directive and are mean-reversion entries: they exit on a
-- MECHANICAL convergence-target / time-exit, and their entries' numbered "CRITERION (1)-(5)" blocks are
-- the ENTRY-SIDE pass/fail gate (close-to-close magnitude, mispricing-vs-consensus, convergence-target
-- validity, adversarial check, A-queue non-conflict) -- NOT thesis-invalidation criteria. Conflating the
-- two would have manufactured five bogus "invalidation criteria" per position. They instead get an
-- explicit machine-readable marker so a future count query can distinguish "no data" from "no criteria
-- BY DESIGN" -- a distinction that is itself the useful signal, and which a NULL cannot express.
--
-- ============================================================================================
-- CARRY-FORWARD SAFETY -- THE TRAP THIS FILE IS BUILT AROUND. state.current_positions is
--   SELECT * FROM events.position_events QUALIFY ROW_NUMBER() OVER (PARTITION BY position_key
--   ORDER BY event_ts DESC) = 1  ... WHERE event_type <> 'CLOSE'      (bigquery/01_schema.sql:129)
-- i.e. PURE LATEST-ROW-WINS ON EVERY COLUMN, with NO coalescing across rows. An ADJUST row that set
-- invalidation_status and left cost_basis / shares / contract_id / ltcg_date unset would NULL THEM OUT
-- for that position -- silently breaking state.position_reconciliation (which SUMs shares), cost-basis
-- accounting, and the LTCG marker. On a live trading book that is a serious corruption, not a nit.
--
-- So each statement below is INSERT ... SELECT **FROM state.current_positions itself**, echoing every
-- existing column back verbatim and substituting ONLY invalidation_status (plus a fresh event_id /
-- event_ts, event_type='ADJUST', and a provenance note). No field value is hand-retyped, so no field
-- can be hand-mistyped. ADJUST-for-metadata-sync is the established pattern here -- D:DIS, D:RTX and
-- B:MDT's current rows are themselves ADJUST rows.
--
-- APPEND-ONLY PRESERVED: these are INSERTs. No existing row is UPDATEd or DELETEd, so
-- state.append_only_integrity's tripwire stays quiet (only decision_log.sub_pattern has a sanctioned
-- UPDATE exception -- ops/RUNBOOK.md 21 -- and this is not that).
--
-- IDEMPOTENCE: every statement carries `AND invalidation_status IS NULL`. After the first successful
-- run, the position's LATEST row is the ADJUST row written here, which HAS invalidation_status -- so a
-- re-run matches zero rows and inserts nothing. Re-running this whole file is a no-op by construction.
--
-- EDITOR TRAP, hit twice while writing this file -- BigQuery does NOT use SQL-standard '' doubling to
-- escape a quote inside a string literal. It reads adjacent literals as CONCATENATION and fails with
-- "concatenated string literals must be separated by whitespace or comments". Use a BACKSLASH (\') as
-- below, or a triple-quoted '''...''' literal (which also lets an inner " through untouched). Verified
-- live: 'x Q1\'27' = '''x Q1'27''' is TRUE, so both forms are interchangeable and this file replays
-- byte-identically to what was applied. Several criteria below legitimately contain BOTH an apostrophe
-- and inner double quotes (D:DIS's metric-immutability item), so do not "simplify" the quoting.
-- ============================================================================================


-- ---------- D:RTX:2026-04-27 -- source a98bc693-85e4-495d-bf16-ec10cddcc52d (2026-04-26 GO) ----------
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    'a98bc693-85e4-495d-bf16-ec10cddcc52d' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'Material adverse Airbus damages ruling > $2B' AS invalidation_1,
    'New powder-metal-style mass quality event > $1B incremental charge' AS invalidation_2,
    'GTF Advantage EIS slips beyond Q1\'27' AS invalidation_3,
    'Backlog declines two consecutive quarters' AS invalidation_4,
    'FY26 FCF guide cut below $7.5B floor' AS invalidation_5,
    'FY27 defense procurement cut >=10% YoY' AS invalidation_6,
    'Falsifiable-milestone reassessment at Q1\'27 earnings -- a SEPARATE trigger, not an invalidation criterion, per the entry\'s own "runs to thesis-invalidation by (i)-(vi) above OR negative outcome on the falsifiable-milestone reassessment"' AS reassessment_milestone,
    'An earlier draft criterion "stock breaks $130 on heavy volume" was explicitly DROPPED by the entry itself as contradicting Strategy D\'s no-stop design; six criteria is the final list.' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from a98bc693; none invented; breach status NOT assessed by this backfill. All other fields echoed forward unchanged from the prior row.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:RTX:2026-04-27' AND invalidation_status IS NULL;


-- ---------- D:DIS:2026-05-07 -- source 86df19dd-654c-4222-a554-8e77c3a5b7c6 (2026-05-07 GO) ----------
-- NOTE this position's source_thesis_ref is NULL, so the entry was identified structurally: 86df19dd is
-- the ONLY decision_log row for strategy='D' AND ticker='DIS', its entry_date matches the position_key's
-- date suffix exactly, its decision is GO, and its text frames itself as the fresh Subtype-B thesis
-- construction that authorized this entry. Checked for inherit-from-earlier language ("verbatim",
-- "carried"): none -- the 2026-04-26 DIS NO-GO is referenced as prior context only, not as a criteria
-- source. Criteria here are long-form prose in the original (unlike the terse Strategy-D norm) and are
-- reproduced verbatim, markdown emphasis included.
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    '86df19dd-654c-4222-a554-8e77c3a5b7c6' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    '**Primary invalidation -- SVOD margin floor.** Entertainment SVOD operating margin falls below 8% for 2 consecutive quarters. Two-consecutive-quarter framing prevents single-quarter content-spend lumpiness from auto-invalidating; sustained breach below the Q1 FY26 8.4% baseline (-40bps tolerance for measurement noise) trips invalidation. Mechanism-enforced via 8-K segment reporting at quarter-end.' AS invalidation_1,
    '**Secondary invalidation -- FY26 EPS guide cut.** Disney 8-K issues guide cut materially below the FY26 ~12% adj EPS growth ex-53rd-week framing. Materially defined as: revised FY26 adj EPS growth guide <=6% (i.e., a >6 percentage point cut from current ~12% midpoint). Mechanism-enforced via 8-K guidance reaffirmation/update at quarterly print.' AS invalidation_2,
    '**Buyback invalidation -- pace fall.** FY26 actual buyback execution falls materially below $7B run-rate (i.e., <=$3B by mid-fiscal-year H1 close per 10-Q cash flow disclosure, <=$5B at Q3 FY26 print, or 8-K announcement of suspended/reduced buyback program). Mechanism-enforced via 10-Q cash flow disclosure + 8-K capital allocation announcements.' AS invalidation_3,
    '**Metric-immutability auto-invalidation (rev 30 mechanism).** If Disney restructures segment reporting such that "Entertainment SVOD operating income" or "Entertainment SVOD operating margin" stops being disclosed in its current form for >=2 consecutive quarters (e.g., rolled into a new aggregate that doesn\'t permit isolating SVOD economics; redefined to non-comparable metric; eliminated entirely), the thesis auto-invalidates as of the date the second non-conforming quarterly report is released. This is the rev 30 metric-immutability protection against thesis-evading reporting changes.' AS invalidation_4,
    '**Regulatory-impairment escalation (KL #4 boundary case).** FCC issues a final order materially restricting Disney TV-station ownership AND Disney 8-Ks the development as material adverse impact to FY26/FY27 EPS framework. Triggers pre-emptive thesis review (NOT auto-invalidation; reviewed in fresh thesis-construction session). This is the (epsilon) adversarial-weight item escalation gate.' AS invalidation_5,
    'invalidation_5 is an ESCALATION-to-review trigger, not an auto-invalidation, per its own text.' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from 86df19dd (identified structurally -- source_thesis_ref is NULL on this position; 86df19dd is the only D/DIS decision_log row and its date matches the position_key). Breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:DIS:2026-05-07' AND invalidation_status IS NULL;


-- ---------- D:AMZN:2026-07-09 -- source c39e644a-9601-4faa-8b62-d522bf092dd3 (2026-07-08 GO) ----------
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    'c39e644a-9601-4faa-8b62-d522bf092dd3' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'AWS YoY <18% 2 consec Q' AS invalidation_1,
    'AWS op-margin <~30% 2 consec Q' AS invalidation_2,
    'AWS backlog declines seq 2 consec Q' AS invalidation_3,
    'Anthropic/OpenAI commits renegotiated down/churned' AS invalidation_4,
    'metric-immutability if AWS segment reporting restructures >=2Q' AS invalidation_5,
    'No max hold; LTCG marker 2027-07-09.' AS horizon_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from c39e644a; breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:AMZN:2026-07-09' AND invalidation_status IS NULL;


-- ---------- D:CRM:2026-07-09 -- source 0c68c3c1-1a62-4943-ada5-1d59d0d60c32 (2026-07-08 GO) ----------
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    '0c68c3c1-1a62-4943-ada5-1d59d0d60c32' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'Agentforce/Data-360 ARR growth <~50% YoY' AS invalidation_1,
    'cRPO <10% cc 2 consec Q' AS invalidation_2,
    'non-GAAP op margin contracts YoY' AS invalidation_3,
    'FY27 rev guide cut <~10%' AS invalidation_4,
    'metric-immutability if Agentforce ARR stops being disclosed in original form >=2Q (CRM moving to disaggregated revenue reporting FY28)' AS invalidation_5,
    'No max hold; LTCG marker 2027-07-09.' AS horizon_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from 0c68c3c1; breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:CRM:2026-07-09' AND invalidation_status IS NULL;


-- ---------- D:UBER:2026-07-09 -- source d2a37460-13e6-454a-b82e-e0e48a30b091 (2026-07-08 GO) ----------
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    'd2a37460-13e6-454a-b82e-e0e48a30b091' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'GB cc YoY <~15% 2 consec Q' AS invalidation_1,
    'adj-EBITDA margin (% of GB) contracts YoY 2 consec Q' AS invalidation_2,
    'Uber One membership stalls/declines seq' AS invalidation_3,
    'metric-immutability if GB disclosure structurally changes' AS invalidation_4,
    'No max hold; LTCG marker 2027-07-09.' AS horizon_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from d2a37460; breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:UBER:2026-07-09' AND invalidation_status IS NULL;


-- ---------- D:GOOGL:2026-07-09 -- source 706bf712-2292-4205-ba15-136c1392e4ea (2026-07-08 GO) ----------
-- CROSS-VALIDATED: the LATER, separate add tranche D:GOOGL:2026-07-26 already carries a populated
-- invalidation_status whose keys are a_cloud_rev_yoy_lt20_2q / b_cloud_margin_contraction_2q /
-- c_cloud_rpo_seq_decline_2q / d_adverse_structural_remedy -- the same four criteria plus
-- metric-immutability transcribed here, independently confirming this list. That row's per-criterion
-- "unbreached" VALUES are NOT copied: they were an assessment made on 2026-07-26, not by this backfill.
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    '706bf712-2292-4205-ba15-136c1392e4ea' AS source_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'Cloud rev YoY <20% 2 consec Q' AS invalidation_1,
    'Cloud op-margin contracts 2 consec Q' AS invalidation_2,
    'Cloud RPO/backlog declines seq 2 consec Q' AS invalidation_3,
    'adverse structural remedy' AS invalidation_4,
    'metric-immutability if Cloud rev stops being reported comparably >=2Q' AS invalidation_5,
    'Cross-validated against the D:GOOGL:2026-07-26 add tranche\'s independently-written invalidation_status keys (a_/b_/c_/d_ + metric-immutability): same criteria set.' AS provenance_note,
    'No max hold; LTCG marker 2027-07-09.' AS horizon_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from 706bf712, cross-validated against the 2026-07-26 add tranche; breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:GOOGL:2026-07-09' AND invalidation_status IS NULL;


-- ---------- D:ISRG:2026-07-20 -- source 82f3bc45-bdf5-46e0-bc4b-c98ade6e7e8a (2026-07-08 DEFER) ----------
-- CHAIN: source_thesis_ref points at the 2026-07-17 GO (9de1893a-3bdf-4ce1-a06b-47d3c30f58a7), which
-- only RE-EVALUATES the criteria with results interleaved rather than restating them. The canonical
-- statement is one entry earlier, in the 2026-07-08 DEFER under an explicit
-- "INVALIDATION (record on future entry):" label -- that is the wording transcribed here.
-- NOTE a SEPARATE Strategy B ISRG position exists (B:ISRG:2026-07-21) with a different thesis entirely.
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    '82f3bc45-bdf5-46e0-bc4b-c98ade6e7e8a' AS source_entry_id,
    '9de1893a-3bdf-4ce1-a06b-47d3c30f58a7' AS authorizing_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'procedure growth <10% YoY 2 consec Q' AS invalidation_1,
    'placements decline YoY 2 consec Q' AS invalidation_2,
    'recurring-rev decouples down from procedures' AS invalidation_3,
    'competitor discloses displacing dV at named large IDNs' AS invalidation_4,
    'Criteria wording taken from the 2026-07-08 DEFER\'s labelled "INVALIDATION (record on future entry):" block; the 2026-07-17 GO named in source_thesis_ref re-evaluates them with results interleaved rather than restating them cleanly. No max hold.' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from 82f3bc45 (the 2026-07-08 DEFER that states them); authorizing GO was 9de1893a. Breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:ISRG:2026-07-20' AND invalidation_status IS NULL;


-- ---------- D:TSM:2026-07-21 -- source a78dac64-6e69-4345-b5f3-7174116bee72 (2026-07-08 DEFER) ----------
-- THE ROW THE SYSTEM ITSELF FLAGGED. Its own child tranche (D:TSM:2026-07-29) says its criteria are
-- "inherited unmodified from parent tranche D:TSM:2026-07-21" while this parent was NULL.
-- CHAIN: source_thesis_ref 'D2 2026-07-17 TSM D GO' -> 0edb56ed (2026-07-17 GO, states them only as a
-- re-worded "Invalidation check") -> a78dac64 (2026-07-08 DEFER, the labelled verbatim source).
-- TRIPLE-CONFIRMED: this wording matches, character for character, what the 2026-07-29 add-tranche entry
-- (32042c0f) quotes under "INHERITED COMPLETION/INVALIDATION CRITERIA (quoted, unmodified...)".
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'transcribed_verbatim_from_entry_record' AS source,
    'a78dac64-6e69-4345-b5f3-7174116bee72' AS source_entry_id,
    '0edb56ed-a45a-42fb-9819-8753840a570c' AS authorizing_entry_id,
    'NOT_ASSESSED_BY_THIS_BACKFILL' AS breach_status,
    'GM <55% OR USD rev YoY <15% 2 consec Q' AS invalidation_1,
    'N2/A16 ramp pushed out OR <7nm share declines 2 consec Q' AS invalidation_2,
    'structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop)' AS invalidation_3,
    'Wording verbatim from the 2026-07-08 DEFER\'s "INVALIDATION (record on future entry):" block; identical to what the 2026-07-29 add-tranche entry 32042c0f quotes as inherited-unmodified. No max hold.' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status mirrored from the at-entry thesis record (bigquery/117 backfill 2026-07-30). Criteria verbatim from a78dac64 (2026-07-08 DEFER); authorizing GO was 0edb56ed. This is the row the 2026-07-29 add-tranche entry flagged as "a mirroring gap, not an absence of criteria". Breach status NOT assessed. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'D:TSM:2026-07-21' AND invalidation_status IS NULL;


-- ---------- B:MDT:2026-06-17 -- NO DISCRETE CRITERIA AT ENTRY (deliberate marker, not a transcription) ----------
-- source ba8a060c-db69-403a-8b58-39436452a856 (2026-06-03 GO; note entry_type='other' on that row).
-- Its five numbered "Criterion" items are the Strategy-B ENTRY-SIDE pass/fail gate (close-to-close
-- magnitude, mispricing vs consensus, convergence-target validity, adversarial check, A-queue
-- non-conflict), NOT thesis-invalidation criteria. Recording them as invalidation criteria would have
-- fabricated five constraints the entry never asserted. Strategy B exits MECHANICALLY.
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'NOT_DISCRETELY_RECORDED_AT_ENTRY' AS status,
    'ba8a060c-db69-403a-8b58-39436452a856' AS source_entry_id,
    'mechanical convergence-target / time-exit per Strategy B design; no discrete thesis-invalidation criteria beyond that were enumerated at entry' AS exit_mechanism,
    'This position pre-dates the 2026-07-21 Rev-40 directive. The entry\'s five numbered "Criterion" items are the ENTRY-SIDE pass/fail gate, not invalidation criteria, and were deliberately NOT transcribed as such. This marker exists so a count query can distinguish "no data" from "no criteria BY DESIGN".' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status set to an explicit NOT_DISCRETELY_RECORDED_AT_ENTRY marker (bigquery/117 backfill 2026-07-30) -- Strategy B mean-reversion entry exits mechanically on convergence-target/time-exit; no criteria were invented. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'B:MDT:2026-06-17' AND invalidation_status IS NULL;


-- ---------- B:ISRG:2026-07-21 -- NO DISCRETE CRITERIA AT ENTRY (deliberate marker) ----------
-- source f90e7c15-cf35-4979-9549-dc15771aae99 (2026-07-20 GO). NOTE this is one of the fourteen rows of
-- the 2026-07-20..22 entry_type='thesis' drift incident that bigquery/116 recovers -- the same entry that
-- was invisible to every calibration view. Same Strategy-B reasoning as B:MDT above: its "CRITERIA
-- (1)-(5)" block is the entry-side GO/NO-GO gate, not invalidation criteria.
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), position_key, 'ADJUST', status, strategy, ticker,
  contract_id, cost_basis, shares, convergence_target, time_exit_date, ltcg_date,
  PARSE_JSON(TO_JSON_STRING(STRUCT(
    DATE '2026-07-30' AS mirrored_on,
    'NOT_DISCRETELY_RECORDED_AT_ENTRY' AS status,
    'f90e7c15-cf35-4979-9549-dc15771aae99' AS source_entry_id,
    'mechanical convergence-target / time-exit per Strategy B design; no discrete thesis-invalidation criteria beyond that were enumerated at entry' AS exit_mechanism,
    'The entry\'s "CRITERIA (1)-(5)" block is the Strategy-B entry-side GO/NO-GO gate, not invalidation criteria, and was deliberately NOT transcribed as such. This entry is also one of the fourteen entry_type=\'thesis\' drift rows recovered by bigquery/116.' AS provenance_note
  ))),
  conviction, model_at_entry, source_thesis_ref,
  'invalidation_status set to an explicit NOT_DISCRETELY_RECORDED_AT_ENTRY marker (bigquery/117 backfill 2026-07-30) -- Strategy B mean-reversion entry exits mechanically; no criteria were invented. All other fields echoed forward unchanged.'
FROM `stock-trading-498512.state.current_positions`
WHERE position_key = 'B:ISRG:2026-07-21' AND invalidation_status IS NULL;


-- ============================================================================
-- VERIFICATION. Run after applying; every row must read PASS.
-- ============================================================================
-- NOTE on this comment style: these verification queries are `--` comment lines, NOT a /* */
-- block. That is DELIBERATE and load-bearing. scripts/check_live_sql_parity.py's extract_body()
-- runs to END OF FILE when no further CREATE follows, and normalize_tail() strips trailing
-- blank/`--` lines but NOT a trailing /* */ block -- so a block comment here gets folded into the
-- object's EXPECTED body and can never match the live definition, reporting DRIFT forever and
-- sending D3's self-heal into a pointless re-apply loop. Measured 2026-07-30: these three files
-- were the ONLY ones in bigquery/ using a trailing /* */ harness, and it made
-- state.add_candidate_reviews and analytics.find_precedents drift permanently. Keep `--`.
-- WITH checks AS (
--   SELECT 'all 14 open positions now carry invalidation_status' AS check_name,
--          (SELECT COUNTIF(invalidation_status IS NULL) FROM `stock-trading-498512.state.current_positions`) = 0 AS ok
--   UNION ALL SELECT 'still exactly 14 open positions (no dupes minted)',
--     (SELECT COUNT(*) FROM `stock-trading-498512.state.current_positions`) = 14
--   UNION ALL SELECT 'CRITICAL: no open position lost cost_basis or shares',
--     (SELECT COUNTIF(cost_basis IS NULL OR shares IS NULL) FROM `stock-trading-498512.state.current_positions`) = 0
--   -- Pre-backfill values captured live 2026-07-30 immediately before applying: 14 open positions,
--   -- 10 NULL invalidation_status, SUM(shares)=4.2296, SUM(cost_basis)=905.020719, 0 NULL money fields.
--   UNION ALL SELECT 'CRITICAL: total book shares unchanged vs pre-backfill (4.2296)',
--     (SELECT ROUND(SUM(shares), 6) FROM `stock-trading-498512.state.current_positions`) = 4.2296
--   UNION ALL SELECT 'CRITICAL: total cost_basis unchanged vs pre-backfill (905.020719)',
--     (SELECT ROUND(SUM(cost_basis), 6) FROM `stock-trading-498512.state.current_positions`) = 905.020719
--   UNION ALL SELECT 'the 2 Strategy B rows carry the honest marker, not invented criteria',
--     (SELECT COUNTIF(JSON_VALUE(invalidation_status, '$.status') = 'NOT_DISCRETELY_RECORDED_AT_ENTRY')
--      FROM `stock-trading-498512.state.current_positions`) = 2
--   UNION ALL SELECT 'no backfilled row asserts a breach verdict it did not evaluate',
--     (SELECT COUNTIF(JSON_VALUE(invalidation_status, '$.breach_status') = 'NOT_ASSESSED_BY_THIS_BACKFILL')
--      FROM `stock-trading-498512.state.current_positions`) = 8
--   UNION ALL SELECT 'D:TSM parent now carries the criteria its child claimed to inherit',
--     (SELECT JSON_VALUE(invalidation_status, '$.invalidation_1') = 'GM <55% OR USD rev YoY <15% 2 consec Q'
--      FROM `stock-trading-498512.state.current_positions` WHERE position_key = 'D:TSM:2026-07-21')
--   UNION ALL SELECT 'IDEMPOTENT: re-running this file inserts nothing',
--     (SELECT COUNTIF(invalidation_status IS NULL) FROM `stock-trading-498512.state.current_positions`) = 0
-- )
-- SELECT check_name, IF(ok, 'PASS', '*** FAIL ***') AS result FROM checks ORDER BY result, check_name;

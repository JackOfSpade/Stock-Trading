-- SL1 research-lead normalization + append-only record corrections (2026-08-03).
-- Project: stock-trading-498512.
--
-- WHY:
--   * Candidate H proved that a research-grade A1 idea could be emitted as a NEW candidate even when
--     its own source said §5.5 guardrails failed and no prospective detector existed. Default-REJECT
--     then burned the archetype's 90-day cooldown exactly as the evidence predicted.
--   * SL1's 2026-08-03 zero-synthesis result correctly preserved disclosure information-surprise as a
--     research lead, but only inside free-form heartbeat JSON/prose. This table makes leads queryable
--     without pretending they are candidates or giving them cooldowns.
--   * The 2026-07-27 heartbeat's joint conclusion that the DOWN gap was capital-gated depended on two
--     facts later disproved: fractional shorting is available, and the flat $40 max-loss budget was
--     retired. Append-only replacements make the stale heartbeats final-ineffective. Candidate F's
--     independent rejection did not use those premises and is untouched. Candidate G remains rejected
--     solely on its capital-independent variance-risk-premium / VVIX timing objection.
--
-- Depends on bigquery/35 (strategy_candidates/lifecycle/rails), bigquery/116 (current
-- ops.sp_log_decision), and bigquery/122 (superseded_by final-effective semantics). Re-run safe.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.strategy_research_leads` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  lead_id STRING NOT NULL,
  event_type STRING NOT NULL,            -- OPEN | UPDATED | CONVERTED | CLOSED
  source_routine STRING,
  archetype STRING NOT NULL,
  mechanism STRING,
  cited_edges ARRAY<STRING>,
  cited_disadvantages ARRAY<STRING>,
  target_regime_cells ARRAY<STRING>,     -- two-token SPY_TREND/VIX_REGIME coverage keys
  evidence_status STRING,
  blocker STRING,
  next_step STRING,
  source_decision_entry_id STRING,
  converted_candidate_code STRING,
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY DATE(event_ts) CLUSTER BY lead_id, event_type
OPTIONS(description='Append-only SISA research leads. A lead is not a strategy candidate, creates no lifecycle REJECTED row, and carries no archetype cooldown. Latest event per lead_id is current.');

-- source_decision_entry_id is a POINT-IN-TIME pointer, not a final-effective one. This file's own
-- second correction block supersedes 789de922 (the heartbeat both leads below name), so resolving this
-- column through the bigquery/122 final-effective filter -- entry_id NOT IN (SELECT superseded_by ...)
-- -- returns ZERO rows even though the entry exists and is correct. That is intended: the lead was
-- opened by that specific run, and repointing it at the replacement would misstate its provenance.
-- Stated on the column so a future reader does not join it the way bigquery/122's views join.
-- Idempotent and separate from the CREATE above, which does not re-run once the table exists.
ALTER TABLE `stock-trading-498512.events.strategy_research_leads`
  ALTER COLUMN source_decision_entry_id
  SET OPTIONS(description='Point-in-time provenance: the events.decision_log entry_id of the run that opened or last updated this lead. Deliberately NOT resolved through the superseded_by chain -- it may name a row later superseded, which the bigquery/122 final-effective filter excludes. Look the entry_id up directly; do not join it to a final-effective decision_log view and expect a match.');

INSERT INTO `stock-trading-498512.events.strategy_research_leads`
  (lead_id, event_type, source_routine, archetype, mechanism, cited_edges, cited_disadvantages,
   target_regime_cells, evidence_status, blocker, next_step, source_decision_entry_id, note)
SELECT
  'sl1-2026-08-disclosure-information-surprise', 'OPEN', 'SL1',
  'disclosure-information-surprise',
  'LLM-modeled information surprise in public-company disclosures; idiosyncratic return signal intended to remain usable in SPY-DOWN regimes.',
  ['1.6','1.1'], [], ['DOWN/LOW','DOWN/NORMAL','DOWN/HIGH'],
  'Magnitude, holding period, and cost robustness unverified; same-lab related paper withdrawn after failed replication.',
  'The RFS-track Representations of Investor Beliefs regression tables were unavailable; abstract-level claims cannot clear SL1 rail (a).',
  'Obtain and inspect the actual regression tables; quantify out-of-sample return magnitude, holding period, transaction-cost robustness, and weigh the Bloated Disclosures withdrawal as a same-lab robustness discount.',
  '789de922-da85-4451-bf9c-340c0a52ee57',
  'Preserved instead of synthesizing: default-REJECT on today\'s ambiguity would force immediate rejection and unnecessarily consume the archetype cooldown.'
-- One-row source. A SELECT of bare literals cannot carry a WHERE clause in GoogleSQL
-- ("Query without FROM clause cannot have a WHERE clause"), so the idempotency guard needs a FROM.
FROM (SELECT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.strategy_research_leads`
  WHERE lead_id = 'sl1-2026-08-disclosure-information-surprise'
);

INSERT INTO `stock-trading-498512.events.strategy_research_leads`
  (lead_id, event_type, source_routine, archetype, mechanism, cited_edges, cited_disadvantages,
   target_regime_cells, evidence_status, blocker, next_step, source_decision_entry_id, note)
SELECT
  'a1-2026-2.20-heterogeneous-regime', 'OPEN', 'A1',
  'heterogeneous-regime-momentum-participation',
  'Prospectively detect a heterogeneous-agent bubbling regime and participate within bounded risk.',
  [], ['2.20'], [],
  'Research hypothesis only: §5.5 guardrails 1 and 2 fail; 2.20 is version-pending and explicitly not reduced or relaxed.',
  'No current-Claude support for the claimed participation rate and no prospective out-of-sample regime detector, countable signal, frequency, invalidation, or kill structure.',
  'Require at least three independent same-direction sources including current-Claude evidence or valid architectural generality, plus a prospective detector with a countable signal and complete invalidation/kill specification.',
  '789de922-da85-4451-bf9c-340c0a52ee57',
  'Candidate H remains historically REJECTED with its original cooldown. This lead preserves only the future research question; it does not reopen or bypass that cooldown.'
FROM (SELECT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.strategy_research_leads`
  WHERE lead_id = 'a1-2026-2.20-heterogeneous-regime'
);

-- state.strategy_candidates is explicitly a mutable registry. Correct G's current reason while
-- preserving status and cooldown. F is deliberately untouched: its actual rejection rests on its
-- independent edge-validity, park-router redundancy, and excess-over-park failures.
UPDATE `stock-trading-498512.state.strategy_candidates`
SET reject_reason = '''REJECTED by SL1 STEP 3 on rail (a), cited-edge validity / positive expectancy.

CAPITAL-INDEPENDENT DECISIVE GROUND. Entering long index convexity after volatility has already risen is a documented negative-expectancy trade. The variance risk premium is one of the most robust findings in derivatives pricing (Carr & Wu, RFS 2009): index option buyers lose money on average as compensation for bearing crash risk. The timing penalty is conditional and measured: FEDS 2013-54 finds a one-standard-deviation rise in VVIX predicts a 1.32%-2.19% decrease in next-day SPX put returns, so the proposed DOWN/HIGH-VIX gate fires precisely when the hedge is dearest. Long-run tail-hedge cost remains adverse, and edge 1.5 supports sizing/scenario analysis but supplies no positive expectancy for buying the structure.

WITHDRAWN HISTORICAL GROUND. The original rail-(d) rejection used a $40 max-loss budget derived from the retired flat 2%-of-$2,000 rule. Experiment_Parameters.md rev 18 replaced that rule the next day with thesis-scaled Capital-at-Risk and a per-name envelope of about $200 at the probe floor. That arithmetic is obsolete and is not a current rejection ground. Fractional shorting evidence (0.42% equity-pair round trip; 0.25%-0.43% sampled borrow) separately retracts the old heartbeat's claim that every market-neutral alternative is execution-infeasible; it does not by itself prove an option vertical fillable. No options-capacity pass is asserted here because the independent rail-(a) failure is decisive.

The 2.18 compensation shape remains structurally sound: defined risk bounds the 2.7 blast radius. G fails because its proposed entry condition has negative expectancy, not because of the superseded $40 sizing rule.

COOLDOWN UNCHANGED: 2026-10-25. This correction does not reopen, requalify, or waive the historical cooldown.'''
WHERE candidate_code = 'G'
  AND status = 'REJECTED'
  AND cooldown_until = DATE '2026-10-25'
  AND reject_reason LIKE '%2%-of-sub-portfolio max-loss budget%';

ASSERT (
  SELECT COUNT(*) = 1
    AND LOGICAL_AND(status = 'REJECTED')
    AND LOGICAL_AND(cooldown_until = DATE '2026-10-25')
    AND LOGICAL_AND(reject_reason LIKE '%CAPITAL-INDEPENDENT DECISIVE GROUND%')
  FROM `stock-trading-498512.state.strategy_candidates`
  WHERE candidate_code = 'G'
) AS 'G correction failed: expected one still-REJECTED row with unchanged cooldown and corrected VRP-only reason.';

-- Complete append-only replacement for the stale 2026-07-27 SL1 heartbeat. Counts and the individual
-- F/G dispositions remain historical facts; only the joint capital-gated interpretation is corrected.
IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.decision_log`
  WHERE superseded_by = 'ef3cfdcf-8da8-43f8-83a1-3619a66aaf62'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-07-27', 'arsenal-heartbeat', NULL, NULL, 'REJECT', NULL, NULL, NULL, NULL,
    'CORRECTED — SL1 2026-Q3: 0 read / 2 synthesized / 0 qualified / 2 rejected; DOWN gap remains idea-open',
    '''APPEND-ONLY REPLACEMENT for heartbeat ef3cfdcf-8da8-43f8-83a1-3619a66aaf62. Historical counts are unchanged: F and G were synthesized; neither qualified; roster stayed at five.

F remains REJECTED on three independent grounds that never depended on fractional shorting or the $40 rule: no Part-1 return-generating edge/Part-2 compensation, domination by the live park router, and no demonstrated excess over park.

G remains REJECTED, but only its capital-independent rail-(a) ground is current: variance-risk-premium and VVIX evidence make post-spike long convexity negative-expectancy. The former $40 capacity calculation is withdrawn because thesis-scaled CaR replaced the flat 2% rule on 2026-07-28.

RETRACTION OF THE JOINT CONCLUSION. The DOWN gap is not established as capital-gated. Operator-verified IBKR preview evidence shows fractional shorts are permitted; measured equity-pair round-trip commission is 0.42% of gross and sampled borrow is 0.25%-0.43% with ample availability. The old claim that every market-neutral structure was execution-infeasible is false. This does not prove a candidate edge: feasibility is necessary, while SL1 rail (a) still requires a return driver grounded in a valid AI edge. The correct standing conclusion is that the DOWN gap is genuine and idea-open, with execution no longer the universal blocker.''',
    TO_JSON_STRING(STRUCT(
      0 AS candidates_read, 2 AS candidates_synthesized, 0 AS qualified, 2 AS rejected,
      ['F','G'] AS rejected_codes, 5 AS roster_active_count,
      'retracted' AS capital_gated_conclusion,
      TRUE AS fractional_shorting_permitted,
      NUMERIC '0.42' AS fractional_short_roundtrip_pct,
      [NUMERIC '0.25', NUMERIC '0.43'] AS borrow_range_pct,
      NUMERIC '200' AS per_name_car_usd_at_probe,
      'F rejection unaffected; G rejection retained solely on VRP/VVIX expectancy' AS correction_scope
    )),
    ['ef3cfdcf-8da8-43f8-83a1-3619a66aaf62','789de922-da85-4451-bf9c-340c0a52ee57','Monthly_E_Pairs.md','Experiment_Parameters.md rev 18'],
    ['SISA','SL1','arsenal-heartbeat','correction'],
    'ef3cfdcf-8da8-43f8-83a1-3619a66aaf62', 'interactive-correction-2026-08-03'
  );
END IF;

-- Replace the later heartbeat too: it carried the right broker/sizing retraction but overstated its
-- reach by saying both F and G were rejected partly on $40. It remains the durable H + zero-synthesis
-- record, now with the F/G distinction stated correctly.
IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.decision_log`
  WHERE superseded_by = '789de922-da85-4451-bf9c-340c0a52ee57'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-08-03', 'arsenal-heartbeat', NULL, NULL, 'REJECT', NULL, NULL, NULL, NULL,
    'CORRECTED — SL1 2026-08-03: 1 read / 0 synthesized / 0 qualified / 1 rejected (H); 2 research leads preserved',
    '''APPEND-ONLY REPLACEMENT for heartbeat 789de922-da85-4451-bf9c-340c0a52ee57.

COUNTS. Read 1 candidate (H), synthesized 0, qualified 0, rejected 1. Roster remained five.

H FAILED ON THE FOUNDATION'S OWN TERMS. Its only cited disadvantage, 2.20, is version-pending and explicitly classified as no reduction/no relaxation. H treats it as relaxed instead of compensating it. The anchor tests no Claude model; both retrieved studies that test Claude find it more fundamentals-anchored in mixed markets, so transferability also fails. No prospective detector exists, making target cells, frequency, invalidation, and kill structure underivable rather than merely blank.

ZERO SYNTHESIS WAS DELIBERATE. All three SPY-DOWN cells have no active strategy. Four mechanisms were researched. Disclosure information-surprise was the best structural fit, but its magnitude/holding period/cost robustness could not be verified and a same-lab related paper was withdrawn after failed replication. Creating a candidate would have forced immediate default-REJECT and burned the archetype cooldown. It is preserved in events.strategy_research_leads with the next step: obtain and inspect the RFS-track regression tables. The heterogeneous-regime idea is likewise normalized as a research lead, subject to its stricter Claude/replication/detector threshold.

PRIOR-RUN CORRECTION, PRECISE SCOPE. The 2026-07-27 heartbeat's joint capital-gated conclusion is withdrawn: fractional shorts are permitted at 0.42% round trip with 0.25%-0.43% sampled borrow, and the flat $40 max-loss premise was superseded by roughly $200 per-name CaR. F's individual rejection never relied on either fact and remains unchanged. G's old capacity arithmetic is withdrawn, but its capital-independent variance-risk-premium/VVIX negative-expectancy ground remains decisive; G stays REJECTED with its original cooldown.''',
    TO_JSON_STRING(STRUCT(
      1 AS candidates_read, 0 AS synthesized, 0 AS qualified, 1 AS rejected,
      ['H'] AS rejected_codes, 5 AS roster_active,
      4 AS mechanisms_researched, 0 AS mechanisms_clearing_rails,
      ['DOWN/LOW','DOWN/NORMAL','DOWN/HIGH'] AS down_cells_uncovered,
      ['sl1-2026-08-disclosure-information-surprise','a1-2026-2.20-heterogeneous-regime'] AS research_lead_ids,
      ['no_fractional_shorting','40usd_max_loss_budget'] AS premises_retracted_from_prior_heartbeat,
      'F unaffected; G remains rejected solely on VRP/VVIX expectancy' AS fg_correction_scope
    )),
    ['789de922-da85-4451-bf9c-340c0a52ee57','ef3cfdcf-8da8-43f8-83a1-3619a66aaf62','AI_Trading_Foundation.md 2.20','Annual_AI_Foundation_Sweep.md','Monthly_E_Pairs.md','Experiment_Parameters.md rev 18'],
    ['SISA','SL1','arsenal-heartbeat','candidate-rejection','research-lead','correction'],
    '789de922-da85-4451-bf9c-340c0a52ee57', 'interactive-correction-2026-08-03'
  );
END IF;

-- Verification: both stale heartbeats have exactly one replacement, both leads exist once, F remains
-- untouched, and G's mutable current reason/cooldown match the correction.
ASSERT (
  SELECT COUNT(*) = 2
  FROM `stock-trading-498512.events.decision_log`
  WHERE superseded_by IN (
    'ef3cfdcf-8da8-43f8-83a1-3619a66aaf62',
    '789de922-da85-4451-bf9c-340c0a52ee57'
  )
) AS 'SL1 heartbeat correction failed: expected exactly one replacement for each stale heartbeat.';

ASSERT (
  SELECT COUNT(DISTINCT lead_id) = 2
  FROM `stock-trading-498512.events.strategy_research_leads`
  WHERE lead_id IN (
    'sl1-2026-08-disclosure-information-surprise',
    'a1-2026-2.20-heterogeneous-regime'
  )
) AS 'Research-lead normalization failed: expected both durable lead IDs.';

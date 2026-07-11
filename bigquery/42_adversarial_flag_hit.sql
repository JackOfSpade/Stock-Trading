-- Adversarial pre-mortem flag-hit scorecard (item 22, self-improvement backlog). Project:
-- stock-trading-498512. Apply after 01_schema.sql (events.*), 03_twr_engine.sql (perf.kill_flags),
-- 35_strategy_arsenal.sql (events.strategy_postmortems, state.strategy_roster), 26_process_metrics.sql
-- (sibling min_n_met scorecard pattern this view follows), 11_theater_judge.sql (the LLM-judgment-at-
-- close pattern this design borrows the shape, NOT the mechanism, from — see WHY below).
--
-- WHY: 26_process_metrics.sql's header explicitly deferred this metric: "NOT included here: an
-- adversarial_flag_hit catch-rate metric (did a pre-registered adversarial-review flag predict a
-- realized loss) — that needs an LLM judgment made ONCE at close time from the ORIGINAL review text (to
-- avoid hindsight relabeling) and a new logged field, which is a routine-instruction change, not a pure-
-- SQL view; deferred as documented future work." This file closes that gap. The load-bearing SISA
-- strategy-adoption gate (bigquery/35_strategy_arsenal.sql state.strategy_adoption_readiness) requires an
-- adversarial pre-mortem review to reach SUFFICIENT before a candidate strategy is spec-locked into
-- SHADOW — but nobody has ever measured whether the Tier1/2/3 flags a pre-mortem review REGISTERS
-- actually predict what later goes wrong (strategy/08_pre_mortems.md Section "Known limitations" enumerates
-- dozens of named review triggers across the five founding strategies + the router, none scored against
-- outcomes). This view is a read-only, ADVISORY diagnostic on the gate's OWN predictive validity — it
-- never feeds a kill trigger, a readiness view, or any autonomous action; it is a scorecard for a human/
-- LLM to read, exactly like analytics.theater_check_calibration (11_theater_judge.sql) is a scorecard on
-- self-certification reliability, not itself a gate.
--
-- TWO-TABLE, TWO-MOMENT DESIGN (why not one table):
--   (1) events.premortem_flags is written AT REGISTRATION TIME — when a pre-mortem review (review_type
--       'pre-mortem', or 'strategy-adoption' for a SISA candidate's pre-mortem artifact) names a Tier 1,
--       Tier 2, or Tier 3 flag with a stated review trigger (strategy/08_pre_mortems.md format: a flag
--       description + a "Review trigger:" condition). Capturing the ORIGINAL flag_text and
--       review_trigger_text verbatim, before any outcome exists, is what makes the later judgment
--       possible without hindsight relabeling — the same anti-relabeling concern 29_precedent_outcomes.sql
--       and 11_theater_judge.sql's "paired ORIGINAL review text" pattern both protect.
--   (2) events.premortem_flag_outcomes is written EXACTLY ONCE per flag, AT CLOSE TIME — when the
--       strategy the flag belongs to has a kill-trigger fire (perf.kill_flags: drawdown_kill,
--       runaway_review, or m2m_underperf_review — 03_twr_engine.sql) or is discretionarily retired
--       (events.strategy_postmortems, SL2-authored — 35_strategy_arsenal.sql). At that moment, an LLM
--       reads the flag's ORIGINAL flag_text + review_trigger_text (never the postmortem's own framing)
--       and judges: did the named trigger condition objectively fire (trigger_fired), and if so, did it
--       fire BEFORE the loss/kill was realized — a LEADING indicator, not a coincident/lagging one
--       (fired_before_loss)? This is documented here as a ROUTINE STEP the SL2 postmortem-authoring step
--       and the kill-flag-firing handler perform inline (each already has an open LLM context reading the
--       strategy's full history at that moment) — deliberately NOT a batch AI.GENERATE_TABLE scorer like
--       ops.sp_score_theater(), because the judgment needs the SPECIFIC close-time context (why THIS
--       strategy failed) that a bulk pass over many strategies at once would flatten. See
--       Claude_Task_Plan.md SL2 + postmortem steps (shared_edits — registering flags at pre-mortem
--       authoring and judging at close; MAY-DEFER, routine-body edit, not applied by this file).
--   Idempotency for the once-only judgment: the routine step MUST check
--   `NOT EXISTS (SELECT 1 FROM events.premortem_flag_outcomes WHERE flag_id = <flag>)` before inserting
--   (same convention as ops.roster_change_log / ops.d2a_cutover_log presence-is-done markers), so a
--   re-run of the same close-time step can never double-judge a flag. analytics.adversarial_flag_hit
--   below additionally takes latest-wins per flag_id so a corrected append-only re-judgment (a NEW row,
--   never an UPDATE, per the events.* append-only convention) is still read safely.
--
-- BACKFILL (NOT performed by this file — see the shared_edits packet returned alongside this file): the
-- five founding strategies' pre-mortems (strategy/08_pre_mortems.md) already enumerate dozens of Tier1/2/3
-- flags with named review triggers, predating this table. A best-effort backfill (backfilled=TRUE) is
-- in-scope future work but requires hand-curating each flag_text/review_trigger_text from that document,
-- which this DDL-only file deliberately does not fabricate.
--
-- FAIL-CLOSED: min_n_met defaults FALSE below the floor (this is ADVISORY-only regardless; it is not a
-- gate input, so there is no not-ready path to keep closed, but the convention is kept for consistency
-- with every other analytics.* scorecard in this codebase). Idempotent (CREATE TABLE IF NOT EXISTS /
-- CREATE OR REPLACE VIEW); safe to re-run.

-- ============================================================================
-- events.premortem_flags — append-only registry of pre-registered adversarial-review flags. One row per
-- named Tier1/2/3 flag at the moment a pre-mortem review states it (strategy/08_pre_mortems.md format:
-- a flag description + an explicit review trigger). WRITE PATH: SL2 (authoring/revising a pre-mortem) and
-- AR_orc (the adversarial-review orchestrator adjudicating review_type IN ('pre-mortem','strategy-
-- adoption')) INSERT one row per Tier1/2/3 flag the ACCEPTED (or revision-required) pre-mortem carries
-- forward, at the point the review concludes — never retroactively, so flag_text/review_trigger_text are
-- always the pre-outcome original.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.premortem_flags` (
  flag_id STRING DEFAULT GENERATE_UUID() NOT NULL,
  registered_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  strategy_code STRING NOT NULL,          -- state.strategy_roster.strategy_code (router-level flags use 'ROUTER')
  review_id STRING,                       -- events.adversarial_reviews.review_id that registered this flag;
                                           -- NULL for backfilled pre-2026-07 rows that predate review_id tagging
  tier STRING NOT NULL,                   -- 'Tier 1' | 'Tier 2' | 'Tier 3' (strategy/08_pre_mortems.md taxonomy;
                                           -- Tier 1 = defect requiring revision, Tier 2 = calibration/
                                           -- measurability accepted-with-trigger, Tier 3 = completeness/scope
                                           -- accepted-with-trigger — a flag registered here is one the pre-
                                           -- mortem carried forward as a documented limitation, not one that
                                           -- blocked acceptance)
  flag_text STRING NOT NULL,              -- the ORIGINAL flag/risk description, verbatim, at registration time
  review_trigger_text STRING,             -- the ORIGINAL named review-trigger condition, verbatim (e.g.
                                           -- "if monthly review subjectively identifies slow-burn conditions
                                           -- that the flag did not catch and the router activated strategies
                                           -- that then lose capital, escalate")
  backfilled BOOL DEFAULT FALSE,          -- TRUE for founding-strategy flags backfilled from
                                           -- strategy/08_pre_mortems.md rather than registered live
  PRIMARY KEY (flag_id) NOT ENFORCED
) PARTITION BY DATE(registered_ts) CLUSTER BY strategy_code, tier
OPTIONS(description='Append-only pre-registered adversarial-review Tier1/2/3 flags (item 22). Written by SL2/AR_orc at pre-mortem review conclusion. Never updated in place — a revised flag is a new row with a new flag_id.');

-- ============================================================================
-- events.premortem_flag_outcomes — append-only, ONE judgment row per flag_id, written ONCE at close time
-- (strategy kill-trigger firing or discretionary-retirement postmortem). WRITE PATH: the kill-flag-firing
-- handler (D2/SL routine reacting to perf.kill_flags.drawdown_kill / runaway_review / m2m_underperf_review)
-- or the SL2 postmortem-authoring step (events.strategy_postmortems), each already holding full context on
-- why the strategy closed, reads every still-unjudged events.premortem_flags row for that strategy_code and
-- INSERTs exactly one outcome row per flag — an LLM judgment documented as a routine step, not a batch
-- AI.GENERATE_TABLE procedure (see file header WHY). judge_session names the routine/session that made the
-- call so the judgment itself is auditable back to a specific close-time context.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.premortem_flag_outcomes` (
  outcome_id STRING DEFAULT GENERATE_UUID() NOT NULL,
  outcome_judged_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  flag_id STRING NOT NULL,                -- events.premortem_flags.flag_id being judged
  trigger_fired BOOL,                     -- did the review_trigger_text condition objectively fire, per the
                                           -- close-time record, at any point in the flag's strategy_code's life?
  fired_before_loss BOOL,                 -- only meaningful when trigger_fired: did it fire BEFORE the
                                           -- realized loss/kill (a LEADING indicator) rather than at/after it
                                           -- (coincident or lagging, i.e. not actually predictive)? NULL when
                                           -- trigger_fired is FALSE or NULL (never fired, so leading-vs-lagging
                                           -- does not apply)
  evidence_text STRING,                   -- the judge's cited evidence (dates/values/decision_log refs)
                                           -- supporting trigger_fired / fired_before_loss
  judge_session STRING,                   -- routine/session id making the ONE judgment, e.g.
                                           -- 'SL2-postmortem-<strategy_code>-<retired_date>' or
                                           -- 'kill-flag-<strategy_code>-<as_of_date>'
  PRIMARY KEY (outcome_id) NOT ENFORCED
) PARTITION BY DATE(outcome_judged_ts) CLUSTER BY flag_id
OPTIONS(description='Append-only ONE-TIME-per-flag LLM outcome judgment (item 22), made at strategy close (kill-flag firing or postmortem authoring) from the flags ORIGINAL registered text. Idempotency is a routine-step NOT-EXISTS check before insert, mirroring ops.roster_change_log.');

-- ============================================================================
-- analytics.adversarial_flag_hit — the scorecard. Per (strategy_code, tier): how many flags were
-- registered, how many have been judged at a close event so far, how often the named trigger actually
-- fired, and — the load-bearing number — how often a fired trigger was a LEADING indicator of the loss
-- (predictive_catch_rate) rather than a coincident/lagging one. ADVISORY ONLY: read-only diagnostic on the
-- pre-mortem gate's own predictive validity, exactly like analytics.theater_check_calibration is a
-- diagnostic on self-certification reliability — never a trigger, never a gate input, never wired into any
-- readiness view or kill trigger. min_n_met floors at >= 5 judged flags per cell (same floor as
-- conviction_monotonicity, 26_process_metrics.sql) so a thin cell reads as "not enough data" rather than a
-- false signal; below the floor the rates are still shown (directional only), matching the sibling's
-- design. Latest-wins per flag_id on the outcome join, so a corrected append-only re-judgment (a new row,
-- never an UPDATE) is read safely without double-counting a flag.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.adversarial_flag_hit` AS
WITH latest_outcome AS (
  SELECT * FROM `stock-trading-498512.events.premortem_flag_outcomes`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY flag_id ORDER BY outcome_judged_ts DESC) = 1
)
SELECT
  f.strategy_code,
  f.tier,
  COUNT(*) AS n_flags_registered,
  COUNTIF(o.flag_id IS NOT NULL) AS n_judged,
  COUNTIF(o.trigger_fired) AS n_trigger_fired,
  COUNTIF(o.trigger_fired AND o.fired_before_loss) AS n_fired_before_loss,
  ROUND(SAFE_DIVIDE(COUNTIF(o.trigger_fired), COUNTIF(o.flag_id IS NOT NULL)), 3) AS trigger_fire_rate,
  ROUND(SAFE_DIVIDE(COUNTIF(o.trigger_fired AND o.fired_before_loss), COUNTIF(o.trigger_fired)), 3) AS predictive_catch_rate,
  (COUNTIF(o.flag_id IS NOT NULL) >= 5) AS min_n_met
FROM `stock-trading-498512.events.premortem_flags` f
LEFT JOIN latest_outcome o ON o.flag_id = f.flag_id
GROUP BY f.strategy_code, f.tier
ORDER BY f.strategy_code, f.tier;

-- bigquery/166_capital_dormancy_sweep.sql (2026-08-11)
-- Project: stock-trading-498512. Apply after bigquery/98_regime_capital_enablement.sql (the
-- regime-capital sweep/restore this mirrors), bigquery/127_strategy_nav_dust_exclusion.sql (canonical
-- analytics.strategy_nav), bigquery/144_decision_log_superseded_audit.sql (state.decision_log_current),
-- bigquery/163_cash_flow_source_provenance.sql (the sanctioned events.cash_flows.source set this file
-- extends), and bigquery/164_capital_utilisation_and_restore_integrity.sql (state.capital_utilisation_watch,
-- state.sweep_recipient_weights, both read here).
--
-- NET-NEW OBJECTS ONLY. Redefines state.cash_flow_source_unknown (bigquery/163) to extend its
-- sanctioned set — the only existing object this file changes. Everything else is additive.
--
-- ============================ WHY ================================================================
-- Prompted by an owner question, 2026-08-11 session: Strategy C holds $9,436.86 — currently the single
-- largest allocation of the five strategies — 100% parked, 0% deployed, and has never once placed a
-- trade in its life (every FOMC thesis it has evaluated, June/July/July/September 2026, came back
-- NO-GO). Operating_Protocols.md §16 already has a name for this: "an active strategy that is merely
-- idle... keeps its capital" — a DELIBERATE principle, not an oversight, guarding against anything that
-- looks like judging a strategy by how busy it currently is (the same instinct behind the flat refusal
-- to size positions by past P&L). That principle is right for a strategy having an unlucky month. It is
-- not obviously right for a strategy whose OWN declared mechanism trades a handful of times a year by
-- design (`strategy/05_strategy_c.md`'s HYBRID-FOMC ceiling is explicitly "8 trades/year, one per FOMC
-- meeting") — holding a full, undifferentiated allocation year-round for a strategy that structurally
-- cannot use most of it most of the time is a distinct case from a strategy that trades often and is
-- just between opportunities.
--
-- Two facts make a narrower mechanism cheap here rather than requiring new settlement/margin plumbing:
--   1. There is only ONE real brokerage account (Operating_Protocols.md §13: "The five strategy
--      sub-portfolios share one IBKR account... The connector has no A/B/C/D/E buckets"). Per-strategy
--      `available_funds` is a bookkeeping split of one pooled cash balance, not a segregated sub-account.
--      Moving a dollar from C's ledger to D's ledger crosses no physical or settlement boundary — it is
--      the same accounting-only move bigquery/98's regime sweep already makes.
--   2. Position sizing is no longer NAV-gated for any strategy (bigquery/104_strip_pretrade_rails.sql,
--      owner directive 2026-07-22, reaffirmed by Rev 19 retiring both numeric CaR envelopes,
--      Experiment_Parameters.md 2026-08-05): a thesis's risk budget is a seven-factor-justified AI
--      judgment call with no percentage-of-portfolio ceiling. So a strategy holding less standing
--      capital is not thereby blocked from sizing a defensible trade when one arrives — it only needs
--      the CASH at the moment of settlement, not a permanently-parked balance sized for a trade that
--      may not happen for months.
--
-- ============================ THE MECHANISM (mirrors bigquery/98's sweep/debt/restore shape exactly,
-- with ONE deliberate divergence on when RESTORE fires — see below) ==============================
--
-- ELIGIBILITY ("dormant"), state.strategy_capital_dormancy: a capital-ENABLED, roster-active strategy
-- with (a) no open position, (b) >=90 days since its last deployment, (c) DECLARED low-frequency BY
-- DESIGN (state.strategy_declared_frequency.is_low_frequency_by_design — see below; NOT a trailing
-- REALIZED trade count), and (d) idle capital that is STILL ACTIVELY EVALUATED (evaluations_60d > 0,
-- reusing bigquery/164's own health signal verbatim — this is what stops the mechanism from ever
-- touching a STRANDED strategy, a different and more urgent problem state.capital_utilisation_watch.
-- is_stranded already alarms on separately). A $2,000 reserve floor is preserved untouched — same
-- figure and same rationale as Experiment_Parameters.md's probe-stake floor ("clears IBKR's ~$0.35
-- minimum commission without commission-dominated economics") — so a dormant strategy always keeps
-- enough to self-fund a small trade without waiting on a cross-strategy pull, and never re-creates the
-- zero-NAV structural deadlock bigquery/22 documents for a PROBE strategy with no capital at all.
--
-- WHY DECLARED FREQUENCY, NOT A TRAILING REALIZED TRADE COUNT — CAUGHT LIVE, 2026-08-11, BEFORE THIS
-- FILE WAS FIRST PROPOSED. The first draft of this eligibility test used trailing-365-day REALIZED
-- entries <=12 (the owner's own literal "<=1 trade/month" proposal, applied to actual trade history).
-- Dry-run against live data flagged BOTH C and E as dormant — wrong for E, which is a market-neutral
-- pairs strategy declared at 6-12 pair theses (12-24 trades)/year, comfortably ABOVE the 1/month bar,
-- and is currently blocked from trading only by its own 0.50 pair-correlation floor, not by being
-- low-frequency by design. A realized-trade-count test cannot tell "structurally rare" (C) apart from
-- "never traded YET" (E) — both currently show zero trailing entries, so the test degenerates to
-- exactly the naive idle-and-days-since-deployment detector bigquery/164's own header warns would
-- "fire on both on day one." Gating on each strategy's own DECLARED frequency ceiling instead — a
-- static fact about its mechanism, sourced verbatim from its `strategy/0N_*.md` "Declared expected
-- frequency" section, unaffected by how much it has or has not actually traded — fixes this: C's
-- ceiling (8/yr, current HYBRID-FOMC routing) and D's (3-8/yr) read low-frequency; A's (15-25), B's
-- (20-30), and E's (12-24) do not, regardless of any of the five strategy's realized trade history.
--
-- SWEEP (state.capital_dormancy_sync_pending, SWEEP rows; standing condition, D2a-executed daily,
-- mechanically weighted): a dormant strategy's idle capital ABOVE the $2,000 floor sweeps to the
-- currently-NON-dormant capital-enabled strategies, using the SAME state.sweep_recipient_weights
-- capacity weight bigquery/164 built for the regime sweep (renormalized over just the eligible
-- recipient subset; falls back to equal split if weights are empty or do not sum to 1.0, identical
-- fallback posture to bigquery/98). Tagged source='capital_dormancy_sweep'. This creates/increases
-- state.capital_dormancy_debt — money owed BACK to the dormant strategy, exactly mirroring how
-- state.regime_capital_debt tracks a receivable for a router-disabled strategy, not a payable for the
-- recipients.
--
-- RESTORE — DELIBERATELY NOT a standing daily condition, unlike bigquery/98's RESTORE. This is the one
-- place this mechanism does NOT copy the regime pattern, and the reason is a real chicken-and-egg
-- problem regime-restore never has to solve: regime RESTORE fires on a state TRANSITION (the strategy
-- flips back to capital_enabled), a signal genuinely independent of whether that strategy has a trade
-- ready that day. Dormancy has no such transition — C stays capital_enabled and HYBRID-ACTIVATE the
-- entire time, dormant or not — so the only honest trigger for "give it back" is "this strategy has a
-- GO thesis that needs it," which by construction happens AFTER the capital would already need to be
-- there to size and craft the order. Firing RESTORE on a daily standing condition instead (mirroring
-- bigquery/98 literally) would pull the swept capital back the moment ANY donor has spare cash on ANY
-- day — which is most days — defeating the sweep within a session or two of it firing. So RESTORE here
-- is exclusively ON-DEMAND: analytics.fn_capital_dormancy_restore_plan(p_strategy, p_amount_needed),
-- called by the order-craft step at the moment a dormant strategy's thesis needs more cash than its
-- current available_funds holds. It pulls LEAST(p_amount_needed, LEAST(outstanding_debt, donor
-- capacity)) pro-rata from the same non-dormant enabled-strategy donor set the sweep pays into —
-- capped at outstanding_debt because this mechanism only ever returns a dormant strategy ITS OWN
-- previously-swept capital, never grants it new capital beyond that (a thesis sized larger than the
-- strategy's total historical capital is a genuinely new capital-allocation question, out of scope
-- here, and falls back to whatever the strategy's own available_funds plus outstanding_debt can cover).
-- Tagged source='capital_dormancy_restore'. This decreases state.capital_dormancy_debt.
--
-- Net effect: a $9,436.86 balance for a strategy that trades roughly once a year, most of the time,
-- reads close to $2,000 (working elsewhere, in a strategy that can currently use it) and reads its full
-- size again for the day or two around an actual GO. The debt ledger means this is never a real loss to
-- C — same "standing receivable, not a shrinkage" property bigquery/165 already established and
-- corrected the record on for the regime mechanism.
--
-- WHY A SEPARATE KILL-SWITCH (ops.capital_dormancy_control) RATHER THAN REUSING ops.capital_control.
-- The existing switch's own registration comment ties it explicitly to "Regime-Capital Enablement" —
-- a different trigger condition (router DO-NOT-ACTIVATE) than this file's (persistent low-frequency
-- idleness). An owner who wants to pause one mechanism without touching the other — e.g. keep the
-- regime sweep live but pause dormancy sweeping while this is new and being watched — needs them
-- independently switchable. Same pattern as ops.park_control / ops.arsenal_control / ops.capital_control
-- already being separate tables for separate mechanisms, not one shared switch.
--
-- WHY A SEPARATE DEBT LEDGER (state.capital_dormancy_debt) RATHER THAN WIDENING state.regime_capital_debt.
-- state.regime_capital_debt is read by name in Operating_Protocols.md §16 prose, the D2a RESTORE
-- substep, and W5's capital-allocation scorecard, all of which assume it means specifically
-- router-driven debt. Widening its source filter to also count dormancy movements would silently change
-- what every existing reader means by "outstanding regime-capital debt" with no corresponding text
-- change at any of those sites. A same-shape sibling view costs one CREATE statement and changes the
-- behavior of nothing that already exists.
--
-- WHAT THIS FILE DELIBERATELY DOES NOT DO. It does not touch bigquery/98's regime sweep/restore, does
-- not change state.regime_capital_debt, does not add a new alert category (state.strategy_capital_dormancy
-- and state.capital_dormancy_debt are both plain SELECT-able views a routine or a human can check;
-- alerting on a stuck or unexpectedly-large dormancy debt is a reasonable follow-up once this has real
-- data behind it, not a day-one requirement), and does not size or craft any order — it only computes
-- eligibility and movement plans. Wiring the RESTORE call into the actual order-craft step for a
-- dormant strategy's GO is a routine-prompt change (Claude_Task_Plan.md / task_plan/D2a.md), scoped and
-- drafted separately from this schema file so the two can be reviewed independently.

-- ===== 1. Kill-switch (analog of ops.capital_control / ops.park_control / ops.arsenal_control) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.capital_dormancy_control`
(
  control_id STRING DEFAULT GENERATE_UUID(),
  control_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  enabled BOOL NOT NULL,
  reason STRING,
  set_by STRING,
  PRIMARY KEY (control_id) NOT ENFORCED
)
PARTITION BY DATE(control_ts)
OPTIONS(
  description="Append-only capital-dormancy-sweep kill-switch (owner directive 2026-08-11; analog of ops.capital_control, the regime-capital-sync switch this mechanism deliberately does NOT share — see bigquery/166 header). Latest row by control_ts wins (state.capital_dormancy_control_latest). enabled=FALSE means state.capital_dormancy_sync_pending still computes its rows but D2a records what it would have moved and moves nothing; the on-demand analytics.fn_capital_dormancy_restore_plan TVF is also gated by this switch inside the function body, so pausing this control blocks BOTH directions of movement. Seeded enabled=TRUE so the loop starts open; flip with a manual INSERT."
);

INSERT INTO `stock-trading-498512.ops.capital_dormancy_control` (enabled, reason, set_by)
SELECT TRUE, 'seed — capital dormancy sweep enabled (owner directive 2026-08-11)', 'bigquery/166 seed'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.capital_dormancy_control`);

CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_dormancy_control_latest`
AS WITH ctrl AS (
  SELECT ARRAY_AGG(
           STRUCT(enabled, reason, set_by, control_ts)
           ORDER BY control_ts DESC LIMIT 1
         )[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.capital_dormancy_control`
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  ctrl.latest.reason                   AS reason,
  ctrl.latest.set_by                   AS set_by,
  ctrl.latest.control_ts               AS control_ts
FROM ctrl;

-- ===== 2. state.strategy_declared_frequency — static seed, sourced verbatim from each strategy's own
-- spec doc. Same pattern as roster.yaml -> state.strategy_roster: a fact that lives in prose, mirrored
-- into a queryable table by hand, with the source line cited so it is auditable rather than asserted.
-- MAINTENANCE: if a strategy's "Declared expected frequency" section is ever edited (which also
-- invalidates its spec_hash — see strategy/roster.yaml), this row must be re-reviewed by hand; nothing
-- here re-derives it automatically. A newly-adopted strategy needs a row added the same way.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.strategy_declared_frequency`
(
  strategy_code STRING NOT NULL,
  declared_frequency_text STRING NOT NULL,
  source_citation STRING NOT NULL,
  is_low_frequency_by_design BOOL NOT NULL,
  PRIMARY KEY (strategy_code) NOT ENFORCED
)
OPTIONS(
  description="Per-strategy declared trade frequency, sourced verbatim from each strategy/0N_*.md 'Declared expected frequency' section (bigquery/166). is_low_frequency_by_design is the hand-reviewed classification the capital-dormancy-sweep eligibility test (state.strategy_capital_dormancy) gates on, chosen over a trailing REALIZED trade count because a never-traded strategy's realized count is zero regardless of whether it is rare by design (C, D) or merely currently blocked (E was misclassified by a realized-count test during this file's own drafting — see bigquery/166 header)."
);

INSERT INTO `stock-trading-498512.state.strategy_declared_frequency`
  (strategy_code, declared_frequency_text, source_citation, is_low_frequency_by_design)
SELECT * FROM UNNEST([
  STRUCT('A' AS strategy_code, '15-25 trades per year over active periods.' AS declared_frequency_text, 'strategy/03_strategy_a.md:60' AS source_citation, FALSE AS is_low_frequency_by_design),
  STRUCT('B', '20-30 trades per year over active periods.', 'strategy/04_strategy_b.md:58', FALSE),
  STRUCT('C', 'Under current HYBRID-FOMC routing: 0-8 trades/year (ceiling reflects the FOMC-meeting-count cap). Would rise to 8-15/year if the router ever widens past FOMC-only.', 'strategy/05_strategy_c.md:69', TRUE),
  STRUCT('D', '3-8 trades per year over active periods (counting entries and exits as separate trades).', 'strategy/06_strategy_d.md:80', TRUE),
  STRUCT('E', '6-12 pair theses per year (12-24 trades counting both legs).', 'strategy/07_strategy_e.md:68', FALSE)
]) AS seed
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.strategy_declared_frequency` existing WHERE existing.strategy_code = seed.strategy_code);

-- ===== 3. state.strategy_capital_dormancy — eligibility + sweepable amount =====
-- Built on top of state.capital_utilisation_watch (bigquery/164) for the idle/health signals, so this
-- view can never disagree with that one about what "idle" or "actively evaluated" means, joined against
-- the declared-frequency classification above for the "low-frequency by design" gate.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_capital_dormancy` AS
WITH trades_365d AS (
  -- Trailing 365-day entry count, dust-excluded — same predicate bigquery/164's own `deploy` CTE uses.
  -- REPORTED FOR CONTEXT ONLY — see the header note on why this column does NOT gate eligibility.
  SELECT strategy AS strategy_code, COUNT(*) AS trades_trailing_365d
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE NOT COALESCE(is_dust, FALSE)
    AND entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 365 DAY)
  GROUP BY strategy
)
SELECT
  w.strategy_code,
  w.idle_capital,
  w.nav,
  w.deployed_mv,
  w.open_positions,
  w.days_since_deployment,
  w.never_deployed,
  w.evaluations_60d,
  w.last_evaluation_date,
  COALESCE(t.trades_trailing_365d, 0)                          AS trades_trailing_365d,
  f.declared_frequency_text,
  f.is_low_frequency_by_design,
  CAST(2000.00 AS NUMERIC)                                      AS reserve_floor,
  ROUND(GREATEST(0, w.idle_capital - 2000.00), 2)               AS dormant_sweepable_amount,
  (
    w.open_positions = 0
    AND w.days_since_deployment >= 90
    AND COALESCE(f.is_low_frequency_by_design, FALSE)
    AND w.evaluations_60d > 0
    AND w.idle_capital > 2000.00
  )                                                              AS is_dormant
FROM `stock-trading-498512.state.capital_utilisation_watch` w
LEFT JOIN trades_365d t ON t.strategy_code = w.strategy_code
LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f ON f.strategy_code = w.strategy_code;

-- ===== 4. state.capital_dormancy_debt — same shape as state.regime_capital_debt, separate ledger =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_dormancy_debt`
AS WITH swept AS (
  SELECT strategy, -SUM(amount) AS swept_out_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'capital_dormancy_sweep' AND amount < 0
  GROUP BY strategy
),
restored AS (
  SELECT strategy, SUM(amount) AS restored_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'capital_dormancy_restore' AND amount > 0
  GROUP BY strategy
)
SELECT
  r.strategy_code                                                               AS strategy,
  COALESCE(sw.swept_out_total, 0)                                               AS swept_out_total,
  COALESCE(rs.restored_total, 0)                                                AS restored_total,
  GREATEST(0, COALESCE(sw.swept_out_total, 0) - COALESCE(rs.restored_total, 0)) AS outstanding_debt
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN swept    sw ON sw.strategy = r.strategy_code
LEFT JOIN restored rs ON rs.strategy = r.strategy_code;

-- ===== 5. state.capital_dormancy_sync_pending — SWEEP rows only (daily, D2a-executed) =====
-- RESTORE deliberately has no row shape here — see the header's chicken-and-egg note. RESTORE is
-- computed on demand by analytics.fn_capital_dormancy_restore_plan (object 5 below), not read from a
-- standing pending view.
CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_dormancy_sync_pending`
AS WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_dormancy_control_latest`
),
dormant AS (
  SELECT strategy_code, dormant_sweepable_amount
  FROM `stock-trading-498512.state.strategy_capital_dormancy`
  WHERE is_dormant AND dormant_sweepable_amount >= 25
),
-- Eligible recipients: capital-enabled AND not themselves currently dormant (never move idle capital
-- from one non-trading strategy to another — that accomplishes nothing).
recipients AS (
  SELECT e.strategy_code
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (SELECT strategy_code FROM `stock-trading-498512.state.strategy_capital_dormancy` WHERE is_dormant)
),
n_recipients AS (SELECT COUNT(*) AS n FROM recipients),
-- Renormalize bigquery/164's capacity weight over just the eligible recipient subset (it may carry
-- weights for strategies excluded here, e.g. another dormant strategy, or omit a strategy this view
-- includes). Falls back to equal split, same posture as bigquery/98's SWEEP.
weights_raw AS (
  SELECT sw.strategy_code, sw.sweep_share
  FROM `stock-trading-498512.state.sweep_recipient_weights` sw
  JOIN recipients r ON r.strategy_code = sw.strategy_code
),
weights_total AS (SELECT SUM(sweep_share) AS total FROM weights_raw),
weights AS (
  SELECT r.strategy_code,
    CASE
      WHEN wt.total > 0.9999 AND wt.total < 1.0001 AND wr.sweep_share IS NOT NULL
        THEN wr.sweep_share
      ELSE 1.0 / n.n
    END AS share
  FROM recipients r
  CROSS JOIN n_recipients n
  CROSS JOIN weights_total wt
  LEFT JOIN weights_raw wr ON wr.strategy_code = r.strategy_code
)
SELECT
  'SWEEP'                                AS action,
  d.strategy_code                        AS strategy,
  d.dormant_sweepable_amount             AS amount,
  w.strategy_code                        AS counterparty_strategy,
  ROUND(d.dormant_sweepable_amount * w.share, 2) AS counterparty_amount,
  ctrl.control_enabled
FROM dormant d
CROSS JOIN weights w
CROSS JOIN ctrl
ORDER BY strategy, counterparty_strategy;

-- ===== 6. analytics.fn_capital_dormancy_restore_plan — on-demand, trade-triggered pull plan =====
-- Called by the order-craft step at the moment a dormant strategy's sized thesis needs more cash than
-- its current available_funds. Returns one row per donor strategy. The calling routine writes the
-- actual $0-sum events.cash_flows double-entry (one positive row for p_strategy, one negative row per
-- donor here) tagged source='capital_dormancy_restore' — this function only computes the plan, exactly
-- as state.regime_capital_sync_pending's RESTORE rows are a plan bigquery/98's executor writes, not a
-- self-executing write.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_capital_dormancy_restore_plan`(
  p_strategy STRING, p_amount_needed NUMERIC
)
AS (
  WITH ctrl AS (
    SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_dormancy_control_latest`
  ),
  debt AS (
    SELECT outstanding_debt FROM `stock-trading-498512.state.capital_dormancy_debt`
    WHERE strategy = p_strategy
  ),
  -- Capped at outstanding_debt: this plan only ever returns a dormant strategy its own previously-swept
  -- capital, never grants new capital beyond that (see header — sizing beyond total historical capital
  -- is out of scope for this mechanism).
  requested AS (
    SELECT LEAST(p_amount_needed, COALESCE((SELECT outstanding_debt FROM debt), 0)) AS amount_payable
  ),
  donors AS (
    SELECT e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
    FROM `stock-trading-498512.state.strategy_capital_enablement` e
    JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = e.strategy_code
    WHERE e.capital_enabled
      AND e.strategy_code != p_strategy
      AND e.strategy_code NOT IN (SELECT strategy_code FROM `stock-trading-498512.state.strategy_capital_dormancy` WHERE is_dormant)
      AND nv.available_funds > 0
  ),
  donor_total AS (SELECT SUM(donor_capacity) AS total FROM donors)
  SELECT
    p_strategy                                                         AS strategy,
    d.donor_strategy,
    d.donor_capacity,
    ROUND(LEAST(rq.amount_payable, dt.total) * d.donor_capacity / dt.total, 2) AS pull_amount,
    rq.amount_payable                                                  AS plan_total,
    ctrl.control_enabled
  FROM donors d
  CROSS JOIN donor_total dt
  CROSS JOIN requested rq
  CROSS JOIN ctrl
  WHERE dt.total > 0
);

-- ===== 7. Extend the sanctioned events.cash_flows.source set (bigquery/163) =====
-- Per bigquery/163's own instruction: "adding a genuinely new movement mechanism means adding it to
-- that sanctioned set in a successor file, not inventing the value in-session." This is that successor
-- file for exactly two new values.
--
-- SUPERSEDED LIVE by bigquery/214_account_fee_recording.sql — current single source of truth for this
-- view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE statement live in isolation. 167 renames the two values added here
-- (capital_dormancy_sweep/capital_dormancy_restore) to nomadic_capital_sweep/nomadic_capital_restore
-- in the sanctioned set below (this file as a whole is superseded by bigquery/167 — see this file's
-- own header — this marker exists because the checker requires one on this specific CREATE statement
-- too).
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flow_source_unknown` AS
SELECT
  event_id, flow_date, flow_type, amount, strategy, source, ingest_ts,
  CASE
    WHEN source IS NULL THEN 'source is NULL - every write path must tag its provenance'
    WHEN source = 'unspecified' THEN 'source left at the column DEFAULT - the writer did not tag this row'
    WHEN source = 'D2' THEN 'source is the RETIRED pre-2026-08-10 default - the writer did not tag this row and was stamped D2'
    ELSE 'source is not in the sanctioned set - either a new movement mechanism that must be added to bigquery/163, or a typo'
  END AS finding,
  SUBSTR(COALESCE(note, ''), 0, 300) AS note_preview
FROM `stock-trading-498512.events.cash_flows`
WHERE ingest_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
  AND (
    source IS NULL
    OR NOT (
    source IN (
      'regime_capital_sweep', 'regime_capital_restore', 'external_withdrawal',
      'termination_redistribution', 'connector-reconciliation',
      'capital_dormancy_sweep',   -- bigquery/166: dormant strategy's excess-above-floor idle capital out
      'capital_dormancy_restore'  -- bigquery/166: on-demand pull of a dormant strategy's own swept capital back
    )
    OR source LIKE 'backfill-%'
    )
  );

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Eligibility reads correctly against live state today (expect C is_dormant=TRUE, E is_dormant=FALSE
--    — E is also 100% idle right now, same as C, but E's DECLARED frequency (12-24 trades/year) is not
--    low-frequency-by-design, so state.strategy_declared_frequency is what tells them apart, not
--    trades_trailing_365d, which reads 0 for BOTH and would misclassify E if used as the gate — this is
--    the exact bug this file's header documents catching before the eligibility test shipped):
--    SELECT strategy_code, idle_capital, days_since_deployment, trades_trailing_365d, evaluations_60d,
--           is_low_frequency_by_design, dormant_sweepable_amount, is_dormant
--    FROM `stock-trading-498512.state.strategy_capital_dormancy` ORDER BY strategy_code;
--
-- 2. No live cash moved (this file writes no events.cash_flows rows):
--    SELECT * FROM `stock-trading-498512.state.capital_dormancy_debt` WHERE outstanding_debt != 0;
--    -> expect zero rows until D2a's dormancy-sweep hook actually executes a SWEEP.
--
-- 3. The sweep plan is well-formed (amounts sum back to the swept total, no NULL counterparties):
--    SELECT strategy, SUM(counterparty_amount) AS recipients_sum, ANY_VALUE(amount) AS swept_amount
--    FROM `stock-trading-498512.state.capital_dormancy_sync_pending` GROUP BY strategy;
--    -> expect recipients_sum ~= swept_amount (rounding pennies only) for every dormant strategy.
--
-- 4. The extended source set is clean:
--    SELECT * FROM `stock-trading-498512.state.cash_flow_source_unknown`;
--    -> expect zero rows.
--
-- 5. Kill-switch reads TRUE (seeded open):
--    SELECT * FROM `stock-trading-498512.state.capital_dormancy_control_latest`;

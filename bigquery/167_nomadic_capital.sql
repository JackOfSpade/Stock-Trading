-- bigquery/167_nomadic_capital.sql (2026-08-11)
-- Project: stock-trading-498512. Apply after bigquery/166_capital_dormancy_sweep.sql (SUPERSEDED by
-- this file — see below), bigquery/98_regime_capital_enablement.sql (one view of which this file
-- redefines), bigquery/127_strategy_nav_dust_exclusion.sql, bigquery/163_cash_flow_source_provenance.sql.
--
-- SUPERSEDES bigquery/166_capital_dormancy_sweep.sql IN FULL. bigquery/166 is kept, unmodified, for
-- DR-rebuild apply-in-order reference only — same convention as bigquery/93 -> bigquery/156 and
-- bigquery/22 -> bigquery/127. DO NOT re-apply 166's CREATE statements in isolation; this file DROPs
-- every object 166 created and replaces them under new names below. 166's `ops.capital_dormancy_control`,
-- `state.capital_dormancy_control_latest`, `state.strategy_capital_dormancy`, `state.capital_dormancy_debt`,
-- `state.capital_dormancy_sync_pending`, and `analytics.fn_capital_dormancy_restore_plan` were all
-- created same-day (2026-08-11) with zero real cash ever moved through them (verified:
-- state.capital_dormancy_debt read all zeros at the moment of this file's drafting) — a clean rename is
-- safe here in a way it would not be for an object carrying real ledger history. `state.strategy_declared_frequency`
-- (166) is UNCHANGED and reused as-is below; it needed no redesign.
--
-- ============================ WHY THIS SUPERSEDES 166, NOT JUST AMENDS IT ========================
-- Owner redesign, same day, after 166 shipped: the eligibility test and the capital-treatment model
-- both change in ways that are not simple parameter tweaks.
--
--   1. ELIGIBILITY BECOMES PERMANENT, NOT CONDITIONAL. 166's `is_dormant` required BOTH a declared-
--      frequency classification AND >=90 days since last deployment AND recent evaluation activity —
--      a strategy could cycle in and out of "dormant" as its own idle clock reset. The owner's redesign
--      makes this a fixed, structural property of the strategy's declared mechanism: any capital-enabled
--      strategy declared at <=1 trade/month (`state.strategy_declared_frequency.is_low_frequency_by_design`,
--      unchanged from 166) is classified **NOMADIC**, permanently, independent of when it last traded.
--      The days-since-deployment and evaluations_60d gates are DROPPED — they answered "is this
--      strategy CURRENTLY idle," a question that no longer matters once idleness isn't the trigger.
--      The one gate that survives is structural, not behavioral: no open position (never sweep capital
--      out from under a live trade).
--
--   2. THE $2,000 RESERVE FLOOR IS RETIRED. A NOMADIC strategy holds NO exclusive standing capital, not
--      even a small self-funding reserve — 166's floor was a compromise for a strategy that might
--      idle-then-un-idle within the same capital band; a permanently-nomadic strategy has no "at rest"
--      state that isn't $0. The daily sweep now moves the FULL idle balance, not the excess above a floor.
--
--   3. THE ON-DEMAND BORROW IS NO LONGER CAPPED AT THE STRATEGY'S OWN SWEPT-OUT HISTORY. 166's RESTORE
--      returned only "money this strategy itself previously had swept from it" (`LEAST(amount_needed,
--      outstanding_debt)`) — a receivable-return model. The owner's redesign is a borrowing model: size
--      is determined ENTIRELY by the AI's normal seven-factor risk-budget judgment (no ceiling, same
--      discipline every strategy's sizing already carries — Experiment_Parameters.md rev 19), and the
--      borrow mechanism's only job is to SOURCE that AI-determined amount, proportionally, from whatever
--      capital the OTHER enabled non-nomadic strategies currently hold. It is not a second, narrower cap
--      layered on top of the sizing discipline that already governs every other strategy. Consequently
--      `state.nomadic_capital_ledger.net_position` (renamed from 166's one-directional `outstanding_debt`)
--      can go NEGATIVE — a nomadic strategy that borrows more than it has ever had swept from it now owes
--      its OWN future proceeds back to its lenders, not merely "its own money."
--
--   4. BOTH DIRECTIONS ARE PLAIN PRO-RATA TO EACH OTHER ENABLED STRATEGY'S `available_funds` — not
--      166's capacity-weighted tilt (`state.sweep_recipient_weights`, built for the REGIME sweep's
--      distinguishable-skill signal). Owner directive, both directions: "borrows proportionally from all
--      other enabled strategies." Proportional-to-size is simpler, symmetric between the sweep-out and
--      borrow-in directions, and reuses the SAME pro-rata idiom `bigquery/98`'s own RESTORE already uses
--      ("pro-rata by their available_funds") rather than introducing a second weighting scheme.
--
--   5. NEW — NOMADIC STRATEGIES ARE EXCLUDED FROM EVERY OTHER CAPITAL-INFLOW RECIPIENT SET, NOT JUST
--      SWEPT AFTER THE FACT. 166 only ever cleaned up AFTER capital landed on a dormant strategy (e.g. a
--      deposit or a regime sweep could still route a share to C, which 166's own next daily pass would
--      then sweep back out). That round-trip is a real gap against "will not have its own exclusive
--      capital" — this file closes it by excluding NOMADIC strategies from `state.regime_capital_sync_pending`'s
--      SWEEP recipient set (`bigquery/98`, redefined below — object 6) and by amending Operating_Protocols.md
--      §16's deposit/termination allocation-call recipient set (prose change, not in this file). A
--      NOMADIC strategy's own realized gains still accrete to its tracked `analytics.strategy_nav.nav`
--      exactly as before (that is untouched — nothing here changes how a strategy's OWN P&L is measured
--      for kill-trigger/30-trade-gate/TWR purposes); what changes is that the CASH backing that NAV
--      never sits idle in its own bucket — it lives with the currently-active strategies until called for.

-- ===== 1. Kill-switch (renamed from ops.capital_dormancy_control) =====
DROP TABLE IF EXISTS `stock-trading-498512.ops.capital_dormancy_control`;

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.capital_nomad_control`
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
  description="Append-only nomadic-capital kill-switch (owner directive 2026-08-11; renamed from ops.capital_dormancy_control, bigquery/166, same day — see bigquery/167 header). Latest row by control_ts wins (state.nomadic_capital_control_latest). enabled=FALSE means state.nomadic_capital_sync_pending still computes its rows but D2a records what it would have moved and moves nothing; the on-demand analytics.fn_nomadic_capital_restore_plan TVF is also gated by this switch inside the function body, so pausing this control blocks BOTH directions of movement. Seeded enabled=TRUE so the loop starts open; flip with a manual INSERT."
);

INSERT INTO `stock-trading-498512.ops.capital_nomad_control` (enabled, reason, set_by)
SELECT TRUE, 'seed — nomadic capital mechanism enabled (owner directive 2026-08-11, redesign of bigquery/166)', 'bigquery/167 seed'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.capital_nomad_control`);

DROP VIEW IF EXISTS `stock-trading-498512.state.capital_dormancy_control_latest`;

CREATE OR REPLACE VIEW `stock-trading-498512.state.nomadic_capital_control_latest`
AS WITH ctrl AS (
  SELECT ARRAY_AGG(
           STRUCT(enabled, reason, set_by, control_ts)
           ORDER BY control_ts DESC LIMIT 1
         )[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.capital_nomad_control`
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  ctrl.latest.reason                   AS reason,
  ctrl.latest.set_by                   AS set_by,
  ctrl.latest.control_ts               AS control_ts
FROM ctrl;

-- ===== 2. state.strategy_nomadic_status — PERMANENT classification (renamed + redesigned from
-- state.strategy_capital_dormancy). state.strategy_declared_frequency (bigquery/166) is REUSED
-- unchanged — its is_low_frequency_by_design column is exactly the "<=1 trade/month declared" fact
-- this classification keys on; only the consumer changes. =====
DROP VIEW IF EXISTS `stock-trading-498512.state.strategy_capital_dormancy`;

-- SUPERSEDED LIVE by bigquery/168_nomadic_capital_fixes.sql — current single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation. 168 rebuilds this view directly off strategy_roster +
-- strategy_nav + position_lifecycle + declared_frequency so a capital-disabled nomadic strategy
-- (e.g. D) still gets a row instead of silently vanishing, and drops the evaluations_60d anti-join
-- this definition no longer needed (audit findings 13 + the cost problem).
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_nomadic_status` AS
SELECT
  w.strategy_code,
  w.idle_capital,
  w.nav,
  w.deployed_mv,
  w.open_positions,
  w.days_since_deployment,
  w.evaluations_60d,
  f.declared_frequency_text,
  COALESCE(f.is_low_frequency_by_design, FALSE)                 AS is_nomadic,
  -- No reserve floor (bigquery/166 kept $2,000; retired here — a nomadic strategy has no "at rest"
  -- balance that isn't zero). The full idle_capital sweeps whenever this reads TRUE and there is
  -- anything to move.
  (
    COALESCE(f.is_low_frequency_by_design, FALSE)
    AND w.open_positions = 0
    AND w.idle_capital > 0
  )                                                              AS sweep_now,
  w.idle_capital                                                 AS sweepable_amount
FROM `stock-trading-498512.state.capital_utilisation_watch` w
LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f ON f.strategy_code = w.strategy_code;

-- ===== 3. state.nomadic_capital_ledger — renamed + redesigned from state.capital_dormancy_debt.
-- net_position can be NEGATIVE (see header point 3): swept_out_total tracks what left a nomadic
-- strategy while idle; restored_total tracks what it has pulled back (which, unlike bigquery/166, is no
-- longer capped at swept_out_total — a nomadic strategy can borrow more than its own sweep history). =====
DROP VIEW IF EXISTS `stock-trading-498512.state.capital_dormancy_debt`;

CREATE OR REPLACE VIEW `stock-trading-498512.state.nomadic_capital_ledger`
AS WITH swept AS (
  SELECT strategy, -SUM(amount) AS swept_out_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'nomadic_capital_sweep' AND amount < 0
  GROUP BY strategy
),
restored AS (
  SELECT strategy, SUM(amount) AS restored_total
  FROM `stock-trading-498512.events.cash_flows`
  WHERE source = 'nomadic_capital_restore' AND amount > 0
  GROUP BY strategy
)
SELECT
  r.strategy_code                                             AS strategy,
  COALESCE(sw.swept_out_total, 0)                             AS swept_out_total,
  COALESCE(rs.restored_total, 0)                               AS restored_total,
  -- Positive: this strategy has more swept-out than restored (owed capital sitting with others).
  -- Negative: this strategy has borrowed more than it ever had swept from it (owes its own future
  -- proceeds back). Zero: fully squared up. Deliberately NOT GREATEST(0, ...) — see header point 3.
  COALESCE(sw.swept_out_total, 0) - COALESCE(rs.restored_total, 0) AS net_position
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN swept    sw ON sw.strategy = r.strategy_code
LEFT JOIN restored rs ON rs.strategy = r.strategy_code;

-- ===== 4. state.nomadic_capital_sync_pending — SWEEP rows, daily/D2a-executed (renamed + redesigned
-- from state.capital_dormancy_sync_pending). Sweeps the FULL idle balance (no floor). Recipients split
-- PLAIN PRO-RATA to their own available_funds (owner directive: "borrows proportionally from all other
-- enabled strategies" — applied symmetrically to the sweep-out direction too, same pro-rata-to-
-- available_funds idiom bigquery/98's own RESTORE already uses), not bigquery/164's capacity weight. =====
DROP VIEW IF EXISTS `stock-trading-498512.state.capital_dormancy_sync_pending`;

-- SUPERSEDED LIVE by bigquery/168_nomadic_capital_fixes.sql — current single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation. 168 nets sweepable_amount against
-- state.open_orders.reserved_cash (GREATEST(0, available_funds - reserved_cash), the same
-- never-sweep-cash-a-pending-buy-needs rule Operating_Protocols.md §13 already applies to the park
-- sweep) so the sweep can no longer claw back cash a same-session pending BUY still needs (audit
-- finding 3, HIGH); adds a window-function last-row-absorbs-the-penny rule so
-- SUM(counterparty_amount) is exactly `amount` by construction; casts counterparty_amount to
-- NUMERIC; and emits an explicit blocked row when no eligible recipient exists instead of zero rows.
CREATE OR REPLACE VIEW `stock-trading-498512.state.nomadic_capital_sync_pending`
AS WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.nomadic_capital_control_latest`
),
-- Single read of state.strategy_nomadic_status (which layers on the expensive
-- state.capital_utilisation_watch chain) — reused below for both the sweep list and the recipient
-- exclusion, exactly the single-read fix bigquery/166 needed live on 2026-08-11 after its first draft
-- invoked the equivalent view twice and timed out.
sns AS (
  SELECT strategy_code, is_nomadic, sweep_now, sweepable_amount
  FROM `stock-trading-498512.state.strategy_nomadic_status`
),
sweeping AS (
  SELECT strategy_code, sweepable_amount
  FROM sns
  WHERE sweep_now AND sweepable_amount >= 25
),
recipients AS (
  SELECT e.strategy_code, nv.available_funds
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  LEFT JOIN sns ON sns.strategy_code = e.strategy_code
  JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = e.strategy_code
  WHERE e.capital_enabled AND NOT COALESCE(sns.is_nomadic, FALSE)
),
recipients_total AS (SELECT SUM(available_funds) AS total, COUNT(*) AS n FROM recipients),
n_recipients AS (SELECT COUNT(*) AS n FROM recipients),
weights AS (
  SELECT r.strategy_code,
    CASE
      -- Plain pro-rata to available_funds when the pool has real size; equal split only if every
      -- eligible recipient reads exactly $0 (a genuine edge case, not the normal path), so this can
      -- never divide by zero.
      WHEN rt.total > 0 THEN r.available_funds / rt.total
      ELSE 1.0 / n.n
    END AS share
  FROM recipients r
  CROSS JOIN recipients_total rt
  CROSS JOIN n_recipients n
)
SELECT
  'SWEEP'                                        AS action,
  s.strategy_code                                AS strategy,
  s.sweepable_amount                             AS amount,
  w.strategy_code                                AS counterparty_strategy,
  ROUND(s.sweepable_amount * w.share, 2)         AS counterparty_amount,
  ctrl.control_enabled
FROM sweeping s
CROSS JOIN weights w
CROSS JOIN ctrl
ORDER BY strategy, counterparty_strategy;

-- ===== 5. analytics.fn_nomadic_capital_restore_plan — on-demand BORROW (renamed + redesigned from
-- analytics.fn_capital_dormancy_restore_plan). No debt cap: pulls exactly p_amount_needed (the AI's own
-- sized risk budget — this function does not second-guess it), clamped only by total donor capacity,
-- pro-rata to each donor's available_funds. =====
DROP TABLE FUNCTION IF EXISTS `stock-trading-498512.analytics.fn_capital_dormancy_restore_plan`;

-- SUPERSEDED LIVE by bigquery/168_nomadic_capital_fixes.sql — current single source of truth for
-- this table function. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. 168 fixes plan_total, which this definition
-- returns as the UNCLAMPED p_amount_needed while pull_amount is the clamped LEAST(p_amount_needed,
-- total) figure — a caller reading plan_total here would believe a partially-funded borrow was
-- fully funded (audit finding 5, CRITICAL). 168 makes plan_total the clamped figure and adds
-- requested_amount + is_fully_funded, and also ports the last-row-absorbs-the-penny rule and NUMERIC
-- typing from its sibling sweep-view fix.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`(
  p_strategy STRING, p_amount_needed NUMERIC
)
AS (
  WITH ctrl AS (
    SELECT enabled AS control_enabled FROM `stock-trading-498512.state.nomadic_capital_control_latest`
  ),
  donors AS (
    -- Nomadic exclusion reads the cheap state.strategy_declared_frequency (a static 5-row table), NOT
    -- state.strategy_nomadic_status — that view chains through the costly state.capital_utilisation_watch
    -- -> state.decision_log_current superseded-row anti-join and measured 3.7M+ slot-ms for a single
    -- read live, 2026-08-11; is_nomadic is a straight pass-through of is_low_frequency_by_design with no
    -- other gating, so this is a correctness-neutral, purely-cheaper substitution. Caught live when the
    -- first draft of state.regime_capital_sync_pending (object 6 below), which needs this same
    -- exclusion 4 times over, consistently timed out on read.
    SELECT e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
    FROM `stock-trading-498512.state.strategy_capital_enablement` e
    JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = e.strategy_code
    WHERE e.capital_enabled
      AND e.strategy_code != p_strategy
      AND e.strategy_code NOT IN (
        SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency` WHERE is_low_frequency_by_design
      )
      AND nv.available_funds > 0
  ),
  donor_total AS (SELECT SUM(donor_capacity) AS total FROM donors)
  SELECT
    p_strategy                                                              AS strategy,
    d.donor_strategy,
    d.donor_capacity,
    -- Clamped only by total donor capacity — NOT by this strategy's own outstanding_debt/net_position
    -- (see header point 3). p_amount_needed is the AI's own seven-factor-justified size; sourcing it is
    -- this function's only job.
    ROUND(LEAST(p_amount_needed, dt.total) * d.donor_capacity / dt.total, 2) AS pull_amount,
    p_amount_needed                                                         AS plan_total,
    ctrl.control_enabled
  FROM donors d
  CROSS JOIN donor_total dt
  CROSS JOIN ctrl
  WHERE dt.total > 0
);

-- ===== 6. state.regime_capital_sync_pending (bigquery/98) — EXCLUDE nomadic strategies from the
-- regime-sweep recipient set. Redefines the ONE existing object this file touches outside its own new
-- objects. See header point 5: without this, a router-disabled strategy's regime sweep could still
-- route a share to a nomadic strategy, which this file's own SWEEP would then have to immediately
-- clean up again — a round-trip against "no exclusive capital, ever." Naturally a no-op on the
-- RESTORE-donor side this same `enabled_set` CTE feeds, since a nomadic strategy's available_funds is
-- ~$0 under steady state anyway (excluding a ~$0-capacity donor from a SUM of positive capacities
-- changes nothing). Every other line of bigquery/98's definition is UNCHANGED, copied verbatim. =====
--
-- SUPERSEDED LIVE by bigquery/215_regime_sweep_blocked_no_recipient.sql — current single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation. 168 splits this definition's single nomadic-exclusive
-- enabled_set into two: a nomadic-EXCLUSIVE set for sweep recipients and restore donors (the actual
-- intent above), and a nomadic-INCLUSIVE set preserving bigquery/98's original semantics for
-- restore_candidates — this definition excluded nomadic strategies from restore_candidates too,
-- which made a nomadic debtor's regime debt permanently unrestorable, silently (audit finding 10,
-- CRITICAL).
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_capital_sync_pending`
AS WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_control_latest`
),
enablement AS (
  SELECT * FROM `stock-trading-498512.state.strategy_capital_enablement`
),
enabled_set AS (
  -- CHANGED (bigquery/167): excludes nomadic strategies, added 2026-08-11 — see this file's header
  -- point 5. Reads the cheap state.strategy_declared_frequency, NOT state.strategy_nomadic_status —
  -- functionally identical exclusion (is_nomadic is a straight pass-through of is_low_frequency_by_design
  -- with no other gating) but this CTE is referenced 4 times downstream, and the expensive form
  -- measured 3.7M+ slot-ms for a SINGLE read live, 2026-08-11 — multiplied across 4 references it
  -- consistently timed out the read path until swapped to this cheaper source.
  SELECT strategy_code FROM enablement e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (
      SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency` WHERE is_low_frequency_by_design
    )
),
n_enabled AS (
  SELECT COUNT(*) AS n FROM enabled_set
),
nav AS (
  SELECT strategy, ROUND(available_funds, 2) AS available_funds
  FROM `stock-trading-498512.analytics.strategy_nav`
),
sweep_candidates AS (
  SELECT e.strategy_code AS strategy, nv.available_funds AS amount
  FROM enablement e
  JOIN nav nv ON nv.strategy = e.strategy_code
  WHERE e.capital_disabled AND nv.available_funds >= 25
),
sweep_rows AS (
  SELECT
    'SWEEP'                     AS action,
    sc.strategy,
    sc.amount,
    es.strategy_code            AS counterparty_strategy,
    ROUND(sc.amount / n.n, 2)   AS counterparty_baseline_amount
  FROM sweep_candidates sc
  CROSS JOIN n_enabled n
  CROSS JOIN enabled_set es
),
debt AS (
  SELECT strategy, outstanding_debt
  FROM `stock-trading-498512.state.regime_capital_debt`
  WHERE outstanding_debt > 0
),
restore_candidates AS (
  SELECT es.strategy_code AS strategy, d.outstanding_debt
  FROM enabled_set es
  JOIN debt d ON d.strategy = es.strategy_code
),
donors AS (
  SELECT rc.strategy AS debtor, nv.strategy AS donor_strategy, nv.available_funds AS donor_capacity
  FROM restore_candidates rc
  JOIN enabled_set es ON es.strategy_code != rc.strategy
  JOIN nav nv ON nv.strategy = es.strategy_code
  WHERE nv.available_funds > 0
),
donor_totals AS (
  SELECT debtor, SUM(donor_capacity) AS total_donor_capacity
  FROM donors
  GROUP BY debtor
),
restore_payable AS (
  SELECT
    rc.strategy,
    rc.outstanding_debt,
    LEAST(rc.outstanding_debt, COALESCE(dt.total_donor_capacity, 0)) AS payable
  FROM restore_candidates rc
  LEFT JOIN donor_totals dt ON dt.debtor = rc.strategy
),
restore_rows AS (
  SELECT
    'RESTORE'                                                          AS action,
    rp.strategy,
    ROUND(rp.payable, 2)                                               AS amount,
    dn.donor_strategy                                                  AS counterparty_strategy,
    ROUND(rp.payable * dn.donor_capacity / dt.total_donor_capacity, 2) AS counterparty_baseline_amount
  FROM restore_payable rp
  JOIN donor_totals dt ON dt.debtor = rp.strategy
  JOIN donors dn ON dn.debtor = rp.strategy
  WHERE rp.payable >= LEAST(25, rp.outstanding_debt)
)
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, ctrl.control_enabled
FROM sweep_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, ctrl.control_enabled
FROM restore_rows CROSS JOIN ctrl
ORDER BY action, strategy, counterparty_strategy;

-- ===== 7. Extend the sanctioned events.cash_flows.source set (bigquery/163) — swap the retired
-- capital_dormancy_* tags for the new nomadic_capital_* ones. capital_dormancy_sweep/restore never
-- appear in any live row (verified — zero rows ever written through bigquery/166's mechanism), so
-- dropping them from the sanctioned set orphans nothing. =====
-- SUPERSEDED LIVE by bigquery/214_account_fee_recording.sql -- current single source of truth for
-- this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. 214 adds 'account_fee' to the sanctioned source allowlist (chain: 163 -> 167 -> 214), so the
-- recurring-account-fee rows written by ops.sp_record_account_fee are not flagged as unsanctioned
-- provenance. No other change.
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
      'nomadic_capital_sweep',   -- bigquery/167 (renamed from capital_dormancy_sweep)
      'nomadic_capital_restore'  -- bigquery/167 (renamed from capital_dormancy_restore)
    )
    OR source LIKE 'backfill-%'
    )
  );

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Old dormancy objects are gone:
--    SELECT table_name FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.TABLES` WHERE table_name = 'capital_dormancy_control';
--    SELECT table_name FROM `stock-trading-498512.state.INFORMATION_SCHEMA.VIEWS` WHERE table_name LIKE '%dormancy%';
--    -> expect zero rows from both.
--
-- 2. Classification reads correctly (expect C is_nomadic=TRUE, sweep_now=TRUE, sweepable_amount = FULL
--    idle_capital (no floor subtracted); E is_nomadic=FALSE):
--    SELECT strategy_code, idle_capital, is_nomadic, sweep_now, sweepable_amount
--    FROM `stock-trading-498512.state.strategy_nomadic_status` ORDER BY strategy_code;
--
-- 3. Sweep plan sweeps the FULL balance now, not excess-above-2000, split pro-rata to recipients'
--    available_funds (today: E is the only eligible recipient, so 100% to E regardless of weighting
--    scheme — the redesign is only distinguishable from bigquery/166's once a second recipient exists):
--    SELECT strategy, SUM(counterparty_amount) AS recipients_sum, ANY_VALUE(amount) AS swept_amount
--    FROM `stock-trading-498512.state.nomadic_capital_sync_pending` GROUP BY strategy;
--
-- 4. The restore plan is uncapped by history (expect a nonzero pull_amount now, unlike bigquery/166's
--    fn_capital_dormancy_restore_plan, which returned 0 for any amount_needed because outstanding_debt
--    was 0 — no sweep had ever executed):
--    SELECT * FROM `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`('C', 500.00);
--
-- 5. Regime-sweep recipient set excludes nomadic strategies (today: with A/B/D disabled and C nomadic,
--    E is the ONLY possible recipient of any regime sweep — live-verified 2026-08-11 against a genuine
--    pending row this fix surfaced: B, currently DO-NOT-ACTIVATE, holds $48.92 available_funds eligible
--    for the regime sweep; the row correctly routes 100% to E, not split with nomadic C as it would
--    have been pre-fix):
--    SELECT * FROM `stock-trading-498512.state.regime_capital_sync_pending`;
--
-- 6. The extended source set is clean:
--    SELECT * FROM `stock-trading-498512.state.cash_flow_source_unknown`;
--    -> expect zero rows.

-- bigquery/168_nomadic_capital_fixes.sql (2026-08-11)
-- Project: stock-trading-498512. Apply after bigquery/167_nomadic_capital.sql.
--
-- SUPERSEDES three objects from bigquery/167 (state.strategy_nomadic_status,
-- state.nomadic_capital_sync_pending, analytics.fn_nomadic_capital_restore_plan) and redefines three
-- pre-existing objects it interacts badly with (state.regime_capital_sync_pending from bigquery/98 via
-- 167, state.regime_restore_shortfall_risk from bigquery/164, state.strategy_funds_deficit from
-- bigquery/161). SUPERSEDED markers are added at each prior definition site in the same change.
--
-- ============================ WHY ================================================================
-- bigquery/167 shipped earlier the same day and was then audited adversarially (7 parallel finders +
-- per-finding refutation, 2026-08-11). The audit confirmed 20 defects. This file fixes the six that
-- are SQL-side; the rest are prose/CI and are fixed in the same commit outside this file.
--
-- NOTHING HAS MOVED YET. Zero events.cash_flows rows carry a nomadic_capital_* source, so every fix
-- here is pre-incident. No compensating entry or backfill is owed.
--
-- FIX 1 (audit finding 13 + the cost problem) — state.strategy_nomadic_status was built FROM
--   state.capital_utilisation_watch, which inherits TWO properties it should never have inherited:
--   (a) that view's `enabled` CTE filters WHERE capital_enabled AND is_active, so a capital-DISABLED
--       nomadic strategy has NO ROW AT ALL. D is nomadic and currently capital-disabled, so the view
--       that exists to answer "who is nomadic" silently omits one of the two nomadic strategies,
--       disagreeing with state.strategy_declared_frequency, which the two cross-cutting consumers were
--       separately routed to read instead. A view whose answer depends on an unrelated axis is a trap.
--   (b) its evals CTE anti-joins state.decision_log_current over the whole decision log, costing
--       1M-3.7M+ slot ms per read. The 167 redesign STOPPED GATING on evaluations_60d — so 167 was
--       paying that cost, and inheriting that filter, for a column it no longer used.
--   Rebuilt here directly on strategy_roster + strategy_nav + position_lifecycle + declared_frequency.
--   Covers every roster-ACTIVE strategy regardless of capital enablement; drops evaluations_60d.
--
-- FIX 2 (audit finding 3, HIGH — the most dangerous one) — the SWEEP never consulted
--   state.open_orders.reserved_cash. sweep_now gated only on open_positions=0, which is sourced from
--   analytics.position_lifecycle, i.e. from CONFIRMED FILLS. A nomadic strategy that borrows cash and
--   stages an order which does not fill same session has open_positions=0 all night, so D2a's next
--   Step 0 would sweep the borrowed cash straight back out from under its own pending order. This repo
--   already solved this exact problem once: Operating_Protocols.md §13 step 1 computes
--   free_cash = settled_cash - SUM(reserved_cash) for the park sweep, "Never sweep cash a pending buy
--   needs," citing the 2026-06-08 MDT de-funding incident. state.open_orders.reserved_cash is already
--   BUY-only, already OCC-aware (x100 for option contracts), already carries the $0.35 commission
--   buffer, and is already filtered to status='pending'. The nomadic sweep now nets against it, exactly
--   like §13.E. sweepable_amount = GREATEST(0, available_funds - reserved_cash).
--
-- FIX 3 (audit findings 6/18/2, HIGH) — per-recipient ROUND() with no residual absorption meant
--   SUM(counterparty_amount) could differ from `amount` by a cent once >=2 recipients exist, so the
--   "atomic $0-sum double-entry" the prose promises was not structurally guaranteed. Both sibling
--   mechanisms in this codebase already solve this (bigquery/98's sweep: last row absorbs the penny;
--   bigquery/161's withdrawal allocator: residual to the largest donor). Ported here to BOTH the sweep
--   view and the borrow TVF via a window-function last-row-absorbs rule, so the identity is exact by
--   construction rather than by the caller remembering a convention.
--
-- FIX 4 (audit finding 7) — counterparty_amount came back FLOAT64 while its sibling `amount` is
--   NUMERIC, because the equal-split fallback branch `1.0 / n.n` is a FLOAT64 literal and forced the
--   CASE's common supertype to FLOAT64. A money column silently typed as binary floating point is a
--   precision hazard and diverges from every other money column in the schema. Now NUMERIC throughout.
--
-- FIX 5 (audit finding 9) — when NO eligible non-nomadic recipient exists, the CROSS JOIN produced
--   zero rows, which D2a reads as "steady state, nothing to sweep" — indistinguishable from "there IS
--   capital to sweep and nowhere legal to put it." Now emits an explicit blocked row
--   (counterparty_strategy NULL, blocked_no_recipient TRUE) so the executor can tell the two apart.
--
-- FIX 6 (audit finding 5, CRITICAL) — fn_nomadic_capital_restore_plan returned
--   `p_amount_needed AS plan_total` while pull_amount was computed from LEAST(p_amount_needed, total).
--   A caller reading plan_total to confirm funding would believe a partially-funded borrow was fully
--   funded, and craft an order the borrowed cash does not cover. plan_total is now the CLAMPED figure;
--   `requested_amount` and `is_fully_funded` are added so the shortfall is impossible to miss.
--
-- FIX 7 (audit finding 10, CRITICAL) — bigquery/167 excluded nomadic strategies from
--   state.regime_capital_sync_pending's `enabled_set` intending only to stop a regime sweep routing a
--   share to a nomadic recipient. But that ONE CTE also feeds restore_candidates. Since nomadic status
--   is PERMANENT, D (nomadic, and carrying $4,376.85 of regime-capital debt) could never again be a
--   restore candidate: its debt became permanently unrestorable, silently. enabled_set is now split —
--   a nomadic-EXCLUSIVE set for sweep recipients and restore donors (the actual intent), and a
--   nomadic-INCLUSIVE set preserving bigquery/98's original semantics for restore_candidates. A
--   re-enabling nomadic strategy reclaims its regime debt normally; the nomadic sweep may then move it
--   on, which is correct and is a one-time hand-off between two ledgers, not a loop.
--
-- FIX 8 (audit finding 11, HIGH) — state.regime_restore_shortfall_risk's donors CTE still sums ALL
--   capital-enabled strategies' available_funds, including nomadic ones. Under steady state a nomadic
--   strategy holds ~$0 so the arithmetic barely moves, but the view's PURPOSE is to answer "could every
--   debtor actually be made whole," and it was computing that against a donor set the live restore
--   mechanism no longer uses. Aligned to the same nomadic-exclusive donor set.
--
-- FIX 9 (audit finding 1, HIGH) — state.strategy_funds_deficit fires on `deposits < 0` with
--   likely_cause "a flow was allocated to a strategy that did not hold it". For a nomadic strategy that
--   is now the NORMAL steady state after any profitable trade, not a misallocation: the sweep removes
--   available_funds (= deposits + realized + unrealized + dividends - deployed_mv), so with deployed=0
--   the post-sweep balance is exactly deposits = -(realized + unrealized + dividends). One winning
--   trade puts a nomadic strategy permanently negative-deposits, and every further win deepens it. The
--   alert is WARNING (non-halting) but would be permanently open and actively misleading — the audit
--   verifier noted the real hazard is a future session "fixing" it with a corrective cash_flow entry,
--   which would be the genuinely dangerous action. Carve-out is deliberately NARROW: available_funds<0
--   still fires for everyone; deposits<0 still fires for every non-nomadic strategy; and it STILL fires
--   for a nomadic strategy if nav is ALSO negative, because then the negative deposits is NOT explained
--   by swept-out own P&L and is a real integrity problem.
--   (Note: the audit's originally-suggested fix keyed on nomadic_capital_ledger.net_position < 0. That
--   is wrong — at the moment deposits goes negative, net_position is strongly POSITIVE, since
--   deposits = original - net_position. Keyed on the classification + nav sign instead.)

-- ============================ KNOWN LIMITATION, DELIBERATELY NOT "FIXED" HERE ====================
-- MULTI-LEG OPTIONS AND open_positions / deployed_mv (audit finding 4, MEDIUM; PRE-EXISTING, not
-- introduced by the nomadic work, but it lands on this mechanism so it is recorded here).
--
-- A multi-leg combo is staged as ONE ORDER_STAGED row under one combo contract_id_ex, and the
-- STAGING-OPEN KEY INVARIANT mints exactly ONE position_key for it. events.position_events /
-- state.current_positions are schema-SINGULAR (one ticker/contract_id/shares/cost_basis per row) and
-- state.current_positions is latest-wins with NO coalescing. If IBKR reports a combo fill as separate
-- per-leg executions under distinct trade_ids, D2a Step 0's per-trade_id loop would write one OPEN row
-- per leg all keyed to that single position_key, and only the LAST leg processed would survive.
-- Strategy C has never traded, so this is INFERRED from schema, not observed.
--
-- WHY THE SWEEP GATE IS NEVERTHELESS SAFE, and why this is not escalated: every structure C is
-- permitted to build (debit spread, credit spread, iron condor, butterfly) is DEFINED-RISK, which by
-- construction requires at least one LONG leg -- that is what caps the loss. A long lot always leaves
-- an unconsumed-buy row in analytics.position_lifecycle until it is closed or expires, so
-- open_positions >= 1 for the whole life of any C structure, and sweep_now is FALSE throughout. The
-- sweep therefore cannot fire out from under a live C structure. (An adversarial reviewer proposed the
-- counter-case of a naked short leg surviving alone after its long leg expired worthless; that was
-- checked against position_lifecycle's own SQL and REFUTED -- the expiring long leg does not stop
-- counting as open.)
--
-- WHAT IS GENUINELY EXPOSED: the AMOUNT, not the gate. If per-leg OPEN rows overwrite each other,
-- SUM(cost_basis) understates committed capital, which inflates available_funds, which would let the
-- sweep move more than it should and the borrow ask for less than it should. Bounded, and it cannot
-- de-fund a live position (the gate holds), so it does not warrant redesigning the options staging
-- path blind, before a single real fill has ever been observed.
--
-- REQUIRED ACTION ON C's FIRST MULTI-LEG FILL: verify how Step 0 reconciled the legs -- one OPEN row
-- per leg (correct, if per-leg position_keys were minted) vs one surviving row (the defect). Until
-- that observation exists, treat any nomadic sweep/borrow AMOUNT for a strategy with options history
-- as unverified. This is flagged in Claude_Task_Plan.md's options-crafting step as well.

-- ===== FIX 1 + FIX 2. state.strategy_nomadic_status — rebuilt off the full roster, reserved-cash aware.
-- SUPERSEDES bigquery/167_nomadic_capital.sql's definition of this view.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_nomadic_status` AS
WITH roster AS (
  SELECT strategy_code
  FROM `stock-trading-498512.state.strategy_roster`
  WHERE is_active
),
nav AS (
  SELECT strategy, deposits, nav, deployed_mv, available_funds
  FROM `stock-trading-498512.analytics.strategy_nav`
),
-- Confirmed-fill open lots only, dust-excluded (bigquery/125's audited is_dust, NULL failing open as
-- non-dust) -- the same predicate every other position_lifecycle reader uses. This is a FILLS-based
-- signal and deliberately does NOT see pending orders; that is what the reserved CTE below is for.
deploy AS (
  SELECT strategy AS strategy_code, COUNTIF(exit_date IS NULL) AS open_positions
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy
),
-- Cash a pending staged BUY already needs. state.open_orders is latest-row-per-item_key and already
-- filtered to status='pending'; its reserved_cash is BUY-only, OCC-aware (x100 on option contracts)
-- and includes the 0.35 commission buffer. Mirrors Operating_Protocols.md §13's park-sweep free_cash.
reserved AS (
  SELECT strategy AS strategy_code, SUM(COALESCE(reserved_cash, 0)) AS reserved_cash_total
  FROM `stock-trading-498512.state.open_orders`
  WHERE strategy IS NOT NULL
  GROUP BY strategy
)
SELECT
  r.strategy_code,
  ROUND(COALESCE(n.available_funds, 0), 2)                        AS idle_capital,
  ROUND(COALESCE(n.nav, 0), 2)                                    AS nav,
  ROUND(COALESCE(n.deployed_mv, 0), 2)                            AS deployed_mv,
  COALESCE(d.open_positions, 0)                                   AS open_positions,
  ROUND(COALESCE(rv.reserved_cash_total, 0), 2)                   AS reserved_cash_total,
  COALESCE(ce.capital_enabled, FALSE)                             AS capital_enabled,
  f.declared_frequency_text,
  COALESCE(f.is_low_frequency_by_design, FALSE)                   AS is_nomadic,
  -- What is genuinely free to move: idle cash NET of anything a pending buy already claims.
  GREATEST(
    CAST(0 AS NUMERIC),
    ROUND(COALESCE(n.available_funds, 0) - COALESCE(rv.reserved_cash_total, 0), 2)
  )                                                                AS sweepable_amount,
  (
    COALESCE(f.is_low_frequency_by_design, FALSE)
    -- Capital-DISABLED strategies are the regime mechanism's business (bigquery/98); never let two
    -- mechanisms contend for the same dollars. A nomadic strategy still shows is_nomadic=TRUE here
    -- while disabled -- that is the whole point of FIX 1 -- it just does not sweep on this path.
    AND COALESCE(ce.capital_enabled, FALSE)
    AND COALESCE(d.open_positions, 0) = 0
    AND GREATEST(
          CAST(0 AS NUMERIC),
          ROUND(COALESCE(n.available_funds, 0) - COALESCE(rv.reserved_cash_total, 0), 2)
        ) > 0
  )                                                                AS sweep_now
FROM roster r
LEFT JOIN nav n  ON n.strategy = r.strategy_code
LEFT JOIN deploy d ON d.strategy_code = r.strategy_code
LEFT JOIN reserved rv ON rv.strategy_code = r.strategy_code
LEFT JOIN `stock-trading-498512.state.strategy_capital_enablement` ce ON ce.strategy_code = r.strategy_code
LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f ON f.strategy_code = r.strategy_code;

-- ===== FIX 3 + FIX 4 + FIX 5. state.nomadic_capital_sync_pending — exact $0-sum, NUMERIC, blocked row.
-- SUPERSEDES bigquery/167_nomadic_capital.sql's definition of this view.
CREATE OR REPLACE VIEW `stock-trading-498512.state.nomadic_capital_sync_pending` AS
WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.nomadic_capital_control_latest`
),
sns AS (
  SELECT strategy_code, is_nomadic, capital_enabled, sweep_now, sweepable_amount
  FROM `stock-trading-498512.state.strategy_nomadic_status`
),
-- The >=25 floor is a de-minimis MOVEMENT threshold (avoids dust cash_flows rows), NOT a retained
-- reserve: it is the same figure bigquery/98's regime sweep uses. Below it, the balance simply waits.
-- Documented as such in Operating_Protocols.md §16 -- the earlier "no floor whatsoever" wording was
-- corrected in the same change (audit findings 8/17).
sweeping AS (
  SELECT strategy_code, sweepable_amount FROM sns WHERE sweep_now AND sweepable_amount >= 25
),
recipients AS (
  SELECT s.strategy_code, GREATEST(nv.available_funds, CAST(0 AS NUMERIC)) AS available_funds
  FROM sns s
  JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = s.strategy_code
  WHERE s.capital_enabled AND NOT s.is_nomadic
),
rt AS (SELECT SUM(available_funds) AS total, COUNT(*) AS n FROM recipients),
weights AS (
  SELECT r.strategy_code,
    CASE
      -- Plain pro-rata to each recipient's own available_funds (owner directive: "borrows
      -- proportionally from all other enabled strategies", applied symmetrically to the sweep-out leg).
      WHEN rt.total > 0 THEN r.available_funds / rt.total
      -- Equal split ONLY when every eligible recipient reads exactly $0. CAST keeps the CASE NUMERIC
      -- (a bare `1.0` literal is FLOAT64 and silently retyped the whole money column -- FIX 4).
      ELSE CAST(1 AS NUMERIC) / CAST(rt.n AS NUMERIC)
    END AS share
  FROM recipients r CROSS JOIN rt
),
alloc AS (
  SELECT
    s.strategy_code                                              AS strategy,
    s.sweepable_amount                                           AS amount,
    w.strategy_code                                              AS counterparty_strategy,
    ROUND(s.sweepable_amount * w.share, 2)                       AS raw_amount,
    ROW_NUMBER() OVER (PARTITION BY s.strategy_code ORDER BY w.strategy_code) AS rn,
    COUNT(*)     OVER (PARTITION BY s.strategy_code)             AS n_cp,
    SUM(ROUND(s.sweepable_amount * w.share, 2))
      OVER (PARTITION BY s.strategy_code ORDER BY w.strategy_code
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)    AS prior_sum
  FROM sweeping s
  CROSS JOIN weights w
),
allocated AS (
  SELECT
    'SWEEP'                     AS action,
    strategy,
    amount,
    counterparty_strategy,
    -- LAST recipient absorbs the rounding residual, so SUM(counterparty_amount) == amount EXACTLY,
    -- for any recipient count. Same convention as bigquery/98's regime sweep (FIX 3).
    CASE WHEN rn = n_cp THEN amount - COALESCE(prior_sum, CAST(0 AS NUMERIC)) ELSE raw_amount END
                                AS counterparty_amount,
    FALSE                       AS blocked_no_recipient
  FROM alloc
),
-- FIX 5: capital to sweep but nowhere legal to put it. Without this the view returns zero rows, which
-- the executor cannot distinguish from the healthy steady state.
blocked AS (
  SELECT
    'SWEEP'                     AS action,
    s.strategy_code             AS strategy,
    s.sweepable_amount          AS amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_amount,
    TRUE                        AS blocked_no_recipient
  FROM sweeping s
  WHERE NOT EXISTS (SELECT 1 FROM weights)
)
-- Alias is `mv` (movement), NOT `rows` -- ROWS is a reserved keyword in BigQuery and aliasing a
-- subquery to it fails with "Unexpected keyword ROWS" (hit live while applying this file).
SELECT mv.*, ctrl.control_enabled
FROM (SELECT * FROM allocated UNION ALL SELECT * FROM blocked) AS mv
CROSS JOIN ctrl
ORDER BY strategy, counterparty_strategy;

-- ===== FIX 3 + FIX 6. analytics.fn_nomadic_capital_restore_plan — clamped plan_total, exact residual.
-- SUPERSEDES bigquery/167_nomadic_capital.sql's definition of this table function.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`(
  p_strategy STRING, p_amount_needed NUMERIC
)
AS (
  WITH ctrl AS (
    SELECT enabled AS control_enabled FROM `stock-trading-498512.state.nomadic_capital_control_latest`
  ),
  donors AS (
    -- Nomadic exclusion reads the cheap static state.strategy_declared_frequency, never
    -- state.strategy_nomadic_status -- same fact, none of the view-chain cost.
    SELECT e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
    FROM `stock-trading-498512.state.strategy_capital_enablement` e
    JOIN `stock-trading-498512.analytics.strategy_nav` nv ON nv.strategy = e.strategy_code
    WHERE e.capital_enabled
      AND e.strategy_code != p_strategy
      AND e.strategy_code NOT IN (
        SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
        WHERE is_low_frequency_by_design
      )
      AND nv.available_funds > 0
  ),
  dt AS (SELECT SUM(donor_capacity) AS total FROM donors),
  funded AS (
    -- The amount actually sourceable RIGHT NOW. p_amount_needed is the AI's own seven-factor-justified
    -- size and is never second-guessed here -- but it CAN exceed what the pool holds, and the caller
    -- must be able to see that (FIX 6).
    SELECT LEAST(p_amount_needed, dt.total) AS funded_amount, dt.total AS donor_total
    FROM dt WHERE dt.total > 0
  ),
  alloc AS (
    SELECT
      d.donor_strategy,
      d.donor_capacity,
      f.funded_amount,
      ROUND(f.funded_amount * d.donor_capacity / f.donor_total, 2)  AS raw_amount,
      ROW_NUMBER() OVER (ORDER BY d.donor_strategy)                 AS rn,
      COUNT(*)     OVER ()                                          AS n_d,
      SUM(ROUND(f.funded_amount * d.donor_capacity / f.donor_total, 2))
        OVER (ORDER BY d.donor_strategy ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_sum
    FROM donors d
    CROSS JOIN funded f
  )
  SELECT
    p_strategy                                                      AS strategy,
    a.donor_strategy,
    a.donor_capacity,
    -- Last donor absorbs the residual so SUM(pull_amount) == plan_total exactly (FIX 3).
    CASE WHEN a.rn = a.n_d THEN a.funded_amount - COALESCE(a.prior_sum, CAST(0 AS NUMERIC))
         ELSE a.raw_amount END                                      AS pull_amount,
    a.funded_amount                                                 AS plan_total,
    p_amount_needed                                                 AS requested_amount,
    (a.funded_amount >= p_amount_needed)                            AS is_fully_funded,
    ctrl.control_enabled
  FROM alloc a
  CROSS JOIN ctrl
);

-- ===== FIX 7. state.regime_capital_sync_pending — split the enabled set.
-- SUPERSEDES bigquery/167_nomadic_capital.sql's definition (which itself superseded bigquery/98's).
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_capital_sync_pending`
AS WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_control_latest`
),
enablement AS (
  SELECT * FROM `stock-trading-498512.state.strategy_capital_enablement`
),
nomadic AS (
  SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
  WHERE is_low_frequency_by_design
),
-- Who may RECEIVE a regime sweep, and who may DONATE to a regime restore: nomadic strategies excluded,
-- because a nomadic strategy holds no standing capital (it would only have to be swept out again).
enabled_recipients AS (
  SELECT strategy_code FROM enablement e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (SELECT strategy_code FROM nomadic)
),
-- Who may be REPAID a pre-existing regime debt: bigquery/98's ORIGINAL, nomadic-INCLUSIVE semantics.
-- Being nomadic must never make an existing debt unrestorable -- that was the bigquery/167 defect
-- (FIX 7). A nomadic debtor is repaid normally; its own sweep may then move that capital on, which is
-- a one-time hand-off from the regime ledger to the nomadic ledger, not a loop.
enabled_debtors AS (
  SELECT strategy_code FROM enablement e WHERE e.capital_enabled
),
n_enabled AS (
  SELECT COUNT(*) AS n FROM enabled_recipients
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
  CROSS JOIN enabled_recipients es
),
debt AS (
  SELECT strategy, outstanding_debt
  FROM `stock-trading-498512.state.regime_capital_debt`
  WHERE outstanding_debt > 0
),
restore_candidates AS (
  SELECT es.strategy_code AS strategy, d.outstanding_debt
  FROM enabled_debtors es
  JOIN debt d ON d.strategy = es.strategy_code
),
donors AS (
  SELECT rc.strategy AS debtor, nv.strategy AS donor_strategy, nv.available_funds AS donor_capacity
  FROM restore_candidates rc
  JOIN enabled_recipients es ON es.strategy_code != rc.strategy
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

-- ===== FIX 8. state.regime_restore_shortfall_risk — donor set aligned to the live restore mechanism.
-- SUPERSEDES bigquery/164_capital_utilisation_and_restore_integrity.sql's definition of this view.
-- Only the `donors` CTE changes (nomadic exclusion + a comment); every other line is bigquery/164's,
-- verbatim, including the deliberately-always-emits-a-row shape its own comment block explains.
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_restore_shortfall_risk` AS
WITH donors AS (
  -- Donor capacity is the capital-ENABLED strategies' undeployed cash -- the same figure bigquery/98's
  -- restore_payable caps against. NOMADIC strategies are excluded (bigquery/168 FIX 8) to stay aligned
  -- with state.regime_capital_sync_pending's donor set, which excluded them as of bigquery/167: a
  -- nomadic strategy holds ~$0 under steady state, so counting it as donor capacity would overstate
  -- how much of a debt could actually be honoured.
  SELECT ROUND(COALESCE(SUM(GREATEST(n.available_funds, 0)), 0), 2) AS donor_capacity
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = e.strategy_code
  LEFT JOIN `stock-trading-498512.analytics.strategy_nav` n ON n.strategy = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
    AND e.strategy_code NOT IN (
      SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
      WHERE is_low_frequency_by_design
    )
),
debt AS (
  SELECT d.strategy, ROUND(d.outstanding_debt, 2) AS outstanding_debt
  FROM `stock-trading-498512.state.regime_capital_debt` d
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = d.strategy
  -- A TERMINATED strategy's debt is extinguished by unreachability (Operating_Protocols.md: RESTORE
  -- targets the enabled set, which filters WHERE is_active), so an inactive strategy's nominal debt
  -- must not be counted here or this view over-reports risk the moment the first termination lands.
  WHERE r.is_active AND d.outstanding_debt > 0
),
-- THE THIRD AND FOURTH CLAIMS ON THE SAME POOL. Independent mechanisms draw on the capital-enabled
-- strategies' idle cash and none of them can see the others: regime-debt RESTORE (above), the SISA
-- PENDING-NEWCOMER probe-stake fill (bigquery/62), external WITHDRAWALS (bigquery/161), and -- added
-- 2026-08-11, bigquery/167 -- a NOMADIC strategy's on-demand BORROW, which draws pro-rata from this
-- same non-nomadic donor pool at order-craft time. The borrow is not pre-declarable (it happens only
-- when a thesis needs it) so it cannot be added as a standing claim column here; it is called out so a
-- reader knows the headroom below is an upper bound that a nomadic borrow can consume without notice.
newcomer AS (
  SELECT ROUND(COALESCE(SUM(GREATEST(funding_gap_dollars, 0)), 0), 2) AS pending_newcomer_claim
  FROM `stock-trading-498512.state.strategy_probe_funding_gap`
)
SELECT
  debt.strategy,
  ROUND(COALESCE(debt.outstanding_debt, 0), 2) AS outstanding_debt,
  donors.donor_capacity,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS total_outstanding_debt,
  newcomer.pending_newcomer_claim,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim, 2)
    AS total_claims_on_idle_pool,
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS aggregate_headroom,
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0)
        - newcomer.pending_newcomer_claim, 2) AS headroom_after_all_claims,
  ROUND(LEAST(COALESCE(debt.outstanding_debt, 0), donors.donor_capacity), 2) AS would_restore_today,
  ROUND(GREATEST(COALESCE(debt.outstanding_debt, 0) - donors.donor_capacity, 0), 2) AS shortfall_if_alone,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0)) AS aggregate_at_risk,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim)
    AS at_risk_including_newcomer_claim,
  (donors.donor_capacity < COALESCE(debt.outstanding_debt, 0)) AS individually_at_risk,
  debt.strategy IS NULL AS is_all_clear_row
FROM donors CROSS JOIN newcomer LEFT JOIN debt ON TRUE;

-- ===== FIX 9. state.strategy_funds_deficit — narrow nomadic carve-out on the deposits<0 arm.
-- SUPERSEDES bigquery/161_withdrawal_after_the_fact.sql's definition of this view.
-- SUPERSEDED (2026-08-18) by bigquery/181_funds_deficit_exempt_any_fully_swept_strategy.sql — do NOT
--   apply this definition. The carve-out below is correct in substance but keyed on the wrong thing:
--   it gates on the strategy being NOMADIC, whereas what makes the row benign is the arithmetic fact
--   that nav >= 0. The REGIME-CAPITAL sweep (bigquery/98) reaches the identical state when a
--   capital-disabled strategy's last position closes — which happened live to Strategy B on
--   2026-08-18 (MSCI invalidation exit, full 47.35 swept, nav to exactly 0, deposits to -18.22),
--   producing precisely the false positive, and precisely the "future session "fixes" it with a
--   corrective cash_flow entry" hazard, that this FIX 9 note names below. bigquery/180 drops the
--   nomadic conjunct and keys the exemption on ROUND(nav,2) < 0 for all strategies.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_funds_deficit` AS
SELECT
  n.strategy,
  ROUND(n.available_funds, 2) AS available_funds,
  ROUND(n.deposits, 2)        AS deposits,
  ROUND(n.nav, 2)             AS nav,
  ROUND(n.deployed_mv, 2)     AS deployed_mv,
  COALESCE(f.is_low_frequency_by_design, FALSE) AS is_nomadic,
  CASE
    WHEN ROUND(n.deposits, 2) < 0 AND COALESCE(f.is_low_frequency_by_design, FALSE)
      THEN 'NOMADIC strategy with negative deposits AND negative NAV - this is NOT the benign swept-out-own-P&L case (which is expected and exempted); investigate as a genuine misallocation'
    WHEN ROUND(n.deposits, 2) < 0
      THEN 'booked deposits are negative - a flow was allocated to a strategy that did not hold it'
    ELSE 'deployed market value exceeds this strategy booked NAV'
  END AS likely_cause
FROM `stock-trading-498512.analytics.strategy_nav` n
LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f ON f.strategy_code = n.strategy
WHERE ROUND(n.available_funds, 2) < 0
   -- deposits<0 still fires for every non-nomadic strategy, and still fires for a NOMADIC strategy
   -- whose NAV is also negative. It is exempted ONLY when nav >= 0, i.e. when the negative deposits is
   -- exactly the retained-own-P&L artefact the nomadic sweep produces by design (FIX 9).
   OR (ROUND(n.deposits, 2) < 0
       AND NOT (COALESCE(f.is_low_frequency_by_design, FALSE) AND ROUND(n.nav, 2) >= 0));

-- ===== FIX 5b. Register the alert category the blocked-sweep row is reported through.
-- The D2a NOMADIC SWEEP substep raises `nomadic_sweep_blocked` when state.nomadic_capital_sync_pending
-- emits a blocked_no_recipient row. Every sibling capital category (capital_stranded,
-- strategy_funds_deficit, regime_restore_shortfall, cash_flow_source_unknown) is registered in
-- ops.alert_policy; this one was referenced in routine prose without a registration, which would leave
-- it with no documented resolve rule for whoever reads the alert. Guarded INSERT, same idempotent shape
-- bigquery/163 and bigquery/164 use.
--
-- WARNING, never critical, and deliberately so: bigquery/107's halt_reason CASE counts
-- severity='critical' rows into blocking_criticals, which freezes ALL order staging system-wide. A
-- capital-ROUTING condition must never be able to halt trading -- the capital is not lost, not
-- mis-booked, and not at risk; it simply has nowhere to move to this session and stays where it is.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'nomadic_sweep_blocked' AS category,
    FALSE AS latching,
    'Auto-resolves when state.nomadic_capital_sync_pending stops emitting a blocked_no_recipient row - i.e. when at least one capital-ENABLED, NON-NOMADIC active strategy exists again to receive the sweep (a router re-enable, or a roster change), or when the nomadic strategy no longer has a sweepable balance at or above the 25-dollar floor. No manual action moves the capital; it simply stays with the nomadic strategy until a legal destination exists.' AS resolve_rule,
    'A NOMADIC strategy holds sweepable idle capital but EVERY capital-enabled strategy is itself nomadic, so the daily sweep has no eligible recipient and moved nothing. Registered by bigquery/168 alongside the blocked_no_recipient row it reports, which exists so this state is distinguishable from the healthy empty-view steady state (before that row, a blocked sweep and a no-op sweep both returned zero rows). WARNING by design, never critical: the capital is neither lost nor mis-booked - it stays put - and a critical would enter bigquery/107 blocking_criticals and halt all order staging over a pure capital-routing condition.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Nomadic status now covers the FULL active roster, including capital-disabled D (FIX 1), and nets
--    reserved cash (FIX 2). Expect 5 rows (A-E), C and D both is_nomadic=TRUE, only C sweep_now=TRUE
--    (D is capital-disabled), and reserved_cash_total 0.00 everywhere today (no pending orders):
--    SELECT strategy_code, capital_enabled, is_nomadic, open_positions, reserved_cash_total,
--           idle_capital, sweepable_amount, sweep_now
--    FROM `stock-trading-498512.state.strategy_nomadic_status` ORDER BY strategy_code;
--
-- 2. Sweep plan is EXACTLY $0-sum and NUMERIC (FIX 3/4), with a blocked flag available (FIX 5):
--    SELECT strategy, SUM(counterparty_amount) AS recipients_sum, ANY_VALUE(amount) AS swept_amount,
--           LOGICAL_OR(blocked_no_recipient) AS any_blocked
--    FROM `stock-trading-498512.state.nomadic_capital_sync_pending` GROUP BY strategy;
--    -> recipients_sum must equal swept_amount to the cent, not approximately.
--    SELECT column_name, data_type FROM `stock-trading-498512.state.INFORMATION_SCHEMA.COLUMNS`
--    WHERE table_name='nomadic_capital_sync_pending' AND column_name='counterparty_amount';
--    -> expect NUMERIC, not FLOAT64.
--
-- 3. Borrow plan reports partial funding honestly (FIX 6). Ask for more than the pool holds:
--    SELECT * FROM `stock-trading-498512.analytics.fn_nomadic_capital_restore_plan`('C', 999999.00);
--    -> plan_total must equal total donor capacity (NOT 999999), requested_amount=999999,
--       is_fully_funded=FALSE, and SUM(pull_amount) must equal plan_total exactly.
--
-- 4. D's regime debt is restorable again (FIX 7). D is capital-disabled today so no RESTORE row is due
--    yet, but confirm D is no longer structurally excluded from the debtor set:
--    SELECT * FROM `stock-trading-498512.state.regime_capital_sync_pending`;
--    SELECT strategy, outstanding_debt FROM `stock-trading-498512.state.regime_capital_debt`
--    WHERE outstanding_debt > 0 ORDER BY strategy;
--
-- 5. Shortfall-risk donor capacity now excludes nomadic strategies (FIX 8) -- expect donor_capacity to
--    drop by C's balance versus the pre-apply reading:
--    SELECT strategy, outstanding_debt, donor_capacity, aggregate_headroom
--    FROM `stock-trading-498512.state.regime_restore_shortfall_risk` ORDER BY strategy;
--
-- 6. Funds-deficit view is clean today and carries the new column (FIX 9):
--    SELECT * FROM `stock-trading-498512.state.strategy_funds_deficit`;
--    -> expect zero rows today.

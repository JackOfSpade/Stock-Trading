-- ===== 215: the REGIME sweep gets the blocked-no-recipient signal the NOMADIC sweep already has =====
-- (2026-09-03/04, interactive triage of ops.alerts WARNING `capital_enablement_single_strategy` raised by
-- AR_orc on 2026-09-03 after divergence review div-E-202608-1.)
--
-- WHAT TRIGGERED THIS. AR_orc converted Strategy E from ACTIVATE to DO-NOT-ACTIVATE
-- (events.regime_events 0e7609e5, key='E', divergence_id='div-E-202608-1', as_of_date 2026-09-03) and
-- disclosed the downstream consequence at the time of the write rather than leaving it to be found:
-- E was the only unqualified ACTIVATE on the roster, so from 2026-09-04 -- when the 2026-09-03 rows
-- satisfy state.strategy_capital_enablement's strictly-before-today cutoff -- the capital_enabled set
-- becomes {C} ALONE. AR_orc explicitly did NOT compute the dollar magnitude ("NOT MEASURED and NOT
-- asserted"). This file computes it and fixes the rail.
--
-- MEASURED, by simulating the view against tomorrow's enablement values (2026-09-03):
--   enabled_recipients      -> 0 rows.  C is the sole capital_enabled strategy and C IS NOMADIC
--                              (state.strategy_declared_frequency.is_low_frequency_by_design; HYBRID-FOMC
--                              routing, 0-8 trades/year), and bigquery/168 FIX 7 excludes a nomadic
--                              strategy from the recipient set -- correctly, since a nomadic strategy
--                              holds no exclusive standing capital ever.
--   sweep_candidates        -> E = 15368.39.  A sweep IS owed under Operating_Protocols.md 16.
--   SWEEP rows emitted      -> ZERO.
--   capital actually swept  -> 0.00.
-- So 15368.39 -- 96.7% of the 15886 book NAV -- is owed a sweep that the view silently declines to
-- emit, because `sweep_rows` is `sweep_candidates CROSS JOIN n_enabled CROSS JOIN enabled_recipients`
-- and a CROSS JOIN against an empty relation yields zero rows. Nothing moves (which is the SAFE
-- outcome -- routing the book to a nomadic strategy would be worse, and is exactly what
-- `sweep_recipient_view_drift` caught on 2026-08-27), but NOTHING ALERTS either: D2a reads the empty
-- view and takes the documented "Empty (the steady state) -> no-op, nothing to log" branch. A
-- whole-roster deactivation is therefore indistinguishable from a healthy quiet day.
--
-- THE FIX IS NOT A NEW MECHANISM -- it is the branch the SIBLING view already has. bigquery/167's
-- state.nomadic_capital_sync_pending carries a `blocked` CTE and a `blocked_no_recipient` column for
-- precisely this configuration, and task_plan/D2a.md already has the handler that raises
-- `nomadic_sweep_blocked` off it, with the rationale stated inline: "This row exists specifically so a
-- blocked sweep is distinguishable from the healthy empty-view steady state; do NOT treat it as a
-- no-op." The REGIME view was written first (bigquery/98, 2026-07-19) and never gained the equivalent.
-- This file closes that asymmetry, in the same shape, so there is one pattern rather than two.
--
-- BOTH DIRECTIONS ARE BLOCKED, not just the sweep. The RESTORE branch fails silently the same way and
-- for the same reason: with no eligible donors, `restore_payable.payable` computes 0 and the
-- `payable >= LEAST(25, outstanding_debt)` guard drops the row. That path is not live today (C is the
-- only capital_enabled strategy and carries zero outstanding_regime_debt; the outstanding debts are
-- A 3888.45, B 4973.25 and D 4430.02, all capital-DISABLED and so not restore candidates), but it
-- becomes live the moment any of those three is re-enabled while every recipient is still nomadic.
-- Adding one branch and leaving its mirror image silent is how the original asymmetry happened.
--
-- DELIBERATELY UNCHANGED: the recipient-eligibility predicate (`capital_enabled AND NOT nomadic` --
-- bigquery/168 FIX 7, load-bearing and re-endorsed here, NOT relaxed to "unblock" the sweep), the $25
-- de-minimis floor, the equal-share baseline, the debt accounting, and the ops.capital_control
-- kill-switch. This file adds a SIGNAL; it moves no money and changes no eligibility. The right
-- response to "the whole book sits behind one narrowly-scoped strategy" is an owner decision about the
-- roster, not a capital rail quietly widening its own recipient set -- and, as AR_orc correctly
-- insisted, a downstream capital rail must never feed back into the regime call.
--
-- SCHEMA NOTE: adds one column, `blocked_no_recipient`, matching the nomadic view's column exactly.
-- Verified live before writing: NO view anywhere queries state.regime_capital_sync_pending (the single
-- INFORMATION_SCHEMA hit, state.sweep_recipient_weights, only mentions it in a COMMENT), so nothing
-- can break on the added column. Regenerate dbt/models/state/regime_capital_sync_pending.sql.
--
-- CARRIED FORWARD, because regenerating the dbt mirror dropped it. The `enabled_debtors` CTE below
-- keeps bigquery/98's ORIGINAL, nomadic-INCLUSIVE semantics and deliberately does NOT reuse the
-- `enabled_recipients` predicate: being nomadic must never make an EXISTING debt unrestorable -- that
-- was the bigquery/167 defect that bigquery/168 fixed. A nomadic strategy holds no STANDING capital,
-- which is a statement about new allocation, not about money already owed back to it. That rationale
-- survived only as a comment in dbt/models/state/regime_capital_sync_pending.sql, which is
-- MECHANICALLY regenerated from this file's canonical body by scripts/gen_dbt_port.py and therefore
-- silently discards any annotation that is not in the body. Recording it here instead of in the body
-- keeps it durable without changing the live view_definition.
--
-- APPLY: live via the BigQuery MCP, together with the dbt mirror and the D2a handler bullet.

-- ===== state.regime_capital_sync_pending =====
-- SUPERSEDES the definition in bigquery/168_nomadic_capital_fixes.sql (chain: 98 -> 167 -> 168 -> 215).
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_capital_sync_pending` AS
WITH ctrl AS (
  SELECT enabled AS control_enabled FROM `stock-trading-498512.state.capital_control_latest`
),
enablement AS (
  SELECT * FROM `stock-trading-498512.state.strategy_capital_enablement`
),
nomadic AS (
  SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
  WHERE is_low_frequency_by_design
),
enabled_recipients AS (
  SELECT strategy_code FROM enablement e
  WHERE e.capital_enabled
    AND e.strategy_code NOT IN (SELECT strategy_code FROM nomadic)
),
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
    ROUND(sc.amount / n.n, 2)   AS counterparty_baseline_amount,
    FALSE                       AS blocked_no_recipient
  FROM sweep_candidates sc
  CROSS JOIN n_enabled n
  CROSS JOIN enabled_recipients es
),
-- bigquery/215: capital to sweep, but every capital-enabled strategy is itself nomadic, so there is
-- nowhere legal to put it. Without this branch the CROSS JOIN above yields zero rows and a
-- whole-roster deactivation is indistinguishable from the healthy empty-view steady state.
sweep_blocked AS (
  SELECT
    'SWEEP'                     AS action,
    sc.strategy,
    sc.amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_baseline_amount,
    TRUE                        AS blocked_no_recipient
  FROM sweep_candidates sc
  WHERE NOT EXISTS (SELECT 1 FROM enabled_recipients)
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
    ROUND(rp.payable * dn.donor_capacity / dt.total_donor_capacity, 2) AS counterparty_baseline_amount,
    FALSE                                                              AS blocked_no_recipient
  FROM restore_payable rp
  JOIN donor_totals dt ON dt.debtor = rp.strategy
  JOIN donors dn ON dn.debtor = rp.strategy
  WHERE rp.payable >= LEAST(25, rp.outstanding_debt)
),
-- bigquery/215: the mirror image of sweep_blocked. With no eligible donors, restore_payable.payable
-- computes 0 and the payable >= LEAST(25, outstanding_debt) guard drops the row -- silently, exactly
-- like the sweep did. Not live today (C is the only capital_enabled strategy and carries zero
-- outstanding_regime_debt) but live the moment a debt-carrying strategy is re-enabled while every
-- recipient is still nomadic.
restore_blocked AS (
  SELECT
    'RESTORE'                   AS action,
    rc.strategy,
    rc.outstanding_debt         AS amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_baseline_amount,
    TRUE                        AS blocked_no_recipient
  FROM restore_candidates rc
  WHERE NOT EXISTS (SELECT 1 FROM enabled_recipients)
)
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, ctrl.control_enabled
FROM sweep_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, ctrl.control_enabled
FROM sweep_blocked CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, ctrl.control_enabled
FROM restore_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, ctrl.control_enabled
FROM restore_blocked CROSS JOIN ctrl
ORDER BY action, strategy, counterparty_strategy;

-- ===== Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'regime_sweep_blocked' AS category,
    FALSE AS latching,
    'Auto-resolves when state.regime_capital_sync_pending stops returning a blocked_no_recipient row -- i.e. when at least one capital-ENABLED, NON-NOMADIC strategy exists again to receive the sweep (a router re-enable, or a roster change), or when the capital-disabled strategy holding the cash drops below the $25 de-minimis floor. NOT covered by any ops.sp_auto_resolve_alerts rule (those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/staleness), so latching=FALSE only SANCTIONS the resolve; D2a re-evaluates the condition each run. Do NOT resolve it by widening the recipient predicate -- capital_enabled AND NOT nomadic is load-bearing (bigquery/168 FIX 7).' AS resolve_rule,
    'CAPITAL-ROUTING CLASS, registered 2026-09-03/04 by bigquery/215 alongside the blocked branch it reports. The exact sibling of nomadic_sweep_blocked (bigquery/168), which the NOMADIC sweep has had since 2026-08-11 while the REGIME sweep -- written first, bigquery/98 -- never gained it. Raised by D2a when a capital-DISABLED strategy holds >= $25 of idle cash that Operating_Protocols.md 16 says must redistribute, but EVERY capital-enabled strategy is nomadic so there is no eligible recipient. Founding case: AR_orc div-E-202608-1 moved Strategy E to DO-NOT-ACTIVATE on 2026-09-03, leaving nomadic C as the sole capital-enabled strategy and 15368.39 (96.7 percent of book NAV) owed a sweep with nowhere legal to go. WARNING, not critical: nothing moves and nothing is at risk -- the defect being fixed is that nothing SAID so.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- SELECT * FROM `stock-trading-498512.state.regime_capital_sync_pending`;
--   -- TODAY (2026-09-03 Denver): still ZERO rows -- E is capital_enabled until the strictly-before-today
--   -- cutoff admits the 2026-09-03 activation rows. This is the correct no-change-on-apply result.
--   -- FROM 2026-09-04 Denver: exactly one row, action='SWEEP', strategy='E', amount=15368.39,
--   -- counterparty_strategy NULL, blocked_no_recipient TRUE.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

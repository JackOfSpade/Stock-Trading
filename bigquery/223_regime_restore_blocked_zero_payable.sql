-- ===== 223: the REGIME restore's blocked branch fires on the condition that actually silences it =====
-- (2026-09-05, owner-directed shock-override package, item R4. Found while mapping every consumer of
-- state.regime_capital_sync_pending for the re-risking-limb work, not by an alert -- the path this
-- fixes has never fired.)
--
-- WHAT bigquery/215 GOT RIGHT AND WHERE IT STOPPED. 215 added the blocked_no_recipient signal to both
-- directions of this view, so a movement that is owed but cannot be made stops reading as the healthy
-- empty-view steady state. Its SWEEP branch is exact: `sweep_rows` is `sweep_candidates CROSS JOIN
-- n_enabled CROSS JOIN enabled_recipients`, so an EMPTY enabled_recipients is precisely and only what
-- silences it, and `WHERE NOT EXISTS (SELECT 1 FROM enabled_recipients)` is its exact complement.
--
-- The RESTORE branch reused that same predicate, and for the restore it is strictly NARROWER than the
-- condition that silences the branch. A restore is dropped by `restore_rows`' guard
-- `payable >= LEAST(25, outstanding_debt)`, and `payable` is
-- `LEAST(outstanding_debt, COALESCE(total_donor_capacity, 0))` -- so what silences a restore is ZERO
-- DONOR CAPACITY, which is not the same proposition as an empty recipient set. `donors` joins
-- `enabled_recipients es ON es.strategy_code != rc.strategy` and filters `nv.available_funds > 0`, so
-- donor capacity is zero in at least two configurations where enabled_recipients is NON-empty:
--   (1) THE ONLY ELIGIBLE RECIPIENT IS THE DEBTOR ITSELF. The `!=` join self-excludes it, `donors`
--       is empty, payable = LEAST(debt, 0) = 0, `restore_rows` drops the row -- and `restore_blocked`
--       does NOT fire, because enabled_recipients = {the debtor} is not empty.
--   (2) Recipients exist but every one of them has available_funds <= 0, so `donors`' own
--       `WHERE nv.available_funds > 0` yields nothing.
-- Both are silent in exactly the way 215 was written to end, one branch over.
--
-- MEASURED, live, 2026-09-05 (America/Denver) -- configuration (1) is ONE ROUTER RE-ENABLE AWAY, not
-- hypothetical:
--   outstanding_regime_debt   A 3888.45, B 4973.25, D 4430.02; C and E zero.
--   capital_enabled           {C} alone (the post-div-E-202608-1 state bigquery/215 predicted).
--   nomadic                   C and D TRUE; A, B, E FALSE.
--   available_funds           A 0.00, B 0.00, C 23.64, D 0.00, E 15368.39.
-- Re-enable B (capital_enabled, non-nomadic) while the rest of the roster stays where it is and
-- enabled_recipients = {B}, restore_candidates = {B}, donors = {} -- B's own 4973.25 of regime debt is
-- owed back, nothing can move it, and under 215 nothing would say so. The three debtors are all
-- capital-DISABLED today, which is the only reason this has never fired. SIMULATED read-only against
-- those live values with enabled_recipients forced to {B}: payable = 0, `restore_rows`' guard
-- (0 >= LEAST(25, 4973.25)) FAILS, and 215's `restore_blocked` does NOT fire because
-- enabled_recipients is non-empty -- ZERO rows emitted for a 4973.25 debt that cannot move. Under the
-- predicate below the row fires, with blocked_reason='no_eligible_recipient'.
--
-- THE FIX IS A PREDICATE REPLACEMENT, NOT A SECOND BRANCH. `payable = 0` SUBSUMES the empty-recipient
-- case (no recipients => no donors => payable 0), so adding it ALONGSIDE the old guard would emit TWO
-- rows for one restore candidate whenever the roster is fully deactivated. The branches must stay
-- mutually exclusive -- one row per candidate, always -- and they are: `restore_rows` requires
-- `payable >= LEAST(25, outstanding_debt)`, `restore_candidates` only admits outstanding_debt > 0, so
-- that floor is strictly positive and no row can satisfy both `payable = 0` and the floor.
--
-- DELIBERATE RESIDUAL, stated rather than left to be re-discovered: a payable that is nonzero but
-- below the floor (0 < payable < LEAST(25, outstanding_debt)) is still dropped silently, and this file
-- does NOT report it. That is a different proposition and the narrower predicate is the honest one: a
-- zero payable means the restore is BLOCKED -- no capacity exists anywhere and nothing the accounting
-- can do will move it -- while a de-minimis payable means the restore is THROTTLED by the $25 floor,
-- capacity does exist, and the condition self-clears as the donor accrues funds. Reporting a throttle
-- as a block would put a permanently-open warning on a healthy, self-resolving state, which is the
-- failure mode this fleet has already paid for elsewhere.
--
-- SCHEMA NOTE: adds one column, `blocked_reason` STRING, NULL on the two movement branches. It exists
-- because `blocked_no_recipient` is now carrying two different facts: for a SWEEP it still means
-- literally "no eligible recipient exists", but for a RESTORE it can also mean "recipients exist, and
-- none of them can fund this". The column NAME is deliberately NOT changed -- bigquery/215 chose it to
-- match state.nomadic_capital_sync_pending's column exactly, and task_plan/D2a.md's handler branches on
-- it -- so the distinction goes in a new column that reads alongside it rather than in a rename that
-- would break the symmetry and the handler at once. Re-verified live before writing, exactly as 215
-- did: across state/analytics/perf/ops/events VIEWS and ROUTINES, the ONLY INFORMATION_SCHEMA hit for
-- this view is state.sweep_recipient_weights, which mentions it in a COMMENT only. Nothing reads it,
-- so nothing can break on the added column. Regenerate dbt/models/state/regime_capital_sync_pending.sql.
--
-- CARRIED FORWARD from bigquery/215's header, because it lives only in a header and the dbt mirror is
-- regenerated mechanically: the `enabled_debtors` CTE below keeps bigquery/98's ORIGINAL,
-- nomadic-INCLUSIVE semantics and deliberately does NOT reuse the `enabled_recipients` predicate --
-- being nomadic must never make an EXISTING debt unrestorable, which was the bigquery/167 defect
-- bigquery/168 fixed. A nomadic strategy holds no STANDING capital, a statement about new allocation,
-- not about money already owed back to it.
--
-- DELIBERATELY UNCHANGED, restating 215 because this file is one branch away from all of it: the
-- recipient-eligibility predicate (`capital_enabled AND NOT nomadic`, bigquery/168 FIX 7), the $25
-- de-minimis floor, the equal-share and pro-rata baselines, the debt accounting, and the
-- ops.capital_control kill-switch. This file adds a SIGNAL; it moves no money and changes no
-- eligibility. Widening the donor set to "unblock" a restore is the wrong repair for the same reason
-- it was wrong for the sweep -- the answer to "the whole book sits behind one strategy" is an owner
-- decision about the roster, not a capital rail quietly enlarging itself.
--
-- ALERTING: the restore-blocked row gets its OWN category, `regime_restore_blocked`, registered below
-- beside the branch that makes it reachable (bigquery/215's pattern). It must NOT reuse
-- `regime_sweep_blocked`'s message: ops.sp_raise_alert_once dedups on (category, message) over
-- UNRESOLVED rows by EXACT STRING EQUALITY, so raising a restore under the sweep's already-open row
-- would silently swallow the restore signal entirely -- and the sweep's pinned message ("a
-- capital-disabled strategy holds sweepable idle cash") is factually wrong about a restore anyway.
--
-- NO-LIVE-CHANGE APPLY, verified read-only against the live view before writing this file: the view
-- returns exactly ONE row today -- action='SWEEP', strategy='E', amount=15368.39, counterparty_strategy
-- NULL, counterparty_baseline_amount NULL, blocked_no_recipient TRUE, control_enabled TRUE -- and the
-- body below returns that same row, byte-identical in every pre-existing column, plus
-- blocked_reason='no_eligible_recipient'. Re-run the check immediately before and after the live
-- replace: a blocked sweep is OUTSTANDING right now (D2a last ran 2026-09-03; 2026-09-04/05 are the
-- Fri/Sat skip), so this replace happens over a live signal, not a quiet view.
--
-- APPLY: live via the BigQuery MCP, together with the dbt mirror and the D2a restore-blocked handler
-- bullet. Apply after 222.

-- ===== state.regime_capital_sync_pending =====
-- SUPERSEDES the definition in bigquery/215_regime_sweep_blocked_no_recipient.sql
-- (chain: 98 -> 167 -> 168 -> 215 -> 223).
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
    FALSE                       AS blocked_no_recipient,
    CAST(NULL AS STRING)        AS blocked_reason
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
    TRUE                        AS blocked_no_recipient,
    'no_eligible_recipient'     AS blocked_reason
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
-- bigquery/223: how many ELIGIBLE recipients OTHER THAN the debtor itself exist, per restore
-- candidate. This is the only thing that separates the two ways a restore can reach payable = 0, and
-- they call for different operator responses: zero others means the roster has collapsed to the
-- debtor (a router/roster question), while others exist but hold no funds means the book is fully
-- deployed (a capital question that clears itself as positions close). LEFT JOIN + COUNTIF rather
-- than a correlated EXISTS: BigQuery rejects a correlated subquery over another relation unless it
-- can de-correlate it.
restore_recipient_reach AS (
  SELECT rc.strategy, COUNTIF(es.strategy_code IS NOT NULL) AS other_recipients
  FROM restore_candidates rc
  LEFT JOIN enabled_recipients es ON es.strategy_code != rc.strategy
  GROUP BY rc.strategy
),
restore_rows AS (
  SELECT
    'RESTORE'                                                          AS action,
    rp.strategy,
    ROUND(rp.payable, 2)                                               AS amount,
    dn.donor_strategy                                                  AS counterparty_strategy,
    ROUND(rp.payable * dn.donor_capacity / dt.total_donor_capacity, 2) AS counterparty_baseline_amount,
    FALSE                                                              AS blocked_no_recipient,
    CAST(NULL AS STRING)                                               AS blocked_reason
  FROM restore_payable rp
  JOIN donor_totals dt ON dt.debtor = rp.strategy
  JOIN donors dn ON dn.debtor = rp.strategy
  WHERE rp.payable >= LEAST(25, rp.outstanding_debt)
),
-- bigquery/223: the mirror image of sweep_blocked, keyed on the condition that actually silences a
-- restore. bigquery/215 keyed this on an empty enabled_recipients -- the SWEEP's exact complement,
-- but strictly narrower than the restore's: `donors` self-excludes the debtor and requires positive
-- available_funds, so payable reaches 0 with a NON-empty recipient set whenever the only eligible
-- recipient IS the debtor, or every recipient is fully deployed. payable = 0 subsumes the empty
-- set (no recipients -> no donors -> payable 0), so this REPLACES that guard rather than joining it:
-- two branches would emit two rows for one candidate. Mutually exclusive with restore_rows by
-- construction -- restore_candidates admits only outstanding_debt > 0, so LEAST(25, outstanding_debt)
-- is strictly positive and payable = 0 can never clear it. A nonzero payable below that floor is a
-- THROTTLE, not a block, and is deliberately not reported here (see this file's header).
restore_blocked AS (
  SELECT
    'RESTORE'                   AS action,
    rp.strategy,
    rp.outstanding_debt         AS amount,
    CAST(NULL AS STRING)        AS counterparty_strategy,
    CAST(NULL AS NUMERIC)       AS counterparty_baseline_amount,
    TRUE                        AS blocked_no_recipient,
    CASE WHEN rr.other_recipients = 0 THEN 'no_eligible_recipient'
         ELSE 'no_donor_capacity' END AS blocked_reason
  FROM restore_payable rp
  JOIN restore_recipient_reach rr ON rr.strategy = rp.strategy
  WHERE rp.payable = 0
)
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM sweep_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM sweep_blocked CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM restore_rows CROSS JOIN ctrl
UNION ALL
SELECT action, strategy, amount, counterparty_strategy, counterparty_baseline_amount, blocked_no_recipient, blocked_reason, ctrl.control_enabled
FROM restore_blocked CROSS JOIN ctrl
ORDER BY action, strategy, counterparty_strategy;

-- ===== Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'regime_restore_blocked' AS category,
    FALSE AS latching,
    'Auto-resolves when state.regime_capital_sync_pending stops returning a RESTORE row with blocked_no_recipient TRUE -- i.e. when at least one capital-ENABLED, NON-NOMADIC strategy OTHER THAN the debtor holds positive available_funds again (a router re-enable, a roster change, or a position closing), or when the debt is repaid by any other path. NOT covered by any ops.sp_auto_resolve_alerts rule (those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/staleness), so latching=FALSE only SANCTIONS the resolve; D2a re-evaluates the condition each run. Do NOT resolve it by relaxing the donor predicate -- capital_enabled AND NOT nomadic is load-bearing (bigquery/168 FIX 7), and the debtor is self-excluded from its own donor set on purpose.' AS resolve_rule,
    'CAPITAL-ROUTING CLASS, registered 2026-09-05 by bigquery/223 alongside the branch it reports, exactly as bigquery/215 registered regime_sweep_blocked. SEPARATE FROM regime_sweep_blocked ON PURPOSE: ops.sp_raise_alert_once dedups on (category, message) by exact string equality over unresolved rows, so a restore raised under the sweep category with the sweep message would be silently swallowed by an already-open sweep row -- and the sweep message ("a capital-disabled strategy holds sweepable idle cash") describes the wrong event. Raised by D2a when a capital-ENABLED strategy carries outstanding regime debt that cannot be repaid at all: payable computes 0 because either the only eligible recipient IS the debtor (the donor join self-excludes it) or every eligible recipient holds zero available funds. blocked_reason on the row says which. WARNING, not critical: nothing moves and nothing is at risk -- the defect being fixed is that nothing SAID so.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- SELECT * FROM `stock-trading-498512.state.regime_capital_sync_pending`;
--   -- TODAY (2026-09-05 Denver): exactly one row, unchanged from the pre-apply read in every
--   -- pre-existing column -- action='SWEEP', strategy='E', amount=15368.39, counterparty_strategy
--   -- NULL, counterparty_baseline_amount NULL, blocked_no_recipient TRUE, control_enabled TRUE --
--   -- plus blocked_reason='no_eligible_recipient'. Any other difference means the replace changed
--   -- behaviour and must be investigated before D2a next runs.
-- SELECT category, latching FROM `stock-trading-498512.ops.alert_policy`
-- WHERE category IN ('regime_sweep_blocked','regime_restore_blocked');
--   -- Two rows. The INSERT above is WHERE-NOT-EXISTS guarded, so re-applying this file is a no-op.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

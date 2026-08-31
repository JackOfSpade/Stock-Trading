-- bigquery/164_capital_utilisation_and_restore_integrity.sql (2026-08-11)
-- Project: stock-trading-498512. Apply after bigquery/98_regime_capital_enablement.sql,
-- bigquery/127_strategy_nav_dust_exclusion.sql, bigquery/125_dust_excluded_from_twr.sql, and
-- bigquery/161_withdrawal_after_the_fact.sql (state.withdrawal_capacity).
--
-- NET-NEW OBJECTS ONLY. Three views and three alert categories. Redefines nothing, changes no
-- behaviour, moves no capital. Every object here is OBSERVABILITY plus one mechanical weight table
-- that a routine may consult; none of them writes a cash flow.
--
-- ============================ WHY ================================================================
-- Operating_Protocols.md §16 states the capital model's objective verbatim: "The system is a live
-- capital-growth engine, not a frozen forward-test... reward winners PASSIVELY via survivorship, not
-- by merit-weighting a short, noisy sample." The intended mechanism is therefore: losers terminate,
-- their capital redistributes to survivors, and survivors compound their own P&L. Nothing is supposed
-- to hand capital to a strategy for being clever, and nothing is supposed to take capital away from a
-- survivor for being unlucky.
--
-- Measured against live data on 2026-08-11, that mechanism is not currently what determines budgets:
--   * Total own-P&L compounding across ALL FIVE strategies, lifetime: $55.46.
--   * Total capital moved by the regime-capital sweep: $13,135.49 -- roughly 237x larger.
--   * Strategy B, the only strategy with realized profit, earned +$18.35 through its own trading and
--     then had $4,870.19 swept away: reallocation beat performance about 265:1 against it.
--   * 96% of the book now sits with C and E, neither of which has ever opened a position.
-- Survivorship is not the dominant term. Reallocation is.
--
-- The sweep itself is not wrong -- capital genuinely should not sit with a strategy the regime router
-- has switched off. Three specific gaps make it overwhelm the survivorship signal, and this file
-- closes the observability half of all three. NONE of them is fixed by merit-weighting, which §16
-- explicitly rejects; each is fixed by measuring something the system currently cannot see.
--
-- GAP 1 -- NOBODY WATCHES WHETHER SWEPT CAPITAL CAN ACTUALLY BE USED. The sweep routes on the binary
-- capital_enabled flag and never asks whether the recipient can deploy. Today it routed 96% of the
-- book to a strategy restricted to ~8 FOMC windows a year and one that keeps failing a hard 0.50
-- correlation gate. §16 anticipates the healthy version of this ("an active strategy that is merely
-- idle... keeps its capital") but there is no detector distinguishing merely-idle from stranded.
--   -> state.capital_utilisation_watch
--
-- GAP 2 -- THE AUTONOMOUS SWEEP IS SKILL-BLIND AND CAPACITY-BLIND IN PRACTICE. §16 already permits a
-- [0.5x, 2x]-of-equal-share tilt, and the 2026-07-19 sweep used it (B and D at 1.2x, C 0.9x, E 0.7x).
-- But that sweep was executed in an interactive session on owner instruction. D2a "carries NO analysis
-- by design", so both autonomous sweeps since (2026-08-05, 2026-08-06) fell back to DEFAULT-EQUAL. In
-- unattended operation every future sweep is therefore an equal split, permanently. A tilt is only
-- reachable unattended if it needs no judgment -- so this file precomputes a MECHANICAL one.
--   -> state.sweep_recipient_weights
--
-- GAP 3 -- A RE-ENABLED STRATEGY CAN COME BACK UNDER-CAPITALISED, AND NOTHING MEASURED IT.
-- The sweep is debt-tracked and reversible, which is what makes it acceptable: a disabled strategy is
-- lending, not losing. bigquery/98's RESTORE pays LEAST(outstanding_debt, donor_capacity), where
-- donor_capacity is the other enabled strategies' UNDEPLOYED cash -- so if the donors have deployed by
-- the time the debtor re-enables, that session's restore is PARTIAL.
--
-- CORRECTION, 2026-08-11 (this file's first draft got this wrong and the error is recorded here on
-- purpose): a partial restore is a DELAY, NOT A PERMANENT LOSS. `restore_candidates` in bigquery/98 is
-- a STANDING CONDITION -- `enabled_set JOIN debt WHERE outstanding_debt > 0` -- with no
-- state-transition trigger, no cooldown, no once-per-strategy flag and no "already attempted" marker
-- anywhere in the CTE chain. `outstanding_debt` is a live view over append-only events.cash_flows
-- (swept_out_total - restored_total), so a partial payment lowers it without zeroing it, and the very
-- next read re-proposes the residual against whatever donor capacity exists then. The only guard, the
-- >=$25-or-full-debt floor, defers a sub-$25 tail until capacity covers it in full; it cannot strand
-- it. So the correct claim is NOT "a profitable strategy can be permanently shrunk" -- it is "a
-- re-enabled strategy may operate under-capitalised for a stretch, recovering automatically and
-- mechanically as donor capacity returns, with no human step."
--
-- That is a materially smaller problem, and this view is scoped to it accordingly: it measures how
-- much of a debtor's claim could be honoured RIGHT NOW, so the drag is visible while it lasts rather
-- than being discovered only when someone asks why a re-enabled strategy is trading small. Today the
-- headroom is positive ($18,779.23 donor capacity vs $13,135.49 debt = $5,643.74 spare) ONLY because
-- C and E have not deployed; the moment they do, a re-enabling debtor would be restored in
-- instalments rather than at once.
--   -> state.regime_restore_shortfall_risk
--
-- WHY NO P&L TERM ANYWHERE IN THIS FILE. Merit-weighting is rejected by §16 for a good reason: at
-- n=11 closed trades and $13.47 realized, B's 90% win rate is a directional read, not an established
-- edge, and weighting capital on it would be exactly the "short, noisy sample" the doc warns about.
-- The weight below keys on DEPLOYMENT CAPACITY -- can this strategy put capital to work at all --
-- which is a structural fact about the strategy's mechanism, not a judgement about its skill. Note
-- separately, for the record, that the parameter-fishing prohibition ("if the justification references
-- the strategy's own realized P&L, hit rate, or drawdown in any way, it is parameter fishing and is
-- forbidden") does NOT scope here: all ten of its repo occurrences sit inside
-- AI_Trading_Foundation.md §5.6a, governing in-life edits to a strategy's OWN machinery, never
-- capital allocation between strategies. So a P&L term would be permitted; it is omitted on §16's
-- noisy-sample grounds, deliberately, not because a rail forbids it.

-- ===== 1. state.capital_utilisation_watch =====
-- Per capital-ENABLED strategy: how much idle capital it holds, how long since it last deployed, and
-- -- critically -- whether it is still being ACTIVELY EVALUATED. That last column is what stops this
-- from crying wolf. A strategy that is adjudicated regularly and honestly declines every thesis is
-- healthy and §16 says it keeps its capital; a strategy sitting on idle capital that nothing has even
-- looked at is a different animal. Live proof the distinction is real and necessary: as of 2026-08-11
-- BOTH capital-enabled strategies are 100% idle and have never deployed, yet E logged four
-- thesis-construction NO-GOs in the trailing 45 days (latest 2026-08-10, declining on a measured
-- correlation of 0.048 against its 0.50 pair-validity floor) and C logged two plus a router-review
-- fresh trigger for the 2026-09-16 FOMC. Both are working correctly. A naive
-- idle-capital-and-days-since-deployment detector would fire on both on day one and be muted within a
-- week, which is worse than having no detector.
CREATE OR REPLACE VIEW `stock-trading-498512.state.capital_utilisation_watch` AS
WITH enabled AS (
  SELECT e.strategy_code
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
),
-- Last real deployment. Dust lots are excluded (bigquery/125's audited is_dust), NULL failing open as
-- non-dust so a real lot can never be silently dropped -- the same predicate every other
-- position_lifecycle reader uses.
deploy AS (
  SELECT strategy AS strategy_code,
    MAX(entry_date) AS last_entry_date,
    COUNTIF(exit_date IS NULL) AS open_positions
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy
),
-- Evaluation liveness. entry_type='thesis-construction' is the canonical "this strategy was assessed
-- for a trade" record, GO or NO-GO alike -- a NO-GO is a successful evaluation, not a missing one.
-- Reads state.decision_log_current (bigquery/144), NOT events.decision_log raw: a corrected decision
-- is recorded append-only as a NEW row whose superseded_by names the obsolete one, so a raw read would
-- count both the superseded row and its replacement and overstate evaluation liveness -- which, in
-- this view, would wrongly clear a genuinely stranded strategy. Enforced by
-- scripts/check_superseded_by_discipline.py, which failed this file on the first attempt.
evals AS (
  SELECT strategy AS strategy_code,
    COUNTIF(entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 60 DAY)) AS evaluations_60d,
    MAX(entry_date) AS last_evaluation_date
  FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'thesis-construction' AND strategy IS NOT NULL
  GROUP BY strategy
),
base AS (
  SELECT
    en.strategy_code,
    ROUND(COALESCE(n.available_funds, 0), 2) AS idle_capital,
    ROUND(COALESCE(n.nav, 0), 2) AS nav,
    ROUND(COALESCE(n.deployed_mv, 0), 2) AS deployed_mv,
    COALESCE(d.open_positions, 0) AS open_positions,
    d.last_entry_date,
    -- NULL last_entry_date means NEVER deployed; measure from capital-eligibility instead so a
    -- never-deployed strategy still gets a real age rather than a NULL that sorts as "fine".
    COALESCE(
      DATE_DIFF(CURRENT_DATE('America/Denver'), d.last_entry_date, DAY),
      DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(r.immutable_since, 'America/Denver'), DAY)
    ) AS days_since_deployment,
    d.last_entry_date IS NULL AS never_deployed,
    COALESCE(ev.evaluations_60d, 0) AS evaluations_60d,
    ev.last_evaluation_date
  FROM enabled en
  LEFT JOIN `stock-trading-498512.analytics.strategy_nav` n ON n.strategy = en.strategy_code
  LEFT JOIN deploy d ON d.strategy_code = en.strategy_code
  LEFT JOIN evals ev ON ev.strategy_code = en.strategy_code
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = en.strategy_code
)
SELECT *,
  CASE
    WHEN idle_capital < 1000 THEN 'immaterial - under the 1000.00 reporting floor'
    WHEN days_since_deployment < 90 THEN 'deploying - within 90 days of its last entry'
    WHEN evaluations_60d > 0 THEN 'idle but ACTIVELY EVALUATED - healthy per Operating_Protocols section 16 (merely idle keeps its capital)'
    ELSE 'STRANDED - material idle capital, no deployment, and no thesis-construction evaluation in 60 days'
  END AS posture,
  -- The ONLY condition that alerts. Everything else is reported for visibility and stays silent.
  (idle_capital >= 1000 AND days_since_deployment >= 90 AND COALESCE(evaluations_60d, 0) = 0)
    AS is_stranded
FROM base;

-- ===== 2. state.sweep_recipient_weights =====
-- A MECHANICAL, judgment-free recipient weight the D2a regime-capital SWEEP substep can apply within
-- the [0.5x, 2x]-of-equal-share band Operating_Protocols §16 already sanctions. It exists so a tilt is
-- reachable in UNATTENDED operation: §16 permits the tilt but reaches it only through an AI call at
-- MEDIUM+ conviction, and D2a carries no analysis by design, so unattended sweeps default to EQUAL
-- forever. This view needs no analysis -- it is arithmetic over deployment history.
--
-- THE WEIGHT KEYS ON CAPACITY TO DEPLOY, NOT ON SKILL. capacity_ratio is the share of the trailing 180
-- days on which the strategy actually held an open position. A strategy that never holds anything
-- cannot put swept capital to work, whatever the reason; a strategy that is continuously deployed
-- demonstrably can. This is a structural property of the mechanism, not a read on its P&L, and it
-- carries none of the small-sample fragility §16 rejects.
--
-- IT DEGENERATES TO EQUAL WHEN RECIPIENTS ARE INDISTINGUISHABLE, WHICH IS CORRECT. If every eligible
-- recipient has the same capacity_ratio -- including the current live case, where C and E are both at
-- 0.0 -- every weight is identical and the split is exactly the equal split it is today. The weight
-- only bites when recipients genuinely differ. It is therefore a strict improvement over DEFAULT-EQUAL
-- and can never be worse.
--
-- ADVISORY UNTIL A ROUTINE READS IT. Nothing consumes this view on apply. Wiring it into D2a's SWEEP
-- substep is a separate, deliberate step; until then it is a measurement.
--
-- SUPERSEDED LIVE by bigquery/202_sweep_recipient_weights_nomadic_exclusion.sql — current single
-- source of truth for this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation. 202 adds the NOMADIC exclusion this
-- definition lacks: bigquery/164 was authored before bigquery/167/168 introduced the nomadic concept
-- later the same day, so this `enabled` CTE (capital_enabled AND is_active, no nomadic term) returned
-- nomadic C alongside E at sweep_share 0.5 each, while state.regime_capital_sync_pending's own
-- recipient set (bigquery/168 FIX 7) correctly returned E alone. A session taking the recipient SET
-- from this view rather than from the pending view credited nomadic C twice — 27.86 on 2026-08-12
-- (swept straight back out the same run) and 23.68 on 2026-08-18 (still held on 2026-08-30, below the
-- $25 nomadic de-minimis floor). Raised by D2a as ops.alerts info `sweep_recipient_view_drift`,
-- 2026-08-27. This view remains a capacity TILT only; ELIGIBILITY is state.regime_capital_sync_pending's.
CREATE OR REPLACE VIEW `stock-trading-498512.state.sweep_recipient_weights` AS
WITH enabled AS (
  SELECT e.strategy_code
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
),
-- Days in the trailing 180 on which each strategy held at least one non-dust open position.
-- Written as an explicit JOIN, not a correlated subquery: BigQuery rejects a subquery that references
-- another table from the outer query ("Correlated subqueries that reference other tables are not
-- supported unless they can be de-correlated"), which the obvious EXISTS formulation of this trips.
cal AS (
  SELECT dt FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 179 DAY),
    CURRENT_DATE('America/Denver'))) AS dt
),
lots AS (
  SELECT strategy, entry_date,
    -- An open lot is deployed through today, so its effective exit is today, not NULL.
    COALESCE(exit_date, CURRENT_DATE('America/Denver')) AS eff_exit
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE NOT COALESCE(is_dust, FALSE)
),
days AS (
  -- LEFT JOINs throughout so a strategy that has never deployed yields COUNT(DISTINCT NULL) = 0
  -- rather than dropping out of the result entirely.
  SELECT en.strategy_code, COUNT(DISTINCT c.dt) AS deployed_days_180
  FROM enabled en
  LEFT JOIN lots l ON l.strategy = en.strategy_code
  LEFT JOIN cal c ON c.dt >= l.entry_date AND c.dt <= l.eff_exit
  GROUP BY en.strategy_code
),
scored AS (
  SELECT strategy_code,
    deployed_days_180,
    ROUND(deployed_days_180 / 180.0, 4) AS capacity_ratio,
    -- Map [0,1] capacity onto the sanctioned [0.5x, 2x] band. A never-deploying recipient lands on the
    -- FLOOR (0.5x), never zero -- §16's band says "never $0", and a strategy that simply has not found
    -- a qualifying setup yet must not be defunded for it.
    ROUND(0.5 + 1.5 * (deployed_days_180 / 180.0), 4) AS raw_multiplier
  FROM days
)
SELECT
  strategy_code,
  deployed_days_180,
  capacity_ratio,
  LEAST(2.0, GREATEST(0.5, raw_multiplier)) AS band_multiplier,
  COUNT(*) OVER () AS n_recipients,
  -- Normalised share of whatever amount is being swept. Sums to 1.0 across recipients.
  SAFE_DIVIDE(
    LEAST(2.0, GREATEST(0.5, raw_multiplier)),
    SUM(LEAST(2.0, GREATEST(0.5, raw_multiplier))) OVER ()
  ) AS sweep_share,
  -- The equal share, for comparison. When these two agree the weight is doing nothing, which is the
  -- expected and correct state whenever recipients are indistinguishable.
  SAFE_DIVIDE(1.0, COUNT(*) OVER ()) AS equal_share
FROM scored;

-- ===== 3. state.regime_restore_shortfall_risk =====
-- Per debtor strategy: what bigquery/98's RESTORE would pay if that strategy re-enabled TODAY, versus
-- what it is owed. RESTORE pays LEAST(outstanding_debt, donor_capacity), so when the donors are
-- deployed the debtor is restored in instalments rather than at once.
--
-- READ THE COLUMN NAMES CAREFULLY -- "shortfall" here means THIS SESSION'S shortfall, not a loss.
-- `shortfall_if_alone` and the `_at_risk` flags describe how much of the claim cannot be honoured on
-- today's donor capacity. They do NOT mean the money is gone. bigquery/98's restore trigger is a
-- standing condition (any enabled strategy with outstanding_debt > 0, re-evaluated every read, no
-- transition gate and no retry guard), so an unpaid residual is automatically re-proposed on later
-- sessions as donor capacity recovers. The value of watching it is that a debtor operating on a
-- fraction of its owed capital is otherwise invisible -- it just quietly trades smaller than it
-- should, and nobody would connect that to a sweep weeks earlier.
--
-- SUPERSEDED LIVE by bigquery/168_nomadic_capital_fixes.sql — current single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation. 168 excludes nomadic strategies from the donors CTE
-- below (aligned to the same nomadic-exclusive donor set the live restore mechanism now uses) —
-- this definition's donors CTE still sums ALL capital-enabled strategies' available_funds,
-- including nomadic ones, against a donor set the live restore mechanism no longer uses (audit
-- finding 11, HIGH).
CREATE OR REPLACE VIEW `stock-trading-498512.state.regime_restore_shortfall_risk` AS
WITH donors AS (
  -- Donor capacity is the capital-ENABLED strategies' undeployed cash -- the same figure bigquery/98's
  -- restore_payable caps against.
  SELECT ROUND(COALESCE(SUM(GREATEST(n.available_funds, 0)), 0), 2) AS donor_capacity
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = e.strategy_code
  LEFT JOIN `stock-trading-498512.analytics.strategy_nav` n ON n.strategy = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
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
-- THE THIRD CLAIM ON THE SAME POOL. Three independent mechanisms draw on the capital-enabled
-- strategies' idle cash and NONE of them can see the other two: regime-debt RESTORE (above), the SISA
-- PENDING-NEWCOMER probe-stake fill (bigquery/62 — every newly adopted strategy has first claim on
-- inflows until it reaches its $2,000 floor), and external WITHDRAWALS (bigquery/161). Surfacing all
-- three against one capacity number is the whole point of this view; a shortfall that only appears
-- once you add the second and third claim is exactly the kind nobody would have seen coming.
newcomer AS (
  SELECT ROUND(COALESCE(SUM(GREATEST(funding_gap_dollars, 0)), 0), 2) AS pending_newcomer_claim
  FROM `stock-trading-498512.state.strategy_probe_funding_gap`
)
-- DRIVEN FROM `donors`, WITH `debt` LEFT-JOINED -- deliberately, not FROM debt. `donors` and
-- `newcomer` are bare aggregates with no GROUP BY, so each always returns exactly one row even over
-- zero input. `debt` is not: it returns nothing once every strategy is square. Joining FROM debt
-- would therefore make this whole view vanish in precisely the healthy state it exists to confirm --
-- and a dashboard or a human reading zero rows cannot tell "all clear" from "the view is broken" or
-- "no data yet". Alerting degrades safely either way (no debt means no risk means no rows to alert
-- on), but a monitor that goes silent when healthy is indistinguishable from a monitor that has died,
-- which is the failure mode this repo's own dead-man's-switch discipline exists to prevent. This
-- shape always emits at least one row: a single all-clear row with strategy = NULL when no debt
-- exists, and one row per debtor otherwise.
SELECT
  debt.strategy,
  ROUND(COALESCE(debt.outstanding_debt, 0), 2) AS outstanding_debt,
  donors.donor_capacity,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS total_outstanding_debt,
  newcomer.pending_newcomer_claim,
  ROUND(COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim, 2)
    AS total_claims_on_idle_pool,
  -- If EVERY debtor re-enabled at once, could they all be made whole?
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0), 2) AS aggregate_headroom,
  -- The same question with the newcomer floor-fill claim included, since it outranks the restore
  -- (Operating_Protocols §16: "newcomers have first claim on every inflow until filled").
  ROUND(donors.donor_capacity - COALESCE(SUM(debt.outstanding_debt) OVER (), 0)
        - newcomer.pending_newcomer_claim, 2) AS headroom_after_all_claims,
  -- If THIS debtor alone re-enabled today, what would it actually get back?
  ROUND(LEAST(COALESCE(debt.outstanding_debt, 0), donors.donor_capacity), 2) AS would_restore_today,
  ROUND(GREATEST(COALESCE(debt.outstanding_debt, 0) - donors.donor_capacity, 0), 2) AS shortfall_if_alone,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0)) AS aggregate_at_risk,
  (donors.donor_capacity < COALESCE(SUM(debt.outstanding_debt) OVER (), 0) + newcomer.pending_newcomer_claim)
    AS at_risk_including_newcomer_claim,
  (donors.donor_capacity < COALESCE(debt.outstanding_debt, 0)) AS individually_at_risk,
  debt.strategy IS NULL AS is_all_clear_row
FROM donors CROSS JOIN newcomer LEFT JOIN debt ON TRUE;

-- ===== Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'capital_stranded' AS category,
    FALSE AS latching,
    'Auto-resolves when state.capital_utilisation_watch returns no is_stranded row - either the strategy deploys, or it gets evaluated again, or its idle capital drops below the 1000.00 floor.' AS resolve_rule,
    'A capital-ENABLED strategy holds material idle capital, has not deployed in 90+ days, AND has had no thesis-construction evaluation in 60 days. Deliberately narrow: a strategy that IS being evaluated and honestly declining is healthy per Operating_Protocols section 16 and never fires this. WARNING, never critical - stranded capital is an allocation-efficiency signal, not a trading fault, and a critical would enter the blocking_criticals halt term.' AS note),
  STRUCT(
    'regime_restore_shortfall' AS category,
    FALSE AS latching,
    'Auto-resolves when donor capacity again covers the outstanding regime-capital debt - typically when a donor exits a position and its cash returns to available_funds.' AS resolve_rule,
    'Outstanding regime-capital debt exceeds what the capital-enabled donors could actually return. A strategy that was swept while disabled would come back structurally smaller than it left, permanently - the direct inverse of the reward-winners-via-survivorship objective. WARNING: it is a forward risk, not a present error, and the debt ledger itself stays arithmetically correct throughout.' AS note),
  STRUCT(
    'capital_concentration' AS category,
    FALSE AS latching,
    'Auto-resolves when no single strategy holds more than 60 percent of total book NAV, or when the concentrated holder resumes deploying.' AS resolve_rule,
    'Informational breadth check registered alongside bigquery/164 so the 96-percent-in-two-never-traded-strategies condition of 2026-08-11 would have surfaced on its own. Not wired to a raise call on apply - reserved for a future D3/W5 step.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Utilisation watch. As of 2026-08-11 expect exactly TWO rows (C and E, the only capital-enabled
--    strategies), both with idle_capital ~9436.86 / ~9342.37, never_deployed=true,
--    days_since_deployment ~111, and BOTH classified 'idle but ACTIVELY EVALUATED' with
--    is_stranded=FALSE -- E on 4 evaluations, C on 2. Zero alerts today is the CORRECT result:
--    SELECT strategy_code, idle_capital, days_since_deployment, never_deployed, evaluations_60d,
--           last_evaluation_date, posture, is_stranded
--    FROM `stock-trading-498512.state.capital_utilisation_watch` ORDER BY strategy_code;
--
-- 2. Sweep weights. Expect C and E both at capacity_ratio 0.0, band_multiplier 0.5, sweep_share 0.5,
--    equal_share 0.5 -- i.e. the weight currently changes NOTHING, which is the correct degenerate
--    case for two indistinguishable non-deploying recipients:
--    SELECT * FROM `stock-trading-498512.state.sweep_recipient_weights` ORDER BY strategy_code;
--
-- 3. Restore shortfall. Expect three rows (A/B/D) totalling 13135.49 against donor_capacity
--    ~18779.23, aggregate_headroom ~+5643.74, aggregate_at_risk=FALSE. The headroom is positive ONLY
--    because C and E hold everything as cash; re-run this after either deploys:
--    SELECT * FROM `stock-trading-498512.state.regime_restore_shortfall_risk` ORDER BY strategy;
--
-- 4. Three categories registered, all non-latching:
--    SELECT category, latching FROM `stock-trading-498512.ops.alert_policy`
--    WHERE category IN ('capital_stranded','regime_restore_shortfall','capital_concentration');
--
-- 5. FALSE-POSITIVE PROOF for the stranded predicate -- it must stay silent on a healthy idle
--    strategy. This should return zero rows today:
--    SELECT * FROM `stock-trading-498512.state.capital_utilisation_watch` WHERE is_stranded;

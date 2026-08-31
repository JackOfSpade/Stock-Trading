-- bigquery/202_sweep_recipient_weights_nomadic_exclusion.sql (2026-08-30)
-- Project: stock-trading-498512. Apply after bigquery/164_capital_utilisation_and_restore_integrity.sql
-- (which created this view), bigquery/166_capital_dormancy_sweep.sql (state.strategy_declared_frequency,
-- the nomadic source table, unchanged and reused here), and bigquery/168_nomadic_capital_fixes.sql
-- (FIX 7, which set state.regime_capital_sync_pending's recipient predicate this file now matches).
--
-- ONE OBJECT REDEFINED: state.sweep_recipient_weights. SUPERSEDES bigquery/164's definition of that
-- view and NOTHING ELSE — bigquery/164's other two views (state.capital_utilisation_watch,
-- state.regime_restore_shortfall_risk) are untouched here. A SUPERSEDED marker is added at 164's
-- definition site in this same commit, matching the convention bigquery/167 and bigquery/168 used.
--
-- ============================ WHY ================================================================
-- D2a raised ops.alerts info `sweep_recipient_view_drift` on 2026-08-27 (alert_id
-- d36365ca-aef0-47ea-b4e8-95d855581a32). The two views D2a's REGIME-CAPITAL SYNC substep reads
-- disagree about who may RECEIVE a regime sweep, and the disagreement is about ELIGIBILITY, not
-- weighting:
--   state.regime_capital_sync_pending (bigquery/168 FIX 7): capital_enabled AND NOT nomadic -> {E}
--   state.sweep_recipient_weights     (bigquery/164, this file's target): capital_enabled AND
--                                      is_active, NO nomadic term at all           -> {C, E} @ 0.5
--
-- bigquery/164 was authored 2026-08-11 BEFORE bigquery/167/168 introduced the nomadic concept later
-- the same day, and was never revisited. Its own header describes it as a capacity TILT among whoever
-- the recipients already are ("A MECHANICAL, judgment-free recipient weight the D2a regime-capital
-- SWEEP substep can apply") — it defers recipient ELIGIBILITY to the sweep view it feeds. But the D2a
-- spec bullet says to take recipient AMOUNTS from this view, so a session reading it literally and
-- without cross-checking credits an ineligible nomadic recipient.
--
-- THAT HAS ALREADY HAPPENED TWICE, both MEASURED in events.cash_flows, both source='regime_capital_sweep':
--   2026-08-12: C credited 27.86 (= ROUND(55.71 * sweep_share 0.5, 2)); the nomadic sweep in the SAME
--               run pulled C's entire 9,464.72 balance back out to E — the exact round-trip
--               bigquery/167 header point 5 says its redesign exists to prevent.
--   2026-08-18: C credited 23.68 (= ROUND(47.35 * sweep_share 0.5, 2)); C STILL HOLDS IT on 2026-08-30,
--               un-swept only because 23.68 sits below the $25 nomadic de-minimis floor
--               (state.nomadic_capital_sync_pending's `WHERE sweep_now AND sweepable_amount >= 25`).
-- Neither is a capital loss — the ledger stays arithmetically correct and $0-sum throughout — but both
-- are book churn that analytics.strategy_nav and any later reconstruction have to see through, and the
-- second one is a live, standing residual on a strategy that by owner directive holds no standing capital.
--
-- WHY THE EXCLUSION IS THE OWNER'S DESIGN, NOT THIS FILE'S OPINION. Operating_Protocols.md §16 NOMADIC
-- STRATEGY CAPITAL: a NOMADIC strategy "holds NO exclusive standing capital, not even a reserve floor".
-- Its "Excluded from the JUDGMENT capital-inflow paths" bullet already names this view's consumer:
-- "state.regime_capital_sync_pending's SWEEP recipient set ... also excludes nomadic strategies —
-- without that, a router-disabled strategy's regime sweep would route a share to a nomadic strategy
-- that just needs sweeping right back out next pass." This file makes the WEIGHT view agree with the
-- ELIGIBILITY view that the same paragraph already governs. It is alignment, not a new policy.
--
-- SCOPE CHECK — this is NOT the carve-out §16 says to leave alone. That same §16 bullet warns: "Do not
-- 'fix' it by special-casing the sweep; if a future pass wants to remove the round-trip, the correct
-- place is §13.C's deposit-recording flow." That warning is explicitly about the DEFAULT-EQUAL DEPOSIT
-- path — a below-MEDIUM-conviction deposit recorded as a single `strategy` NULL row, which
-- bigquery/127's `dep` CTE equal-splits by roster HEADCOUNT, consulting neither enablement nor nomadic
-- status. Both misfires above were verified to carry source='regime_capital_sweep', NOT a NULL-strategy
-- deposit, so they are the REGIME SWEEP path this file's own §16 sentence governs. The deposit
-- round-trip §16 protects is left exactly as it is.
--
-- WHY THE NOMADIC TERM IS THE ONLY SEMANTIC CHANGE. bigquery/98's state.strategy_capital_enablement
-- already ends `FROM state.strategy_roster r ... WHERE r.is_active`, so 164's extra roster JOIN for
-- is_active is redundant (harmless, and KEPT below to hold the diff to one clause). With the nomadic
-- term added, this view's recipient set becomes predicate-identical to bigquery/168 FIX 7's
-- `enabled_recipients` CTE, so `sweep_share` once again sums to 1.0 across exactly the set that is
-- allowed to receive — which is what makes D2a's existing "do not sum to 1.0 ± 0.0001" fallback guard
-- meaningful rather than vacuous.
--
-- READS THE CHEAP SOURCE, DELIBERATELY. The exclusion joins state.strategy_declared_frequency (a static
-- 5-row table) directly, NOT state.strategy_nomadic_status — the same cheap-source substitution
-- bigquery/167 and bigquery/168 both make and both document: is_nomadic is a straight pass-through of
-- is_low_frequency_by_design with no other gating, so the substitution is correctness-neutral, and the
-- expensive form chains through state.capital_utilisation_watch's decision-log anti-join (measured
-- 3.7M+ slot-ms per read, 2026-08-11).
--
-- `strategy_code IS NOT NULL` GUARD inside the NOT IN subquery: `x NOT IN (... NULL ...)` evaluates to
-- NULL, not TRUE, so a single NULL strategy_code in that hand-maintained seed table would empty this
-- view. It degrades safely (D2a falls back to DEFAULT-EQUAL on an empty weight view) but silently, and
-- check_roster_consistency.py's R-L check already documents that this table is hand-maintained and is
-- NOT regenerated when SISA autonomously adopts a strategy. Verified 2026-08-30: all 5 rows non-NULL.
-- bigquery/167/168 use the unguarded idiom; the guard is added here rather than propagating that.
--
-- NO BEHAVIOUR CHANGE TO ANY OTHER OBJECT. Verified 2026-08-30 against INFORMATION_SCHEMA.VIEWS in
-- state/analytics/ops: ZERO live views reference state.sweep_recipient_weights. Its only consumers are
-- PROSE — Claude_Task_Plan.md's D2a REGIME-CAPITAL SYNC bullet (amounts) and W5's informational read —
-- both amended in this same commit. bigquery/166's SQL consumer does not exist: bigquery/167 superseded
-- 166 in full and DROPped state.capital_dormancy_sync_pending (confirmed live — no %dormancy% view remains).

CREATE OR REPLACE VIEW `stock-trading-498512.state.sweep_recipient_weights` AS
WITH enabled AS (
  SELECT e.strategy_code
  FROM `stock-trading-498512.state.strategy_capital_enablement` e
  JOIN `stock-trading-498512.state.strategy_roster` r ON r.strategy_code = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
    -- ADDED (bigquery/202, 2026-08-30): nomadic exclusion, so this view's recipient set is
    -- predicate-identical to state.regime_capital_sync_pending's `enabled_recipients` (bigquery/168
    -- FIX 7). A NOMADIC strategy holds no exclusive standing capital (Operating_Protocols.md §16), so
    -- it is not an eligible sweep RECIPIENT and must never be handed a tilt share.
    AND e.strategy_code NOT IN (
      SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
      WHERE is_low_frequency_by_design AND strategy_code IS NOT NULL
    )
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

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The two views now agree on the recipient SET. Expect ZERO rows (empty symmetric difference):
--    WITH nomadic AS (
--      SELECT strategy_code FROM `stock-trading-498512.state.strategy_declared_frequency`
--      WHERE is_low_frequency_by_design AND strategy_code IS NOT NULL),
--    auth AS (SELECT strategy_code FROM `stock-trading-498512.state.strategy_capital_enablement` e
--      WHERE e.capital_enabled AND e.strategy_code NOT IN (SELECT strategy_code FROM nomadic)),
--    w AS (SELECT strategy_code FROM `stock-trading-498512.state.sweep_recipient_weights`)
--    SELECT COALESCE(a.strategy_code, w.strategy_code) AS strategy_code,
--           a.strategy_code IS NOT NULL AS in_authoritative, w.strategy_code IS NOT NULL AS in_weights
--    FROM auth a FULL OUTER JOIN w ON w.strategy_code = a.strategy_code
--    WHERE a.strategy_code IS NULL OR w.strategy_code IS NULL;
--
-- 2. As of 2026-08-30 expect exactly ONE row -- E, capacity_ratio 0.0, band_multiplier 0.5,
--    n_recipients 1, sweep_share 1.0, equal_share 1.0. Nomadic C is gone; pre-apply this returned
--    C and E at sweep_share 0.5 each. sweep_share == equal_share means the tilt is (correctly) doing
--    nothing with a single recipient -- the weight bites only when >=2 eligible recipients differ:
--    SELECT * FROM `stock-trading-498512.state.sweep_recipient_weights` ORDER BY strategy_code;
--
-- 3. Shares still normalise to exactly 1.0, so D2a's "do not sum to 1.0 +/- 0.0001" DEFAULT-EQUAL
--    fallback guard stays meaningful rather than firing spuriously:
--    SELECT ROUND(SUM(sweep_share), 6) AS total_share
--    FROM `stock-trading-498512.state.sweep_recipient_weights`;
--
-- 4. Nomadic strategies are absent from the weight view but still present in, and still repayable by,
--    the regime debt ledger -- this file must not have touched restore eligibility (bigquery/168 FIX 7
--    keeps restore_candidates nomadic-INCLUSIVE; D carries regime debt and stays a valid debtor):
--    SELECT strategy, outstanding_debt FROM `stock-trading-498512.state.regime_capital_debt`
--    WHERE outstanding_debt > 0 ORDER BY strategy;

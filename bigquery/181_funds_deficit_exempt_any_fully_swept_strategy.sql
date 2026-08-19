-- state.strategy_funds_deficit — re-key the deposits<0 carve-out on the ARITHMETIC that makes it
-- benign (nav >= 0) instead of on the strategy's nomadic CLASSIFICATION (2026-08-18, D2a).
-- Project: stock-trading-498512.
--
-- ============================ WHY ================================================================
-- Found live by D2a on 2026-08-18, immediately after its own REGIME-CAPITAL SWEEP wrote the row that
-- exposed it. This is not a hypothetical.
--
-- WHAT HAPPENED. B:MSCI:2026-07-27 exited on invalidation (D2 staged 2026-08-17, D2a reconciled the
-- fill 2026-08-18). That was Strategy B's LAST open position, so B went flat, and its 47.35 of freed
-- available_funds cleared the $25 floor. B has been capital-DISABLED since the 2026-08-05
-- STRATEGY_ACTIVATION DO-NOT-ACTIVATE verdict, so state.regime_capital_sync_pending correctly emitted
-- a SWEEP row and D2a swept the full 47.35 to C/E. Sweeping a flat strategy's full available_funds
-- takes its NAV to exactly zero -- which is the intended end state -- and drove its deposits column
-- to -18.22. state.strategy_funds_deficit then fired, with likely_cause
--   'booked deposits are negative - a flow was allocated to a strategy that did not hold it'.
--
-- That diagnosis is WRONG here, and the arithmetic proves it:
--   deposits(-18.22) + realized_pnl(17.45) + dividends_held(0.78) + unrealized(0) = 0.01 ~= 0 = nav
-- B held every dollar that was swept. deposits went negative only because the 47.35 included B's own
-- accumulated realized P&L and held dividends -- NAV components that do not live in the deposits
-- column -- so a full sweep necessarily lands deposits at -(realized + unrealized + dividends).
-- B is FLAT, not underwater.
--
-- WHY THE EXISTING CARVE-OUT DID NOT COVER IT. bigquery/168's FIX 9 already identified this exact
-- shape, named it "the benign swept-out-own-P&L case", and exempted it -- but gated the exemption on
-- COALESCE(f.is_low_frequency_by_design, FALSE), i.e. on the strategy being NOMADIC, and recorded the
-- narrowing deliberately: "deposits<0 still fires for every non-nomadic strategy."
--
-- That scoping was reasonable when written: the NOMADIC sweep was then the only mechanism that
-- routinely swept a strategy to exactly zero. But FIX 9's own mechanism sentence -- "the sweep removes
-- available_funds ... so with deployed=0 the post-sweep balance is exactly
-- deposits = -(realized + unrealized + dividends)" -- is generic to ANY full sweep. The REGIME-CAPITAL
-- sweep (bigquery/98) does precisely the same thing to a capital-disabled strategy the moment its last
-- position closes. 2026-08-18 is the first time that has actually happened. The exemption keyed on WHY
-- a strategy was swept; the thing that makes the row benign is the arithmetic fact that its NAV is not
-- negative. This file re-keys it accordingly.
--
-- THE HAZARD THIS CLOSES IS THE ONE FIX 9 ITSELF NAMED. bigquery/168 records that the audit verifier's
-- concern was "the real hazard is a future session 'fixing' it with a corrective cash_flow entry, which
-- would be the genuinely dangerous action." A permanently-open warning whose likely_cause text asserts
-- a misallocation that did not occur is exactly the bait for that. Left alone, B's row could never
-- clear on its own (short of re-activation + RESTORE), so it would sit open indefinitely, misdescribing
-- a healthy state, in front of every future session. Writing a compensating +18.22 cash_flow to "fix"
-- it would manufacture capital for B out of nothing.
--
-- ============================ THE CHANGE =========================================================
-- Predicate before (bigquery/168):
--   OR (ROUND(n.deposits,2) < 0
--       AND NOT (COALESCE(f.is_low_frequency_by_design,FALSE) AND ROUND(n.nav,2) >= 0))
-- Predicate after (this file):
--   OR (ROUND(n.deposits,2) < 0 AND ROUND(n.nav,2) < 0)
--
-- Only the nomadic conjunct is dropped. Everything FIX 9 guaranteed is preserved except the single
-- clause that just produced a false positive:
--   * available_funds < 0 still fires for EVERY strategy, untouched and independent.
--   * deposits < 0 still fires for EVERY strategy -- nomadic or not -- whose NAV is ALSO negative,
--     which is the genuine-misallocation signature: there, the negative deposits is NOT explained by
--     swept-out own P&L.
--   * The exemption can only ever suppress a strategy that is NOT underwater on its own books.
-- The risk profile is therefore identical to the one bigquery/168 already accepted for nomadic
-- strategies; it is now applied uniformly rather than by classification.
--
-- Note on the residual: a genuine misallocation LARGE enough to push deposits below zero but SMALL
-- enough to leave nav >= 0 would be suppressed. That is unchanged from bigquery/168's nomadic arm and
-- is inherent to nav >= 0 being the test. It is the correct trade: nav >= 0 is precisely equivalent to
-- "the negative deposit base is fully covered by this strategy's own accumulated gains", since
-- nav = deposits + realized + unrealized + dividends - (nothing else). A strategy that is whole cannot
-- be diagnosed as having spent money it never held.
--
-- The is_nomadic OUTPUT column and the nomadic-specific likely_cause branch are both KEPT: the join is
-- still needed for them, and that branch still describes exactly the rows it now catches (a NOMADIC
-- strategy with negative deposits AND negative NAV).
--
-- SUPERSEDES bigquery/168_nomadic_capital_fixes.sql's FIX 9 definition of this view, which in turn
-- superseded bigquery/161_withdrawal_after_the_fact.sql's original definition.

CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_funds_deficit` AS
SELECT
  n.strategy,
  ROUND(n.available_funds, 2) AS available_funds,
  ROUND(n.deposits, 2)        AS deposits,
  ROUND(n.nav, 2)             AS nav,
  ROUND(n.deployed_mv, 2)     AS deployed_mv,
  COALESCE(f.is_low_frequency_by_design, FALSE) AS is_nomadic,
  CASE
    -- Both deposits<0 branches ALSO require nav<0 (added 2026-08-18, interactive audit). Without it a
    -- row admitted by the FIRST WHERE arm (available_funds<0, i.e. over-deployed) that happens to carry
    -- deposits<0 and nav>=0 -- a fully-swept strategy later funded into a position -- was labelled
    -- 'negative deposits AND negative NAV ... genuine misallocation' while its NAV was non-negative.
    -- That is the same false label this file exists to remove, one WHERE-arm over: the CASE has to
    -- mirror the arm that admitted the row, or it asserts a fact the row does not carry. The ELSE now
    -- correctly and exclusively describes the available_funds<0 arm.
    WHEN ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0 AND COALESCE(f.is_low_frequency_by_design, FALSE)
      THEN 'NOMADIC strategy with negative deposits AND negative NAV - this is NOT the benign swept-out-own-P&L case (which is expected and exempted); investigate as a genuine misallocation'
    WHEN ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0
      THEN 'negative deposits AND negative NAV - the negative deposit base is NOT covered by this strategy own accumulated gains, so it is not the benign fully-swept case; investigate as a genuine misallocation'
    ELSE 'deployed market value exceeds this strategy booked NAV'
  END AS likely_cause
FROM `stock-trading-498512.analytics.strategy_nav` n
LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f ON f.strategy_code = n.strategy
WHERE ROUND(n.available_funds, 2) < 0
   -- deposits<0 fires for EVERY strategy whose NAV is ALSO negative (the genuine-misallocation
   -- signature). It is exempted ONLY when nav >= 0, i.e. when the negative deposits is exactly the
   -- retained-own-P&L artefact that ANY full sweep produces by design -- the nomadic sweep
   -- (bigquery/167/168) and the regime-capital sweep (bigquery/98) alike. bigquery/168's FIX 9 keyed
   -- this on the nomadic classification; 2026-08-18 showed the regime-capital path reaches the same
   -- benign state, so it is keyed on the arithmetic instead.
   OR (ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The view is clean again -- B's benign fully-swept row is gone, and nothing else appeared:
--    SELECT * FROM `stock-trading-498512.state.strategy_funds_deficit`;
--    -> expect ZERO rows.
--
-- 2. B is genuinely flat, not suppressed while underwater -- deposits negative, but NAV exactly zero
--    and fully explained by its own retained gains:
--    SELECT strategy, deposits, realized_pnl, unrealized_pnl, dividends_held, deployed_mv, nav,
--           available_funds
--    FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = 'B';
--    -> expect deposits -18.22, realized_pnl 17.45, dividends_held 0.78, deployed_mv 0, nav 0.00.
--
-- 3. The genuine-misallocation arm still fires. Negative-NAV detection is unchanged for every
--    strategy, nomadic or not:
--    SELECT strategy, deposits, nav, is_nomadic, likely_cause
--    FROM `stock-trading-498512.analytics.strategy_nav` n
--    LEFT JOIN `stock-trading-498512.state.strategy_declared_frequency` f
--           ON f.strategy_code = n.strategy
--    WHERE ROUND(n.nav, 2) < 0;
--    -> expect zero rows today; any row here would also appear in state.strategy_funds_deficit.

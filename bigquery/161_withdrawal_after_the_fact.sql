-- bigquery/161_withdrawal_after_the_fact.sql (2026-08-10)
-- Project: stock-trading-498512. Apply after bigquery/127_strategy_nav_dust_exclusion.sql
-- (canonical analytics.strategy_nav), bigquery/98_regime_capital_enablement.sql
-- (state.regime_capital_debt), and bigquery/62_probe_stake_funding.sql
-- (state.strategy_probe_funding_gap).
--
-- NET-NEW OBJECTS ONLY. This file defines four new objects and registers one new alert category.
-- It redefines NOTHING: analytics.strategy_nav (bigquery/127) and analytics.account_reconciliation
-- (bigquery/156) are read, never re-created here, so no SUPERSEDED marker is owed anywhere and the
-- supersession chain is untouched.
--
-- ============================ WHY ================================================================
-- The system has never recorded a genuine external WITHDRAWAL. Every flow_type='WITHDRAWAL' row in
-- events.cash_flows to date carries source='regime_capital_sweep' and is an internal, zero-sum
-- inter-strategy double-entry (verified: 4 rows, summing to -13135.49, exactly offset by the paired
-- regime_capital_sweep DEPOSIT rows). Experiment_Parameters.md deferred the methodology "until the
-- first withdrawal is required". That deferral was never true of the LIVE system: Operating_Protocols
-- §13.C already hard-codes a mechanical default -- record it strategy NULL -- which D2a Step 0 will
-- execute autonomously the first time it classifies a residual as a withdrawal.
--
-- THAT DEFAULT IS BROKEN AGAINST THE CURRENT ROSTER. bigquery/127's `dep` CTE splits a NULL-strategy
-- flow by roster HEADCOUNT, gated only on immutable_since/retired_date -- it never consults
-- state.strategy_capital_enablement. All five strategies are capital-eligible, so a NULL-strategy
-- withdrawal debits every one of them equally, including the three the regime router disabled and
-- swept to zero. Simulated live 2026-08-10 against a 3500.00 withdrawal:
--     A: deposits 0.00 -> -700.00, available_funds -700.00
--     B: deposits 84.84 -> -615.16, available_funds -718.35
--     D: deposits 578.18 -> -121.82, available_funds -700.01
-- Three of five strategies go negative on money they do not hold.
--
-- THE DEPOSIT DIRECTION SELF-HEALS; THE WITHDRAWAL DIRECTION DOES NOT. The same NULL default already
-- misfired on the deposit side: the 2026-08-05 operator deposit of 9995.39 was recorded strategy NULL
-- and mechanically handed capital-disabled A a 1999.08 share it should never have received. That was
-- caught same-day only because bigquery/98's state.regime_capital_sync_pending SWEEP branch fires on
-- `available_funds >= 25` -- a SURPLUS-only predicate. A withdrawal pushes a disabled strategy
-- NEGATIVE, which can never satisfy `>= 25`, so that branch is structurally blind to it, and no other
-- detector for a negative available_funds exists anywhere in bigquery/*.sql. A mis-booked withdrawal
-- would sit in the ledger indefinitely with nothing watching.
--
-- ============================ THE RULE ===========================================================
-- Allocate a withdrawal PRO-RATA TO NAV, CLAMPED TO IDLE CASH, WITH THE OVERFLOW REDISTRIBUTED --
-- materialized at write time as one strategy-tagged row per donor.
--
-- A withdrawal is a deduction against the WHOLE portfolio, so the fair BASIS is each strategy's total
-- size (analytics.strategy_nav.nav), not the accident of how much of it happens to be sitting in cash
-- on the day the money leaves. But money can only physically come from where money physically is, so
-- each strategy's charge is CAPPED at its own idle cash (available_funds) and whatever it cannot
-- absorb is redistributed, by the same NAV proportion, across the strategies that still have room.
-- This is the clamp-and-redistribute idiom Operating_Protocols §16 already uses for the
-- capital-allocation call's band, applied to the withdrawal direction.
--
-- WHY NOT THE TWO SIMPLER RULES:
--   * EQUAL-DOLLAR SPLIT BY HEADCOUNT (the retired default) is only fair between equal-SIZED
--     strategies, and this roster is nothing like equal. It also debits strategies that hold no cash,
--     which either books a negative balance (a fiction with no self-heal, see above) or implies
--     force-closing open positions to raise the cash. A withdrawal must never silently close a trade.
--   * PRO-RATA TO IDLE CASH ALONE is self-limiting and never goes negative, but it carries a timing
--     distortion: it charges whichever strategy happens to be sitting in cash on the withdrawal date
--     and spares whichever happens to be fully deployed. The deployed strategy then exits its
--     positions and is left relatively LARGER for having been invested on the wrong day. NAV as the
--     basis removes that artifact; the clamp keeps the feasibility guarantee that made idle-only
--     attractive in the first place.
--
-- WHY IT MUST BE MATERIALIZED rather than computed in the view: available_funds and nav are both
-- functions of `deposits`, which is what the allocation sets -- a read-time definition would be
-- circular -- and both drift daily, so recomputing an old flow's split later would silently revise
-- history. The split is a fact about the moment of the flow. bigquery/127's `dep` CTE already sums a
-- strategy-tagged row directly (`WHEN cf.strategy = a.s THEN cf.amount`), so N tagged rows ARE the
-- allocation, permanently, with no view change required.
--
-- CAPITAL-DISABLED STRATEGIES fall out of this naturally, with no flag check: the regime sweep has
-- already taken their idle cash, so their cap is 0, they saturate on the first pass and bear nothing.
-- Keying donor eligibility on the FLAG instead would be actively unsafe -- bigquery/98's sweep
-- CROSS JOINs against enabled_set, so if every strategy were simultaneously DO-NOT-ACTIVATE the sweep
-- silently produces zero rows and the capital just sits in the disabled strategies' own balances. A
-- flag-keyed donor test would then find zero eligible donors and refuse every withdrawal while the
-- account's entire capital sat right there. Keying on available_funds > 0 has no such trap.
--
-- RAILS (all three enforced by ops.sp_record_withdrawal below):
--   1. REFUSE, do not spill. If the withdrawal exceeds total donor capacity, write NOTHING and raise
--      a critical alert. Spilling into deployed strategies would re-introduce the exact
--      negative-balance corruption this rule exists to prevent, and choosing WHICH position to
--      liquidate is a portfolio judgment that belongs to the capital-allocation machinery, not to a
--      formula buried in an accounting procedure.
--   2. PROTECT A SUB-FLOOR NEWCOMER. A PROBE-phase strategy still below its 2000.00 probe-stake floor
--      (state.strategy_probe_funding_gap.funding_gap_dollars > 0) shows a positive available_funds
--      that is indistinguishable from ordinary idle cash, but it is protected capital -- it is the
--      exact balance the deposit-side PENDING-NEWCOMER FIRST CLAIM exists to build up. Zero-weight
--      it, so a withdrawal cannot claw back a newcomer stake the deposit path just protected.
--   3. EXACT TO THE CENT. Rounded shares are summed and the residual is applied to the largest donor,
--      so SUM(rows) equals the withdrawal exactly. A cash ledger that does not foot is worse than one
--      that is slightly unfair.
--
-- REGIME-CAPITAL DEBT (owner decision 2026-08-10): a withdrawal takes priority over the outstanding
-- regime-capital debt, and the impact is SURFACED rather than gated. state.withdrawal_capacity below
-- reports restore headroom so the drain is visible. Rationale: the debt is an internal IOU to
-- strategies that are not currently trading, not an external obligation, and gating the owner's own
-- liquidity on it would let a suspended strategy veto a withdrawal. Consequence, knowingly accepted:
-- when a disabled strategy is re-enabled, bigquery/98's RESTORE pays LEAST(outstanding_debt,
-- donor_capacity), so a large enough cumulative withdrawal makes that restore partial and the
-- shortfall persists on the ledger.
--
-- ============================ NO ADVANCE NOTICE ==================================================
-- Owner directive 2026-08-10: a withdrawal will never be declared in advance; the system must
-- discover it after the fact and adapt. There is therefore NO operator-declared earmark anywhere in
-- this design.
--
-- The disambiguation an advance declaration would have provided comes from TIME instead, via
-- events.cash_flow_candidates: D2a records a CANDIDATE on the first session that observes an
-- unexplained cash decrease, and commits the real rows on the next session that still observes the
-- cash gone. This matters because the connector exposes no funding or transaction ledger at all --
-- verified across the full 33-tool IBKR MCP surface; get_account_trades returns fills only, and
-- get_pa_performance_all_periods returns TWR without the flows underneath it -- so a withdrawal is
-- never OBSERVED, only inferred by elimination per §13.B. Every competing explanation for an
-- unexplained debit is self-resolving within a session or two (a settlement hold clears, a
-- late-settling fill posts, a multi-day fee accrual stops accruing); a real withdrawal is not. One
-- extra cycle buys most of the safety of a declaration and costs the operator nothing.
--
-- The open candidate also does the second job an earmark would have done, with no operator action:
-- while it is open its amount is excluded from §13.E's free_cash, so the park sweep stops trying to
-- re-park money that is on its way out of the account.
--
-- ============================ THE BACKSTOP =======================================================
-- state.strategy_funds_deficit is the detector this system has never had: ANY strategy whose
-- available_funds goes negative, from any cause, not just a withdrawal. bigquery/98 watches only for
-- a surplus on a disabled strategy; nothing watched for a deficit on any strategy. Deliberately
-- registered as a non-latching WARNING, not a critical: a critical would enter the halt_reason CASE
-- blocking_criticals term (bigquery/107) and freeze all order staging including exits, which is a
-- wildly disproportionate response to a bookkeeping-integrity signal. It auto-resolves when the
-- deficit clears.

-- ===== events.cash_flow_candidates =====
-- Append-only two-phase staging for an INFERRED, not yet committed, external cash flow. A candidate
-- is never itself read by analytics.strategy_nav or analytics.account_reconciliation -- only a
-- committed events.cash_flows row moves the books. Status transitions are recorded by appending a new
-- row with the same candidate_key, never by mutating an existing row.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.cash_flow_candidates` (
  candidate_id STRING DEFAULT GENERATE_UUID(),
  candidate_key STRING NOT NULL,   -- stable key across the two passes, e.g. 'wd-2026-08-13'
  observed_date DATE NOT NULL,     -- trading-day key of the observation (America/Denver, per the pinned operating plane)
  status STRING NOT NULL,          -- 'open' | 'confirmed' | 'retracted'
  direction STRING NOT NULL,       -- 'WITHDRAWAL' | 'DEPOSIT'
  amount NUMERIC NOT NULL,         -- signed, same convention as events.cash_flows: +deposit, -withdrawal
  evidence STRING,                 -- connector evidence for the inference (balances before/after, TWR corroboration)
  note STRING,
  source STRING DEFAULT 'D2a',
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (candidate_id) NOT ENFORCED
) PARTITION BY observed_date
OPTIONS(description='Two-phase staging for an inferred external cash flow. D2a appends status=open on the first session that sees an unexplained cash move, then status=confirmed (after calling ops.sp_record_withdrawal) or status=retracted (the move reversed, so it was a settlement hold) on a later session. Append-only: a status change is a NEW row with the same candidate_key. Never read by the NAV views -- only committed events.cash_flows rows move the books.');

-- ===== state.cash_flow_candidates_open =====
-- Latest row per candidate_key, still open. Two readers: D2a Step 0 (the second-pass confirmation),
-- and §13.E step 1 (free_cash excludes an open withdrawal candidate so the sweep does not re-park
-- cash that is leaving).
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flow_candidates_open` AS
SELECT candidate_key, observed_date, direction, amount, evidence, note, source, event_ts,
  DATE_DIFF(CURRENT_DATE('America/Denver'), observed_date, DAY) AS days_open
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY candidate_key ORDER BY event_ts DESC, candidate_id) AS rn
  FROM `stock-trading-498512.events.cash_flow_candidates`
)
WHERE rn = 1 AND status = 'open';

-- ===== state.withdrawal_capacity =====
-- One row per capital-eligible strategy: its donor weight under the pro-rata-to-idle rule, whether it
-- is eligible to donate, and why not if it is not. Account-level totals are repeated on every row
-- (window aggregates) so a single SELECT answers both "who pays" and "how much can leave".
-- restore_headroom_after_full_capacity surfaces the regime-capital-debt coupling the owner chose to
-- accept rather than gate on.
CREATE OR REPLACE VIEW `stock-trading-498512.state.withdrawal_capacity` AS
WITH base AS (
  SELECT
    sn.strategy,
    ROUND(sn.available_funds, 2) AS available_funds,
    ROUND(sn.nav, 2) AS nav,
    ROUND(sn.deployed_mv, 2) AS deployed_mv,
    COALESCE(pg.funding_gap_dollars, 0) AS probe_funding_gap,
    COALESCE(ce.capital_disabled, FALSE) AS capital_disabled,
    COALESCE(sr.is_active, FALSE) AS roster_active,
    -- Debt owed to a TERMINATED strategy is extinguished (Operating_Protocols.md:553) -- but by
    -- UNREACHABILITY, not by a zeroing write: state.regime_capital_debt itself has no is_active or
    -- retired_date filter, so a terminated strategy keeps reporting outstanding_debt forever even
    -- though bigquery/98's RESTORE can never fire for it again (RESTORE targets enabled_set, which
    -- filters WHERE r.is_active). Summing the raw column here would therefore over-report the debt
    -- the moment the first termination lands, making restore headroom look worse than it is. Zero it
    -- for an inactive strategy so this view stays true after a termination.
    CASE WHEN COALESCE(sr.is_active, FALSE) THEN COALESCE(rd.outstanding_debt, 0) ELSE 0 END
      AS outstanding_regime_debt
  FROM `stock-trading-498512.analytics.strategy_nav` sn
  LEFT JOIN `stock-trading-498512.state.strategy_probe_funding_gap` pg
    ON pg.strategy_code = sn.strategy
  LEFT JOIN `stock-trading-498512.state.strategy_capital_enablement` ce
    ON ce.strategy_code = sn.strategy
  LEFT JOIN `stock-trading-498512.state.regime_capital_debt` rd
    ON rd.strategy = sn.strategy
  LEFT JOIN `stock-trading-498512.state.strategy_roster` sr
    ON sr.strategy_code = sn.strategy
),
scored AS (
  SELECT *,
    -- nav_basis = the share of the withdrawal this strategy SHOULD bear (its size in the portfolio).
    -- cap = the most it CAN actually pay (its idle cash). The two differ for a deployed strategy, and
    -- the procedure's waterfall reconciles them by redistributing whatever a strategy cannot absorb.
    -- A PROBE newcomer still below its stake floor is zeroed on BOTH: it neither bears a share nor
    -- donates cash, mirroring the deposit-side newcomer-first-claim that built that stake up.
    CASE WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 0 ELSE GREATEST(nav, 0) END AS nav_basis,
    CASE WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 0 ELSE GREATEST(available_funds, 0) END AS cap,
    -- A donor must hold idle cash AND not be a newcomer below its probe-stake floor. capital_disabled
    -- is deliberately NOT a disqualifier: a disabled strategy has already been swept to zero idle, so
    -- its cap is 0 and it saturates immediately -- while keying on the FLAG would refuse every
    -- withdrawal in the reachable state where every strategy is DO-NOT-ACTIVATE at once (bigquery/98's
    -- sweep CROSS JOINs enabled_set and silently produces zero rows, leaving the capital sitting in
    -- the disabled strategies' own balances).
    (available_funds > 0 AND COALESCE(probe_funding_gap, 0) <= 0) AS is_donor,
    CASE
      WHEN COALESCE(probe_funding_gap, 0) > 0 THEN 'PROBE newcomer below its 2000.00 stake floor - protected'
      WHEN available_funds <= 0 AND nav > 0 THEN 'bears a share by NAV but holds no idle cash - clamps to zero, share redistributes'
      WHEN available_funds <= 0 THEN 'no idle cash'
      ELSE NULL
    END AS exclusion_reason
  FROM base
)
SELECT
  strategy,
  available_funds,
  nav,
  deployed_mv,
  capital_disabled,
  roster_active,
  probe_funding_gap,
  nav_basis,
  cap,
  is_donor,
  exclusion_reason,
  ROUND(SUM(cap) OVER (), 2) AS total_donor_capacity,
  ROUND(SUM(nav_basis) OVER (), 2) AS total_nav_basis,
  -- Unclamped NAV-proportional target, for inspection only. The procedure's waterfall clamps this to
  -- `cap` and redistributes the overflow, so a strategy's actual charge can be less than this (never
  -- more). Where cap >= this target for every strategy, the two coincide.
  SAFE_DIVIDE(nav_basis, SUM(nav_basis) OVER ()) AS nav_share,
  outstanding_regime_debt,
  ROUND(SUM(outstanding_regime_debt) OVER (), 2) AS total_outstanding_regime_debt,
  -- What would remain to service the regime-capital debt if the full donor capacity were withdrawn.
  -- Negative means a full-capacity withdrawal would leave bigquery/98's RESTORE unable to repay the
  -- disabled strategies in full. Reported, never enforced (owner decision 2026-08-10).
  ROUND(SUM(cap) OVER () - SUM(outstanding_regime_debt) OVER (), 2)
    AS restore_headroom_after_full_capacity
FROM scored;

-- ===== state.strategy_funds_deficit =====
-- The missing backstop: any strategy carrying a NEGATIVE idle balance, from any cause. bigquery/98's
-- state.regime_capital_sync_pending SWEEP branch watches `available_funds >= 25` (surplus-only) and
-- is structurally blind to this.
--
-- SUPERSEDED LIVE by bigquery/168_nomadic_capital_fixes.sql — current single source of truth for
-- this view. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation. 168 carves out a narrow nomadic exception: a nomadic
-- strategy's post-sweep negative deposits (= -(realized + unrealized + dividends) once deployed_mv
-- is 0) is the normal steady state after any profitable trade, not a misallocation, so deposits<0
-- alone no longer fires for a nomadic strategy unless nav is ALSO negative (audit finding 1, HIGH).
-- available_funds<0 still fires for everyone, and deposits<0 still fires for every non-nomadic
-- strategy.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_funds_deficit` AS
SELECT
  strategy,
  ROUND(available_funds, 2) AS available_funds,
  ROUND(deposits, 2) AS deposits,
  ROUND(nav, 2) AS nav,
  ROUND(deployed_mv, 2) AS deployed_mv,
  CASE
    WHEN deposits < 0 THEN 'booked deposits are negative - a flow was allocated to a strategy that did not hold it'
    ELSE 'deployed market value exceeds this strategy booked NAV'
  END AS likely_cause
FROM `stock-trading-498512.analytics.strategy_nav`
WHERE ROUND(available_funds, 2) < 0 OR ROUND(deposits, 2) < 0;

-- ===== ops.sp_record_withdrawal =====
-- The single sanctioned write path for a genuine external withdrawal. in_amount is a POSITIVE
-- magnitude (the dollars that left the account); the procedure writes the signed negative rows.
-- Pass in_candidate_key to mark the matching two-phase candidate confirmed in the same call, or NULL
-- for an operator-directed recording with no candidate.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_record_withdrawal`(
  in_amount NUMERIC,
  in_flow_date DATE,
  in_note STRING,
  in_candidate_key STRING
)
BEGIN
  DECLARE v_capacity NUMERIC;
  DECLARE v_donors INT64;
  DECLARE v_msg STRING;
  DECLARE v_remaining NUMERIC;
  DECLARE v_iter INT64;

  -- A caller bug (wrong sign, missing date) is the one condition that RAISEs: it is not a business
  -- state, and failing loudly is the only way it gets noticed.
  IF in_amount IS NULL OR in_amount <= 0 THEN
    RAISE USING MESSAGE = 'sp_record_withdrawal: in_amount must be a positive magnitude (the dollars that left the account); the procedure writes the negative rows itself.';
  END IF;
  IF in_flow_date IS NULL THEN
    RAISE USING MESSAGE = 'sp_record_withdrawal: in_flow_date must not be NULL (events.cash_flows.flow_date is NOT NULL; a NULL would fail late with a generic constraint error instead of here).';
  END IF;

  -- IDEMPOTENCY GATE. When a candidate key is supplied, the candidate MUST still be open, and this is
  -- checked BEFORE anything is written. Without this, a second call with the same key -- an operator
  -- retry, or a catch-up refire under the retry-v2 / OPS2 protocols -- would re-run the cash_flows
  -- INSERT and double-debit the donors, while the confirmation INSERT below silently wrote zero rows
  -- (its FROM state.cash_flow_candidates_open join no longer matches once status flipped to
  -- confirmed). Silent double-spend on one side, silent no-op on the other. Exiting here instead
  -- makes the whole procedure idempotent per candidate_key: the second call is a no-op with a
  -- visible warning. A NULL key (a deliberate operator-directed recording with no candidate) skips
  -- this gate by design and is the caller's responsibility not to repeat.
  IF in_candidate_key IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.cash_flow_candidates_open`
                     WHERE candidate_key = in_candidate_key) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'warning', 'sp_record_withdrawal', 'withdrawal_candidate_not_open',
      CONCAT('sp_record_withdrawal called for candidate_key that is not open; NOTHING was recorded. ',
             'It was already confirmed, already retracted, or never existed.'),
      TO_JSON_STRING(STRUCT(
        in_candidate_key AS candidate_key,
        in_amount AS requested_amount,
        in_flow_date AS flow_date)));
    RETURN;
  END IF;

  -- Defensive: BigQuery temp tables live for the whole session, so a prior call that aborted between
  -- the two CREATEs would otherwise make this call fail with "already exists" on stale data.
  -- Staleness is handled by CREATE OR REPLACE TEMP TABLE below, NOT by a leading DROP. A leading
  -- `DROP TABLE IF EXISTS _alloc;` looks equivalent and is not: BigQuery resolves an UNQUALIFIED
  -- table name in statement order, so before any CREATE TEMP TABLE of that name has executed in the
  -- session it is not yet a known temp name and the statement fails outright with
  -- 'Table "_alloc" must be qualified with a dataset' -- even with IF EXISTS, which guards against a
  -- missing table, not an unresolvable name. That made every fresh CALL abort on its own cleanup
  -- line. Caught by the post-apply smoke test on 2026-08-10, not by the dry run, which cannot
  -- semantically analyse anything after the first DDL in a script.
  -- Every strategy that either SHOULD bear a share (nav_basis > 0) or CAN pay one (cap > 0). Rows
  -- with nav_basis > 0 and cap = 0 -- a fully-deployed strategy -- belong in the first pass so the
  -- NAV denominator is the true whole-portfolio basis; they clamp to 0 immediately and their share
  -- redistributes to whoever has room.
  CREATE OR REPLACE TEMP TABLE _alloc AS
  SELECT strategy, nav_basis, cap, CAST(0 AS NUMERIC) AS assigned
  FROM `stock-trading-498512.state.withdrawal_capacity`
  WHERE nav_basis > 0 OR cap > 0;

  SET v_donors = (SELECT COUNT(*) FROM _alloc WHERE cap > 0);
  SET v_capacity = COALESCE((SELECT SUM(cap) FROM _alloc), 0);

  -- RAIL 1: refuse and alert rather than spill into deployed strategies.
  IF v_donors = 0 OR in_amount > v_capacity THEN
    SET v_msg = CONCAT(
      'Withdrawal of ', CAST(in_amount AS STRING),
      ' exceeds total donor capacity ', CAST(v_capacity AS STRING),
      ' across ', CAST(v_donors AS STRING), ' eligible strategy(ies). NOTHING was recorded.');
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'sp_record_withdrawal', 'withdrawal_exceeds_capacity',
      v_msg,
      TO_JSON_STRING(STRUCT(
        in_amount AS requested_amount,
        v_capacity AS donor_capacity,
        v_donors AS donor_count,
        in_flow_date AS flow_date,
        in_candidate_key AS candidate_key)));
    DROP TABLE IF EXISTS _alloc;
    -- RETURN, not RAISE. This is an expected business state, not a caller bug, and the alert is the
    -- signal: withdrawal_exceeds_capacity is critical + latching, so it enters the blocking_criticals
    -- term of the halt_reason CASE (bigquery/107) and freezes order staging until a human clears it --
    -- the correct response to the books and the broker genuinely disagreeing. RAISEing instead would
    -- abort the CALLING routine's script mid-session, and for D2a that costs Step 0b's
    -- ops.account_snapshot write, which has no backfill loop -- a permanently missing NAV day that
    -- can understate peak_gain in the drawdown breaker (bigquery/153's fail-dangerous gap). Never
    -- trade a recoverable accounting refusal for an unrecoverable history hole.
    RETURN;
  END IF;

  -- THE WATERFALL. Each pass distributes what is still unallocated across the strategies that are not
  -- yet at their cap, in proportion to nav_basis, clamping each to its cap. A strategy that cannot
  -- absorb its full NAV-proportional share saturates and its overflow flows to the rest on the next
  -- pass. Terminates in at most one pass per strategy (each pass saturates at least one, or finishes),
  -- so the iteration bound is a backstop against a NUMERIC rounding stall, never the normal exit.
  SET v_remaining = in_amount;
  SET v_iter = 0;
  WHILE v_remaining > 0 AND v_iter < 20 DO
    SET v_iter = v_iter + 1;
    UPDATE _alloc a
    SET assigned = LEAST(a.cap, a.assigned + v_remaining * SAFE_DIVIDE(a.nav_basis, u.tn))
    FROM (SELECT SUM(nav_basis) AS tn FROM _alloc WHERE assigned < cap AND nav_basis > 0) u
    WHERE a.assigned < a.cap AND a.nav_basis > 0 AND u.tn > 0;
    SET v_remaining = in_amount - (SELECT COALESCE(SUM(assigned), 0) FROM _alloc);
  END WHILE;

  -- RAIL 3: round to the cent, then apply the whole rounding residual to the donor with the most
  -- unused headroom (never a saturated one, which could not absorb it without exceeding its own cap).
  CREATE OR REPLACE TEMP TABLE _shares AS
  WITH r AS (
    SELECT strategy, cap AS available_funds, nav_basis,
      ROUND(assigned, 2) AS share,
      ROW_NUMBER() OVER (ORDER BY (cap - assigned) DESC, cap DESC, strategy ASC) AS rk
    FROM _alloc
    WHERE assigned > 0
  ),
  adj AS (SELECT in_amount - SUM(share) AS residual FROM r)
  SELECT r.strategy, r.available_funds, r.nav_basis,
    r.share + CASE WHEN r.rk = 1 THEN (SELECT residual FROM adj) ELSE 0 END AS share
  FROM r;

  INSERT INTO `stock-trading-498512.events.cash_flows`
    (flow_date, flow_type, amount, strategy, note, source)
  SELECT
    in_flow_date,
    'WITHDRAWAL',
    -s.share,
    s.strategy,
    CONCAT(
      'EXTERNAL WITHDRAWAL of ', CAST(in_amount AS STRING),
      ', allocated pro-rata to NAV and clamped to idle cash (bigquery/161). This strategy share ',
      CAST(s.share AS STRING), ' against nav_basis ', CAST(s.nav_basis AS STRING),
      ' and idle-cash cap ', CAST(s.available_funds AS STRING),
      '; total donor capacity was ', CAST(v_capacity AS STRING),
      '. The basis is the whole portfolio (NAV), because a withdrawal is a deduction against all of it;',
      ' the cap is what each strategy could actually pay, and any share a strategy could not absorb was',
      ' redistributed to those with room. A PROBE newcomer below its stake floor neither bears nor donates. ',
      COALESCE(in_note, '')),
    'external_withdrawal'
  FROM _shares s;

  IF in_candidate_key IS NOT NULL THEN
    INSERT INTO `stock-trading-498512.events.cash_flow_candidates`
      (candidate_key, observed_date, status, direction, amount, evidence, note, source)
    SELECT in_candidate_key, c.observed_date, 'confirmed', 'WITHDRAWAL', -in_amount, c.evidence,
      CONCAT('Confirmed and committed to events.cash_flows by ops.sp_record_withdrawal. ', COALESCE(in_note, '')),
      'sp_record_withdrawal'
    FROM `stock-trading-498512.state.cash_flow_candidates_open` c
    WHERE c.candidate_key = in_candidate_key;
  END IF;

  DROP TABLE IF EXISTS _alloc;
  DROP TABLE IF EXISTS _shares;
END;

-- ===== Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'strategy_funds_deficit' AS category,
    FALSE AS latching,
    'Auto-resolves when state.strategy_funds_deficit returns no rows for the named strategy. A deficit is a bookkeeping-integrity signal, not a trading condition.' AS resolve_rule,
    'Raised by D2a Step 0 when any strategy carries a negative available_funds or negative booked deposits. Deliberately WARNING, not critical: a critical would enter the blocking_criticals term of the halt_reason CASE (bigquery/107) and freeze all order staging including exits. Root cause is almost always a cash flow allocated to a strategy that did not hold the money - see bigquery/161 for why the NULL-strategy equal split was retired for withdrawals.' AS note),
  STRUCT(
    'withdrawal_exceeds_capacity' AS category,
    TRUE AS latching,
    'Human-only. Raised when ops.sp_record_withdrawal refuses a withdrawal larger than total donor idle capacity. Nothing was written; the withdrawal must be reconciled deliberately (raise cash by closing a position, or record a partial withdrawal against actual idle capacity).' AS resolve_rule,
    'Latching by design: the books and the broker genuinely disagree at this point, and the disagreement cannot be cleared mechanically.' AS note),
  STRUCT(
    'withdrawal_candidate_not_open' AS category,
    FALSE AS latching,
    'Auto-resolves on the next clean pass. Informational: ops.sp_record_withdrawal was called for a candidate_key that was already confirmed, already retracted, or never existed. Nothing was written - this is the idempotency gate doing its job, not a fault.' AS resolve_rule,
    'Expected on a catch-up refire or an operator retry of an already-committed withdrawal. Investigate only if it repeats with a key that should have been open.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Donor set and capacity as of apply. Expect C and E as the only donors (cap > 0); B and D to
--    carry a positive nav_basis with cap = 0 and the "bears a share by NAV but holds no idle cash"
--    exclusion_reason; A zero on everything. total_donor_capacity ~18779.23, total_nav_basis
--    ~19497.71, total_outstanding_regime_debt 13135.49, restore_headroom_after_full_capacity ~5643.74:
--    SELECT strategy, available_funds, nav, nav_basis, cap, is_donor, exclusion_reason, nav_share,
--           total_donor_capacity, total_nav_basis, total_outstanding_regime_debt,
--           restore_headroom_after_full_capacity
--    FROM `stock-trading-498512.state.withdrawal_capacity` ORDER BY strategy;
--
-- 1b. Waterfall behaviour, verified read-only 2026-08-10 against these live figures before apply:
--    * live shape (C/E fully idle)        -> C=1758.81, E=1741.19  (identical to a pure idle split,
--                                            because nav == available_funds for both today)
--    * C clamped to a 1000.00 idle cap    -> C=1000.00 (saturated), E=2500.00 (absorbs the overflow)
--    * every strategy cap-constrained     -> B=28.72, C=1200.00, D=171.28, E=2100.00
--    All three foot to 3500.00 exactly with no strategy exceeding its own cap.
--
-- 2. The deficit detector must be EMPTY on a clean book (this is the pre-withdrawal baseline):
--    SELECT * FROM `stock-trading-498512.state.strategy_funds_deficit`;
--    -> expect zero rows.
--
-- 3. No open candidates before D2a has ever run this path:
--    SELECT * FROM `stock-trading-498512.state.cash_flow_candidates_open`;
--    -> expect zero rows.
--
-- 4. Both alert categories registered exactly once:
--    SELECT category, latching FROM `stock-trading-498512.ops.alert_policy`
--    WHERE category IN ('strategy_funds_deficit','withdrawal_exceeds_capacity');
--    -> expect 2 rows; strategy_funds_deficit latching=false, withdrawal_exceeds_capacity latching=true.
--
-- 5. Refusal rail fires and writes nothing (safe to run -- it RAISEs before any INSERT):
--    CALL `stock-trading-498512.ops.sp_record_withdrawal`(999999, CURRENT_DATE('America/Denver'), 'rail test', NULL);
--    -> expect an error naming the donor capacity, a latching withdrawal_exceeds_capacity alert, and
--    SELECT COUNT(*) FROM `stock-trading-498512.events.cash_flows` WHERE source='external_withdrawal'
--    still 0. Resolve the test alert afterwards.

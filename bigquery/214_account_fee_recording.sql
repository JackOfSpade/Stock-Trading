-- ===== 214: recurring account-fee recording -- closing the 13.C-attributes / 13.D-cannot-record gap =====
-- (2026-09-03, interactive alert triage of ops.alerts b81aab6a `cash_fee` + c35b7b3b
-- `recurring_account_fee_unbooked`, both raised by D2a 2026-09-03.)
--
-- WHAT TRIGGERED THIS. D2a observed a -4.448205 settled-cash outflow on 2026-09-03 with no trade, no
-- corporate action, no position drift and no withdrawal signature, attributed it to the September
-- month-start IBKR account/market-data fee per Operating_Protocols.md 13.C, and then could not BOOK
-- it: 13.C prescribes an attribution ("Standalone account fee / interest, no fill -> equal-split
-- across active strategies") while 13.D provides no write path for that class at all.
-- events.cash_flows is documented DEPOSIT/WITHDRAWAL-only and ops.sp_record_withdrawal is
-- withdrawal-only, so two runs two months apart each re-derived the same disposition from precedent
-- rather than from a rule, and neither booked anything. Consequence: analytics.strategy_nav (and
-- therefore available_funds and sizing_base_2pct) drifts ONE-DIRECTIONALLY HIGH by the cumulative
-- unbooked fees. This file adds the missing sink.
--
-- THE FEE SERIES, MEASURED (not the two-point series the info alert names). It is MONTHLY, posting
-- overnight after the SECOND US business day and read on the THIRD:
--   2026-05-05  4.510000  MEASURED  events.decision_log 2026-05-05 fill-capture, "account-level USD
--                                   Cash $4.51 unaccounted"; closed 2026-05-07 as fee-or-timing-noise.
--   2026-06-03  4.970000  MEASURED-BOUNDED. No decision-log entry exists, and the 2026-06-04 D2
--                                   tripwire read "PASS, no missing funds" -- because the 13.E COVER
--                                   had already absorbed it. IBKR get_account_trades(LAST_QUARTER)
--                                   shows a 0.05 SGOV SELL at 2026-06-03T13:30:04Z (gross 5.0205,
--                                   commission 0.05036522), i.e. a cover, which only fires at
--                                   settled_cash <= -5. Cover sizing is ceil_to_4dp((|cash|+comm)/bid),
--                                   so qty 0.05 at bid 100.41 pins |cash| to (4.96, 4.9701]. The prior
--                                   evening closed at ~0.00 (a 0.01 SGOV micro-cover at 2026-06-02
--                                   T18:48:09Z pins it to <= 0.01), and NO trade sits between the two.
--                                   So an unexplained ~4.97 outflow occurred overnight 06-02 -> 06-03.
--                                   Booked at 4.97, the top of the measured interval.
--   2026-07-03  4.500000  MEASURED  events.decision_log cfc1e2c9 (residual_usd 4.5, prior_cash 78.38
--                                   -> post_cash 73.88); ops.alerts cd09790b.
--   2026-08-05  4.612351  MEASURED -- AND DELIBERATELY NOT BOOKED HERE. See the next paragraph.
--   2026-09-03  4.448205  MEASURED  ops.alerts b81aab6a; settled cash 88.8482 -> -4.4594 against
--                                   -0.011195 expected after the 88.859395 park-sweep BUY.
--
-- WHY AUGUST IS NOT IN THE BACKFILL, AND MUST NEVER BE ADDED WITHOUT ALSO RESTATING THE DEPOSIT.
-- The August fee IS real but is ALREADY ABSORBED, by accident rather than by design. IBKR mail
-- "Deposit Activity Update" 2026-08-05T12:38:04Z reads "A USD ******** Check deposit ... was received
-- on 2026-07-27 and is now available". The masking is character-length-preserving: the 2026-08-11
-- "Withdrawal Activity" mail for the known 3525.00 carries exactly SEVEN asterisks (7 characters), so
-- the deposit mail's EIGHT asterisks mean an 8-character amount -- 10000.00, which arithmetically
-- excludes 9995.39 (7 characters). events.cash_flows row 405d0b9a booked the NET 9995.387649, so
-- 10000.00 - 9995.387649 = 4.612351 of fee is already out of events-side NAV. Booking an August fee
-- row on top of that would DOUBLE-charge it; restating 405d0b9a to the 10000.00 gross without
-- simultaneously booking the fee would create a 4.61 overstatement that does not exist today. Either
-- both or neither -- and neither is the smaller change, so neither is what this file does.
--
-- THE ALLOCATION BASIS IS NOT 13.C's EQUAL-SPLIT. This is the substantive correction in this file.
-- 13.C's fee bullet prescribes "equal-split across active strategies", which is the exact methodology
-- bigquery/161 RETIRED for withdrawals on 2026-08-10 ("SUPERSEDES the former ... default, which is
-- RETIRED for withdrawals and must never be reinstated"), for the exact reason that applies here.
-- Measured live 2026-09-03 against analytics.strategy_nav: A available_funds 0.00, B 0.00, C 23.68,
-- D 0.00 (549.24 fully deployed), E 15386.78. An equal split of 4.448205 charges A, B and D
-- 0.889641 each out of 0.00 of idle cash, driving all three negative and taking
-- state.strategy_funds_deficit from 0 rows to 3. Unclamped NAV-pro-rata still breaks D.
-- This procedure therefore uses the SAME basis and the SAME clamp as ops.sp_record_withdrawal --
-- pro-rata to NAV, clamped to each strategy own available_funds, unabsorbed share redistributed --
-- by reusing state.withdrawal_capacity verbatim. Measured result for the September fee:
-- E 4.441370, C 0.006835, A/B/D 0.00, and state.strategy_funds_deficit stays empty.
-- A capital-DISABLED strategy bears zero WITHOUT needing capital_disabled as a predicate: the sweep
-- has already taken its idle cash to 0, so the clamp produces the right answer on its own -- the same
-- reasoning bigquery/161 records for withdrawals.
--
-- WHY flow_type IS 'WITHDRAWAL' AND NOT A NEW 'FEE' VALUE. Claude_Task_Plan.md / task_plan/D2a.md pin
-- flow_type to DEPOSIT/WITHDRAWAL following the SIGN of amount (2026-08-19). Verified live: NO object
-- anywhere filters events.cash_flows.flow_type -- of the 8 live views that read the table, only
-- state.cash_flow_source_unknown even PROJECTS the column, and analytics.strategy_nav dep CTE keys
-- purely on strategy and signed amount. So a new 'FEE' value would be mechanically identical to
-- 'WITHDRAWAL' in every consumer while contradicting a pinned convention -- a governance cost for
-- zero mechanical benefit. The semantic distinction between an external flow, an internal
-- reallocation and an EXPENSE is carried by `source`, which is exactly what bigquery/163 built the
-- provenance allowlist for. Hence source='account_fee'.
--
-- APPLY: live via the BigQuery MCP, in this order, as ONE unit of work with the dbt mirrors
-- (dbt/models/state/{book_drawdown_watch,cash_flows_backfill_check,cash_flow_source_unknown}.sql) --
-- the dbt-parity CI job fails closed on any mirror drift and would strand every open branch.

-- ===== (1) state.cash_flow_source_unknown -- add 'account_fee' to the sanctioned set =====
-- SUPERSEDES the definition in bigquery/167_nomadic_capital.sql (chain: 163 -> 167 -> 214).
-- Without this, every fee row this file writes is flagged by D3 as unsanctioned provenance and raises
-- a WARNING cash_flow_source_unknown for 14 days. The allowlist is the whole point of the view: a new
-- movement mechanism is added to the set in a successor file, never invented in-session.
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
      'nomadic_capital_restore', -- bigquery/167 (renamed from capital_dormancy_restore)
      'account_fee'              -- bigquery/214 (recurring IBKR account / market-data fee)
    )
    OR source LIKE 'backfill-%'
    )
  );

-- ===== (2) state.book_drawdown_watch -- exclude fee rows from cum_flows =====
-- SUPERSEDES the definition in bigquery/155_snapshot_and_option_anomaly_d2a_gate.sql
-- (chain: 78 -> 153 -> 155 -> 214). ONLY the flowed CTE changes; every other line is byte-identical.
--
-- THIS AMENDMENT PRESERVES CURRENT BEHAVIOUR -- it does not change the breaker. Read carefully,
-- because the naive reading is backwards. `snaps.nav` is ops.account_snapshot.nav, which is written
-- from the CONNECTOR (source 'D2a-connector'), so it ALREADY reflects a fee the moment the money
-- leaves. cum_flows did not. So today gain = nav - cum_flows is already reduced by every fee, i.e.
-- fees ALREADY count as trading drawdown, which is correct -- a fee is an expense, not a capital
-- movement by the investor. Booking fee rows into events.cash_flows WITHOUT this exclusion would drop
-- cum_flows by the same amount and cancel that out, newly HIDING fees from the -15%/-40% breaker in
-- the flattering direction. The magnitude is small (18.43 cumulative against a ~15.9k book, ~0.12%,
-- versus a 15% threshold) so this is not a live breach risk either way -- but the direction is
-- one-way and it compounds, so the exclusion lands in the same unit of work as the booking.
CREATE OR REPLACE VIEW `stock-trading-498512.state.book_drawdown_watch` AS
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM `stock-trading-498512.ops.account_snapshot`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
flowed AS (
  SELECT
    s.snapshot_date,
    s.nav,
    -- cumulative net external flows (deposits +, withdrawals -) up to and including this snapshot.
    -- bigquery/214: source='account_fee' is EXCLUDED. A recurring account/market-data fee is an
    -- EXPENSE of running the book, not an external capital movement, so it must stay inside the
    -- flow-neutral trading gain rather than neutralising itself out of it.
    COALESCE((
      SELECT SUM(cf.amount)
      FROM `stock-trading-498512.events.cash_flows` cf
      WHERE cf.flow_date <= s.snapshot_date
        AND COALESCE(cf.source, '') <> 'account_fee'
    ), 0) AS cum_flows
  FROM snaps s
),
gained AS (
  SELECT
    snapshot_date, nav, cum_flows,
    nav - cum_flows AS gain,
    MAX(nav - cum_flows) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_gain
  FROM flowed
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, cum_flows, gain, peak_gain) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM gained
),
ltd AS (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_gain + agg.latest.cum_flows AS peak_nav,
  agg.latest.cum_flows AS capital_base,
  SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0
   AND agg.latest.snapshot_date < ltd.last_trading_day
   AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
               WHERE routine = 'D2a' AND status = 'completed'
                 AND run_date >= ltd.last_trading_day)) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.account_snapshot_gap`) AS peak_window_gap_days
FROM agg CROSS JOIN ltd;

-- ===== (3) state.cash_flows_backfill_check -- rebase expected_total for the in-window fee backfill =====
-- SUPERSEDES the definition in bigquery/148_audit_2026_08_08_fixes.sql (chain: 22 -> 68 -> 148 -> 214).
-- The check asserts SUM(amount) over flow_date <= 2026-07-03 against a literal, so that it keeps
-- meaning something after legitimate later flows. THREE of the backfilled fees fall inside that
-- window -- 2026-05-05 (4.51), 2026-06-03 (4.97) and 2026-07-03 (4.50), 13.98 total -- so the literal
-- must move with them or `reconciled` flips FALSE permanently and the ledger-corruption alarm this
-- check exists to raise becomes a standing false positive. 9446.86 - 13.98 = 9432.88.
-- The check's PURPOSE is unchanged: it still detects a total-loss corruption of the backfilled rows.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flows_backfill_check` AS
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
   WHERE flow_date <= DATE '2026-07-03') AS cash_flows_total_asof_backfill,
  CAST(9432.88 AS NUMERIC) AS expected_total,
  COALESCE((SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
            WHERE flow_date <= DATE '2026-07-03') = CAST(9432.88 AS NUMERIC), FALSE) AS reconciled;

-- ===== (4) ops.sp_record_account_fee =====
-- The single sanctioned write path for a recurring account / market-data fee. in_amount is a POSITIVE
-- magnitude (the dollars that left the account); the procedure writes the signed negative rows.
--
-- IDEMPOTENCY is keyed on (source='account_fee', flow_date), not on a separate candidate table. The
-- fee posts once per month on a known calendar slot, so flow_date IS the natural key, and keying on
-- it means a catch-up refire or an operator retry is a visible no-op instead of a double charge.
-- Deliberately NOT modelled on ops.sp_record_withdrawal two-pass candidate flow: that exists because
-- a withdrawal must not be committed on first observation (a settlement hold looks identical for a
-- session). A fee has no such competing explanation once the residual is attributed, and its own
-- competing explanations are eliminated in the same run.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_record_account_fee`(
  in_amount NUMERIC,
  in_flow_date DATE,
  in_note STRING
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
    RAISE USING MESSAGE = 'sp_record_account_fee: in_amount must be a positive magnitude (the dollars that left the account); the procedure writes the negative rows itself.';
  END IF;
  IF in_flow_date IS NULL THEN
    RAISE USING MESSAGE = 'sp_record_account_fee: in_flow_date must not be NULL (events.cash_flows.flow_date is NOT NULL; a NULL would fail late with a generic constraint error instead of here).';
  END IF;

  -- IDEMPOTENCY GATE, checked BEFORE anything is written.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.events.cash_flows`
             WHERE source = 'account_fee' AND flow_date = in_flow_date) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'warning', 'sp_record_account_fee', 'account_fee_already_booked',
      'sp_record_account_fee called for a flow_date that already carries account_fee rows; NOTHING was recorded.',
      TO_JSON_STRING(STRUCT(
        in_flow_date AS flow_date,
        in_amount AS requested_amount)));
    RETURN;
  END IF;

  -- Same basis and same clamp as ops.sp_record_withdrawal, by reusing its capacity view verbatim
  -- rather than restating the rule. Rows with nav_basis > 0 and cap = 0 (a fully-deployed strategy)
  -- belong in the first pass so the NAV denominator is the true whole-portfolio basis; they clamp to
  -- 0 immediately and their share redistributes to whoever has room.
  CREATE OR REPLACE TEMP TABLE _fee_alloc AS
  SELECT strategy, nav_basis, cap, CAST(0 AS NUMERIC) AS assigned
  FROM `stock-trading-498512.state.withdrawal_capacity`
  WHERE nav_basis > 0 OR cap > 0;

  SET v_donors = (SELECT COUNT(*) FROM _fee_alloc WHERE cap > 0);
  SET v_capacity = COALESCE((SELECT SUM(cap) FROM _fee_alloc), 0);

  -- RAIL 1: refuse and alert rather than spill into deployed strategies. RETURN, not RAISE -- same
  -- reasoning as bigquery/161: RAISEing aborts the CALLING routine mid-script, and for D2a that costs
  -- Step 0b ops.account_snapshot write, which has no backfill loop.
  IF v_donors = 0 OR in_amount > v_capacity THEN
    SET v_msg = CONCAT(
      'Account fee of ', CAST(in_amount AS STRING),
      ' exceeds total donor capacity ', CAST(v_capacity AS STRING),
      ' across ', CAST(v_donors AS STRING), ' eligible strategy(ies). NOTHING was recorded.');
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'sp_record_account_fee', 'account_fee_exceeds_capacity',
      v_msg,
      TO_JSON_STRING(STRUCT(
        in_amount AS requested_amount,
        v_capacity AS donor_capacity,
        v_donors AS donor_count,
        in_flow_date AS flow_date)));
    DROP TABLE IF EXISTS _fee_alloc;
    RETURN;
  END IF;

  -- THE WATERFALL, identical in shape to bigquery/161: each pass distributes what is still
  -- unallocated in proportion to nav_basis, clamping each to its cap; a saturated strategy overflow
  -- flows to the rest on the next pass. The iteration bound is a backstop against a NUMERIC rounding
  -- stall, never the normal exit.
  SET v_remaining = in_amount;
  SET v_iter = 0;
  WHILE v_remaining > 0 AND v_iter < 20 DO
    SET v_iter = v_iter + 1;
    UPDATE _fee_alloc a
    SET assigned = LEAST(a.cap, a.assigned + v_remaining * SAFE_DIVIDE(a.nav_basis, u.tn))
    FROM (SELECT SUM(nav_basis) AS tn FROM _fee_alloc WHERE assigned < cap AND nav_basis > 0) u
    WHERE a.assigned < a.cap AND a.nav_basis > 0 AND u.tn > 0;
    SET v_remaining = in_amount - (SELECT COALESCE(SUM(assigned), 0) FROM _fee_alloc);
  END WHILE;

  -- Round to the cent, then apply the whole rounding residual to the donor with the most unused
  -- headroom (never a saturated one, which could not absorb it without exceeding its own cap).
  CREATE OR REPLACE TEMP TABLE _fee_shares AS
  WITH r AS (
    SELECT strategy, cap AS available_funds, nav_basis,
      ROUND(assigned, 2) AS share,
      ROW_NUMBER() OVER (ORDER BY (cap - assigned) DESC, cap DESC, strategy ASC) AS rk
    FROM _fee_alloc
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
      'RECURRING ACCOUNT FEE of ', CAST(in_amount AS STRING),
      ', allocated pro-rata to NAV and clamped to idle cash (bigquery/214, same basis and clamp as',
      ' ops.sp_record_withdrawal). This strategy share ', CAST(s.share AS STRING),
      ' against nav_basis ', CAST(s.nav_basis AS STRING),
      ' and idle-cash cap ', CAST(s.available_funds AS STRING),
      '; total donor capacity was ', CAST(v_capacity AS STRING),
      '. flow_type is WITHDRAWAL because it follows the SIGN of amount; the EXPENSE semantics are',
      ' carried by source=account_fee, which state.book_drawdown_watch excludes from cum_flows so the',
      ' fee stays inside flow-neutral trading gain instead of neutralising itself out of it. NOT the',
      ' 13.C equal-split, which would charge strategies that hold no idle cash and drive them negative. ',
      COALESCE(in_note, '')),
    'account_fee'
  FROM _fee_shares s;

  DROP TABLE IF EXISTS _fee_alloc;
  DROP TABLE IF EXISTS _fee_shares;
END;

-- ===== (5) Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'cash_fee' AS category,
    FALSE AS latching,
    'ROUTINE-OWNED, evidence-based resolve keyed on the fee having been BOOKED, never on the cash residual having disappeared -- the 13.E cover absorbs the residual within a session by selling park shares, so residual-disappearance is guaranteed and proves nothing. Resolve when events.cash_flows carries source=account_fee rows for the alert flow_date whose magnitudes sum to the attributed amount. NOT covered by any ops.sp_auto_resolve_alerts rule (those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/staleness), so latching=FALSE only SANCTIONS the resolve, it does not perform it.' AS resolve_rule,
    'CASH-INTEGRITY CLASS, first raised 2026-07-03 (cd09790b); registered 2026-09-03 alongside bigquery/214, after the second firing (b81aab6a) revealed the class had no ops.alert_policy row and therefore no written resolve rule -- the same accident-of-absence discipline used by append_only_violation and premortem_preamble_stale. Raised by D2a when an attributed standalone account/market-data fee is observed. WARNING, not critical: it is ATTRIBUTED by construction, so the ~$1 cash_tripwire hard STOP explicitly does not fire and nothing is blocked.' AS note),
  STRUCT(
    'account_fee_exceeds_capacity' AS category,
    TRUE AS latching,
    'Human-only. Raised when ops.sp_record_account_fee refuses a fee larger than total donor idle capacity. Nothing was written; the fee must be reconciled deliberately. Modelled exactly on withdrawal_exceeds_capacity.' AS resolve_rule,
    'Latching by design: the books and the broker genuinely disagree at this point, and the disagreement cannot be cleared mechanically. NEVER YET RAISED.' AS note),
  STRUCT(
    'account_fee_already_booked' AS category,
    FALSE AS latching,
    'Auto-resolves on the next clean pass. Informational: ops.sp_record_account_fee was called for a flow_date that already carries account_fee rows. Nothing was written - this is the idempotency gate doing its job, not a fault.' AS resolve_rule,
    'Expected on a catch-up refire or an operator retry of an already-booked fee. Investigate only if it repeats with a flow_date that should have been unbooked.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- ===== (6) Backfill: the four unabsorbed fees =====
-- Ordered oldest-first. August is deliberately absent -- see the header. Each CALL is idempotent per
-- flow_date, so re-running this file during a DR rebuild is safe and lands exactly these four rows.
--
-- KNOWN AND ACCEPTED: the allocation basis is TODAY analytics.strategy_nav, not the NAV distribution
-- as it stood on each historical flow_date (the procedure cannot reconstruct a historical capacity
-- table, and state.withdrawal_capacity has no as-of parameter). For a balance-sheet correction this
-- is the defensible reading -- the money is gone NOW, and who bears it is a present-day allocation
-- question -- but it means these four rows do not reproduce what a contemporaneous booking would
-- have produced. Stated here rather than discovered later.
CALL `stock-trading-498512.ops.sp_record_account_fee`(
  CAST(4.51 AS NUMERIC), DATE '2026-05-05',
  'BACKFILL (bigquery/214). May month-start fee, MEASURED: events.decision_log 2026-05-05 fill-capture entry, Anomaly 2, account-level USD Cash 4.51 unaccounted; closed 2026-05-07 as accepted-fee-or-timing-noise. Never booked at the time because 13.D had no fee sink.');

CALL `stock-trading-498512.ops.sp_record_account_fee`(
  CAST(4.97 AS NUMERIC), DATE '2026-06-03',
  'BACKFILL (bigquery/214). June month-start fee, MEASURED-BOUNDED to (4.96, 4.9701] and booked at the top of that interval. No decision-log entry exists and the 2026-06-04 tripwire read PASS because the 13.E cover had already absorbed it: IBKR get_account_trades shows a 0.05 SGOV SELL at 2026-06-03T13:30:04Z (gross 5.0205, commission 0.05036522), a cover, which only fires at settled_cash <= -5, and cover sizing ceil_to_4dp((|cash|+comm)/bid) at bid 100.41 pins |cash| to that interval. The prior evening closed at <= 0.01 and no trade sits between the two.');

CALL `stock-trading-498512.ops.sp_record_account_fee`(
  CAST(4.50 AS NUMERIC), DATE '2026-07-03',
  'BACKFILL (bigquery/214). July month-start fee, MEASURED: events.decision_log cfc1e2c9-0439-4c69-b8f9-762f77d2f260, residual_usd 4.5, prior_cash 78.38 -> post_cash 73.88; ops.alerts cd09790b. Closed at the time as a documentation-only decision-log entry with zero events.cash_flows rows.');

CALL `stock-trading-498512.ops.sp_record_account_fee`(
  CAST(4.448205 AS NUMERIC), DATE '2026-09-03',
  'September month-start fee, MEASURED: ops.alerts b81aab6a. Settled cash 88.8482 -> -4.4594 against -0.011195 expected after the 88.859395 park-sweep BUY, with no trade, no corporate action, no position drift; IBKR 1D TWR implies external flow ~0, so the withdrawal signature is absent.');

-- VERIFICATION (run after apply; read-only).
-- SELECT * FROM `stock-trading-498512.state.cash_flows_backfill_check`;            -- reconciled must be TRUE
-- SELECT * FROM `stock-trading-498512.state.strategy_funds_deficit`;               -- must return ZERO rows
-- SELECT * FROM `stock-trading-498512.state.cash_flow_source_unknown`;             -- must NOT list account_fee rows
-- SELECT flow_date, strategy, amount FROM `stock-trading-498512.events.cash_flows`
--   WHERE source = 'account_fee' ORDER BY flow_date, strategy;                     -- 4 dates, sums 4.51/4.97/4.50/4.448205
-- SELECT breach_soft, breach_hard, capital_base FROM `stock-trading-498512.state.book_drawdown_watch`;
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

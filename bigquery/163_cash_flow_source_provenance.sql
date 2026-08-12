-- bigquery/163_cash_flow_source_provenance.sql (2026-08-10)
-- Project: stock-trading-498512. Apply after bigquery/22_cash_flows.sql (the table),
-- bigquery/98_regime_capital_enablement.sql (the one reader of this column), and
-- bigquery/161_withdrawal_after_the_fact.sql (which introduces source='external_withdrawal').
--
-- NET-NEW plus ONE ALTER. This file defines one new view, registers one alert category, and changes
-- one column DEFAULT. It redefines no existing view or procedure, so no SUPERSEDED marker is owed.
--
-- ============================ THE GAP ============================================================
-- events.cash_flows.source is the provenance tag on every movement of money in this system. Two of
-- its values are pinned precisely in prose -- Operating_Protocols §16 names source='regime_capital_sweep'
-- and source='regime_capital_restore' for the regime-disable/re-enable double-entries -- and
-- bigquery/161 pins source='external_withdrawal' for a real external withdrawal.
--
-- The STRATEGY TERMINATION double-entry has no such pin. It is described in three places -- §16's
-- "Termination write path" bullet, D2's STRATEGY TERMINATIONS step, and AR_orc's m2m-termination
-- handler -- and NONE of the three names a source value. Since no strategy has ever been terminated
-- (verified: events.strategy_lifecycle has zero rows with to_state='TERMINATED'; all five roster
-- strategies are ADOPTED), this has never mattered. It would have mattered the first time SL4/SL5
-- killed a strategy, and it would have failed silently rather than loudly, because of the second half
-- of this gap:
--
-- THE DEFAULT WAS A TRAP. bigquery/22_cash_flows.sql declared source STRING DEFAULT 'D2'. A bare
-- routine id, not a movement-mechanism tag. So a termination double-entry written by AR_orc -- which
-- is not D2 -- with no explicit source would have been silently stamped 'D2': not an error, not a
-- NULL, not anything a reader could distinguish from a genuine D2 write. The money would move
-- correctly and the provenance would be quietly wrong forever, in an append-only ledger with no
-- in-place repair. Worse, 'D2' looks plausible enough that an auditor would likely accept it.
--
-- There is precedent for the class: source='connector-reconciliation' (the 2026-08-05 $9,995.39
-- operator deposit) was coined in-session by the D2a run that recorded it and was never folded back
-- into any documented set. It is a perfectly good value; nothing sanctioned it in advance.
--
-- ============================ THE FIX ============================================================
-- 1. TERMINATION GETS A PINNED VALUE: source='termination_redistribution', specified in
--    Operating_Protocols §16's Termination write path and echoed in D2's and AR_orc's handlers (same
--    commit). ALL N+1 rows of one termination event share it -- the single negative row for the
--    terminated strategy and every positive recipient row, including any newcomer floor-fill rows
--    netted into the same event -- exactly as the regime sweep already does (the 2026-07-19 sweep
--    wrote 1 negative + 4 positive rows, all tagged regime_capital_sweep). Naming follows the
--    movement-mechanism family already in use (snake_case: regime_capital_sweep,
--    regime_capital_restore, external_withdrawal), not the hyphenated one-off/provenance family
--    (backfill-2026-07-03, connector-reconciliation).
--
-- 2. THE DEFAULT NOW SELF-IDENTIFIES: 'D2' -> 'unspecified'. A writer that forgets to tag its row no
--    longer gets a plausible-looking wrong answer; it gets a value the detector below flags on sight.
--    Safe to change: no live row carries 'D2' (all 19 rows are regime_capital_sweep x16,
--    backfill-2026-07-03 x2, connector-reconciliation x1), and every sanctioned write path sets
--    source explicitly, so nothing depends on the old default.
--
-- 3. A DETECTOR: state.cash_flow_source_unknown flags any recent row whose source is outside the
--    sanctioned set, so the next invented-in-session value is caught while it is still one row.
--
-- WHY THE DETECTOR IS A ROLLING WINDOW, NOT ALL-TIME. events.cash_flows is append-only with no
-- sanctioned in-place repair, so a row with a bad source can never be deleted or edited. An all-time
-- detector would therefore fire forever on a row nobody can fix -- a permanently un-clearable alert,
-- which trains everyone to ignore the category. A 14-day window on ingest_ts makes this a TRIPWIRE
-- (the same posture state.append_only_integrity takes with its 2-day JOBS window: "a tripwire, not a
-- forensic log"). The resolution is a code change -- either add the new value to the sanctioned set
-- here if it was legitimate, or write a compensating entry if the flow itself was wrong -- and the
-- alert ages out on its own once the window passes. The all-time audit query is in the verification
-- block at the bottom for when a full survey is actually wanted.
--
-- BLAST RADIUS OF AN UNSANCTIONED VALUE, for severity calibration: exactly one object reads this
-- column anywhere in the repo -- state.regime_capital_debt (bigquery/98:90-101), which filters to
-- source='regime_capital_sweep' AND amount<0 / source='regime_capital_restore' AND amount>0. Every
-- other consumer of events.cash_flows (analytics.strategy_nav, analytics.account_reconciliation,
-- state.book_drawdown_watch's cum_flows, state.cash_flows_backfill_check, and the dbt ports of each)
-- sums amount without ever inspecting source. So a wrong source value is a provenance and
-- audit-trail defect, not a live-money bug -- it cannot misstate NAV, drawdown, or any strategy's
-- booked capital. Hence WARNING, non-latching, and deliberately NOT critical: a critical would enter
-- the blocking_criticals term of bigquery/107's halt_reason CASE and freeze all order staging over a
-- mislabeled ledger row.

-- ===== 1. The self-identifying default =====
ALTER TABLE `stock-trading-498512.events.cash_flows`
  ALTER COLUMN source SET DEFAULT 'unspecified';

-- ===== 2. state.cash_flow_source_unknown =====
-- SUPERSEDED LIVE by bigquery/167_nomadic_capital.sql — current single source of truth for this
-- view (bigquery/166_capital_dormancy_sweep.sql is an intermediate, also-superseded definition — do
-- not stop there; it added capital_dormancy_sweep/capital_dormancy_restore to the sanctioned set
-- below). Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE statement live in isolation. 167 swaps those two tags for nomadic_capital_sweep/
-- nomadic_capital_restore in the sanctioned set.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flow_source_unknown` AS
SELECT
  event_id,
  flow_date,
  flow_type,
  amount,
  strategy,
  source,
  ingest_ts,
  CASE
    WHEN source IS NULL THEN 'source is NULL - every write path must tag its provenance'
    WHEN source = 'unspecified' THEN 'source left at the column DEFAULT - the writer did not tag this row'
    WHEN source = 'D2' THEN 'source is the RETIRED pre-2026-08-10 default - the writer did not tag this row and was stamped D2'
    ELSE 'source is not in the sanctioned set - either a new movement mechanism that must be added to bigquery/163, or a typo'
  END AS finding,
  SUBSTR(COALESCE(note, ''), 0, 300) AS note_preview
FROM `stock-trading-498512.events.cash_flows`
WHERE ingest_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
  -- NULL-SAFETY, load-bearing: `source IS NULL OR ...` must come FIRST and cannot be folded into the
  -- NOT(...) below. SQL three-valued logic makes NOT (NULL IN (...) OR NULL LIKE '...') evaluate to
  -- NULL, not TRUE, and a WHERE clause keeps only TRUE -- so an explicitly NULL-tagged row would be
  -- silently EXCLUDED from this detector, and the CASE branch above that names the NULL case would be
  -- unreachable dead code. That is the exact failure this view exists to prevent, so it must not be
  -- the view's own first bug. Reachable in practice: D2/D2a/AR_orc write ad hoc INSERTs through the
  -- MCP at session time rather than from a checked-in file, and an INSERT that sets source = NULL
  -- explicitly bypasses the column DEFAULT entirely.
  AND (
    source IS NULL
    OR NOT (
    -- Movement-mechanism family (snake_case). Each names HOW the money moved.
    source IN (
      'regime_capital_sweep',        -- §16: regime-router DO-NOT-ACTIVATE sweep-out (bigquery/98)
      'regime_capital_restore',      -- §16: re-enable restore (bigquery/98); no row exists yet
      'external_withdrawal',         -- §13.C: real external withdrawal (bigquery/161, sp_record_withdrawal)
      'termination_redistribution',  -- §16: strategy termination close-out to survivors (this file)
      'connector-reconciliation'     -- historical: the 2026-08-05 operator deposit, coined in-session
    )
    -- Provenance family (hyphenated): DR rebuilds and one-off historical reconstructions.
    OR source LIKE 'backfill-%'
    )
  );

-- ===== 3. Alert-category registration =====
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'cash_flow_source_unknown' AS category,
    FALSE AS latching,
    'Auto-resolves when state.cash_flow_source_unknown returns no rows - which happens either because the value was added to the sanctioned set in a successor to bigquery/163 (the right fix when the mechanism was legitimate) or because the flagged row aged past the 14-day ingest_ts window. The underlying row is never deleted; events.cash_flows is append-only with no in-place repair, so a genuinely WRONG flow is corrected by a compensating entry, never by editing the original.' AS resolve_rule,
    'Provenance integrity on the money ledger. Raised by D3 when a row lands with a source outside the sanctioned set, including the self-identifying DEFAULT value unspecified and the retired D2 default. WARNING by design, not critical: exactly one object (state.regime_capital_debt, bigquery/98) reads this column at all, and every other consumer sums amount without inspecting source, so a bad value is an audit-trail defect and cannot misstate NAV, drawdown, or booked capital. Registered by bigquery/163 after the 2026-08-10 finding that the strategy-termination double-entry named no source anywhere in its three descriptions and would have silently inherited the old D2 default.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The detector is clean against today's ledger (every existing row is sanctioned):
--    SELECT * FROM `stock-trading-498512.state.cash_flow_source_unknown`;
--    -> expect zero rows.
--
-- 2. ALL-TIME audit (the survey the windowed detector deliberately does not do). Expect exactly
--    regime_capital_sweep=16, backfill-2026-07-03=2, connector-reconciliation=1 as of 2026-08-10,
--    and every source in the sanctioned set:
--    SELECT source, COUNT(*) AS n, MIN(flow_date) AS first_seen, MAX(flow_date) AS last_seen
--    FROM `stock-trading-498512.events.cash_flows` GROUP BY source ORDER BY n DESC;
--
-- 3. The new DEFAULT is live and the old one is gone:
--    SELECT column_name, column_default FROM `stock-trading-498512.events.INFORMATION_SCHEMA.COLUMNS`
--    WHERE table_name='cash_flows' AND column_name='source';
--    -> expect column_default = "'unspecified'", NOT "'D2'".
--
-- 4. The alert category is registered exactly once, non-latching:
--    SELECT category, latching FROM `stock-trading-498512.ops.alert_policy`
--    WHERE category='cash_flow_source_unknown';
--    -> expect 1 row, latching=false.
--
-- 5. The one reader of this column is unaffected (its two predicates are unchanged sanctioned values):
--    SELECT * FROM `stock-trading-498512.state.regime_capital_debt` ORDER BY strategy;
--    -> expect A=3888.45, B=4870.19, D=4376.85 outstanding, C/E/F/G/H=0, identical to pre-apply.

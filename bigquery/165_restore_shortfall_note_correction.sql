-- bigquery/165_restore_shortfall_note_correction.sql (2026-08-11)
-- Project: stock-trading-498512. Apply after bigquery/164_capital_utilisation_and_restore_integrity.sql.
--
-- ONE UPDATE, NO NEW OBJECTS. Corrects the `note` and `resolve_rule` prose on the
-- `regime_restore_shortfall` row of ops.alert_policy, which bigquery/164 registered a few hours
-- earlier with a factually wrong claim. Redefines nothing; no SUPERSEDED marker is owed.
--
-- ============================ WHAT WAS WRONG =====================================================
-- bigquery/164 registered this category asserting that a strategy swept while capital-disabled "would
-- come back structurally smaller than it left, permanently - the direct inverse of the
-- reward-winners-via-survivorship objective."
--
-- That is FALSE, and it matters because an alert's `note` is what a future session reads to decide how
-- alarmed to be. Verified against bigquery/98_regime_capital_enablement.sql's actual CTE chain:
-- `restore_candidates` is a STANDING CONDITION -- `enabled_set JOIN debt WHERE outstanding_debt > 0`
-- -- with NO state-transition trigger, NO cooldown, NO once-per-strategy flag and NO
-- "already attempted" marker anywhere in the chain. `state.regime_capital_debt.outstanding_debt` is a
-- live view over append-only events.cash_flows (swept_out_total - restored_total), so a partial
-- payment lowers it without zeroing it, and the very next read re-proposes the residual against
-- whatever donor capacity exists at that moment. The only guard, `WHERE rp.payable >= LEAST(25,
-- rp.outstanding_debt)`, defers a sub-$25 tail until capacity covers it in full -- a threshold, not a
-- block.
--
-- So a partial restore is a DELAY, not a loss. The condition still deserves a warning, but for a
-- different and smaller reason: while it lasts, a re-enabled strategy trades on a fraction of its owed
-- capital, and that is otherwise invisible -- it simply sizes smaller than it should, and nobody would
-- connect that to a sweep weeks earlier. The corrected note says that instead.
--
-- WHY UPDATE RATHER THAN A SECOND INSERT. bigquery/164's registration INSERT is guarded by
-- `WHERE NOT EXISTS (... WHERE e.category = p.category)`, so re-running it can never revise an
-- existing row -- the guard that makes it idempotent also makes it unable to correct itself. An
-- UPDATE is the only way to fix the prose in place. ops.alert_policy is a POLICY REGISTRY, not an
-- audit-truth event stream: it is deliberately absent from state.append_only_integrity's watch-list
-- (which scopes to the `events` dataset only, and which bigquery/162 just extended to cover
-- events.cash_flows), so an in-place UPDATE here is sanctioned and raises no governance violation.
-- The append-only correction convention applies to the LEDGERS, not to a mutable settings row.

UPDATE `stock-trading-498512.ops.alert_policy`
SET
  resolve_rule = 'Auto-resolves when donor capacity again covers the outstanding regime-capital debt - typically when a donor exits a position and its cash returns to available_funds, or when a later session pays down the residual. No manual action is required to recover the capital itself.',
  note = 'A re-enabled strategy would be restored in instalments rather than at once: bigquery/98 RESTORE pays LEAST(outstanding_debt, donor_capacity), and the donors are currently deployed. This is a TEMPORARY DRAG, NOT A LOSS - corrected 2026-08-11, bigquery/165, after bigquery/164 registered this row claiming the strategy would come back permanently smaller. It will not: restore_candidates is a standing condition (any enabled strategy with outstanding_debt > 0, re-evaluated every read, no transition gate, no cooldown, no retry guard), so an unpaid residual is re-proposed automatically as donor capacity recovers, and the 25-dollar-or-full-debt floor only defers a sub-25-dollar tail rather than stranding it. Worth a WARNING anyway because the interim is invisible: an under-capitalised debtor just quietly trades smaller than it should, and nobody would connect that to a sweep weeks earlier. Never critical - it is a capital-efficiency signal, and a critical would enter the blocking_criticals halt term.',
  updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'regime_restore_shortfall';

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Exactly one row updated, and the retracted claim is gone.
--    DO NOT grep for 'permanently smaller' -- the corrected note QUOTES that phrase while retracting
--    it ("...claiming the strategy would come back permanently smaller. It will not: ..."), so a naive
--    search matches the retraction and reports the bug as still present. That exact false positive was
--    hit while writing this file. Test the ASSERTION, not the words:
--    SELECT category, latching,
--           REGEXP_CONTAINS(note, r'TEMPORARY DRAG, NOT A LOSS') AS carries_correction,
--           REGEXP_CONTAINS(note, r'permanently - the direct inverse') AS still_asserts_permanent,
--           REGEXP_CONTAINS(note, r'standing condition')            AS explains_why_not,
--           updated_ts
--    FROM `stock-trading-498512.ops.alert_policy` WHERE category='regime_restore_shortfall';
--    -> expect 1 row, latching=false, carries_correction=TRUE, still_asserts_permanent=FALSE,
--    explains_why_not=TRUE. ('permanently - the direct inverse' is the ORIGINAL claim's distinctive
--    wording from bigquery/164 and appears nowhere in the replacement.)
--
-- 2. The other two categories bigquery/164 registered are untouched:
--    SELECT category, latching, updated_ts FROM `stock-trading-498512.ops.alert_policy`
--    WHERE category IN ('capital_stranded','capital_concentration') ORDER BY category;
--
-- 3. No governance violation was raised by the UPDATE (ops is outside the watched dataset):
--    SELECT * FROM `stock-trading-498512.state.append_only_integrity`;
--    -> expect zero rows.

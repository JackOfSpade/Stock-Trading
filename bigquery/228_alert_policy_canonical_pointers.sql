-- ============================================================================
-- 228 — ops.alert_policy: repoint sixteen prose citations at the file that is
--       actually canonical today. NO NEW OBJECTS, no schema change, no gate change.
--
-- WHY (2026-09-06 interactive triage, found while disposing of the ci_finding alert).
-- ops.alert_policy is the registry a triage session reads to decide how alarmed to be and
-- how an alert is allowed to be closed. Several of its `note` / `resolve_rule` strings
-- locate the live logic by naming a bigquery/NNN file. bigquery/*.sql is APPLY-IN-ORDER
-- and SUPERSEDE-ONLY, so the file that defines an object MOVES over time and the highest
-- numbered definition wins. scripts/check_superseded_markers.py keeps the file-to-file
-- pointers honest, but it parses REPO FILE COMMENTS only -- it is structurally blind to a
-- pointer living in a BigQuery DATA ROW. So this class of citation rots silently, and the
-- session that follows it lands on a definition that is no longer the one running.
--
-- MEASURED 2026-09-06 across all 42 rows: 22 carry at least one pointer presented as the
-- CURRENT location of live logic; 16 of those pointers were stale. Thirteen of the sixteen
-- are one boilerplate clause -- "an open critical sets state.trading_enabled=FALSE
-- (bigquery/107)" -- copied forward into row after row; bigquery/107 stopped being
-- canonical for state.trading_enabled on 2026-08-17 when bigquery/176 superseded it, and
-- every row seeded or hand-revised since then inherited the dead reference. This is one
-- root cause with a fan-out, not sixteen independent mistakes.
--
-- CANONICAL FILE VERIFIED PER OBJECT, not assumed, by the same rule the superseded-marker
-- checker applies (highest-numbered file carrying a CREATE for that object):
--     state.trading_enabled            -> bigquery/176_decouple_embedding_health_from_trading_gate.sql
--     state.append_only_integrity      -> bigquery/162_append_only_watchlist_cash_flows.sql
--     ops.sp_auto_resolve_alerts       -> bigquery/148_audit_2026_08_08_fixes.sql
--     state.catchup_available          -> bigquery/184_inflight_guard_hosted_runs.sql
--     ops.sp_sq_cadence_check          -> bigquery/227_alert_message_stability_ordering.sql
--
-- WHY `REPLACE(...)` AND NOT A FULL `SET note = '<retyped>'`. bigquery/165 (the precedent
-- for correcting an alert_policy row in its own numbered file) retyped the whole string
-- because it was RETRACTING a claim. Here the prose is correct and only a file number is
-- wrong, so a targeted substring swap is the conservative instrument: it cannot mangle the
-- ~2,000 characters of surrounding text that nobody is trying to change, it touches only
-- rows that actually carry the pattern, and re-running it is a no-op once applied. Every
-- statement is scoped by a LIKE on the exact pattern it replaces.
--
-- DELIBERATELY NOT TOUCHED -- three citations that LOOK stale and are not. A pointer is
-- only stale when the prose presents it as where the live logic IS and the content for that
-- object has actually moved. A DATED PROVENANCE claim that is still true must be left alone;
-- rewriting one destroys history and would make this file the defect it is fixing:
--   * phantom_run_completion "the read side (bigquery/175)" -- bigquery/210 supersedes 175
--     for state.run_log_selfheal_candidates, but 210 header explicitly keeps 175 as the
--     canonical home of the read-side-backstop argument this sentence is citing.
--   * instruction_drift "Since 2026-08-19 (bigquery/183) the view separates the two cases
--     explicitly" -- bigquery/201 later added dash normalisation on top, but the dated claim
--     about 183 remains exactly true as written.
--   * regime_restore_shortfall "bigquery/98 RESTORE pays LEAST(outstanding_debt,
--     donor_capacity)" -- the chain moved 98 -> 167 -> 168 -> 215 -> 223, but bigquery/223
--     own header records the formula as DELIBERATELY UNCHANGED, and this sentence was itself
--     written by bigquery/165 as a correction naming where the limb was introduced.
--
-- ONE ROW ALSO GETS A FACTUAL CORRECTION, not just a pointer swap (statement 7).
-- catchup_executor_headroom describes the bigquery/90 in_flight guard gap as an OPEN
-- structural cause, and its own resolve_rule offers "bigquery/90 in_flight join widened to
-- match a hosted routine as_of" as a sufficient reason to resolve. That widening ALREADY
-- LANDED in bigquery/184 on 2026-08-19. Re-verified live 2026-09-06 against
-- state.catchup_available INFORMATION_SCHEMA definition: the in_flight CTE joins on routine
-- alone and carries no run_date term at all. Leaving the row as written would send a future
-- session to re-diagnose a gap that closed three weeks ago -- the same wasted-investigation
-- cost that motivated this whole sweep. The TIMING limb (OPS2 firing ~15 min before the
-- OPS0 sweep, owner console retime under OWNER_ACTIONS.md OPS2-headroom) is untouched and
-- remains the live reason this category exists.
--
-- NOT RAISING, NOT RESOLVING, NOT GATING ANYTHING. No row in ops.alerts is touched, no
-- predicate or severity or latching flag changes, and nothing here can alter which alerts
-- fire. Only documentation prose that humans and triage sessions read.
-- ============================================================================

-- (1) state.trading_enabled boilerplate, parenthesised form -- 11 rows.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note, '(bigquery/107)', '(bigquery/176)'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE note LIKE '%(bigquery/107)%';

-- (2) same boilerplate, filename-qualified form -- queue_venue_claim_unwired.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note, 'bigquery/107_halt_echo_missed_run_gate.sql', 'bigquery/176_decouple_embedding_health_from_trading_gate.sql'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE note LIKE '%bigquery/107_halt_echo_missed_run_gate.sql%';

-- (3) same boilerplate, blocking_criticals phrasing -- nomadic_sweep_blocked.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note, 'bigquery/107 blocking_criticals', 'bigquery/176 blocking_criticals'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE note LIKE '%bigquery/107 blocking_criticals%';

-- (4) state.append_only_integrity -- append_only_violation.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note, '(bigquery/18)', '(bigquery/162)'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE note LIKE '%(bigquery/18)%';

-- (5) ops.sp_auto_resolve_alerts -- catchup_refire_blocked.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note, 'bigquery/94 (sp_auto_resolve_alerts)', 'bigquery/148 (sp_auto_resolve_alerts)'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE note LIKE '%bigquery/94 (sp_auto_resolve_alerts)%';

-- (6) ops.sp_sq_cadence_check live body -- ci_finding. This is the pointer that started the
-- sweep: it named bigquery/172, which bigquery/205 superseded on 2026-08-31, and which
-- bigquery/227 supersedes today. Pointing it at 227 rather than 205 is the whole point --
-- an intermediate file is exactly the dead end this class of pointer keeps creating.
UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = REPLACE(resolve_rule, 'bigquery/172_run_log_unpaired_terminal.sql', 'bigquery/227_alert_message_stability_ordering.sql'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'ci_finding'
  AND resolve_rule LIKE '%bigquery/172_run_log_unpaired_terminal.sql%';

-- (7) catchup_executor_headroom -- pointer swap PLUS the factual correction described above.
UPDATE `stock-trading-498512.ops.alert_policy`
SET note = REPLACE(note,
      'bigquery/90 in_flight guard does not cover the overlap (it joins f.run_date = w.today, while a hosted period-tier routine logs started under period_start per OPS2 hosting requirement (c))',
      'bigquery/90 in_flight guard did not cover the overlap (it joined f.run_date = w.today, while a hosted period-tier routine logs started under period_start per OPS2 hosting requirement (c)) -- that limb was CLOSED 2026-08-19 by bigquery/184_inflight_guard_hosted_runs.sql, which widened the join to routine alone, re-verified live 2026-09-06 (state.catchup_available carries no run_date term), so only the TIMING limb below is still open'),
    resolve_rule = REPLACE(resolve_rule,
      'bigquery/90 in_flight join widened to match a hosted routine as_of',
      'bigquery/90 in_flight join widened to match a hosted routine as_of (THIS REMEDY HAS ALREADY LANDED: bigquery/184_inflight_guard_hosted_runs.sql, 2026-08-19, re-verified live 2026-09-06 -- so this alternative is satisfied, and a fresh firing must be justified on the TIMING limb alone)'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'catchup_executor_headroom';

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this
-- file last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. No CURRENT-claiming pointer at a superseded file survives. Expect 0 rows:
--    SELECT category FROM `stock-trading-498512.ops.alert_policy`
--    WHERE note LIKE '%(bigquery/107)%' OR note LIKE '%bigquery/107_halt_echo%'
--       OR note LIKE '%bigquery/107 blocking_criticals%' OR note LIKE '%(bigquery/18)%'
--       OR note LIKE '%bigquery/94 (sp_auto_resolve_alerts)%'
--       OR resolve_rule LIKE '%bigquery/172_run_log_unpaired_terminal.sql%';
--
-- 2. The replacements actually landed. Expect 13 for the trading-gate clause:
--    SELECT COUNTIF(note LIKE '%bigquery/176%') AS gate_pointer_fixed,
--           COUNTIF(resolve_rule LIKE '%bigquery/227%') AS cadence_pointer_fixed
--    FROM `stock-trading-498512.ops.alert_policy`;
--
-- 3. The three deliberately-untouched provenance citations are still present, unchanged:
--    SELECT COUNTIF(note LIKE '%(bigquery/175)%') AS phantom_kept,
--           COUNTIF(resolve_rule LIKE '%(bigquery/183)%') AS instruction_kept,
--           COUNTIF(note LIKE '%bigquery/98 RESTORE pays%') AS restore_kept
--    FROM `stock-trading-498512.ops.alert_policy`;

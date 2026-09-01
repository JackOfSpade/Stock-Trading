-- 206_staging_halt_prerefresh_disposition.sql (2026-09-01)
--
-- APPLY STATE — COMPLETE. The single view below is live and verified.
-- Applied from an interactive operator session on 2026-09-01. First apply
-- job_jdX1FIl8sdPWC_v-8AsWPypOv-1K; RE-applied as job_dzD4wHmLH6xftGWn74fjpv1iLW9J after the dbt
-- parallel-run caught the range-variable shadowing documented at the `AS v` aliases below (the first
-- body worked live but would have been a latent trap). The live body is the RE-applied one,
-- then read back: gate_alert_action = 'defer_to_craft_site', halt_is_prerefresh_artifact = TRUE,
-- trading_enabled = FALSE (UNCHANGED -- staging still blocked), mechanical_enabled = TRUE,
-- marks_current = engine_current = TRUE, snapshot_stale = FALSE, marks_due_through = 2026-08-31,
-- last_trading_day = 2026-09-01 -- i.e. the exact condition that raised the alert now classifies
-- itself correctly. VERIFIED END-TO-END by `scripts/check_live_sql_parity.py`: 249 objects compared
-- against live BigQuery, **0 mismatched, 0 missing, 0 unchecked** -- and by `scripts/dbt_parity.py`,
-- which row-compares the dbt port against this live view: 85 models compared, 0 skipped, 0 drifted. That checker -- not this comment
-- -- is the authority on repo==live; re-run it rather than trusting this note if the two disagree.
-- Project: stock-trading-498512. Apply any time after 173_freshness_cadence_aware.sql and
-- 176_decouple_embedding_health_from_trading_gate.sql (which SUPERSEDED bigquery/107's three gate
-- views on 2026-08-17 -- 107 is still the header of record for the halt-echo/dedup reasoning, but it is
-- NOT where state.trading_enabled is defined any more; read 176 for the live bodies). PURELY ADDITIVE: creates ONE new view and changes NOTHING
-- that already exists. No gate is redefined, no predicate is loosened, no column is dropped.
--
-- ALSO APPLY dbt/models/state/staging_halt_disposition.sql in the same commit (parallel-run port;
-- scripts/dbt_parity.py row-compares it against this view, and scripts/check_dbt_view_coverage.py
-- otherwise reports the new view as uncovered).
--
-- ===== WHY =====
-- Triage of ops.alerts a5bb4024-887a-4ead-919f-6120088808cc (critical, M4/trading_halted, raised
-- 2026-09-01 15:26 UTC, emailed to the operator): "Order staging blocked: trading is HALTED",
-- halt_reason "state.freshness marks_fresh/engine_fresh not both TRUE".
--
-- NOTHING WAS BROKEN, AND NOTHING WAS BLOCKED. Measured at triage time:
--   state.trading_enabled.trading_enabled            = FALSE  ("...marks_fresh/engine_fresh...")
--   state.trading_enabled_mechanical.trading_enabled = TRUE   (every non-freshness term green)
--   state.freshness.marks_current / engine_current   = TRUE   (marks are as fresh as the SCHEDULE asks)
--   state.freshness.marks_fresh   / engine_fresh     = FALSE
-- M4's own run_log note for 2026-09-01 reaches the same conclusion and records that the halt
-- "blocked NO craft site because none arose (section C zero exits, section H no termination)".
--
-- THE MECHANISM, which is structural and recurs on a fixed schedule:
--   * state.trading_day_today.last_trading_day = MAX(cal_date <= CURRENT_DATE('America/Denver')
--     AND is_trading_day). On a trading day that equals TODAY from DENVER MIDNIGHT (06:00/07:00 UTC),
--     NOT from the close. (bigquery/173's header says "Friday 22:40 UTC (when last_trading_day rolls
--     to Friday)" -- that phrasing is wrong about the roll INSTANT; the conclusion it draws is not.)
--   * marks_fresh/engine_fresh assert coverage of last_trading_day. events.daily_marks and
--     perf.strategy_daily for TODAY are written by D2a, cron 40 22 * * 0,1,2,3,4.
--   * So on EVERY trading day, marks_fresh and engine_fresh are FALSE for the ~16.5h from Denver
--     midnight until D2a completes, and state.trading_enabled is FALSE with exactly this halt_reason.
--
-- For the DAILY tier this is invisible and always was: D2 (23:15 UTC), D3 (00:45 UTC) and AR_orc
-- (00:35 UTC) all run AFTER D2a, and D2a's own gate is state.trading_enabled_MECHANICAL, which omits
-- the freshness terms precisely because they are D2a's own same-run-circular output (bigquery/33).
-- The PERIOD tier does not have that property. Observed start times: M4 ~15:22 UTC, Q4 20:00 UTC --
-- both squarely inside the window, every month and every quarter, forever.
--
-- WHY IT ONLY SURFACED NOW, after two consecutive M4 runs read FALSE. ops.sp_raise_alert_once dedups
-- trading_halted on EXACT message text (bigquery/107 header note (i)), and all seven gate sites emit
-- the same canonical string. When M4 ran 2026-08-03 15:25 UTC, D2a's trading_halted b7457b49 (raised
-- 2026-08-01, resolved 2026-08-04) was still OPEN, so M4's raise was absorbed into it and wrote no
-- row -- M4's August note says "critical trading_halted raised" and it is honest; the call was a
-- no-op. On 2026-09-01 the board happened to carry no open trading_halted, so a fresh row was minted
-- and emailed. The alert is therefore not evidence of a NEW condition; it is the SAME structural
-- condition finally becoming visible. It will now recur on every M4/Q4/A3 run that does not happen
-- to collide with an unrelated open trading_halted.
--
-- WHY THAT IS WORTH FIXING RATHER THAN TOLERATING. trading_halted is CAPITAL-AFFECTING and
-- deliberately human-latching: ops.alert_policy's auto-resolve allowlist is fail-closed and excludes
-- it (Claude_Task_Plan.md shared Observability; drilled monthly by ops.sp_fire_drill_alert_latch).
-- So every occurrence costs a human UPDATE ops.alerts and an operator email, for a condition that is
-- 100% expected and in which nothing was late and nothing was blocked. That is precisely the
-- "dead-man's switch that cries wolf" failure bigquery/173's own header argues against, one tier up.
--
-- ===== WHAT THIS CHANGES, AND WHAT IT DELIBERATELY DOES NOT =====
-- It does NOT touch the GATE. state.trading_enabled stays byte-identical and stays exactly as strict:
-- FALSE all day until D2a lands. No routine may stage an order in that window, before or after this
-- change. bigquery/173's header forbids loosening the order-staging gate "by one inch" and this
-- change honours that literally -- it adds a READ-ONLY classification of a halt that has already
-- been decided, and the classification is consumed only to choose an ALERT SEVERITY, never to decide
-- whether an order may be staged.
--
-- The distinction it makes machine-readable is between:
--   (a) the gate is FALSE because today's post-close refresh has not happened yet -- an ARTIFACT of
--       reading the gate before D2a, in which nothing is late and no dead-man's switch has tripped; and
--   (b) the gate is FALSE for any other reason, or the marks are GENUINELY late -- unchanged, critical.
--
-- ===== RELATION TO ops.alerts 06e84b38 (W1, weekend_freshness_gate_asymmetry), WHICH SAYS =====
-- ===== "BOTH SUGGESTED FIXES REJECTED. Do not re-propose either." -- THIS IS NEITHER OF THEM =====
-- That 2026-08-31 adjudication is the closest prior art and it must be honoured, so state plainly what
-- it rejected and why this is a different object:
--   REJECTED (a): repoint the GATE at marks_current/engine_current. Rejected because it WEAKENS the
--     gate -- from Friday close to Sunday ~22:46 UTC an entire COMPLETED session is absent from
--     events.daily_marks while marks_current reads TRUE, TRUE because the schedule says nothing is due
--     rather than because the data is current.
--   REJECTED (b): an is_trading_day guard on the freshness term. Rejected because it disables the term
--     on SUNDAY, the evening D2 stages the week's orders.
--   THIS CHANGE: neither. state.trading_enabled is not edited, not repointed, not guarded, and not read
--     any differently by any gate. It stays FALSE for exactly as long, on exactly the same predicate.
--     The ONLY consumer of halt_is_prerefresh_artifact is the choice of ALERT SEVERITY at a gate step.
--     Rejection (a)'s concrete counter-scenario is therefore not reachable through this view: even when
--     marks_current is TRUE across that weekend gap, staging is still blocked by marks_fresh, because
--     the gate never sees this view at all.
-- That same note also records, as "THE REAL ADJACENT DEFECT", precisely the mechanism this file
-- addresses -- "last_trading_day includes TODAY from Denver-midnight before today's session has closed,
-- so marks_fresh is unsatisfiable ~16-17h EVERY Mon-Thu too" -- and says fixing THAT needs "a third
-- reference date (last trading day whose regular session has actually closed), which is a real
-- capital-gate design change and is owner/W5 territory". Agreed, and NOT attempted here: no third
-- reference date is introduced, no gate is redesigned. This file takes the strictly smaller, wholly
-- reversible step of making the ALERT proportionate while that design question stays open for the owner.
--
-- ===== WHY THE PREDICATE IS SHAPED THIS WAY (all five terms are load-bearing) =====
-- halt_is_prerefresh_artifact is the AND of five conditions, and it is built by REUSING canonical
-- views rather than by re-deriving bigquery/176's eight-term chain. Re-deriving it here would create
-- a second hand-kept copy of a load-bearing capital gate that must be updated in lockstep forever --
-- the exact drift class bigquery/107's own header, and RUNBOOK Section 22, warn about.
--
--   1. NOT te.trading_enabled
--        There is actually a halt to classify. If the gate is TRUE this column is FALSE, not NULL.
--   2. te.halt_reason = 'state.freshness marks_fresh/engine_fresh not both TRUE'
--        halt_reason's CASE is priority-ordered with halt_all FIRST and freshness SECOND, so this
--        string proves halt_all is green and freshness is the top failing term. It does NOT by
--        itself prove the later terms are green -- which is what 3 and 4 are for.
--   3. tm.trading_enabled  (state.trading_enabled_mechanical)
--        The mechanical gate is bigquery/176's same chain MINUS marks_fresh/engine_fresh. TRUE
--        therefore proves halt_all, embeddings_healthy, blocking_criticals = 0, position_drift and
--        breach_hard are ALL green, without transcribing any of them.
--   4. NOT snapshot_stale
--        state.trading_enabled_mechanical omits this term as well as the freshness pair (compare its
--        SELECT list against state.trading_enabled's in bigquery/176 -- mechanical's dd CTE selects
--        only breach_hard and drawdown_from_peak, while trading_enabled's selects snapshot_stale too and
--        ANDs NOT COALESCE(dd.snapshot_stale, FALSE) into the verdict. VERIFIED against 176, not 107). Term 3 alone would therefore let a genuine
--        ops.account_snapshot staleness halt be misclassified as a pre-refresh artifact. Stated
--        explicitly, and COALESCE'd to TRUE (= not an artifact) so a NULL fails CLOSED.
--   5. f.marks_current AND f.engine_current
--        The teeth. These are bigquery/173's cadence-aware pair, measured against marks_due_through
--        -- the last trading day a SCHEDULED D2a slot has already had the opportunity to ingest.
--        If D2a dies, marks_due_through keeps advancing (it is SCHEDULE-derived, never run-derived,
--        deliberately so per bigquery/173), these go FALSE, and the artifact classification
--        disappears -- so a genuinely dead D2a still produces a critical, within ~6h, exactly as
--        today. This is what makes the change a re-CLASSIFICATION and not a suppression.
--
-- Every COALESCE below resolves toward "NOT an artifact", so any NULL anywhere in the chain yields
-- halt_is_prerefresh_artifact = FALSE and the caller raises the critical. Fail-closed throughout.
--
-- ===== HOW CALLERS USE IT =====
-- The TRADING-ENABLE GATE steps in Claude_Task_Plan.md are
-- updated in the same commit to read gate_alert_action instead of unconditionally raising critical:
--   'raise_critical' -> raise trading_halted critical at the gate, exactly as before.
--   'defer_to_craft_site' -> raise NOTHING at the gate; carry the FALSE verdict forward unchanged
--        (staging stays blocked); and raise the critical only if a craft site is actually declined,
--        which is the moment real work is lost. Record the disposition in the run_log note either way.
-- IN SCOPE: D2, D3, M4, Q4, A3. OUT OF SCOPE, deliberately: D2a, which reads
-- state.trading_enabled_MECHANICAL -- that view carries no marks_fresh/engine_fresh term at all, so a
-- pre-refresh halt can never be its halt reason and this rule is inert there; and AR_orc, whose raise
-- already sits AT a declined craft site, which is exactly where this rule says the critical belongs.
-- Q4 and A3 craft NO orders by construction (their own gate paragraphs say so), so for them
-- 'defer_to_craft_site' resolves to raising nothing at all -- which is the largest single win here:
-- today they would latch a capital-class human-only critical for a halt that blocks nothing they do.
-- Net effect on the daily tier: none -- D2/D3 run after D2a, so they see marks_fresh = TRUE
-- and gate_alert_action is never 'defer_to_craft_site' on a normal run. It DOES cover the
-- 2026-08-24 D2 catch-up case (ops.alerts 0efa2ef3, resolved as "ran the gate check at the wrong
-- time"), which is the same artifact reached from the daily tier.

CREATE OR REPLACE VIEW `stock-trading-498512.state.staging_halt_disposition` AS
WITH
-- EXPLICIT range-variable aliases (`AS v`) are REQUIRED, not style. The implicit alias of a table
-- reference is its LAST path part, so an unaliased `FROM ...state.trading_enabled` introduces a range
-- variable literally named `trading_enabled` that SHADOWS the view's same-named BOOL column: the bare
-- `SELECT trading_enabled` then yields the whole ROW STRUCT, and the artifact predicate below dies with
-- "No matching signature for COALESCE(STRUCT<trading_enabled BOOL, halt_reason STRING>, BOOL)". Caught
-- 2026-09-01 by the dbt parallel-run (scripts/dbt_parity.py), which quotes the path as
-- `proj`.`state`.`trading_enabled` and hit the shadowing where the single-backtick form here happened
-- not to. Do NOT drop these aliases in either copy.
te AS (SELECT v.trading_enabled, v.halt_reason FROM `stock-trading-498512.state.trading_enabled` AS v),
tm AS (SELECT v.trading_enabled AS mechanical_enabled FROM `stock-trading-498512.state.trading_enabled_mechanical` AS v),
f  AS (SELECT marks_fresh, engine_fresh, marks_current, engine_current,
              last_mark_date, engine_through, marks_due_through, last_trading_day
       FROM `stock-trading-498512.state.freshness`),
dd AS (SELECT snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`),
d  AS (
  SELECT
    te.trading_enabled,
    te.halt_reason,
    tm.mechanical_enabled,
    f.marks_fresh, f.engine_fresh, f.marks_current, f.engine_current,
    f.last_mark_date, f.engine_through, f.marks_due_through, f.last_trading_day,
    COALESCE(dd.snapshot_stale, TRUE) AS snapshot_stale,
    -- The five load-bearing terms, in the order the header documents them.
    (NOT COALESCE(te.trading_enabled, TRUE)
     AND te.halt_reason = 'state.freshness marks_fresh/engine_fresh not both TRUE'
     AND COALESCE(tm.mechanical_enabled, FALSE)
     AND NOT COALESCE(dd.snapshot_stale, TRUE)
     AND COALESCE(f.marks_current, FALSE)
     AND COALESCE(f.engine_current, FALSE)) AS halt_is_prerefresh_artifact
  FROM te, tm, f, dd
)
SELECT
  d.trading_enabled,
  d.halt_reason,
  d.halt_is_prerefresh_artifact,
  -- What a TRADING-ENABLE GATE step should do about the ALERT. The gate VERDICT is d.trading_enabled
  -- and is unaffected by this column: 'defer_to_craft_site' still means staging is BLOCKED.
  CASE
    WHEN COALESCE(d.trading_enabled, FALSE) THEN 'none'
    WHEN d.halt_is_prerefresh_artifact THEN 'defer_to_craft_site'
    ELSE 'raise_critical'
  END AS gate_alert_action,
  -- Prose for the run_log note / decision_log / alert payload, so every caller words it identically.
  CASE
    WHEN COALESCE(d.trading_enabled, FALSE) THEN NULL
    WHEN d.halt_is_prerefresh_artifact THEN FORMAT(
      'PRE-REFRESH ARTIFACT, not a fault: marks/engine cover %s = marks_due_through, the last '
      || 'trading day a scheduled D2a slot has had the opportunity to ingest; they do not yet cover '
      || 'last_trading_day %s because that session has not closed and D2a (40 22 * * 0,1,2,3,4) has '
      || 'not run. Every other gate term is green. Staging stays blocked; no critical raised unless a '
      || 'craft site is actually declined. See bigquery/206.',
      CAST(d.marks_due_through AS STRING), CAST(d.last_trading_day AS STRING))
    ELSE d.halt_reason
  END AS disposition_note,
  d.mechanical_enabled,
  d.marks_fresh, d.engine_fresh, d.marks_current, d.engine_current, d.snapshot_stale,
  d.last_mark_date, d.engine_through, d.marks_due_through, d.last_trading_day,
  CURRENT_TIMESTAMP() AS checked_at
FROM d;

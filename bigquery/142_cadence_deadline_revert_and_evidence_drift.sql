-- 142_cadence_deadline_revert_and_evidence_drift.sql (2026-08-06)
-- Project: stock-trading-498512. Apply AFTER bigquery/129_cadence_watch_deadline_autotune.sql (state.
-- cadence_watch), bigquery/132_queue_driven_silence_watch.sql (ops.sp_sq_cadence_check),
-- bigquery/37_self_improvement_autonomy.sql (ops.process_reliability_observations /
-- ops.process_constant_change_log), bigquery/89_scorecard_midnight_retry.sql
-- (analytics.routine_health_scorecard), bigquery/72_constant_tuning_oos_watch.sql
-- (state.process_constant_oos_watch) and bigquery/139_append_only_violation_alert_class.sql
-- (ops.alert_policy).
--
-- ============================ WHY ============================
-- On 2026-08-03 the W5 process_reliability self-tuning loop autotuned cadence_watch_deadline_local from
-- 21:00 to 21:45 America/Denver for D1/D2/D3 (bigquery/129), on a 3-consecutive-cycle deadline-threat
-- streak (threat_pattern = min_n_met AND p90 completion-minute-of-day within about 90 minutes of the
-- deadline). On 2026-08-04, commit 0b9fd49 fixed analytics.routine_health_scorecard (bigquery/89) to
-- EXCLUDE marker-backfilled rows from its percentiles, retroactively, at the reader. A backfilled row
-- carries log_ts equal to backfill time (roughly 22:15 MT), not completion time, so those rows
-- manufactured a fake late tail wherever a routine had been backfilled.
--
-- Under the CORRECTED formula, the three p90s that justified the D1 change were 1030 / 993 / 1006
-- minutes-of-day (16:30 / 16:33 / 16:46 MT, for cycles 2026-07-19 / 07-26 / 08-03) — nowhere near the
-- +/-90-minute band around either 21:00 (minute 1260) or 21:45 (minute 1305). The entire evidence trail
-- behind the D1 change was an artifact of the backfilled-row bug; the 21:45 autotune was never actually
-- supported. The p90s justifying D2 and D3 were genuine: D2 recomputes to 1309 / 1266 / 1266 and D3 to
-- 1193 / 1193 / 1193 — both still inside the band at BOTH 21:00 (1260) and 21:45 (1305), so the revert
-- below costs D2 and D3 nothing, and the autotune never actually helped either routine (the honest p90s
-- were inside the band before AND after the deadline moved). The owner has approved reverting
-- cadence_watch_deadline_local to 21:00 for all three routines AND closing the structural gap that let a
-- manufactured evidence trail justify a live change with nothing checking it against a later
-- metric-formula correction.
--
-- ============================ THE STRUCTURAL GAP ============================
-- state.process_constant_oos_watch (bigquery/72) is the existing fail-safe for this loop, and it is
-- necessary but not sufficient: degraded_revert fires when the SAME (routine, deadline_key) shows
-- threat_pattern=TRUE on >=2 of the 3 W5 cycles AFTER a change — i.e. it detects that the change did not
-- work. It structurally CANNOT detect that the evidence used to justify the change was never real,
-- because it only ever looks forward from change_ts, never back at the observations that triggered the
-- change in the first place. state.process_constant_evidence_drift (STATEMENT 2 below) is that missing
-- backward-looking check: it re-validates each APPLIED autotune justifying observations against the
-- CURRENT, corrected analytics.routine_health_scorecard predicate set.
--
-- ============================ POINT-IN-TIME RECONSTRUCTION (already investigated, build on this) =======
-- analytics.routine_health_scorecard has NO upper time bound on its run_date window (bigquery/89:68 —
-- `WHERE run_date >= DATE_SUB(CURRENT_DATE(...), INTERVAL 90 DAY)`), so an observation W5 wrote CANNOT be
-- reproduced by naively re-querying the view later: rows that landed in ops.run_log AFTER the observation
-- was written are silently included by any fresh 90-day query run today. This is documented, expected
-- behavior of that view, not a bug to fix here. A forensic pass confirmed all four routines 2026-08-03
-- observations reproduce EXACTLY (n, p50 and p90, 12 of 12) when, and only when, the reconstruction is
-- bounded by `log_ts < observed_ts` IN ADDITION to the usual `run_date` window — the log_ts bound is what
-- isolates the FORMULA having changed (what this file exists to detect) from NEW DATA having since landed
-- (a confound the bare run_date window alone does not exclude). Re-verified live during the construction
-- of this file: read-only-querying state.process_constant_evidence_drift reproduced the D1 1030/993/1006
-- figures above exactly. STATEMENT 2 below bounds every per-observation recompute at that observation OWN
-- observed_ts for this exact reason.
--
-- ============================ OPS0 WINTER HAZARD (why 21:45 was never safe to keep) ====================
-- OPS0 fires at 04:30 UTC. bigquery/129 own header documents the 05:15 UTC cadence_check crossing 23:15
-- MDT / 22:15 MST. OPS0 also performs a same-night auto-catchup sweep (STEP 3, Claude_Task_Plan.md) keyed
-- off state.cadence_watch.needs_attention, evaluated at that same 04:30 UTC run — 22:30 MDT today, but
-- 21:30 MST once clocks fall back. Under MDT (the DST state in force today, 2026-08-06), that dispatch
-- lands at 22:30, which is after BOTH candidate deadlines (21:00 and 21:45), so this is a non-issue right
-- now. Under MST (roughly 2026-11-01 through the
-- following spring), 04:30 UTC is 21:30 MST — BEFORE a 21:45 deadline: a genuinely missed D1/D3 run would
-- read needs_attention=FALSE at that 21:30 MST catchup check (the deadline has not passed yet in the
-- views own terms) and lose that night auto-catchup window entirely, even though cadence_check would
-- still correctly alarm 45 minutes later at 22:15 MST. This hazard is DORMANT today under MDT and would
-- only go live around 2026-11-01 — reverting to 21:00 removes it outright, since 21:00 sits comfortably
-- before 21:30 in either DST state.
--
-- ============================ not_already_changed IS ALREADY LATCHED ====================================
-- (this revert disables nothing still live in the W5 loop). state.process_reliability_readiness.
-- not_already_changed (bigquery/37:88-89) keys ONLY on the EXISTENCE of an
-- ops.process_constant_change_log row for (routine, deadline_key) — never on the deadline VALUE. The
-- original 2026-08-03 change-log rows for D1/D2/D3 x cadence_watch_deadline_local already exist (see the
-- MANUAL APPLY STEP below), so ready_for_change already reads FALSE for all three today regardless of
-- this file. Reverting the VIEW TIME literal back to 21:00 therefore does not re-arm the W5
-- process_reliability loop to fire again for these three routines — it only fixes the live deadline.
--
-- ============================ MANUAL ONE-TIME APPLY STEP (NOT one of this file executable statements) ===
-- ops.process_constant_change_log is a runtime append-only log — the loop own idempotency substrate —
-- and re-applying this .sql file must NEVER double-INSERT a revert marker, so the REVERT rows below are
-- deliberately NOT one of this file four CREATE/MERGE statements. Run this INSERT ONCE by hand, any time
-- after Statement 1 is live, substituting the actual landing commit SHA for <git_commit>:
--
--   INSERT INTO `stock-trading-498512.ops.process_constant_change_log`
--     (change_key, routine, deadline_key, old_value, new_value, git_commit, note)
--   VALUES
--     ('D1:cadence_watch_deadline_local:21:00->21:45:REVERT', 'D1', 'cadence_watch_deadline_local',
--      '21:45', '21:00', '<git_commit>',
--      'Manual revert, owner-approved 2026-08-06. state.process_constant_evidence_drift flags D1 '
--      || 'evidence_invalidated=TRUE: the three p90s that justified the change (1279/1275/1279 '
--      || 'persisted) were manufactured by marker-backfilled ops.run_log rows that bigquery/89 '
--      || '(2026-08-04) later excluded; recomputed honest p90s are 1030/993/1006, nowhere near the '
--      || 'deadline band. See bigquery/142.'),
--     ('D2:cadence_watch_deadline_local:21:00->21:45:REVERT', 'D2', 'cadence_watch_deadline_local',
--      '21:45', '21:00', '<git_commit>',
--      'Manual revert, owner-approved 2026-08-06, applied alongside D1/D3 because '
--      || 'cadence_watch_deadline_local is one shared constant, not set per routine. The evidence for '
--      || 'D2 was genuine (recomputed p90 1309/1266/1266, inside the band at both 21:00 and 21:45) — '
--      || 'state.process_constant_evidence_drift reads evidence_invalidated=FALSE for D2; the revert '
--      || 'costs D2 nothing, since it sat inside the band before AND after the deadline moved. See '
--      || 'bigquery/142.'),
--     ('D3:cadence_watch_deadline_local:21:00->21:45:REVERT', 'D3', 'cadence_watch_deadline_local',
--      '21:45', '21:00', '<git_commit>',
--      'Manual revert, owner-approved 2026-08-06, applied alongside D1/D2 for the same shared-constant '
--      || 'reason. The evidence for D3 was genuine (recomputed p90 1193/1193/1193, 67 minutes inside '
--      || 'the band at 21:00) — state.process_constant_evidence_drift reads evidence_invalidated=FALSE '
--      || 'for D3. See bigquery/142.');
--
-- EFFECT ON bigquery/72 (documented, intentional): state.process_constant_oos_watch.degraded_revert
-- (bigquery/72:27-32) is gated by `NOT EXISTS (... r.change_key = CONCAT(lc.change_key, ':REVERT'))`, so
-- once the three rows above land, degraded_revert reads FALSE for these change_keys from then on — which
-- is CORRECT: after a manual revert there is nothing left for the bigquery/72 auto-revert fail-safe to
-- undo. The same ':REVERT' rows also retire the change from STATEMENT 2 own `changes` CTE below (see that
-- statement comment) so the process_constant_evidence_invalidated alert stops re-firing once the revert
-- is recorded.
--
-- ============================ APPLY ORDER (read in full — two separate ordering traps) ================
-- TRAP 1, WITHIN THIS FILE: STATEMENT 2 MUST BE LIVE BEFORE STATEMENT 3. Statement 3 body contains an
-- unguarded `IF EXISTS (SELECT 1 FROM state.process_constant_evidence_drift ...)`, and BigQuery does NOT
-- validate a procedure referenced objects at CREATE time — it binds lazily at CALL time (the same
-- lazy-binding bigquery/89 own header documents for a view). So a live v12 procedure created before
-- Statement 2 would not fail on creation; it would fail on the NEXT nightly cadence_check run, erroring
-- out mid-body with `Not found: state.process_constant_evidence_drift` and aborting every check placed
-- AFTER that point — scheduled_query_stale, probe_funding_stalled, cash_flows_backfill_broken,
-- ci_finding, ci_findings_bridge_stale, constant_tuning_loop_heartbeat_missing and the park_allocator
-- daily-heartbeat check would all silently stop firing until Statement 2 landed. Applying this file top
-- to bottom is therefore correct and safe (Statement 2 is above Statement 3); the hazard is real only for
-- a PARTIAL or reordered apply. Belt-and-braces, the Statement 3 block is additionally wrapped in the
-- same BEGIN ... EXCEPTION WHEN ERROR THEN ... END best-effort guard this procedure already uses for
-- sp_backfill_run_log_from_markers and sp_auto_resolve_alerts, so a missing or broken dependency degrades
-- to one skipped check rather than taking down the whole fleet dead-man switch.
--
-- TRAP 2, ACROSS FILES: the bigquery/63 registry MERGE is a SINGLE statement carrying ALL TWELVE rows,
-- and TWO of them were bumped on 2026-08-06 by TWO DIFFERENT new files — integrity_check v2->v3 by
-- bigquery/141_append_only_halt_scope.sql, and cadence_check v11->v12 by THIS file. There is no way to
-- apply "just this file registry row". Running that MERGE while only ONE of the two procedures is live
-- sets a v3/v12 expectation against a still-live v2/v11 body for the OTHER one, raising a
-- scheduled_query_version_drift WARNING that CANNOT auto-resolve (that category has no ops.alert_policy
-- row) — the same registry-lag bug bigquery/63 own git_note already documents twice. Reading either
-- file APPLY-ORDER note in isolation and stopping there is exactly how that happens.
--
-- CORRECT WHOLE-CHANGESET SEQUENCE (both files land together, registry LAST):
--   1. bigquery/141 in full — the haltable view, THEN ops.sp_sq_integrity_check v3.
--   2. THIS file Statements 1, 2, 3, 4 in written order.
--   3. ONLY NOW the bigquery/63 MERGE — at this point both v3 and v12 bodies are live, so the MERGE
--      makes expected match reported for every row and no drift is raised.
--   4. Verify: state.scheduled_query_version_drift must read 0 drift across all 12 rows.
--   5. The MANUAL ONE-TIME APPLY STEP above (the ':REVERT' rows) — any time after Statement 1 is live.
-- If only part of this can land in a given pass, always apply PROCEDURES first and the registry MERGE
-- last; a live-ahead-of-registry body is the self-healing direction, a registry-ahead-of-body is not.

-- ===== state.cadence_watch (STATEMENT 1 — reverts the bigquery/129 autotune; supersedes 129; daily
-- tier) — copied VERBATIM from bigquery/129_cadence_watch_deadline_autotune.sql, changing ONLY the TIME
-- literal (21:45:00 -> 21:00:00) and this adjacent comment. Everything else, including the
-- never-completed fix from bigquery/113 that 129 already carried forward, is unchanged byte-for-byte. =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_watch` AS
WITH watch AS (
  SELECT
    e.routine,
    e.schedule,
    e.today,
    -- monitored = has EVER completed (unchanged column, no rolling window -- bigquery/48's fix stays).
    EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
           WHERE r.routine = e.routine AND r.status = 'completed') AS monitored,
    EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
           WHERE r.routine = e.routine AND r.status = 'completed'
             AND r.run_date = e.today) AS ran_completed_today
  FROM `stock-trading-498512.state.cadence_expected_today` e
)
SELECT
  e.routine,
  e.schedule,
  e.today,
  e.monitored,
  e.ran_completed_today,
  -- `monitored` precondition stays REMOVED from the alarm predicate (bigquery/113's fix).
  -- CHANGED HERE (bigquery/142, 2026-08-06): TIME '21:45:00' -> TIME '21:00:00' — REVERT of the 129
  -- autotune. The evidence that justified the D1 change was manufactured by a backfilled-row artifact
  -- that bigquery/89 later excluded (see the header of bigquery/142 for the full account); the evidence
  -- for D2 and D3 was genuine, but cadence_watch_deadline_local is one shared constant across all three
  -- routines, not set per routine, so all three revert together.
  -- 'daily_sun_thu' ADDED 2026-08-08 (daily-tier Fri/Sat consolidation onto Sunday, ops/cadence.yaml):
  -- D1/D2a/D2/D3/OPS0/OPS1/OPS2/SL3 moved off daily_trading/daily_all onto this new class. A genuinely
  -- missed Sun-Thu run MUST still raise a CRITICAL through this same alarm predicate -- omitting the
  -- new class here would have silently disarmed needs_attention for the entire daily tier the moment
  -- ops/cadence.yaml's monitor_class fields changed, even though state.cadence_expected_today (12_
  -- cadence_monitor.sql) already expects these routines correctly under the new class.
  (e.schedule IN ('daily_trading','daily_all','daily_sun_thu')
   AND NOT e.ran_completed_today
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM watch e;

-- ===== state.process_constant_evidence_drift (STATEMENT 2 — NEW) =====
-- Re-validates an ALREADY-APPLIED process_constant autotune (ops.process_constant_change_log) against the
-- metric view its justification depended on (analytics.routine_health_scorecard, bigquery/89), recomputed
-- under the CURRENT predicate set and bounded at each justifying observation own observed_ts — see this
-- file header for the point-in-time reconstruction property that bound depends on, and for why
-- state.process_constant_oos_watch (bigquery/72) cannot see this failure mode: that view only ever looks
-- forward from change_ts, never back at the observations that triggered the change.
--
-- WINDOWING mirrors bigquery/37_self_improvement_autonomy.sql state.process_reliability_readiness
-- `ranked`/`trailing3` CTEs (ROW_NUMBER() OVER (PARTITION BY routine, deadline_key ORDER BY cycle_date
-- DESC), rn <= 3) — partitioned here by change_id rather than the bare (routine, deadline_key) pair,
-- which is equivalent for every change on record today (one non-REVERT change per (routine,
-- deadline_key) so far) and correctly generalizes to a (routine, deadline_key) pair autotuned more than
-- once in the future — and ordered by observed_ts (the finer-grained TIMESTAMP the design language "most
-- recent 3 as of the change" names) rather than cycle_date, which is DATE-grained and could tie within
-- one W5 cycle.
CREATE OR REPLACE VIEW `stock-trading-498512.state.process_constant_evidence_drift` AS
WITH changes AS (
  -- Each row here is one APPLIED autotune. The NOT EXISTS guard excludes a change that already carries
  -- its own ':REVERT' sibling row: once reverted, the constant is back to old_value and the change is no
  -- longer LIVE — it is history, not a candidate for ongoing re-validation. Without this guard,
  -- evidence_invalidated would be a PERMANENT fact about a given change_id (every input below is bound
  -- at each observation own observed_ts, so it can never flip to FALSE on its own), and Statement 3
  -- alert would re-raise the identical message every night, forever, even after the documented MANUAL
  -- ONE-TIME APPLY STEP in this file header records the revert. Mirrors
  -- state.process_constant_oos_watch (bigquery/72_constant_tuning_oos_watch.sql) own
  -- `NOT EXISTS (... = CONCAT(change_key, ':REVERT'))` guard, on the identical table, for the identical
  -- reason.
  SELECT c.change_id, c.change_ts, c.change_key, c.routine, c.deadline_key, c.old_value, c.new_value
  FROM `stock-trading-498512.ops.process_constant_change_log` c
  WHERE NOT ENDS_WITH(c.change_key, ':REVERT')
    AND NOT EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.process_constant_change_log` r
      WHERE r.change_key = CONCAT(c.change_key, ':REVERT')
    )
),
ranked AS (
  SELECT
    c.change_id, c.change_key, c.change_ts, c.routine, c.deadline_key, c.old_value, c.new_value,
    o.observation_id, o.observed_ts, o.cycle_date,
    o.p90_completion_minute_of_day AS persisted_p90,
    o.threat_pattern AS persisted_threat,
    ROW_NUMBER() OVER (PARTITION BY c.change_id ORDER BY o.observed_ts DESC) AS rn
  FROM changes c
  JOIN `stock-trading-498512.ops.process_reliability_observations` o
    ON o.routine = c.routine AND o.deadline_key = c.deadline_key AND o.observed_ts <= c.change_ts
),
top3 AS (
  -- The <=3 most-recent-as-of-the-change observations per applied change — mirrors bigquery/37 own
  -- `trailing3` (WHERE rn <= 3 over `ranked`).
  SELECT * FROM ranked WHERE rn <= 3
),
recomputed AS (
  -- Per-observation RECOMPUTE of p90 from ops.run_log, using bigquery/89 CURRENT predicate set
  -- (is_backfilled exclusion via the anchored-prefix REGEXP_CONTAINS, midnight-safe DATETIME_DIFF)
  -- verbatim, bounded TWICE: run_date within the observation own 90-day window ending at its cycle_date
  -- (not CURRENT_DATE — bigquery/89:68 has no upper bound, exactly why a naive re-query today would NOT
  -- reproduce a past observation), AND log_ts < the observation own observed_ts — the point-in-time bound
  -- that isolates the FORMULA having changed from NEW DATA having since landed (a bare cycle_date bound
  -- alone would not exclude a row logged after observed_ts but still dated on/before cycle_date). See
  -- this file header for the forensic verification of this reconstruction property.
  SELECT
    t.change_id, t.observation_id,
    APPROX_QUANTILES(
      IF(r.status = 'completed'
         AND NOT REGEXP_CONTAINS(COALESCE(r.note, ''), r'(?i)^(auto-)?backfilled'),
         DATETIME_DIFF(DATETIME(r.log_ts, 'America/Denver'), DATETIME(r.run_date), MINUTE),
         NULL), 100)[OFFSET(90)] AS recomputed_p90,
    COUNT(*) AS recomputed_n_log_rows_90d
  FROM top3 t
  JOIN `stock-trading-498512.ops.run_log` r
    ON r.routine = t.routine
   AND r.run_date BETWEEN DATE_SUB(t.cycle_date, INTERVAL 90 DAY) AND t.cycle_date
   AND r.log_ts < t.observed_ts
  GROUP BY t.change_id, t.observation_id
),
parsed AS (
  SELECT
    t.change_id, t.observation_id, t.change_key, t.change_ts, t.routine, t.deadline_key,
    t.old_value, t.new_value, t.cycle_date, t.persisted_p90, t.persisted_threat,
    rc.recomputed_p90, COALESCE(rc.recomputed_n_log_rows_90d, 0) AS recomputed_n_log_rows_90d,
    -- deadline_minute_of_day is the deadline IN FORCE when the evidence was gathered — old_value
    -- ("HH:MM") parsed to minutes-since-midnight, the same units as p90_completion_minute_of_day.
    -- VALIDATED, not merely SAFE_CAST: a malformed-but-numeric value like '25:99' would otherwise parse
    -- silently to 1599 (a nonsensical clock time) and be compared against the band as if real. The regex
    -- pins hours 0-23 and minutes 00-59; anything else (a non-time constant, a NULL, '9:5') yields NULL
    -- and is treated below as UNRECOMPUTABLE — an explicit "cannot adjudicate", never a silent FALSE.
    IF(REGEXP_CONTAINS(t.old_value, r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$'),
       SAFE_CAST(SPLIT(t.old_value, ':')[SAFE_OFFSET(0)] AS INT64) * 60
         + SAFE_CAST(SPLIT(t.old_value, ':')[SAFE_OFFSET(1)] AS INT64),
       NULL) AS deadline_minute_of_day
  FROM top3 t
  LEFT JOIN recomputed rc USING (change_id, observation_id)
),
scored AS (
  SELECT
    *,
    -- UNRECOMPUTABLE vs NOT-A-THREAT — these must never be conflated. recomputed_p90 IS NULL means no
    -- ops.run_log row survived the run_date/log_ts bounds, so the statistic could not be rebuilt at all;
    -- an unparseable deadline means there is nothing to compare it against. Either way we CANNOT say
    -- whether the original evidence held. Collapsing that into recomputed_threat=FALSE (as a bare
    -- fail-closed would) makes a DATA GAP look identical to genuinely-manufactured evidence, and this
    -- view drives a latching, hand-adjudicated alert whose whole purpose is to tell those two apart —
    -- so a gap would invite exactly the wrong call (reverting a change that was never unjustified).
    -- Counted separately below and used to SUPPRESS evidence_invalidated entirely.
    (recomputed_p90 IS NULL OR deadline_minute_of_day IS NULL) AS unrecomputable,
    -- min_n_met mirrors bigquery/89 floor (n_log_rows_90d >= 20). A genuine n < 20 IS a legitimate
    -- not-a-threat outcome (that is how the loop itself defines it), not a data gap, so it stays here.
    (recomputed_p90 IS NOT NULL
     AND deadline_minute_of_day IS NOT NULL
     AND recomputed_n_log_rows_90d >= 20
     AND ABS(recomputed_p90 - deadline_minute_of_day) <= 90) AS recomputed_threat
  FROM parsed
),
agg AS (
  SELECT
    change_id, change_key, change_ts, routine, deadline_key, old_value, new_value,
    COUNT(*) AS n_justifying_obs,
    COUNTIF(persisted_threat) AS n_persisted_threat,
    COUNTIF(recomputed_threat) AS n_recomputed_threat,
    COUNTIF(unrecomputable) AS n_unrecomputable,
    ARRAY_AGG(STRUCT(cycle_date, persisted_p90, recomputed_p90, unrecomputable) ORDER BY cycle_date)
      AS obs_detail
  FROM scored
  GROUP BY change_id, change_key, change_ts, routine, deadline_key, old_value, new_value
)
SELECT
  routine,
  deadline_key,
  change_key,
  change_ts,
  old_value,
  new_value,
  n_justifying_obs,
  n_persisted_threat,
  n_recomputed_threat,
  n_unrecomputable,
  (n_persisted_threat = 3) AS persisted_streak_met,
  (n_recomputed_threat = 3) AS recomputed_streak_met,
  -- evidence_invalidated fires ONLY on a fully-reconstructable change whose persisted 3-of-3 streak does
  -- not survive recomputation under the CURRENT formula. Three guards, each load-bearing:
  --   n_justifying_obs >= 3   — mathematically redundant with persisted_streak_met own "= 3" today
  --                             (n_persisted_threat can never exceed n_justifying_obs), kept EXPLICIT so a
  --                             future edit loosening that threshold (e.g. to ">= 2 of 3") cannot silently
  --                             let a partial reconstruction start firing.
  --   n_unrecomputable = 0    — the real guard. Without it, ONE observation whose ops.run_log window came
  --                             back empty drops n_recomputed_threat below 3 and reports the change as
  --                             manufactured evidence when nothing of the sort was shown. Demonstrated
  --                             during this file own adversarial review: forcing a single reconstruction
  --                             gap into D2 (a genuinely-justified change) flipped it to TRUE while the
  --                             other two observations still reproduced their exact real p90s.
  --   NOT recomputed_streak_met — the actual finding.
  -- A change with n_unrecomputable > 0 is therefore reported (its counts are visible) but never ALERTED
  -- on: "cannot adjudicate" is not the same claim as "the evidence was fabricated".
  (n_justifying_obs >= 3
   AND n_unrecomputable = 0
   AND (n_persisted_threat = 3)
   AND NOT (n_recomputed_threat = 3)) AS evidence_invalidated,
  obs_detail,
  CURRENT_TIMESTAMP() AS checked_at
FROM agg;

-- ===== ops.sp_sq_cadence_check (STATEMENT 3 — SQ_VERSION v12; supersedes bigquery/132) =====
-- Copied VERBATIM from bigquery/132_queue_driven_silence_watch.sql, with exactly two changes: (i) the
-- heartbeat literal 'v11' -> 'v12'; (ii) one new record-only WARNING block
-- (process_constant_evidence_invalidated), added immediately after the existing
-- scheduled_query_version_drift block and styled identically to it. Every other check in 132 is carried
-- forward intact, since CREATE OR REPLACE PROCEDURE replaces the WHOLE body. A comment-stripped code-line
-- diff proving only these two changes was produced during construction of this file and is reported
-- alongside it.
-- SUPERSEDED LIVE by bigquery/153_account_snapshot_gap_watch.sql — current single
-- source of truth for ops.sp_sq_cadence_check (supersedes this file, per the chain noted above, via
-- the intermediate bigquery/147). 147 bumps the heartbeat to v13, adds the run_log_note_missing
-- record-only check and its auto-age allowlist entry; 149 bumps the heartbeat to v14 and adds
-- script_version_drift to the #14 auto-age category list; 150 bumps the heartbeat to v15 and adds
-- 'connector' + 'strategy_revised' to the #14 auto-age category list; 153 bumps the heartbeat to v17
-- and adds the account_snapshot_gap record-only WARNING block (+ 'account_snapshot_gap' to the #14
-- auto-age list); all are otherwise a verbatim copy of the body below. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
-- SUPERSEDED (2026-08-10) by bigquery/159_cadence_check_info_severity_autoage.sql (SQ_VERSION
-- v19) -- the current single source of truth for ops.sp_sq_cadence_check. Its predecessor was
-- bigquery/157_account_snapshot_gap_recoverable.sql (SQ_VERSION v18), which is NO LONGER current.
-- 157 retracts a FALSEHOOD carried by every
-- version from v17 down: the account_snapshot_gap alert message claimed the gap days could never be
-- backfilled because IBKR exposes no historical-NAV endpoint. It does -- get_pa_performance_all_periods
-- returns parallel dates[]/nav[] arrays, and D2a Step 0b already calls it but keeps only the last
-- element. 157 changes exactly three strings (heartbeat v17->v18, that message, one comment) and no
-- check logic. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:cadence_check', 'v12', 'cadence_check.sql ran');

  -- RUNBOOK section 38 self-heal (ITEM 3, bigquery/38_run_log_selfheal.sql): backfill any
  -- ops.run_log completion row whose routine already has a landed-commit marker in
  -- ops.routine_commit_markers, BEFORE evaluating missed_run/missing_dependency below, so a
  -- landed-but-unlogged strand self-heals the same night instead of tripping the dead-man's
  -- switch. (This proc also calls sp_auto_resolve_alerts() itself once it backfills anything,
  -- so the general call right below is defense-in-depth for unrelated alerts, not redundant
  -- plumbing.) Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_backfill_run_log_from_markers`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Mechanized alert auto-resolve (WP2, defense-in-depth alongside the routine-level call above).
  -- Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Auto-resolve STALE self-healing WARNING rows (2026-06-28, #14) so the weekly digest's "N open alerts"
  -- reflects live issues, not warnings the owner never manually closed (e.g. a 4-day-old self-healed
  -- instruction_drift warning keeping the digest red). Targets only the self-CLEARING classes, warning
  -- severity, older than 7 days. A condition that is STILL true is simply re-raised by the checks below
  -- (sp_raise_alert_once), so this can only durably clear a row whose underlying condition has actually
  -- healed. Critical rows and the persistent-DRIFT classes (position_drift / ddl_drift /
  -- append_only_violation / restore_fidelity) are deliberately left untouched. Runs first, before any RAISE
  -- (which would abort the script). all_green keys only on open CRITICAL alerts, so this is purely a
  -- digest-quality fix, not a dead-man's-switch change.
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE,
      resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-aged (>7d self-healing warning; cadence_check.sql #14). ', COALESCE(resolved_note, ''))
  WHERE NOT resolved
    AND severity = 'warning'
    -- trigger_missing added 2026-07-04 (audit finding): its message used to embed a daily-changing
    -- day-count, defeating sp_raise_alert_once's dedup and letting undeduped rows accumulate
    -- indefinitely since it was the one self-healing class missing from this auto-age list. The
    -- message fix below (stable text) restores real dedup; this stays as defense-in-depth.
    -- immediate_action_flagged + process_scorecard_signal added 2026-07-16 (consumption-closure): point-in-time W3/M3/W5 signals, consumed autonomously by W4/M4 within days; 7-day age-out stops forever-open dashboard rows. A persisting condition is simply re-raised.
    -- scheduled_query_version_drift added 2026-07-27 (bigquery/111): the SAME self-healing shape as
    -- scheduled_query_stale directly above. A version marker only reports what a scheduled query said
    -- the LAST time it ran, so a mid-day wrapper bump leaves the prior version as the freshest beat
    -- until that query's own next run -- and this proc evaluates ~05:15 UTC, ahead of most of them
    -- (daily_staging_cap_check ~05:25). The gap is therefore a routine bootstrapping-window race that
    -- heals itself within one cycle, exactly like a resumed beat, but it was the one such class absent
    -- from this list -- so every wrapper version bump left a permanently-open row needing a manual
    -- UPDATE (embed_pending 2026-07-17/18; daily_staging_cap_check v3->v4 2026-07-27, alert 0c2b631a).
    -- A STILL-drifted query is simply re-raised by the scheduled_query_version_drift check below, so a
    -- genuinely unapplied wrapper cannot be aged away silently.
    -- scheduled_query_stale + ci_findings_bridge_stale + control_plane_insert added 2026-07-17 (MON H2/H4/H5): self-healing warnings (a resumed beat / a re-armed bridge / an aged-out control INSERT event stop being true) whose stable-message rows would otherwise linger open after the condition heals; a STILL-true condition is simply re-raised below (bridge_stale/scheduled_query_stale in THIS proc, control_plane_insert by safety_critical_dml_watch).
    -- 'stranded_session' REMOVED 2026-07-29, because the Operating_Protocols.md §17 never-pushed-branch
    -- detector that raised it was RETIRED 2026-07-29 (commit a9a029b) and nothing in the tree can raise
    -- the category any more -- verified 2026-07-30: every remaining mention is either an auto-age
    -- allowlist (here and bigquery/75's superseded copy) or RUNBOOK prose describing one. A dead entry in
    -- a fail-closed allowlist reads as coverage that does not exist; dropped with §17.
    -- CORRECTION 2026-07-30: this comment previously justified the removal by asserting the category "was
    -- never once raised anywhere in this repo's entire git history" and "existed only in this allowlist".
    -- Both are FALSE, and the live table is the authority: ops.alerts holds exactly one stranded_session
    -- row -- raised 2026-06-24 22:41:49 by D2 for session sess-d1-20260624 (RUNBOOK §20 never-pushed
    -- strand) -- and THIS auto-age rule is what resolved it, on 2026-07-02 05:15:10, with
    -- resolved_note 'auto-aged (>7d self-healing warning; cadence_check.sql #14)'. So the entry was live
    -- coverage that demonstrably fired once; it is dead only PROSPECTIVELY, now that its raiser is gone.
    -- The removal stands (nothing can raise it, and the one historical row is long resolved, so no open
    -- alert is stranded by dropping it) -- but do not re-derive "never raised" from the old wording.
    -- CAUTION for any future allowlist edit: before dropping a category from this FAIL-CLOSED list,
    -- query ops.alerts for OPEN rows in it. An open row in a removed category never auto-ages again.
    AND category IN ('instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing', 'immediate_action_flagged', 'process_scorecard_signal', 'scheduled_query_stale', 'ci_findings_bridge_stale', 'control_plane_insert', 'scheduled_query_version_drift', 'queue_driven_silent')
    AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);

  -- missed_run (critical) — a monitored routine expected today did not complete.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'missed_run',
      CONCAT('Cadence check: monitored routine(s) expected today did not complete: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, schedule, today)))
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
    SET raise_msg = raise_msg || CONCAT('[missed_run] ',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention), '; ');
  END IF;

  -- queue_driven_silent (warning) — a queue_driven routine has logged no completed run for longer
  -- than any gap in its own history. THIS IS THE ONLY NET THAT COVERS THEM: monitor_class
  -- queue_driven is excluded from state.cadence_expected_today, which BOTH state.cadence_watch and
  -- state.cadence_period_watch are built on, so AR_att/AR_orc/SL2/SL5 have never had a cadence
  -- signal of any kind. Measured 2026-08-03: SL2 and SL5 went dark after 2026-07-30 when their
  -- triggers were disabled, and NOTHING alerted on the silence — the only surfacing was D3's
  -- queue_item_stale, a downstream symptom whose own text had to flag the root cause as INFERRED
  -- because it could not verify it.
  --
  -- WARNING, deliberately NOT critical, and it must stay that way. state.trading_enabled ANDs
  -- `blocking_criticals = 0`, so a critical here would HALT ORDER STAGING every time a SISA
  -- lifecycle routine went quiet. That is exactly the failure mode of the 2026-08-01..03 incident
  -- this file's sibling (bigquery/130) exists to prevent; do not promote this category.
  --
  -- Record-only, like instruction_drift: does NOT append to raise_msg and so does not contribute to
  -- the DTS failure-email RAISE. Auto-ages after 7d via the allowlist above and re-raises on the
  -- next run while the condition persists.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'queue_driven_silent',
      CONCAT('Queue-driven routine(s) silent past threshold — these sit OUTSIDE the cadence nets, so a disabled or dead trigger here produces no other signal. Check the trigger is enabled in claude.ai before assuming an empty queue: ',
             (SELECT STRING_AGG(CONCAT(routine, ' (last completed ',
                                       COALESCE(CAST(last_run_date AS STRING), 'NEVER'), ', ',
                                       COALESCE(CAST(days_silent AS STRING), '?'), 'd ago)'),
                                ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, last_run_date, days_silent,
                                              silence_threshold_days, never_completed) ORDER BY routine))
       FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent));
  END IF;

  -- backup_stale (critical) — events.* GCS backup has not logged a success in >2 days (16_automation_health.sql).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'backup_stale',
      'Backup check: events.* GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.backup_health`);
  END IF;

  -- ops_backup_stale (critical, 2026-06-28 #2) — the ops.* (audit/control-plane) GCS backup has gone
  -- silent (>2 days). ops.* is IRREPLACEABLE append-only history with no upstream, so a stalled ops
  -- backup is as serious as a stalled events backup. Self-bootstrapping (state.ops_backup_health.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ops_backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'ops_backup_stale',
      'Backup check: ops.* (audit/control-plane) GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.ops_backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[ops_backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.ops_backup_health`);
  END IF;

  -- automation_heartbeat (critical) — an out-of-band Apps Script went silent (16_automation_health.sql).
  -- Delivered via THIS query's DTS failure-email, NOT via the (possibly-dead) alert emailer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'automation_heartbeat',
      CONCAT('Heartbeat check: out-of-band automation went silent: ',
             (SELECT STRING_AGG(source, ', ' ORDER BY source)
              FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(source, age_hours, max_age_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale));
    SET raise_msg = raise_msg || CONCAT('[automation_heartbeat] ',
      (SELECT STRING_AGG(source, ', ' ORDER BY source)
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale), '; ');
  END IF;

  -- instruction_drift (WARNING, non-raising). The schedule/instruction live only in the web UI;
  -- state.instruction_drift (bigquery/15_routine_catalog.sql) diffs each routine's LIVE logged trigger
  -- against the canonical catalog. A drift is a config bug to fix, not a halt — so it records but does
  -- NOT contribute to the RAISE.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'instruction_drift',
      CONCAT('Trigger drift: routine(s) whose live web-UI trigger differs from the canonical catalog: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, drifted, unknown_routine, live_instruction, canonical_instruction)))
       FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine));
  END IF;

  -- ====================================================================================
  -- 2026-06-24 stack-review additions (all WARNING, record-only — like instruction_drift —
  -- so they NEVER flip all_green and NEVER add to the DTS RAISE; delivered by the alert
  -- emailer / out-of-band relay, which both forward 'warning' rows). They reference views in
  -- bigquery/18_stack_review_fixes.sql — APPLY 18 BEFORE re-pasting this query. All read only
  -- ops.run_log + state views (no extra IAM); the JOBS-based append-only guard lives in the
  -- separate integrity_check.sql (it needs roles/bigquery.resourceViewer). RUNBOOK §25.
  -- ====================================================================================

  -- trigger_missing (D2) — a calendar-predictable routine the cadence ALARM deliberately excludes
  -- (weekly/monthly/quarterly/annual) has logged NO completed run across its cadence window: a DELETED
  -- (vs edited) web-UI trigger, which instruction_drift cannot see (it needs a run to log). Self-
  -- bootstrapping: only flags routines that have completed before (state.trigger_attestation.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_since_completed (which changes
    -- daily while a routine stays overdue) defeated sp_raise_alert_once's exact-match dedup, creating
    -- a fresh open alert row every day the condition persisted. Per-routine day counts are still fully
    -- visible in the payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'trigger_missing',
      CONCAT('Trigger attestation: routine(s) overdue beyond their cadence window (deleted/disabled web-UI trigger?): ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue),
             '. See payload for per-routine day counts.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, days_since_completed, max_gap_days, last_completed)))
       FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue));
  END IF;

  -- period_missed (warning, 2026-07-03 self-improvement audit WO-1/B-6-obs) — a weekly/monthly/quarterly/
  -- annual routine has not logged 'completed' anywhere in the CURRENT period (ISO week / month / quarter /
  -- year) and Denver wall-clock is past that period's grace deadline (bigquery/24_cadence_period_watch.sql
  -- — placed strictly after the documented Sun-or-Mon weekly tolerance / the 3rd-or-5th trading day for
  -- longer periods). Closes the gap where trigger_missing's coarse 14/70/200/400-day window could leave a
  -- single missed weekly routine unflagged for up to ~2 weeks. Self-bootstrapping (state.cadence_period_
  -- watch.monitored) and WARNING-only (a missed weekly is not a same-night trading halt) — promote to a
  -- RAISE-contributing critical only after a clean period confirms no false fire.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'period_missed',
      CONCAT('Cadence period check: routine(s) have not completed in the current period past their grace deadline: ',
             (SELECT STRING_AGG(CONCAT(routine, ' (', monitor_class, ', period ', CAST(period_start AS STRING), ')'), ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, monitor_class, period_start, grace_deadline)))
       FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed));
  END IF;

  -- routine_stalled (marginal) — a routine logged 'started' but never a terminal status past its per-class
  -- threshold (2026-06-28 #11: now ALL run-logged routines, not just D1/D2/D3): a session that died after
  -- sp_routine_start but before sp_routine_end (the run-log-blind slice).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.stalled_runs`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'routine_stalled',
      CONCAT('Stalled run(s): a routine started but never logged a terminal status: ',
             (SELECT STRING_AGG(CONCAT(routine, '/', CAST(run_date AS STRING)), ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.stalled_runs`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, hours_since_started)))
       FROM `stock-trading-498512.state.stalled_runs`));
  END IF;

  -- position_drift (B4) — the two open-position representations (state.current_positions vs
  -- analytics.position_lifecycle) disagree on open shares beyond tolerance for some (strategy,ticker).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'position_drift',
      CONCAT('Position reconciliation: current_positions vs position_lifecycle open-share drift: ',
             (SELECT STRING_AGG(CONCAT(strategy, ':', ticker), ', ' ORDER BY strategy, ticker)
              FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy, ticker, current_positions_shares, lifecycle_open_shares, share_diff)))
       FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted));
  END IF;

  -- calendar_runway_low (FMP auto-extend liveness) — the trading-calendar horizon has fallen below the
  -- W5 FMP auto-extend trigger and stayed there, an EARLY signal the auto-extend (likely the FMP grant)
  -- is failing, well before the calendar exhausts and the freshness COALESCE→FALSE backstop trips.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.market_calendar_horizon` WHERE runway_low) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_of_runway/calendar_through (both
    -- change daily while the condition persists) defeated sp_raise_alert_once's exact-match dedup,
    -- creating a fresh open alert row every day the runway stayed low. Full detail is still in the
    -- payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'calendar_runway_low',
      'Market-calendar runway low — W5 FMP auto-extend may be failing. See payload for runway/through-date detail.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.market_calendar_horizon` t));
  END IF;

  -- ====================================================================================
  -- 2026-06-28 stack-review #2 additions (originally all WARNING, record-only. restore_stale was PROMOTED
  -- to CRITICAL + RAISE-contributing on 2026-07-11, and ddl_drift on 2026-07-26, each by D3's
  -- monitor-promotion self-flip once its readiness view fired — ITEM 24).
  -- Reference views in bigquery/17_restore_drill.sql (state.restore_health) and
  -- bigquery/19_stack_review_fixes_2.sql (state.ddl_drift) — APPLY 17 + 19 BEFORE re-pasting this query.
  -- ====================================================================================

  -- restore_stale (CRITICAL as of 2026-07-11, promoted from warning per ITEM 24 — see the self-flip note
  -- at the IF block below; #4) — the monthly restore drill has not completed in >40 days OR its last run
  -- did not pass. A drill that writes nothing on success is otherwise invisible (state.restore_health off
  -- ops.drill_log). A silently-paused DR drill means "DR verified monthly" is a belief, not a fact. (A dead
  -- drill SCHEDULER is additionally caught by the Cloud Monitoring absence policy in monitoring.tf.)
  -- MONITOR-PROMOTION HISTORY (ITEM 24, 2026-07-11): logged UNCONDITIONALLY (pass or fail), regardless of
  -- whether the WARNING below fires -- state.ddl_drift_promotion_readiness / state.restore_stale_
  -- promotion_readiness (bigquery/45_monitor_promotion.sql) need this history to evaluate "N consecutive
  -- clean runs", which the plain live views above cannot provide on their own.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, not plain INSERT -- a plain INSERT
  -- let a same-day re-run of this query (off-schedule/manual/duplicate, the exact class the 2026-06-25
  -- cadence deadline-guard fix already had to account for) write a second row for the same (check_id,
  -- check_date), which the NOT-ENFORCED primary key does not prevent -- breaking the "14 consecutive
  -- DISTINCT logged days" promotion bar this history table exists to support (bigquery/45's readiness
  -- views also defend against any pre-existing duplicate independently).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'restore_stale' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT COALESCE(stale, TRUE) AS clean
    FROM `stock-trading-498512.state.restore_health`
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  -- PROMOTED WARNING->CRITICAL (2026-07-11, D3 monitor-promotion self-flip per ITEM 24): once
  -- state.restore_stale_promotion_readiness.ready=TRUE (monitored=TRUE AND last drill passed — the
  -- RUNBOOK's own stated bar), D3 self-applies this promotion. Now a RAISE-contributing critical,
  -- wired into raise_msg like backup_stale/automation_heartbeat above (a silently-stale DR drill is a
  -- capital-safety fact, not a buried warning). ops.monitor_promotion_log guards idempotency.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.restore_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'restore_stale',
      (SELECT CONCAT('Restore-drill health: last drill ', CAST(last_drill_date AS STRING),
                     ' (passed=', CAST(last_drill_passed AS STRING), ') — stale or failing')
       FROM `stock-trading-498512.state.restore_health`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.restore_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[restore_stale] last_drill=',
      CAST(last_drill_date AS STRING), ' passed=', CAST(last_drill_passed AS STRING), '; ')
      FROM `stock-trading-498512.state.restore_health`);
  END IF;

  -- ddl_drift (CRITICAL as of 2026-07-26, promoted from warning per ITEM 24 — D3 monitor-promotion
  -- self-flip once state.ddl_drift_promotion_readiness.ready=TRUE (14 consecutive clean logged days);
  -- #7) — a live events.* audit table's STRUCTURE (NOT NULL / type / partition /
  -- cluster) diverged from the canonical bigquery/01_schema.sql spec (a silent out-of-band ALTER the
  -- idempotent CREATE-IF-NOT-EXISTS spec will not re-assert; invisible to the DML-only append_only_integrity
  -- and to dbt not_null DATA tests). Now a RAISE-contributing critical, wired into raise_msg like
  -- restore_stale above. ops.monitor_promotion_log guards idempotency.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, same rationale as the restore_stale
  -- write above.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'ddl_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'ddl_drift',
      CONCAT('DDL drift: events.* base-table structure differs from bigquery/01_schema.sql: ',
             (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
                     ORDER BY table_name, column_name)
              FROM `stock-trading-498512.state.ddl_drift`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(table_name, column_name, drift_reasons, expected_type, live_type)))
       FROM `stock-trading-498512.state.ddl_drift`));
    SET raise_msg = raise_msg || CONCAT('[ddl_drift] ',
      (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
              ORDER BY table_name, column_name)
       FROM `stock-trading-498512.state.ddl_drift`), '; ');
  END IF;

  -- b3_trading_enabled_drift (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- dbt-b3-coverage-advisory-only). state.b3_trading_enabled_check (bigquery/64_b3_live_invariants.sql)
  -- recomputes state.trading_enabled's formula independently and flags LIVE drift -- the exact
  -- 2026-07-11 incident class (an in-place scheduled-query re-apply silently clobbered a gate
  -- AND-term for days with zero CI/live signal, bigquery/47_trading_enabled_resync.sql), now checked
  -- daily instead of only in an advisory-only dbt test.
  -- MONITOR-PROMOTION HISTORY for b3_trading_enabled_drift (MON M2, 2026-07-17). Mirrors the
  -- ddl_drift/restore_stale MERGE-upsert above and the append_only_integrity one in integrity_check.sql
  -- (ITEM 24/31): logged UNCONDITIONALLY every run (clean = zero drift rows in
  -- state.b3_trading_enabled_check) so state.b3_promotion_readiness (bigquery/79_b3_promotion.sql) can
  -- evaluate the 14-consecutive-clean-DISTINCT-day bar the plain live view cannot provide on its own —
  -- bigquery/64's header promised this promotion path but nothing wrote the history until now. MERGE
  -- (not INSERT) so a same-day off-schedule/manual re-run never double-logs one day (same rationale as
  -- the ddl_drift/restore_stale writes). Does NOT change this check's alerting: still the WARNING-only
  -- IF block below. Because b3_trading_enabled_drift lives in THIS file (which HAS the raise_msg
  -- accumulator, unlike append_only_integrity), D3's MONITOR-PROMOTION SELF-FLIP promotes it by flipping
  -- the 'warning' literal below to 'critical' AND appending to raise_msg — see bigquery/79's header.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'b3_trading_enabled_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'b3_trading_enabled_drift',
      (SELECT CONCAT('state.trading_enabled formula drift: live=', CAST(live_value AS STRING),
                     ' but independently-recomputed expected=', CAST(expected_value AS STRING),
                     ' -- a gate AND-term may have been silently clobbered (see bigquery/47_trading_enabled_resync.sql)')
       FROM `stock-trading-498512.state.b3_trading_enabled_check`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.b3_trading_enabled_check` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[b3_trading_enabled_drift] live=', CAST(live_value AS STRING),
      ' expected=', CAST(expected_value AS STRING), '; ') FROM `stock-trading-498512.state.b3_trading_enabled_check`);
  END IF;

  -- backup_per_table_row_drop (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- backup-per-table-rows-write-only). state.backup_per_table_health (bigquery/65_backup_per_table_
  -- health.sql) was write-only (RUNBOOK B2's per-table row-count evidence, INSERTed but never read).
  -- Every backed-up table is append-only by design, so a day-over-day row-count DROP can only mean an
  -- out-of-band deletion or a backup-query regression -- never legitimate activity.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'backup_per_table_row_drop',
      CONCAT('Backup per-table row-count DROP detected (append-only table(s) should never shrink): ',
             (SELECT STRING_AGG(CONCAT(dataset, '.', table_name, ' ', CAST(prior_rows AS STRING), '->', CAST(latest_rows AS STRING)), ', ' ORDER BY dataset, table_name)
              FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(dataset, table_name, prior_run_date, prior_rows, latest_run_date, latest_rows)))
       FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped));
  END IF;

  -- script_version_drift (warning, item 23 -- Apps Script drift detection). A deployed .gs (alert_emailer
  -- / weekly_report) is running a version other than the repo's expected one, or has stopped reporting a
  -- version at all after previously doing so -- almost always a Claude-side .gs fix that was never re-
  -- pasted by the owner (script.google.com is unreachable from Claude). Self-bootstrapping
  -- (state.script_version_drift.monitored) so this never fires before the owner has pasted the version-
  -- emitting .gs diff at least once. Delivered via THIS query's DTS failure-email path is deliberately
  -- NOT used for delivery (kept WARNING, record-only, like instruction_drift/ddl_drift) since alert_emailer
  -- itself is one of the two monitored scripts -- routing this alarm through it would be circular; the
  -- warning still reaches the owner via the alert emailer's own periodic poll of ops.alerts, which is a
  -- SEPARATE mechanism from "this script being the delivery channel for its own drift" (see 43_script_
  -- version_registry.sql header). Staged-rollout WARNING until a clean baseline confirms no false fire,
  -- matching the ddl_drift / restore_stale precedent above.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.script_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'script_version_drift',
      CONCAT('Script version drift: deployed Apps Script(s) running an unexpected/missing version: ',
             (SELECT STRING_AGG(CONCAT(script_name, ' (expected ', expected_version, ', reported ',
                     COALESCE(last_reported_version, 'NONE'), ')'), ', ' ORDER BY script_name)
              FROM `stock-trading-498512.state.script_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(script_name, expected_version, last_reported_version, last_beat_ts)))
       FROM `stock-trading-498512.state.script_version_drift` WHERE drift));
  END IF;

  -- scheduled_query_version_drift (warning, consumption-closure audit 2026-07-16 -- bigquery/63's
  -- drift view previously had NO automated reader anywhere; verbatim mirror of the script_version_drift
  -- block directly above, same self-bootstrapping convention: monitored=FALSE rows can never fire.
  -- Self-reference caveat: this block cannot report THIS query's own regression -- a regressed body
  -- lacks the block -- so Claude_Task_Plan.md's D3 UNWIRED-MONITOR BRIDGE bullet also raises this
  -- category for cadence_check itself (self-retiring once this body's own heartbeat matches v5 —
  -- comment updated 2026-07-16 by the ARCH-1 wrapper migration's v4->v5 bump; no logic change).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_version_drift',
      CONCAT('Scheduled-query body drift (live console body != repo SQ_VERSION): ',
        (SELECT STRING_AGG(CONCAT(sq_name,' (expected ',expected_version,', reported ',COALESCE(last_reported_version,'NONE'),')'), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, expected_version, last_reported_version, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift));
  END IF;

  -- process_constant_evidence_invalidated (warning, bigquery/142_cadence_deadline_revert_and_evidence_
  -- drift.sql, 2026-08-06). state.process_constant_evidence_drift re-validates an ALREADY-APPLIED W5
  -- process_reliability autotune against the metric-view predicate set its justification depended on,
  -- recomputed as of TODAY — closing a gap state.process_constant_oos_watch (bigquery/72) structurally
  -- cannot reach: that fail-safe only detects that the change did not work (a persisted POST-change
  -- threat); this detects that the evidence was never real (a persisted PRE-change threat manufactured
  -- by a metric formula later corrected — see bigquery/89, 2026-08-04, backfilled-row exclusion, which
  -- is exactly what happened to the D1 2026-08-03 cadence_watch_deadline_local autotune; see bigquery/142
  -- header for the full account). Record-only, like instruction_drift/ddl_drift/ci_finding above: does
  -- NOT join raise_msg (an invalidated-evidence finding needs human adjudication — re-read the view,
  -- decide whether to revert the constant or accept the change on other grounds — it is not a same-night
  -- trading halt). Deliberately ABSENT from the #14 auto-age allowlist above: unlike a self-healing
  -- transient, a genuinely invalidated evidence trail does not become false again on its own, so this must
  -- stay open until a human closes it by hand — see ops.alert_policy.resolve_rule for this category
  -- (bigquery/142).
  -- BEST-EFFORT GUARD, same pattern this procedure already applies to sp_backfill_run_log_from_markers
  -- and sp_auto_resolve_alerts above. BigQuery binds a procedure's referenced objects LAZILY, at CALL
  -- time rather than CREATE time, so applying this v12 body BEFORE bigquery/142's Statement 2 would not
  -- fail on creation — it would abort the NEXT nightly run mid-body with `Not found:
  -- state.process_constant_evidence_drift`, silently killing every check BELOW this point
  -- (scheduled_query_stale, probe_funding_stalled, cash_flows_backfill_broken, ci_finding,
  -- ci_findings_bridge_stale, constant_tuning_loop_heartbeat_missing, park_allocator heartbeat) for that
  -- run and every run after. Applying the file top to bottom makes that impossible, but a partial or
  -- reordered apply must never be able to take down the fleet's dead-man switch over one advisory check.
  BEGIN
    IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated) THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.cadence', 'process_constant_evidence_invalidated',
        CONCAT('Process-constant autotune evidence INVALIDATED by a later metric-formula correction — ',
               'persisted vs recomputed threat streak (of 3), 90-day trailing p90 completion-minute-of-day: ',
               (SELECT STRING_AGG(
                  CONCAT(routine, '/', deadline_key, ' change ', old_value, '->', new_value,
                         ' (persisted ', CAST(n_persisted_threat AS STRING), ' of 3, recomputed ',
                         CAST(n_recomputed_threat AS STRING), ' of 3)'),
                  '; ' ORDER BY routine)
                FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated)),
        (SELECT TO_JSON_STRING(ARRAY_AGG(t))
         FROM `stock-trading-498512.state.process_constant_evidence_drift` t WHERE evidence_invalidated));
    END IF;
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- scheduled_query_stale (warning, MON H5, 2026-07-17). state.scheduled_query_version_drift detects only
  -- a VERSION mismatch among sources that have EVER beaten; a DTS config that silently STOPS forever (7 of
  -- the 12 can), or one registered but never once beaten, is invisible to it — nothing watched beat AGE.
  -- bigquery/63 now carries expected_interval_hours per query + a grace factor and exposes two new columns:
  --   * stale_beat        — monitored (has beaten >=1x) AND last_beat_ts older than interval x grace.
  --   * never_beat_overdue — NOT monitored AND the registry row was declared > 7 days ago (self-
  --                          bootstrapping grace: a freshly-registered query stays quiet for a week).
  -- Record-only, no RAISE (promotion-eligible via the bigquery/45 ladder later, like ddl_drift): a stalled
  -- scheduled query is also caught by its own DTS email-on-failure and the Cloud Monitoring absence policy;
  -- this is the in-band, digest-visible backstop. DEDUP-CRITICAL: the message lists ONLY sq_names +
  -- which failure mode (stable while the stalled set is stable, per the order_guard_omitted convention);
  -- daily-changing ages live ONLY in the JSON payload.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_stale',
      CONCAT('Scheduled-query beat-age dead-man — DTS config(s) overdue past their expected interval (x grace) or never-beat window: ',
        (SELECT STRING_AGG(CONCAT(sq_name, IF(never_beat_overdue, ' (NEVER beat)', ' (stale beat)')), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, monitored, stale_beat, never_beat_overdue, expected_interval_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts) ORDER BY sq_name))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue));
  END IF;

  -- probe_funding_stalled (warning, consumption-closure audit 2026-07-16) -- state.strategy_probe_
  -- funding_stalled (bigquery/62_probe_stake_funding.sql) flags a PROBE-phase newcomer frozen below
  -- the $2,000 floor for >=90 days; previously had no automated reader at all.
  -- DEDUP-CRITICAL: message lists ONLY strategy codes (stable while the stalled set is stable); the
  -- daily-changing numbers (funding_gap_dollars, days_since_probe_entry) live ONLY in the JSON
  -- payload, because ops.sp_raise_alert_once dedups on exact unresolved (category, message) -- a
  -- day-counter in the message would insert a new unresolved warning row + email EVERY night per
  -- stalled newcomer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.strategy_probe_funding_stalled`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','probe_funding_stalled',
      CONCAT('PROBE newcomer(s) frozen below the $2,000 floor >=90 days: ',
        (SELECT STRING_AGG(strategy_code, ', ' ORDER BY strategy_code)
         FROM `stock-trading-498512.state.strategy_probe_funding_stalled`),
        ' — a deposit (sanctioned residual touch) or FIFO redistribution priority check is needed; per-strategy gap/days in payload'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy_code, funding_gap_dollars, days_since_probe_entry)))
       FROM `stock-trading-498512.state.strategy_probe_funding_stalled`));
  END IF;

  -- cash_flows_backfill_broken (warning, consumption-closure audit 2026-07-16) -- state.cash_flows_
  -- backfill_check (bigquery/68_cash_flows_backfill_check_dated.sql, date-scoped redefinition of the
  -- bigquery/22 apply-time gate) flags a backdated/duplicate/typo events.cash_flows row dated
  -- <= 2026-07-03 that shifts the NAV/sizing baseline every downstream consumer relies on. A future
  -- legitimate deposit cannot flip this (view is date-scoped), so it is now safe to poll nightly.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cash_flows_backfill_check` WHERE NOT reconciled) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','cash_flows_backfill_broken',
      'events.cash_flows rows dated <= 2026-07-03 no longer sum to the 9446.86 seed total — a backdated/duplicate/typo flow has shifted the NAV/sizing baseline; investigate before trusting analytics.strategy_nav (bigquery/68)',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.cash_flows_backfill_check` t));
  END IF;

  -- ci_finding (warning, self-improvement audit 2026-07-16, CC-1 -- CI-findings consumption-closure
  -- bridge, bigquery/67_ci_findings_bridge.sql). Four CI guards (live-sql-parity, keyless-sa-audit,
  -- wif-binding-audit, guard-config-audit) each open/refresh a deduped GitHub issue on a finding, but
  -- nothing previously read those issues -- this closes the loop by raising/auto-resolving off
  -- state.ci_findings_open, so a finding reaches the monitored alert-emailer channel even on a day
  -- nobody manually reads GitHub Issues. AUTO-RESOLVE FIRST (matching the RECORD-THEN-RAISE convention
  -- above): once state.ci_findings_open is empty, clear any still-open ci_finding alert -- this also
  -- covers the case where the underlying workflow's next clean run wrote its unconditional resolved
  -- row (see live-sql-parity.yml's "Close finding issue if resolved" step) after a manually-closed GH
  -- issue would otherwise have stranded it. Record-only (does NOT join raise_msg), matching
  -- script_version_drift / ddl_drift / restore_stale above -- an open CI finding is a config/drift bug
  -- to fix, not a trading halt.
  UPDATE `stock-trading-498512.ops.alerts`
     SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
         resolved_note = CONCAT('auto-resolved: state.ci_findings_open empty. ', COALESCE(resolved_note, ''))
   WHERE NOT resolved AND category = 'ci_finding'
     AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_finding',
      CONCAT('Open CI guard finding(s): ',
             (SELECT STRING_AGG(CONCAT(workflow, '/', finding_key), ', ' ORDER BY workflow)
              FROM `stock-trading-498512.state.ci_findings_open`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(workflow, finding_key, CAST(finding_ts AS STRING) AS finding_ts, detail, run_url)))
       FROM `stock-trading-498512.state.ci_findings_open`));
  END IF;

  -- ci_findings_bridge_stale (warning, MON H2, 2026-07-17). The ci_finding block above only ever fires
  -- when the bridge DELIVERS a finding — but ops.ci_findings is the DECLARED single delivery path for
  -- live-sql-parity drift (bigquery/67 / Claude_Task_Plan.md D3), and a DEAD bridge is indistinguishable
  -- from a clean one: zero rows reads identically to "no drift" while objects could sit drifted invisibly.
  -- As of 2026-07-17 the bridge has delivered ZERO live-sql-parity rows EVER (the workflow's INSERT was
  -- swallowed by `|| echo ::warning::` inside an otherwise-green run — fixed in live-sql-parity.yml this
  -- same pass). This dead-man fires when the newest live-sql-parity finding_ts is older than ~40h (the
  -- daily workflow cadence + one missed run of grace) OR — critically — when NONE has EVER been delivered
  -- (MAX over empty = NULL; COALESCE to the epoch makes the never-delivered state fire, which is the
  -- current state and exactly the never-armed failure the swallowed INSERT produced). Record-only, does
  -- NOT join raise_msg (a stalled plumbing bridge is a config fix, not a trading halt), matching
  -- ci_finding/ddl_drift. DEDUP-CRITICAL: the message is fully static (no timestamps/counts); detail is in
  -- the payload — so a persisting dead bridge dedups to a single open warning, not a fresh row every run.
  IF (
    SELECT COALESCE(MAX(finding_ts), TIMESTAMP '1970-01-01 00:00:00 UTC')
             < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 40 HOUR)
    FROM `stock-trading-498512.ops.ci_findings`
    WHERE workflow = 'live-sql-parity'
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_findings_bridge_stale',
      'ops.ci_findings has NO live-sql-parity row newer than ~40h (or none has EVER been delivered) — the DECLARED single delivery path for live-sql-parity drift (bigquery/67) may be dead. A dead bridge reads identically to "no drift", so drifted objects could sit unsurfaced. Verify the daily live-sql-parity.yml run: the WIF vars (GCP_WIF_PROVIDER/SERVICE_ACCOUNT) must be set AND the gh-ci-runner@ dataEditor grant on ops.ci_findings must be live, and the INSERT step must now fail-loud on error (fixed 2026-07-17). See payload for row count / last finding_ts.',
      (SELECT TO_JSON_STRING(STRUCT(
         (SELECT COUNT(*) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS live_sql_parity_rows,
         (SELECT CAST(MAX(finding_ts) AS STRING) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS last_finding_ts,
         CAST(CURRENT_TIMESTAMP() AS STRING) AS checked_at))));
  END IF;

  -- constant_tuning_loop_heartbeat_missing (warning, item 11 -- self-improvement audit 2026-07-11).
  -- meta_monitoring_heartbeat (ops/autonomy_levels.yaml) documents every active_auto/shadow loop should
  -- write an "evaluated this cycle" heartbeat with a scheduled-query dead-man's switch alerting on
  -- absence -- LIVE today for strategy_arsenal (SL1/SL3/SL4) but the four constant-tuning loops
  -- (process_reliability, strategy_playbook, execution_quality_tuning, calibration_parameter_carveout)
  -- had NEITHER a heartbeat write NOR a routine that ever evaluated them at all until Claude_Task_Plan.md's
  -- W5 section was extended (item 11) to write ops.heartbeat(source='loop:<id>') every W5 firing,
  -- regardless of whether that loop's own readiness view fired. cross_model_referee_independence (added
  -- 2026-07-15, promoted dormant->shadow) joins the same list, same W5 bullet pattern. Self-bootstrapping:
  -- a loop with ZERO ops.heartbeat rows ever (never yet evaluated even once post-deployment) does not
  -- alarm -- only a loop that HAS reported at least once and then goes quiet trips this, exactly the
  -- state.script_version_drift / instruction_drift self-bootstrapping convention above. W5 runs weekly;
  -- the ~10-day window tolerates one missed cycle before alarming. Staged-rollout WARNING (record-only),
  -- matching every other self-bootstrapping monitor in this file. park_allocator (added 2026-07-26, PARK
  -- v3 immediate-binding redesign, shadow->active_auto) joins this list too, per
  -- scripts/check_autonomy_consistency.py's coverage requirement -- but its REAL primary coverage is the
  -- dedicated, tighter, trading-day-aware block immediately below (this flat 10-calendar-day window is a
  -- required belt-and-suspenders membership for a loop whose actual cadence is daily, not weekly).
  IF EXISTS (
    SELECT 1 FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                           'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                           'loop:cross_model_referee_independence','loop:research_quality_feedback',
                           'loop:park_allocator']) AS loop_source
    WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
      AND NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
        WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY))
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
      CONCAT('Constant-tuning loop(s) previously reporting a weekly W5 heartbeat have gone quiet >10 days: ',
             (SELECT STRING_AGG(loop_source, ', ')
              FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                            'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                            'loop:cross_model_referee_independence','loop:research_quality_feedback',
                            'loop:park_allocator']) AS loop_source
              WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
                AND NOT EXISTS (
                  SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
                  WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)))),
      TO_JSON_STRING(STRUCT(CURRENT_TIMESTAMP() AS checked_at)));
  END IF;

  -- park_allocator daily-heartbeat staleness (warning, PARK v3 immediate-binding redesign, owner
  -- directive 2026-07-26). loop:park_allocator (ops/autonomy_levels.yaml) converted shadow->active_auto
  -- in this same change and is written DAILY by D1's PARK ALLOCATION CALL (every trading day) -- NOT
  -- weekly like the constant-tuning loops in the generic block above. Folding it only into that block's
  -- flat 10-CALENDAR-day window would be semantically wrong two ways: (1) 10 calendar days is far looser
  -- than appropriate for a nominally-daily loop; (2) because D1's daily beat and W5's own weekly
  -- belt-and-suspenders beat write the IDENTICAL heartbeat source, a real multi-day D1 outage could be
  -- invisibly papered over by W5's once-a-week write resetting the shared clock before the generic
  -- 10-day window ever trips -- defeating the point of watching a daily loop at all. This dedicated block
  -- uses a TRADING-day count via state.market_calendar (same idiom as bigquery/92_park_allocator.sql's
  -- 2026-07-19 park_switch_budget cooldown fix and bigquery/76_owner_confirmation_liveness.sql's
  -- trading_days_since_last_fill -- NOT a naive calendar-day DATE_DIFF, the exact bug class that fix
  -- removed) and a tighter >=3-trading-day threshold. Self-bootstrapping: park_last_beat IS NULL (no
  -- heartbeat row ever) skips the whole block -- no alarm before the loop's first-ever beat; park_allocator
  -- has beaten daily since 2026-07-19, so this arms immediately on apply. Deliberately expressed via a
  -- scalar `source = 'loop:park_allocator'` equality, NEVER an UNNEST(['loop:...']) literal -- adding a
  -- THIRD, single-member UNNEST literal here would shrink
  -- scripts/check_autonomy_consistency.py's cadence_detection_loops() intersection-of-UNNEST-lists to
  -- {park_allocator} alone and false-flag every other constant-tuning loop above as unmonitored. Reuses
  -- the same category ('constant_tuning_loop_heartbeat_missing') as the generic block so it rides the
  -- same emailer/auto-resolve wiring; sp_raise_alert_once dedups on (category, message), so the message
  -- text below is held stable (keyed on the frozen last-beat timestamp, not on the day this check runs)
  -- while the staleness persists, and is distinct from the generic block's message (which never names
  -- park_allocator, since park_allocator's own beats keep it out of that block's stale-source list under
  -- normal operation).
  BEGIN
    DECLARE park_last_beat TIMESTAMP;
    DECLARE park_trading_days_since_beat INT64;
    SET park_last_beat = (
      SELECT MAX(beat_ts) FROM `stock-trading-498512.ops.heartbeat` WHERE source = 'loop:park_allocator');
    IF park_last_beat IS NOT NULL THEN
      SET park_trading_days_since_beat = (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(park_last_beat, 'America/Denver')
          AND mc.cal_date <= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`));
      IF park_trading_days_since_beat >= 3 THEN
        CALL `stock-trading-498512.ops.sp_raise_alert_once`(
          'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
          CONCAT('loop:park_allocator (active_auto, daily D1 heartbeat) has gone quiet >=3 trading days ',
                 '-- last beat ', CAST(park_last_beat AS STRING), '. This is the DEDICATED trading-day-aware ',
                 'check (not the flat 10-calendar-day window above) because D1 writes this heartbeat every ',
                 'trading day, not weekly.'),
          TO_JSON_STRING(STRUCT(park_last_beat AS last_beat,
                                 park_trading_days_since_beat AS trading_days_since_beat,
                                 CURRENT_TIMESTAMP() AS checked_at)));
      END IF;
    END IF;
  END;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;

-- ===== ops.alert_policy registration (STATEMENT 4) =====
-- Registers process_constant_evidence_invalidated (the Statement 3 WARNING block) as latching = TRUE —
-- same shape as bigquery/139_append_only_violation_alert_class.sql, but written as a MERGE (not a
-- guarded INSERT) so re-applying this file, or a future file that revises the resolve_rule/note text for
-- this category, stays idempotent and safe.
MERGE `stock-trading-498512.ops.alert_policy` T
USING (
  SELECT p.category, p.latching, p.resolve_rule, p.note
  FROM UNNEST([
    STRUCT(
      'process_constant_evidence_invalidated' AS category,
      TRUE AS latching,
      CONCAT(
        'NEVER auto-resolves -- an adjudication, not a re-checkable condition. Close by hand only, ',
        'after: (a) reading state.process_constant_evidence_drift for the flagged (routine, ',
        'deadline_key, change_key) row and its obs_detail array (persisted vs recomputed p90 per ',
        'cycle_date); (b) deciding whether the ORIGINAL evidence was genuinely manufactured (an ',
        'artifact of a metric-formula bug later corrected, as bigquery/89 did on 2026-08-04 for ',
        'backfilled rows) or whether the constant should stay changed on OTHER grounds despite the ',
        'recomputed p90 no longer showing the same threat; (c) on a REVERT decision: edit the ',
        'version-controlled deadline/threshold back in a new numbered bigquery file (bigquery/142 is ',
        'the pattern), run scripts/check_cadence_consistency.py, then INSERT the documented ',
        'REVERT-suffixed change_key row into ops.process_constant_change_log (see the bigquery/142 ',
        'header for the exact statement) -- this ALSO silences this category going forward, since the ',
        'view excludes a change once its own REVERT-suffixed sibling row exists; (d) on an ACCEPT ',
        'decision: no REVERT row is written, so this category WILL re-fire nightly on the identical ',
        'finding until a REVERT row is eventually recorded -- state that tradeoff explicitly in the ',
        'resolved_note; (e) resolve with UPDATE ops.alerts SET resolved=TRUE, ',
        'resolved_note=<decision + citation>, scoped by alert_id.'
      ) AS resolve_rule,
      CONCAT(
        'PROCESS-CONSTANT INTEGRITY CLASS, introduced bigquery/142_cadence_deadline_revert_and_',
        'evidence_drift.sql (2026-08-06). Detector: state.process_constant_evidence_drift, ',
        're-validating an ALREADY-APPLIED W5 process_reliability autotune ',
        '(ops.process_constant_change_log) against the analytics.routine_health_scorecard CURRENT ',
        'predicate set, bound at each justifying observation own observed_ts so data landing after ',
        'the observation cannot contaminate the reconstruction (see the bigquery/142 header). Closes ',
        'a structural gap in state.process_constant_oos_watch (bigquery/72): that fail-safe only ',
        'detects a persisted POST-change threat (the change did not work); this detects a persisted ',
        'PRE-change threat that was never real (the evidence was manufactured). FOUNDING CASE, measured ',
        '2026-08-06 by read-only query against the detector view BEFORE this class was ever raised as an ',
        'alert (this note is authored at the same time as the detector, so it asserts a MEASUREMENT, not ',
        'a firing history -- the first genuine firing may post-date it): D1 cadence_watch_deadline_local ',
        'read persisted p90 1279/1275/1279 vs recomputed ',
        '1030/993/1006, all outside the +/-90-minute band -- bigquery/89 (2026-08-04) excluded ',
        'marker-backfilled rows (log_ts equal to backfill time, not completion time) from the ',
        'percentile, and the D1 evidence was manufactured entirely by that measurement artifact. D2 ',
        'and D3 evidence was genuine (recomputed p90 matched the persisted band) and read ',
        'evidence_invalidated=FALSE.'
      ) AS note)
  ]) AS p
) S
ON T.category = S.category
WHEN MATCHED THEN
  UPDATE SET latching = S.latching, resolve_rule = S.resolve_rule, note = S.note, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (category, latching, resolve_rule, note) VALUES (S.category, S.latching, S.resolve_rule, S.note);

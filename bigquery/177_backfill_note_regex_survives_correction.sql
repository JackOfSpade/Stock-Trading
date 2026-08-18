-- 177_backfill_note_regex_survives_correction.sql (2026-08-18)
-- Project: stock-trading-498512. Apply after 176_decouple_embedding_health_from_trading_gate.sql.
--
-- SUPERSEDES bigquery/172's definition of state.run_log_unpaired_terminal and bigquery/171's
-- definition of analytics.routine_health_scorecard. Nothing else in either file changes. Deliberately
-- NOT touching bigquery/142's own copy of this regex (state.process_constant_evidence_drift's
-- `recomputed` CTE) — that copy is a POINT-IN-TIME FORENSIC RECONSTRUCTION of what bigquery/89's
-- formula returned as of specific past `observed_ts` values, all predating this fix by weeks; it must
-- stay byte-identical to what actually ran then, not track this file's improvement.
--
-- ===== WHY =====
-- Found investigating the 2026-08-18 01:16 MT run_log_start_row_missing alert (payload: W5/2026-08-16,
-- run_id c27d3408, status=halted).
--
-- That row IS a genuine ops.sp_backfill_run_log_from_markers auto-backfill (W5 halted at pre-flight on
-- 2026-08-16 when BigQuery de-authorized before it could log a 'started' row at all — see
-- bigquery/175's header for the full phantom-completion saga). A missing 'started' row on a backfilled
-- row is bigquery/172's own documented, INTENDED exclusion ("that mechanism working as designed"), and
-- until 2026-08-17 this row's note correctly matched the exclusion: it began literally with
-- "auto-backfilled from commit marker (ops.sp_backfill_run_log_from_markers, RUNBOOK §38 self-heal): ...".
--
-- W5's 2026-08-17 run then corrected the row's STATUS (the backfill had wrongly minted 'completed';
-- the true terminal state is 'halted') and prepended an explanation to the note, PRESERVING the
-- original text verbatim after "ORIGINAL NOTE: ":
--   "CORRECTED 2026-08-17 by W5: status was auto-backfilled as \"completed\" from a commit marker
--    whose own subject and body state the run HALTED at pre-flight. ... ORIGINAL NOTE: auto-backfilled
--    from commit marker (ops.sp_backfill_run_log_from_markers, RUNBOOK §38 self-heal): git_commit=..."
-- That correction was a raw UPDATE, not ops.sp_amend_run_note (fill-only on blank notes, inapplicable
-- here) — so the "append, never prepend" discipline bigquery/170 documents for that procedure had
-- nothing to enforce it. The prepend moved "auto-backfilled" off byte position 0, which is ALL
-- '^(auto-)?backfilled' checks for, so bigquery/172's exclusion silently stopped applying to a row it
-- was written to exclude, and the SAME condition it always had (no started row) now reads as new.
--
-- This is not a one-off cosmetic gap. bigquery/172's own header already contains the precedent for
-- exactly this shape of correction — "CORRECTED 2026-08-17 by W5" — and the codebase has multiple
-- other examples of a human-authored terminal-row correction landing well after the original write
-- (A1/A2 2026-07-27 "BACKFILLED TERMINAL ROW, written 2026-07-28 by an interactive operator session";
-- SL5 2026-07-30 "BACKFILLED 2026-08-05 in interactive triage, operator-authorized"). Any future
-- correction of an auto-backfilled row that explains itself the same way (lead with the correction,
-- preserve the original note inline) reproduces this exact false alarm.
--
-- ===== THE FIX, AND WHY IT DOES NOT WEAKEN THE ANCHOR =====
-- Add ONE additional, unanchored alternative: the literal 5-word phrase
-- "auto-backfilled from commit marker" — the exact, invariant FORMAT() literal
-- ops.sp_backfill_run_log_from_markers writes (bigquery/38 line ~140) — matched ANYWHERE in the note,
-- not just at position 0. The original anchored `^(auto-)?backfilled` alternative is kept verbatim, so
-- every existing exclusion (the "Backfilled: ...", "Backfilled post-hoc ...", "BACKFILLED TERMINAL
-- ROW..." human-authored forms, none of which get re-corrected with this literal phrase) is unaffected.
--
-- NOT a loose `LIKE '%backfill%'` — bigquery/89's own header measured that a bare substring search
-- would wrongly swallow 6 D2 rows and 1 D3 row that merely DISCUSS backfilling ("no backfill
-- snapshots", "D2 completed via marker backfill", "D1 self-healed from commit marker ... via
-- sp_backfill_run_log_from_markers"). None of those contain the full 5-word phrase in that exact word
-- order, so none match the new alternative either — verified below, not assumed.
--
-- VERIFIED against the full live ops.run_log history (no date bound) before shipping: comparing
-- old-regex vs new-regex match sets over every row with a non-null note, EXACTLY ONE row changes
-- classification — W5/2026-08-16/c27d3408, from NOT-backfilled to backfilled, i.e. from false alarm
-- to correctly excluded. Zero rows move the other direction (a previously-excluded row losing its
-- exclusion is structurally impossible: the new predicate is old-predicate OR new-alternative).
--
-- Idempotent (CREATE OR REPLACE); safe to re-run. No dbt port of either view exists, so no dbt-parity
-- mirror is owed.

-- ===== state.run_log_unpaired_terminal (was bigquery/172) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.run_log_unpaired_terminal` AS
WITH terminal AS (
  SELECT routine, run_date, status, log_ts, run_id
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 3 DAY)
    AND status IN ('completed', 'failed', 'halted')
    AND routine NOT LIKE 'FIRE_DRILL%'
    AND routine <> 'SELFHEAL_RUN_LOG'
    -- HARDENED 2026-08-18 (bigquery/177): was '^(auto-)?backfilled' alone, anchored to the note's
    -- first character. A later human correction of a backfilled row's STATUS (see file header) can
    -- legitimately prepend explanatory text ahead of the preserved original note, which moves
    -- "auto-backfilled" off position 0 without the row becoming any less genuinely backfilled. The
    -- added alternative is the literal, invariant phrase the backfill writer itself emits, matched
    -- anywhere in the note — see file header for the false-positive check against the rest of history.
    AND NOT REGEXP_CONTAINS(COALESCE(note, ''), r'(?i)(^(auto-)?backfilled|auto-backfilled from commit marker)')
)
SELECT
  t.routine,
  t.run_date,
  t.status,
  t.log_ts,
  t.run_id,
  CURRENT_TIMESTAMP() AS checked_at
FROM terminal t
WHERE NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.ops.run_log` s
  WHERE s.status = 'started'
    AND s.run_date = t.run_date
    AND REGEXP_REPLACE(s.routine, r'[·._-]', '') = REGEXP_REPLACE(t.routine, r'[·._-]', ''));

-- ===== analytics.routine_health_scorecard (was bigquery/171) =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.routine_health_scorecard` AS
WITH runs AS (
  SELECT REPLACE(routine, '·', '_') AS routine, run_date, status, log_ts,
    DATETIME_DIFF(DATETIME(log_ts, 'America/Denver'), DATETIME(run_date), MINUTE) AS completion_minute_of_day,
    -- HARDENED 2026-08-18 (bigquery/177) — see state.run_log_unpaired_terminal above and this file's
    -- header for the full rationale; the two views share the exclusion and must stay in step.
    REGEXP_CONTAINS(COALESCE(note, ''), r'(?i)(^(auto-)?backfilled|auto-backfilled from commit marker)') AS is_backfilled
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
),
per_routine AS (
  SELECT
    routine,
    COUNT(*) AS n_log_rows_90d,
    COUNTIF(status = 'completed') AS n_completed_90d,
    COUNTIF(status = 'failed') AS n_failed_90d,
    COUNTIF(status = 'halted') AS n_halted_90d,
    APPROX_QUANTILES(IF(status = 'completed' AND NOT is_backfilled, completion_minute_of_day, NULL), 100)[OFFSET(50)] AS p50_completion_minute_of_day,
    APPROX_QUANTILES(IF(status = 'completed' AND NOT is_backfilled, completion_minute_of_day, NULL), 100)[OFFSET(90)] AS p90_completion_minute_of_day,
    COUNTIF(status = 'completed' AND is_backfilled) AS n_backfilled_excluded_90d
  FROM runs
  GROUP BY routine
),
dep_gate_aborts AS (
  SELECT REPLACE(source, '·', '_') AS routine, COUNT(*) AS n_dep_gate_aborts_90d
  FROM `stock-trading-498512.ops.alerts`
  WHERE category = 'missing_dependency'
    AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY REPLACE(source, '·', '_')
),
retry_agg AS (
  SELECT
    REPLACE(routine, '·', '_') AS routine,
    COUNTIF(token_type = 'RETRY') AS n_retry_events,
    COUNTIF(token_type = 'RETRY' AND outcome = 'exhausted') AS n_retries_exhausted,
    COUNTIF(token_type = 'DEPWAIT') AS n_dep_waits,
    COUNTIF(token_type = 'DEPWAIT' AND outcome = 'futile') AS n_dep_wait_futile,
    COUNTIF(token_type = 'DEPWAIT' AND refired IS NOT NULL AND refired != 'none') AS n_active_refires,
    ROUND(SUM(IF(token_type IN ('RETRY', 'DEPWAIT'), waited_s, NULL)) / 60) AS total_wait_minutes
  FROM `stock-trading-498512.state.retry_telemetry`
  GROUP BY REPLACE(routine, '·', '_')
)
SELECT
  p.routine,
  p.n_log_rows_90d,
  p.n_completed_90d, p.n_failed_90d, p.n_halted_90d,
  p.n_backfilled_excluded_90d,
  p.p50_completion_minute_of_day, p.p90_completion_minute_of_day,
  COALESCE(d.n_dep_gate_aborts_90d, 0) AS n_dep_gate_aborts_90d,
  COALESCE(r.n_retry_events, 0) AS n_retry_events,
  COALESCE(r.n_retries_exhausted, 0) AS n_retries_exhausted,
  COALESCE(r.n_dep_waits, 0) AS n_dep_waits,
  COALESCE(r.n_dep_wait_futile, 0) AS n_dep_wait_futile,
  COALESCE(r.n_active_refires, 0) AS n_active_refires,
  COALESCE(r.total_wait_minutes, 0) AS total_wait_minutes,
  (p.n_log_rows_90d >= 20) AS min_n_met
FROM per_routine p
LEFT JOIN dep_gate_aborts d USING (routine)
LEFT JOIN retry_agg r USING (routine)
ORDER BY p.routine;

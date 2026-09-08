-- Parallel-run dbt port of bigquery/231_run_outcome_notification_fire_drill.sql:state.run_log_unalerted_problems — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT
  r.run_id,
  r.routine,
  r.run_date,
  r.status,
  r.log_ts,
  SUBSTR(TRIM(COALESCE(r.error_msg, '')), 1, 400) AS error_detail,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ source('ops', 'run_log') }} r
WHERE r.run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 14 DAY)
  -- FIX 3 addition (bigquery/231_run_outcome_notification_fire_drill.sql, 2026-09-08). FIRE_DRILL%
  -- rows are EXCLUDED here, not merely cleaned up after the drill runs -- so
  -- ops.sp_fire_drill_run_outcome_notification (bigquery/231) aborting BETWEEN inserting its
  -- synthetic 'failed' row (P1 exercise) and its own unconditional cleanup cannot make this
  -- backstop cry wolf about a stray drill row. Every other run_log-based check in this repo
  -- already special-cases FIRE_DRILL% for the identical reason (state.run_log_unpaired_terminal's
  -- chain: bigquery/172_run_log_unpaired_terminal.sql, 186_monitor_promoted_autoage.sql,
  -- 205_alert_message_stability.sql, 227_alert_message_stability_ordering.sql) -- this view was the
  -- one left unprotected, closed here.
  AND r.routine NOT LIKE 'FIRE_DRILL%'
  AND (
    r.status IN ('failed', 'halted')
    OR (r.status = 'completed' AND TRIM(COALESCE(r.error_msg, '')) != '')
  )
  AND NOT EXISTS (
    SELECT 1
    FROM {{ source('ops', 'alerts') }} a
    -- CATEGORY IS PAIRED TO THE ROW'S STATUS CLASS, not left as a two-element IN (...) — corrected
    -- 2026-09-08 during this file's own adversarial review, before landing. With a bare
    -- `category IN ('routine_run_failed','routine_run_warning')`, a routine that HALTED and then
    -- re-ran and logged `completed` with an `error_msg` on the SAME day had its second row's
    -- witness satisfied by the FIRST row's `routine_run_failed` alert — so a genuinely swallowed
    -- `routine_run_warning` raise (the exact thing this view exists to catch) read as covered.
    -- P1 raises `routine_run_failed` for failed/halted and `routine_run_warning` for
    -- completed-with-error, so the witness must ask for the category that row should have produced.
    WHERE a.category = IF(r.status IN ('failed', 'halted'), 'routine_run_failed', 'routine_run_warning')
    -- P1-SOURCED ALERTS ONLY. ops.sp_report_run_issue (P2 above) also raises `routine_run_warning`
    -- for a (routine, run_date), and its payload is the ONLY one of the two that carries
    -- `issue_key` — so that key is the discriminator. A routine voluntarily reporting an in-run
    -- issue is not evidence that sp_log_run's MECHANICAL raise fired, and letting a P2 row satisfy
    -- this witness would mask precisely the swallowed-raise case (C8) this view is the third
    -- independent check for.
      AND JSON_VALUE(a.payload, '$.issue_key') IS NULL
      AND JSON_VALUE(a.payload, '$.routine') = r.routine
      AND JSON_VALUE(a.payload, '$.run_date') = CAST(r.run_date AS STRING)
    -- DELIBERATELY NOT KEYED ON run_id, though P1's payload carries one and an exact per-row match
    -- looks stricter. `sp_raise_alert_once` dedups on (category, message): two identical failures
    -- of the same routine on the same day render the SAME message, so the second raise is
    -- correctly SUPPRESSED and no alert ever carries the second run_id. A run_id-keyed witness
    -- would therefore flag that second row as unalerted every night for 14 days — a permanently-red
    -- advisory, which this repo treats as broken (feedback: a permanently-red advisory is broken).
    -- One alert per (routine, run_date, status class) IS the intended delivery, and this predicate
    -- asks exactly that question.
    -- NOT filtered on `NOT resolved`: P1's alerts auto-age out after 7 days (#14 allowlist), and
    -- keying on open-ness would make this view re-raise forever once they close.
  )

-- Parallel-run dbt port of bigquery/177_backfill_note_regex_survives_correction.sql:state.run_log_unpaired_terminal — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH terminal AS (
  SELECT routine, run_date, status, log_ts, run_id
  FROM {{ source('ops', 'run_log') }}
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
  FROM {{ source('ops', 'run_log') }} s
  WHERE s.status = 'started'
    AND s.run_date = t.run_date
    AND REGEXP_REPLACE(s.routine, r'[·._-]', '') = REGEXP_REPLACE(t.routine, r'[·._-]', ''))

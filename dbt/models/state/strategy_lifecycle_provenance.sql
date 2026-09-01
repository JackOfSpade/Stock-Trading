-- Parallel-run dbt port of bigquery/190_strategy_lifecycle_provenance_repair.sql:state.strategy_lifecycle_provenance — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH ranked AS (
  SELECT
    strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
    ROW_NUMBER()  OVER (PARTITION BY strategy_code ORDER BY event_ts ASC, event_id ASC) AS rn_earliest,
    COUNT(*)      OVER (PARTITION BY strategy_code, event_ts)                           AS n_at_this_ts,
    MAX(event_ts) OVER (PARTITION BY strategy_code)                                     AS latest_ts,
    -- The creation row is definitionally the one with NO prior state. Counting them per code is what
    -- makes CLASS 1 DETECTION independent of row order -- see the note on CLASS 1 below.
    COUNTIF(from_state IS NULL) OVER (PARTITION BY strategy_code)                       AS n_creation_rows
  FROM {{ source('events', 'strategy_lifecycle') }}
),
findings AS (
  -- CLASS 1 -- the code has NO creation row at all: every row it owns declares a prior state, so the
  -- log never records the code entering the lifecycle. H's defect, repaired above.
  --
  -- DETECTION IS ON THE AGGREGATE (n_creation_rows = 0), NOT on "the earliest row has a from_state"
  -- (adversarial review, 2026-08-21). The earlier formulation tested rn_earliest = 1, whose ORDER BY
  -- falls back to `event_id ASC` on an event_ts tie -- the exact mirror of the `event_id DESC` UUID
  -- coin-flip this file documents for CLASS 2 and state.strategy_roster. F and G each have two rows
  -- tied to the microsecond, so under that formulation CLASS 1 was correct on them only because their
  -- UUIDs happened to sort the right way; the other draw would have reported missing_creation_row for
  -- a code whose creation row demonstrably exists. Counting NULL from_state rows per code cannot tie,
  -- so the detection is now order-independent by construction. `rn_earliest = 1` is retained ONLY to
  -- pick one witness row per offending code for the message -- cosmetic, and it cannot affect whether
  -- the finding fires.
  SELECT 'missing_creation_row' AS finding_class,
         strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
         CONCAT('events.strategy_lifecycle: strategy ', strategy_code,
                ' has no creation row -- its earliest row declares from_state=',
                IFNULL(from_state, 'NULL'),
                ' and no row anywhere records ', strategy_code,
                ' entering the lifecycle from no prior state') AS message
  FROM ranked
  WHERE rn_earliest = 1 AND n_creation_rows = 0

  UNION ALL

  -- CLASS 2 -- two or more rows tie at the code's latest event_ts, so
  -- state.strategy_roster.current_state is settled by the event_id (UUID) tiebreak rather than by the
  -- order the writing routine intended. F/G's defect.
  SELECT 'ambiguous_latest_row',
         strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
         CONCAT('events.strategy_lifecycle: ', CAST(n_at_this_ts AS STRING), ' rows for strategy ',
                strategy_code, ' share the latest event_ts (', CAST(event_ts AS STRING),
                ') -- state.strategy_roster.current_state is decided by the event_id UUID tiebreak,',
                ' not by the intended transition order') AS message
  FROM ranked
  WHERE event_ts = latest_ts AND n_at_this_ts > 1
)
SELECT
  f.*,
  -- ACCEPTED HISTORICAL -- pinned to the exact (code, microsecond) of the two 2026-07-28 SL1 pairs.
  -- Both are terminal REJECTED candidates whose tiebreak demonstrably resolves the RIGHT way and
  -- cannot change (event_id is immutable and no further row will ever be written for a rejected
  -- code), and the table is append-only so they cannot be restamped. Pinned narrowly by timestamp
  -- rather than by code alone so that a NEW tie on F or G would still alert. Do NOT widen this.
  (f.finding_class = 'ambiguous_latest_row'
   AND f.strategy_code IN ('F', 'G')
   AND f.event_ts = TIMESTAMP '2026-07-28 06:10:29.279889+00') AS accepted_historical
FROM findings f

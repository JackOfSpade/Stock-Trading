-- Singular test (passes when ZERO rows): a position's thesis-invalidation criteria must never
-- REGRESS to NULL. Flags any position_key whose LATEST events.position_events row has a NULL
-- invalidation_status while an EARLIER row for that same key had it populated.
--
-- Added 2026-08-04 (ops.alerts 07125db5, D1 invalidation_mirror_dropped; repair bigquery/137).
--
-- WHY THIS CLASS NEEDS A MECHANICAL GUARD:
-- state.current_positions is PURE LATEST-ROW-WINS ON EVERY COLUMN with NO coalescing
-- (bigquery/01_schema.sql:129-133), so a column merely OMITTED from a session's INSERT is not
-- "unspecified" -- it is NULLed for that position. invalidation_status is written ONCE, at
-- staging time, by the session that constructed the thesis; every later row for that key (D2a
-- Step 0 fill-reconciliation OPEN, D2 exit-staging EXIT_PENDING, a CLOSE, an ADJUST, a
-- SPLIT_ADJUST, or a hand-written interactive row) must echo it forward or it is destroyed. On
-- 2026-08-03 one D2a Step 0 batch silently dropped it on three positions at once (D:GEV:2026-08-03,
-- B:MTZ:2026-08-03, B:MDT:2026-06-17). Nothing caught it: the only reason it surfaced at all is
-- that D1's Rev 40 add HARD GATE incidentally noticed GEV's invalidation_criteria_evaluable had
-- flipped FALSE a day later. Cost of a miss is not cosmetic -- the position becomes structurally
-- ineligible for adds and drops out of D1's daily thesis-invalidation sweep.
--
-- WHY "REGRESSED", NOT "IS NULL":
-- A plain IS-NULL test would flag every legacy position that never had criteria recorded, which
-- is a DIFFERENT, already-adjudicated condition (bigquery/117 backfilled those in 2026-07-30 and
-- marked the two genuine cases with an explicit NOT_DISCRETELY_RECORDED_AT_ENTRY payload). Keying
-- on the populated -> NULL TRANSITION isolates the write-path defect and cannot false-positive on
-- honest legacy nulls. It is also why NOT_DISCRETELY_RECORDED_AT_ENTRY counts as populated here:
-- that marker is real content whose loss (as happened to B:MDT) re-hides the very "no data" vs
-- "no criteria BY DESIGN" distinction bigquery/117 created it to make legible.
--
-- SCOPE IS DELIBERATELY ALL POSITIONS, NOT JUST OPEN ONES: two of the three 2026-08-03 casualties
-- were on their way out (an EXIT_PENDING and a CLOSE), and the closed record is what W5
-- calibration and any post-hoc thesis review read. Restricting to open positions would have
-- caught GEV and missed MDT entirely.
--
-- WHY ONLY invalidation_status, WHEN THE SAME WRITE DROPPED MORE:
-- The 2026-08-03 batch also nulled D:GEV:2026-08-03's ltcg_date and conviction, so a wider guard
-- is tempting. It was measured and rejected: extending this test to ltcg_date / conviction /
-- convergence_target / time_exit_date / source_thesis_ref / contract_id flags 12 position_keys
-- today, of which 9 are CLOSED positions whose terminal CLOSE row drops conviction /
-- convergence_target / time_exit_date -- the long-standing NORM for a CLOSE row across this
-- table, not a defect. Shipping that would put the test permanently red and train everyone to
-- ignore it. invalidation_status is the one column with NO other source (assessed once at
-- staging time, recorded nowhere else), so its loss is unrecoverable rather than re-derivable,
-- and it is the only one whose regression set is currently empty after bigquery/137.
-- RESIDUAL GAP, stated plainly: a populated->NULL regression on ltcg_date or conviction for an
-- OPEN position is real and operationally material (M4 STEP C reads ltcg_date for tax-aware exit
-- timing) and is NOT guarded here. Closing it needs the CLOSE-row norm cleaned up first.
--
-- TIE-BREAK: ORDER BY event_ts DESC mirrors state.current_positions; event_id DESC is added only
-- as a deterministic tiebreaker so the test cannot flap. Verified 2026-08-04 that no position_key
-- currently has two rows sharing an event_ts, so the tiebreaker is defensive, not load-bearing.
--
-- JSON NULL: invalidation_status is a JSON column, so a SQL NULL and a JSON `null` literal are
-- distinct values that both mean "no criteria". Both are treated as absent on the latest row and
-- as not-populated on the history side, so neither can smuggle a regression past this test.

WITH ranked AS (
  SELECT
    position_key,
    event_id,
    event_ts,
    event_type,
    status,
    invalidation_status,
    ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC, event_id DESC) AS rn
  FROM {{ source('events', 'position_events') }}
),
latest AS (
  SELECT * FROM ranked WHERE rn = 1
),
ever_populated AS (
  SELECT
    position_key,
    COUNTIF(invalidation_status IS NOT NULL
            AND TO_JSON_STRING(invalidation_status) <> 'null') AS n_rows_with_criteria
  FROM ranked
  GROUP BY position_key
)
SELECT
  l.position_key,
  l.event_id   AS latest_event_id,
  l.event_ts   AS latest_event_ts,
  l.event_type AS latest_event_type,
  l.status     AS latest_status,
  e.n_rows_with_criteria
FROM latest l
JOIN ever_populated e USING (position_key)
WHERE (l.invalidation_status IS NULL OR TO_JSON_STRING(l.invalidation_status) = 'null')
  AND e.n_rows_with_criteria > 0

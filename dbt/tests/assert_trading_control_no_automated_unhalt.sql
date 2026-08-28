-- Singular test (passes when ZERO rows): no AUTOMATED row may be the thing that clears a halt.
--
-- Added 2026-08-28 (triage of control_plane_insert alert 637a7fe1). bigquery/23_trading_control.sql's
-- header states the discipline -- "an auto halt is cleared by an explicit manual INSERT, never by
-- another automated row" -- and records that it is NOT enforced in SQL. This test is that enforcement,
-- and it keys on the RESULT STATE rather than on any writer, so it holds for a repo-authored INSERT, a
-- live-applied procedure, or an out-of-band interactive one.
--
-- WHY IT IS NEEDED. state.trading_control_latest / state.trading_enabled / state.trading_enabled_mechanical
-- each read halt_all off the SINGLE latest row by control_ts with NO mode filter. So a halt_all=FALSE row
-- landing after a genuine halt_all=TRUE row silently UN-HALTS the whole book, whatever its mode. The
-- 'entries_halted' / 'entries_halted_cleared' audit markers D2a writes are exactly such rows; both arms of
-- its Claude_Task_Plan.md bullet now carry an explicit halt_all guard, but prose binds only the routine
-- that reads it -- a future writer inherits nothing. This test catches the state no matter who caused it.
--
-- PREDICATE: fail if the latest row is halt_all=FALSE, is NOT the sanctioned manual operator clear
-- (mode='manual' AND set_by='operator'), and some EARLIER halt_all=TRUE row has no manual clear after it.
-- The seed row (mode='manual', set_by='backfill-2026-07-03') can never trip it: it is the FIRST row, so no
-- earlier halt exists to strand.
--
-- CURRENTLY SATISFIED, NOT VACUOUS: as of 2026-08-28 halt_all=TRUE has never been written to this table by
-- anyone (measured over its full lifetime -- every INSERT job ever issued against it wrote FALSE), so the
-- inner EXISTS is empty and the test passes. It starts doing real work the moment a halt is first set,
-- which is precisely when the un-halt becomes possible. Do NOT delete it as dead code on that basis.

WITH latest AS (
  SELECT halt_all, mode, set_by, control_ts
  FROM {{ source('ops', 'trading_control') }}
  QUALIFY ROW_NUMBER() OVER (ORDER BY control_ts DESC) = 1
),
-- Set-based, NOT a correlated EXISTS: BigQuery rejects a correlated subquery whose only condition is an
-- inequality (the same limitation bigquery/194's CRITICAL 1 comment documents), so the "is there a halt
-- with no manual clear after it" question is answered with two MAX() aggregates instead of a join.
marks AS (
  SELECT
    MAX(IF(halt_all, control_ts, NULL)) AS last_halt_ts,
    MAX(IF(NOT halt_all AND mode = 'manual' AND set_by = 'operator', control_ts, NULL)) AS last_manual_clear_ts
  FROM {{ source('ops', 'trading_control') }}
)
SELECT
  l.control_ts AS masking_row_ts,
  l.mode       AS masking_row_mode,
  l.set_by     AS masking_row_set_by,
  m.last_halt_ts,
  m.last_manual_clear_ts
FROM latest l
CROSS JOIN marks m
WHERE NOT l.halt_all
  AND NOT (l.mode = 'manual' AND l.set_by = 'operator')
  AND m.last_halt_ts IS NOT NULL
  AND (m.last_manual_clear_ts IS NULL OR m.last_manual_clear_ts < m.last_halt_ts)

-- bigquery/260_guard_waivers.sql — ONE-TIME OWNER WAIVERS FOR ROUTINE GUARDS (owner directive 2026-10-20).
-- Project: stock-trading-498512. Apply after 259_live_ramp.sql.
--
-- WHY. The SAME-DAY DOUBLE-RUN GUARD (Claude_Task_Plan.md, shared Observability section) ends a routine
-- that has already logged `completed` for today's America/Denver run_date. That is the right default — it
-- closes the refire-vs-late-original race — but it also blocks a deliberate second fire the owner wants on
-- the same day (2026-10-20 02:19 UTC: SL1 fired by hand to qualify the J research lead ended in 41 s because
-- the Candidate I intake had completed that Denver date). Until now the only ways around it were to wait for
-- Denver midnight or to edit the guard, neither of which is a control. This file is the control: a durable,
-- single-use, owner-granted waiver that a guard consults and consumes, leaving an audit trail.
--
-- SHAPE. Append-only EVENT table: GRANTED / CONSUMED / REVOKED rows keyed by waiver_id. A waiver names ONE
-- routine, ONE guard and ONE Denver run_date; `state.guard_waivers_open` shows the GRANTED rows for today's
-- run_date with no CONSUMED/REVOKED row, which is what a guard reads. A routine that finds its waiver writes
-- the CONSUMED row before proceeding, so a second same-day fire finds nothing and ends on the guard as usual.
-- A waiver expires with its run_date (the view filters on state.trading_day_today) and never widens any other
-- gate: the arsenal kill-switch, the dependency gate and the trading-enable gate are untouched.
--
-- WHO WRITES. GRANTED rows: the owner, in an interactive session (actor = 'owner:<session or name>'), or an
-- owner-directed routine that the directive names. CONSUMED rows: the guarded routine itself. REVOKED rows:
-- the owner. Nothing here is written by a scheduled routine on its own initiative.
--
-- GUARD VOCABULARY (the `guard` column): 'same_day_double_run' is the only consumer wired today. A later
-- guard that wants a waiver adds its own literal here and its own consult-and-consume clause in the plan;
-- an unknown literal matches nothing and waives nothing.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.guard_waivers` (
  event_id   STRING    DEFAULT GENERATE_UUID() NOT NULL,
  event_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL,
  waiver_id  STRING    NOT NULL,   -- '<routine>-<guard>-<run_date>-<short tag>'; stable across its GRANTED/CONSUMED/REVOKED events
  routine    STRING    NOT NULL,   -- the routine id the guard belongs to, e.g. 'SL1'
  guard      STRING    NOT NULL,   -- 'same_day_double_run' (see GUARD VOCABULARY)
  run_date   DATE      NOT NULL,   -- the America/Denver run_date the waiver applies to (state.trading_day_today.today at grant time)
  event      STRING    NOT NULL,   -- 'GRANTED' | 'CONSUMED' | 'REVOKED'
  actor      STRING    NOT NULL,   -- who wrote this event: 'owner:<session>' for GRANTED/REVOKED, '<routine>:<session_id>' for CONSUMED
  note       STRING                -- why (GRANTED), or the run that consumed it (CONSUMED)
)
OPTIONS (description = 'One-time owner waivers for routine guards (Claude_Task_Plan.md shared Observability section, ONE-TIME OWNER WAIVER clause; bigquery/260). Append-only event log: GRANTED by the owner for one routine, one guard, one Denver run_date; CONSUMED by the routine that honoured it; REVOKED by the owner. state.guard_waivers_open is what a guard reads.');

CREATE OR REPLACE VIEW `stock-trading-498512.state.guard_waivers_open` AS
WITH td AS (
  SELECT today FROM `stock-trading-498512.state.trading_day_today`
),
granted AS (
  SELECT waiver_id, routine, guard, run_date, actor AS granted_by, note AS reason, event_ts AS granted_ts
  FROM `stock-trading-498512.ops.guard_waivers`
  WHERE event = 'GRANTED'
),
closed AS (
  SELECT DISTINCT waiver_id
  FROM `stock-trading-498512.ops.guard_waivers`
  WHERE event IN ('CONSUMED', 'REVOKED')
)
SELECT g.waiver_id, g.routine, g.guard, g.run_date, g.granted_by, g.reason, g.granted_ts
FROM granted g
CROSS JOIN td
LEFT JOIN closed c USING (waiver_id)
WHERE c.waiver_id IS NULL
  AND g.run_date = td.today;

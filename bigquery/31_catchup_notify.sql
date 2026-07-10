-- Catch-up-available notification (self-improvement audit WO-8 part 1, 2026-07-03). Project:
-- stock-trading-498512. Apply after 12_cadence_monitor.sql (state.cadence_watch).
--
-- WHY: state.cadence_watch.needs_attention already alarms (critical, category=missed_run,
-- bigquery/scheduled_queries/cadence_check.sql) the instant ANY of D1/D2/D3 misses its 21:00 MT
-- completion deadline — correct, but it treats every miss identically. D1 (market scan) and D3
-- (calendar/queue hygiene) carry NO live order-crafting or intraday-price dependency: firing the
-- trigger LATE produces exactly the output a same-day run would have, so a miss is fully, cheaply
-- self-healing. D2 (and D2a once cut over) is deliberately EXCLUDED — it crafts orders off live
-- intraday quotes, so a late catch-up run is harmless to execute but does not recover the value a
-- same-day run would have had; conflating the two would tell the operator "no rush" about something
-- that, in spirit, still is one. The existing missed_run critical remains the only signal for D2.
--
-- catchup_safe is a short, hand-maintained list (deliberately NOT derived from ops.routine_catalog /
-- ops/cadence.yaml's monitor_class, which classify by SCHEDULE shape, not by intraday-price dependency).
-- Update it if D2a is cut over (its reconciliation/snapshot/TWR-maintenance scope carries no discretionary
-- order crafting, so it would qualify) or if a routine's scope changes.
CREATE OR REPLACE VIEW `stock-trading-498512.state.catchup_available` AS
WITH catchup_safe_routines AS (
  -- SL3 (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive): the daily incubation
  -- monitor carries NO live order-crafting or intraday-price dependency — it computes end-of-day
  -- forward-test signals / simulated fills off the same daily marks D2a ingests and hands the only
  -- capital step (the PROBE launch) to SL5, so a late catch-up run reproduces exactly what a same-day
  -- run would have produced (identical rationale to D1/D3). It is the only SL routine eligible here:
  -- SL1/SL2/SL4/SL5 are not daily, so they never enter state.cadence_watch's alarm set (they are
  -- covered by state.cadence_period_watch / state.stalled_runs instead) and cannot appear on this join.
  SELECT routine FROM UNNEST(['D1', 'D3', 'SL3']) AS routine
)
SELECT w.routine, w.schedule, w.today
FROM `stock-trading-498512.state.cadence_watch` w
JOIN catchup_safe_routines s USING (routine)
WHERE w.needs_attention;

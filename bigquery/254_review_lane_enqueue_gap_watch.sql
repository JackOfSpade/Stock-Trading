-- 254_review_lane_enqueue_gap_watch.sql (2026-10-11)
-- Project: stock-trading-498512. Apply AFTER 253_embed_pending_concurrent_dedupe.sql.
--
-- Defines state.review_lane_enqueue_gap (NEW). SUPERSEDES nothing; it is the "enqueue-cadence detector
-- alongside bigquery/132" that AR_att's `review_lane_enqueue_silence_unwatched` notice (ops.alerts
-- b5aede6d-e2ad-4df1-abc1-5d47d2251619) named as the durable fix.
--
-- WHY. state.queue_driven_silence_watch (bigquery/132) reads ONLY ops.run_log, so it measures AR_att/AR_orc
-- RUN cadence, which stays healthy for as long as the cron fires whatever the producers do; D3's
-- queue_item_stale and the AR_att RESIDUAL SWEEP act only on rows that EXIST; state.queue_venue_claim_unwired
-- tests a row's claimed drainer, not the absence of rows. A total PRODUCER stall in the PENDING_REVIEW lane
-- was therefore invisible. This view measures it from the lane itself: days since the last distinct
-- (America/Denver) date on which a status='pending' PENDING_REVIEW row was written, against the largest gap
-- between consecutive enqueue dates observed in the lane's own history.
--
-- MEASURED at authoring (2026-10-11, Denver plane): 15 distinct enqueue dates, gaps 27,6,3,4,3,4,2,6,5,2,1,3,27,3,
-- max historical gap 27, last enqueue 2026-10-05 (current gap 6) -> NOT stalled. The lane is bursty (month-start
-- divergence-review batch plus ad hoc), so the threshold is the lane's own worst observed gap, not a constant.
-- The current open gap is excluded from the historical max so a stall cannot raise its own threshold.
--
-- CONSUMER: W5 SPEC-DEFECT NOTICE INTAKE (Claude_Task_Plan.md, "REVIEW-LANE ENQUEUE-GAP CHECK"). Read-only view;
-- the view touches no table and raises no alert; the ops.alert_policy row for its raise is registered at the foot of this file.
CREATE OR REPLACE VIEW `stock-trading-498512.state.review_lane_enqueue_gap` AS
WITH dts AS (
  SELECT DISTINCT DATE(event_ts, 'America/Denver') AS d
  FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'PENDING_REVIEW' AND status = 'pending'
),
gaps AS (
  SELECT d, DATE_DIFF(d, LAG(d) OVER (ORDER BY d), DAY) AS gap_days
  FROM dts
)
SELECT
  MAX(d)                                                        AS last_enqueue_date,
  CURRENT_DATE('America/Denver')                                AS today_denver,
  DATE_DIFF(CURRENT_DATE('America/Denver'), MAX(d), DAY)        AS current_gap_days,
  MAX(gap_days)                                                 AS max_historical_gap_days,
  COUNT(*)                                                      AS n_enqueue_dates,
  DATE_DIFF(CURRENT_DATE('America/Denver'), MAX(d), DAY) > MAX(gap_days) AS is_stalled
FROM gaps;

-- ops.alert_policy registration for the raise the W5 REVIEW-LANE ENQUEUE-GAP CHECK makes on this view
-- (registered live by the W5 2026-10-11 orchestrator in the same session; idempotent re-run guard).
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT 'review_lane_enqueue_stalled', FALSE,
  'Condition-healed by W5 (SPEC-DEFECT NOTICE INTAKE, REVIEW-LANE ENQUEUE-GAP CHECK) on the first cycle state.review_lane_enqueue_gap reads is_stalled = FALSE.',
  "PENDING_REVIEW producer-stall watch (bigquery/254): days since the last pending enqueue exceed the lane's own longest observed gap. WARNING, never critical - a reporting signal, it gates nothing."
FROM UNNEST([1]) AS _g
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = 'review_lane_enqueue_stalled');

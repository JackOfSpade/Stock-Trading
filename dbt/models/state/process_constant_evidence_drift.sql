-- Parallel-run dbt port of bigquery/142_cadence_deadline_revert_and_evidence_drift.sql:state.process_constant_evidence_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
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
  FROM {{ source('ops', 'process_constant_change_log') }} c
  WHERE NOT ENDS_WITH(c.change_key, ':REVERT')
    AND NOT EXISTS (
      SELECT 1 FROM {{ source('ops', 'process_constant_change_log') }} r
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
  JOIN {{ source('ops', 'process_reliability_observations') }} o
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
  JOIN {{ source('ops', 'run_log') }} r
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
FROM agg

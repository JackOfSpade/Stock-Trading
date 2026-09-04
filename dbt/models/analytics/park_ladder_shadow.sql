-- Parallel-run dbt port of bigquery/218_park_ladder_shadow.sql:analytics.park_ladder_shadow — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH RECURSIVE
ax AS (
  SELECT as_of_date,
         ANY_VALUE(standing_defensive_count) AS standing,
         ANY_VALUE(firing_count)             AS firing,
         ANY_VALUE(cap_pct)                  AS cap_raw,
         ANY_VALUE(increase_gate_open)       AS gate,
         ANY_VALUE(testable_axes)            AS testable_axes,
         ANY_VALUE(axis_set_fingerprint)     AS axis_set_fingerprint
  FROM {{ ref('park_axis_daily') }}
  WHERE as_of_date >= DATE '2026-06-01'
  GROUP BY as_of_date
),
mk AS (
  SELECT mark_date,
         MAX(IF(ticker = 'SPY',  close, NULL)) AS spy,
         MAX(IF(ticker = '^VIX', close, NULL)) AS vix,
         MAX(IF(ticker = 'VOO',  close, NULL)) AS voo,
         MAX(IF(ticker = 'SGOV', close, NULL)) AS sgov,
         MAX(IF(ticker = 'VOO',  IFNULL(dividend, 0), NULL)) AS voo_div,
         MAX(IF(ticker = 'SGOV', IFNULL(dividend, 0), NULL)) AS sgov_div
  FROM {{ source('state_external', 'signal_marks_curated') }}
  WHERE ticker IN ('SPY', '^VIX', 'VOO', 'SGOV') AND mark_date >= DATE '2026-05-20'
  GROUP BY mark_date
),
mkr AS (
  SELECT mark_date, vix,
         SAFE_DIVIDE(spy,  LAG(spy)  OVER (ORDER BY mark_date)) - 1 AS spy_ret,
         SAFE_DIVIDE(voo  + voo_div,  LAG(voo)  OVER (ORDER BY mark_date)) - 1 AS r_risk,
         SAFE_DIVIDE(sgov + sgov_div, LAG(sgov) OVER (ORDER BY mark_date)) - 1 AS r_def
  FROM mk
),
conv AS (
  SELECT entry_date, MAX(conviction_pct) AS conviction_pct
  -- state.decision_log_current, NOT the raw table: a corrected park-allocation row must supply the
  -- FINAL-EFFECTIVE conviction, not the superseded one it replaced (bigquery/144's anti-join).
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE entry_type = 'park-allocation' AND conviction_pct IS NOT NULL
  GROUP BY entry_date
),
-- The book's ACTUAL defensive weight, on the IDENTICAL ruler, so the comparison is not cross-ruler.
-- park_policy_changes is append-only and 2026-09-03 carries a CORRECTED REPLACEMENT row for the same
-- vehicle/date, so the vehicle is taken from the LATEST event_ts per effective_date.
pol AS (
  SELECT effective_date, vehicle, target_f_pct
  FROM {{ source('events', 'park_policy_changes') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY effective_date ORDER BY event_ts DESC) = 1
),
base AS (
  SELECT a.as_of_date, a.standing, a.firing, a.cap_raw, a.gate, a.testable_axes,
         a.axis_set_fingerprint,
         -- MUST read target_f_pct (added 2026-09-04). bigquery/220 made it the authoritative
         -- weight; deriving the actual arm from the vehicle STRING makes it fiction the moment a
         -- graded call lands, because f=25 and f=50 both write vehicle='VOO' and would score as
         -- f=0 — collapsing r_actual onto r_risk and turning ladder_edge_vs_actual_pp (the criterion
         -- the re-evaluation turns on) into ladder_edge_vs_never_pp. The COALESCE keeps every
         -- pre-v4 row reading exactly as before.
         COALESCE(p.target_f_pct, IF(p.vehicle = 'VOO', 0, 100)) AS actual_f_pct,
         COALESCE(c.conviction_pct, 60) AS conviction,
         COALESCE(m.spy_ret <= -0.025 OR m.vix >= 28, FALSE) AS crisis,
         m.r_risk, m.r_def
  FROM ax a
  LEFT JOIN mkr  m ON m.mark_date  = a.as_of_date
  LEFT JOIN conv c ON c.entry_date = a.as_of_date
  -- Range join, not an equality join: policy effective_dates are NOT always trading days
  -- (2026-07-26 is a Sunday), so "the policy in force on this session" is the latest row at or
  -- before it, never a same-day match.
  LEFT JOIN pol p ON p.effective_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.as_of_date ORDER BY p.effective_date DESC) = 1
),
seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY as_of_date) AS n, as_of_date, standing, firing, gate,
         conviction, crisis, r_risk, r_def, testable_axes, axis_set_fingerprint, actual_f_pct,
         cap_raw,
         LAG(cap_raw, 1) OVER (ORDER BY as_of_date) AS cap_l1,
         LAG(cap_raw, 2) OVER (ORDER BY as_of_date) AS cap_l2,
         COALESCE(crisis
                  OR LAG(crisis, 1) OVER (ORDER BY as_of_date)
                  OR LAG(crisis, 2) OVER (ORDER BY as_of_date), FALSE) AS crisis_recent
  FROM base
),
-- STRICT three-consecutive-readings decay, as its own recursion. The cap does not depend on f, so it
-- is walked separately; folding it into `walk` would strand target_idx, which seq2 derives from it.
-- A cap INCREASE is taken immediately (never delayed, §2.3); a DECREASE is taken only when the new
-- lower value has held for three consecutive readings — otherwise the previously held cap persists.
cap_walk AS (
  SELECT n, cap_raw AS cap_held FROM seq WHERE n = 1
  UNION ALL
  SELECT s.n,
    CASE
      WHEN s.cap_raw >= w.cap_held                      THEN s.cap_raw
      WHEN s.cap_raw = s.cap_l1 AND s.cap_raw = s.cap_l2 THEN s.cap_raw
      ELSE w.cap_held
    END AS cap_held
  FROM cap_walk w JOIN seq s ON s.n = w.n + 1
),
seq2 AS (
  SELECT s.n, s.as_of_date, s.standing, s.firing, s.gate, s.conviction, s.crisis, s.crisis_recent,
         s.r_risk, s.r_def, s.testable_axes, s.axis_set_fingerprint, s.actual_f_pct,
         GREATEST(CAST(c.cap_held / 25 AS INT64), IF(s.crisis, 4, 0)) AS cap_idx,
         LEAST(GREATEST(CAST(c.cap_held / 25 AS INT64), IF(s.crisis, 4, 0)),
               GREATEST(0, CAST(CEIL((s.conviction
                    * GREATEST(CAST(c.cap_held / 25 AS INT64), IF(s.crisis, 4, 0))
                    * 25 / 100 - 12.5) / 25) AS INT64)))
           AS target_idx
  FROM seq s JOIN cap_walk c ON c.n = s.n
),
walk AS (
  SELECT n, CAST(IF(gate AND target_idx > 0, target_idx, 0) AS INT64) AS f_idx
  FROM seq2 WHERE n = 1
  UNION ALL
  SELECT s.n,
    CASE
      WHEN s.gate AND s.target_idx > w.f_idx      THEN LEAST(s.target_idx, s.cap_idx)
      WHEN w.f_idx > s.cap_idx AND s.crisis_recent THEN w.f_idx
      WHEN w.f_idx > s.cap_idx AND w.f_idx >= 2    THEN w.f_idx - 1
      WHEN w.f_idx > s.cap_idx                     THEN s.cap_idx
      ELSE w.f_idx
    END AS f_idx
  FROM walk w JOIN seq2 s ON s.n = w.n + 1
),
joined AS (
  SELECT s.as_of_date, s.standing, s.firing, s.gate, s.conviction, s.crisis, s.crisis_recent,
         s.testable_axes, s.axis_set_fingerprint, s.r_risk, s.r_def, s.actual_f_pct,
         LAG(s.actual_f_pct) OVER (ORDER BY s.as_of_date) AS actual_f_prev_pct,
         s.cap_idx * 25 AS confirmed_cap_pct,
         s.target_idx * 25 AS conviction_target_pct,
         w.f_idx * 25 AS f_pct,
         LAG(w.f_idx * 25) OVER (ORDER BY s.as_of_date) AS f_prev_pct
  FROM seq2 s JOIN walk w ON w.n = s.n
),
priced AS (
  SELECT *,
         -- The weight set on the PRIOR session is what the book earns today (179's prev-lag idiom).
         SAFE_MULTIPLY(1 - f_prev_pct / 100, r_risk)
           + SAFE_MULTIPLY(f_prev_pct / 100, r_def) AS r_ladder,
         SAFE_MULTIPLY(1 - actual_f_prev_pct / 100, r_risk)
           + SAFE_MULTIPLY(actual_f_prev_pct / 100, r_def) AS r_actual,
         -- THE BINARY COUNTERFACTUAL AS ITS OWN NAMED ARM (added 2026-09-04). Once the book follows
         -- the ladder, r_actual and r_ladder are the SAME expression and ladder_edge_vs_actual_pp is
         -- identically 0 — so a criterion resting only on it reports 0-of-N forever and reads as
         -- failure when it actually means "shadow and book merged". The all-or-nothing rule the
         -- ladder replaced engages on exactly the same signal at full size, so it is f=100 whenever
         -- the ladder holds anything at all. This arm is what ladder-vs-binary must be scored on.
         SAFE_MULTIPLY(1 - IF(f_prev_pct > 0, 100, 0) / 100, r_risk)
           + SAFE_MULTIPLY(IF(f_prev_pct > 0, 100, 0) / 100, r_def) AS r_binary
  FROM joined
)
SELECT
  as_of_date,
  standing                                   AS standing_defensive_count,
  firing                                     AS firing_count,
  gate                                       AS increase_gate_open,
  crisis,
  crisis_recent,
  conviction                                 AS conviction_pct,
  -- NAMED confirmed_cap_pct, NOT cap_pct (renamed 2026-09-04). state.park_axis_daily publishes a
  -- DIFFERENT quantity under the name cap_pct: the RAW cap off today's standing count. This one is
  -- the DECAY-CONFIRMED cap produced by the cap_walk recursion. They disagreed on 8 of 68 live
  -- sessions, max gap 75pp (2026-06-05: raw 25, confirmed 100), so one name for both was a trap.
  -- The confirmed cap is PATH-DEPENDENT: a fixed-width MAX over the raw series does NOT recover it
  -- (a 3-session MAX misses all eight disagreements).
  confirmed_cap_pct,
  conviction_target_pct,
  f_pct,
  f_prev_pct,
  r_risk,
  r_def,
  r_ladder,
  -- The ACTUAL book weight and its return, on the identical ruler — this is what makes the
  -- ladder-vs-actual comparison honest rather than cross-ruler.
  actual_f_pct,
  actual_f_prev_pct,
  r_actual,
  IF(f_prev_pct > 0, 100, 0)                 AS binary_f_prev_pct,
  r_binary,
  -- Flap counters (§2.7): a step change in f, and a conviction sitting within 5 points of the
  -- cap-100 step boundary at 62.5, which is dead centre of the allocator's empirical 50-76 range.
  (f_pct != f_prev_pct)                      AS f_changed,
  (ABS(conviction - 62.5) <= 5)              AS conviction_near_step_boundary,
  testable_axes,
  axis_set_fingerprint,
  DATE '2026-06-01'                          AS ladder_start_date,
  -- NULL before the allocator's own era anchor, so graded and grading series share a footing.
  IF(as_of_date >= DATE '2026-07-24', r_ladder, NULL) AS r_ladder_ai_era
FROM priced

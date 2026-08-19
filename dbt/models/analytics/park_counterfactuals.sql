-- Parallel-run dbt port of bigquery/179_park_twr_fill_anchored.sql:analytics.park_counterfactuals —
-- canonical source is that file until owner cutover (supersedes the prior dbt port of
-- bigquery/93_park_accounting.sql). SGOV / VOO / v1-rule-shadow / AI, same date axis, four chained
-- total-return indices — PARK_ROUTER_DESIGN.md v2 §9's three-way evaluation benchmark for the AI
-- Park Allocator. rule_index's vehicle is now LAGGED one axis position (bigquery/179's DEFECT 2 fix)
-- so the shadow is causal — decide on day d-1's close, earn day d's return — matching the AI's own
-- decide-after-close / execute-next-open cadence, instead of being paid for a same-day decision it
-- could not have made in time.
--
-- state.park_rule_shadow (bigquery/92_park_allocator.sql) and state.signal_marks_curated
-- (bigquery/91_park_signal_layer.sql) are declared as state_external sources (dbt does not yet own
-- them — out of scope for this dbt-port pass, see sources.yml).

WITH axis AS (
  -- Reuses park_nav_daily's own date list verbatim — guarantees the "same date axis" the spec calls
  -- for with no risk of independently re-deriving a slightly different one.
  SELECT as_of_date FROM {{ ref('park_nav_daily') }}
),

-- ===== SGOV leg — byte-parallel to sgov_cumulative.sql: forward-fill convention (a missing SGOV
-- mark repeats the last known RATE — correct for a cash-like accrual). =====
sgov_leg AS (
  SELECT a.as_of_date,
    {{ sgov_forward_fill('sg.r_sgov', 'a.as_of_date') }} AS r_sgov
  FROM axis a
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
),
sgov_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_sgov)) OVER (ORDER BY as_of_date)) - 1 AS sgov_index
  FROM sgov_leg
),

-- ===== VOO leg — byte-parallel to voo_cumulative.sql, including its NULL-on-gap display discipline
-- (level still chains internally via COALESCE(r_voo,0)). =====
voo_leg AS (
  SELECT a.as_of_date, v.r_voo,
    MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER () AS first_voo_date
  FROM axis a
  LEFT JOIN {{ ref('voo_daily_return') }} v USING (as_of_date)
),
voo_cum AS (
  SELECT as_of_date,
    CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL
         WHEN r_voo IS NULL THEN NULL
         ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                  OVER (ORDER BY as_of_date)) - 1
    END AS voo_index
  FROM voo_leg
),

-- ===== Rule-shadow leg — v1's deterministic regime->vehicle table, running record-only
-- (state.park_rule_shadow, bigquery/92). rule_vehicle can be ANY menu ticker (incl. ones that live
-- only in signal_marks_curated, e.g. TLT/LQD/...), so this needs the same combined-marks +
-- per-ticker-return construction as park_nav_daily.sql above — duplicated here rather than shared (a
-- BigQuery view's WITH chain cannot span two separate CREATE VIEW/model statements; same "inert
-- duplicate CTE" convention bigquery/90 uses for its copies of 31's/59's CTEs). NULL rule_vehicle (no
-- state.park_rule_shadow row for a date, or a recorded CASH call) -> r=0 carry, via the LEFT JOINs +
-- COALESCE below — no special-case needed for CASH specifically, since a ticker literally named
-- 'CASH' simply never matches any marks row either. =====
rule_marks AS (
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 1 AS src_priority
  FROM {{ ref('daily_marks_curated') }}
  UNION ALL
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 2 AS src_priority
  FROM {{ source('state_external', 'signal_marks_curated') }}
),
rule_marks_curated AS (
  SELECT ticker, mark_date, close, dividend
  FROM rule_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY src_priority) = 1
),
rule_ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM rule_marks_curated
),

-- The prior AXIS date (not calendar date) for each day — so a Monday's return is governed by the
-- preceding Friday's classification, with no weekend hole and no assumption of contiguous dates.
axis_prev AS (
  SELECT as_of_date,
    LAG(as_of_date) OVER (ORDER BY as_of_date) AS prev_as_of_date
  FROM axis
),
rule_leg AS (
  -- state.park_rule_shadow's date column is `mark_date` (bigquery/92), not `as_of_date`. LAGGED
  -- join (bigquery/179's DEFECT 2 fix): day d-1's rule_vehicle governs day d's return, because
  -- park_rule_shadow classifies from day d-1's OWN closing signals and could not have been acted on
  -- before day d opened. The prior body (bigquery/93) joined prs.mark_date = a.as_of_date, paying the
  -- shadow for a same-day decision — an acausal advantage the AI's real, lagged switches never get.
  SELECT ap.as_of_date,
    COALESCE(GREATEST(rtr.r, -0.9999), 0) AS r_rule
  FROM axis_prev ap
  LEFT JOIN {{ source('state_external', 'park_rule_shadow') }} prs
    ON prs.mark_date = ap.prev_as_of_date
  LEFT JOIN rule_ticker_returns rtr
    ON rtr.ticker = prs.rule_vehicle AND rtr.as_of_date = ap.as_of_date
),
rule_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_rule)) OVER (ORDER BY as_of_date)) - 1 AS rule_index
  FROM rule_leg
)
SELECT
  a.as_of_date,
  sc.sgov_index,
  vc.voo_index,
  rc.rule_index,
  -- ai_index = park_nav_daily.twr_index joined by date, per the approved spec — now fill-anchored
  -- (bigquery/179's DEFECT 1 fix), so it is measured on the same footing as the benchmarks.
  pnd.twr_index AS ai_index
FROM axis a
LEFT JOIN sgov_cum sc USING (as_of_date)
LEFT JOIN voo_cum  vc USING (as_of_date)
LEFT JOIN rule_cum rc USING (as_of_date)
LEFT JOIN {{ ref('park_nav_daily') }} pnd USING (as_of_date)

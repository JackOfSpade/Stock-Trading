-- Singular test (passes when ZERO rows): analytics.calibration_shrunk's Wilson interval must always
-- be well-formed — wilson_low/wilson_high in [0,1] and wilson_low <= wilson_high — including the
-- closed=0 "maximal uncertainty" [0,1] case the view's own comment documents.
--
-- Added 2026-07-04 (audit finding: calibration_shrunk had zero test coverage). Also pins the
-- accompanying fix in this model (every division by `closed` in the wilson CTE is now SAFE_DIVIDE,
-- not just the outermost one — a raw `/closed` nested inside an outer SAFE_DIVIDE still hard-errors
-- the whole query when closed=0, which a passing SELECT here would not even reach; this test instead
-- guards the well-formedness of the interval this model must produce for every conviction tier,
-- including a future zero-closed tier).

SELECT conviction, closed, wilson_low, wilson_high
FROM {{ ref('calibration_shrunk') }}
WHERE wilson_low < 0 OR wilson_low > 1
   OR wilson_high < 0 OR wilson_high > 1
   OR wilson_low > wilson_high
   OR (closed = 0 AND (wilson_low <> 0 OR wilson_high <> 1))

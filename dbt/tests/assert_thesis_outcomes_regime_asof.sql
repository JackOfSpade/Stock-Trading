-- Singular test (passes when ZERO rows): analytics.thesis_outcomes.regime_state must be the
-- FUNDAMENTAL_AXIS `_integrative` regime value as-of (on or before) each thesis's entry_date —
-- never a later value. Guards against the 2026-07-03 self-improvement audit finding (S-1/B-1):
-- the prior view back-stamped the single LATEST regime onto every historical thesis, a look-ahead
-- label leak. Recomputes the same decorrelated as-of lookup independently and flags any mismatch.

WITH regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM {{ source('events', 'regime_events') }}
  WHERE scope='FUNDAMENTAL_AXIS' AND key='_integrative'
),
expected AS (
  SELECT t.entry_id, ra.regime_state AS expected_regime_state
  FROM {{ ref('thesis_outcomes') }} t
  LEFT JOIN regime_axis ra ON ra.as_of_date <= t.entry_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY t.entry_id ORDER BY ra.as_of_date DESC) = 1
)
SELECT o.entry_id, o.entry_date, o.regime_state AS actual, e.expected_regime_state AS expected
FROM {{ ref('thesis_outcomes') }} o
JOIN expected e USING (entry_id)
WHERE COALESCE(o.regime_state, '') != COALESCE(e.expected_regime_state, '')

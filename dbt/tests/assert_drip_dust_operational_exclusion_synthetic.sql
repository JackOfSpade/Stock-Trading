-- Singular regression (rewritten 2026-08-02 -- was a pure tautology: two hardcoded rows with
-- `is_dust` preset on the SAME literal, filtered by `WHERE NOT COALESCE(is_dust, FALSE)` and
-- asserted never to fail -- it structurally could not fail under any input).
--
-- `state.position_reconciliation` and `state.strategy_probe_progress` are CREATE-OR-REPLACE VIEWs
-- in bigquery/126_dust_operational_hardening.sql with no dbt model, so `ref()` is unavailable for
-- them. Per the precedent in assert_fn_order_guard_fire_drill.sql (same situation: a live gating
-- object with no dbt port), this queries the LIVE views directly by fully-qualified name. Unlike
-- fn_order_guard, these are plain views over live state, not parameterized functions -- there is no
-- way to inject a synthetic hypothetical (e.g. a >0.01-share dust lot) into them. Instead this
-- recomputes the ONE piece of logic under test -- each view's own `NOT COALESCE(is_dust, FALSE)`
-- filter -- independently from {{ ref('position_lifecycle') }} (which mirrors
-- bigquery/126's `lc` / `openpos` CTEs exactly) and diffs that expectation against the live views,
-- the same "recompute expected, diff against real" shape as assert_thesis_outcomes_regime_asof.sql.
--
-- Verified against live data 2026-08-02: two real open dust lots exist (strategy B / IBM (0.0007 sh)
-- and HCA (0.0001 sh), bigquery/126's header) with NO matching current_positions row, so the
-- position_reconciliation check below returns 0 rows today and would return exactly those 2 rows if
-- the view's dust filter were ever dropped (confirmed by rerunning with the filter removed). Real
-- (non-dust) positions are covered by the same diff, general across every (strategy, ticker) pair,
-- not just the two dust witnesses -- a broken "exclude everything" fix would also fail this test.
-- The strategy_probe_progress check is written the same way but is CURRENTLY VACUOUS in production
-- (zero strategies are in PROBE state as of 2026-08-02, per state.strategy_roster) -- it stays in
-- as a real, general, non-tautological guard for whenever a PROBE strategy next exists; it does not
-- need to be exercised to be correct, and the position_reconciliation half already proves this file
-- can fail.

WITH expected_reconciliation AS (
  SELECT strategy, ticker, SUM(shares) AS expected_lifecycle_open_shares
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy, ticker
),
actual_reconciliation AS (
  SELECT strategy, ticker, lifecycle_open_shares
  FROM `stock-trading-498512.state.position_reconciliation`
),
reconciliation_mismatch AS (
  SELECT
    'position_reconciliation' AS check_source,
    COALESCE(e.strategy, a.strategy) AS strategy,
    COALESCE(e.ticker, a.ticker) AS ticker,
    COALESCE(e.expected_lifecycle_open_shares, 0) AS expected_value,
    COALESCE(a.lifecycle_open_shares, 0) AS actual_value
  FROM expected_reconciliation e
  FULL OUTER JOIN actual_reconciliation a USING (strategy, ticker)
  WHERE COALESCE(e.expected_lifecycle_open_shares, 0) != COALESCE(a.lifecycle_open_shares, 0)
),
expected_probe AS (
  SELECT strategy AS strategy_code, COUNT(*) AS expected_n_open
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL AND NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy
),
actual_probe AS (
  SELECT strategy_code, n_open_positions
  FROM `stock-trading-498512.state.strategy_probe_progress`
),
-- Checked against the same defect class as assert_drip_dust_campaign_semantics_synthetic.sql's
-- Arm A (2026-08-02 review) and found NOT to share it, so left as LEFT JOIN from actual_probe:
-- unlike that file's `expected` CTE (an independent full re-derivation of the SAME campaign
-- population the model computes), expected_probe here has no way to independently enumerate "which
-- strategies are genuinely in PROBE state" -- that's roster-derived information
-- (state.strategy_roster) not present in position_lifecycle at all. expected_probe as written is a
-- per-strategy OPEN-COUNT LOOKUP (every strategy with any open non-dust position, probe or not),
-- consulted only for whichever strategy_code actual_probe already says is in PROBE -- the same
-- lookup-not-independent-enumeration shape as fifo_isolation's fill_class LEFT JOINs, not the
-- diff-two-full-recomputes shape that needs FULL OUTER. Verified live 2026-08-02: switching this to
-- FULL OUTER JOIN would introduce 2 FALSE-POSITIVE failure rows right now (strategy D: 13 open
-- non-dust positions, strategy B: 6) -- neither is in PROBE state, so both are correctly absent from
-- state.strategy_probe_progress; a FULL OUTER JOIN would misreport that absence as a mismatch.
probe_mismatch AS (
  SELECT
    'strategy_probe_progress' AS check_source,
    a.strategy_code AS strategy,
    CAST(NULL AS STRING) AS ticker,
    COALESCE(e.expected_n_open, 0) AS expected_value,
    COALESCE(a.n_open_positions, 0) AS actual_value
  FROM actual_probe a
  LEFT JOIN expected_probe e USING (strategy_code)
  WHERE COALESCE(e.expected_n_open, 0) != COALESCE(a.n_open_positions, 0)
)
SELECT * FROM reconciliation_mismatch
UNION ALL
SELECT * FROM probe_mismatch

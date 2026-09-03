-- Singular test (passes when ZERO rows): no park-vehicle ticker (SGOV, VOO) may ever carry a
-- non-NULL strategy in state.trade_fills_curated.
--
-- Rationale: SGOV/VOO are the shared, ACCOUNT-LEVEL idle-capital park (event-sourced through
-- events.parking_events, where strategy is NULL on 65 of 66 rows -- the single exception, event_id
-- bb4d1216-fe64-4658-85a1-3539262720c4, is this very same 2026-06-30 incident mirrored on the
-- parking_events side, corrected here 2026-09-02 from a flat "NULL on every row") -- never a
-- per-strategy deployed position. A
-- park-sweep fill that leaks into trade_fills with a strategy tag is exactly the RUNBOOK §29
-- 2026-06-30 anomaly (a 0.2468-share SGOV BUY, tagged strategy B, minted a phantom open lot in
-- analytics.position_lifecycle and contaminated strategy B's deployed-TWR return). That specific
-- incident is fixed at the query layer (position_lifecycle's own `ticker != 'SGOV'` filter,
-- bigquery/03_twr_engine.sql / dbt/models/analytics/position_lifecycle.sql) -- but before this test,
-- NOTHING detected the leak itself; it was found by hand while investigating an unrelated alert.
--
-- Deliberately a DETECTIVE test, not a broader exclusion filter: position_lifecycle's blanket
-- `ticker != 'SGOV'` exclusion is safe because SGOV could never legitimately be a strategy's own
-- directional position. VOO is different -- an ordinary, liquid ETF a strategy COULD legitimately
-- trade as a real thesis (none does today, confirmed via repo-wide search, but nothing prevents it
-- going forward per the 2026-07-15 owner directive that added VOO as a second park vehicle). Blanket
-- -excluding VOO the same way SGOV is excluded would silently drop a future strategy's real P&L from
-- the deployed-TWR engine with no error and no test failure -- worse than the leak this guards
-- against. So this test WATCHES for a park-ticker leak (either vehicle) instead of silently
-- filtering it, surfacing it the same way a real trade would surface, via a normal test failure.
--
-- The historical 2026-06-30 row is carved out by trade_id (not by ticker/date, so a NEW leak on the
-- same ticker/date would still be caught) -- it is a known, already-fixed-at-the-query-layer, already
-- -documented incident (RUNBOOK §29), not an ongoing gap this test needs to re-flag every run.

SELECT trade_id, strategy, ticker, side, shares, fill_ts
FROM {{ ref('trade_fills_curated') }}
WHERE ticker IN ('SGOV', 'VOO')
  AND strategy IS NOT NULL
  AND trade_id != '00012978.6a43d694.01.01'  -- RUNBOOK §29, the 2026-06-30 SGOV leak -- known, fixed, documented

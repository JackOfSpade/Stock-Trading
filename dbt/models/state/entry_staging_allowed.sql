-- Parallel-run dbt port of bigquery/78_book_drawdown_rebase_and_staleness_gate.sql:state.entry_staging_allowed — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH bdw AS (SELECT breach_soft, drawdown_from_peak FROM {{ ref('book_drawdown_watch') }}),
ocl AS (SELECT entries_halted, trading_days_since_last_fill, n_pending_instructions FROM {{ ref('owner_confirmation_liveness') }})
SELECT
  (NOT COALESCE(bdw.breach_soft, TRUE) AND NOT COALESCE(ocl.entries_halted, TRUE)) AS entries_allowed,
  COALESCE(bdw.breach_soft, FALSE) AS book_drawdown_soft_breach,
  COALESCE(ocl.entries_halted, FALSE) AS owner_confirmation_entries_halted,
  CASE
    WHEN COALESCE(bdw.breach_soft, TRUE) THEN
      FORMAT('book_drawdown_soft_breach: NAV %.2f%% below flow-adjusted peak exceeds the -15%% soft threshold — NEW-entry staging paused; exits / kill-trigger terminations / park cover UNAFFECTED', bdw.drawdown_from_peak * 100)
    WHEN COALESCE(ocl.entries_halted, TRUE) THEN
      FORMAT('owner_confirmation_stale: %d pending instruction(s), %d trading day(s) since last fill — NEW-entry staging paused (76)', ocl.n_pending_instructions, ocl.trading_days_since_last_fill)
    ELSE NULL
  END AS block_reason
FROM bdw, ocl

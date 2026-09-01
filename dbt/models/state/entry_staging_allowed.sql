-- Parallel-run dbt port of bigquery/205_alert_message_stability.sql:state.entry_staging_allowed — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH bdw AS (SELECT breach_soft, drawdown_from_peak FROM {{ ref('book_drawdown_watch') }}),
ocl AS (SELECT entries_halted, trading_days_since_last_fill, n_pending_instructions FROM {{ ref('owner_confirmation_liveness') }})
SELECT
  (NOT COALESCE(bdw.breach_soft, TRUE) AND NOT COALESCE(ocl.entries_halted, TRUE)) AS entries_allowed,
  COALESCE(bdw.breach_soft, FALSE) AS book_drawdown_soft_breach,
  COALESCE(ocl.entries_halted, FALSE) AS owner_confirmation_entries_halted,
  CASE
    WHEN COALESCE(bdw.breach_soft, TRUE) THEN
      'book_drawdown_soft_breach: NAV below flow-adjusted peak exceeds the -15% soft threshold — NEW-entry staging paused; exits / kill-trigger terminations / park cover UNAFFECTED (see state.book_drawdown_watch.drawdown_from_peak for the live figure)'
    WHEN COALESCE(ocl.entries_halted, TRUE) THEN
      FORMAT('owner_confirmation_stale: %d pending instruction(s), %d trading day(s) since last fill — NEW-entry staging paused (76)', ocl.n_pending_instructions, ocl.trading_days_since_last_fill)
    ELSE NULL
  END AS block_reason
FROM bdw, ocl

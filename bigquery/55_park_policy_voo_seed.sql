-- bigquery/55_park_policy_voo_seed.sql
-- ONE-TIME SEED — the events.decision_log OWNER-DIRECTIVE entry recording the 2026-07-15 directive:
-- (1) the weekly digest email drops SGOV entirely (subject line, chart, table) and becomes VOO-only
-- informational; (2) idle capital's parking vehicle switches from SGOV to VOO going forward, via the
-- event-sourced events.park_policy_changes mechanism (bigquery/54_park_policy_voo_cutover.sql).
--
-- NOT idempotent DDL. Like bigquery/36_strategy_arsenal_seed.sql, this writes a DURABLE decision row
-- via ops.sp_log_decision (which also embeds it) — GUARDED by a NOT-EXISTS check so re-running is a
-- no-op, but NOT part of the apply-in-order idempotent sequence. Apply ONCE, live, via the BigQuery
-- MCP, AFTER bigquery/54_park_policy_voo_cutover.sql.
--
-- Prereqs: events.decision_log (bigquery/01_schema.sql) and ops.sp_log_decision (bigquery/08_ops_procedures.sql).

IF NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'owner-directive'
    AND entry_date = DATE '2026-07-15'
    AND title LIKE 'Owner directive 2026-07-15 — SGOV removed from weekly email%'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-07-15',                                        -- in_entry_date
    'owner-directive',                                        -- in_entry_type
    NULL,                                                     -- in_strategy (account-wide, not per-strategy)
    NULL,                                                     -- in_ticker
    'AUTHORIZED',                                             -- in_decision
    NULL,                                                     -- in_conviction
    NULL,                                                     -- in_conviction_pct
    NULL,                                                     -- in_sub_pattern
    NULL,                                                     -- in_theater_check
    'Owner directive 2026-07-15 — SGOV removed from weekly email; idle-capital parking vehicle switches SGOV -> VOO',  -- in_title
    r"""**Owner directive (2026-07-15).** Two changes, both scoped to the weekly digest email and the physical idle-capital parking vehicle — NEITHER touches the sanctioned kill/gate benchmark:

1. **Weekly email v3** (`ops/weekly_report/weekly_report.gs`, `SCRIPT_VERSION` bumped `'v2'` -> `'v3'`): the "Deployed Book Since..." headline section (deployed-book vs SGOV vs VOO, cumulative %/avg/$-edge) is REMOVED entirely. SGOV is removed from the subject line, the returns chart, and the per-strategy table. The table is retitled "Average Return" and now shows each strategy's OWN average return on DEPLOYED CAPITAL ONLY over ACTIVE (deployed) time only (`analytics.strategy_vs_park_daily.deployed_unit_value`, unchanged data — a pure `.gs`-side switch from `excess_vs_sgov` to the strategy's own return), rather than the prior "average return above SGOV." The chart keeps each deployed strategy's cumulative return + VOO's own cumulative return, each its own natural (non-rebased) line — VOO was already non-rebased; only the SGOV line was removed. VOO becomes the sole displayed benchmark, still purely informational.

2. **Idle-capital parking vehicle: SGOV -> VOO.** Going forward, idle (undeployed) capital parks in VOO instead of SGOV. Implemented event-sourced via the new `events.park_policy_changes` table + `state.park_policy_current` view (`bigquery/54_park_policy_voo_cutover.sql`) rather than a hardcoded cutover date — the actual cutover activates only when a live INSERT records the owner's manual "sell all SGOV, buy VOO" IBKR transfer (a separate, later, one-time action; NOT executed by this migration or this decision-log entry). History before that transfer is genuinely SGOV and is NOT rewritten — `events.parking_events` gained a `ticker` column, backfilled `'SGOV'` for all pre-existing rows. `state.sgov_position`/`state.sgov_reconciliation` are frozen to SGOV-only history; the new vehicle-aware `state.park_position`/`state.park_reconciliation` supersede them going forward. `analytics.fn_order_guard`'s park price-band is now read live from `state.park_policy_current` (0.2% for SGOV, 0.5% for any other vehicle) so it needs no further code change on the actual cutover day.

**Explicitly OUT of scope — the sanctioned kill/gate benchmark is UNCHANGED.** `perf.strategy_daily.excess_vs_sgov`, `perf.kill_flags`, `state.strategy_retirement_candidacy`, `state.strategy_paper_readiness`'s PAPER-phase excess-vs-SGOV gate, `analytics.nogo_counterfactual`, `analytics.sgov_daily_return`, and `ops.sp_recompute_engine` all remain SGOV-anchored, exactly as `bigquery/39_beta_adjusted_alpha.sql` and `bigquery/46_weekly_benchmarks.sql` already document ("SGOV stays the sanctioned kill/gate benchmark... VOO does NOT feed perf.kill_flags"). SGOV's own daily mark ingestion continues unconditionally in D2a regardless of the parking-vehicle switch, because that benchmark still needs it. This directive's items are read as scoped to (a) the weekly email's display and (b) the physical parking vehicle only — not a redefinition of the experiment's measurement machinery, which `Experiment_Parameters.md` reserves to a separate, explicit owner directive.

**Deliberately not done:** the 9 pre-existing `ticker != 'SGOV'` defensive filters (`analytics.position_lifecycle`, `analytics.tax_lots`, `analytics.execution_quality`, `state.open_positions_summary`, `analytics.strategy_vs_park`'s commission CTE, etc.) were NOT widened to also exclude VOO. SGOV could never legitimately be a strategy's own directional position; VOO is an ordinary, liquid ETF a strategy could legitimately trade — a blanket exclusion would risk silently dropping a future strategy's real P&L. A new detective test, `dbt/tests/assert_no_park_ticker_in_strategy_positions.sql`, guards against a leaked park-sweep fill for either vehicle instead.""",  -- in_body_md
    '{"scope":"weekly digest email display + idle-capital physical parking vehicle only","kill_gate_benchmark":"UNCHANGED — perf.strategy_daily.excess_vs_sgov / perf.kill_flags remain SGOV-anchored","parking_mechanism":"events.park_policy_changes -> state.park_policy_current (event-sourced, no hardcoded cutover date)","cutover_trigger":"a separate, later, live INSERT of the VOO row into events.park_policy_changes, made the day the owner\'s manual IBKR SGOV->VOO transfer executes","weekly_email_version":"weekly_report.gs SCRIPT_VERSION v2 -> v3","superseded_views":["state.sgov_position","state.sgov_reconciliation (frozen to SGOV-only history; superseded by state.park_position / state.park_reconciliation going forward)"],"order_guard_change":"analytics.fn_order_guard p_is_sgov renamed p_is_park; price band now vehicle-conditional via state.park_policy_current (same call arity, no call-site changes required)"}',  -- in_fields_json
    ['ops/weekly_report/weekly_report.gs', 'bigquery/54_park_policy_voo_cutover.sql', 'bigquery/46_weekly_benchmarks.sql', 'Operating_Protocols.md#13', 'Claude_Task_Plan.md#D2a'],  -- in_refs
    ['owner-directive', 'weekly-report', 'parking-vehicle', 'voo', 'sgov', 'governance'],  -- in_tags
    NULL,                                                     -- in_superseded_by
    'owner-directive 2026-07-15'                              -- in_source_session
  );
END IF;

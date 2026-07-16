# BigQuery Scheduled Queries

The procedures and health views are deployed, but **nothing runs them on a timer** unless
you create these scheduled queries (a one-time owner action in the GCP Console). Until then
they fire only when a routine session calls them — so a skipped session = silent drift.

**BigQuery schedules run in UTC** (the UI's local-time label is misleading). Times below are UTC.

| File | Schedule (UTC) | What it does | Notify |
|---|---|---|---|
| `embed_pending.sql` | daily ~06:00 UTC | `CALL ops.sp_embed_pending()` — heal any unembedded decisions (P0-3). Timing irrelevant (idempotent). | — |
| `daily_freshness_check.sql` | **daily 05:00 UTC** | dead-man's switch: alert if marks/engine stale, embeddings unhealthy, kills firing, or open critical alerts (P0-2) | **enable "email on failure"** |
| `cadence_check.sql` | **daily ~05:15 UTC** | control-plane dead-man's switch: RAISE if a monitored routine missed today (`state.cadence_watch`), the events backup went silent (`state.backup_health`), or an out-of-band Apps Script went silent (`state.automation_heartbeat`); records (warning, no RAISE) any trigger drift (`state.instruction_drift`) plus the 2026-06-24/06-28 additions (`trigger_missing`, `period_missed`, `routine_stalled`, `position_drift`, `calendar_runway_low`, `restore_stale`, `ddl_drift`). | **enable "email on failure"** |
| `integrity_check.sql` | daily ~05:20 UTC | append-only dead-man's switch: warns (record-only, no RAISE) on any out-of-band UPDATE/DELETE/MERGE/TRUNCATE on the immutable `events.*` audit trail (`state.append_only_integrity`); also logs today's clean/dirty result to `ops.monitor_health_history` (check_id=`append_only_integrity`, ITEM 31, 2026-07-15) so `state.append_only_integrity_promotion_readiness` can evaluate a 14-consecutive-clean-day bar — D3's MONITOR-PROMOTION SELF-FLIP self-promotes this check to critical+RAISE once ready, same mechanism as `ddl_drift`/`restore_stale`. Needs the run-as SA granted `roles/bigquery.resourceViewer` (job metadata only). | recommended (catches the query itself erroring, e.g. a lapsed grant — it never RAISEs on the condition itself; will become **required** once D3 promotes this check to critical+RAISE) |
| `safety_critical_dml_watch.sql` | **every 6h** | safety-critical DML watch (RUNBOOK item 6/§15): RAISE (fail the job) + a critical `ops.alerts` row on any out-of-band UPDATE/DELETE/MERGE/TRUNCATE (last 24h) on exactly `ops.trading_control` / `ops.arsenal_control` / `events.strategy_lifecycle` / `perf.strategy_daily` — the shared-OAuth compensating control for the halt gate / arsenal kill-switch / roster truth / engine truth. Excludes `ops.alerts` (resolution-column UPDATEs are legitimate and frequent) and the one sanctioned nightly `perf.strategy_daily` rebuild inside `ops.sp_recompute_engine()`. Distinct from, and narrower/higher-severity than, the broad advisory `integrity_check.sql` above. Needs the run-as SA granted `roles/bigquery.resourceViewer` (same grant as `integrity_check.sql` — no new grant if run under the same SA). | **enable "email on failure"** (it RAISEs on a real hit) |
| `daily_staging_cap_check.sql` | daily ~05:25 UTC | warns (record-only, no RAISE) if today's staged orders exceed the daily notional/order-count cap (`state.daily_staging_totals`, `bigquery/23_trading_control.sql`); also raises a **critical** `order_guard_omitted` alert (no RAISE — job never fails) if any order staged today has no recorded `fn_order_guard`/`fn_order_guard_options` result in its `events.queue_events` payload (ITEM 15, self-improvement audit 2026-07-11). | — |
| `backup_events_export.sql` | daily ~05:30 UTC | `EXPORT DATA` every `events.*` table to `gs://stock-trading-backups` as dated Parquet — no Cloud Run, no key (P2-1). Needs the SA granted `storage.objectAdmin` on the bucket. **On full success it logs an `ops.backup_log` marker** so `state.backup_health` / `cadence_check.sql` can catch a silently-stalled backup. | — |
| `ops_export.sql` | daily ~05:35 UTC | `EXPORT DATA` every `ops.*` BASE TABLE (the audit/control-plane dataset with no upstream — `run_log`, `alerts`, `backup_log`, `heartbeat`, `account_snapshot`, `drill_log`) to GCS as dated Parquet; RAISEs if any table fails to export. On full success logs an `ops.backup_log` marker (`dataset='ops'`) so `state.ops_backup_health` / `cadence_check.sql` can catch a silently-stalled ops backup. Needs `16_automation_health.sql` applied first. | **enable "email on failure"** |
| `delivery_canary.sql` | **weekly, Mon ~05:40 UTC** | end-to-end alert-delivery canary: asserts the prior week's canary was delivered+stamped (RAISE if not — the alert_emailer may be dead) and always emits a fresh canary row. Needs `18_stack_review_fixes.sql` applied + a deployed `alert_emailer.gs` that stamps `notified_ts`. | **enable "email on failure"** |
| `restore_drill.sql` | **monthly ~06:00 UTC (1st)** | DR verification: `CALL ops.sp_restore_drill()` — load the latest logged backup snapshot of every `events.*` table into a scratch dataset, check restored counts vs live, RAISE on any failure (P2-1). Self-bootstrapping. Needs `17_restore_drill.sql` applied; IAM note in the file body. | **enable "email on failure"** |
| `fire_drill_order_guard.sql` | **monthly ~06:10 UTC (1st)** | `CALL ops.sp_fire_drill_order_guard()` — proves `analytics.fn_order_guard` still rejects an oversized/off-band/negative-qty test order; the procedure itself raises a critical alert on failure (never a bare RAISE). Needs `23_trading_control.sql` applied. | recommended (catches the query itself erroring) |
| `fire_drill_alert_lifecycle.sql` | **monthly ~06:20 UTC (1st)** | `CALL ops.sp_fire_drill_alert_latch()` + `CALL ops.sp_fire_drill_alert_resolve()` (2026-07-15, self-improvement audit) — proves a non-whitelisted alert class (`cash_tripwire`) is NEVER auto-resolved, and a whitelisted class (`missing_dependency`) WITH a satisfied condition IS. Both were previously invoked only ad hoc (latch) or never (resolve). Each procedure raises its own critical alert on a genuine failure. Needs `34_alert_lifecycle.sql` applied. | recommended (catches the query itself erroring) |

> **Why 05:00 UTC for the freshness check:** it must run in the **Denver evening, after D2** has
> ingested the close. 05:00 UTC ≈ 22:30 MDT / 21:30 MST — same Denver day, after D2, in both DST
> regimes. Do **NOT** use 21:30 UTC (= 15:30 MDT = *before* D2): `system_health` keys off
> `CURRENT_DATE('America/Denver')`, so a pre-D2 run would see today's marks missing and false-alarm
> every trading day. On weekends/holidays it stays green automatically (last_trading_day is the
> prior close, already ingested).

## Create one (BigQuery Studio → Scheduled queries → Create scheduled query)
1. Paste the file's SQL.
2. Schedule = the **UTC** time above; **Location = US**; Project = `stock-trading-498512`.
3. No destination table.
4. For `daily_freshness_check.sql`: under **Notifications**, turn on *Send email notifications*
   (it RAISEs on failure, so a non-green system emails you — no Pub/Sub needed).
5. (The new UI no longer exposes `maximum_bytes_billed`; not needed — both scans are < 2 MB. Cost
   is bounded by the project budget alert, see `ops/RUNBOOK.md §2`.)

The recompute engine (`ops.sp_daily_refresh`) is intentionally **not** scheduled here — it needs
the day's connector marks that only D2 can ingest. Keep it in D2; the freshness check above is
what catches a D2 that didn't run.

> **APPLY ORDER (2026-06-22):** `cadence_check.sql` references `state.backup_health` +
> `state.automation_heartbeat`, so apply **`bigquery/16_automation_health.sql` first**, then (re)create
> this scheduled query. The new backup/heartbeat checks are **self-bootstrapping** — they only fire once
> the producers have logged (the backup `ops.backup_log` marker; the Apps Script `ops.heartbeat` beats),
> so pasting `cadence_check.sql` before wiring those never false-alarms.

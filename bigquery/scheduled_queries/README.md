# BigQuery Scheduled Queries

The procedures and health views are deployed, but **nothing runs them on a timer** unless
you create these scheduled queries (a one-time owner action in the GCP Console). Until then
they fire only when a routine session calls them — so a skipped session = silent drift.

**BigQuery schedules run in UTC** (the UI's local-time label is misleading). Times below are UTC.

| File | Schedule (UTC) | What it does | Notify |
|---|---|---|---|
| `embed_pending.sql` | daily ~06:00 UTC | `CALL ops.sp_embed_pending()` — heal any unembedded decisions (P0-3). Timing irrelevant (idempotent). | — |
| `daily_freshness_check.sql` | **daily 05:00 UTC** | dead-man's switch: alert if marks/engine stale, embeddings unhealthy, kills firing, or open critical alerts (P0-2) | **enable "email on failure"** |
| `backup_events_export.sql` | daily ~05:30 UTC | `EXPORT DATA` every `events.*` table to `gs://stock-trading-backups` as dated Parquet — no Cloud Run, no key (P2-1). Needs the SA granted `storage.objectAdmin` on the bucket. | — |

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

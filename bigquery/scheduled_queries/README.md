# BigQuery Scheduled Queries

The procedures and health views are deployed, but **nothing runs them on a timer** unless
you create these scheduled queries (a one-time owner action in the GCP Console). Until then
they fire only when a routine session calls them — so a skipped session = silent drift.

| File | Schedule (America/Denver) | What it does | Notify |
|---|---|---|---|
| `embed_pending.sql` | daily ~06:00 | `CALL ops.sp_embed_pending()` — heal any unembedded decisions (P0-3) | — |
| `daily_freshness_check.sql` | daily ~21:30 (after D2) | dead-man's switch: alert if marks/engine stale, embeddings unhealthy, kills firing, or open critical alerts (P0-2) | **enable "email on failure"** |

## Create one (BigQuery Studio → Scheduled queries → Create scheduled query)
1. Paste the file's SQL.
2. Schedule = the cadence above; **Location = US**; Project = `stock-trading-498512`.
3. No destination table.
4. For `daily_freshness_check.sql`: under **Notifications**, turn on *Send email notifications*
   (it RAISEs on failure, so a non-green system emails you — no Pub/Sub needed).
5. Set a `maximum_bytes_billed` advanced option as a cost cap (these scans are tiny).

The recompute engine (`ops.sp_daily_refresh`) is intentionally **not** scheduled here — it needs
the day's connector marks that only D2 can ingest. Keep it in D2; the freshness check above is
what catches a D2 that didn't run.

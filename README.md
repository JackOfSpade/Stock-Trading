# Stock-Trading experiment

An LLM-operated, event-sourced trading experiment. Claude runs scheduled routines (each a
Claude-Code-on-Web session); BigQuery is the system of record; IBKR + Google Calendar are the
execution interface; the only human action is tapping a `[Claude] Confirm order` calendar event.

## Map
- **Spec / rules:** `Strategy.md`, `Operating_Protocols.md`, `Claude_Task_Plan.md`,
  `Experiment_Parameters.md`, `AI_Trading_Foundation.md`, … (canonical, human + routine authored)
  - `strategy/` — generated read-optimized slices of `Strategy.md` (see `strategy/README.md`)
- **Data substrate:** `bigquery/` — `events` (append-only truth) · `state` (latest-wins views)
  · `perf` (deployed-TWR engine) · `analytics` (BQML/embeddings/NAV) · `ops` (models + procedures).
  Apply `bigquery/01..11_*.sql` in order via the BigQuery MCP. See `bigquery/README.md`.
- **Numerics:** `c_options_math.py` — Strategy C's defined-risk engine (pure stdlib),
  guarded by `tests/` + CI (`.github/workflows/ci.yml`).
- **Ops / control plane:** `ops/` — `RUNBOOK.md` (owner console steps), `cadence.yaml`
  (what runs when), `dashboard/` (static health page). `scripts/` — backups, state snapshots,
  the Strategy.md splitter.

## Health at a glance
```sql
SELECT * FROM `stock-trading-498512.state.system_health`;   -- want all_green = TRUE
```
covers freshness (marks/engine vs the last trading day), embedding health, firing kill flags,
and open alerts. `state.trading_day_today` answers "is today a trading day / last close?".

## Operating it
Start here: **`ops/RUNBOOK.md`** — it lists the one-time console actions (scheduled queries /
the dead-man's switch, budget alerts, GCS backups, dashboard, CI merge-gating) and the staged
adoptions (`run_log`/`alerts` calls, the strategy-slice cutover, the theater judge).

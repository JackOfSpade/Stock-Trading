# BigQuery migration — runbook for the next session

State at handoff (2026-06-05):

- **Live in `stock-trading-498512`** (US multi-region): 5 datasets, 8 append-only event tables, 4 state views — all empty.
- **Schema versioned:** `01_schema.sql` (idempotent; re-runnable).
- **Parsers written:**
  - `parse_decision_log.py` — 221 entries validated (3 header eras)
  - `parse_portfolio_ledger.py` — position blocks → `position_events`; order-details → `trade_fills` (synthetic, superseded by connector); SGOV parking table → `parking_events`
  - `parse_regime_state.py` — technical signals + per-strategy activation states + activation-change history
  - `parse_queues.py` — `Pending_Analysis.md` + `Pending_Adversarial_Reviews.md` + **`Archived_Analysis.md` + `Archived_Adversarial_Reviews.md`** (completed entries, status='complete') + `Watchlist.md`. All collapse into one `events.queue_events` table — no separate "archive" concept.
  - `parse_adversarial_reviews.py` — paired attacker + orchestrator outputs
- **Loader written:** `load_all.py` — one-shot, reads `GCP_SA_KEY` env var, uses `google-cloud-bigquery`, idempotency-guarded per table.

## Run order (when `GCP_SA_KEY` is bound)

```bash
# 1. ensure the venv has the client lib
python3 -m venv /tmp/bqenv
/tmp/bqenv/bin/pip install -q google-cloud-bigquery

# 2. run each parser (writes NDJSON to bigquery/out/, gitignored)
python3 bigquery/parse_decision_log.py
python3 bigquery/parse_portfolio_ledger.py
python3 bigquery/parse_regime_state.py
python3 bigquery/parse_queues.py
python3 bigquery/parse_adversarial_reviews.py

# 3. load everything (uses GCP_SA_KEY)
/tmp/bqenv/bin/python bigquery/load_all.py
```

The loader refuses to write to any non-empty table (idempotency guard), so re-runs are safe.

## After load — next-step queue

1. Spot-check counts and a few sample rows against the source markdown (especially the deployed-TWR-engine fields on `position_events`).
2. Build `perf.strategy_daily` scheduled procedure (the engine — see redesign §5).
3. Build `state.daily_briefing` view (exit-trigger sweep, kill flags, reconciliation delta, queue due-list).
4. **Validate TWR against the IBKR connector** on the live positions before any kill-trigger decision trusts it.
5. Verify the `us.vertex` connection (first AI-layer test), then embeddings + vector index + conviction model + calibration.
6. **Reminder for the operator:** delete or disable the `bq-loader` service account once embeddings finish — ongoing routine writes are tiny MCP INSERTs that don't need the key.

## Files of note

- Design: `../BigQuery_System_Redesign_v2.md`
- Schema: `01_schema.sql` (applied; re-run safe)
- Loader: `load_all.py` (run once after parsers)
- Parsers: `parse_*.py`
- Intermediate NDJSON: `out/` (gitignored)

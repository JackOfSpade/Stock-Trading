# BigQuery system — `stock-trading-498512`

The experiment's quantitative data substrate. **Built, validated, and self-maintaining (2026-06-06).**

## Layout
- `01_schema.sql` — append-only `events.*` tables + latest-wins `state.*` views. Idempotent.
- `02_ai_layer.sql` — Vertex models (`ops.text_embed`, `ops.gemini`), decision embeddings + `find_precedents()`, AI ticker backfill (`AI.GENERATE_TABLE`), the `ops.sp_embed_pending()` incremental embedder, and the `state.embedding_health` drift monitor.
- `03_twr_engine.sql` — deployed-TWR engine: `daily_marks` → `strategy_daily_returns` + `sgov_daily_return` → `perf.strategy_daily` → `perf.kill_flags`. **GROSS-of-commission** profitability metric (commissions tracked exactly in the cash/NAV accounting, separately). The wholesale recompute is `ops.sp_recompute_engine()` (run daily by D2 via `ops.sp_daily_refresh`).
- `04_analytics.sql` — regime scoring, `theater_independence`, `thesis_outcomes` (calibration), `macro_series`, `decision_log.ticker` backfill.
- `05_state_briefing.sql` — `state.daily_briefing` (due queue + kill-flags + exits).
- `06_forecast.sql` — `analytics.deployed_twr_forecast` + `twr_forecast_vs_actual`: zero-shot `AI.FORECAST` (built-in TimesFM, no model to train/host) over the deployed-TWR engine (`perf.strategy_daily`) + macro (`events.macro_fred`, see `07`), written monthly by **M5**. Advisory/early-warning only — never a trigger (kill/gate stay on realised `perf.kill_flags`).
- `07_fred_macro.sql` — `events.macro_fred` + `state.macro_fred_latest`: 15 FRED-derived monthly regime metrics (CPI/PCE/PPI/retail/AHE/IP YoY, U-3, fed funds, NFP, 2Y/10Y/curve/HY-OAS/VIX), deep history from the **St. Louis Fed public CSV (no API key)** — the un-gated input to M5's macro `AI.FORECAST`. Separate from M1a's hand-curated `events.macro_series`. Seeded 2026-06-06 (777 rows, checksum-validated).
- `08_ops_procedures.sql` — ops procedures: `ops.sp_log_decision()` (atomic "append a decision row **and** embed it in one call" — the canonical way to write `events.decision_log`, instead of a raw `INSERT` + separate embed) and `ops.sp_daily_refresh()` (D2's one-call post-marks refresh: `ops.sp_recompute_engine()` + `ops.sp_embed_pending()`).

## How it stays current
The one-time `.md`→BigQuery migration is **COMPLETE**; the migration parsers (`parse_*.py` / `load_all.py`) are **RETIRED** (git history retains them). Ongoing maintenance is **connector/agent-driven**: D2 Step 0 event-sources each reconciled fill → `events.trade_fills` + `events.position_events`, ingests `daily_marks` (`get_price_history`, corporate-action aware), recomputes `perf.strategy_daily`, and writes new decisions via **`CALL ops.sp_log_decision(...)`** — which appends to `events.decision_log` **and embeds in the same call** (no separate embed step, no straggler window). Sync is auditable in one query: `SELECT * FROM state.embedding_health` (expect `is_healthy = TRUE`). See Claude_Task_Plan.md D2 + Operating_Protocols.md §14.

## Schema quick reference

Cold-query map so you don't have to re-derive names via `INFORMATION_SCHEMA` each run. **Datasets:** `events` (append-only source of truth) · `state` (latest-wins views) · `perf` (TWR engine) · `analytics` (BQML / embeddings / rollups) · `ops` (models + procedures).

| You want… | Object | Notes / canonical columns |
|---|---|---|
| Open queue items | `state.open_queue` | flat & tabular: `queue, item_key, item_type, status, strategy, ticker, due_date, conservative_default, has_note, has_payload`. **No** raw `note`/`payload` here |
| A queue item's full note / payload | `state.open_queue_detail` | same rows + raw `note` (STRING) + `payload` (JSON); query by `item_key` |
| Decisions / theses | `events.decision_log` | **date column is `entry_date`** (not `decision_date`); also `entry_type, decision, conviction, sub_pattern, title, body_md, fields(JSON)`. Write via `ops.sp_log_decision` — pass text args as triple-quoted `'''…'''` strings (BigQuery rejects `''`-style apostrophe escaping; use `\'` or triple quotes) |
| Semantic precedent search | `analytics.find_precedents('<text>')` | table function; `ORDER BY distance LIMIT k` |
| Decision embeddings | `analytics.decision_embeddings` | (in `analytics`, **not** `events`); `embed_status=''` means OK |
| Embedding sync health | `state.embedding_health` | one row: `log_rows, embedding_rows, missing_rows, error_rows, is_healthy` |
| Open positions | `state.current_positions` | latest non-CLOSE position event per `position_key` |
| Regime / router state | `state.current_regime` | latest per `scope, key` |
| Deployed-TWR / kill-gate | `perf.strategy_daily` / `perf.kill_flags` | gross-of-commission TWR; kill flags off the latest row |
| Per-strategy NAV / 2%-sizing base | `analytics.strategy_nav` | `sizing_base_2pct` (~$37.7); **not** account net-liq |
| §13 cash/SGOV reconciliation | `analytics.account_reconciliation` | events-side vs connector |
| "What needs attention today" | `state.daily_briefing` | due queue + firing kill-flags + time-exits |
| Models / procedures | `ops.text_embed`, `ops.gemini`; `ops.sp_log_decision`, `ops.sp_embed_pending`, `ops.sp_recompute_engine`, `ops.sp_daily_refresh` | Vertex-billed models; procedures |

## State (2026-06-06)
- Data layer rebuilt from the IBKR connector (authoritative) + validated: `trade_fills` / `daily_marks` / `position_events` correct (the original parser migration had missing exits, NULL shares, placeholder dates — superseded).
- Engine validated: **B 1.0005 gross / D 0.9719**, hand-checked to 0.04%; no kill/gate trigger near firing.
- Calibration live (`thesis_outcomes`: B's closed GO theses 3/3 profitable); `decision_log.ticker` fully backfilled (regex + Gemini, 110/221).
- **Cutover COMPLETE (2026-06-06):** all 18 migrated data `.md` files retired (incl. Portfolio_Ledger, Regime_State, Decision_Log, the Pending_* queues); BigQuery is the canonical operational substrate; routines read/write BigQuery per the Operating_Protocols §15 source map (regime→`state.current_regime`, positions/perf/NAV/§13→`state.current_positions`/`perf.strategy_daily`/`strategy_nav`/`account_reconciliation`, decisions→`events.decision_log`/`find_precedents`, queues→`state.open_queue`). Only spec + cadence-working `.md` files remain. **Remaining:** the conviction model (auto-trains at ≥30 closed trades).
- Operator note: the `bq-loader` service-account key was deleted; ongoing writes are tiny MCP INSERTs.
- **Hardening (2026-06-07):** built the never-built procedures — `ops.sp_log_decision` (atomic decision-log append + embed, one call), `ops.sp_embed_pending` (idempotent self-healing embedder), `ops.sp_recompute_engine` + `ops.sp_daily_refresh` (D2's one-call post-marks recompute + embed, single-sourced from the validated recompute — verified bit-for-bit idempotent); added `state.embedding_health` (one-query drift monitor); split the queue view into compact `state.open_queue` (flat columns + `has_note`/`has_payload`) and `state.open_queue_detail` (raw note/payload) so `SELECT *` is never a JSON wall; added this Schema quick reference. Validated end-to-end: `sp_log_decision` logged 2 hardening entries, embeddings `is_healthy = TRUE` (229/229, 0 missing/0 error/0 dup). See `08_ops_procedures.sql`.

### Scheduled query (recommended — owner console action)
The procedures exist but nothing yet runs them on a timer; they fire only when a session calls them. To keep embeddings (and optionally the engine) fresh even with no active session — and to avoid two concurrent sessions racing the recompute — schedule a daily BigQuery query (BigQuery Studio → Scheduled queries, or `bq query`):
```sql
CALL `stock-trading-498512.ops.sp_embed_pending`();   -- safe any time; embeds stragglers
```
The engine recompute (`ops.sp_daily_refresh`) is best left to D2, which runs it right after ingesting the day's marks; schedule it standalone only if marks are loaded by an automated job. Keep an eye on the Vertex budget alert (embeddings are pennies, but a scheduled job runs unattended).

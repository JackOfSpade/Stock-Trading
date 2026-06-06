# BigQuery system — `stock-trading-498512`

The experiment's quantitative data substrate. **Built, validated, and self-maintaining (2026-06-06).**

## Layout
- `01_schema.sql` — append-only `events.*` tables + latest-wins `state.*` views. Idempotent.
- `02_ai_layer.sql` — Vertex models (`ops.text_embed`, `ops.gemini`), decision embeddings + `find_precedents()`, AI ticker backfill (`AI.GENERATE_TABLE`).
- `03_twr_engine.sql` — deployed-TWR engine: `daily_marks` → `strategy_daily_returns` + `sgov_daily_return` → `perf.strategy_daily` → `perf.kill_flags`. **GROSS-of-commission** profitability metric (commissions tracked exactly in the cash/NAV accounting, separately). Includes the recompute query D2 runs daily.
- `04_analytics.sql` — regime scoring, `theater_independence`, `thesis_outcomes` (calibration), `macro_series`, `decision_log.ticker` backfill.
- `05_state_briefing.sql` — `state.daily_briefing` (due queue + kill-flags + exits).

## How it stays current
The one-time `.md`→BigQuery migration is **COMPLETE**; the migration parsers (`parse_*.py` / `load_all.py`) are **RETIRED** (git history retains them). Ongoing maintenance is **connector/agent-driven**: D2 Step 0 event-sources each reconciled fill → `events.trade_fills` + `events.position_events`, ingests `daily_marks` (`get_price_history`, corporate-action aware), recomputes `perf.strategy_daily`, and mirrors new `Decision_Log.md` entries → `events.decision_log` (+ embedding, + ticker). See Claude_Task_Plan.md D2 + Operating_Protocols.md §14.

## State (2026-06-06)
- Data layer rebuilt from the IBKR connector (authoritative) + validated: `trade_fills` / `daily_marks` / `position_events` correct (the original parser migration had missing exits, NULL shares, placeholder dates — superseded).
- Engine validated: **B 1.0005 gross / D 0.9719**, hand-checked to 0.04%; no kill/gate trigger near firing.
- Calibration live (`thesis_outcomes`: B's closed GO theses 3/3 profitable); `decision_log.ticker` fully backfilled (regex + Gemini, 110/221).
- **Cutover COMPLETE (2026-06-06):** all 18 migrated data `.md` files retired (incl. Portfolio_Ledger, Regime_State, Decision_Log, the Pending_* queues); BigQuery is the canonical operational substrate; routines read/write BigQuery per the Operating_Protocols §15 source map (regime→`state.current_regime`, positions/perf/NAV/§13→`state.current_positions`/`perf.strategy_daily`/`strategy_nav`/`account_reconciliation`, decisions→`events.decision_log`/`find_precedents`, queues→`state.open_queue`). Only spec + cadence-working `.md` files remain. **Remaining:** the conviction model (auto-trains at ≥30 closed trades).
- Operator note: the `bq-loader` service-account key was deleted; ongoing writes are tiny MCP INSERTs.

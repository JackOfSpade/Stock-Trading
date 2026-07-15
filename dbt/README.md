# `dbt/` — parallel-run tested modeling layer (B2 + B3)

A dbt-core project that re-expresses the **pure-SELECT derived views** of the
hand-written BigQuery system as a **dependency-aware DAG** with a **data-test suite**.
It implements two recommendations:

- **B2** — adopt dbt for the derived `state` / `perf` / `analytics` layer so the
  dependency graph is explicit (dbt `ref()`/`source()`) and rebuildable.
- **B3** — test the load-bearing view invariants (the subtle ones that have actually
  bitten this system).

## Status: PARALLEL-RUN — NOT a cutover

The canonical source of truth is **still `bigquery/*.sql`**. Every live `state.*` /
`perf.*` / `analytics.*` view is created by those files and every routine reads the live
objects today. **Nothing here changes behavior; nothing here is applied to BigQuery by
the scaffolding.** This is the same parallel-run-then-flip discipline the system used for
its `.md`→BigQuery migration and for the `strategy/` slices: build the new layer
alongside, prove it, then flip on an **owner-gated** step (see *Cutover plan* below).

Each model file carries a header:
`Parallel-run dbt port of bigquery/<file>.sql:<object> — canonical source is that file until owner cutover.`

## What dbt owns vs what stays in `bigquery/*.sql`

| dbt **owns** (pure-SELECT views, ported as models) | stays in `bigquery/*.sql` (dbt only NOTEs / sources it) |
|---|---|
| `state.current_positions`, `current_regime`, `open_queue`, `open_queue_detail`, `open_orders`, `trade_fills_curated`, `daily_marks_curated`, `daily_briefing`, `market_calendar`, `trading_day_today`, `freshness`, `system_health`, `gate_watch`, `account_latest`, `book_drawdown_watch`, `trading_control_latest`, `trading_enabled` | All **DDL** (`CREATE SCHEMA`, `CREATE TABLE`, table OPTIONS/partitioning/clustering) |
| `perf.kill_flags` | **Procedures** (`ops.sp_recompute_engine`, `sp_daily_refresh`, `sp_log_decision`, `sp_embed_pending`, `sp_log_run`, `sp_raise_alert*`, `sp_score_theater`) |
| `analytics.position_lifecycle`, `strategy_daily_returns`, `sgov_daily_return`, `thesis_outcomes`, `conviction_features`, `calibration_summary`, `strategy_nav`, `account_reconciliation`, `calibration_shrunk`, `deployed_book_vs_sgov`, `park_baseline`, `sgov_cumulative`, `strategy_scorecard`, `strategy_unit_value_7d_ago`, `strategy_vs_park`, `strategy_vs_park_daily`, `weekly_activity` | **Remote models / AI.\*** (`ops.text_embed`, `ops.gemini`, `ML.GENERATE_EMBEDDING`, `AI.GENERATE_TABLE`, `AI.FORECAST`, `VECTOR_SEARCH`, `find_precedents`), **EXPORT DATA**, scheduled-query bodies |

### Intentional source-vs-model decisions (things too procedural to port)

These are declared as **sources** in `models/sources.yml` (read, never built by dbt):

- **`perf.strategy_daily`** — a **TABLE** rebuilt wholesale by `ops.sp_recompute_engine()`
  (chained `EXP(SUM(LN(1+r)))` windows + correlated closed-trade subqueries inside a
  `DELETE`+`INSERT` procedure). It is procedure-maintained, not a pure SELECT, so dbt
  cannot own it. `perf.kill_flags` `source()`s it.
- **`events.*`** — the append-only base tables (`decision_log`, `trade_fills`,
  `position_events`, `regime_events`, `queue_events`, `adversarial_reviews`,
  `parking_events`, `daily_marks`, `market_holidays`, `macro_fred`, `macro_series`,
  `hf_capability_captures`).
- **`ops.run_log`** — control-plane table maintained by `ops.sp_log_run`. `state.freshness`
  reads it. dbt does not own anything in `ops`.
- **`state.embedding_health`** — lives in `02_ai_layer.sql` and is built on remote
  models / `ML.GENERATE_*`. Declared under the `state_external` source so `system_health`
  can reference it without dbt trying to build it. (Per the brief, the embedding-health
  view itself is **skipped** — it is not a pure SELECT.)

### Deliberately NOT ported

- `analytics.review_embeddings` / `analytics.theater_independence` — built on
  `ML.GENERATE_EMBEDDING` + `ML.DISTANCE` over a remote model. Not pure SELECT → stays in
  `04_analytics.sql`.
- `analytics.theater_judge`, `theater_check_calibration` (`11`), the `02` AI layer, the
  `06` `AI.FORECAST` views — all AI/remote-model-backed.

### One controlled exception inside a ported model

`state.system_health` aggregates `ops.alerts` inline (two `COUNTIF` subqueries) exactly as
the live view does. `ops.alerts` is a DML-maintained control-plane table that dbt does not
model, so the ported `system_health.sql` reaches the live `ops.alerts` by its fully
project-qualified name. This is the only place a ported model steps outside the dbt DAG;
it is faithful to `10_observability.sql`.

## BigQuery + dbt: dataset == schema (bare names)

In BigQuery the dbt **schema is the dataset**. Models are routed to the live datasets via
per-folder `+schema:` configs in `dbt_project.yml`:

- `models/state/**`   → dataset **`state`**
- `models/perf/**`    → dataset **`perf`**
- `models/analytics/**` → dataset **`analytics`**

By default dbt **prefixes** the target dataset onto a custom schema (you'd get
`state_state` etc.). `macros/generate_schema_name.sql` overrides that so the **bare**
dataset name is used — models land in `state` / `perf` / `analytics`, identical to the
live objects. (At cutover that means dbt would `CREATE OR REPLACE VIEW` the same names.)

## How to run

```bash
cd dbt

# 1. Profile: copy the relevant block into ~/.dbt/profiles.yml (profile name: stock_trading)
cp profiles.example.yml ~/.dbt/profiles.yml   # then edit; uses OAuth by default (method: oauth)
#    OAuth = your interactive `gcloud auth application-default login` creds (owner's current usage).

# 2. Install the dbt_utils dependency
dbt deps

# 3. Offline structural validation — NO warehouse needed (parses + resolves the DAG/refs)
dbt parse

# 4. Build + test against BigQuery (requires creds; writes views to your target dataset)
dbt build           # = run + test
# or just the tests against already-built objects:
dbt test
```

`dbt build` against the **live** datasets would replace the production views — point
`dataset`/`+schema` at a sandbox first, or run only `dbt parse` until cutover.

## CI

Do **not** wire dbt into `.github/workflows/ci.yml` as a required, warehouse-touching
step blindly — the live SQL dry-run job is already gated on `secrets.GCP_SA_KEY`. The
intended CI commands, in order of credential requirement:

| command | needs a warehouse? | what it checks |
|---|---|---|
| `dbt deps` | no | installs dbt_utils (network only) |
| `dbt parse` | **no** | offline structural validation — compiles every model, resolves every `ref()`/`source()`, validates `schema.yml`. Safe to run in CI without any BigQuery access. **Run this unconditionally.** |
| `dbt build --target ci` | **yes** | runs the models + the full test suite against BigQuery. **Gate this on creds** (WIF / `GCP_SA_KEY`), exactly like the existing `sql-validate` job — skip with a `::notice::` when creds are absent. |

`dbt parse` is the offline gate that catches a broken ref, a renamed column in a
`schema.yml`, or a malformed model before any warehouse cost is incurred.

## Test inventory (B3) — and the invariant each one protects

### Generic tests (in `models/**/schema.yml` and `models/sources.yml`)

**Event-table primary keys** (`models/sources.yml`):
- `decision_log.entry_id`, `position_events.event_id`, `regime_events.event_id`,
  `queue_events.event_id`, `adversarial_reviews.event_id`, `parking_events.event_id`,
  `macro_series.event_id`, `hf_capability_captures.capture_id`, `market_holidays.holiday_date`
  — **unique + not_null**.
- `decision_log.entry_date`, `position_events.position_key`, `regime_events.as_of_date`,
  `queue_events.queue`, `adversarial_reviews.review_id`, `parking_events.action_date` — **not_null**.
- `trade_fills.trade_id` — **not_null** only (NOT unique on the raw append-only table — a
  re-ingested fill duplicates by design; uniqueness is asserted on the curated view).
- `perf.strategy_daily` source — **not_null** on `strategy` + `as_of_date`.

**State / perf / analytics models:**

| Test | Object | Invariant it protects |
|---|---|---|
| `unique_combination_of_columns(scope, key)` + not_null | `current_regime` | latest-wins yields one reading per (scope, key) |
| `expression_is_true(UPPER(status) NOT IN terminal-set)` | `open_queue`, `open_queue_detail` | **no terminal item survives in the open queue** (the case-drift bug `01` guards: `complete` vs `COMPLETE`) |
| `unique_combination_of_columns(queue, item_key)` + not_null | `open_queue`, `open_queue_detail` | latest-wins yields one row per queue item |
| `unique` + not_null on `item_key`; `accepted_values(BUY,SELL)` on `side` | `open_orders` | one pending staged order per key; side is well-formed |
| `unique_combination_of_columns(ticker, mark_date)` + not_null | `daily_marks_curated` | **the dedup invariant that prevents TWR double-count** |
| `unique` + not_null on `trade_id` | `trade_fills_curated` | the idempotency-by-trade_id guard holds |
| `unique` + not_null on `position_key` | `position_lifecycle` | one row per round-trip (LAG window partitions on it) |
| `unique_combination_of_columns(as_of_date, strategy)` + not_null | `strategy_daily_returns` | one return row per strategy-day |
| `unique` + not_null on `as_of_date` | `sgov_daily_return` | one benchmark return per day |
| not_null on `strategy`/`as_of_date`; `accepted_range(current_drawdown <= 0)`; `unique(strategy)` | `kill_flags` | one latest flag-row per strategy; drawdown can never be positive |
| `unique` + not_null on `entry_id` | `thesis_outcomes` | one outcome per thesis (no round-trip fan-out) |
| `unique`/not_null `entry_id`; `accepted_values(decision=GO)`; `accepted_range(conviction_ordinal 1..6)` | `conviction_features` | GO-only feature view; conviction maps to a known ordinal tier |
| `unique` + not_null on `conviction` | `calibration_summary` | one calibration row per tier |
| `unique`/not_null/`accepted_values(A..E)` on `strategy` | `strategy_nav` | one NAV row per strategy |
| `accepted_values(QUEUE_DUE,KILL_FLAG,TIME_EXIT)` on `category` | `daily_briefing` | the union only emits the three known categories |
| `unique` + not_null on `cal_date` | `market_calendar` | one calendar row per date |
| `accepted_range(closed_to_gate >= 0)`; not_null `strategy` | `gate_watch` | gate-remaining never goes negative |

### Singular tests (in `tests/*.sql` — pass iff they return ZERO rows)

| File | Invariant + rationale |
|---|---|
| `assert_account_reconciliation_single_row.sql` | `account_reconciliation` returns exactly **1 row** (scalar §13 rollup D2 diffs). |
| `assert_book_drawdown_watch_single_row.sql` | `state.book_drawdown_watch` returns exactly **1 row**. Added 2026-07-04 (audit finding, HIGH) — the model is deliberately self-bootstrapping via `ARRAY_AGG` aggregates (not a QUALIFY-filtered row) specifically so it can never silently vanish and break the `state.trading_enabled` join it feeds. |
| `assert_calibration_shrunk_wilson_bounds.sql` | `analytics.calibration_shrunk`'s Wilson interval must always be well-formed — `wilson_low`/`wilson_high` in [0,1] and `wilson_low <= wilson_high` — including the closed=0 "maximal uncertainty" [0,1] case the view's own comment documents. Added 2026-07-04 (audit finding: zero test coverage); also pins the accompanying `SAFE_DIVIDE` fix in the wilson CTE. |
| `assert_cash_flows_reconcile.sql` | `SUM(events.cash_flows.amount)` must equal `SUM(analytics.strategy_nav.deposits)` — the equal-split/attributed allocation in `strategy_nav` never drops or double-counts a flow. Self-improvement audit B-1-exec. Also guards the "exactly 5 strategies" assumption baked into the equal-split (`amount/5`): if that ever changes, this test catches the resulting reconciliation drift immediately rather than a silent NAV mis-split. |
| `assert_current_positions_match_lifecycle.sql` | The two open-position representations — `state.current_positions` (← `events.position_events`, the path `strategy_nav` reads for the 2%-sizing base) and `analytics.position_lifecycle` (← `state.trade_fills_curated`, the path the TWR engine / §13 read) — must agree on open shares per (strategy, ticker) within tolerance (stack review 2026-06-24, RUNBOOK §25 B4). They are independently derived and can otherwise diverge with no existing monitor. |
| `assert_fn_order_guard_fire_drill.sql` | `analytics.fn_order_guard` must reject 3 known-bad orders — an oversized notional, an off-band limit price, and a non-positive qty. Added 2026-07-04 (audit finding, HIGH-severity test-gap): `fn_order_guard` is a PARAMETERIZED BigQuery table function, so it cannot be added to the standard row-parity mechanism (`scripts/dbt_parity.py` diffs one dbt model against one live view by name). |
| `assert_freshness_single_row.sql` | `freshness` returns exactly **1 row** (dead-man's-switch input). |
| `assert_no_park_ticker_in_strategy_positions.sql` | No park-vehicle ticker (SGOV, VOO) may ever carry a non-NULL `strategy` in `trade_fills_curated`. Added 2026-07-15 (SGOV->VOO parking-vehicle directive) — a DETECTIVE guard against a leaked park-sweep fill for either vehicle (the RUNBOOK §29 2026-06-30 SGOV incident, carved out by `trade_id`), deliberately NOT a broader exclusion filter since VOO (unlike SGOV) could legitimately be a real strategy position. |
| `assert_open_orders_actionable.sql` | Every pending staged order is well-formed enough to become a real, confirmable order — a valid side (BUY/SELL) and a positive quantity. A malformed registry row can never be crafted/confirmed yet still occupies the slot and (for a BUY) reserves cash, silently breaking the order-intent invariant (pending staged order ⇔ exactly one live confirm event). `limit_price`/`instruction_id` are intentionally NOT required: MARKET orders carry no limit, and options/other non-craftable orders carry a manual block with no `instruction_id`. |
| `assert_open_orders_no_stale_pending.sql` | No `ORDER_STAGED` row stays `pending` past its entry-window close. `state.open_orders` already filters to `status='pending'`; a pending row whose `entry_window_close` is in the past is an ORPHAN — the D2/D3 persist-and-wait sweep must either re-craft it (window still open) or set it terminal (expired/filled). A stale pending row keeps cash reserved (§13.E `reserved_cash`) and shadows the confirm-order slot — the same order-intent invariant the 2026-06-08 MDT near-miss motivated. |
| `assert_open_orders_reserved_cash_formula.sql` | For BUY rows, `reserved_cash == ROUND(qty*limit_price + 0.35, 2)` — the documented `+0.35` commission pad. Drift here could under-reserve and de-fund a staged entry. |
| `assert_open_orders_reserved_cash_nonneg.sql` | `reserved_cash >= 0` for all `open_orders`. A negative reservation would *add* free cash and re-open the de-fund hole. |
| `assert_open_positions_have_marks.sql` | Every OPEN non-SGOV position has a RECENT curated daily mark. 2026-06-28 stack review #2 (#12) — `state.freshness` only checks `MAX(mark_date)` over the WHOLE `daily_marks` table, so a single held name silently missing its mark (an IBKR empty/stale bar with no FMP fallback) understates that strategy's `r_deployed` with no per-name visibility, while the SGOV benchmark side already has a forward-fill completeness guard. Flags an open position with no `state.daily_marks_curated` row in the last ~5 trading days (a name gone dark). |
| `assert_queue_latest_wins_by_event_ts.sql` | An open-queue `item_key` must **not** have a strictly-later `event_ts` row carrying a terminal status — proves latest-wins uses `event_ts`, not `due_date`. |
| `assert_sgov_no_double_count.sql` | `COUNT(DISTINCT ticker, mark_date)` in raw `events.daily_marks` equals the curated row count — the curated view fully collapses re-ingested days. |
| `assert_system_health_single_row.sql` | `system_health` returns exactly **1 row** (consumed as a one-row rollup). |
| `assert_thesis_outcomes_regime_asof.sql` | `analytics.thesis_outcomes.regime_state` must be the `FUNDAMENTAL_AXIS` `_integrative` regime value as-of (on or before) each thesis's `entry_date`, never a later value. Guards the 2026-07-03 self-improvement audit finding (S-1/B-1): the prior view back-stamped the single LATEST regime onto every historical thesis, a look-ahead label leak. Recomputes the same decorrelated as-of lookup independently and flags any mismatch. |
| `assert_trading_control_latest_single_row.sql` | `state.trading_control_latest` returns exactly **1 row**. Added 2026-07-04 (audit finding, HIGH): `ops.trading_control` is seeded exactly once and is never expected to be empty; a 0-or->1-row result here would make `sp_assert_trading_enabled`'s `SELECT INTO` fail in the wrong direction for a safety gate. |
| `assert_trading_day_today_single_row.sql` | `trading_day_today` returns exactly **1 row** (authoritative "today"). |
| `assert_trading_enabled_single_row.sql` | `state.trading_enabled` returns exactly **1 row**. Added 2026-07-04 (audit finding, HIGH): a `CROSS JOIN` of ctrl x health x dd that ever fans out to 0 or >1 rows would make `sp_assert_trading_enabled`'s `SELECT INTO` fail in the wrong direction for the pre-order-staging safety gate. |

### The real incidents these protect (from the schema comments)

- **2026-06-08 MDT silent de-fund / `reserved_cash`** — an MDT entry's earmarked cash was
  swept to SGOV because `free_cash` keyed off live order instructions (empty) with no
  durable staged-order list. `state.open_orders` + its `reserved_cash` is the fix; the two
  `reserved_cash` singular tests guard the formula and sign that protect §13.E.
- **Queue `event_ts` ordering trap** — ordering latest-wins by `due_date` (a target date)
  instead of `event_ts` (the transition time) leaves a closed item in the open queue
  forever. The terminal-status `expression_is_true` test + `assert_queue_latest_wins_by_event_ts.sql`
  catch a regression.
- **`daily_marks` double-count** — a re-ingested day would make the TWR engine sum `mv`
  twice / `LAG` over duplicate dates, silently corrupting `r_deployed` / `r_sgov`. The
  `unique_combination_of_columns(ticker, mark_date)` test + `assert_sgov_no_double_count.sql`
  guard the dedup contract.

## Ownership cutover — DECIDED AGAINST (2026-06-19); dbt stays the TEST layer

**This project will NOT transfer view ownership to dbt.** dbt's role here is the continuous
structure + invariant **test** layer (`dbt parse` in CI; `dbt test` against BigQuery on demand),
NOT the runtime owner of the views. Why, specifically for this system:
- Routine sessions run on the BigQuery MCP and have **no dbt runtime** — if dbt owned the views, a
  session could neither rebuild nor change them.
- Disaster recovery is "apply `bigquery/01..13_*.sql` in order via the MCP"; removing the view DDL
  breaks that single-command rebuild path.
- Byte-parity of `dbt build` vs the live views can't be validated without a dbt runtime, and these
  are live trading views.

So `bigquery/*.sql` stays the **canonical runtime owner**; this `dbt/` tree is a kept-in-sync parallel
port used only for tests. (See `ops/RUNBOOK.md §14`.)

### IF a future owner ever reverses this decision (prerequisites first)
Do NOT just delete the DDL. First wire an operational dbt runner + validate byte-parity, then:

1. Run `dbt build` against the live project (or a staging dataset first) and confirm the
   ported views are **byte-equivalent** to the live ones (`EXCEPT DISTINCT` both ways, or a
   schema+row diff) and the full test suite is green.
2. **Remove the view DDL** for the ported objects from `bigquery/01_schema.sql`,
   `03_twr_engine.sql`, `04_analytics.sql`, `05_state_briefing.sql`, `10_observability.sql`,
   `22_cash_flows.sql`, `23_trading_control.sql` (and the `09` calendar views) — leaving the
   `CREATE TABLE` DDL, procedures, remote models, AI.\*, and EXPORT DATA in those files. dbt
   then owns those views.
3. Keep `perf.strategy_daily` as the procedure-maintained table + source; keep the AI /
   remote-model objects in the `.sql` files (dbt never owns them).
4. Make `dbt build --target ci` a **required** status check (and schedule a daily `dbt build`
   alongside `ops.sp_daily_refresh`, since the engine table it sources is rebuilt daily).
5. Update the routine read-instructions only if any object *name* changes — it should not;
   dbt is configured to emit the bare, identical dataset.object names.

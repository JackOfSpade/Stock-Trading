# BigQuery System Redesign

> **⚠️ SUPERSEDED by [`BigQuery_System_Redesign_v2.md`](BigQuery_System_Redesign_v2.md)** (2026-06-05).
> v2 is the canonical build spec: it keeps this event-sourced spine but adds the maximal-AI/ML layer,
> the server-side workflow redesign (Daily Briefing + conviction gate), the fully-specified deployed-TWR
> engine, and resolves the open decisions (project `stock-trading-498512`, US, 32 GB/day quota). This
> document is retained for history. Read v2 first.

**Status:** Design / proposal. Nothing is live. No GCP project, billing, connector, or data
exists yet. This document is the blueprint for migrating the experiment's data layer off
markdown-as-database onto Google BigQuery, using current (2026) BigQuery capabilities and
**only latest-supported APIs** (no obsolete paths).

**Design principles**
1. **Don't port — re-conceive.** For every current practice X, adopt the BigQuery capability Y
   that serves the *purpose* of X and adds something the markdown version never could.
2. **Event-sourced, append-only.** Matches the experiment's existing ethos ("entries are
   append-only, never deleted or modified retroactively"). State is a *view* over events.
3. **Latest APIs only.** Storage Write API (not legacy `insertAll`); GoogleSQL (not legacy SQL);
   `AI.*` / `AI.FORECAST` (TimesFM) / vector search; managed BigQuery MCP connector.
4. **Cost-capped by construction.** Partition + cluster + `maximum_bytes_billed` + custom daily
   quota keep the analytic core at ~$0; AI/ML (Vertex-billed) features are gated and batched.

---

## 1. Scope: what moves, what stays

**Moves into BigQuery (the data layer):**
- `Decision_Log.md` + `Decision_Log_Archive_2026_Q2.md` → `events.decision_log`
- `Portfolio_Ledger.md` (positions, cost basis, SGOV parking, per-strategy performance) →
  `events.position_events`, `events.trade_fills`, `events.parking_events`, `perf.strategy_daily`
- `Regime_State.md` (technical signals + router activation + history) → `events.regime_events`
- `Watchlist.md`, `Pending_Analysis.md`, `Pending_Adversarial_Reviews.md` → `events.queue_events`
- `Adversarial_Review_*` transcripts → `events.adversarial_reviews`

**Stays as markdown in git (the "constitution" — methodology/prose, correctly version-controlled):**
- `Strategy.md`, `AI_Trading_Foundation.md`, `Operating_Protocols.md`, `Claude_Task_Plan.md`,
  `Experiment_Parameters.md`, `B_Sub_Pattern_Taxonomy.md`, `C_dispersion_compression_methodology.md`,
  `E_signal_process_tightening.md`, `HF_Resource_Catalog.md`, the Monthly/Quarterly/Weekly
  *methodology* notes.
- `Operating_Protocols.md` and `Claude_Task_Plan.md` get **edited** to describe the new BigQuery
  read/write procedures (see §13).

**Gets deleted/retired (its reason-for-existing disappears):**
- The quarterly `Decision_Log_Archive_*` split (partitioning makes file size irrelevant).
- The `.gitattributes` union-merge driver **for data files** and the `auto-merge-claude.yml`
  conflict-PR path **for data files** (concurrent appends no longer conflict). The auto-merge
  flow can remain for the markdown docs.

---

## 2. Capability mapping — current X → BigQuery Y (encompass + extend)

This is the heart of the redesign: each row replaces a process with a richer native capability.

| Current practice (X) | Purpose behind X | BigQuery capability (Y) that encompasses X and adds more |
|---|---|---|
| Append entry to `Decision_Log.md` | Immutable audit trail + future retrieval of precedent | `events.decision_log` append-only table **+ time travel / table snapshots / `CHANGES` TVF** for native point-in-time audit **+ vector search** for *semantic* precedent retrieval (replaces hand-citing "Precedent: HCA 2026-04-28") **+ `AI.GENERATE_TABLE`** to auto-extract structured fields from the prose body |
| Grep the log for line ranges ("file too big") | Find the few relevant entries | SQL `WHERE`/`QUALIFY` on a partitioned+clustered table (KB scanned, not MB) **+ `VECTOR_SEARCH`** ranked by semantic similarity. *Extra:* instant filter by strategy/type/conviction/date; returns rows, not a 14k-line file |
| Manual quarterly archive split | Keep the file readable/loadable | **Eliminated.** Partition by date → only relevant partitions scanned; long-term storage auto-halves price after 90 days; one table holds all history forever |
| Hand-edit `Portfolio_Ledger` position blocks | Per-strategy cost-basis/thesis/exit state IBKR can't derive | `events.position_events` (append lifecycle: OPEN/FILL/UPDATE/CRITERION_FLIP/CLOSE) + `state.current_positions` view. *Extra:* full position history for free; no in-place edits to merge-conflict |
| D2 fill reconciliation idempotent by `trade_id` | Never double-record a fill | `events.trade_fills` append + dedup view, **or Storage Write API committed stream with offsets for exactly-once at the API level** |
| Deployed-TWR engine (manual daily chain-link in markdown) | Per-strategy TWR / drawdown / SGOV-benchmark + kill-trigger inputs | **Scheduled query** → `perf.strategy_daily` using SQL window functions (`EXP(SUM(LN(1+r)) OVER …)` chain-link, running-max high-water mark) **+ materialized views** for rollups **+ `AI.FORECAST` (TimesFM)** to forecast TWR/drawdown and kill-trigger proximity. *Extra:* runs server-side daily with zero agent tokens |
| `Regime_State.md` current states + router history | Current router activation + the change history behind it | `events.regime_events` + `state.current_regime` view. *Extra:* regime-conditioned analytics (join regime → decisions → realized outcomes); "as-of" regime lookups for any past date |
| `Pending_Analysis` / `Watchlist` / `Pending_*` queues | Track due work and drain it | `events.queue_events` (status transitions) + `state.open_queue` view + **scheduled query** that surfaces due/overdue items. *Extra:* aging/SLA metrics; automatic due detection |
| Adversarial review + theater-check (manual judgment) | Detect substantive vs theatrical disagreement | Review rows + **`AI.CLASSIFY` / `AI.SCORE` / `AI.GENERATE_BOOL`** to assist theater-check scoring consistently and track it over time |
| `B_Sub_Pattern_Taxonomy.md` (hand-built) | Classify setups into sub-patterns | Keep the doc as methodology **+ BQML `KMEANS`** to *discover/validate* clusters empirically from realized setups. *Extra:* data-driven pattern discovery, not just curation |
| Conviction calibration (today only aspirational/manual) | Are HIGH-conviction theses actually better? | **BQML `LOGISTIC_REG` / `BOOSTED_TREE_CLASSIFIER` + `ML.EVALUATE`** (ROC, calibration) over a decisions→fills→realized-P&L join. *Extra:* quantified, improving calibration + feature importance |
| `.gitattributes` union merge + auto-merge conflict PR | Concurrency-safe appends from parallel routine sessions | **Eliminated for data.** Concurrent `INSERT`/Storage-Write appends don't conflict (first 1,500 inserts/day land immediately). *Extra:* no merge machinery, no conflict PRs |
| Monthly/Quarterly manual aggregation entries | Periodic rollups (regime score, theater survey, performance) | **Scheduled queries + materialized views** compute these continuously. *Extra:* always current, no manual aggregation step |
| git history as the audit/version record | Immutability + diffable provenance | Append-only tables **+ snapshots / time travel / `CHANGES`** **+ scheduled `EXPORT DATA` to GCS or the HF dataset as Parquet** for DR; git still versions the markdown docs |

---

## 3. Architecture overview

```
GCP project: stock-trading-ai   (billing attached; cost caps + custom quota set on day 1)
│
├── dataset events/   ── append-only source of truth (INSERT/Storage Write API only)
│     decision_log, position_events, trade_fills, parking_events,
│     regime_events, queue_events, adversarial_reviews
│
├── dataset state/    ── current-state projections (standard views; windowed "latest wins")
│     current_positions, current_regime, open_queue, trade_fills_curated
│
├── dataset perf/     ── engine outputs built by scheduled queries
│     strategy_daily (deployed-TWR), strategy_monthly (snapshots)
│
└── dataset analytics/── derived intelligence (materialized views, BQML models, embeddings)
      decision_embeddings (+ VECTOR INDEX), conviction_model, setup_clusters,
      twr_forecast, thesis_outcomes (join view), rollup materialized views
```

**Event sourcing in one line:** routines only ever **INSERT** events; "current state" is read from
a **view** that takes the latest event per entity. This sidesteps BigQuery's only sharp edge
(mutating-DML concurrency), preserves full history natively, and matches the append-only ethos.

All tables are **partitioned by date** and **clustered by `strategy, type, ticker`** so the common
queries scan kilobytes, not the whole table — which is exactly what fixes the "file too big" problem
*and* holds the cost at ~$0.

---

## 4. Core schemas (GoogleSQL DDL — illustrative, confirm exact syntax at build time)

### events.decision_log
```sql
CREATE TABLE events.decision_log (
  entry_id       STRING  DEFAULT GENERATE_UUID(),
  event_ts       TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  entry_date     DATE    NOT NULL,          -- logical decision date (partition key)
  entry_type     STRING  NOT NULL,          -- thesis-construction | divergence-review | router-state-change | ...
  strategy       STRING,                    -- 'A'..'E' or NULL
  ticker         STRING,
  decision       STRING,                    -- GO | NO-GO | ACTIVATE | DO-NOT-ACTIVATE | ...
  conviction     STRING,                    -- HIGH | MEDIUM | ...
  sub_pattern    STRING,                    -- SP6, SP4c, ...
  title          STRING,
  body_md        STRING,                    -- full markdown entry (source of truth for substance)
  fields         JSON,                      -- typed/structured per-type fields (flexible schema)
  refs           ARRAY<STRING>,             -- pointers/links to other entries/docs
  tags           ARRAY<STRING>,
  superseded_by  STRING,                    -- entry_id of a Correction entry, if any (append-only correction model)
  source_session STRING,                    -- routine/session id
  PRIMARY KEY (entry_id) NOT ENFORCED
)
PARTITION BY entry_date
CLUSTER BY strategy, entry_type, ticker
OPTIONS (description = 'Append-only decision audit. Never UPDATE/DELETE; corrections are new rows with superseded_by.');
```

### events.trade_fills  (idempotent by IBKR trade_id)
```sql
CREATE TABLE events.trade_fills (
  trade_id    STRING NOT NULL,              -- IBKR key → idempotency
  order_id    STRING,
  ingest_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  fill_ts     TIMESTAMP,
  strategy    STRING, ticker STRING, contract_id INT64,
  side        STRING,                       -- BUY | SELL
  shares      NUMERIC, price NUMERIC, commission NUMERIC, realized_pnl NUMERIC,
  raw         JSON,
  PRIMARY KEY (trade_id) NOT ENFORCED
)
PARTITION BY DATE(fill_ts)
CLUSTER BY strategy, ticker;
```
Idempotency is enforced by the **curated view**, not the engine (PK is `NOT ENFORCED`):
```sql
CREATE VIEW state.trade_fills_curated AS
SELECT * EXCEPT(rn) FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC) rn
  FROM events.trade_fills)
WHERE rn = 1;
```
*(Or, for exactly-once at write time, use a Storage Write API committed stream with offsets.)*

### events.position_events  →  state.current_positions
```sql
CREATE TABLE events.position_events (
  event_id      STRING DEFAULT GENERATE_UUID(),
  event_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  position_key  STRING NOT NULL,            -- stable lot id, e.g. 'B:MDT:2026-06-04'
  event_type    STRING NOT NULL,            -- OPEN | FILL | UPDATE | CRITERION_FLIP | CLOSE
  strategy STRING, ticker STRING, contract_id INT64,
  cost_basis NUMERIC, shares NUMERIC,
  convergence_target NUMERIC, time_exit_date DATE, ltcg_date DATE,
  invalidation_status JSON,                 -- [{criterion, status, as_of}]
  source_thesis_ref STRING,                 -- decision_log.entry_id
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
)
PARTITION BY DATE(event_ts)
CLUSTER BY strategy, ticker, event_type;

CREATE VIEW state.current_positions AS
SELECT * EXCEPT(rn) FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC) rn
  FROM events.position_events)
WHERE rn = 1 AND event_type <> 'CLOSE';
```

### events.regime_events  →  state.current_regime
```sql
CREATE TABLE events.regime_events (
  event_id   STRING DEFAULT GENERATE_UUID(),
  event_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  as_of_date DATE NOT NULL,
  scope      STRING NOT NULL,               -- TECHNICAL_SIGNAL | STRATEGY_ACTIVATION
  key        STRING NOT NULL,               -- indicator name | strategy id
  value      STRING,                        -- NEUTRAL | ACTIVATE | DO-NOT-ACTIVATE | ...
  numeric_value NUMERIC,
  rationale  STRING,
  source_review_ref STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
)
PARTITION BY as_of_date
CLUSTER BY scope, key;

CREATE VIEW state.current_regime AS
SELECT * EXCEPT(rn) FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY scope, key ORDER BY event_ts DESC) rn
  FROM events.regime_events)
WHERE rn = 1;
```

### events.queue_events  →  state.open_queue
```sql
CREATE TABLE events.queue_events (
  event_id  STRING DEFAULT GENERATE_UUID(),
  event_ts  TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  queue     STRING NOT NULL,                -- PENDING_ANALYSIS | WATCHLIST | PENDING_REVIEW
  item_key  STRING NOT NULL,                -- 'olli-thesis-B-20260605'
  status    STRING NOT NULL,                -- OPEN | DUE | COMPLETE | DROPPED
  strategy STRING, ticker STRING, due_date DATE,
  payload JSON, note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
)
PARTITION BY DATE(event_ts)
CLUSTER BY queue, status;

CREATE VIEW state.open_queue AS
SELECT * EXCEPT(rn) FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY queue, item_key ORDER BY event_ts DESC) rn
  FROM events.queue_events)
WHERE rn = 1 AND status NOT IN ('COMPLETE','DROPPED');
```

---

## 5. The deployed-TWR engine, reimagined as a scheduled query

Today's manual chain-linking ("deployed_unit_value ≈ 1.110 (IBM 1.0700 × META 1.0453 × …)")
becomes a **server-side scheduled query** that runs each trading day with no agent involvement.
Chain-linking and the high-water mark are native window functions:

```sql
-- daily scheduled query → perf.strategy_daily
MERGE perf.strategy_daily T
USING (
  WITH daily AS (             -- per-strategy daily return from positions × connector marks
    SELECT as_of_date, strategy, daily_return, sgov_return
    FROM analytics.strategy_daily_returns
  )
  SELECT as_of_date, strategy,
    EXP(SUM(LN(1+daily_return)) OVER w)                         AS deployed_unit_value,
    MAX(EXP(SUM(LN(1+daily_return)) OVER w)) OVER w             AS peak_unit_value,
    EXP(SUM(LN(1+sgov_return))  OVER w)                         AS sgov_index,
    COUNT(*) OVER w                                             AS deployed_days
  FROM daily
  WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date ROWS UNBOUNDED PRECEDING)
) S
ON  T.as_of_date = S.as_of_date AND T.strategy = S.strategy
WHEN MATCHED THEN UPDATE SET
  deployed_unit_value = S.deployed_unit_value,
  peak_unit_value     = S.peak_unit_value,
  sgov_index          = S.sgov_index,
  deployed_days       = S.deployed_days,
  current_drawdown    = S.deployed_unit_value / S.peak_unit_value - 1
WHEN NOT MATCHED THEN INSERT ROW;
```

- **Kill-trigger checks** become SQL predicates over `perf.strategy_daily`
  (`current_drawdown <= -0.50`, doubling, 36-month / ~756 deployed-day M2M window).
- **Forecasting the kill-trigger proximity** with the built-in TimesFM model:
  ```sql
  SELECT * FROM AI.FORECAST(
    TABLE perf.strategy_daily,
    data_col => 'deployed_unit_value', timestamp_col => 'as_of_date',
    id_cols => ['strategy'], model => 'TimesFM 2.5', horizon => 21);
  ```

---

## 6. The flagship analytics (the "maximal capability" payoff)

These are things the markdown system literally cannot do; each is gated behind deliberate,
batched runs because they call Vertex-billed models (see §10).

**A. Semantic precedent search over the decision log** — replaces grep + manual "Precedent:" citing.
```sql
-- one-time + incremental: embed entries
CREATE OR REPLACE MODEL analytics.text_embed
  REMOTE WITH CONNECTION `proj.us.vertex` OPTIONS (endpoint = 'text-embedding-005');

CREATE OR REPLACE TABLE analytics.decision_embeddings AS
SELECT entry_id, entry_date, strategy, entry_type, title, ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(MODEL analytics.text_embed,
       (SELECT entry_id, entry_date, strategy, entry_type, title, body_md AS content
        FROM events.decision_log));

CREATE VECTOR INDEX decision_idx ON analytics.decision_embeddings(embedding)
  OPTIONS (index_type='IVF', distance_type='COSINE');

-- query: "5 most similar past setups to this new one"
SELECT base.entry_id, base.title, distance
FROM VECTOR_SEARCH(TABLE analytics.decision_embeddings, 'embedding',
       (SELECT ml_generate_embedding_result FROM ML.GENERATE_EMBEDDING(
          MODEL analytics.text_embed, (SELECT @new_thesis AS content))),
       top_k => 5, distance_type => 'COSINE');
```

**B. Conviction calibration** — quantifies the experiment's core question.
```sql
CREATE OR REPLACE MODEL analytics.conviction_model
  OPTIONS (model_type='LOGISTIC_REG', input_label_cols=['was_profitable']) AS
SELECT conviction, sub_pattern, strategy, sector, regime_state, was_profitable
FROM analytics.thesis_outcomes;                  -- view: decisions ⨝ fills ⨝ realized P&L

SELECT * FROM ML.EVALUATE(MODEL analytics.conviction_model);   -- ROC, calibration
SELECT * FROM ML.GLOBAL_EXPLAIN(MODEL analytics.conviction_model);  -- feature importance
```

**C. Data-driven sub-pattern discovery** — validates/extends the hand-built taxonomy.
```sql
CREATE OR REPLACE MODEL analytics.setup_clusters
  OPTIONS (model_type='KMEANS', num_clusters=8) AS
SELECT /* setup features */ FROM analytics.setup_features;
```

**D. LLM-in-SQL enrichment** — extract structured fields from prose, score theater-checks.
```sql
-- backfill structured fields from the markdown body
SELECT entry_id, extracted.*
FROM AI.GENERATE_TABLE(
  MODEL analytics.gemini,
  (SELECT entry_id, body_md AS prompt FROM events.decision_log WHERE fields IS NULL),
  STRUCT('convergence_target FLOAT64, conviction STRING, sub_pattern STRING' AS output_schema)) AS extracted;

-- theater-check assist
SELECT entry_id,
  AI.GENERATE_BOOL(('Did this adversarial review surface substantive disagreement? ', body_md),
                   connection_id => 'proj.us.vertex').result AS substantive
FROM events.adversarial_reviews;
```

---

## 7. Audit & immutability (preserves the experiment's prized guarantee)

The Decision Log's "append-only, never modified" rule is enforced **structurally** and backed by
native point-in-time tooling:
- **Append-only by convention + monitoring:** routines only INSERT; corrections are new rows
  (`superseded_by`). A scheduled check can alert on any `UPDATE`/`DELETE` against `events.*`.
- **Time travel** (7 days; up to 14 on Enterprise Plus): `SELECT … FOR SYSTEM_TIME AS OF …`.
- **`CHANGES` / `APPENDS` TVFs:** row-level history of what landed when (enable change history).
- **Table snapshots** (cheap differential, read-only) on a schedule → long-term immutable points.
- **DR export:** scheduled `EXPORT DATA … AS PARQUET` to GCS **or** push to the existing Hugging
  Face dataset repo (git-versioned, 100 GB free) → keeps a diffable, off-platform audit copy.

---

## 8. Concurrency & idempotency

- **Appends never conflict.** Multiple routine sessions INSERT concurrently; first 1,500
  inserts/day land immediately. No union-merge driver, no conflict PRs.
- **Idempotency** (re-running D2 reconciliation) is handled by **dedup views** keyed on `trade_id`
  / natural keys, or by **Storage Write API committed streams with offsets** for exactly-once.
- **Avoid routine `UPDATE`/`DELETE`.** Mutating DML serializes (2 concurrent + 20 queued per
  table). The event-sourced model means you essentially never issue them; reserve them for rare
  curated rebuilds.

---

## 9. Orchestration — who does what

**Server-side scheduled queries (no agent tokens):**
- daily `perf.strategy_daily` TWR/drawdown/benchmark + kill-trigger flags
- surface due/overdue `state.open_queue` items
- incremental embeddings for new `decision_log` rows + vector-index maintenance
- monthly/quarterly rollups (materialized views refresh automatically)
- periodic table snapshots + Parquet export (DR)

**Agent-side (via the BigQuery MCP connector):**
- reads: targeted `SELECT` over views (replaces whole-file loads) + `VECTOR_SEARCH` precedent lookup
- writes: `INSERT` decision/regime/queue/position events
- on-demand analysis: calibration eval, forecasts, ad-hoc questions

Net effect: routines get **smaller and cheaper** — they query rows instead of loading 14k-line
files, and hand recurring maintenance to scheduled queries.

---

## 10. Cost governance (hard ceiling « $1/month)

**Analytic core = ~$0, structurally:**
- Free tier: 10 GB storage + 1 TB scanned/month. Your data is ~6 MB now (~10 MB/yr growth) → you
  cannot approach either for decades.
- **Partition + cluster** so queries prune to KB. **Materialized views** avoid re-scanning.
- **`maximum_bytes_billed`** default on every query (over-limit queries fail free) **+ custom daily
  quota** (e.g. 5 GB/day project-level) → overspend is *impossible*, not merely unlikely.
- Choose **physical storage billing** if cheaper for compressed data; long-term storage auto-halves
  after 90 days.

**The one watch-item — AI/ML features are Vertex-billed (per token), not free-tier query:**
- Embedding the *entire* current log once ≈ a few million tokens ≈ **cents** (≈$0.10–0.15/1M tokens).
- `AI.GENERATE*` (Gemini) per-row over large sets is where cost could grow → **batch + run on
  demand**, not in every routine. BQML training (`LOGISTIC_REG`, `KMEANS`, ARIMA) is occasional.
- Keep these behind explicit, infrequent jobs; at this data size they stay in pennies, but they are
  the only place to watch. **Continuous queries** (real-time) need slot reservations (real compute
  cost) → **not** for this budget; use scheduled queries instead.
- New GCP accounts get **$300 / 90-day** credits, covering all experimentation.

---

## 11. Connectivity / access

- **GCP project + billing + enable BigQuery API**, then connect via the **managed remote BigQuery
  MCP server** (Google's MCP Toolbox for Databases, v1.0 GA) — the latest, production-ready path.
- **Service account**, least privilege: `BigQuery Data Editor` + `BigQuery Job User`, scoped to the
  project/datasets; for AI features add a Vertex AI connection. No raw keys in the repo — auth lives
  in the connector config.
- **Reachability:** MCP traffic is proxied through Anthropic's servers (works regardless of the
  environment's network policy); BigQuery's REST endpoints are also on the default-Trusted allowlist
  (`*.googleapis.com`). Both channels work here.
- **Only you can wire the connector** (account/billing/credentials). Everything after that —
  schema, views, scheduled queries, models, migration — is buildable by the routine.

---

## 12. Migration plan (one-time, executed once the project + connector exist)

1. **Create** project, datasets, tables (§4), and set cost caps + custom quota (§10) on day 1.
2. **Parse** markdown → newline-delimited JSON:
   - `Decision_Log*.md`: split on `^### \[YYYY-MM-DD\] …` headers → columns + `body_md`; leftover
     structured bits → `fields` JSON.
   - `Portfolio_Ledger.md`, `Regime_State.md`, queues: more bespoke parsers (their schemas are
     documented in-file).
3. **Load** via `LOAD` jobs (NDJSON/Parquet) into `events.*`.
4. **Build** views, materialized views, scheduled queries, BQML models, embeddings + vector index.
5. **Parallel-run** (write both markdown and BigQuery) for a short validation window; reconcile.
6. **Cut over**: routines read/write BigQuery; retire the archive files, the union-merge driver, and
   the conflict-PR path **for data**; keep markdown + git for the docs.
7. **Edit** `Operating_Protocols.md` / `Claude_Task_Plan.md` to describe BigQuery procedures (the
   D1/D2/D3 daily, weekly, monthly, quarterly routines now query/insert instead of read/append).

---

## 13. Decisions needed from you (before any build)

1. **GCP project name + region** (e.g. `US` multi-region vs a specific region — affects latency and
   some feature availability).
2. **Human-readability:** do you want a scheduled **markdown/Sheets export** so you can still eyeball
   the data, or is the BigQuery console (SQL) enough?
3. **AI-feature appetite now vs later:** adopt embeddings + calibration + LLM-enrichment from day one,
   or stand up the plain event store first and layer intelligence in phase 2?
4. **Audit cadence:** is 7-day time travel + periodic snapshots + Parquet export sufficient, or do you
   want a tighter snapshot/export schedule?
5. **Keep a markdown mirror at all,** or go BigQuery-only for the migrated data?

---

## Sources (verified June 2026)

- AI functions / AI.FORECAST (TimesFM): https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-forecast , https://cloud.google.com/blog/products/data-analytics/sql-reimagined-for-the-ai-era-with-bigquery-ai-functions
- Vector search / embeddings: https://docs.cloud.google.com/bigquery/docs/vector-search , https://docs.cloud.google.com/bigquery/docs/vector-index
- Storage Write API (vs legacy streaming): https://docs.cloud.google.com/bigquery/docs/write-api , https://docs.cloud.google.com/bigquery/docs/write-api-best-practices
- Materialized views (window-function limits): https://docs.cloud.google.com/bigquery/docs/materialized-views-intro
- Primary/Foreign keys (NOT ENFORCED): https://docs.cloud.google.com/bigquery/docs/primary-foreign-keys
- Continuous queries: https://docs.cloud.google.com/bigquery/docs/continuous-queries-introduction
- Time travel / snapshots / CHANGES & APPENDS TVF: https://docs.cloud.google.com/bigquery/docs/time-travel , https://docs.cloud.google.com/bigquery/docs/table-snapshots-intro
- DML limits/quotas: https://docs.cloud.google.com/bigquery/docs/data-manipulation-language , https://docs.cloud.google.com/bigquery/quotas
- Cost controls / pricing: https://docs.cloud.google.com/bigquery/docs/custom-quotas , https://cloud.google.com/bigquery/pricing
- BigQuery MCP / Toolbox: https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp , https://github.com/googleapis/mcp-toolbox

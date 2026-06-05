# BigQuery System Redesign v2 — Maximal-Capability Build Spec

**Status:** BUILT — infrastructure phase complete (2026-06-05). Supersedes
`BigQuery_System_Redesign.md` (v1). The data layer, semantic-precedent layer, deployed-TWR engine,
and daily briefing are live on project `stock-trading-498512` (US multi-region). The deployed-TWR
engine is **validated** (rebuilt from authoritative connector fills, hand-checked to 0.04%). See **Build
status & findings** below for the as-built state, the findings, and remaining next-phase work.

**What v2 changes vs v1.** v1 was a sound *storage* migration (event-sourced append-only tables,
state views, a scheduled TWR query) that treated AI/ML as an optional phase-2. v2 keeps that spine
and pushes three things further, per the directive to *use every AI/ML capability where value ≥ 0
and redesign the workflow if there's a better way*:

1. **Reframes the project** around what the experiment's own constitution already demands but the
   markdown substrate cannot deliver: a **classical-ML delegation + calibration layer** (edges 1.8 /
   2.12, §3a.1) and a **ground-truth state engine** for the deployed-TWR/kill math.
2. **Redesigns the operational loop**, not just the data store: the mechanical half of every routine
   moves to server-side SQL/scheduled jobs, and the agent reads a single **Daily Briefing** instead
   of loading the 820-line ledger + cross-checking the connector + scanning the 14.5k-line log.
3. **Adopts the full 2026 AI/ML surface day-one** (vector search, BQML, `AI.*` functions,
   `AI.FORECAST`, `CONTRIBUTION_ANALYSIS`, anomaly detection), each mapped to a concrete use, value
   tier, and cost bucket — gated by `AI.COUNT_TOKENS` + a billing budget alert so the Vertex-billed
   pieces stay in pennies.

---

## Build status & findings (2026-06-05)

**Live in `stock-trading-498512`** (committed as `bigquery/01–05_*.sql` + parsers + `load_all.py`):
- **Data layer** — 7 event tables + 4 state views; full migration of every data file incl. all 3
  archives + the queue archives + monthly fundamental regime scores (~340 rows). `Decision_Log.md` +
  its archive are ONE `events.decision_log` table (the whole archive workflow is retired).
- **Semantic precedent** — `analytics.find_precedents('<thesis>')` over 221 embeddings (validated).
  Replaces grepping the 14.5k-line log.
- **Theater-independence** — `analytics.theater_independence` (raw full-transcript similarity is
  topically saturated ~0.95 → P2 refinement: verdict-only / `AI.GENERATE_BOOL` judge).
- **Deployed-TWR engine — LIVE + VALIDATED.** `perf.strategy_daily` (value-weighted daily
  **total-return, NET-of-commission** TWR) + `perf.kill_flags` (4 triggers; none firing);
  `events.daily_marks` (D2-fed, corporate-action aware); `analytics.sgov_daily_return` (actual SGOV
  total return). Populated 2026-06-05 from 385 real daily marks + the 14 authoritative connector fills;
  full 29-day series computed; independently hand-checked to 0.04% on D. **The legacy markdown
  hand-method is RETIRED** (engine stands alone with an automated sanity guardrail).
- **Daily briefing** — `state.daily_briefing` (due queue + kill-flags + time-exits).
- **Analytics scaffold** — `analytics.thesis_outcomes` (calibration foundation).

**Material findings:**
1. **Deployed-TWR overstatement — found, corrected, VALIDATED.** The ledger's seed sequentially
   chain-linked *concurrent independent* closed trades, overstating **Strategy B to +11% / 1.1099**.
   Validated value-weighted figures: **B 0.9663 (−3.37% net), D 0.9573 (−4.27%)**, both trailing SGOV
   (1.0041); no kill/gate trigger near firing. The live `Portfolio_Ledger.md` has been corrected to the
   validated figures (supersedes the interim 0.992 estimate).
2. **Migrated event data was INCOMPLETE (data-quality).** The v1 migration loaded only the 10 entry
   fills into `events.trade_fills` (no exits) with NULL shares + placeholder dates in
   `position_events` — so the engine could not have been correct until rebuilt. Rebuilt both from the
   connector's 14 authoritative fills; `position_lifecycle` re-sourced from `trade_fills`. (`position_events`
   itself still carries stale rows — the engine no longer reads it; flagged for a follow-up rebuild.)
3. **Commission drag dominates at this scale.** GROSS (pre-commission) deployed-TWR is B **+0.05%**
   (flat) — the stock-picking ~broke even — but ~$0.32 commission per ~$30 trade (~1%/fill, 12 fills)
   drags B to −3.4% net. A structural artifact of ~2%-of-sleeve (~$30–38) position sizing; worth a
   parameter discussion.
4. **SGOV / corporate-action handling (`03_twr_engine.sql`).** Five dividend/split gaps found + fixed:
   SGOV benchmark uses actual total return (not a proxy); the IBKR DRIP reinvest is reclassified
   `DIVIDEND_REINVEST` (not a trade buy); held-stock dividends added to the TWR (confirmed: IBM $1.69,
   RTX $0.73 captured); `daily_marks` captures dividends + splits; D2 must pull
   `include_corporate_actions=true`.

**Remaining (next phase):**
- **Cold-start analytics** — conviction/calibration/attribution/forecast/anomaly: plumbing
  scaffolded, models deferred until ~30 closed trades. Needs `decision_log.ticker` backfill
  (`AI.GENERATE_TABLE`) + realized P&L (now in `trade_fills`) to populate `thesis_outcomes` labels.
- **`position_events` rebuild** — fix the stale migrated rows (engine-independent now, but
  `state.daily_briefing`'s due-exit / convergence-target fields read it).
- **Historical-data migration (owner-flagged)** — adversarial-review outputs
  (`Adversarial_Review_*`) + monthly macro/regime docs (`Monthly_Macro_Data_*`) → BigQuery for
  tracking; additive, low-risk.
- **Data-`.md` retirement** — the *engine* cutover is DONE (validated, hand-method retired, D1/D2
  procedures rewired). What remains is retiring the migrated *data* `.md` files as the operational
  substrate — consequential, owner-gated, deserves deliberate review.
- **Optional** — BLS/SEC public-data wiring (P2); scheduled-query automation (console/DTS) vs. agent-run.
- **Operational** — correct the live ledger B TWR; the `bq-loader` SA key is deleted. Cost to date
  ≈ **$0.12** (Vertex embeddings; all else free-tier).

---

## 1. Reframe — three pillars

The experiment's deliverable is explicitly *infrastructure* — "process, calibration data, mistake
catalog — designed to transfer forward when better models arrive" (`Experiment_Parameters.md`). Read
against that, BigQuery is not a database swap; it is the substrate for three capabilities the
constitution asks for and markdown can't provide:

| Pillar | What the constitution says | What v2 builds |
|---|---|---|
| **A. Ground-truth state engine** | Deployed-TWR feeds 4 kill triggers + the 30-trade gate, yet the chain-link formula is *never written down* (digest finding); precision risks 2.11/2.25 (phantom state) | Canonical SQL deployed-TWR engine (§5): value-weighted daily return → geometric chain-link → high-water mark → SGOV-benchmark → excess; kill-triggers as predicates. State externalized to ground truth. |
| **B. Classical-ML delegation + calibration** | §3a.1: raw LLM probabilities "should not be treated as usable EV inputs without … calibration against realized outcomes … or delegation … to classical methods." Edges 1.8/2.12: "classical gradient-boosted methods and Ridge regression outperform LLMs on tabular financial reasoning." | BQML `LOGISTIC_REG`/`BOOSTED_TREE` conviction model + `ML.EVALUATE` calibration (ROC/ECE) per strategy×sub-pattern, the **calibration map** that turns the experiment's *honest miscalibration tracking* (edge 1.7) into a usable signal. (§6) |
| **C. Semantic retrieval + LLM-in-SQL** | 677 hand-cited `Precedent:` references in a 14.5k-line live log with **no index**; deep-research prompts demand precedent "retrieved, not recalled" | Embeddings + `VECTOR_SEARCH` precedent retrieval; `AI.CLASSIFY` sub-pattern routing; `AI.GENERATE_TABLE` field extraction; `AI.SIMILARITY` adversarial-independence scoring. (§7–8) |

**The unifying principle (unchanged from v1):** event-sourced, append-only. Routines only `INSERT`;
"current state" is a *view* over the latest event per entity. This matches the append-only ethos,
sidesteps BigQuery's one sharp edge (mutating-DML concurrency), and preserves full history natively.

---

## 2. The workflow redesign — the agent's job shrinks to judgment

### 2.1 The automation boundary

From the routine digest, work cleaves cleanly:

- **Mechanical → server-side SQL (no agent tokens):** D1's exit-trigger sweep and kill-trigger
  sweep; *all* of D2 Step 0 (trade_id reconciliation, cash/SGOV §13 drift tripwire, the deployed-TWR
  chain-link arithmetic); D3's queue-archive + calendar hygiene flags; the universe-screening filters
  inside W1/W2/W3/M3/Q2 (mcap/ADV/≥5%-move/252-day-corr); M5 §H's 30-trade-gate + M2M arithmetic.
- **Judgment → stays the agent:** the open-universe market scan and event interpretation (D1
  categories 1–5), every GO/NO-GO/exit/termination *decision*, M1a regime scoring, the deep-research
  narrative syntheses (W3/M4/Q1/Q2/Q3), and the adversarial Attacker/Orchestrator reasoning.

> **Rule of thumb that anchors the whole redesign:** *machines compute state, indices, and threshold
> flags; the agent decides and writes theses.*

### 2.2 The Daily Briefing — one SELECT replaces three expensive reads

A server-side procedure (`ops.sp_daily_refresh`, §13) materializes `state.daily_briefing` before the
agent wakes. D1/D2 open with a single small `SELECT * FROM state.daily_briefing` instead of loading
`Portfolio_Ledger.md` (820 lines) + cross-checking the connector + scanning `Decision_Log.md`
(14.5k lines). The briefing carries, per run:

- **Exit-trigger table** — every open position with live mark vs convergence target and time-exit
  date, `EXIT_TRIGGERED` boolean (the table `Daily.md` builds by hand today).
- **Kill-trigger status** — per strategy: `deployed_unit_value`, `peak`, `current_drawdown`,
  `drawdown_kill` (≤−50%), `runaway_review` (doubled pre-gate), `m2m_underperf` (≥10pp vs SGOV over
  rolling-12mo after 36 deployed-months), gate `n/30`.
- **Reconciliation delta** — new `trade_id`s since last run with price/commission/realized P&L, plus
  the §13 cash/SGOV tripwire (expected-from-ledger vs live-connector, `residual`, `HARD_STOP` if
  unexplained > $1).
- **Queue due-list** — `state.open_queue` items with `due_date <= today`, aged.
- **Forecast & anomaly flags** — `AI.FORECAST` kill-trigger-proximity (§9) and
  `ML.DETECT_ANOMALIES` hits on returns/positions.
- **Precedent hooks** — for each open thesis, the top-k semantically nearest past decisions (§7), so
  precedent arrives pre-retrieved rather than grep-scanned.

The connector remains authoritative for raw fills/positions/cash/quotes; BigQuery is the per-strategy
attribution + TWR + analytics layer downstream of it. D2 Step 0 still *writes* the reconciled events
(it's where IBKR truth enters BigQuery), but the arithmetic it used to do by hand is now a view.

### 2.3 Redesigned daily loop

- **D1** — reads `state.daily_briefing` (sweeps already computed) → spends tokens only on the
  open-universe scan + judgment thesis-invalidation/opportunity checks → `INSERT`s any
  `[HF Frontier-LLM Capture]` and candidate rows. No whole-file loads.
- **D2** — Step 0 becomes: `CALL ops.sp_daily_refresh()` (ingest new fills via Storage Write API /
  `INSERT`, refresh state) then read the briefing's reconciliation delta + `HARD_STOP` flag. Step 1
  drains `state.open_queue` due items (judgment) and, **before logging any GO, calls the conviction
  gate (§2.5)**. Writes are `INSERT`s into `events.*`; no in-place ledger edits to merge-conflict.
- **D3** — reads `state.open_queue` + `state.calendar_actions` (server-computed terminal-entry and
  stale-order flags) and acts on them; the manual sweep disappears.

### 2.4 Redesigned weekly / monthly / quarterly

Each deep-research routine keeps its judgment core but is *fed* a server-built candidate set: the hard
screening filters run as scheduled queries into `analytics.screen_*` tables (A/C catalysts, B
post-event ≥5% movers in-window, D/Q2 eligibility, E pairs with 252-day corr ≥0.5). The agent ranks
and writes the narrative; it no longer reconstructs the universe by hand. M5 §H reads
`perf.gate_status` instead of doing haircut arithmetic. Monthly/quarterly rollups become materialized
views (always current). M1a regime *scoring* stays agent judgment (and stays strategy-blind — see the
blinding note in §6).

### 2.5 The conviction gate (the doctrine, operationalized)

This is the highest-leverage new step and it directly discharges §3a.1. Before the agent logs a GO, it
runs one query:

```sql
-- inputs: the candidate's features (strategy, sub_pattern, sector, regime_state, conviction tier, …)
SELECT
  p.predicted_was_profitable_probs,                    -- calibrated P(profitable) from BQML
  cal.empirical_hit_rate, cal.n_outcomes, cal.ece,     -- this bucket's realized calibration (§6)
  prec.top_precedents                                  -- §7 nearest past setups + their outcomes
FROM ML.PREDICT(MODEL analytics.conviction_model, (SELECT @candidate_features)) p
LEFT JOIN analytics.calibration_map cal USING (conviction, sub_pattern, strategy)
LEFT JOIN analytics.precedent_lookup(@new_thesis_text) prec ON TRUE;
```

The agent's *stated* ordinal conviction now meets a **classical, calibrated probability + the realized
hit rate of that exact bucket + the nearest historical analogues and how they resolved.** Sizing stays
the fixed 2% (conviction is decoupled from sizing by design); the gate informs the binary enter
decision and is logged for the calibration loop to keep learning. When `n_outcomes` is small the gate
reports wide CIs and says so — preserving the experiment's sample-size honesty (2.21).

---

## 3. Architecture

```
GCP project: stock-trading-498512  (US multi-region; 32 GB/day query quota + billing budget alert)
│
├── events/    append-only source of truth (INSERT / Storage Write API only)
│     decision_log, position_events, trade_fills, parking_events,
│     regime_events, queue_events, adversarial_reviews, hf_capability_captures
│
├── state/     current-state projections (STANDARD views; windowed "latest wins")
│     current_positions, current_regime, open_queue, trade_fills_curated,
│     daily_briefing, calendar_actions
│
├── perf/       engine outputs (scheduled-procedure + materialized views)
│     strategy_daily (deployed-TWR), strategy_monthly, gate_status, kill_flags
│
├── analytics/  derived intelligence (BQML models, embeddings, MVs)
│     decision_embeddings (+VECTOR INDEX), conviction_model, conviction_model_gbt,
│     calibration_map, setup_clusters, twr_forecast, anomaly_flags,
│     attribution (CONTRIBUTION_ANALYSIS), thesis_outcomes (join view),
│     theater_independence, screen_A/B/C/D/E (universe filters), rollup MVs
│
└── ops/        connections, remote models, procedures, audit
      sp_daily_refresh, sp_weekly_refresh, vertex connection, gemini_flash / text_embed models,
      snapshot + Parquet-export jobs
```

All `events.*` tables are **partitioned by date** and **clustered by `strategy, type, ticker`** so the
common queries prune to KB. Event-sourcing keeps INSERTs concurrency-free (no union-merge driver, no
conflict-PR path for data); the markdown auto-merge flow remains only for the constitution docs.

---

## 4. Maximal AI/ML capability catalog (use them all, value ≥ 0)

Every applicable 2026 BigQuery AI/ML surface, mapped to a concrete use here, with value tier and cost
bucket. **Free** = byte-billed under the 1 TiB/mo free tier. **Vertex¢** = Vertex-billed per
token/char (no BQ free tier) but pennies at our ~6 MB scale. Priority: **P1** day-one, **P2** as
outcomes accrue, **P3** marginal/experimental (kept because value ≥ 0, but low effort budget).

| Capability | Concrete use | Tier | Value | Cost |
|---|---|---|---|---|
| `ML.GENERATE_EMBEDDING` / `AI.EMBED` | Embed every decision-log entry, thesis, adversarial review | P1 | High | Vertex¢ (~$0.15 backlog) |
| `VECTOR_SEARCH` + `CREATE VECTOR INDEX` | Semantic precedent retrieval (replaces 677 hand `Precedent:` refs + log scans); near-duplicate thesis detection | P1 | High | Free |
| `LOGISTIC_REG` conviction model | Calibrated P(profitable) by conviction×sub_pattern×strategy×regime — the §3a.1 delegation | P1→P2 | Core | Free |
| `ML.EVALUATE` / `ML.GLOBAL_EXPLAIN` | ROC, ECE, calibration curve, feature importance | P1→P2 | High | Free |
| `CONTRIBUTION_ANALYSIS` (`ML.GET_INSIGHTS`) | Auto-attribution: which strategy/sector/sub-pattern/regime drives Δ excess-return (router value is otherwise *unmeasurable* per the digest) | P2 | High | Free |
| `AI.SIMILARITY` / embeddings | Quantify semantic independence of attacker vs orchestrator → detect the 8/8-CONVERGENT theater degeneration | P1 | High | Vertex¢ |
| `AI.CLASSIFY` | Route a NO-GO into its B sub-pattern (SP1/SP4c/Pattern N…); classify entry_type | P2 | Med-High | Vertex¢ |
| `AI.GENERATE_TABLE` | Extract structured fields (convergence_target, conviction, invalidation criteria) from prose `body_md` — migration backfill + ongoing | P1 (migration) | Med-High | Vertex¢ one-time |
| `BOOSTED_TREE_CLASSIFIER` | Nonlinear conviction/outcome model + importance; the GBM the foundation prefers for tabular | P2 | Med | Vertex¢ (training) |
| `KMEANS` | Empirically discover/validate B sub-patterns; cluster failure modes | P2 | Med | Free |
| `ARIMA_PLUS` / `ARIMA_PLUS_XREG` | Forecast regime indicators (VIX, breadth) & macro; native anomaly handling; XREG = TWR with regime regressors | P2 | Med | Free |
| `AI.FORECAST` (TimesFM) | Zero-setup forecast of deployed-TWR / drawdown / kill-trigger proximity per strategy | P2 | Med | Free |
| `ML.DETECT_ANOMALIES` | Flag anomalous daily returns, positions, reconciliation residuals | P2 | Med | Free |
| `AI.SCORE` | Rank candidate setups by thesis-quality rubric; score reviews for substance | P2 | Med | Vertex¢ |
| `AI.GENERATE` / `ML.GENERATE_TEXT` | Generate the briefing narrative, pre-mortem red-team prompts, monthly survey summaries | P2 | Med | Vertex¢ |
| `AI.GENERATE_BOOL` | Theater-check assist; criterion-flip detection from notes | P2 | Med | Vertex¢ |
| `AI.COUNT_TOKENS` | Pre-estimate Gemini cost before any batch (AI-side dry-run) | P1 | High (cost ctrl) | Free |
| `SEARCH` index | Keyword/full-text search over bodies (complements vector) | P3 | Low-Med | Free |
| `PCA` / `AUTOENCODER` | Setup-feature reduction; autoencoder reconstruction-error anomaly flag | P3 | Low-Med | Free / Vertex¢ |
| `AI.IF` / `AI.AGG` / `AI.GENERATE_INT/DOUBLE` | LLM-predicate filtering; NL summarize an entry set; numeric extraction | P3 | Low-Med | Vertex¢ |
| `MATRIX_FACTORIZATION` / `WIDE_AND_DEEP` / `DNN` | ticker×pattern affinity; deep models — kept for completeness, low value at this sample size | P3 | Low | Free / Vertex¢ |
| Time travel / snapshots / `CHANGES` TVF | Native point-in-time audit of the append-only log | P1 | High | Free |

> **Cost-bucket note for "max capability":** `BOOSTED_TREE`, `RANDOM_FOREST`, `DNN`, `AUTOENCODER`
> train via **Vertex AI** (compute-billed, not the 10 GB BQML free tier) — still cents per run at our
> data size, but not free. `LOGISTIC_REG`/`LINEAR_REG`/`KMEANS`/`PCA`/`ARIMA_PLUS`/
> `CONTRIBUTION_ANALYSIS`/`AI.FORECAST`/`VECTOR_SEARCH` are **byte-billed → free**. So the default
> conviction model is logistic (free); the boosted-tree is an opt-in comparison.

---

## 5. The deployed-TWR engine, fully specified

The digest flagged that the most load-bearing computation (feeds 4 kill triggers + the gate) has a
*conceptual* definition but no written formula. v2 specifies it. TWR is computed on **deployed capital
only**, flow-immune by construction by using a **value-weighted daily return of held positions** (so
capital moving in/out of the SGOV sleeve never distorts it):

**Daily deployed return** for strategy `s` on a *deployed* day `t` (≥1 open position):

```
r_{s,t} = Σ_i  w_{i,t-1} · ( (MV_{i,t} + div_{i,t}) / MV_{i,t-1} − 1 )
   where w_{i,t-1} = MV_{i,t-1} / Σ_j MV_{j,t-1}      (prior-EOD value weights)
   exits realize at fill price on the exit day; corporate actions via connector
```

Days with zero open positions (fully parked / deactivated) **do not advance** either chain — matching
"TWR on deployed capital only" and the rule that the 36-month M2M clock "accumulates only during
deployed periods." Then, as a scheduled-procedure step writing `perf.strategy_daily`:

```sql
SELECT as_of_date, strategy,
  EXP(SUM(LN(1 + r_deployed)) OVER w)               AS deployed_unit_value,   -- geometric chain-link
  MAX(EXP(SUM(LN(1 + r_deployed)) OVER w)) OVER w   AS peak_unit_value,        -- high-water mark
  EXP(SUM(LN(1 + r_sgov))    OVER w)                AS sgov_index,             -- benchmark, same days
  COUNT(*) OVER w                                   AS deployed_days
FROM analytics.strategy_daily_returns               -- r_deployed (above), r_sgov for deployed days
WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date ROWS UNBOUNDED PRECEDING);
-- derived: current_drawdown = deployed_unit_value/peak_unit_value − 1
--          excess           = deployed_unit_value/sgov_index − 1   (pre tax/inflation haircut)
```

**Kill-triggers** (predicates over `perf.strategy_daily` → `perf.kill_flags`):

| # | Trigger | Predicate |
|---|---|---|
| 1 | Drawdown (immediate, mechanical) | `current_drawdown <= -0.50` |
| 3 | Runaway-success (pre-gate only) | `deployed_unit_value >= 2 AND closed_trades < 30` |
| 4 | M2M underperformance | `deployed_days >= ~756 (36 mo) AND min over any rolling-12mo of (deployed_unit_value/sgov_index − 1) <= -0.10` (M2M includes unrealized P&L) |
| Gate | 30-trade go/no-go | `closed_trades >= 30 AND excess_real_return >= 0` (post-tax, post-inflation haircut) |

**Forecast overlay (P2):** `AI.FORECAST(TABLE perf.strategy_daily, data_col=>'deployed_unit_value',
timestamp_col=>'as_of_date', id_cols=>['strategy'], horizon=>21)` projects kill-trigger proximity so
the briefing can warn *before* a threshold is hit.

**Finalized convention (locked 2026-06-05).** Value-weighted daily TWR, deployed-days-only chain —
the gold-standard, flow-immune reading. Edge cases specified so the engine is deterministic:
- **Deployed day** = strategy holds ≥ 1 open position at the prior session close; the chain advances
  only on deployed days (parked/deactivated days don't accrue, matching the 36-month M2M clock rule).
- **Entry day:** a newly opened lot has zero prior-EOD MV → weight 0 that day (its fill→first-close
  move is captured implicitly in the *next* session's return). First-trade date = first fill date;
  the deployed chain's first return is the following session. (Standard daily-valuation TWR.)
- **Exit day:** the lot's return = exit-fill / prior-EOD-MV − 1, weighted by prior-EOD MV (captures
  the exit move).
- **Total return:** dividends / corporate actions added to the numerator via the connector's
  `include_corporate_actions` flag.
- **SGOV benchmark:** the same geometric chain over SGOV daily total return, restricted to the
  strategy's deployed days (answers "what SGOV returned over exactly the periods this strategy was
  deployed"). `excess_real = deployed_unit_value / sgov_index − 1`, then post-tax + post-inflation
  haircut for the gate.

This is flow-immune by construction (it averages held-position returns; capital entering/leaving never
manufactures a return). It will still be **validated against the IBKR connector** on real positions
during parallel-run before any kill-trigger decision relies on it.

---

## 6. Classical-ML delegation + calibration layer

`analytics.thesis_outcomes` (view) joins `events.decision_log` ⨝ `state.trade_fills_curated` ⨝
realized P&L ⨝ `state.current_regime` (regime as-of the decision date) → one row per closed thesis
with `was_profitable`, return, hold days, and features (conviction tier, sub_pattern, strategy,
sector, regime_state, days_in_window, implied_upside, …).

```sql
-- free, built-in; the §3a.1 "delegate probability to classical methods"
CREATE OR REPLACE MODEL analytics.conviction_model
  OPTIONS (model_type='LOGISTIC_REG', input_label_cols=['was_profitable'],
           auto_class_weights=TRUE, data_split_method='SEQ', data_split_col='entry_date') AS
SELECT conviction, sub_pattern, strategy, sector, regime_state, days_in_window, was_profitable
FROM analytics.thesis_outcomes WHERE was_profitable IS NOT NULL;

SELECT * FROM ML.EVALUATE(MODEL analytics.conviction_model);        -- ROC-AUC, log loss
SELECT * FROM ML.GLOBAL_EXPLAIN(MODEL analytics.conviction_model);  -- feature importance
```

**The calibration map** — turns edge 1.7 (honest miscalibration tracking) into a usable signal,
per strategy × sub_pattern × conviction tier, with realized hit rate, n, and Expected Calibration
Error, plus Wilson CIs that stay wide until n crosses the foundation's 30-outcome (directional) /
200-outcome (statistical) thresholds:

```sql
CREATE OR REPLACE TABLE analytics.calibration_map AS
SELECT strategy, sub_pattern, conviction,
       COUNT(*) AS n_outcomes,
       AVG(CAST(was_profitable AS INT64)) AS empirical_hit_rate,
       /* Wilson lower/upper, ECE vs stated-tier midpoint */
FROM analytics.thesis_outcomes WHERE was_profitable IS NOT NULL
GROUP BY strategy, sub_pattern, conviction;
```

Retrained by the weekly refresh procedure as outcomes accrue. `BOOSTED_TREE_CLASSIFIER` (P2, Vertex¢)
is trained alongside as the GBM comparison the foundation prefers for tabular reasoning; both feed the
conviction gate (§2.5). **Edge-decay monitors** (hit rate across consecutive 10-trade windows, D's
24-month alpha-vs-SPY-synthetic with CI gating, E's entry-percentile↔P&L rank correlation) become
windowed queries over `thesis_outcomes`.

> **Blinding preserved:** M1a regime scoring stays strategy-blind and stays in the agent; the ML layer
> reads only *persisted, post-decision* outcomes, so it cannot leak strategy mappings back into the
> blinded scoring step. Calibration is a backward-looking diagnostic, not an input to M1a.

---

## 7. Semantic retrieval + LLM-in-SQL enrichment

```sql
CREATE OR REPLACE MODEL ops.text_embed
  REMOTE WITH CONNECTION `stock-trading-498512.us.vertex`
  OPTIONS (endpoint = 'text-embedding-005');           -- or gemini-embedding-001

CREATE OR REPLACE TABLE analytics.decision_embeddings AS
SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, title, ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(MODEL ops.text_embed,
       (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, title,
               CONCAT(title,'\n',body_md) AS content FROM events.decision_log));

CREATE VECTOR INDEX decision_idx ON analytics.decision_embeddings(embedding)
  OPTIONS (index_type='IVF', distance_type='COSINE');
```

- **Precedent lookup (replaces grep + hand `Precedent:` citing):** `VECTOR_SEARCH` top-k nearest past
  setups to a new thesis, joined to their realized outcomes — surfaced in the briefing and the
  conviction gate. Incremental embedding of new rows runs in the daily refresh (pennies).
- **Near-duplicate / "have we rejected this before?":** cosine distance threshold flags a candidate
  that matches a prior NO-GO; `AI.CLASSIFY` proposes the matching B sub-pattern code (SP1…Pattern N).
- **Migration field extraction:** `AI.GENERATE_TABLE` parses `body_md` → typed `fields` (convergence
  target, conviction tier, invalidation criteria status) where the markdown wasn't already structured.

---

## 8. Theater-check independence + adversarial analytics

The CONVERGENT-rate problem ("8 of 8 cycles produced CONVERGENT theater-check flags") is a *measurable*
adversarial-independence failure. Embed the attacker and orchestrator outputs of each review; compute:

```sql
SELECT review_id, strategy, review_type,
  AI.SIMILARITY(attacker_text, orchestrator_text,
                connection_id => 'stock-trading-498512.us.vertex') AS independence_inv,  -- high sim ⇒ low independence
  -- base-rate-adjusted CONVERGENT rate over trailing reviews
FROM events.adversarial_reviews_paired;
```

High similarity + a self-certified CONVERGENT flag ⇒ ratification, not independent reasoning →
surfaced as an **architectural-drift alert**. This operationalizes router pre-mortem indicators 9.2
(CONVERGENT rate ≥ 50% over ≥ 6 reviews) and 9.4 (chronic default-deny ≥ 40% over ≥ 5) as standing
queries instead of manual monthly surveys.

---

## 9. Attribution, forecasting, anomaly detection

- **`CONTRIBUTION_ANALYSIS`** over `thesis_outcomes` × regime decomposes Δ excess-return into
  strategy / sector / sub_pattern / regime_state contributors — the regime-conditioned attribution the
  experiment admits it currently *cannot* measure (the router counterfactual was dropped as incoherent).
- **`AI.FORECAST` / `ARIMA_PLUS`** project deployed-TWR, drawdown, and regime indicators forward for
  the briefing's early-warning flags.
- **`ML.DETECT_ANOMALIES`** flags anomalous daily returns, position marks, and reconciliation residuals
  → feeds the §13 cash/SGOV `HARD_STOP` and a "look at this" briefing row.

---

## 10. Cost governance (hard ceiling « $1/month)

- **Byte/analytic core = $0, structurally.** ~6 MB data, ~10 MB/yr growth vs 10 GB storage + 1 TiB/mo
  query free tier; partition+cluster prune to KB; materialized views avoid re-scans. Every non-trivial
  query is **dry-run first** (the MCP exposes `dryRun`).
- **Daily query quota = 32 GB/day** (you set it; §App-A). 32 GB × 31 = ~0.99 TB < the 1 TiB free tier
  even if maxed → still $0, with margin. Hard-stops any runaway scan.
- **The Vertex watch-item.** AI/ML generative + embedding calls are Vertex-billed per token/char and
  the **query quota does not cap them** — so the real guard is a **billing budget alert** (§App-B, set
  to ~$5/mo with 50/90/100% alerts). Before any batch `AI.GENERATE*`, run **`AI.COUNT_TOKENS`** to
  price it; embeddings are batched + incremental (backlog ≈ $0.15, ongoing pennies/yr). Gemini Flash
  ($0.30/$2.50 per 1M tok) is the default model; Pro only on demand.
- **No continuous queries / no slot reservations** (they need real compute commitments) — scheduled
  queries + on-demand only.
- Realistic steady state: **$0/month** for the analytic+forecast+vector core; **cents/month** if AI
  enrichment runs as designed (batched, on-demand). The budget alert makes an overshoot impossible to
  miss.

---

## 11. Core schemas (DDL grounded in the real on-disk formats)

Schemas extend v1's with the *actual* fields found in the data digest. Highlights of the grounding:

- **`events.decision_log`** — `entry_date DATE` (partition), `entry_type` (router-state-change |
  divergence-review | foundation-change-assessment | pre-mortem | termination | redistribution |
  m2m-review | runaway-review | theater-survey | correction | thesis-construction | fill-capture |
  action-conversion), `strategy`, `ticker`, `decision` (GO/NO-GO/ACTIVATE/…), `conviction` (ordinal
  ladder: HIGH | MEDIUM-HIGH | MEDIUM | MEDIUM-LOW | LOW, plus optional `conviction_pct`),
  `sub_pattern` (SP1/SP3/SP4{a-d}/SP5{a,b}/SP6/SP7/SP8/Pattern-N), `theater_check`
  (CONVERGENT|DIVERGENT|MIXED), `title`, `body_md`, `fields JSON`, `refs ARRAY<STRING>`,
  `superseded_by`, `source_session`. Cluster by `strategy, entry_type, ticker`.
- **`events.trade_fills`** — idempotent by IBKR `trade_id`; `order_id`, `contract_id`, `side`,
  `shares`, `price`, `commission`, `realized_pnl`, `fill_ts`, `raw JSON`. Curated dedup view keys on
  `trade_id` (PKs are NOT ENFORCED → idempotency lives in the view or Storage-Write exactly-once).
- **`events.position_events`** — lifecycle OPEN/FILL/UPDATE/CRITERION_FLIP/CLOSE; `position_key`
  (e.g. `B:MDT:2026-06-04`), `cost_basis`, `shares`, `convergence_target`, `time_exit_date`,
  `ltcg_date`, `invalidation_status JSON` (`[{criterion:'(i)', status:'NOT-TRIPPED', as_of:…}]`),
  `status` (OPEN/CLOSED/EXIT-PENDING/ORDER-STAGED), `source_thesis_ref`. → `state.current_positions`.
- **`events.regime_events`** — `scope` (TECHNICAL_SIGNAL | STRATEGY_ACTIVATION), `key` (indicator |
  strategy), `value` (UP/NEUTRAL/DOWN, NORMAL/HIGH, ACTIVATE/DO-NOT-ACTIVATE/HYBRID/PENDING),
  `numeric_value`, `divergence_id` (`div-<S>-<YYYYMM>-<N>`), `theater_check`. → `state.current_regime`.
- **`events.queue_events`** — `queue` (PENDING_ANALYSIS | WATCHLIST | PENDING_REVIEW), `item_key`,
  `analysis_type`/`review_type`, `status` (pending/attacker-complete/complete/superseded/DUE/DROPPED),
  `due_date`, `conservative_default`, `artifact_path`, `payload JSON`. → `state.open_queue`.
- **`events.adversarial_reviews`** — `review_id`, `review_type`, role (attacker|orchestrator),
  `verdict`, `theater_check`, `weaknesses JSON` (W1..Wn tiers / MW1..MWn), `artifact_path`,
  `attacker_text`, `orchestrator_text`. (Paired view feeds §8.)
- **`events.parking_events`** — SGOV Parking Activity rows (date/action/shares/price/commission/
  order_id) for per-strategy cash attribution feeding the §13 tripwire.

(Full GoogleSQL DDL carried over from v1 §4, amended with the fields above, finalized at build time.)

---

## 12. Migration plan (one-time)

1. **Create** datasets + tables (US) + set cost caps (§App-A/B) — *before* loading.
2. **Parse markdown → NDJSON**, handling the real-world messiness the digest found:
   - `Decision_Log*.md`: entry delimiter is a **date-prefixed header at H1/H2/H3** plus `---`; three
     header eras coexist (`## 2026-04-26 …` em-dash unbracketed; `### [2026-06-03] …` bracketed; `#
     [archived] … → file` tombstones to skip). Split on the date-prefix; body → `body_md`; bold-field
     `**Name:** value` lines → typed columns where known, leftover → `fields` JSON.
   - `Portfolio_Ledger.md`: position blocks keyed by H3 suffix status; the **Performance block has two
     field-name dialects** (legacy `Deployed TWR`/`Cumulative active time` vs engine `Deployed unit
     value`/`Deployed days`) — normalize both to the engine schema; SGOV Parking + at-a-glance tables →
     `parking_events` / seed `position_events`.
   - `Regime_State.md`, `Watchlist.md` (pipe tables keyed by ticker), the two YAML-ish queues, and the
     adversarial review pairs: bespoke parsers per the documented formats.
   - For genuinely unstructured fields, **`AI.GENERATE_TABLE`** backfills `fields` (gated by
     `AI.COUNT_TOKENS`).
3. **Load** via `LOAD`/Storage Write API into `events.*`; dedup verification on `trade_id`.
4. **Build** views, materialized views, the refresh procedures, BQML models, embeddings + vector index.
5. **Parallel-run** (write both markdown and BigQuery) for a short validation window; reconcile
   deployed-TWR and positions against the connector ground truth.
6. **Cut over**: routines read the briefing + `INSERT` events; retire the archive split, the
   `.gitattributes` union-merge driver, and the conflict-PR path **for data**; keep markdown + git +
   auto-merge for the **constitution** docs only.
7. **Edit** `Operating_Protocols.md` / `Claude_Task_Plan.md` so D1/D2/D3/W*/M*/Q* describe the
   BigQuery procedures (read briefing / `VECTOR_SEARCH` precedent / `INSERT` events / conviction gate)
   instead of file reads/appends.

---

## 13. Orchestration — what runs where

- **`ops.sp_daily_refresh()` (stored procedure, built via MCP):** ingest new fills, refresh
  `perf.strategy_daily` + `kill_flags` + `state.daily_briefing`, incremental-embed new decision rows,
  run anomaly scan. Invoked **either** by D2 Step 0 (`CALL …`, zero console setup) **or** by a daily
  **scheduled query** (§App-E, zero agent tokens, runs even with no session). Recommended: the
  scheduled query, with the `CALL` as a manual fallback.
- **`ops.sp_weekly_refresh()`:** retrain `conviction_model` + rebuild `calibration_map`, refresh the
  `screen_*` candidate sets, rebuild theater-independence + attribution. Scheduled weekly.
- **Materialized views** refresh themselves for the monthly/quarterly rollups.
- **Snapshots + Parquet export** (audit/DR): daily table snapshots + weekly `EXPORT DATA AS PARQUET`
  to the existing **Hugging Face dataset** (git-versioned, 100 GB free → no GCS bucket to provision).
- **Agent-side (MCP):** read briefing, `VECTOR_SEARCH` precedent, conviction gate, `INSERT` events,
  on-demand analysis. The agent never hand-computes TWR or reconstructs the universe again.

---

## 14. Decisions — resolved + still open

**Resolved (this session):**
- Region → **US multi-region**. Project → **`stock-trading-498512`**.
- Daily query quota → **32 GB/day** (you set it in console).
- AI-feature appetite → **adopt all day-one where value ≥ 0** (this doc), gated by
  `AI.COUNT_TOKENS` + budget alert + batched/on-demand execution.

**Defaults I've chosen (override if you disagree):**
- **#2 Human-readable view:** a **Looker Studio** dashboard over `state.*`/`perf.*` (free) + an
  optional thin daily `State_Snapshot.md` auto-exported to git for eyeballing. *(Default: build the
  dashboard; skip the markdown snapshot unless you want it.)*
- **#4 Audit cadence:** 7-day time travel + **daily** table snapshots + **weekly** Parquet export to
  the HF dataset. *(Tighten/loosen on request.)*
- **#5 Markdown mirror:** **phased** — parallel-run both during validation, then **BigQuery-authoritative
  for data** with the read-only dashboard/snapshot mirror; the constitution stays markdown-in-git.
- **§5 TWR convention → LOCKED** (you delegated the choice): value-weighted daily TWR,
  deployed-days-only chain, with the entry/exit-day + dividend + SGOV-benchmark edge cases now fully
  specified in §5. Still validated against the connector during parallel-run before kill-triggers
  rely on it.
- **External public datasets → selective adopt** (§16): BLS + SEC for regime-conditioning / base-rate
  priors (the calibration cold-start), Trends/patents as P3 features; GDELT deprioritized on cost.

---

## 15. Build sequence

1. **You:** GCP console setup — quota, budget alert, enable APIs, Vertex connection + IAM (§App, the
   paste prompts). *Unblocks the AI layer.*
2. **Me (MCP):** create datasets + tables (US) → migrate markdown → rows → build state/perf views +
   `sp_daily_refresh` → validate TWR vs connector.
3. **Me (MCP):** embeddings + vector index + conviction model + calibration map + attribution +
   forecast + anomaly + theater-independence.
4. **You (console):** schedule `sp_daily_refresh` / `sp_weekly_refresh`; build the Looker dashboard.
5. **Parallel-run → cutover →** edit the protocol docs to the BigQuery procedures.

---

## 16. External public datasets (verified against the live catalog)

`bigquery-public-data` is co-located in US multi-region and **queryable in place** (cross-project
JOINs to our tables, byte-billed under the free tier — no copy needed). The right mental model is a
hard split:

- **Live signals (today's price / news / event / fundamentals): do NOT use public data.** The IBKR
  connector (prices/positions) + web search (news/events) are fresher and more precise. Public sets
  lag (BLS monthly + *revised*, SEC quarterly + filing lag, Census quarterly) or are noisy (GDELT).
- **Historical / calibration / regime-conditioning / cold-start priors: this is where they beat web
  search.** Web search can't hand you a clean, queryable, point-in-time panel JOINed to your trades.
  SQL over multi-year history can. This directly feeds the experiment's stated deliverable
  ("calibration data") and the conviction model's **cold-start** problem (only ~3 closed trades today —
  historical base rates can seed priors until the 30-outcome threshold accrues).

> **Point-in-time / look-ahead caveat (non-negotiable for rigor):** use the *release/filing* timestamp,
> not the period date, and treat revised series (BLS, GDP) as as-released snapshots. Conditioning on
> data that wasn't knowable at decision time silently invalidates calibration. This is also why public
> data is *context and priors only* — never a backtest to overfit to (consistent with the foundation's
> regime-maladaptation / recency warnings). The experiment is a forward test, not a backtest engine.

**Tiered adoption (value ≥ 0, but effort-budgeted):**

| Dataset (verified) | Use here | Tier | Cost note |
|---|---|---|---|
| `bls.cpi_u` / `c_cpi_u` / `employment_hours_earnings` / `unemployment_cps` | Ground-truth macro history for **M1a** inflation/growth axes + **regime-conditioning** of outcomes | P2 | tiny, free; snapshot as-released (revisions) |
| `sec_quarterly_financials` (XBRL `numbers`/`submission`/…) | **D** structural-metric history + fundamentals **base rates** for the conviction cold-start | P2 | moderate, free; key on filing date, XBRL is messy |
| `google_trends` / `google_trends_hourly` | retail-attention proxy → crowding/homogenization (2.8) feature, catalyst attention | P3 | small, free |
| `patents` / `google_patents_research` | structural-moat / innovation-trajectory metric for long-horizon **D** theses | P3 | moderate, free |
| `fda_drug` (`drug_enforcement`, `drug_label`) | pharma **recall/label risk** flag only — **not** a PDUFA calendar, so limited for **C** | P3 | small, free |
| `gdelt-bq.gdeltv2.*` (narrative tone/themes for A/B/E edge) | semantic narrative-divergence signal | **Defer** | **cost-hostile: one 2-col GKG query = ~343 GiB > the 32 GB/day quota → rejected.** Only viable via the `*_partitioned` tables + tight date windows + a scoped daily extract; web+connector already cover live narrative |
| crypto / sports / genomics / geo / civic | — | Skip | irrelevant |

**Mechanics:** small sets (BLS, SEC, Trends) are JOINed in place. Anything large gets a **scheduled,
tightly-scoped extract** into our own small table (never query the giant source per-routine), and
**every public-data query is dry-run first** (GDELT especially — it's the one place a single query can
blow the daily quota). Net: a couple of genuine wins for the calibration/attribution layer (BLS
regime-conditioning, SEC base-rate priors); GDELT parked on cost; live signals stay connector + web.

---

## Sources (verified June 2026)

- BQML model types & pricing: https://docs.cloud.google.com/bigquery/docs/bqml-introduction ,
  https://cloud.google.com/bigquery/pricing
- AI functions & overview: https://docs.cloud.google.com/bigquery/docs/generative-ai-overview ,
  https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-generate
- AI.FORECAST / TimesFM: https://docs.cloud.google.com/bigquery/docs/timesfm-model ,
  https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-forecast
- Vector search / embeddings: https://docs.cloud.google.com/bigquery/docs/vector-search
- Vertex connection + IAM: https://docs.cloud.google.com/bigquery/docs/generate-text-tutorial
- Storage Write API / time travel / snapshots / custom quotas / Vertex pricing — as v1 §Sources.

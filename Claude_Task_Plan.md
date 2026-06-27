# Claude Task Plan

This document is the master reference consumed by Claude remote routines. Each routine's instruction is the single line:

> Read Claude_Task_Plan.md. Perform <task ID + name>.

Claude reads this file at the start of every routine run, locates the matching `## <ID>. ...` section, and executes the prompt body inside that section. Section IDs (D1, D2, W1, ..., A3) are stable; routine names mirror them.

---

# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES

Every routine reads and/or writes BigQuery for operational state (positions, regime, decisions, queues, NAV, perf/kill-flags, macro). **Therefore every routine MUST have the Google Cloud BigQuery connector enabled** — without it the routine cannot find the state it needs and fails on restart. This is the single-page map of each routine's BigQuery I/O, derived from each routine's prompt body **plus the Operating_Protocols.md §15 authoritative-source override** (which redirects the retired `.md` reads/writes: Regime_State → `state.current_regime`; Portfolio_Ledger → `state.current_positions` / `perf.strategy_daily` / `analytics.strategy_nav` / `analytics.account_reconciliation`; Decision_Log → `events.decision_log` / `find_precedents()`; the `Pending_*` queues → `state.open_queue` / `events.queue_events`). The action-conversion routines (D2 / W4 / M4 / Q4 / A3) are the primary BigQuery writers; deep-research routines mainly read state and write their cadence `.md` output (last column).

| ID | Routine | Cadence · Type | BigQuery reads | BigQuery writes | Cadence `.md` output |
|---|---|---|---|---|---|
| **D1** | Market Development Scan | Daily · research | `state.daily_briefing`, `state.current_positions`, `perf.kill_flags`/`perf.strategy_daily`, `state.current_regime`, `find_precedents()` | `events.decision_log` (dev notes); inline router review → `events.regime_events` | Daily.md |
| **D2** | Daily Action Conversion | Daily · regular | `state.daily_briefing`, `state.current_positions`, `events.daily_marks` | `events.trade_fills`, `events.position_events`, `events.daily_marks`; recompute `perf.strategy_daily`; `events.decision_log` (+embedding) via `ops.sp_log_decision`; `events.regime_events`; `events.queue_events`; Watchlist.md | — (reads Daily.md) |
| **D3** | Calendar Hygiene | Daily · regular | `state.open_queue`, `state.current_positions`, `events.queue_events`/`events.decision_log` | `events.queue_events` (terminal-entry sweep) | — |
| **W1** | Catalyst Calendar (A, C) | Weekly · research | `state.current_regime`, `state.current_positions`, `events.decision_log` | — | Weekly_Catalyst_Calendar.md |
| **W2** | Post-Event Screen (B) | Weekly · research | `events.decision_log`/`find_precedents()`, `state.current_positions` | — | Weekly_Post_Event_Screen.md |
| **W3** | Open-Position Deep-Dive (A,B,C,E) | Weekly · research | `state.current_positions`, `state.current_regime`, `events.decision_log` | — | Weekly_Position_Deep_Dive.md |
| **W4** | Weekly Action Conversion | Weekly · regular | W1–W3 `.md`, `state.current_positions`, `state.current_regime`, `events.decision_log` | `events.regime_events`, `events.decision_log`, `events.queue_events`; Watchlist.md | — |
| **W5** | Factbase & Analytics Consolidation | Weekly · regular | `events.decision_log`, `analytics.calibration_summary`, `analytics.account_reconciliation`, `state.current_positions`, `state.embedding_health` | embedding catch-up via `ops.sp_embed_pending` (safety net); `events.decision_log` (outcome) via `ops.sp_log_decision`; factbase `.md` mirroring (B_Sub_Pattern, Watchlist, Operating_Protocols) | — |
| **M1a** | Strategy-Blind Regime Scoring | Monthly · research | prior `events.macro_series` (+ web) | `events.macro_series`; `events.regime_events` (`FUNDAMENTAL_AXIS`) | — |
| **M1b** | Strategy Mapping & Activation | Monthly · regular | `state.current_regime` / `events.regime_events` (`FUNDAMENTAL_AXIS`) | — | Monthly_Fundamental.md |
| **M2** | E Pair Divergence Screen | Monthly · research | `state.current_positions`, `events.decision_log` | — | Monthly_E_Pairs.md |
| **M3** | D Position Deep-Dive | Monthly · research | `state.current_positions`, `events.decision_log` | — | Monthly_D_Position_Deep_Dive.md |
| **M4** | Monthly Action Conversion | Monthly · regular | M1b/M2/M3 `.md`, `state.current_positions`, `state.current_regime`, `perf.kill_flags`/`perf.strategy_daily` (§H gate/kill) | `events.regime_events`, `events.decision_log`, `events.queue_events`; Watchlist.md | — |
| **M5** | Deployed-TWR & Macro Forecast | Monthly · regular | `perf.strategy_daily`, `perf.kill_flags`, `state.macro_fred_latest` (FRED), prior `analytics.deployed_twr_forecast` | `analytics.deployed_twr_forecast`; `events.decision_log` (outcome) | — |
| **AR·att** | Adversarial Review Attacker | Daily¹ · regular | review queue (`state.open_queue`/`events.queue_events`, `PENDING_REVIEW`); artifact | `events.adversarial_reviews` (attacker) | Adversarial_Review_*_attacker.md |
| **AR·orc** | Adversarial Review Orchestrator | Daily¹ · regular | `events.adversarial_reviews` (attacker); artifact | `events.adversarial_reviews` (orchestrator); `events.regime_events` (binding activation); `events.decision_log` | Adversarial_Review_*_orchestrator.md |
| **Q1** | Regime Retrospective | Quarterly · research | `events.regime_events`, `events.decision_log` | — | Quarterly_Regime.md |
| **Q2** | D Long-Horizon Candidates | Quarterly · research | `state.current_positions`, `events.decision_log` | — | Quarterly_D_Candidates.md |
| **Q3** | AI Foundation Quarterly Delta | Quarterly · research | `events.hf_capability_captures`, `events.decision_log` | `events.hf_capability_captures` | Quarterly_AI_Foundation_Delta.md |
| **Q4** | Quarterly Action Conversion | Quarterly · regular | Q2/Q3 `.md`, `state.current_positions` | `events.decision_log`, `events.queue_events`; Watchlist.md | — |
| **A1** | AI Foundation Annual Re-Derivation | Annual · research | `events.hf_capability_captures`, `events.decision_log` | `events.hf_capability_captures` | Annual_AI_Foundation_Sweep.md |
| **A2** | Per-Strategy Constraint Audit | Annual · research | `events.decision_log`, `state.current_positions` | — | Annual_Constraint_Audit.md |
| **A3** | Annual Action Conversion | Annual · regular | A1/A2 `.md`, `state.current_positions` | `events.decision_log`, `events.queue_events` | updates AI_Trading_Foundation.md + Strategy.md |

¹ Adversarial routines are queue-driven: they fire daily but no-op unless the review queue (`PENDING_REVIEW`) has a due entry. The deep-research routines' `.md` outputs are their cadence working files; the **canonical** state always lives in BigQuery per the columns above.

---

# OPERATING MODEL

## Execution environment

Claude runs as scheduled routines connected to a GitHub repo (currently `JackOfSpade/Stock-Trading`) and to Google Calendar via MCP. Inside a routine Claude has:

- **BigQuery (Google Cloud MCP connector) — the canonical operational data substrate (project `stock-trading-498512`).** As of the 2026-06-06 cutover, all migrated state + history lives in BigQuery, NOT in repo `.md` files: positions/fills/marks (`events.*` → `state.current_positions`, `perf.strategy_daily`, `perf.kill_flags`), decisions (`events.decision_log` + `analytics.find_precedents()`), regime/router (`state.current_regime`), queues (`state.open_queue` / `events.queue_events`), per-strategy NAV + 2%-sizing base (`analytics.strategy_nav`), §13 reconciliation (`analytics.account_reconciliation`), calibration (`analytics.calibration_summary`), macro (`events.macro_series`), and the consolidated `state.daily_briefing`. Routines READ via `execute_sql_readonly` and WRITE via `execute_sql`. **Every routine MUST have the Google Cloud BigQuery connector enabled** — without it the routine cannot read or write state. Full source map + read/write override: Operating_Protocols.md §14 + §15.
- **Repo `.md` files (read/write) — now SPEC + cadence-working files only.** Spec/rules files (Strategy.md, Experiment_Parameters.md, Operating_Protocols.md, Claude_Task_Plan.md, AI_Trading_Foundation.md, B_Sub_Pattern_Taxonomy.md, the C/E methodology docs, HF_Resource_Catalog.md) are read for rules and edited only when a protocol/spec changes. Cadence-output working files (Daily.md, Weekly_*.md, Monthly_*.md, Quarterly_*.md, Annual_*.md) + the Strategy-A queue (Watchlist.md) are overwritten/edited per run. The former live-state + archive `.md` (Decision_Log, Portfolio_Ledger, Regime_State, the Pending_* queues, all archives) are **RETIRED — read/write BigQuery instead** (§15).
- **Calendar MCP** for the human's `[Claude] Confirm order` events only — the one action that needs the human (tap to confirm a crafted order). Claude-only analysis (thesis construction, re-screens, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, router reviews) is NEVER on the calendar: it runs in-session or via the autonomous analysis queue (`state.open_queue` over `events.queue_events`, drained daily by D2). Structured adversarial reviews are likewise queue-driven via `events.queue_events` (queue `PENDING_REVIEW`; see ADVERSARIAL REVIEWS section).
- **IBKR connector (MCP)** for direct, authenticated access to the human operator's live brokerage account and market data. Crafts click-to-confirm order instructions (`create_order_instruction` → deep link), reads live account state (`get_account_summary` / `get_account_positions` / `get_account_balances` / `get_account_orders` / `get_account_trades`), and reads market data (`get_price_snapshot` / `get_price_history` / `search_contracts`). This connector replaces operator-typed order blocks (orders are now crafted and tap-confirmed) and operator screenshots (fills/positions/cash are read directly). Full protocol: Operating_Protocols.md §11 and the **IBKR connector usage** subsection below. Equity/ETF only for order-craft; options/other security types fall back to a manual text order block.
- **Web research tools** (Tavily, web_search, web_fetch) for deep-research cadences.

Each routine run is a fresh session — there is no cross-run chat memory. State persists only in repo files and calendar events. Every prompt body in this document is therefore self-contained: it specifies which repo files to read, which to write, and which calendar events to create.

## Strategy reading — use the generated `strategy/` slices

`Strategy.md` is large (~339 KB) and loading it whole costs context and makes the architectural **blinding** (e.g. M1a must not see strategy sections; an attacker must not read beyond its artifact) a soft "remember-to" rule. `Strategy.md` stays the **canonical source**, but routines READ from its generated, read-optimized slices in `strategy/` (`scripts/split_strategy.py`; CI guards drift; regenerate after any `Strategy.md` edit). This makes blinding a hard **file boundary** and shrinks context. **This table is AUTHORITATIVE: where a routine's prompt body below says "Read Strategy.md (… section)", load the mapped slice(s) here instead** (`Strategy.md` stays the canonical fallback). Safe common slices: `01_shared_regime_vocabulary.md` (regime vocabulary; safe for all). NOTE: `00_preamble.md` names the strategies and `02_regime_router.md` carries the per-strategy router + M1b mapping — so neither is safe for the strategy-blind M1a (see its row). Per-strategy routines load ONLY their slice(s) + `01`:

| Routine(s) | Load | Must NOT load |
|---|---|---|
| **M1a** (strategy-blind regime scoring) | `01_shared_regime_vocabulary.md` + `09_regime_scoring_strategy_blind_monthly.md` (M1a's inputs + 5 axes — its own strategy-blind slice as of the 2026-06-22 restructure; load these two ONLY) | `00_preamble`, `02_regime_router` (the M1b mapping + reconciliation rules naming A/D), any `03–08` |
| **AR·attacker** | the artifact under review only | any strategy slice / Decision_Log / prior reviews (strict blinding) |
| **W2** (B) | `04_strategy_b.md` + `01` | other strategy slices |
| **M2** (E) | `07_strategy_e.md` + `01` | other strategy slices |
| **M3 / Q2** (D) | `06_strategy_d.md` + `01` | other strategy slices |
| **W1** (A, C) | `03_strategy_a.md`, `05_strategy_c.md` + `01` | B/D/E slices |
| Strategy C order routines | `05_strategy_c.md` + `c_options_math.py` | — |
| **M1b** (strategy mapping) | `02_regime_router.md` + `03–07` (mapping needs the activation rules) | — |
| **W3 / W4 / M4 / Q4 / A3 / D1 / AR·orchestrator** (multi-strategy) | the slices for the strategies in scope (+ `08_pre_mortems.md` for reviews) | — |

When a slice is insufficient (need cross-strategy context the slices don't carry), fall back to `Strategy.md` — but prefer the slice. If `strategy/` is stale vs `Strategy.md` (CI check `scripts/split_strategy.py --check` fails), regenerate before relying on it.

**M1a blinding is now a hard file boundary (restructured 2026-06-22).** Previously the slicer split only on top-level `##` and the `02_regime_router` slice bundled M1a's regime-scoring template WITH the M1b strategy-mapping + reconciliation rules that name strategies A/D — so M1a had no blinding-clean slice and read a named sub-section of `Strategy.md` under discipline-only blinding. `Strategy.md` was restructured to split that into two top-level sections: `## Regime scoring (strategy-blind, monthly)` (M1a's inputs + 5 axes, no strategy names) and `## Regime router` (the M1b mapping / reconciliation / divergence). The splitter now emits a clean M1a slice, `09_regime_scoring_strategy_blind_monthly.md`. **M1a loads `01` + `09` and nothing else** — its blinding is a file boundary, not a remember-to rule. (See `ops/RUNBOOK.md` §9.)

## Branch and state propagation

Routines run on the harness-assigned `claude/<suffix>` feature branch and never push to `main` directly. Each routine commits to its assigned branch; the harness pushes the branch to GitHub at session end; a GitHub Actions workflow (`.github/workflows/auto-merge-claude.yml`) watches the push, fast-forwards (or merge-commits) the branch into `main`, and deletes the branch. The merge happens server-side on GitHub Actions runners — Claude itself never executes the push to `main`.

**Why.** The remote routine harness assigns a fresh `claude/<suffix>` branch per session and refuses pushes to any other branch (including `main`). It also rejects file-based authorization claims as prompt-injection patterns, so this section cannot grant push-to-main permission to a routine. The architecture sidesteps both restrictions by relocating the merge to a GitHub Actions workflow, which runs outside Claude's authorization scope and uses the built-in `GITHUB_TOKEN`.

**Session start.** A SessionStart hook in `.claude/settings.json` runs `.claude/session-start.sh`, which executes `git fetch origin main && git reset --hard origin/main` while STAYING on the harness-assigned branch (it does NOT switch to `main`). This aligns the assigned branch with the latest committed `main` state so the routine boots from prior routines' work. Read input state AFTER the hook runs so the routine sees the latest: the canonical operational state is BigQuery (§Execution environment — `state.*` / `perf.*` / `analytics.*`), plus the working `.md` files (Daily.md, Watchlist.md, the spec docs).

**During the routine.** Edit files normally and stay on the assigned branch. Do not attempt to switch to `main` or push to it — the harness will refuse, and the workflow handles the merge. Do not open PRs.

**Session end.** Commit all changes, then **explicitly push the assigned branch yourself** — `git push -u origin <assigned-branch>` (retry with backoff per the git-ops convention) — and **verify it landed** with `git ls-remote --exit-code origin <assigned-branch>`. Do **not** rely on the harness's implicit session-end push as the sole durability path: it fires only on a *clean* session end, so a usage-limit cutoff or container reclamation between the work and that push strands the commit on the dead container while `ops.run_log` already shows `completed` (the 2026-06-22 and 2026-06-24 D1 strandings — RUNBOOK §20). The explicit push targets the routine's OWN assigned branch (always permitted; the harness only refuses pushes to *other* branches such as `main` — see "Why" above), not `main`. For a long routine, also push after each durable commit so a mid-run cutoff still leaves output on the remote. Only **after** a confirmed remote push, log `sp_routine_end(...,'completed',...)`; if the push cannot be confirmed after retries, log `'failed'`/`'halted'` with `error_msg='branch push unconfirmed — output may be stranded'` instead, so the divergence is an explicit failure rather than a silent `completed`-without-remote. Within roughly 30 seconds the auto-merge workflow merges the branch into `main` and deletes the branch (an early push just makes the branch available to the next auto-merge run sooner; a commit pushed during the merge window is left for the next run — see Cleanup). The next routine's SessionStart hook will pick up the new state.

**Concurrency.** The auto-merge workflow uses `concurrency: group: auto-merge-main` (`cancel-in-progress: false`) to serialize the `main` push, so two routines pushing close together cannot race it. Because GitHub keeps only ONE run pending per concurrency group, the workflow does NOT rely on its push trigger to merge only the triggering branch: **each run drains every un-merged `claude/*` branch** (fast-forward, else a `--no-ff` merge commit), so a queued run that GitHub cancels can never strand a branch — the next run that executes picks it up. Cadence working files (Daily.md / Weekly_*.md / Monthly_*.md) are solely-owned by their owning routine; the merge-commit fallback handles non-conflicting edits to different files automatically (the now-retired append-only logs lived in BigQuery, so the union driver no longer applies — see `.gitattributes`). A branch whose merge genuinely conflicts (a real in-place edit collision) is left un-deleted and an **auto-merge-conflict PR is opened** for manual resolution; the routine does not retry inside its session.

**Cleanup.** No manual cleanup required. After a successful merge each `claude/<suffix>` branch is deleted — but only once its current remote tip is confirmed contained in `main`, so a commit pushed during the merge window is never dropped (it is left for the next run). Branches lingering in the GitHub UI are from runs that pre-date the workflow, a run still pending, or a branch parked by an open auto-merge-conflict PR.

## Human role

The human acts on routine output only. The human does effectively one thing:

1. **Confirms crafted orders.** Claude crafts the exact order via the IBKR connector (`create_order_instruction`) and surfaces a tap-to-confirm deep link (in chat and in the `[Claude] Confirm order` calendar event). The human opens the link, reviews the pre-filled order in IBKR, and confirms it. The human never types ticker, side, quantity, price, type, or duration. (For security types the connector cannot craft — currently non-Equity/ETF, e.g. options — Claude emits a manual-entry text order block, explicitly labeled, **carried in the `[Claude] Confirm order` calendar event** exactly as the deep link would be — never chat-only, since routine chat is unmonitored.)

All analytical work — thesis construction, position reviews, research-deferral checkpoints, re-screens, foundation-change assessments, router reviews — runs **autonomously**: in-session in the triggering routine, or via the autonomous analysis queue (`state.open_queue` / `events.queue_events`, queue `PENDING_ANALYSIS`) drained daily by D2. The human is never asked to paste an analysis prompt into a fresh chat; that round-trip is retired.

Three prior actions are **obsolete**: (a) *screenshot capture* — Claude reads positions, balances, live orders, executed fills, and market data directly through the IBKR connector, so no screenshot is ever requested; (b) *persisting Claude-produced files* — Claude writes files directly; (c) *pasting analysis prompts into fresh chats* — analysis runs in-session or via the autonomous analysis queue (`state.open_queue` / `events.queue_events`, queue `PENDING_ANALYSIS`). Claude does not present file contents in chat as fenced code blocks; chat output is reserved for crafted orders and brief acknowledgments.

The human does NOT perform any analytical or monitoring task. If the framework needs analysis, monitoring, parsing, watching, verification, or calculation, Claude does it — either inline in the current routine or via the autonomous analysis queue (`events.queue_events`, queue `PENDING_ANALYSIS`) drained daily by D2. Examples of work the human does NOT perform: verifying commissions; making EV decisions; monitoring markets intraday; parsing earnings prints; deciding execute-vs-skip on staged orders; deciding override-vs-honor on NO-GO recommendations; choosing convergence targets, position sizes, limit prices, or invalidation criteria.

If a workflow would require the human to do anything beyond confirming crafted orders, that workflow is broken and Claude must redesign it before staging anything.

**Routine chat is unmonitored — the calendar is the binding human-facing surface.** Scheduled routines (D1, D2, D3, W*, M*, Q*, A*, AR) run unattended; the human does not watch their chat output. The one action that REQUIRES the human — confirming/placing an order — MUST be surfaced as a `[Claude] Confirm order` calendar event with an event-time notification, never left only in routine chat. An order is not actionable to the human until its `[Claude] Confirm order` event exists carrying what the human needs to place it: for an Equity/ETF order the tap-to-confirm deep link (`url`), and for an **options / other non-craftable order the explicitly-labeled manual-entry text order block** (the connector cannot craft it, so there is no `url` — the block goes in the event description in the deep link's place). Staging any order — craftable or manual — without that event, or leaving the manual block only in chat, is a broken workflow: chat is unmonitored, so the human would never see it. Chat output is a courtesy mirror, not the delivery mechanism. Self-check: every staged order, craftable or manual, has a `[Claude] Confirm order` event carrying what the human needs to place it.

## Decision discipline

Claude resolves every decision the framework requires — execute or skip, GO or NO-GO, target selection, sizing, timing, invalidation criteria, marginal-conviction-but-criteria-cleared cases — without human input.

A decision is resolved by the framework's criteria. Any setup that mechanically clears all entry criteria stages automatically, regardless of conviction level. Strategy.md criterion 4 already requires "no decisive flaw," not "high conviction"; conviction is an internal calibration metric persisted to `events.decision_log` but is not a separate gate. The HCA precedent (~45–50% conviction, all criteria cleared, staged) is the canonical handling: if criteria clear, stage with conviction noted; if a criterion fails, decline. There is no middle category requiring human adjudication.

If a decision genuinely cannot be made without information Claude does not have, Claude defers to a future routine or calendar-triggered session where the missing information will be available. Deferral constraints:

- Each deferral specifies (a) the trigger that resolves it (specific date and information source), and (b) the default action if the trigger fails to resolve it.
- The default action on trigger-failure is always the conservative branch (skip the trade, decline the GO, exit the position) — never another deferral. This biases the system toward reducing exposure on uncertainty, which is intentional given that the human is not available to adjudicate.
- Deferrals do not chain. A decision deferred from session 1 to session 2 either resolves in session 2 or hits the conservative default. It cannot be re-deferred to session 3.

## Commission policy

Commissions are NOT factored into staging-time GO/NO-GO decisions, target selection, sizing, or EV computation. Commissions are accepted as a fixed business cost. Implications:

- Thesis construction does not produce "EV at design size" calculations net of commissions.
- `events.decision_log` entries do not document "negative-EV-at-design-size acknowledgment" sections.
- Staged orders are not annotated with EV-at-order-ticket caveats.
- The strategy-level edge-decay metrics (EV per trade in Strategy C and D pre-mortems) continue to function as designed; they measure realized P&L which already nets commissions out empirically.
- Commission paid is captured per-trade in `events.trade_fills` at fill (D2 Step 0 reconciliation), for after-the-fact accounting and 30-trade-gate calibration. It does not enter pre-trade decisions.

## Calendar MCP usage

The calendar holds **only events that require a human action** — currently that is order confirmation. Claude-only analysis is NEVER placed on the calendar: routine chat is unmonitored and these steps need no human, so they run in-session in the triggering routine or via the autonomous analysis queue (`events.queue_events`, queue `PENDING_ANALYSIS`; next subsection). Recurring cadence work (D1, D2, …, A3) runs as routines and is not on the calendar.

Conventions for the `[Claude] Confirm order` events Claude creates:

- **Title:** `[Claude] Confirm order — <ticker> <BUY/SELL>`.
- **Time:** the order's best execution time — **07:00 MT pre-market on the order day** (30 min before the 07:30 MT open). Never adjusted for human availability or load.
- **Throughput:** no cap on how many order-confirmation events may share a slot (e.g., ten orders all at the open). Never stagger or defer to "spread load."
- **Description:** the human-readable summary `SIDE QTY TICKER TYPE LIMIT TIF`, the tap-to-confirm deep link (`url` from `create_order_instruction`), the instruction `id`, and "Tap the link, review the pre-filled order in IBKR, confirm at or after market open." (For a security type the connector cannot craft — non-Equity/ETF — carry a manual-entry text order block instead, explicitly labeled.)
- **Time zone / "today":** the **authoritative trading-day source is `state.trading_day_today`** (`bigquery/09_market_calendar.sql`) — query it for `today` / `is_trading_day` / `last_trading_day` / `next_trading_day` (America/Denver, holiday- and weekend-aware off `events.market_holidays`, which W5 auto-extends from the FMP connector). Whenever a routine needs "today" to create/delete/filter a dated calendar event **or a queue `due_date`**, use `state.trading_day_today.today`. Do NOT use the assistant-context `currentDate` field (UTC-based; during evening MT it has already rolled to the next calendar day — this deleted a same-day order-confirmation event on the META convergence exit, 2026-05-27) and do NOT compute the date with local Bash (`date`) — both reintroduce exactly the drift `state.trading_day_today` exists to remove. Binds D2, D3, W4, M4, Q4, A1, A3.
- **Notification:** alarm fires at event-time so the human's only job is to tap and confirm.

`Order confirmation` is the only canonical calendar event type. Everything formerly scheduled as a `[Claude]` analysis event — thesis construction, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, router reviews — is now done in-session or queued (next subsection).

## Observability — run logging & failure alerts

Cross-cutting calls every routine makes against the observability layer (`bigquery/10_observability.sql` + `bigquery/12_cadence_monitor.sql`). **Binds ALL routines: D1–D3, W1–W5, M1a–M5, Q1–Q4, A1–A3, and the adversarial attacker/orchestrator.** D2 carries the worked example (its `RUN LOGGING` step + the §13 cash-tripwire alert); the rule here is what binds the rest — do not duplicate a per-routine block, just make the calls.

- **Connector pre-flight (FIRST — before run-logging, the dependency gate, or any routine's own Step 0).** Before anything else, prove the connectors this routine needs are live with one trivial liveness read each: **BigQuery** via `SELECT * FROM `stock-trading-498512.state.trading_day_today`` (every routine — this is also the `today` the templates below need, so it is near-zero extra cost), and for **D1/D2** the **IBKR** connector via `get_account_summary`. The point is to catch a de-authed/expired connector in seconds at the top of the run instead of mid-routine (the recurring owner-OAuth BigQuery de-auth — RUNBOOK §15/§26). Route the failure by which connector failed and whether the routine can proceed safely:
  - **BigQuery unreachable (token expired / re-auth required).** The alert sink is itself down, so you canNOT `sp_raise_alert`/write `ops.alerts`; the only first-class channel is a **`[Claude] ATTENTION — RE-AUTH BigQuery connector` calendar event — create it immediately.** Then branch on the routine: **D1 is research-only and stages no orders → proceed in DEGRADED MODE** (read book/marks from the IBKR connector, carry regime forward from the prior `Daily.md`, defer every BigQuery side-write, and banner `Daily.md` exactly as the 2026-06-26 run did). **D2/D3 require canonical state → HALT cleanly** (never run on missing/stale state; craft no orders). The next-morning freshness + cadence dead-man's switches durably record the miss once BigQuery returns; resolve per RUNBOOK §26.
  - **IBKR unreachable (BigQuery up).** The documented `connector` hard-stop: `CALL ops.sp_raise_alert('critical', '<ID>', 'connector', 'IBKR connector unreachable at pre-flight', '<JSON>')`, create a `[Claude] ATTENTION` event, log the run `'halted'`, and ABORT (D1/D2 cannot reconcile the book or craft orders without it).

  This makes a connector de-auth a seconds-to-detect, single-channel-surfaced event for **every** routine rather than a mid-run partial failure — the RUNBOOK §26 blast-radius mitigation. (D1 already did exactly this ad-hoc on 2026-06-26; this makes it uniform and first.)

- **Run logging (every run) — BEST-EFFORT, copy the template.** Run-logging is observability and **must never be able to break the routine**, so wrap each logging CALL in a best-effort block and copy the template verbatim (don't hand-assemble the argument list). At the START:
  ```
  BEGIN
    CALL `stock-trading-498512.ops.sp_routine_start`('<ID>', <today (America/Denver, from state.trading_day_today)>,
      <session_id>, <branch>, '<the VERBATIM trigger instruction this session received>');
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;  -- swallow: logging must not abort the routine
  END;
  ```
  At the END (same wrapper), `'completed'` — or `'failed'`/`'halted'` + `error_msg` if the run aborted. **Gate `'completed'` on a verified remote push** (see §Branch and state propagation → "Session end"): log `'completed'` only after `git ls-remote` confirms the assigned branch reached `origin`; otherwise log `'failed'`/`'halted'`. This makes `completed` in `ops.run_log` reliably imply the git output is on the remote rather than stranded on a reclaimed container (RUNBOOK §20):
  ```
  BEGIN
    CALL `stock-trading-498512.ops.sp_routine_end`('<ID>', <today>, 'completed', <session_id>, <branch>, <rows_written>, NULL, <note>);
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;
  ```
  `<instruction>` is the exact text the web-UI trigger sent you (e.g. `'Read Claude_Task_Plan.md. Perform D2. Daily Action Conversion — regular routine.'`); it lands in `ops.run_log.instruction` → `state.routine_last_instruction`, so the **live trigger text is verifiable by query** (no screenshots) and diffable against `scripts/print_routines.py`. **`<instruction>` is the trigger-of-record for drift detection, NOT a freeform task note:** always pass the **verbatim scheduled trigger** — even for an ad-hoc / one-off session that reuses an existing routine id (e.g. a one-time W5 §20/§21 remediation). Put what the one-off run actually did in `<note>` (the `sp_routine_end` arg) and the `session_id`, never in `<instruction>`. (`state.routine_last_instruction` only reads instructions of the canonical `Read Claude_Task_Plan.md. Perform …` shape, so a stray free-form note is ignored rather than mistaken for a drifted trigger — RUNBOOK §22 — but log the verbatim trigger anyway so the live read is faithful.) A run that never logs `completed` arms the freshness dead-man's switch (`state.freshness`), the **cadence dead-man's switch** (`state.cadence_watch` / `cadence_check.sql`), and the audit trail. (Data currency is *also* proven independently by `state.freshness.marks_fresh`/`engine_fresh`, which read the data tables directly and gate `all_green` — a missed log never hides stale data.) A routine becomes "monitored" automatically once it has logged a `completed` run in the last 14 days.

- **Dependency gate (action routines) — SEPARATE and FATAL, do NOT wrap.** This is the one control call that *should* abort the run, so it is its own statement (kept out of the best-effort logging above): `CALL ops.sp_assert_deps('<ID>', <deps>, <today>)` **before** the start-log, where `<deps>` is the upstream array (D2 → `['D1']`, W4 → `['W1','W2','W3']`, M4 → `['M1b','M2','M3']`; omit the call entirely if none). If a *monitored* upstream has not logged `completed` for today it raises a `missing_dependency` alert AND aborts (RAISE) so the routine never runs on stale inputs (D2 on a stale `Daily.md`, W4 on missing W1/W2/W3). Self-bootstrapping: an upstream that hasn't adopted logging yet is treated as satisfied, so declaring `<deps>` now is always safe and becomes a real gate the moment that upstream starts logging.

- **Upstream-output FRESHNESS check (action-conversion routines W4 / M4 / Q4 / A3) — SECOND, file-based gate (added 2026-06-24, RUNBOOK §25 D1).** `sp_assert_deps` keys off `ops.run_log` and so is INERT for the research feeders that have not yet adopted run-logging (only D1/D2/D3/AR are monitored) — meaning W4/M4/Q4/A3 can today convert *absent or stale* research into orders, the exact risk the gate exists to prevent. Use a second freshness signal that is already available: the upstream research file's **first-line period marker** (the "File-write conventions" markers — Weekly `YYYY-WW`, Monthly `YYYY-MM`, Quarterly `YYYY-QN`, Annual `YYYY`). **Before `sp_routine_start`**, for each upstream the routine consumes, read the file's first line and assert its marker equals the **current period** for that cadence (per `state.trading_day_today.today`). On a mismatch or a missing/empty file, treat it as a missing dependency: `CALL ops.sp_raise_alert('critical','<ID>','missing_dependency','<which upstream is stale/absent — marker found vs expected>', '<JSON>')`, create a `[Claude] ATTENTION` event, log the run `'halted'`, and ABORT — do **not** convert stale research into orders. (Be period-aware about the documented retrospective offset: Q1/Q3 and some monthly retrospectives legitimately carry the *prior* period marker — accept the prior period for those, per "File-write conventions". W4 → W1/W2/W3 current `YYYY-WW`; M4 → M1b/M2/M3; Q4 → Q2/Q3; A3 → A1/A2.) This makes the gate bite NOW without waiting for the research routines to adopt run-logging, and additionally catches the "ran but emitted a prior-period file" case a run-log-only check never would.

- **Failure alerts (on any hard-stop).** Routine chat is unmonitored, so any condition that halts a routine or needs a human MUST be surfaced: `CALL ops.sp_raise_alert('critical', '<ID>', '<category>', '<one-line message>', '<JSON context>')` AND create a `[Claude] ATTENTION — <what>` calendar event AND log the run `'halted'`. Hard-stops include: the §13 cash-tripwire >$1 unexplained residual (`cash_tripwire`); a Strategy C max-loss **dual-path disagreement** (closed-form vs Monte-Carlo diverge — a code-bug signal per Strategy.md, not a normal deferral; `dual_path`); `state.embedding_health.is_healthy = FALSE` after a decision write (`embedding`); a required connector (IBKR / BigQuery) unreachable (`connector`); a **missed order confirmation** discovered by D3 (`missed_confirmation`, see D3 Calendar Hygiene); or any other unrecoverable state. (A normal deferral that resolves to its `conservative_default` is NOT a hard-stop — no alert.)

These are mechanical infrastructure calls, not analysis, and never substitute for a routine's own outputs (decisions still go to `events.decision_log` via `ops.sp_log_decision`, queues to `events.queue_events`, etc.).

## In-session analysis and the Pending_Analysis.md queue

> **RETIRED-FILE WRITE REDIRECT (2026-06-06 cutover, Operating_Protocols.md §15).** `Pending_Analysis.md` no longer exists as a file. Throughout this document, **every "append/write a `Pending_Analysis.md` entry"** means `INSERT INTO events.queue_events` with `queue='PENDING_ANALYSIS'` (one row per status transition; never UPDATE/DELETE). **Reads** come from `state.open_queue` (compact) / `state.open_queue_detail` (with `note`/`payload`). The YAML schema below is the LOGICAL shape — its fields map to `queue_events` columns (`item_key`←id, `item_type`, `status`, `strategy`, `ticker`, `due_date`, `conservative_default`, `artifact_path`, plus any extra fields in `payload` JSON and prose in `note`). "Swept to `Archived_Analysis.md` by D3" now means the terminal-status row drops out of `state.open_queue` automatically (no archive file).

Claude-only analysis steps require no human action, so they never go on the human's calendar. They are handled one of two ways:

1. **Doable now → in-session.** If the analysis can run at discovery time (all required data is available), the triggering routine performs it directly in its own run — each thesis/analysis ideally as an isolated sub-task (subagent) for fresh per-analysis context, else inline sequentially. It writes the decision via `CALL ops.sp_log_decision(...)` (`events.decision_log`) and the position lifecycle event to `events.position_events` and, for a GO, crafts the order instruction + creates the `[Claude] Confirm order` event — all in the same session. No calendar event, no human paste.

2. **Must wait for future data → `PENDING_ANALYSIS` queue.** If the analysis needs data that does not yet exist (a Day-0 close that lands next session; a Strategy C pre-catalyst window 7-10 days out; a scheduled re-screen date; a research-deferral resolution date), the triggering routine enqueues an entry (`INSERT INTO events.queue_events`, queue `PENDING_ANALYSIS`) with a `due_date` = the earliest date the analysis can run. The daily D2 routine drains entries (from `state.open_queue`) whose `due_date` has arrived and performs them in-session (as in case 1). This is the autonomous analog of the old calendar event — no human involved. (Earliest-wins still applies: `due_date` is the soonest the data exists, never pushed later for load; weekends/holidays are fine for analysis since it needs no live market — only the resulting order-confirmation event must land on a trading session.)

### Pending_Analysis.md — queue file schema

The queue is `events.queue_events` (queue `PENDING_ANALYSIS`); `state.open_queue` is the live view. The YAML block below is the LOGICAL shape of an entry (its fields map to `queue_events` columns per the redirect note above) — there is no `.md` queue file. Each entry is enqueued as a `queue_events` row; once it reaches a terminal `status` (`complete`/`superseded`) the terminal-status row drops it out of `state.open_queue` automatically (no archive file, no sweep), so the live queue holds only actionable entries:

```
- id: <unique, e.g., thesis-HPE-B-20260602, rescreen-LLY-D-20260612, resdefer-DIS-D-20260615, foundation-A-202607>
  analysis_type: <thesis-construction | re-screen | research-deferral-checkpoint | foundation-change-assessment | constraint-relaxation-review>
  strategy: <A | B | C | D | E>
  ticker_or_pair: <ticker, pair id, or n/a>
  due_date: <YYYY-MM-DD America/Denver — EARLIEST date the analysis can run: today if data is available, else when the required data lands>
  context: <self-contained prompt: candidate context, which Strategy.md criteria apply, references to Operating_Protocols.md / B_Sub_Pattern_Taxonomy.md / Watchlist.md, and the specific data to fetch (e.g. "Tue 6/2 close for Day-0 CTC via connector get_price_snapshot")>
  conservative_default: <action if the analysis still cannot resolve on its due_date — always the conservative branch (skip / decline GO / exit). Deferrals do not chain.>
  status: <pending | complete | superseded>
  outcome: <set when complete: GO/NO-GO + events.decision_log pointer>
```

### Draining the queue

D2 (Daily Action Conversion) is the daily drainer. Each run, after Step 0 fill reconciliation, it reads `state.open_queue` (queue `PENDING_ANALYSIS`) and processes every entry with `status: pending` and `due_date <= today` (America/Denver): perform the analysis, write outputs, and for a GO craft the order + `Confirm order` event; then insert a `complete` status row to `events.queue_events` with the `outcome`. If an entry's required data is still unavailable on its due_date, apply its `conservative_default` and mark complete — do NOT re-defer (deferrals do not chain). Use isolated sub-tasks (subagents) per analysis where available so fan-out (e.g., ten B candidates) gets fresh context per thesis without context exhaustion. D2 only inserts the `complete` status row (with its `outcome`); there is no archive sweep — the terminal-status row drops the entry out of `state.open_queue` automatically.

## IBKR connector usage

Canonical protocol: Operating_Protocols.md §11. Operational summary for routines:

**Crafting an order (equity/ETF).** When a routine stages an order: (1) resolve the `contract_id` (use the cached id from the **Cached `contract_id`s** list in this section below, else `search_contracts` selecting the US primary listing — `country_code` US, primary exchange, exact symbol, STK/ETF section); (2) pull a **realtime** `get_price_snapshot` (the operator's IBKR market-data subscription — the most accurate live quote, authoritative over web/delayed prices) and set a marketable limit (sell at a slight discount to last / buy at a slight premium; use MARKET when assured execution is the objective, e.g. a convergence exit already through target) — if the quote is not live (empty bid/ask pre-market, or a stale `last.ts`), base the limit on prior-close with a wider buffer rather than a stale price; (3) call `create_order_instruction(contract_id, side, quantity, order_type, limit_price, time_in_force)` with **`time_in_force` always `DAY`, never GTC** (the connector has no modify/amend endpoint, so a persist-and-wait order is re-crafted fresh as a DAY order each session — which is also the checkpoint to re-price the limit to the live market; Operating_Protocols.md §11) and capture `{id, url}`; (4) record the instruction `id` in the `state.open_orders` staged-order row (`events.queue_events`, queue `ORDER_STAGED`); (5) put `url` + summary + `id` into the order-confirmation calendar event. If a staged order is superseded before the operator confirms, call `delete_order_instruction(id)`.

**Order-craft is Equity/ETF only.** For options / futures / other security types, do NOT call `create_order_instruction` — emit a manual-entry text order block in the calendar event, labeled "manual entry — connector cannot craft this security type."

**Reconciling fills (D2 Step 0, daily, idempotent by `trade_id`).** Read `get_account_trades` over a multi-day window (e.g. DAYS_7). For each fill whose `trade_id` is not already recorded in `events.trade_fills`: write exact price / size / `commission` / `realized_pnl` / `trade_time` (`INSERT INTO events.trade_fills`); flip ORDER-STAGED→OPEN or exit-pending→CLOSED via an `events.position_events` row; update strategy sector counts / KL events; record the fill against the position's decision via `CALL ops.sp_log_decision(...)` (`events.decision_log`). Take realized P&L from the connector's `realized_pnl` field — never infer it. Aggregate exchange-split partial fills by `order_id`. Then refresh live marks/cash from `get_account_positions` + `get_account_summary` + `get_account_balances`, and note still-working orders from `get_account_orders`.

**Source-of-truth boundary.** Connector = authoritative for fills, positions, cash, live orders, quotes. The BigQuery events-side state is authoritative for strategy-bucket cost-basis attribution (`state.current_positions` / `events.position_events` `cost_basis`) and per-strategy NAV (`analytics.strategy_nav`) — the connector has no strategy buckets. On account-level drift (dividends/fees/reinvest), the connector is the truth and the events-side state is corrected to match (via `events.position_events` / `analytics.account_reconciliation`) while preserving strategy attribution at the cost-basis level.

**Sizing and analysis on live data.** The 2% position-sizing base is the **per-strategy sub-portfolio NAV** (Strategy.md "2% of strategy portfolio"), read from `analytics.strategy_nav` (~$1,880–1,890/strategy → ~$38/entry) — NOT `get_account_summary` net-liquidation, which is the whole-account figure (~$9,460 = all five sub-portfolios + the SGOV park) and oversizes ~5× if used as the base; net-liq / `available_funds` / `buying_power` are for execution-feasibility only (does the SGOV-funded entry settle), never the sizing base. **Sanity tripwire: a computed single-name entry over ~$50 (or >3% of the sub-portfolio) means the wrong base was used — STOP and recompute off the sub-portfolio.** Use `get_account_positions` for exact current holdings; use `get_price_snapshot`/`get_price_history` for quotes, close-to-close verification, and convergence-target checks. Web quotes are a fallback only when the connector lacks the instrument.

**Day-trade / buying-power guard.** Before staging a same-session round-trip (exit on the same day as entry), check `get_account_summary` `day_trades_remaining` — if 0, defer the exit one session (this is a small margin account where PDT can bind). Before an entry, confirm `available_funds` / `buying_power` cover the staged principal (entries are funded by liquidating the SGOV park).

**Mechanical exit monitoring.** D1's daily connector sweep checks each open position's live price against its convergence target and time-based-exit date and flags hits as EXIT TRIGGERED for D2 — so mechanical exits no longer wait on a per-position scheduled review (see D1).

**Rich market-data fields (use them wherever they sharpen a decision).** `get_price_snapshot` exposes far more than last/bid/ask:
- *Instrument eligibility:* `avg-90d-usd-volume` (when populated) gives dollar ADV for the Strategy B criterion-1 ≥$10M liquidity gate; it can be omitted by the API, so if absent derive ADV from `get_price_history` (volume × close). `misc-statistics` gives 13/26/52-week high/low.
- *Pre-event-rally / momentum context (B sub-pattern 3 + criterion-2 disproportion):* `year-to-date-change` + the 52-week range (`misc-statistics`) + returns derived from `get_price_history` quantify how much of a move was a pre-print rally already absorbing the narrative. (The `cumulative-perf-*` fields are ETF/fund-oriented and come back empty for most single stocks — do not rely on them for equities.)
- *Volatility context:* `implied-vol`, `implied-volatility-percentile`, `historical-vol` gauge whether a post-event move is large relative to the name's own vol regime.
- *Options analytics (A/C options theses):* `implied-vol`, `option-midpoint-iv`, `option-volume`, `option-open-interest`, `underlying-today/avg-option-volume`. The connector cannot CRAFT options orders (equity/ETF only — fall back to a manual block), but it supplies the data to BUILD and size the options thesis.
- Always pull `get_price_history` with `include_corporate_actions: true` so splits / special dividends are surfaced and never masquerade as price moves — critical for the B criterion-1 close-to-close magnitude gate and convergence-target derivation, and for attributing account drift in D2 Step 0.

**Cached `contract_id`s for current holdings** (verify against `get_account_positions` at use; ids are stable per instrument): SGOV 424099317, RTX 415342104, DIS 6459, HCA 85076790, TJX 12814, ZBRA 276304, BRC 6467986, AZO 4750, BURL 135699190. New names resolve via `search_contracts`.

## Chat output discipline

Routine chat output to the human contains only:

1. The order(s) to execute, surfaced as crafted IBKR order instructions — the tap-to-confirm deep link plus a one-line `SIDE QTY TICKER TYPE LIMIT TIF` summary (or `no order`), grouped by execution day if more than one. (Manual-entry text block only for security types the connector cannot craft.)
2. A one-line acknowledgment of writes performed and calendar events created (e.g., `events.decision_log + events.position_events written. 1 order instruction crafted, 1 calendar event scheduled.`).
3. If applicable, a short flag for any high-urgency item the human should be aware of when checking IBKR (e.g., "Flagged: AAPL exit limit set 1% below last close; reconsider if quote moves").

Routine chat output does NOT contain:

- Recapitulation of decision reasoning (lives in `events.decision_log`)
- File contents inside fenced code blocks (Claude writes files directly)
- "→ Filename.md (replace)" annotations (the persistence path is gone)
- Adversarial-review summaries
- Pillar/criteria walkthroughs
- "Three things to flag" / "two things to note" framings
- Pending-queue summaries beyond what affects the human's next action
- Theater-checks
- Compaction-survival notes (these belong in `events.decision_log`, not chat)
- Explanations of why a NO-GO is a NO-GO when no human action is required
- Operator-override paths when the recommendation is NO-GO

If a routine has no orders, no file changes, and no events: state `No actions required.` and end.

## Self-check before composing chat output

Claude performs the following checklist in thinking blocks before composing every routine's chat output:

- [ ] Have I created any task for the human beyond confirming a crafted order or pasting a calendar prompt? (Screenshots are obsolete — never ask for one.)
- [ ] Have I asked the human to make any decision?
- [ ] For every staged equity/ETF order, did I craft the order instruction (`create_order_instruction`) and surface its deep link — rather than emit a raw text block the human must type?
- [ ] Have I included file contents in chat (fenced code blocks, "attached files," etc.) when the file should have been written directly?
- [ ] Have I deferred a decision to "human's call" that I should have resolved myself?
- [ ] Have I factored commissions into a staging-time decision?
- [ ] Have I scheduled an order-confirmation event (07:00 MT pre-market on order day) carrying the deep link for any staged equity/ETF order?
- [ ] If I deferred a decision, have I specified its resolution trigger and conservative-default fallback?

If any answer reveals a violation, the response gets revised before sending.

---

# FILE CONVENTIONS AND READ-ACCESS SCOPE

## Decision-log lifecycle and archive policy

**SUPERSEDED 2026-06-06 (BigQuery cutover — Operating_Protocols.md §15).** The decision log is now `events.decision_log` (queryable; full narrative in `body_md`; semantic lookup via `analytics.find_precedents()`). There is **no live/archive split and no pruning** — BigQuery holds all entries, bounded automatically, so W5's archival lifecycle is retired. Routines write each new decision as an `events.decision_log` row (structured fields + `body_md`) and read via SQL / `find_precedents()`. `B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, and `Operating_Protocols.md` remain as kept `.md` factbase/spec files. The paragraphs below describe the retired `.md` live-log + per-quarter archive lifecycle and are kept only as historical context.

`Decision_Log.md` was the LIVE decision log — entries that are still operationally relevant (open positions, active deferrals, current protocol revisions, recent dispositions within retention windows). Pruned weekly by W5.

`Decision_Log_Archive_<YYYY>_<QN>.md` files contain matured entries from prior periods, organized by quarter (e.g. `Decision_Log_Archive_2026_Q2.md`). One file per quarter; appended throughout the quarter as W5 archives matured entries; closed at quarter-end.

`B_Sub_Pattern_Taxonomy.md` is the canonical reference for Strategy B criterion-4 NO-GO sub-patterns, extracted from individual `events.decision_log` NO-GO rows by W5. Thesis-construction sessions read this file rather than scanning scattered NO-GO entries for sub-pattern context. (Analogous per-strategy taxonomy files may be created later if other strategies accumulate enough sub-pattern data to warrant extraction.)

`Watchlist.md` is a factbase tracking names queued for re-evaluation under specific conditions. Living document; read by all cadences; written by D2/W4/M4 (action-conversion routines) and W5 (mirroring). Sections per strategy. Currently the only structurally-needed section is **Strategy A queue** (names awaiting router-activation re-evaluation — populated by router-gate NO-GO sessions, drained by M4 sessions when A router flips ACTIVATE). Strategy D pending re-screens are tracked in calendar events (canonical source); Strategy B prior-NO-GOs are not queued because B operates on event-flow with fresh-evaluation discipline (sub-pattern factbase preserves the durable signal). Sections may be added as other strategies surface persistent queue needs.

`Operating_Protocols.md` is the canonical reference for active operational protocols (the operating-model section of this file in current canonical form, commission-disregarded protocol, "NO-GO records are context, not barriers" rule, conviction-calibration ladder, deferral chaining rules, etc.). Living document; read by all cadences. Each protocol section contains current canonical text plus a revision-history pointer list. When a protocol is revised, the new revision text replaces the canonical section and a new entry is added to revision history pointing to the `events.decision_log` row that introduced the revision.

When an entry is archived, the live Decision_Log.md replaces the moved-out section with a single-line pointer:

`# [archived] <YYYY-MM-DD> <title> → Decision_Log_Archive_<YYYY>_<QN>.md`

Future sessions looking up specific historical entries find either the entry or the pointer in the live file.

## Queue lifecycle and daily archive policy

**SUPERSEDED 2026-06-06 (BigQuery cutover — §15).** The queues are now `events.queue_events`; **`state.open_queue` is the live view** (latest status per item, filtered to actionable). Enqueue = insert a `queue_events` row; complete/supersede = insert a terminal-status row; there is **no `.md` queue and no `.md` daily-archive** — status filtering in `state.open_queue` replaces the physical archive entirely, so D3's queue-archive sweep is retired. D2 reads due analysis items from `state.open_queue` (queue `PENDING_ANALYSIS`); the Adversarial routines read `PENDING_REVIEW`; the Strategy-A queue stays in `Watchlist.md`. The paragraphs below describe the retired `.md` queues and are historical context.

The two drain-to-completion queues — `Pending_Analysis.md` (drained daily by D2) and `Pending_Adversarial_Reviews.md` (drained by the Adversarial Review routines) — were cleared **daily**, not on a retention window. A queue is read **to completion** by its drainer every day to find the entries it must act on, so a completed entry left in place is needlessly re-read each day — the opposite of `Decision_Log.md`, which is append-only, never scanned end-to-end, and therefore tolerates W5's weekly retention-window prune.

Each day **D3 Calendar Hygiene** sweeps every entry at a terminal `status` (`complete` or `superseded`) out of its live queue into the queue's daily archive — `Archived_Analysis.md` / `Archived_Adversarial_Reviews.md`. The full entry block is appended (tagged with an `archived: <YYYY-MM-DD>` field) and then **removed from the live file entirely**: this is a full clear — **no pointer line is left behind** (unlike the Decision_Log archive). The live queue therefore holds only actionable entries — `pending`, plus the adversarial queue's in-flight `attacker-complete` mid-state — preceded by its unchanged header + schema-reference preamble.

Lookup convention (BigQuery era): a queue item id **absent from `state.open_queue` has a terminal-status row in `events.queue_events`** (no archive file). The durable record of any verdict/outcome lives independently in the per-review output files (`Adversarial_Review_<id>_*.md`) and `events.adversarial_reviews`, the router rows in `events.regime_events` (`state.current_regime`), and `events.decision_log` — a gate that needs a completed review's result reads those, not the queue entry. (Historically the terminal entries were swept to `Archived_Analysis.md` / `Archived_Adversarial_Reviews.md`; both archive files are retired — `events.queue_events` holds all history, queryable, and Q1's regime retrospective queries `events.adversarial_reviews` / `events.queue_events` for prior-quarter review records.)

## Action-conversion routines (deep research → action)

Deep-research routines produce exactly one output file. A research file with recommendations sitting in it is not an action; the human acts only on crafted order confirmations, so any recommendation in a research file evaporates at the next overwrite unless something converts it into an order, an edited live file, or a `PENDING_ANALYSIS` queue entry (`events.queue_events`).

Each cadence with deep-research routines that produce actionable recommendations therefore carries an **action-conversion** routine that runs after all of that cadence's research files are saved. The action-conversion routine reads the just-saved research file(s) and emits orders / live-file edits / calendar events.

Pairing:
- **D2 Daily Action Conversion** — reads Daily.md.
- **W4 Weekly Action Conversion** — reads Weekly_Catalyst_Calendar.md, Weekly_Post_Event_Screen.md, Weekly_Position_Deep_Dive.md.
- **M4 Monthly Action Conversion** — reads Monthly_Fundamental.md (M1b output, which echoes M1a regime scoring in PART 1), Monthly_E_Pairs.md, Monthly_D_Position_Deep_Dive.md.
- **Q4 Quarterly Action Conversion** — reads Quarterly_D_Candidates.md and Quarterly_AI_Foundation_Delta.md (Q1 Quarterly_Regime.md is a pure backward-looking factbase with no actions).
- **A3 Annual Action Conversion** — reads Annual_AI_Foundation_Sweep.md and Annual_Constraint_Audit.md; produces updated AI_Trading_Foundation.md and updated Strategy.md.

Cadence-level hygiene routines (D3 Calendar Hygiene, W5 Factbase & Analytics Consolidation) run after action conversion since they reference state mutated by it.

Because each routine run is a fresh session, deep-research routines must persist EVERYTHING the action-conversion routine will need into the cadence-output file. The legacy "PART 1 saved / PART 2 in-chat" split is obsolete — both parts go into the file.

## File-write conventions for routine outputs

Cadence-output files (Daily.md, Weekly_Catalyst_Calendar.md, etc.) are overwritten in full each run. The first line is always a date marker:

- Daily files: `YYYY-MM-DD` (today's calendar date).
- Weekly files: `YYYY-WW` (current ISO week).
- Monthly files: `YYYY-MM` (the month identified by the prompt — typically prior calendar month for retrospective tasks, current month for forward-looking tasks).
- Quarterly files: `YYYY-QN` (the quarter identified by the prompt — prior for Q1/Q3 retrospectives, current for Q2 forward).
- Annual files: `YYYY` (calendar year).

The kept living spec/factbase files (Watchlist.md, Operating_Protocols.md) are edited surgically. Routines apply minimal in-place edits via str_replace or the equivalent; they do not rewrite these files in full unless the prompt explicitly calls for a full rewrite. (The former live-state `.md` files — Decision_Log, Portfolio_Ledger, Regime_State — are retired: decisions/positions/regime are now appended to `events.*` and read via `state.*`, not edited in place.)

The Decision_Log per-quarter archive files (`Decision_Log_Archive_*`) are retired — `events.decision_log` holds all history (queryable, bounded), so there is no archive file to append to.

The queue archives (`Archived_Analysis` / `Archived_Adversarial_Reviews`) are retired — terminal-status rows drop out of `state.open_queue` automatically and all history lives in `events.queue_events`, so there is no daily archive sweep.

## Read-access scope by cadence

**BigQuery cutover note (§15):** `events.decision_log` holds ALL decision history — queryable and bounded automatically. There is **no live/archive split** anymore: routines query `events.decision_log` (+ `analytics.find_precedents()` for semantic lookup) and let the WHERE clause bound the window, rather than choosing between a "live" file and per-quarter archive files (both retired). Likewise queue history is all in `events.queue_events` (live view `state.open_queue`); there is no `.md` queue archive. The per-cadence rules below now express *how much history a cadence queries*, not which files it opens.

**Daily and Weekly routines** (D1, D2, D3, W1, W2, W3, W4, W5):
- Query `events.decision_log` bounded to the operationally-relevant recent window (open positions, active deferrals, recent dispositions) — do not pull full multi-year history.
- Do not query the queue history for decision input beyond `state.open_queue` — the live view carries every actionable entry; older `events.queue_events` rows are cold traceability. (Monthly+ cadence MAY query deeper — e.g., Q1 queries `events.adversarial_reviews` / `events.queue_events` for prior-quarter review records.)
- Cross-strategy factbase files (`B_Sub_Pattern_Taxonomy.md`, `Quarterly_D_Candidates.md`, `Weekly_Catalyst_Calendar.md`, etc.) ARE in scope and should be read as the prompt directs.
- If a daily/weekly routine genuinely needs a decision older than its recent window (rare), this is a signal that the relevant content should have been extracted to a factbase. Surface it via an `events.decision_log` entry rather than widening the routine's habitual query window.

**Monthly routines** (M1a, M1b, M2, M3, M4):
- May query all of `events.decision_log`. **Exception: M1a's read scope is restricted by design — see M1a's prompt body. M1b's read scope is restricted to the M1a regime-scoring input (`state.current_regime` / `events.regime_events`) — see M1b's prompt body.**
- In practice most monthly tasks operate on current open-book state and do not require deep-history queries. Query the full log only when the prompt explicitly directs (e.g., per-strategy thesis-invalidation count for the trailing 36-month window).

**Quarterly routines** (Q1, Q2, Q3, Q4):
- May query all of `events.decision_log` (and `events.queue_events` / `events.adversarial_reviews` / `events.regime_events` as needed).
- Q1 (Regime Retrospective) explicitly queries prior-quarter router history (`events.regime_events`) and adversarial review records (`events.adversarial_reviews`).
- Q2 (D Long-Horizon Candidates) and Q3 (AI Foundation Delta) reference historical dispositions and prior-cycle outcomes.
- Q4 (Action Conversion) reads only the just-saved Q2/Q3 research files plus live state; deep-history queries not required.

**Annual routines** (A1, A2, A3):
- Query everything, including full `events.decision_log` history.
- A2 (Per-Strategy Constraint Audit) explicitly traces foundation-citation graphs across full `events.decision_log` history.
- A3 (Action Conversion) reads only the just-saved A1/A2 outputs plus live state; deep-history queries not required.

## Shared rules referenced across prompts

**"NO-GO records are context, not barriers."** A prior NO-GO entry on a candidate informs current evaluation but does not pre-empt it. New evidence, new context, new structural conditions can flip a prior NO-GO to GO. The `events.decision_log` NO-GO row tells future Claude what to look at, not what to conclude. For Strategy B, sub-pattern taxonomy entries are particularly informative — a candidate matching a documented sub-pattern faces a high bar but is not auto-rejected.

**Conviction-calibration ladder.** Conviction is logged in `events.decision_log` rows on a coarse scale (e.g., 30%, 45%, 60%, 75%) for after-the-fact calibration analysis. It is not a gate. A 45%-conviction setup that clears all criteria stages; a 75%-conviction setup that fails any criterion declines.

---

# DAILY (after market close)

## D1. Market Development Scan — deep research

```
Read access scope: Daily cadence. Query `events.decision_log` (+ `analytics.find_precedents()`) bounded to the recent operationally-relevant window — `events.decision_log` holds all history, queryable, no live/archive split (§15). Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction.

Read Strategy.md, Experiment_Parameters.md, AI_Trading_Foundation.md, Watchlist.md, Operating_Protocols.md (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

Read `state.current_positions` to identify currently-open positions across Strategies A, B, C, D, E with their entry-record thesis-invalidation criteria. Read Watchlist.md for queued names.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior `events.decision_log` NO-GO entry.

Produce a daily market development scan and write it directly to `Daily.md` (overwrite; first line = today's calendar date in YYYY-MM-DD format).

SCAN WINDOW — dynamic, measured from the last D1 run to now (not a fixed lookback). Set the window start = the timestamp through which the previous D1 scan covered, and scan all developments from there to now (this run's execution time, America/Denver). Resolve the start automatically, in priority order:

1. **Prior Daily.md stamp (primary).** At run start, `Daily.md` on disk is still the previous run's output (this run overwrites it). Read it first and parse the machine-readable marker `<!-- d1_scan_through_utc: <ISO-8601 UTC> -->` written just below the date line by the previous run — that timestamp is the exact hand-off boundary → window start.
2. **Git commit timestamp (fallback + cross-check).** If the marker is missing or unparseable, use the commit time of the most recent `Daily.md` commit — `git log -1 --format=%cI -- Daily.md` (every D1 run commits Daily.md as "D1 Market Development Scan …"). Also use this to sanity-check (1); the two should agree to within one session's length.
3. **Conservative fixed lookback (last resort).** If neither is available (e.g. a shallow clone with no Daily.md history, or no prior file at all), fall back to a 30-hour lookback ending now. Never silently narrow coverage below this.

This keeps coverage gap-free across skipped or delayed runs: if a scheduled run was missed, the window automatically stretches back to the *actual* last run instead of dropping a session (e.g. the 2026-06-06 run correctly had to cover the Friday 6/5 session because there was no D1 between Thu 6/4 and Sat 6/6 — a fixed 24-hour lookback would have missed all of Friday). If the resolved start is more than ~50 hours ago (a multi-session gap), state the gap explicitly in the scan-window line; always cover at least the most recent completed trading session even when the elapsed window is short. Throughout DEVELOPMENTS below, "today" means "within this scan window" (≥ today; more when the window spans a missed run).

Record the boundary for the next run: in the Daily.md you write, emit `<!-- d1_scan_through_utc: <this run's execution time, ISO-8601 UTC> -->` on the line directly below the date, and a human-readable `Scan window: <start · America/Denver> → <now · America/Denver>` line in the header.

Cast broadly — do not scope the scan to tickers owned or on the watchlist. The purpose is to surface any development that could either threaten an existing position's thesis or create a new entry opportunity for any strategy, including at names not currently on any list. Do not pad; if a category has no material items, state so.

DEVELOPMENTS

1. Market-wide breaking events. Geopolitical shocks, unscheduled regulatory or enforcement actions, material bankruptcies, disasters, or events materially affecting global risk assets. Per event: what happened, source, observable reaction across equities / rates / commodities / FX.

2. Scheduled events that resolved today (across the US-listed universe with market cap ≥ $2B, not limited to watchlist). Earnings prints (EPS/revenue vs. consensus), FDA PDUFA outcomes, FOMC actions, other resolved catalysts. Per event: outcome, price reaction if observable, source.

3. Large single-name moves. US-listed equities with market cap ≥ $2B that moved ≥5% close-to-close today attributable to identifiable public events. Per name: ticker, move magnitude and direction, event type, source.

4. Sector-level moves. Any GICS sector with a move of ≥2% at sector-ETF level or notable intraday dispersion. Per sector: magnitude, apparent driver, source.

5. Notable commentary. Major sell-side reports issued, regulator or central-bank speeches with market-moving content, senior corporate commentary worth noting.

ANALYSIS — RISK TO EXISTING POSITIONS

MECHANICAL EXIT-TRIGGER SWEEP (run for EVERY open position regardless of whether any Development fired). Read the open book + its two MECHANICAL exit triggers (`convergence_target`, `time_exit_date`, with `contract_id`) from **`state.current_positions`** (BigQuery — authoritative per Operating_Protocols.md §15, D2-maintained), and pull live prices from the IBKR connector (`get_price_snapshot` per name). Parallel-run cross-check: confirm the open set matches `get_account_positions` and flag any divergence (`state.current_positions` is the canonical open book; the connector is authoritative for live holdings). For each open position, check the two MECHANICAL exit triggers:
- **Convergence target hit** (Strategy B / E price targets): live price at or through the convergence target → flag EXIT TRIGGERED (mechanical — the target IS the exit rule per Strategy.md; no judgment needed).
- **Time-based exit due**: today (America/Denver) ≥ the position's time-based-exit date → flag EXIT TRIGGERED.
This catches a target-hit the next morning without waiting for a per-position scheduled review — the lag that left the BURL convergence exit owed for days under the screenshot workflow. It retires the per-position pulse-check / time-exit / convergence-check calendar events entirely (this daily sweep replaces them). D2 converts every EXIT TRIGGERED flag into a crafted exit order.

PER-STRATEGY KILL-TRIGGER SWEEP (connector-driven; run for EVERY active strategy, alongside the per-position sweep above). Read each strategy's kill/gate state from **`perf.kill_flags`** (BigQuery engine — `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, computed from the latest `perf.strategy_daily`). D1 runs before D2, so the engine row is yesterday's close — refresh `current_drawdown` against today's live marks (`get_price_snapshot`) if a position moved sharply intraday, then evaluate the flags below against the thresholds in Experiment_Parameters.md "Kill criteria (per-strategy)":
- **Drawdown kill (#1, mechanical / immediate):** if peak-to-trough deployed TWR has dropped ≥50% from the strategy's highest historical value since first trade → flag **STRATEGY TERMINATION — DRAWDOWN**. Rigid and context-independent — no judgment, no review.
- **Runaway-success (#3, pre-gate only):** if deployed TWR has **doubled** AND the strategy has not yet cleared its 30-trade gate → flag **RUNAWAY-SUCCESS REVIEW** (does NOT terminate directly — routes to an m2m-termination review to rule out reward-function exploitation / hidden tail risk).
D2 converts a DRAWDOWN flag into an immediate strategy termination (close all positions + deterministic redistribution) and a RUNAWAY-SUCCESS flag into an enqueued review. (The mark-to-market #4 and foundation-change #2 triggers are detected on slower cadences — M4 monthly and Q3/A1 respectively — not here.)

For each open position, does any Development above ALSO trigger a (judgment-laden) thesis-invalidation exit criterion in the position's entry record (per Strategy.md exit rules for the relevant strategy)? For each position affected: position (ticker + strategy), triggering development, whether the invalidation criterion is met (YES with specific criterion / NO with reasoning).

For each watchlist candidate: does any Development materially change candidacy status (closer to entry / invalidated / unchanged)?

ANALYSIS — OPPORTUNITY CHECK

For every Development above, evaluate whether it creates a new entry candidate for any of Strategies A, B, C, or E (D's multi-year horizons rarely turn on single-day developments). Do not limit evaluation to existing watchlist names — names currently unwatchlisted can become candidates, and names currently held in one strategy can incidentally create candidacy in another (with the simultaneous-holding constraints from Strategy.md respected). Examples of signals to surface:
- ≥5% post-event move on a name fitting Strategy B's eligibility → B candidate (10-day entry window)
- Newly announced qualifying catalyst within 45 days on a name fitting Strategy C's eligibility → C candidate
- Catalyst announcement within 6 months on a name fitting Strategy A's eligibility → A candidate
- Sector-level divergence that opens intra-industry-group pair opportunities → E candidate

Per new opportunity: ticker, strategy, why the development creates the opportunity, next step (full thesis construction required in a separate session per Strategy.md entry criteria).

ANALYSIS — REGIME CHECK

Does any Development plausibly shift any strategy's router activation state enough to warrant an inter-monthly router review, given the shared regime vocabulary and per-strategy activation rules in Strategy.md? High bar; default NO on ambiguity.

ANALYSIS — FRONTIER-LLM CAPABILITY CHECK (light-touch, optional)

Run AT MOST ONE Hugging Face `paper_search` query per day, rotating across the §6.1 query batteries from `HF_Resource_Catalog.md` on a weekly cycle (e.g., Mon: cross-session consistency, Tue: prompt injection, Wed: calibration, Thu: sycophancy/anchoring, Fri: trading/financial, Sat: multi-agent debate, Sun: long-context). Use `concise_only=true` and `results_limit=5`. Skim only the abstracts of papers published since the last D1 run — use the SCAN WINDOW start resolved above as the lower bound (capped at ~72 hours so a multi-day gap stays light-touch; on the normal daily cadence this is ~24 hours), so a skipped run does not silently drop a day's papers. If a result materially bears on a documented `AI_Trading_Foundation.md` disadvantage (Tier 1 architectural change, new failure mode, or contradicts a Tier 2 numerical claim per `HF_Resource_Catalog.md` §2 inverse mapping), write an `events.decision_log` entry via `CALL ops.sp_log_decision(...)` tagged `[HF Frontier-LLM Capture]` with the arXiv ID, a one-paragraph summary, and the affected `AI_Trading_Foundation.md` item. Reference-only — D1 does NOT act on the finding today; Q3 queries `[HF Frontier-LLM Capture]` entries in `events.decision_log` during its quarterly delta to surface mid-quarter material deltas. Default is silent on ambiguity. No Daily.md output for this check.

RECOMMENDED ACTIONS

The downstream D2 routine reads this section verbatim and converts each bullet into an order / live-file edit / calendar event, so be specific (ticker, strategy, criterion-cited where applicable):
- Exits triggered (with invalidation criterion and strategy)
- New entry candidates (with strategy) requiring full thesis construction in separate sessions per Strategy.md
- Watchlist updates (adds / removes / demotions)
- Router reviews recommended (with justification)

If nothing material: "No recommended actions."

OUTPUT: write the complete content above directly to `Daily.md` (overwriting the prior day's file). First line is today's date in YYYY-MM-DD format; the line directly below it is the machine-readable `<!-- d1_scan_through_utc: <this run's execution time, ISO-8601 UTC> -->` marker (per SCAN WINDOW above — this is what the next run reads to resolve its window start), and the header carries the human-readable `Scan window: <start · America/Denver> → <now · America/Denver>` line. No chat output beyond a one-line acknowledgment that Daily.md was written.
```

---

## D2. Daily Action Conversion — regular routine

Runs after D1 has written Daily.md. Reconciles fills, drains the analysis queue, and converts D1's RECOMMENDED ACTIONS into orders and live-file edits — running thesis construction and other analyses in-session (no human-pasted thesis events).

```
Read access scope: Daily cadence. Read decisions from `events.decision_log` + `analytics.find_precedents()` (the retired `Decision_Log*.md` are git history only). Read positions/perf/NAV from `state.current_positions` / `perf.strategy_daily` / `analytics.strategy_nav` (retired Portfolio_Ledger.md) and regime from `state.current_regime` (retired Regime_State.md). Read the spec/working files `Strategy.md`, `Experiment_Parameters.md`, `Operating_Protocols.md`, `Watchlist.md`, `B_Sub_Pattern_Taxonomy.md` as relevant.

RUN LOGGING (every run — observability, `bigquery/10_observability.sql`). At the very START of this routine, `CALL ops.sp_log_run('D2', <today, America/Denver from state.trading_day_today>, 'started', <session_id>, <branch>, NULL, NULL, NULL)`. At the END, call it again with `'completed'` (or `'failed'`/`'halted'` + an `error_msg` if it stopped), passing `rows_written` = fills + marks ingested. This populates `state.freshness.d2_ran_last_trading_day` and arms the dead-man's switch (`bigquery/scheduled_queries/daily_freshness_check.sql`), so a silently-skipped or crashed D2 is detected instead of failing silent.

STEP 0 — BROKER RECONCILIATION (run first, every run, before reading Daily.md's actions). Reconcile the live brokerage account against the BigQuery events-side state (`state.current_positions` / `analytics.account_reconciliation`; Portfolio_Ledger.md is retired, §15) via the IBKR connector. This replaces the retired operator-screenshot fill-capture sessions (Operating_Protocols.md §11):
- Read `get_account_trades` over a DAYS_7 window. For each fill whose `trade_id` is NOT already in `events.trade_fills` (idempotent match on `trade_id`): record the exact price / size / `commission` / `realized_pnl` / `trade_time` (via the BigQuery event-sourcing step below); flip the affected position ORDER-STAGED→OPEN (entries) or exit-pending→CLOSED (exits) with an `events.position_events` row, and set the matching `state.open_orders` staged-order row terminal `filled` (Operating_Protocols.md §11 staged-order registry); update strategy sector counts and any KL #12 event membership; write the GO/close decision via `CALL ops.sp_log_decision(...)` if staging recorded only the order. Realized P&L comes from the connector's `realized_pnl` field — never inferred. Aggregate exchange-split partial fills by `order_id`.
- **Mirror the reconciliation to the BigQuery event tables (connector-driven event-sourcing).** For each new fill: `INSERT INTO events.trade_fills` (trade_id, order_id, contract_id, fill_ts, strategy, ticker, side, shares, price, commission, realized_pnl) — idempotent by `trade_id`; and write the position lifecycle event to `events.position_events` — an `OPEN` event on an entry (`cost_basis = shares×price + commission`, contract_id, shares, plus convergence_target / time_exit_date / conviction / source_thesis_ref from the staging entry) or a `CLOSE` event on an exit. This keeps `state.current_positions`, the deployed-TWR engine, and `state.daily_briefing` current. Also write the day's new decision via **`CALL ops.sp_log_decision(...)`** (bigquery/08_ops_procedures.sql) — this appends the structured `events.decision_log` row (incl. `body_md`) **and embeds it in the same call**, so a decision is never left unembedded (no separate `ML.GENERATE_EMBEDDING` step). Populate `ticker` (regex for the clean "Strategy X — TICKER" title format, else `ops.gemini` AI extraction per bigquery/02_ai_layer.sql). Sync is verifiable any time via `SELECT * FROM state.embedding_health` (expect `is_healthy = TRUE`); if a raw `INSERT` was ever used instead, `CALL ops.sp_embed_pending()` to catch up. **This connector/agent-driven event-sourcing SUPERSEDES the one-time `parse_*.py` migration path** (which produced the buggy initial rows, since rebuilt from the connector 2026-06-05/06); the parsers are kept for reference only.
- Read (do not transcribe) live positions, cash, and net-liquidation from `get_account_positions` + `get_account_summary` + `get_account_balances` for the reconciliation cross-check; reconcile account-level drift (dividends, fees, reinvestments, splits) to the connector truth while preserving per-strategy cost-basis attribution — use `get_price_history` with `include_corporate_actions: true` (plus the `get_account_trades` DRIP/dividend rows) to attribute the drift precisely. Per the connector-era recording policy, marks/market-values/unrealized-P&L are NOT written into the events-side state — only cost-basis and strategy allocation are (`events.position_events` / `state.current_positions`; live marks flow through `events.daily_marks` into the TWR engine instead).
- **Staged-order registry reconciliation (`state.open_orders`; run after fill reconciliation, before the §13 cash steps so reservations are current).** This is the durable persist-and-wait sweep (Operating_Protocols.md §11) — it iterates a queryable list, not the between-sessions-empty live-order endpoints, so a staged entry/exit can never be silently dropped. For each still-`pending` `ORDER_STAGED` row: **(a) filled** — if a fill reconciled above matches it (ticker / `contract_id` / side), set the row terminal by inserting a `queue_events` row (`queue='ORDER_STAGED'`, same `item_key`, `status='filled'`); the `position_events` OPEN/CLOSE + decision were already written in the fill loop. **(b) window still open + unfilled** (`entry_window_close >= today` MT) — re-craft it as a fresh DAY instruction: re-pull `get_price_snapshot`, hold the thesis's disciplined limit (or re-price to the live market if the thesis warrants — never chase past the documented rest level), `create_order_instruction`, write a new `ORDER_STAGED` `pending` row with the updated `payload.instruction_id` (same `item_key`), and create/repair the 07:00-MT confirm event. **(c) window closed + unfilled** (`entry_window_close < today`) — set the row terminal `expired` and **`CALL ops.sp_log_decision(...)`** recording the missed entry/exit (the `conservative_default` outcome). A row's reserved cash (next bullet) stays earmarked until it is terminal, so an entry cannot be de-funded while its window is open; a row leaves the registry only by a fill or a logged terminal decision. (Staging a NEW entry/exit — Step 1 GO, or Weekly/Monthly — writes the `pending` `ORDER_STAGED` row at the same time the instruction + confirm event are created; see the staging steps below.)
- **Cash/SGOV balance reconciliation — tripwire (run every time, before any sizing/staging; full procedure Operating_Protocols.md §13).** Compute expected SGOV shares + cash = Σ the per-strategy SGOV-share allocations and cash residuals from `analytics.account_reconciliation` (+ `state.sgov_reconciliation` for SGOV shares); compare to live SGOV shares (`get_account_positions`, SGOV contract_id 424099317) + live cash (`get_account_balances`), netting out commissions/realized-P&L of fills reconciled above. Attribute every non-zero residual per the §13 decision-tree — dividend/interest → owning strategy or pro-rata by SGOV share; deposit/withdrawal → equal-split; standalone fee → equal-split; commission-on-fill → trading strategy (already counted); operator SGOV-sale-to-cover-negative-cash → the strategies whose commissions created the deficit; genuinely unexplained → log + flag + conservative hold, never silently absorb. Find causes with `get_account_trades`, `get_price_history(include_corporate_actions: true)`, and net-liq-vs-Deposit-History. A residual that stays UNEXPLAINED and exceeds ~$1 is a hard STOP — resolve it before sizing or staging. On that hard STOP, also `CALL ops.sp_raise_alert('critical','D2','cash_tripwire', <one-line message>, <JSON: residual, connector evidence>)` AND create a `[Claude] ATTENTION — D2 halted (cash residual)` calendar event, plus `CALL ops.sp_log_run('D2', <today>, 'halted', …, error_msg=<message>)` — routine chat is unmonitored, so an unexplained halt must reach the operator via the alert sink + calendar (Operating_Protocols.md §13.A.4). Reconcile the per-strategy SGOV/cash allocation in the events-side state (`events.position_events` / `state.sgov_reconciliation`, surfaced via `analytics.account_reconciliation`) to the connector truth.
- **Cash flattening — auto-craft the SGOV sweep/cover (Operating_Protocols.md §13.E).** After the tripwire/attribution above, on **settled** cash: `free_cash = settled_cash − Σ reserved_cash from state.open_orders` (the durable staged-order registry — authoritative even between sessions when an earmarked entry's DAY order is not live; plus any live unfilled BUY in `get_account_orders`/`get_order_instructions` not represented there). This registry-based reservation is what stops a sweep from de-funding a staged entry mid-window (the 2026-06-08 MDT case). **Sweep** if `free_cash ≥ +$25` → craft BUY SGOV sized DOWN `floor_to_4dp((free_cash − ~$0.35 comm)/ask)` (can't overdraw; never sweeps cash a pending buy needs). **Cover** if `settled_cash ≤ −$5` (a *realized* debit — covers only what actually filled; does NOT pre-fund a resting limit buy) → craft SELL SGOV sized UP `ceil_to_4dp((|settled_cash| + ~$0.35 comm)/bid)`, capped at SGOV held (clears the debit; no margin left). Otherwise no action (a $0…−$5 debit is left on margin; commission to cover it isn't worth it). Order: contract_id 424099317, TIF **DAY** (§11), marketable limit (ask/bid) or MARKET; record instruction `id` + a 07:00 confirm event + an SGOV Parking Activity row; attribute to the owning strategy(ies) per §13.C so Σ per-strategy SGOV = connector SGOV and Σ per-strategy cash ≈ $0. Never sweep cash a pending buy needs.
- Note still-working / partial orders from `get_account_orders` (e.g. a DAY order not yet filled this session, or any legacy/operator-placed GTC still working) and leave them exit-pending / ORDER-STAGED. The persist-and-wait re-craft of an expired-but-still-intended order is handled by the staged-order registry reconciliation above (and mirrored by D3), driven off `state.open_orders` rather than the live-order endpoints (which are empty between sessions under the DAY-only policy, §11).
- For any crafted instruction in `get_order_instructions` whose order day has passed unconfirmed, or whose position Step 0 just closed, call `delete_order_instruction` to clear it.

STEP 0b — ACCOUNT SNAPSHOT (run after Step 0, while connector account data is fresh; one INSERT, best-effort). Persist the account-level NAV/cash/TWR you already read in Step 0 so the weekly self-email and account-NAV history have it — the Apps Script emailer (`ops/weekly_report/`) cannot reach IBKR, so D2 is the only writer. Pull `get_pa_performance_all_periods` and take the LAST element of each period's `cps` array (cumulative TWR fraction at the period end). `INSERT INTO ops.account_snapshot (snapshot_date, nav, total_cash, buying_power, available_funds, gross_position_value, sgov_market_value, twr_1d, twr_7d, twr_mtd, twr_ytd, twr_1y)`: today (America/Denver from `state.trading_day_today`); `net_liquidation`/`total_cash_value`/`buying_power`/`available_funds`/`gross_position_value` from `get_account_summary`; the SGOV market value from `get_account_positions` (contract_id 424099317); and `twr_1d/7d/mtd/ytd/1y` from the cps arrays. One row per `snapshot_date` (latest ingest wins via `state.account_latest`); if today's row already exists, skip. Wrap best-effort so a snapshot failure never aborts D2 — it feeds a report, not trading. (`bigquery/14_weekly_report.sql`.)

PER-STRATEGY PERFORMANCE MAINTENANCE (deployed-TWR engine; run after fill reconciliation above, daily, while connector marks are fresh). **The authoritative engine is the BigQuery value-weighted daily TOTAL-return TWR** (project `stock-trading-498512`: `events.daily_marks` → `analytics.strategy_daily_returns` + `analytics.sgov_daily_return` → `perf.strategy_daily` → `perf.kill_flags`; method in bigquery/03_twr_engine.sql + Operating_Protocols.md §14). The deployed-TWR / drawdown / gate state lives entirely in `perf.strategy_daily` (the former Portfolio_Ledger.md Performance block was a human-readable mirror of this row — retired 2026-06-06; `perf.strategy_daily` is now the sole record, not a separate hand-computation). Requires the BigQuery MCP connector (`execute_sql` / `execute_sql_readonly`).
1. **Ingest today's marks (TOTAL-return source).** For each held ticker + SGOV, pull `get_price_history(include_corporate_actions: true)` and `INSERT INTO events.daily_marks (mark_date, ticker, close, dividend, split_ratio)`: today's close, any ex-div cash dividend per share, and split_ratio (prices split-adjusted at ingest). Dividends on held stocks (material for D's multi-month holds) and SGOV's monthly DRIP income are captured HERE — a price-only mark silently drops them. Idempotent on (mark_date, ticker).
2. **Recompute the engine + embed (one call).** After the marks are in, **`CALL ops.sp_daily_refresh()`** (bigquery/08_ops_procedures.sql) — it runs `ops.sp_recompute_engine()` (a state-free `DELETE`+`INSERT` that rebuilds the full `perf.strategy_daily` series from `events.daily_marks` + the views) **and** `ops.sp_embed_pending()` (catches up any decision embeddings) in a single idempotent call. (Single-source: the recompute SQL lives only in the procedure now, not copy-pasted per run.) The recompute chains `deployed_unit_value ×= (1 + r_deployed)` (value-weighted daily TOTAL return, **GROSS of commissions** — the profitability metric per Operating_Protocols.md §14 "Commission policy": entry baseline = market cost, exit = gross proceeds, dividends in the numerator; commissions are excluded as a scale artifact of ~$30 positions but tracked EXACTLY in the cash/NAV accounting); `peak` = high-water mark vs the 1.000 inception base; `sgov_index ×= (1 + r_sgov)` from SGOV's ACTUAL close+dividend total return; then `excess`, `deployed_days`, and `closed_trades`/`gate_n` from reconciled CLOSE events. The full recompute is trivially cheap (~30 deployed days × active strategies) and absorbs any late mark/fill correction, so D2 re-runs it wholesale rather than appending one row. A strategy fully in SGOV all day contributes no row (indices pause). `perf.kill_flags` then reads the latest row.
3. **Verify the engine row (no ledger to mirror).** After the recompute, the engine's latest `perf.strategy_daily` row (`deployed_unit_value`, `peak_unit_value`, `current_drawdown`, `sgov_index`, `excess`, `deployed_days`, `closed_trades`, `gate_status`, `as_of` = today MT) IS the record — there is no Portfolio_Ledger.md Performance block to copy it into (retired; the Monthly-snapshots history lives in the `perf.strategy_daily` series itself). **The legacy hand-computation is RETIRED** — the engine was validated 2026-06-05 by a full rebuild from the connector's authoritative fills + real daily marks and independently hand-checked to within 0.04% on D, so it stands alone. The guardrail is automated, not a manual re-compute: trust `perf.strategy_daily`, but flag in chat if a day's `r_deployed` exceeds ±15% or `deployed_unit_value` leaves (0.3, 3.0) absent a matching large market move — those signal a bad mark or an unreconciled fill, not real performance.

**SEEDING A NEW STRATEGY (block still `[n/a]` — A/C/E on first deployment).** Seed via the **value-weighted daily method ONLY**: backfill `events.daily_marks` over the strategy's deployed days and let the engine compute `perf.strategy_daily` forward from inception. **Do NOT seed by sequentially chain-linking realized closed-trade returns** (`Π (1 + realized_pnl/cost_basis)`) — those trades are CONCURRENT, independently-funded ~2%-of-sleeve bets, so chaining them as sequential reinvestment manufactures compounding that never occurred and compounds only the winners while open losers enter as a single drag. **That anti-pattern overstated Strategy B's 2026-06-04 seed to 1.1099/+11%; the validated GROSS value-weighted figure (the profitability metric) is ≈ 1.0005/+0.05% (net-of-commission 0.966).** B and D are populated + validated in `perf.strategy_daily`. `gate_status = pre-gate`; set `deployed_days`/`closed_trades` from trade history.

STEP 1 — DRAIN PENDING ANALYSES (run after Step 0). Read due items from `state.open_queue` / `state.open_queue_detail` (queue `PENDING_ANALYSIS`). For every entry with `status: pending` and `due_date <= today` (America/Denver), perform the analysis in-session — each as an isolated sub-task (subagent) for fresh context where available, else inline sequentially. This is where deferred thesis constructions, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, and constraint-relaxation reviews actually run. For each entry: do the full analysis per its `context` (apply the relevant Strategy.md criteria, Operating_Protocols.md rules, B_Sub_Pattern_Taxonomy.md, connector live data §11); write the decision via `CALL ops.sp_log_decision(...)` (`events.decision_log`) and, if a position changes, the lifecycle event to `events.position_events`; for a GO, craft the order instruction and create the `[Claude] Confirm order` event (per the staging steps below); set the entry `complete` with its `outcome` (insert a terminal-status row to `events.queue_events`). If the required data is still unavailable on the due_date, apply the entry's `conservative_default` (skip / decline / exit) and mark complete — do NOT re-defer (deferrals do not chain).

Then read the just-saved `Daily.md` (today's market development scan; first line = today's date in YYYY-MM-DD format).

Convert every bullet in Daily.md's "RECOMMENDED ACTIONS" section into operator-actionable outputs per the operating model at the top of this file. Claude resolves all decisions internally; commissions are disregarded at staging time.

If Step 0 reconciled no new fills AND Daily.md "RECOMMENDED ACTIONS" reads "No recommended actions": output "No actions required." and end. (If Step 0 reconciled fills but there are no new Daily.md actions, report the reconciliation per chat-output discipline and end.)

For each recommendation type:

1. EXITS TRIGGERED. For each exit flagged:
   - Read Strategy.md exit rules and the position's entry-record invalidation criteria from `events.decision_log` (or the `state.current_positions` / `events.position_events` entry-record) to confirm the criterion is in fact met. If on review the criterion is NOT met, do not stage the exit; record the second-look decision via a brief `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) instead.
   - If confirmed: craft the exit order via the IBKR connector. Resolve `contract_id` (cached in the IBKR connector usage section's contract_id list, else `search_contracts`); pull `get_price_snapshot` and set the limit — for stocks a marketable limit (sell at a slight discount to last) unless the invalidation logic favors patient execution, or MARKET when assured exit is the objective; Day duration unless thesis logic requires GTC. Call `create_order_instruction(...)` and capture `{id, url}`. (Options legs: connector cannot craft — fall back to a manual-entry text block at mid of current bid/ask.)
   - Write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording: triggering development, specific invalidation criterion met, position exit decision, conviction-calibration notes per the conviction-calibration ladder.
   - Mark the position exit-pending with an `events.position_events` row carrying the staged order details and the crafted instruction `id` (there is no Portfolio_Ledger.md to update).
   - **Write the `pending` `ORDER_STAGED` row to `state.open_orders`** (Operating_Protocols.md §11 staged-order registry): an `INSERT INTO events.queue_events` with `queue='ORDER_STAGED'`, a stable `item_key`, and a payload carrying `side`/`qty`/`limit_price`/`contract_id`/`instruction_id`/`source_decision_ref` and the exit deadline as `due_date`. This is what keeps the resting DAY exit alive across sessions (Step 0 registry reconciliation) instead of letting it lapse when the DAY order expires.
   - Schedule a "[Claude] Confirm order — <ticker> SELL" calendar event for **07:00 MT pre-market on the order day**. Description: the `SIDE QTY TICKER TYPE LIMIT TIF` summary, the tap-to-confirm deep link (`url`), the instruction `id`, and "Tap the link, review the pre-filled order in IBKR, confirm at or after market open." (Options / other non-craftable exit: no `url` — carry the explicitly-labeled manual-entry text order block in the event description in place of the deep link.) No fill-capture event — the fill is reconciled by Step 0 on the next daily run.

2. NEW ENTRY CANDIDATES. For each candidate flagged, determine the earliest the thesis can run, from Strategy.md per the candidate's strategy:
     - Strategy B: 10 trading days from event — doable as soon as the Day-0 close-to-close is measurable (often the same evening; if the Day-0 close lands a later session, that close is the earliest-doable date).
     - Strategy C: catalyst within 45 days — runs in the pre-catalyst window (7-10 days before the catalyst when it is >14 days out; otherwise now).
     - Strategy A: catalyst within 6 months — respect router state. If A is DO-NOT-ACTIVATE per `state.current_regime` / most-recent M1 call, the candidate goes to Watchlist.md A queue (no thesis now). If ACTIVATE, the thesis is doable now.
     - Strategy E: pair divergence — normally handled by M2/M4; a fast-moving divergence may run now.
   - **If the thesis is doable now** (required data available; router admits it): perform the full thesis construction **in-session** — an isolated sub-task (subagent) per candidate for fresh context where available, else inline sequentially. Apply Strategy.md entry criteria, the Operating_Protocols.md "NO-GO records are context, not barriers" rule + conviction-calibration ladder, B_Sub_Pattern_Taxonomy.md, commission-disregarded staging, and the connector for live quotes / CTC / eligibility (§11). Write the decision (GO or NO-GO) via `CALL ops.sp_log_decision(...)` (`events.decision_log`) and, on a GO, the OPEN lifecycle event to `events.position_events`; craft the order instruction, **write the `pending` `ORDER_STAGED` row to `state.open_orders`** (Operating_Protocols.md §11 staged-order registry — payload: `side`/`qty`/`limit_price`/`contract_id`/`convergence_target`/`time_exit_date`/`instruction_id`/`source_decision_ref`; `due_date` = entry-window close), and create the `[Claude] Confirm order` event per the staging steps above. The registry row is what makes the entry a durable, daily-re-crafted persist-and-wait order whose earmarked cash §13 reserves until it fills or is terminally resolved. No calendar thesis event, no human paste.
   - **If the thesis must wait for future data** (a Day-0 close not yet in; a Strategy C pre-catalyst window): enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type: thesis-construction; due_date = earliest-doable date; self-contained `context`; `conservative_default` = decline/skip). D2 drains it on its due_date.
   - For Strategy A candidates that should queue rather than proceed: update Watchlist.md A-queue section with ticker, date-added, reason summary, resolution-trigger ("next M1 with A router ACTIVATE").

3. WATCHLIST UPDATES. For each add/remove/demote flagged:
   - Apply the change directly to Watchlist.md (creating it if absent — first line `# Watchlist`, sections per strategy as needed).
   - Per add: ticker, date-added, source-Daily-date, reason summary, resolution-trigger.
   - Per remove: confirm resolution event before removal; if uncertain, leave on list and append a status note.

4. ROUTER REVIEWS RECOMMENDED. For each router-review flag:
   - Confirm the threshold for inter-monthly review per Strategy.md (high bar; only material regime shifts qualify). If the threshold is not met, record the second-look decision via `events.decision_log` (`CALL ops.sp_log_decision(...)`) and stop.
   - If confirmed: perform the router review **in-session** (Claude-only analysis) — assess the Daily.md development against `state.current_regime` (BigQuery) and Strategy.md activation rules for the affected strategy; if the state changes, write the new activation state to `events.regime_events` (scope `STRATEGY_ACTIVATION`) and write an `events.decision_log` entry (Operating_Protocols §15). No calendar event.

5. STRATEGY TERMINATIONS. For each strategy flagged by D1's per-strategy kill-trigger sweep (or by a drained foundation-change assessment with a "terminate" verdict, or an Orchestrator m2m-termination TERMINATE verdict):
   - **DRAWDOWN termination (immediate, mechanical) / foundation-terminate / m2m-terminate:** execute the termination per Experiment_Parameters.md "Strategy termination and capital redistribution" — stage exit orders to close ALL the strategy's open positions (connector-crafted, each with a `[Claude] Confirm order` event; MARKET or marketable-limit for assured exit), mark the strategy **terminated** via an `events.regime_events` (scope `STRATEGY_ACTIVATION`) row (active→terminated; new entries blocked), and once the closes reconcile (D2 Step 0), perform the **deterministic redistribution**: fill any pending-newcomer strategies to their $2,000 probe-stake floor (FIFO, oldest first), then split the remainder equally among active survivors; reconcile the per-strategy allocations in the events-side state (`events.position_events` / `analytics.strategy_nav`) and write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording the termination post-mortem + per-survivor redistribution amounts + any newcomer fills. The drawdown trigger is rigid — do not wait on any review.
   - **RUNAWAY-SUCCESS flag:** do NOT terminate. Enqueue a `PENDING_REVIEW` entry (`INSERT INTO events.queue_events`, queue='PENDING_REVIEW'; review_type m2m-termination; the strategy; trigger_context = "runaway-success — deployed TWR doubled pre-gate; rule out reward-function exploitation / hidden tail risk per Experiment_Parameters.md kill-trigger #3"; attacker_due_date = next trading day; orchestrator_due_date = +1 trading day; status pending). The Attacker/Orchestrator routines adjudicate terminate-vs-continue and, on TERMINATE, execute the same termination + redistribution inline.

DEFERRAL DISCIPLINE: if a decision genuinely cannot be resolved this routine, specify (a) the trigger date and information source that will resolve it, and (b) the conservative-default fallback (skip / decline / exit). Deferrals do not chain. Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; due_date = the resolution date) so D2 drains it then — do not create a calendar event for analysis.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md (default America/Denver if silent). Set per-event notification to fire at event-time.

CHAT OUTPUT (per chat output discipline):
- Order(s) to execute as crafted instructions (tap-to-confirm deep link + `SIDE QTY TICKER TYPE LIMIT TIF` summary), grouped by execution day if more than one. Use "no order" if no exits staged. If Step 0 reconciled fills, state it in one line.
- One-line acknowledgment of writes and calendar events created (e.g., "events.decision_log + events.position_events written, Watchlist.md updated. 1 order instruction crafted, 1 calendar event scheduled.").

If no orders, no file changes, no events: "No actions required."
```

---

## D3. Calendar Hygiene — regular routine

```
Read access scope: Calendar Hygiene. Read the spec/cadence `.md` files + BigQuery state (`state.open_queue`, `state.current_positions`) as needed. (The Decision_Log/queue archives are retired per §15 — query `events.decision_log` / `events.queue_events` if historical context is needed.)

Reconcile Google Calendar against current state, and keep the `PENDING_ANALYSIS` queue (`events.queue_events` / `state.open_queue`) healthy. Recurring cadence work (D1, D2, …, A3) runs as routines; Claude-only analysis runs in-session or via the `PENDING_ANALYSIS` queue. The calendar holds **only `[Claude] Confirm order` events** — the sole human action.

DATE ANCHOR: "Today" comes from **`state.trading_day_today`** (`SELECT today, is_trading_day, last_trading_day, next_trading_day FROM state.trading_day_today`) — the single authoritative America/Denver trading-day source (holiday/weekend-aware). Do NOT use the assistant-context `currentDate` field (UTC-based; during evening MT it has already rolled to the next calendar day — using it as "today" mis-classified a same-day order-confirmation event as order-day-passed and deleted it, 2026-05-27 evening MT on the META convergence exit), do NOT compute the date with local Bash (`date`), and do NOT infer it from file timestamps (Decision_Log entry headers, "Last updated" lines — may be forward-dated/templated/recovery-artifact). If `state.trading_day_today` ever conflicts with `currentDate` or a file timestamp, trust `state.trading_day_today` and flag the conflict in chat output.

QUEUE HYGIENE (BigQuery — the `.md` queue-archive sweep is RETIRED per §15). The queues are `events.queue_events`; `state.open_queue` already surfaces only actionable items (latest status per item — terminal `complete`/`superseded` entries are filtered out automatically, so there is no physical sweep). Spot-check: confirm any item D2 or the Adversarial routines marked terminal this cycle has its terminal-status row in `events.queue_events` (so it drops out of `state.open_queue`), and flag any `state.open_queue` item whose `due_date` is past but still actionable (a missed drain).

Walk all `[Claude]` events in the next 90 days. The calendar should contain **only `[Claude] Confirm order` events**:
- If any legacy analysis event is still present (thesis construction, re-screen, research-deferral checkpoint, foundation-change assessment, constraint-relaxation review, router review, pulse-check / time-exit / convergence check), it is OBSOLETE under the in-session/queue model: convert it to a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) with an appropriate `due_date` + self-contained `context` (or, for pulse / time-exit / convergence checks, simply drop it — D1's daily mechanical exit sweep covers those), then delete the calendar event.
- DELETE a confirm-order event only when its order day has passed AND the order has filled or been cancelled per Step 0 reconciliation (`get_account_trades` / `get_account_orders`).
- DO NOT delete a confirm-order event solely because its datetime is past and unconfirmed — a past unconfirmed order is a MISSED confirmation that may still be actionable. First verify via the connector whether it actually filled (`get_account_trades`); if it did NOT fill, this is a hard-stop-grade escalation (chat is unmonitored, so flagging in chat is not enough): `CALL ops.sp_raise_alert('critical','D3','missed_confirmation', '<ticker SIDE QTY — confirm event <when> passed unconfirmed and unfilled>', '<JSON: item_key, instruction_id, event_time, connector evidence>')` AND create a `[Claude] ATTENTION — missed order confirmation <ticker>` calendar event. Then keep the staged-order registry row `pending` and re-craft per the persist-and-wait policy if the window is still open (so the order is re-surfaced), or set it terminal `expired` + log the missed-entry decision if the window has closed.
- Confirm each confirm-order event's description carries a valid deep link + `SIDE QTY TICKER TYPE LIMIT TIF` summary + instruction `id`, that a matching live instruction exists in `get_order_instructions` (re-craft + repair if missing), and that the notification fires at event-time.

Walk staged orders from **`state.open_orders`** (the durable staged-order registry, Operating_Protocols.md §11 — the authoritative list of what is meant to be resting, since under DAY-only the live endpoints are empty between sessions) and open positions from `state.current_positions`, cross-checked against the connector (`get_account_positions`, `get_account_orders`, `get_order_instructions`):
- Confirm every still-`pending` `state.open_orders` row (entry or exit) has a corresponding order-confirmation event at 07:00 MT pre-market on the order day (if the order day is still in the future) AND a live crafted instruction in `get_order_instructions` matching its `payload.instruction_id`. If the order day is still future and the instruction is missing, re-craft it (`create_order_instruction`) and repair the event. If the order day is today and market is still open, create/repair the event immediately. If the order day is past and the order was Day duration (now the only duration Claude crafts — Operating_Protocols.md §11), it either filled or expired — confirm via Step 0 reconciliation / `get_account_trades`; flag if not yet reconciled (if it expired unfilled but the thesis still wants the entry/exit, it is re-crafted as a fresh DAY order per the persist-and-wait re-craft step below).
- Garbage-collect stale crafted instructions: any `get_order_instructions` entry whose order day has passed unconfirmed, or whose position is already closed/opened per reconciliation, is cleared with `delete_order_instruction`.
- Daily re-craft of persist-and-wait orders (DAY-only policy, Operating_Protocols.md §11; primary path is the D2 Step 0 staged-order registry reconciliation — D3 is the calendar-side backstop): a Claude-crafted DAY order does not rest overnight — it fills or expires at session close — so an order meant to persist is kept alive by re-crafting it fresh each session. For each still-`pending` `state.open_orders` row whose prior DAY order expired unfilled but whose window is still open (`entry_window_close >= today` / exit still required), re-craft a new DAY instruction for the current session: re-pull `get_price_snapshot`, re-set the limit to the live market (or hold the disciplined non-chasing limit if the thesis dictates a specific rest level), `create_order_instruction`, write the updated `ORDER_STAGED` `pending` row (new `payload.instruction_id`), and create/repair the 07:00 confirm event. A row whose window has closed unfilled is set terminal `expired` + a missed-order decision logged (do not leave it `pending`). Any legacy or operator-placed GTC still working in `get_account_orders` that is drifted far from the market or past its intended window is flagged for delete/cancel + re-craft to a DAY order rather than left to drift indefinitely.
- Queue hygiene (`state.open_queue` / `events.queue_events`): confirm every open position flagged for research-deferral has a `queue_events` entry (analysis_type: research-deferral-checkpoint) with its resolution `due_date` + `conservative_default`; flag any `state.open_queue` item whose `due_date` is past but still actionable (D2 should have drained it — surface as a missed analysis).
- GO-WITHOUT-ORDER self-check (added 2026-06-24, RUNBOOK §25 D3 — closes the staging-completeness gap the registry-centric checks above structurally miss). The reconciliations above all walk FROM `state.open_orders`/the connector outward, so a GO that `ops.sp_log_decision` wrote atomically but whose `ORDER_STAGED` row was never written (the session died mid-step) is invisible. Anchor on the decision instead: `SELECT * FROM state.go_without_order` (`bigquery/18_stack_review_fixes.sql` — GO decisions in the last ~36h with no matching staged-order row, by `source_decision_ref`/ticker+strategy, AND no fill). For each row, ADJUDICATE (a GO can be analytical or deliberately deferred to a future window — those are fine): if it is a genuine actionable order that should have produced a staged-order/instruction/confirm-event triple and did not, `CALL ops.sp_raise_alert_once('warning','D3','go_without_order','<ticker/strategy — GO logged <entry_id> but no staged order/fill>', '<JSON: entry_id, ticker, strategy>')` and re-stage it (craft the order + `ORDER_STAGED` row + confirm event) or, if the window has closed, log the missed-entry decision. A GO that legitimately maps to no order (analysis-only, or a future-dated deferral with its own queue entry) is left alone.

Time zone America/Denver unless Experiment_Parameters.md specifies otherwise.

CHAT OUTPUT: one-line summary of calendar + queue reconciliation (e.g., "1 legacy thesis event migrated to queue + deleted; 3 confirm-order events verified; state.open_queue clean (no past-due actionable items).").
```

---

# WEEKLY (Sunday or Monday before market week)

W1, W2, W3 are deep-research routines run in parallel; W4 (action conversion) runs after all three are saved; W5 (factbase & analytics consolidation) runs alongside or after W4.

## W1. Catalyst Calendar (Strategies A and C) — deep research

```
Read access scope: Weekly cadence. Query `events.decision_log` (+ `analytics.find_precedents()`) bounded to the recent operationally-relevant window — all history, queryable, no live/archive split (§15). Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction. **Strategy A queue is in Watchlist.md** — relevant for Strategy A shortlisting.

Read Strategy.md (Strategy A and Strategy C sections for entry criteria, instrument eligibility, qualifying-event definitions), Experiment_Parameters.md, Watchlist.md, Operating_Protocols.md (positions from `state.current_positions`, decisions from `events.decision_log`).

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior `events.decision_log` NO-GO entry.

Produce a catalyst calendar across the Strategy A universe (6-month window) and the Strategy C universe (45-day window). Write the complete content directly to `Weekly_Catalyst_Calendar.md` (overwrite; first line = current ISO week in YYYY-WW format).

PART 1 — Two calendars.

A. Strategy A universe (6-month window). All US-listed equities with market cap ≥ $2B and 30-day ADV ≥ $10M with a scheduled catalyst in the next 6 months. Catalyst types: earnings releases, product launches, restructuring events, analyst days, regulatory decisions, other structural narrative markers. Per entry: ticker, name, catalyst type, date (confirmed / estimated / tentative), source.

B. Strategy C universe (45-day window). US-listed companies with qualifying events in the next 45 days — C's types only: earnings (from company IR), FDA PDUFA (from FDA calendar or company disclosure), FOMC (from Fed calendar). Per entry: ticker or event, name, event type, date, source.

Two tables. No interpretation in PART 1.

PART 2 — Ranked shortlists. The downstream W4 routine reads this PART 2 verbatim and enqueues thesis-construction entries to the `PENDING_ANALYSIS` queue (`events.queue_events`) for ranked shortlist names (D2 runs them), so make rankings and date specifics explicit.

Strategy A preliminary shortlist of 30–50 candidates where preliminary narrative synthesis suggests potential misalignment between consensus and what public documents (recent earnings transcripts, 10-Q/10-K filings, sector context, policy context) support. Cast deliberately broad. Per candidate: (a) direction of hypothesized mispricing, (b) specific supporting public documents, (c) catalyst date, (d) overlap with open A positions or recent watchlist archives, (e) priority tier (top-10 / 11-20 / rest) based on conviction-strength of the narrative misalignment.

Strategy C preliminary shortlist of 10–15 event candidates where preliminary synthesis suggests options-market implied view diverges from what public documents support. Per candidate: (a) direction of hypothesized divergence, (b) supporting public documents, (c) event date, (d) whether current C portfolio size supports an executable defined-risk structure at 2% sizing (flag deferrals), (e) overlap with open A positions (A and C cannot hold simultaneously), (f) priority tier (top-5 / rest).

Shortlists only. Full thesis construction per Strategy.md happens in separate sessions scheduled by W4.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Weekly_Catalyst_Calendar.md`. First line is the YYYY-WW marker. Chat output: one-line acknowledgment that the file was written.
```

---

## W2. Post-Event Screen (Strategy B) — deep research

```
Read access scope: Weekly cadence. Query `events.decision_log` (+ `analytics.find_precedents()`) bounded to the recent operationally-relevant window — all history, queryable, no live/archive split (§15). Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction.

Read Strategy.md (Strategy B section for entry criteria, instrument eligibility — A and B cannot hold the same name simultaneously), Experiment_Parameters.md, B_Sub_Pattern_Taxonomy.md, Operating_Protocols.md (positions from `state.current_positions`, decisions from `events.decision_log`).

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior `events.decision_log` NO-GO entry.

Produce a post-event screen for Strategy B candidates. Write the complete content directly to `Weekly_Post_Event_Screen.md` (overwrite; first line = current ISO week in YYYY-WW format).

PART 1 — All US-listed equities with market cap ≥ $2B, 30-day ADV ≥ $10M, experiencing a close-to-close price move of ≥5% in either direction on any day in the prior 10 trading days, where the move was attributable to a public event. Event types: earnings, FDA decisions, guidance updates, regulatory actions, material corporate developments (M&A, management), analyst actions with material price impact. Per entry: ticker, name, event date, event type, move magnitude and direction, source. Sort by event date (most recent first).

PART 2 — Ranked shortlist. The downstream W4 routine reads this PART 2 verbatim and enqueues thesis-construction entries to the `PENDING_ANALYSIS` queue (`events.queue_events`) for the ranked shortlist (D2 runs them), so rank explicitly and surface days-remaining-in-window per candidate.

Evaluate each entry for possible over- or under-sized reaction relative to fundamental implications. Ground in: event details, fundamentals from recent filings, comparable historical reactions to similar events at similar companies (retrieved, not recalled), information vs. sentiment distinction. Default assumption: market reaction is correct.

Rank a shortlist of up to 15 candidates. Per candidate: (a) direction and magnitude of hypothesized mispricing, (b) supporting public information, (c) convergence indicators to watch, (d) days remaining in the 10-trading-day entry window, (e) priority tier (top-5 / rest).

Exclude any name with an open Strategy A position.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Weekly_Post_Event_Screen.md`. First line is the YYYY-WW marker. Chat output: one-line acknowledgment that the file was written.
```

---

## W3. Open-Position Deep-Dive (Strategies A, B, C, E) — deep research

```
Read access scope: Weekly cadence. Query `events.decision_log` (+ `analytics.find_precedents()`) bounded to the recent operationally-relevant window — all history, queryable, no live/archive split (§15).

Read Strategy.md, Experiment_Parameters.md, Operating_Protocols.md (positions from `state.current_positions`, decisions from `events.decision_log`).

For each currently-open position in Strategies A, B, C, and E (not D — D gets a monthly deep-dive in M3), produce thesis-status research. Write the complete content directly to `Weekly_Position_Deep_Dive.md` (overwrite; first line = current ISO week in YYYY-WW format).

Per position, cover:

1. Current thesis status. Original thesis from entry record. Does it still hold after the prior week's developments? Has narrative drift occurred that daily headline scans would have missed?

2. Competitive landscape. Material moves by competitors or sector peers in the prior week affecting the thesis.

3. Fundamental developments. New filings, guidance updates, analyst actions, rating changes, sell-side commentary accumulated in the prior week.

4. Sector and macro context. Broader environment shifts affecting the thesis mechanics (e.g., for C: implied volatility regime changes; for A: shifts in how similar catalysts are being priced).

5. Thesis-invalidation signals. Has cumulative evidence moved the position closer to any invalidation criterion in the entry record?

6. Time-to-thesis-resolution. On track for the expected resolution window? Flag positions approaching time-based exits (A: 12-month hard stop; B: 60-day stale; C: option expiration; E: 6-month stale).

Per position: explicit recommendation (hold / close on thesis completion / close on thesis invalidation / further research). The downstream W4 routine reads these recommendations and stages exits for "close" calls and schedules research-deferral events for "further research" calls, so each recommendation must cite the specific invalidation criterion (for close calls) or the specific information gap (for further research calls).

If any position shows material thesis invalidation, set an "IMMEDIATE-ACTION" flag at the top of the file content so W4's read picks it up first.

OUTPUT: write the complete content directly to `Weekly_Position_Deep_Dive.md`. First line is the YYYY-WW marker. Chat output: one-line acknowledgment that the file was written, plus the IMMEDIATE-ACTION flag (if any) so the human sees it before W4 fires.
```

---

## W4. Weekly Action Conversion — regular routine

Runs after W1, W2, W3 are all saved. Converts ranked shortlists and per-position recommendations into orders / live-file edits / calendar events.

```
Read access scope: Weekly cadence. Query `events.decision_log` (+ `analytics.find_precedents()`) bounded to the recent operationally-relevant window — all history, queryable, no live/archive split (§15). Read `Strategy.md`, `Experiment_Parameters.md`, `Operating_Protocols.md`, `Watchlist.md`, `B_Sub_Pattern_Taxonomy.md` as relevant (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

Read the just-saved weekly research files:
- `Weekly_Catalyst_Calendar.md` (W1 — Strategy A and C shortlists)
- `Weekly_Post_Event_Screen.md` (W2 — Strategy B shortlist)
- `Weekly_Position_Deep_Dive.md` (W3 — per-position hold/close/research recommendations + immediate-action flag)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. EXITS FROM W3 — for each position with W3 recommendation "close on thesis completion" or "close on thesis invalidation" or marked with the immediate-action flag:
   - Confirm the cited invalidation criterion or completion condition is in fact met by reviewing the position's entry record (`events.decision_log` / `state.current_positions` / `events.position_events`) and Strategy.md exit rules. Second-look discipline: if on review the criterion is NOT met, do not stage the exit; record the second-look decision via a brief `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) and continue.
   - If confirmed: craft the exit order via the IBKR connector per D2 staging rules (resolve `contract_id`; `get_price_snapshot` → marketable limit, or MARKET when assured exit is the objective; **always DAY, never GTC** (a persist exit is re-crafted DAY each session, not rested as GTC — Operating_Protocols.md §11); `create_order_instruction` → `{id, url}`; options fall back to a manual text block).
   - Write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording: triggering condition (thesis-completion or invalidation criterion), conviction-calibration notes, timing relative to time-based exit windows.
   - Mark the position exit-pending with an `events.position_events` row carrying the staged order details and the crafted instruction `id` (there is no Portfolio_Ledger.md to update); also write the `pending` `ORDER_STAGED` row to `state.open_orders` per the D2 staging steps.
   - Schedule "[Claude] Confirm order — <ticker> SELL" for 07:00 MT pre-market on order day. Description: the `SIDE QTY TICKER TYPE LIMIT TIF` summary, the tap-to-confirm deep link (`url`), the instruction `id`, and "Tap the link, review the pre-filled order in IBKR, confirm at or after market open." (Options / other non-craftable exit: no `url` — carry the explicitly-labeled manual-entry text order block in place of the deep link.) No fill-capture event — the fill reconciles via D2 Step 0.

(Thesis construction and research deferrals are no longer scheduled as human-pasted calendar events. W4 enqueues them to the `PENDING_ANALYSIS` queue (`events.queue_events`); the daily D2 routine drains and runs them in-session, each as an isolated sub-task for fresh context. This keeps W4 light at high fan-out and incurs at most ~1 day latency — negligible against B's 10-day window.)

B. RESEARCH DEFERRALS FROM W3 — for each position with recommendation "further research":
   - Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`): analysis_type research-deferral-checkpoint; the position's ticker/strategy; due_date = the date the resolving information becomes available (next trading day if already available); context = the specific information gap from W3 + reference to Strategy.md exit rules + "resolve the gap and either stage an exit or continue holding"; conservative_default = exit the position if unresolved on due_date.

C. THESIS CONSTRUCTION FROM W2 (Strategy B) — for the W2 top-tier shortlist:
   - Enqueue one `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per top-tier candidate (no per-week cap, no overflow to Watchlist.md): analysis_type thesis-construction; strategy B; due_date per the **HARD CHECK** below; context = B context from W2 (event, mispricing direction, days remaining) + Strategy.md B criteria + B_Sub_Pattern_Taxonomy.md + Operating_Protocols.md; conservative_default = decline (no entry) if the entry window closes unresolved. Order by days-remaining-in-window (fewer first) so D2 prioritizes.
   - **HARD CHECK — due_date MUST be the earliest-doable date, NEVER a next-trading-day default (earliest-wins; §"In-session analysis and the Pending_Analysis.md queue").** W2 only shortlists names with an ALREADY-REALIZED ≥5% close-to-close move, so the Day-0 close is by definition already in for every W2 candidate → **due_date = today** (the W4 run date, America/Denver from `state.trading_day_today.today`), **even when today is a weekend/holiday** (analysis needs no live market; only the resulting order-confirmation event must land on a trading session). The ONLY legitimate future due_date in this section is the §E deconfliction case (1 trading day after an expected exit fill). Do NOT push due_date to "the next trading day", "the next D2 run", or "the Monday open" for cadence/load convenience — that is the forbidden "pushed later for load" pattern, and it needlessly force-declines near-expiry candidates whose entry window closes within a day or two (the 2026-06-21 W4 run mis-stamped all 8 B-theses to the next session, which would have auto-declined WIX whose window closed 6/22 had D2 not re-dated them). **Self-verify before the INSERTs (earliest-wins, not "always today"):** a future (after-today) due_date is legitimate ONLY when (a) §E deconfliction applies, or (b) the candidate's qualifying Day-0 close genuinely has not printed yet — in which case set due_date to the date that close lands (the earliest the analysis can actually run). Case (b) cannot occur for a realized-move W2 shortlist (the move, hence the Day-0 close, is by definition already in), so in practice every §C row is due today. What is forbidden is pushing due_date later for cadence/load convenience (next-trading-day / next-D2 / Monday-open defaulting); if a row would post a later due_date for any reason other than (a) or (b), correct it to the earliest-doable date before writing.

D. THESIS CONSTRUCTION FROM W1 (Strategy A and C) — for the W1 top-tier shortlists:
   - Strategy A top-tier (top-10): check `state.current_regime` / most-recent M1 A router. If DO-NOT-ACTIVATE → route to Watchlist.md A-queue (reason "router gate; queued for next M1 ACTIVATE"); no thesis. If ACTIVATE → enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per top-tier name (analysis_type thesis-construction; strategy A; due_date today; context from W1 + Strategy.md/Operating_Protocols.md refs; conservative_default decline), ordered by catalyst-date proximity. No per-week cap. (The DO-NOT-ACTIVATE gate is a strategy gate, not a load cap.)
   - Strategy C top-tier (top-5): enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per top-tier name (analysis_type thesis-construction; strategy C; due_date = today if catalyst < 14 days, else the pre-catalyst window date 7-10 days before the catalyst; context from W1; conservative_default decline). No per-week cap.

E. CROSS-STRATEGY DECONFLICTION — per Strategy.md simultaneous-holding constraints (A↔B and A↔C cannot hold the same name): if a ticker is both a W3 exit candidate and a W1/W2 new-entry candidate, set the new-entry queue entry's due_date to 1 trading day after the expected exit fill, and add a context note to verify (via the connector / `state.current_positions`) that the exit has filled before the thesis proceeds.

F. WATCHLIST UPDATES — apply A-queue additions from D, B-watch overflow from C, and any other updates surfaced.

DEFERRAL DISCIPLINE: if a recommendation cannot be acted on this routine, specify (a) trigger date and information source, (b) conservative-default fallback. Deferrals do not chain. Enqueue deferred analyses to the `PENDING_ANALYSIS` queue (`events.queue_events`; never the calendar).

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly only for `[Claude] Confirm order` events (exits staged in section A). Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- Exit order(s) as crafted instructions (tap-to-confirm deep link + `SIDE QTY TICKER TYPE LIMIT TIF` summary) grouped by execution day (or "no order").
- One-line acknowledgment of file edits, `PENDING_ANALYSIS` queue entries enqueued, and confirm-order events created.

If no orders, no file changes, no queue entries: "No actions required."
```

---

## W5. Factbase & Analytics Consolidation — regular routine

Runs weekly (Sunday, after W4). **Repurposed 2026-06-06 (BigQuery cutover §15):** the Decision_Log live/archive prune is RETIRED — `events.decision_log` holds everything, queryable + bounded, so there is nothing to archive. W5 is now **weekly knowledge + analytics consolidation**: extract new Strategy-B sub-patterns, capture protocol revisions, reconcile the Watchlist, refresh decision embeddings, and review the calibration + reconciliation health. Not deep research.

```
Read access scope: Weekly cadence with factbase WRITE permission. Query `events.decision_log` (entries added since the last W5 run, by `entry_date`/`event_ts`), `analytics.calibration_summary`, `analytics.account_reconciliation`, `state.current_positions`. Read the kept factbase/spec files `B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`.

FACTBASE MIRRORING — walk the new `events.decision_log` entries since the last W5 run and mirror durable signal into the kept factbase files.

Mirror to `Watchlist.md`:
- For any entry that adds a name to a strategy queue (e.g., "AAPL added to A-watchlist queue per router-gate-failure pattern"), ensure the name appears in Watchlist.md under the appropriate strategy section. Per-name fields: ticker, date-added, source-`events.decision_log`-entry-date, reason summary, resolution-trigger condition (e.g., "next M1 with A router ACTIVATE").
- For any entry that resolves a queue item (e.g., a future thesis-construction session that processes a queued name), ensure the resolved name is removed from Watchlist.md.
- Do NOT add Strategy B prior-NO-GO names to Watchlist.md — B operates on event-flow with fresh evaluation per "NO-GO records are context, not barriers". Sub-pattern factbase preserves the durable signal.
- Do NOT add Strategy D pending re-screens to Watchlist.md — calendar events are the canonical source.
- Note: Watchlist.md is also written by D2 / W4 / M4 (action-conversion routines) for in-cycle additions; W5 reconciles any drift between those writes and `events.decision_log` signal.

Mirror to `Operating_Protocols.md`:
- For any entry that introduces or revises an operational protocol (operating-model updates, commission-disregarded protocol, "NO-GO records are context, not barriers" rule, conviction-calibration ladder, deferral chaining rules, file-conventions/read-access-scope policy, decision-log lifecycle policy, etc.), ensure the canonical-current text is reflected in Operating_Protocols.md. Each protocol gets a section with: title, current canonical text, revision-history list (date + `events.decision_log` entry pointer + brief change description per revision).
- When revising an existing protocol section, replace the canonical text with the new revision and append the prior canonical to revision history.
- Do NOT mirror NO-GO entries, position entries, calendar-recon entries, or session-end-consolidation entries — those are not protocol entries.

ANALYTICS REVIEW (BigQuery) — the Decision_Log live/archive split + weekly prune is RETIRED (`events.decision_log` is queryable + bounded; nothing to archive). Instead:
- Confirm embedding coverage with `SELECT * FROM state.embedding_health` (expect `is_healthy = TRUE`, `missing_rows = error_rows = 0`); if anything is pending/errored, `CALL ops.sp_embed_pending()` to catch up so `find_precedents()` covers the week's new theses. (Routine writes via `ops.sp_log_decision` already embed inline; this is the weekly safety net.)
- Review `analytics.calibration_summary` (per-conviction-tier win-rate / avg realized P&L as closed trades accrue) and note progress toward the ≥30-closed-trade gate that activates the conviction model (bigquery/04_analytics.sql).
- Sanity-check `analytics.account_reconciliation` (events-side NAV totals) for drift; flag anything material in the W5 outcome.

MARKET-CALENDAR AUTO-EXTEND (keep `events.market_holidays` from silently expiring; cheap, idempotent — acts only when the horizon is short). Query `SELECT MAX(holiday_date) FROM events.market_holidays`. If that max is less than ~120 days ahead of today (America/Denver from `state.trading_day_today`), pull the next ~18 months of US market holidays from the **FMP connector** — `mcp__FMP__marketHours` endpoint `holidays-by-exchange`, exchange `NASDAQ`, `from_date` = today, `to_date` = +18 months — and MERGE into `events.market_holidays` (idempotent on `holiday_date`): `full_close = (isClosed = true)`; an early-close row (`adjCloseTime` present and not `isClosed`) → `full_close = FALSE`; `source = 'FMP-autoextend'`. FMP holiday NAMES can be imperfect (record as-is — only the date + close flag drive `state.market_calendar.is_trading_day`). This retires the manual yearly hand-MERGE (ops/RUNBOOK.md §8) and ensures `last_trading_day` never NULLs the freshness dead-man's switch (`bigquery/09_market_calendar.sql §auto-extend`). Best-effort: a connector hiccup here must not abort W5 — the seed already covers through 2029.

EXTRACT B sub-pattern instances. Query `events.decision_log` for Strategy-B criterion-4 NO-GO entries added since the last W5 run; for each:
1. Confirm it is a Strategy B criterion-4 NO-GO (narrative-misalignment/sub-pattern-driven) versus a mechanical NO-GO (criterion-1 mechanical, instrument-rule, router-gate). Mechanical NO-GOs go to (4) below.
2. Confirm sub-pattern classification language is present in the entry. If the entry describes a specific sub-pattern but does not name it explicitly, classify it now per the taxonomy below; if it neither describes nor names a sub-pattern, log a consistency-check anomaly.
3. For each new NO-GO entry in `events.decision_log`: scan for sub-pattern classification language. The Strategy B taxonomy as of this prompt's authoring includes (non-exhaustive list — extract additional categories as they appear in entries):
   - aggressive-sell-side-bull-ratification (NXPI/STX/BE/TWLO/CAT pattern)
   - structural-overhang-persistence (V/MDLZ pattern)
   - information-priced-via-pre-print-rally (SBUX/CBOE pattern)
   - negative-direction information-confirmed-by-cross-section (NOW/CHTR pattern)
   - in-window-binary-catalyst (STLA pattern)
   - valuation-reset-but-not-narrative-reset (TEAM pattern)
   - TEAM+V/MDLZ-hybrid (EL pattern)

   For any sub-pattern instance not yet recorded in B_Sub_Pattern_Taxonomy.md, append a brief instance entry there with: ticker, decision date, sub-pattern category, one-paragraph evidence summary including the decisive flaw type and key sell-side / price-action data points, comparable-name framing for thesis-construction routing, and a pointer back to the source `events.decision_log` row (entry id / date+title). The instance entry must contain enough detail that future thesis-construction sessions can route a new candidate against the sub-pattern WITHOUT needing to re-read the source NO-GO row.

   If B_Sub_Pattern_Taxonomy.md does not exist, create it. First line: `# Strategy B Criterion-4 NO-GO Sub-Pattern Taxonomy`. Organize by sub-pattern category with each instance under its category.

4. Mechanical-failure NO-GOs (criterion-1 mechanical, instrument-rule, router-gate failures): no sub-pattern extraction needed.

QUARTER ROLLOVER: RETIRED — the per-quarter Decision_Log archive files are gone (`events.decision_log` holds all history, queryable + bounded by `event_ts`), so there is no archive file to close out or start at quarter rollover.

ENTRIES THAT POINT BACKWARDS: when an `events.decision_log` entry contains "References" pointing to specific other entries, leave the references as-is (text-level). The structured fields (entry id / date+title) make lookup deterministic by query.

CONSISTENCY CHECK: cross-reference text mentioning specific dated entries (e.g. "per Decision_Log 2026-04-29 SBUX NO-GO") is fine — the reader can find the row by query. Do NOT mass-rewrite cross-references. (There is no live/archive split to keep consistent — `events.decision_log` holds everything.)

BIGQUERY / FILE EDITS:
- There is no `.md` log or archive to move entries between (retired) — the W5 outcome entry is written to `events.decision_log` via `CALL ops.sp_log_decision(...)`.
- Apply mirroring edits directly to the kept factbase files `B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`; confirm `state.embedding_health` is clean (catch up via `ops.sp_embed_pending()` if needed) per the Analytics Review above.

Write a brief `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) documenting the W5 cycle outcome: count of new entries processed, count of new sub-pattern instances extracted, factbase deltas if notable, any consistency-check anomalies surfaced.

If no entries qualify for sub-pattern extraction AND no factbase mirroring is needed: write the W5 outcome entry stating "No new entries to process and no factbase mirroring needed this cycle." and end without other file changes.

CHAT OUTPUT: one-line acknowledgment of factbase files edited (e.g., "events.decision_log W5-outcome written, B_Sub_Pattern_Taxonomy.md updated. 4 entries processed, 1 new B sub-pattern instance extracted.").
```

---

# MONTHLY (first trading day of month)

M1a, M1b, M2, M3 are deep-research routines; M4 (action conversion) runs after all are saved; M5 (forecast monitor) runs after M4.

(Renumbered 2026-06-06 to match the remote routine console: the former vacant "M2" slot was closed — E Pair Divergence Screen → M2, D Position Deep-Dive → M3, Monthly Action Conversion → M4. The AI Capabilities Research task once in the old "M2" slot remains at quarterly cadence as Q3. M5 (Deployed-TWR & Macro Forecast) was added 2026-06-06 as the monthly AI.FORECAST monitor — see its section after M4.)

## M1a. Strategy-Blind Regime Scoring — deep research

Schedule: Monthly, before M1b.

```
Read access scope: Monthly cadence. May query `events.regime_events` (scope `FUNDAMENTAL_AXIS`, prior months) for prior months' regime scores only (cross-month regime-trend cross-references) — `events.decision_log` holds all decision history, queryable, no live/archive split (§15). For the M1a template specification read the strategy-blind slice `strategy/09_regime_scoring_strategy_blind_monthly.md` (the `## Regime scoring (strategy-blind, monthly)` section) — load that + `01_shared_regime_vocabulary.md` ONLY; do NOT load `02_regime_router`, `00_preamble`, or any strategy slice (blinding is now a hard file boundary — see the "Strategy reading" table + `ops/RUNBOOK.md` §9). Also read Experiment_Parameters.md, AI_Trading_Foundation.md.

CRITICAL BLINDING REQUIREMENT: This routine must NOT read Strategy.md sections describing individual strategies (Strategy A through Strategy E sections), per-strategy activation rules, or any document referencing strategy letters or mechanisms. M1a is strategy-blind by design. The output produced here feeds M1b (a separate routine) which then applies per-strategy mapping. If you find yourself referencing "Strategy A" or any strategy letter / mechanism in your reasoning, stop and re-scope — that work belongs in M1b, not here.

Produce strategy-blind regime scoring for the prior calendar month. Two output files:

OUTPUT 1 — **write the structured macro indicators to `events.macro_series`** (one row per metric per release; the `Monthly_Macro_Data_*.md` audit file is RETIRED 2026-06-06 per Operating_Protocols §15 — do NOT recreate it). These are the audit trail of underlying inputs, NOT read by M1b. **Also append the month's new prints to `events.macro_fred`** — the deep-history macro substrate that M5's `AI.FORECAST` reads. **Pull via the FMP connector first** (`mcp__FMP__economics` `treasury-rates` + `economics-indicators`; map + YoY transforms in bigquery/07_fred_macro.sql §refresh), since the remote routine has FMP but may lack outbound `curl`; fall back to the FRED public CSV (no key) for any series FMP doesn't carry (notably `hy_oas`, and `vix` unless taken from an FMP/IBKR quote). Tag each row `source='FMP'` or `'FRED'`. This keeps the macro forecast current without depending on agent-side HTTP. `macro_fred` is a separate bulk/forecast substrate, distinct from this hand-curated `macro_series` audit table:

PART 1 — Prior calendar month coverage. If a section has no material items, state so.

Section 1 — Macro data releases from the prior calendar month
Per indicator: latest value, release date, prior release, trailing 3-month trend.
- CPI headline and core (YoY, MoM)
- PPI headline (YoY, MoM)
- Non-farm payrolls (latest, 3-month average, revisions)
- Unemployment rate (U-3)
- Retail sales (monthly change, ex-autos if relevant)
- GDP growth rate (if released; advance vs. prior estimate)

Section 2 — Federal Reserve and FOMC developments
- FOMC meeting: decision, statement text changes vs. previous, dot plot updates, press conference key points
- Fed speeches with market-moving content: speaker, date, venue, key quotes, observable reaction
- Fed funds futures implied path vs. most recent dot plot

Section 3 — Earnings aggregate status (S&P 500)
- If active season: % reported, aggregate EPS beat rate, sales beat rate, EPS surprise magnitude
- Change in forward 12-month S&P 500 EPS consensus over the prior month
- Sector-level aggregate divergences

Section 4 — Geopolitical events of material consequence
Global trade, oil/commodities, sovereign credit, or global risk sentiment. Per event: what happened, source, observable market reaction.

Section 5 — Policy environment
- Regulatory changes affecting broad sectors: agency, rule, effective date
- Tariff and trade developments
- Major legislation: bill name, status, market-relevant provisions

Section 6 — Cross-asset and risk-sentiment indicators (compensatory)
- VIX level and trailing trend
- Credit spreads (IG and HY OAS)
- USD index trend
- 10Y yield trend, yield curve shape

Close PART 1 with a 3–5 sentence summary of the month's character — strategy-blind language only.

OUTPUT 2 — **write the 5-axis regime scores to `events.regime_events` (scope `FUNDAMENTAL_AXIS`)**: one row per axis (growth_momentum / inflation_trend / policy_stance / risk_sentiment / shock_overlay) + the `_integrative` row, each with its categorical value + brief rationale (+ a `fallback_suppression` flag row when applicable). The `Monthly_Fundamental_RegimeScore.md` file is RETIRED 2026-06-06 (Operating_Protocols §15) — do NOT recreate it. This is M1b's sole regime input from M1a, which M1b reads from `state.current_regime` / `events.regime_events`:

First line: YYYY-MM marker.
Second line: fallback_suppression flag (true / false). If ≥2 of the 5 primary input categories (macro / Fed / earnings / geopolitical / policy — input 6 is compensatory and does not count) were unavailable per the fallback protocol, set true.

If fallback_suppression = true: write only the suppression rationale and exit. Do not score axes.

If fallback_suppression = false: score the 5 regime condition axes per Strategy.md's M1a template. Per axis: assigned value, brief rationale (max 3 sentences) citing which inputs drove the call. NO references to strategies, strategy letters, or per-strategy mechanisms. The 5 axes (per Strategy.md):
- growth_momentum: { accelerating | stable | decelerating }
- inflation_trend: { disinflating | stable | reaccelerating }
- policy_stance: { dovish | neutral | hawkish }
- risk_sentiment: { risk-on | neutral | stressed }
- shock_overlay: { none | latent | acute }

Followed by a 2–3 sentence integrative summary of the regime in strategy-blind terms (e.g., "decelerating growth + hawkish policy + neutral risk sentiment, no acute shock") — do not name strategies.

CHAT OUTPUT: one-line acknowledgment naming both files written. If fallback_suppression = true, additionally state "FALLBACK SUPPRESSION ACTIVE — M1b will not produce strategy mappings this month."
```

---

## M1b. Strategy Mapping and Activation Calls — regular routine

Schedule: Monthly, after M1a completes.

```
Read access scope: Monthly cadence. May query all of `events.decision_log` (no live/archive split, §15). Read Strategy.md (full document — strategy-mapping requires reading per-strategy activation rules), Experiment_Parameters.md, Watchlist.md, Operating_Protocols.md (positions from `state.current_positions`; regime from `state.current_regime`).

CRITICAL BLINDING REQUIREMENT — read scope: Read M1a's regime scores from `state.current_regime` / `events.regime_events` (scope `FUNDAMENTAL_AXIS`, latest month) for the regime input. Do NOT read `events.macro_series` or any other macro/policy/earnings source for this month — the underlying inputs M1a consumed are not part of M1b's input set by design. This preserves the architectural blinding between regime scoring and strategy mapping per Strategy.md "Two-routine blinded scoring." M1b's regime view is exactly M1a's `FUNDAMENTAL_AXIS` regime scores in `events.regime_events`, no more.

Read the latest `FUNDAMENTAL_AXIS` regime scores from `state.current_regime` / `events.regime_events`.

If the `fallback_suppression` flag is true: write Monthly_Fundamental.md with header noting fallback suppression for the month, set all 5 strategies to DO-NOT-ACTIVATE with reasoning "fallback suppression — sub-step M1a flagged ≥2 missing primary inputs," do NOT compute divergence flags, exit with chat acknowledgment.

If fallback_suppression = false: produce per-strategy activation calls and divergence flags. Write Monthly_Fundamental.md (overwrite; first line = current month YYYY-MM marker).

PART 1 — Echo M1a regime scoring (read from `state.current_regime` / `events.regime_events` FUNDAMENTAL_AXIS). Reproduce the 5 axis assignments with their brief rationale and the integrative summary. This is the ONLY regime context for downstream consumers and the divergence-review attacker.

PART 2 — Activation calls and divergence flags. The downstream M4 routine reads this PART 2 verbatim and acts on activation flips, divergence flags, and queue-drain triggers, so make calls explicit and structured.

1. Per-strategy activation calls. For each of A, B, C, D, E produce binary ACTIVATE / DO-NOT-ACTIVATE with reasoning per Strategy.md's immutable output format. Reasoning must reference M1a regime scoring (max 300 words per strategy). Compare against the prior month's call (from `events.regime_events` / `state.current_regime` `STRATEGY_ACTIVATION`, or prior-month Monthly_Fundamental.md) and explicitly tag each call as "FLIP TO ACTIVATE" / "FLIP TO DO-NOT-ACTIVATE" / "UNCHANGED" — flips drive M4 actions.

2. Reconciliation rules (apply mechanically AFTER step 1; per Strategy.md):
   - shock_overlay = acute → override ACTIVATE → DO-NOT-ACTIVATE for ANY strategy.
   - risk_sentiment = stressed → override ACTIVATE → DO-NOT-ACTIVATE for A or D.
   - growth_momentum = decelerating AND policy_stance = hawkish → override ACTIVATE → DO-NOT-ACTIVATE for A.
   - inflation_trend = reaccelerating AND policy_stance = hawkish → override ACTIVATE → DO-NOT-ACTIVATE for D.
   For each override applied: log the override with the originating regime axis values and the affected strategy, in a "Reconciliation overrides applied" subsection.

3. Divergence flags. For each strategy, compare final activation call (post-reconciliation) against current technical signal from `state.current_regime` / `events.regime_events` (scope `TECHNICAL_SIGNAL`) applied through the per-strategy technical rule. List divergences — each will be queued as a divergence-review by M4.

OUTPUT: write the complete content (PART 1 + PART 2) directly to Monthly_Fundamental.md. First line is the YYYY-MM marker. Chat output: one-line acknowledgment.
```

---

## M2. E Pair Divergence Screen — deep research

```
Read access scope: Monthly cadence. May query all of `events.decision_log` (no live/archive split, §15). In practice this routine operates on current open-book state and screening universe; deep-history queries are usually unnecessary unless explicitly needed.

Read Strategy.md (Strategy E section in full, including the "Explicit confrontation of disadvantage 2.6 (no access to private information)" subsection. Abandon any candidate pair where the divergence thesis requires expert network calls, private management access, conference-derived private context, buy-side intelligence, industry contacts, or channel checks), Experiment_Parameters.md, Operating_Protocols.md (positions from `state.current_positions`, decisions from `events.decision_log`).

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior `events.decision_log` NO-GO entry.

Produce an E pair divergence screen. Write the complete content directly to `Monthly_E_Pairs.md` (overwrite; first line = current month in YYYY-MM format).

PART 1 — Identify GICS industry groups (6-digit) in the US-listed large-cap universe with at least two companies meeting Strategy E's eligibility. Within each, identify pairs where:
- Both have market cap and 30-day ADV sufficient for E execution (flag pairs requiring ETF substitution at small portfolio sizes)
- Trailing 252-day daily-return correlation ≥ 0.5
- Both have reported earnings or filed 10-Q/10-K within the last 90 days

Per pair: provisional L and S (refined in PART 2), industry group, 252-day correlation, most recent earnings/filing dates, approximate short borrow rate per leg if estimable, individual-stock vs. ETF-substitution execution flag. Table organized by industry group.

PART 2 — Ranked shortlist. The downstream M4 routine reads this PART 2 verbatim and schedules pair-thesis-construction events, so rank explicitly with priority tier.

Per pair, preliminary narrative-divergence assessment strictly from public sources: 10-K/10-Q, 8-K, earnings transcripts, public analyst reports (full text), press releases, public news, public industry data. No expert networks, management access, conference-private context, buy-side intelligence, industry contacts, or channel checks. If analysis requires such sources, abandon and note why.

Identify pairs where narrative divergence has materially outpaced fundamental divergence, with specific predictions about what public events would cause reconvergence.

Rank shortlist of up to 10 pair candidates. Per pair:
(a) L (laggard, long) and S (leader, short) designation with public-document reasoning
(b) Narrative divergence thesis
(c) Reconvergence indicator(s): specific future public events or disclosures marking thesis playing out
(d) Estimated short borrow cost and whether it fits ≤ 15% of expected thesis return per Strategy.md
(e) Individual-stock vs. ETF substitution execution path
(f) Priority tier (top-3 / rest)

Exclude pairs where either leg is in the open E book.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Monthly_E_Pairs.md`. First line is the YYYY-MM marker. Chat output: one-line acknowledgment.
```

---

## M3. D Position Deep-Dive — deep research

```
Read access scope: Monthly cadence. May query all of `events.decision_log` (no live/archive split, §15). Open D positions' entry records are queryable in `events.decision_log` / `events.position_events`; deep-history queries are needed only if a multi-month-old context cross-reference is required.

Read Strategy.md (Strategy D section), Experiment_Parameters.md, Operating_Protocols.md (positions from `state.current_positions`, decisions from `events.decision_log`).

For each currently-open Strategy D position, produce thesis-status research. Write the complete content directly to `Monthly_D_Position_Deep_Dive.md` (overwrite; first line = current month in YYYY-MM format).

Per position, cover:

1. Current thesis status. Original multi-year structural thesis from entry record. Does it still hold after the prior month's developments?

2. Multi-year driver check. For each original thesis driver (product cycle phase, regulatory process stage, management strategic plan, thematic participation mechanism — whichever applied), has observable progress been made? Stalled? Reversed?

3. Fundamental developments. Material filings, earnings transcripts, analyst days, regulatory events, management changes, competitive moves in the prior month.

4. Invalidation criteria check. For each at-entry-defined invalidation criterion, has any been triggered?

5. Sector and theme context. Structural shifts in the secular theme or regulatory environment affecting the multi-year case.

6. Long-term tax treatment. Time to 12-month LTCG qualification; any thesis-completion signals suggesting LTCG timing coordination.

Per position: explicit recommendation (hold / close on thesis completion / close on thesis invalidation / further research). The downstream M4 routine reads these recommendations and stages exits for "close" calls and schedules research-deferral events for "further research" calls, so each recommendation must cite the specific invalidation criterion (for close calls) or the specific information gap (for further research calls).

If any position shows material thesis invalidation, set an "IMMEDIATE-ACTION" flag at the top of the file content so M4's read picks it up first.

OUTPUT: write the complete content directly to `Monthly_D_Position_Deep_Dive.md`. First line is the YYYY-MM marker. Chat output: one-line acknowledgment, plus the IMMEDIATE-ACTION flag (if any).
```

---

## M4. Monthly Action Conversion — regular routine

Runs after M1, M2, M3 are all saved.

```
Read access scope: Monthly cadence. May query all of `events.decision_log` (no live/archive split, §15). Read `Strategy.md`, `Experiment_Parameters.md`, `Operating_Protocols.md`, `Watchlist.md` as relevant (positions from `state.current_positions`, regime from `state.current_regime`, perf/kill from `perf.strategy_daily` / `perf.kill_flags`).

Read the just-saved monthly research files:
- `Monthly_Fundamental.md` (M1b — per-strategy ACTIVATE/DO-NOT-ACTIVATE calls + divergence flags; echoes M1a regime scoring in PART 1)
- `Monthly_E_Pairs.md` (M2 — pair shortlist with priority tier)
- `Monthly_D_Position_Deep_Dive.md` (M3 — per-position hold/close/research recommendations + immediate-action flag)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. ROUTER ACTIVATION FLIPS FROM M1b — for each strategy with FLIP TO ACTIVATE or FLIP TO DO-NOT-ACTIVATE:
   - Write the new per-strategy activation state to `events.regime_events` (scope `STRATEGY_ACTIVATION`); `state.current_regime` surfaces it (Operating_Protocols §15).
   - Write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording the flip: strategy, prior state, new state, M1 reasoning summary, date.
   - **A FLIP TO ACTIVATE for Strategy A — drain Watchlist.md A-queue.** For each name in the A queue with resolution-trigger "next M1 with A router ACTIVATE":
     * Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per queued name (analysis_type thesis-construction; strategy A; due_date today — the router ACTIVATE flip is the resolving event; context from the A-queue row + Strategy.md / Operating_Protocols.md; conservative_default decline), ordered by soonest catalyst date. No cap — drain the entire A-queue. D2 runs them.
     * Remove processed names from Watchlist.md A-queue (or mark "queued <date>").
   - **A FLIP TO DO-NOT-ACTIVATE for any strategy — halt new-position activity.** Supersede any pending `PENDING_ANALYSIS` thesis-construction entries for that strategy (insert a `superseded` status row to `events.queue_events`). Existing positions are unaffected (per Strategy.md exit rules — DO-NOT-ACTIVATE blocks new entries, not existing-position management).

B. DIVERGENCE FLAGS FROM M1b — for each divergence flag (fundamental call vs. technical signal):
   - Enqueue a `PENDING_REVIEW` entry (`INSERT INTO events.queue_events`, queue='PENDING_REVIEW') with review type `divergence-review`. Schema and field details per the ADVERSARIAL REVIEWS section of this document. Required fields: id (unique, e.g., `div-<strategy>-<YYYYMM>-<seq>`), review_type = divergence-review, strategy, prior_activation_state, m1b_artifact_path = Monthly_Fundamental.md, technical_reading (snapshot of the relevant `state.current_regime` / `events.regime_events` `TECHNICAL_SIGNAL` fields at queue time), attacker_due_date (next trading day), orchestrator_due_date (one trading day after attacker_due_date), status = pending.
   - The Adversarial Review Attacker and Orchestrator routines (defined below) will pick the entry up on their daily fire and produce the assessment + binding decision. M4 itself does not invoke any review prompt — it only enqueues.

C. EXITS FROM M3 — for each D position with M3 recommendation "close on thesis completion" or "close on thesis invalidation" or marked with the immediate-action flag:
   - Confirm the cited invalidation criterion or completion condition is in fact met. Second-look discipline applies. If on review the criterion is not met, record the second-look decision via an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) and continue.
   - If confirmed: craft the exit order via the IBKR connector per D2 staging rules. Note for D positions: check LTCG status — if within 30 days of 12-month qualification AND the invalidation is not catastrophic, stage the exit for the post-LTCG date instead by enqueuing a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type re-screen; strategy D; ticker; due_date = the LTCG date; context = "craft and stage the D exit on this date"; conservative_default exit) — do NOT craft a far-future instruction now; D2 crafts it on the due_date. If invalidation is catastrophic, exit immediately regardless of LTCG.
   - Write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) and the exit-pending lifecycle event to `events.position_events` with the crafted instruction `id` (plus the `pending` `ORDER_STAGED` row to `state.open_orders`). Schedule "[Claude] Confirm order — <ticker> SELL" for 07:00 MT pre-market on order day (description: the deep link + `SIDE QTY TICKER TYPE LIMIT TIF` summary + instruction `id`; options / non-craftable: the explicitly-labeled manual-entry text block in place of the deep link). No fill-capture event — the fill reconciles via D2 Step 0.

D. RESEARCH DEFERRALS FROM M3 — for each D position with recommendation "further research":
   - Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`): analysis_type research-deferral-checkpoint; strategy D; due_date = when the resolving info is available (next trading day if already available); context = information gap from M3 + Strategy.md D exit rules; conservative_default = exit the position if unresolved.

E. THESIS CONSTRUCTION FROM M2 (Strategy E) — for the M2 top-tier pair shortlist:
   - Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per top-tier pair (analysis_type thesis-construction; strategy E; ticker_or_pair = <L>/<S>; due_date = today unless the pair's entry must wait for a specific event; context = pair specifics from M2 [L, S, divergence thesis, reconvergence indicators, borrow cost estimate, execution path] + Strategy.md E criteria; conservative_default decline), ordered by reconvergence-indicator proximity. No per-month cap. D2 drains them.

F. CROSS-PROMPT DECONFLICTION — if any ticker appears as both an exit candidate (M3) and a new-entry candidate (M2 leg, or A-queue drain), respect simultaneous-holding constraints per Strategy.md: set the new-entry queue entry's due_date to after the expected exit fill, with a context note to verify the exit filled (connector / `state.current_positions`) before the thesis proceeds.

G. WATCHLIST UPDATES — apply any A-queue drains from A and any other updates surfaced.

H. KILL-TRIGGER & GATE EVALUATION (per active strategy; the slower triggers not covered by D1's daily sweep). **Source: `perf.kill_flags` (`gate_reached`, `m2m_underperf_review`) + the `perf.strategy_daily` indices (the engine row; the former ledger Performance block was just a mirror of it, retired).** Per Experiment_Parameters.md "Kill criteria (per-strategy)" + the success threshold:
   - **30-trade gate:** for each active strategy whose `perf.strategy_daily` row shows **closed_trades ≥ 30** and `gate_status = pre-gate`, read the maintained **deployed unit value** and **SGOV index** at the 30-trade mark; nominal excess = `deployed_unit_value ÷ sgov_index − 1`; apply the **post-tax** haircut (short-term cap-gains rate per Experiment_Parameters.md on the realized-gain portion) and **post-inflation** haircut (CPI over the first-trade-to-gate span) → **excess real return**. **If < 0% → terminate** (execute the close + deterministic redistribution per the D2 termination procedure / Experiment_Parameters.md "Strategy termination and capital redistribution"); write the gate post-mortem to `events.decision_log` (`CALL ops.sp_log_decision(...)`). **If ≥ 0% → mark the gate CLEARED** via an `events.regime_events` / `perf` state update + an `events.decision_log` entry (permission to continue; not a success verdict). Record the evaluation either way. (Strategy D's gate is expected never to be reached — low turnover; documented and fine.)
   - **Mark-to-market underperformance (#4):** for each strategy whose `perf.strategy_daily` row shows **`deployed_days` ≥ ~756 (≈ 36 months active)**, compute the rolling-12-month deployed-vs-SGOV gap from the `perf.strategy_daily` series — `(deployed_unit_value/sgov_index now) ÷ (deployed_unit_value/sgov_index ~12 months ago) − 1`; if it has trailed SGOV by **≥ 10 percentage points over any rolling 12-month window** (router-deactivation periods already excluded, since the indices only advance on deployed days), enqueue a `PENDING_REVIEW` entry (`INSERT INTO events.queue_events`, queue='PENDING_REVIEW'; review_type m2m-termination; the strategy; trigger_context = the measured 36-month-active + rolling-12-month gap; attacker_due_date next trading day; orchestrator_due_date +1; status pending). The Attacker/Orchestrator adjudicate; on TERMINATE they execute termination + redistribution inline. (At ~6 weeks of experiment age this cannot fire until ~2029 — a no-op until then.)

DEFERRAL DISCIPLINE: deferrals don't chain. Specify trigger and conservative-default fallback for any deferred decision. Enqueue deferred analyses to the `PENDING_ANALYSIS` queue (`events.queue_events`; never the calendar).

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly only for `[Claude] Confirm order` events (D exits in section C; strategy-termination closes in section H). Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- Exit order(s) as crafted instructions (tap-to-confirm deep link + `SIDE QTY TICKER TYPE LIMIT TIF` summary) grouped by execution day (or "no order").
- One-line acknowledgment of file edits, `PENDING_ANALYSIS` queue entries enqueued, and confirm-order events created.

If no orders, no file changes, no queue entries: "No actions required."
```

---

## M5. Deployed-TWR & Macro Forecast — regular routine

Runs monthly, after M4 (Monthly Action Conversion). The forward-looking monitoring overlay: a zero-shot `AI.FORECAST` (BigQuery built-in TimesFM — **no model to train or host**) over the deployed-TWR engine and, once it accrues enough history, the macro series. **Advisory / early-warning ONLY — it never stages an exit, termination, or activation change. Kill/gate triggers fire on REALISED values (`perf.kill_flags`), never on a forecast** (Experiment_Parameters.md kill-criteria discipline). Not deep research; pure BigQuery. DDL + query templates: `bigquery/06_forecast.sql`.

```
Read access scope: Monthly cadence, BigQuery read + write. Read `perf.strategy_daily` (the deployed-TWR series), `perf.kill_flags`, `events.macro_series`, and the prior run's `analytics.deployed_twr_forecast`. No web research or repo factbase reads required.

STEP 0 — ensure the store + early-warning view exist: idempotently run `CREATE TABLE IF NOT EXISTS analytics.deployed_twr_forecast` **and** `CREATE OR REPLACE VIEW analytics.twr_forecast_vs_actual` (bigquery/06_forecast.sql §store + §B). The view reads the table + `perf.strategy_daily`, so it is safe to (re)create even when the table is empty — STEP 1 needs it to exist on the next run.

STEP 1 — FORECAST-VS-ACTUAL early-warning (skip on the first-ever run). Query `analytics.twr_forecast_vs_actual` (the most-recent PRIOR run's `deployed_unit_value` forecast vs realised `perf.strategy_daily` for now-elapsed dates). Flag any strategy whose realised deployed-unit-value landed BELOW the prior forecast's `pi_lower` (downside surprise — possible regime shift / unmodeled deterioration) or above `pi_upper`. This is the calibration + early-warning signal.

STEP 2 — NEW deployed-TWR forecast. Run `AI.FORECAST` per active strategy over `perf.strategy_daily`, horizon 21 (~one trading month), `confidence_level => 0.9`, for two series: `deployed_unit_value` (drawdown / profitability path) and `excess_vs_sgov` (relative-perf / mark-to-market path). INSERT every forecast row into `analytics.deployed_twr_forecast` with `run_date = CURRENT_DATE('America/Denver')` (bigquery/06_forecast.sql §A — INSERT only rows whose `ai_forecast_status` is empty, so a newly-activated strategy with too few deployed days is skipped rather than written as NaN). (29 deployed days at 2026-06 is enough to run — AI.FORECAST handles the business-day spacing; intervals are wide now and tighten as history accrues.)

STEP 3 — KILL/GATE TRAJECTORY check (advisory). From the new forecast, note whether the central path or `pi_lower` of `deployed_unit_value` trends toward a kill threshold over the horizon — drawdown-kill `deployed_unit_value / peak_unit_value − 1 ≤ −0.50` (#1), or `excess_vs_sgov ≤ −0.10` (the mark-to-market #4 proxy, which only becomes a live trigger at `deployed_days ≥ 756`). A heads-up for the next M4 gate/kill review — NOT a trigger. Do NOT stage any exit or termination off the forecast.

STEP 4 — MACRO forecast (FRED-backed, un-gated). Run `AI.FORECAST` over `state.macro_fred_latest` (15 FRED-derived monthly regime metrics with deep history — 37–54 months each; St. Louis Fed public CSV, no API key; bigquery/07_fred_macro.sql): `data_col => 'value'`, `timestamp_col => 'ref_month'`, `id_cols => ['metric']`, horizon 3, `confidence_level => 0.8`. INSERT the rows whose `ai_forecast_status` is empty into `analytics.deployed_twr_forecast` (`series` = metric, `entity` = 'macro'). The ≥8-obs gate is satisfied for all seeded metrics — keep it only as a guard for any thin/new metric (skip + record `insufficient history (n=<k>)`). Advisory only; TimesFM zero-shot short-horizon central paths on policy-driven series (e.g. `fed_funds`) are noisy, so weight the trend + interval over the point. `macro_fred` is refreshed monthly by M1a appending the new prints (bigquery/07_fred_macro.sql §refresh); M5 forecasts off whatever is current. (The M1a-curated `events.macro_series` audit table is separate and not used here.)

STEP 5 — write a brief decision entry via **`CALL ops.sp_log_decision(...)`** (`entry_type='forecast-monitor'`; appends to `events.decision_log` + embeds in one call, per Operating_Protocols §15): per-strategy horizon-end forecast + interval for `deployed_unit_value` and `excess_vs_sgov`; any STEP 1 band breaches; the STEP 3 trajectory note; macro coverage (metrics forecasted vs. gated).

CHAT OUTPUT: one line — e.g. "M5 forecast: B duv(21d) 0.999 [0.97,1.02], excess −0.4% [−2.1%,+1.3%]; D duv 0.96 [0.92,1.00]; no prior-band breach; no kill-trajectory flag; macro 0/12 (insufficient history). Wrote 84 forecast rows + 1 decision_log entry."
```

---

# ADVERSARIAL REVIEWS (queue-driven, fires daily as needed)

Structured adversarial reviews — pre-mortem reviews, regime-router divergence reviews, mark-to-market termination reviews, scope-widening adjudications, and any future structured review the experiment design adds — are executed by a small set of generic routines that read entries from the `PENDING_REVIEW` queue (`state.open_queue` / `events.queue_events`) and produce reviews per artifact handoff. Triggering routines (M4, A3, kill-trigger handlers, etc.) enqueue entries (`INSERT INTO events.queue_events`); they never invoke a review prompt directly. (Capital redistribution after a strategy terminates is NOT an adversarial review — it is a **deterministic equal-split among surviving strategies** handled inline by the termination handler; see Experiment_Parameters.md "Strategy termination and capital redistribution.")

## Pending_Adversarial_Reviews.md — queue file schema

> **RETIRED-FILE WRITE REDIRECT (2026-06-06 cutover, Operating_Protocols.md §15).** `Pending_Adversarial_Reviews.md` no longer exists as a file. Every "write/append a `Pending_Adversarial_Reviews.md` entry" means `INSERT INTO events.queue_events` with `queue='PENDING_REVIEW'`; status transitions (`pending`→`attacker-complete`→`complete`/`superseded`) are new rows. The review-specific fields (`review_type`, `trigger_context`, `artifact_path`, `prior_state`, `attacker_due_date`, `orchestrator_due_date`, `cycle_number`, `attacker_output_path`, `orchestrator_output_path`, `notes`) live in the `payload` JSON; `item_key`←id, `status`←status. **Reads** come from `state.open_queue` / `state.open_queue_detail`. The attacker/orchestrator transcripts themselves go to `events.adversarial_reviews` (per §15). "Swept to `Archived_Adversarial_Reviews.md` by D3" now means the terminal-status row drops out of `state.open_queue` automatically.

The queue is `events.queue_events` (queue `PENDING_REVIEW`); `state.open_queue` / `state.open_queue_detail` is the live view. Each review is enqueued as a `queue_events` row; status transitions (`pending`→`attacker-complete`→`complete`/`superseded`) are new rows. Once an entry reaches a terminal `status` (`complete` or `superseded`), the terminal-status row drops it out of `state.open_queue` automatically — no `.md` queue, no archive file, no D3 sweep. `state.open_queue` therefore holds only actionable entries (`pending` / `attacker-complete`); a queue id absent from it has a terminal-status row in `events.queue_events`.

Each entry is a YAML-style block (the LOGICAL shape; fields map to `queue_events` columns per the redirect note above):

```
- id: <unique identifier, e.g., div-A-202605-1, premortem-strategyB-cycle3, m2m-D-202609, scopewiden-C-202611-1>
  review_type: <one of: pre-mortem | divergence-review | m2m-termination | scope-widening-adjudication>
  strategy: <A | B | C | D | E | router>
  trigger_context: <one paragraph of context — what fired the review and any specifics needed by the reviewer beyond the artifact_path>
  artifact_path: <relative repo path to the artifact under review — for divergence-review, this is Monthly_Fundamental.md (containing M1b output); for pre-mortem, the pre-mortem document; for m2m-termination, a per-trigger termination-context file produced by the kill-trigger handler; for scope-widening, the post-HYBRID fundamental update document>
  prior_state: <free-form text describing what state the system is in pending review — e.g., for divergence-review: "Strategy A activation state held at DO-NOT-ACTIVATE pending review"; for m2m-termination: "Strategy D continues trading pending review">
  attacker_due_date: <YYYY-MM-DD; the next trading day after queue creation, in the experiment's reference timezone per Experiment_Parameters.md>
  orchestrator_due_date: <YYYY-MM-DD; one trading day after attacker_due_date>
  status: <pending | attacker-complete | complete | superseded>
  attacker_output_path: <set by attacker routine when it completes; e.g., Adversarial_Review_<id>_attacker.md>
  orchestrator_output_path: <set by orchestrator routine; e.g., Adversarial_Review_<id>_orchestrator.md>
  cycle_number: <integer; 1 for first cycle of a given artifact, incremented per re-review after revision; n/a for non-cycling review types>
  notes: <free-form, optional — e.g., for cycle 5+ pre-mortem, the forcing-question answer; for revision-induced cycles, the prior cycle's id>
```

(There is no `.md` queue file; reads/writes go through `state.open_queue` / `events.queue_events` as above.)

## Adversarial Review Attacker — regular routine

Schedule: daily. The routine wakes, scans the queue, and exits if no entry matches its phase.

```
Read access scope — STRICT BLINDING: Read the review queue from `state.open_queue` / `state.open_queue_detail` (queue `PENDING_REVIEW`, to find and process the entry). Read the queue entry's artifact_path (the document under attack).

EXPLICITLY DO NOT READ for any review processed by this routine: `events.decision_log` (or any decision history), prior `events.adversarial_reviews` / `Adversarial_Review_*.md` files, broader sections of Strategy.md or Experiment_Parameters.md beyond the section directly under review, prior versions of the artifact, or any other repo file or BigQuery state. The artifact under review is required to be self-contained per Experiment_Parameters.md "Self-containment requirement for pre-mortem artifacts" (which generalizes to all adversarial-review artifacts). If you need information that is not in the artifact and not in the queue entry's trigger_context field, the artifact has failed self-containment and you flag this as a Tier 1 defect — do not search for the missing context.

This blinding is enforced by prompt discipline. Tool-call / query logs are auditable; reading any forbidden source is a discipline violation that will be caught at quarterly review. Compliance is critical to preserving the architectural separation between attacker and orchestrator routines under the routine architecture.

Read the review queue from `state.open_queue` (queue `PENDING_REVIEW`).

Find the next entry where attacker_due_date <= today AND status = pending. Process all matching entries this routine fire — each entry as an isolated sub-task (subagent) for fresh per-entry context where available, else inline sequentially with an explicit per-entry scope reset between artifacts (so per-entry read-scope discipline is preserved and prior in-fire artifacts do not bleed into a subsequent entry's output — particularly load-bearing for the Attacker routine's STRICT BLINDING, where each entry's blinding applies to its own artifact_path). If none: write chat output "No adversarial reviews due for attacker today." and exit.

If found, attack the artifact per the review_type's protocol from Experiment_Parameters.md and Strategy.md:

- pre-mortem: identify Tier 1 / Tier 2 / Tier 3 weaknesses (theater indicators, vague failure modes, unverifiable frequency declarations, post-hoc-reinterpretable activation thresholds). Verdict: SUFFICIENT / TIER 1 DEFECT — REVISION REQUIRED.
- divergence-review: produce strongest bear case against the M1b fundamental claim and argue for the technical call. Specific weaknesses in the fundamental reasoning. Verdict on whether fundamental claim should survive.
- m2m-termination: produce strongest case for terminating the strategy. Specific weaknesses in any "thesis-still-intact" reasoning visible in the artifact. Verdict on terminate vs continue.
- scope-widening-adjudication: attack whether the fundamental reasoning has adequately addressed the three required topics per Strategy.md Strategy C post-HYBRID adjudication mechanism. Verdict.

Write attack to Adversarial_Review_<id>_attacker.md (where <id> is the queue entry id) and to `events.adversarial_reviews` (attacker transcript). Format: header (id, review_type, date, cycle_number), verdict (one-line), specific weaknesses identified (numbered, each with anchor to artifact text), self-imposed scope confirmation ("I read only: <list of sources actually read>; I did not read: events.decision_log, prior reviews, broader docs"), reasoning section.

Update the queue entry: insert a `queue_events` row (same `item_key`) with attacker_output_path set in the payload and status = attacker-complete.

CHAT OUTPUT: one line per processed entry naming the entry id, review_type, and attacker verdict. If multiple entries were processed this fire, list each on its own line.
```

## Adversarial Review Orchestrator — regular routine

Schedule: daily (after Attacker routine). The routine wakes, scans the queue, and exits if no entry matches its phase.

```
Read access scope: Read the review queue from `state.open_queue` / `state.open_queue_detail` (queue `PENDING_REVIEW`), Strategy.md, Experiment_Parameters.md, AI_Trading_Foundation.md, and BigQuery state as needed (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log` — all history, queryable, no live/archive split, §15), the queue entry's artifact_path and attacker_output_path.

Read the review queue from `state.open_queue` (queue `PENDING_REVIEW`).

Find the next entry where status = attacker-complete AND orchestrator_due_date <= today. Process all matching entries this routine fire — each entry as an isolated sub-task (subagent) for fresh per-entry context where available, else inline sequentially with an explicit per-entry scope reset between artifacts (so per-entry read-scope discipline is preserved and prior in-fire artifacts do not bleed into a subsequent entry's output — particularly load-bearing for the Attacker routine's STRICT BLINDING, where each entry's blinding applies to its own artifact_path). If none: write chat output "No adversarial reviews due for orchestrator today." and exit.

If found, orchestrate per the review_type's protocol:

1. Read attacker_output_path. Read artifact_path.
2. Produce explicit independent assessment documenting:
   (a) For each weakness the attacker identified, validity assessment (valid Tier 1 / valid but Tier 2-3 / invalid) — for pre-mortem; for other types, equivalent grading per the type's protocol.
   (b) Theater in the attacker's output (generic-sounding objections without specific anchors).
   (c) Weaknesses the attacker missed.
   (d) Final verdict per review_type:
       - pre-mortem: SUFFICIENT or TIER 1 DEFECT — REVISION REQUIRED. If REVISION REQUIRED, identify whether to invoke the rev 15 forcing question and answer it in writing per Experiment_Parameters.md (a/b/c). For cycle 5+, justify continuation per the soft cap.
       - divergence-review: final activation state for the strategy (ACTIVATE / DO-NOT-ACTIVATE) with reasoning. Apply the default-on-ambiguity rule and the theater-check tiebreaker: if theater_check = CONVERGENT, default to DO-NOT-ACTIVATE regardless of the verdict.
       - m2m-termination: TERMINATE / CONTINUE with reasoning. Default-on-ambiguity = TERMINATE.
       - scope-widening-adjudication: re-widening AUTHORIZED / NOT AUTHORIZED with reasoning. Apply the four-screen test and the CONVERGENT-theater-check requirement per Strategy.md.
   (e) Theater-check flag: CONVERGENT / DIVERGENT / MIXED with specific rationale referencing concrete claims in the attacker output and the orchestrator's own assessment. The orchestrator self-certifies this flag — accepted-risk note: this is structurally weaker than a separate Theater Auditor routine; if empirical theater-check rates suggest under-detection of CONVERGENT framing, a separate auditor routine can be added in a future revision.

3. Write orchestrator output to Adversarial_Review_<id>_orchestrator.md and to `events.adversarial_reviews` (orchestrator transcript). Format: header (id, review_type, date, cycle_number), final verdict (one-line + binding decision), theater-check flag (one-line), reasoning sections per (a)-(d) above, action taken (if any).

4. Take resulting action:
   - divergence-review: write the binding activation state to `events.regime_events` (scope `STRATEGY_ACTIVATION`). If the verdict differs from the prior state, write the binding decision to `events.decision_log` via `CALL ops.sp_log_decision(...)` (Operating_Protocols §15).
   - m2m-termination with verdict TERMINATE: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording termination, mark the strategy terminated via an `events.regime_events` (scope `STRATEGY_ACTIVATION`) row, immediately move strategy portfolio value to SGOV (stage IBKR orders in chat output for the participant to execute), and **perform the deterministic capital redistribution inline** — split the terminated strategy's booked allocation equally among active surviving strategies, after first filling any pending newcomer strategies to their probe-stake floor (per Experiment_Parameters.md "Strategy termination and capital redistribution" + "New strategy funding"), reconciling the per-strategy allocations in the events-side state (`events.position_events` / `analytics.strategy_nav`).
   - m2m-termination with verdict CONTINUE: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording the review outcome, no portfolio action.
   - pre-mortem with verdict REVISION REQUIRED: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording the cycle outcome. Subsequent revision is performed by the participant or by a participant-triggered drafting session — orchestrator does not auto-revise the artifact. (Pre-mortem revision is itself an editorial action and is out of scope for an autonomous routine.)
   - pre-mortem with verdict SUFFICIENT: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`), no further action; the pre-mortem is unblocked for first-trade gating purposes.
   - scope-widening-adjudication with verdict AUTHORIZED: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`); downstream Strategy C handlers may re-widen per Strategy.md.
   - scope-widening-adjudication with verdict NOT AUTHORIZED: write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`); re-widening is blocked.

5. Update the queue entry: insert a `queue_events` row (same `item_key`) with orchestrator_output_path set in the payload and status = complete.

CHAT OUTPUT:
- Crafted order instructions (tap-to-confirm deep link + summary) if any were staged (otherwise omit).
- One line per processed entry naming the entry id, review_type, final verdict, theater-check flag, and action taken. If multiple entries were processed this fire, list each on its own line.
```

---

# QUARTERLY (first trading day of quarter)

Q1, Q2, Q3 are deep-research routines; Q4 (action conversion) runs after Q2 and Q3 are saved (Q1 has no actionable outputs and does not gate Q4).

## Q1. Regime Retrospective — deep research

```
Read access scope: Quarterly cadence. Query all of `events.decision_log` (no live/archive split, §15) plus `events.regime_events` and `events.adversarial_reviews` — this routine has explicit dependencies on prior-quarter router history and adversarial review records.

Read Strategy.md (shared regime vocabulary and regime router sections), Experiment_Parameters.md, Operating_Protocols.md (positions from `state.current_positions`; regime/router history from `state.current_regime` / `events.regime_events`; router history and adversarial review records for the prior quarter from `events.decision_log` / `events.adversarial_reviews`).

Produce a regime retrospective for the prior calendar quarter. Write the complete content directly to `Quarterly_Regime.md` (overwrite; first line = prior calendar quarter in YYYY-QN format).

PART 1 — Retrospective characterization of the prior calendar quarter. Seven dimensions:

1. SPY trend character
- Total return for the quarter, path description (steady / choppy / rolling tops or bottoms)
- 50-day / 200-day SMA relationship stability; any crosses
- Major intra-quarter drawdowns or rallies with dates

2. Volatility regime
- VIX range and average
- Realized S&P 500 volatility (annualized)
- Vol events (spikes above 25, compressions below 15, persistent elevations)

3. Yield curve trajectory
- 10Y and 2Y yields at quarter start and end; intra-quarter path
- Inversion state and any transitions
- Notable moves tied to Fed or macro events

4. Equity market breadth
- % S&P 500 above 200-day SMA at quarter start and end, trajectory
- Broad, narrow (mega-cap-led), or rotating participation
- Sector leadership and laggards with magnitudes

5. Dominant macro narrative
- One or two themes dominating market commentary
- Inflection points (data, Fed actions, geopolitical events) shifting the narrative
- Quarter-start vs. quarter-end narrative comparison

6. Earnings and fundamentals backdrop
- Aggregate beat rates and surprise magnitudes for earnings seasons within the quarter
- Change in forward S&P 500 EPS consensus
- Sector-level earnings divergences

7. Overall regime characterization (3–5 sentences)
Retrospective description: risk-on, risk-off, sector rotation, macro-driven, idiosyncratic, transitional, range-bound, trending. Specific about which descriptors apply and why.

PART 2 — Q1 produces no actionable outputs. This part is a backward-looking factbase consumed by the next experiment-restart router pre-mortem (mid-experiment immutability per Experiment_Parameters.md prevents inter-quarter router revision).

1. Router activation trace. For each of A, B, C, D, E, trace activation state changes during the quarter using `events.regime_events` (router/activation history) and `events.decision_log`. Table: strategy, activation periods, deactivation periods, disagreement reviews triggered and outcomes.

2. Consistency comparison. Per strategy, compare router classifications against PART 1 retrospective. Does the regime the router classified match the regime the retrospective describes? Focus on systematic disagreements (e.g., router said HEALTHY/UP during a quarter the retrospective calls "rolling distribution").

3. Diagnostic flags. Patterns of systematic router disagreement with reasonable-observer regime reads. Not mid-experiment revision triggers (immutability per Experiment_Parameters.md) — inputs to the next full router pre-mortem at experiment restart.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Quarterly_Regime.md`. First line is the YYYY-QN marker. Chat output: one-line acknowledgment.
```

---

## Q2. D Long-Horizon Candidates — deep research

```
Read access scope: Quarterly cadence. Query all of `events.decision_log` (no live/archive split, §15) — historical D NO-GO dispositions are queryable there and inform "NO-GO records are context, not barriers" application.

Read Strategy.md (Strategy D section in full: thesis requirements, entry criteria, concentration rules, sector concentration cap), Experiment_Parameters.md, Operating_Protocols.md (current D book state and concurrent-position count from `state.current_positions`; regime from `state.current_regime`; decisions from `events.decision_log`).

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior `events.decision_log` NO-GO entry.

Produce a D long-horizon candidate screen. Write the complete content directly to `Quarterly_D_Candidates.md` (overwrite; first line = current quarter just beginning in YYYY-QN format).

PART 1 — Identify candidates meeting D's eligibility: US-listed common equity (ADRs acceptable for large-cap foreign-domiciled), market cap ≥ $10B, 30-day ADV ≥ $20M. Within this universe, identify companies with plausible multi-year structural narrative thesis potential across (non-exhaustive, apply judgment):

- Product cycle stories with 12+ month multi-cycle roadmaps
- Regulatory or legal resolution processes in progress (antitrust, litigation, approval processes)
- Management execution stories (turnaround or strategic transformation under specific identified leadership)
- Secular thematic participation with specific mechanisms (not just theme exposure)
- Industry structural change with identified beneficiaries

Cast broadly — up to 50 candidates. Filtering in PART 2.

Per candidate: ticker, name, market cap, GICS sector and industry, preliminary thesis category, 1–2 sentence summary of why on the list, key public documents already suggesting the thesis (most recent 10-K, recent earnings transcripts, relevant analyst days or investor presentations). Table.

PART 2 — Ranked shortlist with readiness flags. The downstream Q4 routine reads this PART 2 verbatim and schedules D thesis-construction events for "ready now" candidates, so flag readiness explicitly per candidate.

Per candidate, deepen narrative synthesis against Strategy D's entry criteria.

1. Structural thesis articulation. Thesis with 12+ month expected realization timeline and specific multi-year drivers (not just theme exposure).

2. Evidence base. Confirm adequate public-document evidence across Strategy D's required inputs (last 8 quarters of earnings transcripts, last 2 annual reports, competitive/sector context, regulatory/policy context, technological/secular theme context as applicable).

3. Invalidation criteria. Observable pre-completion invalidation signals — specific, not price-action-based.

4. Concentration check. Compare against current D book: does adding this name push any GICS sector above 30% concentration? Note the implication.

5. Position-count check. Would adding this push D above the 10-concurrent-position hard cap? If so, flag that an existing D position would need to close first.

6. Momentum screen. Is the name rallying hard (specify magnitude) in the trailing 30 days? Flag for entry deferral per Strategy.md.

Rank shortlist of up to 10 candidates for full thesis construction. Per candidate:
- Thesis strength (ordinal rating, with reasoning)
- Specific catalysts or drivers
- Specific invalidation criteria
- Current sector concentration implication
- Readiness (ready now / deferred pending rally pause / blocked by concentration or position count)

Exclude names in the open D book. Note any shortlist addition that would require an existing D position to close first — do not recommend the close.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Quarterly_D_Candidates.md`. First line is the YYYY-QN marker. Chat output: one-line acknowledgment.
```

---

## Q3. AI Foundation Quarterly Delta — deep research

```
Read access scope: Quarterly cadence. Query all of `events.decision_log` (no live/archive split, §15) — prior-cycle Q3 outcomes and AI-foundation-change dispositions are queryable there.

Read AI_Trading_Foundation.md (Parts 1, 2, 3, 4 in full — pay particular attention to the Tier framework distinction between architectural / structural Tier 1 items vs empirical / measured Tier 2 items, and to Part 4 verification protocol), Strategy.md, Experiment_Parameters.md, Operating_Protocols.md (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

Frame research adversarially: look for evidence that contradicts or updates documented edges and disadvantages, not evidence that confirms them. Offsets self-reference bias (this task evaluates LLM claims while being executed by an LLM).

HF tool orientation. Read `HF_Resource_Catalog.md` once at session start for the authoritative HF tooling map. Apply the following operational rules during PART 1 research:
- Run Hugging Face `paper_search` on each of the 9 query batteries enumerated in `HF_Resource_Catalog.md` §6.1, scoped to the prior calendar quarter. Use `concise_only=true` and `results_limit=8`. For each battery, record any new papers from the prior quarter that bear on documented disadvantages or surface new failure modes — record arXiv IDs in the form `hf.co/papers/<id>`.
- For Section 3a benchmark results, iterate `hub_repo_search` over open-weights model authors (`meta-llama`, `Qwen`, `mistralai`, `deepseek-ai`, others) with `repo_types=["model"]` and read recent (prior-quarter) model cards for benchmark trajectory updates on benchmarks mapped per `AI_Trading_Foundation.md` §5.5 (cross-reference the inverse mapping in `HF_Resource_Catalog.md` §2).
- Do NOT use `space_search` for canonical Spaces — per `HF_Resource_Catalog.md` §8.1, semantic search misses popular Spaces. Use `hub_repo_search` with explicit `author` and `repo_types=["space"]` for known Space lookup.
- HF is silent on Anthropic/Claude. Section 1 (Claude model capability changes) is `web_search` / `web_fetch` only — query `anthropic.com`, `docs.anthropic.com`, Anthropic research blog, and Anthropic-tagged news. Do NOT attempt to find Claude data on HF.
- Do NOT pull data from any HF Space (none durable enough per §3) or any HF dataset (offline-only per §4). HF resources for this routine are: papers, model cards, leaderboards-as-references — nothing else.
- Combine HF and `web_search` / `Tavily` deliberately: HF for academic LLM research and open-weights model evidence; web_search for vendor announcements, regulatory developments, and analyst-bias literature (per `HF_Resource_Catalog.md` §1.11, HF is weak on the classical accounting/finance literature).
- Query `[HF Frontier-LLM Capture]` entries from `events.decision_log` covering the prior calendar quarter (all history queryable, no live/archive split). These are mid-quarter material findings that D1's light-touch daily HF check captured but did not act on. Treat them as required priors when running the §6.1 query batteries — verify each captured paper is incorporated into the relevant section, and check whether any has been superseded by newer work in the prior quarter.

Produce AI capabilities research for the prior calendar quarter (3 calendar months). Write the complete content directly to `Quarterly_AI_Foundation_Delta.md` (overwrite; first line = prior calendar quarter in YYYY-QN format).

Scope. Section 1 is scoped to Anthropic/Claude only — the workflow's decision-maker is Claude, so capability releases from other providers do not change what this workflow can do. Sections 2–6 stay broad because they describe the reference class (autonomous-AI trading performance baseline), the evidence base for architectural failure modes (which replicate more robustly when observed across model families), or the environment (market structure and regulation) regardless of which model the workflow uses. Non-Claude evidence in Sections 2, 3, 5 is filtered for transferability in PART 2 before triggering foundation-change assessment.

PART 1 — Prior calendar quarter coverage. Primary sources only (papers, arXiv preprints, company announcements, regulatory filings, reputable news citing primary sources). If a section is empty, state so.

Section 1 — Claude model capability changes
New releases, version updates, deprecations from Anthropic (Claude family only). Per item: name and version, release date, Anthropic capability claims (reasoning, tool use, long-context synthesis, calibration, math), independent benchmark results. Include deprecation notices and scheduled end-of-life dates for any Claude version currently in use or plausibly in use within the next review cycle.

Section 2 — AI trading performance research and reported results
New papers, arXiv preprints, hedge fund or prop firm disclosures, live-capital LLM trading arena updates, brokerage reports. Per item: methodology, models evaluated, results. Flag any item that evaluated a Claude model specifically.

Section 3 — LLM failure mode and bias research
New research on documented disadvantages and any newly-identified failure modes. Include replications. Per item: models evaluated. Flag items that evaluated a Claude model specifically or that claim architectural generality.

**Section 3a — Benchmark results bearing on Tier 2 disadvantages.** For each Tier 2 disadvantage with documented benchmark mapping per AI_Trading_Foundation.md §5.5 (the table in that section maps disadvantages to primary benchmarks), report any new benchmark results in the prior quarter that bear on the disadvantage. Per result: benchmark name and version, models evaluated, score and direction of change vs prior measurements, citation. Flag whether the result clears §5.5 Goodhart guardrails (≥3 sources, transferability, sustained, domain coverage) — single-source results are reported but flagged as not yet sufficient for reduction confirmation.

Section 4 — Market saturation and AI-driven market structure
AI adoption, retail AI use, AI share of trading volume, capital concentration through specific foundation models. Synchronized AI-driven market events. Regulator reports.

Section 5 — Adversarial content and manipulation risks
Prompt injection research, adversarial content targeting AI consumption, AI-generated content in financial documents. Per item: models evaluated where relevant.

Section 6 — Regulatory developments affecting AI in financial decision-making
New regulations, consultations, enforcement actions affecting AI-driven trading, robo-advisory, algorithmic decision-making.

Six sections, reverse chronological within each, citations inline.

PART 2 — Verification answers and per-strategy effects. The downstream Q4 routine reads this PART 2 verbatim and schedules per-strategy foundation-change assessment events per YES verdicts, so make YES/NO answers structured and per-strategy effects explicit.

Answer each AI_Trading_Foundation.md Part 4 verification question explicitly using PART 1 as evidence. Default bias: YES — err toward flagging change, err toward triggering per-strategy foundation-change assessment. The experiment accepts false-positive assessments to catch real changes.

Transferability filter for non-Claude evidence. For PART 1 findings drawn from models other than Claude (Sections 2, 3, 5), a finding triggers per-strategy foundation-change assessment only if at least one of the following is present: (a) replication on a Claude model, (b) architectural generality — the mechanism is a documented property of autoregressive LLMs broadly rather than a specific model's training artifact, or (c) evidence from an Anthropic-family model (prior Claude version). Non-Claude findings lacking transferability evidence are logged in the YES/NO answer and flagged as watch items for the next review cycle, but do not trigger foundation-change assessment on their own.

Verification questions (per AI_Trading_Foundation.md Part 4):
Q1 — Has any AI capability in Part 1 materially changed? (Tier 1 by structural change, or Tier 2 by measurement update.)
Q2 — Has any AI disadvantage in Part 2 been reduced or eliminated by capability changes? (Triggers constraint-relaxation review per Experiment_Parameters.md if reduction is material AND the strategy has constraints flowing from the reduced disadvantage.)
Q3 — Has any new disadvantage emerged that is not listed?
Q4 — Have any Part 3a questions been resolved by accumulated evidence?
Q5 — Has market saturation changed in a way that shifts edge accessibility?
Q6 — Has a synchronized-AI market event occurred in the prior quarter?
Q7 — Have calibration records confirmed or refuted any edge or disadvantage claim?
Q8 — Has new research surfaced specific new failure modes or confirmed edges?

Note: rev 3 dropped the previous Q8 ("model deprecation or version update") from triggering refresh — version changes follow a separate protocol per AI_Trading_Foundation.md Part 4 §"Version-change protocol" (no early refresh; flip Tier 2 to version-pending; quarterly delta picks up version-specific research as it emerges).

Per YES: (a) evidence triggering the yes, (b) whether the evidence clears the transferability filter (if non-Claude), (c) which Tier the affected item is (Tier 1 architectural / Tier 2 magnitude), (d) strategies affected, (e) which foundation-change-assessment branch is warranted (continue / terminate / constraint-relaxation per Experiment_Parameters.md §Foundation change trigger).

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Quarterly_AI_Foundation_Delta.md`. First line is the YYYY-QN marker. Chat output: one-line acknowledgment.
```

---

## Q4. Quarterly Action Conversion — regular routine

Runs after Q2 and Q3 are saved. Q1 has no actionable outputs and does not gate Q4.

```
Read access scope: Quarterly cadence. Query `events.decision_log` for any cross-references needed (all history queryable, no live/archive split, §15). Read `Strategy.md`, `Experiment_Parameters.md`, `AI_Trading_Foundation.md`, `Operating_Protocols.md`, `Watchlist.md` as relevant (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

Read the just-saved quarterly research files:
- `Quarterly_D_Candidates.md` (Q2 — D candidate shortlist with readiness flags)
- `Quarterly_AI_Foundation_Delta.md` (Q3 — YES/NO verification answers with foundation-change-assessment branches per strategy)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. D THESIS CONSTRUCTION FROM Q2 — for the Q2 ranked shortlist:
   - For each candidate marked "ready now": enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type thesis-construction; strategy D; due_date today; context from Q2 + Strategy.md D criteria + Operating_Protocols.md; conservative_default decline), ordered by thesis-strength rating. No cap. D2 drains them.
   - For each candidate marked "deferred pending rally pause": add to Watchlist.md D-deferred section with the trailing-30-day momentum reading and resolution-trigger ("when 30-day trailing return drops below X%"), AND enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type re-screen; strategy D; due_date = 30 days out; context = the re-check condition; conservative_default skip) so D2 re-checks then.
   - For each candidate marked "blocked by concentration or position count": add to Watchlist.md D-blocked section with the specific blocker and resolution condition ("when GICS <sector> concentration < 30%" or "when D book < 10 positions"). No queue entry — these resolve when an existing D position closes (M4 D-exit handling triggers re-evaluation).

B. FOUNDATION-CHANGE ASSESSMENT FROM Q3 — for each YES verdict that cleared the transferability filter and warrants foundation-change-assessment:
   - Per the strategies-affected list in the Q3 entry, enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per affected strategy (analysis_type foundation-change-assessment; strategy; due_date today; context = Q3 evidence summary + affected Tier (1 architectural / 2 magnitude) + the branch warranted (continue / terminate / constraint-relaxation) + reference to Experiment_Parameters.md §Foundation change trigger procedure; conservative_default = no change / continue). D2 drains them.
   - For NO verdicts and YES verdicts that fail the transferability filter: no action; logged as watch items, reviewed at next Q3 cycle.

C. WATCHLIST UPDATES — apply D-deferred / D-blocked additions from A.

D. DECISION-LOG ENTRIES — write a Q4-cycle outcome entry to `events.decision_log` (`CALL ops.sp_log_decision(...)`) summarizing: Q2 candidates scheduled vs deferred vs blocked counts, Q3 foundation-change-assessment events scheduled per strategy.

DEFERRAL DISCIPLINE: deferrals don't chain. Conservative-default fallback per deferred decision.

CALENDAR MCP USAGE: Q4 creates no calendar events — its analyses are enqueued to the `PENDING_ANALYSIS` queue (`events.queue_events`) and run by D2. Anchor dated due_dates on the America/Denver date. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- No exit orders are produced by Q4 (D exits flow through M4; A/B/C/E exits flow through D2/W4).
- One-line acknowledgment of file edits and `PENDING_ANALYSIS` queue entries enqueued.

If no file changes, no queue entries: "No actions required."
```

---

# ANNUAL (first trading day of January, or experiment anniversary month if January-anchoring isn't operationally clean)

A1, A2 are deep-research routines; A3 (action conversion) runs after A1 and A2 are saved.

## A1. AI Foundation Annual Full Re-Derivation — deep research

```
Read access scope: Annual cadence. Read everything, including full `events.decision_log` history (queryable, no live/archive split, §15).

Read AI_Trading_Foundation.md (Parts 1, 2, 3, 4 in full — pay particular attention to the Tier framework distinction), Strategy.md, Experiment_Parameters.md, Operating_Protocols.md, all prior Quarterly_AI_Foundation_Delta.md outputs from the past year (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

This is a FULL RE-DERIVATION task, not a delta. The scope is last-24-months primary-source research, not last-quarter. The purpose is to catch cumulative slow drift on Tier 2 numerical claims that quarterly deltas can't reliably surface, and to verify Tier 1 architectural items against any affirmative architectural-change evidence over a longer window.

HF tool orientation. Read `HF_Resource_Catalog.md` once at session start for the authoritative HF tooling map. Apply the following operational rules during PART 1 research:
- Run Hugging Face `paper_search` on each of the 9 query batteries enumerated in `HF_Resource_Catalog.md` §6.1 (Tier 1 architectural failure modes; cross-cutting; trading/financial). Use `concise_only=true` and `results_limit=8`. For each battery, record the 3–5 most-cited / most-recent papers (last 24 months) with arXiv IDs in the form `hf.co/papers/<id>`.
- Cross-check the durable anchors listed in §6.1 (StockBench `2510.02209`, FinanceBench `PatronusAI/financebench`, ReasonBENCH `2512.07795`, Beacon `2510.16727`, SynAnchors `2505.15392`, WAInjectBench `2510.01354`, BeliefShift `2603.23848`, Open LLM Leaderboard `open-llm-leaderboard/open_llm_leaderboard`) — verify each still exists and capture any successor work cited from them.
- For Tier 2 benchmark trajectories in §5.5, iterate `hub_repo_search` over open-weights model authors (`meta-llama`, `Qwen`, `mistralai`, `deepseek-ai`, others as relevant) with `repo_types=["model"]` and read benchmark scores from model cards. For benchmarks released or revised in the last 24 months that map to documented disadvantage categories (per §6.1 inverse mapping), capture the new measurements.
- Do NOT use `space_search` for canonical Spaces — per `HF_Resource_Catalog.md` §8.1, semantic search misses popular Spaces. Use `hub_repo_search` with explicit `author` and `repo_types=["space"]` for known Space lookup.
- HF is silent on Anthropic/Claude. For Section 1 Claude capability claims and any vendor-claim portion of other sections, use `web_search` and `web_fetch` against `anthropic.com`, `docs.anthropic.com`, and Anthropic's research blog. Do NOT attempt to find Claude data on HF.
- Do NOT pull data from any HF Space (none durable enough for multi-year experiment per §3) or any HF dataset (offline-only per §4). HF resources for this routine are: papers, model cards, leaderboards-as-references — nothing else.

Write the complete content directly to `Annual_AI_Foundation_Sweep.md` (overwrite; first line = current calendar year in YYYY format).

PART 1 — Last-24-months coverage of primary-source research, organized by AI_Trading_Foundation.md item rather than by topic. For EACH numbered item in Parts 1 and 2 (1.1 through 1.10, 2.1 through 2.26 or whatever the current count is):

  - Item identifier and tier (per AI_Trading_Foundation.md headers — Tier 1, Tier 2, or Tier 1 existence / Tier 2 magnitudes).
  - Current text of the item.
  - Primary-source research from last 24 months that bears on this item: papers, arXiv preprints, benchmark results, replications. Citations inline. Reverse chronological within item.
  - **Benchmark-result summary**: for Tier 2 items with benchmark mapping per §5.5, summarize benchmark trajectory over last 24 months — score progression on each mapped benchmark, models evaluated (specifically flag Claude family vs other), whether trajectory clears §5.5 Goodhart guardrails (≥3 sources, transferability, sustained, domain coverage). For Tier 1 items: no benchmark trajectory required (Tier 1 not subject to benchmark inference).
  - For Tier 2 items specifically: list the specific numerical claims and tag each as either "supported by recent research" (with citation), "contradicted/refined by recent research" (with citation and proposed update), "supported by benchmark inference" (with §5.5 verification), "contradicted by benchmark inference" (with §5.5 verification), or "absent from recent research" (no citation found in the 24-month window).
  - For Tier 1 items: report whether any architectural-change evidence has emerged. (Default: NO unless affirmative evidence is found.)

PART 2 — Per-item resolutions. The downstream A3 routine reads this PART 2 verbatim and produces the updated AI_Trading_Foundation.md applying the per-item resolutions, plus schedules per-strategy foundation-change assessment events per the aggregate outcomes. Make per-item resolutions explicit and structured.

For each item:
  - If Tier 1 with no architectural-change evidence: KEEP UNCHANGED.
  - If Tier 1 with architectural-change evidence: UPDATE per evidence; flag for foundation-change assessment.
  - If Tier 2 with supporting research: KEEP, optionally update with most-recent measurement.
  - If Tier 2 with contradicting/refining research: UPDATE numerical claim per evidence; flag for foundation-change assessment (may trigger constraint-relaxation review per Experiment_Parameters.md if the update represents disadvantage reduction).
  - If Tier 2 absent from recent research: MARK AS VERSION-PENDING. Do NOT auto-remove. The two-year absence is signal but not sufficient on its own to remove a previously-documented item — publication asymmetry means improvements often don't generate papers. Flag for participant judgment at next review cycle.

Then aggregate:
  - List of all items KEEP UNCHANGED.
  - List of all items UPDATE (with old text → new text and citation).
  - List of all items MARK AS VERSION-PENDING.
  - List of all items proposed for REMOVAL (rare; requires Tier 1 architectural-change evidence or Tier 2 with explicit contradicting research, NOT mere absence).
  - List of all NEW items proposed for addition (new failure modes or new edges discovered in the 24-month window).
  - Per-strategy foundation-change assessment recommendations: for each strategy A through E, list which items materially change its foundation and what the recommended outcome is (continue / terminate / constraint-relaxation review).

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Annual_AI_Foundation_Sweep.md`. First line is the YYYY marker. Chat output: one-line acknowledgment.
```

---

## A2. Per-Strategy Constraint Audit — deep research

```
Read access scope: Annual cadence. Read everything, including full `events.decision_log` history (queryable, no live/archive split, §15). A2 traces foundation-citation graphs across full `events.decision_log` history.

Read Strategy.md (full, including all per-strategy pre-mortems), Experiment_Parameters.md, AI_Trading_Foundation.md (current revision), Operating_Protocols.md, most recent Annual_AI_Foundation_Sweep.md output, and recent Quarterly_AI_Foundation_Delta.md outputs (positions from `state.current_positions`, regime from `state.current_regime`, decisions from `events.decision_log`).

This is the INVERSE of pre-mortem. Where pre-mortems attack strategies looking for missing constraints to ADD, this audit reviews strategies looking for existing constraints to potentially RELAX. Per AI_Trading_Foundation.md rev 4, the audit is fully mechanical — apply the criteria from §5.3-§5.6, no orchestrator discretion.

Write the complete content directly to `Annual_Constraint_Audit.md` (overwrite; first line = current calendar year in YYYY format).

For EACH strategy (A, B, C, D, E — and any others added since this task was authored), execute the §5.3 mechanical procedure:

PART 1 — Constraint inventory and foundation-citation graph.

  List every distinct constraint in the strategy's mechanism document and pre-mortem. Each constraint should be linked to:
  - The specific text of the constraint (entry rule, sizing cap, eligibility restriction, exit trigger, etc.).
  - The constraint's PRIMARY citation per AI_Trading_Foundation.md — parsed from the rev N annotations explicitly linking the constraint to a specific disadvantage. Mechanical: the constraint's primary citation is the item named in the annotation "rev N per cycle M T1.X" where T1.X is the cycle attacker output that originally surfaced the need for this constraint, traced to the specific 2.X item.
  - The constraint's SECONDARY citations — any other disadvantages named as mitigation targets in the pre-mortem's Section 5 entries or binding-constraint section. Mechanical: exact-text-match against pre-mortem Section 5 mitigation citations.
  - The revision in which the constraint was added.
  - Constraint type per §5.6 lookup (per-position sizing cap / universe restriction / concentration limit / frequency-cadence rule / hit-rate threshold / out-of-table).

PART 2 — Mechanical per-constraint relaxation verdicts. The downstream A3 routine reads this PART 2 verbatim and produces the updated Strategy.md applying mechanical relaxation verdicts per §5.6, plus queues out-of-table flags for explicit review. Make per-constraint outcomes explicit.

For each constraint:

Step 1 — Reduction status of primary citation. From most recent Annual_AI_Foundation_Sweep.md and prior-year Quarterly_AI_Foundation_Delta.md outputs, classify the primary cited disadvantage's reduction magnitude:
- NONE (no reduction signal) — constraint not a candidate; skip remaining steps.
- PARTIAL (25-75% reduction per §5.4 thresholds, with direct research evidence OR benchmark inference clearing §5.5 Goodhart guardrails) — proceed to Step 2.
- MATERIAL (>75% reduction or full elimination per §5.4 thresholds) — proceed to Step 2.

Step 2 — Benchmark-inference verification (rev 4 added). If the reduction signal comes from benchmark inference rather than direct research, verify §5.5 Goodhart guardrails:
- ≥3 independent benchmark sources (different research groups, different benchmark suites)?
- Replication on Claude family OR architectural-generality argument documented?
- Sustained improvement across ≥2 quarterly cycles OR documented in last-2-years annual sweep?
- Domain coverage matching workflow usage (general-purpose benchmarks always count; narrow benchmarks count only if domain matches)?
If any guardrail fails, downgrade reduction to NONE for this audit cycle. Constraint is not a candidate.

Step 3 — Load-bearing test. Check the constraint's secondary citations from PART 1:
- For each secondary citation, is the cited disadvantage still in force per current AI_Trading_Foundation.md (i.e., not eliminated, and not classified as MATERIAL reduction in this audit cycle)?
- If any secondary citation is still in force → constraint is load-bearing for multiple disadvantages → no relaxation, regardless of magnitude on primary citation.

Step 4 — Apply §5.6 mechanical relaxation lookup. For constraints passing Steps 1-3:
- Per-position sizing caps: PARTIAL → cap × (1 + reduction%); MATERIAL → cap × 2 (capped at 5%).
- Concentration limits: PARTIAL → limit + (limit × reduction%); MATERIAL → limit + 15pp (capped at 50%) or removed if all citations eliminated.
- Universe restrictions: PARTIAL → no change; MATERIAL with full elimination of all citations → reconsider for full removal (subject to Step 3).
- Hit-rate thresholds with disadvantage-keyed derivations: PARTIAL → threshold loosened proportionally per derivation citation; MATERIAL → threshold reconsidered at next gate review.
- Frequency-cadence rules: no auto-relaxation. Flag for explicit annual review.
- Out-of-table constraints: flag in §5.7 audit trail; no relaxation; constraint stays at current value pending participant resolution.

Step 5 — Output structured audit trail per §5.7 for each strategy:
- Strategy identifier and current revision.
- Foundation citation graph.
- Per-citation status changes since strategy's foundation revision.
- Per-constraint evaluation: primary citation reduction status, benchmark-inference verification result (if applicable), load-bearing test result, applicable relaxation form per §5.6, new constraint value (if relaxed), reason for non-relaxation (if not).
- Out-of-table flags listing any constraints the criteria couldn't deterministically resolve, with the specific gap identified.

The expected outcome of A2 in any given year is: most constraints have NONE primary-citation reduction (Step 1 terminates the evaluation); a small number have PARTIAL or MATERIAL reduction; of those, most fail Step 3 load-bearing test; of the remainder, §5.6 lookup produces structured relaxation forms; out-of-table flags are rare. The audit is operationally cheap when no constraints have reduction signals and only generates substantive output when AI_Trading_Foundation.md has documented disadvantage reductions.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Annual_Constraint_Audit.md`. First line is the YYYY marker. Chat output: one-line acknowledgment.
```

---

## A3. Annual Action Conversion — regular routine

Runs after A1 and A2 are saved. Produces the updated AI_Trading_Foundation.md from A1 and the updated Strategy.md from A2, plus schedules per-strategy foundation-change assessment events.

```
Read access scope: Annual cadence. Read everything (full `events.decision_log` history, queryable, no live/archive split, §15). Read `AI_Trading_Foundation.md` (current revision), `Strategy.md` (current revisions for all strategies), `Experiment_Parameters.md`, `Operating_Protocols.md`, `Watchlist.md` (positions from `state.current_positions`, decisions from `events.decision_log`).

Read the just-saved annual research files:
- `Annual_AI_Foundation_Sweep.md` (A1 — per-item KEEP/UPDATE/VERSION-PENDING/REMOVAL/NEW outcomes + per-strategy foundation-change assessment recommendations)
- `Annual_Constraint_Audit.md` (A2 — per-constraint mechanical relaxation verdicts + out-of-table flags)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. UPDATED AI_TRADING_FOUNDATION.MD FROM A1 — produce a new revision of AI_Trading_Foundation.md applying:
   - All KEEP UNCHANGED items: text unchanged.
   - All UPDATE items: replace old text with new text per A1 evidence. Update item revision annotation to cite the A1 sweep date and the underlying primary research.
   - All MARK AS VERSION-PENDING items: mark inline with "VERSION-PENDING per A1 <YYYY> sweep" annotation; do NOT remove.
   - All REMOVAL items: remove (these are rare per A1 specification — Tier 1 architectural change or Tier 2 with explicit contradicting research only).
   - All NEW items: append in the appropriate Part (1 capabilities / 2 disadvantages / etc.) with full annotation.
   - Increment AI_Trading_Foundation.md revision number; append revision-history entry citing A1 sweep date and summary of changes (counts per category).

B. PER-STRATEGY FOUNDATION-CHANGE ASSESSMENT FROM A1 — for each per-strategy recommendation in A1's aggregate output:
   - Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`) per affected strategy (analysis_type foundation-change-assessment; strategy; due_date today; context = A1 evidence summary + recommended outcome (continue / terminate / constraint-relaxation review) + reference to Experiment_Parameters.md §Foundation change trigger procedure; conservative_default = continue at current revision). D2 drains them.

C. UPDATED STRATEGY.MD FROM A2 — produce a new revision of Strategy.md applying:
   - All constraints with §5.6 mechanical relaxation verdicts: replace constraint value with new (relaxed) value per §5.6 formula. Update constraint annotation to cite the A2 audit date and underlying foundation revision.
   - All constraints flagged out-of-table: leave at current value; add out-of-table annotation citing the §5.7 audit trail.
   - All constraints with no relaxation (NONE primary citation, or Step 3 load-bearing test failed, or §5.5 Goodhart guardrail failed): unchanged.
   - Increment per-strategy revision numbers as needed; append revision-history entries citing A2 audit and underlying AI_Trading_Foundation.md revision.

D. OUT-OF-TABLE EXPLICIT REVIEW FROM A2 — for each out-of-table flag:
   - Enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type constraint-relaxation-review; strategy; ticker_or_pair n/a; due_date = the first trading day after the foundation-change assessments are expected to complete, typically week 2 of the new year; context = §5.7 audit-trail content for the flag (constraint text, why mechanical lookup failed, specific gap) + reference to Experiment_Parameters.md constraint-relaxation review procedure; conservative_default = leave the constraint unchanged). D2 drains it.

E. DECISION-LOG ENTRIES — write entries to `events.decision_log` (`CALL ops.sp_log_decision(...)`) documenting:
   - The A1 cycle outcome: counts per category (KEEP / UPDATE / VERSION-PENDING / REMOVAL / NEW), revision number bumped on AI_Trading_Foundation.md, per-strategy foundation-change assessments scheduled.
   - The A2 cycle outcome: per-strategy constraints relaxed counts, out-of-table flag counts, revisions bumped on Strategy.md.

F. WATCHLIST AND OPERATING_PROTOCOLS RECONCILIATION — review whether any A1/A2 outcomes affect Watchlist.md (e.g., constraint-relaxation that re-opens previously-blocked candidates) or Operating_Protocols.md (e.g., updated foundation revision affecting protocol citations). Apply minimal edits if changed.

DEFERRAL DISCIPLINE: deferrals don't chain. Conservative-default fallback: if a foundation-change assessment cannot resolve, the strategy continues at current revision pending next quarterly delta.

CALENDAR MCP USAGE: A3 creates no calendar events — its assessments/reviews are enqueued to the `PENDING_ANALYSIS` queue (`events.queue_events`) and run by D2. Anchor dated due_dates on the America/Denver date. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- No exit orders are produced by A3.
- One-line acknowledgment of file edits and `PENDING_ANALYSIS` queue entries enqueued.

If no file changes, no queue entries: "No actions required." (rare for A3 — at minimum AI_Trading_Foundation.md will have a revision bump documenting the sweep, even if all items KEEP UNCHANGED.)
```

After A3 completes, the per-strategy foundation-change assessments and out-of-table constraint-relaxation reviews run when D2 drains their `PENDING_ANALYSIS` queue entries (`events.queue_events`; per the Experiment_Parameters.md §Foundation change trigger procedure).

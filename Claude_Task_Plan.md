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
| **AR_att** | Adversarial Review Attacker | Daily¹ · regular | review queue (`state.open_queue`/`events.queue_events`, `PENDING_REVIEW`); artifact | `events.adversarial_reviews` (attacker) | Adversarial_Review_*_attacker.md |
| **AR_orc** | Adversarial Review Orchestrator | Daily¹ · regular | `events.adversarial_reviews` (attacker); artifact | `events.adversarial_reviews` (orchestrator); `events.regime_events` (binding activation); `events.decision_log` | Adversarial_Review_*_orchestrator.md |
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
| **AR_attacker** | the artifact under review only | any strategy slice / Decision_Log / prior reviews (strict blinding) |
| **W2** (B) | `04_strategy_b.md` + `01` | other strategy slices |
| **M2** (E) | `07_strategy_e.md` + `01` | other strategy slices |
| **M3 / Q2** (D) | `06_strategy_d.md` + `01` | other strategy slices |
| **W1** (A, C) | `03_strategy_a.md`, `05_strategy_c.md` + `01` | B/D/E slices |
| Strategy C order routines | `05_strategy_c.md` + `c_options_math.py` | — |
| **M1b** (strategy mapping) | `02_regime_router.md` + `03–07` (mapping needs the activation rules) | — |
| **W3 / W4 / M4 / Q4 / A3 / D1 / AR_orchestrator** (multi-strategy) | the slices for the strategies in scope (+ `08_pre_mortems.md` for reviews) | — |

When a slice is insufficient (need cross-strategy context the slices don't carry), fall back to `Strategy.md` — but prefer the slice. If `strategy/` is stale vs `Strategy.md` (CI check `scripts/split_strategy.py --check` fails), regenerate before relying on it.

**M1a blinding is now a hard file boundary (restructured 2026-06-22).** Previously the slicer split only on top-level `##` and the `02_regime_router` slice bundled M1a's regime-scoring template WITH the M1b strategy-mapping + reconciliation rules that name strategies A/D — so M1a had no blinding-clean slice and read a named sub-section of `Strategy.md` under discipline-only blinding. `Strategy.md` was restructured to split that into two top-level sections: `## Regime scoring (strategy-blind, monthly)` (M1a's inputs + 5 axes, no strategy names) and `## Regime router` (the M1b mapping / reconciliation / divergence). The splitter now emits a clean M1a slice, `09_regime_scoring_strategy_blind_monthly.md`. **M1a loads `01` + `09` and nothing else** — its blinding is a file boundary, not a remember-to rule. (See `ops/RUNBOOK.md` §9.)

## Branch and state propagation

Routines run on the harness-assigned `claude/<suffix>` feature branch and never push to `main` directly. Each routine commits to its assigned branch; the harness pushes the branch to GitHub at session end; a GitHub Actions workflow (`.github/workflows/auto-merge-claude.yml`) watches the push, fast-forwards (or merge-commits) the branch into `main`, and deletes the branch. The merge happens server-side on GitHub Actions runners — Claude itself never executes the push to `main`.

**Why.** The remote routine harness assigns a fresh `claude/<suffix>` branch per session and refuses pushes to any other branch (including `main`). It also rejects file-based authorization claims as prompt-injection patterns, so this section cannot grant push-to-main permission to a routine. The architecture sidesteps both restrictions by relocating the merge to a GitHub Actions workflow, which runs outside Claude's authorization scope and uses the built-in `GITHUB_TOKEN`.

**Session start.** A SessionStart hook in `.claude/settings.json` runs `.claude/session-start.sh`, which executes `git fetch origin main && git reset --hard origin/main` while STAYING on the harness-assigned branch (it does NOT switch to `main`). This aligns the assigned branch with the latest committed `main` state so the routine boots from prior routines' work. Read input state AFTER the hook runs so the routine sees the latest: the canonical operational state is BigQuery (§Execution environment — `state.*` / `perf.*` / `analytics.*`), plus the working `.md` files (Daily.md, Watchlist.md, the spec docs).

**During the routine.** Edit files normally and stay on the assigned branch. Do not attempt to switch to `main` or push to it — the harness will refuse, and the workflow handles the merge. Do not open PRs.

**Session end.** Commit all changes, then **explicitly push the assigned branch yourself** — `git push -u origin <assigned-branch>` (retry with backoff per the git-ops convention) — and **verify it landed** with `git ls-remote --exit-code origin <assigned-branch>`. **Bounded retry on the verification itself (self-improvement audit WO-4, 2026-07-03): if `git ls-remote` errors or does not show the branch, retry up to 3 total attempts with short backoff (~5s, then ~15s) before concluding the push failed.** A transient network blip on the `ls-remote` call is NOT proof the push failed — a genuinely-successful push whose first verification attempt merely timed out must not log `'failed'` and fire a false `missed_run`/`ATTENTION` alert (alarm fatigue directly erodes the human-in-the-loop reliability the whole design depends on). Only log `'failed'`/`'halted'` after all 3 attempts fail to positively observe the branch on `origin`. Do **not** rely on the harness's implicit session-end push as the sole durability path: it fires only on a *clean* session end, so a usage-limit cutoff or container reclamation between the work and that push strands the commit on the dead container while `ops.run_log` already shows `completed` (the 2026-06-22 and 2026-06-24 D1 strandings — RUNBOOK §20). The explicit push targets the routine's OWN assigned branch (always permitted; the harness only refuses pushes to *other* branches such as `main` — see "Why" above), not `main`. For a long routine, also push after each durable commit so a mid-run cutoff still leaves output on the remote. Only **after** a confirmed remote push, log `sp_routine_end(...,'completed',...)`; if the push cannot be confirmed after the 3 retries, log `'failed'`/`'halted'` with `error_msg='branch push unconfirmed after 3 verification attempts — output may be stranded'` instead, so the divergence is an explicit failure rather than a silent `completed`-without-remote. Within roughly 30 seconds the auto-merge workflow merges the branch into `main` and deletes the branch (an early push just makes the branch available to the next auto-merge run sooner; a commit pushed during the merge window is left for the next run — see Cleanup). The next routine's SessionStart hook will pick up the new state.

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

- **Connector pre-flight (FIRST — before run-logging, the dependency gate, or any routine's own Step 0).** Before anything else, prove the connectors this routine needs are live with one trivial liveness read each: **BigQuery** via `SELECT * FROM `stock-trading-498512.state.trading_day_today`` (every routine — this is also the `today` the templates below need, so it is near-zero extra cost); for **D1/D2** the **IBKR** connector via `get_account_summary`; and for the **order-STAGING routines** (D2, D3, W4, M4, Q4, A1, A3, AR_orc — every routine that may create a `[Claude] Confirm order` event; D1 stages nothing, so it is exempt) the **Calendar** connector via a 1-day `list_events` read. The point is to catch a de-authed/expired connector in seconds at the top of the run instead of mid-routine (the recurring owner-OAuth BigQuery de-auth — RUNBOOK §15/§26). Route the failure by which connector failed and whether the routine can proceed safely:
  - **BigQuery unreachable (token expired / re-auth required).** The alert sink is itself down, so you canNOT `sp_raise_alert`/write `ops.alerts`; the only first-class channel is a **`[Claude] ATTENTION — RE-AUTH BigQuery connector` calendar event — create it immediately.** Then branch on the routine: **D1 is research-only and stages no orders → proceed in DEGRADED MODE** (read book/marks from the IBKR connector, carry regime forward from the prior `Daily.md`, defer every BigQuery side-write, and banner `Daily.md` exactly as the 2026-06-26 run did). **D2/D3 require canonical state → HALT cleanly** (never run on missing/stale state; craft no orders). The next-morning freshness + cadence dead-man's switches durably record the miss once BigQuery returns; resolve per RUNBOOK §26.
  - **IBKR unreachable (BigQuery up).** The documented `connector` hard-stop: `CALL ops.sp_raise_alert('critical', '<ID>', 'connector', 'IBKR connector unreachable at pre-flight', '<JSON>')`, create a `[Claude] ATTENTION` event, log the run `'halted'`, and ABORT (D1/D2 cannot reconcile the book or craft orders without it).
  - **Calendar unreachable (BigQuery up; staging routines only).** Calendar is the ONLY binding human-facing surface (Human role above): an order the human is never told to confirm is a broken workflow. If the pre-flight `list_events` fails on a routine that may stage an order, treat it as a hard-stop BEFORE crafting anything: `CALL ops.sp_raise_alert('critical', '<ID>', 'connector', 'Calendar connector unreachable at pre-flight', '<JSON>')`, log the run `'halted'`, and ABORT — do NOT craft IBKR orders you cannot surface a confirm event for. (BigQuery is up here, so the `ops.alerts` row + the alert-emailer/relay deliver it; the §26 BigQuery-down branch already covers the shared-OAuth case where Calendar is down because BigQuery is.)

  This makes a connector de-auth a seconds-to-detect, single-channel-surfaced event for **every** routine rather than a mid-run partial failure — the RUNBOOK §26 blast-radius mitigation. (D1 already did exactly this ad-hoc on 2026-06-26; this makes it uniform and first.)

- **Alert auto-resolve (every run, right after connector pre-flight) — BEST-EFFORT, never gates.** `CALL ops.sp_auto_resolve_alerts()` (`bigquery/34_alert_lifecycle.sql`, self-improvement audit WP2, 2026-07-07), wrapped so a failure here can never abort the routine:
  ```
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;  -- swallow: cleanup must not abort the routine
  END;
  ```
  This mechanically clears a small, explicit allowlist of critical/warning alerts whose truth is a re-checkable fact (`missing_dependency`, `missed_run`, `routine_stalled`, the `staleness` echo — see `ops.alert_policy`, fail-closed: every other category, including every capital-affecting class like `cash_tripwire`/`order_guard_block`/`trading_halted`, is untouched and stays human-only, drilled monthly via `ops.sp_fire_drill_alert_latch`). Running it here — before `state.trading_enabled`/`_mechanical` is ever read by a staging routine, and before this routine's own dependency gate below — means a stale alert from a prior day's transient (e.g. a stranded upstream that has since caught up) self-clears on the very next routine to run, instead of requiring a human `UPDATE ops.alerts`. Live incident this closes (verified 2026-07-06/07): a stranded D1 left `missing_dependency`/`missed_run`/`staleness` criticals open that would otherwise have kept `state.trading_enabled = FALSE` forever after D1/D2 caught up.

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

- **Staging atomicity (order-staging routines) — gate `completed` on the confirm event existing.** Creating the `[Claude] Confirm order` event is PART of staging, not an afterthought: if `create_event` fails AFTER an IBKR order is crafted and the `ORDER_STAGED` `pending` row is written, the order is staged but the human is never told to confirm it (routine chat is unmonitored). Treat that as a hard error — `CALL ops.sp_raise_alert('critical', '<ID>', 'staging', 'confirm-order event creation failed for <ticker> — order staged but unsurfaced', '<JSON>')` and log the run `'failed'`/`'halted'` (do **NOT** log `'completed'`), mirroring the verified-push gate above. This makes a staged-but-unsurfaced order a durable terminal-status fact the `missed_run` / `routine_stalled` / `state.go_without_order` switches catch, rather than a silent `completed` hiding a real actionable order. (D3 `missed_confirmation` + `state.go_without_order` remain the next-day backstop; this closes the same-run window.)

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

Cadence-output files (Daily.md, Weekly_Catalyst_Calendar.md, etc.) are overwritten in full each run. The first line is ALWAYS the bare marker, literally first — before any `#` title or blockquote (a 2026-06/07 Q1 run put a title on line 1 and the marker on line 3; corrected — see Quarterly_Regime.md):

- Daily files: `YYYY-MM-DD` (today's calendar date).
- Weekly files: `YYYY-WW` — the ISO week of TODAY's run date (`state.trading_day_today.today`), the SAME week every weekly file stamps this cycle. Never the upcoming trading-Monday's week or any other look-ahead convention (a 2026-06-28 W1 run once did this and mismatched its own W2/W3 siblings — corrected, see the W1 prompt body's explicit guard).
- Monthly/Quarterly files: **per-routine, not a single rule** — the exact semantics differ by whether the routine is retrospective (looks backward) or forward-looking (stages what's ahead), so check the table below rather than assume:

  | Routine | File | Marker = |
  |---|---|---|
  | M1b | Monthly_Fundamental.md | current month (forward-looking activation calls) |
  | M2 | Monthly_E_Pairs.md | current month |
  | M3 | Monthly_D_Position_Deep_Dive.md | current month |
  | Q1 | Quarterly_Regime.md | **prior** quarter (retrospective) |
  | Q2 | Quarterly_D_Candidates.md | current quarter (forward-looking) |
  | Q3 | Quarterly_AI_Foundation_Delta.md | **prior** quarter (retrospective) |
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

TL;DR (readability — added 2026-07). Immediately after the header (scan-window line + tape summary), before DEVELOPMENTS, write a ≤5-line plain-bullet TL;DR: exits triggered (count + tickers, or "none"), new entry candidates (count + tickers, or "none"), watchlist changes (or "none"), and a one-line regime-review flag (or "no review"). This is a summary of the RECOMMENDED ACTIONS section computed below, placed at the top for a human skimming top-down (D2 still reads the full file bottom-up as today; this changes nothing D2 parses).

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

MACHINE-READABLE ACTION BLOCK (added 2026-07, robustness). Immediately after the prose RECOMMENDED ACTIONS section, append a fenced ```yaml d1_actions``` block with ONE list entry per bullet above (empty list `[]` if "No recommended actions"), same order, mirroring the same content structurally rather than restating it in prose:
```yaml d1_actions
- action: exit | thesis | watchlist | router_review
  ticker: <ticker, or n/a for a watchlist-only / router_review item>
  strategy: <A|B|C|D|E, or n/a>
  detail: <one line — invalidation criterion / candidate rationale / add-remove-demote / review justification>
```
This gives D2 a structural cross-check independent of prose-parsing: D2 counts the prose bullets against this block's entry count and HALTS (per the observability "Failure alerts" convention — `missing_dependency` category, since converting an under- or over-counted action set risks a missed exit or a fabricated order) on a mismatch, instead of silently mis-converting a bullet a prose-only parse missed or double-counted. The block is a structural mirror, not a new source of truth — the prose above remains authoritative for WHY; this block only has to agree on WHAT and HOW MANY.

OUTPUT: write the complete content above directly to `Daily.md` (overwriting the prior day's file). First line is today's date in YYYY-MM-DD format; the line directly below it is the machine-readable `<!-- d1_scan_through_utc: <this run's execution time, ISO-8601 UTC> -->` marker (per SCAN WINDOW above — this is what the next run reads to resolve its window start), and the header carries the human-readable `Scan window: <start · America/Denver> → <now · America/Denver>` line, followed by the TL;DR block. No chat output beyond a one-line acknowledgment that Daily.md was written.
```

---

## D2a. Broker Reconcile & Snapshot — regular routine

> **PARTIALLY CUT OVER (self-improvement audit WO-3, 2026-07-03; trigger created 2026-07-03).** This
> routine splits D2's mechanical, dependency-light broker-reconcile/cash-safety/TWR-engine work out of
> the analysis-heavy action-conversion work, so a halt in the latter (Step 1 onward) can never stall
> fills reconciliation, cash-tripwire safety, the SGOV sweep, or the deployed-TWR engine simultaneously
> (the D2 mega-SPOF the audit flagged). The web-UI trigger now exists and ran once (2026-07-03, a market
> holiday — see `ops.run_log`). **Until the CUTOVER AUTO-CHECK below actually performs the cutover, D2
> continues to run its OWN Step 0/Step 0b/TWR-maintenance exactly as documented in the "## D2." section —
> nothing changes operationally, and the current split-brain state (both routines doing Step 0's work) is
> safe: D2a runs first, and D2 redoing the same reconciliation is idempotent.**
>
> **The cutover is now FULLY AUTONOMOUS — no chat question, no human reply, ever.** (Correction,
> 2026-07-03: D2a's first run ended by asking the operator in chat "Reply if you'd like me to complete
> the cutover" — but routine chat is unmonitored, documented throughout this file; that question would
> never be seen, so the cutover would simply never happen. That is a bug in this section's original
> instructions, not a one-off mistake by that run — fixed here.) The CUTOVER AUTO-CHECK step at the end
> of this routine's steps below queries `state.d2a_cutover_readiness` — `ready_for_cutover` requires
> **3 DISTINCT TRADING-DAY** completed D2a runs (a holiday run does not count: it never exercises real
> fill reconciliation, SGOV sweep/cover crafting under `analytics.fn_order_guard`, or TWR-engine ingest
> from freshly-pulled marks — the paths this cutover actually needs confidence in) AND no prior cutover
> (`ops.d2a_cutover_log` empty, the durable idempotency marker — a BigQuery row, not a prose/grep read of
> this file). When ready, D2a performs the cutover ITSELF, in the same session, with full repo write
> access (exactly as this file's own edits are made): edit `ops/cadence.yaml` (`D2`'s `depends_on` →
> `[D1, D2a]`), delete Step 0 / Step 0b / "PER-STRATEGY PERFORMANCE MAINTENANCE" / "SEEDING A NEW
> STRATEGY" from the "## D2." section below (replace with a one-line pointer: "Step 0/0b/TWR-maintenance
> now run in D2a; see `state.current_positions` / `analytics.strategy_nav` / `perf.strategy_daily` /
> `analytics.account_reconciliation` for its output" and fix D2's "If Step 0 reconciled no new fills..."
> check to read D2a's `ops.run_log` fill-count instead), regenerate `ops/triggers.json`
> (`python scripts/print_routines.py --write`), run `scripts/check_cadence_consistency.py` to confirm all
> surfaces agree, commit, and push. Then `INSERT INTO ops.d2a_cutover_log` (the idempotency marker) and
> `CALL ops.sp_raise_alert('info','D2a','auto_cutover', 'D2/D2a cutover performed autonomously after N
> qualifying trading-day runs', <JSON: qualifying_trading_day_runs, git_commit>)` — an INFO-severity row
> purely for the audit trail, since no action is needed from anyone; do NOT ask in chat, before or after.
> The BigQuery-side scaffolding (cadence_expected_today, routine_catalog, stalled_runs tier,
> `state.d2a_cutover_readiness`) is already applied live — see `bigquery/12_cadence_monitor.sql` /
> `15_routine_catalog.sql` / `18_stack_review_fixes.sql` / `32_d2a_cutover_readiness.sql`. Self-
> bootstrapping throughout: `state.cadence_watch`/`state.stalled_runs` only become alarm-eligible after
> a routine's first `completed` run, so D2a's adoption has generated zero false alarms.

Runs first, every operating day (including non-trading days, so the account stays reconciled even when
D1/D2 don't fire) — independent of D1. Reconciles the live brokerage account, runs the cash/SGOV safety
tripwire, sweeps/covers to SGOV, snapshots the account, and maintains the deployed-TWR engine. Carries
NO analysis and stages NO discretionary orders (only the mechanical SGOV sweep/cover) — D2 (below)
depends on this routine's output for its own Step 1 onward.

```
Read access scope: Daily cadence. Read positions/perf/NAV from `state.current_positions` /
`perf.strategy_daily` / `analytics.strategy_nav` / `analytics.account_reconciliation`. Read
`Operating_Protocols.md` §11/§13/§14 as relevant. No Strategy.md / Watchlist.md / decision_log access
needed — this routine does no thesis work.

RUN LOGGING (every run). At the very START of this routine, `CALL ops.sp_log_run('D2a', <today,
America/Denver from state.trading_day_today>, 'started', <session_id>, <branch>, NULL, NULL, NULL)`. At
the END, call it again with `'completed'` (or `'failed'`/`'halted'` + `error_msg`), passing
`rows_written` = fills + marks ingested.

**TRADING-ENABLE GATE (self-improvement audit B-1-obs, 2026-07-03; gate-ordering fix 2026-07-07, `bigquery/33_gate_ordering_fix.sql`) — `CALL ops.sp_assert_trading_enabled_mechanical('D2a')` before anything else.** FATAL (mirrors `ops.sp_assert_deps`) — aborts if `state.trading_enabled_mechanical.trading_enabled = FALSE` (a manual/auto halt, a NAV drawdown breach, unhealthy embeddings, an open critical alert, or position-reconciliation drift). Deliberately NOT `ops.sp_assert_trading_enabled` (the D2/W4/M4/Q4/A1/A3 gate) — that one also requires `marks_fresh`/`engine_fresh`, which THIS routine's own PER-STRATEGY PERFORMANCE MAINTENANCE step (below) is what makes true each morning; calling the freshness-inclusive gate before that ingest RAISEs on every trading-day run (see `33_gate_ordering_fix.sql`'s header for the full self-diagnosed deadlock this replaced). Reads/reconciliation are safe regardless; do not size or stage the SGOV sweep past this point if it raises.

STEP 0 — BROKER RECONCILIATION. Reconcile the live brokerage account against the BigQuery events-side
state (`state.current_positions` / `analytics.account_reconciliation`) via the IBKR connector — verbatim
the same procedure as "## D2." Step 0 below (reproduced there; this routine performs it, D2 no longer
does once cut over): fill reconciliation + event-sourcing mirror, staged-order registry reconciliation,
cash/SGOV tripwire, cash flattening sweep/cover (with the `analytics.fn_order_guard` check per
self-improvement audit B-2-exec), noting still-working orders, and clearing stale instructions.

STEP 0b — ACCOUNT SNAPSHOT. Same procedure as "## D2." Step 0b below.

PER-STRATEGY PERFORMANCE MAINTENANCE (deployed-TWR engine). Same procedure as "## D2." below: ingest
daily marks (with the FMP fallback), the per-name completeness check, `CALL ops.sp_daily_refresh()`, and
the engine-verification sanity check.

CUTOVER AUTO-CHECK (run last, after everything above — self-improvement audit follow-up, 2026-07-03).
`SELECT * FROM state.d2a_cutover_readiness`. If `ready_for_cutover = FALSE`, do nothing and proceed to
chat output — this is the expected state on every run until the threshold clears; it is NOT a finding
and never needs mentioning in chat output. If `ready_for_cutover = TRUE`, perform the full cutover
described in this section's banner above (edit `ops/cadence.yaml` + the "## D2." section + regenerate
`ops/triggers.json` + `check_cadence_consistency.py` + commit + push), then `INSERT INTO
ops.d2a_cutover_log` and `CALL ops.sp_raise_alert('info','D2a','auto_cutover', ...)` — no chat question,
before or after; a one-line mention in this run's chat output that the cutover happened is sufficient
(chat is unmonitored, so the alert row above is the record that matters, not the chat line).

CHAT OUTPUT: one-line acknowledgment of reconciliation (fills captured, cash tripwire status, sweep/
cover crafted or not, engine recompute status). If nothing to report: "Reconciliation complete, no
action needed."
```

---

## D2. Daily Action Conversion — regular routine

Runs after D1 has written Daily.md. Reconciles fills, drains the analysis queue, and converts D1's RECOMMENDED ACTIONS into orders and live-file edits — running thesis construction and other analyses in-session (no human-pasted thesis events).

```
Read access scope: Daily cadence. Read decisions from `events.decision_log` + `analytics.find_precedents()` (the retired `Decision_Log*.md` are git history only). Read positions/perf/NAV from `state.current_positions` / `perf.strategy_daily` / `analytics.strategy_nav` (retired Portfolio_Ledger.md) and regime from `state.current_regime` (retired Regime_State.md). Read the spec/working files `Strategy.md`, `Experiment_Parameters.md`, `Operating_Protocols.md`, `Watchlist.md`, `B_Sub_Pattern_Taxonomy.md` as relevant.

RUN LOGGING (every run — observability, `bigquery/10_observability.sql`). At the very START of this routine, `CALL ops.sp_log_run('D2', <today, America/Denver from state.trading_day_today>, 'started', <session_id>, <branch>, NULL, NULL, NULL)`. At the END, call it again with `'completed'` (or `'failed'`/`'halted'` + an `error_msg` if it stopped), passing `rows_written` = fills + marks ingested. This populates `state.freshness.d2_ran_last_trading_day` and arms the dead-man's switch (`bigquery/scheduled_queries/daily_freshness_check.sql`), so a silently-skipped or crashed D2 is detected instead of failing silent.

STEP 0 — BROKER RECONCILIATION (run first, every run, before reading Daily.md's actions). **TRADING-ENABLE GATE (self-improvement audit B-1-obs, 2026-07-03) — `CALL ops.sp_assert_trading_enabled('D2')` before anything else in this step.** This is FATAL (mirrors `ops.sp_assert_deps`): it RAISEs and aborts the routine if `state.trading_enabled.trading_enabled = FALSE` (a manual/auto halt, `state.system_health.all_green = FALSE`, or a book-level NAV drawdown breach — see `bigquery/23_trading_control.sql`). Reconciliation/reads are safe regardless of the gate, but do NOT size or stage anything past this point if it raises — the alert + `RAISE` already record why. Then reconcile the live brokerage account against the BigQuery events-side state (`state.current_positions` / `analytics.account_reconciliation`; Portfolio_Ledger.md is retired, §15) via the IBKR connector. This replaces the retired operator-screenshot fill-capture sessions (Operating_Protocols.md §11):
- Read `get_account_trades` over a DAYS_7 window. For each fill whose `trade_id` is NOT already in `events.trade_fills` (idempotent match on `trade_id`): record the exact price / size / `commission` / `realized_pnl` / `trade_time` (via the BigQuery event-sourcing step below); flip the affected position ORDER-STAGED→OPEN (entries) or exit-pending→CLOSED (exits) with an `events.position_events` row, and set the matching `state.open_orders` staged-order row terminal `filled` (Operating_Protocols.md §11 staged-order registry); update strategy sector counts and any KL #12 event membership; write the GO/close decision via `CALL ops.sp_log_decision(...)` if staging recorded only the order. Realized P&L comes from the connector's `realized_pnl` field — never inferred. Aggregate exchange-split partial fills by `order_id`.
- **Mirror the reconciliation to the BigQuery event tables (connector-driven event-sourcing).** For each new fill: `INSERT INTO events.trade_fills` (trade_id, order_id, contract_id, fill_ts, strategy, ticker, side, shares, price, commission, realized_pnl) — idempotent by `trade_id`; and write the position lifecycle event to `events.position_events` — an `OPEN` event on an entry (`cost_basis = shares×price + commission`, contract_id, shares, plus convergence_target / time_exit_date / conviction / source_thesis_ref from the staging entry) or a `CLOSE` event on an exit. This keeps `state.current_positions`, the deployed-TWR engine, and `state.daily_briefing` current. Also write the day's new decision via **`CALL ops.sp_log_decision(...)`** (bigquery/08_ops_procedures.sql) — this appends the structured `events.decision_log` row (incl. `body_md`) **and embeds it in the same call**, so a decision is never left unembedded (no separate `ML.GENERATE_EMBEDDING` step). Populate `ticker` (regex for the clean "Strategy X — TICKER" title format, else `ops.gemini` AI extraction per bigquery/02_ai_layer.sql). Sync is verifiable any time via `SELECT * FROM state.embedding_health` (expect `is_healthy = TRUE`); if a raw `INSERT` was ever used instead, `CALL ops.sp_embed_pending()` to catch up. **This connector/agent-driven event-sourcing SUPERSEDES the one-time `parse_*.py` migration path** (which produced the buggy initial rows, since rebuilt from the connector 2026-06-05/06); the parsers are kept for reference only.
- Read (do not transcribe) live positions, cash, and net-liquidation from `get_account_positions` + `get_account_summary` + `get_account_balances` for the reconciliation cross-check; reconcile account-level drift (dividends, fees, reinvestments, splits) to the connector truth while preserving per-strategy cost-basis attribution — use `get_price_history` with `include_corporate_actions: true` (plus the `get_account_trades` DRIP/dividend rows) to attribute the drift precisely. Per the connector-era recording policy, marks/market-values/unrealized-P&L are NOT written into the events-side state — only cost-basis and strategy allocation are (`events.position_events` / `state.current_positions`; live marks flow through `events.daily_marks` into the TWR engine instead).
- **Connector-sanity band on net-liquidation (self-improvement audit, 2026-07-03) — before treating this session's `get_account_summary` net-liquidation as ground truth for anything downstream.** Compare it to `state.account_latest.nav` (yesterday's Step 0b snapshot — today's row does not exist yet at this point in the run, so this is a clean prior-day baseline with no new table needed). If the day-over-day change exceeds **±15%**, do not proceed past this bullet — do not sweep, size, stage, or let Step 0b write today's snapshot — unless the move is fully explained by what THIS session already reconciled (a fill's realized P&L, a dividend, a deposit/withdrawal from the cash tripwire below, a confirmed split). An unexplained jump halts exactly like the cash tripwire: `CALL ops.sp_raise_alert('critical','D2','connector_sanity', <one-line message with prior_nav/today_nlv/pct_change>, <JSON>)`, create a `[Claude] ATTENTION — D2 halted (connector sanity)` calendar event, and `CALL ops.sp_log_run('D2', <today>, 'halted', …, error_msg=<message>)`. **Why this exists:** the cash tripwire below catches a small unreconciled residual; it does not catch a connector returning a wholesale-wrong NLV (stale snapshot, misplaced decimal, a corporate action the connector mis-marked) whose sheer size would otherwise sail through the ~$1 residual check and cascade silently into `ops.account_snapshot`, the weekly email's TWR figures, and — per PER-STRATEGY PERFORMANCE MAINTENANCE below — the deployed-TWR engine's drawdown gate. Trust the connector's day-to-day story, not any single number, unverified.
- **Staged-order registry reconciliation (`state.open_orders`; run after fill reconciliation, before the §13 cash steps so reservations are current).** This is the durable persist-and-wait sweep (Operating_Protocols.md §11) — it iterates a queryable list, not the between-sessions-empty live-order endpoints, so a staged entry/exit can never be silently dropped. For each still-`pending` `ORDER_STAGED` row: **(a) filled** — if a fill reconciled above matches it (ticker / `contract_id` / side), set the row terminal by inserting a `queue_events` row (`queue='ORDER_STAGED'`, same `item_key`, `status='filled'`); the `position_events` OPEN/CLOSE + decision were already written in the fill loop. **(b) window still open + unfilled** (`entry_window_close >= today` MT) — re-craft it as a fresh DAY instruction: re-pull `get_price_snapshot`, hold the thesis's disciplined limit (or re-price to the live market if the thesis warrants — never chase past the documented rest level), `create_order_instruction`, write a new `ORDER_STAGED` `pending` row with the updated `payload.instruction_id` (same `item_key`), and create/repair the 07:00-MT confirm event. **(c) window closed + unfilled** (`entry_window_close < today`) — set the row terminal `expired` and **`CALL ops.sp_log_decision(...)`** recording the missed entry/exit (the `conservative_default` outcome). A row's reserved cash (next bullet) stays earmarked until it is terminal, so an entry cannot be de-funded while its window is open; a row leaves the registry only by a fill or a logged terminal decision. (Staging a NEW entry/exit — Step 1 GO, or Weekly/Monthly — writes the `pending` `ORDER_STAGED` row at the same time the instruction + confirm event are created; see the staging steps below.)
- **Cash/SGOV balance reconciliation — tripwire (run every time, before any sizing/staging; full procedure Operating_Protocols.md §13).** Compute expected SGOV shares + cash = Σ the per-strategy SGOV-share allocations and cash residuals from `analytics.account_reconciliation` (+ `state.sgov_reconciliation` for SGOV shares); compare to live SGOV shares (`get_account_positions`, SGOV contract_id 424099317) + live cash (`get_account_balances`), netting out commissions/realized-P&L of fills reconciled above. Attribute every non-zero residual per the §13 decision-tree — dividend/interest → owning strategy or pro-rata by SGOV share; deposit/withdrawal → equal-split; standalone fee → equal-split; commission-on-fill → trading strategy (already counted); operator SGOV-sale-to-cover-negative-cash → the strategies whose commissions created the deficit; genuinely unexplained → log + flag + conservative hold, never silently absorb. Find causes with `get_account_trades`, `get_price_history(include_corporate_actions: true)`, and net-liq-vs-Deposit-History. A residual that stays UNEXPLAINED and exceeds ~$1 is a hard STOP — resolve it before sizing or staging. On that hard STOP, also `CALL ops.sp_raise_alert('critical','D2','cash_tripwire', <one-line message>, <JSON: residual, connector evidence>)` AND create a `[Claude] ATTENTION — D2 halted (cash residual)` calendar event, plus `CALL ops.sp_log_run('D2', <today>, 'halted', …, error_msg=<message>)` — routine chat is unmonitored, so an unexplained halt must reach the operator via the alert sink + calendar (Operating_Protocols.md §13.A.4). Reconcile the per-strategy SGOV/cash allocation in the events-side state (`events.position_events` / `state.sgov_reconciliation`, surfaced via `analytics.account_reconciliation`) to the connector truth.
- **Cash flattening — auto-craft the SGOV sweep/cover (Operating_Protocols.md §13.E).** **ORDER-GUARD CHECK (self-improvement audit B-2-exec) — before calling `create_order_instruction` below, `SELECT * FROM analytics.fn_order_guard('<strategy or NULL for account-level>', '<BUY|SELL>', <qty>, <limit_price>, <last_price>, TRUE)` (the final `TRUE` = `is_sgov`). If `passed = FALSE`, do NOT craft the order — `CALL ops.sp_raise_alert_once('critical','D2','order_guard_block', <reasons joined>, <JSON>)` and skip this sweep/cover for the session instead.** After the tripwire/attribution above, on **settled** cash: `free_cash = settled_cash − Σ reserved_cash from state.open_orders` (the durable staged-order registry — authoritative even between sessions when an earmarked entry's DAY order is not live; plus any live unfilled BUY in `get_account_orders`/`get_order_instructions` not represented there). This registry-based reservation is what stops a sweep from de-funding a staged entry mid-window (the 2026-06-08 MDT case). **Sweep** if `free_cash ≥ +$25` → craft BUY SGOV sized DOWN `floor_to_4dp((free_cash − ~$0.35 comm)/ask)` (can't overdraw; never sweeps cash a pending buy needs). **Cover** if `settled_cash ≤ −$5` (a *realized* debit — covers only what actually filled; does NOT pre-fund a resting limit buy) → craft SELL SGOV sized UP `ceil_to_4dp((|settled_cash| + ~$0.35 comm)/bid)`, capped at SGOV held (clears the debit; no margin left). Otherwise no action (a $0…−$5 debit is left on margin; commission to cover it isn't worth it). Order: contract_id 424099317, TIF **DAY** (§11), marketable limit (ask/bid) or MARKET; record instruction `id` + a 07:00 confirm event + an SGOV Parking Activity row; attribute to the owning strategy(ies) per §13.C so Σ per-strategy SGOV = connector SGOV and Σ per-strategy cash ≈ $0. Never sweep cash a pending buy needs.
- Note still-working / partial orders from `get_account_orders` (e.g. a DAY order not yet filled this session, or any legacy/operator-placed GTC still working) and leave them exit-pending / ORDER-STAGED. The persist-and-wait re-craft of an expired-but-still-intended order is handled by the staged-order registry reconciliation above (and mirrored by D3), driven off `state.open_orders` rather than the live-order endpoints (which are empty between sessions under the DAY-only policy, §11).
- For any crafted instruction in `get_order_instructions` whose order day has passed unconfirmed, or whose position Step 0 just closed, call `delete_order_instruction` to clear it.

STEP 0b — ACCOUNT SNAPSHOT (run after Step 0, while connector account data is fresh; one INSERT, best-effort). Persist the account-level NAV/cash/TWR you already read in Step 0 so the weekly self-email and account-NAV history have it — the Apps Script emailer (`ops/weekly_report/`) cannot reach IBKR, so D2 is the only writer. Pull `get_pa_performance_all_periods` and take the LAST element of each period's `cps` array (cumulative TWR fraction at the period end). `INSERT INTO ops.account_snapshot (snapshot_date, nav, total_cash, buying_power, available_funds, gross_position_value, sgov_market_value, twr_1d, twr_7d, twr_mtd, twr_ytd, twr_1y)`: today (America/Denver from `state.trading_day_today`); `net_liquidation`/`total_cash_value`/`buying_power`/`available_funds`/`gross_position_value` from `get_account_summary`; the SGOV market value from `get_account_positions` (contract_id 424099317); and `twr_1d/7d/mtd/ytd/1y` from the cps arrays. One row per `snapshot_date` (latest ingest wins via `state.account_latest`); if today's row already exists, skip. Wrap best-effort so a snapshot failure never aborts D2 — it feeds a report, not trading. (`bigquery/14_weekly_report.sql`.)

PER-STRATEGY PERFORMANCE MAINTENANCE (deployed-TWR engine; run after fill reconciliation above, daily, while connector marks are fresh). **The authoritative engine is the BigQuery value-weighted daily TOTAL-return TWR** (project `stock-trading-498512`: `events.daily_marks` → `analytics.strategy_daily_returns` + `analytics.sgov_daily_return` → `perf.strategy_daily` → `perf.kill_flags`; method in bigquery/03_twr_engine.sql + Operating_Protocols.md §14). The deployed-TWR / drawdown / gate state lives entirely in `perf.strategy_daily` (the former Portfolio_Ledger.md Performance block was a human-readable mirror of this row — retired 2026-06-06; `perf.strategy_daily` is now the sole record, not a separate hand-computation). Requires the BigQuery MCP connector (`execute_sql` / `execute_sql_readonly`).
1. **Ingest today's marks (TOTAL-return source).** For each held ticker + SGOV, pull `get_price_history(include_corporate_actions: true)` and `INSERT INTO events.daily_marks (mark_date, ticker, close, dividend, split_ratio, source)`: today's close, any ex-div cash dividend per share, split_ratio (prices split-adjusted at ingest), and `source='connector'`. Dividends on held stocks (material for D's multi-month holds) and SGOV's monthly DRIP income are captured HERE — a price-only mark silently drops them. Idempotent on (mark_date, ticker).
   - **FMP fallback (single-connector dependency mitigation — 2026-06-28 #12).** The engine's ENTIRE input is `get_price_history`, with no documented fallback. For each held name: if `get_price_history` returns no bar — or a bar older than `state.trading_day_today.last_trading_day` (the prior-close-lag guard) — fall back to the **FMP connector** (`mcp__FMP__quote` for the close; `mcp__FMP__chart` to confirm the dated bar / ex-div) and INSERT the row with `source='FMP-fallback'` (the `events.daily_marks.source` column already exists — `bigquery/03_twr_engine.sql`; do NOT invent a new column). Prefer IBKR when present (FMP ex-div timing may differ). Wrap the FMP path best-effort so an FMP hiccup never aborts D2 (it feeds the engine, not an order). If a systematic per-name IBKR gap appears, `CALL ops.sp_raise_alert('warning','D2','mark_gap','<ticker> mark missing from IBKR; used FMP fallback','<JSON>')` so it is visible.
   - **Per-name completeness check (close the per-TABLE blind spot).** `state.freshness` checks only `MAX(mark_date)` over the whole table, so it cannot see ONE held name silently missing its mark within an otherwise-fresh run (the held-stock `r_deployed` side lacks the forward-fill completeness guard the SGOV benchmark side already has in `03_twr_engine.sql`). After ingest, assert every OPEN position (`state.current_positions`, ex-SGOV) has a `state.daily_marks_curated` row for `last_trading_day`. On a gap that neither IBKR nor FMP filled, do NOT silently skip — carry the prior mark forward explicitly (mirroring the SGOV forward-fill) AND `CALL ops.sp_raise_alert('warning','D2','mark_gap', ...)`. The standing CI detector is the dbt test `dbt/tests/assert_open_positions_have_marks.sql`.
2. **Recompute the engine + embed (one call).** After the marks are in, **`CALL ops.sp_daily_refresh()`** (bigquery/08_ops_procedures.sql) — it runs `ops.sp_recompute_engine()` (a state-free `DELETE`+`INSERT` that rebuilds the full `perf.strategy_daily` series from `events.daily_marks` + the views) **and** `ops.sp_embed_pending()` (catches up any decision embeddings) in a single idempotent call. (Single-source: the recompute SQL lives only in the procedure now, not copy-pasted per run.) The recompute chains `deployed_unit_value ×= (1 + r_deployed)` (value-weighted daily TOTAL return, **GROSS of commissions** — the profitability metric per Operating_Protocols.md §14 "Commission policy": entry baseline = market cost, exit = gross proceeds, dividends in the numerator; commissions are excluded as a scale artifact of ~$30 positions but tracked EXACTLY in the cash/NAV accounting); `peak` = high-water mark vs the 1.000 inception base; `sgov_index ×= (1 + r_sgov)` from SGOV's ACTUAL close+dividend total return; then `excess`, `deployed_days`, and `closed_trades`/`gate_n` from reconciled CLOSE events. The full recompute is trivially cheap (~30 deployed days × active strategies) and absorbs any late mark/fill correction, so D2 re-runs it wholesale rather than appending one row. A strategy fully in SGOV all day contributes no row (indices pause). `perf.kill_flags` then reads the latest row.
3. **Verify the engine row (no ledger to mirror).** After the recompute, the engine's latest `perf.strategy_daily` row (`deployed_unit_value`, `peak_unit_value`, `current_drawdown`, `sgov_index`, `excess`, `deployed_days`, `closed_trades`, `gate_status`, `as_of` = today MT) IS the record — there is no Portfolio_Ledger.md Performance block to copy it into (retired; the Monthly-snapshots history lives in the `perf.strategy_daily` series itself). **The legacy hand-computation is RETIRED** — the engine was validated 2026-06-05 by a full rebuild from the connector's authoritative fills + real daily marks and independently hand-checked to within 0.04% on D, so it stands alone. The guardrail is automated, not a manual re-compute: trust `perf.strategy_daily`, but flag in chat if a day's `r_deployed` exceeds ±15% or `deployed_unit_value` leaves (0.3, 3.0) absent a matching large market move — those signal a bad mark or an unreconciled fill, not real performance.

**SEEDING A NEW STRATEGY (block still `[n/a]` — A/C/E on first deployment).** Seed via the **value-weighted daily method ONLY**: backfill `events.daily_marks` over the strategy's deployed days and let the engine compute `perf.strategy_daily` forward from inception. **Do NOT seed by sequentially chain-linking realized closed-trade returns** (`Π (1 + realized_pnl/cost_basis)`) — those trades are CONCURRENT, independently-funded ~2%-of-sleeve bets, so chaining them as sequential reinvestment manufactures compounding that never occurred and compounds only the winners while open losers enter as a single drag. **That anti-pattern overstated Strategy B's 2026-06-04 seed to 1.1099/+11%; the validated GROSS value-weighted figure (the profitability metric) is ≈ 1.0005/+0.05% (net-of-commission 0.966).** B and D are populated + validated in `perf.strategy_daily`. `gate_status = pre-gate`; set `deployed_days`/`closed_trades` from trade history.

STEP 1 — DRAIN PENDING ANALYSES (run after Step 0). Read due items from `state.open_queue` / `state.open_queue_detail` (queue `PENDING_ANALYSIS`). For every entry with `status: pending` and `due_date <= today` (America/Denver), perform the analysis in-session — each as an isolated sub-task (subagent) for fresh context where available, else inline sequentially. This is where deferred thesis constructions, scheduled re-screens, research-deferral checkpoints, foundation-change assessments, and constraint-relaxation reviews actually run. For each entry: do the full analysis per its `context` (apply the relevant Strategy.md criteria, Operating_Protocols.md rules, B_Sub_Pattern_Taxonomy.md, connector live data §11); write the decision via `CALL ops.sp_log_decision(...)` (`events.decision_log`) and, if a position changes, the lifecycle event to `events.position_events`; for a GO, craft the order instruction and create the `[Claude] Confirm order` event (per the staging steps below); set the entry `complete` with its `outcome` (insert a terminal-status row to `events.queue_events`). If the required data is still unavailable on the due_date, apply the entry's `conservative_default` (skip / decline / exit) and mark complete — do NOT re-defer (deferrals do not chain).

Then read the just-saved `Daily.md` (today's market development scan; first line = today's date in YYYY-MM-DD format).

**Cross-check the machine-readable action block (added 2026-07, robustness).** Parse the fenced ```yaml d1_actions``` block Daily.md carries after its prose RECOMMENDED ACTIONS section. Count the prose bullets (by category: exits / new candidates / watchlist updates / router reviews) and compare to the block's entry count. On a mismatch (or a missing/unparseable block on a Daily.md that isn't the pre-2026-07 format): treat it as a corrupted upstream, same handling as the upstream-freshness gate — `CALL ops.sp_raise_alert('critical','D2','missing_dependency','D1 prose/d1_actions count mismatch — <N prose vs M block entries>','<JSON>')`, create a `[Claude] ATTENTION` event, log the run `'halted'`, and ABORT before converting anything. This catches a bullet a prose-only parse would have missed or double-counted BEFORE it becomes a missed exit or a fabricated order. When they agree, use the block's structured fields (ticker/strategy/action) to drive the conversion below — the prose stays the reference for WHY (rationale, criteria) but the block is what removes ambiguity on WHAT and HOW MANY.

Convert every bullet in Daily.md's "RECOMMENDED ACTIONS" section into operator-actionable outputs per the operating model at the top of this file. Claude resolves all decisions internally; commissions are disregarded at staging time.

If Step 0 reconciled no new fills AND Daily.md "RECOMMENDED ACTIONS" reads "No recommended actions": output "No actions required." and end. (If Step 0 reconciled fills but there are no new Daily.md actions, report the reconciliation per chat-output discipline and end.)

For each recommendation type:

1. EXITS TRIGGERED. For each exit flagged:
   - Read Strategy.md exit rules and the position's entry-record invalidation criteria from `events.decision_log` (or the `state.current_positions` / `events.position_events` entry-record) to confirm the criterion is in fact met. If on review the criterion is NOT met, do not stage the exit; record the second-look decision via a brief `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) instead.
   - If confirmed: craft the exit order via the IBKR connector. Resolve `contract_id` (cached in the IBKR connector usage section's contract_id list, else `search_contracts`); pull `get_price_snapshot` and set the limit — for stocks a marketable limit (sell at a slight discount to last) unless the invalidation logic favors patient execution, or MARKET when assured exit is the objective; Day duration unless thesis logic requires GTC. **ORDER-GUARD CHECK (self-improvement audit B-2-exec) — before calling `create_order_instruction`, `SELECT * FROM analytics.fn_order_guard(<strategy>, <side>, <qty>, <limit_price>, <last_price>, FALSE)`. If `passed = FALSE`, do NOT craft — `CALL ops.sp_raise_alert_once('critical','D2','order_guard_block', <reasons joined>, <JSON>)` and treat this exit as un-stageable this session (retry next run; the invalidation/exit intent itself is unchanged, only the crafted order is blocked).** Call `create_order_instruction(...)` and capture `{id, url}`. (Options legs: connector cannot craft — fall back to a manual-entry text block at mid of current bid/ask.)
   - Write an `events.decision_log` entry (`CALL ops.sp_log_decision(...)`) recording: triggering development, specific invalidation criterion met, position exit decision, conviction-calibration notes per the conviction-calibration ladder.
   - Mark the position exit-pending with an `events.position_events` row carrying the staged order details and the crafted instruction `id` (there is no Portfolio_Ledger.md to update).
   - **Write the `pending` `ORDER_STAGED` row to `state.open_orders`** (Operating_Protocols.md §11 staged-order registry): an `INSERT INTO events.queue_events` with `queue='ORDER_STAGED'`, a stable `item_key`, and a payload carrying `side`/`qty`/`limit_price`/`contract_id`/`instruction_id`/`source_decision_ref` and the exit deadline as `due_date`. This is what keeps the resting DAY exit alive across sessions (Step 0 registry reconciliation) instead of letting it lapse when the DAY order expires.
   - Schedule a "[Claude] Confirm order — <ticker> SELL" calendar event for **07:00 MT pre-market on the order day**. Description: the `SIDE QTY TICKER TYPE LIMIT TIF` summary, the tap-to-confirm deep link (`url`), the instruction `id`, and "Tap the link, review the pre-filled order in IBKR, confirm at or after market open." (Options / other non-craftable exit: no `url` — carry the explicitly-labeled manual-entry text order block in the event description in place of the deep link.) No fill-capture event — the fill is reconciled by Step 0 on the next daily run.

2. NEW ENTRY CANDIDATES. For each candidate flagged, determine the earliest the thesis can run, from Strategy.md per the candidate's strategy:
     - Strategy B: 10 trading days from event — doable as soon as the Day-0 close-to-close is measurable (often the same evening; if the Day-0 close lands a later session, that close is the earliest-doable date).
     - Strategy C: catalyst within 45 days — runs in the pre-catalyst window (7-10 days before the catalyst when it is >14 days out; otherwise now).
     - Strategy A: catalyst within 6 months — respect router state. If A is DO-NOT-ACTIVATE per `state.current_regime` / most-recent M1 call, the candidate goes to Watchlist.md A queue (no thesis now). If ACTIVATE, the thesis is doable now.
     - Strategy E: pair divergence — normally handled by M2/M4; a fast-moving divergence may run now.
   - **If the thesis is doable now** (required data available; router admits it): perform the full thesis construction **in-session** — an isolated sub-task (subagent) per candidate for fresh context where available, else inline sequentially. Apply Strategy.md entry criteria, the Operating_Protocols.md "NO-GO records are context, not barriers" rule + conviction-calibration ladder, B_Sub_Pattern_Taxonomy.md, commission-disregarded staging, and the connector for live quotes / CTC / eligibility (§11). **OUTCOME-ANNOTATED PRECEDENT REVIEW (self-improvement audit S-6, 2026-07-03) — mandatory before the GO/NO-GO call:** call `analytics.find_precedents(<candidate context text>)`; each returned row now carries the precedent's realized outcome (`position_closed`, `was_profitable`, `thesis_realized_pnl` for a prior thesis; `nogo_excess_return_vs_sgov` / `nogo_was_correct_long_framing` for a prior NO-GO) alongside its conviction tier's shrunk posterior + Wilson interval (`tier_win_rate_shrunk`, `tier_wilson_low/high`, `tier_trustworthy_edge`). Explicitly reason, in the thesis write-up, about whether this candidate resembles precedents that WON or LOST net — and ALWAYS state the tier's interval width alongside any precedent outcome cited, so a handful of salient wins (or losses) cannot be read as more informative than the honest-wide estimate permits (`tier_trustworthy_edge=FALSE`, which is true for every tier today, means: weight the precedent evidence as directional, not decisive). Write the decision (GO or NO-GO) via `CALL ops.sp_log_decision(...)` (`events.decision_log`) and, on a GO, the OPEN lifecycle event to `events.position_events`; craft the order instruction — **ORDER-GUARD CHECK (self-improvement audit B-2-exec) first: `SELECT * FROM analytics.fn_order_guard(<strategy>, 'BUY', <qty>, <limit_price>, <last_price>, FALSE)`. If `passed = FALSE`, do NOT craft — `CALL ops.sp_raise_alert_once('critical','D2','order_guard_block', <reasons joined>, <JSON>)`, record the GO decision as staged-but-blocked in `events.decision_log`, and do not write an `ORDER_STAGED` row this session (re-evaluate next run — a guard block on a GO thesis is itself signal worth a second look, not just a retry).** **write the `pending` `ORDER_STAGED` row to `state.open_orders`** (Operating_Protocols.md §11 staged-order registry — payload: `side`/`qty`/`limit_price`/`contract_id`/`convergence_target`/`time_exit_date`/`instruction_id`/`source_decision_ref`; `due_date` = entry-window close), and create the `[Claude] Confirm order` event per the staging steps above. The registry row is what makes the entry a durable, daily-re-crafted persist-and-wait order whose earmarked cash §13 reserves until it fills or is terminally resolved. No calendar thesis event, no human paste.
   - **If the thesis must wait for future data** (a Day-0 close not yet in; a Strategy C pre-catalyst window): enqueue a `PENDING_ANALYSIS` entry (`INSERT INTO events.queue_events`; analysis_type: thesis-construction; due_date = earliest-doable date; self-contained `context`; `conservative_default` = decline/skip). D2 drains it on its due_date.
   - For Strategy A candidates that should queue rather than proceed: update Watchlist.md A-queue section with ticker, date-added, reason summary, resolution-trigger ("next M1 with A router ACTIVATE").

3. WATCHLIST UPDATES. For each add/remove/demote flagged:
   - Apply the change directly to Watchlist.md (creating it if absent — first line `# Watchlist`, sections per strategy as needed).
   - Per add: ticker, date-added, source-Daily-date, reason summary, resolution-trigger.

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

# Claude Task Plan

This document is the master reference consumed by Claude remote routines. Each routine's instruction is the single line:

> Read Claude_Task_Plan.md. Perform <task ID + name>.

Claude reads this file at the start of every routine run, locates the matching `## <ID>. ...` section, and executes the prompt body inside that section. Section IDs (D1, D2, W1, ..., A3) are stable; routine names mirror them.

---

# OPERATING MODEL

## Execution environment

Claude runs as scheduled routines connected to a GitHub repo (currently `JackOfSpade/Stock-Trading`) and to Google Calendar via MCP. Inside a routine Claude has:

- **Direct read/write access to repo .md files.** Live state files (Decision_Log.md, Portfolio_Ledger.md, Watchlist.md, Operating_Protocols.md, Regime_State.md) are edited in place. Cadence-output files (Daily.md, Weekly_*.md, Monthly_*.md, Quarterly_*.md, Annual_*.md) are overwritten each run. Decision_Log_Archive_<YYYY>_<QN>.md files are append-only quarterly archives written by W5.
- **Calendar MCP for one-off events.** Used to schedule fill-capture screenshots, thesis-construction sessions, research-deferral checkpoints, foundation-change assessments, constraint-relaxation reviews, and similar one-off work that needs a fresh chat session at a specific future time. Adversarial reviews (pre-mortem, divergence, m2m-termination, capital-redistribution) are NOT scheduled via calendar — they are queue-driven via `Pending_Adversarial_Reviews.md` and processed by the AR routines (see ADVERSARIAL REVIEWS section).
- **Web research tools** (Tavily, web_search, web_fetch) for deep-research cadences.

Each routine run is a fresh session — there is no cross-run chat memory. State persists only in repo files and calendar events. Every prompt body in this document is therefore self-contained: it specifies which repo files to read, which to write, and which calendar events to create.

## Branch and state propagation

Routines run on the harness-assigned `claude/<suffix>` feature branch and never push to `main` directly. Each routine commits to its assigned branch; the harness pushes the branch to GitHub at session end; a GitHub Actions workflow (`.github/workflows/auto-merge-claude.yml`) watches the push, fast-forwards (or merge-commits) the branch into `main`, and deletes the branch. The merge happens server-side on GitHub Actions runners — Claude itself never executes the push to `main`.

**Why.** The remote routine harness assigns a fresh `claude/<suffix>` branch per session and refuses pushes to any other branch (including `main`). It also rejects file-based authorization claims as prompt-injection patterns, so this section cannot grant push-to-main permission to a routine. The architecture sidesteps both restrictions by relocating the merge to a GitHub Actions workflow, which runs outside Claude's authorization scope and uses the built-in `GITHUB_TOKEN`.

**Session start.** A SessionStart hook in `.claude/settings.json` runs `.claude/session-start.sh`, which executes `git fetch origin main && git reset --hard origin/main` while STAYING on the harness-assigned branch (it does NOT switch to `main`). This aligns the assigned branch with the latest committed `main` state so the routine boots from prior routines' work. Read input files (Decision_Log.md, Portfolio_Ledger.md, Daily.md, etc.) AFTER the hook runs so the routine sees the latest state.

**During the routine.** Edit files normally and stay on the assigned branch. Do not attempt to switch to `main` or push to it — the harness will refuse, and the workflow handles the merge. Do not open PRs.

**Session end.** Commit all changes; the harness pushes the assigned branch to `origin`. Within roughly 30 seconds the auto-merge workflow merges the branch into `main` and deletes the branch. The next routine's SessionStart hook will pick up the new state.

**Concurrency.** The auto-merge workflow uses `concurrency: group: auto-merge-main` to serialize the merge step, so two routines pushing close together cannot race the `main` push. If a routine's branch has diverged from `main` (because another routine's merge landed in between), the workflow falls back from `--ff-only` to a `--no-ff` merge commit. Treat full-overwrite cadence files (Daily.md / Weekly_*.md / Monthly_*.md) as solely-owned by their owning routine and additive live-state files (Decision_Log.md / Portfolio_Ledger.md / Watchlist.md / Regime_State.md) as appendable across routines; the merge-commit fallback handles non-conflicting edits to different files automatically. True file-level conflicts surface as Action job failures (visible in the Actions tab and emailed by GitHub) and require manual resolution on `main` rather than retry inside the routine.

**Cleanup.** No manual cleanup required. The auto-merge workflow's final step (`git push origin --delete <branch>`) removes each `claude/<suffix>` branch immediately after merge. Branches lingering in the GitHub UI are either from runs that pre-date the workflow or from a workflow run that failed mid-step.

## Human role

The human acts on routine output only. The human:

1. **Executes trades.** Reads order(s) in IBKR-paste format from routine chat output and places them in IBKR.
2. **Pastes calendar-triggered prompts** into a fresh Claude chat at trigger time. This is the path for one-off events that need a fresh session — most importantly screenshot capture, where the chat session takes screenshots as input and writes Portfolio_Ledger.md from them.
3. **Pastes IBKR screenshots** when prompted by a calendar event (typically end-of-day on order days, or on-demand when the human wants to reconcile state).

The prior protocol's "action 4 — persist Claude-produced files" is **obsolete**. Claude writes files directly. Claude does not present file contents in chat as fenced code blocks; chat output is reserved for orders and brief acknowledgments.

The human does NOT perform any analytical or monitoring task. If the framework needs analysis, monitoring, parsing, watching, verification, or calculation, Claude does it — either inline in the current routine or via a calendar-triggered fresh session at the appropriate time. Examples of work the human does NOT perform: verifying commissions; making EV decisions; monitoring markets intraday; parsing earnings prints; deciding execute-vs-skip on staged orders; deciding override-vs-honor on NO-GO recommendations; choosing convergence targets, position sizes, limit prices, or invalidation criteria.

If a workflow would require the human to do anything beyond the three actions above, that workflow is broken and Claude must redesign it before staging anything.

## Decision discipline

Claude resolves every decision the framework requires — execute or skip, GO or NO-GO, target selection, sizing, timing, invalidation criteria, marginal-conviction-but-criteria-cleared cases — without human input.

A decision is resolved by the framework's criteria. Any setup that mechanically clears all entry criteria stages automatically, regardless of conviction level. Strategy.md criterion 4 already requires "no decisive flaw," not "high conviction"; conviction is an internal calibration metric persisted to Decision_Log.md but is not a separate gate. The HCA precedent (~45–50% conviction, all criteria cleared, staged) is the canonical handling: if criteria clear, stage with conviction noted; if a criterion fails, decline. There is no middle category requiring human adjudication.

If a decision genuinely cannot be made without information Claude does not have, Claude defers to a future routine or calendar-triggered session where the missing information will be available. Deferral constraints:

- Each deferral specifies (a) the trigger that resolves it (specific date and information source), and (b) the default action if the trigger fails to resolve it.
- The default action on trigger-failure is always the conservative branch (skip the trade, decline the GO, exit the position) — never another deferral. This biases the system toward reducing exposure on uncertainty, which is intentional given that the human is not available to adjudicate.
- Deferrals do not chain. A decision deferred from session 1 to session 2 either resolves in session 2 or hits the conservative default. It cannot be re-deferred to session 3.

## Commission policy

Commissions are NOT factored into staging-time GO/NO-GO decisions, target selection, sizing, or EV computation. Commissions are accepted as a fixed business cost. Implications:

- Thesis construction does not produce "EV at design size" calculations net of commissions.
- Decision_Log entries do not document "negative-EV-at-design-size acknowledgment" sections.
- Staged orders are not annotated with EV-at-order-ticket caveats.
- The strategy-level edge-decay metrics (EV per trade in Strategy C and D pre-mortems) continue to function as designed; they measure realized P&L which already nets commissions out empirically.
- Commission paid is captured per-trade in Portfolio_Ledger.md at fill, for after-the-fact accounting and 30-trade-gate calibration. It does not enter pre-trade decisions.

## Calendar MCP usage

The calendar is exclusively for **one-off [Claude] events** — events that need a fresh chat session at a specific future time. Recurring cadence work (D1, D2, ..., A3) runs as routines and is NOT placed on the calendar.

Conventions for one-off events Claude creates:

- **Title:** `[Claude] <task short name>` so events are scannable.
- **Time:** scheduled to the moment the human needs to act (e.g., end-of-day on order day for a fill-capture screenshot; pre-market for a thesis-construction session; etc.).
- **Description:** contains a single self-contained prompt the human pastes into a fresh Claude chat. The prompt references the relevant project files Claude will need.
- **Time zone:** per Experiment_Parameters.md (default America/Denver if silent; note the assumption inline if defaulted).
- **Notification:** alarm fires at event-time so the human's only job is to respond.

Canonical one-off-event types and triggers:

- **Fill capture** — scheduled after every staged order's expected fill window (typically end-of-day on the order day). Description instructs the human to screenshot IBKR positions and orders pages and paste both into a fresh Claude chat with the prompt text. The triggered Claude session reads the screenshots, updates Portfolio_Ledger.md directly, and acknowledges in chat.
- **Thesis construction** — for new-entry candidates that cleared the screening cadence (W4 schedules A/B/C; M5 schedules E pairs; Q4 schedules D candidates). Description includes ticker, strategy, candidate context, and references to Strategy.md / Operating_Protocols.md.
- **Research deferral checkpoint** — for positions flagged "further research" by W3/M4. Description includes the specific information gap, reference to Strategy.md exit rules, and the conservative-default fallback (exit on trigger-failure).
- **Foundation-change assessment** — scheduled by Q4/A3 per strategy, for material AI-foundation revisions affecting that strategy.
- **Constraint-relaxation review** — scheduled by A3 for out-of-table constraint flags.
- **Router review** — scheduled by D2 for inter-monthly router-state revisits when Daily.md flags a material regime shift.

## Chat output discipline

Routine chat output to the human contains only:

1. The order(s) to execute, in exact IBKR-paste format (or `no order`), grouped by execution day if more than one.
2. A one-line acknowledgment of file writes performed and calendar events created (e.g., `Decision_Log.md, Portfolio_Ledger.md updated. 2 calendar events scheduled.`).
3. If applicable, a short flag for any high-urgency item the human should be aware of when checking IBKR (e.g., "Flagged: AAPL exit limit set 1% below last close; reconsider if quote moves").

Routine chat output does NOT contain:

- Recapitulation of decision reasoning (lives in Decision_Log.md)
- File contents inside fenced code blocks (Claude writes files directly)
- "→ Filename.md (replace)" annotations (the persistence path is gone)
- Adversarial-review summaries
- Pillar/criteria walkthroughs
- "Three things to flag" / "two things to note" framings
- Pending-queue summaries beyond what affects the human's next action
- Theater-checks
- Compaction-survival notes (these belong in Decision_Log.md, not chat)
- Explanations of why a NO-GO is a NO-GO when no human action is required
- Operator-override paths when the recommendation is NO-GO

If a routine has no orders, no file changes, and no events: state `No actions required.` and end.

## Self-check before composing chat output

Claude performs the following checklist in thinking blocks before composing every routine's chat output:

- [ ] Have I created any task for the human beyond reading an order, pasting a calendar prompt, or pasting a screenshot?
- [ ] Have I asked the human to make any decision?
- [ ] Have I included file contents in chat (fenced code blocks, "attached files," etc.) when the file should have been written directly?
- [ ] Have I deferred a decision to "human's call" that I should have resolved myself?
- [ ] Have I factored commissions into a staging-time decision?
- [ ] Have I scheduled a fill-capture screenshot event for any staged order?
- [ ] If I deferred a decision, have I specified its resolution trigger and conservative-default fallback?

If any answer reveals a violation, the response gets revised before sending.

---

# FILE CONVENTIONS AND READ-ACCESS SCOPE

## Decision-log lifecycle and archive policy

`Decision_Log.md` is the LIVE decision log — entries that are still operationally relevant (open positions, active deferrals, current protocol revisions, recent dispositions within retention windows). Pruned weekly by W5.

`Decision_Log_Archive_<YYYY>_<QN>.md` files contain matured entries from prior periods, organized by quarter (e.g. `Decision_Log_Archive_2026_Q2.md`). One file per quarter; appended throughout the quarter as W5 archives matured entries; closed at quarter-end.

`B_Sub_Pattern_Taxonomy.md` is the canonical reference for Strategy B criterion-4 NO-GO sub-patterns, extracted from individual Decision_Log NO-GO entries by W5. Thesis-construction sessions read this file rather than scanning scattered NO-GO entries for sub-pattern context. (Analogous per-strategy taxonomy files may be created later if other strategies accumulate enough sub-pattern data to warrant extraction.)

`Watchlist.md` is a factbase tracking names queued for re-evaluation under specific conditions. Living document; read by all cadences; written by D2/W4/M5 (action-conversion routines) and W5 (mirroring). Sections per strategy. Currently the only structurally-needed section is **Strategy A queue** (names awaiting router-activation re-evaluation — populated by router-gate NO-GO sessions, drained by M5 sessions when A router flips ACTIVATE). Strategy D pending re-screens are tracked in calendar events (canonical source); Strategy B prior-NO-GOs are not queued because B operates on event-flow with fresh-evaluation discipline (sub-pattern factbase preserves the durable signal). Sections may be added as other strategies surface persistent queue needs.

`Operating_Protocols.md` is the canonical reference for active operational protocols (the operating-model section of this file in current canonical form, commission-disregarded protocol, "NO-GO records are context, not barriers" rule, conviction-calibration ladder, deferral chaining rules, etc.). Living document; read by all cadences. Each protocol section contains current canonical text plus a revision-history pointer list. When a protocol is revised, the new revision text replaces the canonical section and a new entry is added to revision history pointing to the Decision_Log entry that introduced the revision.

When an entry is archived, the live Decision_Log.md replaces the moved-out section with a single-line pointer:

`# [archived] <YYYY-MM-DD> <title> → Decision_Log_Archive_<YYYY>_<QN>.md`

Future sessions looking up specific historical entries find either the entry or the pointer in the live file.

## Action-conversion routines (deep research → action)

Deep-research routines produce exactly one output file. A research file with recommendations sitting in it is not an action; the human acts only on chat-output orders, calendar event prompts, and screenshot requests, so any recommendation in a research file evaporates at the next overwrite unless something converts it into an order, an edited live file, or a calendar event.

Each cadence with deep-research routines that produce actionable recommendations therefore carries an **action-conversion** routine that runs after all of that cadence's research files are saved. The action-conversion routine reads the just-saved research file(s) and emits orders / live-file edits / calendar events.

Pairing:
- **D2 Daily Action Conversion** — reads Daily.md.
- **W4 Weekly Action Conversion** — reads Weekly_Catalyst_Calendar.md, Weekly_Post_Event_Screen.md, Weekly_Position_Deep_Dive.md.
- **M5 Monthly Action Conversion** — reads Monthly_Fundamental.md (M1b output, which echoes M1a regime scoring in PART 1), Monthly_E_Pairs.md, Monthly_D_Position_Deep_Dive.md.
- **Q4 Quarterly Action Conversion** — reads Quarterly_D_Candidates.md and Quarterly_AI_Foundation_Delta.md (Q1 Quarterly_Regime.md is a pure backward-looking factbase with no actions).
- **A3 Annual Action Conversion** — reads Annual_AI_Foundation_Sweep.md and Annual_Constraint_Audit.md; produces updated AI_Trading_Foundation.md and updated Strategy.md.

Cadence-level hygiene routines (D3 Calendar Hygiene, W5 Decision Log Hygiene) run after action conversion since they reference state mutated by it.

Because each routine run is a fresh session, deep-research routines must persist EVERYTHING the action-conversion routine will need into the cadence-output file. The legacy "PART 1 saved / PART 2 in-chat" split is obsolete — both parts go into the file.

## File-write conventions for routine outputs

Cadence-output files (Daily.md, Weekly_Catalyst_Calendar.md, etc.) are overwritten in full each run. The first line is always a date marker:

- Daily files: `YYYY-MM-DD` (today's calendar date).
- Weekly files: `YYYY-WW` (current ISO week).
- Monthly files: `YYYY-MM` (the month identified by the prompt — typically prior calendar month for retrospective tasks, current month for forward-looking tasks).
- Quarterly files: `YYYY-QN` (the quarter identified by the prompt — prior for Q1/Q3 retrospectives, current for Q2 forward).
- Annual files: `YYYY` (calendar year).

Live-state files (Decision_Log.md, Portfolio_Ledger.md, Watchlist.md, Operating_Protocols.md, Regime_State.md) are edited surgically. Routines apply minimal in-place edits via str_replace or the equivalent; they do not rewrite these files in full unless the prompt explicitly calls for a full rewrite.

Decision_Log_Archive_<YYYY>_<QN>.md files are append-only — W5 adds matured entries to the current-quarter archive; existing archive entries are not modified.

## Read-access scope by cadence

These rules keep the live-file working set bounded for high-frequency reads while preserving full historical access where the cadence justifies the cost.

**Daily and Weekly routines** (D1, D2, D3, W1, W2, W3, W4, W5):
- Read `Decision_Log.md` (live) only.
- DO NOT read or rely on content from `Decision_Log_Archive_*.md` files.
- Cross-strategy factbase files (`B_Sub_Pattern_Taxonomy.md`, `Quarterly_D_Candidates.md`, `Weekly_Catalyst_Calendar.md`, etc.) ARE in scope and should be read as the prompt directs.
- If the live file's pointer indicates an archived entry that the working set genuinely needs (rare), this is a signal that either (a) the lifecycle rules need revisiting or (b) the relevant content should have been extracted to a factbase. Surface it via a Decision_Log entry rather than fetching from the archive.

**Monthly routines** (M1a, M1b, M3, M4, M5):
- May read `Decision_Log.md` and all `Decision_Log_Archive_*.md` files. **Exception: M1a's read scope is restricted by design — see M1a's prompt body. M1b's read scope is restricted to the M1a regime-scoring file as the regime input — see M1b's prompt body.**
- In practice most monthly tasks operate on current open-book state and do not require archive reads. Read archives only when the prompt explicitly directs (e.g., per-strategy thesis-invalidation count for the trailing 36-month window).

**Quarterly routines** (Q1, Q2, Q3, Q4):
- Read `Decision_Log.md` and all `Decision_Log_Archive_*.md` files.
- Q1 (Regime Retrospective) explicitly needs prior-quarter archive content for router history and adversarial review records.
- Q2 (D Long-Horizon Candidates) and Q3 (AI Foundation Delta) reference historical dispositions and prior-cycle outcomes.
- Q4 (Action Conversion) reads only the just-saved Q2/Q3 research files plus live state; archive reads not required.

**Annual routines** (A1, A2, A3):
- Read everything, including all archive files.
- A2 (Per-Strategy Constraint Audit) explicitly traces foundation-citation graphs across full Decision_Log history.
- A3 (Action Conversion) reads only the just-saved A1/A2 outputs plus live state; archive reads not required.

## Shared rules referenced across prompts

**"NO-GO records are context, not barriers."** A prior NO-GO entry on a candidate informs current evaluation but does not pre-empt it. New evidence, new context, new structural conditions can flip a prior NO-GO to GO. The Decision_Log NO-GO entry tells future Claude what to look at, not what to conclude. For Strategy B, sub-pattern taxonomy entries are particularly informative — a candidate matching a documented sub-pattern faces a high bar but is not auto-rejected.

**Conviction-calibration ladder.** Conviction is logged in Decision_Log entries on a coarse scale (e.g., 30%, 45%, 60%, 75%) for after-the-fact calibration analysis. It is not a gate. A 45%-conviction setup that clears all criteria stages; a 75%-conviction setup that fails any criterion declines.

---

# DAILY (after market close)

## D1. Market Development Scan — deep research

```
Read access scope: Daily cadence. Read `Decision_Log.md` (live) only. Do NOT read or act on content from `Decision_Log_Archive_*.md` files. Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction.

Read Strategy.md, Experiment_Parameters.md, AI_Trading_Foundation.md, Portfolio_Ledger.md, Watchlist.md, Operating_Protocols.md, Regime_State.md, Decision_Log.md (live).

Read Portfolio_Ledger.md to identify currently-open positions across Strategies A, B, C, D, E with their entry-record thesis-invalidation criteria. Read Watchlist.md for queued names.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior Decision_Log NO-GO entry.

Produce a daily market development scan and write it directly to `Daily.md` (overwrite; first line = today's calendar date in YYYY-MM-DD format).

Scan general market developments from the prior 30 hours. Cast broadly — do not scope the scan to tickers owned or on the watchlist. The purpose is to surface any development that could either threaten an existing position's thesis or create a new entry opportunity for any strategy, including at names not currently on any list. Do not pad; if a category has no material items, state so.

DEVELOPMENTS

1. Market-wide breaking events. Geopolitical shocks, unscheduled regulatory or enforcement actions, material bankruptcies, disasters, or events materially affecting global risk assets. Per event: what happened, source, observable reaction across equities / rates / commodities / FX.

2. Scheduled events that resolved today (across the US-listed universe with market cap ≥ $2B, not limited to watchlist). Earnings prints (EPS/revenue vs. consensus), FDA PDUFA outcomes, FOMC actions, other resolved catalysts. Per event: outcome, price reaction if observable, source.

3. Large single-name moves. US-listed equities with market cap ≥ $2B that moved ≥5% close-to-close today attributable to identifiable public events. Per name: ticker, move magnitude and direction, event type, source.

4. Sector-level moves. Any GICS sector with a move of ≥2% at sector-ETF level or notable intraday dispersion. Per sector: magnitude, apparent driver, source.

5. Notable commentary. Major sell-side reports issued, regulator or central-bank speeches with market-moving content, senior corporate commentary worth noting.

ANALYSIS — RISK TO EXISTING POSITIONS

For each open position (from Portfolio_Ledger.md), does any Development above trigger any thesis-invalidation exit criterion in the position's entry record (per Strategy.md exit rules for the relevant strategy)? For each position affected: position (ticker + strategy), triggering development, whether the invalidation criterion is met (YES with specific criterion / NO with reasoning).

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

Run AT MOST ONE Hugging Face `paper_search` query per day, rotating across the §6.1 query batteries from `HF_Resource_Catalog.md` on a weekly cycle (e.g., Mon: cross-session consistency, Tue: prompt injection, Wed: calibration, Thu: sycophancy/anchoring, Fri: trading/financial, Sat: multi-agent debate, Sun: long-context). Use `concise_only=true` and `results_limit=5`. Skim only the abstracts of papers published in the prior 24–72 hours. If a result materially bears on a documented `AI_Trading_Foundation.md` disadvantage (Tier 1 architectural change, new failure mode, or contradicts a Tier 2 numerical claim per `HF_Resource_Catalog.md` §2 inverse mapping), append a Decision_Log.md entry tagged `[HF Frontier-LLM Capture]` with the arXiv ID, a one-paragraph summary, and the affected `AI_Trading_Foundation.md` item. Reference-only — D1 does NOT act on the finding today; Q3 reads `[HF Frontier-LLM Capture]` entries during its quarterly delta to surface mid-quarter material deltas. Default is silent on ambiguity. No Daily.md output for this check.

RECOMMENDED ACTIONS

The downstream D2 routine reads this section verbatim and converts each bullet into an order / live-file edit / calendar event, so be specific (ticker, strategy, criterion-cited where applicable):
- Exits triggered (with invalidation criterion and strategy)
- New entry candidates (with strategy) requiring full thesis construction in separate sessions per Strategy.md
- Watchlist updates (adds / removes / demotions)
- Router reviews recommended (with justification)

If nothing material: "No recommended actions."

OUTPUT: write the complete content above directly to `Daily.md` (overwriting the prior day's file). First line is today's date in YYYY-MM-DD format. No chat output beyond a one-line acknowledgment that Daily.md was written.
```

---

## D2. Daily Action Conversion — regular routine

Runs after D1 has written Daily.md. Converts D1's RECOMMENDED ACTIONS into orders, live-file edits, and calendar events.

```
Read access scope: Daily cadence. Read `Decision_Log.md` (live). Do NOT read or act on content from `Decision_Log_Archive_*.md` files. Read `Strategy.md`, `Experiment_Parameters.md`, `Portfolio_Ledger.md`, `Operating_Protocols.md`, `Watchlist.md`, `Regime_State.md`, `B_Sub_Pattern_Taxonomy.md` as relevant.

Read the just-saved `Daily.md` (today's market development scan; first line = today's date in YYYY-MM-DD format).

Convert every bullet in Daily.md's "RECOMMENDED ACTIONS" section into operator-actionable outputs per the operating model at the top of this file. Claude resolves all decisions internally; commissions are disregarded at staging time.

If Daily.md "RECOMMENDED ACTIONS" reads "No recommended actions": output "No actions required." and end.

For each recommendation type:

1. EXITS TRIGGERED. For each exit flagged:
   - Read Strategy.md exit rules and the position's entry-record invalidation criteria from Decision_Log.md (or Portfolio_Ledger.md entry-record pointer) to confirm the criterion is in fact met. If on review the criterion is NOT met, do not stage the exit; record the second-look decision via a brief Decision_Log entry instead.
   - If confirmed: stage the exit order in IBKR-paste format. Limit-price selection: for stocks, use the most-recent close as starting point and adjust to a marketable limit (sells at slight discount to last, buys at slight premium) unless the invalidation logic favors patient execution; for options legs, use mid of current bid/ask if available. Day duration unless thesis logic requires GTC.
   - Append a Decision_Log entry recording: triggering development, specific invalidation criterion met, position exit decision, conviction-calibration notes per the conviction-calibration ladder.
   - Update Portfolio_Ledger.md to mark the position exit-pending with the staged order details.
   - Schedule a "[Claude] Screenshot IBKR — fill capture <ticker> exit" calendar event for the order's expected fill window (typically end-of-day on the order day, prior to next trading session).

2. NEW ENTRY CANDIDATES. For each candidate flagged:
   - Determine entry-window urgency from Strategy.md per the candidate's strategy:
     - Strategy B: 10 trading days from event — high urgency.
     - Strategy C: catalyst within 45 days — medium urgency, scheduling depends on days-to-catalyst.
     - Strategy A: catalyst within 6 months — schedule respecting router state. If A is currently DO-NOT-ACTIVATE per Regime_State.md / Decision_Log.md most-recent M1 call, the candidate goes to Watchlist.md A queue rather than thesis-construction; do not schedule a thesis-construction event.
     - Strategy E: pair divergence opening — schedule next-cycle M3 unless divergence is fast-moving (then schedule pair-thesis-construction within 1–2 trading days).
   - For each candidate that should proceed to thesis construction: schedule a "[Claude] Thesis construction — <ticker> <strategy>" calendar event at the appropriate time (Strategy B: next morning pre-market or first hour; Strategy C: same-week if catalyst < 14 days, otherwise next weekend after W1; Strategy A: aligned with W1 weekend session; Strategy E fast-moving: within 2 trading days).
   - Event description must be a self-contained thesis-construction prompt: (a) ticker, strategy, candidate context (what Daily.md flagged), (b) reference to Strategy.md entry criteria for the strategy, (c) reference to Operating_Protocols.md for the "NO-GO records are context, not barriers" rule and conviction-calibration ladder, (d) instruction to apply commission-disregarded staging, (e) reminder that the session writes Decision_Log.md / Portfolio_Ledger.md directly and emits the order in chat.
   - For Strategy A candidates that should queue rather than proceed: update Watchlist.md A-queue section with ticker, date-added, reason summary, resolution-trigger condition ("next M1 with A router ACTIVATE").

3. WATCHLIST UPDATES. For each add/remove/demote flagged:
   - Apply the change directly to Watchlist.md (creating it if absent — first line `# Watchlist`, sections per strategy as needed).
   - Per add: ticker, date-added, source-Daily-date, reason summary, resolution-trigger.
   - Per remove: confirm resolution event before removal; if uncertain, leave on list and append a status note.

4. ROUTER REVIEWS RECOMMENDED. For each router-review flag:
   - Confirm the threshold for inter-monthly review per Strategy.md (high bar; only material regime shifts qualify). If on review the threshold is not met, record the second-look decision via Decision_Log.md and skip scheduling.
   - If confirmed: schedule a "[Claude] Router review — <strategy>" calendar event for the next trading-day open.
   - Event description: router-review prompt body referencing Regime_State.md, Strategy.md activation rules for the affected strategy, and the specific Daily.md development that triggered the review.

DEFERRAL DISCIPLINE: if a decision genuinely cannot be resolved this routine, specify (a) the trigger date and information source that will resolve it, and (b) the conservative-default fallback (skip / decline / exit). Deferrals do not chain. Schedule a calendar event for the resolution session.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md (default America/Denver if silent). Set per-event notification to fire at event-time.

CHAT OUTPUT (per chat output discipline):
- Order(s) to execute in IBKR-paste format, grouped by execution day if more than one. Use "no order" if no exits staged.
- One-line acknowledgment of file edits and calendar events created (e.g., "Decision_Log.md, Portfolio_Ledger.md, Watchlist.md updated. 3 calendar events scheduled.").

If no orders, no file changes, no events: "No actions required."
```

---

## D3. Calendar Hygiene — regular routine

```
Read access scope: Calendar Hygiene. Read all live project files. Do NOT read or act on content from `Decision_Log_Archive_*.md` files.

Reconcile Google Calendar against current state. Recurring cadence work (D1, D2, ..., A3) is handled by routines and is NOT placed on calendar. The calendar is exclusively for one-off `[Claude]` events.

Walk all `[Claude]` events in the next 90 days:
- Delete events whose triggering condition has passed (e.g., fill-capture events for orders that have already been reconciled into Portfolio_Ledger.md; thesis-construction events for tickers that have been entered, declined, or no longer fit eligibility; research-deferral checkpoints whose underlying position has been exited).
- Update events whose timing or prompt content is stale (e.g., a thesis-construction event for a Strategy B candidate whose 10-day entry window has shifted; a foundation-change assessment whose strategies-affected list has changed since the underlying Q3/A1 finding).
- Confirm pending events have correct prompt text in their descriptions — descriptions must be self-contained so the human can paste directly into a fresh Claude chat.
- Confirm per-event notifications are set to fire at event-time.

Walk currently-open positions and pending orders from Portfolio_Ledger.md:
- Confirm every open exit-pending order has a corresponding fill-capture event scheduled.
- Confirm every position with a research-deferral has a deferral-checkpoint event scheduled.

Time zone America/Denver unless Experiment_Parameters.md specifies otherwise.

CHAT OUTPUT: one-line summary of calendar reconciliation (e.g., "Deleted 4 stale events, updated 1 prompt description, no missing events.").
```

---

# WEEKLY (Sunday or Monday before market week)

W1, W2, W3 are deep-research routines run in parallel; W4 (action conversion) runs after all three are saved; W5 (decision-log hygiene) runs alongside or after W4.

## W1. Catalyst Calendar (Strategies A and C) — deep research

```
Read access scope: Weekly cadence. Read `Decision_Log.md` (live) only. Do NOT read or act on content from `Decision_Log_Archive_*.md` files. Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction. **Strategy A queue is in Watchlist.md** — relevant for Strategy A shortlisting.

Read Strategy.md (Strategy A and Strategy C sections for entry criteria, instrument eligibility, qualifying-event definitions), Experiment_Parameters.md, Portfolio_Ledger.md, Watchlist.md, Operating_Protocols.md.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior Decision_Log NO-GO entry.

Produce a catalyst calendar across the Strategy A universe (6-month window) and the Strategy C universe (45-day window). Write the complete content directly to `Weekly_Catalyst_Calendar.md` (overwrite; first line = current ISO week in YYYY-WW format).

PART 1 — Two calendars.

A. Strategy A universe (6-month window). All US-listed equities with market cap ≥ $2B and 30-day ADV ≥ $10M with a scheduled catalyst in the next 6 months. Catalyst types: earnings releases, product launches, restructuring events, analyst days, regulatory decisions, other structural narrative markers. Per entry: ticker, name, catalyst type, date (confirmed / estimated / tentative), source.

B. Strategy C universe (45-day window). US-listed companies with qualifying events in the next 45 days — C's types only: earnings (from company IR), FDA PDUFA (from FDA calendar or company disclosure), FOMC (from Fed calendar). Per entry: ticker or event, name, event type, date, source.

Two tables. No interpretation in PART 1.

PART 2 — Ranked shortlists. The downstream W4 routine reads this PART 2 verbatim and schedules thesis-construction calendar events for ranked shortlist names, so make rankings and event-date specifics explicit.

Strategy A preliminary shortlist of 30–50 candidates where preliminary narrative synthesis suggests potential misalignment between consensus and what public documents (recent earnings transcripts, 10-Q/10-K filings, sector context, policy context) support. Cast deliberately broad. Per candidate: (a) direction of hypothesized mispricing, (b) specific supporting public documents, (c) catalyst date, (d) overlap with open A positions or recent watchlist archives, (e) priority tier (top-10 / 11-20 / rest) based on conviction-strength of the narrative misalignment.

Strategy C preliminary shortlist of 10–15 event candidates where preliminary synthesis suggests options-market implied view diverges from what public documents support. Per candidate: (a) direction of hypothesized divergence, (b) supporting public documents, (c) event date, (d) whether current C portfolio size supports an executable defined-risk structure at 2% sizing (flag deferrals), (e) overlap with open A positions (A and C cannot hold simultaneously), (f) priority tier (top-5 / rest).

Shortlists only. Full thesis construction per Strategy.md happens in separate sessions scheduled by W4.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Weekly_Catalyst_Calendar.md`. First line is the YYYY-WW marker. Chat output: one-line acknowledgment that the file was written.
```

---

## W2. Post-Event Screen (Strategy B) — deep research

```
Read access scope: Weekly cadence. Read `Decision_Log.md` (live) only. Do NOT read or act on content from `Decision_Log_Archive_*.md` files. Read factbase files (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`) per prompt direction.

Read Strategy.md (Strategy B section for entry criteria, instrument eligibility — A and B cannot hold the same name simultaneously), Experiment_Parameters.md, Portfolio_Ledger.md, B_Sub_Pattern_Taxonomy.md, Operating_Protocols.md.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior Decision_Log NO-GO entry.

Produce a post-event screen for Strategy B candidates. Write the complete content directly to `Weekly_Post_Event_Screen.md` (overwrite; first line = current ISO week in YYYY-WW format).

PART 1 — All US-listed equities with market cap ≥ $2B, 30-day ADV ≥ $10M, experiencing a close-to-close price move of ≥5% in either direction on any day in the prior 10 trading days, where the move was attributable to a public event. Event types: earnings, FDA decisions, guidance updates, regulatory actions, material corporate developments (M&A, management), analyst actions with material price impact. Per entry: ticker, name, event date, event type, move magnitude and direction, source. Sort by event date (most recent first).

PART 2 — Ranked shortlist. The downstream W4 routine reads this PART 2 verbatim and schedules thesis-construction calendar events for the ranked shortlist, so rank explicitly and surface days-remaining-in-window per candidate.

Evaluate each entry for possible over- or under-sized reaction relative to fundamental implications. Ground in: event details, fundamentals from recent filings, comparable historical reactions to similar events at similar companies (retrieved, not recalled), information vs. sentiment distinction. Default assumption: market reaction is correct.

Rank a shortlist of up to 15 candidates. Per candidate: (a) direction and magnitude of hypothesized mispricing, (b) supporting public information, (c) convergence indicators to watch, (d) days remaining in the 10-trading-day entry window, (e) priority tier (top-5 / rest).

Exclude any name with an open Strategy A position.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Weekly_Post_Event_Screen.md`. First line is the YYYY-WW marker. Chat output: one-line acknowledgment that the file was written.
```

---

## W3. Open-Position Deep-Dive (Strategies A, B, C, E) — deep research

```
Read access scope: Weekly cadence. Read `Decision_Log.md` (live) only. Do NOT read or act on content from `Decision_Log_Archive_*.md` files.

Read Strategy.md, Experiment_Parameters.md, Portfolio_Ledger.md, Operating_Protocols.md.

For each currently-open position in Strategies A, B, C, and E (not D — D gets a monthly deep-dive in M4), produce thesis-status research. Write the complete content directly to `Weekly_Position_Deep_Dive.md` (overwrite; first line = current ISO week in YYYY-WW format).

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
Read access scope: Weekly cadence. Read `Decision_Log.md` (live) only. Do NOT read or act on content from `Decision_Log_Archive_*.md` files. Read `Strategy.md`, `Experiment_Parameters.md`, `Portfolio_Ledger.md`, `Operating_Protocols.md`, `Watchlist.md`, `Regime_State.md`, `B_Sub_Pattern_Taxonomy.md` as relevant.

Read the just-saved weekly research files:
- `Weekly_Catalyst_Calendar.md` (W1 — Strategy A and C shortlists)
- `Weekly_Post_Event_Screen.md` (W2 — Strategy B shortlist)
- `Weekly_Position_Deep_Dive.md` (W3 — per-position hold/close/research recommendations + immediate-action flag)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. EXITS FROM W3 — for each position with W3 recommendation "close on thesis completion" or "close on thesis invalidation" or marked with the immediate-action flag:
   - Confirm the cited invalidation criterion or completion condition is in fact met by reviewing the position's entry record (Decision_Log.md or Portfolio_Ledger.md pointer) and Strategy.md exit rules. Second-look discipline: if on review the criterion is NOT met, do not stage the exit; record the second-look decision in a brief Decision_Log entry and continue.
   - If confirmed: stage the exit order in IBKR-paste format. Limit-price selection per D2 staging rules. Day duration unless thesis logic requires GTC.
   - Append a Decision_Log entry recording: triggering condition (thesis-completion or invalidation criterion), conviction-calibration notes, timing relative to time-based exit windows.
   - Update Portfolio_Ledger.md to mark exit-pending.
   - Schedule "[Claude] Screenshot IBKR — fill capture <ticker> exit" for end-of-day on order day.

B. RESEARCH DEFERRALS FROM W3 — for each position with recommendation "further research":
   - Schedule a "[Claude] Research deferral — <ticker> <strategy>" calendar event for next-trading-day pre-market.
   - Event description: the specific information gap from W3, reference to Strategy.md exit rules, instruction to resolve gap and either stage exit or continue holding. Conservative-default fallback: if the trigger session fails to resolve, exit the position.

C. THESIS-CONSTRUCTION SCHEDULING FROM W2 (Strategy B) — for the W2 top-tier shortlist:
   - Schedule one "[Claude] Thesis construction — <ticker> B" calendar event per top-tier candidate, prioritized by days-remaining-in-window (fewer days = earlier scheduling).
   - Cap: up to 5 events per week (avoid flooding). If more than 5 top-tier candidates, schedule the 5 with shortest remaining window; the rest go to Watchlist.md B-watch section as overflow with their window-expiry dates.
   - Event description: ticker, B context from W2 (event, mispricing direction, days remaining), reference to Strategy.md B entry criteria, B_Sub_Pattern_Taxonomy.md, and Operating_Protocols.md.
   - Trigger times: same-week if window ≥ 5 days remaining; next-morning otherwise.

D. THESIS-CONSTRUCTION SCHEDULING FROM W1 (Strategy A and C) — for the W1 top-tier shortlists:
   - Strategy A top-tier (top-10 from W1): check Regime_State.md / most-recent M1 A router state. If A is currently DO-NOT-ACTIVATE, route to Watchlist.md A-queue (with reason "router gate; queued for next M1 ACTIVATE"); do not schedule thesis-construction. If A is ACTIVATE, schedule "[Claude] Thesis construction — <ticker> A" events. Cap: up to 5 per week, prioritized by catalyst-date proximity.
   - Strategy C top-tier (top-5 from W1): schedule "[Claude] Thesis construction — <ticker> C" events. Trigger time: same-week if catalyst < 14 days; otherwise scheduled to land 7-10 days before catalyst date. Cap: up to 3 per week.
   - Each event description: ticker, strategy, candidate context from W1, references to Strategy.md / Operating_Protocols.md.

E. CROSS-STRATEGY DECONFLICTION — per Strategy.md simultaneous-holding constraints (A and B cannot hold same name; A and C cannot hold same name): if the same ticker appears as both an exit candidate (W3) and a new-entry candidate (W1/W2), do NOT schedule the new-entry thesis until after the exit fills. Instead, schedule the new-entry thesis-construction event for 1 trading day after expected exit fill, with a check-Portfolio_Ledger gate in the event description.

F. WATCHLIST UPDATES — apply A-queue additions from D, B-watch overflow from C, and any other updates surfaced.

DEFERRAL DISCIPLINE: if a recommendation cannot be acted on this routine, specify (a) trigger date and information source, (b) conservative-default fallback. Deferrals do not chain.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- Exit order(s) in IBKR-paste format grouped by execution day (or "no order").
- One-line acknowledgment of file edits and calendar events.

If no orders, no file changes, no events: "No actions required."
```

---

## W5. Decision Log Hygiene — regular routine

Runs weekly (Sunday or Monday before market week, alongside or after W4). Mechanical lifecycle bookkeeping, not deep research.

```
Read access scope: Weekly cadence with factbase WRITE permission. Read `Decision_Log.md` (live), the current-quarter `Decision_Log_Archive_<YYYY>_<QN>.md` if it exists, `B_Sub_Pattern_Taxonomy.md` if it exists, `Watchlist.md` if it exists, `Operating_Protocols.md` if it exists, and `Portfolio_Ledger.md` (for open-position list). Do not read other archive quarters' files unless an entry being archived references them and consistency check is needed.

PRE-ARCHIVAL MIRRORING — before applying lifecycle rules, walk current Decision_Log.md entries and mirror durable signal into factbases. This step preserves operationally-needed context that would otherwise be lost when entries archive.

Mirror to `Watchlist.md`:
- For any entry that adds a name to a strategy queue (e.g., "AAPL added to A-watchlist queue per router-gate-failure pattern"), ensure the name appears in Watchlist.md under the appropriate strategy section. Per-name fields: ticker, date-added, source-DecisionLogEntry-date, reason summary, resolution-trigger condition (e.g., "next M1 with A router ACTIVATE").
- For any entry that resolves a queue item (e.g., a future thesis-construction session that processes a queued name), ensure the resolved name is removed from Watchlist.md.
- Do NOT add Strategy B prior-NO-GO names to Watchlist.md — B operates on event-flow with fresh evaluation per "NO-GO records are context, not barriers". Sub-pattern factbase preserves the durable signal.
- Do NOT add Strategy D pending re-screens to Watchlist.md — calendar events are the canonical source.
- Note: Watchlist.md is also written by D2 / W4 / M5 (action-conversion routines) for in-cycle additions; W5 reconciles any drift between those writes and Decision_Log signal.

Mirror to `Operating_Protocols.md`:
- For any entry that introduces or revises an operational protocol (operating-model updates, commission-disregarded protocol, "NO-GO records are context, not barriers" rule, conviction-calibration ladder, deferral chaining rules, file-conventions/read-access-scope policy, decision-log lifecycle policy, etc.), ensure the canonical-current text is reflected in Operating_Protocols.md. Each protocol gets a section with: title, current canonical text, revision-history list (date + Decision_Log entry pointer + brief change description per revision).
- When revising an existing protocol section, replace the canonical text with the new revision and append the prior canonical to revision history.
- Do NOT mirror NO-GO entries, position entries, calendar-recon entries, or session-end-consolidation entries — those are not protocol entries.

LIFECYCLE RULES — after mirroring, apply the live/archive split:

Keep in live Decision_Log.md any entry meeting one of:
- (a) ENTRY records for currently-open positions (across A, B, C, D, E)
- (b) ACTIVE deferrals (deferred decisions not yet resolved)
- (c) PROTOCOL revisions still canonical (i.e., the revision is in current force)
- (d) Recent NO-GO entries within retention window per Strategy: 14 days for B; 30 days for C; 60 days for A; 90 days for D and E
- (e) Recent ROUTER calls within retention window: most-recent M1 call per strategy stays live; older M1 calls archive
- (f) Recent SESSION-END consolidation entries within 14 days
- (g) Open ADVERSARIAL REVIEW records (review not yet completed)

Move to current-quarter archive any entry not meeting (a)-(g). For each moved entry:
1. Append the full entry to `Decision_Log_Archive_<YYYY>_<QN>.md` (current-quarter file), creating the file with first line `# Decision Log Archive <YYYY> <QN>` if it does not exist.
2. Replace the entry in live Decision_Log.md with the single-line pointer: `# [archived] <YYYY-MM-DD> <title> → Decision_Log_Archive_<YYYY>_<QN>.md`

EXTRACT B sub-pattern instances during archival. For each B NO-GO entry being archived:
1. Confirm it is a Strategy B criterion-4 NO-GO (narrative-misalignment/sub-pattern-driven) versus a mechanical NO-GO (criterion-1 mechanical, instrument-rule, router-gate). Mechanical NO-GOs go to (4) below.
2. Confirm sub-pattern classification language is present in the entry. If the entry describes a specific sub-pattern but does not name it explicitly, classify it now per the taxonomy below; if it neither describes nor names a sub-pattern, log a consistency-check anomaly.
3. For each NO-GO entry being archived: scan for sub-pattern classification language. The Strategy B taxonomy as of this prompt's authoring includes (non-exhaustive list — extract additional categories as they appear in entries):
   - aggressive-sell-side-bull-ratification (NXPI/STX/BE/TWLO/CAT pattern)
   - structural-overhang-persistence (V/MDLZ pattern)
   - information-priced-via-pre-print-rally (SBUX/CBOE pattern)
   - negative-direction information-confirmed-by-cross-section (NOW/CHTR pattern)
   - in-window-binary-catalyst (STLA pattern)
   - valuation-reset-but-not-narrative-reset (TEAM pattern)
   - TEAM+V/MDLZ-hybrid (EL pattern)

   For any sub-pattern instance not yet recorded in B_Sub_Pattern_Taxonomy.md, append a brief instance entry there with: ticker, decision date, sub-pattern category, one-paragraph evidence summary including the decisive flaw type and key sell-side / price-action data points, comparable-name framing for thesis-construction routing, and a pointer back to the archive location. The instance entry must contain enough detail that future thesis-construction sessions can route a new candidate against the sub-pattern WITHOUT needing to read the archived NO-GO entry.

   If B_Sub_Pattern_Taxonomy.md does not exist, create it. First line: `# Strategy B Criterion-4 NO-GO Sub-Pattern Taxonomy`. Organize by sub-pattern category with each instance under its category.

4. Mechanical-failure NO-GOs (criterion-1 mechanical, instrument-rule, router-gate failures): no sub-pattern extraction needed. Pure archive move.

QUARTER ROLLOVER: At the first W5 run after a quarter rollover (e.g. first run after 2026-07-01 starts Q3), close out the prior quarter's archive file (no further appends to it) and start a new Decision_Log_Archive_<YYYY>_<QN>.md for the current quarter. Future W5 runs append matured entries to the current-quarter archive only.

ENTRIES THAT POINT BACKWARDS: when archiving an entry that contains "References" pointing to specific other Decision_Log entries, leave the references as-is (text-level). The pointer line replacement in live preserves the date+title which makes archive lookup deterministic.

CONSISTENCY CHECK: after archival actions complete, scan the updated live Decision_Log.md for any references to entries that were just archived. Cross-reference text mentioning specific dated entries (e.g. "per Decision_Log 2026-04-29 SBUX NO-GO") is fine — the reader can find the pointer line. Do NOT mass-rewrite cross-references.

FILE EDITS:
- Apply all live/archive moves directly to `Decision_Log.md` and the current-quarter `Decision_Log_Archive_<YYYY>_<QN>.md`.
- Apply mirroring edits directly to `B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`.

Append a brief Decision_Log entry documenting the W5 cycle outcome: count of entries archived, count of new sub-pattern instances extracted, file size deltas if notable, any consistency-check anomalies surfaced.

If no entries qualify for archival AND no factbase mirroring is needed: append the W5 outcome entry stating "No entries matured for archival and no factbase mirroring needed this cycle." and end without other file changes.

CHAT OUTPUT: one-line acknowledgment of files edited (e.g., "Decision_Log.md, Decision_Log_Archive_2026_Q2.md, B_Sub_Pattern_Taxonomy.md updated. 4 entries archived, 1 new B sub-pattern instance extracted.").
```

---

# MONTHLY (first trading day of month)

M1a, M1b, M3, M4 are deep-research routines; M5 (action conversion) runs after all are saved.

(The "M2" slot is intentionally vacant — the AI Capabilities Research task previously M2 was moved to quarterly cadence as Q3. M5 numbering is retained sequentially with the gap.)

## M1a. Strategy-Blind Regime Scoring — deep research

Schedule: Monthly, before M1b.

```
Read access scope: Monthly cadence. May read Decision_Log.md and Decision_Log_Archive_*.md files for prior months' Monthly_Fundamental_RegimeScore.md outputs only (cross-month regime-trend cross-references). Read Strategy.md "Fundamental analysis template (monthly)" section for the M1a template specification, Experiment_Parameters.md, AI_Trading_Foundation.md.

CRITICAL BLINDING REQUIREMENT: This routine must NOT read Strategy.md sections describing individual strategies (Strategy A through Strategy E sections), per-strategy activation rules, or any document referencing strategy letters or mechanisms. M1a is strategy-blind by design. The output produced here feeds M1b (a separate routine) which then applies per-strategy mapping. If you find yourself referencing "Strategy A" or any strategy letter / mechanism in your reasoning, stop and re-scope — that work belongs in M1b, not here.

Produce strategy-blind regime scoring for the prior calendar month. Two output files:

OUTPUT FILE 1 — Monthly_Macro_Data_<YYYY-MM>.md (audit trail of underlying inputs, NOT read by M1b):

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

OUTPUT FILE 2 — Monthly_Fundamental_RegimeScore.md (M1b's sole input from M1a):

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
Read access scope: Monthly cadence. May read Decision_Log.md and Decision_Log_Archive_*.md files. Read Strategy.md (full document — strategy-mapping requires reading per-strategy activation rules), Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, Watchlist.md, Operating_Protocols.md.

CRITICAL BLINDING REQUIREMENT — file-read scope: Read Monthly_Fundamental_RegimeScore.md (M1a's regime-scoring output) for the regime input. Do NOT read Monthly_Macro_Data_<YYYY-MM>.md or any other macro/policy/earnings source for this month — the underlying inputs M1a consumed are not part of M1b's input set by design. This preserves the architectural blinding between regime scoring and strategy mapping per Strategy.md "Two-routine blinded scoring." M1b's regime view is exactly M1a's regime-scoring file, no more.

Read Monthly_Fundamental_RegimeScore.md.

If first line indicates fallback_suppression = true: write Monthly_Fundamental.md with header noting fallback suppression for the month, set all 5 strategies to DO-NOT-ACTIVATE with reasoning "fallback suppression — sub-step M1a flagged ≥2 missing primary inputs," do NOT compute divergence flags, exit with chat acknowledgment.

If fallback_suppression = false: produce per-strategy activation calls and divergence flags. Write Monthly_Fundamental.md (overwrite; first line = current month YYYY-MM marker).

PART 1 — Echo M1a regime scoring (read from Monthly_Fundamental_RegimeScore.md). Reproduce the 5 axis assignments with their brief rationale and the integrative summary. This is the ONLY regime context for downstream consumers and the divergence-review attacker.

PART 2 — Activation calls and divergence flags. The downstream M5 routine reads this PART 2 verbatim and acts on activation flips, divergence flags, and queue-drain triggers, so make calls explicit and structured.

1. Per-strategy activation calls. For each of A, B, C, D, E produce binary ACTIVATE / DO-NOT-ACTIVATE with reasoning per Strategy.md's immutable output format. Reasoning must reference M1a regime scoring (max 300 words per strategy). Compare against the prior month's call (read Decision_Log.md or prior-month Monthly_Fundamental.md) and explicitly tag each call as "FLIP TO ACTIVATE" / "FLIP TO DO-NOT-ACTIVATE" / "UNCHANGED" — flips drive M5 actions.

2. Reconciliation rules (apply mechanically AFTER step 1; per Strategy.md):
   - shock_overlay = acute → override ACTIVATE → DO-NOT-ACTIVATE for ANY strategy.
   - risk_sentiment = stressed → override ACTIVATE → DO-NOT-ACTIVATE for A or D.
   - growth_momentum = decelerating AND policy_stance = hawkish → override ACTIVATE → DO-NOT-ACTIVATE for A.
   - inflation_trend = reaccelerating AND policy_stance = hawkish → override ACTIVATE → DO-NOT-ACTIVATE for D.
   For each override applied: log the override with the originating regime axis values and the affected strategy, in a "Reconciliation overrides applied" subsection.

3. Divergence flags. For each strategy, compare final activation call (post-reconciliation) against current technical signal from Regime_State.md applied through the per-strategy technical rule. List divergences — each will be queued as a divergence-review by M5.

OUTPUT: write the complete content (PART 1 + PART 2) directly to Monthly_Fundamental.md. First line is the YYYY-MM marker. Chat output: one-line acknowledgment.
```

---

## M3. E Pair Divergence Screen — deep research

```
Read access scope: Monthly cadence. May read `Decision_Log.md` and all `Decision_Log_Archive_*.md` files. In practice this routine operates on current open-book state and screening universe; archive reads are usually unnecessary unless explicitly needed.

Read Strategy.md (Strategy E section in full, including the "Explicit confrontation of disadvantage 2.6 (no access to private information)" subsection. Abandon any candidate pair where the divergence thesis requires expert network calls, private management access, conference-derived private context, buy-side intelligence, industry contacts, or channel checks), Experiment_Parameters.md, Portfolio_Ledger.md, Operating_Protocols.md.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior Decision_Log NO-GO entry.

Produce an E pair divergence screen. Write the complete content directly to `Monthly_E_Pairs.md` (overwrite; first line = current month in YYYY-MM format).

PART 1 — Identify GICS industry groups (6-digit) in the US-listed large-cap universe with at least two companies meeting Strategy E's eligibility. Within each, identify pairs where:
- Both have market cap and 30-day ADV sufficient for E execution (flag pairs requiring ETF substitution at small portfolio sizes)
- Trailing 252-day daily-return correlation ≥ 0.5
- Both have reported earnings or filed 10-Q/10-K within the last 90 days

Per pair: provisional L and S (refined in PART 2), industry group, 252-day correlation, most recent earnings/filing dates, approximate short borrow rate per leg if estimable, individual-stock vs. ETF-substitution execution flag. Table organized by industry group.

PART 2 — Ranked shortlist. The downstream M5 routine reads this PART 2 verbatim and schedules pair-thesis-construction events, so rank explicitly with priority tier.

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

## M4. D Position Deep-Dive — deep research

```
Read access scope: Monthly cadence. May read `Decision_Log.md` and all `Decision_Log_Archive_*.md` files. Open D positions' entry records remain in live Decision_Log.md by lifecycle rule (a); archive reads are needed only if a multi-month-old context cross-reference is required.

Read Strategy.md (Strategy D section), Experiment_Parameters.md, Portfolio_Ledger.md, Operating_Protocols.md.

For each currently-open Strategy D position, produce thesis-status research. Write the complete content directly to `Monthly_D_Position_Deep_Dive.md` (overwrite; first line = current month in YYYY-MM format).

Per position, cover:

1. Current thesis status. Original multi-year structural thesis from entry record. Does it still hold after the prior month's developments?

2. Multi-year driver check. For each original thesis driver (product cycle phase, regulatory process stage, management strategic plan, thematic participation mechanism — whichever applied), has observable progress been made? Stalled? Reversed?

3. Fundamental developments. Material filings, earnings transcripts, analyst days, regulatory events, management changes, competitive moves in the prior month.

4. Invalidation criteria check. For each at-entry-defined invalidation criterion, has any been triggered?

5. Sector and theme context. Structural shifts in the secular theme or regulatory environment affecting the multi-year case.

6. Long-term tax treatment. Time to 12-month LTCG qualification; any thesis-completion signals suggesting LTCG timing coordination.

Per position: explicit recommendation (hold / close on thesis completion / close on thesis invalidation / further research). The downstream M5 routine reads these recommendations and stages exits for "close" calls and schedules research-deferral events for "further research" calls, so each recommendation must cite the specific invalidation criterion (for close calls) or the specific information gap (for further research calls).

If any position shows material thesis invalidation, set an "IMMEDIATE-ACTION" flag at the top of the file content so M5's read picks it up first.

OUTPUT: write the complete content directly to `Monthly_D_Position_Deep_Dive.md`. First line is the YYYY-MM marker. Chat output: one-line acknowledgment, plus the IMMEDIATE-ACTION flag (if any).
```

---

## M5. Monthly Action Conversion — regular routine

Runs after M1, M3, M4 are all saved.

```
Read access scope: Monthly cadence. May read `Decision_Log.md` and all `Decision_Log_Archive_*.md` files. Read `Strategy.md`, `Experiment_Parameters.md`, `Portfolio_Ledger.md`, `Regime_State.md`, `Operating_Protocols.md`, `Watchlist.md` as relevant.

Read the just-saved monthly research files:
- `Monthly_Fundamental.md` (M1b — per-strategy ACTIVATE/DO-NOT-ACTIVATE calls + divergence flags; echoes M1a regime scoring in PART 1)
- `Monthly_E_Pairs.md` (M3 — pair shortlist with priority tier)
- `Monthly_D_Position_Deep_Dive.md` (M4 — per-position hold/close/research recommendations + immediate-action flag)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. ROUTER ACTIVATION FLIPS FROM M1b — for each strategy with FLIP TO ACTIVATE or FLIP TO DO-NOT-ACTIVATE:
   - Update Regime_State.md to reflect the new activation state per strategy.
   - Append a Decision_Log entry recording the flip: strategy, prior state, new state, M1 reasoning summary, date.
   - **A FLIP TO ACTIVATE for Strategy A — drain Watchlist.md A-queue.** For each name in the A queue with resolution-trigger "next M1 with A router ACTIVATE":
     * Schedule a "[Claude] Thesis construction — <ticker> A" calendar event for the next available trading day, prioritizing names with the soonest catalyst dates. Cap: 5 events; remaining names stay queued.
     * Remove processed names from Watchlist.md A-queue (or mark as "scheduled <date>" if Watchlist.md tracks scheduling state).
   - **A FLIP TO DO-NOT-ACTIVATE for any strategy — halt new-position activity.** Cancel any pending thesis-construction calendar events for that strategy via Calendar MCP. Existing positions are unaffected (per Strategy.md exit rules — DO-NOT-ACTIVATE blocks new entries, not existing-position management).

B. DIVERGENCE FLAGS FROM M1b — for each divergence flag (fundamental call vs. technical signal):
   - Append an entry to `Pending_Adversarial_Reviews.md` with review type `divergence-review`. Schema and field details per the ADVERSARIAL REVIEWS section of this document. Required fields: id (unique, e.g., `div-<strategy>-<YYYYMM>-<seq>`), review_type = divergence-review, strategy, prior_activation_state, m1b_artifact_path = Monthly_Fundamental.md, technical_reading (snapshot of relevant Regime_State.md fields at queue time), attacker_due_date (next trading day), orchestrator_due_date (one trading day after attacker_due_date), status = pending.
   - The Adversarial Review Attacker and Orchestrator routines (defined below) will pick the entry up on their daily fire and produce the assessment + binding decision. M5 itself does not invoke any review prompt — it only enqueues.

C. EXITS FROM M4 — for each D position with M4 recommendation "close on thesis completion" or "close on thesis invalidation" or marked with the immediate-action flag:
   - Confirm the cited invalidation criterion or completion condition is in fact met. Second-look discipline applies. If on review the criterion is not met, record the second-look decision in Decision_Log.md and continue.
   - If confirmed: stage the exit order in IBKR-paste format. Note for D positions: check LTCG status — if within 30 days of 12-month qualification AND the invalidation is not catastrophic, stage exit for the post-LTCG date instead and schedule a "[Claude] D exit window — <ticker>" calendar event at LTCG date. If invalidation is catastrophic, exit immediately regardless of LTCG.
   - Append Decision_Log entry, update Portfolio_Ledger.md. Schedule fill-capture screenshot event.

D. RESEARCH DEFERRALS FROM M4 — for each D position with recommendation "further research":
   - Schedule a "[Claude] Research deferral — <ticker> D" calendar event for next-trading-day pre-market.
   - Event description: information gap from M4, reference to Strategy.md D exit rules. Conservative-default fallback: if trigger fails to resolve, exit the position.

E. THESIS-CONSTRUCTION SCHEDULING FROM M3 (Strategy E) — for the M3 top-tier pair shortlist:
   - Schedule "[Claude] Pair thesis construction — <L>/<S>" events. Cap: up to 3 events per month, prioritized by reconvergence-indicator proximity.
   - Event description: pair specifics from M3 (L, S, divergence thesis, reconvergence indicators, borrow cost estimate, execution path), reference to Strategy.md E entry criteria.

F. CROSS-PROMPT DECONFLICTION — if any ticker appears as both an exit candidate (M4) and a new-entry candidate (M3 leg, or A-queue drain from A), respect simultaneous-holding constraints per Strategy.md. Schedule new-entry thesis for after expected exit fill.

G. WATCHLIST UPDATES — apply any A-queue drains from A and any other updates surfaced.

DEFERRAL DISCIPLINE: deferrals don't chain. Specify trigger and conservative-default fallback for any deferred decision.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- Exit order(s) in IBKR-paste format grouped by execution day (or "no order").
- One-line acknowledgment of file edits and calendar events.

If no orders, no file changes, no events: "No actions required."
```

---

# ADVERSARIAL REVIEWS (queue-driven, fires daily as needed)

Structured adversarial reviews — pre-mortem reviews, regime-router divergence reviews, mark-to-market termination reviews, capital-redistribution reviews, scope-widening adjudications, and any future structured review the experiment design adds — are executed by a small set of generic routines that read entries from `Pending_Adversarial_Reviews.md` and produce reviews per file handoff. Triggering routines (M5, A3, kill-trigger handlers, termination handlers, etc.) write entries to the queue; they never invoke a review prompt directly.

## Pending_Adversarial_Reviews.md — queue file schema

The queue is a single Markdown file at the repo root. Each pending review is one entry, separated by `---`. Entries are appended in order of creation; processed entries are NOT deleted (provides traceability) — they are marked complete and retained. The file may be archived periodically by a quarterly housekeeping routine (out of scope for initial implementation).

Each entry is a YAML-style block:

```
- id: <unique identifier, e.g., div-A-202605-1, premortem-strategyB-cycle3, m2m-D-202609, redist-202707-strategyC, scopewiden-C-202611-1>
  review_type: <one of: pre-mortem | divergence-review | m2m-termination | capital-redistribution | scope-widening-adjudication>
  strategy: <A | B | C | D | E | router | n/a (n/a for redistribution which is account-level)>
  trigger_context: <one paragraph of context — what fired the review and any specifics needed by the reviewer beyond the artifact_path>
  artifact_path: <relative repo path to the artifact under review — for divergence-review, this is Monthly_Fundamental.md (containing M1b output); for pre-mortem, the pre-mortem document; for m2m-termination, a per-trigger termination-context file produced by the kill-trigger handler; for capital-redistribution, a per-termination context file produced by the termination handler; for scope-widening, the post-HYBRID fundamental update document>
  prior_state: <free-form text describing what state the system is in pending review — e.g., for divergence-review: "Strategy A activation state held at DO-NOT-ACTIVATE pending review"; for m2m-termination: "Strategy D continues trading pending review">
  attacker_due_date: <YYYY-MM-DD; the next trading day after queue creation, in the experiment's reference timezone per Experiment_Parameters.md>
  orchestrator_due_date: <YYYY-MM-DD; one trading day after attacker_due_date>
  recommendation_due_date: <YYYY-MM-DD or n/a; only used for capital-redistribution; if used, set one trading day before attacker_due_date>
  status: <pending | recommendation-complete | attacker-complete | complete | superseded>
  attacker_output_path: <set by attacker routine when it completes; e.g., Adversarial_Review_<id>_attacker.md>
  orchestrator_output_path: <set by orchestrator routine; e.g., Adversarial_Review_<id>_orchestrator.md>
  recommendation_output_path: <set by recommendation routine if used; e.g., Adversarial_Review_<id>_recommendation.md>
  cycle_number: <integer; 1 for first cycle of a given artifact, incremented per re-review after revision; n/a for non-cycling review types>
  notes: <free-form, optional — e.g., for cycle 5+ pre-mortem, the forcing-question answer; for revision-induced cycles, the prior cycle's id>
```

The queue file's header (first line) is `# Pending Adversarial Reviews — queue`, followed by a brief schema reference, then entries.

## Adversarial Review Recommendation — regular routine (capital-redistribution only)

Schedule: daily. The routine wakes, scans the queue, and exits if no entry matches its phase.

```
Read access scope: Read Pending_Adversarial_Reviews.md, Strategy.md, Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, AI_Trading_Foundation.md, Decision_Log.md (and Decision_Log_Archive_*.md as needed), the queue entry's artifact_path, and any per-strategy state files referenced by the trigger_context.

Read Pending_Adversarial_Reviews.md.

Find the next entry where review_type = capital-redistribution AND status = pending AND recommendation_due_date <= today. Process at most one entry per routine fire. If none: write chat output "No capital-redistribution recommendations due today." and exit.

If found:
1. Read the entry's artifact_path (the per-termination context file). Read Portfolio_Ledger.md and Regime_State.md for current surviving-strategy state.
2. Produce a recommendation per Experiment_Parameters.md "Strategy termination and capital redistribution" — one of: full redistribution / full hold (SGOV) / partial redistribution (with specified fraction). Explicit reasoning required.
3. Write the recommendation to Adversarial_Review_<id>_recommendation.md (where <id> is the queue entry id). Format: header (id, review_type, strategy, date, cycle_number), recommendation (one-line verdict), reasoning (free-form, structured under headers), key inputs section listing what was read.
4. Update the queue entry: set recommendation_output_path, set status = recommendation-complete.

CHAT OUTPUT: one-line acknowledgment naming the entry id and recommendation file written.
```

## Adversarial Review Attacker — regular routine

Schedule: daily (after Recommendation routine completes if both fire same day). The routine wakes, scans the queue, and exits if no entry matches its phase.

```
Read access scope — STRICT BLINDING: Read Pending_Adversarial_Reviews.md (to find and process the entry). Read the queue entry's artifact_path (the document under attack). Read its recommendation_output_path if review_type = capital-redistribution AND status = recommendation-complete (the recommendation is the artifact for the attacker in capital-redistribution reviews).

EXPLICITLY DO NOT READ for any review processed by this routine: Decision_Log.md, Decision_Log_Archive_*.md, prior Adversarial_Review_*.md files, broader sections of Strategy.md or Experiment_Parameters.md beyond the section directly under review, prior versions of the artifact, or any other repo file. The artifact under review is required to be self-contained per Experiment_Parameters.md "Self-containment requirement for pre-mortem artifacts" (which generalizes to all adversarial-review artifacts). If you need information that is not in the artifact and not in the queue entry's trigger_context field, the artifact has failed self-containment and you flag this as a Tier 1 defect — do not search for the missing context.

This blinding is enforced by prompt discipline. Tool-call logs are auditable; reading any forbidden file is a discipline violation that will be caught at quarterly review. Compliance is critical to preserving the architectural separation between attacker and orchestrator routines under the routine architecture.

Read Pending_Adversarial_Reviews.md.

Find the next entry where attacker_due_date <= today AND status matches the entry's phase: status = pending for review types pre-mortem / divergence-review / m2m-termination / scope-widening-adjudication; status = recommendation-complete for review type capital-redistribution. Process at most one entry per routine fire. If none: write chat output "No adversarial reviews due for attacker today." and exit.

If found, attack the artifact per the review_type's protocol from Experiment_Parameters.md and Strategy.md:

- pre-mortem: identify Tier 1 / Tier 2 / Tier 3 weaknesses (theater indicators, vague failure modes, unverifiable frequency declarations, post-hoc-reinterpretable activation thresholds). Verdict: SUFFICIENT / TIER 1 DEFECT — REVISION REQUIRED.
- divergence-review: produce strongest bear case against the M1b fundamental claim and argue for the technical call. Specific weaknesses in the fundamental reasoning. Verdict on whether fundamental claim should survive.
- m2m-termination: produce strongest case for terminating the strategy. Specific weaknesses in any "thesis-still-intact" reasoning visible in the artifact. Verdict on terminate vs continue.
- capital-redistribution: produce strongest case against the recommendation on its merits. Not told which direction the recommendation runs. Verdict.
- scope-widening-adjudication: attack whether the fundamental reasoning has adequately addressed the three required topics per Strategy.md Strategy C post-HYBRID adjudication mechanism. Verdict.

Write attack to Adversarial_Review_<id>_attacker.md (where <id> is the queue entry id). Format: header (id, review_type, date, cycle_number), verdict (one-line), specific weaknesses identified (numbered, each with anchor to artifact text), self-imposed scope confirmation ("I read only: <list of files actually read>; I did not read: Decision_Log, prior reviews, broader docs"), reasoning section.

Update the queue entry: set attacker_output_path, set status = attacker-complete.

CHAT OUTPUT: one-line acknowledgment naming the entry id, review_type, and attacker verdict.
```

## Adversarial Review Orchestrator — regular routine

Schedule: daily (after Attacker routine). The routine wakes, scans the queue, and exits if no entry matches its phase.

```
Read access scope: Read Pending_Adversarial_Reviews.md, Strategy.md, Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, AI_Trading_Foundation.md, Decision_Log.md (and Decision_Log_Archive_*.md as needed), the queue entry's artifact_path, attacker_output_path, and recommendation_output_path (if applicable).

Read Pending_Adversarial_Reviews.md.

Find the next entry where status = attacker-complete AND orchestrator_due_date <= today. Process at most one entry per routine fire. If none: write chat output "No adversarial reviews due for orchestrator today." and exit.

If found, orchestrate per the review_type's protocol:

1. Read attacker_output_path. Read artifact_path. Read recommendation_output_path if applicable.
2. Produce explicit independent assessment documenting:
   (a) For each weakness the attacker identified, validity assessment (valid Tier 1 / valid but Tier 2-3 / invalid) — for pre-mortem; for other types, equivalent grading per the type's protocol.
   (b) Theater in the attacker's output (generic-sounding objections without specific anchors).
   (c) Weaknesses the attacker missed.
   (d) Final verdict per review_type:
       - pre-mortem: SUFFICIENT or TIER 1 DEFECT — REVISION REQUIRED. If REVISION REQUIRED, identify whether to invoke the rev 15 forcing question and answer it in writing per Experiment_Parameters.md (a/b/c). For cycle 5+, justify continuation per the soft cap.
       - divergence-review: final activation state for the strategy (ACTIVATE / DO-NOT-ACTIVATE) with reasoning. Apply the default-on-ambiguity rule and the theater-check tiebreaker: if theater_check = CONVERGENT, default to DO-NOT-ACTIVATE regardless of the verdict.
       - m2m-termination: TERMINATE / CONTINUE with reasoning. Default-on-ambiguity = TERMINATE.
       - capital-redistribution: full redistribution / full hold / partial redistribution (with fraction) with reasoning. Default-on-ambiguity = full hold (SGOV).
       - scope-widening-adjudication: re-widening AUTHORIZED / NOT AUTHORIZED with reasoning. Apply the four-screen test and the CONVERGENT-theater-check requirement per Strategy.md.
   (e) Theater-check flag: CONVERGENT / DIVERGENT / MIXED with specific rationale referencing concrete claims in the attacker output and the orchestrator's own assessment. The orchestrator self-certifies this flag — accepted-risk note: this is structurally weaker than a separate Theater Auditor routine; if empirical theater-check rates suggest under-detection of CONVERGENT framing, a separate auditor routine can be added in a future revision.

3. Write orchestrator output to Adversarial_Review_<id>_orchestrator.md. Format: header (id, review_type, date, cycle_number), final verdict (one-line + binding decision), theater-check flag (one-line), reasoning sections per (a)-(d) above, action taken (if any).

4. Take resulting action:
   - divergence-review: update Regime_State.md with the binding activation state for the strategy. If the verdict differs from the prior state, append the binding decision to Decision_Log.md.
   - m2m-termination with verdict TERMINATE: append Decision_Log.md entry recording termination, update Portfolio_Ledger.md to mark strategy terminated, immediately move strategy portfolio value to SGOV (stage IBKR orders in chat output for the participant to execute), and append a new queue entry of review_type = capital-redistribution for the just-terminated strategy (with appropriate due dates).
   - m2m-termination with verdict CONTINUE: append Decision_Log.md entry recording the review outcome, no portfolio action.
   - capital-redistribution: update Portfolio_Ledger.md per the verdict (held-aside pool annotations, redistribution amounts to surviving strategy portfolios), stage any required IBKR orders in chat output for the participant to execute, append Decision_Log.md entry.
   - pre-mortem with verdict REVISION REQUIRED: append Decision_Log.md entry recording the cycle outcome. Subsequent revision is performed by the participant or by a participant-triggered drafting session — orchestrator does not auto-revise the artifact. (Pre-mortem revision is itself an editorial action and is out of scope for an autonomous routine.)
   - pre-mortem with verdict SUFFICIENT: append Decision_Log.md entry, no further action; the pre-mortem is unblocked for first-trade gating purposes.
   - scope-widening-adjudication with verdict AUTHORIZED: append Decision_Log.md entry; downstream Strategy C handlers may re-widen per Strategy.md.
   - scope-widening-adjudication with verdict NOT AUTHORIZED: append Decision_Log.md entry; re-widening is blocked.

5. Update the queue entry: set orchestrator_output_path, set status = complete.

CHAT OUTPUT:
- IBKR-paste-format orders if any were staged (otherwise omit).
- One-line acknowledgment naming the entry id, review_type, final verdict, theater-check flag, and action taken.
```

---

# QUARTERLY (first trading day of quarter)

Q1, Q2, Q3 are deep-research routines; Q4 (action conversion) runs after Q2 and Q3 are saved (Q1 has no actionable outputs and does not gate Q4).

## Q1. Regime Retrospective — deep research

```
Read access scope: Quarterly cadence. Read `Decision_Log.md` AND all `Decision_Log_Archive_*.md` files — this routine has explicit dependencies on archive content for prior-quarter router history and adversarial review records.

Read Strategy.md (shared regime vocabulary and regime router sections), Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, Decision_Log.md (router history and adversarial review records from the prior quarter), Operating_Protocols.md.

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

1. Router activation trace. For each of A, B, C, D, E, trace activation state changes during the quarter using Regime_State.md history and Decision_Log.md. Table: strategy, activation periods, deactivation periods, disagreement reviews triggered and outcomes.

2. Consistency comparison. Per strategy, compare router classifications against PART 1 retrospective. Does the regime the router classified match the regime the retrospective describes? Focus on systematic disagreements (e.g., router said HEALTHY/UP during a quarter the retrospective calls "rolling distribution").

3. Diagnostic flags. Patterns of systematic router disagreement with reasonable-observer regime reads. Not mid-experiment revision triggers (immutability per Experiment_Parameters.md) — inputs to the next full router pre-mortem at experiment restart.

OUTPUT: write the complete content (PART 1 + PART 2) directly to `Quarterly_Regime.md`. First line is the YYYY-QN marker. Chat output: one-line acknowledgment.
```

---

## Q2. D Long-Horizon Candidates — deep research

```
Read access scope: Quarterly cadence. Read `Decision_Log.md` AND all `Decision_Log_Archive_*.md` files — historical D NO-GO dispositions live in the archives and inform "NO-GO records are context, not barriers" application.

Read Strategy.md (Strategy D section in full: thesis requirements, entry criteria, concentration rules, sector concentration cap), Experiment_Parameters.md, Portfolio_Ledger.md (current D book state and concurrent-position count), Regime_State.md, Operating_Protocols.md.

Apply the shared 'NO-GO records are context, not barriers' rule when any candidate has a prior Decision_Log NO-GO entry.

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
Read access scope: Quarterly cadence. Read `Decision_Log.md` AND all `Decision_Log_Archive_*.md` files — prior-cycle Q3 outcomes and AI-foundation-change dispositions are spread across archives.

Read AI_Trading_Foundation.md (Parts 1, 2, 3, 4 in full — pay particular attention to the Tier framework distinction between architectural / structural Tier 1 items vs empirical / measured Tier 2 items, and to Part 4 verification protocol), Strategy.md, Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, Operating_Protocols.md.

Frame research adversarially: look for evidence that contradicts or updates documented edges and disadvantages, not evidence that confirms them. Offsets self-reference bias (this task evaluates LLM claims while being executed by an LLM).

HF tool orientation. Read `HF_Resource_Catalog.md` once at session start for the authoritative HF tooling map. Apply the following operational rules during PART 1 research:
- Run Hugging Face `paper_search` on each of the 9 query batteries enumerated in `HF_Resource_Catalog.md` §6.1, scoped to the prior calendar quarter. Use `concise_only=true` and `results_limit=8`. For each battery, record any new papers from the prior quarter that bear on documented disadvantages or surface new failure modes — record arXiv IDs in the form `hf.co/papers/<id>`.
- For Section 3a benchmark results, iterate `hub_repo_search` over open-weights model authors (`meta-llama`, `Qwen`, `mistralai`, `deepseek-ai`, others) with `repo_types=["model"]` and read recent (prior-quarter) model cards for benchmark trajectory updates on benchmarks mapped per `AI_Trading_Foundation.md` §5.5 (cross-reference the inverse mapping in `HF_Resource_Catalog.md` §2).
- Do NOT use `space_search` for canonical Spaces — per `HF_Resource_Catalog.md` §8.1, semantic search misses popular Spaces. Use `hub_repo_search` with explicit `author` and `repo_types=["space"]` for known Space lookup.
- HF is silent on Anthropic/Claude. Section 1 (Claude model capability changes) is `web_search` / `web_fetch` only — query `anthropic.com`, `docs.anthropic.com`, Anthropic research blog, and Anthropic-tagged news. Do NOT attempt to find Claude data on HF.
- Do NOT pull data from any HF Space (none durable enough per §3) or any HF dataset (offline-only per §4). HF resources for this routine are: papers, model cards, leaderboards-as-references — nothing else.
- Combine HF and `web_search` / `Tavily` deliberately: HF for academic LLM research and open-weights model evidence; web_search for vendor announcements, regulatory developments, and analyst-bias literature (per `HF_Resource_Catalog.md` §1.11, HF is weak on the classical accounting/finance literature).
- Read `[HF Frontier-LLM Capture]` entries from `Decision_Log.md` and `Decision_Log_Archive_*.md` covering the prior calendar quarter. These are mid-quarter material findings that D1's light-touch daily HF check captured but did not act on. Treat them as required priors when running the §6.1 query batteries — verify each captured paper is incorporated into the relevant section, and check whether any has been superseded by newer work in the prior quarter.

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
Read access scope: Quarterly cadence. Read `Decision_Log.md` (live) and any archive files needed for cross-references. Read `Strategy.md`, `Experiment_Parameters.md`, `AI_Trading_Foundation.md`, `Portfolio_Ledger.md`, `Regime_State.md`, `Operating_Protocols.md`, `Watchlist.md` as relevant.

Read the just-saved quarterly research files:
- `Quarterly_D_Candidates.md` (Q2 — D candidate shortlist with readiness flags)
- `Quarterly_AI_Foundation_Delta.md` (Q3 — YES/NO verification answers with foundation-change-assessment branches per strategy)

Convert into operator-actionable outputs per the operating model. Claude resolves all decisions internally; commissions disregarded at staging time.

A. D THESIS-CONSTRUCTION SCHEDULING FROM Q2 — for the Q2 ranked shortlist:
   - For each candidate marked "ready now": schedule "[Claude] Thesis construction — <ticker> D" calendar event for the next available trading day, prioritized by thesis-strength rating. Cap: up to 4 events in the first week of the quarter; remainder spread over weeks 2–3.
   - For each candidate marked "deferred pending rally pause": add to Watchlist.md D-deferred section with the trailing-30-day momentum reading and resolution-trigger condition ("when 30-day trailing return drops below X%"). Schedule a calendar event in 30 days to re-check.
   - For each candidate marked "blocked by concentration or position count": add to Watchlist.md D-blocked section with the specific blocker and resolution condition ("when GICS <sector> concentration < 30%" or "when D book < 10 positions"). No calendar event — these resolve when an existing D position closes (M5 D-exit handling will trigger re-evaluation).

B. FOUNDATION-CHANGE ASSESSMENT FROM Q3 — for each YES verdict that cleared the transferability filter and warrants foundation-change-assessment:
   - Per the strategies-affected list in the Q3 entry, schedule a "[Claude] Foundation-change assessment — <strategy>" calendar event per affected strategy, for the next available trading day. Stagger if multiple strategies (one per day to manage cognitive load).
   - Event description: Q3 evidence summary, affected Tier (1 architectural / 2 magnitude), foundation-change-assessment branch warranted (continue / terminate / constraint-relaxation), reference to Experiment_Parameters.md §Foundation change trigger procedure.
   - For NO verdicts and YES verdicts that fail the transferability filter: no scheduling action; these are logged as watch items and reviewed at next Q3 cycle.

C. WATCHLIST UPDATES — apply D-deferred / D-blocked additions from A.

D. DECISION_LOG ENTRIES — append a Q4-cycle outcome entry summarizing: Q2 candidates scheduled vs deferred vs blocked counts, Q3 foundation-change-assessment events scheduled per strategy.

DEFERRAL DISCIPLINE: deferrals don't chain. Conservative-default fallback per deferred decision.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- No exit orders are produced by Q4 (D exits flow through M5; A/B/C/E exits flow through D2/W4).
- One-line acknowledgment of file edits and calendar events.

If no file changes, no events: "No actions required."
```

---

# ANNUAL (first trading day of January, or experiment anniversary month if January-anchoring isn't operationally clean)

A1, A2 are deep-research routines; A3 (action conversion) runs after A1 and A2 are saved.

## A1. AI Foundation Annual Full Re-Derivation — deep research

```
Read access scope: Annual cadence. Read everything, including `Decision_Log.md` and all `Decision_Log_Archive_*.md` files.

Read AI_Trading_Foundation.md (Parts 1, 2, 3, 4 in full — pay particular attention to the Tier framework distinction), Strategy.md, Experiment_Parameters.md, Portfolio_Ledger.md, Regime_State.md, Operating_Protocols.md, all prior Quarterly_AI_Foundation_Delta.md outputs from the past year.

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
Read access scope: Annual cadence. Read everything, including `Decision_Log.md` and all `Decision_Log_Archive_*.md` files. A2 traces foundation-citation graphs across full Decision_Log history.

Read Strategy.md (full, including all per-strategy pre-mortems), Experiment_Parameters.md, AI_Trading_Foundation.md (current revision), Portfolio_Ledger.md, Regime_State.md, Operating_Protocols.md, most recent Annual_AI_Foundation_Sweep.md output, and recent Quarterly_AI_Foundation_Delta.md outputs.

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
Read access scope: Annual cadence. Read everything (live + all archives). Read `AI_Trading_Foundation.md` (current revision), `Strategy.md` (current revisions for all strategies), `Experiment_Parameters.md`, `Portfolio_Ledger.md`, `Operating_Protocols.md`, `Watchlist.md`, `Decision_Log.md`.

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
   - Schedule a "[Claude] Foundation-change assessment — <strategy>" calendar event per affected strategy, for the next available trading day. Stagger one per day across affected strategies.
   - Event description: A1 evidence summary, recommended outcome (continue / terminate / constraint-relaxation review), reference to Experiment_Parameters.md §Foundation change trigger procedure.

C. UPDATED STRATEGY.MD FROM A2 — produce a new revision of Strategy.md applying:
   - All constraints with §5.6 mechanical relaxation verdicts: replace constraint value with new (relaxed) value per §5.6 formula. Update constraint annotation to cite the A2 audit date and underlying foundation revision.
   - All constraints flagged out-of-table: leave at current value; add out-of-table annotation citing the §5.7 audit trail.
   - All constraints with no relaxation (NONE primary citation, or Step 3 load-bearing test failed, or §5.5 Goodhart guardrail failed): unchanged.
   - Increment per-strategy revision numbers as needed; append revision-history entries citing A2 audit and underlying AI_Trading_Foundation.md revision.

D. OUT-OF-TABLE EXPLICIT REVIEW SCHEDULING FROM A2 — for each out-of-table flag:
   - Schedule a "[Claude] Constraint relaxation review — <strategy> <constraint>" calendar event for the next available trading day after foundation-change assessments complete (typically week 2 of the new year).
   - Event description: §5.7 audit-trail content for the flag (constraint text, why mechanical lookup failed, specific gap), reference to Experiment_Parameters.md constraint-relaxation review procedure.

E. DECISION_LOG ENTRIES — append entries documenting:
   - The A1 cycle outcome: counts per category (KEEP / UPDATE / VERSION-PENDING / REMOVAL / NEW), revision number bumped on AI_Trading_Foundation.md, per-strategy foundation-change assessments scheduled.
   - The A2 cycle outcome: per-strategy constraints relaxed counts, out-of-table flag counts, revisions bumped on Strategy.md.

F. WATCHLIST AND OPERATING_PROTOCOLS RECONCILIATION — review whether any A1/A2 outcomes affect Watchlist.md (e.g., constraint-relaxation that re-opens previously-blocked candidates) or Operating_Protocols.md (e.g., updated foundation revision affecting protocol citations). Apply minimal edits if changed.

DEFERRAL DISCIPLINE: deferrals don't chain. Conservative-default fallback: if a foundation-change assessment cannot resolve, the strategy continues at current revision pending next quarterly delta.

CALENDAR MCP USAGE: Claude calls the Calendar MCP directly. Time zone per Experiment_Parameters.md.

CHAT OUTPUT:
- No exit orders are produced by A3.
- One-line acknowledgment of file edits and calendar events.

If no file changes, no events: "No actions required." (rare for A3 — at minimum AI_Trading_Foundation.md will have a revision bump documenting the sweep, even if all items KEEP UNCHANGED.)
```

After A3 completes, the per-strategy foundation-change assessment events fire at their scheduled times per the Experiment_Parameters.md §Foundation change trigger procedure. Out-of-table constraint-relaxation reviews fire at their scheduled times per the same procedure.

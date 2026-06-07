# Operating Protocols

Canonical reference for active operational protocols governing the AI-directed trading experiment. Each protocol section: title, current canonical text, revision-history list. Living document; read by all cadences. Written and maintained by W5. Future protocol revisions: revise the relevant section here, append a revision-history entry pointing back to the Decision_Log entry that documented the change.

**Created**: 2026-05-10 (first W5 run; bootstrap mirroring of canonical protocols from current Decision_Log entries per Claude_Task_Plan.md W5 PRE-ARCHIVAL MIRRORING step).

**Scope**: This file holds operational protocols only. Strategy-specific mechanics live in Strategy.md (immutable). Experiment-level parameters live in Experiment_Parameters.md (immutable). The framework's edge/disadvantage map lives in AI_Trading_Foundation.md. Decision_Log.md remains the audit trail for individual decisions; this file holds the durable operating-rule signal extracted from those entries.

---

## 1. Human Operator Interaction Protocol (HOIP)

**Canonical-current text:**

The human operator's role is execution, not decision-making.

The human operator does effectively one thing:
1. **Confirm a crafted order.** Claude crafts the exact order through the IBKR connector (`create_order_instruction`) and surfaces a tap-to-confirm deep link; the human operator opens the link, reviews the pre-filled order in IBKR, and confirms it (or declines). The human operator never types ticker, side, quantity, price, order type, or duration — Claude crafts all of them. For security types the connector cannot craft (currently anything other than Equity/ETF — e.g. options), Claude falls back to a text order block the human operator enters manually, explicitly labeled as a manual-entry fallback and **carried in the `[Claude] Confirm order` calendar event** in place of the deep link — never chat-only, since routine chat is unmonitored (Claude_Task_Plan.md "Routine chat is unmonitored — the calendar is the binding human-facing surface").

All analytical work — thesis construction, position reviews, research-deferral checkpoints, re-screens, foundation-change and constraint-relaxation reviews, router reviews — runs autonomously: in-session in the triggering routine, or via the `Pending_Analysis.md` queue drained daily by D2. The operator is never asked to paste an analysis prompt into a fresh chat.

Three prior actions are retired:
- **Screenshotting IBKR is obsolete.** Claude reads the human operator's positions, balances, live orders, executed fills (with exact price/commission/realized P&L), and live + historical market data directly through the IBKR connector (§11). Claude never asks for a screenshot.
- **Persisting Claude-produced files is obsolete.** Claude routines write project files directly.
- **Pasting analysis prompts into fresh chats is obsolete.** Thesis construction and every other Claude-only analysis step run in-session or via the autonomous `Pending_Analysis.md` queue — never as a human-pasted calendar event.

The human operator does NOT verify commissions, make EV decisions, monitor markets intraday, watch sell-side wires, parse earnings prints in real time, decide execute-vs-skip on staged orders, decide override-vs-honor on NO-GO recommendations, choose convergence targets, position sizes, limit prices, or invalidation criteria, or read project sources to understand context Claude could resolve internally.

If a workflow requires the human operator to do anything beyond confirming crafted orders, that workflow is broken and Claude redesigns it before staging anything.

**Claude resolves all decisions internally.** Claude makes every decision the framework requires — execute or skip, GO or NO-GO, target selection, sizing, timing, invalidation criteria — without human operator input. The human operator's *judgment* is never solicited: Claude does not ask whether to place a trade; it resolves GO/skip itself and surfaces only the crafted order. The tap that confirms a crafted order to IBKR is the human operator's *execution* role — the physical act of placing the order — not a decision the human operator is being asked to make. If a decision genuinely cannot be made without information Claude does not have, Claude defers it to a future autonomous routine — a `Pending_Analysis.md` queue entry (drained daily by D2) with a `due_date` set to when the missing information will be available, and a conservative-default fallback. Claude documents the deferral logic in Decision_Log.md so the future routine can resume.

**Sell-side and follow-on data monitoring is Claude's responsibility.** Claude does not stage workflows requiring the human operator to "watch" anything. Where follow-on data (e.g., a peer print landing two days after entry) could affect a position, Claude uses autonomous review routines (a `Pending_Analysis.md` queue entry drained daily by D2) to handle it — no human action.

**Chat output discipline.** Claude's chat output to the human operator contains only:
1. The order(s) to execute — surfaced as crafted IBKR order instructions (the tap-to-confirm deep link plus a one-line human-readable summary `SIDE QTY TICKER TYPE LIMIT TIF`), or `no order` — AND
2. The minimum information the human operator needs to confirm a crafted order.

Claude's chat output does NOT contain: recapitulation of decision reasoning that already exists in Decision_Log.md or Portfolio_Ledger.md, adversarial-review summaries, pillar/criteria walkthroughs, "three things to flag" framings, pending-queue summaries beyond what affects the human operator's next action, theater-checks, compaction-survival notes, explanations of why a NO-GO is a NO-GO, operator-override paths when the recommendation is NO-GO.

**Project sources are for Claude, not for the human operator.** Everything Claude writes to Decision_Log.md, Portfolio_Ledger.md, Daily.md, factbase files, methodology files, and other project sources is written for future Claude sessions. The human operator does not read these files and no longer persists them — Claude routines write project sources directly (the prior "persist Claude-produced files" action is retired). Claude writes for self-comprehension at compaction-survival depth, NOT human-operator-facing summaries.

**Self-check Claude runs before each chat response:**
- Have I created any new task for the human operator beyond confirming a crafted order? (Analysis is autonomous — never ask the operator to paste an analysis prompt.)
- Have I asked the human operator to make any decision, or to take a screenshot (screenshots are obsolete — read the connector instead)?
- For every staged equity/ETF order, did I craft the order instruction (`create_order_instruction`) and surface its deep link, rather than emitting a raw text block the human must type?
- Have I included prose in chat that summarizes context already saved to project files?
- Have I deferred a decision to "human-operator's call" that I should have resolved myself?

If any answer reveals a violation, the response is revised before sending.

**Revision history:**
- 2026-06-01 (later same day): Analysis steps moved off the human calendar. Human-operator action reduced from two to effectively one (confirm crafted orders); thesis construction and all other Claude-only analysis now run in-session in the triggering routine or via the autonomous `Pending_Analysis.md` queue (drained daily by D2). The "paste a calendar-triggered analysis prompt" action is retired; the calendar holds only `[Claude] Confirm order` events. → Decision_Log 2026-06-01 "Analysis steps moved off the human calendar to in-session execution + Pending_Analysis.md queue".
- 2026-06-01: Revised to the IBKR-connector execution model. Human-operator actions reduced from four to two (confirm crafted orders via tap-to-confirm deep link; paste calendar prompts). Screenshot-capture and file-persistence actions retired — Claude reads positions/fills/market data directly through the connector and writes files directly. New §11 (IBKR Connector Protocol) added. → Decision_Log 2026-06-01 "IBKR connector integration — click-to-confirm orders + connector-driven reconciliation".
- 2026-04-27 (Sun, late): Adopted in (then-)current canonical form (four operator actions; orders emitted as IBKR-paste text). → Decision_Log 2026-04-27 "Human-operator interaction protocol adopted (Decision_Log-internal); commission policy changed; staged orders cleaned of EV-decision hooks".

---

## 2. Commission Policy — Disregarded at Decision Time

**Canonical-current text:**

Commissions are disregarded at decision time and accepted as a business cost. No "negative-EV-at-design-size acknowledgment" sections, no commission-verification hooks, no operator-decides-on-EV-at-ticket-time language. Strategy edge-decay metrics measure realized post-commission P&L empirically; that is the binding measurement, not an at-thesis-time veto. Trades with thin gross-EV-at-target margins go GO if the thesis clears the entry criteria; the realized P&L feeds back into the strategy-level edge-decay assessment as it accumulates.

**Revision history:**
- 2026-04-27 (Sun, late): Adopted in current form (replaced prior "negative-EV-at-design-size acknowledgment" framing in IBM/RTX/HCA staging entries). → Decision_Log 2026-04-27 "Human-operator interaction protocol adopted; commission policy changed; staged orders cleaned of EV-decision hooks".

---

## 3. NO-GO Records Are Context, Not Barriers

**Canonical-current text:**

A prior NO-GO disposition for a name does NOT auto-fail a future thesis on the same name. Each fresh trigger event (new earnings print, fresh post-event window, new catalyst, new information layer) merits fresh thesis-construction evaluation against the relevant strategy's entry criteria. The prior NO-GO record is one input to the new evaluation — context, not barrier — but does not artificially inflate the threshold to enter.

This rule applies symmetrically across strategies: a prior Strategy D NO-GO does not propagate as a barrier for a Strategy C or B entry on the same name (the strategies have different mechanisms); a prior Strategy B NO-GO on one event does not gate a Strategy B re-evaluation on a structurally distinct subsequent event (e.g., AXSM 2026-05-02 FDA-approval criterion-1 NO-GO did not gate AXSM 2026-05-04 Q1-print criterion-4 NO-GO; each is a separate event with its own 10-day post-event window).

The cost of occasional wasted thesis-construction work on structurally-closed names is accepted; the benefit of preserving framework integrity (no Closed_Names.md style permanent gate) is paramount.

**Revision history:**
- (foundational): Implicit from experiment inception; framed explicitly across multiple Decision_Log entries (2026-04-26 D outcome GOOGL precedent; 2026-04-27 GOOGL C precedent; 2026-05-04 AXSM Q1-print precedent; 2026-05-03 lifecycle-architecture entry naming the rule). No standalone protocol-introduction entry; rule emerged from operating practice and is authoritative as of 2026-05-03 factbase-architecture session.

---

## 4. Pre-Mortem Cycle Turn-Batching

**Canonical-current text:**

Within an orchestrating Claude session, each pre-mortem review cycle is handled in a single batched turn rather than across multiple turns:
1. User pastes attacker output.
2. Orchestrating session in one turn (a) performs in-conversation independent review, (b) flags theater-check, (c) decides on stop conditions or applies revisions, (d) presents updated Strategy.md, (e) drafts the next cycle's attacker prompt.
3. User runs the next attacker incognito and pastes back, repeating.

This is an operational efficiency choice — it does not change the underlying single-session architecture (single-session attacker + in-conversation review per Experiment_Parameters.md rev 14 remains in force). The "confirm before applying fixes" step from earlier cycles was theater given the user's standing instruction to proceed with the orchestrator's recommendation.

**Exception**: Reintroduce an intermediate confirmation turn ONLY when the orchestrator's recommendation involves a strategy-design change (e.g., the rev 3 short-side-stop-loss decision in Strategy B), in which case explicit user confirmation is appropriate before applying.

**Revision history:**
- 2026-04-25: Adopted. → Decision_Log 2026-04-25 "Operational decision: pre-mortem cycle turn-batching".

---

## 5. Deployment-Risk Stop + Forcing Question (Adversarial Review Cycling)

**Canonical-current text:**

Substantive protocol lives in Experiment_Parameters.md rev 15 (immutable). Summary for cross-reference:

1. **Deployment-risk stop (pass condition 1(b)).** Orchestrating session may invoke saturation acceptance when remaining Tier 1 items pass four screens: (i) do not contradict any specific quantitative claim the artifact makes about its own loss-bounding, (ii) do not omit a top-five AI_Edges disadvantage from req-4 enumeration, (iii) do not introduce or leave in place a trigger that fails to detect the failure mode it nominally exists to detect, and (iv) do not break self-containment for a numbered requirement.

2. **Forcing question (mandatory pre-cycle assessment).** Before drafting the next cycle's attacker prompt, the orchestrating session must explicitly answer in writing: "If we accept the artifact at its current revision with these residual Tier 1 items, would that change deployment risk vs. fixing them first?" Answer must be (a) yes-continue / (b) marginal-stop / (c) no-stop with substantive reasoning.

3. **Cycle-count soft cap.** Starting at cycle 5, orchestrating session must explicitly justify continuation in Decision_Log rather than defaulting through "stop conditions don't fire." Burden of proof shifts after cycle 5.

**Revision history:**
- 2026-04-25 (during Strategy B cycle 4 → 5 transition): Introduced as Experiment_Parameters.md rev 15. → Decision_Log 2026-04-25 "Architectural decision: deployment-risk stop + forcing question (Experiment_Parameters.md rev 15)".

---

## 6. Decision-Log Lifecycle Policy

**Canonical-current text:**

Three-tier file structure for decision-log management:

1. **`Decision_Log.md` (LIVE)** — read by all sessions; contains entries that are still operationally relevant per the W5 lifecycle rules. Pruned weekly by W5.
2. **`Decision_Log_Archive_<YYYY>_<QN>.md` (per-quarter ARCHIVE)** — one file per calendar quarter; appended-to throughout the quarter as W5 archives matured entries; closed at quarter-end. Read only by monthly+ cadence prompts.
3. **Factbases (`B_Sub_Pattern_Taxonomy.md`, `Watchlist.md`, `Operating_Protocols.md`)** — durable signal extracted from Decision_Log entries by W5 PRE-ARCHIVAL MIRRORING step. Read by all cadences.

**W5 lifecycle rules (entry STAYS in live if ANY of (a)-(g) is true):**
- (a) ENTRY records for currently-open positions (across A, B, C, D, E)
- (b) ACTIVE deferrals (deferred decisions not yet resolved)
- (c) PROTOCOL revisions still canonical (i.e., the revision is in current force)
- (d) Recent NO-GO entries within retention window per Strategy: 14 days for B; 30 days for C; 60 days for A; 90 days for D and E
- (e) Recent ROUTER calls within retention window: most-recent M1 call per strategy stays live; older M1 calls archive
- (f) Recent SESSION-END consolidation entries within 14 days
- (g) Open ADVERSARIAL REVIEW records (review not yet completed)

If all (a)-(g) are false → archive. Live file retains a single-line pointer `# [archived] <YYYY-MM-DD> <title> → Decision_Log_Archive_<YYYY>_<QN>.md` replacing the moved-out section.

Authoritative procedural details (sub-pattern extraction, quarter rollover, factbase mirroring sub-rules, cross-reference handling, file-edit application, output reporting): see Claude_Task_Plan.md §W5.

**Revision history:**
- 2026-05-03 (Sun, ~late afternoon MT): Architecture established (3-tier file structure, lifecycle rules a-f, sub-pattern extraction). → Decision_Log 2026-05-03 "Decision-log lifecycle architecture decision".
- 2026-05-03 (Sun, evening MT): Factbases extended (Watchlist.md + Operating_Protocols.md added; PRE-ARCHIVAL MIRRORING step inserted; rule (c) reformulated as canonical-mirroring). → Decision_Log 2026-05-03 "Watchlist.md and Operating_Protocols.md factbases added".
- (subsequent Claude_Task_Plan revision before 2026-05-10): Lifecycle rules refined to current (a)-(g) form (separate retention windows by strategy; explicit session-end and adversarial-review rules; renaming W4 → W5). Reflected in current Claude_Task_Plan.md §W5.

---

## 7. File Conventions and Read-Access Scope

**Canonical-current text:**

**Live state files** (edited in place): Decision_Log.md, Portfolio_Ledger.md, Watchlist.md, Operating_Protocols.md, Regime_State.md.

**Cadence-output files** (overwritten each run): Daily.md, Weekly_*.md, Monthly_*.md, Quarterly_*.md, Annual_*.md.

**Per-quarter archives** (append-only quarterly): Decision_Log_Archive_<YYYY>_<QN>.md.

**Factbases** (extracted durable signal):
- `B_Sub_Pattern_Taxonomy.md` — Strategy B criterion-4 NO-GO sub-patterns; written by W5 from individual NO-GO entries; read by thesis-construction sessions instead of scanning scattered NO-GO entries.
- `Watchlist.md` — names queued for re-evaluation under specific conditions; written by D2 / W4 / M4 (action-conversion routines) for in-cycle additions and W5 (mirror reconciliation); read by all cadences.
- `Operating_Protocols.md` — canonical operational protocols; written by W5 mirror step.

**Per-cadence read-access scope:**
- **Daily / Weekly (D1, D2, D3, W1, W2, W3, W4, W5)**: live `Decision_Log.md` plus factbases. Do NOT read archive files.
- **Monthly (M1a, M1b, M2, M3, M4)**: may read live + all archive files. In practice mostly operates on current open-book state.
- **Quarterly (Q1, Q2, Q3)**: read live + all archive files.
- **Annual (A1, A2, A3)**: read everything (full citation graphs across history).

**Pointer convention** (for archived entries): live file retains a single-line replacement `# [archived] <YYYY-MM-DD> <title> → Decision_Log_Archive_<YYYY>_<QN>.md`.

**Revision history:**
- 2026-05-03 (Sun, ~late afternoon MT): File conventions and read-access scope policy established (lifecycle architecture session). → Decision_Log 2026-05-03 "Decision-log lifecycle architecture decision".
- 2026-05-03 (Sun, evening MT): Factbase taxonomy extended with Watchlist.md and Operating_Protocols.md. → Decision_Log 2026-05-03 "Watchlist.md and Operating_Protocols.md factbases added".

---

## 8. Conviction Calibration Ladder (Strategy B Reference)

**Canonical-current text:**

Strategy B GO entries calibrate target-magnitude (gap-fill %) against per-trade conviction in absolute terms, not relative-to-watchlist labels. The current empirical ladder (3 trades) anchors target choices for future B GO entries:

- **IBM (2026-04-27, MEDIUM-HIGH conviction)**: ~50%-62% gap-fill; high-conviction-absolute, sector-contagion-supported.
- **HCA (2026-04-28, MEDIUM-LOW conviction)**: ~25% gap-fill; lower-conviction with three live adversarial weights.
- **META (2026-05-05, MEDIUM conviction)**: ~25% gap-fill; same conviction as IBM but conservative-target choice reflects recurrence of 2.4 narrative-overfit risk on the "capex-overreaction V-pattern" commoditized AI strategy thesis per pre-mortem KL #2.

The gap-fill % choice IS the conviction calibration tool when the convergence target is numerical-price-level rather than event-named. Future B GO entries reference this 3-trade ladder to anchor target-magnitude choices and document where on the ladder the new entry sits with explicit reasoning.

**Daily.md scan labels** (e.g., "highest conviction" within a watchlist) are local to the scan's relative ordering and do NOT translate to absolute conviction; thesis-construction sessions apply Strategy B's actual entry criteria with absolute-scale calibration.

**Underlying framework anchor**: AI_Trading_Foundation.md 2.13 (ordinal-tier conviction calibration) + Strategy.md Strategy B pre-mortem rev 7.

**Revision history:**
- 2026-05-01: Three-trade ladder (IBM/HCA/META) explicitly framed in META GO entry. → Decision_Log 2026-05-01 "Strategy B thesis construction outcome — META GO at MEDIUM conviction".

---

## 9. Deferral Discipline (No Re-Deferral; Decide-at-Earliest-Resolvable Window)

**Canonical-current text:**

When a decision cannot be made because required information is genuinely missing, Claude defers to a future autonomous routine — a `Pending_Analysis.md` queue entry (drained daily by D2) with a `due_date` set to when the information will be available. Two rules:

1. **No re-deferral (no deferral chaining).** If the future session also cannot resolve, Claude does NOT defer again. The conservative-default fallback is documented in the original deferral entry and fires automatically at the next checkpoint.

2. **Decide at the earliest resolvable information window.** If multiple checkpoint sessions are scheduled and the earliest one has sufficient information, Claude resolves there and cancels the later events as redundant (e.g., HCA criterion (iv) UHS Apr-27 AMC parsed Mon evening rather than Tue 9:25 AM ET; Tue event cancelled).

**Apply pattern**: gate-failure entries document branch (a) clear / (b) single-deferral-with-conservative-default. Branch (b) cannot fire twice on the same gate.

**Revision history:**
- 2026-04-28 (Tue): Pattern established via HCA criterion-(iv) Mon-evening resolution + Tue 9:25 redundant-event cancellation. → Decision_Log 2026-04-28 "HCA fill captured; Apr 28 SGOV cycle reconciled" compaction-survival note (e).
- 2026-05-04 / 2026-05-05: Pattern reinforced via META Funds-on-Hold gate (b) single-deferral Mon → Tue (a) clear; conservative-default fallback would have fired at Tue if also blocked.

---

## 10. No Invented Position Caps — Strategy-Level Concurrent Position Limits

**Canonical-current text:**

Claude must **never invent a total concurrent position cap** for any strategy unless that cap is explicitly stated in Strategy.md for that strategy. Operational habit, portfolio monitoring convenience, or analogy to a different strategy's cap are not sufficient grounds to introduce one.

**Strategy B has no position caps of any kind (Rev 35 update).** As of Strategy.md rev 35 (2026-05-30, owner directive), the per-GICS-sector cap of 3 concurrent B positions is **removed**, on top of the (never-existent) total-position cap. There is now **no holdings-count limit on B at any level** — not total, not per-sector. Any entry that passes criteria 1–5 is eligible regardless of how many other B positions are open or how many are already in the same GICS sector. *(Prior rev 7–34 text — "B permits multiple concurrent longs (sector cap is 3 per GICS sector, no total-position cap)" — is superseded on its sector-cap clause by rev 35.)* Concurrent-position correlation is handled by **monitoring only** (KL #12 metric (d), below), never by a cap.

**Do not express concurrent position counts as X/N** (e.g., "4/5", "5/5", or "3/3" for a sector) when N is not a cap defined in Strategy.md. As of rev 35 there is **no** B holdings-count cap at any level, so no X/N framing is valid for B. If tracking the count is useful, write it as an absolute count ("4 concurrent open B positions; 2 in Apparel Retail"), not against any ceiling.

**Slot-gate protocols, slot-contingent staging, and slot-saturation language are prohibited** unless rooted in a Strategy.md-defined cap.

**KL #12 monitoring — correct interpretation of the two metrics:**

Strategy.md Section 6 defines two monthly monitoring checks (not entry gates):

- **(d) Average pairwise correlation > 0.5** — this is the real risk indicator. If active long B positions are moving together above this threshold, the per-trade 2% loss bound no longer bounds *portfolio-level* loss, because the positions are effectively acting as one. Flag for KL #12 escalation evaluation. This metric does meaningful work.

- **(b) Long exposure > 10% of strategy portfolio** — this is a count-based proxy that fires when ≥6 positions are open at 2% each. It does not independently measure risk. The 2% entry cap already bounds per-trade downside; more *uncorrelated* positions add diversification, not risk. The 10% flag is only meaningful insofar as it prompts checking metric (d). **It is not an entry gate and must not be treated as a position limit.** Claude must not decline or defer a GO entry because open long exposure approaches or exceeds 10%.

The correct operational read: enter every thesis that clears criteria 1–5 (no sector or total count cap applies as of rev 35); check metric (d) at each monthly review; flag only if average pairwise correlation exceeds 0.5.

**Revision history:**
- 2026-05-24: Protocol established after audit found a false "5-concurrent-cap" had been introduced by Claude in commit 718204a (ZBRA fill capture 2026-05-14) with no Strategy.md basis and no documented rationale. Cap was removed from all operational documents. → User instruction 2026-05-24.
- 2026-05-30: Per owner directive, Strategy.md rev 35 removes ALL holdings-count caps across A/B/C/D — including B's per-GICS-sector cap of 3 (the one cap the 2026-05-24 cleanup had retained). §10 updated: B now has no count cap at any level; KL #12 metric (d) pairwise-correlation monitoring is the sole concurrent-position-correlation control. D's 10-position/theme/correlation-bucket count caps are likewise removed (D's 30%-of-NAV exposure cap and minimum-5 floor retained). → Decision_Log 2026-05-30 "Holdings-count caps removed by owner directive"; User instruction 2026-05-30.

---

## 11. IBKR Connector Protocol

**Canonical-current text:**

An IBKR connector (MCP server) gives Claude routines direct, authenticated access to the human operator's live brokerage account and market data. It is identified by its tool names, not by a server ID (the server ID is not stable across sessions). The tools:

- **Order instructions (the click-to-confirm execution path):** `create_order_instruction` (crafts a saved order and returns `{id, url}` where `url` is a deep link the operator taps to review-and-confirm in IBKR), `get_order_instructions` (lists pending crafted instructions), `delete_order_instruction` (cancels a pending instruction). **Equity and ETF only.**
- **Live account state (replaces screenshots):** `get_account_summary` (net liquidation, buying power, available funds, margin, day-trades-remaining), `get_account_positions` (per-position qty / market price / market value / unrealized P&L / `contract_id`), `get_account_balances` (cash + market value by currency), `get_account_orders` (live working orders + fill status), `get_account_trades` (executed fills with exact price, size, **commission**, **realized P&L**, time, and `order_id`).
- **Market data — the operator's IBKR market-data subscription (realtime):** `get_price_snapshot` (live bid/ask, last + timestamp, change, volume, IV, etc.), `get_price_history` (OHLCV bars), `search_contracts` (resolve ticker/name → `contract_id`). Prices are served **realtime on the exchanges the operator is subscribed to** (delayed only where unsubscribed; frozen / delayed-frozen are not served). This is the most accurate live source and is **authoritative over any web or delayed quote** — use it as the primary quote everywhere (CTC verification, convergence checks, marketable-limit crafting, position marks); web quotes are a fallback only when the connector lacks the instrument. **Realtime-awareness:** during RTH a realtime quote has `last.ts` within seconds of "now" and live bid/ask sizes; if `last.ts` is stale or bid/ask returns empty (e.g. pre-market / illiquid), treat the quote as not-live and base any limit on prior-close with a wider marketable buffer rather than crafting on a stale price. **Prior-close lag (data-quality guard):** `get_price_snapshot`'s prior-/previous-close field can trail the most recent settled session by one trading day, so for any close-to-close (CTC) verification, convergence check, or position mark the **authoritative close is the dated bar from `get_price_history`** — cross-check the snapshot's close against the latest `get_price_history` bar and use the history bar when they disagree (the 2026-06-05 W3 position deep-dive caught `get_price_snapshot` returning the 6/4 close for four names while `get_price_history` had the correct 6/5 close). Query `SMART` (default) for the consolidated best quote; name a primary listing exchange only when a specific venue is required.

**Execution model — Claude crafts, the human confirms.** `create_order_instruction` does NOT execute a trade. It places a *pending instruction* into the operator's IBKR app that the operator must open (via the returned deep link) and confirm before anything reaches the market. Claude therefore has no execute authority; the operator's confirm tap is the single execution gate. This preserves the experiment's invariant — Claude decides, the human executes — while removing the manual data-entry step (and the operator-discretion limit drift it caused). The deep link opens the operator's full pending-instruction queue, so one tap surfaces every instruction Claude has crafted; per-order calendar events exist for *timing* and a human-readable summary, not because each needs a distinct link.

**Order-craft discipline.** When a routine stages an equity/ETF order it: (1) resolves the `contract_id`; (2) pulls a live `get_price_snapshot` and sets a marketable limit (or MARKET when the objective is assured execution); (3) calls `create_order_instruction(contract_id, side, quantity, order_type, limit_price, time_in_force)`; (4) records the returned instruction `id` in Portfolio_Ledger.md alongside the staged-order details; (5) puts the deep link, the `SIDE QTY TICKER TYPE LIMIT TIF` summary, and the instruction `id` into the order-confirmation calendar event. If a staged order is later cancelled/superseded before the operator confirms, Claude calls `delete_order_instruction` to clear it.

**Time-in-force is `DAY`, always — never `GTC`.** The connector exposes **no modify/amend endpoint**: a crafted order's price, size, side, or duration cannot be changed in place. The only available actions are `create_order_instruction` (craft new), `delete_order_instruction` (clear a still-pending, not-yet-confirmed instruction), and `get_order_instructions` (read); a *confirmed working order* can be cancelled only by the operator inside IBKR (the connector cannot cancel a live working order). "Modifying" an order therefore always means delete/cancel + re-craft. Given that, **every order Claude crafts — entry or exit, regardless of whether its thesis intends it to rest for days — is `time_in_force: "DAY"`, never `GTC` (and never `OVT`/`OND`/`OPG`).** A persist-and-wait order (a limit resting below the market for a pullback entry, or above it for an exit) is **not** crafted once as GTC and left to sit; it is **re-crafted fresh as a new DAY order each trading session it is meant to remain live** — day → day → day → filled, rather than gtc → filled. The daily re-craft is the point of the policy, not overhead: each session's `create_order_instruction` is the checkpoint at which the limit is re-pulled against a live `get_price_snapshot` and re-set to the current market if the thesis warrants — the adaptive re-pricing that a GTC's multi-day rest would foreclose (and since there is no modify endpoint, a resting GTC could only be re-priced by delete + re-craft anyway, so DAY gives up nothing and forces the daily review). A still-resting order that should persist is re-crafted by the next session's staging-integrity sweep (D2/D3); one whose entry window has closed or whose exit is no longer required is simply allowed to expire at session close. (Operator-discretion duration changes at confirm time are outside Claude's control, but Claude itself never crafts a non-DAY TIF.)

**`contract_id` discipline.** `contract_id` is the connector's instrument key. Cache each open position's `contract_id` in Portfolio_Ledger.md. Resolve new tickers via `search_contracts`, selecting the **US primary listing**: `country_code` US, primary exchange (NYSE / NASDAQ / ARCA / BATS), the `STK` (or ETF) section, and an exact symbol match — never a foreign listing, leveraged/inverse derivative, or same-named ETF. When in doubt, confirm against `get_price_snapshot`/`get_price_history` before crafting an order.

**Fill reconciliation is connector-driven, not screenshot-driven.** No fill-capture screenshot events are created. Reconciliation is a daily pull (D2 Step 0; see Claude_Task_Plan.md), idempotent by `trade_id`: read `get_account_trades` over a multi-day window, match fills against the `trade_id`s already recorded in Portfolio_Ledger.md, and for each new fill write the exact price / size / commission / realized P&L / time into the ledger and the position's Decision_Log record — flipping ORDER-STAGED→OPEN or exit-pending→CLOSED. Realized P&L is taken from the connector's `realized_pnl` field, never inferred. Multi-session fills (a persist-and-wait order re-crafted DAY across several sessions, or any legacy/operator-placed GTC still working) and exchange-split partial fills (aggregate by `order_id`) are caught by the window. The "PROVISIONAL fill / reconciliation owed to a screenshot session" failure mode is structurally eliminated.

**Source-of-truth boundary.** The connector is authoritative for fills, positions, cash, live orders, and quotes. `Portfolio_Ledger.md` remains authoritative for *strategy-bucket cost-basis attribution and per-strategy NAV* — the connector has no concept of the A/B/C/D/E strategy buckets. Reconciliation maps connector fills onto strategy buckets; when the connector's account-level cash/positions drift from the ledger (dividends, fees, reinvestments), the connector is the truth and the ledger is corrected to match, with the strategy attribution preserved at the cost-basis level. (Detection of that drift + the deterministic per-strategy attribution decision-tree are codified in §13.)

**Live data in analysis.** Thesis-construction, position deep-dives, exit-checks, and daily scans use `get_price_snapshot`/`get_price_history` for quotes and bars (close-to-close verification, convergence-target checks, marketable-limit computation) and `get_account_positions`/`get_account_summary` for exact holdings and execution-feasibility checks. **The 2% position-sizing base is the per-strategy sub-portfolio NAV from `analytics.strategy_nav` (BigQuery — the `sizing_base_2pct` column, ≈ $37.7/strategy; Portfolio_Ledger.md mirrors it), per Strategy.md "2% of strategy portfolio", NOT account net-liquidation: the connector has no A/B/C/D/E buckets, so net-liq (~$9,460) is the whole-account figure and oversizes ~5× if used as the base. Sanity tripwire: a computed single-name entry over ~$50 (or >3% of the sub-portfolio) means the wrong base was used — recompute off the sub-portfolio.** Web quotes are a fallback only when the connector lacks the instrument. Beyond last/bid/ask, `get_price_snapshot` supplies dollar ADV (`avg-90d-usd-volume` when populated — else derive from `get_price_history` volume×close — for the B criterion-1 liquidity gate), 13/26/52-week range (`misc-statistics`), momentum / pre-rally context (`year-to-date-change` + the 52-week range + price-history returns, feeding B sub-pattern 3 and criterion-2 disproportion; the `cumulative-perf-*` fields are ETF/fund-oriented and usually empty for single stocks), volatility (`implied-vol-underlying`, `implied-volatility-percentile`, `historical-vol`), and options analytics (`option-midpoint-iv`, `option-open-interest`, `underlying-today/avg-option-volume`) for Strategy A/C options theses — the connector supplies options *data* even though it cannot craft options *orders*. Pull `get_price_history` with `include_corporate_actions: true` so splits / special dividends are flagged and never read as price moves (and to attribute account-level drift during D2 Step 0 reconciliation).

**Revision history:**
- 2026-06-01: Protocol established on IBKR-connector availability. Order execution moved from operator-typed IBKR-paste blocks to Claude-crafted click-to-confirm order instructions; fill capture moved from operator screenshots to connector reads; live account + market data made available to all routines. → Decision_Log 2026-06-01 "IBKR connector integration — click-to-confirm orders + connector-driven reconciliation".
- 2026-06-04: Corrected a sizing-base error in "Live data in analysis" (mirrored in Claude_Task_Plan.md §"IBKR connector usage"). Both summaries had said the 2% base was account net-liquidation ("2%-NAV sizing on live net-liquidation"), which contradicts Strategy.md ("2% of strategy portfolio") and the per-strategy-NAV source-of-truth boundary above, and caused the MDT 2-share / ~$156 oversize (2026-06-03; ~5× intended). Base clarified to the per-strategy sub-portfolio NAV; added a >~$50 sanity tripwire; Portfolio_Ledger.md Operational Notes gained a standing "Position-sizing base" note. → Decision_Log 2026-06-04 "MDT B sizing correction + base-NAV doc fix".
- 2026-06-05: Time-in-force policy set to **DAY-only (never GTC)** for all Claude-crafted orders, after confirming the connector has no modify/amend endpoint (only `create`/`delete`/`get` order instructions; a confirmed working order is cancellable only by the operator in IBKR). A persist-and-wait order is re-crafted fresh as a DAY order each session rather than rested as GTC, which makes each session's craft the natural limit-re-pricing checkpoint (and costs nothing, since with no modify endpoint a GTC could only be re-priced by delete + re-craft anyway). Added the DAY-only rule + the daily-re-craft mechanism here (§11) and propagated to Claude_Task_Plan.md (order-craft summary, D2 Step 0 still-working note, D3 staging-integrity re-craft step, exit-staging). Historical fill records (operator-discretion GTC modifications already executed) are left as factual records, unaltered. → Decision_Log 2026-06-05 "Order time-in-force policy → DAY-only (no GTC); connector has no modify endpoint".
- 2026-06-07: Added the **prior-close lag data-quality guard** to "Market data" — `get_price_snapshot`'s prior-/previous-close field can trail the latest settled session by a trading day, so close-to-close verification, convergence checks, and position marks take the authoritative close from the dated `get_price_history` bar (cross-check; use history when they disagree). Codifies the fix for the 2026-06-05 W3 deep-dive, where `get_price_snapshot` returned 6/4 closes for four names while `get_price_history` had the correct 6/5 closes. (Connector-feed issue, not BigQuery — `events.daily_marks` already ingests from `get_price_history`.) → decision-log data-quality entry.

---

## 12. Queue Lifecycle and Daily Archive Policy

**Canonical-current text:**

The two drain-to-completion queues — `Pending_Analysis.md` (drained daily by D2) and `Pending_Adversarial_Reviews.md` (drained by the Adversarial Review routines) — are cleared **daily**, not on a retention window. Rationale: unlike the append-only `Decision_Log.md` (never read end-to-end by a routine; pruned weekly by W5), a queue is read **to completion** every day by its drainer, so a completed entry left in place is needlessly re-read each day.

Each day **D3 Calendar Hygiene** sweeps every entry at a terminal `status` (`complete`/`superseded`) out of its live queue into the queue's daily archive (`Archived_Analysis.md` / `Archived_Adversarial_Reviews.md`): the full block is appended (tagged with an `archived:` date) and then removed from the live file entirely — **full clear, no pointer line** (this differs from the Decision_Log archive, which leaves a pointer). The live queue retains only actionable entries (`pending`, plus the adversarial queue's in-flight `recommendation-complete` / `attacker-complete`) plus its header/schema preamble.

Lookup: an id absent from a live queue is in that queue's daily archive. The durable verdict/outcome record lives independently in the per-review output files (`Adversarial_Review_<id>_*.md`), `Regime_State.md`, and `Decision_Log.md` — gates needing a completed review's result read those, not the queue.

Read-access: the daily archives are append-only cold traceability; Daily/Weekly routines do not read them for decision input (D3's mechanical sweep-append is exempt). Monthly+ cadence may read them (Q1 reads the adversarial daily-archive for prior-quarter review records).

Authoritative procedural details (the D3 sweep step, append-only file-write convention): see Claude_Task_Plan.md "Queue lifecycle and daily archive policy" and §D3.

**Revision history:**
- 2026-06-04: Policy established. Queues moved from "mark complete + retain indefinitely" to daily full-clear-to-daily-archive via D3; `Archived_Analysis.md` + `Archived_Adversarial_Reviews.md` created; supersedes the deferred "quarterly housekeeping routine (out of scope)" note formerly in Claude_Task_Plan.md's adversarial-queue schema. Initial sweep migrated 3 completed analyses (HPE, OKTA, monitor-KL12) + 3 completed divergence reviews (div-C/-D/-E-202605-1). → Decision_Log 2026-06-04 "Queue lifecycle — daily full-clear-to-daily-archive policy established".

---

## 13. Account-Level Cash/SGOV Reconciliation, Drift Attribution & Cash Flattening

The five strategy sub-portfolios share one IBKR account; undeployed capital sits in the SGOV park. The connector has no A/B/C/D/E buckets, so per-strategy allocation is tracked in Portfolio_Ledger.md at the cost-basis level (per-strategy SGOV-share allocation + cash residual). Account-level events that are NOT strategy trades — cash dividends, interest, account fees, deposits/withdrawals, and operator-initiated cash operations (e.g. the operator selling SGOV to clear a negative cash balance left by accumulated commissions) — change live cash/SGOV without, by themselves, telling Claude which strategy they belong to. This protocol detects that drift and attributes it deterministically so per-strategy budgets stay correct. It runs as part of D2 Step 0, every daily run, before any sizing or staging.

**Invariant (the accounting target).** All undeployed capital lives in the shared SGOV park; account USD cash is held at ≈ $0 (within the no-act band in E). Consequently each strategy's **available (undeployed) funds = its SGOV-allocation value + its (near-zero) cash residual**, and summing across strategies: **Σ available funds = total SGOV market value + total USD cash = total undeployed NAV**, with the per-strategy SGOV-share allocation summing exactly to the connector's SGOV share count (the reconciliation basis in A.1). (Per-strategy *deployed* NAV — the 2%-sizing base in Strategy.md — additionally includes that strategy's open-position market value; available funds ⊂ NAV, and is the SGOV slice of it.) Detection (A–C) keeps the per-strategy split correct; cash flattening (E) drives account cash to ≈ $0 by auto-crafting an SGOV order so the invariant holds in practice, not just on paper.

**A. Detection — the balance tripwire (reconcile SHARES and CASH, both exact from the connector; no mark dependence).**
1. Expected (ACCOUNT-LEVEL via BigQuery — Portfolio_Ledger retired 2026-06-06 per §15): the events-side total from `analytics.account_reconciliation` (deposits + realized + open-position unrealized + dividends) and the per-strategy budget from `analytics.strategy_nav` (`available_funds` / `sizing_base_2pct`). The reconciliation is account-level (no per-strategy SGOV-share ledger): compare the connector's live NLV / SGOV shares / cash to the events-side expected and flag any residual > ~$1 (the per-strategy split is `strategy_nav`-derived, not a hand-kept allocation).
2. Live = `get_account_positions` SGOV shares (contract_id 424099317) + `get_account_balances` cash.
3. Δ = live − expected, netting out commissions / realized-P&L of fills reconciled earlier in this Step 0 (already attributed in the trade loop).
4. Attribute every non-zero residual per C below. A residual that remains UNEXPLAINED after cause-finding and exceeds ~$1 is a hard STOP — do not size or stage anything until it is explained. Sub-$1 unexplained residue is documented as rounding/fee noise (equal-split), never silently absorbed.

**B. Cause-finding (tools, in order).**
- `get_account_trades` (DAYS_7+): a not-yet-recorded row — a DRIP/dividend reinvest, or an operator SGOV buy/sell — explains a share/cash move.
- `get_price_history(include_corporate_actions: true)` on held names + SGOV: cash dividends, special dividends, splits.
- `get_account_summary` / `get_account_balances` net-liq vs. Deposit History: an NLV jump with no matching trade is a deposit/withdrawal. Confirm against any settlement-hold status — a cleared hold that RAISES NLV is a deposit, not a pending outflow (Apr 28→May 7 $2,500 precedent: the "hold-within-NLV" reading was wrong).
- No connector evidence + small: account fee / interest noise.

**C. Attribution decision-tree (deterministic — then update the per-strategy allocation in Portfolio_Ledger.md).**
- Dividend / interest on a strategy-owned holding → that holding's strategy.
- Dividend / interest on the shared SGOV park → pro-rata across A–E by current SGOV-share allocation.
- Deposit / withdrawal → equal-split across active strategies (standing deposit methodology) unless the operator states an allocation.
- Commission / fee tied to a fill → the strategy that traded (already done in the Step 0 trade loop; do not double-count).
- Standalone account fee / interest, no fill → equal-split across active strategies.
- Operator SGOV-sale-to-cover-a-negative-cash-balance → the deficit traces to commissions already charged to the strategies that traded; reduce those same strategies' SGOV allocation in proportion to the commissions that created the deficit (converts already-charged cash-drag into an SGOV reduction — no new strategy P&L). Repark / top-up on the next settlement cycle.
- Genuinely unexplained after B → do NOT absorb into any strategy. Log the open delta + the connector evidence in Decision_Log.md, flag it in chat, hold conservatively, and re-attempt next run (pending dividends / settlements usually resolve within 1–2 sessions). This is the only delta permitted to carry across runs, and it is explicitly tracked.

**D. Recording.** The connector is always the truth; the ledger is corrected to match, attribution preserved at the cost-basis level. Update the per-strategy SGOV/cash allocation, plus SGOV Parking Activity / Deposit History rows as applicable, and a one-line Decision_Log.md note for any non-routine or >~$1 attribution. The per-strategy SGOV-share + cash allocation MUST be kept current (it is the reconciliation basis in A.1) — a stale allocation produces false tripwire deltas.

**E. Cash flattening — auto-crafting the SGOV sweep/cover order (commission-aware).** After A–D have reconciled the day's fills and attributed any drift, flatten residual account cash into/out of the SGOV park so the Invariant above holds. Runs in D2 Step 0 (and may also run at a fill-reconciliation that leaves a large idle balance), on **settled** cash, after fills are reconciled.

1. **Balances to act on.** `settled_cash` = settled USD cash (`get_account_balances`). `free_cash = settled_cash − Σ cash required by still-pending unfilled BUY orders/instructions` (Σ qty×limit + est. commission, from `get_account_orders` + `get_order_instructions`). The **sweep** test (3) uses `free_cash` — never sweep cash a pending buy will consume. The **cover** test (4) uses `settled_cash` — cover only a *realized* debit; do NOT pre-fund a resting limit buy that may not fill. A buy placed against ~$0 cash is allowed to fill into margin (the SGOV park is the collateral) and the realized negative is cleared on the next sweep. Never pre-count pending SELL proceeds (park those only once they actually land).
2. **No-act band.** Take no action when `free_cash < +$25` (no sweep) **and** `settled_cash > −$5` (no cover) — flattening a smaller balance wastes the ~$0.35 commission. The sub-band residual is left as tracked cash (attributed per C) and clears on the next qualifying cycle.
3. **Sweep (free_cash ≥ +$25 → BUY SGOV).** Size DOWN so cost + commission can never overdraw: `shares = floor_to_4dp((free_cash − comm_buffer) / SGOV_ask)`, where `comm_buffer` ≈ $0.35 (use the connector's latest SGOV per-order commission from `get_account_trades`; take the higher, conservatively). **Buying too much is the failure mode to avoid** — a tiny positive cash residual is fine.
4. **Cover (settled_cash ≤ −$5 → SELL SGOV).** Size UP so net proceeds fully clear the *realized* debit and leave no margin balance: `shares = ceil_to_4dp((|settled_cash| + comm_buffer) / SGOV_bid)`, capped at the available SGOV holding (if a deficit ever exceeded SGOV — not the case at current scale, ~$9.2k SGOV vs ~$38 entries — sell all SGOV and flag the residual margin in chat + Decision_Log). **Selling too little is the failure mode to avoid** — a tiny positive cash residual after covering is fine. A debit between $0 and −$5 is intentionally left on margin (covering it would cost more commission than the ≈$0.001/day of margin interest); it clears once it deepens past −$5 or a positive cash event (dividend / exit proceeds) nets it out.
5. **Craft it.** `create_order_instruction(contract_id 424099317, side, quantity=shares, order_type=LIMIT at the live get_price_snapshot ask (buy) / bid (sell)` — SGOV's penny-wide spread fills a marketable limit promptly; MARKET is acceptable for an assured same-session flatten — `time_in_force=DAY` per §11). Record the instruction `id`, put the deep link + `SIDE QTY SGOV TYPE LIMIT DAY` summary into a 07:00-MT confirm-order event, and add an SGOV Parking Activity row.
6. **Attribute + close the Invariant.** Attribute the flattening order to the owning strategy(ies) via the C decision-tree (exit proceeds → that strategy; SGOV dividend → pro-rata; deposit → equal-split; deficit cover → reduce the SGOV allocation of the strategies whose buys/commissions created the deficit). Update the per-strategy SGOV-share + cash allocation so, once the order reconciles next run, **Σ per-strategy SGOV shares = connector SGOV shares and Σ per-strategy cash = connector cash (≈ $0)**. The exact fill price + commission are read back from `get_account_trades` the next D2 and the allocation precision-corrected (idempotent by `trade_id`); any leftover > ~$1 unexplained trips the A.4 hard stop.

**Connector limits / safety.** `create_order_instruction` does not execute — the operator still taps to confirm (§11), so a mis-sized sweep is caught at the confirm gate. SGOV is Equity/ETF (craftable). With no modify endpoint, a sweep/cover that needs re-sizing is delete + re-craft (§11). Never craft a sweep that would overdraw a pending buy's reserved cash (step 1).

**Revision history:**
- 2026-06-04: Section added. Codifies the cash/SGOV balance tripwire + drift-attribution decision-tree previously applied ad hoc in Decision_Log reconciliation narratives (Apr 27/28 SGOV cycles; May 5 fee equal-split; the May 7 $2,500 deposit first mis-read as a settlement hold). → Decision_Log 2026-06-04 "Account-level cash/SGOV reconciliation + drift-attribution protocol added".
- 2026-06-05: Renumbered §12 → **§13** (it had been a duplicate `## 12` alongside the Queue Lifecycle section; cross-refs in §11 and Claude_Task_Plan.md D2 Step 0 updated). Extended from reconcile-and-attribute to also **flatten cash automatically**: added the **Invariant** (undeployed capital = SGOV; account cash ≈ $0; Σ per-strategy available funds = total SGOV + cash) and **subsection E — commission-aware SGOV sweep/cover order-crafting** (sweep idle cash ≥ +$25 by buying SGOV rounded DOWN; cover cash ≤ −$5 by selling SGOV rounded UP; both include the connector commission so we never overdraw or leave a margin balance; TIF DAY per §11; operator-confirmed). The per-strategy SGOV-allocation catch-up owed since the 5/7 snapshot is to be executed by the next D2 Step 0 under the new Invariant. → Decision_Log 2026-06-05 "Auto cash-flattening to SGOV + cash/strategy-funds invariant (§13)".
- 2026-06-05 (refinement): Decoupled the two triggers per operator preference — **sweep** keys off `free_cash` (settled − pending-buy reservations; don't sweep cash a pending buy needs), **cover** keys off **realized `settled_cash`** (cover only an actual debit; do NOT pre-fund a resting limit buy that may not fill). A buy into ~$0 cash is allowed to ride on margin (SGOV collateral) until the next sweep clears the realized negative. → Decision_Log 2026-06-05 cash-flattening entry (cover-trigger refinement).

---

## 14. BigQuery Analytics Substrate & Deployed-TWR Engine

**Canonical-current text:**

A BigQuery event-sourced analytics substrate (GCP project `stock-trading-498512`, US multi-region) is the authoritative engine for the experiment's quantitative performance accounting and the semantic/analytical layer over its decision history. Routines reach it through the BigQuery MCP connector (`execute_sql` / `execute_sql_readonly`); it complements — does not replace — the IBKR connector (§11, authoritative for live fills/positions/cash/quotes) and Portfolio_Ledger.md (§11/§13, authoritative for per-strategy cost-basis attribution). Design + as-built status live in `BigQuery_System_Redesign_v2.md` ("Build status & findings"); DDL in `bigquery/*.sql`.

**Data model.** Append-only `events.*` tables (fills, position events, daily marks, parking activity, decision log, regime scores, embeddings) → `state.*` / `analytics.*` views → `perf.*` (the deployed-TWR engine). Nothing is destructively updated; corrections are new rows. `events.daily_marks` is the TOTAL-return source: per held ticker + SGOV it carries `close`, `dividend` (ex-div cash/share), and `split_ratio`, pulled daily by D2 Step 0 via `get_price_history(include_corporate_actions: true)`.

**Deployed-TWR method (authoritative).** `perf.strategy_daily` is the value-weighted daily **total-return** TWR on each strategy's active book — `r_deployed = Σ(MV_t + dividends_t − MV_{t-1}) / Σ MV_{t-1}` chain-linked over deployed days, flow-immune. It is **GROSS of commissions** (see Commission policy below). The benchmark `sgov_index` chain-links SGOV's **actual** close+dividend total return (`analytics.sgov_daily_return`), not a risk-free proxy.

**Commission policy (2026-06-05 owner directive).** Two layers, opposite treatment: (a) the **profitability metric** — the deployed-TWR and everything that judges "is the strategy working" (gate, kill triggers, excess-vs-SGOV) — is computed **GROSS of commissions**, because the fixed ~$0.32/fill commission on ~$30 (2%-of-sleeve) positions (~1%/fill) is a SCALE artifact of the experiment's tiny capital, not the strategy's stock-selection edge; (b) the **cash/NAV accounting** — cost basis (principal + commission), realized P&L (connector net-of-commission), the §13 SGOV/cash reconciliation, and account NAV — tracks commissions **EXACTLY** (now that the IBKR connector supplies them per fill; `trade_fills.commission` + `parking_events.commission`, reconciled to the connector to the cent). The old "disregard commissions" simplification is removed from the accounting; it is retained — deliberately — only for the profitability metric and for forward order-sizing/staging (where the exact commission is unknown until the fill reconciles). `perf.kill_flags` derives the kill/gate flags (`drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`) from the latest row. **These are authoritative for deployed-TWR + kill/gate; the Portfolio_Ledger.md Performance block is the human-readable mirror of the latest `perf.strategy_daily` row** (maintenance procedure: Claude_Task_Plan.md D2 "PER-STRATEGY PERFORMANCE MAINTENANCE"; D1 kill-sweep + D2 Step H read `perf.kill_flags`).

**Anti-pattern (do NOT do this).** Never compute or seed a strategy's deployed-TWR by sequentially chain-linking the returns of CONCURRENT, independently-funded closed trades (`Π (1 + realized_pnl/cost_basis)`). They were parallel ~2%-of-sleeve bets, not sequential reinvestments; chaining them manufactures compounding that never occurred and compounds only the winners while open losers enter as a single drag. This is exactly what overstated Strategy B's 2026-06-04 FIRST-RUN seed to 1.1099 (+11%) when the validated value-weighted truth is ≈ **1.0005 (+0.05% gross — the profitability metric; ~breakeven)**, or 0.966 net-of-commission. Always use the value-weighted daily method (the engine).

**SGOV / corporate-action handling (audited 2026-06-05).** SGOV pays a monthly dividend reinvested via IBKR DRIP (`IBDRIPUS`) — its price is ~flat and its whole return is income, so it is processed as total return throughout: (1) the SGOV benchmark uses actual close+dividend total return; (2) the DRIP reinvest is classified `DIVIDEND_REINVEST` (not a trade-funded buy) and reconciled as income per §13.C (shares added, NO strategy-cash debit, pro-rata across strategies' SGOV); (3) held-STOCK dividends enter the TWR numerator (material for D's multi-month holds); (4) `daily_marks` carries `dividend` + `split_ratio`; (5) splits are handled via split-adjusted close at ingest.

**Engine validation & cutover policy.** The deployed-TWR engine was VALIDATED 2026-06-05 by a full rebuild from the connector's 14 authoritative fills + real daily marks, independently hand-checked to within 0.04% on Strategy D, so the **legacy markdown hand-computation is retired** — the engine stands alone with an automated sanity guardrail (flag an implausible daily return / unit value, not a manual re-compute). The engine is authoritative for the deployed-TWR + kill/gate flags; the Portfolio_Ledger.md Performance block is its human-readable mirror. The broader cutover — retiring the migrated data `.md` files as the operational substrate — is separate and unfinished: those files remain authoritative for narrative/state until the owner signs off, and retiring any live `.md` data file requires owner sign-off.

**Revision history:**
- 2026-06-05: Section established. BigQuery analytics substrate built (data layer; semantic precedent search over decision-history embeddings; value-weighted total-return deployed-TWR engine; daily briefing; thesis-outcomes calibration scaffold). The deployed-TWR engine + `perf.kill_flags` made authoritative for performance and kill/gate flags, with the Portfolio_Ledger.md Performance block as the mirror; D1 kill-sweep, D2 performance-maintenance, and D2 Step H rewired to the engine (parallel-run cross-check against the legacy hand-method). SGOV/corporate-action audit fixed five gaps (SGOV benchmark → actual total return; DRIP reclassified `DIVIDEND_REINVEST`; held-stock dividends in the TWR numerator; `daily_marks` gains `dividend` + `split_ratio`; splits via split-adjusted close). The buggy FIRST-RUN SEED (sequential chain-link of concurrent closed trades) replaced with the value-weighted method + an explicit anti-pattern note. Then (same day) the engine was VALIDATED by a full rebuild: the migrated `events.trade_fills`/`position_events` were found incomplete (only the 10 entry fills, no exits; NULL shares; placeholder 2026-04-22 dates), so both were rebuilt from the connector's 14 authoritative fills + 385 real daily marks; `analytics.position_lifecycle` re-sourced from `trade_fills`; the TWR view upgraded to fill-price cost basis + net-of-commission. Validated figures: **B 0.9663 (−3.37% net; +0.05% gross), D 0.9573 (−4.27%)**, both trailing SGOV 1.0041, no trigger near firing; independently hand-checked to 0.04% on D. The legacy hand-method is retired (engine stands alone). Live ledger + Decision_Log updated to the validated figures. → Decision_Log 2026-06-05 + BigQuery_System_Redesign_v2.md "Build status & findings".
- 2026-06-05 (commission policy): Per owner directive, commission treatment split into two layers (see **Commission policy** above) — the **deployed-TWR / profitability metric is GROSS of commissions** (scale artifact, not strategy edge), so the headline figures become **B 1.0005 (+0.05%, ~breakeven), D 0.9719 (−2.81%)** (net-of-commission B 0.966 / D 0.957 retained for reference); the **cash/NAV accounting is fully exact WITH commissions** (the old "disregard commissions" simplification removed now the connector supplies them — `trade_fills` commissions sum to $4.4642, reconciled to the connector to the cent). Engine view + recompute, live ledger, and design doc updated. → Decision_Log 2026-06-05 commission-policy entry.
- 2026-06-06 (forecast layer): added `analytics.deployed_twr_forecast` + the `analytics.twr_forecast_vs_actual` early-warning view (`bigquery/06_forecast.sql`) — a zero-shot `AI.FORECAST` (built-in TimesFM, no model to train/host) monitoring layer over `perf.strategy_daily` (deployed-TWR) and `events.macro_fred` (FRED-backed deep-history macro regime metrics — public St. Louis Fed CSV, no API key; `bigquery/07_fred_macro.sql`), written monthly by the new **M5. Deployed-TWR & Macro Forecast** routine. **Advisory / early-warning ONLY** — kill/gate triggers continue to fire on realised `perf.kill_flags`, never on a forecast.
- 2026-06-07 (substrate hardening): built the stored procedures the v2 design specified but never created (`ops.INFORMATION_SCHEMA.ROUTINES` was empty), which had left incremental embedding a hand-run step prone to stragglers. Added **`ops.sp_log_decision`** (atomic — appends the `events.decision_log` row **and** embeds it in one call; the decision is the durable source of truth, the embedding a derived index, so an embed failure never discards the decision and self-heals on the next call) and **`ops.sp_embed_pending`** (idempotent, self-healing incremental embedder; `bigquery/02_ai_layer.sql` + `08_ops_procedures.sql`); added **`state.embedding_health`** (one-SELECT drift monitor — `is_healthy`/`missing_rows`/`error_rows`, replaces the manual count-compare); split the queue view into a compact **`state.open_queue`** (flat routing columns + `has_note`/`has_payload`) and **`state.open_queue_detail`** (raw note/payload) so `SELECT *` is never a JSON wall (`bigquery/01_schema.sql`); and added a Schema quick-reference to `bigquery/README.md` (canonical names — e.g. decision-log date column is `entry_date`, embeddings live in `analytics` not `events`). Verified live: `embedding_health.is_healthy = TRUE` (227/227, 0 missing/0 error). → decision-log substrate-hardening entry.

---

## 15. Data-substrate cutover (`.md` → BigQuery)

**Canonical-current text:**

The migrated data domains live authoritatively in BigQuery (§14); the corresponding `.md` files are being retired as the operational substrate via a **parallel-run cutover — never a hard flip**, because the routines read/write these files live and a silent divergence would mis-drive trading. Phased: routines READ BigQuery-first with the `.md` as a cross-checked mirror; D2 **dual-writes** (event-sources to BigQuery per §14 + updates the `.md` mirror); after a clean parallel-run window + owner sign-off, each migrated `.md` DATA file is retired (git rm; reversible).

**Authoritative-source map** (source-of-truth NOW vs mirror):

| Domain | Authoritative (BigQuery) | `.md` mirror (retire after parallel-run) | Status |
|---|---|---|---|
| Deployed-TWR / kill-gate | `perf.strategy_daily` / `perf.kill_flags` | Portfolio_Ledger Performance blocks | **cut over** (2026-06-05) |
| Positions / fills / lifecycle | `events.trade_fills`, `state.current_positions` | Portfolio_Ledger position blocks | reads cut over (D1 exit-sweep); D2 dual-writes |
| Per-strategy NAV / 2%-sizing base | `analytics.strategy_nav` (`sizing_base_2pct`) | Portfolio_Ledger per-strategy NAV | **cut over** (2026-06-06); exact §13 SGOV-share split pending |
| Decisions / theses | `events.decision_log` (+ embeddings, `thesis_outcomes`) | Decision_Log.md (human audit record) | write via `ops.sp_log_decision` (append + embed atomically); precedent search via `find_precedents()`; sync via `state.embedding_health` |
| Regime / router state | `state.current_regime` (`regime_events`) | Regime_State.md | parallel-run pending |
| Queues | `events.queue_events` / `state.*` | Pending_* / Archived_* | parallel-run pending |
| Adversarial reviews | `events.adversarial_reviews` | Adversarial_Review_*.md | migrated; reads to cut over |
| Macro / regime scores | `events.macro_series`, `regime_events` | Monthly_Macro_Data_*, Monthly_Fundamental_RegimeScore | migrated (audit-only) → retirable |

**Parallel-run protocol.** A migrated routine reads BigQuery first; where the `.md` mirror still exists it spot-checks parity and flags any divergence in chat (divergence = an un-event-sourced write or a stale mirror → fix before trusting). D2 Step 0 keeps BigQuery current by event-sourcing every reconciled fill / position / decision (§14). Run until N consecutive clean cycles per domain.

**Retirement criteria.** A migrated `.md` DATA file is retired only when: (a) every routine that read it now reads BigQuery; (b) N clean parallel-run cycles, no divergence; (c) owner sign-off. Per-file, owner-gated, git-reversible. Order (lowest-risk first): audit-only files (Monthly_Macro_Data_*, Monthly_Fundamental_RegimeScore, Adversarial_Review_*, the Decision_Log/queue archives) → live-state mirrors (Regime_State, Portfolio_Ledger, the queues) → Decision_Log.md LAST (the human audit trail — retire only once the operator accepts BigQuery as the sole record, or keep it indefinitely).

**What NEVER retires (spec / working files, not migrated data):** Strategy.md, Experiment_Parameters.md, Operating_Protocols.md, Claude_Task_Plan.md, AI_Trading_Foundation.md, B_Sub_Pattern_Taxonomy.md, the C/E methodology docs, HF_Resource_Catalog.md; and the daily/weekly/monthly/quarterly WORKING files (Daily.md, Watchlist.md, Weekly_*, the non-migrated Monthly_*, Quarterly_*) — operating rules + cadence outputs, not the migrated data substrate.

**Cutover applied — 2026-06-06 (operator stopped the routines → safe to flip the reads/writes). BigQuery is now CANONICAL for EVERY migrated data domain, and this map supersedes every `.md` read/write reference to these files throughout this document and Claude_Task_Plan.md** — routines read/write BigQuery, not the retired `.md`:

| Retired `.md` | Read instead | Write instead |
|---|---|---|
| Monthly_Macro_Data_*.md | (audit-only; none) | M1a → `events.macro_series` |
| Monthly_Fundamental_RegimeScore.md | `state.current_regime` / `events.regime_events` (scope `FUNDAMENTAL_AXIS`) | M1a → `events.regime_events`; M1b reads it there |
| Adversarial_Review_*.md | `events.adversarial_reviews` | adversarial routines → `events.adversarial_reviews` |
| Decision_Log_Archive_*.md / Archived_Analysis / Archived_Adversarial_Reviews | `events.decision_log` / `events.queue_events` | archive workflow RETIRED — durable copy is `events.decision_log` / `events.queue_events` |
| **Regime_State.md** | `state.current_regime` / `events.regime_events` (scopes `STRATEGY_ACTIVATION` + `TECHNICAL_SIGNAL`) | M4 / divergence-review / D1 router-review → `events.regime_events` (scope `STRATEGY_ACTIVATION`) |
| **Portfolio_Ledger.md** (positions / perf / NAV / §13 / parking) | `state.current_positions`, `perf.strategy_daily`, `analytics.strategy_nav` (sizing/NAV), `analytics.account_reconciliation` (§13), `events.parking_events` | D2 → `events.trade_fills` + `events.position_events`; §13 reconciliation is ACCOUNT-LEVEL (account_reconciliation + strategy_nav + connector) |
| **Decision_Log.md** | `events.decision_log` + `analytics.find_precedents()` | every routine → **`CALL ops.sp_log_decision(...)`** — appends the structured row (incl. `body_md`) **and embeds it in the same call** (no separate embed step). Verify sync any time via `state.embedding_health` (`is_healthy = TRUE`). A raw `INSERT` is the legacy path — if ever used, run `CALL ops.sp_embed_pending()` after |
| **Pending_Analysis.md / Pending_Adversarial_Reviews.md** | `state.open_queue` (flat routing columns; `has_note`/`has_payload` flags) — read the full note/payload from `state.open_queue_detail` by `item_key` | enqueue / D3 sweep → `events.queue_events` |
| Decision_Log_Migration_Entry.md | (one-time artifact) | — |

The explicit WRITE instructions that would otherwise recreate one of these files are updated directly in the routines (M1a → macro_series/regime_events; M4 / divergence-review / D1 router-review → regime_events); the pervasive Decision_Log / queue / position writes follow this override. **On restart, routines read/write BigQuery per this map.**

**Retired 2026-06-06 (git rm; content verified in BigQuery; git-recoverable) — 13 files:** the audit/archive set (Monthly_Macro_Data×2, Monthly_Fundamental_RegimeScore, Adversarial_Review_*×6, Decision_Log_Archive_2026_Q2, Archived_Analysis, Archived_Adversarial_Reviews, Decision_Log_Migration_Entry).

**Also retired 2026-06-06 (git rm; owner-confirmed) — the 5 core data files:** `Portfolio_Ledger.md`, `Regime_State.md`, `Decision_Log.md`, `Pending_Analysis.md`, `Pending_Adversarial_Reviews.md`. BigQuery is canonical for them (reads/writes redirected per the map above); git-recoverable. **The `.md` → BigQuery migration is COMPLETE — no migrated data file remains; only spec + cadence-working files persist.** Notes: the §13 cash-tripwire is reframed to account-level (connector vs `account_reconciliation`; per-strategy budget via `strategy_nav`) — the exact per-strategy SGOV-share split is no longer hand-kept; `events.decision_log` holds the 221 trading-decision entries (with `body_md` narrative), while this migration's own infrastructure decision entries live in this design doc's Build status + git history.

**Kept (spec + cadence working files, NOT migrated data):** Strategy.md, Experiment_Parameters.md, Operating_Protocols.md, Claude_Task_Plan.md, AI_Trading_Foundation.md, B_Sub_Pattern_Taxonomy.md, the C/E methodology docs, HF_Resource_Catalog.md; Daily.md, Watchlist.md, the Weekly_* / non-migrated Monthly_* / Quarterly_* cadence outputs.

**Revision history:**
- 2026-06-06 (cutover applied): retired the 12 migrated/audit `.md` files (Monthly_Macro_Data×2, Monthly_Fundamental_RegimeScore, Adversarial_Review_*×6, Decision_Log_Archive_2026_Q2, Archived_Analysis, Archived_Adversarial_Reviews, Decision_Log_Migration_Entry); reads/writes overridden to BigQuery per the map above; fixed the `regime_events` D/E activation gap so `state.current_regime` is faithful; kept Regime_State / Portfolio_Ledger / Decision_Log / the live queues with documented rationale. → Decision_Log 2026-06-06 retirement entry.
- 2026-06-06: Section established — cutover framework + authoritative-source map + parallel-run protocol + retirement criteria. **Phase 1:** deployed-TWR/kill already cut over (§14); D1 exit-trigger sweep migrated to read `state.current_positions` (convergence/time-exit) with the connector for live prices; precedent lookups use `analytics.find_precedents()`. Remaining domains (regime, queues, decisions, adversarial) staged for parallel-run, then owner-gated per-file retirement. → Decision_Log 2026-06-06 cutover entry.

---

## Maintenance

- W5 (weekly Factbase & Analytics Consolidation) appends new protocol revisions to the relevant section here as they emerge from Decision_Log entries.
- When revising an existing protocol section, replace the canonical-current text with the new revision and append the prior canonical to revision history.
- Do NOT mirror NO-GO entries, position entries, calendar-recon entries, or session-end-consolidation entries — those are not protocol entries.
- If a new protocol category surfaces that doesn't fit existing sections, create a new numbered section and document it in the W5 outcome entry.

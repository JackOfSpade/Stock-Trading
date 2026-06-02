# Operating Protocols

Canonical reference for active operational protocols governing the AI-directed trading experiment. Each protocol section: title, current canonical text, revision-history list. Living document; read by all cadences. Written and maintained by W5. Future protocol revisions: revise the relevant section here, append a revision-history entry pointing back to the Decision_Log entry that documented the change.

**Created**: 2026-05-10 (first W5 run; bootstrap mirroring of canonical protocols from current Decision_Log entries per Claude_Task_Plan.md W5 PRE-ARCHIVAL MIRRORING step).

**Scope**: This file holds operational protocols only. Strategy-specific mechanics live in Strategy.md (immutable). Experiment-level parameters live in Experiment_Parameters.md (immutable). The framework's edge/disadvantage map lives in AI_Trading_Foundation.md. Decision_Log.md remains the audit trail for individual decisions; this file holds the durable operating-rule signal extracted from those entries.

---

## 1. Human Operator Interaction Protocol (HOIP)

**Canonical-current text:**

The human operator's role is execution, not decision-making.

The human operator can do exactly two things:
1. **Confirm a crafted order.** Claude crafts the exact order through the IBKR connector (`create_order_instruction`) and surfaces a tap-to-confirm deep link; the human operator opens the link, reviews the pre-filled order in IBKR, and confirms it (or declines). The human operator never types ticker, side, quantity, price, order type, or duration — Claude crafts all of them. For security types the connector cannot craft (currently anything other than Equity/ETF — e.g. options), Claude falls back to a text order block the human operator enters manually, explicitly labeled as a manual-entry fallback.
2. **Paste a calendar-triggered Claude prompt** (the prompt text lives in the Google Calendar event description) into a fresh Claude chat.

Two prior actions are retired:
- **Screenshotting IBKR is obsolete.** Claude reads the human operator's positions, balances, live orders, executed fills (with exact price/commission/realized P&L), and live + historical market data directly through the IBKR connector (§11). Claude never asks for a screenshot.
- **Persisting Claude-produced files is obsolete.** Claude routines write project files directly.

The human operator does NOT verify commissions, make EV decisions, monitor markets intraday, watch sell-side wires, parse earnings prints in real time, decide execute-vs-skip on staged orders, decide override-vs-honor on NO-GO recommendations, choose convergence targets, position sizes, limit prices, or invalidation criteria, or read project sources to understand context Claude could resolve internally.

If a workflow requires the human operator to do anything beyond the two actions above, that workflow is broken and Claude redesigns it before staging anything.

**Claude resolves all decisions internally.** Claude makes every decision the framework requires — execute or skip, GO or NO-GO, target selection, sizing, timing, invalidation criteria — without human operator input. The human operator's *judgment* is never solicited: Claude does not ask whether to place a trade; it resolves GO/skip itself and surfaces only the crafted order. The tap that confirms a crafted order to IBKR is the human operator's *execution* role — the physical act of placing the order — not a decision the human operator is being asked to make. If a decision genuinely cannot be made without information Claude does not have, Claude defers the decision to a future calendar-triggered session where the missing information will be available. Claude documents the deferral logic in Decision_Log.md so the future session can resume.

**Sell-side and follow-on data monitoring is Claude's responsibility.** Claude does not stage workflows requiring the human operator to "watch" anything. Where follow-on data (e.g., a peer print landing two days after entry) could affect a position, Claude uses calendar-triggered review sessions to handle it. The calendar event triggers Claude; the human operator's only action is to paste the prompt.

**Chat output discipline.** Claude's chat output to the human operator contains only:
1. The order(s) to execute — surfaced as crafted IBKR order instructions (the tap-to-confirm deep link plus a one-line human-readable summary `SIDE QTY TICKER TYPE LIMIT TIF`), or `no order` — AND
2. The minimum information the human operator needs to confirm a crafted order or paste a calendar prompt.

Claude's chat output does NOT contain: recapitulation of decision reasoning that already exists in Decision_Log.md or Portfolio_Ledger.md, adversarial-review summaries, pillar/criteria walkthroughs, "three things to flag" framings, pending-queue summaries beyond what affects the human operator's next action, theater-checks, compaction-survival notes, explanations of why a NO-GO is a NO-GO, operator-override paths when the recommendation is NO-GO.

**Project sources are for Claude, not for the human operator.** Everything Claude writes to Decision_Log.md, Portfolio_Ledger.md, Daily.md, factbase files, methodology files, and other project sources is written for future Claude sessions. The human operator does not read these files and no longer persists them — Claude routines write project sources directly (the prior "persist Claude-produced files" action is retired). Claude writes for self-comprehension at compaction-survival depth, NOT human-operator-facing summaries.

**Self-check Claude runs before each chat response:**
- Have I created any new task for the human operator beyond the two actions (confirm a crafted order; paste a calendar prompt)?
- Have I asked the human operator to make any decision, or to take a screenshot (screenshots are obsolete — read the connector instead)?
- For every staged equity/ETF order, did I craft the order instruction (`create_order_instruction`) and surface its deep link, rather than emitting a raw text block the human must type?
- Have I included prose in chat that summarizes context already saved to project files?
- Have I deferred a decision to "human-operator's call" that I should have resolved myself?

If any answer reveals a violation, the response is revised before sending.

**Revision history:**
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
- `Watchlist.md` — names queued for re-evaluation under specific conditions; written by D2 / W4 / M5 (action-conversion routines) for in-cycle additions and W5 (mirror reconciliation); read by all cadences.
- `Operating_Protocols.md` — canonical operational protocols; written by W5 mirror step.

**Per-cadence read-access scope:**
- **Daily / Weekly (D1, D2, D3, W1, W2, W3, W4, W5)**: live `Decision_Log.md` plus factbases. Do NOT read archive files.
- **Monthly (M1a, M1b, M3, M4, M5)**: may read live + all archive files. In practice mostly operates on current open-book state.
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

When a decision cannot be made because required information is genuinely missing, Claude defers to a future calendar-triggered session where the information will be available. Two rules:

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
- **Market data — the operator's IBKR market-data subscription (realtime):** `get_price_snapshot` (live bid/ask, last + timestamp, change, volume, IV, etc.), `get_price_history` (OHLCV bars), `search_contracts` (resolve ticker/name → `contract_id`). Prices are served **realtime on the exchanges the operator is subscribed to** (delayed only where unsubscribed; frozen / delayed-frozen are not served). This is the most accurate live source and is **authoritative over any web or delayed quote** — use it as the primary quote everywhere (CTC verification, convergence checks, marketable-limit crafting, position marks); web quotes are a fallback only when the connector lacks the instrument. **Realtime-awareness:** during RTH a realtime quote has `last.ts` within seconds of "now" and live bid/ask sizes; if `last.ts` is stale or bid/ask returns empty (e.g. pre-market / illiquid), treat the quote as not-live and base any limit on prior-close with a wider marketable buffer rather than crafting on a stale price. Query `SMART` (default) for the consolidated best quote; name a primary listing exchange only when a specific venue is required.

**Execution model — Claude crafts, the human confirms.** `create_order_instruction` does NOT execute a trade. It places a *pending instruction* into the operator's IBKR app that the operator must open (via the returned deep link) and confirm before anything reaches the market. Claude therefore has no execute authority; the operator's confirm tap is the single execution gate. This preserves the experiment's invariant — Claude decides, the human executes — while removing the manual data-entry step (and the operator-discretion limit drift it caused). The deep link opens the operator's full pending-instruction queue, so one tap surfaces every instruction Claude has crafted; per-order calendar events exist for *timing* and a human-readable summary, not because each needs a distinct link.

**Order-craft discipline.** When a routine stages an equity/ETF order it: (1) resolves the `contract_id`; (2) pulls a live `get_price_snapshot` and sets a marketable limit (or MARKET when the objective is assured execution); (3) calls `create_order_instruction(contract_id, side, quantity, order_type, limit_price, time_in_force)`; (4) records the returned instruction `id` in Portfolio_Ledger.md alongside the staged-order details; (5) puts the deep link, the `SIDE QTY TICKER TYPE LIMIT TIF` summary, and the instruction `id` into the order-confirmation calendar event. If a staged order is later cancelled/superseded before the operator confirms, Claude calls `delete_order_instruction` to clear it.

**`contract_id` discipline.** `contract_id` is the connector's instrument key. Cache each open position's `contract_id` in Portfolio_Ledger.md. Resolve new tickers via `search_contracts`, selecting the **US primary listing**: `country_code` US, primary exchange (NYSE / NASDAQ / ARCA / BATS), the `STK` (or ETF) section, and an exact symbol match — never a foreign listing, leveraged/inverse derivative, or same-named ETF. When in doubt, confirm against `get_price_snapshot`/`get_price_history` before crafting an order.

**Fill reconciliation is connector-driven, not screenshot-driven.** No fill-capture screenshot events are created. Reconciliation is a daily pull (D2 Step 0; see Claude_Task_Plan.md), idempotent by `trade_id`: read `get_account_trades` over a multi-day window, match fills against the `trade_id`s already recorded in Portfolio_Ledger.md, and for each new fill write the exact price / size / commission / realized P&L / time into the ledger and the position's Decision_Log record — flipping ORDER-STAGED→OPEN or exit-pending→CLOSED. Realized P&L is taken from the connector's `realized_pnl` field, never inferred. Multi-day GTC fills and exchange-split partial fills (aggregate by `order_id`) are caught by the window. The "PROVISIONAL fill / reconciliation owed to a screenshot session" failure mode is structurally eliminated.

**Source-of-truth boundary.** The connector is authoritative for fills, positions, cash, live orders, and quotes. `Portfolio_Ledger.md` remains authoritative for *strategy-bucket cost-basis attribution and per-strategy NAV* — the connector has no concept of the A/B/C/D/E strategy buckets. Reconciliation maps connector fills onto strategy buckets; when the connector's account-level cash/positions drift from the ledger (dividends, fees, reinvestments), the connector is the truth and the ledger is corrected to match, with the strategy attribution preserved at the cost-basis level.

**Live data in analysis.** Thesis-construction, position deep-dives, exit-checks, and daily scans use `get_price_snapshot`/`get_price_history` for quotes and bars (close-to-close verification, convergence-target checks, marketable-limit computation) and `get_account_positions`/`get_account_summary` for exact holdings and 2%-NAV sizing on live net-liquidation. Web quotes are a fallback only when the connector lacks the instrument. Beyond last/bid/ask, `get_price_snapshot` supplies dollar ADV (`avg-90d-usd-volume` when populated — else derive from `get_price_history` volume×close — for the B criterion-1 liquidity gate), 13/26/52-week range (`misc-statistics`), momentum / pre-rally context (`year-to-date-change` + the 52-week range + price-history returns, feeding B sub-pattern 3 and criterion-2 disproportion; the `cumulative-perf-*` fields are ETF/fund-oriented and usually empty for single stocks), volatility (`implied-vol-underlying`, `implied-volatility-percentile`, `historical-vol`), and options analytics (`option-midpoint-iv`, `option-open-interest`, `underlying-today/avg-option-volume`) for Strategy A/C options theses — the connector supplies options *data* even though it cannot craft options *orders*. Pull `get_price_history` with `include_corporate_actions: true` so splits / special dividends are flagged and never read as price moves (and to attribute account-level drift during D2 Step 0 reconciliation).

**Revision history:**
- 2026-06-01: Protocol established on IBKR-connector availability. Order execution moved from operator-typed IBKR-paste blocks to Claude-crafted click-to-confirm order instructions; fill capture moved from operator screenshots to connector reads; live account + market data made available to all routines. → Decision_Log 2026-06-01 "IBKR connector integration — click-to-confirm orders + connector-driven reconciliation".

---

## Maintenance

- W5 (weekly Decision Log Hygiene) appends new protocol revisions to the relevant section here as they emerge from Decision_Log entries.
- When revising an existing protocol section, replace the canonical-current text with the new revision and append the prior canonical to revision history.
- Do NOT mirror NO-GO entries, position entries, calendar-recon entries, or session-end-consolidation entries — those are not protocol entries.
- If a new protocol category surfaces that doesn't fit existing sections, create a new numbered section and document it in the W5 outcome entry.

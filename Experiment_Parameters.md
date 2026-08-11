# Experiment Parameters

**Document date:** 2026-04-23 (revision 15; revision 16 amendment 2026-07-10 — Strategy Arsenal Lifecycle autonomy conversion, owner directive; revision 17 amendment 2026-07-28 — non-fundamental in-life strategy edit path + per-position sizing relaxation row struck, owner directive; revision 18 amendment 2026-07-28 — fixed 2% position sizing RETIRED, replaced by thesis-scaled risk budgeting with hard envelopes, owner directive; **revision 19 amendment 2026-08-05 — BOTH hard CaR envelopes RETIRED (per-name ≤10%, per-strategy deployed ≤75%); sizing is now completely unconstrained numerically and governed only by the seven-factor justification + the mandatory adversarial attack on size, owner directive**)
**Purpose:** Defines the boundaries of the AI-directed trading experiment — what is being tested, what counts as success or failure, and when it stops.
**Relationship to other documents:** `AI_Trading_Foundation.md` defines AI's capabilities and limitations. The strategy document (derived in a separate project) defines the strategies themselves: how many, what they are, what they trade, and how the regime router activates them. This document defines experiment-level rules that are strategy-agnostic — they apply to any strategy composition. It operates at the strategy portfolio and experiment level, not the per-trade level. (rev 16, 2026-07-10 — Strategy Arsenal autonomy conversion.) The strategy document's machine-readable expression is now `strategy/roster.yaml`, mirrored to `state.strategy_roster` (the latest-row-per-code view over the append-only `events.strategy_lifecycle`); the "how many / what" authority is exercised autonomously by routines SL2/SL5 editing Strategy.md through the Strategy Arsenal Lifecycle below, not by a human.
**Immutability (two-tier doctrine — rev 16, 2026-07-10 amendment; rev 17, 2026-07-28 — non-fundamental in-life edit path added, owner directive).** Immutability was always a *means* to one end: a clean, uncontaminated statistical read on each strategy's edge, protecting against optimize-into-noise (`AI_Trading_Foundation.md` 2.14 recency), instruction-adherence-over-capital-preservation (2.18), look-ahead bias (2.19), and cross-session inconsistency (2.24). That end is served by freezing each strategy's *own machinery*, not by freezing the *size* of the roster. Accordingly — mirroring exactly the 2026-06 capital-allocation pivot below (lines within "Capital allocation model — 2026-06 revision"), which already carved the allocation rules out of blanket immutability into an explicitly versioned policy while leaving the evaluation machinery and 2% sizing immutable — this document's immutability splits into two tiers:

- **Immutable (per-strategy machinery, for that strategy's entire life, plus the experiment-level machinery).** Each strategy's entry/exit rules, thresholds, indicators, position-sizing methodology, kill-criteria structure, cited foundation edges/disadvantages, and its pre-mortem. A strategy's machinery **freezes at SHADOW entry** (`spec_locked_since`), not at its first live trade, so the shadow/paper forward-test measures a fixed ruleset (see "Strategy Arsenal Lifecycle" below); its official edge-measurement clock (`immutable_since`, the clean before/after boundary vs SGOV) starts at its **first PROBE trade**. Once locked, the only way to change a strategy's machinery **in a way that alters what the strategy fundamentally is** is terminate-that-strategy-and-restart-as-new (fresh pre-mortem, fresh derivation, documented post-mortem) — never a quiet edit. **NON-FUNDAMENTAL IN-LIFE EDIT PATH (rev 17, 2026-07-28, owner directive — see `AI_Trading_Foundation.md` §5.6a for the full specification and rails).** A foundation-driven constraint edit that changes **none** of the five material-structural-difference dimensions ({strategy approach, instrument scope, position-sizing methodology, regime-router structure, kill-criteria structure} — see "After termination: restart and new-experiment constraints" below) does **not** alter what the strategy fundamentally is, and may be applied in life without terminating the strategy. Rationale (owner, 2026-07-28): immutability is a *means* to a clean statistical read, and that premise is already spent — **the model of record is changed mid-strategy regardless of whether the strategy has reached an adequate trade count for analysis** (item 2.9: calibration "does not transfer cleanly to its successor"; Part 4 step 4 flips Tier 2 magnitudes to version-pending on every model change). A series already discontinuous at owner-driven model boundaries is not protected by refusing a bounded, exogenously-triggered edit. The edit is gated on all six §5.6a rails — exogenous trigger only (**any justification referencing the strategy's own realized P&L is parameter fishing and is forbidden**), loosen-only to the §5.6 computed value, sizing and kill-trigger structure excluded, a dated epoch stamp marking the measurement seam, one edit per strategy per annual cycle, and CI-enforced `spec_hash`/`revision_history` provenance. A change touching ≥1 of the five dimensions remains terminate-and-restart, unchanged. This closes the pre-rev-17 defect (A2 2026 finding F-1) in which a purely numerical foundation-driven relaxation was forbidden in place *and* rejected as a restart for differing "in more than just threshold numbers" — a closed loop with no legal exit. The shared regime-vocabulary thresholds and every existing strategy's activation thresholds also stay frozen; a newcomer only *appends* its own activation rule. Globally immutable: ~~2% sizing and then the existence of hard CaR envelopes~~ **the EXISTENCE of the per-thesis risk-budget discipline (rev 19, 2026-08-05, owner directive): a recorded seven-factor justification plus the mandatory adversarial attack on size. Both numeric CaR envelopes are retired; their existence is not required, and only a later owner directive may reintroduce either one**, the mechanical kill-trigger structure, and the **measurement-and-selection machinery itself** — the candidate-qualification tests, the two-routine adversarial-review protocol, the shadow/paper/probe graduation bars, the kill triggers, and deterministic redistribution. Revising a parameter of a *live* strategy still forces THAT strategy's termination and a materially-different successor — not the end of the whole experiment. Changing the *machinery* itself is a whole-experiment successor, reserved to an explicit owner directive.
- **Versioned policy (roster membership and N).** Which strategies exist and in what phase is revised only through the Strategy Arsenal Lifecycle (routines SL1–SL5, adversarial review, and objective readiness views), recorded as versioned revisions in `strategy/roster.yaml` with a revision history. Additive changes that do not mutate any existing instance's machinery — appending a new strategy section, adding a newcomer's own router-activation rule, adding a shared-vocabulary measurement used only by a new strategy — are explicitly **not** "revisions" and are permitted mid-run. Adding or retiring a strategy no longer "ends the experiment."

Enforcement of the immutable tier remains behavioral for the human operator but is now machine-enforced for the routines: `scripts/check_roster_consistency.py` (a CI build-gate) plus the readiness views and the `ops.roster_change_log` idempotency markers prevent a routine from mutating a locked strategy or drifting the roster. The immutable tier is load-bearing on the experiment's integrity; breaching it destroys the experiment's value. See "Strategy Arsenal Lifecycle" below for the full machinery.

---

## Terminology

Precise terminology matters in this document because the multi-strategy architecture introduces multiple financial entities that a casual reader can conflate. The following terms are used consistently throughout; readers should map each term to its precise referent rather than interpreting them loosely.

- **Account.** The single IBKR custodial account holding all capital. Singular. This is the legal/custodial entity. The account is not itself a portfolio in this document's sense — it is the container.
- **Strategy portfolio.** An externally-tracked sub-allocation of the account assigned to a specific strategy. There is one per strategy; N in total per experiment, where N is defined by the strategy document. Each strategy portfolio is tracked outside IBKR in a ledger maintained by the participant. Each has its own starting value, its own deposit share, its own deployed-capital history, its own ~~SGOV~~ **park [Rev 38, owner directive, 2026-07-15 — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13]** allocation, its own TWR, its own drawdown, its own trade count, its own gate, and its own kill triggers.
- **Deployed capital.** Within a strategy portfolio, the portion currently in active trades (not ~~SGOV~~ **park [Rev 38]** parking). Used for TWR measurement.
- ~~**SGOV parking.**~~ **Idle-capital parking [Rev 38, owner directive, 2026-07-15].** Capital within a strategy portfolio not currently deployed into active trades, held in the park — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13 — as the default idle vehicle. The park is baseline treasury management, not a strategy decision.
- **Pending newcomer.** A newly-added strategy that is frozen (non-trading) until its booked allocation reaches its probe-stake floor ($2,000); it has first claim on incoming deposits and sunset-redistribution capital until filled. See "New strategy funding" below. (There is no "held-aside pool" — terminated capital always redistributes to survivors, never sits unallocated.)
- **Strategy termination.** The termination of a single strategy's participation in the experiment via that strategy's drawdown kill trigger, mark-to-market underperformance trigger, 30-trade gate failure, runaway-success review, or per-strategy foundation-change assessment. Other strategies continue unaffected.
- **Experiment termination.** The termination of the entire experiment. Occurs when the foundation-change trigger fires in a way that affects all strategies simultaneously, or when the last active strategy terminates (leaving no active strategies), or by final determination after the last strategy's post-gate run ends.

The word "portfolio" without the "strategy" prefix does not appear in this document. Every occurrence of "portfolio" is "strategy portfolio." This prevents the recurring ambiguity of "is this the main thing or a sub-thing?" — there is no "main portfolio" in this architecture, only the account (custodial container) and the strategy portfolios (N externally-tracked sub-allocations, one per strategy).

---

## Why proceed

This workflow is a bet that future AI models will have a demonstrable edge over the autonomous-AI trading baseline. It is not a bet on beating top professional traders, and not a bet on beating passive index investing during the current-model phase.

The rationale for running the experiment now, before that edge plausibly exists, is infrastructure — building the process, calibration data, mistake catalog, and execution discipline required to deploy quickly when a sufficiently capable model becomes available. Losses during the testing period are acceptable if they are bounded by the drawdown kill criteria and produce usable data.

What transfers forward: process, documentation structure, workflow artifacts, mistake-category taxonomies. What does not transfer: model-specific numerical calibration (observed hit rates, specific bias magnitudes). This distinction matters because the experiment's value hinges on the transferable components compounding over time — not on any assumption that calibration data survives model transitions.

The multi-strategy architecture is a consequence of this "infrastructure first" framing. No single strategy can be known in advance to be the right one for the forward-testing period. Running multiple structurally different strategies in parallel, each evaluated independently, produces more infrastructure — more mistake catalog entries, more pre-mortem templates, more adversarial review evidence, more per-strategy calibration data — than any single-strategy experiment would. The cost is operational complexity. The accepted bet is that the additional infrastructure justifies the additional complexity.

---

## What is being tested

Whether specific AI-directed trading strategies, each explicitly designed to best exploit documented AI edges while compensating for documented AI disadvantages, can each achieve positive real excess returns (relative to SGOV, post-fees, post-taxes, post-inflation) measured in time-weighted return (TWR) terms, with a mechanical + AI-adversarial regime router determining when each strategy is active.

Multiple strategies run in parallel (count defined by the strategy document). Each is evaluated independently. The experiment as a whole produces evidence on each strategy's edge separately, plus evidence on the regime router's function.

Each strategy has a go/no-go evaluation gate at 30 closed positions (trades, not SGOV parking adjustments). If the gate is cleared by a given strategy, that strategy continues indefinitely until one of its kill triggers fires. If a strategy's gate is not cleared, that strategy terminates. There is no calendar cap on any strategy's duration under any circumstances.

### Measurement framework: deployed TWR vs. SGOV benchmark

Strategy evaluation is TWR-based on *deployed capital only* — the periods when a strategy portfolio's capital is in active trades, not during SGOV parking or regime-router deactivation. SGOV is the opportunity-cost benchmark: the return the participant would have earned by leaving the capital idle instead of running the strategy. A strategy that deploys capital and returns less than SGOV over the deployment period has destroyed value regardless of its nominal TWR.

TWR separates the effect of strategy decisions from the effect of capital flows — deposits and withdrawals do not affect the measured performance of the strategy. A 2% gain on deployed capital is a 2% gain whether the strategy portfolio holds $10K or $100K; a 50% drawdown is a 50% drawdown regardless of what capital was deposited when.

**Primary metrics per strategy:**

- **Deployed TWR.** TWR measured only over periods when capital was in active strategy trades, excluding SGOV parking and regime-router deactivation periods.
- **SGOV benchmark.** What SGOV would have returned over the same calendar periods during which deployed capital existed, for the same capital amounts.
- **Excess real return.** Deployed TWR minus SGOV benchmark, post-tax, post-inflation. This is the quantity the success threshold is stated on. **Tax-lot caveat (ITEM 18, 2026-07-11):** the "post-tax" figure implicitly assumes every realized loss is fully deductible; `analytics.tax_lots` / `state.wash_sale_exposure` (`bigquery/41_tax_lots.sql`) now detect account-wide wash sales (a same-ticker BUY within 30 days of any strategy's loss-realizing SELL, across strategies — this experiment deliberately runs up to `n_max=8` strategies that can independently trade the same ticker, which is exactly the cross-strategy wash-sale exposure a per-strategy view cannot see). A disallowed loss reduces the actual post-tax figure below what the naive TWR-minus-tax-rate estimate implies; this is detection/reporting only (IBKR's own 1099-B, computed off the elected cost-basis method, remains the authoritative tax figure, not this repo's approximation). **Cost-basis election (owner-confirmed 2026-07-17):** the account uses **FIFO** (the IBKR default); no specific-lot election has been made, so this repo's FIFO lot construction matches the broker's lot-by-lot accounting. If the election ever changes, update this note (OWNER_ACTIONS §4).

**Secondary diagnostic (not used for trigger evaluation):** full-strategy-portfolio TWR including SGOV parking. Useful in post-mortems for understanding what happened holistically. Not the basis for kill triggers or gate evaluation.

All thresholds in this document (drawdown, success) are stated in deployed-TWR or excess-real-return terms as specified per trigger. Reactive capital flows cannot affect the experiment's evaluation because the measurement is invariant to capital flows.

### What the experiment can and cannot deliver

This experiment targets directional signal per strategy, not statistical proof. Research on minimum viable sample sizes for strategy validation shows that proving a 2% per-trade edge with 95% confidence requires 200+ independent trades, and proving smaller edges requires thousands. Reaching that threshold is technically possible per strategy given uncapped duration, but model deprecation (`AI_Trading_Foundation.md` 2.9) will almost certainly occur over the multi-year horizon required at typical catalyst-driven trade frequencies — meaning the test subject changes mid-experiment, which contaminates any attempt at statistical-proof-level conclusions. The per-strategy 30-trade gate is therefore calibrated to directional signal, not statistical proof; continuation past the gate accumulates more data but does not convert directional signal into statistical proof for the reasons above.

What the experiment can deliver:

- Evidence of process discipline per strategy — whether each strategy executes consistently as designed
- Evidence of catastrophic failure modes per strategy — whether any strategy blows up in ways the design should have anticipated
- Evidence on regime router function — whether mechanical + adversarial router calls match realized regime behavior
- Calibration data on AI probability estimates and conviction ratings (directional only; statistical calibration requires larger samples)
- Infrastructure validation — whether the workflows, packets, pre-mortem templates, adversarial review structures, and review cadences function correctly
- Directional signal about strategy-type performance — whether specific strategy approaches produced positive or negative excess real returns, conditioned on the regime states they were active in

Success criteria below are calibrated to these achievable outputs, not to statistical proof.

### On the success threshold being hard to hit

The per-strategy success threshold (excess real return ≥ 0%, meaning deployed TWR beats SGOV after taxes and inflation) is a high bar — SGOV at current short-term Treasury yields is a materially positive benchmark, not zero. This is deliberate. The experiment's purpose is wealth-building; a strategy that deploys capital and fails to beat idle-in-SGOV is not contributing to that purpose.

Many autonomous-AI trading approaches do not achieve this. The threshold is set honestly rather than optimistically — a strategy that cannot meet it has not added value over doing nothing with the capital. Expect each strategy's threshold to be difficult to meet; that's the honest calibration.

---

## Architecture overview

The experiment runs N strategies in parallel, where N is defined by the strategy document. Each strategy has its own strategy portfolio. A regime router determines which strategies are active at any time.

**Minimum N.** The multi-strategy architecture applies when N ≥ 2. At N = 1, the multi-strategy machinery (regime router with independent per-strategy rules, cross-strategy capital redistribution, per-strategy gates) is unnecessary overhead — a simpler single-strategy experiment document would be more appropriate. N = 1 experiments are out of scope of this document.

**Maximum N.** Not specified. Larger N carries consequences the strategy document should address consciously: each strategy portfolio starts at 1/N of account total, so its available dollar base can become small enough that otherwise justified entries are fee-dominated or operationally impractical. Position size is not a fixed fraction of that base: each thesis requires its own no-ceiling seven-factor risk-budget justification and mandatory adversarial attack on size. The strategy document's choice of N should consider the participant's account scale, expected trade economics, and whether a strategy can deploy a defensible thesis budget at that scale.

**Strategy composition.** The identities, theses, instruments, entry/exit rules, and characteristics of the N strategies live in the strategy document, not here. Each strategy is selected because it exploits a distinct combination of AI edges and compensates for a distinct combination of AI disadvantages documented in `AI_Trading_Foundation.md`.

(rev 16, 2026-07-10 — Strategy Arsenal autonomy conversion.) The identity home is now Strategy.md + `strategy/roster.yaml` + `state.strategy_roster`, all routine-editable by SL1–SL5 and held one-to-one consistent by the `scripts/check_roster_consistency.py` CI gate. This file stays strategy-agnostic; the count N is now a dynamic roster attribute, bounded by the rails (floor N ≥ 2, ceiling N_max = 8) defined in the Strategy Arsenal Lifecycle below.

**The regime router** (details in "Regime router" section below):

- N independent activation rules, one per strategy.
- Each rule combines mechanical technical indicators (updated daily) with AI fundamental analysis (updated monthly).
- When technicals and fundamentals agree, the activation state updates mechanically.
- When they disagree, a two-routine adversarial review (Attacker routine + Orchestrator routine, BigQuery-keyed handoff per `Claude_Task_Plan.md`) adjudicates the activation state.
- The router determines which strategies are currently eligible to deploy new capital. Strategies not activated hold their strategy portfolios ~~in SGOV~~ **in the park [Rev 38, owner directive, 2026-07-15 — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13]** and do not open new positions. Existing open positions in a deactivated strategy run to their normal thesis-invalidation or exit conditions.

**Capital structure:**

- Starting capital is split equally across the N strategy portfolios. Each begins at 1/N of the account's total value.
- Each strategy's position sizes are computed against its own strategy portfolio value, not the account's total value.
- No rebalancing occurs between active strategy portfolios during the experiment. Performance drift between strategies is preserved.
- Deposits to the account are split equally among currently-active strategies (not yet terminated). See "Capital flows" below.

---

## Capital structure and accounting

### Starting capital

At experiment start, the account's total value is split equally across the N strategy portfolios. Each strategy portfolio begins at 1/N of account total. The split is tracked in an external ledger maintained by the participant; IBKR does not natively track sub-portfolios.

### Deposits

Deposits fund the system and are the lever that makes position sizes *meaningful* — redistribution only reallocates the existing pie; deposits grow it. A deposit is allocated in this fixed order:

1. **Fill pending newcomers first.** Any active strategy below its probe-stake floor (see "New strategy funding") is topped up toward the floor — oldest-pending first (FIFO), one filled to the floor before the next — until the deposit is exhausted.
2. **Allocate the remainder** among all currently-active strategies (including any newcomer just filled, and including regime-router-deactivated strategies — deactivation is temporary and the portfolio is still maintained) via the AI capital-allocation call (Operating_Protocols.md §16; owner-approved redesign 2026-07-19, `AI_DECISION_REDESIGN.md` §3 Redesign A) — bounded to [0.5×, 2×] each survivor's equal share, defaulting to the classic equal split below MEDIUM conviction. Terminated strategies receive nothing.

Example: a $1,000 deposit with no pending newcomers and M currently-active strategies defaults to $1,000/M to each, absent a MEDIUM+ conviction call directing a different (still-bounded) split. Because winners survive longer, they are present for more deposit events and accrete disproportionately over time (the same survivorship effect as redistribution). TWR is invariant to deposits — a deposit never flatters or repairs a strategy's measured return — so deposit-driven scaling does not contaminate per-strategy evaluation.

### New strategy funding (probe stake)

New strategies are not guaranteed a 1/N slice. A newly-added strategy starts **frozen** (defined but non-trading, zero booked allocation) and accumulates capital until it reaches its **probe-stake floor of $2,000** (an adjustable parameter chosen so a defensible no-ceiling thesis budget can clear IBKR's absolute ~$0.35 minimum commission without commission-dominated economics at the book's current operating scale). The floor is an absolute dollar amount because the binding constraint is absolute, not proportional; it prescribes neither a position fraction nor a fixed-dollar order. Every PROBE entry still requires its own seven-factor size justification and mandatory adversarial attack on size.

- **Funding priority.** While any newcomer is below $2,000, *all* incoming capital — from both deposits and strategy-sunset redistribution — feeds to pending newcomers first (oldest-pending first, FIFO, one filled to the floor before the next); only the remainder is subject to the AI capital-allocation call (Operating_Protocols.md §16), defaulting to the classic equal split among all active strategies below MEDIUM conviction. This is **not a one-time carve** — newcomers have first claim on every inflow until filled. **Implemented 2026-07-15 (self-improvement audit, CONFIRMED GAP `probe-stake-floor-prose-only`):** `state.strategy_probe_funding_gap` (`bigquery/62_probe_stake_funding.sql`) is the live, queryable FIFO status; `Operating_Protocols.md` §13.C's deposit-recording instruction and D2's termination-redistribution step both route capital against it. Previously this entire section was policy prose with no backing mechanism — a real newcomer would have received no priority funding and, independently, `analytics.strategy_nav` had no row for it at all until it later cleared the 30-trade gate (fixed the same session, `bigquery/22_cash_flows.sql`).
- **Launch.** A newcomer begins trading the moment its booked allocation reaches $2,000; below that it stays frozen and never trades at commission-dominated size. Enforced as an explicit pre-check in D2's entry-crafting step (`Claude_Task_Plan.md`) against `state.strategy_probe_funding_gap`, deliberately kept OUT of `analytics.fn_order_guard` (shared by every live strategy) so this has zero effect on current trading.
- **No proactive seeding.** A newcomer is not seeded from idle capital on demand — it waits, frozen, until deposits and/or sunsets bring it to the floor.
- **Multiple pending newcomers** fill in creation order; each must reach $2,000 before the next receives anything.

### Withdrawals

**DECIDED 2026-08-10 (owner directive).** A withdrawal is allocated **pro-rata to each strategy's NAV, clamped to the idle cash that strategy actually holds, with any unabsorbed share redistributed** across the strategies that still have room. It is materialized at write time as one `strategy`-tagged row per donor via `ops.sp_record_withdrawal` (`bigquery/161_withdrawal_after_the_fact.sql`; the full recording procedure is Operating_Protocols.md §13.C).

Why NAV is the basis: a withdrawal is a deduction against the *whole portfolio*, so each strategy should bear a share proportional to its size — not to the accident of how much of that size happens to be sitting in cash on the day the money leaves. Why the clamp: money can only physically come from where money physically is. A strategy that is fully deployed has nothing to give, and charging it anyway would either book a negative balance (a fiction with no self-heal) or imply force-closing its open positions to raise cash. A withdrawal must never silently close a trade. The clamp-and-redistribute shape is the same idiom §16 already uses for the capital-allocation call's band.

Both simpler rules were rejected on live data. **Equal-split by headcount** is only fair between equal-*sized* strategies, and against a $3,500 withdrawal on 2026-08-10 it put three of five negative. **Pro-rata to idle cash alone** never goes negative, but carries a timing distortion: it charges whichever strategy happens to be in cash that day and spares whichever happens to be deployed — the deployed one then exits and is left relatively larger for having been invested on the wrong day. NAV-basis-with-clamp removes that artifact while keeping the feasibility guarantee.

Capital-disabled strategies drop out of this with no flag check: the regime sweep has already taken their idle cash, so their cap is zero and they bear nothing. Eligibility is deliberately keyed on idle cash rather than on `capital_enabled`, because a roster where *every* strategy is DO-NOT-ACTIVATE is reachable (`bigquery/98`'s sweep `CROSS JOIN`s `enabled_set` and silently produces zero rows in that state), and a flag-keyed test would then refuse every withdrawal while the account's entire capital sat in those balances.

Three rails, all enforced by the procedure: a withdrawal larger than total donor capacity is **refused** rather than spilled into deployed strategies (choosing which position to liquidate is a portfolio judgment, not an accounting formula); a PROBE-phase newcomer still below its stake floor is **zero-weighted**, so a withdrawal cannot claw back capital the deposit-side newcomer-first-claim just protected; and the rows foot to the withdrawn amount **exactly to the cent**.

Withdrawals are **discovered after the fact, never declared in advance** (owner directive 2026-08-10) — there is deliberately no operator-declared earmark anywhere in the system. Because the broker connector exposes no funding ledger, a withdrawal is inferred by elimination, so recording is **two-pass**: a candidate is staged on the session that first observes the cash gone and committed on the next session that still observes it gone. That substitutes time for advance notice as the way to tell a real withdrawal from a settlement hold, a late-settling fill, or a fee accrual.

**Priority against regime-capital debt:** the withdrawal wins, and the impact is surfaced rather than gated (`state.withdrawal_capacity.restore_headroom_after_full_capacity`). The debt is an internal IOU to strategies that are not currently trading, not an external obligation, so it does not get to veto the owner's liquidity. Knowingly accepted consequence: a large enough cumulative withdrawal makes a later `bigquery/98` RESTORE partial, and the shortfall persists on the ledger.

### No inter-strategy rebalancing

Capital in one active strategy portfolio never moves to another active strategy portfolio. If one strategy outperforms another, the outperformer's strategy portfolio grows and the underperformer's shrinks, and this gap persists. This preserves each strategy's independent TWR evaluation — rebalancing would contaminate the diagnostic signal by coupling strategies that are meant to be evaluated independently.

The only time capital moves between strategies is after a strategy terminates, via the deterministic redistribution described below (winners accrete more by surviving longer; this is the intended scaling mechanism, not contamination to be avoided).

### Proportional sizing property

Position size is measured against the *strategy portfolio's* current value (not the account). The former asymptotic-loss property is **retired**: under rev 19 the AI-chosen per-thesis risk budget has no numeric ceiling, so it need not be a proper fraction of the strategy portfolio. A long thesis sized at the full strategy portfolio can reduce it to zero; a short gap can exceed stated CaR. The per-strategy drawdown kill trigger is therefore a detector that terminates a strategy **after** a loss, not a mechanism that prevents the portfolio from reaching zero. This is the accepted residual of the rev-19 sizing doctrine.

### Capital allocation model — 2026-06 revision (live-growth pivot)

The capital-allocation rules in this section were revised on 2026-06-01 to make the system a **live capital-growth engine**, not only a frozen forward-test. Two original provisions are superseded: (a) equal-split-among-all redistribution gated behind a capital-redistribution adversarial review with a default-hold → replaced by **deterministic redistribution to survivors** (no review, no held-aside pool); (b) the implicit "every parameter is immutable for the experiment's life" treatment of the *allocation* rules → the allocation policy is now an explicitly **versioned policy** that may be revised as the system matures.

What is *not* relaxed: the **evaluation machinery** — per-strategy 30-trade gates, kill triggers (drawdown, mark-to-market, runaway-success, foundation-change), and deployed-TWR-vs-SGOV measurement — all stand unchanged. ~~and **2%-per-trade risk sizing**… The system scales *capital* (the dollar base a strategy trades), never the *risk fraction* (2% per position).~~ **[Rev 19, 2026-08-05, owner directive: the fixed 2% risk fraction and both successor hard envelopes are retired. The risk fraction is an AI judgment per thesis with no numeric ceiling; only the recorded seven-factor justification and mandatory adversarial attack on size remain as sizing discipline. The evaluation machinery listed above is unchanged and detects failure after the fact rather than bounding position size.]** Winners scale by surviving longer and thus accreting more deposit/redistribution events; losers and edge-obsolete strategies terminate and hand their capital to survivors. Accepted trade: per-strategy TWRs are no longer perfectly independent (capital coupling via redistribution/deposits), so the "clean statistical experiment" framing is relaxed in favor of compounding real capital onto what works. See Decision_Log 2026-06-01 "Capital model pivot — deterministic survivorship accretion + new-strategy probe stake."

**2026-07-19 update (AI capital-allocation call, `AI_DECISION_REDESIGN.md` §3 Redesign A).** The *within-survivors split* of the remainder (after the pending-newcomer floor fill) is no longer a fixed equal share — it is a bounded AI judgment call, described in full at "Strategy termination and capital redistribution" below and Operating_Protocols.md §16. Nothing else in this revision's provisions changes: still no adversarial review, still no held-aside pool, still a versioned (not frozen) allocation policy — this is a further versioning of that same policy, not a reopening of (a) or (b) above.

---

## Strategy Arsenal Lifecycle (rev 16 — 2026-07 revision — autonomous roster policy)

*Owner directive, 2026-07-10:* strategy addition and deletion are **fully autonomous** — no human review, approval, or chat anywhere in the path. The only residual human touches are the system-wide IBKR order-confirm tap (an execution-layer action applied to every trade equally, including a newcomer's first orders and a terminated strategy's liquidation orders) and deposits. This section is the **canonical specification** of the machinery; `Strategy.md`, `Operating_Protocols.md`, `ops/autonomy_levels.yaml` (loop `strategy_arsenal` = `active_auto`), and `ops/RUNBOOK.md` point here. Recorded in Decision_Log 2026-07-10.

**Reframing.** The "experiment" is no longer "these N immutable strategies for N years"; it is "an immutable measurement-and-selection *machinery* that runs continuously and grows/shrinks a roster of independently-immutable strategy instances." Each strategy remains a clean before/after unit (spec frozen at SHADOW entry, edge clock from its first PROBE trade); the arsenal is a portfolio of such units. Roster membership is versioned policy (see "Immutability" above).

**Single source of truth.** `strategy/roster.yaml` (the roster analog of `ops/cadence.yaml`) is the checked-in single source: one entry per strategy {code, archetype, roster_state, edges_exploited, disadvantages_compensated, per_strategy_routine, adopted_date, spec_locked_since, immutable_since, retired_date, is_restart_of, revision_history} plus a top-level rails block. It is mirrored to an append-only `events.strategy_lifecycle` → `state.strategy_roster` (latest-row-per-code) → `state.active_strategy_codes` (the thin view the roster-derived SQL reads). `scripts/check_roster_consistency.py` is a CI build-gate asserting one-to-one agreement across roster.yaml ↔ state.strategy_roster ↔ Strategy.md `## Strategy` sections ↔ strategy/ slices ↔ Claude_Task_Plan.md slice-map rows, and that no bare strategy-code literal or fixed divisor remains in the roster-derived SQL. An inconsistent roster is a build failure and can never merge.

**State machine.** Every transition is fired by exactly one routine against exactly one objective readiness view, following the D2a self-execute pattern: check an objective BigQuery view → write a durable `ops.roster_change_log` idempotency row → write `events.decision_log` → for consequential transitions raise an `ops.alerts` row → never a chat question. **Severity (corrected 2026-08-04):** roster-MEMBERSHIP changes raise at **`warning`** under the ROSTER-CHANGE NOTICE contract (`Claude_Task_Plan.md` preamble), because `info` is filtered out by both `alert_emailer.gs` and `scripts/alert_relay.py` and therefore reaches the operator through no channel at all; every other consequential transition stays `info`. `warning` cannot halt trading — the gates count `critical` only. No state advances on judgment or on a human answer.

- **CANDIDATE** — a structured intake record {code, thesis with each rule cited to a foundation edge/disadvantage, instruments, sizing methodology, kill-criteria structure, target regime cells, declared frequency, is_restart_of}. Emitted by the scouting routines (D1 capability captures, Q1 router-fitness flags, Q3 foundation-delta outputs, A1 re-derivation) writing candidate rows instead of dead-ending at a human recommendation, plus SL1's quarterly synthesis biased toward under-covered regime cells. Zero capital.
- **QUALIFYING** — SL1 mechanical qualification, **default-REJECT on ambiguity**: every rule cites a valid live foundation edge/disadvantage; material-structural-difference vs every live AND terminated strategy (differ in ≥1 of {approach, instrument scope, sizing methodology, router structure, kill-criteria structure} beyond threshold numbers — for a restart, checked against its own post-mortem); non-redundancy vs the current roster; capacity/cost fit at the $2,000 probe floor; roster below N_max; cooldown clear. Pass → AUTHORING when the incubation cap and the adoption-rate window are open (else waits FIFO); fail → REJECTED + cooldown stamp.
- **AUTHORING** — SL2 (independent context from SL1 and the reviewers) drafts the full `## Strategy <code> [CANDIDATE]` section + a self-contained 7-section pre-mortem, derives ALL parameters FRESH with a provenance record (for the anti-inheritance check), and enqueues a `strategy-adoption` review (conservative_default = REJECT).
- **UNDER_REVIEW** — the existing two-routine cycle: AR_att (strict-blinded attacker) → AR_orc (orchestrator). AR_orc assigns tiers **mechanically** by the rev-15 working definitions (absorbing the former human triage; triage is deliberately not itself adversarially reviewed, to avoid infinite regress), answers the forcing question, and applies the deployment-risk four-screen stop + the cycle-5 soft cap. REVISION REQUIRED enqueues an **SL2 auto-revision** task (redraft Tier-1 defects fresh, cycle_number++, re-enqueue); DEPLOYMENT-RISK-UNACCEPTABLE at the soft cap → REJECTED + cooldown; SUFFICIENT → adoption readiness clears.
- **SHADOW** (signals only, zero capital, no orders) — SL5 inserts the roster row and **the strategy's machinery LOCKS here** (`spec_locked_since`); the forward-test now measures a fixed ruleset. SL3 computes signals against fresh live marks, measuring signal rate vs declared frequency, scaffolding correctness, and would-be-trade regime cells. → PAPER when `state.strategy_shadow_readiness` clears (≥ 20 shadow trading days AND signal rate within the declared, archetype-scaled band [≥1, ≤ the `bigquery/52_shadow_readiness_band.sql` ceiling] AND zero scaffolding faults); → REJECTED on `state.strategy_shadow_readiness.stuck` (self-improvement audit 2026-07-15, `bigquery/60_shadow_stuck_cull.sql`: ≥400 shadow days with the signal-rate-or-scaffolding condition still unmet — the numeric definition of "window-exceeded," mirroring PAPER's own 400-day `stuck` constant below) or a catastrophic scaffolding break.
- **PAPER** (full forward-test; simulated fills at live marks with modeled IBKR commissions + conservative slippage vs SGOV, tracked in `analytics.strategy_incubation_perf`) — → PROBE-ready when `state.strategy_paper_readiness` clears (≥ ~60 paper trading days AND ≥ ~10 simulated closed trades AND paper excess-vs-SGOV ≥ 0 over the window AND regime coverage: positive excess in ≥2 regime cells OR fills a zero-coverage arsenal cell AND adoption-rate window open AND roster below N_max); → REJECTED on materially-negative paper excess or a paper drawdown-kill-equivalent → cooldown.
- **PROBE** (live newcomer) — on readiness SL3 enqueues SL5, which SELF-EXECUTES the registration (D2a): finalize the Strategy.md section (candidate namespace → roster-active), run `scripts/split_strategy.py`, flip the roster.yaml state, run the roster fanout + `check_roster_consistency.py` + `check_cadence_consistency.py` + `split_strategy --check` locally, commit+push (auto-merge on green CI), re-apply the roster-derived views live via the BigQuery MCP in apply order, and register the newcomer into the **existing** probe-stake funding queue. It launches at the unchanged **$2,000 probe-stake floor**, sized at its per-thesis risk budget (**rev 18, 2026-07-28 — the flat 2% is retired; the $2,000 floor itself is unchanged**) (see "New strategy funding (probe stake)"); a PROBE launch additionally defers under an `ops.trading_control` account halt (incubation continues, capital does not deploy). **`immutable_since` is stamped at its first PROBE trade** — the official clean-measurement inception. → ADOPTED on the existing 30-trade gate (cumulative excess real return ≥ 0); → TERMINATED on gate FAIL or any mechanical kill.
- **ADOPTED** — full member, runs indefinitely. Subject to ALL existing mechanical kill triggers **unchanged** (drawdown immediate; runaway-success / foundation-change / mark-to-market via the existing autonomous two-routine reviews) PLUS eligibility for SL4 discretionary retirement.
- **RETIREMENT_PROPOSED** — SL4 (monthly, remove-only) detects an objective sustained signal (edge-decay, redundancy, or dominated-by-newcomer) and enqueues a `strategy-retirement` review (conservative_default = **KEEP**; affirmative RETIRE required). RETIRE → TERMINATED (routes to the existing deterministic-redistribution handler); KEEP → ADOPTED + re-proposal cooldown. Never below the N ≥ 2 floor.
- **TERMINATED** — reached via any mechanical kill (immediate, no review — unchanged) or an SL4 RETIRE. The existing termination handler closes positions (liquidation orders route through the operator confirm-tap = execution layer only), redistributes deterministically to survivors, writes a TERMINATED lifecycle row, and enqueues an SL2 post-mortem; SL5 deregisters the roster row and sets the edge cooldown.
- **POST_MORTEM** — SL2 authors `events.strategy_postmortems` {what_revealed, what_unresolved, material_diff_required_for_restart}. Terminal, but becomes an SL1 restart input.
- **REJECTED / RESTART_CANDIDATE** — a rejected candidate or a shadow/paper cull carries a `cooldown_until` stamp. A terminated edge re-enters ONLY as a fresh CANDIDATE via SL1, which mechanically enforces the restart constraints (see "After termination: restart and new-experiment constraints" below).

**Graduation** = "survived multiple independent scrutiny, forward-tested, ready for any regime" = adversarial pre-mortem SUFFICIENT (layer 1) + SHADOW signals (2) + PAPER forward-test economics (3) + live PROBE (4) + the 30-trade gate (5), while contributing to `state.arsenal_regime_coverage` — the regime-cell coverage matrix (SPY trend × VIX regime, yield-curve overlay) that operationalizes "ready to deploy into any regime." SL1 biases candidate synthesis toward zero-coverage cells (target k_regime = 3) and SL3 gates paper graduation on demonstrated coverage.

**The five lifecycle routines (defined in `Claude_Task_Plan.md`; each gated by `ops.sp_assert_arsenal_enabled` at entry).**
- **SL1 — Candidate Synthesis & Qualification** (quarterly, after Q1/Q3): synthesizes and mechanically qualifies candidates, default-REJECT.
- **SL2 — Draft, Revise & Post-mortem** (queue-driven): authors candidate sections + pre-mortems, performs AR-ordered auto-revisions (overturning the former "participant revises" carve-out), and writes post-mortems. Independent context; never touches capital or the live roster.
- **SL3 — Incubation Monitor & Graduation** (daily, after D2a): runs the SHADOW/PAPER forward-tests, self-executes the light SHADOW→PAPER transition, and enqueues SL5 for the PROBE registration.
- **SL4 — Discretionary Retirement Proposer** (monthly, after M4): remove-only, default-KEEP, can only move in the fail-safe direction and never below the N ≥ 2 floor.
- **SL5 — Strategy Register & Roster Sync** (queue-driven): the sole writer of roster membership; self-executes the repo/SQL fanout (D2a self-bootstrapping order — land repo+SQL first, create any per-strategy web-UI trigger last; reverse on delete) with `ops.roster_change_log` idempotency.

**Safety rails (no human in the loop).** Owner kill-switch `ops.arsenal_control` (enabled / incubation_frozen) freezes candidate generation / graduation / retirement with a single out-of-band INSERT, without disturbing live trading; default-no / default-KEEP / default-HOLD biases at every gate; concurrent-incubation cap **k_incubate = 2** (SHADOW+PAPER combined); adoption rate limit **one PROBE launch per rolling ~90 days / calendar quarter**; roster **floor N ≥ 2** (a hit force-generates candidates + an info `roster_below_floor` alert — the successor-experiment safety valve) and **ceiling N_max = 8** (cost discipline for a ~$10k account); staged forward-test (no live capital before pre-mortem SUFFICIENT → SHADOW → PAPER); bounded capital at risk (newcomers launch only at the $2,000 floor and remain subject to the unchanged mechanical kills); remove-only discretionary retirement; post-rejection / post-termination / post-KEEP cooldowns (the anti-churn machine rate-limit that substitutes for human cooling-off and blocks dead-strategy laundering via the material-structural-difference test); `ops.roster_change_log` + a NOT-EXISTS-later-state guard in every readiness view for idempotency; scrutineer independence (SL1 generates, SL2 authors, AR_att/AR_orc review, SL3 judges graduation, SL5 executes — separate fresh-context routines); full dead-man monitoring plus a meta-heartbeat (each scheduled SL routine writes an "evaluated, no change" decision_log entry every firing); and the `check_roster_consistency.py` CI gate. Every transition writes `events.strategy_lifecycle` + `events.decision_log` + (consequential ones) an info `ops.alerts` row on the monitored alerting surface.

**New review types (reuse the existing two-routine AR pair; added to the closed review-type enumeration).** `strategy-adoption` (conservative_default = REJECT), `strategy-retirement` (conservative_default = KEEP), and `out-of-table-resolution` (conservative_default = HOLD-current-state; used by the foundation-change / constraint-relaxation exception path in the Kill-criteria section, replacing the former participant handoff — no attack needed, apply the default unless objective criteria clearly resolve).

---

## Constraints on strategy design

Each strategy derived from `AI_Trading_Foundation.md` must:

- Exploit edges that actually exist in the current model generation, not aspirational ones.
- Compensate for the disadvantages documented in `AI_Trading_Foundation.md`.
- Not maximize return potential at the cost of capital preservation. AI disadvantage 2.18 (instruction adherence over capital preservation) means aggressive edge-maximization produces tail-risk failures. The correct framing is "best use of real edges with hard capital preservation constraints."
- Declare its expected trade frequency (trades per year, measured over *active periods only* — periods when the regime router has the strategy activated). This declaration is not load-bearing on a kill trigger, but remains required for three reasons: (a) sanity-checking strategy viability; (b) diagnostic signal — if realized frequency over active periods differs materially from declared, the strategy has a process problem that should be reviewed at monthly cadence even though it does not auto-terminate; (c) calibrating participant expectations about time-to-gate.

Each strategy is derived from `AI_Trading_Foundation.md` without reference to this document. Per-trade decisions do not consider the kill criteria or success thresholds — those operate at the strategy portfolio level over the full test period.

---

## Regime router

The router determines, for each strategy, whether that strategy is currently activated (eligible to deploy new capital) or deactivated (~~capital held in SGOV~~ **capital held in the park [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13**, no new entries, existing positions run to normal exits).

The activation rules are independent, one per strategy. Activations and deactivations are computed per-strategy based on that strategy's own best-environment criteria. There is no combinatorial logic across strategies — if all strategies' criteria are met simultaneously, all are active; if none are met, none are active. Both extremes are valid states.

### Two-signal cross-check

Each activation rule combines two signals:

- **Mechanical technical indicators.** Computed from price, volume, and volatility data. Updated daily. Specific indicator set is specified in the strategy document, not here, and is immutable once trading begins. Properties the indicator set must satisfy: every indicator is computed from objective data (no AI classification in the computation), the activation threshold for each strategy is specified as a concrete numerical rule, and the indicators collectively produce a binary activate/do-not-activate output per strategy.
- **AI fundamental analysis.** Produced monthly by a structured Claude session against a fixed template of inputs (macro data, policy environment, earnings aggregate trends, geopolitical risk factors, sector-specific factors relevant to the strategies in use). The template is specified in the strategy document and is immutable once trading begins. The output is a binary activate/do-not-activate call per strategy, with explicit reasoning.

The two-signal structure exists to compensate for `AI_Trading_Foundation.md` 2.7 (AI regime misclassification) without hard-coding permanent distrust of AI fundamental analysis. Technical indicators lag but are unbiased mechanically. AI fundamentals can see structural shifts technicals miss but carry documented biases (2.4, 2.13, 2.14, 2.24). Using both as cross-check exploits the complementary failure modes.

### Resolution on agreement

When technicals and fundamentals agree on activation state for a given strategy, the router's activation state for that strategy matches the agreement. No review required.

### Resolution on disagreement (two-routine adversarial review)

When technicals and fundamentals disagree on activation state for a given strategy, the router cannot update that strategy's activation state until a two-routine adversarial review (Attacker routine + Orchestrator routine per `Claude_Task_Plan.md`, queue-driven through `events.queue_events` / `state.open_queue`) adjudicates. During the review, the strategy retains its prior activation state.

**Input — Fundamental analysis (already produced).** The monthly fundamental analysis output (M1b) that created the disagreement. This is the input to the review, not a separately-commissioned routine. The triggering routine (typically M4, or D2 if a daily technical flip creates the divergence) writes the queue entry referencing the M1b output file and current technical reading.

**Attacker routine.** Fresh routine context. Given via the queue entry: (a) the fundamental claim (M1b output file path), (b) the current technical indicator readings, (c) instruction to produce the strongest bear case against the fundamental claim, treating disagreement with technicals as potentially signaling an error in the fundamental reasoning. The attacker is not told which direction the disagreement runs — it is asked to attack the fundamental claim on its merits. Attacker prompt explicitly forbids reading other repo files (Decision_Log.md, prior reviews, broader Strategy.md sections) — accepted-risk note: this is prompt-discipline blinding rather than the structural blinding incognito sessions provided. Attacker routine has no chat history and no access to the orchestrator routine's reasoning (orchestrator hasn't run yet). Output: full attack with specific weaknesses identified, plus the attacker's verdict on whether the fundamental claim should survive, stored as its `events.adversarial_reviews` attacker row.

**Orchestrator routine.** Fresh routine context. Reads the exact current attacker row from `state.adversarial_reviews_current` by `(review_id, cycle_number, role='attacker')` and the M1b output file. Produces an explicit independent assessment that documents: (a) the validity of each weakness the attacker identified, (b) any theater in the attacker's output (generic-sounding objections without specific anchors), (c) any weaknesses the attacker missed, and (d) a final verdict — final activation state for the strategy (activate or do-not-activate), reasoning, and theater-check flag (explicit judgment on whether the orchestrator's review identified substantive issues or merely ratified the attacker without meaningful independence). The theater-check is self-certified by the orchestrator routine; this is a known reduction in rigor relative to a separate-routine theater auditor pattern, accepted as part of migration scope.

**Default on ambiguity.** If the orchestrator's final verdict is ambiguous or non-committal, the default is do-not-activate. An affirmative activate decision is required for activation to occur.

**Logging.** The M1b output, the attacker output, and the orchestrator's assessment are all recorded as part of the router's decision log. The log is reviewed at monthly cadence alongside other monthly-review items.

**Why this architecture (history).** The original design used a three-session architecture (attacker + judge + adjudicator-on-disagreement) to apply `AI_Trading_Foundation.md` 2.24 (cross-session inconsistency) as a deliberate edge: context-isolated sessions produce genuinely different reasoning. That design was simplified to single-session attacker + in-conversation orchestrator review (rev 3 simplification) on operational-sustainability grounds — the manual incognito-tab + paste-back workflow was operationally too costly to sustain across many reviews. The routine architecture migration translates this into the two-routine pattern: routine boundary serves as session boundary, and the exact-key BigQuery transcript handoff replaces paste-back. Operational cost approaches zero (routines fire automatically), but the structural blinding-by-no-project-access of incognito sessions is replaced with prompt-discipline blinding under the two-routine pattern. The original three-session-with-separate-judge rigor is not restored as part of migration scope; it can be added in a future revision (third routine: Theater Auditor) if accumulated theater-check flags suggest self-certification is producing under-detection of CONVERGENT framing.

**Residual limitation (acknowledged).** All routines run on the same underlying model weights. Hard-wired biases (optimism, recency, base-rate neglect) can cut across routine boundaries regardless of context isolation. The theater-check flag in the orchestrator's review is the check against weight-level bias; if reviews consistently converge on similar framing, the monthly review should flag this as drift indicating the adversarial structure is not producing meaningful independence. Accepted as a sustainability trade plus migration-scope simplification.

### Cadence

- Technical indicators: updated daily (mechanical, cheap).
- Fundamental analysis: produced monthly.
- Activation state changes: can occur at any time a new signal would cross the activation threshold. A daily technical flip against a stable monthly fundamental triggers a review that day (or at the participant's next daily check, with at most 24-hour lag). The monthly fundamental analysis can itself trigger a review if it flips against stable technicals.
- Adversarial reviews: triggered only when disagreement would change activation status. Agreement cases require no review.

### Router pre-mortem

The regime router is itself a component subject to pre-mortem with adversarial review before the experiment's first trade. See "Pre-mortems" section below.

---

## Experiment parameters

### Position size — THESIS-SCALED RISK BUDGETING (rev 18, 2026-07-28, owner directive)

**There is no blanket per-position size rule, and ~~within hard envelopes~~ [rev 19, owner directive 2026-08-05] no hard envelope either. The AI chooses each thesis's size, expressed as a risk budget, with COMPLETE freedom — no numeric ceiling at the position level or the strategy level.**

*(This supersedes the fixed "2% of current strategy portfolio value per trade" rule that stood from rev 1 through rev 17. The change is FUNDAMENTAL — it alters position-sizing methodology, one of the five material-structural-difference dimensions — and is applied by explicit owner directive, the unbounded override channel; it is **not** an `AI_Trading_Foundation.md` §5.6a non-fundamental in-life edit and must not be cited as precedent for one.)*

**Why the fixed 2% rule was retired.** Two reasons, in order of force:

1. **It had already stopped being a risk cap.** Rev 40 (2026-07-21, owner directive) authorised adding to an existing position as ~~"a fresh 2%-of-strategy-NAV tranche… no cumulative cap on the number of tranches a single name may accumulate"~~ **[historical rule, retired by rev 18/19]**. From that date the rule bounded *tranche granularity*, not per-name risk: a name could accumulate unbounded 2% tranches. The derivation the rule rested on — "a 10-trade consecutive losing streak costs approximately 18%" — silently assumed independent 2% bets and no longer held. The document was asserting a discipline the mechanism no longer delivered. Retiring it replaces a fiction with an explicit control.
2. **A blanket number is the wrong instrument when sizing IS the risk control.** This experiment deliberately uses no price-based stop-losses (see *Risk management via sizing* below): a position runs to thesis completion or thesis invalidation. Because there is no stop, **the size decision is the risk decision** — it is the only lever that bounds the loss when a thesis is wrong. A single fixed number applies the same risk to a tightly-falsifiable 3-week catalyst and a diffuse 3-year structural thesis, which are not the same risk. Owner directive 2026-07-28: the AI sizes each thesis to its own risk, with no blanket rule.

**Definitions.**

- **Capital at Risk (CaR)** — the loss incurred if the thesis is wrong, measured at entry:
  - *Long equity:* the full position notional. With no stop-loss, the honest worst case is total loss; CaR is therefore not discounted by any assumed exit level.
  - *Defined-risk options (Strategy C):* `max_loss`, inclusive of the bounded early-assignment cascade, as computed by `c_options_math.py` — the operative figure is `total_max_loss = max(closed_form, cascade)`. **[Rev 44, 2026-08-10 — scope correction per AR_orc `premortem-C-2026-a3` cycle 11]** The base component is dual-path-verified and is exact, not an assumption. The cascade component is single-path (regression-tested, no independent second implementation) and IS assumption-dependent — it rests on the 2× implied-move adverse-move scaling of Known Limitation 9. Where the cascade term binds, treat CaR as exact for its non-cascade component only.
  - *Short equity:* notional × the strategy's short stop distance (see *Short positions* below). Shorts are the one place a stop is mandatory, because without it CaR is unbounded and the phrase "risk is capped by sizing" would be false.
  - *Pairs (Strategy E):* the sum of both legs' CaR, sized to the hedge ratio.
- **Risk budget** — the CaR the AI assigns to a thesis, expressed as a percentage of that strategy's portfolio value (park holdings + open positions at market) at the moment of initiation. Not a percentage of the account; not of the sum of all strategy portfolios.

**The sizing decision (required at every entry and every add).** The AI states the risk budget and justifies it against this fixed factor list. The justification is recorded in the thesis's `events.decision_log` entry; a size with no recorded justification is not a valid order.

1. **Falsifiability of the invalidation criteria.** Tight, observable, near-dated invalidation means the position is exited early when wrong — supports a larger budget. Diffuse or slow-to-observe invalidation supports a smaller one.
2. **Time to resolution.** Longer horizons accumulate unknown-unknowns and carry more foundation-change and regime risk — supports a smaller budget.
3. **Instrument loss profile.** Defined-risk (exact CaR) supports a larger budget than open-ended equity downside at equal conviction.
4. **Correlation with the existing book.** A thesis that duplicates exposure already held (same name, sector, theme, or correlation bucket) supports a smaller budget — concurrent correlated positions are not independent bets.
5. **Regime fragility.** Sizing is smaller where the router's activation is marginal, or where the thesis depends on a regime the foundation flags as adverse.
6. **Liquidity and exit-ability** at the intended size.
7. **Conviction — ordinal only.** Per `AI_Trading_Foundation.md` 3a.1 and 2.26, conviction enters as an ordinal tier, **never as an explicit probability multiplied into a sizing formula.** Raw model probabilities are not calibrated (2.13: 80% CIs hit ~69%; ECE measured flat this cycle) and must not be used as sizing arithmetic.

**Mandatory adversarial attack on the size (compensating control).** Every strategy's existing adversarial counter-argument entry criterion is extended: the counter-argument must attack **the size as well as the direction** — it must state what the position would cost if the thesis is wrong, and argue whether that loss is acceptable. This is the structural compensation for handing sizing to judgment subject to 2.13 (miscalibration), 2.18 (instruction adherence over capital preservation) and 2.26 (RL-induced overconfidence), all three of which A2 2026 confirmed are **not** reduced — 2.13 flat, 2.18 strengthened. A size that survives no adversarial attack is not sized, it is asserted.

**~~Hard envelopes (versioned policy — the ruin-prevention backstop)~~ NO SIZING CEILING — BOTH CaR ENVELOPES RETIRED (rev 19, owner directive 2026-08-05).** ~~These are not conviction constraints; they are set wide enough that ordinary judgment never touches them, and exist so that a single miscalibrated session cannot destroy a strategy~~ **— and that self-description is precisely why they were retired. A ceiling that "ordinary judgment never touches" does no risk work in the ordinary case, while in the rare case where judgment genuinely wants to concentrate, it overrides the judgment this experiment exists to test. Owner directive: there are no stop-losses here, so SIZE IS THE RISK-MANAGEMENT LEVER, and the AI is trusted to set it. There is now no numeric ceiling on position size at any level.**

| ~~Envelope~~ Retired / retained | ~~Limit~~ Status | Note |
|---|---|---|
| ~~**Per-name aggregate CaR** (all tranches, one strategy)~~ | ~~≤ 10% of that strategy's portfolio value~~ **RETIRED 2026-08-05** | No per-name ceiling. A single thesis may be sized to any fraction of its strategy's portfolio the AI can justify. Code enforcement removed from `strategy_math/common.py` and `c_options_math.py` the same day. |
| ~~**Per-strategy total deployed CaR**~~ | ~~≤ 75% of that strategy's portfolio value~~ **RETIRED 2026-08-05** | No deployment ceiling. A strategy may be fully committed. Consequence accepted deliberately: "deployed TWR measured on deployed capital" stays well-defined, but the automatic parking buffer/dry-powder reservation is gone — holding back capital for a better thesis is now a judgment call per thesis, not a rail. |
| **Book-level NAV drawdown circuit-breaker** | **RETAINED, unchanged** (`breach_soft` −15% entries-only pause, `breach_hard` −40% full halt) | Not a sizing cap — an account-level circuit breaker. Untouched. |
| **Strategy C defined-risk rail** | **RETAINED, unchanged** | `max_loss` (incl. early-assignment cascade — i.e. `max(closed_form, cascade)`) must be ≤ the thesis's stated risk budget. The base component is dual-path verified; the cascade component is single-path (Rev 44, 2026-08-10 scope correction). This bounds a structure against **its own declared budget**; it is not a ceiling on what that budget may be. The options order-guard rail still enforces it, and must receive the combined figure. |
| **Per-GICS-sector exposure cap (Strategy D, 30% of NAV)** | **RETAINED, unchanged** | A concentration bound across names, not a position-sizing cap. Untouched. |

~~The envelope *values* are **versioned policy** — tunable by owner directive or by A2 without terminating any strategy, mirroring the 2026-06 capital-allocation carve-out. The *existence* of an envelope is not optional.~~ **[rev 19, owner directive 2026-08-05 — SUPERSEDED, and note this clause is what the directive had to override: the prior revision made envelope VALUES tunable while declaring their EXISTENCE mandatory. The owner-directive channel is unbounded (see the Rev 35 / rev 17 precedent) and was exercised deliberately here, with the trade-off stated: retiring the per-name envelope means the −50% deployed-TWR drawdown kill becomes the only quantitative backstop, and it is a DETECTOR that fires after a loss is realised, not a bound that caps it. That is accepted. A2 may not reintroduce an envelope on its own initiative — doing so would re-impose a constraint the owner removed; it takes another owner directive.]**

**What survives, and is now the whole of the sizing discipline — procedural, not numeric.** (1) the seven-factor justification recorded in the thesis's decision-log entry; (2) the **mandatory adversarial attack on the size**, above — a size that survives no adversarial attack is not sized, it is asserted; (3) the per-strategy kill triggers and the 30-trade gates, all unchanged. Nothing about this directive relaxes the *evaluation* machinery.

*Short positions.* Shorts keep a mandatory stop, and this is a deliberate exception to the no-stops posture rather than an oversight. Long downside is bounded at −100% of notional, so sizing alone caps it. **Short downside is unbounded, so sizing alone caps nothing** — the stop is what makes CaR finite and therefore what makes "risk is capped by sizing" a true statement for a short. Strategy B's existing short stop (close if the underlying rises ≥ 25% from short-entry) is retained unchanged and now serves explicitly as the CaR-defining bound.

*Paired positions.* A pair is sized as one thesis: the AI sets the pair's total risk budget, and the legs are sized to the hedge ratio rather than each taking an independent budget. This replaces the old "2% per leg, therefore 4% per pair" arithmetic.

*Context on account scale and fee-domination.* Positions below roughly $100–200 are fee-dominated for equities and worse for options at IBKR retail commissions. Thesis-scaled sizing *improves* this relative to the flat rule — a high-conviction thesis can now clear the fee-dominated floor that a fixed 2% of a small strategy portfolio could not — but it does not eliminate it, and a small budget on a small portfolio is still fee-dominated. Unchanged: this is an accepted cost of multi-strategy breadth, strategies are not terminated for fee-dominated underperformance alone, and the $2,000 probe-stake floor still governs newcomer funding.

*Risk management via sizing, not via stop-losses (retained, and now load-bearing).* Positions run to their thesis conclusion — completion, invalidation, or an explicit time/structural exit — not to a price-based stop. Stops fire only on thesis invalidation (the catalyst did not materialise, the event did not happen, the structural condition changed), never on price action alone; the sole exception is the short-side CaR bound above. The rationale is diagnostic integrity: letting theses play out generates clean signal on whether the strategy's theses are correct, whereas tight price stops convert strategy-edge questions into execution-timing questions. This clause is *why* sizing carries the whole risk load, and is therefore the reason the sizing decision must be justified and adversarially attacked rather than left to unexamined judgment.

**Measurement consequence — per-trade metrics must normalise by CaR.** With variable sizing, raw per-trade P&L is no longer comparable across trades. Every edge-decay and gate metric expressed per trade is now **per unit of capital at risk**: EV per trade = (hit rate × average win **per unit CaR**) − ((1 − hit rate) × average loss **per unit CaR**). Count-based metrics (hit rate, convergence rate, invalidation counts) are unaffected. Deployed TWR is unaffected (it is time-weighted on capital, not per-trade). Strategy C's pre-mortem already defines EV per unit of capital at risk and needs no change.

**Calibration upside — an argument for this change, not merely a cost.** Under the flat 2% rule, 2.13/2.26 overconfidence was both unmitigated *and* unmeasurable in the sizing dimension: every trade was the same size regardless of conviction, so realised outcomes carried no information about whether the model's confidence was worth anything. Under thesis-scaled sizing with ordinal conviction recorded per entry, size-vs-outcome becomes a directly measurable calibration series that `analytics.calibration_summary` and W5 can consume. If the AI's larger-budget theses do not out-hit its smaller-budget theses, that is now visible, falsifiable, and actionable. The change converts an invisible bias into a monitored one.

### Kill criteria (per-strategy)

A strategy terminates immediately — all its open positions closed at next available daily review, no new entries in that strategy, strategy portfolio moves to ~~fully in SGOV~~ **fully into the park [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13** pending deterministic redistribution to survivors — if any one of the following fires for that strategy:

**1. Drawdown trigger.** Deployed TWR drops 50% below its highest historical value since the strategy's first trade.

*Derivation.* Calibrated to a reference strategy with Sharpe ~0.5 and 15% annualized volatility — this is an assumption, and an important one. For a reference strategy of these characteristics: 43% probability of -30% drawdown over 10 years (1.5-sigma), 10% probability of -45% (3-sigma), 1.5% probability of -60% (4-sigma). A 50% drawdown is approximately 2.5-sigma — beyond normal variance for the reference but not so deep that only catastrophic failures trigger it. If a given strategy has meaningfully worse Sharpe (plausible given cataloged AI disadvantages), a 50% drawdown is closer to normal variance, and the trigger is more likely to fire on unlucky-but-working runs. This is an accepted cost: we cannot calibrate to each strategy individually because the strategies aren't written yet. The Sharpe 0.5 reference is a defensible middle; the trigger is honestly aggressive against weaker strategies.

*Measurement.* Drawdown is peak-to-trough deployed TWR for the specific strategy. Capital flows in or out of the account do not affect this calculation. A deposit after a drawdown does not recover the drawdown; only positive strategy returns do. SGOV parking periods are not included in the TWR measurement — the drawdown trigger operates on deployed TWR only.

The trigger is rigid and context-independent. No intermediate context-aware review. The documented AI disadvantages (narrative over-fit, optimism bias, instruction adherence over capital preservation) make AI-driven "should we continue" assessments most unreliable precisely when they would be invoked — under loss pressure. Rigid thresholds accept higher false-positive cost in exchange for eliminating AI-judgment failure in the highest-risk moment.

**2. Foundation change trigger (per-strategy assessment).** The quarterly review of `AI_Trading_Foundation.md` (Q3 task in `Claude_Task_Plan.md`) or the annual full re-derivation (A1 task) identifies a change that affects the foundation a specific strategy was built on. Prior to 2026-04-25 (rev 3 of the foundation document) this was a monthly review; the cadence change reflects the new quarterly delta + annual sweep architecture.

Foundation changes do not automatically kill all strategies. When a foundation change is identified, each strategy is assessed independently against the change. The assessment produces one of three outcomes per strategy (rev 3 added the constraint-relaxation branch):

**Outcome (a) — Continue.** The change does not materially affect this strategy's foundation. The strategy continues without modification.

**Outcome (b) — Terminate.** The change materially weakens this strategy's foundation. Specifically: a documented edge in Part 1 was removed or materially reduced AND the strategy exploits that edge, OR a documented disadvantage in Part 2 was added or materially increased AND the strategy has not adequately compensated for it. Strategy terminates per the standard termination path (immediate close, ~~SGOV~~ **park [Rev 38, owner directive, 2026-07-15]**, deterministic redistribution to survivors).

**Outcome (c) — Constraint-relaxation review (rev 3 added, rev 4 mechanized).** The change is a *reduction* in a disadvantage that the strategy explicitly compensates for, AND the strategy has constraints (entry rules, sizing caps, eligibility restrictions, etc.) that were added to address that disadvantage. The orchestrator session executes a constraint-relaxation review by applying mechanical criteria from `AI_Trading_Foundation.md` Part 5 — no orchestrator discretion. The verdict is determined by the criteria; the orchestrator's role is to execute the criteria and produce the audit-trailed output, not to exercise judgment.

*Mechanical procedure (per `AI_Trading_Foundation.md` §5.3):* (1) parse strategy mechanism + pre-mortem for foundation citations including the rev N annotations linking constraints to specific Tier 2 disadvantages; (2) classify reduction magnitude per §5.4 thresholds (NONE / PARTIAL / MATERIAL) using direct research evidence and benchmark inference per §5.5; (3) apply §5.6 mechanical relaxation lookup based on reduction magnitude and constraint type; (4) apply load-bearing test mechanically — if the constraint is named as mitigation for any other still-in-force disadvantage in the pre-mortem's Section 5 mitigation citations, no relaxation regardless of magnitude on the cited disadvantage; (5) output structured audit trail per §5.7 listing relaxed constraints (with new form), unrelaxed constraints (with mechanical reason), and any out-of-table flags — which (rev 16, 2026-07-10) are routed to an autonomous `out-of-table-resolution` adversarial review (conservative_default = HOLD-current-state), not to participant resolution.

*Why mechanical, not judgment-based.* The asymmetric default mirrors the termination-side default but inverted: tie goes to NO relaxation (preserve the constraint) when evidence is insufficient. But "tie goes to" was previously a judgment call by the orchestrator session. Rev 4 mechanizes the criteria so the orchestrator applies explicit thresholds rather than exercising discretion: PARTIAL/MATERIAL reduction magnitudes are quantified per §5.4; benchmark inference is bounded by Goodhart guardrails per §5.5 (≥3 sources, transferability, sustained, domain coverage); relaxation forms are looked up per §5.6 based on constraint type. Constraints that don't fit the lookup table generate an out-of-table flag rather than orchestrator-discretion fill-in — the strategy is held in current state (the conservative default is preserved) and the gap is resolved autonomously by an `out-of-table-resolution` adversarial review (conservative_default = HOLD-current-state), not deferred to a human at the next annual cycle (rev 16, 2026-07-10). The flag is logged in Decision_Log.md; if the review does not affirmatively resolve it, HOLD persists and the item is re-surfaced each A1/A2 cycle — no silent drop, no unsafe auto-relaxation. This eliminates the "AI judgment under capability-improvement pressure" failure mode, parallel to how the drawdown trigger eliminates "AI judgment under loss pressure."

*Benchmark inference (rev 4 added per `AI_Trading_Foundation.md` §5.5).* Tier 2 disadvantages can be inferred as reduced from benchmark-result improvements without requiring an explicit "deficiency X is cured" research paper. The benchmark-to-disadvantage mapping is documented in §5.5 with quantitative thresholds. Inference requires Goodhart guardrails: ≥3 independent benchmark sources, replication on Claude family or architectural-generality argument, sustained improvement across ≥2 quarterly cycles, domain coverage matching workflow usage. Single-source benchmark improvements or unsustained spikes do not count. Direct research findings still count regardless of benchmark coverage.

*Constraint relaxation forms (rev 4 added per `AI_Trading_Foundation.md` §5.6; **sizing row struck rev 17, superseded rev 18, and numeric envelopes retired rev 19**).* **There is no sizing cap or envelope left to relax.** Rev 17 struck §5.6's sizing row because its MATERIAL branch bounded against a 5% cap defined nowhere and because the cap was not disadvantage-keyed. Rev 18 retired the fixed 2% rule in favour of thesis-scaled risk budgeting; rev 19 then retired both numeric CaR envelopes. Per-thesis size is now an AI judgment with no numeric ceiling, governed by the seven-factor justification and mandatory adversarial attack on size. A2 cannot tune or restore an envelope; reintroduction requires a new owner directive. Universe restrictions don't admit graded relaxation (PARTIAL → no change; MATERIAL with full elimination → reconsidered for full removal). Concentration limits relax proportionally with caps. Frequency / cadence rules don't auto-relax (require explicit annual A2 review). Hit-rate thresholds and edge-decay metrics relax only if their derivation explicitly cites a Tier 2 magnitude. Constraints outside the lookup table generate out-of-table flags.

*When outcome (c) fires, what does the review produce?* Mechanical output per §5.7: structured audit trail per strategy listing (i) foundation citation graph parsed from mechanism + pre-mortem, (ii) status changes since strategy's foundation revision, (iii) outcome verdict per item, (iv) per-constraint relaxation candidate evaluation with load-bearing test result and applicable relaxation form, (v) out-of-table flags. The output is replicable — running the same orchestrator session on the same inputs produces the same verdict (within 2.24 cross-session inconsistency, which is the residual unavoidable variance).

Foundation changes that trigger per-strategy assessment include: a documented edge in Part 1 is removed or materially reduced; a documented disadvantage in Part 2 is added or materially increased; a documented disadvantage in Part 2 is **reduced or eliminated** (rev 3 — this branch did not previously trigger assessment but is the input to outcome (c)); the quarterly verification questions in `AI_Trading_Foundation.md` Part 4 produce a "yes" that changes the edge map; the annual A1 sweep produces Tier 2 fade-review outcomes affecting strategy-cited claims.

*Bias direction for (b) terminate vs (a) continue.* "Materially affected" is a judgment call. The default is bias toward termination — tie goes to termination when the impact is ambiguous. A strategy running on stale edge assumptions is exactly the failure mode the trigger exists to prevent; permissive interpretation of "not materially affected" would defeat the trigger's purpose.

*Bias direction for (c) constraint-relaxation (rev 4 update).* No "default direction" — outcomes are determined mechanically per `AI_Trading_Foundation.md` §5.3-§5.6. The mechanical thresholds embed conservative defaults: PARTIAL/MATERIAL reduction magnitudes are calibrated so most reduction signals do not trigger constraint relaxation; the load-bearing test rejects relaxation when constraints serve multiple disadvantages; benchmark inference requires ≥3 independent sources plus transferability plus sustained improvement to count as evidence. The conservatism is built into the criteria, not into orchestrator discretion. Where the criteria don't deterministically resolve a case, the constraint stays in force and the gap is routed to the autonomous `out-of-table-resolution` adversarial review (conservative_default = HOLD-current-value) — this is the intended exception path, not orchestrator judgment and no longer a participant handoff (rev 16, 2026-07-10).

*Experiment-level consequence.* If a foundation change simultaneously triggers per-strategy assessment on all strategies and all terminate, the experiment as a whole ends (no active strategies remain). Experiment termination via foundation change is a consequence of aggregated per-strategy assessments, not a blanket trigger. Constraint-relaxation outcomes do not contribute to experiment-level termination — by definition they keep the strategy alive with looser constraints.

*Version-change protocol (rev 3 added).* A new Claude version dropping does NOT trigger a foundation refresh or per-strategy assessment. Per `AI_Trading_Foundation.md` Part 4 §"Version-change protocol": Tier 2 numerical claims flip to "version-pending replication" status, the in-use-version field is updated, and strategies continue with existing foundation. Quarterly delta picks up version-specific research as it emerges; annual sweep does the full re-derivation on its normal schedule. This deliberately avoids the operational waste of refreshing on day 0 of a new version when no version-specific research yet exists.

**3. Runaway-success review trigger.** A strategy's deployed TWR doubles before that strategy reaches its 30-trade gate.

*Derivation.* AI disadvantage 2.18 (instruction adherence over capital preservation) includes reward function exploitation — strategies that look excellent on paper while carrying catastrophic hidden tail risk. Spectacular early returns are a warning sign for this pattern, not just a cause for celebration. The trigger is framed in sample terms rather than calendar terms to stay consistent with the uncapped-duration structure: a doubling before the strategy has had time to generate a meaningful sample is suspicious regardless of whether it occurred in calendar months or years. This trigger doesn't terminate the strategy directly; it forces a structured review to rule out reward exploitation, hidden leverage, or systematic luck. If the review finds legitimate strategy performance, the strategy continues toward its 30-trade gate. If it finds exploitation, the strategy terminates. The trigger applies only before the 30-trade gate for that strategy — post-gate, spectacular performance is no longer early-stage evidence of exploitation and the drawdown trigger is the operative capital-preservation control.

**4. Mark-to-market underperformance trigger.** After a strategy has been active (accumulating deployed-state time, excluding router-deactivation periods) for ≥36 months from its first trade, if that strategy's deployed TWR has trailed the SGOV benchmark by ≥10 percentage points on a cumulative basis measured over any rolling 12-month window, that strategy enters a two-routine adversarial termination review (Attacker routine + Orchestrator routine per `Claude_Task_Plan.md`, queue-driven through `events.queue_events` / `state.open_queue` with review type `m2m-termination`). The question being: should this strategy be terminated or continue? The orchestrator routine's verdict is the binding decision (terminate or continue), reasoning, and theater-check flag.

*Measurement.* The 36-month active-time threshold accumulates only during deployed periods; router-deactivation periods do not count toward it. The rolling 12-month gap is computed as (deployed TWR over the strategy's deployed sub-periods within the trailing 12 calendar months) minus (SGOV return over those same deployed sub-periods). Periods of router deactivation within the 12-month window are excluded from both sides of the comparison — the trigger asks whether active trading underperforms SGOV, not whether router inactivity does. "Deployed TWR" here is mark-to-market, including unrealized gains and losses on open positions, consistent with the drawdown trigger's measurement.

*Default on ambiguity.* If the orchestrator routine's final verdict is ambiguous or non-committal, the default is termination. An affirmative continue decision is required for the strategy to survive the trigger.

*Interaction with the 30-trade gate.* If this trigger fires for a strategy that has not yet reached its 30-trade gate, an orchestrator decision to continue does not waive the gate requirement — both the structured review outcome and the eventual gate evaluation must be satisfied independently. In practice, this interaction is rare: at typical catalyst-driven frequencies, strategies hit 30 trades well before 36 months of active time. The interaction primarily matters for long-horizon strategies whose low turnover makes 30 trades unreachable within that window.

*Derivation.* The 36-month active-time floor is calibrated to allow long-horizon strategies (held positions of 12+ months) to express their theses across at least two full earnings cycles on initial positions, while being short enough to complete the check within typical model-generation windows — firing too late defeats the trigger's purpose. The 12-month rolling persistence duration is a standard convention for distinguishing trend from noise in monthly-resolution return data; shorter windows fire on normal equity drawdowns, longer windows wait out the entire point of the trigger. The 10-percentage-point gap magnitude is calibrated such that the trigger fires when deployed TWR is meaningfully below SGOV (e.g., SGOV returns +5% while the strategy returns -5% over a 12-month window), not on mild underperformance produced by normal equity volatility. At tighter magnitudes (5 points), the trigger fires during normal variance; at wider magnitudes (20 points), the drawdown trigger fires first and this trigger adds little.

*Rationale.* The 30-trade gate serves as a mid-life filter for strategies with moderate to high trade frequency: silent negative-edge strategies get caught at the gate and terminated before accumulating prolonged underperformance. For strategies whose design produces low turnover — by holding individual positions for long periods, or by being infrequently activated by the regime router — the gate is unreachable within reasonable model-generation windows, and silent underperformance can persist for years without triggering drawdown (which requires catastrophic loss magnitudes, not mild underperformance). This trigger closes that gap uniformly across all strategies, with an active-time floor that prevents firing during normal early-phase variance.

*Why structured review rather than mechanical termination.* Unlike drawdown — where AI judgment under loss pressure is specifically unreliable — underperformance-vs-benchmark is a case where thesis context legitimately matters: a strategy's positions may be unrealized-negative but thesis-intact, pending a catalyst that has not yet materialized. The structured review is the appropriate place to test that claim adversarially. The two-routine architecture (with termination as the ambiguity default) prevents AI narrative over-fit from saving failing strategies: the attacker routine has no commitment to continuation, and the orchestrator routine must produce an affirmative "continue" decision for the strategy to survive the trigger.

Whichever trigger condition is met first for a given strategy initiates its termination path — mechanical termination for #1; structured review or assessment for #2, #3, and #4, any of which may or may not terminate the strategy. Termination of one strategy does not affect the other strategies' continued operation.

### Evaluation gate and termination structure

**Per-strategy 30-trade go/no-go gate.**

When a strategy has recorded 30 closed positions (trades only; SGOV parking adjustments do not count), the success threshold is evaluated against that strategy's cumulative excess real return from its first trade to that point.

- **If the threshold is met:** the strategy continues. No further evaluation-based termination applies to that strategy. The strategy terminates only when one of its kill triggers fires.
- **If the threshold is not met:** the strategy terminates at that point, declared unsuccessful.

Each strategy has its own gate. A strategy that fails its gate terminates while other strategies continue unaffected, including strategies that have not yet reached their own gates.

**Post-gate phase per strategy.**

After a strategy clears its 30-trade gate, that strategy runs indefinitely until one of its kill triggers fires. There is no ongoing success re-evaluation for that strategy. The design bet is that a strategy that clears its gate against a deliberately-high bar (excess real return ≥ 0% post-tax, post-inflation) has demonstrated enough directional signal to commit the runway to. Severe post-gate degradation is absorbed by the drawdown kill trigger; sustained mild underperformance vs. SGOV is absorbed by the mark-to-market underperformance trigger once the strategy has accumulated 36 months of active time.

**Final determination per strategy.**

Each strategy's success or failure is ultimately determined at that strategy's termination, using cumulative excess real return from first trade to final close. Clearing the 30-trade gate is not a commitment to a "successful" verdict — it is permission to continue running. A strategy that clears its gate at +3% excess real return, runs for five more years, and eventually terminates via drawdown trigger at -12% cumulative excess real return is declared unsuccessful at strategy termination. A strategy that clears its gate and is eventually ended by the foundation-change trigger at +25% excess real return is declared successful.

*Derivation of the 30-trade gate threshold.* Research on minimum viable sample sizes shows significant effect-size sensitivity to variance. For strategies with moderate per-trade variance, ~30 trades permits directional assessment at confidence insufficient for publication but sufficient for operational decisions. The gate is the first point at which any honest directional claim about a strategy can be made; placing it here avoids ending strategies prematurely while refusing to pass strategies that have only a handful of lucky outcomes.

*Implications of the structure.*

- A strategy that clears its 30-trade gate but then degrades slowly could run for an extended period before terminating, but not indefinitely: after 36 months of active time, the mark-to-market underperformance trigger provides a backstop for sustained SGOV underperformance that drawdown alone wouldn't catch. Between gate-clearing and the 36-month active-time floor, degradation is absorbed by the drawdown trigger alone.
- Model version drift during extended post-gate runs is partially addressed by the per-strategy foundation-change assessment. Gradual drift that falls below the foundation-change threshold is partly addressed by the underperformance trigger, which catches cases where drift produces persistent SGOV underperformance. Drift that neither invalidates a foundation claim nor produces SGOV underperformance is not addressed; that is an accepted cost of uncapped duration.
- The 30-trade gate is a real hurdle. The success threshold (excess real return ≥ 0%) is high — strategies will fail it at the gate, which is the point.
- Regime router deactivation periods do not count toward the 30-trade gate. A strategy that is active for only 4 months of a year will accumulate trades toward its gate only during those 4 months. This means a strategy whose ideal regime is rare may take much longer than its nominal trade-frequency implies to reach its gate.

*Regime diversity.* If a strategy reaches its gate in under ~12 months of active trading, the gate evaluation reflects a narrower regime window than ideal; this does not invalidate the gate, but it does weaken the generalizability of any conclusion drawn at evaluation. The post-mortem (whether final or at-gate) should explicitly note what regimes were represented in that strategy's active sample.

### Book-level NAV drawdown circuit-breaker — the versioned constant record (account-level; Rev 39, 2026-07-17)

This is the versioned record `bigquery/23_trading_control.sql` points to for `state.book_drawdown_watch` — distinct from the per-strategy kill criteria above; it is an **account-level** breaker on total NAV, not a per-strategy trigger. Its live definition is `bigquery/78_book_drawdown_rebase_and_staleness_gate.sql` (supersedes 23's original).

- **Measurement (flow-adjusted, Rev 39).** Drawdown is measured on **flow-neutral trading gain**, not raw NAV: `gain(t) = nav(t) − cumulative_net_external_flows(t)` (deposits +, withdrawals −, from `events.cash_flows`); `drawdown = (gain − running_peak_gain) / cumulative_net_flows`. A deposit raises NAV and cumulative flows equally, so it cannot ratchet the peak; a withdrawal cannot manufacture a phantom breach. When flows are constant this reproduces the old raw-NAV drawdown to within rounding.
- **Two tiers (Rev 39 — rebased at the SGOV→VOO park cutover, which put ~97% of NAV into equity and made the old single −15% raw-NAV full-halt trip on an ordinary correction while freezing exits):**
  - **`breach_soft` = drawdown ≤ −15%** → **entries-only pause** (via `state.entry_staging_allowed`). New-entry staging pauses; exit re-craft, per-strategy drawdown-kill terminations, and park cover are **unaffected**. A first-cut POLICY INVARIANT (not fitted to any trade sample), to be reviewed as the book grows.
  - **`breach_hard` = drawdown ≤ −40%** → **full halt** (an AND-term in `state.trading_enabled` / `state.trading_enabled_mechanical`). The genuine-catastrophe / data-corruption backstop; a book collapse of this magnitude warrants a hard stop and owner review.
- **`n_snapshots ≥ 5`** guard: fewer than five snapshots is insufficient peak history; defaults to no breach.
- **History note.** Rev ≤38 used a single **−15% raw-NAV** threshold as a full-halt gate term. The Rev 39 rebase is the fix for whole-system-audit finding **C1 (2026-07-17)**: the SGOV-era constant was never re-reviewed at the VOO cutover. A **park-beta-adjusted** soft tier (measure drawdown in excess of what holding the park vehicle alone would explain) is a documented future refinement, deferred until VOO price history accrues; the flat flow-adjusted tiers above are the current live definition.

### Strategy termination and capital redistribution

When a strategy terminates — by any kill trigger, gate failure, negative runaway-success review, or a **foundation-change-assessment "terminate" verdict** (including the annual A1/A2/A3 AI-edge review deleting a strategy whose edge has decayed) — its strategy portfolio value at termination ~~moves to SGOV~~ **moves into the park [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13** and is **redistributed to surviving strategies via a rail-bounded AI capital-allocation call, with no adversarial review.**

**Redistribution (the termination handler executes this inline).** The terminated strategy's booked allocation is redistributed in this fixed order:
1. **Fill pending newcomers first.** Any active strategy still below its probe-stake floor (a "pending newcomer," see "New strategy funding") is topped up toward the floor — oldest-pending first (FIFO), one filled to the floor before the next — until the terminated capital is exhausted.
2. **Allocate the remainder** among all currently-active strategies (including any newcomer just filled to its floor, and including regime-router-deactivated strategies — deactivation is temporary and the portfolio is still maintained) via the **AI capital-allocation call** (Operating_Protocols.md §16; owner-approved redesign 2026-07-19, `AI_DECISION_REDESIGN.md` §3 Redesign A) — bounded to [0.5×, 2×] each survivor's equal share, defaulting to the classic equal split below MEDIUM conviction.

There is **no hold option and no held-aside pool** — every dollar of a terminated strategy's allocation flows to survivors. The capital physically ~~sits in SGOV~~ **sits in the park [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13** until a receiving strategy stages a separately justified thesis; redistribution changes the *booked allocation*, not immediate market exposure. Each subsequent entry uses the no-ceiling per-thesis risk-budget discipline: the seven-factor justification and mandatory adversarial attack on size, never a preset deployment fraction or pace. The termination handler records the redistribution (amounts to each survivor, any newcomer fills, and — since 2026-07-19 — the call's conviction/rationale/invalidation) in `events.decision_log` alongside the termination post-mortem.

**Why no adversarial review (history + 2026-07-19 update).** Earlier revisions ran a three-routine adversarial review (recommendation + attacker + orchestrator) to adjudicate full / partial / hold, on the theory that a *systemic*-shock termination might mean survivors shouldn't absorb the capital. That review is **removed** as of the 2026-06 capital-model revision: (a) with redistribution equal-among-survivors there was no decision left to adjudicate; (b) redistributed capital is not immediately exposed — it accretes to the survivor's base, and any later entry must carry its own seven-factor size justification and adversarial size attack; drawdown kill triggers and regime-router deactivation remain independent post-loss/detection controls, not capital-allocation caps; (c) the "was this termination systemic?" diagnosis still occurs in the foundation-change assessment and the M2M-termination review. The `capital-redistribution` review type and its dedicated Recommendation routine are retired (see `Claude_Task_Plan.md`). **2026-07-19 update:** the *split* is no longer always equal — the AI capital-allocation call above lets it deviate, within bounds. This does **not** reopen (b) or (c): the call is same-session (no queue, no added latency), the [0.5×, 2×] rail constrains allocation proportions rather than later thesis size, there is still no held-aside pool or default-HOLD, and each receiving strategy still stages only separately justified theses under the no-ceiling risk-budget discipline. The allocation call therefore needs no additional adversarial pipeline merely to move booked capital; it does not certify or cap any future exposure.

**Scaling consequence (intended).** Redistribution defaults to equal-per-event (or, at MEDIUM+ conviction, a bounded AI-directed deviation favoring the stronger survivor), but winners *survive longer*, so they are present for more termination-redistribution events (and more deposit events) and thus accrete more capital over time — a passive, survivorship-driven increase in the dollar base available for their future thesis budgets, with an additional bounded tilt toward the call's judgment of relative strength at each event. This does not prescribe a percentage deployment rate or a size cap: each future thesis remains independently justified against the seven factors and adversarially attacked on size. It rewards durability rather than short-sample magnitude (a coarse but robust selector — a strategy must keep *not dying* to keep accreting). Note this only reallocates the existing pie; net new capital — the lever that makes position sizes *meaningful* — comes from deposits (see "Deposits").

### Strategy authoring — judgment-native machinery (owner directive 2026-07-19)

A candidate strategy's entry/exit machinery may be authored as a **structured judgment protocol** — criteria the executing session evaluates fresh each time, with declared conviction gates and explicit invalidation criteria — instead of fixed numeric triggers, and should be where the cited edge is judgment-shaped (`AI_DECISION_REDESIGN.md` §3 Redesign B; operational spec in Claude_Task_Plan.md SL2 (A) 1b). Nothing else changes: the protocol must declare a countable signal definition and expected signal-rate band (the SHADOW gate's input); the no-ceiling risk-budget discipline (**rev 19** — seven-factor justification plus mandatory adversarial attack on size), kill triggers, 30-trade gate, and graduation rails bind unchanged; spec-freeze covers the protocol text exactly as it covers formulas; and the pre-mortem must attack the protocol's own failure class (criteria drift under loss pressure) explicitly. This applies to FUTURE candidates only — no live strategy's frozen machinery is touched.

### Pre-mortems (per-strategy required before that strategy's capital deploys)

Before any capital deploys into any strategy, that strategy must have completed its own pre-mortem with structured adversarial review, and the one-time regime-router pre-mortem must have completed. (rev 16, 2026-07-10 — scoped per-strategy under the Strategy Arsenal Lifecycle; N is now the dynamic roster size.) For the **founding cohort** the requirement was N+1 pre-mortems (one per strategy plus one for the router), all complete before the experiment's first trade. For a **mid-life newcomer**, its own pre-mortem must reach a SUFFICIENT adversarial verdict — surfaced as `state.strategy_adoption_readiness` — before it enters SHADOW; capital is committed only later, at PROBE. A newcomer never re-opens the router pre-mortem: it only *appends* its own activation rule.

**Strategy pre-mortems (one per strategy, N total).** Each strategy's author (Claude, in the strategy project) is required to articulate in writing:

- The specific scenarios under which this strategy would lose money systematically
- The specific market conditions in which it would underperform its SGOV benchmark (not just lose money, but fail to beat idle)
- The specific signs that would indicate the strategy's edge (if any) has decayed
- The specific failure modes from `AI_Trading_Foundation.md` Part 2 that pose the greatest risk to this strategy
- The strategy's declared expected trade frequency (measured over active periods only)
- A dated set of expected failure indicators that can be checked at monthly reviews
- If the strategy's core edge is materially constrained by a specific disadvantage in `AI_Trading_Foundation.md` Part 2, the pre-mortem must explicitly confront that constraint and specify any exclusions or limitations on the strategy's universe that flow from it

**One router pre-mortem.** The regime router's author is required to articulate:

- The specific regime states the router attempts to classify
- The specific technical indicators used and their activation thresholds
- The specific fundamental analysis template and its inputs
- The specific scenarios under which the router would misclassify regime (2.7 being the primary risk)
- The specific failure modes from `AI_Trading_Foundation.md` Part 2 that pose the greatest risk to the router's function (2.7, 2.4, 2.14, 2.24 at minimum)
- A dated set of expected failure indicators that can be checked at monthly reviews

**Self-containment requirement for pre-mortem artifacts.** Each pre-mortem must be a fully self-contained artifact that enumerates every specific item on its requirements list within the pre-mortem document itself. Cross-references to other parts of the strategy document (e.g., "per the shared regime vocabulary," "per the fundamental template section") do not satisfy "the specific X" requirements. The pre-mortem must reproduce the required content in its own text so that a reader with no access to any other document — including the Attacker routine for adversarial review, whose prompt explicitly forbids reading other repo files — can verify requirement satisfaction directly from the pre-mortem. This applies at drafting time (the original pre-mortem), at revision time (any revised pre-mortem), and at the prompt-construction stage (any prompt that embeds the pre-mortem for adversarial review must embed the self-contained version, not a cross-referencing version).

This requirement generalizes to any other artifact entering a structured adversarial review in this experiment: the artifact delivered to the Attacker routine must be self-contained with respect to all definitions, thresholds, rules, and inputs the review requires.

**Adversarial review of each pre-mortem.** For each of the N+1 pre-mortems, structured review runs as a two-routine adversarial review (Attacker routine + Orchestrator routine per `Claude_Task_Plan.md`, queue-driven through `events.queue_events` / `state.open_queue` with review type `pre-mortem`).

**Two-routine pre-mortem adversarial-review architecture (universal, applies to all pre-mortem reviews going forward).**

- *Attacker routine.* Fresh routine context. Given via the queue entry: the pre-mortem itself and the instruction to attack it. Instructed to identify where the pre-mortem is theater (vague indicators, failure modes that sound concerning but aren't actually checkable, frequency declarations that can't be verified, activation thresholds that can be reinterpreted after the fact). Attacker prompt explicitly forbids reading other repo files. Output: verdict on whether the pre-mortem is sufficient or contains material weakness requiring revision, with specific Tier 1 / Tier 2 / Tier 3 weaknesses identified, stored as the keyed attacker row in `events.adversarial_reviews`.
- *Orchestrator routine.* Fresh routine context. Reads the exact current attacker row from `state.adversarial_reviews_current` by `(review_id, cycle_number, role='attacker')` and the pre-mortem itself. Produces an explicit independent assessment that documents: (a) for each Tier 1 weakness the attacker identified, valid Tier 1 / valid but Tier 2-3 / invalid; (b) any theater in the attacker's output (generic-sounding objections without specific anchors); (c) any Tier 1 weaknesses the attacker missed; (d) a verdict (SUFFICIENT or TIER 1 DEFECT — REVISION REQUIRED).
- *No separate judge or theater auditor.* The orchestrator routine's verdict is final for the cycle, and the orchestrator self-certifies the theater-check flag. (See "Architectural simplification — accepted-risk note" below; the original three-session-with-judge architecture is not restored as part of migration scope.)

**Historical note — three-session architecture used for early pre-mortem reviews.** The regime-router pre-mortem (4 cycles) and Strategy A pre-mortem cycles 1–4 used a three-session architecture (Attacker / Judge / Adjudicator-on-disagreement) executed as manual incognito Claude.ai conversations with paste-back. All eight cycles produced CONVERGENT theater-check flags between attacker and judge, with zero adjudicator invocations. This established that the separate judge had been validating rather than challenging the attacker, motivating the simplification to single-session-with-orchestrator-review. Decision_Log.md entries for those reviews record the three-session outputs; they are not to be retroactively modified. The current routine architecture preserves the rev 3 simplification (single-attacker-equivalent + orchestrator-equivalent) translated into the two-routine BigQuery-keyed handoff pattern.

**Logging.** The attacker and orchestrator transcripts are recorded in `events.adversarial_reviews`; the decision record carries the theater-check flag in `events.decision_log`.

**Completion requirement (rev 16, 2026-07-10 — scoped to the founding cohort).** For the **founding cohort**, all N+1 pre-mortems (original + adversarial review + any revisions) had to complete before the experiment's first trade — "complete all N+1 before the experiment's first trade," not merely before each strategy's own first trade — because once any founding strategy traded, the founding batch's parameters were immutable and incomplete pre-mortems on other founding components would become locked-in gaps. This all-before-first-trade rule applied to the **founding batch only**. A **mid-life newcomer** adopted through the Strategy Arsenal Lifecycle instead completes ITS OWN pre-mortem (a SUFFICIENT adversarial verdict) before it enters SHADOW, spec-locks at SHADOW entry, and commits capital only at PROBE — its incompleteness can never lock in gaps for already-live strategies, consistent with per-strategy immutability. The router pre-mortem is one-time; a newcomer appends its own activation rule without re-opening it.

**Architectural simplification — accepted-risk note (operational rationale superseded by routine migration; substantive policy preserved).** All structured adversarial reviews in this experiment — pre-mortem reviews, regime-router divergence reviews, mark-to-market termination reviews — use a single-attacker-equivalent followed by orchestrator-routine independent assessment, instead of the three-session Attacker / Judge / Adjudicator architecture originally specified. The original three-session design ran the attacker, judge, and adjudicator-on-disagreement as separate incognito Claude.ai conversations with paste-back, applying `AI_Trading_Foundation.md` 2.24 (cross-session inconsistency) as a deliberate edge: context-isolated sessions produce somewhat-different reasoning, and convergence between attacker and judge is the validation signal. Empirical operation across eight three-session cycles (four for the regime-router pre-mortem, four for Strategy A pre-mortem cycles 1–4) showed CONVERGENT theater-check flags in 8 of 8 cycles with zero adjudicator invocations. The separate-judge step was therefore ratifying the attacker rather than producing meaningfully independent reasoning, while incurring substantial operational cost (multiple incognito tabs per review, paste-back rounds, manual coordination). The rev 3 simplification trades: independent verification of the attacker by a separate session-isolated judge → in-conversation review by the orchestrating session, which is not session-isolated from the active drafting conversation and is therefore structurally less independent. The routine-architecture migration translates this into the two-routine pattern (attacker routine → orchestrator routine, BigQuery-keyed handoff). The operational-cost rationale that justified rev 3's simplification (manual paste-back unsustainable) no longer applies under routines; the simplification is preserved on substance grounds rather than cost grounds for pre-mortem / divergence / M2M-termination reviews. **Future readers of this document — including future Claude routines reviewing the experiment design — should not flag this simplification as a defect to be corrected back to three-session for those review types.** If empirical theater-check rates suggest self-certification is producing under-detection, a separate Theater Auditor routine can be added per review type as a future revision; that is a known adjustable parameter, not a defect.

**Pass conditions (rev 15 — supersedes rev 14 conditions on stopping; deployment-risk stop and forcing question added).** A pre-mortem is considered to have passed adversarial review when both of the following hold:

1. **Tier 1 clean OR deployment-risk acceptable.** Either (a) the most recent adversarial cycle surfaced no Tier 1 structural defects, or all Tier 1 defects surfaced in the most recent cycle have been resolved by a subsequent revision and the next cycle ran clean (rev 14 condition retained); OR (b) the Orchestrator routine, after explicit assessment, judges that remaining Tier 1 items are documentation, wording, or calibration grade rather than items that would change deployment risk if accepted unfixed (rev 15 deployment-risk stop). The deployment-risk stop is invokable when the residual Tier 1 items (i) do not contradict any specific quantitative claim the strategy makes about its own loss-bounding, (ii) do not omit a top-five AI_Edges disadvantage from req-4 enumeration, (iii) do not introduce or leave in place a trigger that fails to detect the failure mode it nominally exists to detect, and (iv) do not break self-containment for a numbered requirement. Items that pass these four screens are deployment-risk-acceptable as Tier 1 even if technically structural.

2. **Diminishing-returns reassessment.** Per rev 14 — pattern-based stop conditions retained: (i) cycle-to-cycle items decreasing AND most recent cycle Tier 1 clean (clean stop); (ii) attacks recycling prior framings without surfacing new structural surfaces (saturation stop); (iii) all Tier 1 items revision-induced rather than original-architecture (revision-churn stop). If none of (i)-(iii) hold and the most recent cycle still surfaced something material, evaluate the rev 15 forcing question (below) before running another cycle.

**Forcing question (rev 15 mandatory pre-cycle assessment, addresses generative-bottomless problem).** Before the next cycle's Attacker routine fires, the Orchestrator routine of the prior cycle (or, for cycle 1, the routine that triggers the queue entry) must explicitly answer in writing in its `events.adversarial_reviews` transcript and decision record: *"If we accept the pre-mortem at its current revision with these residual Tier 1 items, would that change deployment risk vs. fixing them first?"* The answer must be one of: (a) "yes, fixing changes deployment risk meaningfully — continue cycling"; (b) "marginal — the fixes are quality improvements but would not change deployment risk meaningfully"; (c) "no — remaining items are documentation/wording/calibration grade." Answers (b) and (c) trigger the deployment-risk stop in pass condition 1(b). Answer (a) requires identifying what specifically would change in deployment risk if the items remained; vague answers ("the document would be more rigorous") do not satisfy (a). The forcing question's purpose is to prevent pattern-matching defaults: pattern-based stop conditions can fail silently (none fires, so cycling continues), but the forcing question requires an explicit substantive answer every cycle.

**Cycle-count soft cap (rev 15).** No hard ceiling on cycles — sometimes a late cycle surfaces something architecturally serious. Soft cap at cycle 5: starting at cycle 5, the Orchestrator routine must explicitly justify continuation in Decision_Log.md rather than defaulting through "stop conditions don't fire." The justification must engage the forcing question's framing — what specific deployment risk would another cycle bound that the current revision does not? If no such risk is identifiable, the soft cap fires acceptance.

**Theoretical-bottomless rationale (rev 15 added).** Adversarial review against an LLM-generated artifact has no theoretical bottom. The attacker can always find another wording inconsistency, calibration looseness, or asymmetric textual treatment somewhere in the document, because the document is generated by the same kind of process the attacker is critiquing. The pattern-based stop conditions in rev 14 were heuristics for when to consider stopping but did not address the substantive question — does the artifact bound deployment risk well enough to deploy? Rev 15 makes that question load-bearing: review continues until additional review would not change deployment risk, regardless of whether the attack pattern has formally saturated. This change was made after Strategy B reached cycle 5 with a similar pattern to Strategy A's accepted-at-cycle-6 saturation pattern, but with the rev 14 conditions reading as "not saturated" because of one revision-induced new surface — strict pattern reading would have continued indefinitely on minor calibration grades.

**Stopping rule (rev 12-14 framing — retained for context).** Adversarial review cycles on a single pre-mortem are bounded. Observed behavior during the initial router pre-mortem and the Strategy A pre-mortem showed that each revision cycle surfaced a roughly constant or growing set of critiques in the early cycles, with theater-check flags consistently CONVERGENT across sessions — evidence that the adversarial architecture saturates (AI_Trading_Foundation.md 2.4 and 2.24 predict this: weight-level biases cut across sessions, and separate sessions on the same weights produce correlated critique sets). A pre-mortem that cannot be reviewed to a clean pass is not necessarily a defective pre-mortem; it may be at the limit of what the adversarial architecture can evaluate on a system of this complexity. The pre-mortem exists to surface limitations before trading, not to eliminate them.

**Floor acknowledgment.** These pass conditions reflect a structural property of LLM-generated adversarial review: the same model weights that produce the artifact produce the revisions and produce the critique. Successive revision can reduce defect severity (the cycle-to-cycle Tier 1 count is the operational measure) but cannot reach a zero-defect artifact, because each revision samples from the same distribution that produced the original. The stopping rule accepts a non-zero residual defect floor as a condition of doing the work at all. The "Known limitations" section of each pre-mortem is the operational expression of this acceptance. A pre-mortem that appears to approach zero defects across many cycles is more likely exhibiting convergent critique saturation (caught by the theater-check flag) than achieving genuine cleanness; the diminishing-returns reassessment in condition 2 is designed to distinguish the two.

**Tier definitions (for the stopping rule):**

- **Tier 1 — Structural defects and internal contradictions.** Items where the pre-mortem contradicts itself textually, specifies a metric that is mathematically incoherent, or describes a mechanism that cannot do what it claims (e.g., blinding that does not blind, counterfactual that is path-dependent on its own subject, immutability clause contradicted by calibration language elsewhere). These MUST be resolved.
- **Tier 2 — Calibration and measurability gaps.** Items where a threshold, indicator, or protocol is specified but its specific numeric or procedural form is unjustified or may be unfireable under plausible operating conditions. These SHOULD be resolved but may be deferred to known-limitations if resolution would require arbitrary re-specification.
- **Tier 3 — Completeness and scope gaps.** Items where the pre-mortem does not address a failure scenario or operational detail that a reasonable reader could expect but that is not part of the pre-mortem requirements list. These MAY be resolved or explicitly deferred; a pre-mortem is not a complete operational manual and some completeness demands belong in other documents or in strategy-level specifications.

When a pre-mortem passes via the diminishing-returns reassessment with residual Tier 2/3 items (rather than via clean pass with no residuals), the accepted pre-mortem must contain a "Known limitations" section enumerating every Tier 2 and Tier 3 item surfaced during review, with a note for each on whether it will be addressed by a future revision trigger (monthly review, foundation-change, etc.) or accepted as permanent scope. This section is part of the pre-mortem artifact going forward and is checked at every monthly pre-mortem-indicator review.

**Triage responsibility (rev 16, 2026-07-10 — human removed).** Tier assignment is done **mechanically by the AR_orc orchestrator routine**, applying the working definitions above after each adversarial cycle completes, and logged to Decision_Log.md (and `events.decision_log`) as part of the cycle outcome. This absorbs the former "participant with Claude assistance" step without adding any human gate. As before, the triage is deliberately **not** itself subject to adversarial review (or the loop regresses infinitely); a different fresh-context routine re-reviewing the same items may disagree on tier, and that is accepted — triage stays non-adversarial by design.

**Rationale for the pre-mortem approach.** The pre-mortem replaces a pre-live backtest phase. AI-driven backtesting on historical catalyst trades is contaminated by training-data look-ahead bias (AI disadvantage 2.19) to a degree that makes the output unreliable as a go/no-go signal. The adversarial pre-mortem forces equivalent discipline without the contamination. If a pre-mortem cannot survive adversarial review, the corresponding strategy or the router is not sufficiently well-defined to deploy capital.

### Success threshold

**Excess real return ≥ 0%** — deployed TWR beats SGOV over the same evaluation periods, after taxes and inflation.

Applied per strategy, at two points:

1. **At the strategy's 30-trade gate**, against cumulative excess real return from the strategy's first trade to the 30-trade mark. Failure here terminates that strategy.
2. **At the strategy's termination**, against cumulative excess real return from first trade to final close. This is the final determination for that strategy.

Measurement specifics:

- Deployed TWR is measured on periods when the strategy's capital was in active trades, excluding SGOV parking periods (both regime-router deactivation periods and between-trade SGOV holding within active periods).
- SGOV benchmark is the return SGOV would have produced on the same capital amounts over the same calendar periods during which deployed capital existed.
- Excess return = deployed TWR − SGOV benchmark, both measured over matching periods.
- Fees include commissions, spread costs on execution, and any subscription costs attributable to the workflow, subtracted from deployed TWR before computing excess.
- Taxes calculated at actual marginal rates, with short-term capital gains treated as ordinary income. Long-term capital gains rates apply to positions held ≥12 months; strategies that plan to hold positions long enough for LTCG treatment should reflect this in their excess-return calculations.
- Inflation measured by CPI over the period being evaluated.
- The evaluation period runs from the strategy's first trade to its evaluation point (gate or termination). Cherry-picking start dates is disallowed.
- TWR is invariant to capital flows; deposits and withdrawals to the strategy portfolio do not affect the measured return.

---

## Experiment termination vs. strategy termination

**Strategy termination** occurs when a single strategy's kill triggers fire, its gate fails, or its runaway-success review concludes negatively. Other strategies continue unaffected.

**Experiment termination** occurs when either:

- The last active strategy terminates (no active strategies remain — the experiment has nothing left to measure); or
- A foundation change triggers per-strategy assessments that terminate all strategies simultaneously.

The experiment continues as long as at least one strategy is still active. Individual strategy terminations are expected and survivable; they are part of the multi-strategy architecture's design, not failures of it. The experiment's own termination is a separate event from any single strategy's termination.

**What experiment termination means operationally:**

- All remaining open positions across all still-active strategies close at next available daily review.
- No new entries across any strategy.
- Final experiment-level post-mortem is written, covering all strategies' individual histories and the router's function.
- The new-experiment constraints below apply before any successor experiment begins.

---

## After termination: restart and new-experiment constraints

(rev 16, 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive.) Restart and successor decisions are no longer "the participant may decide"; they are made autonomously by the Strategy Arsenal Lifecycle. The anti-laundering constraints below are **preserved in substance** and are now machine-enforced rather than exercised as human judgment.

When a strategy terminates, it re-enters the arsenal only as a fresh **CANDIDATE** proposed by SL1 (typically seeded by its own post-mortem, or by a scouting routine), subject to the same adversarial + shadow + paper + probe + 30-trade graduation scrutiny as any newcomer. There is no separate "successor experiment" decision for a roster change: adding or restarting a strategy is a versioned roster change that runs continuously through the machinery. A true whole-experiment successor — a change to the **machinery itself** (the qualification tests, the adversarial protocol, the graduation bars, the kill triggers, deterministic redistribution) — is the only thing still reserved to an explicit owner directive.

Any restart must satisfy the following constraints — otherwise it is the same strategy with cosmetic changes, not a new one. SL1 enforces each mechanically with **default-REJECT on ambiguity**; a candidate that fails any constraint is rejected with a cooldown stamp:

- **Material structural difference.** A restarted strategy must differ from the prior in more than just threshold numbers. SL1's structural-difference check requires the candidate to differ in ≥1 of {strategy approach, instrument scope, position-sizing methodology, regime-router structure, kill-criteria structure} beyond threshold numbers, checked against every live AND every terminated strategy (for a restart, against its own post-mortem). Same implementation with the drawdown trigger at 60% instead of 50% fails the check.
- **Documented post-mortem of the prior.** A restart may only begin after a written post-mortem of the prior — now **auto-authored by SL2** at termination (the POST_MORTEM state, guaranteed to exist) — that identifies what the prior revealed, what it failed to resolve, and what specifically the new design addresses, populating a `material_diff_required_for_restart` field. SL1 refuses a restart whose post-mortem is missing or silent on the difference.
- **Parameter re-derivation, not inheritance.** New parameters are derived fresh by SL2 with a provenance record; SL1 rejects a restart whose parameters byte-match the prior. If similar parameters emerge from fresh derivation, that's fine; if they're copied because they felt right, that's continuation.

The purpose is unchanged: to prevent strategies from continuing under new names when the honest response would be to stop them entirely, and to prevent the experiment as a whole from continuing under a new name when it should stop. Under the lifecycle this is preserved by the default-REJECT qualification bias, the default-KEEP retirement bias, and the N ≥ 2 floor — the honest answer is still allowed to be "do not restart."

**No cooling-off period as a human-psychology delay.** Cooling-off is human-psychology-based (emotional reset between losses and new decisions) and does not apply to an AI-driven workflow where the decisions to restart are themselves subject to adversarial review — which is now literally true under SL1 + AR_att/AR_orc. The anti-churn post-rejection / post-termination cooldown stamp enforced by SL1/SL4 is an **autonomous rate-limit rail** (preventing oscillation and relabeled-continuation), not a human-psychology cooling-off period.

---

## Review cadence and enforcement

The experiment's review cadence is split by component type. Different components have different bias profiles and benefit from different cadences.

### Daily (mechanical)

- Technical indicator updates for the regime router.
- Account-level position check: what is open, what is closed today.
- Regime router activation state updates when indicators cross thresholds (triggering adversarial reviews if new state disagrees with current fundamental state).

These are mechanical operations with no AI judgment component. Daily cadence is appropriate because the inputs update daily and the outputs are deterministic.

### Weekly (mechanical strategy-level checks)

Each week, Claude computes per strategy:

- Current deployed TWR and current excess real return vs. SGOV benchmark.
- Current drawdown state (peak-to-trough deployed TWR).
- Trade count toward that strategy's 30-trade gate.
- For strategies with ≥36 months of accumulated active time: current rolling 12-month deployed TWR vs. SGOV gap, flagged if ≥10 percentage points.
- Whether any kill trigger's firing condition is met.

If any kill trigger's firing condition is met for a strategy, the corresponding termination path is initiated that week — immediate termination for the drawdown trigger; structured review for the runaway-success, foundation-change, and mark-to-market underperformance triggers. When a strategy terminates (whether via mechanical trigger or review conclusion), deterministic redistribution to surviving strategies runs immediately (handled inline by the termination handler — no separate review).

These are mechanical checks against mechanical metrics. Weekly cadence allows faster detection of drawdown or gate events without exposing AI-judgment components to recency bias.

### Monthly (AI-judgment components)

Once per month, on the first trading day of the month:

- **Fundamental analysis refresh.** The regime router's fundamental analysis template is re-run for all strategies. New fundamental activation states are produced. Any resulting disagreements with current technical states trigger adversarial reviews.
- **Pre-mortem failure indicator check.** Per strategy and for the router, the dated failure indicators from the pre-mortems are checked explicitly.
- **Realized-frequency diagnostic.** Per strategy, realized trade frequency over active periods only (excluding router-deactivation periods) is compared to declared frequency. Material gaps are flagged for diagnostic review — this does not auto-terminate the strategy but surfaces strategy-level process problems.
- **Theater-check flag review.** Router disagreement reviews and any M2M-termination reviews from the month are surveyed for patterns — if the theater-check flags indicate consistent convergence across supposedly-adversarial sessions, this is flagged as architectural drift.

(Rev 3 cadence change, 2026-04-25: the `AI_Trading_Foundation.md` review previously included here at monthly cadence has been moved to quarterly + annual cadence — see Quarterly and Annual sections below.)

Monthly cadence for AI-judgment components partially averages across 4 weeks of input rather than maximizing recency exposure (compensation for `AI_Trading_Foundation.md` 2.14).

### Quarterly (rev 3 added)

Once per quarter, on the first trading day of the new calendar quarter:

- **`AI_Trading_Foundation.md` quarterly delta review (Q3 task).** Verification questions in Part 4 are answered explicitly against last-quarter primary-source research (papers, arXiv preprints, company announcements, regulatory filings). Default bias YES — err toward flagging change. Adversarial framing — look for evidence that contradicts or updates documented edges and disadvantages, not evidence that confirms them. Any material changes trigger per-strategy foundation-change assessments per the Foundation change trigger above (which may produce continue / terminate / constraint-relaxation outcomes per strategy).
- **Regime retrospective review (Q1 task).** Already in place, unchanged by rev 3.
- **D long-horizon candidate screen (Q2 task).** Already in place, unchanged by rev 3.

### Annual (rev 3 added)

Once per year, on the first trading day of January (or the experiment's anniversary month if January-anchoring isn't operationally clean for the participant):

- **`AI_Trading_Foundation.md` annual full re-derivation (A1 task).** Full re-pull against last-2-years primary-source research, not delta against prior version. Tier 1 items audited for affirmative architectural-change evidence; Tier 2 items subject to fade review (specific magnitudes absent from last-2-years research are flagged version-pending or replaced with current evidence). Default bias: YES on flagging change; NO on removing items absent affirmative evidence. Updated `AI_Trading_Foundation.md` is published with revision-history entry. Any items materially changed trigger per-strategy foundation-change assessments.
- **Per-strategy constraint audit (A2 task, rev 3 added).** Inverse of pre-mortem. The reviewer's job is to identify constraints in any strategy mechanism that were added to address a specific disadvantage where current `AI_Trading_Foundation.md` shows the disadvantage has been materially reduced or eliminated. Output: candidate relaxations, each requiring constraint-relaxation review per the Foundation change trigger procedure above. Default outcome on each candidate: NO relaxation unless reviewer affirmatively makes the case. The audit is annual (not quarterly) because the underlying signal (capability improvements through model upgrades and research findings) doesn't warrant tighter cadence and the cognitive load of monthly relaxation reviews would be excessive.

*Why annual not quarterly for A1/A2.* The annual cadence reflects two findings: (a) Tier 2 fade review needs sufficient time-window to distinguish "absent because cured" from "absent because no one wrote a paper this quarter" — 2 years of evidence is the minimum window for the asymmetric publication bias to wash out; (b) constraint-audit costs cognitive load on each per-strategy evaluation, and quarterly cadence would consume excessive review capacity for low-frequency upstream signal.

### Monthly review template

To prevent the monthly review from drifting into whatever feels salient, the following structure is required. Each section is produced per review.

**Per-strategy sections (×N):**

1. Deployed TWR (cumulative since first trade) and excess real return vs. SGOV benchmark
2. Drawdown state: current peak, current trough since peak, peak-to-trough percentage
3. Trade count toward 30-trade gate; trades closed this month
4. Realized frequency over active periods this month vs. declared rate
5. Pre-mortem failure indicators status (each indicator checked explicitly)
6. Any kill trigger evaluation results
7. Regime router history for this strategy this month: activation state changes, any adversarial reviews invoked

**Experiment-level sections:**

8. `AI_Trading_Foundation.md` verification status check: report whether last completed quarterly Q3 task and last completed annual A1 task results have been propagated to per-strategy foundation-change assessments. (The full Part 4 verification is no longer monthly per rev 3 — moved to Q3 quarterly + A1 annual. Monthly review confirms downstream propagation is complete.)
9. Any per-strategy foundation-change assessments triggered this month
10. Regime router disagreement log for the month (all adversarial reviews, their outputs, theater-check flags)
11. Any strategy terminations this month and their deterministic redistribution allocations (amounts to each survivor / newcomer fills)
12. Any new research surfaced that bears on the foundation document
13. Router counterfactual attribution: actual sum-of-strategy TWR minus the all-active counterfactual TWR (router's capital-preservation contribution) and minus the all-SGOV counterfactual (system-vs-SGOV). Per `Strategy.md` router pre-mortem Section 7. Neither metric is a kill trigger, but sustained negative router-contribution over 12+ months triggers foundation-change reassessment.

### Parameter visibility

The parameters in this document are visible to Claude at the strategy-portfolio and experiment level but not at the per-trade level. Individual trade decisions do not reference these thresholds. Strategy design and per-trade execution operate on strategy-layer documentation only.

---

## Operational requirements

### Routine architecture for all structured adversarial reviews

All structured adversarial reviews in this experiment run as Claude routines with the exact-key BigQuery transcript handoff specified in `Claude_Task_Plan.md`, queue-driven through `events.queue_events` / `state.open_queue`. No exceptions. This applies to:

- Pre-mortem adversarial reviews (Attacker routine + Orchestrator routine; one queue entry per cycle)
- Regime router divergence reviews (Attacker routine + Orchestrator routine; one queue entry per disagreement)
- Mark-to-market underperformance termination reviews (Attacker routine + Orchestrator routine; one queue entry per trigger firing)
- Any future structured adversarial review this experiment's design adds — defaults to the Attacker + Orchestrator two-routine pattern unless the design explicitly specifies a different pipeline

**Rationale.** The adversarial architecture depends on context isolation producing genuinely independent reasoning (`AI_Trading_Foundation.md` 2.24 deliberate-exploitation edge). Each routine run is a fresh session with no chat history, satisfying the context-isolation property. The attacker writes its transcript once to `events.adversarial_reviews`; the Orchestrator reads only the exact current attacker row plus the artifact under review. No cross-routine memory ingestion path exists for routine outputs.

**Residual limitation under routine architecture (acknowledged, accepted).** Routines have full repo read access by default. Structural prevention of cross-file reads (the property incognito Claude.ai sessions provided by virtue of having no project access) is replaced by prompt-discipline blinding: the Attacker routine prompt explicitly forbids reading other repo files (Decision_Log.md, prior reviews, broader sections of the artifact's parent document). This is structurally weaker than incognito blinding because a routine could in principle violate the prompt; the mitigation is auditable via the routine's tool-call log. Per-routine accepted-risk note.

Even under perfect blinding, all routines run on the same underlying model weights. Hard-wired biases (`AI_Trading_Foundation.md` 2.13 optimism, 2.14 recency, 2.15 base-rate neglect) cut across routine boundaries regardless of context isolation. The theater-check flag in the Orchestrator routine's output is the diagnostic check against weight-level bias; the monthly review's theater-check survey is the aggregated diagnostic. This residual limitation is uncorrectable without model improvements; the mitigations specified are the best available.

**Operational procedure.** Adversarial reviews are triggered by other routines (M4 for divergence reviews, A3 / Q4 for foundation-driven pre-mortem refresh, kill-trigger detectors for M2M termination) inserting `PENDING_REVIEW` events into `events.queue_events`. (Capital redistribution after a termination is not a review — the termination handler performs it deterministically.) The Attacker routine and Orchestrator routine fire daily, each processing queue items at their phase. No human action is required for any structured adversarial review under this architecture.

### Prompt construction for adversarial reviews

Prompts for any adversarial review must be drafted so that each routine in the pipeline receives all context it needs from queue entry + designated input file(s), with no requirement for cross-file inference beyond what the prompt explicitly authorizes.

Specifically:

- The Attacker routine prompt is self-contained with all fixed context it needs (rules, vocabulary, requirements, the full self-contained artifact under review per the self-containment requirement above, and any relevant inline definitions of cross-referenced AI_Edges disadvantages or other concepts the review depends on). The artifact under review is referenced via the queue entry's `artifact_path` field; the Attacker routine reads only that path plus its prompt.
- The Orchestrator routine reads the exact current attacker row from `state.adversarial_reviews_current` plus the artifact under review (path from queue entry). No other repo files unless the prompt explicitly authorizes.

**BigQuery-keyed handoff rule (universal under routine architecture):**

- The Attacker writes one transcript row keyed by review id, cycle number, and role; the Orchestrator reads only that exact current row and its authorized queue/artifact inputs.
- Each downstream routine reads only the upstream transcript rows and the queue entry's authorized inputs.
- No routine writes or reads a local transcript mirror. No routine modifies the queue entry beyond marking its phase complete.

The artifact under review is the single source of truth referenced from the queue entry. Self-containment of that artifact is enforced at drafting time per the self-containment requirement; if the artifact is not self-contained, the Attacker routine flags this as a Tier 1 defect and exits without producing an attack.

This requirement applies at the prompt-construction level: any routine prompt that drafts adversarial-review queue entries (M4, A3, Q4, kill-trigger detectors, termination handlers) must produce queue entries that satisfy this pattern. Queue entries that violate it must be redrafted before the relevant routines fire.

---

## What this document does not contain

- Strategy rules. Those derive from `AI_Trading_Foundation.md` and live in the strategy document.
- The specific technical indicator set used by the regime router. That lives in the strategy document and is immutable once trading begins.
- The specific fundamental analysis template used by the regime router. That lives in the strategy document and is immutable once trading begins.
- Per-trade risk management. Those are strategy-level decisions.
- ~~Position sizing methodology beyond the 2%-of-strategy-portfolio parameter. Strategy-level detail.~~ **[rev 18, 2026-07-28 — NO LONGER TRUE: this document now DOES contain the position-sizing methodology. §Position size is the canonical specification of thesis-scaled risk budgeting (the CaR definitions, the seven-factor justification list, and the mandatory adversarial size attack; the hard envelopes it also specified were retired at rev 19, 2026-08-05), because sizing carries the experiment's whole risk load once price-based stop-losses are excluded. Per-strategy application detail remains in Strategy.md.]**
- Instrument scope, entry criteria, exit rules. Strategy-level.
- ~~Withdrawal methodology. Deferred until first withdrawal.~~ **DECIDED 2026-08-10** — pro-rata to NAV clamped to idle cash, two-pass after-the-fact recording. See the "Withdrawals" section above and Operating_Protocols.md §13.C.
- Any calendar-based termination. Experiment duration is bounded only by per-strategy gates (pass/fail only) and, post-gate, by the per-strategy kill triggers.
- Any ongoing post-gate re-declaration of success. Clearing a strategy's gate earns that strategy continued runway, not a permanent "successful" verdict — final determination is at strategy termination. Post-gate kill triggers (drawdown, foundation-change, and mark-to-market underperformance per the kill criteria section) continue to operate.
- Any cooling-off period between experiments or strategy restarts. Human-psychology-based; not applicable.

The separation is intentional. Strategy design and router design should be driven by edges and disadvantages documented in `AI_Trading_Foundation.md`, not shaped to satisfy experiment parameters. Experiment parameters function as external discipline, not as inputs to strategy construction.

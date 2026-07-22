# AI-Conversion Audit & Redesign — deterministic decisions → AI judgment

Status: **Redesigns A, B, and C ALL IMPLEMENTED 2026-07-19.** Owner verdict history: A
approve, B approve, C defer — relayed by the owner via their Claude-in-Chrome session and
pasted into this session by the owner; the C deferral was then REVERSED later the same day
by direct in-session owner directive ("Yes, implement it"), given immediately after the
owner asked for and read a plain-language explanation of Redesign C ("whats redesign C").
Companion to `PARK_ROUTER_DESIGN.md` v2 (the park allocator, implemented and live under
separate owner authorization). Redesign C's canonical rails live in
`Operating_Protocols.md` §19 — see §3/§4.
Method: 4-agent exhaustive catalog of every deterministic decision point (~60 entries
across Claude_Task_Plan.md, bigquery/*.sql, strategy specs, Operating_Protocols/ops),
then orchestrator classification. Full catalogs preserved in the session workspace.

## 1. The classification principle

"Fully AI-driven" applies to **decisions** — questions where market/capital judgment can
add value. It deliberately does NOT apply to four other kinds of determinism this system
runs on, each of which exists *because* it is not judgment:

1. **Safety rails & compensating controls** — the documented substitute for the human
   gates removed on 2026-07-10 (CLAUDE.md settled decision: "the compensating control is
   the graduation pipeline + the anti-churn rails + the kill-switch, NOT human review").
   Converting a rail to judgment removes the thing that justified autonomy.
2. **Frozen strategy machinery** — every live strategy's entry/exit/sizing/router rules
   are spec-frozen for its life (two-tier immutability; spec_hash CI-enforced). The only
   change channel is terminate-and-restart. Converting these in place is architecturally
   forbidden, not merely inadvisable.
3. **Deliberate independent cross-checks** — mechanisms whose value IS independence from
   AI judgment (mechanical technical router half vs AI fundamental half — "complementary
   failure modes" compensating disadvantage 2.7; golden scenarios; cross-model referee;
   dual-path max-loss; TimesFM advisory forecast). Making both sides AI collapses the
   diversity that makes the check work.
4. **Accounting/infra** — TWR math, reconciliation, retries, parity, catchup. Determinism
   here is correctness.

## 2. Disposition of the full catalog

### CONVERT to AI judgment (redesigns in §3)

| Decision | Today | Verdict |
|---|---|---|
| Park vehicle selection (sweep target) | Static `state.park_policy_current`, owner-set | **DONE — PARK_ROUTER_DESIGN.md v2** (implementing now) |
| Termination capital redistribution (D2 §5 / AR_orc): equal-split residual | FIFO newcomer floor, then equal split among survivors — "no review, no hold" | **DONE — Redesign A** (implemented 2026-07-19; `Operating_Protocols.md` §16, `Claude_Task_Plan.md` D2 §5/AR_orc, `bigquery/95_capital_allocator.sql`) |
| Deposit allocation residual (§13.C) | FIFO newcomer floor, then equal split | **DONE — Redesign A** (same call; `Operating_Protocols.md` §13.C) |
| Future strategies' internal machinery | SL2 authors numeric-trigger specs by default | **DONE — Redesign B** (implemented 2026-07-19; Claude_Task_Plan.md SL1 STEP 2 + SL2 (A) 1b, Experiment_Parameters.md authoring note) |
| Research-funnel significance thresholds (W2 ≥5% move; M2 corr ≥0.5 pairing; + D1's single-name ≥5% / sector ≥2% screens, found on inventory) | Fixed numeric screens | **DONE — Redesign C** (initially owner-DEFERRED 2026-07-19, REVERSED same day by direct in-session owner directive; implemented 2026-07-19 — `Operating_Protocols.md` §19, `Claude_Task_Plan.md` D1/W2/M2/W4/W5, `bigquery/96_research_screener.sql`; the old revisit trigger is now W5's standing rule_only-then-GO check) |

### KEEP mechanical — with the specific reason

| Group | Representative entries | Why it stays |
|---|---|---|
| Kill triggers | 50% drawdown-kill; 30-trade gate; m2m 36mo/10pp trigger; foundation-change terminate | **Owner-settled** (CLAUDE.md: "Mechanical kill triggers … are unchanged") + foundation doc 3b.3: "judgment under loss pressure is unreliable" — the one place the foundation explicitly reserves the decision FROM the AI |
| SISA anti-churn rails | n_min/n_max, k_incubate, 1-adoption/quarter, cooldowns, default-REJECT/KEEP, SL1 qualification gate, SHADOW/PAPER graduation gates, time-culls | The settled compensating control for full autonomy. The judgment half (candidate synthesis, drafting, adversarial verdicts) is already AI |
| Router technical half | SPY trend / VIX bands / yield curve / breadth + per-strategy activation rules | (a) Deliberate independent cross-check on the AI fundamental half — the divergence-review architecture requires a non-AI signal to diverge FROM; (b) frozen vocabulary ("immutable once the experiment begins") + router change-control lock |
| M1b reconciliation overrides | 4 fixed acute/stressed/hawkish overrides | Conservative-direction-only clamps ON an AI decision — exactly the rail pattern PARK v2 keeps. They never choose activation, only veto it toward safety |
| A2 constraint-relaxation lookup | PARTIAL/MATERIAL formula table, Goodhart guardrails | Anti-self-dealing governance: this table bounds how far the AI may loosen *its own* constraints. Rev 4 mechanized it specifically to remove discretion from that loop; gaps already route to an AR review with default-HOLD (judgment has a channel) |
| W5 self-tuning loop gates | readiness views for process/exec/calibration loops + auto-reverts | The objective data-sufficiency bars are what replaced human PR review (autonomy_levels: retired `no_auto_merge_self_improvement`). Judgment gates here would be autonomy justified by vibes |
| Execution safety | fn_order_guard hard rails (sizing/notional/qty sanity; park bands)¹, options guard, daily staging caps, PDT deferral, DAY-TIF, connector-sanity band, mark-discontinuity, cash tripwire, breaker tiers, entry-staging gates, OPS0 refire exclusions | Fat-finger/runaway containment. These fire in exactly the moments AI judgment is least reliable, and they bound the blast radius of every AI decision above them |
| Frozen per-strategy machinery (A–E) | entry/exit triggers, convergence/time exits, 2% sizing, B short-stop, C dual-path/80% take-profit | Two-tier immutability; spec_hash. Conversion channel exists (owner-directed override → terminate-and-restart per strategy, Rev-35 precedent) but resets every edge clock — not recommended; Redesign B achieves the goal prospectively instead |
| 2% sizing fraction | flat 2% of sleeve NAV | "Globally immutable"; the experiment's primary risk control ("a strategy with 2% sizing and 20% stops is effectively a 0.4% sizing strategy") — sizing-by-conviction is the classic AI failure mode the design excludes |
| Screens feeding AI review | retirement candidacy, runaway-success, probe-stuck, divergence trigger, KL monitors, universe liquidity floors | Already the correct division of labor: mechanical detection → AI adjudication. Converting detection to AI creates self-selected review queues |
| Cross-checks | golden scenarios, theater judge, cross-model referee, dual-path max-loss, M5 TimesFM advisory, CI parity/consistency gates | Value = independence from the reasoning model. M5 in particular is quarantined advisory by design ("kill/gate triggers fire on REALISED values, never a forecast") — do not arm it |
| Accounting/infra | TWR engine, tax lots/wash-sale detection, cash-attribution tree, catchup/retry/dep-wait, alert lifecycle, backups, split/gen scripts, .gs display constants | Determinism = correctness; none of these choose anything a market view could improve |
| Park sweep/cover floors ($25/−$5) & sizing arithmetic | §13.E | Operational friction floors (tap friction, fractional min order) — kept as rails in PARK v2; the *decision* (vehicle) is what converted |

¹ The equity %-off-last band was converted to the **AI LIMIT DECISION** on 2026-07-20 by
owner directive (see Claude_Task_Plan.md's LIMIT DECISION block; `bigquery/99_ai_limit_decision_order_guard.sql`)
— the one deliberate carve-out from this row since this table was written.

**Follow-up (2026-07-21): the LIMIT DECISION was itself superseded the very next day.** The
market-only order cutover (owner directive 2026-07-21) removed limit prices from every IBKR
order this system generates — entries, exits, park/sweep, and options are all
`order_type='MARKET'`, with no `limit_price` transmitted. With no resting limit to raise, hold,
or lower, the RAISE/HOLD/LOWER/ABANDON judgment has nothing left to decide and retires along
with the mechanism it governed; the equity 0.5%-off-last advisory retires with it. Illiquidity
is now a HARD pre-trade gate (reject the pick outright) rather than a post-craft price-chase
decision — specifically, same-day, an owner revision (SPEC v2) replaced an initial flat-dollar-
ADV/flat-spread design with an **expected-implementation-shortfall liquidity gate**
(Almgren-Thum-Hauptmann-Li 2005: half-spread + 0.142×sigma_daily×participation^0.6; a
horizon-scaled slippage budget per strategy — D 150 / A 100 / C 25 / else 50 bps; a 10%-of-ADV
metaorder cap; a $1M minimum-ADV floor; a documented ADV proxy protocol; options kept a simpler
open-interest≥500 / spread≤10% floor). See `bigquery/100_market_only_order_guard.sql`.

**Follow-up (2026-07-22): the expected-implementation-shortfall liquidity gate itself was retired
the next day, along with every other pre-trade sizing rail.** Owner directive, in one interactive
session: no buy/sell restriction due to liquidity survives — full freedom to market-buy/-sell on
thesis and market conditions regardless of current price and slippage — confirmed, when the
boundary was checked explicitly, to mean *strip everything except market-only*.
`analytics.fn_order_guard` drops the Almgren-Thum-Hauptmann-Li expected-shortfall gate and its
self-activating φ·α adaptive budget (`bigquery/103_adaptive_shortfall_budget.sql`, now retired),
the $1M minimum-ADV floor, the 10%-of-ADV participation cap, and — beyond liquidity — even the
fat-finger sizing rails: the 1.5x-sizing_base notional/max_loss cap, the $50 absolute notional
backstop, and the park 1.10x-account-NAV magnitude backstop (park orders are no longer
distinguished from any other order at all). All that remains is `order_type='MARKET'` plus
qty/ref-price sanity. `analytics.fn_order_guard_options` keeps that same market-only + sanity
floor but RETAINS the defined-risk requirement (max_loss must be a computed, positive, bounded
number) — a distinct unbounded-loss-prevention rail the owner explicitly chose to keep. The
owner's per-order IBKR confirm-tap is now the sole discretionary backstop on every order this
system generates. See `bigquery/104_strip_pretrade_rails.sql`.

Same day, the owner also authorized **partial sells** (trim/scale-out) across all strategies: the
AI may market-sell fewer shares than a position holds, not just exit it in full. No order-guard
change is needed for this — a partial sell is simply a SELL with qty less than the open position,
which the (now sizing-free) guard already passes. Reconciliation runs through a new
`events.position_events` `event_type='ADJUST'` path: the position stays `status='OPEN'` with its
share count reduced, and the fills-derived FIFO-lot/campaign accounting
(`bigquery/102_pyramid_aware_lifecycle.sql`) already resolves the resulting partial exit
correctly.

## 3. Redesigns

### Redesign A — AI Capital Allocation Call (termination + deposit residuals)

**What converts.** The residual allocation after the mechanical PENDING-NEWCOMER floor
claim — today "split equally among active survivors" — becomes an AI judgment call made
by the session already executing the event (D2 §5 or AR_orc for terminations; the §13.C
recording flow for deposits): *which strategies deserve this capital, in what
proportions, given regime fit, capacity, recent evidence, and coverage?*

**Call structure** (mirrors the park call): per-survivor allocation percentages summing
to 100%, conviction (HIGH/MEDIUM/LOW + pct), rationale addressing why the winner beats
the runner-up, invalidation criteria, theater self-check. Logged every event as
`events.decision_log` `entry_type='capital-allocation'` with the split in `fields` JSON;
lands as the same per-strategy `events.cash_flows` rows the equal-split writes today.

**Rails (mechanical, SISA-style — bound blast radius, never choose):**
- The newcomer $2,000-floor FIFO first-claim stays mechanical (it is a SISA pipeline
  rail, not an allocation opinion).
- Per-survivor bounds: each active survivor receives between **0.5× and 2× its
  equal-share** (and never $0). Deviation beyond that is a menu the AI doesn't have.
- **Default-EQUAL on ambiguity**: below MEDIUM conviction, the split is the classic
  equal split. The AI must earn the deviation.
- No new movement points: allocation happens only at the events where capital already
  moves (termination, deposit) — the `no-inter-strategy-rebalancing` doctrine
  ("rebalancing would contaminate the diagnostic signal") is untouched, and per-strategy
  deployed TWR is flow-invariant by construction, so AI-weighted splits cannot distort
  any kill/gate measurement.
- W5 records each call vs the equal-split counterfactual; Q1 retrospective reviews them.

**Not a regression to the retired design.** The 2026-06 revision retired an
adversarial-review-gated redistribution (default-HOLD, held-aside pool, added latency).
Redesign A adds none of that back: same-session, no queue, no hold pool, no default-HOLD
— the formula becomes a judgment; the event flow is unchanged.

**Staging.** Terminations are rare (zero so far), so a time-boxed shadow would gate on
events that may not occur for quarters. Given the 0.5×–2× bounds, flow-invariant
measurement, and decision-log audit, this can bind from its first event, registered in
`ops/autonomy_levels.yaml` as loop `capital_allocator` (ceiling `active_auto`) with W5
evaluation. Surface: prose edits (Claude_Task_Plan D2 §5 / AR_orc / §13.C,
Operating_Protocols §16, Experiment_Parameters pointer), one small view
(`state.capital_allocation_calls`), autonomy-loop entry. No new tables.

### Redesign B — Judgment-native strategy specs (prospective, via SL1/SL2)

**What converts.** SL1/SL2 authoring guidance today produces numeric-trigger machinery
because the founding cohort was authored that way. Add to SL1/SL2's authoring protocol:
candidate strategies MAY (and where the edge is judgment-shaped, SHOULD) define their
entry/exit machinery as **structured judgment protocols** — criteria the executing
session evaluates with stated conviction gates — rather than fixed thresholds. The
spec-freeze then freezes the *protocol text* (spec_hash works identically on prose);
the pre-mortem attacks it; SHADOW/PAPER measure its realized signal rate and excess
exactly as they do numeric specs.

**What does not change:** 2% sizing, kill triggers, 30-trade gate, graduation rails,
review types — all rails apply to judgment-native strategies unchanged. This is how the
arsenal becomes AI-native over time without touching a single frozen spec or resetting
any edge clock.

Surface: SL1/SL2 prose sections + one paragraph in Experiment_Parameters' strategy-
authoring notes. Zero schema.

### Redesign C — Research-funnel significance judgment (IMPLEMENTED 2026-07-19 — owner reversal of same-day DEFER)

**Verdict history (recorded exactly).** This audit recommended DEFER and the owner's
2026-07-19 verdict (Chrome relay) agreed. Later the same day the owner asked "whats
redesign C", read a plain-language explanation, and reversed with a direct in-session
directive: "Yes, implement it." The original defer reasoning stays visible below —
it was sound as far as it went, and the implementation answers each point rather than
ignoring it.

**What the original text proposed.** W2's "≥5% close-to-close move," M2's "correlation
≥0.5" pairing bar, and similar *significance* thresholds encode market judgment and could
become per-session AI calls ("is this move significant for this name's vol regime?") with
the liquidity/capacity floors (mkt-cap/ADV) kept as rails. Deferred because: the funnel
feeds AI judgment two steps later anyway (thesis construction, GO/NO-GO), the thresholds
bound research cost predictably, and the conversion's win is marginal while its churn is
not.

**What the 2026-07-19 implementation inventory found (and how it sharpened the design).**
(1) The two named bars are ALSO frozen strategy machinery: `strategy/04_strategy_b.md`
Entry criterion 1 independently requires the ≥5% event-day move and
`strategy/07_strategy_e.md` Entry criterion 3 independently requires corr ≥0.5 — both
spec_hash-frozen. A below-bar name/pair can never trade B/E regardless of what the funnel
says, so the honest conversion target is SURFACING/PRIORITIZATION (what earns research
attention and write-up), with the frozen numbers surviving as an explicit **spec-floor
rail** (they now derive from the frozen specs, not from a tunable screen). (2) The
"similar thresholds in W1/Q2" clause was empty — W1/Q2 carry only liquidity/scope rails;
their worthiness prose was already qualitative. (3) One unnamed screen of the same class
was found and converted: D1's sector-move ≥2% bar (no frozen constraint).

**As implemented** (canonical rails: `Operating_Protocols.md` §19; loop
`research_screener`, built directly `active_auto` per the capital_allocator staging
rationale — a screen moves research attention, never capital):
- **Two-layer structure.** Layer 1 = mechanical population rails, explicitly cost bounds
  and never significance claims (D1 single-name ≥2%, D1 sector ≥1%, W2 ≥3% over the
  unchanged 10-day window, M2 corr ≥0.3 band; +3-item sub-net escape valve). Layer 2 =
  the AI significance judgment as the sole decider of what advances, with per-item
  conviction on the house ladder. This answers the defer's research-cost point: the
  enumeration stays bounded by the nets and the unchanged result-count caps (W2 ≤15,
  M2 ≤10), while the *judgment* is no longer a number.
- **Spec-floor rail.** B/E candidacy still mechanically requires the frozen criteria;
  AI-significant sub-floor items are recorded `below_spec_floor` as context/SL1 ideation
  evidence (judgment-native new-strategy material per Redesign B), never entry candidates.
- **Record-only legacy benchmark.** Every call computes the old fixed bars mechanically
  (`legacy_rule_pass`) — the park_rule_shadow precedent — producing a standing
  agreement/disagreement ledger (`both`/`ai_only`/`rule_only`) instead of a shadow phase.
- **Read surface + evaluation.** `entry_type='research-screen'` decision_log rows →
  `state.research_screen_calls` + `analytics.research_screen_disagreements`
  (`bigquery/96_research_screener.sql`); W5's RESEARCH-SCREEN SCORECARD (record-only)
  reports the ledger weekly and flags any `rule_only` rejection that later reached a GO
  thesis — the old defer-revisit trigger ("screens rejecting winners"), converted from a
  passive hope into a standing measured check.
Surface: `Operating_Protocols.md` §19 (canonical), `Claude_Task_Plan.md` D1 items 3/4 +
routing / W2 PART 1-2 / M2 PART 1 / W4 HARD CHECK rewording / W5 scorecard bullet + table
rows, `bigquery/96_research_screener.sql` + README index, `ops/autonomy_levels.yaml`
loop entry + `check_autonomy_consistency.py` heartbeat carve-out, `Watchlist.md`
rewordings, golden scenarios RS-01..04. Zero edits to frozen specs or Strategy.md.

## 4. What Phase 2 implements now vs what awaits your verification

- **Implemented** (authorized): PARK_ROUTER_DESIGN.md v2 in full, and — per your 2026-07-19
  verdict on this document — **Redesign A** (the AI capital-allocation call, both the
  termination-redistribution and deposit-allocation residuals): `Operating_Protocols.md`
  §16/§13.C, `Claude_Task_Plan.md` D2 §5/AR_orc/W5, `bigquery/95_capital_allocator.sql`
  (`state.capital_allocation_calls`), loop `capital_allocator` in `ops/autonomy_levels.yaml`
  (built directly `active_auto`, no shadow phase — per this document's own staging
  rationale above). No held-aside pool, no review, no new movement point added — exactly
  as designed.
- **Implemented** (same 2026-07-19 verdict): **Redesign B** — judgment-native machinery
  for FUTURE candidates: `Claude_Task_Plan.md` SL1 STEP 2 (judgment-native preference) +
  SL2 (A) 1b (the four non-waivable requirements), `Experiment_Parameters.md` "Strategy
  authoring — judgment-native machinery". Prose-only, zero schema, no live strategy touched.
- **Implemented (owner reversal, same day)**: **Redesign C** — initially owner-DEFERRED
  2026-07-19 (Chrome-relay verdict), reversed later that day by direct in-session owner
  directive ("Yes, implement it") after the owner asked for and read a plain-language
  explanation. Surfaces: `Operating_Protocols.md` §19 (canonical rails),
  `Claude_Task_Plan.md` D1/W2/M2/W4/W5, `bigquery/96_research_screener.sql`
  (`state.research_screen_calls`, `analytics.research_screen_disagreements`), loop
  `research_screener` (`active_auto`) in `ops/autonomy_levels.yaml` +
  `check_autonomy_consistency.py` carve-out, `Watchlist.md` rewordings, golden scenarios
  RS-01..04. The frozen B/E entry bars survive as §19's spec-floor rail (zero frozen-spec
  edits); the old revisit trigger is now W5's standing rule_only-then-GO check.

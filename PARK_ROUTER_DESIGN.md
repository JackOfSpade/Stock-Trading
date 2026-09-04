# DESIGN PROPOSAL v2 — Active Park Management ("AI Park Allocator")

Status: **v3 — IMMEDIATE BINDING (owner directive 2026-07-26), IMPLEMENTED**. v2's shadow
burn-in, promotion gate, cadence rails (re-risk concurrence, lateral-pending, 2-per-30d
budget, 5-day cooldown), conviction binding gates, the `ops.park_control` kill-switch, and
the park-specific soft-breach re-risk block are ALL RETIRED
(`bigquery/108_park_allocator_immediate_binding.sql`; loop `park_allocator` = `active_auto`).
Every D1 park call now binds same-day — any direction, any conviction — and D2 converts it
the same evening; the only non-binding outcomes are KEEP and the connectors-down HOLD. The
owner's stated risk posture: assume the first analysis is right, accept wrong-call cost, rely
on next-session reversibility rather than confirmation delays. Triggering defect, for the
record: the v2 promotion gate was permanently latched —
`state.park_allocator_promotion_readiness` counted missing call-days since inception with no
recovery window, so the 2026-07-23/24 platform outage (2 missed days) made `ready`
unreachable forever (verified live 2026-07-26: n_call_days=5, n_missing_trading_days=2,
ready=false). The owner directive removed the gate rather than repairing it. Live surfaces:
`Operating_Protocols.md` §13.F (rewritten),
`Claude_Task_Plan.md` D1/D2/W5 steps, `ops/autonomy_levels.yaml` (`active_auto`),
`bigquery/108`. §§7/8/10 below are v2-HISTORICAL — kept as the design-rationale record of
the rails this directive removed.

**This file is now a design-rationale record, not the operative spec.** It has been edited in
place after its stated date (see the 2026-07-19 CORRECTION in §5 and the owner-approved tightening
in §7), so it is a hybrid design/changelog. **On any divergence, the operative surfaces above
govern** — notably, all three operative surfaces strengthened this doc's evidence-freedom language
to the explicit "a floor, not a ceiling" formula.

v2 supersedes v1 (same session) per owner direction: v1's deterministic regime→vehicle
rule table is **rejected as the decision-maker** — this is an AI-based trading system, and
the park allocation decision must be AI judgment, end to end. v1's rule table survives
only as a record-only shadow *benchmark* the AI is measured against (§9).

---

## 1. Summary

Every trading day, the AI makes the park allocation call the way this system already makes
its other judgment calls (M1a regime scoring, shock_overlay router-reviews, m2m reviews):
a fresh-context model session reads the live tape and decides — no thresholds, no lookup
table, no formula anywhere in the decision path. The decision is **which single instrument
from an owner-bounded menu the park holds**, chosen daily with conviction, rationale, and
invalidation criteria, logged and executed through the existing park machinery.

| Component | Choice |
|---|---|
| Decision-maker | **AI judgment, daily**: a new PARK ALLOCATION CALL produced by D1 (the daily deep-research market scan), converted to orders by D2 — the exact analysis→conversion architecture the system already runs |
| Decision scope | Full: crisis assessment, risk level, duration stance, credit stance, tax angle — all judgment. The AI picks any menu instrument for any articulable reason |
| Menu (allowlist, a rail not a decision) | CASH, SGOV, GOVT, IEF, TLT, LQD, MUB, HYG, PFF, AOR, VOO, VTI — one liquid wrapper per class the owner enumerated |
| Book structure | Single vehicle at a time (execution/accounting plumbing, not a decision constraint — §5) |
| Anti-churn | v3 (2026-07-26): NONE — every call binds same-day, any direction, any conviction. v2's cadence rails are retired; see §7 (v2-HISTORICAL). **AMENDED 2026-09-03 — no longer literally "NONE": ONE bar now exists, and only on de-risks.** A de-risk converts only when ≥2 INDEPENDENT evidence axes fire in the same session (two readings on one axis count as one); a single-axis de-risk is called as a KEEP with `fields.park_watch`, re-decided fresh next session. Re-risks and laterals are untouched, and it is not a cooldown, budget, conviction gate or approval step. Operative text: Claude_Task_Plan.md D1 PARK ALLOCATION CALL + Operating_Protocols.md §13.F. Triggered by the 09-01→09-03 VOO→SGOV→VOO round trip ($214.32, plus a wash sale: the 09-04 rebuy FILLED at the broker and disallows essentially the whole $107.73 repo-FIFO loss on the losing legs, the repo figure flipping off $0.00 when D2a records the fill; the account-level -$149.18 IBKR figure is average-cost basis and is NOT the same ruler), whose exit fired on ONE axis while its re-entry required TWO |
| Data | `events.signal_marks` layer kept from v1 — now the AI's evidence base + evaluation substrate, not a rule input |
| Accounting | Unchanged from v1: generalized multi-ticker park views, `analytics.park_nav_daily` (park TWR), vehicle-aware reconciliation |
| Kill-switch | RETIRED 2026-07-26 (owner directive: "human would never do this manually. remove this feature."). No replacement lever — owner recourse is a direct instruction, not a control table; see §8 |
| Evaluation | W5 weekly: AI's park TWR vs **three** counterfactuals — 100% SGOV, 100% VOO, and the v1 rule table running record-only in shadow |
| Rollout | None — registered directly at `active_auto` 2026-07-26 (immediate-binding redesign; the shadow/promotion machinery was permanently latched, see status block above); see §10 (v2-HISTORICAL) |

Today's tape (VIX ~15.7, market near highs, shock latent-but-building): the AI would very
likely call VOO / KEEP — adoption is a no-trade event. But unlike v1, if the AI judges the
Hormuz picture differently from what any threshold would say, **its judgment wins**.

---

## 2. Grounding (from the 5-agent read-only recon; unchanged from v1)

- Park = account-level, one vehicle at a time: `events.park_policy_changes` →
  `state.park_policy_current`; legs in `events.parking_events`; rollup/reconciliation in
  `state.park_position*` / `park_reconciliation` (`bigquery/54`). Live: VOO 13.4048 sh
  ≈ $9,152 (~97% of NAV), cash $0.63.
- D2a §13.E already executes all park trades mechanically (sweep ≥$25 / cover ≤−$5,
  `create_order_instruction` + owner confirm-tap, `analytics.fn_order_guard` — market-only + sanity, no
  park-specific parameter as of the 2026-07-22 rail strip, `bigquery/104_strip_pretrade_rails.sql`).
- No per-strategy park attribution (dissolved 2026-06-19, by design); per-strategy budgets
  are derived (`analytics.strategy_nav.available_funds`).
- The system's precedent for capital-affecting **judgment** decisions is exactly what v2
  uses: D1's daily scan → `RECOMMENDED ACTIONS` → D2 converts to orders; shock_overlay
  re-adjudicated near-daily in prose (`router-review` decision-log rows); M1a scores the
  regime monthly by model judgment with structured output; SISA adds/retires strategies by
  AI decision inside mechanical anti-churn rails, no human gate.
- Data reality: no daily VIX series exists, technical regime rows are 45 days stale, SPY
  history in `daily_marks` is deliberately thin (live kill-signal input — must not be
  deepened). Any evidence layer must be new and isolated.
- Every order passes the owner confirm-tap; DAY-TIF MARKET orders; FIFO tax lots +
  cross-strategy wash-sale watch exist; commissions characterized per vehicle only after
  real fills.

---

## 3. The decision architecture: AI in the loop it already owns

**D1 (16:00, daily deep-research market scan) gains a mandatory `## PARK ALLOCATION
CALL` section in `Daily.md`.** D1 is already the session that reads the whole tape every
trading day — developments, positions, kill-triggers, shock_overlay watch. The park call
is the natural last analytical output of that scan, not a new analysis surface:

1. **Evidence gathering (live, fresh-context, house-style "no memory recall")**: live VIX
   (FMP `^VIX`), index level and character of the tape (IBKR/FMP), trend context from
   `state.park_signal_daily` (§6), latest `hy_oas` and macro axes (`state.current_regime`
   fundamental scores, incl. `shock_overlay` and `inflation_trend`), the developments D1
   itself just scanned, anything else the session judges relevant — the AI is free to
   weigh, discount, or seek evidence beyond this list.
2. **The call** (structured, auditable):
   - `vehicle` — any menu instrument (KEEP = current vehicle)
   - `conviction` — HIGH / MEDIUM / LOW + `conviction_pct`
   - `rationale` — one paragraph; must address why *this* instrument beats the runner-up
   - `invalidation` — what observable development would flip this call (house convention)
   - `theater_check` — one-line self-audit that the rationale isn't narrating a foregone
     conclusion (echoes the AR theater-check discipline)
3. **Default-KEEP on ambiguity** — the same "high bar, default NO" posture as D1's
   existing router-review flag. Conviction gates: de-risking calls bind at MEDIUM+,
   re-risking calls at HIGH (asymmetry: cheap to be safely wrong in SGOV, expensive to be
   wrongly brave in VOO). *(v2; retired 2026-07-26 — any conviction binds. Default-KEEP
   above stays as AI-judgment discipline, not a mechanical gate.)*
4. **Logged**: `events.decision_log` `entry_type='park-allocation'` (every day, including
   KEEP days — the daily no-change record is what makes calibration and the Q1
   retrospective possible), structured readings snapshot in `fields` JSON. View
   `state.park_allocation_latest` on top.

**D2 (17:15) converts the call** exactly as it converts every other D1 action: if the
bound call is a SWITCH, D2 INSERTs the `events.park_policy_changes` row (note = the
call's rationale + readings) and the generalized §13.E converges the book (§5). No new
routine, no new trigger, no new cadence entries — the decision rides the existing
analysis→conversion rail.

**Why not a new dedicated routine**: a fresh P1 routine would buy stricter context
isolation at the cost of the full 12-step registration and a second daily deep-read of
the same tape D1 already reads. The M1a-style blinding argument is weak here — the park
call *should* see the day's developments. Rejected; revisit only if evaluation (§9) shows
contamination between strategy context and park calls.

## 4. The menu — an allowlist rail, one wrapper per owner-approved class

The owner's instruction bounds the universe ("must be one of the following"); within it
the AI chooses freely. One liquid wrapper per class keeps one-time onboarding bounded:

| Class (owner's list) | Ticker | Note |
|---|---|---|
| Cash / money market | **CASH** | Degenerate vehicle: sweeps suspended, park sits in USD. For the tail case where the AI wants zero market exposure of any kind |
| Short-term T-bills | **SGOV** | The proven original vehicle; fully characterized commissions |
| Govt bond, broad | **GOVT** | All-maturity Treasury |
| Govt bond, intermediate | **IEF** | 7–10y — the classic flight-to-quality rally asset |
| Govt bond, long | **TLT** | Lets the AI express a real duration view — a dimension v1's table couldn't have |
| IG corporate | **LQD** | |
| Municipal | **MUB** | AI weighs tax-equivalent yield at this account's bracket; expected low use |
| High-yield | **HYG** | AI may judge carry worth it in calm credit; spreads-widen-in-stress risk is its to weigh |
| Preferreds | **PFF** | |
| Balanced | **AOR** | One-ticker 60/40 — a blended risk level without a multi-leg book |
| Broad equity | **VOO**, **VTI** | Both kept: VTI doubles as the wash-sale alternate after a VOO loss-sale |

(VCIT/JNK dropped as near-duplicates of LQD/HYG.) Each ticker is onboarded **once** at
implementation: foundation-change §A checklist run, commission model bootstrap
(UNVERIFIED → characterized on first fills, existing §13 protocol), dividend
DRIP-or-cash check at first dividend (§13.C protocol), `mark_discontinuity_watch`
extension. Thereafter the AI switches among them with only a decision-log row. Park
orders are restricted to menu tickers only — **not** by an `fn_order_guard` parameter
(CORRECTION, 2026-07-19 adversarial review), but mechanically: a `SELECT COUNT(*) FROM
state.park_menu WHERE ticker = '<vehicle>'` check is the first item in D2's PARK
ALLOCATION CONVERSION checklist (Claude_Task_Plan.md) and the first step of every
park-order craft (Operating_Protocols.md §13.E) — an off-menu vehicle is HELD/blocked
there, before any order is crafted. Menu changes = numbered SQL + Operating_Protocols
edit + decision-log + foundation review.

A mechanical `risk_tier` (0 CASH/SGOV · 1 GOVT/IEF/MUB · 2 LQD/TLT · 3 HYG/PFF/AOR ·
4 VOO/VTI) is attached to each ticker — **not** used to pick vehicles. *(v3, 2026-07-26: the
cadence rails (§7) and breaker interplay (§8) that once read this direction are retired;
`risk_tier` now classifies a switch's direction only for W5 scorecard/counterfactual
evaluation — §9.)*

## 5. Book structure: single vehicle at a time (plumbing, not a decision limit)

Unchanged from v1, and deliberately: the park holds 100% of one menu instrument. This is
an execution/accounting constraint, not a constraint on judgment — every existing park
surface (policy view, sweep/cover, reconciliation, tripwire) is built around "the one
current vehicle," a $9.2k book makes multi-leg rebalancing mostly confirm-tap friction,
and AOR already gives the AI a one-ticker blend. The AI expresses *risk level* by choosing
the instrument, not by weighting legs.

Execution of a switch (2026-07-19 tightening, owner-approved: the FIRST leg moves from
§13.E to D2 itself, same evening as the flip — binds same day (v3)): the policy row flips at
decision time and D2 immediately crafts the full SELL of the vehicle the switch just
vacated in that same run — menu-membership and order-guard checked there — so the SELL
is already working at the **next** open instead of the one after. Generalized §13.E
keeps its rule — *any park-book ticker ≠ policy vehicle above dust → craft full SELL* —
as the convergence **backstop** (re-crafts the same leg if D2's DAY order expires
unfilled; still the only path for an older, pre-cutover stranded leg), and its existing
sweep re-deploys any residual cash into the policy vehicle once it lands.

**v3.1 — BOTH LEGS, SAME SESSION (owner directive 2026-07-26).** Superseding the
2026-07-19 tightening above, D2 now also crafts the **BUY** of the incoming vehicle in
that same run, sized off the **expected** net proceeds of the SELL it just crafted
rather than off settled cash (`Operating_Protocols.md` §13.E step 1, PAIRED-ROTATION
EXCEPTION). Convergence therefore completes at **ONE open**, not across ~1–2 sessions,
and the book is never parked for a session in cash — or in the vehicle the AI just
decided to leave — purely as a settlement artifact. Rationale: orders are market-only
(owner directive 2026-07-21) so a fill is near-certain, and the account is
margin-enabled, so the settlement wait bought nothing but unintended exposure. Bounded
by `buy_cost ≤ settled_cash + expected_net_proceeds(paired SELL)` — **settlement
bridging, never leverage** — with a mandatory 0.5% open-gap haircut, a
different-tickers rail (a same-ticker pair is a PDT day-trade), and a hard ordering
rule that a failed SELL guard cancels BOTH legs. §13.E is now the convergence
**backstop for both legs** (re-craft either expired leg; deploy the haircut residual),
still the only path for an older pre-cutover stranded leg. Two consequences recorded
deliberately: §13.E step 4's cover test must read `bridge_adjusted_settled_cash` or it
would sell the brand-new vehicle to "cover" the T+1 artifact and unwind the switch; and
`bigquery/93_park_accounting.sql`'s "cash ≤ $25 by construction" exclusion is knowingly
violated for one settlement cycle, so a park-TWR point inside a bridge window is not
clean (W5 must note it). `CASH` policy = §13.E sweep no-ops (cover still allowed).
Cross-ticker switch ≠ PDT day-trade pairing; both legs = two confirm-taps, typically
one sitting.

**Deferred option (owner call, §12)**: allow the AI to nominate a two-leg split (primary +
secondary, min 25% per leg, 10% drift band). Real machinery cost; recommend v2 ships
single-vehicle and this graduates later only if the AI's decision-log rationales keep
wanting it.

## 6. Evidence layer: `events.signal_marks` (kept from v1, repurposed)

Same isolated table as v1 — menu tickers + SPY + `^VIX` daily closes, ingested by D2a
STEP 1 alongside the existing pulls; SPY ~2y / VIX ~1y one-time backfill; strictly
separate from `events.daily_marks` so the spec-frozen consumers (TWR, kill flags, thin-SPY
beta input) are untouched. `state.park_signal_daily` still computes trend/drawdown/vol
context — but in v2 these are **briefing inputs the AI may weigh or override**, plus the
substrate for the three counterfactuals (§9). Nothing in the decision path consumes them
mechanically.

## 7. Anti-churn: mechanical rails around AI decisions, SISA-style

**[v2-HISTORICAL — rails retired 2026-07-26; only the connectors-down HOLD (rail 6) survives.
Kept below as the design-rationale record of what this directive removed — see the status
block and §12b.]**

The SISA precedent is the model: the AI makes every decision; rails bound only **cadence
and blast radius** (as N-floor/ceiling and cooldowns do for strategy adoption). No rail
ever chooses a vehicle:

1. **De-risk binds same day.** A MEDIUM+ conviction call to a lower risk_tier converts
   that evening (D2) — and, in that same D2 run, the outgoing vehicle's full SELL is
   crafted immediately (2026-07-19 tightening, §5), so the leg is already working the
   **next** open rather than waiting for D2a's following-day §13.E pass. Flight to
   safety is never queued, never blocked by budget.
2. **Re-risk needs next-session concurrence.** A HIGH-conviction call to a higher
   risk_tier is recorded PENDING; it binds only if the *next* trading day's D1 —
   instructed to derive its own call **before** reading the pending one (derive-then-
   compare, the golden-scenario re-evaluation discipline) — independently lands on the
   same vehicle. Two fresh-context reads of two different sessions' tape must agree
   before the book re-risks. This is the AI-native replacement for v1's "3 consecutive
   days" counter: the brake is a second independent judgment, not a threshold.
3. **Lateral moves** (same risk_tier, e.g. IEF→GOVT): bind at MEDIUM+ next session, no
   concurrence, but count against the budget. **Mechanism:** a first-proposed lateral
   call is logged `status='PENDING'`, exactly like a re-risk — but unlike a re-risk, it
   does not need an independently-matching re-derivation to bind: the NEXT session
   automatically marks it `'BOUND'`, UNLESS that next session's own freshly-derived call
   is a de-risk or names a vehicle different from the pending lateral's — either of which
   supersedes the pending lateral (it lapses, noted in that session's rationale) and the
   fresh call is what gets evaluated/logged instead.
4. **Re-risk/lateral budget**: 2 per rolling 30 days. Breach → call recorded, not
   executed, `warning` alert. De-risk exempt. **Allocator-epoch exemption:** the budget/
   cooldown count only `events.park_policy_changes` switches from the first-ever
   `entry_type='park-allocation'` `events.decision_log` row forward — the manual
   2026-07-15 SGOV→VOO cutover predates the AI allocator and does not consume its budget.
5. **Cooldown**: no re-risk within 5 trading days of a de-risk execution.
6. **Connectors down / cannot gather evidence**: no call binds; HOLD + `warning`
   (`park_router` category, auto-resolvable). The AI decides with evidence or not at all.

If the owner wants pure unconstrained AI (rails 2–5 removed), the design degrades
gracefully — each rail is a separate clause. Recommendation: keep them; every autonomous
loop in this system pairs AI judgment with anti-churn rails, and each park switch is a
full-book taxable round trip.

## 8. Safety rails, kill-switch, breaker interplay (unchanged from v1 in substance)

**[v2-HISTORICAL — the `ops.park_control` kill-switch bullet and the soft-breach re-risk
block below are retired 2026-07-26 (owner directive). The foundation-change-review and
wash-sale-monitoring bullets remain OPERATIVE, unchanged.]**

- **`ops.park_control`** (append-only, latest-wins, seeded open): `enabled BOOL`
  (FALSE = allocator records-only; sweeps continue on current vehicle),
  `forced_vehicle STRING` (owner pins; AI records disagreement daily), `reason`,
  `set_by` → `state.park_control_latest` → `ops.sp_assert_park_router_enabled`.
- **Drawdown breaker**: de-risk switches are risk-reducing — allowed during soft breach
  (`entry_staging_allowed=FALSE`, alongside exits/park-cover); re-risk switches blocked
  during soft breach; hard halt blocks everything.
- **Foundation-change amendment**: §A checklist runs once per menu ticker at onboarding;
  menu-internal switches thereafter need only their decision-log row; only menu *changes*
  re-trigger the full checklist.
- **Wash sales**: **CORRECTED (2026-08-18, interactive-session probe) — this bullet was
  FALSE from onboarding (2026-07-19) through 2026-08-17.** `state.wash_sale_exposure`
  (`bigquery/41_tax_lots.sql`/`50_short_sale_tax_lots.sql`) is built from
  `state.trade_fills_curated` → `events.trade_fills`, which holds ONLY strategy-tagged
  fills; every park fill lands in `events.parking_events` instead, a separate table with
  no `realized_pnl`/lot-basis concept — so park round trips (the 2026-07-27 VOO exit /
  2026-08-04 re-entry included) were structurally invisible to "the extended wash-sale
  watch," and W5's weekly `wash-sale-review` log entries reported zero park exposure every
  cycle regardless of the real underlying loss (`events.decision_log`, verified). Nor is
  the AI actually told any lot situation in its PARK ALLOCATION CALL briefing —
  `Claude_Task_Plan.md`'s evidence-gathering list for that call has never enumerated
  `state.wash_sale_exposure` or any park lot table (the evidence-floor discipline means the
  AI *could* look it up unprompted, but nothing surfaces it, and no session is known to
  have). Mitigating: IBKR's own 1099-B computes wash sales at broker/CUSIP level across the
  whole account regardless of what this repo tracks, so the owner's actual tax liability
  was never at risk — only this repo's advance-visibility reporting was blind.
  `bigquery/178_park_wash_sale_exposure.sql` extends `state.wash_sale_exposure` (same
  output shape, no reader change needed) to cover park round trips via a new
  `analytics.park_tax_lots` FIFO view over `events.parking_events` — written this session,
  **not yet applied live** (operator applies via the BigQuery MCP/console per this repo's
  standard practice). The "AI is told the lot situation" / "may choose VTI over VOO"
  judgment-call framing remains v2's INTENDED design, not its current implementation —
  wiring `state.wash_sale_exposure` into the PARK ALLOCATION CALL's evidence list, if
  wanted, is a separate, not-yet-done change to `Claude_Task_Plan.md`.
- **Alerts**: `park_router` warning categories (stale evidence HOLD, budget breach,
  concurrence miss), existing critical tripwire categories for reconciliation breaks.
  Emailer needs zero changes.

## 9. Accounting & evaluation

Accounting is v1's, unchanged: generalized multi-ticker `park_position_current` /
`park_reconciliation` (superseded-markers into 54), **`analytics.park_nav_daily`** (daily
park MV, instrument-only — unswept cash is deliberately excluded, ≤$25 by construction
per §13.E's sweep/cover floor — vehicle label, chained park TWR — the fluctuation-proof
record of "current allocation"), vehicle-aware `account_reconciliation` (makes today's
~$50 park-unrealized fuzz explicit), `park_baseline` frozen, weekly email park section.

Evaluation is where v2 earns its keep — **the AI is benchmarked against three record-only
counterfactuals** from feature inception (all computable from `signal_marks`):

1. 100% SGOV (never left the old world)
2. 100% VOO (the current static policy)
3. **The v1 deterministic rule table**, running as `state.park_rule_shadow` — a daily
   mechanical classification that never trades. If AI judgment can't beat a lookup table,
   the owner should know.

W5 weekly: park TWR vs all three, conviction calibration (conviction_pct vs realized
next-20-day outcome, feeding the house calibration concept). *(v3, 2026-07-26: switch/budget
usage and concurrence-outcome metrics dropped — those rails no longer exist.)*
Q1 quarterly: park-allocation retrospective bullet — hindsight review of every switch and
notable KEEP, theater/bias check on rationales, alongside the existing regime retro.

## 10. Autonomy staging & rollout

**[v2-HISTORICAL — shadow/promotion machinery retired 2026-07-26. The loop is registered
directly at `active_auto`; see the status block and §12b.]**

`ops/autonomy_levels.yaml` loop `park_allocator` (ceiling `active_auto`), starting
`shadow` per house precedent, with mechanical self-promotion (no owner gate, SISA
posture):

- **Phase 0**: apply SQL; backfill `signal_marks`; onboard all 12 menu tickers
  (foundation §A runs, contract_ids resolved and cached); golden-scenario fixtures
  (crisis call → binds same day; low-conviction ambiguity → KEEP; connectors-down →
  HOLD; re-risk without concurrence → stays PENDING).
- **Phase 1 (shadow, 10 trading days)**: D1 makes the full call daily; logged, no orders.
  `state.park_allocator_promotion_readiness`: ≥10 sessions with a well-formed call, 0
  missing-call trading days, would-be churn within budget.
- **Phase 2**: W5's PROMOTION CHECK flips the loop to `active_auto` (decision-log + info
  alert). Calls start binding; §13.E converges the book on the first switch.
- Owner recourse: `ops.park_control` freeze/pin any time; confirm-tap on every order.

Cadence note: this remains an EOD system by design — the AI decides once per trading day
at 16:00 and orders work the next session. No intraday path exists anywhere in the stack,
and none is added.

## 11. Rejected alternatives (do not re-propose without new evidence)

- **v1's deterministic regime→vehicle rule table as decision-maker** — owner-rejected
  2026-07-18; retained only as shadow benchmark #3.
- **Weighted multi-vehicle park** — deferred option (§5), not v2. Rebuilds park machinery
  and multiplies taps at $9.2k scale; AOR covers the blend.
- **A dedicated new routine (P1)** — D1→D2 already is the daily judgment→conversion rail;
  full 12-step registration buys only context isolation with no current evidence of need.
- **Full AR_att/AR_orc adversarial review per switch** — 2-day latency contradicts the
  crash use-case; the concurrence rail (§7.2) + Q1 retrospective + theater self-check
  carry the adversarial burden at this decision's tempo.
- **Reusing `state.current_regime` technicals / writing park state into
  `events.regime_events` / deepening SPY in `daily_marks`** — staleness, scope pollution,
  live-signal perturbation respectively (unchanged from v1).
- **Human approval gate on switches** — contra the 2026-07-10 SISA directive.

## 12. Change inventory

| Surface | Change |
|---|---|
| `bigquery/91_park_signal_layer.sql` | `events.signal_marks` + curated view; `state.park_signal_daily`; backfill template |
| `bigquery/92_park_allocator.sql` | Menu + risk_tier reference; `state.park_allocation_latest`, PENDING/concurrence state, budget/cooldown views; `ops.park_control` + view + assert proc; `state.park_rule_shadow` (v1 table, record-only); `state.park_allocator_promotion_readiness`; generalized `park_position_current`/`park_reconciliation` (markers into 54); `mark_discontinuity_watch` menu extension (marker into 82) |
| `bigquery/93_park_accounting.sql` | `analytics.park_nav_daily`, `analytics.park_counterfactuals` (SGOV / VOO / rule-shadow); vehicle-aware `account_reconciliation` (marker into 22); freeze `park_baseline` (marker into 21) |
| `Operating_Protocols.md` §13 | §13.F AI allocation protocol (call structure, conviction gates, rails); §13.E generalization; menu + onboarding doc |
| `Claude_Task_Plan.md` | D1: `## PARK ALLOCATION CALL` step + Daily.md section spec; D2: conversion clause; D2a: STEP 1 signal ingest; W5: scorecard + promotion-check bullets; inventory-table `writes` cells |
| `ops/cadence.yaml` | D1/D2/D2a/W5 `writes:` lists |
| `ops/autonomy_levels.yaml` | `park_allocator` loop (shadow → active_auto) + heartbeat |
| `ops/foundation_change_review.md` | Onboard-once amendment; menu changes trigger full checklist |
| `dbt/` | Mirrors for changed analytics views |
| `tests/golden_scenarios/` | 4 park-allocator fixtures (§10) |
| `ops/weekly_report/weekly_report.gs` | Park section (version bump, pinned-SHA redeploy) |
| One-time | signal_marks backfill; 12-ticker onboarding (foundation §A, contract_id cache, commission/dividend bootstrap) |

## 12b. v3 change inventory (2026-07-26)

Immediate-binding redesign (owner directive 2026-07-26) — what changed on top of the v2 build
above. See the status block for the one-line story and the triggering defect.

| Surface | Change |
|---|---|
| `bigquery/108_park_allocator_immediate_binding.sql` (new) | 4 DROPs: `state.park_allocator_promotion_readiness`, `state.park_switch_budget`, `state.park_control_latest`, `ops.park_control`; superseded/retired markers added to `bigquery/92`'s affected sections |
| `bigquery/75_scheduled_query_wrappers.sql` + `bigquery/63_scheduled_query_version_registry.sql` | `sp_sq_cadence_check` v7→v8: `loop:park_allocator` added to the active_auto required-heartbeat lists + a dedicated 3-trading-day daily-heartbeat staleness check |
| `Operating_Protocols.md` §13.F | Rewritten: rails/conviction-gates/`ops.park_control` clauses removed; menu, connectors-down HOLD, default-KEEP discipline, daily logging, W5/Q1 evaluation text kept; `BOUND`/`HOLD` status vocabulary |
| `Claude_Task_Plan.md` | D1: emits `status='BOUND'` directly, no pending-read; D2: conversion strips `park_control`/budget/cooldown/concurrence/`entry_staging_allowed` reads; W5: PROMOTION CHECK bullet removed, scorecard stays |
| `ops/autonomy_levels.yaml` | `park_allocator` loop: `stage: shadow` → `active_auto`; `gate_to_next_stage` becomes terminal "authorized at ceiling" prose with compensating controls |
| `tests/golden_scenarios/scenarios.yaml` | PA-1/PA-2/PA-3 rationale reframed (no rails/budget/cadence-numbering assumptions); PA-4 flips to `GO (status='BOUND')` — re-risk now converts same day, no concurrence |

## 13. Open questions for the owner

1. **Menu breadth**: all 12 tickers incl. CASH as proposed — or trim (e.g. drop
   MUB/PFF)? Each is one-time onboarding cost only.
2. **RESOLVED by owner directive 2026-07-26.** *Cadence rails* (§7.2–7.5: re-risk
   concurrence, budget, cooldown): removed entirely — fully unconstrained AI, not the
   "keep them" recommendation this doc originally made.
3. **RESOLVED by owner directive 2026-07-26.** *Conviction gates* (MEDIUM+ to de-risk,
   HIGH to re-risk): removed — any-conviction calls bind.
4. **Two-leg splits** (§5): defer (recommended) or include in v2? — still open.
5. **RESOLVED by owner directive 2026-07-26.** *Shadow length*: moot — the shadow phase
   itself is abolished; the loop registered directly at `active_auto` (no burn-in, no
   auto-promotion mechanics).

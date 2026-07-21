# DESIGN PROPOSAL v2 — Active Park Management ("AI Park Allocator")

Status: **IMPLEMENTED 2026-07-19** (header corrected 2026-07-20 — it read "DESIGN ONLY — not
implemented" long after the build landed, and a future audit could wrongly dismiss this file as
unbuilt intent). Live surfaces: `Operating_Protocols.md` §13.F, `bigquery/91_park_signal_layer.sql`
/ `92_park_allocator.sql` / `93`, the PARK ALLOCATION CALL step in `Claude_Task_Plan.md` +
`task_plan/D1.md`, and the PARK ALLOCATION CONVERSION step in D2. Loop `park_allocator` is at
autonomy stage `shadow` (calls logged `RECORD_ONLY`, no conversion) — that is a staging gate on
the *decision*, not evidence the design is unbuilt. Originally raised for owner review 2026-07-18.

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
| Anti-churn | Mechanical *cadence* rails around the AI's decisions (de-risk binds same day; re-risk needs next-session concurrence), SISA-style — §7 |
| Data | `events.signal_marks` layer kept from v1 — now the AI's evidence base + evaluation substrate, not a rule input |
| Accounting | Unchanged from v1: generalized multi-ticker park views, `analytics.park_nav_daily` (park TWR), vehicle-aware reconciliation |
| Kill-switch | `ops.park_control` (freeze / pin a vehicle), house append-only pattern |
| Evaluation | W5 weekly: AI's park TWR vs **three** counterfactuals — 100% SGOV, 100% VOO, and the v1 rule table running record-only in shadow |
| Rollout | 10-trading-day shadow (AI calls logged, no orders) → mechanical auto-promotion via W5 |

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
  `create_order_instruction` + owner confirm-tap, `fn_order_guard(p_is_park=TRUE)`).
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
   wrongly brave in VOO).
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
4 VOO/VTI) is attached to each ticker — **not** used to pick vehicles, only to classify a
switch's *direction* (de-risk vs re-risk) for the cadence rails (§7) and breaker
interplay (§8).

## 5. Book structure: single vehicle at a time (plumbing, not a decision limit)

Unchanged from v1, and deliberately: the park holds 100% of one menu instrument. This is
an execution/accounting constraint, not a constraint on judgment — every existing park
surface (policy view, sweep/cover, reconciliation, tripwire) is built around "the one
current vehicle," a $9.2k book makes multi-leg rebalancing mostly confirm-tap friction,
and AOR already gives the AI a one-ticker blend. The AI expresses *risk level* by choosing
the instrument, not by weighting legs.

Execution of a switch (2026-07-19 tightening, owner-approved: the FIRST leg moves from
§13.E to D2 itself, same evening as the flip — see §7 rail 1): the policy row flips at
decision time and D2 immediately crafts the full SELL of the vehicle the switch just
vacated in that same run — menu-membership and order-guard checked there — so the SELL
is already working at the **next** open instead of the one after. Generalized §13.E
keeps its rule — *any park-book ticker ≠ policy vehicle above dust → craft full SELL* —
as the convergence **backstop** (re-crafts the same leg if D2's DAY order expires
unfilled; still the only path for an older, pre-cutover stranded leg), and its existing
sweep re-deploys settled proceeds into the policy vehicle once they land — the BUY side
is untouched by this tightening, still exclusively §13.E-owned. Convergence to full
redeployment now runs in **~1–2 sessions** (one session tighter than before this
change) using only existing staged-order persistence, re-craft-on-expiry, fill
reconciliation, and tripwire machinery — no new mechanism, just an earlier trigger for
the first leg. `CASH` policy = §13.E sweep no-ops (cover still allowed). Cross-ticker
switch ≠ PDT day-trade pairing; both legs = two confirm-taps, typically one sitting.

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
- **Wash sales**: monitored via the extended wash-sale watch; the AI is told the lot
  situation in its briefing and may choose VTI over VOO after a recent VOO loss-sale —
  a judgment call in v2, not a hardcoded substitution.
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

W5 weekly: park TWR vs all three, switch/budget usage, concurrence outcomes (how often a
pending re-risk died on day 2 — the whipsaw brake's hit rate), conviction calibration
(conviction_pct vs realized next-20-day outcome, feeding the house calibration concept).
Q1 quarterly: park-allocation retrospective bullet — hindsight review of every switch and
notable KEEP, theater/bias check on rationales, alongside the existing regime retro.

## 10. Autonomy staging & rollout

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

## 13. Open questions for the owner

1. **Menu breadth**: all 12 tickers incl. CASH as proposed — or trim (e.g. drop
   MUB/PFF)? Each is one-time onboarding cost only.
2. **Cadence rails** (§7.2–7.5: re-risk concurrence, budget, cooldown): keep as proposed
   (recommended — SISA-style rails around AI judgment), or remove for fully
   unconstrained AI?
3. **Conviction gates** (MEDIUM+ to de-risk, HIGH to re-risk): keep, or let any-conviction
   calls bind?
4. **Two-leg splits** (§5): defer (recommended) or include in v2?
5. **Shadow length**: 10 trading days then mechanical auto-promote (recommended)?

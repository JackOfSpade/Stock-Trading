<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Strategy C: Defined-risk options structures around known events

### Thesis

AI's narrative synthesis (edge 1.1, which uses cross-report contradiction surfacing 1.4 as one synthesis technique rather than as a separately-load-bearing edge — rev 21 per pre-mortem cycle 4 T1.C) can identify earnings releases, FDA PDUFA decisions, and FOMC meetings where Claude's directional view has meaningful divergence from the options market's pricing of the event. Defined-risk structures cap maximum loss at a pre-committed premium, eliminating reliance on AI judgment under loss pressure (compensating 2.18). Event-dated options concentrate the thesis into a known resolution window, which matches Claude's analytical cycle (compensating 2.1 execution latency within tolerable bounds).

### Instrument eligibility rule

Any defined-risk options structure around a qualifying event, where:

- Maximum loss at expiration is deterministically computable at entry from strike prices and net debit/credit (no reliance on assumptions about future volatility)
- Maximum loss including early-assignment cascade scenarios is also deterministically computable at entry (rev 19 addition per Strategy C pre-mortem cycle 2 T1.2/T1.4, rev 20 conventions pinned per cycle 3 T1.β): for any structure with one or more short legs (debit spreads, credit spreads, iron condors, butterflies), classical-method delegation must compute the worst-case loss assuming the short leg is assigned at any point pre-expiration, the long leg is held to its expiration, and the resulting equity exposure is marked-to-market at the worst plausible adverse move. Three conventions pinned (rev 20):
  - Mark-to-market reference point: at the assignment instant (not at long-leg expiration; not as a worst-case envelope across the holding window). The bound assumes the operator/code processes the assignment cascade by closing the resulting equity position immediately at the worst-plausible-adverse mark.
  - Implied-move horizon for the 2× scaling: the full structure expiration horizon (i.e., 2× the at-entry implied-move computed for the underlying through the structure's expiration). This is conservative — it scales the adverse-move assumption by the full structure horizon even though assignment may occur earlier, when the time-scaled implied-move would be smaller.
  - Multi-expiration variants (calendars, diagonals, and any structure with two or more distinct expirations across legs) are excluded from eligibility (rev 20 per cycle 3 T1.β). These structures have more complex assignment scenarios that the cascade rule's "long leg held to expiration" assumption does not cleanly handle.
  This bounded-early-assignment-loss quantity must also be ≤ **the thesis's stated risk budget (Rev 43, owner directive, 2026-07-28 — formerly a flat 2% of strategy portfolio)**. Long-options-only structures (long calls, long puts) trivially satisfy this with the same max-loss as the no-early-assignment case.
- Total capital at risk for the structure is ≤ ~~2% of C's strategy portfolio value at entry~~ **the AI-chosen risk budget for this thesis (Rev 43, owner directive, 2026-07-28)**, considering both the standard max-loss and the bounded-early-assignment-loss. C's Capital at Risk is **exact, not assumed** — it is `max_loss` inclusive of the early-assignment cascade, dual-path verified — which per `Experiment_Parameters.md` §Position size factor 3 supports a larger budget than open-ended equity downside at equal conviction. The budget is justified in the decision-log entry and adversarially attacked on size; it is bounded by the per-name (≤10% CaR) and per-strategy-deployed (≤75% CaR) envelopes. The retained options order-guard rail enforces `max_loss ≤ stated budget` at craft time.
- Structure expiration is within 1-45 days of entry
- A qualifying event is scheduled strictly before expiration
- Long calls, long puts, debit spreads, credit spreads, iron condors, butterflies, and their single-expiration variants are all permitted if they meet the maximum-loss and sizing constraints. Multi-expiration variants (calendars, diagonals, double calendars, and any structure with two or more distinct expirations across legs) are excluded (rev 20 per cycle 3 T1.β; see cascade-computation conventions above for rationale).

**Qualifying events:**

- Corporate earnings releases (US-listed companies, confirmed date from company IR)
- FDA PDUFA dates (confirmed from FDA calendar or company disclosure)
- FOMC meetings (confirmed Fed calendar)

Other event types (analyst days, product launches, conference presentations, M&A-related, legal rulings, index rebalances) are excluded at the strategy level. Rationale: these have weaker narrative predictability, less standardized disclosure, or both.

**Deferral behavior:** If no structure satisfying the eligibility rule can be constructed for a thesis at current strategy portfolio size, the thesis is deferred. C's strategy portfolio ~~remains in SGOV~~ **remains parked [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13**. As the portfolio grows (via deposits and realized profits), eligibility progressively expands without requiring any rule change. Deferred theses are not logged as missed opportunities for diagnostic purposes.

### Entry criteria

All criteria must be met:

1. A qualifying event is scheduled within 45 days
2. Claude produces a directional thesis (bullish, bearish, or volatility-directional) synthesized from: last 4 earnings call transcripts, last 10-Q and 10-K filings, recent sell-side report synthesis (retrieved, not recalled), sector peer context. **Sell-side handling clause (rev 19 addition per Strategy C pre-mortem cycle 2 T1.7/T1.8):** retrieved sell-side reports may be summarized and used as a public-information input, but theses depending on private-information-class signals (specific channel-check claims, KOL conversation references, management non-public guidance) are inadmissible even when those signals appear in retrieved sell-side reports as analyst-laundered content. The thesis must be reconstructible from primary public sources (filings, transcripts, official disclosures) without reliance on the sell-side analyst's private-information-derived conclusions; sell-side may inform structure but cannot be the load-bearing rationale.
3. Adversarial counter-argument is produced in the same session before entry; no decisive flaw is identified
4. Classical-method delegation (see below) produces: max loss ≤ **the thesis's stated risk budget (Rev 39; formerly a flat 2% of strategy portfolio)** (including bounded early-assignment cascade scenarios per the eligibility rule), explicit breakeven(s), and P&L at a minimum of 5 outcome scenarios (strike + 10%, strike + 5%, strike, strike − 5%, strike − 10% for equity events; analogous for rate events). **Dual-path verification clause (rev 19 addition per Strategy C pre-mortem cycle 2 T1.3):** max-loss verification must be performed by two independent code paths — closed-form formula computation AND Monte Carlo P&L scenario simulation across the structure's expiration grid — and both must agree to within $1 per structure before entry is permitted. Disagreement between the two paths defers the thesis. This is the flowing limitation for Constraint 3 (2.12 code-execution dependence) per the pre-mortem.
5. Entry is at least 1 trading day before the event (no same-day-of-event entries — avoids intraday-only thesis windows per 2.2)

### Exit rules and thesis invalidation

**Default: hold to expiration.** The defined-risk structure is the stop; no price-based intervention.

**Exit early if any of:**

- Event occurs earlier than scheduled and thesis has resolved (positive or negative)
- Pre-event public news invalidates the thesis (e.g., FDA advisory panel vote opposite to expected PDUFA direction, company pre-announces earnings, FOMC inter-meeting action)
- Position reaches ≥ 80% of max profit before expiration (take profit — reduces pin-risk exposure; computed by code)

**Not exit-triggering:**

- Adverse price movement in the underlying with no thesis-invalidating news
- General market moves
- Time decay (theta is priced in at entry; exiting on expected theta is paying the premium twice)

### Partial exits (trim / scale-out)

For a multi-contract structure, the AI may scale out partially — a market order selling some but not all of the position's contracts — on judgment, rather than only closing the full structure (Rev 41, owner directive, 2026-07-22). The remaining contracts continue to run under the structure's original defined-risk terms through to expiration (or an early exit trigger above); max_loss simply recomputes over the reduced contract count. A single 1-contract structure has no partial form and is closed as a unit, as before.

### Declared expected frequency (over active periods only)

Two declarations corresponding to two router states (rev 22 split per Strategy C pre-mortem cycle 5 T1.γ):

- *Under current HYBRID-FOMC routing:* 0-8 trades per year. Floor 0 reflects deferral-driven realized frequency at small portfolio sizes; ceiling 8 reflects FOMC-meeting-count cap.
- *Under full-eligibility router state (post scope-widening per Strategy C pre-mortem KL #12 gate):* 8-15 trades per year. Earnings seasons (4 per year) provide most trades; FDA PDUFA dates and FOMC meetings (8 per year) supplement. Realized frequency is sensitive to strategy portfolio size — at small sizes, many theses defer because no eligible structure fits the thesis's risk budget (**[Rev 43]** formerly a flat 2% sizing constraint — thesis-scaled budgeting materially *reduces* this deferral rate at small portfolio sizes, since a high-conviction thesis may now be budgeted above the old flat 2% and clear a structure that 2% could not); as the portfolio grows, deferral rate falls further and realized frequency climbs within this range.

### Classical-method delegation (all numerical work goes to code per 2.11 and 2.12)

All of the following calculations are executed by code, not by Claude's reasoning:

- All Greek computations (delta, gamma, theta, vega, rho) for every leg and the net structure
- Breakeven calculation for every structure variant
- P&L at any specified underlying price and date (implemented via Black-Scholes or equivalent)
- Maximum loss verification at every strike/expiration boundary (rev 19 per cycle 2 T1.3: must be performed by two independent code paths — closed-form formula AND Monte Carlo P&L simulation — and both must agree to within $1 per structure)
- Maximum loss including early-assignment cascade scenarios per the eligibility rule (rev 19 per cycle 2 T1.2/T1.4)
- Position sizing arithmetic (**[Rev 43] the thesis's stated risk budget** as a fraction of current strategy portfolio, converted to contract count; formerly a flat 2%)
- Implied volatility at entry and comparison to realized volatility over the trailing 30 days
- Probability-weighted payoff at entry using market-implied risk-neutral distribution (with the explicit caveat that these probabilities are price-derived, not Claude-forecasted, per 2.13)

Claude's role is to produce the directional thesis and select the structure type; all quantitative work that could commit a numerical error is delegated.

### Router activation rule

**Technical:** SPY Trend State ≠ DOWN (i.e., UP or NEUTRAL)

Rationale: In DOWN regimes, individual-stock event reactions are dominated by macro-driven selling cascades; event-specific theses get drowned out by beta. The router deactivates C rather than forcing C's pre-mortem to anticipate this case.

**Fundamental question (monthly template answers):** Is the event-trading environment functional, or is the current regime dominated by macro shocks that override individual-catalyst dynamics?

---


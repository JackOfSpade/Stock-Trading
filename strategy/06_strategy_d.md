<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Strategy D: Long-horizon narrative-screened equity core

### Thesis

AI's cross-document synthesis (1.1, 1.4) and cross-disciplinary integration (1.10) identifies a small number of high-conviction equity names where the case for 12+ month holding rests on structural factors that take 1–3 years to play out. D is deliberately concentrated — 5–10 positions when fully deployed — because the synthesis edge is in identifying specific names worth committing to, not in producing diversified factor exposures (which an index fund provides at lower cost). Compensates 2.23 (tax and fee drag) through LTCG-optimized holding periods.

**Permitted thesis subtypes (rev 28 added per pre-mortem cycle 3 T1-β).** D's universe consists of two explicit thesis structures, each with its own form of binding-constraint flowing limitations. The subtypes are mutually exclusive at thesis-formation time — each entry is filed under one or the other.

- **Subtype A — Future-dated catalyst theses.** Thesis primary driver is a future-dated event with a publicly-known scheduled date that has not yet occurred at thesis-formation time. Examples: FDA decision date 2027-Q3 for a specific drug application; regulatory deadline 2026-12-31 for compliance regime; scheduled product launch with announced public timeline; contractual milestone from disclosed agreements; scheduled corporate action (spin-off, reverse merger). *Invalidation criteria* must be public-information-observable: financial metric breach, regulatory milestone missed, contractual obligation failure, or publicly-disclosed corporate action.

- **Subtype B — Trend-continuation theses anchored to quantifiable current trend metrics (rev 28 added).** Thesis primary driver is continuation of a quantifiable current trend metric for ≥ 12 months. The trend itself must be quantifiable (e.g., "AAPL services revenue compounds at ≥ 18% YoY for next 4 quarters"; "NVDA datacenter revenue grows ≥ 50% YoY for next 4 quarters"; "COST membership renewal rate stays ≥ 90% with member count growth ≥ 5% YoY"; "BRK.B operating earnings grow ≥ 7% over 24 months"). *Invalidation criteria* must be quantitative thresholds on the trend metric: e.g., "growth rate falls below 15% YoY for 2 consecutive quarters" = invalidation. The trend metric IS the test, not analogical reasoning to historical comparable cases — this addresses 2.19 manifestation (a) (narrative pattern-matching) by structurally requiring forward-anchored verification rather than backward analogical reasoning. **Metric-immutability auto-invalidation rule (rev 30 added per pre-mortem cycle 4 T1-3):** if the underlying reportable category undergoes a structural change such that the metric specified at thesis-formation is no longer reported in its original form for ≥ 2 consecutive quarters, the thesis auto-invalidates as of the date the second non-conforming quarterly report is released. Structural change includes: (a) the metric is no longer disclosed at all, (b) the metric is rolled into a different aggregate that doesn't permit isolating the original quantity, (c) the metric's definition changes such that the at-entry threshold is no longer comparable to the post-change disclosure. Auto-invalidation is mechanism-enforced via classical-method delegation comparing reported categories at quarter-end to those documented at thesis-formation.

Both subtypes maintain the no-qualitative-only invalidation discipline that Constraint 3 (Section 5) was designed to enforce. Both address 2.19 manifestation (a) by requiring forward-anchored thesis structure rather than analogical reasoning. The rev 27 framing was Subtype A only, which excluded legitimate trend-continuation theses (AAPL services, NVDA hyperscaler, COST flywheel, V/MA payments, BRK.B compounder); cycle 3 T1-β surfaced this as a strategy-declaration-vs-operating-universe mismatch. Rev 28 expanded to both subtypes while preserving the no-qualitative-only discipline.

**Typing rule for dual-signal theses (rev 30 added per pre-mortem cycle 4 T1-1).** When a thesis exhibits both a future-dated catalyst (Subtype A signal) AND a quantifiable trend metric (Subtype B signal), the typing decision is mechanism-enforced via date arithmetic against the resolution timing:
- Subtype A only: catalyst present, no quantifiable trend metric articulated.
- Subtype B only: trend metric articulated, no future-dated catalyst with publicly-known scheduled date.
- Subtype A required for dual-signal: catalyst's scheduled resolution date is ≤ 12 months from thesis-formation. Catalyst resolves before the trend metric's 12-month forward-verification window completes; Subtype A's invalidation menu is the more time-relevant test.
- Subtype B required for dual-signal: catalyst's scheduled resolution date is > 12 months from thesis-formation. Trend metric's 12-month forward-verification completes before catalyst resolves; Subtype B's invalidation menu is the more time-relevant test.
- Both subtypes simultaneously required: catalyst date falls within 12-month forward-verification window AND trend metric's threshold can be evaluated independently of catalyst resolution. Invalidation is the union of Subtype A and Subtype B invalidation menus.

The typing rule is mechanism-enforced via date comparison, not participant adjudication. Pre-mortem cycle 4 T1-1 surfaced that rev 28's subtype framing left primary-driver / typing determination unspecified for dual-signal theses, reintroducing the cycle 2 defendant-as-judge pattern at the typing stage. Rev 30 closes this with mechanism-enforced date arithmetic.

### Concentration as a design decision

D holds 5–10 positions when fully deployed. Rationale: a 20+ name "diversified narrative core" is structurally indistinguishable from a narrative-tilted equity index, and any AI-synthesis edge is diluted toward index beta. A 5-position concentrated book commits to specific thesis bets where the synthesis edge earns its keep. The capital-preservation cost of concentration is bounded by 2% per position (drawdown of any single name ≤ 2% of strategy portfolio at entry, less with compounding losses) and by the concurrent-position floor (minimum 5 when any are held).

### Instrument eligibility rule

- US-listed common equity (ADRs acceptable for large-cap foreign-domiciled companies)
- Market cap ≥ $10B at entry (higher threshold than A/B because D's multi-year horizons expose it to more business-risk drift in smaller names)
- 30-day average daily volume ≥ $20M
- Position size: 2% of strategy portfolio at entry
- Concurrent position count: minimum 5 (floor retained); ~~maximum 10 (hard cap)~~ **maximum REMOVED (Rev 35, owner directive)** — no holdings-count ceiling (the 2%-per-position size cap and the 30%-of-NAV sector exposure cap remain the deployment bounds)
- Long-only

**Deployment posture:** At 2% per position, D's deployment is bounded by the 2%-per-position size cap and the 30%-of-NAV sector exposure cap rather than a position-count ceiling — the former "max 10 positions → at most 20%" ceiling is **removed (Rev 35, owner directive)**, the minimum-5 floor retained; ~~the remainder is SGOV-parked. This is intentional. SGOV parking during active periods reflects the scarcity of genuine long-horizon conviction, not an execution problem. D's deployed TWR is measured on deployed capital only (per `Experiment_Parameters.md`), so SGOV parking does not dilute the strategy's measured edge.~~ **the remainder is parked [Rev 38, owner directive, 2026-07-15] — SGOV historically, VOO from the 2026-07-15 cutover forward; see Operating_Protocols.md §13. This is intentional: parking during active periods reflects the scarcity of genuine long-horizon conviction, not an execution problem. D's deployed TWR is measured on deployed capital only (per `Experiment_Parameters.md`), so idle-capital parking does not dilute the strategy's measured edge.**

### Entry criteria

1. Structural thesis articulated with 12+ month expected realization timeline. (rev 28 reframed per pre-mortem cycle 3 T1-β.) Thesis is filed under one of two permitted subtypes per the Thesis section: Subtype A (future-dated catalyst — primary driver is a future-dated event with publicly-known scheduled date) or Subtype B (trend-continuation — primary driver is continuation of a quantifiable current trend metric for ≥ 12 months).
2. Thesis constructed from: last 8 quarters of earnings call transcripts (minimum), last 2 annual reports, competitive/sector context, regulatory and policy context, technological and secular theme context as applicable
3. Adversarial counter-argument specifically addresses: multi-year risk factors, management turnover risk, technological disruption risk, competitive erosion risk, concentration risk within D's existing book
4. Thesis specifies BOTH "completion" criteria (narrative fulfillment markers) AND "invalidation" criteria (observable pre-completion failure signals) — immutable through the position's life. (rev 28 subtype-specific per pre-mortem cycle 3 T1-β.) Subtype A invalidation: financial metric breach, regulatory milestone missed, contractual obligation failure, or publicly-disclosed corporate action. Subtype B invalidation: quantitative threshold on the trend metric (e.g., "growth rate falls below 15% YoY for 2 consecutive quarters"). Both subtypes maintain the no-qualitative-only invalidation discipline.
5. Position does not produce > 30% concentration in any single GICS sector within D's book; additionally (rev 26 added per pre-mortem cycle 1 item 7, rev 27 reframed per cycle 2 T1-C as mechanism-enforced correlation test, rev 28 extended per cycle 3 T1-α to post-entry monitoring): for any two currently-held positions with trailing-252-day daily-return correlation > 0.6, both count toward the same correlation bucket. No more than 3 positions may share any correlation bucket. The bucket assignment is computed by classical-method delegation across all currently-held positions plus the candidate entry. *Post-entry monitoring (rev 28):* the correlation matrix is recomputed monthly. If any held-position pair exceeds 0.7 daily-return correlation post-entry (above the 0.6 entry-time threshold by margin), the pair is treated as a 2-position correlation bucket for the purposes of subsequent entry decisions — any new candidate entry that would join this post-entry-emergent bucket counts as the bucket's third position, blocking further accumulation. Post-entry monitoring does not force exits on already-held positions; it only constrains future entries. The rev 27 framing operated only at entry-time which left a scope gap during stress regimes when correlations rise toward unity; the rev 28 extension closes the entry-decision channel of the gap while accepting that during-hold drift on existing pairs cannot be entry-time-resolved. **[Rev 35 (owner directive): the "No more than 3 positions may share any correlation bucket" count cap, and the post-entry-monitoring behavior of blocking a future entry into an emergent bucket, are REMOVED — correlation-bucket membership (both at-entry and post-entry) is now monitored-only/informational (Section 6), neither capped nor entry-blocking. The 30%-of-NAV GICS-sector exposure cap at the start of this criterion is unchanged.]**
6. Entry is not triggered by short-term momentum; if the name is rallying hard in the trailing 30 days, defer entry until rally pauses (avoids buying at recency-bias-fueled peaks per 2.14)

### Exit rules and thesis invalidation

**Exit if any of:**

- Thesis completion: narrative fulfillment marker reached
- Thesis invalidation: specific at-entry-defined invalidation criteria met (NOT price action alone)
- Tax optimization: after 12 months holding, positions qualify for LTCG treatment; when exiting on completion, prefer post-12-month exits where thesis permits
- No maximum hold. D's theses can legitimately take 2–3 years. Unlike A's 12-month hard cap, D accepts long timelines as thesis-structural.

**Not exit-triggering:**

- Short-term adverse price moves
- Quarterly results that don't bear on the multi-year thesis
- Macro environment shifts that don't invalidate the specific structural drivers

### Declared expected frequency

3–8 trades per year over active periods (counting entries and exits as separate trades; a single 2-year hold is 2 trades over ~2 years).

**Critical property (from Experiment_Parameters.md):** D's 30-trade gate will likely not be reached within any stable model-generation window. D's final determination comes at termination via one of the kill triggers — primarily the mark-to-market underperformance trigger (36-month active floor) or the foundation-change trigger, and secondarily drawdown. The gate is effectively inactive for D; this is an accepted, documented property, not a flaw.

### Classical-method delegation

- Market cap and liquidity screens
- Concurrent-position count and sector concentration checks
- Position sizing and 12-month LTCG qualification date tracking
- Portfolio-level sector and factor exposure
- Correlation-bucket computation (rev 27 added per Strategy D pre-mortem cycle 2 T1-C): trailing-252-day daily-return correlation matrix across all currently-held positions plus any candidate entry; bucket assignment by > 0.6 pairwise correlation threshold; max-3-per-bucket enforcement at entry
- Mark-to-market tracking for the underperformance trigger (rolling 12-month deployed TWR vs. SGOV gap; rev 27 dual-benchmark per cycle 2 T1-D: also rolling 24-month deployed TWR vs. SPY gap for edge-decay detection separate from beta drawdown; rev 28 beta-adjusted per cycle 3 T1-γ: 24-month edge-decay metric is alpha differential vs beta-equivalent SPY synthetic — regress monthly D-deployed-TWR on monthly SPY returns over 24-month window to estimate β̂; construct synthetic = β̂ × SPY; alpha = TWR − synthetic; rev 30 CI-gated per pre-mortem cycle 4 T1-4: also compute SE on the alpha estimate via the regression intercept's standard error and the 95% upper CI bound; alpha-test fires only when alpha point estimate ≤ -3pp AND 95% upper CI bound on alpha ≤ 0pp)

### Router activation rule

**Technical:** (SPY Trend State = UP OR SPY Trend State = NEUTRAL) AND Yield Curve Sustained Inversion Flag = NOT-SUSTAINED

Rationale: D is long-only equity with 12+ month minimum holding expectations. In DOWN regimes, initiating new long positions with multi-year time-to-resolution expectations adds macro risk with no compensation — defer. SUSTAINED yield curve inversion (> 18 months) has historically preceded regimes where multi-year equity theses compress under recessionary stress; the conservative backstop is to deactivate D rather than force its pre-mortem to anticipate that.

**Router deactivation does not force exits on existing D positions.** Per `Experiment_Parameters.md`, existing positions in a deactivated strategy run to their normal thesis-invalidation or exit conditions. D's multi-year theses would be systematically damaged by forced exits on transient regime changes.

**Fundamental question:** Is the current macro-structural environment one in which multi-year equity theses can plausibly play out, or are there structural headwinds (recessionary signals, regulatory regime shifts, secular theme disruption) that argue against initiating new long-horizon positions this month?

---


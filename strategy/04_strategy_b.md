<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Strategy B: Post-event mispricing exploitation

### Thesis

AI's narrative synthesis (1.1, 1.4) identifies situations where the market's immediate reaction to a public event (earnings, FDA decision, guidance update, regulatory action) has over- or under-shot relative to the information content of the event. The mispricing resolves over weeks as the market fully digests the event's narrative context. B's edge is in evaluating the quality of a realized market reaction to known public information, rather than predicting a future event's outcome. (Rev 12 correction, per Strategy B pre-mortem rev 2 cycle 1: B is structurally exposed to 2.20 (textbook-rational penalty) because the strategy's mechanism is precisely the textbook-rational instinct — that prices return to fundamental value — applied after an overreaction. The router's HIGH-VIX exclusion is a partial regime-level mitigation; no mechanism-level mitigation exists. The prior framing that B "compensates 2.20 by exploiting market irrationality" inverted what 2.20 actually is and has been retracted.)

### Differentiation from A

Already specified in A's section. Summary: A enters before event; B enters after. Never simultaneously in same name.

### Instrument eligibility rule

- US-listed common equity
- Market cap ≥ $2B at entry
- 30-day average daily volume ≥ $10M
- Long or short (differentiates from A's long-only posture) — but **long-biased in practice**; see the *Directional posture* note under the Router activation rule below
- Position size: ~~2% of strategy portfolio at entry~~ **AI-chosen risk budget per thesis (Rev 43, owner directive, 2026-07-28).** No blanket per-position figure. The AI sets this thesis's Capital at Risk (for long equity, the full position notional — there is no stop-loss, so the honest worst case is total loss) as a percentage of strategy portfolio value at entry, justified in the decision-log entry against the seven-factor list in `Experiment_Parameters.md` §Position size, and attacked on size as well as direction by the adversarial counter-argument entry criterion. Bounded by the ~~hard envelopes: **per-name aggregate CaR ≤ 10%** of strategy portfolio (all tranches summed) and **per-strategy deployed CaR ≤ 75%**~~ **[owner directive 2026-08-05 — BOTH envelopes RETIRED. The risk budget has NO numeric ceiling at any level; sizing is governed solely by the seven-factor justification and the mandatory adversarial attack on the size].** Conviction enters as an ordinal tier only — never as a probability multiplied into a sizing formula (`AI_Trading_Foundation.md` 3a.1, 2.26).
- No options

### Entry criteria

1. Public event occurred within the last 10 trading days, producing an immediate price reaction of ≥ 5% in either direction (measured as close-to-close move on event day)
2. Narrative synthesis concludes the market reaction is materially over- or under-sized relative to the event's fundamental implications, grounded in: event details, company fundamentals, comparable historical reactions to similar events at similar companies (retrieved, not recalled)
3. Thesis has explicit convergence target (rev 13 strict closure, rev 14 index-list strict enumeration per Strategy B pre-mortem rev 4 cycle 3 T1-4): either (a) a numerical price level OR (b) a specific event drawn from this strictly enumerated closed list named at entry — "next earnings release," "next FDA decision date," "next FOMC meeting," or "inclusion announcement in one of: S&P 500, Russell 1000, or Nasdaq 100." No additional event types are admissible; no other indexes are admissible. The convergence target is immutable from entry. (Rev 12 had included "or equivalent named at entry" which made the list operator-extensible; rev 13 closed that escape hatch but introduced "S&P (or major index)" which left "major index" undefined; rev 14 strict-enumerates the three admissible indexes.) Specific timeline: entry through convergence expected within 60 days.
4. Adversarial counter-argument doesn't identify a decisive flaw — specifically, attacker must consider whether the market reaction is information-driven rather than sentiment-driven (if information-driven, "mispricing" is actually correct pricing)
5. No A position currently open in the same name

### Adding to an existing position

**Authorized (Rev 40, owner directive 2026-07-21).** B may add to an already-open position in the same name — a second (or subsequent) ~~2%~~ **[Rev 43, owner directive, 2026-07-28 — superseded: adds are not fixed at 2%; each add carries its own AI-chosen risk budget, and as of the 2026-08-05 owner directive that budget has no numeric ceiling]** tranche layered onto an existing post-event thesis. Trigger is AI judgment: either (a) a dip against an intact thesis (adverse mark-to-market with no new information, per the "Not exit-triggering" list below — long positions only, consistent with B's asymmetric stop-loss design) or (b) strengthened conviction (new information reinforcing the original over/under-reaction read without itself requiring an independently-enumerated new convergence target). The hard gate: the position's original at-entry invalidation criteria (Exit rules below — new information that changes the situation, or the strict convergence-target/60-day timeline) must remain UNBREACHED at the time of the add — an add that would coincide with invalidation territory does not happen; that situation routes to exit, not to a pyramid.

Sizing: each add carries its **own AI-chosen risk budget**, sized independently of the parent tranche and every other add. Under rev 19 (owner directive, 2026-08-05), neither the add nor the name's aggregate CaR has a numeric ceiling. Each add's budget is justified against the seven factors and adversarially attacked on size exactly as a first entry is; tranche count and aggregate same-name risk are uncapped. Each add is independently thesis-constructed and logged as a distinct entry event; it shares the parent position's immutable convergence target and timeline. Adds obey the same instrument-eligibility and cross-strategy exclusions as a first entry. A short add is also barred when the position is at or near its +25% stop trigger.

### Exit rules and thesis invalidation

**Exit if any of:**

- Convergence target reached (price target or narrative-fulfillment marker)
- Thesis invalidation: new public information changes the situation (follow-on event, management action, regulatory development)
- Timeline expiry at 60 days from entry (thesis is stale; market had ample absorption time and did not converge)
- For short positions: borrow rate spike above 10% annualized (short-financing cost overwhelms thesis)
- For short positions: short-side stop-loss (rev 13 addition, per Strategy B pre-mortem rev 3 cycle 2 T1-A) — close the short if the underlying rises ≥ 25% from short-entry price. ~~At 2% position sizing, this caps single-trade short loss at 0.5% of strategy portfolio in the worst case~~ **[Rev 43, owner directive, 2026-07-28] This stop is now the DEFINING bound on a short's Capital at Risk, not a supplement to a fixed size: CaR = notional × 25%, so a short's stated risk budget and its notional are related by that factor. The stop is retained and is mandatory — long downside is bounded at −100% of notional so sizing alone caps it, but short downside is unbounded, so without this stop "risk is capped by sizing" would be false for a short.** This closes the unbounded-short-downside hole identified in cycle 2. The 25% threshold is wider than typical post-event drift (limiting whipsaw on routine adverse movement) but tight enough to bound squeeze-driven losses. Asymmetric-by-design: long positions retain no stop-loss because long downside is bounded at -100% of position (so worst-case long loss is bounded at 2% of strategy portfolio without an explicit stop), whereas short downside is unbounded without an explicit stop.

**Not exit-triggering:**

- Adverse mark-to-market without news (long positions only — short positions now have the rev 13 stop-loss above)
- General market moves

### Partial exits (trim / scale-out)

The same partial-trim authorization as A applies to B's long positions: the AI may sell part of an open long position on thesis or market-condition judgment via a market SELL for fewer shares than held, leaving the remainder open (Rev 41, owner directive, 2026-07-22). For short legs, a partial COVER — a market buy-to-cover for fewer shares than the short position — is likewise allowed on judgment. This is distinct from, and does not modify, the short stop-loss above: that trigger remains a full, mechanical close of the short position at the 25%-adverse-move threshold.

### Declared expected frequency

20–30 trades per year over active periods. Higher than A because the entry filter (recent 5%+ post-event move in a $2B+ name) is broader than A's (specific upcoming catalyst with narrative thesis).

### Classical-method delegation

- Event magnitude measurement (price moves over specific windows around event)
- Historical event-reaction base rates (how often do X% moves on event type Y revert vs. continue)
- Position sizing and short-borrow cost calculation
- Correlation check against A's current book
- ~~Sector concentration check (cap at 3 concurrent B positions per GICS sector, same as A)~~ — **REMOVED (Rev 35, owner directive):** no per-GICS-sector holdings-count cap; concurrent-position correlation monitored via Section 6 / KL #12, not capped

### Router activation rule

**Technical:** SPY Trend State ≠ DOWN AND VIX Regime ≠ HIGH

Rationale: In DOWN regimes, post-event moves are dominated by macro selling cascades; "overreaction" indistinguishable from regime change. In HIGH VIX regimes, post-event move sizes are noisy — every event produces 5%+ moves, diluting the signal.

**Directional posture — long-biased in practice (Rev 36, owner directive, per the 2026-06-23 short-bar revisit).** Although B is spec'd long-or-short, it is long-biased *by construction*, not by screen miscalibration. A SHORT requires fading a *positive* overreaction (a pop), but the router activates B only when SPY Trend ≠ DOWN and VIX ≠ HIGH — precisely the risk-on/neutral regimes where fading a pop runs into momentum, squeeze risk, and the 2.20 textbook-rational penalty (B's mechanism *is* that penalty). The regimes where pop-fading would be safer (DOWN / HIGH-VIX) are the ones the router excludes. Empirically, through 2026-06-22, 0 of ~108 B theses produced a short entry, and every declined short held or extended rather than faded (e.g. INTC 6/18 SP5 rumor-pop: declined, then extended +5% to $140.94 by 6/22 vs the ~$121 fade target). This long-bias is intended; the SP1/2.20 short gating is **not** to be loosened (see Section 5 Constraint 2 empirical note). The only lever that would make shorts routinely takeable is a router relaxation — deferred to a future pre-mortem.

**Fundamental question:** Is the current environment one in which event reactions show measurable mean reversion at 2–8 week horizons, or is the market in a regime where reactions are fully informative (no mean reversion to exploit)?

---


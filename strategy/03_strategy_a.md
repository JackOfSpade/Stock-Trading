<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Strategy A: Catalyst-driven equity long positions (pre-event, directional)

### Thesis

AI's narrative synthesis (1.1, 1.10) identifies equity names where an upcoming catalyst within 6 months has narrative underpinnings not yet reflected in sell-side consensus or price. Long equity position (not options) when the thesis time frame exceeds C's 45-day tenor, when the catalyst is structural rather than strictly date-specific, or when option premiums make defined-risk structures uneconomic. Exploits the same core narrative edge as C but over longer time scales where options are not the appropriate instrument.

### Differentiation from C and B (critical — both exist to prevent A being redundant)

- **A vs. C:** A's thesis timeline > 45 days OR the catalyst is structural rather than date-specific OR options premiums would consume > 30% of expected thesis payoff. A and C must not simultaneously hold positions in the same name on the same thesis.
- **A vs. B:** A enters before the catalyst. B enters after. Same name cannot be in A and B simultaneously under any circumstance. If A closes before catalyst and B later opens on post-catalyst reaction, those are two distinct theses that each require independent narrative construction and entry criteria satisfaction — B cannot inherit A's thesis.

### Instrument eligibility rule

- US-listed common equity
- Market cap ≥ $2B at entry (screens small-caps where hallucination rates are elevated per 2.3)
- 30-day average daily volume ≥ $10M (execution liquidity)
- Long-only (no short positions in A — short is B's territory)
- Position size: ~~2% of strategy portfolio at entry~~ **AI-chosen risk budget per thesis (Rev 43, owner directive, 2026-07-28).** No blanket per-position figure. The AI sets this thesis's Capital at Risk (for long equity, the full position notional — there is no stop-loss, so the honest worst case is total loss) as a percentage of strategy portfolio value at entry, justified in the decision-log entry against the seven-factor list in `Experiment_Parameters.md` §Position size, and attacked on size as well as direction by the adversarial counter-argument entry criterion. Bounded by the ~~hard envelopes: **per-name aggregate CaR ≤ 10%** of strategy portfolio (all tranches summed) and **per-strategy deployed CaR ≤ 75%**~~ **[owner directive 2026-08-05 — BOTH envelopes RETIRED. The risk budget has NO numeric ceiling at any level; sizing is governed solely by the seven-factor justification and the mandatory adversarial attack on the size].** Conviction enters as an ordinal tier only — never as a probability multiplied into a sizing formula (`AI_Trading_Foundation.md` 3a.1, 2.26).
- No options (if options are appropriate, the thesis belongs in C, not A)

### Entry criteria

1. Identified catalyst within 6 months: earnings cycle, regulatory timeline, product launch, restructuring event, analyst day, or structural narrative marker
2. Narrative thesis synthesized across: last 4 quarters of earnings transcripts, last 10-Q and 10-K filings, sell-side report synthesis (retrieved, not recalled, per 2.3 and 2.5), sector and competitor context
3. Thesis has a specific directional call with explicit pre-catalyst price target and post-catalyst thesis-completion criteria (both written at entry, immutable through the position's life)
4. Adversarial counter-argument doesn't identify a decisive flaw
5. ~~Sector concentration check (via code): position does not produce > 3 concurrent A positions in the same GICS sector~~ — **REMOVED (Rev 35, owner directive):** no per-GICS-sector holdings-count cap applies; concurrent-position correlation is monitored, not capped (see Section 6 / Known Limitations). *(Numbered slot retained for cross-reference stability; it no longer blocks entry.)*
6. 2.19 exclusion (added in pre-mortem rev 3): the thesis does not rest primarily on analogy to a specific named historical setup. Concretely: if removing the historical-analogue portion of the thesis (e.g., "this looks like [named company] in [specific year]," "setups like this historically produced X% returns," "management teams that did [thing] subsequently did [outcome]") causes the remaining reasoning to fail to support the directional call, the thesis is inadmissible. Historical context as calibration (typical drug approval timelines, sector margin distributions, typical earnings surprise magnitudes at the same company) is permitted — these are institutional or current-company facts, not outcome memory. The test: does the thesis stand on current-company public documents and current sector/macro context, without the specific historical-setup analogue? If yes, admissible. If the analogue is load-bearing, inadmissible.

### Adding to an existing position

**Authorized (Rev 40, owner directive 2026-07-21).** A may add to an already-open position in the same name — a second (or subsequent) ~~2%~~ **[Rev 43, owner directive, 2026-07-28 — superseded: adds are not fixed at 2%; each add carries its own AI-chosen risk budget, and as of the 2026-08-05 owner directive that budget has no numeric ceiling]** tranche layered onto an existing catalyst thesis, not a new independent entry. Trigger is AI judgment: either (a) a dip against an intact thesis — price weakness with no invalidation news, consistent with the "Not exit-triggering" list below — or (b) strengthened conviction — new information (an incremental data point, an analyst confirmation, a narrowing catalyst timeline) that reinforces the original narrative without itself constituting a new, independently-enumerated thesis. The hard gate: the position's original at-entry invalidation criteria (Entry criterion 3, enforced via the Exit rules below) must remain UNBREACHED at the time of the add — an add that would coincide with invalidation territory does not happen; that situation routes to exit, not to a pyramid.

Sizing: each add carries its **own AI-chosen risk budget**, sized independently of the parent tranche and every other add. Under rev 19 (owner directive, 2026-08-05), neither the add nor the name's aggregate CaR has a numeric ceiling. Each add's budget is justified against the seven factors and adversarially attacked on size exactly as a first entry is; tranche count and aggregate same-name risk are uncapped. Each add is independently thesis-constructed—its own adversarial counter-argument and written note—and logged as a distinct entry event, while sharing the parent position's immutable completion/invalidation criteria. Adds obey the same instrument-eligibility and cross-strategy exclusions as any first entry.

### Exit rules and thesis invalidation

**Exit if any of:**

- Thesis completion: catalyst has occurred AND narrative thesis has played out per the at-entry completion criteria (price target reached OR narrative fulfillment marker met)
- Thesis invalidation: catalyst failed to materialize as expected OR produced the opposite effect OR specific invalidation criteria defined at entry are met (e.g., management departure, guidance cut, regulatory blocker)
- Maximum hold 12 months from entry (hard time stop). Rationale: positions held > 12 months by design belong in D, not A. A hitting 12 months with no resolution indicates thesis timeline was miscalibrated — force exit generates diagnostic signal rather than allowing stale positions to linger.
- Thesis overlap resolution: if the same thesis is discovered to justify a D-style long-horizon position, A exits and D may enter (coordinated manually at monthly review, not automatic)

**Not exit-triggering:**

- Adverse price movement with no invalidation news
- Market-wide drawdowns
- Interim quarterly results that don't affect the catalyst thesis

### Partial exits (trim / scale-out)

Independent of the full-exit triggers above, the AI may sell part of an open A position — reducing size without closing it — on thesis or market-condition judgment: e.g., reduced conviction that falls short of full invalidation, partial profit-taking, or risk trimming (Rev 41, owner directive, 2026-07-22). A partial exit is a market SELL for fewer shares than the position currently holds; the remainder stays open and continues to run against the same at-entry completion/invalidation criteria. Trigger and size are AI judgment — no fixed schedule or fixed fraction is specified.

### Declared expected frequency

15–25 trades per year over active periods.

### Classical-method delegation

- Market cap and liquidity screens (daily maintenance check that positions remain above thresholds; if a name falls below mid-position, not an exit trigger, but flagged in monthly review)
- Sector concentration checks (GICS sector codes, concurrent position counts)
- Volatility-adjusted position sizing flag if a name has materially higher volatility than sector median (~~position held at 2% but flagged for monthly review~~ **[Rev 43] volatility is now an input the AI weighs directly when setting the thesis's risk budget rather than a post-hoc flag on a fixed size; the monthly-review flag is retained as a check that it was actually weighed**)
- Catalyst date tracking and thesis-age monitoring
- Correlation check against current B book (prevent concurrent A/B on same name)

### Router activation rule

**Technical:** SPY Trend State = UP AND Equity Breadth State = HEALTHY

Rationale: A is long-only equity with 1–12 month holds. In DOWN or NEUTRAL regimes, even correct catalyst calls produce losses dominated by beta. HEALTHY breadth required because UP regimes with WEAK breadth (narrow mega-cap rallies) frequently leave individual catalyst names behind — the rally is in index-constituent-weighted terms, not in terms of where individual catalyst narratives play.

**Fundamental question:** Is the current macro environment one in which individual-stock catalysts are being rewarded by the market, or is the market's attention dominated by macro factors that overwhelm idiosyncratic narrative?

---


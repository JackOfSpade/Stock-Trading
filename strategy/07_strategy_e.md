<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Strategy E: Market-neutral narrative-divergence pairs

### Thesis

Within a single GICS industry group, AI's cross-document synthesis (1.1, 1.4, 1.10) can identify two companies L (laggard) and S (leader) where the narrative divergence in public disclosures and analyst reaction patterns has gotten ahead of the fundamental divergence. Long L / short S captures mean reversion without net market exposure, compensating 2.7 (regime maladaptation) and 2.20 (textbook-rational penalty) — market direction doesn't matter for the pair's returns.

### Explicit confrontation of disadvantage 2.6 (no access to private information)

Per `Experiment_Parameters.md` pre-mortem requirement: this is the load-bearing constraint for E and is confronted explicitly here (not only in the pre-mortem section).

**E's universe excludes any name where the narrative divergence thesis depends on:**

- Expert network calls or consultations
- In-person management access or private investor meetings
- Conference attendance that reveals non-public context (sell-side conferences included)
- Buy-side intelligence or fund-manager relationships
- Industry contacts, supplier or customer channel checks, or private competitive intelligence
- Any information whose provenance cannot be traced to a specific public document or public news release

**During thesis construction, if reasoning requires any phrase resembling "per industry contacts," "sources familiar with," "per channel checks," "management has indicated privately," or any equivalent — the thesis is not tradeable in E. The session must abandon the thesis and move to the next candidate.**

All thesis construction must be fully auditable against: 10-K and 10-Q filings, 8-K announcements, earnings call transcripts, public analyst reports (full text), press releases, publicly available news, and publicly available industry data (including subscription-available sector data if the subscription is broadly accessible at retail tier).

### Instrument eligibility rule

A pair consists of:

- Long position in company L
- Short position in company S
- Both in the same GICS **industry group** (6-digit GICS level, tighter than sector — GICS sectors would allow pairs like "two software companies" which may have minimal correlation)
- Both executable at 2% of strategy portfolio per leg within IBKR minimum-share-size constraints

Per `Experiment_Parameters.md`, paired positions consume 4% of strategy portfolio per thesis (2% per position × 2 positions). Each leg is 1 position for the 30-trade gate count; a pair equals 2 trades.

**ETF pair substitution:** If individual-stock shorting is not feasible at the current strategy portfolio size (typical issue when S's share price × minimum share count × 2% cap interact unfavorably), the pair may use same-industry-group ETFs as substitute legs. ETF-pair execution dilutes the idiosyncratic thesis (ETFs carry many constituents) but preserves the market-neutral structure. This substitution is a documented accepted cost when portfolio size does not support individual-stock pair execution. As portfolio size grows past that threshold, individual-stock pairs become the primary construction without any rule change needed.

### Entry criteria

1. Narrative divergence thesis identified: specific public-information basis for why L is under-narrated relative to S, with explicit predictions about what public events would cause reconvergence
2. Adversarial counter-argument doesn't identify a decisive flaw
3. Classical-method delegation produces: L–S correlation over trailing 252 trading days ≥ 0.5 (pairs with lower correlation are not pairs — they are two independent bets); beta-adjusted leg sizing if L and S have materially different volatilities
4. Expected holding period to thesis resolution is 1–6 months
5. Short-financing cost for the S leg (borrow rate × position size × expected holding period) is computed by code and is ≤ 15% of thesis expected return — otherwise financing eats the alpha

### Exit rules and thesis invalidation

**Exit if any of:**

- Convergence target reached: the specific public indicators defined at entry as "thesis playing out" are met (e.g., S misses earnings consensus by > X% while L meets/beats)
- Thesis invalidation: new public information changes the fundamental situation on either leg (management change, material operational event, M&A announcement, regulatory action)
- Time-based exit at 6 months from entry: thesis is stale; short-financing costs accumulating; exit regardless of P&L
- Correlation breakdown: rolling 60-day correlation between L and S falls below 0.3 (pair relationship has broken; thesis is no longer market-neutral)

**Not exit-triggering:**

- Adverse mark-to-market on the pair with no thesis-invalidating news
- General market moves (pair should be approximately neutral to these by construction)

### Declared expected frequency

6–12 pair theses per year over active periods, equaling 12–24 trades counted toward the 30-trade gate (two positions per pair).

### Classical-method delegation

- Correlation computation (L vs. S, trailing 252 trading days, rolling 60 days)
- Beta adjustment for leg sizing (regression L returns on S returns, use hedge ratio)
- P&L attribution per leg (verify thesis is playing out in the expected direction on each side)
- Short financing cost estimation using broker's current rate
- GICS industry group classification lookup

### Router activation rule

**Technical:** SPY Trend State ≠ DOWN AND VIX Regime ≠ HIGH AND Breadth State = HEALTHY

Rationale: In DOWN regimes and HIGH VIX regimes, within-sector correlations collapse toward 1 (everything moves together in fear) or toward 0 (everything unmoored). Either extreme breaks pair mechanics. In UP or NEUTRAL regimes with LOW or NORMAL VIX, sector-level correlations are in the 0.5–0.8 band where pair trades have room to express divergence.

The additional HEALTHY breadth requirement (tightening from the prior B-identical rule) reflects that E runs market-neutral within-industry pairs, which require cross-sectional dispersion inside each sector to generate convergence edge. Narrow markets (breadth < 50%) correspond to concentrated participation where leadership clusters in a small number of names; within-industry pair spreads compress because the long-leaders outrun the laggards in the same factor regime. B, which exploits 2–8 week post-event overshoots in specific names regardless of breadth, does not need this additional constraint.

**Fundamental question:** Is the current sector-rotation environment conducive to within-industry-group mean reversion, or are macro forces dominating intra-sector dynamics?

---


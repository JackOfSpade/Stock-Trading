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
- Both legs executable within IBKR minimum-share-size constraints at the pair's AI-chosen risk budget (**Rev 43, owner directive, 2026-07-28** — formerly "2% of strategy portfolio per leg")

Per `Experiment_Parameters.md` rev 19 §Position size, a pair is sized as **one thesis**: the AI sets one combined CaR budget with no numeric ceiling and sizes the legs to the hedge ratio. The budget is seven-factor justified and adversarially attacked on size. Each leg is one position for the 30-trade gate count; a pair equals two trades.

**ETF pair substitution:** If individual-stock shorting is not feasible at the current strategy portfolio size (typical issue when S's share price × minimum share count × ~~2% cap~~ **[Rev 43, owner directive, 2026-07-28 — the pair's AI-chosen Capital-at-Risk budget; a pair is sized as ONE thesis, not per leg. ~~bounded by the ≤ 10% per-name / ≤ 75% per-strategy envelopes~~ — owner directive 2026-08-05 retired both envelopes, so the pair budget has no numeric ceiling]** interact unfavorably), the pair may use same-industry-group ETFs as substitute legs. ETF-pair execution dilutes the idiosyncratic thesis (ETFs carry many constituents) but preserves the market-neutral structure. This substitution is a documented accepted cost when portfolio size does not support individual-stock pair execution. As portfolio size grows past that threshold, individual-stock pairs become the primary construction without any rule change needed.

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
- **Short-leg stop — MANDATORY, distance AI-determined per pair at entry (Rev 45, owner directive, 2026-08-18).** Close the pair if S rises from its short-entry price by at least the **stop distance fixed for this pair at entry**. `Experiment_Parameters.md` §Position size makes a stop mandatory on any short leg because it is the only thing that bounds short Capital at Risk — *"without it CaR is unbounded and the phrase 'risk is capped by sizing' would be false"* — and this rule is what makes E's short-leg CaR an enforced number rather than an assumption. **Before this revision E had no stop of any kind anywhere in its machinery while every document that sized an E pair assumed a mandatory +25% one; that gap was found by D2 on 2026-08-18 (`events.decision_log` ops-note `5f65959b-d259-47e7-966e-e0b61f9ccbde`) at E's first thesis to reach the sizing step, and closed here.**

  **The distance is NOT a fixed constant, and deliberately so (owner directive: "no fixed numbers, it should be determined by the AI so it can leverage context of current market conditions").** It is judgment-native machinery in the sense of `Claude_Task_Plan.md` SL2 (A) 1b: chosen fresh for each pair during thesis construction from that pair's own measured conditions — S's realized and implied volatility, the pair's trailing-252-day spread distribution and where the entry sits in it, the 252-day correlation and the beta-derived hedge ratio, borrow cost and expected holding period, and the prevailing SPY-trend / VIX / breadth regime — so that a low-volatility utilities pair and a high-beta semiconductor pair do not inherit the same bound from a constant that was never derived for either. Strategy B's `SHORT_STOP_LOSS_PCT = 0.25` is B's own machinery and is **not** imported here: B's 25% was derived against B's post-event-drift horizon, and importing it would license an E pair to carry a bound nothing about E produced.

  **Three rails, none waivable:**
  1. **Set at entry, BEFORE sizing.** The distance is chosen and written down before the CaR arithmetic that consumes it, because short-leg CaR *is* `short notional × that distance` and E's pair budget is the sum of both legs' CaR. A pair whose distance has not been set cannot be sized, and therefore cannot be entered. This ordering is the whole point: a distance chosen after the size is a rationalisation of the size.
  2. **Frozen for the life of the position — it may tighten, never widen.** Re-deriving the distance after an adverse move is exactly the criteria-drift-under-loss-pressure failure that judgment-native machinery requirement (d) names, and it would retroactively unbound a CaR figure already recorded and already justified. A tightening is permitted only as part of a full pair exit.
  3. **Recorded with its justification.** Write the chosen distance and the reasoning into the thesis's `events.decision_log` entry (`fields.short_stop_pct`, `fields.short_stop_rationale`), under the same discipline as the seven-factor CaR justification and subject to the same mandatory adversarial attack on size. An unrecorded distance is treated as unset — see rail 1.

  **The stop closes the PAIR, not the short leg alone.** When it fires, cover S and sell L in the same session, for the reason the Partial exits paragraph below already gives: a lone surviving leg is a naked directional position and defeats the market-neutral structure that is this strategy's entire thesis.

**Not exit-triggering:**

- Adverse mark-to-market on the pair with no thesis-invalidating news
- General market moves (pair should be approximately neutral to these by construction)

### Partial exits (trim / scale-out)

A partial trim is allowed only by reducing both pair legs together, proportionally, in the same session — a market SELL on part of the long L leg paired with a market partial-COVER on part of the short S leg, sized to preserve the pair's hedge ratio (Rev 41, owner directive, 2026-07-22). Trimming one leg alone is never permitted: it would leave a naked, unhedged leg and defeat the market-neutral pair structure. This directive does not change the fact that E's fills-derived campaign/lot accounting is long-only-correct only — a pre-existing limitation, unrelated to and unchanged by this directive.

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


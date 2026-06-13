2026-06-13
<!-- d1_scan_through_utc: 2026-06-13T22:04:27Z -->

# Daily Market Development Scan — 2026-06-13 (Sat, MT)

Scan window: 2026-06-11 16:05 MDT → 2026-06-13 16:04 MDT (~48h). **The scheduled Friday-evening D1 did not run (last D1 commit was Thu 6/11 22:10 UTC), so this window stretches back to the actual last run and covers the full Friday 6/12 cash session — gap-free.** Saturday 6/13 is a non-trading day, so the only completed trading session inside the window is **Friday 6/12**, which includes the **ADBE FQ2 Day-0 close-to-close** (the prior scan flagged this for verification) and the **SpaceX (SPCX) IPO debut**. Cast broadly across the US-listed ≥$2B universe, not scoped to held/watchlist names. Live book + Friday marks pulled from the IBKR connector; canonical state read from BigQuery (`state.current_positions`, `state.current_regime`, `perf.kill_flags`).

> **Connector data note (weekend):** on this Saturday run the `get_price_snapshot` `last`/`prior-close` fields returned **stale Thursday 6/11 closes** (e.g. ZBRA 222.44, HCA 378.51, AZO 3081.62), while `get_account_positions` market_price and `get_price_history` daily bars carried the **Friday 6/12 closes**. Friday closes below are taken from `get_price_history` ONE_DAY bars (the authoritative source), not the stale snapshot.

Open book (connector `get_account_positions`): **ZBRA (B), HCA (B), AZO (B), RTX (D), DIS (D)** + SGOV park (92.30 sh). Matches `state.current_positions` exactly. One immaterial divergence: the connector carries a **0.0007-sh IBM fractional dust ($0.19)**, a residual from the prior IBM B-exit; BQ does not track it as OPEN — not a position, no action. (RTX shows the 6/12 DRIP reinvest — +0.0006 sh @ $183.87 from the 5/22 ex-div, already reconciled in BQ.)

Regime (`state.current_regime`, M1b 2026-06-01 + divergence reviews 6/3): **A=DO-NOT-ACTIVATE, B=ACTIVATE, C=HYBRID ACTIVATE (FOMC-only), D=ACTIVATE, E=ACTIVATE (execution-feasibility-deferred, ETF-substitution-required at current book size)**. Fundamental axis: stagflation-tilt + risk-on; shock_overlay=latent. Breadth HEALTHY · SPY Trend NEUTRAL · curve NOT-sustained-inverted.

Friday tape: **S&P 500 +0.5% → 7,431.46; Dow +0.7% (+353.51) → 51,202.26; Nasdaq +0.31% → 25,888.84.** A **third consecutive up-session** and a modest, broad-based grind higher — but note the leadership rotation: **Dow > Nasdaq** (cyclical/value tilt) as megacap tech digested Thursday's chip rip, **ADBE −6.8% dragged software**, and the **SpaceX IPO drew an estimated >$11B of turnover at the open**, siphoning liquidity from the rest of tech. Two macro threads continued the de-escalation/relief tape from Thursday: **(1) Iran** — a Trump administration official put the odds of a signed US-Iran deal in the coming days at **~80%** (deal would reopen Hormuz, lift the naval blockade, dismantle Iran's nuclear program), though **Iran's Mehr agency released contradictory terms**, so the deal is *signaled but not signed and terms are disputed*; **(2) crude fell again** — **WTI −3.2% → $84.88, Brent −3.4% → $87.33** (lowest since spring) as the supply-shock premium kept deflating. **UMich June preliminary sentiment 48.9** (up ~9% off May's record-low 44.8) with **1yr inflation expectations easing 4.8%→4.6% and 5-10yr 3.9%→3.4%** reinforced the "energy-driven, now-cooling inflation" read.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **SpaceX (SPCX) IPO — the largest in history; +19% Day-1 to $161.11.** Priced at $135, opened ~$150 (+11%), peaked +>30% (briefly >$2.25T market cap), and **closed $161.11, +19%**, raising **~$75B** and valuing SpaceX above $2T. It dominated Friday's tape — >$11B turnover at the open pulled liquidity out of the rest of tech (Nasdaq the day's relative index laggard) and out of listed space/satellite names (SATS, ASTS, RKLB sold off in sympathy as money rotated into SPCX). Historic in scale, but a **brand-new listing with no earnings history and no event-convergence mechanism** — not a strategy candidate (see Opportunity Check). (Sources: [CNBC SpaceX IPO 6/12](https://www.cnbc.com/2026/06/12/spacex-ipo-spcx-live-updates.html), [NPR 6/12](https://www.npr.org/2026/06/12/nx-s1-5855004/stock-ai-spacex-ipo-elon-musk), [Fortune 6/12](https://fortune.com/2026/06/12/spacex-ipo-trading-first-day-live-updates-elon-musk/).)
- **Iran — deal signaled (~80% per US official) but NOT signed; terms disputed.** A Trump administration official said there is an ~80% chance the US and Iran sign in the coming days (reopen Hormuz, lift the naval blockade, dismantle the nuclear program, remove enriched uranium), but **Iran's Mehr news agency published more Tehran-favorable terms** (US force withdrawal, blockade lift in 30 days, $300B reconstruction), i.e. the two sides are not aligned on terms. Markets kept pricing the relief branch: **crude −3%+ again** (WTI $84.88, Brent $87.33). Directly continues to relieve the energy-driven inflation impulse and the `shock_overlay` thread. (Sources: [CNBC oil/Iran 6/12](https://www.cnbc.com/2026/06/12/oil-prices-wti-brent-on-hopes-of-us-iran-deal-despite-tehran-pushback.html), [TheStreet 6/12](https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-june-12-2026).)
- No unscheduled regulatory/enforcement action, material bankruptcy, or disaster surfaced inside the window beyond the above.

### 2. Scheduled events that resolved today (US-listed ≥$2B)

- **Adobe (ADBE) FQ2 Day-0 close-to-close — −6.76%** (Thu 6/11 close $218.80 → Fri 6/12 close $204.02, on ~17.9M shares ≈ 5× normal). **The flagged verification: the negative AH reaction not only held but deepened into the cash session.** The print itself was a clean **beat-and-raise** (adj EPS $5.96 vs $5.82; revenue $6.62B +13% YoY; FY guide raised to $24.35–24.45 EPS / $26.50–26.60B; **AI-first ARR >$500M, tripled YoY**), but the Day-0 tape sold off on the **CFO Dan Durn departure (effective 6/15)** layered onto the still-vacant permanent-CEO seat — a **dual senior-leadership vacuum**, not a demand miss. For the A-queue this **refutes the standing bearish ADBE framing at the print level** (Creative-Cloud-decel / Firefly-monetization-lag thesis) while the −6.76% Day-0 is a **governance/leadership overhang**, not fundamentals. (Sources: [TechTimes ADBE 6/12](https://www.techtimes.com/articles/318264/20260612/adobe-q2-2026-earnings-record-662b-revenue-ai-arr-triples-cfo-exits-days.htm), [Investing.com ADBE 6/11](https://www.investing.com/news/earnings/adobe-delivers-beatandraise-quarter-but-stock-slips-after-hours-on-cfo-exit-4738231).)
- **RH (Restoration Hardware) FQ1 — −5.8% to $149.95.** Revenue $800.3M (−1.7% YoY, slightly below the $816.8M consensus on one tally / a hair above $792.8M on another), **adj loss −$1.97 vs −$2.11 consensus (beat)**, FY26 sales guide **raised at the low end only** ($3.577–3.715B → $3.594–3.715B). But **operating profit −38.8% YoY to $34.2M and a net loss (−$0.73 GAAP diluted)** — the headline "beat-and-raise" masks genuine **margin/profit deterioration** consistent with housing-turnover starvation (the same structural consumer-discretionary weakness as the A-queue HD/TGT bearish theses). Wells Fargo nudged its PT $160→$175 (Overweight). A ≥5% / ≥$2B event-mover — screened as a B candidate below. (Sources: [Quiver RH Q1 6/12](https://www.quiverquant.com/news/RH+(RH)+Stock+Falls+on+Q1+2026+Earnings), [Benzinga RH 6/12](https://www.benzinga.com/analyst-stock-ratings/price-target/26/06/53172761/these-analysts-increase-their-forecasts-on-rh-following-better-than-expected-q1-earnings).)
- **UMich June preliminary consumer sentiment 48.9** (vs May's record-low 44.8, +~9% MoM — first rise in five months, on falling gasoline prices); **1yr inflation expectations 4.6% (from 4.8%), 5-10yr 3.4% (from 3.9%).** Sentiment improving off a historic nadir; inflation expectations easing but still well above the 2.8–3.2% 2024 band. Marginally softens the inflation-axis input (energy), no axis flip. (Sources: [Advisor Perspectives 6/12](https://www.advisorperspectives.com/dshort/updates/2026/06/12/consumer-sentiment-improves-in-june-but-remains-bleak), [IndexBox 6/12](https://www.indexbox.io/blog/us-consumer-sentiment-improves-in-early-june-2026-after-four-month-decline-1/).)
- **Calendar ahead:** **FOMC 6/16–17** (Warsh's first meeting as Chair; live C catalyst, queued `rescreen-FOMC-C-20260615` due 6/15). **MU FQ3 — 6/24 AMC** (A-queue). No other held/watchlist print inside the window.

### 3. Large single-name moves (≥$2B, ≥5% close-to-close, event-attributable)

- **SPCX +19% Day-1** ($135 IPO → $161.11) — the record IPO debut (§1). New listing; no strategy fit.
- **ADBE −6.76% Day-0** — beat-and-raise undercut by the CFO-exit / dual-leadership-vacuum overhang (§2). A-queue name; information/governance-driven.
- **RH −5.8%** to $149.95 — FQ1 print; "beat-and-raise" headline over a −38.8% operating-profit / net-loss / margin-deterioration body (§2). Screened as a B candidate below.
- **Space/satellite sympathy down-moves (SATS, ASTS, RKLB)** as IPO liquidity rotated into SPCX — sympathy/flow moves, no event-fundamental catalyst on each name, no convergence mechanism → no strategy fit. (Micro-cap movers like CAST/HSPT/SMSI are sub-$2B, excluded.)
- No other clean ≥5% close-to-close move on a ≥$2B name attributable to an identifiable public event surfaced inside the window. The Thursday AI-hardware rip (INTC +9.27%, etc.) was the *prior* window and is not re-counted here; Friday's chip complex was mixed-to-flat as megacap tech digested the move and ceded liquidity to SPCX.

### 4. Sector-level moves

- **Modest broad advance, cyclical/value-tilted (Dow +0.7% > Nasdaq +0.31%).** No clean GICS sector ETF printed a ≥2% close on the day; the structure was a low-amplitude rotation — financials/industrials/cyclicals firmer with the steeper-curve / risk-on read, **software soft** (ADBE −6.8% drag), and **energy the relative laggard** on the ~3% crude drop (Iran-deal supply expectations). This was a grind, not a down-leg anywhere. (Sources: [TheStreet 6/12](https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-june-12-2026), [CNBC 6/12](https://www.cnbc.com/2026/06/11/stock-market-today-live-updates.html).)

### 5. Notable commentary

- **Iran-deal terms openly disputed** between the US administration (~80% sign odds, hardline terms) and Tehran (Mehr's softer terms) — the relief tape is running ahead of an unsigned, contested agreement; the crude tape (WTI $84.88) and Hormuz traffic remain the tells.
- **ADBE leadership question sharpened:** coverage framed the recurring 2026 pattern — improving numbers (AI-ARR tripled), complicating narrative (now no permanent CEO *and* no permanent CFO). Relevant to the A-queue AI-software cohort's entry-quality read.
- **RH analyst PT nudges** (Wells Fargo $160→$175 Overweight) into a print the tape sold −5.8% — a beat-on-the-loss-line against deteriorating operating margins; the housing-discretionary demand backdrop remains the binding constraint.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP (every open position; today = 2026-06-13 MT, last session = Fri 6/12)

Friday closes from `get_price_history` ONE_DAY bars; targets/time-exits from `state.current_positions`. Open set per connector = ZBRA, HCA, AZO, RTX, DIS (+SGOV).

| Pos (strat) | Close (Fri 6/12) | Fri % | Convergence target | Time-exit | Trigger? |
|---|---|---|---|---|---|
| ZBRA (B) | $228.42 | **+2.69%** | $264.00 | 2026-07-13 | No (−13.5% below) |
| HCA (B) | $387.18 | +2.29% | $442.85 | 2026-06-27 | No (−12.6% below) |
| AZO (B) | $3,116.30 | +1.13% | $3,200.00 | 2026-07-24 | No (−2.6% below) |
| RTX (D) | $183.53 | −0.37% | none (long-horizon) | 2027-04-27 | No |
| DIS (D) | $100.04 | −0.30% | none (long-horizon) | 2027-05-07 | No |

**No mechanical exit triggered.** No convergence-target hit (AZO closest at −2.6% below $3,200; ZBRA −13.5%; HCA −12.6%). No time-based exit due — earliest is **HCA 2026-06-27 (14 days out)**. The three B-longs each added ground Friday (ZBRA continues recovering off its 6/10 52-wk low of $216.79 intraday / $214.31 print-low).

### PER-STRATEGY KILL-TRIGGER SWEEP (every active strategy)

Latest engine row (`perf.kill_flags`, **as-of 2026-06-12 = Friday close** — fully current, no intraday refresh needed since Saturday is non-trading): **B** deployed_unit_value 1.01790 / peak 1.01790 / **drawdown 0.00%** (fully recovered to its high-water mark on the Wed→Fri rally; excess_vs_SGOV +1.32%; deployed_days 34, gate_n 25, closed_trades 5); **D** deployed_unit_value 0.98044 / peak 1.00926 / **drawdown −2.85%** (excess −2.41%; deployed_days 34, gate_n 30). **All four flags false** for both (drawdown_kill / runaway_review / m2m_underperf_review / gate_reached). Both are **nowhere near the −50% drawdown kill (#1)**, and neither deployed TWR has doubled → **no runaway-success (#3)**. **No kill-trigger flags.**

### JUDGMENT-LADEN INVALIDATION CHECK (developments vs entry-record exit criteria)

- **RTX (D) — NOT-TRIPPED.** −0.37% Fri. The Iran de-escalation is a *mild* narrative headwind for a defense/effectors name (a signed deal would reduce near-term missile-defense demand pull), but it is nowhere near the entry-record invalidation set (Airbus / powder-metal / GTF EIS / backlog / FCF / procurement) — none of which moved, and the deal is unsigned with disputed terms. Long-horizon D thesis intact. No action.
- **DIS (D) — NOT-TRIPPED.** −0.30%; no name-specific news inside the window. Criterion (v) (final FCC order materially restricting ownership AND a Disney 8-K material-adverse disclosure) — neither exists → NOT-TRIPPED. No action.
- **ZBRA (B) — NOT-TRIPPED, pressure continues easing.** +2.69% to $228.42, a second up-session off the 6/10 52-wk low. No name-specific catalyst inside the window; the bounce is macro/sector beta (industrial-tech firmer with the broad risk-on). Entry-record criteria (name-specific catalyst / guidance cut / demand-break / sub-pattern-1 PT cluster) all NOT-TRIPPED; B-longs carry no price stop; disposition stays convergence ($264) / time-exit (2026-07-13, 30 days out). Still the furthest open B-long below target (−13.5%) but recovering. No action.
- **HCA / AZO (B) — NOT-TRIPPED.** HCA +2.29% beta; AZO +1.13% (back to −2.6% below its $3,200 target, the closest open position to a convergence). No name-specific catalyst, below the ≥5% bar. Criteria NOT-TRIPPED. HCA time-exit 6/27 (14 days) is the next mechanical disposition to watch.

### WATCHLIST CANDIDATE STATUS

- **Strategy A queue (AI/semi/tech cohort)** — **context for the next M1 ACTIVATE evaluation, not a today action** (router DNA → no drain). One A-queue name had a material datapoint this window: **ADBE** — FQ2 **Day-0 close-to-close −6.76%** confirmed. The beat-and-raise (AI-ARR >$500M tripled; FY guide raised) **refutes the standing bearish ADBE framing at the print level**, but the −6.76% Day-0 is a **CFO-exit / dual-leadership-vacuum (no permanent CEO + no permanent CFO) overhang**, not a demand signal — i.e. the bearish framing is refuted at fundamentals while the entry-quality read is complicated by governance + a negative tape (the same "fundamentals ratified/refuted but Day-0 negative" shape seen on NVDA/AMAT sell-the-news). The cohort's standing **"valuation + capital-intensity / governance"** caveat carries. **No queue name moves to entry-ready; none invalidated. Strategy A queue unchanged.**
- No B-overflow (NVO) / B-short-tracking (SHOP/PYPL/CDW/MGM) / D-pipeline name materially changed inside the window.

---

## ANALYSIS — OPPORTUNITY CHECK

- **RH (−5.8%, FQ1 print) — new Strategy B candidate (B is ACTIVATE); thesis construction required in a separate session.** Mechanically clears the screen (≥5% close-to-close, ≥$2B, identifiable earnings event, 10-day entry window open ~through 6/22–23). Direction would be a **B-LONG mean-reversion** (the stock fell on a beat-EPS / raise-guide headline). **Caveat for the thesis-construction session:** the move looks **information-driven, not a clean sentiment overshoot** — operating profit −38.8% YoY, a net loss, revenue −1.7% YoY, and only a low-end guide raise point to genuine margin/housing-demand deterioration (the same structural discretionary weakness as the HD/TGT bearish A-theses), which is a weak basis for a B-long convergence. Check against B sub-pattern taxonomy (info-driven guidance/margin reset family) before any GO. **Next step: full B thesis construction (D2 queue).**
- **SPCX (+19% Day-1) — no strategy fit.** A first-day IPO debut with no earnings history, no public-information *event* to fade/converge against, and no convergence mechanism → not a B/C/A/E candidate.
- **ADBE (−6.76% Day-0) — A-queue, not a fresh B candidate.** The drop is governance-driven on a beat-and-raise, but ADBE has **no admissible 60-day B convergence catalyst** (next earnings ~Sept, FOMC mechanism-mismatched, already in all indices), so any 60-day target degenerates to the multi-quarter narrative = Strategy A territory (same routing logic as INTC). Already in the A-queue; resolves at next M1 ACTIVATE. No fresh B thesis.
- **No new C or A catalyst announced.** Live C catalyst remains **FOMC 6/16–17** (queued `rescreen-FOMC-C-20260615` due 6/15, conservative-default = stay in SGOV). A is DNA → any A catalyst routes to the Watchlist A-queue.
- **E (intra-cyclical dispersion):** Friday's modest, low-amplitude rotation opened no clean intra-industry-group divergence; **E remains execution-feasibility-deferred at current book size** (ETF-substitution-required per `div-E-202605-1`) regardless. E-watch for M2/M4.
- **Already-queued items drained by D2 (not D1):** `rescreen-FOMC-C-20260615` (due 6/15), and any still-open staged items. No D1 action. (Note: the prior scan's `rescreen-LLY-D-20260612` was due 6/12 — D2 handles it on its next run.)

---

## ANALYSIS — REGIME CHECK

The window continues the de-escalation/relief theme into a third up-session. Walked against the high bar:

- **shock_overlay (Iran) — de-escalating; stays latent, escalation tail further reduced but NOT resolved.** A signed deal is signaled (~80% per a US official) and crude fell another ~3% (WTI $84.88), but the **deal is unsigned and the two sides published contradictory terms** — a one-headline relief that can re-reverse. The overlay **stays latent** (not removed); the acute-supply-shock branch is materially less likely than a week ago. The router-relevant escalation bar (a fresh flare with a sustained crude breakout >~$95–100) is the *opposite* of what the window delivered.
- **inflation / policy axis — marginally softer at the energy margin, no flip.** The continued crude drop + **UMich 1yr inflation expectations 4.8%→4.6% / 5-10yr 3.9%→3.4%** trim the energy-driven CPI impulse and the front-loaded-hike tail at the margin. But the standing M1b axis (reaccelerating inflation / hawkish / stagflation-tilt) is set on weight of evidence, expectations remain well above the 2.8–3.2% norm, and a **Dec 25bps hike remains the base case** into **FOMC 6/16–17 (Warsh's first meeting)**. **No axis flip** — the window softens an *input* (energy/expectations), not the axis.
- **risk_sentiment axis — the Wed/Thu whipsaw settled into a modest grind higher; one week does not flip a monthly axis.** Three sessions: broad −2% (Wed) → broad +2% (Thu) → +0.5% (Fri). SPY Trend still NEUTRAL, breadth HEALTHY. Friday's narrowing (Dow > Nasdaq; ADBE drag; SpaceX siphoning tech liquidity) is a low-amplitude rotation, not a trend break. **Watch** the run-up to FOMC for whether the tape holds.
- **Per-strategy activation — no flip implied.** B (post-event mispricing) is unaffected by the calmer two-way tape → ACTIVATE; C is FOMC-gated (6/16–17 ahead, queued); A is already DNA; D is long-horizon ACTIVATE; E is deferred. No development in the window changes any activation state.

**Default NO — no inter-monthly router review recommended.** The window *confirms* the standing 6/1 stagflation/hawkish/latent-shock axis and validates that shock_overlay was latent rather than escalating. **Monitor into FOMC 6/16–17 (the binding near-term event):** (a) Iran — whether the disputed-terms deal is actually *signed* (crude / Hormuz traffic the tells); (b) **FOMC** — Warsh's first meeting and whether the Dec-hike base case is reinforced or shifted; (c) risk_sentiment — whether the modest grind holds or the SpaceX-IPO liquidity event distorts breadth.

*(Frontier-LLM capability check — Saturday rotation [multi-agent debate], 1 HF `paper_search` run, concise, limit 5: nearest results — "Demystifying Multi-Agent Debate: The Role of Confidence and Diversity" 2601.19921 (2026-01-09), "Can LLM Agents Really Debate?…" 2511.07784 (2025-11-11), "DEBATE: A Large-Scale Benchmark…" 2510.25110, "LLM-Consensus…" 2410.20140, "…Equitable Cultural Alignment" 2505.24671. All pre-date the scan window (newest 2026-01-09); nothing published inside 6/11→6/13, no Tier-1 architectural delta, new failure mode, or Tier-2 numerical contradiction → silent per protocol; no Decision_Log capture.)*

---

## RECOMMENDED ACTIONS

The downstream D2 routine reads this section verbatim and converts each bullet into an order / live-file edit / queue entry.

- **Exits triggered:** **NONE.** No mechanical convergence-target hit (AZO closest at −2.6% below; ZBRA −13.5%, HCA −12.6%), no time-based exit due (earliest HCA 2026-06-27), no per-strategy kill-flag (B drawdown 0.00% at high-water mark, D −2.85%; all flags false), no judgment-laden invalidation trip. No reconciliation item outstanding (the 0.0007-sh IBM dust is immaterial; the 6/12 RTX DRIP +0.0006 sh is already reconciled in BQ).
- **New entry candidates:** **RH (Strategy B, B-LONG, FQ1 print −5.8%)** — clears the ≥5% / ≥$2B / event screen; **route to full B thesis construction in a separate session (D2 queue), 10-day window ~through 6/22–23.** Carry the caveat that the move appears **information-driven (operating profit −38.8%, net loss, low-end-only guide raise = margin/housing-demand deterioration)**, a weak basis for a B-long convergence — check the B sub-pattern taxonomy (info-driven guidance/margin-reset family) before any GO. **SPCX (+19% IPO debut)** — no strategy fit. **ADBE (−6.76% Day-0)** — A-queue (governance-driven, no admissible 60-day B catalyst), resolves at next M1 ACTIVATE.
- **Watchlist updates:** none requiring an edit today. **Note for the next M1 ACTIVATE evaluation (A-queue):** **ADBE** FQ2 Day-0 −6.76% — beat-and-raise + AI-ARR >$500M tripled **refutes the standing bearish framing at the print level**, but the Day-0 selloff is a **CFO-exit / dual-leadership-vacuum (no permanent CEO + no permanent CFO) governance overhang**, not demand — entry-quality complicated by governance + negative tape.
- **Router reviews:** none (high bar not met; the window *confirms* the standing 6/1 stagflation/hawkish/latent-shock axis and flips no activation; shock_overlay validated as latent, not escalating). **Monitor into FOMC 6/16–17:** (i) Iran — whether the disputed-terms deal is actually *signed* vs a re-reversing headline (crude / Hormuz traffic the tells); (ii) **FOMC** (Warsh's first meeting; Dec-hike base case); (iii) risk_sentiment — whether the modest grind holds after the broad −2%/+2% whipsaw and the SpaceX-IPO liquidity event. Continue to watch **HCA** (held B; time-exit 6/27, 14 days) and **ZBRA** (held B; recovering but −13.5% below target, 30 days to its 7/13 time-exit) — no invalidation on either.

2026-W25

# Weekly Post-Event Screen — Strategy B (deep research)

**Run:** Sunday 2026-06-21 MT (ISO week 2026-W25, the upcoming trading week).
**Screen window — prior 10 trading days:** **2026-06-05 → 2026-06-18** (Fri 6/19 was Juneteenth, market closed). Trading days in window: 6/5, 6/8, 6/9, 6/10, 6/11, 6/12, 6/15, 6/16, 6/17, 6/18.
**Universe filter:** US-listed common equity, market cap ≥ $2B, 30-day ADV ≥ $10M, close-to-close move ≥ 5% (either direction) on a day in the window, attributable to a public event.
**Magnitude provenance:** all moves marked *(IBKR)* are close-to-close from the IBKR connector `get_price_history` (authoritative); ADV$ is `avg_90d_usd_volume`. A handful are news-sourced where the connector boundary or a multi-day catalyst prevented a clean single-session anchor (marked *(news)*).

## Operating context (binds the screen)

- **Strategy B router = ACTIVATE** (`state.current_regime`, last set 2026-06-03): SPY Trend NEUTRAL (≠ DOWN), VIX not HIGH. B entries are admissible this week. The monthly M1 router has not been re-evaluated since 6/3.
- **Macro caveat (material to B).** Two risk-off catalysts sit inside the window: (i) the **6/5 jobs print** (hot NFP → higher-for-longer; a semiconductor/AI-capex pullback day), and (ii) **Warsh's first FOMC on 6/17**, which read hawkish — the market took it as signalling a **rate hike later in 2026** and sold off into 6/17–6/18. SPY Trend is still judged NEUTRAL (so B stays active), **but B's own router rationale warns that in/near macro-cascade conditions "overreaction" is hard to distinguish from regime change.** Any event-day move landing on 6/5, 6/17, or 6/18 carries an FOMC/jobs-beta component that must be decomposed before a mean-reversion thesis is credited (binds KR, ACN, INTC most directly — all 6/18).
- **Open positions (exclusions/dedup).** Strategy A: **none open** → the "exclude open A name" and A↔B simultaneous-holding constraints have no live conflict this week. Open Strategy B names (not new-entry candidates): **AZO, HCA, MDT, ZBRA** (TJX closed 6/10 on convergence; MDT filled 6/17; D book: RTX, DIS). None overlap the candidates below.
- **"NO-GO records are context, not barriers."** Names carrying a prior-window NO-GO are re-examinable on fresh evidence and are surfaced below; they are not auto-excluded. Where fresh analysis does not overturn the decisive flaw, they are listed as *resolved context* and are NOT re-ranked into the actionable shortlist (re-queuing a robust NO-GO would only re-derive the same disposition and burn a D2 cycle). INTC is a special case: it carries a 6/8 NO-GO on a *different* catalyst and a *fresh* 6/18 rumor-pop event — surfaced as a new candidate.
- **Methodology note.** This window was partially pre-screened by the daily D1→D2 pipeline (ACN, GIL, and the 6/8 INTC catalyst were minted and adjudicated daily). This W2 reconciles that record into the full universe, **adds the large-cap movers the daily earnings cadence did not adjudicate** (ORCL, ADBE, KR, and the non-earnings M&A/dilution/regulatory movers), verifies magnitudes against IBKR, and ranks only what remains actionable. Mid-June is a light, off-cycle earnings period; the universe is moderate and skewed toward capital-action and M&A events.

---

# PART 1 — Qualifying universe (≥5% close-to-close, event-driven, ≥$2B, ADV≥$10M)

Sorted by event date, most recent first. "Day-0" = the close-to-close reaction session. Disposition reflects the `events.decision_log` record unless marked **FRESH** (not yet adjudicated → candidate for PART 2).

### A. Earnings / guidance events

| Ticker | Name | Day-0 | Event type | Move (c2c) | Dir | ADV$ | Disposition |
|---|---|---|---|---|---|---|---|
| **ACN** | Accenture | 6/18 | FQ3 FY26 print (beat) + **FY local-ccy growth-midpoint cut** + large cyber M&A spend | **−17.97%** *(IBKR)* | DOWN | $762M | NO-GO 6/18 (Pattern N; guidance/info-driven) |
| **KR** | Kroger | 6/18 | FQ1 print: margin compression from price investment | **−8.43%** *(IBKR)* | DOWN | $358M | **FRESH** |
| **CHWY** | Chewy | 6/11 | Day-after-earnings **analyst downgrades** (UBS $32→$24); earnings day 6/10 was only −2.06% | **−6.06%** *(IBKR)* | DOWN | $168M | **FRESH** (analyst-action driver, not the print) |
| **ADBE** | Adobe | 6/12 | FQ2 print (beat+raise) but **surprise CFO departure (Dan Durn)** + ARR-guide nuance | **−6.76%** *(IBKR)* | DOWN | $1.17B | **FRESH** |
| **ORCL** | Oracle | 6/11 | FQ4 print (beat) but **$55.7B capex / deeply negative FCF / cloud-margin pressure** | **−8.53%** *(IBKR)* | DOWN | $4.86B | **FRESH** |
| **SJM** | J.M. Smucker | 6/9 | Fiscal Q4 earnings beat (adj EPS $2.77 vs $2.64) | **+10.44%** *(IBKR)* | UP | $206M | **FRESH** |
| **SAIL** | SailPoint | 6/9 | Q1 beat but **weak FY guidance** | **−11.48%** *(IBKR)* | DOWN | $54M | **FRESH** |
| **WIX** | Wix.com | 6/8 | **Cut FY bookings outlook** to low-teens growth | **−7.98%** *(IBKR)* | DOWN | $108M | **FRESH** (near-expiry — see PART 2) |
| **LULU** | lululemon | 6/5 | FY guidance cut (reported 6/4 AMC) — window-boundary | **~−8.6%** *(news)* | DOWN | (boundary) | NO-GO (adjudicated; was queued `thesis-LULU-B-20260608`) |

### B. Non-earnings event movers (capital actions, M&A, rumor, regulatory)

| Ticker | Name | Day-0 | Event type | Move (c2c) | Dir | ADV$ | Disposition |
|---|---|---|---|---|---|---|---|
| **INTC** | Intel | 6/18 | **Trump Truth Social post** ("Apple agreed to work with Intel… chips in America") — unconfirmed | **+10.64%** *(IBKR)* | UP | $17.8B | **FRESH** (rumor-pop; 6/8 NO-GO was a different catalyst) |
| **QS** | QuantumScape | 6/18 | Multi-year solid-state-battery R&D pact with Honda | **+16.52%** *(IBKR)* | UP | $177M | **FRESH** (speculative pre-revenue — see PART 2 exclusions) |
| **LEGN** | Legend Biotech | 6/18 | Priced **$226M ADS offering @ $29.35** (dilution) | **−16.68%** *(IBKR)* | DOWN | $74M | **FRESH** (biotech dilution — marginal fit) |
| **GIL** | Gildan Activewear | 6/16 | **Jehoshaphat short report** (alleged channel-stuffing; ~$510M excess inv.; governance) | **−18.77%** *(IBKR)* | DOWN | $74.6M | NO-GO 6/16 (Pattern N + 4d-adjacent governance overhang) |
| **MRVL** | Marvell | 6/15 | New CFO (Dan Durn, ex-ADBE) + **pending S&P 500 inclusion** (eff. 6/22) | **+10.43%** *(IBKR)* | UP | $12.8B | **FRESH** (index-inclusion + personnel — see PART 2) |
| **SMCI** | Super Micro | 6/10 | Announced **~$7B stock/securities raise** (dilution) | **−27.98%** *(IBKR)* | DOWN | $1.5B | **FRESH** (dilution + fraud/governance overhang — exclude) |
| **ELF** | e.l.f. Beauty | 6/9 | Product launch (e.l.f. Hair) + Raymond James Strong Buy — part of a multi-day rally | **+6.48%** *(IBKR, biggest single day)* | UP | $219M | **FRESH** (no clean single-event Day-0 — exclude) |

### M&A targets / acquirers (≥5% but merger-arb or strategic-integration — see PART 2 exclusions)

| Ticker | Name | Day-0 | Event | Move | Dir | Fit |
|---|---|---|---|---|---|---|
| NUVL | Nuvalent | 6/9 | GSK to acquire ~$10.6B ($124/sh cash, ~40% premium) | +39.28% *(IBKR)* | UP | Merger-arb — excluded |
| ROKU | Roku | 6/12 | Sale-talks → Fox $22B takeover (Roku = target, $160/sh) | +20.08% *(IBKR)* | UP | Merger-arb — excluded |
| FOXA | Fox Corp | 6/15 | **Acquirer** of Roku (~$22B) — overpay/dilution concern | −16.84% *(IBKR)* | DOWN | Strategic-integration, multi-quarter info — excluded |

### Regulatory / binary-clinical (≥5% but binary catalyst — B mechanism mismatch, SP5)

| Ticker | Name | Day-0 | Event | Move | Dir | Fit |
|---|---|---|---|---|---|---|
| QURE | uniQure | 6/17 | FDA agreed AMT-130 data can support accelerated-approval BLA (Huntington's) | +78.4% *(IBKR)* | UP | Binary regulatory; mcap crossed $2B *only on the pop* (pre-pop ~$1B) — excluded |
| MRNA | Moderna | 6/17 | Constructive FDA briefing docs ahead of 6/18 VRBPAC mRNA-flu vote | +11.55% *(IBKR)* | UP | In-window binary catalyst (the 6/18 vote itself) — SP5 — excluded |

### C. Evaluated but sub-threshold / mechanically ineligible (NOT in qualifying universe)

- **JBL** (Jabil) — FQ3 beat-and-raise (6/17 BMO); spiked intraday to an all-time high $428.93 then fully reversed → **close-to-close only −0.14%** → criterion-1 fail. (A close-based screen correctly excludes it; an intraday-high screen would have flagged it.)
- **LEN** (Lennar) — Q2 reported **6/11 AMC**; reaction day **6/12 = −4.90%** → just under the 5% gate. (The ~6/16 date floated in the daily feed was wrong; the 6/17/6/18 wiggles were not earnings.)
- **INGR** (Ingredion) — **acquirer** of Tate & Lyle (announced 6/8); INGR's own move 6/8 was **−0.32%** (max in-window ~+2%) → fail. (The +43% mover was the UK target on the LSE.)
- **CPRX** (Catalyst Pharma) — Angelini $4.1B cash deal ($31.50/sh) was announced **5/07, outside the window**; stock now pinned at the deal price (~0% daily moves in-window) → no in-window event-day ≥5% move.
- **KMX** (CarMax) — earnings 6/17 −8.98% **then** 6/18 +13.14% rebound on upgrades; the move round-tripped over two sessions → net signal muddled, treated as non-actionable (not a clean single-direction post-event mispricing).

---

# PART 2 — Ranked actionable shortlist

The downstream **W4** routine reads this PART 2 verbatim and enqueues thesis-construction entries to `state.open_queue` (PENDING_ANALYSIS); D2 runs them. **Each ranked name therefore becomes a D2 thesis-construction task.** W4 should order the queue by **days-remaining (fewest first)** so D2 prioritizes the names whose entry window closes soonest.

**Default assumption throughout: the market reaction is correct.** A candidate earns a rank only where a *specific, public, non-sentiment* reason to suspect over/under-shoot exists, with a criterion-3-admissible convergence target (a numeric price level or a closed-list event: next earnings / next FDA decision / next FOMC / S&P-500·Russell-1000·Nasdaq-100 inclusion). Several names below are constructed despite a likely-NO-GO read — the screen surfaces fresh, unadjudicated movers; the thesis session resolves them.

**Days-remaining in the 10-trading-day entry window** (sessions still available to enter, from 6/22): WIX ≈1 (closes 6/22) · SJM, SAIL ≈2 (6/23) · ORCL, CHWY ≈4 (6/25) · ADBE ≈5 (6/26) · KR, INTC ≈9 (7/2).

### Tier: TOP-5 (actionable — W4 should queue)

**#1 — ORCL (Oracle) — LONG capex-panic-overshoot candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** LONG; modest. ORCL fell −8.53% on an earnings *beat*; the selloff is a capital-intensity re-rating ($55.7B capex, deeply negative FCF) rather than a demand/bookings miss. Hypothesis: the market is extrapolating near-term FCF drag while under-weighting the AI-cloud RPO/backlog that the capex funds — a candidate over-shoot of the dilution/FCF math.
- **(b) Supporting public information:** Q4 beat (EPS $2.11 vs ~$1.95; rev $19.2B +21%); the negative reaction is explicitly tied to the capex/funding plan and cloud-gross-margin commentary — public and quantified.
- **(c) Convergence indicators to watch:** RPO/backlog disclosure and any reaffirmation of cloud-margin trajectory; price recovery toward the pre-print ~$201 level; sell-side response — *mass PT cuts with ratings maintained* = SP6 NO-GO, whereas an undershoot with maintained bull theses is the LONG opening.
- **(d) Days remaining:** Day-0 6/11 → window closes **6/25 (~4 sessions)**.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk:** the FCF/capex concern is a genuine multi-quarter free-cash-flow re-rating (information-driven), and any LONG continuation on AI-cloud backlog is **Strategy A multi-quarter territory (B-vs-A foreclosure)**. Leans NO-GO unless a clean technical/sentiment over-shoot component can be isolated.

**#2 — KR (Kroger) — LONG oversold-bounce candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** LONG; modest. A −8.43% drop in a defensive, low-multiple grocer on a *self-inflicted* margin trade-off (price investment to defend share) can over-shoot if the market treats a deliberate margin choice as a demand problem.
- **(b) Supporting public information:** in-line EPS / revenue beat with weak profit guidance driven by price cuts (public). Grocery is non-cyclical; the share-defense rationale is management-stated.
- **(c) Convergence indicators to watch:** comp-sales trajectory vs WMT/ALDI; gross-margin stabilization commentary; price recovery toward the pre-print level; sell-side cut-vs-maintain pattern.
- **(d) Days remaining:** Day-0 6/18 → window closes **7/2 (~9 sessions)** — most runway; also the freshest, lowest-info-decay candidate.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk:** margin compression from a structural price war is multi-quarter to refute (SP4c / SP6 territory); and the 6/18 move carries an FOMC-beta component (decompose). Leans NO-GO but has the cleanest "defensive name over-shoot" candidacy.

**#3 — INTC (Intel) — SHORT rumor-pop-fade candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** SHORT; the +10.64% is explicitly **sentiment/rumor-driven** (an unconfirmed Trump Truth Social post), with no confirmed fundamental change — the textbook information-vs-sentiment case B exists to exploit on the short side.
- **(b) Supporting public information:** the move's sole driver is the social-media post; no Apple or Intel confirmation, no contract, no filing. Absent confirmation, the pop should fade toward the pre-rumor level.
- **(c) Convergence indicators to watch:** any official Apple/Intel confirmation (would *ratify* the move → invalidate the short); fade back toward the pre-post price; volume normalization.
- **(d) Days remaining:** Day-0 6/18 → window closes **7/2 (~9 sessions)**.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk:** binary — if the rumor is confirmed, a short faces a squeeze. The rev-13 short-side stop-loss (close on +25% from short entry) and borrow-cost rules apply. Poor asymmetry if confirmation odds are non-trivial; the thesis must size the binary. INTC's 6/8 NO-GO is context, not a barrier (different catalyst).

**#4 — ADBE (Adobe) — LONG beat-but-CFO-exit overshoot candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** LONG; modest. ADBE fell −6.76% despite a beat-and-raise; the marginal driver was a **surprise CFO departure (Dan Durn → Marvell)** plus ARR-guide nuance. A personnel/governance shock can over-penalize a fundamentally beating name.
- **(b) Supporting public information:** Q2 beat + raised guide (public); the CFO exit is a discrete, public, one-time event whose fundamental read-through is bounded.
- **(c) Convergence indicators to watch:** CFO-succession clarity; reaffirmation of ARR guidance; price recovery; sell-side reaction (a clean "personnel-only" cut that maintains theses supports the LONG; a thesis-level cut on monetization strategy does not).
- **(d) Days remaining:** Day-0 6/12 → window closes **6/26 (~5 sessions)**.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk:** if the decline is really about the deliberate freemium/price-deferral monetization choice (a strategic information signal, not a personnel blip), it is information-driven and correctly priced. Direction-ambiguous; moderate NO-GO probability.

**#5 — CHWY (Chewy) — LONG analyst-downgrade-overshoot candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** LONG; modest. The qualifying −6.06% was a **next-day analyst-downgrade** move (UBS $32→$24), not the print (earnings day was only −2.06%) — a PT-cut-driven dip that can over-shoot if it is sentiment ratification rather than new information.
- **(b) Supporting public information:** Q1 beat (net sales $3.36B +7.7%, margin expansion) with a cautious organic-growth guide; the downgrades post-date the public print.
- **(c) Convergence indicators to watch:** whether the post-print stock sits **below** a cut-PT cluster (LONG undershoot opening) or **at/within** it (SP6 NO-GO); active-customer / autoship trajectory.
- **(d) Days remaining:** Day-0 6/11 → window closes **6/25 (~4 sessions)**.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk:** classic SP6 (valuation-reset-not-narrative-reset) profile — if the stock is at/within the cut-PT cluster there is no asymmetric anchor. Moderate-to-high NO-GO probability.

### Tier: rest (near-expiry — queue only if W4 can run them 6/22, else conservative-default skip)

**#6 — SAIL (SailPoint) — likely NO-GO (software guide-cut)**
- LONG oversold read on −11.48%, but the driver is a **weak FY guide** despite a Q1 beat → information-driven (SP6 / SP4b software-deceleration territory), multi-quarter to refute. Day-0 6/9 → closes **6/23 (~2 sessions)**. Construct only if D2 can run it 6/22; else conservative-default decline. Lower liquidity (ADV $54M) but clears the $10M gate.

**#7 — SJM (J.M. Smucker) — likely NO-GO (positive-reaction staples beat)**
- +10.44% on an earnings beat → positive-direction reaction; LONG is information-driven and any continuation is A territory, SHORT fails on no overshoot if sell-side ratifies = **SP1 risk**. Day-0 6/9 → closes **6/23 (~2 sessions)**. Construct only if runnable 6/22; else decline.

**#8 — WIX (Wix.com) — effectively expired**
- −7.98% on an FY-bookings **guide cut** → information-driven software-deceleration (SP6/4b). Day-0 6/8 → window closes **6/22 (~1 session)**. Effectively no runway; surface for completeness, **conservative-default decline** unless D2 runs it at the 6/22 open.

### Not re-ranked — resolved context this window (NOT queued)

Per "NO-GO records are context, not barriers," these were re-examined; fresh evidence does **not** overturn the decisive flaw, so they are **not** re-queued:
- **ACN** (6/18, −17.97%) — NO-GO Pattern N: FQ3 beat but FY guidance-midpoint cut + large cyber-M&A spend; selloff information-driven, multi-quarter to refute.
- **GIL** (6/16, −18.77%) — NO-GO Pattern N + 4d-adjacent: Jehoshaphat short-report alleging channel-stuffing + governance overhang; structural/litigation, multi-quarter to refute.
- **INTC 6/8 catalyst** — prior NO-GO (SP1-positive-noncprint + Pattern-N overlay); the *6/18 rumor pop* is the fresh, separately-ranked event (#3 above), not this one.
- **LULU** (6/5, ~−8.6%) — boundary mover already adjudicated NO-GO via the queued 6/8 thesis (SP4c/SP6 guide-cut).

### Excluded by structural fit (NOT queued)

- **M&A targets / acquirer** — NUVL (GSK target, +39%), ROKU (Fox target, +20%): deal price caps the move, merger-arb not B mean-reversion, and an announced deal is not an admissible criterion-3 catalyst. FOXA (−16.8%, the acquirer): a ~$22B strategic acquisition is a multi-quarter integration re-rating (information-driven), not a digestible over-shoot.
- **Binary regulatory / clinical** — QURE (+78%, FDA accelerated-approval pathway; also crossed $2B only on the pop), MRNA (+11.6%, ahead of the 6/18 VRBPAC vote = an in-window binary catalyst, SP5): pure-information / step-function events; "market is correct" default is strongest, B mechanism mismatch.
- **Dilution-with-overhang** — SMCI (−28%, $7B raise layered on an active fraud/governance overhang = SP4d): the dilution is not a clean technical-supply over-shoot (unlike a vanilla secondary) because it compounds a structural overhang. LEGN (−16.7%, $226M ADS offering): biotech dilution funding operations + pipeline-binary exposure — marginal technical-supply fit, low ADV; defer.
- **Speculative / no-clean-catalyst-day** — QS (+16.5%, Honda R&D pact; pre-revenue solid-state story = sentiment, no fundamentals to anchor mean-reversion), ELF (+6.5%, multi-day momentum rally with no single Day-0), MRVL (+10.4%, CFO hire + already-known S&P-500 inclusion eff. 6/22 — index front-running could fade post-effective-date but the move is multi-driver and the inclusion is the *acquirer* of demand, not an over-shoot to short cleanly).

---

## Summary for W4

- **Queue (thesis-construction), ordered by days-remaining (fewest first so D2 prioritizes):**
  1. **WIX** — software guide-cut; **~1 session (closes 6/22)** — likely-NO-GO, queue only if runnable at the 6/22 open, else conservative-default decline.
  2. **SJM** & **SAIL** — staples beat (SP1 risk) / software guide-cut; **~2 sessions (6/23)** — likely-NO-GO; same near-expiry caveat.
  3. **ORCL** (LONG capex-panic), **CHWY** (LONG downgrade-overshoot) — **~4 sessions (6/25)**.
  4. **ADBE** (LONG CFO-exit overshoot) — **~5 sessions (6/26)**.
  5. **KR** (LONG oversold), **INTC** (SHORT rumor-fade) — **~9 sessions (7/2)** — most runway.
- **Do not queue:** the resolved-context NO-GOs (ACN, GIL, INTC-6/8, LULU) and the M&A / binary-regulatory / dilution-with-overhang / speculative structural misfits above.
- **Open-B dedup:** AZO, HCA, MDT, ZBRA are open — not new-entry candidates. No open A → no A↔B exclusion this week.
- **Regime flag for the thesis sessions:** decompose any 6/5, 6/17, or 6/18 event-day move for the jobs/FOMC-beta component before crediting mean-reversion (binds KR, INTC most directly). B router is ACTIVATE but the 6/17 hawkish-FOMC raises regime-shift risk that the next M1 has not yet re-scored.
- **Conviction posture:** this remains a high-NO-GO-probability window — most movers are guidance/information-driven (KR/ORCL/ADBE/WIX/SAIL), positive-reaction-ratified (SJM), rumor/sentiment (INTC), or structurally misfit (M&A/clinical/dilution). The shortlist is surfaced for fresh adjudication, not as conviction LONGs/SHORTs; the default (market-correct) leans NO-GO on most.

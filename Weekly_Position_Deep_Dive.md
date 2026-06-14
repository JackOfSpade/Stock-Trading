2026-W24

# Weekly Position Deep-Dive — W3
**ISO Week:** 2026-W24 (Sun 2026-06-14 run) | **Research as of:** Sun 2026-06-14 (after the trading week Mon 6/8 → Fri 6/12; next session Mon 6/15 cash open)
**Scope:** Strategy B open positions — **HCA, ZBRA, AZO**. Strategies A / C / E flat (zero open positions). Strategy D excluded per W3 spec (RTX and DIS covered in M3).
**Book change since last W3 (prior run):** **TJX closed** during the week (it was within ~2.4% of its $164.50 convergence target last cycle and reached it). The B book is now three longs (down from four). `state.current_positions` confirms: HCA, ZBRA, AZO (B) + RTX, DIS (D, out of scope).
**Sources:** BigQuery `state.current_positions` (open book + convergence/time-exit/conviction), `state.current_regime` (router), `events.decision_log` (GO thesis entries: HCA 2026-04-27, ZBRA 2026-05-13, AZO 2026-05-27; ZBRA mid-window HOLD checkpoint 2026-06-09); Strategy.md (B exit rules §"Exit rules and thesis invalidation"); Operating_Protocols.md; B_Sub_Pattern_Taxonomy.md; last cycle's Weekly_Position_Deep_Dive.md for original invalidation criteria. IBKR connector `get_price_history` (dated daily bars — authoritative closes) + `get_price_snapshot` (vol/52-wk context). Tavily / web deep-research 6/14 (per-position citations inline).

> **Data-integrity note:** `get_price_snapshot` was again one session stale on this Sunday pull (its `last`/`prior-close` returned the **Thu 6/11** close for HCA $378.51 and AZO $3,081.62). All marks below use the authoritative **Fri 6/12** closes from `get_price_history` dated bars (HCA **$387.18**, ZBRA **$228.42**, AZO **$3,116.30**). Standing recommendation for D1/D2 stands: prefer `get_price_history` dated bars over `get_price_snapshot` `prior-close` for convergence-proximity precision on weekend/pre-market pulls.

---

## IMMEDIATE-ACTION: NONE

No open position has a tripped invalidation criterion this week. All three are **HOLD**. The two big single-week moves — HCA's **+7.2% rally** off the 6/8 low and ZBRA's **−7.4% one-day drop on 6/10** — are both **non-thesis events**: HCA's rally was a healthcare-sector breadth thrust + a Michael Burry long disclosure (supportive of, not contrary to, the thesis), and ZBRA's drop was market/sector beta (hot CPI + Iran escalation + AI/chip selloff) with **no ZBRA-specific news**. Strategy.md gives B **longs** no price stop, so neither an adverse nor a favorable mark is an exit trigger absent news. No W4 exit-staging is owed this cycle. AZO remains within ~2.7% of its $3,200 convergence target (D1/D2 first-close-above watch); HCA (time-exit **6/27**, ~13 days) and ZBRA (time-exit **7/13**, ~29 days) are both far from target and most-likely resolve on their time-based exits.

---

## Strategies A, C, E — No Open Positions

- **Strategy A:** Zero open. Router **DO-NOT-ACTIVATE** (`state.current_regime` STRATEGY_ACTIVATION A, as-of 2026-06-03, unchanged from April). Nothing to deep-dive.
- **Strategy C:** Zero open structures. Router **HYBRID ACTIVATE** (div-C-202605-1, MIXED). The **FOMC 2026-06-16/17** meeting is the gating event window this week — relevant to C *entry* screening (W1), not to any open position (none). Nothing open to deep-dive.
- **Strategy E:** Zero open pair positions. Router **ACTIVATE but execution-feasibility-deferred** at current book size (ETF-substitution-required per M3 / div-E-202605-1). Nothing to deep-dive.

---

## Strategy B — Open Position Deep-Dives

**Router state:** B router **ACTIVATE** (`state.current_regime`: STRATEGY_ACTIVATION B = ACTIVATE; SPY_TREND = NEUTRAL ≠ DOWN; EQUITY_BREADTH = HEALTHY; SUSTAINED_INVERSION NOT-SUSTAINED). The 6/10 risk-off (hot May CPI → yields/Iran → AI-chip selloff; Dow −953 intra-week) did not flip the technical clauses (Trend ≠ DOWN, VIX ≠ HIGH on a closing basis); formal re-call is owned by the monthly M1. FUNDAMENTAL_AXIS integrative read: **stagflation-tilt + risk-on** (decelerating growth, reaccelerating inflation, hawkish policy, risk-on sentiment, latent shock) — the week's hot-CPI print reinforces the reaccelerating-inflation axis.

**B book — corrected closes (Fri 2026-06-12, `get_price_history`):**

| Position | Status | Fill date | Fill px | Cost basis (incl. comm) | Shares | Convergence target | 6/12 close | Δ vs cost | Δ to target | Time-based exit | Days to time-exit | Conviction |
|----------|--------|-----------|---------|--------------------------|--------|--------------------|-----------|-----------|-------------|-----------------|-------------------|------------|
| HCA  | OPEN | 2026-04-28 | $433.46 | $28.11 | 0.0642 | $442.85 | **$387.18** | **−10.7%** | +14.4% | 2026-06-27 | **~13** | MEDIUM-LOW |
| ZBRA | OPEN | 2026-05-14 | $249.52 | $37.90 | 0.1505 | $264.00 | **$228.42** | **−8.5%** | +15.6% | 2026-07-13 | ~29 | MEDIUM-HIGH |
| AZO  | OPEN | 2026-05-27 | $3,110.69 | $37.99 | 0.0121 | $3,200 | **$3,116.30** | +0.2% | +2.7% | 2026-07-24 | ~40 | MEDIUM-LOW |

**Cross-cuts:** Three concurrent B longs spanning Health Care Facilities (HCA), Communications Equipment / AIDC (ZBRA), and Automotive Retail (AZO). Per Strategy.md rev-35 (owner directive) there is **no per-GICS holdings-count cap**; concurrent-position correlation is monitored (KL #12 metric (d)), never capped. With TJX's exit the book is now three single-sector-distinct names — the most diversified (and smallest) the B book has been this cycle.

---

### HCA Healthcare (OPEN — thesis intact and re-strengthening; +7.2% sector-rotation rally narrows the loss; still ~14% below target with ~13 days left)

**1. Current thesis status.** Thesis (Q1-print overshoot reverts ~25% toward $442.85) **HOLDS** and the week was the first clearly *favorable* one. HCA rallied every day after a Mon 6/8 low: IBKR closes 6/8 **$361.32** (week/13-wk low) → 6/9 **$374.90** → 6/10 **$373.34** → 6/11 **$378.51** → 6/12 **$387.18**, a **~+7.2%** recovery off the low. Spot is now ~**−10.7%** vs the $433.46 cost basis (improved from −14.1% last cycle); the $442.85 target sits ~**+14.4%** above the 6/12 close (narrowed from +19.0%). Critically, the rally was **not** an HCA-specific catalyst — it was a **healthcare-sector breadth thrust** (per SentimenTrader via Seeking Alpha, 6/11/2026: healthcare's strongest 5-day run vs. the S&P 500 since 2009) plus BofA-flagged sector-leading **healthcare ETF inflows** (Seeking Alpha, 6/10/2026). This is the oversold-mean-reversion the Strategy-B thesis predicted finally getting a sentiment tailwind, rather than thesis fulfillment via fundamentals.

**2. Competitive landscape.** No new peer earnings prints this week (THC, UHS, CYH all reported Q1 in late-April/early-May, resolved at staging). **UHS** hit a 52-wk low ($140.76, 6/3) then presented at the Goldman Sachs 47th Global Healthcare Conference ~6/9, reaffirming 2–3% volume-growth targets with no deterioration (Yahoo Finance 6/8; Simply Wall St, Jun 2026). Positive adjacent read-through: **Alignment Healthcare (ALHC)** hiked guidance and jumped ~25% on 6/9 (ts2.tech 6/9), feeding managed-care/hospital sentiment. No peer issued negative guidance — criteria (iii)/(iv) remain cleared.

**3. Fundamental developments.** No HCA filing, guidance change, or business update in 6/8–6/12. The only HCA-specific item was operational color — HCA plans to hire ~3,000 staff in India by end-2026 for digital/IT functions (Nashville Business Journal via ad-hoc-news.de, 6/9) — thesis-neutral. **Stock-specific amplifier:** **Michael Burry (Scion) disclosed a new HCA long** (Substack post surfaced 6/9; Stocktwits 6/9), calling HCA an "insanely efficient compounder" and explicitly dismissing the $600–900M ACA-subsidy-expiration headwind as Street-overweighted — i.e., a high-profile articulation of the *same* overreaction thesis. Landed on the 6/9 +3.8% up-day. No new sell-side rating/PT action dated in-window; the rally was **not** analyst-driven (most recent visible: Bernstein Hold $413, BofA Hold — both pre-window; consensus mean PT still ~$510–518, Moderate/Strong-Buy skew).

**4. Sector / macro context.** The standing overhang is the **CMS proposed rule on Medicaid State-Directed Payments** (issued **5/20/2026** — *pre-window*; caps SDPs at 100% of Medicare in expansion states / 110% non-expansion, grandfathered through state-plan-years beginning on/after 1/1/2028; Forvis Mazars / Morgan Lewis / Modern Healthcare). This is a known, pre-existing, multi-year structural negative — **not a new in-week shock** — and the sector rallied *through* it (a "less-bad-than-feared"/oversold-positioning tell). Backdrop: a defensive rotation into healthcare ahead of **FOMC 6/16–17**; XLV closed 6/12 at $153.81 after its best 5-day relative run since 2009. By Strategy.md rules, a favorable mark on already-priced policy is no more an exit trigger than an adverse one.

**5. Thesis-invalidation signals.**
- **(i) FY26 guide cut below floors ($76.5B rev / $15.55B adj EBITDA / $29.10 EPS): NOT-TRIPPED.** No 8-K, guidance reaffirmed; nothing in-window contradicts the frame.
- **(ii) HCA pre-announcement / negative business update: NOT-TRIPPED.** Only in-week HCA item (India hiring) is neutral; the Burry disclosure is thesis-supportive.
- **(iii) Peer sector-wide shortfall print: NOT-TRIPPED** (no new peer print; UHS reaffirmed at Goldman; ALHC raised).
- **(iv) UHS corroboration: CLEARED** (no adverse UHS development; reaffirmed targets).
No criterion tripped. Cumulative evidence moved the position **away from** invalidation this week.

**6. Time to thesis resolution.** Still tight on time. With **~13 days to the 6/27 time-exit** and the $442.85 target ~+14.4% above the 6/12 close, full convergence by 6/27 would require a further ~14% in under three weeks with **no scheduled HCA catalyst** before it (Q2 earnings ~7/23–7/24, *after* the exit; MarketChameleon/MarketBeat). The momentum is now favorable and the loss has narrowed materially, but the most-probable resolution remains the **6/27 60-day stale exit** — now at a meaningfully smaller loss than the −14% to −19% range of prior weeks if the sector bid holds.

**Recommendation: HOLD (to the 6/27 time-based exit).** No invalidation criterion (i)–(iv) tripped; the week's move is a favorable sector-rotation mark plus a supportive bull disclosure, neither of which is an exit trigger (and B longs have no profit-taking rule short of the convergence target, which is still +14.4% away). Convergence to $442.85 by 6/27 remains improbable absent a catalyst, so the **6/27 60-day time-exit is the cited resolution rule** (Strategy.md "Timeline expiry at 60 days from entry"). No W4 exit-staging this cycle — D1's daily sweep flags the time-exit hit for D2 staging on/after 6/27. **Watch:** if the breadth-thrust momentum carries HCA to a close ≥ $442.85 before 6/27, D1/D2 stage the convergence SELL on the first close-above (META/IBM first-close-above precedent) — the favorable path that would close this at a gain.

---

### Zebra Technologies (OPEN — thesis intact; 6/10 −7.4% drop was macro beta, not news; gap-fill math harder)

**1. Current thesis status.** Thesis **HOLDS** — no new ZBRA-specific negative information in 6/8–6/12. The defining event was a **−7.4% one-day drop on Wed 6/10** ($234.20 → **$216.79**), which deep-research attributes entirely to **market/sector beta**, not a ZBRA event: a broad risk-off day on a hot **May CPI print** (highest in 3 years, third straight monthly acceleration; CNBC/BLS 6/10), **Iran-war escalation** headlines, and a continuing **AI/chip-valuation selloff** drove "Dow −953 / S&P −1.6% / tech −2.3%, industrials leading down" (WSJ 6/10). ZBRA — high-beta (~1.6), industrial/AIDC, ~62% realized vol — sat squarely in the leading-down cohort. Confirming the beta read: ZBRA actually **rose +0.5% on 6/9 against a down tape**, then rebounded 6/11 (+2.6%) and 6/12 to **$228.42** as the market recovered. Per the 6/12 close the position is ~**−8.5%** vs the $249.52 cost basis; the $264 target sits ~**+15.6%** above spot — a wider gap than last cycle after the 6/10 air-pocket.

**2. Competitive landscape.** No adverse peer signals; structurally supportive. **Honeywell** continues exiting AIDC — its PSS (mobile-computing/barcode/printing) division sale to **Brady Corp for $1.4B** reduces direct competitive intensity (DC Velocity, prior-period). Motorola Solutions launched "SafetyCam" 6/4 (adjacent retail-safety, not core AIDC overlap). No negative 6/8–6/12 read-through from Datalogic, Cognex, Ciena, or Lumentum on AIDC/enterprise-mobile-computing demand.

**3. Fundamental developments.** No SEC filings of substance (routine incentive-plan 8-K/S-8, routine Form-4/144 insider sales), **no guidance change, no pre-announcement, no tariff disclosure**, and — critically for criterion (iv) — **no new sell-side rating/PT action dated 6/8–6/12.** The post-Q1 PT cluster remains the 5/13–5/14 batch (KeyBanc OW $305, Baird $310, Barclays $345, Citi $284, BNP $370, Truist $267) — pre-entry, already priced. The only in-week event was **NRF PROTECT (6/8–10, Grapevine TX)**, a routine retail trade show, not a guidance event. FY26 framework unchanged (EPS $18.30–$18.70; 10–14% sales growth; ~22% adj-EBITDA margin; Q1 organic +4.3%).

**4. Sector / macro context.** Defined by the **Iran energy shock → hot CPI → Fed-on-hold-into-6/17 → AI/chip selloff** complex (CNBC/WSJ/NYT 6/10). **Section 232 semiconductor tariffs** (25%, eff. 1/15/2026) remain a live *macro* theme with a 7/1/2026 data-center review pending (ITIF 6/4), and Trump modified 232 steel/aluminum/copper tariffs 6/10 — but **no ZBRA-specific tariff impact was disclosed**, so criterion (iii) is not engaged (general tariff noise is explicitly excluded by Strategy.md "general market moves").

**5. Thesis-invalidation signals.**
- **(i) FY26 framework reset (EPS < $18.30 mid / organic-rev guide < 4% / adj-EBITDA-margin reset / Q2 pre-announce): NOT-TRIPPED.** No guide change; framework intact.
- **(ii) Demand / customer-weakness pre-announcement: NOT-TRIPPED.** No pre-announcement; NRF PROTECT presence is neutral-to-positive.
- **(iii) Tariff-regime ZBRA-specific adverse disclosure: NOT-TRIPPED.** No ZBRA-specific tariff disclosure 6/8–6/12; only macro Section-232 noise.
- **(iv) Sub-pattern-1 cluster escalation (≥3 aggressive +10% PT raises): NOT-TRIPPED.** Zero new PT actions in-window.
No criterion tripped. The 6/10 move was macro beta (adverse mark without news), which B-strategy rules exclude as a trigger. (This corroborates the 2026-06-09 mid-window HOLD checkpoint already logged in `events.decision_log`.)

**6. Time to thesis resolution.** ~29 days to the 7/13 stale-exit; next hard catalyst (Q2 print) is **8/4 — after the exit**, so no in-window fundamental catalyst remains to force the gap-fill. Convergence now requires ~**+15.6%** from $228.42 in ~4 weeks with no scheduled company catalyst and a hostile rate/macro tape — materially less probable than at entry, and the 6/10 air-pocket widened the gap. The most-likely resolution is the **7/13 time-based exit** absent a sharp sympathy rally.

**Recommendation: HOLD.** No invalidation criterion (i)–(iv) tripped — the week produced no ZBRA-specific news; the only material price action (−7.4% on 6/10) was a market-wide, CPI/Iran/AI-driven selloff, i.e., an **adverse mark without thesis news**, which B-strategy rules expressly exclude as an exit trigger (cited rule: Strategy.md "Not exit-triggering: adverse mark-to-market without news (long positions only); general market moves"). Thesis intact; probability of reaching $264 by 7/13 has fallen further, but that is a sizing/calibration observation, not an invalidation. **Watch:** criterion (iv) for any incipient ≥3-firm aggressive PT-raise wave; otherwise resolution defaults to the 7/13 time-exit (D1 daily sweep → D2 staging).

---

### AutoZone (OPEN — thesis intact; range-bound at cost; target ~+2.7% away; PT-cut watch still de-escalated)

**1. Current thesis status.** Thesis **HOLDS**. AZO chopped in a tight $3,074–$3,138 closing range all week with intraday probes higher: IBKR closes 6/8 **$3,074.04** → 6/9 **$3,137.75** → 6/10 **$3,110.05** → 6/11 **$3,081.62** → 6/12 **$3,116.30**, with intraday highs to ~**$3,162** (6/9) and ~**$3,177** (6/10) that stalled just below the $3,200 target before fading. Spot sits ~**+0.2%** above the $3,110.69 cost basis; the immutable $3,200 target is ~**+2.7%** above the 6/12 close — essentially unchanged from last cycle. The week was **news-light in both directions**: no fresh catalyst to clear $3,200, and no deterioration. The pin is technical/sentiment (post-print digestion + caution into FOMC 6/16–17), with the repeated intraday pushes toward $3,177 showing latent buying interest stalling just under target.

**2. Competitive landscape.** No new peer prints in-window (auto-parts retailers reported Apr–May). Read-throughs remain **supportive**: **O'Reilly (ORLY)** reaffirmed FY26 comps +3.0–5.0% and *expanded its buyback* (~6/1; commercial +13%), next reports ~7/21; **Advance Auto (AAP)** beat EPS and *raised* FY guidance (biggest peer beat, stock +10.7% post-print); **Genuine Parts (GPC)** remains the laggard (revenue light) but no new in-week development. Net: resilient DIFM/commercial aftermarket demand — **no sector deterioration**, mildly thesis-confirming.

**3. Fundamental developments.** No material AZO-specific news 6/8–6/12 — no 8-K, no buyback/insider disclosure, no store/mega-hub or commercial press release dated in-window (routine Q3 10-Q for the period ended 5/9 was filed late May, pre-window). The mega-hub strategy (~156 operating, targeting ~300; commercial +10.4% domestic) is unchanged background from the 5/26 Q3 print. **Analyst action — the key check:** only **one** in-window action, **Argus (Bill Selesky) Maintains Buy (6/11)** — a *reiteration* (Argus's actual Buy upgrade with a $4,325 PT was 3/9). **No new PT cuts** continued the post-print 5/27–5/28 wave; **no PT is at/below spot** — the lowest target remains **Mizuho $3,200 (Neutral)**, still ~+2.7% above the $3,116 close.

**4. Sector / macro context.** No demand-shock macro event in-window. The risk tape steadied into week-end on "peace hopes" (S&P rebounded off its 50-DMA; Schwab 6/12). The standing overhang — **Mexico's Jan-2026 non-FTA auto-parts tariffs (5–50%)** + peso/FX — persists but **no new escalation crossed 6/8–6/12** (White & Case / mexicobusiness.news). Consumer-discretionary fundamentals are flagged as softening sector-wide (generic headwind, not AZO-specific). The market is positioned cautiously into **FOMC 6/16–17** (decision + May retail sales 6/17) — a plausible reason for the wait-and-see pin and the next sentiment inflection.

**5. Thesis-invalidation signals.**
- **(i) FY26 domestic SSS guide cut below 3% floor: NOT-TRIPPED.** No guidance update; AZO gives no formal SSS guidance; last data point (fiscal Q3 5/26) was +5.5% reported domestic SSS.
- **(ii) Structural US auto-parts demand disruption (EV/ICE): NOT-TRIPPED.** No such event; aging-parc/DIFM thesis intact; mega-hub expansion is the opposite signal.
- **(iii) International-to-domestic contagion in guidance: NOT-TRIPPED.** No quarterly guidance event in-window; no analyst note framing domestic contagion.
- **Sub-pattern-4a PT-cut-wave watch — NOT ESCALATED.** Escalation requires additional firms cutting **and** a PT taken to/below spot. In-window: **zero new cuts**; only an Argus Buy reiteration; lowest PT Mizuho $3,200 still **above** spot. Watch flag remains **LOWERED**.
None tripped.

**6. Time to thesis resolution.** ~40 days to the 7/24 stale-exit. With the 6/12 close at $3,116.30 the $3,200 target is only ~**+2.7%** away, and the intraday probes to ~$3,177 this week show the move is well within reach — but there is **no scheduled AZO catalyst before 7/24** (Q4 FY26 earnings ~late September, after exit), so resolution hinges on continued passive mean-reversion drift rather than a discrete event. A benign **FOMC 6/17** lifting discretionary risk appetite is the most plausible near-term unlock; supportive ORLY/AAP read-through and the still-overhead PT median (~$3,850–$4,000) provide pull.

**Recommendation: HOLD — APPROACHING TARGET.** No invalidation criterion tripped (i/ii/iii all NOT-TRIPPED) and the sub-pattern-4a PT-cut watch remains **de-escalated** (no new cuts, no PT at/below spot, Argus Buy reiteration 6/11). Convergence target $3,200 is only ~+2.7% above spot with ~40 days left — let the thesis run. **D1/D2 daily watch:** if AZO closes ≥ $3,200 on any session, stage the convergence SELL immediately per Strategy.md "Convergence target reached" (META/IBM first-close-above precedent).

---

## Cross-Position & Macro Context (week ending Fri 2026-06-12)

- **Tape / macro:** The defining event was **Wed 6/10's hot May CPI print** (highest in 3 years; third consecutive monthly acceleration) layered on **Iran-war escalation** and a continuing **AI/chip-valuation selloff**, producing a sharp mid-week risk-off (Dow −953 intraday; tech/industrials leading down; WSJ/CNBC 6/10) before a late-week "peace-hopes" recovery. This reinforces the regime's reaccelerating-inflation + hawkish-policy axis (FUNDAMENTAL_AXIS stagflation-tilt). High-beta/rate-sensitive names (ZBRA −7.4% on 6/10) bore the brunt; **defensive rotation lifted healthcare** (HCA +7.2% on the week, best XLV 5-day relative run since 2009). None of this flips a B criterion — the moves are macro marks, not position-specific news.
- **B router:** **ACTIVATE** confirmed (SPY Trend NEUTRAL ≠ DOWN; VIX ≠ HIGH on a closing basis; breadth HEALTHY). The 6/10 intra-week risk-off does not flip the technical clauses; the monthly M1 owns formal re-derivation. **FOMC 6/16–17 next week** is the dominant macro inflection for all three names' sentiment (esp. AZO consumer-discretionary and ZBRA rate-sensitive tech).
- **Portfolio correlation (KL #12):** three longs across three distinct GICS sub-industries (Health Care Facilities; Communications Equipment/AIDC; Automotive Retail) — the most diversified and smallest the B book has been this cycle after TJX's exit. Per rev-35 this is monitoring, not a cap.
- **Scheduled catalysts inside open-position windows:** **None position-specific before any exit.** HCA Q2 ~7/23–7/24 is after the 6/27 time-exit; ZBRA Q2 ~8/4 is after the 7/13 time-exit; AZO Q4 FY26 ~late-Sept is after the 7/24 time-exit. FOMC 6/16–17 is a general read-through, not a per-name B criterion.
- **Convergence proximity ranking (D1/D2 watch priority):** **AZO (+2.7% to $3,200)** is the only name within striking distance — first close ≥ target stages the convergence SELL. **HCA (+14.4%)** and **ZBRA (+15.6%)** are far from target; HCA's most-likely resolution is the **6/27 time-exit** (with favorable momentum that could yet reach target), ZBRA's the **7/13 time-exit** absent a sharp rally.

---

## Summary Recommendation Table

| Position | Status | To convergence (6/12 close) | Recommendation | Cited criterion / key watch |
|----------|--------|-----------------------------|----------------|------------------------------|
| HCA  | OPEN | +14.4% ($442.85; spot $387.18) | **HOLD — to 6/27 time-exit** | Criteria (i)–(iv) NOT-TRIPPED; no B price-stop. ~13 days to 2026-06-27 time-exit. +7.2% week was a healthcare breadth thrust + Burry long disclosure (6/9) — favorable mark, not thesis fulfillment; loss narrowed to −10.7%. Cited close rule at expiry: Strategy.md "Timeline expiry at 60 days." If a close ≥ $442.85 lands before 6/27, D1/D2 stage convergence SELL. No W4 action owed. |
| ZBRA | OPEN | +15.6% ($264.00; spot $228.42) | **HOLD** | Criteria (i)–(iv) NOT-TRIPPED; no ZBRA-specific news. The −7.4% on 6/10 is macro beta (CPI/Iran/AI selloff → adverse mark without news, not an exit trigger). ~29 days to 7/13 time-exit; no in-window catalyst. Resolution defaults to time-exit absent a rally. |
| AZO  | OPEN | +2.7% ($3,200; spot $3,116.30) | **HOLD — APPROACHING TARGET** | Criteria (i)–(iii) NOT-TRIPPED; sub-pattern-4a PT-cut watch **DE-ESCALATED** (zero new cuts; lowest PT Mizuho $3,200 still above spot; Argus Buy reiteration 6/11). Intraday probes to ~$3,177. D1/D2: first close ≥ $3,200 → stage convergence SELL. FOMC 6/17 = next inflection. |

**IMMEDIATE-ACTION: NONE.** No tripped invalidation criterion. All three positions HOLD. AZO is within ~2.7% of convergence (D1/D2 first-close-above watch); HCA carries favorable momentum into its 6/27 time-exit (loss narrowed to −10.7%); ZBRA holds through a macro-driven adverse mark toward its 7/13 time-exit. No W4 exit-staging owed this cycle.

2026-Q3

# Quarterly Regime Retrospective

> **Scope.** Retrospective for the prior calendar quarter, **Q3 2026 (July 1 – September 30, 2026)**, written by Q1 on 2026-10-02 (catch-up window = Q1's last completion 2026-07-01 → now, 92.95 days = exactly one quarter, so no missed quarter is owed). Part 1 characterises the market; Part 2 traces the regime router for the five ADOPTED strategies (A–E; F/G/H are REJECTED candidates with no Q3 deployment) against that characterisation. Figures marked *(derived)* were computed from raw series; everything else is a reported figure from the named source. Retrospective factbase only — no decision in this file is retroactive.

## PART 1 — Retrospective characterization of Q3 2026

### 1. SPY trend character

- **Return.** SPY 746.77 (6/30) → **762.63 (9/30)**, **+2.12% price** *(derived, IBKR daily bars; 9/30 close cross-checks the persisted `SPY_TREND` numeric exactly)*; the S&P 500 index returned +2.03% (First Financial Trust). The Q3 SPY dividend was not retrieved, so the total return is roughly 0.3–0.4 points higher but unverified. Month-ends: Jul 747.03 (+0.04%), Aug 767.05 (+2.68%), Sep 762.63 (−0.58%).
- **Path: a July shakeout, then a sharp V into early-August record highs, then a rolling-top, range-bound September.** The quarter opened below the 6/2 pre-quarter record close (759.57). SPY fell **−3.38% from 754.95 (7/10) to 729.46 (7/29)**, the quarter's low close. The worst day was the 7/29 hawkish-hold FOMC (−1.55%), and the Nasdaq came close to a 10% correction on AI nerves. A **+6.64% rally from 7/29 to 777.88 on 8/13** followed, gaining +5.7% in its first four sessions (8/4 +1.79% was the quarter's best day). It was driven by strong earnings, Hormuz-reopening hopes and a surprise July payroll *decline* that eased hike fears. **Record closes on 8/4, 8/7 and 8/13.** Then came **−3.06% from 8/13 to 754.05 (9/16)** on rising global yields, oil and a hot August payroll print, rebounds on 9/17 and 9/21 (+1.13%, +1.54%), and a 9/21 retest about 0.6% below the record with no new high. The quarter ended **1.96% below the 8/13 record**. The quarter's closing range was only about 6.6%.
- **SMA structure** *(derived)*:

  | Date | Close | 50-day | 200-day |
  |---|---|---|---|
  | 6/30 | 746.77 | 735.87 | 691.43 |
  | 9/30 | 762.63 | 762.74 | 719.62 |

  The close was above a rising 200-day on every session, and the 50-day stayed above the 200-day throughout (no golden or death cross). **Close-versus-50-day crossings:** the close fell below the 50-day on 7/17 (back above 7/21), 7/23 (back above 7/31), 9/10 (back above 9/11), 9/15 (back above 9/17) and 9/30 (below by 0.11 points). Apart from those, it was continuously above from 7/31 to 9/9. SPY ended the quarter pinned to its rising 50-day.
- **Character:** a primary uptrend in the cap-weighted index that went sideways after the 8/13 peak, with rolling tops. Index-level resilience masked deterioration beneath the surface (see section 4).

### 2. Volatility regime

- **VIX** *(IBKR index bars 7/6–9/30, FMP ^VIX 6/30–7/2; agrees with BigQuery)*:
  - 6/30 close 16.45, 9/30 close 16.34.
  - **Quarter high close 20.66 on 7/29** (the FOMC dissent day; intraday 20.88).
  - **Low close 14.21 on 9/22** (intraday low 13.80 on 9/3).
  - **Average close about 16.1** *(derived)*. Monthly averages: July 17.23, August 15.23, September 15.83.
- **Vol events:**
  - **No close above 25.** There was only one close above 20 (7/29).
  - A modest July stress cluster: 18.2–20.7 from 7/17 to 7/29, into the FOMC.
  - Compression to 14–16 for most of August and September. There were **13 closes below 15**, in 8 August and 5 September sessions.
  - The only September lift was 9/10–9/16 (peak 17.84 close on 9/10), as the 10-year broke toward 5% ahead of the hike. VIX fell to 15.44 the day after the hike.
- **Realized volatility:** SPY's daily log returns over 64 Q3 sessions had a standard deviation of 0.690%, so **annualized realized volatility was about 10.96%** *(derived)*. The largest down day was −1.55% (7/29); the largest up day was +1.79% (8/4). With realized volatility (about 11%) below implied (VIX about 16), the variance premium stayed normal and positive.
- **Character: low-to-normal volatility all quarter.** The quarter's macro shocks (oil, rates, a Fed hike) showed up in bonds and commodities, never as equity-volatility stress. The persisted `VIX_REGIME` never read HIGH.

### 3. Yield curve trajectory

| Date | 10Y | 2Y | 10Y–2Y |
|---|---|---|---|
| 6/30 | 4.44% | 4.14% | +30 bp |
| 9/30 | **5.29%** | **4.88%** | **+41 bp** |

*(FMP treasury-rates; 10Y matches the persisted `TREASURY_10Y` day for day.)*

- **The bond selloff was the quarter's dominant market event: the 10-year rose +85 bp and the 2-year +74 bp.**
  - **10-year path:** 4.48% low (7/1, 7/6); 4.71–4.75% interim highs (7/23, 7/31, 8/21, 8/31); first above 5.00% on 9/15–9/16 (a 24-year high); 5.11% after the largest daily move, +15 bp on 9/23 (cause not identified); then 5.24% (9/28) and **5.29% at quarter-end, the quarter high**.
  - The 30-year exceeded 5.6% in late September, a level last seen in 2002.
  - **2-year:** low 4.13% (7/6, 7/15), high **4.92% (9/28)**. It jumped +11 bp to 4.34% on Warsh's 8/28 Jackson Hole speech, and repriced again after the hot 9/4 payroll report.
- **Curve shape:** **never inverted** (minimum +20 bp). The 10Y–2Y spread steepened to **+53 bp (8/17)**, then **bear-flattened to +20 bp (9/21)** as the front end priced the hike, then re-steepened to +41 bp by quarter-end. On 9/30 the curve slopes upward beyond the front end: 3M 4.20%, 2Y 4.88%, 5Y 5.09%, 10Y 5.29%, 30Y 5.64%. `SUSTAINED_INVERSION` read NOT-SUSTAINED on every recorded day.
- **Fed:**
  - **Jul 28–29: HOLD at 3.50–3.75%, 9–3**, with Hammack, Kashkari and Logan dissenting for a hike. The statement cited elevated inflation from energy-supply shocks and the Middle East conflict.
  - **Aug 28, Jackson Hole:** Chair Warsh said the Fed had missed its 2% target for 65 consecutive months. September hike odds jumped from about 35% to over 57%.
  - **Sep 15–16: HIKE of 25 bp to 3.75–4.00%, 12–0.** This was the first hike since July 2023. The median dot shows one more hike in 2026.
  - October pricing at quarter-end was contested between sources (CME about 64% for a hike versus Polymarket about 60% for no change).
- **Macro data:**
  - **Payrolls:** July was an unexpected decline. August was +162k against about +55k expected, with unemployment at 4.1%.
  - **Inflation:** August CPI was 3.4% year over year. August core PCE was +0.2% month over month and 3.0% year over year, softer than expected (3.3%).
  - **Growth:** Q2 GDP was +2.2% annualized.
  - Several of these come from secondary sources that do not fully tie out; they are lower confidence. The July and August CPI release details were not verified.

### 4. Equity market breadth

- **Share of S&P 500 members above their 200-day SMA** (persisted `EQUITY_BREADTH_PCT`, Barchart $S5TH, cross-checked against EODData and MacroMicro):
  - **Start:** about **62% at Q2 end** (prior retrospective). There is no measured July value; the persisted signal carried a stale June HEALTHY reading (see Part 2, Flag 1).
  - **Peak:** 70.57% on 8/5, the first measured value, then **73.16% on 8/13**, the index peak.
  - **Decline:** 72.11% (8/24), 62.62% (9/1), 54.67% (9/10), then below 50% from 9/22.
  - **End:** **40.55% on 9/30** (41.15% on 10/1).
  - That is **−32.6 points from peak to quarter-end**, with about 17 points lost in the last three weeks of September alone. The persisted `EQUITY_BREADTH` signal flipped HEALTHY → **WEAK on 9/18** (49.50).
- **Participation: narrow, mega-cap and AI-led, and deteriorating** *(derived, IBKR bars, 6/30 → 9/30 price returns)*:
  - **Equal weight lagged cap weight:** RSP (equal-weight S&P) **−2.23%** against SPY +2.12%, a 4.35-point gap.
  - **Small caps:** IWM **−7.51%** (Russell 2000 −7.52%).
  - **Nasdaq-100:** QQQ +0.46%, so the gain was concentrated in semiconductors and AI-linked mega-caps rather than the broad Nasdaq-100.
  - **Other indices:** the Dow fell −2.70%, and about 75% of S&P members declined in September while the index was roughly flat.
- **Sector leadership and laggards.** Only 4 of 11 SPDR sectors finished the quarter positive:

  | Leaders | Q3 | Laggards | Q3 |
  |---|---|---|---|
  | XLE Energy | **+15.80%** | XLU Utilities | **−13.01%** |
  | XLV Health Care | +6.15% | XLI Industrials | −9.85% |
  | XLC Comm. Services | +3.58% | XLY Cons. Discretionary | −7.20% |
  | XLK Technology | +2.75% | XLRE Real Estate | −7.09% |
  | | | XLB Materials −4.19%, XLP Staples −2.97%, XLF Financials −0.39% | |

  Energy led on the oil shock and Health Care on a defensive-quality bid. Rate-sensitive sectors and cyclicals (utilities, industrials, real estate, discretionary, small caps) were hit hard by the yield spike.
- **Character:** this was **rotation and narrowing, not broadening.** Breadth peaked with the index on 8/13 and then collapsed in step with yields and oil while two index-heavy sectors held the cap-weighted index up.

### 5. Dominant macro narrative

- **Theme 1: the Iran-war oil shock feeding sticky inflation.**
  - The war, under way since late February, re-escalated in July: US strikes on 7/8, an attack on Kuwaiti infrastructure on 7/17, and **Brent above $100 on 7/23**.
  - Hopes of a Hormuz reopening briefly reversed it in early August (Brent about $83.5 on 8/7).
  - Re-escalation followed: US maximum sanctions on 8/20, Brent $101 on 9/9, and a mid-September **peak of about $105–108**. Diesel hit a record $6.06 per gallon on 9/11.
  - WTI went from about $69.50 (6/30) to about $94.61 (9/24), **+36%** (FactSet). Hormuz traffic was down about three-quarters, and the Strategic Petroleum Reserve fell below 300M barrels.
- **Theme 2: a hawkish Fed under Chair Warsh and a global bond selloff.**
  - It ran from a dissent-split hold (7/29), through the hawkish Jackson Hole speech (8/28) and the hot August payroll report (9/4), to the first hike since 2023 (9/16).
  - Over the same stretch the 10-year reached a 24-year high of 5.29%, the 30-year exceeded 5.6%, and the dollar index rose above 100.
- **Supporting theme: AI and mega-cap earnings strength** kept the cap-weighted index positive (section 6). The late-September Trump–Xi truce extension (to 1/10/2027) kept tariffs a minor theme.
- **Quarter start versus end.** The quarter opened on an *"AI rally + fragile ceasefire + Fed on hold"* story: WTI below $70, the S&P near records on H1 gains of about 10%. It closed on *"stagflation-lite + higher-for-longer"*: oil at $90–100, an actual hike with more priced, long yields at 20-year-plus highs, and cyclicals and small caps under pressure while mega-cap tech held the index.

### 6. Earnings and fundamentals backdrop

- **Q2 2026 reporting season (mid-July to August; FactSet).**
  - **Beat rates:** **87% beat EPS** (99% reported; the highest since Q2 2021, against a 5-year average of 78%) and **77% beat revenue** (5-year average 70%).
  - **Size of surprise:** aggregate EPS surprise about **+26–29%**, but only about **+9–11% excluding Alphabet and Amazon**, whose one-time gains of $98B and $53B inflated the headline.
  - **Growth:** blended year-over-year EPS growth about **52%**, or about 29% excluding Alphabet and Amazon. Revenue grew about 15%, and the net margin was a record 17.0%.
  - **By sector:** 10 of 11 sectors grew earnings; Health Care was the lone decliner.
- **Forward estimates rose while the multiple compressed.**
  - Q3 bottom-up EPS rose **+1.3% during the quarter**, from $88.64 to $89.76; estimates normally fall about 2.2–2.5%. This was the second straight quarter of upward revisions.
  - The CY2026 growth estimate rose from 24.0% to 32.0%. The CY2027 estimate slipped from 16.8% to 15.4%.
  - **Forward 12-month EPS rose +8.9%** while the **forward P/E compressed from 20.4 to 19.2** (FactSet 9/25). The index return was therefore entirely earnings-driven, against roughly 6% multiple compression consistent with the rate shock.
  - Buy ratings reached 59.9%, a record.
- **Sector divergence.**
  - **Q3 EPS revisions:** Energy +18.0% and Technology +4.1% on the upside; Materials −8.9%, Staples −3.3% and Health Care −2.6% on the downside.
  - **Q3 growth estimates:** Energy +111% (refiners +427%), Technology +63.5% (24.2% excluding semiconductors), Communication Services +51% (12% excluding Meta and EchoStar), against low single digits for Financials, Health Care and Staples.
  - **Earnings growth is extremely concentrated in semiconductors, Meta and energy**, mirroring the narrow price breadth.
- **Q3 reporting-season preview (as of 9/25):**
  - EPS growth is expected at **+29.1%** (26.7% on 6/30) and revenue growth at +12.1%.
  - **62% of companies guiding for Q3 have guided positive**, against a 5-year average of 41%, and 61% of those positive guiders are in Technology.

### 7. Overall regime characterization

Q3 2026 was a **macro-driven, transitional, narrowing quarter**. An energy-supply shock (the Iran war and Hormuz) and a hawkish Fed pivot from hold to hike produced a **bear-steepening and then bear-flattening bond selloff to a 24-year-high 10-year yield**. Equities never registered it as volatility stress: the VIX averaged about 16 and never closed above 21. The **cap-weighted index ground out +2%** with record highs in early August, carried by an AI and mega-cap earnings surge and +8.9% forward-EPS growth that absorbed about 6% of multiple compression. **Beneath the index, the regime was rotating and risk-off:**
- equal weight −2.2%;
- small caps −7.5%;
- breadth collapsing from 73% to 41% of members above their 200-day;
- rate-sensitive sectors and cyclicals −7% to −13%, against energy +16%.

The accurate descriptors are **macro-driven, sector-rotational, narrow-leadership, range-bound after the August top, and transitional from "AI-rally risk-on" toward "stagflation-lite, higher-for-longer"**. It was *not* a broad risk-off and *not* a trending bull. The cap-weighted trend read (UP) and the equal-weight and breadth read (deteriorating) disagreed for most of August and September.

---

## PART 2 — Router activation trace, consistency comparison, and diagnostic flags

*Backward-looking factbase. Each live strategy's own machinery and the shared regime vocabulary stay immutable (SISA per-strategy immutability, owner directive 2026-07-10). These flags feed **SL1** (candidate synthesis; it reads this Part 2 directly in its STEP 1) and **SL4** (its retirement scan reads `entry_type='strategy-retirement-signal'`). See "Arsenal-loop writes this run" at the end for exactly what Q1 wrote to BigQuery and why.*

### 1. Router activation trace (Q3 2026)

The M4 monthly router rows were dated 07-01, 08-03, 09-01 and 10-02, each followed by a divergence-review cohort: June resolved 07-06, July resolved 08-05, August resolved 09-03, and the September cohort was still pending at 10-02. *(Sources: `events.regime_events` STRATEGY_ACTIVATION; `state.adversarial_reviews_current`.)*

| Strat | Technical rule | Activation trace | Divergence / adversarial reviews (outcome) | Deployment in Q3 |
|---|---|---|---|---|
| **A** | SPY Trend=UP AND Breadth=HEALTHY | **DO-NOT-ACTIVATE all quarter.** 07-01 DNA confirmed, with no divergence because the technical leg read a stale NEUTRAL. 08-03 DNA pending `div-A-202607-1`, **A's first-ever divergence review**, once the repaired SPY_TREND read UP. 09-01 DNA pending `div-A-202608-1`. 10-02 DNA with planes agreeing (breadth WEAK 41.15%). | `div-A-202607-1` (08-05): attacker "fundamental should not survive"; orchestrator **held DNA, DIVERGENT**. `div-A-202608-1` (09-03): same attacker position; **held DNA, MIXED**. | None, ever. A has never activated since inception (4/22). |
| **B** | SPY Trend≠DOWN AND VIX≠HIGH | **ACTIVATE until 08-05, then DNA.** On 08-03 M4 flagged an acute-shock override flip, held pending. On 08-05 the flip resolved to **DNA** (state change). Held DNA on 09-03. 10-02 DNA pending `div-B-202609-1`. **B's raw technical and fundamental calls are both ACTIVATE**; the DNA is produced by the `shock_overlay=acute` override alone, now three months running. | `div-B-202607-1` (08-05): override validly applied, **DIVERGENT**. `div-B-202608-1` (09-03): DNA held, **DIVERGENT**. | **The most active strategy until 8/5.** Buys: HCA (dust), MDT, ISRG, MSCI, FTV, MTZ. Exits: ZBRA, AZO, HCA, IBM, MDT, MTZ, FTV, ISRG, MSCI. Realized **+$17.45**; unit value 1.0913 → 1.1841; excess over SGOV +0.171 at the last mark (8/18). **Flat from 8/18.** Thesis screens: 3 GO / 39 NO-GO (thesis-construction). |
| **C** | SPY Trend≠DOWN | **HYBRID ACTIVATE (FOMC-only) all quarter.** Re-derived each cycle: 07-06 MIXED, 08-05 DIVERGENT, 09-03 MIXED (broad ACTIVATE "procedurally unreachable" without a scope-widening adjudication). 10-02 pending `div-C-202609-1`. | 3 reviews, all continued HYBRID; the attacker argued against blanket DNA every cycle. | None. Two Q3 FOMCs (7/29, 9/16) produced no qualifying entry. NAV $19.49. |
| **D** | (SPY Trend UP or NEUTRAL) AND Sustained-Inversion=NOT-SUSTAINED | **ACTIVATE until 08-05, then DNA.** 07-06 ACTIVATE held: the DNA was manufactured by the inflation+hawkish override acting on a raw ACTIVATE (DIVERGENT). On 08-05 the result was **DNA (state change)**: inflation had moved to stable, so the override was inert and this was a *raw* fundamental DNA (the attacker agreed it survives). Held DNA on 09-03. On 10-02 the raw call flipped to ACTIVATE on firmer growth, and the **acute override** now produces the DNA (pending `div-D-202609-1`). | 07-06 ACTIVATE, DIVERGENT. 08-05 DNA, DIVERGENT. 09-03 DNA held, DIVERGENT (two Tier-1 attacker findings were adopted against the reasoning, but the verdict was unchanged). | **Deployed heavily in July** while active: AMZN, GOOGL (+add), CRM, UBER on 7/09; ISRG; TSM ×2; DIS ×2; AMZN add; GEV on 8/3. One exit: **CRM on 8/27, +$16.58**. **Open at quarter-end:** AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER, all UNBREACHED at M3 10-01. NAV $548.96; unit value 0.9859 → 1.0695; excess +0.053; kill flags all false. |
| **E** | SPY Trend≠DOWN AND VIX≠HIGH AND Breadth=HEALTHY | **ACTIVATE until 09-03, then DNA.** 07-06 ACTIVATE (substantive), execution feasibility deferred. 08-05 ACTIVATE with the **deferral lifted in full**. 09-03 **DNA** (state change; the acute override fired on E for the first time). 10-02 DNA with planes agreeing (breadth WEAK). | `div-E-202606-1`, `div-E-202607-1` and `div-E-202608-1`: all **DIVERGENT**. | **None.** No entries, even in the 8/5–9/3 window with the deferral lifted. E carries **$12,672.77 of deposits/NAV fully idle**, the largest book in the arsenal. |

**Out-of-table router review:** `otr-router-shock-override-2026` (AR_orc, 09-09) ended in **HOLD**, so the acute override stands as written (uniform, one-directional, unscaled). AR_orc's own text records that this HOLD does **not** discharge the open limbs (b) horizon scaling and (c) per-strategy transmission (`decision_log`, citing `ops.alerts` 18196168).

**Summary.** Q3 inverted Q2's picture:
- **Every Q3 state change was toward DNA:** B (08-05), D (08-05) and E (09-03).
- **By quarter-end no strategy was broadly ACTIVATE.** C held its narrow HYBRID (FOMC-only) scope, and D is the only strategy holding positions, from its July deployment.
- **Theater-check distribution over the Q3 divergence verdicts: DIVERGENT 11, MIXED 5, CONVERGENT 0.** The degenerate all-CONVERGENT pattern that would mandate a separate Theater Auditor still has not appeared.

### 2. Consistency comparison — router classification vs. retrospective

**Technical half (mechanical vocabulary) vs. the actual Q3 tape:**

| Signal | Router-recorded state | Retrospective / mechanically-correct value | Match? |
|---|---|---|---|
| SPY Trend State | **Stale NEUTRAL (6/03 row) served for all of July**. From 7/31, measured daily: UP, with single-day NEUTRAL on 9/10, 9/15–9/16 and 9/30 | **July:** UP on 7/1–7/16 and 7/21–7/22 (close > 50d > 200d); NEUTRAL on 7/17–7/20 and 7/23–7/30 (close < 50d > 200d). **August/September:** the measured values match the derived 50/200-day series exactly | **July: NO** (persistence defect, fixed 08-03; see Flag 1). **Aug–Sep: YES**, mechanically correct |
| Equity Breadth | **Stale HEALTHY (6/03) through July.** HEALTHY from 7/31; WEAK from 9/18 | About 62% at the 6/30 start (HEALTHY plausible but **unmeasured** in July). 70–73% in August; below 50% from 9/22; 40.55% at 9/30 | **Mostly yes.** HEALTHY was correct while values were above 50, and the flip to WEAK on 9/18 is consistent. One carry-forward lag: the 9/18 value persisted while a measured 50.49 for 9/21 went unwritten, already recorded in `decision_log` e8fb3657 |
| VIX Regime | NORMAL, alternating LOW/NORMAL from 8/07 | VIX 14.2–20.7, no close above 25 | **YES** |
| Sustained Inversion | NOT-SUSTAINED | Positively sloped all quarter (+20 to +53 bp) | **YES** |

**Where the technical half and the retrospective genuinely part ways — cap weight versus participation.** The technical vocabulary is keyed to cap-weighted SPY. It correctly read **UP** through August and September while the equal-weight index, small caps and four in seven sectors were falling and breadth was collapsing from 73% to 41%. The breadth signal is the one technical input that measures participation. It is a **level** threshold (50%), so it stayed HEALTHY through a −20-point slide (8/13 → 9/10) and flipped only on 9/18, about five weeks after breadth peaked. This is not a recording error; the vocabulary did what it says. But a reasonable observer would have called **mid-August to September "narrowing / distribution under a flat index"**, while the router's technical half read it as **UP/HEALTHY (unqualified)** until 9/18.

**Fundamental half (M1a/M1b) vs. the actual regime — better aligned than in Q2.**

| As of | Growth | Inflation | Policy | Risk | Shock | Retrospective verdict |
|---|---|---|---|---|---|---|
| 07-01 | stable | reaccelerating | hawkish | neutral | latent | Fair. Oil had not yet re-spiked, and the Fed's 7/29 dissents vindicate "hawkish". |
| 08-01 | decelerating | stable | hawkish | neutral | **acute** | **Defensible on macro grounds** (Brent above $100 on 7/23, the Kuwait attack, the Fed citing energy shocks), but the equity tape never confirmed it: VIX at most 20.7, and record highs on 8/4–8/13. |
| 09-01 | decelerating | disinflating | hawkish | risk-on | acute | Mixed. "Disinflating" sits poorly with CPI at 3.4% and oil re-spiking; "risk-on" matched the index but not breadth. |
| 10-01 | stable | stable | hawkish | neutral | acute | Fair. "Hawkish tightening" is now literal (the 9/16 hike); the shock (Brent $95–108 in September) is real. |

Q2's flag was that the fundamental half ran **bearish against a melt-up**. In Q3 the fundamental half's DNA cluster turned out to be **consistent with the retrospective's below-the-surface regime**:
- B went flat on 8/18. Over 8/18 → 9/30, SPY drifted slightly lower (−2% from its 8/13 record) while RSP and small caps fell and breadth halved, so B's DNA forgave little or no opportunity in its long-bias universe.
- D's new-entry block from 8/5 cost little.
- D's July-deployed book (AMZN, GOOGL, TSM, GEV, ISRG) sat in exactly the mega-cap and AI cohort that led, and stayed unbreached.
- A's two held DNAs in August and early September came as the cap-weighted index went sideways and equal weight fell.

The one systematic disagreement is **mechanism, not outcome**. Four of the five strategies were DNA'd in August and September through a **uniform `shock_overlay=acute` override** firing in a tape whose equity volatility never confirmed a shock (Flag 2). Outcome-wise the override happened to be cheap this quarter, because the shock's equity transmission ran through breadth and sector rotation rather than index drawdown.

### 3. Diagnostic flags (inputs to SL1 candidate synthesis and the SL4 retirement scan)

**Follow-up on the Q2 flags.**
- **Q2 Flag 1** (stale SPY Trend persistence) was **confirmed and fixed**. The TECHNICAL_SIGNAL write had been orphaned at the 2026-06-06 cutover (`decision_log` 424d05e2). It was repaired on 08-03, and D2a now writes daily from 07-31.
- **Q2 Flag 2** (fundamental half bearish against the tape) **did not recur** in outcome terms (see above).
- **Q2 Flag 3** (theater-check distribution) still has **no CONVERGENT verdicts**: Q3 had 11 DIVERGENT and 5 MIXED.

**Flag 1 — The stale-technicals defect suppressed a second A divergence review, on 07-01 (closed).** The 07-01 M4 read used the stale 6/03 NEUTRAL/HEALTHY rows. The mechanically-correct 7/1 value was **UP** (close 746.77 versus 50-day about 736 and 200-day about 691) with breadth plausibly HEALTHY (about 62% at 6/30). That combination would have made A technically ACTIVATE against a fundamental DNA, a divergence that was again never reviewed. It would very likely have resolved to DNA, as both later A reviews (08-05, 09-03) did. The root cause is fixed. Recorded so the Q2 count of suppressed reviews is not read as one.

**Flag 2 — A uniform acute-shock override DNA'd the arsenal through a low-volatility, record-high tape; the "acute shock" regime cell is structurally uncoverable (highest priority for SL1).**
- **What happened.** From 08-01, `shock_overlay=acute` forced DNA on B (3 months running, against raw technical and fundamental ACTIVATE), then E (09-03), then D (10-02, against a raw ACTIVATE). The router rule text reads: *"An acute shock overrides mechanism-specific optimism across all strategies."*
- **Retrospective evidence on the open limbs (b) horizon scaling and (c) per-strategy transmission.**
  - The Q3 shock was real but **transmitted through rates, oil and sector rotation, not through index drawdown or equity volatility**: VIX at most 20.7, realized volatility about 11%, cap-weighted index records on 8/4–8/13.
  - The sectors that **benefited** were energy (+15.8%), health care (+6.2%) and AI/semiconductor mega-caps. The sectors hit were utilities, industrials, real estate, discretionary and small caps.
  - A per-strategy transmission rule would therefore have **distinguished**:
    - B's long-bias quality universe (mixed exposure);
    - D's mega-cap catalyst names (which led);
    - E's ETF pairs (which, as relative-value pairs, are plausibly the *least* shock-exposed).
  - The uniform rule could not.
  - Outcome cost this quarter was low (see section 2), so **this is evidence for the open limbs, not proof the override was wrong.**
- **Consequence for arsenal coverage.** The override applies to *every* strategy, including any SISA newcomer under the shared reconciliation block. So **no strategy, present or future, can be ACTIVATE under `shock_overlay=acute`**, and the acute-shock cell is uncoverable by construction while limb (c) stays undischarged.
- **Factbase for SL1.** The quarter's realized leadership (energy and commodity-shock beneficiaries, rate-shock-resilient quality) had **zero arsenal exposure and zero permissible mechanism**. A candidate targeting that cell would be DNA'd on day one by the override. It would fail SL1 STEP 3 on fit, and per SL1 STEP 2 writing it "merely to reject it … burns the archetype's cooldown without adding evidence" (see "Arsenal-loop writes" below).
- **Owner of the structural question:** the Strategy.md M1a/M1b reconciliation block. It was adjudicated HOLD on 09-09 (`otr-router-shock-override-2026`) with limbs (b) and (c) explicitly left open. This Q3 evidence is recorded for whichever cycle reopens them; Q1 does not re-tune the shared vocabulary or the reconciliation rules.

**Flag 3 — The technical vocabulary is participation-blind at the trend level and lags at the breadth level.** SPY Trend (cap weight) read UP through a quarter in which equal weight fell −2.2% and small caps −7.5%. The breadth level threshold stayed HEALTHY for about five weeks of a 73% → 50% slide. There is also **single-session flapping** with no hysteresis:
- SPY_TREND went UP → NEUTRAL three times in September (four NEUTRAL sessions: 9/10, 9/15–9/16, 9/30), each on a 50-day cross of under 0.5 points.
- VIX_REGIME made about 15 LOW/NORMAL transitions.

Monthly M4 cadence absorbed the flaps this quarter: no activation flipped on a one-day print. A daily-gated rule (D2a or D1 consumers) would not be protected. Per immutability, **the shared vocabulary is not re-tuned**. This is recorded as a factbase input: a newcomer whose router keys on equal-weight or participation-aware trend, or on breadth *rate of change*, would be materially structurally different from A–E on router structure (SL1 STEP 3(b)).

**Flag 4 — Capital idleness and non-deployment (factbase for SL4, not a retirement signal).**
- **At quarter-end only D holds positions ($549 deployed).**
- **E's $12,672.77 is fully idle.** E never entered a pair in two quarters, including 8/5–9/3 when it was ACTIVATE with its execution deferral lifted.
- **A has never activated** in about 5.3 months.
- **C** (HYBRID FOMC-only) traded neither Q3 FOMC.

None of these is an *edge-decay*, *redundancy*, *dominated-by-newcomer* or *router-disagreement* signal on Q3 evidence. A's and B/D/E's DNAs were consistent with the retrospective's regime (section 2), and B and D, the only strategies with measurable outcomes, both show positive excess over SGOV. They are recorded so SL4's own quantitative scan, which owns idle-strategy judgments, sees the dormancy pattern alongside its `state.strategy_retirement_candidacy` read.

**Flag 5 — The arsenal coverage matrix is degenerate for the live roster, and its stated build blocker is gone.** `state.arsenal_regime_coverage` reads all 9 cells `is_gap=TRUE` with five ADOPTED strategies. This is by design: it measures demonstrated *paper* coverage only, and SL1 STEP 2 already treats it as degenerate for the founding A–E. The view's own header says the ADOPTED-coverage leg was deferred because *"it needs a technical-regime daily series that does not yet exist."* **That series now exists:** daily TECHNICAL_SIGNAL rows since 2026-07-31, about 44 sessions in Q3. This is filed as an out-of-scope `ops.alerts` info notice for the view's owner (see below).

### Arsenal-loop writes this run

- **`state.strategy_candidates`: 0 rows written.**
  - The IDEMPOTENCY pre-check found no existing `source_routine='Q1'` rows (codes in use: A–E roster, F/G/H REJECTED; next free code I).
  - The only roster-relevant coverage finding (Flag 2, the acute-shock cell) names a regime cell that **no candidate can activate in** while the uniform override stands. A row for it would fail SL1 STEP 3 on fit and burn that archetype's cooldown, which SL1 STEP 2 expressly prohibits.
  - The adjacent archetypes F (defensive-quality-regime-rotation, cooldown to 10-25), G (defined-risk index downside convexity, cooldown to 10-25) and H (cooldown to 11-01) are all inside their post-rejection cooldowns.
  - Flags 2 and 3 are left here as SL1-readable factbase (SL1 STEP 1 reads this Part 2) instead.
- **`events.decision_log` `strategy-retirement-signal`: 0 rows written.**
  - The SL4 signal classes require edge-decay, redundancy, dominated-by-newcomer or router-vs-observer disagreement.
  - Q3 evidence shows none of these for any of A–E (Flag 4).
- **One `events.decision_log` `routine-outcome` row** records this run's findings, including the Flag 2 retrospective evidence on the override's open limbs.
- **One `ops.alerts` info notice** (`adopted_coverage_leg_unblocked`) is filed for Flag 5.

---

*Part 1 sources: IBKR connector daily bars (SPY, VIX, the 11 SPDR sectors, RSP, IWM, QQQ); FMP treasury-rates and ^VIX; persisted `events.regime_events` (TREASURY_10Y, EQUITY_BREADTH_PCT — Barchart $S5TH, EODData and MacroMicro cross-checks); `events.macro_fred`; FactSet Earnings Insight (6/26, 8/7, 9/4, 9/25 editions); First Financial Trust Q3 market review; TechTimes (9/28); CNBC and Federal Reserve press-release summaries; the Wikipedia 2026 oil-market chronology (secondary; levels deferred to FactSet where they conflict). Part 2 sources: `events.regime_events`, `events.decision_log`, `events.adversarial_reviews` / `state.adversarial_reviews_current`, `events.trade_fills`, `state.current_positions`, `analytics.strategy_nav`, `perf.strategy_daily`, `perf.kill_flags`, `state.strategy_candidates`, `state.strategy_roster`, `events.strategy_lifecycle` and `state.arsenal_regime_coverage` (project `stock-trading-498512`); `strategy/02_regime_router.md` and `strategy/03–07`.*

2026-Q4
# Strategy D — Long-Horizon Candidate Screen, 2026-Q4

Prepared: 2026-10-02 (quarter just beginning; Q2 fired one trading day after the 2026-10-01 first trading day of Q4).
Strategy scope: **D only.** `strategy/roster.yaml` has D as the sole roster strategy with `review_cadence: long_horizon` (A, B, C and E are `reactive`), so no other strategy section is owed.
Strategy: D (long-horizon narrative-screened equity core — Subtype A future-dated catalyst / Subtype B trend continuation).

**Evidence window.** `state.routine_catchup_window` gives Q2 `window_start_ts` = 2026-07-01 19:18 UTC (Q2's own last completion) and `window_days` = 92.95. That is cadence-normal for a quarterly routine, so no missed-quarter sub-sections are owed. Developments are researched from 2026-07-01 onward.

---

## 0. Book state, regime, and screen constraints

- **D book** (`state.current_positions`, 2026-10-02): **8 names, 12 tranches, all OPEN**, and none of them is eligible for this screen: AMZN, GOOGL, TSM, GEV, DIS, ISRG, UBER and RTX. Market value is $549.33 against D NAV $548.96 (`analytics.strategy_nav`: deployed_mv = nav, available_funds 0).
  - M3 2026-10 (`Monthly_D_Position_Deep_Dive.md`) returned **all 8 HOLD, 0 of 34 criteria breached**.
  - The floor of 5 concurrent positions is met (8). There is no count ceiling (Rev 35).
  - **CRM left the book** on 2026-08-26, when invalidation criterion 3 was met. It is screened below as an ordinary candidate.
- **Sector exposure, by market value on 09-30:**

  | Sector | Names | Value | Share of D NAV now ($549) | Share if capital restored (~$4,979) |
  |---|---|---|---|---|
  | Industrials | GEV, UBER, RTX | $183.29 | **33.37%** | ~3.7% |
  | Communication Services | GOOGL, DIS | $164.66 | **29.97%** | ~3.3% |
  | Consumer Discretionary | AMZN | $86.31 | 15.71% | ~1.7% |
  | Information Technology | TSM | $70.71 | 12.87% | ~1.4% |
  | Health Care | ISRG | $44.36 | 8.08% | ~0.9% |

- **Capital enablement — the concentration check carries a caveat this quarter.** `state.strategy_capital_enablement` shows D `capital_disabled = TRUE`.
  - `state.regime_capital_debt` shows D `outstanding_debt` = $4,430.02, swept out and not yet restored.
  - D's NAV has therefore collapsed onto its own deployed book. The "% of D NAV" column above is the denominator in question under the open `sector_cap_denominator_artifact` question (M3 F-12; W5's caveat in this routine's spec).
  - Per spec, **no candidate below is classified "blocked by concentration" on that reading alone.** Each Industrials or Communication Services addition is reported with both readings.
  - On the artifact denominator, any Industrials name reads above 30% (the sector is already over). Any Communication Services name of more than about $0.20 also reads above 30%.
  - On the restored denominator (NAV ≈ $548.96 + $4,430.02 = $4,978.98), every sector sits below 4%. A single ~2%-of-NAV add cannot approach 30%.
  - **Which denominator Entry criterion 5 intends is an A3/owner-level question.** This routine does not resolve it.
- **The AI-capex cluster is the real concentration (M3 F-9).** AMZN, GOOGL, TSM and GEV hold 66.2% of D's market value. Because they sit in four GICS sectors, the sector cap cannot see them.
  - This screen therefore treats **"does this name add to the AI-capex cluster?"** as a ranking input under Entry criterion 3, the adversarial concentration-risk-within-D's-book factor. It is not a block.
  - Diversifying names rank ahead of equal-strength cluster names.
- **Regime** (`state.current_regime`, September integrative, as of 2026-10-01): **stable growth, stable inflation, hawkish policy, neutral risk, acute shock.**
  - Growth: August payrolls +162k; Q2 GDP revised to 2.2%.
  - Inflation: CPI 3.4%; core CPI 2.4%.
  - Policy: the Fed **hiked 25bp to 3.75–4.00%** on 2026-09-16.
  - Rates: the 10Y is at **5.24%** (D2a 10-01), up from 4.75% in August.
  - Credit: high-yield OAS widened 49bp.
  - Shock: drone strikes on the Saudi East-West pipeline on 09-10/11 pushed Brent above $100.
  - Technicals: SPY trend UP (close 763.99 > 50d > 200d); VIX 16.39 NORMAL; breadth WEAK at 41.15%.
  - **Implication for D:** long-duration multiple compression is the live headwind. Favour theses anchored to quantified, cash-generative trends at reasonable entry points over high-multiple narrative names.
- **D router — new entries are BLOCKED.** The operative state is **DO-NOT-ACTIVATE — PENDING `div-D-202609-1`**.
  - M4 2026-10 carried the state forward with the basis **inverted**.
  - The raw M1b fundamental call flipped DNA → ACTIVATE on the growth reversal.
  - The post-reconciliation DNA is now manufactured by the universal acute-shock override.
  - The technical leg reads ACTIVATE.
  - The divergence review is queued: attacker 2026-10-05, orchestrator 2026-10-06 (`state.open_queue` PENDING_REVIEW).
  - **Every readiness flag below is thesis, eligibility and momentum only.** "Ready now" means ready for Q4 to schedule thesis construction. It does not mean stage an order. Staging stays gated by the router and by `state.trading_enabled`.
- **Caps** (Strategy.md as of Rev 43 and the 2026-08-05 owner directive):
  - **Removed:** the count cap, the bucket-count cap, the flat 2% size and both CaR envelopes.
  - **The only live concentration bound** is the 30%-of-NAV GICS-sector cap (Entry criterion 5).
  - **Correlation buckets** (>0.6 trailing-252d daily-return correlation) are **informational only** (Rev 35).
- **Correlation method.** Correlations come from classical-method delegation in code.
  - **Source:** IBKR `get_price_history`, one contract per call (the documented series-swap mitigation), ONE_DAY, RTH, last completed session 2026-10-01. The in-progress 10-02 bar was dropped.
  - **Statistic:** Pearson correlation of 252 daily simple returns.
  - **Checks:** every held name's 09-30 close matched the M3 / `events.daily_marks` close exactly, so no series swap. One candidate (SPOT) was re-pulled independently and matched to the cent.
  - **Held matrix reproduces M3:** GEV–TSM 0.609 (M3 0.614) and AMZN–GOOGL 0.537. No other held pair exceeds 0.31.
- **Momentum convention** (Entry criterion 6), carried from the 2026-Q3 screen: trailing 30-calendar-day close-to-close change, 2026-09-01 → 2026-10-01. **"Rallying hard" = more than about +15%.**
- **"NO-GO records are context, not barriers."** Prior D dispositions and their current reading:

  | Name | Prior disposition | Current reading |
  |---|---|---|
  | LLY | Entry-timing NO-GOs 2026-04-30 and 06-12. The 09-14 re-screen was a terminal NO-GO on the router gate alone, with no merits evidence gathered. A re-screen is queued for 2026-12-14. | The entry-timing failure has **normalised on the merits**: trailing 30d −0.9%, 10% below the 52-week high. |
  | BA | Criterion-2 NO-GO 2026-08-03. Its premise was **refuted** 2026-08-09: all 8 transcripts are free on Boeing IR. The 09-01 terminal re-screen kept the NO-GO. | Re-screened below on current facts. |
  | NKE | 2026-09-27 conservative-default DECLINE, because the print fell after the due date. | That print is now in (FQ1 FY27, 10-01) and is still negative. |
  | CCJ | Criterion-4 NO-GO 2026-05-06. | — |
  | CRM | Mechanical exit 2026-08-26. | — |
  | CEG, VST | NO-GOs 2026-04-26. | — |

  Each name is re-screened on current facts. None is excluded on record alone.
- **Data provenance.**
  - **Prices, momentum, ADV and correlations:** IBKR connector, as described above.
    - ADV is the 21-session mean of close × volume in IBKR shares.
    - IBKR's volume appears to be a partial-venue count, about 40–60% of consolidated tape. ADV figures are therefore **lower bounds**, and every name still clears $20M by a wide margin. The smallest is CCJ at about $171M.
  - **Market caps:** one undated page fetch per name group on 2026-10-02 (companiesmarketcap.com / stockanalysis.com). They are approximate, and every name is at least $37B, so the **≥$10B gate is cleared by every listed name with a wide margin.**
  - **Thesis evidence:** company 8-Ks, 10-Qs and releases plus secondary web sources for calendar-Q2-2026 prints (Jul–Sep 2026) and later developments. Each figure is dated and period-labelled. Figures carried from a single secondary source are marked "(1-src)".
  - **Not verified this session, for any name:** whether all 8 quarterly transcripts plus 2 annual reports are on file (Entry criterion 2). For every large-cap US issuer here they are very likely public on IR sites or EDGAR. The two prior "evidence floor not met" findings (GEV 2026-08-09, BA 2026-08-09) were both **refuted** on that basis. **Thesis construction must confirm criterion 2 for each name; it is not presumed met here.**

**Thesis-category legend:** `1` Product cycle (multi-cycle roadmap) · `2` Regulatory/legal resolution · `3` Management execution / turnaround · `4` Secular thematic (specific mechanism) · `5` Industry structural change (identified beneficiary).

---

## 1. PART 1 — Candidate universe (broad long list)

These are **50 names** that pass D's eligibility gates and carry a concrete, documented multi-year structural driver. They are ordered by market cap.

**Construction of the list:**
- Start from the 2026-Q3 long list.
- Remove the six names now held (GOOGL, AMZN, TSM, ISRG, UBER, GEV) and the two weak-fit names BAC and SLB (rate and oil beta rather than a structural narrative).
- Add ten names the Q3 list omitted: MSFT, NVDA, META, ASML, VRTX, BSX, PWR, NFLX, V and ANET.

The 30d, ADV and correlation columns are the IBKR quant pull described in §0. **Bold** 30d values exceed the +15% rally threshold.

| # | Ticker | Company | Mkt Cap | GICS Sector / Industry | Cat | Why on the list (latest sourced figure) | Key public docs | 30d | ADV (21d, IBKR) | Max 252d corr vs held |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NVDA | NVIDIA | ~$5.67T | Information Technology / Semiconductors | 1,4 | Annual GPU platform cadence (Blackwell -> Vera Rubin in full production); Data Center revenue $89.0B in FQ2 FY27, +117% YoY; hyperscale $48.7B, AI clouds/industrial/enterprise $40.3B. | FQ2 FY27 press release (2026-08-26):  ; 10-Q for qtr ended 2026-07-26 (EDGAR nvda-20260726.htm); latest 10-K = FY2026 (FYE Jan 2026; not fetched). | +6.2% | $13.9B | 0.64 TSM |
| 2 | MSFT | Microsoft | ~$3.83T | Information Technology / Systems Software | 4,5 | Azure + AI demand: Azure/other cloud +43% YoY in FQ4 FY26 (accelerating from 40%), Azure FY26 revenue >$100B (+41%), commercial RPO $678B (+84%), M365 Copilot >30M paid seats. | FY2026 10-K (FYE 2026-06-30):  ; FQ4 FY26 earnings release 8-K ex99.1 (reported 2026-07-29); call page  No 2026 investor day verified. | +2.4% | $5.6B | 0.39 AMZN |
| 3 | META | Meta Platforms | ~$1.86T | Communication Services / Interactive Media & Services | 4,3 | AI-driven ad ranking lifts monetization: Q2 2026 revenue $60.8B +28% YoY (impressions +14%, price/ad +12%) while capex runs $130-145B in 2026; Muse personal AI agent app launched 2026-09-08 and was reported a hit. | Q2 2026 8-K ex99.1 (2026-07-29):  ; 10-Q Q2 2026; FY2025 10-K (not fetched). | **+25.5%** | $10.6B | 0.40 AMZN |
| 4 | AVGO | Broadcom | ~$1.69T | Information Technology / Semiconductors | 1,4 | Custom AI XPU + networking: AI semiconductor revenue $16.7B in FQ3 FY26 (+221% YoY), six XPU customers (Google, Anthropic, OpenAI...); mgmt guide FY26 AI $58B, ~$115B FY27, ~$230B FY28. | FQ3 FY26 release (2026-09-02):  ; 10-Q qtr ended 2026-08-02; FY2025 10-K (not fetched). | -7.0% | $5.1B | 0.62 TSM |
| 5 | TSLA | Tesla, Inc. | ~$1.47T | Consumer Discretionary / Automobile Manufacturers | 4,1 | Optionality on robotaxi/Cybercab/Optimus; core auto and energy growing but profitability thin: Q2 2026 revenue $28.24B +26%, GAAP operating margin 1.4%. | Q2 2026 update 8-K  (2026-07-22) | -0.6% | $10.2B | 0.47 TSM |
| 6 | MU | Micron Technology | ~$1.22T | Information Technology / Semiconductors | 4,5 | HBM/DRAM supercycle: FQ4 FY26 revenue $54.2B +379% YoY, FY26 $133.2B +256%; FQ1 FY27 guide $61.5B midpoint, GM 86.25%; supply tight through FY27-28. | Latest earnings release (see sources); 10-K not fetched | **+17.6%** | $16.8B | 0.63 TSM |
| 7 | BRK-B | Berkshire Hathaway Inc. (Class B) | ~$1.07T | Financials / Multi-Sector Holdings | 3 | First-year succession under CEO Greg Abel beginning to deploy $365.5B cash: Q2 2026 operating earnings $12.98B +16%, ~$4.5B buybacks, ~$20B net equity purchases. | 10-Q  ; Q2 report  (~2026-08-08) | -0.4% | $1.2B | 0.18 ISRG |
| 8 | LLY | Eli Lilly and Company | ~$1.02T | Health Care / Pharmaceuticals | 1,4 | Incretin franchise (Mounjaro/Zepbound) plus new oral Foundayo (orforglipron) and retatrutide (BLA planned Q1 2027) form a multi-cycle obesity/diabetes roadmap; Q2 CY2026 revenue $23.0B +48% YoY (volume +60%, price -13%). | Q2 2026 earnings release (8-K, ~2026-08-05)  ; Q2 10-Q  ; FY2025 10-K (not fetched this session); EASD 2026 data presentations announced. No 2026 investor day verified. | -0.9% | $1.2B | 0.20 ISRG |
| 9 | ASML | ASML Holding (ADR) | ~$715B | Information Technology / Semiconductor Equipment | 1,5 | Sole EUV supplier; 2026 guide raised twice to EUR43-45B net sales (from EUR36-40B), Q2 2026 sales EUR9.3B, GM 54.0%; capacity +30% for low-NA EUV in 2027 (up to ~80 units if demand supports). | Q2 2026 results (2026-07-15):  ; 20-F FY2025 / annual report 2025 (asml.com/en/investors/annual-report/2025, not fetched). | +8.6% | $1.5B | 0.73 TSM |
| 10 | V | Visa Inc. | ~$670B | Financials / Transaction & Payment Processing Services | 4,2 | Secular cash-to-card and cross-border growth compounding at double-digit rate: FQ3 2026 net revenue $11.6B +14% (+13% cc), cross-border ex-intra-Europe +12%; legal overhang from DOJ debit suit and interchange MDL. | FQ3 2026 release 2026-07-28  ; 10-Q  ; FY2025 10-K (FYE Sept 30, 2025) not fetched. | -3.4% | $998M | 0.23 DIS |
| 11 | INTC | Intel | ~$634B | Information Technology / Semiconductors | 3,1 | Turnaround/foundry: Q2 2026 revenue $16.1B +25% YoY, Data Center AI $6.3B +59%; Foundry revenue $5.8B (+31%) loss $2.1B vs $3.2B a year ago; 14A on track for 2028. | Latest earnings release (see sources); 10-K not fetched | **+34.9%** | $8.0B | 0.52 TSM |
| 12 | ABBV | AbbVie Inc. | ~$462B | Health Care / Biotechnology | 1 | Skyrizi/Rinvoq replacing Humira: Q2 2026 Skyrizi $5.505B +24.4%, Rinvoq $2.525B +24.5%, immunology $8.79B +15.1%. | Q2 2026 release 2026-07-31  ; 10-Q | -0.0% | $406M | 0.14 RTX |
| 13 | LRCX | Lam Research | ~$437B | Information Technology / Semiconductor Equipment | 5,4 | Etch/deposition for NAND/DRAM/GAA: June-2026 qtr revenue $6.72B; Sept-qtr guide $8.10B +/-$0.4B (>20% QoQ), non-GAAP op margin guide 39.5%. | Latest earnings release (see sources); 10-K not fetched | **+17.2%** | $1.1B | 0.75 TSM |
| 14 | ORCL | Oracle | ~$429B | Information Technology / Application Software | 4,1 | AI cloud backlog: FQ1 FY27 revenue $19.3B +30%; OCI $7.4B +121%; RPO $664B (+$209B YoY); >$30B new AI contracts in qtr; FY guide $90B+ (OCI). | Latest earnings release (see sources); 10-K not fetched | -2.3% | $3.1B | 0.42 TSM |
| 15 | AMAT | Applied Materials | ~$428B | Information Technology / Semiconductor Equipment | 5,4 | WFE/advanced packaging: FQ3 FY26 record revenue $9.12B +25% YoY; Semi Systems $7B +27%; DRAM +52%; CY26 semi systems growth guided >30%, packaging >70%. | Latest earnings release (see sources); 10-K not fetched | **+19.8%** | $1.5B | 0.71 TSM |
| 16 | CAT | Caterpillar Inc. | ~$390B | Industrials / Construction Machinery & Heavy Trucks | 4,5 | Power-generation (data center gensets/turbines) now drives growth: Q2 CY2026 sales $20.5B +24%; Power Gen sales to users +72%; backlog $72B (+92% YoY). | Q2 2026 release (8-K ex991) ~2026-08; Q2 10-Q | +6.1% | $839M | 0.61 GEV |
| 17 | MRK | Merck & Co., Inc. | ~$354B | Health Care / Pharmaceuticals | 1,2 | Keytruda patent cliff (2028) bridge via Keytruda QLEX subcutaneous ($463M Q2) and Winrevair ($588M, +75%); Q2 2026 sales $16.6B +5%. | Q2 2026 release 2026-08-04  ; 10-Q | -4.0% | $553M | 0.20 RTX |
| 18 | UNH | UnitedHealth Group Inc. | ~$332B | Health Care / Managed Health Care | 3 | Margin-recovery turnaround: Q2 2026 medical care ratio 86.7% vs 89.4% in Q2 2025 (incl. $860M favorable prior-period development). | Q2 2026 release 2026-07-16  ; 8-K | -7.8% | $913M | 0.14 DIS |
| 19 | GE | GE Aerospace | ~$324B | Industrials / Aerospace & Defense | 1,4 | Installed-base flywheel: LEAP/GEnx/CFM56 shop visits and spares drive commercial services; Q2 CY2026 total orders $16.5B +17%, adj revenue $12.6B +24%, FCF $3.0B +43%; backlog >$210B incl ~$170B commercial services. | FY2025 10-K (not opened); Q2 2026 earnings release 2026-07-16 (SEC 8-K ge2q2026earningsrelease.htm); Q2 call 2026-07-16; investor day: UNVERIFIED | -5.7% | $672M | 0.53 RTX |
| 20 | NFLX | Netflix, Inc. | ~$279B | Communication Services / Entertainment (Movies & Entertainment) | 4,5 | Scale streaming with ad tier and pricing levers: Q2 2026 revenue $12.56B +13% (+12% FXN), operating margin 33.4%; ads targeted ~$3B in 2026 (roughly double 2025). | Q2 2026 shareholder letter 8-K (2026-07-16)  ; 10-Q | -16.0% | $1.5B | 0.30 DIS |
| 21 | KLAC | KLA Corporation | ~$270B | Information Technology / Semiconductor Equipment | 5,4 | Process control intensity rises with leading-edge logic, memory, packaging: FQ4 FY26 revenue $3.66B +15% YoY (record); FQ1 FY27 guide $4.0B +/-$0.2B. | Latest earnings release (see sources); 10-K not fetched | **+17.2%** | $978M | 0.72 TSM |
| 22 | ANET | Arista Networks | ~$260B | Information Technology / Communications Equipment | 4,5 | AI data-center Ethernet: Q2 2026 revenue ~ $3.0B +37.7% YoY, 2026 revenue guide raised to $12.6B (+40%), AI fabrics >= $3.5B, campus >= $1.25B; growth broadening beyond AI back-end. | Q2 2026 call transcript  (call ~2026-08-11); Q1 2026 8-K on EDGAR; FY2025 10-K (not fetched). 2025 Analyst Day was 2025-09-11; no 2026 analyst day verified. | +8.1% | $450M | 0.50 TSM |
| 23 | MRVL | Marvell Technology | ~$244B | Information Technology / Semiconductors | 4,1 | Custom AI silicon/optics: FQ2 FY27 revenue $2.739B +37% YoY; data center $2.172B +46%, 79% of sales; Q3 guide $3.15B +/-5%. | Latest earnings release (see sources); 10-K not fetched | **+27.4%** | $2.3B | 0.56 TSM |
| 24 | LIN | Linde plc | ~$220B | Materials / Industrial Gases | 4,5 | Industrial-gas toll-like contracts: Q2 CY2026 sales $9.3B +9%, adj EPS $4.50 +10%; sale-of-gas project backlog record $8.1B (total project backlog $11B), electronics/helium demand; FY26 adj EPS guide $17.70-17.90 (+8-9%). | FY2025 10-K (not opened); Q2 2026 release 2026-07-31 (8-K lin_ex991) and call transcript; Q2 10-Q | -3.6% | $438M | 0.13 RTX |
| 25 | IBM | IBM | ~$209B | Information Technology / IT Consulting & Other Services | 3,4 | Software mix shift under CEO Krishna: Q2 2026 revenue $17.2B +1%, software $7.8B +5% (Red Hat +11%, Data +19%); FY guide revenue +4-5%, software +6-8%; infrastructure -7%. | Latest earnings release (see sources); 10-K not fetched | -2.5% | $584M | 0.23 ISRG |
| 26 | QCOM | Qualcomm | ~$198B | Information Technology / Semiconductors | 4,3 | Diversification away from handsets: FQ3 FY26 revenue $9.95B -4% YoY; automotive record $1.59B +61% (23 straight double-digit quarters), handsets down ~20%; data center custom silicon starts Dec qtr (targets $5B FY27, $15B FY29). | Latest earnings release (see sources); 10-K not fetched | +9.3% | $1.2B | 0.30 TSM |
| 27 | CRM | Salesforce | ~$192B | Information Technology / Application Software | 4,3 | Agentforce/Data 360 monetization: AI & Data ARR ~ $3.9B (+210% YoY), Agentforce ARR >$1.5B (+240%), cRPO $33.5B +14%; revenue growth only ~11% and non-GAAP op margin 34.1% vs 34.3% a year ago. | Q2 FY27 press release (2026-08-26):  ; transcript  ; FY2026 10-K (FYE Jan 2026, not fetched). | -8.3% | $1.5B | 0.20 UBER |
| 28 | DE | Deere & Company | ~$184B | Industrials / Agricultural & Farm Machinery | 1,4 | Ag-cycle trough thesis: FQ3 FY2026 (qtr ended 2026-08-02) net income $1.379B, EPS $5.10 vs $4.75, sales $12.608B +5%; mgmt says 2026 is the cycle bottom; FY26 net income guide raised to $4.75-5.00B. | FQ3 FY26 release 2026-08-20 (8-K de-20260820xex99d1); 10-Q for 2026-08-02 | -1.3% | $463M | 0.14 DIS |
| 29 | ETN | Eaton Corporation plc | ~$170B | Industrials / Electrical Components & Equipment | 4,5 | Data-center and grid electrification: Q2 CY2026 sales $8.5B record +21% (organic +14%); data center organic revenue +65%; Electrical backlog +43% YoY; Boyd Thermal ($9.55B, closed 2026-03-12) adds liquid cooling. | FY2025 10-K (not opened); Q2 2026 release (8-K etn06302026exhibit99, ~2026-08-04/05; fool.com transcript dated 2026-08-07); Q2 10-Q | +11.9% | $458M | 0.67 GEV |
| 30 | NVO | Novo Nordisk A/S (ADR) | ~$165B | Health Care / Pharmaceuticals | 3,1 | Turnaround under CEO Mike Doustdar built on the Wegovy pill (>5M scripts; weekly scripts >265K wk ending Jul 17, ~90% US oral obesity share) against falling prices; Q2 2026 adjusted sales +7% CER. | Q2 2026 financial report 2026-08-04  ; 6-K  ; FY2025 20-F not fetched. | -17.1% | $403M | 0.22 UBER |
| 31 | UNP | Union Pacific Corporation | ~$165B | Industrials / Rail Transportation | 2,5 | Pending UP-NS merger (STB review): Q2 CY2026 EPS $3.36 +7%, net income $2.0B +6%, reported OR 59.7% (adj 59.2%, +110bp YoY; fuel hit 120bp). | Q2 2026 release 2026-07-23; Q2 10-Q | -6.3% | $259M | 0.18 DIS |
| 32 | BA | Boeing Company | ~$153B | Industrials / Aerospace & Defense | 3,2,1 | Turnaround under CEO Kelly Ortberg: Q2 CY2026 revenue $24.6B +8%, 171 commercial deliveries (+14%), FCF +$631M (vs -$200M), record backlog $715B; 737 ramping 42->47/mo with FAA concurrence; certification of 737-7/-10/777X pending. | FY2025 10-K (not opened); Q2 2026 release 2026-07-28; Q2 10-Q (ba-20260630.htm); investor day: UNVERIFIED | -6.5% | $971M | 0.36 RTX |
| 33 | NOW | ServiceNow | ~$140B | Information Technology / Application Software | 4,3 | Enterprise workflow/AI platform: Q2 2026 subscription revenue $3,877M +24.5% YoY (23% cc), cRPO $13.20B +21%; ServiceNow AI crossed $1B ACV; but non-GAAP op margin 29.5% down ~50bp YoY and stock fell ~6% on print. | Q2 2026 release (2026-07-22):  ; 10-Q Q2 2026; FY2025 10-K (not fetched). Armis ($7.75B) closed 2026-04-20; Moveworks closed 2025-12-15. | -3.6% | $974M | 0.28 UBER |
| 34 | VRTX | Vertex Pharmaceuticals Inc. | ~$128B | Health Care / Biotechnology | 1,2 | CF franchise (Alyftrek >$1B in H1 2026) funds a pipeline of non-CF launches (Journavx, Casgevy, povetacicept); Q2 2026 revenue $3.33B +12%. | Q2 2026 release (2026-08-03)  ; 8-K  ; pipeline/business update ahead of investor meetings  (date not verified) | -7.5% | $232M | 0.27 ISRG |
| 35 | LMT | Lockheed Martin | ~$117B | Industrials / Aerospace & Defense | 5,3 | Record backlog $230B (Q2 CY2026 book-to-bill 3.2, incl multi-year THAAD interceptor contract); sales $20.1B +11%; FY26 EPS guide raised to $29.95-30.65. | Q2 2026 release (8-K ex991q22026) ~2026-07-21/23; Q2 10-Q | -7.2% | $284M | 0.58 RTX |
| 36 | SBUX | Starbucks Corporation | ~$108B | Consumer Discretionary / Restaurants | 3 | Brian Niccol 'Back to Starbucks' turnaround: FQ3 2026 global comps +7.9% (transactions +4.2%), four consecutive quarters of comp growth and two of margin expansion. | FQ3 FY2026 release 2026-07-29  ; 10-Q | -10.6% | $325M | 0.23 DIS |
| 37 | FCX | Freeport-McMoRan | ~$103B | Materials / Copper | 4,3 | Copper supply-deficit + Grasberg recovery: Q2 CY2026 consolidated copper 786Mlb, realised copper $6.17/lb vs $4.54; Q3 copper ~830Mlb; Grasberg ramp to 80% capacity mid-2027, near full by YE2027. | Q2 2026 release (8-K a2q2026exhibit991); Q3 operational update 8-K 2026-10-02 | -4.4% | $479M | 0.54 TSM |
| 38 | PWR | Quanta Services | ~$102B | Industrials / Construction & Engineering | 4,5 | Grid/data-center build-out: Q2 CY2026 revenue $9.56B vs $6.77B (+41%), record backlog $53.4B (Electric $43.8B, incl ~$2.4B acquired); FY26 revenue guide raised to $39.3-39.7B. | FY2025 10-K (not opened); Q2 2026 release 2026-07-30; 2026 Investor Day 2026-03-31 (presentation on IR site) | +8.4% | $245M | 0.62 GEV |
| 39 | SPOT | Spotify Technology S.A. | ~$98B | Communication Services / Entertainment (Music Streaming) | 4,3 | Pricing power and gross-margin expansion on 300M subscribers: Q2 2026 revenue EUR4.8B +14% (+15% cc), gross margin 33.4% (record), operating income EUR655M (13.7% margin, +61% YoY). | Q2 2026 6-K 2026-08-04  ; transcript  ; FY2025 20-F not fetched. | -9.7% | $448M | 0.26 DIS |
| 40 | HWM | Howmet Aerospace | ~$92B | Industrials / Aerospace & Defense | 1,4 | Engine-airfoil/fastener supplier benefitting from commercial build rates and gas-turbine demand; Q2 CY2026 revenue $2.55B +24% (organic +21%), adj EPS $1.33 +46%, adj EBITDA margin 32.1%; commercial aero +28%, gas turbines +38%. | FY2025 10-K (hwm-20251231.htm); Q2 2026 release 2026-08-06; Q2 10-Q | -10.4% | $425M | 0.49 RTX |
| 41 | CEG | Constellation Energy Corporation | ~$90B | Utilities / Independent Power Producers | 4,2 | Nuclear scarcity premium plus Calpine scale (closed 2026-01-07): Q2 CY2026 adj operating EPS $2.55 vs $1.91; FY26 adj operating EPS guide raised to $11.50-12.50; hyperscaler PPAs (Microsoft/Crane 835MW, Meta/Clinton 1.1GW, CyrusOne, new 2026 deals). | FY2025 10-K (not opened); Q2 2026 release 2026-08-06; Q2 10-Q (ceg-20260630.htm); 2026-02 8-K | -7.6% | $435M | 0.42 TSM |
| 42 | GD | General Dynamics | ~$89B | Industrials / Aerospace & Defense | 5,1 | Q2 CY2026 revenue $14.1B +8.1%, EPS $4.24 +13.4%, record backlog $136.5B (+32% YoY); Gulfstream 41 deliveries, ~160 for FY26; FY EPS guide $16.80-16.90. | Q2 2026 release (investorrelations.gd.com) ~2026-07-22; call transcript fool.com 2026-08-07 (date of post) | -9.9% | $225M | 0.53 RTX |
| 43 | MELI | MercadoLibre, Inc. | ~$86B | Consumer Discretionary / Broadline Retail (Internet Retail) | 4,5 | LatAm e-commerce + fintech/credit compounder: Q2 2026 net revenue $10.2B +50% (+43% FX-neutral), GMV $21.9B +44% (+36% FXN), TPV $101B +56%, credit book >$16B +75%, but operating margin compressed to 6.7% from 12.2%. | Q2 2026 release 2026-08-05  ; transcript  ; FY2025 10-K not fetched. | -14.2% | $762M | 0.38 UBER |
| 44 | NOC | Northrop Grumman | ~$68B | Industrials / Aerospace & Defense | 1,3 | Q2 CY2026 sales $10.9B +5%, EPS $7.68, record backlog $105B (book-to-bill 1.84) incl +$7.6B Sentinel definitization; B-21 ramp. | Q2 2026 release 2026-07-21; Q2 10-Q | -9.6% | $214M | 0.65 RTX |
| 45 | HON | Honeywell Technologies (post-spin 'Honeywell International' on stockanalysis; ticker HON) | ~$68B | Industrials / Industrial Conglomerates | 3,2 | Separation completed: Solstice spun 2025-10-30; Honeywell Aerospace spun 2026-06-29 (NASDAQ: HONA; 1 share per 2 HON). RemainCo (Honeywell Technologies, HON) ex-Aerospace Q2 CY2026: sales $5.2B +3% (+4% organic), orders +16%, backlog ~$20B, adj EPS $1.95. | Q2 2026 release 2026-07-23 (honeywell.com/press-releases/2026/07); Aerospace 10-12B/10-Q under HONA | +1.8% | $246M | 0.43 RTX |
| 46 | BSX | Boston Scientific Corporation | ~$62B | Health Care / Health Care Equipment | 1,3 | Medtech product-cycle story (Watchman, Farapulse/EP, Penumbra pending) has broken: Q2 2026 organic +7.0% but Watchman only +4% and guided to decline mid-high single digits in H2; FY organic guidance cut to 5-6%, then a cyberattack (8-day global shutdown) made Q3/FY guidance unlikely to be met. | Q2 release 2026-07-29  ; call transcript  ; Wells Fargo conf. 2026-09-10 | -10.1% | $547M | 0.41 ISRG |
| 47 | NKE | NIKE, Inc. | ~$50B | Consumer Discretionary / Footwear | 3 | Elliott Hill turnaround ('Sport Offense', Pace restructuring) is still shrinking: FQ1 FY27 revenue $11.2B -4% reported (-5% cc), guide FY27 revenue down high-single digits. | FQ1 FY2027 release 2026-10-01 (quarter ended 2026-08-31)  ; 8-K Ex.99.1  ; FY2026 results/10-K (FYE 2026-05-31)  ; ARS | -7.8% | $889M | 0.36 DIS |
| 48 | VST | Vistra Corp. | ~$46B | Utilities / Independent Power Producers | 4 | Q2 CY2026 ongoing-ops adj EBITDA $1,767M +30%; 2026 guide reaffirmed $6.8-7.6B EBITDA, $3.925-4.725B FCFbG; 20-yr AWS PPA 1,200MW at Comanche Peak (delivery Q4 2027 ramping to 2032); Helix data-centre venture with KKR/NVIDIA/KIA. | Q2 2026 release 2026-08-07; Q2 10-Q | +1.2% | $375M | 0.47 TSM |
| 49 | CMG | Chipotle Mexican Grill, Inc. | ~$41B | Consumer Discretionary / Restaurants | 4 | Unit-growth compounder (100 new company restaurants in Q2, 80 with Chipotlanes) but comps slowed: Q2 2026 revenue $3.35B +9.3%, comps +2.2%, restaurant-level margin 25.2% vs 27.4%. | Q2 2026 results ~2026-07-29/30 | -13.8% | $296M | 0.21 DIS |
| 50 | CCJ | Cameco Corporation | ~$37B | Energy / Coal & Consumable Fuels (Uranium) | 4 | Uranium + Westinghouse: Q2 CY2026 adj net earnings $77M (adj EPS ~$0.13 vs $0.28 est), Westinghouse net loss $10M vs +$126M, share of adj EBITDA $163M vs $352M; LT uranium price at decade highs H1 2026; 2026 production guide 19.5-21.5Mlb unchanged. | Q2 2026 6-K (d125942dex991); Q2 MD&A on cameco.com | -11.0% | $171M | 0.48 TSM |

**Long-list notes.**

- **Semiconductor and AI-infrastructure cluster.** This covers NVDA, AVGO, ASML, MU, INTC, AMAT, LRCX, KLAC, MRVL, QCOM, ORCL, ANET, MSFT and META.
  - Seven names correlate above 0.6 with held **TSM**: NVDA 0.64, AVGO 0.62, ASML 0.73, MU 0.63, AMAT 0.71, LRCX 0.75 and KLAC 0.72. Each would join the GEV–TSM bucket (informational under Rev 35).
  - Every one of them also adds to the 66% AI-capex cluster (M3 F-9).
  - Six names are **rallying hard** on criterion 6: INTC +34.9%, MRVL +27.4%, META +25.5%, AMAT +19.8%, MU +17.6%, and LRCX and KLAC +17.2% each.
  - MU's +379% YoY revenue at an 86% gross-margin guide is a memory-pricing peak, not a 12-month structural trend metric.
- **Power and electrification cluster.** ETN, PWR and CAT correlate above 0.6 with held **GEV** (0.67, 0.62 and 0.61). They are the same AI-power thesis GEV already expresses.
  - ETN is +37% YTD and within 5% of its high.
  - CEG and VST stay de-rated (−36% and −34% from their highs) on PJM/ERCOT policy overhang.
- **Defense.** NOC correlates 0.65 with held RTX. LMT (0.58), GD (0.53) and GE (0.53) sit just under the 0.6 threshold. Accumulating defense alongside RTX concentrates Industrials, which is already the largest sector.
- **Turnarounds not yet turned.**
  - **NKE:** FQ1 FY27 (quarter to 08-31, reported 10-01, 8-K) revenue was $11.2B, −5% currency-neutral. Nike Direct fell 8%, Greater China fell 26% currency-neutral, and FY27 is guided down high-single-digits.
  - **BSX:** the Watchman slowdown, an early-September cyberattack (about 8 days of global shutdown, with management saying Q3/FY guidance is unlikely to be met) and a 2–4% 2027 organic framework mean the growth thesis is broken.
  - **NVO:** sales are guided to decline; it is −41% from its high.
  - **UNH:** the medical care ratio improvement is flattered by prior-period development.
  - **INTC:** the foundry is still loss-making, and the stock is rallying hard.
- **Event and binary names.**
  - **UNP:** Norfolk Southern merger. The STB lifted abeyance on 2026-08-18, the record closes around 2027-05-28 and a decision is due within 90 days. That is a Subtype A catalyst more than 12 months out, which is binary.
  - **FCX:** Grasberg permit-extension decision hoped for by YE2026, and the ramp to 80% by mid-2027.
  - **HON:** both separations are complete (Solstice 2025-10-30; Aerospace spun as HONA on 2026-06-29). The separation catalyst is therefore spent. HON's price series is spin-adjusted.
- **BA, re-screened on current facts.**
  - Execution is improving: Q2 FCF was +$631M against −$200M a year earlier, the 737 is ramping 42 → 47/month with FAA concurrence, and backlog is $715B.
  - The dated catalysts keep slipping. The FAA **delayed 737-10 certification on 2026-09-28** over go-around software. The 777X is not certifiable in 2026, with the FAA signalling early 2027. SPEEA engineers have authorised a strike, possible from about **2026-10-06/07**.
  - The 737-7 type certificate reported as granted 2026-08-03 comes from one secondary source and is **unverified**.
  - BA stays off the shortlist this quarter. It is not barred; its catalysts are unresolved.
- **CRM, re-screened as a fresh candidate.**
  - FQ2 FY27 (quarter to 07-31, reported 2026-08-26): non-GAAP operating margin was 34.1% against 34.3% a year earlier (prior-year figure 1-src). The exit criterion "contracts YoY" was therefore met, but by only about 20bp.
  - In the same quarter, cRPO was $33.5B (+14%), Agentforce ARR was above $1.5B (+240%), AI & Data ARR was about $3.9B (+210%; the ARR definition was widened to include Slackbot and Headless 360), and the FY guide was raised to $46.1–46.4B.
  - The exit followed an immutable criterion exactly as written, which is the design, and there is nothing to revisit.
  - As a **new** thesis, CRM's ~11% top-line growth rates **Medium**. Any re-entry would need a fresh trend metric that is robust to a few basis points of margin noise.
- **Financials.** These are now represented by **V**, a secular payments compounder, and **BRK-B**. BRK-B fits loosely: it has no earnings calls, so the 8-transcript input of criterion 2 is structurally unavailable.

---

## 2. PART 2 — Ranked shortlist (10) with readiness flags

The shortlist is ranked on four factors:
- thesis strength;
- evidence quality;
- **diversification away from the 66% AI-capex cluster** (criterion 3, concentration risk within D's existing book);
- regime and entry-timing fit (a hawkish +54bp rates shock favours cash-generative, non-extended entries).

**Q4 reads this section verbatim to schedule D thesis construction for the "ready now" names.** Two qualifications apply to every flag:
- The **`div-D-202609-1` router block** applies (§0). "Ready now" means ready for thesis construction once that block clears. It does not mean stage today.
- **Concentration is a caveat, not a block, while D is capital-disabled** (§0). Each card reports both the artifact reading and the restored reading.

**Common checkpoint.** Nine of the ten report calendar-Q3 results between 2026-10-20 and early November. Q4 may sensibly sequence thesis construction after each name's print, the way the 2026-Q3 cycle sequenced TSM and ISRG.

### Rank 1 — LLY (Eli Lilly) · Health Care / Pharmaceuticals · ~$1.02T
- **Thesis (Subtype B, with a Subtype A overlay).** The incretin franchise is still compounding at scale. Q2 2026 (reported 2026-08-05) revenue was **$23.0B, +48% YoY**, with volume +60% and price −13%. Mounjaro was **$9.9B, +91%**. Zepbound was $4.9B, +44–46% (sources differ).
  - The next legs are already scheduled:
    - **Foundayo** (orforglipron, oral) launched, with $98M in Q2 (1-src).
    - **Retatrutide's** Phase 3 package is complete. TRIUMPH-2 detail followed on 09-29: −20.8% weight loss at 80 weeks in T2D plus obesity. The **BLA is planned for Q1 2027**.
    - Orforglipron for T2D has been submitted to the FDA.
  - **Trend metric:** Mounjaro + Zepbound combined revenue grows **≥25% YoY for each of the next 4 quarters**. Q2 is about +60% on about $14.8–14.9B.
  - **Typing:** the retatrutide BLA *submission* is a company target, not a scheduled public decision date. The thesis files as Subtype B, with the BLA and its eventual PDUFA as overlay.
- **Evidence base:** large-cap IR with webcasts, 10-Qs and 10-Ks. The Lilly IR page returned HTTP 503 this session, so the release was read via PRNewswire. Criterion 2 must be confirmed at construction.
- **Invalidation (non-price):**
  - combined Mounjaro + Zepbound YoY growth below 20% in any quarter before Q2 2027;
  - retatrutide BLA submission slips beyond Q2 2027, or the FDA issues a refuse-to-file/CRL;
  - FY2027 guidance implies revenue growth below 15%;
  - Foundayo quarterly revenue flat or down QoQ for 2 consecutive quarters.
- **Catalysts and next test:** Q3 results **2026-10-29** (1-src; confirm on IR); EASD data; orforglipron T2D FDA action (date unverified).
- **Momentum:** trailing 30d **−0.9%**; 63d −5.3%; 10.2% below the 52-week high; close 2.4% under its 50-day SMA, with the 50-day above the 200-day. **Not rallying.** The run-up behind the April and June entry-timing NO-GOs has worked off on the merits.
- **Concentration:** joins ISRG in Health Care. A sizeable add takes HC from about 8% to the mid-teens on the artifact denominator, or about 1–3% restored. **Clear on both readings.** Correlation-bucket status: max 0.20 (ISRG), **no bucket**.
- **Thesis strength: Very High.** It has the largest verified growth trend on the list, the multi-product roadmap is dated, it is uncorrelated with the book and it is outside the AI cluster. The main risk is price erosion (MFN/TrumpRx; −13% realised price).
- **Readiness: READY NOW** (router-gated).
- **Queue reconciliation for Q4:** a `PENDING_ANALYSIS` item `rescreen-LLY-D-20261214` (due 12-14) already exists. Q4 should decide whether a ready-now thesis construction supersedes it, rather than run both.

### Rank 2 — V (Visa) · Financials / Transaction & Payment Processing Services · ~$670B
- **Thesis (Subtype B).** The secular cash-to-card and cross-border volume compounder.
  - FQ3 FY26 (quarter to 06-30, reported 2026-07-28; 8-K):
    - net revenue **$11.6B, +14% (+13% cc)**;
    - payments volume +10% cc;
    - cross-border volume excluding intra-Europe +12%;
    - processed transactions 71.7B (+10%).
  - **Trend metric:** net revenue grows **≥10% cc YoY for each of the next 4 quarters**, with cross-border ex-intra-Europe ≥10%.
- **Evidence base:** 10-Q and release from EDGAR; Visa IR hosts transcripts and 10-Ks. Completeness of 8 quarters and 2 annual reports is not yet verified.
- **Invalidation (non-price):**
  - net revenue growth below 8% cc in any quarter;
  - cross-border growth below 8% for 2 consecutive quarters;
  - a court-ordered debit-routing or interchange remedy in the DOJ debit case that materially cuts US debit revenue;
  - enactment of a statutory interchange cap or routing mandate (for example the Credit Card Competition Act).
- **Catalysts and next test:** FQ4 FY26 results, historically the last Tuesday of October (2026 date unverified). DOJ debit-case trial date unverified. A search hit on "DOJ suit Sept 24" was the **2024** filing, not a new event.
- **Momentum:** 30d **−3.4%**; 63d −0.6%; 6.3% below the 52-week high. **Not rallying.**
- **Concentration:** opens a **new sector**, Financials, at 0% today. **Clear on both readings.** Correlation: max 0.23 (DIS), **no bucket**.
- **Thesis strength: High.** The double-digit trend is verified, cash generation is high and it fits the hawkish regime well. It is the best diversifier on the list (correlation ≤0.23 with every held name). Risks are legal/regulatory and stablecoin disintermediation. The growth rate is steady rather than accelerating.
- **Readiness: READY NOW** (router-gated).

### Rank 3 — GE (GE Aerospace) · Industrials / Aerospace & Defense · ~$324B
- **Thesis (Subtype B).** An installed-base aftermarket flywheel: LEAP, GEnx and CFM56 shop visits and spares.
  - Q2 2026 (reported 2026-07-16): adjusted revenue +24%, orders $16.5B (+17%), FCF $3.0B (+43%), backlog above $210B including about $170B in commercial services. Internal shop visits and spares were each up about 25%.
  - **Trend metric:** Commercial Engines & Services services revenue grows **≥ low-teens % YoY for each of the next 4 quarters**, with LEAP deliveries growing about 10% or more a year.
- **Evidence base:** 8-K release; IR-hosted transcripts and 10-K (not opened this session).
- **Invalidation (non-price):**
  - CES services revenue growth below 10% YoY for 2 consecutive quarters;
  - LEAP annual deliveries fail to grow YoY, or the 2028 delivery target is withdrawn;
  - commercial backlog declines sequentially for 2 quarters;
  - FY FCF guidance cut by more than 10%.
- **Catalysts and next test:** **Q3 results 2026-10-20**, 07:30 ET (confirmed on the GE Aerospace webcast page).
- **Momentum:** 30d **−5.7%**; 63d −17.3%; 18.1% below the 52-week high; 8.8% under its 50-day SMA. **Not rallying** — this is a pullback entry.
- **Concentration (CAVEATED):** **Industrials already reads 33.37% on the capital-disabled artifact denominator**, so any GE add reads above 30% there. On the restored denominator Industrials is about 3.7%, about 5–6% after an add, which is clear. Not classed as blocked, per spec. Correlation: 0.53 with RTX, just under the bucket threshold, so **no bucket**.
- **Thesis strength: High.** The mechanism is durable and quantified and the metrics are accelerating, and it is outside the AI cluster. It adds to D's heaviest sector and to commercial-aero exposure alongside RTX. Fuel and oil-shock sensitivity in airline demand is the regime risk to attack.
- **Readiness: READY NOW** (router-gated). The sector reading is a flagged caveat pending A3/owner resolution of the denominator question.

### Rank 4 — VRTX (Vertex Pharmaceuticals) · Health Care / Biotechnology · ~$128B
- **Thesis (Subtype A + B, both required).**
  - **Subtype A anchor:** the povetacicept (IgAN) BLA was accepted under accelerated approval with a **PDUFA date of 2026-11-30**.
  - **Subtype B trend:** non-CF revenue ramps on the cash-generative CF franchise. Q2 2026 (reported 2026-08-03): total revenue $3.33B (+12%); Alyftrek above $1B in H1; Casgevy $76M (+151% YoY); Journavx $50M (more than 4× YoY); guidance embeds at least $500M of non-CF revenue in 2026.
  - **Typing (rev 30, by date arithmetic):** the catalyst resolves 59 days after today, which is ≤12 months, so **Subtype A is required**. The non-CF trend is independently evaluable inside the 12-month window, so **both subtypes apply** and invalidation is the union of the two menus.
  - **Timing constraint for Q4:** thesis construction must complete **before 2026-11-30**. After that date the catalyst is no longer future-dated, and the thesis would need re-typing as Subtype B only.
- **Evidence base:** BusinessWire release plus 8-K; Vertex IR hosts transcripts and the 10-K.
- **Invalidation (non-price):**
  - povetacicept CRL, or the PDUFA extended past 2026-11-30;
  - Journavx revenue flat or down QoQ for 2 quarters;
  - Casgevy below $150M in H2 2026;
  - Alyftrek/Trikafta franchise growth below 5% YoY.
  - Watch item, not a trigger: zimislecel (T1D) dosing completion was postponed pending a manufacturing analysis.
- **Catalysts:** PDUFA **2026-11-30**; positive inaxaplin (APOL1) Phase 2b on 09-22; suzetrigine DPN Phase 3 enrollment completing by end-2026; Q3 results (date unverified).
- **Momentum:** 30d **−7.5%**; 9.2% below the 52-week high. **Not rallying.**
- **Concentration:** Health Care; **clear on both readings** (it also stacks with LLY if both proceed: about 8% → about 20–25% artifact, or about 3% restored). Correlation: max 0.27 (ISRG), **no bucket**.
- **Thesis strength: High.** It has a dated catalyst and quantified launch ramps funded by a cash-generative franchise, and it diversifies away from the AI cluster. The binary PDUFA outcome is what the adversarial pass must price.
- **Readiness: READY NOW** (router-gated). **Time-boxed by the 11-30 PDUFA.**

### Rank 5 — MSFT (Microsoft) · Information Technology / Systems Software · ~$3.83T
- **Thesis (Subtype B).** Azure as the AI-workload platform.
  - FQ4 FY26 (quarter to 06-30, reported 2026-07-29): Azure and other cloud **+43% YoY**, accelerating from +40%. Azure passed $100B in FY26 revenue (+41%). Commercial RPO was **$678B (+84%)**. M365 Copilot has more than 30M paid seats.
  - **Trend metric:** Azure and other cloud services growth **≥35% YoY for each of the next 4 quarters**.
- **Evidence base:** FY26 10-K on EDGAR (FYE 06-30); IR call pages; transcripts widely mirrored.
- **Invalidation (non-price):**
  - Azure growth below 30% YoY in any quarter;
  - commercial RPO growth below 40% YoY;
  - an 8-K disclosure that OpenAI contract terms materially curtail Azure commitments;
  - capex guidance raised for 2 consecutive quarters without matching Azure acceleration.
- **Catalysts and next test:** FQ1 FY27 results, estimated around 2026-10-28 (unconfirmed).
- **Momentum:** 30d **+2.4%**, below the threshold, so **not rallying hard on criterion 6**. However, 63d is **+31.3%** and the close is 5.7% above its 50-day SMA. The rally from about −19% YTD in late September has paused rather than reversed, so thesis construction should re-check the 30d reading at entry.
- **Concentration:** joins TSM in IT (12.9% → low-20s artifact; about 2–3% restored); **clear on both readings**. Correlation: max 0.39 (AMZN), **no bucket**.
- **AI-cluster flag (F-9):** MSFT is a direct AI-capex name, so it raises the 66% cluster even though price correlation is low.
- **Thesis strength: High.** The metric is accelerating and backed by a very large contracted backlog. It ranks below LLY, V, GE and VRTX on the cluster flag alone.
- **Readiness: READY NOW** (router-gated; AI-cluster caveat).

### Rank 6 — SPOT (Spotify, NYSE-listed; Luxembourg-domiciled foreign private issuer) · Communication Services / Entertainment · ~$98B
- **Thesis (Subtype B).** Pricing power and gross-margin expansion at scale.
  - Q2 2026 (6-K, 2026-08-04): revenue €4.8B (+15% cc); gross margin **33.4% (record)**; operating income €655M (13.7% margin, +61% YoY); 300M premium subscribers (+9%); 777M MAU (+12%).
  - **Trend metric:** gross margin **≥32%** and operating margin **≥13%** each quarter, with net subscriber adds of at least 5M a quarter.
- **Evidence base:** 6-K, Fool transcript and 20-F (20-F not fetched); Spotify IR decks.
- **Invalidation (non-price):**
  - Q3 operating income below the €670M guide;
  - gross margin below 31%;
  - net subscriber adds below 3M in a quarter;
  - ad-supported revenue negative YoY cc for 2 quarters.
- **Catalysts and next test:** **Q3 results 2026-10-22**, pre-market (announced 2026-09-24).
- **Momentum:** 30d **−9.7%**; YTD −15.4%; 30.5% below the 52-week high. **Not rallying.** IBKR re-pull confirmed the 10-01 close at 491.40.
- **Concentration (CAVEATED):** **Communication Services reads 29.97% on the artifact denominator**, so any material SPOT add reads above 30% there. Restored it is about 3.3% → about 5%, which is clear. Not classed as blocked, per spec. Correlation: max 0.26 (DIS), **no bucket**.
- **Thesis strength: High.** Margin inflection is verified and there is a dated checkpoint. Risks: label royalty renegotiation, EUR reporting / FX, and the co-CEO transition after Ek stepped down in early 2026.
- **Readiness: READY NOW** (router-gated; sector reading is a flagged caveat).

### Rank 7 — MELI (MercadoLibre) · Consumer Discretionary / Broadline Retail · ~$86B
- **Thesis (Subtype B).** The Latin American commerce and fintech dual flywheel.
  - Q2 2026 (reported 2026-08-05; EDGAR exhibit): net revenue **$10.2B, +50% (+43% FX-neutral)** — the 30th consecutive quarter above 30%. GMV +36% FX-neutral. TPV $101B (+56%). Credit book above $16B (+75%).
  - **But operating margin fell to 6.7% from 12.2%.**
  - **Trend metric:** FX-neutral net revenue growth **≥30% for each of the next 4 quarters**, with operating margin ≥6%.
- **Evidence base:** EDGAR exhibit plus transcript; 10-K not fetched.
- **Invalidation (non-price):**
  - FX-neutral revenue growth below 30% in any quarter;
  - operating margin below 5%;
  - 15–90-day NPL above 8%;
  - TPV growth below 35% FX-neutral.
- **Catalysts and next test:** Q3 results around 2026-11-04 (provisional). A $1.0B 2036 note was priced 09-09.
- **Momentum:** 30d **−14.2%**; 28.6% below the 52-week high; 9.5% under its 50-day SMA. **Not rallying** — it is de-rating on margin concern.
- **Concentration:** joins AMZN in Consumer Discretionary (15.7% → low-20s artifact; about 2–3% restored); **clear on both readings**. Correlation: max 0.38 (UBER), **no bucket**.
- **Thesis strength: Medium-High.** The growth streak is exceptional and it sits outside the AI cluster. Margin compression from credit and logistics investment, together with EM credit quality under a rising-USD-rates regime, is the weak flank. The invalidation set includes the margin floor for that reason.
- **Readiness: READY NOW** (router-gated). Sequence thesis construction after the Q3 print, so the margin floor is tested on fresh data.

### Rank 8 — AVGO (Broadcom) · Information Technology / Semiconductors · ~$1.69T
- **Thesis (Subtype B).** Custom AI accelerators (XPU) plus AI Ethernet.
  - FQ3 FY26 (quarter to 08-02, reported 2026-09-02): AI semiconductor revenue **$16.7B, +221% YoY (+54% QoQ)**, across six XPU customers. Management framed FY27 at about $115B and FY28 at about $230B of AI revenue (per call summary; confirm against the transcript).
  - **Trend metric:** AI semiconductor revenue grows **≥100% YoY through FY27**. The FQ4 guide of $21.7B is the first check.
- **Evidence base:** release and 10-Q; FY25 10-K not fetched.
- **Invalidation (non-price):**
  - AI revenue misses the prior-quarter guide;
  - any sequential decline in AI revenue;
  - the FY27 AI target is cut or described as at risk;
  - loss or pause of a named XPU program is disclosed.
- **Catalysts:** FQ4 FY26 results in early-to-mid December (date unverified).
- **Momentum:** 30d **−7.0%**; 28.6% below the 52-week high. **Not rallying.**
- **Concentration:** joins TSM in IT; clear on both readings. **Correlation: 0.62 with TSM → joins the GEV–TSM bucket (informational only, Rev 35).**
- **AI-cluster flag (F-9):** AVGO is the purest addition to the AI-capex cluster on this list.
- **Thesis strength: High.** The roadmap is explicit and quantified. It ranks 8th for the cluster and bucket overlap and for customer concentration (AI-lab financing circularity).
- **Readiness: READY NOW** (router-gated; cluster- and bucket-cautioned). If Q4 can construct only a subset, construct AVGO last.

### Rank 9 — HWM (Howmet Aerospace) · Industrials / Aerospace & Defense · ~$92B
- **Thesis (Subtype B).** Engine airfoils and fasteners riding commercial build-rate and gas-turbine demand.
  - Q2 2026 (reported 2026-08-06): revenue $2.55B, **+24% (organic +21%)**; commercial aero +28%; gas turbines +38%; adjusted EBITDA margin 32.1%.
  - **Trend metric:** organic growth **≥12% YoY** with adjusted EBITDA margin **≥30%** each quarter.
- **Evidence base:** FY25 10-K and Q2 10-Q exist; transcripts not checked.
- **Invalidation (non-price):**
  - organic growth below 8% for 2 quarters;
  - adjusted EBITDA margin below 29%;
  - a formal 737 or 787 build-rate cut;
  - gas-turbine growth below 10%.
- **Catalysts and next test:** **Q3 results 2026-10-29** (howmet.com release 2026-10-01).
- **Momentum:** 30d **−10.4%**; 63d −15.5%; 22% below the 52-week high. **Not rallying** — a pullback.
- **Concentration (CAVEATED):** Industrials, on the same artifact reading as GE (already above 30%). Restored is about 4–6%, which is clear. If both GE and HWM proceed, aero concentration with RTX becomes a criterion-3 adversarial item. Correlation: 0.49 with RTX, **no bucket**.
- **Thesis strength: High** on metrics; valuation is premium. It is weaker than GE as a diversifier because it overlaps GE's aero driver.
- **Readiness: READY NOW** (router-gated; sector reading is a flagged caveat).

### Rank 10 — META (Meta Platforms) · Communication Services / Interactive Media · ~$1.86T
- **Thesis (Subtype B).** AI ranking lifts ad monetization.
  - Q2 2026 (reported 2026-07-29; 8-K): revenue **$60.8B, +28%** — impressions +14%, price per ad +12%.
  - The Muse agent app launched 2026-09-08.
  - **Trend metric:** revenue growth **≥18% YoY for each of the next 4 quarters**, with FCF positive.
- **Invalidation (non-price):**
  - revenue growth below 15% in any quarter;
  - negative quarterly FCF, or the capex guide raised above $160B without a revenue-guide raise;
  - ad impressions negative YoY;
  - an adverse structural FTC/EU remedy.
  - A reported state teen-addiction settlement of about $18B over 5 years is **unverified at primary source**.
- **Catalysts:** Q3 results around the week of 2026-10-26 (estimate).
- **Momentum:** 30d **+25.5%** — September was its best month since 2022 — and the close is **16.6% above its 50-day SMA**. **RALLYING HARD → criterion-6 deferral.**
- **Concentration (CAVEATED):** Communication Services, on the same artifact reading as SPOT. Correlation: 0.40 (AMZN), **no bucket**. It is an AI-capex-adjacent name ($130–145B 2026 capex).
- **Thesis strength: Medium-High.** Growth is strong and measurable, but FCF is near zero under the capex load, and the legal overhang is heavy.
- **Readiness: DEFERRED — pending rally pause.**
  - **Resolving trigger:** trailing-30d change at or below +10% *and* the close within 5% of the 50-day SMA, measured after the Q3 print.
  - **Conservative default:** skip — no construction this quarter if the trigger has not fired by the 2027-Q1 screen.

### Shortlist summary

| Rank | Ticker | Sector | Subtype | Trend / catalyst metric (latest) | 30d | Max corr vs held | Sector reading: artifact → restored | Readiness |
|---|---|---|---|---|---|---|---|---|
| 1 | LLY | Health Care | B (+A overlay) | Mounjaro+Zepbound ≥25% YoY ×4Q (Q2 ~+60%; revenue +48%) | −0.9% | 0.20 ISRG | HC 8% → clear / clear | **Ready now** (router-gated; reconcile 12-14 queue item) |
| 2 | V | Financials | B | Net revenue ≥10% cc ×4Q (FQ3 +13% cc) | −3.4% | 0.23 DIS | new sector / clear | **Ready now** (router-gated) |
| 3 | GE | Industrials | B | CES services ≥ low-teens % ×4Q (Q2 ~+25%) | −5.7% | 0.53 RTX | **33.4% artifact** / ~4% restored | **Ready now** (router-gated; sector caveat) |
| 4 | VRTX | Health Care | A + B | PDUFA 2026-11-30; non-CF ≥$500M FY26 | −7.5% | 0.27 ISRG | clear / clear | **Ready now** (router-gated; **construct before 11-30**) |
| 5 | MSFT | IT | B | Azure ≥35% YoY ×4Q (FQ4 +43%) | +2.4% (63d +31%) | 0.39 AMZN | clear / clear | **Ready now** (router-gated; AI-cluster caveat) |
| 6 | SPOT | Comm Services | B | GM ≥32%, OM ≥13% (Q2 33.4% / 13.7%) | −9.7% | 0.26 DIS | **30.0% artifact** / ~3% restored | **Ready now** (router-gated; sector caveat) |
| 7 | MELI | Cons Disc | B | FXN revenue ≥30% ×4Q, OM ≥6% (Q2 +43% / 6.7%) | −14.2% | 0.38 UBER | clear / clear | **Ready now** (router-gated; after Q3 print) |
| 8 | AVGO | IT | B | AI semi revenue ≥100% YoY through FY27 (FQ3 +221%) | −7.0% | **0.62 TSM** (bucket, info) | clear / clear | **Ready now** (router-gated; cluster/bucket caveat; construct last) |
| 9 | HWM | Industrials | B | Organic ≥12%, adj. EBITDA margin ≥30% (Q2 +21% / 32.1%) | −10.4% | 0.49 RTX | **33.4% artifact** / ~4% restored | **Ready now** (router-gated; sector caveat) |
| 10 | META | Comm Services | B | Revenue ≥18% YoY ×4Q (Q2 +28%) | **+25.5%** | 0.40 AMZN | **30.0% artifact** / ~3% restored | **Deferred** — rally pause |

**Ready-now set for Q4** (all router-gated on `div-D-202609-1`; attacker 10-05, orchestrator 10-06): **LLY, V, GE, VRTX, MSFT, SPOT, MELI, AVGO, HWM.**
- **Suggested construction order if capacity is limited:** LLY → V → VRTX (time-boxed by the 11-30 PDUFA) → GE → MSFT → SPOT → MELI → HWM → AVGO. This puts the diversifiers outside the AI cluster first.
- **No candidate is classified "blocked by concentration."**
  - The three Industrials and Communication Services names (GE, HWM, SPOT; META when un-deferred) read above 30% only on the capital-disabled artifact denominator. Per this routine's spec, that is carried as a flagged caveat, not a block.
  - If A3/owner resolves Entry criterion 5's denominator as the *current* (swept) NAV, those names become blocked until capital is restored or the book composition changes.
- **No shortlist addition requires an existing D position to close first.** There is no count cap, and the sector reading is caveated rather than binding. No close is recommended.

**Deferred set:**
- **META** — rally pause; trigger and conservative default are stated above.
- **Off the shortlist, not deferred items:** BA (737-10 certification slipped 09-28; possible SPEEA strike from about 10-06), NKE (FQ1 FY27 −5% cc; trend not turned) and NFLX (30d −16%, at the bottom of its 52-week range, revenue growth decelerating to +13% with operating margin down YoY — trend confirmation pending).
- Deferrals do not chain, and each name will be re-screened on its own facts next quarter.

**Dropped from the 2026-Q3 shortlist:**
- GOOGL, AMZN, ISRG, UBER, TSM and GEV are now held, and are excluded as open D book.
- CRM was exited (criterion 3, 2026-08-26). As a fresh thesis it rates Medium (see long-list notes).
- BA and NKE are covered above.

**Alternates if a ready-now name fails construction:** ABBV (Skyrizi + Rinvoq +24% each; 30d flat; 2.4% below its high; correlation 0.14) and ETN (data-center organic +65%, but GEV correlation 0.67 and +37% YTD — an AI-power cluster add).

---

## 3. Run notes

- **Sources and calls.** All price, momentum, ADV and correlation figures came from the IBKR connector (free): one contract per call; 66 candidate and held pulls plus one verification re-pull.
  - Thesis research used **122 free Anthropic `web_search` / `web_fetch` calls** across three research sub-agents.
  - **Zero** Tavily, FMP and Hugging Face calls.
  - Every metered call is logged one row per call in `ops.web_calls`.
- **Known soft spots, for thesis construction to firm up:**
  - market caps from undated aggregator pages;
  - several next-earnings dates unverified (marked as such above);
  - GICS labels from general knowledge for the technology names;
  - criterion-2 evidence completeness unverified for all names;
  - figures marked (1-src).
- **Nothing in this screen is an order, a staging instruction or a disposition.** The only consumer is Q4's thesis-construction scheduling.

2026-11-01
<!-- d1_scan_through_utc: 2026-11-01T22:30:01Z -->

# Daily Market Development Scan — session 2026-10-30 (Fri), run 2026-11-01 (Sun)

Scan window: 2026-10-29 16:03 MT → 2026-11-01 15:30 MT (~72h). The start is the prior `Daily.md` marker `2026-10-29T22:03:00Z`, which agrees with that file's commit (22:44Z) and with `state.routine_catchup_window` (last completion 22:49Z). **The window exceeds 50 hours** because D1 runs Sunday to Thursday and there is no Friday or Saturday run; it holds **one completed US session, Friday 2026-10-30**, plus Thursday after-hours and the weekend. Moves are 10-29 → 10-30 close-to-close on IBKR regular-session daily bars.

Tape: **an AI/semis liquidation.** Intel's 10-29 after-close print set off the selloff, on top of Alphabet's 10-29 drop and Amazon's capex. Defensives and energy rallied.
- **Indices.** IBKR closes, 10-29 → 10-30: SPY 769.36 → **755.72 (−1.77%, 2.05x volume)**, QQQ −3.47%, DIA −1.07%, RSP −0.79%, IWM −1.65%, **SMH −6.98% (3.1x volume)**. SPX 7720.39 → 7580.07 (−1.82%).
- **Volatility.** VIX 17.20 → **19.42** (IBKR IND/CBOE bar; intraday high 23.93), still inside the 15–25 NORMAL band.
- **Rates and havens.** TLT +0.43%, HYG −0.19%, GLD −3.47%. The 10Y was about 4.93% (investing.com, discovery only).
- **Oil.** Brent (BZUSD, FMP read 2026-11-01) was **113.43 on 10-30**, against **110.80 on 10-29** in the same series (+2.37%). The stored 10-29 value is the provisional 111.57, which the vendor has since revised. USO +0.38%.
- **Breadth.** Down to **59.44** (from 63.81), from a single EODData source. ChartRow agrees (−4.02pp vs −4.37pp).

## TL;DR

- **Exits triggered: none.** None of the twelve D tranches has a mechanical trigger. AMZN's 10-Q (AWS +39.3%, 38.7% margin, backlog about $578B against $496B) and GOOGL's 10-Q (Cloud +102.6%, backlog $560.8B) breach no criterion.
- **New entry candidates: none routed.** 50 names cleared Strategy B's frozen ≥5% floor on their own events, led by RDDT, INTC, CDNA, CACC, ILMN, RBLX, BFAM, TFII, TWLO and FDXF. B is `DO-NOT-ACTIVATE` and capital-disabled, so all 50 go to the index only.
- **Add candidates: none (0 of 12).** Eight tranches carry a trigger: AMZN ×2 strengthened conviction; GOOGL ×2, TSM ×2, ISRG and GEV dip-with-intact-thesis. D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 50 changes.** ADD the 50 names to the Strategy B new-entry index.
- **Regime review: no review.** Iran's 11-01 48-hour Hormuz reopening plan is a conditional proposal, not a settlement in force. The US blockade of Iranian ports is still in force and Brent rose +2.37% into the 10-30 close, so this is not a qualifying resolution event. New tanker-mine and strike-threat headlines fall inside the standing `acute` overlay.

Park: VOO-only pin verified

Paper book (J): 120 calls, 189/30 realized, net_mu -0.54%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Hormuz / Gulf (ongoing war; no resolution event).**
  - **The 11-01 offer.** Foreign Minister Araghchi offered to reopen Hormuz within 48 hours, via Qatari mediators: the US acts on day 1 and shipping resumes on day 2 (investing.com; houseofsaud.com, 11-01). It is a **conditional proposal**. The conditions are sanctions relief, release of about $12B in frozen funds, restored oil waivers, recognition of an Oman-designated route, a smaller US military presence, and an end to attacks on Lebanon.
  - **Status.** The US has not accepted it. Security chief Rezaei says the strait stays shut until the conditions are met. Iran held a third day of talks with Qatar in Doha, and no direct US-Iran talks are planned. Iran rejected a Qatari draft on 10-30.
  - **In force.** The US naval blockade of Iranian ports (CENTCOM: 144 commercial ships redirected) and the Hormuz closure. Iran's "Persian Gulf Strait Authority" threatened legal action against Sinokor ships from 11-01 (Gulf News 10-29).
  - **Escalation, inside the standing `acute` overlay.**
    - Trump's pre-midterm strike moratorium expires on 11-03, and he renewed threats against the "Pickaxe Mountain" nuclear site.
    - Mojtaba Khamenei ordered commanders to prepare an immediate response to any attack.
    - Iran says four tankers hit mines; the US called the claim false.
    - A Qatari gas carrier was reportedly hit (UNCONFIRMED; the source page returned 403).
  - **Brent (context).** About 113.10 at the 10-30 close (investing.com) and +13.6% in October. The measured level is in item 4.
- **Crypto shock.** Binance disclosed a **$6.3B exploit** on 10-29/30, which the FBI and TRM attribute to North Korea. BTC fell to a six-week low of about $76.1k with $1.57B of liquidations (CNBC, CoinDesk), and was about $78.0k on 11-01. Binance says about 90% of the stolen funds have been replenished. COIN (−10.6% on its own print) and MSTR (−7.8%) sold off with crypto equities.
- **Other geopolitics.**
  - Israel's election left both blocs short of a majority, with more than 96% counted.
  - Lula won Brazil's runoff with 51.79%.
  - The US approved a $2.1B sale of 500 Patriot interceptors to Ukraine and eased some Russian diesel sanctions.
  - US-China tariffs and sanctions: unmeasured.
- **M&A.** These deals are in or near the window:
  - DoorDash–Instacart, $17B (10-29, pre-window)
  - Thrive–ADT take-private, $7.6B (10-29)
  - Affle–Perion, about $420M at $11.70 per share (11-01)
  - GE Vernova agreed to buy a high-voltage grid component maker (Bloomberg 10-30; a held name, with no criterion bearing)
  - REGN expanded its Sanofi collaboration ($1.0B upfront)
  - Rumour, UNCONFIRMED: Marvell in talks for Lumentum.
- **Unmeasured:** bankruptcies and enforcement actions. Anthropic filed US IPO paperwork earlier in the week (Economic Times).

### 2. Scheduled events that resolved in the window

- **Macro (10-30).**
  - **Q3 Employment Cost Index:** +0.8% q/q, in line.
  - **September personal income and outlays:** core PCE +0.3% m/m and 3.12% y/y, real spending flat, incomes down the most since April, saving rate 3.8% (the lowest since October 2022) (TheStreet).
  - **UMich final sentiment:** 48.0 (UNCONFIRMED; single social-media source).
  - **Chicago PMI:** unmeasured.
- **BoJ (10-30).** Held at 1.25%, as expected. It raised its inflation forecast and stressed readiness to keep hiking (Reuters).
- **Fed.** After the 10-28 hold (10-2), Logan said at least two more 25bp hikes and Musalem said more tightening "soon"; Barkin favours a gradual path. December hike odds were about 72% at week-end, from 78% (TheStreet). ECB and BoE in the window: unmeasured.
- **Week of 11-02.**
  - 11-02: ISM Manufacturing, Treasury borrowing estimate.
  - 11-03: US midterms, JOLTS, RBA.
  - 11-04: ADP, ISM Services, Treasury quarterly refunding.
  - 11-05: BoE (a hike is expected).
  - 11-06: October payrolls (consensus +65k, unemployment 4.2%).
  - Earnings: AAPL and PLTR 11-02, AMD and PFE 11-03, QCOM and **UBER (held) 11-04 08:00 ET**.
- **Earnings enumeration (Nasdaq key-less calendar, curl).** 10-29 lists 323 rows, 209 at or above $2B; its after-close reporters reacted on 10-30. 10-30 lists 66 rows, 40 at or above $2B, including XOM, ABBV, CVX, AZN, BP, SNY, GD, REGN, CL, D, EXC and CCJ. The calendar's `time` field was `time-not-supplied` on every row, so release timing comes from EDGAR acceptance times (EVENT-IDENTITY GATE). Per-name outcomes for the written-up movers are in item 3. XOM, CVX and ABBV results were not extracted; their moves were under 4%.
- **FDA.** fda.gov's 10-30 press announcement confirms the **accelerated approval of Voceryq (INO-3107)**, sponsor Inovio, for adult recurrent respiratory papillomatosis. REGN's 10-30 release cites an FDA approval for FOP (issuer source only). Agios mitapivat (sickle cell, aggregator PDUFA 11-01) is **unresolved** against FDA's own pages, and AGIO fell −17.9% on 10-30 with no identified event. Other PDUFA outcomes 10-29..11-01: unmeasured.


### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `e2dfa715-80cb-4d38-81fb-fe3310e21cfd` (single-name-move): **surfaced_count 54** (50 own-event floor clearers + 4 sub-floor context names), rail_tally 50, agreement both 50 / ai_only 4 / rule_only 278.
- **Discovery.** The Nasdaq screener table still carried the 10-29 session on Sunday, so I pulled each ≥$2B symbol's Nasdaq quote/info closing print stamped Oct 30, 2026: 2137 of 2,151 (14 had no print). 905 moved ≥2% and 328 moved ≥5%.
- **Attribution.** All 446 names moving ≥4% were mapped to EDGAR acceptance times and the Nasdaq earnings calendar in two disjoint sub-agent legs (A–L, M–Z), with no overlapping tickers. Most of the ≥5% movers share a common driver rather than an own event: the AI/semis/hardware selloff (about 95 names, e.g. AMD −10.9%, QCOM −11.1%, ARM −10.0%, DELL −10.8%), crypto after the Binance hack (about 20), gold/silver and metals miners (about 44), software (about 39), space/quantum/nuclear and life-science tools. Those are counted, not written up.
- **Confirmation.** IBKR regular-session close arrays were pulled for 66 contracts. Every `metric_pct` below reproduces `(event_close/prior_close − 1) × 100`.
- **Anchors.** A 10-29 after-close release anchors on 2026-10-29 with 10-30 as the reaction session; a 10-30 pre-open release anchors on 2026-10-30. **ENHA (−26.96%), AGIO (−17.94%) and GPN (+12.97%) have no identifiable event**, so their anchors are UNRESOLVED and they are recorded under `rejected_notable`. ENHA's series is split-adjusted for a 1-for-10 reverse split on 10-29. FTRE, ALGM, LAUR, GTX, IDCC, ESTA, ATI and IOVA are day-two moves on 10-29 pre-open events (IOVA −11.3% more after −35.4%).
- **Close-chain check.** No hits. Only AXTI, SAN and MSTR have earlier items, all on different anchors. Coverage is thin, so this is not a clearance.
- **No event found** (Nasdaq figures, not IBKR): TXG -14.03%, TWST -11.92%, PENG -11.67%, CSQR -11.10%, AAON -10.49%, ALMR -10.11%, GRAL -9.75%, SDGR -9.50%, BB -8.38%, GENB -8.31%, BHC -7.97%, FRVO -7.95%, CHRN -7.91%, CDLR +7.76%.

Own-event floor clearers (IBKR closes, conviction, anchor, other ≥5% sessions in the 10-session window):

- **RDDT** -29.22% (129.6 → 91.73; 75; anchor 2026-10-29). Q3 rev $895M +53% y/y, EPS $1.40 vs $1.31 cons (Nasdaq cal); Q4 rev guide $1.000-1.030B per web snippet (pre-print preview expected ~$1.05B, inference only); stock -29% on heavy volume.
- **INTC** -28.58% (92.07 → 65.76; 75; anchor 2026-10-29; 2 other ≥5% session(s)). Q3 results 8-K after close 10-29; stock -30% on 10-30 on the print, drove AI/semis selloff.
- **CDNA** +22.22% (71.52 → 87.41; 75; anchor 2026-10-29). Q3 results after close 10-29; shares +22%.
- **CACC** -19.26% (575.78 → 464.89; 75; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 results after close 10-29; shares -19%.
- **ILMN** -18.64% (290.06 → 235.99; 75; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 results after close 10-29; shares -18.6% (tools/guidance reaction).
- **RBLX** -18.05% (52.46 → 42.99; 75; anchor 2026-10-29). Q3 report 8-K item 2.02/7.01; EPS -$0.32 vs -$0.41 cons (cal); stock -18% — web search could not confirm cause (only prior-quarter negative-bookings guide found).
- **BFAM** -17.92% (66.98 → 54.98; 75; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 results plus Item 5.02 officer change after close 10-29; shares -18%.
- **TFII** -17.08% (112.54 → 93.32; 75; anchor 2026-10-29). 6-K Q3 results; Finsee snippet: Q4 adj EPS guide $1.30-1.40 vs Q3 $1.70-1.80 plan, first outlook miss in six quarters; EPS $1.67 vs $1.75 cons (cal, -4.6%).
- **TWLO** -15.24% (241.9 → 205.03; 75; anchor 2026-10-29; 2 other ≥5% session(s)). Q3 rev $1.56B +20% (organic +16%), non-GAAP EPS $0.90 vs $0.74 cons (cal); stock -15% despite beat; one German AI-generated snippet cites FY growth guide raised to 20% - cause of drop unverified.
- **FDXF** +14.91% (109.69 → 126.04; 60; anchor 2026-10-29). FedEx Freight FQ1 results after close 10-29; shares +15%.
- **SKYW** -14.72% (96.54 → 82.33; 60; anchor 2026-10-29). Q3 EPS $3.08 vs $3.13 cons (cal), pre-tax $159M; results hurt by higher fuel cost in prorate business; stock -14.7%.
- **MEOH** +14.04% (62.76 → 71.57; 60; anchor 2026-10-29). 6-K filings 10-29 17:05/17:12 ET (post-close) and 10-30; Q3 EPS $3.69 vs $3.17 cons (cal); stock +14%.
- **SNDK** -13.47% (1330.05 → 1150.89; 60; anchor 2026-10-29; 5 other ≥5% session(s)). FQ1'27 rev $11.0B +23% q/q, non-GAAP EPS $49.51 (cal $48.92 vs $46.19 cons); FQ2 rev guide $12.2-12.6B, 8-for-1 split announced; stock -13.5% amid semis/memory selloff.
- **REGN** +13.33% (818.77 → 927.89; 60; anchor 2026-10-30). Q3 rev $5.1B +36%, non-GAAP EPS $20.07 vs ~$13.76 cons (cal); expanded Sanofi collaboration with $1.0B upfront (up to $7B milestones); FDA approval of Pasatru for FOP; stock +13.3%.
- **CVCO** +13.11% (547.25 → 619; 60; anchor 2026-10-29; 1 other ≥5% session(s)). FQ2 results after close 10-29; shares +13%.
- **BTSG** +11.08% (60.22 → 66.89; 60; anchor 2026-10-30). Q3 results pre-open 10-30; shares +11%.
- **GDDY** +10.72% (105.89 → 117.24; 60; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 results after close 10-29; shares +10.7%.
- **COIN** -10.62% (160.59 → 143.54; 60; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 results after close 10-29 (EPS fcst -0.16); shares -10.6% alongside crypto weakness.
- **SXT** -10.57% (131.53 → 117.63; 60; anchor 2026-10-30). Q3 rev $455.8M +10.6%, op income +25.5%, EPS $1.13 vs $1.03 cons (cal); stock -10.6% — cause not identified (possible guidance/margin).
- **AXTI** -9.56% (60.88 → 55.06; 60; anchor 2026-10-29; 6 other ≥5% session(s)). Q3 results after close 10-29; shares -9.6% amid semis selloff.
- **GTES** -9.22% (26.25 → 23.83; 60; anchor 2026-10-30; 1 other ≥5% session(s)). Q3 results pre-open 10-30; shares -9.2%.
- **RMD** -9.05% (252.83 → 229.94; 60; anchor 2026-10-29). FQ1'27 rev +6% to $1.4B, non-GAAP EPS $2.91 vs $2.67 cons (cal); stock -9%.
- **NWG** -9.00% (17 → 15.47; 60; anchor 2026-10-30). Q3 2026 results; EPS $0.52 vs $0.51 cons (cal); ADR -9.0%.
- **NVT** -8.81% (138.15 → 125.98; 60; anchor 2026-10-30; 1 other ≥5% session(s)). Q3 EPS $1.52 vs $1.40 cons (cal); stock -8.8% despite beat, in AI-infrastructure selloff.
- **CCJ** -7.88% (83.49 → 76.91; 45; anchor 2026-10-30). Cameco Q3 6-K pre-open 10-30; shares -7.9%.
- **MSTR** -7.84% (141.62 → 130.51; 45; anchor 2026-10-29; 3 other ≥5% session(s)). Q3 EPS $44.75 (bitcoin gains $20.9B; cal cons $21.50); 848,517 BTC held; 8-K also items 3.03/5.03/5.07 (STRC changes); stock -7.8% with crypto weakness.
- **MMSI** -7.66% (93.39 → 86.24; 45; anchor 2026-10-29). Q3 rev $416.2M +8.4%, non-GAAP EPS $1.12 vs ~$0.93 cons (cal), raised FY26 guidance; stock -7.7% nonetheless.
- **HGV** +7.64% (35.71 → 38.44; 45; anchor 2026-10-30). $200M uncollared ASR with Deutsche Bank announced pre-open 10-30 (8-K 1.01); earnings were pre-open 10-29.
- **TBBK** -7.46% (50.52 → 46.75; 45; anchor 2026-10-29). Q3 EPS $1.53 (cal $1.47 vs $1.48 cons); stock -7.5%.
- **RKT** +7.38% (11.92 → 12.8; 45; anchor 2026-10-29; 2 other ≥5% session(s)). Q3 GAAP NI $709M, adj NI $419M, EPS $0.12 vs $0.11 cons (cal); highest margin in ~5 yrs; stock +7.4%.
- **MHK** +7.25% (129.99 → 139.41; 45; anchor 2026-10-29; 1 other ≥5% session(s)). Q3 EPS $2.72 vs $2.56 cons (cal); stock +7.25%.
- **PIPR** -7.14% (68.72 → 63.81; 45; anchor 2026-10-30). Q3 advisory rev +18% y/y, new buyback authorization; EPS $0.87 vs $0.93 cons (cal, -6.5%); stock -7.1%.
- **AZN** +7.02% (174.4 → 186.65; 45; anchor 2026-10-30). AstraZeneca 9M/Q3 results 6-K pre-open 10-30; ADR +7.0%.
- **MIAX** +6.97% (31.44 → 33.63; 45; anchor 2026-10-29). Q3 EPS $0.45 vs $0.36 cons (cal); stock +7.0%.
- **PTCT** -6.97% (64.46 → 59.97; 45; anchor 2026-10-29). Q3 total rev $358M, raised FY26 rev guide to $1.29-1.32B, acquired ST-920 Fabry gene therapy; EPS $0.61 vs $0.17 cons (cal); stock -7.0% (reaction contrary to beat; cause unverified).
- **CBOE** +6.77% (314.25 → 335.53; 45; anchor 2026-10-30). Q3 results pre-open 10-30; shares +6.8%.
- **VLTO** +6.77% (104.06 → 111.1; 45; anchor 2026-10-29). Q3 sales $1,509M +7.5%, adj EPS $1.18 vs $1.10 cons (cal); stock +6.8%.
- **RBC** -6.76% (495.74 → 462.21; 45; anchor 2026-10-30; 1 other ≥5% session(s)). FQ2'27 net sales $524.6M +15.2%, EPS $3.53 vs $3.39 cons (cal); stock -6.8%.
- **BHVN** -6.49% (16.49 → 15.42; 45; anchor 2026-10-29; 6 other ≥5% session(s)). Q3 results after close 10-29; shares -6.5%.
- **INVX** -6.40% (30 → 28.08; 45; anchor 2026-10-29; 2 other ≥5% session(s)). Q3 results + Reg FD after close 10-29; shares -6.4%.
- **SYK** -6.38% (311.75 → 291.86; 45; anchor 2026-10-29). Q3 sales $6.5B +7.7% organic, adj EPS $3.52 vs $3.56 cons (cal, -1.1%); stock -6.4%.
- **RIVN** +6.20% (11.45 → 12.16; 45; anchor 2026-10-29). Q3 rev $2.155B +38%, deliveries +46%, guidance raised across all metrics; EPS -$0.62 vs -$0.84 cons (cal); stock +6.2%.
- **AN** +6.08% (169.34 → 179.64; 45; anchor 2026-10-30; 2 other ≥5% session(s)). Q3 results pre-open 10-30; shares +6.1%.
- **COLM** +6.04% (63.69 → 67.54; 45; anchor 2026-10-29). Q3 results after close 10-29; shares +6.0%.
- **BBIO** +5.97% (70.73 → 74.95; 45; anchor 2026-10-29). Q3 results after close 10-29; shares +6.0%.
- **IMO** +5.52% (130.87 → 138.1; 45; anchor 2026-10-30). Imperial Oil Q3 results pre-open 10-30; shares +5.5%.
- **FND** -5.46% (50.34 → 47.59; 45; anchor 2026-10-29; 2 other ≥5% session(s)). Q3 results + Item 5.02 after close 10-29; shares -5.5%.
- **TGS** -5.40% (25.02 → 23.67; 45; anchor 2026-10-29). Q3 results; EPS $0.49 vs $0.67 cons (cal, -27%); ADS -5.4%.
- **ATR** +5.02% (130.64 → 137.2; 45; anchor 2026-10-29). Q3 results after close 10-29 (17:08 ET); shares +5.0% (intraday high +8.9%).
- **LYB** +5.00% (65.37 → 68.64; 45; anchor 2026-10-30). Q3 results pre-open 10-30; shares +5.0%.

Sub-floor context (never B candidates): TECK -4.88% (63.72 → 60.61); EXEL +4.82% (66.2 → 69.39); SAN -4.77% (11.75 → 11.19); OMF -4.70% (59.34 → 56.55).

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` NOT WRITTEN — the digest-checked call was refused three times for a transcription mismatch and, per the bounded-retry rule, nothing was written by any other path (in-run issue `research_screen_write_refused`); the measurements below are this run's (sector-move): **a tech liquidation with a defensive bid, surfaced_count 3.** All 11 SPDRs were measured on their registry contract ids, and the 10-29 closes match the prior run's event_close on every SPDR and on 10 tape symbols.
- **XLK −4.89%** (188.74 → 179.51; conviction 75; legacy 2% pass; 2.7x volume). The centre of the AI/semis liquidation: Intel's 10-29 after-close print (cash burn, and a PC-demand warning tied to the memory-chip shortage) landed after Alphabet's 10-29 drop and Amazon's ~$220B capex. SMH fell −6.98% on 3.1x volume.
  - Goldman described asset managers as net sellers with ETFs about 31% of volume, and the S&P closed below its 100-day average for the first time since April (TheStreet).
- **XLE +1.91%** (68.71 → 70.02; conviction 45; legacy fail). Brent rose +2.37% (FMP BZUSD 110.80 → 113.43) as Hormuz stayed shut, and XOM, CVX and IMO (+5.52%) reported before the open.
- **XLP +1.41%** (88.18 → 89.42; conviction 45; legacy fail; 2.0x volume). A defensive rotation, with XLU +0.67%, XLV +0.45% and TLT +0.43% also up.
- **Not surfaced:**
  - XLI −1.60% and XLC −1.29% (index-like; XLC is follow-through after 10-29's −1.87%).
  - XLF −0.76%, XLY −0.71%, XLB +0.40%, XLU +0.67%, XLV +0.45% and XLRE +0.26%.
- Five of 11 SPDRs rose. RSP beat SPY by 0.98pp, and breadth fell −4.37pp.

### 5. Notable commentary

- **Flows (S5).** Goldman's desk and BofA described systematic, ETF and gamma-driven selling into month-end. VVIX was the highest since March and BofA put gamma less than 1% from negative. The Nasdaq Composite lost 5.3% in October, its worst month since March 2025 (TheStreet, Yahoo).
- **Fed.** Logan wants at least two more hikes, Musalem expects more tightening "soon", and Barkin favours a gradual path. BofA, JPM and MS expect a December hike; BofA also sees March, with a terminal 4.25–4.50%.
- **Corporate.** Intel warned on PC demand and cash burn. Amazon guided "meaningfully more" capex for 2027. Big Tech's reliance on debt (MSFT $25B bond) was cited (Reuters via Economic Times).
- **Unmeasured:** other strategist notes.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- **Book check.** I re-read the 12 Strategy D tranches from `state.current_positions` (no `convergence_target`, no `time_exit_date`) and compared them with IBKR `get_account_positions`. They agree on every name: AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156. VOO 16.895 is the park. No position is in IBKR but missing from the book, so no reconciliation-lag alert is owed. **No exit is triggered.**
- **Closes, 10-29 to 10-30 (IBKR ONE_DAY, outside_rth=false):** AMZN 243.79 → 240.35 (−1.41%), GOOGL 283.82 → 279.84 (−1.40%), GEV 887.85 → 857.87 (−3.38%), TSM 431.81 → 406.13 (−5.95%), ISRG 448.76 → 432.01 (−3.73%), RTX 199.40 → 199.80 (+0.20%), DIS 110.91 → 110.94 (+0.03%), UBER 65.74 → 65.25 (−0.75%).
- **D book:** $530.09 → $518.17 (**−2.25%**). The 10-29 value matches the prior run's.
- **Dividend netting.** No price-level criterion is in play, so none is owed.

### Thesis-invalidation review

The positions leg pulled EDGAR filings in the window plus 9 free web searches. "None found" is not proof of none.
- **AMZN.** The 10-Q was filed 10-30. All five criteria are UNBREACHED:
  - (1) AWS sales $45.98B, +39.3% YoY.
  - (2) AWS operating margin 38.7%.
  - (3) Performance obligations about **$578B, up from $496B** in Q2: no sequential decline. This is the test the 10-29 run could not make.
  - (4) The OpenAI and Anthropic commitments are still cited as expanded.
  - (5) AWS segment reporting is unchanged.
  - The −5.7% two-session drop is a reaction to the EPS miss and capex, not an invalidation.
- **GOOGL.** Criteria (1), (2), (3) and (5) are UNBREACHED: Cloud +102.6%, Cloud margin 36.2% (from 35.6%), Cloud backlog $560.8B (from about $513.9B).
  - (4) structural remedy: no new remedy action in the window. The 10-29 read of the 10-Q (ad-tech structural divestiture denied) stands.
  - The investment-loss EPS miss is not a criterion.
- **GEV.** UNBREACHED. Q3 (10-28, pre-window) organic orders were +96% against the 15% line. Completion is not met: backlog is $197B against the $200B leg, and orders growth is above 25%.
- **ISRG, TSM, RTX:** no filing or news bearing on their criteria; not testable this window. TSM's −5.95% is sector-wide.
- **DIS:** FQ4 print on 11-17; not testable.
- **UBER:** Q3 on 11-04 08:00 ET; not testable until then.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-29): unit 1.0328 against a peak of 1.1065 (−6.66%). `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` are all FALSE.
  - **Refreshed on IBKR 10-30 closes:** the book fell −2.25%, which puts the unit at ≈1.0096 and the drawdown at **≈−8.75%**, against the −50% kill.
  - `excess_vs_sgov` was +1.37% at 10-29. No interim warning is open, so none is owed or healed.
- **B:** no open position. `analytics.b_pairwise_correlation` is inert (n_positions 0).
- No other strategy holds positions. **No termination and no runaway review.**

**Watchlist candidacy:** the Strategy B new-entry index gains the floor clearers below. No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** The own-event floor clearers are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only.
  - A thesis session would need to weigh prior ≥5% sessions against criterion 4 (information vs sentiment):
    - AXTI and BHVN: 6 others each.
    - SNDK: 5 others; it is also a memory name inside the common semis driver.
    - MSTR: 3 others.
    - INTC, TWLO, RKT, INVX, AN and FND: 2 others each.
  - Several reactions ran against the print direction: TWLO −15% on a beat, NVT −8.8% on a beat, MMSI −7.7% after raising guidance, PTCT −7.0% after raising guidance. Those are open criterion-4 questions, not settled reads.
- **C.** C stays HYBRID ACTIVATE (FOMC-only). The next FOMC (December) is not a catalyst in this scan; no new qualifying catalyst within 45 days was found.
- **A** (`DO-NOT-ACTIVATE`, div-A-202610-1): not a candidate.
- **E** (`DO-NOT-ACTIVATE`, div-E-202610-1). These intra-group divergences are recorded for M2, not routed:
  - semis: INTC −28.6% on its print vs a group mostly down 5–11% (common driver);
  - healthcare tools: ILMN −18.6% vs RMD −9.1% and SYK −6.4% on their own prints;
  - pharma: REGN +13.3% and AZN +7.0% vs ABBV (under 4%).

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `d293ba74-b55e-4bd6-b003-cd0992c48c16`. All 12 open D tranches were evaluated: 0 flagged, 0 declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12. Each tranche is marked at its IBKR 10-30 close against its own cost per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +23.60% | dip-with-intact-thesis | declined: no funding path |
| D:RTX:2026-04-27 | +12.95% | none | declined |
| D:DIS:2026-08-05 | +6.89% | none | declined |
| D:TSM:2026-07-29 | +3.37% | dip-with-intact-thesis | declined: no funding path |
| D:DIS:2026-05-07 | -0.34% | none | declined |
| D:AMZN:2026-07-09 | -0.37% | strengthened-conviction | declined: no funding path |
| D:TSM:2026-07-21 | -5.08% | dip-with-intact-thesis | declined: no funding path |
| D:AMZN:2026-07-30 | -9.54% | strengthened-conviction | declined: no funding path |
| D:UBER:2026-07-09 | -10.87% | none | declined |
| D:GEV:2026-08-03 | -11.55% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-26 | -14.64% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-09 | -22.23% | dip-with-intact-thesis | declined: no funding path |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- **Technical side.** SPY closed at 755.72 (−1.77%), VIX at 19.42 (NORMAL band) and breadth at 59.44 (still above 50). D2a classifies these, and the measured refresh triggers (VIX into HIGH, SPY trend change, breadth ±10pp month-over-month, shock price leg) are D2's to detect. This scan only notes that the SPY close sits below the 10-29 SMA50 of 767.63.
- **Geopolitical-trigger duty.**
  - Escalations (tanker mines, Khamenei's response order, the 11-03 moratorium expiry, the reported hit on a Qatari carrier) fall inside the standing `acute` overlay. A further event inside `acute` needs no scenario-3 flag.
  - **Mirror (qualifying resolution event): none.** The 11-01 Araghchi 48-hour plan is a conditional proposal, not a ceasefire or settlement in force. The US has not accepted it, the blockade is still in force (144 ships redirected), and Iran says the strait stays shut until its conditions are met. No sanctions or tariff regime was removed; the Russian diesel waiver is not the named channel. The oil leg moved the wrong way for a resolution: Brent rose +2.37% into 10-30. This is narrative de-escalation with no measurable leg.
  - Israel's hung count is domestic.
- **Macro.** BoJ held, US ECI was in line and the saving rate is at a low. These are inputs M1a/M1R score, not geopolitical triggers.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **59.44 for 2026-10-30**.
- **Source.** EODData's end-of-day table row "30 Oct 26 62.42 62.42 58.05 59.44" (`date_attribution=source_dated`), fetched by curl about 50 hours after the close. The prior row (63.81) matches the stored 10-29 value. It is a real bar, not a carry and not an exact repeat (−4.37pp).
- **Widget stamp.** EODData's quote-box widget is stamped "30 Oct 26 15:55", which is before 16:00 ET, so the rationale carries `unsettled_at_fetch=15:55 ET (widget stamp only)`. The table row is the value recorded.
- **Single usable source.** Barchart `$S5TH`, the declared primary, did not answer: Tavily extract failed and WebFetch returned an empty page. Barchart and EODData count as one source in any case.
- **MacroMicro weekly Sunday re-probe:** failed ("Failed to fetch url"); the designation is unchanged.
- **ChartRow cross-check.** "as of market close, Oct 30, 2026", 294 of 497 eligible, against 314 on 10-29. That is −4.02pp against `$S5TH`'s −4.37pp, so `chartrow_dod_gap=0.35`, the same direction and within 1.0pp. No disagreement exceeds 5pp.

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. Sunday's battery was long-context: one `hf_fs` paper search returned five relevance-ranked results, none in the window. The date-ordered `hf://papers/daily/latest` listing was empty on Sunday.

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled, so the eligible own-event floor clearers are indexed below instead.
Not indexed: ENHA, AGIO and GPN (anchor UNRESOLVED); the day-two moves FTRE, ALGM, LAUR, GTX, IDCC, ESTA, ATI and IOVA (their 10-29 anchors were screened on 10-29); and TECK, SAN, OMF and EXEL (sub-floor context).

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `e2dfa715-80cb-4d38-81fb-fe3310e21cfd`.

- ADD **RDDT** (Strategy B, `qualifying_event_date` 2026-10-29) — -29.2207% (129.6 -> 91.73); earnings; after-close 10-29 (EDGAR 8-K acc 0001713445-26-000114, accepted 2026-10-29T20:08:57 UTC); index only
- ADD **INTC** (Strategy B, `qualifying_event_date` 2026-10-29) — -28.5761% (92.07 -> 65.76); earnings; after-close 10-29 16:08 ET (8-K acc 0000050863-26-000188); index only; 2 other >=5% session(s) in window
- ADD **CDNA** (Strategy B, `qualifying_event_date` 2026-10-29) — +22.2176% (71.52 -> 87.41); earnings; after-close 10-29 16:02 ET (8-K acc 0001217234-26-000059); index only
- ADD **CACC** (Strategy B, `qualifying_event_date` 2026-10-29) — -19.2591% (575.78 -> 464.89); earnings; after-close 10-29 16:02 ET (8-K acc 0000885550-26-000200); index only; 1 other >=5% session(s) in window
- ADD **ILMN** (Strategy B, `qualifying_event_date` 2026-10-29) — -18.6410% (290.06 -> 235.99); earnings; after-close 10-29 16:07 ET (8-K acc 0001110803-26-000202); index only; 1 other >=5% session(s) in window
- ADD **RBLX** (Strategy B, `qualifying_event_date` 2026-10-29) — -18.0518% (52.46 -> 42.99); earnings; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068235, accepted 2026-10-29T20:10:59 UTC); index only
- ADD **BFAM** (Strategy B, `qualifying_event_date` 2026-10-29) — -17.9158% (66.98 -> 54.98); earnings; after-close 10-29 16:13 ET (8-K acc 0001437578-26-000022); index only; 1 other >=5% session(s) in window
- ADD **TFII** (Strategy B, `qualifying_event_date` 2026-10-29) — -17.0784% (112.54 -> 93.32); earnings/guidance; after-close 10-29 (EDGAR 6-K acc 0001193125-26-437899, accepted 2026-10-29T20:39:23 UTC); index only
- ADD **TWLO** (Strategy B, `qualifying_event_date` 2026-10-29) — -15.2418% (241.9 -> 205.03); earnings; after-close 10-29 (EDGAR 8-K acc 0001447669-26-000106, accepted 2026-10-29T20:07:30 UTC); index only; 2 other >=5% session(s) in window
- ADD **FDXF** (Strategy B, `qualifying_event_date` 2026-10-29) — +14.9056% (109.69 -> 126.04); earnings; after-close 10-29 16:08 ET (8-K acc 0001628280-26-068228); index only
- ADD **SKYW** (Strategy B, `qualifying_event_date` 2026-10-29) — -14.7193% (96.54 -> 82.33); earnings; after-close 10-29 (EDGAR 8-K acc 0001104659-26-120182, accepted 2026-10-29T20:01:17 UTC); index only
- ADD **MEOH** (Strategy B, `qualifying_event_date` 2026-10-29) — +14.0376% (62.76 -> 71.57); earnings; after-close 10-29 (EDGAR 6-K acc 0001628280-26-068300, accepted 2026-10-29T21:05:15 UTC); index only
- ADD **SNDK** (Strategy B, `qualifying_event_date` 2026-10-29) — -13.4702% (1330.05 -> 1150.89); earnings/other; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068243, accepted 2026-10-29T20:13:53 UTC); index only; 5 other >=5% session(s) in window
- ADD **REGN** (Strategy B, `qualifying_event_date` 2026-10-30) — +13.3273% (818.77 -> 927.89); earnings/M&A; pre-open 10-30 06:50 ET (8-K acc 0000872589-26-000032) (EDGAR 8-K acc 0000872589-26-000032, accepted 2026-10-30T10:50:20 UTC); index only
- ADD **CVCO** (Strategy B, `qualifying_event_date` 2026-10-29) — +13.1110% (547.25 -> 619); earnings; after-close 10-29 16:57 ET (8-K acc 0001628280-26-068294); index only; 1 other >=5% session(s) in window
- ADD **BTSG** (Strategy B, `qualifying_event_date` 2026-10-30) — +11.0761% (60.22 -> 66.89); earnings; pre-open 10-30 06:05 ET (8-K acc 0001865782-26-000011); index only
- ADD **GDDY** (Strategy B, `qualifying_event_date` 2026-10-29) — +10.7187% (105.89 -> 117.24); earnings; after-close 10-29 16:11 ET (8-K acc 0001609711-26-000117); index only; 1 other >=5% session(s) in window
- ADD **COIN** (Strategy B, `qualifying_event_date` 2026-10-29) — -10.6171% (160.59 -> 143.54); earnings; after-close 10-29 16:09 ET (8-K acc 0001679788-26-000121); index only; 1 other >=5% session(s) in window
- ADD **SXT** (Strategy B, `qualifying_event_date` 2026-10-30) — -10.5679% (131.53 -> 117.63); earnings; pre-open 10-30 07:10 ET (EDGAR 8-K acc 0001140361-26-041223, accepted 2026-10-30T11:10:09 UTC); index only
- ADD **AXTI** (Strategy B, `qualifying_event_date` 2026-10-29) — -9.5598% (60.88 -> 55.06); earnings; after-close 10-29 16:16 ET (8-K acc 0001437749-26-033941); index only; 6 other >=5% session(s) in window
- ADD **GTES** (Strategy B, `qualifying_event_date` 2026-10-30) — -9.2190% (26.25 -> 23.83); earnings; pre-open 10-30 07:32 ET (8-K acc 0001628280-26-068435); index only; 1 other >=5% session(s) in window
- ADD **RMD** (Strategy B, `qualifying_event_date` 2026-10-29) — -9.0535% (252.83 -> 229.94); earnings; after-close 10-29 (EDGAR 8-K acc 0001193125-26-437783, accepted 2026-10-29T20:05:45 UTC); index only
- ADD **NWG** (Strategy B, `qualifying_event_date` 2026-10-30) — -9.0000% (17 -> 15.47); earnings; pre-open 10-30 (6-Ks 07:50-14:24 ET) (EDGAR 6-K acc 0001654954-26-009258, accepted 2026-10-30T11:50:06 UTC); index only
- ADD **NVT** (Strategy B, `qualifying_event_date` 2026-10-30) — -8.8093% (138.15 -> 125.98); earnings; pre-open 10-30 06:47 ET (EDGAR 8-K acc 0001628280-26-068391, accepted 2026-10-30T10:47:30 UTC); index only; 1 other >=5% session(s) in window
- ADD **CCJ** (Strategy B, `qualifying_event_date` 2026-10-30) — -7.8812% (83.49 -> 76.91); earnings; pre-open 10-30 06:57 ET (6-K acc 0001193125-26-439858); index only
- ADD **MSTR** (Strategy B, `qualifying_event_date` 2026-10-29) — -7.8449% (141.62 -> 130.51); earnings; after-close 10-29 (EDGAR 8-K acc 0001050446-26-000047, accepted 2026-10-29T20:03:24 UTC); index only; 3 other >=5% session(s) in window
- ADD **MMSI** (Strategy B, `qualifying_event_date` 2026-10-29) — -7.6561% (93.39 -> 86.24); earnings/guidance; after-close 10-29 (EDGAR 8-K acc 0000856982-26-000051, accepted 2026-10-29T20:07:29 UTC); index only
- ADD **HGV** (Strategy B, `qualifying_event_date` 2026-10-30) — +7.6449% (35.71 -> 38.44); other; pre-open 10-30 08:33 ET (8-K acc 0001140361-26-041230); index only
- ADD **TBBK** (Strategy B, `qualifying_event_date` 2026-10-29) — -7.4624% (50.52 -> 46.75); earnings; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068227, accepted 2026-10-29T20:08:03 UTC); index only
- ADD **RKT** (Strategy B, `qualifying_event_date` 2026-10-29) — +7.3826% (11.92 -> 12.8); earnings; after-close 10-29 17:19 ET (EDGAR 8-K acc 0001805284-26-000121, accepted 2026-10-29T21:19:26 UTC); index only; 2 other >=5% session(s) in window
- ADD **MHK** (Strategy B, `qualifying_event_date` 2026-10-29) — +7.2467% (129.99 -> 139.41); earnings; after-close 10-29 (EDGAR 8-K acc 0000851968-26-000038, accepted 2026-10-29T20:19:28 UTC); index only; 1 other >=5% session(s) in window
- ADD **PIPR** (Strategy B, `qualifying_event_date` 2026-10-30) — -7.1449% (68.72 -> 63.81); earnings; pre-open 10-30 08:06 ET (EDGAR 8-K acc 0001230245-26-000038, accepted 2026-10-30T12:06:16 UTC); index only
- ADD **AZN** (Strategy B, `qualifying_event_date` 2026-10-30) — +7.0241% (174.4 -> 186.65); earnings; pre-open 10-30 07:36 ET (6-K acc 0001654954-26-009256); index only
- ADD **MIAX** (Strategy B, `qualifying_event_date` 2026-10-29) — +6.9656% (31.44 -> 33.63); earnings; after-close 10-29 (EDGAR 8-K acc 0001438472-26-000044, accepted 2026-10-29T20:15:36 UTC); index only
- ADD **PTCT** (Strategy B, `qualifying_event_date` 2026-10-29) — -6.9656% (64.46 -> 59.97); earnings/guidance; after-close 10-29 (EDGAR 8-K acc 0001104659-26-120200, accepted 2026-10-29T20:10:20 UTC); index only
- ADD **CBOE** (Strategy B, `qualifying_event_date` 2026-10-30) — +6.7717% (314.25 -> 335.53); earnings; pre-open 10-30 07:30 ET (8-K acc 0001628280-26-068432); index only
- ADD **VLTO** (Strategy B, `qualifying_event_date` 2026-10-29) — +6.7653% (104.06 -> 111.1); earnings; after-close 10-29 (EDGAR 8-K acc 0001967680-26-000047, accepted 2026-10-29T20:31:44 UTC); index only
- ADD **RBC** (Strategy B, `qualifying_event_date` 2026-10-30) — -6.7636% (495.74 -> 462.21); earnings; pre-open 10-30 09:08 ET (EDGAR 8-K acc 0001213900-26-114098, accepted 2026-10-30T13:08:59 UTC); index only; 1 other >=5% session(s) in window
- ADD **BHVN** (Strategy B, `qualifying_event_date` 2026-10-29) — -6.4888% (16.49 -> 15.42); earnings; after-close 10-29 16:05 ET (8-K acc 0001935979-26-000093); index only; 6 other >=5% session(s) in window
- ADD **INVX** (Strategy B, `qualifying_event_date` 2026-10-29) — -6.4000% (30 -> 28.08); earnings; after-close 10-29 16:20 ET (8-K acc 0001193125-26-437829); index only; 2 other >=5% session(s) in window
- ADD **SYK** (Strategy B, `qualifying_event_date` 2026-10-29) — -6.3801% (311.75 -> 291.86); earnings; after-close 10-29 (EDGAR 8-K acc 0000310764-26-000059, accepted 2026-10-29T20:11:16 UTC); index only
- ADD **RIVN** (Strategy B, `qualifying_event_date` 2026-10-29) — +6.2009% (11.45 -> 12.16); earnings/guidance; after-close 10-29 16:00 ET (EDGAR 8-K acc 0001874178-26-000065, accepted 2026-10-29T20:00:35 UTC); index only
- ADD **AN** (Strategy B, `qualifying_event_date` 2026-10-30) — +6.0824% (169.34 -> 179.64); earnings; pre-open 10-30 07:11 ET (8-K acc 0001628280-26-068426); index only; 2 other >=5% session(s) in window
- ADD **COLM** (Strategy B, `qualifying_event_date` 2026-10-29) — +6.0449% (63.69 -> 67.54); earnings; after-close 10-29 16:05 ET (8-K acc 0001050797-26-000148); index only
- ADD **BBIO** (Strategy B, `qualifying_event_date` 2026-10-29) — +5.9664% (70.73 -> 74.95); earnings; after-close 10-29 16:03 ET (8-K acc 0001743881-26-000033); index only
- ADD **IMO** (Strategy B, `qualifying_event_date` 2026-10-30) — +5.5246% (130.87 -> 138.1); earnings; pre-open 10-30 08:02 ET (8-K acc 0000049938-26-000049); index only
- ADD **FND** (Strategy B, `qualifying_event_date` 2026-10-29) — -5.4629% (50.34 -> 47.59); earnings; after-close 10-29 16:13 ET (8-K acc 0001628280-26-068242); index only; 2 other >=5% session(s) in window
- ADD **TGS** (Strategy B, `qualifying_event_date` 2026-10-29) — -5.3957% (25.02 -> 23.67); earnings; after-close 10-29 17:13 ET (6-K) (EDGAR 6-K acc 0000931427-26-000014, accepted 2026-10-29T21:13:24 UTC); index only
- ADD **ATR** (Strategy B, `qualifying_event_date` 2026-10-29) — +5.0214% (130.64 -> 137.2); earnings; after-close 10-29 17:08 ET (8-K acc 0000896622-26-000187); index only
- ADD **LYB** (Strategy B, `qualifying_event_date` 2026-10-30) — +5.0023% (65.37 -> 68.64); earnings; pre-open 10-30 06:31 ET (8-K acc 0001489393-26-000067); index only

```yaml d1_actions
- action: watchlist
  ticker: RDDT
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -29.2207% (129.6 -> 91.73); earnings; after-close 10-29 (EDGAR 8-K acc 0001713445-26-000114, accepted 2026-10-29T20:08:57 UTC); index only
- action: watchlist
  ticker: INTC
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -28.5761% (92.07 -> 65.76); earnings; after-close 10-29 16:08 ET (8-K acc 0000050863-26-000188); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: CDNA
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +22.2176% (71.52 -> 87.41); earnings; after-close 10-29 16:02 ET (8-K acc 0001217234-26-000059); index only
- action: watchlist
  ticker: CACC
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -19.2591% (575.78 -> 464.89); earnings; after-close 10-29 16:02 ET (8-K acc 0000885550-26-000200); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: ILMN
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -18.6410% (290.06 -> 235.99); earnings; after-close 10-29 16:07 ET (8-K acc 0001110803-26-000202); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: RBLX
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -18.0518% (52.46 -> 42.99); earnings; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068235, accepted 2026-10-29T20:10:59 UTC); index only
- action: watchlist
  ticker: BFAM
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -17.9158% (66.98 -> 54.98); earnings; after-close 10-29 16:13 ET (8-K acc 0001437578-26-000022); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: TFII
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -17.0784% (112.54 -> 93.32); earnings/guidance; after-close 10-29 (EDGAR 6-K acc 0001193125-26-437899, accepted 2026-10-29T20:39:23 UTC); index only
- action: watchlist
  ticker: TWLO
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -15.2418% (241.9 -> 205.03); earnings; after-close 10-29 (EDGAR 8-K acc 0001447669-26-000106, accepted 2026-10-29T20:07:30 UTC); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: FDXF
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +14.9056% (109.69 -> 126.04); earnings; after-close 10-29 16:08 ET (8-K acc 0001628280-26-068228); index only
- action: watchlist
  ticker: SKYW
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -14.7193% (96.54 -> 82.33); earnings; after-close 10-29 (EDGAR 8-K acc 0001104659-26-120182, accepted 2026-10-29T20:01:17 UTC); index only
- action: watchlist
  ticker: MEOH
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +14.0376% (62.76 -> 71.57); earnings; after-close 10-29 (EDGAR 6-K acc 0001628280-26-068300, accepted 2026-10-29T21:05:15 UTC); index only
- action: watchlist
  ticker: SNDK
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -13.4702% (1330.05 -> 1150.89); earnings/other; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068243, accepted 2026-10-29T20:13:53 UTC); index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: REGN
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +13.3273% (818.77 -> 927.89); earnings/M&A; pre-open 10-30 06:50 ET (8-K acc 0000872589-26-000032) (EDGAR 8-K acc 0000872589-26-000032, accepted 2026-10-30T10:50:20 UTC); index only
- action: watchlist
  ticker: CVCO
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +13.1110% (547.25 -> 619); earnings; after-close 10-29 16:57 ET (8-K acc 0001628280-26-068294); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: BTSG
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +11.0761% (60.22 -> 66.89); earnings; pre-open 10-30 06:05 ET (8-K acc 0001865782-26-000011); index only
- action: watchlist
  ticker: GDDY
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +10.7187% (105.89 -> 117.24); earnings; after-close 10-29 16:11 ET (8-K acc 0001609711-26-000117); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: COIN
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -10.6171% (160.59 -> 143.54); earnings; after-close 10-29 16:09 ET (8-K acc 0001679788-26-000121); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: SXT
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -10.5679% (131.53 -> 117.63); earnings; pre-open 10-30 07:10 ET (EDGAR 8-K acc 0001140361-26-041223, accepted 2026-10-30T11:10:09 UTC); index only
- action: watchlist
  ticker: AXTI
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -9.5598% (60.88 -> 55.06); earnings; after-close 10-29 16:16 ET (8-K acc 0001437749-26-033941); index only; 6 other >=5% session(s) in window
- action: watchlist
  ticker: GTES
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -9.2190% (26.25 -> 23.83); earnings; pre-open 10-30 07:32 ET (8-K acc 0001628280-26-068435); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: RMD
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -9.0535% (252.83 -> 229.94); earnings; after-close 10-29 (EDGAR 8-K acc 0001193125-26-437783, accepted 2026-10-29T20:05:45 UTC); index only
- action: watchlist
  ticker: NWG
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -9.0000% (17 -> 15.47); earnings; pre-open 10-30 (6-Ks 07:50-14:24 ET) (EDGAR 6-K acc 0001654954-26-009258, accepted 2026-10-30T11:50:06 UTC); index only
- action: watchlist
  ticker: NVT
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -8.8093% (138.15 -> 125.98); earnings; pre-open 10-30 06:47 ET (EDGAR 8-K acc 0001628280-26-068391, accepted 2026-10-30T10:47:30 UTC); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: CCJ
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -7.8812% (83.49 -> 76.91); earnings; pre-open 10-30 06:57 ET (6-K acc 0001193125-26-439858); index only
- action: watchlist
  ticker: MSTR
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -7.8449% (141.62 -> 130.51); earnings; after-close 10-29 (EDGAR 8-K acc 0001050446-26-000047, accepted 2026-10-29T20:03:24 UTC); index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: MMSI
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -7.6561% (93.39 -> 86.24); earnings/guidance; after-close 10-29 (EDGAR 8-K acc 0000856982-26-000051, accepted 2026-10-29T20:07:29 UTC); index only
- action: watchlist
  ticker: HGV
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +7.6449% (35.71 -> 38.44); other; pre-open 10-30 08:33 ET (8-K acc 0001140361-26-041230); index only
- action: watchlist
  ticker: TBBK
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -7.4624% (50.52 -> 46.75); earnings; after-close 10-29 (EDGAR 8-K acc 0001628280-26-068227, accepted 2026-10-29T20:08:03 UTC); index only
- action: watchlist
  ticker: RKT
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +7.3826% (11.92 -> 12.8); earnings; after-close 10-29 17:19 ET (EDGAR 8-K acc 0001805284-26-000121, accepted 2026-10-29T21:19:26 UTC); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: MHK
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +7.2467% (129.99 -> 139.41); earnings; after-close 10-29 (EDGAR 8-K acc 0000851968-26-000038, accepted 2026-10-29T20:19:28 UTC); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: PIPR
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -7.1449% (68.72 -> 63.81); earnings; pre-open 10-30 08:06 ET (EDGAR 8-K acc 0001230245-26-000038, accepted 2026-10-30T12:06:16 UTC); index only
- action: watchlist
  ticker: AZN
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +7.0241% (174.4 -> 186.65); earnings; pre-open 10-30 07:36 ET (6-K acc 0001654954-26-009256); index only
- action: watchlist
  ticker: MIAX
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.9656% (31.44 -> 33.63); earnings; after-close 10-29 (EDGAR 8-K acc 0001438472-26-000044, accepted 2026-10-29T20:15:36 UTC); index only
- action: watchlist
  ticker: PTCT
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -6.9656% (64.46 -> 59.97); earnings/guidance; after-close 10-29 (EDGAR 8-K acc 0001104659-26-120200, accepted 2026-10-29T20:10:20 UTC); index only
- action: watchlist
  ticker: CBOE
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.7717% (314.25 -> 335.53); earnings; pre-open 10-30 07:30 ET (8-K acc 0001628280-26-068432); index only
- action: watchlist
  ticker: VLTO
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.7653% (104.06 -> 111.1); earnings; after-close 10-29 (EDGAR 8-K acc 0001967680-26-000047, accepted 2026-10-29T20:31:44 UTC); index only
- action: watchlist
  ticker: RBC
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -6.7636% (495.74 -> 462.21); earnings; pre-open 10-30 09:08 ET (EDGAR 8-K acc 0001213900-26-114098, accepted 2026-10-30T13:08:59 UTC); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: BHVN
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -6.4888% (16.49 -> 15.42); earnings; after-close 10-29 16:05 ET (8-K acc 0001935979-26-000093); index only; 6 other >=5% session(s) in window
- action: watchlist
  ticker: INVX
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -6.4000% (30 -> 28.08); earnings; after-close 10-29 16:20 ET (8-K acc 0001193125-26-437829); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: SYK
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -6.3801% (311.75 -> 291.86); earnings; after-close 10-29 (EDGAR 8-K acc 0000310764-26-000059, accepted 2026-10-29T20:11:16 UTC); index only
- action: watchlist
  ticker: RIVN
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.2009% (11.45 -> 12.16); earnings/guidance; after-close 10-29 16:00 ET (EDGAR 8-K acc 0001874178-26-000065, accepted 2026-10-29T20:00:35 UTC); index only
- action: watchlist
  ticker: AN
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.0824% (169.34 -> 179.64); earnings; pre-open 10-30 07:11 ET (8-K acc 0001628280-26-068426); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: COLM
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +6.0449% (63.69 -> 67.54); earnings; after-close 10-29 16:05 ET (8-K acc 0001050797-26-000148); index only
- action: watchlist
  ticker: BBIO
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +5.9664% (70.73 -> 74.95); earnings; after-close 10-29 16:03 ET (8-K acc 0001743881-26-000033); index only
- action: watchlist
  ticker: IMO
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +5.5246% (130.87 -> 138.1); earnings; pre-open 10-30 08:02 ET (8-K acc 0000049938-26-000049); index only
- action: watchlist
  ticker: FND
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -5.4629% (50.34 -> 47.59); earnings; after-close 10-29 16:13 ET (8-K acc 0001628280-26-068242); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: TGS
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — -5.3957% (25.02 -> 23.67); earnings; after-close 10-29 17:13 ET (6-K) (EDGAR 6-K acc 0000931427-26-000014, accepted 2026-10-29T21:13:24 UTC); index only
- action: watchlist
  ticker: ATR
  strategy: B
  qualifying_event_date: 2026-10-29
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +5.0214% (130.64 -> 137.2); earnings; after-close 10-29 17:08 ET (8-K acc 0000896622-26-000187); index only
- action: watchlist
  ticker: LYB
  strategy: B
  qualifying_event_date: 2026-10-30
  source_research_screen_id: e2dfa715-80cb-4d38-81fb-fe3310e21cfd
  detail: ADD to B new-entry index — +5.0023% (65.37 -> 68.64); earnings; pre-open 10-30 06:31 ET (8-K acc 0001489393-26-000067); index only
```

2026-10-25
<!-- d1_scan_through_utc: 2026-10-25T22:40:00Z -->

# Daily Market Development Scan — session 2026-10-23 (Fri), written 2026-10-25 (Sun)

Scan window: 2026-10-23 03:00 MT → 2026-10-25 16:40 MT (~61.7h). **This is a multi-session gap of more than 50 hours.** The start comes from the prior `Daily.md` marker `2026-10-23T09:00:00Z`; that file's commit (09:34Z) agrees. D1 runs Sunday to Thursday, so there was no Friday D1 and no D1 between the 10-22 catch-up and today. The window holds **one completed US session, Friday 2026-10-23**, plus the 10-22 after-close releases (which react on 10-23) and the weekend. No ≥$2B issuer filed an Item 2.02 after the 10-23 close or over the weekend.

Tape: **a risk-off, oil-led Friday.** Brent rose again on continued Houthi strikes on Saudi Arabia. The 10Y moved back toward 5%, and about three in four S&P names fell. Energy hit records, and cybersecurity rallied on an AI-enabled attack wave.
- **Indices.** IBKR regular-session closes, 10-22 → 10-23: SPY 763.96 → **759.97 (−0.5223%)**, QQQ −0.0099%, IWM −0.3325%, **DIA −1.2351%**, RSP −0.7699%, SMH +0.7356%. The S&P 500 closed at 7,623.68 (−0.52%, a second weekly loss) and the Dow at 52,215.16 (−1.23%) (AP).
- **Rates.** 10Y about **4.99% (+3bp from 4.96%)** (AP/BNN). The 2Y and the dollar index were not retrieved. TLT −0.49%, HYG −0.06%. FedWatch: ~92% hold on 10-28, ~78-80% for a December hike.
- **Oil.** **Brent December settled $116.72 on 10-23 (+$3.55, +3.1%)**, after **$113.17 on 10-22** (the D1 10-22 record, consistent with the reported change). WTI December settled $103.27 (+$3.80). Sources: AP/BNN, FinanceFeeds, MarketScreener (WTI) and Rio Times. Sources disagree on how notable the level is: "highest since 4-29" vs "since June 2022". USO +4.32%.
- **Gold and crypto.** Spot gold ~$3,996 (−0.6%, ~−4% on the week, first close under $4,000 since mid-July); GLD −0.65%. BTC fell below $80k over the weekend (secondary).
- **Leadership.** XLE +2.60 led and XLP −1.92 lagged. Breadth fell to **56.06** (from 57.25).

## TL;DR

- **Exits triggered: none.** Twelve Strategy D tranches carry no mechanical trigger, and no Development meets a thesis-invalidation criterion. No held name had company news or an 8-K in the window.
- **New entry candidates: none routed.** 20 names cleared Strategy B's frozen ≥5% floor on their own events. B is `DO-NOT-ACTIVATE` and capital-disabled, so they go to the index only (list below).
- **Add candidates: none (0 of 12).** Six D tranches read dip-with-intact-thesis, but D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 20 changes.** ADD the 20 names to the Strategy B new-entry index.
- **Regime review: no review.** The 10-25 Houthi strikes on Riyadh and Yanbu and Brent +3.1% are further escalation inside the standing `acute` shock overlay. Iran's 7-day ceasefire is proposed only and not in force, so there is no qualifying resolution.

Park: VOO-only pin verified

Paper book (J): 118 calls, 51/30 realized, net_mu -1.31%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Gulf / Saudi Arabia / Iran (continued escalation, no resolution).**
  - 10-23: the US departure of non-emergency staff from Saudi Arabia took effect, and Brent traded above $117 intraday. An oil spill off the UAE came from an unidentified tanker. Libya shut a pipeline valve to Zawiya. Reuters-cited expectations are that US strikes on Iran resume within weeks.
  - 10-24: Iran said it will not let US warships approach. Its 7-day ceasefire proposal is **under review, not in force** (Al Jazeera, snippet).
  - **10-25:** Saudi Arabia said it intercepted Houthi missiles and drones aimed at Riyadh and other cities, and Riyadh airport closed, then reopened. The Houthis claim they targeted King Khalid Airport and Aramco Yanbu (CNBC, New Arab; snippets). Trump says the US is "not negotiating" and something will happen "fairly soon".
  - Earlier in the week: Aramco evacuated its Dhahran HQ (10-22). The IRGC claims of tanker hits remain unconfirmed, though UKMTO confirmed two tanker attacks that week.
- **AI spending.** The AI-capex payoff worry from 10-22 lingered, though SMH bounced +0.74%. Anthropic's public S-1 was reported (10-21) as possible "as soon as Friday". EDGAR full-text search for 10-20..10-25 returns no hit, so it is **not confirmed filed**.
- **SpaceX / telecom.** Bloomberg reported after the 10-22 close that SpaceX is in talks with Crown Castle, American Tower and Vertical Bridge for at least 80,000 cell sites for a fourth-carrier plan. T fell −7.96% and TMUS −7.71%, while CCI rose +9.06%.
- **Cybersecurity.** A wave of AI-enabled cyberattacks ("Black October", with federal advisories) lifted the whole security-software group 6-9% (Yahoo/StockStory). The trading date of the move is inferred.
- **Europe.** Moody's kept France at Aa3 with a negative outlook on 10-23 (CNBC), so there was no downgrade.
- **Russia-Ukraine.** Strikes continue. The Kremlin says trilateral talks are planned for the first half of November in Abu Dhabi. There is no ceasefire.
- **Not found** in this window: China tariff, shutdown, bankruptcy or enforcement news. Those searches were not exhaustive.

### 2. Scheduled events that resolved in the window

- **Enumeration.** I fetched the Nasdaq key-less calendar for 10-22..10-26 with curl: 83 reporters ≥$2B on 10-22 and 15 on 10-23, with release times mostly "not supplied". EDGAR 8-K Ex-99.1 acceptance stamps decide the release times and are an upper bound. Consensus figures are Nasdaq-calendar (secondary).
- **Macro (10-23).**
  - UMich final October sentiment was **48.0** vs 46.3 prelim and consensus (September 48.1). Current conditions were 46.7, and 1y inflation expectations 4.7%. It is the second-lowest final on record.
  - Flash PMI 57.6 comes from a single weak source and is unverified. September new home sales were not confirmed released.
- **After-close 10-22 reporters reacting on 10-23 (IBKR close-to-close).**

  | Ticker | Result (secondary consensus) | 10-23 move |
  |---|---|---|
  | **RHI** | EPS $0.49 vs ~$0.47; Talent Solutions back to y/y growth for the first time since 2022 | **+21.74%** |
  | **BE** | record revenue (+138%), EPS $0.94 vs $0.56, FY guide raised; fell with AI infrastructure | **−11.24%** |
  | **SLM** | GAAP EPS −$0.19 vs +$0.12; FY EPS guide cut to $1.95-2.05 from $3.10-3.20 | **−10.80%** |
  | **FIX** | EPS $13.91 vs $12.71, backlog $17.8B; fell with AI infrastructure | **−9.26%** |
  | **CUBI** | EPS $2.27 vs $2.15, raised FY guide | +7.38% |
  | **SSNC** | adj EPS $1.78 (+14.8%); basis vs consensus unclear | −7.35% |
  | **REXR** | core FFO in line, 2026 guide raised, $1.2B portfolio sale | +6.70% |
  | **KNSL** | op EPS $5.70 vs $4.95, but GWP −4.8% | −6.69% |
  | **ENVA** | adj EPS $4.48; moved with the consumer-finance selloff | −6.62% |
  | **SIGI** | op EPS $2.37 vs $1.91; dividend +12%, $200M buyback | +5.31% |
  | RNG / DECK / NEM / WDC | beats (RNG +4.9987% sits just under the floor) | +5.00 / −4.91 / −4.59 / −2.97 |

- **Pre-open / intraday 10-23 reporters.**
  - Down: **LKQ −22.47** (preliminary Q3 miss, FY26 guide withdrawn, CEO change), **FLG −9.27** (EPS $0.01 vs $0.06, provision +$58M), **INFY −6.58** (FY27 cc revenue guide cut to 1-2%), GNTX −4.97, AXP −3.67 (beat, but job cuts), ALV −3.54, FHB −3.02.
  - Up: **FCNCA +8.15** (EPS $55.37 vs $46.61, $1.2B buyback), **RITM +8.18**, SLB +7.08 (modest beat inside the energy rally, so a common driver), BCPC +2.18.
  - ESMO (10-23): **GMAB +9.48** (Phase 3 RAINFOL-02 Rina-S met PFS and OS; 6-K 11:58 ET); **TNGX −16.43** (pancreatic data, 8-K 06:36 ET, sell-the-news after a +22% run-up); ZLAB +9.03 (a $250M PIPE plus Phase 1b data; an ADS under $10B, so ineligible); CORT −20.13 on GMAB's competing win (no own event).
- **Following sessions, not reactions** (released before 10-23): TTMI +8.42, VC −6.52, CBRE −6.05, FCFS −6.51, GL −8.09 (10-21 print; 10-23 Piper downgrade), T −7.96 (10-21 print), OII +7.24, TR −6.48, AAL −3.9, TSCO −3.8, PG −2.8.
- **Pending (react Monday 10-26).** No ≥$2B Item 2.02 was accepted after the 10-23 close. RIG and VAL filed Item 8.01 merger 8-Ks at ~17:00 ET 10-23 (content not read). Monday: VZ pre-market; WELL, CDNS, NUE, PSA, HIG and CLS after hours.
- **FDA.** No PDUFA decision or CRL for a ≥$2B sponsor was found for 10-23..10-25. This is an absence on leg searches, not confirmed against the FDA's own page.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `290d4251-8c5b-4fba-86f5-dc034c7e4057` (`surfaced_count` 40 = `ARRAY_LENGTH(passed)`: 20 floor clearers plus 20 below-floor own-event items; agreement both 20 / ai_only 20 / rule_only 74). Every written-up figure is an IBKR regular-session daily-bar close-to-close (close array), 10-22 → 10-23. Every pair agreed with the Nasdaq closes within 0.3%.

- **Discovery.**
  - The Nasdaq screener snapshot was **stale** (it still carried 10-22 changes), so it was not used for moves.
  - Instead, a key-less Nasdaq historical-bar sweep (curl, unmetered) ran over **every ≥$2B name in the screener file**: 2,133 symbols, of which 2,130 returned 10-22 and 10-23 bars. **676 moved ≥2% and 94 moved ≥5%.**
- **Layer 2.** Every calendar or Item-2.02 reporter moving ≥2% and every non-reporter moving ≥5% was examined (EDGAR 8-K checks plus clustered news searches). The 545 non-reporters at 2-5% were not individually attributed (`selection_rule`).
- **Fan-out reconciliation.** Four tickers were named by two legs (LKQ, GL, T, OII). They agree on event date, anchor and disposition. No primary-source tiebreak was needed.
- **Own-event ≥5% floor clearers: index only (B `DO-NOT-ACTIVATE`).**

| Ticker | Move (close → close) | Release and anchor | Conviction | Notes |
|---|---|---|---|---|
| **LKQ** | -22.4744% (22.47 → 17.42) | pre-open 10-23, EDGAR accepted 08:06:44 ET (8-K 2.02/5.02/7.01); anchor 2026-10-23, reaction 2026-10-23 | 75 | Prelim Q3 rev $3.32B vs $3.50B y/y, adj EPS $0.47-0.53 vs $0.84 y/y, Europe organic -9.8% (ERP disruption in Germany), $111M impairments, FY26 guidance withdrawn, new CEO (Abbate) and Alvarez & Marsal retained; claimed from non5;… |
| **RHI** | +21.7357% (37.68 → 45.87) | after-close 10-22, EDGAR accepted 16:05:25 ET (8-K 2.02 Ex-99.1); anchor 2026-10-22, reaction 2026-10-23 | 75 | Q3 EPS $0.49 vs ~$0.47 cons (Nasdaq calendar, secondary) on rev $1.359B flat y/y; Talent Solutions returned to y/y growth (+2%) first time since 2022 and earnings beat guide midpoint; +21.7% is a short-covering re-rate on a depre… |
| **TNGX** | -16.4339% (27.93 → 23.34) | pre-open 10-23; 8-K Items 7.01/8.01 accepted 06:36 ET; webcast 07:30 ET; anchor 2026-10-23, reaction 2026-10-23 | 60 | Vopimetostat+daraxonrasib PDAC data (82% ORR, 9-mo PFS 88%, Ph3 1H27) at ESMO 10-23; stock sold off -16.4% on 12.4M shares after a +22% run into the data (sell-the-news). 5 other >=5% session(s) in window (2026-10-09:+5.49, 2026-… |
| **BE** | -11.2366% (217.77 → 193.3) | after-close 10-22, EDGAR accepted 16:09:25 ET; anchor 2026-10-22, reaction 2026-10-23 | 45 | Record rev $1,235.8M (+138%), non-GAAP EPS $0.94 vs $0.56 cons (Nasdaq calendar, secondary), FY26 rev guide raised to $4.4-4.6B, yet -11.2% after -8.7% on 10-22; fell with AI-infrastructure cluster (FIX -9.3%, CRDO, WDC) on extre… |
| **SLM** | -10.7996% (21.76 → 19.41) | after-close 10-22, EDGAR accepted 16:32:31 ET (call 5:30pm ET); anchor 2026-10-22, reaction 2026-10-23 | 75 | GAAP EPS -$0.19 vs +$0.12 cons (Nasdaq calendar, secondary); FY26 EPS guide cut to $1.95-2.05 from $3.10-3.20, NCO guide raised to $400-420M (third-party debt-collection practice issue); consumer-finance peers also weak (DAVE, SE… |
| **GMAB** | +9.4750% (40 → 43.79) | pre-open/intraday 10-23; EDGAR 6-K accepted 11:58 ET 10-23 (upper bound); Copen…; anchor 2026-10-23, reaction 2026-10-23 | 60 | Phase 3 RAINFOL-02 of Rina-S met PFS primary and OS key secondary in platinum-resistant ovarian cancer; ADS +9.5% on 3x volume; FPI (6-K filer) but cap ~$25B >= $10B. |
| **FLG** | -9.2657% (11.44 → 10.38) | pre-open 10-23, EDGAR accepted 06:03:50 ET; anchor 2026-10-23, reaction 2026-10-23 | 60 | EPS $0.01 vs $0.06 cons (Nasdaq calendar, secondary); provision +$58M on NYC rent-regulated multifamily/higher rates; NII +5% and loans +6% annualized offset; idiosyncratic (other banks rose). |
| **FIX** | -9.2632% (1279.37 → 1160.86) | after-close 10-22, EDGAR accepted 16:10:19 ET; anchor 2026-10-22, reaction 2026-10-23 | 45 | EPS $13.91 vs $12.71 cons (+9.4%, Nasdaq calendar, secondary), rev $3.77B (+50%), backlog $17.81B vs $14.06B q/q, op cash flow $1.01B; still -9.3% after -8.7% on 10-22, moved with AI-infrastructure/data-center cluster (BE, CRDO, … |
| **CART** | +9.2105% (51.68 → 56.44) | intraday (afternoon) 10-23: The Information report, then Bloomberg follow-up; e…; anchor 2026-10-23, reaction 2026-10-23 | 60 | Report of a sale process (30-40% premium would imply ~$16-17B vs ~$12B cap) lifted CART +9.21% to 56.44 on 11.4M shares (~7x avg); unconfirmed, one bidder reportedly exited. |
| **CCI** | +9.0575% (78.83 → 85.97) | after-close 10-22 (Bloomberg report that SpaceX is in talks with Crown Castle/A…; anchor 2026-10-22, reaction 2026-10-23 | 45 | Bloomberg report after the 10-22 close that SpaceX is negotiating access to >=80k towers incl. Crown Castle; stock gapped to 91.56 high then closed +9.06%; not confirmed by the company; media-report catalyst on top of 10-21 AMC e… |
| **RITM** | +8.1797% (8.68 → 9.39) | pre-open 10-23, EDGAR accepted 07:24:56 ET; anchor 2026-10-23, reaction 2026-10-23 | 45 | EAD $0.55 vs $0.51 cons (Nasdaq calendar, secondary); GAAP EPS $0.38 vs $0.04 q/q, BV/share $12.51, fee-based asset-management growth; mortgage REITs/financials firm so partly sector. |
| **FCNCA** | +8.1520% (2196.76 → 2375.84) | pre-open 10-23, EDGAR accepted 06:31:24 ET (8-K 2.02/7.01/8.01); anchor 2026-10-23, reaction 2026-10-23 | 60 | EPS $55.37 vs $46.61 cons (+18.8%, Nasdaq calendar, secondary); mgmt said results exceeded expectations, new $1.2B repurchase plan, repaid $8B of Purchase Money Note, closed BMO branch deal; regional banks also bid (GBCI, COLB, C… |
| **CUBI** | +7.3797% (78.73 → 84.54) | after-close 10-22, EDGAR accepted 16:45:50 ET; anchor 2026-10-22, reaction 2026-10-23 | 60 | EPS $2.27 vs $2.15 cons (+5.6%, Nasdaq calendar, secondary); NII +7.6% q/q, efficiency ratio 47.2%, record deposits/loans, raised FY guide (NII $805-810M); regional banks broadly firm (FCNCA, GBCI, COLB) so some sector tailwind. |
| **SSNC** | -7.3487% (89.54 → 82.96) | after-close 10-22, EDGAR accepted 16:24:53 ET; anchor 2026-10-22, reaction 2026-10-23 | 45 | Adj EPS $1.78 (+14.8%) / rev $1.690B (+7.8%) vs Nasdaq-calendar cons $1.59 (GAAP/adj basis mismatch likely, secondary); FY26 adj EPS guide $7.11-7.17, Q4 $1.88-1.94; GAAP EPS flat, reason for -7.3% not clear from release (possibl… |
| **REXR** | +6.6979% (36.28 → 38.71) | after-close 10-22, EDGAR accepted 16:28:26 ET; anchor 2026-10-22, reaction 2026-10-23 | 60 | Core FFO $0.60 in line (cons $0.60, Nasdaq calendar) but 2026 Core FFO/share guidance raised, $1.5B YTD dispositions ($1.2B portfolio sale), $408.7M buyback at ~$37.59; same-property NOI -2.6%. |
| **KNSL** | -6.6941% (390.64 → 364.49) | after-close 10-22, EDGAR accepted 16:11:00 ET; anchor 2026-10-22, reaction 2026-10-23 | 45 | Operating EPS $5.70 vs $4.95 cons (+15%, Nasdaq calendar, secondary) but GAAP EPS $4.36 vs $6.09 y/y, GWP -4.8%, NWP -1.5%; stock had run +6.1% on 10-22 into print, so sell-the-news on premium decline. |
| **ENVA** | -6.6241% (176.78 → 165.07) | after-close 10-22, EDGAR accepted 16:16:13 ET; anchor 2026-10-22, reaction 2026-10-23 | 30 | Adj EPS $4.48 / diluted $4.06 vs $4.19 cons (Nasdaq calendar printed $4.15, basis unclear, secondary), originations +31%, stable credit; fell -6.6% inside a consumer-finance selloff (SLM -10.8%, DAVE -7.3%, GPGI -9.6%, SEZL -5.2%… |
| **INFY** | -6.5809% (13.22 → 12.35) | scheduled ~15:45 IST 10-23 (~06:15 ET) per Kotak Neo preview (secondary); EDGAR…; anchor 2026-10-23, reaction 2026-10-23 | 60 | Q2 rev $5,145M (+1.5% cc y/y), op margin 21.0%, large-deal TCV $5.2B, but FY27 cc revenue guide revised to 1-2% (margin 20-22% kept); EPS $0.20 vs $0.21 cons (Nasdaq calendar, secondary); ADR cap >$10B; exact release minute not v… |
| **TEM** | +5.9552% (63.81 → 67.61) | pre-open 10-23, EDGAR 8-K Item 8.01 acceptance 09:00:30 ET; anchor 2026-10-23, reaction 2026-10-23 | 30 | $55M max cash over five years is small versus an ~$11.6B cap and a >$1.5B revenue run-rate; +5.96% is only just over floor, with prior -9.0% (10-16) and -5.8% (10-22) swings showing a news-flow-sensitive name. |
| **SIGI** | +5.3085% (91.74 → 96.61) | after-close 10-22, EDGAR accepted 16:18:10 ET; anchor 2026-10-22, reaction 2026-10-23 | 60 | Operating EPS $2.37 vs $1.91 cons (+24%, Nasdaq calendar, secondary), combined ratio 96.8%, NII guide raised to $490M, dividend +12% and new $200M buyback; NPW -7% tempers; P&C peers KNSL/ORI fell so idiosyncratic. |

- **Source caveats.** CART's event is a media report (The Information / Bloomberg / Reuters, 10-23 afternoon) that Instacart is exploring a sale. CCI's is a Bloomberg report after the 10-22 close. Neither is an issuer release. INFY's release minute comes from a broker schedule (~06:15 ET), not the issuer's page; the anchor is 10-23 either way.
- **Below the floor, own events (context only, `below_spec_floor`).** RNG +4.9987, GNTX -4.97, DECK -4.91, NEM -4.59, GBCI +3.96, AXP -3.67, KRC +3.64, KN -3.62, ALV -3.54, SAM +3.35, COLB +3.25, APPF -3.09, FHB -3.02, WDC -2.97, MXL -2.79, AMR +2.64, CRS -2.60, HTH -2.47, RCI -2.44, BCPC +2.18. RNG is +4.9987%, under the floor by 0.0013pp.
- **Not routed.**
  - **Ineligible:** RGC −21.81, VCRE −9.11 (a giveback of its 10-22 pop), ZLAB +9.03, MMYT −7.17, INTR +6.68, VIST +5.99 and BBAR +5.36 are foreign issuers under the $10B ADS line. CORT −20.13 fell on GMAB's competing Phase 3 win with no event of its own.
  - **Common driver (28):**
    - cybersecurity 12 (NTSK +9.37, FSLY, SAIL, CRWD +8.25, ZS, NET, PANW, FROG, S, RBRK, TENB, OKTA), on the AI-enabled attack wave;
    - energy 15 (NE +8.53, TDW +8.11, SLB +7.08, WFRD, SDRL, MTDR, VAL, PTEN, RIG, NOV, HAL, ECO, EQNR, LPG, CHRD), on Brent +3.1%;
    - TMUS −7.71, on the SpaceX tower report.
  - **No own event found (38)**, limited search, not proof of absence:
    - following sessions: TTMI, VC, CBRE, FCFS, GL, T, OII, TR, CLF;
    - no event found: WGS −16.37, GPGI −9.64, CRDO −9.51 (competition commentary only), VG +9.29, PBLS, NAMS, LQDA, DAVE, FIVN, AXSM, OSCR, NWL, BETA, PENN, OUST, IEP, KRMN, MBLY, VKTX, BHVN, SMTC, COKE, TARS, AMBA, OLLI, JMKE, SEZL, KNSA, LOAR.
  - **Anchor UNRESOLVED:** BBD +3.04. Its IBKR 10-22 bar also fails low≤close by $0.01; it is below the floor anyway.
- **Close-chain check (one read).** Research-screen items since 10-15 were checked for 32 names with anchors 10-22/10-23. There was **one CHAIN HIT: FPS.** My pair 24.92 → 24.22 starts at the 10-22 item's `event_close` (`5022f59e`, 31.76 → 24.92, CFO resignation pre-open 10-22). This item measures an after-close 10-22 preliminary-results release, so the chain is legitimate. The 10-22 B-index disposition carries forward, and no second disposition is written. Coverage is partial, so a clean pass is not a clearance.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` `67d505a8-1190-4a2b-84bc-58b69f8475c7` (`surfaced_count` 8). Registry contract ids were used, and the guard closes (XLK 182.34, XLP 89.99, XLU 42.87, XLC 107.42) matched.

- **XLE +2.6047%** (67.57 → 69.33), conviction 60: the oil bid. Brent December settled $116.72 on 10-23 vs $113.17 on 10-22 on continued Houthi strikes and US-Iran strike talk. SLB beat, and energy services rose 5-8%.
- **XLP −1.9224%** (89.99 → 88.26), conviction 45: a giveback of the 10-22 +3.31% defensive bid as the 10Y moved toward 5%.
- **XLC −1.7781%** (107.42 → 105.51), conviction 45: T −7.96 and TMUS −7.71 on the SpaceX tower-lease report.
- **XLY −1.6607%, XLF −1.3239%, XLI −1.2655%, XLV −1.1142%**, conviction 30:
  - XLY: broad consumer weakness after UMich at 48.0, plus LKQ;
  - XLF: the consumer-finance selloff (SLM, ENVA, AXP);
  - XLI: AI-infrastructure contractors (FIX, BE);
  - XLV: a defensive giveback plus CORT.
- **XLK +0.4881%**, dispersion only (`legacy_rule_pass=false`), conviction 30: cybersecurity rose 6-9% against a flat-to-weak hardware complex.
- **Under 1%, not surfaced:** XLB −0.74, XLU −0.72, XLRE +0.12.

### 5. Notable commentary

- Edward Jones (Kourkafas): investors are "increasingly focused on the economics of AI". Alpine Macro (Giorgi): the market is "not giving the benefit of the doubt" to heavy AI spenders.
- BakerAvenue (Lip) says the market needs "another round of really strong earnings". Greenwood (Todd) is watching the Warsh press conference for the rate path.
- Citi named CCI, SBAC, AMT and EchoStar as SpaceX-tower beneficiaries (secondary). The Fed is in blackout, and no sell-side notes on held names were captured.
- Week ahead: KO and BA (10-27); **GEV pre-open and the FOMC at 14:00 ET on 10-28, with GOOGL and MSFT after the close**; LLY, MA, then **AMZN** after the close, plus Q3 GDP and September PCE (10-29); XOM and CVX (10-30). AAPL reports 11-02, and the midterms are 11-03. UBER's date was not found.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- I swept the union of `state.current_positions` (12 tranches, re-read before the appends and unchanged) and IBKR `get_account_positions`, and they agree on every name:
  - AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156.
  - VOO 17.7307 is the park. There is no reconciliation-lag position.
- All 12 tranches are Strategy D, with no `convergence_target` and no `time_exit_date`, so **no exit is triggered**.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-22; D2a has not written a 10-23 engine row, see below):
  - unit 1.0409 vs peak 1.1065 (drawdown −5.93%); `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` all FALSE.
  - **Refreshed on IBKR 10-23 closes**, the D book fell −0.71% ($534.29 → $530.51), which puts the unit at ≈1.0335 and the drawdown at **≈−6.59%** against the −50% kill.
- **B:** no open position. The `analytics.b_pairwise_correlation` check is inert (n_positions 0).
- No other strategy holds positions. **No termination and no runaway review.** There is no open `interim_underperf_warning` alert to heal.

### Thesis-invalidation review

EDGAR shows no 8-K or 6-K from any held name inside the window (AMZN, DIS, GOOGL, UBER last filed in Aug-Sep; ISRG and RTX on 10-20; TSM on 10-15 and 10-22). Web coverage was one wide search plus one GEV search, so "none found" is not proof of none.
- **GEV** (D:GEV:2026-08-03): −1.50% (827.42 → 815.00) after −10.64% on 10-22. There is no GEV-specific news (its only 10-23 release was a UK education item). BofA expects Q3 orders of ~$21.0B vs ~$22.2B consensus (secondary).
  - The orders criterion becomes testable at the **10-28 pre-open Q3**. Price action is on its not-exit-triggering list. UNBREACHED.
- **UBER** (−3.43%, to 66.70): no company news. The CART-sale report names Uber as a possible bidder (secondary), which is not a criterion. UNBREACHED.
- **AMZN** (−0.95%), **GOOGL** (−1.24%), **TSM** (+1.49%), **ISRG** (+1.90%), **RTX** (−1.90%), **DIS** (−0.54%): no news since the already-assessed items, and all criteria are UNBREACHED or not testable this window. GOOGL (10-28) and AMZN (10-29) report next week (secondary dates).

**Watchlist candidacy:** the Strategy B new-entry index gains 20 names (below). No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** The 20 own-event floor clearers are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only. A full thesis would be needed in a separate session if B activates.
- **C.** Strategy C stays HYBRID ACTIVATE (FOMC-only); the 10-27/28 FOMC is already gated under `thesis-FOMC-C-20261020`. No new qualifying catalyst within 45 days was found.
- **A.** `DO-NOT-ACTIVATE` (div-A-202610-1). Not a candidate.
- **E.** `DO-NOT-ACTIVATE` (div-E-202610-1). These intra-group divergences are recorded for M2, not routed:
  - towers vs carriers: CCI +9.06 vs T −7.96 / TMUS −7.71, on one SpaceX report;
  - regional banks: FCNCA +8.15 / CUBI +7.38 vs FLG −9.27;
  - ovarian-cancer ADC peers: GMAB +9.48 vs CORT −20.13.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `f66de309-7da2-4f4b-9478-6ceb66dfe348`. All 12 open D tranches were evaluated, 0 were flagged and 0 were declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12, and positions were re-read immediately before the append. Each tranche is marked at its IBKR 10-23 close against its own cost basis per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +29.41% | none | declined |
| D:DIS:2026-08-05 | +8.42% | none | declined |
| D:RTX:2026-04-27 | +7.98% | none | declined |
| D:TSM:2026-07-29 | +6.52% | none | declined |
| D:AMZN:2026-07-09 | +2.80% | none | declined |
| D:DIS:2026-05-07 | +1.08% | none | declined |
| D:TSM:2026-07-21 | −2.19% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-26 | −2.33% | dip-with-intact-thesis | declined: no funding path |
| D:AMZN:2026-07-30 | −6.66% | dip-with-intact-thesis | declined: no funding path |
| D:UBER:2026-07-09 | −8.89% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-09 | −11.02% | dip-with-intact-thesis | declined: no funding path |
| D:GEV:2026-08-03 | −15.97% | dip-with-intact-thesis | declined: no funding path; Q3 10-28 |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- **Technical side.** VIX is not re-measured here. SPY closed at 759.97 (−0.52%), and breadth fell to 56.06 (D2a classifies it; still above 50). The measured refresh triggers are D2's to detect.
- **Geopolitical-trigger duty.**
  - The 10-25 Houthi missile and drone attacks on Riyadh and Aramco Yanbu are a dated, attributable escalation, and so are the 10-23 US departure taking effect, the UAE spill and the Libya valve shut. Their oil leg is Brent +3.1% on 10-23 (113.17 → 116.72) and +7.3% over two sessions (108.82 → 116.72).
  - But `shock_overlay` already reads `acute`, and the rubric escalates no further. So no scenario-3 flag is owed.
  - On the mirror: Iran's 7-day ceasefire is **proposed and under review, not in force**. There is no blockade lifted, no settlement and no sanctions change, and the oil leg points the other way. So it is not a qualifying resolution event.
- No other Development plausibly shifts any strategy's activation state.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **56.06 for 2026-10-23**. The value is source-dated by Barchart `$S5TH`: "Quote Overview for Fri, Oct 23rd, 2026", 56.06 −1.19 (−2.08%), Previous Close 57.25, which equals the stored 10-22 value with no revision. O/H/L 56.46/56.85/55.86 is a real bar, not a carry. It was fetched via tavily_extract at 22:35Z Sunday, so the value is settled.

- **Single usable source.** EODData's 23 Oct row agrees exactly, but Barchart and EODData are one feed.
- **Independent check.** ChartRow (as of the 10-23 close) shows 277 of 497 = 55.73%. Its day-over-day change of −1.21pp vs `$S5TH` −1.19pp gives `chartrow_dod_gap=0.02`.
- **MacroMicro weekly re-probe (Sunday): FAILED.** tavily_extract returned "Failed to fetch url" and WebFetch HTTP 403, unbroken since 2026-08-19. Barchart stays primary.
- Not an exact repeat.

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The 20 eligible own-event floor clearers are indexed below instead.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `290d4251-8c5b-4fba-86f5-dc034c7e4057`.

- ADD **LKQ** (Strategy B, `qualifying_event_date` 2026-10-23) — -22.4744% (22.47 → 17.42); Prelim Q3 rev $3.32B vs $3.50B y/y, adj EPS $0.47-0.53 vs $0.84 y/y, Europe organic -9.8% (ERP disruption in Germany), $111M impairments, FY26 guidance withdrawn, new CEO (Abbate) and Alvarez & Marsa…; index only. 1 other ≥5% session(s) in the window.
- ADD **RHI** (Strategy B, `qualifying_event_date` 2026-10-22) — +21.7357% (37.68 → 45.87); Q3 EPS $0.49 vs ~$0.47 cons (Nasdaq calendar, secondary) on rev $1.359B flat y/y; Talent Solutions returned to y/y growth (+2%) first time since 2022 and earnings beat guide midpoint; +21.7% is a sho…; index only. 1 other ≥5% session(s) in the window.
- ADD **TNGX** (Strategy B, `qualifying_event_date` 2026-10-23) — -16.4339% (27.93 → 23.34); Vopimetostat+daraxonrasib PDAC data (82% ORR, 9-mo PFS 88%, Ph3 1H27) at ESMO 10-23; stock sold off -16.4% on 12.4M shares after a +22% run into the data (sell-the-news). 5 other >=5% session(s) in w…; index only. 5 other ≥5% session(s) in the window.
- ADD **BE** (Strategy B, `qualifying_event_date` 2026-10-22) — -11.2366% (217.77 → 193.3); Record rev $1,235.8M (+138%), non-GAAP EPS $0.94 vs $0.56 cons (Nasdaq calendar, secondary), FY26 rev guide raised to $4.4-4.6B, yet -11.2% after -8.7% on 10-22; fell with AI-infrastructure cluster (…; index only. 5 other ≥5% session(s) in the window.
- ADD **SLM** (Strategy B, `qualifying_event_date` 2026-10-22) — -10.7996% (21.76 → 19.41); GAAP EPS -$0.19 vs +$0.12 cons (Nasdaq calendar, secondary); FY26 EPS guide cut to $1.95-2.05 from $3.10-3.20, NCO guide raised to $400-420M (third-party debt-collection practice issue); consumer-fin…; index only.
- ADD **GMAB** (Strategy B, `qualifying_event_date` 2026-10-23) — +9.4750% (40 → 43.79); Phase 3 RAINFOL-02 of Rina-S met PFS primary and OS key secondary in platinum-resistant ovarian cancer; ADS +9.5% on 3x volume; FPI (6-K filer) but cap ~$25B >= $10B.; index only.
- ADD **FLG** (Strategy B, `qualifying_event_date` 2026-10-23) — -9.2657% (11.44 → 10.38); EPS $0.01 vs $0.06 cons (Nasdaq calendar, secondary); provision +$58M on NYC rent-regulated multifamily/higher rates; NII +5% and loans +6% annualized offset; idiosyncratic (other banks rose).; index only.
- ADD **FIX** (Strategy B, `qualifying_event_date` 2026-10-22) — -9.2632% (1279.37 → 1160.86); EPS $13.91 vs $12.71 cons (+9.4%, Nasdaq calendar, secondary), rev $3.77B (+50%), backlog $17.81B vs $14.06B q/q, op cash flow $1.01B; still -9.3% after -8.7% on 10-22, moved with AI-infrastructure/d…; index only. 2 other ≥5% session(s) in the window.
- ADD **CART** (Strategy B, `qualifying_event_date` 2026-10-23) — +9.2105% (51.68 → 56.44); Report of a sale process (30-40% premium would imply ~$16-17B vs ~$12B cap) lifted CART +9.21% to 56.44 on 11.4M shares (~7x avg); unconfirmed, one bidder reportedly exited.; index only.
- ADD **CCI** (Strategy B, `qualifying_event_date` 2026-10-22) — +9.0575% (78.83 → 85.97); Bloomberg report after the 10-22 close that SpaceX is negotiating access to >=80k towers incl. Crown Castle; stock gapped to 91.56 high then closed +9.06%; not confirmed by the company; media-report …; index only. 1 other ≥5% session(s) in the window.
- ADD **RITM** (Strategy B, `qualifying_event_date` 2026-10-23) — +8.1797% (8.68 → 9.39); EAD $0.55 vs $0.51 cons (Nasdaq calendar, secondary); GAAP EPS $0.38 vs $0.04 q/q, BV/share $12.51, fee-based asset-management growth; mortgage REITs/financials firm so partly sector.; index only.
- ADD **FCNCA** (Strategy B, `qualifying_event_date` 2026-10-23) — +8.1520% (2196.76 → 2375.84); EPS $55.37 vs $46.61 cons (+18.8%, Nasdaq calendar, secondary); mgmt said results exceeded expectations, new $1.2B repurchase plan, repaid $8B of Purchase Money Note, closed BMO branch deal; regional…; index only.
- ADD **CUBI** (Strategy B, `qualifying_event_date` 2026-10-22) — +7.3797% (78.73 → 84.54); EPS $2.27 vs $2.15 cons (+5.6%, Nasdaq calendar, secondary); NII +7.6% q/q, efficiency ratio 47.2%, record deposits/loans, raised FY guide (NII $805-810M); regional banks broadly firm (FCNCA, GBCI, C…; index only.
- ADD **SSNC** (Strategy B, `qualifying_event_date` 2026-10-22) — -7.3487% (89.54 → 82.96); Adj EPS $1.78 (+14.8%) / rev $1.690B (+7.8%) vs Nasdaq-calendar cons $1.59 (GAAP/adj basis mismatch likely, secondary); FY26 adj EPS guide $7.11-7.17, Q4 $1.88-1.94; GAAP EPS flat, reason for -7.3% n…; index only.
- ADD **REXR** (Strategy B, `qualifying_event_date` 2026-10-22) — +6.6979% (36.28 → 38.71); Core FFO $0.60 in line (cons $0.60, Nasdaq calendar) but 2026 Core FFO/share guidance raised, $1.5B YTD dispositions ($1.2B portfolio sale), $408.7M buyback at ~$37.59; same-property NOI -2.6%.; index only.
- ADD **KNSL** (Strategy B, `qualifying_event_date` 2026-10-22) — -6.6941% (390.64 → 364.49); Operating EPS $5.70 vs $4.95 cons (+15%, Nasdaq calendar, secondary) but GAAP EPS $4.36 vs $6.09 y/y, GWP -4.8%, NWP -1.5%; stock had run +6.1% on 10-22 into print, so sell-the-news on premium declin…; index only.
- ADD **ENVA** (Strategy B, `qualifying_event_date` 2026-10-22) — -6.6241% (176.78 → 165.07); Adj EPS $4.48 / diluted $4.06 vs $4.19 cons (Nasdaq calendar printed $4.15, basis unclear, secondary), originations +31%, stable credit; fell -6.6% inside a consumer-finance selloff (SLM -10.8%, DAVE…; index only.
- ADD **INFY** (Strategy B, `qualifying_event_date` 2026-10-23) — -6.5809% (13.22 → 12.35); Q2 rev $5,145M (+1.5% cc y/y), op margin 21.0%, large-deal TCV $5.2B, but FY27 cc revenue guide revised to 1-2% (margin 20-22% kept); EPS $0.20 vs $0.21 cons (Nasdaq calendar, secondary); ADR cap >$1…; index only. 2 other ≥5% session(s) in the window.
- ADD **TEM** (Strategy B, `qualifying_event_date` 2026-10-23) — +5.9552% (63.81 → 67.61); $55M max cash over five years is small versus an ~$11.6B cap and a >$1.5B revenue run-rate; +5.96% is only just over floor, with prior -9.0% (10-16) and -5.8% (10-22) swings showing a news-flow-sensi…; index only. 2 other ≥5% session(s) in the window.
- ADD **SIGI** (Strategy B, `qualifying_event_date` 2026-10-22) — +5.3085% (91.74 → 96.61); Operating EPS $2.37 vs $1.91 cons (+24%, Nasdaq calendar, secondary), combined ratio 96.8%, NII guide raised to $490M, dividend +12% and new $200M buyback; NPW -7% tempers; P&C peers KNSL/ORI fell so…; index only.

```yaml d1_actions
- action: watchlist
  ticker: LKQ
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -22.4744% (22.47 -> 17.42); Prelim Q3 rev $3.32B vs $3.50B y/y, adj EPS $0.47-0.53 vs $0.84 y/y, Europe organic -9.8% (ERP disruption in Germany), $111M impairments, FY26 guidance withdrawn, new CEO (Abbate) and Alvarez & Marsa…; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: RHI
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +21.7357% (37.68 -> 45.87); Q3 EPS $0.49 vs ~$0.47 cons (Nasdaq calendar, secondary) on rev $1.359B flat y/y; Talent Solutions returned to y/y growth (+2%) first time since 2022 and earnings beat guide midpoint; +21.7% is a sho…; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: TNGX
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -16.4339% (27.93 -> 23.34); Vopimetostat+daraxonrasib PDAC data (82% ORR, 9-mo PFS 88%, Ph3 1H27) at ESMO 10-23; stock sold off -16.4% on 12.4M shares after a +22% run into the data (sell-the-news). 5 other >=5% session(s) in w…; index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: BE
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -11.2366% (217.77 -> 193.3); Record rev $1,235.8M (+138%), non-GAAP EPS $0.94 vs $0.56 cons (Nasdaq calendar, secondary), FY26 rev guide raised to $4.4-4.6B, yet -11.2% after -8.7% on 10-22; fell with AI-infrastructure cluster (…; index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: SLM
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -10.7996% (21.76 -> 19.41); GAAP EPS -$0.19 vs +$0.12 cons (Nasdaq calendar, secondary); FY26 EPS guide cut to $1.95-2.05 from $3.10-3.20, NCO guide raised to $400-420M (third-party debt-collection practice issue); consumer-fin…; index only
- action: watchlist
  ticker: GMAB
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +9.4750% (40 -> 43.79); Phase 3 RAINFOL-02 of Rina-S met PFS primary and OS key secondary in platinum-resistant ovarian cancer; ADS +9.5% on 3x volume; FPI (6-K filer) but cap ~$25B >= $10B.; index only
- action: watchlist
  ticker: FLG
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -9.2657% (11.44 -> 10.38); EPS $0.01 vs $0.06 cons (Nasdaq calendar, secondary); provision +$58M on NYC rent-regulated multifamily/higher rates; NII +5% and loans +6% annualized offset; idiosyncratic (other banks rose).; index only
- action: watchlist
  ticker: FIX
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -9.2632% (1279.37 -> 1160.86); EPS $13.91 vs $12.71 cons (+9.4%, Nasdaq calendar, secondary), rev $3.77B (+50%), backlog $17.81B vs $14.06B q/q, op cash flow $1.01B; still -9.3% after -8.7% on 10-22, moved with AI-infrastructure/d…; index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: CART
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +9.2105% (51.68 -> 56.44); Report of a sale process (30-40% premium would imply ~$16-17B vs ~$12B cap) lifted CART +9.21% to 56.44 on 11.4M shares (~7x avg); unconfirmed, one bidder reportedly exited.; index only
- action: watchlist
  ticker: CCI
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +9.0575% (78.83 -> 85.97); Bloomberg report after the 10-22 close that SpaceX is negotiating access to >=80k towers incl. Crown Castle; stock gapped to 91.56 high then closed +9.06%; not confirmed by the company; media-report …; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: RITM
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +8.1797% (8.68 -> 9.39); EAD $0.55 vs $0.51 cons (Nasdaq calendar, secondary); GAAP EPS $0.38 vs $0.04 q/q, BV/share $12.51, fee-based asset-management growth; mortgage REITs/financials firm so partly sector.; index only
- action: watchlist
  ticker: FCNCA
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +8.1520% (2196.76 -> 2375.84); EPS $55.37 vs $46.61 cons (+18.8%, Nasdaq calendar, secondary); mgmt said results exceeded expectations, new $1.2B repurchase plan, repaid $8B of Purchase Money Note, closed BMO branch deal; regional…; index only
- action: watchlist
  ticker: CUBI
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +7.3797% (78.73 -> 84.54); EPS $2.27 vs $2.15 cons (+5.6%, Nasdaq calendar, secondary); NII +7.6% q/q, efficiency ratio 47.2%, record deposits/loans, raised FY guide (NII $805-810M); regional banks broadly firm (FCNCA, GBCI, C…; index only
- action: watchlist
  ticker: SSNC
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -7.3487% (89.54 -> 82.96); Adj EPS $1.78 (+14.8%) / rev $1.690B (+7.8%) vs Nasdaq-calendar cons $1.59 (GAAP/adj basis mismatch likely, secondary); FY26 adj EPS guide $7.11-7.17, Q4 $1.88-1.94; GAAP EPS flat, reason for -7.3% n…; index only
- action: watchlist
  ticker: REXR
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +6.6979% (36.28 -> 38.71); Core FFO $0.60 in line (cons $0.60, Nasdaq calendar) but 2026 Core FFO/share guidance raised, $1.5B YTD dispositions ($1.2B portfolio sale), $408.7M buyback at ~$37.59; same-property NOI -2.6%.; index only
- action: watchlist
  ticker: KNSL
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -6.6941% (390.64 -> 364.49); Operating EPS $5.70 vs $4.95 cons (+15%, Nasdaq calendar, secondary) but GAAP EPS $4.36 vs $6.09 y/y, GWP -4.8%, NWP -1.5%; stock had run +6.1% on 10-22 into print, so sell-the-news on premium declin…; index only
- action: watchlist
  ticker: ENVA
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -6.6241% (176.78 -> 165.07); Adj EPS $4.48 / diluted $4.06 vs $4.19 cons (Nasdaq calendar printed $4.15, basis unclear, secondary), originations +31%, stable credit; fell -6.6% inside a consumer-finance selloff (SLM -10.8%, DAVE…; index only
- action: watchlist
  ticker: INFY
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — -6.5809% (13.22 -> 12.35); Q2 rev $5,145M (+1.5% cc y/y), op margin 21.0%, large-deal TCV $5.2B, but FY27 cc revenue guide revised to 1-2% (margin 20-22% kept); EPS $0.20 vs $0.21 cons (Nasdaq calendar, secondary); ADR cap >$1…; index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: TEM
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +5.9552% (63.81 -> 67.61); $55M max cash over five years is small versus an ~$11.6B cap and a >$1.5B revenue run-rate; +5.96% is only just over floor, with prior -9.0% (10-16) and -5.8% (10-22) swings showing a news-flow-sensi…; index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: SIGI
  strategy: B
  qualifying_event_date: 2026-10-22
  source_research_screen_id: 290d4251-8c5b-4fba-86f5-dc034c7e4057
  detail: ADD to B new-entry index — +5.3085% (91.74 -> 96.61); Operating EPS $2.37 vs $1.91 cons (+24%, Nasdaq calendar, secondary), combined ratio 96.8%, NII guide raised to $490M, dividend +12% and new $200M buyback; NPW -7% tempers; P&C peers KNSL/ORI fell so…; index only
```

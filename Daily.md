2026-10-28
<!-- d1_scan_through_utc: 2026-10-28T22:10:00Z -->

# Daily Market Development Scan — session 2026-10-28 (Wed)

Scan window: 2026-10-27 16:10 MT → 2026-10-28 16:10 MT (~24h). The start is the prior `Daily.md` marker `2026-10-27T22:10:00Z`; that file's commit (22:31Z) agrees, and `state.routine_catchup_window` gives 0.98 days. The window holds **one completed US session, Wednesday 2026-10-28**. Moves are 10-27 → 10-28 close-to-close on IBKR regular-session daily bars.

Tape: **an FOMC hold with two hawkish dissents, a cap-weighted up day led by memory and semis, and a heavy earnings slate.**
- **Indices.** IBKR closes, 10-27 → 10-28: SPY 769.66 → **772.31 (+0.34%)**, QQQ +0.60%, IWM +0.40%, DIA +0.27%, **RSP -0.04%**, **SMH +1.74%**. Equal-weight was flat, so leadership was cap-weighted again.
- **Volatility.** The VIX fell 17.52 → 16.91 (-3.48%; IBKR CBOE bar, delayed feed).
- **Rates.** FMP par yields for 10-28: 2Y 4.67 (from 4.70), 10Y 5.05 (from 4.99), 30Y 5.37. TLT -0.78%, HYG -0.01%.
- **Oil.** Brent December settled **$113.88 on 10-27** (DTN/Rigzone). The 10-28 settle is **unconfirmed**: one secondary source gives about $115.32 (+1.3%) and WTI about $102.78, consistent with intraday reports of $115-116, but no exchange or primary print was found, so no level is quoted as the 10-28 settle. USO +1.64% on IBKR. Brent December expires 10-30.
- **Gold and crypto.** GLD +0.33%. Gold about $4,052 and BTC about $81.2k (FMP live quotes at fetch, not settles).
- **Leadership.** No sector SPDR moved 1%: XLK +0.80% led and XLU -0.84% lagged. Breadth fell to **58.25** (from 59.24).

## TL;DR

- **Exits triggered: none.** Twelve Strategy D tranches carry no mechanical trigger. GEV's Q3 (organic orders +96%) and GOOGL's Q3 (Cloud +103%, margin 36.2%) breach no invalidation criterion.
- **New entry candidates: none routed.** 45 names cleared Strategy B's frozen ≥5% floor on their own issuer events, led by AXGN, GMAB, FFIV, LSTR, ICLR, VRT, ENPH, BLCO, LPLA and ORCL. B is `DO-NOT-ACTIVATE` and capital-disabled, so 44 B-eligible names go to the index only (EDU is a sub-$10B ADS). SK hynix (+13.3%) is recorded with an UNRESOLVED anchor and not routed.
- **Add candidates: none (0 of 12).** GEV and GOOGL read as strengthened conviction and four tranches as dip-with-intact-thesis, but D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 44 changes.** ADD the 44 names to the Strategy B new-entry index.
- **Regime review: no review.** The FOMC hold is not a geopolitical trigger. The Houthi claim on Ras Tanura (10-27) is unconfirmed and sits inside the standing `acute` overlay, and there was no ceasefire, settlement or blockade lift.

Park: VOO-only pin verified

Paper book (J): 120 calls, 81/30 realized, net_mu -0.99%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **FOMC (10-28, 14:00 ET; federalreserve.gov release).** The Committee **held at 3.75-4.00%** on a **10-2 vote**: Cook and Hammack dissented in favour of a 25bp hike.
  - The statement switched "raise" to "maintain", described activity as expanding "at a strong pace", and added that "accumulation of more information will help the Committee determine the policy stance". It still calls inflation elevated and cites geopolitical uncertainty.
  - Chair Kevin Warsh, at the 14:30 ET presser, said inflation has been above target for about six years and the September hike is taking hold. He also said one 2027 meeting and two 2028 meetings will be strategy-only, with no rate vote.
  - Reaction (secondary, Yahoo live blog): equities edged up and the 10Y moved back above 5%. On IBKR closes SPY finished +0.34% and TLT −0.78%.
- **Gulf (no resolution).**
  - On 10-27 the Houthis claimed a ballistic-missile strike on Aramco's Ras Tanura refinery. Saudi Arabia did not confirm a hit, and the coalition reported intercepting three missiles and four drones (MarketScreener/DJ, WSJ; secondary).
  - On 10-28 one secondary source reported that the US gave Gulf states advance notice of a possible strike on Iran after the 11-03 midterms. It is single-source and unconfirmed.
  - The 10-26 Tehran talks produced no agreement. There is no ceasefire or settlement in force and no blockade lift.
- **Israel election.** Not final. With 48.4% counted, Netanyahu's bloc had 55 seats and Eisenkot's 50, with neither at 61. Final results are expected on 10-29 (CBC, AP).
- **Not measured:** tariff/trade actions, bankruptcies, enforcement actions and disasters got one combined search that returned nothing relevant. That is unmeasured, not "none".

### 2. Scheduled events that resolved in the window

- **Enumeration.** I fetched the Nasdaq key-less calendar with curl for 10-27, 10-28 and 10-29. At ≥$2B (held names excluded) it lists 156 issuers on 10-28 (64 pre-market, 90 after-hours, 2 not supplied). Slots come from EDGAR acceptance stamps: 61 reported after the 10-27 close, 58 before the 10-28 open, 3 intraday (APH, GSK, AER) and 82 after the 10-28 close. Consensus figures are the Nasdaq calendar's (secondary); EPS was read from the release for only a subset, so surprises are quoted only where verified.
- **Macro (10-28; tradingeconomics, secondary).** MBA mortgage applications +3.4%. The September advance goods deficit was −$134.9B against −$130B expected. Advance wholesale inventories +0.6% against +0.5%. EIA crude, ADP and retail-inventory actuals were not found.
- **10-27 after-close reporters (reacted 10-28).** V $3.48 vs $3.43; STX $7.68 vs $7.17 (+4.51%, below the floor); NXPI $4.20 vs $3.78; OKE $2.13 vs $1.46; BKR $0.70 vs $0.63 (−7.36%); TER $2.29 vs $2.04; HOOD $0.60 adjusted; RRC $0.82 vs $0.66. Floor-clearing reactions are in §3: FFIV −20.4%, LSTR −17.8%, ICLR +17.0%, ENPH −16.0%, LPLA −15.2%, CSGP −14.0%, LOGI −12.1%, ZWS −11.5%, MIR, ENSG, UCTT, RUSHA/B, BKR, NOV and INTA.
  - **NOV:** the 8-K was accepted at 09:00 ET on 10-28, but its Item 2.02 states the release was issued on October 27. That puts the anchor at 10-27, reacting 10-28; the two legs disagreed and the issuer text settled it.
  - **MANH:** the 10-27 16:02 ET 8-K carries Items 2.01/3.03/5.02 and no 2.02, so it is a transaction filing, not earnings.
- **10-28 pre-open reporters.** ADP $2.82 vs $2.78; PSX $14.08 vs $11.97; AEP $2.23 vs $2.04; BSX $0.73 in line (−5.84%); TEL $3.14 vs $3.08; HSBC, SAN, UBS, AON, GRMN, ODFL, BIIB, GEHC, FLEX, OTIS, LH, CHRW, JLL, LII, EVR, EAT, ETSY and others. Intraday: APH $0.80 vs $0.73. The ≥5% reactions are in §3.
- **Held names.** GEV (pre-open) and GOOGL (after the close) are covered under ANALYSIS — RISK.
- **10-28 after-close reporters (react 10-29, not measured).** MSFT $4.89 vs $4.71; KLAC $1.22 vs $1.18; TMUS $3.22 vs $2.86; FTNT $0.91 vs $0.77; CP $1.28 vs $0.95; EBAY $1.51 vs $1.11; ORLY $0.97 vs $0.92; NOW, EQIX, FDX, CVNA, HONA, F, CMG, RJF, STRL and about 65 more.
- **Unresolved (no earnings 8-K/6-K found):** SIM, SEB, LXP, PII, HIW, KAI (listed 10-27); MKL, ARXS, AGI, SIMO, PPC, PTEN, PFS, BBVA (10-28 after-hours); TR. TOWN could not be mapped to a CIK.
- **Pending.** 10-29: Q3 GDP advance, September PCE, the ECB, **AMZN** after the close, and LLY, MA, INTC, MRK, CAT, SHEL, LIN, GILD, SNDK and about 60 more large caps. 10-30: the BoJ. UBER's date is not company-confirmed (Nasdaq lists 11-04). The midterms are 11-03.
- **FDA.** CDER's Novel Drug Approvals 2026 page (curl) still has #47 Hibsago (10-20) as its newest entry, and the press feed ends at 10-22, so there was no novel approval on 10-27 or 10-28. CRLs are not published on those pages and are unmeasured, not absent.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df` (single-name-move). Discovery used Nasdaq quote/info regular-session closing prints for all 2,145 ≥$2B screener symbols; 2,139 were measured, and the screener's own `pctchange` was stale at this hour. **539 moved ≥2% and 122 moved ≥5%.** EDGAR was pulled for every ≥4.5% mover and IBKR close arrays for 71 names. `surfaced_count` = 46 (45 floor clearers plus ROG as sub-floor context); agreement both 45 / ai_only 1 / rule_only 77.

| Name | Move (IBKR) | Closes | Event | Anchor | Conv. | Other ≥5% sessions |
|---|---|---|---|---|---|---|
| AXGN | +31.4736% | 37.46 → 49.25 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| GMAB | +28.2516% | 44.67 → 57.29 | clinical trial 6-K | 2026-10-28 (pre-open/intraday 10-28) | 75 | 1 |
| FFIV | -20.4262% | 459.36 → 365.53 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 0 |
| LSTR | -17.7628% | 168.78 → 138.8 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 0 |
| ICLR | +17.0401% | 182.98 → 214.16 | earnings 6-K | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 1 |
| VRT | +16.4845% | 208.56 → 242.94 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 1 |
| ENPH | -16.0282% | 29.76 → 24.99 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 2 |
| BLCO | +15.7775% | 17.62 → 20.4 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| LPLA | -15.2318% | 317.56 → 269.19 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 0 |
| SLS | -14.7083% | 12.17 → 10.38 | issuer press release trial event | 2026-10-28 (pre-open/intraday 10-28) | 75 | 5 |
| CSGP | -13.9644% | 32.01 → 27.54 | earnings+acquisition 8-K 2.02/1.01/7.01 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 3 |
| HAYW | +13.5073% | 13.03 → 14.79 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 1 |
| STLA | +13.0435% | 4.14 → 4.68 | earnings 6-K | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| DBD | -12.9124% | 66.68 → 58.07 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| EDU (not B-eligible) | -12.5366% | 57.99 → 50.72 | earnings 6-K | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| EVR | +12.5144% | 259.86 → 292.38 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| OSW | +12.5050% | 24.95 → 28.07 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| EAT | +12.2102% | 196.72 → 220.74 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 0 |
| WING | +12.1843% | 123.52 → 138.57 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 75 | 2 |
| LOGI | -12.1177% | 111.82 → 98.27 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 75 | 0 |
| FLEX | +11.6137% | 83.35 → 93.03 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 3 |
| ZWS | -11.4954% | 49.15 → 43.5 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 60 | 0 |
| JLL | +11.1393% | 299.93 → 333.34 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 1 |
| CHRW | -11.1359% | 143.59 → 127.6 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 0 |
| ORCL | +10.7332% | 130.53 → 144.54 | investor day 8-K 7.01 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 0 |
| LII | -10.5927% | 372.05 → 332.64 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 0 |
| AXTI | +10.5616% | 58.23 → 64.38 | financing 8-K 1.01/7.01 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 5 |
| LH | +8.7810% | 331.17 → 360.25 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 60 | 0 |
| MIR | +8.6957% | 15.41 → 16.75 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 60 | 0 |
| ENSG | +8.6195% | 169.5 → 184.11 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 60 | 0 |
| UCTT | +8.5470% | 51.48 → 55.88 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 60 | 3 |
| RUSHA | -8.3113% | 45.48 → 41.7 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 60 | 0 |
| TEX | +7.4275% | 49.68 → 53.37 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| BKR | -7.3559% | 59.0 → 54.66 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 45 | 1 |
| ODFL | -7.3304% | 187.03 → 173.32 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| GEHC | +6.6235% | 71.11 → 75.82 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| DAN | -6.3235% | 27.2 → 25.48 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| SAN | -6.2550% | 12.47 → 11.69 | earnings 6-K | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| NOV | -6.2287% | 20.55 → 19.27 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 45 | 1 |
| BSBR | -6.1983% | 4.84 → 4.54 | earnings 6-K | 2026-10-28 (pre-open/intraday 10-28) | 45 | 1 |
| INTA | -6.0768% | 42.95 → 40.34 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 45 | 2 |
| BSX | -5.8367% | 45.06 → 42.43 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| GRMN | -5.8167% | 289.34 → 272.51 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| ETSY | +5.3502% | 87.66 → 92.35 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 1 |
| SW | -5.1951% | 42.54 → 40.33 | earnings 8-K 2.02 | 2026-10-28 (pre-open/intraday 10-28) | 45 | 0 |
| ROG (not B-eligible) | +4.9732% | 134.12 → 140.79 | earnings 8-K 2.02 | 2026-10-27 (after close 10-27, reaction 10-28) | 30 | 2 |

- **Rejected as common drivers or non-issuer events (recorded, not dropped):**
  - **SK hynix (SKHY) +13.30%:** a record Q3 (6-K 06:01 ET, released overnight in Korea). The release minute is unresolved, so its anchor is UNRESOLVED and it is not routed.
  - **Memory and semicap read-through of SK hynix:** MU +5.86%, SNDK +7.66%, LRCX +5.39%, AMAT +5.07%, plus ENTG, AMKR, FN, LITE and AAOI on Nasdaq figures.
  - **Neocloud cluster on Oracle's investor day:** NBIS +6.96% and CRWV +7.32%; miners IREN, WULF, RIOT and CORZ on Nasdaq figures.
  - **Brazil banks:** BBD −6.19% on downgrades. BSBR and SAN reported their own prints and are indexed.
  - **Analyst actions only:** GLXY +11.12%, FPS +8.45%, SIMO +7.56%.
    - **GLXY CHAIN HIT:** today's prior close of 17.18 equals the event close in `3b0ca8cf` (anchor 10-27, pre-open). The 10-27 measurement was correct, and today is session 2, so that disposition is carried forward.
  - **Other non-issuer or non-explanatory events:** ADT +7.86% (unconfirmed take-private report), CBRS −5.66% (Culper short report and lockup expiry), LCII +8.63% (unsolicited $101 proposal against a pending merger; deal-pinned), ENLT −7.46% (AGM notice only), MOD +5.15% (5.02-only 8-K).
  - **Session-2 follow-through of pre-window prints:** CLS, INIO, KNSA, BEAM, HRI.
  - **Own release after the 10-28 close (react 10-29):** FTNT −5.9%, HONA +5.4%, STRL +5.8%, KEX +6.6%, PRCH −7.7%, BHC +10.5%. Their 10-28 moves are not explained by those releases.
  - **Unattributed:** VSAT +11.3%, TEM, PRAX and most small caps in the ≥5% list.
- **Sub-floor:** ROG +4.97% on IBKR (Nasdaq +5.03%), 3bp under the frozen floor. Context only. PPG measured +4.41% on IBKR against +4.55% on Nasdaq.
- **Fan-out reconciliation.** The screen and events legs agree on 46 of 47 overlapping (ticker, date) pairs; NOV was settled by its issuer 8-K text. The close-chain check found one hit, GLXY (above).

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` `1363808c-82bf-494d-90ae-c5420ec7bfbd` (sector-move): **a quiet sector tape, surfaced_count 0**, with all 11 SPDRs measured on registry contract ids. The 10-27 closes match the prior run on every guard symbol.
- XLK +0.80, XLF +0.45, XLV +0.30, XLY -0.10, XLP -0.36, XLE +0.35, XLI +0.34, XLB +0.15, XLU -0.84, XLRE -0.73, XLC -0.42.
- The max-min spread was XLK vs XLU, 1.64pp, on an FOMC hold with yields higher: rate-sensitive XLU/XLRE lagged and tech led. That is ordinary rate-day dispersion, not a significant sector move.

### 5. Notable commentary

- **Fed:** Warsh's presser (above), with Cook and Hammack dissenting for a hike. EY-Parthenon had expected a "hawkish hold".
- **Oil:** UBS raised its Brent forecast to about $110 through end-2026, from $100 (10-27). ING says clarity comes only after the 11-03 midterms and the risk premium may erode without renewed strikes. Commerzbank flags possible new US strikes on Iran after the midterms.
- **Israel:** Citi says the deadlock raises the odds of a volatile path, with a negotiated deal by year-end still its central case.
- **Corporate:** Oracle's investor day set FY30 targets of $225B+ revenue and $21+ non-GAAP EPS, with capital raises capped at $20B through FY30. SK hynix said more than half of its 2027-28 capacity is committed and spoke of a memory shortage running to 2030 (secondary).

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- I swept the union of `state.current_positions` (12 tranches, re-read before the appends and unchanged) and IBKR `get_account_positions`, and they agree on every name:
  - AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156.
  - VOO 16.895 is the park. There is no reconciliation-lag position.
- All 12 tranches are Strategy D, with no `convergence_target` and no `time_exit_date`, so **no exit is triggered**.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-27): unit 1.0578 vs peak 1.1065 (−4.40%). `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` are all FALSE.
  - **Refreshed on IBKR 10-28 closes**, the D book fell −0.22% ($542.92 → $541.72), which puts the unit at ≈1.0555 and the drawdown at **≈−4.61%**, against the −50% kill.
- **B:** no open position. The `analytics.b_pairwise_correlation` check is inert (n_positions 0).
- No other strategy holds positions. **No termination and no runaway review.** There is no open `interim_underperf_warning` alert to heal.

### Thesis-invalidation review

EDGAR submissions for the eight held issuers, accepted from 10-27 22:00Z: GEV 8-K (2.02) + 10-Q, GOOGL 8-K (2.02) + six Form 4s, ISRG one Form 4. None for AMZN, UBER, RTX, DIS or TSM. One wide news search covered all eight, so "none found" is not proof of none.
- **GEV** (-1.90% to 878.03). Q3 8-K Ex-99.1 accepted 06:16 ET (pre-open), fiscal Q3 2026:
  - **Total-company organic orders +96% YoY** ($29.3B), up from 71% last quarter and 88% at entry, and still disclosed in comparable form.
  - Backlog $197B (+$20B q/q); revenue $12.64B (+27%, +18% organic); guidance raised (revenue $46.5-47.5B, FCF $16-17B). It also raised its buyback to $20B and announced a $9.0B Trench Group acquisition.
  - The invalidation test (organic orders <15% for two consecutive quarters) is **not met**: 96% this quarter. The completion criteria are not met either: backlog is $197B (<$200B) and orders growth is not ≤25%.
  - The −1.9% close was attributed to worries about order cadence and slot reservations (IBD, CNBC; secondary). **UNBREACHED.**
- **GOOGL** (+1.34% on 10-28). Q3 8-K Ex-99.1 accepted **16:01 ET, after the close**; the anchor is 10-28 and it **reacts 10-29**, so no reaction is measured here.
  - **Google Cloud revenue $30.71B, +103% YoY**, with TPU systems sales a meaningful contributor. **Cloud operating margin 36.2%**, up from 35.6%.
  - Group revenue $127.6B (+25%). EPS $2.12 against about $3.01 expected, a miss driven by about $8.2B of other expense (investment losses). FCF −$9.06B on $51.4B capex. WSJ reports the stock >8% lower after hours (not measured).
  - Criteria: Cloud revenue <20% is no; Cloud margin contraction is no; RPO is not in the release and is **untestable until the 10-Q**; no structural remedy was seen; Cloud is still a reported segment. The TPU-systems mix inside Cloud revenue is worth watching for metric immutability. **UNBREACHED.**
- **AMZN** (+0.59%; Q3 10-29 after the close), **TSM** (+0.60%), **RTX** (+0.64%), **ISRG** (-0.38%), **DIS** (-1.08%) and **UBER** (-0.78%; Q3 date not company-confirmed, Nasdaq lists 11-04): no filing or news. All criteria are UNBREACHED or not testable this window.
- No price-level criterion is in play, so no dividend netting is owed.

**Watchlist candidacy:** the Strategy B new-entry index gains 44 names (below). No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** 44 own-event floor clearers are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only.
  - A thesis session would need to weigh the pattern of prior ≥5% sessions against criterion 4 (information vs sentiment) for SLS and AXTI (5 others each), CSGP, FLEX and UCTT (3 each).
  - ORCL's investor-day targets and VRT's beat-and-raise are mega-cap repricings, and their peers moved with them (neoclouds, AI power).
  - EDU is an ADS below the $10B line. SKHY's anchor is unresolved. LCII is deal-pinned.
- **C.** C stays HYBRID ACTIVATE (FOMC-only). The 10-28 FOMC resolved as a **hold at 3.75-4.00% (10-2, two hawkish dissents)**. Settling `thesis-FOMC-C-20261020` against that outcome is D2's job, not D1's. No new qualifying catalyst within 45 days was found.
- **A** (`DO-NOT-ACTIVATE`, div-A-202610-1): not a candidate.
- **E** (`DO-NOT-ACTIVATE`, div-E-202610-1). These intra-group divergences are recorded for M2, not routed:
  - freight: CHRW −11.1, ODFL −7.3 and LSTR −17.8 vs SAIA;
  - water: ZWS −11.5 dragging WTS and XYL vs HAYW +13.5 (pool);
  - memory: SNDK/MU up on SK hynix vs STX +4.5 after its own print.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `3212762d-20c6-4b69-b3b9-4eb0c9cee040`. All 12 open D tranches were evaluated, 0 were flagged and 0 were declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12, and positions were re-read immediately before the append. Each tranche is marked at its IBKR 10-28 close against its own cost per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +27.09% | none | declined |
| D:TSM:2026-07-29 | +11.87% | none | declined |
| D:RTX:2026-04-27 | +10.71% | none | declined |
| D:AMZN:2026-07-09 | +5.54% | none | declined |
| D:DIS:2026-08-05 | +5.06% | none | declined |
| D:TSM:2026-07-21 | +2.72% | none | declined |
| D:GOOGL:2026-07-26 | −0.90% | strengthened-conviction | declined: no funding path |
| D:DIS:2026-05-07 | −2.05% | dip-with-intact-thesis | declined: no funding path |
| D:AMZN:2026-07-30 | −4.18% | dip-with-intact-thesis | declined: no funding path; Q3 10-29 |
| D:GEV:2026-08-03 | −9.47% | strengthened-conviction | declined: no funding path; Q3 orders +96% |
| D:GOOGL:2026-07-09 | −9.71% | strengthened-conviction | declined: no funding path; Q3 Cloud +103% |
| D:UBER:2026-07-09 | −10.84% | dip-with-intact-thesis | declined: no funding path |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- **Technical side.** SPY closed at 772.31 (+0.34%), the VIX at 16.91, and breadth at 58.25 (D2a classifies them). The measured refresh triggers are D2's to detect.
- **FOMC.** A hold with two dissents for a hike is a monetary development that M1a/M1R score on `policy_stance` (already `hawkish`). It is not one of the two geopolitical triggers this check produces.
- **Geopolitical-trigger duty.**
  - The Houthi claim on Ras Tanura (10-27) is unconfirmed by Saudi Arabia, and it falls inside the standing `acute` overlay. A further event inside `acute` needs no scenario-3 flag.
  - The single-source report of a possible US strike after the midterms is a prospective statement, not a dated event.
  - **Mirror:** there is no ceasefire or settlement in force, no blockade lift and no sanctions settlement; the 10-26 talks produced nothing. That is not a `Qualifying resolution event`.
  - Israel's count is incomplete and domestic.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **58.25 for 2026-10-28**. The value is source-dated by Barchart `$S5TH`: "Quote Overview for Wed, Oct 28th, 2026", 58.25 −0.99 (−1.67%) stamped **17:05 ET**, so it is settled. Previous Close is 59.24, equal to the stored 10-27 value. O/H/L 57.05/58.64/56.26 is a real bar, not a carry and not an exact repeat. It was fetched via tavily_extract at about 22:08Z.
- **Single usable source.** EODData (curl) shows the same 58.25 at 17:05 ET, but Barchart and EODData are one feed in any case.
- **Independent check unconfirmed.** ChartRow reads 294 of 497 (59.16%), but its 200-day reading is dated Oct 27, one session behind (`chartrow_unconfirmed=session 2026-10-27`). Its 10-26 → 10-27 change of +1.21 matches `$S5TH`'s +1.19.
  - This is the second run in a row where ChartRow lagged at the D1 slot. It was reported through `sp_report_run_issue` (`breadth_chartrow_cross_check_unconfirmed`) with the evidence that would settle it.
- The direction is consistent with the tape: RSP −0.04 while SPY rose cap-led. No MacroMicro probe (Wednesday).

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The 44 eligible own-event floor clearers are indexed below instead. EDU (sub-$10B ADS), SKHY (anchor unresolved) and LCII (deal-pinned) are not indexed.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df` (a correction-replacement of `72e9607d`, which had two transcription defects in its metadata; no item changed).

- ADD **AXGN** (Strategy B, `qualifying_event_date` 2026-10-28) — +31.4736% (37.46 → 49.25); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only.
- ADD **GMAB** (Strategy B, `qualifying_event_date` 2026-10-28) — +28.2516% (44.67 → 57.29); clinical trial 6-K, pre-open/intraday 10-28; 2026-10-28 09:43 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **FFIV** (Strategy B, `qualifying_event_date` 2026-10-27) — -20.4262% (459.36 → 365.53); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:09 ET (EDGAR acceptance); index only.
- ADD **LSTR** (Strategy B, `qualifying_event_date` 2026-10-27) — -17.7628% (168.78 → 138.8); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:22 ET (EDGAR acceptance); index only.
- ADD **ICLR** (Strategy B, `qualifying_event_date` 2026-10-27) — +17.0401% (182.98 → 214.16); earnings 6-K, after close 10-27, reaction 10-28; 2026-10-27 16:46 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **VRT** (Strategy B, `qualifying_event_date` 2026-10-28) — +16.4845% (208.56 → 242.94); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:02 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **ENPH** (Strategy B, `qualifying_event_date` 2026-10-27) — -16.0282% (29.76 → 24.99); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only. 2 other ≥5% session(s) in the window.
- ADD **BLCO** (Strategy B, `qualifying_event_date` 2026-10-28) — +15.7775% (17.62 → 20.4); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:03 ET (EDGAR acceptance); index only.
- ADD **LPLA** (Strategy B, `qualifying_event_date` 2026-10-27) — -15.2318% (317.56 → 269.19); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:16 ET (EDGAR acceptance); index only.
- ADD **SLS** (Strategy B, `qualifying_event_date` 2026-10-28) — -14.7083% (12.17 → 10.38); issuer press release trial event, pre-open/intraday 10-28; 2026-10-28 ~08:35 ET (GlobeNewswire/StockTitan); index only. 5 other ≥5% session(s) in the window.
- ADD **CSGP** (Strategy B, `qualifying_event_date` 2026-10-27) — -13.9644% (32.01 → 27.54); earnings+acquisition 8-K 2.02/1.01/7.01, after close 10-27, reaction 10-28; 2026-10-27 16:05 ET (EDGAR acceptance); index only. 3 other ≥5% session(s) in the window.
- ADD **HAYW** (Strategy B, `qualifying_event_date` 2026-10-28) — +13.5073% (13.03 → 14.79); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **STLA** (Strategy B, `qualifying_event_date` 2026-10-28) — +13.0435% (4.14 → 4.68); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 11:07 ET (EDGAR acceptance); index only.
- ADD **DBD** (Strategy B, `qualifying_event_date` 2026-10-28) — -12.9124% (66.68 → 58.07); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:17 ET (EDGAR acceptance); index only.
- ADD **EVR** (Strategy B, `qualifying_event_date` 2026-10-28) — +12.5144% (259.86 → 292.38); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:45 ET (EDGAR acceptance); index only.
- ADD **OSW** (Strategy B, `qualifying_event_date` 2026-10-28) — +12.5050% (24.95 → 28.07); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only.
- ADD **EAT** (Strategy B, `qualifying_event_date` 2026-10-28) — +12.2102% (196.72 → 220.74); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:03 ET (EDGAR acceptance); index only.
- ADD **WING** (Strategy B, `qualifying_event_date` 2026-10-28) — +12.1843% (123.52 → 138.57); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:37 ET (EDGAR acceptance); index only. 2 other ≥5% session(s) in the window.
- ADD **LOGI** (Strategy B, `qualifying_event_date` 2026-10-27) — -12.1177% (111.82 → 98.27); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only.
- ADD **FLEX** (Strategy B, `qualifying_event_date` 2026-10-28) — +11.6137% (83.35 → 93.03); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:10 ET (EDGAR acceptance); index only. 3 other ≥5% session(s) in the window.
- ADD **ZWS** (Strategy B, `qualifying_event_date` 2026-10-27) — -11.4954% (49.15 → 43.5); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only.
- ADD **JLL** (Strategy B, `qualifying_event_date` 2026-10-28) — +11.1393% (299.93 → 333.34); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:33 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **CHRW** (Strategy B, `qualifying_event_date` 2026-10-28) — -11.1359% (143.59 → 127.6); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:03 ET (EDGAR acceptance); index only.
- ADD **ORCL** (Strategy B, `qualifying_event_date` 2026-10-28) — +10.7332% (130.53 → 144.54); investor day 8-K 7.01, pre-open/intraday 10-28; 2026-10-28 14:24 ET (EDGAR acceptance); index only.
- ADD **LII** (Strategy B, `qualifying_event_date` 2026-10-28) — -10.5927% (372.05 → 332.64); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:49 ET (EDGAR acceptance); index only.
- ADD **AXTI** (Strategy B, `qualifying_event_date` 2026-10-28) — +10.5616% (58.23 → 64.38); financing 8-K 1.01/7.01, pre-open/intraday 10-28; 2026-10-28 06:10 ET (EDGAR acceptance); index only. 5 other ≥5% session(s) in the window.
- ADD **LH** (Strategy B, `qualifying_event_date` 2026-10-28) — +8.7810% (331.17 → 360.25); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:57 ET (EDGAR acceptance); index only.
- ADD **MIR** (Strategy B, `qualifying_event_date` 2026-10-27) — +8.6957% (15.41 → 16.75); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:16 ET (EDGAR acceptance); index only.
- ADD **ENSG** (Strategy B, `qualifying_event_date` 2026-10-27) — +8.6195% (169.5 → 184.11); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:11 ET (EDGAR acceptance); index only.
- ADD **UCTT** (Strategy B, `qualifying_event_date` 2026-10-27) — +8.5470% (51.48 → 55.88); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only. 3 other ≥5% session(s) in the window.
- ADD **RUSHA** (Strategy B, `qualifying_event_date` 2026-10-27) — -8.3113% (45.48 → 41.7); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 17:28 ET (EDGAR acceptance); index only.
- ADD **TEX** (Strategy B, `qualifying_event_date` 2026-10-28) — +7.4275% (49.68 → 53.37); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only.
- ADD **BKR** (Strategy B, `qualifying_event_date` 2026-10-27) — -7.3559% (59.0 → 54.66); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 17:05 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **ODFL** (Strategy B, `qualifying_event_date` 2026-10-28) — -7.3304% (187.03 → 173.32); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:57 ET (EDGAR acceptance); index only.
- ADD **GEHC** (Strategy B, `qualifying_event_date` 2026-10-28) — +6.6235% (71.11 → 75.82); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:25 ET (EDGAR acceptance); index only.
- ADD **DAN** (Strategy B, `qualifying_event_date` 2026-10-28) — -6.3235% (27.2 → 25.48); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only.
- ADD **SAN** (Strategy B, `qualifying_event_date` 2026-10-28) — -6.2550% (12.47 → 11.69); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 06:22 ET (EDGAR acceptance); index only.
- ADD **NOV** (Strategy B, `qualifying_event_date` 2026-10-27) — -6.2287% (20.55 → 19.27); earnings 8-K 2.02, after close 10-27, reaction 10-28; press release dated 2026-10-27 per 8-K Item 2.02 (after close); 8-K accepted 2026-10-28 09:00 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **BSBR** (Strategy B, `qualifying_event_date` 2026-10-28) — -6.1983% (4.84 → 4.54); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 12:40 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **INTA** (Strategy B, `qualifying_event_date` 2026-10-27) — -6.0768% (42.95 → 40.34); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:17 ET (EDGAR acceptance); index only. 2 other ≥5% session(s) in the window.
- ADD **BSX** (Strategy B, `qualifying_event_date` 2026-10-28) — -5.8367% (45.06 → 42.43); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:34 ET (EDGAR acceptance); index only.
- ADD **GRMN** (Strategy B, `qualifying_event_date` 2026-10-28) — -5.8167% (289.34 → 272.51); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only.
- ADD **ETSY** (Strategy B, `qualifying_event_date` 2026-10-28) — +5.3502% (87.66 → 92.35); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:07 ET (EDGAR acceptance); index only. 1 other ≥5% session(s) in the window.
- ADD **SW** (Strategy B, `qualifying_event_date` 2026-10-28) — -5.1951% (42.54 → 40.33); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:39 ET (EDGAR acceptance); index only.

```yaml d1_actions
- action: watchlist
  ticker: AXGN
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +31.4736% (37.46 -> 49.25); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: GMAB
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +28.2516% (44.67 -> 57.29); clinical trial 6-K, pre-open/intraday 10-28; 2026-10-28 09:43 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: FFIV
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -20.4262% (459.36 -> 365.53); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:09 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: LSTR
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -17.7628% (168.78 -> 138.8); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:22 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: ICLR
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +17.0401% (182.98 -> 214.16); earnings 6-K, after close 10-27, reaction 10-28; 2026-10-27 16:46 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: VRT
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +16.4845% (208.56 -> 242.94); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:02 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: ENPH
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -16.0282% (29.76 -> 24.99); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: BLCO
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +15.7775% (17.62 -> 20.4); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:03 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: LPLA
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -15.2318% (317.56 -> 269.19); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:16 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: SLS
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -14.7083% (12.17 -> 10.38); issuer press release trial event, pre-open/intraday 10-28; 2026-10-28 ~08:35 ET (GlobeNewswire/StockTitan); index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: CSGP
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -13.9644% (32.01 -> 27.54); earnings+acquisition 8-K 2.02/1.01/7.01, after close 10-27, reaction 10-28; 2026-10-27 16:05 ET (EDGAR acceptance); index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: HAYW
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +13.5073% (13.03 -> 14.79); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: STLA
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +13.0435% (4.14 -> 4.68); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 11:07 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: DBD
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -12.9124% (66.68 -> 58.07); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:17 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: EVR
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +12.5144% (259.86 -> 292.38); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:45 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: OSW
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +12.5050% (24.95 -> 28.07); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: EAT
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +12.2102% (196.72 -> 220.74); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:03 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: WING
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +12.1843% (123.52 -> 138.57); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:37 ET (EDGAR acceptance); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: LOGI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -12.1177% (111.82 -> 98.27); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: FLEX
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +11.6137% (83.35 -> 93.03); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:10 ET (EDGAR acceptance); index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: ZWS
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -11.4954% (49.15 -> 43.5); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: JLL
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +11.1393% (299.93 -> 333.34); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:33 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: CHRW
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -11.1359% (143.59 -> 127.6); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:03 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: ORCL
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +10.7332% (130.53 -> 144.54); investor day 8-K 7.01, pre-open/intraday 10-28; 2026-10-28 14:24 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: LII
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -10.5927% (372.05 -> 332.64); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:49 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: AXTI
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +10.5616% (58.23 -> 64.38); financing 8-K 1.01/7.01, pre-open/intraday 10-28; 2026-10-28 06:10 ET (EDGAR acceptance); index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: LH
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +8.7810% (331.17 -> 360.25); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:57 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: MIR
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +8.6957% (15.41 -> 16.75); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:16 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: ENSG
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +8.6195% (169.5 -> 184.11); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:11 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: UCTT
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +8.5470% (51.48 -> 55.88); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:07 ET (EDGAR acceptance); index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: RUSHA
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -8.3113% (45.48 -> 41.7); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 17:28 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: TEX
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +7.4275% (49.68 -> 53.37); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:04 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: BKR
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -7.3559% (59.0 -> 54.66); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 17:05 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: ODFL
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -7.3304% (187.03 -> 173.32); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 08:57 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: GEHC
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +6.6235% (71.11 -> 75.82); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:25 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: DAN
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -6.3235% (27.2 -> 25.48); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: SAN
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -6.2550% (12.47 -> 11.69); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 06:22 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: NOV
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -6.2287% (20.55 -> 19.27); earnings 8-K 2.02, after close 10-27, reaction 10-28; press release dated 2026-10-27 per 8-K Item 2.02 (after close); 8-K accepted 2026-10-28 09:00 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: BSBR
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -6.1983% (4.84 -> 4.54); earnings 6-K, pre-open/intraday 10-28; 2026-10-28 12:40 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: INTA
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -6.0768% (42.95 -> 40.34); earnings 8-K 2.02, after close 10-27, reaction 10-28; 2026-10-27 16:17 ET (EDGAR acceptance); index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: BSX
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -5.8367% (45.06 -> 42.43); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:34 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: GRMN
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -5.8167% (289.34 -> 272.51); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:00 ET (EDGAR acceptance); index only
- action: watchlist
  ticker: ETSY
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — +5.3502% (87.66 -> 92.35); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 07:07 ET (EDGAR acceptance); index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: SW
  strategy: B
  qualifying_event_date: 2026-10-28
  source_research_screen_id: c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df
  detail: ADD to B new-entry index — -5.1951% (42.54 -> 40.33); earnings 8-K 2.02, pre-open/intraday 10-28; 2026-10-28 06:39 ET (EDGAR acceptance); index only
```

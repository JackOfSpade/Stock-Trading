2026-10-27
<!-- d1_scan_through_utc: 2026-10-27T22:10:00Z -->

# Daily Market Development Scan — session 2026-10-27 (Tue)

Scan window: 2026-10-26 16:30 MT → 2026-10-27 16:10 MT (~23.7h). The start is the prior `Daily.md` marker `2026-10-26T22:30:00Z`, and that file's commit (22:28Z) agrees; `state.routine_catchup_window` gives 0.98 days. The window holds **one completed US session, Tuesday 2026-10-27**. Moves are 10-26 → 10-27 close-to-close on IBKR regular-session daily bars.

Tape: **a second, narrower AI-led up day, with oil and energy lower and a heavy earnings slate.**
- **Indices.** IBKR closes, 10-26 → 10-27: SPY 765.37 → **769.66 (+0.5605%)**, QQQ +1.2707%, IWM +1.1517%, DIA +0.0593%, **RSP +0.1058%**, **SMH +3.0206%**. Leadership was cap-weighted, and equal-weight barely moved.
- **Volatility.** The VIX fell 18.39 → 17.52 (−4.73%; IBKR CBOE bar, delayed feed).
- **Rates and dollar.** FMP par yields: 2Y 4.70 (from 4.68), 10Y 4.99 (from 5.00), 30Y 5.30. TLT −0.06%, HYG +0.52%. The dollar was described as firm; no level was confirmed.
- **Oil.** Brent December **settled $113.88** on 10-27, down from **$115.81** on 10-26; WTI December $99.90 from $101.76 (DTN/Rigzone; FMP Brent EOD agrees at 113.88). The two-session fall from the 10-23 settles (116.72 / 103.27) is −$2.84 Brent and −$3.37 WTI. Brent December expires 10-30, and January trades about $5 lower. USO −1.41%.
- **Gold and crypto.** GLD +1.21% (gold about $4,027). BTC about $80.8k (+1.0%, FMP).
- **Leadership.** XLK +1.70 led and XLE −2.05 lagged. Breadth rose to **59.24** (from 58.05).

## TL;DR

- **Exits triggered: none.** Twelve Strategy D tranches carry no mechanical trigger, and no Development meets a thesis-invalidation criterion. No held name filed an 8-K, 6-K or 10-Q in the window (TSM only a passive 13G).
- **New entry candidates: none routed.** 33 names cleared Strategy B's frozen ≥5% floor on their own issuer events, nearly all on earnings, led by HRI, KNSA, CTOS, XYL, HWKN, SOFI, PNR, ABG, CLS and BA. B is `DO-NOT-ACTIVATE` and capital-disabled, so they go to the index only. UNF and INOD are recorded but not routed.
- **Add candidates: none (0 of 12).** Six D tranches read dip-with-intact-thesis, but D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 33 changes.** ADD the 33 names to the Strategy B new-entry index.
- **Regime review: no review.** There was no new qualifying shock and no qualifying resolution: the Tehran talks agreed only to keep talking, the blockade and Houthi attacks continue, and Israel's election is a domestic deadlock.

Park: VOO-only pin verified

Paper book (J): 120 calls, 62/30 realized, net_mu -1.06%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Gulf (still no resolution).**
  - On 10-26, Saudi, Pakistani and Turkish officials met Iran's president in Tehran and agreed to keep talking, with no date or terms. The US blockade of Iranian ports continues.
  - Houthi drones are still hitting Saudi Arabia, and a fire near Ras Tanura was contained. October is the worst month for Hormuz shipping attacks since 2017.
  - Trump called it "decision time" and said strikes could resume after the Israeli vote or the 11-03 midterms. A WSJ headline that Oman says talks outline a plan to open Hormuz is unconfirmed (paywalled), and reports conflict on Hormuz flows.
  - Oil fell on the talks narrative (Brent −1.7%), and refiners repriced −7% to −10%.
- **Israel election (10-27).** Exit polls (Axios, 20:08Z) give the Eisenkot bloc 52-53 seats and Netanyahu's bloc 50, with Arab parties at 17-18. Neither reaches 61, and Reuters calls it a deadlock. Official results are unconfirmed, and no market reaction is observable yet.
- **AI rally, day two.** The Anthropic S-1 (made public 10-26) kept the AI-chip, optical and server cohort bid: SMH +3.02%, and 46 ≥$2B cohort names moved ≥5%.
- **Brazil.** Brazilian assets partly recovered on 10-27 after Monday's election crash (closing levels unconfirmed). This is domestic politics, not a geopolitical or trade channel.
- **Trade and Russia.** The US and Canada are working on easing steel and auto tariffs (Reuters via ZeroHedge), with nothing concluded. US-Russia-Ukraine talks are planned in the UAE next month, with no settlement.
- **Antitrust.** Semafor reported the FTC will sue to block Cintas's $5.5B acquisition of UniFirst: UNF −10.46%, CTAS −4.93%.
- **Not found** in this window: China, shutdown, bankruptcy or disaster news. That absence comes from thin searches and is not a measured absence.

### 2. Scheduled events that resolved in the window

- **Enumeration.** I fetched the Nasdaq key-less calendar for 10-26, 10-27 and 10-28 with curl: 111 issuers of $2B or more were scheduled on 10-27, and 35 on 10-26. Release times come from EDGAR acceptance stamps. Consensus figures are the Nasdaq calendar's (secondary).
- **Macro (10-27).** Conference Board consumer confidence was **91.7** against 81.0 expected (Proactive Investors; secondary). Durable goods, new home sales and Richmond Fed actuals were not confirmed. The FOMC (10-28, 14:00 ET) is expected to hold at 3.75-4.00%, and markets price about 73-81% odds of a December hike.
- **10-26 after-close reporters, which reacted on 10-27.** All were accepted at 16:01-18:21 ET on 10-26, before this window opened, except CNC (19:05 ET). The ones that moved ≥5% are written up in §3: CTOS, HWKN, CLS (Q3 $3.30 vs $2.89, raised, initial 2027 revenue outlook about $40B), AMKR ($0.76 vs $0.79), CDNS ($2.11, raised), AGYS, WELL, ARE, SSD, PII, NUE, NE, PPTA (an Army tungsten agreement, not earnings) and BRO (−4.97%, below the floor). CNC posted $0.58 vs $0.07 and raised guidance.
- **10-27 pre-open reporters (46).** Outcomes from the Ex-99.1 releases (adjusted EPS vs secondary consensus):
  - **Beats:** IQV $3.34 vs $2.94 (raised); HCA $7.22 vs $6.74; PYPL $1.45 vs $1.31 (raised); RCL $6.57 vs $6.38 (raised); NVS core $2.46 vs $2.25 (raised core operating income guidance); KO $0.91 vs $0.87 (raised); JCI $1.66 vs $1.58 (FY27 EPS guide $6.15-6.30); UPS $1.69 vs $1.63 (raised); HLT $2.45 vs $2.36.
  - **Misses and in-line:** BA core loss −$0.34 a share (GAAP −$0.26 vs −$0.21 expected), −10.69%; SHW $3.63 vs $3.65 (guidance narrowed); ECL $2.18, in line; ITW $3.00 vs $2.99 (raised); PCAR $1.61, in line.
  - **Corporate:** SPGI began a strategic review of Capital IQ and its data businesses. GWRE agreed to buy Hyperexponential for $1.7B cash (8-K 07:05 ET), and GM is moving its listing from NYSE to Nasdaq (8-K 06:30 ET).
  - **HSBC:** Q3 profit before tax of $9.6B, with targets reaffirmed. Its 6-K was accepted at 12:27 ET, and the London-hours release minute is unresolved.
- **10-27 after-close reporters (57 of $2B or more, accepted 16:02-17:28 ET).** They react on 10-28 and are not measured here.
  - V $3.48 vs $3.43, dividend +16%; STX $7.68 vs $7.17, FQ2 EPS guide $9.20; NXPI $4.20 vs $3.78 plus a $5B buyback; WM $2.15 vs $2.18, guidance affirmed; HOOD adjusted $0.60 (a new measure; GAAP $0.51), consensus basis ambiguous; OKE raised; BKR $0.70 vs $0.63, raised its IET orders guide to $50B+; VTR raised; ACGL operating $2.67 vs $2.15; EQT $0.42 vs $0.38.
  - Also reporting: EXR, FE, FFIV, LPLA, PPG, EXE, ESS, LOGI, WPC, RNR (Q3 net loss of $161M), ICLR, MANH, CSGP (buying Vexcel), CR, UHS, ENSG, UMBF, BXP, ZWS, STAG, CHE, EXLS, ST, CZR, LSTR, CAKE, RUSHA/B, AKO.A/B, ENPH, RNST, MIR, INTA, FFBC, SLDE (special dividend $1.50), SBCF, BANC, NBTB, APAM, TRMK, BUSE, NTB, IVT, ROG, UCTT.
  - **TER** released on Business Wire after 16:30 ET (revenue $1,306M), but no EDGAR 8-K was visible yet, so its figures are third-party.
- **Unresolved** (no 8-K/6-K Ex-99.1 on EDGAR through 22:14Z): RRC and HIW (10-Qs filed, no release found), NOV, FCF, MCRI, SEB, KAI, SIM, PKX, CX, MMYT.
- **Pending.**
  - 10-28: **GEV pre-open**; the **FOMC at 14:00 ET**; **GOOGL** after the close.
  - 10-29: Q3 GDP, September PCE, the ECB, and **AMZN** after the close.
  - 10-30: the BoJ.
  - UBER's date is not company-confirmed (Nasdaq lists 11-04 pre-open). The midterms are 11-03.
- **FDA.** CDER's Novel Drug Approvals 2026 page (fetched about 22:12Z) has its newest entry, #47 Hibsago, on 10-20, and the press page ends at 10-22. So there was no novel approval on 10-26 or 10-27. CRLs and supplemental approvals could not be resolved from those pages and are recorded as unresolved, not as a measured absence.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `3b0ca8cf-58a6-4193-90d0-355368d80aad` (`surfaced_count` 37 = `ARRAY_LENGTH(passed)`: 35 floor clearers plus CTAS and BRO below the floor; agreement both 35 / ai_only 2 / rule_only 151). Every written-up figure is an IBKR regular-session daily-bar close-to-close (close array), 10-26 → 10-27.

- **Discovery (unmetered).** The Nasdaq screener's `pctchange` was stale (10-26 values). So 10-27 closes came from Nasdaq quote/info ("Closed at Oct 27, 2026 4:00 PM ET") for **1,934 of 1,945** ≥$2B US stocks and ADRs. **697 moved ≥2% and 186 moved ≥5%.** Eleven were unmeasured: CCZ, GJS and WLYB failed to fetch, and BATRA, CCC, CHYM, GDS, HLNE, PLBL, RDY and TBB returned a blank change.
- **Attribution.** EDGAR 8-K/6-K filings were pulled for all 186 ≥5% names and for the ≥2% reporters. There were 11 cluster-level searches, and the 2-5% non-reporters were not individually attributed (`selection_rule`). `rail_tally` 62 is a lower bound.
- **Fan-out reconciliation.** The screen leg and the EDGAR scheduled-events leg were compared by (ticker, event date) on every overlapping name, and they agree. EDGAR acceptance stamps are the tiebreak. Two corrections came from that pass: GWRE −8.05% is an acquisition, not an earnings reaction, and GM +5.54% is a listing transfer.
- **Close-chain check.** No CHAIN HIT and no same-name, same-anchor earlier disposition. Coverage is limited, so a clean pass is not a clearance.
- **Market cap near the rail.** CTOS and PPTA were re-derived from 10-Q cover share counts. CTOS has 227,173,348 shares (cover as of 2026-10-22), worth $2.05B at its 10-26 close. PPTA has 125,095,803 shares (cover as of 2026-08-05), worth $2.08B. Both clear $2B.

| Ticker | Move (close → close) | Release and anchor | Conv. | Notes |
|---|---|---|---|---|
| **HRI** | +22.7562% (127.13 → 156.06) | pre-open 10-27, 8-K 06:31 ET; anchor 10-27 | 75 | Q3; 1 other ≥5% session |
| **KNSA** | +22.2253% (72.98 → 89.20) | pre-open 10-27, 8-K 07:32 ET; anchor 10-27 | 75 | Q3; 1 other ≥5% session |
| **XYL** | −14.2092% (108.24 → 92.86) | pre-open 10-27, 8-K 07:01 ET; anchor 10-27 | 75 | Q3 plus strategic actions and an officer change (Item 5.02) |
| **SOFI** | +13.4163% (14.46 → 16.40) | pre-open 10-27, 8-K 07:02 ET; anchor 10-27 | 75 | Q3; 2 other ≥5% sessions |
| **BA** | −10.6898% (188.31 → 168.18) | pre-open 10-27, 8-K 07:30 ET; anchor 10-27 | 75 | Q3 core loss −$0.34 a share |
| **CTOS** | +16.6482% (9.01 → 10.51) | after-close 10-26, 8-K 16:13 ET; anchor 10-26, reaction 10-27 | 60 | Q3; cap $2.05B on the filed share count |
| **HWKN** | +13.5927% (135.44 → 153.85) | after-close 10-26, 8-K 16:13 ET; anchor 10-26, reaction 10-27 | 60 | FQ2 |
| **PNR** | +12.8033% (55.22 → 62.29) | pre-open 10-27, 8-K 06:51 ET; anchor 10-27 | 60 | Q3 |
| **ABG** | +12.7370% (172.96 → 194.99) | pre-open 10-27, 8-K 07:02 ET; anchor 10-27 | 60 | Q3 |
| **CLS** | +12.1184% (246.65 → 276.54) | after-close 10-26, 8-K 16:23 ET; anchor 10-26, reaction 10-27 | 60 | Q3 beat, raise, 2027 outlook; 3 other ≥5% sessions |
| **PPTA** | +10.6627% (16.60 → 18.37) | after-close 10-26, 8-K 17:30 ET; anchor 10-26, reaction 10-27 | 45 | Army tungsten agreement; 3 other ≥5% sessions |
| **GLXY** | +9.5663% (15.68 → 17.18) | pre-open 10-27, 8-K 07:04 ET; anchor 10-27 | 45 | Q3; 5 other ≥5% sessions |
| **LECO** | +9.1707% (258.65 → 282.37) | pre-open 10-27, 8-K 09:03 ET; anchor 10-27 | 60 | Q3 |
| **AMKR** | +8.5031% (36.81 → 39.94) | after-close 10-26, 8-K 16:07 ET; anchor 10-26, reaction 10-27 | 45 | Q3 miss, inside the semis bid; 4 other ≥5% sessions |
| **AIT** | −8.3467% (324.68 → 297.58) | 8-K 09:31 ET 10-27 (at the open); anchor 10-27 | 60 | FQ1 |
| **GWRE** | −8.0507% (183.96 → 169.15) | pre-open 10-27, 8-K 07:05 ET; anchor 10-27 | 60 | $1.7B cash acquisition of Hyperexponential |
| **ITRI** | +7.7739% (87.73 → 94.55) | pre-open 10-27, 8-K 08:35 ET; anchor 10-27 | 60 | Q3 |
| **EEFT** | −7.7248% (63.95 → 59.01) | pre-open 10-27, 8-K 08:15 ET; anchor 10-27 | 60 | Q3 |
| **CDNS** | +6.4904% (322.17 → 343.08) | after-close 10-26, 8-K 16:03 ET; anchor 10-26, reaction 10-27 | 60 | Q3, raised |
| **AGYS** | −6.1887% (123.45 → 115.81) | after-close 10-26, 8-K 16:05 ET; anchor 10-26, reaction 10-27 | 45 | FQ2 |
| **ARE** | −5.8525% (43.40 → 40.86) | after-close 10-26, 8-K 16:08 ET; anchor 10-26, reaction 10-27 | 45 | Q3 |
| **WELL** | −5.7728% (240.61 → 226.72) | after-close 10-26, 8-K 16:33 ET; anchor 10-26, reaction 10-27 | 60 | Q3; rare for a $173B REIT |
| **AWI** | −5.7396% (164.82 → 155.36) | pre-open 10-27, 8-K 06:00 ET; anchor 10-27 | 45 | Q3 |
| **HSBC** | −5.7011% (91.21 → 86.01) | London-hours release 10-27 (6-K 12:27 ET, minute unresolved); anchor 10-27 | 45 | Q3 PBT $9.6B |
| **JCI** | +5.6814% (147.50 → 155.88) | pre-open 10-27, 8-K 06:58 ET; anchor 10-27 | 45 | FQ4, FY27 guide |
| **GM** | +5.5432% (76.31 → 80.54) | pre-open 10-27, 8-K 06:30 ET; anchor 10-27 | 45 | NYSE-to-Nasdaq listing transfer (index-eligibility expectation) |
| **HUBB** | −5.4680% (459.40 → 434.28) | pre-open 10-27, 8-K 08:05 ET; anchor 10-27 | 45 | Q3 |
| **RCL** | +5.4597% (280.60 → 295.92) | pre-open 10-27, 8-K 06:32 ET; anchor 10-27 | 45 | Q3 beat, raised |
| **NE** | −5.4173% (47.81 → 45.22) | after-close 10-26, 8-K 17:03 ET; anchor 10-26, reaction 10-27 | 30 | Q3; gives back +8.5% from 10-23 |
| **SSD** | +5.3135% (181.99 → 191.66) | after-close 10-26, 8-K 16:18 ET; anchor 10-26, reaction 10-27 | 45 | Q3; IBKR basis (Nasdaq read +5.85%) |
| **PII** | +5.2765% (55.15 → 58.06) | after-close 10-26, 8-K 18:21 ET; anchor 10-26, reaction 10-27 | 45 | Q3 |
| **TRU** | −5.2751% (79.62 → 75.42) | pre-open 10-27, 8-K 06:15 ET; anchor 10-27 | 30 | Q3; 3 other ≥5% sessions |
| **NUE** | +5.2225% (257.35 → 270.79) | after-close 10-26, 8-K 16:54 ET; anchor 10-26, reaction 10-27 | 30 | Q3 |
| UNF | −10.4563% (279.64 → 250.40) | Semafor report 10-27, minute unresolved; anchor 10-27 | 60 | FTC suit to block the Cintas merger; merger-pinned, **not routed** |
| INOD | −25.3213% (59.91 → 44.74) | press reports 10-27, minute unresolved; anchor 10-27 | 45 | About 550 layoffs reported, with no company filing; **not routed** |
| CTAS | −4.9263% (225.93 → 214.80) | same Semafor report | 30 | Acquirer side; below the floor, context only |
| BRO | −4.9662% (71.08 → 67.55) | after-close 10-26, 8-K 17:03 ET | 30 | Q3 organic growth 1.2%; below the floor, context only |

- **Rejected or common driver** (Nasdaq basis unless noted; 151 names, each listed in the row):
  - **AI-chip, optical, neocloud and server cohort (46)**, on the Anthropic S-1 aftermath.
  - **Biotech sector beta (19)**; nuclear, uranium and AI-power (16); critical minerals (13); space and eVTOL rebound (11); crypto miners (7); quantum (4); fintech sympathy with SOFI (3).
  - **Refiners −7% to −10% (8)**: VLO, MPC, PSX, DK, PARR, PBF, CVI, DINO, on lower oil.
  - **10-27 after-close reporters whose move came before the release**: UCTT +10.2, INTA −8.9, BKR +5.3, CSGP −5.0.
  - **Continuations of 10-26 events**: ORKA, RRC (EQT merger pin), STM, RHI.
  - **15 unattributed** idiosyncratic ≥5% moves with no EDGAR filing and no search. This is limited search, not proof of absence.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` `56a602d2-cb78-475c-a5c7-c38cd833e3f1` (`surfaced_count` 3). Registry contract ids were used, the guard 10-26 closes matched the prior run (XLK 186.32, XLC 103.85, XLI 166.96, XLY 114.26), and every bar is stamped 2026-10-27.

- **XLE −2.0534%** (69.64 → 68.21), conviction 45, `legacy_rule_pass=true`. Crude fell (Brent December settled 113.88 on 10-27, from 115.81 on 10-26) and refiners repriced −7% to −10%.
- **XLK +1.7014%** (186.32 → 189.49), conviction 45: the second day of the AI and semis bid after the Anthropic S-1 (SMH +3.02%). With equal-weight RSP at only +0.11%, leadership was narrow.
- **XLY +1.0415%** (114.26 → 115.45), conviction 30: AMZN +1.61% and RCL +5.46% carry the cap-weighted ETF.
- **Under 1%, not surfaced:** XLB +0.78, XLU +0.71, XLI +0.58, XLV −0.06, XLF −0.25, XLC −0.26, XLRE −0.84, XLP −0.92.

### 5. Notable commentary

- The dedicated strategist search returned nothing. BofA, Capital.com and BNY were quoted only in passing in wraps, with nothing market-moving.
- The Fed is in blackout before the 10-28 FOMC. No sell-side notes on held names were captured.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- I swept the union of `state.current_positions` (12 tranches, re-read before the appends and unchanged) and IBKR `get_account_positions`, and they agree on every name:
  - AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156.
  - VOO 16.895 is the park (it was 17.7307 in the prior run's sweep; that reconciliation is D2a's, not D1's). There is no reconciliation-lag position.
- All 12 tranches are Strategy D, with no `convergence_target` and no `time_exit_date`, so **no exit is triggered**.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-26): unit 1.0423 vs peak 1.1065 (−5.79%). `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` are all FALSE.
  - **Refreshed on IBKR 10-27 closes**, the D book rose +1.47% ($535.04 → $542.92), which puts the unit at ≈1.0577 and the drawdown at **≈−4.41%**, against the −50% kill.
- **B:** no open position. The `analytics.b_pairwise_correlation` check is inert (n_positions 0).
- No other strategy holds positions. **No termination and no runaway review.** There is no open `interim_underperf_warning` alert to heal.

### Thesis-invalidation review

EDGAR shows no 8-K, 6-K or 10-Q from any of the eight held names in the window. TSM filed only a passive SCHEDULE 13G at 20:21Z. Web coverage was two wide searches, so "none found" is not proof of none.
- **GEV** (+4.67% to 895.08): Q3 is **10-28 pre-open** (consensus EPS about $3.97-3.99 on $11.99B revenue). The orders criterion needs two consecutive quarters, so one print cannot trip it. UNBREACHED.
- **RTX** (−1.46%): the only news was a $100M Pratt & Whitney Poland plant announcement. UNBREACHED.
- **GOOGL** (+1.19%, Q3 10-28 after the close), **AMZN** (+1.61%, Q3 10-29 after the close), **TSM** (+2.95%), **ISRG** (−1.27%), **DIS** (−0.15%; the Skydance chatter concerns SKYD, not DIS) and **UBER** (−0.53%; Q3 date not company-confirmed, Nasdaq lists 11-04): no news. All criteria are UNBREACHED or not testable this window.

**Watchlist candidacy:** the Strategy B new-entry index gains 33 names (below). No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** 33 own-event floor clearers are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only.
  - A thesis session would need to weigh the pattern of prior ≥5% sessions against criterion 4 (information vs sentiment) for GLXY (5 others), AMKR (4), CLS, PPTA and TRU (3 each).
  - GM's move is a listing-venue change and GWRE's is an acquirer reaction. Both are weak information-repricing cases.
  - UNF (merger-pinned) and INOD (unconfirmed press report, no filing) are not indexed.
- **C.** Strategy C stays HYBRID ACTIVATE (FOMC-only). The 10-28 FOMC is already gated under `thesis-FOMC-C-20261020`. No new qualifying catalyst within 45 days was found.
- **A** (`DO-NOT-ACTIVATE`, div-A-202610-1): not a candidate.
- **E** (`DO-NOT-ACTIVATE`, div-E-202610-1). These intra-group divergences are recorded for M2, not routed:
  - water: XYL −14.2 vs PNR +12.8 (both on own earnings);
  - uniforms: UNF −10.5 vs CTAS −4.9 (deal risk);
  - refiners −7% to −10% vs XLE −2.05 (upstream).

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `3584fad9-c720-443c-8f62-f95a71fe49c2`. All 12 open D tranches were evaluated, 0 were flagged and 0 were declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12, and positions were re-read immediately before the append. Each tranche is marked at its IBKR 10-27 close against its own cost basis per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +27.57% | none | declined |
| D:TSM:2026-07-29 | +11.20% | none | declined |
| D:RTX:2026-04-27 | +10.01% | none | declined |
| D:DIS:2026-08-05 | +6.21% | none | declined |
| D:AMZN:2026-07-09 | +4.91% | none | declined |
| D:TSM:2026-07-21 | +2.11% | none | declined |
| D:DIS:2026-05-07 | −0.98% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-26 | −2.22% | dip-with-intact-thesis | declined: no funding path |
| D:AMZN:2026-07-30 | −4.74% | dip-with-intact-thesis | declined: no funding path |
| D:GEV:2026-08-03 | −7.71% | dip-with-intact-thesis | declined: no funding path; Q3 10-28 |
| D:UBER:2026-07-09 | −10.15% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-09 | −10.91% | dip-with-intact-thesis | declined: no funding path |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- **Technical side.** SPY closed at 769.66 (+0.56%), the VIX at 17.52, and breadth at 59.24 (D2a classifies them). The measured refresh triggers are D2's to detect.
- **Geopolitical-trigger duty.**
  - Houthi strikes on Saudi Arabia continue inside the standing `acute` overlay, so no scenario-3 escalation flag is owed.
  - **Mirror:** the 10-26 Tehran meeting only agreed to keep talking. There is no ceasefire in force, the blockade is not lifted, attacks continue, and there is no sanctions settlement. That is narrative de-escalation, not a `Qualifying resolution event`. Brent's two-session fall of −$2.84 is attributed to the talks narrative.
  - Israel's election deadlock is domestic politics and not a named geopolitical or trade channel.
- No other Development plausibly shifts any strategy's activation state.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **59.24 for 2026-10-27**. The value is source-dated by Barchart `$S5TH`: "Quote Overview for Tue, Oct 27th, 2026", 59.24 +1.19 (+2.05%) stamped **16:56 ET**, so it is settled. Previous Close is 58.05, equal to the stored 10-26 value. O/H/L 58.84/59.44/57.05 is a real bar, not a carry. It was fetched via tavily_extract at about 22:08Z.

- **Single usable source.** EODData read 59.44 stamped 15:55 ET, with Close equal to High. That is an unsettled running print (`eoddata_unsettled_at_fetch=15:55 ET`), 0.20pp from Barchart, and it was not used. Barchart and EODData are one feed in any case.
- **Independent check unconfirmed.** ChartRow still dates its 200-day count to Oct 26 (288 of 497, unchanged), so it neither confirms nor refutes (`chartrow_unconfirmed=session 2026-10-26`). This was reported through `sp_report_run_issue` (`breadth_chartrow_cross_check_unconfirmed`). The direction is consistent with the tape (QQQ +1.28, IWM +1.15).
- No MacroMicro probe (Tuesday). Not an exact repeat.

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The 33 eligible own-event floor clearers are indexed below instead. UNF (merger-pinned) and INOD (unconfirmed press report) are not indexed.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `3b0ca8cf-58a6-4193-90d0-355368d80aad`.

- ADD **HRI** (Strategy B, `qualifying_event_date` 2026-10-27) — +22.7562% (127.13 → 156.06); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:31 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **KNSA** (Strategy B, `qualifying_event_date` 2026-10-27) — +22.2253% (72.98 → 89.2); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:32 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **CTOS** (Strategy B, `qualifying_event_date` 2026-10-26) — +16.6482% (9.01 → 10.51); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:13 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **XYL** (Strategy B, `qualifying_event_date` 2026-10-27) — -14.2092% (108.24 → 92.86); Q3 earnings + strategic actions (8-K 2.02/5.02), pre-open; 8-K accepted 2026-10-27 07:01 ET; index only.
- ADD **HWKN** (Strategy B, `qualifying_event_date` 2026-10-26) — +13.5927% (135.44 → 153.85); FQ2 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:13 ET, reaction 2026-10-27; index only.
- ADD **SOFI** (Strategy B, `qualifying_event_date` 2026-10-27) — +13.4163% (14.46 → 16.4); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:02 ET; index only. 2 other ≥5% session(s) in the window.
- ADD **PNR** (Strategy B, `qualifying_event_date` 2026-10-27) — +12.8033% (55.22 → 62.29); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:51 ET; index only.
- ADD **ABG** (Strategy B, `qualifying_event_date` 2026-10-27) — +12.7370% (172.96 → 194.99); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:02 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **CLS** (Strategy B, `qualifying_event_date` 2026-10-26) — +12.1184% (246.65 → 276.54); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:23 ET, reaction 2026-10-27; index only. 3 other ≥5% session(s) in the window.
- ADD **BA** (Strategy B, `qualifying_event_date` 2026-10-27) — -10.6898% (188.31 → 168.18); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:30 ET; index only.
- ADD **PPTA** (Strategy B, `qualifying_event_date` 2026-10-26) — +10.6627% (16.6 → 18.37); US Army tungsten OTIA agreement + warrant extension (8-K 8.01/3.02), 8-K accepted 17:30 ET 10-26; 8-K accepted 2026-10-26 17:30 ET, reaction 2026-10-27; index only. 3 other ≥5% session(s) in the window.
- ADD **GLXY** (Strategy B, `qualifying_event_date` 2026-10-27) — +9.5663% (15.68 → 17.18); Q3 earnings (8-K 2.02/7.01), pre-open; 8-K accepted 2026-10-27 07:04 ET; index only. 5 other ≥5% session(s) in the window.
- ADD **LECO** (Strategy B, `qualifying_event_date` 2026-10-27) — +9.1707% (258.65 → 282.37); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 09:03 ET; index only.
- ADD **AMKR** (Strategy B, `qualifying_event_date` 2026-10-26) — +8.5031% (36.81 → 39.94); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:07 ET, reaction 2026-10-27; index only. 4 other ≥5% session(s) in the window.
- ADD **AIT** (Strategy B, `qualifying_event_date` 2026-10-27) — -8.3467% (324.68 → 297.58); FQ1 earnings (8-K 2.02), 8-K accepted 09:31 ET; 8-K accepted 2026-10-27 09:31 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **GWRE** (Strategy B, `qualifying_event_date` 2026-10-27) — -8.0507% (183.96 → 169.15); Acquisition of Hyperexponential Ltd for $1.7B cash + up to $400M contingent (8-K 1.01/2.03/7.01), pre-open; 8-K accepted 2026-10-27 07:05 ET; index only. 2 other ≥5% session(s) in the window.
- ADD **ITRI** (Strategy B, `qualifying_event_date` 2026-10-27) — +7.7739% (87.73 → 94.55); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:35 ET; index only.
- ADD **EEFT** (Strategy B, `qualifying_event_date` 2026-10-27) — -7.7248% (63.95 → 59.01); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:15 ET; index only.
- ADD **CDNS** (Strategy B, `qualifying_event_date` 2026-10-26) — +6.4904% (322.17 → 343.08); Q3 earnings (8-K 2.02/8.01), after-close 10-26; 8-K accepted 2026-10-26 16:03 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **AGYS** (Strategy B, `qualifying_event_date` 2026-10-26) — -6.1887% (123.45 → 115.81); FQ2 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:05 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **ARE** (Strategy B, `qualifying_event_date` 2026-10-26) — -5.8525% (43.4 → 40.86); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:08 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **WELL** (Strategy B, `qualifying_event_date` 2026-10-26) — -5.7728% (240.61 → 226.72); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:33 ET, reaction 2026-10-27; index only.
- ADD **AWI** (Strategy B, `qualifying_event_date` 2026-10-27) — -5.7396% (164.82 → 155.36); Q3 earnings (8-K 2.02/7.01), 06:00 ET; 8-K accepted 2026-10-27 06:00 ET; index only.
- ADD **HSBC** (Strategy B, `qualifying_event_date` 2026-10-27) — -5.7011% (91.21 → 86.01); Q3 earnings (6-K), UK-hours release; 6-K accepted 2026-10-27 12:27 ET; index only.
- ADD **JCI** (Strategy B, `qualifying_event_date` 2026-10-27) — +5.6814% (147.5 → 155.88); FQ4 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:58 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **GM** (Strategy B, `qualifying_event_date` 2026-10-27) — +5.5432% (76.31 → 80.54); Exchange transfer NYSE to Nasdaq (8-K 3.01/5.03/7.01), pre-open; 8-K accepted 2026-10-27 06:30 ET; index only. 1 other ≥5% session(s) in the window.
- ADD **HUBB** (Strategy B, `qualifying_event_date` 2026-10-27) — -5.4680% (459.4 → 434.28); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:05 ET; index only.
- ADD **RCL** (Strategy B, `qualifying_event_date` 2026-10-27) — +5.4597% (280.6 → 295.92); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:32 ET; index only.
- ADD **NE** (Strategy B, `qualifying_event_date` 2026-10-26) — -5.4173% (47.81 → 45.22); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 17:03 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **SSD** (Strategy B, `qualifying_event_date` 2026-10-26) — +5.3135% (181.99 → 191.66); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:18 ET, reaction 2026-10-27; index only.
- ADD **PII** (Strategy B, `qualifying_event_date` 2026-10-26) — +5.2765% (55.15 → 58.06); Q3 earnings (8-K 2.02), after-close 10-26 (8-K 18:21 ET); 8-K accepted 2026-10-26 18:21 ET, reaction 2026-10-27; index only. 1 other ≥5% session(s) in the window.
- ADD **TRU** (Strategy B, `qualifying_event_date` 2026-10-27) — -5.2751% (79.62 → 75.42); Q3 earnings (8-K 2.02/7.01), pre-open; 8-K accepted 2026-10-27 06:15 ET; index only. 3 other ≥5% session(s) in the window.
- ADD **NUE** (Strategy B, `qualifying_event_date` 2026-10-26) — +5.2225% (257.35 → 270.79); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:54 ET, reaction 2026-10-27; index only.

```yaml d1_actions
- action: watchlist
  ticker: HRI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +22.7562% (127.13 -> 156.06); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:31 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: KNSA
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +22.2253% (72.98 -> 89.2); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:32 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: CTOS
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +16.6482% (9.01 -> 10.51); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:13 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: XYL
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -14.2092% (108.24 -> 92.86); Q3 earnings + strategic actions (8-K 2.02/5.02), pre-open; 8-K accepted 2026-10-27 07:01 ET; index only
- action: watchlist
  ticker: HWKN
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +13.5927% (135.44 -> 153.85); FQ2 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:13 ET, reaction 2026-10-27; index only
- action: watchlist
  ticker: SOFI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +13.4163% (14.46 -> 16.4); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:02 ET; index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: PNR
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +12.8033% (55.22 -> 62.29); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:51 ET; index only
- action: watchlist
  ticker: ABG
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +12.7370% (172.96 -> 194.99); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:02 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: CLS
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +12.1184% (246.65 -> 276.54); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:23 ET, reaction 2026-10-27; index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: BA
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -10.6898% (188.31 -> 168.18); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 07:30 ET; index only
- action: watchlist
  ticker: PPTA
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +10.6627% (16.6 -> 18.37); US Army tungsten OTIA agreement + warrant extension (8-K 8.01/3.02), 8-K accepted 17:30 ET 10-26; 8-K accepted 2026-10-26 17:30 ET, reaction 2026-10-27; index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: GLXY
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +9.5663% (15.68 -> 17.18); Q3 earnings (8-K 2.02/7.01), pre-open; 8-K accepted 2026-10-27 07:04 ET; index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: LECO
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +9.1707% (258.65 -> 282.37); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 09:03 ET; index only
- action: watchlist
  ticker: AMKR
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +8.5031% (36.81 -> 39.94); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:07 ET, reaction 2026-10-27; index only; 4 other >=5% session(s) in window
- action: watchlist
  ticker: AIT
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -8.3467% (324.68 -> 297.58); FQ1 earnings (8-K 2.02), 8-K accepted 09:31 ET; 8-K accepted 2026-10-27 09:31 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: GWRE
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -8.0507% (183.96 -> 169.15); Acquisition of Hyperexponential Ltd for $1.7B cash + up to $400M contingent (8-K 1.01/2.03/7.01), pre-open; 8-K accepted 2026-10-27 07:05 ET; index only; 2 other >=5% session(s) in window
- action: watchlist
  ticker: ITRI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +7.7739% (87.73 -> 94.55); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:35 ET; index only
- action: watchlist
  ticker: EEFT
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -7.7248% (63.95 -> 59.01); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:15 ET; index only
- action: watchlist
  ticker: CDNS
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +6.4904% (322.17 -> 343.08); Q3 earnings (8-K 2.02/8.01), after-close 10-26; 8-K accepted 2026-10-26 16:03 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: AGYS
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -6.1887% (123.45 -> 115.81); FQ2 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:05 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: ARE
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.8525% (43.4 -> 40.86); Q3 earnings (8-K 2.02), after-close 10-26; 8-K accepted 2026-10-26 16:08 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: WELL
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.7728% (240.61 -> 226.72); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:33 ET, reaction 2026-10-27; index only
- action: watchlist
  ticker: AWI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.7396% (164.82 -> 155.36); Q3 earnings (8-K 2.02/7.01), 06:00 ET; 8-K accepted 2026-10-27 06:00 ET; index only
- action: watchlist
  ticker: HSBC
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.7011% (91.21 -> 86.01); Q3 earnings (6-K), UK-hours release; 6-K accepted 2026-10-27 12:27 ET; index only
- action: watchlist
  ticker: JCI
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.6814% (147.5 -> 155.88); FQ4 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:58 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: GM
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.5432% (76.31 -> 80.54); Exchange transfer NYSE to Nasdaq (8-K 3.01/5.03/7.01), pre-open; 8-K accepted 2026-10-27 06:30 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: HUBB
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.4680% (459.4 -> 434.28); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 08:05 ET; index only
- action: watchlist
  ticker: RCL
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.4597% (280.6 -> 295.92); Q3 earnings (8-K 2.02), pre-open; 8-K accepted 2026-10-27 06:32 ET; index only
- action: watchlist
  ticker: NE
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.4173% (47.81 -> 45.22); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 17:03 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: SSD
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.3135% (181.99 -> 191.66); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:18 ET, reaction 2026-10-27; index only
- action: watchlist
  ticker: PII
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.2765% (55.15 -> 58.06); Q3 earnings (8-K 2.02), after-close 10-26 (8-K 18:21 ET); 8-K accepted 2026-10-26 18:21 ET, reaction 2026-10-27; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: TRU
  strategy: B
  qualifying_event_date: 2026-10-27
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — -5.2751% (79.62 -> 75.42); Q3 earnings (8-K 2.02/7.01), pre-open; 8-K accepted 2026-10-27 06:15 ET; index only; 3 other >=5% session(s) in window
- action: watchlist
  ticker: NUE
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 3b0ca8cf-58a6-4193-90d0-355368d80aad
  detail: ADD to B new-entry index — +5.2225% (257.35 -> 270.79); Q3 earnings (8-K 2.02/7.01), after-close 10-26; 8-K accepted 2026-10-26 16:54 ET, reaction 2026-10-27; index only
```

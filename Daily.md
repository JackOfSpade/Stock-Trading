2026-10-26
<!-- d1_scan_through_utc: 2026-10-26T22:30:00Z -->

# Daily Market Development Scan — session 2026-10-26 (Mon)

Scan window: 2026-10-25 16:40 MT → 2026-10-26 16:30 MT (~23.8h). The start is the prior `Daily.md` marker `2026-10-25T22:40:00Z`, and that file's commit (22:37Z) agrees. The window holds **one completed US session, Monday 2026-10-26**, plus Sunday evening. Moves are 10-23 → 10-26 close-to-close.

Tape: **an AI-led relief rally, with Brazil crashing and oil lower.**
- **Indices.** IBKR regular-session closes, 10-23 → 10-26: SPY 759.97 → **765.37 (+0.7106%)**, QQQ +1.1073%, IWM +0.4497%, DIA +0.3069%, RSP +0.3464%, **SMH +2.7352%**. The S&P ended two days of losses.
- **Volatility.** The VIX index fell 19.45 → 18.39 (−5.45%; IBKR CBOE bar, delayed feed).
- **Rates and dollar.** 10Y flat at about **4.99%** (Yahoo ^TNX 4.988 → 4.986; Reuters "flat"). A 2Y close was not found. DXY rose 101.81 → 102.01. TLT +0.42%, HYG +0.19%.
- **Oil.** Brent and WTI fell on reports of diplomatic effort in the Gulf, with no deal. **The 10-26 settle is not confirmed by any outlet**, so no level is quoted here. The only figure found is a Yahoo continuous-contract close, which is not a settle statement. The 10-23 settles were Brent December $116.72 and WTI December $103.27. USO −1.95%.
- **Gold and crypto.** Gold about $4,030 (+0.6%), GLD +0.33%. BTC about $79.9k (−1.4%).
- **Leadership.** XLK +1.69 led and XLC −1.57 lagged. Breadth rose to **58.05** (from 56.06).

## TL;DR

- **Exits triggered: none.** Twelve Strategy D tranches carry no mechanical trigger, and no Development meets a thesis-invalidation criterion. No held name filed an 8-K or 6-K in the window.
- **New entry candidates: none routed.** Six names cleared Strategy B's frozen ≥5% floor on their own events: SGRY, RRC, ORKA, ESLT, ASST and WULF. B is `DO-NOT-ACTIVATE` and capital-disabled, so they go to the index only. FICO (−13.2%) is recorded but not routed, because its anchor is unresolved.
- **Add candidates: none (0 of 12).** Seven D tranches read dip-with-intact-thesis, but D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 6 changes.** ADD the six names to the Strategy B new-entry index.
- **Regime review: no review.** Brazil's election crash is a domestic election, not a named geopolitical or trade channel, and `shock_overlay` already reads `acute`. Iran's ceasefire is still only proposed, so there is no qualifying resolution.

Park: VOO-only pin verified

Paper book (J): 120 calls, 51/30 realized, net_mu -1.31%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Anthropic S-1 made public (10-26, 09:00 ET; EDGAR acc 0001628280-26-067168).**
  - Terms: it lists on Nasdaq Global Select as "ANT", led by Goldman Sachs and Morgan Stanley. The price range and share count are blank.
  - Financials: revenue was $4.585B in 2025 and $16.286B in 6M-2026 (vs $1.163B in 6M-2025). The net loss was $80.7B in 6M-2026, mostly fair-value changes on convertibles and SAFEs. WSJ says pricing could come as early as the week before Thanksgiving.
  - Reaction: an AI and semis rally. SMH rose +2.74% and optical/AI-infrastructure names 5-8% (LITE, AXTI, COHR, AAOI, TSEM, TTMI, ARM, FIX, BE).
  - This supersedes the 10-25 "not confirmed filed".
- **Brazil election crash (Lula re-elected in the 10-25 runoff).** Brazilian ADRs collapsed on Monday, with a record EWZ fall reported.
  - XP fell **−48.34%** (IBKR, 30.41 → 15.71). On Nasdaq closes: BBD −28.1, INTR −34.9, STNE −27.4, SBS −26.3, PAGS −25.2, NU −17.0, PBR −14.1, ABEV −13.9.
  - The real fell as well (WSJ/Bloomberg; size not measured).
  - This is a common macro driver, not an issuer event.
- **Gulf (escalation continues; still no resolution).**
  - On 10-24 the Houthis hit Riyadh again, and Dammam airport and the Shaybah oilfield were reported targeted (Al Jazeera/AFP). Saudi attacks were ongoing on Monday (Reuters).
  - Iran's 7-day ceasefire is **under review, not in force**. Four regional states backed the June Islamabad MOU and demanded free Hormuz passage, which is a statement, not a settlement.
  - Monday's oil drop was attributed to reports of diplomatic effort, not a deal. Israel votes 10-27.
- **M&A.**
  - **EQT/Range Resources:** an all-stock deal at 0.987 EQT per RRC share. The agreement is dated 10-25; EQT's 8-K was accepted at 06:17 ET and RRC's at 07:07 ET.
  - **Surgery Partners:** a take-private by HealthSpan Partners, a Bon Secours Mercy Health affiliate, at **$23.50 cash**, an EV of about $5.7B. The 8-K was accepted at 09:03 ET.
  - The RIG/VAL 10-23 8-Ks are procedural Item 8.01 filings for the existing deal: meetings on 11-24 and the Bermuda sanction hearing on 11-26.
- **Telecom.** The selloff on SpaceX's wireless ambitions continued: CHTR −5.9% to a 52-week low, and VZ −3.49% despite a beat.
- **Not found** in this window: China tariff, Russia-Ukraine, shutdown, bankruptcy or enforcement news. Those searches were thin.

### 2. Scheduled events that resolved in the window

- **Enumeration.** I fetched the Nasdaq key-less calendar for 10-26 and 10-23 with curl. No ≥$2B issuer released after the 10-23 close. Release times come from EDGAR acceptance stamps, and consensus figures are Nasdaq-calendar (secondary).
- **Macro (10-26).**
  - Chicago Fed NAI for September was **+0.07** vs −0.08 in August and a −0.10 consensus (secondary sources).
  - The Dallas Fed Texas manufacturing survey for October (from the Dallas Fed's own page) had general business activity at **13.4** (from 9.8), production at 15.8 (−14) and new orders at 9.3 (from 30.7).
- **Pre-open 10-26 reporters (IBKR close-to-close).**

  | Ticker | Result (secondary consensus) | 10-26 move |
  |---|---|---|
  | **VZ** | adj EPS $1.31 vs ~$1.27; FY26 guide raised for the third straight quarter; 406k postpaid phone adds (07:00 ET) | **−3.49%** |
  | MMYT | | −2.11% |
  | BOH | EPS $1.49 vs $1.52 | −0.10% |
  | CX | | −0.10% |
  | ARLP | | +0.99% |

  No reporter moved ≥5%.
- **No EDGAR print found** for PKX, SMMT, BMRN, CLBK, BLX or ENI, so they are recorded as unresolved.
- **After-close 10-26 (react 10-27, not measured).** 26 names of $2B or more, accepted 16:01-17:03 ET:
  - WELL, CDNS (raised its 2026 outlook), NUE, PSA (raised guidance), HIG and CLS (Q3 revenue $5.83B vs $5.44B, 2026 revenue guide $21B);
  - CINF, BRO, PFG, GGB, SUI, AMKR, RMBS, BRX, NE, SSD, ARE, PSMT, PECO, DORM, AGYS, PRK, HWKN, HTO, NWBI, CTOS.
- **Pending this week.**
  - Tuesday: KO and BA.
  - 10-28: **GEV pre-open; the FOMC at 14:00 ET** (about 90% hold, December hike favoured); GOOGL after the close.
  - 10-29: Q3 GDP and September PCE, the ECB, and **AMZN** after the close.
  - 10-30: the BoJ. The midterms are 11-03.
- **FDA.** No PDUFA decision, approval or CRL for a ≥$2B sponsor was found for 10-24..10-26. The FDA press page's newest entry is 10-22 and novel approvals' newest is 10-20, so this is unresolved, not a measured absence. MIRM released pivotal data on 10-26, which is not an FDA action.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `7d029722-e7f6-476e-9907-423b12af4cd7` (`surfaced_count` 10 = `ARRAY_LENGTH(passed)`: 9 floor clearers plus VZ below the floor; agreement both 9 / ai_only 1 / rule_only 79). Every written-up figure is an IBKR regular-session daily-bar close-to-close (close array), 10-23 → 10-26. Every pair agreed with the Nasdaq closes within 0.15pp.

- **Discovery (unmetered).**
  - The Nasdaq screener `pctchange` was **stale** (10-23 values), and Nasdaq historical bars had no 10-26 row at about 22:10Z.
  - So the 10-26 closes came from Nasdaq quote/info ("Closed at Oct 26 4:00 PM ET") against the 10-23 bar, for **2,014 of 2,015** ≥$2B US stocks and ADRs. **513 moved ≥2% and 88 moved ≥5%.**
  - EDGAR 8-K/6-K filings were pulled for all 513.
- **Layer 2.** Every non-reporter moving ≥5% was examined, clustered by theme (18 searches). The 2-5% non-reporters were not individually attributed (`selection_rule`).
- **Fan-out reconciliation.** Legs were compared by (ticker, event date). SGRY was named with two different buyer names; its 8-K Ex-99.1 resolves both as HealthSpan Partners (BSMH). There were no date conflicts.
- **Close-chain check.** No CHAIN HIT among the passed items. CART's 10-26 pair chains forward from its 10-23 item, and it is rejected below as a continuation.

| Ticker | Move (close → close) | Release and anchor | Conviction | Notes |
|---|---|---|---|---|
| **SGRY** | +47.6190% (15.75 → 23.25) | pre-open 10-26, 8-K 09:03 ET; anchor 2026-10-26 | 75 | $23.50 cash take-private (EV ~$5.7B); trades at a ~1% spread to the deal; cap ~$2.06B pre-move; 1 other ≥5% session (10-20) |
| **RRC** | +17.6626% (45.52 → 53.56) | pre-open 10-26, 8-K 07:07 ET; anchor 2026-10-26 | 75 | All-stock merger into EQT at 0.987 (implied ~54.14); EQT −1.40% |
| **FICO** | −13.1533% (815.31 → 708.07) | announcement described as Friday 10-23, minute not established; **anchor UNRESOLVED**, reaction 2026-10-26 | 60 | Held the $10 mortgage-score price, then a Wells Fargo downgrade and FHFA's Pulte on score competition; **not routed** |
| **ORKA** | +12.7012% (80.15 → 90.33) | pre-open 10-26, 8-K 08:00 ET; anchor 2026-10-26 | 60 | Phase 2b EVERLAST-B psoriasis: PASI100 61% vs 0% placebo; 1 other ≥5% session (10-20) |
| **ASST** | −9.1474% (28.97 → 26.32) | pre-open 10-26, 8-K 07:50 ET; anchor 2026-10-26 | 30 | New $1.0B preferred ATM; the crypto cohort was also weak; 6 other ≥5% sessions |
| TENB | +8.1184% (44.59 → 48.21) | Baird PT raise (analyst action) | 30 | Not an issuer event; not B-eligible |
| **WULF** | +5.8304% (11.32 → 11.98) | after-close 10-23, 8-K 17:13 ET; anchor 2026-10-23, reaction 2026-10-26 | 30 | Revolver upsized to ~$400M; mostly beta; 5 other ≥5% sessions |
| **ESLT** | +5.7960% (735.34 → 777.96) | pre-open 10-26, 6-K 06:01 ET; anchor 2026-10-26 | 30 | ~$200M ISTAR contract, small vs a ~$36B cap; defense firm; 2 other ≥5% sessions |
| TSLA | +5.2120% (372.22 → 391.62) | Barclays upgrade (analyst action) | 30 | Not an issuer event; not B-eligible |
| VZ | −3.4931% (44.66 → 43.10) | pre-open 10-26, 8-K 07:00 ET | 30 | Beat and raise, but moved with the telecom selloff; below the floor, context only |

- **Rejected or common driver** (Nasdaq-basis unless noted):
  - **XP −48.34% (IBKR)** and 25+ Brazil ADRs at −12% to −35%: the election.
  - **AI-infrastructure cohort +5-8%**: the Anthropic S-1.
  - **Refiners +5-8%**: PARR, CVI, PBF, DK, CLMT.
  - **Telecom/cable**: CHTR −5.9, VSAT +8.0.
  - **Crypto, mixed**: CRCL −7.1, GLXY +6.8, BMNR −6.5.
  - **CART +7.87% (IBKR)**: a continuation of the 10-23 sale report.
  - **No event found**: DAVE −8.9, VICR +10.6, INIO +9.3.
  - BSP +5.8 (Miro deal closing). BAH +6.5 is a following session after its 10-23 print.
  - The after-close 10-26 reporters AMKR −6.3, RMBS +5.5 and CLS −5.3 moved before their releases.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` `cb06c3e0-7916-4ab8-8490-ac25122263f6` (`surfaced_count` 4). Registry contract ids were used, and the guard closes on 10-23 matched the prior run (XLE 69.33, XLP 88.26, XLC 105.51, XLK 183.23).

- **XLK +1.6864%** (183.23 → 186.32), conviction 45: the AI and semis rally on the Anthropic S-1, led by SMH +2.74%.
- **XLC −1.5733%** (105.51 → 103.85), conviction 45: the telecom and cable selloff on SpaceX wireless (CHTR, VZ). It is the second down day.
- **XLI +1.4215%**, conviction 30: defense (RTX +3.39%, LMT +5.2%) and AI-infrastructure contractors.
- **XLY +1.0256%**, conviction 30: TSLA +5.21% carries the cap-weighted ETF.
- None of the four reaches 2%, so `legacy_rule_pass=false` for all.
- **Under 1%, not surfaced:** XLRE +0.54, XLE +0.45, XLF +0.21, XLB +0.14, XLV 0.00, XLU −0.02, XLP −0.34. The XLE vs USO dispersion (−1.95%) reflects refiners up against upstream, and is not surfaced.

### 5. Notable commentary

- RBC (Calvasina): the top-10 S&P names have started to falter again against the rest of the market.
- An Apollo analysis (via Semafor, 10-25) found AI capex shows "zero financial payoff" outside the Magnificent 7, and a PM told Bloomberg investors have "absolutely no patience" for higher capex. Monday's S-1 rally cut against that.
- Bloomberg (Authers, 10-26): a post-election Iran escalation could mean an oil wipeout.
- The Fed is in blackout before the 10-28 FOMC. No sell-side notes on held names were captured.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- I swept the union of `state.current_positions` (12 tranches, re-read before the appends and unchanged) and IBKR `get_account_positions`, and they agree on every name:
  - AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156.
  - VOO 17.7307 is the park. There is no reconciliation-lag position.
- All 12 tranches are Strategy D, with no `convergence_target` and no `time_exit_date`, so **no exit is triggered**.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-23):
  - unit 1.0335 vs peak 1.1065 (−6.59%); `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` all FALSE.
  - **Refreshed on IBKR 10-26 closes**, the D book rose +0.85% ($530.51 → $535.04), which puts the unit at ≈1.0423 and the drawdown at **≈−5.79%** against the −50% kill.
- **B:** no open position. The `analytics.b_pairwise_correlation` check is inert (n_positions 0).
- No other strategy holds positions. **No termination and no runaway review.** There is no open `interim_underperf_warning` alert to heal.

### Thesis-invalidation review

EDGAR shows no 8-K or 6-K from any of the eight held names in 10-23..10-26. Web coverage was one wide search, so "none found" is not proof of none.
- **GEV** (+4.92% to 855.12): no company news. Q3 is **10-28 pre-open** (CNBC consensus revenue $11.99B, EPS $3.97), and that is when the orders-growth criterion becomes testable. UNBREACHED.
- **ISRG** (−0.15%): Form 4s on 10-26 and four Form 144s on 10-23 are routine insider-sale notices, not a criterion. UNBREACHED.
- **GOOGL** (−1.06%, Q3 10-28 after the close), **AMZN** (+0.44%, Q3 10-29 after the close), **RTX** (+3.39%), **TSM** (+1.40%), **DIS** (−1.88%) and **UBER** (−0.85%; earnings date not found): no news. All criteria are UNBREACHED or not testable this window.
- **The Anthropic S-1** is reinforcing context for AMZN's criterion 4 (Anthropic commitments), not a breach.

**Watchlist candidacy:** the Strategy B new-entry index gains 6 names (below). No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** Six own-event floor clearers are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only.
  - SGRY and RRC are merger targets pinned to deal terms. A thesis session would have to clear criterion 4 (information-driven repricing) against them.
- **C.** Strategy C stays HYBRID ACTIVATE (FOMC-only). The 10-28 FOMC is already gated under `thesis-FOMC-C-20261020`. No new qualifying catalyst within 45 days was found.
- **A** (`DO-NOT-ACTIVATE`, div-A-202610-1): not a candidate.
- **E** (`DO-NOT-ACTIVATE`, div-E-202610-1). These intra-group divergences are recorded for M2, not routed:
  - E&P: RRC +17.7 vs EQT −1.4 (deal arbitrage, not a divergence trade);
  - refiners +5-8% vs upstream (XLE +0.45);
  - cybersecurity: TENB +8.1 vs a mixed group.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `d53668fc-9c77-43dc-a056-898d269ca821`. All 12 open D tranches were evaluated, 0 were flagged and 0 were declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12, and positions were re-read immediately before the append. Each tranche is marked at its IBKR 10-26 close against its own cost basis per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +29.22% | none | declined |
| D:RTX:2026-04-27 | +11.63% | none | declined |
| D:TSM:2026-07-29 | +8.01% | none | declined |
| D:DIS:2026-08-05 | +6.37% | none | declined |
| D:AMZN:2026-07-09 | +3.25% | none | declined |
| D:DIS:2026-05-07 | −0.83% | dip-with-intact-thesis | declined: no funding path |
| D:TSM:2026-07-21 | −0.82% | dip-with-intact-thesis | declined: no funding path |
| D:GOOGL:2026-07-26 | −3.37% | dip-with-intact-thesis | declined: no funding path |
| D:AMZN:2026-07-30 | −6.25% | dip-with-intact-thesis | declined: no funding path |
| D:UBER:2026-07-09 | −9.67% | dip-with-intact-thesis | declined: no funding path |
| D:GEV:2026-08-03 | −11.83% | dip-with-intact-thesis | declined: no funding path; Q3 10-28 |
| D:GOOGL:2026-07-09 | −11.96% | dip-with-intact-thesis | declined: no funding path |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- **Technical side.** SPY closed at 765.37 (+0.71%), the VIX at 18.39, and breadth at 58.05 (D2a classifies them). The measured refresh triggers are D2's to detect.
- **Geopolitical-trigger duty.**
  - The 10-24 Houthi strikes on Riyadh, Dammam and Shaybah are further escalation inside the standing `acute` overlay, so no scenario-3 flag is owed.
  - The Brazil election crash is a domestic political event. It is not a named geopolitical or trade channel under the `Qualifying shock event` definition, and the overlay is `acute` regardless.
  - **Mirror:** Brent fell sharply on Monday, but on diplomacy reports. There is no ceasefire in force, no blockade lifted and no sanctions settlement, so it is not a qualifying resolution event.
- No other Development plausibly shifts any strategy's activation state.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **58.05 for 2026-10-26**. The value is source-dated by Barchart `$S5TH`: "Quote Overview for Mon, Oct 26th, 2026", 58.05 +1.99 (+3.55%) stamped **16:57 ET**, so it is settled. Previous Close is 56.06, equal to the stored 10-23 value. O/H/L 58.25/59.24/57.85 is a real bar, not a carry. It was fetched via tavily_extract at about 22:08Z.

- **Single usable source.** EODData's 26 Oct row agrees exactly (its header clock read 15:51, but its row matches the settled print). Barchart and EODData are one feed.
- **Independent check.** ChartRow (as of the 10-26 close) shows 288 of 497 = 57.95%, against 55.73% on 10-23. Its day-over-day change of +2.22pp vs `$S5TH` +1.99pp gives `chartrow_dod_gap=0.23`, and the level gap is 0.10pp.
- No MacroMicro probe (Monday). Not an exact repeat.

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The six eligible own-event floor clearers are indexed below instead. FICO is not indexed: its anchor is UNRESOLVED, so its window cannot be dated.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `7d029722-e7f6-476e-9907-423b12af4cd7`.

- ADD **SGRY** (Strategy B, `qualifying_event_date` 2026-10-26) — +47.6190% (15.75 → 23.25); $23.50 all-cash take-private by HealthSpan Partners (BSMH), EV ~$5.7B, 8-K 09:03 ET; trades at a ~1% deal spread; index only. 1 other ≥5% session in the window.
- ADD **RRC** (Strategy B, `qualifying_event_date` 2026-10-26) — +17.6626% (45.52 → 53.56); all-stock merger into EQT at 0.987 EQT per share, 8-K 07:07 ET; index only.
- ADD **ORKA** (Strategy B, `qualifying_event_date` 2026-10-26) — +12.7012% (80.15 → 90.33); Phase 2b EVERLAST-B psoriasis topline, PASI100 61% vs 0% placebo, 8-K 08:00 ET; index only. 1 other ≥5% session in the window.
- ADD **ASST** (Strategy B, `qualifying_event_date` 2026-10-26) — −9.1474% (28.97 → 26.32); new $1.0B 15% Series A perpetual preferred ATM, 8-K 07:50 ET, inside a weak crypto cohort; index only. 6 other ≥5% sessions in the window.
- ADD **WULF** (Strategy B, `qualifying_event_date` 2026-10-23) — +5.8304% (11.32 → 11.98); revolver upsized from $250M to ~$400M, 8-K after the 10-23 close (17:13 ET), reaction 10-26; mostly beta; index only. 5 other ≥5% sessions in the window.
- ADD **ESLT** (Strategy B, `qualifying_event_date` 2026-10-26) — +5.7960% (735.34 → 777.96); ~$200M Asia-Pacific ISTAR contract, 6-K 06:01 ET, small against a ~$36B cap and partly defense-sector; index only. 2 other ≥5% sessions in the window.

```yaml d1_actions
- action: watchlist
  ticker: SGRY
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — +47.6190% (15.75 -> 23.25); $23.50 all-cash take-private by HealthSpan Partners (BSMH), EV ~$5.7B, 8-K 09:03 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: RRC
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — +17.6626% (45.52 -> 53.56); all-stock merger into EQT at 0.987, 8-K 07:07 ET; index only
- action: watchlist
  ticker: ORKA
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — +12.7012% (80.15 -> 90.33); Phase 2b psoriasis topline PASI100 61% vs 0%, 8-K 08:00 ET; index only; 1 other >=5% session(s) in window
- action: watchlist
  ticker: ASST
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — -9.1474% (28.97 -> 26.32); new $1.0B preferred ATM, 8-K 07:50 ET; index only; 6 other >=5% session(s) in window
- action: watchlist
  ticker: WULF
  strategy: B
  qualifying_event_date: 2026-10-23
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — +5.8304% (11.32 -> 11.98); revolver upsized to ~$400M, 8-K after close 10-23 17:13 ET, reaction 10-26; index only; 5 other >=5% session(s) in window
- action: watchlist
  ticker: ESLT
  strategy: B
  qualifying_event_date: 2026-10-26
  source_research_screen_id: 7d029722-e7f6-476e-9907-423b12af4cd7
  detail: ADD to B new-entry index — +5.7960% (735.34 -> 777.96); ~$200M ISTAR contract, 6-K 06:01 ET; index only; 2 other >=5% session(s) in window
```

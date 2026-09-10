2026-09-10
<!-- d1_scan_through_utc: 2026-09-10T22:30:10Z -->

# Daily Market Development Scan — 2026-09-10 (Thu, MT)

**Scan window: 2026-09-09 16:40 MT → 2026-09-10 16:30 MT** (23.8h — an ordinary single-cycle window, no gap. Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-09T22:40:27Z -->` marker, cross-checked against that file's own commit at 2026-09-09T22:44:24Z; the two agree to within four minutes. `state.routine_catchup_window` independently returns `window_start_ts = 2026-09-09T22:47:37Z`, `window_days = 0.97`, `never_completed = false` — the same boundary, so no catch-up widening applies and no `CATCHUP[...]` token is owed. The git history is **not** shallow at this fire (1,402 commits, `is-shallow-repository = false`), so the HISTORY-DEPTH PRECHECK passes and the git leg of the window resolution is sound rather than merely silent.)

**ONE completed US trading session inside this window: Thursday 2026-09-10.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-10`. Every close-to-close figure in this file is measured 2026-09-09 → 2026-09-10.

**Tape.** SPY 762.40 → 757.83 (**−0.5994%**), VOO 700.87 → 696.65 (−0.6021%), QQQ **−1.0638%**, DIA −0.6335%, IWM −1.0116%, SGOV +0.0100%. VIX 16.46 → **17.84** (+8.3840%). Brent 101.21 → **107.63** (+6.3433%), USO **+5.6078%**. GLD −1.7330%, TLT −1.1624%, UUP +0.1787%, BITO −1.3321%. Equity breadth ($S5TH) 56.85 → **54.67**. Nine of eleven GICS sectors lower; the cross-sector spread was only 2.02pp (XLC +0.6045% to XLK −1.4105%).

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), each verified carrying a 2026-09-10 bar stamped `13:30:00Z`. **One documented exception, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) is stamped `07:15:00Z`, not the RTH `13:30:00Z` — an index-feed property, not an equity RTH bar. It is used anyway because the same series cross-validates exactly: its 2026-09-09 bar reads 16.46, which equals the value already stored in `state.signal_marks_curated` for that session. No new alert is raised for this; a standing feed property re-alerted each session is the alarm fatigue this fleet's alert discipline exists to prevent.

**Nothing about this run is degraded, and that is measured rather than claimed.** 33 distinct single names and 25 index/ETF instruments were put to IBKR for confirmation; **all 58 resolved with a genuine 2026-09-10 regular-session bar. Zero symbol-level denials, zero unresolved.** So every `surfaced_count` below is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

---

## TL;DR

- **Exits triggered: none.** No mechanical trigger exists to fire (all 12 open tranches carry NULL `convergence_target` and NULL `time_exit_date`), and no Development breaches any thesis-invalidation criterion.
- **New entry candidates: 4** — all Strategy B: **COO, AEO, NAVN** (all three on 2026-09-09 after-close prints) and **RDDT** (2026-09-10). No A, no C, no E.
- **Add candidates: none.** 12 open Strategy-D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER — breach status never assessed and no covering tranche).
- **Watchlist changes:** the 4 Strategy-B names above enter the B new-entry-candidate index; no removes and no demotions.
- **Regime review: no review.** Default-NO on ambiguity holds; nothing today plausibly flips a router state.
- **Park: BOUND DE-RISK, `target_f_pct` 25 → 50** (VOO 50% / SGOV 50%), MEDIUM 55 — a fourth defensive axis (index) ENTERED on live measurement while the three already standing all deepened.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**US–Iran escalation broadens to shipping on both sides; Brent settles 107.63.** Following the US destruction of five Iranian tankers, Iran retaliated against roughly ten vessels near the Strait of Hormuz (two US vessels and eight oil tankers by Iran's own claim) — the largest wave of shipping attacks by either side since the war began. At least one seafarer was killed and one is missing aboard the tanker *Hercules Star* off Dubai; the Iraqi tanker *New Andros*, carrying ~2M barrels of fuel oil, caught fire after a drone strike in Iraqi waters (22 crew, no casualties reported). Iran fired ballistic missiles at a US base in Jordan, most intercepted, and the IRGC said it would announce an enlarged maritime exclusion zone extending toward Chabahar.

- Sources: France 24, https://www.france24.com/en/middle-east/20260909-iran-and-us-strike-tankers-in-biggest-shipping-attack-since-war-began (published 2026-09-09 22:31); Reuters wire via Club of Mozambique, https://clubofmozambique.com/news/iran-and-us-hit-tankers-in-biggest-wave-of-attacks-on-shipping-since-war-began (2026-09-10); CNBC, https://www.cnbc.com/2026/09/10/iran-us-oil-hormuz-supply-trump-military-brent-wti.html (2026-09-10).
- **Timing caveat, stated rather than resolved:** outlets differ on tanker-strike counts and on whether the first wave landed Tuesday or overnight into Wednesday. All agree the retaliation and the market reaction fall inside this scan window. The exact strike minute is **not established**.
- **Observable reaction (each figure below measured from IBKR bars unless attributed):** Brent +6.3433% to 107.63, USO +5.6078% — the clear mover. Equities lower and broad: SPY −0.5994%, QQQ −1.0638%, IWM −1.0116%, 9 of 11 sectors down. **The energy complex is the tell and it points the other way** — XLE **fell 0.5818%** on the day crude rose 6.3%. Rates higher (10Y at its highest since November 2023, press-sourced). **No flight to safety:** gold −1.7330%, long Treasuries −1.1624%, dollar +0.1787%. Crypto lower, BITO −1.3321%.
- **What the cross-asset reaction shows:** a discount-rate and input-cost repricing, not a systemic risk event. Gold, Treasuries and the dollar all failed to catch a safety bid, and the only two green sectors were idiosyncratic (XLC) and staples (XLP +0.0482%).

**ECB raised its deposit rate 25bp to 2.50%** (Thursday, second hike of 2026), explicitly citing Iran-war-driven energy inflation; Lagarde said headline inflation will stay "well above target" into H1 2027 while calling the eurozone economy "resilient despite the energy shock." Recorded here rather than under §2 because, although scheduled, it is a war-driven policy response rather than a routine print. It was ~98–100% priced beforehand, so it is **not** a central-bank surprise. Sources: Bloomberg, https://www.bloomberg.com/news/videos/2026-09-10/ecb-s-lagarde-inflation-to-stay-above-target-into-2027-video ; Reuters, https://www.reuters.com/world/china/global-markets-view-europe-2026-09-10.

**No other market-wide breaking event surfaced in the window** — no material bankruptcy, disaster, unscheduled enforcement action or central-bank surprise. Stated as a measured absence over the scan performed, not as a claim of exhaustiveness.

### 2. Scheduled events that resolved today

**EVENT-IDENTITY GATE applied.** Each result below was verified against reporting that names the fiscal period and release date, and each price reaction was independently confirmed from IBKR regular-session bars rather than taken from the reporting.

**Macro (both released Thursday 2026-09-10, 08:30 ET):**

- **August PPI.** Headline final demand **+0.4% MoM**, in line with consensus (July revised to +0.1%); headline **+5.4% YoY** against ~5.3% consensus — a modest upside surprise; core ex-food-and-energy **+0.2% MoM** against +0.3% expected, i.e. *below* consensus; core **+4.6% YoY**, in line. Primary source: BLS, https://www.bls.gov/news.release/archives/ppi_09102026.htm ; consensus comparison, Yahoo Finance, https://finance.yahoo.com/economy/article/ppi-data-shows-wholesale-prices-advancing-in-line-with-expectations-124319008.html. The split matters: the *headline* beat is the oil pass-through, the *core* miss is not, so this is a less hawkish print than the 5.4% number alone implies.
- **Weekly initial jobless claims**, week ended 2026-09-05: **206,000**, down 1,000 from a revised 207,000, against a 205,000 consensus. Continuing claims 1.774M (week ended 08-29), below the 1.780M consensus. Source: Reuters, https://www.reuters.com/world/us/us-weekly-jobless-claims-edge-down-layoffs-remain-low-2026-09-10.

**Earnings prints that resolved inside the window** (fiscal period as the source states it; reaction independently measured from IBKR):

- **Macy's (M) — Q2 FY2026, reported before Thursday's open: −4.6955%.** Adjusted EPS $0.63 vs $0.37 consensus, net sales $4.87B vs $4.81B estimate (+1.1% YoY), comparable sales +2.7%, Bloomingdale's +11.3%. FY guidance **raised** to $2.15–$2.35 adjusted EPS and $21.68–21.83B revenue, including a $116M tariff-refund benefit. A beat-and-raise met with a −4.7% session. (TheStreet, https://www.thestreet.com/stock-market-today/stock-market-today-dow-jones-sp-500-nasdaq-updates-sept-10-2026)
- **Adobe (ADBE) — Q3 FY2026 (quarter ended 2026-08-28), reported AFTER Thursday's close: −2.3660% on the session.** Revenue $6.76B vs ~$6.70B consensus (+13% YoY), non-GAAP EPS $6.13 vs $6.09; FY2026 revenue target raised to $26.576–26.626B; AI-first ARR +150% YoY; CEO transition announced (Anil Chakravarthy to President/CEO effective 2026-12-01, Shantanu Narayen to Executive Chair). **The −2.3660% is PRE-print drift, not the reaction** — the reaction session is 2026-09-11. (Business Wire, https://www.businesswire.com/news/home/20260910832552/en/Adobe-Reports-Record-Q3-Results)

**Reaction sessions for prints that landed after Wednesday's close** — these resolved in the prior window but their price reaction is today's, which is why they carry `qualifying_event_date` 2026-09-09:

- **Cooper Companies (COO) — FQ3: −14.6660%.** Revenue $1.066B vs ~$1.098B consensus (miss), FY guidance cut, CooperVision channel destocking named as the mechanism.
- **American Eagle (AEO) — Q2: −13.9728%.** EPS and revenue **beat**, guidance **raised** (tariff-refund-boosted), comparable-sales miss overwhelmed both. (StockStory, https://stockstory.org/us/stocks/nyse/aeo/news/why-up-down/why-american-eagle-aeo-shares-are-plunging-today-2)
- **Navan (NAVN) — FQ2 FY2027: −21.7458%.** Beat and raised outlook; widening GAAP operating and net loss overshadowed headline growth.
- **AeroVironment (AVAV) — FQ1: +4.4460%.** Revenue $480.5M vs $455.8M consensus, record backlog. (Barchart, https://www.barchart.com/story/news/4538530/stocks-slump-as-crude-prices-soar-and-bond-yields-surge)

**Pending, not resolved — recorded with confirmed scheduled dates and NO outcome figures populated:**

- **August CPI — Friday 2026-09-11, 08:30 ET (BLS).**
- **September FOMC — 2026-09-15/16**; decision and SEP Wednesday 2026-09-16 14:00 ET, press conference 14:30 ET.
- **Oracle (ORCL) FQ1 FY2027** — reported after today's close; reaction session 2026-09-11.
- **Telix Pharmaceuticals (TLX)** PDUFA on TLX101-Px — 2026-09-11. **Scholar Rock (SRRK)** PDUFA on apitegromab — 2026-09-30. Neither resolved in this window.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (`screen='single-name-move'`)

Logged as one `entry_type='research-screen'` row, `events.decision_log` entry_id **`7d717e9f-c609-4166-8487-e965a2faff13`**. `surfaced_count = 16` (= `ARRAY_LENGTH(passed)`, per the 2026-08-30 pin), `rail_tally = 22`, `universe_measured = 33`. Agreement: `both` 10, `ai_only` 6, `rule_only` 0.

Layer-1 rail: US-listed, market cap ≥ $2B, close-to-close ≥ 2% attributable to an identifiable public driver. Caps from FMP `company/profile-symbol`, which returned for **all 25** discovery candidates; the documented sibling denials (`batch-market-cap`, `market-cap`, `shares-float`, `batch-quote`, `chart`) were hit and are the **standing** plan-tier limit — no fresh vendor-tier alert is owed and none is raised.

| Ticker | Move | Event | Conviction | `legacy_rule_pass` (≥5%) |
|---|---|---|---|---|
| NAVN | **−21.7458%** | FQ2 FY27 beat-and-raise met with a widening GAAP loss | 60 | true |
| COO | **−14.6660%** | FQ3 revenue miss + FY guide cut, CooperVision destocking | 75 | true |
| AEO | **−13.9728%** | Comp-sales miss overwhelmed an EPS/revenue beat and a raised guide | 75 | true |
| SCCO | **−7.2255%** | Copper off record highs on White House refined-copper tariff indecision | 60 | true |
| FCX | **−6.5853%** | Same copper-tariff channel (counted as one driver, not two) | 60 | true |
| RDDT | **+6.0776%** | Piper Sandler data: +8% MoM August user growth | 60 | true |
| CIFR | **−5.6805%** | Bitcoin-miner / AI-data-centre complex on a higher-rates risk-off session | 45 | true |
| LRCX | **−5.6453%** | Semi-cap equipment on the duration repricing | 45 | true |
| INTC | **−5.5723%** | Profit-taking after a multi-session rally, inside the chip selloff | 45 | true |
| ORCL | **−5.3764%** | Pre-earnings de-risking; the print landed AFTER the close | 45 | true |
| CHTR | **+4.9817%** | Rebound plus reception to management's growth plans | 45 | false |
| ELV | **+4.9483%** | FY2026 earnings and benefit-expense guidance **reaffirmed** | 60 | false |
| M | **−4.6955%** | Q2 beat-and-raise met with a −4.7% session | 60 | false |
| AVAV | **+4.4460%** | FQ1 revenue beat, record backlog | 45 | false |
| AAPL | **+3.5612%** | Foldable "iPhone Duo" launch enthusiasm | 60 | false |
| AGNC | **−3.0447%** | 10Y at its highest since November 2023 | 45 | false |

**`rejected_notable` (7)** — rail-clearing or near-rail names judged not significant, each recorded in the decision-log row with its reason: NVDA −2.3740%, ADBE −2.3660% (pre-print drift), MARA −4.1107% and IREN −3.8131% (same crypto-miner driver as CIFR, counted once), AA −4.7901% (second-order to the copper channel; aluminium is not the commodity under review), FOXA +2.0670%, GEV −2.8527% (held D position; **no identifiable public event found**, so it does not clear the rail).

**Two open-position names cleared magnitude and cap but are excluded from the rail for want of an identified driver: ISRG +2.0439% and UBER +2.0822%.** Stated as a found-nothing, not as an absence of news.

**What confirmation caught, and why the discovery leg is never the source of record.** Two names arrived from discovery with large reported moves and were **refuted by measurement**: **CC** reported +6.6% on a $455M PFAS settlement, measured **+0.1995%**; **SSNC** reported +5.0% on a UBS target raise, measured **−0.5294%**. Both were dropped. A third contamination class was caught inside discovery itself — FICO, LULU, ADBE, EFX, ADSK and PTC surfaced with large moves that on inspection were dated **2026-09-04**, not 09-10. IBKR governed in every case per Operating_Protocols.md §19 PRICE BASIS.

**Cap-rail caveat that is NOT resolved.** Two names sit inside the ~30% band around $2B where FMP's implied share count is not trustworthy: **AEO $2.44B** and **CC $2.27B**. CC is moot (it failed the 2% limb). **AEO is not moot** — it is written up *and* routed as a Strategy-B candidate on a −13.97% move, so its rail clearance rests on a figure this run flags as needing a second source. Recorded rather than resolved.

**ORCL and ADBE are deliberately NOT Strategy-B candidates** despite ORCL clearing the 5% floor: both reported after today's close, so today's moves contain positioning and no resolved information. Their reaction sessions are 2026-09-11 and the next D1 owns them. Recorded here so tomorrow's run does not mistake today's drift for the event move.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (`screen='sector-move'`)

Logged as one `entry_type='research-screen'` row, entry_id **`37a595df-af23-4b3e-97ef-689e99e29f96`**. `surfaced_count = 6`, `rail_tally = 2`, `universe_measured = 11`. Agreement: `both` 0, `ai_only` 6, `rule_only` 0 — **no sector moved ≥2%, so every write-up here is an AI-only surfacing by construction.**

| Sector ETF | Move | Conviction | Read |
|---|---|---|---|
| XLE | **−0.5818%** | **75** | Energy equities FELL on the day Brent rose 6.34% and USO rose 5.61% |
| XLK | **−1.4105%** | 60 | Largest decline; long-duration rate channel via ORCL/INTC/LRCX/NVDA |
| XLB | **−1.2259%** | 60 | Single policy driver: copper-tariff indecision (FCX, SCCO, AA) |
| XLU | −0.9781% | 45 | Bond proxy sold with the 10Y move |
| XLRE | −0.8293% | 45 | Second rates limb; corroborates XLU rather than adding information |
| XLC | **+0.6045%** | 45 | Only meaningful gainer, and idiosyncratic (RDDT, CHTR, FOXA) |

Full measured panel, descending: XLC +0.6045, XLP +0.0482, XLF −0.3330, XLY −0.4446, XLV −0.5523, XLE −0.5818, XLI −0.7218, XLRE −0.8293, XLU −0.9781, XLB −1.2259, XLK −1.4105.

**The headline finding is the one the mechanical ≥1% rail would have discarded.** XLE fails the net and is ranked *above* the two sectors that clear it. A 6.2pp gap between crude and its own producers, on the day crude spiked, is a market statement: this oil move is being priced as a demand-destroying, short-half-life supply shock rather than as a producer earnings windfall. No magnitude-ranked screen could surface that.

**Two third-party sector sources were obtained and DISCARDED, on evidence.** A Zacks/Yahoo recap carried XLE **+1.1%**, XLI −1.5%, XLY −1.2%, XLU −1.1% for what it labelled the session — figures that disagree **in sign** with the IBKR measurement for XLE. The same article carried "VIX +4.7% to 16.46" and "Brent settled 101.21", both of which are the **2026-09-09** session: it is a prior-day recap published on 09-10 and its sector line is the wrong day. FMP `sector-performance-snapshot` was also discarded — it returns equal-weighted NASDAQ-listed averages, not the cap-weighted SPDRs, and its Energy −0.81 / Industrials +0.82 likewise contradict the ETF signs. Recorded rather than silently dropped, because a session that took either at face value would have written up an energy-sector *rally* on the day energy equities fell.

### 5. Notable commentary

- **Goldman Sachs** (Daan Struyven, co-head of global commodities research) put the tail risk at **oil above $120/barrel** if shipping attacks intensify. (CNBC, https://www.cnbc.com/2026/09/10/iran-us-oil-hormuz-supply-trump-military-brent-wti.html)
- **Oxford Economics** (Ben May) now sees the base case as "simmering tensions … and lower-than-normal traffic in the Strait of Hormuz until at least the end of 2027," with oil averaging ~$85 for the rest of 2026 and falling to ~$65 by end-2027. (ABC45/Nexstar, https://abc45.com/news/nation-world/100-oil-returns-as-renewed-iran-fighting-threatens-inflation-progress-strait-of-hormuz-tankers-gasoline-diesel-economy — **publish timestamp not confirmed**; content is consistent with the window but the date could not be pinned.)
- **BOJ board member Kazuyuki Masu**, ahead of next week's BOJ meeting, said underlying inflation is "very close" to the 2% target, hinting at faster hikes; cited as a driver of yen strength (~153.4–153.6/USD, +4% in September). (Reuters, https://www.reuters.com/world/china/global-markets-view-europe-2026-09-10)
- **Bank of America** raised its H2 oil forecast to $83/barrel with a $95–120 scenario if shipping attacks continue and up to $150 if major energy infrastructure is hit. **Flagged as out-of-window:** the note is dated Tuesday 2026-09-08, before this scan window opened. Listed only because Goldman's newer and higher call above is inside the window and directionally consistent.

No sell-side report, regulator action or senior corporate commentary beyond the above rose to notable within the window.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

**Result: no exit triggered, and no mechanical trigger exists that could fire.**

The book is **12 open tranches across 8 names, all Strategy D**. Strategies A, B, C and E hold no open position. Every one of the 12 carries **NULL `convergence_target` and NULL `time_exit_date`** in `state.current_positions`, so both mechanical limbs are structurally inert for the whole book — stated as a property of the record, not as a passed test.

**UNION SWEEP against the live connector: clean, no reconciliation lag.** `get_account_positions` returns ten lines — the eight held names plus the two park sleeves (VOO 16.2575, SGOV 37.4175). Every share count reconciles exactly against the BigQuery tranches: AMZN 0.1554 + 0.1910 = 0.3464 ✓, DIS 0.2822 + 0.4422 = 0.7244 ✓, GOOGL 0.1534 + 0.1043 = 0.2577 ✓, TSM 0.0891 + 0.0659 = 0.1550 ✓, and GEV / ISRG / RTX / UBER single-tranche exact. **No position exists in the connector that is absent from `state.current_positions`**, so no `position_reconciliation_lag` alert is owed and none is raised.

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` carries two rows. **Strategy D** (as of 2026-09-09): `deployed_unit_value` 1.05306816, `peak_unit_value` 1.098110312, `current_drawdown` −4.1018%, `excess_vs_sgov` +3.8952%, `deployed_days` 94, `gate_n` 29 (gate not reached), all four flags FALSE. **Strategy B** (as of **2026-08-18**, its last marked session): `deployed_days` 79, `closed_trades` 13, `gate_n` 17, all four flags FALSE — the row is legitimately stale, not missing, because B has held no position since that date.

**Unconditional drawdown refresh against today's marks, as required.** Refreshed on the 2026-09-10 IBKR RTH daily-bar closes rather than `get_price_snapshot`, which is the better basis under §19 PRICE BASIS and the 2026-09-07 pin. The D book moved 540.7131 → 539.3579, **−0.2506%** on the session, carrying the deployed unit value to ≈1.050429 and the drawdown to **−4.3421%**. The kill threshold is −50%. **No drawdown kill.**

- **Drawdown kill (#1):** NO — −4.3421% against a −50% bar.
- **Runaway-success (#3):** NO — deployed TWR has not doubled (unit value 1.05).
- **Interim underperformance warning:** `interim_underperf_warning` is FALSE for both strategies. There is **no open `ops.alerts` row in that category**, so no heal-resolution `UPDATE` is owed either.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0` (B holds nothing today), with `avg_offdiagonal_corr` and `min_overlap_days` both NULL. The `n_positions >= 2` term fails, so the check is a no-op and no `b_pairwise_corr_high` alert is raised. Note this is a stricter zero than the standing plan text, which describes B as holding a single position (MDT) — **B's open book is now empty, not one name.**

### JUDGMENT-LADEN THESIS-INVALIDATION CHECK

**Result: no invalidation criterion is met on any of the 12 tranches.**

No Development in this scan touched any of the eight held names with new information. The session was a rates-and-oil repricing and every held name moved inside that channel: AMZN −0.2021%, DIS +1.5742%, GEV −2.8527%, GOOGL +0.5897%, ISRG +2.0439%, RTX +0.2885%, TSM −1.6837%, UBER +2.0822%.

Criterion-by-criterion, the invalidation sets are all fundamental-metric or event-triggered, and none has a test that this session's data could move:

- **AMZN** (both tranches) — AWS revenue YoY, AWS operating margin, AWS backlog, hyperscaler commitments, metric immutability. All quarterly-reported; next test is the Q3 print. Unbreached.
- **DIS** (both) — Entertainment SVOD operating margin, FY26 EPS guide, buyback pace, metric immutability, FCC escalation. The 08-05 tranche records all five affirmatively re-verified at the Q3 FY26 checkpoint (SVOD margin ~13%, third consecutive quarter of expansion; FY26 ~12% adjusted EPS growth reiterated; buyback target *raised* to ≥$9B). Unbreached.
- **GEV** — total-company organic orders growth YoY, entry-quarter reading 88% against a 15% two-consecutive-quarter invalidation floor. Unbreached with a wide margin.
- **GOOGL** (both) — Cloud revenue YoY, Cloud operating margin, Cloud RPO, adverse structural remedy. The 07-26 tranche records all four `unbreached`, with the EU DMA 07-23 ruling noted as behavioral (i.e. not the adverse structural remedy the criterion names). Unbreached.
- **ISRG** — procedure growth, placements, recurring revenue decoupling, competitor displacement at named IDNs. Quarterly. No breach evidence.
- **RTX** — Airbus damages ruling >$2B, a new powder-metal-class quality event >$1B, GTF Advantage EIS slipping past Q1'27, two-quarter backlog decline, FY26 FCF guide below $7.5B, FY27 defence procurement cut ≥10%. None engaged.
- **TSM** (both) — gross margin <55% or USD revenue YoY <15% for two quarters, N2/A16 pushout or sub-7nm share decline, structural AI-capex reset. The 07-29 tranche measured GM 67.7%, USD revenue +33.7% YoY, sub-7nm mix 77% and rising, FY26 capex guide raised to $60–64B. Unbreached.
- **UBER** — gross bookings cc YoY, adjusted-EBITDA margin as a share of GB, Uber One membership, metric immutability. Quarterly. No breach evidence.

**DIVIDEND NETTING: not engaged this session.** The rule binds only where an invalidation criterion names a **price level**. None of the twelve tranches carries a price-level criterion — every criterion above is a fundamental metric or a discrete event, and Strategy D is explicitly a no-stop design (the RTX record even documents that a draft "breaks $130 on heavy volume" criterion was *dropped at entry* as contradicting that design). So `state.price_level_criterion_drift` was not consulted, and that is a scope finding, not an omission.

### WATCHLIST CANDIDATE STATUS

No Development materially changes the candidacy status of any queued name. The Strategy A queue carries `A:FSLR:2026-09-06` as pending; nothing today touches it. The Strategy B new-entry index gains four names (below) and loses none — no window closed today that this run is responsible for.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — verified live this run as **A, B, C, E** (D carries `long_horizon` and is excluded here; all five are `roster_state: adopted`).

**Strategy B — 4 candidates.** B's frozen Entry criterion 1 requires **≥5% close-to-close on the event day** plus a resolved qualifying public event.

| Ticker | Move | `qualifying_event_date` | Why it creates the opportunity |
|---|---|---|---|
| **COO** | −14.6660% | 2026-09-09 | FQ3 revenue miss and FY guide cut with a *named, bounded* mechanism (CooperVision channel destocking) — the cleanest information event of the session |
| **AEO** | −13.9728% | 2026-09-09 | EPS **and** revenue beat with guidance **raised**, yet −14% on a comp-sales miss: the sentiment-vs-information divergence B exists to exploit |
| **NAVN** | −21.7458% | 2026-09-09 | Beat-and-raise met with −21.7% on a widening GAAP loss. **Weakest mechanism fit of the four** — Navan is a recent IPO with no established volatility regime, so float and lockup mechanics are not separable from information here |
| **RDDT** | +6.0776% | 2026-09-10 | Piper Sandler +8% MoM August user-growth data — a discrete, dated, external datapoint rather than a re-rating |

**RDDT identity check, done on the FIELDS and not on the key string.** RDDT already sits in the B new-entry index from **2026-08-25** (+6.3851%, The Information report), a window that has since closed. The four-part identity here is `(thesis-construction, B, RDDT, 2026-09-10)`, which differs from `(…, RDDT, 2026-08-25)` in its `qualifying_event_date`. Per the shared rule, a later **distinct** event in the same ticker must not be suppressed. Not a duplicate.

**Names that cleared 5% and were deliberately NOT routed to B, each with its reason:** ORCL −5.3764% and ADBE −2.3660% (their prints landed after today's close; no resolved information in today's move); INTC −5.5723% (profit-taking is not an event); LRCX −5.6453% and CIFR −5.6805% (sector/complex sympathy with no name-specific event); SCCO −7.2255% and FCX −6.5853% (**continued White House *indecision* on refined-copper tariffs is a non-announcement — there is no discrete resolved event to date the thesis from**, which is what B's four-part identity requires).

**Strategy A — none.** No development in the window named a dated qualifying catalyst within six months on an A-eligible name.

**Strategy C — none, and this is a deliberate suppression rather than an absence.** The 2026-09-15/16 FOMC is inside C's 45-day window and C's router reads `HYBRID ACTIVATE (FOMC-only)`. But the identity check finds `events.queue_events` item **`thesis-FOMC-C-20260908`** (`item_type='thesis-construction'`, `strategy='C'`, `ticker='FOMC'`, `due_date=2026-09-08`) already in terminal status **`complete`**. Re-flagging the same FOMC would duplicate a finished item. Independently, W5's open `strategy_c_criterion2_unreached_pattern` alert records that C has now failed FOMC entry criterion 2 on **five consecutive drains** — so a sixth identical flag would be adding queue traffic to a pattern already under review. **Recorded because the 2026-09-09 run flagged this same FOMC as a new C candidate one day *after* the item completed;** D2 correctly de-duplicated it, so nothing was lost, but the flag should not have been raised and is not raised again here.

**Strategy E — none.** The session's most striking divergence is XLE −0.58% against Brent +6.34%, but that is commodity-versus-equity, not the **intra-industry-group** pair divergence E requires. Within the copper complex FCX −6.59% and SCCO −7.23% moved together, which is convergence, not divergence. AAPL +3.56% against the semiconductor complex is a real divergence but spans different GICS industry groups. No clean E pair surfaced.

**Router activation context, stated so the candidates are not misread as entries.** `state.current_regime` (as of 2026-09-03) carries A, B, D and E at **DO-NOT-ACTIVATE** and C at HYBRID ACTIVATE (FOMC-only). The four B candidates above therefore queue for thesis construction; the activation gate is D2's to apply and is not relaxed by anything in this file.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

**Result: 12 tranches evaluated, 0 flagged, 3 declined at the HARD GATE.** Logged in full — including every decline — as `events.decision_log` entry_id **`7c37f5c2-ec5f-462f-8ac9-c938116250fa`** (`entry_type='add-candidate-review'`).

All 12 open tranches are Strategy D; A and B hold nothing, so the A/B/D scope reduces to D.

**Price basis, per the 2026-09-07 pin.** Each `mark_vs_cost_pct` below uses the 2026-09-10 IBKR **regular-session** daily-bar close over that **tranche's own** `cost_basis / shares` — never the account-level blended `average_price`. That matters again today: `get_account_positions` served **AMZN at 252.20** and **GOOGL at 331.80** against true 09-10 closes of **251.89** and **332.60** — wrong in *both directions* on the same account read. A fresh instance of exactly the defect the pin records.

| Tranche | `mark_vs_cost_pct` | Session | Disposition | Evaluable |
|---|---|---|---|---|
| D:RTX:2026-04-27 | **+11.9962%** | +0.2885% | `declined_hard_gate` | false |
| D:TSM:2026-07-29 | +8.9459% | −1.6837% | declined | true |
| D:AMZN:2026-07-09 | +4.4129% | −0.2021% | declined | false |
| D:ISRG:2026-07-20 | +3.1328% | +2.0439% | `declined_hard_gate` | false |
| D:DIS:2026-08-05 | +1.9604% | +1.5742% | declined | true |
| D:GOOGL:2026-07-26 | +1.4508% | +0.5897% | declined | true |
| D:TSM:2026-07-21 | +0.0394% | −1.6837% | declined | false |
| D:UBER:2026-07-09 | −0.8842% | +2.0822% | `declined_hard_gate` | false |
| D:GEV:2026-08-03 | −4.7423% | **−2.8527%** | declined | true |
| D:DIS:2026-05-07 | −4.9399% | +1.5742% | declined | false |
| D:AMZN:2026-07-30 | −5.1951% | −0.2021% | declined | true |
| D:GOOGL:2026-07-09 | **−7.5722%** | +0.5897% | declined | false |

**HARD GATE.** Seven tranches carry `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'` and therefore report `invalidation_criteria_evaluable = false` under the **third disjunct** (added 2026-09-06): D:AMZN:2026-07-09, D:DIS:2026-05-07, D:GOOGL:2026-07-09, D:ISRG:2026-07-20, D:RTX:2026-04-27, D:TSM:2026-07-21, D:UBER:2026-07-09. Not one of the twelve carries a `$.status` key at all, so the two-disjunct form would have returned `true` for every position — the inversion that bullet exists to prevent. **Four** of the seven are covered at NAME level by a later tranche carrying a fresh assessment (AMZN by 07-30, DIS by 08-05, GOOGL by the 07-26 tranche whose `a_`/`b_`/`c_`/`d_` keys all read `unbreached`, TSM by 07-29), so the gate *can* affirmatively confirm unbreached for the name and these are ordinary declines. **Three are covered nowhere in the record — ISRG, RTX, UBER — and are structurally ineligible for an add.** This is the third consecutive sweep to record the same three; it is now a standing condition of the record rather than a finding of this run.

**Why zero flagged.** No Development touched any held name with new information, so neither add trigger is available. The two deepest tranche drawdowns, D:GOOGL:2026-07-09 (−7.5722%) and D:AMZN:2026-07-30 (−5.1951%), both saw their underlying **rise or barely move** today — a carried drawdown is not a dip-with-intact-thesis. **GEV is the only genuine same-session dip of size** (−2.8527%, −4.7423% against cost, thesis reading 88% against a 15% floor) and it is declined for the reason that actually applies: **no driver was identified**, so "dip against an intact thesis" and "the market knows something" are indistinguishable from the evidence in hand. Adding equity risk in the strategy book on the same evening the park de-risks would also need a reason, and there is not one.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar; default-NO on ambiguity holds.

A single session of SPY −0.60% with oil and yields higher does not plausibly shift any strategy's activation state. The `FUNDAMENTAL_AXIS` already carries `shock_overlay: acute`, so today's escalation deepens a condition the router has already priced rather than introducing a new one, and the other four axes (decelerating growth, disinflating, hawkish, risk-on) are untouched by one session.

**One watch item, recorded and explicitly not escalated:** equity breadth has fallen **60.63 → 56.85 → 54.67** in three sessions, −5.96pp. The `TECHNICAL_SIGNAL` `EQUITY_BREADTH` still read HEALTHY at 56.85. Applying the HEALTHY/WEAK threshold is **D2a's** job, not D1's — D1 observes, D2a classifies — so this file records the observation and the trajectory and leaves the classification alone. If D2a flips that key, the router review question belongs to that flip, not to this scan.

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events`, `as_of_date = 2026-09-10`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `numeric_value = 54.67`, `value='Barchart $S5TH'`.** Idempotency verified before the write (no prior row on that key for this date).

- **Primary: Barchart `$S5TH`**, https://www.barchart.com/stocks/quotes/$S5TH?cb=20260910 via `tavily_extract` (advanced, cache-busted). Page header verbatim: *"Quote Overview for Thu, Sep 10th, 2026"*; quote line `54.67 −2.18 (−3.83%) 17:05 ET [INDEX]`; Previous Close 56.85. **Source-dated, not inferred** — the page names its own session and the 17:05 ET stamp is post-close, so the `date_attribution=inferred_post_close` fallback was not used and is not claimed.
- **Second independent source obtained — EODData, exact agreement.** https://www.eoddata.com/stockquote/INDEX/S5TH.htm?cb=20260910, historical table row "10 Sep 26": Open 55.66, High 55.86, Low 52.88, **Close 54.67**, PREV 56.85. A **0.00pp** match on both the close and the prior reading. This run has **two** usable sources, not one, so no single-source disclosure is owed. The >5pp disagreement rule is not engaged.
- **The EODData unsettled-value tell was observed and correctly rejected.** That page's *header quote block* separately showed `LAST 53.47` stamped `10 Sep 26 15:55` — pre-16:00 ET, and disagreeing with the page's own settled table row for the same date. The 53.47 was discarded and the dated end-of-day row used.
- **No overnight settlement revision this session.** Barchart's Previous Close reads 56.85, which equals exactly the value D1 stored for 2026-09-09. Nothing is owed to today's rationale on that account, and no prior row was retroactively corrected (the idempotency rule is unchanged and was not touched).
- **MacroMicro deliberately not attempted.** Under the 2026-09-06 W5 ruling it is a **weekly, Sunday-anchored** re-probe, not a per-run first attempt. Today is Thursday, so no probe was due and skipping it is compliance, not a missed source. Barchart is the declared primary and answered on the first call.

---

## PARK ALLOCATION CALL

Logged as `events.decision_log` entry_id **`a383d21d-f59a-4798-a3ae-3a571aff49c4`** (`entry_type='park-allocation'`); heartbeat written to `ops.heartbeat` (`loop:park_allocator`). `state.park_allocation_latest` confirms the row surfaces to D2 with `status='BOUND'`, `target_f_pct=50`, `is_call=true`.

- **`vehicle`** — **VOO** (the majority sleeve; at f=50 the tie resolves to the **risk** sleeve. This is *not* a claim that the book is single-vehicle).
- **`target_f_pct`** — **50** (risk sleeve VOO 50% / defensive sleeve SGOV 50%), up from a policy 25 and an actual 24.9264%. **Direction: de-risk. Status: BOUND.**
- **`conviction`** — **MEDIUM**, `conviction_pct` **55**.
- **`rationale`** — The runner-up is KEEP at 25, and it has real arguments: the index crossing is only 0.0548% deep, credit is actively risk-**on**, the drawdown is an ordinary −2.58%, and this allocator's measured record is bad (0-for-2 on AI-era defensive excursions at −2.841pp and −1.019pp; −0.638pp mean forward edge across 15 historical episodes, 4 wins in 15; the 2026-09-01 single-axis de-risk cost a measured $214.32 round trip). KEEP loses on one point, and it is decisive: **the direction of travel is unambiguous, and answering that proportionately is the whole reason this ladder replaced the binary switch.** Since f went 0 → 25 on 09-08, every axis then standing has *deepened* — VIX 15.72 → 17.84, breadth 60.63 → 54.67, Brent 99.39 → 107.63 — and a **fourth has joined**. Holding at 25 through a strictly worse reading on every input would make the ladder a one-step switch again. One step to 50 is what its own arithmetic returns without being pushed.
- **`invalidation`** — **Symmetric by construction, and deliberately single-limb because the increase was carried by a single-limb case.** A step back toward f=25 or lower needs evidence of the same *kind* and *weight* in the other direction, and **any one** of these, judged in the round, is enough — do **not** require a conjunction: (a) SPY reclaims and holds its 50-day SMA with breadth turning up off 54.67; **or** (b) the Hormuz supply channel visibly de-escalates with Brent retreating under 95; **or** (c) the 09-11 CPI and the 09-15/16 FOMC resolve benignly enough to take the rate channel off the table, with VIX falling back through its own 20d SMA. Equally, the increase should be re-examined on its own terms next session: it rests on a 0.0548% index crossing, and if SPY closes back above its 50dma with nothing else changed, the fourth axis is gone and 25 is again the ladder's answer. No later session is bound by any of this.
- **`theater_check`** — The rationale names the axis that **refuses to confirm** (credit, +0.5561% *above* its 20d SMA) and states that the axis carrying the entire increase crosses by 0.0548%. It also states the record that argues against the action taken. The conviction is 55 **because** of those two, and 55 is what produced 50 rather than 75 — if the number had been reverse-engineered from a desired f, 0.75 × 100 would have been the easier arithmetic to write.

### Ladder arithmetic (stated, as required)

Hand-scored `standing_defensive_count` = **4** → raw cap = `LEAST(100, 25 × 4)` = **100**. **Decay:** the confirmed cap steps down only on the first session at which a *lower* standing count has already held on the two preceding measured sessions; the count **rose** this session (3 → 4), so no step-down is pending and the confirmed cap equals the raw cap at **100**. The clamp is therefore non-binding (50 ≤ 100). **Conviction sizes it:** 0.55 × 100 = 55; the nearest step in {0, 25, 50, 75, 100} is **50** (|55−50| = 5 against |55−75| = 20). No ±1-step deviation taken. **Crisis override not engaged:** session index move −0.5994% (bar −2.5%), VIX 17.84 (bar 28).

### The five testable axes, measured this session

| Axis | Verdict | Reading |
|---|---|---|
| **index** | **DEFENSIVE — ENTERED TODAY** | SPY 757.83 < 50dma **758.2458** (by 0.4158pts, **0.0548%**); dd −2.5775% does **not** clear the −3% limb |
| volatility | defensive, standing, deepening | VIX **17.84** > 20d SMA **15.3360** and > 15; entered 09-09 at 16.46 |
| breadth | defensive, standing, deteriorating fastest | **54.67** < 66; −5.96pp over three sessions; entered 09-08 |
| shock | defensive, standing, both limbs | `shock_overlay='acute'` **and** Brent **107.63** > 95 |
| **credit** | **NOT defensive — the honest counterweight** | HYG/IEF **0.8622505** vs 20d SMA **0.8574818** = **+0.5561%**; the test needs **−0.50%** |
| rates | untestable by construction | No daily 10Y series reachable (FMP economics plan-gated) |

Credit did not merely fail to confirm — it **improved**, because IEF (−0.77%) fell harder than HYG (−0.46%) on the rate move. In a genuine risk event credit leads, and it is not leading. That, plus the absence of any safety bid (gold −1.73%, TLT −1.16%, dollar +0.18%) and a cross-sector spread of only 2.02pp, is why this is MEDIUM 55 and not HIGH. The **rates** axis is worth naming twice: the session's dominant macro fact — the 10Y at its highest since November 2023 — lives on precisely the axis the panel cannot see.

### Axis overrides — the mechanical panel disagrees, and this is the case the rule anticipates

`state.park_axis_daily` for 2026-09-10 reports `standing_defensive_count = 3`, `firing_count = 0`, `cap_pct = 75`, `increase_gate_open = FALSE`. Its four price-derived axes all carry `measured_on = 2026-09-09` (`sessions_since_measured = 1`), because D2a — which writes `events.signal_marks` — does not run until after D1; only `breadth` is same-session, and only because D1 wrote it minutes earlier.

Per the **MIXED VINTAGE** rule, the mechanical count may **not** block or demote a de-risk on an axis whose `measured_on` is not today; a stale quiet must not veto observed deterioration. The **ratchet holds the other way and is respected**: no carried axis is counted as FIRING here — the single firing axis is `index`, measured live today. Recorded in `fields.axis_overrides`: index (mechanical *not defensive* @09-09 vs live **DEFENSIVE and ENTERING** @09-10), standing count 3 → 4, firing count 0 → 1, gate FALSE → TRUE, cap 75 → 100. **Credit is recorded as an explicit non-disagreement** — re-measured live, and it agrees with the mechanical panel.

**Cardinality floor: satisfied.** The 2026-09-03 DE-RISK EVIDENCE CARDINALITY rule is superseded as the *sizing* rule by the graded ladder and retained as its **floor** — a single *standing* axis licenses no increase. Standing count is 4, so the floor clears with room, and the ladder's own gate (≥1 axis entered within 2 sessions **and** standing ≥ 2) is the operative test.

**Forward test context, stated because it does not flatter this call.** The ladder is a running forward test, not a settled system: over 15 historical episodes the defensive signal had mean forward edge −0.638pp and won 4 of 15, and both AI-era defensive excursions lost. Read as: grading beats the all-or-nothing switch, and de-risking at all still costs against simply holding VOO. That is the reason for MEDIUM 55, and W5's PARK FORWARD-TEST COUNTDOWN forces the re-evaluation after three post-activation episodes.

---

## RECOMMENDED ACTIONS

- **Exits triggered:** none.
- **New entry candidates (full thesis construction required in separate sessions per Strategy.md):**
  - **COO — Strategy B.** −14.6660% close-to-close (63.48 → 54.17, IBKR RTH daily bars, contract 685217803) on the FQ3 print released 2026-09-09 after the close: revenue $1.066B vs ~$1.098B consensus with FY guidance cut on CooperVision channel destocking. Clears B Entry criterion 1. `qualifying_event_date` **2026-09-09**.
  - **AEO — Strategy B.** −13.9728% close-to-close (16.89 → 14.53, IBKR RTH daily bars, contract 4725951) on the Q2 print released 2026-09-09 after the close: EPS **and** revenue beat with FY guidance **raised**, met with −14% on a comparable-sales miss. Clears B Entry criterion 1. `qualifying_event_date` **2026-09-09**. **Cap caveat:** FMP `profile-symbol` returns $2.44B, inside the ~30% band where the implied share count is unreliable — second-source the cap during thesis construction.
  - **NAVN — Strategy B.** −21.7458% close-to-close (25.89 → 20.26, IBKR RTH daily bars, contract 827263725) on the FQ2 FY2027 print released 2026-09-09: beat and raised outlook met with −21.7% on a widening GAAP operating and net loss. Clears B Entry criterion 1. `qualifying_event_date` **2026-09-09**. **Weakest mechanism fit of the four** — recent IPO, no established volatility regime, float and lockup mechanics not separable from information.
  - **RDDT — Strategy B.** +6.0776% close-to-close (146.44 → 155.34, IBKR RTH daily bars, contract 692025016) on Piper Sandler data showing +8% MoM August user growth. Clears B Entry criterion 1. `qualifying_event_date` **2026-09-10**. Distinct from the 2026-08-25 RDDT event (window closed); identity checked on the fields, not the key string.
- **Add candidates:** none. 12 open Strategy-D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER).
- **Watchlist updates:** ADD COO, AEO, NAVN, RDDT to the Strategy B new-entry-candidate index. No removes, no demotions.
- **Router reviews recommended:** none.

```yaml d1_actions
- action: thesis
  ticker: COO
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: 7d717e9f-c609-4166-8487-e965a2faff13
  detail: -14.6660% close-to-close (63.48 -> 54.17, IBKR RTH daily bars, contract 685217803) on the 2026-09-09 after-close FQ3 print - revenue $1.066B vs ~$1.098B consensus, FY guidance cut, CooperVision channel destocking. Clears B Entry criterion 1.
- action: thesis
  ticker: AEO
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: 7d717e9f-c609-4166-8487-e965a2faff13
  detail: -13.9728% close-to-close (16.89 -> 14.53, IBKR RTH daily bars, contract 4725951) on the 2026-09-09 after-close Q2 print - EPS and revenue beat with FY guidance raised, met with -14% on a comp-sales miss. Clears B Entry criterion 1. CAP CAVEAT - FMP profile-symbol $2.44B is inside the ~30% band; second-source the cap.
- action: thesis
  ticker: NAVN
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: 7d717e9f-c609-4166-8487-e965a2faff13
  detail: -21.7458% close-to-close (25.89 -> 20.26, IBKR RTH daily bars, contract 827263725) on the 2026-09-09 FQ2 FY2027 print - beat and raised outlook met with -21.7% on a widening GAAP loss. Clears B Entry criterion 1. Weakest mechanism fit of the four - recent IPO, no established volatility regime.
- action: thesis
  ticker: RDDT
  strategy: B
  qualifying_event_date: 2026-09-10
  source_research_screen_id: 7d717e9f-c609-4166-8487-e965a2faff13
  detail: +6.0776% close-to-close (146.44 -> 155.34, IBKR RTH daily bars, contract 692025016) on Piper Sandler data showing +8% MoM August user growth. Clears B Entry criterion 1. Distinct from the 2026-08-25 RDDT event whose window has closed - identity checked on the fields, not the key string.
- action: watchlist
  ticker: n/a
  strategy: B
  qualifying_event_date: n/a
  source_research_screen_id: 7d717e9f-c609-4166-8487-e965a2faff13
  detail: ADD COO, AEO, NAVN and RDDT to the Strategy B new-entry-candidate index. No removes and no demotions this session.
```

---

## PROCESS NOTES

- **Frontier-LLM capability check: run, silent, no capture.** One Hugging Face `hf_fs` paper search on the Thursday battery (sycophancy / anchoring). All five results published between 2024-12 and 2025-11 — none since the scan-window start — so nothing qualified for the abstract skim, no `[HF Frontier-LLM Capture]` entry was written and no `state.strategy_candidates` row was emitted. Default-silent on ambiguity, as specified.
- **Two out-of-scope findings recorded rather than fixed**, each naming its owning surface, per this run's standing rule:
  1. `ops.alerts` info, category **`screen_surfaced_count_header_contradicts_pin`** — `bigquery/96_research_screener.sql`'s fields-JSON schema comment still documents `surfaced_count` as the Layer-1 population size, the exact reading the 2026-08-30 pin overturned. Comment-only divergence; no view logic is wrong and no landed row is affected. Both of this run's screens were written to the **pin**, and `state.research_screen_calls` confirms `surfaced_count == ARRAY_LENGTH(passed)` on both.
  2. `ops.alerts` info, category **`hy_oas_not_refreshed_by_last_m1a`** — the 2026-09-01 M1a run completed and refreshed 12 of the 15 metrics in `state.macro_fred_latest`, but **`hy_oas` was not among them** (newest `fetched_ts` 2026-08-05; `fed_funds` 2026-08-03), leaving `hy_oas` at `ref_month` 2026-07-01. Consistent with the already-documented Tavily-extract timeouts against both sanctioned FRED paths. It matters because `hy_oas` is a *named* evidence input in this section's own step; it is **not** a park defect today, because the credit axis reads HYG/IEF and this run's park record labels `hy_oas` STALE and excludes it from the decision.
- **FIELDS-JSON KEY CONTRACT verified after writing, not assumed.** `state.research_screen_calls` for 2026-09-10 returns 16 `passed` + 7 `rejected_notable` single-name item rows and 6 sector item rows, with `name`, `metric_pct` and `conviction_pct` populated on **100%** of them, and the agreement columns populated from the **nested** `"agreement": {...}` object (10 / 6 / 0 and 0 / 6 / 0). The W2 `screen_fields_schema_drift` failure mode is closed for this run.

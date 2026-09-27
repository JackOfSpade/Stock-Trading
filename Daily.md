2026-09-27
<!-- d1_scan_through_utc: 2026-09-27T22:05:00Z -->

# Daily Market Development Scan — 2026-09-27 (Sun, MT)

Scan window: 2026-09-24 16:21 MT → 2026-09-27 16:05 MT (**71.7h — a multi-session gap, stated explicitly per the >50h rule**; resolved from the prior `Daily.md` marker `2026-09-24T22:21:24Z`, cross-checked against that file's commit at 2026-09-24T22:26:13+00:00 — agree to 5 min — and against `state.routine_catchup_window` `window_days = 2.98`). The gap is **cadence-normal, not a missed run**: D1 fires Sun–Thu, so Friday and Saturday have no scheduled fire and Sunday's run always carries Friday's session. Exactly **one completed US trading session** sits inside the window — **Friday 2026-09-25** (`state.market_calendar`: 09-26 and 09-27 both `is_trading_day = FALSE`). Thursday 09-24's session closed *before* the window opened, so Thursday's **after-hours** releases are in-window while Thursday's price action is not. No `CATCHUP` token owed.

Tape: **the bond market made another multi-decade high intraday and equities bought the diplomacy instead.** S&P 500 **7,743.41 (+0.51%)**, Nasdaq Composite **27,068.72 (+0.48%, a record close)**, Dow **51,828.62 (+0.93%)**. On IBKR RTH closes SPY 767.18 → **771.35 (+0.5436%)**, VOO 706.99 → **710.79 (+0.5375%)**. The 10Y touched **5.225%** intraday (reported highest since 2007) and the 30Y **5.502–5.525%** (reported highest since 2004), yet both eased into the close — 10Y ~**5.17%** (*down* 1bp on Thursday), 30Y ~**5.50%**. Brent settled **$104.32 (−2.14%)** and WTI **$92.41 (−2.33%)** on reports of US–Iran talks toward a phased Strait of Hormuz reopening; **VIX 14.87 (−5.11%)**; spot gold ~**$4,288–4,298**. An index that rises half a percent while the long end prints a 22-year high is a tape that has decided the rate move is not the binding constraint this week.

## TL;DR

- **Exits triggered: none.** Twelve open tranches, all Strategy D; not one carries a `convergence_target` or a `time_exit_date`, so no mechanical trigger exists to fire, and no Development touched any thesis criterion.
- **New entry candidates: none routed.** B is `DO-NOT-ACTIVATE` and capital-disabled at NAV $0.00, so the five names that clear its frozen ≥5% floor on a resolvable anchor go to the index only.
- **Add candidates: none (0 of 12).** Nine declined on the merits, three blocked at the HARD GATE (ISRG, RTX, UBER) for the fifth consecutive cycle.
- **Watchlist: 5 changes — ADD ZS, PPLI, VIAV, TWLO, DELL** to the Strategy B new-entry index, each anchored on its own resolved event date.
- **Regime review: no review.** Breadth improved for the first time in four sessions but at 46.52 is still below the 50 HEALTHY/WEAK line; one improving session is not a trend, and nothing else moved structurally.

> **NOTE (not a bullet, and deliberately not a `d1_actions` entry): PARK ALLOCATION CALL — KEEP VOO, `target_f_pct` 0, BOUND, MEDIUM 65.** D2 reaches this through `state.park_allocation_latest`, never through prose or the action block. See `## PARK ALLOCATION CALL` below — the call turned on overriding a mechanical increase gate that was reading Thursday's VIX on a Friday row.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **US–Iran diplomacy on the Strait of Hormuz became the session's proximate driver.** Reports Friday morning that negotiators meeting in New York were discussing a phased deal to end the Persian Gulf standoff; Iran's foreign minister later confirmed a seven-day reopening plan. This pulled crude down from Thursday's spike and was cited by multiple outlets as the cause of the equity rally. Brent −2.14% to $104.32, WTI −2.33% to $92.41. ([WSJ live coverage](https://www.wsj.com/livecoverage/stock-market-today-dow-sp-500-nasdaq-09-25-2026), [CNBC live blog](https://www.cnbc.com/2026/09/24/stock-market-today-live-updates.html))
  - **A source-data correction worth recording rather than absorbing:** CNBC's own live blog printed "Brent crude for November delivery declined 1% at **$93.66**" and "WTI futures for November dropped 0.68% at **$105.86**" in the same paragraph — the labels are **swapped**. Brent trades above WTI, and $93.66 cannot be reconciled with Thursday's ~$106.80 Brent. Resolved against Trading Economics' dated Sep/25 table (Brent 104.32, WTI 92.41) and corroborated by an oilprice.com same-day piece on the spread widening to ~$12: 104.32 − 92.41 = **11.91**, which reconciles. The figures used throughout this file are the resolved ones.
- **The global long-end selloff extended intraday and then reversed into the close.** 10Y 5.225% intraday and 30Y 5.502–5.525% intraday, both characterised by their sources as multi-decade highs, but the closes were ~5.17% and ~5.50% — the 10Y finished *below* Thursday. Coverage ties the move to a global phenomenon rather than a US-specific one, including French fiscal risk (Fitch citing debt to 119.3% of GDP). ([Yahoo Finance](https://finance.yahoo.com/markets/stocks/articles/stock-market-today-sept-25-134126022.html), [Asia Times](https://asiatimes.com/2026/09/bond-vigilantes-on-a-savage-hunt-as-global-yields-run-wild) — the latter secondary, not government data)
- **Trump–Xi state dinner, White House, Thursday evening 09-24** — ~130 guests including Jensen Huang and Elon Musk, 27 CEOs attending; agreements on some student visas and additional US–China flights, described as light on policy. Timing straddles the window's 18:21 ET open. Secondary sourcing only; no primary transcript checked.
- **Reported but NOT corroborated, and flagged as such:** a single secondary outlet reports Colombia severing diplomatic relations with Iran on 09-25 with a Colombian peso reaction. One source, no wire-service confirmation found. Recorded at low confidence rather than dropped or dressed up.
- **No bankruptcy, disaster or enforcement action** materially affecting global risk assets was identified inside the window.

### 2. Scheduled events that resolved in the window

**Earnings — EVENT-IDENTITY GATE applied, and it changed an answer.**

- **COST — Costco, fiscal Q4 and full-year 2026** (Q4 = 16 weeks ended 2026-08-30). **ISSUER-SOURCED**: `investor.costco.com` datelines the release "ISSAQUAH, Wash., Sept. 24, 2026" and schedules the call for "2:00 p.m. (PT) today" = **17:00 ET, after the close**. Q4 net sales **$93.9B, +11.2% YoY**; FY net sales **$297.2B, +10.1%**; Q4 diluted EPS **$6.75** against $5.87 prior year; FY diluted EPS **$20.76** against $18.21 — including a non-recurring **$0.15/share IEEPA tariff-refund benefit**. Anchor **2026-09-24**; Friday is the reaction session, **+2.9311%** (896.48 → 922.76, IBKR RTH bars).
  - **Two corrections to this routine's own prior-cycle prose, recorded rather than carried forward.** The 2026-09-24 `Daily.md` put this release at "~16:15 ET" — the issuer's own page puts the call at 17:00 ET — and stated "revenue **$93.87B vs $94.97B** (miss)". Costco's release states net sales of $93.9B **up 11.2%** and **states no consensus figure at all**. The consensus comparison is not issuer-sourced and is not asserted here. Neither correction changes any verdict; both are recorded because an unsourced "miss" attached to a record quarter is the kind of thing a later reader inherits as fact.
- **BB — BlackBerry, fiscal Q2 2027** (three months ended 2026-08-31). **ISSUER-SOURCED**, from the SEC 8-K exhibit fetched directly: the dateline reads "today reported financial results for the three months ended August 31, 2026" and the call is "today beginning at **8:00 a.m. ET**", which places the release **pre-market Thursday 2026-09-24**. Revenue **$163.3M, +26% YoY** with record QNX revenue; adjusted basic EPS **$0.07**. The release states no consensus, so the widely-quoted "$0.07 vs $0.04" beat is **not issuer-verified** and is reported as secondary. **This is the anchor finding of the run — see §3.**
- **SCHL — Scholastic, fiscal Q1**: adjusted loss **$3.63/share** against $2.52 a year ago, revenue **$216.8M (−4% YoY)**, shares −7.12%. Below the $2B cap rail. ([CNBC midday movers](https://www.cnbc.com/2026/09/25/stocks-making-the-biggest-moves-midday-akam-geni-ppli.html))
- **No other ≥$2B name had a primary-sourced earnings print land specifically on Friday 09-25.** Friday is structurally a thin earnings day and this is stated as a measured absence, not an assumption.

**Economic data — one confirmed, three explicitly unresolved.**

- **University of Michigan Consumer Sentiment, FINAL September — CONFIRMED, released Friday 2026-09-25 ~10:04 ET.** **PRIMARY SOURCE**: [University of Michigan Surveys of Consumers](https://www.sca.isr.umich.edu), "Final Results for September 2026". Index of Consumer Sentiment **48.1** (August 51.7, **−7.0% m/m**; September 2025 55.1, **−12.7% y/y**); Current Economic Conditions **50.9** (−1.9% m/m); Index of Consumer Expectations **46.3** (**−10.1% m/m**). A materially weak print, and the one hard macro datum of the window. A secondary framing that 48.1 sits "below every past recession" reading was found and is **not** repeated as fact — the 48.1 figure is primary, the characterisation is not.
- **Initial jobless claims** and **new home sales** were released **Thursday 2026-09-24**, i.e. *before* the window opened at 18:21 ET, and are correctly excluded. (The 2026-09-24 file recorded all three as PENDING; two of the three are now known to have landed on that Thursday and thus fall outside this window in either direction.)
- **Durable goods orders** and **PCE / personal income & outlays: NOT CONFIRMED as having been released on 09-25 at all.** Multiple wide searches returned no BEA or Census primary-source hit. No figures are reported. A calendar date is a schedule, not evidence of a release, and an honest "did not establish" is the entry here.
- **FOMC / Fed speakers: none identified with market-moving content inside the window.** The standing policy fact still driving the tape is the 2026-09-16 hike to 3.75–4.00%, not a new Friday event.

**FDA — resolved against the FDA's own pages, per the PDUFA limb.**

- **MRK + Eisai — WELIREG (belzutifan) + LENVIMA (lenvatinib) APPROVED for advanced ccRCC with a clear-cell component.** **CONFIRMED on the FDA's own approvals page**, which states "On September 24, 2026, the Food and Drug Administration approved…" ([fda.gov](https://www.fda.gov/drugs/resources-information-approved-drugs/fda-approves-belzutifan-combination-lenvatinib-advanced-renal-cell-carcinoma-clear-cell-component)). **Sponsor and status both resolved against the FDA, not an aggregator.** A date ambiguity is flagged rather than smoothed: the FDA dates the action 09-24, while **Merck's own release is timestamped 2026-09-25 06:45 EDT** — so the market-moving disclosure landed Friday morning even though the regulatory action is dated Thursday. Approved ahead of its own 2026-10-04 target action date, on Phase III LITESPARK-011. MRK moved **+0.5406%**.
- **AZN — Imfinzi + enfortumab vedotin: NOT an approval.** This is FDA *acceptance* of the sBLA with Priority Review for muscle-invasive bladder cancer, announced 2026-09-25; the PDUFA target is "during the fourth quarter of 2026" and remains **FORWARD-LOOKING**. Recorded as PENDING with no outcome figures.
- **PENDING, unresolved in window:** BridgeBio — Attruby, PDUFA on or before 2026-11-27. Capricor — deramiocel (DMD), PDUFA extended to 2026-11-22 (the extension itself was announced 2026-08-24, no new in-window action). Cytokinetics — aficamten MAPLE-HCM sNDA, PDUFA 2026-11-14.
- **AGGREGATOR TRAP CAUGHT AND EXCLUDED.** A Benzinga calendar row dated 09-25 07:02 describes Ocugen's OCU400 receiving "provisional approval and priority designation from the **LARTA Board**" — LARTA is a regulatory body of the Commonwealth of The Bahamas, **not the FDA**. Excluded from the FDA list and recorded here so the row is not mistaken for a US action next cycle. Separately, the two rows this limb exists to guard — **NUVL/zidesamtinib** (approved 2026-07-22 to Nuvalent, not GSK) and **IONS/zilganersen** (approved 2026-09-03) — were specifically checked for and did **not** reappear in this window's aggregator output. No corrective action owed.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Decision record: `events.decision_log` `b15a5838-419b-4899-85ca-7542c1c3a34d` (`entry_type='research-screen'`, `screen='single-name-move'`). **42 names measured**, 23 moved ≥2%, **8 surfaced**, `rail_tally` 12, `agreement` {both 5 / ai_only 3 / rule_only 5}. Every figure from IBKR `get_price_history` (`step='ONE_DAY'`, `outside_rth=false`), read from the **`close` array at both ends**, all bars stamped `13:30:00Z`.

**THE FINDING OF THE RUN: the anchor convention flipped a SIGN, not just a magnitude.**

**BB — BlackBerry. Anchor 2026-09-24, and criterion 1 must be tested on THURSDAY.** The issuer-sourced timestamp above puts the print **pre-market Thursday**. A pre-open release on session S anchors on S *and is tested on S*. So the qualifying move is Wednesday close → Thursday close: **8.38 → 8.73 = +4.1766%**, which **misses Strategy B's frozen ≥5% floor by 82bp**. The figure the discovery leg handed up — **−5.9565%** (8.73 → 8.21) — is the Thursday→Friday move, i.e. the *second* session, which the convention forbids testing. The spec's own worked precedent (MSTR, 2026-09-20) turned a 3.3× clearance into a 19bp failure; **this one flips the sign**: the market's actual answer to the print was a **+4.18% gain**, and the −5.96% is Friday handing it back. Recording Friday's figure would have entered BB into the durable record as a ~6% post-earnings *decline* when the event-day reaction was positive. Volume corroborates the issuer timestamp independently and was not needed to reach it: **38,015,942** shares on 09-24 against 20,705,975 on 09-23 (**1.84×**) marks Thursday as the event day. `below_spec_floor = true`. Conviction 75 — on the anchor work, not on the magnitude.

**FIVE OF ELEVEN ≥5% MOVERS CANNOT BE ANCHORED, AND ARE RECORDED `UNRESOLVED` RATHER THAN DEFAULTED.** Each of these has a real dated event behind its recent strength, and in every case the event is **three or more sessions before this window**:

| Ticker | Move (Fri) | Nearest dated event | Why UNRESOLVED |
|---|---|---|---|
| BE | **+8.2711%** | S&P 500 inclusion effective **2026-09-21** | No BE release or filing dated 09-24/09-25; reads as continued index-flow and PT-hike momentum |
| CRDO | **+7.6542%** | Mizuho PT cut to $245 (09-20/21); ECOC 2026 Málaga (09-21..09-23); Q1 FY27 print (09-01 AMC) | All three pre-date the window; Friday coverage describes momentum, not a catalyst |
| GNRC | **+5.0947%** | $8B Amazon generator supply deal, **2026-09-17** | See below — the instructive case |
| SBSW | +3.2101% | H1 2026 results 2026-09-01; one undated PT **cut** | Undated thematic platinum strength; a PT cut cannot explain a positive move |
| INTC | −3.4461% | none found | Attributed by coverage to pre-weekend profit-taking after a multi-week rally, which is not a public event |

**GNRC is the case worth dwelling on, because a dated in-window event *does* exist and is still not the anchor.** A real nor'easter arrived, with NWS High Wind and Coastal Flood products confirmed **issued 2026-09-24** — inside the window. And not one source credits the storm as GNRC's Friday driver; coverage attributes the move to continued institutional reaction to the 09-17 Amazon deal (Wells Fargo, JPMorgan, Canaccord and Cantor all raising targets in the days after). **A dated event that happens to sit inside the window is not thereby the anchor.** Recorded UNRESOLVED.

Also UNRESOLVED and recorded in `rejected_notable`: **META −3.3348%** (nearest dated events are the Meta Connect conference dates 09-23..09-24, and Deutsche Bank *raised* its target to $820 the same Friday morning — pointing opposite to the move), **CRWV −2.8181%** (CEO Form 4 sales 09-22, Redburn initiation and SemiAnalysis ClusterMAX 09-23), **IREN −4.3878%** (Redburn Neutral/$40 initiation 09-23), **EQIX −2.5785%** (nothing dated; the nearest is a 09-21 upgrade to Strong Buy, pointing the wrong way).

**ZS — the cleanest Strategy-B mechanism shape on the board. −10.0587%** (214.64 → 193.05), market cap **$31.22B**, anchor **2026-09-24**, reaction session 09-25. A **Form 8-K Item 5.02** filed 09-24 discloses the Chief Revenue Officer stepping down for personal reasons effective 10-01, with the head of worldwide sales promoted and the departing officer retained as an adviser through year-end; secondary reporting places the break after Thursday's close. A leadership transition of that shape is **not a change in the business's earning power**, and the market repriced a $31B company by ten percent on it — the sentiment-versus-information divergence Strategy B exists to trade. Conviction **75**. Index-only regardless (B router `DO-NOT-ACTIVATE`, NAV $0.00).

**Surfaced and indexed, with their fragilities on the face of the record:**

- **PPLI +11.3276%** (35.93 → 40.00), cap **$2.98B**, anchor **2026-09-24** — a WSJ report that **MGM is weighing a counter-bid for People Inc.**, reported published 09-24 **18:26 EDT** (after the close; clock AGGREGATOR-SOURCED, date corroborated by a Bloomberg piece datelined 09-24). **Confirmed a NEW event, not a duplicate**: the 2026-09-23 anchor already in the record was People Inc. *withdrawing its own bid for MGM*; this is the reverse leg. Conviction **60** — an M&A rumour re-rates toward a bid price, which is B's weakest mechanism class, and the whole move rests on a paywalled report neither company has confirmed.
- **TWLO −7.9623%** (299.66 → 275.80), cap **$41.86B**, anchor **2026-09-25** pre-open — HSBC cut to Reduce (analyst Sameer Lam), PT held at $211, on scepticism that Twilio captures proportional value from Meta's Muse AI agent traffic. A reported ~3.5% pre-market dip implies the note circulated before the open. Conviction **60**: an analyst downgrade carries no new company disclosure — the ground on which CRWD was declined 2026-08-20 and BFLY/SNDK scored 45 on 09-22 — but an 8% repricing of a $42B company on one broker's view of a **third party's** product is a materially larger divergence than those cases. Provenance note: HSBC does not publish research publicly, so this anchor is structurally incapable of being upgraded to issuer-sourced.
- **VIAV +9.2667%** (37.23 → 40.68), cap **$10.04B**, anchor **2026-09-25** — CMMC Level 2 certification for the aerospace and defence lines. Conviction **45**, the lowest surfaced: the anchor could **not** be found on Viavi's own newsroom, and two aggregator write-ups date it **09-25 AND 09-26**. 09-26 is a Saturday with no session, so 09-25 is chosen by *calendar compatibility rather than by the source* — reasoning stated plainly so it is not read as issuer evidence. A compliance certification is also thin news for a 9.3% move, which usually means something else moved the stock.
- **DELL +5.0129%** (536.02 → 562.89), cap **$373.91B**, anchor **2026-09-25** — disclosure of a record **$60.9B** in new AI-server orders with backlog to **$95B**, reinforced by a Morgan Stanley note. It clears the frozen floor by **13bp** on an AGGREGATOR-dated anchor, which is inside the noise of which session an unverified disclosure is attributed to: **the eligibility verdict here is genuinely contingent on a timestamp nobody has verified**, and it sits in B's weakest mechanism class besides (the stock rose in the direction the information supports). Conviction 60, stated with the fragility rather than around it.

**Two items are written up precisely because they UNDER-reacted, and both fail the floor:**

- **AKAM +3.1971%** (110.41 → 113.94), cap **$16.57B** — Anthropic committed to a **seven-year, $11.6B** Akamai Cloud agreement, roughly **70% of the entire market capitalisation**, and the stock moved 3.2%. Other aggregator headlines quoted a much larger percentage; **IBKR is the source of record and the RTH bars say +3.1971%** — a third-party figure disagreeing with mine is evidence against *their* read until I re-derive it, and I re-derived it.
- **COST +2.9311%** — the only fully issuer-confirmed anchor of the day, and a proportionate reaction to a record quarter. Fails B's floor; context only.

**GENI — the cap rail done properly, and the answer was NOT the convenient one.** FMP `profile-symbol` put Genius Sports at **$1,658,544,720**, 17% below the $2B floor and inside the ~30% band where FMP's implied share count is not trustworthy. Escalated to the issuer per Operating_Protocols.md §11 MARKET CAP BASIS via a **direct EDGAR fetch** — CIK 0001834489, **Form 6-K** filed 2026-08-06, Exhibit 99.1, period ended **2026-06-30**: **267,626,957 shares outstanding**. At the $6.44 close that is **$1.724B**, ~14% below the floor. The two sources differ by **~4%, not 30%**, so this is **not** an FMP share-count artifact — GENI genuinely belongs below the rail and its +11.0345% is excluded on the cap leg with primary-source confidence. Note GENI files 6-K as a foreign private issuer, so the count came off the exhibit's balance sheet rather than a cover page. SCHL (**$610M**, ~70% below the floor) was excluded without escalation, correctly — it is far outside the band where second-sourcing buys anything.

**Judged NOT significant despite clearing the rail** (in `rejected_notable` with reasons): SMCI +4.2158% (NVIDIA Vera Rubin NVL72 rack shipment news, 09-25), MSFT +3.6632% (Copilot revamp, 09-25), AAL +3.8951% (macro, not company-specific — the Hormuz reopening plan cutting jet-fuel costs), GWW −2.8452% (Barclays PT trim $1,185 → $1,172, Underweight maintained — a 1% target cut is not new information and a 2.8% reaction to it is proportionate).

**COVERAGE, STATED AS THE BOUND IT IS.** `universe_measured = 42` is a numerator whose denominator this run does **not** establish. The 42 are the union of the discovery legs' output and a deliberate 19-name orchestrator supplement (the AI/semis megacap complex, the two energy majors, LLY and NVO, and five rate-sensitive REITs — the REITs added because the long end printed a 22-year high and a NASDAQ-only equal-weighted read put Real Estate at −2.59%, making the REIT complex the one place a cap-weighted sector print could hide a large move). **Discovery legs that FAILED:** FMP `marketPerformance` `biggest-gainers` and `biggest-losers` both returned almost entirely sub-$2B microcaps and leveraged/inverse ETFs and were useless for a ≥$2B screen; two Tavily searches returned zero results and were widened rather than re-issued narrow. **Legs that worked:** FMP `most-active` (volume-ranked), CNBC's midday-movers article, wide Tavily movers sweeps, direct SEC EDGAR fetches for issuer timestamps and share counts, and issuer IR pages. A COHR-class large-cap decliner outside both the sweep and the supplement can still have been missed. `surfaced_count = 8` is `ARRAY_LENGTH(passed)`, never the rail tally.

The 19 measured names that moved **<2%**, so the denominator is explicit: TSLA −1.5425, ORCL −1.7487, PLTR −1.5160, BG −1.0980, HPE −0.9130, XOM −0.9560, CVX −0.5836, PLD −0.5754, AMT +1.0582, AZN +1.2277, MRK +0.5406, GEV +0.2712, MU +0.1620, NVDA +0.2182, AMD +0.2177, LLY +0.1329, NVO +0.4661, O +0.2346, SPG +0.0586.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Decision record: `events.decision_log` `de515993-dc7a-48e2-aa6f-89ad3bb0d168` (`screen='sector-move'`). All **11 S&P 500 SPDR GICS sector ETFs plus SPY** measured exhaustively on IBKR RTH daily bars — the complete sector population, so unlike the single-name screen this one carries no coverage caveat. **3 surfaced of 12 measured**, `rail_tally` **0**, `agreement` {both 0 / ai_only 3 / rule_only 0}.

**NOT ONE SECTOR CLEARED THE 1% LEVEL LIMB, and that is a measurement rather than an omission.** The full range is XLI **+0.9476%** to XLC **−0.9036%** — a cross-sector spread of **1.851pp** on a tape that rose +0.5436%. For calibration against this screen's own history: the 2026-09-24 run surfaced three sectors on a spread of ~2.5pp and called that tape flat, so **today's dispersion is narrower than a session already judged flat**. All three items below enter through the **dispersion limb** and log `legacy_rule_pass = false` by convention — false, never NULL.

| Sector | Move | Conviction | Note |
|---|---|---|---|
| **Real Estate (XLRE)** | **−0.2161%** | **60** | The aggregate hiding its own constituents — see below |
| Energy (XLE) | −0.8946% | 45 | Gave up less than half of crude's −2.14% |
| Communication Services (XLC) | −0.9036% | 45 | Essentially one name: META −3.3348% |

**THE REAL FINDING IS AN AGGREGATE THAT HIDES ITS OWN CONSTITUENTS.** On the session the 30Y touched 5.502–5.525% intraday, the cap-weighted rate-sensitive sector moved **−0.2161%** — essentially nothing. Two independent constructions say the damage was real and *concentrated*: **EQIX closed −2.5785%** on IBKR RTH bars (a $99.5B data-centre REIT), and FMP's `sector-performance-snapshot` — explicitly **NASDAQ-listed-only and EQUAL-weighted**, stated as such rather than dressed as an S&P figure — put Real Estate at **−2.59%**, by a wide margin its largest decliner. Two different constructions agree on ~−2.6% while the cap-weighted ETF reads −0.22%. The four other REITs measured corroborate dispersion rather than the sector print: PLD −0.5754%, O +0.2346%, SPG +0.0586%, and **AMT +1.0582%** — up more than a percent on the same session EQIX fell two and a half. A level-limb-only screen would have reported this as a quiet day in real estate.

**Energy refused to follow crude, which is information about how the tape read the diplomacy.** Brent −2.14%, XLE −0.8946% — less than half. Energy equities pricing a 2.1% crude retracement at 0.9% reads as the market treating the de-escalation as reversible rather than as a regime change, which matters because the shock overlay is the one fundamental axis still standing defensive. Held at 45: a ~0.4 single-day beta of energy equities to crude is not by itself unusual.

**Communication Services is not a sector signal, and that is why it is recorded.** XLC was the weakest sector on a rising tape and essentially all of it is **META −3.3348%** at a $1.91T cap — written up so a later reader does not read one mega-cap's drawdown as a rotation, and with the oddity that META fell the same morning Deutsche Bank raised its target to $820 from $750.

**Cross-source disagreement, recorded rather than reconciled away.** FMP's NASDAQ-only equal-weighted snapshot **disagrees** with the cap-weighted ETFs on Energy (+0.53 vs XLE −0.8946) and on Consumer Defensive (+3.14 vs XLP +0.4406). That is what an equal-weighted NASDAQ-only construction *should* do, and it is why the cap-weighted SPDR ETFs remain this screen's measurement of record; its Real Estate figure is used only as corroboration of **dispersion**, never as the sector metric.

Also worth one line: **Consumer Staples did not lead (+0.4406%) despite COST +2.9311%**, which argues against reading the day as a defensive bid — and **Utilities rose +0.3811% on a session the long end sold off**, mildly contrary but 38bp is too small to carry a claim.

### 5. Notable commentary

- **JPMorgan initiated Genius Sports (GENI) at Overweight**, citing a scarce combination of diversified above-market growth, execution, improving profitability/FCF and valuation. +11.0345% — excluded on the cap rail (see §3). ([CNBC](https://www.cnbc.com/2026/09/25/stocks-making-the-biggest-moves-midday-akam-geni-ppli.html))
- **HSBC cut Twilio to Reduce**, PT $211 held. See §3.
- **Deutsche Bank raised Meta's target to $820 from $750**, calling Meta's "Muse" AI personal agent virtually unique and far ahead of rival launches — the same Friday META fell 3.33%. ([CNBC](https://www.cnbc.com/2026/09/25/top-10-things-to-watch-in-the-stock-market-friday.html))
- **BMO raised Micron estimates** ahead of its print the following week, citing the memory supercycle. MU moved +0.1620%.
- **Barclays trimmed Grainger's target** to $1,172 from $1,185, Underweight maintained. GWW −2.8452%.
- **BofA Global Research moved to a December ECB hike call**, citing a renewed energy-price inflation impulse (Reuters, datelined 09-24, at the window boundary).
- A dated correction to a widely-repeated claim: **AMD crossing $1 trillion in market capitalisation** is referenced throughout Sept-2026 coverage, and the clearest dating puts it on **Monday 2026-09-21**, not this window. AMD moved +0.2177% Friday.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

**UNION SWEEP PERFORMED, BROKER RECONCILIATION CLEAN, NO EXIT TRIGGERED.** The sweep enumerated the union of `state.current_positions` (**12 tranches**, all Strategy D) and live `get_account_positions` (9 rows). Every live equity — AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER — maps to a reconciled tranche; the ninth live row is **VOO 17.7651 shares**, the park risk sleeve and not a strategy position. **No reconciliation-lag position exists and no `position_reconciliation_lag` alert is owed.** Two things that would otherwise look like discrepancies: **GEV** is present in the broker and *is* reconciled (`D:GEV:2026-08-03`), and **MDT** — Strategy B's last open position, which this routine's own `b_pairwise_corr_high` prompt note still describes as live — is **absent from both surfaces**, consistent with `analytics.b_pairwise_correlation` reading `n_positions = 0`.

**All twelve tranches carry `convergence_target IS NULL` and `time_exit_date IS NULL`.** Convergence targets are a Strategy B/E construct and time exits are not part of D's design (D has no maximum hold), so this is the expected state for an all-D book rather than a gap. It is stated plainly because a reader seeing "no exits triggered" for weeks should know the mechanical limb **has nothing to fire on**, not that it fired and passed.

### Per-strategy kill-trigger sweep

**UNCONDITIONAL live-mark drawdown refresh performed — no flag fires.** `perf.kill_flags` carries rows for B (as of 2026-08-18) and D (as of 2026-09-24) only.

- **Strategy D.** Engine row: `deployed_unit_value` 1.070108245 against `peak_unit_value` 1.098110312, `current_drawdown` **−2.5500%**. Refreshed against Friday's closes the deployed book marks **549.2882 → 551.4068, +0.38570%**, putting deployed unit value at ~**1.074236** and `current_drawdown` at ~**−2.1742%** — an *improvement*. Stated as an approximation because it re-marks the deployed positions without re-deriving the engine's cash and flow treatment; the conclusion is robust to any plausible refinement, since **−2.17% against a −50% kill line is not a close call.** Runaway-success does not engage (a doubling needs 2.0 against 1.074, and the 30-trade gate is unreached at 1 closed trade). `interim_underperf_warning` FALSE: `deployed_days` 105 clears the 90-day leg, but `excess_vs_sgov` is **+5.4400%**, nowhere near −15%.
- **Strategy B.** `deployed_days` 79, `current_drawdown` −3.92%, all flags FALSE, zero open positions, capital-disabled at NAV $0.00.
- **No open `interim_underperf_warning` alert exists**, so the heal-resolution clause has nothing to resolve.
- **`b_pairwise_corr_high` is INERT, as its own prompt note predicts** — `n_positions = 0 < 2`, `avg_offdiagonal_corr` NULL. A genuine no-op, not a skipped check.

### Judgment-laden thesis-invalidation check

**No Development in the window touches any open position's invalidation criteria.** None of the eight held names appears anywhere in this run's 42-name screen, and no in-window development bears on an AWS growth/margin/backlog metric, a Google Cloud revenue/margin/RPO metric, a TSMC gross-margin or N2/A16 ramp metric, a Disney SVOD operating-margin or buyback metric, GE Vernova's organic orders growth, Intuitive's procedure growth or placements, or an RTX programme metric — the specific quantities these theses are written on. Not one name moved more than **1.4167%** (ISRG); TSM was the only decliner, at **−0.1197%**.

**DIVIDEND NETTING CHECKED AND NOT OWED.** `state.price_level_criterion_drift` returns exactly one row, `D:DIS:2026-08-05`, and it is **not** an exit criterion: `is_exit_criterion = false`, `actionable_price_level = false`, `criterion_key = 'not_exit_triggering'` — the $45 figure is the tranche's notional inside a sentence saying ordinary adverse marks do *not* trigger an exit. `has_dividend_drift = false`, `cum_dividend_since_reference = 0`, `marks_cover_reference = true`. No price-level criterion is under test anywhere in this book, so no adjusted comparison is owed. One flag recorded rather than glossed: **`reference_date_declared = false`** on that row, so the view fell back to the entry date — harmless while the criterion is non-actionable, and a lower bound if it ever becomes one.

### Watchlist candidates

No Development materially changes the candidacy status of any existing watchlist name. The five ADDs below are new rows, not status changes to existing ones.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D excluded via `long_horizon`). Router state from `state.current_regime` (as of 2026-09-03): **A DO-NOT-ACTIVATE, B DO-NOT-ACTIVATE, C HYBRID ACTIVATE FOMC-only, D DO-NOT-ACTIVATE, E DO-NOT-ACTIVATE**.

- **Strategy B — five names clear the frozen Entry criterion 1 on a RESOLVED anchor: ZS, PPLI, VIAV, TWLO, DELL.** All five go to the **new-entry index only**. B's router is `DO-NOT-ACTIVATE` (`div-B-202607-1`) and B is capital-disabled at NAV $0.00, so no thesis construction is routed and no capital is exposed. Anchors, fragilities and conviction per §3. **BB, COST and AKAM do NOT clear the floor** and are `below_spec_floor` context only — never described as tradeable candidates. **BE, CRDO, GNRC, SBSW and INTC are not routed at all**: their anchors are UNRESOLVED, and a candidate whose eligibility session cannot be established has no criterion-1 test to pass.
- **Strategy A — no candidate.** Nothing in the window is a newly announced qualifying catalyst within six months on an A-eligible name. The Merck ccRCC approval is a *resolved* regulatory action, not a forward catalyst.
- **Strategy C — no candidate.** C is live only under the FOMC-only carve-out, which restricts its catalyst class to FOMC events; no in-window development creates a named C opportunity, and there was no Fed action or market-moving speaker inside the window.
- **Strategy E — no candidate routed, but one observation logged for M2 rather than manufactured into one.** The real-estate dispersion above (EQIX −2.5785% against XLRE −0.2161% and AMT +1.0582%) is exactly the intra-industry-group divergence E's mechanism targets. It is **not** routed, and the reason is stated rather than implied: E's frozen Entry criterion 3 requires a **252-day pair correlation ≥ 0.5** and this run measured no correlation for any REIT pair, so there is no candidate to assess — only a pair-shaped observation. E is also `DO-NOT-ACTIVATE` with zero open positions. Flagged here so M2's monthly pair screen can pick up the data-centre-REIT versus tower/industrial-REIT divergence with the correlation work actually done.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

Durable record: `events.decision_log` `a1339982-9867-416b-b38f-72d00fbb028c` (`entry_type='add-candidate-review'`). **12 tranches evaluated, 0 flagged, 3 blocked at the HARD GATE.** A and B hold nothing, so all twelve are Strategy D.

**Price basis per the 2026-09-07 pin**, and the check mattered: `mark_vs_cost_pct` numerators are Friday's IBKR RTH closes, denominators are each tranche's **own** `cost_basis / shares`, never the blended account `avg_price`. `get_account_positions` served AMZN at 249.72999575 and GOOGL at 344.00 against true closes of **249.67** and **343.92**. Third-decimal-place differences, and the point of the pin is that a number which moves when nothing moved is unreadable as a series whatever its size. **A further tell for the record: `get_account_positions` carries no `is_close` flag at all** — its price fields are `market_price`, `average_price`, `market_value`, `unrealized_pnl`, `daily_pnl` and nothing else — so the pin's instruction to check `is_close` cannot be satisfied from that endpoint even in principle. A position-endpoint mark is not evidence of a close.

| Position | mark vs cost | Day | Disposition | Evaluable |
|---|---|---|---|---|
| D:AMZN:2026-07-30 | **−6.0306%** | +0.1163% | declined | true |
| D:UBER:2026-07-09 | **−4.9002%** | +0.5779% | **declined_hard_gate** | false |
| D:DIS:2026-05-07 | −4.6434% | +0.5589% | declined | false |
| D:GOOGL:2026-07-09 | −4.4264% | +0.4557% | declined | false |
| D:GEV:2026-08-03 | −1.2657% | +0.2712% | declined | true |
| D:DIS:2026-08-05 | +2.2784% | +0.5589% | declined | true |
| D:AMZN:2026-07-09 | +3.4927% | +0.1163% | declined | false |
| D:GOOGL:2026-07-26 | +4.9037% | +0.4557% | declined | true |
| D:TSM:2026-07-21 | +5.3169% | −0.1197% | declined | false |
| D:RTX:2026-04-27 | +7.0669% | +0.4189% | **declined_hard_gate** | false |
| D:TSM:2026-07-29 | +14.6932% | −0.1197% | declined | true |
| D:ISRG:2026-07-20 | +15.9278% | +1.4167% | **declined_hard_gate** | false |

**The HARD GATE blocks the same three names as the prior four cycles, and the constraint is structural.** Seven of twelve tranches carry `JSON_VALUE(invalidation_status,'$.breach_status') = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. Four are covered at **name** level by a later tranche carrying a fresh assessment (AMZN, DIS, GOOGL, TSM). **Three are covered nowhere — ISRG, RTX, UBER — each a single-tranche name whose only tranche is unassessed, so "unbreached" cannot be affirmatively confirmed and they are structurally ineligible for an add regardless of merit.** UBER at −4.90% is the book's third-largest drawdown and is where a dip case would start if one could be made; the gate forecloses it before merit is reached. `invalidation_criteria_evaluable` is computed with all three disjuncts ORed and NULL-wrapped — **not one of the twelve carries a `$.status` key**, so a two-disjunct or bare IS-NULL test would report all twelve as evaluable and re-hide exactly this ambiguity.

**Why nine merit declines, and why matching the prior cycle's shape is not laziness.** The window held **one** session. In it no held name moved more than 1.42%, five moved less than 0.6%, and none appears in this run's 42-name screen. Trigger (a), a dip against an intact thesis, needs adverse price action — everything rose except TSM, by a tenth of a percent. Trigger (b), strengthened conviction, needs new information — there is none. The two genuine standing drawdowns, **AMZN −6.03%** and **GOOGL −4.43%**, are multi-week marks against mid-summer entries, not Friday dips, and re-flagging a standing drawdown as a fresh dip on each daily pass is precisely the theater this durable log exists to expose. One adjacent case was considered and rejected on the reasoning: **BE +8.2711%** on the AI-power theme could be read as sector conviction support for the GEV orders thesis, and it is not — a peer's price move is not information about GE Vernova's organic orders growth, BE's own anchor is UNRESOLVED, and **EQIX −2.5785%** on the same tape cuts the other way on data-centre capex.

**External constraints, noted and explicitly NOT the reason for any decline.** D's router is `DO-NOT-ACTIVATE` and D is capital-disabled; **`state.trading_enabled` is FALSE** (`halt_reason`: "state.freshness marks_fresh/engine_fresh not both TRUE"); an open `nomadic_borrow_blocked` warning records no funded donor capacity anywhere in the roster. So an add could not be funded today even if flagged. None of that is load-bearing for the nine merit declines. `state.entry_staging_allowed` is **open** (`entries_allowed = true`, `book_drawdown_soft_breach = false`) — a change from the prior cycle, which declined against an open soft breach.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** Default NO holds, and the default is not being leaned on — the case was considered on its merits. Breadth improved **+1.40pp** to 46.52, its first increase after three consecutive declines, but it remains **below the 50 HEALTHY/WEAK line**, so the `EQUITY_BREADTH` router key does not flip; one improving session is not a trend. VIX fell 5.11% to 14.87 and SPY_TREND stays UP, neither of which is a state change. The long end deteriorated in level and improved in direction on the same session, which is not a basis for anything. The 2026-09-23 flag was already acted on — D2 performed that review on 09-24 and reached a determinate verdict — and nothing in this window reopens it.

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events` `as_of_date = 2026-09-25`, `scope = TECHNICAL_INPUT`, `key = EQUITY_BREADTH_PCT`, `numeric_value = 46.52`, `value = 'Barchart $S5TH'`.**

- **Two independent sources, zero gap.** Barchart `$S5TH` published **46.52** with its own as-of wording "Quote Overview for Fri, Sep 25th, 2026" and a Previous Close of **45.12** that matches the stored 09-24 row exactly. EODData's **end-of-day table** for the same session reads Close **46.52**, with its prior-day close also 45.12. Gap **0.00pp**.
- **The documented EODData unsettled trap fired and was caught.** The same EODData page's top live-quote block served **46.12** stamped "25 Sep 26 **15:48**" — twelve minutes before the close. Discarded. Had it been taken at face value this row would read 0.40pp low.
- **On-page clock: ABSENT, and said so rather than glossed.** Barchart's index quote page carries no per-quote clock at all, so the ≥16:00 ET test could not be satisfied by the primary source. The token recorded is **`onpage_clock=ABSENT`**, not `unsettled_at_fetch=<hh:mm>` — asserting a specific pre-close fetch time would be false, since the issue is an absent field rather than an early one. Settlement rests on two facts instead, both stronger than a clock: **`settlement_evidence=T+2_elapsed`** (fetched ~50 hours after the Friday close with two non-sessions in between, so no live session could be mid-print under the 09-25 date) and **`settlement_evidence=eoddata_eod_table`** (an independent vendor's post-session recap at the identical value). This is **not** the 2026-09-17 failure mode, where a correctly-dated page carried a 14:58 ET clock on a *live* session and later settled 0.80pp lower.
- **`date_attribution=source_dated`** — both sources state the session date, so the post-close-inference fallback was neither used nor claimed.
- **Fetch-path provenance:** the kept figure came from `tavily_extract` (advanced), corroborated by a second extract of `/overview`. A rendering `WebFetch` of the **same URL** failed twice (base and `%24`-encoded, each cache-busted) with empty content — a **fetch-path** failure, not a source failure.
- **MacroMicro weekly probe: due, spent, still down.** Today is Sunday, the first D1 fire of the Sunday-anchored week, so one probe was owed and one was made: `tavily_extract` (advanced, cache-busted) returned "Failed to fetch url" — the same failure mode unbroken since 2026-08-19. Barchart remains the **operative primary**; MacroMicro's designation is not withdrawn and resumes the moment it answers.
- **Single-usable-source disclosure is NOT owed this run**, stated so its absence is not read as an omission: two independent settled readings were obtained.

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

Silent. One `hf_fs` paper-search call, Sunday's long-context battery ("long context LLM lost in the middle"), five results — **all five published before the scan-window start**, the most recent (2609.03874, STAIR) dated 2026-09-03, ~three weeks early. Zero in-window papers, so no materiality assessment against `AI_Trading_Foundation.md` was possible and none is claimed. No capture written, no `state.strategy_candidates` row.

## PARK ALLOCATION CALL

Durable record: `events.decision_log` `7c9df95f-49e2-41f9-b899-3e70055ab486`, surfaced on `state.park_allocation_latest`.

- **`vehicle`: VOO** (`risk_sleeve` VOO, `defensive_sleeve` SGOV)
- **`target_f_pct`: 0** — unchanged since the 2026-09-22 terminal re-risk. `direction` keep, `status` **BOUND**, `park_watch` false.
- **`conviction`: MEDIUM, `conviction_pct` 65**
- **`rationale`.** `state.park_axis_daily` for 2026-09-25 publishes `standing_defensive_count = 4`, `firing_count = 1`, `cap_pct = 100` and **`increase_gate_open = TRUE`** on a firing **volatility** axis. At face value that is a live de-risk licence at a cap of 100. It is not one, for two reasons that bite independently. **First**, all six axis rows on that date carry `measured_on = 2026-09-24`, `sessions_since_measured = 1`, `axes_measured_today = 0` — the row is entirely carried from Thursday's marks (structural, since D2a writes `events.signal_marks` after D1 runs), and **a carried axis may never be counted as FIRING**, because an event is by definition a change. **Second**, on Friday's own data the volatility axis did not merely fail to fire, it **EXITED defensive**: VIX closed **14.87** against 15.67 (−5.1053%), and against its own 20-day mean of **15.6715** it sits **5.1080% BELOW** — where Thursday it sat 0.1054% above. The method is validated, not asserted: the identical computation over the window ending 09-24 returns **15.6535**, matching `state.park_signal_daily`'s stored 09-24 figure **exactly**. My hand-score is therefore **standing 3, firing 0, gate CLOSED** — breadth (46.52, standing but **improving** +1.40pp), rates (30Y 5.50% standing, 10Y *down* 1bp), shock (`acute`, dated 2026-09-01 and therefore 26 days old — a standing state is never news, and Brent −2.14% points toward its de-escalation legs) defensive; volatility, index (SPY +0.5436%, above both means, drawdown from the 252-day high improving to ~−0.8395%) and credit (`hy_oas` 2.85%, `ref_month` 2026-07-01 — **two months stale**, and one of the two reasons conviction is 65 rather than higher) not. **VOO beats the runner-up (a 25% SGOV sleeve) and it is not close:** the two axes that actually *moved* both moved toward risk, the Nasdaq closed at a record, and the one input that deteriorated in level eased into the close. The forward-test record sets the bar higher still — both defensive excursions this allocator has taken lost ground (**0-for-2**, −2.841pp and −1.019pp on `analytics.park_counterfactuals`), and across 15 historical episodes the defensive signal's mean forward edge is **−0.638pp** with 4 wins. **No cap binds today and I am not computing the decay-confirmed clamp as though one did:** f is 0, the gate is closed, and a cap is a ceiling on an increase that cannot happen. The ratchet is what makes the override safe in this direction — the mechanical count is *higher* than mine, and it may only ever block or demote a conversion, never upgrade a KEEP into one.
- **`invalidation` (symmetric standard).** f=0 was reached by a re-risk justified on a narrative/judgment case, so the conditions for leaving it are an **OR-of-pairs, not a conjunctive checklist**: any **two** independent axes *entering* defensive in the same session carries an increase — VIX closing back above its own 20-day mean, or the index losing its 50-day mean, or breadth resuming its decline below the low-40s, or a fresh **dated** shock event, or `hy_oas` printing a fresh reading that is itself defensive. Any two on their own session's evidence and f rises at the conviction-sized step; any **one** alone is a WATCH, re-decided fresh next session. A standing axis *deepening* is explicitly not an entry and never counts toward the pair.
- **`theater_check`.** The verdict is a no-change, so the theater risk runs the other way from usual: the mechanical view handed me an open gate and a firing axis, and declining them is the harder call to write, not the easier one. I checked that I am not reaching for a KEEP because f is already 0 and 0 is comfortable — the override rests on one measurement I made myself and can be re-run in a line, validated to the fourth decimal against the engine's own stored prior-day figure. Had it come back the other way I would have had two axes and a live gate.

Every numeric claim above appears in `fields.readings` with a value, a source and an as-of date. Every count is computed from a named series — the three-consecutive-decline breadth count from `events.regime_events`, the 20-day VIX mean from the IBKR bar series, the 8-positive/3-negative sector split from the eleven measured ETFs. **No superlative or record-claim is made about any series this call touches**; the two record-claims that appear (30Y "highest since 2004", 10Y "highest since 2007") are attributed to the sources that made them and were **not** recomputed here.

---

## RECOMMENDED ACTIONS

- **ADD ZS to the Strategy B new-entry index** — `qualifying_event_date` **2026-09-24** (Form 8-K Item 5.02 CRO departure, filed 09-24, broke after the close; Friday is the reaction session), **−10.0587%** close-to-close (214.64 → 193.05, IBKR RTH bars), market cap $31.22B. Clears B's frozen Entry criterion 1 by 2.0×. Index-only: B router `DO-NOT-ACTIVATE`, capital-disabled. Originating screen `b15a5838-419b-4899-85ca-7542c1c3a34d`.
- **ADD PPLI to the Strategy B new-entry index** — `qualifying_event_date` **2026-09-24** (WSJ report that MGM is weighing a counter-bid, published 18:26 EDT after the close; clock aggregator-sourced, date corroborated by Bloomberg), **+11.3276%** (35.93 → 40.00), cap $2.98B. A **new** event, not a duplicate of the 2026-09-23 MGM anchor, which was People Inc.'s withdrawal of its own bid. Index-only, same router reason.
- **ADD VIAV to the Strategy B new-entry index** — `qualifying_event_date` **2026-09-25** (CMMC Level 2 certification), **+9.2667%** (37.23 → 40.68), cap $10.04B. **Anchor confidence LOW**: not found on Viavi's own newsroom, and aggregator write-ups date it 09-25 *and* 09-26 — 09-26 being a Saturday, 09-25 is chosen by calendar compatibility rather than by the source. Index-only, same router reason.
- **ADD TWLO to the Strategy B new-entry index** — `qualifying_event_date` **2026-09-25** (HSBC cut to Reduce, PT $211 held; a ~3.5% pre-market dip implies the note circulated pre-open), **−7.9623%** (299.66 → 275.80), cap $41.86B. Anchor aggregator-sourced and structurally unable to be otherwise, since HSBC does not publish research publicly. Index-only, same router reason.
- **ADD DELL to the Strategy B new-entry index** — `qualifying_event_date` **2026-09-25** ($60.9B AI-server orders, backlog to $95B), **+5.0129%** (536.02 → 562.89), cap $373.91B. **Clears the frozen floor by 13bp on an aggregator-dated anchor** — the eligibility verdict is genuinely contingent on a timestamp nobody verified, and that is on the face of the record rather than around it. Index-only, same router reason.

**No exits triggered.** No mechanical trigger exists on any of the twelve open tranches (all `convergence_target` and `time_exit_date` NULL), and no Development met any thesis-invalidation criterion.

**No add candidates.** 0 of 12; three blocked at the HARD GATE (ISRG, RTX, UBER), nine declined on the merits.

**No router reviews recommended.**

**NOTE, explicitly not a bullet:** the PARK ALLOCATION CALL above is **KEEP VOO at `target_f_pct` 0, BOUND**. D2 reads it from `state.park_allocation_latest`, never from this section or the action block, and it is deliberately absent from both so the prose-bullet count and the block entry count stay equal at five.

```yaml d1_actions
- action: watchlist
  ticker: ZS
  strategy: B
  qualifying_event_date: 2026-09-24
  source_research_screen_id: b15a5838-419b-4899-85ca-7542c1c3a34d
  detail: ADD to Strategy B new-entry index — -10.0587% close-to-close (214.64 -> 193.05, IBKR RTH bars) on the Form 8-K Item 5.02 CRO departure filed 2026-09-24 and public after that session's close; anchor 2026-09-24, reaction session 2026-09-25, cap $31.22B, clears the frozen >=5% floor by 2.0x, conviction 75. Index-only, B router DO-NOT-ACTIVATE and capital-disabled.
- action: watchlist
  ticker: PPLI
  strategy: B
  qualifying_event_date: 2026-09-24
  source_research_screen_id: b15a5838-419b-4899-85ca-7542c1c3a34d
  detail: ADD to Strategy B new-entry index — +11.3276% (35.93 -> 40.00) on a WSJ report that MGM is weighing a counter-bid, published 2026-09-24 18:26 EDT after the close (clock AGGREGATOR-SOURCED, date corroborated by Bloomberg); anchor 2026-09-24, reaction session 2026-09-25, cap $2.98B, conviction 60. A NEW event, not a duplicate of the 2026-09-23 MGM anchor. Index-only, same router reason.
- action: watchlist
  ticker: VIAV
  strategy: B
  qualifying_event_date: 2026-09-25
  source_research_screen_id: b15a5838-419b-4899-85ca-7542c1c3a34d
  detail: ADD to Strategy B new-entry index — +9.2667% (37.23 -> 40.68) on CMMC Level 2 certification for the aerospace/defence lines; cap $10.04B, conviction 45. ANCHOR CONFIDENCE LOW — not found on Viavi's own newsroom and aggregator write-ups date it 09-25 AND 09-26; 09-26 is a Saturday, so 09-25 is chosen by calendar compatibility rather than by the source. Index-only, same router reason.
- action: watchlist
  ticker: TWLO
  strategy: B
  qualifying_event_date: 2026-09-25
  source_research_screen_id: b15a5838-419b-4899-85ca-7542c1c3a34d
  detail: ADD to Strategy B new-entry index — -7.9623% (299.66 -> 275.80) on HSBC's cut to Reduce with PT $211 held; a reported ~3.5% pre-market dip implies the note circulated pre-open, so anchor and reaction session are both 2026-09-25. Cap $41.86B, conviction 60. Anchor AGGREGATOR-SOURCED and structurally unable to be otherwise. Index-only, same router reason.
- action: watchlist
  ticker: DELL
  strategy: B
  qualifying_event_date: 2026-09-25
  source_research_screen_id: b15a5838-419b-4899-85ca-7542c1c3a34d
  detail: ADD to Strategy B new-entry index — +5.0129% (536.02 -> 562.89) on disclosure of $60.9B in new AI-server orders with backlog to $95B; anchor and reaction session both 2026-09-25, cap $373.91B, conviction 60. Clears the frozen >=5% floor by only 13bp on an AGGREGATOR-dated anchor, so eligibility is contingent on an unverified timestamp. Index-only, same router reason.
```

---

## PROCESS NOTES

- **An append-only correction to this routine's own durable record was written this run.** W2's `ops.alerts` `62775339` (`d1_below_spec_floor_contradicts_own_anchor_prose`) found that D1's 2026-09-24 single-name screen `6e179f3c-2c67-4a07-857c-b911ec051464` carried IONQ with `below_spec_floor = false`, `legacy_rule_pass = true` and the pair 42.54 → 44.98 (+5.7358%), while the **same item's** `reason`, `criterion1_on_anchor_pct = 4.4183` and `criterion1_verdict = "FAIL by 58bp"` all said the opposite. A cross-row close chain proves which field was wrong: the 2026-09-23 screen `91b1a00c` recorded IONQ on the **identical** `qualifying_event_date` as 40.74 → 42.54 = +4.4183%, so 42.54 is the anchor-session **close** and cannot also be its own denominator. Replacement row **`5915447c-22b6-4dff-9204-2add2bb50f81`** carries `in_superseded_by = 6e179f3c…`, tag `correction`, and corrects `metric_pct` 4.4183 / `prior_close` 40.74 / `event_close` 42.54 / `below_spec_floor` TRUE / `legacy_rule_pass` FALSE, plus `market_cap_usd` off the round 10,000,000,000 placeholder to the 15,878,903,588 the 09-23 row measured, with `agreement` recounted to both 4 / ai_only 5 / rule_only 0. Nothing else in that screen was touched, and **MGM's `below_spec_floor = false` was deliberately left alone** — it is correct (the buyout withdrawal released 09-23 18:05 ET, after the close, so 09-24 *is* its eligibility session, and D2 already re-classified it); only MGM's prose is wrong, and prose is not a parsed field. This closes the **durable-record half** of queue item `rescreen-IONQ-B-20260927`; D2 retains any index/candidacy half.
  - **Alert `62775339` is deliberately left OPEN.** Its generalisable ask is the *check*, not the instance — a write-time cross-row close-chain test beside the two-price contract — and that is a spec change to `Claude_Task_Plan.md` D1 item 3 owned by W5's SPEC-DEFECT NOTICE INTAKE. Closing the alert on the instance alone would bury the ask. **D1 applied the check by hand this run** against its own eight `passed` items and found no such defect: every `prior_close`/`event_close` pair reproduces its `metric_pct`, and every pair belongs to the session its own `qualifying_event_date` implies — including BB, where the pair was deliberately re-taken from the anchor session rather than the reaction session.
- **Two queue items due today were NOT actioned by this routine and are named rather than left silent:** `rescreen-ORCL-B-20260927` (`PENDING_ANALYSIS`, strategy B) and `rescreen-NKE-D-20260925` (`PENDING_ANALYSIS`, strategy D). Both are D2-drained queue items, not D1 surfaces, and D1 has no queue-draining step. ORCL was measured this run for completeness and moved **−1.7487%**, sub-rail.
- **An earlier-cycle prose claim corrected, recorded because a later reader would inherit it:** this routine's `b_pairwise_corr_high` prompt note states "today B holds a single position (MDT)". B holds **zero** positions — MDT is absent from both `state.current_positions` and the live broker, and `analytics.b_pairwise_correlation` reads `n_positions = 0`. The check's inertness is unchanged either way (0 < 2 as surely as 1 < 2), so nothing turns on it operationally. Recorded as an observation about the spec text, which W5 owns; no spec edit made from here.
- **Metered spend, reported per the shared rule.** 97 calls logged to `ops.web_calls` — Tavily 21 (17 `search`, 4 `extract`), FMP 29, Anthropic 46 (33 `web_search`, 13 `web_fetch`), HF 1. Tavily credits ~27 (rate-card **ESTIMATED**, not provider-reported). Notable: the anchor-resolution leg spent **zero** Tavily credits, resolving every issuer timestamp and the GENI share count through free `web_search`/`WebFetch` against SEC EDGAR and issuer IR pages — the ordering rule working as intended. Per-call timestamps are attributed to each sub-agent's execution window, since the sub-agents did not return per-call clock times; stated so `state.web_duplicate_targets` is read with that limitation in view.

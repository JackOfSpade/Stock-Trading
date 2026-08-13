2026-08-12
<!-- d1_scan_through_utc: 2026-08-12T22:24:00Z -->

# Daily Market Development Scan — 2026-08-12 (Wed, MT)

**Scan window:** 2026-08-11 16:22 MT → 2026-08-12 16:24 MT (24.0h). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-11T22:22:49Z -->` parsed cleanly from the `Daily.md` on disk, cross-checked against that file's own commit at 2026-08-11T22:33:32Z (agree to within 11 min — the prior run's write-then-commit interval, not drift). `state.routine_catchup_window` reports `window_days = 0.98`, `never_completed = false` — cadence-normal, so no `CATCHUP` token is owed on this run's completion note.

**This window contains exactly ONE trading session — Wednesday 2026-08-12.** `state.trading_day_today` reads `today = 2026-08-12`, `is_trading_day = true`, `last_trading_day = 2026-08-12`.

**Tape (2026-08-12 regular session; every ETF/equity figure from IBKR regular-session `ONE_DAY` bars, `outside_rth=false`, denominator = the 2026-08-11 close):** SPY 772.49 (+0.25%, from 770.56), QQQ 723.70 (+0.73%), IWM 302.71 (+0.57%), equal-weight RSP 221.08 (+0.18%). **VIX 14.55 (−4.78% from 15.28)** — FMP `chart` historical-price-eod, the bar carrying its own `"date":"2026-08-12"` field, not a live quote. Brent ~$90/bbl (+1.24%), WTI ~$84.3 (+1.3%). Gold ~$4,437/oz, a nine-week high (+1.6%). hy_oas 2.85 (2026-07 monthly, latest available — no daily series exists). Index cross-check via CNBC: S&P 500 7,748.50 (+0.26%, matching SPY to 1bp), Nasdaq Composite 26,588.49 (+0.54%), Dow 53,770.27 (−0.04%).

**The one-line characterisation: an in-line CPI print released the September-hike pressure, the AI-infrastructure complex went vertical on earnings, and the equity market closed at highs with its volatility gauge in the LOW regime — on the same day the Iran conflict produced its first fatal attack on shipping, Brent went to $90 and gold hit a nine-week high.** The two complexes disagreed openly today. Equity vol says calm; the commodity and haven complex says escalation. That split, not the CPI print, is the day's real content — and it is the exposure the park KEEP deliberately accepts (see PARK ALLOCATION CALL → `theater_check`).

---

## TL;DR

- **Exits triggered: none new.** Yesterday's staged `B:ISRG` convergence exit **FILLED today** — SELL 0.1388 @ 402.64, 13:30:02Z, realized P&L **+$6.79** (+13.9% on a $48.92 cost basis). That closes the trade; it is not a new action. `state.current_positions` still shows the tranche `EXIT_PENDING`, so **D2a Step 0 owes the CLOSE tonight**.
- **New entry candidates: none.** Today produced the richest B-eligible post-event cohort in recent memory — **17 names ≥5% close-to-close on identifiable events** — and not one is routable: B's router is DO-NOT-ACTIVATE (binding since 2026-08-05) and `state.entry_staging_allowed.entries_allowed` is FALSE. The cohort is handed to W2 as shortlist material, not staged. See OPPORTUNITY CHECK.
- **Add candidates: none flagged** (14 A/B/D tranches evaluated, **0 declined at the HARD GATE** — the first zero since the field was introduced, because the one structurally-ineligible tranche left the book today). **UBER −4.05% was the closest thing to a trigger the book has produced this week and is declined on an epistemic ground, not a merit one:** the driver could not be identified, and "no invalidation news" is not the same claim as "no news I could find."
- **Watchlist changes: none.** Deliberate — see WATCHLIST.
- **Regime review: no review recommended.** But note a real technical change: **VIX 14.55 closes BELOW the 15.00 LOW boundary**, so D2a's step 1e will flip `VIX_REGIME` NORMAL → LOW tonight. It does not move any router, because every current DO-NOT-ACTIVATE is produced by the fundamental/shock-overlay half, not the technical half.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**(a) Iran / Strait of Hormuz — first fatal attack on shipping since the war began. MATERIAL ESCALATION.**
- Iran-backed Houthis struck the Egyptian-owned cargo ship **Tihamah** with missiles in the Bab el-Mandeb Strait, **killing 4–6** (reports vary: 4 crew per Reuters, 6 total including 2 rescuers per UPI). Reported as the **first fatal Houthi strike on shipping since the war began 2026-02-28**. Sources: [Reuters](https://www.reuters.com/world/china/three-killed-attacks-ships-red-sea-gulf-sources-say-2026-08-11), [UPI](https://www.upi.com/Top_News/World-News/2026/08/11/yemen-houthis-kill-6-in-attack/1181786477788).
- A **US helicopter fired a Hellfire missile** at the Panama-flagged container ship **Vela Nova** off Pakistan after it allegedly tried to evade the US blockade on Iran-linked shipping (WSJ reporting via Reuters; no CENTCOM comment).
- **Transit collapse deepened: 8 vessels crossed Hormuz on Tuesday 2026-08-11**, against a 130–140/day pre-war baseline (Al Jazeera, citing shipping trackers). Cumulative CENTCOM blockade actions: 55 merchant ships redirected, 3 disabled, 2 boarded (Lloyd's List Intelligence, [Hormuz brief 12 Aug](https://www.lloydslistintelligence.com/resources/blog/strait-of-hormuz-brief-12-august-2026)).
- Iran's new National Security Council chief Rezaei told China's ambassador the Strait **"will not be opened"** until the US lifts the naval blockade, unfreezes Iranian assets and ends regional conflicts ([Al Jazeera](https://www.aljazeera.com/news/2026/8/12/iran-refutes-trumps-claim-to-control-hormuz-whats-the-latest-in-talks)). Trump reiterated the US has "total control" of the strait. Iran–Oman talks on joint future management of the waterway continue; wider US–Iran talks are largely paused.
- **Observable reaction:** Brent +1.24% to ~$90, WTI +1.3% to ~$84.3. Gold to a nine-week high ~$4,437 (+1.6%). Dollar index round-tripped — fell to 99.73 on the CPI print, then erased the loss "amid Hormuz uncertainty." European equities fell (FTSE 100 lower "as MidEast risks weigh despite in-line U.S. inflation"). **US equities did not react at all**: SPY +0.25%, XLE +0.16%, VIX −4.78%.
- The IEA (2026-08-12) cut its 2026 oil-demand forecast **again** — now expecting demand to *fall* 1.6 mb/d in 2026, a further 510 kb/d cut versus its July forecast, explicitly citing the Hormuz closure's effect on consumption.

**(b) Nothing else market-wide.** No material bankruptcy, disaster, or unscheduled regulatory/enforcement action affecting global risk assets surfaced in the window.

### 2. Scheduled events that resolved today

**(a) US July CPI — the window's dominant scheduled event. PRINTED IN LINE ACROSS ALL FOUR HEADLINE MEASURES.** Source: the [BLS release itself](https://www.bls.gov/news.release/archives/cpi_08122026.htm), corroborated by [CNBC](https://www.cnbc.com/2026/08/12/cpi-inflation-report-july-2026.html).

| Measure | Actual | Consensus | Prior |
|---|---|---|---|
| Headline MoM (SA) | +0.1% | +0.1% | — |
| Headline YoY | **+3.4%** | +3.4% | +3.5% |
| Core MoM (SA) | +0.2% | +0.2% | — |
| Core YoY | **+2.5%** | +2.5% | +2.6% |

Components (BLS): shelter +0.1% MoM / +3.2% YoY, about two-thirds of the monthly headline increase; OER +0.3%; lodging away from home −2.8%. **Energy −1.5% MoM but +14.7% YoY, gasoline +24.6% YoY** — the Hormuz shock is now the single largest line in the year-over-year headline. Food +0.1% MoM / +3.0% YoY. Airline fares +2.2%, medical care +0.4%, used vehicles +0.4%.

**Reaction — the September hike came off the table, and moved to Q4 rather than disappearing.** Sources report a range rather than one number and the range is reported here as a range, not resolved to a false precision: September-hike odds fell from roughly 50–52% pre-print (they had been pushed *up* to ~51.7% on Tuesday by Cleveland Fed President Hammack saying current rates "may not be restrictive enough" and that "multiple hikes could still be needed") to **~34–40%** post-print — 34% per The Kobeissi Letter, "less than 40%" per Morningstar, ~40% implied by CNBC's ~60% hold-odds figure citing CME FedWatch. **October-hike odds ~53%; December ~73%** (CME FedWatch via CNBC). Sage Advisory's Rob Williams: *"the combination of CPI and payroll takes September off the table… the markets are gravitating towards December."*

**(b) Cisco (CSCO) — Q4 FY26, after today's close. Clean double beat, sold off after hours.** EPS $1.22 vs $1.17 est; revenue $17.252B vs $16.836B est (+18% YoY); product revenue +24%; RPO $46.7B (+7%); AI orders >$4B against $3.7B guided; FY27 AI revenue target raised to $6.5–7B ([Cisco newsroom](https://newsroom.cisco.com/c/r/newsroom/en/us/a/y2026/m08/cisco-reports-fourth-quarter-earnings.html)). CSCO closed the **regular session +2.86%** (123.88, IBKR daily bar) and then fell ~3.07% after hours on the print — a beat already in the price after a ~58–60% YTD run.

**(c) Other resolved catalysts ≥$2B** are enumerated with confirmed closes in DEVELOPMENTS 3 below.

**(d) No FDA PDUFA outcome and no non-US central-bank decision** resolved in the window for any name ≥$2B — searched and not found, which is a finding, not a gap.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 population rail (mechanical cost bound, never a significance claim): US-listed, market cap ≥$2B, moved ≥2% close-to-close today, attributable to an identifiable public event. **Every figure below is an IBKR regular-session `ONE_DAY` bar with `outside_rth=false`, both bar dates confirmed** — never a snapshot. **21 names reached Layer-2 judgment; 19 written up as significant, 2 rejected.**

**The day had one structure and it was not the CPI print: an AI-infrastructure earnings cluster detonated and dragged an entire supply chain with it.** Seven of the top eight movers are the same trade.

| Ticker | Move | Event | Significance |
|---|---|---|---|
| **NBIS** | **+34.15%** (193.23→259.20) | Q2 revenue surge on AI-cloud contracts; FY26 revenue guidance reaffirmed, year-end contracted-power targets raised | 75 — largest move on the tape, on its own reported numbers |
| **QNT** | **+27.97%** (56.06→71.74) | Multi-year Oracle Cloud Infrastructure partnership (Helios quantum system in OCI); FY26 bookings ≥$120M reaffirmed | 75 — a named, dated commercial contract, not sentiment |
| **CRWV** | **+19.28%** (90.32→107.73) | Q2 revenue +112% YoY to $2.58B; **backlog $104B**, nearly doubled since November; FY26 revenue guide raised to $12.4–13.2B, capex guide raised to $35–39B | 75 — the backlog figure is the sector's load-bearing datapoint |
| **SMCI** | **+19.02%** (31.60→37.61) | Q4 FY26 revenue $11.1B (~+100% YoY), gross margin ~doubled to 17.5%, **FY27 revenue guide $65–72B vs $11.68B consensus** | 75 — a guide that far above consensus is a regime statement about AI-server demand |
| **MRX** | **+18.69%** (59.93→71.13) | Record Q2: revenue +39% YoY to $695.8M, EPS $1.64 vs $1.36 est | 60 — clean beat, unrelated to the AI cluster |
| **WEN** | **+14.70%** (7.55→8.66) | FT reports Trian (Peltz), Flynn Group and BlueFive preparing a take-private bid; no formal bid submitted | 60 — real dated event, but a report of a prospective bid, not a bid |
| **CAVA** | **+14.24%** (60.81→69.47) | Q2 revenue +31.3% YoY to $365.4M (beat); comps +9.0% on +5.3% traffic | 60 — traffic-led comp beat is high-quality for a restaurant name |
| **LITE** | **+13.64%** (820.59→932.47) | Q4 FY26 revenue $1.01B (+109% YoY, first $1B quarter), beat ~$985M consensus; guidance raised; pump lasers sold out, shipments +80% YoY | 75 — "sold out" is a capacity statement, the strongest form of this cluster's evidence |
| **FRVO** | **−16.59%** (24.17→20.16) | Q2 operating loss $28.7M, net loss $55.9M | 60 — largest decliner; a growth-stage miss |
| **EYE** | **−11.56%** (22.06→19.51) | FY guidance (adj EPS $0.94–1.09, revenue $2.037–2.076B) missed consensus | 60 — **note: news wires reported this as "−6%"; the exchange close was −11.56%** |
| **DELL** | **+9.87%** (440.97→484.50) | Sympathy with SMCI/CRWV; Dell's own print is 2026-09-03. Goldman reiterated Buy, PT raised to $510 | 60 — a $293B mega-cap moving ~10% on *someone else's* guide is itself the signal |
| **IREN** | **+9.86%** (39.75→43.67) | Sympathy with NBIS/CRWV plus its own recent $2.8B AI contract | 45 — genuine but derivative |
| **NOK** | **+9.32%** (9.44→10.32) | Sympathy (supplies CoreWeave's optical/IP backbone) plus own AI-RAN platform news | 45 — derivative, with a real supply-chain link |
| **ACM** | **−8.96%** (67.05→61.04) | Weak fiscal Q3: revenue $3.59B (−14% YoY); Americas NSR $808.4M vs $1.24B consensus | 60 — **wires reported "−6%"; exchange close −8.96%.** Also note the week's slide runs 74.93 (08-06) → 61.04 |
| **HPE** | **+8.11%** (54.38→58.79) | Sympathy on SMCI's guide; Goldman trimmed PT to $75 from $79 on competition | 45 — derivative, and the only cluster name with a PT *cut* today |
| **REZI** | **+6.06%** (24.24→25.71) | Q2 revenue $1.98B beat, adj EPS $0.83 vs $0.68 est; headline FY guide cut is ADI spin-off mechanics, not underlying weakness | 45 — the guide-cut headline misreads the release |
| **ORCL** | **+5.36%** (145.48→153.28) | Quantinuum OCI partnership (the other side of QNT's move); also a circulating AI-capex-driven layoffs report | 60 — a $420B name moving 5% on a partnership |
| **CSCO** | **+2.86%** (120.43→123.88) | Regular-session run into its own AMC print (see DEVELOPMENTS 2b) | 45 — `below_spec_floor` |
| **OPLN** | **−3.20%** (36.50→35.33) | Priced an 8M-share secondary by an Apax-affiliated holder; company receives no proceeds | 45 — mechanical dilution overhang; `below_spec_floor` |

**Rejected at Layer 2 (recorded, per §19's logging contract):**
- **SNAP −5.63%** (5.51→5.20) — **clears the legacy ≥5% bar and is rejected anyway**, because no dated 2026-08-12 catalyst could be sourced; only stale, undated PT cuts (UBS, Goldman). Rejection conviction 45, deliberately not higher: a −5.6% move in a $9B name usually *has* a cause, and failing to find one is weaker evidence than finding none exists. This is the honest record of an unexplained move, not a claim it was noise.
- **TPR −4.24%** (160.54→153.74) — rejected. The only driver on offer is valuation caution ahead of tomorrow's Q4 print; that is positioning, not an event. Rejection conviction 45.

**Also checked and excluded from the population for want of any identifiable driver** (they fail the rail's event-attributability clause, and none clears the legacy 5% bar, so none is owed a `rejected_notable` slot): PINS −3.58%, KSS +4.22%, FISV −2.20%, TJX −2.01%, ZTS ~−2.4%.

> **RECURRING FINDING, SECOND CONSECUTIVE SESSION — news-reported reactions disagree with exchange-measured closes, and the error is not small.** Today: EYE reported "−6%" vs a measured **−11.56%**; ACM reported "−6%" vs **−8.96%**; WEN reported "+13%" vs **+14.70%**. Yesterday's screen logged the same class of disagreement on 6 of 7 checked names. Both sessions used wire copy only for *discovery* and IBKR daily bars for every logged number, so nothing has been mis-logged — but a routine that took wire percentages at face value would today have mis-sized two names by ~3 and ~5.5 percentage points, and EYE's true move is nearly double what was reported. This is the §19 PRICE BASIS rule earning its keep on live data twice in two days.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Layer-1 rail: any GICS sector ≥1% at sector-ETF level, or notable intraday dispersion. All figures IBKR regular-session `ONE_DAY` bars, both dates confirmed. **Top-to-bottom dispersion 2.73pp** (XLK +1.4886% to XLB −1.2397%), against 1.97pp yesterday and 5.95pp Monday — a modest re-widening, still a quiet interior. Six of eleven sectors closed inside ±0.5%; three cleared ±1%.

| Rank | Sector (ETF) | Close-to-close |
|---|---|---|
| 1 | Technology (XLK) | **+1.4886%** |
| 2 | Real Estate (XLRE) | +0.9302% |
| 3 | Utilities (XLU) | +0.4812% |
| 4 | Consumer Staples (XLP) | +0.4605% |
| 5 | Health Care (XLV) | +0.2560% |
| 6 | Financials (XLF) | +0.2076% |
| 7 | Energy (XLE) | +0.1641% |
| 8 | Industrials (XLI) | +0.0970% |
| 9 | Communication Services (XLC) | −0.8987% |
| 10 | Consumer Discretionary (XLY) | −1.1321% |
| 11 | Materials (XLB) | −1.2397% |

**Surfaced and judged (4 items — 3 on the ≥1% rail, 1 via §19's escape valve):**

- **Technology +1.49% — significant, conviction 60.** Driver is the AI-infrastructure earnings cluster of DEVELOPMENTS 3 plus the benign CPI. The point worth recording is proportional: on a day the index rose 0.25%, one sector rose 1.49%. Tech *was* the tape.
- **Energy +0.16% — significant, conviction 60. Surfaced via the escape valve as a NON-REACTION, and it is the most informative sector item on the tape.** On the day the Iran conflict produced its first shipping fatalities, Hormuz transits hit 8 vessels against a 130–140 pre-war baseline, Brent went to ~$90 and the IEA cut demand by a further 510 kb/d, the energy sector ETF moved **sixteen basis points**. Yesterday's screen recorded a version of the same thing (tankers *fell* on the day a 20% transit levy was announced). Two sessions running, US energy equities have declined to price Hormuz escalation that the crude and gold markets are pricing in real time. That is a standing, dated, falsifiable observation about where this risk is and is not being expressed.
- **Consumer Discretionary −1.13% — significant, conviction 45, with the significance heavily qualified.** AMZN (~25% of XLY) closed −1.83%, so much of the sector print is a weighting artifact rather than a sector signal. Corroborating same-day framing from Citi's Scott Chronert, who called the sector "lagging" and noted traditional retailers ex-Amazon/Tesla "have struggled to attract investor interest."
- **Materials −1.24% — significant, conviction 30, DRIVER NOT IDENTIFIED.** Worst sector on an up day, and a targeted search across materials news, gold/dollar/copper commentary and XLB-specific coverage produced no reliably-dated 2026-08-12 cause. Same-day commodity moves (gold ~flat +0.01%, copper +0.36%) do not explain a 1.24% sector decline. Logged with the driver explicitly unknown rather than assigned a plausible-sounding one.

**No sector cleared the legacy ≥2% bar**, so all four surfacings are `ai_only` and the record-only benchmark rule contributed nothing today.

**Dispersion note beyond the sector table.** QQQ (+0.73%) and IWM (+0.57%) both beat SPY (+0.25%), which beat equal-weight RSP (+0.18%). Gains were concentrated, not broad — and equity breadth *fell* on an up day (below). A rising index built out of a narrowing interior is the same structure as Monday, in the opposite direction.

### 5. Notable commentary

- **Morgan Stanley Wealth Management, Ellen Zentner:** *"In-line inflation will keep the 'no need to hike rates' narrative intact… unless [upcoming] numbers tell a much different story, the Fed will likely still be in a position to leave rates unchanged next month."*
- **Sage Advisory, Rob Williams:** *"the combination of CPI and payroll takes September off the table… the markets are gravitating towards December."*
- **Reuters Instant View, Marc Chandler (Bannockburn):** CPI in line, dollar "didn't go anywhere," market "may have downgraded very slightly the odds of a September rate hike." An unnamed panelist added the useful qualifier: *"For the Federal Reserve, this is a helpful report rather than an all-clear — headline inflation at 3.4% remains comfortably above target and energy prices are still nearly 15% higher than a year ago."*
- **Cleveland Fed President Beth Hammack** (Tuesday 2026-08-11, market-moving into today): current rates "may not be restrictive enough," "multiple hikes could still be needed." This is the hawkish counterweight that today's print partially offset — it is why September-hike odds were *rising* into the CPI release. *Sourced to a newsletter rather than a Fed transcript; treated as lower-confidence.*
- **Goldman Sachs:** reiterated Buy on Dell, HPE, NetApp on agentic-AI hardware demand; Dell PT to $510, NetApp to $210 (from $200), HPE trimmed to $75 (from $79) on competition.
- **Yardeni Research** lifted its S&P 500 year-end target to 8,400 (headline-level only — the underlying note was not retrievable, MarketWatch returned 403).
- **Norway's NBIM** reported a record H1 profit above $182B (+9.4%) and disclosed a first-ever SpaceX stake (0.05%), alongside 1.3% of Nvidia ($61.8B) and 1.2% of Apple ($52.7B) as of June 30.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

Swept the **UNION** of `state.current_positions` (15 rows) and live IBKR `get_account_positions` (11 equity lines incl. the VOO park), per the ITEM 14 union rule.

**Union reconciliation — every live broker line maps to a BigQuery row, and the share counts tie exactly:** AMZN 0.3464 = 0.191 + 0.1554; CRM 0.2275; DIS 0.7244 = 0.2822 + 0.4422; GEV 0.1244; GOOGL 0.2577 = 0.1534 + 0.1043; ISRG 0.1091; MSCI 0.0863; RTX 0.1601; TSM 0.1550 = 0.0891 + 0.0659; UBER 0.5156. **There is NO position present in the connector but absent from `state.current_positions`, so no `position_reconciliation_lag` alert is owed and none was raised.**

**The one divergence runs the other way, and that direction is out of this alert's scope by construction.** `B:ISRG:2026-07-21` still reads `EXIT_PENDING` in BigQuery, but the order **filled today**: `get_account_trades` returns SELL 0.1388 ISRG @ 402.64, MARKET/DAY, trade `0001296f.6a7c61f6.01.01`, order 1636131074, 2026-08-12T13:30:02Z, commission 0.351464, net 55.886432, **realized P&L +6.79338**. The combined broker line went 0.2479 → 0.1091, leaving only the untouched D tranche exactly as yesterday's exit note specified. `state.position_reconciliation` and the `position_reconciliation_lag` alert both detect connector-present/BigQuery-absent; this is BigQuery-present/connector-absent, i.e. a pending CLOSE write, which is precisely **D2a Step 0's** job tonight. Recorded here so it cannot be silently dropped, not alerted.

**Per-position mechanical triggers:**

| Position | Convergence target | Live | Hit? | Time exit | Due? |
|---|---|---|---|---|---|
| B:MSCI:2026-07-27 | 615 | 563.01 | **NO** — 8.4% below | 2026-09-25 | NO (44 days) |
| B:ISRG:2026-07-21 | 400 | — | already exited (filled 402.64 today) | 2026-09-18 | n/a |
| All 13 D tranches | none (NULL) | — | n/a | none (NULL) | n/a |

**No new exit is triggered.** Every D tranche carries `convergence_target = NULL` and `time_exit_date = NULL` by design — Strategy D has no maximum hold and no price stop, and the `ltcg_date` fields several tranches carry are tax markers, not exits (the bigquery/121 correction moved RTX's mis-filed date out of `time_exit_date` for exactly this reason). MSCI is the only live mechanical trigger in the book and it is 8.4% away, drifting the wrong way.

### PER-STRATEGY KILL-TRIGGER SWEEP

Engine row `perf.kill_flags` is dated 2026-08-11 (D1 runs before D2a), so `current_drawdown` is **refreshed unconditionally against today's live marks**, per ITEM 16 — no judgment predicate on whether to run it.

| Strategy | Engine deployed unit value | Peak | Engine drawdown | **Refreshed drawdown** | Kill threshold | Flags |
|---|---|---|---|---|---|---|
| **B** | 1.202674 | 1.202674 | 0.00% | **~0.00%** (MSCI +0.23% today; ISRG exit realized +$6.79) | −50% | all FALSE |
| **D** | 1.090497 | 1.092373 | −0.17% | **~−0.11%** (13 tranches net ≈ +$0.40 on ≈$615 market value, +0.06%) | −50% | all FALSE |

- **Drawdown kill (#1):** not triggered, not close. B is at its own peak; D is 11bp below its peak against a −50% threshold.
- **Runaway-success (#3):** not triggered. B deployed TWR 1.2027 (+20.3%) has not doubled; 11 closed trades against the 30-trade gate. D has 0 closed trades.
- **Interim underperformance warning:** `interim_underperf_warning = FALSE` for both, and neither is even eligible — the rule requires `deployed_days >= 90` and both strategies stand at **74**. B's beta-adjusted excess vs SGOV is **+19.0%**, D's **+7.9%**; both are positive, i.e. the opposite sign from the −15% trigger. No alert raised, and there is no open alert of this category to heal-resolve.
- **B open-book pairwise correlation (KL #12, finding M1):** `analytics.b_pairwise_correlation` returns `n_positions = 2, n_pairs = 1, avg_offdiagonal_corr = NULL, min_overlap_days = NULL`. The NULL is correct and is the view working as designed — ISRG (entered 2026-07-21) and MSCI (2026-07-27) have nothing like 40 overlapping days, so the pair is excluded from the average as thin history. The alert condition (`avg > 0.5 AND n >= 2 AND min_overlap >= 40`) fails on NULL and no alert is due. **It goes structurally inert tomorrow**: once D2a books the ISRG close, B holds one position and `n_positions = 1 < 2`.

### Thesis-invalidation check against today's Developments

For each open position, does any Development trigger a judgment-laden thesis-invalidation criterion in its entry record? **No position is invalidated.** The three held names that moved ≥2% are treated individually because they are the only ones where the question is live:

- **UBER −4.05% (75.36), Strategy D, invalidation criteria UNBREACHED.** Criteria are gross-bookings cc growth <~15% for 2 consecutive quarters; adj-EBITDA margin as % of GB contracting YoY 2 consecutive quarters; Uber One membership stalling/declining sequentially; metric-immutability on GB disclosure. **None of the four is a price criterion and no company-reported data landed today**, so none can have moved. Strategy D lists "adverse price movement with no invalidation news" as explicitly *not* exit-triggering. NOT an exit. The move is discussed as a possible ADD below, where it fails on different grounds.
- **CRM −2.10% (193.32), Strategy D, UNBREACHED.** Only in-window item is a Wells Fargo PT raise to $205 from $200 at Equal Weight — a *positive* opinion action, and opinion touches none of the four criteria (Agentforce/Data-360 ARR growth, cRPO, non-GAAP operating margin, FY27 revenue guide), all of which are company-reported metrics next updated at the 2026-08-26 print.
- **GEV +2.77% (1039.90), Strategy D, UNBREACHED.** An up-move; no invalidation question arises. The one attribution on offer (TradingKey citing "renewed analyst upgrades" and raised FY FCF guidance) **could not be confirmed for this window** — the verified Bernstein/Guggenheim/TD Cowen PT raises are dated 2026-07-23, before it. Recorded as unattributed rather than credited.

Two further in-window items on held names, neither invalidating: **ISRG** — Oppenheimer upgraded to Outperform, PT $500 (2026-08-12); **TSM** — Bernstein maintained Outperform and raised PT to $554 from $430 (2026-08-11). Both are sell-side opinion and neither touches a company-reported criterion.

**One live item to carry forward: MSCI's August 2026 Index Review results were scheduled for release after today's US close (~17:00 ET) and were not public at scan time.** MSCI's own first invalidation criterion is "first ratings downgrade from any covering analyst," and an index review is the sort of event that moves sell-side views. Nothing to act on tonight; flagged so tomorrow's scan reads it against the criterion rather than discovering it late.

### Watchlist candidate status

No Development changes the candidacy status of any queued name. None of today's 21 screened movers is on the A queue, the D re-screen pipeline, or any B tracking section.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D is `long_horizon` and excluded here by design).

**Result: NO new entry candidates.** The reasoning is substantive rather than an absence of material, so it is recorded rather than summarised away.

**Strategy B — a rich cohort, none of it routable.** Today produced **17 names clearing B's frozen Entry criterion 1** (≥5% close-to-const-to-close on event day, `strategy/04_strategy_b.md`, spec_hash-frozen): NBIS, QNT, CRWV, SMCI, MRX, WEN, CAVA, LITE, FRVO, EYE, DELL, IREN, NOK, ACM, HPE, REZI, ORCL. That is the largest single-day B-eligible population in recent scans, and it is not a coincidence — it is one earnings cluster plus its supply chain. **None is routed as a B candidate, for two independent and individually sufficient reasons:**
1. **B's router is DO-NOT-ACTIVATE**, binding since 2026-08-05 (`div-B-202607-1`), produced by the Strategy.md:121 universal `shock_overlay = acute` reconciliation override. That blocks NEW B entries outright. Today's Hormuz escalation makes the override's precondition *more* firmly satisfied, not less.
2. **`state.entry_staging_allowed.entries_allowed = FALSE`** — `book_drawdown_soft_breach` (NAV −18.37% below flow-adjusted peak, an artifact of the 2026-08-11 $3,525 external withdrawal) plus `owner_confirmation_entries_halted = TRUE`. Total cash is $52.43.

**Handed to W2, which is the routine that owns this.** W2's post-event screen runs weekly over a 10-day retrospective window, so this entire cohort falls inside its next scan regardless. Recording it here as a dated hand-off rather than a staged action is the correct disposition — and the cluster's *shape* (a single AI-capex theme producing 17 simultaneous ≥5% movers, several of them pure sympathy moves in $70–290B names) is exactly the recurring-class evidence §19 directs toward SL1 ideation.

**Strategy C — window open, no candidate flagged, and one thing worth pre-registering.** C is the only strategy whose router currently permits a new entry (`HYBRID ACTIVATE (FOMC-only)`). The September FOMC sits inside C's 45-day Entry criterion 1 window. **No candidate is flagged, because nothing was *newly announced* today** — D1's routing bullet requires a newly-announced qualifying catalyst, and a scheduled FOMC is not that. But the honest observation is that today changed the *pricing* of that event materially (September-hike odds roughly halved in one session while December held at ~73%), and C's actual historical gating criterion across four consecutive FOMC NO-GOs has been "no documentable divergence from market pricing." A repricing of this size is the first thing in months that could plausibly create such a divergence. **Routed to W1**, which owns the catalyst calendar and runs Sunday — not converted into an action bullet here, per the default-NO-on-ambiguity posture.

**Strategy E — no pair.** Today's tape was the opposite of pair material: the AI-infrastructure cohort moved violently *together* (eight names +8% to +34%), which is convergence, not divergence. The one genuine divergence on the tape — energy equities flat against Brent at $90 — is a commodity-vs-equity relationship, not an L/S equity pair. **The FRO/APA Hormuz tanker-vs-E&P pair from 2026-08-10 is NOT reopened**: D2 adjudicated it NO-GO the same day on Entry criterion 3 (252-day correlation 0.048 against a 0.5 floor) and closed it `do_not_reprobe`. Today's escalation does not repair a correlation of 0.048; that pair failed on arithmetic, not on thesis.

**Strategy A — none.** No newly-announced catalyst within A's 6-month horizon surfaced on any name, and the router is DO-NOT-ACTIVATE (over-determined per `div-A-202607-1`: `growth_momentum = decelerating` AND `policy_stance = hawkish` both hold, which forces the Strategy.md:123 override).

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

**14 tranches evaluated. 0 flagged. 0 declined at the HARD GATE.**

The count moves 15 → 14 because `B:ISRG:2026-07-21` **filled and left the book today**; it is no longer an open position and is correctly out of scope. That same tranche was the *only* holding carrying `invalidation_status.status = NOT_DISCRETELY_RECORDED_AT_ENTRY`, which is why `n_declined_hard_gate` reads **0 for the first time** since the field was introduced. This is a real structural improvement in the book's legibility, not a quiet metric drift: **every one of the 14 remaining tranches has discretely-recorded, evaluable invalidation criteria**, so `invalidation_criteria_evaluable = true` across the board and the HARD GATE was genuinely applied to all 14 rather than short-circuiting on any.

`mark_vs_cost_pct` is computed from the 2026-08-12 regular-session close against each tranche's own commission-inclusive cost basis (per §19's SCOPE clause, the add-candidate mark is a current valuation, not a screen figure; the session close is used for series continuity with prior sweeps).

| Position | Today | mark vs cost | Disposition |
|---|---|---|---|
| D:UBER:2026-07-09 | **−4.05%** | +2.94% | declined — driver unidentified (see below) |
| D:CRM:2026-07-09 | −2.10% | +20.56% | declined — a 2% pullback on a name up 20% is a wobble, not a dip; symmetric to D's own "not exit-triggering" test |
| D:AMZN:2026-07-09 | −1.83% | +10.79% | declined — same wobble reasoning as yesterday, at a smaller magnitude |
| D:AMZN:2026-07-30 | −1.83% | +0.60% | declined — this tranche *is* the 2026-07-30 add, filled into a gap-up at 263.859; adding again 13 days later on a 1.8% dip is chasing |
| D:DIS:2026-05-07 | −0.30% | −7.28% | declined — no fresh trigger. Criteria were AFFIRMATIVELY re-passed at the Q3 FY26 checkpoint (SVOD op margin ~13%, buyback target raised to ≥$9B, FY26/FY27 EPS growth reiterated); a −7% mark is the thesis being early, not distressed |
| D:DIS:2026-08-05 | −0.30% | −0.54% | declined — a case made and deferred on 08-10 does not strengthen by restatement |
| D:GOOGL:2026-07-09 | −0.08% | −4.53% | declined — yesterday's criterion-4 objection (federal appellate action targeting the named "adverse structural remedy" criterion) is **unresolved, not withdrawn**; a flat session resolves nothing |
| D:GOOGL:2026-07-26 | −0.08% | +4.79% | declined — same criterion-4 reasoning; also not a dip, up 4.79% on cost |
| D:RTX:2026-04-27 | −0.49% | +25.93% | declined — best performer in the book, no dip, no fresh conviction event. Only in-window items are a routine $0.73 dividend declaration and a 5c Erste FY26 EPS estimate nudge. All six criteria unbreached |
| B:MSCI:2026-07-27 | +0.23% | −2.81% | declined — **and specifically premature**: MSCI's own August Index Review results were due after today's close and were not public at scan time. Adding immediately ahead of an unread event that bears on its first invalidation criterion (any analyst downgrade) is the wrong sequence |
| D:ISRG:2026-07-20 | +0.01% | +14.81% | declined — Oppenheimer's upgrade to Outperform (PT $500) is in-window and real, but **sell-side opinion is structurally not a D add trigger**: D's trigger (b) requires a quarter's data confirming the trend metric or a catalyst's timeline firming, and all four ISRG criteria are company-reported. Also, the book *reduced* ISRG today via the B exit |
| D:TSM:2026-07-21 | +1.68% | +0.30% | declined — up on the day, no dip. Bernstein's PT raise to $554 is the same opinion-not-metric category as ISRG |
| D:TSM:2026-07-29 | +1.68% | +9.23% | declined — up 9.23% on cost, no dip, no metric confirmation |
| D:GEV:2026-08-03 | **+2.77%** | +7.22% | declined — up strongly, no dip; and the only strengthened-conviction story available (analyst upgrades, raised FY FCF guide) **could not be confirmed inside the window** — the verified PT raises are dated 2026-07-23 |

**The UBER decision is the one worth writing out, because it is the closest the book has come to an add this week and it is declined on an epistemic ground rather than a merit one.**

The case *for* was genuinely strong and better-formed than yesterday's GOOGL: −4.05% is the largest single-day decline in the book; it happened on a day the S&P **rose** 0.25%, so the relative move is −4.3pp; UBER's GICS sector (Industrials, XLI) closed **+0.10%**, so the move is not a sector effect either; a targeted search across earnings, guidance, ratings, regulatory, legal, M&A and management categories returned **no company-specific news**; and all four invalidation criteria are quarterly company-reported metrics that no event today could have moved.

It is declined because **"no invalidation news" and "no news I could find" are different claims, and only the first one satisfies the trigger.** Strategy D's add trigger (a) is "short-term adverse price movement with *no bearing on the multi-year structural drivers*" — an assertion about the cause. I cannot make an assertion about a cause I have not identified. A −4% idiosyncratic move against a flat sector and a rising index almost always has a driver; a single search pass failing to surface it is weak evidence that none exists, and an add sized into an unfound fact is an add sized into a fact you will learn about after you have paid for it. Note also that the position is +2.94% **above** cost — this is a dip from a profit, not a distressed price.

**This decline pre-registers its own resolution, which is the point of writing it down:** if tomorrow's scan identifies UBER's driver and it is immaterial to gross bookings, EBITDA margin or Uber One, the case reopens *stronger* than it stands today — with the cause known, the thesis confirmed intact, and quite possibly at a similar or better price. If instead the driver turns out to bear on one of those three metrics, today's decline will have been the difference between an add and an exit.

**A capital note stated for the record, and deliberately NOT used as the reason for any decline above.** `entries_allowed = FALSE` and cash is $52.43, so D2 could not stage an add today even if one were flagged. Every one of the 14 declines above is written on thesis grounds that would hold with a full wallet — the constraint is noted so the reader knows it exists, not smuggled in as the argument. Yesterday's sweep made the same distinction in the opposite direction.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended.** High bar, and today does not clear it — but the reasoning is worth stating because a real technical input did change.

**What changed:** VIX closed **14.55**, below the 15.00 vocabulary boundary. D2a's step 1e will therefore flip `TECHNICAL_SIGNAL / VIX_REGIME` from NORMAL to **LOW** tonight. This key has now oscillated across that boundary four sessions running (14.90 LOW on 08-07, 15.46 NORMAL, 15.28 NORMAL, 14.55 LOW).

**Why it moves no router.** Every current DO-NOT-ACTIVATE is produced by the *fundamental* half of the reconciliation, not the technical half — and in each case the technical call already reads ACTIVATE:
- **A**: DNA is over-determined by the Strategy.md:123 override (`growth_momentum = decelerating` AND `policy_stance = hawkish`). Both still hold.
- **B**: DNA is produced entirely by the Strategy.md:121 universal `shock_overlay = acute` override. Today's Hormuz escalation strengthens that precondition.
- **D**: DNA from `div-D-202607-1`, resting on the discount-rate regime and the inflation-axis knife-edge.
- A VIX regime shift touches none of these. Making a strategy *more* technically activated does not disturb a fundamental override that is already winning the reconciliation.

**The one item that genuinely argues against a current axis score — and it goes to M1a, not to a router review.** `policy_stance = hawkish` was scored 2026-08-01 partly on "~66% odds of a September hike and roughly two hikes to ~4.125% by year-end." September odds are now ~34–40%. That is the first material evidence against that score since it was set. It does **not** warrant an inter-monthly review, because the axis is about *stance* and the stance has not softened: December-hike odds sit at ~73%, three FOMC members dissented for a hike three weeks ago, and Hammack was arguing for multiple hikes as recently as yesterday. The market repriced *timing*, not direction — "delayed to Q4, not cancelled," in Sage Advisory's phrasing. **Flagged for M1a's next monthly scoring (2026-09-01)** with the specific instruction that the September-vs-December odds split is the thing to score, not the September number alone.

`inflation_trend = stable` is unchanged and today's print supports it: core YoY 2.5% sits inside the 2.47–2.82% band the axis was scored on.

---

## EQUITY-BREADTH OBSERVATION

**Measured value: 69.38% of S&P 500 constituents closing above their own 200-day SMA, attributed to session 2026-08-12.** Written to `events.regime_events`, `scope = 'TECHNICAL_INPUT'`, `key = 'EQUITY_BREADTH_PCT'`.

- **Source:** Barchart `$S5TH` ("S&P 500 Stocks Above 200-Day Average"), live WebFetch, value 69.38 with a published day-change of **−2.52%**.
- **Dating: `date_attribution=inferred_post_close`.** The Barchart page's own session-date field again rendered as an unfilled client-side template placeholder (`[[ item.sessionDateDisplayLong ]]`), so the source states no as-of date. All three fallback preconditions were **checked, not assumed**: (a) D1 is in its normal post-close slot and the 2026-08-12 US session has closed — independently evidenced by IBKR regular-session `ONE_DAY` bars dated 2026-08-12 retrieved this run for 26 separate symbols; (b) this literal token is recorded; (c) the fetch timestamp is recorded (2026-08-12, ~22:2x UTC).
- **Arithmetic tie-out.** 71.17 (this table's own source-dated 2026-08-10 row) × (1 − 0.0252) = 69.3765 ≈ **69.38** ✓. This alone is ambiguous between "69.38 is 08-11's close" and "69.38 is 08-12's close from an 08-11 that also read 71.17," and that ambiguity is stated rather than papered over.
- **The ambiguity is resolved by an INDEPENDENT post-close count, which is the real evidence here.** A Finviz screener run *after today's close* returned **347 of 503** S&P 500 constituents trading above their 200-day SMA = **68.99%** — a genuinely different computation path (Finviz derives it per-ticker from its own price/SMA data; it is not a repost of Barchart's published index). Two independent methods both land at ~69% for the just-closed session. Since the question was whether today's value is ~69 or ~71, an unambiguous "as of now" count of 68.99 settles it in favour of ~69.
- **Cross-check margin: 0.39pp**, far inside the 5pp suppression threshold, so the row is written rather than withheld. Investing.com separately showed 71.17 tagged "Delayed Data·11/08" with a 0.00% change, consistent with 2026-08-11 having closed flat at 71.17 — used only for date-pinning, not counted as a cross-check value.
- **Sources that failed** (recorded because knowing which trackers are unusable is durable): StockCharts `$SPXA200R` — 503 on the legacy URL, a JS-only chart shell on the current one, and `{}` from the raw data endpoint; StreetStats — JS-rendered, and its cached copy is stamped 2026-07-31, twelve days stale; indexindicators.com — canvas-rendered, no text value; MarketInOut — value published as a chart image only.

**Reading: breadth FELL 1.79pp (71.17 → 69.38) on a day the index ROSE 0.25%.** That is the same narrowing the tape showed elsewhere — QQQ +0.73% and SPY +0.25% against equal-weight RSP +0.18%, with one sector (+1.49% tech) accounting for the index's entire gain. A majority of S&P names slipped relative to their own trend while the cap-weighted index made a new high. At 69.38 the level remains comfortably HEALTHY; it is the *direction against the index* that is worth carrying forward. Threshold classification (HEALTHY/WEAK) is D2a's to apply on `scope = 'TECHNICAL_SIGNAL'` and is deliberately not applied here.

**Freshness note:** D1 wrote no breadth row for 2026-08-11, so D2a carried the 2026-08-10 measurement forward at `breadth_measurement_age_days = 1`. Today's row resets that counter to 0.

---

## PARK ALLOCATION CALL

- **vehicle:** **VOO** (KEEP — `state.park_policy_current.vehicle` is VOO, effective 2026-08-03)
- **direction:** keep
- **conviction:** **MEDIUM**, `conviction_pct` **65** (up from 55 yesterday)
- **status:** **BOUND**

**rationale — why VOO beats the runner-up.** The runner-up is SGOV (tier 0), and it is the only real alternative: the menu's intermediate tiers (GOVT, IEF, MUB, LQD, TLT) are all duration bets, and duration remains unattractive on the *specific* ground that the market still prices ~73% odds of a December hike — buying duration here is a bet against a Fed the market itself expects to tighten, merely later than it thought yesterday. So the menu collapses to a tier-0/tier-4 binary, as it has since 2026-08-03. Against SGOV, VOO wins on four dated readings: SPY closed 772.49, **above both its 50-day (747.84) and 200-day (703.99) averages** and roughly 0.10% off its 252-day high; **VIX 14.55 is a LOW-regime print**, below both its recent range and the 15.00 boundary; breadth at 69.38% is HEALTHY; and — decisively — **the single largest scheduled risk to a tier-4 park in the near window has now resolved benignly.** July CPI printed in line on all four headline measures and September-hike odds roughly halved. Yesterday's conviction was cut to 55 explicitly because a dated CPI/PPI pair sat directly ahead; that reason has now expired in the favourable direction, which is what the +10 represents. De-risking to cash *after* the catalyst you were worried about passes cleanly is the classic wrong-way move.

**invalidation — the observable development that would flip this call.** Any Hormuz development that transmits to **equity** risk rather than only to oil and gold: concretely, VIX closing back above 20, or SPY closing below its 50-day average (747.84), or a direct US–Iran kinetic exchange producing US casualties. Separately, on the macro leg: a hot August CPI or PPI print, or Fed commentary that repositions September-hike odds back above ~60% — the level they were at before this print.

**theater_check.** This rationale is not narrating a foregone conclusion, and the strongest evidence against it is stated rather than buried: **today the equity complex and the commodity/haven complex openly disagreed.** VIX fell 4.78% into the LOW regime while gold hit a nine-week high and Brent went to ~$90 on the first fatal attack on shipping of the entire war. In siding with the equity-vol reading I am siding with the surface that is **least** informed about a shipping-lane risk — equity vol would reprice this last, not first, and the honest statement is that a KEEP is directly exposed to the one risk that is actively escalating. That is precisely why conviction is held at MEDIUM 65 and not pushed toward HIGH, despite a benign CPI, a LOW VIX, healthy breadth and an index at its highs — four readings that, taken alone, would justify a much higher number. A second self-check: the runner-up was scored on a specific, dated, falsifiable ground (its motivating catalyst has passed), not strawmanned into a general pro-equity prior; and the same energy non-reaction that supports the KEEP is flagged in DEVELOPMENTS 4 as the tape's most suspicious feature, not omitted from it.

---

## RECOMMENDED ACTIONS

**No recommended actions.**

Stated positively, so D2 is not left inferring it: no new exit is triggered (yesterday's ISRG exit filled today and needs no further staging — D2a Step 0 owes the reconciliation write); no new entry candidate is routable (17 names cleared B's spec floor, all blocked by B's DO-NOT-ACTIVATE router and by `entries_allowed = FALSE`, and all handed to W2); no add is flagged across 14 tranches; no watchlist change is warranted; and no router review is recommended. The PARK ALLOCATION CALL is a KEEP, which D2's PARK ALLOCATION CONVERSION step no-ops by construction since the called vehicle equals the current policy vehicle.

```yaml d1_actions
[]
```

---

## WATCHLIST

**No changes — and the decision not to add is deliberate rather than an oversight.** Today's AI-infrastructure cohort (NBIS, CRWV, SMCI, LITE, IREN, DELL, HPE, NOK) is genuinely interesting structural material, and LITE's first billion-dollar quarter on sold-out pump-laser capacity is the strongest single datapoint in it. None of it is added to the A queue, because A's queue criterion is a *qualifying catalyst within a 6-month horizon* and a routine next quarterly print is not one; adding names on thematic interest alone would dilute a queue already carrying 36 names against a DO-NOT-ACTIVATE router. The cohort's correct destinations are **W2** (post-event shortlist, 10-day retrospective window — it will pick these up automatically) and **SL1** (recurring-class ideation evidence, per §19's below-spec-floor/recurring-class provision).

---

## MEASUREMENT GAPS AND UNOBTAINED ITEMS

Recorded so a later reader can tell an absent measurement from an unattempted one.

- **10Y / 2Y Treasury closes for 2026-08-12 — NOT OBTAINED as dated closes.** Pre-CPI morning readings were 10Y ~4.682%, 2Y ~4.212%; post-market quotes of ~4.66% / ~4.199% could not be confirmed as the 08-12 close rather than a live quote. **No rates figure is asserted as a close anywhere in this scan.** (The same class of gap was flagged on 2026-08-11 and remains open; D2a's step 1e sources treasury rates independently via FMP `economics` and computed the 08-11 spread at +0.48 that way.)
- **September-hike odds — reported as a range (34–40%), not a point.** Vendors genuinely disagree across timestamps: 34% (Kobeissi), "<40%" (Morningstar), ~40% implied (CNBC/CME FedWatch). Resolving this to a single number would be false precision.
- **Materials sector (XLB) −1.24% driver — NOT OBTAINED.** Searched materials news, gold/dollar/copper commentary and XLB-specific coverage; nothing reliably dated to 2026-08-12.
- **SNAP −5.63% driver — NOT OBTAINED.** Recorded in the screen as an explicit unexplained legacy-rule-passing rejection rather than assigned a plausible cause.
- **GEV +2.77% driver — NOT CONFIRMED for this window.** The available attribution cites analyst upgrades without naming firm or date; the verifiable PT raises predate the window by three weeks.
- **MSCI August 2026 Index Review results** — scheduled after today's close, not public at scan time. Carried forward to tomorrow.
- **Exact post-move market caps** for NBIS, CRWV, SMCI, LITE, CAVA, NOK — only pre-move snapshots dated 08-06 to 08-10 were sourced. All clear the $2B rail by a wide margin either way, so the screen's population decision is unaffected.
- **FMP `quote` / `company` / `news` / `economics` endpoints returned ACCESS DENIED (plan-tier gated) throughout this run.** Only `mcp__FMP__calendar` and `mcp__FMP__chart` were usable. All company news sourcing fell back to Tavily/WebSearch, which is slower per name and is the binding constraint on how many mid-tier movers could be individually chased. **This is a recurring capability limit worth noting to W5** — it has now shaped two consecutive D1 runs' coverage depth.
- **FRONTIER-LLM CAPABILITY CHECK: run, NO CAPTURE.** One `hf_fs` paper search on the Wednesday calibration battery (`"LLM calibration confidence uncertainty"`, `--limit 5`) returned five papers, the newest published 2026-03-06 — none inside the ~24h window this light-touch check is scoped to. No `events.decision_log` capture and no `state.strategy_candidates` row, which is the expected default.

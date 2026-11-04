2026-11-04
<!-- d1_scan_through_utc: 2026-11-04T22:48:03Z -->

# Daily Market Development Scan — session 2026-11-04 (Wed), run 2026-11-04 (Wed)

Scan window: 2026-11-03 15:22 MT → 2026-11-04 15:48 MT (~24h). The start is the prior `Daily.md` marker `2026-11-03T22:22:24Z`; the window holds one completed US session, Wednesday 2026-11-04, the day after the US midterms. BigQuery is back (re-authorized overnight), so this is a normal run, not a degraded one.

SCAN MODE: ROUTER-GATED (A DO-NOT-ACTIVATE; B DO-NOT-ACTIVATE; D DO-NOT-ACTIVATE; E DO-NOT-ACTIVATE), read live from `state.current_regime`. C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

Tape: **a broad relief rally on a Democratic midterm sweep, with oil collapsing and chips lagging.** IBKR regular-session closes, 11-03 → 11-04:
- **Indices.** SPY 754.35 → **766.81 (+1.65%, 1.58x its 20-day volume)**; SPX 7568.92 → 7688.73 (+1.58%). DIA **+3.10%**, RSP +1.86%, IWM +1.51%, QQQ +0.97%. **SMH −2.75%** (518.52 → 504.27), giving back Tuesday's +2.0%.
- **Volatility.** VIX 20.83 → **16.61 (−4.22 points)**, inside the NORMAL band (IBKR IND/CBOE bar, delayed flag).
- **Rates, credit, havens.** TLT +0.80%, HYG +0.70%, **GLD +3.68%**; the dollar was reported at a one-month low.
- **Oil.** Brent (BZUSD, provisional same-evening read) **94.60 on 2026-11-04**, against **103.60 on 2026-11-03** in the same FMP series (**−8.69%**). The vendor has revised 11-03 from the 104.36 quoted yesterday. USO −8.07%, XLE −4.74%.
- **Breadth.** Up to **66.13** (from 61.55 as Barchart now carries 11-03), Barchart `$S5TH`, settled-stamped 16:46 ET; single settled source.

## TL;DR

- **Exits triggered: none.** No tranche carries a mechanical trigger, and no development meets an invalidation criterion. UBER's Q3 print (pre-open 11-04) passed c1–c3.
- **New entry candidates: none routed.** **93** names cleared Strategy B's frozen ≥5% floor on their own stamped events, all confirmed on IBKR bars. B is `DO-NOT-ACTIVATE`, so all 93 go to the new-entry index only; no thesis handoff. The screen's durable row did not land this run (see item 3). No new FOMC-class C candidate.
- **Add candidates: none (0 of 12).** The hard gate cleared all 12 tranches today. Six carry triggers (dips on GEV, GOOGL ×2, TSM ×2; strengthened conviction on UBER), all declined because D is DO-NOT-ACTIVATE and has no funding path.
- **Watchlist: 93 changes.** ADD the 93 names to the Strategy B new-entry index.
- **Regime review: no review.** No Gulf/Hormuz settlement is in force (Iran still conditions reopening on lifting the blockade), so the two-session oil drop is not a qualifying resolution event. The VIX and shock-price-leg measured triggers are D2's to detect.

Park: VOO-only pin verified

Paper book (J): 99 calls, 270/30 realized, net_mu -0.56%, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **US midterms: a Democratic sweep.**
  - AP projections give Democrats majorities in **both the House and the Senate** (AP via Fox10, 11-04 07:11 CST). Final seat counts are incomplete; a single secondary count (Variety: Senate D 54–R 44 with MS and AK uncalled, House D 228 with 68 open) is unconfirmed.
  - Also: AP projects Gina Hinojosa (D) won the Texas governorship on a data-center-moratorium pledge (CNBC live blog).
  - **Reaction.** Overnight, Nasdaq futures fell more than 2% and Korean/Taiwanese chipmakers dropped on AI and data-center regulation fears (DW). The cash session then rallied: Dow +3.10% (DIA), S&P +1.58%, defensives and cyclicals together, while chips (SMH −2.75%), defense (RTX −2.64%; NOC and LMT lower) and AI-power names (GEV −9.30%) fell. The dollar hit a one-month low and gold rose about 2.9% (ZeroHedge, AP).
- **Iran / Hormuz: talk, nothing in force.**
  - An Iranian envoy in Dhaka said on 11-04 the strait reopens only if the US lifts its naval blockade and meets Iran's other conditions (TBS News, 12:20 GMT). Rezaei called the US response "not convincing" (Arab Weekly, 11-04); Qatar says proposals are under review after the Doha round. No agreement, ceasefire or blockade lift is in force.
  - No new kinetic event was confirmed in the window; Trump played down imminent post-midterm strikes. One Middle East Online page on mine-layer strikes carries an 11-03 stamp but reads as stale content and is not counted.
  - **Oil.** Brent fell for a third session, to 94.60 (−8.69%) on the FMP series; OilPrice framed it as "traders bet on a US-Iran deal", Reuters as Iran-war uncertainty plus the midterm sweep.
- **Other.** Bitcoin about $78.5k (+1%). Block's 10-Q discloses an October DOJ agreement in principle on a deferred prosecution agreement (about $764M net), not verified against the filing. Euro-area October HICP flash 4.0% (as expected, prior 3.8%; single aggregator).
- **Unmeasured:** bankruptcies, disasters, tariffs and other enforcement. Nothing turned up in the searches run, which were not exhaustive; several searches hit Tavily HTTP 429 limits.

### 2. Scheduled events that resolved in the window

- **ADP, October:** **+86k** against a consensus of about +69k, a beat; September revised to 86k from 90k (Reuters via Yahoo; Fox Business).
- **ISM Services, October:** actual **not obtained** (search rate-limited); consensus 54.8, prior 54.9. UNRESOLVED.
- **Treasury quarterly refunding:** statement content **not obtained**. UNRESOLVED.
- **Fed:** no speakers on 11-04. Hammack (a hike dissenter) and Barkin speak 11-05; Bowman after payrolls on 11-06.
- **Earnings.** The key-less Nasdaq calendar lists 236 reporters for 11-04 with market cap ≥$2B (77 pre-market, 148 after-hours, 11 unspecified), largest TM, ARM (after), MCD (pre), NVO (pre), QCOM (after), UBER (pre, held), CVS (pre), MCK (after). Under the router-gated source limit, non-held names are not researched per name; pre-market reporters that cleared B's floor are in item 3, and after-hours reporters react on 11-05.
  - **UBER (held)**, Q3 2026 from the issuer's 8-K (accepted 2026-11-04 11:55Z, pre-open): gross bookings $59.8B (+20% cc), trips 4.06B (+16%), revenue $14.77B (+10%), non-GAAP EPS $0.88, adjusted EBITDA 5.0% of GB (from 4.5%); Q4 guide GB $63.25–65.25B. Close +4.91%.
- **FDA:** no PDUFA outcome was resolved against FDA's own pages; any in-window action is **UNRESOLVED**.
- **Upcoming:** 11-05 BoE (a hike was expected; not re-verified), Fed's Hammack and Barkin, plus after-hours reporters' reactions; 11-06 October payrolls (consensus about +65k against −29k, unemployment 4.2%); 11-10/11 Russia-Ukraine round in Abu Dhabi; TSM October sales about 11-10; DIS FQ4 on 11-17.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED MODE

- **Population.** US-listed common stocks, market cap ≥$2B, |close-to-close| ≥5% on 11-04 against 11-03 (B's frozen floor; no sub-floor write-ups in this mode).
- **Discovery.** The Nasdaq screener supplied symbols and caps only (its `pctchange` lags). Moves came from per-symbol Nasdaq `quote/info` closes dated "Closed at Nov 4, 2026": **2009** names measured, **666** at ≥5% (`rail_tally`). A broad rally day: the discovery median was +2.3%, so most ≥5% names have no own event.
  - Unmeasured: BRK/A and BRK/B (no data), 382 screener rows with no market cap. BGC, CACC, CCK and CNK had no Nasdaq print and were measured on IBKR instead (all below 5%); CARG likewise (+8.14%, no own-event filing).
- **Confirmation and identity.** Every passed name is confirmed on IBKR regular-session daily bars (`close` array, `outside_rth=false`); release times come only from the scripted EDGAR batch, labels from the key-less earnings calendar. No metered call. IBKR's `search_contracts` 30-per-minute limit forced a second paced pass, which confirmed all remaining own-event names.
  - **Dropped below 5% on IBKR (10):** STVN -4.68%, MGEE +4.95%, PLGO +4.98%, NVO +4.95%, TARS -4.91%, IFF -4.89%, UBER +4.91%, BIRK +4.90%, ASH +4.68%, BCO +4.65%.
- **Close-chain check.** No durable row carries an 11-03 or 11-04 anchor (0 hits). Against the unlanded 11-03 file: **2 hits**, DUOL and NVTS, both after-close 11-03 anchors that chain forward legitimately (yesterday coded them `POST_MOVE_EVENT`, consistent). Not a clearance.

**Passed (93, `surfaced_count = 93`, all anchors resolved):**

|Ticker|Move|IBKR closes 11-03 → 11-04|Event|Release|Anchor|Conv.|Prior ≥5% sessions|
|---|---|---|---|---|---|---|---|
|NRIX|-38.23%|25.82 → 15.95|Sanofi discontinues SAR448272 (oral STAT6 degrader) Phase 1 and terminates the program (8-|after-close|2026-11-03|75|0|
|KD|+30.14%|12.94 → 16.84|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|1|
|DOX|-30.07%|62.43 → 43.66|fiscal Q4 earnings (6-K)|after-close|2026-11-03|75|0|
|ECG|-29.29%|112.73 → 79.71|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|45|2|
|DUOL|+25.99%|128 → 161.27|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|0|
|YOU|+23.70%|47.76 → 59.08|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|0|
|FIS|-23.67%|38.99 → 29.76|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|1|
|HUT|-23.23%|63.75 → 48.94|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|30|4|
|MOD|-21.43%|125.45 → 98.56|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|30|3|
|PCOR|+19.68%|63.17 → 75.6|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|0|
|IOSP|-18.72%|99.23 → 80.65|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|75|0|
|MDLN|+18.36%|34.09 → 40.35|earnings release (8-K Item 2.02)|pre-open|2026-11-04|75|0|
|LIVN|+17.88%|79.9 → 94.19|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|0|
|UNM|-17.84%|91.03 → 74.79|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|0|
|MTRN|-17.66%|227.43 → 187.26|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|2|
|UFPT|+17.66%|280.32 → 329.82|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|0|
|BTU|-17.62%|20.66 → 17.02|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|pre-open|2026-11-04|75|1|
|MOS|+17.37%|18.42 → 21.62|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|1|
|TRMB|-17.31%|65.61 → 54.25|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|0|
|OUST|+15.73%|28.98 → 33.54|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|30|5|
|VRDN|+15.51%|25.15 → 29.05|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|75|1|
|XYZ|+15.30%|76 → 87.63|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|0|
|SM|-15.30%|36.67 → 31.06|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|75|1|
|DDOG|-14.42%|220.52 → 188.72|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|30|4|
|TREX|+14.30%|50 → 57.15|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|0|
|PRIM|-13.98%|79.57 → 68.45|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|after-close|2026-11-03|45|2|
|KMT|-13.92%|30.53 → 26.28|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|1|
|FLYW|+13.89%|19.15 → 21.81|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/7.01)|after-close|2026-11-03|60|0|
|PFGC|+13.53%|96.51 → 109.57|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|0|
|ZBH|+13.49%|97.06 → 110.15|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|0|
|MCY|-13.42%|102.71 → 88.93|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|0|
|HL|+13.17%|13.21 → 14.95|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/8.01)|after-close|2026-11-03|45|2|
|SWK|+13.10%|104.62 → 118.33|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|pre-open|2026-11-04|60|0|
|BRKR|+12.90%|56.5 → 63.79|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|2|
|HURN|-12.70%|198.17 → 173.01|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|1|
|ATHM|+12.68%|19.96 → 22.49|results press release (6-K; calendar lists pre-market 2026-11-04)|pre-open|2026-11-04|60|0|
|CDW|+12.67%|149.77 → 168.75|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|pre-open|2026-11-04|60|1|
|CVS|-12.53%|91.41 → 79.96|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|0|
|CPNG|+11.95%|15.23 → 17.05|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|0|
|ANDE|-11.68%|62.67 → 55.35|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|0|
|MIRM|+11.42%|87.03 → 96.97|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|0|
|SKY|+11.35%|86.37 → 96.17|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|after-close|2026-11-03|60|1|
|W|+11.00%|111.32 → 123.56|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|1|
|JKHY|+10.83%|161.66 → 179.16|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|60|1|
|AVNT|+10.66%|43.25 → 47.86|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|60|0|
|BKNG|+9.83%|155.67 → 170.97|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|CAMT|-9.71%|112.37 → 101.46|Q3 earnings (6-K)|pre-open|2026-11-04|30|3|
|RIOT|+9.63%|14.02 → 15.37|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|30|5|
|CWK|+9.62%|13.62 → 14.93|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|pre-open|2026-11-04|45|1|
|CAR|+9.58%|109.34 → 119.81|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|1|
|SEPN|+9.57%|43.7 → 47.88|SEP-204 development-candidate selection for Graves disease/TED plus preclinical data at AT|pre-open|2026-11-04|45|2|
|MMM|+9.55%|177.05 → 193.95|settlement of the PFAS/AFFF MDL personal-injury claims (8-K Items 1.01/8.01)|after-close|2026-11-03|45|1|
|GXO|+9.48%|52.03 → 56.96|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|ALMR|-9.36%|30.22 → 27.39|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02)|after-close|2026-11-03|30|7|
|KAI|+9.11%|282.79 → 308.56|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|45|1|
|PENG|-9.10%|53.19 → 48.35|agreement to sell its Optimized LED business (Penguin is the seller; 8-K Items 8.01/7.01/5|pre-open|2026-11-04|30|4|
|NVTS|+9.00%|8.56 → 9.33|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|30|4|
|SMG|+8.72%|61.8 → 67.19|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|1|
|SEDG|-8.70%|32.88 → 30.02|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|2|
|OC|+8.53%|117.76 → 127.8|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|0|
|PAYP|+8.50%|14.71 → 15.96|fiscal Q2 results (6-K)|after-close|2026-11-03|45|0|
|ATRC|+8.48%|60.41 → 65.53|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|LTM|+8.37%|44.09 → 47.78|Q3 results (6-K)|after-close|2026-11-03|45|2|
|TKR|-7.81%|115.66 → 106.63|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|1|
|DNLI|+7.76%|19.45 → 20.96|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|PACS|+7.67%|46.68 → 50.26|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|CVE|-7.64%|30.74 → 28.39|Q3 results (6-K)|pre-open|2026-11-04|45|1|
|SSRM|+7.61%|26.16 → 28.15|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|2|
|SNN|+7.59%|30.17 → 32.46|Q3 trading report (6-K)|pre-open|2026-11-04|45|1|
|CRL|-7.27%|351.87 → 326.29|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|30|3|
|MTDR|-7.25%|54.31 → 50.37|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|45|2|
|HRMY|-7.05%|37.02 → 34.41|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|pre-open|2026-11-04|45|1|
|TFPM|+6.69%|28.25 → 30.14|Q3 results (6-K, MD&A and interim financials)|after-close|2026-11-03|45|0|
|WULF|-6.62%|12.53 → 11.7|credit-support agreements for the Anthropic-leased Kentucky data-center campus (8-K Items |pre-open|2026-11-04|30|7|
|PRU|+6.58%|118.81 → 126.63|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|45|0|
|PODD|+6.56%|154.86 → 165.02|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|pre-open|2026-11-04|45|0|
|SOLS|-6.54%|61.74 → 57.7|earnings release (8-K Item 2.02)|pre-open|2026-11-04|45|1|
|GWW|+6.54%|1397.98 → 1489.39|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|0|
|MCD|+6.53%|263.04 → 280.22|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|0|
|SDRL|-6.48%|46.32 → 43.32|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|2|
|EL|+6.31%|105.39 → 112.04|Capital Markets Experience China event announcing fiscal 2030 ambition (8-K Item 7.01)|pre-open|2026-11-04|45|0|
|FRSH|-6.29%|14.15 → 13.26|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|1|
|UWMC|+6.29%|1.59 → 1.69|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|30|3|
|NICE|-6.29%|106.27 → 99.59|Q3 results (6-K; beat guidance ranges)|pre-open|2026-11-04|45|0|
|GFS|-5.95%|42.89 → 40.34|Q3 earnings (6-K; calendar pre-market 2026-11-04)|pre-open|2026-11-04|45|2|
|SMCI|-5.70%|31.39 → 29.6|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|after-close|2026-11-03|30|4|
|OVV|-5.61%|66.43 → 62.7|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01)|after-close|2026-11-03|45|1|
|TOST|+5.49%|33.53 → 35.37|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02)|after-close|2026-11-03|45|1|
|OPLN|-5.45%|38.88 → 36.76|earnings release (8-K Item 2.02, quarter ending Sep/2026)|pre-open|2026-11-04|45|0|
|AVA|+5.41%|38.11 → 40.17|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|after-close|2026-11-03|45|0|
|RRR|-5.31%|51.39 → 48.66|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|45|0|
|VSH|-5.07%|27.22 → 25.84|earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01)|pre-open|2026-11-04|30|3|
|ANET|+5.04%|169.91 → 178.48|earnings release (8-K Item 2.02, quarter ending Sep/2026)|after-close|2026-11-03|30|3|

- **Noisy names** (≥3 other ≥5% sessions in the 10-day window, criteria 2 and 4 context): HUT (4), MOD (3), OUST (5), DDOG (4), CAMT (3), RIOT (5), ALMR (7), PENG (4), NVTS (4), CRL (3), WULF (7), UWMC (3), SMCI (4), VSH (3), ANET (3).
- **Event notes:** NRIX fell on Sanofi ending a partnered Phase 1 program (Item 8.01); MMM's 8-K carries a PFAS settlement (1.01/8.01); PENG is the seller in a business-unit sale; EL's event is an investor day (7.01); SEPN's is a preclinical candidate selection (7.01); WULF's 1.01 is a financing (low confidence).
- **Rejected:** `rejected_notable` is empty. `rejected_compact` (574), closes on the discovery basis unless the legend says IBKR: 275 `ANCHOR_UNRESOLVED` (no own-event filing, or one that does not explain the move, or an unreadable exhibit: SII, LKFT, LEGN), 257 `DAY2_EVENT_PRIOR`, 42 `POST_MOVE_EVENT`.
- **Deal-pinned:** none. Filing text was read for every passed name with Items 1.01/7.01/8.01 or a 6-K without 2.02.
- **Metered calls:** none.
- **Durable row: NOT WRITTEN this run.** The generated, digest-checked split write (6 parts + call) is committed at `ops/spikes/d1-2026-11-04-single-name-screen-unlanded/`; its issuing sub-agent staged part 1 and was then stopped by a provider safety filter. In-run issue `research_screen_write_refused` asks for an interactive landing. agreement = {both 93, ai_only 0, rule_only 574}.

### 4. Sector-level moves (IBKR regular-session closes 11-03 → 11-04)

- **Surfaced (8 of 11; rail tally 9 at |move| ≥ 1%).**
  - **XLE −4.74%** (66.68 → 63.52, conviction 75). The oil collapse: Brent (BZUSD, provisional same-evening read) 94.60 on 11-04 against 103.60 on 11-03, USO −8.07%.
  - **XLY +4.26%** (117.33 → 122.33, conviction 60). Best sector in a broad relief rally, with lower oil easing consumer costs.
  - **XLF +3.51%, XLC +3.47%, XLP +3.36%, XLRE +3.32%, XLV +3.06%** (conviction 45 each). One broad beta move in which defensives and cyclicals rose together, after the midterm result and a 4-point VIX drop; healthcare policy read-through is plausible but unverified.
  - **XLK −0.01%** (176.51 → 176.50, conviction 45, dispersion-only): flat against SPX +1.58% while SMH fell 2.75%, the chip reversal on data-center regulation fears.
- **Rejected notable:** XLB +2.49% (moved with the cyclical tape, no metals driver found) and XLI −1.09% (no catalyst found), conviction 30 each.
- **Not surfaced:** XLU +0.44%.
- **Id check.** All 11 prior closes equal the 11-03 closes recorded yesterday, so no contract ids were re-resolved.
- **Caveat.** Drivers other than XLE are inferred from the cross-asset tape; no sector-by-sector wrap was read (searches thin and partly rate-limited).
- **Durable row:** `research-screen` `sector-move`, entry `a4e2f628-7fc8-4d87-abaa-739b8cecdaa3`.

### 5. Notable commentary

- Jay Woods (Freedom Capital Markets, via Variety): gridlock has historically been good for markets.
- Brian Sozzi (Yahoo Finance): the rally reads as relief on hyperscaler capex and free cash flow.
- CNBC analysts: Democratic control could weigh on AI-buildout names through data-center restrictions, which matches the GEV, SMH and Texas-moratorium read.
- No sell-side or central-bank note text was retrieved (the commentary searches returned little or hit 429).

---

## ANALYSIS — RISK TO EXISTING POSITIONS

**Mechanical exit-trigger sweep.**
- **Union of book and view.** IBKR `get_account_positions` and `state.current_positions` agree on all 8 names and share counts (AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156). VOO (16.895 sh) is the park holding. No connector-only position, so no `position_reconciliation_lag`.
- **Exit triggers.** No tranche carries a `convergence_target` or `time_exit_date`. **No EXIT TRIGGERED.**

**Per-strategy kill-trigger sweep.**
- **Strategy D.** `perf.kill_flags` (as of 11-02): every flag FALSE; unit 1.0180 against peak 1.1065 (−7.99%). Refreshed against IBKR 11-04 closes, the book's market value moved about +3.3% since 11-02 (the 11-03 rebound plus 11-04's mixed session), which leaves the drawdown at roughly −5%, far from the −50% kill. `interim_underperf_warning` is FALSE (deployed 132 days, excess vs SGOV −0.13%), and no alert of that category is open.
- **Strategy B.** No open positions; `analytics.b_pairwise_correlation` reports 0 positions, so the correlation check is inert.

**Thesis-invalidation check** (criteria read from `state.current_positions.invalidation_status`; closes IBKR 11-04, moves against 11-03).
- **AMZN** 266.03 (+6.12%). A hyperscaler rebound; no company news; criteria are quarterly AWS and commitment metrics. **NO.**
- **DIS** 118.95 (+4.18%, a 52-week high intraday). Only the known cost plan; FQ4 is 11-17 and has **not occurred** (EVENT-IDENTITY GATE). **NO.**
- **GEV** 832.83 (**−9.30%**). Profit-taking after Tuesday's +6.5%, data-center backlash fears on the sweep, and analyst target trims (Argus, Guggenheim and others; Barron's, Investing.com). The criterion is organic orders growth below 15% for two quarters; the latest reading is +96%, and price action is listed as not exit-triggering. **NO.**
- **GOOGL** 288.93 (+3.18%). Rebound; no structural-remedy ruling in the window. **NO.**
- **ISRG** 482.10 (+9.38%). A healthcare-sector bounce with no company catalyst found. **NO.**
- **RTX** 198.43 (−2.64%). Defense names fell on budget fears after the sweep. c6 needs an enacted or proposed FY27 procurement cut of 10% or more; none exists (a CR funds FY26 levels through 12-11). **NO.**
- **TSM** 395.75 (−2.24%). No company news; October sales are due about 11-10. **NO.**
- **UBER** 69.87 (+4.91%). Q3 2026 verified from the issuer 8-K (accepted 11:55Z, quarter ended 2026-09-30): c1 gross bookings +20% cc passes; c2 adjusted EBITDA margin expanded to 5.0% of GB; c3 Uber One about 55M (from the call; the prior count was not re-read, so "no sequential decline" rests on management's record-high language); c4 no definition change seen in the release. The President's departure (Item 5.02) is not a criterion. **NO.**

Price-level criteria: `state.price_level_criterion_drift` holds 4 rows (DIS, RTX ×2, TSM), all parsed non-price figures with `actionable_price_level = FALSE`; no verdict here tests a price level, so no dividend netting applies.

Caveat: only UBER was checked against a primary filing; the other seven rest on one secondary-press search each, so absence of news is weak evidence.

Watchlist candidates: no existing B-index name's candidacy changes beyond the adds below.

## ANALYSIS — OPPORTUNITY CHECK

- **A, D and E are GATED** under the ROUTER-GATED SCAN RULE, so nothing was evaluated for them.
- **B is GATED.** Its 93 ≥5% own-event names still reach the new-entry index as `watchlist` actions (item 3); no deal-pinned target, and no thesis handoff is routed. None of the 93 is a held name (UBER fell just below the floor at +4.91%).
- **C, HYBRID (FOMC-only carve-out).** No new FOMC-class candidate; the December 8–9 FOMC is already inside the 45-day window.

## ANALYSIS — ADD-CANDIDATE CHECK

- **Durable row:** `add-candidate-review`, entry `e97e5eb3-7825-4f4f-8ef4-b20b67e5387f`. 12 evaluated, **0 flagged, 0 `declined_hard_gate`**, 12 `declined`.
- **Gate.** `invalidation_status` is readable and populated for all 12 (no NULL, no `NOT_DISCRETELY_RECORDED_AT_ENTRY`, no `NOT_ASSESSED_BY_THIS_BACKFILL`), and the sweep above found no criterion breached, so the hard gate clears and `invalidation_criteria_evaluable = TRUE` on all 12.

| Tranche | Close 11-04 | Tranche cost | Mark vs cost | Trigger | Disposition |
|---|---|---|---|---|---|
| D:AMZN:2026-07-09 | 266.03 | 241.2441 | +10.27% | none | declined |
| D:AMZN:2026-07-30 | 266.03 | 265.6930 | +0.13% | none | declined |
| D:DIS:2026-05-07 | 118.95 | 111.3190 | +6.86% | none | declined |
| D:DIS:2026-08-05 | 118.95 | 103.7854 | +14.61% | none | declined |
| D:GEV:2026-08-03 | 832.83 | 969.9058 | −14.13% | dip-with-intact-thesis | declined |
| D:GOOGL:2026-07-09 | 288.93 | 359.8484 | −19.71% | dip-with-intact-thesis | declined |
| D:GOOGL:2026-07-26 | 288.93 | 327.8435 | −11.87% | dip-with-intact-thesis | declined |
| D:ISRG:2026-07-20 | 482.10 | 349.5106 | +37.94% | none | declined |
| D:RTX:2026-04-27 | 198.43 | 176.8988 | +12.17% | none | declined |
| D:TSM:2026-07-21 | 395.75 | 427.8613 | −7.51% | dip-with-intact-thesis | declined |
| D:TSM:2026-07-29 | 395.75 | 392.8830 | +0.73% | dip-with-intact-thesis | declined |
| D:UBER:2026-07-09 | 69.87 | 73.2073 | −4.56% | strengthened-conviction | declined |

- **Price basis.** IBKR 11-04 regular-session closes over each tranche's own `cost_basis / shares`.
- **Dip rule.** The 11-04 close at least 5% below the 10-28 close with no invalidation news: GEV −5.15% (only after today's −9.30%), GOOGL −11.07%, TSM −9.96%. UBER's print reinforces c1–c3 (strengthened conviction).
- **Why none is flagged.** D is DO-NOT-ACTIVATE and capital-disabled, so no add has a funding path, the same disposition as 11-02.

## ANALYSIS — REGIME CHECK

**No router review.** The standing regime is `shock_overlay = acute` (Gulf/Hormuz), as of 2026-11-02.

**Qualifying shock event: no flag needed.** No new dated kinetic event was confirmed in the window, and the overlay already reads `acute`.

**Qualifying resolution event: NO.**
- No ceasefire, settlement or blockade lift is in force: Iran's envoy and Rezaei restated that the strait reopens only once the US blockade is lifted and Iran's conditions are met; Qatar is still reviewing proposals.
- Oil's two-session drop (BZUSD 104.77 → 103.60 → 94.60 on the revised series, about −9.7% over 11-02 → 11-04) is priced on deal hopes and the election, not on a resolution of the channel. That is narrative de-escalation with no event behind it, so it does not qualify. If a settlement is signed, the next D1 flags it with this window's moves stated.

**Measured triggers, for D2 to detect (not computed here).** VIX fell 4.22 points in one session to 16.61, and Brent's drop may move the shock price leg; D2 item 4 reads D2a's step-1d/1e rows. This run's breadth row (66.13, up about 4.5pp) is the input to the two breadth triggers.

## EQUITY-BREADTH OBSERVATION

**Row written:** `events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **66.13** for as_of_date **2026-11-04**.
- **Source.** Barchart `$S5TH`, via `tavily_extract` (advanced, `?cb=20261104`), fetched about 22:07Z. The page reads "Quote Overview for Wed, Nov 4th, 2026", stamped 16:46 ET (settled). O 64.14, H 66.33, L 63.34; not an exact repeat.
- **Prior-session revision.** Barchart's Previous Close is now **61.55**, against the 61.63 D1 recorded for 11-03 (a 0.08pp settlement revision, expected noise). The true change is +4.58 off 61.55. Note that the 11-03 row itself is still not in BigQuery (see the out-of-scope note at the end).
- **Corroboration.** EODData read 65.53 with a 15:51 quote stamp (pre-close, `unsettled_at_fetch=15:51 ET`) and shares Barchart's feed, so this is a **single settled source**. MacroMicro was not probed (Wednesday; the probe rides on Sunday).
- **ChartRow lags one session.** Its 200-day tile is dated Nov 3: 304 of 496 (61%), read twice including a final re-read. Recorded `chartrow_unconfirmed=lag session 2026-11-03` and `chartrow_lagged_dod_gap=0.03 for 2026-11-03` (ChartRow −1.81pp against `$S5TH` −1.78pp for 11-02 → 11-03). A plain one-session lag on a non-repeat row, so not an in-run issue.

## RECOMMENDED ACTIONS

- Watchlist: ADD NRIX to the Strategy B new-entry index — Sanofi discontinues SAR448272 (oral STAT6 degrader) Phase 1 and terminates the program (8-K Item 8.01), after-close release; reaction session 11-04, -38.23% (25.82 → 15.95); qualifying_event_date 2026-11-03.
- Watchlist: ADD KD to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +30.14% (12.94 → 16.84), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD DOX to the Strategy B new-entry index — fiscal Q4 earnings (6-K), after-close release; reaction session 11-04, -30.07% (62.43 → 43.66); qualifying_event_date 2026-11-03.
- Watchlist: ADD ECG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, -29.29% (112.73 → 79.71), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD DUOL to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +25.99% (128 → 161.27); qualifying_event_date 2026-11-03.
- Watchlist: ADD YOU to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +23.70% (47.76 → 59.08); qualifying_event_date 2026-11-04.
- Watchlist: ADD FIS to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -23.67% (38.99 → 29.76), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD HUT to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -23.23% (63.75 → 48.94), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD MOD to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -21.43% (125.45 → 98.56), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD PCOR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +19.68% (63.17 → 75.6); qualifying_event_date 2026-11-03.
- Watchlist: ADD IOSP to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, -18.72% (99.23 → 80.65); qualifying_event_date 2026-11-03.
- Watchlist: ADD MDLN to the Strategy B new-entry index — earnings release (8-K Item 2.02), pre-open release; reaction session 11-04, +18.36% (34.09 → 40.35); qualifying_event_date 2026-11-04.
- Watchlist: ADD LIVN to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +17.88% (79.9 → 94.19); qualifying_event_date 2026-11-04.
- Watchlist: ADD UNM to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -17.84% (91.03 → 74.79); qualifying_event_date 2026-11-03.
- Watchlist: ADD MTRN to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -17.66% (227.43 → 187.26), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD UFPT to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +17.66% (280.32 → 329.82); qualifying_event_date 2026-11-03.
- Watchlist: ADD BTU to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), pre-open release; reaction session 11-04, -17.62% (20.66 → 17.02), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD MOS to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +17.37% (18.42 → 21.62), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD TRMB to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -17.31% (65.61 → 54.25); qualifying_event_date 2026-11-04.
- Watchlist: ADD OUST to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +15.73% (28.98 → 33.54), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD VRDN to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +15.51% (25.15 → 29.05), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD XYZ to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +15.30% (76 → 87.63); qualifying_event_date 2026-11-03.
- Watchlist: ADD SM to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -15.30% (36.67 → 31.06), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD DDOG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -14.42% (220.52 → 188.72), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD TREX to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +14.30% (50 → 57.15); qualifying_event_date 2026-11-04.
- Watchlist: ADD PRIM to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), after-close release; reaction session 11-04, -13.98% (79.57 → 68.45), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD KMT to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -13.92% (30.53 → 26.28), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD FLYW to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/7.01), after-close release; reaction session 11-04, +13.89% (19.15 → 21.81); qualifying_event_date 2026-11-03.
- Watchlist: ADD PFGC to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +13.53% (96.51 → 109.57); qualifying_event_date 2026-11-04.
- Watchlist: ADD ZBH to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +13.49% (97.06 → 110.15); qualifying_event_date 2026-11-04.
- Watchlist: ADD MCY to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -13.42% (102.71 → 88.93); qualifying_event_date 2026-11-03.
- Watchlist: ADD HL to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/8.01), after-close release; reaction session 11-04, +13.17% (13.21 → 14.95), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD SWK to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), pre-open release; reaction session 11-04, +13.10% (104.62 → 118.33); qualifying_event_date 2026-11-04.
- Watchlist: ADD BRKR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +12.90% (56.5 → 63.79), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD HURN to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -12.70% (198.17 → 173.01), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD ATHM to the Strategy B new-entry index — results press release (6-K; calendar lists pre-market 2026-11-04), pre-open release; reaction session 11-04, +12.68% (19.96 → 22.49); qualifying_event_date 2026-11-04.
- Watchlist: ADD CDW to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), pre-open release; reaction session 11-04, +12.67% (149.77 → 168.75), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD CVS to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -12.53% (91.41 → 79.96); qualifying_event_date 2026-11-04.
- Watchlist: ADD CPNG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +11.95% (15.23 → 17.05); qualifying_event_date 2026-11-03.
- Watchlist: ADD ANDE to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -11.68% (62.67 → 55.35); qualifying_event_date 2026-11-03.
- Watchlist: ADD MIRM to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +11.42% (87.03 → 96.97); qualifying_event_date 2026-11-03.
- Watchlist: ADD SKY to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), after-close release; reaction session 11-04, +11.35% (86.37 → 96.17), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD W to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +11.00% (111.32 → 123.56), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD JKHY to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +10.83% (161.66 → 179.16), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD AVNT to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +10.66% (43.25 → 47.86); qualifying_event_date 2026-11-04.
- Watchlist: ADD BKNG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +9.83% (155.67 → 170.97); qualifying_event_date 2026-11-03.
- Watchlist: ADD CAMT to the Strategy B new-entry index — Q3 earnings (6-K), pre-open release; reaction session 11-04, -9.71% (112.37 → 101.46), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD RIOT to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +9.63% (14.02 → 15.37), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD CWK to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), pre-open release; reaction session 11-04, +9.62% (13.62 → 14.93), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD CAR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +9.58% (109.34 → 119.81), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD SEPN to the Strategy B new-entry index — SEP-204 development-candidate selection for Graves disease/TED plus preclinical data at ATA (8-K Item 7.01 press release), pre-open release; reaction session 11-04, +9.57% (43.7 → 47.88), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD MMM to the Strategy B new-entry index — settlement of the PFAS/AFFF MDL personal-injury claims (8-K Items 1.01/8.01), after-close release; reaction session 11-04, +9.55% (177.05 → 193.95), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD GXO to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +9.48% (52.03 → 56.96); qualifying_event_date 2026-11-03.
- Watchlist: ADD ALMR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02), after-close release; reaction session 11-04, -9.36% (30.22 → 27.39), with 7 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD KAI to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, +9.11% (282.79 → 308.56), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD PENG to the Strategy B new-entry index — agreement to sell its Optimized LED business (Penguin is the seller; 8-K Items 8.01/7.01/5.02, outlook reaffirmed), pre-open release; reaction session 11-04, -9.10% (53.19 → 48.35), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD NVTS to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, +9.00% (8.56 → 9.33), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD SMG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +8.72% (61.8 → 67.19), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD SEDG to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -8.70% (32.88 → 30.02), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD OC to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +8.53% (117.76 → 127.8); qualifying_event_date 2026-11-04.
- Watchlist: ADD PAYP to the Strategy B new-entry index — fiscal Q2 results (6-K), after-close release; reaction session 11-04, +8.50% (14.71 → 15.96); qualifying_event_date 2026-11-03.
- Watchlist: ADD ATRC to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +8.48% (60.41 → 65.53); qualifying_event_date 2026-11-03.
- Watchlist: ADD LTM to the Strategy B new-entry index — Q3 results (6-K), after-close release; reaction session 11-04, +8.37% (44.09 → 47.78), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD TKR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -7.81% (115.66 → 106.63), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD DNLI to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +7.76% (19.45 → 20.96); qualifying_event_date 2026-11-03.
- Watchlist: ADD PACS to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +7.67% (46.68 → 50.26); qualifying_event_date 2026-11-03.
- Watchlist: ADD CVE to the Strategy B new-entry index — Q3 results (6-K), pre-open release; reaction session 11-04, -7.64% (30.74 → 28.39), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD SSRM to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +7.61% (26.16 → 28.15), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD SNN to the Strategy B new-entry index — Q3 trading report (6-K), pre-open release; reaction session 11-04, +7.59% (30.17 → 32.46), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD CRL to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -7.27% (351.87 → 326.29), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD MTDR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, -7.25% (54.31 → 50.37), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD HRMY to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), pre-open release; reaction session 11-04, -7.05% (37.02 → 34.41), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD TFPM to the Strategy B new-entry index — Q3 results (6-K, MD&A and interim financials), after-close release; reaction session 11-04, +6.69% (28.25 → 30.14); qualifying_event_date 2026-11-03.
- Watchlist: ADD WULF to the Strategy B new-entry index — credit-support agreements for the Anthropic-leased Kentucky data-center campus (8-K Items 1.01/7.01/8.01), pre-open release; reaction session 11-04, -6.62% (12.53 → 11.7), with 7 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD PRU to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, +6.58% (118.81 → 126.63); qualifying_event_date 2026-11-03.
- Watchlist: ADD PODD to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), pre-open release; reaction session 11-04, +6.56% (154.86 → 165.02); qualifying_event_date 2026-11-04.
- Watchlist: ADD SOLS to the Strategy B new-entry index — earnings release (8-K Item 2.02), pre-open release; reaction session 11-04, -6.54% (61.74 → 57.7), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD GWW to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +6.54% (1397.98 → 1489.39); qualifying_event_date 2026-11-04.
- Watchlist: ADD MCD to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +6.53% (263.04 → 280.22); qualifying_event_date 2026-11-04.
- Watchlist: ADD SDRL to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -6.48% (46.32 → 43.32), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD EL to the Strategy B new-entry index — Capital Markets Experience China event announcing fiscal 2030 ambition (8-K Item 7.01), pre-open release; reaction session 11-04, +6.31% (105.39 → 112.04); qualifying_event_date 2026-11-04.
- Watchlist: ADD FRSH to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -6.29% (14.15 → 13.26), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD UWMC to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, +6.29% (1.59 → 1.69), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD NICE to the Strategy B new-entry index — Q3 results (6-K; beat guidance ranges), pre-open release; reaction session 11-04, -6.29% (106.27 → 99.59); qualifying_event_date 2026-11-04.
- Watchlist: ADD GFS to the Strategy B new-entry index — Q3 earnings (6-K; calendar pre-market 2026-11-04), pre-open release; reaction session 11-04, -5.95% (42.89 → 40.34), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD SMCI to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), after-close release; reaction session 11-04, -5.70% (31.39 → 29.6), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD OVV to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01), after-close release; reaction session 11-04, -5.61% (66.43 → 62.7), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD TOST to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02), after-close release; reaction session 11-04, +5.49% (33.53 → 35.37), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-03.
- Watchlist: ADD OPLN to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), pre-open release; reaction session 11-04, -5.45% (38.88 → 36.76); qualifying_event_date 2026-11-04.
- Watchlist: ADD AVA to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), after-close release; reaction session 11-04, +5.41% (38.11 → 40.17); qualifying_event_date 2026-11-03.
- Watchlist: ADD RRR to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, -5.31% (51.39 → 48.66); qualifying_event_date 2026-11-03.
- Watchlist: ADD VSH to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01), pre-open release; reaction session 11-04, -5.07% (27.22 → 25.84), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-04.
- Watchlist: ADD ANET to the Strategy B new-entry index — earnings release (8-K Item 2.02, quarter ending Sep/2026), after-close release; reaction session 11-04, +5.04% (169.91 → 178.48), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-03.

```yaml d1_actions
- action: watchlist
  ticker: NRIX
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Sanofi discontinues SAR448272 (oral STAT6 degrader) Phase 1 and terminates the p after-close, -38.23% (25.82 -> 15.95), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: KD
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +30.14% (12.94 -> 16.84), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DOX
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; fiscal Q4 earnings (6-K) after-close, -30.07% (62.43 -> 43.66), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ECG
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, -29.29% (112.73 -> 79.71), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DUOL
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +25.99% (128 -> 161.27), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: YOU
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +23.70% (47.76 -> 59.08), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: FIS
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -23.67% (38.99 -> 29.76), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: HUT
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -23.23% (63.75 -> 48.94), 4 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MOD
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -21.43% (125.45 -> 98.56), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PCOR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +19.68% (63.17 -> 75.6), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: IOSP
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, -18.72% (99.23 -> 80.65), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MDLN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02) pre-open, +18.36% (34.09 -> 40.35), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: LIVN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +17.88% (79.9 -> 94.19), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: UNM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -17.84% (91.03 -> 74.79), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MTRN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -17.66% (227.43 -> 187.26), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: UFPT
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +17.66% (280.32 -> 329.82), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: BTU
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) pre-open, -17.62% (20.66 -> 17.02), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MOS
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +17.37% (18.42 -> 21.62), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TRMB
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -17.31% (65.61 -> 54.25), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: OUST
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +15.73% (28.98 -> 33.54), 5 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: VRDN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +15.51% (25.15 -> 29.05), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: XYZ
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +15.30% (76 -> 87.63), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -15.30% (36.67 -> 31.06), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DDOG
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -14.42% (220.52 -> 188.72), 4 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TREX
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +14.30% (50 -> 57.15), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PRIM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) after-close, -13.98% (79.57 -> 68.45), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: KMT
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -13.92% (30.53 -> 26.28), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: FLYW
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/7.01) after-close, +13.89% (19.15 -> 21.81), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PFGC
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +13.53% (96.51 -> 109.57), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ZBH
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +13.49% (97.06 -> 110.15), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MCY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -13.42% (102.71 -> 88.93), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: HL
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02/8.01) after-close, +13.17% (13.21 -> 14.95), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SWK
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) pre-open, +13.10% (104.62 -> 118.33), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: BRKR
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +12.90% (56.5 -> 63.79), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: HURN
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -12.70% (198.17 -> 173.01), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ATHM
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; results press release (6-K; calendar lists pre-market 2026-11-04) pre-open, +12.68% (19.96 -> 22.49), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CDW
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) pre-open, +12.67% (149.77 -> 168.75), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CVS
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -12.53% (91.41 -> 79.96), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CPNG
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +11.95% (15.23 -> 17.05), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ANDE
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -11.68% (62.67 -> 55.35), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MIRM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +11.42% (87.03 -> 96.97), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SKY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) after-close, +11.35% (86.37 -> 96.17), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: W
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +11.00% (111.32 -> 123.56), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: JKHY
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +10.83% (161.66 -> 179.16), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: AVNT
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +10.66% (43.25 -> 47.86), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: BKNG
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +9.83% (155.67 -> 170.97), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CAMT
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 earnings (6-K) pre-open, -9.71% (112.37 -> 101.46), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: RIOT
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +9.63% (14.02 -> 15.37), 5 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CWK
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) pre-open, +9.62% (13.62 -> 14.93), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CAR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +9.58% (109.34 -> 119.81), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SEPN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; SEP-204 development-candidate selection for Graves disease/TED plus preclinical  pre-open, +9.57% (43.7 -> 47.88), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MMM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; settlement of the PFAS/AFFF MDL personal-injury claims (8-K Items 1.01/8.01) after-close, +9.55% (177.05 -> 193.95), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: GXO
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +9.48% (52.03 -> 56.96), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ALMR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02) after-close, -9.36% (30.22 -> 27.39), 7 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: KAI
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, +9.11% (282.79 -> 308.56), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PENG
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; agreement to sell its Optimized LED business (Penguin is the seller; 8-K Items 8 pre-open, -9.10% (53.19 -> 48.35), 4 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: NVTS
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, +9.00% (8.56 -> 9.33), 4 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SMG
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +8.72% (61.8 -> 67.19), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SEDG
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -8.70% (32.88 -> 30.02), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: OC
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +8.53% (117.76 -> 127.8), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PAYP
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; fiscal Q2 results (6-K) after-close, +8.50% (14.71 -> 15.96), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ATRC
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +8.48% (60.41 -> 65.53), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: LTM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 results (6-K) after-close, +8.37% (44.09 -> 47.78), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TKR
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -7.81% (115.66 -> 106.63), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: DNLI
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +7.76% (19.45 -> 20.96), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PACS
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +7.67% (46.68 -> 50.26), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CVE
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 results (6-K) pre-open, -7.64% (30.74 -> 28.39), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SSRM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +7.61% (26.16 -> 28.15), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SNN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 trading report (6-K) pre-open, +7.59% (30.17 -> 32.46), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: CRL
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -7.27% (351.87 -> 326.29), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MTDR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, -7.25% (54.31 -> 50.37), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: HRMY
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) pre-open, -7.05% (37.02 -> 34.41), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TFPM
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 results (6-K, MD&A and interim financials) after-close, +6.69% (28.25 -> 30.14), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: WULF
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; credit-support agreements for the Anthropic-leased Kentucky data-center campus ( pre-open, -6.62% (12.53 -> 11.7), 7 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PRU
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, +6.58% (118.81 -> 126.63), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: PODD
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) pre-open, +6.56% (154.86 -> 165.02), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SOLS
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02) pre-open, -6.54% (61.74 -> 57.7), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: GWW
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +6.54% (1397.98 -> 1489.39), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: MCD
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +6.53% (263.04 -> 280.22), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SDRL
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -6.48% (46.32 -> 43.32), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: EL
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Capital Markets Experience China event announcing fiscal 2030 ambition (8-K Item pre-open, +6.31% (105.39 -> 112.04), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: FRSH
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -6.29% (14.15 -> 13.26), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: UWMC
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, +6.29% (1.59 -> 1.69), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: NICE
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 results (6-K; beat guidance ranges) pre-open, -6.29% (106.27 -> 99.59), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: GFS
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; Q3 earnings (6-K; calendar pre-market 2026-11-04) pre-open, -5.95% (42.89 -> 40.34), 2 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: SMCI
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) after-close, -5.70% (31.39 -> 29.6), 4 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: OVV
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.01) after-close, -5.61% (66.43 -> 62.7), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: TOST
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 5.02) after-close, +5.49% (33.53 -> 35.37), 1 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: OPLN
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) pre-open, -5.45% (38.88 -> 36.76), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: AVA
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) after-close, +5.41% (38.11 -> 40.17), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: RRR
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, -5.31% (51.39 -> 48.66), 0 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: VSH
  strategy: B
  qualifying_event_date: 2026-11-04
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01) pre-open, -5.07% (27.22 -> 25.84), 3 prior >=5% sessions; B GATED, index only
- action: watchlist
  ticker: ANET
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)
  detail: ADD to B new-entry index; earnings release (8-K Item 2.02, quarter ending Sep/2026) after-close, +5.04% (169.91 -> 178.48), 3 prior >=5% sessions; B GATED, index only
```

---

**Out-of-scope note (2026-11-03 deferred writes).** The degraded 2026-11-03 run's BigQuery rows (two `research-screen` rows, the `add-candidate-review`, the 61.63 breadth row and 120 paper-book calls) are still unlanded; the ledger is `ops/spikes/bigquery-deauth-2026-11-03-d1-deferred-writes.md`. This run's attempt to land them stopped before writing anything, and the item is tracked on the open `ops.alerts` row `639c1422` (owner: OPS2 catch-up), with evidence added to `events.decision_log` this run.

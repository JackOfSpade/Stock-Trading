2026-11-15
<!-- d1_scan_through_utc: 2026-11-15T22:00:00Z -->

# Daily Market Development Scan — sessions 2026-11-10..11-13 (Tue-Fri), run 2026-11-15 (Sun)

Scan window: 2026-11-09 15:41 MT → 2026-11-15 15:00 MT (~5 days 23 hours; multi-session gap). The start is the prior `Daily.md` marker `2026-11-09T22:41:02Z`. D1 did not run on 11-10, 11-11 or 11-12: `state.fleet_blackout_days` lists all three as fleet blackout days (all eight expected daily routines silent), and D2a has not run since 11-09. This run covers four sessions (11-10, 11-11, 11-12, 11-13) plus the weekend.

SCAN MODE: ROUTER-GATED (A DO-NOT-ACTIVATE; D DO-NOT-ACTIVATE; E DO-NOT-ACTIVATE — PENDING div-E-202611-2), read live from `state.current_regime`. B reads ACTIVATE (as of 2026-11-09), so the single-name screen runs in FULL mode, with the first-full-run re-check of gated names. C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-09 → 11-13).** SPY 752.69 → 754.37 (+0.22% over the four sessions: −0.37%, +1.32%, −0.35%, −0.36%); QQQ +0.08%; SMH −0.14% (+4.82% on 11-11, −2.99% on 11-13).
- **Volatility.** VIX 19.92 → 19.46, 17.49, 18.70, **19.30** (IBKR CBOE index bars, delayed=900s). Out of HIGH all week.
- **Rates and dollar.** Hot October CPI (11-10). The 10-year yield rose from 4.88% to **5.15%**; DXY at its highest since April 2025. A December Fed hike is about 87% priced (FedWatch, 11-11).
- **Oil.** Brent (BZUSD, provisional same-evening read) **95.84 on 2026-11-13**, against 95.82 on 2026-11-12 and 92.57 on 2026-11-09 in the same FMP series.
- **Breadth.** **63.81** for 11-13 (Barchart `$S5TH`, single settled source; ChartRow 63.78% as of Nov 13), against 63.14 stored for 11-09.
- **Crypto.** Bitcoin about $68.3K on 11-13 and about $64.3K on 11-14, below its 200-week average.

## TL;DR

- **Exits triggered: none.** No tranche carries a mechanical trigger, and no development meets an invalidation criterion. Disney reports 11-17.
- **New entry candidates: none routed as thesis handoffs.** 20 names passed the FULL-mode Strategy B screen on IBKR bars and go to the B new-entry index (W2 ranks them): CRWV, CTVA, AAON, HIMS, NOVT, QLYS, YETI, LFTO, NU, TTWO, ONON, SKYD, GFL, HWC, NBIS, DGII, CSCO, MOD, RKLB, STVN. Discovery was DEGRADED (key-less fetches refused this run), so the population is not fully measured.
- **Add candidates: none (0 of 12).** All 12 D tranches clear the hard gate; dip reads (GEV, GOOGL ×2) and strengthened-conviction reads (TSM ×2) are declined because D is DO-NOT-ACTIVATE.
- **Watchlist: 20 changes.** ADD the 20 names to the Strategy B new-entry index.
- **Regime review: one PENDING flag.** The 2026-11-14 Iranian claim of three tankers mined in Hormuz is a dated Gulf-channel event; its two-session oil window (11-16, 11-17) has not closed. No resolution event.

Park: VOO-only pin verified

Paper book (J): not run (marks and headline fetches refused this run), 0 calls, 361/30 realized, net_mu -0.85%, ready=FALSE, unwritten: all calls / all marks tickers

## DEVELOPMENTS

### 1. Market-wide breaking events

**Nvidia CEO transition (Thu 11-12).** Nvidia's board replaced Jensen Huang as CEO with immediate effect; CFO Colette Kress is interim CEO and Harvey Jones becomes board chair (Nvidia release, nvidianews.nvidia.com "NVIDIA Announces CEO Transition"). Bloomberg reports that the ouster followed reports of affairs, including one with a woman suspected of spying for China. NVDA fell about 14% on the week (IBKR closes: −5.47% 11-10, +2.87% 11-11, −4.34% 11-12, −2.01% 11-13), its worst week since April 2025. Nvidia's Q3 FY27 report stays on Tue 11-17. Bloomberg also reports a bipartisan push for tougher AI-chip curbs on China.

**Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's restriction of Hormuz).** No ceasefire, settlement or blockade lift is in force.
- The US naval blockade of Iranian ports stays in force; Hormuz transits run about 65% below pre-war (UKMTO via UN News). The June 60-day ceasefire lapsed in August.
- 11-09: the Qatari PM met Trump and Vance (FT). Talk only.
- 11-10: Rubio said there is "no need for major combat operations any longer" (NYT, Axios). Iran's security-council secretary said no negotiations are underway (Reuters).
- 11-12: Trump posted "We don't need a deal with Iran... we've got their Strait!" and told Vance to drop the push (AP, Bloomberg). Iran's military claimed four tankers were hit by explosions in Hormuz (Reuters could not verify). The Houthis claimed strikes on Saudi pipeline, Yanbu and Riyadh oil targets; Saudi air defences report intercepts through 11-15 (Reuters).
- 11-13: the UN Security Council met on Hormuz at Bahrain's request. The IEA says October supply exceeded demand by about 2 mb/d and Gulf shipments run 26% below pre-war. Axios: the Mossad chief is in Washington pressing for strikes, and Trump has so far declined.
- 11-14 (Sat): Iran's navy said three tankers hit mines in Hormuz and one is on fire (state media via Reuters). Not independently confirmed.
- 11-15 (Sun): the IRGC says it launched six drones at a US radar at Al-Rifaa base in Bahrain. Bahrain says it intercepted several attacks; no US or Bahraini confirmation of damage (Reuters via JPost, Guardian live). Reuters: Trump may hold off on strikes absent new provocations; a third carrier is moving to the region.

**Oil.** Brent (BZUSD, provisional same-evening read; FMP series, D2a has not landed 11-10..11-13): 92.57 (11-09), 91.49 (11-10), 92.76 (11-11), **95.82 (11-12, +3.3%)**, **95.84 (11-13)**. The curated series carries 92.29 for 11-09 (vendor revision). Brent fell about 2.5% on the week, its second weekly decline (EnergyNow).

**Rates and dollar.** The 10-year Treasury yield rose from 4.88% (11-09) to **5.15%** (11-13), its highest since 10-19; the 2-year reached 4.88% (FactIQ, Fed H.15). DXY made its highest level since April 2025 (about 103.2 on 11-12); USD/JPY is near 160.

**Crypto.** Bitcoin fell from about $75.3K (11-09) to about $68.3K (11-13) and about $64.3K on Saturday 11-14, below its 200-week average (economies.com, CoinGlass).

**Other.** SoftBank booked a $3.7B charge on US data-center power equipment (11-10). MSCI will delete Strategy (MSTR) after the 11-30 close. No tariff, bankruptcy or disaster shock surfaced (one widened search; not exhaustive).

### 2. Scheduled events that resolved in the window

- **October CPI (Tue 11-10, BLS):** headline +0.4% m/m against 0.3% expected; core +0.3% against 0.2%. Waller and Logan then argued for more hikes.
- **October PPI (Fri 11-13):** final demand +0.3% m/m against 0.4% expected; +6.5% y/y (CNBC).
- **Jobless claims (Thu 11-12):** initial 200K; continuing 1.697M.
- **Fed:** funds 3.75-4.00%. The next FOMC is Dec 8-9; CME FedWatch put a December 25 bp hike at about 87% on 11-11. Williams (11-12): "more rate hikes likely".
- **TSMC October revenue (Tue 11-10, TSMC release / 6-K):** NT$586.89B, +59.7% y/y and +14.7% m/m, a record above the NT$560-570B analyst range.
- **Earnings that moved stocks ≥5%** are in item 3. Notables: CoreWeave (after the close 11-10, beat and raised its 2026 guide; +24.71% on 11-11), Nebius (−16.84% 11-12 on a capex raise), Corteva (−24.30% 11-12 on a cut 2026 outlook), Cisco (−6.24% 11-13 despite a beat and raise).
- **Pending, not resolved:** Disney's fiscal Q4 FY26 report is scheduled for **Tue 11-17 before the open** (Disney IR). It has not reported, so no FQ4 figures exist. Nvidia reports 11-17; October retail sales are due 11-17.
- FDA/PDUFA: no PDUFA outcome on a ≥$2B name was established from the FDA's own pages in this window; none is recorded.
- Key-less earnings-calendar enumeration (Nasdaq) was not available this run (see item 3 DEGRADED note), so the earnings list comes from web mover lists and is not exhaustive.


### 3. Large single-name moves — AI-significance screen, FULL mode (B ACTIVATE)

Durable record: `research-screen` row `c3638fec-f367-45f4-936a-b08b24291514` (screen `single-name-move`, `screen_mode` full). One row covers the four-session window; every item carries its own reaction session.

**DEGRADED DISCOVERY.** Every key-less `curl` fetch (Nasdaq screener and historical bars, EDGAR submissions, Google News RSS) was refused by this session's permission classifier. So no full ≥$2B universe sweep ran. Names came from one web search per session for published mover lists (115 entries), FMP's 11-13 gainers, losers and most-active lists (a partial net), and the 25-name gated re-check pool. All 115 discovered names were measured on IBKR regular-session daily bars (close array; two sequential batches of 60 and 55, `search_contracts` paced under 25 a minute). Events and release times came from one web attribution pass. Movers between 2% and 5% were not individually measured. The eligible population is NOT fully measured; `surfaced_count` counts confirmed passes only.

**Passed (20; all ≥5% on IBKR bars, ≥$2B, own event, resolved anchor):**
- **CRWV** +24.71% on 2026-11-11 (48.73 → 60.77); anchor 2026-11-10 (after-close); conviction 75. Q3 revenue beat, 2026 revenue guide raised to $13.0-13.3B; reported after close 11/10. Prior ≥5% sessions in the prior 10: 8.
- **CTVA** -24.30% on 2026-11-12 (12.14 → 9.19); anchor 2026-11-11 (after-close); conviction 75. Q3 miss and sharply cut FY adj. core profit outlook (Brazil); released after close Wed 11/11, exact time not established.
- **AAON** +19.31% on 2026-11-10 (62.87 → 75.01); anchor 2026-11-09 (after-close); conviction 60. Q3 record results, FY26 sales growth guide raised to 72-75% (also H1 restatement/material weakness); released after close Mon 11/9. Prior ≥5% sessions in the prior 10: 6.
- **HIMS** -16.61% on 2026-11-10 (22.94 → 19.13); anchor 2026-11-09 (after-close); conviction 60. Q3 results miss, Q4 revenue guide well below consensus, FY EBITDA guide cut; release after close 11/9, exact time not established. Prior ≥5% sessions in the prior 10: 6.
- **NOVT** -15.26% on 2026-11-10 (145.98 → 123.71); anchor 2026-11-09 (after-close); conviction 60. Q3 beat but Q4 EPS guide below consensus, Stockport factory issue; released after close 11/9 (Business Wire). Prior ≥5% sessions in the prior 10: 2.
- **QLYS** -13.51% on 2026-11-10 (202.46 → 175.11); anchor 2026-11-09 (after-close); conviction 60. Q3 beat, FY raised, but Q4 billings growth guide ~8% vs 14%; released after close 11/9. Prior ≥5% sessions in the prior 10: 3.
- **YETI** -10.49% on 2026-11-12 (42.79 → 38.3); anchor 2026-11-12 (pre-open); conviction 60. Q3 results, FY26 sales/EPS outlook cut (GlobeNewswire 06:00 ET). Prior ≥5% sessions in the prior 10: 1.
- **LFTO** +30.63% on 2026-11-13 (18.71 → 24.44); anchor 2026-11-12 (after-close); conviction 60. Q3 results well above guidance (rev $238M +32%, NI $87M); reported after close 11/12. Prior ≥5% sessions in the prior 10: 5.
- **NU** +11.75% on 2026-11-13 (11.83 → 13.22); anchor 2026-11-12 (after-close); conviction 60. Record Q3 net income $1.1B; results after close 11/12 (call 5pm ET).
- **TTWO** +8.31% on 2026-11-10 (207.4 → 224.64); anchor 2026-11-09 (after-close); conviction 45. FQ2 FY27 results (bookings below guide), GTC VI preorders far above expectations, outlook reiterated; 8-K 11/9 after close. Prior ≥5% sessions in the prior 10: 1.
- **ONON** -7.54% on 2026-11-10 (37.53 → 34.7); anchor 2026-11-10 (pre-open); conviction 45. Q3 results: DTC sales miss despite adj EPS beat; reported pre-market 11/10 (exact time not established). Prior ≥5% sessions in the prior 10: 2.
- **SKYD** -7.59% on 2026-11-10 (8.7 → 8.04); anchor 2026-11-09 (after-close); conviction 45. First post-WBD-merger Q3 results, Q4 EBITDA headwind ($200M) from WB film slate; released 11/9 ahead of 5pm ET call. Prior ≥5% sessions in the prior 10: 1.
- **GFL** -7.56% on 2026-11-10 (45.88 → 42.41); anchor 2026-11-10 (pre-open); conviction 45. Board ended strategic review, rejected ~$22B ($52/sh) Blackstone/KKR/ECP take-private proposals (not a signed deal), BC Partners stake sale; announced pre-open 11/10, exact time not established.
- **HWC** -10.20% on 2026-11-12 (72.38 → 65); anchor 2026-11-12 (pre-open); conviction 45. Definitive all-stock agreement to acquire Trustmark (~$3.2B, 0.7463 HWC/TRMK); HWC is ACQUIRER; announced before open 11/12, exact time not established.
- **NBIS** -16.84% on 2026-11-12 (154.69 → 128.64); anchor 2026-11-12 (pre-open); conviction 45. Q3 results: revenue beat but 2026 revenue to low end of guide, capex raised to ~$27B, 2027 capex $40-45B. Prior ≥5% sessions in the prior 10: 10.
- **DGII** -12.72% on 2026-11-12 (66.96 → 58.44); anchor 2026-11-11 (after-close); conviction 45. FQ4 beat but FY27 growth guide 10-15% and Q1 guide disappointed; released after close Wed 11/11. Prior ≥5% sessions in the prior 10: 3.
- **CSCO** -6.24% on 2026-11-13 (102.01 → 95.64); anchor 2026-11-12 (after-close); conviction 45. FQ1 FY27 beat/raise but Q2 guide below Q1 and margin pressure; released after close Thu 11/12, PT cuts. Prior ≥5% sessions in the prior 10: 2.
- **MOD** +27.86% on 2026-11-13 (106.1 → 135.66); anchor 2026-11-12 (after-close); conviction 45. Bloomberg report Samsung in takeover talks for Modine (not a signed deal, no price); surfaced after Thursday close (+29% after-hours), exact time not established. Prior ≥5% sessions in the prior 10: 5.
- **RKLB** +6.54% on 2026-11-10 (58.86 → 62.71); anchor 2026-11-09 (after-close); conviction 30. Q3 2026 results, record backlog, Q4 guide (GlobeNewswire). Prior ≥5% sessions in the prior 10: 5.
- **STVN** -28.57% on 2026-11-03 (19.74 → 14.1); anchor 2026-11-03 (pre-open); conviction 45. Q3 results with 2027 growth warning (GLP-1 customer volume cut); released pre-market 11/3, call 8:30 ET.

**Rejected_notable (18):**
- FA -8.25% on 2026-11-10 — `OFFERING_PRICED`. Silver Lake 15M-share secondary launched after the 11-09 close and priced at $21.80, a 7.3% discount with no company proceeds; the move is the offering discount, not new information.
- KDP -7.40% on 2026-11-12 — `OFFERING_PRICED`. $2.0B common-stock offering announced before the 11-12 open and priced at $34.50; dilution priced mechanically, not new information. KDP's 11-03 earnings anchor already passed in c51c9632.
- ACAD +10.79% on 2026-11-10 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: Federal Circuit oral argument on the Nuplazid patent (11-09) plus a BMO note.
- CHTR +10.61% on 2026-11-10 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: Q3 results with a $2B opex-cut plan and a $1.5B below-par debt tender (PRNewswire 11-10).
- NVDA -5.47% on 2026-11-10 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: second day of the CEO-conduct disclosure (Sunday 11-08 memo, board probe); the CEO resigned 11-12.
- TREX -7.30% on 2026-11-10 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: downgrade to Neutral (PT $55).
- REZI +18.25% on 2026-11-11 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: Q3 beat and FY26 outlook update (PRNewswire 11-10).
- SONO +12.85% on 2026-11-11 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: FQ4 results, $150M buyback and FQ1 guide (BusinessWire 11-10).
- FIS -6.12% on 2026-11-12 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: KBW-conference remarks calling 2027 a transition year and a Truist PT cut.
- GPN -12.01% on 2026-11-12 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: Reuters report that CD&R and GTCR abandoned take-private talks (stock halted intraday).
- WRBY -11.34% on 2026-11-12 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: smart-eyewear preorders opened 11-12; sell-the-news after a large run.
- CBRS +11.22% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: raised 2026 core revenue outlook and a Microsoft customer win.
- NBIS -9.92% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: report that Microsoft is reviewing neocloud contracts, inside a chip selloff; second day after the 11-12 print.
- WWW +8.83% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: continuation after the 11-12 Q3 beat with several PT raises.
- CVLT -8.48% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: CFO departure with guidance reaffirmed (11-13).
- DGII -5.15% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: second day after the FQ4 print with a Piper Sandler PT cut; the same 11-11 anchor passed in this row's 11-12 item.
- STVN +10.03% on 2026-11-13 — `ANCHOR_UNRESOLVED`. Own event identified but its first-public time was not established from an issuer or news timestamp, so the anchor is UNRESOLVED and no window is indexed: director open-market purchases after the 11-03 collapse.
- HTFL -19.13% on 2026-11-13 — `NO_EVENT_FOUND`. A -19% move with no event found in this run's search; likely own-event but unattributed, so it does not clear the identified-event rail.

**Not railed.** Sympathy and beta moves with no own event (AI-infrastructure rally on 11-11 after CoreWeave; the chip and neocloud selloff on 11-12 and 11-13 after Nvidia's CEO exit), for example MU +11.89%, ARM +12.05%, DELL +11.75% and −7.18%, AMD −8.75%, IREN, APLD, AAOI and RGTI, are listed in `fields.sympathy_not_railed`. 18 ticker-sessions were not researched for events (named in `degraded_legs`). Names under $2B (PEPG, ZIP, APPS, SECZ, AZTA, FRMI and others) are listed in `fields.below_cap_not_railed`.

**First-full-run gated re-check.** The pool had 655 names; the 25 largest were checked. **STVN passed** (Q3 2027 growth warning, pre-open 11-03, −28.57%, window closes 11-17). Five were dropped for market cap under $2B. FLY's 11-06 engine deal has no release time. The rest have no own event on their gated move session (broad AI, semis and crypto beta), so their anchors stay UNRESOLVED.

**Deal-pinned rail:** not triggered. GFL rejected take-private bids (a deal break), HWC is an acquirer, and MOD's Samsung talks are an unsigned report.

### 4. Sector-level moves (IBKR regular-session closes 11-09 → 11-13)

Durable record: `research-screen` row `70bf9236-a05d-481e-8247-e57453b7dd3b` (screen `sector-move`). 9 sector-sessions crossed the 1% rail; 3 passed:
- **XLK 11-11 +3.23%** (168.91 → 174.36; SMH +4.82%): CoreWeave's beat-and-raise re-lit the AI-infrastructure trade. Conviction 60.
- **XLK 11-13 −2.01%** (173.77 → 170.28; SMH −2.99%): the AI-chip selloff resumed after Nvidia's CEO exit, with the 10-year at 5.15%. Conviction 60.
- **XLE 11-12 +1.51%** (63.37 → 64.33): Brent (BZUSD, provisional same-evening read) 92.76 on 2026-11-11 → 95.82 on 2026-11-12 after Trump's Hormuz post and Houthi claims on Saudi sites. Energy rose 4.88% on the week. Conviction 45.
- Rejected: XLK 11-10 −1.15% (CPI and rates), XLE 11-11 +1.86% (same oil theme), XLI 11-11 +1.33% (beta), XLB 11-12 −1.28% (Corteva single-name), XLP 11-13 +1.42% and XLC 11-13 +1.05% (defensive rotation).

### 5. Notable commentary

- Goldman strategists (11-13): S&P 500 +14% over the next year on cheap hyperscaler valuations. Goldman expects hikes in December and March (Bloomberg, CNBC).
- JPMorgan: "AI is not a continued sell"; Morgan Stanley: "buy the drop" (Axios, 11-10).
- Citi Wealth CIO: the Fed may need to hike more than is priced.
- Fed: Waller (11-10) put 50 bp on the table if core inflation stays near 0.3%; Logan wants at least two more hikes; Williams (11-12) said "more rate hikes likely".

## ANALYSIS — RISK TO EXISTING POSITIONS

**Book.** `state.current_positions` (12 Strategy D tranches in 8 names) matches the IBKR connector exactly (AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156) plus the VOO park (16.895 sh). No reconciliation-lag position. No Strategy B position, so the B pairwise-correlation check is inert (n_positions 0).

**Mechanical exit sweep.** No tranche carries a convergence target or time-exit date (Strategy D, no max hold). No EXIT TRIGGERED.

**Kill-trigger sweep.** `perf.kill_flags` (D as of 11-09, B as of 08-18): drawdown_kill, runaway_review, m2m_underperf_review, evidence_kill and interim_underperf_warning are all FALSE. D's engine drawdown was −5.83% at 11-09. Refreshed against 11-13 closes, the D sleeve moved by under 1% (GEV −3.2%, ISRG −3.7%, UBER −2.1%, GOOGL +2.6%, TSM +2.6% over the four sessions), far from the 50% line. No interim-underperformance alert to raise or heal.

**Thesis-invalidation read, per name:**
- DIS (2 tranches): NO. Fiscal Q4 FY26 reports Tue 11-17 before the open (Disney IR), so the SVOD-margin, EPS-guide and buyback criteria have no new reading. Test them on the 11-17 print.
- TSM (2): NO. October revenue NT$586.89B (+59.7% y/y, record) reinforces criteria 1 and 3.
- GEV: NO. The −17% from cost is the AI-power de-rating (SoftBank $3.7B equipment charge; Musk's turbine-default claim, denied by SoftBank; rates). The criterion is quarterly organic orders growth, and there is no new reading. Not-exit-triggering per entry: short-term price action.
- GOOGL (2): NO. No Cloud revenue, margin or RPO reading and no structural remedy in the window.
- UBER: NO. The Q3 print came in the window (revenue $14.77B; mobility revenue missed). No two-consecutive-quarter gross-bookings or margin breach is evidenced. The 11-13 vendor data breach is not a criterion.
- RTX: NO. 2026 guide reaffirmed (11-10) and S&P upgraded RTX to A- (11-13).
- AMZN (2), ISRG: NO. No criterion-relevant development.

No price-level criterion is open, so dividend netting does not apply.

**Watchlist candidates.** B ACTIVATE re-opens the B index path. The 451 B thesis items D2 enqueued on 11-09 are D2's to drain. No development changes an A-queue or E-pair candidacy (both gated).

## ANALYSIS — OPPORTUNITY CHECK

- **B:** the 20 screen passes above clear Entry criterion 1 (≥5% close-to-close on the reaction session) on IBKR bars, with resolved anchors. They go to the new-entry index for W2's ranking. None is caught by the Deal-pinned rail.
- **C (carve-out only):** the next FOMC is Dec 8-9 (24 days out). It is not newly announced, and the carve-out class is already tracked. No new C candidate.
- **A, D, E:** gated; nothing evaluated.

## ANALYSIS — ADD-CANDIDATE CHECK

Durable record: `add-candidate-review` row `631ac725-aff0-4803-a504-90caddb6495e`. 12 D tranches evaluated, 0 flagged, 0 declined at the hard gate. Every tranche has a populated `invalidation_status` with no NOT_ASSESSED marker (`invalidation_criteria_evaluable` TRUE). Dip reads on GEV (−17.20% vs cost) and GOOGL (−17.81%, −9.78%) and strengthened-conviction reads on TSM (record October revenue) are declined because D reads DO-NOT-ACTIVATE. Prices are IBKR 11-13 bar closes over each tranche's own cost. The connector's position marks were stale (GEV 790.01 vs 803.13).

## ANALYSIS — REGIME CHECK

Standing `shock_overlay` = `latent` (M1R snapshot as of 2026-11-09; the Gulf/Hormuz structure opened 2026-09-09 remains open).
- **11-12 events (Iran's claim of four tankers hit; Houthi claims on Saudi oil sites; Trump's "we've got their Strait" post):** the two-session window is closed. Brent (BZUSD) 92.76 (11-11) → 95.82 (11-12, +$3.06) → 95.84 (11-13, +$3.08 cumulative). That is under the >$5/bbl criterion, and no trade-flow, spread or currency leg was measured. Not a qualifying event.
- **2026-11-14 (Sat): Iran's navy says three tankers hit mines in Hormuz** (state media via Reuters; not independently confirmed). This is a dated development on the named Hormuz channel. Its two-session oil window is S1 Mon 11-16 and S2 Tue 11-17, against a prior close of 95.84 (11-13). Neither session has closed, so the window is **PENDING**. Flagged as a `router_review` so that D2 logs it refresh-only and M1R rules after S2.
- **11-15 IRGC drone claim on a US radar in Bahrain:** a military action with no trade-flow or price leg of its own yet. It is noted under the 11-14 flag, which covers the same window.
- **Resolution side:** no ceasefire, settlement or blockade lift is in force. Trump said no deal is needed (11-12), and the blockade continues.
- **Measured triggers** (VIX, SPY trend, breadth, shock price leg) are D2 item 4's to detect from D2a rows; none is computed here.

## EQUITY-BREADTH OBSERVATION

Written to `events.regime_events` (`TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`, as_of 2026-11-13) = **63.81**. Barchart `$S5TH`, "Quote Overview for Fri, Nov 13th, 2026", with Previous Close 61.82. EODData's end-of-day table agrees (11-13 close 63.81, low 62.02; 11-12 close 61.82). Both were read on 11-15, so the dated table row is settled. Barchart and EODData count as ONE source. ChartRow cross-check: "as of market close, Nov 13, 2026", 317 of 497 eligible (63.78%), consistent. Its day-over-day gap is unavailable because no 11-12 ChartRow count is on record. The weekly MacroMicro re-probe returned HTTP 403. No 11-10..11-12 rows were written (only the last completed session is owed).

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. `hf://papers/daily/latest` was empty on Sunday. The Sunday long-context battery search returned only catalogued or out-of-window papers.

## RECOMMENDED ACTIONS

- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 revenue beat, 2026 revenue guide raised to $13.0-13.3B; reported after close 11/10 after-close release on 2026-11-10; reaction session 2026-11-11, +24.71% (48.73 -> 60.77), with 8 prior >=5% sessions in the window; qualifying_event_date 2026-11-10.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 miss and sharply cut FY adj. core profit outlook (Brazil); released after close Wed 11/11, exact time not established after-close release on 2026-11-11; reaction session 2026-11-12, -24.30% (12.14 -> 9.19); qualifying_event_date 2026-11-11.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 record results, FY26 sales growth guide raised to 72-75% (also H1 restatement/material weakness); released after close Mon 11/9 after-close release on 2026-11-09; reaction session 2026-11-10, +19.31% (62.87 -> 75.01), with 6 prior >=5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results miss, Q4 revenue guide well below consensus, FY EBITDA guide cut; release after close 11/9, exact time not established after-close release on 2026-11-09; reaction session 2026-11-10, -16.61% (22.94 -> 19.13), with 6 prior >=5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 beat but Q4 EPS guide below consensus, Stockport factory issue; released after close 11/9 (Business Wire) after-close release on 2026-11-09; reaction session 2026-11-10, -15.26% (145.98 -> 123.71), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 beat, FY raised, but Q4 billings growth guide ~8% vs 14%; released after close 11/9 after-close release on 2026-11-09; reaction session 2026-11-10, -13.51% (202.46 -> 175.11), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results, FY26 sales/EPS outlook cut (GlobeNewswire 06:00 ET) pre-open release on 2026-11-12; reaction session 2026-11-12, -10.49% (42.79 -> 38.3), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results well above guidance (rev $238M +32%, NI $87M); reported after close 11/12 after-close release on 2026-11-12; reaction session 2026-11-13, +30.63% (18.71 -> 24.44), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Record Q3 net income $1.1B; results after close 11/12 (call 5pm ET) after-close release on 2026-11-12; reaction session 2026-11-13, +11.75% (11.83 -> 13.22); qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ2 FY27 results (bookings below guide), GTC VI preorders far above expectations, outlook reiterated; 8-K 11/9 after close after-close release on 2026-11-09; reaction session 2026-11-10, +8.31% (207.4 -> 224.64), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results: DTC sales miss despite adj EPS beat; reported pre-market 11/10 (exact time not established) pre-open release on 2026-11-10; reaction session 2026-11-10, -7.54% (37.53 -> 34.7), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-10.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): First post-WBD-merger Q3 results, Q4 EBITDA headwind ($200M) from WB film slate; released 11/9 ahead of 5pm ET call after-close release on 2026-11-09; reaction session 2026-11-10, -7.59% (8.7 -> 8.04), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Board ended strategic review, rejected ~$22B ($52/sh) Blackstone/KKR/ECP take-private proposals (not a signed deal), BC Partners stake sale; announced pre-open 11/10, exact time not established pre-open release on 2026-11-10; reaction session 2026-11-10, -7.56% (45.88 -> 42.41); qualifying_event_date 2026-11-10.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Definitive all-stock agreement to acquire Trustmark (~$3.2B, 0.7463 HWC/TRMK); HWC is ACQUIRER; announced before open 11/12, exact time not established pre-open release on 2026-11-12; reaction session 2026-11-12, -10.20% (72.38 -> 65); qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results: revenue beat but 2026 revenue to low end of guide, capex raised to ~$27B, 2027 capex $40-45B pre-open release on 2026-11-12; reaction session 2026-11-12, -16.84% (154.69 -> 128.64), with 10 prior >=5% sessions in the window; qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ4 beat but FY27 growth guide 10-15% and Q1 guide disappointed; released after close Wed 11/11 after-close release on 2026-11-11; reaction session 2026-11-12, -12.72% (66.96 -> 58.44), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-11.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ1 FY27 beat/raise but Q2 guide below Q1 and margin pressure; released after close Thu 11/12, PT cuts after-close release on 2026-11-12; reaction session 2026-11-13, -6.24% (102.01 -> 95.64), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Bloomberg report Samsung in takeover talks for Modine (not a signed deal, no price); surfaced after Thursday close (+29% after-hours), exact time not established after-close release on 2026-11-12; reaction session 2026-11-13, +27.86% (106.1 -> 135.66), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-12.
- Watchlist: ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 2026 results, record backlog, Q4 guide (GlobeNewswire) after-close release on 2026-11-09; reaction session 2026-11-10, +6.54% (58.86 -> 62.71), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD (first-full-run gated re-check) to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results with 2027 growth warning (GLP-1 customer volume cut); released pre-market 11/3, call 8:30 ET pre-open release on 2026-11-03; reaction session 2026-11-03, -28.57% (19.74 -> 14.1); qualifying_event_date 2026-11-03.
- Router review (refresh-only): 2026-11-14 Iranian navy claim that three tankers hit mines in the Strait of Hormuz (state media via Reuters), a dated event on the Gulf/Hormuz channel while shock_overlay reads latent; it may meet the Qualifying shock event criterion (trade-flow effect or an oil move > $5/bbl). Two-session window PENDING: S1 2026-11-16, S2 2026-11-17, prior Brent (BZUSD) close 95.84 on 2026-11-13; no closed-session move yet. Also noted: 11-15 IRGC drone claim on a US radar in Bahrain.

```yaml d1_actions
- action: watchlist
  ticker: CRWV
  strategy: B
  qualifying_event_date: 2026-11-10
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 revenue beat, 2026 revenue guide raised to $13.0-13.3B; reported after close 11/10 after-close release on 2026-11-10; reaction session 2026-11-11, +24.71% (48.73 -> 60.77), with 8 prior >=5% sessions in the window; qualifying_event_date 2026-11-10."
- action: watchlist
  ticker: CTVA
  strategy: B
  qualifying_event_date: 2026-11-11
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 miss and sharply cut FY adj. core profit outlook (Brazil); released after close Wed 11/11, exact time not established after-close release on 2026-11-11; reaction session 2026-11-12, -24.30% (12.14 -> 9.19); qualifying_event_date 2026-11-11."
- action: watchlist
  ticker: AAON
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 record results, FY26 sales growth guide raised to 72-75% (also H1 restatement/material weakness); released after close Mon 11/9 after-close release on 2026-11-09; reaction session 2026-11-10, +19.31% (62.87 -> 75.01), with 6 prior >=5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: HIMS
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results miss, Q4 revenue guide well below consensus, FY EBITDA guide cut; release after close 11/9, exact time not established after-close release on 2026-11-09; reaction session 2026-11-10, -16.61% (22.94 -> 19.13), with 6 prior >=5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: NOVT
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 beat but Q4 EPS guide below consensus, Stockport factory issue; released after close 11/9 (Business Wire) after-close release on 2026-11-09; reaction session 2026-11-10, -15.26% (145.98 -> 123.71), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: QLYS
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 beat, FY raised, but Q4 billings growth guide ~8% vs 14%; released after close 11/9 after-close release on 2026-11-09; reaction session 2026-11-10, -13.51% (202.46 -> 175.11), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: YETI
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results, FY26 sales/EPS outlook cut (GlobeNewswire 06:00 ET) pre-open release on 2026-11-12; reaction session 2026-11-12, -10.49% (42.79 -> 38.3), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: LFTO
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results well above guidance (rev $238M +32%, NI $87M); reported after close 11/12 after-close release on 2026-11-12; reaction session 2026-11-13, +30.63% (18.71 -> 24.44), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: NU
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Record Q3 net income $1.1B; results after close 11/12 (call 5pm ET) after-close release on 2026-11-12; reaction session 2026-11-13, +11.75% (11.83 -> 13.22); qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: TTWO
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ2 FY27 results (bookings below guide), GTC VI preorders far above expectations, outlook reiterated; 8-K 11/9 after close after-close release on 2026-11-09; reaction session 2026-11-10, +8.31% (207.4 -> 224.64), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: ONON
  strategy: B
  qualifying_event_date: 2026-11-10
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results: DTC sales miss despite adj EPS beat; reported pre-market 11/10 (exact time not established) pre-open release on 2026-11-10; reaction session 2026-11-10, -7.54% (37.53 -> 34.7), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-10."
- action: watchlist
  ticker: SKYD
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): First post-WBD-merger Q3 results, Q4 EBITDA headwind ($200M) from WB film slate; released 11/9 ahead of 5pm ET call after-close release on 2026-11-09; reaction session 2026-11-10, -7.59% (8.7 -> 8.04), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: GFL
  strategy: B
  qualifying_event_date: 2026-11-10
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Board ended strategic review, rejected ~$22B ($52/sh) Blackstone/KKR/ECP take-private proposals (not a signed deal), BC Partners stake sale; announced pre-open 11/10, exact time not established pre-open release on 2026-11-10; reaction session 2026-11-10, -7.56% (45.88 -> 42.41); qualifying_event_date 2026-11-10."
- action: watchlist
  ticker: HWC
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Definitive all-stock agreement to acquire Trustmark (~$3.2B, 0.7463 HWC/TRMK); HWC is ACQUIRER; announced before open 11/12, exact time not established pre-open release on 2026-11-12; reaction session 2026-11-12, -10.20% (72.38 -> 65); qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: NBIS
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results: revenue beat but 2026 revenue to low end of guide, capex raised to ~$27B, 2027 capex $40-45B pre-open release on 2026-11-12; reaction session 2026-11-12, -16.84% (154.69 -> 128.64), with 10 prior >=5% sessions in the window; qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: DGII
  strategy: B
  qualifying_event_date: 2026-11-11
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ4 beat but FY27 growth guide 10-15% and Q1 guide disappointed; released after close Wed 11/11 after-close release on 2026-11-11; reaction session 2026-11-12, -12.72% (66.96 -> 58.44), with 3 prior >=5% sessions in the window; qualifying_event_date 2026-11-11."
- action: watchlist
  ticker: CSCO
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): FQ1 FY27 beat/raise but Q2 guide below Q1 and margin pressure; released after close Thu 11/12, PT cuts after-close release on 2026-11-12; reaction session 2026-11-13, -6.24% (102.01 -> 95.64), with 2 prior >=5% sessions in the window; qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: MOD
  strategy: B
  qualifying_event_date: 2026-11-12
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Bloomberg report Samsung in takeover talks for Modine (not a signed deal, no price); surfaced after Thursday close (+29% after-hours), exact time not established after-close release on 2026-11-12; reaction session 2026-11-13, +27.86% (106.1 -> 135.66), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-12."
- action: watchlist
  ticker: RKLB
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 2026 results, record backlog, Q4 guide (GlobeNewswire) after-close release on 2026-11-09; reaction session 2026-11-10, +6.54% (58.86 -> 62.71), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: STVN
  strategy: B
  qualifying_event_date: 2026-11-03
  source_research_screen_id: c3638fec-f367-45f4-936a-b08b24291514
  detail: "ADD (first-full-run gated re-check) to the Strategy B new-entry index (B ACTIVATE; W2 ranks, no thesis handoff from D1): Q3 results with 2027 growth warning (GLP-1 customer volume cut); released pre-market 11/3, call 8:30 ET pre-open release on 2026-11-03; reaction session 2026-11-03, -28.57% (19.74 -> 14.1); qualifying_event_date 2026-11-03."
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: "Router review (refresh-only): 2026-11-14 Iranian navy claim that three tankers hit mines in the Strait of Hormuz (state media via Reuters), a dated event on the Gulf/Hormuz channel while shock_overlay reads latent; it may meet the Qualifying shock event criterion (trade-flow effect or an oil move > $5/bbl). Two-session window PENDING: S1 2026-11-16, S2 2026-11-17, prior Brent (BZUSD) close 95.84 on 2026-11-13; no closed-session move yet. Also noted: 11-15 IRGC drone claim on a US radar in Bahrain."
```


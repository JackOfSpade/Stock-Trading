2026-10-21
<!-- d1_scan_through_utc: 2026-10-22T04:30:00Z -->

# Daily Market Development Scan — 2026-10-21 (Wed, MT)

Scan window: 2026-10-20 16:30 MT → 2026-10-21 22:30 MT (~30h). The start comes from the prior `Daily.md` marker `2026-10-20T22:30:00Z`, and that file's commit (22:31Z) agrees. The window holds **one completed US trading session, Wednesday 2026-10-21**, plus the 10-20 after-close releases, which react on 10-21. Releases after the 10-21 close (META, TSLA, IBM, LRCX, TXN, SAP, CSX, MEDP and others) react on 10-22 and are pending.

Tape: **the AI trade came back.** SpaceX's after-close Q3 and Super Micro's raised outlook lifted AI hardware, a cybersecurity rally followed critical PHP flaws, and telecom/media lagged on AT&T and Netflix.
- **Indices.** IBKR regular-session closes, 10-20 → 10-21: SPY 769.05 → **773.09 (+0.5253%)**, **QQQ +1.0549%**, IWM +0.2538%, DIA +0.6370%, RSP +0.3613%, **SMH +1.8925%**.
- **VIX 16.68** (from 17.31). This is D2a's FMP-sourced close; IBKR's CBOE index history returned "details currently unavailable" three times.
- **Rates.** 10Y about 5.13-5.15% (+1-3bp) and 2Y about 4.80-4.82%, from secondary wraps; D2a's FMP pin reads 10Y 5.13 / 2Y 4.81. A $13B 20-year auction tailed 0.9bp. TLT +0.14% and HYG +0.20%.
- **Oil.** **Brent December settled $108.82 on 10-21 (+$0.03)** and **$108.79 on 10-20** (Newsquawk, ICIS; the 10-21 figure has a single source). WTI December was $97.15 (10-21) and $97.82 (10-20). Brent traded about $110.2-110.7 early on 10-21 and gave the gain back. USO −0.50% and GLD +0.34%.
- **Leadership.** XLK +1.67 led and XLC −1.11 lagged. Defensives (XLRE −0.76, XLP −0.73, XLV −0.49) trailed a tech-led tape.

## TL;DR

- **Exits triggered: none.** Twelve Strategy D tranches carry no mechanical trigger. ISRG's Q3 (10-20 after close) and the window's other news breach no criterion.
- **New entry candidates: none routed.** Ten names cleared Strategy B's frozen ≥5% floor on their own events. B is `DO-NOT-ACTIVATE` and capital-disabled, so they go to the index only: **SPCX, SMCI, WFRD, LAD, MHO, T, NFLX, ROIV, FLY, ASST**.
  - AMX and RCUS have unresolved anchors, so they are not routed.
  - TLX is an ADS below the $10B line, so it is ineligible.
- **Add candidates: none (0 of 12).** D is `DO-NOT-ACTIVATE` and capital-disabled.
- **Watchlist: 10 changes.** ADD the ten names above to the Strategy B new-entry index.
- **Regime review: no review.** VIX is 16.68 and breadth rose to **54.67**. The Gulf headlines (IRGC mine claims, the Shaybah drone, embassy ordered-departure prep) fall inside the standing `acute` shock overlay.

Park: VOO-only pin verified

Paper book (J): 120 calls, 0/30 realized, net_mu n/a, ready=FALSE

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Gulf / Hormuz.**
  - **IRGC claims, unconfirmed.** The IRGC says two "offending" tankers burned after hitting its mines, a third tanker carrying more than 2M barrels was struck, and it shot down a US MQ-9. It calls the strait "completely closed."
  - **Flows.** The US says Hormuz flows recovered to about 14M bpd. Kpler counts at least 18 vessel attacks in two weeks, and LSEG analysts see targeting spreading into the Gulf of Oman.
  - **Saudi Arabia.** A Houthi drone attack on Aramco's Shaybah field on 10-21 was intercepted with no operational impact. Argus says Yanbu and Shaybah are undamaged.
  - **Late 10-21.** State is preparing ordered departures at some Gulf embassies. Brent rose and T-notes fell on the headline.
  - **US and Israel.** Trump ruled out a new Iran strike before the midterms. The Theodore Roosevelt group and the 13th MEU are being dispatched. Netanyahu named regime change in Iran a military objective.
  - **EIA (week to 10-16).** Crude −3.06M barrels vs about −0.8M expected; gasoline −2.95M.
  - Sources: Newsquawk US wrap, Nation Thailand, Atalayar/CBS, Dawn live blog.
- **Russia.** Russia reportedly accepted a US-proposed trilateral meeting with Ukraine (Axios). The EU will not lift energy sanctions. The US eased Russian-diesel record-keeping and licensed Lukoil International sale talks.
- **Europe.** The French 10-year hit 5% for the first time since 2002. The OAT-Bund spread is about 160bp, with Moody's due on France 10-23. UK CPI was 3.5% vs 3.4% expected.
- **AI credit.**
  - CoreWeave 5-year CDS is above 1,100bp, and its 9.625% 2032 notes are at about 79. CRWV fell −0.50% even as the AI trade rallied.
  - Anthropic's draft IPO filing (247wallst, Bitget) cites about $450B of signed cloud commitments: Google Cloud $111B, AWS $110B, Microsoft $31B. It also cites a possible ~$2T valuation, with a public S-1 possibly as early as 10-23.
  - These are secondary reports of a draft. **No OpenAI funding or compute-commitment event** was found; that means nothing was found, not that none exists.

### 2. Scheduled events that resolved in the window

- **Enumeration.**
  - The Nasdaq key-less calendar was fetched with curl for 10-20 (39 reporters ≥$2B), 10-21 (66) and 10-22 (80).
  - Release times come from issuer releases, EDGAR acceptance stamps or CNBC/investing.com after-hours movers lists, as noted per name. Several 10-21 pre-open times (LAD, MHO, OFG, ONB, UNF) rest on calendar "BMO" listings, not issuer timestamps.
  - FMP was unavailable this session, so it was not used.
- **Macro.**
  - No major US release on 10-21. Mortgage applications fell −5.3%, and the 30-year mortgage rate was 7.41%.
  - The Fed is in blackout before the 10-27/28 FOMC. Hike pricing conflicts: CME FedWatch per Newsquawk has October at ~3.7bp and December at ~25bp, while TheStreet shows October ~15% and December ~88%.
  - Weekly claims come 10-22.
- **Earnings that reacted on 10-21 (10-20 after close, then 10-21 pre-open), IBKR close-to-close.**

  | Ticker | Release | Result | 10-21 move |
  |---|---|---|---|
  | **SPCX** (SpaceX) | 10-20 after close | Q3 revenue $14.58B (+161%) vs ~$12.87B; adj EPS $0.35 vs $0.15; first profit as a public company. Musk confirmed SpaceX/Tesla committees are discussing a merger. | **+7.79%** |
  | **SMCI** | 10-20 after close | Preliminary FQ1'27 revenue raised to $18.5-19.5B, from $14.5-15.5B | **+9.55%** |
  | **NFLX** | 10-20 after close | EPS $0.87 vs $0.82; Q4 guide ($13.44B / $0.67) below consensus; ad forecast cut ~$300M | **−5.31%**, a 52-week low |
  | **ISRG** | 10-20 after close (issuer) | Revenue +22%; non-GAAP EPS $3.00; $450M antitrust settlement. Procedures +15%, placements 546 vs 427, I&A +18%. Guide narrowed to 14-15%; I&A per-procedure price cuts of 3-5% flagged. | −2.26% (−8.6% at the open) |
  | **WFRD** | 10-20 after close (calendar) | EPS ~$1.66 vs ~$1.21-1.30 | **+7.75%** |
  | **COF** | 10-20 after close | EPS $5.61 | +2.53% |
  | **UAL** | 10-20 after close | Slight miss: $2.54 vs $2.57 | +3.99% |
  | **T** | 06:30 ET 10-21 | Q3 beat; 2026 EPS outlook raised; fell on promotional-cost concern | **−6.45%** |
  | **LAD** | 10-21 pre-open (calendar) | Q3; specific driver not established | **−10.15%**, dragging GPI −7.48, AN −5.49 and SAH −5.23 |
  | **MHO** | 10-21 pre-open (calendar) | Q3; driver not established | **−8.08%** |
  | **DHR** | 10-21 pre-open | EPS $2.11 vs $1.92; FY guide raised to $8.57-8.62 | +4.29% |
  | **PM, TMO, ABT, NEE, CME, ELV, MCO** | 10-21 pre-open | — | All under 2%. ABT −1.89% lowered its diabetes-care growth outlook, and DXCM fell −6.39% on the read-through. |
  | **AMX** | Scheduled 10-20; release time not established | Revenue +7.6%, EBITDA margin 40.8% | +6.07% |
  | **TLX** | 6-K accepted 19:40 ET 10-20 | Q3 revenue +19% | −10.13% |
  | **ROIV** | 07:05 ET 10-21 8-K | Brepocitinib met all endpoints in both Phase 3 uveitis trials | **+5.38%** |

- **Released after the 10-21 close (react 10-22, pending; Newsquawk figures, issuer releases not fetched).**
  - **META:** revenue $64.6B vs $63.3B; GAAP EPS $3.83 after a $9.89B litigation charge; stronger Q4 guide; ~+3.5% after hours.
  - **TSLA:** adj EPS $0.48 vs $0.45; revenue $28.0B vs $28.1B; 2026 capex guide cut. The after-hours direction conflicts across sources.
  - **TXN:** EPS $2.62 vs $2.42; Q4 guide above consensus.
  - **IBM:** EPS $2.95 vs $2.86; FY FCF outlook raised.
  - **LRCX:** a slim beat; about −6.8% after hours.
  - **CSX:** EPS miss.
  - **SAP:** raised its operating-profit guide.
  - **LUV:** revenue beat with a fuel-driven profit-guide cut.
  - **Not captured:** KMI, URI, LVS.
- **FDA.** No PDUFA decision or CRL for a ≥$2B sponsor was found for 10-20/21. This is an absence among sponsor wires, not confirmed on the FDA's own page. Small-cap items: BCRX ORLADEYO pellet sNDA approved; Unicycive NDA accepted with a 3-25-2027 PDUFA.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

`research-screen` `70635acf-db7a-49d4-a63b-a2f429bc3f20` (`surfaced_count` 30 = `ARRAY_LENGTH(passed)`; agreement both 13 / ai_only 17 / rule_only 74). Every figure is an IBKR regular-session daily-bar close-to-close (close array), 10-20 → 10-21.

- **Discovery.**
  - **New this run:** a key-less Nasdaq historical-bar sweep of **every ≥$2B name in the Nasdaq screener file**, run with curl and unmetered. It covered 2,138 symbols; 2,134 had a 10-21 bar, and **524 moved ≥2%**.
  - Also: the 10-20/10-21 earnings calendar (58 names), IBKR's saved "US Movers" screener (47 names, an after-hours snapshot — its "decliners" LRCX/IBM/TSLA were after-close prints, not session moves), and three wide news searches.
  - **Confirmation.** 192 names were confirmed on IBKR bars: every ≥5% sweep name, every reporter, every screener name, and the held names.
  - **Not confirmed.** Sweep names moving 2-5% with no calendar event were not IBKR-confirmed or attributed. That is a Layer-2 decline on a common-tape day, stated in `selection_rule`.
- **Degraded legs.**
  - The FMP MCP server failed to connect, so there were no FMP movers lists and no `profile-symbol` caps. Caps come from Nasdaq's screener file (one day stale), with second sources for names within ~30% of $2B.
  - Nasdaq's stock screener still served the 10-20 session at run time, so it was used only for caps and the symbol universe.
- **Own-event ≥5% floor clearers: index only (B `DO-NOT-ACTIVATE`).**

  | Ticker | Move (close → close) | Event and anchor | Conviction | Notes |
  |---|---|---|---|---|
  | **SPCX** | +7.7948% (147.79 → 159.31) | After-close 10-20 Q3; anchor 10-20 | 75 | — |
  | **SMCI** | +9.5473% (32.47 → 35.57) | After-close 10-20 guidance raise; anchor 10-20 | 60 | Two other ≥5% sessions in the window (10-14, 10-16) |
  | **NFLX** | −5.3137% (68.69 → 65.04) | After-close 10-20 Q3 guide; anchor 10-20 | 60 | — |
  | **T** | −6.4475% (23.42 → 21.91) | Pre-open 10-21 Q3; anchor 10-21 | 60 | The move runs against a beat and raise, so criterion 4 is the crux. One other ≥5% session (10-09). |
  | **ROIV** | +5.3837% (34.92 → 36.80) | 07:05 ET 10-21 Phase 3 readout; anchor 10-21 | 60 | Sits near the floor |
  | **WFRD** | +7.7514% (79.34 → 85.49) | After-close 10-20 Q3 beat (calendar time); anchor 10-20 | 45 | Irish-domiciled, US-primary ordinary shares, so eligible under Rev 49 |
  | **LAD** | −10.1492% (299.53 → 269.13) | Pre-open 10-21 Q3 (calendar time); anchor 10-21 | 45 | Driver not established |
  | **MHO** | −8.0767% (124.06 → 114.04) | Pre-open 10-21 Q3 (calendar time); anchor 10-21 | 45 | Driver not established; homebuilders weak on 5%+ yields |
  | **FLY** | +8.2771% (16.31 → 17.66) | Pre-open 10-21 NASA Elytra design-review PR; anchor 10-21 | 30 | Space names also rose with SpaceX. Three other ≥5% sessions. Cap $2.73B. |
  | **ASST** | +13.6364% (27.06 → 30.75) | 10-21 8-K declaring the first SATS-preferred dividend; anchor 10-21 | 30 | A bitcoin-treasury name on a crypto-up day, with four other ≥5% sessions in the window |

- **Own events ≥5%, not routed.**
  - **AMX** +6.0699% (22.90 → 24.29): Q3 with its release time not established, so the anchor is UNRESOLVED.
  - **RCUS** −19.5789% (23.75 → 19.10): ARC-20 data PR (10-20, time unknown) plus an offering PR around the 10-21 close. Which release drove the session is unresolved, so the anchor is UNRESOLVED.
  - **TLX** −10.1254% (11.16 → 10.03): Q3 via a 19:40 ET 10-20 6-K. A foreign ADS of $3.8B is below the $10B ADR line, so it is B-ineligible.
- **Below the floor, own events (context only).** DHR +4.29, OFG −4.63, ELS −4.53, OZK +4.18, UAL +3.99, ADC −3.86, NP −3.73, TSLA +3.41 (SpaceX merger remarks), LRN −3.24, ONB −2.96, PEGA −2.90, UNF +2.76, COF +2.53, HWC −2.47, EWBC +2.43, ALK −2.39, ISRG −2.26.
- **Rejected: ≥5% with no own event (75 names in `rejected_notable`).**
  - **AI-hardware / AI-hosting common driver:** CRDO, BE, APLD, CIEN, WULF, TTMI, DELL (Super Micro read-through), RKLB and ECHO (SpaceX read-through).
  - **Cybersecurity rally on the PHP flaws:** ZS, OKTA, DDOG, NET, CRWD, NTSK, FSLY, RBRK; also MDB.
  - **CRO / life-science tools rally:** CRL, MEDP, ICLR, FTRE, ILMN, BRKR, TXG.
  - **Crypto beta:** MSTR, GLXY, XXI, PURR.
  - **Peer read-throughs:** DXCM (Abbott); GPI, AN and SAH (Lithia).
  - **Second-day moves:** WING (the StoneX target cut came pre-open 10-20), EQPT and MANE.
  - **Weak attribution:** KOD (an S-3ASR shelf, no priced offering) and OPEN (an executive change; cap ~$2.0B).
  - **No event found:** about 35 others, each named in the row.
- **Close-chain check (one read).**
  - 3 hits: HAS, MSCI, VICR. Today's prior_close equals their 10-20 event_close in `ec09d8fc`, and all three anchors were pre-open 10-20. So the 10-21 pair is the following session; the earlier dispositions carry forward and are not re-written.
  - No hit on any written item. Coverage is partial, so a clean pass is not a clearance.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

`research-screen` `eb301f2f-0617-4298-9164-eae4cfde118a` (`surfaced_count` 3). Registry contract ids were used; the 10-20 guard closes (XLV 179.82, XLF 55.72, XLK 185.44) matched.

- **XLK +1.6717%** (185.44 → 188.54), conviction 60: the AI-hardware revival (SMH +1.89, SOX +1.97) plus the cybersecurity rally. It reverses the 10-20 tech lag.
- **XLC −1.1072%** (110.19 → 108.97), conviction 45: AT&T −6.45 and NFLX −5.31 on earnings, plus GOOGL −1.62. This is earnings-driven, not beta.
- **Dispersion, defensives lagging** (XLRE −0.7551, XLP −0.73, XLV −0.49), conviction 30: logged with legacy false by convention. XLE was +0.28 on flat Brent.
- **Under 1%:** XLI +0.91, XLF +0.57, XLU +0.29, XLB +0.18, XLY +0.03.

### 5. Notable commentary

- **Analyst calls:**
  - Morgan Stanley kept Overweight on NFLX with a lower target, and Overweight on SpaceX ($300).
  - Wells Fargo raised its SpaceX target to $274.
  - RBC downgraded Mobileye to Underperform; Rosenblatt initiated HOOD at Buy.
  - StoneX cut its Wingstop target to $185, citing a hard quarter for fast-food chains (10-20).
  - Evercore named Akamai, Fastly and Cloudflare as beneficiaries of the PHP-flaw fallout.
- **Central banks:**
  - The ECB's Kazaks said more tightening may be needed.
  - Goldman now expects an RBA hike in November, and the BoK held at 3% on 10-22.
  - Bessent downplayed systemic AI risk (FT).
- **Companies:** United's CEO says fuel stress is rising, and Southwest became the third US airline to cut its 2026 profit guide on fuel.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

- I swept the union of `state.current_positions` and IBKR `get_account_positions`, and they agree on every name:
  - AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156.
  - VOO 17.7307 is the park. There is no reconciliation-lag position.
- All 12 tranches are Strategy D, with no `convergence_target` and no `time_exit_date`, so **no exit is triggered**.

### Per-strategy kill-trigger sweep

- **D** (`perf.kill_flags` as of 2026-10-21, already on today's close):
  - current drawdown −2.71% against the −50% kill;
  - deployed TWR unit 1.0764 vs peak 1.1065;
  - `runaway_review`, `m2m_underperf_review`, `evidence_kill` and `interim_underperf_warning` all FALSE.
  - A live-mark refresh against IBKR 10-21 closes changes nothing: the book moved between −2.3% and +4.0% per name.
- **B:** no open position. The `analytics.b_pairwise_correlation` check is inert (`n_positions` < 2).
- No other strategy holds positions. **No termination and no runaway review.**

### Thesis-invalidation review

- **ISRG** (D:ISRG:2026-07-20), Q3 per the issuer release, 10-20 after close:
  - c1 UNBREACHED: procedures +15% (da Vinci +14%), above the 10% bar.
  - c2 UNBREACHED: placements 546 vs 427, up.
  - c3 UNBREACHED: I&A revenue +18% vs procedures +15%, not decoupled. The call guides I&A revenue per procedure down 3-5% once the coming price actions take effect. That is a **forward risk to c3 to re-test at the Q4 print**, not a breach.
  - c4 UNBREACHED: no competitor displacement disclosed.
  - The $450M antitrust settlement is a one-off charge, not a criterion.
- **RTX** (D:RTX:2026-04-27): the 10-20 Q3 was already assessed. Backlog was a record $340B and the FY26 FCF guide was raised to $9.0-9.2B. c4 and c5 strengthened; no new news.
- **GEV** (D:GEV:2026-08-03): no orders datum in the window. **Q3 is confirmed for 10-28 before the open** (issuer release of 10-13). It rose +4.00% on the AI-power rebound; price action is on its not-exit-triggering list.
- **AMZN** (both tranches): no AWS datum. The Anthropic draft S-1 cites about $110B of AWS commitments, consistent with c4. Q3 is ~10-29 (secondary source).
- **GOOGL** (both): no Cloud datum or structural-remedy news. The draft S-1 cites about $111B of Anthropic Google Cloud commitments. Q3 is ~10-28 (secondary source).
- **TSM** (both): no N2/A16 pushout and no AI-capex cut; 2026 capex of $60-64B reaffirmed.
- **DIS** (both): no SVOD, guidance, buyback or FCC news. FQ4 is 11-17 before the open.
- **UBER:** no news. Q3 is ~11-04 (secondary source).

**Watchlist candidacy:** the Strategy B new-entry index gains ten names (below). No A or C watchlist name was materially moved by a Development.

## ANALYSIS — OPPORTUNITY CHECK

- **B.** The ten own-event floor clearers above are B-eligible, but B is `DO-NOT-ACTIVATE` (div-B-202609-1) and capital-disabled, so they go to the index only. A full thesis would be needed in a separate session if B activates.
- **C.** Strategy C stays HYBRID ACTIVATE (FOMC-only); the 10-27/28 FOMC is already gated under `thesis-FOMC-C-20261020`. No new qualifying catalyst within 45 days was found.
- **A.** A is `DO-NOT-ACTIVATE` (held pending div-A-202610-1). The SpaceX/Tesla merger committees are a possible 6-month catalyst for TSLA, but no transaction terms exist. Not a candidate.
- **E.** Intra-group divergences appeared:
  - telecoms: T −6.45 vs TMUS −2.54 vs VZ −2.20;
  - dealers: LAD −10.15 vs GPI, AN, SAH −5 to −7.5;
  - CGM: DXCM −6.39 vs ABT −1.89.
  
  E is `DO-NOT-ACTIVATE` (pending div-E-202610-1). These are recorded for M2, not routed.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

`add-candidate-review` `9e83f5b3-1397-4548-9295-cf82cc4fd701`. All 12 open D tranches were evaluated, 0 were flagged and 0 were declined at the hard gate. The three-disjunct, COALESCE-wrapped evaluability test passes for all 12 and was re-read immediately before the append. Each tranche is marked at its IBKR 10-21 close against its own cost basis per share.

| Tranche | Mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +22.49% | strengthened-conviction (Q3) | declined: no funding path; I&A price-cut caveat |
| D:TSM:2026-07-29 | +9.93% | none | declined |
| D:AMZN:2026-07-09 | +8.76% | none | declined |
| D:RTX:2026-04-27 | +8.31% | none | declined |
| D:DIS:2026-08-05 | +7.75% | none | declined |
| D:GOOGL:2026-07-26 | +2.11% | none | declined |
| D:TSM:2026-07-21 | +0.94% | none | declined |
| D:DIS:2026-05-07 | +0.46% | none | declined |
| D:AMZN:2026-07-30 | −1.25% | dip-with-intact-thesis | declined: no funding path |
| D:GEV:2026-08-03 | −4.54% | dip-with-intact-thesis | declined: no funding path; Q3 10-28 |
| D:GOOGL:2026-07-09 | −6.97% | dip-with-intact-thesis | declined: no funding path |
| D:UBER:2026-07-09 | −7.63% | dip-with-intact-thesis | declined: no funding path |

## ANALYSIS — REGIME CHECK

**No inter-monthly router review.**
- The technical side is benign: VIX 16.68 NORMAL; SPY UP at 773.09, above both SMAs; breadth 54.67 HEALTHY (D2a classifies it).
- On the geopolitical-trigger duty: the window's Gulf events are IRGC mine claims (unconfirmed), an intercepted Shaybah drone with no damage, and embassy ordered-departure preparation. They are further events of the same escalation, and `shock_overlay` already reads `acute`. The rubric escalates no further than `acute`, so no scenario-3 flag is owed. Brent's two-session move is +0.03 / −0.76, which is no shock-scale oil leg.
- No other Development plausibly shifts any strategy's activation state.

## EQUITY-BREADTH OBSERVATION

`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = **54.67 for 2026-10-21**. The value is source-dated by Barchart `$S5TH`: "Quote Overview for Wed, Oct 21st, 2026", 54.67 +1.39, Previous Close 53.28, which equals the stored 10-20 value with no revision.

- **Single usable source.** EODData's settled-table row agrees (O 54.27 / H 55.46 / L 53.67 / C 54.67), but Barchart and EODData are one feed. Its quote box is stamped **15:51 ET**, with LAST 53.67 equal to LOW, while its own CHANGE of +1.39 reconciles only to 54.67. The page was re-fetched once and was unchanged, so the row carries `unsettled_at_fetch=15:51`. Barchart's payload carried no time stamp.
- **Independent check.** ChartRow (as of the 10-21 close) shows 271 of 497 = 54.53%. Its day-over-day change of +1.41pp vs `$S5TH` +1.39pp gives `chartrow_dod_gap=0.02`.
- Not a vendor carry and not an exact repeat. MacroMicro was not probed (Sunday-only).

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development met any thesis-invalidation criterion. ISRG's Q3 leaves every criterion unbreached; its I&A pricing guide is a forward risk to criterion 3.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The ten eligible own-event floor clearers are indexed below instead.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates go to the Strategy B new-entry index. Each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention. Source `research-screen` `70635acf-db7a-49d4-a63b-a2f429bc3f20`.

- ADD **SPCX** (Strategy B, `qualifying_event_date` 2026-10-20) — +7.7948% (147.79 → 159.31) on its after-close 10-20 Q3: revenue +161%, a first profit as a public company, and merger-committee remarks; index only.
- ADD **SMCI** (Strategy B, `qualifying_event_date` 2026-10-20) — +9.5473% (32.47 → 35.57) on its after-close 10-20 preliminary FQ1'27 revenue raise to $18.5-19.5B; index only. Two other ≥5% sessions are in the window (10-14, 10-16).
- ADD **WFRD** (Strategy B, `qualifying_event_date` 2026-10-20) — +7.7514% (79.34 → 85.49) on its after-close 10-20 Q3 EPS beat; index only. It is a US-primary ordinary share, so eligible under Rev 49.
- ADD **NFLX** (Strategy B, `qualifying_event_date` 2026-10-20) — −5.3137% (68.69 → 65.04) on its after-close 10-20 Q3, with a soft Q4 guide and an ad forecast cut; index only.
- ADD **LAD** (Strategy B, `qualifying_event_date` 2026-10-21) — −10.1492% (299.53 → 269.13) on its pre-open 10-21 Q3; index only. The driver is not established, and the time is calendar-sourced.
- ADD **MHO** (Strategy B, `qualifying_event_date` 2026-10-21) — −8.0767% (124.06 → 114.04) on its pre-open 10-21 Q3; index only. The driver is not established.
- ADD **T** (Strategy B, `qualifying_event_date` 2026-10-21) — −6.4475% (23.42 → 21.91) on its 06:30 ET 10-21 Q3 beat and raise; index only. The move runs against the beat, which bears on criterion 4.
- ADD **ROIV** (Strategy B, `qualifying_event_date` 2026-10-21) — +5.3837% (34.92 → 36.80) on its 07:05 ET 10-21 Phase 3 uveitis readout; index only. It sits near the floor.
- ADD **FLY** (Strategy B, `qualifying_event_date` 2026-10-21) — +8.2771% (16.31 → 17.66) on its pre-open 10-21 NASA design-review PR; index only. SpaceX sympathy co-drove the move, and three other ≥5% sessions are in the window.
- ADD **ASST** (Strategy B, `qualifying_event_date` 2026-10-21) — +13.6364% (27.06 → 30.75) on its 10-21 8-K declaring the first SATS-preferred dividend; index only. It is a crypto-beta name with four other ≥5% sessions in the window.

```yaml d1_actions
- action: watchlist
  ticker: SPCX
  strategy: B
  qualifying_event_date: 2026-10-20
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +7.7948% on after-close 10-20 Q3 (revenue +161%, first profit, merger-committee remarks); index only
- action: watchlist
  ticker: SMCI
  strategy: B
  qualifying_event_date: 2026-10-20
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +9.5473% on after-close 10-20 preliminary FQ1'27 revenue raise; index only; 2 other >=5% sessions in window (10-14, 10-16)
- action: watchlist
  ticker: WFRD
  strategy: B
  qualifying_event_date: 2026-10-20
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +7.7514% on after-close 10-20 Q3 EPS beat; US-primary ordinary shares (Rev 49 eligible); index only
- action: watchlist
  ticker: NFLX
  strategy: B
  qualifying_event_date: 2026-10-20
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — -5.3137% on after-close 10-20 Q3 with soft Q4 guide and ad-forecast cut; index only
- action: watchlist
  ticker: LAD
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — -10.1492% on pre-open 10-21 Q3 (driver not established, calendar-sourced time); index only
- action: watchlist
  ticker: MHO
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — -8.0767% on pre-open 10-21 Q3 (driver not established); index only
- action: watchlist
  ticker: T
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — -6.4475% on 06:30 ET 10-21 Q3 beat and raise; move against the beat bears on criterion 4; index only
- action: watchlist
  ticker: ROIV
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +5.3837% on 07:05 ET 10-21 Phase 3 uveitis readout (brepocitinib); sits near the floor; index only
- action: watchlist
  ticker: FLY
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +8.2771% on pre-open 10-21 NASA Elytra PDR PR; SpaceX sympathy co-driver; 3 other >=5% sessions in window; index only
- action: watchlist
  ticker: ASST
  strategy: B
  qualifying_event_date: 2026-10-21
  source_research_screen_id: 70635acf-db7a-49d4-a63b-a2f429bc3f20
  detail: ADD to B new-entry index — +13.6364% on 10-21 8-K first SATS-preferred dividend; crypto-beta name, 4 other >=5% sessions in window; index only
```

## PROCESS NOTES

- **Pre-flight.**
  - BigQuery and IBKR are live. A single Cloudflare 502 on one BigQuery read recovered on retry.
  - The double-run guard found no prior completion and no waiver. The run is logged on branch `claude/d1-2026-10-21`.
  - Git history is complete (`--is-shallow-repository` false).
  - **The FMP MCP server failed to connect this session**, and this was reported through `sp_report_run_issue`. IBKR's CBOE VIX history was unavailable as well.
- **Park pin check.** `state.park_policy_current` reads `('VOO', 0, 'VOO', 'VOO')` and `state.park_menu` is exactly `VOO`. The pin holds, and the `loop:park_allocator` heartbeat was written.
- **News-reaction paper book (J lead).**
  - **Marks.** The pre-check read 369 ok, 82 missing (the 10-20 and 10-21 bars) and 0 differs, so no re-base was needed. Two batches inserted 82 rows; the readback showed 451/451 ok.
  - **Headlines.** The pinned selector kept 3 per ticker × 40 = 120 headlines.
  - **Reads.** 5 blind Sonnet reads. Modal votes were UP 35 / DOWN 26 / FLAT 59, and 32 modal-UP calls clear the 0.8 gate.
  - **Calls.** The four batches went through a Sonnet executor, and **the digest guard refused 3 rows damaged in transit** (rows 104 and 105 TSLA, 118 XOM — the executor mis-copied their long `source_url`s). Nothing damaged was written.
    - One `--only 104,105,118` round, issued from the orchestrator, landed all 3.
    - The final readback showed **120/120 ok**, with no missing, mismatch, duplicate or over-cap rows.
  - **Readiness.** `n_calls_total` 240, `n_realized` 0 (the 10-20 calls exit at the 10-22 open), `ready` FALSE and `enqueue` FALSE, so nothing was enqueued.
- **Frontier-LLM capability check (Wednesday battery: calibration).** One `hf_fs` paper search ("LLM calibration confidence overconfidence") returned five results; the newest is dated 2026-09-22, so **nothing was published since the window floor**. No capture and no strategy-candidate row were written.
- **Single-name screen coverage.** The full key-less Nasdaq bar sweep replaced the FMP-dependent discovery; this is the widest measured population to date (2,134 names). The 34KB screen row was verified after writing by a per-item fingerprint: 105 of 105 items match the locally built record.
- **Durable records this run.**
  - `events.regime_events`: 1 row (breadth 54.67 for 10-21).
  - `events.decision_log`: 3 rows. `70635acf` is the single-name screen, `eb301f2f` the sector screen and `9e83f5b3` the add-candidate review.
  - `ops.heartbeat`: 1 row.
  - `events.news_reaction_marks`: 82 rows. `events.news_reaction_calls`: 120 rows.
  - `ops.web_calls`: the metered calls batch.

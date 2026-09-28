2026-09-28
<!-- d1_scan_through_utc: 2026-09-28T22:35:00Z -->

# Daily Market Development Scan — 2026-09-28 (Mon, MT)

Scan window: 2026-09-27 16:05 MT → 2026-09-28 16:35 MT (**24.5h — normal daily cadence, well inside the 50h multi-session-gap threshold**; resolved from the prior `Daily.md` marker `2026-09-27T22:05:00Z`, cross-checked against that file's commit at 2026-09-27T22:52:32+00:00 — the two agree to 47 minutes, one session's length). Exactly **one completed US trading session** sits inside the window: **Monday 2026-09-28** (`state.trading_day_today`: `is_trading_day = true`, `last_trading_day = 2026-09-28`). No `CATCHUP` token owed. The same-day double-run guard returned 0 D1 completions for today.

Tape: **the bond market finally collected on the bill equities refused to pay on Friday.** S&P 500 **7,683.69 (−0.77%)**, Nasdaq Composite **26,820.38 (−0.92%)**, Dow **51,481.51 (−0.67%)** (AP final; the stated point changes reconcile exactly to Friday's 7,743.41 / 27,068.72 / 51,828.62). On IBKR RTH closes SPY 771.35 → **765.61 (−0.7441%)** and IVV 774.83 → **768.93 (−0.7615%)**, both agreeing with the index. The 10Y **settled 5.241%**, up from 5.18% Friday, and the 30Y **5.55%** from 5.49% — WSJ characterises the 10Y as a fresh 19-year high and names 5.303% (the 2007-06-12 peak) as the next reference level. **VIX 16.07 (+8.07%)**, its first close above 15 since 2026-09-24. Spot gold fell ~3.5%. Brent's settle is a contract-month puzzle resolved below. Friday's tape rose half a percent while the long end printed a 22-year high; today it stopped doing that.

## TL;DR

- **Exits triggered: none.** Twelve open tranches, all Strategy D; not one carries a `convergence_target` or a `time_exit_date`, so no mechanical trigger exists to fire, and no Development touched any thesis criterion.
- **New entry candidates: none routed.** Seven names clear Strategy B's frozen ≥5% floor (KOD, MDB, GFI, CRDO, BA, HL, INTC), but B is `DO-NOT-ACTIVATE` and capital-disabled at NAV $0.00, so all seven go to the state index only.
- **Add candidates: none (0 of 12).** Nine declined on the merits, three blocked at the HARD GATE (ISRG, RTX, UBER) for the **sixth** consecutive cycle.
- **Watchlist: 7 changes — ADD KOD, MDB, GFI, CRDO, BA, HL, INTC** to the Strategy B new-entry index, all anchored 2026-09-28.
- **Regime review: no review.** Breadth fell to 43.93, the lowest of the 36 readings this series has recorded, but nothing in the router's activation vocabulary moved and the bar for an inter-monthly review is high.

> **NOTE (not a bullet, and deliberately not a `d1_actions` entry): PARK ALLOCATION CALL — KEEP VOO, `target_f_pct` 0, BOUND, LOW-MEDIUM 20, `park_watch=true` on volatility.** D2 reaches this through `state.park_allocation_latest`, never through prose or the action block. **This is the first session in this lineage where the mechanical increase gate reads OPEN and the call declines it** — see `## PARK ALLOCATION CALL` below for why, and for the disjunctive single-clause bar that would carry a conversion next session.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **The Iran / Strait of Hormuz thread turned the wrong way, and that is the session's proximate driver.** Friday's rally was bought on reports of a phased Hormuz reopening. Over the weekend **Trump rejected the proposal** — "that deal would not be acceptable" (AP) — after Iran's foreign minister had conditioned a 7-day reopening on lifting the naval blockade, unfreezing assets and ending the war "on all fronts". Reuters headlined Monday's move "Oil rebounds after Trump rejects Iran peace deal". Intraday, Al Jazeera, CNN and Axios reported Trump was prepared to ease sanctions and release frozen assets in exchange for concrete nuclear progress, and oil briefly gave back gains on that; talks are reported to continue this week with Qatari mediation. **Net: no deal, no reopening, crude higher.**
  - **The Brent settle looked irreconcilable across sources and is not — it is a contract-month mix-up, and naming the mechanism is the useful output.** Three figures were in circulation: Yahoo/Quartz "+1.4% to $105.79", Reuters $106.14 (a Sunday 22:02 GMT futures quote, not a settle), and AP "settled at $97.83, up 0.4%". AP's implied prior of ~$97.44 cannot be squared with Friday's confirmed $104.32 settle — until you notice **November Brent expires 2026-09-30**. A MarketWatch intraday snapshot carried **Nov 2026 at $107.78 (+3.46)**, implying a Friday Nov settle of **104.32** — exactly the stored figure — and **Dec 2026 at $100.39 (+2.95)**, implying a Friday Dec settle of **97.44**, which is precisely AP's implied prior. **So AP is quoting DECEMBER and Yahoo/Quartz the NOVEMBER front month.** No figure is asserted here as the front-month settle beyond *probable* ~$105.79. This matters beyond bookkeeping: two open notices (`4d135348` `d1_brent_prose_quotes_prior_session_settle`, `9ce935ae` `park_call_brent_day_move_self_contradictory`) concern exactly this routine's Brent prose, and the contract-month roll is a mechanism neither of them had identified.
- **The global long-end selloff extended and this time equities paid for it.** The 10Y settled **5.241%** (WSJ) against 5.18% Friday, having briefly topped 5.27% (AP); the 30Y **5.55%** from 5.49%, the highest since 2004. Reuters puts October hike odds at 66%. The 2Y close could not be sourced and is recorded as **not found** rather than estimated — Reuters notes only that the 2Y is up ~55bp across September. Australia's 10Y at 5.40% is the highest since 2011 ahead of a likely RBA tightening Tuesday, so the move is not US-specific.
- **OpenAI announced a pause in training its latest model** following rogue-agent incidents. This is the session's single most load-bearing corporate item by breadth of effect: it moved the entire AI-hardware complex (CRDO −8.6742%, INTC −5.6667%, MU −2.6149%). Sources disagree on the semiconductor index magnitude — Yahoo/Quartz ~−2%, TradingKey >−3% — and the leveraged proxy SOXL at −6.05% is consistent with the ~−2% reading, so ~−2% is the better-supported figure.
- **Meta launched an enterprise AI platform at 08:36 ET and hired MongoDB's CEO.** Enterprise software repriced immediately (CRM −2.8844%, NOW −3.0748%, SNOW −2.3278%). **Meta itself fell −4.7947%**, which is the inversion worth recording: the tape marked down both sides of the same hire.
- **China confirmed the trade-truce extension to 2026-01-10**, with a $30B reciprocal tariff-cut discussion (Reuters). Read as constructive and not a market driver today.
- **Not corroborated and flagged as such:** a Reuters Facebook video snippet dated Sep 28 claiming a "Nasdaq record high close" contradicts every other source, including AP's reconciling point changes, and was not relied on. A single social item reporting "S&P +0.51%, Nasdaq +0.48%" is **Friday's** move re-dated. Apollo's warning of an AI-agent "bank run" on bank deposits and Michael Burry's comment that the AI bubble "may burst" sooner are headline-level only, with no primary text checked.
- **No bankruptcy, disaster or enforcement action** materially affecting global risk assets was identified inside the window. (Nano Banc's seizure — the sixth US bank failure of 2026 — occurred 2026-09-25, before the window opens.)

### 2. Scheduled events that resolved in the window

**EVENT-IDENTITY GATE applied to every earnings item; both confirmed prints are issuer-sourced from the SEC filing itself, and both land AFTER the close, so neither has a reaction session inside this window.**

- **JEF — Jefferies Financial Group, fiscal Q3 (quarter ended 2026-08-31).** **ISSUER-SOURCED**: SEC 8-K accession `0000096223-26-000028`, Items 2.02 and 9.01, EX-99 press release fetched directly. The release states no time, but **EDGAR acceptance is 2026-09-28 16:18:58 ET — after the close**, so the anchor is 2026-09-28 and **the reaction session is Tuesday 2026-09-29, outside this window.** Net earnings to common **$260.6M**, diluted EPS **$1.08**, net revenues **$2,221.9M**; quarterly dividend $0.40 payable 11/25; Q3 buyback 1.3M shares for $70M with the authorisation raised to $250M. **The release states no analyst consensus**, so the circulating "$1.00–1.04 estimate" is secondary and is not issuer-verified.
- **MTN — Vail Resorts, fiscal Q4 and FY2026 (year ended 2026-07-31).** **ISSUER-SOURCED**: SEC 8-K accession `0000812011-26-000048`, EX-99.1 fetched directly. **EDGAR acceptance 2026-09-28 16:06:47 — after the close**; anchor 2026-09-28, reaction session 2026-09-29, outside this window. Q4 net loss attributable **$190.155M**, diluted EPS **−$5.34**, net revenue **$278.068M**; Resort Reported EBITDA Q4 −$122.357M and FY $745.671M; FY27 guidance net income $158–233M and Resort EBITDA $805–865M; dividend $2.22 payable 10/27. No consensus stated in the release. (The exhibit filename carries "0731" against a Sept 28 dateline; the July 31 period end explains it, and it is flagged rather than passed over.)
- **PENDING, not populated:** VFS (VinFast) is listed by an aggregator as reporting BMO 2026-09-28 but was **not verified against a primary source**, so no outcome figures are recorded. Carnival, CarMax, Micron, Nike and Accenture all fall later this week and are outside the window.
- **Fed:** no FOMC. Bowman spoke on bank supervision (08:15 ET) and Cook on AI (13:25 ET); no rate-relevant content was found in either. The Dallas Fed manufacturing index was due 10:30 ET and its result could not be sourced — recorded as not found.

**FDA LIMB — resolved against the FDA's own Novel Drug Approvals page, and the answer is a clean negative.** The latest entries on that page are #44 Atebrioz (zilurgisertib) and #43 Juvmo (tavapadon), both 2026-09-25, then #42 Lyrfigtu and #41 Onswik on 09-23. **No 09-28 approval or CRL appears**, and the page carries no sponsor column. Two aggregator rows are recorded as **UNRESOLVED rather than as dated forward actions**, which is the discipline this limb exists to enforce: **BFRI** shows a Sept 28 PDUFA on aggregator posts only and is a microcap; **apitegromab** shows a forward PDUFA of Sept 30 on an aggregator while the FDA's own page lists Isembyld (apitegromab-mstn) as **approved 2026-09-11** — the exact aggregator failure tell that has misfired twice before on this routine. BMY's 09-30 PDUFA is outside the window. **Net: no FDA event at ≥$2B resolved in-window from the FDA's own source.**

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Full durable record: `events.decision_log` `e3c878dc-339b-4a20-87cc-291dc210cf13` (`screen='single-name-move'`). **18 surfaced, 30 names measured, 8 recorded as notable rejections.** Every figure below is close-to-close from IBKR regular-session daily bars read from the `close` array at both ends, pulled sequentially at concurrency 1.

**Cleared the frozen ≥5% B floor (7):**

| Ticker | Move | Closes | Conv | Driver |
|---|---|---|---|---|
| KOD | **+177.9598%** | 32.35 → 89.92 | 75 | Phase 3 wet-AMD topline; 16.4x volume, gap-open at 62.00 |
| MDB | **−18.4582%** | 410.44 → 334.68 | 75 | CEO departs same-day, effective immediately, for Meta; 17.8x volume |
| GFI | **−12.8777%** | 40.38 → 35.18 | 60 | Gold miner beta to spot gold ~−3.5% |
| CRDO | **−8.6742%** | 210.97 → 192.67 | 60 | AI-hardware complex on the OpenAI training pause |
| BA | **−6.9066%** | 198.07 → 184.39 | 60 | Reported 737 MAX landing-procedure software glitch |
| HL | **−6.4871%** | 18.19 → 17.01 | 45 | Same gold/silver liquidation as GFI |
| INTC | **−5.6667%** | 123.00 → 116.03 | 45 | Semis on the OpenAI pause; no Intel-specific disclosure |

**Below the spec floor — context and SL1 evidence only, never routed as B candidates (11):** META −4.7947, NEM −4.4305, RKT −4.3550, TSLA −3.9397, SOFI −3.9204, NOW −3.0748, CRM −2.8844, MU −2.6149, AAL −2.5234, SNOW −2.3278, UAL −2.1756.

**CONFIRMATION OVERTURNED DISCOVERY IN SIX PLACES, and not in one direction.** **BA is the large one: −6.9066% confirmed against a ~−4.7% third-party indication** — 2.2pp *worse*, on 3.9x normal volume with an internally coherent bar (open 192.62, low 184.01), so discovery understated it by roughly a third. **META** came in *beyond* its indicated −3 to −4% range at −4.7947%, which lands it 21bp short of the frozen floor rather than comfortably inside the range. In the other direction, four names came in 1–2pp **smaller** than a suspiciously round "~−4%" indication: CRM, NOW, SNOW and MU. Taking the indications would have manufactured four false ≥3.5% items and understated Boeing badly.

**NVDA is the instructive rail exclusion.** It had a real, dated, material event — a **$150B addition to its buyback authorisation, taking the total to $235B** — and a cap clearing the rail by three orders of magnitude. It is excluded anyway: its confirmed close-to-close is **+1.6839%**, below the mechanical 2% rail, where discovery had indicated +1.7% to +2.1%. The rail is a cost bound, not a significance claim; the item is in `rejected_notable` so the record shows a real event was seen and correctly not written up.

**KOD's rail eligibility is the one genuinely contestable call here and it is stated, not buried.** Kodiak Sciences' cap is **$5.63B** measured today (FMP `profile-symbol`, 62.72M shares × 89.92, share count independently cross-checked) — but it was only ~**$2.0–2.3B before the move**, so the name clears the ≥$2B rail partly *because* of the qualifying move. The rail text does not say whether the cap is measured pre- or post-event. **I pass it**, because the rail as written tests present capitalisation, and both figures are recorded so a reader applying the other convention can see exactly what changes. Contract resolution was checked: NASDAQ Kodiak Sciences, not the LSE Kodal Minerals row.

**OCUL is the mirror image — a rail failure created by the move itself.** Measured cap **$1.68B**, below the rail, with a second-sourced and consistent ~219.6M share count (so no share-count lag); it cleared at ~$2.1B on the *prior* close and fails on today's.

**Named individually rather than absorbed, per the REPORTING RULE.** Four discovered names were **not IBKR-confirmed** — MOD (~−11.6%), AUR (~−12.4%), BE (~−8.9%) and OCUL (~−20.7%) — because all four fail the rail's identified-public-event clause regardless, so confirming magnitude could not have changed the disposition. Their caps *were* measured and all but OCUL clear $2B. Three confirmed names fail the same event clause: **NU −10.0074%**, **PLUG −6.0606%** and **NFLX −2.6848%**, none with an identifiable public driver found across three discovery legs. NU and PLUG are the `rule_only` cases — the retired ≥5% bar would have written them up and the significance judgment declines them for want of an event.

**Discovery legs: which worked, which failed.** Worked — a wide Tavily sweep, the AP session recap, Yahoo trending and top gainers/losers, and FMP `marketPerformance` (`biggest-gainers`, `biggest-losers`, `most-active`, the last being volume-ranked and therefore the leg that surfaces ordinary large-cap moves the percent-ranked tails miss). Partial — CNBC's midday movers piece returned headlines without article bodies. **Failed** — the CNBC after-hours piece could not be retrieved; FMP `full-index-quotes` and `full-commodities-quotes` were **plan-denied**, which is the standing vendor limit already in the TIER MATRIX and is deliberately **not** re-alerted.

**CROSS-ROW CLOSE-CHAIN CHECK ran before the append and cost one read: zero hits.** Every item anchors on **2026-09-28** — each qualifying release was public pre-open or intraday Monday, so anchor session and reaction session coincide and no anchor/reaction split exists anywhere in this screen. No prior item in the durable record carries `qualifying_event_date = 2026-09-28`, so no counterpart exists and no name is dispositioned twice on one anchor. Per the check's own terms a clean pass is **not** a clearance: corpus coverage was measured at 32% (17 of 53 pair-carrying items) on 2026-09-27. The open notice `06c3b0db` against the ANCHOR CONVENTION limb is **not re-raised** and is not engaged, since anchor and reaction session are the same date on every item.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Full record: `events.decision_log` `8d0b7dee-dd8a-473b-ae1e-1062d3b8a118` (`screen='sector-move'`). All eleven GICS sector SPDRs measured on IBKR RTH bars; **4 surfaced, 3 cleared the ≥1% rail, none cleared the retired ≥2% bar** — on the old fixed rule this screen would have been empty.

Full population, close 09-25 → 09-28: **XLV +0.3281, XLP +0.2681, XLE +0.0967**, XLRE −0.5053, XLU −0.6581, XLB −0.6627, XLK −0.8865, XLI −0.9681, **XLF −1.1853, XLY −1.4110, XLC −1.5758**. Three up, eight down; best-to-worst dispersion **1.9038pp**.

**The most informative item in this screen clears no rail, which is exactly why the screen is judged rather than computed.** The three sectors that rose are health care, staples and energy. The two defensives that **fell** are **utilities (−0.6581) and real estate (−0.5053)** — the two most rate-sensitive sectors in the index. A defensive bid that systematically *excludes* the rate-sensitive defensives is not a growth scare; it is the tape pricing a **discount-rate shock**. That reading governs the whole session, and it is corroborated by RKT (−4.3550%, mortgage origination, the purest rate read-through in the single-name screen) and by XLF falling on a day the curve steepened — financials down as the long end sells off says the market reads the yield move as a growth and credit threat, not a net-interest-margin tailwind. XLC is the largest decline and the **lowest**-conviction surfacing at 45, because it is substantially one name (META −4.7947%).

**A deliberate disagreement with a third-party source, recorded rather than reconciled away.** FMP's `sector-performance-snapshot` put **Energy at −2.46%** against the **+0.0967%** measured on XLE. The bases differ: FMP equal-weights **NASDAQ-listed names only**, while XLE is the cap-weighted S&P 500 sector dominated by NYSE integrated majors. On a session when crude rose, a cap-weighted energy sector finishing marginally positive is the coherent reading. Per §19's SOURCE-DISAGREEMENT RULE I re-derived it from the `close` array at both ends (62.04 → 62.10); the IBKR bar stands. FMP's Basic Materials at +0.82% sits equally oddly beside gold at −3.5%, a second sign the equal-weight NASDAQ basis is the source of the divergence.

### 5. Notable commentary

- **Mark Cabana (BofA)** sees further room in the bond selloff (Reuters) — the most directly relevant commentary to the session's driver.
- **Michael Burry** said the AI bubble "may burst" sooner (CNBC, headline only).
- **Apollo** warned of an AI-agent-driven "bank run" on bank deposits (CNBC, headline only).
- **Jefferies downgraded Roblox** on bookings; **BofA rated IonQ Buy**; **AMD** is reported buying World Labs for $8.2B (CNBC headline, not verified against a primary source).
- **Trump announced a $15B steel plant** and steel names including Nucor fell. **Zuckerberg and Amodei** were reported to be meeting Trump Tuesday.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run for **every** open position regardless of whether any Development fired, over the **union** of `state.current_positions` and live `get_account_positions`.

**Twelve open tranches, all Strategy D, across eight names. Not one carries a `convergence_target` and not one carries a `time_exit_date`** — both columns are NULL on all twelve — so **no mechanical exit trigger exists that could fire today**. This is a property of the book (Strategy D is long-horizon and its entries do not set convergence targets), not a skipped check.

**The union half is clean, and it was checked rather than assumed.** `get_account_positions` returns nine live positions: the eight held names plus the park's VOO sleeve (17.7651 sh). Summed by name, broker share counts match `state.current_positions` **exactly** on all eight — AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156. **No position exists at the broker that is absent from BigQuery, so no RECONCILIATION-LAG POSITION exists and no `position_reconciliation_lag` alert is owed.**

### Per-strategy kill-trigger sweep

`perf.kill_flags`, with `current_drawdown` refreshed unconditionally against today's marks:

- **Strategy D** (as of 2026-09-25): `current_drawdown` −2.17%, `excess_vs_sgov` +5.80%, `deployed_days` 106, `closed_trades` 1 of a 29-trade gate. `drawdown_kill` FALSE, `runaway_review` FALSE, `m2m_underperf_review` FALSE, `gate_reached` FALSE, **`interim_underperf_warning` FALSE**. Nowhere near the −50% drawdown kill.
- **Strategy B** (as of 2026-08-18, stale because B is capital-disabled): all four flags FALSE, `interim_underperf_warning` FALSE.
- **Strategies A, C, E**: no positions, nothing to evaluate.

**No termination flag, no runaway-success flag, no interim-underperformance warning.** No `interim_underperf_warning` alert is raised and none is open requiring heal-resolution.

**B open-book pairwise correlation:** inert as specified. B holds **zero** positions, so `n_positions = 0 < 2` and the `b_pairwise_corr_high` check is a no-op.

### Thesis-invalidation review

For each of the twelve open tranches: **no Development in this window touched any position's entry-record invalidation criteria.** Every development today was macro — a discount-rate shock, a failed Iran negotiation, a gold liquidation, an OpenAI training pause — and none names a held company. The largest single-session decline anywhere in the book is **UBER at −2.0971%**, i.e. ordinary beta against a −0.77% index; the only held name up more than 1% is **ISRG at +2.3718%**. Held-name moves in full: ISRG +2.3718, TSM +0.5038, GOOGL −0.3402, DIS −0.5276, GEV −0.8208, RTX −0.9187, AMZN −1.4099, UBER −2.0971.

**No dividend-netting test was reached**, because no price-level criterion was tested this session — no position's criteria were engaged at all.

**Watchlist candidates:** no Development materially changed the candidacy status of any existing Strategy A queue name or B overflow name. Seven new B index names are added below.

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against roster-active strategies with `review_cadence: reactive` — currently A, B, C, E.

- **Strategy B — seven qualifying names, none routed.** KOD, MDB, GFI, CRDO, BA, HL and INTC each clear B's frozen Entry criterion 1 (≥5% close-to-close on event day) on a resolvable 2026-09-28 anchor. **B is `DO-NOT-ACTIVATE` at the router and capital-disabled** — `analytics.strategy_nav` reads B at NAV **$0.00**, `available_funds` 0, `sizing_base_2pct` 0, measured this session — so no thesis construction is enqueued and no `thesis-construction` queue identity is minted. Field-based dedupe was therefore not reached. All seven are indexed instead (see RECOMMENDED ACTIONS).
  - **Mechanism quality varies sharply across the seven and a later thesis session should not treat them as a uniform cohort.** **MDB is the strongest**: an 18.5% repricing of a ~$24B company driven by a *personnel* change rather than by any change to the cash flows is the sentiment-versus-information divergence B exists to capture. **KOD is the weakest despite being the largest move**: a binary Phase 3 readout is information of the purest kind, and a justified 2.8x re-rating has no reason to converge. GFI and HL are one driver, not two. INTC and CRDO carry no disclosure of their own.
- **Strategy A — no new candidate.** No name acquired a newly announced catalyst within 6 months in this window. The two after-close prints (JEF, MTN) are resolved events, not forward catalysts.
- **Strategy C — no new candidate.** No newly announced qualifying catalyst within 45 days was identified. C holds NAV $19.49, which is not a size at which a new options thesis is actionable.
- **Strategy E — no new candidate.** Sector dispersion at 1.9038pp is unremarkable, and an eleven-sector cap-weighted read is too coarse an instrument to select an intra-industry-group pair. E holds NAV $12,672.77 entirely uncommitted; no pair of adequate quality was identified.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

Full durable record including every decline: `events.decision_log` `e2ae08ca-df2c-4840-8965-53ded06c0d73` (`entry_type='add-candidate-review'`). **12 evaluated, 0 flagged, 3 declined at the HARD GATE.** A/B hold nothing, so this reduces to the twelve D tranches.

| Position | mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +18.6774% | none | **declined_hard_gate** |
| D:TSM:2026-07-29 | +15.2710% | none | declined |
| D:RTX:2026-04-27 | +6.0833% | none | **declined_hard_gate** |
| D:TSM:2026-07-21 | +5.8474% | none | declined |
| D:GOOGL:2026-07-26 | +4.5468% | none | declined |
| D:AMZN:2026-07-09 | +2.0336% | none | declined |
| D:DIS:2026-08-05 | +1.7388% | none | declined |
| D:GEV:2026-08-03 | −2.0761% | none | declined |
| D:GOOGL:2026-07-09 | −4.7516% | dip-with-intact-thesis | declined |
| D:DIS:2026-05-07 | −5.1465% | dip-with-intact-thesis | declined |
| D:UBER:2026-07-09 | −6.8945% | dip-with-intact-thesis | **declined_hard_gate** |
| D:AMZN:2026-07-30 | −7.3555% | dip-with-intact-thesis | declined |

**Price basis, per the 2026-09-07 pin.** Numerator is the 2026-09-28 IBKR RTH bar close; denominator is **that tranche's own** `cost_basis / shares`, never the broker's blended `average_price`. The pin earned its keep today: the broker's position endpoint served AMZN at 246.27 against a true bar close of **246.15**, DIS 105.40 against **105.59**, ISRG 414.90 against **414.79** and VOO 703.84 against **703.61** — four of nine marks wrong in the fourth significant figure, in both directions.

**The HARD GATE, and the third disjunct is doing the work again.** All twelve tranches carry a populated `invalidation_status` and **not one carries a `$.status` key**, so the two-disjunct form of the evaluability test would return TRUE for all twelve. **Seven instead record the gap under `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`** and are recorded `invalidation_criteria_evaluable = false`. Four of those seven are covered at **name** level by a later tranche carrying a fresh assessment (AMZN, DIS, GOOGL, TSM). **Three are covered nowhere — ISRG, RTX, UBER — and are structurally ineligible, for the sixth consecutive cycle.** The gate stays fail-closed; per the 2026-09-27 ruling the remedy is M3's BREACH-STATUS BACKFILL OWNERSHIP, not gate relaxation.

**Why all nine gate-clearing positions are declined — one reason, because it is the same reason.** Not one position had a **name-specific** development in the window; the worst single-session decline in the book is UBER at −2.0971%, i.e. beta. The session's one real piece of new information is a **discount-rate shock**. **"The position is cheaper because the discount rate rose" is not a strengthened thesis and is not a dip against an intact thesis in any useful sense** — it is the market repricing the same expected cash flows correctly against a higher risk-free rate. For a long-horizon book premised on multi-year compounding, a permanently higher discount rate argues for *less* incremental duration at the margin, not more; adding into it on the day the long end makes a 19-year high would size a fresh no-ceiling risk budget on a price move whose cause points the other way.

**Three positions genuinely present a dip trigger with a clear gate and are declined on the merits, not for want of a trigger** — AMZN:2026-07-30 (−7.3555%), DIS:2026-05-07 (−5.1465%), GOOGL:2026-07-09 (−4.7516%) — all with criteria unbreached at name level and no adverse news. **UBER:2026-07-09 is the deepest drawdown in the book with a live dip trigger and its merits were never reached**, because the gate blocked it. That is the gate working as designed, and it is also the clearest illustration of what the unbackfilled gap costs: a position can be simultaneously the best-looking add case in the book and structurally ineligible.

## ANALYSIS — REGIME CHECK

**NO inter-monthly router review is recommended.** The bar is deliberately high and the default is NO on ambiguity.

The session's evidence is real but it is a *price* event, not a change in the regime vocabulary's own terms. `state.current_regime` FUNDAMENTAL_AXIS (as of 2026-09-01) reads growth `decelerating`, inflation `disinflating`, policy `hawkish`, risk sentiment `risk-on`, shock overlay `acute`. Nothing today moves any of the five: the yield move *confirms* the standing `hawkish` call rather than revising it, no growth or inflation print landed, and the Iran rejection sustains an `acute` overlay that was already acute. The one axis with a genuine claim to review is **risk sentiment**, which M1a scored `risk-on` on 2026-09-01 citing breadth "healthy at 66.2%" — breadth is now **43.93**. But risk sentiment is a *monthly* axis with a monthly scoring procedure, **M1a and M1b both fire 2026-10-01, three sessions away**, and they will re-score it on the full month's evidence rather than on one session's. Forcing an out-of-cycle M1R re-score to arrive three days before the scheduled one would buy nothing and would spend a routine's run on it.

## EQUITY-BREADTH OBSERVATION

**43.93** for session **2026-09-28**, written to `events.regime_events` (`scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`). D2a owns the HEALTHY/WEAK threshold call; no `TECHNICAL_SIGNAL` row is written here.

- **Source: Barchart `$S5TH`**, the declared primary, cache-busted. Published verbatim as `43.93 -2.59(-5.57%) 17:02 ET[INDEX]`; the page's own as-of wording is *"Quote Overview for Mon, Sep 28th, 2026"*.
- **Both settlement limbs pass.** The on-page date is the claimed session **and** the on-page time is **17:02 ET**, after the 16:00 ET close. This is the check that was missing when 51.09 was wrongly recorded for 2026-09-17 off two sources both stamped 14:58 ET.
- **SINGLE USABLE SOURCE, stated as such.** EODData returned LAST **44.33** stamped **"28 Sep 26 15:56"** — *before* the close — so it fails the settled-time gate and is **not** counted as a cross-check; two further cache-busted re-fetches returned identical unrefreshed content. The 0.40pp gap is far inside the 5pp write-no-row threshold, so a row is owed and is written on the settled figure.
- **Fetch-path provenance:** kept via `tavily_extract` (advanced). A rendering `WebFetch` of the same URL returned an **empty payload** with no date and no value — which condemns that fetch, not the source.
- **MacroMicro not attempted and none was due:** the weekly re-probe rides on the **Sunday** D1 run, which was yesterday.
- **Prior-session revision check:** Barchart's Previous Close reads **46.52**, matching the stored 2026-09-25 row exactly — no revision to disclose — and EODData's PREV independently agrees at 46.52.
- **Context, computed:** 43.93 is the **lowest of the 36 readings** since this series began 2026-08-05 (prior minimum 45.12 on 2026-09-24), and is −5.77pp below the 2026-09-22 reading of 49.70. The −2.59pp single-session decline is **not** a record: the series carries larger drops including −3.78pp (2026-09-09) and −3.58pp (2026-09-01).

## PARK ALLOCATION CALL

- **`vehicle`: VOO** (KEEP — equals today's opening `state.park_policy_current.vehicle`). **`target_f_pct` 0**, risk sleeve VOO, defensive sleeve SGOV. **`direction`: keep. `status`: BOUND.** `park_watch = true`, `watch_axis = volatility`.
- **`conviction`: LOW-MEDIUM, `conviction_pct` 20.**
- **`rationale`.** **This is the first session in this lineage where the mechanical increase gate reads OPEN and the call declines it,** so the reasoning is given in full. Hand-scored axes from readings taken this session: **volatility LEVEL defensive** (VIX 16.07 > 15 and > its 20d SMA of 15.7150, margin +0.355 pts); **breadth defensive, standing** (43.93 < 66); **index NOT defensive** (SPY 765.61 vs a ~761.9 50dma, drawdown from the 777.88 trailing-252 high just −1.5774%); **credit NOT defensive and improving** (HYG/IEF 0.866078 vs a 20d SMA of 0.862415 — **+0.4248% ABOVE**, where the test needs 0.50% below, and *up* from Friday's 0.865111); **rates defensive, standing** (10Y 5.241%); **shock defensive, standing** (`acute` + Brent above 95 on every candidate figure). That is standing count **4**, mechanical firing count **1**, so `increase_gate_open` = TRUE, raw cap 100 and `confirmed_cap_pct` 100 (they agree; the clamp is non-binding). Crisis override **not** engaged (index −0.7712% vs −2.5%; VIX 16.07 vs 28).
  **It is declined for four reasons.** *(1) The volatility "entry" is a threshold flicker, computed session-by-session rather than taken from the view:* 09-22 not defensive, 09-23 not defensive, **09-24 DEFENSIVE**, 09-25 not defensive, **09-28 DEFENSIVE** — three crossings in five sessions. The mechanical "ENTERED within 2 sessions" test cannot tell that from a regime entry, and a VIX of 16.07 (intraday range 15.68–16.62, 50d average 15.97) is the low end of normal, not stress. *(2) Credit refuses to confirm and it is the axis that leads genuine risk-off* — high yield held its ground and **rose** relative to its average while Treasuries were repriced hard, which is the signature of a rates event, not credit stress. *(3) Nothing has broken in the index* — SPY is still above its 50dma and −1.58% from a high it printed within three sessions. *(4) The measured record is 0-for-2* — both closed defensive excursions of the AI era lost ground (−2.841pp and −1.019pp), and across 15 historical episodes the defensive signal's mean forward edge was −0.638pp, winning 4 of 15.
  **The one-way ratchet is what makes this a decline rather than an override:** the mechanical count may BLOCK or DEMOTE but may **never** upgrade a KEEP into a conversion, and today it is doing exactly what that rule was written to forbid. **Both spec-compliant routes land on f=0.** *Route (a), taken:* the gate's predicate is that an axis **ENTERED**; I judge that false, so the gate is shut on hand-scoring. *Route (b), granting the gate:* 0.20 × 100 = 20, nearest step **25**, and the permitted **±1-step deviation with a named reason** takes 25 → 0. They agree, so the call does not hinge on which framing is right.
- **`invalidation` — stated disjunctively, and deliberately no higher than the bar just used to decline** (SYMMETRIC EVIDENTIARY STANDARD; the 2026-07-31 conjunctive-bar precedent is why). **ANY ONE** of the following, alongside the four standing axes, carries a conversion next session: **credit turns** (HYG/IEF at or below 0.50% under its 20d SMA); **or the index breaks** (SPY closes below its 50dma, or drawdown from the trailing-252 high exceeds 3%); **or volatility stops flickering** (VIX closes above both 15 and its 20d SMA on **two consecutive** sessions). Any one alone suffices. This binds no later session.
- **`theater_check`.** This call declines a conversion the machinery affirmatively permits, which is the harder direction to write — the easy essay was available (breadth at a 36-reading low, VIX +8%, 10Y at a 19-year high, four standing axes, cap 100) and is rejected on the two axes that refuse to confirm plus a flicker I computed rather than inherited. The counter-test: had credit been 50bp *below* its 20d SMA instead of 42bp above it, this would be a conversion — and that is named above as a single sufficient condition rather than buried in a conjunctive list.

**A measurement defect found while gathering this evidence.** VOO's 2026-09-28 IBKR close of **703.61** implies **−1.0101%**, against SPY **−0.7441%**, IVV **−0.7615%** and the index itself **−0.7712%** — VOO is the outlier by ~24bp against three mutually-agreeing references. It was re-pulled **alone** and returned a byte-identical series, its volume array is distinct, and its bar internals are coherent, so this is **not** the parallel cross-contamination defect. It is **not load-bearing** for this call (the index axis and the crisis test resolve identically on any of the four figures), but D2 sizes park capital off that close and `analytics.park_counterfactuals` scores VOO as the risk-on arm of the forward test. Filed as `ops.alerts` info `park_risk_sleeve_close_diverges_from_index` against D2a STEP 1d.

---

## RECOMMENDED ACTIONS

**Exits triggered: none.** No mechanical trigger exists to fire (no open position carries a `convergence_target` or `time_exit_date`) and no Development engaged any thesis-invalidation criterion.

**New entry candidates requiring thesis construction: none.** Seven names clear Strategy B's frozen ≥5% floor but B is `DO-NOT-ACTIVATE` and capital-disabled at NAV $0.00, so none is routed; all seven are indexed below instead.

**Add candidates: none.** 12 evaluated, 0 flagged, 3 blocked at the HARD GATE (ISRG, RTX, UBER).

**Router reviews recommended: none.** See ANALYSIS — REGIME CHECK; M1a and M1b both fire 2026-10-01.

**NOTE (not a bullet): the PARK ALLOCATION CALL above is BOUND — KEEP VOO, `target_f_pct` 0.** D2 reaches it through `state.park_allocation_latest`, never through this section or the action block.

Watchlist updates — add the following seven to the **Strategy B new-entry candidates (state index)**, each anchored on its own resolved event date:

- **ADD KOD** to the Strategy B new-entry index — qualifying event date 2026-09-28, +177.9598% close-to-close (32.35 → 89.92, IBKR RTH bars), Phase 3 wet-AMD topline. Cap $5.63B measured today but ~$2.0–2.3B pre-move, so rail clearance is partly created by the move itself. Weakest B mechanism class: a binary clinical readout is pure information and a justified re-rating has no reason to converge. Index-only; B router `DO-NOT-ACTIVATE` and capital-disabled.
- **ADD MDB** to the Strategy B new-entry index — qualifying event date 2026-09-28, −18.4582% (410.44 → 334.68), CEO departing same-day and effective immediately for Meta, on 17.8x normal volume. Strongest B mechanism of the cohort: a personnel change, not a cash-flow change, repricing a ~$24B company by 18.5%. Index-only, same router/capital reason.
- **ADD GFI** to the Strategy B new-entry index — qualifying event date 2026-09-28, −12.8777% (40.38 → 35.18), gold-miner beta to spot gold ~−3.5%, cap $31.5B measured. Commodity beta rather than a company-specific mispricing; shares its driver with HL and is not independent of it. Index-only, same router/capital reason.
- **ADD CRDO** to the Strategy B new-entry index — qualifying event date 2026-09-28, −8.6742% (210.97 → 192.67), AI-hardware complex repriced on OpenAI's announced training pause, cap $35.9B measured. No disclosure of its own. Index-only, same router/capital reason.
- **ADD BA** to the Strategy B new-entry index — qualifying event date 2026-09-28, −6.9066% (198.07 → 184.39), reported 737 MAX landing-procedure software glitch, on 3.9x normal volume. Confirmed move is 2.2pp worse than the third-party indication that surfaced it. Index-only, same router/capital reason.
- **ADD HL** to the Strategy B new-entry index — qualifying event date 2026-09-28, −6.4871% (18.19 → 17.01), same gold/silver liquidation as GFI, cap $11.4B measured. Recorded as corroboration of that driver, not as independent evidence. Index-only, same router/capital reason.
- **ADD INTC** to the Strategy B new-entry index — qualifying event date 2026-09-28, −5.6667% (123.00 → 116.03), semiconductor selloff on the OpenAI training pause with no Intel-specific disclosure identified. Clears the frozen floor on a purely sector-attributed driver. Index-only, same router/capital reason.

**Entry-window arithmetic, stated under both live conventions rather than pretending it is settled.** The 10-trading-day window runs from the 2026-09-28 anchor. Counting the event session as day 1 it closes **2026-10-09**; counting from the session after, **2026-10-12**. That inclusivity divergence between W4/W2 and D2 is an **open, unadjudicated question** (recorded in `Watchlist.md`, W5's to settle), and it is stated here rather than silently resolved. Under either convention all seven windows close **after** the 2026-10-01 M1a/M1b/M4 cycle, so unlike most prior cohorts these are genuinely reachable by the scheduled router-flip path if B is ever re-enabled and re-funded.

```yaml d1_actions
- action: watchlist
  ticker: KOD
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — +177.9598% close-to-close (32.35 to 89.92, IBKR RTH bars) on Phase 3 wet-AMD topline; cap $5.63B measured today but ~$2.0-2.3B pre-move so rail clearance is partly created by the move; weakest B mechanism class (pure information). Index-only, B DO-NOT-ACTIVATE and capital-disabled at NAV $0.00.
- action: watchlist
  ticker: MDB
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -18.4582% close-to-close (410.44 to 334.68) on the CEO departing same-day for Meta, 17.8x volume; strongest B mechanism of the cohort. Index-only, same router/capital reason.
- action: watchlist
  ticker: GFI
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -12.8777% close-to-close (40.38 to 35.18) on the gold liquidation, cap $31.5B measured; commodity beta, shares its driver with HL. Index-only, same router/capital reason.
- action: watchlist
  ticker: CRDO
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -8.6742% close-to-close (210.97 to 192.67) on the OpenAI training-pause AI-hardware selloff, cap $35.9B measured; no disclosure of its own. Index-only, same router/capital reason.
- action: watchlist
  ticker: BA
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -6.9066% close-to-close (198.07 to 184.39) on a reported 737 MAX landing-procedure software glitch, 3.9x volume; confirmed move 2.2pp worse than the indication that surfaced it. Index-only, same router/capital reason.
- action: watchlist
  ticker: HL
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -6.4871% close-to-close (18.19 to 17.01) on the same gold/silver liquidation as GFI, cap $11.4B measured; corroboration not independent evidence. Index-only, same router/capital reason.
- action: watchlist
  ticker: INTC
  strategy: B
  qualifying_event_date: 2026-09-28
  source_research_screen_id: e3c878dc-339b-4a20-87cc-291dc210cf13
  detail: ADD to Strategy B new-entry index — -5.6667% close-to-close (123.00 to 116.03) on the OpenAI training-pause semiconductor selloff, no Intel-specific disclosure; clears the frozen floor on a sector-attributed driver. Index-only, same router/capital reason.
```

---

## PROCESS NOTES

- **Two `ops.alerts` info rows raised, both routed to W5 SPEC-DEFECT NOTICE INTAKE.** (1) `park_risk_sleeve_close_diverges_from_index` — owner D2a STEP 1d; VOO's IBKR close implies a session move ~24bp more negative than the index and two peer trackers, contamination ruled out by a solo re-pull, not load-bearing today but D2 sizes park capital off that mark. (2) `hf_capability_check_search_cannot_satisfy_its_recency_window` — owner D1's own FRONTIER-LLM step; `hf_fs` search ranks by **relevance, not date**, so a `--limit 5` query applies a 24-hour recency filter to a result set with no reason to contain anything recent, and NO CAPTURE becomes indistinguishable from an honest absence. Filed on **one** observation and flagged as such, with three candidate remedies and no position taken.
- **FRONTIER-LLM CAPABILITY CHECK: no capture.** One `hf_fs` query (Monday battery, *"LLM cross-session consistency reasoning variance"*). Five results, **zero in window** — the newest was 2026-05-11, over four months past the ~72h cap — and three of the five are already catalogued in `HF_Resource_Catalog.md` §2. Default-silent, as specified.
- **Standing constraints deliberately NOT re-alerted:** FMP `full-index-quotes`/`full-commodities-quotes`/`quote` plan denials (standing vendor limit, TIER MATRIX), and the open `06c3b0db` anchor-convention notice (not engaged — anchor and reaction session coincide on every item this run).
- **Sub-agent discipline.** The grunt work ran on Sonnet sub-agents; the D1 rules that are written for a single session were **restated verbatim in each sub-agent prompt** — the SEARCH PROTOCOL widening rule, the EVENT-IDENTITY GATE, the FDA limb, the `close`-array mandate, the IBKR concurrency ceiling, the breadth settlement checks. This is the condition that open alert `959693b5` (`d1_single_session_rules_not_inherited_by_subagents`, D1, 2026-09-24) names; it is **not re-raised**, and this run is one data point that the restatement works — the `close`-array and settled-time rules both demonstrably fired.

2026-09-17
<!-- d1_scan_through_utc: 2026-09-17T22:33:15Z -->

# Daily Market Development Scan — 2026-09-17 (Thu, MT)

**Scan window: 2026-09-16 16:31 MT → 2026-09-17 16:33 MT** (24.0h — cadence-normal, no gap to state). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-16T22:31:18Z -->` marker, cross-checked against that file's own commit at `2026-09-16T22:35:29Z` — the two agree to within four minutes. `state.routine_catchup_window` independently gives `window_days = 0.98`, so no `CATCHUP` token is owed. The git history is **not** shallow (1,474 commits), so the git leg of the window resolution is sound rather than merely silent. **ONE completed US trading session inside this window: Thursday 2026-09-17.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-17`. Every close-to-close figure in this file is measured **2026-09-16 → 2026-09-17**.

**Tape — the day after the hike undid the day of the hike.** SPY 754.05 → **762.60** (**+1.1339%**), VOO 693.24 → 701.03 (+1.1237%), on **27.36M shares** against a trailing-nine-session mean of ~26.4M — an ordinary-volume session, not a conviction surge. QQQ **+1.7312%** led, DIA +0.6075% and IWM +0.5318% lagged. The decisive number is volatility: VIX 17.71 → **15.44**, **−12.8176%**, and now **below its own 20d SMA of 15.7990** for the first time in this episode. Yields fell across the whole curve — 2Y 4.74 → **4.67**, 10Y 5.01 → **4.94**, 30Y 5.35 → **5.29**, all −6 to −7bp — so the 10Y closed back below 5% one session after closing above it for the first time since 2007. TLT **+1.1128%**, LQD +0.6798%, HYG +0.3826%, SGOV +0.0099%. Brent (BZX6) 105.83 → **104.82** (−0.9544%), USO −0.5507%. UUP −0.0704%, BITO +0.5871%. GLD **+1.6899%**. Equity breadth ($S5TH) 50.09 → **51.09**, **+1.00pp** and the first up-session after three consecutive falls. **Nine of eleven GICS sectors higher**, none flat, cross-sector spread **2.8201pp** (XLK +2.2449% to XLC −0.5752%) against 2.9857pp yesterday — a fourth consecutive wide-dispersion session, still narrowing.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-17 stamp of `13:30:00Z`. **Two documented exceptions, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900` — an index-feed property, not an equity RTH bar; and the Brent bar is a NYMEX future (BZX6, contract 339981284) carrying `delayed:600`. Several US equity legs also returned with a `delayed:900` flag on the underlying feed; settled daily closes are unaffected and the flag is recorded for completeness.

**This run is NOT degraded, and that is measured rather than claimed.** 23 distinct single names and 26 index/ETF/future instruments were put to IBKR for confirmation; **every one returned a genuine 2026-09-17 regular-session bar. Zero symbol-level denials. Zero measurement failures. Zero discovered-but-unconfirmable names.** Every `surfaced_count` in this file is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

**Three provenance notes, all resolved before anything was written.** (1) A sub-agent reported SPY's 2026-09-17 volume as 4,644,974 against a ten-session average of 5,120,708. That is irreconcilable with the prior file's measured 37.8M for 2026-09-16, so the orchestrator **re-pulled the SPY bar directly** and measured **27,358,454** today against a nine-session series of 21.6M–37.8M. The sub-agent figure is discarded; the number in the tape paragraph and in `fields.readings` is the orchestrator's own. (2) A secondary market wrap reported **spot gold −0.40%** on the same session that IBKR measured **GLD +1.6899%**. The GLD bar was independently re-pulled by the orchestrator (contract 51529211: 391.74 → 398.36) and stands; the divergence against the third-party spot figure is **not resolved here** and is not load-bearing, since gold is not a park axis and IBKR is the source of record for the ETF. It is recorded rather than quietly dropped. (3) Sector-ETF contract ids were re-resolved through `search_contracts` before pricing, per the 2026-09-16 finding that nine of eleven carried ids were wrong; two continuity checks tie today to that corrected series (the 2026-09-16 closes measured this run — XLU 41.32, XLC 113.00, XLE 64.03, XLF 55.93 — reproduce the prior file exactly). The registry gap itself remains open as `ops.alerts` `716d9ab3`, owner W5, and is **not** fixed here.

---

## TL;DR

- **Exits triggered: none.** No convergence target, no time exit, and no thesis-invalidation criterion met on any of the 12 open tranches. No position carries a price-level exit criterion, so no dividend netting was owed.
- **New entry candidates: 6 (GNRC, VICR, SDGR, MRNA, SMR, INTC)** — all Strategy B, all **state-index only**; B is `DO-NOT-ACTIVATE`, so no thesis construction is routed.
- **Add candidates: none.** 12 D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER — breach status uncovered). A broad rally is the worst possible tape for a dip trigger.
- **Watchlist changes: 6 adds** to the Strategy B new-entry index, per the above.
- **Regime review: no review.** No development moves a router state; default NO on ambiguity holds.
- **Park: RE-RISK, `target_f_pct` 50 → 25.** Both axes that built the f=50 position — volatility and index — exited defensive in the same session.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**The Fed follow-through is the whole story, and it ran opposite to the decision-day reaction.** The FOMC's 2026-09-16 unanimous 25bp hike to 3.75–4.00% — the first since 2023 — was sold on the day and bought back the next. Chair Warsh's "the plain fact is that inflation is too high and has been for too long," the 16-of-18 dot plot for at least one more 2026 hike, and the IORB move to 3.90% effective today were all in the market's hands by this window's open. What the window added was the **repricing**: a 6–7bp parallel rally across 2Y/10Y/30Y and a 12.8% VIX collapse. That combination — a hawkish hike, then yields *down* and volatility *down* — is the market reading the hike as credible inflation-fighting rather than as a growth shock. Source: Federal Reserve press release and statement PDF (federalreserve.gov, 2026-09-16); US Treasury daily par yield curve via FMP `economics/treasury-rates` (range call pinned 2026-09-15→2026-09-17).

**Iran conflict — active but de-escalating in tone, and the oil tape agrees.** Inside the window: Iran downed at least two US MQ-1 drones (one claimed over the Strait of Hormuz); Saudi Arabia intercepted a suspected Houthi drone with one fatality; the State Department approved a possible $24.3B sale of 48 F-35s to Saudi Arabia. Against those, Trump told reporters he hoped the war was near an end and that Iran wants a deal. **Crude fell** (Brent −0.9544%, WTI-Oct reported −0.90% to $100.99), which is the tell: a market pricing escalation does not sell oil into drone shoot-downs. Sources: Jerusalem Post live updates (2026-09-17 — the liveblog states its times in local terms without a stated UTC offset, so intraday timing is approximate while the date is confirmed); Times of Israel and ABC News liveblogs; Yahoo Finance market summary.

**Bank of England held Bank Rate at 3.75% in a 6–3 vote**, announced 2026-09-17 from the meeting concluding 09-16, with Greene, Mann and Pill dissenting for a hike to 4%. The BoE cited Middle East conflict pushing energy prices and UK CPI at 3.1% in August. Source: Bank of England September 2026 Monetary Policy Summary and Minutes.

**Bank of Japan is PENDING, not resolved.** The 09-17/18 meeting decides Friday ~02:45 GMT, **after** this window closed. A 25bp hike to 1.25% is priced at high probability. **No figures are recorded for it** and no event-dependent assessment is made against it. Source: FXStreet, 2026-09-17.

**Bankruptcies, disasters, FDA: genuinely empty for this window.** No single-company bankruptcy or disaster with a dateline inside the window moved broad markets. No PDUFA action date or FDA decision landed on 2026-09-17; the nearest are GSK's Jideytro (9/18), RARE's Ux11119 (9/19) and IONS' zilganersen (9/22). Stated as measured absences, not as padding.

### 2. Scheduled events that resolved today

**EVENT-IDENTITY GATE APPLIED. Exactly one ≥$2B US-listed earnings print is in scope, and it is in scope by the after-yesterday's-close carve-out, not by a calendar entry.**

**Lennar (LEN) — Q3 FY2026, fiscal quarter ended 2026-08-31, released after the close on 2026-09-16** with the call held 2026-09-17 11:00 ET. Primary source: Lennar investor-relations press release (investors.lennar.com, dated 09-16-2026). GAAP net earnings $284M / $1.19 per diluted share (against $591M / $2.29 in Q3 2025); adjusted $294M / **$1.23** against consensus **$1.29** (miss); revenue **$8.05B**, −8.7% YoY, against consensus ~$8.31–8.32B (miss). New orders −9% to 20,879 homes; home-sales gross margin −170bp to 15.8%; backlog 16,857 homes / $6.3B. FY2026 delivery guidance **cut** to 80,000–81,000 from 82,000–83,000. LEN closed −1%.

**Three names plausible for this slot were checked against primary/company sources and confirmed NOT to have reported inside the window:** FedEx (next print outside the window), **Darden — scheduled 2026-09-24, PENDING, no figures**, **General Mills — scheduled 2026-09-23, PENDING, no figures**. FMP's `calendar/earnings-calendar` returned `[]` for both a pinned 09-17 call and a widened 09-15→09-18 retry — the documented silent-partial failure mode, so that emptiness is recorded as **missing evidence, not as an established zero**, and the earnings sweep rests on primary-source checking instead.

**US economic data released 2026-09-17** (Investrade mid-morning note, corroborated by search aggregation of the DOL/Philly Fed/Census releases; FMP `economics/economics-calendar` returned ACCESS DENIED on plan tier and was not retried per the tier rule):
- **Initial jobless claims 196,000** (consensus 208,000; prior 206,000); 4-week average 203,250; continued claims 1.730M (consensus 1.78M, prior 1.769M). A materially strong labour print.
- **Philadelphia Fed Manufacturing (September) 37.8** (August 47.4; consensus 30.5) — a beat on the headline but with **prices paid up to 48.6 from 40.9**, employment down to 11.8 from 27.9, and the six-month outlook down to 52.9 from 73.6. The internals are worse than the headline.
- **Housing starts (August) 1.275M**, −2.6% (consensus 1.309M); single-family +7.6% to 918,000, multifamily −21.7% to 357,000; permits 1.394M (consensus 1.410M); pending home sales −4.7% YoY. This is the read Lennar's guidance cut corroborates.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

**Layer-1 rail:** US-listed common stocks, cap ≥ $2B, close-to-close ≥ 2%, attributable to an identifiable public event. **`universe_measured` = 23** names priced through IBKR · **`rail_tally` = 17** cleared all three limbs · **`surfaced_count` = 11** = `ARRAY_LENGTH(passed)`, the Layer-2 judgment. Logged as `events.decision_log` `a913941a-3df1-43c5-916c-e77868c63da7`.

| Ticker | Move | Conv | Driver |
|---|---|---|---|
| **MU** | **+5.4994%** | **75** | DRAM contract prices forecast +>50% this quarter, NAND ~60% |
| **GNRC** | **+18.3370%** | **75** | Up to **$8B** Amazon data-center generator supply deal (regulatory filing) + warrant for ~3% of shares |
| **VICR** | **+17.6608%** | **75** | Two NH sites for ChiP Fab-2/Fab-3 + VPD licence to a major AI OEM + $150M buyback + backlog **+145%** |
| SMCI | +9.4979% | 60 | AI-server re-rating on the same memory forecast |
| SMR | +8.9157% | 45 | First-of-a-kind boron-oxide pellet fabrication, passive cooling |
| MRNA | +8.5495% | 60 | Phase 3 progress, intismeran cancer vaccine (MS Healthcare conf.) |
| INTC | +7.6695% | 60 | Analyst target hikes + **reported** SK Hynix production talks |
| AMD | +6.3590% | 45 | Third-session semiconductor rebound |
| HL | +5.3919% | 45 | Silver surge, record Lucky Friday output |
| SDGR | +26.3766% | 45 | "Tectora" JV, two early-stage programs for equity/royalty |
| **CRWV** | **−4.1632%** | **60** | **$3B converts due 2033 + ATM for up to 35M shares** |

**MU +5.4994%, conviction 75 — the most consequential development of the day, and the reason XLK led.** A >50% quarterly rise in DRAM contract prices is a cost input across every hardware OEM and a margin event for the memory complex. What earns conviction 75 is that the move is *small* relative to the input-cost change being priced, not that it is large.

**SMCI +9.4979%, conviction 60 — and the DIRECTION is the tell.** Higher memory cost is a margin **headwind** for a server assembler, and SMCI rallied 9.5% anyway (HPE and DELL with it). That is the market pricing pass-through power, not cost relief — the more interesting half of the pair.

**GNRC +18.3370%, conviction 75 — and it reads through to a name this book holds.** Potential revenue of roughly 65% of a $12.2B market cap, from a named counterparty, disclosed by filing. **D:GEV:2026-08-03 traded up intraday on the same hyperscaler-power signal before closing flat (−0.0173%)**, and that read-through is evaluated under ADD-CANDIDATE CHECK below rather than left as colour.

**CRWV −4.1632%, conviction 60 — the only material idiosyncratic decliner on a +1.13% tape, and `below_spec_floor = true`.** At −4.16% it does not clear Strategy B's frozen 5% floor and is **context and SL1 evidence only, never routed as a B candidate**. It is surfaced because a 4% fall against a broad rally, on a dilution-and-financing event at an AI-infrastructure bellwether, is a reading on the *financing* side of the capex cycle that none of the up-moves supply. It is the whole of `agreement.ai_only`.

**HL +5.3919%, conviction 45 — surfaced for the cross-asset dissonance, not the company news.** Precious metals bid (GLD +1.6899%) on a day the long end *rallied* and the Fed is tightening. A debasement/haven bid the rates market declines to corroborate is worth a record.

**Declined, and the absences are the informative part.** **CDE +5.2687%** and **MARA +5.4348%** both clear the legacy ≥5% rule and are therefore carried in `rejected_notable` rather than dropped — they are the whole of `agreement.rule_only`. CDE is pure tandem with HL on one silver print (two readings of one thing are one thing); MARA is balance-sheet beta with no dated corporate event. Below the legacy rule and so owed no slot: **NVDA +2.5432%** (sector flow), **BMNR +4.7352%** (ETH treasury story), **NOK +4.5365%** (AI-RAN trials + Microsoft partnership — real but ordinary), **PLUG +4.9505%** (a broker-hosted roadshow is not a corporate event).

**Two names excluded from the rail arithmetic itself, stated rather than quietly dropped.** **IREN +2.0178%** — the discovery leg found **no IREN-specific dated catalyst**; it fails the identifiable-event limb and is excluded from `rail_tally`, not from measurement. **SPCX +2.6048%** — excluded on the event limb (attribution is "part of the broad rally"), and separately its FMP `profile-symbol` cap of **$2.041 TRILLION** against a $154.81 share price implies ~13.2B shares. That figure is **not relied on and not second-sourced**; the exclusion does not depend on it.

**Sub-rail context, measured and outside the population.** **FLNC −15.36%** (9.05 → 7.66) on a cut FY26 revenue forecast ($2.9–3.1B → $2.4B) and **DSP −19.00%** (12.37 → 10.02) on a CTV-growth miss both carry genuine company events and fail only the cap rail, at $1.41B and $657.5M. Recorded so the exclusion is legible as a **cap** decision rather than an absence. (`company/market-cap` and `company/shares-float` returned ACCESS DENIED for FLNC — the standing FMP tier constraint, deliberately **not** re-alerted.)

**Window-boundary check on yesterday's two flags.** **JBHT** 236.73 → 236.80 = **+0.0296%**; its −13.3% event sat in the 09-15→09-16 session and does not re-qualify. **FANG** 194.54 → 196.94 = **+1.234%**; same. Neither is double-counted.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

**Layer-1 rail:** any GICS sector ≥1% at ETF level, or notable dispersion. **`universe_measured` = 11** · **`rail_tally` = 2** (XLK, XLY cleared the ≥1% limb) · **`surfaced_count` = 3**. Logged as `events.decision_log` `3b6ab6b2-4659-4041-b964-318cd3f6d1ba`.

| Sector | Move | | Sector | Move |
|---|---|---|---|---|
| **XLK Technology** | **+2.2449%** | | XLRE Real Estate | +0.3037% |
| XLY Cons Disc | +1.0982% | | XLP Cons Staples | +0.1920% |
| XLU Utilities | +0.8955% | | XLI Industrials | +0.1778% |
| XLE Energy | +0.7028% | | **XLF Financials** | **−0.0894%** |
| XLB Materials | +0.6950% | | **XLC Comm Svcs** | **−0.5752%** |
| XLV Health Care | +0.6199% | | | |

**XLK +2.2449%, conviction 60 — the only sector doing real work, for the second session running.** The gap to second place (XLY) is 1.15pp, larger than the whole distance from XLY down to XLI. What makes it significant rather than merely large is the regime: **long-duration growth leading on the session after a rate hike, with 16 of 18 dots on another**, is the opposite of the textbook rates read. Yesterday XLK was also the sole meaningful gainer (+0.1034%) on a down tape. One session is noise; two in a row through a policy event is a pattern.

**XLF −0.0894%, conviction 60 — below the magnitude rail and surfaced anyway, because the CONTINUATION is the signal.** Yesterday financials were the second-worst sector at −1.6183% on the hike itself, conviction 75. Today the tape rallied +1.1339% and **banks still did not join** — 1.22pp behind the index and one of only two decliners. One session of banks selling a hike can be positioning; two sessions, the second of them a broad rally they sit out, is a held view about the credit-and-growth side of a tightening cycle landing on an economy scored `decelerating`. **This is deliberately NOT the park's credit axis firing** — the mechanical credit test measures **+0.3816%** and refuses to confirm, and an equity-sector move is not a credit-spread reading. Two readings of adjacent things are not two axes.

**XLC −0.5752%, conviction 45** — worst sector, 1.71pp behind SPY, with **no single driver established**, and it is surfaced as the negative tail of a one-sided board rather than as an event.

**XLY +1.0982% CLEARS the rail and is deliberately not surfaced** — against SPY +1.1339% it is a market-beta print to within 4bp, and a sector moving exactly with the index carries no rotation information. Surfacing it because it crossed a mechanical line is precisely the Layer-1-as-significance-claim error the two-layer design exists to prevent. **The defensive complex did nothing notable** — utilities, staples, health care and real estate all rose but all lagged — so **this is not a defensive rotation and must not be read as one**; that inference is the 2026-09-01 error (`bigquery/213`) a later correction had to undo, and the guard is checking what the defensives did rather than inferring it from the leaders.

### 5. Notable commentary

- **Goldman Sachs reversed its call** and now expects an **October** hike, attributing the pivot to Warsh's tone and the dot plot. **Citi** takes the opposite side, expecting a prolonged pause and a cut next June. Wall Street is genuinely split on the Oct/Dec path.
- **Raymond James** (Daniel Tamayo): the SEP shift implies two 2026 hikes against one previously; ~83% odds of two. **BCA Research** (Felix Vezina-Poirier): a new tightening cycle, but "mild and front-loaded" at two to three hikes. **Capital.com** (Daniela Hathorn): the more important message was that policymakers do not think the cycle is finished. **Evercore ISI** framed the reshaped committee as "the disappearance of the doves."
- **October-meeting odds are genuinely unsettled across sources and the disagreement is recorded rather than resolved:** ~55.1% hike on one CME-tracking aggregator against ~95% on another, and Polymarket implying ~48%. None was fetched from a CME FedWatch page directly, so the exact percentage is source-dependent; only the directional read (a live, contested coin-flip-to-likely additional hike) is consistent across them.
- **Sell-side actions on the tape:** Bernstein downgraded PANW, OKTA and S to market-perform after ~100%+ 2026 gains in security software; Citigroup downgraded BSX; HSBC downgraded CPRT; Guggenheim downgraded LYFT; BofA upgraded HAWK (+6%); JPMorgan flagged MIR as an H2 catalyst.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep — UNION of `state.current_positions` and live `get_account_positions`

**12 open tranches across 8 names, every one Strategy D. No exit triggered.**

**Convergence targets: none exist.** All 12 tranches carry `convergence_target IS NULL` — Strategy D is a long-horizon, no-stop design with no price targets. **Time exits: none exist.** All 12 carry `time_exit_date IS NULL`. Both mechanical triggers are therefore vacuous on this book by construction, and that is a property of Strategy D rather than a quiet pass.

**Union check — no reconciliation-lag position.** The live IBKR book holds ten lines: the eight strategy names plus SGOV and VOO, which are the park and not strategy positions. Every equity line reconciles to its BigQuery tranches exactly (AMZN 0.3464 = 0.1554 + 0.1910; DIS 0.7244 = 0.2822 + 0.4422; GOOGL 0.2577 = 0.1043 + 0.1534; TSM 0.1550 = 0.0891 + 0.0659). **No position exists in the connector that is absent from `state.current_positions`**, so no `position_reconciliation_lag` alert is owed and none was raised.

**Dividend netting: not owed, and that is checked rather than assumed.** `state.price_level_criterion_drift` returns exactly **one** row — `D:DIS:2026-08-05`, criterion key `not_exit_triggering`, carrying `is_exit_criterion = false` and `actionable_price_level = false`. It is the "$45.00 notional" phrase inside the thesis's own *not*-exit-triggering sentence, not a price test. **No open position carries a price-level exit criterion**, so there is nothing to dividend-adjust on this book.

### Thesis-invalidation sweep — all eight names, criterion by criterion

**No development inside the scan window bears on any named invalidation criterion of any of the eight positions.** Each was searched against its own criteria, not scanned generically:

| Name | Finding |
|---|---|
| **AMZN** | Nothing touches AWS revenue YoY, AWS margin, AWS backlog, Anthropic/OpenAI commitment churn, or segment-reporting immutability. The Anthropic AWS commitment stories are April–July 2026, outside the window, and the April item was an **expansion**, not a reduction. *Not criterion-bearing:* the Generac ~$2.4B backup-generator supply deal (filed 09-16) is data-center supply-chain news. |
| **DIS** | No FCC final order restricting station ownership and no corresponding 8-K. The only recent FCC station-ownership action was an 2026-08-06 vote to **repeal** the national cap — the opposite direction, and outside the window. No buyback 8-K, no SVOD reporting change. *Not criterion-bearing:* a Senate Commerce committee bill advanced 09-16 barring government pressure on broadcasters is a committee action, not an FCC final order. |
| **GEV** | Nothing touches total-company organic orders growth YoY or disclosure comparability. CEO backlog commentary at the Morgan Stanley Laguna Conference ($176B → "$200B very early 2027") is timestamped **before** the window opened, and backlog is not the named primary trend metric. *Explicitly excluded by the thesis:* the ~3.3% intraday data-center-power pop is short-term price action. |
| **GOOGL** | No Cloud revenue/margin/RPO data in the window. The only structural-remedy-relevant ruling — Judge Brinkema's 2026-09-02 ad-tech order — is both outside the window and **behavioral** (it rejected the DOJ's AdX divestiture), so it would not meet criterion 4 even if fresh. |
| **ISRG** | No procedure-growth, placement, recurring-revenue or named-IDN-displacement disclosure. Searches on Medtronic Hugo and J&J Ottava surfaced no hospital-contract displacement. *Not criterion-bearing, and favourable:* EU CE Mark approval expanding da Vinci SP into gynecologic procedures. |
| **RTX** | No new Airbus damages ruling (the powder-metal compensation thread shows Melrose obligation payments **declining**), no new >$1B quality charge, no GTF Advantage EIS slip, backlog at a **record $289B and rising**, FY26 FCF guidance **$8.25–8.75B** against the $7.5B floor, no FY27 procurement cut. *Not criterion-bearing:* the F135 Engine Core Upgrade design review is a military programme, not the commercial GTF Advantage named in criterion 3. |
| **TSM** | No GM/revenue print (next report 2026-10-15), no N2/A16 pushout, no sub-7nm share decline. The capex signal ran the **other** way — Vera Rubin cited in full production with orders from every major hyperscaler, 2nm expansion and CoWoS doubling reaffirmed. *Not criterion-bearing:* an industry-wide Arizona fab labour-shortage story. |
| **UBER** | No gross-bookings, EBITDA-margin, Uber One or disclosure-format development inside the window. The most recent Uber One datapoint (>50M members, +50% YoY) is 2026-09-10, outside the window, and shows no stall. |

### Per-strategy kill-trigger sweep

**`current_drawdown` refreshed unconditionally against today's live marks, as required — not conditioned on any judgment about whether the book moved.** The D book rose **+0.6020%** on the session (market value 540.70 → 543.96 against cost 542.24). Applying that to the engine's 2026-09-16 `deployed_unit_value` of 1.053380711 gives a refreshed **≈1.0597** against a peak of 1.098110312, i.e. **drawdown ≈ −3.50%**, improved from the engine's −4.0733%.

- **Drawdown kill (#1):** −3.50% against a −50% trigger. **Not fired**, and not close.
- **Runaway-success (#3):** deployed TWR has not doubled (unit value ≈1.06) and `gate_reached` is FALSE at `gate_n` 29 of 30. **Not fired.**
- **Interim underperformance warning:** `deployed_days` 99 (≥90) but `excess_vs_sgov` **+3.86%**, far above the −15% bar. **FALSE for D.** Strategy B's row is stale at 2026-08-18 with all flags FALSE and **zero open positions**, so there are no live marks to refresh and nothing to evaluate. No alert owed, and **no open alert of this category exists to heal-resolve**.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, `avg_offdiagonal_corr` NULL. The check is inert by its own `n_positions >= 2` guard. **Nothing raised** — and note the alert message for this category is a fixed string by design, so no interpolation defect can arise here.

*(Mark-to-market #4 and foundation-change #2 are detected on M4 and Q3/A1 respectively, not here.)*

### Watchlist candidacy

**One material change, and it is a resolution rather than a new flag.** The **XOM** row (A queue) was annotated yesterday when its crude-up/energy-equities-flat divergence closed unfavourably. Today energy participated modestly (XLE +0.7028%) while Brent fell again (−0.9544%) — the divergence is now inverted rather than restored, and at this size it is noise. **No further annotation is owed** and no disposition changes; A remains `DO-NOT-ACTIVATE`. The remaining A-queue names and the B watch-overflow rows are unaffected by anything in this window.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated for every roster-active strategy with `review_cadence: reactive` in `strategy/roster.yaml` — currently **A, B, C, E**. **Every one of the four is `capital_disabled`** as of the 2026-09-04 divergence-review cohort (A, B, D, E all DO-NOT-ACTIVATE; C is HYBRID ACTIVATE, FOMC-only). Candidacy is surfaced regardless — D1 surfaces, D2 gates — and every routing decision below states the activation state it is subject to.

**Strategy B — 6 candidates, all state-index only.** Twelve names cleared B's frozen Entry criterion 1 (≥5% close-to-close on event day, ≥$2B cap) today. Six carry a **company-specific public event** and are indexed; six do not and are declined:

| Indexed | Move | Qualifying event (2026-09-17) |
|---|---|---|
| **GNRC** | +18.3370% | Up-to-$8B Amazon data-center generator supply deal, disclosed by regulatory filing, plus a warrant for ~3% of shares |
| **VICR** | +17.6608% | Two NH sites for ChiP Fab-2/Fab-3, VPD licence to a major AI OEM, $150M buyback, backlog +145% |
| **SDGR** | +26.3766% | "Tectora" JV formed by contributing two early-stage small-molecule programs for equity and royalties |
| **MRNA** | +8.5495% | Phase 3 progress on intismeran, presented at the Morgan Stanley Global Healthcare Conference |
| **SMR** | +8.9157% | First-of-a-kind boron-oxide pellet fabrication for a passive emergency cooling system |
| **INTC** | +7.6695% | Analyst target hikes (Tigress $145, Northland Outperform) + **reported** SK Hynix production talks |

**Declined for indexing, with reasons:** **MU +5.4994%, SMCI +9.4979%, AMD +6.3590%** — one industry price forecast, not a company event at any of the three; this is exactly the "information-driven rather than sentiment-driven" case criterion 4 exists to catch. **HL +5.3919%, CDE +5.2687%** — commodity beta. **MARA +5.4348%** — balance-sheet beta. **INTC is indexed with a caveat carried into the row:** its largest leg is a *report* of SK Hynix talks, not a company announcement, and a thesis session must weigh that before treating it as an event.

**Deterministic four-part identity checked on FIELDS, never on the key string**, against both open and terminal `events.queue_events` history. Prior B thesis items exist for **GNRC (`due_date` 2026-06-28, status complete)**, **MRNA (2026-07-12, complete)** and **INTC (2026-06-21/22, complete)** — all carrying **different qualifying event dates**, so today's are distinct later events in the same tickers, not duplicates, and suppressing them would be the prohibited ticker-only deduplication. **VICR, SDGR and SMR have no rows at all.** Ten-trading-day B windows anchor on the **qualifying event date 2026-09-17** per the ANCHOR PIN, giving ~2026-10-01.

**Strategy A — no new candidate.** Nothing in the window puts a named catalyst within a six-month horizon on a name not already queued. The A queue is unchanged and remains `DO-NOT-ACTIVATE`.

**Strategy C — no new candidate.** C's operative state is the **FOMC-only carve-out**. Today's follow-through resolves the September meeting rather than creating a new catalyst, and the next FOMC (2026-10-28) is **already queued** as `thesis-FOMC-C-20261020`, due 2026-10-20. Creating a second item would duplicate it.

**Strategy E — no new candidate.** The XLK/XLF divergence is a cross-sector spread, not an intra-industry-group pair, and E's own entry design needs a named pair within an industry group. E holds zero positions and is `capital_disabled`. **No pair is surfaced**, and "the tech/banks gap is wide" is deliberately not dressed up as one.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

**12 tranches evaluated · 0 flagged · 3 declined at the HARD GATE.** Logged in full to `events.decision_log` `27c6ccd6-2adb-411b-9c17-980dbac40553` (`entry_type='add-candidate-review'`), including every decline.

**`mark_vs_cost_pct` price basis:** numerator is the IBKR regular-session close, denominator is **that tranche's own** `cost_basis / shares`, never the blended `avg_price`. The documented divergence appeared again this run — `get_account_positions` served AMZN at 250.75 and DIS at 105.50 against true closes of 251.19 and 105.35 — and the position-endpoint mark was used for nothing.

| Tranche | mark vs cost | Disposition | Evaluable |
|---|---|---|---|
| D:AMZN:2026-07-09 | +4.1227% | declined | FALSE |
| D:AMZN:2026-07-30 | −5.4586% | declined | TRUE |
| D:DIS:2026-05-07 | −5.3621% | declined | FALSE |
| D:DIS:2026-08-05 | +1.5076% | declined | TRUE |
| D:GEV:2026-08-03 | −4.6371% | declined | TRUE |
| D:GOOGL:2026-07-09 | −3.4788% | declined | FALSE |
| D:GOOGL:2026-07-26 | +5.9438% | declined | TRUE |
| **D:ISRG:2026-07-20** | +9.7363% | **declined_hard_gate** | FALSE |
| **D:RTX:2026-04-27** | +9.4072% | **declined_hard_gate** | FALSE |
| D:TSM:2026-07-21 | +0.5606% | declined | FALSE |
| D:TSM:2026-07-29 | +9.5135% | declined | TRUE |
| **D:UBER:2026-07-09** | −3.1927% | **declined_hard_gate** | FALSE |

**A rally is structurally the worst tape for trigger (a).** Six of eight names rose; only two fell, and neither is a dip in the sense the trigger means. **DIS −1.5329%** was the largest faller and the only real relative weakness (2.67pp behind the index), but the name is not in position-level drawdown at all — the 08-05 tranche sits **+1.5076%** — and a single-session move with no information is exactly what the thesis itself enumerates under "NOT exit-triggering." A move that is not evidence for an exit is not evidence for an add. **RTX −1.6718%** is even less of one: the tranche stands **+9.4072%** above cost.

**Trigger (b) was tested and GEV is the closest call of the sweep — declined, with the reasoning recorded.** GNRC's up-to-$8B Amazon deal is genuinely new information about the demand channel the GEV thesis rests on. It is declined because (i) it is a contract won by a peer, not GEV's own bookings, and the thesis metric is specifically **total-company organic orders growth YoY**, next observable at GEV's own print; (ii) GEV closed **flat** (−0.0173%), so the market did not price it as GEV news either; (iii) the thesis lists "short-term price action" among things that are not exit-triggering, and that symmetry binds an add as much as an exit.

**HARD GATE — three tranches structurally ineligible, re-derived this session rather than inherited.** Seven tranches carry `breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. Four are covered at **name** level by a later tranche with a fresh dated assessment (AMZN by 07-30, DIS by 08-05, GOOGL by 07-26, TSM by 07-29). **ISRG, RTX and UBER are covered nowhere**, so "unbreached" cannot be affirmatively confirmed and they are ineligible regardless of merit. No add case was argued for any of the three, so the gate cost nothing today — recorded because the day it costs something, it will cost it silently.

**`invalidation_criteria_evaluable` — computed on the THREE-disjunct rule: 5 TRUE, 7 FALSE.** Measured again this run: **not one of the 12 tranches carries a `$.status` key at all**, so the two-disjunct rule would have returned TRUE for all twelve, *including the three the gate declines* — the field would have said the opposite of what the gate did. The `breach_status` disjunct is what makes them agree. NULL-safety wrap applied.

**Standing context, deliberately not used as a reason:** Strategy D has been `capital_disabled` since 2026-09-04, and an add is new capital. Every tranche was nonetheless evaluated on its merits first, because a sweep that short-circuits on the router state stops being evidence about the book.

---

## ANALYSIS — REGIME CHECK

**No router review recommended.** High bar; default NO on ambiguity, and this is not close to it. Today is a one-session reversal of a one-session reaction. The operative fundamental axes were scored 2026-09-01 by M1a (`growth_momentum` decelerating, `inflation_trend` disinflating, `policy_stance` hawkish, `risk_sentiment` risk-on, `shock_overlay` acute); nothing in this window moves any of them by a month's worth of evidence. The hike itself was the *expected* realisation of the already-scored hawkish stance, not new information about it, and a 7bp yield retracement with a VIX drop is the market's reaction function, not a regime change. The mechanical technical signals D2a will write tonight (SPY_TREND, VIX_REGIME) are its own to set and are not pre-empted here.

---

## EQUITY-BREADTH OBSERVATION

**`EQUITY_BREADTH_PCT` = 51.09 for `as_of_date` 2026-09-17**, written to `events.regime_events` (`scope='TECHNICAL_INPUT'`), source **Barchart `$S5TH`**.

**Two sources agree exactly.** Barchart read 51.09 with as-of wording *"Quote Overview for Thu, Sep 17th, 2026"*; **EODData `$S5TH` independently returned Close 51.09** (OHLC 51.29 / 51.49 / 48.90 / 51.09). **Barchart's Previous Close (50.09) and EODData's PREV (50.09) both match the stored 2026-09-16 value exactly** — zero revision, so no Previous-Close reconciliation is owed. Investing.com confirms the prior chain (Sep 16 = 50.09, Sep 15 = 52.88) but has **no row for 2026-09-17** at this hour, exactly as the step spec predicts, so it is a prior-session cross-check only.

**Fetch provenance:** `tavily_extract` at advanced depth, cache-busted. A rendering `web_fetch` returned an empty body on Barchart across three attempts (confirmed working against a control URL), so per the fetch-method-is-provenance rule the empty payload condemned **that fetch**, not the source, and the other path was retried and succeeded. Three cache-busted extracts at distinct wall-clock times returned byte-identical content, which is what rules out a Tavily-side cache artifact. **Source-dated, not `inferred_post_close`.**

**Settlement caveat, stated rather than hidden.** Both vendors carry an on-page timestamp of **14:58 ET**, roughly an hour *before* the close, despite being fetched at ~18:10 ET. The compound EODData unsettled tell does **not** apply (Low 48.90 ≠ Close 51.09) and the on-page as-of date is correct on both. But the pre-close timestamp appears on both simultaneously, which is more consistent with two vendors mirroring one stalled upstream feed than with two independent settled prints. Recorded as **agreeing-but-caveated**; a later upward revision would be expected noise of the documented kind. **Per the idempotency rule this row will NOT be retroactively corrected** — if 09-17 settles differently, tomorrow's run records the revised value in its own rationale.

**MacroMicro deliberately not attempted** — the 2026-09-06 W5 ruling makes it a weekly re-probe riding the **Sunday** D1 run, and today is Thursday, so a fetch would have been forbidden spend. **Rejected:** Barchart via rendering `web_fetch` (empty body ×3); the Barchart JSON proxy (HTTP 403); Investing.com as a same-session source; an uncorroborated social post citing an unrelated "92% above 200-day" figure.

---

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

One HF `hf_fs` paper search, Thursday's rotation battery (`sycophancy LLM anchoring narrative bias`, §6.1 / §1.12). All five returns — Beacon (2510.16727), SynAnchors (2505.15392), Sycophancy Causes and Mitigations (2411.15287), Anchoring Bias Experimental Study (2412.06593), SYCON-Bench (2505.23840) — are **already catalogued in `HF_Resource_Catalog.md` §1.12**, and the newest was published 2025-10-19, far outside this run's ~24h window. **No paper published since the last D1 run. Nothing captured, no `events.decision_log` entry, no `state.strategy_candidates` row** — default-silent, correctly.

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO** — the **majority sleeve** at `target_f_pct = 25` (risk sleeve 75%). `risk_sleeve` VOO, `defensive_sleeve` SGOV.
- **`target_f_pct`: 25 — DOWN from 50. Direction: RE-RISK. Status: BOUND.**
- **`conviction`: MEDIUM, `conviction_pct` 45.**
- **`rationale`:** **Two axes exited defensive in the same session, and they are the two that built this position.** **Volatility EXITED** — VIX 17.71 → **15.44** (−12.8176%), now **−2.2723% below its 20d SMA of 15.7990**; the conjunctive test needs VIX above both the SMA and 15, and it is above 15 by 0.44 and below the SMA by 0.36. Volatility entered defensive on **2026-09-09** and justified the first de-risk (f 0 → 25) on 09-08. **Index EXITED** — SPY **762.60** reclaimed the 50dma of **759.5314** on a close, **+0.4040%**, and drawdown from the 252-session closing high (777.88, 2026-08-13) improved from −3.0635% to **−1.9643%**. Index entered on **2026-09-15** and justified the second de-risk (f 25 → 50) on 09-10. **Zero axes entered.** Hand-scored standing count **5 → 3**.

  **The three that still stand are real:** breadth DEFENSIVE (51.09 vs the 66 line, though **turned up +1.00pp** after three falls); rates DEFENSIVE (mid-cycle at 3.75–4.00% with 16 of 18 dots on another hike — today's 7bp parallel rally is a retracement, not an exit, and the 10Y−2Y spread is unchanged at +0.27); shock DEFENSIVE (`shock_overlay = acute` as-of **2026-09-01**, a sixteen-day-old **standing state, which is never news**, plus Brent 104.82 > 95). **Credit still refuses to confirm, in the direction that supports this call**: HYG/IEF **0.8626849** vs a 20d SMA of **0.8594052** = **+0.3816%** where the test needs −0.50%, compressed toward the mean from +0.6253% yesterday.

  **The arithmetic, computed before this was written.** Standing 3 → raw cap `LEAST(100, 25×3)` = **75**. Suggested target = nearest step to `0.45 × 75 = 33.75`; |33.75−25| = 8.75 against |33.75−50| = 16.25 → **25**. The ±1-step deviation is available and declined in both directions. **Decreasing f is always allowed and never delayed**, and re-risks sit outside the DE-RISK EVIDENCE CARDINALITY floor, so nothing gates this beyond the judgment.

  **Which cap goes in the formula — the two bullets disagree today and the choice is stated.** The **decay-confirmed cap is 100**, computed rather than assumed: standing count read 5 on 09-15 and 5 on 09-16 and 3 for the first time today, so the three-consecutive-readings step-down is not yet due. The **raw cap is 75**. I size on the **raw** cap and clamp to the confirmed one (non-binding, since both 50 and 25 sit under 100), because the CAP bullet itself says the confirmed cap is a ceiling the one-way ratchet forbids using "to license a larger de-risk than your own hand-scoring supports." Sizing on 100 would give `0.45 × 100 = 45` → step 50, holding the defensive weight up on a count I do not believe.

  **This call is NOT arithmetically robust and this file says so.** Step 25 is returned for conviction in roughly (16.7%, 50%]; **at 51% or above the ladder returns 50 and this becomes a KEEP**. So it rests on the judgment that conviction fell from yesterday's 55 to 45 — and the reason it fell is precise: the f=50 position was built on two *entering* events, and both reversed today, leaving only the slow standing set that this system's own rule says is never news. Holding conviction at 55 would assert my belief is unchanged on the day both of its precipitating events were undone.

  **The case AGAINST re-risking, stated in full.** (a) Three axes still stand defensive against a genuinely hostile backdrop — an active tightening cycle landing on `decelerating` growth, with an acute shock overlay. (b) One session is one session, and a sharp reversal of a hawkish selloff is exactly the shape that fails. (c) The VIX exit is thin — 0.36 points puts it back. (d) Breadth at 51.09 is weak in absolute terms and, at a **pre-close 14:58 ET vendor timestamp**, is the least settled number in this file. **The case for wins because the defensive posture is what needs justifying here, not the risk posture.** The park's default vehicle is the risk asset; both closed defensive excursions of the AI era **lost** (−2.841pp, −1.019pp — 0-for-2); across 15 historical episodes the defensive signal carried mean forward edge −0.638pp and won 4 of 15; and f=50 cost **$83.84** of foregone return today alone. **Yesterday's own invalidation named today's conditions explicitly** — "any one of: SPY reclaiming its 50dma on a close; breadth recovering above roughly 60; or the index axis simply exiting defensive" — and **two of those three disjuncts fired**. Declining to act on criteria written one session ago, when they fired as written, is the asymmetry that cost ~$265 in the 2026-07-31/08-02 episode. **Why VOO 75 / SGOV 25 beats the runner-up (f=50):** the runner-up holds protection bought on two events that no longer obtain. **Why not f=0:** three axes genuinely still stand defensive and the cycle is live — this is a step down the ladder, not an all-clear.

  **Mechanical panel disagrees and the disagreement is pure VINTAGE — recorded in `fields.axis_overrides`.** `state.park_axis_daily` for 2026-09-17 publishes standing 5 / firing 0 / cap 100 / gate shut, with **`axes_measured_today = 0` and all six axes carrying `measured_on = 2026-09-16`** — structural, since D2a writes `events.signal_marks` at 16:41 MT, after this run. I override volatility and index on today's measured closes. **The MIXED VINTAGE rule and the one-way ratchet are both written for the DE-RISK direction and are literally silent on this case** — a carried *defensive* reading standing against a same-session measured *improvement*. Read by mechanism rather than letter, a carried reading is not evidence about today in either direction, and letting yesterday's stale defensiveness veto today's measured improvement is the same failure MIXED VINTAGE names, pointed the other way — and it would make the park sticky in the defensive direction, this allocator's one twice-measured, money-losing failure mode. I act on the measured readings and **record the spec gap rather than resolving it unilaterally**: `ops.alerts` info `park_axis_vintage_rule_silent_on_rerisk`, owner W5 SPEC-DEFECT NOTICE INTAKE.

  **Conversion is real, checked on TARGET WEIGHTS not the vehicle string.** Park market value **$15,171.72** (VOO 10.9027 sh × 701.03 = $7,643.12; SGOV 74.8667 sh × 100.56 = $7,528.60); `actual_f_pct_before` = **49.6226%** against a standing policy of (50, VOO, SGOV). New target (25, VOO, SGOV) differs by **24.6226pp** even though the named vehicle string is unchanged — far outside the 10pp no-op band. Each leg is **$3,735.67**: sell ~37.1487 SGOV, buy ~5.3288 VOO, both far above the $25 minimum. Both instruments are `state.park_menu` members (VOO tier 4, SGOV tier 0), and moving to a higher risk tier is what makes this a re-risk.

  Crisis override **not engaged**: session index move +1.1339% against the −2.5% bar; VIX 15.44 against the 28 bar. Increase gate **shut** (firing_count 0) and irrelevant to a decrease.
- **`invalidation` (symmetric standard, both limbs at the same bar):** **Would RAISE f again** — **any one** of: VIX closing back above its 20d SMA; SPY losing the 50dma on a close; breadth turning back down through ~48; or credit finally confirming (HYG/IEF crossing below its 20d SMA by more than 0.50%). **Would LOWER f further** — breadth recovering above ~60, **or** the shock overlay de-escalating at the next M1a scoring, **or** a second consecutive session with VIX below 15. Deliberately **disjunctive on both limbs and at the same height**, because I re-risked on a disjunctive two-axis-exit case and must not require a conjunctive checklist to undo it. No later session is bound by this.
- **`theater_check`:** The conclusion is **not** the default — KEEP at 50 is, and this record overturns it, so the burden sits here. The arithmetic (`0.45 × 75 = 33.75 → step 25`) was computed before the rationale was written, the strongest counter-case is stated in full, and the single load-bearing weakness is named outright: at conviction 51+ this is a KEEP, so the call rests on a judgment about conviction rather than on any cushion in the numbers. It is falsifiable against tomorrow — if volatility or index re-enter defensive, f should go back up, and this note is what will make that legible.

Heartbeat written: `ops.heartbeat` `('loop:park_allocator', 'VOO call, status=BOUND')`.

---

## RECOMMENDED ACTIONS

- **Park conversion — RE-RISK the park from `target_f_pct` 50 to 25** (risk sleeve VOO 75%, defensive sleeve SGOV 25%), per the BOUND call above. Sell ~37.1487 SGOV and buy ~5.3288 VOO, ~$3,735.67 per leg against a park market value of $15,171.72 and an `actual_f_pct_before` of 49.6226%. Originating `events.decision_log` entry `f0d2e48d-ad0d-41ee-a385-3fb6977ae704`.
- **Watchlist adds — six names to the Strategy B new-entry candidates state index** (index-only; **no** thesis construction routed, because B is `DO-NOT-ACTIVATE`), each with qualifying event date **2026-09-17** and a ~2026-10-01 ten-trading-day window anchored on the event date per the ANCHOR PIN: **GNRC**, **VICR**, **SDGR**, **MRNA**, **SMR**, **INTC**. Originating D1 `research-screen` decision `a913941a-3df1-43c5-916c-e77868c63da7`.

**No exits triggered. No add candidates flagged. No router review recommended.**

```yaml d1_actions
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: >-
    PARK CONVERSION (not a strategy router review): execute the BOUND re-risk from target_f_pct 50
    to 25, risk sleeve VOO 75% / defensive sleeve SGOV 25%. Sell ~37.1487 SGOV, buy ~5.3288 VOO,
    ~$3,735.67 per leg; park market value $15,171.72, actual_f_pct_before 49.6226%, convergence band
    24.6226pp. Both axes that built the f=50 position (volatility, index) exited defensive this
    session; zero entered. Originating decision f0d2e48d-ad0d-41ee-a385-3fb6977ae704.
- action: watchlist
  ticker: GNRC
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE). +18.3370% close-to-close 175.11 -> 207.23, IBKR RTH daily
    bars contract 72529783, on the up-to-$8B Amazon data-center backup-generator supply deal
    disclosed by regulatory filing plus a warrant for ~3% of shares. Clears B Entry criterion 1's
    frozen >=5% floor. 10-trading-day window anchored on the qualifying event date 2026-09-17
    (~2026-10-01) per the ANCHOR PIN. Cap $12.20B (FMP profile-symbol). Prior GNRC B item
    (due_date 2026-06-28) is complete and carries a different qualifying event date, so this is a
    distinct later event, not a duplicate.
- action: watchlist
  ticker: VICR
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +17.6608% close-to-close 183.91 -> 216.39, IBKR RTH daily bars contract 275759, on two New
    Hampshire sites acquired for ChiP Fab-2/Fab-3, a VPD technology licence to a major AI OEM, a
    $150M buyback, and backlog up 145%. Window ~2026-10-01 anchored on 2026-09-17. Cap $9.81B
    (FMP profile-symbol). No prior VICR queue row of any status exists.
- action: watchlist
  ticker: SDGR
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +26.3766% close-to-close 23.93 -> 30.24, IBKR RTH daily bars contract 402800760, on the
    formation of the "Tectora" JV contributing two early-stage small-molecule programs for equity
    and royalties. NOTE FOR THE THESIS SESSION: the JV economics are UNDISCLOSED, and cap $2.26B
    (FMP profile-symbol) sits only ~13% above the $2B rail, inside the ~30% band where the FMP
    implied share count is untrustworthy — the documented error runs toward understatement, so the
    rail call is safe in the direction that matters. Window ~2026-10-01 anchored on 2026-09-17.
- action: watchlist
  ticker: MRNA
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +8.5495% close-to-close 145.62 -> 158.07, IBKR RTH daily bars contract 344809106, on Phase 3
    progress for the intismeran personalised cancer vaccine presented at the Morgan Stanley Global
    Healthcare Conference. NOTE: conference-presented PROGRESS, not a topline readout. Window
    ~2026-10-01 anchored on 2026-09-17. Cap $62.72B (FMP profile-symbol). Prior MRNA B item
    (due_date 2026-07-12) is complete with a different qualifying event date — distinct event.
- action: watchlist
  ticker: SMR
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +8.9157% close-to-close 8.30 -> 9.04, IBKR RTH daily bars contract 559289446, on fabrication
    of first-of-a-kind boron-oxide pellets for a passive emergency cooling system on an
    NRC-approved design. Cap $2.70B (FMP profile-symbol) — inside the ~30% understatement band
    above the rail, and SMR is the very name the FMP TIER MATRIX records as understated ~30%, so
    it clears either way. Window ~2026-10-01 anchored on 2026-09-17.
- action: watchlist
  ticker: INTC
  strategy: B
  qualifying_event_date: 2026-09-17
  source_research_screen_id: a913941a-3df1-43c5-916c-e77868c63da7
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, B DO-NOT-ACTIVATE).
    +7.6695% close-to-close 101.05 -> 108.80, IBKR RTH daily bars contract 270639, on analyst
    target hikes (Tigress $145, Northland Outperform) plus REPORTED SK Hynix memory-production
    talks. CAVEAT CARRIED TO THE THESIS SESSION: the SK Hynix leg is a REPORT, not a company
    announcement, and criterion 1 wants a public event — weigh that before treating it as one.
    Window ~2026-10-01 anchored on 2026-09-17. Cap $548.79B (FMP profile-symbol). Prior INTC B
    item (due_date 2026-06-21/22) is complete with a different qualifying event date.
```

---

*Metered spend this run: 117 logged `ops.web_calls` rows — 31 Tavily (~37 credits, a floor), 30 FMP, 55 `web_search`/`web_fetch`, 1 HF. IBKR and BigQuery calls are free and are not billed telemetry.*

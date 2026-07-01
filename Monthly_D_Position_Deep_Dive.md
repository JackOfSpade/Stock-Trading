2026-07

# Monthly D Position Deep-Dive — July 2026 cycle (prior-month review window 2026-06-02 → 2026-07-01)

**IMMEDIATE-ACTION flag:** none. No D position shows material thesis invalidation this cycle. All RTX (6/6) and DIS (5/5) at-entry invalidation criteria are NOT-TRIPPED.

**Scope.** Strategy D currently holds **2 open positions** (per `state.current_positions` / IBKR `get_account_positions`, verified 2026-07-01):
- **RTX** — OPEN 2026-04-27 — **0.1601 sh** @ $176.90 avg (cost basis $28.32 incl comm + 6/12 DRIP) — Subtype A / trend-continuation-with-passed-catalyst (12–24 month deep-cyclical recovery + secular aftermarket compounder; falsifiable milestone re-eval Q1'27).
- **DIS** — OPEN 2026-05-07 — **0.28 sh** @ $111.45 avg (cost basis $31.21 incl comm) — Subtype B (trend-continuation: Entertainment SVOD operating margin ≥10% sustained + FY26 ~12% adj-EPS growth reaffirmed + buyback ≥$8B).

**D engine state (informational; not exit-triggering).** `perf.strategy_daily` 2026-06-30: deployed_unit_value **0.9829** (−1.71% total return on deployed capital), peak 1.0093, current_drawdown **−2.62%**, sgov_index 1.0063, **excess_vs_sgov −2.33%**, deployed_days 45, closed_trades 0, gate_n 30. All kill flags FALSE (`perf.kill_flags`). The 30-trade gate (0/30) and the mark-to-market underperformance trigger (needs ≥756 deployed days) are both structurally inactive for D — documented, expected, not a flaw. D NAV ≈ $1,880–1,890 (RTX mark $30.44 + DIS mark $27.29 + SGOV park). 2/5 minimum-position-floor; concurrent-position cap REMOVED per Rev 35; 30%-of-NAV per-sector + 2%-per-position size caps retained. Sector exposure: Industrials/Aerospace & Defense ~1.6% (RTX); Communication Services/Entertainment ~1.4% (DIS); both deeply within the 30% cap.

**Router state at review (informational; does NOT alter disposition).** D router technical signal = **ACTIVATE** (SPY Trend NEUTRAL; Yield-Curve Sustained-Inversion NOT-SUSTAINED). The prior cycle's fundamental-axis flip-to-DNA was **rejected**: `div-D-202605-1` orchestrator resolved 2026-06-03 — "M1b flip-to-DNA rejected; M5-imposed new-entry block LIFTED; RTX/DIS run to thesis-invalidation." Current `state.current_regime` fundamental axis (2026-07-01 M1a): **reflation-tilt + neutral risk** (stable/re-firmed growth, reaccelerating inflation, hawkish Fed, neutral risk, latent Iran shock). Per Strategy.md "router-deactivation-does-not-force-exits" and Experiment_Parameters.md, both positions run to their position-specific thesis-invalidation menus regardless of any regime read. Disposition below is criterion-driven, NOT regime-driven.

**Review window** covers structural developments 2026-06-02 → 2026-07-01 (the month since the prior M3/M4 review closed at 2026-06-02): investor-conference commentary, defense-contract wave, FY27 appropriations progress, FCC/ABC procedural escalation, competitive-landscape shifts, and the June price action. No mechanical exit (convergence / time-based) was triggered by D1's daily connector sweep on either name across the window (D has no near-term convergence target and no time-based exit — long-horizon by design). Prior-cycle M3/M4 2026-06 recommended HOLD on both with all invalidation criteria NOT-TRIPPED.

---

## Position 1 — RTX (Strategy D — future-dated-catalyst / backlog-conversion)

### 1. Current thesis status

**Original thesis** (Decision_Log 2026-04-26 GO): 12–24 month deep-cyclical recovery + secular aftermarket compounder. Q1'26 8-K beat-and-raise anchored the entry — revenue $22.1B (+10% organic), adj EPS $1.78 (+21%), **backlog $271B (+25% YoY; $162B commercial / $109B defense)**, FY26 guide raised to adj sales $92.5–93.5B / adj EPS $6.70–6.90 / FCF $8.25–8.75B reaffirmed. Counter-cycle entry texture: trailing-30-day −16% into a sentiment-driven (tariff/Iran-premium-fade) pullback, not a thesis break. Falsifiable milestone (re-eval by Q1'27): AOGs down ≥25% from YE2025; GTF Advantage EIS in 2026; backlog ≥$280B by Q1'27; FY26 adj EPS within $6.70–6.90; defense organic growth ≥mid-single-digits each quarter.

**Does the thesis still hold after the prior month's developments? YES — a quiet, constructive month; thesis intact and marginally reinforced.** No 8-K bombshell, no guidance change, no adverse Airbus ruling, no new GTF charge. The window's material items are all directionally supportive: (a) backlog-accretive defense awards (AIM-9X $1.1B, SPY-6 $515M); (b) FY27 defense-appropriations momentum (House full-committee markup passed 34–27 on 6/24, a ~$1T munitions-heavy bill); and (c) a **~+9% June share-price rally** (a market re-rating toward the thesis, not a trigger). No development trips any of the six invalidation criteria.

### 2. Multi-year driver check

Per the at-entry driver decomposition (Decision_Log 2026-04-26):

| Driver pillar | Observable progress / status (window 2026-06-02 → 2026-07-01) | Direction |
|---|---|---|
| **(a) GTF Advantage EIS 2026** | EASA aircraft-level certification of the GTF-Advantage-powered A320neo family cleared **2026-04-17** — "the final regulatory approval before commercial service begins later in 2026." Bernstein 5/29 (Calio, just pre-window): certification achieved; ~two-year production cut-over (production standard ~2028). **EIS 2026 (in-year) reaffirmed** — well inside the Q1'27 invalidation bar. Criterion (iii) NOT-TRIPPED. | **On-track** |
| **(b) Powder-metal → aftermarket conversion (HS+ / P&W MRO)** | Collins Aerospace opened an expanded 22,000 m² landing-gear plant in Tajęcina, Poland (~$69M, 6/2) — incremental footprint complementing P&W's Rzeszów expansion. Hot Section Plus (HS+) narrative intact: existing GTF operators can capture 90–95% of durability benefit at shop visits — the conversion-to-annuity mechanic. **No new powder-metal/durability quality event or incremental charge** in-window (only the legacy 2023 $3–3.5B stands). Criterion (ii) NOT-TRIPPED. | **Progressing — incremental capacity commitment** |
| **(c) Backlog $271B (2.9× FY26 sales)** | Fresh in-window defense bookings ≥$1.6B: **AIM-9X Block II $1.1B U.S. Navy (6/26)** incl. allied FMS; **SPY-6 radar $515M U.S. Navy (6/3)** sole-source follow-on. (The $904.6M LTAMDS LRIP and $6.6B F135 awards re-circulated in June are pre-window — Q2 bookings, not June events.) Criterion (iv) requires TWO consecutive quarterly declines; next backlog read is the **Q2'26 print 2026-07-23**. | **On-track — multi-billion in-window adds** |
| **(d) AOG trough easing** | No new public AOG datapoint in-window (Q1 metrics: PW1100 AOGs −15% sequentially, MRO output +23% YoY, GTF Advantage 50M flight hours, 8,000-engine backlog). Bernstein 5/29 reaffirmed "exceptionally strong" demand across all three segments. Independent verification deferred to the Q2'26 print 7/23. | **Indeterminate-but-not-reversed** (consistent with multi-year cadence) |
| **(e) Defense organic growth tail through FY27** | The month's biggest structural item is a **tailwind**: House Defense full-committee markup **passed 34–27 (6/24)** a ~$1T base bill, munitions-heavy — **$10.6B for critical legacy munitions incl. PAC-3, THAAD, Tomahawk** (all RTX/Raytheon-relevant) plus multiyear munitions authorizations — atop the admin's ~$1.5T FY27 national-security request. Defense procurement trending **up**, not down. Criterion (vi) NOT-TRIPPED. | **On-track — strengthened by FY27 appropriations** |

**Net driver-level read:** five pillars assessed; four on-track or progressing positively; (d) AOG trough indeterminate but with no contradicting evidence. No driver stalled or reversed. Pillar (e) is materially reinforced by the FY27 markup. Capital-allocation confidence vector intact (7.4% dividend raise to $0.73/qtr, paid 6/11).

### 3. Fundamental developments (window 2026-06-02 → 2026-07-01)

- **2026-06-02 — Collins Aerospace opened expanded landing-gear plant, Tajęcina, Poland** (~$69M, 22,000 m²). Capacity/footprint. Source: rtx.com / StockTitan.
- **2026-06-03 — $515M U.S. Navy SPY-6 radar contract** (Raytheon, Andover) — sole-source follow-on to the June-2025 Integration & Production Support contract; upgrades Flight IIA destroyers to SPY-6(V)4; Germany FMS optionality. Source: rtx.com news-center 2026/06/03.
- **2026-06-08–09 — ITA Airways (Italy) signals it may sue Pratt & Whitney within "6–8 weeks"** over GTF groundings (~20% of its ~80-aircraft fleet), calling P&W's compensation proposal "not sufficient." A *threat to file*, separate from the Airbus matter and not yet a claim against RTX. Source: ClaimsJournal 2026-06-09. **New watch item** (does not touch the invalidation menu).
- **2026-06-11 — Dividend paid $0.73/sh** (raised +7.4%, declared 4/30; record 5/22). In-window cash event; already DRIP-reinvested (0.1595→0.1601 sh per D2 2026-06-12 reconciliation).
- **2026-06-11 / 06-24 — House FY27 defense appropriations markups** (subcommittee 6/11; full-committee passed **34–27 on 6/24**), ~$1T munitions-heavy bill (PAC-3/THAAD/Tomahawk $10.6B). Source: Breaking Defense; CRFB Appropriations Watch 6/25.
- **2026-06-26 — $1.1B U.S. Navy AIM-9X Block II missile contract** (Raytheon, Tucson) incl. allied FMS. Source: rtx.com news-center 2026/06/26; RealClearDefense.
- **2026-06-30 — RTX confirmed Q2'26 earnings date: Thursday, 2026-07-23, before market open** (call 7:30 a.m. ET). Source: RTX/PRNewswire 6/30. (MarketBeat's "July 28" is an algorithmic estimate and is superseded by the company-confirmed 7/23.)
- **No in-window 8-K of material substance** (June EDGAR activity = routine Form 4s / director phantom-stock grants / 11-K / SD per RTX IR & filing aggregators; direct EDGAR fetch returned 403 — low residual chance a minor 8-K is unlisted).
- **No management turnover / restructuring / strategy change.** CEO/Chair Chris Calio, CFO Neil Mitchill, Collins president Troy Brunk all in place.
- **Airbus damages claim:** no ruling, quantification, or settlement in-window — still at the Reuters 2026-03-19 "pursuing a formal damages claim" stage.

### 4. Invalidation criteria check

Per Decision_Log 2026-04-26 (price-based criterion dropped at entry per Strategy D no-stop rule) — all six checked against in-window evidence:

- **(i) Material adverse Airbus damages ruling > $2B** — **NOT-TRIPPED.** No ruling/quantification/settlement; open claim at the March-19 stage. (ITA Airways 6/8–9 suit *threat* is a separate matter, not against RTX, not quantified — tracked, not triggering.)
- **(ii) New powder-metal-style mass quality event > $1B incremental charge** — **NOT-TRIPPED.** No new defect campaign or charge; only the legacy 2023 $3–3.5B stands. Largo/Poland MRO buildout is the annuity-conversion narrative, not a charge.
- **(iii) GTF Advantage EIS slips beyond Q1'27** — **NOT-TRIPPED.** EASA aircraft-level cert 2026-04-17; EIS guided **2026 (in-year)**, reaffirmed at Bernstein 5/29. No slip signal.
- **(iv) Backlog declines two consecutive quarters** — **NOT-TRIPPED.** Q1'26 backlog $271B (+25% YoY); ≥$1.6B fresh in-window awards (AIM-9X + SPY-6). Next read Q2'26 print 2026-07-23.
- **(v) FY26 FCF guide cut below $7.5B floor** — **NOT-TRIPPED.** FCF confirmed **$8.25–$8.75B**; no in-window revision. ⚠️ *Data-quality flag:* an Investing.com Bernstein-conference (5/29) transcript rendered FCF as "$7.0–$7.5B" — this contradicts RTX's own Q1 press release and matches the stale 2025-vintage GTF-episode figure; treated as a **transcription artifact**, not a guide cut. No RTX primary source lowers FY26 FCF.
- **(vi) FY27 defense procurement cut ≥10% YoY** — **NOT-TRIPPED.** Opposite direction: House FY27 markup (passed 34–27, 6/24) is a ~$1T munitions-heavy bill atop a ~$1.5T FY27 request. Procurement is trending up.

**All six criteria NOT-TRIPPED as of 2026-07-01.**

### 5. Sector and theme context

- **Aerospace & Defense (GICS Industrials).** The dominant in-window sector item is the **FY27 appropriations tailwind** (House markup passed; munitions-heavy) — structurally supportive of the multi-year defense case. RTX is the sole A&D name in the D book; no theme over-concentration.
- **Defense-contracting regulatory overhang (structural, not new, not triggering).** The Trump EO "Prioritizing the Warfighter in Defense Contracting" (2026-01-07) empowers the Secretary of War to designate "underperforming" contractors and **restrict dividends/buybacks/exec comp**. As of this window there is **no public evidence RTX has been designated** — the process is review-and-remediate. Not in the invalidation menu; monitored as a capital-allocation tail risk.
- **Commercial aerospace.** Sole-engine supplier to A220 + ~40% of A320neo via the PW1000G family; GTF Advantage phased transition (production standard ~2028) intact. Competitor GE Aerospace targeting a record ~2,000 LEAP deliveries in 2026 (record backlog) — no competitive disruption to RTX's aftermarket/backlog thesis. Note: 2026's major air show is **Farnborough (mid-July, just after the window)** — a potential order catalyst for the Q2-print cycle.
- **Macro overlay.** Iran conflict de-escalated further (mid-June ceasefire framework; Brent back to pre-war ~$73) — the defense-premium fade is a headline factor only; RTX criteria (i)–(vi) are structural (aftermarket / backlog / GTF / FCF / procurement) and NOT geopolitically-indexed. Reflation-tilt regime is not in the invalidation menu.

### 6. Long-term tax treatment

- **12-month LTCG-eligible date: 2027-04-28** (entry 2026-04-27 + "more than one year"). Time elapsed at review 2026-07-01: **~65 days**; ~301 days to the LTCG line.
- Strategy.md LTCG-coordination preference applies only when exiting on thesis completion. No in-window completion signal; the Q1'27 falsifiable-milestone gate is the relevant cadence and sits ~10 months out — LTCG will be reached well before any natural completion review. No LTCG coordination operative this cycle.
- STCG risk if invalidation fires within ~10 months: all invalidation criteria are structural (multi-billion damages ruling, mass quality event, EIS slip, two-quarter backlog decline, FCF cut, procurement cut); none has a near-term trigger probability above noise. Accepted residual per Strategy.md money-loss scenario #6 / Constraint 3.

### Mark-to-market (informational; not exit-triggering)

- 2026-07-01 live $190.15 (IBKR snapshot); 6/30 close $189.73; 7/1 close $190.18. Position mark **0.1601 × $190.15 = $30.44** vs cost basis $28.32 = **+$2.12 / +7.5%** — a swing to positive from the prior cycle's −1.49%. June trajectory: $174.26 (6/2) → intramonth low ~$172.55 (6/2/6/3) → **~+9.0% for June**, intramonth high ~$194.17 (6/23 intraday), settling ~$190. YTD ~+4.0%; 52-week range ~$141.30–$214.41. Div yield ~1.46%.
- The mark improvement is a market re-rating toward the thesis, NOT a signal in the invalidation menu; Strategy D marks are informational only.

### Recommendation — RTX

**HOLD.** All six invalidation criteria NOT-TRIPPED. Five driver pillars on-track or progressing; pillar (e) reinforced by the FY27 House markup; backlog accretion continued (AIM-9X $1.1B + SPY-6 $515M). GTF Advantage EIS 2026 reaffirmed. FY26 FCF guide unchanged ($8.25–8.75B). Airbus litigation still unresolved; the new ITA Airways P&W-suit threat is separate and non-quantified. Mark +7.5% is within long-horizon noise and non-triggering. No completion signal; no research gap. **Next structural read: Q2'26 print 2026-07-23** (backlog test of criterion iv, any FY26 guide revision, GTF Advantage EIS reiteration, Airbus commentary). No second-look invalidation criterion to flag; no research deferral required.

---

## Position 2 — DIS (Strategy D — Subtype B, trend-continuation)

### 1. Current thesis status

**Original thesis** (Decision_Log 2026-05-07 GO): Subtype B trend-continuation anchored to **Entertainment SVOD operating margin sustained ≥10% over 12+ forward months + FY26 ~12% adj-EPS growth reaffirmed + buyback ≥$8B**. Two-observation trend evidence at entry: Q1 FY26 8.4% → Q2 FY26 10.6% (streaming OI $582M, +88% YoY). Primary driver explicitly reframed at the 2026-05-07 re-screen from a "management-execution-quality" (D'Amaro) framing to a **financial-metric-traceable** thesis (Strategy.md Subtype B / Constraint 3); KL #4 management-execution residual treated as a bounded secondary driver.

**Does the thesis still hold after the prior month's developments? YES — anchors intact and unchallenged; quiet on hard corporate news; price weak but non-criterion.** June produced **no 8-K, no guidance change, and no management conference appearance** — so no new data point moved the standing thesis in either direction. The three quantitative anchors (SVOD margin ≥10%, ~12% FY26 adj-EPS growth, ≥$8B buyback) carry unchanged from the 5/6 Q2 print / 5/14 MoffettNathanson reaffirmation. The one live risk — the FCC/ABC license review — **escalated procedurally** (third-party petitions-to-deny; deadline passed 6/29) but produced **no final order** and **no Disney material-adverse 8-K**, so both arms of criterion (v) fail. The salient dissonance is the tape (−5.2% June, ~−14% YTD, near 52-week lows) versus unchanged fundamentals — a Strategy-D trend-continuation watch-item, not an invalidation.

### 2. Multi-year driver check

Per Decision_Log 2026-05-07 driver decomposition (Subtype B financial-metric-traceable):

| Driver pillar | Observable progress / status (window 2026-06-02 → 2026-07-01) | Direction |
|---|---|---|
| **(a) Entertainment SVOD operating margin ≥10% sustained 12+ forward months** | No new in-window print (latest = Q2 FY26 10.6% vs Q1 8.4%; FY26 "at least 10%" reaffirmed at Q2 + MoffettNathanson 5/14). Next datapoint Q3 FY26 print (~early-to-mid Aug). Industry read-through supportive: **Peacock (NBCUniversal) said 6/2 it will be "profitable in Q2"** — first-ever streaming profit, corroborating durable DTC-margin structure. Criterion (i) requires <8% for 2 consecutive quarters — NOT-TRIPPED. | **On-track — no negative datapoint; industry inflection corroborates** |
| **(b) FY26 ~12% adj-EPS growth reaffirmed** | Guide unchanged from the 5/6 Q2 print (~12% ex-53rd-week / ~16% incl.; FY27 double-digit reiterated). No pre-announcement, no 8-K, no guidance revision in-window. Criterion (ii) requires a cut to ≤6% — NOT-TRIPPED. | **On-track — unchanged** |
| **(c) Buyback ≥$8B FY26** | Raised to ≥$8B at the 5/6 Q2 print ("betting $8 billion on our own stock"); no suspension 8-K; H1 pace disclosure lands with the Q3 10-Q. Criterion (iii) requires ≤$3B H1 / ≤$5B Q3 / suspension — NOT-TRIPPED. | **On-track — unchanged** |
| **(d) Experiences / Parks durability** (secondary, not in invalidation menu) | **Shanghai Disney 10th anniversary (6/15–16)**: D'Amaro on-site; park crossed ~100M cumulative guests, framed as bucking the broad Chinese consumer pullback. **"50 states" economic-impact report (6/23)**: ~$67B annual U.S. impact / 403k+ jobs; **restated** the existing ~$30B U.S. parks investment through 2033 (no new capex). Forward bookings +5% (from Q2). No deterioration signal. | **On-track — capital commitment restated** |
| **(e) FCC TV-license overhang (criterion (v) boundary case)** | FCC review of Disney's 8 ABC O&O stations (MB Docket 26-131) advanced **procedurally only**: Disney filed renewals "under protest" (5/28); petitions-to-deny deadline **6/29** drew multiple third-party filings (whistleblower ~6/9–11; Center for American Rights 6/13; conservative groups 6/26–29; and, unusually, a *pro-Disney* petition 6/26–29). **NO final order, NO Hearing Designation Order, NO license restriction issued in June; NO Disney 8-K.** Opposition/reply cycle runs into August; Disney has signaled a court challenge ("can play out in courts for years"). | **Open watch — neither arm of the (v) conjunction has fired** |

**Net driver-level read:** all five tracked pillars on-track or progressing. The three quantitative anchors (a)/(b)/(c) carry unchallenged (no negative in-window datapoint; next test is Q3). Driver (e) escalated procedurally without crossing the criterion-(v) conjunction. The thesis remains one verification print (Q2 5/6) + one CFO reaffirmation (5/14) into a 12+ month metric-trajectory regime; the next thesis-moving datapoint is the Q3 FY26 print.

### 3. Fundamental developments (window 2026-06-02 → 2026-07-01)

- **2026-06-02 — Peacock/NBCUniversal (Evercore TMT): Peacock "will be profitable in Q2"** — first-ever streaming profit; signals industry-wide DTC-profitability inflection. Source: Deadline 6/2.
- **2026-06-09 to 06-29 — FCC/ABC license review procedural escalation.** Petition-to-deny cycle (Public Notice DA 26-541): deadline **6/29**; oppositions 7/29; replies 8/5. Multiple third-party petitions filed (whistleblower, Center for American Rights 6/13, conservative groups, plus a pro-Disney petition). Sources: Communications Daily; Guardian 6/13; Politico 6/29; The Desk 6/29. **No final FCC order; no Disney 8-K.**
- **2026-06-15–16 — Shanghai Disney 10th anniversary**; D'Amaro on-site; ~100M cumulative guests; second-gate speculation unconfirmed (a new hotel appears to be the actual announcement). Source: CNBC 6/19.
- **2026-06-23 — "50 states" economic-impact report** (~$67B U.S. impact; restates ~$30B U.S. parks investment through 2033). Source: thewaltdisneycompany.com.
- **2026-06-24 — Avatar: Fire and Ash arrives on Disney+** (content driver). No standalone Disney+ price change in June (last hike Oct 2025).
- **2026-06-30 — Semiannual dividend $0.75/sh ex-date** (declared 11/13/2025; payable 7/22/2026). The June event is the ex-date passing, not a new declaration. TTM $1.50, yield ~1.5%. (~$0.75 of the 6/29→6/30 price drop is mechanical ex-div.)
- **Hulu consolidation:** continuation of the pre-window (Variety 5/19) integration reporting; a Disney rep stated **"no current plans to sunset the Hulu app."** Framed purely as a consumer app/tech-stack matter; **no source indicates a change to SEC segment reporting** of Entertainment SVOD operating income.
- **No 8-K in the window** (verified against the authoritative `data.sec.gov` submissions API, CIK 0001744489; last 8-K = 5/6 Q2 earnings). Routine Form 4s (RSU vesting/withholding, no discretionary selling) + two Form 11-K only. No pre-announcement, no guidance revision, no material-adverse business update.
- **CEO succession — no June development.** Josh D'Amaro is the **sitting CEO** (effective 2026-03-18 annual meeting); Bob Iger is a senior adviser/board member retiring 2026-12-31; Dana Walden is President & CCO. June items are commentary/retrospectives only.
- **ESPN layoffs** (reported 6/4) tied to NFL Media integration — another summer round; no named executive departures. (Aggregator-sourced; headcount unconfirmed.)

### 4. Invalidation criteria check

Per Decision_Log 2026-05-07 (no price-based stop) — all five checked against in-window evidence:

- **(i) Entertainment SVOD operating margin falls below 8% for 2 consecutive quarters** — **NOT-TRIPPED.** Q1 FY26 8.4% / Q2 FY26 10.6% (both >8%; rising, not falling). No in-window print. FY26 ≥10% target reaffirmed. Next read Q3 (~early-to-mid Aug).
- **(ii) FY26 adj-EPS growth guide cut to ≤6% (>6pp cut from ~12%)** — **NOT-TRIPPED.** Guide unchanged at ~12%; no in-window guidance change, pre-announcement, or 8-K.
- **(iii) FY26 buyback pace fall (≤$3B H1 / ≤$5B Q3 / suspension 8-K)** — **NOT-TRIPPED.** Target raised to ≥$8B at Q2; no suspension; H1 pace lands with the Q3 10-Q. Management framing intact.
- **(iv) Metric-immutability auto-invalidation: SVOD operating income/margin no longer reported in current form for ≥2 consecutive quarters** — **NOT-TRIPPED.** The non-GAAP "Entertainment SVOD operating income (excl. Hulu Live TV/DMVPD)" measure was reported identically in Q1 (8.4%) and Q2 (10.6%) FY26. **Hulu app consolidation is a consumer-app/tech-stack matter, not a segment-reporting change** ("no current plans to sunset the Hulu app"). *Caveat: absence-of-evidence; definitive confirmation at the Q3 print.*
- **(v) FCC issues a FINAL order materially restricting Disney TV-station ownership AND Disney 8-Ks it as material adverse to the FY26/FY27 EPS framework (BOTH arms)** — **NOT-TRIPPED.** **Arm 1 FALSE:** no final order — proceeding is in the petition-to-deny phase (deadline 6/29; replies to 8/5), any decision and Disney's signaled court challenge beyond the window. **Arm 2 FALSE:** no 8-K on the FCC matter; only a single non-quantified 10-Q risk-factor sentence with no "material adverse effect" characterization. Both required arms fail.

**All five criteria NOT-TRIPPED as of 2026-07-01.**

### 5. Sector and theme context

- **Streaming-margin pivot (GICS Communication Services / Entertainment).** The primary sector frame. **Peacock's Q2 profitability call (6/2)** corroborates the structural durability of DTC margins (supportive of the thesis mechanic) — while also signaling more profitable competition. Netflix remains the ~30%-margin structural reference; Disney positioned as a credible #2 SVOD-margin story.
- **Competitive consolidation watch-item — Paramount / Warner Bros Discovery.** The Paramount-Skydance/WBD deal (won by Paramount, Feb 2026) cleared through June: China approval 6/17; UK CMA Phase 1 launched 6/9 (decision due 8/7); **UK Culture Secretary "minded to intervene" on media-plurality grounds 6/30**. If cleared, Paramount+ folds into HBO Max → a ~200M-sub platform, a scaled Disney+/Netflix competitor. **A structural multi-year competitive-landscape item to track**, though it does not touch DIS's financial-metric-traceable invalidation menu (which tests Disney's own margin/EPS/buyback, not competitor scale).
- **Regulatory-overhang theme (FCC ABC stations).** Open, purely procedural; criterion (v) conjunction requires a final order + a Disney material-adverse 8-K. Multi-quarter (potentially multi-year) resolution horizon.
- **Experiences theme.** Shanghai 10th-anniversary strength + the restated ~$30B U.S. parks investment through 2033 reinforce the secondary Parks read-through; no deterioration.
- **Macro overlay.** Reflation-tilt + hawkish-Fed regime pressures long-duration earnings streams broadly, but DIS's invalidation menu contains no discount-rate / inflation / consumer-sentiment threshold; the macro tilt argues for prudent watchful holding (which is what is recommended), not exit under Strategy D rules.
- **Theme-concentration / correlation.** DIS is the sole Comm-Services name; RTX is Industrials — no over-concentration. In-window the two moved oppositely (RTX +9%, DIS −5%), reinforcing the estimated 0.20–0.35 pairwise correlation (below the 0.6 entry / 0.7 post-entry thresholds); no classical-method recomputation warranted.

### 6. Long-term tax treatment

- **12-month LTCG-eligible date: 2027-05-08** (entry 2026-05-07 + "more than one year"). Time elapsed at review 2026-07-01: **~55 days**; ~311 days to the LTCG line.
- Subtype B's 12+ month verification window (Q3 FY26 → Q4 FY26 → Q1 FY27) extends past LTCG eligibility by design; no LTCG-line coordination operative this cycle.
- STCG risk if invalidation fires within ~10 months: the menu is quantitative-threshold-based with intrinsic 2-consecutive-quarter inertia; only criterion (v) has a non-zero near-term probability, and its conjunction (final order + material-adverse 8-K) is multi-quarter. STCG residual bounded by the menu's structure.

### Mark-to-market (informational; not exit-triggering)

- 2026-07-01 live $97.42 (IBKR); 6/30 close $96.25; 7/1 close $97.41. Position mark **0.28 × $97.42 = $27.29** vs cost basis $31.21 = **−$3.92 / −12.6%** — widened from the prior cycle's −9.04%. June trajectory: $101.41 (6/2) → brief bounce to $103.89 (6/18) → rolled to $96.25 (6/30) → $97.41 (7/1); **−5.2% June, ~−14% YTD**, trading below the 50-DMA (~$102) and 200-DMA (~$107), near the 52-week low ($92.19–$124.61 range). ~$0.75 of the late-June drop is the mechanical 6/30 ex-dividend.
- The weakness is **non-criterion** — no Strategy D long-position invalidation fires on price action alone. The market appears to be discounting (1) the reflation-tilt / long-duration-earnings macro; (2) FCC-overhang ambiguity (visible petition-to-deny escalation); (3) Hulu-consolidation consumer uncertainty (even though margin-supportive); (4) pre-Q3-print de-risking. None crosses the (i)–(v) menu. The May-6 post-print pop (~$118–120 intraday) has been fully given back — a give-back, not a fresh negative disclosure.

### Recommendation — DIS

**HOLD.** All five invalidation criteria NOT-TRIPPED. All five driver pillars on-track or progressing; the three quantitative anchors carry unchallenged (no negative in-window datapoint). The FCC/ABC review escalated only procedurally and remains far from the criterion-(v) conjunction (no final order; no material-adverse 8-K). Hulu consolidation is margin-supportive and not a metric-immutability event. Mark −12.6% is within long-horizon noise on a 12+ month thesis and is NOT exit-triggering per Strategy D rules; the price/fundamental dissonance is a trend-continuation watch-item into the Q3 print, not an invalidation. **⚠️ Q3 FY26 earnings-date correction for M4/M5:** the date is NOT officially confirmed as of 2026-07-01; the best-supported estimate is **~2026-08-05 (BMO)** per Wall Street Horizon/MarketBeat (consistent with the Q3-FY25 Aug-6 precedent), not the ~Aug-12 figure carried in prior cycles — re-check Disney IR mid-July. No second-look invalidation criterion to flag; no research deferral required.

---

## Cross-position observations (informational; for M4 / M5 / next-cycle context)

- **Under-deployment indicator now firing (Strategy.md §6 dated failure indicator).** D holds **2/5** positions vs the 5-position floor — this is the **3rd consecutive monthly cycle** below the floor (May→June→July), which reaches the "≥3 consecutive months below 5" threshold. This is a **strategy-deployment-cadence** flag for M4 / the Q2 quarterly-D-candidates feeder, **not** a position-level invalidation (no IMMEDIATE-ACTION). Pipeline into deployment: the Q2 quarterly D-candidates screen and the queued **LLY re-screen (`rescreen-LLY-D-20260914`, due 2026-09-14)** — whose STEP-0 D-activation gate is now **clear** (D router ACTIVATE, div-D-202605-1 resolved), so the LLY re-screen can proceed to a full thesis re-construction on its due date if the entry-timing-failure conditions have normalized. New D entries are unblocked (M5-imposed block lifted 6/3).
- **Correlation matrix.** RTX–DIS estimated 0.20–0.35; in-window divergence (RTX +9% / DIS −5%) reinforces low correlation. Below both 0.6 entry-time and 0.7 post-entry-emergent thresholds. No recompute needed.
- **Sector-concentration drift.** RTX ~1.6% of NAV; DIS ~1.4% of NAV; both far within the 30%-per-sector cap. Not at-risk via price drift.
- **Invalidation-count / edge-decay.** Rolling-36-month thesis-invalidation count = 0 (Strategy D first trade 2026-04-27). Edge-decay flag (≥3 invalidations in any rolling 36-month) far from firing.
- **24-month alpha-test / 36-month m2m-underperformance / 30-trade gate:** all not applicable — D is ~45 deployed days / 0 closed trades; these metrics require 24 / 36 months active and 30 closed trades respectively.
- **Engine (informational).** D deployed_unit_value 0.9829 (−1.71%), drawdown −2.62%, excess_vs_sgov −2.33% at 2026-06-30; all kill flags FALSE. Not exit-triggering.
- **Router.** D ACTIVATE (technical); div-D-202605-1 resolved 2026-06-03 (flip-to-DNA rejected). Even a future flip to DO-NOT-ACTIVATE would not force exits — Strategy.md "router-deactivation-does-not-force-exits."

---

## Output discipline

This file is the M3 deep-research output. M4 (Monthly Action Conversion) reads it and converts the per-position recommendations into orders / queue entries / calendar events. Both positions recommend **HOLD** — no "close" call (so no exit to stage) and no "further research" deferral required — so M4 has no D-side staging action this cycle beyond reading and acknowledging. Two carry-forward notes for M4/M5: (1) the DIS Q3 earnings date is ~Aug-5 (unconfirmed), not ~Aug-12; (2) the D under-deployment indicator reaches its 3-consecutive-cycle threshold this month (deployment-cadence flag, not a position invalidation).

No IMMEDIATE-ACTION flag set.

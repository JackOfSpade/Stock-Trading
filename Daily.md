2026-08-17
<!-- d1_scan_through_utc: 2026-08-17T22:50:00Z -->

# Daily Market Development Scan — 2026-08-17 (Mon, MT)

**Scan window:** 2026-08-16 19:32 MT → 2026-08-17 16:50 MT (**21.3 hours — normal daily cadence, no gap**). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-17T01:32:00Z -->` parsed cleanly from the `Daily.md` on disk and cross-checks against that file's own commit at 2026-08-17T01:34:31Z (agree to within 2.5 minutes — the prior run's write-then-commit interval, not drift). `state.routine_catchup_window` reports `window_days = 0.86`, `never_completed = false` — inside the daily cadence, so **no `CATCHUP` token is owed** on this run.

**The window contains exactly ONE completed trading session — Monday 2026-08-17, today.** `state.trading_day_today` reads `today = 2026-08-17`, `is_trading_day = true`, `last_trading_day = 2026-08-17`, `next_trading_day = 2026-08-18`. Every price, level and percentage in this file is measured from **IBKR regular-session daily bars** (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`), 2026-08-14 close → 2026-08-17 close, unless explicitly labelled otherwise. No figure here comes from `get_price_snapshot`.

**Tape — Monday 2026-08-17 (US cash close).**

| Metric | Close | Change | Source |
|---|---:|---:|---|
| SPY | 772.67 | −0.47% | IBKR RTH daily bar |
| IVV | 776.29 | −0.48% | IBKR RTH daily bar |
| VOO (park vehicle) | 710.27 | −0.47% | IBKR RTH daily bar |
| RSP (equal weight) | 220.79 | **−0.89%** | IBKR RTH daily bar |
| QQQ | 729.87 | −0.16% | IBKR RTH daily bar |
| DIA | 534.19 | −0.49% | IBKR RTH daily bar |
| IWM | 304.06 | −0.34% | IBKR RTH daily bar |
| EFA | 108.45 | −0.17% | IBKR RTH daily bar |
| ^VIX | 15.19 | **+6.60%** (from 14.25) | FMP quote, exact date |
| 10Y UST | 4.72% | +4bp | FMP treasury-rates, exact date |
| 30Y UST | 5.31% | +6bp | FMP treasury-rates, exact date |
| 2Y UST | 4.19% | +2bp | FMP treasury-rates, exact date |
| S&P 500 breadth (% > own 200dma) | **68.38** | **−4.38pp** (from 72.76) | EODData `$S5TH`, source-dated |

Equal-weight underperformed cap-weight by 42bp and 9 of 11 GICS sectors closed lower. **The index level is the least informative number on this page today** — see DEVELOPMENTS 3 and 4.

---

## TL;DR

- **Exits triggered: 1 — MSCI (Strategy B).** Closed 550.68 vs a named invalidation trough of 550.79. Breach by 11 cents, with the "no accompanying new information" leg satisfied on three independent lines. No tolerance band applied, deliberately.
- **New entry candidates: none routed.** A, B and D routers are DO-NOT-ACTIVATE; C is HYBRID-FOMC with its next thesis already queued for 2026-09-08; E is ACTIVATE but today's dispersion is cross-industry-group and does not fit E's mechanism.
- **Add candidates: none.** 14 tranches evaluated, 0 flagged. The best-formed case in months (D:DIS, −7.02% below cost, criteria affirmatively passed) dies on the router, not on merit.
- **Watchlist changes: 2 notes, no disposition changes** — AMAT (first ratification-shaped move against a three-point "beats get sold" shape recorded yesterday) and NOW (a standing 2025-12-15 KeyBanc Underweight, recorded so it is not re-mis-dated).
- **Regime review flag: no review.** `shock_overlay` is already `acute`, its maximum severity, so today's escalation cannot move the axis.
- **Park: KEEP VOO** (MEDIUM, 58 — down from 62). Three numeric invalidation triggers named in advance.

---

# DEVELOPMENTS

## 1. Market-wide breaking events

**The US–Iran 60-day memorandum of understanding EXPIRED on 2026-08-17 with no extension sought.** The President stated he would not seek one and publicly threatened to strike **Oman** — the party mediating the Strait of Hormuz reopening talks — in the phrasing "if Oman gets in the way, we'll bomb the shit out of them." Same-day coverage reported **Hormuz shipping halted**, and parallel escalation in Lebanon alongside a fresh US sanctions push on Iran.
*Sources (all dated on-page 2026-08-17):* [Washington Post](https://www.washingtonpost.com/world/2026/08/17/trump-threatens-bomb-oman-if-it-gets-way/), [Bloomberg](https://www.bloomberg.com/news/articles/2026-08-17/trump-threatens-to-bomb-oman-if-it-gets-in-way-of-us-fox-news-msx5rdoc), [CNN](https://www.cnn.com/2026/08/17/world/live-news/iran-war-trump), [CBS News](https://www.cbsnews.com/live-updates/us-iran-war-deal-expired-strait-of-hormuz/).

**Observable reaction — and it is the interesting part.** Equities gave back only −0.47%. The reaction that did NOT occur is more informative than the one that did: on a geopolitical escalation of this shape the textbook response is a defensive bid — staples up, utilities up, duration up, energy up. **Exactly one of those four happened.** Energy rose (XLE +1.08%) and everything else defensive fell: staples were the *second-worst* sector on the board (XLP −1.64%), utilities fell (XLU −0.29%), and the long end was sold (30Y +6bp, 10Y +4bp). The market priced this as an **oil-and-inflation event, not a demand shock**. That is a falsifiable claim and it is the single most useful read this scan produced.

`shock_overlay` has been scored `acute` since 2026-08-01 — its maximum severity — so this escalation cannot move that axis. What it changes is the measured *channel*: the shock now reaches the book through rates and input costs rather than through growth.

## 2. Scheduled events that resolved in window

**Earnings: NONE from any US-listed issuer at or above $2B market cap.** This was verified rather than assumed, because an empty calendar result is exactly the shape a plan-gated API returns. Four independent lines agree: the FMP earnings calendar (8/16–8/18) returned only BIDU on 8/18; a market recap for the date states plainly that no major earnings were expected; a filings-wire search for the date found no qualifying issuer; and the AMAT verification below independently confirms the season's mid-August lull. **The retail wave lands 2026-08-18 to 08-20** (HD, TGT, LOW, WMT, BIDU) — four of those are on the Strategy A watchlist and none is actionable while A is deactivated.

**Macro releases in window:**

| Indicator | Agency | Actual | Consensus | Prior |
|---|---|---:|---:|---:|
| Empire State Manufacturing (Aug) | NY Fed, 8/17 08:30 ET | **20.6** | ~11.0 | 15.6 |
| NAHB Housing Market Index (Aug) | NAHB, 8/17 10:00 ET | **35** | 33 | 34 |
| China Industrial Production YoY (Jul) | China NBS, 8/17 | **4.5%** | ~5.0% | 5.3% |
| China Retail Sales YoY (Jul) | China NBS, 8/17 | **0.6%** | 1.5% | 1.0% |
| China Fixed-Asset Investment YTD YoY | China NBS, 8/17 | **−6.7%** | ~−6.0% | −5.7% |

Empire State was read directly off the NY Fed's own survey page (MEASURED, primary). The China figures are MEASURED from Reuters wire text but were not cross-checked against `stats.gov.cn` directly, so they carry slightly lower confidence than the two US prints. A large US regional-manufacturing beat alongside a broad China demand miss is a genuinely two-sided input against the standing `growth_momentum = decelerating` score — noted, not acted on; M1a re-scores 2026-09-01.

**Central bank actions: none.** No Fed, ECB, BoE or BoJ decision fell in window; the next major Fed event is Jackson Hole, 2026-08-27 to 08-29.

**Other resolved catalysts:** the **AvalonBay (AVB) / Equity Residential (EQR) merger of equals CLOSED 2026-08-17**, both large-cap REITs, approved by >99% of votes cast. The combined entity is renamed **Vivmark Residential** and begins trading as NYSE: VMRK at the 2026-08-18 open, so there is no observable VMRK reaction inside this session.

**FDA — a near-miss the event-identity gate caught.** Bristol Myers Squibb's iberdomide (Zenbexus) carried a **PDUFA target date of 2026-08-17**, which is inside the window. The actual FDA accelerated approval was granted **2026-08-13**, before the window opens. A calendar date is a schedule, not evidence of a decision; recorded as out-of-window rather than as a resolved event. Regeneron's garetosmab BLA (priority review, "August 2026" target, no day-specific date found) remains **PENDING** — no decision found.

## 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

Logged as `entry_type='research-screen'`, `screen='single-name-move'`, with an append-only correction row (see PROCESS NOTES). Layer-1 rail: ≥$2B market cap, ≥2% close-to-close, identifiable public event. **19 names surfaced. All 19 also cleared the legacy ≥5% bar, so nothing is `below_spec_floor`.**

**The day was one trade, not nineteen.** Sixteen of the nineteen are a single coherent rotation: the **AI-hardware / memory complex was bought across the entire capitalisation range**, and **AI-exposed application software was sold**.

| Name | Move | ~Cap | Event |
|---|---:|---:|---|
| **ARGX** | +16.04% | $62B | Phase 3 ALKIVIA hit primary endpoint, p=0.0011 — dated 8/17, in window |
| **AXTI** | +17.55% | $6B | Late-July Q2 beat repricing — *rejected, stale cause* |
| **CBRS** | +15.07% | $59B | MS Overweight reiteration + OpenAI hardware partnership + Tiger Global stake, 8/17 |
| **SNDK** | +8.88% | $265B | Memory-complex anchor; 8/13 Investor Day targets re-rated 8/17 |
| **CRDO** | +8.82% | $53B | AI-networking, theme |
| **VICR** | +7.99% | $12B | AI-rack power, theme |
| **COHR** | +7.79% | $69B | Optical/AI infrastructure, theme |
| **VIAV** | +6.25% | $11B | Optical test, theme |
| **ONTO** | +5.86% | $17B | Semi metrology, theme |
| **TER** | +5.81% | $69B | Semi test, theme |
| **AEIS** | +5.56% | $14B | Semi power, theme |
| **AMAT** | +5.55% | $425B | **Print was 8/13, NOT today** — see gate note below |
| **MRVL** | +5.54% | $205B | AI silicon, theme |
| **WDC** | +5.35% | $185B | Memory, theme |
| **SITM** | +5.27% | $23B | Timing semis, theme |
| **NOW** | −5.08% | $122B | **No verified same-day catalyst** — see gate note below |
| **STZ** | −6.19% | $17B | Weak attribution: 8/16 13F Berkshire exit — *rejected* |
| **CVNA** | −7.28% | $77B | Prior-date guidance miss + profit-taking — *rejected* |
| **RDDT** | −7.63% | $32B | 8/14 Form 144 insider filings + valuation — *rejected* |

The software leg mostly fell 4–5% and so sits just under the rail: **MDB −4.70%, GTLB −4.93%, MNDY −4.79%, SAIL −4.81%**, alongside NOW. Machines that run the models were bid; businesses selling seats the models might replace were sold.

### EVENT-IDENTITY GATE — it fired twice, and that is worth its own paragraph

Two of roughly thirteen individually-attributed names (~15%) came back with a **real, verifiable, correctly-described event attached to the wrong date — and in both cases the wrong date was today.**

- **AMAT.** Discovery credited today's +5.55% to fiscal Q3 2026 earnings. The issuer places that print on **Thursday 2026-08-13 after close**, where shares *fell* ~4.94% after-hours to $508.15 — which reconciles exactly with the IBKR 2026-08-14 close of 507.18. The print is four days outside this window. Today's move is theme re-rating, not a fresh fundamental surprise.
- **NOW.** Discovery credited today's −5.08% to "a KeyBanc downgrade to Underweight, PT $775, dated 2026-08-17." The downgrade is dated **2025-12-15** (Jackson Ader, Sector Weight → Underweight, on IT back-office employment trends and AI seat-count risk) and has been reiterated since. The **$775 target is a stale pre-split figure**; the post-split equivalent is ~$85, which reconciles with the measured 117.70 close and with the Watchlist row's own CLSA Underperform/$72 reference.

**How the second one was caught, because the method transfers:** $775 on a $117.70 stock is a 6.6× absurdity. An internally inconsistent number is the cheapest available tell that a source is describing a different instrument, a different date, or a different price scale — and checking every quoted price or target against the *measured* price costs nothing. The other defense that worked both times was verifying the event date against the **issuer or originating source**, never the aggregator.

Neither correction touches the rotation finding, which rests on price behaviour across two dozen names rather than on any single name's catalyst.

### Coverage — NOT established as complete

Discovery went past the capped gainers/losers lists (both saturate on sub-$2B micro-caps and structurally *cannot* surface a large-cap 2–8% mover) by screening a cap-filtered universe of ~2,147 mid-cap-and-above names, top 60 rows each direction. **That closed the exact gap that lost COHR (~$64B, −7.99%) on the predecessor run — COHR was surfaced cleanly today.** Cap verification also eliminated 10 of 16 shared-list candidates as sub-$2B (BALY, FTK, ENVX, CUE, EXOD, EYPT, SWMR, FDMT, RCMT, ATTO, UFI, VCX).

**What is still missing: the 2%-to-~4.5% band is essentially unenumerated** — plausibly another 50–150 qualifying names. A further ~40 names were surfaced with ticker/cap/percent but never searched for cause, and the 16 theme names carry sector attribution rather than individually confirmed company press.

## 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (§19)

Logged as `entry_type='research-screen'`, `screen='sector-move'`, with an append-only correction row. Layer-1 rail: ≥1% at sector-ETF level, or notable dispersion.

| XLE | XLK | XLI | XLV | XLU | XLB | XLRE | XLF | XLY | XLP | XLC |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **+1.08** | +0.16 | −0.10 | −0.19 | −0.29 | −0.57 | −0.97 | **−1.00** | **−1.23** | **−1.64** | **−1.89** |

**Five sectors cleared the 1% rail. ZERO cleared the legacy 2% bar** — so this entire screen is an AI-only surfacing, and a fixed 2% rule would have reported a blank day. The day was not blank.

- **XLE +1.08% — HIGH (75).** The only sector up, on the only real macro event, through the exact channel that event transmits through. Small in magnitude, unambiguous in meaning.
- **XLP −1.64% — MEDIUM (60).** Surfaced for *direction*, not size. Staples as the second-worst sector on an escalation day is the observation that falsifies the growth-scare reading.
- **XLC −1.89% — LOW (45), attribution explicitly incomplete.** Worst sector, no clean driver established. Not simply mega-cap internet: GOOGL closed only −0.55%. No constituent decomposition was performed and none is asserted. Held position DIS (−3.14%) sits here and underperformed the sector — recorded, unresolved.
- **XLY −1.23% — LOW (45).** Coherent with the oil channel (retail gasoline ~$4.06/gal) and with positioning into the 8/18–8/20 retail wave. Two adequate explanations, neither established.
- **XLF −1.00% — LOW (30), rejected.** A steepening curve is not obviously bank-negative; a give-back at the rail boundary reads as beta. Surfaced by the rail, judged near-uninformative, recorded as such rather than narrated into meaning.

**Dispersion:** 2.97pp top-to-bottom on a −0.47% index day, 9 of 11 sectors lower, RSP −42bp vs SPY. **Known limitation of this instrument:** the day's largest moves were *intra*-sector — AI-hardware +5–9% against AI-exposed software −4–5% — which cancelled almost perfectly to leave XLK at +0.16%. A sector-ETF screen is structurally blind to that; the single-name screen carries it.

## 5. Notable commentary

- **September Fed-hike odds have repriced hard — but NOT in this window, and the distinction matters.** CME FedWatch now prices roughly **32% for a September hike (~68% hold)**, against the ~66% that stood at the end of July. The repricing traces to the **2026-08-07 July jobs miss**, ten days before this window opens. It is recorded here as standing context, explicitly *not* as an in-window development, and it is not a basis for an inter-monthly router review. *(MEASURED from CME-derived reporting; the move's date is INFERRED from the dating of the reporting that describes it.)*
- No Fed official speech or transcript dated in window. Next scheduled event is Jackson Hole, 8/27–8/29.
- Sell-side desk commentary was thin and directional-only; nothing rising to a market-moving published report.

---

# ANALYSIS — RISK TO EXISTING POSITIONS

## MECHANICAL EXIT-TRIGGER SWEEP

Run over the **union** of `state.current_positions` (14 tranches) and live `get_account_positions` (11 IBKR lines). **The union is clean: all 10 strategy names reconcile exactly on share count**, and the 11th IBKR line is VOO, the park vehicle, which correctly does not appear as a strategy position. **No reconciliation-lag positions; no `position_reconciliation_lag` alert owed.**

| Trigger | Position | Status |
|---|---|---|
| Convergence target | B:MSCI:2026-07-27, target 615 | **NOT hit** — closed 550.68, far below |
| Time-based exit | B:MSCI:2026-07-27, exit 2026-09-25 | **NOT due** — 39 days out |
| Convergence / time exit | All 13 D tranches | **None carry either** — Strategy D has no max hold, by design |

**Zero mechanical exits triggered.** The exit below comes from a judgment-laden thesis-invalidation criterion, not from these two.

## EXIT TRIGGERED — B:MSCI:2026-07-27, invalidation criterion (b)

**MSCI closed 2026-08-17 at 550.68 against a named invalidation criterion reading: "a fresh close below the 550.79 post-event trough with no accompanying new information (falsifies the stabilisation read; confirms PatternN forming)."** Breach by 11 cents.

**The setup was reconstructed from a one-month IBKR daily-bar pull rather than assumed:**

| Date | Close | Note |
|---|---:|---|
| 2026-07-20 | 625.11 | Pre-event |
| **2026-07-21** | **561.74** | Qualifying event — Q2 print with FY26 opex-guidance raise, **−10.14%** |
| **2026-07-24** | **550.79** | **Post-event closing trough — matches the criterion's number exactly** |
| 2026-07-27 | 571.03 | Entry (cost 579.28/sh) |
| 2026-07-28 → 08-14 | 556–582 | Sixteen sessions, never a close below the trough |
| **2026-08-17** | **550.68** | **First close below it** |

That the trough in the criterion matches an identifiable closing low to the cent confirms the criterion was written against a real reference, not an approximation.

**The "no accompanying new information" leg is satisfied on three independent lines:** a dedicated in-window news sweep of the name found nothing; an independent targeted search returned only the mid-July Q2 story; and the stockanalysis.com news listing shows MSCI's most recent item as "MSCI Equity Indexes August 2026 Index Review" dated **2026-08-12**, with nothing at all dated 8/16 or 8/17. That index-review item is MSCI's own product announcement about *other* issuers' index membership — not information about MSCI's business economics, and no explanation for a −3.24% day. The same source independently confirms the close at 550.68 / −3.24%, matching the IBKR authoritative bar exactly.

**Nor is it tape.** MSCI −3.24% against SPY −0.47% and its own sector XLF −1.00% — roughly 2.2pp of unexplained single-name underperformance.

**On the 11-cent margin — no tolerance band is being applied, and the reasoning matters more than the verdict.** 0.02% is one tick, and a criterion missed by 11 cents *feels* like it was not really missed. But this criterion is pre-committed and immutable for the life of the position, and it is written as a close test with no stated tolerance. Inventing a tolerance *after observing the price* is not risk management — it is amending an immutable criterion to escape its consequence, which is precisely the discretion the immutability rule exists to remove. The system's discipline is symmetric: a setup that mechanically clears every entry criterion stages regardless of how marginal the conviction, so an exit criterion that is met, exits, regardless of how marginal the margin. Any tolerance adopted here would have to apply to every future criterion, and its width would be chosen by whoever wanted a particular answer.

**Criteria (a) and (c) were checked, not assumed, and are UNBREACHED.**
- **(a) — no covering-analyst downgrade.** Post-Q2 sell-side activity is uniformly price-*target* cuts with ratings **maintained**: BofA Buy (730→715), JPMorgan Overweight (742→700), Evercore ISI Outperform (746→722), Raymond James (710→700), Morgan Stanley (→700). A target cut is not a ratings downgrade; the criterion says downgrade. Two Seeking Alpha *contributor* pieces carry "Rating Downgrade" in their titles, but a contributor is not a covering analyst and both are pre-window Q2 reactions. A pre-window 2026-07-30 Weiss Ratings tier change (B → B−) is a quant rating-agency action, not a covering sell-side downgrade, and predates this window.
- **(c)** — no further FY26 opex escalation, and no management reframing of the raise as durable/structural, in window.

**One evidential soft spot, stated plainly:** the MSCI investor-relations page returned HTTP 503 on one fetch attempt, so the "no news" negative rests on three secondary lines rather than four including the primary. Given they agree and the news listing is comprehensive through 8/12, this does not change the verdict, but it is the weakest link in the chain and is recorded as such.

**D2 note:** `state.trading_enabled` currently reads **FALSE**, `halt_reason = "state.freshness marks_fresh/engine_fresh not both TRUE"`. This is the **normal pre-D2a state**, not an incident — `last_mark_date` and `engine_through` both read 2026-08-14 because D2a has not yet run for today. D2a runs after this routine and should clear it. D2 must apply its own trading-enable re-check at craft time regardless.

## Per-position thesis-invalidation assessment (all 14 tranches)

| Position | Mark vs cost | Day | In-window items | Criteria |
|---|---:|---:|---|---|
| B:MSCI:2026-07-27 | −4.94% | −3.24% | none | **(b) MET → EXIT**; (a),(c) unbreached |
| D:AMZN:2026-07-09 | +8.32% | −0.51% | none | all 5 unbreached |
| D:AMZN:2026-07-30 | −1.65% | −0.51% | none | all 5 unbreached |
| D:CRM:2026-07-09 | +19.09% | −2.67% | none | all 5 unbreached; **Q2 FY27 print 2026-08-26 confirmed** |
| D:DIS:2026-05-07 | −7.02% | −3.14% | none | all 5 unbreached, three affirmatively passed at Q3 checkpoints |
| D:DIS:2026-08-05 | −0.28% | −3.14% | none | inherited, unbreached |
| D:GEV:2026-08-03 | +11.25% | **+1.48%** | none | orders-growth metric unbreached |
| D:GOOGL:2026-07-09 | −4.40% | −0.55% | none | all 5 unbreached; EU DMA remains behavioral |
| D:GOOGL:2026-07-26 | +4.93% | −0.55% | none | inherited, unbreached |
| D:ISRG:2026-07-20 | +11.68% | −1.06% | none | all 4 unbreached |
| D:RTX:2026-04-27 | +25.29% | −0.60% | none | all 6 unbreached; Airbus claim unresolved, no ruling |
| D:TSM:2026-07-21 | +0.73% | **+1.08%** | none | all 3 unbreached; Jul monthly rev was 8/10, pre-window |
| D:TSM:2026-07-29 | +9.70% | **+1.08%** | none | inherited, unbreached |
| D:UBER:2026-07-09 | +2.44% | −1.26% | **1 — Zipline partnership** | all 4 unbreached; touches none |

**UBER carried the book's only in-window company news:** a drone-delivery partnership and equity investment with Zipline, announced 2026-08-17 (investor.uber.com, corroborated same-day by four outlets), targeting 1M daily drone deliveries by end-2029 with Dallas/Houston launch by year-end 2026. It discloses nothing about gross bookings, adjusted-EBITDA margin as a percent of gross bookings, Uber One membership, or gross-bookings reporting structure — **real news, correctly non-criterion-bearing.**

**DIS underperformed its own sector** (−3.14% vs XLC −1.89%) with no in-window news found. Recorded and unresolved rather than explained away.

Two secondary fetches returned HTTP 503 during the position sweep (MSCI IR, ISRG news), so those two names' "nothing in window" conclusions rest on search coverage rather than search plus primary page. Noted for calibration.

## PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` reads as of 2026-08-14 (D1 runs before D2a, so the engine row is stale by one session). **Per the unconditional-refresh rule, `current_drawdown` was recomputed against today's live marks for every open position — not conditioned on any judgment about whether the day was eventful.**

| Strategy | Engine unit value (8/14) | Peak | Book move today | Refreshed drawdown | Deployed days | Flags |
|---|---:|---:|---:|---:|---:|---|
| **B** | 1.2237 | 1.2324 | **−3.24%** (MSCI only) | **≈ −3.9%** from peak | 77 | none |
| **D** | 1.0981 | 1.0981 | **−0.49%** (9 names) | **≈ −0.49%** from peak | 77 | none |

- **Drawdown kill (≥50% from peak):** B ≈ −3.9%, D ≈ −0.49%. **Not remotely triggered.**
- **Runaway success (TWR doubled, pre-gate):** B 1.22, D 1.10 — neither doubled. B has 12 of 18 closed trades toward its gate; D has 0 of 30. **Not triggered.**
- **Interim underperformance warning:** both strategies at `deployed_days = 77`, below the 90-day threshold, and both `interim_underperf_warning = FALSE`. D's `excess_vs_sgov` is **+8.6%**, B's **+21.0%**. **No alert owed, and none raised.**
- **B pairwise-correlation warning:** `analytics.b_pairwise_correlation` returns `n_positions = 1` (MSCI alone), so the ≥2 condition fails and the check is a no-op, exactly as designed.
- A, C, E hold no positions and have no kill-flag rows.

**No `ops.alerts` rows raised by this sweep, and none healed.**

---

# ANALYSIS — OPPORTUNITY CHECK

Evaluated against every roster-active strategy with `review_cadence: reactive` — currently **A, B, C, E**.

**No entry candidates are routed today.** Not because the tape was empty — it was the most eventful session in a fortnight — but because of where the router stands:

| Strategy | State | Consequence |
|---|---|---|
| **A** | DO-NOT-ACTIVATE since 2026-08-05 (div-A-202607-1) | No new entries. 36-name queue stays queued. |
| **B** | DO-NOT-ACTIVATE since 2026-08-05 (div-B-202607-1, universal `shock_overlay=acute` override) | No new entries. |
| **C** | HYBRID ACTIVATE (FOMC-only) | Next thesis already queued: `thesis-FOMC-C-20260908`, due 2026-09-08. Nothing new today. |
| **E** | **ACTIVATE** | Assessed today and declined — see below. |

**The four B-shaped candidates today were NOT blocked by the spec floor.** NOW (−5.08%), CVNA (−7.28%), RDDT (−7.63%) and STZ (−6.19%) all cleared B's frozen ≥5% event-day floor comfortably. What blocks them is the router: a deactivated strategy is by definition not eligible to deploy new capital. Routing them forward would manufacture an action D2 cannot take, so they are recorded and deliberately not routed.

**Strategy E — assessed and declined on mechanism, not on capital.** E holds all the free capital in the system ($15,309.94) and is the one ACTIVATE strategy, so today's enormous dispersion deserved a serious look. It does not produce an E candidate: **the hardware-versus-software split is a cross-industry-group divergence, and E's mechanism requires a within-industry-group pair.** Within each group today's moves were *convergent*, not divergent — the memory/AI-hardware names moved together, and the software names fell together. Manufacturing a pair out of a cross-group rotation would misuse the mechanism. The dispersion is logged as evidence for M2's next monthly pair screen, which is the routine that owns pair selection.

---

# ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

**14 tranches evaluated. 0 flagged. 1 declined at the HARD GATE. 13 declined.** Full per-tranche reasoning is durably logged as `entry_type='add-candidate-review'`. Marks are each tranche's *own* per-share cost basis (`cost_basis / shares`), never a name-level blended average.

**B:MSCI:2026-07-27 → `declined_hard_gate`.** Its invalidation criteria are breached, so per this section's own routing rule it is not an add candidate — it is an exit, handled above.

### The stated reason for declining every D add since 2026-08-13 has been wrong

The 2026-08-13 sweep logged a `capital_context` block asserting `D_available_funds: 0` and concluding, verbatim, that "No A/B/D add can be sized regardless of merit." **For D that is factually wrong, and it has been carried forward as the stated reason for four sessions.**

MEASURED this session: `state.strategy_declared_frequency` reads `is_low_frequency_by_design = TRUE` for D. **D is NOMADIC by design** — it holds no exclusive standing capital as a matter of architecture — so its `available_funds` of $0.11 is its *normal resting state*, not a deprivation. Reading it as a block is reading the design as a defect. The funding path for exactly this case is live: `analytics.fn_nomadic_capital_restore_plan(p_strategy => 'D', p_amount_needed => 50.0)` returns donor E, `pull_amount 50`, `plan_total 50`, **`is_fully_funded = TRUE`, `control_enabled = TRUE`**. A D add could be funded today, in full, mechanically, with no gate failing.

**What actually binds D is the ROUTER.** D has been DO-NOT-ACTIVATE since 2026-08-05, and the router's own definition is that an activated strategy is "eligible to deploy new capital" while a deactivated one takes "no new entries, existing positions run to normal exits." An add deploys new capital by construction.

The conclusion is unchanged; the reason is corrected — and the difference is operationally load-bearing. **A future session reading "capital-DISABLED, available_funds 0" would watch D's cash balance for the unblock signal. That is the wrong variable.** D adds unblock when the router flips, at the next M1a/M1b cycle or an inter-monthly divergence review. For A and B the original framing does hold, by a different mechanism: both are non-nomadic and router-deactivated, so their zero balances *are* genuine consequences of deactivation.

### The best-formed case in months dies on the router, not on merit

**D:DIS:2026-05-07** — **−7.02% below cost**, the deepest drawdown in the book, on a −3.14% session with no in-window news, and its criteria are not merely un-breached but were each **affirmatively passed** at their own named Q3 FY26 checkpoints: SVOD operating margin ~13% against an 8% floor and a third consecutive quarter of expansion (8.4% → 10.6% → ~13%); FY26 ~12% and FY27 double-digit adjusted-EPS growth reiterated unchanged against a ≤6% cut trigger; buyback target **raised to ≥$9B from $8B** against a fall-below-$7B trigger. That is the textbook shape of Strategy D's dip-with-intact-thesis trigger. It is declined solely because D cannot deploy new capital. **This is the opposite of the last five sessions, where the cases died on merit** — worth stating plainly so the pattern is not read as five more weak cases.

**D:CRM:2026-07-09 is the one case declined on genuine merit.** −2.67% on the session, but +19.09% above cost and Salesforce reports Q2 FY27 on **2026-08-26**, nine days out and company-confirmed. A drift into a print with no new information is the market de-risking ahead of an event; adding into it buys event risk while calling it a dip.

**D:TSM (both tranches) rose +1.08% with the AI-hardware complex, and that is explicitly NOT trigger (b).** The rally is directionally the *opposite* of TSM's criterion (c) — a structural AI-capex reset — so it is comforting. But Strategy D's strengthened-conviction trigger requires "a subsequent quarter's **data** further confirming a Subtype B trend metric," and a one-day sector re-rating is tape, not quarterly data. Reading a rally as thesis confirmation is exactly the recency-bias substitution D's entry criterion 6 warns against.

Remaining declines are noise or dips-from-profit: AMZN (+8.32% / −1.65%, sub-1.7% drift with zero AWS news), GEV (+11.25%, and *up* 1.48% today), GOOGL (−4.40% / +4.93%), ISRG (+11.68%), RTX (+25.29%), UBER (+2.44%).

All 14 positions carry a populated `invalidation_status` and none carries the `NOT_DISCRETELY_RECORDED_AT_ENTRY` marker, so **`invalidation_criteria_evaluable = true` for all 14** — no position is structurally ineligible for adds today.

---

# ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar, default NO on ambiguity, and the honest reason is structural rather than dismissive:

- **`shock_overlay` is already `acute` — its maximum severity, since 2026-08-01.** Today's escalation, real and dated as it is, **cannot move the axis further.** An escalation within an already-acute overlay is not a state change.
- The **Sept-hike repricing (66% → ~32%) is real but out of window**, tracing to the 2026-08-07 jobs miss. It has been the standing condition for ten days and is M1a's to score on 2026-09-01. It is not a development in this window and is not a basis for a review.
- Today's genuinely new macro inputs cut **both ways** against `growth_momentum = decelerating` — a large US regional-manufacturing beat (Empire State 20.6 vs ~11) against a broad China demand miss. Two-sided evidence is not a review trigger.
- The one thing today *did* establish — that the shock transmits through the inflation/rates channel rather than the growth channel — refines the mechanism without changing any axis value.

All five activation states stand: A DNA, B DNA, C HYBRID ACTIVATE (FOMC-only), D DNA, E ACTIVATE.

---

# EQUITY-BREADTH OBSERVATION

**68.38%** of S&P 500 constituents closed above their own 200-day SMA on **2026-08-17**.

- **Source (source-dated, not inferred):** EODData end-of-day table for index `$S5TH`, fetched twice with distinct cache-busting parameters, both returning identical figures. The table's own Date column reads verbatim: `17 Aug 26 | Open 70.97 | High 70.97 | Low 68.19 | Close 68.38 | Volume 0`. `date_attribution = source_dated` — the post-close-inference fallback was **not needed and not used**.
- **Cross-check (independent, source-dated, agrees):** MacroMicro's S&P DJI-attributed series reads `2026-08-17 | 68.58 %` with a prior reading of `72.76 %` that matches EODData's 8/14 close exactly. **Gap 0.20pp**, far inside the 5pp suppression threshold.
- **Direction — the material fact:** **−4.38pp from 72.76** (−6.02% relative), the sharpest one-day breadth decline in the recent series and the second consecutive down-tick off the 8/13 one-month high of 73.16. **It is not explained by the index**, which fell only −0.47%. The interior did the work: RSP −0.89% underperforming SPY, 9 of 11 sectors lower, and a violent rotation beneath a flat-looking tape. This is narrowing participation, not a directional sell-off. Participation remains historically broad in absolute terms.

Written to `events.regime_events` as `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`. **Threshold classification is D2a's**, on `TECHNICAL_SIGNAL`, and is deliberately not applied here — though at 68.38 it remains comfortably ≥50. D2a should treat this as a genuine same-session measurement (`breadth_measurement_age_days = 0`), not a carry-forward.

**Sources tried and rejected** (durable, because knowing which trackers are unusable saves future calls): MacroMicro direct fetch returned HTTP 403 and was reachable only via extract. Barchart `$S5TH`, StockCharts `$SPXA200R`, Investing.com `S5TH` and indexindicators were **not re-tried** — each is a documented prior-run failure and re-confirming a known failure is waste. Real Investment Advice carries a dated figure but its most recent references 2026-08-14, the wrong session.

---

# PARK ALLOCATION CALL

- **vehicle:** **VOO** (KEEP — unchanged from `state.park_policy_current`, effective 2026-08-03)
- **conviction:** **MEDIUM**, `conviction_pct` **58** (down from 62 yesterday)
- **direction:** keep · **status:** **BOUND**

**rationale.** The runner-up is SGOV, and it is the only serious alternative — not because the menu is short but because every intermediate rung is a duration bet and duration is exactly where today hurt. The long end was *sold* on the escalation: 30Y 5.25→5.31 (+6bp), 20Y 5.25→5.30, 10Y 4.68→4.72 (+4bp). So TLT, IEF, GOVT, MUB and LQD are all rungs that took damage on the very headline that would supposedly justify de-risking into them, while AOR/PFF/HYG carry equity or credit beta without equity upside. The menu collapses to the tier-0/tier-4 binary, for the same reason as on 2026-08-03 — a reason today strengthened rather than weakened. Against SGOV, four measured facts favour staying: SPY at 772.67 sits above its 50-day (~749) and far above its 200-day (~705), so the trend condition the 2026-08-03 re-risk was built on is intact and not close to failing; VIX at 15.19 remains well below both its own 50-day (17.18) and 200-day (18.53) averages and nowhere near its 52-week high of 35.30; credit is tight (hy_oas 2.85); and the index fell only −0.47%.

**invalidation.** Any ONE of these, on a close, flips this to a de-risk into SGOV: **(i)** SPY closes below its 50-day (~748.93, about 3.1% below today's close); **(ii)** VIX closes above its own 50-day average (17.18); **(iii)** breadth contracts below 60% of members above their 200-day. Named in advance so the next session can check them mechanically rather than re-argue the call.

**theater_check.** The foregone-conclusion risk here runs toward KEEP — it is the standing default and I inherited a MEDIUM-62 KEEP from yesterday, so restating it is the path of least resistance; the specific failure would be waving off the geopolitical escalation as background noise because it has *been* background noise for six weeks. So the rationale deliberately does not rest on the escalation being unimportant. It rests on a falsifiable, measured claim about the transmission channel — **defensives and duration both declined, which is inconsistent with a growth scare** — a claim that is checkable and could be wrong. Conviction was cut on the day's two adverse readings (VIX crossing the 15 boundary; breadth −4.38pp) rather than held flat, and three numeric triggers were named in advance. An unchanged 62 with no named triggers would have been the honest tell of theater.

*(VIX did cross the vocabulary LOW/NORMAL boundary at 15 today — a real threshold event, and the reason this is not a high-conviction call.)*

---

# RECOMMENDED ACTIONS

- **EXIT — MSCI (Strategy B, position `B:MSCI:2026-07-27`).** Invalidation criterion (b) MET: fresh close at 550.68, below the named 550.79 post-event trough, with no accompanying new information (verified on three independent lines). Criteria (a) and (c) remain unbreached; the convergence target (615) and time exit (2026-09-25) are neither hit nor due. Full position, 0.0863 shares. D2 must apply its own trading-enable re-check — `state.trading_enabled` is currently FALSE pending D2a's marks refresh, which is the normal pre-D2a state.
- **Watchlist update — AMAT (Strategy A), NOTE ONLY, no disposition change.** The 2026-08-16 row records a three-data-point shape, "the fundamentals keep beating and the tape keeps selling them," as the third input to the deferred bearish/bullish framing-flip. Today AMAT closed **+5.55%** (507.18 → 535.31, IBKR RTH bars) — the **first ratification-shaped price reaction** in that sequence, and therefore a direct qualification of the claim recorded yesterday. Fourth input to the same deferred flip decision, to be weighed at the next M1 with the A router ACTIVATE. Do not resolve the flip without it.
- **Watchlist update — NOW (Strategy A), NOTE ONLY, no disposition change.** Closed **−5.08%** (124.00 → 117.70) as the largest-cap member of an AI-exposed software cluster (MDB, GTLB, MNDY, SAIL all −4.7% to −4.9%) on a day the AI-hardware complex rose 5–9%. **No same-day catalyst exists.** Record explicitly, so it is not re-mis-dated by a future scan: KeyBanc's Underweight downgrade (Jackson Ader, Sector Weight → Underweight, AI seat-count risk) is dated **2025-12-15** and reiterated since, and the widely-quoted **$775 target is a stale PRE-SPLIT figure** — post-split equivalent ~$85, consistent with the measured 117.70 close and the row's own CLSA Underperform/$72 reference. This is standing bearish context on the same axis as NOW's A-thesis (SaaS-AI-platform monetization), not a new development.

```yaml d1_actions
- action: exit
  ticker: MSCI
  strategy: B
  qualifying_event_date: 2026-07-21
  source_research_screen_id: n/a
  detail: Invalidation criterion (b) MET — fresh close 550.68 below the named 550.79 post-event trough with no accompanying new information (three independent lines); criteria (a) and (c) unbreached; convergence target 615 not hit and time exit 2026-09-25 not due; exit full position 0.0863 sh; D2 to re-check state.trading_enabled, currently FALSE pending D2a marks refresh.
- action: watchlist
  ticker: AMAT
  strategy: A
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: NOTE ONLY, no disposition change — +5.55% (507.18 to 535.31, IBKR RTH bars) is the FIRST ratification-shaped price reaction against the three-point "fundamentals beat, tape sells" shape recorded 2026-08-16; fourth input to the deferred framing-flip decision, weigh at next M1 with A router ACTIVATE.
- action: watchlist
  ticker: NOW
  strategy: A
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: NOTE ONLY, no disposition change — -5.08% (124.00 to 117.70) as largest-cap member of an AI-exposed software cluster with NO same-day catalyst; record that the KeyBanc Underweight is dated 2025-12-15 and reiterated, and that its $775 target is a stale PRE-SPLIT figure (post-split ~$85, consistent with the 117.70 close), so a future scan does not re-mis-date it as new.
```

---

# PROCESS NOTES

**Durable writes this run (7 BigQuery rows):**

| Target | Row |
|---|---|
| `events.regime_events` | `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT` = 68.38, as_of 2026-08-17 |
| `events.decision_log` | `research-screen` / `single-name-move` (19 surfaced) |
| `events.decision_log` | `research-screen` / `single-name-move` **[CORRECTION]**, supersedes the above |
| `events.decision_log` | `research-screen` / `sector-move` (5 surfaced) |
| `events.decision_log` | `research-screen` / `sector-move` **[CORRECTION]**, supersedes the above |
| `events.decision_log` | `add-candidate-review` (14 evaluated, 0 flagged, 1 hard-gate) |
| `events.decision_log` | `park-allocation` — KEEP VOO, MEDIUM 58, BOUND |
| `ops.heartbeat` | `loop:park_allocator` |

Both `research-screen` corrections were verified to parse: `state.research_screen_calls` now returns exactly one NOW row (the corrected one, conviction 45), confirming the correction-aware view filters the superseded rows as designed. All 14 `add-candidate-review` positions parse into `state.add_candidate_reviews` with `invalidation_criteria_evaluable = true`.

**Sub-agent fan-out discipline (the rule added 2026-08-17 after the W2 FMP exhaustion).** Six sub-agents were used. The orchestrator made **all** shared pulls before fan-out — gainers/losers, sector snapshot and earnings calendar — and passed them into each prompt as literal text with an explicit instruction not to re-fetch. Every discovery agent was told the orchestrator re-measures all closes against IBKR and was instructed to record a provisional figure with its source and stop. Each prompt carried an explicit call budget and an instruction to report incompleteness on exhaustion rather than discover the ceiling by hitting it. **No agent hit the FMP cap** and the orchestrator spent 6 FMP requests total. Two agents reported that `include_usage` was rejected as an unsupported parameter by this deployment's Tavily schema, so per-call credit figures are **routine-ESTIMATED, not provider-REPORTED**.

**A spec-implementation hazard worth fixing before the next session steps in it.** The `invalidation_criteria_evaluable` field is specified as FALSE when the status is NULL *or* carries the `NOT_DISCRETELY_RECORDED_AT_ENTRY` marker. Written literally in GoogleSQL — `NOT (invalidation_status IS NULL OR JSON_VALUE(invalidation_status,'$.status') = 'NOT_DISCRETELY_RECORDED_AT_ENTRY')` — the **healthy case returns NULL, not TRUE**, because no position carries a `$.status` key at all, so the equality is NULL and `NOT(FALSE OR NULL)` is NULL. A session trusting that expression emits 14 NULLs into the `fields` payload instead of 14 TRUEs, silently degrading the exact field that exists to make ambiguity legible. **Wrap it in COALESCE.** Recorded in the `add-candidate-review` row's `spec_hazard_note`.

**Frontier-LLM capability check: run, silent, no capture.** One `hf_fs` paper search on the Monday rotation slot (cross-session consistency). Every result predated the window lower bound by weeks — newest was 2026-06-16 against a bound of 2026-08-14 under the 72-hour cap. **No capture written, no `state.strategy_candidates` row, no Daily.md finding** — the correct outcome, recorded here only so a future audit can distinguish "ran and found nothing" from "did not run."

**Open alerts observed but deliberately not touched.** Nine unresolved rows exist, including a `critical` `trading_halted` from D2a and a cluster of `queue_item_stale` / `review_handoff_stuck` / `phantom_run_completion` rows belonging to AR_att, D3, OPS0 and W5. None is D1's to resolve — capital-affecting and cross-routine classes are human- or owner-routine-owned under the fail-closed allowlist — and none blocks a research-only routine. The `trading_halted` row is surfaced above because it conditions what D2 can do with the MSCI exit, not because this run acted on it.

**Two evidential soft spots, stated rather than buried:** (i) the MSCI and ISRG investor-relations pages each returned HTTP 503 on one fetch, so those two "nothing in window" conclusions rest on search coverage rather than search plus primary page — this matters most for MSCI, where it is the weakest link in an exit decision, though three independent lines still agree; (ii) the single-name screen's ≥2% population is **not established as complete** — the 2%-to-4.5% band is essentially unenumerated, plausibly 50–150 further names.

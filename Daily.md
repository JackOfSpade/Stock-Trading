2026-09-24
<!-- d1_scan_through_utc: 2026-09-24T22:21:24Z -->

# Daily Market Development Scan — 2026-09-24 (Thu, MT)

Scan window: 2026-09-23 16:24 MT → 2026-09-24 16:21 MT (23.9h, cadence-normal; resolved from the prior `Daily.md` marker `2026-09-23T22:24:21Z`, cross-checked against that file's commit at 2026-09-23T22:27:35Z — agree to 3 min — and against `state.routine_catchup_window` `window_days = 0.98`. One completed US session inside the window: Thursday 2026-09-24. No `CATCHUP` token owed.)

Tape: **a second duration day, and this time the index refused to follow.** S&P 500 **7,703.83 (−0.03%)**, Nasdaq Composite **26,939.37 (+0.01%)**, Dow **51,349.98 (−0.31%)**. On IBKR RTH closes SPY 767.81 → **767.18 (−0.0821%)**. The 10Y closed **5.18% (+7bp)** and the **30Y 5.47%**, reported as its highest since 2004; Brent rose ~**3.6% to ~$106.80** on US/Iran escalation; VIX **15.67 (+3.23%)**; gold $4,298 (−0.47%). An index that moves 0.03% on a 7bp long-end move and a 3.6% oil move is not a quiet tape — it is a tape where the movement went sideways across sectors instead of up or down.

## TL;DR

- **Exits triggered: none.** Twelve open tranches, all Strategy D; not one carries a `convergence_target` or a `time_exit_date`, so no mechanical trigger exists on any of them, and no Development breached any thesis criterion.
- **New entry candidates: none routed.** B is `DO-NOT-ACTIVATE` and capital-disabled; the one name that survives its anchor test (SECZ) goes to the index only.
- **Add candidates: none (0 of 12).** Nine declined on the merits, three blocked at the HARD GATE (ISRG, RTX, UBER) — and the two best dip cases in the book, UBER and RTX, are among the blocked.
- **Watchlist: 2 changes — ADD SECZ** (anchor 2026-09-24, window to 2026-10-08) and **UPDATE MGM's short-direction tracking row**, whose subject bid was withdrawn today.
- **Regime review: no review.** Yesterday's flag was acted on — D2 performed the router review and reached a determinate verdict — and today's Brent move pushes the one pending trigger *further* away, not closer.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **The global bond selloff extended; the 30Y reached its highest since 2004.** 30Y ~**5.47%** and 10Y ~**5.18%**, up from 5.40%/5.11% Wednesday — the second consecutive session driven by the long end, attributed to Wednesday's hot flash PMI (input costs rising at the fastest pace in four years), weak recent auction demand, and firming hike expectations. It hit tech hardest intraday (Nasdaq was down over 1% before paring to flat) and pressured gold. ([Schwab market commentary](https://www.schwab.com/learn/topic/markets-and-economy), [Investing.com](https://www.investing.com/news/stock-market-news/us-stock-futures-dip-after-high-yields-batter-tech-trumpxi-summit-begins-4914303))
- **Oil spiked ~3.6–4% on US–Iran escalation.** Brent from ~$103 Wednesday to an intraday **$106.80–107.18**; WTI ~+4% to ~$95.8. At the UN, Trump threatened to "annihilate" the Iranian regime; US officials said Iran downed at least two US drones; embassies across the region issued security alerts, while first direct US–Iran talks since June resumed. This is an ongoing conflict rather than a fresh in-window shock, but it is the proximate driver of the oil move. ([CBS live updates](https://www.cbsnews.com/live-updates/iran-war-trump-un-speech-annihilate-threat-talks-resume), [Reuters via Business Recorder](https://www.brecorder.com/news/40440960))
- **US–China tariff truce extended two months as Xi Jinping began a three-day state visit.** Announced by Treasury Secretary Bessent as Xi arrived at Joint Base Andrews Wednesday evening (~19:59 ET, inside the window). Talks cover trade, AI export controls and Iran. Supportive for China-exposed equities, and comprehensively overshadowed by the bond move. ([CNBC](https://www.cnbc.com/2026/09/24/us-china-trade-truce-bessent-trump-xi.html))
- **No bankruptcy, disaster or enforcement action** materially affecting global risk assets was identified inside the window.

### 2. Scheduled events that resolved in the window

**Earnings (fiscal period as stated by the source; EVENT-IDENTITY GATE applied).**

- **COST — Costco, fiscal Q4 2026** (16 weeks ended 2026-08-30), released ~16:15 ET Thursday, inside the window. Adj EPS **$6.75 vs $6.54** consensus (beat); revenue **$93.87B vs $94.97B** (miss). After-hours print; no settled close-to-close reaction is measurable in this window.
- **DRI — Darden, fiscal Q1 2027**, released **PRE-MARKET 2026-09-24**. A slim sales/EPS miss against reaffirmed FY guidance; **−3.0184%** close-to-close (213.69 → 207.24, IBKR RTH bars). **This run's own two legs disagreed about this print and the screen leg was right:** the developments sweep placed DRI's release pre-market *Wednesday* and excluded it as out-of-window, while Darden's own investor-relations release date is 2026-09-24. The issuer source governs. Recorded because an identity gate that only ever checks outside sources cannot catch a disagreement between two of this routine's own legs.
- **GIS, CTAS, PAYX** reported Wednesday pre-market — **outside** the window (which opens 18:24 ET Wednesday) and correctly excluded.

**Economic data — three releases scheduled, none confirmed.**

- **Initial jobless claims** (week ended 09-19, scheduled 08:30 ET), **new home sales (August)** and **building permits** (both scheduled 10:00 ET) were all on the calendar for today. **No actual print could be confirmed from a primary source within this run's budget, so all three are recorded PENDING with their confirmed scheduled dates and no outcome figures.** A calendar date is a schedule, not evidence of a completed release.

**FDA limb.**

- **One resolved event, and it is a real one: the FDA Molecular & Clinical Genetics Panel met 2026-09-23** to review GRAIL's Galleri PMA application — confirmed against the **FDA's own advisory-committee calendar**, not an aggregator. GRAL was **halted** through the 2026-09-23 session and reopened +15.38% on 09-24. See the single-name screen below for why the halt matters.
- **No PDUFA approval or CRL** was identified as resolving inside the window. The nearest candidate (an Ionis action dated 2026-09-22) falls *before* the window and **could not be resolved against the FDA's own approvals page within budget — it is recorded UNRESOLVED, not as a dated forward action.** This limb exists because aggregator calendars have twice misfired on exactly this pattern here.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

**`entry_id` `6e179f3c-2c67-4a07-857c-b911ec051464`** (`screen='single-name-move'`). 25 distinct names measured close-to-close on IBKR regular-session daily bars, `close` array at both ends on every one. `surfaced_count` **9**, `rail_tally` **6**, `universe_measured` **25**.

**The finding is not the size of the moves — it is that correct anchoring disqualified two of the three biggest.** Strategy B's Entry criterion 1 tests the ≥5% move *on the anchor session*, and the anchor is the date the information crossed the wire, never the session the reaction was measured in.

| Ticker | prior close (9/23) | close (9/24) | metric_pct | Anchor | Criterion 1 on the anchor |
|---|---|---|---|---|---|
| **MGM** | 37.85 | 33.69 | **−10.9908%** | 2026-09-23 (after close) | **−2.6992% — FAIL** |
| **TWST** | 158.50 | 184.03 | **+16.1073%** | UNRESOLVED (originating deal ~09-16) | **+3.5989% on 09-16 — FAIL** |
| **GRAL** | 108.52 *(halt bar)* | 125.21 | **+15.3797%** | 2026-09-23 (FDA panel) | **UNMEASURABLE — anchor session did not trade** |
| **SECZ** | 14.36 | 16.53 | **+15.1114%** | 2026-09-24 09:00 ET, pre-open | **+15.1114% — PASS** |
| **IONQ** | 42.54 | 44.98 | **+5.7358%** | 2026-09-23 (intraday AM) | **+4.4183% — FAIL by 58bp** |
| **DRI** | 213.69 | 207.24 | **−3.0184%** | 2026-09-24 pre-market | −3.0184% — fail (below floor) |
| **ORCL** | 144.56 | 139.54 | −3.4588% | UNRESOLVED | n/a |
| **INTC** | 122.60 | 127.39 | +3.9070% | UNRESOLVED | n/a |
| **DIS** | 103.46 | 105.56 | +2.0298% | UNRESOLVED | n/a |

- **MGM.** Barry Diller's People Inc. **withdrew its buyout proposal**, reported as landing after Wednesday's close. −11% on 15.97M shares against ~1.7M the prior three sessions. I could not pin the release to a primary issuer timestamp — only a live blog — so strictly the anchor is UNRESOLVED, **and it does not matter**: the only anchor consistent with the evidence gives −2.6992% and fails criterion 1, and the anchor that would pass is the reaction session, which the convention forbids by name. Not a B candidate on either reading. This is the MSTR 2026-09-20 shape repeating.
- **GRAL.** Its 2026-09-23 bar carries **volume 0 with open = high = low = close = 108.52** — a trading halt, not a session. Criterion 1 is therefore *unmeasurable* on the anchor, and the +15.38% is the first tradeable repricing rather than an anchor-session move. Recorded as such rather than quietly tested on 09-24, which is the defaulting the convention exists to prevent. GRAL is separately already in the B index on a **distinct earlier event** (`qualifying_event_date` 2026-09-21, +33.6759%) whose window is still open, so the name is covered.
- **IONQ.** Quantum-computing breakthrough announced the morning of 09-23 — volume 49.8M that session against 7.8M the day before makes the event day unmistakable. An intraday release anchors on its own session, and there the move is **+4.4183%**, missing the floor by 58bp. It is the *continuation* leg that clears, on the session the convention forbids testing.
- **ORCL** is recorded deliberately: this is the exact ticker the 2026-09-14 run mismeasured at −13.79% by reading the `open` array. This run read `close` at both ends and gets −3.4588%.
- **Rejected at Layer-1, named individually.** **BALY +15.07%, DNA +19.46%, BNR +19.44%, MNTK +26.59%** — all confirmed on IBKR, all excluded on the **cap** rail ($687.7M / $669.6M / $19.0M / $409.9M). They clear the legacy ≥5% bar but were never in the eligible population, so they are *not* `rule_only` disagreements. **PSA, TDY, FRT, COIN, RJF** were surfaced by an unverified premarket-movers post at +12.3%/+10.5%/+9.4%/+11.7%/−4.6% and **all five failed on the close** (−0.76%, +0.30%, +0.88%, +0.55%, +0.34%). **ARM** was named by the same post at +3.3% premarket and **was not measured** — a named gap in this run's coverage, not an absence.

**COVERAGE GAP, MEASURED THIS RUN.** `DIS` closed **+2.0298%**, clearing both the ≥2% and ≥$2B rails, and **no discovery leg surfaced it.** It appears above only because D1 holds DIS and priced it for the add sweep. One confirmed leak found by accident in one session is the honest size of this net — recorded in `fields.selection_rule` so no downstream scorecard reads `universe_measured` as a coverage ratio.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

**`entry_id` `4280a628-3d50-4527-91ad-db3cff7b06d6`** (`screen='sector-move'`). All 11 SPDR GICS sector ETFs plus SPY measured on IBKR RTH daily bars, `close` array at both ends. `universe_measured` **12**, `rail_tally` **2**, `surfaced_count` **3**.

`XLC +1.2705` | `XLV +0.6338` | `XLE +0.3688` | `XLF −0.0183` | `XLY −0.2983` | `XLK −0.3226` | `XLRE −0.4541` | `XLI −0.7466` | `XLP −0.8857` | `XLU −0.9811` | `XLB −1.1935` | **`SPY −0.0821`**

- **XLC +1.2705%** — best sector, and specifically *not* a general mega-cap bid: **XLK fell −0.3226% the same session.** A long-duration growth sector bid on the day the 30Y made a multi-decade high is a divergence from the day's own driver. Conviction held to **45** because the one budgeted search returned no date-specific driver and the cause is genuinely unestablished.
- **XLB −1.1935%** — worst sector, **and it fell on a session Brent rose ~3.6% and XLE rose +0.3688%.** Materials normally track the commodity complex; falling while energy rises points at a rate-driven de-rating of cyclicals rather than a commodity story. The divergence from energy is the evidence. Conviction **60**.
- **XLU −0.9811%** — **missed the ≥1% level limb by 19bp and is surfaced on the dispersion limb deliberately.** Utilities are the most rate-sensitive sector on the board and XLU **closed exactly at its session low (39.36 = low)**, the only one of the twelve to do so. Conviction **60**. The honest counter-argument, recorded in the row: **XLRE, the other classic rate-sensitive sector, did not confirm** at only −0.4541%.
- The **legacy rule (sector ≥2%) surfaces an empty set** — the largest absolute move on the board was 1.27%. So `agreement` is `{both: 0, ai_only: 3, rule_only: 0}`; on this tape every judgment is AI-only.
- **Data-quality note:** XLP's 09-24 bar carries **close 81.70 against a stated low of 81.71** — the close sits a cent *below* the session low, which cannot be true. Transcribed exactly as IBKR returned it. It changes nothing (XLP clears no rail) but is on the record before it lands somewhere it matters.

### 5. Notable commentary

- **HSBC** reiterated a "max bullish" call on US equities, telling investors to lean into tech. ([Investing.com](https://www.investing.com/news/stock-market-news/us-stock-futures-dip-after-high-yields-batter-tech-trumpxi-summit-begins-4914303))
- **BTIG's Jonathan Krinsky** warned that "2000-like" technical signals are mounting. (same source; the original BTIG note was not independently fetched)
- **Goldman Sachs** reiterated positioning for further equity upside while flagging continued volatility from geopolitical risk, inflation, government debt and AI-capex sustainability. ([CNBC](https://www.cnbc.com/2026/09/23/stock-market-today-live-updates.html))
- All three are dated at or just before the window boundary (Wednesday daytime) and are **flagged as lower-confidence on exact in-window timing**.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run over the **union** of `state.current_positions` (12 tranches, 8 names, all Strategy D) and live `get_account_positions`. **The union is exact** — IBKR share counts match BigQuery on every name (AMZN 0.3464 = 0.1910+0.1554; DIS 0.7244 = 0.4422+0.2822; GOOGL 0.2577 = 0.1043+0.1534; TSM 0.1550 = 0.0659+0.0891; GEV/ISRG/RTX/UBER single-tranche), plus the park's VOO 17.7177. **No position exists in the connector that is absent from BigQuery, so no `position_reconciliation_lag` alert is owed.**

**Not one of the twelve tranches carries a `convergence_target` or a `time_exit_date`** — both columns are NULL on every row, which is what Strategy D's no-stop, open-ended design looks like. **So there is no mechanical exit to trigger, and this sweep is structurally a no-op today rather than a checked-and-clear.** Stating the distinction because "no triggers fired" and "no triggers exist" look identical in a summary and are not the same fact.

### Per-strategy kill-trigger sweep

`perf.kill_flags` (engine as-of 2026-09-23): **D** — `drawdown_kill` FALSE, `runaway_review` FALSE, `m2m_underperf_review` FALSE, `interim_underperf_warning` FALSE; deployed unit value 1.0637, peak 1.0981, drawdown −3.13%, excess vs SGOV +4.81%, deployed_days 104, closed_trades 1 against a gate of 29. **B** — all flags FALSE (row is as-of 2026-08-18; B holds no open position).

**Unconditional live-mark drawdown refresh**, as required, computed from today's IBKR RTH closes against yesterday's: the D book marked **$545.99 → $549.29, +0.6033%** on the session, which carries deployed unit value to ~**1.0701** and the refreshed drawdown to ~**−2.55%** against the −50% kill line. *This is a directional refresh from position marks, not a restatement of the TWR engine* (which also handles flows) — it is sufficient to establish the kill threshold is nowhere near, and nothing more is claimed for it.

- **Drawdown kill:** not triggered, by a factor of ~20.
- **Runaway-success:** not triggered — deployed TWR 1.0637 has not doubled.
- **Interim underperformance:** `interim_underperf_warning` is FALSE for both strategies, and there is **no open alert of that category** to heal-resolve.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`. **B holds nothing**, so the `n_positions >= 2` guard fails and the check is a no-op — inert, as designed, not passing.

### Thesis-invalidation check against today's Developments

Eight names, checked criterion by criterion against the window's Developments. **No invalidation criterion is met on any position, and no Development in this window touches any of them.**

The book's exposure to today's actual driver is indirect. The long-end move and the oil move are macro; every open thesis is invalidated by *company* metrics on multi-quarter horizons — AWS growth and margin (AMZN), Cloud revenue/margin/RPO and the structural-remedy question (GOOGL), SVOD operating margin and the FY26 EPS/buyback framework (DIS), organic orders growth (GEV), procedure growth and placements (ISRG), the Airbus/powder-metal/GTF and backlog set (RTX), gross margin and the N2/A16 ramp (TSM), gross bookings and Uber One (UBER). **None has a new datapoint in this window.** The one price move worth noting is DIS **+2.0298%**, the best in the book — and with no dateable DIS-specific release behind it, that is unexplained strength, which is neither a confirmation nor an invalidation.

**No dividend-netting test was required this run**: no open position carries a price-level invalidation criterion. Every criterion in the book is a fundamental metric.

### Watchlist candidacy changes

**MGM.** The Watchlist carries an MGM row dated 2026-06-01 recording People Inc.'s **unsolicited $48.30/share bid** (~$18B EV), with the B LONG direction declined on mechanism-mismatch and the name kept on short-direction tracking. **That bid was withdrawn today.** The premise of the tracked row has resolved, and the resolution is exactly the direction the row was watching. Routed as a watchlist update below.

No other watchlist candidate is materially changed by anything in this window.

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against the roster's `review_cadence: reactive` set — **A, B, C, E** (from `strategy/roster.yaml`; D is excluded on `long_horizon`).

- **Strategy B.** One name survives its anchor test: **SECZ, +15.1114%, anchor 2026-09-24 (pre-open PRNewswire), clearing the frozen ≥5% floor by ~3×.** MGM, TWST, GRAL and IONQ all fail or cannot be measured on their correct anchors, as set out above, and are **not** routed. **B is `DO-NOT-ACTIVATE` and capital-disabled, so SECZ goes to the new-entry state index only** — no thesis construction routed, no order, no position.
  **The cap rail on SECZ is not safe and is flagged, not buried:** $2.447B sits ~22% above the $2B rail, inside the ~30% band where FMP's implied share count is unreliable, and SECZ is a **2026-07-02 SPAC listing** — precisely the recent-issuance case that produces the lag. A second cap source is owed before any thesis session treats eligibility as settled.
- **Strategy C** (`HYBRID ACTIVATE (FOMC-only)`). No FOMC action resolved in this window and no qualifying catalyst within 45 days was newly announced. Nothing surfaced.
- **Strategy A.** No catalyst announcement within a 6-month horizon was newly surfaced on a name fitting A's eligibility.
- **Strategy E.** The day's sector dispersion is real but is a **single macro factor expressed across sectors** — rate sensitivity — rather than intra-industry-group divergence. XLB falling while XLE rose is a cross-*sector* spread, not a pair within an industry group, and XLRE's failure to confirm XLU weakens even the rate-sensitivity read. **No E candidate.**

## ANALYSIS — ADD-CANDIDATE CHECK (A / B / D only)

**`entry_id` `01c7c88f-595e-43f4-82bf-42b750f5ee26`.** Twelve tranches evaluated, **zero flagged**, three declined at the HARD GATE. There are no open A or B positions, so this section's scope reduces to D today.

Marks are the last completed session's IBKR RTH close over **that tranche's own** `cost_basis / shares` — never the connector's blended `average_price`. Both halves matter: `get_account_positions` served VOO at 706.44 tonight against a true close of **706.99**, and on ISRG the connector's blended average differs from the tranche's own basis by $0.32.

| Tranche | mark vs cost | today | evaluable | disposition |
|---|---|---|---|---|
| D:AMZN:2026-07-30 | **−6.1389%** | +0.04% | ✓ | declined |
| D:AMZN:2026-07-09 | +3.3725% | +0.04% | ✗ (name-covered) | declined |
| D:DIS:2026-08-05 | +1.7104% | +2.03% | ✓ | declined |
| D:DIS:2026-05-07 | −5.1736% | +2.03% | ✗ (name-covered) | declined |
| D:GEV:2026-08-03 | −1.5323% | +0.34% | ✓ | declined |
| D:GOOGL:2026-07-09 | −4.8594% | +1.34% | ✗ (name-covered) | declined |
| D:GOOGL:2026-07-26 | +4.4279% | +1.34% | ✓ | declined |
| **D:ISRG:2026-07-20** | +14.2993% | +0.31% | ✗ **uncovered** | **declined_hard_gate** |
| **D:RTX:2026-04-27** | +6.6203% | **−1.86%** | ✗ **uncovered** | **declined_hard_gate** |
| D:TSM:2026-07-29 | +14.8307% | +1.03% | ✓ | declined |
| D:TSM:2026-07-21 | +5.4431% | +1.03% | ✗ (name-covered) | declined |
| **D:UBER:2026-07-09** | **−5.4466%** | −0.29% | ✗ **uncovered** | **declined_hard_gate** |

**The gate is doing the deciding on three, and they are not the boring three.** Seven tranches carry `breach_status = NOT_ASSESSED_BY_THIS_BACKFILL`; four are covered at name level by a later tranche holding a fresh assessment (AMZN, DIS, GOOGL, TSM), three are covered nowhere (**ISRG, RTX, UBER**). And the two best dip cases in the book sit behind that gate:

- **UBER at −5.4466%** — second-deepest drawdown in the book, no adverse print anywhere in the window. That is the dip-with-intact-thesis shape almost exactly, and it cannot be assessed because nobody ever recorded whether its criteria were breached.
- **RTX at −1.8627% on the session** — the worst-performing held name today, the only one whose price action alone would have opened the question.

So the honest summary is not "no adds today" but **"no adds today, and the two cases most worth arguing about were never eligible to be argued."**

`invalidation_criteria_evaluable` is written FALSE for all seven via the **third disjunct** (`$.breach_status`). **Not one of the twelve carries a `$.status` key at all**, so the two-key test would have returned TRUE for every position *including the three the gate blocked* — the exact inversion the third disjunct exists to close.

**The closest thing to a case still fails.** AMZN:2026-07-30 at **−6.1389%** is the deepest drawdown in the book against five AWS criteria re-verified fresh at entry and unbreached. But the drawdown is eight weeks of drift with no adverse AWS datapoint behind it, and AMZN moved +0.0441% today — an add there would be averaging down on price alone, which the trigger definition explicitly is not.

**One constraint outside this sweep, stated so zero does not look over-determined:** `ops.alerts` carries an open `book_drawdown_soft_breach` warning (D2a, this morning) pausing D2 NEW-entry staging. A flag raised here would plausibly have been declined downstream anyway. **That is not why anything above was declined** — every decline is on its own trigger test or the gate — but a reader counting zero deserves to know a second constraint was standing.

## ANALYSIS — REGIME CHECK

**NO review recommended.** Yesterday's D1 flagged an out-of-cycle `FUNDAMENTAL_AXIS` review on the grounds that Wednesday's flash PMI (manufacturing 57.0, services 58.7, composite strongest in over five years) directly contradicts `growth_momentum='decelerating'` and `inflation_trend='disinflating'`, both standing since 2026-09-01. **That flag was acted on.** D2 performed the router review in its 2026-09-23 run and reached a determinate verdict: while `shock_overlay='acute'` stands, Strategy.md's first M1a/M1b reconciliation rule overrides ACTIVATE to DO-NOT-ACTIVATE for any strategy unconditionally, so **neither contradicted axis can move any activation in either direction.** A/B/D/E are already at the DO-NOT-ACTIVATE floor and no reconciliation rule reaches C from these two axes.

Re-flagging the same review one day later would be noise on a question already answered. **And today's tape pushes the answer further out, not closer:** the exposure D2 identified is dated to the moment Brent closes below the **96.74** retrace trigger, at which point the acute override lifts and the stale axes start deciding activations. **Brent rose ~3.6% today to ~$106.80** — further above that trigger, not nearer it. The condition that would make the stale axes matter is less imminent tonight than it was last night.

The high-bar, default-NO posture is satisfied: nothing in this window is a new fact about the axes that D2 has not already adjudicated.

## EQUITY-BREADTH OBSERVATION

**45.12%** of S&P 500 constituents closing above their own 200-day SMA, **as-of session 2026-09-24**, written to `events.regime_events` (`TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`).

- **Source: Barchart `$S5TH`**, the declared primary — `https://www.barchart.com/stocks/quotes/$S5TH?cb=20260924` (cache-busted). Page header verbatim: *"Quote Overview for Thu, Sep 24th, 2026"*. Quote line: `45.12 −2.59 (−5.43%) 17:03 ET`.
- **The on-page timestamp is 17:03 ET — after the 16:00 ET close**, so this is a settled figure and the 2026-09-20 `unsettled_at_fetch` trap does not apply. `date_attribution=source_dated`, not inferred.
- **Previous Close 47.71 reconciles exactly with the stored 2026-09-23 row.** No overnight revision to record.
- **This run had ONE usable source and says so.** EODData `$S5TH` returned the identical 45.12, but its live quote box carried an on-page time of **15:53 ET** (pre-close) and its day row showed **Low == Close (45.12/45.12)** — the documented unsettled tell. It is recorded as weak corroboration, not as independent confirmation.
- **Fetch-path provenance:** Barchart's rendering `WebFetch` path returned empty content this run; the figure kept came from the `tavily_extract` path on the identical URL. Recorded per the 2026-08-26 per-site cache-tier finding — an undated or empty payload condemns *that fetch*, not the source.
- **MacroMicro was deliberately not probed.** It is a Sunday-anchored weekly re-probe under the 2026-09-06 ruling, and today is Thursday.

Breadth is now **45.12** against **66.40 on 2026-09-03** — a three-week grind (66.40 → 60.63 → 56.26 → 50.49 → 45.12), not a gap. **It is the lowest of the 35 readings this key holds (2026-08-05 .. 2026-09-24); the key's history begins 2026-08-05, so that is a stated-window statement and not an all-time claim.**

## PARK ALLOCATION CALL

**`entry_id` `63984115-a848-46be-b10c-5991966a856d`.**

- **`vehicle`: VOO** — `target_f_pct` **0** (risk sleeve VOO 100%, defensive sleeve SGOV 0%). Direction **keep**. Status **BOUND**.
- **`conviction`: MEDIUM / 55.**
- **`rationale`:** The increase gate is **SHUT**, so KEEP is the only legal call. `state.park_axis_daily` for 2026-09-24 gives **standing_defensive_count 3** (breadth, rates, shock), **firing_count 0**, raw `cap_pct` 75, `increase_gate_open` FALSE. Increasing f needs an axis to have **ENTERED** defensive within 2 sessions *and* a standing count ≥ 2; limb (b) holds at 3, limb (a) fails outright — **all three defensive axes were already defensive yesterday**, and a standing state is never news. The DE-RISK EVIDENCE CARDINALITY floor (≥2 independent axes firing in the same session) is not even reached at zero. **The ladder arithmetic, stated rather than skipped:** 0.55 × 75 = 41.25, nearest step 50 — **unreachable and non-binding**, because the ladder sizes a licensed de-risk and never licenses one. **Decay:** the standing count read 3 on 09-22, 09-23 and 09-24, so no step-down is confirmed and the cap stays 75; non-binding at f=0 either way. **Crisis override not engaged** — SPY −0.0821% against the −2.5% bar, VIX 15.67 against 28. The runner-up (f=25, a first defensive step) beats nothing: it is mechanically unavailable, and on the evidence only breadth deteriorated *within* an already-defensive state. Why VOO beats SGOV on the merits as well as the mechanism: credit is **+0.5727% above** its 20d SMA where the test needs 0.50% *below*; the index sits **+0.8245%** over its 50dma and **+6.9082%** over its 200dma, only **−1.3755%** off the trailing-252 high; VIX at 15.67 is **+0.1054%** from its own 20d SMA, i.e. essentially on it.
- **`invalidation`:** Stated at the same bar as the KEEP, in both directions — and it is a **low bar, said plainly rather than buried.** Because the standing count is already 3, limb (b) is permanently satisfied, so **any single axis ENTERING defensive opens the gate outright**: volatility entering (VIX is 0.1% from its 20d SMA — the nearest), *or* credit entering (HYG/IEF falling to 0.50% below its 20d SMA, ~1.07% from here), *or* index entering (SPY losing its 50dma at ~760.91, −0.82% from today's close). Any **one** of those converts this KEEP into a licensed de-risk next session, sized against a cap of 75. Deliberately **not** a conjunctive checklist — the 2026-07-31/08-02 calls named one and cost the park ~$265 by making the return bar harder than the exit bar. Nothing here binds tomorrow's session.
- **`theater_check`:** The KEEP is mechanically forced, so the rationale cannot be narrating me into a conclusion I chose — but that cuts both ways, and the honest statement is that **my own hand-read is more defensive than the call I am permitted to make.** Breadth at 45.12 is the lowest of the 35 readings this key holds, the 30Y is at a multi-decade high, and Brent re-accelerated +3.6%. Recording that explicitly so a forced KEEP does not read as agreement with the tape. Three standing axes deteriorating in unison on a flat tape is the shape a top has; the cardinality rule declines to act on it *by design*, after a one-axis de-risk on 2026-09-01 moved ~97% of NAV and cost $214.32, and against a record in which the defensive signal won 4 of 15 and both closed defensive excursions of the AI era lost ground. If this KEEP is wrong it will be wrong slowly, and that is the trade the rails were chosen to make.

**Axis overrides recorded** (`fields.axis_overrides`): **rates** — the axis carries 09-23's 10Y at 5.11; my live reading is 5.18 (+7bp) with the 30Y at 5.47, which *deepens* a standing state and is not an entry. **shock** — curated BZUSD 103.08 (09-23) against my live ~106.80 (09-24); both clear the 95 axis line and both sit above the 96.74 retrace trigger, and today's move pushes further from de-escalation. Cited with dates because `ops.alerts` `9ce935ae` is an open notice about this exact instrument disagreeing across surfaces. **Mixed vintage checked per axis:** only breadth is same-session; the five price axes carry `measured_on` 2026-09-23 because D2a has not yet run. Structural, not an outage.

**Book:** VOO **17.7177** shares, no SGOV line at all — which is what f = 0 looks like. Park market value = 17.7177 × **706.99** (IBKR RTH close, contract 136155102) = **$12,526.24**. `actual_f_pct_before` 0.0%, matching the standing target exactly, so there is no convergence gap for D2 to close.

---

## RECOMMENDED ACTIONS

- **Watchlist — ADD `SECZ`** to the Strategy B new-entry candidates state index. Anchor `qualifying_event_date` **2026-09-24** (PRNewswire issuer release 09:00 ET, pre-open); criterion 1 tested on 09-24 gives **+15.1114%** (14.36 → 16.53, IBKR RTH daily bars, `close` array both ends), clearing the frozen ≥5% floor by ~3×. 10-trading-day window runs to **2026-10-08**. **Index only** — B is DO-NOT-ACTIVATE and capital-disabled; no thesis construction routed. **Cap caveat that must travel with the row:** $2.447B (FMP `profile-symbol`) is ~22% above the $2B rail, inside the band where FMP's implied share count is unreliable, and SECZ is a 2026-07-02 SPAC listing — a second cap source is owed before eligibility is treated as settled. Four-part field identity `(item_type, strategy, ticker, qualifying_event_date)` checked against open and terminal `events.queue_events` history and against `Watchlist.md`: **no prior SECZ record of any kind.** D2 must perform the real field-based dedupe, never a key-string match.
- **Watchlist — UPDATE the `MGM` short-direction tracking row** (added 2026-06-01, `B:MGM:2026-06-01`). The People Inc. **$48.30/share unsolicited bid that row exists to track was withdrawn today**; MGM fell **−10.9908%** (37.85 → 33.69, IBKR RTH bars) on 15.97M shares against ~1.7M the prior three sessions. Record the resolution on the row. **This is a status update, not a new B candidate:** on the correct 2026-09-23 anchor the move is **−2.6992%** and fails Entry criterion 1, and the anchor that would pass is the reaction session, which the anchor convention forbids.

**NOTE (not a bullet, not a `d1_actions` entry):** the PARK ALLOCATION CALL above is a **bound KEEP at `target_f_pct` 0**, matching standing policy exactly. D2 reaches it through `state.park_allocation_latest`, never through this section or the block below.

- Exits triggered: **none.**
- New entry candidates requiring thesis construction: **none.**
- Add candidates: **none.**
- Router reviews recommended: **none.**

```yaml d1_actions
- action: watchlist
  ticker: SECZ
  strategy: B
  qualifying_event_date: 2026-09-24
  source_research_screen_id: 6e179f3c-2c67-4a07-857c-b911ec051464
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE and capital-disabled). ANCHOR IS 2026-09-24 and the release
    is PRE-OPEN, so criterion 1 is tested on the same session: ARK Invest tokenized the $1.3B ARK
    Venture Fund (ARKVX) via Securitize on Ethereum, PRNewswire issuer release 2026-09-24 09:00 ET,
    ahead of the 09:30 ET open. IBKR RTH daily bars give 14.36 -> 16.53 = +15.1114%, close array
    read at both ends, clearing the frozen >=5% floor by ~3x. The 10-trading-day window runs to
    2026-10-08. CAP CAVEAT THAT MUST TRAVEL WITH THE ROW: $2.447B from FMP profile-symbol is ~22%
    above the $2B rail, inside the ~30% band in which FMP implied share count is known to lag, and
    SECZ is a 2026-07-02 SPAC listing - the exact recent-issuance case that produces the lag. A
    second cap source is owed before any thesis session treats instrument eligibility as settled.
    Four-part field identity (item_type, strategy, ticker, qualifying_event_date) checked against
    open and terminal events.queue_events history and against Watchlist.md - no prior SECZ record
    of any kind. D2 must perform the real field-based dedupe, never a key-string match.
- action: watchlist
  ticker: MGM
  strategy: B
  qualifying_event_date: n/a
  source_research_screen_id: 6e179f3c-2c67-4a07-857c-b911ec051464
  detail: >-
    UPDATE the existing MGM short-direction tracking row (added 2026-06-01, item_key
    B:MGM:2026-06-01, which records People Inc. unsolicited $48.30/share bid, ~$18B EV, with the B
    LONG direction declined on mechanism-mismatch). THAT BID WAS WITHDRAWN TODAY: MGM fell
    -10.9908% close-to-close (37.85 -> 33.69, IBKR RTH daily bars contract 9560, both bars stamped
    13:30:00Z) on volume of 15,967,265 against roughly 1.7M on each of the prior three sessions.
    Record the resolution on the existing row - the premise the row was tracking has now resolved,
    in the direction it was watching. THIS IS A STATUS UPDATE, NOT A NEW B CANDIDATE, and the
    reason is the anchor: the withdrawal is reported as landing after the 2026-09-23 close, so the
    anchor is 2026-09-23 and criterion 1 is tested there, where MGM moved -2.6992% (38.90 -> 37.85)
    and FAILS the >=5% floor. The anchor that would pass is the 09-24 reaction session, which the
    ANCHOR CONVENTION forbids by name. Note also that the release could be pinned only to a
    secondary live blog, not a primary issuer timestamp, so the anchor is formally UNRESOLVED -
    which changes nothing here, because both readings decline the candidate.
```

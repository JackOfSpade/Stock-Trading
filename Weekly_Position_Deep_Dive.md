2026-W38

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-09-20 · **Evidence window:** 2026-09-13 09:23:32 UTC → 2026-09-20 09:08 UTC (this routine's own last `completed` run → now; `state.routine_catchup_window` `window_days = 6.99`, cadence-normal against the 10.5-day 1.5× weekly bar — no missed period, no catch-up sub-section owed, no `CATCHUP` token).

**NO `WEEKLY-THESIS-ACTION` FLAG.** No hold / weekly-thesis-action / further-research recommendation is issued, because there is no open in-scope position to issue one on.

**Marker.** `2026-W38` is the plain ISO week of the run date (Sun 2026-09-20 is day 7 of the Mon 09-14 → Sun 09-20 week). W1 (`3e5638e`, `f36bac4`) and W2 (`0c35b49`) both stamped `2026-W38` earlier today, so all three weekly files agree and W4's upstream-freshness read matches.

**Scope, derived not assumed.** In-scope = roster-active strategies with `review_cadence: reactive`. Read from `state.strategy_roster` and `strategy/roster.yaml` (`reactive` for A, B, C, E; `long_horizon` for D). So the set is **A, B, C, E** — unchanged. D's 12 open tranches are M3's monthly deep-dive and are untouched here.

---

## HEADLINE — the book is empty for a fifth week, and for the first time the shock overlay's exit moved in two directions at once

`state.current_positions` returns **12 open rows and all 12 are Strategy D**. A, B, C and E hold nothing. That is the fifth consecutive weekly cycle with an empty in-scope book, and Steps 1, 2, 3, 5 and 6 of this routine are vacuous in consequence — stated at the bottom rather than silently dropped.

What is **not** vacuous is Step 4, and it changed materially this week. The `acute` shock overlay's published two-leg exit moved **closer on the price leg and further away on the clock leg in the same seven days**:

| | 2026-09-13 W3 reading | 2026-09-20 W3 reading | direction |
|---|---|---|---|
| Brent peak (running max of acute run) | 107.63 (09-10) | **108.75 (09-15)** | ratcheted up |
| Retrace trigger (baseline + 50% of elevation) | 96.18 | **96.74** | ratcheted up |
| Brent current | 107.63 (09-10, = peak) | **104.82** (09-17, warehouse) / **103.87** (09-18, externally sourced) | fell |
| Further decline required for leg (ii) | **−10.64%** | **−6.86%** | **closer** |
| Leg (i) quiet-clock anchor | 2026-09-11 | **2026-09-15** (per W1 today; contested — see below) | **further** |
| Earliest date leg (i) can pass | 2026-10-02 | **2026-10-06** | **further** |

**The consequence is unchanged from last cycle and is worth restating because it is the load-bearing fact:** the next scheduled scoring, **M1a on 2026-10-01, is arithmetically incapable of de-escalating this axis.** Measured against `state.market_calendar`, 2026-10-01 is only the **12th** trading day after 2026-09-15 against a requirement of 15 — and even under the *older* 2026-09-11 anchor it is only the **14th**. Leg (i) fails at that scoring under either reading, and leg (ii) fails by 6.86%. Nothing in this file argues for a regime change; this is a measurement offered as evidence, not a scoring act.

**The one genuinely new thing:** this is the **first cycle of the acute run in which the required decline shrank.** From 2026-08-01 to 2026-09-13 every W3 reading had Brent at or near its running maximum, so leg (ii)'s gap only ever widened. It has now narrowed by 3.78 percentage points in one week. Twenty percent of the required retrace has been achieved (`(108.75 − 103.87) / (108.75 − 84.73) = 20.32%`). That is a change in kind, not merely in degree, and it is the first evidence in seven weeks that the price leg is a live exit rather than a theoretical one.

---

## THE EMPTY BOOK, RE-ESTABLISHED INDEPENDENTLY

Measured this run, not carried forward from the prior file:

- `state.current_positions`: 12 rows, strategy `D` on all 12 (AMZN ×2, DIS ×2, GOOGL ×2, TSM ×2, GEV, ISRG, RTX, UBER).
- `events.position_events` grouped across **all** recorded history returns exactly two strategies: **B** (41 events, 2026-04-27 → 2026-08-18) and **D** (34 events, 2026-04-27 → 2026-09-14). **A, C and E have never produced a single position event.**
- B's last event is the terminal `CLOSE` of `B:MSCI:2026-07-27` on **2026-08-18** (D2a STEP 0 fill reconciliation). B has therefore been flat **33 calendar days / 22 trading days** — last week's file correctly measured 26 calendar days on 09-13, and this is that same figure advanced by seven, not a restatement.

**The caveat that has not stopped being true, restated because it changes what the verdict means.** An "empty book" verdict on A, C and E is a weaker statement in kind than the same verdict on B: A, C and E have *never opened a position*, whereas B genuinely went flat. Saying "no thesis drifted this week" about a strategy that has never held a thesis is not a finding about the strategy's health.

### Why the book is empty — the causes, re-measured

| Strategy | Activation state | Capital | Binding cause today |
|---|---|---|---|
| **A** | `DO-NOT-ACTIVATE` | disabled | Universal `shock_overlay = acute` override. `leg_a_dwell` TRUE (103 trading days, left-censored), `leg_c_technical` TRUE, **`leg_b_price_leg` FALSE**. W1 derives the router gate at **2026-11-02**. |
| **B** | `DO-NOT-ACTIVATE` | disabled (NAV $0.00) | Same override. 4th consecutive INDEX-MODE cycle (W2). `leg_a_dwell` TRUE (31 dwell days), `leg_c_technical` TRUE, `leg_b_price_leg` FALSE. |
| **C** | `HYBRID ACTIVATE (FOMC-only)` | **enabled** | The only open door. NAV **$23.64**. Blocked not by the router but by affordability — see the C section. |
| **E** | `DO-NOT-ACTIVATE` | disabled | Same override, adjudicated on the merits for E on 2026-09-03 (`div-E-202608-1`). Holds **$15,368.39 idle** — 96.44% of the book's $15,936.22 total NAV. |

---

## STEP 4 — SECTOR AND MACRO CONTEXT (the only step with in-scope content)

### 4a. The shock overlay, measured against its own published exit

The rubric is `Strategy.md:2132` / `strategy/09_regime_scoring_strategy_blind_monthly.md:71`, Rev 48 (2026-09-05, owner directive), verbatim:

> **De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold.** Downgrade when BOTH are true, each dated and measured in the row rationale: **(i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation, i.e. it now sits at or below the baseline-to-peak midpoint.** Either leg failing keeps the grade at `acute`.

The rubric file took **zero commits** inside this window — it is unchanged and simply being measured against.

#### Leg (ii) — FAILS, but by the smallest margin of the run

Read from `state.rerisking_limb_status` (`bigquery/224_rerisking_limb_status.sql`), all five terms identical across every strategy row:

- `brent_baseline` **84.73** — median of the 60-trading-day window strictly before the acute run start (43 observations, 2026-06-01 → 2026-07-31)
- `brent_peak` **108.75**, set **2026-09-15**
- `brent_retrace_trigger` **96.74** = `84.73 + 0.5 × (108.75 − 84.73)` — reproduced by hand, matches the view exactly
- `brent_current` **104.82**, `brent_as_of` **2026-09-17**
- `leg_b_basis` **`not_retraced`**, `leg_b_price_leg` **FALSE**

The full acute-run path from `state.signal_marks_curated`, 33 observations 2026-08-01 → 2026-09-17, run low **79.36**:

```
09-08  99.39
09-09 101.21
09-10 107.63   ← prior cycle's peak AND prior cycle's current
09-11 104.61
09-14 105.68
09-15 108.75   ← new running maximum; trigger ratchets 96.18 → 96.74
09-16 105.83
09-17 104.82   ← warehouse current
09-18 103.87   ← EXTERNALLY SOURCED (see Coverage); warehouse does not hold it
```

**Taking Friday's externally-sourced close, leg (ii) fails by 7.13 — a further −6.86% is required.** On the warehouse's own last-held session (104.82) it fails by 8.08, −7.71%. Last cycle the same arithmetic demanded −10.64%. Either figure is a fail; the movement between them is the finding.

**The ratchet is real and this cycle demonstrates it in both directions.** Last week's file predicted exactly this: *"every new high raises the retracement target… a partial pullback after a new high does not restore the prior position."* The 09-15 high raised the trigger 96.18 → 96.74, so 0.56 of the 3.76-point fall from the old peak was consumed by the target moving rather than by price approaching it. That prediction is now **verified within one week**, and it is why "Brent fell 4.5% from the peak" overstates the progress: net of the ratchet, the gap closed by 3.78pp, not by the full decline.

**Context on the size of what remains, from the series' own history.** A −6.86% move is inside the range this series has printed — the acute run has already produced single sessions of +6.3% (09-10) and +2.9% (09-15) — so unlike last cycle's requirement, which exceeded the largest one-day decline on record, the remaining leg-(ii) distance is now an ordinary multi-session move. That is context, not a forecast.

#### Leg (i) — FAILS OUTRIGHT, and the anchor date is contested between two internal surfaces

This is the part that needs care, because **two internal surfaces now disagree about when the governing qualifying event happened**, and one of them published a derived date off it earlier today.

**Reading A — anchor 2026-09-15 (D1's own record, adopted by W1 today).** D1's 2026-09-15 sector-move screen (`events.decision_log` `db7dc01c-1280-407c-ac66-5391c6f26666`) records, as that session's event:

> "XLE +2.1695% is the only meaningful gainer, on a physical event: **drones struck Saudi Arabia East-West pipeline — the Hormuz bypass — forcing a shutdown**, with industry estimates putting up to 4% of global supply at risk. Brent front-month BZX6 closed 105.68 → 108.75 (+2.9050%) and USO +3.3198% in the same session."

W1 2026-W38, running earlier today, took this as the anchor, reset the quiet clock to 2026-09-15, and published a derived A-router gate of **2026-11-02**.

**Reading B — anchor 2026-09-10/11 (this run's external sweep).** An independent external check dates the drone strike on the East-West pipeline pumping station to **2026-09-10** and Saudi Arabia's precautionary shutdown of the whole line to **2026-09-11**. Two internal facts corroborate that dating: D1's own 2026-09-13 file already referred to *"the weekend's Saudi flow-suspension escalation"* — i.e. a Saudi flow suspension was known before 09-15 — and Brent's largest single move of the entire acute run, **+6.3% to 107.63, landed on 09-10**, which is the price signature of a fresh supply event. 09-15's +2.9% is a second, smaller move.

**What decides between them cannot be decided here, and does not need to be.** D1's 09-15 row **cites no news source at all** — it attributes the strike solely to the price/volume co-movement it observed (Brent, USO, XLE), which is exactly the evidence pattern that cannot distinguish a new event from a re-pricing of a known one. The external sweep's 09-10/09-11 dating rests on secondary aggregation and its one in-window follow-up item (an 2026-09-18 report that Aramco told European refiners they would receive no October allocation) is **single-sourced and unverifiable** — the underlying article returned HTTP 403. Neither reading is established to this routine's satisfaction.

**It changes no verdict today, and that is stated affirmatively rather than used to avoid the question.** Measured directly against `state.market_calendar`:

| anchor | 15th quiet trading day | position of 2026-10-01 M1a scoring |
|---|---|---|
| 2026-09-15 | **2026-10-06** | 12th of 15 — fails |
| 2026-09-11 | **2026-10-02** | 14th of 15 — fails |

Leg (i) fails at the 2026-10-01 scoring either way, and leg (ii) fails outright, so the overlay stays `acute` under every reading available. The discrepancy is filed rather than resolved — see **FILED THIS RUN**.

**One honest limit.** The 2026-09-18 Aramco allocation item, if it were a qualifying event, would restart the clock from 09-18 and push the earliest possible exit into late October. This run declines to treat it as one: by its own framing it is a *commercial consequence* of an already-counted event, not an independent attack, sanction, OPEC action, blockade or force majeure. That judgement is recorded so a later run can overturn it on better sourcing rather than re-derive it from scratch.

### 4b. The technical plane reversed the narrowing this routine reported last week — after a near-miss of 0.09pp

Last week's file reported that the technical plane *"is still passing — but its margin narrowed on all three axes at once."* Re-established from `events.regime_events` as of 2026-09-17, that narrowing has reversed on all three, and one axis came within a rounding error of flipping first:

| Axis | Value (2026-09-17) | Label | Margin to failing side |
|---|---|---|---|
| `VIX_REGIME` | 15.44 (from 17.71, −12.82%) | `NORMAL` | 9.56 below the `HIGH` line at 25 |
| `SPY_TREND` | 762.60 vs 50dma 759.5314, 200dma 715.87445 | `UP` (**flip from `NEUTRAL`**) | +0.404% above the 50dma |
| `EQUITY_BREADTH` | 51.09 | `HEALTHY` | **1.09pp** above the 50 line |

`leg_c_technical` reads **TRUE**.

**The near-miss is the finding, and it is not visible in today's reading.** Breadth printed **50.09 on 2026-09-16** — **0.09pp** above the `HEALTHY`/`WEAK` boundary. Had it closed one tenth of a point lower, `leg_c_technical` would have gone FALSE and the re-risking limb would have lost its technical leg entirely, on a day when nobody was watching that axis because the FOMC was the story. The full chain across the window is 56.26 → 52.88 → 50.09 → 51.09: a three-session slide that stopped 0.09pp short of mattering, then recovered. **This is exactly the class of slow-burn, cumulative fact W3 exists to surface** — no single D1 run flagged it, because on each individual day the label never changed.

**An apparent contradiction worth one line, because it looks alarming and is not.** The same 51.09 reading is `HEALTHY` to the regime vocabulary (threshold 50) and **DEFENSIVE** to the park allocator v4 (threshold 66). Two consumers, two thresholds, one measurement — not a disagreement, and not a defect.

**Corroboration from the system's own allocator.** D1's 2026-09-17 park call (`f0d2e48d-ad0d-41ee-a385-3fb6977ae704`) independently recorded **VOLATILITY — EXITED** and **INDEX — EXITED**, dropping the standing defensive count 5 → 3, and D2 executed the first graded step in the re-risk direction (`target_f_pct` 50 → 25, VOO 75 / SGOV 25, conviction MEDIUM 45). That is a separate mechanism reading the same tape and reaching the same conclusion, which is corroboration rather than an echo. **Crude did not join it:** the same call kept `shock` DEFENSIVE — *"`shock_overlay = 'acute'` … plus Brent … 105.83 → 104.82, still far above 95"* — which is consistent with the leg-(ii) measurement above and is the reason a re-risking technical plane does not unlock any in-scope strategy.

### 4c. The Fed hiked — the macro plane's largest move of the window

From D1's own record (`873b8fad-0111-43e9-a015-1d252bb59dce`), sourced to federalreserve.gov's statement and projection materials released 2026-09-16 14:00 ET:

> "The FOMC raised the target range 25bp to 3.75-4.00%, the first hike since 2023, 12-0, with an SEP median implying more."

**16 of 18 participants penciled in at least one further 2026 hike.** The tape: SPY −0.441% (757.39 → 754.05) on 37.8M shares against a 22–27M norm, having traded as high as 761.62 after the decision — a full round trip, not a quiet day. XLF −1.618% and XLE −2.882% carried the downside; technology was flat. Rates: 10Y 5.01% (from 5.00), 2Y 4.74% (+7bp), the 10y–2y spread flattening 0.33 → 0.27. By 09-17 the front end unwound to 10Y 4.94 / 2Y 4.67, and externally the 10Y was still ~4.94% at Friday's close, a move the external source attributes to the softer crude tape.

**Read-through to the in-scope book: none mechanically, one thing worth carrying.** No A/B/C/E position exists for this to affect. What it changes is the *setting* for the only capital-enabled strategy — see below.

**August CPI, stated with its disagreement intact.** Energy was unambiguously the driver: energy index +2.1% m/m, gasoline +3.9% m/m, energy +16.3% y/y, accounting for more than a third of the headline monthly increase, attributed to Middle East pass-through. The **headline and core YoY figures could not be resolved**: two named aggregators reported +3.4%/+2.4% and +3.71%/+2.76% respectively, and this run did not spend a further call to adjudicate. Both are recorded; neither is relied on. The directional point — that the energy shock has now reached the realized inflation data, which is the transmission channel the `acute` grade asserts — holds under either.

---

## STRATEGY C — the only open door, and the hike made it narrower, not wider

**What already happened, terminal and not to be re-opened.** `thesis-FOMC-C-20260908` was drained **NO-GO by D2 on 2026-09-08** and re-confirmed NO-GO on 09-09 — the fifth consecutive NO-GO in the C-FOMC series. W4 on 2026-09-13 (`5755398b-2527-41ff-8083-f9205570e8a4`) **deliberately declined to re-enqueue the 2026-09-16 FOMC**, correctly, on idempotency: the event was already represented by a terminal row, and re-minting it *"would have asked D2 to adjudicate the same catalyst a third time in a week against a conservative default of decline."* **So no routine evaluated a fresh C opportunity around the hike, and none should have.**

**The live item, which W3 must not duplicate.** `thesis-FOMC-C-20261020` sits on `PENDING_ANALYSIS`, due **2026-10-20**, for the **2026-10-28** decision. **D2 owns the GO/NO-GO.** W1 measured its mechanics today and found the same structural bind that produced the five-drain streak: NAV **$23.64**; the 2026-10-30 expiry ATM 763 strike carries `implied_vol` **12.84%** against HV10 **9.785%** / HV20 **9.157%** / HV30 **8.743%**, i.e. **IV/HV20 = 1.40**; the ATM straddle costs $26.96/share against a total strategy NAV of $23.64. Rich implied favours *selling* premium; the budget admits only *buying* it. The two cheap-to-realized names in W1's 19-name panel (PYPL 0.72, F 0.94) are both earnings events and therefore router-forbidden under the FOMC-only carve-out.

**W3's own addition, and it is a slow-burn one D1's daily mechanics do not produce.** The September drain's single C-favourable factor was **two-sidedness** — the hike was priced near 56% when the thesis was written, *"genuinely two-sided for the first time."* That factor is now gone, and gone in a direction that makes the October setup harder rather than easier:

- The Fed has demonstrated it will act on its dots, **12–0**, with no dissent to price against.
- **16 of 18** participants project at least one more 2026 hike, so October's decision starts from a one-sided prior, not a coin flip.
- Criterion 2 requires an **affirmative, sourced, quantified divergence from market pricing**. A consensus that has just been vindicated is a harder thing to find a defensible divergence against than a market split 56/44.
- And the affordability bind is **tightening, not loosening**: W1 measured the two cheap-premium ratios at 0.72 and 0.94 this cycle against 0.68 and 0.83 last cycle — the edge on the router-forbidden side is narrowing.

**This is context for D2's 2026-10-20 pass and nothing more.** W3 crafts nothing, enqueues nothing, adjudicates nothing, and does not pre-empt that decision. Recorded here because the disappearance of two-sidedness is precisely a *cumulative* change across the window that no single daily run would flag.

**One sector read-through, held at its true weight.** Last cycle this file noted XLE gaining only +0.3% against a ~+17.6% monthly Brent move and read it as the equity market declining to price the shock as persistent. This cycle the seam behaved differently on the two decisive days: XLE was the **only** gaining sector on the 09-15 supply event (+2.17%), then **−2.88%, the worst sector, on the hike**. So the energy complex did respond to the supply news when it arrived; what dominated it four sessions later was rates. That is a more ordinary picture than last cycle's and argues for less weight on the XLE-divergence framing, not more. W1 independently flags the same seam as *"INTENSIFIED this week"* on its A-queue names (XOM, CVX both `SPENT-BY-GATE`) — a different reading of the same data, recorded rather than reconciled, because neither run can settle it and nothing turns on it today.

---

## STRATEGIES A, B AND E — no position, no thesis, and what did happen

- **A.** Router `DO-NOT-ACTIVATE`, 5th consecutive cycle; capital-disabled. W1 re-derived the gate at **2026-11-02**. Its ten-name shortlist overlaps four open **Strategy D** tranches (GOOGL, GEV, AMZN, TSM) — **not a conflict**: A holds nothing, A is double-blocked, and A and D are separate mandates permitted to hold the same name. W1's strongest new thesis of the cycle (DAL/UAL/AAL/CCL, oil-shock fuel-cost bearish) is **DIRECTION-INADMISSIBLE** under A's long-only rail for the second cycle running — a structural, not a discretionary, decline.
- **B.** Router `DO-NOT-ACTIVATE`, 4th consecutive INDEX-MODE cycle; NAV $0.00. One index-only watchlist add this window (**JBHT**, −13.30% on 09-16, on a CFO guidance warning given after the 09-15 close). D2 corrected the qualifying-event date from D1's 09-16 to **09-15** and recomputed the window close to 2026-09-29 — the same anchor-dating question that appears in leg (i) above, on a different surface, and already filed by D2 as `d1_qualifying_event_date_anchor_unspecified`. W2 separately found D1 had measured **ORCL on opens rather than closes** (−13.79% open-to-open vs a true **−3.65%** close-to-close), putting it below B's 5% floor; a re-screen is queued as `rescreen-ORCL-B-20260920`. **Neither touches a position, because B has none.**
- **E.** `DO-NOT-ACTIVATE`, capital-disabled since 2026-09-04. One pair surfaced and was declined this window: **DELL/STX**, a 15.70pp same-session divergence, declined by D2 on 2026-09-13 on *three independent bars*, any one sufficient — the router/capital block, entry criterion 3 unmeasured (M2's job, not D2's), and entry criterion 5 **unevaluable on this connector at all** (no shortable-shares / borrow-rate / HTB field on IBKR MCP; §11 fails closed: *"If the reading cannot be obtained, the short leg does not open."*). D2 also named a fundamental mechanism cutting against the pair regardless — hyperscaler capex accrues to compute and networking, not commodity storage. Correctly disposed; W3 adds nothing.
- **E's idle capital is the book's dominant fact and is already instrumented.** `state.regime_capital_sync_pending` still returns exactly one row — `SWEEP / E / 15368.39 / counterparty NULL / blocked_no_recipient TRUE / blocked_reason 'no_eligible_recipient'`. **96.44%** of the book's NAV sits behind a deactivated strategy with nowhere to go. Nothing moves, which is the safe outcome. D2a's `regime_sweep_blocked` warning (`b40cb3e6`, 2026-09-06) is open and owned. **Do NOT re-file.**

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE — and one measured exoneration

Per the MEASURE-FROM-THE-GOVERNING-SURFACE rule, every quantity this file restates was re-read from the surface that owns it, not carried forward.

1. **The 09-04 Brent restatement did NOT recur, and this is the return-path check on my own filed finding.** `events.signal_marks` was queried directly for every `BZUSD` row with `mark_date ≥ 2026-09-08`: **eight dates, eight rows, exactly one row per date, no duplicates.** The revisability hazard filed last week (`82c99515`) is real but did not fire in this window. Stating the negative result matters as much as the positive one: a filed finding that quietly stops recurring looks identical to a filed finding nobody checked.
2. **Last week's trigger of 96.18 was correct for its date and is now superseded by the ratchet, not by an error.** 96.18 = `84.73 + 0.5 × (107.63 − 84.73)` reproduces exactly against a peak of 107.63; today's 96.74 reflects the 09-15 high. Neither reading is wrong; the target moved, exactly as the prior file said it would.
3. **Last week's "the 15th trading day after 2026-09-11 is 2026-10-02" is re-verified as arithmetic and is now contested only on its anchor.** Measured against `state.market_calendar` this run, 2026-10-02 *is* the 15th trading day after 09-11. What moved is which event the clock hangs on, and that is filed below rather than silently adopted from W1.
4. **"B flat 26 days" → 33 calendar days / 22 trading days.** Advanced by seven days, same underlying event (`B:MSCI:2026-07-27` terminal CLOSE, 2026-08-18). Not a correction.
5. **"96.4% of book NAV stranded behind E" → 96.44%**, re-measured from `analytics.strategy_nav` (15,368.39 / 15,936.22). Unchanged.
6. **The technical-plane claim is REVERSED, not corrected.** Last week's *"margin narrowed on all three axes at once"* was true on its own data; this week all three margins sit on the safe side. Re-establishing rather than carrying forward is what surfaced the 0.09pp breadth near-miss that neither reading would have shown on its own.

---

## COVERAGE STATED HONESTLY

**D1 coverage is complete for the window.** D1 logged `completed` on **2026-09-13, 09-14, 09-15, 09-16 and 09-17** — the full `daily_sun_thu` set. `state.cadence_watch` reports `needs_attention = FALSE` for D1, D2, D2a, D3, OPS0, OPS1 and OPS2. Every event this file treats as already-detected was in fact detected daily; the shock-overlay and technical-plane findings above are cumulative readings *across* those runs, which is the boundary W3 is supposed to work on.

**Friday 2026-09-18 is a full trading session no internal routine has yet observed, and that is structural, not a fault.** `marks_due_through` = 2026-09-17 against `last_trading_day` = 2026-09-18; the daily tier is `daily_sun_thu`, so Friday is absorbed by today's D1/D2a fire, which runs *after* this one. This is the exact condition the W3 spec's 2026-09-13 clause anticipates, and **externally sourcing that one session is required, not the forbidden re-source.** Done, and labelled:

- **Brent 2026-09-18 = 103.87** — two sources agree (FMP `commodities-historical-price-eod-light` and one named web source reporting the settlement). A third figure of 103.21 surfaced without an attributable outlet and reads as an intraday quote rather than a settlement print; it is recorded and **not relied on**. Under either figure leg (ii) fails. **No new high was made** — 103.87 < 104.82 < 108.75 — so the trigger did not ratchet again.
- **VIX 2026-09-18 = 14.81** — **single-sourced (FMP only), not cross-checked.** Flagged because it is consequential: 14.81 is below the 15 line, so when D2a ingests it tonight the `VIX_REGIME` key would score **`LOW`** for the first time in this episode. That is **INFERRED from an externally-sourced close applied to a published threshold, not measured by the warehouse, and D2a owns the label.** It does not move `leg_c_technical`, which requires only VIX ≠ `HIGH`.
- **SPY 2026-09-18 = 761.69** — single-sourced (FMP only). This run does **not** recompute the 50-day SMA for 09-18 and therefore makes **no claim** about Friday's `SPY_TREND` label; the 09-17 SMA of 759.5314 is not Friday's SMA. D2a owns it.

**The 2026-09-18/19 platform outage cost this file no evidence, and the reason is worth pinning so a later reader does not assume otherwise.** Anthropic's 7-day usage limit was exhausted 2026-09-18 01:16 UTC and reset 2026-09-19 08:00 UTC, rejecting four routine fires outright (**SL5, SL3, OPS2, OPS0**) and cutting **SL2** mid-run. **It did not touch D1, D2a, D2 or the weekly research chain.** SL3 self-healed; OPS0, OPS2 and SL5 are `catchup_safe: false`, so those 2026-09-17 slots stay permanently missed. The absence of `Daily.md` entries for 09-18/09-19 is ordinary D1 cadence, **not** outage fallout — a conflation that would be easy to make and wrong.

**One in-flight capital move, outside this routine's scope but recorded so it is not mistaken for a gap.** D2's 2026-09-17 park re-risk legs (`SELL 37.1486 SGOV` instr 100 / `BUY 5.3013 VOO` instr 101) filled at Friday's open and remain **unreconciled** pending today's D2a Step 0; two `staged_order_awaiting_confirm` warnings are open and owned. `state.staged_order_reconciliation_overdue` (120h, `bigquery/244`) landed inside this window and does **not** fire at ~53h. This is a park-allocator action, not an A–E position; **D2a owns the reconciliation.**

**This run's own discipline, reported rather than buried.** The external-research sub-agent was given a hard budget of 12 metered calls and made **13**, disclosing the overage itself. All 13 are written to `ops.web_calls` in full. The per-call timestamps in that table are **approximate to within the sub-agent's run window** (~09:20–09:26 UTC): the agent returned reconstructed ordering rather than a verified wall clock, and inventing precision it did not have would have been worse than recording the approximation. No finding in this file rests on a 13th call — it was a CME FedWatch probability check whose figure is cited only as second-hand context.

**System state at write time.** `state.system_health.all_green = TRUE`, **zero open criticals**, 69 open alerts (59 info, 10 warning). `state.trading_enabled = FALSE` with `halt_reason` *"state.freshness marks_fresh/engine_fresh not both TRUE"*; `state.staging_halt_disposition` reads `halt_is_prerefresh_artifact = TRUE`, `gate_alert_action = 'defer_to_craft_site'`, `mechanical_enabled = TRUE` — the documented pre-refresh artifact for a Sunday fire. **W3 crafts no orders, so per the PRE-REFRESH HALT DISPOSITION rule it raises nothing at all.**

---

## OBSERVED, NOT ADJUDICATED — recorded so a future run does not re-flag them

- **`shock_rubric_brent_peak_revisable` (`82c99515`, filed by W3 2026-09-13) is still OPEN and unadjudicated.** W5's 2026-09-13 SPEC-DEFECT NOTICE INTAKE read 55 open info rows, fixed 5 and rejected 1, leaving 49 open; this one is among them. Its `>=2-cycle` escalation has not yet fired on it. **Do not re-file** — the return path is working as designed, just slowly. Re-checked substantively this run (item 1 above): the hazard did not recur.
- **`nomadic_borrow_blocked_unsignalled` (`6f04ff75`, D2, 2026-09-07) remains open.** The earlier W3-filed form (`e2eb2990`) was correctly resolved after being drained through W5 → queue → D2, and D2 raised the durable version itself. Owned and signalled; **do not re-file.**
- **`regime_sweep_blocked` (`b40cb3e6`, D2a, 2026-09-06) remains open**, covering E's $15,368.39 blocked sweep. Owned; **do not re-file.**
- **W5's two open warnings from 2026-09-13 are consistent with park churn and are owned**: `regime_restore_shortfall` (debtors A, B, D) and `wash_sale_exposure` (VOO, PARK). W5's surface.
- **Two `staged_order_awaiting_confirm` warnings** on the 09-17 park legs, both already notified. D2a's surface, as above.
- **`d1_qualifying_event_date_anchor_unspecified` (`03b8f773`, D2, 2026-09-16) is open** and is the sibling of the finding filed below — same root (D1 has no written rule for dating a qualifying event), different surface (Strategy B's window anchor vs the shock rubric's quiet clock). Cross-referenced rather than duplicated.
- **Strategy A's `analytics.strategy_nav` row is entirely zero including `deposits`**, unlike its siblings — consistent with A having been capital-disabled and swept. Unchanged for a third cycle, not measured to a conclusion, not escalated.

---

## FILED THIS RUN — one finding, on a surface W3 does not own

**The shock rubric's leg (i) has no written rule for dating a qualifying event, and two internal surfaces now carry different anchors for the same physical event — one of which has already been published as a derived gate date.**

MEASURED this session, not relayed: D1's 2026-09-15 sector-move row (`db7dc01c-1280-407c-ac66-5391c6f26666`) records the Saudi East-West pipeline strike as **that session's** physical event and cites **no news source** for it, attributing it solely to the Brent/USO/XLE co-movement it observed. An independent external check dates the strike to **2026-09-10** and the pipeline shutdown to **2026-09-11**; D1's own 2026-09-13 file already referenced *"the weekend's Saudi flow-suspension escalation"*, and the run's largest single Brent move (+6.3%, to 107.63) landed on **09-10**, not 09-15. W1 2026-W38 adopted the 09-15 anchor this morning and published a derived A-router gate of **2026-11-02**.

**Nothing is wrong today, and this was checked rather than assumed.** W1's gate is the next *reachable scheduled* M1a/M1b re-score, and those are `monthly_ftd`: 2026-10-01, then 2026-11-02. The quiet clock expires **2026-10-06** under the 09-15 anchor and **2026-10-02** under the 09-11 anchor — **both after 2026-10-01 and both before 2026-11-02** — so W1's published gate is **2026-11-02 under either anchor and does not move.** Leg (i) fails at the 2026-10-01 scoring either way (12th vs 14th trading day of 15) and leg (ii) fails outright, so no verdict, no gate date and no capital allocation turns on the difference in this cycle. (An earlier draft of this section asserted the 09-11 anchor would pull the gate to 2026-10-30; that was wrong — it does not, because the monthly-first-trading-day grid is coarser than the two-day discrepancy.) The exposure is **purely prospective, and narrow**: the two anchors diverge by two trading days (2026-10-02 vs 2026-10-06), and the rubric's de-escalation is **REQUIRED, not discretionary**, once both legs hold — so a scoring landing *between* those two dates would be decided by which surface it happened to read. No scheduled M1a/M1b falls in that gap this cycle, which is why nothing is broken today; an **M1R out-of-cycle re-score, which fires on a limb rather than on a calendar, could**. The durable fix is a written dating rule, not a correction to either file.

Filed per the OUT-OF-SCOPE FINDINGS rule as an `ops.alerts` **`info`** row — **`6081d304-118e-42c9-a6ed-ed6f0693c17f`**, `source='W3'`, category `shock_leg_i_event_anchor_undated` — naming the owning surfaces (D1's research-screen event-dating; `strategy/09_regime_scoring_strategy_blind_monthly.md` §Shock / overlay grading rubric leg (i); and W1's gate derivation as the downstream consumer) and the nearest owning routine for adjudication (**W5**, SPEC-DEFECT NOTICE INTAKE). **De-dup performed before filing**, per the rule: no open info row names this surface. The nearest sibling, `03b8f773` (`d1_qualifying_event_date_anchor_unspecified`, D2, 2026-09-16), is cited **in** the new row so W5 may merge them if it judges them one defect — it covers the Strategy-B window anchor, a different surface with a different consumer and no published derived date.

**Venue consumer verified, not assumed:** W5's SPEC-DEFECT NOTICE INTAKE demonstrably drained W3's own info row `e2eb2990` through to a D2 disposition, and read 55 open rows on 2026-09-13.

**What W3 did NOT do, stated explicitly:** it did not score or re-score any regime axis; did not touch `bigquery/224`, the rubric file, `Strategy.md` or any slice; did not correct W1's published gate date or edit `Weekly_Catalyst_Calendar.md`; did not edit a queue item; did not craft, block or size anything; did not adjudicate `thesis-FOMC-C-20261020`; did not re-file the four findings already open and named above; and did not decide whether C should be funded.

---

## STEPS 1–6, DISPOSED

Stated rather than omitted, so "missing" is never mistaken for "skipped."

1. **Current thesis status** — no thesis in scope. Vacuous.
2. **Competitive landscape** — no position whose peers matter. Vacuous.
3. **Fundamental developments** — no position to accrue evidence against. Vacuous.
4. **Sector and macro context** — the only step with in-scope content, discharged in full by §4a (shock overlay, both legs), §4b (technical plane and the 0.09pp breadth near-miss), §4c (the FOMC hike and August CPI), and the Strategy C implied-vol section.
5. **Thesis-invalidation signals** — no criteria live in scope. Vacuous. (D1 evaluated the D book's criteria on every scanned day — "12 open tranches evaluated, 0 flagged" on each of 09-14 through 09-17 — which is M3's surface, not this one.)
6. **Time-to-thesis-resolution** — no resolution window open. Vacuous. Per spec W3 checks no convergence targets, time-exit dates or option-expiry mechanics in any case: D1's connector sweep is the sole detector, D2 the sole converter.

---

## WHAT W4 OWES ON THIS FILE — nothing, stated affirmatively

- **No `WEEKLY-THESIS-ACTION` flag.** No hold, no weekly-thesis-action, no further-research recommendation — there is no open in-scope position to carry one. No `immediate_action_flagged` alert is owed and none is raised.
- **Zero queue-convertible items.** No research-deferral checkpoint, no thesis action for D2 to revalidate.
- **Cross-strategy deconfliction is vacuous** with zero open in-scope positions. Noted only for shape: four of W1's A-queue names (GOOGL, GEV, AMZN, TSM) are also open Strategy D tranches — not a conflict, since A holds nothing and is double-blocked, and A and D are separate mandates permitted to hold the same name.
- **The C FOMC lane already has its live item and W4 must not re-mint it.** `thesis-FOMC-C-20261020` is open on `PENDING_ANALYSIS`, due 2026-10-20, for the 2026-10-28 decision; D2 owns the GO/NO-GO. The September FOMC is terminal.
- **The shock-overlay measurement is evidence, not a referral.** W4 need not convert it and **must not route it to M1a** (blinding).
- **One `ops.alerts` info row was raised by this run** (`6081d304-118e-42c9-a6ed-ed6f0693c17f`, `shock_leg_i_event_anchor_undated`). It is a spec-defect notice for W5's intake, not a W4 conversion.
- **The leg-(i) anchor discrepancy does NOT invalidate W1's published gate.** Checked this run: `2026-11-02` holds under both candidate anchors, so `Weekly_Catalyst_Calendar.md` needs no correction and W4 should not treat it as suspect. The finding is routed to W5 as a missing-rule notice, not pushed at W1 mid-cycle.

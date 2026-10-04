2026-W40

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-10-04 · **Evidence window:** 2026-09-27 09:27:01 UTC → 2026-10-04 ~09:30 UTC (this routine's own last `completed` run → now; `state.routine_catchup_window` `window_days = 6.98`, `never_completed` FALSE, cadence-normal against the 10.5-day 1.5× weekly bar — no missed period, no catch-up sub-section owed, no `CATCHUP` token).

**NO `WEEKLY-THESIS-ACTION` FLAG.** There is no open in-scope position, so this file issues no hold, weekly-thesis-action or further-research recommendation. No `immediate_action_flagged` alert is owed and none is raised.

**Marker.** `2026-W40` is the plain ISO week of the run date (Sun 2026-10-04 is day 7 of the Mon 09-28 → Sun 10-04 week). W1 and W2 both stamped `2026-W40` earlier today, so all three weekly files agree.

**Scope, derived not assumed.** In-scope = roster-active strategies with `review_cadence: reactive`. Read this run from `strategy/roster.yaml` (`reactive` for A, B, C, E; `long_horizon` for D) and `state.strategy_roster` (A–E `ADOPTED`, `is_active`; F, G, H `REJECTED`). So the set is **A, B, C, E**. That is unchanged, and no SISA graduate has been registered that would widen it. D's 12 open tranches belong to M3.

---

## HEADLINE — the view's price leg says "closest yet", and on a true basis it is "furthest since the peak". Both are true; only one is price.

`state.current_positions` returns **12 open rows, all Strategy D**. A, B, C and E hold nothing. This is the **seventh** consecutive weekly cycle with an empty in-scope book, so Steps 1, 2, 3, 5 and 6 are vacuous. They are disposed at the bottom rather than dropped. Step 4 carries the cycle again.

| | 2026-09-27 W3 | 2026-10-04 W3 | direction |
|---|---|---|---|
| `brent_peak` / `brent_retrace_trigger` (view) | 108.75 / 96.74 | **108.75 / 96.74** | unchanged |
| `brent_current` (view) | 106.60 (09-24) | **102.31 (10-01)** | **−4.0%** |
| Required fall for leg (ii), view basis | −9.25% | **−5.44%** (−5.39% on Friday's external 102.25) | **looks much closer** |
| Same, **like-for-like contract** (W3 estimate, §4a) | −9.25% (no roll inside that window) | **≈ −10.2% to −11.0%** | **slightly further** |
| Retracement achieved, like-for-like | 8.95% (09-24) | **≈ 4%** (10-01) | **near the peak again** |
| Leg (i) quiet-clock: earliest pass | 2026-10-14 (09-23 anchor) | **2026-10-02 / 10-14 / 10-19–10-20**, depending on anchor (§4b) | **spread widened** |
| `leg_c_technical` | FALSE (breadth 45.12) | **FALSE (breadth 41.15)** | **further** |
| `sql_limbs_fired` | FALSE | **FALSE** | — |

**Three things this cycle, in order of weight.**

**1. A contract roll split the governing view from the price it is supposed to measure.** `state.signal_marks_curated` `BZUSD` is an unadjusted continuous series. It switched from the November to the December Brent contract on **2026-09-29**, and about −6.43 of that session's −9.12 stored step is backwardation, not price (`events.decision_log` `0c7fcaec`, owner session, 10-02). The view now compares a December-contract `current` against a November-contract peak and trigger. The headline distance improved from −9.25% to −5.44%, and **none of that improvement is price**: like-for-like, Brent at the 10-01 close sat within about one dollar of its 09-15 peak. On 2026-09-29 the stored close (96.16) was **below** the 96.74 trigger, so leg (ii) read as satisfied for one session on the roll alone. It did not fire only because leg (c) was false.

**2. The next roll lands two trading days before the next scheduled scoring, and that scoring is the first one at which leg (i) passes under every anchor in the fleet.** The December contract expires 2026-10-30, so the stored series rolls about **2026-10-29**. The next `monthly_ftd` M1a scoring is **2026-11-02**. With Brent flat near 102 and a backwardation of 5–6, the post-roll stored close would sit at roughly 96–97, at or through the 96.74 trigger, **with no change in price**. The rubric reads this same curated series (its SOURCE TRAP pin), and the rubric's downgrade is **"REQUIRED, not optional, once both legs hold."** `0c7fcaec` names the roll hazard for the limb. **The dated collision with a scheduled, gate-setting scoring is what W3 adds**, and it is filed (FILED THIS RUN).

**3. One published figure in the fleet carries the wrong label, and it points the wrong way.** `Weekly_Catalyst_Calendar.md` PART 2A STEP 1 gives the like-for-like required fall as "≈ −10% to −11%". In the same sentence it gives the like-for-like retracement as "only ~25–30% (M1a's own figure, `5d3998df`)". On the view's own baseline and peak, those two cannot both hold: a −10% to −11% required fall implies roughly **0–4%** retracement. Reproduced below, the ~25–30% figure is the **stored-basis** (mixed-contract) retracement at 10-01, not the like-for-like one. W1's conclusion ("read honestly, the price leg moved *away* from clearing this week") is correct, and more strongly than its own number says. The error is in W1's surface, so it is filed to W1, not edited here.

Nothing in this file scores or re-scores any regime axis.

---

## THE EMPTY BOOK, RE-ESTABLISHED INDEPENDENTLY

Measured this run, not carried forward:

- `state.current_positions`: 12 rows, strategy `D` on all 12 (AMZN ×2, DIS ×2, GOOGL ×2, TSM ×2, GEV, ISRG, RTX, UBER).
- `events.position_events` across all recorded history: **B 41, D 41** events. **A, C and E have never produced a position event.** D's count rose 34 → 41 through seven `ADJUST` rows on 2026-10-01 14:22 UTC (M3's surface). The B/D count match is a coincidence of that arithmetic, re-derived rather than assumed.
- B's last event is still the terminal `CLOSE` of `B:MSCI:2026-07-27` on **2026-08-18**. B has now been flat **47 calendar days / 32 trading days**, last week's 40/27 advanced by exactly 7 and 5.

**The caveat that still holds.** "Empty book" is a weaker statement about A, C and E, which have never opened a position, than about B, which went flat. "No thesis drifted" says nothing about the health of a strategy that has never held a thesis.

### Why the book is empty — re-measured from `state.strategy_capital_enablement` and `state.rerisking_limb_status`

| Strategy | Activation (M4 2026-10 carry-forward, `as_of` 10-02) | Capital | NAV | Binding cause today |
|---|---|---|---|---|
| **A** | `DO-NOT-ACTIVATE` | disabled | $0.00 | M1b's raw call, not the shock (the acute override is *inert* for A); the technical leg also reads DNA on breadth. W1's gate: **2026-11-02**, fourth cycle. |
| **B** | `DO-NOT-ACTIVATE — PENDING div-B-202609-1` | disabled | $0.00 | Raw call ACTIVATE; DNA is **override-manufactured** by `shock_overlay = acute`, third month. **AR_att 10-05 / AR_orc 10-06 can bind ACTIVATE.** |
| **C** | `HYBRID ACTIVATE (FOMC-only) — PENDING div-C-202609-1` | **enabled** | **$19.49** | Affordability. M1b's raw call is DNA, so the 10-06 review could *close* C's only door. |
| **E** | `DO-NOT-ACTIVATE` | disabled | **$12,672.77** | Raw call DNA on its own reasoning (rate-duration factor). The override is inert. Holds **95.71%** of the $13,241.22 NAV basis. |

**The near-term fact for the in-scope book is B, not the shock.** If `div-B-202609-1` binds ACTIVATE on 2026-10-06, its overflow-drain limb converts B's watch overflow that same run. W2 measured all 22 of its new identities as drainable on that bind. **This is the first cycle in seven in which next week's W3 could plausibly find an open in-scope position.** W3 does not pre-empt that review. It records that next week's Steps 1–6 may not be vacuous.

---

## STEP 4 — SECTOR AND MACRO CONTEXT

### 4a. Leg (ii): the price leg, and the roll

The rubric is `strategy/09_regime_scoring_strategy_blind_monthly.md` §Shock / overlay grading rubric (Rev 48). It is measured against, not reopened. Downgrade `acute` → `latent` is required once **(i)** 15 consecutive quiet trading days hold **and (ii)** Brent sits at or below the baseline-to-peak midpoint.

**Governing surface, read first** (`state.rerisking_limb_status`; all five rows identical on the price terms):

- `brent_baseline` **84.73** (43 obs, 2026-06-01 → 07-31), `brent_peak` **108.75** (the only 108.75 row in raw `events.signal_marks` is 2026-09-15), `brent_retrace_trigger` **96.74**. Reproduced by hand.
- `brent_current` **102.31**, `brent_as_of` **2026-10-01**, `leg_b_basis` **`not_retraced`**, `leg_b_price_leg` **FALSE**.

**The stored path** (`state.signal_marks_curated` `BZUSD`; raw `events.signal_marks` shows exactly one row per date from 09-15 on, with no restatement):

```
09-24 106.60   Nov contract
09-25 104.32   Nov   ← last week's externally-sourced figure; ingested 09-27 22:54, EXACT match
09-28 105.28   Nov
09-29  96.16   Dec   ← ROLL. −9.12 stored, ≈ −2.69 price + ≈ −6.43 backwardation (0c7fcaec). BELOW the 96.74 trigger
09-30  98.03   Dec   (Nov's own expiry-day settle 103.50 → spread 5.47)
10-01 102.31   Dec   +4.28, +4.4%, stalled US–Iran talks (D1 3ec80668)
10-02 102.25   Dec   ← EXTERNALLY SOURCED (FMP); warehouse does not yet hold 10-02
```

**Three readings of the same 10-01 close:**

| Basis | Retracement achieved (50% required) | Required further fall |
|---|---|---|
| **View (stored, mixed contract)** | (108.75 − 102.31) / 24.02 = **26.8%** | **−5.44%** |
| **Like-for-like, spread method**: Dec 102.31 + Nov–Dec spread 5.47 (09-30) to 6.43 (09-29) = Nov-equivalent 107.78–108.74 | **≈ 0.0% – 4.0%** | **≈ −10.2% – −11.0%** |
| **Like-for-like, path method**: Nov's last own settle 103.50 (09-30, 21.9% retraced) carried forward by Dec's +4.28 on 10-01 = 107.78 | **≈ 4.0%** | **≈ −10.2%** |

The two like-for-like methods are independent and agree. **So the price leg is at roughly 4% of a required 50%, the worst reading since the peak.** For comparison: 42.55% at the 09-22 best, 18.44% on 09-25, and 21.9% on Nov's expiry day. The view's −5.44% is the most flattering headline of the run apart from 09-22, and it is flattering because of the roll. **The governing surface and the price moved in opposite directions this week.**

**Stated limits of the estimate.** (1) Both methods assume the Nov–Dec spread held near its roll-date value. If backwardation widened between 09-15 and 09-29, the December contract's own peak was lower and true retracement is somewhat higher. The warehouse holds no second contract, so W3 cannot measure that. The 0–4% figure is an estimate, not a reading. (2) The **baseline is itself contract-mixed**: 2026-06-01 → 07-31 spans the end-June and end-July rolls. The midpoint therefore carries an unquantified roll component of its own. This is noted, not measured. (3) The 09-29 Nov settle is disputed across sources (102.59 vs 103.19). The path method uses the undisputed 09-30 settle and the warehouse's own 10-01 step.

**Reproducing W1's mislabelled figure.** On the view's baseline and peak, the stored-basis retracement at 10-01 is 26.8%. Under M1a's anchor-dependent baseline, it is about 30%. `5d3998df` item 3 gives that baseline implicitly: stored 49.7% at 09-30 with a 09-09 anchor ⇒ elevation ≈ 21.57, baseline ≈ 87.18; then (108.75 − 102.31) / 21.57 = **29.9%**. `5d3998df` itself uses "~30% at the 10-01 close (102.31)" to describe how far the **stored-basis** margin had moved. It quotes the *like-for-like* figure separately, as 24.4–25.0% on 09-30, which was **before** Dec's +4.28. W1 carried "~25–30%" across as like-for-like. **The like-for-like retracement at 10-01 is ~4%, not ~25–30%.** The direction of W1's conclusion survives; the magnitude it attaches is about seven times too generous. Filed to W1 (FILED THIS RUN).

**Return-path check on last week's claim.** Last week's file said the 09-22 → 09-24 setback was "recoverable by price alone", because the rally had not re-ratcheted the peak. That remains true of the peak, which is still 108.75. **It did not anticipate the roll**: the stored series then gave back ~6.4 for free on 09-29, which is the opposite of a price recovery. All of last week's within-window comparisons (09-15 peak, 09-22 best, 09-24 rally) are Nov-vs-Nov and stand as written.

### 4b. Leg (i): the quiet clock, now a three-way anchor spread

Counted against `state.market_calendar` (no holiday in range; 2026-10-12 is a trading day):

| Anchor (most recent qualifying event) | Held by | 15th quiet trading day | Status at 2026-10-04 |
|---|---|---|---|
| **2026-09-11** (Saudi export-pipeline drone strikes) | **M1a 2026-10-01 rubric row** (`3b6d1923`), which treats later flows as recovery | **2026-10-02** | **PASSES now** |
| **2026-09-23** (Libya El Sharara blockade + proposed US diesel-export ban) | W1 (W39 and W40), last week's W3 rubric test | **2026-10-14** | fails |
| **2026-09-28 / 09-29** (candidates sourced this run, **not adjudicated**, below) | no routine | **2026-10-19 / 10-20** | fails |

**Candidate events in this window, externally sourced and recorded so a later run can overturn them on better sourcing.** None appears in the warehouse. W1 found no physical event after 09-23 in the record.

- **2026-09-27 (Sunday):** the Petroleum Facilities Guard closed a valve on the Sharara pipeline again, and output fell below 100k bpd. **Single-sourced** (journaldeguinee.com, 09-27). NOC reported >300k bpd by 09-28. **No force majeure declaration is confirmed.** A Sunday event also raises the dating question `6081d304` already owns: is the anchor 09-27 or the first session, 09-28?
- **~2026-09-29:** three Liberian-flagged tankers were struck by projectiles in the Strait of Hormuz. It was reported Wednesday, "Tuesday" is inferred, and the date is **not cleanly established**. A physical attack on shipping in a chokepoint is a candidate under category 4's trade-flows alternative.
- **Not candidates, on the rubric's own text:** the Qatar LNG force-majeure **extension** (continuation, not a new event); Russia extending its own diesel export ban to 10-31 (pre-existing policy, extended); the US diesel-export-ban talk (still narrative: "thinking about it", a reported 90-day plan denied by the White House); and US rejection of Iran's Hormuz proposal (narrative, no measurable leg).

**What the spread decides, and what it does not.** Every anchor clears before 2026-11-02, so **W1's gate of 2026-11-02 holds under all of them**, and `Weekly_Catalyst_Calendar.md` needs no correction on this point. What the spread changes is whether leg (i) is *already* satisfied. **On M1a's own anchor it is, as of Friday.** That is what makes §4a's roll timing consequential: at the 2026-11-02 scoring, leg (i) passes under every anchor above, so leg (ii) alone decides the grade, and it would be read off a series that rolls ~10-29.

The dispute itself is not re-filed. `6081d304` (dating) and `11bbd3b7` (magnitude window) are both open, unadjudicated, and own it. This cycle adds only the measured fact that the spread grew from 2 trading days (W38) to 6 (W39) to **12 between the earliest and latest candidate** (10-02 → 10-20).

### 4c. Technicals: breadth kept falling, SPY trend touched NEUTRAL for one session

From `events.regime_events` (`scope` TECHNICAL_SIGNAL / TECHNICAL_INPUT; no correction rows in window):

```
date   breadth  label  SPY      50dma     trend    VIX    regime  10Y   2Y
09-24  45.12    WEAK   767.18   761.1532  UP       15.67  NORMAL  5.18  4.87
09-25  46.52    WEAK   771.35   761.5658  UP       14.87  LOW     5.17  4.81
09-28  43.93    WEAK   765.61   762.0122  UP       16.07  NORMAL  5.24  4.92
09-29  43.14    WEAK   764.20   762.4544  UP       16.04  NORMAL  5.26  4.89
09-30  40.55    WEAK   762.63   762.7414  NEUTRAL  16.34  NORMAL  5.29  4.88
10-01  41.15    WEAK   763.99   763.073   UP       16.39  NORMAL  5.24  4.78
```

- `leg_c_technical` **FALSE** on breadth alone, now **8.85pp** below the 50 line (4.88pp last week). Q1's retrospective (`4c0487f7`) measured breadth falling from 73.16% (08-13) to 40.55% (09-30).
- **SPY_TREND went NEUTRAL on 09-30 by 0.11 points** (762.63 vs a 762.7414 50dma) and returned to UP on 10-01 by 0.92. NEUTRAL does not break leg (c), which needs only SPY ≠ DOWN. But the index is now riding its 50-day average to within about 0.1% while breadth falls. That is the same narrowing advance last week's file described, one step further along.
- **Last week's breadth choice is vindicated by the tape.** Last week's file did not source 09-25 breadth, arguing that nothing turned on it because restoring leg (c) needed a 10.8% one-day rise. The warehouse now holds **46.52 WEAK** for 09-25.
- **The 10Y printed 5.29% on 09-30**, the high of the window. The 2Y is down from 4.92 to 4.78, so the curve steepened from 0.32 to 0.46 (still `NOT-SUSTAINED` inversion read).

### 4d. Rates and the October FOMC: a 50-point swing in a week

- **September payrolls (10-02): +29k vs ~84k expected.** Unemployment was 4.2% vs 4.1%, and July–August were revised down by a combined 60k (CNBC, 10-02). Core PCE for August (09-30) was 3.0% y/y, in line. Q2 GDP third estimate: 2.2% SAAR. ISM manufacturing for September: 54.5 vs 55.0, with prices paid at **77.9** vs 72.3.
- **Market-implied odds of an October 28 hike fell from ~64–70% (CME, 09-28) to ~25% (10-01) and ~17–18% (10-02, after payrolls).** Sources: CNBC 17%, Seeking Alpha 18.3%, Kalshi ~18%. December hike odds remain above 65–75%. Several sources agree; snapshot timing varies.
- **Correction to last week's file, not an error:** last week's "~60% hike / 40% hold" was single-sourced and dated 09-21. It is superseded by a large move, not refuted.

**Why this matters only through C.** Last cycle's file treated the move to 60/40 as *reducing* two-sidedness relative to September's 56/44. At ~18/82 the October decision is **more lopsided than at any point this file has recorded**. On that axis the rate event has become less, not more, of the genuinely uncertain catalyst C's edge statement wants. A 50-point repricing in five sessions is itself evidence that the path is uncertain even if the single meeting looks lopsided. W3 records both readings and adjudicates neither.

**Not obtained, stated:** S&P 500 % above 200dma (Barchart `$S5TH`) for 10-02. One search found no dated reading and the extract failed. Nothing turns on it: breadth would need +8.85pp in one session.

---

## STRATEGY C — the binds re-measured; last week's "pricing bind loosened" did not continue

**The live item W3 must not duplicate.** `thesis-FOMC-C-20261020` is `pending` on `PENDING_ANALYSIS`, due **2026-10-20**, for the **2026-10-28** decision. Its conservative default is decline. **D2 owns the GO/NO-GO.** Ahead of it sits **`div-C-202609-1`** (attacker 10-05, orchestrator 10-06, default RETAIN). M1b's raw call for C is DNA. If the review binds DNA, the FOMC item becomes router-ineligible, and D2/W4 must read the router after 10-06, not any weekly file.

**W1's measurements this cycle** (SPY 2026-10-30 expiry, ATM 770 vs 769.64, IBKR):

| | 2026-09-27 cycle | 2026-10-04 cycle | direction |
|---|---|---|---|
| Reachable capital | $19.49 | **$19.49** | flat; last week's −17.6% drift did not repeat |
| ATM straddle | $2,458 /contract | **$2,165.50 /contract** (≈111×) | cheaper, still unaffordable |
| IV source | broker `implied_vol` valid (12.7813%) | **broker field INVALID**; derived 12.74%, underlying 30-day 12.494% | **less precise** |
| IV / HV30 (spec window) | 1.309 | **1.322** (1.296 on the broker's 30-day IV) | flat |
| IV / HV10 | 1.080 | **1.162** | **richer** |
| HV10 / HV20 / HV30 | 11.83 / 10.76 / 9.76 | **10.96 / 10.32 / 9.64** | still inverted, less so |

**Self-correction.** Last week this file wrote that "the pricing bind loosened" and that "realized vol is rising *into* implied, which is the term structure that precedes a genuinely fairly-priced event". **The convergence did not continue.** HV10 fell 11.83 → 10.96, and IV/HV10 moved back out from 1.080 to 1.162. The premium at the spec window is flat. One week of convergence was reported as a trend, and it was not one.

**The conclusion that survives, and is unchanged in force.** C cannot be unblocked by the vol surface. $2,165.50 against $19.49 fails by a factor of ~111. The borrow channel still reads `donor_capacity_total` 0, `donor_count` 0 (`state.nomadic_borrow_capacity_watch`; `71d484fa` open). This is context for D2's 10-20 pass and the 10-06 review only. **W3 crafts, enqueues and adjudicates nothing.**

---

## STRATEGIES A, B AND E — no position, and what did happen

- **A.** DNA for the 7th consecutive cycle, on M1b's raw reasoning. The acute override is inert for A, so **A's gate does not depend on §4a or §4b at all**: an artifactual downgrade at 11-02 would not by itself activate A. W1 re-derived the gate at 2026-11-02 for the fourth cycle and examined the M1R path for the first time (`99ccd487`, its surface). W1's shortlist again carries XOM/CVX `SPENT-BY-GATE`, and the airline shorts remain DIRECTION-INADMISSIBLE.
- **B.** Flat 47/32 days. Sixth INDEX-MODE cycle. Index adds landed this week via D2 (`0b46baef` 5, `cfe254ba` 3, `12174735` 2), and **no capital moved**. The two W39 re-screens drained on 09-27: IONQ already satisfied, ORCL corrected, metric only. `rescreen-COST-B-20261004` is due tonight (D2). **B is the strategy whose DNA *is* the override.** An artifactual `latent` at 11-02 (§4a) would therefore reach B's router directly. That is the real-money consequence of the roll hazard, and the reason it is filed rather than noted.
- **E.** Raw call DNA independently (rate-duration factor), so the override is inert. **E has its first thesis items in this file's record:** M4 queued `thesis-CB-TRV-E-20261002`, `thesis-MCHP-ADI-E-20261002` and `thesis-MDB-SNOW-E-20261002` from M2's October screen (`50d589a2`, 85 pairs clear Layer 1). All three are due 10-02 and still `pending` (D2 last ran 10-01; tonight's D2 owns them), with a default of decline. Not this file's to drain.
- **E's balance is unchanged at $12,672.77** (`analytics.strategy_nav`). `state.regime_capital_sync_pending` still returns the single `SWEEP / E / blocked_no_recipient` row. **Correction to last week's file:** `regime_sweep_blocked` `b40cb3e6` is **resolved** (2026-09-30 22:48), and the condition is now carried by **`e722bd13` (09-30) and `22eeb107` (10-01)**, both open, both D2a. Two open rows for one standing condition is D2a's lifecycle question (dedup is on exact message), observed and not adjudicated. **Do NOT re-file.**
- **Capital rail, observed only:** `state.withdrawal_capacity` now reports `total_outstanding_regime_debt` **$13,291.72** against `total_donor_capacity` **$12,692.26**, so `restore_headroom_after_full_capacity` is **−$599.46**. Even a full restore of every donor's idle cash would not repay the regime debt owed to A, B and D. That is consistent with the ~$2,700 withdrawal on 09-23 having come out of the donor pool. Capital-rail surface. Not adjudicated, not filed.

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE

Every restated quantity was re-read from its owning surface.

1. **"The pricing bind loosened … realized rising into implied" → did not continue.** See the C section.
2. **"`regime_sweep_blocked` (`b40cb3e6`) … OPEN" → resolved 09-30; carried now by `e722bd13` / `22eeb107`.**
3. **"Market-implied ~60% October hike" → ~18%.** Superseded by a 50-point move, not refuted.
4. **"The whole setback is recoverable by price alone" → true of the peak, silent on the roll.** See §4a's return-path check.
5. **CONFIRMED: last week's externally-sourced 09-25 closes were exact again.** Brent 104.32, VIX 14.87, SPY 771.35, 10Y 5.17 and 2Y 4.81 all match the warehouse. The VIX `LOW` label inferred last week is the label D2a wrote. Across two cycles that is **8 of 8** externally sourced closes reproduced to the digit, which is why this run sources 10-02 the same way.
6. **CONFIRMED: the restatement hazard `82c99515` did not recur for a third consecutive window**, with one raw `BZUSD` row per date from 09-15 through 10-01. **It acquired a sibling instead:** the roll, recorded by the owner session as evidence on the same notice (`0c7fcaec`).
7. **CONFIRMED: last week's breadth non-sourcing call.** The 09-25 reading is 46.52, WEAK, as argued.

---

## COVERAGE STATED HONESTLY

**D1 coverage is complete:** `completed` on 09-27, 09-28, 09-29, 09-30 and 10-01, the full `daily_sun_thu` set. D2, D2a, D3 and M1R are likewise complete on all five dates. AR_orc has no 09-28 row (BigQuery OAuth de-auth; `queue_driven_missed_fire` `52a472fd` open). **The monthly chain slipped a day:** M1a's 10-01 trigger never fired, so M1b, M4, M5 and SL4 halted on their dependency gates on 10-01. M1a was run inline by an owner session on 10-02 (`5d3998df` records its caveats: file-blind rather than context-blind, plus anchor dependence), and M1b/M4 caught up the same morning. The `routine_run_failed` warnings for M1b, M4, M5 and SL4 remain open (OPS0/W5 surface). **None touches an in-scope position.**

**Friday 2026-10-02 is unobserved by the warehouse** (`marks_due_through` 2026-10-01 vs `last_trading_day` 2026-10-02). That is structural: Friday is absorbed by tonight's D1/D2a. Per the spec's 2026-09-13 clause, external sourcing is required. It was done and labelled:

- **Overlap validation:** FMP's values for **every** date 09-24 → 10-01 (Brent, VIX, SPY, 10Y, 2Y) equal the warehouse to the digit. That is six overlapping sessions, against one last week.
- **Brent 10-02 = 102.25** (Dec contract, FMP only), giving a view-basis required fall of −5.39%. No new high and no ratchet.
- **VIX 10-02 = 15.31** → would score `NORMAL`. **INFERRED** from an external close against a published threshold; D2a owns the label.
- **SPY 10-02 = 769.64** (it also matches W1's IBKR close). 10Y **5.28**, 2Y **4.83**. No 50dma is recomputed and no `SPY_TREND` claim is made, though at 769.64 against a 50dma near 763 the margin widened.
- **Breadth 10-02: not obtained** (§4d).

**System state at write time.** `state.system_health.all_green = TRUE`. **Zero open criticals**, and **113 open alerts (95 info, 18 warning)**, against 105 (85 / 20) last cycle: info up, warnings down by two. `state.trading_enabled = FALSE` with `halt_reason` "state.freshness marks_fresh/engine_fresh not both TRUE". `state.staging_halt_disposition` reads `halt_is_prerefresh_artifact = TRUE`, `gate_alert_action = 'defer_to_craft_site'`, `mechanical_enabled = TRUE`. That is the documented Sunday pre-refresh artifact. **W3 crafts no orders, so it raises nothing for it.** `state.open_orders` is empty, and `state.staged_order_reconciliation_overdue` is empty.

**Metered spend.** One external sub-agent, budget 14, **12 used**: 4 FMP calls (BZUSD, ^VIX and SPY EOD, plus treasury rates) and 8 Tavily calls (7 searches, 1 extract). **One failed**: the Barchart `$S5TH` extract returned "Failed to fetch url". One search returned zero results and was retried. All 12 are written to `ops.web_calls`, the failure included. Timestamps are real `date -u` reads, to within about 5 seconds for the parallel calls. The warehouse sub-agent and the orchestrator made BigQuery reads only, which are not metered.

---

## OBSERVED, NOT ADJUDICATED — do not re-flag

- **`82c99515` `shock_rubric_brent_peak_revisable`** (W3, 09-13): OPEN. `0c7fcaec` (owner session, 10-02) attaches the contract-roll evidence to it. This run's filing extends it with a date and is not a duplicate of either.
- **`6081d304` `shock_leg_i_event_anchor_undated`** (W3, 09-20) and **`11bbd3b7` `shock_leg_i_qualifying_event_test_underspecified`** (W3, 09-27): both OPEN and unadjudicated. §4b's widened spread is evidence for them, not a new finding.
- **`03b8f773`, `d9e55dc9`, `06c3b0db`, `3c755d0b`, `3897ecc6`**: the D1-side anchor family. All OPEN, all owned elsewhere.
- **`71d484fa` `nomadic_borrow_blocked`** and **`6f04ff75`**: OPEN. Together they own C's borrow condition.
- **`e722bd13` / `22eeb107` `regime_sweep_blocked`** (D2a): OPEN. They own E's blocked sweep.
- **`9ce935ae`, `4d135348`** (Brent prose quoting the prior session): OPEN, owned.
- **W5's intake congestion**: `cce77a41`, `c96b42e5`, `6f444586`, `ee81138f` and `16f282f0` are all OPEN warnings. This is relevant to filing. It is the only designated venue, so filing proceeds, with the congestion stated.
- **`99ccd487` `w1_catalyst_gate_omits_m1r_path`** (W1, today): W1's own surface.
- **`731e53d0` `blinding_side_channel_via_alert_board`**: the filings below are written strategy-neutral in their *message* text for that reason. The payload names consequences.

---

## FILED THIS RUN

**1. `ops.alerts` info, `source='W3'`, category `shock_price_leg_roll_precedes_scheduled_scoring`. Owner: `bigquery/217` (BZUSD ingest), `state.rerisking_limb_status` (`bigquery/224`) and the rubric slice. Nearest routine: W5 SPEC-DEFECT NOTICE INTAKE. To be disposed together with `82c99515`.** Alert id **`1039c8fa-f743-40bc-8eee-04b76632496f`**.
MEASURED: the stored series rolls ~2026-10-29 (Dec expiry 10-30). The next scheduled scoring is 2026-11-02, two trading days later. Leg (i) passes at that scoring under every anchor held in the fleet. At the last roll's 5.47–6.43 backwardation, a flat ~102 December price lands the post-roll stored close at ~96–97, at or through the 96.74 trigger. So a REQUIRED `acute` → `latent` downgrade can be manufactured by a contract roll at a gate-setting scoring. The 09-29 precedent shows it already happened for one session. `0c7fcaec`'s suggested fix (roll-adjusted series, or within-contract retracement) is an owner/live-SQL decision, and W3 makes no such change. **What W3 asks for is the dated deadline: the fix or an interim "roll-date flip = unverified" rule must reach the 11-02 scorer before 10-29.**

**2. `ops.alerts` info, `source='W3'`, category `w1_like_for_like_brent_retracement_mislabelled`. Owner: `Weekly_Catalyst_Calendar.md` PART 2A STEP 1 (routine W1, next fire 2026-10-11).** Alert id **`2bf52b18-06a4-42bc-8256-7105122f59b0`**. The ~25–30% "like-for-like" retracement is the stored-basis figure. Like-for-like at 10-01 is ~4%, consistent with W1's own −10% to −11% required fall. The fix is one figure. W1's direction of conclusion stands.

**What W3 did NOT do:** score or re-score any axis; edit the rubric, `bigquery/*`, `Strategy.md`, any slice, or `Weekly_Catalyst_Calendar.md`; adjudicate any candidate qualifying event; touch a queue item; craft, block or size anything; adjudicate `thesis-FOMC-C-20261020` or any divergence review; re-file any finding listed above.

---

## STEPS 1–6, DISPOSED

1. **Current thesis status:** no thesis in scope. Vacuous.
2. **Competitive landscape:** no position whose peers matter. Vacuous.
3. **Fundamental developments:** no position to accrue evidence against. Vacuous.
4. **Sector and macro context:** discharged by §4a (price leg and roll), §4b (quiet clock, three-way anchor spread), §4c (technicals), §4d (rates and FOMC), and the C section.
5. **Thesis-invalidation signals:** no criteria live in scope. Vacuous. (D1's daily sweep of the D book is M3's.)
6. **Time-to-thesis-resolution:** no resolution window open. Vacuous. Per spec, no convergence targets, time-exits or option-expiry mechanics were checked.

---

## WHAT W4 OWES ON THIS FILE — nothing, stated affirmatively

- **No `WEEKLY-THESIS-ACTION` flag.** No position-level recommendation and no `immediate_action_flagged` alert.
- **Zero queue-convertible items.**
- **Cross-strategy deconfliction is vacuous** with zero open in-scope positions.
- **`thesis-FOMC-C-20261020` is live and must not be re-minted.** `div-C-202609-1` (10-05/10-06) may change its router eligibility. Read the router after 10-06.
- **The shock-overlay measurement is evidence, not a referral.** W4 must not route it to M1a (blinding). The two filed alerts go to W5 and W1 respectively.
- **W1's 2026-11-02 gate is NOT invalidated** (§4b, every anchor). Its like-for-like retracement *figure* is wrong (filed to W1). Its conclusion and gate date are not.
- **B may hold positions by next cycle** if `div-B-202609-1` binds ACTIVATE on 10-06. That is not a W4 conversion, but next week's W3 should expect a non-vacuous Step 1.

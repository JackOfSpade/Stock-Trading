2026-W38

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-09-20 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W38
**Intake watermark:** 2026-09-13T08:33:27Z (this routine's own prior completion) · **Catch-up window:** 6.98 days = 1.00x the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` (`entry_type='post-event-enrichment'`, strategy B) · two `ops.alerts` rows raised (`screen_move_measured_on_opens` warning, `b_intake_population_coverage_unquantified` info), one resolved (`e1ff0ebc` `screen_fields_schema_drift`), one `events.queue_events` item enqueued (`rescreen-ORCL-B-20260920`).

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).** Fourth consecutive index-mode cycle.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It does not pull broad price bars to find movers, does not enumerate a population, does not repeat an event search, and does not re-judge D1's §19 significance verdicts. Its intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion; its job is B-specific eligibility, ranking and enrichment on top of that record.

The **2026-09-18 (Friday) session is deliberately uncovered** by this run and that is correct, not a gap in it. D1 runs Sun–Thu; its last screen covers the 2026-09-17 session, and D1's Sunday scan (tonight, after W2) owns 09-18. PART 1 forbids W2 covering that gap with its own bar pulls. One consequence is visible and recorded rather than acted on: SMR moved **−8.5177%** on 09-18 in a bar series this run already held, and that move belongs to the next D1, not to this file.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime` scope `STRATEGY_ACTIVATION` key `B` = **DO-NOT-ACTIVATE**, divergence `div-B-202608-1`, `as_of` 2026-09-03, theater-check DIVERGENT. Unchanged from the prior two cycles — no `STRATEGY_ACTIVATION` row of any kind has been written since 2026-09-03. So PART 2 runs in **INDEX MODE**: per eligible item this file records only ticker, qualifying event date, event-day close-to-close move, window close date, sessions remaining, a one-line factual event description, the originating D1 decision id, and a rank. The mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis and the convergence-indicator enumeration are **deliberately skipped**. The cohort-level work is kept in full, and this cycle it is the most informative part of the file.

**B's capital.** `state.strategy_capital_enablement` for B: `capital_disabled = TRUE`, `capital_enabled = FALSE`, latest activation 2026-09-03. Stated because it is a today-only fact and not a bar: an ACTIVATE-but-unfunded B would still get full-depth analysis. The zero funding is not why this run is in index mode; the router is.

---

## WINDOW ARITHMETIC

Convention, re-verified against the prior file's own published closes: **the qualifying event day counts as session 1 and the window closes on the 10th trading day inclusive** — that is, event date **+ 9 further sessions**, not +10. Validated: qed 2026-09-04 → 2026-09-18 reproduces the prior cycle's table exactly. A first pass inside this run used +10 and was caught and corrected against that check before anything was written; it is recorded here because the error would have overstated every remaining window by one session.

| Qualifying event date | Window closes | Sessions remaining after today |
|---|---|---|
| 2026-09-10 | 2026-09-23 | 3 |
| 2026-09-11 | 2026-09-24 | 4 |
| 2026-09-14 | 2026-09-25 | 5 |
| 2026-09-15 | 2026-09-28 | 6 |
| 2026-09-16 | 2026-09-29 | 7 |
| 2026-09-17 | 2026-09-30 | 8 |

Where a release preceded the reaction, the **window** runs from the qualifying event date while the **measured magnitude** is the reaction session's close-to-close move. Two different clocks, deliberately not merged. This cycle that separation binds six names: HPE, DELL, SMCI and ANET all carry `qualifying_event_date` 2026-09-10 (Oracle's capex disclosure, after the 09-10 close) and reacted on 09-11; SMR carries 09-16 and reacted 09-17; SRRK carries 09-11 (an after-hours FDA approval) and reacted 09-14. All six magnitudes reproduce D1's figure exactly on the reaction session, so the date offsets are the anchor convention working, not an error. The convention itself is still unwritten in D1's own spec — that is the already-open `d1_qualifying_event_date_anchor_unspecified` (`03b8f773`), not re-raised here.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five D1 `single-name-move` screens landed since the watermark, carrying **57 passed rows across 44 distinct tickers**:

| D1 decision id | Run date | Session(s) screened | Passed rows | `universe_measured` |
|---|---|---|---|---|
| `1f76f7cb-2a61-45ef-a6ae-f803923c0339` | 2026-09-13 | 2026-09-10 and 09-11 | 14 | 116 |
| `46d69e8d-81fb-47b6-8afc-bb749d95a7f5` | 2026-09-14 | 2026-09-14 | 14 | 33 |
| `13a0441f-fb4c-49e3-922c-bb806e83943e` | 2026-09-15 | 2026-09-15 | 13 | 23 |
| `873b8fad-0111-43e9-a015-1d252bb59dce` | 2026-09-16 | 2026-09-16 | 5 | 18 |
| `a913941a-3df1-43c5-916c-e77868c63da7` | 2026-09-17 | 2026-09-17 | 11 | 23 |

**One further `single-name-move` row crossed the watermark and is deliberately NOT intake.** `6a3be1bd-2ff5-4493-bbcb-aa2c27814a87` (2026-09-14) is a D2-authored **correction** of the 2026-09-03 D1 screen `b606229e-…`, which **W2 2026-W36 already consumed** — W36's own `d1_source_ids` array names `b606229e` explicitly. Its qualifying event dates are 09-02/09-03, inside W36's window, and its only substantive change is appending BMNR to `rejected_notable`. Treating a supersession of an already-consumed row as new intake would have re-ranked SNOW, CIEN, HPE, DELL and five others a second time. Matched on the fields and excluded.

That correction also closes a loop this routine opened: W36 raised `ed5e2e24` (`screen_move_no_disposition`) because BMNR's +14.7008% on 2026-09-03 had no disposition anywhere; W37 noted it still open; D2 drained `rescreen-BMNR-B-20260914` on 09-14 and wrote the correction. The referral worked end to end with no human step.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

The latest `thesis-construction` / strategy B identities anywhere in `events.queue_events` are the five of 2026-08-03 (AAPL, CARR, GDDY, LII, VRT), every one terminal `complete`. No `(analysis_type='thesis-construction', strategy='B', ticker, qualifying_event_date)` tuple exists for any 2026-09-10..09-17 event. **Zero collisions**, and no expired-window carry-in to exclude.

## PRICE-BASIS RECONCILIATION — ONE CORRECTION OWED, and it is the largest this lineage has recorded

Every magnitude reaching PART 1 was re-measured on IBKR regular-session daily bars (`STK`, `ONE_DAY`, `outside_rth=false`) per Operating_Protocols.md §19 PRICE BASIS. **20 of 21 names reproduce D1's figure to ≤0.006pp.** One does not.

**ORCL — D1 recorded −13.7912% for 2026-09-14; the true close-to-close move is −3.6532%.** The root cause is reproduced exactly rather than inferred: **−13.7912% is the OPEN-to-OPEN move** (2026-09-11 open 164.38 → 2026-09-14 open 141.71 = −13.7912%, matching digit for digit), where §19 requires close-to-close (150.28 → 144.79). D1 read the `open` array. The largest close-to-close move ORCL made anywhere in 2026-08-20..09-18 is +5.6878%, so no session in the window is within 8pp of the recorded figure.

Three things make this a finding rather than a suspicion:

- **The series is authenticated.** D1's *own earlier* ORCL figure — +5.6878% for 2026-09-03 — reproduces **exactly** on closes from the same contract (272800, ORACLE CORP NYSE) and the same pull. A wrong contract or a contaminated series could not do that.
- **D1's own text corroborates it.** Its ORCL reason says third-party sources "carry a 09-11 close of 150.28 against the IBKR 164.38, so their figures are unreliable". 150.28 **is** the true IBKR 09-11 close; 164.38 is that session's **open**. D1 had the right number in front of it, judged it unreliable against its own misread, and used the open.
- **It is bounded, not systemic.** Five other names on the same 09-14 screen were re-measured on closes and all reproduce: ZS +16.5249, NOK −13.2974, SRRK −6.4248, BAC −5.1364 (all ≤0.0001pp) and GEV −8.6193 against a recorded −8.6189.

This is a **new variant** of the §19 violation: every prior instance on record (CVS, COIN, GLW, UPS) was `get_price_snapshot`-instead-of-bars. This one is the right tool with the wrong field, which no existing check catches.

**Consequence, applied in this file.** At −3.6532% ORCL falls below Strategy B's frozen Entry criterion 1 (≥5% event-day close-to-close) and is **not rankable**. D1 recorded it as the highest-conviction item of that session (75, "Largest mega-cap move on the board"); the error promoted a sub-floor move to the head of the B queue. Because B is router-gated nothing was staged and no capital was exposed — but on an ACTIVATE cycle this name would have been ranked first or second. Filed as `ops.alerts` `screen_move_measured_on_opens` (warning) with `events.queue_events` item `rescreen-ORCL-B-20260920` for the durable correction, which is D1/D2 surface and not W2's to write.

## Items preserved from D1

### Rankable — passes BOTH D1's §19 significance judgment AND B's ≥5% frozen spec floor — 20 items

Every field below is D1's own except the reconciled magnitude. Ranking basis is **absolute event-day close-to-close move, descending, and nothing else**; criterion 1 and eligibility are applied as upstream gates, not as tie-breaks.

| # | Ticker | Qualifying event | Move | Reaction session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|
| 1 | SDGR | 2026-09-17 | +26.3766% | 09-17 | 2026-09-30 | 8 | `a913941a` | Tectora JV formed by contributing two early-stage programs for equity and royalties, no disclosed economics. |
| 2 | ENVA | 2026-09-15 | −23.4254% | 09-15 | 2026-09-28 | 6 | `13a0441f` | Withdrew the regulatory applications for the Grasshopper Bancorp acquisition, abandoning the bank-charter strategy while reaffirming guidance. |
| 3 | ALHC | 2026-09-15 | −19.8609% | 09-15 | 2026-09-28 | 6 | `13a0441f` | At the Baird healthcare conference management flagged rising medical-cost and hospital-billing headwinds and declined to discuss 2027 Star ratings. |
| 4 | GNRC | 2026-09-17 | +18.3370% | 09-17 | 2026-09-30 | 8 | `a913941a` | Up to $8B Amazon data-centre generator supply deal disclosed via regulatory filing, plus a warrant to Amazon for ~3% of shares. |
| 5 | VICR | 2026-09-17 | +17.6608% | 09-17 | 2026-09-30 | 8 | `a913941a` | Four quantified legs in one release: two NH sites for ChiP Fab-2/Fab-3, a VPD licence to a major AI OEM, a $150M buyback, backlog +145%. |
| 6 | ZS | 2026-09-14 | +16.5249% | 09-14 | 2026-09-25 | 5 | `46d69e8d` | Fiscal Q4 revenue $898.2M vs $877.0M consensus, adj EPS $1.19 vs $1.09. |
| 7 | SWKS | 2026-09-15 | +13.5503% | 09-15 | 2026-09-28 | 6 | `13a0441f` | CEO told an investor conference the $22B Qorvo merger has cleared all but two jurisdictions. |
| 8 | JBHT | 2026-09-16 | −13.3016% | 09-16 | 2026-09-29 | 7 | `873b8fad` | Morgan Stanley Laguna Conference warning that Q3 earnings could fall 5–10% vs Q2 on rising purchased-transportation costs. |
| 9 | NOK | 2026-09-14 | −13.2974% | 09-14 | 2026-09-25 | 5 | `46d69e8d` | Compound driver: AI-datacentre-capex slowdown hitting optical/networking, plus an exit from almost all mainland-China sites, plus a terminated business combination. |
| 10 | HPE | 2026-09-10 | +12.4411% | **09-11** | 2026-09-23 | 3 | `1f76f7cb` | Re-rated on Oracle's capex disclosure — a second-order repricing of an unquantified share of a third party's spend. |
| 11 | DELL | 2026-09-10 | +11.9776% | **09-11** | 2026-09-23 | 3 | `1f76f7cb` | Same Oracle read-through at $377B of market value, which is a far larger anomaly per unit of market cap than HPE. |
| 12 | RIG | 2026-09-15 | +8.9908% | 09-15 | 2026-09-28 | 6 | `13a0441f` | Won a ~$300M two-year ultra-deepwater drillship contract with ONGC; D1 discounts it because crude rose 2.9% the same session. |
| 13 | SMR | 2026-09-16 | +8.9157% | **09-17** | 2026-09-29 | 7 | `a913941a` | First-of-a-kind boron-oxide pellet fabrication for a passive emergency cooling system on an NRC-approved design. |
| 14 | MRNA | 2026-09-17 | +8.5495% | 09-17 | 2026-09-30 | 8 | `a913941a` | Phase 3 progress on the intismeran personalised cancer vaccine presented at the Morgan Stanley Global Healthcare Conference. |
| 15 | INTC | 2026-09-17 | +7.6695% | 09-17 | 2026-09-30 | 8 | `a913941a` | Analyst target hikes (Tigress $145, Northland Outperform) plus *reported* SK Hynix memory-production talks — the SK Hynix leg is a report, not a company announcement. |

**BELOW THE CAP — 5 eligible items, carried with the same fields so nothing is lost**

| Ticker | Qualifying event | Move | Reaction session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| SMCI | 2026-09-10 | +7.2766% | **09-11** | 2026-09-23 | 3 | `1f76f7cb` | Same Oracle read-through, in a name whose native volatility makes a +7% day ordinary. |
| SRRK | 2026-09-11 | −6.4249% | **09-14** | 2026-09-24 | 4 | `46d69e8d` | FDA approval of Isembyld (apitegromab-mstn, SMA) after the 09-11 close; gave back the entire approval pop while four brokers raised targets. |
| ANET | 2026-09-10 | +5.6087% | **09-11** | 2026-09-23 | 3 | `1f76f7cb` | The networking leg of the Oracle read-through; cleanest evidence the bid extended beyond servers. |
| BAC | 2026-09-14 | −5.1364% | 09-14 | 2026-09-25 | 5 | `46d69e8d` | CEO Moynihan guided Q3 investment-banking fees down >10% YoY and sales/trading flat against +33% in Q2. |
| TLX | 2026-09-11 | −5.1261% | 09-11 | 2026-09-24 | 4 | `1f76f7cb` | Fell on its confirmed 2026-09-11 FDA PDUFA goal date for Pixclara/TLX101-Px; the date is established, **the outcome is not** and no post-decision primary source was obtained. |

### Context only — `below_spec_floor = true`, never routable — 23 items

09-13 screen: MARA +4.8118, HAL −4.4267, QRVO +3.8180, STX −3.7297, GEV +3.6106, WDC −2.9835, UNH −2.3670.
09-14: RIG −3.8801, TSM −3.5153, NVDA −3.3579, GOOGL +3.2171, ISRG +2.3814.
09-15: GRAB −3.6424, SOFI −3.2860, PATH −2.9332, F −2.5974, AAL −2.5191, MARA −2.2609, AMZN −2.0194.
09-16: GEV +4.7893, INTC +4.0251, BAC −2.7218.
09-17: CRWV −4.1632.

### Identities EXCLUDED before enrichment — 13, every ground drawn from D1's own record, B's frozen spec, or this run's own measurement

**Criterion 1 — no identified public event (4).** SMR −15.6709 on 09-11 (`qualifying_event_date` NULL; D1: "NO identifiable public event was found"); SIMO −16.7569 ("no catalyst established beyond the semis selloff"); CRWD +13.8531 ("a record high on NO company news"); MRVL −7.3189 (sector sympathy, no named event).

**Spec floor, on this run's own corrected measurement (1).** ORCL, true move −3.6532% — see PRICE-BASIS RECONCILIATION above.

**The recorded move is not the event-day reaction (1).** SWKS +5.1410 on the 09-13 screen — D1's own text: "the EVENT DAY was 09-10, so the 09-11 move is not an event-day reaction and cannot anchor a B identity." SWKS re-enters legitimately at rank 7 on its distinct 09-15 event.

**D1 explicitly declined to route (6).** HBAN −5.5522 — D1: "explicitly NOT routed as a Strategy B candidate: a macro-driven sector repricing carries no company-specific information for B to exploit". OPEN −5.0179, the same class (10Y through 5% → broad iBuyer selloff), excluded on the same ground. MU +5.4994, SMCI +9.4979 (the 09-17 leg), AMD +6.3590 and HL +5.3919 — all four declined for B indexing by D1's own 2026-09-17 OPPORTUNITY CHECK as sector narrative or commodity beta. Honouring D1's verdict rather than re-judging it is what PART 1 requires.

**Analyst-action-only, on the W36/W37 RDDT precedent (1).** GEV −8.6189 — a GLJ Research Sell initiation stacked on a sector-wide datacentre-power repricing, with D1 recording that "GEV disclosed nothing". Also a held Strategy-D name. Note the asymmetry with INTC, which is ranked 15th on a similar analyst-driven move: the difference is that D1's own OPPORTUNITY CHECK routed INTC to B and did not route GEV. Recorded explicitly because the two look alike and a later cycle should not read the pair as inconsistent.

**Prior-disposition consistency (1).** BMNR −8.3851 — ETH/crypto-treasury beta. The identical class on this same ticker was dispositioned `rejected_notable` by D2's 2026-09-14 correction on the ground that sector beta is not a B qualifying event.

## Criterion 5 binds nothing this cycle

`state.current_positions` holds 12 open lots, **all Strategy D** (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER). Zero A positions, zero B positions. GEV, ISRG, GOOGL, AMZN and TSM appear in this week's intake but as **D** holdings, and the A/B mutual exclusion names A only.

## PRICE-LAYER COMPLETENESS BACKSTOP

Scanning the 21 reconciliation bar series for other ≥5% close-to-close sessions on days D1 screened found **24 such moves that appear in neither arm of that day's record** — 5 on 09-10, 2 on 09-11, 8 on 09-14, 2 on 09-15, 3 on 09-16, 4 on 09-17. Three further candidates were checked and discarded because they **are** recorded (INTC −5.5858 on 09-14 in `rejected_notable`; SMR −15.6709 on 09-11 and SMCI +9.4980 on 09-17 in `passed`).

**This is not a rail failure and is deliberately not filed as one.** D1's declared `universe_measured` for those sessions is 116, 33, 23, 18 and 23 — a bounded scan by cost, not a sweep of the US ≥$2B universe, so a ≥5% move in a name the scan never measured is outside it rather than dropped by it.

What it does establish is load-bearing for B, and is new: since the 2026-08-17 redesign W2's intake is *exclusively* D1's record, so **D1's bounded scan is the definition of B's candidate population** — and within a 21-name sample W2 already held, the ≥5% sessions absent from the record (24) outnumber those present (21). Filed as `b_intake_population_coverage_unquantified` (info), with the honest limit stated there: these 21 names were already selected as movers, so the 24 bounds nothing about the true population and must not be read as a coverage rate.

---

## POST-EVENT TRAJECTORY — the residual-thinness test

**This cycle's panel is better identified than any before it, and the reason is worth stating.** All four series below are measured on the **same date, 2026-09-18**, across four event vintages — 78 names in total. The market environment of that session is therefore common to every band, which removes the market-week confound the prior cycles could not remove. What remains confounded is cohort **composition**, and the data says that confound is the dominant one.

`gap_intact_pct` = (close 2026-09-18 − pre-event close) ÷ (event-day close − pre-event close) × 100. 100% = the whole move is still there; 0% = fully round-tripped; negative = reversed through; >100% = extended.

### Series A — this cycle's 20 eligible names, first observation (1–5 elapsed sessions)

| Ticker | Elapsed | Gap intact | | Ticker | Elapsed | Gap intact |
|---|---|---|---|---|---|---|
| SRRK | 4 | 246.1% | | INTC | 1 | 97.4% |
| ALHC | 3 | 178.6% | | SWKS | 3 | 88.5% |
| BAC | 4 | 154.0% | | SDGR | 1 | 80.7% |
| ZS | 4 | 120.5% | | HPE | 5 | 80.6% |
| VICR | 1 | 119.5% | | MRNA | 1 | 67.6% |
| JBHT | 2 | 106.8% | | SMCI | 5 | 62.9% |
| DELL | 5 | 101.3% | | RIG | 3 | 38.8% |
| GNRC | 1 | 100.7% | | NOK | 4 | 30.4% |
| ANET | 5 | 98.1% | | SMR | 1 | −4.1% |
| ENVA | 3 | 97.9% | | TLX | 5 | −113.1% |

n=20 · **mean 87.7%** · **median 97.7%** · sd 71.2 · min −113.1% (TLX) · max 246.1% (SRRK)

### Series B — cohort-3 (the 2026-09-13 cycle's 22 names), second observation (6–9 sessions)

n=22 · **mean 111.4%** · **median 96.0%** · sd 41.6 · min 54.3% (TSLA) · max 206.3% (CMCSA)
Prior observation at 09-11: mean 102.7%, median 99.8%, sd 29.0. **All 22 of the prior cycle's published residuals reproduce within 0.5pp** on an independent pull (largest divergence FICO, 0.46pp).

### Series C — cohort-2 (the 2026-09-06 cycle's 20 names), third observation (10–14 sessions)

n=19 (HPE excluded) · **mean 57.3%** · **median 61.6%** · sd 80.7 · min −100.0% (CRK) · max 212.9% (DELL)
Prior observations: 85.4% @1–5, 71.5% @6–10. HPE stays excluded on the prior cycle's own grounds and this run confirms why — the +12.44% move contaminating its 09-03 residual is the very move that enters this file as rank 10. The hand-off worked.

### Series D — cohort-1 (the 2026-08-30 cycle's 17 names), FOURTH observation (15–20 sessions)

n=17 · **mean 58.0%** · **median 69.6%** · sd 128.5 · min −190.1% (SNDK) · max 417.5% (BTDR)
Prior observations: 55.8% @1–6, 52.7% @5–10, 59.4% @11–15.

### What the cohort says

**FINDING 1 — the 2026-09-18 cross-section is NOT a decay curve, and the fourth series is what proves it.** Read by elapsed band the means run **87.7 → 111.4 → 57.3 → 58.0** and the standard deviations **71.2 → 41.6 → 80.7 → 128.5**. Neither is monotone. Three cohorts alone would have supported a tidy story — a residual decaying from ~111% to ~58% and a dispersion doubling each band — and adding the shortest-horizon series breaks both. Recorded as a refuted candidate finding so a later cycle does not re-derive it from three points.

**FINDING 2 — what actually dominates is cohort composition, not elapsed time, and this is now measurable.** At the same elapsed age of roughly one week the four cohorts' means were **55.8%, 85.4%, 102.7% and 87.7%** — a 47 pp spread. Each cohort's own change from its first observation to 2026-09-18 was **+2.2, −28.1, +8.7** and (for Series A) not yet observable: no consistent sign, and smaller than the spread between cohorts in every case but one. Cohort-1's four-point series, **55.8 → 52.7 → 59.4 → 58.0**, is flat across the full ~20 sessions. This is W37's FINDING 3 confirmed on a longer horizon and a new cohort, and it now has a stronger form: *which events are in the cohort* explains more of the residual than *how long you have held them*.

**FINDING 3 — the up/down coin flip replicates a third and fourth time.** From 09-11 to 09-18: cohort-3 split **11 rose / 11 fell** (exactly), cohort-2 **10 / 9** (HPE excluded), cohort-1 **9 / 8**. No cohort over any interval yet measured shows a directional tendency.

**FINDING 4 — a mean/median divergence that changes how this lineage should report the statistic.** Cohort-3's mean **rose** 102.7 → 111.4 while its median **fell** 99.8 → 96.0. A mean and a median moving in opposite directions is proof the mean move is outlier-driven (CMCSA 206.3%, BKNG 195.5%, GPCR 177.3%). Every prior cycle in this lineage reported the cohort **mean**; on distributions with sd up to 128 and a 600 pp range that is not the robust statistic. This file reports the median alongside the mean for every series and later cycles should continue to. Note what changes when you do: by median the four bands read **97.7 → 96.0 → 61.6 → 69.6**, far more orderly than the means, and consistent with a partial early give-back that then stops.

**FINDING 5 — the decision-relevant synthesis for B, stated so a divergence review can test it.** B's fundamental question is whether event reactions show measurable mean reversion at 2–8 week horizons. Across 78 names measured on one date at horizons from 1 to 20 sessions, the **typical** name retains roughly 60–100% of its event move at every horizon, and the spread around that is enormous and not a clean function of time. That is evidence **against** a generic mean-reversion premise and **for** reading B as a selection problem: whatever reverts has reverted before W2's intake can reach the name, and holding longer buys variance rather than convergence. This is an evidence series, not a verdict. B's machinery is frozen and W2 proposes no change to it.

**A correction to this lineage's own record, carried forward.** The 2026-W35 file lists BTDR's event-day move as **+9.01%** in its PART 1 and PART 2 tables, while its own PRICE-BASIS RECONCILIATION paragraph and trajectory table give **+8.31%** from closes 9.63 → 10.43. The 9.63/10.43 pair is the one carried through all four observations and it reproduces exactly; **+8.31% is the correct figure** and +9.01% corresponds to no adjacent close-pair in BTDR's series. Recorded here rather than raised as an alert: the W2 output file is overwritten each cycle, so the stale figure survives only in git history and in this note.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).**

The ranked list is the table in PART 1 — TOP-15 by absolute event-day move, then the five below the cap. Index mode records the seven mandated fields per item and skips the four per-candidate research steps. It does **not** skip the cohort work above, which is this cycle's substantive output.

## ROUTING — no thesis-construction enqueue is owed, and W4 must not create one

Route the top tier to `Watchlist.md`'s "Strategy B watch overflow" marked **router-gated, not rank-gated**, exactly as W4 §C directs. Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed.

**Every candidate in this file will expire ungraded, and this cycle that is provable rather than likely.** MEASURED:

- The latest window in the intake closes **2026-09-30**.
- The earliest reachable B activation write is **2026-10-01** — M1a, M1b and M4 fire on the first of the month (`ops/cadence.yaml` crons `0 11 1 * *`, `0 12 1 * *`, `0 15 1 * *`). Every window therefore closes **one session before** the only scheduled flip path can even begin, and a divergence-attached flip resolves later still (attacker +1 day, orchestrator +2).
- The **out-of-cycle path is blocked on one falsifiable price condition**, not merely idle. `state.rerisking_limb_status` for B: `leg_a_dwell` **TRUE** (31 dwell trading days), `leg_c_technical` **TRUE** (VIX NORMAL, SPY UP, breadth HEALTHY), `leg_b_price_leg` **FALSE** — Brent 104.82 against a retrace trigger of **96.74** (peak 108.75, baseline 84.73), basis `not_retraced`, as of 2026-09-17. `sql_limbs_fired` FALSE, and `events.queue_events` holds **zero** `PENDING_REGIME_REFRESH` rows in its entire history. So the re-risking limb is armed on two of three legs and gated on exactly one thing: **front-month Brent closing at or below 96.74, a further −7.71% from 104.82, before 2026-09-30.**

This is the first cycle able to state the blocker as a number rather than as "the router has not flipped". It is also worth recording that the *drain* half of this problem was genuinely fixed on 2026-09-14 — AR_orc now drains the B watch overflow the moment a divergence review binds B to ACTIVATE, rather than waiting for the next monthly M4 (`022d6490`, resolved). The remaining constraint is no longer the drain cadence; it is that nothing can flip the router inside a 10-trading-day window when the scheduled re-score is monthly and the only off-cycle path needs an 7.7% move in Brent.

---

## FINDINGS FOR D1 — two, upstream, not fixed here

1. **`screen_move_measured_on_opens`** (warning) — the ORCL open-vs-close error, root-caused exactly, with `rescreen-ORCL-B-20260920` queued for the durable correction. A new variant of the §19 PRICE BASIS violation that no existing check catches.
2. **`b_intake_population_coverage_unquantified`** (info) — D1's bounded scan is the definition of B's candidate population and its selection rule is unrecorded. Proposes recording the selection rule alongside `universe_measured`; explicitly does **not** propose widening the rail, which is a cost decision on D1/W5 surface.

**Resolved this run:** `e1ff0ebc` `screen_fields_schema_drift`, W2's own referral from 2026-W37. All five D1 screens since are clean on the four structural fields across both arms (77 item rows, zero missing). The one field still showing NULLs — `qualifying_event_date` on 10 rows — is correct: every one carries a reason string explicitly stating no public event was identified.

---

## HONEST LIMITS OF THIS RUN

- **The 24 backstop moves are not a coverage rate.** The 21 names were already selected as movers. Nothing here establishes what fraction of the true ≥5% population D1 surfaces, and W2 makes no such claim.
- **Four cohorts is not many.** FINDING 2 rests on four starting levels and three completed changes. It is consistent with "the level is set at the event and does not move" and also with "slow decay with large noise"; this run cannot separate them, and cohort-2's −28.1 is the case that keeps the second alive.
- **Series A's residuals are 1–5 sessions old.** They are a first observation and should be read as a baseline for the next cycle, not as a result.
- **Cross-cohort level comparisons remain confounded by composition** even though the measurement date is now common. That is the finding, but it also limits it: this panel cannot say *which* compositional feature drives the level.
- **TLX's event outcome is still unestablished.** Its PDUFA goal date is confirmed and its −5.13% reaction is measured, but no post-decision primary source was obtained by D1 and W2 performs no discovery, so no event-dependent criterion is assessed for it.
- **An IBKR data-integrity defect was live during this run's measurements** — `ibkr_price_history_parallel_cross_contamination` (`7cc25b71`), raised by W1 earlier today: `get_price_history` silently returns another ticker's series at concurrency ≥5. All four measurement passes were re-run or verified under a sequential/≤3-concurrency guard, and every one of the 79 measured names was cross-checked against an independently recorded event-day move plus a duplicate-statistic scan. **No contamination was found in any series**, and the two anomalies that did surface (ORCL, and the BTDR figure above) were both traced to the upstream record rather than the price feed. That is corroboration for W1's alert, not a refutation of it: the guard was applied precisely so the result would be interpretable either way.

---

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR versus US-listed-ordinary line, sixth consecutive cycle

Unchanged and still unwritten. Strategy B's instrument eligibility says "US-listed common equity" and the operative test is where the **primary listing** is, not the filing form. It decided CRDO in the 2026-09-06 cycle and NU below the cap. It binds nothing this cycle — all 20 rankable names are US-primary — but the line is still not written down anywhere, and the next cycle that surfaces an ADR will decide it again from scratch.

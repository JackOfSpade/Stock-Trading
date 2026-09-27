2026-W39

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-09-27 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W39
**Intake watermark:** 2026-09-20T08:32:46Z (this routine's own prior completion) · **Catch-up window:** 6.984 days = 0.998x the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `8dc13897-e834-4458-8860-04941eaa4ece` (`entry_type='post-event-enrichment'`, strategy B) · three `ops.alerts` rows raised (`62775339` warning, `3218eb3c` info, `3897ecc6` info) · two `events.queue_events` items enqueued (`rescreen-IONQ-B-20260927`, `rescreen-ORCL-B-20260927`, both due 2026-09-27 for tonight's D2 drain).

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).** Fifth consecutive index-mode cycle.

**THIS IS THE FIRST W2 RUN UNDER THE NO-PRICE-PULL BOUNDARY, and that is the run's defining methodological fact.** Commit `fee75d7` (2026-09-21 05:03:25 UTC, owner, interactive triage of `screen_move_measured_on_opens`) gave W2 a free RECORDED-FIGURE ARITHMETIC CHECK and restated that W2 pulls no price bars, assigning the broker re-measurement to D2. It landed **20.5 hours after** the 2026-09-20 W2 run, whose own durable record states its price basis as `IBKR get_price_history STK ONE_DAY outside_rth=false` across 21 reconciliation names and a 78-name panel. Every methodological difference below follows from that one change, including one consequence the change did not anticipate (see POST-EVENT TRAJECTORY).

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**: no broad bar pulls, no mover enumeration, no repeated event search, no re-judging of D1's §19 significance verdicts. Its intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion; its job is B-specific eligibility, ranking and enrichment on top of that record.

**And this cycle W2 pulls no price bars at all — not for reconciliation, not for the cohort panel.** The prior four cycles did both. What replaces the reconciliation is (a) the arithmetic check, which reads two numbers D1 already wrote, and (b) **D2's QUALIFYING-MOVE RE-MEASUREMENT**, the rail the same 2026-09-21 change created, which re-measures every B candidate's qualifying move on closes before any thesis work. D2 ran that rail on all five evenings of this window. Its figures are therefore this file's **measurement of record**, and they are better evidence than W2's own pull ever was, because they are produced by the routine that owns price tooling at the point where capital is about to move.

**The 2026-09-25 (Friday) session is deliberately uncovered** by this run and that is correct, not a gap. D1 runs Sun–Thu; its last screen covers 2026-09-24. D1's Sunday scan (tonight, after W2) owns 09-25, and PART 1 forbids W2 covering that gap with its own bar pulls. Unlike the prior cycle, W2 now has no bar series in hand at all, so it cannot even observe what it is not covering — a small, real loss of the price-layer backstop, recorded under HONEST LIMITS.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime` scope `STRATEGY_ACTIVATION` key `B` = **DO-NOT-ACTIVATE**, divergence `div-B-202608-1`, `as_of_date` 2026-09-03, theater-check DIVERGENT. Unchanged; no `STRATEGY_ACTIVATION` row of any kind has been written since 2026-09-03. So PART 2 runs in **INDEX MODE**: per eligible item this file records only ticker, qualifying event date, event-day close-to-close move, window close, sessions remaining, a one-line factual event description, the originating D1 decision id and a rank. The mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis and the convergence-indicator enumeration are **deliberately skipped**.

**B's capital.** `state.strategy_capital_enablement` for B: `capital_disabled = TRUE`, `capital_enabled = FALSE`, latest activation snapshot 2026-08-27. `state.strategy_roster`: B is **ADOPTED and active**, not incubating. Stated because the two facts are routinely confused: B is a live roster member that is deliberately not risking capital, and an ACTIVATE-but-unfunded B would still get full-depth analysis. The zero funding is not why this run is in index mode; the router is.

---

## WINDOW ARITHMETIC

Convention, unchanged from the prior four cycles: **the qualifying event day counts as session 1 and the window closes on the 10th trading day inclusive** — event date **+ 9 further sessions**. Trading days verified against `state.market_calendar`: no NYSE holiday falls between 2026-09-14 and 2026-11-15, so every non-trading day in the span is a weekend.

| Qualifying event date | Window closes (W2/W4 convention) | Window closes (D2 convention) | Sessions remaining after today |
|---|---|---|---|
| 2026-09-17 | 2026-09-30 | 2026-10-01 | 3 |
| 2026-09-21 | 2026-10-02 | 2026-10-05 | 5 |
| 2026-09-22 | 2026-10-05 | 2026-10-06 | 6 |
| 2026-09-23 | 2026-10-06 | 2026-10-07 | 7 |
| 2026-09-24 | 2026-10-07 | 2026-10-08 | 8 |

**Both columns are printed because `ops.alerts` `e3263203` (`b_window_close_convention_divergence`, raised by D2 2026-09-13, adjudication W5) is still open and this is the first cycle in which the one-session difference could have decided something.** D2's convention is 10 trading days *after* the event day; W2's and W4's counts the event day as session 1. The divergence does **not** flip any row this cycle — see PART 2's ROUTING section for the arithmetic — but it comes within one session of doing so, and that is new.

**Where a release preceded the reaction, the window runs from the qualifying event date while the measured magnitude is the eligibility session's close-to-close move.** The rule that decides which session that is: *an event that lands after the close makes the NEXT session the eligibility session; an event that lands intraday or pre-open makes THAT session the eligibility session.* This cycle the rule binds eight of the fifteen ranked names, and D2 applied it explicitly on every one.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five D1 `single-name-move` screens landed since the watermark, carrying **65 passed rows**:

| D1 decision id | Written (UTC) | Session screened | Passed | Rejected | `universe_measured` | Two prices recorded? |
|---|---|---|---|---|---|---|
| `ce24e9cb-603d-4c8e-81fa-1a7a9fad0ff6` | 2026-09-20 22:37 | 2026-09-18 | 15 | 4 | 39 | **No — 0 of 15** |
| `b86e1daa-2a6b-4faf-902b-ec6364777e7f` | 2026-09-22 22:12 | 2026-09-21 | 8 | 9 | 25 | Yes — 8 of 8 |
| `587a88e4-31b3-4899-ab31-26f9f63bbacc` | 2026-09-22 22:32 | 2026-09-22 | 26 | 6 | 43 | Yes — 26 of 26 |
| `91b1a00c-b80f-4a9c-992f-2f39f57479a2` | 2026-09-23 22:22 | 2026-09-23 | 7 | 3 | 14 | Yes — 7 of 7 |
| `6e179f3c-2c67-4a07-857c-b911ec051464` | 2026-09-24 22:18 | 2026-09-24 | 9 | 9 | 25 | Yes — 9 of 9 |

Two further rows crossed the watermark and are deliberately **NOT** intake:

- **`4264b87f-6d0e-4bf1-af9b-707c21ba7a47`** (written 2026-09-20 22:30) is D1's own **correction** of the 2026-09-14 screen `46d69e8d`, which **W2 2026-W38 already consumed** — W38's `d1_source_ids` names `46d69e8d` explicitly. Diffed item by item: **only the ORCL item changed** (`metric_pct` −13.7912 → −3.6532, `conviction_pct` 75 → 30, `below_spec_floor` false → **true**, `legacy_rule_pass` true → false), plus the mechanical `agreement` recount and a withdrawn ORCL comparison in NVDA's reason text. The other 13 passed items are unchanged. Treating a supersession of an already-consumed row as new intake would re-rank ZS, NOK, SRRK, BAC, GEV and eight others a second time. Matched on the FIELDS and excluded — the same disposition W38 reached on `6a3be1bd`, now a two-cycle precedent.
- **`d2aa2b42-ed38-4607-9417-6deb79e7ef1c`** (2026-09-23 22:18) landed with `fields.screen` and `fields.routine` absent and was corrected the same run by `91b1a00c`. It would not even match a `screen='single-name-move'` filter. `91b1a00c` is the operative row. The same shape hit three `sector-move` rows in the same window (`39deb2b3`→`730ccc29`, `372a84fa`→`e01d9ca6`, and `5bc3bb3c`→`4f06d0b0`); none is B intake and none is re-flagged here, because the missing-key defect is already carried by D1's own same-run corrections.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

Every `(item_type='thesis-construction', strategy='B', ticker, qualifying_event_date)` tuple in `events.queue_events` is **terminal**: 41 distinct `item_key`s, every one `status='complete'`, newest 2026-08-03 (AAPL, CARR, GDDY, LII, VRT). No tuple exists for any 2026-09-17..09-24 event. **Zero collisions, and no expired-window carry-in to exclude.** Both prior `re-screen` items are drained: `rescreen-ORCL-B-20260920` went pending→complete 2026-09-22, `rescreen-BMNR-B-20260914` on 2026-09-14.

## RECORDED-FIGURE ARITHMETIC CHECK — its first cycle, and it caught two things

The check ran on every intake item carrying both prices: **49 of the 65 passed rows.** Computed `(event_close/prior_close − 1) × 100` in SQL and compared to `metric_pct` at the recorded precision.

**48 of 49 reproduce**, with absolute differences from 2.5e-06 to 5.0e-05 percentage points — exactly the rounding noise expected from closes stored to two decimals. One does not.

**CATCH 1 — ORCL, `6e179f3c`, a transcription slip in one of the two recorded prices.** `metric_pct` **−3.4588** against the row's own pair **144.56 → 139.54**, which computes to **−3.4726065302**. The difference, **0.0138 pp, is ~280x the largest of the other 48**, so it is not rounding. The pair that *would* yield −3.4588 is **144.5393… → 139.54**, i.e. a `prior_close` of 144.54; equivalently an `event_close` of 139.5600 against 144.56. One of the two numbers is off by two cents. **This is a third, distinct variant of the §19 family:** CVS/COIN/GLW/UPS were wrong-tool (`get_price_snapshot`); ORCL 2026-09-14 was right-tool-wrong-field (the `open` array); this is right-tool, right-field, **wrong transcription**. It binds nothing — that ORCL row carries `qualifying_event_date = 'UNRESOLVED'` and `below_spec_floor = true`, so it was never rankable — but it is the check's first catch and it demonstrates the check works on exactly the defect class that needs no external data to see. Filed as `rescreen-ORCL-B-20260927`, due today for tonight's D2 drain.

**CATCH 2 — IONQ, `6e179f3c`, a structured flag that contradicts its own item's prose, and the cross-row close chain proves which one is wrong.** The item carries `qualifying_event_date = 2026-09-23`, `metric_pct = +5.7358`, pair **42.54 → 44.98**, and `below_spec_floor = false`. Its own `reason` says the opposite: *"on 09-23 the move is +4.4183% and misses the 5% floor by 58bp — it is the 09-24 continuation leg that clears, on the session the convention forbids testing."* The arithmetic is internally consistent (44.98/42.54 − 1 = +5.7358%), so an arithmetic check alone cannot see it. **A cross-row close chain can, and it is free:** `91b1a00c`'s IONQ item for the SAME `qualifying_event_date` records the pair **40.74 → 42.54**, and `6e179f3c`'s `prior_close` (42.54) is **byte-identical to that row's `event_close`**. The chain proves the +5.7358% pair measures the session *after* the anchor session. The eligibility-session move is **+4.4183%**, below B's frozen floor, and D2 did not index IONQ. So no candidate was minted and no capital was ever at stake; the defect is in the durable screen record. Filed as `rescreen-IONQ-B-20260927` and `ops.alerts` `62775339` (`d1_below_spec_floor_contradicts_own_anchor_prose`, warning).

**The same entry carries the same contradiction a second time, in the opposite direction, and D2 caught that one.** `6e179f3c`'s MGM item has `below_spec_floor = false` (correct) while its `reason` says *"on the 09-23 anchor the move is −2.6992% and criterion 1 fails"* (wrong — the buyout withdrawal was released 2026-09-23 18:05 ET, after the close, so 09-24 IS the eligibility session). D2 re-classified MGM as qualifying on 2026-09-24 (`4fc1abc0`, superseding `02137af9` once the primary-source timestamp was pinned). **So one D1 entry produced a flag/prose contradiction twice on the same day, once each way: a false positive nobody had filed, and a false negative D2 caught.** That pairing is the finding — not either instance alone — because it shows the failure is in how the anchor convention is being applied to the two independent fields, not in a single judgment.

**A CHECK-COVERAGE FINDING, and it corrects a plausible misreading of the spec's own date label.** The two-price contract says the keys are mandatory on D1 rows *"written from 2026-09-20"*, and W2's own text says *"NULL on older rows, which is expected and not a defect."* Read literally, `ce24e9cb` (15 items) and `4264b87f` (14 items) are 29 violations: both were written on 2026-09-20 and carry zero of the two prices. **They are not violations.** The clause landed in commit `fee75d7` at **2026-09-21 05:03:25 UTC**; those rows were written at 22:30 and 22:37 UTC on 2026-09-20, **~6.5 hours before the rule existed**. Both paragraphs' own text back-dates itself to the incident rather than the commit, which is what creates the false reading. The measured cost of the gap is real and belongs in this file: the arithmetic check covered **49 of 65** passed rows and was structurally blind to the entire 2026-09-18 screen — which supplies **three of this run's fifteen ranked names** (XENE, NUE, COIN). One-line clarification owed: the cutoff is the rule's landing commit, not its label date. Filed as `ops.alerts` `3897ecc6` (`d1_two_price_mandate_date_label_predates_its_own_landing`, info).

## MEASUREMENT OF RECORD — D2's re-measurement, not W2's pull

D2's QUALIFYING-MOVE RE-MEASUREMENT ran on all five evenings and **corrected D1's anchor on every candidate it touched.** The corrections, with the two that flip Entry criterion 1 in bold:

| Ticker | D1 anchor | D2 anchor | D1 figure | D2 eligibility-session figure | Effect |
|---|---|---|---|---|---|
| XENE | 09-18 | **09-17** | −30.6888 | −30.6888 (57.35 → 39.75) | anchor only; clears 6.1x |
| NUE | 09-18 | **09-17** | −6.3211 | −6.3211 (265.14 → 248.38) | anchor only; clears 1.26x |
| COIN | 09-18 | **09-17** | +11.6572 | **+5.7504** (164.51 → 173.97) | clears in its own right — the control that proves the correction is load-bearing, not uniformly disqualifying |
| **MSTR** | 09-18 | **09-17** | +16.3856 | **+4.8106** (126.18 → 132.25) | **criterion 1 flips PASS → FAIL, by 19 bp** |
| **BE** | 09-18 | **09-04** | −5.3889 | −5.3889 | **disposition flips: the window had already closed 2026-09-18, before D1 surfaced the name** |
| **MGM** | 09-23 | 09-23 | −2.6992 (anchor session) | **−10.9908** (37.85 → 33.69) | **criterion 1 flips FAIL → PASS** — the inverse error |
| SHOP | 09-21 | 09-21 | +7.1201 (reaction leg) | **+7.3307** (128.50 → 137.92) | eligibility figure supplied; clears on both legs |
| FSLY | 09-21 | 09-21 | +13.6887 (09-23 leg) | **+14.9204** (23.86 → 27.42) | eligibility figure supplied; D1's recorded magnitude was a non-eligibility session |
| GRAL / WBD / NVO | 09-21 | unchanged | as recorded | reproduced exactly | no anchor issue |
| SECZ | 09-24 | unchanged | +15.1114 | +15.1114 | no anchor issue |

**Every figure in PART 2 is D2's where D2 supplied one, and D1's otherwise.** Three points are worth stating plainly rather than leaving implicit:

1. **The anchor convention has displaced price basis as this lineage's largest source of criterion-1 error.** Of the four criterion-1 flips recorded in the last ten days, **three are anchor-driven** (MSTR, MGM, BE's disposition) and one price-basis-driven (ORCL). The open `ops.alerts` `d1_qualifying_event_date_anchor_unspecified` (`03b8f773`, D2, 2026-09-16) already names the cause — the convention is written only inside D2's own section and D1's prompt carries no equivalent limb — and it remains unresolved. This is the **fifth consecutive cycle** in which D1's anchor needed correcting at D2 (D2's own 2026-09-20 note says fourth; MGM on 09-24 makes five). Not re-filed; the count is the new evidence.
2. **D2 carried five of the six 2026-09-22 figures without a fresh pull** (VKTX, BFLY, CLDX, SNDK, RCL). Those five are D1's numbers, arithmetic-checked here and matching to ≤5.0e-05 pp, but not broker-re-verified by anyone. SNDK clears the floor by only **1.4x**, the narrowest margin in the intake, and D2 flagged it for re-measurement before any thesis work. Stated as a provenance fact, per the State-provenance rule: what was MEASURED by a second party is XENE/NUE/COIN/MSTR/GRAL/WBD/NVO/SHOP/FSLY/SECZ/MGM; what was measured once and checked only arithmetically is VKTX/BFLY/CLDX/SNDK/RCL.
3. **W2 losing the pull cost this file nothing on the reconciliation half, and the reason is worth recording** — D2 now does the same work one layer closer to the capital, on the whole candidate set rather than on W2's intake slice, and it caught two anchor flips that W2's magnitude-only reconciliation would have reproduced without noticing. The 2026-09-21 reassignment was the right call on its reconciliation merits. Where it cost something is the cohort panel, below.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor on the eligibility-session figure — 15 items, at the cap

Ranking basis is **absolute eligibility-session close-to-close move, descending, and nothing else**; criterion 1 and eligibility are upstream gates, not tie-breaks.

| # | Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|
| 1 | VKTX | 2026-09-22 | +35.6692% | 09-22 | 2026-10-05 | 6 | `587a88e4` | Company PR: VK2735 maintenance/tolerability topline. |
| 2 | GRAL | 2026-09-21 | +33.6759% | 09-21 | 2026-10-02 | 5 | `b86e1daa` | FDA staff briefing document partially de-risked the Galleri MCED test two days before its AdComm vote. |
| 3 | XENE | 2026-09-17 | −30.6888% | **09-18** | 2026-09-30 | 3 | `ce24e9cb` | Own GlobeNewswire release ~16:30 ET 09-17: voluntary pause of new trial enrollment on side-effect reports. |
| 4 | BFLY | 2026-09-22 | +21.9902% | 09-22 | 2026-10-05 | 6 | `587a88e4` | Needham initiating coverage at Buy — a sell-side initiation alone, no new company information. |
| 5 | SECZ | 2026-09-24 | +15.1114% | 09-24 | 2026-10-07 | 8 | `6e179f3c` | Pre-open issuer release: ARK tokenized the $1.3B ARK Venture Fund via Securitize on Ethereum. |
| 6 | FSLY | 2026-09-21 | +14.9204% | 09-21 | 2026-10-02 | 5 | `91b1a00c` | AI Firewall / AI Runtime Control launch, a dated issuer-sourced event. |
| 7 | CLDX | 2026-09-22 | −11.5598% | 09-22 | 2026-10-05 | 6 | `587a88e4` | Phase 3 EMBARQ-CSU1/CSU2 topline hit the primary endpoint in both trials — and the stock fell. |
| 8 | MGM | 2026-09-23 | −10.9908% | **09-24** | 2026-10-06 | 7 | `6e179f3c` | People Inc. withdrew its $48.30/share buyout proposal, released 18:05 ET 09-23 after the close. |
| 9 | WBD | 2026-09-21 | +10.7914% | 09-21 | 2026-10-02 | 5 | `b86e1daa` | Twelve state AGs settled the suit blocking the WBD/Paramount merger, removing a named quantified obstacle. |
| 10 | NVO | 2026-09-21 | −7.9556% | 09-21 | 2026-10-02 | 5 | `b86e1daa` | Announced 2030 growth ambitions — and fell on its own good news. |
| 11 | SHOP | 2026-09-21 | +7.3307% | 09-21 | 2026-10-02 | 5 | `587a88e4` | CEO's own post ~11:04 ET 09-21: Shop Pay checkout integrated inside Meta's Muse agent. |
| 12 | SNDK | 2026-09-22 | +6.8152% | 09-22 | 2026-10-05 | 6 | `587a88e4` | Rosenblatt initiating at Buy, $2400 PT — initiation only, no new company information. |
| 13 | NUE | 2026-09-17 | −6.3211% | **09-18** | 2026-09-30 | 3 | `ce24e9cb` | Own PR Newswire release 16:30 ET 09-17: Q3 diluted EPS guidance $5.55–5.65, below consensus. |
| 14 | RCL | 2026-09-22 | −6.1379% | 09-22 | 2026-10-05 | 6 | `587a88e4` | FT report of a ~$3B deal for 50% of Sandals Resorts — a press report of talks, not a confirmed deal. |
| 15 | COIN | 2026-09-17 | +5.7504% | 09-17 | 2026-09-30 | 3 | `ce24e9cb` | SEC "Innovation Exemption" release, public intraday 09-17 — tokenized-stock rulemaking, business-model channel. |

### BELOW THE CAP — 1 eligible identity, and it is the more decision-relevant of its ticker's two

| Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| GRAL | 2026-09-23 | +15.3797% | **09-24** | 2026-10-06 | 7 | `6e179f3c` | FDA Molecular & Clinical Genetics Panel met on the Galleri PMA; the anchor session was halted, so 09-24 is the first tradeable repricing. |

**This is a distinct identity, not a duplicate, and PART 1's rule is explicit that a later distinct event remains eligible.** It falls below the cap only because ranking is on absolute magnitude and rank 2 already holds GRAL's earlier event. **The point W4 and D2 should notice: D2 declined a second index row on the ground that the 09-21 identity's window is still open — so the identity that reaches `Watchlist.md` is the *smaller, earlier, pre-vote* event, while the *larger, later, post-vote* event is the one a thesis would actually want to be anchored on.** If B flips on 2026-10-01, M4 drains the 09-21 row, and whatever thesis D2 then constructs must state which event it is anchored on. Recorded here rather than filed as a defect: nothing is wrong with either routine's action, and the choice is a live judgment D2 owns at thesis time.

### Context only — below the frozen spec floor on the eligibility-session figure, never routable

- **MSTR** +4.8106% (09-17) — clears by 3.3x on D1's anchor, **fails by 19 bp on the corrected one**. Indexed FLAGGED by D2 rather than dropped. The single most instructive item in the intake: a 19-bp miss is what separates the top of a ranked B shortlist from ineligibility, and it turned entirely on which session the event happened in.
- **IONQ** +4.4183% (09-23) — misses by 58 bp on the anchor session; see CATCH 2.
- 2026-09-18 screen: ILMN −2.2677, STLD −4.1125, ETN +3.7391, MU +3.9182, NFLX −4.6738, DIS −2.5439, ISRG +2.5525, META −2.4271.
- 2026-09-21: PSKY −2.9383.
- 2026-09-22: AZO +3.2634, MPC −3.1562, VLO −4.1015, and ten undated items (BAC, CMCSA, DINO, GSHD, LPLA, MU, RJF, SCHW, SGRY, WFC — all `qualifying_event_date = 'UNRESOLVED'`).
- 2026-09-23: PCG −3.6491, RKT −4.6311, plus AMZN −2.2394 and GOOGL −3.7960 (undated, and both held Strategy-D names).
- 2026-09-24: DRI −3.0184, plus DIS +2.0298, INTC +3.9070, ORCL −3.4588 (all undated).

### Identities EXCLUDED before enrichment — 16, every ground drawn from D1's own record, D2's disposition, or B's frozen spec

**Window already closed before the name was surfaced (1).** **BE** −5.3889% — D2 re-anchored to the true S&P 500 *announcement* date 2026-09-04 (09-18 was only the rebalance-trade session), on which the 10-day window had closed **2026-09-18**, two days before D1 surfaced it. Criterion 1 also fails in substance: the information was fourteen days stale. D2 indexed it as a record, not a candidate. **This is the first item in this lineage to expire ungraded before it was ever surfaced**, and it is a cleaner statement of the cost of an unwritten anchor convention than any of the criterion-1 flips.

**D1 explicitly held the name out of routing (6).** **ARM** +17.1583% — *"ANCHOR RESOLVED to 2026-09-16 … held out of routing on dating, not magnitude"*; a 17% move five sessions after a TV interview, on the day AMD and INTC surged. **META** +11.3406% — *"held out of routing on event quality/dating"*; both legs mis-dateable, and the same ticker's 09-18 session move was −2.4271%, the opposite sign. **AMD** +9.9496%, **INTC** +12.1363% — *"one repricing, not three … no issuer disclosure"* and *"held out of routing on event quality"*. **SMR** −8.5177% and **GM** −5.1028% — D1 records no company event for either (sector complex; *"explicitly ZERO company news"*). Honouring D1's verdict rather than re-judging it is what PART 1 requires.

**Instrument-eligibility rail (3).** **MAZE** +26.753%, **GSHD** −11.4894%, **SGRY** +15.6662% — all three fail the $2B market-cap floor on D1's own measurement.

**Macro/sector axis with no name-specific event, on the HBAN/OPEN precedent (2).** **CDE** −5.7101% — *"real-yield shock (macro axis, not name)"*. **INOD** +14.611% — a third-party research note reading through from another issuer's news. Neither was indexed by D2.

**No identified public event (4).** **ALL** −5.5011% (a PR five sessions old; D1: today's move is cohort, not reaction), **GME** +5.58%, **GRAB** +8.9347% and **LEN** +6.3781% — all four carry `below_spec_floor = true` on their own anchor sessions because the eligibility-session move misses the floor, and D1 recorded that correctly. **VICR** +19.8481% belongs to this class too and is worth naming as the cycle's cleanest worked example of the convention: genuine new company information (a raised Q3 guide tied to a named AI-hardware royalty, in a $12B name, D1 conviction 75) released **after** the 2026-09-21 close, so the eligibility session is 09-21 at **+0.5298%** and criterion 1 fails on a +19.85% reaction. Nothing is wrong with the name; the frozen floor simply does not reach it.

## Criterion 5 binds nothing this cycle

`state.current_positions` holds **12 open lots, all Strategy D** (AMZN x2, DIS x2, GEV, GOOGL x2, ISRG, RTX, TSM x2, UBER). **Zero A positions, zero B positions.** DIS, ISRG, AMZN, GOOGL and INTC appear in this week's intake, but as **D** holdings or as sub-floor context, and the A/B mutual exclusion names A only.

---

## POST-EVENT TRAJECTORY — the measurement is SUSPENDED, and this is a spec defect, not a silent omission

**The cohort trajectory / residual-thinness test cannot be newly measured this cycle, and the reason is internal to W2's own spec.** The INDEX MODE bullet is unambiguous: *"**STILL DO** the cohort-level work — the post-event trajectory / residual-thinness test and any cohort-wide structural finding … Index mode must not silence them."* Three facts, each measured rather than assumed, make a new observation unreachable:

1. **`gap_intact_pct` has only ever been produced from IBKR `get_price_history`.** The 2026-09-20 run's own durable record says so in its `fields`: `"price_basis":"IBKR get_price_history STK ONE_DAY outside_rth=false"`, `"panel_names_total":78`, `"panel_measurement_date":"2026-09-18"`. Commit `fee75d7` then forbade that pull outright, 20.5 hours later.
2. **BigQuery holds no substitute.** The only two tables anywhere in the project carrying daily closes are `events.daily_marks` (24 tickers: the held-position roster plus SPY/VOO/SGOV) and `events.signal_marks` (14 tickers: the park-menu ETFs plus SPY and `^VIX`). Tested directly against 28 cohort tickers across all time — SRRK, ALHC, BAC, ZS, VICR, JBHT, DELL, GNRC, ANET, ENVA, INTC, SWKS, SDGR, HPE, MRNA, SMCI, RIG, NOK, SMR, TLX, CMCSA, BKNG, GPCR, BTDR, SNDK, CRK, TSLA, FICO — **zero matches, in either table, for every one of the 28.** Both tables' own headers say they are narrow by design.
3. **No other routine produces an equivalent series.** `gap_intact` appears nowhere in `Claude_Task_Plan.md` outside W2's own bullet, and the "future divergence review" that bullet names as the consumer is a downstream reader of W2's output, not an alternative producer.

So the same section that mandates the measurement forbids its only data source and offers no replacement. **Filed as `ops.alerts` `3218eb3c` (`b_cohort_trajectory_unreachable_under_no_pull_boundary`, info), owner `Claude_Task_Plan.md` W2 PART 2 INDEX MODE bullet plus the 2026-09-21 no-price-bar paragraph, adjudication surface W5 SPEC-DEFECT NOTICE INTAKE.** W2 does **not** resolve this by pulling bars anyway: the boundary was set by the owner in an interactive session on the evidence of a live incident, and a routine deciding for itself that a categorical instruction does not apply to it is a worse failure than a suspended measurement. The notice names two candidate fixes without choosing between them — grant the series a narrow, enumerated bar-pull carve-out scoped to cohort names already in the record, or reassign the series to a routine that already holds price tooling (D2 is the natural home, since it now re-measures every B candidate anyway).

### What replaces it: a within-name re-analysis of the already-published panel — no new measurement, and it settles a question the lineage left open

Every prior cycle's residuals survive in git history. Reconstructed from the five files that carry the section (`8b53d6a7`, `9bd54c59`, `3fa0da97`, `98fdc747`, `0c35b49c`), the published panel is **79 names with 1–3 per-name observations each**. Two validations first, because a re-analysis of someone else's numbers is worthless without them:

- **Every published cohort mean reproduces exactly** from the published per-ticker values: cohort-1 55.8 / 52.7, cohort-2 85.4 / 71.5, cohort-3 102.7, cohort-4 87.7. The dispersion convention is confirmed **sample** sd, not population: cohort-1's published 41.7 and 104.1 reproduce to the decimal on `stdev`, not on `pstdev`.
- **The one per-name value the lineage never published is recoverable by arithmetic.** W38 published cohort-1's 2026-09-11 aggregate at n=17 (mean 59.4, sd 74.8) while W37 itemized only 16 of the 17 — CRM's value is absent from every file. From the published mean and the 16 known values, CRM's 2026-09-11 residual is **90.8%**; substituting it returns n=17, mean 59.4, sample sd 74.8, both matching the published figures exactly. **The panel is therefore complete without a single price call.**

**Every prior cycle compared cohort MEANS across elapsed bands. None ever looked within a name.** That is the whole of what follows, and it needs no new data.

| Interval | n | Spearman rank correlation | mean change | median change | sd(change) | sd(level at start) | ratio |
|---|---|---|---|---|---|---|---|
| cohort-1, 2026-08-28 → 09-04 | 17 | **+0.509** | −3.7 | +0.0 | 100.5 | 39.5 | **2.54** |
| cohort-1, 2026-09-04 → 09-11 | 17 | **+0.632** | +8.6 | +4.5 | 58.3 | 102.8 | **0.57** |
| cohort-1, 2026-08-28 → 09-11 (two weeks) | 17 | **+0.273** | — | — | — | — | — |
| cohort-2, 2026-09-04 → 09-11 | 19 | **+0.618** | −13.9 | −1.0 | 37.2 | 26.3 | **1.42** |

Direction splits, now with a test statistic rather than a count: cohort-1 8 up / 8 down (two-sided sign test **p = 1.000**), cohort-1 second interval 9 / 7 (**p = 0.804**), cohort-2 9 / 10 (**p = 1.000**). Threshold crossings are rare — 3, 3 and 1 of the names cross 0%; 3, 2 and 2 cross 100%. Of the 16 cohort-1 names with three observations, only **5 are monotone**; 11 reverse direction between the two intervals (6 down-then-up, 5 up-then-down).

### What the cohort says

**FINDING 1 — W38's open question is now closed, on W38's own numbers.** W38's HONEST LIMITS stated that its data *"is consistent with 'the level is set at the event and does not move' and also with 'slow decay with large noise'; this run cannot separate them."* **The within-name view separates them.** If the level were set at the event and did not move, the week-to-week change would be small relative to the cross-name spread in the level, and the adjacent-week rank correlation would sit near +1. Measured: sd(change) is **0.57x to 2.54x** sd(level), and adjacent-week rank correlation is only **+0.51 to +0.63**. The first hypothesis is **refuted**; the second survives. This required no measurement the lineage had not already published — only the view it had not taken.

**FINDING 2 — the residual re-randomises on roughly a two-week timescale, and that interval is the same length as B's entry window.** Rank persistence is moderate week over week (+0.51, +0.62, +0.63 across three independent intervals and two cohorts) and then **collapses to +0.27 over two weeks**. A name's position in its cohort's residual distribution is therefore informative about next week and close to uninformative about the week after. **B's entry window is 10 trading days.** So the one quantity a post-event thesis would most want to persist decays to near-noise over exactly the interval in which B is allowed to act.

**FINDING 3 — this refines W38's FINDING 2 rather than overturning it, and the two together are the sharpest statement this lineage has reached.** W38 established that cohort *composition* explains the cross-cohort *level* better than elapsed time does; that stands and is untouched here. What is new is that *within* a cohort a name's rank is not durable. The synthesis: **the level is a property of the cohort, the rank is not a property of the name.** A B thesis that says "this name's move is the one that will persist" is making a claim the panel gives no support for; a B thesis that says "reactions of this event type in this environment behave thus" is making one it does.

**FINDING 4 — the up/down coin flip now has a p-value, and it replicates for the fifth and sixth time.** W36, W37 and W38 each reported a near-even split as a count. Sign tests on the three measurable intervals return p = 1.000, 0.804 and 1.000. No cohort over any interval yet measured shows a directional tendency, and the absence is now tested rather than merely observed.

**FINDING 5 — W38's median-first methodology change is adopted and the medians are supplied for every series that published only a mean.** cohort-1: 69.0 / 62.0 / 47.0 (against means 55.8 / 52.7 / 59.4). cohort-2: 83.0 / 81.0 (against 85.4 / 71.5). cohort-3 @09-11: 100.0 (against 102.7). cohort-4 @09-18: 97.7 (against 87.7). Note what this exposes that the means hid: cohort-1's **median falls monotonically** across all three observations (69.0 → 62.0 → 47.0) while its mean is flat (55.8 → 52.7 → 59.4). W37's FINDING 3 — *"the cohort MEAN does not move at all across up to 15 sessions"* — is **true of the mean and false of the median**, and the median is the statistic W38 itself ruled the robust one. Recorded as a correction to this lineage's own record: the typical cohort-1 name did decay, by 22 points over ~15 sessions, and only outlier growth at the top (BTDR 86 → 344 → 291) held the mean level.

**A SECOND CORRECTION TO THIS LINEAGE'S RECORD, carried forward.** W38's Series D published cohort-1's 2026-09-18 aggregate but, unlike every earlier series, **published no per-ticker values at all** — only SNDK and BTDR are named, as the extremes. That breaks the panel at its most valuable point: the only four-observation series in the dataset cannot be extended within-name past 2026-09-11, which is why FINDING 1's intervals stop there. Later cycles should itemize every series, not only the newest one; the aggregate is not a substitute, and this is now a measured cost rather than a stylistic preference.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, and unaffected by the suspended measurement

**S1 — event-type composition of the 15 ranked names is the most regulatory-heavy this lineage has carried.** Clinical or regulatory readouts 5 (VKTX, GRAL, XENE, CLDX, NVO); corporate action or M&A 3 (MGM, WBD, RCL); product or platform 3 (FSLY, SHOP, SECZ); sell-side initiation only 2 (BFLY, SNDK); issuer guidance 1 (NUE); regulatory rulemaking 1 (COIN). **Six of fifteen are binary regulatory or clinical readouts.** This matters for Entry criterion 3, whose convergence-target list admits *"next FDA decision date"*: that limb is reachable for five of them, against the one or two a typical cycle offers. W37's FINDING 5 first flagged the limb becoming reachable; this is the cycle where it would be the modal choice.

**S2 — direction is 6 down / 9 up, and two of the up-movers carry no company information at all.** BFLY (+21.99%) and SNDK (+6.82%) moved on sell-side initiations. D2 indexed both with the caveat recorded; W2 ranks both, because PART 1 forbids re-judging D1's significance verdict and D1 passed them. **The tension is worth naming, since neither routine owns it:** W38 excluded GEV on essentially this ground (analyst action, *"GEV disclosed nothing"*) — but only because D1's own OPPORTUNITY CHECK had declined to route GEV, whereas here D1 routed and D2 indexed. So the same fact pattern reaches opposite outcomes depending on an upstream routing call, not on a written rule. Not filed: no harm can follow while B is router-gated, and inventing a W2-side information-quality veto would be exactly the second significance screen PART 1 forbids. Recorded so a later cycle does not read the pair as inconsistent.

**S3 — the undated tail is a quarter of the intake and it is growing.** **16 of 65** passed rows carry `qualifying_event_date = 'UNRESOLVED'` or an anchor D1 could not pin, concentrated almost entirely in the 2026-09-22 screen (10 of its 26) where a whole financials cohort moved with no name-specific catalyst. None can anchor a B identity, so they are context by construction. The structural point: D1's anchor convention, added 2026-09-21, is doing its job — it is now *surfacing* the dating problem as an explicit `UNRESOLVED` rather than silently assigning the measurement session as the event date, which is what produced every one of this cycle's criterion-1 flips. The convention is working; what is missing is its absence from D1's own prompt (`03b8f773`).

**S4 — eligibility sits on the rail for two names, and W2 cannot resolve either without a metered call it should not make.** **SECZ** carries a market cap of **$2.447B** on D1's FMP figure, inside the $1.5–2.5B band in which §19 MARKET CAP BASIS says *"the eligibility verdict is not decided until shares outstanding is re-derived from the issuer's own most recently filed share count."* D2 recorded that SECZ's cap at the 2026-09-16 close was **$1.150–1.269B, below the rail on either basis** — the name clears only because of a six-session run of ≥5% moves, five of them within the last six sessions. So SECZ is ranked at 5 with its eligibility **unresolved**, which is the honest state: resolving it needs an `secFilings`/EDGAR call, and the right place to spend that is D2 at thesis construction, where the name is about to consume capital. **NVO** carries the standing ADR instrument-eligibility objection (`b_instrument_eligibility_adr_silence_unwritten`, `74c52a54`, open), which on this file's own precedent is terminal — see the OPEN QUESTION below.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).**

The ranked list is the 15-item table in PART 1, plus the one identity below the cap. Index mode records the seven mandated fields per item and skips the four per-candidate research steps. The cohort work is not skipped; its measurement half is suspended for the reason recorded above, and its structural half is in full.

## ROUTING — and for the first time in this lineage, the routing is load-bearing rather than ceremonial

Route all 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.

**Every prior cycle in this lineage reported that its candidates would certainly expire ungraded because every window closed before the only reachable flip path. That is FALSE this cycle, and it is the most decision-relevant fact in this file.** MEASURED:

- **M1a, M1b and M4 all fire on 2026-10-01** (`ops/cadence.yaml` crons `0 11 1 * *`, `0 12 1 * *`, `0 15 1 * *`; `monitor_class: monthly_ftd`). 2026-10-01 is a trading day.
- **M4's Strategy-B watch-overflow drain limb exists** (added 2026-08-30, closing `b_overflow_no_drain_consumer`) and selects rows satisfying BOTH filters — the Reason cell reading `Router-gated, not rank-gated.`, and the row's window still open on the flip date, **boundary EXCLUSIVE** — enqueueing them with `due_date` = the first trading day AFTER the flip, i.e. **2026-10-02**.
- **Applying that limb to this week's rows: 12 of the 15 would drain.** The 2026-09-21 cohort (GRAL, WBD, NVO, SHOP, FSLY) closes 2026-10-02, the 09-22 cohort (VKTX, BFLY, CLDX, SNDK, RCL) 2026-10-05, MGM 2026-10-06, SECZ 2026-10-07 — all strictly after the flip date. The **2026-09-17 cohort (XENE, NUE, COIN) does not**: its window closes 2026-09-30, the session *before* the flip.
- **The convention divergence does not change that count, but it comes within one session of doing so.** Under D2's convention the 09-17 cohort closes 2026-10-01 — the flip date itself — which M4's EXCLUSIVE boundary also excludes. The two conventions therefore agree here, for different reasons: W2's says the window is already shut, D2's says it shuts exactly on the boundary. **Had any candidate anchored on 2026-09-18 instead of 09-17 they would NOT have agreed.** W2's convention would give 2026-10-01, the flip date itself, so the EXCLUSIVE boundary excludes it and **nothing drains**; D2's would give 2026-10-02, strictly after the flip, so it **drains**. One session of convention decides the whole disposition of that cohort. D1 did surface 09-18-anchored names — all five of them — and the only reason the split did not materialise is that D2 re-anchored every one to 09-17 or 09-04. `e3263203` is no longer a cosmetic divergence, and W5 now has a worked example rather than a hypothetical.
- **Time-in-window after a flip is short for the earliest cohort.** The 09-21 cohort's `due_date` (2026-10-02) *is* the last session of its window: one session of life. The 09-22 cohort gets four, MGM five, SECZ six.

**THE ACTION THIS CREATES, and it is W4's tonight.** M4's limb reads **only** the "Strategy B watch overflow" section. D2's separate "Strategy B new-entry candidates (state index)" section — where all 15 of these names already sit — has **no drain consumer of any kind**. So a name indexed by D2 is *not* thereby drainable. **If W4 does not write these 15 rows into the overflow section with the exact `Router-gated, not rank-gated.` marker tonight, then the first cycle in this lineage whose candidates are actually reachable by the scheduled flip path will be lost to a routing gap rather than to the router.** W4 has written such a block on each of the last seven cycles, so nothing here suggests it will not; the point is that this is the first week where omitting it would cost something real.

**What would have to change on 2026-10-01, stated as a falsifiable number.** The binding constraint is the universal `shock_overlay = acute` override (`Strategy.md`:131, :1016), which has turned B's raw ACTIVATE into DO-NOT-ACTIVATE for two consecutive months. Rev 48 (2026-09-05) gave that axis the de-escalation rule it previously lacked: the `acute → latent` downgrade is **REQUIRED** once both legs hold — zero new qualifying shock events for 15 consecutive trading days, **and** Brent retraced at least 50% of the shock elevation. Leg 2 is a number: baseline **84.73**, peak **108.75**, so the trigger is **96.74**, and `state.rerisking_limb_status` reads Brent at **106.60** as of 2026-09-24, basis `not_retraced`. **Brent must fall 9.25% to 96.74 within the four sessions to 2026-10-01 for the downgrade to be required.** Leg 1 is not readable from this view; what would confirm it is M1a's October grading, which Rev 48 obliges to record the most recent qualifying event's date.

**And the out-of-cycle path receded this week on both of its movable legs, which is the opposite of last cycle.** `state.rerisking_limb_status` for B: `leg_a_dwell` **TRUE** (36 dwell trading days, up from 31); **`leg_c_technical` flipped TRUE → FALSE**, on exactly one failing conjunct — `equity_breadth` went **HEALTHY → WEAK** (VIX NORMAL and SPY UP both still pass; `technical_as_of` 2026-09-24 ≥ `technical_stale_floor` 2026-09-21 also passes); `leg_b_price_leg` **FALSE**, with Brent having moved **away** from the trigger (104.82 → 106.60, so the required fall widened from −7.71% to **−9.25%** in one week). `sql_limbs_fired` FALSE, and `events.queue_events` still holds **zero** `PENDING_REGIME_REFRESH` rows in its entire history. So the limb went from **2 of 3 legs armed to 1 of 3**.

**The synthesis, because the two halves point opposite ways and only the pair is informative.** The scheduled path became *reachable* for the first time — 12 of 15 windows now outlive the monthly re-score — while the out-of-cycle path became *less* reachable and the condition that would actually lift the override moved further away. Both paths converge on the same single number, **Brent ≤ 96.74**: it is leg 2 of the shock de-escalation rule and leg B of the re-risking limb, the same trigger computed from the same baseline and peak. **One price condition gates every route to a B entry, and it is 9.25% away with four sessions to run.** That is a sharper statement of B's position than "the router has not flipped", and it is the first time this file can name one number rather than a mechanism.

---

## FINDINGS FILED — three alerts and two queue items, all upstream, none fixed here

**`ops.alerts`:**

1. **`d1_below_spec_floor_contradicts_own_anchor_prose`** — `62775339-002b-4e12-8119-45409a6c4f01` (warning, owner `Claude_Task_Plan.md` D1 item 3 FIELDS-JSON KEY CONTRACT) — IONQ's `6e179f3c` item sets `below_spec_floor = false` from the 09-24 continuation leg while its own `reason` states the anchor-session move misses the floor by 58 bp "on the session the convention forbids testing". Proved by cross-row close chain, not inference: the item's `prior_close` 42.54 is byte-identical to `91b1a00c`'s `event_close` for the same `qualifying_event_date`. The same entry carries the mirror defect on MGM (flag right, prose wrong), which D2 caught on 2026-09-24. **The generalisable half is the check, not the instance:** a cross-row close chain tests whether a recorded price pair belongs to the session its `qualifying_event_date` implies, costs nothing, and catches a class the arithmetic check provably cannot see, because the offending pair is internally consistent.
2. **`b_cohort_trajectory_unreachable_under_no_pull_boundary`** — `3218eb3c-6fb2-4ce8-b983-02291a70dde6` (info, adjudication W5 SPEC-DEFECT NOTICE INTAKE) — the same W2 section mandates the trajectory measurement and forbids its only data source, with no BigQuery substitute (measured: 0 of 28 cohort tickers present in either of the project's two price tables) and no alternative producer anywhere in the plan. Two candidate fixes named, neither chosen.
3. **`d1_two_price_mandate_date_label_predates_its_own_landing`** — `3897ecc6-5a3b-4373-a9f5-0d45d7666731` (info, adjudication W5) — the clause's "written from 2026-09-20" label predates its own commit (`fee75d7`, 2026-09-21 05:03:25 UTC) by ~6.5 hours, so 29 correctly-NULL items read as violations. One-line clarification owed; the measured cost is that the arithmetic check covered 49 of 65 rows.

**`events.queue_events` (`PENDING_ANALYSIS`, drained by D2):**

4. **`rescreen-IONQ-B-20260927`** — correct the `6e179f3c` IONQ item to `below_spec_floor = true` at the anchor-session figure +4.4183%, superseding per D1's Late-data-discipline convention. The durable screen record is D1/D2 surface and not W2's to write.
5. **`rescreen-ORCL-B-20260927`** — the 0.0138 pp arithmetic mismatch on `6e179f3c`'s ORCL item (recorded −3.4588 against its own pair 144.56 → 139.54, which computes to −3.4726065302). A third distinct §19 variant: right tool, right field, **wrong transcription**, off by two cents in one of the two prices. Filed exactly as the RECORDED-FIGURE ARITHMETIC CHECK directs, and it is that check's first catch.

**Carried, not re-filed:** `d1_qualifying_event_date_anchor_unspecified` (`03b8f773`, open) — now with a fifth consecutive cycle of anchor corrections and three of the last four criterion-1 flips attributable to it. `e3263203` (`b_window_close_convention_divergence`, open) — now demonstrably decision-relevant. `b_intake_population_coverage_unquantified` (`08582955`, W2's own, open). `b_instrument_eligibility_adr_silence_unwritten` (`74c52a54`, open). `ibkr_price_history_parallel_cross_contamination` (`7cc25b71`, open) — moot for W2 now that it pulls nothing, and that is worth noting as the one unambiguous benefit of the boundary.

---

## HONEST LIMITS OF THIS RUN

- **The trajectory panel gains no new observation.** FINDING 1's refutation rests on three measurable intervals across two cohorts (n=17, 17, 19). That is enough to reject "the level never moves", because the rejection turns on a magnitude comparison rather than on a trend; it is **not** enough to estimate the re-randomisation timescale precisely. "Roughly two weeks" is bounded by the only two-week interval in the dataset, a single measurement.
- **FINDING 2's persistence collapse is one number.** ρ = +0.273 over 2026-08-28 → 09-11 in cohort-1 alone. Cohort-2 has no two-week interval published per-ticker, and cohort-1's own third and fourth observations were published as aggregates only. A second two-week interval would be the single most informative addition to this series, and producing one needs either the carve-out or the reassignment the notice proposes.
- **Five of the fifteen ranked figures were never broker-verified by anyone** (VKTX, BFLY, CLDX, SNDK, RCL — D1's numbers, carried by D2 without a fresh pull, arithmetic-checked here only). SNDK clears the floor by 1.4x, so a two-cent error of the ORCL kind would be enough to move it. Flagged rather than resolved: re-measurement is D2's at thesis construction.
- **The arithmetic check was blind to 16 of 65 rows**, including the whole 2026-09-18 screen, which supplies three ranked names. Those three carry D2's independent re-measurement instead, so they are not unverified — but they are not arithmetic-checked either, and the two are different assurances.
- **SECZ's instrument eligibility is unresolved, not resolved favourably.** §19 says the verdict is not decided inside the band it sits in, and W2 does not spend the metered call needed to decide it.
- **Nothing here re-tests D1's significance verdicts**, including on the two initiation-only names W2 ranks and would not have surfaced itself. That is the boundary working as designed, and it is also a real limit on what a rank in this file means.
- **W2 now has no price-layer completeness backstop at all.** The prior four cycles caught unrecorded ≥5% sessions (the 8/13 COHR miss, the 24 moves recorded in W38) because they held bar series incidentally. This cycle holds none, so this file can say nothing about what D1's bounded scan did not surface. `b_intake_population_coverage_unquantified` is now unmeasurable from W2's side, which strengthens rather than weakens it.

---

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR versus US-listed-ordinary line, seventh consecutive cycle

Still unwritten, and this cycle it **binds a ranked name for the first time.** Strategy B's instrument eligibility reads *"US-listed common equity"* with no ADR carve-out. The operative test this lineage has applied is where the **primary listing** is, not the filing form; it decided CRDO in 2026-09-06 and NU below the cap. **NVO is ranked 10th** and is a foreign-domiciled ADR whose primary listing is Copenhagen. D2 attached a standing instrument-eligibility objection to its index row (`b_instrument_eligibility_adr_silence_unwritten`, `74c52a54`, open since 2026-09-13) and recorded that on the standing precedent the objection is **terminal** — i.e. a thesis on NVO would be refused at construction, after a drain, on a rule that exists only as precedent.

Six cycles reported that the line binds nothing. It now does: NVO is one of the twelve names M4 would drain on a 2026-10-01 flip, and the first thing D2 would do with it is decline it. The question for the owner is unchanged and one sentence long: **is a US-listed ADR whose primary listing is foreign eligible for Strategy B?** Whatever the answer, writing it down removes a name from the queue before the queue is drained rather than after.

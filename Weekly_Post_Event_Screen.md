2026-W40

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-10-04 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W40
**Intake watermark:** 2026-09-27T08:40:06Z (this routine's own prior completion) · **Catch-up window:** 6.98 days, about the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `aab4fdbb-b379-4836-8d9c-ca5537c8634c` (`entry_type='post-event-enrichment'`, strategy B) · one `events.queue_events` item enqueued (`rescreen-COST-B-20261004`, due 2026-10-04 for tonight's D2 drain) · one `ops.alerts` row resolved as fix-verified (`62775339`).

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-02 — held pending `div-B-202609-1`).** Sixth consecutive index-mode cycle.

**The fact that decides this cycle:** the next reachable router flip is **not** M4. It is the **`div-B-202609-1` divergence review**: AR_att is due 2026-10-05 and AR_orc 2026-10-06. If AR_orc binds ACTIVATE, its **B WATCH-OVERFLOW DRAIN ON BIND** limb drains the overflow section **that same run**. **All 22 new identities in this file have windows that close after 2026-10-06, so all 22 are inside that path.** Of last cycle's 16 identities, only SECZ is. The next M4 (2026-11-02) reaches none of this cohort; every window here has closed by 2026-10-14.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It runs no broad bar pulls, no mover enumeration, no repeated event search, and no re-judging of D1's §19 significance verdicts. **It pulled no price bars of any kind**: that boundary is unchanged and `scripts/check_routine_scope.py` enforces it. Its intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion. Its job is B-specific eligibility, ranking and the cohort-level work on top of that record.

**The 2026-10-02 (Friday) session is deliberately uncovered**, and that is correct. D1 runs Sun–Thu and its last screen covers 2026-10-01. D1's Sunday scan (tonight, after W2) owns 10-02, and PART 1 forbids W2 covering the gap. NKE's 10-01 after-close print (reaction session 10-02) is the known item in that gap; D1 recorded it as "owed to the next D1".

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime` scope `STRATEGY_ACTIVATION` key `B` = **`DO-NOT-ACTIVATE — PENDING div-B-202609-1`**, `as_of_date` 2026-10-02. That row was written by M4's 2026-10 catch-up run: M1a missed its 2026-10-01 slot and M4's 10-01 fire halted on M1b. M4's rationale: the raw fundamental call is ACTIVATE on a stronger basis than last month, but the universal `shock_overlay = acute` override fires for the **third consecutive month**, so the reconciled state stays DO-NOT-ACTIVATE. The technical leg is ACTIVATE (SPY UP, VIX NORMAL), so the planes diverge, and the divergence review is queued (`events.queue_events` `div-B-202609-1`, `PENDING_REVIEW`, `due_date` 2026-10-05). Its conservative default if unresolved by 2026-10-06 is to retain the prior state. PART 2 therefore runs in **INDEX MODE**.

**B's capital.** `state.strategy_capital_enablement` for B: `capital_disabled = TRUE`, `capital_enabled = FALSE`. B is an adopted roster member that is deliberately not risking capital.

---

## WINDOW ARITHMETIC

**One convention only this cycle.** `ops.alerts` `e3263203` (`b_window_close_convention_divergence`) was **resolved 2026-09-28 by W5** (commit `2edc774`) on the INCLUSIVE convention: the qualifying event day is trading session 1 and the window closes on the 10th trading day inclusive. The dual-column table of the prior four cycles is retired. Trading days were verified against `state.market_calendar`; no NYSE holiday falls between 2026-09-23 and 2026-10-30.

| Qualifying event date | Window closes | Sessions remaining after today | Drainable on a 2026-10-06 AR_orc bind? | Sessions of life after the 2026-10-07 `due_date` |
|---|---|---|---|---|
| 2026-09-23 | 2026-10-06 | 2 | **No** (closes ON the bind date; EXCLUSIVE boundary) | — |
| 2026-09-24 | 2026-10-07 | 3 | Yes | 1 |
| 2026-09-25 | 2026-10-08 | 4 | Yes | 2 |
| 2026-09-28 | 2026-10-09 | 5 | Yes | 3 |
| 2026-09-29 | 2026-10-12 | 6 | Yes | 4 |
| 2026-09-30 | 2026-10-13 | 7 | Yes | 5 |
| 2026-10-01 | 2026-10-14 | 8 | Yes | 6 |

The window runs from the qualifying event date. The measured magnitude is the eligibility session's close-to-close move: an after-close release makes the NEXT session the eligibility session, and an intraday or pre-open release makes THAT session the eligibility session.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Seven D1 `single-name-move` rows landed since the watermark:

| D1 decision id | Session screened | Passed items | Floor-clearers, resolved anchor | Floor-clearers, UNRESOLVED anchor | Two prices recorded? | Note |
|---|---|---|---|---|---|---|
| `b712a5d7-7244-46d2-aaf0-a3c8286165bf` | 2026-09-24 | 9 | 3 (MGM, GRAL, SECZ) | 1 (TWST) | 9 of 9 | Correction #2 of `6e179f3c`, written by D2 draining `rescreen-ORCL-B-20260927`; **current effective record** |
| `5915447c-22b6-4dff-9204-2add2bb50f81` | 2026-09-24 | 9 | — | — | 9 of 9 | Correction #1 (D1, IONQ); superseded by `b712a5d7` |
| `b15a5838-419b-4899-85ca-7542c1c3a34d` | 2026-09-25 | 8 | 5 | 0 | 8 of 8 | |
| `e3c878dc-339b-4a20-87cc-291dc210cf13` | 2026-09-28 | 18 | 7 | 0 | 18 of 18 | |
| `f93a84d0-4c73-4672-be17-3c2fd58bd67a` | 2026-09-29 | 16 | 5 | 6 | 16 of 16 | |
| `795e6fb0-825d-4b57-83bd-08cc54d2e362` | 2026-09-30 | 11 | 3 | 1 | 11 of 11 | |
| `63af8a6a-064e-4f30-9760-dccf280036ad` | 2026-10-01 | 4 | 2 | 1 | 4 of 4 | Only row carrying `release_timing` per item |

**66 current passed items, all 66 carrying a two-price pair.** Last cycle 16 of 65 carried none. The two-price mandate is now fully adopted, so both free checks below reached every row for the first time.

**The two 09-24 corrections change nothing for ranking.** Diffed field by field against the original `6e179f3c`, the only changes are (a) IONQ, corrected by D1 to `below_spec_floor = true` at the anchor-session figure +4.4183% (40.74 → 42.54), exactly what `rescreen-IONQ-B-20260927` asked for; and (b) ORCL's derived `metric_pct`, −3.4588 → −3.4726065302, exactly what `rescreen-ORCL-B-20260927` asked for. Both W39 queue items closed within the same evening. MGM, GRAL (09-23) and SECZ carry identical figures in all three versions, so they are **carried from W39, not re-ranked** (see below).

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

`events.queue_events` holds **zero** `thesis-construction` / B rows since 2026-09-01, and `events.decision_log` holds **zero** B `thesis-construction` decisions in the same span. The only B `re-screen` rows (IONQ and ORCL, both NO-CHANGE or corrected) carry identities that are either already in this record (IONQ 2026-09-23, below floor) or undated (ORCL). **No intake identity is excluded by dedupe.**

## RECORDED-FIGURE ARITHMETIC CHECK — 66 of 66 rows, one mismatch

`metric_pct` was tested against `(event_close/prior_close − 1) × 100` on every current item. 65 of 66 reproduce to within 7.4e-05 pp, inside the 5e-05 half-unit of a 4-dp figure plus float noise.

**CATCH — COST, `b15a5838`, session 2026-09-25.** It records **2.9311** against its own pair 896.48 → 922.76, which computes to **2.9314652865**, or **2.9315** at the recorded precision. The difference is 0.000365 pp, about 5x the largest residual elsewhere in the intake. **Both implied prices round to the recorded two-decimal closes** (implied event close 922.7567, implied prior close 896.4832). So no price is visibly wrong and the slip is in the derived field alone. That is the same class D2 established for ORCL on 2026-09-27 when it refuted W2's transcription hypothesis. **No routing consequence**: COST is `below_spec_floor = true` on either figure. Filed exactly as the check directs: **`rescreen-COST-B-20261004`** (`PENDING_ANALYSIS`, D2), naming `b15a5838` as the supersede target. That row is the current effective record, with no row superseding it as of today. This applies D2's 2026-09-27 lesson: naming an already-superseded record leaves two contradictory effective records.

## CROSS-ROW CLOSE-CHAIN CHECK — 0 hits

The corpus is every non-superseded `single-name-move` item since 2026-09-10 (17 rows, 206 items). The test asks whether any other item carrying the same name and the same `qualifying_event_date` has an `event_close` equal to this item's `prior_close`, or a `prior_close` equal to its `event_close`. **Zero hits.** The one same-name, same-date pair is IONQ 2026-09-23, where `b712a5d7` and `91b1a00c` now carry the **identical** pair 40.74 → 42.54. That is the corrected state agreeing with itself, not a chain. Coverage is 66 of 66 intake items. Per §19, **a clean pass is not a clearance.**

**The check now runs upstream too.** Every D1 row since 2026-09-28 carries its own `close_chain_check` object (`ran: true`, 0 hits on each). Commit `2142752`, landed by W2 2026-W39, wrote the check into D1 item 3 and §19, and the data shows D1 executing it. That is why alert `62775339` (`d1_below_spec_floor_contradicts_own_anchor_prose`) was **resolved this run as fix-verified**. It had stayed open only because nothing resolved it after the fix landed.

## MEASUREMENT OF RECORD — D2's re-measurement, not W2's pull

D2's QUALIFYING-MOVE RE-MEASUREMENT has run on **17 of the 22** new identities: every 09-28, 09-29, 09-30 and 10-01 name. D2 used IBKR RTH daily bars, the close array, one ticker at a time. **All 17 reproduce D1 EXACTLY; nothing was superseded.** The five 09-25 names (ZS, PPLI, VIAV, TWLO, DELL) were indexed by D2 on 2026-09-27 without a fresh pull. They are arithmetic-checked here only, and D2 owns their re-measurement at thesis construction. DELL clears the floor by **13 bp** on an aggregator-dated anchor, which is the one item where that matters.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor on the eligibility-session figure — 15 of 22, at the cap

Ranking is by **absolute eligibility-session close-to-close move, descending, and nothing else**. Criterion 1 and eligibility are upstream gates, not tie-breaks.

| # | Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|
| 1 | KOD | 2026-09-28 | +177.9598% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | Phase 3 wet-AMD topline; gap-open 62.00 vs 32.35 prior close on 16.4x volume. |
| 2 | LQDA | 2026-09-30 | −57.1934% | 09-30 | 2026-10-13 | 7 | `795e6fb0` | Intraday Delaware ruling: Yutrepia infringes two claims of UTHR's '327 patent; halted intraday. |
| 3 | FICO | 2026-09-28 | −26.5219% | **09-29** | 2026-10-09 | 5 | `f93a84d0` | FHFA Director Pulte's after-close post moving Fannie/Freddie to a single pricing grid that adds VantageScore. |
| 4 | MDB | 2026-09-28 | −18.4582% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | CEO departed same-day, effective immediately, for Meta; ~17.8x volume. |
| 5 | ACN | 2026-10-01 | +15.7768% | 10-01 | 2026-10-14 | 8 | `63af8a6a` | Pre-open, issuer-verified FQ4 FY26 beat plus FY27 EPS guide. |
| 6 | CCL | 2026-09-29 | +13.4146% | 09-29 | 2026-10-12 | 6 | `f93a84d0` | Pre-open fiscal-Q3 beat with raised guidance. |
| 7 | GFI | 2026-09-28 | −12.8777% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | Gold-miner beta to a ~−3.5% spot-gold liquidation; no company event. |
| 8 | SNPS | 2026-09-30 | +12.7834% | **10-01** | 2026-10-13 | 7 | `63af8a6a` | Investor Day long-term model and FY27 guide, release 16:05 ET 09-30 (presentations ran intraday 09-30). |
| 9 | UTHR | 2026-09-30 | +12.5491% | 09-30 | 2026-10-13 | 7 | `795e6fb0` | The winning side of the same '327 ruling as LQDA (one event, two identities). |
| 10 | PPLI | 2026-09-24 | +11.3276% | **09-25** | 2026-10-07 | 3 | `b15a5838` | WSJ report, 18:26 EDT 09-24, that MGM is weighing a counter-bid; a bid-anchored move. |
| 11 | ZS | 2026-09-24 | −10.0587% | **09-25** | 2026-10-07 | 3 | `b15a5838` | Form 8-K Item 5.02: CRO departure for personal reasons, filed after the 09-24 session. |
| 12 | JBL | 2026-09-30 | −10.0301% | 09-30 | 2026-10-13 | 7 | `795e6fb0` | Pre-open FQ4 beat-and-raise (FY27 guide $44.5B / $17.55, AI revenue +54%) that sold hard. |
| 13 | VIAV | 2026-09-25 | +9.2667% | 09-25 | 2026-10-08 | 4 | `b15a5838` | CMMC Level 2 certification; D1 calls it thin news for a 9.3% move (conviction 45). |
| 14 | CRDO | 2026-09-28 | −8.6742% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | AI-hardware complex repriced on OpenAI's announced training pause; no disclosure of its own. |
| 15 | TWLO | 2026-09-25 | −7.9623% | 09-25 | 2026-10-08 | 4 | `b15a5838` | HSBC downgrade to Reduce, PT $211; analyst action only. |

### BELOW THE CAP — 7 eligible identities, all drainable on a 2026-10-06 bind

| Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| RCL | 2026-09-29 | +7.4529% | 09-29 | 2026-10-12 | 6 | `f93a84d0` | Read-through of CCL's pre-open release; RCL issued nothing. |
| AIR | 2026-09-28 | −7.2465% | **09-29** | 2026-10-09 | 5 | `f93a84d0` | Fiscal Q1 FY27 beat (16:50 ET 09-28) paired with a debt/PIPE-funded 65% MRO Holdings acquisition. |
| BA | 2026-09-28 | −6.9066% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | Reported 737 MAX landing-procedure software glitch; ~3.9x volume. |
| HL | 2026-09-28 | −6.4871% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | The same gold/silver liquidation as GFI. |
| SMMT | 2026-09-28 | +5.8786% | **09-29** | 2026-10-09 | 5 | `f93a84d0` | AstraZeneca $2B equity investment, announced after the 09-28 close. |
| INTC | 2026-09-28 | −5.6667% | 09-28 | 2026-10-09 | 5 | `e3c878dc` | The same OpenAI-pause semiconductor selloff as CRDO; no Intel disclosure. |
| DELL | 2026-09-25 | +5.0129% | 09-25 | 2026-10-08 | 4 | `b15a5838` | $60.9B in new AI-server orders, backlog to $95B; clears the floor by 13 bp on an aggregator-dated anchor. |

**Why the cap matters this cycle, and why it does not decide anything W2 owns.** The drain limb selects overflow rows by marker and window, not by rank tier. So whichever of these 22 W4 writes into the overflow section with the `Router-gated, not rank-gated.` marker is drainable on a 10-06 bind, and whichever it omits is not. Last cycle W4 deliberately carried W2's one below-cap identity. Whether to carry all seven here is W4's call under §C. W2 records that **each of the seven would be a live drain candidate**, and that four of them share a driver with a ranked name (RCL with CCL, HL with GFI, INTC with CRDO) or depend on a 13-bp margin (DELL).

### CARRIED FROM W39 — not re-ranked, because the corrections that re-surfaced them changed nothing

| Ticker | Qualifying event | Move | Window closes | Status on a 2026-10-06 bind |
|---|---|---|---|---|
| SECZ | 2026-09-24 | +15.1114% | 2026-10-07 | **Drainable, one session of life.** Instrument eligibility is still UNRESOLVED: cap $2.447B, inside §19's $1.5–2.5B band. |
| MGM | 2026-09-23 | −10.9908% | 2026-10-06 | **Not drainable**: the window closes on the bind date itself. |
| GRAL | 2026-09-23 | +15.3797% | 2026-10-06 | **Not drainable**, same reason. |

They re-entered the intake only because `b712a5d7` and `5915447c` are new rows for an already-consumed session. Their overflow rows from W39 already exist, so W4 owes no second row for any of them.

### Context only — below the frozen spec floor on the eligibility-session figure, never routable

- 2026-09-24: IONQ +4.4183 (corrected), DRI −3.0184; undated ORCL −3.4726, INTC +3.9070, DIS +2.0298.
- 2026-09-25: BB +4.1766 on the anchor session. The sign inverts against the −5.9565% Friday continuation, which the convention forbids testing. Also COST +2.9311 (see CATCH), AKAM +3.1971.
- 2026-09-28: META −4.7947, NEM −4.4305, RKT −4.355, TSLA −3.9397, SOFI −3.9204, NOW −3.0748, CRM −2.8844, MU −2.6149, AAL −2.5234, SNOW −2.3278, UAL −2.1756.
- 2026-09-29: KMX +4.7392 (misses by 26 bp on an issuer-verified beat), GLW +4.6969, ORCL +3.914, AAPL −2.6596, MTN +2.3173.
- 2026-09-30: CAG −4.8832, NOC −4.1874 (anchor 09-29 after close), FDS +3.8389, GME +3.7458 (anchor 09-29 after close); undated GIS −4.9083, HPE +3.9031, MDB +3.3868 (the 09-30 rebound leg of rank 4's name, a separate undated item).
- 2026-10-01: MU +3.0307 (anchor 09-30).

### Floor-clearers that cannot anchor an identity — 9, all `qualifying_event_date = 'UNRESOLVED'`

TWST +16.1073 (09-24), IOVA +31.4832, BE +10.7962, DKNG −7.4197, DUOL +6.1951, AMAT +5.1874, LITE +5.6625 (all 09-29), MRNA −5.3524 (09-30), MCK +5.2717 (10-01). **W2 does not date them.** Assigning an anchor would be the second significance and dating screen PART 1 forbids, and D1 left each undated with a stated reason (a release time not retrievable, two candidate drivers, or a multi-session rally with no dated release). See S3.

### Identities EXCLUDED before enrichment — 0

No intake identity is excluded on dedupe, expired window, criterion 5 or the instrument rail this cycle. D1's own rail and anchor discipline did that filtering upstream: everything that cleared the floor either carries a resolved anchor and appears above, or is undated and listed in the previous subsection.

## Criterion 5 binds nothing this cycle

`state.current_positions` holds **12 open lots, all Strategy D** (AMZN x2, DIS x2, GEV, GOOGL x2, ISRG, RTX, TSM x2, UBER). **Zero A positions, zero B positions.** INTC appears in the intake as a B identity; the A/B mutual exclusion names A only.

---

## POST-EVENT TRAJECTORY — still a GAP, named as one, and not improvised

The INDEX MODE bullet's 2026-09-27 pin governs. The forward-close measurement the trajectory test ran on through 2026-W38 needs a post-event close per cohort name per date. **No such layer exists, re-measured this run.** `events.daily_marks` (24 tickers) and `events.signal_marks` (14 tickers) hold **zero rows for any of the 36 cohort tickers** across W39 and W40. The `events` dataset has no other price-bearing table (only `daily_marks`, `signal_marks`, `option_marks`, `market_holidays`). So: **no substitute series, no missing observation read as a zero, no reassignment on W2's authority.** Alert `3218eb3c` (`b_cohort_trajectory_unreachable_under_no_pull_boundary`) stays open with W5.

**What the within-name panel gains this cycle: nothing, and that is the honest entry.** The panel W39 reconstructed (79 names, 1–3 observations each, cohort-1 through cohort-4) ends at 2026-09-18. W39 published no new observation, because it was the first no-pull cycle, and W40 cannot produce one. W39's FINDINGS 1–5 therefore stand exactly as published and are neither strengthened nor weakened. Above all, the ~two-week re-randomisation timescale remains **one measurement** (ρ = +0.273, cohort-1, 2026-08-28 → 09-11). The gap is now two cycles old. Every cycle that passes without the layer is a cohort whose forward trajectory can never be reconstructed later, because the evidence is a close on a date that has gone by.

### What W2 CAN add from its own durable record: the GRADING OUTCOME series, itemized per ticker

This series needs no price data. It asks what happened to each published candidate. It is the evidence B's convergence assumption most directly lacks: not whether a mispricing converged, but whether any candidate ever reached the point of being tested.

**W39 cohort (16 identities), itemized:**

| Ticker | Qualifying event | Window closed / closes | Outcome |
|---|---|---|---|
| XENE, NUE, COIN | 2026-09-17 | 2026-09-30 | Expired ungraded. Closed before any flip path. |
| GRAL, FSLY, WBD, NVO, SHOP | 2026-09-21 | 2026-10-02 | Expired ungraded. W39 counted all five drainable on a 10-01 M4 flip; no flip occurred (M4 2026-10 catch-up, 10-02: NO NET FLIP). |
| VKTX, BFLY, CLDX, SNDK, RCL | 2026-09-22 | 2026-10-05 | Will expire ungraded: closes before the 10-06 bind. |
| MGM, GRAL (2nd) | 2026-09-23 | 2026-10-06 | Will expire ungraded: closes ON the bind date (EXCLUSIVE). |
| SECZ | 2026-09-24 | 2026-10-07 | The **only** W39 identity alive on a 10-06 bind, with one session of life, and its instrument eligibility unresolved. |

**Lineage tally.** Across six consecutive index-mode cycles and eight router-gated overflow blocks to date (W4's count; tonight's would be the ninth), **not one published B identity has been evaluated against B's entry criteria.** The 2026-08-24 limb that created INDEX MODE cites 15 full-depth analyses from three cycles, all expired ungraded. Every cycle since has added to the count, and none has subtracted from it.

**A near miss inside the M4 path, recorded rather than filed.** M1a missed its 2026-10-01 slot and M4's 10-01 fire halted on M1b, so the monthly router write landed on **10-02**. Had it bound ACTIVATE, the drain's EXCLUSIVE boundary on a 10-02 flip would have excluded the five-name 09-21 cohort, whose window closed 10-02. On an on-time 10-01 flip all five would have drained. **One day of upstream lateness was worth five drainable candidates.** It cost nothing because B did not flip. Not filed: the miss already has its owner and alerts (OPS0 / `missed_run`), and nothing is wrong with the drain rule.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, and unaffected by the gap

**S1 — 22 identities, 18 independent events.** Four shared-driver pairs: GFI/HL (gold liquidation), CRDO/INTC (OpenAI training pause), LQDA/UTHR (the same Delaware '327 ruling, **opposite signs**), CCL/RCL (CCL's pre-open release). Within the ranked 15, only LQDA/UTHR shares a driver, so the 15 hold 14 independent events. This matters for B's concurrent-position correlation (Section 6 / KL #12), which replaced the retired per-sector cap. If a 10-06 bind drained all 22 into D2, four pairs would arrive as eight candidates that are in substance four bets.

**S2 — event-type composition of the ranked 15 tilts to earnings, where W39's tilted to regulatory and clinical readouts.** Earnings or guidance 4 (ACN, CCL, JBL, SNPS); legal or regulatory 3 (LQDA, UTHR, FICO); personnel 2 (MDB, ZS); commodity or sector beta with no company event 2 (GFI, CRDO); clinical 1 (KOD); bid report 1 (PPLI); certification 1 (VIAV); analyst action 1 (TWLO). Direction is **8 down / 7 up**, consistent with the coin-flip pattern the lineage has now replicated six times.

**S3 — the undated tail is stable at about a quarter, and it now holds the cycle's two largest unrankable moves.** **15 of 66** passed items (23%) carry `qualifying_event_date = 'UNRESOLVED'`, against 16 of 65 last cycle. More pointedly, **9 of the 34 floor-clearers (26%)** cannot anchor an identity. They include **IOVA +31.48%**, larger than every ranked move but KOD and LQDA, and TWST +16.11%. This is D1's anchor convention working as designed: an explicit `UNRESOLVED` rather than the measurement session silently treated as the event date. It is also the largest single leak between "B-sized move on an identified event" and "rankable identity". The open notices `03b8f773` (no written D1 anchor rule) and `06c3b0db` (anchor vs reaction clock conflated) are where that leak is owned. Neither is re-filed.

**S4 — two "beat and sold" cases, the shape B's information-versus-sentiment test exists for.** JBL fell −10.03% on a beat-and-raise, and AIR fell −7.25% on a beat paired with a levered acquisition. Index mode skips the per-candidate read, so this records only that the shape is present. Whichever thesis D2 builds after a drain must still clear criterion 4's objection that the market may be pricing the acquisition, not the beat.

**S5 — two names whose instrument-rail clearance is not settled by the screen record.** **KOD** cleared the $2B rail at the event close ($5.63B) but was about $2.0–2.3B before the move (D2's own note), so the move itself created part of the clearance. B's rule tests cap **at entry**, so KOD is eligible today, but a thesis must state the cap it relies on. **LQDA** is at $2.69B after a −57% day. That is just above §19's $1.5–2.5B band; a further ~7% fall puts it in the band and ~26% below the floor. Both are D2's to settle at thesis construction, and W2 spends no metered call on either.

**S6 — the ADR question binds nothing this cycle.** No ranked or below-cap name is a foreign-primary ADR. ACN (Irish plc) and CCL (Panama-incorporated) both have their primary listings on the NYSE as ordinary shares. `74c52a54` stays open, carried rather than re-filed. Last cycle's binding case, NVO, expired ungraded on 2026-10-02 before the question could matter.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-02 — held pending div-B-202609-1).**

The ranked list is the 15-item table in PART 1, plus the 7 eligible identities below the cap. Index mode records the seven mandated fields per item: ticker, `qualifying_event_date`, event-day move, window close, originating D1 id, one-line event and rank. It skips the four per-candidate research steps. The cohort work is not skipped: its measurement half is a named GAP, and its structural half and the grading-outcome series are in full.

## ROUTING — and why this week's W4 write is the one that decides whether a 10-06 flip can do anything

Route the ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. The below-cap seven are at W4's discretion (see PART 1). **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.**

**The mechanism, MEASURED from the plan text rather than assumed.** AR_orc Step 4 carries **B WATCH-OVERFLOW DRAIN ON BIND** (added 2026-09-14). If the divergence-review activation state AR_orc writes for B is ACTIVATE, it runs the identical M4 §A drain in the same run. It selects only overflow rows that carry the marker and whose window is still open on the bind date (boundary EXCLUSIVE), enqueues them with `due_date` = the first trading day after the bind, and stamps them "drained". On a 2026-10-06 bind that `due_date` is **2026-10-07**.

- **All 22 new identities qualify on the window test.** PPLI and ZS (close 10-07) would get exactly one session, the `due_date` itself; VIAV, TWLO and DELL two; the 09-28 cohort three; CCL and RCL four; the 09-30 cohort five; ACN six.
- **From W39, only SECZ qualifies.** Last cycle's other 15 are dead on or before 10-06.
- **D2's "Strategy B new-entry candidates (state index)" section — where all 22 already sit — has no drain consumer.** A name D2 indexed is not thereby drainable. **If W4 does not write these rows into the overflow section with the exact marker tonight, a 10-06 ACTIVATE bind drains nothing from this cohort**, because AR_att runs 10-05 and AR_orc 10-06, and no W4 run falls between tonight and then.

**How likely is the bind? Reachable, not likely, and less unlikely than last week.**

- **Against:** both prior B divergence reviews, `div-B-202607-1` (resolved 2026-08-05) and `div-B-202608-1` (resolved 2026-09-03), bound DO-NOT-ACTIVATE. The `acute` shock override that bound them still holds on its price leg, and the review's conservative default retains the prior state.
- **For:** M4 reports the raw fundamental call as ACTIVATE on a **stronger** basis than last month, and the technical leg is ACTIVATE.
- **The one number, unchanged in identity, moved in the right direction.** The Rev 48 `acute → latent` downgrade and the re-risking limb's leg B share a trigger: Brent ≤ **96.74** (baseline 84.73, peak 108.75). `state.rerisking_limb_status` reads Brent **102.31** as of 2026-10-01, down from 106.60 a week ago. The required fall narrowed from **−9.25% to −5.44%**.
- **The out-of-cycle path is unchanged at 1 of 3 legs.** `leg_a_dwell` TRUE (41 dwell days), `leg_b_price_leg` FALSE (`not_retraced`), `leg_c_technical` FALSE on `equity_breadth` WEAK alone (VIX NORMAL, SPY UP). `sql_limbs_fired` FALSE.

**So the synthesis is narrower than last week's, and sharper.** Last week the scheduled path became reachable for the first time and then did not flip. This week the reachable path is a single adjudication two days out, it covers the whole new cohort, and its usefulness depends on one W4 write tonight. The router outcome is AR_orc's to decide. The routing is the only part of the chain that is not.

---

## FINDINGS — one queue item, one alert resolved, nothing new filed upstream

**`events.queue_events` (`PENDING_ANALYSIS`, drained by D2):**

1. **`rescreen-COST-B-20261004`** — the RECORDED-FIGURE ARITHMETIC CHECK's one catch: COST 2.9311 vs 2.9315 on its own pair, derived-field slip, supersede target `b15a5838` (current effective record). No routing consequence. Low priority.

**`ops.alerts` resolved:**

2. **`62775339`** (`d1_below_spec_floor_contradicts_own_anchor_prose`, warning, raised by W2 2026-W39) — **fix verified**. Commit `2142752` put the close-chain test into §19 and D1 item 3, D1 rows since 09-28 carry `close_chain_check` with `ran: true`, and the IONQ instance is corrected.

**Carried, not re-filed:**

- `3218eb3c` (cohort trajectory unreachable; W2's own) — still true, re-measured this run.
- `3897ecc6` (two-price mandate date label) — corrected in W2's own section on 2026-09-27, **but still unqualified at its two other sites**: Operating_Protocols.md §19's field-contract line ("added 2026-09-20") and D1's FIELDS-JSON KEY CONTRACT. It now binds nothing, since every intake row this cycle carries the pair. The prose fix remains W5's.
- `03b8f773` and `06c3b0db` (D1 anchor rule and anchor-vs-reaction clock) — see S3.
- `08582955` (`b_intake_population_coverage_unquantified`, W2's own) — unmeasurable from W2's side under the no-pull boundary.
- `74c52a54` (ADR line) — binds nothing this cycle, see S6.
- `82de3746` (`routine_run_warning` on W2's 2026-09-27 completion) — its substance is the trajectory gap, which still holds. Left for its owner, not cleared here.

---

## HONEST LIMITS OF THIS RUN

- **The trajectory panel gains nothing for the second cycle running**, so every claim about post-event persistence rests on data ending 2026-09-18.
- **Five ranked or below-cap figures were never broker-verified** (ZS, PPLI, VIAV, TWLO, DELL). They are arithmetic-checked only, and DELL's 13-bp margin is exactly the size a two-cent error could erase.
- **The likelihood statements about the 10-06 bind are reasoned, not measured.** W2 reads the router state, the limb view and M4's rationale, and does not see the divergence-review artifact's argument. AR_att's blinding forbids pre-empting it, and nothing here should be read as a forecast of AR_orc's verdict.
- **Nothing here re-tests D1's significance verdicts.** That includes the two sector-beta names W2 ranks (GFI, CRDO) and the analyst-action name (TWLO), none of which W2 would have surfaced itself. The same tension W39 recorded as S2 applies, and it is still not W2's to resolve.
- **W2 has no price-layer completeness backstop.** This file can say nothing about what D1's bounded scan did not surface. D1's own `selection_rule` text calls each `surfaced_count` "a floor".

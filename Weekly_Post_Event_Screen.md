2026-W42

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-10-18 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W42
**Intake watermark:** 2026-10-11T08:27:41Z (this routine's own prior completion, `ops.run_log` `ea5ab54a`) · **Catch-up window:** 7.0 days, the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `3af8c71e-823f-43d6-947f-04704e90f836` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · zero new `ops.alerts` rows.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).** This is the eighth consecutive index-mode cycle.

**What decides this cycle: the out-of-cycle flip path has advanced for the first time, and it is now one leg from firing.** In `state.rerisking_limb_status` (as of 2026-10-18), the technical leg C has turned **TRUE**: equity breadth is HEALTHY, VIX is NORMAL and SPY is UP, all as of 10-15. Last week it read FALSE on breadth WEAK. Leg A (dwell) is still TRUE. The only leg left is the Brent price leg B, and Brent has moved *away* from its trigger for the second week running. Every window in this cohort closes on or before 2026-10-28, before the 2026-11-02 scheduled router write, so the limb is the cohort's only route.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It pulled no broad bars, enumerated no movers, repeated no event search, and did not re-judge D1's §19 significance verdicts. **It pulled no price bars of any kind**, and `scripts/check_routine_scope.py` enforces that boundary. The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

The run made **zero metered external calls**: no Anthropic `web_search`/`web_fetch`, no Tavily, no FMP, no HF and no IBKR. Index mode skips per-candidate enrichment, and the two data-assembly sub-agents were confined to BigQuery reads and repo reads.

**The 2026-10-16 (Friday) session is deliberately uncovered.** D1 runs Sunday to Thursday, and its last screen covers 10-15. D1's Sunday scan tonight owns 10-16, and PART 1 forbids W2 from covering that gap. **The 10-09 (Friday) session that W41 left uncovered is in this intake** (D1 `bba9dd7a`, written 10-11 22:11Z, after W41's watermark).

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`, reads **`DO-NOT-ACTIVATE`**:
- as_of 2026-10-06;
- `divergence_id` `div-B-202609-1`, theater check MIXED;
- source `events.adversarial_reviews:7db26d06`, event `e503c2d3`.

This row is unchanged since W41. **B's capital:** `state.strategy_capital_enablement` for B reads `capital_disabled = TRUE`.

**Flip paths that could reach this cohort before its windows close (latest 2026-10-28):**
- **Scheduled path: none.** M1a, M1b and M4 next fire 2026-11-02 (`ops/cadence.yaml`, first trading day; 11-01 is a Sunday).
- **Out-of-cycle path (D2a re-risking limb → M1R → D2): now 2 of 3 legs, up from 1 of 3.**

| Leg | W41 (2026-10-11) | W42 (2026-10-18) |
|---|---|---|
| A, dwell | TRUE (46 days) | TRUE (**51** trading days, DNA run since 2026-08-05) |
| B, Brent price | FALSE: 104.28 (10-08) vs 96.74 trigger, needs −7.23% | FALSE: **105.92** (10-15) vs 96.74 trigger, needs **−8.67%** |
| C, technical | FALSE (breadth WEAK) | **TRUE** (breadth HEALTHY, VIX NORMAL, SPY UP, as of 10-15) |
| `sql_limbs_fired` | FALSE | FALSE |

- **The limb now waits on one price.** The shock overlay is still `acute`, run start 2026-08-01, with `leg_b_basis = not_retraced` and a peak of 108.75.
- **On M1a's alternative midpoint the gap is smaller.** M1a uses 97.975 (alert `143c2aaf`, still open with W5), so Brent needs **−7.50%** on that reading. The two readings disagree for any Brent close between 96.74 and 97.975. A first leg-B pass is the moment that disagreement becomes live.
- **The read is "reachable, not likely."** A Brent fall of ~8.7% inside ~7 sessions, followed by the D2a → M1R → D2 → AR_orc chain completing before the 10-28 close, is possible but improbable. This is the first cycle since index mode began in which only one leg stands between the cohort and a re-score.

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE, adopted when W5 resolved `e3263203` on 2026-09-28. The qualifying event day is trading session 1, and the window closes on the 10th trading session inclusive.

Trading days were verified against `state.market_calendar`. 2026-10-12 is a trading day, and no NYSE holiday falls between 10-08 and 11-10. All six qualifying dates in this cohort are sessions, so session 1 = the qualifying date.

| Qualifying event date | Window closes | Sessions remaining from 2026-10-19, inclusive | Reachable by the 2026-11-02 scheduled write? |
|---|---|---|---|
| 2026-10-08 | 2026-10-21 | 3 | No |
| 2026-10-09 | 2026-10-22 | 4 | No |
| 2026-10-12 | 2026-10-23 | 5 | No |
| 2026-10-13 | 2026-10-26 | 6 | No |
| 2026-10-14 | 2026-10-27 | 7 | No |
| 2026-10-15 | 2026-10-28 | 8 | No |

The measured magnitude is the eligibility session's close-to-close move:
- An after-close release makes the NEXT session the eligibility session.
- An intraday or pre-open release makes THAT session the eligibility session.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five `single-name-move` rows have landed since the watermark, carrying 36 passed items in total:

| Decision id | Session screened | Passed items | Two prices recorded? | Note |
|---|---|---|---|---|
| `bba9dd7a-763e-4786-9d4f-ee70b80b4692` | 2026-10-09 (Fri) | 10 | 10 of 10 | 8 of 10 anchor on after-close 10-08 releases and are measured on the 10-09 reaction session; D1 recorded `anchor_session_move_pct` for each. D1's own close-chain check: 0 hits. |
| `394b6b39-44a8-46e4-b7fb-0542d058ccd2` | 2026-10-12 (Mon) | 3 | 3 of 3 | Correction row for stub `f5a0c793`, whose `fields` parsed to NULL. `394b6b39.superseded_by = f5a0c793`, which is the correct convention: the correction names the obsolete row (`bigquery/144`). The superseding row is the record used here. |
| `c4156ada-f578-4595-84ce-881cfc777b1f` | 2026-10-13 (Tue) | 6 | 6 of 6 | EFXT passed but was "NOT routed" under Rev 49. FRMI was indexed with a cap caveat. D1's close-chain check: 0 hits. |
| `c75cac94-6362-4cb3-923c-2f92811f86c2` | 2026-10-14 (Wed) | 8 | 8 of 8 | CRWV passed with anchor UNRESOLVED and was not indexed. LQDA carries a magnitude-clock caveat. D1's close-chain check: 0 hits. |
| `3e90f4a0-d40c-4cc9-b8f2-60dc787f3bc8` | 2026-10-15 (Thu) | 9 | 9 of 9 | D1's own close-chain check reported 2 hits (DELL, HPE). Both are day-2 carried-forward items that D1 did not re-write as passed, so neither is intake (see below). |

- **Not intake:** five `sector-move` rows in the window (`c69c1a3d`, `982a5f26`, `3159fd07`, `ab91c8e7`, `2caefda0`).
- **No B-relevant D1 candidate or action records since the watermark.** The only strategy-B decision row in the window is the 2026-10-13 `owner-directive` for Rev 49 (instrument eligibility, below).
- **No D1 or D2 correction of any single-name figure** since the watermark.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

- **Queue rows:** `events.queue_events` holds **zero** `thesis-construction` + strategy B rows since 2026-09-01, open or terminal.
- **Rescreen items:** no `rescreen-*` item touches an intake ticker at these qualifying dates. `rescreen-IONQ-B-20260927` is the 2026-09-23 IONQ anchor, a distinct event.
- **Earlier B decisions are all distinct events** and exclude nothing: MRNA (06-05, 07-12 NO-GO), NTAP, HPE, DELL, INTU (all 06-05), VZ (07-27 NO-GO), C (07-21 NO-GO), and the IONQ re-screen of 09-27.
- **The two IONQ items are distinct identities:**
  - 10-12, the all-stock Elisity acquisition;
  - 10-14, the $2.0B registered direct.

  Deduping by ticker alone would have wrongly dropped one.

## RECORDED-FIGURE ARITHMETIC CHECK — 36 of 36 passed items, zero mismatches

Every passed item carries both `prior_close` and `event_close`. Each `metric_pct` equals `(event_close/prior_close − 1) × 100` to the recorded 4-dp precision. The largest residual is 5×10⁻⁵ pp (DELL, AMAT, LQDA), which is rounding. **No `rescreen-*` item is owed.**

## CROSS-ROW CLOSE-CHAIN CHECK — 0 hits

- **Corpus:** every `single-name-move` item in the durable record, all-time, including superseded and stub rows: 1,562 items, 498 of them carrying both closes.
- **Test:** for each of the 35 intake items with a dated `qualifying_event_date`, look for another item with the same name and the same date whose `event_close` equals this item's `prior_close`, or whose `prior_close` equals its `event_close`. **No pair chains.**
- **D1's two self-reported hits do not touch the intake.** DELL and HPE on `3e90f4a0` are session-late day-2 items that D1 carried forward and did not pass. Their passed 10-14 items rest on pre-open Barclays notes and are measured on the anchor session itself.
- **CRWV is a cross-anchor continuation, not a chain hit.** The 10-15 item's `prior_close` 65.78 equals the 10-14 CRWV item's `event_close`, but the 10-14 item's date is UNRESOLVED, so the two are not a same-date pair. D1 disclosed it.
- **A clean pass is not a clearance.** The test reaches only items that share a name and date with another item; it measured 32% coverage on 2026-09-27.

## MEASUREMENT OF RECORD — D2's re-measurement, not W2's pull

`Watchlist.md`'s Strategy B new-entry index has D2 rows for 34 of the 36 items. The two without are EFXT and the 10-14 CRWV item.

- **Re-measured, 18 identities (the 10-09, 10-12 and 10-13 sessions).** D2 re-measured each against IBKR RTH closes and reproduced D1 **exactly**, including both CCC figures. So no D2 figure differs from D1 anywhere in the intake, and the D2-REMEASURED FIGURE PRECEDENCE rule changes no rank this cycle.
- **Not re-measured, 16 identities (the 10-14 and 10-15 sessions).** Their index rows say "Figures are D1's, not re-measured on IBKR in this pass". W41's weak spot repeats here: **six of the ranked 15 are arithmetic-checked only**, namely BSP, LQDA, MAN, DELL, QNT and ARQT.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor on the eligibility-session figure — 15 of 34, at the cap

Ranking is by **absolute eligibility-session close-to-close move, descending, and nothing else**. Every figure is D1's, which D2 reproduced where it re-measured (see above).

| # | Tier | Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | top-5 | BSP | 2026-10-14 | +41.2044% | 10-14 | 2026-10-27 | 7 | `c75cac94` | Berkshire Hathaway bought 10M shares at $33 (~4% stake, a 13% discount) per a 10-14 6-K. Nasdaq ordinary shares of an Italian S.p.A.; Rev 49-eligible. |
| 2 | top-5 | LQDA | 2026-10-13 | +26.5946% | **10-14** | 2026-10-26 | 6 | `c75cac94` | Settled six United Therapeutics suits for a net $380.7M and keeps Yutrepia; after-close 10-13 release. |
| 3 | top-5 | FSLY | 2026-10-09 | +15.8561% | 10-09 | 2026-10-22 | 4 | `bba9dd7a` | Oppenheimer upgrade to Outperform ($35 PT), pre-open; analyst action only. |
| 4 | top-5 | MAN | 2026-10-15 | −15.8199% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Staffing bellwether guided Q4 soft, pre-open. |
| 5 | top-5 | CCI | 2026-10-08 | +15.6046% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | SpaceX bought Grain's 800 MHz spectrum (after-close 10-08); the tower REIT re-rated up. |
| 6 | rest | FRMI | 2026-10-13 | +14.4615% | 10-13 | 2026-10-26 | 6 | `c4156ada` | AMD credit-support agreement for Project Matador, pre-open. |
| 7 | rest | MRNA | 2026-10-09 | +14.2132% | 10-09 | 2026-10-22 | 4 | `bba9dd7a` | NYT report of a national NIH/NCI cancer-vaccine initiative; a policy report, with no company contract. |
| 8 | rest | TMUS | 2026-10-08 | −13.2683% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Same SpaceX/Grain event: a direct-to-device low-band competitor to the carriers. |
| 9 | rest | CIFR | 2026-10-13 | −12.7692% | 10-13 | 2026-10-26 | 6 | `c4156ada` | $850M 0% convertible plus a note-for-share exchange; dilutive financing. |
| 10 | rest | HUM | 2026-10-08 | +11.5597% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | CMS 2027 Medicare Advantage Star Ratings (~95% of members in 4+ star plans); FY26 EPS reaffirmed. |
| 11 | rest | DELL | 2026-10-14 | −11.2740% | 10-14 | 2026-10-27 | 7 | `c75cac94` | Barclays cut to Equal Weight (PT 574 from 603), pre-open; a sector component. |
| 12 | rest | QNT | 2026-10-15 | +11.0506% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Upgrade-driven rebound after −10.15% on 10-14; quantum peers rebounded too. |
| 13 | rest | T | 2026-10-08 | −10.8162% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Same SpaceX/Grain event. D1 notes a likely, unverified 10-09 ex-dividend, net ~−9.81%. |
| 14 | rest | ASTS | 2026-10-08 | −10.4778% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Lost the Grain spectrum it had pursued to SpaceX; already −6.13% on 10-08. |
| 15 | rest | ARQT | 2026-10-15 | +10.1855% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Coverage initiation; a low-information event. |

### BELOW THE CAP — 19 eligible identities

| Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| VZ | 2026-10-08 | −10.1402% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Same SpaceX/Grain event; a likely ex-dividend 10-09, net ~−8.75%. |
| IONQ | 2026-10-14 | −9.5307% | 10-14 | 2026-10-27 | 7 | `c75cac94` | $2.0B registered direct to Heights Capital at $40 with 100M 7-yr warrants. |
| AMT | 2026-10-08 | +9.3025% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Same SpaceX/Grain event; tower REIT. |
| IONQ | 2026-10-12 | −9.0750% | 10-12 | 2026-10-23 | 5 | `394b6b39` | All-stock acquisition of Elisity (up to $1.3B incl. earnout); ~10% dilution. |
| PAG | 2026-10-15 | +8.8352% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Cash take-private at $212; **deal-pinned target**. |
| MMED | 2026-10-14 | −8.6413% | 10-14 | 2026-10-27 | 7 | `c75cac94` | Medtronic completed its exit via exchange offer; full float to the public. |
| HPE | 2026-10-14 | −8.2837% | 10-14 | 2026-10-27 | 7 | `c75cac94` | The same Barclays note as DELL (PT 77 from 83). |
| CCC | 2026-10-09 | +8.1197% | **10-12** | 2026-10-22 | 4 | `394b6b39` | Bloomberg: GTCR and Elliott in advanced take-private talks (after-close 10-09); no terms. |
| SBAC | 2026-10-08 | +7.3407% | **10-09** | 2026-10-21 | 3 | `bba9dd7a` | Same SpaceX/Grain event; tower REIT. |
| NTAP | 2026-10-14 | −7.0332% | 10-14 | 2026-10-27 | 7 | `c75cac94` | The same Barclays note as DELL and HPE. |
| AMAT | 2026-10-13 | −6.6911% | 10-13 | 2026-10-26 | 6 | `c4156ada` | Investor Day declined a WFE forecast on a semicap-selloff day. |
| RKLB | 2026-10-14 | −6.6408% | **10-15** | 2026-10-27 | 7 | `3e90f4a0` | Program-schedule slip (~16:58 ET 10-14); the −7.85% anchor-session move predates the release. |
| INTU | 2026-10-15 | +6.3555% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Own event on a software-rotation day. |
| MANH | 2026-10-12 | +6.3449% | 10-12 | 2026-10-23 | 5 | `394b6b39` | Morgan Stanley upgrade to Overweight; analyst action only. |
| CROX | 2026-10-15 | +6.1511% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Sell-side upgrade on a consumer-discretionary rally. |
| NOW | 2026-10-15 | +6.1366% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Denial of a dilutive-M&A overhang, intraday, on the software rotation. |
| CRWV | 2026-10-15 | +5.9441% | 10-15 | 2026-10-28 | 8 | `3e90f4a0` | Intraday reversal after a supplier/investor statement; distinct from the undated 10-14 item. |
| JNJ | 2026-10-13 | −5.7331% | 10-13 | 2026-10-26 | 6 | `c4156ada` | Q3 beat and guide raised, but MedTech sales missed. |
| C | 2026-10-13 | −5.6019% | 10-13 | 2026-10-26 | 6 | `c4156ada` | Q3 EPS beat, but weaker markets revenue and outlook. |

**The cap decides nothing W2 owns this cycle.** Ranked and below-cap identities share one fate unless the limb fires. W4 decides under §C whether to carry the 19 below-cap names into the overflow block.

### Not rankable — 2 passed items

- **EFXT** (10-13, +14.3688%, `c4156ada`): **ineligible under Rev 49.** It is TSX-primary with an NYSE secondary listing, ADR-class, and D1 recorded a $3.36B cap, under the $10B line. D1 applied Rev 49 itself and did not route it. W2 concurs and does not overrule.
- **CRWV 10-14** (−15.4607%, `c75cac94`): `qualifying_event_date = 'UNRESOLVED'`. It came from debt repricing with no issuer release. **W2 does not date it**, because assigning an anchor would be the second dating screen PART 1 forbids. This is the cohort's only undated floor-clearer: 1 of 36, against 1 of 24 in W41.

### Context only — below the floor or not an identity

The 10-09 row also lists rejected ≥5% movers (PLTR, JOBY, ACHR, all analyst-action-only and rejected on significance), plus undated `rejected_notable` items. W2 does not re-judge them.

### Identities EXCLUDED before enrichment — 0

None were excluded on dedupe, expired window or criterion 5.

## Rev 49 — Strategy B instrument eligibility changed mid-cycle (owner directive, 2026-10-13)

`strategy/04_strategy_b.md` now reads:
- US-primary-listed common or ordinary shares are eligible **regardless of place of incorporation**.
- ADRs/ADSs of foreign-domiciled issuers are eligible only at **market cap ≥ $10B** at entry.
- The ADV and cap floors apply to every instrument.

Alert `74c52a54` (`b_instrument_eligibility_adr_silence_unwritten`) was resolved on 10-13 by this directive. That settles the incorporation-versus-listing-form disagreement W41 recorded.

- **This intake:** D1 applied Rev 49 correctly on every row written after it. EFXT was not routed, and BSP (Italian S.p.A., Nasdaq ordinary shares, $35.8B) was indexed. The only row still using the old "foreign-incorporated, held" language is `bba9dd7a` (written 10-11, two days before Rev 49), on BNTX, which was rejected for an unresolved anchor anyway. Nothing changes.
- **W41's three instrument-held names, for W4:**
  - **BULL** (10-07, −19.0934%, window closes 10-20): eligible under Rev 49 as Nasdaq-primary ordinary shares.
  - **SPOT** (10-07, +5.0786%, window closes 10-20): eligible under Rev 49 as NYSE-primary ordinary shares.
  - **ARGX** (10-08, −11.8274%, window closes 10-21): an ADS on a Euronext primary listing, so it is eligible only at a cap ≥ $10B. W2 read no cap figure for it and does not assert one.

  These are pre-watermark identities, so W2 does not re-rank them. Their windows are still alive, but the same router gate blocks them. W4 may add them to the overflow block under the same `Router-gated, not rank-gated.` marker.

## Criterion 5 binds nothing this cycle

`state.current_positions` holds 8 tickers, all Strategy D: AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM and UBER. There are **zero A positions and zero B positions**, and no intake ticker is held.

---

## POST-EVENT TRAJECTORY — still a GAP, named as one, and not improvised

The INDEX MODE bullet's 2026-09-27 pin governs. **No post-event cohort mark layer exists; this was re-measured this run.**
- `events.daily_marks` since 10-08 holds 11 tickers.
- `events.signal_marks` since 10-08 holds 14 tickers.
- **Zero of the 34 intake tickers appear in either table.**
- So: no substitute series, no missing observation read as a zero, and no reassignment on W2's authority. Alert `3218eb3c` (`b_cohort_trajectory_unreachable_under_no_pull_boundary`) stays open with W5.

**The within-name residual panel gains nothing, for the fourth cycle running.**
- It still ends 2026-09-18. W39's FINDINGS 1–5 stand as published, including the ~two-week re-randomisation estimate (ρ = +0.273), which remains one measurement.
- The 2026-09-18 values for cohorts 1–3 were published only as aggregates, so they cannot be extended within-name.
- The gap is now four cohorts deep (W39 through W42), and none of the four can be reconstructed later.

**Repeat-name panel (re-appearance, not persistence), reconstructed from the published W29–W41 files.**
- Fifteen tickers had appeared in two or more ranked or below-cap cycles before this one, every time on a distinct event.
- **This cycle adds six re-appearances, all on new, distinct events:**

| Ticker | Earlier published appearances (cycle: rank, event date, move) | W42 appearance |
|---|---|---|
| DELL | W36: 7, 09-01, +15.8118% · W38: 11, 09-10, +11.9776% · W40: below-cap, 09-25, +5.0129% | rank 11, 10-14, −11.2740% (4th appearance) |
| HPE | W36: below-cap, 09-02, +5.0357% · W38: 10, 09-10, +12.4411% | below-cap, 10-14, −8.2837% (3rd) |
| MRNA | W34: 6, 08-19, +177.03% · W38: 14, 09-17, +8.5495% | rank 7, 10-09, +14.2132% (3rd) |
| LQDA | W40: 2, 09-30, −57.1934% | rank 2, 10-13, +26.5946% (2nd) |
| FSLY | W39: 6, 09-21, +14.9204% | rank 3, 10-09, +15.8561% (2nd) |
| AMAT | W34a (08-17): 6, 08-14, −5.12% | below-cap, 10-13, −6.6911% (2nd) |

- **The repeat panel grows from 15 to 18 tickers** (LQDA, FSLY and AMAT join). DELL's and HPE's 10-14 appearances share one driver with each other for the second time: the 09-10 pair was also a joint event.
- **No ticker has ever been ranked twice on the same event.** A cross-cycle rank-persistence statistic is therefore undefined on this panel. Rank persistence is measurable only on the residual series, which is the series the gap has frozen.
- **LQDA's two events are the same litigation with opposite signs.** −57% on 09-30, against UTHR, and +27% on the 10-13 settlement with UTHR. That is a distinct second event inside one dispute, not persistence. It is the panel's clearest case of a name re-entering because its event stream is dense.

### What W2 CAN add from its own durable record: the GRADING OUTCOME series, itemized per ticker

**W41 cohort (20 identities), graded against the router state (DO-NOT-ACTIVATE throughout, no drain):**

| Ticker | Qualifying event | Window closes | Outcome |
|---|---|---|---|
| SYNA, ON, STX, WDC | 2026-10-01 | 2026-10-14 | **Expired ungraded.** |
| PTC, PCVX, RXO, SPHR, CHRW, INSM, HOG, DKNG | 2026-10-05 | 2026-10-16 | Expired ungraded. |
| MELI | 2026-10-04 | 2026-10-16 | Expired ungraded. |
| OPCH, CEG, MRVL | 2026-10-06 | 2026-10-19 | **Will expire ungraded** unless the limb fires on 10-19, which it cannot (leg B FALSE as of 10-15). |
| PENG | 2026-10-06 (reaction 10-07) | 2026-10-19 | Will expire ungraded, same reason. |
| HESM | 2026-10-07 | 2026-10-20 | Will expire ungraded unless Brent falls ~8.7% by the next D2a evaluation; improbable. |
| HAE, CMG | 2026-10-08 | 2026-10-21 | Same as HESM. |

**W40 cohort:** all 22 windows are now closed. The last, ACN, closed 10-14, and every one expired ungraded.

**Lineage tally:**
- Eight consecutive index-mode cycles.
- **No published B identity has ever been evaluated against B's entry criteria.** There are zero B thesis-construction queue rows since 2026-09-01, and no B thesis or NO-GO decision on any W40/W41 identity.
- **The W42 cohort is the first whose route to a re-score stands on a single leg.** That is a change in reachability, not a grade of B.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, and unaffected by the gap

**S1 — 34 identities, 26 independent events. Event-sharing is the heaviest this lineage has recorded.**
- **One third-party transaction produced seven identities.** SpaceX's purchase of Grain's 800 MHz spectrum moved TMUS, T and VZ (carriers, down), CCI, AMT and SBAC (towers, up) and ASTS (the losing bidder, down). The signs split by business model: towers gain from a new tenant, carriers lose to a new direct-to-device competitor.
- **One Barclays note produced three:** DELL, HPE and NTAP.
- **IONQ's two items are distinct events** (an acquisition, then a financing) and count twice.
- **Within the ranked 15, the cluster holds four slots** (CCI #5, TMUS #8, T #13, ASTS #14), so the ranked 15 hold **12 independent events**.
- **Why this matters:** B's concurrent-position correlation constraint (Section 6 / KL #12) would bind on this cohort if it were ever routable. Four of fifteen slots move on one causal driver.

**S2 — the deal-pinned share collapsed from 4 of W41's top seven to 0 of W42's ranked 15.**
- PAG, a cash take-private at $212, is the only pinned target in the intake, and it sits below the cap.
- CCC is a take-private *report* with no terms, so it is not pinned.
- BSP is a strategic minority purchase at a discount, not a tender, so it is not pinned either.
- The W41 S2 concern was that absolute-move ranking mechanically promotes takeover premia. **It was a property of that cohort's composition, not a stable feature of the rule.** That is one more observation, still unfiled: the taxonomy question stays with SL/W5.

**S3 — event-type composition of the ranked 15.**

| Event type | Count | Names |
|---|---|---|
| Analyst action / coverage | 4 | FSLY, DELL, QNT, ARQT |
| Competitive read-across from a third-party transaction | 4 | CCI, TMUS, T, ASTS |
| Financing / capital structure | 3 | BSP, FRMI, CIFR |
| Regulatory / policy | 2 | HUM, MRNA |
| Litigation | 1 | LQDA |
| Earnings / guidance | 1 | MAN |

- **Direction is 9 up / 6 down**, identical to W41. The coin-flip pattern holds for the eighth time.
- **Analyst-action-only events take 4 of 15 ranked slots**, up from 1 of 15 in W41, plus MANH and CROX below the cap. Whether a sell-side note carries the "information" half of criterion 4's information-versus-sentiment test is D2's per-candidate call. W2 records the share and does not re-judge D1's admission.
- **Earnings are nearly absent.** Only MAN is ranked, with JNJ and C below the cap, even though this is the first full week of Q3 reporting. Bank and pharma prints mostly moved less than 6%.

**S4 — anchor quality.**
- **Undated tail:** 1 of 36 passed items is UNRESOLVED (CRWV 10-14), against 1 of 24 last cycle.
- **Reaction-session measurement now shapes the ranking.**
  - Eleven of the 34 identities are after-close releases measured on the next session: TMUS, CCI, HUM, T, VZ, AMT, SBAC, CCC, LQDA, RKLB and ASTS.
  - Eight of them are below 5% on the anchor session: TMUS, CCI, HUM, T, VZ, AMT, SBAC and LQDA.
  - The convention is the spec's (after-close → next session). D1 recorded `anchor_session_move_pct` beside every one, which is the transparency notice `06c3b0db` asked for. Six of the ranked 15 depend on it.
- **Broker verification:** 18 of 34 identities are D2-reproduced exactly; 16 are D1-only, including six of the ranked 15.

**S5 — instrument-rail and measurement items for D2 at thesis construction, none W2's to settle.**
- **T and VZ:** D1 flags a likely but unverified 10-09 ex-dividend inside the close-to-close figure. The net moves (~−9.81% and ~−8.75%) still clear the floor. T's net figure would rank below ASTS, swapping ranks 13 and 14, and alters no tier. Settling the ex-date is D2's.
- **FRMI:** the $2.37B cap is not second-sourced (D1 caveat), within 30% of the $2B floor.
- **MAN:** the $2.03B post-drop cap is second-sourced but sits 1.5% above the $2B floor.
- **BSP:** a 6-K foreign private issuer. It is Rev 49-eligible, but D2 should confirm ADV on the new float.
- **QNT, IONQ and CRWV** moved with their sector peers. D1 flags QNT as "sector mean reversion".

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).**

The ranked list is the 15-item table in PART 1. It carries the tier field (e) on every row, set strictly by rank (1–5 `top-5`, 6–15 `rest`), plus `qualifying_event_date`, event-day move, window close, sessions left, originating D1 id and a one-line event. The 19 eligible identities below the cap follow it, marked `below-cap`.

Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, fields (a) and (c) read **"not assessed — INDEX MODE"** for every candidate. Fields (b), (d), (e), (f) and (g) are in the tables.

The cohort work is not skipped. Its measurement half is a named GAP, and its structural half and the grading-outcome series are given in full.

## ROUTING

Route the 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. **W4 §C's top tier is the five `top-5` rows: BSP, LQDA, FSLY, MAN and CCI.**

- The 19 below-cap names are at W4's discretion.
- So are W41's three Rev 49-eligible held names (BULL, SPOT, and ARGX subject to its cap test).
- **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.**

**The routing is no longer pure bookkeeping.** With leg C now TRUE, an out-of-cycle re-score inside these windows needs only the Brent leg. If it fires, the M1R → D2 → router-review chain could drain only rows that carry the marker.

---

## FINDINGS — zero alerts filed, zero queue items, nothing resolved by W2

**`ops.alerts`:** none filed.
- **The 10-12 stub/correction pointer is NOT a defect.** A data-assembly pass first read `394b6b39.superseded_by = f5a0c793` as an inverted pointer. Against `bigquery/144`'s contract (the correction row names the obsolete row it replaces; readers exclude the named row), it is correct, and the obsolete stub is the one excluded.
- **The limb's two-of-three state is a measurement, not a defect.**

**`events.queue_events`:** none. Both free checks were clean, and no thesis-construction enqueue is owed under index mode.

**Carried, not re-filed (open):**
- `143c2aaf` (`shock_baseline_window_divergent_between_m1a_and_limb_view`, W2's own, W5). It is **more relevant now**: leg B is the only open leg, so the 96.74 vs 97.975 band is exactly where a first pass would be decided.
- `3218eb3c` (cohort trajectory unreachable, W2's own): still true, re-measured this run.
- `3897ecc6` (two-price mandate date label): binds nothing, because every intake row carries the pair.
- `06c3b0db` (anchor-vs-reaction clock, D2's): D1 now records the anchor-session figure beside every reaction-session item, so no suppression instance arises this cycle. RKLB and LQDA are the flagged cases.

**Resolved since W41 by their owners (re-read live this run):**
- `74c52a54`, by owner directive Rev 49 on 10-13.
- `4880faf0`, `98323b28`, `dd5f30f9` and `08582955`, by W5 on 10-12.

The W2 section's D2-precedence and TIER PIN clauses are the resolutions of `4880faf0` and `98323b28`, and this file applies both.

---

## HONEST LIMITS OF THIS RUN

- **The trajectory panel gains nothing for the fourth cycle running.** Every claim about post-event persistence rests on data ending 2026-09-18.
- **Sixteen identities were never broker-verified, six of them ranked:** BSP, LQDA, MAN, DELL, QNT and ARQT. They are arithmetic-checked only.
- **The flip-path read rests on a view's as-of 10-15 inputs.** W2 pulled no Brent print and makes no forecast. "Reachable, not likely" is a statement about the arithmetic and the chain length, not a price view.
- **S1–S3 classify D1's one-line reasons.** They are not measurements, and the event-type buckets are W2's reading.
- **Nothing here re-tests D1's significance verdicts**, including the four analyst-action names W2 ranks.
- **W2 has no price-layer completeness backstop.** This file can say nothing about what D1's bounded scan did not surface.

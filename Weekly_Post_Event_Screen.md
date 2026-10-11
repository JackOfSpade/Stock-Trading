2026-W41

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-10-11 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W41
**Intake watermark:** 2026-10-04T08:18:12Z (this routine's own prior completion) · **Catch-up window:** 7.0 days, the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `343fdc8a-ad3c-4565-8534-5c7b11080f77` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · one `ops.alerts` info row `143c2aaf-0a41-4df1-8ee7-6025d85eb843` (`shock_baseline_window_divergent_between_m1a_and_limb_view`, see FINDINGS).

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).** Seventh consecutive index-mode cycle.

**The fact that decides this cycle: the review W40 pointed at has run, and it did not flip.** AR_orc resolved `div-B-202609-1` on 2026-10-06 as **DO-NOT-ACTIVATE, UNCHANGED**. The decision row is `1170c3bd`, the activation row `e503c2d3`, and the pending flag is now cleared. The watch-overflow drain therefore did not engage, and all 22 W40 identities will expire ungraded. This cycle's 20 new eligible identities have windows closing **2026-10-14 to 2026-10-21**. The next scheduled router write is M4 on **2026-11-02**, which is after every one of those windows. The only path that could reach them is M1R's out-of-cycle path, and that path moved further away this week.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**: no broad bar pulls, no mover enumeration, no repeated event search, and no re-judging of D1's §19 significance verdicts. **It pulled no price bars of any kind**. That boundary is unchanged, and `scripts/check_routine_scope.py` enforces it. The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion. W2's job on top of that record is B-specific eligibility, ranking and the cohort-level work.

**The 2026-10-09 (Friday) session is deliberately uncovered.** D1 runs Sunday to Thursday, and its last screen covers 10-08. D1's Sunday scan tonight owns 10-09, and PART 1 forbids W2 from covering that gap.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`, reads **`DO-NOT-ACTIVATE`** with `as_of_date` 2026-10-06, `divergence_id` `div-B-202609-1`, theater check MIXED, source `events.adversarial_reviews:7db26d06`. AR_orc's rationale says M1b's raw call was ACTIVATE but was overridden by `shock_overlay = acute`, validly applied, because Rev 48 leg (ii) fails. On the M1a basis that is 37.9% retraced at 100.58 on 10-06, against the 97.975 midpoint. The 09-30 reading of 49.7% was a single print inflated by the 09-29 contract roll. The fourth consecutive monthly cycle now ends in the same override.

**B's capital.** `state.strategy_capital_enablement` for B reads `capital_disabled = TRUE`. B is an adopted roster member that is deliberately not risking capital.

**Flip paths that could reach this cohort before 2026-10-21:**
- **Scheduled path: none.** M1a, M1b and M4 next fire 2026-11-02.
- **Out-of-cycle path (D2a re-risking limb → M1R → D2): still 1 of 3 legs.** In `state.rerisking_limb_status` as of 2026-10-11:
  - `leg_a_dwell` is TRUE (46 dwell days).
  - `leg_b_price_leg` is FALSE. Brent is **104.28** as of 10-08 against the view's 96.74 trigger, so it needs a **−7.23%** fall. Last week the gap was −5.44%, so Brent moved away.
  - `leg_c_technical` is FALSE on `equity_breadth` WEAK alone; VIX is NORMAL and SPY is UP.
  - `sql_limbs_fired` is FALSE.

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE, adopted when W5 resolved `e3263203` on 2026-09-28. The qualifying event day is trading session 1, and the window closes on the 10th trading session inclusive. When the event falls on a non-session day, the first session after it is session 1 (MELI, event Sunday 10-04).

Trading days were verified against `state.market_calendar`. No NYSE holiday falls between 2026-10-01 and 2026-11-06, and 2026-10-12 is a trading day. Every close date below matches the close D2 recorded when it indexed the name.

| Qualifying event date | Window closes | Sessions remaining from 2026-10-12, inclusive | Reachable by the 2026-11-02 scheduled write? |
|---|---|---|---|
| 2026-10-01 | 2026-10-14 | 3 | No |
| 2026-10-04 (Sun) / 2026-10-05 | 2026-10-16 | 5 | No |
| 2026-10-06 | 2026-10-19 | 6 | No |
| 2026-10-07 | 2026-10-20 | 7 | No |
| 2026-10-08 | 2026-10-21 | 8 | No |

The measured magnitude is the eligibility session's close-to-close move. An after-close release makes the NEXT session the eligibility session. An intraday or pre-open release makes THAT session the eligibility session.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Six `single-name-move` rows have landed since the watermark:

| Decision id | Session screened | Passed items | New floor-clearers, resolved anchor | Floor-clearers held or undated | Two prices recorded? | Note |
|---|---|---|---|---|---|---|
| `d5ee1347-5d75-42a0-b54f-4c9bfdfe8408` | 2026-10-02 | 7 | 4 (SYNA, ON, STX, WDC) | 1 undated (ECHO) | 7 of 7 | D1 Sunday scan |
| `ff2bf587-f8f2-4460-b9b6-192a956e15ae` | 2026-09-25 | 8 | — | — | 8 of 8 | **D2 correction** of `b15a5838`, which W2 consumed in W40. See below. |
| `0e8fe4c3-f20b-4533-a198-1ddc04918c2e` | 2026-10-05 | 12 | 9 | 0 | 12 of 12 | |
| `7ac0f2f6-85dd-4bf9-900d-716d60c7197e` | 2026-10-06 | 4 | 3 | 0 | 4 of 4 | |
| `e863504e-12b0-4d76-a146-94657fd9519f` | 2026-10-07 | 5 | 2 | 2 held (BULL, SPOT) | 5 of 5 | |
| `8e407ff8-9ad9-479c-b837-e9bcecbf055a` | 2026-10-08 | 4 | 2 | 1 held (ARGX) | 4 of 4 | |

**There are 39 passed items, and all 39 carry a two-price pair.** The 31 items from the five new-session rows yield 20 new eligible identities, 3 instrument-held floor-clearers and 1 undated floor-clearer.

**The correction row `ff2bf587` changes nothing for ranking.** D2 wrote it on 2026-10-04 while draining W40's `rescreen-COST-B-20261004`. Diffed field by field against `b15a5838`, the only change is COST `metric_pct` 2.9311 → 2.9314652865. The prices are unchanged and verified on IBKR contract 272997, and COST stays below the floor. The other seven passed items and the whole `rejected_notable` array are byte-identical. **`ff2bf587` is now the current effective record for the 2026-09-25 session**, and any later citation of `b15a5838` should read `ff2bf587`. That matters for W4's open notice `4880faf0` (`w2_intake_carries_superseded_d1_move_figures`): this file cites the superseding row. The W40 identities that came from that session (ZS, PPLI, VIAV, TWLO, DELL) all closed 10-07 or 10-08, so they are not re-ranked.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

`events.queue_events` holds **zero** `thesis-construction` / B rows since 2026-09-01, open or terminal, and `events.decision_log` holds **zero** B `thesis-construction` decisions in the same span. D2's own dedupe found PTC's prior B decision `d24b2bff`, a NO-GO on a distinct May 2026 event, so the 2026-10-05 identity remains eligible. ON appears in `B_Sub_Pattern_Taxonomy.md` on the 2026-06-26 all-stock announcement of the same SYNA deal, which is also a distinct event. **No intake identity is excluded by dedupe.**

## RECORDED-FIGURE ARITHMETIC CHECK — 39 of 39 passed items, zero mismatches

`metric_pct` was tested against `(event_close/prior_close − 1) × 100` on every passed item. The largest residual is 8.5e-05 pp (WDC). Every residual sits inside the envelope that 2-dp stored closes leave around a figure computed on the unrounded broker close. The corrected COST figure now reproduces exactly. **Nothing is filed.**

**Extended to `rejected_notable`, recorded and not filed:** four items exceed 1e-4 pp: COHR (+1.2e-4, `d5ee1347`), and BE (+1.8e-3), GWW and EQIX (−2.7e-4 / −1.2e-4) in the carried `ff2bf587` array. The largest is BE: 266.65 → 288.70 computes to 8.26927 against a recorded 8.2711. Backing out the recorded figure gives an implied prior close of 266.645, which is a half-cent rounding boundary. So the residual is consistent with rounding of the unrounded close, and unlike the COST case it is not visible as a defect on the row's face. More decisively, BE is a rejected, `UNRESOLVED`-anchor item whose window could only have closed by 10-08. A re-screen would spend a D2 broker pull to correct a field that routes nothing. The checks are mandated over the intake, and these rows are outside it.

## CROSS-ROW CLOSE-CHAIN CHECK — 0 hits

The corpus is every non-superseded `single-name-move` item since 2026-09-24: 11 rows, 257 items, 214 of which carry both closes. **Zero hits on a dated `qualifying_event_date`.**
- **Three sentinel-date matches.** AAOI, IREN and INTC chain only through the string `UNRESOLVED`, which is not a date. They are ordinary consecutive-session chains across different sessions, not an anchor defect.
- **D1's own `close_chain_check`.** Every new row carries one with `ran: true`, and `d5ee1347` reports one hit: ACN in `rejected_notable`. That is the 10-02 give-back of W40's rank-5 identity, correctly resolved by D1 as a carried-forward day-2 leg.

**A clean pass is not a clearance.** The test reaches only items that share a name and a date.

## MEASUREMENT OF RECORD — D2's re-measurement, not W2's pull

D2's QUALIFYING-MOVE RE-MEASUREMENT has run on **16 of the 20** new identities: every 10-05, 10-06, 10-07 and 10-08 name. D2 used IBKR RTH daily bars on the close array. **All 16 reproduce D1 exactly, and nothing was superseded.** The four 10-01 names (SYNA, ON, STX, WDC) were indexed by D2 on 2026-10-04 with no itemized re-measurement in its record. They are arithmetic-checked here only, and D2 owns their re-measurement at thesis construction.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor on the eligibility-session figure — 15 of 20, at the cap

Ranking is by **absolute eligibility-session close-to-close move, descending, and nothing else**.

| # | Tier | Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | top-5 | PTC | 2026-10-05 | +33.4861% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Schneider Electric definitive all-cash $205/sh, joint release pre-open; **deal-pinned target** (spread ~6.6%). |
| 2 | top-5 | OPCH | 2026-10-06 | +32.6487% | 10-06 | 2026-10-19 | 6 | `7ac0f2f6` | CD&R + McKesson definitive $32.05/sh cash, ~04:00 ET release; **deal-pinned target** (spread ~3.4%). |
| 3 | top-5 | PCVX | 2026-10-05 | +30.7011% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Positive pivotal Phase 3 OPUS-1 topline for VAX-31, pre-open; faded from +57% intraday. |
| 4 | top-5 | RXO | 2026-10-05 | +22.5406% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Target in C.H. Robinson's cash-plus-stock acquisition ($30.25 implied); **deal-pinned to part-stock consideration**. |
| 5 | top-5 | HAE | 2026-10-08 | +17.4614% | 10-08 | 2026-10-21 | 8 | `8e407ff8` | 8-K Item 7.01: CSL to move all US plasma centers to NexSys PCS by end-2027. |
| 6 | rest | HESM | 2026-10-07 | −14.6291% | 10-07 | 2026-10-20 | 7 | `e863504e` | Chevron/Hess Midstream restructuring: ~40% share cancellation, 2027 tariff cut, 2027 EBITDA guide well below 2026. |
| 7 | rest | SYNA | 2026-10-01 | +14.0838% | **10-02** | 2026-10-14 | 3 | `d5ee1347` | onsemi revised its takeover to all-cash $123/sh after a rival bid (16:34 ET 10-01); **deal-pinned target**. |
| 8 | rest | SPHR | 2026-10-05 | −13.6062% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Craig-Hallum downgrade to Hold on softer Wizard of Oz demand; analyst action only. |
| 9 | rest | PENG | 2026-10-06 | +13.0821% | **10-07** | 2026-10-19 | 6 | `e863504e` | FQ4 FY26 beat and FY27 outlook raised (~16:30 ET 10-06). |
| 10 | rest | CEG | 2026-10-06 | +12.2487% | 10-06 | 2026-10-19 | 6 | `7ac0f2f6` | Google 20-year 890 MW nuclear uprate PPA, pre-open. |
| 11 | rest | CHRW | 2026-10-05 | −10.8483% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Acquirer-side de-rating on the RXO deal (same release as rank 4). |
| 12 | rest | WDC | 2026-10-01 | −10.2193% | **10-02** | 2026-10-14 | 3 | `d5ee1347` | Toshiba HDD-capacity-doubling report (Nikkei stamp 17:59 ET 10-01); anchor rests on one page stamp. |
| 13 | rest | STX | 2026-10-01 | −10.2139% | **10-02** | 2026-10-14 | 3 | `d5ee1347` | The same Toshiba report as WDC, identical magnitude; same single-stamp anchor. |
| 14 | rest | MELI | 2026-10-04 | +9.6696% | **10-05** | 2026-10-16 | 5 | `0e8fe4c3` | Brazil first-round election result counted Sunday night; macro/political, not company-specific. |
| 15 | rest | INSM | 2026-10-05 | −6.5605% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | CFO departure effective 10-30, guidance reaffirmed. |

### BELOW THE CAP — 5 eligible identities

| Ticker | Qualifying event | Move | Eligibility session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| HOG | 2026-10-05 | +6.6802% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | Citi upgrade to Buy pre-market; analyst action only. |
| CMG | 2026-10-08 | +6.2073% | 10-08 | 2026-10-21 | 8 | `8e407ff8` | FT exclusive that Starbucks explored a Chipotle takeover; unconfirmed. |
| ON | 2026-10-01 | +6.0065% | **10-02** | 2026-10-14 | 3 | `d5ee1347` | The acquirer side of SYNA (rank 7): the switch to cash terms removes dilution, on a ~3% semis-up day. |
| MRVL | 2026-10-06 | +5.8101% | 10-06 | 2026-10-19 | 6 | `7ac0f2f6` | Investor Day raised its FY28 revenue outlook to ~$20B against ~$18.2B consensus; public intraday on the anchor session. |
| DKNG | 2026-10-05 | +5.4330% | 10-05 | 2026-10-16 | 5 | `0e8fe4c3` | BofA upgrade to Buy pre-open; partly retraces 09-29's −7.42%. |

**The cap decides nothing W2 owns this cycle.** No flip path reaches these windows (see the router gate), so the ranked and below-cap tiers have the same practical fate. W4 decides under §C whether to carry the five below-cap names into the overflow block, as it carried W40's seven.

### Floor-clearers held on the instrument rail — 3, held by D1 pending `74c52a54`, not ranked

| Ticker | Qualifying event | Move | Window closes | Listing form | D1 origin |
|---|---|---|---|---|---|
| BULL | 2026-10-07 | −19.0934% | 2026-10-20 | Cayman-incorporated **ordinary shares**, primary listing Nasdaq | `e863504e` |
| ARGX | 2026-10-08 | −11.8274% | 2026-10-21 | argenx SE (Netherlands) **ADS**, primary listing Euronext Brussels | `8e407ff8` |
| SPOT | 2026-10-07 | +5.0786% | 2026-10-20 | Luxembourg-incorporated **ordinary shares**, primary listing NYSE; clears the floor by 8 bp | `e863504e` |

**W2 does not overrule D1's hold, but records an inconsistency that bears on the adjudication.** D1 holds out BULL and SPOT on **place of incorporation**, as it did NU. W2's W40 reading (S6) instead treated **listing form** as the test: ACN (an Irish plc) and CCL (Panama-incorporated) were ranked because their primary listings are NYSE ordinary shares, and D1 itself indexed ACN. Under W40's reading, only ARGX, an ADS on a foreign primary listing, engages the ADR question, and BULL and SPOT are ordinary US-primary listings like ACN. Under D1's reading, ACN should have been held too. The two readings disagree on two of these three names this cycle. That is evidence for `74c52a54` (`b_instrument_eligibility_adr_silence_unwritten`, adjudication W5), which already names the surface, so W2 files nothing new. Because no flip path reaches any of these windows, the disagreement changes no outcome this cycle.

### Context only — below the frozen spec floor on the eligibility-session figure, never routable

- 2026-10-01 / 10-02: TSLA +4.6539 (pre-open deliveries), NKE −3.6415 (after-close guide-down; recovered from −7.3% premarket).
- 2026-10-02 → 10-05: TSM +2.7539 (held D name; anchor vs the 10-02 session unresolved), VST +3.4781.
- 2026-10-05: MRK −3.2987 (read-across from PCVX).
- 2026-10-06: GEV +3.9606 (held D name; read-through to CEG).
- 2026-10-07: DE −3.7962 (FTC/USDA RFI).
- 2026-10-08: PEP +3.7259.
- 2026-09-25 (carried in `ff2bf587`, unchanged): BB +4.1766, COST +2.9314652865 (corrected), AKAM +3.1971.

### Floor-clearers that cannot anchor an identity — 1

ECHO +6.7988 (session 10-02), `qualifying_event_date = 'UNRESOLVED'`. Its only source is one secondary roundup on the DISH DBS Chapter 11 emergence, with no issuer timestamp. **W2 does not date it.** Assigning an anchor would be the second dating screen that PART 1 forbids. The undated tail fell from 9 of 34 floor-clearers last cycle to 1 of 24.

### Identities EXCLUDED before enrichment — 0

None on dedupe, expired window or criterion 5. The three instrument-held names above were held by D1 upstream and are listed rather than excluded by W2.

## Criterion 5 binds nothing this cycle

`state.current_positions` holds **11 open positions, all Strategy D**: GOOGL ×2, GEV, AMZN ×2, ISRG, UBER, TSM ×2, RTX and DIS ×2. There are **zero A positions and zero B positions.** GEV and TSM appear in the intake as below-floor context only.

---

## POST-EVENT TRAJECTORY — still a GAP, named as one, and not improvised

The INDEX MODE bullet's 2026-09-27 pin governs. **No post-event cohort mark layer exists; this was re-measured this run.**
- `events.daily_marks` since 10-01 holds 11 tickers: the held roster plus SGOV, SPY and VOO.
- `events.signal_marks` holds the park menu plus BZUSD and ^VIX.
- **Zero of the 39 intake tickers appear in either table**, apart from GEV and TSM, which are held D names and context items.
- So: no substitute series, no missing observation read as a zero, and no reassignment on W2's authority. Alert `3218eb3c` (`b_cohort_trajectory_unreachable_under_no_pull_boundary`) stays open with W5.

**The within-name panel gains nothing, for the third cycle running.** It still ends 2026-09-18, and W39's FINDINGS 1–5 stand as published. The ~two-week re-randomisation estimate (ρ = +0.273) remains one measurement. The gap is now three cohorts deep, and none of those three can be reconstructed later.

### What W2 CAN add from its own durable record: the GRADING OUTCOME series, itemized per ticker

**W40 cohort (22 identities), graded against the 2026-10-06 AR_orc outcome (DO-NOT-ACTIVATE, no drain):**

| Ticker | Qualifying event | Window closes | Outcome |
|---|---|---|---|
| PPLI, ZS | 2026-09-24 | 2026-10-07 | **Expired ungraded.** They were alive on the bind date, and the bind did not flip. |
| VIAV, TWLO, DELL | 2026-09-25 | 2026-10-08 | Expired ungraded, same reason. |
| KOD, MDB, GFI, CRDO, BA, HL, INTC | 2026-09-28 | 2026-10-09 | Expired ungraded, same reason. |
| FICO, AIR, SMMT | 2026-09-28 | 2026-10-09 | Expired ungraded, same reason. |
| CCL, RCL | 2026-09-29 | 2026-10-12 | **Will expire ungraded.** No flip path fires by 10-12. |
| LQDA, UTHR, JBL, SNPS | 2026-09-30 | 2026-10-13 | Will expire ungraded, same reason. |
| ACN | 2026-10-01 | 2026-10-14 | Will expire ungraded, same reason. |

**W39's last survivor, SECZ, expired ungraded on 2026-10-07.**

**Lineage tally.** There have been seven consecutive index-mode cycles and nine router-gated overflow blocks; W4's count is 83 rows, and tonight's block would be the tenth. **No published B identity has ever been evaluated against B's entry criteria.** W40 was the lineage's best chance: all 22 windows were alive on a scheduled adjudication date. It closed exactly as the reasoned "reachable, not likely" read predicted. That grades W40's prediction as correct. It does not grade B.

**The W41 cohort is structurally unreachable on the scheduled path.** Its latest window closes 2026-10-21, eight trading days before the 2026-11-02 write. Unlike W40, there is no adjudication date inside any window. The only theoretical route is the out-of-cycle limb, which needs Brent to fall 7.23% on the view's own trigger *and* breadth to recover, inside about eight sessions.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, and unaffected by the gap

**S1 — 20 identities, 17 independent events.** There are three shared-driver pairs:
- RXO / CHRW: the same acquisition, **opposite signs**, target and acquirer.
- STX / WDC: the same Toshiba capacity report, identical magnitude.
- SYNA / ON: the same revised takeover, target and acquirer.

Within the ranked 15, RXO/CHRW and STX/WDC share drivers, so the ranked 15 hold 13 independent events. This matters for B's concurrent-position correlation (Section 6 / KL #12).

**S2 — four of the top seven ranked identities are acquisition targets whose post-event price is bounded by the deal consideration.** They are PTC (#1, $205 cash), OPCH (#2, $32.05 cash), RXO (#4, cash plus stock) and SYNA (#7, $123 cash). For a pinned target, the event-day move *is* the deal premium, and the residual is merger-arbitrage completion risk, not a mispricing relative to fundamentals. That is a different mechanism from the one B's convergence hypothesis describes. Ranking by absolute move, the only rule PART 2 gives, mechanically puts these names on top, because a takeover premium is the largest single-day move a large cap makes.
- **B's frozen spec has no rule for this.** `strategy/04_strategy_b.md` and `B_Sub_Pattern_Taxonomy.md` contain no target-side M&A sub-pattern. The only M&A entries are acquirer-side: ON's 2026-06-26 all-stock 4e instance on this same deal, and the EL merger-termination 4a. Index mode makes this cost nothing this cycle.
- **Recorded, not filed.** W2 may not change the ranking rule. Whether a pinned target can satisfy criterion 4's information-versus-sentiment test is the per-candidate judgment D2 makes at thesis construction. Sub-pattern definition is SL/W5 surface. The counts are logged in the decision row as evidence for whoever next revises B's taxonomy.

**S3 — event-type composition of the ranked 15.**

| Event type | Count | Names |
|---|---|---|
| M&A, target | 4 | PTC, OPCH, RXO, SYNA |
| M&A, acquirer | 1 | CHRW |
| Commercial or operational disclosure | 3 | HAE, CEG, HESM |
| Supply/industry report | 2 | STX, WDC |
| Earnings or guidance | 1 | PENG |
| Clinical | 1 | PCVX |
| Analyst action | 1 | SPHR |
| Personnel | 1 | INSM |
| Macro/political | 1 | MELI |

Direction is **9 up / 6 down**. The coin-flip pattern holds for the seventh time. MELI is the cohort's one name with no company-specific event at all, and D1's §19 verdict admitted it on a Brazil-wide re-rating. As in W40's S2 for GFI and CRDO, that is D1's call and W2 does not re-judge it.

**S4 — anchor quality is the best this lineage has recorded.**
- **Undated tail:** 1 of 24 floor-clearers is `UNRESOLVED` (ECHO), against 9 of 34 last cycle and 16 of 65 the cycle before.
- **New fields:** every new row carries `event_timing` or `release_timing` per item.
- **D1's own discipline:** D1 flags STX/WDC as resting on a single page stamp rather than silently dating them.
- **Weak spot:** the two single-stamp names are the cohort's only remaining anchor weakness. Both are 10-01 identities that D2 has not itemized as re-measured. Both close 10-14.

**S5 — instrument-rail items for D2 at thesis construction, none W2's to settle.**
- **HESM** trades as Class A shares of a limited partnership (US ISIN). D2 flagged that "US-listed common equity" must be confirmed for that structure.
- **SPOT** clears the floor by only 8 bp, and **DKNG** by 43 bp.
- **CMG** rests on one unconfirmed FT report.
- The BULL/SPOT/ARGX listing-form question is recorded above, under the held names.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).**

The ranked list is the 15-item table in PART 1, which carries tier, `qualifying_event_date`, event-day move, window close, sessions left, originating D1 id and a one-line event. The five eligible identities below the cap follow it. Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, fields (a) and (c) read **"not assessed — INDEX MODE"** for every candidate. Fields (b), (d), (e), (f) and (g) are in the tables. The cohort work is not skipped: its measurement half is a named GAP, and its structural half and the grading-outcome series are given in full.

## ROUTING

Route the ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. The below-cap five are at W4's discretion. **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.**

**Unlike W40, no adjudication date falls inside any window in this cohort**, so the routing is bookkeeping this cycle, not a live drain set. The rows are still owed. The spec requires them, and an out-of-cycle M1R → D2 router review inside the window, however improbable, would drain only rows that carry the marker.

**Correction to W40's router paragraph.** W40 wrote that the Rev 48 `acute → latent` downgrade and the re-risking limb's leg B "share a trigger: Brent ≤ 96.74". **They do not.**
- **M1a's 2026-10-01 shock-axis rationale** (`regime_events` `3b6d1923`) uses a baseline of **87.20**: the 60-session median ending 09-08, anchored on the 09-09 Gulf attacks as the start of the "current escalation". That gives a midpoint of **97.975**, the figure AR_orc applied on 10-06.
- **`state.rerisking_limb_status`** uses a baseline of **84.73**: the median over 06-01..07-31, anchored on the acute run start 2026-08-01. That gives **96.74**.
- **Who uses which.** W1, W3 and W4 all carry 96.74, and only `Monthly_Fundamental.md` carries 97.975.
- **Why it can bind.** The two thresholds disagree for any Brent close between 96.74 and 97.975. W3's 2026-W40 file (`Weekly_Position_Deep_Dive.md`, finding 2) projects the ~2026-10-29 Dec→Jan roll to land a flat ~102 price at a stored ~96–97 close, two days before the 2026-11-02 scoring. **That projected landing falls inside the disagreement band**, where M1a's leg (ii) would pass and the limb's leg B would fail.
- **What this run did.** This is not this cohort's problem, since every window closes before then, and it is not W2's surface to fix. It is filed as an `ops.alerts` info row for W5 (see FINDINGS).

---

## FINDINGS — one info alert filed, zero queue items, nothing resolved

**`ops.alerts` (info, adjudication W5 SPEC-DEFECT NOTICE INTAKE):**

1. **`shock_baseline_window_divergent_between_m1a_and_limb_view`.** The Rev 48 rubric's "first qualifying event of the current shock structure" (`strategy/09_regime_scoring_strategy_blind_monthly.md`, Pre-shock baseline) is read two ways. `bigquery/224_rerisking_limb_status.sql` anchors on the acute run start, while M1a anchored on the latest escalation. The result is two de-escalation midpoints for one rule. W2 did not edit either surface and did not decide which reading is right. Numbers are in the payload.

**`events.queue_events`:** none. Both free checks were clean on the intake, and no thesis-construction enqueue is owed under index mode.

**Carried, not re-filed:**
- `3218eb3c` (cohort trajectory unreachable, W2's own): still true, re-measured this run.
- `3897ecc6` (two-price mandate date label): binds nothing; every intake row carries the pair. The prose fix remains W5's.
- `06c3b0db` (anchor-vs-reaction clock): no instance this cycle. Every after-close item (SYNA, ON, STX, WDC, PENG) is measured on its reaction session.
- `08582955` (`b_intake_population_coverage_unquantified`, W2's own): unmeasurable from W2's side under the no-pull boundary.
- `74c52a54` (ADR / instrument eligibility): now holds three floor-clearers, and the incorporation-vs-listing-form disagreement is recorded above as evidence.
- `4880faf0` (superseded D1 figures in W2 intake, W4's): this file cites `ff2bf587`, the superseding row.
- `dd5f30f9` (D2's B new-entry-index expiry backlog): D2's.

**Resolved since W40 by their owners:** `03b8f773` (W5, 10-05, already fixed) and `82de3746` (auto-aged, 10-05). `rescreen-COST-B-20261004` was drained by D2 on 10-04 into `ff2bf587`.

---

## HONEST LIMITS OF THIS RUN

- **The trajectory panel gains nothing for the third cycle running.** Every claim about post-event persistence rests on data ending 2026-09-18.
- **Four ranked or below-cap figures were never broker-verified:** SYNA, ON, STX and WDC, the 10-01 cohort. They are arithmetic-checked only. STX and WDC also carry single-stamp anchors.
- **S2's deal-pinning count is W2's reading of D1's one-line reasons, not a measurement.** Whether a given spread leaves room for B's mechanism is D2's per-candidate call.
- **The baseline finding reproduces two surfaces' own arithmetic; it does not re-derive either baseline.** W2 did not recompute the 60-session median from raw marks and did not decide which shock-structure start the rubric means.
- **Nothing here re-tests D1's significance verdicts.** That includes the two analyst-action names W2 ranks (SPHR, plus HOG and DKNG below the cap) and the macro name MELI, none of which W2 would have surfaced itself.
- **W2 has no price-layer completeness backstop.** This file can say nothing about what D1's bounded scan did not surface.

2026-W47

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-11-22 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W47
**Intake watermark:** 2026-11-15T08:30:16Z, this routine's own prior completion (`state.routine_catchup_window`). **Catch-up window:** 6.98 days, the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `2139a463-b52e-4711-9b4f-b54abd4866a9` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · zero `ops.alerts` rows filed.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-11-18).** Last cycle (W46) was the one full-depth cycle. The router value is now `DO-NOT-ACTIVATE — PENDING div-B-202611-3`. This is a held state, not a judged one, and it is operative.

**What decides this cycle:**
- **B ran ACTIVATE from 11-09 to 11-18, and the drain resolved.** All 456 B `thesis-construction` items enqueued since 11-09 are terminal:
  - **14 GO**, each staged (instructions 100–113). `state.current_positions` now holds 14 open B positions: ANDE, ARQT, DDOG, ECG, EXPE, IRTC, MCY, MTRN, NRIX, RELY, ROK, RVMD, SM and SYY.
  - **186** DECLINE (conservative default: window lapsed). These are the 11-10..11-13 blackout casualties W46 reported.
  - **197** NO-GO (criterion-2), **30** NO-ACTION (conservative default), **10** NO-GO (criterion-2-residual), **8** NO-GO (eligibility), **8** NO-GO (full thesis) and **3** NO-GO (eligibility-adv).
  - **This is the first time a published B identity has been graded against B's entry criteria.** See the GRADING OUTCOME series below.
- **The flip back.** On 11-18, D2's measured-trigger review (`vix_regime_exit_high`, review `f411301f`) found B's technical line ACTIVATE (SPY NEUTRAL 730.20, VIX NORMAL 24.56) but B's standing fundamental call DO-NOT-ACTIVATE (`76858106`). D2 opened `div-B-202611-3` and wrote the held row `c28273be` (23:19Z).
- **`div-B-202611-3` is `attacker-complete`** (queue, 11-20); AR_orc's verdict is still owed. W2 makes no forecast of it and does not pre-empt AR_orc.
- **Consequence for this file:** no new B entry can be made from this intake unless that review, or another of the four flip paths in the router clause, writes ACTIVATE while a window is open. The ranked windows close between 11-23 and 12-03.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

`SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-11-18)`

W2 performs **zero market-wide discovery**:
- It pulled no broad bars, enumerated no movers and repeated no event search.
- It did not re-judge D1's §19 significance verdicts or D1's Rev 49 eligibility calls.
- **It pulled no price bars or quotes of any kind.** `scripts/check_routine_scope.py` enforces that boundary.
- The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

**METERED SPEND: ZERO.** No Parallel, web_search, web_fetch, FMP or HF call was made by the orchestrator or ANY sub-agent. This is an honest zero, not an omission.
- Index mode skips per-candidate enrichment, so no search was owed.
- One Sonnet data-assembly sub-agent did read-only extraction from `Watchlist.md` (local file reads only).
- Everything else was BigQuery reads by the orchestrator.

**Coverage edge left open: the 2026-11-20 (Friday) session**, together with the 11-19 after-close reporters that reacted on 11-20. D1 last completed 11-19 22:40Z, and D1's Sunday scan tonight owns that gap; PART 1 forbids W2 from covering it. **W46's open edge is closed:** the 11-10..11-13 blackout sessions are in this intake (D1 catch-up row `c3638fec`, written 11-15 22:37Z, after W46's watermark).

**BigQuery availability.** W1's slot this morning (07:39Z) halted on a BigQuery connector de-auth (`ops/spikes/bigquery-deauth-2026-11-22-w1-halt-record.md`). The connector answered normally for this whole run, so W2 ran in full. The outage's onset and recovery are recorded in that file and are not W2's to settle.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`:

| Field | Value |
|---|---|
| value | `DO-NOT-ACTIVATE — PENDING div-B-202611-3` |
| as_of | 2026-11-18 |
| event | `c28273be-988d-4e90-927a-9e0d2b266158` (D2, 23:19:28Z) |
| divergence | `div-B-202611-3`, queue status `attacker-complete` (11-20); AR_orc verdict owed |
| previous B row | `ACTIVATE` (D2 measured refresh, 11-09, `461ba0ee`) |
| Strategy A | `DO-NOT-ACTIVATE` (11-04, `066f367a`) |

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE. Session 1 is the first trading session on or after the qualifying event date, and the window closes on the 10th trading session inclusive.
- Trading days come from `state.market_calendar`. **11-26 (Thanksgiving) is a holiday**, and 11-27 is a trading session.
- SMMT's qualifying event date is a Sunday (11-15). Its session 1 is therefore 11-16, so it closes 11-30.
- **Every window-close date below matches D2's index row exactly** (49 of 49).

| Window closes | Sessions left from 11-23, inclusive | Ranked + below-cap identities |
|---|---|---|
| 2026-11-23 | 1 | 3 |
| 2026-11-24 | 2 | 2 |
| 2026-11-25 | 3 | 7 |
| 2026-11-30 | 5 | 7 |
| 2026-12-01 | 6 | 6 |
| 2026-12-02 | 7 | 10 |
| 2026-12-03 | 8 | 6 |
| 2026-11-16 / 2026-11-20 (expired) | 0 | 8 excluded |

**How the move is measured:** for an after-close release, the move is measured on the NEXT session (the reaction session). The ranked table marks that session in **bold** where it differs from the qualifying date. 22 of the 49 items are after-close releases.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five `single-name-move` rows have landed since the watermark, and none is superseded. Together they carry **49** `passed[]` items, which are 49 distinct ticker + `qualifying_event_date` identities. MOD appears twice, on two distinct events (11-12 and 11-18). All 49 clear B's spec floor (`below_spec_floor = false`, minimum |move| 5.22%), all are `legacy_rule_pass = true`, and all carry both recorded closes.

| Decision id | Session(s) screened | `passed[]` | `screen_mode` / note |
|---|---|---|---|
| `c3638fec-f367-45f4-936a-b08b24291514` | 2026-11-10..11-13 (blackout catch-up, written 11-15) | 20 | full; **degraded discovery** (`degraded_legs`) |
| `6af501d7-dcb2-45e4-bf9c-c4fdfa10d70b` | 2026-11-16 | 5 | full |
| `46f9523a-d05a-4a2f-8192-c0fe389c6999` | 2026-11-17 | 8 | full |
| `5e7515bb-8d49-4b10-a7eb-8676466cc4c5` | 2026-11-18 | 4 | router-gated |
| `d9eb6c19-9fd9-4a87-b83a-368ce4abaa20` | 2026-11-19 | 12 | router-gated |

- **No passed item has an UNRESOLVED anchor**, so the unanchored-name line of index mode lists nothing. Unanchored names (for example PDD, AMD and SQM) sit only in D1's rejected sets.
- **Deal-pinned rail:** no passed item's `reason` begins `deal-pinned:`, and none records a signed all-cash deal at a pinned price.
  - **MOD (11-12)** and **BILL** are unsigned reports with no price.
  - **TU** is a non-binding proposal.
  - **HWC** and **PANW** are acquirers.
  - **GFL** is a deal break.
  - All of these stay rankable.
- **Not intake:** the `sector-move` rows (`70bf9236`, `62c5958d`, `c0b189cc`, `8c0e6dc9`, `ee7039cd`) and the `add-candidate-review` rows (`631ac725`, `e80382c3`).

## Four-part identity dedupe — matched on the FIELDS, never on the key string

- **Queue rows:** no `events.queue_events` B `thesis-construction` row, open or terminal, carries any of the 49 ticker + `qualifying_event_date` identities. There are same-ticker rows, but each is on a distinct earlier event:
  - `thesis-MOD-B-20261103`: NO-GO criterion-2-residual.
  - `thesis-SMMT-B-20261104`: NO-ACTION.
  - `thesis-RYTM-B-20261103`: complete.
- **Decision rows:** no B thesis or B decision row exists for any intake identity.
- **Open Strategy A positions:** none. The 14 open B positions and 12 D tranches share no ticker with the intake.
- **Expired B windows:** **8 identities are excluded before ranking.** Their windows closed before the next session (11-23):
  - STVN (qed 11-03, closed 11-16).
  - AAON, HIMS, NOVT, QLYS, TTWO, SKYD and RKLB (qed 11-09, all closed 11-20).
  - All eight were screened by D1 only on 11-15, in the blackout catch-up, so they never had a routable session.

**Identities EXCLUDED before enrichment: 8** (all window-expired). Rankable: 41.

## RECORDED-FIGURE ARITHMETIC CHECK — 49 of 49 items, zero mismatches

For every item, `metric_pct` equals `(event_close / prior_close − 1) × 100` to the recorded 4-decimal precision. No `rescreen-` item is owed.

## CROSS-ROW CLOSE-CHAIN CHECK — 6 hits on the actionable side, 0 defects

**Search scope:** every `single-name-move` row landed since 2026-10-20, covering `passed[]` items, `rejected_notable` items and the 2,044 `rejected_compact` tuples (4,325 records in all). Each was matched on the same name and the same `qualifying_event_date`, using the tuple's row session as its date.

- **6 hits on the actionable side**, where the intake item's `prior_close` equals another record's `event_close`:
  - AAON, NOVT, QLYS, RKLB and SKYD (qed 11-09) chain from `9f5c6b11` compact tuples on the 11-09 session.
  - PANW (qed 11-18) chains from a `5e7515bb` compact tuple on the 11-18 session (309.29 → 339.92).
  - **All six are after-close releases** measured on the reaction session. That is the case the rule names as legitimate, not the IONQ `6e179f3c` continuation-leg defect. D1's own `c3638fec` and `d9eb6c19` chain notes record the same reading.
  - Five of the six are window-expired anyway.
- **5 hits on the other side**, which are not actionable. CGON, SMMT and UNH (to `46f9523a` / `5e7515bb` notable items) and DGII and NBIS (to `c3638fec` notable items) each run forward from the anchor.

**This is a record read, not a re-measurement, and a clean pass is not a clearance.** The tuple closes are D1's discovery closes, and coverage is partial by construction.

## MEASUREMENT OF RECORD — D1's figures, because D2 re-measured none of them

The D2-REMEASURED FIGURE PRECEDENCE rule was applied and **changes nothing this cycle.**
- All 49 identities have a D2 index row in `Watchlist.md`'s "Strategy B new-entry candidates" (lines 1919–1967).
- Every one of those rows says its figures are D1's and were not re-measured.
- D1 and D2 agree on figure, `qualifying_event_date` and window close for every identity.
- No D1 `superseded` correction row exists for any intake row.
- So the rank key is the D1 figure. It is arithmetic-consistent but not broker-verified at this stage.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor — 41 identities, 15 ranked at the cap

Ranks 1–5 carry tier `top-5` and ranks 6–15 carry `rest`. There is no tie at the cap: rank 15 NTES is -11.3907, and rank 16 ACM is +11.0759.

| Rank | Tier (e) | Ticker (a) | `qualifying_event_date` (f) | Move % (c) | Measured on | Window close (d) | Sessions left from 11-23 | Originating D1 id (g) | Event (one line, factual, from D1's item text) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `top-5` | LFTO | 2026-11-12 | +30.6253 | **11-13** | 2026-11-25 | 3 | `c3638fec` | Q3 well above guidance (revenue $238M, +32%) with guidance above consensus; after-close release |
| 2 | `top-5` | SA | 2026-11-19 | -29.3151 | 11-19 | 2026-12-03 | 8 | `d9eb6c19` | BC Supreme Court quashed the KSM Project Substantially Started Designation (issuer release, 6-K); release 11-19 release |
| 3 | `top-5` | MOD | 2026-11-12 | +27.8605 | **11-13** | 2026-11-25 | 3 | `c3638fec` | Bloomberg report that Samsung is in takeover talks; unsigned, no price (not deal-pinned); after-close release |
| 4 | `top-5` | SNEX | 2026-11-18 | -26.7137 | **11-19** | 2026-12-02 | 7 | `d9eb6c19` | Fiscal Q4 results (8-K Item 2.02); after-close release |
| 5 | `top-5` | CRWV | 2026-11-10 | +24.7076 | **11-11** | 2026-11-23 | 1 | `c3638fec` | Q3 beat; 2026 revenue guide raised to $13.0-13.3B; after-close release |
| 6 | `rest` | CTVA | 2026-11-11 | -24.2998 | **11-12** | 2026-11-24 | 2 | `c3638fec` | Q3 miss and a sharp cut to the FY adjusted profit outlook on Brazil; after-close release |
| 7 | `rest` | NBIS | 2026-11-12 | -16.8401 | 11-12 | 2026-11-25 | 3 | `c3638fec` | Q3 revenue beat, 2026 revenue to low end of guide, capex raised (2026 ~$27B, 2027 $40-45B); pre-open release |
| 8 | `rest` | SMMT | 2026-11-15 | -16.4664 | **11-16** | 2026-11-30 | 5 | `6af501d7` | FDA complete response letter for the ivonescimab BLA (HARMONi, OS not significant); Sun release release |
| 9 | `rest` | WSM | 2026-11-19 | -15.1601 | 11-19 | 2026-12-03 | 8 | `d9eb6c19` | Q3 results (8-K Item 2.02); pre-open release |
| 10 | `rest` | CGON | 2026-11-16 | +13.9516 | 11-16 | 2026-11-30 | 5 | `6af501d7` | PIVOT-006 Phase 3 topline for cretostimogene in NMIBC met its primary endpoint; pre-open release |
| 11 | `rest` | DGII | 2026-11-11 | -12.7240 | **11-12** | 2026-11-24 | 2 | `c3638fec` | FQ4 beat, but FY27 growth guide 10-15% and a soft Q1 guide; after-close release |
| 12 | `rest` | BILL | 2026-11-17 | +12.5803 | 11-17 | 2026-12-01 | 6 | `46f9523a` | FT report that TPG is close to a take-private; unsigned, no price (not deal-pinned); intraday release |
| 13 | `rest` | TU | 2026-11-16 | +12.1923 | 11-16 | 2026-11-30 | 5 | `6af501d7` | TELUS confirmed an unsolicited, non-binding Quebecor acquisition proposal; pre-open release |
| 14 | `rest` | NU | 2026-11-12 | +11.7498 | **11-13** | 2026-11-25 | 3 | `c3638fec` | Record Q3 net income of $1.1B and US-launch plans; after-close release |
| 15 | `rest` | NTES | 2026-11-19 | -11.3907 | 11-19 | 2026-12-03 | 8 | `d9eb6c19` | Q3 2026 results: net revenue down 1.8% y/y, games down 1.7% (6-K); pre-open release |

### BELOW THE CAP — 26 eligible identities (`below-cap`, not ranked)

Format: ticker, move %, (`qualifying_event_date` MM-DD, originating D1 id), ordered by absolute move:

ACM +11.08 (11-16, `46f9523a`); YETI -10.49 (11-12, `c3638fec`); VVV +10.40 (11-19, `d9eb6c19`); ACIW -10.25 (11-18, `5e7515bb`); HWC -10.20 (11-12, `c3638fec`); MANU -9.50 (11-19, `d9eb6c19`); TEVA -8.74 (11-18, `d9eb6c19`); TSN +8.72 (11-16, `6af501d7`); RYTM +8.49 (11-16, `46f9523a`); KLIC -8.08 (11-18, `d9eb6c19`); TJX +8.05 (11-18, `5e7515bb`); UGI -7.75 (11-19, `d9eb6c19`); HP -7.71 (11-18, `d9eb6c19`); JD -7.66 (11-17, `46f9523a`); GFL -7.56 (11-10, `c3638fec`); ONON -7.54 (11-10, `c3638fec`); TME +6.64 (11-17, `46f9523a`); PANW +6.42 (11-18, `d9eb6c19`); NKE -6.30 (11-17, `46f9523a`); MOD +6.28 (11-18, `5e7515bb`); CSCO -6.24 (11-12, `c3638fec`); ESLT +5.85 (11-17, `46f9523a`); BLSH +5.66 (11-18, `5e7515bb`); UNH -5.42 (11-17, `46f9523a`); BIDU -5.38 (11-16, `6af501d7`); WWD +5.22 (11-18, `d9eb6c19`).

**The cap decides nothing W2 owns this cycle.** Ranked and below-cap identities share one fate unless the router flips. W4 decides under §C whether to carry the below-cap names into the overflow block.

### Not rankable — floor-clearing items D1 did not route: 0

### Context only — below the floor — 0 items

### Identities EXCLUDED before enrichment — 8

| Ticker | qed | Move % | Window closed | D1 id |
|---|---|---|---|---|
| STVN | 2026-11-03 | -28.5714 | 2026-11-16 | `c3638fec` |
| AAON | 2026-11-09 | +19.3097 | 2026-11-20 | `c3638fec` |
| HIMS | 2026-11-09 | -16.6085 | 2026-11-20 | `c3638fec` |
| NOVT | 2026-11-09 | -15.2555 | 2026-11-20 | `c3638fec` |
| QLYS | 2026-11-09 | -13.5088 | 2026-11-20 | `c3638fec` |
| TTWO | 2026-11-09 | +8.3124 | 2026-11-20 | `c3638fec` |
| SKYD | 2026-11-09 | -7.5862 | 2026-11-20 | `c3638fec` |
| RKLB | 2026-11-09 | +6.5409 | 2026-11-20 | `c3638fec` |

## Rev 49 instrument eligibility and Criterion 5

- **Rev 49 eligibility:** D1 applied it on every row, and W2 does not re-judge it. The ADRs in the intake (NTES, JD, TME, BIDU, ESLT, NU, MANU and BLSH) are D1's eligibility calls.
- **Criterion 5:** no Strategy A position is open, so B criterion 5 excludes no name.

---

## POST-EVENT TRAJECTORY — re-sourced from D2's `CLOSED-WINDOW COHORT NOTE` series

**Definition.**
- **Source of record:** D2's `CLOSED-WINDOW COHORT NOTE` series in `Watchlist.md`. This cycle reads the five notes dated 11-15, 11-16, 11-17, 11-18 and 11-19 (lines 2042–2050), all on or after W2's previous run date. D2 has written no note after 11-19.
- **Dedupe:** on ticker + `qualifying_event_date`, against every annotation already published. That leaves **50 new rows, with 0 overlaps and 0 internal duplicates.**
- **`gap_intact_pct`** follows the 2026-W38 definition: (window-close close − pre-event close) ÷ (event-session close − pre-event close) × 100.
- **Basis:** every annotation prints all three closes, so every row is **`basis: closes`**. None is UNMEASURED.
- **Grouping:** every one of the five notes calls its ten names one same-event-week cohort, "not ten independent draws". The 11-18 note splits its ten into a sub-cohort closing 11-05 and one closing 11-06. So these are **five cohorts of correlated observations, not 50 independent ones.**

**This is a FIXED-HORIZON series.** It has one observation per identity, taken at that identity's own window close. **It is not a continuation of, and must not be spliced onto, the retired 2026-W29..W38 COMMON-DATE cross-section.** The within-name panel that ended 2026-09-18 is cited by reference (2026-W39 findings) and is not re-published.

### Aggregate, offered only beside the per-ticker rows that follow

| Statistic | Value |
|---|---|
| New observations | 50 |
| Median `gap_intact_pct` | 125.29 |
| ≥ 100 (move fully intact or extended) | 28 |
| < 0 (move fully reversed and beyond) | 10: COCO, KNSL, ENVA, WULF, CLS, AMKR, CDNS, ARE, ESLT, WELL |
| Median per note (11-15 / 11-16 / 11-17 / 11-18 / 11-19) | 174.87 / 151.98 / 125.29 / 72.27 / -21.22 |
| D2's own summaries (continuations to reversals, median drift) | 11-15 9:1, +7.03%; 11-16 7:3, +2.72%; 11-17 6:4, +4.61%; 11-18 3:7, −1.05%; 11-19 3:7, −8.19% |
| UNMEASURED | 0 |

The per-note medians fall from the 10-22 cohort to the 10-26 cohort. That is five correlated cohorts, so it is a record and not a trend, and no criterion is re-derived from it.

### Per-ticker series (50 new annotations, in D2 note order)

| # | Ticker | qed | Window close | Pre-event close | Event close | Window-close close | `gap_intact_pct` | Basis | D2 reading | D2 note |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SPOT | 2026-10-22 | 2026-11-04 | 525.34 | 583.66 | 627.66 | 175.45 | `closes` | CONTINUATION | 2026-11-15 |
| 2 | ALLE | 2026-10-22 | 2026-11-04 | 159.0 | 176.52 | 192.69 | 192.29 | `closes` | CONTINUATION | 2026-11-15 |
| 3 | R | 2026-10-22 | 2026-11-04 | 240.31 | 265.53 | 283.12 | 169.75 | `closes` | CONTINUATION | 2026-11-15 |
| 4 | ROP | 2026-10-22 | 2026-11-04 | 397.56 | 436.23 | 492.22 | 244.79 | `closes` | CONTINUATION | 2026-11-15 |
| 5 | BX | 2026-10-22 | 2026-11-04 | 109.57 | 118.75 | 125.57 | 174.29 | `closes` | CONTINUATION | 2026-11-15 |
| 6 | NDAQ | 2026-10-22 | 2026-11-04 | 96.12 | 103.3 | 109.7 | 189.14 | `closes` | CONTINUATION | 2026-11-15 |
| 7 | CURB | 2026-10-22 | 2026-11-04 | 26.91 | 28.86 | 30.16 | 166.67 | `closes` | CONTINUATION | 2026-11-15 |
| 8 | ZGN | 2026-10-22 | 2026-11-04 | 12.92 | 13.85 | 14.88 | 210.75 | `closes` | CONTINUATION | 2026-11-15 |
| 9 | COCO | 2026-10-22 | 2026-11-04 | 63.5 | 59.0 | 65.47 | -43.78 | `closes` | REVERSAL of a down-move | 2026-11-15 |
| 10 | LMT | 2026-10-22 | 2026-11-04 | 551.51 | 589.91 | 595.04 | 113.36 | `closes` | CONTINUATION by sign but effectively flat | 2026-11-15 |
| 11 | TSCO | 2026-10-22 | 2026-11-04 | 32.69 | 34.73 | 36.58 | 190.69 | `closes` | CONTINUATION | 2026-11-16 |
| 12 | VLY | 2026-10-22 | 2026-11-04 | 13.02 | 13.81 | 14.49 | 186.08 | `closes` | CONTINUATION | 2026-11-16 |
| 13 | DAR | 2026-10-22 | 2026-11-04 | 59.09 | 55.64 | 52.3 | 196.81 | `closes` | CONTINUATION | 2026-11-16 |
| 14 | BFH | 2026-10-22 | 2026-11-04 | 108.63 | 102.45 | 104.83 | 61.49 | `closes` | REVERSAL | 2026-11-16 |
| 15 | RHI | 2026-10-22 | 2026-11-04 | 37.68 | 45.87 | 44.95 | 88.77 | `closes` | REVERSAL by sign but small | 2026-11-16 |
| 16 | BE | 2026-10-22 | 2026-11-04 | 217.77 | 193.3 | 200.4 | 70.98 | `closes` | REVERSAL | 2026-11-16 |
| 17 | SLM | 2026-10-22 | 2026-11-04 | 21.76 | 19.41 | 18.68 | 131.06 | `closes` | CONTINUATION | 2026-11-16 |
| 18 | FIX | 2026-10-22 | 2026-11-04 | 1279.37 | 1160.86 | 1091.31 | 158.69 | `closes` | CONTINUATION | 2026-11-16 |
| 19 | CCI | 2026-10-22 | 2026-11-04 | 78.83 | 85.97 | 92.17 | 186.83 | `closes` | CONTINUATION | 2026-11-16 |
| 20 | CUBI | 2026-10-22 | 2026-11-04 | 78.73 | 84.54 | 87.17 | 145.27 | `closes` | CONTINUATION | 2026-11-16 |
| 21 | SSNC | 2026-10-22 | 2026-11-04 | 89.54 | 82.96 | 79.57 | 151.52 | `closes` | CONTINUATION | 2026-11-17 |
| 22 | REXR | 2026-10-22 | 2026-11-04 | 36.28 | 38.71 | 39.25 | 122.22 | `closes` | CONTINUATION but small | 2026-11-17 |
| 23 | KNSL | 2026-10-22 | 2026-11-04 | 390.64 | 364.49 | 391.73 | -4.17 | `closes` | REVERSAL | 2026-11-17 |
| 24 | ENVA | 2026-10-22 | 2026-11-04 | 176.78 | 165.07 | 181.18 | -37.57 | `closes` | REVERSAL | 2026-11-17 |
| 25 | SIGI | 2026-10-22 | 2026-11-04 | 91.74 | 96.61 | 103.2 | 235.32 | `closes` | CONTINUATION | 2026-11-17 |
| 26 | LKQ | 2026-10-23 | 2026-11-05 | 22.47 | 17.42 | 20.54 | 38.22 | `closes` | REVERSAL | 2026-11-17 |
| 27 | TNGX | 2026-10-23 | 2026-11-05 | 27.93 | 23.34 | 20.87 | 153.81 | `closes` | CONTINUATION | 2026-11-17 |
| 28 | GMAB | 2026-10-23 | 2026-11-05 | 40.0 | 43.79 | 52.74 | 336.15 | `closes` | CONTINUATION | 2026-11-17 |
| 29 | FLG | 2026-10-23 | 2026-11-05 | 11.44 | 10.38 | 10.6 | 79.25 | `closes` | REVERSAL but small | 2026-11-17 |
| 30 | CART | 2026-10-23 | 2026-11-05 | 51.68 | 56.44 | 57.79 | 128.36 | `closes` | CONTINUATION but small | 2026-11-17 |
| 31 | RITM | 2026-10-23 | 2026-11-05 | 8.68 | 9.39 | 9.45 | 108.45 | `closes` | CONTINUATION but effectively flat | 2026-11-18 |
| 32 | FCNCA | 2026-10-23 | 2026-11-05 | 2196.76 | 2375.84 | 2304.72 | 60.29 | `closes` | REVERSAL | 2026-11-18 |
| 33 | INFY | 2026-10-23 | 2026-11-05 | 13.22 | 12.35 | 12.8 | 48.28 | `closes` | REVERSAL | 2026-11-18 |
| 34 | TEM | 2026-10-23 | 2026-11-05 | 63.81 | 67.61 | 70.43 | 174.21 | `closes` | CONTINUATION | 2026-11-18 |
| 35 | WULF | 2026-10-23 | 2026-11-05 | 11.32 | 11.98 | 10.08 | -187.88 | `closes` | REVERSAL | 2026-11-18 |
| 36 | SGRY | 2026-10-26 | 2026-11-06 | 15.75 | 23.25 | 23.2 | 99.33 | `closes` | flat | 2026-11-18 |
| 37 | RRC | 2026-10-26 | 2026-11-06 | 45.52 | 53.56 | 48.72 | 39.80 | `closes` | REVERSAL | 2026-11-18 |
| 38 | CTOS | 2026-10-26 | 2026-11-06 | 9.01 | 10.51 | 9.33 | 21.33 | `closes` | REVERSAL | 2026-11-18 |
| 39 | HWKN | 2026-10-26 | 2026-11-06 | 135.44 | 153.85 | 150.95 | 84.25 | `closes` | REVERSAL but small | 2026-11-18 |
| 40 | ORKA | 2026-10-26 | 2026-11-06 | 80.15 | 90.33 | 102.86 | 223.08 | `closes` | CONTINUATION | 2026-11-18 |
| 41 | CLS | 2026-10-26 | 2026-11-06 | 246.65 | 276.54 | 206.68 | -133.72 | `closes` | REVERSAL | 2026-11-19 |
| 42 | PPTA | 2026-10-26 | 2026-11-06 | 16.6 | 18.37 | 19.53 | 165.54 | `closes` | CONTINUATION | 2026-11-19 |
| 43 | ASST | 2026-10-26 | 2026-11-06 | 28.97 | 26.32 | 21.45 | 283.77 | `closes` | CONTINUATION | 2026-11-19 |
| 44 | AMKR | 2026-10-26 | 2026-11-06 | 36.81 | 39.94 | 32.82 | -127.48 | `closes` | REVERSAL | 2026-11-19 |
| 45 | CDNS | 2026-10-26 | 2026-11-06 | 322.17 | 343.08 | 319.92 | -10.76 | `closes` | REVERSAL | 2026-11-19 |
| 46 | AGYS | 2026-10-26 | 2026-11-06 | 123.45 | 115.81 | 121.09 | 30.89 | `closes` | REVERSAL | 2026-11-19 |
| 47 | ARE | 2026-10-26 | 2026-11-06 | 43.4 | 40.86 | 44.8 | -55.12 | `closes` | REVERSAL | 2026-11-19 |
| 48 | ESLT | 2026-10-26 | 2026-11-06 | 735.34 | 777.96 | 682.59 | -123.77 | `closes` | REVERSAL | 2026-11-19 |
| 49 | WELL | 2026-10-26 | 2026-11-06 | 240.61 | 226.72 | 245.01 | -31.68 | `closes` | REVERSAL | 2026-11-19 |
| 50 | NE | 2026-10-26 | 2026-11-06 | 47.81 | 45.22 | 40.87 | 267.95 | `closes` | CONTINUATION | 2026-11-19 |

### Not yet in the series — PENDING D2 ANNOTATION, and the named GAPs

- **PENDING D2 ANNOTATION, as D2's most recent note (11-19) states it, not re-derived:** "Remaining backlog: 555 unannotated closed rows … (3 closing 2026-11-06, SSD first; 35 closing 2026-11-09; 64 closing 2026-11-10; 80 closing 2026-11-11; 16 closing 2026-11-12; 26 closing 2026-11-13; 82 closing 2026-11-16; 133 closing 2026-11-17; 96 closing 2026-11-18; 20 closing 2026-11-19); the next oldest window-close date is 2026-11-06 (SSD)."
  - The note predates the 11-20 closes, which add more pending windows. These include W46's 20 qed-11-09 identities and this intake's seven expired qed-11-09 names (AAON, HIMS, NOVT, QLYS, TTWO, SKYD and RKLB). STVN closed 11-16 and is inside the 82.
  - They are pending, not gaps and not zeros.
  - D2 writes ten a run, so at that pace this backlog takes roughly 55 runs to clear. That is D2's lane, not W2's.
- **Named GAPs (intake identity with no index row at all): none new.** All 49 intake identities have index rows. The earlier GAPs are unchanged: EFXT, CRWV 10-14, BULL, SPOT 10-07, ARGX and ECHO.

### Repeat names — each on a distinct event

- **ESLT** is in the new series (qed 10-26, `gap_intact_pct` −123.77) and in this intake (qed 11-17, +5.85%, below-cap).
- **MOD** has two intake identities (11-12, rank 3; 11-18, below-cap) plus a graded 11-03 identity (NO-GO criterion-2-residual).
- **SMMT** (prior 11-04 identity: NO-ACTION), **RYTM** (prior 11-03 identity: complete) and **CRWV** (10-14 GAP) are each on a distinct event.
- LKQ, GMAB, TEM, WULF and others that W45 listed as pending are now annotated.

### What W2 adds from its own durable record: the GRADING OUTCOME series, itemized per ticker

B was ACTIVATE from 11-09 to 11-18. In that period D2 drained every enqueued B identity to a terminal state. Latest status per item key (`events.queue_events`, B `thesis-construction`, enqueued since 11-09) is 456 items, all terminal.

| Cohort (by `qualifying_event_date`) | Items | Outcome |
|---|---|---|
| 10-28 / 10-29 / 10-30 / 11-02 | 64 / 80 / 16 / 26 | all DECLINE (conservative default: window lapsed), lost to the 11-10..11-12 blackout |
| 11-03 | 81 | 6 GO · 61 NO-GO (criterion-2) · 7 NO-ACTION · 3 NO-GO (full thesis) · 2 NO-GO (eligibility) · 1 NO-GO (eligibility-adv) · 1 NO-GO (criterion-2-residual) |
| 11-04 | 133 | 6 GO · 93 NO-GO (criterion-2) · 20 NO-ACTION · 5 NO-GO (eligibility) · 5 NO-GO (criterion-2-residual) · 4 NO-GO (full thesis) |
| 11-05 | 55 | 2 GO · 42 NO-GO (criterion-2) · 4 NO-GO (criterion-2-residual) · 3 NO-ACTION · 2 NO-GO (eligibility-adv) · 1 NO-GO (full thesis) · 1 NO-GO (eligibility) |
| 11-09 | 1 | 1 NO-GO (criterion-2) (FRVO) |

**W46's own routed top-5 (enqueued by W4 on 11-15):**
- **IRTC → GO** (staged `entry-IRTC-B-20261115`, instruction 108; decision `6eacca6f`; now an open B position).
- **KRMN** (`fcc0c1c3`), **FROG** (`36fa5106`), **TMDX** (`47de9e56`) and **FRVO** (`2578048a`) → **NO-GO (criterion-2)**.
- W46's other 80 identities (ranks 6–15 and the 70 below-cap) got no W4 enqueue under the ACTIVATE router. Their windows closed between 11-18 and 11-20. W2 did not re-check each of the 80 against the 11-09 drain keys, so **at most 80 expired ungraded**.

**Lineage tally:**
- **Graded for the first time:** 270 identities reached a criterion verdict (14 GO, 256 NO-GO / NO-ACTION). The other 186 drain items lapsed. Across those 270 verdicts, criterion 2 decided 197 NO-GO + 10 residual = 207, which is 77%.
- **Expired ungraded:** W40–W43 136; W44 183 (per W46); W45 77 (per W46); plus up to 80 from W46.
- **Open:** this file's 41 rankable identities. None is reachable unless the router flips.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, record-read only

**S1 — a thin, late-season intake.**
- There are 41 routable identities, against 85 in W46 and 342 in W45: the tail of the Q3 earnings season.
- **Direction:** 23 down and 18 up among the routable 41. Within the ranked 15, 8 are down and 7 are up.
- **Non-earnings anchors are a larger share than in any recent cycle**, at about 14 of 49:
  - Courts: SA.
  - Takeover reports or proposals: MOD 11-12, BILL and TU. GFL is a deal break, and HWC is an acquirer.
  - FDA: SMMT (CRL).
  - Clinical data: CGON and RYTM.
  - Management departures: ACIW and TEVA.
  - Investor days: NKE and MOD 11-18.
  - Sector policy: UNH, which D1 typed `macro`.
- For B's information-versus-sentiment mechanism, the unsigned-bid names (MOD, BILL, TU) are binary setups, where the gap to a plausible offer is the question. That is D2's question at thesis construction if the router flips.

**S2 — the 11-19 session tape.** SPY fell 1.96% on 11-19 (D1's figures). The 12 `d9eb6c19` identities, including SA, SNEX, WSM and NTES in the ranked 15, carry their own event *and* that tape. D1 handled common drivers at screen time, and W2 does not re-judge them. Index mode cannot separate the event-specific component from the tape.

**S3 — noisy names.** D1 records many other ≥5% sessions in the prior 10 for CRWV (8) and SMMT (8). For these names the event move is one of several in the window.

**S4 — anchor and measurement quality.**
- **Strong on checks:** 49 of 49 items carry both closes, the arithmetic is clean, and all 6 actionable-side chain hits resolve to after-close releases.
- **Weaker on provenance:** the `c3638fec` catch-up row was screened with degraded discovery after the blackout. D1 measured four sessions in one late pass, five days after the first of them.
- **Broker verification:** no index row has been broker re-measured.
- **After-close measurement:** 8 of the ranked 15 are measured on a later session than their qed (the bold cells). Seven are after-close releases, and SMMT's release came on a Sunday.

**S5 — the blackout's shadow on routability.** Eight of the 20 identities D1 recovered for 11-09..11-13 were already window-expired on the first session W2 can route to. A four-session catch-up screen arriving after the blackout nearly exhausts a 10-session window. This is a record of cost. The blackout itself is surfaced elsewhere, and W2 files nothing on it.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-11-18).**

The ranked list is the 15-item table in PART 1. Every row carries:
- the tier field (e), set strictly by rank (1–5 `top-5`, 6–15 `rest`);
- `qualifying_event_date` (f);
- the event-day move (c, as the index-mode move field);
- the window close and sessions left (d);
- the originating D1 id (g);
- a one-line event (b).

The 26 eligible identities below the cap follow it, marked `below-cap`.

Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, the mispricing-direction and convergence-indicator fields read **"not assessed — INDEX MODE"** for every candidate.

The cohort work is not skipped. The fixed-horizon trajectory series, the structural findings and the grading-outcome series are all given in full above.

## ROUTING

Route the 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. **W4 §C's top tier is the five `top-5` rows: LFTO, SA, MOD, SNEX, CRWV.**

- The 26 below-cap names are at W4's discretion.
- **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.** That includes the held `— PENDING div-B-202611-3` value.
- **For W4 and for whatever drains a flip:** CRWV (rank 5) closes 11-23, so a flip would need to bind by that session. CTVA and DGII close 11-24. LFTO, MOD and NBIS close 11-25 (3 sessions left from 11-23). The latest close is 12-03 (SA, WSM and NTES).

---

## FINDINGS — zero alerts filed, zero queue items

**`ops.alerts`:** none filed. The free checks were clean, and no out-of-scope defect was found. The one open W2-surface row is `15b06460` (`routine_run_warning`, W2 2026-11-15: its `ops.web_calls` timestamps are only batch-approximate). That is W46's own in-run report. It does not recur this cycle, because this run made no metered calls. It is left for its owner's lifecycle, and nothing is re-filed.

**`events.queue_events`:** none. Both free checks were clean (no `rescreen-` item owed), and no thesis-construction enqueue is owed under index mode.

---

## HONEST LIMITS OF THIS RUN

- **None of the 41 is broker-verified.** They are arithmetic-checked only. D2's index rows copy D1's figures, so the precedence rule had nothing to apply.
- **The fixed-horizon series is D2's measurement, published by record read.** W2 re-verified no close against a bar. Every row reproduces from its three printed closes, and the 50 rows are five correlated cohorts.
- **The flip timing is not forecast.** `div-B-202611-3` is attacker-complete. When AR_orc rules, and how, is not W2's to predict.
- **The 11-20 session is uncovered**, and so are the 11-19 after-close reporters. Both belong to D1 tonight.
- **The 11-10..11-13 sessions were screened degraded and late.** W2 cannot see whether anything material sat outside D1's catch-up discovery, and it does not re-screen.
- **The grading series reads the latest queue status per item key.** The outcome taxonomy is D2's. W2 did not open the 456 decision rows, and it neither re-grades nor audits them.

2026-W44

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-11-01 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W44
**Intake watermark:** 2026-10-25T08:25:07Z (this routine's own prior completion, `ops.run_log` `5012065e`) · **Catch-up window:** 6.99 days, the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `d82bab65-bd17-488a-a1d1-274171d62a46` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · one `ops.alerts` info row filed (`dfb0f575`, see FINDINGS).

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).** This is the tenth consecutive index-mode cycle.

**What decides this cycle: every ranked window, and every one of the 183 eligible windows, is open on the 2026-11-02 scheduled router write.** The intake is the second peak week of Q3 earnings season: 183 routable identities, three times W43's 60. Their windows close 2026-11-04 to 2026-11-11. The earliest close (11-04) still leaves three sessions after M1a, M1b and M4 run on 11-02. So if that write activates B, a drain could reach the whole cohort, not just a slice of it, as it could in W43.

**Reachable is still not likely, but the price leg moved.** B's DO-NOT-ACTIVATE comes from the `shock_overlay = acute` override. M1R re-scored blind on 10-28 (run `02ae1886`) and no axis moved; the overlay stayed acute. On the latest stored Brent close (111.57, 2026-10-29) `state.shock_price_leg_status` reads **NOT ELEVATED**, by the plateau-band clause, not by a retrace: the close sits ~10.8 above the view's 100.725 midpoint. That read fires the refresh-only `shock_price_leg_exit` trigger. W2 makes no forecast. Whether 11-02 scores the overlay acute is M1a's blind call, and this file does not pre-empt it.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It pulled no broad bars, enumerated no movers, repeated no event search, and did not re-judge D1's §19 significance verdicts. **It pulled no price bars of any kind**, and `scripts/check_routine_scope.py` enforces that boundary. The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

The run made **zero metered external calls**: no Anthropic `web_search`/`web_fetch`, no Tavily, no FMP, no HF and no IBKR. Index mode skips per-candidate enrichment. Three Sonnet data-assembly sub-agents were confined to BigQuery reads and repo reads.

**One coverage edge is deliberately left open:**
- **The 2026-10-30 (Friday) session is uncovered**, along with the 10-29 after-close reporters that react on 10-30. D1's latest screen covers 10-29. D1's Sunday scan tonight owns 10-30, and PART 1 forbids W2 from covering that gap.
- **W43's open edges are closed.** The 10-23 session and the 10-22 after-close names are in this intake (D1 `290d4251`, written 10-25 22:34Z, after W43's watermark).

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`, reads **`DO-NOT-ACTIVATE`**:
- as_of 2026-10-06;
- `divergence_id` `div-B-202609-1`, theater check MIXED;
- source `events.adversarial_reviews:7db26d06`, event `e503c2d3`.

This row is unchanged since W41. `events.regime_events` holds no B activation row after 10-06, and no B row has ever read ACTIVATE. No router review or divergence review touching B has opened since the watermark. D2's router reviews `db286caf` (10-26), `e6a37e4b` (10-28) and `c13f9996` (10-29, REFRESH-ONLY) wrote no activation. **B's capital:** `state.strategy_capital_enablement` for B reads `capital_disabled = TRUE`.

**Flip paths that could reach this cohort before its windows close (2026-11-04 to 2026-11-11):**
- **Scheduled path: reaches the whole cohort.** M1a, M1b and M4 fire 2026-11-02 (`ops/cadence.yaml`, first trading day; 11-01 is a Sunday). Every one of the 183 windows is open that day, with 3 to 8 sessions left.
- **Out-of-cycle path (Rev 52).** A measured trigger queues a `PENDING_REGIME_REFRESH` item through D2a, and M1R drains it by re-scoring blind.
  - **Since the watermark:** one item, `regime-refresh-20261027`, queued 10-27 and drained 10-28 by M1R's re-score branch. It wrote six `FUNDAMENTAL_AXIS` rows as_of 10-28: growth stable, inflation stable, policy hawkish, risk neutral, **shock_overlay acute**. No axis moved.
  - **The 10-29 NOT-ELEVATED read** fired `shock_price_leg_exit`. D2's router review `c13f9996` treated it as refresh-only. No refresh row for it is visible yet, because D2a has not run since 10-29 (10-30 and 10-31 are outside `daily_sun_thu`).
  - **The price leg's last ten stored sessions (10-16 to 10-29)** read NOT ELEVATED three times (10-16, 10-21, 10-29), each through the plateau-band clause. A new peak printed 10-23 (116.72) and lifted the view's midpoint from 98.95 to 100.725. As W43 noted, the exit trigger is reached by Brent going *quiet*, not only by Brent falling. That is an observation on the view's own outputs, not a forecast.

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE, adopted when W5 resolved `e3263203` on 2026-09-28. The qualifying event date is trading session 1, and the window closes on the 10th trading session inclusive. All 183 window-close dates below match D2's index rows exactly.

Trading days were verified against `state.market_calendar`. There are no holidays or early closes between 10-22 and 11-11.

| Qualifying event date | Window closes | Sessions remaining from 2026-11-02, inclusive | Routable identities |
|---|---|---|---|
| 2026-10-22 | 2026-11-04 | 3 | 11 |
| 2026-10-23 | 2026-11-05 | 4 | 10 |
| 2026-10-26 | 2026-11-06 | 5 | 18 |
| 2026-10-27 | 2026-11-09 | 6 | 35 |
| 2026-10-28 | 2026-11-10 | 7 | 64 |
| 2026-10-29 | 2026-11-11 | 8 | 45 |

How the move is measured:
- For an after-close release, the move is measured on the NEXT session, the reaction session. The ranked table marks it in **bold** where it differs from the qualifying date.
- For an intraday or pre-open release, the move is measured on THAT session.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Six `single-name-move` rows have landed since the watermark. One is superseded, so five are of record. They carry **217** distinct `passed[]` items: 191 clear B's spec floor and 26 are `below_spec_floor = true` write-ups. All 217 carry both recorded closes.

| Decision id | Session screened | `passed[]` items (routed / floor-clearing not routed / below floor) | Note |
|---|---|---|---|
| `290d4251-8c5b-4fba-86f5-dc034c7e4057` | 2026-10-23 (Fri), written by D1's Sunday scan 10-25 | 40 (20 / 0 / 20) | Covers W43's open 10-23 edge and the 10-22 after-close names. D1's close-chain check: 1 hit (FPS, not in this row's passed list). |
| `7d029722-e7f6-476e-9907-423b12af4cd7` | 2026-10-26 (Mon) | 10 (6 / 3 / 1) | D1's close-chain check: the CART 10-26 pair chains from its 10-23 item (see below). |
| `3b0ca8cf-58a6-4193-90d0-355368d80aad` | 2026-10-27 (Tue) | 37 (33 / 2 / 2) | D1's close-chain check: 0 hits. |
| `c8a50e56-d48d-47e4-9b60-7d8fcd7dd4df` | 2026-10-28 (Wed) | 46 (44 / 1 / 1) | **Row of record**, an append-only correction of `72e9607d`. D1's close-chain check: 1 hit (GLXY). |
| `b1e61b9c-b2e0-47b9-9489-ddf0babebd5d` | 2026-10-29 (Thu) | 84 (81 / 1 / 2) | Items carry no event-type field; timing comes from `reason` (mostly "Own 8-K 2.02"). D1's close-chain check: 0 hits. |

- **Supersession, applied by the `bigquery/122`/`144` convention.** `c8a50e56` carries `superseded_by = 72e9607d`; the correction row names the obsolete target. The two rows' `passed[]`, `rejected_notable`, `close_chain_check` and `body_md` are byte-identical. They differ only in `correction_note`, one `fanout_reconciliation` date (NOV's screen leg, 10-27 → 10-28) and one added `rejected_legend` code. **No W2 figure changes.** Every 10-28 item cites `c8a50e56`.
- **Not intake:** five `sector-move` rows in the window (`67d505a8`, `cb06c3e0`, `56a602d2`, `1363808c`, `014b69e9`).
- **No B-relevant D1 candidate or action records since the watermark.** There is no `strategy = 'B'` decision row of any type.
- **GOOG is folded into GOOGL.** D1 routed both share classes on the same 10-28 after-close Alphabet print (−12.29% and −12.64%). D1's Daily.md and D2's index treat them as one issuer and one event ("GOOG is indexed under GOOGL"). W2 counts one identity, so there are **183** rankable identities, not 184.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

- **Queue rows:** `events.queue_events` holds **zero** `thesis-construction` + strategy B rows since 2026-08-03, open or terminal. The intake names that have any earlier B queue row (ORCL, LII, VRT, PNR, VZ, MGM) carry them on older, distinct event dates. Those payloads store no `qualifying_event_date`, so the date was read from the key suffix as the best field evidence available; no collision results either way.
- **Decision rows:** no B thesis or B decision row exists for any intake identity. HWM and LLY carry Strategy D NO-GOs (2026-10-07). Those are D records, context only under the shared "NO-GO records are context, not barriers" rule, and they do not exclude a B identity.
- **Open Strategy A positions:** none. `state.current_positions` holds Strategy D only (AMZN, GOOGL, GEV, DIS, ISRG, RTX, UBER, TSM). GOOGL is held in D. The B same-name exclusion is against A, so it does not apply.
- **Expired windows:** none. The earliest close is 11-04.

**Identities EXCLUDED before enrichment: 0.**

## RECORDED-FIGURE ARITHMETIC CHECK — 217 of 217 items, zero mismatches

For every item, `metric_pct` equals `(event_close / prior_close − 1) × 100` to the recorded 4-decimal precision; the maximum difference is 0.0000. No `rescreen-` item is owed.

## CROSS-ROW CLOSE-CHAIN CHECK — 1 same-anchor hit, 0 defects

The search covered every `single-name-move` row since 2026-10-12 (superseded `72e9607d` excluded), both `passed` and `rejected_notable`, on the same name, testing `other.event_close == this.prior_close` or `other.prior_close == this.event_close`.

- **Passed against passed, same name and same `qualifying_event_date`: 0 hits.**
- **CART (qed 2026-10-23): the one same-anchor hit.** The ranked-eligible item measures 51.68 → 56.44 (+9.2105%) on 10-23, the anchor session of an intraday 10-23 media report. Its 56.44 is the `prior_close` of a 10-26 leg (56.44 → 60.88) that `7d029722` rejected as a continuation. The chain runs FORWARD from the anchor to a rejected leg. The item W2 carries is the anchor-session figure, so this is the reverse of the IONQ `6e179f3c` defect pattern, not an instance of it.
- **Widened to any date, informational only:** GLXY (pre-open 10-27 anchor; the 10-28 leg was rejected, matching D1's own hit), TENB and ADT (different anchors, neither routed) and CRS (below floor, context only).

**This is a record read, not a re-measurement, and a clean pass is not a clearance.** Coverage depends on rejected items carrying closes, and most `rejected_notable` items do not.

## MEASUREMENT OF RECORD — D1's figures, because D2 re-measured none of them

The D2-REMEASURED FIGURE PRECEDENCE rule was applied and **changes nothing this cycle.** All 183 identities have a D2 index row in `Watchlist.md`'s "Strategy B new-entry candidates". Every index row added 10-22 to 10-29 states that its figures are D1's and were **not re-measured on IBKR in this pass**. D1 and D2 agree on figure, `qualifying_event_date` and window close for every identity. No D1 `superseded` correction touches a single-name figure. The rank key is the D1 figure, which is arithmetic-consistent but has not been independently broker-verified at the index-row stage. Broker re-measurement belongs to D2 at Strategy-B thesis construction (D2 STEP 1), which index mode never reaches.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor — 183 identities, 15 ranked at the cap

Ranks 1–5 carry tier `top-5`, and ranks 6–15 carry `rest`. There is no tie at the cap: rank 15 RHI is 21.7357, and rank 16 FFIV is −20.4262.

| Rank | Tier (e) | Ticker (a) | `qualifying_event_date` (f) | Move % (c) | Measured on | Window close (d) | Sessions left from 11-02 | Originating D1 id (g) | Event (one line, factual) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `top-5` | SGRY | 2026-10-26 | +47.6190 | 10-26 | 2026-11-06 | 5 | `7d029722` | All-cash $23.50 take-private (Bain affiliates roll over), pre-open 8-K 1.01; closed ~1% under the offer. Deal-pinned (see S2). |
| 2 | `top-5` | IOVA | 2026-10-29 | -35.4490 | 10-29 | 2026-11-11 | 8 | `b1e61b9c` | Clinical trial update (Phase 2 lung data in line), pre-open PR; prior_qualifying_sessions 2. |
| 3 | `top-5` | GKOS | 2026-10-28 | +33.6493 | **10-29** | 2026-11-10 | 7 | `b1e61b9c` | Own 8-K 2.02 earnings, AC 10-28 16:10 ET. |
| 4 | `top-5` | AXGN | 2026-10-28 | +31.4736 | 10-28 | 2026-11-10 | 7 | `c8a50e56` | Q3 earnings 8-K 2.02, pre-open 07:04 ET; $2.2B cap. |
| 5 | `top-5` | BHC | 2026-10-28 | +28.7572 | **10-29** | 2026-11-10 | 7 | `b1e61b9c` | Own 8-K 2.02 earnings, AC 10-28 16:07 ET; $2.59B cap. |
| 6 | `rest` | GMAB | 2026-10-28 | +28.2516 | 10-28 | 2026-11-10 | 7 | `c8a50e56` | Clinical trial 6-K, 09:43 ET 10-28 (distinct from GMAB 10-23 identity). |
| 7 | `rest` | PRCH | 2026-10-28 | +28.1595 | **10-29** | 2026-11-10 | 7 | `b1e61b9c` | Own 8-K 2.02 earnings, AC 10-28 16:09 ET; $2.15B cap. |
| 8 | `rest` | NOW | 2026-10-28 | -26.9500 | **10-29** | 2026-11-10 | 7 | `b1e61b9c` | Own 8-K 2.02 earnings, AC 10-28 16:14 ET. |
| 9 | `rest` | CROX | 2026-10-29 | +25.5410 | 10-29 | 2026-11-11 | 8 | `b1e61b9c` | Own 8-K 2.02 earnings, pre-open 07:02 ET. |
| 10 | `rest` | ALNY | 2026-10-29 | -25.1291 | 10-29 | 2026-11-11 | 8 | `b1e61b9c` | Own 8-K 2.02 earnings, pre-open 08:16 ET. |
| 11 | `rest` | HRI | 2026-10-27 | +22.7562 | 10-27 | 2026-11-09 | 6 | `3b0ca8cf` | Q3 earnings 8-K 2.02, pre-open 06:31 ET. |
| 12 | `rest` | SFM | 2026-10-28 | -22.5806 | **10-29** | 2026-11-10 | 7 | `b1e61b9c` | Own 8-K 2.02 earnings, AC 10-28 16:04 ET. |
| 13 | `rest` | LKQ | 2026-10-23 | -22.4744 | 10-23 | 2026-11-05 | 4 | `290d4251` | Prelim Q3 + CEO change + FY26 guidance withdrawn, pre-open 08:06 ET. |
| 14 | `rest` | KNSA | 2026-10-27 | +22.2253 | 10-27 | 2026-11-09 | 6 | `3b0ca8cf` | Q3 earnings 8-K 2.02, pre-open 07:32 ET. |
| 15 | `rest` | RHI | 2026-10-22 | +21.7357 | **10-23** | 2026-11-04 | 3 | `290d4251` | Q3 earnings, AC 10-22; reaction session 10-23. |

### BELOW THE CAP — 168 eligible identities (`below-cap`, not ranked)

The `#` column is position by absolute move, given for reference only. These are not ranks.

| # | Tier | Ticker | `qualifying_event_date` | Move % | Window close | Sessions left from 11-02 | D1 id |
|---|---|---|---|---|---|---|---|
| 16 | `below-cap` | FFIV | 2026-10-27 | -20.4262 | 2026-11-09 | 6 | `c8a50e56` |
| 17 | `below-cap` | FTNT | 2026-10-28 | -20.0942 | 2026-11-10 | 7 | `b1e61b9c` |
| 18 | `below-cap` | LSTR | 2026-10-27 | -17.7628 | 2026-11-09 | 6 | `c8a50e56` |
| 19 | `below-cap` | RRC | 2026-10-26 | +17.6626 | 2026-11-06 | 5 | `7d029722` |
| 20 | `below-cap` | FTAI | 2026-10-29 | +17.2729 | 2026-11-11 | 8 | `b1e61b9c` |
| 21 | `below-cap` | ICLR | 2026-10-27 | +17.0401 | 2026-11-09 | 6 | `c8a50e56` |
| 22 | `below-cap` | CTOS | 2026-10-26 | +16.6482 | 2026-11-06 | 5 | `3b0ca8cf` |
| 23 | `below-cap` | VRT | 2026-10-28 | +16.4845 | 2026-11-10 | 7 | `c8a50e56` |
| 24 | `below-cap` | TNGX | 2026-10-23 | -16.4339 | 2026-11-05 | 4 | `290d4251` |
| 25 | `below-cap` | ENPH | 2026-10-27 | -16.0282 | 2026-11-09 | 6 | `c8a50e56` |
| 26 | `below-cap` | GEN | 2026-10-28 | +15.8111 | 2026-11-10 | 7 | `b1e61b9c` |
| 27 | `below-cap` | BLCO | 2026-10-28 | +15.7775 | 2026-11-10 | 7 | `c8a50e56` |
| 28 | `below-cap` | CVNA | 2026-10-28 | +15.6816 | 2026-11-10 | 7 | `b1e61b9c` |
| 29 | `below-cap` | LPLA | 2026-10-27 | -15.2318 | 2026-11-09 | 6 | `c8a50e56` |
| 30 | `below-cap` | BOOT | 2026-10-28 | +15.1633 | 2026-11-10 | 7 | `b1e61b9c` |
| 31 | `below-cap` | INSM | 2026-10-29 | +15.0650 | 2026-11-11 | 8 | `b1e61b9c` |
| 32 | `below-cap` | SLS | 2026-10-28 | -14.7083 | 2026-11-10 | 7 | `c8a50e56` |
| 33 | `below-cap` | PRLB | 2026-10-29 | -14.5969 | 2026-11-11 | 8 | `b1e61b9c` |
| 34 | `below-cap` | HLN | 2026-10-29 | -14.3000 | 2026-11-11 | 8 | `b1e61b9c` |
| 35 | `below-cap` | FCN | 2026-10-29 | +14.2821 | 2026-11-11 | 8 | `b1e61b9c` |
| 36 | `below-cap` | XYL | 2026-10-27 | -14.2092 | 2026-11-09 | 6 | `3b0ca8cf` |
| 37 | `below-cap` | CSGP | 2026-10-27 | -13.9644 | 2026-11-09 | 6 | `c8a50e56` |
| 38 | `below-cap` | HWKN | 2026-10-26 | +13.5927 | 2026-11-06 | 5 | `3b0ca8cf` |
| 39 | `below-cap` | HAYW | 2026-10-28 | +13.5073 | 2026-11-10 | 7 | `c8a50e56` |
| 40 | `below-cap` | AUR | 2026-10-28 | -13.4578 | 2026-11-10 | 7 | `b1e61b9c` |
| 41 | `below-cap` | NCLH | 2026-10-29 | +13.4496 | 2026-11-11 | 8 | `b1e61b9c` |
| 42 | `below-cap` | SOFI | 2026-10-27 | +13.4163 | 2026-11-09 | 6 | `3b0ca8cf` |
| 43 | `below-cap` | HII | 2026-10-29 | +13.2314 | 2026-11-11 | 8 | `b1e61b9c` |
| 44 | `below-cap` | STLA | 2026-10-28 | +13.0435 | 2026-11-10 | 7 | `c8a50e56` |
| 45 | `below-cap` | DBD | 2026-10-28 | -12.9124 | 2026-11-10 | 7 | `c8a50e56` |
| 46 | `below-cap` | BLDR | 2026-10-29 | +12.8490 | 2026-11-11 | 8 | `b1e61b9c` |
| 47 | `below-cap` | PNR | 2026-10-27 | +12.8033 | 2026-11-09 | 6 | `3b0ca8cf` |
| 48 | `below-cap` | ABG | 2026-10-27 | +12.7370 | 2026-11-09 | 6 | `3b0ca8cf` |
| 49 | `below-cap` | ORKA | 2026-10-26 | +12.7012 | 2026-11-06 | 5 | `7d029722` |
| 50 | `below-cap` | STGW | 2026-10-29 | +12.6840 | 2026-11-11 | 8 | `b1e61b9c` |
| 51 | `below-cap` | GOOGL | 2026-10-28 | -12.6412 | 2026-11-10 | 7 | `b1e61b9c` |
| 52 | `below-cap` | EVR | 2026-10-28 | +12.5144 | 2026-11-10 | 7 | `c8a50e56` |
| 53 | `below-cap` | OSW | 2026-10-28 | +12.5050 | 2026-11-10 | 7 | `c8a50e56` |
| 54 | `below-cap` | EAT | 2026-10-28 | +12.2102 | 2026-11-10 | 7 | `c8a50e56` |
| 55 | `below-cap` | WING | 2026-10-28 | +12.1843 | 2026-11-10 | 7 | `c8a50e56` |
| 56 | `below-cap` | CLS | 2026-10-26 | +12.1184 | 2026-11-06 | 5 | `3b0ca8cf` |
| 57 | `below-cap` | LOGI | 2026-10-27 | -12.1177 | 2026-11-09 | 6 | `c8a50e56` |
| 58 | `below-cap` | FLS | 2026-10-28 | +11.8925 | 2026-11-10 | 7 | `b1e61b9c` |
| 59 | `below-cap` | TXT | 2026-10-29 | +11.6701 | 2026-11-11 | 8 | `b1e61b9c` |
| 60 | `below-cap` | DRS | 2026-10-29 | +11.6620 | 2026-11-11 | 8 | `b1e61b9c` |
| 61 | `below-cap` | FORM | 2026-10-28 | -11.6490 | 2026-11-10 | 7 | `b1e61b9c` |
| 62 | `below-cap` | FLEX | 2026-10-28 | +11.6137 | 2026-11-10 | 7 | `c8a50e56` |
| 63 | `below-cap` | ZWS | 2026-10-27 | -11.4954 | 2026-11-09 | 6 | `c8a50e56` |
| 64 | `below-cap` | CHDN | 2026-10-28 | +11.2386 | 2026-11-10 | 7 | `b1e61b9c` |
| 65 | `below-cap` | BE | 2026-10-22 | -11.2366 | 2026-11-04 | 3 | `290d4251` |
| 66 | `below-cap` | JLL | 2026-10-28 | +11.1393 | 2026-11-10 | 7 | `c8a50e56` |
| 67 | `below-cap` | CHRW | 2026-10-28 | -11.1359 | 2026-11-10 | 7 | `c8a50e56` |
| 68 | `below-cap` | SLM | 2026-10-22 | -10.7996 | 2026-11-04 | 3 | `290d4251` |
| 69 | `below-cap` | TRN | 2026-10-29 | +10.7981 | 2026-11-11 | 8 | `b1e61b9c` |
| 70 | `below-cap` | ORCL | 2026-10-28 | +10.7332 | 2026-11-10 | 7 | `c8a50e56` |
| 71 | `below-cap` | BA | 2026-10-27 | -10.6898 | 2026-11-09 | 6 | `3b0ca8cf` |
| 72 | `below-cap` | PPTA | 2026-10-26 | +10.6627 | 2026-11-06 | 5 | `3b0ca8cf` |
| 73 | `below-cap` | LII | 2026-10-28 | -10.5927 | 2026-11-10 | 7 | `c8a50e56` |
| 74 | `below-cap` | FTRE | 2026-10-29 | -10.5873 | 2026-11-11 | 8 | `b1e61b9c` |
| 75 | `below-cap` | AXTI | 2026-10-28 | +10.5616 | 2026-11-10 | 7 | `c8a50e56` |
| 76 | `below-cap` | RSI | 2026-10-28 | -9.9802 | 2026-11-10 | 7 | `b1e61b9c` |
| 77 | `below-cap` | PLXS | 2026-10-28 | -9.6181 | 2026-11-10 | 7 | `b1e61b9c` |
| 78 | `below-cap` | HONA | 2026-10-28 | -9.5972 | 2026-11-10 | 7 | `b1e61b9c` |
| 79 | `below-cap` | GLXY | 2026-10-27 | +9.5663 | 2026-11-09 | 6 | `3b0ca8cf` |
| 80 | `below-cap` | TNET | 2026-10-29 | -9.5299 | 2026-11-11 | 8 | `b1e61b9c` |
| 81 | `below-cap` | GMAB | 2026-10-23 | +9.4750 | 2026-11-05 | 4 | `290d4251` |
| 82 | `below-cap` | FLG | 2026-10-23 | -9.2657 | 2026-11-05 | 4 | `290d4251` |
| 83 | `below-cap` | FIX | 2026-10-22 | -9.2632 | 2026-11-04 | 3 | `290d4251` |
| 84 | `below-cap` | CAT | 2026-10-29 | -9.2503 | 2026-11-11 | 8 | `b1e61b9c` |
| 85 | `below-cap` | CART | 2026-10-23 | +9.2105 | 2026-11-05 | 4 | `290d4251` |
| 86 | `below-cap` | MBLY | 2026-10-29 | -9.2068 | 2026-11-11 | 8 | `b1e61b9c` |
| 87 | `below-cap` | LECO | 2026-10-27 | +9.1707 | 2026-11-09 | 6 | `3b0ca8cf` |
| 88 | `below-cap` | ASST | 2026-10-26 | -9.1474 | 2026-11-06 | 5 | `7d029722` |
| 89 | `below-cap` | CCI | 2026-10-22 | +9.0575 | 2026-11-04 | 3 | `290d4251` |
| 90 | `below-cap` | GVA | 2026-10-29 | +8.9729 | 2026-11-11 | 8 | `b1e61b9c` |
| 91 | `below-cap` | APG | 2026-10-29 | +8.9018 | 2026-11-11 | 8 | `b1e61b9c` |
| 92 | `below-cap` | CMG | 2026-10-28 | +8.8757 | 2026-11-10 | 7 | `b1e61b9c` |
| 93 | `below-cap` | LH | 2026-10-28 | +8.7810 | 2026-11-10 | 7 | `c8a50e56` |
| 94 | `below-cap` | SCI | 2026-10-28 | -8.6967 | 2026-11-10 | 7 | `b1e61b9c` |
| 95 | `below-cap` | MIR | 2026-10-27 | +8.6957 | 2026-11-09 | 6 | `c8a50e56` |
| 96 | `below-cap` | ENSG | 2026-10-27 | +8.6195 | 2026-11-09 | 6 | `c8a50e56` |
| 97 | `below-cap` | UCTT | 2026-10-27 | +8.5470 | 2026-11-09 | 6 | `c8a50e56` |
| 98 | `below-cap` | AMKR | 2026-10-26 | +8.5031 | 2026-11-06 | 5 | `3b0ca8cf` |
| 99 | `below-cap` | AIT | 2026-10-27 | -8.3467 | 2026-11-09 | 6 | `3b0ca8cf` |
| 100 | `below-cap` | RUSHA | 2026-10-27 | -8.3113 | 2026-11-09 | 6 | `c8a50e56` |
| 101 | `below-cap` | RITM | 2026-10-23 | +8.1797 | 2026-11-05 | 4 | `290d4251` |
| 102 | `below-cap` | FCNCA | 2026-10-23 | +8.1520 | 2026-11-05 | 4 | `290d4251` |
| 103 | `below-cap` | GWRE | 2026-10-27 | -8.0507 | 2026-11-09 | 6 | `3b0ca8cf` |
| 104 | `below-cap` | NEU | 2026-10-28 | -8.0388 | 2026-11-10 | 7 | `b1e61b9c` |
| 105 | `below-cap` | BC | 2026-10-29 | +8.0029 | 2026-11-11 | 8 | `b1e61b9c` |
| 106 | `below-cap` | ITRI | 2026-10-27 | +7.7739 | 2026-11-09 | 6 | `3b0ca8cf` |
| 107 | `below-cap` | EEFT | 2026-10-27 | -7.7248 | 2026-11-09 | 6 | `3b0ca8cf` |
| 108 | `below-cap` | EHC | 2026-10-28 | +7.6992 | 2026-11-10 | 7 | `b1e61b9c` |
| 109 | `below-cap` | BAX | 2026-10-29 | -7.6984 | 2026-11-11 | 8 | `b1e61b9c` |
| 110 | `below-cap` | OWL | 2026-10-29 | +7.6525 | 2026-11-11 | 8 | `b1e61b9c` |
| 111 | `below-cap` | CSL | 2026-10-28 | +7.5751 | 2026-11-10 | 7 | `b1e61b9c` |
| 112 | `below-cap` | TPG | 2026-10-29 | +7.5129 | 2026-11-11 | 8 | `b1e61b9c` |
| 113 | `below-cap` | TEX | 2026-10-28 | +7.4275 | 2026-11-10 | 7 | `c8a50e56` |
| 114 | `below-cap` | CUBI | 2026-10-22 | +7.3797 | 2026-11-04 | 3 | `290d4251` |
| 115 | `below-cap` | BKR | 2026-10-27 | -7.3559 | 2026-11-09 | 6 | `c8a50e56` |
| 116 | `below-cap` | SSNC | 2026-10-22 | -7.3487 | 2026-11-04 | 3 | `290d4251` |
| 117 | `below-cap` | ODFL | 2026-10-28 | -7.3304 | 2026-11-10 | 7 | `c8a50e56` |
| 118 | `below-cap` | STNG | 2026-10-28 | +7.1573 | 2026-11-10 | 7 | `b1e61b9c` |
| 119 | `below-cap` | LNG | 2026-10-29 | +7.1095 | 2026-11-11 | 8 | `b1e61b9c` |
| 120 | `below-cap` | GATX | 2026-10-29 | +6.8692 | 2026-11-11 | 8 | `b1e61b9c` |
| 121 | `below-cap` | LHX | 2026-10-29 | +6.8378 | 2026-11-11 | 8 | `b1e61b9c` |
| 122 | `below-cap` | REXR | 2026-10-22 | +6.6979 | 2026-11-04 | 3 | `290d4251` |
| 123 | `below-cap` | KNSL | 2026-10-22 | -6.6941 | 2026-11-04 | 3 | `290d4251` |
| 124 | `below-cap` | LLY | 2026-10-29 | +6.6289 | 2026-11-11 | 8 | `b1e61b9c` |
| 125 | `below-cap` | ENVA | 2026-10-22 | -6.6241 | 2026-11-04 | 3 | `290d4251` |
| 126 | `below-cap` | GEHC | 2026-10-28 | +6.6235 | 2026-11-10 | 7 | `c8a50e56` |
| 127 | `below-cap` | ALGM | 2026-10-29 | -6.6158 | 2026-11-11 | 8 | `b1e61b9c` |
| 128 | `below-cap` | INFY | 2026-10-23 | -6.5809 | 2026-11-05 | 4 | `290d4251` |
| 129 | `below-cap` | CDNS | 2026-10-26 | +6.4904 | 2026-11-06 | 5 | `3b0ca8cf` |
| 130 | `below-cap` | DAN | 2026-10-28 | -6.3235 | 2026-11-10 | 7 | `c8a50e56` |
| 131 | `below-cap` | TENB | 2026-10-28 | +6.2808 | 2026-11-10 | 7 | `b1e61b9c` |
| 132 | `below-cap` | SAN | 2026-10-28 | -6.2550 | 2026-11-10 | 7 | `c8a50e56` |
| 133 | `below-cap` | FTI | 2026-10-29 | -6.2325 | 2026-11-11 | 8 | `b1e61b9c` |
| 134 | `below-cap` | NOV | 2026-10-27 | -6.2287 | 2026-11-09 | 6 | `c8a50e56` |
| 135 | `below-cap` | BSBR | 2026-10-28 | -6.1983 | 2026-11-10 | 7 | `c8a50e56` |
| 136 | `below-cap` | AGYS | 2026-10-26 | -6.1887 | 2026-11-06 | 5 | `3b0ca8cf` |
| 137 | `below-cap` | OLED | 2026-10-28 | -6.0945 | 2026-11-10 | 7 | `b1e61b9c` |
| 138 | `below-cap` | INTA | 2026-10-27 | -6.0768 | 2026-11-09 | 6 | `c8a50e56` |
| 139 | `below-cap` | EGO | 2026-10-28 | -6.0360 | 2026-11-10 | 7 | `b1e61b9c` |
| 140 | `below-cap` | KGC | 2026-10-28 | -6.0052 | 2026-11-10 | 7 | `b1e61b9c` |
| 141 | `below-cap` | TEM | 2026-10-23 | +5.9552 | 2026-11-05 | 4 | `290d4251` |
| 142 | `below-cap` | VKTX | 2026-10-28 | +5.9148 | 2026-11-10 | 7 | `b1e61b9c` |
| 143 | `below-cap` | ATI | 2026-10-29 | +5.8681 | 2026-11-11 | 8 | `b1e61b9c` |
| 144 | `below-cap` | PHIN | 2026-10-29 | +5.8599 | 2026-11-11 | 8 | `b1e61b9c` |
| 145 | `below-cap` | ARE | 2026-10-26 | -5.8525 | 2026-11-06 | 5 | `3b0ca8cf` |
| 146 | `below-cap` | MBIN | 2026-10-28 | +5.8416 | 2026-11-10 | 7 | `b1e61b9c` |
| 147 | `below-cap` | BSX | 2026-10-28 | -5.8367 | 2026-11-10 | 7 | `c8a50e56` |
| 148 | `below-cap` | WULF | 2026-10-23 | +5.8304 | 2026-11-05 | 4 | `7d029722` |
| 149 | `below-cap` | GRMN | 2026-10-28 | -5.8167 | 2026-11-10 | 7 | `c8a50e56` |
| 150 | `below-cap` | ESLT | 2026-10-26 | +5.7960 | 2026-11-06 | 5 | `7d029722` |
| 151 | `below-cap` | CTSH | 2026-10-29 | -5.7866 | 2026-11-11 | 8 | `b1e61b9c` |
| 152 | `below-cap` | VMC | 2026-10-29 | +5.7774 | 2026-11-11 | 8 | `b1e61b9c` |
| 153 | `below-cap` | WELL | 2026-10-26 | -5.7728 | 2026-11-06 | 5 | `3b0ca8cf` |
| 154 | `below-cap` | AWI | 2026-10-27 | -5.7396 | 2026-11-09 | 6 | `3b0ca8cf` |
| 155 | `below-cap` | MGM | 2026-10-28 | +5.7206 | 2026-11-10 | 7 | `b1e61b9c` |
| 156 | `below-cap` | HSBC | 2026-10-27 | -5.7011 | 2026-11-09 | 6 | `3b0ca8cf` |
| 157 | `below-cap` | SAIA | 2026-10-29 | +5.6836 | 2026-11-11 | 8 | `b1e61b9c` |
| 158 | `below-cap` | JCI | 2026-10-27 | +5.6814 | 2026-11-09 | 6 | `3b0ca8cf` |
| 159 | `below-cap` | NMRK | 2026-10-29 | -5.6385 | 2026-11-11 | 8 | `b1e61b9c` |
| 160 | `below-cap` | PBI | 2026-10-28 | -5.6193 | 2026-11-10 | 7 | `b1e61b9c` |
| 161 | `below-cap` | WCC | 2026-10-29 | +5.6132 | 2026-11-11 | 8 | `b1e61b9c` |
| 162 | `below-cap` | DASH | 2026-10-29 | +5.6110 | 2026-11-11 | 8 | `b1e61b9c` |
| 163 | `below-cap` | AGCO | 2026-10-29 | +5.5599 | 2026-11-11 | 8 | `b1e61b9c` |
| 164 | `below-cap` | GM | 2026-10-27 | +5.5432 | 2026-11-09 | 6 | `3b0ca8cf` |
| 165 | `below-cap` | HWM | 2026-10-29 | +5.5075 | 2026-11-11 | 8 | `b1e61b9c` |
| 166 | `below-cap` | HUBB | 2026-10-27 | -5.4680 | 2026-11-09 | 6 | `3b0ca8cf` |
| 167 | `below-cap` | RCL | 2026-10-27 | +5.4597 | 2026-11-09 | 6 | `3b0ca8cf` |
| 168 | `below-cap` | KLAC | 2026-10-28 | +5.4544 | 2026-11-10 | 7 | `b1e61b9c` |
| 169 | `below-cap` | NE | 2026-10-26 | -5.4173 | 2026-11-06 | 5 | `3b0ca8cf` |
| 170 | `below-cap` | JOE | 2026-10-28 | +5.3868 | 2026-11-10 | 7 | `b1e61b9c` |
| 171 | `below-cap` | ETSY | 2026-10-28 | +5.3502 | 2026-11-10 | 7 | `c8a50e56` |
| 172 | `below-cap` | SSD | 2026-10-26 | +5.3135 | 2026-11-06 | 5 | `3b0ca8cf` |
| 173 | `below-cap` | SIGI | 2026-10-22 | +5.3085 | 2026-11-04 | 3 | `290d4251` |
| 174 | `below-cap` | LKQ | 2026-10-29 | +5.2938 | 2026-11-11 | 8 | `b1e61b9c` |
| 175 | `below-cap` | PII | 2026-10-26 | +5.2765 | 2026-11-06 | 5 | `3b0ca8cf` |
| 176 | `below-cap` | TRU | 2026-10-27 | -5.2751 | 2026-11-09 | 6 | `3b0ca8cf` |
| 177 | `below-cap` | HTO | 2026-10-29 | -5.2265 | 2026-11-11 | 8 | `b1e61b9c` |
| 178 | `below-cap` | NUE | 2026-10-26 | +5.2225 | 2026-11-06 | 5 | `3b0ca8cf` |
| 179 | `below-cap` | SW | 2026-10-28 | -5.1951 | 2026-11-10 | 7 | `c8a50e56` |
| 180 | `below-cap` | MO | 2026-10-29 | +5.1514 | 2026-11-11 | 8 | `b1e61b9c` |
| 181 | `below-cap` | DXPE | 2026-10-28 | +5.1285 | 2026-11-10 | 7 | `b1e61b9c` |
| 182 | `below-cap` | LTH | 2026-10-29 | +5.1229 | 2026-11-11 | 8 | `b1e61b9c` |
| 183 | `below-cap` | EPR | 2026-10-28 | +5.0982 | 2026-11-10 | 7 | `b1e61b9c` |

**The cap decides nothing W2 owns this cycle.** Ranked and below-cap identities share one fate unless the router flips. W4 decides under §C whether to carry the 168 below-cap names into the overflow block. Every window is open on the 11-02 write.

### Not rankable — 7 floor-clearing items D1 did not route

| Ticker | `qualifying_event_date` | Move % | D1 row | D1's stated reason |
|---|---|---|---|---|
| ADT | 2026-10-29 | +33.1984 | `b1e61b9c` | Own take-private agreement 8-K; "deal-pinned take-private, not B-routable" (see S2 and FINDINGS) |
| INOD | 2026-10-27 | −25.3213 | `3b0ca8cf` | Unconfirmed layoff reports; release minute UNRESOLVED |
| FICO | UNRESOLVED | −13.1533 | `7d029722` | Anchor UNRESOLVED (announcement minute not established) |
| EDU | 2026-10-28 | −12.5366 | `c8a50e56` | ADS of a foreign-domiciled issuer at ~$9.0B, below Rev 49's $10B threshold |
| UNF | 2026-10-27 | −10.4563 | `3b0ca8cf` | Merger spread blew out on reported FTC intent; minute UNRESOLVED |
| TENB | 2026-10-26 | +8.1184 | `7d029722` | Analyst price-target raise only, not an issuer event |
| TSLA | 2026-10-26 | +5.2120 | `7d029722` | Single-broker upgrade |

### Context only — below the floor — 26 items

These 26 items have `below_spec_floor = true` and `legacy_rule_pass = false`:
- 20 in `290d4251`: RNG, GNTX, DECK, NEM, GBCI, AXP, KRC, KN, ALV, SAM, COLB, APPF, FHB, WDC, MXL, AMR, CRS, HTH, RCI, BCPC.
- VZ in `7d029722`.
- BRO and CTAS in `3b0ca8cf`.
- ROG in `c8a50e56`.
- SIRI and MUSA in `b1e61b9c`.

SIRI and MUSA also carry `b_eligible = true`. That is harmless, because the floor governs.

### Identities EXCLUDED before enrichment — 0

## Rev 49 instrument eligibility — applied by D1 on every row

Rev 49 (2026-10-13) makes US-primary-listed common shares eligible regardless of where the issuer is incorporated. ADRs/ADSs of foreign-domiciled issuers need ≥$10B market cap. Every instrument needs ≥$2B market cap and ≥$10M 30-day ADV.
- D1 declined EDU on the ADS threshold.
- Every foreign-domiciled issuer D1 routed is D1's eligibility call, and W2 does not re-judge it.

## Criterion 5 binds nothing this cycle

No Strategy A position is open, so B criterion 5 excludes no name.

---

## POST-EVENT TRAJECTORY — re-sourced from D2's `CLOSED-WINDOW COHORT NOTE` series

**Definition.**
- **Source of record:** D2's `CLOSED-WINDOW COHORT NOTE` series in `Watchlist.md`'s "Strategy B new-entry candidates" section. This cycle reads the five notes dated 10-25, 10-26, 10-27, 10-28 and 10-29, all on or after W2's previous completed run date. No D2 note is dated after 10-29.
- **Dedupe:** on ticker + `qualifying_event_date`, against the 107 annotations W43 published. That leaves **43 new rows, with 0 overlaps and 0 internal duplicates.**
- **`gap_intact_pct`** follows the 2026-W38 definition: (window-close close − pre-event close) ÷ (event-session close − pre-event close) × 100.
- **Basis:** every row prints all three closes, so every row is **`basis: closes`**. The `m_d` value is shown as a cross-check only; it agrees within 0.12 points.
- **Measured:** all 43, so none is UNMEASURED.

**This is a FIXED-HORIZON series.** It has one observation per identity, taken at that identity's own window close. **It is not a continuation of, and must not be spliced onto, the retired 2026-W29..W38 COMMON-DATE cross-section.** The within-name panel that ended 2026-09-18 is cited by reference (2026-W39 findings) and is not re-published.

### Aggregate, offered only beside the per-ticker rows that follow

- **n = 43**, all measured.
- **Median `gap_intact_pct` = 83.78** (mean 77.22; quartiles 24.69 / 83.78 / 128.99).
- **16 of 43 (37.2%)** are at or above 100: the gap held or extended.
- **9 of 43 (20.9%)** are below 0: the price round-tripped through the pre-event close.
- **18 of 43 (41.9%)** partially retraced (0 to 100).
- **Drift sign against the event move:** 16 continued, 27 reversed.
- **Collapsing D2's shared-catalyst groups** (SpaceX/Grain spectrum deal, 7 rows to 1; Barclays storage downgrade, 3 rows to 1) leaves **35 independent observations, median 85.59.**
- **Comparison:** W43's 106 measured rows had a median of 98.68, so this October-event vintage reads lower. That is suggestive only, because n is small. Where |m| is small the ratio is extreme (MRVL −216.75, AMAT +330.25), which is why the per-ticker row is the unit.

### Per-ticker series (43 new annotations, in D2 note order)

| # | Ticker | Qualifying event (reaction session) | Window close | Pre-event close | Event-session close | Window-close close | m (event session) | d (post-window drift) | gap_intact_pct | Basis | m_d cross-check | D2 grouping | D2 note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MELI | 2026-10-04 (react 10-05) | 2026-10-16 | 1696.56 | 1860.61 | 1834.0 | +9.67% | -1.4302% | 83.78 | closes | 83.78 | independent | 2026-10-25 |
| 2 | CEG | 2026-10-06 | 2026-10-19 | 267.62 | 300.4 | 263.19 | +12.25% | -12.3868% | -13.51 | closes | -13.50 | independent | 2026-10-25 |
| 3 | MRVL | 2026-10-06 | 2026-10-19 | 271.25 | 287.01 | 237.09 | +5.81% | -17.3931% | -216.75 | closes | -216.76 | independent | 2026-10-25 |
| 4 | OPCH | 2026-10-06 | 2026-10-19 | 23.37 | 31.0 | 31.21 | +32.65% | +0.6774% | 102.75 | closes | 102.75 | independent (cash-pinned take-private) | 2026-10-25 |
| 5 | PENG | 2026-10-06 (react 10-07) | 2026-10-19 | 64.21 | 72.61 | 56.54 | +13.08% | -22.1319% | -91.31 | closes | -91.34 | independent | 2026-10-25 |
| 6 | HESM | 2026-10-07 | 2026-10-20 | 38.69 | 33.03 | 30.67 | -14.63% | -7.1450% | 141.70 | closes | 141.69 | independent | 2026-10-25 |
| 7 | HAE | 2026-10-08 | 2026-10-21 | 101.71 | 119.47 | 117.11 | +17.46% | -1.9754% | 86.71 | closes | 86.71 | independent | 2026-10-25 |
| 8 | CMG | 2026-10-08 | 2026-10-21 | 30.77 | 32.68 | 28.12 | +6.21% | -13.9535% | -138.74 | closes | -138.65 | independent | 2026-10-25 |
| 9 | TMUS | 2026-10-08 (react 10-09) | 2026-10-21 | 171.31 | 148.58 | 153.75 | -13.27% | +3.4796% | 77.25 | closes | 77.26 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-25 |
| 10 | T | 2026-10-08 (react 10-09) | 2026-10-21 | 24.87 | 22.18 | 21.91 | -10.82% | -1.2173% | 110.04 | closes | 110.03 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-25 |
| 11 | VZ | 2026-10-08 (react 10-09) | 2026-10-21 | 46.35 | 41.65 | 43.56 | -10.14% | +4.5858% | 59.36 | closes | 59.36 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-26 |
| 12 | CCI | 2026-10-08 (react 10-09) | 2026-10-21 | 68.89 | 79.64 | 78.65 | +15.60% | -1.2431% | 90.79 | closes | 90.79 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-26 |
| 13 | AMT | 2026-10-08 (react 10-09) | 2026-10-21 | 166.73 | 182.24 | 177.64 | +9.30% | -2.5241% | 70.34 | closes | 70.34 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-26 |
| 14 | SBAC | 2026-10-08 (react 10-09) | 2026-10-21 | 170.01 | 182.49 | 173.41 | +7.34% | -4.9756% | 27.24 | closes | 27.24 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-26 |
| 15 | ASTS | 2026-10-08 (react 10-09) | 2026-10-21 | 56.93 | 50.965 | 40.9 | -10.48% | -19.7488% | 268.73 | closes | 268.69 | shared: SpaceX/Grain 800 MHz spectrum deal after-close 2026-10-08 (VZ+CCI+AMT+SBAC+ASTS+TMUS+T) | 2026-10-26 |
| 16 | HUM | 2026-10-08 (react 10-09) | 2026-10-21 | 387.12 | 431.87 | 425.42 | +11.56% | -1.4935% | 85.59 | closes | 85.59 | independent | 2026-10-26 |
| 17 | MRNA | 2026-10-09 | 2026-10-22 | 197.0 | 225.0 | 202.63 | +14.21% | -9.9422% | 20.11 | closes | 20.09 | independent | 2026-10-26 |
| 18 | FSLY | 2026-10-09 | 2026-10-22 | 25.29 | 29.3 | 22.45 | +15.86% | -23.3788% | -70.82 | closes | -70.79 | independent | 2026-10-26 |
| 19 | CCC | 2026-10-09 (react 10-12) | 2026-10-22 | 7.02 | 7.59 | 7.64 | +8.12% | +0.6588% | 108.77 | closes | 108.77 | independent (deal-pinned) | 2026-10-26 |
| 20 | IONQ | 2026-10-12 | 2026-10-23 | 39.89 | 36.27 | 31.27 | -9.07% | -13.7855% | 238.12 | closes | 238.20 | independent | 2026-10-26 |
| 21 | MANH | 2026-10-12 | 2026-10-23 | 204.89 | 217.89 | 238.19 | +6.34% | +9.3166% | 256.15 | closes | 256.27 | independent | 2026-10-27 |
| 22 | JNJ | 2026-10-13 | 2026-10-26 | 263.73 | 248.61 | 266.3 | -5.73% | +7.1156% | -17.00 | closes | -17.07 | independent | 2026-10-27 |
| 23 | C | 2026-10-13 | 2026-10-26 | 131.92 | 124.53 | 121.04 | -5.60% | -2.8025% | 147.23 | closes | 147.24 | independent | 2026-10-27 |
| 24 | AMAT | 2026-10-13 | 2026-10-26 | 497.53 | 464.24 | 387.59 | -6.69% | -16.5109% | 330.25 | closes | 330.29 | independent | 2026-10-27 |
| 25 | CIFR | 2026-10-13 | 2026-10-26 | 13.0 | 11.34 | 7.71 | -12.77% | -32.0106% | 318.67 | closes | 318.66 | independent | 2026-10-27 |
| 26 | FRMI | 2026-10-13 | 2026-10-26 | 3.25 | 3.72 | 2.54 | +14.46% | -31.7204% | -151.06 | closes | -151.09 | independent | 2026-10-27 |
| 27 | LQDA | 2026-10-13 (react 10-14) | 2026-10-26 | 26.81 | 33.94 | 43.74 | +26.59% | +28.8745% | 237.45 | closes | 237.47 | independent | 2026-10-27 |
| 28 | BSP | 2026-10-14 | 2026-10-27 | 37.86 | 53.46 | 46.97 | +41.20% | -12.1399% | 58.40 | closes | 58.39 | independent | 2026-10-27 |
| 29 | DELL | 2026-10-14 | 2026-10-27 | 572.47 | 507.93 | 501.96 | -11.27% | -1.1754% | 109.25 | closes | 109.25 | shared: pre-open 2026-10-14 Barclays downgrade note (NTAP+DELL+HPE) | 2026-10-27 |
| 30 | HPE | 2026-10-14 | 2026-10-27 | 68.81 | 63.11 | 60.84 | -8.28% | -3.5969% | 139.82 | closes | 139.84 | shared: pre-open 2026-10-14 Barclays downgrade note (NTAP+DELL+HPE) | 2026-10-27 |
| 31 | NTAP | 2026-10-14 | 2026-10-27 | 239.01 | 222.2 | 227.58 | -7.03% | +2.4212% | 68.00 | closes | 67.98 | shared: pre-open 2026-10-14 Barclays downgrade note (NTAP+DELL+HPE) | 2026-10-28 |
| 32 | IONQ | 2026-10-14 | 2026-10-27 | 34.73 | 31.42 | 32.95 | -9.53% | +4.8695% | 53.78 | closes | 53.77 | independent | 2026-10-28 |
| 33 | MMED | 2026-10-14 | 2026-10-27 | 18.4 | 16.81 | 18.93 | -8.64% | +12.6115% | -33.33 | closes | -33.35 | independent | 2026-10-28 |
| 34 | RKLB | 2026-10-14 (react 10-15) | 2026-10-27 | 59.18 | 55.25 | 58.31 | -6.64% | +5.5385% | 22.14 | closes | 22.13 | independent | 2026-10-28 |
| 35 | MAN | 2026-10-15 | 2026-10-28 | 51.96 | 43.74 | 45.75 | -15.82% | +4.5953% | 75.55 | closes | 75.55 | independent | 2026-10-28 |
| 36 | PAG | 2026-10-15 | 2026-10-28 | 194.79 | 212.0 | 211.95 | +8.84% | -0.0236% | 99.71 | closes | 99.71 | independent (deal-pinned $212) | 2026-10-28 |
| 37 | INTU | 2026-10-15 | 2026-10-28 | 310.44 | 330.17 | 328.19 | +6.36% | -0.5997% | 89.96 | closes | 89.97 | independent | 2026-10-28 |
| 38 | CROX | 2026-10-15 | 2026-10-28 | 117.54 | 124.77 | 119.69 | +6.15% | -4.0715% | 29.74 | closes | 29.73 | independent | 2026-10-28 |
| 39 | QNT | 2026-10-15 | 2026-10-28 | 33.03 | 36.68 | 38.33 | +11.05% | +4.4984% | 145.21 | closes | 145.21 | independent | 2026-10-28 |
| 40 | ARQT | 2026-10-15 | 2026-10-28 | 26.41 | 29.1 | 31.45 | +10.19% | +8.0756% | 187.36 | closes | 187.33 | independent | 2026-10-28 |
| 41 | CRWV | 2026-10-15 | 2026-10-28 | 65.78 | 69.69 | 63.93 | +5.94% | -8.2652% | -47.31 | closes | -47.41 | independent | 2026-10-29 |
| 42 | NOW | 2026-10-15 | 2026-10-28 | 139.98 | 148.57 | 150.13 | +6.14% | +1.0502% | 118.16 | closes | 118.15 | independent | 2026-10-29 |
| 43 | MSTR | 2026-10-15 (react 10-16) | 2026-10-28 | 151.29 | 136.83 | 145.16 | -9.56% | +6.0878% | 42.39 | closes | 42.41 | independent | 2026-10-29 |

All 43 stated `m` and `d` values were reproduced from the three printed closes by script. D2's stated per-note medians and continuation/reversal splits also reproduce. Two cosmetic items were found: NOW's 10-29 figure is printed as "−26.9%", where the exact value is −26.95%, and ASTS's event close is printed to three decimals. Neither changes a published value.

### Not yet in the series — PENDING D2 ANNOTATION, and the named GAPs

- **PENDING D2 ANNOTATION, copied from D2's most recent note (10-29), not re-derived:** a backlog of **0**, with the next-oldest close date **2026-10-30**. Those five windows (IRON, CLF, MANE, DDOG, ARQT, all qed 10-19 from W43) closed on the 10-30 session, after that note was written. They are PENDING as of this run, not gaps and not zeros. D2's Sunday run tonight is the next opportunity.
- **W43's other 54 identities** close 11-02 (15), 11-03 (17) and 11-04 (22), so they are not yet closed.
- **Named GAPs (intake identity with no index row at all): none new.** All 60 W43 identities and all 183 W44 identities have an index row. GOOG has no row of its own by design (folded into GOOGL). Earlier GAPs are unchanged: EFXT, CRWV 10-14, BULL, SPOT 10-07, ARGX and ECHO.

### Repeat names — intake tickers already in the fixed-horizon series

Two ranked names repeat a W42 identity on a new, distinct event:
- **NOW:** this cycle's qed is 10-28 (−26.95%). Its 10-15 identity (+6.14%) closed with `gap_intact_pct` 118.16; the 10-15 window-close close (150.13) is exactly this event's prior close.
- **CROX:** this cycle's qed is 10-29 (+25.54%). Its 10-15 identity (+6.15%) closed at 29.74.

Two names appear twice inside this intake on distinct events:
- **LKQ:** 10-23 (−22.47%, rank 13) and 10-29 (+5.29%, below-cap).
- **GMAB:** 10-23 (+9.48%) and 10-28 (+28.25%, rank 6).

### What W2 adds from its own durable record: the GRADING OUTCOME series, itemized per ticker

The router was DO-NOT-ACTIVATE throughout, `events.queue_events` holds zero B `thesis-construction` rows (the last is 2026-08-03), and no drain occurred:

| Cohort | Identities | Status on 2026-11-01 |
|---|---|---|
| W43 | 60 | 6 closed and **expired ungraded** (MSTR 10-28; IRON, CLF, MANE, DDOG and ARQT 10-30). 54 still open until 11-02 to 11-04. |
| W42 | 34 | **All expired ungraded.** The last eight closed 10-28. |
| W41 | 20 | All expired ungraded (unchanged). |
| W40 | 22 | All expired ungraded (unchanged). |

**Lineage tally:**
- **82 identities have expired ungraded** (W40 to W42 = 76, plus 6 of W43).
- **54 W43 identities and 183 W44 identities are open.**
- **No published B identity has ever been evaluated against B's entry criteria.**
- **The 11-02 write is the first scheduled write that can reach two consecutive cohorts at once:** W43's 54 open identities and W44's 183.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, record-read only

**S1 — earnings season at full volume, skewed upward.**
- 183 routable identities, against 60 in W43, 34 in W42 and 20 in W41.
- **Direction:** 108 up, 75 down. Within the ranked 15, 10 are up and 5 are down.
- **The 10-29 row alone carries 81 routed items.** Its items are almost all "Own 8-K 2.02" earnings releases, and none carries an event-type field.
- **Non-earnings anchors in the ranked 15:**
  - SGRY's take-private;
  - IOVA's clinical update;
  - GMAB's clinical 6-K;
  - LKQ's preliminary results with a CEO change and withdrawn guidance.

**S2 — a deal-pinned target is at rank 1 for the second cycle running, and D1 routed the same class inconsistently.** SGRY's +47.62% is an all-cash $23.50 take-private, and the stock closed ~1% under the offer. Like W43's BRZE, its post-event path is merger-spread arithmetic, not B's information-versus-sentiment mechanism.
- **This week, D1 split the class:**
  - D1 declined ADT (+33.20%, own take-private 8-K, 10-29) as "deal-pinned take-private, not B-routable".
  - Three days earlier it routed SGRY, and the RRC (+17.66%, all-stock merger target) item beside it.
- **Grep of the plan, Operating_Protocols.md, `strategy/04_strategy_b.md` and `B_Sub_Pattern_Taxonomy.md`:** none of them states a deal-pinned routability rule, so the exclusion is applied without a written basis.
- **Why it matters:** SGRY's routing puts it in W4 §C's top tier.
- **W2's handling:** W2 does not re-judge D1, so SGRY keeps rank 1 and ADT stays unranked. Unlike W41 and W43, this finding is now filed (FINDINGS) because the inconsistency sits inside one week of one routine's output, not across a taxonomy question.

**S3 — shared drivers inside the routable set.** Each ranked name has its own anchor, so the ranked 15 hold **15 distinct qualifying events**. D1 rejected the cohort moves as common drivers: memory, neocloud, Brazil banks, the AI cohort and refiners. Some routed names still share a sector print day. Examples are the 10-28 after-close software prints (NOW −26.95%, FTNT −20.09%) and the 10-29 pre-open aerospace and defense prints (HII, DRS, TXT, LHX). Each is its own issuer's own 8-K, so W2 records the clustering and does not re-judge it.

**S4 — anchor and measurement quality.**
- **Better than W43 on checks:** 217 of 217 items carry both closes, the arithmetic is clean, and there are no same-anchor close-chain defects.
- **Weaker on verification:** no index row was broker re-measured. 6 of the ranked 15 (GKOS, BHC, PRCH, NOW, SFM and RHI) are after-close releases measured on the next session, as the bold cells in the ranked table show.

**S5 — instrument-rail and floor-edge items for D2 at thesis construction, none W2's to settle.**
- **BHC** sits near the $2B cap floor (D1 states $2.59B), and so do **AXGN** ($2.2B) and **PRCH** ($2.15B).
- **SGRY's** cap is stated post-move (~$3.0B; ~$2.06B on the 10-23 close).
- **Near the 5% floor:** the smallest below-cap items (EPR +5.10%, LTH +5.12%, DXPE +5.13%) sit within 0.15 points of it.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).**

The ranked list is the 15-item table in PART 1. It carries the tier field (e) on every row, set strictly by rank (1–5 `top-5`, 6–15 `rest`), plus `qualifying_event_date` (f), event-day move, window close (d), sessions left, originating D1 id (g) and a one-line event (b). The 168 eligible identities below the cap follow it, marked `below-cap`.

Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, fields (a) and (c) read **"not assessed — INDEX MODE"** for every candidate. Fields (b), (d), (e), (f) and (g) are in the tables.

The cohort work is not skipped. The fixed-horizon trajectory series, the structural findings and the grading-outcome series are all given in full above.

## ROUTING

Route the 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. **W4 §C's top tier is the five `top-5` rows: SGRY, IOVA, GKOS, AXGN and BHC.**

- The 168 below-cap names are at W4's discretion.
- **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.**
- **For W4: all 15 ranked windows, and all 183 eligible windows, are open on 2026-11-02.** RHI (closes 11-04) has the fewest sessions left after that write: three.

---

## FINDINGS — one info alert filed, zero queue items, nothing resolved by W2

**`ops.alerts`:** one row filed.
- **`dfb0f575-09b8-47d8-8d95-5cc142865ec8`** (`info`, source W2, `d1_deal_pinned_routing_rule_unwritten_inconsistent`) is a W5 SPEC-DEFECT NOTICE INTAKE item.
  - **OWNER:** D1's single-name-move B-routing, together with `strategy/04_strategy_b.md`. The nearest owning routine is D1.
  - **Defect:** S2. D1 declined ADT as deal-pinned but routed SGRY and RRC, and no written rule exists either way.
  - **What W2 did not do:** it did not re-rank, did not exclude SGRY and did not add ADT.
  - **Before filing:** a check found no open alert on this surface.

**`events.queue_events`:** none. Both free checks were clean, and no thesis-construction enqueue is owed under index mode.

**Carried, not re-filed (open):**
- **`143c2aaf`** (`shock_baseline_window_divergent_between_m1a_and_limb_view`, W2's own, owned by W5). The band has moved again:
  - **The view:** a baseline of 84.73 and the new 116.72 peak (10-23) put its midpoint at 100.725.
  - **M1R's 10-28 scoring:** a baseline of 87.20 and a midpoint of 101.96.
  - **The disagreement band** is therefore 100.725 to 101.96, inverted again from W43's 97.975 to 98.95.
  - **Not live this cycle:** the stored 10-29 close of 111.57 is ~10 above both midpoints.
  - **Unchanged:** the finding itself, one rule with two midpoints.
- **`0a40c378`** (M1R, a blinding side channel via git commit subjects): this run's commit subject carries no regime, router or price substance.

**Resolved since W43 by their owners:** none. No `ops-note` or `routine-outcome` row since the watermark adjudicates a W2 referral.

---

## HONEST LIMITS OF THIS RUN

- **None of the 183 is broker-verified.** They are arithmetic-checked only. D2's index rows copy D1's figures this cycle, so the precedence rule had nothing to apply.
- **The fixed-horizon series is D2's measurement, published by record read.** W2 re-verified no close against a bar. The spot checks matched D2's printed text (MELI, CEG and ASTS), and every row reproduces from its three printed closes.
- **The flip-path read rests on a view's as-of 10-29 inputs.** The 10-30 Brent close is not yet stored. W2 pulled no price, makes no forecast, and does not pre-empt M1a's blind scoring on 11-02.
- **10-30 is uncovered**, and so are the 10-29 after-close reporters. Both are D1's tonight.
- **GOOG/GOOGL are folded into one identity.** This follows D1's and D2's stated treatment. If a later rule treats share classes as separate identities, GOOG (−12.293%, qed 10-28, `b1e61b9c`) would join the below-cap list.

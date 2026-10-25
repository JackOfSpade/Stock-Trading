2026-W43

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-10-25 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W43
**Intake watermark:** 2026-10-18T08:22:58Z (this routine's own prior completion, `ops.run_log` `c56847de`) · **Catch-up window:** 7.0 days, the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `1a5a33bb-9c2a-4dd5-a5cd-4bb0bc220ebd` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · zero new `ops.alerts` rows.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).** This is the ninth consecutive index-mode cycle.

**What decides this cycle: for the first time, the scheduled router write falls inside live windows.** The intake is peak Q3 earnings season: 60 routable identities, nearly double W42's 34. Their windows close 2026-10-28 to 2026-11-04. **54 of the 60 windows, and 13 of the ranked 15, are still open on 2026-11-02**, the day M1a, M1b and M4 run. In all eight earlier index-mode cycles, every window closed before the next scheduled write. That makes this cycle's `Router-gated, not rank-gated.` marker more than bookkeeping. If the 11-02 write activates B, these rows are the ones a drain could reach.

**Reachable is not likely.** B's DO-NOT-ACTIVATE comes from the `shock_overlay = acute` override, not from the raw M1b call. On the latest stored Brent close (113.17, 2026-10-22), the price leg reads ELEVATED, 14.22 above the view's 98.95 midpoint (`state.shock_price_leg_status`). W2 makes no forecast. Whether the 11-02 scoring lands acute is M1a's blind call, and this file does not pre-empt it.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It pulled no broad bars, enumerated no movers, repeated no event search, and did not re-judge D1's §19 significance verdicts. **It pulled no price bars of any kind**, and `scripts/check_routine_scope.py` enforces that boundary. The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

The run made **zero metered external calls**: no Anthropic `web_search`/`web_fetch`, no Tavily, no FMP, no HF and no IBKR. Index mode skips per-candidate enrichment. Three Sonnet data-assembly sub-agents were confined to BigQuery reads and repo reads.

**Two coverage edges are deliberately left open:**
- **The 2026-10-23 (Friday) session is uncovered.** D1's latest screen covers 10-22. D1's Sunday scan tonight owns 10-23, and PART 1 forbids W2 from covering that gap.
- **The 10-22 after-close names are also not yet screened.** D1 `5022f59e` lists them as `after_close_pending`: WDC, NEM, BE, FIX, VRSN, OMC, DECK, KNSL, RNG, MXL, APPF, SSNC, RHI, LULU, BRO and others, all reacting 10-23.
- **The 10-16 session that W42 left uncovered is in this intake** (D1 `b03ff6a6`, written 10-18 22:30Z, after W42's watermark).

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`, reads **`DO-NOT-ACTIVATE`**:
- as_of 2026-10-06;
- `divergence_id` `div-B-202609-1`, theater check MIXED;
- source `events.adversarial_reviews:7db26d06`, event `e503c2d3`.

This row is unchanged since W41. No router review or divergence review touching B has opened since. **B's capital:** `state.strategy_capital_enablement` for B reads `capital_disabled = TRUE`.

**Flip paths that could reach this cohort before its windows close (2026-10-28 to 2026-11-04):**
- **Scheduled path: now reachable, for the first time.** M1a, M1b and M4 fire 2026-11-02 (`ops/cadence.yaml`, first trading day; 11-01 is a Sunday). Windows still open on 11-02:
  - 15 identities close on 11-02 itself;
  - 17 close on 11-03;
  - 22 close on 11-04.

  An activation written that morning leaves one to three sessions of window.
- **Out-of-cycle path: re-wired by Rev 52 (owner directive, 2026-10-22).** The three-leg re-risking limb W42 tracked is **retired**, so "two of three legs" no longer describes anything. Now any ONE measured trigger, in either direction, has two effects:
  - D2a's REFRESH REQUEST queues a `PENDING_REGIME_REFRESH` item;
  - M1R drains that item by re-scoring blind.

  The trigger that bears on B's override is `shock_price_leg_exit`: the price leg reads NOT ELEVATED while the overlay is `acute`. It is refresh-only, with no router review and no activation write of its own.
  - **State since the watermark:** zero `PENDING_REGIME_REFRESH` rows. M1R ran 10-18, 10-19 and 10-22, all on its gate branch with no scoring. There are no `FUNDAMENTAL_AXIS` rows after as_of 2026-10-01.
  - **The price leg's recent record is not one-way.** In the ten stored sessions 10-09 to 10-22, the view read NOT ELEVATED on 10-13, 10-14, 10-15, 10-16 and 10-21. Every one of those came through the **plateau re-base clause** (ten closes inside ±5% of their median), not through a retrace below the midpoint. The 10-22 close of 113.17 broke the band. So the exit trigger is reached by Brent going *quiet*, not only by Brent falling. That is an observation on the view's own outputs, not a forecast.
- **Legacy view still live.** `state.rerisking_limb_status` is still defined and reads leg A TRUE, leg B FALSE and leg C TRUE (SPY NEUTRAL since 10-21, VIX NORMAL, breadth HEALTHY). Rev 52 retired its use, and W2 does not report it as a path.

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE, adopted when W5 resolved `e3263203` on 2026-09-28. The qualifying event date is trading session 1, and the window closes on the 10th trading session inclusive. This is the convention D2's index rows carry, and all 60 window-close dates below match D2's rows exactly.

Trading days were verified against `state.market_calendar`. There are no holidays or early closes between 10-14 and 11-20.

| Qualifying event date | Window closes | Sessions remaining from 2026-10-26, inclusive | Open on the 2026-11-02 scheduled write? | Routable identities |
|---|---|---|---|---|
| 2026-10-15 | 2026-10-28 | 3 | No | 1 (MSTR) |
| 2026-10-19 | 2026-10-30 | 5 | No | 5 |
| 2026-10-20 | 2026-11-02 | 6 | **Yes — its last session** | 15 |
| 2026-10-21 | 2026-11-03 | 7 | **Yes** | 17 |
| 2026-10-22 | 2026-11-04 | 8 | **Yes** | 22 |

How the move is measured:
- For an after-close release, the move is measured on the NEXT session, the reaction session. The tables mark it in **bold** where it differs from the qualifying date.
- For an intraday or pre-open release, the move is measured on THAT session.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five `single-name-move` rows have landed since the watermark, carrying 135 `passed[]` items in total. 80 clear B's spec floor; the other 55 are `below_spec_floor = true` write-ups.

| Decision id | Session screened | `passed[]` items (floor-clearers / below-floor) | Two prices recorded? | Note |
|---|---|---|---|---|
| `b03ff6a6-4230-4d05-9c49-eff2c9378b9f` | 2026-10-16 (Fri) | 1 (1 / 0) | 1 of 1 | MSTR, after-close 10-15, measured on 10-16. D1's close-chain check: 6 hits, all on rejected or carried-forward items (below). |
| `c7045f5f-9300-44cd-8227-b0771dc4ad29` | 2026-10-19 (Mon) | 7 (5 / 2) | 7 of 7 | D1's close-chain check: 0 hits. |
| `ec09d8fc-29d6-42fc-92a8-ce292d0501d5` | 2026-10-20 (Tue) | 15 (12 / 3) | 15 of 15 | Its items carry no release-timing field; timing comes from the item `reason` text. D1's close-chain check: 2 hits (IRON, CLF), both on the session after their measure. |
| `70635acf-db7a-49d4-a63b-a2f429bc3f20` | 2026-10-21 (Wed) | 30 (13 / 17) | 30 of 30 | D1's close-chain check: 3 hits (HAS, MSCI, VICR), all on the session after their measure. |
| `5022f59e-c56e-4864-9dfc-08f805bb5a62` | 2026-10-22 (Thu) | 82 (49 / 33) | 82 of 82 | A **catch-up run**, written 10-23 09:32Z after the 10-22 evening slot was missed (critical `missed_run` `204b983b`). It carries no `close_chain_check` field. |

- **Not intake:** five `sector-move` rows in the window (`c0188030`, `dbd82e7e`, `af249738`, `eb301f2f`, `aa0b6953`).
- **No B-relevant D1 candidate or action records since the watermark.** D1's only other records are five Strategy D `add-candidate-review` rows. There is no `strategy = 'B'` decision row of any type since the watermark.
- **No supersession and no correction.** No row written since the watermark carries `superseded_by`, and no D1 or D2 correction touches a single-name figure. `bigquery/144`'s convention is therefore moot this cycle.
- **No `anchor_session_move_pct` key exists on any intake item.** Where an anchor-session figure matters, it lives only in the item's free-text `reason`. This is a field-shape note, not a defect: neither the W2 section nor §19 mandates that key.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

- **Queue rows:** `events.queue_events` holds **zero** `thesis-construction` + strategy B rows since 2026-09-01, open or terminal. The last of its 84 all-time B rows is dated 2026-08-03.
- **Rescreen items:** no `rescreen-*` item touches an intake ticker for B. `rescreen-META-D-20261105` is Strategy D, and `rescreen-COST-B-20261004` is not an intake ticker.
- **Other strategies' items on intake tickers are not B identities and exclude nothing:** `thesis-EFX-TRU-E-20260903` (E), `thesis-SPOT-D-20261006` and `thesis-GE-D-20261006` (D, both NO-GO router-gated), and `A:AMZN:2026-07-12` (A watchlist).
- **Repeat tickers are distinct events.** MRNA, ARQT, T and SPOT all re-appear on new qualifying dates. Deduping by ticker alone would have wrongly dropped them.

## RECORDED-FIGURE ARITHMETIC CHECK — 135 of 135 items, zero mismatches

Every item carries both `prior_close` and `event_close`. Each `metric_pct` equals `(event_close/prior_close − 1) × 100` to the recorded 4-dp precision. The largest residual is 5×10⁻⁵ pp, which is half a unit at 4 dp: rounding. **No `rescreen-*` item is owed.**

## CROSS-ROW CLOSE-CHAIN CHECK — 0 hits

- **Corpus:** every `single-name-move` row in the durable record, all-time, including superseded rows: 81 rows, 954 `passed[]` items, 336 of them carrying both closes. This item-level corpus is narrower than W42's 1,562, which also counted `rejected_notable` entries. Those carry no closes, so they cannot chain.
- **Test:** for each intake item with a dated `qualifying_event_date`, look for another item with the same name and the same date whose `event_close` equals this item's `prior_close`, or whose `prior_close` equals its `event_close`. **No pair chains.**
- **Looser test, same name and any date: one pair, not a defect.** TSLA's 70635acf item (10-20, 373.71 → 386.47) chains into its 5022f59e item (10-21, 386.47 → 374.58). These are consecutive sessions on two distinct anchors, and both items are below the floor.
- **D1's own self-reported hits do not touch the intake's anchors:**
  - **MSTR:** a legitimate after-close forward chain.
  - **MAN, RKLB, HPE, DELL, CRWV** (`b03ff6a6`): W42 identities carried forward and not re-written as passed.
  - **IRON, CLF, HAS, MSCI, VICR:** the next session's item chained to a pre-open anchor that was already measured on its own session.
- **A clean pass is not a clearance.** The test reaches only items that share a name and date with another item; it measured 32% coverage on 2026-09-27.

## MEASUREMENT OF RECORD — D2's index rows, not W2's pull

`Watchlist.md`'s Strategy B new-entry index has a D2 row (lines 606–665) for **all 60 routable identities**, and every window-close date matches.

- **Re-measured on IBKR RTH closes: 1 of 60.** MSTR, 151.29 → 136.83 = −9.5578%, "D1's figure confirmed exact". For META, D2 read the 697.52 / 648.85 bars and found they match D1's pair.
- **Not re-measured: 59 of 60.** Each row says "Figures are D1's … not re-measured on IBKR in this pass." **All of the ranked 15 are arithmetic-checked only.** This is the weakest broker coverage of any cycle: W42 was 18 of 34. The cause is volume, not a rule gap. D2's re-measurement of record belongs to thesis construction (D2 STEP 1 QUALIFYING-MOVE RE-MEASUREMENT), which index mode never reaches.
- **No D2 figure differs from D1**, so the D2-REMEASURED FIGURE PRECEDENCE rule changes no rank. No D1 `superseded` correction applies either.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor — 60 identities, 15 ranked at the cap

Ranking is by **absolute event-day close-to-close move, descending, and nothing else**. Every figure is D1's; D2 reproduced it where it re-measured (MSTR only). Field (e) is set strictly by rank.

| # | Tier | Ticker | Qualifying event | Move | Measured session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | top-5 | BRZE | 2026-10-20 | +51.6977% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Salesforce definitive all-cash acquisition at $47.50/sh (~58% premium); **deal-pinned target**. |
| 2 | top-5 | IRON | 2026-10-19 | +38.8635% | 10-19 | 2026-10-30 | 5 | `c7045f5f` | Phase 3 APOLLO topline success (bitopertin), pre-open; $350M follow-on priced the same day. |
| 3 | top-5 | TTMI | 2026-10-22 | −27.6652% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 beat plus a proposed acquisition in the release, pre-open; fell with the 10-22 AI-hardware rout; 6 other ≥5% sessions in the window. |
| 4 | top-5 | KALU | 2026-10-21 | −25.3069% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 EPS miss ($1.89 vs ~$2.37), after-close 10-21. |
| 5 | top-5 | FPS | 2026-10-22 | −21.5365% | 10-22 | 2026-11-04 | 8 | `5022f59e` | CFO resignation, pre-market; confounded by the AI-power selloff; 3 other ≥5% sessions. |
| 6 | rest | MRNA | 2026-10-22 | −17.5664% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Partial Phase 3 melanoma data leak, intraday (minute unresolved); 4 other ≥5% sessions. |
| 7 | rest | OII | 2026-10-21 | −16.9426% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 EPS miss ($0.50 vs ~$0.59), after-close 10-21; oilfield-services read-through with LBRT. |
| 8 | rest | CLF | 2026-10-19 | +16.3366% | 10-19 | 2026-10-30 | 5 | `c7045f5f` | Q3 results and 2027 EBITDA outlook, pre-open. |
| 9 | rest | MSM | 2026-10-22 | −15.3516% | 10-22 | 2026-11-04 | 8 | `5022f59e` | FQ4 record sales but margin and GAAP EPS down, soft FQ1 guide, pre-open. |
| 10 | rest | GGG | 2026-10-21 | −15.316% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 adj EPS slight miss, Q4 revenue guide $610-640M, after-close 10-21. |
| 11 | rest | FCFS | 2026-10-22 | −14.7497% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS beat ($2.68 vs ~$2.63); driver of the fall not established. |
| 12 | rest | LION | 2026-10-20 | +14.4068% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Bloomberg report of a revived ~$3.5B Legendary takeover offer (anonymous, unconfirmed). |
| 13 | rest | POOL | 2026-10-22 | +14.3644% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $3.40 vs ~$3.36, pre-open. |
| 14 | rest | ASST | 2026-10-21 | +13.6364% | 10-21 | 2026-11-03 | 7 | `70635acf` | First cash dividends on its 15% SATS perpetual preferred, ~pre-open; crypto-up day; 4 other ≥5% sessions. |
| 15 | rest | BMI | 2026-10-22 | +13.484% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS in line, revenue $230M vs ~$240M, pre-open; driver not established. |

### BELOW THE CAP — 45 eligible identities (`below-cap`, not ranked)

| Ticker | Qualifying event | Move | Measured session | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|---|
| MANE | 2026-10-19 | +12.369% | 10-19 | 2026-10-30 | 5 | `c7045f5f` | Phase 3 Study 304 topline success, pre-open; five other ≥5% sessions in the window. |
| KSS | 2026-10-22 | +11.8231% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Gordon Haskett upgrade on a broad retail bid; analyst action only. |
| LRCX | 2026-10-21 | −11.7557% | **10-22** | 2026-11-03 | 7 | `5022f59e` | FQ1 beat but guide midpoint below consensus, after-close 10-21; set off the semi-equipment rout. |
| EFX | 2026-10-20 | +11.3325% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 beat but FY revenue guide cut (mortgage); follows a 10-15 +7.25% session. |
| HAS | 2026-10-20 | +11.1991% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 beat (adj EPS $2.90 vs $1.86), outlook raised, buyback doubled. |
| SPOT | 2026-10-22 | +11.1014% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 KPIs met or exceeded guidance, pre-open. |
| ALLE | 2026-10-22 | +11.0189% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $2.60 vs ~$2.50, pre-open. |
| ARQT | 2026-10-19 | +10.6523% | 10-19 | 2026-10-30 | 5 | `c7045f5f` | Guggenheim PT raise ($44); aggregator-only sourcing; a distinct event from its 10-15 W42 item. |
| R | 2026-10-22 | +10.4948% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $4.33 vs ~$4.15, pre-open. |
| LAD | 2026-10-21 | −10.1492% | 10-21 | 2026-11-03 | 7 | `70635acf` | Q3, pre-open; driver not established; dealer group down. |
| ROP | 2026-10-22 | +9.7268% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $5.89 vs ~$5.79, FY guide raised, pre-open. |
| MSTR | 2026-10-15 | −9.5578% | **10-16** | 2026-10-28 | 3 | `b03ff6a6` | MSCI finalized non-operating-company exclusion rules, after-close 10-15; measured on the 10-16 reaction session. |
| SMCI | 2026-10-20 | +9.5473% | **10-21** | 2026-11-02 | 6 | `70635acf` | Preliminary FQ1 revenue raised to $18.5-19.5B, after-close 10-20. |
| HXL | 2026-10-21 | −9.5392% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 revenue slight miss, guide unchanged, after-close 10-21; Carpenter read-through. |
| BX | 2026-10-22 | +8.3782% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $1.32 vs ~$1.26, pre-open. |
| FLY | 2026-10-21 | +8.2771% | 10-21 | 2026-11-03 | 7 | `70635acf` | Elytra PDR for NASA MoonFall; rose with space names on SpaceX day; own-event share doubtful. |
| MHO | 2026-10-21 | −8.0767% | 10-21 | 2026-11-03 | 7 | `70635acf` | Q3, pre-open; driver not established; homebuilder weakness. |
| LBRT | 2026-10-21 | −7.849% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 in line, after-close 10-21; oilfield services weak with OII. |
| SPCX | 2026-10-20 | +7.7948% | **10-21** | 2026-11-02 | 6 | `70635acf` | Q3 revenue $14.58B (+161% y/y), after-close 10-20; SpaceX-Tesla merger-committee remarks. |
| WFRD | 2026-10-20 | +7.7514% | **10-21** | 2026-11-02 | 6 | `70635acf` | Q3, after-close 10-20; Irish-domiciled, US-primary-listed, so Rev 49-eligible. |
| NDAQ | 2026-10-22 | +7.4698% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $1.04 vs ~$1.02, pre-open. |
| CURB | 2026-10-22 | +7.2464% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3, pre-open; outran XLRE by ~6pp. |
| ZGN | 2026-10-22 | +7.1981% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 revenue release, pre-open. |
| COCO | 2026-10-22 | −7.0866% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 beat (EPS $0.58 vs ~$0.47) yet fell; driver not established. |
| VICR | 2026-10-20 | +7.0589% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 revenue +78.5% y/y, small EPS miss; five other ≥5% sessions in the window. |
| PAC | 2026-10-20 | +7.0511% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | 3Q26 revenue +21.8% y/y; ADS at $11.3B cap, above the Rev 49 $10B ADR line. |
| META | 2026-10-21 | −6.9776% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 beat (EPS $7.40 vs ~$6.54), higher expense outlook and ~$825B commitments, after-close 10-21. |
| BBT | 2026-10-21 | +6.9643% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 EPS $0.77 vs ~$0.78, buyback to $125M, after-close 10-21. |
| LMT | 2026-10-22 | +6.9627% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $7.97 vs ~$7.52, pre-open. |
| FR | 2026-10-21 | −6.9192% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 with a guide raise yet fell ~8pp below XLRE, after-close 10-21. |
| GM | 2026-10-20 | −6.8399% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 beat with a $20B buyback but GMI EBIT-adj −88% y/y. |
| CSX | 2026-10-21 | +6.7562% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 EPS $0.57 vs ~$0.53, after-close 10-21. |
| T | 2026-10-21 | −6.4475% | 10-21 | 2026-11-03 | 7 | `70635acf` | Q3 beat and raised EPS outlook, fell on promo-cost concern, 06:30 ET; a distinct event from its W42 10-08 item. |
| TSCO | 2026-10-22 | +6.2404% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $0.43 vs ~$0.41, pre-open. |
| VLY | 2026-10-22 | +6.0676% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS $0.36 vs ~$0.33 with two acquisitions, pre-open. |
| DAR | 2026-10-22 | −5.8386% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 8-K 06:51 ET; results not read by D1; driver not established. |
| MMM | 2026-10-20 | +5.7774% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 beat, FY guide raised. |
| BFH | 2026-10-22 | −5.689% | 10-22 | 2026-11-04 | 8 | `5022f59e` | Q3 EPS beat ($3.84 vs ~$3.34) yet fell. |
| LUV | 2026-10-21 | +5.3912% | **10-22** | 2026-11-03 | 7 | `5022f59e` | Q3 EPS $0.66 vs ~$0.57, after-close 10-21; near the floor on an airline-up day. |
| ROIV | 2026-10-21 | +5.3837% | 10-21 | 2026-11-03 | 7 | `70635acf` | Brepocitinib Phase 3 uveitis met endpoints, 07:05 ET. |
| DDOG | 2026-10-19 | +5.362% | 10-19 | 2026-10-30 | 5 | `c7045f5f` | Bernstein upgrade, pre-open; retraced a −7.19% Friday. |
| NFLX | 2026-10-20 | −5.3137% | **10-21** | 2026-11-02 | 6 | `70635acf` | Q3 EPS beat but Q4 guide below consensus and ad forecast cut, after-close 10-20. |
| GPC | 2026-10-20 | −5.116% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 slight miss, FY range top cut. |
| MSCI | 2026-10-20 | +5.0045% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 EPS $5.11 vs $4.98; sits on the 5% floor. |
| UCB | 2026-10-20 | +5.003% | 10-20 | 2026-11-02 | 6 | `ec09d8fc` | Q3 operating EPS distorted by the Navitas sale gain; 5.0030%, on the floor. |

**The cap decides nothing W2 owns this cycle.** Ranked and below-cap identities share one fate unless the router flips. W4 decides under §C whether to carry the 45 below-cap names into the overflow block. With 54 of 60 windows open on 11-02, that choice matters more than it has before.

### Not rankable — 20 floor-clearing items D1 did not route

W2 concurs with each disposition and does not overrule D1.

- **Anchor UNRESOLVED: 7.** AMX (+6.0699%), RCUS (−19.5789%), CRS (−20.6160%), CSQR (−11.8343%), RTO (+8.7452%), SCCO (−7.3105%) and SLG (+5.3770%). **W2 does not date them**, because assigning an anchor would be the second dating screen PART 1 forbids. That is 7 of 80 floor-clearers, against 1 of 36 in W42. Five of the seven come from the 10-22 catch-up row.
- **Instrument-ineligible under Rev 49: 4.**
  - AERO (−6.3562%), TLX (−10.1254%) and VCRE (+11.2069%) are foreign ADSs under the $10B ADR line.
  - FSV (+7.7824%) is TSX/Nasdaq dual-listed, with US-primary status unverified.
- **D1 `declined_common_driver`: 8.** NOK (optical/AI networking), WCN (waste peers), ESI (AI electronics), CATY (regional banks), PHM (homebuilders on the yield drop), PG (staples), ROL and EPRT (REIT rate rally). These are D1's significance judgment that the move was the sector's, not the name's. W2 does not re-judge it.
- **Context only: 1.** WDFC (+9.1504%) has no index row.

### Context only — below the floor

There are 55 `below_spec_floor = true` items, among them AMZN (+4.98%) and ISRG (−2.2557%), both Strategy D holdings, plus 493 `rejected_notable` names. W2 does not re-judge them.

### Identities EXCLUDED before enrichment — 0

None were excluded on dedupe, expired window or criterion 5.

## Rev 49 instrument eligibility — applied correctly by D1 on every row

- **Eligible, and indexed:**
  - PAC: an ADS with a $11.3B cap, above the $10B line.
  - WFRD: Irish-domiciled but US-primary-listed.
- **Not routed:** AERO, TLX, VCRE and FSV, as above.
- **Nothing in the intake uses the pre-Rev 49 "foreign-incorporated, held" language.**

## Criterion 5 binds nothing this cycle

`state.current_positions` holds 12 lots in 8 tickers, all Strategy D: AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM and UBER. There are **zero A positions and zero B positions**, and no routable intake ticker is held.

---

## POST-EVENT TRAJECTORY — re-sourced from D2's `CLOSED-WINDOW COHORT NOTE` series; first publication under the 2026-10-19 rule

**This section replaces W42's "named GAP".** Alert `3218eb3c` (`b_cohort_trajectory_unreachable_under_no_pull_boundary`) and its stall escalation `76cbd8f6` were RESOLVED on 2026-10-19 by an interactive owner session (main `c311b68`), one day after W42 ran. Under that fix:
- the series is a **record read, never a re-pull**;
- W2 pulled no bars to build it, and the no-price-bar boundary is untouched.

This is the first run under the rule, so it takes **every annotation already on file**: thirteen D2 notes from 2026-08-20 through 2026-10-23 (`Watchlist.md` lines 674–718), deduped on ticker + `qualifying_event_date` (no duplicates were found).

**Definition.**
- `d` is D2's post-window drift: window-close close against the event-session close the row measured its move on.
- Basis `closes`: `gap_intact_pct = (window-close close − pre-event close) ÷ (event-session close − pre-event close) × 100`, used wherever all three closes are printed.
- Basis `m_d`: `((1+m)(1+d) − 1) ÷ m × 100`, with `m` and `d` as fractions. It is used where a close is missing: CVS, DVA and SEZL print no pre-event close; DKS, BBWI and RDDT print no window-close close.
- **Reading the number:** 100 means the whole event-session gap is intact at window close; above 100, the move extended; 0 to 100, a partial retrace; below 0, the price round-tripped through the pre-event level.
- **Cross-check:** on all 100 `closes` rows, the two bases agree within 0.13 pp, which is rounding.

**This is a FIXED-HORIZON series.** It has one observation per identity, taken at that identity's own window close. **It is not a continuation of, and must not be spliced onto, the retired 2026-W29..W38 COMMON-DATE cross-section.** The within-name panel that ended 2026-09-18 is cited by reference (2026-W39 findings) and is not re-published.

### Aggregate, offered only beside the per-ticker rows that follow

- **106 measured, 1 UNMEASURED** (BE, a zero-length window).
- **The median reaction held.** The median `gap_intact_pct` is 98.68, with an interquartile range of 56.27 to 141.82.
  - 51 rows extended (above 100);
  - 41 partly retraced (0 to 100);
  - 14 round-tripped (below 0).
  - By the sign of `d` against `m`: 51 continued and 55 reversed.
- **Shared catalysts barely move the result.** Collapsing D2's stated shared-catalyst groups (a mean within each group) leaves **93 independent observations**, with a median of 99.97: 46 extended, 37 retraced, 10 round-tripped.
- **No direction asymmetry.** Up-moves have a median of 99.05 (n = 51) and down-moves 98.31 (n = 55).
- **Vintage drift, which is suggestive and not a finding.** Median by qualifying month: August 86.30 (n = 32), September 102.50 (n = 61), October 106.55 (n = 13). October is small and covers only 10-01 to 10-05.
- **What it says about B, and what it does not.** On this record, the median B-eligible reaction neither faded nor extended over its own ten sessions. That is consistent with the spec's default ("market reaction is correct"). It is not evidence for a convergence edge in either direction. The dispersion is wide: only 21 of 106 rows land within ±10 of 100. So any edge would have to come from per-candidate selection, not from the cohort. This is a research record and no decision reads it.

### Per-ticker series (all 107 annotations, in D2 note order)

| # | Ticker | Qualifying event | Window close | m (event session) | d (post-window drift) | gap_intact_pct | Basis | D2 grouping | D2 note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | CVS | 2026-08-05 | 2026-08-19 | −5.08% | −5.52% | 203.14 | m_d | independent | 2026-08-20 |
| 2 | DVA | 2026-08-05 | 2026-08-19 | −17.24% | −6.05% | 129.04 | m_d | independent | 2026-08-20 |
| 3 | SEZL | 2026-08-07 | 2026-08-20 | −33.89% | −0.51% | 100.99 | m_d | independent | 2026-08-20 |
| 4 | BLLN | 2026-08-06 | 2026-08-19 | −38.89% | +0.02% | 99.97 | closes | independent | 2026-08-20 |
| 5 | ONON | 2026-08-11 | 2026-08-25 | −20.29% | −6.73% | 126.43 | closes | independent | 2026-08-25 |
| 6 | TME | 2026-08-11 | 2026-08-25 | −11.92% | +0.23% | 98.31 | closes | independent | 2026-08-25 |
| 7 | ACM | 2026-08-12 | 2026-08-25 | −8.96% | +2.85% | 71.05 | closes | independent | 2026-08-25 |
| 8 | MU | 2026-08-24 | 2026-09-08 | −5.8286% | +9.87% | -59.41 | closes | shared: SINGLE-CATALYST COHORT (memory/storage, 2026-08-24) | 2026-09-09 |
| 9 | SNDK | 2026-08-24 | 2026-09-08 | −6.4508% | +16.4% | -137.83 | closes | shared: SINGLE-CATALYST COHORT (memory/storage, 2026-08-24) | 2026-09-09 |
| 10 | STX | 2026-08-24 | 2026-09-08 | −6.5118% | +13.81% | -98.25 | closes | shared: SINGLE-CATALYST COHORT (memory/storage, 2026-08-24) | 2026-09-09 |
| 11 | WDC | 2026-08-24 | 2026-09-08 | −5.2368% | +9.63% | -74.23 | closes | shared: SINGLE-CATALYST COHORT (memory/storage, 2026-08-24) | 2026-09-09 |
| 12 | DKS | 2026-08-25 | 2026-09-09 | −30.6809% | +7.28% | 83.55 | m_d | independent | 2026-09-09 |
| 13 | BBWI | 2026-08-25 | 2026-09-09 | −8.2942% | +0.74% | 91.82 | m_d | independent | 2026-09-09 |
| 14 | RDDT | 2026-08-25 | 2026-09-09 | +6.3851% | −9.86% | -64.28 | m_d | independent | 2026-09-09 |
| 15 | GWRE | 2026-09-04 | 2026-09-18 | −19.9349% | −11.1624% | 144.83 | closes | independent | 2026-09-20 |
| 16 | FICO | 2026-09-04 | 2026-09-18 | −16.6829% | +1.8686% | 90.67 | closes | independent | 2026-09-20 |
| 17 | LULU | 2026-09-04 | 2026-09-18 | −17.3771% | −2.5345% | 112.05 | closes | independent | 2026-09-20 |
| 18 | FN | 2026-08-17 | 2026-08-31 | −19.38% | −14.4346% | 160.06 | closes | independent | 2026-10-12 |
| 19 | KLAR | 2026-08-18 | 2026-09-01 | −22.81% | −5.3785% | 118.20 | closes | independent | 2026-10-12 |
| 20 | BIDU | 2026-08-18 | 2026-09-01 | −12.73% | +4.3909% | 69.89 | closes | independent | 2026-10-12 |
| 21 | AMLX | 2026-08-18 | 2026-09-01 | +63.83% | −3.7026% | 90.50 | closes | independent | 2026-10-12 |
| 22 | EL | 2026-08-19 | 2026-09-02 | +16.3% | +3.2038% | 122.85 | closes | independent | 2026-10-12 |
| 23 | MRNA | 2026-08-19 | 2026-09-02 | +176.97% | −13.5165% | 78.85 | closes | independent | 2026-10-12 |
| 24 | WOLF | 2026-08-19 | 2026-09-02 | −9.42% | +1.1385% | 89.05 | closes | independent | 2026-10-12 |
| 25 | MRVL | 2026-08-19 | 2026-09-02 | +9.85% | −12.9768% | -44.76 | closes | independent | 2026-10-12 |
| 26 | NDSN | 2026-08-19 | 2026-09-02 | +8.0% | −5.3989% | 27.08 | closes | independent | 2026-10-12 |
| 27 | WMT | 2026-08-20 | 2026-09-03 | −9.15% | +4.4106% | 56.21 | closes | independent | 2026-10-12 |
| 28 | AAP | 2026-08-20 | 2026-09-03 | −24.55% | +0.7785% | 97.61 | closes | independent | 2026-10-13 |
| 29 | DE | 2026-08-20 | 2026-09-03 | +6.94% | +11.8321% | 282.26 | closes | independent | 2026-10-13 |
| 30 | BTDR | 2026-08-20 | 2026-09-03 | +8.31% | +14.1898% | 285.00 | closes | independent | 2026-10-13 |
| 31 | BJ | 2026-08-21 | 2026-09-04 | +5.61% | −3.3499% | 36.91 | closes | independent | 2026-10-13 |
| 32 | TSLA | 2026-08-21 | 2026-09-04 | +5.14% | −2.4197% | 50.48 | closes | independent | 2026-10-13 |
| 33 | QBTS | 2026-08-21 | 2026-09-04 | +8.46% | −18.6856% | -139.62 | closes | independent | 2026-10-13 |
| 34 | DNN | 2026-08-21 | 2026-09-04 | +11.46% | −2.2857% | 77.78 | closes | independent | 2026-10-13 |
| 35 | AAOI | 2026-08-21 | 2026-09-04 | −13.77% | −1.9511% | 112.22 | closes | independent | 2026-10-13 |
| 36 | BE | 2026-09-04 | 2026-09-18 | −5.3889% | UNMEASURED (zero-length window) | UNMEASURED | — | independent (S&P 500 index-add flow) | 2026-10-13 |
| 37 | TTAN | 2026-09-09 | 2026-09-22 | −29.98% | +7.7731% | 81.85 | closes | independent | 2026-10-13 |
| 38 | CASY | 2026-09-09 | 2026-09-22 | −14.24% | −7.0267% | 142.31 | closes | independent | 2026-10-14 |
| 39 | BRZE | 2026-09-09 | 2026-09-22 | −21.71% | +7.5432% | 72.80 | closes | independent | 2026-10-14 |
| 40 | TBBK | 2026-09-09 | 2026-09-22 | −22.33% | +1.1193% | 96.11 | closes | independent | 2026-10-14 |
| 41 | SIG | 2026-09-09 | 2026-09-22 | +23.96% | −2.0101% | 89.60 | closes | independent | 2026-10-14 |
| 42 | ASO | 2026-09-09 | 2026-09-22 | +14.4% | −3.2258% | 74.38 | closes | independent | 2026-10-14 |
| 43 | CMCSA | 2026-09-09 | 2026-09-22 | −6.61% | −8.8247% | 224.71 | closes | independent | 2026-10-14 |
| 44 | META | 2026-09-09 | 2026-09-22 | +6.55% | +12.6834% | 306.19 | closes | independent | 2026-10-14 |
| 45 | COO | 2026-09-09 | 2026-09-22 | −14.67% | +2.0676% | 87.97 | closes | independent | 2026-10-14 |
| 46 | AEO | 2026-09-09 | 2026-09-22 | −13.97% | +9.5664% | 41.10 | closes | independent | 2026-10-14 |
| 47 | NAVN | 2026-09-09 | 2026-09-22 | −21.75% | +3.4551% | 87.57 | closes | independent | 2026-10-14 |
| 48 | RDDT | 2026-09-10 | 2026-09-24 | +6.08% | −1.6866% | 70.56 | closes | independent | 2026-10-15 |
| 49 | HPE | 2026-09-10 | 2026-09-24 | +12.44% | +2.3031% | 120.82 | closes | shared: Oracle FQ1 print/capex (HPE+DELL = one catalyst) | 2026-10-15 |
| 50 | DELL | 2026-09-10 | 2026-09-24 | +11.98% | −5.5122% | 48.46 | closes | shared: Oracle FQ1 print/capex (HPE+DELL = one catalyst) | 2026-10-15 |
| 51 | JBHT | 2026-09-15 | 2026-09-29 | −13.3% | −3.147% | 120.51 | closes | independent | 2026-10-15 |
| 52 | XENE | 2026-09-17 | 2026-09-30 | −30.69% | −6.4403% | 114.55 | closes | independent | 2026-10-15 |
| 53 | NUE | 2026-09-17 | 2026-09-30 | −6.32% | −5.8902% | 187.29 | closes | independent | 2026-10-15 |
| 54 | MSTR | 2026-09-17 | 2026-09-30 | +16.39% | −0.5392% | 96.17 | closes | shared: SEC "Innovation Exemption" release 2026-09-17 (MSTR+COIN) | 2026-10-15 |
| 55 | COIN | 2026-09-17 | 2026-09-30 | +11.66% | −4.036% | 61.34 | closes | shared: SEC "Innovation Exemption" release 2026-09-17 (MSTR+COIN) | 2026-10-15 |
| 56 | GNRC | 2026-09-17 | 2026-10-01 | +18.34% | +0.3281% | 102.12 | closes | independent | 2026-10-15 |
| 57 | VICR | 2026-09-17 | 2026-10-01 | +17.66% | +42.6083% | 383.87 | closes | independent | 2026-10-15 |
| 58 | SDGR | 2026-09-17 | 2026-10-01 | +26.37% | +0.7275% | 103.49 | closes | independent | 2026-10-18 |
| 59 | MRNA | 2026-09-17 | 2026-10-01 | +8.55% | +19.5293% | 347.95 | closes | independent | 2026-10-18 |
| 60 | SMR | 2026-09-17 | 2026-10-01 | +8.92% | −13.8274% | -68.92 | closes | independent | 2026-10-18 |
| 61 | INTC | 2026-09-17 | 2026-10-01 | +7.67% | +10.2941% | 244.52 | closes | independent | 2026-10-18 |
| 62 | GRAL | 2026-09-21 | 2026-10-02 | +33.68% | +32.685% | 229.74 | closes | independent | 2026-10-18 |
| 63 | WBD | 2026-09-21 | 2026-10-02 | +10.79% | +0.4545% | 104.67 | closes | independent | 2026-10-18 |
| 64 | NVO | 2026-09-21 | 2026-10-02 | −7.96% | −6.2312% | 172.09 | closes | independent | 2026-10-18 |
| 65 | SHOP | 2026-09-21 | 2026-10-02 | +7.33% | +9.7665% | 242.99 | closes | independent | 2026-10-18 |
| 66 | FSLY | 2026-09-21 | 2026-10-02 | +14.92% | −5.8716% | 54.78 | closes | independent | 2026-10-18 |
| 67 | VKTX | 2026-09-22 | 2026-10-05 | +35.67% | −28.3231% | -7.73 | closes | independent | 2026-10-18 |
| 68 | BFLY | 2026-09-22 | 2026-10-05 | +21.99% | −5.5388% | 69.27 | closes | independent | 2026-10-19 |
| 69 | CLDX | 2026-09-22 | 2026-10-05 | −11.56% | −2.7454% | 121.00 | closes | independent | 2026-10-19 |
| 70 | SNDK | 2026-09-22 | 2026-10-05 | +6.82% | −9.6914% | -51.89 | closes | independent | 2026-10-19 |
| 71 | RCL | 2026-09-22 | 2026-10-05 | −6.14% | +17.0889% | -161.33 | closes | independent | 2026-10-19 |
| 72 | MGM | 2026-09-23 | 2026-10-06 | −10.99% | −9.35% | 175.72 | closes | shared: one linked storyline (MGM/People Inc. bid) | 2026-10-19 |
| 73 | SECZ | 2026-09-24 | 2026-10-07 | +15.11% | −31.0345% | -136.41 | closes | independent | 2026-10-19 |
| 74 | ZS | 2026-09-24 | 2026-10-07 | −10.06% | +10.619% | 5.05 | closes | independent | 2026-10-19 |
| 75 | PPLI | 2026-09-24 | 2026-10-07 | +11.33% | +1.475% | 114.50 | closes | shared: one linked storyline (MGM/People Inc. bid) | 2026-10-19 |
| 76 | VIAV | 2026-09-25 | 2026-10-08 | +9.27% | +8.3825% | 198.84 | closes | independent | 2026-10-19 |
| 77 | TWLO | 2026-09-25 | 2026-10-08 | −7.96% | −0.0109% | 100.13 | closes | independent | 2026-10-19 |
| 78 | DELL | 2026-09-25 | 2026-10-08 | +5.01% | +2.0715% | 143.39 | closes | independent | 2026-10-20 |
| 79 | KOD | 2026-09-28 | 2026-10-09 | +177.96% | +11.0654% | 117.28 | closes | independent | 2026-10-20 |
| 80 | MDB | 2026-09-28 | 2026-10-09 | −18.46% | +15.3131% | 32.35 | closes | independent | 2026-10-20 |
| 81 | GFI | 2026-09-28 | 2026-10-09 | −12.88% | +4.6617% | 68.46 | closes | shared: 2026-09-28 gold/silver liquidation (GFI+HL) | 2026-10-20 |
| 82 | CRDO | 2026-09-28 | 2026-10-09 | −8.67% | +12.3942% | -30.49 | closes | shared: 2026-09-28 AI-hardware repricing / OpenAI training pause (CRDO+INTC) | 2026-10-20 |
| 83 | BA | 2026-09-28 | 2026-10-09 | −6.91% | +3.2431% | 56.29 | closes | independent | 2026-10-20 |
| 84 | HL | 2026-09-28 | 2026-10-09 | −6.49% | +0.3527% | 94.92 | closes | shared: 2026-09-28 gold/silver liquidation (GFI+HL) | 2026-10-20 |
| 85 | INTC | 2026-09-28 | 2026-10-09 | −5.67% | −9.7647% | 262.55 | closes | shared: 2026-09-28 AI-hardware repricing / OpenAI training pause (CRDO+INTC) | 2026-10-20 |
| 86 | FICO | 2026-09-28 | 2026-10-09 | −26.52% | +8.0454% | 77.71 | closes | independent | 2026-10-20 |
| 87 | SMMT | 2026-09-28 | 2026-10-09 | +5.88% | +7.3215% | 231.87 | closes | independent | 2026-10-20 |
| 88 | AIR | 2026-09-28 | 2026-10-09 | −7.25% | −5.9204% | 175.78 | closes | independent | 2026-10-21 |
| 89 | CCL | 2026-09-29 | 2026-10-12 | +13.41% | +5.456% | 146.13 | closes | shared: CCL 2026-09-29 pre-open fiscal-Q3 read-through (CCL+RCL) | 2026-10-21 |
| 90 | RCL | 2026-09-29 | 2026-10-12 | +7.45% | +7.6725% | 210.62 | closes | shared: CCL 2026-09-29 pre-open fiscal-Q3 read-through (CCL+RCL) | 2026-10-21 |
| 91 | LQDA | 2026-09-30 | 2026-10-13 | −57.19% | −11.4012% | 108.53 | closes | shared: 2026-09-30 Delaware '327 patent ruling (LQDA+UTHR) | 2026-10-21 |
| 92 | UTHR | 2026-09-30 | 2026-10-13 | +12.55% | +0.2787% | 102.50 | closes | shared: 2026-09-30 Delaware '327 patent ruling (LQDA+UTHR) | 2026-10-21 |
| 93 | JBL | 2026-09-30 | 2026-10-13 | −10.03% | +10.8067% | 3.06 | closes | independent | 2026-10-21 |
| 94 | SNPS | 2026-09-30 | 2026-10-13 | +12.78% | +0.8093% | 107.14 | closes | independent | 2026-10-21 |
| 95 | ACN | 2026-10-01 | 2026-10-14 | +15.78% | +1.2529% | 109.19 | closes | independent | 2026-10-21 |
| 96 | SYNA | 2026-10-01 | 2026-10-14 | +14.08% | −3.0884% | 74.98 | closes | shared: 2026-10-01 after-close onsemi/SYNA $123 cash deal (SYNA+ON) | 2026-10-21 |
| 97 | ON | 2026-10-01 | 2026-10-14 | +6.01% | −13.5823% | -139.71 | closes | shared: 2026-10-01 after-close onsemi/SYNA $123 cash deal (SYNA+ON) | 2026-10-21 |
| 98 | STX | 2026-10-01 | 2026-10-14 | −10.21% | −15.9543% | 240.25 | closes | shared: Nikkei/Toshiba HDD report 2026-10-01 (STX+WDC) | 2026-10-23 |
| 99 | WDC | 2026-10-01 | 2026-10-14 | −10.22% | −12.3263% | 208.29 | closes | shared: Nikkei/Toshiba HDD report 2026-10-01 (STX+WDC) | 2026-10-23 |
| 100 | PTC | 2026-10-05 | 2026-10-16 | +33.49% | +0.3745% | 101.49 | closes | independent | 2026-10-23 |
| 101 | PCVX | 2026-10-05 | 2026-10-16 | +30.7% | −13.8174% | 41.18 | closes | independent | 2026-10-23 |
| 102 | RXO | 2026-10-05 | 2026-10-16 | +22.54% | −0.1745% | 99.05 | closes | shared: CHRW acquisition of RXO 2026-10-05 (RXO+CHRW) | 2026-10-23 |
| 103 | CHRW | 2026-10-05 | 2026-10-16 | −10.85% | −0.7965% | 106.55 | closes | shared: CHRW acquisition of RXO 2026-10-05 (RXO+CHRW) | 2026-10-23 |
| 104 | SPHR | 2026-10-05 | 2026-10-16 | −13.61% | −6.5614% | 141.66 | closes | independent | 2026-10-23 |
| 105 | INSM | 2026-10-05 | 2026-10-16 | −6.56% | −7.2811% | 203.70 | closes | independent | 2026-10-23 |
| 106 | HOG | 2026-10-05 | 2026-10-16 | +6.68% | +2.1764% | 134.76 | closes | independent | 2026-10-23 |
| 107 | DKNG | 2026-10-05 | 2026-10-16 | +5.43% | −3.5714% | 30.69 | closes | independent | 2026-10-23 |

### Not yet in the series — PENDING D2 ANNOTATION, and the named GAPs

- **PENDING D2 ANNOTATION.** This is copied from D2's most recent note (2026-10-23, line 718); W2 does not re-derive it. "Remaining backlog: **19** unannotated closed rows carried to the next run's `<note>`, next oldest close date **2026-10-16 (MELI)**; plus IONQ and MANH (closing 2026-10-23)." The 19 are:
  - MELI;
  - PENG, CEG, MRVL and OPCH (closing 10-19);
  - HESM (10-20);
  - HAE, CMG, TMUS, T, VZ, CCI, AMT, SBAC, ASTS and HUM (10-21);
  - MRNA, FSLY and CCC (10-22).

  These are pending, not gaps, and not zeros. D2's carried backlog has fallen at every note (63 → 57 → 52 → 42 → 41 → 35 → 26 → 26 → 19 across the 10-12 to 10-23 notes). It annotates ten rows per run, so the W42 cohort should start entering the series within one to two D2 runs.
- **Named GAPs: W2 intake identities with no index row at all.** Nothing will ever annotate them:
  - W42: EFXT (Rev 49-ineligible) and CRWV 2026-10-14 (undated);
  - W41: BULL, SPOT 2026-10-07 and ARGX (held on the instrument rail), and ECHO (undated).
- **This cycle adds seven more future GAPs** (the UNRESOLVED-anchor items above), plus the four Rev 49-ineligible items.

### Repeat names — intake tickers already in the fixed-horizon series

| Ticker | Earlier closed window(s) in the series (qualifying date: m, gap_intact) | This intake |
|---|---|---|
| MRNA | 08-19: +176.97%, 78.85 · 09-17: +8.55%, 347.95 (W42's 10-09 item is pending) | rank 6, 10-22, −17.5664%. Its fifth published B appearance, every one a distinct event. |
| VICR | 09-17: +17.66%, **383.87** (the series' largest extension) | below-cap, 10-20, +7.0589%, with five other ≥5% sessions in the window |
| BRZE | 09-09: −21.71%, 72.80 | rank 1, 10-20, +51.6977%, now a pinned cash-deal target |
| META | 09-09: +6.55%, 306.19 | below-cap, 10-21, −6.9776% |
| MSTR | 09-17: +16.39%, 96.17 | below-cap, 10-15, −9.5578% |

Three further intake names repeat earlier W2 cohorts on new events: ARQT (W42 rank 15), T (W42 rank 13) and SPOT (W41, held on the instrument rail). **No ticker has ever been ranked twice on the same event.**

### What W2 adds from its own durable record: the GRADING OUTCOME series, itemized per ticker

**W42 cohort (34 identities), graded against the router state (DO-NOT-ACTIVATE throughout, no drain):**

| Ticker(s) | Window closes | Outcome |
|---|---|---|
| CCI, TMUS, T, VZ, AMT, SBAC, ASTS, HUM | 2026-10-21 | **Expired ungraded.** |
| FSLY, MRNA, CCC | 2026-10-22 | Expired ungraded. |
| IONQ (10-12), MANH | 2026-10-23 | Expired ungraded. |
| LQDA, FRMI, CIFR, AMAT, JNJ, C | 2026-10-26 | **Will expire ungraded** unless the out-of-cycle chain completes inside a single session; that is not plausible. |
| BSP, DELL, IONQ (10-14), MMED, HPE, NTAP, RKLB | 2026-10-27 | Will expire ungraded. Reaching them needs a trigger in tonight's D2a, an M1R re-score at 13:00 UTC on 10-26, and a D2 review writing ACTIVATE that evening. Improbable. |
| MAN, QNT, ARQT (10-15), PAG, INTU, CROX, NOW, CRWV (10-15) | 2026-10-28 | Same as above, with one more session of slack. |

**W41 cohort (20 identities):** all windows are now closed. The last were HAE and CMG on 10-21, and every one expired ungraded. **W40 (22):** all expired ungraded.

**Lineage tally:**
- Nine consecutive index-mode cycles.
- **No published B identity has ever been evaluated against B's entry criteria.** There are zero B thesis-construction queue rows since 2026-08-03, and no B thesis or NO-GO decision on any W40–W42 identity.
- **W43 is the first cohort the scheduled router write can reach.** That is a change in reachability, not a grade of B.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, record-read only

**S1 — earnings season dominates, and analyst actions left the ranked list.**
- 47 of the 60 identities are earnings or guidance events, and 9 of the ranked 15 are.
- The other ranked six are:
  - clinical: IRON, MRNA;
  - M&A: BRZE (definitive), LION (an unconfirmed report);
  - executive change: FPS;
  - capital return: ASST.
- **Analyst-action-only events take 0 of the ranked 15**, against 4 of 15 in W42. Three sit below the cap: KSS, ARQT and DDOG. W42's analyst-action share was a property of a light-earnings week, not of the rule.
- **Direction in the ranked 15 is 7 up / 8 down.** The coin-flip pattern holds for the ninth time.

**S2 — a deal-pinned target is back at rank 1.** BRZE's +51.70% is Salesforce's all-cash $47.50 offer, and its 45.57 close sits 4.2% under that price. W41 recorded deal-pinned names at 4 of its top seven; W42 had 0 of 15. Absolute-move ranking promotes takeover premia whenever a cohort contains one, and a pinned target's post-event path is merger-spread arithmetic, not B's information-versus-sentiment mechanism. LION's takeover *report* is unconfirmed, so it is not pinned. TTMI is the acquirer in its own release, not a target. This remains one more observation, not filed: the taxonomy question stays with SL/W5, as in W41.

**S3 — shared drivers inside the routable set.** Each ranked name has its own anchor, so the ranked 15 hold **15 distinct qualifying events**. But D1 flags common-driver confounding on several:
- **The 10-22 AI-hardware and semis rout:** TTMI (rank 3) and FPS (rank 5, "confounded by the AI-power selloff"). LRCX's after-close guide (below-cap) is the session's trigger. D1 declined NOK and ESI on the same driver.
- **Oilfield services:** OII (rank 7) and LBRT (below-cap) fell together. WFRD rose on its own print.
- **The SpaceX Q3 print:** SPCX and FLY (both below-cap); TSLA was below the floor.
- **Homebuilders:** MHO (below-cap); D1 declined PHM.

B's concurrent-position correlation constraint (Section 6 / KL #12) would bind on OII and LBRT, and possibly on TTMI and FPS, if they were ever routable together.

**S4 — anchor and measurement quality, worse than W42 on two counts.**
- **Undated tail: 7 of 80 floor-clearers are UNRESOLVED**, against 1 of 36. Five come from the catch-up row `5022f59e`.
- **Reaction-session measurement:** 16 of the 60 are after-close releases measured on the next session, 3 of them ranked (KALU, OII, GGG).
- **Broker verification: 1 of 60** (MSTR), against 18 of 34 in W42 (see MEASUREMENT OF RECORD).
- **Multi-session names, a criterion 2 question for D2:** other ≥5% sessions inside the window are recorded for TTMI (6), MANE (5), VICR (5), ASST (4), MRNA (4), FPS (3) and FLY (3). D1 calls MANE and VICR "not a clean single-event reaction".

**S5 — instrument-rail and floor-edge items for D2 at thesis construction, none W2's to settle.**
- **On the floor:** UCB at 5.0030% and MSCI at 5.0045% sit within 0.005 pp of the floor. Broker re-measurement could move either below 5%, so they are rankable only on D1's figure.
- **Near the floor:** ROIV 5.3837%, LUV 5.3912% and DDOG 5.3620%.
- **Small caps:** KALU ($2.52B), ASST ($3.36B) and FLY ($2.73B; D1 found no second source for the cap) sit less than 70% above the $2B floor.
- **BRZE:** pinned, as in S2.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-10-06).**

The ranked list is the 15-item table in PART 1. It carries the tier field (e) on every row, set strictly by rank (1–5 `top-5`, 6–15 `rest`), plus `qualifying_event_date`, event-day move, window close, sessions left, originating D1 id and a one-line event. The 45 eligible identities below the cap follow it, marked `below-cap`.

Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, fields (a) and (c) read **"not assessed — INDEX MODE"** for every candidate. Fields (b), (d), (e), (f) and (g) are in the tables.

The cohort work is not skipped. The fixed-horizon trajectory series, the structural findings and the grading-outcome series are all given in full above.

## ROUTING

Route the 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. **W4 §C's top tier is the five `top-5` rows: BRZE, IRON, TTMI, KALU and FPS.**

- The 45 below-cap names are at W4's discretion.
- **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.**
- **For W4: 13 of the ranked 15 have windows still open on 2026-11-02.** The exceptions are IRON and CLF, which close 10-30. So the overflow rows' status cell should say that the scheduled 11-02 write *can* reach them, not the "closes before the next scheduled router write" wording that was correct for every block through W42.

---

## FINDINGS — zero alerts filed, zero queue items, nothing resolved by W2

**`ops.alerts`:** none filed.
- **The catch-up row's missing `close_chain_check` field is not a defect W2 can act on.** W2's own close-chain test, run over the same items, found 0 hits. The spec puts that check on W2 and on D2, not on a D1 field.
- **The retired limb view still being live is Rev 52's stated design.** The view stays defined under a retirement marker (`bigquery/224` names `bigquery/263`). It is not a defect.

**`events.queue_events`:** none. Both free checks were clean, and no thesis-construction enqueue is owed under index mode.

**Carried, not re-filed (open):**
- `143c2aaf` (`shock_baseline_window_divergent_between_m1a_and_limb_view`, W2's own, W5). **Its band has moved.** A new Brent peak (113.17, 10-22) raised the view's midpoint to 98.95 on its 84.73 baseline. M1a's last-scored midpoint is still 97.975, on the 87.20 baseline and the 108.75 peak. So the view's midpoint now sits *above* M1a's: the disagreement band is 97.975 to 98.95, inverted from 96.74 to 97.975.
  - The band is not live this cycle: the stored close is ~14 above both midpoints.
  - The finding is unchanged: one rule, two midpoints.
  - M1a will recompute its own on 11-02.
- `0a40c378` (M1R, blinding side channel via git commit subjects): this run's commit subject carries no regime, router or price substance.

**Resolved since W42 by their owners (re-read live this run):**
- `3218eb3c` and `76cbd8f6`, by an interactive owner session on 10-19 (applied above: the trajectory series is published for the first time).
- `3897ecc6` and `06c3b0db`, by W5 on 10-18.

---

## HONEST LIMITS OF THIS RUN

- **None of the ranked 15 is broker-verified.** They are arithmetic-checked only, and two sit on the 5% floor.
- **The fixed-horizon series is D2's measurement, published by record read.** W2 re-verified no close against a bar. The spot checks matched D2's printed text (VKTX, PCVX and the 10-19 re-measurements). The six `m_d`-basis rows rest on D2's stated move and drift.
- **The flip-path read rests on a view's as-of 10-22 inputs.** The 10-23 Brent close is not yet stored. W2 pulled no price, makes no forecast, and does not pre-empt M1a's blind scoring on 11-02.
- **10-23 is uncovered**, and so are the 10-22 after-close reporters. Both are D1's tonight. Next week's intake will be heavy again.

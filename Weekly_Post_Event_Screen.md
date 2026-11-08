2026-W45

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-11-08 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W45
**Intake watermark:** 2026-11-01T08:28:33Z, this routine's own prior completion. **Catch-up window:** 7.03 days, which is the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `d7974612-d507-473a-8653-20805aa27e9d` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · zero `ops.alerts` rows filed.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-11-05).** This is the eleventh consecutive index-mode cycle. The router value is now `DO-NOT-ACTIVATE — PENDING div-B-202611-2`: a held state, not a judged one.

**What decides this cycle: B's DO-NOT-ACTIVATE no longer rests on the shock override. It rests on one technical line, and that line is under adversarial review.**
- **The fundamental side changed.** On 11-05 M1R re-scored `shock_overlay` from acute to latent (event `cbdfa3d5`, refresh item `regime-refresh-20261104`). The acute override had been B's only reason for DO-NOT-ACTIVATE, and M1b's raw call for B on 11-01 was ACTIVATE (`d5299c85`). D2 then re-mapped B's standing fundamental call to ACTIVATE (`310bd8ff`, 11-05).
- **The technical side moved against it on the same day.** VIX Regime read HIGH (28.18) on 11-05 for the first time, on a −4.41% SPY session. SPY is NEUTRAL (733.00, below its SMA50 of 766.40) and breadth is HEALTHY (58.56%).
- **So D2 opened `div-B-202611-2`** under its daily technical-flip clause (queue event `380f3ca7`, `PENDING_REVIEW`/`divergence-review`, still `pending`). D2 also wrote the held router row (`89f2506e`, 11-05 23:21Z).
- **When the flip could land (inferred from `ops/cadence.yaml` and the payload's due dates):** the payload's `attacker_due_date` is 11-06 and its `orchestrator_due_date` is 11-09. AR_att serves Sun–Thu at 18:00 MT, so its first fire on or after the 11-06 due date is tonight, 11-08. AR_orc serves at 18:35 MT, so the earliest write that could resolve this review to ACTIVATE is **2026-11-09 at 18:35 MT**, after the 11-09 session closes. The first session that write could reach is **11-10**.
- **On that timetable every ranked window is still open, and so is every one of the 342 eligible windows.** The earliest close is 11-11 (33 identities, all with qed 10-29), and those would have two sessions left (11-10 and 11-11). W2 makes no forecast of the verdict. The same review class resolved `div-B-202611-1` to DNA on 11-05 (AR `dcc68d14`), but that verdict rested on the acute override, which has since lapsed.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**:
- It pulled no broad bars, enumerated no movers and repeated no event search.
- It did not re-judge D1's §19 significance verdicts.
- **It pulled no price bars of any kind.** `scripts/check_routine_scope.py` enforces that boundary.
- The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

**The run made zero metered external calls**: no Anthropic `web_search`/`web_fetch`, no Tavily, no FMP, no HF and no IBKR. Index mode skips per-candidate enrichment. Sonnet data-assembly sub-agents were confined to BigQuery reads and repo reads.

**One coverage edge is deliberately left open: the 2026-11-06 (Friday) session**, together with the 11-05 after-close reporters that reacted on 11-06. D1 has no Friday or Saturday run. D1's Sunday scan tonight owns that gap, and PART 1 forbids W2 from covering it. **W44's open edge is closed:** the 10-30 session and the 10-29 after-close names are in this intake (D1 `e2dfa715`, written 11-01 after W44's watermark).

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`:

| Field | Value |
|---|---|
| value | `DO-NOT-ACTIVATE — PENDING div-B-202611-2` |
| as_of | 2026-11-05 |
| event | `89f2506e-af09-4f02-a29e-bec6bcec53b5` (D2, 23:21Z) |
| divergence | `div-B-202611-2`, `pending`, orchestrator due 11-09 |
| previous B row | DNA via `div-B-202611-1` (AR_orc, 11-05 00:50Z, `3038961a`) |
| B capital | `state.strategy_capital_enablement` `capital_disabled = TRUE` |

**Router-relevant writes since the watermark:**
- M1a, M1b and M4 ran on **2026-11-01**, not 11-02 (runs `a688d4b4`, `bc114c1f`, `8fa05335`). M1b's raw call for B was ACTIVATE, and its binding DNA came only from the acute override. M4 queued divergence reviews for A to E.
- M1R drained two `PENDING_REGIME_REFRESH` items:
  - 11-02 (`regime-refresh-20261101`): no axis moved, and the overlay stayed acute.
  - 11-05 (`regime-refresh-20261104`): `shock_overlay` acute → latent. The 11-04 Brent close of 94.60 was below M1R's 101.96 midpoint. The structure leg is still open.
  - No refresh item is open now.
- `state.shock_price_leg_status` (latest stored row 11-05): Brent 99.37, **NOT ELEVATED**, basis `retraced`. 11-02 and 11-03 read ELEVATED (103.68 and 103.60), and 11-04 read NOT ELEVATED (94.60, `retraced`). The view's midpoint is 100.725; M1R's scoring used 101.96. The two midpoints are a declared by-design difference (W5 closed `143c2aaf` on 11-02).

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE. The qualifying event date is trading session 1, and the window closes on the 10th trading session inclusive. All window-close dates below match D2's index rows exactly. Trading days were verified against `state.market_calendar`: there is no holiday or early close between 10-29 and 11-18 (the first market holiday ahead is 11-26).

| Qualifying event date | Window closes | Sessions left from 11-09 / from 11-10, inclusive | Rankable identities |
|---|---|---|---|
| 2026-10-29 | 2026-11-11 | 3 / 2 | 35 |
| 2026-10-30 | 2026-11-12 | 4 / 3 | 16 |
| 2026-11-02 | 2026-11-13 | 5 / 4 | 26 |
| 2026-11-03 | 2026-11-16 | 6 / 5 | 81 |
| 2026-11-04 | 2026-11-17 | 7 / 6 | 133 |
| 2026-11-05 | 2026-11-18 | 8 / 7 | 51 |

The "from 11-10" column counts from the first session the earliest possible flip write could reach (see the headline).

**How the move is measured:** for an after-close release the move is measured on the NEXT session, the reaction session, and the ranked table marks that session in **bold** where it differs from the qualifying date. 187 of the 346 passed items are after-close releases of this kind.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five `single-name-move` rows have landed since the watermark. None is superseded, and none is superseded by a correction row. Together they carry **346** distinct `passed[]` items (346 distinct ticker + `qualifying_event_date` identities). 342 clear B's spec floor, and 4 are `below_spec_floor = true` write-ups. All 346 carry both recorded closes.

| Decision id | Session screened | `passed[]` items | Note |
|---|---|---|---|
| `e2dfa715-80cb-4d38-81fb-fe3310e21cfd` | 2026-10-30 (Fri), written by D1's Sunday scan 11-01 | 54 (50 rankable, 4 below floor) | Closes W44's open 10-30 edge, including the 10-29 after-close reporters. |
| `da7bf33a-75de-4d4e-8ac6-4784082974b1` | 2026-11-02 (Mon) | 12 | `screen_mode` router-gated. |
| `c51c9632-6f14-4022-bcde-de8c37dd81c5` | 2026-11-03 (Tue) | 49 | **Degraded:** BigQuery was de-authed during D1's 11-03 run. Of 146 names that cleared the discovery rail, 49 were IBKR-confirmed and passed. D1's durable close-chain check did not run (`degraded_legs`); W2's check below covers this row. The row was landed by backfill on 11-05 (16:42Z). |
| `7701d3bc-1d7c-4a3b-9de8-3bf1eb1d91e3` | 2026-11-04 (Wed) | 93 | D1's own run could not land it (its issuing sub-agent was stopped by a provider safety filter). It was landed byte-exact by interactive triage under RUNBOOK §57 (alert `2c1417f8`, resolved). |
| `f5359185-8c8f-4d39-86f4-2dd0821fcdbb` | 2026-11-05 (Thu) | 138 | The same failure and the same §57 landing (alert `4ad2f90c`, resolved; written with D1's original call digest). |

- **Every passed item is `b_eligible = true`.** No passed item carries an UNRESOLVED anchor, so the unanchored-name line of index mode lists nothing this cycle. Unanchored names exist only in D1's rejected sets.
- **Deal-pinned rail (Operating_Protocols.md §19, landed 11-02 by PR #139):** no passed item's `reason` begins `deal-pinned:`, and none records a signed all-cash deal with a pinned price. LITE and MRVL are all-stock merger names, and D1 states they are not deal-pinned. CVI is the acquirer in a cash asset purchase, not a target. All three stay rankable.
- **Not intake:** the `sector-move` rows (`0b27dc01`, `514a7707`/`dc9251ab`, `98cf62ab`, `a4e2f628`, `23dea2da`) and the `pair-divergence` row `67f68f9a`.
- **No B-relevant D1 candidate or action record** exists since the watermark beyond these screen rows.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

- **Queue rows:** `events.queue_events` holds no `thesis-construction` + strategy B row after 2026-08-05, open or terminal. No same-ticker, same-`qualifying_event_date` collision is possible. The same-ticker overlaps that do exist (for example GDDY and APP) are June–July events on distinct dates.
- **Decision rows:** no B thesis or B decision row exists for any intake identity.
- **Open Strategy A positions:** none. `state.current_positions` holds 12 Strategy D tranches only (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER).
- **Expired windows:** none. The earliest close is 11-11.
- **Already published by W44:** none. No intake ticker + `qualifying_event_date` matches a W44 ranked or below-cap identity. The 35 qed-10-29 identities here are the after-close reporters W44 explicitly left uncovered.

**Identities EXCLUDED before enrichment: 0.**

## RECORDED-FIGURE ARITHMETIC CHECK — 346 of 346 items, zero mismatches

For every item, `metric_pct` equals `(event_close / prior_close − 1) × 100` to the recorded 4-decimal precision. No `rescreen-` item is owed.

## CROSS-ROW CLOSE-CHAIN CHECK — 17 hits on the actionable side, 0 defects

The search covered every `single-name-move` row landed since 2026-10-20 (14 rows), both `passed` and the `rejected_notable` / `rejected_compact` tuples, on the same name and the same `qualifying_event_date`, testing `other.event_close == this.prior_close` and `other.prior_close == this.event_close`.

- **17 hits on the actionable side.** In each one the intake item's `prior_close` equals an earlier row's `POST_MOVE_EVENT` tuple's `event_close`, which makes the intake item the later session:
  - ACHC, ADMA, APP, ARM, CGNX, DAVE, EXPE, IOND, IPAR, LUMN, PCVX, QCOM, RGLD, SEZL and SITM chain from `7701d3bc` tuples (session 11-04) to `f5359185` items (qed 11-04, measured 11-05).
  - DUOL and NVTS chain from `c51c9632` tuples (session 11-03) to `7701d3bc` items (qed 11-03, measured 11-04).
- **Resolved against each item's own release timing: all 17 are after-close releases**, with EDGAR acceptance at or after 21:00Z (21:00Z to 21:49Z) on the qualifying date. D1's legend defines `POST_MOVE_EVENT` as a move made *before* the only own-event filing was accepted. Each item therefore legitimately reports the next session, the reaction session. This is the after-close case the rule names as not a defect; it is not the IONQ `6e179f3c` continuation-leg pattern. D1's own `reason` text records the chain for APP, ADMA and DUOL and describes it the same way.
- **45 further hits are on the other side** (the intake item's `event_close` is another item's `prior_close`, a continuation running forward from the anchor). They are not actionable.

**This is a record read, not a re-measurement, and a clean pass is not a clearance.** The tuple closes are D1's Nasdaq discovery closes, not IBKR, and most rejected items carry no closes at all.

## MEASUREMENT OF RECORD — D1's figures, because D2 re-measured none of them

The D2-REMEASURED FIGURE PRECEDENCE rule was applied and **changes nothing this cycle.** All 342 rankable identities have a D2 index row in `Watchlist.md`'s "Strategy B new-entry candidates". Every one states that its figures are D1's and were not re-measured on IBKR. D1 and D2 agree on figure, `qualifying_event_date` and window close for every identity. So the rank key is the D1 figure: it is arithmetic-consistent, but it has not been independently broker-verified at the index-row stage. Broker re-measurement belongs to D2 at Strategy-B thesis construction (D2 STEP 1), which index mode never reaches.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor — 342 identities, 15 ranked at the cap

Ranks 1–5 carry tier `top-5`, and ranks 6–15 carry `rest`. There is no tie at the cap: rank 15 HUT is −23.2314, and rank 16 WRBY is +22.4988.

| Rank | Tier (e) | Ticker (a) | `qualifying_event_date` (f) | Move % (c) | Measured on | Window close (d) | Sessions left from 11-09 / from 11-10 | Originating D1 id (g) | Event (one line, factual, from D1's own item text) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `top-5` | VCYT | 2026-11-04 | -54.3031 | **11-05** | 2026-11-17 | 7 / 6 | `f5359185` | Earnings release (8-K Item 2.02, Item 8.01); after-close release (EDGAR 8-K accepted 2026-11-04 21:08Z) |
| 2 | `top-5` | NRIX | 2026-11-03 | -38.2262 | **11-04** | 2026-11-16 | 6 / 5 | `7701d3bc` | Sanofi discontinues SAR448272 (oral STAT6 degrader) Phase 1 and terminates the program (8-K Item 8.01); after-close release (EDGAR 8-K accepted 2026-11-03 21:02Z) |
| 3 | `top-5` | APP | 2026-11-04 | +31.0396 | **11-05** | 2026-11-17 | 7 / 6 | `f5359185` | Earnings release (8-K Item 2.02); after-close release (EDGAR 8-K accepted 2026-11-04 21:08Z) |
| 4 | `top-5` | KD | 2026-11-04 | +30.1391 | 11-04 | 2026-11-17 | 7 / 6 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026); pre-open release (EDGAR 8-K accepted 2026-11-04 12:16Z) |
| 5 | `top-5` | DOX | 2026-11-03 | -30.0657 | **11-04** | 2026-11-16 | 6 / 5 | `7701d3bc` | Fiscal Q4 earnings (6-K); after-close release (EDGAR 6-K accepted 2026-11-04 02:57Z) |
| 6 | `rest` | ECG | 2026-11-03 | -29.2912 | **11-04** | 2026-11-16 | 6 / 5 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 7.01); after-close release (EDGAR 8-K accepted 2026-11-03 21:34Z) |
| 7 | `rest` | RDDT | 2026-10-29 | -29.2207 | **10-30** | 2026-11-11 | 3 / 2 | `e2dfa715` | Q3 rev $895M +53% y/y, EPS $1.40 vs $1.31 cons (Nasdaq cal) |
| 8 | `rest` | INTC | 2026-10-29 | -28.5761 | **10-30** | 2026-11-11 | 3 / 2 | `e2dfa715` | Q3 results 8-K after close 10-29 |
| 9 | `rest` | FSLY | 2026-11-04 | -26.9011 | **11-05** | 2026-11-17 | 7 / 6 | `f5359185` | Earnings release (8-K Item 2.02, Item 7.01); after-close release (EDGAR 8-K accepted 2026-11-04 21:08Z) |
| 10 | `rest` | ECPG | 2026-11-04 | +26.2584 | **11-05** | 2026-11-17 | 7 / 6 | `f5359185` | Earnings release (8-K Item 2.02); after-close release (EDGAR 8-K accepted 2026-11-04 21:15Z) |
| 11 | `rest` | ADMA | 2026-11-04 | +26.0496 | **11-05** | 2026-11-17 | 7 / 6 | `f5359185` | Earnings release (8-K Item 2.02); after-close release (EDGAR 8-K accepted 2026-11-04 21:10Z) |
| 12 | `rest` | DUOL | 2026-11-03 | +25.9922 | **11-04** | 2026-11-16 | 6 / 5 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026); after-close release (EDGAR 8-K accepted 2026-11-03 21:06Z) |
| 13 | `rest` | YOU | 2026-11-04 | +23.7018 | 11-04 | 2026-11-17 | 7 / 6 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026); pre-open release (EDGAR 8-K accepted 2026-11-04 11:03Z) |
| 14 | `rest` | FIS | 2026-11-04 | -23.6727 | 11-04 | 2026-11-17 | 7 / 6 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026); pre-open release (EDGAR 8-K accepted 2026-11-04 12:34Z) |
| 15 | `rest` | HUT | 2026-11-04 | -23.2314 | 11-04 | 2026-11-17 | 7 / 6 | `7701d3bc` | Earnings release (8-K Item 2.02, quarter ending Sep/2026); pre-open release (EDGAR 8-K accepted 2026-11-04 11:37Z) |

### BELOW THE CAP — 327 eligible identities (`below-cap`, not ranked)

Format: ticker, move %, (`qualifying_event_date` MM-DD, originating D1 id). Ordered by absolute move within each window-close date.

- **Window closes 2026-11-11 — 33 identities:** CDNA +22.22 (10-29, `e2dfa715`); CACC -19.26 (10-29, `e2dfa715`); ILMN -18.64 (10-29, `e2dfa715`); RBLX -18.05 (10-29, `e2dfa715`); BFAM -17.92 (10-29, `e2dfa715`); TFII -17.08 (10-29, `e2dfa715`); TWLO -15.24 (10-29, `e2dfa715`); FDXF +14.91 (10-29, `e2dfa715`); SKYW -14.72 (10-29, `e2dfa715`); MEOH +14.04 (10-29, `e2dfa715`); SNDK -13.47 (10-29, `e2dfa715`); CVCO +13.11 (10-29, `e2dfa715`); GDDY +10.72 (10-29, `e2dfa715`); COIN -10.62 (10-29, `e2dfa715`); AXTI -9.56 (10-29, `e2dfa715`); RMD -9.05 (10-29, `e2dfa715`); MSTR -7.84 (10-29, `e2dfa715`); MMSI -7.66 (10-29, `e2dfa715`); TBBK -7.46 (10-29, `e2dfa715`); RKT +7.38 (10-29, `e2dfa715`); MHK +7.25 (10-29, `e2dfa715`); MIAX +6.97 (10-29, `e2dfa715`); PTCT -6.97 (10-29, `e2dfa715`); VLTO +6.77 (10-29, `e2dfa715`); BHVN -6.49 (10-29, `e2dfa715`); INVX -6.40 (10-29, `e2dfa715`); SYK -6.38 (10-29, `e2dfa715`); RIVN +6.20 (10-29, `e2dfa715`); COLM +6.04 (10-29, `e2dfa715`); BBIO +5.97 (10-29, `e2dfa715`); FND -5.46 (10-29, `e2dfa715`); TGS -5.40 (10-29, `e2dfa715`); ATR +5.02 (10-29, `e2dfa715`).
- **Window closes 2026-11-12 — 16 identities:** REGN +13.33 (10-30, `e2dfa715`); BTSG +11.08 (10-30, `e2dfa715`); SXT -10.57 (10-30, `e2dfa715`); GTES -9.22 (10-30, `e2dfa715`); NWG -9.00 (10-30, `e2dfa715`); NVT -8.81 (10-30, `e2dfa715`); CCJ -7.88 (10-30, `e2dfa715`); HGV +7.64 (10-30, `e2dfa715`); PIPR -7.14 (10-30, `e2dfa715`); AZN +7.02 (10-30, `e2dfa715`); CBOE +6.77 (10-30, `e2dfa715`); RBC -6.76 (10-30, `e2dfa715`); USLM +6.61 (10-30, `da7bf33a`); AN +6.08 (10-30, `e2dfa715`); IMO +5.52 (10-30, `e2dfa715`); LYB +5.00 (10-30, `e2dfa715`).
- **Window closes 2026-11-13 — 26 identities:** IDXX +21.85 (11-02, `da7bf33a`); LITE -18.59 (11-02, `da7bf33a`); FN +15.45 (11-02, `c51c9632`); ADEA -13.59 (11-02, `c51c9632`); NBIX +13.42 (11-02, `c51c9632`); MRVL -12.72 (11-02, `da7bf33a`); PAY -11.50 (11-02, `c51c9632`); LSCC +10.98 (11-02, `c51c9632`); KRYS -10.95 (11-02, `da7bf33a`); TBBB +10.53 (11-02, `c51c9632`); AEIS +9.63 (11-02, `c51c9632`); TEM +8.67 (11-02, `da7bf33a`); MTCH -8.49 (11-02, `c51c9632`); CALX -7.97 (11-02, `c51c9632`); JAZZ +7.13 (11-02, `c51c9632`); CHKP -6.98 (11-02, `da7bf33a`); TSEM -6.70 (11-02, `da7bf33a`); CHH +6.70 (11-02, `da7bf33a`); MSA -6.64 (11-02, `c51c9632`); LDOS -6.55 (11-02, `c51c9632`); CIFR -5.90 (11-02, `da7bf33a`); AXSM -5.83 (11-02, `da7bf33a`); RIG -5.30 (11-02, `c51c9632`); ALSN +5.16 (11-02, `c51c9632`); GRFS +5.06 (11-02, `da7bf33a`); CE +5.05 (11-02, `c51c9632`).
- **Window closes 2026-11-16 — 77 identities:** MOD -21.43 (11-03, `7701d3bc`); GPK +21.22 (11-03, `c51c9632`); PCOR +19.68 (11-03, `7701d3bc`); IOSP -18.72 (11-03, `7701d3bc`); UNM -17.84 (11-03, `7701d3bc`); UFPT +17.66 (11-03, `7701d3bc`); MOS +17.37 (11-03, `7701d3bc`); XMTR +16.55 (11-03, `c51c9632`); BETA +16.00 (11-03, `c51c9632`); OUST +15.73 (11-03, `7701d3bc`); XYZ +15.30 (11-03, `7701d3bc`); SM -15.30 (11-03, `7701d3bc`); DT -14.69 (11-03, `c51c9632`); PRIM -13.98 (11-03, `7701d3bc`); FLYW +13.89 (11-03, `7701d3bc`); MCY -13.42 (11-03, `7701d3bc`); IT -13.19 (11-03, `c51c9632`); HL +13.17 (11-03, `7701d3bc`); CVI -13.09 (11-03, `c51c9632`); HURN -12.70 (11-03, `7701d3bc`); FISV +12.46 (11-03, `c51c9632`); CPNG +11.95 (11-03, `7701d3bc`); PTCT +11.89 (11-03, `c51c9632`); RRX +11.81 (11-03, `c51c9632`); ANDE -11.68 (11-03, `7701d3bc`); MIRM +11.42 (11-03, `7701d3bc`); SKY +11.35 (11-03, `7701d3bc`); DRVN -11.24 (11-03, `c51c9632`); JKHY +10.83 (11-03, `7701d3bc`); LIND -10.64 (11-03, `c51c9632`); SRAD +10.33 (11-03, `c51c9632`); TRI -9.87 (11-03, `c51c9632`); BKNG +9.83 (11-03, `7701d3bc`); SHC -9.64 (11-03, `c51c9632`); CAR +9.58 (11-03, `7701d3bc`); MMM +9.55 (11-03, `7701d3bc`); GXO +9.48 (11-03, `7701d3bc`); ALMR -9.36 (11-03, `7701d3bc`); SYY -9.33 (11-03, `c51c9632`); KAI +9.11 (11-03, `7701d3bc`); GRAB +9.09 (11-03, `c51c9632`); NVTS +9.00 (11-03, `7701d3bc`); OTTR -8.85 (11-03, `c51c9632`); ZBRA -8.76 (11-03, `c51c9632`); SHOP -8.74 (11-03, `c51c9632`); DD +8.61 (11-03, `c51c9632`); PAYP +8.50 (11-03, `7701d3bc`); ATRC +8.48 (11-03, `7701d3bc`); LTM +8.37 (11-03, `7701d3bc`); MDGL -8.08 (11-03, `c51c9632`); RVTY +7.84 (11-03, `c51c9632`); DNLI +7.76 (11-03, `7701d3bc`); PACS +7.67 (11-03, `7701d3bc`); SSRM +7.61 (11-03, `7701d3bc`); RYTM -7.49 (11-03, `c51c9632`); TLN +7.29 (11-03, `c51c9632`); MTDR -7.25 (11-03, `7701d3bc`); HGTY +7.17 (11-03, `c51c9632`); BALL -7.14 (11-03, `c51c9632`); ETN +7.00 (11-03, `c51c9632`); ULS +7.00 (11-03, `c51c9632`); ADM -6.82 (11-03, `c51c9632`); TFPM +6.69 (11-03, `7701d3bc`); PRU +6.58 (11-03, `7701d3bc`); APTV -6.53 (11-03, `c51c9632`); SDRL -6.48 (11-03, `7701d3bc`); FRSH -6.29 (11-03, `7701d3bc`); NPO +6.06 (11-03, `c51c9632`); SMCI -5.70 (11-03, `7701d3bc`); KDP -5.65 (11-03, `c51c9632`); OVV -5.61 (11-03, `7701d3bc`); LBTYK +5.51 (11-03, `c51c9632`); TOST +5.49 (11-03, `7701d3bc`); AVA +5.41 (11-03, `7701d3bc`); KMX -5.39 (11-03, `c51c9632`); RRR -5.31 (11-03, `7701d3bc`); ANET +5.04 (11-03, `7701d3bc`).
- **Window closes 2026-11-17 — 124 identities:** CAI -21.64 (11-04, `f5359185`); BROS -21.41 (11-04, `f5359185`); MGNI +20.75 (11-04, `f5359185`); ARQT -20.70 (11-04, `f5359185`); EPAM +20.63 (11-04, `f5359185`); RELY -20.42 (11-04, `f5359185`); LOPE -18.86 (11-04, `f5359185`); MDLN +18.36 (11-04, `7701d3bc`); TTAM -18.32 (11-04, `f5359185`); DAVE -18.11 (11-04, `f5359185`); LIVN +17.88 (11-04, `7701d3bc`); MTRN -17.66 (11-04, `7701d3bc`); BTU -17.62 (11-04, `7701d3bc`); TRMB -17.31 (11-04, `7701d3bc`); GRAL -17.07 (11-04, `f5359185`); POWI -17.01 (11-04, `f5359185`); FIG -16.67 (11-04, `f5359185`); VRDN +15.51 (11-04, `7701d3bc`); DDOG -14.42 (11-04, `7701d3bc`); TREX +14.30 (11-04, `7701d3bc`); PGNY +14.19 (11-04, `f5359185`); SNAP -14.02 (11-04, `f5359185`); KMT -13.92 (11-04, `7701d3bc`); EXPE -13.74 (11-04, `f5359185`); NGVT -13.59 (11-04, `f5359185`); PFGC +13.53 (11-04, `7701d3bc`); ZBH +13.49 (11-04, `7701d3bc`); SEZL +13.40 (11-04, `f5359185`); NWSA -13.35 (11-04, `f5359185`); NWS -13.24 (11-04, `f5359185`); SWK +13.10 (11-04, `7701d3bc`); ARM -13.08 (11-04, `f5359185`); COHR -12.98 (11-04, `f5359185`); BRKR +12.90 (11-04, `7701d3bc`); COTY +12.68 (11-04, `f5359185`); ATHM +12.68 (11-04, `7701d3bc`); CDW +12.67 (11-04, `7701d3bc`); CYTK -12.66 (11-04, `f5359185`); CVS -12.53 (11-04, `7701d3bc`); STM -12.39 (11-04, `f5359185`); SEI -12.30 (11-04, `f5359185`); RUN +12.29 (11-04, `f5359185`); SMMT -12.24 (11-04, `f5359185`); MELI -12.05 (11-04, `f5359185`); SITM -11.97 (11-04, `f5359185`); RVMD -11.04 (11-04, `f5359185`); W +11.00 (11-04, `7701d3bc`); LUMN -10.96 (11-04, `f5359185`); AVNT +10.66 (11-04, `7701d3bc`); LB -10.66 (11-04, `f5359185`); Z -10.65 (11-04, `f5359185`); CGNX -10.50 (11-04, `f5359185`); VERX +10.49 (11-04, `f5359185`); VIAV -10.48 (11-04, `f5359185`); SLF -10.37 (11-04, `f5359185`); AMC -10.19 (11-04, `f5359185`); CAMT -9.71 (11-04, `7701d3bc`); LMND -9.63 (11-04, `f5359185`); RIOT +9.63 (11-04, `7701d3bc`); CWK +9.62 (11-04, `7701d3bc`); IOND -9.58 (11-04, `f5359185`); SEPN +9.57 (11-04, `7701d3bc`); QCOM -9.49 (11-04, `f5359185`); IPAR +9.48 (11-04, `f5359185`); ZG -9.40 (11-04, `f5359185`); MKSI -9.30 (11-04, `f5359185`); PENG -9.10 (11-04, `7701d3bc`); SMG +8.72 (11-04, `7701d3bc`); SEDG -8.70 (11-04, `7701d3bc`); RYN +8.63 (11-04, `f5359185`); OC +8.53 (11-04, `7701d3bc`); RCUS -8.39 (11-04, `f5359185`); PK -8.31 (11-04, `f5359185`); NVST -8.20 (11-04, `f5359185`); PLMR +8.07 (11-04, `f5359185`); WBI -8.03 (11-04, `f5359185`); ACHC +7.88 (11-04, `f5359185`); TKR -7.81 (11-04, `7701d3bc`); TGB -7.67 (11-04, `f5359185`); CVE -7.64 (11-04, `7701d3bc`); VECO -7.64 (11-04, `f5359185`); SNN +7.59 (11-04, `7701d3bc`); FCX -7.51 (11-04, `f5359185`); CXW -7.50 (11-04, `f5359185`); ALGT +7.43 (11-04, `f5359185`); CRL -7.27 (11-04, `7701d3bc`); SOBO -7.17 (11-04, `f5359185`); YPF -7.09 (11-04, `f5359185`); HRMY -7.05 (11-04, `7701d3bc`); ORCL -6.93 (11-04, `f5359185`); CPAY +6.78 (11-04, `f5359185`); LPG -6.78 (11-04, `f5359185`); PAYC -6.76 (11-04, `f5359185`); AAUC +6.76 (11-04, `f5359185`); WULF -6.62 (11-04, `7701d3bc`); PODD +6.56 (11-04, `7701d3bc`); SOLS -6.54 (11-04, `7701d3bc`); GWW +6.54 (11-04, `7701d3bc`); MCD +6.53 (11-04, `7701d3bc`); CG -6.53 (11-04, `f5359185`); WU +6.53 (11-04, `f5359185`); OGC +6.48 (11-04, `f5359185`); VCTR -6.47 (11-04, `f5359185`); INGM -6.43 (11-04, `f5359185`); VIR -6.37 (11-04, `f5359185`); AMPL -6.34 (11-04, `f5359185`); WES -6.32 (11-04, `f5359185`); EL +6.31 (11-04, `7701d3bc`); UWMC +6.29 (11-04, `7701d3bc`); NICE -6.29 (11-04, `7701d3bc`); NEOG -6.26 (11-04, `f5359185`); RGLD +6.18 (11-04, `f5359185`); CF +6.17 (11-04, `f5359185`); GFS -5.95 (11-04, `7701d3bc`); PCVX -5.72 (11-04, `f5359185`); RLAY -5.71 (11-04, `f5359185`); HST -5.67 (11-04, `f5359185`); LFST -5.49 (11-04, `f5359185`); AMCR -5.48 (11-04, `f5359185`); OPLN -5.45 (11-04, `7701d3bc`); HUBS -5.39 (11-04, `f5359185`); HCI -5.18 (11-04, `f5359185`); VSH -5.07 (11-04, `7701d3bc`); LMAT -5.04 (11-04, `f5359185`).
- **Window closes 2026-11-18 — 51 identities:** WRBY +22.50 (11-05, `f5359185`); ROAD -21.88 (11-05, `f5359185`); GIL -19.07 (11-05, `f5359185`); MTSI -18.35 (11-05, `f5359185`); SHOO -17.01 (11-05, `f5359185`); PBH -16.82 (11-05, `f5359185`); NTCT -16.46 (11-05, `f5359185`); DCO -15.24 (11-05, `f5359185`); U +14.93 (11-05, `f5359185`); ENHA +14.91 (11-05, `f5359185`); WMS -14.88 (11-05, `f5359185`); ROK -14.15 (11-05, `f5359185`); VCEL +13.85 (11-05, `f5359185`); NSIT -13.04 (11-05, `f5359185`); ARW -12.61 (11-05, `f5359185`); MH -11.99 (11-05, `f5359185`); ACMR -11.52 (11-05, `f5359185`); IRM -11.09 (11-05, `f5359185`); IOVA -11.03 (11-05, `f5359185`); CORZ -10.81 (11-05, `f5359185`); DNOW -10.74 (11-05, `f5359185`); TIC -10.09 (11-05, `f5359185`); UEC -9.87 (11-05, `f5359185`); FWONA +9.55 (11-05, `f5359185`); MAIR -9.28 (11-05, `f5359185`); CTRI -9.20 (11-05, `f5359185`); GEO -8.57 (11-05, `f5359185`); APPN +8.45 (11-05, `f5359185`); ZTS -7.95 (11-05, `f5359185`); FWONK +7.67 (11-05, `f5359185`); MRX -7.65 (11-05, `f5359185`); RL -7.35 (11-05, `f5359185`); BGC -7.19 (11-05, `f5359185`); TPR +7.07 (11-05, `f5359185`); IMAX -7.01 (11-05, `f5359185`); VRSK +6.88 (11-05, `f5359185`); PRVA +6.88 (11-05, `f5359185`); MDU -6.51 (11-05, `f5359185`); DYN -6.36 (11-05, `f5359185`); CNR -6.25 (11-05, `f5359185`); BOBS +6.22 (11-05, `f5359185`); VNT +6.17 (11-05, `f5359185`); SONY +6.13 (11-05, `f5359185`); AMLX -6.05 (11-05, `f5359185`); TRLV -6.03 (11-05, `f5359185`); LNC -5.87 (11-05, `f5359185`); IRON -5.78 (11-05, `f5359185`); OSCR -5.71 (11-05, `f5359185`); IBP -5.24 (11-05, `f5359185`); AAP -5.18 (11-05, `f5359185`); NVMI -5.10 (11-05, `f5359185`).

**The cap decides nothing W2 owns this cycle.** Ranked and below-cap identities share one fate unless the router flips. W4 decides under §C whether to carry the 327 below-cap names into the overflow block.

### Not rankable — floor-clearing items D1 did not route: 0

Every floor-clearing `passed[]` item this cycle is `b_eligible = true` with a resolved anchor. D1's declines (ANCHOR_UNRESOLVED, DAY2_EVENT_PRIOR, POST_MOVE_EVENT, common-driver and deal-pinned) sit in its rejected sets, and W2 does not re-judge them.

### Context only — below the floor — 4 items

TECK (−4.88%), EXEL (+4.82%), SAN (−4.77%) and OMF (−4.70%), all in `e2dfa715`, with `below_spec_floor = true`.

### Identities EXCLUDED before enrichment — 0

## Rev 49 instrument eligibility and Criterion 5

- **Rev 49 eligibility:** D1 applied it on every row (US-primary common shares eligible regardless of domicile; foreign ADRs/ADSs need ≥$10B; every instrument needs ≥$2B cap and ≥$10M 30-day ADV). W2 does not re-judge it.
- **Criterion 5:** no Strategy A position is open, so B criterion 5 excludes no name.

---

## POST-EVENT TRAJECTORY — re-sourced from D2's `CLOSED-WINDOW COHORT NOTE` series

**Definition.**
- **Source of record:** D2's `CLOSED-WINDOW COHORT NOTE` series in `Watchlist.md`'s "Strategy B new-entry candidates" section. This cycle reads the four notes dated 11-01, 11-02, 11-04 and 11-05, all on or after W2's previous completed run date. No D2 note is dated 10-30, 10-31, 11-03 or after 11-05: D2's 11-03 slot was lost to the BigQuery de-auth, and D2 has not run since 11-05.
- **Dedupe:** on ticker + `qualifying_event_date`, against every annotation already published. That leaves **35 new rows, with 0 overlaps and 0 internal duplicates.**
- **`gap_intact_pct`** follows the 2026-W38 definition: (window-close close − pre-event close) ÷ (event-session close − pre-event close) × 100.
- **Basis:** every annotation prints all three closes, so every row is **`basis: closes`**, and each row's stated m and d reproduce from its closes. None is UNMEASURED.
- **Grouping:** the 11-05 note says nine rows (KALU, OII, GGG, LRCX, HXL, LBRT, META, BBT, FR) share one session, the 10-21 after-close prints, and are "not nine independent observations". Those nine are labelled shared. D2 names no other shared-catalyst cohort; its 11-02 and 11-04 notes caveat their rows as "not fully independent" without grouping them, so they are recorded as independent with that caveat.
- **Bar-date note (D2's, copied):** SPCX, SMCI, WFRD and NFLX carry qed 10-20 with the move realized on the 10-21 bar, and the nine shared rows carry qed 10-21 with the move on the 10-22 bar. Each row uses its own qed and window close of record.

**This is a FIXED-HORIZON series.** It has one observation per identity, taken at that identity's own window close. **It is not a continuation of, and must not be spliced onto, the retired 2026-W29..W38 COMMON-DATE cross-section.** The within-name panel that ended 2026-09-18 is cited by reference (2026-W39 findings) and is not re-published.

### Aggregate, offered only beside the per-ticker rows that follow

| Statistic | Value |
|---|---|
| New observations | 35 |
| Median `gap_intact_pct` | 100.96 |
| ≥ 100 (move fully intact or extended) | 19 |
| < 0 (move fully reversed and beyond) | 7: DDOG, GM, VICR, SPCX, SMCI, MHO, ASST |
| Median with the nine shared rows collapsed to one observation (27 observations) | 100.96 |
| UNMEASURED | 0 |

W44's 43 rows had a median of 83.78. The two cycles are different identities at different horizons, so the difference is a record, not a trend.

### Per-ticker series (35 new annotations, in D2 note order)

| # | Ticker | `qualifying_event_date` | Window close | m (event-session move, %) | d (post-window drift, %) | `gap_intact_pct` | Basis | D2 grouping | D2 note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | IRON | 2026-10-19 | 2026-10-30 | 38.86 | 2.4199 | 108.65 | `closes` | independent | 2026-11-01 |
| 2 | CLF | 2026-10-19 | 2026-10-30 | 16.34 | 1.0638 | 107.58 | `closes` | independent | 2026-11-01 |
| 3 | MANE | 2026-10-19 | 2026-10-30 | 12.37 | 14.2378 | 229.35 | `closes` | independent | 2026-11-01 |
| 4 | DDOG | 2026-10-19 | 2026-10-30 | 5.36 | -9.6366 | -89.36 | `closes` | independent | 2026-11-01 |
| 5 | ARQT | 2026-10-19 | 2026-10-30 | 10.65 | 0.5644 | 105.86 | `closes` | independent | 2026-11-01 |
| 6 | BRZE | 2026-10-20 | 2026-11-02 | 51.7 | 0.2194 | 100.64 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 7 | HAS | 2026-10-20 | 2026-11-02 | 11.2 | 8.0716 | 180.15 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 8 | EFX | 2026-10-20 | 2026-11-02 | 11.33 | 9.0461 | 188.87 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 9 | LION | 2026-10-20 | 2026-11-02 | 14.41 | -0.0823 | 99.35 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 10 | PAC | 2026-10-20 | 2026-11-02 | 7.05 | 8.2609 | 225.42 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 11 | GM | 2026-10-20 | 2026-11-02 | -6.84 | 16.6688 | -127.03 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 12 | MMM | 2026-10-20 | 2026-11-02 | 5.78 | 4.0789 | 174.68 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 13 | GPC | 2026-10-20 | 2026-11-02 | -5.12 | 0.8824 | 83.63 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 14 | MSCI | 2026-10-20 | 2026-11-02 | 5.0 | 7.6932 | 261.42 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 15 | VICR | 2026-10-20 | 2026-11-02 | 7.06 | -14.2892 | -116.72 | `closes` | independent (D2: ten catalysts, one calendar window/earnings tape, "not fully independent" | 2026-11-02 |
| 16 | UCB | 2026-10-20 | 2026-11-02 | 5.0 | 6.1178 | 228.40 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 17 | SPCX | 2026-10-20 | 2026-11-02 | 7.79 | -14.3996 | -99.13 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 18 | SMCI | 2026-10-20 | 2026-11-02 | 9.55 | -14.4223 | -65.48 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 19 | WFRD | 2026-10-20 | 2026-11-02 | 7.75 | 4.1057 | 157.07 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 20 | NFLX | 2026-10-20 | 2026-11-02 | -5.31 | -4.1513 | 173.97 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 21 | LAD | 2026-10-21 | 2026-11-03 | -10.15 | 11.0133 | 2.50 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 22 | MHO | 2026-10-21 | 2026-11-03 | -8.08 | 12.9779 | -47.70 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 23 | T | 2026-10-21 | 2026-11-03 | -6.45 | -2.3733 | 134.44 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 24 | ROIV | 2026-10-21 | 2026-11-03 | 5.38 | -2.0652 | 59.57 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 25 | FLY | 2026-10-21 | 2026-11-03 | 8.28 | -3.624 | 52.59 | `closes` | independent (D2: ten catalysts, shared earnings-season window, "not fully independent") | 2026-11-04 |
| 26 | ASST | 2026-10-21 | 2026-11-03 | 13.64 | -32.813 | -173.44 | `closes` | independent (separate day: 10-21 pre-open 8-K, crypto-beta) | 2026-11-05 |
| 27 | KALU | 2026-10-21 | 2026-11-03 | -25.31 | 2.7046 | 92.02 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 28 | OII | 2026-10-21 | 2026-11-03 | -16.94 | 4.2327 | 79.25 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 29 | GGG | 2026-10-21 | 2026-11-03 | -15.32 | -0.1732 | 100.96 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 30 | LRCX | 2026-10-21 | 2026-11-03 | -11.76 | 0.2477 | 98.14 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 31 | HXL | 2026-10-21 | 2026-11-03 | -9.54 | 0.6891 | 93.47 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 32 | LBRT | 2026-10-21 | 2026-11-03 | -7.85 | -3.7061 | 143.51 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 33 | META | 2026-10-21 | 2026-11-03 | -6.98 | -4.2876 | 157.16 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 34 | BBT | 2026-10-21 | 2026-11-03 | 6.96 | 3.005 | 146.15 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |
| 35 | FR | 2026-10-21 | 2026-11-03 | -6.92 | -0.7054 | 109.49 | `closes` | shared: 2026-10-21 after-close prints, repriced 2026-10-22 (D2: "nine of them are the same | 2026-11-05 |

### Not yet in the series — PENDING D2 ANNOTATION, and the named GAPs

- **PENDING D2 ANNOTATION, as D2's most recent note (11-05) states it, not re-derived:** a backlog of **45** closed-but-unannotated windows, with the next-oldest close date **2026-11-03**. That note predates the 11-06 closes, so 18 more windows have closed since (window close 11-06). As of this run **63 identities are PENDING**: CSX and LUV (closed 11-03); 33 that closed 11-04; 10 that closed 11-05 (CART, FCNCA, FLG, GMAB, INFY, LKQ, RITM, TEM, TNGX, WULF); and 18 that closed 11-06 (AGYS, AMKR, ARE, ASST, CDNS, CLS, CTOS, ESLT, HWKN, NE, NUE, ORKA, PII, PPTA, RRC, SGRY, SSD, WELL). They are pending, not gaps and not zeros. D2's Sunday run tonight is the next opportunity.
- **Named GAPs (intake identity with no index row at all): none new.** All 99 identities whose windows closed by 11-06 have index rows. This was checked as a text match on ticker + qed. The earlier GAPs are unchanged: EFXT, CRWV 10-14, BULL, SPOT 10-07, ARGX and ECHO.

### Repeat names — tickers already in the fixed-horizon series, each on a distinct event

- **In the 35 new rows:** ARQT and T (already in the series from W44) and BRZE, VICR and META (already in the series from W43). Each is a different qed, so none is a duplicate.
- **In this week's intake:** ARQT appears again with qed 11-04 (−20.70%, below-cap). LKQ's and GMAB's W44 identities are now pending annotation.

### What W2 adds from its own durable record: the GRADING OUTCOME series, itemized per ticker

The router was DO-NOT-ACTIVATE throughout, `events.queue_events` holds zero B `thesis-construction` rows (the last is 2026-08-03), and no drain occurred:

| Cohort | Identities | Status on 2026-11-08 |
|---|---|---|
| W44 | 183 | 39 closed 11-04 to 11-06 and **expired ungraded**. 144 are still open: 35 close 11-09, 64 close 11-10 and 45 close 11-11. |
| W43 | 60 | **All expired ungraded.** The last 54 closed between 11-02 and 11-04. |
| W42 | 34 | All expired ungraded (unchanged). |
| W41 | 20 | All expired ungraded (unchanged). |
| W40 | 22 | All expired ungraded (unchanged). |

**Lineage tally:**
- **175 identities have expired ungraded:** W40 to W43 = 136, plus 39 from W44.
- **144 W44 identities and 342 W45 identities are open.**
- **No published B identity has ever been evaluated against B's entry criteria.**
- **On the earliest possible flip timetable (first reachable session 11-10), 109 of W44's 144 open identities are still reachable:** those closing 11-10 and 11-11. The 35 that close 11-09 are not. All 342 W45 identities are reachable.

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, record-read only

**S1 — peak earnings volume, skewed down.**
- 342 routable identities, against 183 in W44, 60 in W43 and 34 in W42. The 11-04 row alone carries 133.
- **Direction:** 204 down and 138 up. This reverses W44's 108 up and 75 down. Within the ranked 15, 9 are down and 6 are up.
- The cohort is almost entirely own-issuer Q3 releases: roughly 330 of 346 items by D1's event text.
- **Non-earnings anchors in the ranked 15:** NRIX (Sanofi terminated a partnered Phase 1 program, 8-K 8.01). VCYT's 8-K also carries Item 8.01 beside its 2.02.

**S2 — the market-wide 11-05 session sits inside this intake.** On 11-05 SPY fell 4.41% and SMH fell 11.21% (D2's figures in its 11-05 router record). This is the same session that moved VIX to HIGH and opened `div-B-202611-2`. The 51 identities with qed 11-05, plus the 11-04 after-close names measured on 11-05 (VCYT, APP, FSLY, ECPG and ADMA in the ranked 15), carry their own event *and* that tape. D1 handled common drivers at screen time; W2 does not re-judge them. The point is structural: for B's information-versus-sentiment mechanism, a measured move on a −4.4% index session overstates the event-specific component in an unknown proportion, and index mode cannot separate the two. That is D2's question at thesis construction, if the router flips.

**S3 — noisy names.** D1 records "other ≥5% sessions in the prior 10" on most items. Several ranked names carry several: APP 3, FSLY 5, HUT 4 and SITM 6 (below-cap). For these names the event move is one of several in the window.

**S4 — anchor and measurement quality.**
- **Better on checks:** 346 of 346 items carry both closes, the arithmetic is clean, and all 17 actionable-side chain hits resolve to after-close releases.
- **Weaker on provenance:** the 11-03 row was screened degraded (BigQuery de-authed, D1's durable chain check skipped), and the 11-04 and 11-05 rows were landed by §57 repair, not by D1's own run. All three were read back intact, and the 11-05 row carries D1's original call digest. No index row was broker re-measured.
- **After-close measurement:** 11 of the ranked 15 are after-close releases measured on the next session (the bold cells).

**S5 — instrument-rail and floor-edge items for D2 at thesis construction, none W2's to settle.** Near the 5% floor: LYB +5.00, ATR +5.02, LMAT −5.04, ANET +5.04 and CE +5.05 clear it by less than 0.05 points. Names stated near the $2B cap rail are D1's eligibility call.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-11-05).**

The ranked list is the 15-item table in PART 1. Every row carries:
- the tier field (e), set strictly by rank (1–5 `top-5`, 6–15 `rest`);
- `qualifying_event_date` (f);
- the event-day move;
- the window close (d) and the sessions left;
- the originating D1 id (g);
- a one-line event (b).

The 327 eligible identities below the cap follow it, marked `below-cap`.

Index mode skips the four per-candidate research steps: mispricing direction and magnitude, retrieved comparables, information-versus-sentiment, and convergence indicators. For W4's deterministic handoff, fields (a) and (c) read **"not assessed — INDEX MODE"** for every candidate. Fields (b), (d), (e), (f) and (g) are in the tables.

The cohort work is not skipped. The fixed-horizon trajectory series, the structural findings and the grading-outcome series are all given in full above.

## ROUTING

Route the 15 ranked names to `Watchlist.md`'s **"Strategy B watch overflow"** section, marked **`Router-gated, not rank-gated.`**, exactly as W4 §C directs. **W4 §C's top tier is the five `top-5` rows: VCYT, NRIX, APP, KD and DOX.**

- The 327 below-cap names are at W4's discretion.
- **Zero `PENDING_ANALYSIS` thesis-construction enqueues are owed while B is DO-NOT-ACTIVATE.** That includes the held `— PENDING div-B-202611-2` value.
- **For W4 and for whatever drains a flip:**
  - All 15 ranked windows are open on the earliest possible flip write (AR_orc, 11-09 18:35 MT).
  - RDDT and INTC (both close 11-11) have the fewest sessions left after it: two, 11-10 and 11-11.
  - The ranked 15 close between 11-11 and 11-17.

---

## FINDINGS — zero alerts filed, zero queue items, three referrals closed by their owners

**`ops.alerts`:** none filed. Before filing, a check found no open `info` row on any W2 surface. The free checks were clean, and no out-of-scope defect was found.

**`events.queue_events`:** none. Both free checks were clean (no `rescreen-` item owed), and no thesis-construction enqueue is owed under index mode.

**Referral status — every W2 referral is now closed:**
- `dfb0f575` (deal-pinned routing, owner D1): **FIX**, resolved 11-02. The §19 Deal-pinned rail landed (PR #139), and this run applied it.
- `143c2aaf` (two shock midpoints, owner W5): **REJECT (superseded)**, resolved 11-02. W5 declared the two baselines by design under Rev 52.
- `0a40c378` (M1R blinding via commit subjects): **FIX**, resolved 11-02 by a read-scope rule that bars M1a and M1R from reading other routines' commit subjects.

**Observed and explained, so nothing was filed:** D1's own 11-04 and 11-05 run notes say their single-name rows were NOT landed, and yet both rows exist. They were landed by interactive triage under RUNBOOK §57 on 11-05. The in-run alerts `2c1417f8` and `4ad2f90c` are resolved, with the landing recorded in their `resolved_note`.

---

## HONEST LIMITS OF THIS RUN

- **None of the 342 is broker-verified.** They are arithmetic-checked only. D2's index rows copy D1's figures, so the precedence rule had nothing to apply.
- **The fixed-horizon series is D2's measurement, published by record read.** W2 re-verified no close against a bar. Every row reproduces from its three printed closes.
- **The flip timing is inferred from the queue payload's due dates and `ops/cadence.yaml`, not observed.** A late or skipped AR_att/AR_orc fire moves it. W2 makes no forecast of the verdict and does not pre-empt AR_orc.
- **The 11-06 session is uncovered**, and so are the 11-05 after-close reporters. Both belong to D1 tonight.
- **The 11-03 screen was degraded at source.** Only the 49 IBKR-confirmed names of 146 discovery-rail clearers were judged that day. W2 cannot see whether anything material sat in the unconfirmed remainder, and it does not re-screen.
- **The durable decision row is lighter than W44's.** `d7974612` carries the ranked 15, the 35 trajectory rows and all counts, but only the *count* of below-cap names. Their full list is in this file and in D2's index rows. The first two attempts to write the full-list row did not land: a sub-agent was stopped by a provider safeguard, and the split call was refused twice for digest mismatch. Nothing partial was written.

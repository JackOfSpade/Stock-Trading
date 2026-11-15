2026-W46

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-11-15 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W46
**Intake watermark:** 2026-11-08T09:35:25Z, this routine's own prior completion. **Catch-up window:** 6.94 days, which is the weekly norm, so no `CATCHUP` token is owed.
**Durable record:** `events.decision_log` `9af4cc58-aa06-4fe3-a606-f813978ff9b4` (`entry_type='post-event-enrichment'`, strategy B) · zero `events.queue_events` items · zero `ops.alerts` rows filed.

**SCREEN MODE: FULL (B router ACTIVATE as of 2026-11-09).** This is the first full-depth cycle after eleven consecutive index-mode cycles.

**What decides this cycle: the router flipped, and then the fleet went dark for three trading days.**
- **The flip.** On 11-09 D2's item 4 measured out-of-cycle trigger (re-risking: `vix_regime_exit_high` + `breadth_mom_rise_gt10`, review `79dab266`) wrote **B = ACTIVATE** (`state.current_regime` event `461ba0ee`, 23:22Z). The technical line was ACTIVATE (SPY NEUTRAL 752.69, VIX NORMAL 19.92, breadth HEALTHY 63.14). No reconciliation override binds B (shock_overlay latent), and the standing fundamental call is ACTIVATE (`310bd8ff`; re-stated `762b040e`). The judged state superseded the held `— PENDING div-B-202611-2` value. AR_orc closed that review SUPERSEDED (`f78e6bf9`, 11-10 00:39Z).
- **The drain on bind.** The same evening D2 enqueued **451** B `thesis-construction` items from the watch overflow, all due 11-10 (alert `eddabe43`, `b_overflow_drain_volume`, open).
- **The blackout.** `state.fleet_blackout_days` lists **11-10, 11-11 and 11-12**: every expected routine (D1, D2, D2a, D3, OPS0, OPS1, OPS2, SL3) logged zero rows. No routine logged a row on 11-13 or 11-14 either; Friday and Saturday are not expected days for the daily cohort. `ops.run_log` shows the last D1, D2 and D2a completions on 11-09. This is already surfaced (blackout rows, `queue_driven_missed_fire` warnings 11-12 to 11-14, `constant_tuning_loop_heartbeat_missing` `d5b4b41b`, `staleness` critical `68d5d95b`), so W2 files nothing on it.
- **Consequences for this file.**
  - None of the 451 drain items has a terminal status. 186 of them closed their windows between 11-10 and 11-13 **ungraded**; 265 remain open, closing 11-16 to 11-18.
  - There is **no D1 single-name screen for the 11-10, 11-11, 11-12 or 11-13 sessions.** The intake ends at the 11-09 session. Those four sessions belong to D1's catch-up path, not to W2 (PART 1 forbids covering them).
  - Every ranked window below closes 11-18 to 11-20. **From the next trading day, 11-16, the ranked windows have 3 to 5 sessions left.**

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**:
- It pulled no broad bars, enumerated no movers and repeated no event search.
- It did not re-judge D1's §19 significance verdicts or D1's Rev 49 eligibility calls.
- **It pulled no price bars or quotes of any kind.** `scripts/check_routine_scope.py` enforces that boundary.
- The intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion.

**Metered external calls: 32 Parallel `web_search` calls, zero `web_fetch`, zero FMP, zero HF, zero IBKR.** All 32 came from the three per-candidate enrichment sub-agents. No call failed and the SEARCH GUARD never tripped. Each call is logged to `ops.web_calls` with its verbatim target.
- Sub-agents were barred from fetching prices. Any post-event price cited below appeared incidentally in a news excerpt; it is labelled as such and is not a measurement.
- The precedent retrieval used the free `analytics.find_precedents()` in BigQuery. Several of those calls hit BigQuery's concurrent-embedding quota and were re-run one at a time. One (IBRX's dedicated query) did not succeed, and that gap is stated in its block.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`:

| Field | Value |
|---|---|
| value | `ACTIVATE` |
| as_of | 2026-11-09 |
| event | `461ba0ee-0801-4fe5-b2c2-521858d1dd5b` (D2, 23:22:35Z) |
| divergence | none open; `div-B-202611-2` closed SUPERSEDED (`f78e6bf9`) |
| previous B row | `DO-NOT-ACTIVATE — PENDING div-B-202611-2` (D2, 11-05, `89f2506e`) |

PART 2 therefore runs at **FULL DEPTH, regardless of B's NAV**, as the router clause directs.

---

## WINDOW ARITHMETIC

There is one convention: INCLUSIVE. The qualifying event date is trading session 1, and the window closes on the 10th trading session inclusive. Trading days were verified against `state.market_calendar`: there is no holiday between 11-05 and 11-20; Thanksgiving (11-26) is the first. All window-close dates below match D2's index rows exactly.

| Qualifying event date | Window closes | Sessions left from 11-16, inclusive | Rankable identities |
|---|---|---|---|
| 2026-11-05 | 2026-11-18 | 3 | 45 |
| 2026-11-06 | 2026-11-19 | 4 | 20 |
| 2026-11-09 | 2026-11-20 | 5 | 20 |

**How the move is measured:** for an after-close release, the move is measured on the NEXT session (the reaction session). The ranked table marks that session in **bold** where it differs from the qualifying date. 47 of the 85 items are after-close releases and 38 are pre-open; none is intraday.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Two `single-name-move` rows have landed since the watermark. Neither is superseded, and no correction row references either. Together they carry **85** `passed[]` items, which are 85 distinct ticker + `qualifying_event_date` identities. All 85 clear B's spec floor, all are `b_eligible = true` with a resolved anchor, and all carry both recorded closes.

| Decision id | Session screened | `passed[]` items | Note |
|---|---|---|---|
| `d564cda0-bf53-4045-96d8-ccfe54f4cb02` | 2026-11-06 (Fri), plus the 11-05 after-close reporters | 63 | Hosted inline by OPS2 for the 11-08 D1 slot, whose own session went quiet at 16:36 MT before writing this row. `screen_mode` router-gated (the router flipped later that day). |
| `9f5c6b11-5ff1-4e65-b563-d0290627864d` | 2026-11-09 (Mon) | 22 | `screen_mode` router-gated (written 22:40Z, before D2's 23:22Z flip). D1 notes a **broad relief rally**: median discovery move +2.27%, and most ≥5% moves without an own-event filing were left ANCHOR_UNRESOLVED as market/sector beta. |

- **The qed split:** 45 items with qed 11-05 (all after-close, measured 11-06); 20 with qed 11-06 (18 pre-open; ASTS and AGLT after-close, measured 11-09); 20 with qed 11-09 (all pre-open).
- **Deal-pinned rail (Operating_Protocols.md §19):** no passed item's `reason` begins `deal-pinned:`, and none records a signed all-cash deal with a pinned price. The only deal-pinned name, SGRY (a signed $25.00 all-cash deal, trading above the offer), sits in `9f5c6b11`'s `rejected_notable` with `b_eligible = false`. It is not intake.
- **Not intake:** the `sector-move` rows `cb1d002c` and `8327041f`.
- **Since the watermark, no B-relevant D1 candidate or action record exists** beyond these two screen rows.
- **Screened degraded at source, recorded by D1:**
  - **`d564cda0`:** 15 unmeasured symbols; 384 screener rows without market cap, so they were not screened; the 4.5–5.0% near-floor band was not IBKR-checked.
  - **`9f5c6b11`:** 10 unmeasured symbols; 1,316 rows without market cap; AMX dropped in error by the name filter.
  - W2 cannot see what sat in those remainders, and it does not re-screen them.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

- **Queue rows:** D2's 451 drain rows carry `payload.qualifying_event_date`. A field match on ticker + that date against all 85 intake identities finds **zero** coincidences.
  - Four tickers do appear in both, each on a different qed: DXPE (queue qed 10-28) and VIR, VRDN and WULF (queue qed 11-04). Each is a distinct event, and the later event stays eligible.
  - No other B `thesis-construction` row, open or terminal, matches an intake identity.
- **Decision rows:** no B thesis, GO or NO-GO row exists for any intake identity.
- **Open Strategy A positions:** none. `state.current_positions` holds Strategy D tranches only: AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM and UBER.
- **Expired windows:** none. The earliest close is 11-18.

**Identities EXCLUDED before enrichment: 0.**

## RECORDED-FIGURE ARITHMETIC CHECK — 85 of 85 items, zero mismatches

For every item, `metric_pct` equals `(event_close / prior_close − 1) × 100` to the recorded 4-decimal precision. No `rescreen-` item is owed.

## CROSS-ROW CLOSE-CHAIN CHECK — 2 hits on the actionable side, 0 defects

The search covered every `single-name-move` row landed since 2026-10-27 (11 rows, 3,118 items and tuples). That includes the `passed`, `rejected_notable` and `rejected_compact` tuples on the same name and the same `qualifying_event_date`. Each pair was tested for `other.event_close == this.prior_close` and for `other.prior_close == this.event_close`.

- **2 hits on the actionable side, and both are after-close releases, so neither is a defect.**
  - **GMED:** an `f5359185` `POST_MOVE_EVENT` tuple's `event_close` 81.44 equals the item's `prior_close`. The release was after the close on 11-05 (21:09Z).
  - **ASTS:** a `d564cda0` `POST_MOVE_EVENT` tuple's `event_close` 32.33 equals the item's `prior_close`. The release was after the close on 11-06 (22:00Z).
  - In each case the intake item legitimately reports the reaction session. This is the after-close case the rule names, not the IONQ `6e179f3c` continuation-leg pattern.
- **23 further hits are on the other side:** later-session `9f5c6b11` tuples whose `prior_close` equals an intake item's `event_close`. These are continuations forward from the anchor and are not actionable.

**This is a record read, not a re-measurement, and a clean pass is not a clearance.** Many tuple closes are D1's Nasdaq discovery closes, not IBKR closes.

## MEASUREMENT OF RECORD — D1's figures, because D2 re-measured none of them

The D2-REMEASURED FIGURE PRECEDENCE rule was applied and **changes nothing this cycle.** All 85 identities have a D2 index row in `Watchlist.md`'s "Strategy B new-entry candidates", added 11-09. Every one states that its figures are D1's and were not re-measured on IBKR, and D1 and D2 agree on figure and window close for all 85. The rank key is therefore the D1 figure. It is arithmetic-consistent, but it has not been broker-verified at the index-row stage. Broker re-measurement belongs to D2 at Strategy-B thesis construction (D2 STEP 1), which a FULL-mode router now reaches.

## Items preserved from D1

### Rankable — clears BOTH D1's §19 significance judgment AND B's frozen ≥5% spec floor — 85 identities, 15 ranked at the cap

Ranks 1–5 carry tier `top-5`, and ranks 6–15 carry `rest`. There is no tie at the cap: rank 15 IBRX is −17.6607, and rank 16 FIVN is −17.6333.

| Rank | Tier (e) | Ticker | `qualifying_event_date` (f) | Move % | Measured on | Window close | Days left (d) from 11-16 | Originating D1 id (g) | Event (one line, factual) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `top-5` | KRMN | 2026-11-05 | +42.1315 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 FY26 results (8-K 2.02): revenue $201.6M (+66%), FY26 revenue guide raised to $755–760M; after-close (EDGAR 21:17Z) |
| 2 | `top-5` | FROG | 2026-11-05 | +35.3256 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.02): revenue $179.2M (+31%) vs ~$166M consensus, FY26 guide raised to $680–682M; after-close (EDGAR 21:08Z) |
| 3 | `top-5` | IRTC | 2026-11-05 | −30.7013 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.02): revenue $221.6M in line; FY guide raise includes ~$16M acquired revenue; Zio MCT FDA filing moved to 2027; after-close (EDGAR 21:15Z) |
| 4 | `top-5` | TMDX | 2026-11-05 | +27.9211 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.02): revenue $203.0M (+41%) vs ~$178M consensus, FY26 guide raised; after-close (EDGAR 21:02Z) |
| 5 | `top-5` | FRVO | 2026-11-09 | +26.0244 | 11-09 | 2026-11-20 | 5 | `9f5c6b11` | Q3 results (8-K 2.02) with a Google 15-year 396 MW PPA; IPO lock-up expiry the same day; pre-open (EDGAR 13:37Z) |
| 6 | `rest` | QNT | 2026-11-05 | +25.9893 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.02): revenue $9.05M vs ~$8.05M consensus, FY26 outlook raised to $31–34M; after-close (EDGAR 21:03Z) |
| 7 | `rest` | IONQ | 2026-11-05 | +23.4204 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.01/2.02/3.02/7.01): revenue $173.8M, FY26 guide raised to $505–515M; Elisity all-stock close; after-close (EDGAR 21:07Z) |
| 8 | `rest` | IONS | 2026-11-09 | −21.3597 | 11-09 | 2026-11-20 | 5 | `9f5c6b11` | Q3 results (8-K 2.02): Tryngolza FY26 sales guide cut to ~$50M from $100–110M; pre-open (EDGAR 12:00Z) |
| 9 | `rest` | DKNG | 2026-11-06 | −21.3010 | 11-06 | 2026-11-19 | 4 | `d564cda0` | Q3 results (8-K 2.02): revenue miss, FY26 adj. EBITDA guide cut to $175–275M from $700–900M; EDGAR acceptance 11-06 11:50Z (see the timing flag below) |
| 10 | `rest` | IREN | 2026-11-05 | +20.0222 | **11-06** | 2026-11-18 | 3 | `d564cda0` | FQ1'27 results (8-K 2.02): revenue $228M (+66% q/q); >$4B ARR go-live moved to Jan/Feb 2027; after-close (EDGAR 21:03Z) |
| 11 | `rest` | PRAX | 2026-11-09 | +19.9373 | 11-09 | 2026-11-20 | 5 | `9f5c6b11` | Q3 results / corporate update (8-K 2.02): reaffirmed PDUFA dates 2026-12-27 and 2027-01-29, ~$1.3B cash; pre-open (EDGAR 12:02Z) |
| 12 | `rest` | QXO | 2026-11-09 | +19.2042 | 11-09 | 2026-11-20 | 5 | `9f5c6b11` | Preliminary Q3 (8-K 2.02): net sales $4.90B (+79%, acquisition-driven), adj. EBITDA $557M; pre-open (EDGAR 11:02Z) |
| 13 | `rest` | TILE | 2026-11-06 | −18.7203 | 11-06 | 2026-11-19 | 4 | `d564cda0` | Q3 results (8-K 2.02/7.01): adj. EPS beat, revenue $366.7M below own range, FY sales guide cut; pre-open (EDGAR 11:44Z) |
| 14 | `rest` | AXON | 2026-11-05 | −18.1828 | **11-06** | 2026-11-18 | 3 | `d564cda0` | Q3 results (8-K 2.02): revenue $908.6M vs ~$934M consensus, FY26 and FCF guides cut, $1.2B more into Skydio; after-close (EDGAR 21:18Z) |
| 15 | `rest` | IBRX | 2026-11-09 | −17.6607 | 11-09 | 2026-11-20 | 5 | `9f5c6b11` | QUILT-2.005 Cohort A met its primary endpoint (8-K 7.01), then Q3 revenue $48.7M (−4% q/q) vs ~$59M consensus (8-K 2.02); pre-open (EDGAR 12:39Z) |

### BELOW THE CAP — 70 eligible identities (`below-cap`, not ranked)

Format: ticker, move %, (`qualifying_event_date` MM-DD, originating D1 id). Ordered by absolute move within each window-close date.

- **Window closes 2026-11-18 — 37 identities:** FIVN -17.63 (11-05, `d564cda0`); TEAM -16.15 (11-05, `d564cda0`); HALO -15.72 (11-05, `d564cda0`); WK -14.90 (11-05, `d564cda0`); NTRA -14.59 (11-05, `d564cda0`); LION +13.38 (11-05, `d564cda0`); DIOD +13.17 (11-05, `d564cda0`); GMED -12.76 (11-05, `d564cda0`); NMIH -11.84 (11-05, `d564cda0`); PLUS +11.74 (11-05, `d564cda0`); ABNB +11.67 (11-05, `d564cda0`); CENX +11.31 (11-05, `d564cda0`); STEP +10.84 (11-05, `d564cda0`); COMP +10.74 (11-05, `d564cda0`); ELVN +10.36 (11-05, `d564cda0`); MCHP -10.02 (11-05, `d564cda0`); NET +9.91 (11-05, `d564cda0`); SARO +9.21 (11-05, `d564cda0`); AUGO +9.19 (11-05, `d564cda0`); AGM -8.98 (11-05, `d564cda0`); FG +7.84 (11-05, `d564cda0`); VSAT +7.70 (11-05, `d564cda0`); IAG +7.20 (11-05, `d564cda0`); COGT +6.96 (11-05, `d564cda0`); AAOI +6.91 (11-05, `d564cda0`); AKAM +6.74 (11-05, `d564cda0`); CARG -6.67 (11-05, `d564cda0`); GRDN +6.32 (11-05, `d564cda0`); XRAY -6.24 (11-05, `d564cda0`); DXPE +5.88 (11-05, `d564cda0`); WSC +5.72 (11-05, `d564cda0`); CALY +5.72 (11-05, `d564cda0`); CLDX +5.66 (11-05, `d564cda0`); SKWD -5.50 (11-05, `d564cda0`); SBS +5.48 (11-05, `d564cda0`); TIGO +5.21 (11-05, `d564cda0`); KTOS +5.12 (11-05, `d564cda0`).
- **Window closes 2026-11-19 — 18 identities:** CGON +17.27 (11-06, `d564cda0`); BKD -16.65 (11-06, `d564cda0`); UI +15.29 (11-06, `d564cda0`); ASTS +14.10 (11-06, `9f5c6b11`); WULF +12.80 (11-06, `d564cda0`); AGLT -11.31 (11-06, `9f5c6b11`); VST +10.55 (11-06, `d564cda0`); ATMU +9.62 (11-06, `d564cda0`); ELAN +8.70 (11-06, `d564cda0`); CLMT -8.56 (11-06, `d564cda0`); ESNT -7.57 (11-06, `d564cda0`); MSGR +7.26 (11-06, `d564cda0`); STWD -6.44 (11-06, `d564cda0`); CHTR -6.19 (11-06, `d564cda0`); HUM +5.33 (11-06, `d564cda0`); MRNA +5.27 (11-06, `d564cda0`); UAA -5.21 (11-06, `d564cda0`); UA -5.04 (11-06, `d564cda0`).
- **Window closes 2026-11-20 — 15 identities:** IMVT +15.13 (11-09, `9f5c6b11`); VIA +12.80 (11-09, `9f5c6b11`); VIR +11.71 (11-09, `9f5c6b11`); FERG +11.22 (11-09, `9f5c6b11`); CNH +10.90 (11-09, `9f5c6b11`); CEG +10.46 (11-09, `9f5c6b11`); NRG +10.32 (11-09, `9f5c6b11`); MNDY -9.10 (11-09, `9f5c6b11`); KGS +7.20 (11-09, `9f5c6b11`); WTTR -6.86 (11-09, `9f5c6b11`); GCMG +6.24 (11-09, `9f5c6b11`); VRDN +5.97 (11-09, `9f5c6b11`); TGTX +5.93 (11-09, `9f5c6b11`); TNGX +5.77 (11-09, `9f5c6b11`); AMG +5.56 (11-09, `9f5c6b11`).

**Under an ACTIVATE router, W4 §C enqueues only the `top-5` rows.** `rest` and below-cap identities are not enqueued as thesis-construction rows. They stay on D2's index rows as context.

### Not rankable — floor-clearing items D1 did not route: 0

Every floor-clearing `passed[]` item this cycle is `b_eligible = true` with a resolved anchor. D1's declines (ANCHOR_UNRESOLVED, DAY2_EVENT_PRIOR, POST_MOVE_EVENT, common-driver and deal-pinned) sit in its rejected sets, and W2 does not re-judge them. The two `b_eligible = false` names, SGRY (deal-pinned) and AUGO's 11-06 later-day move, are both in `rejected_notable`.

### Context only — below the floor — 0 items

No passed item carries `below_spec_floor = true`. D1 dropped six names to below the floor on IBKR closes and did not pass them: VCRE, MP, BEN and WYNN in `d564cda0`, and CRL and ROIV in `9f5c6b11`.

### Identities EXCLUDED before enrichment — 0

## Rev 49 instrument eligibility and Criterion 5

- **Rev 49 eligibility:** D1 applied it on every row. US-primary common shares are eligible regardless of domicile; foreign ADRs/ADSs need ≥$10B; every instrument needs ≥$2B cap and ≥$10M 30-day ADV. W2 does not re-judge it. **One flag for D2 at thesis construction (rank 13, TILE):** D1 recorded TILE at $2.19B. Enrichment search excerpts put its post-drop cap at about $1.78–1.82B, below the $2B floor, and B tests the cap **at entry**. This is a third-party figure, not a measurement, and W2 does not settle it.
- **Criterion 5:** no Strategy A position is open, so B criterion 5 excludes no name.

---

## POST-EVENT TRAJECTORY — re-sourced from D2's `CLOSED-WINDOW COHORT NOTE` series

**Definition.**
- **Source of record:** D2's `CLOSED-WINDOW COHORT NOTE` series in `Watchlist.md`'s "Strategy B new-entry candidates" section. This cycle reads the **one** note dated on or after W2's previous run date (11-08): **D2's 2026-11-09 note.** No D2 note is dated after 11-09, because D2 has not completed since then (the blackout).
- **Dedupe:** on ticker + `qualifying_event_date`, against every annotation already published. That leaves **10 new rows, with 0 overlaps and 0 internal duplicates.**
- **`gap_intact_pct`** follows the 2026-W38 definition: (window-close close − pre-event close) ÷ (event-session close − pre-event close) × 100.
- **Basis:** the note prints all three closes for every row, so every row is **`basis: closes`**. Each row's stated m and d reproduce from its closes (10 of 10). None is UNMEASURED.
- **Grouping, D2's words:** "ten independent observations by cause" (two event dates, ten catalysts). D2 adds that they share one market path, 10-22 to 11-04, and claims no base rate from ten rows. No shared-catalyst cohort is named, so collapsing changes nothing.
- **Bar-date note:** CSX and LUV carry qed 10-21 (an after-close release) with the move realized on the 10-22 bar. Each row uses its own qed and window close of record.

**This is a FIXED-HORIZON series.** It has one observation per identity, taken at that identity's own window close. **It is not a continuation of, and must not be spliced onto, the retired 2026-W29..W38 COMMON-DATE cross-section.** The within-name panel that ended 2026-09-18 is cited by reference (2026-W39 findings) and is not re-published.

### Aggregate, offered only beside the per-ticker rows that follow

| Statistic | Value |
|---|---|
| New observations | 10 |
| Median `gap_intact_pct` | 111.97 |
| ≥ 100 (move fully intact or extended) | 6: LUV, TTMI, FPS, POOL, BMI, KSS |
| < 0 (move fully reversed and beyond) | 1: MRNA |
| Median with a shared cohort collapsed | 111.97 (no cohort named) |
| UNMEASURED | 0 |

W45's 35 rows had a median of 100.96, and W44's 43 rows a median of 83.78. These are different identities at different horizons, so the sequence is a record, not a trend.

### Per-ticker series (10 new annotations, D2 note of 2026-11-09)

| # | Ticker | `qualifying_event_date` | Window close | m (event-session move, %) | d (post-window drift, %) | `gap_intact_pct` | Basis | D2 grouping |
|---|---|---|---|---|---|---|---|---|
| 1 | CSX | 2026-10-21 | 2026-11-03 | 6.76 | -1.8386 | 70.95 | `closes` | independent (one market path) |
| 2 | LUV | 2026-10-21 | 2026-11-03 | 5.39 | 3.3785 | 166.05 | `closes` | independent (one market path) |
| 3 | TTMI | 2026-10-22 | 2026-11-04 | -27.67 | -0.6902 | 101.80 | `closes` | independent (one market path) |
| 4 | FPS | 2026-10-22 | 2026-11-04 | -21.54 | -9.9518 | 136.26 | `closes` | independent (one market path) |
| 5 | MRNA | 2026-10-22 | 2026-11-04 | -17.57 | 27.5132 | -29.11 | `closes` | independent (one market path) |
| 6 | MSM | 2026-10-22 | 2026-11-04 | -15.35 | 3.2287 | 82.20 | `closes` | independent (one market path) |
| 7 | FCFS | 2026-10-22 | 2026-11-04 | -14.75 | 4.6325 | 73.22 | `closes` | independent (one market path) |
| 8 | POOL | 2026-10-22 | 2026-11-04 | 14.36 | 11.1810 | 189.02 | `closes` | independent (one market path) |
| 9 | BMI | 2026-10-22 | 2026-11-04 | 13.48 | 9.4293 | 179.36 | `closes` | independent (one market path) |
| 10 | KSS | 2026-10-22 | 2026-11-04 | 11.82 | 2.3406 | 122.14 | `closes` | independent (one market path) |

### Not yet in the series — PENDING D2 ANNOTATION, and the named GAPs

- **PENDING D2 ANNOTATION, as D2's most recent note (11-09) states it, not re-derived:** "98 closed rows are unannotated … annotates 10 of 98 … carries 88: 25 closing 2026-11-04 (SPOT first), 10 closing 2026-11-05, 18 closing 2026-11-06 and 35 closing 2026-11-09, so the next oldest window-close date is **2026-11-04 (SPOT)**."
- **Since that note, 186 more windows have closed** without a D2 run to annotate them: 64 on 11-10, 80 on 11-11, 16 on 11-12 and 26 on 11-13 (counted from D2's index rows). **As of this run 274 identities are PENDING.** They are pending, not gaps and not zeros. D2's next run is the next opportunity.
- **Named GAPs (an intake identity with no index row at all): none new.** The 75 W45 below-cap identities that closed 11-11 to 11-13 were checked as a text match on ticker + qed, and all have index rows. The earlier GAPs are unchanged: EFXT, CRWV 10-14, BULL, SPOT 10-07, ARGX and ECHO.

### Repeat names — tickers already in the series or the queue, each on a distinct event

- **In the 10 new rows:** MRNA's 10-22 identity. MRNA reappears in this week's intake with qed 11-06 (+5.27%, below-cap), which is a distinct event.
- **In this week's intake:** DXPE, VIR, VRDN and WULF also have drain-queue rows on earlier qeds (see the dedupe above). IONS and CEG have unrelated June–July B queue rows.

### What W2 adds from its own durable record: the GRADING OUTCOME series

The router flipped on 11-09 and D2 drained the overflow the same evening, but **no drain item has been graded**: all 451 are still `pending`. Mapped by `qualifying_event_date` to the W2 cohort that published each:

| Cohort | Identities published | Enqueued 11-09 | Status on 2026-11-15 |
|---|---|---|---|
| W45 | 342 | 342 | **77 expired ungraded** (qed 10-29, 10-30 and 11-02; closed 11-11 to 11-13). **265 open and pending** (81 close 11-16, 133 close 11-17, 51 close 11-18). |
| W44 | 183 | 109 (the 64 qed-10-28 and 45 qed-10-29 identities still open on 11-09) | **All expired ungraded.** 39 closed 11-04 to 11-06 and 35 closed 11-09, before any drain could reach them. The 109 enqueued closed 11-10 and 11-11 during the blackout. |
| W40–W43 | 136 | 0 | All expired ungraded (unchanged). |

**Lineage tally:**
- **0 published B identities have ever been evaluated against B's entry criteria.** The router-gated series W40 to W45 has ended, and the first ACTIVATE drain has not yet run.
- **396 identities have expired ungraded:** W40 to W43 = 136, W44 = 183, and W45 = 77 so far. 186 of them expired **after** enqueue, inside the 11-10 to 11-12 blackout.
- **Open now:** 265 W45 drain items, plus this cycle's 85 identities (15 ranked).
- **No B order has been staged since 2026-09-01, and no B position is open.**

---

## COHORT-WIDE STRUCTURAL FINDINGS ON THE INTAKE — free, record-read only

**S1 — a thin, late, upside-skewed intake.**
- 85 routable identities, against 342 in W45. The cause is coverage, not the tape: the intake has only two screened sessions (11-06 and 11-09) plus the 11-05 after-close reporters, because D1 has no row for 11-10 to 11-13.
- **Direction:** 57 up and 28 down, reversing W45's 204 down / 138 up. Within the ranked 15, 9 are up and 6 are down.
- **Almost all are own-issuer Q3 releases.** The non-earnings anchors in the ranked 15 are FRVO's Google PPA (with lock-up expiry the same day) and IBRX's trial readout.

**S2 — two different tapes sit inside this intake.**
- The 45 qed-11-05 names are measured on **11-06**, the session after the −4.41% SPY / −11.21% SMH 11-05 sell-off that set VIX HIGH.
- The 20 qed-11-09 names are measured on **11-09**, a broad relief rally. D1 records a median discovery move of +2.27%; an enrichment excerpt puts SPY at about +2.4%.
- For B's information-versus-sentiment mechanism, the qed-11-05 names carry a rebound tape and the qed-11-09 names a relief-rally tape. Index-level beta inflates up-moves and dampens down-moves in an unknown proportion. IONS (−21.4% against a rising tape) is the cleanest information signal in the ranked 15 for that reason.

**S3 — noisy names.** D1 records the other ≥5% sessions in the prior 10. Several ranked names carry many: IREN 8, FRVO 6, QNT 5, IONQ 5, IBRX 5, KRMN 4 and PRAX 4. For these, the event move is one of several in the window, and B's attacker must treat the event-day figure as partly flow.

**S4 — anchor and measurement quality.**
- **Better on checks:** 85 of 85 items carry both closes, the arithmetic is clean, and both actionable-side chain hits resolve to after-close releases.
- **Weaker on provenance:** `d564cda0` was hosted by OPS2 after D1's own session died, and both rows were screened `router-gated`. No figure was broker re-measured.
- **One release-timing conflict, for D2 to settle (rank 9, DKNG).** D1 anchors DKNG on the EDGAR acceptance at **11-06 11:50Z** (pre-open), giving qed 11-06 and window close 11-19. Press coverage found by enrichment describes the release as **after the close on 11-05**. If that is right, the qed is 11-05 and the window closes **11-18, one session earlier**. The measured session (11-06) and the move are the same either way. W2 does not re-judge anchors and files no rescreen: neither free check fired, and the figure is unaffected. The conservative reading for D2 is 11-18.
- **One share-class pair:** UA (−5.04%) and UAA (−5.21%) are two classes of one issuer on one event. They are counted as two identities by D1, and both are below-cap.

**S5 — the trajectory series and the grading series both lost the same three days.** The blackout stopped D2's annotation as well as D2's drain. The fixed-horizon series gained 10 rows, against a backlog of 274, and the first graded B outcome has still not happened.

---

# PART 2 — RANKED SHORTLIST (FULL MODE)

**SCREEN MODE: FULL (B router ACTIVATE as of 2026-11-09).**

The default assumption is that **the market reaction is correct.** Each block below gives the fields W4's deterministic handoff needs:
- (a) the direction and magnitude of any hypothesized mispricing;
- (b) supporting public information, with primary sources;
- (c) convergence indicators, and which admissible convergence-target type would fit;
- (d) days remaining in the window (from 11-16, inclusive);
- (e) tier;
- (f) `qualifying_event_date`;
- (g) the originating D1 id.

Each block also records the retrieved comparables and the information-versus-sentiment read. Comparables come from `analytics.find_precedents()` (B rows only) and from sources the sub-agents found. They are retrieved, not recalled. Vector distances were about 0.35–0.49, so similarity is weak and the precedents are indicative only.

**This is enrichment, not a decision.** W2 makes no GO/NO-GO call. Thesis construction, D2's broker re-measurement and the adversarial attack belong to D2 (via W4 §C) for the `top-5` rows.

**Admissible convergence targets — a finding that binds the whole list.** Only **PRAX** has a source-stated admissible dated event inside a 60-day horizon: the relutrigine PDUFA on 2026-12-27, an FDA decision date. For every other candidate, no company-stated next-earnings date was found, and the third-party dates point to February–March 2027, beyond 60 days. Only criterion 3(a), a numerical price level, fits them.

**Post-event prices quoted below** come from news excerpts that surfaced incidentally in searches. They are not measurements, and D2 must re-measure on IBKR.

### Rank 1 · KRMN (Karman Space & Defense) · `top-5` · qed 2026-11-05 · +42.13% on 11-06 · 3 days left (closes 11-18) · D1 `d564cda0`
- **(a) Mispricing:** direction ambiguous, leaning **none established**. The news was a real but modest beat-and-raise: the guide midpoint rose about 2.5%, and adj. EPS was $0.19 against $0.15–0.16. A 42% move far exceeds that. A fade case is circumstantial; excerpts put the price near $40.6 by 11-13, against a $45.61 event close. B's long bias puts a pop-fade at the evidence bar it does not meet here, and a long under-reaction has no support after a 42% gap.
- **(b) Information:** revenue $201.6M (+65.6%, +25% organic); record backlog $1.7B including a $218M 7-year THAAD LTA with Lockheed; FY26 revenue guide raised to $755–760M (from $730–745M); Space & Launch −6.9% on ULA timing; FCF $13M; LT debt $851.5M. Sources: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/2040127/000119312526449899/krmn-ex99_1.htm), [press release](https://investors.karman-sd.com/News--Events/press-releases/news-details/2026/Karman-Space--Defense-Reports-Third-Quarter-Fiscal-Year-2026-Financial-Results/default.aspx).
- **(c) Convergence:** numerical price level only; next earnings is described only as "around March 2027", by a secondary source. Watch the two further LTAs management expects this year, 2027 guidance, leverage (~3.2x), and secondary-offering supply. Needham cut its PT from $80 to $50 on 11-06, and most sell-side targets are falling, not rising.
- **Comparables retrieved:** AVAV 2026-07-05 (`0a2ea97d`, NO-GO), ACHR 2026-07-20 (NO-GO), SAIC 2026-06-02 (NO-GO), GTLB 2026-06-03 (NO-GO). All are defense or software NO-GOs, and none is profitable-labelled.
- **Information vs sentiment:** mixed, leaning **sentiment/positioning**. The pop reversed a −13.5% and −6.1% slide on 11-04 and 11-05 and sits on a +44% bounce from the 10-14 low.

### Rank 2 · FROG (JFrog) · `top-5` · qed 2026-11-05 · +35.33% on 11-06 · 3 days left (closes 11-18) · D1 `d564cda0`
- **(a) Mispricing:** **none; the reaction appears correct.** It was a large beat-and-raise, and the stock extended afterward (excerpts: about $109.5 on 11-11 and $113.6 on 11-13, against a $100.98 event close), the opposite of a fade.
- **(b) Information:** revenue $179.2M (+31%) vs ~$165.9M consensus and its own $164–166M guide; cloud +60%; RPO $812.4M (+60%); FY26 guide raised to $680–682M from $648–652M; Q4 guide $183–185M vs ~$168M consensus. Sources: [press release](https://jfrog.com/press-room/jfrog-announces-third-quarter-2026-results/), [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1800667/000119312526449797/frog-ex99_1.htm).
- **(c) Convergence:** numerical price level only; no next-earnings date was found. Watch analyst revisions (reported as 10 raises and 0 cuts), whether the FY27 frame of $775–825M (~18% growth) is maintained, and AI-disruption sentiment toward software.
- **Comparables retrieved:** SAIC, SANM 2026-07-28, TEAM 2026-05-02 (a long framing judged inappropriate for B on a positive reaction), MNDY, NET and GTLB. All are NO-GO.
- **Information vs sentiment:** **information-driven**, ratified by sell-side target raises. Part of the pop retraces a −13.6% 11-05 session.

### Rank 3 · IRTC (iRhythm Technologies) · `top-5` · qed 2026-11-05 · −30.70% on 11-06 · 3 days left (closes 11-18) · D1 `d564cda0`
- **(a) Mispricing:** the **only plausible long-side over-reaction among the top-5**, at low-to-moderate confidence. The headline was in line, but the organic guide was effectively trimmed (the raise includes ~$16M of acquired VitalConnect revenue), Zio AT stalled, and the Zio MCT FDA submission slipped from 2026 to 2027. On a stock priced near 58x forward earnings, that de-rating is a legitimate information response. Sell-side PT cuts of about 10–25% (and a Citi downgrade to Neutral) are smaller than the 31% price drop, which is consistent with a partial overshoot at most. The magnitude cannot be estimated from the evidence.
- **(b) Information:** revenue $221.6M (+14.9%) vs ~$222M consensus; adj. EBITDA margin 23.1%; GAAP loss includes a ~$50M litigation settlement; Q4 Zio AT guided down ~10%; management reiterated ~$1B organic 2027 revenue. Sources: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1388658/000138865826000093/irtcq32026ex991pressrelease.htm), [IR release](https://investors.irhythmtech.com/news/news-details/2026/iRhythm-Holdings-Announces-Third-Quarter-2026-Financial-Results/default.aspx).
- **(c) Convergence:** numerical price level only. "Next earnings release" would fit criterion 3(b), but the Q4 report is described only as "February" by a third party, likely past 60 days. Watch the VitalPatch–Zio integration (mid-Q1 2027), any second MCT slip (a bear trigger), and further downgrades.
- **Comparables retrieved:** ISRG 2026-07-20 (`f90e7c15`, **GO, profitable**: a quality compounder's double beat sold −14% on tone, against a milder drop); BSX 2026-05-28 and 06-03 (the guidance-cut analogue, NO-GO); OMCL, GKOS and A (NO-GO); FTV 2026-07-29 (GO, profitable, a −7% reaction to a beat-and-raise).
- **Information vs sentiment:** mostly **information plus multiple compression**, on roughly 11x normal volume (per secondary sources). The stock rose 5.5% on 11-04 into the print, which raised the bar.

### Rank 4 · TMDX (TransMedics) · `top-5` · qed 2026-11-05 · +27.92% on 11-06 · 3 days left (closes 11-18) · D1 `d564cda0`
- **(a) Mispricing:** **none established; the reaction looks like correct pricing**, with at most mild continuation. Excerpts show the gain held (about $91.4 on 11-13 against an $88.24 event close). Adj. EPS fell 24% y/y, margins compressed and October flights were soft, so it is not clearly under-reacted either. A long continuation view is Strategy A territory, not B's mean reversion.
- **(b) Information:** revenue $203.0M (+41%, +35% organic) vs ~$178M consensus; adj. EPS $0.51 vs ~$0.30; FY26 guide raised to $764–774M (including ~$14M of acquired PAD Aviation revenue). Sources: [press release](https://investors.transmedics.com/news-releases/news-release-details/transmedics-reports-third-quarter-2026-financial-results), [call transcript](https://stockanalysis.com/stocks/tmdx/transcripts/723973-q3-2026).
- **(c) Convergence:** numerical price level only; next earnings is "tentative Feb 23, 2027" by a third party, beyond 60 days. Watch Q4 flight and case volumes, and the ENHANCE Heart Part B and DENOVO Lung starts (Q1 2027).
- **Comparables retrieved:** ISRG and FTV (GO, profitable, but downside fades, the opposite direction); OMCL, BSX, A and GKOS (NO-GO). The retrieved positive-pop B precedents are all NO-GO.
- **Information vs sentiment:** **information-driven**, with sell-side ratification (Canaccord $95→$120, UBS $77→$88, JPM $73→$85) and a director purchase. The stock was down 44% YTD before the print.

### Rank 5 · FRVO (Fervo Energy) · `top-5` · qed 2026-11-09 · +26.02% on 11-09 · 5 days left (closes 11-20) · D1 `9f5c6b11`
- **(a) Mispricing:** direction unclear, leaning **none established**; the move is flow-dominated. The Google PPA and backlog are real news, but the session coincided with:
  - the IPO lock-up expiry (205.8M Class A shares, ~97% of Class A outstanding);
  - an open short report (Morpheus Research, 10-06);
  - plaintiff-firm "investigations";
  - the relief-rally tape.
  Sell-side cut targets after the pop (Baird $26→$20, Roth $45→$37, BofA $30→$25). A pop-fade is the case B's long bias says needs strong evidence, and squeeze and litigation risk cut both ways.
- **(b) Information:** a Google 15-year take-or-pay PPA for 396 MW (with an option on ~600 MW more); contracted PPAs 1,054 MW / ~$11.9B backlog (from 658 MW / $7.2B); GeoBlock 1 reached commercial operation 9-30; H2 capex guide cut to $700–750M on timing; revenue $116K. Sources: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1853868/000162828026071911/exhibit991earningsrelease1.htm), [results release](https://ir.fervoenergy.com/news-releases/news-release-details/fervo-energy-reports-third-quarter-2026-results). The 10-Q text includes a remediation plan for material weaknesses (not verified further).
- **(c) Convergence:** numerical price level only. Cape GeoBlocks 2–3 operation "by January 1, 2027" is company-stated but not an admissible event type. Watch Cape flow and water-loss data, transmission and curtailment news, lock-up supply and short-report developments.
- **Comparables retrieved:** BE 2026-05-01 (NO-GO; a massive beat plus a hyperscaler win, the "2.20 textbook-rational trap"), FLEX, GEV and GNRC (NO-GO), and D1 `7ac0f2f6` (CEG's Google PPA, indexed, not routed).
- **Information vs sentiment:** mixed, **tilting sentiment/flow.** FRVO is pre-revenue and a short-seller target, its lock-up expired the same day, it had a +15.9% session on 11-06, and it carries 6 other ≥5% sessions in the prior 10.

### Rank 6 · QNT (Quantinuum) · `rest` · qed 2026-11-05 · +25.99% on 11-06 · 3 days left · D1 `d564cda0`
- **(a)** **None**; at most a modest unsubstantiated over-reaction. The beat was about $1M on a ~$9M revenue base, and the move came after a ~40% slide since its September post-IPO high.
- **(b)** Q3 revenue $9.05M (+233%) vs ~$8.05M consensus; FY26 outlook $31–34M (from $28–32M); adj. EBITDA loss widened to $80M; sell-side cut targets on sector multiple compression while keeping Buy (BofA $85→$50). Source: [company release](https://www.quantinuum.com/press-releases/quantinuum-reports-third-quarter-2026-results-and-raises-full-year-revenue-outlook).
- **(c)** Numerical price level only. A lock-up expiry for ≥1% holders on Nov 30 / Dec 1 (~231M shares) is a supply overhang inside any 60-day hold.
- **Comparables:** no quantum or post-IPO comparable was retrieved. Loosely related B NO-GOs: CLSK, BE and IREN 2026-07-20.
- **Information vs sentiment:** mixed, leaning **sector sympathy and oversold bounce**.

### Rank 7 · IONQ (IonQ) · `rest` · qed 2026-11-05 · +23.42% on 11-06 · 3 days left · D1 `d564cda0`
- **(a)** **None** to a modest over-reaction up. Roughly half of revenue is acquired (SkyWater), gross margin is 21.9%, and dilution is heavy (a $2B raise at $40 on 10-14, the Elisity all-stock close, and Series C warrants). Nine firms cut targets the next morning.
- **(b)** Revenue $173.8M vs ~$141M consensus; FY26 guide $505–515M (from $450–460M); RPO $1.2B; share count about 409M at 9/30 → ~465M after Elisity. Sources: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1824920/000119312526449779/ionq-ex99_1.htm), [IR release](https://investors.ionq.com/news/news-details/2026/IonQ-Announces-Record-3Q26-Revenues-and-Raises-FY2026-Guidance-to-505---515-Million-as-Backlog-Grows-to-1-2-Billion/default.aspx).
- **(c)** Numerical price level only. Watch share-count growth, the 256-qubit year-end system and the margin trend.
- **Comparables:** GLW 2026-05-11 (`7db1b13a`, NO-GO, an extreme pre-event rally) and IREN 2026-07-20 (`3c2dfc3f`, NO-GO). One source reports IonQ's three prior results-day moves averaged 11.6% absolute.
- **Information vs sentiment:** mixed. Note this item's 8-K carries Items 2.01 and 3.02 alongside 2.02, so its event is not a pure earnings release.

### Rank 8 · IONS (Ionis Pharmaceuticals) · `rest` · qed 2026-11-09 · −21.36% on 11-09 · 5 days left · D1 `9f5c6b11`
- **(a)** **None; the reaction looks correct.** A modest over-reaction down is possible only if the Tryngolza ramp re-accelerates.
- **(b)** Tryngolza FY26 sales guide cut to ~$50M from $100–110M after $9M in Q3 (against ~$21–23M consensus); the positive-cash-flow target moved to 2029; total-revenue guidance was reaffirmed; RBC, BofA and TD Cowen cut targets by roughly 30–37%. Sources: [company release](https://ir.ionis.com/news-releases/news-release-details/ionis-reports-third-quarter-2026-financial-results-and), [STAT](https://www.statnews.com/2026/11/09/ionis-pharmaceuticals-shares-plummet-after-tryngolza-slow-rollout).
- **(c)** Numerical price level only. EU approval (expected Q4 2026) is not an admissible type, and the Q4 report ("late February", third-party) falls beyond 60 days.
- **Comparables:** ALNY 2026-07-30 (`48a5ad5f`, NO-GO, a franchise-trajectory reset), VCYT 2026-08-03 (`23c67fbc`, NO-GO), TGTX and ZTS (NO-GO). Launch or guide-cut resets were screened out as information-driven.
- **Information vs sentiment:** **information-driven.** It fell against a rising tape, which is S2's cleanest signal.

### Rank 9 · DKNG (DraftKings) · `rest` · qed 2026-11-06 per D1 (see S4: possibly 11-05) · −21.30% on 11-06 · 4 days left on D1's anchor, 3 on the alternative · D1 `d564cda0`
- **(a)** **None; the reaction looks correct.** A modest over-reaction down is the only defensible hypothesis.
- **(b)** Revenue $1.33B vs ~$1.41B consensus; FY26 adj. EBITDA guide cut to $175–275M from $700–900M (prediction-markets investment of $650–700M); FY27 guide $800M–1.0B vs ~$1.12B expected; downgrades from JPM, UBS, Stifel, Wells Fargo and Berenberg; a CFO purchase of about $350K on 11-09. Source: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1883685/000188368526000039/q326-prx8kexx991.htm).
- **(c)** Numerical price level only; the Q4 report (February, third-party) falls beyond 60 days.
- **Comparables:** PEGA 2026-07-22 (`bcd09486`), SRAD, GDDY, NET and DASH, all NO-GO.
- **Information vs sentiment:** mostly **information**, plus a regulatory-risk sentiment layer.

### Rank 10 · IREN (IREN Ltd) · `rest` · qed 2026-11-05 · +20.02% on 11-06 · 3 days left · D1 `d564cda0`
- **(a)** **None** to a modest over-reaction up. The print cut both ways: AI Cloud revenue rose strongly, but the >$4B ARR go-live slipped to Jan/Feb 2027, the December-quarter AI Cloud guide was flat, and ATM equity sales continue. Goldman cut its PT 40% ($50→$30) while the stock rose 20%.
- **(b)** Revenue $228M (+66% q/q) vs ~$221M consensus; AI Cloud $200M; backlog $20.3B; FY27 capex guide cut. Sources: [8-K exhibit](https://www.sec.gov/Archives/edgar/data/1878848/000187884826000065/irenreportsq1-fy27result.htm), [Reuters](https://www.reuters.com/technology/neocloud-firm-iren-tops-quarterly-revenue-estimates-shares-jump-2026-11-05/).
- **(c)** Numerical price level only. The ARR milestone is company-stated but outside 60 days and not an admissible type.
- **Comparables:** **IREN itself, 2026-07-20** (`3c2dfc3f`, NO-GO: "+19.6% approximately information-proportionate re-rating … sympathy/squeeze-contaminated"), the closest same-ticker, same-magnitude precedent. Also CLSK and BE (NO-GO).
- **Information vs sentiment:** mixed, with heavy flow contamination; IREN carries 8 other ≥5% sessions in the prior 10, the most in the ranked 15.

### Rank 11 · PRAX (Praxis Precision Medicines) · `rest` · qed 2026-11-09 · +19.94% on 11-09 · 5 days left · D1 `9f5c6b11`
- **(a)** **None; the reaction appears correct.** The release reaffirmed both PDUFA dates, brought no new clinical data, and showed about $1.3B of cash. The move reads as positioning ahead of FDA binaries, and excerpts show a −6.2% fade on the 11-12 Investor Day.
- **(b)** GAAP loss $3.23/share vs ~$3.54–3.64 consensus; G&A up on launch build; POWER3 start moved to 2027. Sources: [IR release](https://investors.praxismedicines.com/news-releases/news-release-details/praxis-precision-medicines-provides-corporate-update-and-21), [8-K exhibit](https://www.sec.gov/Archives/edgar/data/1689548/000168954826000086/praxisq32026pr.htm).
- **(c)** **The only admissible dated target in the list: the relutrigine PDUFA on 2026-12-27, an FDA decision date** (company-stated, inside 60 days from an 11-16 entry). The ulixacaltamide PDUFA of 2027-01-29 is about 74 days out. Caveat: anchoring a thesis on a PDUFA makes it an event bet, not a reaction-quality thesis.
- **Comparables:** AXSM 2026-05-04 (`c009141d`, NO-GO) and ARWR 2026-07-22 (`7abf96ac`, NO-GO: +19% on a Ph3 beat, efficient absorption).
- **Information vs sentiment:** **sentiment/flow on a thin informational anchor**, on the relief-rally tape.

### Rank 12 · QXO · `rest` · qed 2026-11-09 · +19.20% on 11-09 · 5 days left · D1 `9f5c6b11`
- **(a)** A possible mild over-reaction up, uncertain. The pre-announced quarter was a ~1% revenue beat on acquired revenue, and short-covering after a beaten-down run is plausible. Excerpts show a −7.2% fall to about 12.81 after the full 11-12 report.
- **(b)** Preliminary net sales $4.90B (+79%, from TopBuild and Kodiak), adj. EBITDA $557M (11.4% margin). The full 11-12 report showed adj. EPS $0.13 vs $0.14 on 36% more shares, LT debt $8.95B, no guidance, a $500M buyback and a CFO transition. Sources: [preliminary release](https://investors.qxo.com/news/news-details/2026/QXO-Announces-Third-Quarter-2026-Preliminary-Financial-Information/default.aspx), [full results](https://investors.qxo.com/news/news-details/2026/QXO-Reports-Third-Quarter-2026-Results/default.aspx).
- **(c)** Numerical price level only. The 11-12 full report is follow-on information that D2 must weigh under the exit rule's "new public information".
- **Comparables:** no close analog was retrieved; FTV (GO, the opposite direction), BE, DLTR, BTSG and BBY (NO-GO).
- **Information vs sentiment:** mixed.

### Rank 13 · TILE (Interface) · `rest` · qed 2026-11-06 · −18.72% on 11-06 · 4 days left · D1 `d564cda0`
- **(a)** At most a modest over-reaction down. Adj. EPS beat and EPS guidance was reaffirmed, but revenue missed its own range, the FY sales guide was cut, orders rose only 1% (EAAA −7%), and the implied Q4 gross margin falls. Excerpts show no recovery (about 31 on 11-13).
- **(b)** Revenue $366.7M vs its own $370–380M range; FY sales guide $1.440–1.455B (from $1.455–1.485B). Management calls it "timing shifts, not lost business", citing European softness and new Canadian tariffs. Source: [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/715787/000071578726000027/a991pressreleaseq32026.htm).
- **(c)** Numerical price level only; the next earnings date shown (03/02/2027) is a third-party estimate beyond 60 days.
- **Eligibility flag:** the post-drop market cap is about $1.8B, below B's $2B floor at entry (see Rev 49 above).
- **Comparables:** LII 2026-08-03, PNR 2026-07-20 and CARR 2026-08-03 (NO-GO; CARR retraced a 0% gap in 4 sessions).
- **Information vs sentiment:** mostly **information-driven**.

### Rank 14 · AXON (Axon Enterprise) · `rest` · qed 2026-11-05 · −18.18% on 11-06 · 3 days left · D1 `d564cda0`
- **(a)** **None** to a mild over-reaction down. The sales cut is three federal Dedrone deals (~$130M) that slipped on timing, against ARR +40% and $15.8B of bookings. But gross margin fell 350bp, FCF was negative and the FCF guide was cut, on top of $1.2B more committed to Skydio after a $1.15B convert. Sell-side cut PTs 20–33%, and Craig-Hallum downgraded to Hold. The stock was already down about 50% from August.
- **(b)** Revenue $908.6M (+28%) vs ~$934M consensus; non-GAAP EPS $1.72 vs $1.89; FY26 revenue guide ~$3.61–3.63B; Q4 guide $990M–1.01B vs ~$1.07B consensus. Sources: [IR release](https://investor.axon.com/2026-11-05-Axon-reports-record-Q3-2026-revenue-of-909-million,-up-28-year-over-year), [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1069183/000162828026071086/axon-20261105xex991.htm).
- **(c)** Numerical price level only. Watch whether the Dedrone deployments land before 12-31.
- **Comparables:** GTLB, AMKR 2026-07-28 (a move that decomposes into disclosed capex/FCF deterioration) and SANM, all NO-GO.
- **Information vs sentiment:** mostly **information-driven**.

### Rank 15 · IBRX (ImmunityBio) · `rest` · qed 2026-11-09 · −17.66% on 11-09 · 5 days left · D1 `9f5c6b11`
- **(a)** **No mispricing established.** The primary-endpoint win came first (n=370, no response rates disclosed), then the Q3 revenue miss drove the reversal. Excerpts put the 11-12 close at about 6.07, below the 7.11 event close.
- **(b)** Net product revenue $48.7M (+53% y/y but −4% q/q, the first sequential decline after eight quarters) vs ~$59.2M consensus. The 10-Q carries going-concern language and a funding need. Jefferies called the trial a "large value driver" (~$2.2B peak). Sources: [trial release](https://ir.immunitybio.com/news-releases/news-release-details/immunitybio-announces-anktivar-plus-bcg-meets-primary-endpoint), [8-K EX-99.1](https://www.sec.gov/Archives/edgar/data/1326110/000132611026000097/ibrx-2026119x8kexhibit991.htm).
- **(c)** Numerical price level only. The sBLA submission planned for Q4 2026 is not an FDA decision date, and no PDUFA exists. The 11-16 UBS and Jefferies conference talks are not admissible types.
- **Comparables:** **INCOMPLETE.** The dedicated query failed twice on a BigQuery embedding-concurrency quota and was not re-run. Only positive-direction biotech NO-GOs were retrieved (ARWR, AXSM).
- **Information vs sentiment:** **information-driven plus retail flow**, with 5 other ≥5% sessions in the prior 10.

## ROUTING

**Router ACTIVATE → W4 §C enqueues one `PENDING_ANALYSIS` `thesis-construction` row per `top-5` row, due today**, per its HARD CHECK, ordered by days remaining (fewer first). **W4 §C's top tier is the five `top-5` rows: KRMN, FROG, IRTC, TMDX and FRVO.**

- **Days remaining from 11-16:** KRMN, FROG, IRTC and TMDX have **3** (window close 11-18), and FRVO has **5** (11-20).
- **For each, the payload should carry** `qualifying_event_date`, the originating D1 id (`d564cda0` for the first four, `9f5c6b11` for FRVO) and this file's enrichment block.
- **Dedupe for W4:** none of the five matches an existing B `thesis-construction` row on ticker + `qualifying_event_date`.
- **Read before routing:** no `top-5` row shows evidence of a clear mispricing. The only plausible over-reaction is IRTC's, on the long side at low-to-moderate confidence. Whether any setup clears criteria 2–4 is D2's decision at thesis construction.
- **Queue load D2 will face on its next run:** the 265 still-open drain items (closing 11-16 to 11-18), plus these five. That load is W4's and D2's to sequence. Alert `eddabe43` already covers the drain volume, so W2 files nothing new.

---

## FINDINGS — zero alerts filed, zero queue items

**`ops.alerts`:** none filed. Before filing, a check found open rows already covering every out-of-scope condition this run met:
- the fleet blackout (`fleet_blackout_days`, `queue_driven_missed_fire` ×15, `d5b4b41b`, `68d5d95b`);
- the drain volume (`eddabe43`).

**`events.queue_events`:** none. Both free checks were clean, so no `rescreen-` item is owed. W2 does not enqueue thesis-construction rows; W4 §C does.

**Recorded for D2, not filed (each is a thesis-construction input, not a defect on a record):**
- the DKNG anchor-timing conflict (S4);
- TILE's post-drop market cap against the $2B floor;
- QXO's 11-12 follow-on report.

None of the three is in the `top-5`.

**Referral status:** W2 has no open referral. All three earlier referrals were closed by their owners on 11-02.

---

## HONEST LIMITS OF THIS RUN

- **None of the 85 is broker-verified.** They are arithmetic-checked only. D2's index rows copy D1's figures, so the precedence rule had nothing to apply.
- **The intake has no 11-10 to 11-13 coverage.** That is D1's catch-up path. A large event on any of those four sessions is invisible here.
- **The enrichment rests on search excerpts, not full-document fetches.** The sub-agents made 32 `web_search` calls and no `web_fetch`. Primary-source figures were taken from press releases and 8-K exhibits as excerpted. Several secondary sites were low-grade, and their figures were used only to corroborate. Post-event prices are incidental and unmeasured.
- **Precedent similarity is weak** (vector distance ~0.35–0.49), and IBRX's precedent search is incomplete.
- **The fixed-horizon series is D2's measurement, published by record read.** W2 re-verified no close against a bar.
- **The grading tally maps queue rows to W2 cohorts by `qualifying_event_date`.** A name that appeared in two cohorts on different events is counted once per event.

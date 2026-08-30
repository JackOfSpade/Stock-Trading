2026-W35

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-08-30** (Sunday, the `weekly_sun` slot). Windows measured from the run date: **Strategy A = 6 months (2026-08-30 → 2027-02-28); Strategy C = 45 days (2026-08-30 → 2026-10-14).**

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: ~13 weeks, to 2026-11-24 — the "6 months" above describes the window this file *searches*, not the horizon its bulk source *reaches*.** Beyond that cliff this file carries only per-name dates obtained from company IR pages and cadence projections, at `(C)`/`(E)` provenance, for shortlisted names. See the COVERAGE STATEMENT before 1A.1. This is a standing vendor-plan constraint, already recorded in `Claude_Task_Plan.md` PART 1A, `ops/connector_tools.yaml` and `OWNER_ACTIONS.md` item `FMP-earn-horizon`; **no fresh alert is raised for it and none should be.**

**Marker.** `2026-W35` is the ISO week of this run date (Sun 2026-08-30 is weekday 7 of the Mon 08-24 → Sun 08-30 week). `scripts/check_cadence_marker.py` passes.

**Catch-up window.** `state.routine_catchup_window` for W1: `never_completed = false`, `window_days = 6.97` — below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token is owed** and no missed-period sub-section is needed. Evidence window: **2026-08-23 → 2026-08-30**.

> ### THE FOUR THINGS IN THIS FILE A READER SHOULD NOT MISS
>
> 1. **Jackson Hole happened, and it cut against the C thesis.** The prior cycle retired its own counter (b) by observing that the 09-08 drain would know what was said rather than price the risk of it. It now knows: Warsh's first Jackson Hole keynote as Chair was hawkish, and **September hike odds re-priced from ~30% to the high-40s/mid-50s in one session.** The directional divergence the C thesis was going to document is *materially smaller* than it was two weeks ago. That is the single most important input this file hands to 09-08, and it points the opposite way from last cycle's framing.
> 2. **Strategy A's override is better supported going into its re-score, not worse — and the re-score is in two days.** M1a fires **2026-09-01 11:00 UTC**, M1b at 12:00. The `Strategy.md` reconciliation override that holds A shut fires on `growth_momentum = decelerating` **AND** `policy_stance = hawkish`. This week supplied fresh evidence for *both*. The prior cycle ranked against a clock about to run; this cycle ranks for an A epoch that may not open until October.
> 3. **Two of the prior cycle's ranked non-earnings catalysts do not exist.** META's "UTECA trial, October 2026" is a one-year mis-projection of a trial held **1–2 October 2025** that has already produced a ~€479M judgment. The "QCOM v. Arm trial, 2026-10-05" is not corroborated by any source — the case Qualcomm already **won** in 2025 is being confused with a separate, undated suit. QCOM was promoted #29 → #3 last cycle explicitly on that date. Both rows come down.
> 4. **A third catalyst in the NUVL lineage was already resolved before it was ever carried.** GSK's zidesamtinib PDUFA, carried at 09-18, was **approved 2026-07-22** as Jideytro. So was BIIB's Leqembi IQLIK initiation dose — approved **2026-07-13**, six weeks before the 08-24 date this file ranked it on. Both were carried at `(C)`. The failure mode is not bad sourcing; it is **confirming that a date was scheduled without checking whether it had already been acted on.**

---

## Regime and routing state (measured this run)

Read from `state.current_regime`, `events.regime_events`, `analytics.strategy_nav`, `state.regime_capital_debt` and `state.freshness`.

**Regime — M1a scoring as_of 2026-08-01, integrative call "stagflationary shock + hawkish policy":** `growth_momentum` **decelerating** · `inflation_trend` **stable** · `policy_stance` **hawkish** · `risk_sentiment` **neutral** · `shock_overlay` **acute**.

**Technical signals — D2a as_of 2026-08-27, the last session the fleet scored:** `SPY_TREND` **UP** (771.10 > 50d 753.3874 > 200d 709.4067) · `EQUITY_BREADTH` **HEALTHY** (69.58%, down 0.79pp from 70.37) · `VIX_REGIME` **LOW** (14.51) · `SUSTAINED_INVERSION` **NOT-SUSTAINED** (10Y−2Y +0.47; 10Y 4.67 / 2Y 4.20).

**The VIX regime flipped.** 14.51 on 08-27 is the **first `LOW` print of the current sequence**, against `NORMAL` on 08-26 (15.21) and 08-25 (15.45). Recorded as a fact here; it is D2a's to score and no verdict is drawn from it in this file. It matters to PART 2B only as context for whether index vol was cheap *before* Friday's rates move.

| Strategy | Router state | Source | Capital (measured) |
|---|---|---|---|
| **A** | **DO-NOT-ACTIVATE** — blocks NEW A entries only | `div-A-202607-1` resolved 2026-08-05; re-affirmed by D2's declined out-of-cycle review 2026-08-13 | **NAV $0.00, available $0.00** — capital-disabled; `outstanding_debt` **$3,888.45** |
| **C** | **HYBRID ACTIVATE (FOMC-only)** | `div-C-202607-1` resolved 2026-08-05 | NAV **$23.68**, available **$23.68**; **NOMADIC**, `outstanding_debt` $0.00 |

### The finding that shapes PART 2A: A's re-score is in two days, and the week's evidence argues the gate stays shut

Strategy A's technical condition is **SPY Trend = UP AND Equity Breadth = HEALTHY**. **Both legs read TRUE** and have for weeks. A sits at DO-NOT-ACTIVATE entirely because of the `Strategy.md` M1a/M1b reconciliation override — `growth_momentum = decelerating` **AND** `policy_stance = hawkish` forces a raw ACTIVATE back to DNA — which is what `div-A-202607-1` meant in calling the DNA "architecturally over-determined."

Both override preconditions are axes M1a re-scores on the first of each month. Per `ops/cadence.yaml`, **M1a's cron is `0 11 1 * *` and M1b's is `0 12 1 * *`** — so the re-score is **2026-09-01, in two days.** A call that diverges from the technical read routes through an AR_att/AR_orc divergence review before it binds; the 2026-08 cycle's took four days (M1b 08-01 → resolved 08-05).

**The prior cycle framed this as a clock about to run. The honest read this week is that the clock is about to run and the evidence going into it moved AWAY from the gate lifting.** This is a judgment about the *evidence*, not a prediction of M1a's call — M1a is strategy-blind, scores its own inputs, and this file does not see its working:

- **`policy_stance = hawkish`** was scored on 2026-08-01 off the 9–3 July split and ~66% year-end hike pricing. Since then hike pricing had *fallen* to ~29–32% (which would have argued the axis was drifting), and then **reversed hard on 2026-08-28**: Warsh's Jackson Hole keynote, two of the three July dissenters restating the hike case on the record, and September pricing back to the high-40s/mid-50s. The axis is better evidenced now than at the scoring, not worse.
- **`growth_momentum = decelerating`** was scored off the June payroll miss and the Q2 advance GDP estimate of +1.5% against Q1's +2.1%. The **second estimate, released 2026-08-26, came in at +1.5% — unchanged.** The deceleration was re-confirmed, not revised away.

**And the router is only the first of two gates.** A is **capital-disabled at NAV $0.00** with $3,888.45 of outstanding regime-capital debt (unchanged this week — nothing was swept out of A and nothing restored). A router flip on 09-01 still leaves A with no capital until a regime-capital sweep allocates some. **Both gates must lift; only one is on a scheduled clock, and this week's evidence argues against that one lifting.**

**What this file does about it — the REACH cut moves.** The prior cycle cut REACHABLE/SPENT at ~2026-09-05. Keeping that cut would imply the 09-01/09-02 print cluster is "nearly reachable," which over-reads a gate that now looks *less* likely to open. **This cycle treats every catalyst before ~2026-10-01 as unreachable for a first A entry** and ranks for an A epoch that may not open before the 2026-10-01 M1 cycle. The rule that a **spent catalyst does not demote the name** is unchanged — it keeps its narrative standing and its `Watchlist.md` row, and its next in-window catalyst is named where one exists.

### Capital and executability for C — measured, and it reconciles exactly

C is **NOMADIC** (`Operating_Protocols.md` §16, owner directive 2026-08-11): no exclusive capital by design, not even a floor; it borrows on demand pro-rata from other enabled strategies' `available_funds` at order-craft time, uncapped. **Measured from `analytics.strategy_nav`:** C NAV **$23.68** / available **$23.68**; donors — **E $15,386.78**, D $0.00, B $0.00. **Reachable ≈ $15,410.46.**

**That donor balance reconciles to the cent against the prior cycle, which is worth stating because it is the kind of check that usually is not run.** The 2026-08-23 file measured E's `available_funds` at **$15,333.61**. The 2026-08-27 REGIME-CAPITAL SWEEP moved **$53.17** from D to E (E was the sole eligible recipient; C was excluded as nomadic). `15,333.61 + 53.17 = 15,386.78` — exactly this run's reading. Nothing else moved.

Per the **State provenance** rule: what is **MEASURED** is the donor balances; what is **INFERRED** is that `fn_nomadic_capital_restore_plan` would still source them. A 09-08 order-craft session should re-run the restore plan rather than rely on this arithmetic. **"No structure fits at current size" is not an available deferral reason** and has not been since 2026-08-12.

**Overlap with open A positions: none open → no A/C conflict on any candidate on either shortlist.** The open book is entirely Strategy D — AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER. **`D:CRM:2026-07-09` closed 2026-08-27** (exit filled 0.2275 @ 234.77, realized +$16.58), so CRM is now flat and carries no cross-strategy constraint at all.

### One gate reading recorded, deliberately not alerted

`state.trading_enabled` reads **FALSE**, `halt_reason` = *"state.freshness marks_fresh/engine_fresh not both TRUE"*. **This is the expected weekend state, not an incident**, and W1 stages nothing so nothing here is blocked. `state.freshness` on the same row reads `marks_fresh` FALSE **but `marks_current` TRUE** — the two families disagree, and the disagreement is structural rather than a data problem. The mechanism is set out in the OUT-OF-SCOPE section at the end of this file, where it is recorded for its owning surface rather than acted on here.

## Past-window tape and the cadence shape (2026-08-24 → 2026-08-29)

**`ops.run_log` holds zero rows for Friday 2026-08-28 and Saturday 2026-08-29. THAT IS THE EXPECTED CADENCE, NOT AN OUTAGE, and this file states it that way on purpose.** Since the 2026-08-08 daily-tier consolidation, `monitor_class: daily_sun_thu` (`ops/cadence.yaml`) means no routine in the fleet is scheduled on a Friday or a Saturday; `state.cadence_watch` encodes the same day-of-week predicate and correctly expects nothing. **The 2026-08-23 run of this very routine got this wrong** — it read the same zero-row shape on 2026-08-21/22 and raised a `cadence_outage` warning claiming a "FLEET-WIDE SCHEDULED-TRIGGER OUTAGE." W3 refuted it the same day on measured evidence, but the operator email had already gone out, and `Claude_Task_Plan.md` now carries a shared bullet (**RUN-LOG GAP INTERPRETATION**) naming that failure. Per that bullet, a single-routine claim must be resolved against `state.cadence_expected_history` and a fleet-wide claim against `state.fleet_blackout_days`. No such claim is made here and no alert is raised.

**The real consequence, which is a coverage fact rather than a defect: D1's evidence reaches only through Thursday 2026-08-27, so Friday 2026-08-28 was a full trading session no internal routine observed.** That is a standing weekly property of the consolidated cadence, not a miss. This file therefore carries a bounded gap-check over 08-28 for newly-disclosed *dated* catalysts only — it does not attempt a second broad news scan, per the daily-to-weekly boundary rule.

---

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-08-30 → 2027-02-28)

Universe rails per `strategy/03_strategy_a.md`: US-listed common equity, market cap **≥ $2B**, 30-day ADV **≥ $10M**. ADRs appear as context and are marked; they are **not A-eligible** per W4's 2026-08-09 ruling.

> ### COVERAGE STATEMENT — read before using 1A.1. The constraint is sharper than the prior cycle described it.
>
> The prior cycle established that FMP's `earnings-calendar` returns **zero rows past 2026-11-24** on this plan tier. **That is re-confirmed this run and the horizon has NOT moved** — a 2026-12-01 → 2027-02-28 probe returned an empty array. Per `Claude_Task_Plan.md` PART 1A, only a *move* in the horizon would be new information, and there is none, so no alert is raised.
>
> **But this run measured something the prior cycles did not, and it changes what the source can be trusted for.** Five probes were issued across the whole window. The **union of every symbol they returned is 78 distinct tickers** — essentially the documented ~87-name free-tier **symbol allow-list**. The date cliff is not the only filter; there is a *symbol* filter underneath it, and it is the one that actually shapes this table:
>
> | Probe window | Rows returned |
> |---|---|
> | 2026-08-31 → 2026-09-18 | **4** (NIO, DOCU, ADBE, FDX) |
> | 2026-09-19 → 2026-10-14 | 12 |
> | 2026-10-15 → 2026-11-30 | 63 |
> | 2026-12-01 → 2027-02-28 | **0** |
>
> **Four rows for a nineteen-day window containing DELL, PANW, AVGO, SNOW, HPE, NTAP, ORCL, LULU and CHWY is not a thin calendar — it is an allow-list.** Absent from *every* probe despite confirmed dates: ORCL, MU, AVGO, SNOW, HPE, DELL, NTAP, CRM, CAT, GEV, SMCI, DDOG, AMAT, CRWV, NBIS, NOW, VRTX, LLY, MRK, IBM, QCOM, AKAM, TTWO, FSLR, HD, CTVA. This single mechanism explains, without needing a second hypothesis, both the near-window sparsity above **and** D1's 2026-08-27 observation (`ops.alerts` `bccc6d2e`, `fmp_endpoint_scoping_defect`) that `earnings-calendar` returned **2** rows against ~115 secondary-counted US reporters. **It also corrects this file's own prior framing** that "FMP contributed the bulk earnings calendar to 2026-11-24": it contributed the *allow-listed subset* to 2026-11-24.
>
> **Consequence for how to read 1A.1: essentially every date below that matters was obtained from a company IR page, an SEC filing, or web research — not from the bulk feed.** The Dec 2026 – Feb 2027 block in 1A.6 is per-name and cadence-projected, per the plan's instruction to fill that tail for shortlisted names at `(E)` provenance rather than leave it blank.

### 1A.1 — Earnings catalysts inside the Strategy C 45-day window (2026-08-31 → 2026-10-14)

Status vocabulary: **(C)** confirmed against the company's own IR release or SEC filing · **(2S)** two independent sources agree, no company release located · **(E)** single-source or cadence estimate · **(!)** sources disagree, all candidate dates shown.

| Date | Ticker | Company | Fiscal Q | Status |
|---|---|---|---|---|
| 2026-09-01 | **DELL** | Dell Technologies | Q2 FY27 | **(C)** businesswire 2026-08-18 (prior cycle), corroborated (2S) this run |
| 2026-09-01 | **PANW** | Palo Alto Networks | Q4 FY26 | **(2S)** — *fiscal-quarter label disputed between sources (Q4 FY26 vs Q1 FY27); the DATE is not* |
| 2026-09-01 | NIO | NIO | Q2 CY26 | (E) · **ADR** |
| 2026-09-02 | **AVGO** | Broadcom | Q3 FY26 | **(C)** investors.broadcom.com |
| 2026-09-02 | **SNOW** | Snowflake | Q2 FY27 | **(C)** snowflake.com |
| 2026-09-02 | **HPE** | Hewlett Packard Enterprise | Q3 FY26 | **(2S)** |
| 2026-09-02 | **NTAP** | NetApp | Q1 FY27 | **(C)** netapp.com 2026-08-11 |
| 2026-09-03 | **LULU** | lululemon | Q2 FY26 | **(C)** corporate.lululemon.com 2026-08-20 |
| 2026-09-03 | **DOCU** | DocuSign | Q2 FY27 | **(C)** — *upgraded from (E)* |
| 2026-09-03 | **CPB** | The Campbell's Company | Q4/FY26 | **(C)** — **NEW to this file** |
| 2026-09-03 **or** 09-10 | RH | RH | Q2 FY26 | **(!)** — **NEW**; ir.rh.com carries no Q2 announcement |
| **~09-08 / 09-10 / 09-14** | **ORCL** | Oracle | Q1 FY27 | **(!) UNRECONCILED FOR A FOURTH CYCLE** — see below |
| ~2026-09-08/09 | GME | GameStop | Q2 FY26 | **(!)** sources split; GameStop does not pre-announce |
| 2026-09-09 | **CHWY** | Chewy | Q2 FY26 | **(C)** investor.chewy.com |
| 2026-09-10 | **ADBE** | Adobe | Q3 FY26 | **(2S)** — no Adobe IR release located, second cycle running |
| 2026-09-11 | **KR** | Kroger | Q2 FY26 | **(C)** ir.kroger.com |
| 2026-09-22 | **AZO** | AutoZone | Q4 FY26 | **(C)** globenewswire 2026-08-24 — **NEW to this file** |
| 2026-09-23 | **GIS** | General Mills | Q1 FY27 | **(C)** businesswire 2026-08-26 — *upgraded from (E)* |
| ~2026-09-23/24 | CTAS | Cintas | Q1 FY27 | **(E)** cadence only; no FY27 announcement |
| 2026-09-24 | **DRI** | Darden Restaurants | Q1 FY27 | **(2S)** — **RESOLVES the prior cycle's 09-17-or-09-24 split** |
| 2026-09-24 | **COST** | Costco | Q4 FY26 | **(C)** investor.costco.com |
| 2026-09-24 | **JBL** | Jabil | Q4 FY26 | **(2S)** — **NEW to this file** |
| ~2026-09-29/30 | PAYX | Paychex | Q1 FY27 | **(E)** cadence only |
| **2026-09-30** | **MU** | Micron | Q4 FY26 | **(C) globenewswire 2026-08-26 — RESOLVED, see below** |
| ~late Sept | ACN | Accenture | Q4 FY26 | **(E)** cadence only |
| **2026-10-01** | **NKE** | Nike | Q1 FY27 | **(C) — RESOLVED, see below** |
| ~2026-10-01 | STZ | Constellation Brands | Q2 FY27 | **(E)** single-source |
| 2026-10-05 | CCL | Carnival | Q3 FY26 | **(2S)** |
| ~2026-10-08/12 | DAL | Delta Air Lines | Q3 2026 | **(E)** no company date set |
| 2026-10-08 | **PEP** | PepsiCo | Q3 2026 | **(2S)** |
| 2026-10-08 | TLRY | Tilray | Q1 FY27 | (E) |
| 2026-10-13 | **JPM** | JPMorgan Chase | Q3 2026 | **(C)** — from JPM's own multi-quarter 2026 date release |
| 2026-10-13 | GS, C, WFC, JNJ | — | Q3 2026 | **(E)** — feed only; **not individually verified** |
| 2026-10-14 | **BAC** | Bank of America | Q3 2026 | **(C)** — from BAC's own 2026 reporting-dates release |
| ~2026-09-17 | ~~FDX~~ | ~~FedEx~~ | — | **WITHDRAWN FOR A SECOND CYCLE — see below** |

**THE MICRON DATE IS RESOLVED, AND THE ANSWER WAS A DATE NO AGGREGATOR CARRIED.** Three cycles carried MU at `(!)` across **09-22 / 09-23 / 09-29**. Micron's own release, dated **2026-08-26**, sets fiscal Q4 for **2026-09-30**. All three candidate dates were wrong. MU was ranked **#2 on PART 2A and #16 on PART 2B** last cycle on an unresolved date; it now has a first-party one, and it sits at the far end of the window rather than the middle.

**THE NIKE DATE IS RESOLVED TOO, AND FMP WAS RIGHT.** Nike's own release sets Q1 FY27 for **2026-10-01**. The prior cycle carried 09-24-or-09-29 and reasoned that "09-29 is a Tuesday and matches Nike's pattern." The pattern argument reached the wrong answer; the company's release settles it. FMP's feed had already moved to 10-01 and was, on this one row, ahead of the reasoning.

**THE ORACLE DATE IS NOW UNRESOLVED FOR A FOURTH CONSECUTIVE CYCLE, AND THAT IS ITSELF THE FINDING.** Oracle has **not issued** its customary "Sets the Date for its First Quarter Fiscal Year 2027 Earnings Announcement" release — the exact IR URL pattern used in prior years returns 404, and neither EDGAR nor the wires carry one. All three candidate dates (09-08 / 09-10 / 09-14) are analyst inference. Oracle self-announces roughly two weeks ahead, so a date should appear within days. **ORCL is ranked #1 in PART 2A and its catalyst is the first in the window; a structure or an entry cannot be dated off this row as it stands.** W4/D2: re-check `investor.oracle.com` before treating any of the three as real.

**THE FEDEX WITHDRAWAL STANDS AND IS NOW CONFIRMED AGAINST THE FILING.** FedEx changed its fiscal year end from May 31 to December 31 effective **2026-06-01**; its next disclosure is a transition-period report covering Jun–Dec 2026, and **no quarterly earnings call falls in this window**. **FMP still returns the phantom 2026-09-17 row** — it appeared again in this run's pull. Withdrawn for the second consecutive cycle, and recorded here so a third cycle does not re-add it from the feed.

### 1A.2 — Earnings catalysts, 2026-10-15 → 2026-11-24 (where the bulk feed still reaches)

| Date | Tickers | Status |
|---|---|---|
| 2026-10-15 | **TSM** | (E) · **ADR — not A-eligible** |
| 2026-10-20 | **LMT**, KO, GE, GM, NFLX, VZ | (E) |
| 2026-10-21 | UAL, T | (E) |
| 2026-10-21/22 | **GEV**, **IBM** | **(E)** cadence — *GEV corrects the prior cycle's ~10-28* |
| 2026-10-22 | **INTC**, NOK (ADR), AAL, F | (E) |
| 2026-10-22 **or** 11-12 | **AMAT** | **(!)** — single source each way, unresolved |
| 2026-10-23 | HCA | (E) |
| 2026-10-27 | V, UNH, CARR, PYPL, SOFI | (E) |
| **2026-10-28** | **MSFT, GOOGL, META, TSLA, BA**, SBUX | (E) |
| **2026-10-29** | **AAPL, AMZN**, COIN, RBLX, RIOT, RKT | (E) |
| 2026-10-30 | XOM, CVX, ABBV | (E) |
| 2026-11-02 | PLTR, FUBO | (E) |
| 2026-11-02/03 | **VRTX** | (E) cadence |
| 2026-11-03 | **AMD**, **SMCI**, PFE, PINS, RIVN, SHOP, UBER, SIRI | (E); **SMCI (C)** company |
| **2026-11-04** | **CAT** | **(C)** investors.caterpillar.com — *resolves the prior cycle's ~10-20-vs-11-04 split* |
| 2026-11-04 | ET, ETSY, HOOD, LCID, MGM, ROKU, SNAP | (E) |
| 2026-11-05 | MRNA, **DDOG** | (E) |
| 2026-11-05/06 | **AKAM** | (E) cadence |
| 2026-11-10/11 | **NBIS**, **CRWV**, SONY (ADR) | (E) cadence — *CRWV's prior 11-09-or-11-16 split narrows* |
| **2026-11-11** | **QCOM** | (E) cadence |
| **2026-11-12** | **CSCO** | **(C)** newsroom.cisco.com — *upgraded from (2S)* |
| 2026-11-12 | DIS, BILI (ADR) | (E) |
| 2026-11-17 | BIDU (ADR) | (E) |
| 2026-11-18 | **TGT**, **HD** | (E) |
| **2026-11-18** | **NVDA** | (E) — *the feed's date; NVDA has issued no FY27 Q3 release* |
| 2026-11-18/19 | **PANW** | (E) cadence |
| 2026-11-19 | **WMT** | (E) |
| **2026-11-20** | **INTU** | **(C)** investors.intuit.com |
| 2026-11-23 | ZM | (E) |
| 2026-11-24 | BABA (ADR) | (E) — **the last date the bulk feed returns** |
| 2026-11-24/25 | **WDAY** | (E) cadence |
| **2026-11-27** *or* **12-02/03** | **SNOW** | **(!)** — one aggregator says 11-27, cadence says ~12-02/03 |

### 1A.3 — The December 2026 – February 2027 tail, filled per-name for shortlisted names

**This is the block the bulk feed cannot reach at all, and the plan directs it to be filled per-name for shortlisted names at estimated provenance rather than left blank.** Every row here is `(E)` cadence-projected off the company's own prior-year date unless marked otherwise, because companies do not announce Dec–Feb dates until two to four weeks ahead. **That is expected at a 2026-08-30 vantage point and is not a research failure — but none of these may be used to date a structure.**

| Date | Ticker | Fiscal Q | Status |
|---|---|---|---|
| **2026-12-01** | **NTAP** | Q2 FY27 | **(C)** — stated in NetApp's own Q1 release; *still the only company-confirmed date in this file beyond 2026-11-24* |
| 2026-12-01 | **CRWD** | Q3 FY27 | **(2S)** |
| 2026-12-01/02 | **MRVL** | Q3 FY27 | (E) cadence |
| 2026-12-02 | **OKTA** | Q3 FY27 | **(2S)** |
| 2026-12-02/03 | **CRM** | Q3 FY27 | (E) cadence — *some aggregators claim 12-08; unverified* |
| 2026-12-03/04 | **HPE** | Q4 FY26 | (E) cadence |
| 2026-12-09/10 | **ORCL** | Q2 FY27 | (E) cadence |
| 2026-12-09/10 | **ADBE** | Q4 FY26 | (E) cadence |
| 2026-12-10 | **AVGO** | Q4 FY26 | (E) cadence |
| ~2026-12 early | COST, KR | Q1 FY27 / Q3 FY26 | (E) low confidence |
| 2026-12-16 | **MU** | Q1 FY27 | (E) vendor-inferred |
| 2026-12-17/18 | **NKE** | Q2 FY27 | (E) cadence |
| 2027-01-13/14 | **JPM** | Q4 2026 | (E) cadence |
| 2027-01-14/15 | **GS**, **TSM** (ADR) | Q4 2026 | (E) cadence |
| 2027-01-21/22 | **INTC** | Q4 2026 | (E) cadence |
| 2027-01-27 | **MSFT** | Q2 FY27 | (E) cadence |
| 2027-01-27/28 | **META**, **GEV**, **IBM** | Q4 2026 | (E) cadence |
| 2027-01-28 | **AAPL**, **CAT** | Q1 FY27 / Q4 2026 | (E) cadence |
| 2027-02-02/03 | **AMD** | Q4 2026 | (E) cadence |
| 2027-02-03/04 | **GOOGL** | Q4 2026 | (E) cadence |
| 2027-02-05 | **AMZN** | Q4 2026 | (E) single-source |
| 2027-02-24 | **HD** | Q4 FY26 | (E) cadence |
| 2027-02-25 | **NVDA** | Q4 FY27 | (E) cadence (prior three years: 2/21, 2/26, 2/25) |

**Not reached, stated so the gap is visible rather than hidden:** **TTWO**, **FSLR**, **MRK** and **DELL** have no located date beyond 2026-10-14 — TTWO and FSLR matter because both are ranked on non-earnings catalysts anyway, but MRK and DELL are genuine holes.

### 1A.4 — Product launches, keynotes and product events

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| **2026-09-09** | **AAPL** | **"Surprise and Shine" keynote, Apple Park** — iPhone 18 Pro / Pro Max and a first foldable expected; **the first keynote led by CEO Ternus** | **(2S) — UPGRADED from (E). Invites went out 2026-08-26.** |
| 2026-09-15 → 17 | CRM | Dreamforce 2026, Moscone Center SF ("The Agentic Enterprise") | **(C)** |
| 2026-09-23 → 24 | META | Meta Connect 2026 | (E) — *carried, not re-verified this run* |
| 2026-10-20 → 22 | NVDA | GTC Berlin | (E) — *carried, not re-verified* |
| 2026-10-25 → 28 | ORCL | Oracle CloudWorld / AI World 2026 | (E) — *carried, not re-verified* |
| 2026-11-10 → 12 | ADBE | Adobe MAX 2026 | (E) — *carried, not re-verified* |
| 2026-11-17 → 20 | MSFT | Microsoft Ignite 2026 | (E) — *carried, not re-verified* |
| **2026-11-19** | **TTWO** | **Grand Theft Auto VI launch** (PS5, Xbox Series X\|S); **pre-load opens 2026-11-12** | **(2S) — REAFFIRMED** |
| 2026-11-30 → 12-03 | AMZN | AWS re:Invent 2026 | (E) — *carried, not re-verified* |
| 2026-11-30 → 12-03 | NVDA | GTC Washington, D.C. | (E) — *carried, not re-verified* |
| 2027-01-06 → 09 | broad | CES 2027, Las Vegas | (E) — *carried, not re-verified* |

**THE APPLE KEYNOTE IS NO LONGER SPECULATION.** The prior cycle's row read "Apple had issued no invite as of 2026-08-19; press speculation." **Apple issued invites on 2026-08-26** for a 2026-09-09 event at Apple Park. Combined with the CEO transition confirmed below, AAPL now carries two dated September events plus its late-October print.

**THE GTA VI TRAILER HAPPENED, WHICH RETIRES A CARRIED UNCERTAINTY.** The prior cycle carried the "Extended Look" trailer at 2026-08-27 without re-verification. It **premiered on schedule** — Netflix 3:00pm ET, then Rockstar's own channels 9:00pm ET the same day, corroborated by four independent outlets. The **2026-11-19 launch is reaffirmed**, pre-orders having opened 2026-06-25 and pre-load scheduled 2026-11-12. Rockstar's own newswire returned a cookie wall to both a direct fetch and an extract, so this is `(2S)` rather than first-party.

**A BLOCK OF SEVEN CONFERENCE ROWS WAS NOT RE-VERIFIED THIS RUN, AND IS MARKED (E) RATHER THAN CARRIED AT (C).** META Connect, NVDA GTC Berlin, ORCL CloudWorld, ADBE MAX, MSFT Ignite, AMZN re:Invent, NVDA GTC DC and CES 2027 were all previously `(C)`. The sweep's budget went to the four load-bearing re-verifications above and did not reach them. **Downgrading them is the honest disposition**: a confirmation from two weeks ago is evidence about two weeks ago. Recurring annual conferences rarely move, so the practical risk is low — but "low risk" is not "verified," and this file has now twice been bitten by carrying a prior confirmation forward as a current one.

### 1A.5 — Analyst days, investor days and major conferences

| Date | Ticker | Event | Status |
|---|---|---|---|
| 2026-09-10 | LH | Labcorp Investor Day, 9am–12pm ET | **(C)** ir.labcorp.com |
| 2026-09-16 | ON | onsemi Financial Analyst Day, NYC | **(C)** onsemi.com |
| **2026-09-17** | **INTU** | **Investor Day, 8:00am–12:00pm PDT** — agenda still unpublished | **(C) investors.intuit.com — RE-VERIFIED FIRST-PARTY** |
| 2026-09-17 | DCO | Ducommun (~$3.1B) Investor Day, NYC | **(C)** |
| 2026-10-13 | BGC | FMX (BGC Group) first-ever Investor Day, NYC; Geoffrey Hinton keynote | **(C)** businesswire |

**The INTU Investor Day is confirmed and the prior cycle was right to demand it.** It was carried at `(C)` two cycles ago, not re-surfaced last cycle, and explicitly flagged as "load-bearing for a ranked row" with an instruction to re-verify before use. It was re-verified this run, first-party, and it stands. **The flag did its job — and the two corrections below show what happens on rows where an equivalent flag was raised and the answer came back the other way.**

### 1A.6 — Regulatory, legal, trade and policy decisions

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| **2026-09-04** | UNP, NSC | **STB UP–NS review: Notices of Intent to participate due** | **(C)** stb.gov PR-26-21 |
| **2026-09-29** | **GOOGL** | **DOJ v. Google search-remedies appeal — Google's REPLY BRIEF due (D.C. Circuit)**; oral argument still unscheduled | **(C)** — **NEW dated item** |
| **2026-09-30** | broad | **US government funding deadline.** A Senate-passed continuing resolution to **2026-12-11** was moving through the House with White House backing as of 08-28 | **(E)** — a live process, not a fixed outcome; **bears on whether the October BLS/BEA prints publish on schedule** |
| 2026-10-16 | V | DOJ v. Visa — fact discovery closes (expert discovery to 2027-04-08); **no trial date set** | **(C)** |
| by Oct 2026 | AAPL | Company-stated deadline to update App Store terms for EU DMA compliance | **(C)** as a commitment; **no fixed date** |
| **2026-11-10** | broad China-import-exposed | **USTR Section 301 China-tariff exclusions (178 products) expire** 11:59pm ET 11-09 absent extension | **(C)** ustr.gov |
| **2026-11-18** | UNP, NSC | STB UP–NS: public comments due | **(C)** |
| **2026-12-03** | UNP, NSC | STB UP–NS: DOJ/USDOT preliminary comments due | **(C)** |
| **2026-12-04** | **FSLR** + solar/polysilicon chain | **Section 232: 15% ad valorem tariff PLUS a minimum-import-price regime effective 12:01am ET** — polysilicon $21/kg, ingots/wafers $100/kg, cells $0.22/W, modules $0.38/W | **(C)** whitehouse.gov |
| **2027-02-16** | UNP, NSC | STB UP–NS: responses to comments and protests due | **(C)** |
| ~2027-02 | LYV | DOJ/states v. Live Nation — **remedies/breakup phase**, estimated but **unscheduled** | (E) |
| ~2027-03-29 | AMZN | FTC v. Amazon trial — **OUT of this window**, re-confirmed | **(C)** |

**CORRECTION — THE QCOM v. ARM TRIAL DATE DOES NOT HOLD, AND IT WAS THE BASIS OF A #3 RANKING.** The prior cycle promoted QCOM from **#29 to #3** explicitly on "two dated catalysts where the row previously had none," the new one being "Qualcomm v. Arm trial begins 2026-10-05 **(C) — NEW this cycle**." This run could not corroborate that date from any source. What exists is: (a) the Arm ALA/TLA licensing case, which **Qualcomm already won outright**, with final judgment around September–October **2025** — a completed matter, not a forward catalyst; and (b) a **separate** Qualcomm breach-of-contract suit against Arm, filed January 2025 and amended 2026-03-30, whose trial estimate has moved (one source places it in Q4 2026, an earlier one in March/April 2026) and for which **no source gives 2026-10-05**. The likeliest explanation is that the completed case and the pending one were conflated. **QCOM's second dated catalyst dissolves; the row returns to resting on its Q4 FY26 print.**

**CORRECTION — THE META UTECA TRIAL IS A ONE-YEAR MIS-PROJECTION OF A COMPLETED CASE.** META was ranked **#19** last cycle on a row that read "Refuted at the Q2 print (−9% on charges); **the row rests on the legal catalyst**," that catalyst being a "UTECA trial, October 2026" carried at `(C)` and flagged as not re-verified. **There is no October 2026 trial.** The UTECA/AERC unfair-competition action was joined to the parallel AMI media-association case and went to trial on **1–2 October 2025**. It produced a judgment: Madrid Commercial Court No. 15 ordered Meta to pay **~€479 million**, reported around 2026-01-30. Meta has appealed to the Madrid Provincial Court and **no appeal hearing has been scheduled.** The forward catalyst the row rested on does not exist; META's only in-window catalyst is its Q3 print. **The prior cycle's instruction to "re-verify the date before relying on it" was correct and is exactly what caught this.**

*Verified resolved or unscheduled, so a later cycle does not re-investigate:* DOJ v. Live Nation's **liability trial is complete** (jury verdict 2026-04-15 for the states; DOJ settled mid-trial for $280M with no Ticketmaster divestiture) · DOJ v. Google **oral argument unscheduled** · DOJ v. Visa **trial unscheduled**, realistically 2027–2028 · Boeing 777X certification guided to "2027," no fixed date.

### 1A.7 — Restructuring and structural events

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| **2026-09-01** | **AAPL** | **CEO transition — John Ternus succeeds Tim Cook; Cook becomes Executive Chairman** | **(C) apple.com/newsroom — RE-VERIFIED FIRST-PARTY** |
| 2026-09-01 | COP | CEO transition — Andy O'Brien succeeds Ryan Lance; Konnie Haynes-Welsh to CFO | **(C)** conocophillips.com |
| 2026-09-01 | TFC | CEO transition — Michael P. Lyons succeeds Bill Rogers | **(C)** ir.truist.com |
| 2026-09-18 | broad S&P 500 | Q3 quarterly index rebalance (third Friday; effective at the ~09-21 open) | (E) |
| **Q4 2026** | **CTVA** | **"Vylor" seed/genetics spin-off completion — CORRECTED: the company gives a QUARTER, not 2026-10-01** | **(C)** for the Q4-2026 window |
| **Q4 2026** | KMB, KVUE | Kimberly-Clark / Kenvue close — **narrowed from "by end-2026"** by Kenvue's 2026-08-06 release; contractual outside date 2026-11-02, auto-extending to 2027-05-03 if only regulatory conditions remain | **(C)** kenvue.com |
| 2026-09 → 2027-03 | TECK | Anglo American–Teck final approvals (China MOFCOM the last pending item) | **(C)** angloamerican.com |
| 2026-12-18 | broad S&P 500 | Q4 quarterly index rebalance | (E) |
| 2027-01-01 | DG | CEO transition — JJ Fleeman becomes CEO; Vasos senior advisor to 2027-04-02 | **(C)** |
| 2026-08-21 *(disclosed)* | BA | SVP Finance Ryan Shedd succeeds Michael Cleary as Controller upon the 2026 10-K filing | **(C)** 8-K Item 5.02 |

**THE APPLE CEO TRANSITION IS CONFIRMED FIRST-PARTY AND IS TWO DAYS AWAY.** Carried unverified for two cycles and flagged as load-bearing. Apple's own newsroom (announcement dated 2026-04-20, unanimous board approval) states Ternus becomes CEO **effective 2026-09-01**. It is AAPL's only dated *structural* catalyst; the keynote is 09-09 and the Q4 print is late October.

**CORRECTION — CORTEVA'S SPIN-OFF HAS NO 2026-10-01 DATE.** The prior cycle carried "2026-10-01 · CTVA · Target completion of the Vylor spin-off **(C)** company target" and ranked CTVA **#34** on it as "a dated structural catalyst, new to this list." Corteva's own releases of 2026-05-04, 2026-06-29 and 2026-08-06 say only that the separation is **"on track for the fourth quarter of 2026."** The company gives a quarter. The row is corrected to the company's own language, and CTVA's catalyst is no longer *dated* in the sense Entry criterion 1 rewards.

---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-08-30 → 2026-10-14)

C's qualifying event types **only**: corporate earnings (company IR), FDA PDUFA (FDA calendar / company disclosure), FOMC (Fed calendar). **Router reminder: only an FOMC-catalyst thesis is router-eligible; everything else in this PART is context.**

### 1B.1 — FOMC, and what Jackson Hole did to it

**Re-fetched first-party this run from `federalreserve.gov/monetarypolicy/fomccalendars.htm`.**

| Event | Detail | Date | In window? |
|---|---|---|---|
| **FOMC** | Meeting **2026-09-15/16**, decision **Wed 2026-09-16**, **WITH a Summary of Economic Projections** (asterisked on the Fed's own page) | **2026-09-16 (C)** | **YES — the only one** |

Remaining meetings off the same page: **2026-10-27/28** (no SEP) · **2026-12-08/09** (SEP) · 2027-01-26/27 · 2027-03-16/17 (SEP) · 2027-04-27/28 · 2027-06-08/09 (SEP) · 2027-07-27/28 · 2027-09-14/15 (SEP) · 2027-10-26/27 · 2027-12-07/08 (SEP). **The prior cycle's reading is confirmed exactly, with no changes.** The 2:00pm ET decision / 2:30pm ET press-conference timing is the Fed's standard format and is corroborated by two secondary sources; the calendar page itself does not print per-meeting times, and this file does not claim it does.

**The one FOMC inside this window remains the only SEP-carrying meeting before December** — a second, independent source of surprise beyond the rate decision.

> #### JACKSON HOLE, 2026-08-27 → 08-29 — THE INPUT THE PRIOR CYCLE SAID WOULD BE KNOWN BY 09-08, AND IT IS HAWKISH
>
> Chair Warsh delivered his first Jackson Hole keynote as Chair — **"In Our Time," Friday 2026-08-28**, full text on federalreserve.gov. Verbatim, from the Fed's own posting:
>
> - *"Inflation is running above our 2 percent target. So the Fed's predominant focus right now should be on prices."*
> - *"The 12-month change in the PCE price index, stands at 3.7 percent, while the six-month change is 4.1 percent."*
> - *"Of goods and services in the PCE basket, 49 percent showed annualized price increases above 3 percent."*
> - *"We must be confident that underlying inflation is moving to our objective, clearly and at sufficient speed. Otherwise, we have work to do."*
> - *"I stand here today committed to a discipline, not to a decision."*
>
> **He gave no explicit September signal, and withholding one was deliberate. That is the finding, not a gap in the research.**
>
> **The market did not read it as neutral.** Same session: **2Y +>12bp to 4.356% · 10Y +>5bp to 4.726% · 30Y +2bp to 5.211%.**
>
> **And the September hike odds re-priced hard.** Kalshi's own recap puts it at **30% pre-speech → 47% after**. Polymarket's event page, fetched directly on 2026-08-30, reads **47% hike / 51% no change**. CNBC cites CME FedWatch at **55.7%**, roughly 20 percentage points above the prior day — **one source removed**, because FedWatch is JS-rendered and has never been readable first-party from this environment, in this or any prior cycle. The three do not fully agree and are not forced into one number here.

**The trend across five cycles, which is what the 09-08 session actually needs:** ~56–62% (early August) → ~36–43% (mid-August) → ~29–32% (~08-16) → **~30% (08-27, pre-speech) → high-40s/mid-50s (08-28, post-speech).**

**Corroborating hawkish commentary in-window, from the July dissenters themselves:** **Hammack** (CNBC from Jackson Hole, Thu 2026-08-27) — *"I think it's appropriate for us to put some restraint there to help bring inflation back down to target. The longer inflation stays above our objective, the harder it will be for us to bring it back down."* **Kashkari** (CBS *Face the Nation*, Sun 2026-08-23) — *"I'm not feeling confident right now that inflation is heading back down to target in a short period of time,"* and separately flagging the Iran conflict as extending the inflation imprint. **Logan has made no public statement since her 2026-07-31 dissent** — a measured absence off the Dallas Fed's own speeches index, not an unchecked one.

**Scheduled macro releases between this file and the decision — context, not C-qualifying:**

| Date | Release | Agency | Confirmation |
|---|---|---|---|
| 2026-09-01 | ISM Manufacturing PMI (Aug) | ISM | **Calculated** from the first-business-day rule |
| 2026-09-03 | ISM Services PMI (Aug) | ISM | **Calculated** from the third-business-day rule |
| 2026-09-04 | **Employment Situation, August** | BLS | Calculated from the first-Friday norm |
| 2026-09-10 | **PPI, August** | BLS | **Confirmed** bls.gov |
| **2026-09-11** | **CPI, August** | BLS | **Confirmed** bls.gov |
| **2026-09-16** | **FOMC decision + SEP** | Fed | **Confirmed** |
| 2026-09-30 | PCE + Personal Income, August | BEA | **Confirmed** — *after* the decision |
| 2026-09-30 | GDP Q2, third estimate | BEA | **Confirmed** |
| 2026-10-02 | Employment Situation, September | BLS | **Confirmed** |
| **2026-10-14** | **CPI, September** | BLS | **Confirmed — lands on the LAST DAY of this window** |
| 2026-10-15 | PPI, September | BLS | Confirmed — *one day outside the window* |

**One CPI, one PPI, one payroll report and one ISM pair land between this file and the decision.** **No Treasury quarterly refunding falls in the window** (next 2026-11-04) and **no Humphrey-Hawkins testimony** (Warsh testified 2026-07-14/15; next ~February 2027). Both stated as measured absences, because "no row" and "not checked" are otherwise indistinguishable.

**A prior-cycle disposition, revisited honestly.** The 2026-08-23 file **dropped** an FOMC-minutes row it had inferred at "~2026-08-19," on the ground that the Fed publishes minutes dates only for meetings already past and the item was therefore never verifiable forward. **The July minutes were in fact released on 2026-08-19.** Dropping the row was still the right call on the evidence available — the inference happening to be correct does not make it sound — but the outcome is recorded rather than quietly omitted.

**Prints that landed since the prior file, which a September thesis has to account for:**
- **July PCE (released 2026-08-26, BEA):** headline **+3.7% y/y** against ~3.6% consensus — **hotter** — and **+0.2% m/m** against ~0.1% expected. Core **+3.3% y/y**; sources disagree on whether that matched or exceeded a ~3.2% consensus, and the disagreement is **carried as unresolved** rather than settled by picking one. Note that Warsh's own speech quotes the same 3.7% headline and adds a **six-month rate of 4.1%** — i.e. the Chair is pointing at acceleration within the trailing year, not just the level.
- **Q2 2026 GDP, second estimate (2026-08-26, BEA):** **+1.5% SAAR, unchanged** from the advance estimate, against Q1's +2.1%.

### 1B.2 — Corporate earnings inside the 45-day window

Same dated set as 1A.1 falling 2026-08-31 → 2026-10-14, status carried verbatim: **DELL (C)** / **PANW (2S)** / NIO 9/01 · **AVGO (C)** / **SNOW (C)** / **HPE (2S)** / **NTAP (C)** 9/02 · **LULU (C)** / **DOCU (C)** / **CPB (C)** 9/03 · RH 9/03-or-9/10 **(!)** · **ORCL ~9/08 (!)** · GME ~9/08-09 **(!)** · **CHWY (C)** 9/09 · **ADBE (2S)** 9/10 · **KR (C)** 9/11 · **AZO (C)** 9/22 · **GIS (C)** 9/23 · CTAS ~9/23-24 (E) · **DRI (2S)** / **COST (C)** / **JBL (2S)** 9/24 · PAYX ~9/29-30 (E) · **MU (C) 9/30** · ACN ~late-Sept (E) · **NKE (C) 10/01** · STZ ~10/01 (E) · CCL **(2S)** 10/05 · **PEP (2S)** / DAL (E) / TLRY (E) 10/08 · **JPM (C)** + GS/C/WFC/JNJ (E) 10/13 · **BAC (C)** 10/14.

*FDX is deliberately absent — see the FedEx correction in 1A.1.* *NVDA, CRM, CRWD, OKTA, MRVL, INTU, WDAY, DG, DLTR and ZM all reported 2026-08-25 → 08-27 and are correctly outside this window; their results are in the past-window section of PART 2A.*

### 1B.3 — FDA PDUFA and advisory actions inside the 45-day window

> **THE THREE PENDING PDUFAs FROM LAST WEEK ALL RESOLVED, ALL AS APPROVALS — AND ONE OF THEM HAD ALREADY RESOLVED SIX WEEKS BEFORE THIS FILE RANKED IT.** See the correction block below the table. This is the most consequential sourcing lesson of the cycle.

| Date | Ticker | Company (approx cap) | Drug / indication | Event | Status |
|---|---|---|---|---|---|
| 2026-09-11 | **TLX** | Telix (**~$6B** — *corrected up from the prior cycle's ~$3.4–3.8B*) | Pixclara (TLX101-Px), recurrent glioma PET imaging | NDA PDUFA | **(C)** telixpharma.com |
| 2026-09-19 | **RARE** | Ultragenyx (**~$2.5–2.6B — borderline**) | UX111, Sanfilippo A gene therapy | Resubmitted BLA | **(C)** ir.ultragenyx.com |
| 2026-09-21 | **MRK** | Merck | **Winrevair (sotatercept), HYPERION-based label update — newly-diagnosed PAH** | sBLA PDUFA | **(2S) — DOWNGRADED from (C)**, see below |
| 2026-09-22 | **IONS** | Ionis (~$9B) | Zilganersen, Alexander disease | NDA PDUFA | **(C)** ir.ionis.com |
| **2026-09-23** | **GRAL** | GRAIL (**~$3.7–3.9B** — *corrected up from ~$3.0B*) | Galleri MCED test | **CDRH Molecular & Clinical Genetics Panel — a PMA advisory VOTE, not a final decision** | **(C)** Federal Register 2026-16245 |
| 2026-09-26 | **INCY / MIRM** | Incyte / Mirum (~$6B) | Zilurgisertib, fibrodysplasia ossificans progressiva | NDA PDUFA | **(C)** both sponsors |
| ~2026-09-30 | **PTGX / TAK** | Protagonist / Takeda | Rusfertide, polycythemia vera | NDA PDUFA | **(2S)** — Takeda confirms only "Q3 CY2026"; the 09-30 day is tracker-derived |
| ~2026-09-30 | **ROIV** | Roivant / **Priovant** (~$8B) | **Brepocitinib, dermatomyositis** | NDA PDUFA | **(2S)** — Roivant states "Q3 CY2026, launch expected end of September" |
| 2026-09-30 | **SRRK** | Scholar Rock (~$5.7–6.2B) | Apitegromab, SMA | Resubmitted BLA | **(C)** investors.scholarrock.com — *upgraded from (R)* |
| 2026-09-30 | **BMY** | Bristol Myers Squibb | Camzyos, adolescent obstructive HCM | sNDA PDUFA | **(C)** news.bms.com — *upgraded from (R)* |
| ~Sept 2026 | **NVO** | Novo Nordisk | Denecimig (Mim8), hemophilia A | BLA PDUFA | **(R) — UNRESOLVED.** Trackers give Aug 15 (already past, no outcome found) or "Q3 2026"; no Novo-issued date located. **The weakest row in this table; re-check first next cycle.** |
| 2026-10-04 | **MRK / Eisai** | Merck / Eisai | Welireg + Lenvima, advanced RCC | sNDA PDUFA | **(2S)** |
| **2026-10-10** | **MRK / Daiichi Sankyo** | Merck / Daiichi Sankyo | **Ifinatamab deruxtecan (I-DXd), ES-SCLC post-platinum** (RTOR + Project Orbis) | BLA PDUFA | **(C)** merck.com, quoted verbatim — **newly inside the window as it rolled** |
| 2026-10-15 | RHHBY | Roche/Genentech | Enspryng (satralizumab), thyroid eye disease | sBLA PDUFA | **(C)** roche.com — *one day outside; carried for continuity* |

> #### THE CORRECTION THAT MATTERS MOST THIS CYCLE: TWO ROWS WERE RANKED ON DATES THAT HAD ALREADY BEEN ACTED ON
>
> **GSK / zidesamtinib, carried at "2026-09-18 (C)" — the drug was APPROVED on 2026-07-22 as Jideytro**, ahead of its PDUFA date, for previously-treated ROS1+ NSCLC (gsk.com). It sat in the prior cycle's 1B.3 as a live in-window binary. **This is the third distinct error in the NUVL lineage**: first the ticker was wrong (Nuvalent had been acquired and NUVL no longer traded), then the sponsor was reassigned to GSK correctly — and now it turns out the event itself was already spent.
>
> **BIIB / Leqembi IQLIK subcutaneous initiation dose, carried at "2026-08-24 (C)" with a note that the FDA "has raised no approvability concern" — it was APPROVED on 2026-07-13**, six weeks before the date this file ranked it on. **BIIB was ranked #45 on that catalyst.** (One residual ambiguity is stated rather than hidden: Leqembi has had more than one subcutaneous filing, and this run's source is a joint Eisai/Biogen release explicitly describing an **initiation-dose** approval on 07-13. If a distinct starting-dose sBLA with an 08-24 date existed separately, this run did not find it — but nothing supports treating 08-24 as live.)
>
> **The common failure is not weak sourcing. Both rows were confirmed against the sponsor's own material. What was confirmed was that a PDUFA date had been SET — not that it was still OUTSTANDING.** For a regulatory catalyst those are different questions, and the FDA acting early makes them come apart routinely. **Every PDUFA row in this file is now checked for an intervening action, not merely for a scheduled date**, and that check is what produced both corrections above and the three resolutions below.

**Resolved before this window opened — recorded because trackers still list some of them as pending:**
- **BIIB / Eisai — Leqembi IQLIK SC initiation dose: APPROVED 2026-07-13** (joint Eisai/Biogen release).
- **JAZZ — Ziihera (zanidatamab-hrii) ± tislelizumab + chemo, 1L HER2+ gastroesophageal: APPROVED on its date, 2026-08-25** (globenewswire).
- **GILD — bictegravir + lenacapavir: APPROVED on its date, 2026-08-27, as Bixlenvo** (gilead.com).
- **GSK — zidesamtinib: APPROVED 2026-07-22 as Jideytro** (gsk.com).

**All four carried-in pending events closed, and all four as approvals.** That is a notable base rate in itself and is recorded as an observation, not extrapolated into an expectation for the rows above.

**Corrections to the carry-in list:** **ROIV/PFE → ROIV only.** Brepocitinib is a **Roivant/Priovant** asset; Pfizer's involvement was carried in error, and Pfizer's separate vitiligo program (ritlecitinib) has no PDUFA date. The **indication, dermatomyositis, was right.**

**Below the $2B floor or not US-listed, stated so the exclusions are auditable:** **VNDA** (imsidolimab, GPP) — market cap **~$349M**, far below the floor; the prior cycle listed it in the beyond-window block with no exclusion, which is corrected here · **INO** (INO-3107, 10-30) sub-$2B · **DCPH** (tirabrutinib, 12-18) — **the stale-sponsor trap confirmed again**: a live tracker still credits Deciphera, which Ono Pharmaceutical acquired in 2024; DCPH does not trade and Ono is Japan-listed · **Pierre Fabre** (tabelecleucel, ~10-10) private/French · **Zydus** (saroglitazar, ~11-27) India-listed · **PYXS**, **CLDI** sub-$2B and pre-BLA.

### 1B.4 — Beyond-window PDUFAs (2026-10-15 → 2027-02-28), A-side context only

**VTRS/Opus** phentolamine ophthalmic **10-17 (C)** · **IONS/GSK** bepirovirsen **10-26 (C)** · **SMMT** ivonescimab, EGFRm NSCLC 2L+ **2026-11-14 (C)** — **NEW to this file, ~$12B, and materially contested**: HARMONi's Western-subgroup overall survival was directional but not statistically significant (HR 0.76 at the June 2026 cut), so this is a genuine binary rather than a formality · **SNY** venglustat **11-25 (C)** · **BBIO** BBP-418 **11-27 (C)**, FDA not planning an AdCom · **GSK** neladalkib **11-27 (2S)** · **VRTX** povetacicept, IgA nephropathy **11-30 (C)** · **RHHBY** giredestrant **adjuvant** early-stage breast **11-30 (C)** — *a **separate filing** from the 12-18 one, which the prior cycle did not carry* · **EXEL** zanzalintinib + atezolizumab **12-03 (2S)** · **GILD/ACLX** anito-cel **12-23 (2S)** · **RHHBY** giredestrant + everolimus, ESR1-mutated **12-18 (C)** · **MLYS** lorundrostat **12-22 (C)**, ~$2.2–2.4B borderline · **PRAX** relutrigine **12-27** — *one tracker flags a possible drift from 09-27; re-verify* · **COGT** bezuclastinib **12-30**, carried unconfirmed this cycle · **NUVB** taletrectinib **2027-01-04 (C)** — **corrected in KIND: this is an sNDA duration-of-response LABEL UPDATE on an already-approved drug, not a first-approval binary**, which the prior cycle's listing implied · **BLTE** tinlarebant **2027-02-12**, carried unconfirmed.

**AdCom coverage remains incomplete for a structural reason, not a search failure.** FDA posts advisory-committee notices only ~30–75 days ahead via the Federal Register, and `fda.gov`'s live calendar is JS-rendered and has returned 401 to a direct fetch in prior cycles. **This run went to the Federal Register directly instead of retrying fda.gov, which is how the GRAIL panel was confirmed** (docket FDA-2026-N-8004, FR notice 2026-16245). A further Federal Register search surfaced **no other sponsor-specific AdCom notice inside window C**. October meetings may simply not be noticed yet — re-run next cycle rather than treating this as complete.

---

## PART 2A — Strategy A preliminary ranked shortlist (46 candidates)

W4 reads this section verbatim.

**ROUTING — both gates shut, one re-scored in two days, and this week's evidence argues it stays shut.** (i) **Router:** A = **DO-NOT-ACTIVATE** (`div-A-202607-1`, 2026-08-05; re-affirmed 2026-08-13). Every name below routes to the `Watchlist.md` A-queue with reason "router gate; queued for next M1 ACTIVATE"; **no thesis-construction is enqueued this cycle.** (ii) **Capital:** A is capital-disabled at **NAV $0.00**, `outstanding_debt` **$3,888.45**. **Both must lift.** Next router resolution: **M1a 2026-09-01 11:00 UTC → M1b 12:00 UTC**, plus a divergence review if the call diverges from the technical read (it did last cycle, and took four days).

Per candidate: (a) hypothesised direction, (b) supporting public documents, (c) catalyst date, (d) **REACH**, (e) overlap, (f) tier. Direction is a *preliminary* synthesis hypothesis; full thesis construction (adversarial counter-argument attacking **size as well as direction**, immutable at-entry price target and completion criteria per Entry criterion 3, the criterion-6 historical-analogue exclusion) happens in W4-scheduled sessions.

> ### THE REACH MARKER IS NOW TWO-EPOCH, AND THE REASON IS THE FINDING ABOVE
>
> The prior cycle used a single cut at ~2026-09-05. That was right when the M1 re-score was nine days out and its direction was genuinely open. It is the wrong instrument now, because the question is no longer "is the catalyst after the re-score" but "**which** re-score."
>
> - **E1** — reachable if the **2026-09-01** re-score flips A *and* capital is restored: catalyst on/after **~2026-09-05**.
> - **E2** — reachable if 09-01 holds DNA and the **2026-10-01** cycle flips it: catalyst on/after **~2026-10-05**.
> - **SPENT** — catalyst before ~2026-09-05, unreachable under either.
>
> **Ranking stays on conviction, and ties break toward E2**, because that is the epoch this week's evidence makes more likely. A row that is E1-only is not wrong — it is a bet on the sooner gate. **A spent catalyst still does not demote a name**; it keeps its narrative standing and its `Watchlist.md` row, and its next in-window catalyst is named.

### What the week established, and why it re-orders the list

Ten large-cap names reported between 2026-08-25 and 2026-08-27, and Friday 2026-08-28 then repriced the whole complex on the Fed. The prior cycle's organising question was *composition-of-beat* — derived from AMD and DDOG both beating and falling on a second-order line item. **This week sharpens that materially, and in a way that partly refutes the form it was carried in.**

| Name | Quarter vs consensus | What the guide did | Reaction |
|---|---|---|---|
| **CRM** | Rev $11.345B +10.8%; non-GAAP EPS $5.90 | **FY27 revenue RAISED to $46.1–46.4B; FY27 EPS $16.67–16.71** | **+22.58%** (08-27) |
| **OKTA** | Rev $805M +11% vs ~$793–795M; adj EPS $1.05 vs ~$0.96 | **FY27 EPS RAISED to $3.90–3.94** | **+28.63%** (08-27) |
| **CRWD** | Rev $1.47B +26% vs $1.44B; ARR $5.84B +25%, record $332.8M net-new | **FY27 revenue RAISED to $5.99–6.01B** | **+20.50%** (08-27) |
| **NVDA** | Rev $96.22B vs $92.17B; non-GAAP EPS $2.22 vs $2.10; DC $89.0B | **Q3 guide $108B ±2% vs $104.2B street** | **+8.74%** (08-27), then **−4.57%** (08-28) |
| **MRVL** | Rev $2.739B **record**, +37%; DC $2.17B +46%; adj EPS $0.94 vs ~$0.93 | **FY27 raised to ~$12B; FY28 raised to ~$18B from ~$16.5B one quarter ago** — but **Q3 gross margin guided DOWN to 57.5–58.5%** | **−10.28%** (08-28) |
| **INTU** | Rev $4.4B +14% vs ~$4.27B; non-GAAP EPS $4.03 +47% | **FY27 revenue growth guided 9–10%, against FY26's realised +14%** | **−4%** (08-26) |
| **WDAY** | Rev $2.649B +12.8%; non-GAAP EPS $2.75 vs ~$2.61 | FY27 subscription raised to ~$9.94B, **but the Q3 subscription guide missed** | **−7% after hours, then +5.76% (08-28)** |
| **DLTR** | Adj EPS $2.70 vs $1.15 — a ~135% beat | FY26 EPS raised to $7.70–8.05, **but Q3 EPS guided $0.80–0.95 against ~$1.40 consensus** | **−3% to −3.7%** (08-27) |
| **DG** | Diluted EPS $2.48 vs ~$2.00; comps +3.5% | FY26 EPS raised to $7.80–8.00 from $7.20–7.45 | **+2.5% to +5%** (08-27) |
| **ZM** | Rev $1.28B +4.9%, beat the guide high end; adj EPS $1.55 | FY27 raised, **but the Q3 EPS guide midpoint ~$1.47 came in ~2% light** | **~−9.3% across two sessions** |

**Read down the "guide" column and the pattern is unambiguous, and it is not the one this file has been carrying.** Every name whose *forward* number went up was bought hard. Every name whose forward number decelerated, or whose forward *margin* deteriorated, was sold — **regardless of how large the beat was.** DLTR beat by ~135% and fell. MRVL set a revenue record, raised both FY27 and FY28, and fell 10.28% on a gross-margin line. INTU beat and fell on a growth rate, and JPMorgan cut its price target from **$605 to $331**.

**This refines the prior cycle's framing rather than confirming it.** "Composition of beat" was close, but it pointed at the reported quarter. **The operative variable is the forward guide — its growth rate and its margin — not the quarter that was just delivered.** And it explicitly **refutes the general form of the AMAT/CSCO thesis** carried at #15/#16, which held that "beats keep landing and the tape keeps selling." On 2026-08-26/27 the tape emphatically *bought* beats — five of them, violently — whenever the guide accelerated. D1's independent same-day reading of the software/cyber cluster (conviction 60) was that a "SaaSpocalypse" de-rating premise "got repriced hard in one session across independent reporters." **The sold-on-a-beat pattern survives only where the forward number disappointed, and, on 2026-08-27, in hardware specifically — HPQ fell 2.92% on a beat-and-raise the same day software was bought.** That is a narrower and more testable claim than the one it replaces, and PART 2A is re-ordered on it.

**The measured price data supports the same re-ordering from the other side.** All 39 A-side names were measured this run against IBKR regular-session daily bars through 2026-08-28, with eight rows individually re-fetched and all eight matching. The 30-bar move splits the list cleanly: names where the market has already moved *toward* the thesis — **SMCI +55.60%, CRM +47.30%, NOW +38.21%, PLTR +38.15%, MSFT +27.65%, ORCL +24.28%, ADBE +24.19%, INTU +21.86%, MRK +19.25%** — have *less* remaining misalignment for A to exploit, which is a reason to demote them, not a reason to chase. Names still de-rating against improving documents — **GEV −15.50%, AKAM −12.72%, AMAT −12.18%, META −10.51%, DDOG −9.96%, WMT −8.12%, INTC −7.82%, AMD −7.54%, CAT −7.41%** — are where a catalyst-driven long has something to be right about.

**Strategy A's edge is a gap between documents and price. A closed gap is a completed thesis, not a strong one.**

### Two eligibility and universe facts measured this run

**GRAL FAILS STRATEGY A's LIQUIDITY RAIL AND IS STRUCK FROM THE SHORTLIST — this is mechanical, not a judgment.** `strategy/03_strategy_a.md` requires 30-day ADV **≥ $10M**. GRAL measures **$6.8M/day** (mean of close × raw share volume over 30 IBKR daily bars through 08-28). It is the **only one of the 39 measured names that fails**, and it was ranked **#35** last cycle on the Galleri advisory panel. The panel is still a real dated event and stays in 1B.3 as context; **the ticker cannot carry a Strategy A position.** Every other name clears the floor with room — the range runs from **TTWO $65.1M** and **NTAP $47.0M** at the thin end to **NVDA $2,830.8M** and **AAPL $2,086.7M** at the wide end.

**Market capitalisation could NOT be verified this run, and that is stated rather than glossed.** The IBKR connector exposes no market-cap field for operating companies (`get_price_snapshot` carries only `total_net_assets`, which applies to funds), and FMP's per-symbol `quote`/`market-cap` path is parameter-gated for every symbol outside its ~87-name allow-list. **So the ≥ $2B floor is asserted from prior-cycle readings and general knowledge for every name below except AAPL** (FMP returned a full `marketCap` of $4.620T for it on 08-27, an allow-listed symbol). No name on this list is near the floor except RARE (~$2.5–2.6B) and MLYS (~$2.2–2.4B) in the PDUFA tables, both flagged in place.

### TOP-10

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | REACH | Measured (close 08-28 / 30-bar) | Overlap |
|---|---|---|---|---|---|---|---|
| 1 | **GEV** | Bullish — **the widest documents-vs-price gap on the measured list** | Q2 (07-22): revenue $11.1B **+22%**, **orders +88% to $24.2B**, backlog **$176B** including 116GW of gas-power reservations and >$5B of 2026 data-centre orders; FY26 guidance raised. Against that, the stock is **the single worst 30-bar performer of all 39 names measured** | **Q3 ~2026-10-21/22 (E)**; Q4 ~2027-01-27/28 (E) | **E1 + E2** | 911.93 / **−15.50%** · ADV $388.8M | **Open D position** — correlation check required, not a bar |
| 2 | **MRVL** | Bullish — **the cleanest instance of this cycle's actual pattern** | Q2 FY27 (08-27): revenue **$2.739B, a record, +37% y/y**; data-centre **$2.17B +46%**; adj EPS $0.94. **FY27 outlook raised to ~$12B and FY28 raised to ~$18B from the ~$16.5B given one quarter earlier.** The stock fell **10.28%** the next session on a Q3 **gross-margin** guide of 57.5–58.5% and an absence of Google-deal detail. Two raised multi-year revenue outlooks against one quarter of margin mix | **Q3 FY27 ~2026-12-01/02 (E)** | **E2** | 216.62 (08-28) / not in the 39-name sweep · thin coverage flagged | A-queue |
| 3 | **AMAT** | **Bearish — but the thesis must NARROW, and this is the correction** | The row was carried as "beats keep landing and the tape keeps selling, pattern 4-deep." **The general form is refuted by 2026-08-26/27**, when five software beats were bought violently. What survives is the *hardware/semicap* form: AMAT's FQ4 (08-13, adj EPS $3.50, revenue +25% to $9.12B) closed **−5.12%**, and HPQ fell **2.92% on a beat-and-raise** on 08-27, the same session software was bid. Still de-rating: **−12.18% over 30 bars** | **Q4 FY26 2026-10-22 or 11-12 (!)** | **E1 + E2** | 461.67 / **−12.18%** · ADV $496.2M | A-queue |
| 4 | **INTC** | Bullish | Q2: revenue **$16.1B +25% y/y** (fastest in 15+ years), **DCAI +59%**, gross margin back to 42%, capex raised >$20B, management "cannot keep up with orders" — **unrefuted by any subsequent disclosure**, and INTC rose only 4.36% on 08-27 in the NVDA halo | **Q3 2026-10-22 (E)**; Q4 ~2027-01-21/22 (E) | **E1 + E2** | 89.47 / **−7.82%** · ADV $1,226.0M | A-queue |
| 5 | **DDOG** | **Contested — and the objection is now a year-old cohort question** | The 08-06 customer-concentration objection — a disclosed usage decline from its largest customer beginning Q3, **on a beat-and-raise** (−19.03%) — remains open and unanswered. But the software cohort it sits in was re-rated hard on 08-26/27 without DDOG participating, and it is still **−9.96%** over 30 bars. Either the objection is specific and correct, or DDOG is being left behind by a cohort re-rating. **That is a decidable question at the next print, which is what makes it rankable** | **Q3 ~2026-11-05 (E)** | **E1 + E2** | 236.98 / **−9.96%** · ADV $130.0M | A-queue; objection OPEN |
| 6 | **CAT** | Bullish — ratified, runway contested | Q2 (08-04): sales **$20.543B +24% y/y** (first quarter above $20B), adj EPS **$8.17 vs ~$6.20** consensus — largest beat in five years — record **$63B backlog**, E&T/power-gen **+29% y/y on data-centre demand**, FY guidance raised. Still de-rating at **−7.41%**. **Its date is now confirmed**, which removes the prior cycle's `(!)` | **Q3 2026-11-04 (C)** caterpillar IR; Q4 ~2027-01-28 (E) | **E1 + E2** | 800.25 / −7.41% · ADV $495.8M | A-queue |
| 7 | **ORCL** | Bullish (deep re-base) — **but the date is unresolved for a fourth cycle** | The **~$7B, 10-year DoD software-consolidation award** (07-27; initial 5-yr tranche $3.31B) ratifies the OCI-bookings/RPO thesis *at the layer it predicted*. **But the market has now moved a long way toward it: +24.28% over 30 bars**, which is the largest single-name re-rating among the de-rated cohort's neighbours and materially reduces the remaining gap | **Q1 FY27 ~09-08 / 09-10 / 09-14 (!) — NO Oracle release exists**; Oracle AI World 10-25→28 (E); **Q2 FY27 ~12-09/10 (E)** | **E1 only** on the September print · **E2** on the December print | 150.85 / **+24.28%** · ADV $667.3M | A-queue |
| 8 | **AMD** | **Direction CONTESTED** | The 08-03 thesis (MI400 shipped, roadmap risk converted to product) was ratified on product and refuted elsewhere at the 08-04 print. Two-sided: it priced its largest-ever USD bond ($4.75B, four tranches) to fund AI capex on 08-14 and **rose** 6.50% — the market rewarding financing it punished AVGO for. Now **−7.54%** over 30 bars | **Q3 2026-11-03 (E)**; Q4 ~2027-02-02/03 (E) | **E1 + E2** | 465.58 / −7.54% · ADV $1,363.7M | A-queue |
| 9 | **TTWO** | Bullish — **the largest dated non-earnings catalyst in the window, and it is now re-confirmed** | **GTA VI launches 2026-11-19**, the trailer landed on schedule 2026-08-27 (Netflix 3pm ET, Rockstar 9pm ET), pre-orders opened 06-25 and **pre-load opens 2026-11-12**. Unaffected by either AI objection class, and essentially flat at **−1.50%** while the AI complex swung violently — an uncorrelated dated binary | **Product launch 2026-11-19 (2S)** | **E1 + E2** | 235.39 / −1.50% · **ADV $65.1M — thinnest but clears** | A-queue |
| 10 | **AKAM** | Bearish/contested — **promoted on measurement, not on news** | Still names no dated contract or figure, which caps it. But it is the **second-worst 30-bar performer measured (−12.72%)** and it did not participate in the 08-26/27 software re-rating despite sitting adjacent to that cohort. The same decidable question as DDOG, one tier down on evidence quality | **Q3 ~2026-11-05/06 (E)** | **E1 + E2** | 107.47 / **−12.72%** · ADV $48.6M | A-queue |

### 11–20

| # | Ticker | Direction | Note | Catalyst | REACH | Measured |
|---|---|---|---|---|---|---|
| 11 | **META** | **Reframed — and the row it rested on has been deleted** | Refuted at the Q2 print (−9% on charges). The prior cycle ranked it #19 saying "**the row rests on the legal catalyst**" — the UTECA trial. **That trial does not exist in this window** (held 1–2 Oct **2025**, ~€479M judgment, appeal unscheduled). What is left is a name **−10.51%** over 30 bars with only its print. The de-rating is real; the mechanism named for it was not | Q3 **2026-10-28 (E)**; Q4 ~2027-01-27/28 (E) | E1 + E2 | 578.02 / −10.51% · ADV $1,152.8M |
| 12 | **WMT** | Bearish/contested | **−8.12%** over 30 bars; Oppenheimer downgrade with the $140 PT withdrawn. Retail guidance shock was the 08-25 theme (DKS −30.68% with contagion into TGT/KSS/BBWI, per D1) and WMT did not escape it | Q3 FY27 **2026-11-19 (E)** | E1 + E2 | 103.09 / −8.12% · ADV $337.8M |
| 13 | **CSCO** | Bullish — metric ratified, price re-rated | FQ4 (08-13) beat both lines — revenue **$17.3B +18% y/y**, adj EPS **$1.22 vs $1.17** — and **FY2026 AI-infrastructure orders landed at $9.3B, ~4.5× prior year, above the $9B the thesis cited.** Flat since (−0.70%). **Its date is now company-confirmed** | Q1 FY27 **2026-11-12 (C)** cisco newsroom | E1 + E2 | 109.93 / −0.70% · ADV $300.9M |
| 14 | **QCOM** | **DEMOTED from #3 — one of its two dated catalysts dissolved** | Promoted #29 → #3 last cycle explicitly on "two dated catalysts where the row previously had none," the new one being a **2026-10-05 Qualcomm v. Arm trial that no source corroborates** (see 1A.6). The licensing case Qualcomm already **won** in 2025 appears to have been conflated with a separate, undated suit. **The row returns to resting on its print.** Also **−3.60%** over 30 bars | Q4 FY26 **~2026-11-11 (E)** | E1 + E2 | 164.19 / −3.60% · ADV $210.0M |
| 15 | **CRWV** | Bullish — two-sided by construction | Q2 (08-11): revenue **$2.575–2.6B, +112% y/y**; adj op margin ~5% vs ~2.7% expected; **backlog $104B, +246% y/y**; FY26 guide raised to $12.4–13.2B. Simultaneously the strongest demand document and the purest instance of the financing objection — **and that objection produced a fresh instance this week** (below) | Q3 **~2026-11-10/11 (E)** | E1 + E2 | 84.23 / +15.29% · ADV $382.4M |
| 16 | **GOOGL** | Bullish | Cloud rev/margin/RPO trend intact; UK CAT class-action certified and assessed NOT a D-breach. Essentially unmoved at **−1.53%**. **New dated item: Google's reply brief in the DOJ search-remedies appeal is due 2026-09-29**, though oral argument is unscheduled | Q3 **2026-10-28 (E)**; reply brief **09-29 (C)**; Q4 ~2027-02-03/04 (E) | E1 + E2 | 346.59 / −1.53% · ADV $1,337.7M |
| 17 | **NVDA** | Bullish — **thesis ratified at the print, then half given back on the Fed** | FQ2 FY27 (08-26, primary-verified): revenue **$96.221B vs ~$92.27B**, non-GAAP EPS **$2.22 vs $2.09**, **Q3 guide $108.0B ±2% against ~$104B**, data centre $89.0B. Rose **+8.74%** on 08-27 — then fell **−4.57%** on 08-28 as Warsh spoke. **Measured, and worth stating: roughly half the post-print re-rating was surrendered to a macro session within 24 hours** | Q3 FY27 **2026-11-18 (E)**; GTC Berlin 10-20→22 (E); Q4 ~2027-02-25 (E) | E1 + E2 | 217.55 / +7.02% · **ADV $2,830.8M, the most liquid name here** | A-queue |
| 18 | **MU** | Bullish — **and its date is finally company-confirmed** | Load-bearing evidence remains a *customer's own disclosure*: QCOM's FQ4 guide-down explicitly citing "unprecedented increases in memory pricing." **Micron's own release now sets Q4 FY26 for 2026-09-30**, closing three cycles of `(!)`. But 09-30 falls **five days short of E2** — MU is precisely the name whose reachability depends on which epoch obtains | **Q4 FY26 2026-09-30 (C)**; Q1 FY27 ~2026-12-16 (E) | **E1 only** on the September print · E2 on December | 932.86 / +7.79% · ADV $4,307.6M |
| 19 | **INTU** | **Direction now genuinely two-sided, and the row is stronger for it** | The prior cycle held it at #4 for having "two dated disclosure events rather than one." **Both are now confirmed** — Investor Day **09-17** first-party, Q1 FY27 **11-20** first-party. But the print itself was a **beat that fell 4%** on an FY27 guide of 9–10% growth against FY26's realised 14%, and **JPMorgan cut its price target from $605 to $331.** A ~45% PT cut on a beat is a real disagreement about the forward number, which is exactly the variable this week identified as operative | **Investor Day 2026-09-17 (C)**; **Q1 FY27 2026-11-20 (C)** | **E1** on the Investor Day · **E2** on the print | 358.06 / +21.86% · ADV $171.9M |
| 20 | **FSLR** | Bullish — the policy catalyst is now fully specified | **Section 232 takes effect 2026-12-04 at 12:01am ET: a 15% ad valorem tariff PLUS a minimum-import-price regime** — polysilicon $21/kg, ingots/wafers $100/kg, cells $0.22/W, modules $0.38/W. A dated, scheduled policy decision directly favourable to a domestic producer, and materially more specific than the prior cycle's description of it. Flat at −0.41% | **Policy effective 2026-12-04 (C)**; Q3 date not located | **E1 + E2** | 204.46 / −0.41% · ADV $55.1M |

### 21–46 (rest tier)

21 **CRM** (+47.30%, **the largest 30-bar move on the list**; FY27 guide raised to $46.1–46.4B; **catalyst spent 08-26, next ~12-02/03 (E)**; **the D position closed 08-27 so the name is now unencumbered**) · 22 **NOW** (+38.21% on the 08-27 cluster with **no company catalyst of its own**; Q3 10-28 · E1+E2) · 23 **SMCI** (**+55.60%, the strongest move measured**; FQ1 guided $14.5–15.5B vs $11.99B consensus and FY2027 $65–72B vs $54.43B — the gap is extraordinary and the issuer has a record; Q1 FY27 **2026-11-03 (C)**) · 24 **MSFT** (+27.65%; thesis realised at the prior print and the market has now moved a long way toward it; Q1 FY27 10-28) · 25 **AMZN** (+6.58%; rests on the print alone — **the FTC trial is out of window at 2027-03-29, re-confirmed**; Q3 10-29, re:Invent 11-30→12-03) · 26 **PLTR** (+38.15%; direction SUSPENDED since its bearish lean was refuted at print; Q3 11-02) · 27 **VRTX** (+12.73%; Q3 ~11-02/03 **plus povetacicept PDUFA 11-30 (C)** — a non-AI diversifier with two dated catalysts) · 28 **NBIS** (+14.54%; highest-vol name on the queue; the financing objection reads across) · 29 **MRK** (+19.25%; **the densest regulatory calendar of any large cap here — Winrevair 09-21 (2S), Welireg+Lenvima 10-04 (2S), I-DXd 10-10 (C)** — but the 30-bar move has already closed much of the gap) · 30 **TGT** (+16.90%; direction SUSPENDED since comps +6% refuted it; caught in the 08-25 retail-guidance contagion; Q3 11-18) · 31 **IBM** (+10.61%; direction SUSPENDED, documentation row; Q3 ~10-21/22) · 32 **HD** (−0.86%; bearish/neutral, modest support only; Q3 11-18) · 33 **LLY** (+2.42%; retatrutide BLA slipped to Q1 2027 — a filing date, not a trial or safety event; Q3 10-29) · 34 **ADBE** (+24.19%; bearish, cohort evidence oscillating and now partly refuted by the software re-rating; **Q3 FY26 09-10 (2S)** · **E1 only**) · 35 **LMT** (+10.66%; Q3 10-20) · 36 **BA** (+0.16%; Q3 10-28; 777X certification still has no fixed date) · 37 **NTAP** (+16.05%; two first-party dated catalysts — **09-02 (C) SPENT** → **2026-12-01 (C)**, still the only company-confirmed date in this file beyond 2026-11-24) · 38 **CTVA** (**DEMOTED** — its "dated" spin-off is not dated; Corteva says only Q4 2026) · 39 **TSM** (Q3 10-15 — **NOT A-ELIGIBLE, ADR ruling 2026-08-09**; listed so the exclusion stays visible; open D position unaffected) · 40 **ON** (Financial Analyst Day 09-16 (C) · **E1 only**) · 41 **SMMT** (**NEW — ivonescimab PDUFA 2026-11-14 (C), ~$12B**; HARMONi Western-subgroup OS directional but not significant at HR 0.76, so a genuine binary) · 42 **BBIO** (BBP-418 PDUFA 11-27 (C); FDA not planning an AdCom) · 43 **EXEL** (zanzalintinib PDUFA 12-03 (2S)) · 44 **COGT** (bezuclastinib PDUFA 12-30, carried unconfirmed) · 45 **IONS** (zilganersen PDUFA **09-22 (C)** · **E1 only**) · 46 **RARE** (UX111 PDUFA **09-19 (C)** · **E1 only**; **~$2.5–2.6B, borderline on the cap floor**).

**STRUCK FROM THE SHORTLIST THIS CYCLE, with the reason so it is auditable:**
- **GRAL** (was #35) — **fails the 30-day ADV ≥ $10M rail at a measured $6.8M/day.** Mechanical, not a narrative judgment.
- **JAZZ** (was #43), **GILD** (was #44), **BIIB** (was #45) — all three ranked on PDUFA catalysts that have now **resolved as approvals** (08-25, 08-27, and — six weeks before this file ranked it — 07-13). GILD retains a dated catalyst at anito-cel 12-23 and could return on that; the other two carry no in-window dated event.

**The SPENT cluster, recorded once rather than ranked into the tail.** Live narratives, `Watchlist.md` rows retained, but every catalyst falls before ~2026-09-05 with no second in-window date near enough to matter: **CRWD** (08-26; +20.50% at print) · **OKTA** (08-26; +28.63%) · **WDAY** (08-27) · **DG** / **DLTR** (08-27) · **ZM** (08-25) · **DELL** (09-01) · **PANW** (09-01) · **AVGO** (09-02, financing objection open) · **SNOW** (09-02) · **HPE** (09-02) · **LULU** / **DOCU** (09-03). **AAPL** is properly SPENT→NEXT: its CEO transition (09-01, now first-party confirmed) and keynote (09-09) are both E1-only, but its **Q4 print on 2026-10-29 is E1+E2**, so it belongs in the 21–46 band on that basis and is placed here only because its *structural* catalysts — the ones the row actually rests on — are the near ones. AAPL measured **319.70 / −2.11% · ADV $2,086.7M**.

### The standing objection class produced a new instance this week

The prior cycle recorded one week's absence of a new "AI-financing" instance and explicitly declined to read that as resolution. **The class produced a fresh instance on 2026-08-27/28.** **IREN** disclosed, alongside FY2026 results, a **$2.4B GPU-equipment financing led by Blue Owl Capital** — a $1.2B senior secured term loan plus $1.2B of senior secured notes **at a 9.0% fixed rate** — funding Blackwell Ultra purchases, alongside a separate **$3.6B investment-grade facility tied to its Microsoft contract at a 6.0% weighted average**, and **FY2027 capex guidance of up to $30B**. The stock fell **~13%** on 08-28. **The 300bp spread between the two facilities inside one issuer is the informative part**: the market is pricing contracted, investment-grade AI capex very differently from uncontracted GPU collateral, within the same balance sheet on the same day.

IREN is not itself an A candidate on this list. It matters because it is a fifth dated instance in the sequence — **NVDA (circular financing, 07-27) · DDOG (customer concentration, 08-06) · AVGO (~$370B debt-vehicle note, 08-14) · CRWV (structural) · IREN (08-28)** — and the standing instruction on those rows is unchanged: **a thesis must answer the financing objection on its own terms, and "the drawdown improved the entry price" answers a different question.**


---

## PART 2B — Strategy C preliminary ranked shortlist (15 event candidates)

W4 reads this section verbatim.

**CRITICAL ROUTER GATE: C = HYBRID ACTIVATE (FOMC-only)**, resolved 2026-08-05, unchanged and not pending. **Only candidate #1 is router-eligible.** Candidates #2–15 are router-PARKED and carried as divergence context only — **W4 must NOT enqueue thesis-construction on a parked row.** Widening C's scope is reserved to a separate scope-widening adjudication whose conditions are nowhere near met.

> ### ⚠️ THE FOMC THESIS IS ALREADY ENQUEUED. W4 MUST NOT ENQUEUE IT AGAIN.
>
> `state.open_queue` carries **`thesis-FOMC-C-20260908`** — `PENDING_ANALYSIS`, `item_type=thesis-construction`, `strategy=C`, **`due_date=2026-09-08`**, `artifact_path=Weekly_Catalyst_Calendar.md`, status `pending`. **D2 will drain it on 2026-09-08.** Its `conservative_default`: *decline — no entry if unresolved by 2026-09-15 (entry required at least one trading day before the 09-16 decision), or if no affirmative, sourced, quantified divergence from market pricing can be established.*
>
> That default was **corrected on 2026-08-17 by W4** to strip a decline-trigger referencing the retired ≤10% per-name CaR envelope. **Do not re-add a sizing ceiling.** What binds is the recorded seven-factor size justification, the mandatory adversarial attack on size, and C's own defined-risk rail (`total_max_loss = max(closed_form, cascade)` ≤ the thesis's stated risk budget).
>
> **This section's job is to update the inputs the 09-08 session will use. It does not construct a thesis and takes no directional view.**

### Candidate 1 — FOMC 2026-09-16 (the only router-eligible row)

**Event, re-verified first-party this run:** FOMC meets **September 15–16**, decision **Wednesday 2026-09-16**, **with a Summary of Economic Projections** (asterisked on the Fed's own calendar page). The next meeting (10-27/28) carries no SEP and falls outside the window.

#### THE PRIOR CYCLE'S REMAINING TWO OPEN MEASUREMENTS ARE NOW BOTH TAKEN

The 2026-08-23 file closed one third of counter (c) and left two parts explicitly open, naming them as the 09-08 session's first task:

> *"**No IV percentile was obtained for the 2026-09-18 series.** … The dated expiry has not been shown cheap against its own history. **No ATM-straddle expected-move figure was obtained**, so the implied move is not yet expressible in points."*

**Both were obtained this run, from the IBKR connector, on the 2026-09-18 series — the first expiration strictly after the decision.** Series confirmed live (`756733@SMART/OPT/SMART/20260918/SPY/1`, `regular:true`). Spot **769.35** (2026-08-28 regular-session close), ATM strike **769**, call `891842941`, put `891847810`, both `is_valid:true`.

| Measurement | Value | Status |
|---|---|---|
| **ATM implied volatility, 2026-09-18 series** | **10.86%** | measured; see the caveat below |
| 30-bar realised volatility, computed (30 close-to-close log returns, 07-17→08-28, ×√252) | **11.88%** | measured |
| 30-bar realised volatility, IBKR's own `historical_vol` field | **10.79%** | measured |
| **IV / HV ratio** | **0.914** on the computed HV · **1.006** on IBKR's HV | **estimator-sensitive — see below** |
| **ATM straddle expected move** | call mid **$8.805** + put mid **$8.140** = **$16.945** = **±2.20% of spot** through 2026-09-18 | **NEWLY OBTAINED — open for three cycles** |
| **IV percentile** (`implied_volatility_percentile`: `high_13w` 0.0 · `high_26w` 0.0 · `high_52w` 0.0199) | **0th percentile of the 13-week and 26-week ranges; ~2nd percentile of the 52-week range** | **NEWLY OBTAINED — open for three cycles** |
| VIX, 2026-08-28 close | **14.43**, down **23.1%** over 30 bars (from 18.77 on 07-17); *15-minute-delayed feed, flagged* | measured |

**So the dated expiry IS now shown cheap against its own history, which is the claim the prior cycle explicitly could not make.** 0th percentile of its 13- and 26-week ranges is not "somewhat low"; it is the floor of the observable range on this feed.

#### THE MEASUREMENT THAT SHOULD DRIVE THE 09-08 SESSION: THE DATED EXPIRY GOT *CHEAPER* IN THE WEEK HIKE ODDS NEARLY DOUBLED

The prior cycle measured **this same 2026-09-18 series** at **IV 12.1%** on 2026-08-21. **It now reads 10.86%** — a decline of roughly a tenth in relative terms, one week closer to the event.

**Across the same week, September hike odds moved from ~30% to the high-40s/mid-50s, the 2-year yield jumped more than 12bp, and the Fed Chair told Jackson Hole the central bank has "work to do."** The rates market re-priced a materially more contested September; the equity-index option surface for the expiry that contains that meeting got *less* expensive.

**That is the divergence in its sharpest form yet in this file's record**, and it is the opposite sign from the setup the 2026-07-27 drain correctly declined, which measured July's FOMC implied vol at ~25–30% **over** realised.

#### WHAT THIS DOES NOT ESTABLISH — three caveats, none of them cosmetic

1. **"Implied below realised" is NOT robust to the volatility estimator, and the prior cycle's 0.97 was quoted without this sensitivity.** The computed 30-bar HV (11.88%) gives a ratio of **0.914**; IBKR's own `historical_vol` (10.79%) gives **1.006**. **The two bracket 1.0.** The honest statement is that implied is *at or slightly below* trailing realised, not that it is definitively below it. What is *not* estimator-sensitive is the percentile reading, which is a comparison of the same IV series against its own history and is unambiguous at the floor.
2. **The ATM call and put implied vols came back identical to sixteen significant figures** (0.1086400601844652 on both). Two independently solved option IVs do not match to machine precision. The feed is almost certainly returning a single fitted surface value rather than two independent solves, so **"averaged across the ATM call and put" describes one measurement, not two.** Both legs read `is_valid:true` and the figure is reported as measured, but it carries less redundancy than the phrasing implies.
3. **Counter (d) still stands untouched, and this week made half of it stronger.** Cheap vol has an innocent explanation a thesis must defeat rather than ignore: realised vol has itself been low, breadth is healthy at 69.58%, and **VIX has fallen 23.1% over 30 bars to 14.43, flipping the regime signal to `LOW` for the first time in the sequence.** Vol at a floor in a calm tape is ordinary, not anomalous. **The ±2.20% straddle is the number that makes this concrete and arguable**: a thesis now has to say why a 21-day move through an SEP-carrying FOMC should exceed ±2.20%, in points, against a dot plot — which is exactly the form of argument the prior four drains lacked and is the reason obtaining this figure mattered.

#### THE DIRECTIONAL LEG MOVED THE OTHER WAY, AND THE 09-08 SESSION MUST NOT INHERIT LAST CYCLE'S FRAMING

**This is the most important thing in this section.** The prior cycle's directional case was that *"hike pricing collapsed ~56–62% → ~29–32% over two weeks while the hawkish counter-evidence went unretracted"* — the market drifting **away** from a hawkish read the documents still supported.

**That gap has now largely closed, and it closed from the market's side in a single session.** Odds went ~30% → high-40s/mid-50s on 2026-08-28. Hammack and Kashkari both restated the hike case on the record in the same window. **The divergence a directional thesis would have to document is materially smaller than it was two weeks ago.**

**So the two legs have moved in opposite directions this week, and the 09-08 session must hold both:**

| Leg | Prior cycle | This cycle | Direction of change |
|---|---|---|---|
| **Directional** — market pricing vs what the documents support | Hike odds collapsing while dissents stood unretracted | Odds re-priced toward the hawkish read; Chair explicitly hawkish; two dissenters on the record | **AGAINST** the thesis — the gap narrowed |
| **Premium** — is the dated optionality cheap | Ratio 0.97, no percentile, no expected move | Ratio 0.914–1.006, **0th/0th/~2nd percentile**, **±2.20% straddle**, and IV *fell* into a more contested meeting | **FOR** the thesis — and now fully specified |

**A thesis that leans on "the market is under-pricing a hike" is weaker than it was on 2026-08-23. A thesis that leans on "the dated optionality is at the floor of its own range into a two-sided, SEP-carrying decision" is stronger, and is now measurable in points.** Those are different trades with different structures. **This file takes no view on which, if either, clears Entry criterion 2 — that is the 09-08 session's work, and it is now equipped to do it with numbers rather than adjectives.**

#### The counter the calendar has retired, and the one it has created

**RETIRED — counter (b), Jackson Hole.** The prior cycle noted the symposium fell inside the pre-event window and that "no structure can be entered blind to it." **It is over.** The 09-08 drain constructs its thesis with the content in hand, and that content is set out verbatim in 1B.1. Counter (b) is not refuted; it is spent.

**STILL LIVE, and the prior cycle raised it correctly — the CPI decision.** The queue's `due_date` is the earliest date the analysis *can* run, not a requirement to enter that day, and C permits entry up to one trading day before 09-16:

| Date | Event | Bearing on a structure entered at the due date |
|---|---|---|
| 2026-09-08 | Queue `due_date` — earliest the analysis can run | — |
| 2026-09-10 | PPI, August | One day after the earliest entry |
| **2026-09-11** | **CPI, August** | **The largest scheduled input to the decision, and it falls INSIDE the holding period of anything entered on 09-08** |
| 2026-09-15 | Last permissible entry day | — |
| **2026-09-16** | **FOMC decision + SEP** | The event |

**Entering before the 09-11 CPI print is a materially different trade from entering after it, and the difference is not a sizing question.** With a ±2.20% straddle now measured, that choice can finally be priced rather than argued.

**NEW this cycle, and worth a line:** a **US government funding deadline falls on 2026-09-30**, with a continuing resolution to 2026-12-11 in progress. It is outside any structure's life if entered for the 09-16 decision, but it bears on whether the October data the *next* meeting depends on publishes on schedule.

#### The record this candidate is measured against

All four prior FOMC drains resolved **NO-GO** — 2026-04-27, 06-08, 06-15, 07-27 — **every one on an inability to document divergence, not on sizing.** Per the shared **"NO-GO records are context, not barriers"** rule, that record informs this evaluation and does not pre-empt it. What is genuinely new relative to all four is that the premium leg is, for the first time, quantified on the correct instrument, against its own history, and in points.

**Disposition: no new enqueue is needed or permitted — the work is already scheduled for 2026-09-08.** This section hands that session four things it did not have: the IV percentile, the straddle expected move, the week-over-week direction of the dated IV, and the fact that the directional leg has weakened while the premium leg has strengthened.

### Candidates 2–15 — router-PARKED, divergence context only

Ranked by measured event premium. **Read the caveats before ranking on these numbers.**

**TENOR IS NOT COMPARABLE ACROSS ROWS AND THE RATIOS MUST NOT BE RANKED NAIVELY.** Each expiration is the first strictly after that name's own event, so tenor runs from 4 days (the 09-04 weeklies) to 21 days (NTAP's forced 09-18 monthly). A near-dated expiry spanning an imminent print concentrates event vol; a distant one dilutes it across ordinary time. **Two rows are additionally compromised and are flagged in place rather than silently ranked.**

| # | Event (ticker) | Type | Date | Expiry used | Close 08-28 | ATM IV / 30-bar HV | Ratio | Note |
|---|---|---|---|---|---|---|---|---|
| **2** | **SNOW** earnings | Earnings | 2026-09-02 **(C)** | 09-04 | 328.00 | 111.69 / 37.15 | **3.01** | **The richest measured premium in this file's record**, and richer than last cycle's 2.62 on the same name. +21.98% over 30 bars |
| 3 | **LULU** earnings | Earnings | 2026-09-03 **(C)** | 09-04 | 120.81 | 86.43 / 39.57 | **2.18** | New to this ranking |
| 4 | **HPE** earnings | Earnings | 2026-09-02 **(2S)** | 09-04 | 52.31 | 102.03 / 52.07 | 1.96 | Prior quarter +29–37% after hours |
| 5 | **NTAP** earnings | Earnings | 2026-09-02 **(C)** | **09-18** | 187.02 | 63.82 / 35.52 | 1.80 | **TENOR-COMPROMISED: NTAP lists no weekly, so the nearest expiry strictly after the event is 16 days late.** The ratio understates event concentration |
| 6 | **AVGO** earnings | Earnings | 2026-09-02 **(C)** | 09-04 | 368.79 | 73.53 / 41.98 | 1.75 | Financing objection open |
| 7 | **DOCU** earnings | Earnings | 2026-09-03 **(C)** | 09-04 | 64.00 | 98.45 / 64.18 | 1.53 | +21.35% over 30 bars |
| 8 | **PANW** earnings | Earnings | 2026-09-01 **(2S)** | 09-04 | 371.59 | 83.34 / 56.79 | 1.47 | Rose 12.83% on 08-27 with **no confirmed company catalyst** — D1 recorded it as possible cluster halo |
| 9 | **NKE** earnings | Earnings | **2026-10-01 (C)** | 10-02 | 39.60 | 44.32 / 31.69 | 1.40 | Date **newly resolved**; the expiry used does span it |
| 10 | **KR** earnings | Earnings | 2026-09-11 **(C)** | 09-18 | 57.72 | 35.01 / 25.16 | 1.39 | 7-day tenor overhang |
| 11 | **ORCL** earnings | Earnings | **~09-08 (!)** | 09-11 | 150.85 | 78.60 / 57.03 | 1.38 | **DATE-COMPROMISED: if Oracle in fact reports 09-14, the 09-11 expiry used here EXPIRES BEFORE the event and this is not an event-vol reading at all.** Fourth cycle unresolved |
| 12 | **DELL** earnings | Earnings | 2026-09-01 **(C)** | 09-04 | 456.24 | 101.96 / 77.78 | 1.31 | +15.11% over 30 bars |
| 13 | **COST** earnings | Earnings | 2026-09-24 **(C)** | 09-25 | 945.47 | 23.78 / 18.81 | 1.26 | Lowest absolute vol on the list |
| 14 | **ADBE** earnings | Earnings | 2026-09-10 **(2S)** | 09-11 | 291.52 | 58.82 / 52.25 | 1.13 | |
| 15 | ~~**MU** earnings~~ | Earnings | **2026-09-30 (C)** | ~~09-25~~ | 932.86 | 52.70 / 93.02 | ~~0.57~~ | **MEASUREMENT VOIDED — see below** |

> **THE MU ROW IS VOIDED, AND CATCHING IT IS THE POINT.** The measurement pass was dispatched with MU's event date still unresolved at "~09-22" and selected the **2026-09-25** expiry as the first one strictly after it. **In parallel, Micron's own release resolved the date to 2026-09-30.** The 09-25 series therefore **expires five days BEFORE the event**, and its striking 0.57 ratio is not a cheap-event-premium reading — it is an ordinary event-EXCLUDING expiry measured against a trailing realised window that contains a very large already-realised move (MU traded from ~990 down to ~739 and back above 1,000 inside the 30-bar window). **An expiry that excludes the event should read cheap against that. Nothing here says MU's actual event premium is low.**
>
> Last cycle ranked MU **#16 on this list with a 0.68 ratio** and called it "the only in-window earnings event measured with implied BELOW realised." **That reading rested on the same defect** — a 09-25 expiry chosen against a then-assumed 09-22/09-23/09-29 date set. **A correct MU event-vol reading requires the 2026-10-02 expiry or later and has not been taken.** MU is retained on the list with its measurement struck rather than quietly re-ranked.

**PDUFA candidates, carried without volatility measurement this run** (the measurement pass was scoped to index and the near-dated equity earnings set): **TLX 09-11 (C)** · **RARE 09-19 (C)** · **MRK Winrevair 09-21 (2S)** · **IONS 09-22 (C)** · **GRAL panel 09-23 (C)** · **INCY/MIRM 09-26 (C)** · **PTGX/TAK ~09-30 (2S)** · **ROIV ~09-30 (2S)** · **SRRK 09-30 (C)** · **BMY 09-30 (C)** · **MRK/Eisai 10-04 (2S)** · **MRK/Daiichi I-DXd 10-10 (C)**. Two cycles ago RARE measured at IV/HV **2.14** on a ~$2.6B sponsor with ~$0.06B ADV. **That figure is now two weeks stale and must not be carried forward** — the prior cycle's own AVGO observation (ratio 1.37 at the 68th/76th/88th IV percentiles collapsing to 0.87 at the 0th/3rd/19th in a single week) is the standing reason no volatility figure in this system survives a cycle unrefreshed.

### One methodological note on the ADV figures in this section

The Task-2 ADV figures above are computed as **mean(close) × mean(volume)**, an approximation, whereas PART 2A's 39-name sweep uses the exact **mean of (close × volume)** per bar. The two agree closely for stable names and diverge where price moved a lot inside the window. **The PART 2A figures are the ones to use for the $10M liquidity rail**; these are indicative only. The raw-shares volume convention was re-confirmed independently on SPY this run: the proper sum-of-products gives **$21.07B/day**, while a lots-of-100 reading would give **$2.107 trillion/day**, which would exceed total US equity turnover on its own.

---

## OUT-OF-SCOPE FINDING — RECORDED, NOT REPAIRED

**The trading-enable gate reads the non-cadence-aware freshness pair, so `state.trading_enabled` is FALSE by construction for roughly 51 hours every weekend.**

**Measured this run:** `state.trading_enabled` = **FALSE**, `halt_reason` = *"state.freshness marks_fresh/engine_fresh not both TRUE"*, while `state.freshness` on the same row reads **`marks_fresh` FALSE but `marks_current` TRUE**.

**Derived from the view's own SQL, read this run — not inferred from an absence.** `state.freshness` computes two pairs against two different reference dates. `marks_current` / `engine_current` compare against `marks_due_through`, which the view defines as *the last trading day a scheduled D2a slot has already had the opportunity to ingest* — an array that excludes Friday and Saturday (`DAYOFWEEK NOT IN (6,7)`) and requires the 22:40 UTC slot to have elapsed. `marks_fresh` / `engine_fresh` compare against `last_trading_day` instead. **From Friday's close until Sunday ~22:40 UTC, `marks_due_through` is stuck at Thursday while `last_trading_day` is Friday, so `marks_fresh` is FALSE by construction.** Corroborated independently: `events.daily_marks` **does** hold Friday rows (2026-08-07 n=13, 08-14 n=13, 08-21 n=12) — Friday is ingested, just by the following Sunday-evening D2a.

**The view's own comment says this was a deliberately scoped fix, which is why this is a finding rather than a bug report.** The cadence-aware pair was added 2026-08-15 and the comment states *"these are what the daily_freshness_check dead-man now reads,"* while `marks_fresh`/`engine_fresh` are *"retained unchanged because the trading gates in `bigquery/107` read them — do not 'simplify' the two pairs into one."* **The dead-man's-switch half was repaired; the capital-gate half deliberately was not.**

**Measured cost — real but bounded.** No trade is ever blocked, because the market is closed for the entire stretch. What happens instead is that a routine reading the gate inside that window raises a **human-latching `trading_halted` critical** for a non-event. Four measured instances: **D2a Sat 2026-07-11 · W4 Sun 2026-07-19 · W4 Sun 2026-07-26 · D2a Sat 2026-07-25** (all since resolved by a human).

**Not repaired here, deliberately.** Editing a live capital gate has fleet-wide blast radius, and this is the same file and the same shape as the existing **"DELIBERATELY NOT FIXED HERE"** note in `Claude_Task_Plan.md` about `bigquery/107`'s embedding term. W1 stages no orders and nothing in this run depended on the gate. **Recorded as an `ops.alerts` `info` row, category `weekend_freshness_gate_asymmetry`, naming `bigquery/107` and the `state.freshness` view as the owning surfaces and W5 self-improvement as the nearest owning routine** — a *verified* consumer, since W5's SPEC-DEFECT NOTICE INTAKE step reads exactly `severity = 'info' AND NOT resolved`.

---

## Method and coverage notes

**Sub-agent fan-out:** eight Sonnet 5 sub-agents — C-window earnings dates, A-window tail earnings, FDA/PDUFA, FOMC/macro, past-week tape and results, non-earnings catalysts, IBKR index/event volatility, IBKR A-shortlist market data. **Ranking, adjudication, corrections and design were done in-session.** Per the shared **"one shared pull, not N independent ones"** rule, the FMP earnings calendar was pulled **once by the orchestrator before fan-out** (five probes) and passed into the two earnings agents as literal text with an explicit instruction not to re-fetch it; **no sub-agent called FMP at all.**

**Sources reached this run:** company IR pages and press releases (the primary source for every `(C)` earnings and PDUFA row), SEC EDGAR filings, `federalreserve.gov` (both the FOMC calendar and the full Warsh speech text), `bls.gov`, `bea.gov`, `federalregister.gov`, `apple.com/newsroom`, `whitehouse.gov`, `stb.gov`, the IBKR connector (every price, volume and option measurement), Polymarket's live event page, and web/Tavily search.

**Sources that failed, recorded so a later cycle does not re-attempt them blind:** `cnbc.com` and `bloomberg.com` **403** on direct fetch (both were reachable only via search snippets, which is why the CME FedWatch figure is one source removed) · `rockstargames.com` returned a **cookie wall** to both WebFetch and a Tavily extract · `drugs.com` **403** (the one page that might have settled the denecimig date) · `investor.roivant.com` **503** · `hcplive.com` and `appliedclinicaltrialsonline.com` **403** · `thecardiologyadvisor.com` **402 paywall** · `bls.gov/schedule/news_release/2026_sched.htm` **404** (the per-release pages worked) · `federalregister.gov` direct fetch redirected through an interstitial WebFetch would not follow · **`investor.oracle.com`'s "Sets the Date" URL 404s because the release does not exist yet** — that is an absence, not a fetch failure. **`fda.gov`'s live AdCom calendar was deliberately not re-attempted** (documented 401/JS-shell); the Federal Register was used instead and is what confirmed the GRAIL panel.

**Measurement provenance.** All price, 30-bar change, ADV, IV, HV and option figures are live IBKR reads taken this run against the **2026-08-28** regular-session close, `step=ONE_DAY`, `outside_rth=false`. **No close anywhere in this file came from `get_price_snapshot`.** Both measurement agents were run under an explicit anti-transcription protocol after two prior cycles published mis-attributed figures: batches of at most four symbols, symbol kept attached to every intermediate value, then individual re-fetches. **The A-side sweep re-checked 8 of 39 rows across all four groups; all 8 matched exactly. The index/event sweep re-checked 5 rows; all 5 matched.** No symbol failed to resolve and no option contract returned `is_valid:false` in either pass.

**Two measurement caveats are carried in the body rather than buried here** — SPY's ATM call and put implied vols returning identical to sixteen significant figures, and the MU expiry that excludes its own newly-confirmed event date.

**Metered-call telemetry** for this run is written to `ops.web_calls` immediately before run completion. **`credits_reported` is FALSE on every Tavily row** because `include_usage` is not a parameter this MCP server accepts, so all Tavily credit figures are rate-card **estimates**, not provider-reported. **Per-call timestamps are BUCKETED into each sub-agent's real dispatch-to-completion window** — no MCP layer in this environment returns a server-side call time — and that bucketing is stated rather than disguised.

**One free-allowance limit was hit, and it shaped the run.** The session's Anthropic `web_search` budget (a session-wide cap shared across all eight sub-agents, not a per-agent one) was **exhausted partway through**, after which the remaining work escalated to Tavily per the ordering rule. Two named consequences: the non-earnings sweep did **not** re-verify seven recurring conference rows, which are consequently downgraded from `(C)` to `(E)` in 1A.4 rather than carried; and the tape sweep did not pin exact index levels for the 2026-08-25 session or an RSP close for 08-28. Both are stated where they occur.

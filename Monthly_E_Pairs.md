2026-09

# E Pair Divergence Screen — September 2026

**Run 2026-09-01 (M2, deep research). Every correlation, beta, volatility and spread below was re-measured this session from IBKR daily closes — nothing is carried over from the August edition.** The catch-up evidence window resolved to 28.95 days (`state.routine_catchup_window`, back to M2's own last completed run at 2026-08-03) — cadence-normal for a monthly routine, single-period, so no missed-period sub-sections are owed and no `CATCHUP` token is due.

## The gate that blocked this shortlist in August has been REMOVED

The August edition closed by saying that "what blocks entry is no longer execution — it is E's fundamental DO-NOT-ACTIVATE call (divergence review pending), `state.trading_enabled = FALSE`, and the open Tier-1 defect on E's pre-mortem." **Two of those three have since changed, and the August text is now stale on the first one.**

- **Strategy E's binding activation state is `ACTIVATE`**, set 2026-08-05 by divergence review `div-E-202607-1` — **two days after the August screen was written**, which is why that edition could not see it. The orchestrator lifted the standing `execution-feasibility-deferred` qualifier **in full**, and it did so partly on evidence this very screen produced: M2's August measurement that 60-day correlation exceeded 252-day in 66 of 89 pairs empirically refuted M1b's stationarity ground. Measured this session from `events.regime_events` (scope `STRATEGY_ACTIVATION`, key `E`); no later row supersedes it.
- **E's technical gate also reads ACTIVATE on today's inputs**: SPY Trend `UP` (767.05 > 50d 754.36 > 200d 710.27), VIX Regime `LOW` (14.92), Equity Breadth `HEALTHY` (66.2). E's technical rule requires SPY ≠ DOWN **and** VIX ≠ HIGH **and** Breadth = HEALTHY; all three hold.
- **The pre-mortem Tier-1 defect is still open, and it has moved on since the August edition's description of it.** `state.open_queue` still carries `premortem-E-2026-a3` as `PENDING_REVIEW`, due today. But it is now at **cycle 13** (attacker verdict `TIER 1 DEFECT — REVISION REQUIRED`, theater-check `MIXED`, dated 2026-08-31), with **no orchestrator ruling yet**. Both the August edition and the `state.current_regime` rationale text still describe it as "cycle 6" — that is stale by seven cycles. The live cycle-13 Tier-1 item is narrow and methodological: a `grep` sweep the rev-15 artifact claims is "mechanically reproducible" does not in fact reproduce the artifact's own enumeration, so a method-level discharge claim is false as literally stated.

**Consequence for this screen.** E is activated and executable; the residual blockers are the open pre-mortem defect and the trading-enable gate, neither of which M2 can clear and neither of which is a reason to weaken the screen. **This PART 2 is still research feedstock for M4, not a queue to drain into orders** — but for a different and weaker reason than in August.

> **AMENDMENT, same day, after M1b completed.** M2 read the activation state before M1b's September run landed; M1b then completed at 2026-09-01 and its September call materially changes the *framing* above without changing the binding state. Recorded here rather than left for M4 to reconcile:
>
> - **The binding state is still `ACTIVATE`** — M1b wrote **no** new `STRATEGY_ACTIVATION`/`E` row, so the 2026-08-05 row remains the latest and everything above stands as measured. Re-verified after M1b's commit.
> - **But M1b's September post-reconciliation call for E is DO-NOT-ACTIVATE**, and it is **override-manufactured for the first time**: M1b's *raw* fundamental call **flipped to ACTIVATE** — a genuine flip, and one it credits substantially to *this screen's own August measurement* (60d correlation exceeding 252d in 66 of 89 pairs, 74%) — and then the universal rule `shock_overlay = acute → override ACTIVATE → DO-NOT-ACTIVATE for ANY strategy` fired. **This is the first time that rule has ever fired on E.**
> - **So only the mechanical shock override now stands between E and activation.** M1b's own raw grounds no longer argue against E; they agree with `div-E-202607-1`. M1b flags the raw-to-override inversion as materially new information for the incoming divergence review, and notes the net call is unchanged so there is no router flip for M4 to action.
> - **This does not weaken any disposition in this screen** — no pair was advanced or dropped on activation state, and the technical gate reads ACTIVATE on all three legs either way. It does mean **M4 should read PART 2 as feedstock for a live divergence review on E**, not as a shortlist blocked by a settled fundamental DNA.

**`state.trading_enabled` reads FALSE as of this run**, on `halt_reason = 'state.freshness marks_fresh/engine_fresh not both TRUE'`. This is the ordinary pre-close state on a trading day, not an incident: `state.freshness` shows `marks_current = TRUE` and `engine_current = TRUE` with marks through 2026-08-31 and `marks_due_through` 2026-08-31 — the flag is FALSE only because `last_trading_day` has already rolled to today and today's D2a has not yet run. Stated as fact; M2 stages no orders and is not gated by it.

## Cross-strategy conflicts and the E book

**Strategy E's own book is empty** — `state.current_positions` holds 12 open positions and **every one is Strategy D** (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER). `events.shadow_positions` holds no E legs either. So the rule "exclude pairs where either leg is in the open E book" excludes nothing this month.

The open D book still creates one genuine conflict:

- **GEV is open long in the D book** (`D:GEV:2026-08-03`). This continues to kill **VRT/GEV** (measured 0.6252 this cycle) — an E short of GEV against a D long of GEV largely nets out at book level. Recorded, not advanced, same as August.
- **MTZ is no longer in the B book.** August dropped MTZ/PWR partly because MTZ had just been staged long in B; that position is not in the current book. The drop nevertheless **stands on its independent merits** (see PART 1E) — the cross-strategy reason has lapsed, the earned-divergence reason has not, and it has since gotten worse, not better.

## Structurally invalid pairs — permanent exclusion list

Four pairs are not data failures but structurally dead and must never be re-probed. **EA/TTWO is new to this list this cycle.**

| Pair | Reason |
|---|---|
| **SYF/DFS** | DFS delisted by the Capital One / Discover merger; no live IBKR listing (only a frozen `VALUE`-exchange reference entry) |
| **SPR/HWM** | SPR delisted by Boeing's acquisition of Spirit AeroSystems |
| **JNPR/ANET** | JNPR delisted by HPE's acquisition of Juniper Networks |
| **EA/TTWO** | **NEW — Electronic Arts was taken private and deregistered in August 2026.** Confirmed independently on two sides: (i) SEC EDGAR shows EA filed a **Form 15-12G on 2026-08-14** (termination of registration), preceded by a SCHEDULE 13D/A on 2026-08-05 and a burst of insider Form 4s on 2026-08-04 — the signature of a going-private close; (ii) IBKR `search_contracts` returns exactly one exact-symbol EA row, conid 268995 on exchange `VALUE` with no `country_code`, and `get_price_history` on it errors "Details currently unavailable" — the identical frozen-placeholder signature that SYF/DFS shows. EA/TTWO was already out of population on correlation (0.204 in August), so this changes no disposition; it is recorded because "structurally dead, never re-probe" is a more useful permanent record than "below the rail this month." |

Ticker/entity notes carried forward and re-verified: **BK lists as BNY**; **PARA's successor is PSKY** (Paramount Skydance) — and contrary to the August note that PSKY's short IBKR history is a "benign 3-day merger offset," PSKY returned a **full 251-bar series** this cycle, so no truncation applies to the 2025-09-02 → 2026-08-31 window at all.

---

# PART 1 — measured population

All figures measured this session from **IBKR daily closes, 251 bars per ticker, window 2025-09-02 → 2026-08-31** (250 aligned daily log-return observations per pair). Pearson correlation on log returns; beta = OLS slope of A on B; vol annualised ×√252. **"1M" = 2026-08-03 → 2026-08-31** (deliberately anchored to the August screen's own run date, so the 1M column reads as "what happened since the last screen"). **"3M" = 2026-06-01 → 2026-08-31.** Spread = A minus B in percentage points. Prices are full-precision closes as returned.

**Layer-1 population rail (mechanical, a cost bound):** same 6-digit GICS industry, 252-day correlation ≥ 0.30, large-cap with adequate ADV, both legs reported earnings or filed a 10-Q/10-K within 90 days (i.e. on or after **2026-06-03**).
**Spec floor (mechanical, derived from Strategy E's spec_hash-frozen Entry criterion 3):** 252-day correlation ≥ 0.50 to be eligible to advance. This number derives from the frozen spec, not from a screen tune, and is not negotiated at the third decimal.

**Population this cycle: 81 pairs** — 61 above the spec floor and eligible, 20 in the 0.30–0.49 context band. A further 6 fall below the 0.30 rail (out of population), 2 are measured but withheld, and 1 (EA/TTWO) is structurally dead. 90 pairs defined, 89 measurable.

## The 90-day recency gate was resolved against SEC EDGAR, not aggregators — and it changed three dispositions

**Method change this cycle, and it is the single biggest quality improvement in the run.** The August screen resolved earnings/filing recency name-by-name through FMP and web search. That path failed again this cycle exactly as it did last: FMP served 5 of 7 date-range sweeps as ACCESS DENIED, the 2 that succeeded returned implausibly few rows (6 and 2 — partial results, not empty ones), and `earnings-company` was denied on every attempt; a fallback path then hit its Tavily budget with **99 of 122 tickers still unresolved**. That is not a usable gate.

The gate was therefore re-run against **SEC EDGAR's own submissions API** (`data.sec.gov/submissions/CIK##########.json`, joined to `sec.gov/files/company_tickers.json`), taking for each ticker the later of (a) its most recent 10-Q/10-K filing date and (b) its most recent 8-K carrying **Item 2.02 (Results of Operations)**. This is the primary source, it is free and unmetered, it needed no credentials, and it resolved **171 of 172 tickers in seconds**. Result: **168 PASS, 2 FAIL, 1 structurally not applicable.**

Three dispositions turn on it:

- **MDB/SNOW — FAILS the gate, out of population despite clearing the correlation floor at 0.6250.** MongoDB's last earnings 8-K is 2026-05-28 and its last 10-Q 2026-05-29; Snowflake's are 2026-05-27 and 2026-05-29. At 94–96 days both legs are outside the window. Both report again in early September — days after this run — which is precisely the situation that made the August screen reject PGR/ALL. Recorded in PART 1D, not advanced.
- **ROST/TJX — PASSES, but only on the earnings limb.** Ross Stores' most recent 10-Q is 2026-06-02 (91 days, would fail), but it filed an Item 2.02 8-K on **2026-08-20**. The gate reads "reported earnings **or** filed 10-Q/10-K," so ROST clears on the first limb. Stating which limb carried it, because the two limbs disagree here.
- **ALL/PGR — back in population.** Allstate failed this gate in August at 96 days; it filed its Q2 10-Q on **2026-08-05** and now clears with room. Measured 0.7032 this cycle.

**PANW clears at exactly zero margin, and the margin is worth naming rather than rounding away.** Palo Alto Networks' most recent 10-Q was filed **2026-06-03** — precisely 90 days before this run date, i.e. on the boundary and inside "within the last 90 days." Its last earnings release (Item 2.02 8-K) was 2026-06-02, which at 91 days would **fail**. So PANW is in the population only because the gate has a filing limb and the 10-Q landed one day after the release. Next cycle this resolves either way on its own — see PART 2 §7, PANW reports tonight.

**One structural non-applicability, stated rather than papered over.** SPOT (Spotify) is a foreign private issuer: it files 20-F/6-K and never files a 10-Q, so the filing limb of this gate is structurally unsatisfiable for it and EDGAR returns no 10-Q/10-K at all. LYV/SPOT is out of population on correlation anyway (0.1429), so nothing turns on it, but a future screen that reaches for a foreign-private-issuer leg needs to handle the earnings limb explicitly rather than treat an EDGAR miss as a failure.

## PART 1A - ABOVE the 0.50 spec floor (61 pairs, eligible to advance)

### Technology

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 453010 Semis | QRVO/SWKS | 0.9643 | 0.9892 | 0.7636 | 36.66% | 46.3% | -1.97 | 7.34 | 96.08 | 67.01 |
| 453010 Semi Equip | LRCX/KLAC | 0.8706 | 0.9033 | 0.918 | 63.55% | 60.27% | 6.33 | 4.63 | 301.49 | 175.45 |
| 451030 Software | PANW/CRWD | 0.82 | 0.897 | 0.6848 | 43.65% | 52.27% | -3.97 | 9.04 | 382.13 | 231.0 |
| 453010 Semis | MCHP/ADI | 0.8049 | 0.8882 | 1.1184 | 49.28% | 35.47% | -2.42 | -9.67 | 73.45 | 362.14 |
| 453010 Semi Equip | TER/AMAT | 0.7545 | 0.854 | 0.9713 | 75.93% | 58.98% | 7.18 | -5.36 | 349.83 | 458.39 |
| 451030 Software | WDAY/NOW | 0.7527 | 0.7441 | 0.7053 | 53.02% | 56.58% | -9.97 | 16.65 | 197.45 | 147.99 |
| 453010 Semis | ON/NXPI | 0.7352 | 0.8194 | 0.9696 | 62.67% | 47.52% | -8.06 | -10.87 | 74.09 | 224.64 |
| 451030 Software | FTNT/CRWD | 0.6967 | 0.802 | 0.5338 | 40.05% | 52.27% | -9.32 | -1.96 | 170.93 | 231.0 |

### Financials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | RF/KEY | 0.8798 | 0.8307 | 0.9004 | 24.05% | 23.5% | 0.18 | 5.89 | 29.88 | 21.61 |
| 401010 Banks | USB/PNC | 0.8665 | 0.8902 | 0.8915 | 22.16% | 21.53% | 1.11 | 4.09 | 61.58 | 239.63 |
| 401010 Banks | TFC/MTB | 0.8416 | 0.7821 | 0.9373 | 24.03% | 21.57% | 1.72 | -4.77 | 49.58 | 233.94 |
| 402030 Capital Markets | STT/BNY | 0.7986 | 0.8498 | 0.9257 | 24.82% | 21.41% | 0.95 | 6.66 | 191.38 | 161.28 |
| 402020 Consumer Finance | COF/AXP | 0.7727 | 0.7536 | 0.9298 | 32.43% | 26.95% | 2.76 | 10.92 | 214.51 | 330.17 |
| 403010 Insurance | TRV/CB | 0.7157 | 0.7313 | 0.7633 | 20.67% | 19.38% | 0.65 | 17.35 | 365.93 | 338.6 |
| 402010 Capital Markets | RJF/LPLA | 0.7058 | 0.7439 | 0.489 | 25.4% | 36.67% | -2.44 | -12.39 | 178.17 | 370.13 |
| 403010 Insurance | ALL/PGR | 0.7032 | 0.7499 | 0.6406 | 25.02% | 27.46% | -5.48 | 11.23 | 257.8 | 218.08 |
| 403010 Insurance | MET/PRU | 0.7011 | 0.7648 | 0.73 | 23.66% | 22.72% | 3.19 | -0.74 | 95.17 | 117.6 |
| 401010 Banks | WFC/C | 0.6921 | 0.6716 | 0.6284 | 26.52% | 29.21% | -0.25 | 9.99 | 86.39 | 131.62 |
| 403010 Insurance | AIG/HIG | 0.546 | 0.749 | 0.6878 | 24.45% | 19.41% | 0.78 | -4.58 | 76.36 | 137.38 |
| 402030 Capital Markets | BEN/TROW | 0.517 | 0.3861 | 0.5744 | 27.8% | 25.03% | -1.13 | 3.29 | 34.15 | 111.28 |

### Energy/Materials/Utilities

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 151010 Chemicals | DOW/LYB | 0.8791 | 0.9243 | 0.8993 | 44.36% | 43.36% | -5.25 | -8.95 | 30.52 | 65.08 |
| 101020 E&P | DVN/EOG | 0.8485 | 0.8922 | 1.0347 | 35.14% | 28.82% | 9.33 | -1.35 | 48.51 | 144.96 |
| 101020 E&P | APA/FANG | 0.787 | 0.8366 | 1.1329 | 46.47% | 32.28% | 16.16 | 13.58 | 43.15 | 200.48 |
| 151030 Packaging | IP/PKG | 0.7338 | 0.8548 | 1.1542 | 43.83% | 27.86% | -1.66 | 7.05 | 37.93 | 233.94 |
| 151010 Chemicals | PPG/SHW | 0.7324 | 0.7681 | 0.8116 | 30.4% | 27.43% | 2.74 | -14.82 | 112.17 | 338.81 |
| 101010 Energy Equip | HAL/SLB | 0.7019 | 0.7295 | 0.7147 | 36.15% | 35.51% | -6.33 | -16.12 | 36.85 | 60.1 |
| 551010 Utilities | EXC/AEP | 0.6911 | 0.8133 | 0.6963 | 19.29% | 19.15% | 0.4 | -1.12 | 43.72 | 122.43 |
| 151010 Chemicals | EMN/CE | 0.6337 | 0.6414 | 0.3956 | 33.21% | 53.19% | -2.98 | 13.69 | 72.44 | 45.48 |
| 101010 Energy Equip | HAL/BKR | 0.6078 | 0.5657 | 0.6701 | 36.15% | 32.79% | 11.05 | -7.27 | 36.85 | 63.55 |
| 151040 Metals | CLF/NUE | 0.5322 | 0.641 | 1.1783 | 69.78% | 31.52% | 7.4 | -14.21 | 11.55 | 249.64 |

### Consumer

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 252010 Homebuilders | KBH/DHI | 0.8565 | 0.8536 | 0.9308 | 38.7% | 35.61% | -3.86 | 5.93 | 53.3 | 144.56 |
| 302020 Food | CAG/GIS | 0.7853 | 0.7966 | 0.8596 | 30.45% | 27.81% | -7.0 | -0.31 | 16.02 | 41.2 |
| 253020 Hotels | H/MAR | 0.7422 | 0.6664 | 0.9194 | 33.79% | 27.28% | -1.22 | 0.26 | 166.97 | 341.76 |
| 252010 Homebuilders | TOL/NVR | 0.7201 | 0.8272 | 0.906 | 34.5% | 27.42% | -6.45 | 0.5 | 143.45 | 6315.23 |
| 255030 Broadline Retail | DLTR/DG | 0.6124 | 0.6435 | 0.6871 | 41.4% | 36.9% | -1.37 | -1.61 | 126.59 | 126.75 |
| 255040 Specialty Retail | ROST/TJX | 0.5829 | 0.6347 | 0.7511 | 26.22% | 20.35% | 5.34 | 14.33 | 228.54 | 133.91 |
| 251020 Automobiles | F/GM | 0.5707 | 0.6496 | 0.6386 | 37.52% | 33.53% | -1.84 | -20.58 | 13.94 | 86.32 |
| 303010 Household Prod | CLX/CHD | 0.5559 | 0.6592 | 0.744 | 31.16% | 23.28% | -0.36 | 4.94 | 97.68 | 99.78 |
| 303010 Household Prod | KMB/PG | 0.5295 | 0.6803 | 0.7511 | 27.73% | 19.55% | 0.26 | 6.76 | 107.95 | 145.12 |

### Industrials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 202020 Prof Services | EFX/TRU | 0.8462 | 0.8729 | 0.8006 | 39.08% | 41.3% | 2.48 | -6.54 | 189.16 | 84.91 |
| 203020 Airlines | AAL/DAL | 0.8167 | 0.8592 | 0.9992 | 47.47% | 38.8% | -1.43 | -2.09 | 13.43 | 78.0 |
| 203040 Ground Transport | XPO/ODFL | 0.7458 | 0.809 | 0.8528 | 42.8% | 37.43% | 3.93 | 0.2 | 193.99 | 199.96 |
| 201030 Constr & Eng | MTZ/PWR | 0.7443 | 0.6747 | 0.8973 | 52.37% | 43.44% | 2.54 | -22.09 | 239.78 | 607.09 |
| 201010 Aero & Defense | NOC/LMT | 0.7036 | 0.73 | 0.6855 | 27.21% | 27.93% | 2.68 | -8.57 | 539.7 | 561.23 |
| 201040 Electrical Equip | VRT/NVT | 0.7015 | 0.8332 | 1.0096 | 64.98% | 45.15% | 3.79 | -7.87 | 258.72 | 150.75 |
| 201060 Machinery | DOV/IR | 0.6457 | 0.5343 | 0.5177 | 26.16% | 32.62% | 6.64 | -15.0 | 194.23 | 77.05 |
| 201060 Machinery | SWK/ITW | 0.6376 | 0.5677 | 1.1265 | 37.67% | 21.32% | 2.77 | 11.26 | 96.37 | 275.37 |
| 201040 Electrical Equip | HUBB/NVT | 0.6368 | 0.6957 | 0.4498 | 31.89% | 45.15% | 0.59 | 9.98 | 453.0 | 150.75 |
| 203010 Air Freight | FDX/UPS | 0.633 | 0.5625 | 0.5948 | 28.05% | 29.85% | 8.34 | 1.12 | 327.4 | 104.23 |
| 201040 Electrical Equip | VRT/GEV | 0.6252 | 0.7021 | 0.7833 | 64.98% | 51.86% | 9.1 | -14.53 | 258.72 | 898.53 |
| 201020 Bldg Products | LII/TT | 0.6214 | 0.6302 | 0.9266 | 42.59% | 28.56% | -8.39 | -22.07 | 382.64 | 444.4 |
| 201030 Constr & Eng | ACM/J | 0.5824 | 0.4775 | 0.662 | 37.83% | 33.28% | -17.3 | -27.83 | 67.43 | 149.05 |
| 201040 Electrical Equip | VRT/HUBB | 0.5769 | 0.6815 | 1.1755 | 64.98% | 31.89% | 3.19 | -17.85 | 258.72 | 453.0 |
| 201030 Constr & Eng | DY/EME | 0.5534 | 0.6656 | 0.6345 | 51.69% | 45.08% | -19.69 | -29.44 | 291.21 | 734.54 |
| 201060 Machinery | CMI/PCAR | 0.5029 | 0.3912 | 0.6722 | 36.72% | 27.47% | -7.01 | -25.68 | 564.4 | 124.13 |

### Health Care

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 351020 HC Distributors | COR/MCK | 0.7116 | 0.8197 | 0.757 | 32.51% | 30.56% | -2.1 | 1.78 | 323.6 | 885.32 |
| 352030 Life Sci Tools | RVTY/TMO | 0.6955 | 0.6928 | 0.8732 | 38.02% | 30.28% | 4.17 | 3.1 | 128.67 | 617.1 |
| 351020 Managed Care | ELV/UNH | 0.6637 | 0.6228 | 0.6491 | 35.8% | 36.61% | 8.8 | -5.03 | 392.54 | 389.41 |
| 351020 Managed Care | CNC/MOH | 0.5487 | 0.6449 | 0.4836 | 49.21% | 55.84% | -1.14 | -4.7 | 64.34 | 198.77 |
| 351010 HC Equipment | BAX/BDX | 0.5134 | 0.5801 | 0.9062 | 44.34% | 25.12% | -17.99 | 11.87 | 26.0 | 188.11 |
| 351010 HC Equipment | ZBH/SYK | 0.5043 | 0.752 | 0.5835 | 32.56% | 28.14% | 8.25 | 12.49 | 100.04 | 323.8 |

## PART 1B - 0.30-0.49 band, BELOW the spec floor (20 pairs) - context / SL1 ideation only

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 202020 Prof Services | EFX/VRSK | 0.4974 | 0.7406 | 0.5555 | 39.08% | 34.99% | 8.3 | 3.64 | 189.16 | 193.78 |
| 201020 Bldg Products | MAS/CARR | 0.4874 | 0.6223 | 0.479 | 35.08% | 35.7% | 4.4 | 15.19 | 72.16 | 58.22 |
| 351020 Managed Care | CVS/CI | 0.4873 | 0.4825 | 0.4597 | 31.49% | 33.38% | -8.76 | 2.94 | 93.91 | 276.08 |
| 452020 Tech Hardware | HPQ/DELL | 0.4801 | 0.1354 | 0.3 | 43.02% | 68.85% | 4.4 | 4.45 | 30.02 | 456.01 |
| 352020 Pharma | BMY/MRK | 0.4773 | 0.5797 | 0.4334 | 27.41% | 30.19% | -13.6 | -6.71 | 66.81 | 147.76 |
| 255040 Specialty Retail | AAP/ORLY | 0.4772 | 0.5001 | 1.1128 | 59.88% | 25.68% | -23.18 | -31.36 | 42.18 | 88.8 |
| 201010 Aero & Defense | TXT/GD | 0.4744 | 0.5614 | 0.5778 | 27.01% | 22.18% | -3.85 | -19.56 | 80.56 | 371.35 |
| 453010 Semis | MRVL/AVGO | 0.4706 | 0.6652 | 0.7495 | 77.02% | 48.36% | 14.81 | 15.95 | 211.66 | 370.34 |
| 453010 Semis | AMD/NVDA | 0.47 | 0.5463 | 0.8751 | 70.67% | 37.96% | -9.72 | -6.13 | 470.72 | 220.78 |
| 352010 Biotech | GILD/AMGN | 0.4665 | 0.5555 | 0.4521 | 26.55% | 27.39% | -1.88 | -18.99 | 146.34 | 429.88 |
| 201060 Machinery | CR/ITW | 0.4661 | 0.3824 | 0.7046 | 32.23% | 21.32% | -1.95 | 0.62 | 205.07 | 275.37 |
| 352010 Biotech | BIIB/VRTX | 0.4567 | 0.4702 | 0.5621 | 34.88% | 28.34% | -8.33 | -11.5 | 216.65 | 544.52 |
| 351010 HC Equipment | MDT/BSX | 0.4553 | 0.6559 | 0.2761 | 23.37% | 38.54% | 4.85 | 21.87 | 90.65 | 48.3 |
| 453010 Semis | INTC/TXN | 0.4323 | 0.7315 | 0.8006 | 77.32% | 41.75% | 1.38 | -7.12 | 89.51 | 260.91 |
| 352020 Pharma | PFE/LLY | 0.4318 | 0.5076 | 0.2892 | 23.84% | 35.61% | 10.55 | 4.15 | 28.46 | 1156.73 |
| 302010 Beverages | KDP/MNST | 0.371 | 0.5707 | 0.3836 | 27.07% | 26.18% | 4.9 | 2.42 | 31.86 | 45.92 |
| 551010 Utilities | PCG/NEE | 0.3605 | 0.2748 | 0.5908 | 35.07% | 21.4% | -19.0 | -16.26 | 13.27 | 82.34 |
| 402030 Capital Markets | NDAQ/CME | 0.327 | 0.5375 | 0.3799 | 27.71% | 23.85% | -2.51 | -4.51 | 98.61 | 285.5 |
| 352030 Life Sci Tools | ILMN/DHR | 0.3091 | 0.19 | 0.4626 | 46.99% | 31.41% | -0.32 | 11.22 | 213.63 | 213.56 |
| 253020 Restaurants | YUM/QSR | 0.3063 | 0.4594 | 0.3044 | 23.84% | 23.98% | -3.74 | -2.96 | 153.31 | 77.88 |

## PART 1C - BELOW the 0.30 population rail (6 pairs) - OUT OF POPULATION

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 502020 Media | PSKY/FOXA | 0.1987 | 0.2266 | 0.2846 | 52.05% | 36.34% | 17.99 | -1.45 | 10.91 | 67.35 |
| 502020 Media | LYV/SPOT | 0.1429 | 0.2741 | 0.1022 | 31.54% | 44.13% | -12.77 | -1.52 | 179.89 | 543.62 |
| 501010 Telecom | TMUS/CMCSA | 0.0945 | 0.419 | 0.0908 | 30.33% | 31.58% | -5.25 | -8.75 | 180.69 | 26.62 |
| 253020 Restaurants | SBUX/CMG | 0.0025 | -0.0712 | 0.0036 | 42.58% | 29.4% | -0.37 | 27.86 | 38.03 | 180.44 |
| 351010 HC Equipment | PODD/DXCM | -0.0175 | 0.0892 | -0.0289 | 46.12% | 27.87% | -15.18 | -9.73 | 148.66 | 106.25 |
| 502020 Media | WBD/NFLX | -0.1262 | 0.0192 | -0.1417 | 40.07% | 35.67% | -1.18 | 10.29 | 28.53 | 81.05 |

## PART 1D - measured but WITHHELD (2 pairs)

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | FITB/HBAN | 0.8672 | 0.8031 | 0.8364 | 25.78% | 26.73% | -1.58 | 5.36 | 53.77 | 16.68 |
| 451030 Software | MDB/SNOW | 0.625 | 0.7058 | 0.6769 | 65.21% | 60.22% | 18.88 | -6.05 | 453.37 | 331.43 |
## PART 1B notes — why these three sub-floor pairs are recorded

Per §19 the 0.50 bar **derives from** Strategy E's spec_hash-frozen Entry criterion 3 and is **not** a screen tune. Sub-floor pairs are recorded `below_spec_floor=true`, are SL1 ideation evidence only, and are **never** entry candidates. §19 caps the record at **3 per call**, binding both the fields-JSON `passed` items and this note — the same three pairs appear in both.

| Pair | 252d | 60d | Why it is recorded anyway |
|---|---|---|---|
| **AMD/NVDA** (453010) | **0.4700** | 0.5463 | **Fourth consecutive month below the floor** — 0.49 (June), 0.4933 (July), 0.492 (August), **0.4700 now** — and for the first time it is moving *away* from the floor rather than hovering. August recorded this as "an established sub-floor pattern, not a monthly novelty." A fourth reading that decays rather than converges upgrades that from a pattern to a settled finding: this is not a pair whose correlation is about to qualify, and it should stop being re-litigated as a near-miss. |
| **AAP/ORLY** (255040) | **0.4772** | 0.5001 | August recorded this at **0.499**, missing by 0.001, and deliberately refused to round it up. **That discipline is now vindicated by the data**: a month later it sits at 0.4772, materially further below the floor, with a −31.36pp 3M spread that would have looked like an enormous opportunity to anyone who had rounded. The single cleanest live argument in the whole screen for why the floor is mechanical. |
| **EFX/VRSK** (202020) | **0.4974** | 0.7406 | Misses by **0.0026**, and is the *dominated* expression of a thesis that IS advancing: EFX/TRU measures 0.8462 and carries the same long leg. Recorded to make the point that the screen advanced the better-hedged expression of the Equifax idea and rejected the weaker one on a mechanical number, not on narrative preference. Its 60d/252d gap (+0.243) is the widest in the band and worth re-checking next cycle. |

## PART 1E — reconciliation of the 2026-08-03 shortlist

**Five of the ten pairs the August screen advanced are dropped this cycle.** That is high turnover and it is not churn: each drop is carried by dated public evidence gathered this session, and two of them are corrections to factual errors in the August edition rather than changes in the world.

| Prior pair | Prior tier | Status | Reason (public-information only) |
|---|---|---|---|
| **COR/MCK** (0.7116) | TOP | **DROP — the catalyst fired and falsified the thesis** | The most decisive reconciliation in the screen. Both legs reported **2026-08-05** as predicted, and the thesis was wrong directionally. MCK posted adj EPS $9.93, **+20% YoY**, revenue $105.4B (+8%), raised FY27 adj EPS guidance to $44.20–45.00 and lifted the dividend 15%; it closed **+5.64%** on the print. COR beat too — adj EPS $4.48 vs $4.35, revenue $84.8B (+5.1%), FY26 guidance raised a second time to $17.75–17.95 — but closed only **+3.57%**. Since 2026-08-03 MCK has gained 6.61% against COR's 5.66%, so the gap the thesis said would close instead **widened slightly in the leader's favour**. The premise — that MCK's multiple rested on narrative rather than the quarter — is refuted by a quarter that grew adjusted EPS 20%. Cardinal Health's 2026-08-11 print is a useful control: it beat by 20% but **$0.31/share of that was a one-time IEEPA tariff refund**, and the stock moved only +1.3%, i.e. this market demonstrably does discount non-repeating drivers in this sub-industry — which undercuts the "the market is being fooled by MCK's optics" reading. Recorded honestly as a **falsified thesis**, not a timing miss. *(Separately noted, not relied upon: MCK disclosed a cybersecurity incident in an 8-K filed 2026-08-28, discovered 2026-08-25, not yet deemed material.)* |
| **CB/TRV** (0.7157) | TOP | **KEEP — demoted to REST, reduced conviction** | The mispricing the thesis was built on has largely closed **without the catalyst firing**. Forward P/E is now **CB 12.10 vs TRV 12.19** — near-parity, where the August thesis rested on TRV's forward multiple having been pushed *above* Chubb's. Meanwhile the named mechanical catalyst has become less likely, not more: the Atlantic season through 2026-08-31 has produced only four **tropical storms** (Arthur, Bertha, Cristobal, Dolly) with **no hurricane-strength landfall**, and CSU's below-normal seasonal forecast is holding. Retained only because the structure remains the safest in the screen (vols 20.7%/19.4%, the lowest of any candidate) and cat-loss normalisation still has Q3/Q4 to run. |
| **EFX/TRU** (0.8462) | REST (top of stack) | **KEEP — PROMOTED TO TOP** | The only carry-forward that did what it was supposed to. See PART 2 §2. |
| **MCHP/ADI** (0.8049) | REST | **KEEP — REST, substantially realised** | See PART 2 §4. Both catalysts fired; the pair reconverged from −13.30pp to −9.67pp on the 3M measure. |
| **PPG/SHW** (0.7324) | REST | **DROP** | The August demotion was the right call and the evidence has only accumulated. The shared end-market deteriorated for **both** legs — July housing starts −12.4% MoM to a 1.239M SAAR (Census, released 2026-08-18), NAR existing-home sales −1.7% MoM (released 2026-08-11), 10Y at 4.75%, its highest since January 2025 — so the macro does not discriminate between the legs. What *does* discriminate cuts against the thesis: SHW picked up a fresh **Guggenheim initiation at Buy, $400 PT, 2026-08-03**, with no comparable fresh bullish action on PPG, and SHW's Paint Stores Group grew same-store sales 4.2% against that same weak tape while pushing through an 8% price increase effective 2026-09-01. That is channel insulation, i.e. the two businesses are less comparable than "same 6-digit GICS" implies, and the gap is earned. |
| **VRT/NVT** (0.7015) | REST | **DROP** | Two independent reasons. **(i) It has already substantially reconverged**: the 3M spread narrowed from −23.22pp in August to **−7.87pp** now, and VRT out-performed by +3.79pp over the last month — most of the gap the thesis existed to harvest is gone. **(ii) The earned case strengthened on new public information**: on **2026-08-24** nVent announced a definitive agreement to acquire **Maverick Power for $1.75B** (+ up to $550M earnout), a data-centre power-distribution platform, funded from cash plus a BofA bridge and guided EPS-accretive in year one — a company expanding into the exact contested end-market from balance-sheet strength. Vertiv meanwhile spent August absorbing shareholder-litigation overhang stemming directly from the execution miss. *(Discipline note: those "investigations" are standard plaintiff-firm solicitation releases issued after almost any sharp drop — no complaint has been filed and no findings exist. Their existence is a fact and is recorded as overhang; their allegations are not evidence and are not relied on.)* |
| **PANW/CRWD** (0.8200) | REST | **KEEP — REST, EVENT-PENDING** | See PART 2 §7. Two date corrections apply; the pair is genuinely unresolvable today. |
| **FTNT/CRWD** (0.6967) | REST | **DROP — decisive, on a factual error in the August edition** | The thesis's central tell does not survive verification. August argued that on **2026-07-29** CRWD rose "as much as +11%" and PANW +7% **on Fortinet's news** — a sympathy re-rating with no name-level information. Close-to-close, **both legs fell that day**: CRWD $181.80 → $179.38 (**−1.33%**) and PANW $319.00 → $314.15 (**−1.52%**). The +11%/+7% figures appear to belong to an entirely different, later event — **CRWD's own 2026-08-26 earnings reaction**. The August screen relied on an intraday move that fully reversed, and attributed magnitudes from one event to another. With the tell removed there is no differentiating case for this pair over §7, which has both the better hedge and the live catalyst. |
| **COF/AXP** (0.7727) | REST, flagged | **KEEP — REST, decayed by success** | See PART 2 §5. The pair has been working: +10.92pp over 3M, so much of the thesis is realised. |
| **WFC/C** (0.6921) | REST, reduced | **DROP** | Every remaining support has now been retired. **(i)** The hedge is still weakening — 60d **0.6716** below the 252d **0.6921**, the same relationship August flagged, now for a second consecutive month. **(ii)** August's one open factual question is closed: **Citigroup filed its Q2 2026 10-Q on 2026-08-06** (SEC EDGAR, CIK 0000831001) — the "first detailed look still pending" is no longer pending, and it landed on Citi's ordinary cadence, so there was never an anomaly. **(iii)** The catalyst August flagged as "unverified as to date" is now pinned and is **stale by fifteen months**: the Federal Reserve removed Wells Fargo's asset cap on **2025-06-03** (Fed press release; confirmed by Wells Fargo's own newsroom), with the underlying enforcement action closed in March 2026. Goldman's Conviction List addition dates to **2026-07-01**. Neither is a forward catalyst. Both banks report Q3 on **2026-10-13** (CONFIRMED, each issuer's own IR page). Nothing is left but a residual valuation sliver on a decaying hedge. |

---

# PART 2 — Ranked shortlist of divergence theses (public-information-only)

**How this ranking was produced.** The ten August pairs were reconciled against dated public evidence (PART 1E); six new candidates drawn from this cycle's measured population were researched from public sources. **Three of the six new candidates were killed** and five of the ten carry-forwards dropped. Every surviving pair carries an explicit **earned-divergence counter-argument** — a pair with no stated counter-argument was not allowed to advance. All eight meet the ≥ 0.50 spec floor on measured 252-day correlation and both legs clear the 90-day recency gate.

**Tier coding.** **TOP** = highest-conviction narrative-outpaces-fundamental thesis with a dated public catalyst and a correlation comfortably above the floor. **REST** = supportive but carrying a correlation, realisation-decay, catalyst-timing or thesis-purity caveat. M4 reads this section verbatim.

**A calibration note this cycle earned.** August assigned its top pair `conviction_pct = 75` and that thesis was **falsified two days later** by the very catalyst it named. No pair is rated above 60 this month. That is a deliberate response to a measured miss, not false modesty — the screen's conviction ladder should reflect that a dated, imminent, binary catalyst raises the *variance* of a thesis, not only its attractiveness.

### 1) Long DY / Short EME — Construction & Engineering (201030) — **TOP, NEW**
- **(a) L/S.** **EME = leader/short** (~$734.54). Its Q2 print on 2026-07-30 was a clean beat-and-raise: revenue $5.15B (+19.8%), FY26 EPS guidance raised to $32.00–33.25 from $28.25–29.75; the stock closed **+19.3%** on the day ($672.48 → $802.37, verified close-to-close from IBKR daily bars). **DY = laggard/long** (~$291.21). Dycom's fiscal Q2 2027 was, on the numbers, a *record*: revenue $2.01B **+45.6% YoY**, backlog **+53.2% to $12.24B**, and full-year revenue guidance **raised** to $7.48–7.66B from $6.85–7.15B. It closed **−11.6%** on 2026-08-26 ($351.80 → $310.91, verified close-to-close) and kept sliding to roughly −17% on the week.
- **(b) Divergence thesis.** Corr **0.5534**, 60d **0.6656** — above the floor and strengthening, though the weakest hedge of any advanced pair, which is the main reason this is not a higher-conviction call. **3M spread −29.44pp — the largest divergence in the entire 81-pair population** — and 1M **−19.69pp**, so the divergence is recent and accelerating rather than stale. The asymmetry is the point: a company that raised full-year revenue guidance and posted a record backlog was marked down 11.6% in a session, while its same-industry peer that also beat was marked *up* 19.3%. What DY actually delivered against what the tape did to it is the widest such gap this screen has measured.
- **(c) Reconvergence indicators.** (i) **DY fiscal Q3 2027 results — ESTIMATE, ~mid-to-late November 2026**; not issuer-scheduled yet, and the prior-year comparable was 2025-11-19. The direct test is whether the ~$150M of wireless-replacement revenue that shifted into FY28 shows up as guided. (ii) **EME Q3 2026 — ESTIMATE ~2026-10-29**, aggregator-sourced, not IR-confirmed. (iii) Further sell-side target revisions on DY: post-print, KeyBanc, BofA, Cantor and B.Riley all *raised* targets into the $610–654 range while only Wells Fargo cut (to $550), against a ~$291 close.
- **(d) Borrow/cost fit.** EME short interest ~**2.1% of float** (~0.9–0.94M shares) — low, no squeeze signal; aggregator-sourced and therefore an ESTIMATE, not exchange-confirmed. No evidence of special borrow. DY's own short interest was not sourced. Re-quote at execution.
- **(e) Execution.** Individual-stock, both legs. **DY's ~$173.1M average daily dollar volume is the lowest of any advanced leg** (IBKR `avg_90d_usd_volume`) — still more than 17× the $10M floor, so not a constraint, but it is the thinnest name in the shortlist and worth naming. DY vol 51.7% / EME 45.1%: beta-adjusted sizing matters here.
- **(f) Tier: TOP** on divergence magnitude and freshness. **Honest risk — and it is not small.** The margin compression and the deferral are *real, disclosed facts*, not rumour: communications-segment adjusted EBITDA margin fell to 13.6% from 14.9% YoY, the Q3 EPS guide ($4.33–4.79) missed the ~$4.68 consensus midpoint, and ~$150M of revenue moved out of the fiscal year. A ~$637 consensus target against a ~$291 price can mean the sell-side is slow to reprice a genuine deceleration just as easily as it can mean the market overreacted. **This pair should be re-tested for further target cuts before it is sized**, and the "raised guidance" headline must not be allowed to obscure that the raise was on revenue while the miss was on margin.

### 2) Long EFX / Short TRU — Professional Services (202020) — **TOP (carry-forward, promoted)**
- **(a) L/S.** **TRU = leader/short** (~$84.91; Q2 2026-07-28, revenue $1.31B +14.9% YoY, beat, raised full-year guidance on financial-services strength). **EFX = laggard/long** (~$189.16; Q2 2026-07-21, revenue $1.70B in line, adj EPS $2.25 vs $2.20 — a beat — but Q3 EPS guidance below consensus and a sharp de-rating).
- **(b) Divergence thesis.** Corr **0.8462**, 60d **0.8729** — **the highest measured correlation of any live thesis in this screen, and strengthening**, i.e. structurally the best-hedged pair on the list. Both are consumer-credit-bureau businesses in the same 6-digit industry with heavily overlapping end-markets. **This is the one carry-forward that has done what it was supposed to do**: since 2026-08-03 EFX has gained **+8.6%** against TRU's **+6.2%**, and the 3M spread has narrowed from −12.18pp in August to **−6.54pp** now. It is reconverging, on schedule, in the predicted direction.
- **(c) Reconvergence indicators.** (i) **NAR August existing-home sales — CONFIRMED 2026-09-10**, the next direct read on the shared driver and the nearest dated catalyst in the entire shortlist. (ii) EFX Q3 2026 (~late October, ESTIMATE, not issuer-confirmed) — the direct test of the Q3 guide that caused the de-rating. (iii) TRU Q3 2026 (~late October, ESTIMATE).
- **(d) Borrow/cost fit.** TRU measured live last cycle at **0.25% fee rate with 1,800,000 shares available** — GC, ample, no hard-to-borrow flag; on a $150 short leg held three months that is roughly $0.09. Immaterial against the 15%-of-thesis-return ceiling. Not re-measured this session; re-quote at execution.
- **(e) Execution.** Both legs far above any commission break-even; ADV $600M+ and $370M+ respectively.
- **(f) Tier: TOP.** Promoted from REST on realised behaviour plus the best hedge in the screen. **The public macro corroborates the laggard's own framing rather than contradicting it**: EFX attributed its guide-down to a tough mortgage market, and July existing-home sales fell 1.7% MoM with the 30-year fixed near a one-year high and the refi index still ~22% below year-ago — that is a cycle condition, not an EFX-specific failure, and it is the condition TRU carries far less of. **Honest risk (unchanged and material):** that asymmetry cuts both ways — TRU genuinely has less mortgage exposure, so part of the gap is a real difference in end-market mix. **A second, newer counter:** TRU's +5.1% single-day move on 2026-08-19 was attributed to its own consumer-credit-score system overhaul — a company-specific growth initiative unrelated to the mortgage cycle, meaning some of TRU's relative strength is idiosyncratic and earned.

### 3) Long NOW / Short WDAY — Software (451030) — **REST (top of stack), NEW — note the inverted direction**
- **(a) L/S.** **WDAY = leader/short** (~$197.45) and **NOW = laggard/long** (~$147.99) — *on price behaviour*, which is the opposite of the way this pair would usually be framed on fundamentals. ServiceNow's Q2 2026 (10-Q filed 2026-07-23, period ended 2026-06-30) showed subscription revenue **+23–24.5% YoY** and cRPO **+21%**, with FY26 subscription guidance raised to $15.76–15.78B. Workday's Q2 FY2027 (10-Q filed 2026-08-27, period ended 2026-07-31) showed subscription revenue **+13.9%** and cRPO **+14.2%** — roughly 60% of ServiceNow's growth rate.
- **(b) Divergence thesis.** Corr **0.7527**, 60d 0.7441, beta 0.7053. Over three months **WDAY outperformed NOW by +16.65pp** despite growing at well under half its rate, on an AI-"agent system of record" narrative (AI SKU ARR reported +200% YoY to ~$600M). The price gap ran in the opposite direction to the fundamental growth gap — a textbook Strategy E setup, with the unusual feature that the *faster-growing, higher-quality* leg is the long.
- **(c) Reconvergence indicators.** (i) **The first leg has already delivered**: WDAY's 2026-08-27 print sent shares down ~7% after-hours on a subscription-guidance miss ($2.52B) with commentary that reacceleration "is still elusive" — which is visible in the measured **1M spread of +9.97pp in NOW's favour**. (ii) WDAY fiscal Q3 2027 and NOW Q3 2026 — both ESTIMATE, ~late October/November, neither issuer-scheduled.
- **(d) Borrow/cost fit — THE BINDING CAVEAT ON THIS PAIR.** WDAY short interest is reported at **~14.0% of float** in one aggregator snapshot (described as up sharply) but at **4–5%** in others. **These cannot both be right and neither is exchange-confirmed.** A 14%-of-float short leg is a materially different proposition from a 4% one for both borrow cost and squeeze risk. **This pair must not be sized before the S leg's short interest is pinned to a primary FINRA/exchange settlement-date source.** Recorded as UNVERIFIED rather than split the difference.
- **(e) Execution.** Both legs are the most liquid in the screen (NOW ~$3.36B/day, the highest ADV of any leg). Vols 53.0% / 56.6% — the highest-volatility pair advanced, so hedge-ratio error is costly.
- **(f) Tier: REST (top of stack).** Held below TOP for two reasons stated plainly: roughly half the reconvergence has **already happened** on the 2026-08-27 print, so entry today is chasing a partially-played move; and the short leg's borrow picture is unresolved. **Honest risk:** Workday's AI-agent monetisation is a real, disclosed, growing revenue line (>$100M new ACV in the quarter, 25%+ of new ACV, 5,500+ customers, +35% QoQ) — the three-month rally may be an early re-rating of a legitimate new growth vector rather than hype, and ServiceNow's existing premium (EV/Revenue ~7.4–9× vs WDAY ~5.0×) already prices it as the structurally faster grower, so part of the "gap" is ordinary multiple arithmetic.

### 4) Long MCHP / Short ADI — Semiconductors (453010) — **REST (carry-forward, substantially realised)**
- **(a) L/S.** **ADI = leader/short** (~$362.14). **MCHP = laggard/long** (~$73.45).
- **(b) Divergence thesis.** Corr **0.8049**, 60d **0.8882** — high and strengthening, the second-best hedge on the list. But **the reconvergence largely happened during the month**: the 3M spread narrowed from −13.30pp in August to **−9.67pp**, and the mechanism was exactly the one the thesis named. Microchip's FQ1 2027 (2026-08-06, CONFIRMED via SEC 8-K and its own IR) printed net sales $1.485B **+38% YoY / +13.2% QoQ**, non-GAAP EPS $0.76 against a $0.67–0.71 guide, **book-to-bill "well above 1" on its best bookings quarter in about four years**, distribution inventory down to 25 days and total inventory days down 10 QoQ — and the stock closed **+13.9%** the next session. Analog Devices' FQ3 (2026-08-19, CONFIRMED) was a *record* quarter — $4.02B revenue (+40% YoY, its first $4B quarter), adj EPS $3.45 (+68%), 72.5% adj gross margin — and the stock closed **−0.81%**, a sell-the-news fade.
- **(c) Reconvergence indicators.** (i) ADI FQ4 2026 and MCHP FQ2 2027 — both **ESTIMATE, ~November**, neither company-confirmed this session. (ii) Both companies' book-to-bill and inventory-days disclosures, the shared cycle indicator; note **neither company discloses a numeric book-to-bill**, only qualitative language, so this indicator is directional only.
- **(d) Borrow/cost fit.** ADI not sampled live this cycle; mega-cap GC, no evidence of special borrow.
- **(e) Execution.** Standard. Vols 49.3% / 35.5%, beta 1.1184 — the only advanced pair with beta above 1.
- **(f) Tier: REST.** Held down precisely because it worked: the cycle-inflection catalyst on the long leg has already fired favourably, so materially less of the gap remains than the raw 3M number suggests. **Honest risk:** ADI's margin and cash-flow profile (72.5% GM, 50% adj operating margin, record FCF on 40% growth) is structurally superior to Microchip's, and MCHP's GAAP EPS — $0.22 in FQ4 2026, improving only to $0.37 now — remains depressed by preferred-dividend and restructuring accounting against a genuine inventory-correction cycle. Part of the discount is earned.

### 5) Long COF / Short AXP — Consumer Finance (402020) — **REST (carry-forward, decayed by success)**
- **(a) L/S.** **AXP = leader/short** (~$330.17). **COF = laggard/long** (~$214.51).
- **(b) Divergence thesis.** Corr **0.7727**, 60d 0.7536, beta **0.9298** — nearly dollar-neutral, still the cleanest structure in the screen. The thesis is intact but **has substantially paid out already: +10.92pp over 3M and a further +2.76pp in the last month**, so what remains is the tail of a working trade rather than a fresh dislocation.
- **(c) Reconvergence indicators.** (i) **AXP Q3 — CONFIRMED 2026-10-23, 08:30 ET**, sourced to American Express's own IR release pre-announcing its full 2026 schedule. **This is the only issuer-confirmed earnings date in the entire shortlist** (see the provenance note below). (ii) COF Q3 — **ESTIMATE ~2026-10-20**; no COF-issued confirmation found, and Capital One appears to announce quarter-by-quarter closer to the date. (iii) COF's next monthly credit-metrics 8-K (August data), expected ~mid-September on the observed cadence.
- **(d) Borrow/cost fit.** Both GC; no evidence of special borrow on AXP.
- **(e) Execution.** Standard.
- **(f) Tier: REST, flagged for decay.** **The credit check the August edition asked for was run, and it is genuinely two-sided.** From the issuers' own 8-K/ABS trust filings: COF's July 2026 domestic-card annualised net charge-off rate is **4.12%** (auto 1.48%); American Express's Card Master Trust reported an annualised net default rate of **1.1% in July rising to 1.2% in August**. **These are not like-for-like** — COF's book skews subprime/near-prime card plus auto, AXP's skews affluent charge/spend-centric — so the ~3.5× ratio is not evidence of deterioration. What it *is* evidence of is that August's stated risk is real: COF's discount is partly a genuine credit-quality difference. **A June comparable for COF was not retrieved, so its July level cannot be characterised as improving, flat or deteriorating** — stated as a gap, not smoothed over. One risk *has* retired: the CFPB cleared the Capital One–Discover transaction under fast-track review, finding it unlikely to raise serious competition concerns.

### 6) Long CB / Short TRV — Insurance (403010) — **REST (carry-forward, demoted from TOP)**
- **(a) L/S.** **TRV = leader/short** (~$365.93). **CB = laggard/long** (~$338.60).
- **(b) Divergence thesis.** Corr **0.7157**, 60d 0.7313 (stable), and **vols 20.7% / 19.4% — the lowest of any pair in the screen**, so hedge-ratio error costs least here. The measured divergence actually **widened**: CB−TRV is −17.35pp over 3M. But the *stated* mispricing has closed — forward P/E is now **CB 12.10 vs TRV 12.19**, essentially parity, where the August thesis rested on TRV's multiple having been pushed above Chubb's on a non-repeatable catastrophe-loss benefit. A 17pp price divergence with P/Es at parity means forward EPS estimates moved with the price, which is the *earned* reading, not the narrative one.
- **(c) Reconvergence indicators.** (i) Q3 catastrophe-loss disclosure at either insurer, spanning peak Atlantic season — but see the risk below. (ii) CB Q3 — **ESTIMATE ~2026-10-20**; TRV Q3 — **ESTIMATE ~2026-10-15**. Neither is issuer-confirmed: Q3 has not closed and neither company has published its call announcement. **August recorded CB's date as "confirmed 2026-10-20"; that could not be re-confirmed this session and is downgraded to ESTIMATE.**
- **(d) Borrow/cost fit.** Both large-cap GC insurers; no evidence of special borrow.
- **(e) Execution.** Structurally the safest pair in the screen on volatility.
- **(f) Tier: REST, demoted from TOP.** **Honest risk, and it is now the leading reading:** the mechanical catalyst has not fired and is looking less likely to. The Atlantic season through 2026-08-31 produced four **tropical storms** and **no hurricane landfall**, with CSU's below-normal forecast holding. A thesis whose reconvergence mechanism is "a hurricane forces catastrophe-loss normalisation" is weaker in a below-normal season, and with the valuation gap already closed there is materially less left to harvest than in August.

### 7) Long PANW / Short CRWD — Software (451030) — **REST, EVENT-PENDING TONIGHT — two date corrections**
- **(a) L/S.** **CRWD = leader/short** (~$231.00). **PANW = laggard/long** (~$382.13).
- **(b) Divergence thesis.** Corr **0.8200**, 60d **0.8970** — strengthening, and now the best-hedged of the carry-forwards. 3M spread +9.04pp in PANW's favour, 1M −3.97pp.
- **(c) TWO DATE CORRECTIONS to the August edition, both verified at the primary source.** **(i) CrowdStrike did NOT report on 2026-09-02.** It reported **2026-08-26**, after close — SEC 8-K carrying Item 2.02 filed that date, with the 10-Q for the period ended 2026-07-31 filed 2026-08-27. The August screen listed "CRWD FQ2 confirmed 2026-09-02" as the freshest catalyst for both this pair and §8; **that catalyst has already fired**, and its result cuts *against* the short leg: revenue $1.47B (+26% YoY, a beat), **record net-new ARR $333M (+51% YoY)**, ending ARR $5.84B (+25%), FCF $377M, and FY27 guidance raised to $5.99–6.01B revenue / $1.25–1.26 EPS, above consensus; the stock rose more than 11%. **(ii) Palo Alto did NOT report on 2026-08-24.** August recorded that date as "confirmed, corroborated by two independent sources." SEC EDGAR shows **no Item 2.02 filing** for PANW between 2026-06-02 and today — its 2026-08-21 8-K carries items 5.02/5.03/9.01 (officer change and bylaw amendment), not results. PANW's own press release states it reports **2026-09-01 — today — after close.** *(Carried forward and re-verified: the PANW/CyberArk deal closed **2026-02-11**; aggregators calling it an "August 2026" event remain wrong.)*
- **(d) Borrow/cost fit.** CRWD's short-interest build that August flagged has **not** continued: ~2.40% of float / 24.16M shares (2026-09-01) and ~2.54% / 25.56M shares with 2.30 days to cover (2026-08-28), against August's 2.74% reading — flat-to-lower, with a quoted **borrow rate of 0.25%** and no hard-to-borrow signal. August's instruction that "CRWD is the one name warranting an individual SLB check before entry" is **partially discharged**: the escalating-short-pressure concern is refuted, though these remain aggregator figures rather than a live SLB quote.
- **(e) Execution.** Standard; vols 43.7% / 52.3%.
- **(f) Tier: REST, EVENT-PENDING.** **This pair is genuinely unresolvable today and it would be dishonest to rate it otherwise.** Half its evidence is a week old and unfavourable — CrowdStrike's own quarter argues its premium is being earned by a business that is *reaccelerating*, which is the opposite of the thesis premise — and the other half lands hours after this file is written. **Per Decision discipline, this deferral names its resolver and its default: M4 must re-check PANW's FQ4 result before queueing this pair, and if it cannot, the conservative default is to decline. The deferral does not chain — it resolves at M4 or it dies there.**

### 8) Long F / Short GM — Automobiles (251020) — **REST (bottom), NEW, size-limited**
- **(a) L/S.** **GM = leader/short** (~$86.32; Q2 2026 beat-and-raise per its 2026-07-21 8-K). **F = laggard/long** (~$13.94; Q2 2026 revenue $48.3B with a **GAAP net loss of $1.3B**).
- **(b) Divergence thesis.** Corr **0.5707**, 60d **0.6496** (strengthening), beta 0.6386. 3M spread **−20.58pp**. The candidate mispricing is an optics/substance gap: Ford's GAAP loss came almost entirely from a **disclosed, previously-announced, one-time EV retreat** — a $3.6B BlueOval SK JV wind-down plus a $500M program cancellation, decided in December 2025 and executed in H1 2026 — while Ford's *adjusted* EBIT was $2.5B and it **raised** full-year adjusted EBIT guidance to $10–11B on the same day. A headline loss driven by a pre-announced strategic write-down is the cleanest available example of narrative running ahead of economics.
- **(c) Reconvergence indicators.** (i) Ford Q3 2026 — **ESTIMATE ~2026-10-22**; Ford's own IR events page lists no Q3 event yet. (ii) GM Q3 2026 — **ESTIMATE ~2026-10-20**; GM's IR page returned HTTP 503 on fetch, so this is aggregator-sourced and not primary-confirmed. (iii) Monthly US sales releases from both.
- **(d) Borrow/cost fit.** GM short interest **~2.2–3.6% of float** depending on source and date — low single digits, no squeeze signal, but the sources conflict and none is exchange-confirmed. ESTIMATE.
- **(e) Execution.** Both highly liquid. Note Ford's ~$13.94 share price: at small book sizes the fractional-share mechanics matter more here than anywhere else in the shortlist.
- **(f) Tier: REST (bottom), explicitly size-limited.** **Honest risk, and it is quantified and real:** GM's margin advantage is not narrative. Its 10-Q shows **warranty expense for recall campaigns fell to $310M in H1 2026 from $614M in H1 2025 — down 49% YoY** — North America EBIT margin rose 2.5pp to 8.6%, and management explicitly cited lower warranty costs as a guidance driver, while Ford still carries roughly 12M vehicles under recall in 2026. A meaningful part of the −20.58pp gap is Ford earning a genuine quality/warranty deficit. This advances as the weakest of the eight, on the strength of the GAAP-versus-adjusted asymmetry alone, and should be sized accordingly. *(One widely-circulated Ford August US sales figure was **excluded** rather than repeated: the source carried a 2024 headline under a 2026 copyright, and neither automaker had released August US sales as of this run.)*

---

## Considered and NOT advanced (new candidates this cycle)

| Pair | 252d | Why not |
|---|---|---|
| **ZBH/SYK** | **0.5043** | **Newly above the floor — and still not advanced.** August recorded this at 0.493 as the widest 60d-over-252d gap in the population and predicted the trailing window understated it; that call was right, the 252d has crossed the floor and 60d is **0.752**. But crossing a mechanical gate does not create a thesis. Both legs' recent moves trace to real, disclosed, company-specific events: Stryker fell ~9% after 2026-07-30 on the continuing fallout from a disclosed March 2026 cybersecurity incident **and** a −6.7% decline in US Vascular from a supply disruption, and only *narrowed* rather than raised full-year guidance; Zimmer beat (net sales $2.177B +4.8%, adj EPS $2.07) and raised guidance on genuine ROSA traction (technology/data +21.5%). That is two different quarters, not a narrative gap. Note also that ZBH has been **out-performing** (+12.49pp 3M, +8.25pp 1M), so a long-ZBH thesis is late, not early — and forward P/E is still ~20× SYK vs ~11× ZBH, i.e. the valuation gap has **not** converged, which is what a genuine re-rating would show. |
| **ELV/UNH** | **0.6637** | **Prior drop STANDS — but on updated grounds, and the old grounds are stale.** August dropped this because UNH's discount was "substantially a disclosed regulatory/litigation risk premium." **That reason has inverted**: UNH is no longer the discounted leg — forward P/E ~18.5× UNH vs ~14.1× ELV. And one specific fact August relied on has moved: the **Claritev DOJ criminal grand jury closed on 2026-06-17** with DOJ advising Claritev it is not a target (SEC 8-K ctev-20260622), though a separate civil investigative demand from 2026-05-19 was reportedly broadened on 2026-07-16. The drop nevertheless stands for a *new* reason: Elevance's underperformance is now substantially its own earned, guided-down fundamentals — FY2026 adjusted EPS guided to "at least $27," a **~11% YoY decline** from FY2025's $30.29, on a specifically-disclosed Medicaid margin trough (operating margin guided to −1.75%, down 125bp). The August +8.8pp ELV bounce is a beat against an already-lowered bar, not a gap opening. **Re-derived, not inherited.** |
| **HAL/SLB** | **0.7019** | **REJECT — the DVN/EOG failure mode, explicitly.** August rejected DVN/EOG because a merger had changed one leg's production mix and the pair had become "a commodity-direction bet in pair clothing." HAL/SLB is the same class: the gap is substantially a structural **North-America-versus-international business-mix and commodity-sensitivity** difference, not a narrative one, with both legs hit by the *same* shared macro shock (Bab el-Mandeb tanker traffic collapsed from 5.91M to 0.79M bpd July→mid-August; Brent closed August at 93.03). A detail that makes the point sharper rather than softer: SLB has the *greater* Middle East revenue exposure (~34% of 2025 revenue vs HAL's ~23%) and outperformed anyway — so this is not simple shock-avoidance, it is a business-mix bet. SLB's differentiation (Digital +9% sequential at 35% EBITDA margin, ChampionX contributing ~$870M, a $2B+ data-centre-solutions target) is disclosed and real. |
| **MTZ/PWR** | 0.7443 | Not re-advanced. The B-book conflict that co-justified August's drop has lapsed (MTZ is not in the current book), but the independent earned-divergence reason stands and the spread **widened further to −22.09pp over 3M**. A gap that keeps widening on an earned mechanism is not a reconvergence candidate. |
| **VRT/GEV** | 0.6252 | **Cross-strategy — unchanged.** GEV is open long in the D book; an E short of GEV would largely net out at book level. Recorded, not advanced. |
| **VRT/HUBB, HUBB/NVT** | 0.5769 / 0.6368 | Not advanced — both are dominated expressions of the VRT/NVT idea, which was itself dropped this cycle (PART 1E). |

---

## Tier summary and ordering

**TOP (2):** §1 DY/EME (corr 0.5534; −29.44pp 3M, the largest divergence in the population), §2 EFX/TRU (corr 0.8462, the best hedge in the screen, and the one carry-forward measurably reconverging as predicted).

**REST (6):** §3 NOW/WDAY, §4 MCHP/ADI, §5 COF/AXP, §6 CB/TRV, §7 PANW/CRWD *(event-pending tonight)*, §8 F/GM *(size-limited)*.

Total shortlist **8 pairs** — 3 new (DY/EME, NOW/WDAY, F/GM), 5 carried forward. **Five of August's ten were dropped** (COR/MCK on a falsified thesis, FTNT/CRWD on a factual error, PPG/SHW and VRT/NVT on strengthened earned-divergence evidence, WFC/C on the retirement of all three supports), and one prior TOP (COR/MCK) was falsified outright by the catalyst it named.

**Ordering for M4 by reconvergence-indicator proximity:** §7 PANW/CRWD (**2026-09-01, tonight, after close — CONFIRMED**) → §2 EFX/TRU (**2026-09-10 NAR existing-home sales — CONFIRMED**) → §5 COF/AXP (**AXP 2026-10-23 — CONFIRMED**; COF ~10-20 estimate) → §6 CB/TRV (~10-15/10-20, estimates) → §8 F/GM (~10-20/10-22, estimates) → §1 DY/EME (EME ~10-29 estimate; DY ~mid-to-late Nov) → §4 MCHP/ADI (~November, estimates) → §3 NOW/WDAY (~late Oct/Nov, estimates).

**A provenance correction that binds this whole ordering.** August presented several Q3 dates as CONFIRMED — SHW 2026-10-27, VRT 2026-10-28, COF 2026-10-20, CB 2026-10-20. **On re-check this session, none of those could be confirmed from the issuer**, because Q3 has not closed and these companies announce their call dates roughly three weeks ahead. Only **two dates in this entire shortlist are genuinely issuer-confirmed**: AXP's 2026-10-23 (from its January multi-quarter announcement) and PANW's 2026-09-01 (from its own press release). Everything else is an aggregator estimate and is labelled as such. The asymmetry is systematic and worth remembering: a company that pre-announces a full-year schedule is confirmable months ahead; most do not, and an aggregator's confident-looking date for an unclosed quarter is a projection.

**Execution disposition.** Individual-stock pair execution remains feasible and cheap — fractional shorts permitted, round-trip commission 0.42% of gross, borrow on sampled legs 0.25–0.43% with ample availability, all far inside Entry criterion 5's 15%-of-thesis-return ceiling. Every advanced leg clears the ADV floor by more than an order of magnitude (lowest DY ~$173.1M/day against a $10M floor). **What now stands between this shortlist and a live entry is the open `premortem-E-2026-a3` Tier-1 defect (cycle 13, awaiting orchestrator) and the trading-enable gate — not activation, and not execution.** M4 should treat PART 2 as research feedstock, with §7 carrying an explicit resolve-or-decline instruction.

---

## Data-provenance and defect notes

- **METHOD IMPROVEMENT — the recency gate now runs on SEC EDGAR primary filings.** See the PART 1 gate section. 171 of 172 tickers resolved, free and unmetered, in seconds, against a metered path that left 99 of 122 unresolved. Recommended as the standing method for this gate.
- **FMP remains largely unusable — third consecutive cycle, and the failure mode is now well characterised.** Across four independent agents this session: 5 of 7 `earnings-calendar` sweeps returned ACCESS DENIED and the 2 that succeeded returned partial row sets; `earnings-company` denied on every attempt; `chart` and `quote` denied. One agent got **~6–7 successful calls across two endpoints and then hit a session-wide lockout** that persisted regardless of symbol — matching last cycle's "three successes then quota" observation. **Treat FMP as unavailable for this screen's purposes and do not budget calls against it.**
- **THE `get_price_history` MISATTRIBUTION DEFECT REPRODUCED — three times, independently, and this cycle SEPARATES IT INTO TWO DISTINCT DEFECTS.** August concluded the swap was "CONTRACT-LEVEL, not a batching artifact," because RCL's contract returned SPOT's series byte-identically on isolated solo calls, and that "the sequential-fetch mitigation does NOT catch it." That remains true for that defect — but it is not the whole picture, and this cycle's evidence is much stronger than last cycle's on the other one:
  - **Defect A — batch-response misattribution. Reproduced independently by three of six workers.** One found its batched slots misaligned across nine of twenty-four tickers (CB↔PGR, PNC↔STT, ALL↔MTB↔TRV, BNY↔PRU chains). A second confirmed reproducibly that batched results "did not reliably match invocation order" (a slot attributed to CRWD held AMAT's series; NOW/NXPI likewise). A third had IR and FDX briefly take ACM's series. **All three detected it and all three fixed it the same way — discard the batch, re-fetch individually.** So for this defect, sequential fetching *is* an effective mitigation, and three independent reproductions make that a solid finding rather than an anecdote.
  - **Defect B — contract-level series substitution** (the RCL→SPOT case) is a different failure that survives sequential fetching. Not re-probed this cycle; August's finding stands unchallenged.
  - **Operative conclusion, refined:** fetch individually *and* cross-check independently. Sequencing is not sufficient for Defect B but it is both necessary and sufficient for Defect A, which is the far more frequent one.
- **SYSTEMATIC INTEGRITY DETECTION — new this cycle, and it closes a gap August could only spot-check.** August verified 48 legs against live snapshots and called cross-checking "the only reliable detection." Holding the whole population makes two checks possible with no external endpoint at all: **(i) a swap detector** — any two distinct tickers sharing an identical close series cannot both be genuine, which is exactly the RCL/SPOT signature; run pairwise across all 171 loaded tickers it came back **CLEAN**, with the only shared final close (MTB and PKG both at 233.94) confirmed coincidental on full-series comparison. **(ii) a frozen-print detector** for runs of ≥3 identical consecutive closes. These are free, cover the entire population rather than a sample, and should be standing checks.
- **FITB's frozen-print defect reproduced — and the window MOVED, which is diagnostically important.** August recorded six identical 53.42 closes spanning 2026-06-24 → 2026-07-01. This cycle FITB returned **the same value (53.42) for the same run length (six sessions) over a DIFFERENT window: 2026-06-12 → 2026-06-22** — plus a missing bar for 2026-06-11 entirely (250 bars where every other ticker returned 251). **A genuine frozen print is pinned to fixed calendar dates; a defect whose window shifts between fetches while preserving value and run-length points at bar assembly or date alignment, not at the underlying quote data.** FITB/HBAN is again excluded on data quality, not thesis — it would otherwise be the third-highest correlation in the population at 0.8672.
- **Independent cross-check PASSED on all 22 advanced and candidate legs.** Every leg was re-read through `get_price_snapshot` — a different endpoint from the history call — pre-market on 2026-09-01. **No discrepancy exceeded 2.7%** (largest: ZBH +2.64%, PANW −2.45%, ADI −2.19%; HAL matched exactly), and **every contract description matched the expected company**. Two further independent confirmations fell out of the narrative research, which sourced prices through an entirely different path: COR 323.60 and MCK 885.32, and EFX 189.16 and TRU 84.91, match this session's IBKR closes **to the cent**.
- **Market cap is NOT available and this is now confirmed rather than inferred.** August said "neither IBKR's snapshot nor FMP exposes live market cap for most tickers." This cycle establishes the stronger statement for IBKR: the `get_price_snapshot` `market_data_names` enum contains **no market-cap or shares-outstanding field at all**. No market caps are reported anywhere in this screen and none were estimated. The large-cap limb of the population rail is therefore carried by **ADV plus S&P-500 membership**, stated rather than papered over.
- **ADV definition, refined.** ADV is IBKR's `avg_90d_usd_volume` — 90-day, not the 30-day the screen nominally specifies. This cycle also confirms the field's documented meaning is **already a USD figure**, not a share count, so no price multiplication is applied. Every advanced leg clears $10M by more than an order of magnitude (range ~$173.1M for DY to ~$3.36B for NOW), so the 90-vs-30-day distinction changes no disposition.
- **A telemetry blind spot, referred rather than fixed here.** The SEC EDGAR work in this run was done by direct HTTPS from the Bash tool — free, unmetered, and **not representable in `ops.web_calls`**, whose `provider` column admits only `tavily`/`anthropic`/`fmp`/`hf`. No row was invented for it. The consequence is worth flagging to whoever owns that table: a routine that moves work *off* a metered provider onto direct HTTP looks in the telemetry like it reduced spend, when it has actually moved off-ledger. Recorded as an `ops.alerts` info row against the owning surface rather than acted on here.

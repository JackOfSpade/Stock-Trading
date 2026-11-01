2026-11

# E Pair Divergence Screen — November 2026

**Run 2026-11-01 (M2, deep research; a Sunday — M2's cron fires on the 1st, ahead of the 2026-11-02 first trading day).** Every correlation, beta, volatility and spread below was re-measured this session from IBKR regular-session daily closes. Nothing is carried over from the October edition. The catch-up evidence window resolved to 30.98 days (`state.routine_catchup_window`, back to M2's own last completed run at 2026-10-01 13:34 UTC). That is cadence-normal and single-period, so no missed-period sub-sections are owed.

## Activation state — fundamental DO-NOT-ACTIVATE; technical gate now passes

- **Binding state: `DO-NOT-ACTIVATE`**, most recently re-affirmed by divergence review `div-E-202610-1` (resolved 2026-10-22, `events.regime_events` 4396bd01… scope `STRATEGY_ACTIVATION`, key `E`, theater MIXED). **This morning's M1b (2026-11) keeps the raw fundamental call at DO-NOT-ACTIVATE**, on within-group common factors: the AI-capex selloff, the oil shock (`shock_overlay = acute`, Brent peak 116.72 on 10-23, structure still open) and a hawkish rate path. The Shock Transmission Register shows E as `SPREAD`, `override_applies = TRUE` (`binds: class SPREAD`, Rev 53), so an ACTIVATE would have been overridden anyway.
- **The technical gate now PASSES.** SPY Trend UP (769.36 > SMA50 767.63 > SMA200 728.53), VIX NORMAL (17.20) and Breadth HEALTHY (63.81%, as of 2026-10-29). In October breadth was WEAK at 40.55 and the gate failed. M1b records **Divergence: YES** (Tech ACTIVATE / Fund DO-NOT-ACTIVATE).
- **What happened to October's shortlist.** M4 2026-10-02 enqueued MCHP/ADI, MDB/SNOW and CB/TRV. D2 declined all three on 2026-10-04 on the item conservative_default (router-gate limb), not on the merits. MTZ/PWR was REST watch-grade and was not enqueued. None entered.

**Consequence.** PART 2 is research feedstock for M4 and the next divergence review, not a queue to drain into orders. All pair dispositions were set **before** the activation state was read, and none depends on it.

## This screen's own measurement for the Shock Transmission Register (Rev 50)

Over the **63-pair spec-floor population** (252d corr ≥ 0.50, in population, PART 1A), the trailing-60-day log-return correlation has **median 0.6937**, and **16 of 63 (0.254)** pairs sit at ≥ 0.80. Measured as of the 2026-10-30 close. In 35 of 63 pairs the 60d correlation is above the 252d one. That is in the same direction as August's 66 of 89 and still a majority, but narrower. These four figures are logged as `e_corr_median_60d` / `e_corr_share_60d_ge_080` / `e_corr_population_n` / `e_corr_as_of` on this screen's research-screen row for `state.shock_transmission_status`. Rev 53 currently leaves E's breaker gate thresholds undefined (`gate_defined = FALSE`), so the figures are published but trip nothing.

## Cross-strategy conflicts and the E book

**Strategy E's own book is empty.** `state.current_positions` holds 12 open positions, all Strategy D (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER), the same as in October. The "either leg in the open E book" exclusion therefore removes nothing. **GEV remains open long in D**, so **VRT/GEV** (0.6351) stays recorded and not advanced.

## Structurally invalid or compromised pairs

**Permanently excluded (unchanged):** SYF/DFS, SPR/HWM, JNPR/ANET, EA/TTWO. None was re-probed.

**New this cycle: three legs no longer exist as listed common stock, and one pair is removed from the universe.**

| Leg / pair | What was found (public sources) | Disposition |
|---|---|---|
| **QRVO** (QRVO/SWKS) | The Skyworks–Qorvo merger **closed 2026-10-05** ($32.50 cash + 0.960 SWKS per QRVO share; Qorvo 8-K seen via search result, not opened). IBKR returns only a `VALUE`-exchange row and "Details currently unavailable" for history. | **Permanently excluded.** The pair is now one company. |
| **WBD** (WBD/NFLX) | **Acquired and delisted 2026-10-06** by "Skydance Corporation (formerly Paramount Skydance Corporation, 'SKYD')" at $31.0167 cash (WBD 8-K, accession 0001193125-26-415055, opened). No US STK row on IBKR. | **Permanently excluded.** |
| **PSKY** (PSKY/FOXA) | `search_contracts("PSKY")` returns nothing. The WBD 8-K names the acquirer as "formerly Paramount Skydance", ticker **SKYD**, so a rename at closing is indicated. Not independently confirmed. | **Not measured.** FOXA/SKYD would be a post-merger company with a structurally changed business. The pair was below the 0.30 rail last cycle (0.2153). Re-admission requires a fresh SKYD contract and ≥ 252 post-merger sessions. |
| **TMUS/CMCSA** | Not the same GICS industry group (501020 vs 502010), as flagged in October. | **Removed from the universe** this cycle, as October recommended. |
| **WDAY** (WDAY/NOW) | The Silver Lake take-private is **still an unconfirmed report** (Reuters 2026-08-13). Workday held its 2026-10-13 analyst day as a standalone company, and the CEO said publicly that he "did not come back to sell" ("never say never"). Nothing has been signed and nothing abandoned. | **Rejected (structural), unchanged.** It matters this month: NOW fell ~27% on 2026-10-29, so WDAY would now be the SHORT leg, carrying an undated take-private bid. |
| **KMB** (KMB/PG) | The Kenvue transaction is **still pending**. The EC cleared it 2026-10-13 with an EEA feminine-care divestiture, and Brazil and Australia cleared by 10-20. Closing is guided Q4 2026. (Secondary sources; no issuer release opened.) | Rejected (structural), unchanged. |
| **IP** (IP/PKG) | International Paper is planning to separate EMEA (DS Smith) by spin or sale, with a DS Smith capital-markets day on 2026-11-03 (per snippets). It also took a $1.38B EMEA goodwill impairment in Q3. | **Newly flagged.** The IP leg is contaminated by a pending separation, so the pair is not advanced. |

---

# PART 1 — measured population

All figures were measured this session from **IBKR regular-session daily closes** (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`, `step_count=253`, the `close` array). That gives **253 bars per ticker, 2025-10-29 → 2026-10-30, and 252 aligned daily log returns per pair**, so the trailing-252-day spec is met exactly this cycle. October's feed ceiling of 249/251 returns did not recur with `step_count=253`. FITB is the one exception at 251 returns (see Data integrity). Pearson correlation is on log returns. Beta is the OLS slope of A's returns on B's. Vol is annualised ×√252. **1M = 2026-09-30 → 2026-10-30**, anchored to the October screen's last close. **3M = 2026-07-31 → 2026-10-30.** Spread = A's total return minus B's, in percentage points. **167 tickers and 87 pairs were measured.** The universe is October's 91 pairs, minus TMUS/CMCSA (removed) and the three pairs with a vanished leg (QRVO/SWKS, WBD/NFLX, PSKY/FOXA). Six research workers pulled the bars.

**Layer-1 population rail (mechanical, a cost bound):** same 6-digit GICS industry, 252-day correlation ≥ 0.30, large-cap with adequate ADV, and both legs reported earnings or filed a 10-Q/10-K within 90 days (on or after **2026-08-03**).
**Spec floor (mechanical, derived from Strategy E's spec_hash-frozen Entry criterion 3):** 252-day correlation ≥ 0.50 to be eligible to advance.

**Population this cycle: 81 pairs clear the rail.** Of these, 63 are above the spec floor and 18 sit in the 0.30–0.49 context band. **Out of population:** 5 pairs on the 90-day recency gate (PART 1C) and FITB/HBAN, withheld on data quality (PART 1D). **No measured pair falls below the 0.30 rail on correlation alone.** DELL/STX (0.3044), PCG/NEE (0.3068) and ILMN/DHR (0.3191) all moved up into the band. LYV/SPOT (0.1640) is below the rail but is listed under the gate.

**Crossings of the 0.50 floor since October** (none is rounded):
- **Up:** **AMD/NVDA 0.5345** (after five consecutive months below), GILD/AMGN 0.5243, TXT/GD 0.5025, and CVS/CI 0.5222. CVS/CI is out of population on CI's recency gate.
- **Down:** none.
- **Hedge breakdown inside the eligible set:** **LII/TT** 60d 0.1235 and **CMI/PCAR** 60d 0.2745 are both below E's own 0.3 correlation-breakdown exit. Either would be exited on day one, so neither is advanceable whatever its 252d reads.

## The 90-day recency gate — SEC EDGAR primary filings, 166 of 170 resolved

The gate ran on **SEC EDGAR's submissions API**. For each ticker the date taken is the later of its latest 10-Q/10-K and its latest 8-K carrying **Item 2.02**. All 167 measured tickers plus the 3 vanished ones were checked (168 HTTPS requests, off-ledger). **Result: 160 PASS, 6 FAIL, 4 UNRESOLVED.**

- **The 6 FAILs were re-verified directly by the orchestrator against EDGAR this session.** In each case the latest Item 2.02 8-K and 10-Q fall before the 2026-08-03 cutoff, and no newer one exists: **SWKS 07-28, VRSK 07-29, SWK 07-29, LYV 07-30, CI 07-30, BEN 07-31.** These are timing failures, not defects. All six report Q3 in early November, so all are expected back in population in December. The cost this cycle: **CVS/CI** (now 0.5222, above the floor for the first time), **EFX/VRSK**, **SWK/ITW**, **BEN/TROW** and LYV/SPOT drop out.
- **UNRESOLVED:** QRVO, WBD and PSKY are absent from `company_tickers.json` (structural, above). **SPOT** is still a foreign private issuer (6-K 2026-10-22, no 10-Q). Nothing turns on it, because LYV fails the gate and the pair is below the rail.
- **Closest PASSes:** MAR and ON, both exactly on the cutoff (2026-08-03), then J and PFE (08-04).

## Data integrity — five checks, all on the full population

1. **Swap detector** (no two tickers may share a close series): **CLEAN**, run across all 167.
2. **Frozen-print detector** (≥3 identical consecutive closes): one hit, the known one. **FITB again returns 53.42 for the 2026-06-12 → 06-22 run and is missing the 2026-06-11 bar** (its series starts one session earlier to compensate, giving 251 aligned returns). This is the same value, same run and same dates for the third consecutive pull. **FITB/HBAN stays withheld on data quality, not thesis.** It would otherwise be the sixth-highest correlation in the population (0.8667).
3. **Independent re-pull transcription audit.** 24 randomly chosen tickers were re-pulled by a separate worker using a different request (`period=ONE_YEAR`). 23 resolved (QRVO is gone). The re-pulls were compared close by close over 251 overlapping sessions each: **0 mismatches across 5,773 closes, and contract IDs identical.**
4. **NEW — population-wide cross-edition anchor check.** Every one of the **167** tickers' 2026-09-30 close in this pull was compared against the `Last` closes the October edition recorded from its own independent pull. **167 of 167 match.** Together with check 3, this matters because three of the six bar workers transcribed arrays from tool output rather than writing them programmatically, and one caught and fixed its own volume copy slip (KBH). Volume feeds only the ADV column, never a correlation.
5. **Single-day jumps > 25%.** Eight hits.
   - **Six are October's known event dates, reproduced exactly:** SNOW +36.5% (2026-05-28), MRVL +32.5% (06-02), DELL +32.8% (05-29), DY +25.8% (05-27), NXPI +25.5% (04-29), MOH −25.5% (02-06).
   - **Two are new and are real October prints:** **NOW −26.9% on 2026-10-29** (Q3, 53.1M shares) and **INTC −28.6% on 2026-10-30** (~310M shares).
   - FDX, BDX and KLAC carry back-adjusted histories (spin/split adjustments). Returns are valid.

## PART 1A — ABOVE the 0.50 spec floor (63 pairs, eligible to advance)

### Technology

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 452020 Tech Hardware | WDC/STX | 0.8830 | 0.9267 | 0.9576 | 80.29% | 74.04% | 10.67 | -8.09 | 366.11 | 644.58 |
| 453010 Semi Equip | LRCX/KLAC | 0.8757 | 0.8903 | 0.9331 | 65.5% | 61.46% | -8.22 | -4.77 | 239.11 | 157.91 |
| 451030 Software | PANW/CRWD | 0.8559 | 0.9147 | 0.7657 | 49.49% | 55.33% | -2.5 | -20.95 | 365.87 | 250.43 |
| 453010 Semis | MCHP/ADI | 0.8028 | 0.7741 | 1.0862 | 49.37% | 36.49% | -5.7 | -9.42 | 77.34 | 417.11 |
| 453010 Semi Equip | TER/AMAT | 0.7668 | 0.7280 | 0.9653 | 76.31% | 60.61% | -7.85 | -2.22 | 274.37 | 390.09 |
| 453010 Semis | ON/NXPI | 0.7255 | 0.7380 | 0.9638 | 63.48% | 47.79% | -16.06 | -25.47 | 71.67 | 259.61 |
| 451030 Software | WDAY/NOW | 0.6947 | 0.4564 | 0.5618 | 53.52% | 66.18% | 25.42 | 28.87 | 197.82 | 105.12 |
| 451030 Software | FTNT/CRWD | 0.6805 | 0.6690 | 0.5966 | 48.5% | 55.33% | -18.47 | -47.19 | 136.08 | 250.43 |
| 451030 Software | MDB/SNOW | 0.6158 | 0.5941 | 0.7085 | 72.74% | 63.22% | 11.11 | 0.22 | 352.96 | 306.08 |
| 453010 Semis | AMD/NVDA | 0.5345 | 0.5467 | 0.9851 | 68.55% | 37.19% | -7.09 | 4.08 | 504.8 | 204.64 |
| 453010 Semis | MRVL/AVGO | 0.5276 | 0.4822 | 0.9139 | 80.21% | 46.31% | -18.52 | 20.95 | 196.4 | 326.08 |

### Financials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | USB/PNC | 0.8836 | 0.8938 | 0.9278 | 22.14% | 21.08% | 0.41 | 3.16 | 59.45 | 227.86 |
| 401010 Banks | RF/KEY | 0.8695 | 0.9080 | 0.8806 | 23.08% | 22.79% | 1.06 | -1.18 | 28.57 | 21.12 |
| 401010 Banks | TFC/MTB | 0.8482 | 0.8384 | 0.9390 | 23.36% | 21.1% | 3.94 | 4.5 | 48.79 | 220.72 |
| 402030 Capital Markets | STT/BNY | 0.8012 | 0.8356 | 0.8906 | 24.06% | 21.65% | -4.48 | -1.92 | 169.77 | 147.11 |
| 402020 Consumer Finance | COF/AXP | 0.7666 | 0.6991 | 0.9280 | 31.33% | 25.88% | 1.17 | 3.11 | 204.85 | 319.11 |
| 403010 Insurance | TRV/CB | 0.7304 | 0.7755 | 0.7755 | 20.44% | 19.25% | -0.81 | 2.01 | 396.22 | 364.12 |
| 403010 Insurance | ALL/PGR | 0.7088 | 0.6293 | 0.6588 | 25.44% | 27.38% | 5.57 | -10.99 | 259.87 | 231.28 |
| 403010 Insurance | MET/PRU | 0.6931 | 0.7622 | 0.7290 | 23.77% | 22.6% | 3.7 | 8.66 | 100.02 | 116.45 |
| 401010 Banks | WFC/C | 0.6748 | 0.6922 | 0.5895 | 25.58% | 29.28% | 9.47 | 3.88 | 83.4 | 122.64 |
| 402010 Capital Markets | RJF/LPLA | 0.6554 | 0.4706 | 0.4087 | 25.1% | 40.25% | 6.71 | 9.12 | 157.22 | 283.74 |
| 403010 Insurance | AIG/HIG | 0.5166 | 0.6265 | 0.6167 | 23.8% | 19.94% | 1.69 | 10.79 | 81.9 | 132.59 |

### Energy/Materials/Utilities

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 151010 Chemicals | DOW/LYB | 0.8989 | 0.8856 | 0.8745 | 41.59% | 42.75% | 6.56 | 3.99 | 34.7 | 68.64 |
| 101020 E&P | DVN/EOG | 0.8562 | 0.8746 | 1.0075 | 34.26% | 29.12% | -6.89 | 4.22 | 52.15 | 165.54 |
| 101020 E&P | APA/FANG | 0.7968 | 0.8162 | 1.0775 | 44.18% | 32.67% | 11.77 | 37.03 | 52.82 | 212.08 |
| 551010 Utilities | EXC/AEP | 0.7566 | 0.8493 | 0.8249 | 20.12% | 18.45% | 4.51 | -1.1 | 46.16 | 130.21 |
| 101010 Energy Equip | HAL/SLB | 0.7444 | 0.8110 | 0.6631 | 32.38% | 36.35% | 3.44 | 3.79 | 36.17 | 53.74 |
| 151010 Chemicals | PPG/SHW | 0.7238 | 0.5767 | 0.7996 | 30.21% | 27.35% | 11.67 | 10.56 | 119.52 | 332.61 |
| 151030 Packaging | IP/PKG | 0.7197 | 0.6034 | 1.1617 | 44.5% | 27.57% | -2.37 | -15.39 | 36.37 | 256.82 |
| 101010 Energy Equip | HAL/BKR | 0.6015 | 0.5780 | 0.5710 | 32.38% | 34.11% | 13.14 | 20.85 | 36.17 | 55.23 |
| 151040 Metals | CLF/NUE | 0.5951 | 0.6486 | 1.2687 | 66.42% | 31.16% | 12.26 | 17.25 | 14.25 | 273.87 |
| 151010 Chemicals | EMN/CE | 0.5785 | 0.4632 | 0.3608 | 31.77% | 50.94% | -8.5 | -15.13 | 66.53 | 49.3 |

### Consumer

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 252010 Homebuilders | KBH/DHI | 0.8588 | 0.8924 | 0.9502 | 39.04% | 35.29% | -3.68 | -14.84 | 47.94 | 146.0 |
| 302020 Food | CAG/GIS | 0.8219 | 0.8743 | 0.8689 | 31.72% | 30.0% | 1.78 | 4.5 | 14.57 | 34.29 |
| 253020 Hotels | H/MAR | 0.7288 | 0.6962 | 0.9336 | 34.47% | 26.91% | 1.61 | -3.36 | 180.57 | 399.3 |
| 252010 Homebuilders | TOL/NVR | 0.7129 | 0.7573 | 0.8644 | 34.1% | 28.12% | 11.49 | 3.11 | 145.95 | 5958.56 |
| 255030 Broadline Retail | DLTR/DG | 0.6351 | 0.6654 | 0.6846 | 40.87% | 37.92% | 6.77 | 1.1 | 133.87 | 132.3 |
| 251020 Automobiles | F/GM | 0.5900 | 0.6279 | 0.6306 | 35.57% | 33.28% | -11.93 | -14.91 | 12.25 | 87.4 |
| 255040 Specialty Retail | ROST/TJX | 0.5866 | 0.4889 | 0.7165 | 26.11% | 21.38% | -8.24 | 1.75 | 228.28 | 140.31 |
| 303010 Household Prod | CLX/CHD | 0.5776 | 0.5656 | 0.8129 | 32.15% | 22.84% | -5.18 | -16.4 | 88.0 | 107.23 |
| 303010 Household Prod | KMB/PG | 0.5592 | 0.6757 | 0.7845 | 29.06% | 20.72% | -0.43 | -13.07 | 107.94 | 161.57 |

### Industrials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 202020 Prof Services | EFX/TRU | 0.8640 | 0.8741 | 0.8388 | 41.06% | 42.29% | 8.87 | 9.27 | 184.6 | 76.79 |
| 203020 Airlines | AAL/DAL | 0.8474 | 0.8547 | 1.0308 | 46.52% | 38.24% | -1.79 | -9.15 | 12.6 | 80.15 |
| 203040 Ground Transport | XPO/ODFL | 0.7401 | 0.7322 | 0.8140 | 41.96% | 38.14% | 8.46 | 12.99 | 189.57 | 172.56 |
| 201010 Aero&Defense | NOC/LMT | 0.7147 | 0.7427 | 0.6802 | 28.43% | 29.87% | -9.76 | -6.53 | 557.54 | 636.95 |
| 201040 Electrical Equip | VRT/NVT | 0.7124 | 0.7865 | 0.9459 | 67.36% | 50.73% | 17.79 | 14.35 | 232.5 | 125.98 |
| 201030 Constr&Eng | MTZ/PWR | 0.7101 | 0.6191 | 0.8403 | 53.01% | 44.8% | -9.51 | -22.29 | 186.06 | 620.73 |
| 203010 Air Freight | FDX/UPS | 0.6644 | 0.6936 | 0.6228 | 28.16% | 30.04% | -5.96 | -1.95 | 313.28 | 108.25 |
| 201060 Machinery | DOV/IR | 0.6571 | 0.6599 | 0.4883 | 24.73% | 33.28% | 4.48 | 5.52 | 207.74 | 80.05 |
| 201040 Electrical Equip | VRT/GEV | 0.6351 | 0.6483 | 0.8003 | 67.36% | 53.45% | 6.09 | 9.62 | 232.5 | 857.87 |
| 201040 Electrical Equip | HUBB/NVT | 0.6259 | 0.6166 | 0.3948 | 32.0% | 50.73% | 14.57 | 7.5 | 422.44 | 125.98 |
| 201030 Constr&Eng | ACM/J | 0.5915 | 0.5535 | 0.6864 | 38.1% | 32.83% | -6.86 | -27.09 | 63.34 | 154.62 |
| 201040 Electrical Equip | VRT/HUBB | 0.5819 | 0.5267 | 1.2250 | 67.36% | 32.0% | 3.22 | 6.85 | 232.5 | 422.44 |
| 201030 Constr&Eng | DY/EME | 0.5615 | 0.5575 | 0.6595 | 52.79% | 44.95% | -5.45 | -28.44 | 227.7 | 679.55 |
| 201020 Bldg Products | LII/TT | 0.5304 | 0.1235 | 0.7558 | 42.46% | 29.8% | 6.21 | -7.38 | 344.08 | 410.0 |
| 201060 Machinery | CMI/PCAR | 0.5059 | 0.2745 | 0.6910 | 36.45% | 26.69% | 4.0 | 2.04 | 500.09 | 101.91 |
| 201010 Aero&Defense | TXT/GD | 0.5025 | 0.7131 | 0.6401 | 28.61% | 22.46% | 0.18 | 3.34 | 85.7 | 372.59 |

### Health Care

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 351020 HCDistributors | COR/MCK | 0.7108 | 0.7989 | 0.7535 | 32.26% | 30.44% | -6.3 | -9.9 | 330.84 | 994.58 |
| 352030 Life Sci Tools | RVTY/TMO | 0.6947 | 0.6937 | 0.9249 | 38.81% | 29.15% | -0.56 | 18.17 | 157.0 | 697.0 |
| 351020 Managed Care | ELV/UNH | 0.6715 | 0.5041 | 0.6693 | 35.59% | 35.71% | -2.83 | 13.56 | 420.07 | 406.97 |
| 351020 Managed Care | CNC/MOH | 0.5754 | 0.7992 | 0.5025 | 45.77% | 52.4% | 1.9 | 5.33 | 68.45 | 204.78 |
| 351010 HCEquipment | ZBH/SYK | 0.5359 | 0.7453 | 0.5773 | 33.52% | 31.12% | 0.42 | 11.02 | 94.52 | 291.86 |
| 352010 Biotech | GILD/AMGN | 0.5243 | 0.6777 | 0.4789 | 26.98% | 29.54% | 3.95 | 10.09 | 170.68 | 466.01 |

## PART 1B — 0.30–0.49 band, BELOW the spec floor (18 pairs) — context / SL1 ideation only

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 255040 Specialty Retail | AAP/ORLY | 0.4952 | 0.4614 | 1.1116 | 58.35% | 26.0% | 12.76 | -17.4 | 45.11 | 88.12 |
| 201020 Bldg Products | MAS/CARR | 0.4846 | 0.4071 | 0.4880 | 35.37% | 35.12% | 21.89 | 26.05 | 80.64 | 53.63 |
| 351010 HCEquipment | BAX/BDX | 0.4804 | 0.3143 | 0.8384 | 44.67% | 25.59% | -14.71 | -31.56 | 23.0 | 197.88 |
| 352010 Biotech | BIIB/VRTX | 0.4762 | 0.4911 | 0.5586 | 34.06% | 29.04% | 5.38 | 7.83 | 253.62 | 558.88 |
| 452020 Tech Hardware | HPQ/DELL | 0.4570 | 0.3036 | 0.2858 | 46.5% | 74.35% | 13.13 | 0.87 | 28.78 | 424.3 |
| 351010 HCEquipment | MDT/BSX | 0.4570 | 0.4305 | 0.2817 | 24.6% | 39.91% | 15.7 | 23.22 | 96.54 | 41.98 |
| 453010 Semis | INTC/TXN | 0.4523 | 0.4531 | 0.9114 | 83.7% | 41.54% | -52.71 | -36.2 | 65.76 | 300.84 |
| 352020 Pharma | BMY/MRK | 0.4522 | 0.5118 | 0.4297 | 28.18% | 29.66% | -2.77 | -19.17 | 62.48 | 149.52 |
| 352020 Pharma | PFE/LLY | 0.4420 | 0.6287 | 0.2713 | 21.63% | 35.24% | -15.5 | -1.36 | 30.52 | 1417.54 |
| 201060 Machinery | CR/ITW | 0.4391 | 0.3112 | 0.7001 | 33.72% | 21.15% | -11.21 | -4.31 | 198.02 | 278.55 |
| 302010 Beverages | KDP/MNST | 0.4065 | 0.5290 | 0.3981 | 25.55% | 26.09% | 4.38 | 16.93 | 35.84 | 47.34 |
| 351010 HCEquipment | PODD/DXCM | 0.4031 | 0.4468 | 0.4637 | 46.39% | 40.33% | 19.36 | -8.09 | 149.68 | 82.29 |
| 402030 Capital Markets | NDAQ/CME | 0.3540 | 0.5261 | 0.3997 | 28.34% | 25.1% | -0.26 | -0.42 | 106.23 | 303.14 |
| 253020 Restaurants | SBUX/CMG | 0.3400 | 0.3059 | 0.2083 | 27.41% | 44.75% | 10.52 | 12.82 | 103.67 | 31.89 |
| 253020 Restaurants | YUM/QSR | 0.3346 | 0.6067 | 0.3407 | 24.65% | 24.21% | 12.11 | 3.56 | 155.4 | 72.41 |
| 352030 Life Sci Tools | ILMN/DHR | 0.3191 | 0.5803 | 0.5554 | 52.56% | 30.2% | -18.59 | -4.04 | 235.99 | 232.23 |
| 551010 Utilities | PCG/NEE | 0.3068 | 0.1400 | 0.5292 | 36.02% | 20.88% | -2.93 | -20.47 | 13.18 | 83.71 |
| 452020 Tech Hardware | DELL/STX | 0.3044 | 0.2949 | 0.3056 | 74.35% | 74.04% | 8.99 | 29.38 | 424.3 | 644.58 |

## PART 1C — OUT OF POPULATION on the 90-day recency gate (5 pairs; measured, shown for continuity)

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 201060 Machinery | SWK/ITW | 0.6198 | 0.4994 | 1.0617 | 36.23% | 21.15% | 8.5 | 12.3 | 103.44 | 278.55 |
| 202020 Prof Services | EFX/VRSK | 0.5228 | 0.5947 | 0.6045 | 41.06% | 35.51% | 17.56 | 6.2 | 184.6 | 196.3 |
| 351020 Managed Care | CVS/CI | 0.5222 | 0.7103 | 0.4976 | 31.79% | 33.36% | -4.39 | -20.45 | 90.25 | 298.23 |
| 402030 Capital Markets | BEN/TROW | 0.5209 | 0.5504 | 0.5970 | 27.45% | 23.95% | -1.35 | 0.47 | 31.64 | 103.9 |
| 502020 Media | LYV/SPOT | 0.1640 | 0.3457 | 0.1087 | 30.82% | 46.52% | -16.69 | -16.54 | 177.89 | 593.44 |

## PART 1D — measured but WITHHELD on data quality (1 pair)

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | FITB/HBAN | 0.8667 | 0.8747 | 0.8260 | 24.75% | 25.97% | 3.1 | 2.74 | 53.87 | 15.78 |

## PART 1B notes — the three sub-floor pairs recorded

Per §19 the 0.50 bar **derives from** Strategy E's spec_hash-frozen Entry criterion 3 and is not a screen tune. Sub-floor pairs are recorded `below_spec_floor=true` as SL1 ideation evidence only and are **never** entry candidates. The cap is 3 per call, and these are the same three pairs as the fields-JSON `passed` items.

| Pair | 252d | 60d | Why it is recorded |
|---|---|---|---|
| **AAP/ORLY** (255040) | **0.4952** | 0.4614 | **Closest miss in the population.** It misses by 0.0048 and is not rounded up. Its fourth consecutive reading within 0.01 of the floor (0.499 in August, 0.4772, 0.4911, now 0.4952). AAP +12.8pp 1M against −17.4pp 3M. |
| **BAX/BDX** (351010) | **0.4804** | 0.3143 | **Second cycle recorded.** The hedge is decaying toward E's 0.3 breakdown line (60d 0.46 → 0.31), while the spread blew out to **−31.6pp 3M / −14.7pp 1M** against BAX. A divergence on a dissolving hedge is the exact shape E's correlation rule exists to refuse. |
| **INTC/TXN** (453010) | **0.4523** | 0.4531 | **The largest single-month divergence measured anywhere: −52.7pp 1M.** INTC fell 28.6% on 2026-10-30 on ~310M shares. That is a single-name event on a sub-floor pair, recorded as SL1 evidence of the AI-capex/foundry factor cutting through a GICS group, and nothing more. |

## PART 1E — reconciliation of the 2026-10-01 shortlist

| Prior pair | Prior tier | Status | Reason (public information only) |
|---|---|---|---|
| **MCHP/ADI** (0.8028) | TOP-3 #1 | **KEEP — TOP-3 #1** | The spread kept widening without a laggard-specific cause: −5.70pp 1M, −9.42pp 3M (October measured −14.61pp 3M on a June base). The decisive event is now days away (MCHP FQ2, **2026-11-05**). See PART 2 §1. |
| **MDB/SNOW** (0.6158) | TOP-3 #2 | **DROP — realised on price** | The October thesis targeted only the 09-28 CEO-departure increment. **The spread reversed +11.11pp in MDB's favour in October**, and the 3M gap is now **+0.22pp**. MDB 348.61 → 352.96 and SNOW 339.56 → 306.08. No permanent CEO had been named in the sources found (interim Ittycheria; guidance reaffirmed). Nothing is left to harvest at the pair level. |
| **CB/TRV** (TRV/CB 0.7304) | TOP-3 #3 | **DROP — resolved against the thesis** | The thesis was that TRV's Q3 would show the late-September nor'easter. **TRV's Q3 (8-K, 2026-10-16) was a large beat**: core EPS $9.18 against $8.14 a year earlier and ~$7.1–7.4 consensus, with cat losses of $538M, mainly wind/hail. The release does not mention a nor'easter, and $234M of favourable reserve development helped. **CB (8-K 10-20, call 10-21) took the larger cat hit** ($705M against $285M) on core EPS $7.66 (+0.8%). The storm mechanism did not show up. October's prominent caveat ("nothing about the storm may be relied on until the 10-16 print") was the correct one, and the pair is declined at that print as October pre-committed. |
| **MTZ/PWR** (0.7101) | REST (watch) | **DROP — earned** | Both reported 2026-10-29 (8-Ks opened). **PWR**: revenue $12.01B, adj-EPS $6.06, record $63.7B backlog, FY guide **raised** to $17.90–18.30. **MTZ**: adj-EPS $2.96 against its own $2.98 guide, record $24.5B backlog, but Pipeline EBITDA −18% and Communications EBITDA −48%, FY EBITDA ~flat, and Pipeline starts slipping into 2027. The −9.51pp 1M / −22.29pp 3M widening is earned by the print. The short leg just raised guidance, and no dated catalyst lands before ~February 2027. |

---

# PART 2 — Ranked shortlist of divergence theses (public-information-only)

**How this ranking was produced.** October's four pairs were reconciled against dated public evidence (PART 1E). Eighteen further pairs were researched from public sources by five research workers: the largest 1M/3M spreads in the eligible population, the four new floor-crossers, and two prior rejects whose spread moved materially. In total the workers made **78 metered calls (57 web_search, 12 web_fetch, 9 Tavily basic search)** plus 24 off-ledger SEC EDGAR requests. **This is a Q3-earnings month, so most legs had already printed by 2026-10-31.** That produced unusually decisive evidence, and it ran overwhelmingly one way: **most measured divergences this cycle are EARNED, closed by prints that moved fundamentals.** Short-interest/borrow data was **not retrievable for any short leg**. Several stock-reaction and consensus figures are aggregator-sourced and flagged as such.

**Tier coding.** TOP-3 = highest priority for M4. REST = advanced with a stated caveat. **One pair advances this cycle.** The shortlist is shorter than October's because the evidence is better, not because the screen tightened. The "up to 10" cap is a ceiling, and nothing else cleared the narrative-over-fundamental bar.

### 1) Long MCHP / Short ADI — Semiconductors (453010) — **TOP-3 #1 (carry-forward, third consecutive cycle)**
- **(a) L/S.** **ADI = leader/short** (417.11). **MCHP = laggard/long** (77.34). Both are analog/mixed-signal on the same industrial/auto/data-center upcycle.
- **(b) Divergence thesis.** Corr **0.8028**, 60d **0.7741**, still the best hedge among researched candidates, though it eased from 0.8259. Beta 1.0855; vols 49.4% / 36.5%, so beta-adjusted sizing is required. Spread **−5.70pp 1M, −9.42pp 3M**. Neither company has reported since August:
  - **MCHP FQ1** (2026-08-06, issuer exhibit 99.1 opened): sales +38% y/y, non-GAAP EPS $0.76 against a $0.67–0.71 guide, book-to-bill "well above 1". FQ2 guide **$1.589–1.618B revenue, 66–67% GM**.
  - **ADI FQ3** (2026-08-19, exhibit opened): a record $4.02B (+40%), Q4 guide $4.3B.
  - **No MCHP-specific negative event and no October analyst action on either leg was found.** The widening is consistent with sentiment and beta (the October AI-capex/semis selloff hit the higher-vol leg harder) rather than fundamentals. That is the narrative-outpacing-fundamental shape. It is **inferred from the absence of a found driver, not measured.**
- **(c) Reconvergence indicators.** (i) **MCHP FQ2 FY27 — 2026-11-05, 5pm ET**, from Microchip's IR events calendar entry seen in a search result; the page itself was not opened, so the date is *near*-issuer-confirmed. The direct test: delivery against the $1.589–1.618B / 66–67% GM guide, plus FQ3 guide and inventory-day commentary. (ii) **ADI FQ4 — ESTIMATE ~2026-11-24.** (iii) Qualitative book-to-bill/channel language from both. Neither discloses a numeric book-to-bill, so this is directional only.
- **(d) Borrow/cost fit.** No short-interest data was retrieved. ADI is a ~$613M/day (30-day $ADV) mega-cap with no evidence of special borrow, so GC is presumed (ESTIMATE, re-quote at execution). At GC over a 1–6 month hold, financing is ~0.1–0.25% of notional, far inside criterion 5's 15%-of-expected-return ceiling.
- **(e) Execution.** Individual stocks on both legs. 30-day $ADV: MCHP ~$279M, ADI ~$613M.
- **(f) Tier: TOP-3 #1, conviction 45.** **Honest risk:**
  - The 11-05 print is a **binary event on the long leg**, with no S-leg catalyst for ~3 weeks after it. An entry staged ahead of 11-05 is a directional MCHP earnings bet in pair clothing.
  - **M4/D2 should treat 11-05 as the decision point, not the entry point.** If MCHP meets or beats its guide and the spread does not close, the thesis strengthens. A guide miss would make the divergence earned and decline the pair.
  - ADI's structurally higher margin (72.5% GM) and AI-data-center mix justify part of its premium.
  - This is the pair's third cycle on the shortlist, and the September "half-realised" reconvergence proved temporary.

---

## Considered and NOT advanced (researched this cycle)

| Pair | 252d | Why not |
|---|---|---|
| **FTNT/CRWD** (451030) | 0.6805 | **Earned.** FTNT Q3 (10-28): revenue $2.08B, +20% (from +26%); product growth +37% from +52%; **FY services guide cut** to $5.15–5.17B. The stock fell ~20–23% on 10-29 after a ~132% YTD run. BofA downgraded to Neutral (PT $220 → $140) on demand pull-forward, and Jefferies cut its PT to $145. Estimate cuts are still coming. Biggest eligible 3M spread (−47.2pp), with no narrative component found. |
| **WDAY/NOW** (451030) | 0.6947 | **Narrative, but structurally unfit.** NOW Q3 (10-28) beat on subscription revenue ($3.99B) and raised its FY subscription guide. Q4 cRPO was guided at 18.5% (a slowdown). The stock's **record ~27% one-day drop** after a ~60% run reads as AI-disruption narrative more than fundamentals. That would make NOW the long and **WDAY the short**, and WDAY carries the unconfirmed Silver Lake take-private (above). The 60d hedge has also collapsed to **0.4564**. Rejected on structure. Re-open if the WDAY bid is formally abandoned or signed. |
| **ON/NXPI** (453010) | 0.7255 | **Partly earned; event-pending.** ON amended its pending **Synaptics** acquisition to **$123/share cash (~$5.7B)** after an unsolicited third-party bid (8-K 2026-10-01, opened), with Morgan Stanley debt financing and a mid-2027 close. That leverage and dilution explain much of the −25.5pp 3M lag. NXPI (8-K 10-27) guided Q4 slightly below consensus. **ON reports 2026-11-02 after close** (onsemi release via wire copies). Revisit next cycle. A pending leveraged acquisition on the long leg is not a clean narrative gap. |
| **MRVL/AVGO** (453010) | 0.5276 | **Rumour-driven.** MRVL fell ~13% intraday on 10-29 on reports of "advanced talks" to acquire Lumentum (unnamed sources, no price or financing). This is acquirer-discount risk on a rumour, which E's public-provenance rule cannot underwrite. The −17% over 10-09..10-16 had no company news, and MRVL's 10-06 investor day raised its FY28 outlook (~$20B). The hedge is weak (60d 0.4822, below 252d). Reassess once the deal is announced or denied. |
| **AMD/NVDA** (453010) | 0.5345 (NEW above floor) | **Not a laggard on the 3M horizon** (AMD +4.08pp 3M), and the hedge is borderline. AMD's −7.09pp 1M is an AI-trade selloff with no company news (−5.7% on 10-14). **AMD reports 2026-11-03** and NVDA 2026-11-17, both issuer-announced dates seen via search. That is a binary print two sessions out. First month above the floor after five below: record and watch whether it holds. |
| **ACM/J** (201030) | 0.5915 | **Watch, not advance.** ACM's −27.1pp 3M lag traces to its FQ3 (2026-08-10): a **$337M pre-tax charge on one delayed Construction Management project** (net loss $84M), with the ex-charge adj-EPS guide ($5.90–6.10) described as maintained. A one-project charge priced as a franchise de-rating is the right shape for E. But the evidence is snippet-level, the stock-reaction figures conflict (−8.5% vs −16.7%), the FQ4 date is not issuer-announced (mid-Nov ESTIMATE), and ACM is the thinnest leg (~$36.5M/day). **Strongest candidate to advance next cycle** if the FQ4 print confirms the ex-charge guide. |
| **RVTY/TMO** (352030) | 0.6947 | **Event-pending.** TMO Q3 (8-K 10-21): adj-EPS $6.68 against $6.40 (~$0.15 tariff refunds), guide raised. **RVTY reports 2026-11-03 pre-market** (Business Wire headline seen via search). The +18.2pp 3M RVTY lead accrued in Aug–Sep (1M −0.56pp), so a short-RVTY idea rests entirely on that print. An unexplained Form 25-NSE on RVTY's EDGAR record (2026-07-20) was noted and not investigated. |
| **DY/EME** (201030) | 0.5615 | **D2's 2026-09-03 NO-GO stands, reinforced.** EME Q3 (8-K 10-29, opened): non-GAAP EPS $9.60, RPO a record $18.57B (+47%), FY EPS guide **raised** to $34.50–35.50, +$500M buyback. DY: nothing new in October; FQ3 ~11-18 (ESTIMATE). The −28.4pp 3M gap is earned by the leader. |
| **TRV/CB**, **MTZ/PWR**, **MDB/SNOW** | 0.7304 / 0.7101 / 0.6158 | October shortlist pairs, dropped. See PART 1E. |
| **PANW/CRWD** (451030) | 0.8559 | Resolved against PANW in September. No October fundamental event on either leg. The 1M spread narrowed (−2.50pp). PANW FQ1 ~11-13 (ESTIMATE). |
| **ELV/UNH** (351020) | 0.6715 | **Both beat and raised.** UNH (10-13): adj-EPS $4.69 against ~$4.12, FY ≥ $20.50, with $610M of favourable reserve development. ELV (10-21): $6.99 against ~$4.71, including a $1.85 non-operating benefit, FY ≥ $29. Its 2027 baseline is ≥ $26.75 and MA membership is shrinking. 60d 0.5041. No clean gap. |
| **KBH/DHI** (252010) | 0.8588 | **Both deteriorating; no idiosyncratic catalyst.** DHI FQ4 (10-29): EPS $2.67, a miss; orders −7%; FY27 guide below FY26. KBH last reported 09-22 (orders −12%, GM 16.5%), with FQ4 ~mid-Dec (ESTIMATE). |
| **IP/PKG** (151030) | 0.7197 | Structurally contaminated: pending EMEA/DS Smith separation, and a Q3 sales miss with a $1.38B impairment (see table above). PKG beat (adj-EPS $3.04). |
| **CLX/CHD** (303010) | 0.5776 | Earned, after April's guide cut. **CLX reports Q1 FY27 2026-11-02** (consensus ~$1.07), with management flagging a slow quarter on Kingsford timing. Revisit. |
| **F/GM** (251020) | 0.5900 | Both printed. GM (10-20): EBIT-adj $4.1B, FY $14.5–15.5B, $20B buyback, stock ~−6% on implied Q4. Ford (~10-28): a beat, FY adj-EBIT $10.5–11B, 2027 flat. Partly earned, with no dated catalyst. |
| **PPG/SHW** (151010) | 0.7238 | Earned. SHW Q3 (10-27): adj-EPS $3.63, a miss, GM 47.8% against 49.2%. PPG: organic +5%, adj-EPS $2.25. 60d 0.5767. |
| **CLF/NUE** (151040) | 0.5951 | Earned. CLF adj-EBITDA $612M against a $575M guide, Q4 ~$715M. NUE EPS $5.80. |
| **KMB/PG** | 0.5592 | Structural (pending Kenvue). |
| **VRT/GEV** | 0.6351 | Cross-strategy: GEV is open long in the D book. |
| **LII/TT**, **CMI/PCAR** | 0.5304 / 0.5059 | 60d correlation 0.1235 / 0.2745, below E's own 0.3 breakdown exit. |
| **APA/FANG** (101020) | 0.7968 | Not re-researched. The +37.0pp 3M APA lead in an acute Middle-East oil shock is the commodity-bet-in-pair-clothing failure mode October named (international/Brent vs Permian WTI). Unchanged rejection. |

All other PART 1A pairs: no narrative-versus-fundamental divergence case was identified this cycle (spreads in the table).

---

## Tier summary and ordering

**TOP-3:** §1 MCHP/ADI (corr 0.8028; MCHP FQ2 **2026-11-05**, near-issuer-confirmed).
**REST:** none.

Total shortlist: **1 pair**, carried forward. **Three of October's four were dropped:** MDB/SNOW realised on price, CB/TRV resolved against the thesis at TRV's 10-16 print, and MTZ/PWR earned at the 10-29 prints. **Watch for December** (each has a dated print within ~2 weeks): ACM/J (AECOM FQ4 ~mid-Nov, ESTIMATE), ON/NXPI (ON 11-02), RVTY/TMO (RVTY 11-03), AMD/NVDA (AMD 11-03), CLX/CHD (CLX 11-02). WDAY/NOW is also on watch, contingent on the WDAY take-private resolving.

**Ordering for M4 by reconvergence-indicator proximity:** §1 MCHP/ADI (MCHP 2026-11-05).

**Execution disposition.** Both legs clear ADV by a wide margin. Borrow was **not verified** and must be re-quoted before sizing. What stands between this pair and a live entry is **E's binding DO-NOT-ACTIVATE**: M1b 2026-11 keeps the fundamental call, and the register would override an ACTIVATE. It is not execution, and no longer the technical gate, which now passes.

---

## Data-provenance and defect notes

- **Transcription is now cross-checked population-wide.** The 24-series independent re-pull (0 mismatches over 5,773 closes) is joined this cycle by a 167-of-167 anchor match against the October edition's independently pulled 09-30 closes. Recommended as a standing pair of checks: the anchor check is free and covers every ticker.
- **The IBKR window ceiling did not recur.** `step_count=253` returned 253 bars for every ticker except FITB, so the trailing-252-day spec is met exactly (252 returns). October's ONE_YEAR (250 bars) / partial-253 ceiling looks request-shape-dependent, not a feed property.
- **FITB's frozen-print defect is stable for a third pull**: the same 53.42, the same 2026-06-12 → 06-22 run, the same missing 2026-06-11 bar. Recorded, not resolved.
- **IBKR `search_contracts` rate limit: 30/minute (10/second).** Several workers hit it and recovered after ~60s. The contract IDs used are now in this run's bar files; carrying them forward would let next cycle skip ~170 searches. That is a suggestion for this routine, not a filed defect.
- **FMP was not used** (fourth consecutive cycle). **Tavily: 9 basic searches** this cycle, with no 429s observed.
- **SEC EDGAR recency work remains off-ledger.** It ran over direct HTTPS (198 requests: 168 by the gate worker, 6 orchestrator re-verifications, 24 by two research workers). `ops.web_calls.provider` admits no SEC value. This was referred in prior cycles and is not re-filed.
- **Research call timestamps are approximate.** The five research workers returned verbatim targets but not per-call clock times. The `ops.web_calls` rows carry approximated per-call `call_ts` (worker start + ~25s spacing, 2026-11-01 ~13:24–13:32 UTC), not measured times.
- **One worker statement corrected here:** a research worker described PANW as the 3M "outperformer". On the measured spread (A=PANW minus B=CRWD = −20.95pp 3M) PANW is the 3M laggard. The disposition is unaffected.
- **GICS labels are inherited** from prior editions and were not re-derived (no GICS connector). The TMUS/CMCSA error found last month suggests others may carry the same unverified status.
- **Screen record.** One `entry_type='research-screen'` row (screen `pair-divergence`) was logged via `ops.sp_log_decision`. It is **`events.decision_log` `67f68f9a-a4ea-489e-aa71-f57e8eb82c82`**, read back and verified: `fields` parsed, `surfaced_count` 4 = `ARRAY_LENGTH(passed)`, 63 `rejected_notable` items (62 above-floor AI rejections plus FITB/HBAN withheld), agreement both 1 / ai_only 3 / rule_only 63. It carries the four Rev 50 `e_corr_*` fields, and `state.shock_transmission_status` for E now reads it as its `measurement_entry_id` (median 0.6937, share 0.254, n 63).

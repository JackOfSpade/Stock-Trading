2026-10

# E Pair Divergence Screen — October 2026

**Run 2026-10-01 (M2, deep research). Every correlation, beta, volatility and spread below was re-measured this session from IBKR regular-session daily closes — nothing is carried over from the September edition.** The catch-up evidence window resolved to 29.95 days (`state.routine_catchup_window`, back to M2's own last completed run at 2026-09-01 14:11 UTC) — cadence-normal for a monthly routine, single-period, so no missed-period sub-sections are owed and no `CATCHUP` token is due.

## Activation state — E is BLOCKED on BOTH halves of its router this month

The September edition was written while E's binding state was still `ACTIVATE`. **That changed three days later and is still in force.**

- **Binding state: `DO-NOT-ACTIVATE` since 2026-09-04** — divergence review `div-E-202608-1` (cycle 2, theater-check DIVERGENT) converted E from ACTIVATE on the universal `shock_overlay = acute → DO-NOT-ACTIVATE` override, which fired on E for the first time. The orchestrator upheld the override on four grounds, one of them this screen's own August measurement (60d correlation above 252d in 66 of 89 pairs) read as directional evidence of rising within-industry correlation. Measured from `events.regime_events` (scope `STRATEGY_ACTIVATION`, key `E`, event_ts 2026-09-04 01:03 UTC); no later row supersedes it.
- **Technical gate also FAILS on today's inputs.** E requires SPY ≠ DOWN **and** VIX ≠ HIGH **and** Breadth = HEALTHY. As of 2026-09-30: SPY Trend `NEUTRAL` (762.63, 0.11 below its 50d 762.74 — passes ≠ DOWN), VIX `NORMAL` (16.34 — passes), **Equity Breadth `WEAK` (40.55%, Barchart $S5TH) — FAILS**. Breadth has fallen from 66.2 at the September screen to 40.55. That is exactly the narrow-participation condition E's spec says compresses within-industry spreads.
- **Pre-mortem: CLEARED.** The September edition described `premortem-E-2026-a3` cycle 13 as open with no orchestrator ruling. AR_orc ruled the same day, 2026-09-01: **SUFFICIENT**, the attacker's Tier-1 defect not sustained, the pre-mortem unblocked for first-trade gating (`events.decision_log` `8d15c8e3-6c57-43fd-baf0-d4338ac336a2`). That stale description is corrected here.
- **What happened to September's shortlist.** M4 2026-09-01 enqueued two pairs for thesis construction, and D2 drained both on 2026-09-03. **DY/EME was NO-GO on the merits**: criterion 2 failed on four fresh sell-side target cuts (`e04dc017-b375-49f2-bb48-230a6365d88a`). **EFX/TRU was GO on the merits (60) but NO ENTRY**, because the then-pending `div-E-202608-1` review fired the item's conservative default (`3540112c-ccb3-46fb-bf9a-106975e1f910`). Neither pair entered. On 2026-09-13 D2 declined a D1-routed **DELL/STX** E pair at the router and referred it here (`8d6a402d-dd92-4496-822d-87befd097112`). It is measured below: **corr 0.2675, below the 0.30 population rail, out of population.**

**Consequence.** PART 2 is research feedstock for M4 and for the next divergence review, **not a queue to drain into orders**. Nothing here can stage until both the binding fundamental state and the breadth leg of the technical gate change. The screen is not weakened on that account. Activation state was read only after every pair's disposition was set, and no disposition turns on it.

## Cross-strategy conflicts and the E book

**Strategy E's own book is empty.** `state.current_positions` holds 12 open positions and every one is Strategy D (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER), unchanged from September. The rule "exclude pairs where either leg is in the open E book" therefore excludes nothing.

- **GEV remains open long in the D book** (`D:GEV:2026-08-03`), so **VRT/GEV** (0.6394) stays recorded and not advanced. An E short of GEV would largely net out against D at book level.

## Structurally invalid or compromised pairs

The permanent exclusion list is unchanged: **SYF/DFS** (DFS delisted, Capital One merger), **SPR/HWM** (SPR delisted, Boeing), **JNPR/ANET** (JNPR delisted, HPE), **EA/TTWO** (EA deregistered after going private, Form 15-12G 2026-08-14). None was re-probed.

**Three legs are newly flagged this cycle as compromised by a pending or reported control transaction.** That makes them unsuitable as pair legs whatever their correlation:

| Leg | Pairs affected | What was found (public sources) | Disposition |
|---|---|---|---|
| **WDAY** | WDAY/NOW (0.7507) | Reuters reported on 2026-08-13 that Silver Lake is in talks to take Workday private (~$43B); the stock rose ~17% that day. As of late September no deal had been announced and none had been abandoned. A short leg carrying an undated binary take-private premium is not a narrative-divergence short. | **Rejected this cycle**: September's #3 pair is dropped. |
| **KMB** | KMB/PG (0.5354) | The Kimberly-Clark–Kenvue transaction is still pending as of 2026-10-01. Shareholders approved it 2026-01-29 and the HSR waiting period expired 2026-02-04. EU remedies were offered 2026-09-23 and the EC deadline was extended to 2026-10-13 (press-reported, ESTIMATE). KMB trades on deal and financing risk. | Rejected (structural). |
| **WBD** | WBD/NFLX (−0.0322) | IBKR closes pinned at 30.76–30.95 for the last 7 sessions after a jump from 28.07 to 30.80 on 2026-09-21; `search_contracts` lists a `WBD.TEN` tender row. This is a takeover-peg signature. | Already out of population on correlation; recorded so it is not mistaken for a live leg. |

---

# PART 1 — measured population

All figures were measured this session from **IBKR regular-session daily closes** (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`, the `close` array), **250 bars per ticker, window 2025-10-02 → 2026-09-30**. That gives 249 aligned daily log-return observations per pair. Pearson correlation is computed on log returns; beta is the OLS slope of A's returns on B's; vol is annualised ×√252. **"1M" = 2026-08-31 → 2026-09-30**, anchored to the September screen's last close so the column reads "what happened since the last screen". **"3M" = 2026-06-30 → 2026-09-30.** Spread = A's total return minus B's, in percentage points. 172 tickers and 91 pairs were measured. The 91 are September's 89 measurable pairs plus **DELL/STX** (the D2 referral) and **WDC/STX** (new; the other half of the HDD duopoly).

**Window length, stated rather than papered over.** The spec names a trailing **252**-day correlation. IBKR's `ONE_YEAR` period returns 250 bars. A dedicated re-pull with `step_count=253` returned at most 252 bars (19 of 24 tickers), so the longest window this feed supplies here is **251 returns**. Every pair within ±0.02 of the 0.50 floor was **re-measured on that 251-return window**, along with five high-stakes pairs. **No disposition changes**:

| Pair | 249-return | 251-return | Side of the 0.50 floor |
|---|---|---|---|
| CMI/PCAR | 0.5012 | 0.5019 | above (both) |
| EFX/VRSK | 0.5121 | 0.5040 | above (both) |
| MRVL/AVGO | 0.5084 | 0.5085 | above (both) |
| ZBH/SYK | 0.5131 | 0.5119 | above (both) |
| BEN/TROW | 0.5159 | 0.5191 | above (both) |
| **CVS/CI** | **0.4979** | **0.4992** | **below (both) — misses by 0.0008 and is not rounded up** |
| BAX/BDX | 0.4946 | 0.4966 | below (both) |
| MAS/CARR | 0.4922 | 0.4910 | below (both) |
| AAP/ORLY | 0.4911 | 0.4881 | below (both) |
| WDC/STX · PANW/CRWD · AAL/DAL | 0.8777 · 0.8461 · 0.8231 | 0.8788 · 0.8455 · 0.8226 | above (all) |

**Layer-1 population rail (mechanical, a cost bound):** same 6-digit GICS industry, 252-day correlation ≥ 0.30, large-cap with adequate ADV, and both legs reported earnings or filed a 10-Q/10-K within 90 days (on or after **2026-07-03**).
**Spec floor (mechanical, derived from Strategy E's spec_hash-frozen Entry criterion 3):** 252-day correlation ≥ 0.50 to be eligible to advance. Not negotiated at the third decimal.

**Population this cycle: 85 pairs clear the rail.** Of these, 64 are above the spec floor and eligible, 20 sit in the 0.30–0.49 context band, and 1 (FITB/HBAN) is withheld on data quality. A further 5 fall below the 0.30 rail. **TMUS/CMCSA is measured but excluded**: its legs are not in the same GICS industry group (see the defect notes).

## The 90-day recency gate — SEC EDGAR primary filings, 171 of 172 resolved

The gate ran again on **SEC EDGAR's submissions API**, the standing method recommended last cycle. For each ticker the date taken is the later of its latest 10-Q/10-K and its latest 8-K carrying **Item 2.02**. All 172 tickers resolved (BNY via CIK 1390777; `company_tickers.json` lists it as BNY, not BK). **Result: 171 PASS, 0 FAIL, 1 structurally not applicable.**

- **The closest-to-cutoff name is DAL** (last qualifying filing 2026-07-10, 83 days), followed by ELV (07-15), NFLX/TRV (07-17) and a cluster on 07-21. Nobody is on the boundary this cycle. **Q3 earnings season, starting ~mid-October, will refresh the whole population before November's run.**
- **MDB/SNOW is back in population.** Both legs failed the gate in September at 94–96 days. MongoDB has since filed an Item 2.02 8-K and 10-Q on 2026-09-01, and Snowflake filed its 8-K on 09-02 and 10-Q on 09-04.
- **SPOT is still a foreign private issuer** (last filing a 6-K, 2026-09-03; never a 10-Q). LYV/SPOT is out of population on correlation (0.1673), so nothing turns on it.

## Data integrity — four checks, all on the full population

1. **Swap detector** (no two tickers may share a close series): **CLEAN**, run pairwise across all 172.
2. **Frozen-print detector** (≥3 identical consecutive closes): one hit, the known one. **FITB again returns 53.42 for six sessions (2026-06-12 → 06-22) and is missing the 2026-06-11 bar** (249 bars against 250 for every other ticker). This is the same value, the same run length and the same window as the September pull. The window had shifted between the August and September fetches; between September and October it did not move. **FITB/HBAN stays withheld on data quality, not thesis.** It would otherwise rank seventh in the population at 0.8736.
3. **Independent re-pull transcription audit — NEW, and it closes a gap.** This cycle the closes were transcribed from tool responses by eight separate workers, so a mid-series copying slip was a real risk that a last-close check cannot see. 24 tickers were re-pulled by a different worker with a different request (`step_count=253`) and compared close by close over the overlapping dates. **Zero mismatches across all 24 series** (~6,000 closes). This is the strongest integrity evidence this screen has produced, and it should be a standing check.
4. **Single-day jumps >25%** (corporate-action and split screen). Six hits, all consistent with disclosed earnings reactions and not with unadjusted splits: SNOW +36.5% (2026-05-28), MRVL +32.5% (06-02), DELL +32.8% (05-29), DY +25.8% (05-27), NXPI +25.5% (04-29), MOH −25.5% (02-06). Split-adjusted series were confirmed internally consistent for NOW, NFLX, CRWD and CMG. FDX, CMCSA and BDX carry back-adjusted early closes (spin-off adjustments), which leaves returns valid.

## PART 1A — ABOVE the 0.50 spec floor (64 pairs, eligible to advance)

### Technology

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 453010 Semis | QRVO/SWKS | 0.9762 | 0.9950 | 0.7505 | 39.49% | 51.37% | -8.41 | -3.34 | 114.48 | 85.48 |
| 452020 Tech Hardware | WDC/STX | 0.8777 | 0.8387 | 0.9424 | 79.49% | 74.03% | -10.47 | -24.43 | 454.46 | 922.34 |
| 453010 Semi Equip | LRCX/KLAC | 0.8743 | 0.8685 | 0.9229 | 64.57% | 61.17% | -2.14 | 11.2 | 328.51 | 194.93 |
| 451030 Software | PANW/CRWD | 0.8461 | 0.9049 | 0.7415 | 47.55% | 54.25% | -10.64 | -22.26 | 397.31 | 264.75 |
| 453010 Semis | MCHP/ADI | 0.8126 | 0.8259 | 1.1164 | 50.0% | 36.39% | -3.66 | -14.61 | 77.77 | 396.71 |
| 453010 Semi Equip | TER/AMAT | 0.7635 | 0.7907 | 0.9883 | 77.22% | 59.65% | 3.04 | 12.13 | 400.91 | 511.38 |
| 451030 Software | WDAY/NOW | 0.7507 | 0.6835 | 0.6921 | 53.54% | 58.07% | 5.91 | 20.6 | 190.46 | 134.01 |
| 451030 Software | FTNT/CRWD | 0.7427 | 0.8661 | 0.5697 | 41.62% | 54.25% | -10.03 | -22.4 | 178.76 | 264.75 |
| 453010 Semis | ON/NXPI | 0.7388 | 0.7714 | 0.9823 | 64.59% | 48.58% | -1.99 | -3.21 | 76.87 | 237.53 |
| 451030 Software | MDB/SNOW | 0.6005 | 0.5282 | 0.6851 | 71.19% | 62.4% | -25.56 | -29.64 | 348.61 | 339.56 |
| 453010 Semis | MRVL/AVGO | 0.5084 | 0.4942 | 0.8444 | 77.85% | 46.87% | 30.0 | -4.28 | 264.21 | 351.19 |

### Financials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | RF/KEY | 0.8869 | 0.8892 | 0.9015 | 24.66% | 24.26% | -2.91 | 1.94 | 26.88 | 20.07 |
| 401010 Banks | USB/PNC | 0.8847 | 0.9186 | 0.9045 | 22.59% | 22.09% | 1.05 | 5.36 | 57.76 | 222.26 |
| 401010 Banks | TFC/MTB | 0.8481 | 0.8006 | 0.9524 | 24.69% | 21.99% | 0.37 | 1.51 | 46.3 | 217.6 |
| 402030 Capital Markets | STT/BNY | 0.8098 | 0.8643 | 0.9332 | 25.11% | 21.79% | 1.55 | 2.93 | 174.59 | 144.63 |
| 402020 Consumer Finance | COF/AXP | 0.7711 | 0.7035 | 0.9268 | 32.5% | 27.04% | -2.1 | 6.33 | 193.07 | 304.1 |
| 403010 Insurance | ALL/PGR | 0.7186 | 0.6721 | 0.6549 | 25.43% | 27.9% | -9.0 | -1.66 | 221.86 | 207.31 |
| 403010 Insurance | TRV/CB | 0.7158 | 0.6949 | 0.7615 | 20.81% | 19.57% | 1.37 | 12.54 | 356.51 | 325.25 |
| 403010 Insurance | MET/PRU | 0.7091 | 0.7597 | 0.7360 | 23.81% | 22.94% | 2.36 | 6.05 | 94.16 | 113.58 |
| 402010 Capital Markets | RJF/LPLA | 0.7032 | 0.7343 | 0.4832 | 25.15% | 36.6% | 6.07 | -4.62 | 158.02 | 305.8 |
| 401010 Banks | WFC/C | 0.6874 | 0.7414 | 0.6271 | 26.83% | 29.41% | -5.71 | 4.35 | 80.05 | 129.48 |
| 403010 Insurance | AIG/HIG | 0.5221 | 0.6065 | 0.6433 | 24.45% | 19.84% | 8.39 | 7.52 | 74.42 | 122.36 |
| 402030 Capital Markets | BEN/TROW | 0.5159 | 0.3948 | 0.5907 | 28.02% | 24.48% | 0.55 | 5.02 | 32.12 | 104.05 |

### Energy/Materials/Utilities

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 151010 Chemicals | DOW/LYB | 0.8808 | 0.8998 | 0.8926 | 43.98% | 43.39% | 1.93 | -8.5 | 27.54 | 57.47 |
| 101020 E&P | DVN/EOG | 0.8533 | 0.9063 | 1.0235 | 34.72% | 28.95% | -0.12 | 5.23 | 46.04 | 137.76 |
| 101020 E&P | APA/FANG | 0.7954 | 0.8283 | 1.1094 | 45.75% | 32.8% | 4.58 | 22.97 | 41.54 | 183.81 |
| 151030 Packaging | IP/PKG | 0.7365 | 0.8080 | 1.1697 | 44.74% | 28.17% | -10.55 | -9.15 | 33.17 | 229.26 |
| 151010 Chemicals | PPG/SHW | 0.7364 | 0.7427 | 0.8200 | 30.59% | 27.47% | -2.4 | -7.87 | 104.33 | 323.27 |
| 101010 Energy Equip | HAL/SLB | 0.7000 | 0.6218 | 0.6783 | 35.09% | 36.21% | 5.23 | -11.13 | 31.8 | 48.72 |
| 551010 Utilities | EXC/AEP | 0.6943 | 0.8031 | 0.7139 | 19.54% | 19.0% | -4.5 | -0.06 | 40.4 | 118.64 |
| 151010 Chemicals | EMN/CE | 0.6132 | 0.4954 | 0.3792 | 32.57% | 52.66% | -8.05 | 0.35 | 64.84 | 44.37 |
| 101010 Energy Equip | HAL/BKR | 0.6017 | 0.4105 | 0.6331 | 35.09% | 33.35% | -0.09 | -5.25 | 31.8 | 54.9 |
| 151040 Metals | CLF/NUE | 0.5581 | 0.6139 | 1.2211 | 70.13% | 32.06% | 1.69 | 12.31 | 11.01 | 233.75 |

### Consumer

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 252010 Homebuilders | KBH/DHI | 0.8544 | 0.8844 | 0.9359 | 38.94% | 35.55% | -7.34 | -9.65 | 46.47 | 136.65 |
| 302020 Food | CAG/GIS | 0.8045 | 0.7662 | 0.8523 | 30.44% | 28.73% | 5.84 | 7.44 | 13.44 | 32.16 |
| 253020 Hotels | H/MAR | 0.7341 | 0.6338 | 0.9138 | 33.88% | 27.21% | -9.11 | -14.17 | 158.56 | 355.67 |
| 252010 Homebuilders | TOL/NVR | 0.7131 | 0.7648 | 0.8982 | 34.47% | 27.37% | -3.52 | -8.54 | 134.75 | 6154.39 |
| 255030 Broadline Retail | DLTR/DG | 0.6240 | 0.6413 | 0.6900 | 41.19% | 37.25% | -4.27 | -9.61 | 114.02 | 119.58 |
| 251020 Automobiles | F/GM | 0.5903 | 0.6638 | 0.6478 | 38.44% | 35.02% | -2.69 | -13.13 | 12.06 | 77.0 |
| 255040 Specialty Retail | ROST/TJX | 0.5766 | 0.5369 | 0.7158 | 26.25% | 21.15% | 3.32 | 22.32 | 233.4 | 132.31 |
| 303010 Household Prod | CLX/CHD | 0.5511 | 0.5873 | 0.7784 | 31.97% | 22.64% | -11.49 | -12.37 | 81.01 | 94.22 |
| 303010 Household Prod | KMB/PG | 0.5354 | 0.5698 | 0.7641 | 28.19% | 19.75% | -9.86 | -10.31 | 97.43 | 145.28 |

### Industrials

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 202020 Prof Services | EFX/TRU | 0.8515 | 0.8664 | 0.8138 | 38.8% | 40.59% | 0.57 | 1.74 | 137.24 | 61.12 |
| 203020 Airlines | AAL/DAL | 0.8231 | 0.8417 | 1.0021 | 47.67% | 39.16% | -7.45 | -15.12 | 13.37 | 83.46 |
| 203040 Ground Transport | XPO/ODFL | 0.7490 | 0.7417 | 0.8430 | 42.8% | 38.03% | 3.78 | 5.46 | 175.98 | 173.84 |
| 201030 Constr&Eng | MTZ/PWR | 0.7367 | 0.6214 | 0.9027 | 53.56% | 43.71% | -16.74 | -37.89 | 213.62 | 642.51 |
| 201040 Electrical Equip | VRT/NVT | 0.7135 | 0.7702 | 0.9961 | 65.64% | 47.01% | -13.11 | -22.48 | 241.31 | 160.37 |
| 201010 Aero&Defense | NOC/LMT | 0.7038 | 0.6217 | 0.6878 | 27.74% | 28.39% | -1.16 | -5.03 | 483.48 | 509.25 |
| 203010 Air Freight | FDX/UPS | 0.6541 | 0.5258 | 0.6165 | 29.04% | 30.81% | -2.57 | 4.12 | 285.09 | 93.44 |
| 201060 Machinery | DOV/IR | 0.6499 | 0.4512 | 0.5200 | 26.22% | 32.77% | -1.18 | -8.21 | 187.05 | 75.11 |
| 201040 Electrical Equip | HUBB/NVT | 0.6459 | 0.6360 | 0.4422 | 32.19% | 47.01% | -6.25 | -7.85 | 453.6 | 160.37 |
| 201040 Electrical Equip | VRT/GEV | 0.6394 | 0.6125 | 0.8010 | 65.64% | 52.39% | -12.51 | -8.83 | 241.31 | 950.49 |
| 201060 Machinery | SWK/ITW | 0.6156 | 0.4554 | 1.0574 | 37.57% | 21.88% | -1.5 | -1.0 | 88.59 | 257.28 |
| 201020 Bldg Products | LII/TT | 0.6149 | 0.5986 | 0.9065 | 42.37% | 28.74% | -8.92 | -30.06 | 355.02 | 451.98 |
| 201040 Electrical Equip | VRT/HUBB | 0.5961 | 0.6246 | 1.2156 | 65.64% | 32.19% | -6.86 | -14.63 | 241.31 | 453.6 |
| 201030 Constr&Eng | ACM/J | 0.5919 | 0.5383 | 0.6759 | 38.32% | 33.56% | -3.33 | -22.9 | 58.95 | 135.27 |
| 201030 Constr&Eng | DY/EME | 0.5542 | 0.6831 | 0.6388 | 52.2% | 45.29% | -10.32 | -37.69 | 269.08 | 754.49 |
| 202020 Prof Services | EFX/VRSK | 0.5121 | 0.7126 | 0.5468 | 38.8% | 36.34% | -14.07 | -7.03 | 137.24 | 167.85 |
| 201060 Machinery | CMI/PCAR | 0.5012 | 0.0739 | 0.6891 | 36.88% | 26.82% | 3.06 | -18.99 | 516.57 | 109.81 |

### Health Care

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 351020 HCDistributors | COR/MCK | 0.7047 | 0.8101 | 0.7570 | 32.2% | 29.98% | -3.66 | -6.89 | 300.25 | 853.81 |
| 352030 Life Sci Tools | RVTY/TMO | 0.6936 | 0.6330 | 0.9358 | 38.73% | 28.71% | 9.43 | 2.77 | 152.89 | 675.05 |
| 351020 Managed Care | ELV/UNH | 0.6734 | 0.4482 | 0.6692 | 35.46% | 35.68% | 4.79 | 12.22 | 388.82 | 367.08 |
| 351020 Managed Care | CNC/MOH | 0.5448 | 0.7100 | 0.4713 | 48.02% | 55.51% | 1.41 | 14.09 | 62.12 | 189.1 |
| 351010 HCEquipment | ZBH/SYK | 0.5131 | 0.7004 | 0.5701 | 33.29% | 29.96% | 3.75 | 15.71 | 88.83 | 275.39 |

## PART 1B — 0.30–0.49 band, BELOW the spec floor (20 pairs + TMUS/CMCSA shown but excluded) — context / SL1 ideation only

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 351020 Managed Care | CVS/CI | 0.4979 | 0.5500 | 0.4656 | 31.65% | 33.85% | -7.21 | -15.77 | 85.69 | 271.83 |
| 351010 HCEquipment | BAX/BDX | 0.4946 | 0.4562 | 0.8528 | 43.99% | 25.52% | -2.85 | -5.71 | 24 | 179 |
| 201020 Bldg Products | MAS/CARR | 0.4922 | 0.5683 | 0.4837 | 35.36% | 35.98% | -0.83 | 8.04 | 67.4 | 54.86 |
| 255040 Specialty Retail | AAP/ORLY | 0.4911 | 0.5199 | 1.1364 | 60.11% | 25.98% | -3.93 | -30.21 | 38.91 | 85.41 |
| 352010 Biotech | GILD/AMGN | 0.4839 | 0.5169 | 0.4425 | 26.45% | 28.93% | 3.8 | 1.57 | 149.05 | 421.51 |
| 452020 Tech Hardware | HPQ/DELL | 0.4748 | 0.2269 | 0.2970 | 45.35% | 72.5% | -13.77 | 17.89 | 31.28 | 537.95 |
| 201010 Aero&Defense | TXT/GD | 0.4738 | 0.4839 | 0.5687 | 26.91% | 22.42% | 5.23 | -10.6 | 76.2 | 331.83 |
| 453010 Semis | AMD/NVDA | 0.4708 | 0.4048 | 0.8974 | 71.94% | 37.74% | 26.52 | -8.83 | 611.76 | 228.38 |
| 201060 Machinery | CR/ITW | 0.4601 | 0.2882 | 0.6822 | 32.44% | 21.88% | 6.06 | -3.66 | 204.02 | 257.28 |
| 352010 Biotech | BIIB/VRTX | 0.4581 | 0.4585 | 0.5453 | 33.69% | 28.3% | 8.25 | -0.71 | 225.88 | 522.81 |
| 351010 HCEquipment | MDT/BSX | 0.4558 | 0.5248 | 0.2726 | 23.74% | 39.69% | 4.82 | 8.03 | 86.29 | 43.65 |
| 453010 Semis | INTC/TXN | 0.4480 | 0.5596 | 0.8138 | 76.08% | 41.88% | 26.97 | -7.86 | 120.23 | 280.09 |
| 352020 Pharma | BMY/MRK | 0.4434 | 0.4997 | 0.4146 | 26.82% | 28.68% | -4.94 | -4.79 | 62.4 | 145.31 |
| ~~501010 Telecom~~ NOT SAME GROUP (501020 vs 502010) — excluded from population, see defect note | TMUS/CMCSA | 0.4254 | 0.6996 | 0.3948 | 30.49% | 32.85% | 8.64 | 8.59 | 163.08 | 21.76 |
| 351010 HCEquipment | PODD/DXCM | 0.4197 | 0.4958 | 0.4874 | 46.22% | 39.81% | -7.0 | -42.43 | 130.47 | 86.29 |
| 352020 Pharma | PFE/LLY | 0.3917 | 0.5374 | 0.2465 | 21.62% | 34.36% | 0.18 | 21.97 | 28.52 | 1157.08 |
| 302010 Beverages | KDP/MNST | 0.3826 | 0.5264 | 0.3942 | 27.11% | 26.32% | 4.59 | 6.1 | 30.34 | 41.62 |
| 551010 Utilities | PCG/NEE | 0.3597 | 0.2616 | 0.6262 | 36.46% | 20.94% | 0.33 | -13.46 | 12.25 | 75.74 |
| 253020 Restaurants | SBUX/CMG | 0.3495 | 0.2772 | 0.2236 | 27.63% | 43.18% | 4.42 | -2.02 | 93.96 | 31.95 |
| 402030 Capital Markets | NDAQ/CME | 0.3440 | 0.3972 | 0.3950 | 27.96% | 24.35% | 1.55 | -1.9 | 92.01 | 261.98 |
| 253020 Restaurants | YUM/QSR | 0.3433 | 0.5118 | 0.3494 | 24.6% | 24.17% | -2.34 | -12.74 | 136.34 | 71.08 |

## PART 1C — BELOW the 0.30 population rail (5 pairs) — OUT OF POPULATION

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 352030 Life Sci Tools | ILMN/DHR | 0.2905 | 0.2342 | 0.4566 | 47.35% | 30.12% | 24.37 | 39.34 | 273.68 | 221.55 |
| 452020 Tech Hardware | DELL/STX | 0.2675 | 0.3859 | 0.2620 | 72.5% | 74.03% | 6.63 | 29.1 | 537.95 | 922.34 |
| 502020 Media | PSKY/FOXA | 0.2153 | 0.3786 | 0.2979 | 49.44% | 35.74% | 1.66 | -15.34 | 10.33 | 62.65 |
| 502020 Media | LYV/SPOT | 0.1673 | 0.3849 | 0.1167 | 31.21% | 44.75% | 4.46 | -13.69 | 169.3 | 487.38 |
| 502020 Media | WBD/NFLX | -0.0322 | 0.2462 | -0.0235 | 26.7% | 36.65% | 22.63 | 18.64 | 30.95 | 69.58 |

## PART 1D — measured but WITHHELD (1 pair)

| GICS | Pair (A/B) | 252d | 60d | beta | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | FITB/HBAN | 0.8736 | 0.8562 | 0.8291 | 26.27% | 27.68% | 2.58 | 3.66 | 50.58 | 15.26 |


## PART 1B notes — the three sub-floor pairs recorded

Per §19 the 0.50 bar **derives from** Strategy E's spec_hash-frozen Entry criterion 3 and is **not** a screen tune. Sub-floor pairs are recorded `below_spec_floor=true` as SL1 ideation evidence only and are **never** entry candidates. The cap is **3 per call**, and the same three pairs appear in this note and in the fields-JSON `passed` items.

| Pair | 252d | 60d | Why it is recorded |
|---|---|---|---|
| **CVS/CI** (351020) | **0.4979** (0.4992 on 251 returns) | 0.5500 | **Closest miss in the population on both windows.** It misses by 0.0008 on the longer window and is not rounded up. Same discipline as AAP/ORLY in August (0.499, not rounded, then 0.4772 a month later). |
| **AMD/NVDA** (453010) | **0.4708** | 0.4048 | **Fifth consecutive month below the floor**: 0.49, 0.4933, 0.492, 0.4700, now 0.4708. The 60d has fallen to 0.40. September called this a settled finding, and this reading confirms it. AMD's +26.5pp 1M outperformance is a two-stock AI-accelerator divergence that is not a pair by E's own definition, so it stays on record as SL1 material and nothing more. |
| **BAX/BDX** (351010) | **0.4946** (0.4966 on 251 returns) | 0.4562 | **Second-closest miss on both windows**, with a 3M spread of −5.71pp. The 60d (0.46) is below the 252d, so this hedge is weakening, not converging. Recorded with CVS/CI as the two boundary names, so W5's recurrence check can watch whether either crosses. |

## PART 1E — reconciliation of the 2026-09-01 shortlist

**Six of September's eight pairs are dropped. Two are kept, and both are promoted into the top three.** The turnover is high because the evidence moved. Every drop rests on dated public information gathered this session, and two also correct statements in the September edition.

| Prior pair | Prior tier | Status | Reason (public information only) |
|---|---|---|---|
| **DY/EME** (0.5542) | TOP | **NOT RE-ADVANCED — D2's NO-GO stands** | D2 judged it NO-GO on the merits on 2026-09-03. A NO-GO is context, not a barrier, so it was re-examined, and nothing new and decisive turned up. Raymond James cut its target to $375 from $610 on 09-03, one of the four cuts behind the NO-GO. KeyBanc nudged its target to $429 from $423 on 09-21, and no further cuts were found. The Q3 EPS guide midpoint (~$4.56 against $4.68 consensus) and the margin/deferral risk are unchanged. The spread widened further, to −37.69pp 3M and −10.32pp 1M, but a gap that keeps widening on the earned mechanism a NO-GO identified is not new evidence against that NO-GO. Re-test at DY's FQ3 (~late November, ESTIMATE). |
| **EFX/TRU** (0.8515) | TOP | **DROP — the thesis's spread no longer exists** | Both legs fell ~27–28% since 2026-08-31 (EFX 189.16 → 137.24, TRU 84.91 → 61.12), so the pair spread is **+0.57pp 1M / +1.74pp 3M**, essentially closed. The cause was **one shared policy shock, not the mortgage-cycle reconvergence the thesis named**. On 2026-09-03 FHFA Director Pulte said the credit bureaus overcharge, put "bi-merge" (two bureaus per mortgage instead of three) under serious consideration, and ordered Fannie/Freddie to accept VantageScore 4.0 for all lenders. On 09-04 TRU fell ~9% and EFX ~8% (Reuters, via secondary). BMO cut EFX's target to $160 from $179 on 09-30. A regulatory event that hits both bureaus equally carries no pair view. The pair kept its 0.85 hedge and lost its divergence. |
| **NOW/WDAY** (0.7507) | REST (top) | **DROP — structurally compromised short leg** | See the Structurally compromised table: WDAY is a reported Silver Lake take-private target (Reuters, 2026-08-13). **Two September statements are corrected.** (i) WDAY's 2026-08-27 print did not plainly "miss" its subscription guide. FY27 subscription was guided to $9.94–9.95B and the operating-margin guide was raised to 31%. (ii) The 2026-09-29 Item 2.02 8-K is a **restructuring** (~2.5% of the workforce, ~525 roles, $65–80M of charges), not a pre-announcement. NOW fell in September on valuation (~85× earnings after a ~30% run), layoffs and insider sales. The 3M spread widened to +20.6pp in WDAY's favour, partly on the deal premium. |
| **MCHP/ADI** (0.8126) | REST | **KEEP — PROMOTED to #1** | The reconvergence September called "substantially realised" has **reversed**: the 3M spread re-widened from −9.67pp to **−14.61pp**, with no MCHP-specific negative event found. See PART 2 §1. |
| **COF/AXP** (0.7711) | REST | **DROP** | No pair-specific September event and no narrative-vs-fundamental gap. Both legs drifted lower: 1M −2.10pp, and the 3M lead has shrunk to +6.33pp, so what remained of a "decayed by success" trade has decayed further. COF's August credit-metrics 8-K was not located this session. **Correction: AXP's 2026-10-23 Q3 date, called "issuer-confirmed" in September, could not be re-verified against AXP IR this session and is downgraded to ESTIMATE.** |
| **CB/TRV** (0.7158) | REST | **KEEP — PROMOTED to #3** | The divergence reopened: TRV has led by +12.54pp over 3M. Both legs' Q3 dates are now issuer-confirmed. See PART 2 §3. |
| **PANW/CRWD** (0.8461) | REST, event-pending | **DROP — resolved against the long leg** | September made this resolve-or-decline at PANW's FQ4. **It resolved, and against the thesis.** PANW beat (revenue $3.41B vs $3.35B, EPS $1.02 vs $0.98), but headline NGS-ARR growth of 63% is inflated by the CyberArk and Chronosphere acquisitions. The FY27 guide implies ~22–23% organic NGS-ARR growth, and gross margin fell 100bp to 74.8%. PANW fell ~5% after the print, took a Bernstein downgrade on 09-18 and fell 3.9% on 09-25. CRWD rose ~33% in 30 days on record net-new ARR (~$333M), the DOJ closing its inquiry, and Fal.Con launches. The −22.26pp 3M gap is largely **earned**. *(Unresolved detail: September recorded PANW as reporting "2026-09-01 after close"; this session's sources show the drop in the 09-01 regular session. The 8-K was not opened, so the exact timing is left open rather than asserted.)* |
| **F/GM** (0.5903) | REST (bottom) | **DROP — the long leg deteriorated** | Ford's September worked against the long. It halted F-150 output at Dearborn in the quarter's final week, August US sales fell 10.3%, it recalled 148,663 vehicles (F-150 campaign 26V578), it warned on USMCA costs, and Cox forecasts ~12.5% share (−1pt). Together these are a guide-cut risk against the $10–11B adj-EBIT guide. GM also fell ~7% in September (truck changeover, ~35k fewer Q4 deliveries), so the 1M spread is only −2.69pp. **Correction to September's framing:** that edition called Ford's Q2 GAAP loss "pre-announced"; this session confirms only that Ford reported a $1.3B GAAP net loss on $4.2B of pre-tax EV charges on 2026-07-28, not that the loss was pre-announced. |

---

# PART 2 — Ranked shortlist of divergence theses (public-information-only)

**How this ranking was produced.** September's eight pairs were reconciled against dated public evidence (PART 1E). Fourteen further candidates were researched from public sources: the largest spreads in this cycle's eligible population, plus September's rejects where the spread had moved materially. Six research workers made 83 metered web calls in total. **The evidence base is thinner than September's and is labelled that way.** Most of it is secondary or aggregator reporting rather than filings or transcripts. Tavily returned HTTP 429 (rate-limited) on several calls, and **no short-interest figure was retrievable for any short leg**. All four pairs meet the ≥ 0.50 spec floor, and both legs of each clear the 90-day gate and the ADV floor by more than 30×.

**Tier coding.** **TOP-3** = the three highest-priority pairs for M4. **REST** = advanced with a stated caveat. M4 reads this section verbatim. **No pair is rated above 45.** September's top pair (DY/EME) went NO-GO two days after the screen, and its other TOP (EFX/TRU) lost its spread to a shared policy shock within a month. The conviction ladder should reflect that.

### 1) Long MCHP / Short ADI — Semiconductors (453010) — **TOP-3 #1 (carry-forward, promoted)**
- **(a) L/S.** **ADI = leader/short** (396.71). **MCHP = laggard/long** (77.77). Both are analog/mixed-signal and share the industrial/auto cycle.
- **(b) Divergence thesis.** Corr **0.8126**, 60d **0.8259**: the best hedge on the shortlist, stable. Beta 1.1164, vols 50.0% / 36.4%, so beta-adjusted sizing matters. The 3M spread is **−14.61pp**, **re-widened** from −9.67pp at the September screen, and 1M is −3.66pp. The fundamentals point the other way to the price. MCHP's FQ1 (2026-08-06): sales $1.485B (+38% y/y), non-GAAP GM 63.8%, inventory days down from 185 to 175, September-quarter guide **+7–9% sequential**; the stock rose ~14% on the print. ADI's FQ3 (2026-08-19): a record $4.02B (+40%), 72.5% GM, $4.3B guide; the stock went −0.9% the next day, and ADI then collected target raises (JPMorgan $500, Morgan Stanley $458, Needham $450; TD Cowen reiterated $460 on 09-08). **No MCHP-specific negative event was found for September.** The re-widening came as sell-side enthusiasm accrued to the leader while the laggard's recovery data went unrewarded. That is the narrative-outpacing-fundamental shape, but it is inferred from the absence of a found event, not measured.
- **(c) Reconvergence indicators.** (i) **MCHP FQ2 FY27 — ESTIMATE ~early November.** The direct test of the +7–9% sequential guide and further inventory-day normalisation. (ii) ADI FQ4 — ESTIMATE ~late November. (iii) Both companies' qualitative book-to-bill and channel-inventory language. Neither discloses a numeric book-to-bill, so this indicator is directional only.
- **(d) Borrow/cost fit.** No short-interest data was retrieved. ADI is a ~$1.44B/day mega-cap with no evidence of special borrow, so general collateral (GC) is presumed (ESTIMATE). At GC (~0.25–0.5% p.a.) over a 3–6 month hold, financing is ~0.1–0.25% of notional, far inside criterion 5's 15%-of-thesis-return ceiling. Re-quote at execution.
- **(e) Execution.** Individual stocks on both legs. ADV: MCHP ~$741M, ADI ~$1.44B (IBKR `avg_90d_usd_volume`).
- **(f) Tier: TOP-3 #1, conviction 45.** **Honest risk:** ADI's AI-data-center mix and its structurally higher margin (72.5% GM, against MCHP's 63.8% with GAAP EPS still depressed by restructuring) justify part of the premium. September recorded this pair as half-realised, and that realisation proved temporary.

### 2) Long MDB / Short SNOW — Software (451030) — **TOP-3 #2, NEW (back in population)**
- **(a) L/S.** **SNOW = leader/short** (339.56). **MDB = laggard/long** (348.61).
- **(b) Divergence thesis.** Corr **0.6005**, 60d **0.5282**: above the floor but **the weakest and a weakening hedge**. Vols are 71.2% / 62.4%, the highest on the shortlist. 1M spread **−25.56pp**, 3M **−29.64pp**: the largest live divergence among the advanced pairs. It has **two components, and they must be kept apart**:
  - **The earnings leg (1–2 Sep) is largely EARNED.** MDB's Q2 (2026-09-01) was strong: revenue $771.8M (+30%), Atlas +29%, FY27 revenue guide raised to $2.99–3.03B. It still fell ~12% after hours on a guided **sequential Q3 revenue decline**. SNOW (2026-09-02) posted product revenue $1.49B (+37%), its **third straight acceleration**, with NRR 126% and FY product guide raised to $6.07B. It rose ~22%.
  - **The 09-28 leg is NARRATIVE.** MDB closed **−18%** on 2026-09-28 (410.44 → 334.68, IBKR bars; ~−26% intraday) when CEO CJ Desai resigned after about a year to lead Meta's new enterprise platform. Former CEO Dev Ittycheria returned as interim. **The next day MDB held its scheduled investor day (2026-09-29, confirmed by MDB press release)**. It **raised** its 3-year targets (revenue growth >20% from high-teens, Atlas mid-20s, 100–200bp/yr margin expansion), authorised a **$1B buyback**, and launched Atlas Infinite and Atlas Agent Engine. The stock recovered only to 348.61 by 09-30. An 18% move on a leadership change, followed the next day by raised long-term targets from the board-backed interim team, is the textbook E setup on the second component only.
- **(c) Reconvergence indicators.** (i) **Permanent CEO appointment** (undated; board search). This is the single largest catalyst. (ii) MDB Q3 FY27 — ESTIMATE ~early December. This is the test of the sequential-decline guide, which is what earned the first leg. (iii) SNOW FQ3 FY27 — ESTIMATE ~late Nov/early Dec.
- **(d) Borrow/cost fit.** SNOW short interest was not retrieved. It is a ~$1.67B/day name; GC is presumed but **not verified**, and SNOW's +22% post-print move makes a squeeze check worthwhile. Must be re-quoted before sizing.
- **(e) Execution.** Individual stocks. ADV: MDB ~$736M, SNOW ~$1.67B.
- **(f) Tier: TOP-3 #2, conviction 45.** Ranked above #3 on divergence size and a clean narrative component, and below #1 on hedge quality. **Honest risk, and it is large:** the hedge is the weakest advanced (60d 0.53, on a pair whose 252d is only 0.60), so E's correlation-breakdown exit (rolling 60d < 0.3) is closer than for any other pair. SNOW's acceleration is real. A CEO leaving abruptly for a potential competitor (Meta) is a governance and competitive fact, not a misreading. **The thesis targets ONLY the post-earnings 09-28 increment and must be sized with that in mind, not against the full −29.6pp.**

### 3) Long CB / Short TRV — Insurance (403010) — **TOP-3 #3 (carry-forward, promoted)**
- **(a) L/S.** **TRV = leader/short** (356.51). **CB = laggard/long** (325.25).
- **(b) Divergence thesis.** Corr **0.7158**, 60d 0.6949, beta 0.7615. **Vols 20.8% / 19.6% are the lowest in the screen**, so hedge-ratio error costs least here. TRV's 3M lead is +12.54pp (1M +1.37pp), built on its Q2 beat (2026-07: net income $2.21B, +46%; core EPS $10.04 on light catastrophe losses). TRV peaked at $398.70 on 07-28 and has given back ~10.6% since. Q3 consensus core EPS is ~$6.84 (aggregator ESTIMATE), a step-down from Q2. The case is that TRV's multiple still carries a catastrophe-light Q2 into a quarter that includes a **late-September Northeast nor'easter** (from ~2026-09-25: NJ/NY flooding, 80,000+ outages across five states). That storm hits TRV's personal-lines concentration harder than globally diversified Chubb's. **Source-quality caveat, prominently:** the storm's insured-loss significance comes from a low-quality blog source only. No dollar estimate and no catastrophe pre-announcement from either insurer was found. **Nothing about the storm may be relied on until the 10-16 print quantifies it.**
- **(c) Reconvergence indicators — the only issuer-CONFIRMED dates in this shortlist.** (i) **TRV Q3: Fri 2026-10-16, pre-market, call 9:00 ET — CONFIRMED** (TRV scheduling press release, via a reprint). (ii) **CB Q3 call: Wed 2026-10-21, 8:30 ET — CONFIRMED** (Chubb press release). The release itself is expected 10-20 after close, which is **derived** from the call date (ESTIMATE). (iii) Any catastrophe-loss pre-announcement by TRV before 10-16.
- **(d) Borrow/cost fit.** TRV short interest not retrieved; it is a large-cap GC insurer with no evidence of special borrow (ESTIMATE).
- **(e) Execution.** Individual stocks. ADV: TRV ~$609M, CB ~$576M.
- **(f) Tier: TOP-3 #3, conviction 30.** It sits in the top three on catalyst proximity and structure (two confirmed prints inside three weeks, lowest vol), not on thesis strength. **Honest risk:** TRV's 3M lead was earned by a real Q2 beat, and the storm-loss mechanism is unquantified. If TRV's 10-16 catastrophe line is benign, the thesis has nothing left and should be declined at that print.

### 4) Long MTZ / Short PWR — Construction & Engineering (201030) — **REST, NEW**
- **(a) L/S.** **PWR = leader/short** (642.51). **MTZ = laggard/long** (213.62).
- **(b) Divergence thesis.** Corr **0.7367**; 60d **0.6214**, weakening. 3M spread **−37.89pp, the largest in the eligible population**; 1M −16.74pp. MTZ's Q2 (late July) set records: revenue $4.4B (+23%), 18-month backlog $21.4B, FY adj-EPS guide **raised** to $9.30. The stock nonetheless fell on Communications-segment softness, wireline deferrals and free-cash-flow concerns, then dropped a further ~7–8% on **2026-09-17 with no identified trigger** (sources disagree between −7.92% and −7.04%; technical breaks of the 50/200-day averages and insider-sale filings were noted). Consensus target ~$417 against a $214 price.
- **(c) Reconvergence indicators.** MTZ Q3 — ESTIMATE ~late Oct/early Nov. This tests whether Communications deferrals are a timing shift or a lost book.
- **(d) Borrow/cost fit.** PWR short interest not retrieved; large-cap, GC presumed (ESTIMATE).
- **(e) Execution.** Individual stocks. ADV: MTZ ~$323M (the thinnest advanced leg, still >30× the floor), PWR ~$666M.
- **(f) Tier: REST, conviction 30.** **Honest risk:** August and September both declined this pair because the earned divergence kept widening, and it has widened again, by a further 16pp. Advancing it now rests on a raised guide and record backlog against an unexplained 09-17 drop. That is weaker than a thesis. **M4 should treat this as watch-grade: a candidate for the Q3 print, not for thesis construction ahead of it.**

---

## Considered and NOT advanced (researched this cycle)

| Pair | 252d | Why not |
|---|---|---|
| **WDC/STX** (452020, NEW) | **0.8777** | **Earned.** STX has run 44TB HAMR drives in production since March 2026; WDC's volume HAMR targets 2027. WDC beat on every line on 2026-08-06 (revenue $3.747B, EPS $3.56, GM 54.4%) and still fell ~11% on the technology gap, with Summit Insights downgrading to Hold that day. The gap reflects a technology roadmap that will not close inside E's 1–6 month horizon. The second-highest correlation in the population with no narrative component. |
| **TJX/ROST** (255040) | 0.5766 | **Earned, on guidance.** ROST's Q2 (2026-08-20): comp **+10%**, its second straight double-digit; FY EPS guide raised to $8.61–8.77 (Q2 EPS included ~$0.60 of tariff refund). TJX (08-19): comp +4%, Marmaxx +1%, Q3 comp guide 2–3% against ROST's 6–7%. The forward guides say the +22.3pp 3M gap persists. The hedge is also weakening (60d 0.54). |
| **FANG/APA** (101020) | 0.7954 | **Commodity bet in pair clothing** — the DVN/EOG and HAL/SLB failure mode, a third time. APA's Egypt/North Sea/international exposure against FANG's pure Permian WTI, during an acute Middle East supply shock (Brent ~$107 on 09-15), is a Brent/international-gas beta trade, not a narrative one. APA hit a 52-week high of $47.44 on 09-15 with a 40M-share buyback; FANG fell 7.6% in September. |
| **LII/TT** (201020) | 0.6149 | **Earned, end-market mix.** Lennox cut its FY26 EPS guide on 2026-07-29 to $23.00–24.00, with Home Comfort shipments −12%. Deutsche Bank downgraded it to Hold on 09-14 and Wells Fargo initiated at Equal-Weight on 09-25. Residential HVAC destocking against Trane's commercial/data-center exposure is a real business difference, and no dated residential inflection exists. |
| **AAL/DAL** (203020) | 0.8231 | **Earned, and in practice an oil/leverage bet.** AAL has a stockholders' deficit of $3.97B and $28.9B of debt and finance leases, and its operating income does not cover interest; Delta's covers it more than 8×. AAL cut its FY EPS guide in July and recovers less of the fuel increase through fares (~50% vs Delta ~60%). At a September conference AAL's CFO said fuel $1/gal above plan adds ~$1B per quarter. DAL's Q3 call 2026-10-09 appears issuer-announced, but the IR page was not opened (likely-confirmed). |
| **H/MAR** (253020) | 0.7341 | **Mostly earned through estimate cuts, on a weakening hedge** (60d 0.63). Hyatt beat EPS on 07-30 but trimmed net rooms growth to ~6%, and its Mexico all-inclusive recovery is slow. Marriott raised its RevPAR guide to 3–3.5% on 08-03. Hyatt's openings are Q4-weighted, so proof is back-loaded beyond a clean catalyst. |
| **VRT/NVT** (201040) | 0.7135 | **Evidence too thin to advance; momentum against the long.** VRT lagged a further 13.1pp in September on multiple compression and deal concern. It is acquiring UtilityInnovation Group for $1.45B plus up to $1.15B in earn-outs (~13× 2027 EBITDA, close expected Q4 2026). No guidance change was found, NVT's side was not re-verified, and **both legs now carry pending acquisitions**. |
| **ALL/PGR** (403010) | 0.7186 | No identified cause for ALL's −9.0pp 1M lag. PGR's August monthly: net income $951M (−22% y/y), combined ratio 89.3% vs 83.1%. No thesis. |
| **CLX/CHD** (303010) | 0.5511 | Earned. FY26 sales −5.4%, FY27 EPS guide $5.70–6.00 with >$200M of inflation, GOJO-driven leverage, a Sell downgrade and target cuts (Wells Fargo $102 → $90, Citi $100 → $97). The CHD leg was not researched. |
| **KMB/PG**, **NOW/WDAY** | 0.5354 / 0.7507 | Structurally compromised (pending/reported control transactions). See the table above. |
| **VRT/GEV** | 0.6394 | Cross-strategy: GEV is open long in the D book. |

---

## Tier summary and ordering

**TOP-3:** §1 MCHP/ADI (corr 0.8126, best hedge; the reconvergence reversed with no laggard-specific cause found), §2 MDB/SNOW (corr 0.6005; −29.6pp 3M, of which only the 09-28 CEO-departure increment is the thesis), §3 CB/TRV (corr 0.7158, lowest vols; **two issuer-confirmed Q3 prints, 10-16 and 10-21**).

**REST (1):** §4 MTZ/PWR (watch-grade, at the Q3 print).

Total shortlist **4 pairs**: 2 carried forward (both promoted), 2 new. **Six of September's eight were dropped**: DY/EME on D2's standing NO-GO, EFX/TRU on a spread erased by a shared FHFA shock, NOW/WDAY on a take-private-target short leg, COF/AXP on no remaining divergence, PANW/CRWD resolved against the long, and F/GM on a deteriorating long leg.

**Ordering for M4 by reconvergence-indicator proximity:** §3 CB/TRV (**TRV 2026-10-16 CONFIRMED; CB call 2026-10-21 CONFIRMED**) → §4 MTZ/PWR (~late Oct/early Nov, ESTIMATE) → §1 MCHP/ADI (MCHP ~early Nov, ESTIMATE) → §2 MDB/SNOW (CEO appointment undated; earnings ~late Nov/early Dec, ESTIMATE).

**Provenance of dates — the systematic lesson repeats.** Only **two** dates in this shortlist are issuer-confirmed, and both are TRV/CB. Every other date is an aggregator projection for an unclosed quarter. September's one "issuer-confirmed" date (AXP 10-23) could not be re-confirmed this session.

**Execution disposition.** Every advanced leg clears the ADV floor by more than 30× (lowest MTZ ~$323M/day). Individual-stock pairs are feasible on all four. Borrow was **not verified on any short leg** this cycle and must be re-quoted before sizing. **What stands between this shortlist and a live entry is E's binding DO-NOT-ACTIVATE (shock override, `div-E-202608-1`) and the WEAK-breadth leg of its technical gate, not execution and not the pre-mortem.**

---

## Data-provenance and defect notes

- **Integrity audit is now population-wide AND transcription-checked.** See the four checks in PART 1. The new independent re-pull audit (24 series, zero mismatches) closes the one gap the swap and frozen-print detectors cannot see: a worker copying a close wrongly. It is recommended as a standing check.
- **FITB's frozen-print defect is now STABLE across fetches.** It returned the same value (53.42), the same run length (6) and the same window (2026-06-12 → 06-22), with the same missing 2026-06-11 bar, as September. August's window differed. So the "shifting window" diagnosis from September has not reproduced, and the defect now looks pinned to fixed dates. Recorded, not resolved.
- **IBKR window ceiling.** `period=ONE_YEAR` returns 250 bars, and `step_count=253` returned 252 bars for 19 of 24 tickers. The trailing-252-day spec is therefore met at **249 returns (population) / 251 returns (boundary re-measure)**. The boundary re-measure shows no disposition sensitivity to the shortfall, but it is a standing property of the feed and is stated rather than rounded away.
- **IBKR `search_contracts` rate limit — 30 requests/minute (10/second).** Several workers hit it on parallel searches and recovered by batching. Contract IDs are now recorded in the bar files, so next cycle can skip the searches entirely.
- **FMP was not used** (third consecutive cycle unusable per September; not budgeted).
- **Tavily returned HTTP 429 on several research calls** across three workers. These were logged and are counted at rate-card estimate in `ops.web_calls`, so those rows overstate actual credits for the rate-limited calls; whether a 429 bills is not established. The research completeness caveat above stems partly from this.
- **SEC EDGAR recency work remains off-ledger.** It ran via direct HTTPS from the Bash tool and is not representable in `ops.web_calls`, whose `provider` admits only `tavily`/`anthropic`/`fmp`/`hf`. This was already referred last cycle and is not re-filed.
- **UNIVERSE DEFECT, inherited and now flagged: TMUS/CMCSA is not a same-industry-group pair.** T-Mobile is GICS 501020 (Wireless Telecommunication Services, group 5010) and Comcast is 502010 (Media, group 5020). Prior editions carried it as "501010 Telecom". It is below the floor this cycle (0.4254; 60d 0.6996), so nothing turns on it. It should be **removed from the universe** next cycle rather than tracked toward the floor. GICS was not re-derived for every pair (no GICS connector exists), so other inherited labels carry the same unverified status.
- **Screen record.** One `entry_type='research-screen'` row (screen `pair-divergence`) was logged via `ops.sp_log_decision` as `events.decision_log` **`50d589a2-bff6-4353-b565-604599c786de`**. It was read back and verified: `fields` parsed (not NULL, unlike September's first row), `surfaced_count` 7 = `ARRAY_LENGTH(passed)` per the 2026-09-27 §19 correction, 61 `rejected_notable` items (every above-floor rejection, FITB/HBAN included), agreement both 4 / ai_only 3 / rule_only 61.
- **Market cap is still not available from IBKR.** The large-cap limb of the population rail is carried by ADV plus S&P-500 membership, as in prior cycles.

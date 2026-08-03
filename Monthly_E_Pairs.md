2026-08

**THIS FILE SUPERSEDES THE 2026-08-01 EDITION OF THE SAME MONTHLY CYCLE.** M2 ran on 2026-08-01 inside a **broken monthly chain**: M1b halted that morning at 07:03 — two minutes before M2 started at 07:05 — and M4 and M5 subsequently halted on the missing dependency. That screen therefore had no August regime read at all and explicitly carried the **2026-07-01** `state.current_regime` snapshot forward. M1a and M1b completed cleanly today (2026-08-03, 05:13 / 05:35 MT), so this run is the repaired chain and the first M2 edition of the August cycle written against the actual August regime. **Every correlation below was independently re-measured this session rather than carried over.**

**Methodology.** Strategy E is a market-neutral within-industry pair trade (Long laggard L + Short leader S in the same 6-digit GICS industry) screened on: (a) trailing 252-day daily-return correlation — population rail ≥ 0.30, **spec floor ≥ 0.50** per Operating_Protocols.md §19 and Strategy E's frozen Entry criterion 3; (b) both legs reported earnings **or** filed 10-Q/10-K within 90 days (on/after ~2026-05-05); (c) large-cap / adequate ADV per leg; (d) short-financing ≤ 15% of expected thesis return; (e) narrative divergence has materially outpaced fundamental divergence on a **public-information-only** basis. Any candidate whose thesis required non-public provenance was abandoned and noted.

**Scope this cycle: 94 candidate pairs measured, against the prior edition's 28.** Every sector the August file listed as an unreached budget gap was covered — Machinery, Electrical Equipment, Industrial Conglomerates, Energy Equipment & Services, Oil Gas & Consumable Fuels, Consumer Staples Distribution, Food Products, Broadline/Specialty Retail, Hotels Restaurants & Leisure, Professional Services, Commercial Services, Utilities, Capital Markets, Telecom.

---

## The August regime read INVERTS the 2026-08-01 edition's premise

The 08-01 file's headline was that the environment had turned **conducive** to within-industry mean reversion, recorded as a deliberate reversal of the July read. Today's M1b — reading the actual July data the 08-01 run could not see — reaches the opposite conclusion and puts Strategy E at **fundamental DO-NOT-ACTIVATE**:

- `shock_overlay` FLIPPED latent → **acute**; `growth_momentum` FLIPPED stable → decelerating; `inflation_trend` FLIPPED reaccelerating → stable. Three of five axes moved — M1b calls it "the largest single-month regime change in the recorded series." Integrative: **"stagflationary shock + hawkish policy."**
- M1b's E-specific reasoning attacks E's mechanism directly: Brent +20.5% / WTI +22.2% on a Hormuz transit collapse, then a 5–7% give-back on the 2026-08-02 called-off strike; plus large-cap growth −6.57% against equal-weight +1.05%. Both are **common-factor** moves that "move both legs of a pair together — compressing exactly the intra-group dispersion E monetises."
- It further argues the correlation-stationarity condition behind Entry criterion 3 is stressed: another regime break inside the trailing-252-day window, on top of the February tariff-IEEPA ruling and the February–June Iran conflict.
- **All five roster strategies are fundamentally DO-NOT-ACTIVATE — the first time in the recorded lineage.** All five carry a Tech-ACTIVATE / Fund-DO-NOT-ACTIVATE divergence and are queued to PENDING_REVIEW.

E's technical router still passes (SPY Trend UP ≠ DOWN, VIX 15.99 ≠ HIGH, Breadth HEALTHY ~67%). E's *operative* router state remains ACTIVATE (substantive) + execution-feasibility-deferred from `div-E-202606-1` until the new divergence review adjudicates. **E's activation is sub judice, and this screen does not prejudge it — M1b sets activation, not M2.**

### This screen TESTS M1b's stationarity claim rather than asserting against it

M1b's objection is empirical and therefore checkable. Every pair below carries **both** a 252-day and a **rolling 60-day** correlation. Where the 60-day sits materially below the 252-day, the hedge is decaying *now* — and E's own frozen exit rule fires when the rolling 60-day falls below 0.30. That uses a number already in the spec rather than a screen tune.

**RESULT: M1b's conclusion is right, but one of its two stated supports is empirically WRONG — and the true reason is the OPPOSITE of the one given.**

Across **89 measurable pairs**, the rolling 60-day correlation is **HIGHER** than the trailing 252-day in **66 (74%)**, lower in 21, flat in 2.

| Sector batch | pairs | 60d > 252d | 60d < 252d | ≥ 0.50 spec floor |
|---|---|---|---|---|
| Financials | 12 | 7 | 4 (1 flat) | 11 |
| Technology / Semis / Software | 13 | **13 — every single one** | 0 | 9 |
| Health Care | 14 | 12 | 2 | **5 only** |
| Industrials | 13 | 7 | 6 | 11 |
| Materials / Energy / Utilities / Retail / Staples | 14 | 12 | 2 | 11 |
| Consumer / Media / Homebuilders | 13 | 7 | 5 (1 flat) | 7 |
| Fresh Q2 divergence candidates | 10 | 8 | 2 | 7 |
| **TOTAL** | **89** | **66 (74%)** | **21** | **61** |

*(Note on grouping: the batch columns above follow the measurement batches; PART 1A below groups the same pairs by GICS sector, so RJF/LPLA and HAL/BKR appear under Financials and Materials/Energy there while counting in the "Fresh Q2" batch here. The 89 and 61 totals are the same either way.)*

Two distinct claims in M1b's E paragraph must be separated, because the measurement answers them in **opposite** directions:

1. **"The correlation-stationarity condition behind Entry criterion 3 is further stressed."** — **REFUTED.** Correlations are not destabilising downward; short-window correlation is rising almost everywhere, most emphatically in technology/semis where **all 13 pairs tightened**. On the specific condition Entry criterion 3 encodes, pairs are **better** hedged today than the trailing year implies. Only three pairs show a genuine hedge breakdown worth acting on: ILMN/DHR (0.318 → **0.132**), ACM/J (0.631 → 0.437) and CR/ITW (0.470 → 0.386).
2. **"Common-factor moves compress exactly the intra-group dispersion E monetises."** — **SUPPORTED, and the rising correlation is itself the evidence for it.** Higher within-group correlation means less idiosyncratic separation to harvest. A pair that hedges near-perfectly also converges to near-zero expected spread return.

So M1b reaches the right verdict for a reason it did not state. The honest formulation: **E's *hedge* is in unusually good condition right now, and that is precisely why its *edge* is thin.** This is a materially different diagnosis from "the pair relationship is breaking," and it points at a different remedy — the constraint is dispersion supply, not hedge quality. Recorded as a correction to M1b's stated reasoning, **not** to its call.

### Sector capacity findings (about where E can *ever* work, not just this month)

- **HEALTH CARE is structurally not a pair sector.** Only 5 of 14 pairs clear the floor. PFE/LLY (0.350), BIIB/VRTX (0.333), ILMN/DHR (0.318), PODD/DXCM (0.358) sit below even the 0.30 population rail. Single-asset pipeline, trial-readout and reimbursement risk dominates common variance.
- **MEDIA & ENTERTAINMENT is a dead zone.** **WBD/NFLX measures −0.141 (negative)**, EA/TTWO 0.204 with a 60-day of −0.071, LYV/SPOT 0.138, PARA/FOXA 0.226. A shared media GICS code carries no hedging information whatsoever — these are anti-hedges, not weak hedges.
- Roughly a quarter of the nominal universe is structurally unsuited to E. Future cycles should weight the sweep toward **banks, insurers, chemicals, semis and industrials**, where 9–11 of every 12–14 pairs clear the floor.

---

## Status gates standing between this shortlist and any live entry

Stated up front so nothing below reads as trade-ready:

1. **`state.trading_enabled = FALSE`** (halt_reason: "state.freshness marks_fresh/engine_fresh not both TRUE"). M2 stages nothing, so this does not gate the screen.
2. **Fundamental DO-NOT-ACTIVATE for E this month**, divergence review pending. Per M4 section A, a FLIP TO DO-NOT-ACTIVATE supersedes pending thesis-construction entries for that strategy. **PART 2 is research feedstock for E's reactivation, not a queue to drain into orders.**
3. **E's pre-mortem is in an open TIER 1 DEFECT — REVISION REQUIRED (cycle 5, 2026-07-30)**: E's Rev-43 sizing edit "omits the CaR envelopes, the mandatory attack-on-size step, and item 2.28" that D's parallel edit includes. Queue item `revise-premortem-E-2026-a3`, conservative_default NO-EDIT. The envelope arithmetic below is drawn from `Experiment_Parameters.md` and `Strategy.md`, **not** from E's own slice — which is precisely the self-containment gap under revision.

---

## EXECUTION — the standing "execution-feasibility-deferred" qualifier should now be DISCHARGED

The August edition left this open: "individual-stock execution is arithmetically inside the envelopes **IF** IBKR permits fractional short sales — that question is unresolved." Two full document-research passes then reached **opposite** conclusions. An operator-driven Client Portal session (read-only; order tickets previewed and cancelled, **never transmitted**) settled it in minutes.

### 1. Fractional shorts: PERMITTED

A `SELL 0.25 AMD` ticket accepted the decimal quantity without rounding, previewed at ~$115.79 value, and **the balances panel modelled the position going 0 → −0.25** — the platform explicitly treating it as *opening a new short* (category c, not a long liquidation). No shortability warning; only a generic price-collar notice. `BUY 0.25 AMD` behaved identically in the opposite direction. Account permission "Global (Trade in Fractions)" confirmed **enabled**.

This **refutes** an external adversarial audit's REFUTED verdict, which reasoned from Form 4231's purchase-only language plus a securities-lending whole-share-block argument. *Method note, recorded because it generalises: one order-ticket preview beat two deep-research passes, and the arguments-from-mechanism on both sides proved unreliable.* Residual caveat stated honestly — a preview is not a fill; the ticket accepting and modelling the short does not absolutely prove the locate/routing engine would not reject on transmit.

### 2. The commission rule: resolved, and it is the CHEAP reading

Five live previews reconcile every contradictory reading, **including IBKR's own two published examples**. The operative rule is the standard schedule, not footnote 11's literal text:

> **commission = clamp(per-share rate, min $0.35 Tiered, max 1% of trade value)**, with a $0.01 absolute floor on fractional orders.

| Order (live preview) | Trade value | 1% cap | $0.35 min | Binds | Charged |
|---|---|---|---|---|---|
| F 0.5 sh | $7.43 | $0.074 | $0.35 | cap | ~$0.07 |
| F 1.1 sh | $16.35 | $0.164 | $0.35 | cap | ~$0.16 |
| F 2 sh (whole) | $29.72 | $0.297 | $0.35 | cap | ~$0.30 |
| **AMD 0.25 sh** | $115.79 | $1.158 | $0.35 | **min** | **$0.35** |
| **AMD 1.1 sh** | $513.47 | $5.135 | $0.35 | **min** | **$0.35** |

IBKR's two published footnote-11 examples ($5.00 → $0.05; $0.75 → $0.01) are **both tiny orders where the 1% cap falls below the $0.35 minimum** — which is why the published text reads as though 1% were a floor. It is not. **Break-even is a $35 trade value**; above it, a fractional order pays a flat $0.35 like any other. There is no fractional surcharge, and the sub-1-share-versus-mixed-order distinction that consumed two research passes is **moot** — AMD at 0.25 sh and at 1.1 sh both charged $0.35.

**Corrected pair economics.** Legs of ~$180 long / ~$150 short are both far above the $35 break-even, so each of the four round-trip orders costs $0.35:

> **round trip = 4 × $0.35 = $1.40 on ~$330 gross = 0.42% of gross exposure**

**RETRACTION.** This file previously carried ~2.0% and concluded E was fee-dominated at this book size. That is **wrong and withdrawn.** Against realistic pair convergence of 5–10%, fee drag is **~4–8% of expected return** — comfortably inside Entry criterion 5's 15%-of-return ceiling. A corollary also dies: the hypothesis that E should prefer legs priced below the per-leg budget is dead, because a 0.25-share order and a 2.2-share order cost the same $0.35. **Leg share price is irrelevant to cost.**

### 3. Short borrow: measured, and immaterial

Live SLB readings (8 of 24 short-leg candidates sampled before the session expired):

| Ticker | Shares available | Fee rate | | Ticker | Shares available | Fee rate |
|---|---|---|---|---|---|---|
| NVT | 3,200,000 | 0.4081% | | ALL | 3,100,000 | 0.2505% |
| TRU | 1,800,000 | 0.25% | | MTB | 1,800,000 | 0.4276% |
| EOG | 6,200,000 | 0.4081% | | DAL | 6,900,000 | 0.4135% |
| LMT | 2,100,000 | 0.25% | | IP | 2,100,000 | 0.25% |

All general collateral, ample availability, none flagged. On a $150 short leg held three months at 0.43%, financing costs **~$0.16** — roughly two orders of magnitude below anything threatening Entry criterion 5. The unsampled 16 share the same large-cap GC profile and rates must be re-quoted at entry regardless, so the sample is treated as sufficient. **CRWD is the one name worth an individual check before any entry** — reported short interest rose ~284% MoM — and is the only plausible special-borrow candidate in the set.

### 4. ETF substitution and the NTF program: both CLOSED as negatives

US-listed ETFs are fractional-eligible and billed under the **same** rules as individual stocks, so substitution was never a fee escape. The IBKR fee-waived NTF program (reimburses commissions on ETF shares held ≥30 days) spans 10 fund families; three were checked in full and **no broad US sector ETFs** appear in any of them. The hypothesis that E's 1–6 month holding period uniquely clears the 30-day bar was correct in principle and **moot in practice**. Recorded as a closed negative so no future cycle re-opens it.

### 5. Further operational constraints on fractional legs

- **Fractional shares are NOT ACATS-transferable** — any broker transfer forces liquidation first (a commission and a taxable event).
- **Unmarketable limit orders may leave the fractional component UNFILLED.** For a two-leg market-neutral pair this is a first-order risk, not a nuisance: a partially-filled pair is a **naked directional leg**, exactly what E's structure exists to prevent and what its Rev-41 partial-trim rule forbids creating. Any live E entry must account for leg-fill asymmetry.
- No voting rights and no voluntary corporate-action elections on fractional holdings.

### Consequence for the pending divergence review

E has carried a router qualifier since `div-E-202606-1`: *ACTIVATE (substantive) + **execution-feasibility-deferred***, justified by "$37.79/leg, ETF-substitution-required at ~$1.9k book." **That rationale is now dead three times over** — fractional shorts are permitted, round-trip cost is 0.42% not 2.0%, and borrow is 0.25–0.43%. The execution-feasibility question that has gated E for two months is **answered affirmatively and the deferral should be discharged rather than rolled forward.** The remaining blockers are purely non-execution: the fundamental DO-NOT-ACTIVATE call, `trading_enabled=false`, and the open Tier-1 pre-mortem defect. M1b's DO-NOT-ACTIVATE reasoning is about **regime**, not feasibility; the two should stop being conflated.

---

## Sizing envelopes

`analytics.strategy_nav` 2026-08-03: E NAV **$2,220.01**, deployed $0, available $2,220.01, realized/unrealized P&L 0. **E has never traded.**

- Per-name aggregate CaR ≤ 10% of strategy portfolio → **$222.00** combined per pair
- Per-strategy total deployed CaR ≤ 75% → **$1,665.01**
- CaR(pair) = long notional + (short notional × the 25% short-stop distance), both legs sized to the hedge ratio and counted **once** (Experiment_Parameters.md rev 18 / Rev 43)

## Cross-strategy conflicts (open book as of 2026-08-03)

Strategy E's own book is **empty**, so "exclude pairs where either leg is in the open E book" excludes nothing. But the open B/D book creates real conflicts the 08-01 edition could not have seen:

- **MTZ is OPEN in the B book** (`B:MTZ:2026-08-03`, staged today) — the 08-01 edition's #1 TOP long leg. Combined with the independent finding below that MTZ/PWR should drop on its merits, this is a second reason to keep E away from a long MTZ.
- **GEV is OPEN in the D book** (`D:GEV:2026-08-03`, staged today). This **kills the VRT/GEV pair** surfaced by this cycle's discovery sweep: an E short of GEV against a D long of GEV largely nets out at book level. Recorded, not advanced.
- **CRM is OPEN in the D book** — appears only as prior-cycle below-floor context, never advanced.

## Structurally invalid pairs — permanent exclusion list

Three candidate pairs are not data failures but structurally dead and should never be re-probed:

| Pair | Reason |
|---|---|
| **SYF/DFS** | DFS delisted by the Capital One / Discover merger; no live IBKR listing (only a frozen `VALUE`-exchange reference entry) |
| **SPR/HWM** | SPR delisted by Boeing's acquisition of Spirit AeroSystems |
| **JNPR/ANET** | JNPR delisted by HPE's acquisition of Juniper Networks |

Ticker/entity notes: **BK now lists as BNY**; **PARA's successor is PSKY** (Paramount Skydance), whose IBKR history starts 2025-08-07 — a real, benign 3-day merger offset.

---

# PART 1 — measured population

All figures measured this session from IBKR daily closes, **249 aligned daily log-return observations**, window 2025-08-04 → 2026-07-31. Pearson correlation on log returns; beta = OLS slope of A on B; vol annualized ×√252. "1M" = 2026-07-01 → 2026-07-31. "3M" = 2026-05-01 (or nearest) → 2026-07-31. Spread = A minus B in percentage points.

**Layer-1 population rail (mechanical, a cost bound):** same 6-digit GICS industry, 252-day correlation ≥ 0.30, large-cap with adequate ADV, both legs reported earnings or filed 10-Q/10-K within 90 days.
**Spec floor (mechanical, derived from frozen Entry criterion 3):** 252-day corr ≥ 0.50 to be eligible to advance.

## PART 1A — ABOVE the 0.50 spec floor (61 pairs)

### Financials

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 401010 Banks | RF/KEY | 0.886 | 0.838 | 0.901 | 24.4% | 24.0% | +3.33 | +6.50 | 30.95 | 22.59 |
| 401010 Banks | USB/PNC | 0.870 | 0.906 | 0.905 | 22.6% | 21.8% | +2.39 | −1.29 | 63.01 | 249.87 |
| 401010 Banks | TFC/MTB | 0.847 | 0.846 | 0.939 | 24.3% | 21.9% | +0.07 | **−12.00** | 51.84 | 246.29 |
| 402030 Capital Markets | STT/BNY | 0.785 | 0.818 | 0.915 | 24.8% | 21.4% | +1.48 | +4.30 | 184.16 | 156.33 |
| 402020 Consumer Finance | COF/AXP | 0.769 | 0.755 | 0.926 | 32.6% | 27.0% | +5.42 | +3.73 | 209.01 | 336.25 |
| 403010 Insurance | ALL/PGR | 0.734 | 0.828 | 0.660 | 24.3% | 27.0% | **+14.78** | **+15.85** | 264.08 | 211.42 |
| 403010 Insurance | MET/PRU | 0.722 | 0.809 | 0.747 | 23.8% | 23.0% | +0.33 | −3.97 | 96.13 | 122.08 |
| 403010 Insurance | TRV/CB | 0.715 | 0.738 | 0.764 | 20.6% | 19.3% | **+12.17** | **+15.36** | 374.36 | 350.68 |
| 402010 Capital Markets | RJF/LPLA | 0.709 | 0.751 | 0.490 | 25.4% | 36.8% | −9.36 | +1.66 | 175.98 | 353.70 |
| 401010 Banks | WFC/C | 0.695 | **0.644** | 0.633 | 26.7% | 29.2% | +6.07 | +3.05 | 86.45 | 132.45 |
| 403010 Insurance | AIG/HIG | 0.549 | 0.752 | 0.703 | 24.7% | 19.2% | −3.39 | −4.73 | 78.58 | 141.91 |
| 402030 Capital Markets | BEN/TROW | 0.534 | **0.430** | 0.581 | 27.7% | 25.5% | +3.17 | +5.42 | 33.86 | 111.75 |

### Technology / Semiconductors / Software

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 453010 Semis | QRVO/SWKS | **0.952** | **0.989** | 0.763 | 36.4% | 45.4% | +5.20 | +7.10 | 90.57 | 62.28 |
| 453010 Semi Equip | LRCX/KLAC | 0.870 | 0.905 | 0.912 | 62.9% | 60.0% | +6.20 | +8.20 | 293.02 | 182.82 |
| 453010 Semis | MCHP/ADI | 0.802 | 0.869 | 1.074 | 47.4% | 35.4% | −10.70 | **−13.30** | 74.29 | 367.41 |
| 451030 Software | PANW/CRWD | 0.783 | 0.871 | 0.669 | 40.8% | 47.7% | −4.50 | +15.70 | 331.83 | 190.86 |
| 451030 Software | WDAY/NOW | 0.780 | 0.867 | 0.703 | 49.5% | 54.9% | **+18.00** | +4.30 | 160.34 | 111.23 |
| 453010 Semis | ON/NXPI | 0.745 | 0.817 | 0.972 | 62.6% | 47.9% | +4.20 | +1.60 | 81.61 | 229.16 |
| 453010 Semi Equip | TER/AMAT | 0.732 | 0.870 | 0.907 | 74.1% | 59.8% | +8.00 | **−24.00** | 367.69 | 507.67 |
| 451030 Software | FTNT/CRWD | 0.628 | 0.726 | 0.611 | 46.4% | 47.7% | +3.10 | +20.10 | 161.95 | 190.86 |
| 451030 Software | MDB/SNOW | 0.580 | 0.659 | 0.662 | 72.0% | 63.1% | −18.40 | **−79.90** | 337.48 | 293.28 |

### Health Care (only 5 of 14 clear the floor)

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 351020 Distributors | COR/MCK | 0.714 | 0.730 | 0.760 | 32.1% | 30.2% | −3.50 | −2.80 | 311.34 | 856.19 |
| 352030 Life Sci Tools | RVTY/TMO | 0.706 | **0.649** | 0.881 | 38.1% | 30.6% | **−12.20** | +7.40 | 112.52 | 574.30 |
| 351020 Managed Care | ELV/UNH | 0.659 | 0.662 | 0.613 | 36.1% | 38.8% | −6.80 | −11.50 | 375.84 | 414.40 |
| 351020 Managed Care | CNC/MOH | 0.550 | 0.634 | 0.485 | 49.2% | 55.7% | +6.90 | **+15.10** | 62.22 | 195.62 |
| 351010 HC Equipment | BAX/BDX | 0.526 | 0.634 | 0.873 | 44.0% | 26.5% | +12.30 | **+41.10** | 26.16 | 165.62 |

### Industrials

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 203020 Airlines | AAL/DAL | 0.827 | 0.853 | 1.014 | 48.7% | 39.7% | −9.83 | +2.21 | 15.27 | 87.44 |
| 203040 Ground Transport | XPO/ODFL | 0.758 | 0.778 | 0.865 | 43.7% | 38.3% | −0.27 | −9.72 | 200.97 | 212.14 |
| 201030 Constr & Eng | MTZ/PWR | 0.742 | **0.680** | 0.892 | 50.9% | 42.4% | **−29.17** | **−26.88** | 263.10 | 667.36 |
| 201010 Aero & Defense | NOC/LMT | 0.692 | 0.706 | 0.670 | 26.4% | 27.3% | −7.34 | **−18.16** | 542.48 | 582.74 |
| 201060 Machinery | DOV/IR | 0.662 | **0.556** | 0.539 | 26.5% | 32.6% | −8.90 | −16.29 | 204.62 | 83.38 |
| 203010 Air Freight | FDX/UPS | 0.659 | 0.641 | 0.637 | 28.7% | 29.6% | +2.79 | +0.08 | 307.40 | 104.22 |
| 201060 Machinery | SWK/ITW | 0.652 | **0.556** | 1.162 | 38.6% | 21.7% | −3.14 | +8.12 | 94.58 | 286.95 |
| 201030 Constr & Eng | ACM/J | 0.631 | **0.437** | 0.658 | 34.6% | 33.2% | +0.01 | −18.59 | 72.39 | 134.93 |
| 201020 Bldg Products | LII/TT | 0.615 | 0.667 | 0.925 | 42.7% | 28.3% | **−21.06** | −14.50 | 415.88 | 454.95 |
| 201030 Constr & Eng | DY/EME | 0.569 | 0.544 | 0.632 | 49.2% | 44.3% | −13.90 | +4.24 | 401.07 | 797.43 |
| 201060 Machinery | CMI/PCAR | 0.532 | 0.539 | 0.704 | 36.5% | 27.6% | −16.49 | −17.84 | 634.20 | 132.68 |

### Materials / Energy / Utilities / Retail / Staples

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 151010 Chemicals | DOW/LYB | 0.882 | 0.907 | 0.910 | 44.9% | 43.5% | −5.97 | −7.60 | 30.29 | 62.08 |
| 101020 E&P | DVN/EOG | 0.841 | 0.892 | 1.058 | 34.1% | 27.1% | −3.51 | **−17.75** | 45.13 | 148.69 |
| 302020 Food | CAG/GIS | 0.789 | 0.821 | 0.889 | 30.1% | 26.8% | +6.82 | +0.23 | 14.51 | 35.75 |
| 101020 E&P | APA/FANG | 0.757 | 0.844 | 1.097 | 45.9% | 31.7% | −0.92 | −4.74 | 37.32 | 202.95 |
| 151010 Chemicals | PPG/SHW | 0.732 | 0.718 | 0.817 | 30.1% | 27.0% | −8.36 | −4.39 | 110.52 | 340.85 |
| 151030 Packaging | IP/PKG | 0.721 | 0.834 | 1.104 | 43.5% | 28.4% | +3.17 | **+15.82** | 40.83 | 245.84 |
| 101010 Energy Equip | HAL/SLB | 0.696 | 0.674 | 0.711 | 35.5% | 34.8% | **−12.28** | −9.71 | 32.25 | 49.59 |
| 551010 Utilities | EXC/AEP | 0.686 | 0.805 | 0.700 | 19.2% | 18.8% | +4.38 | +5.16 | 45.82 | 127.85 |
| 255030 Broadline Retail | DLTR/DG | 0.634 | 0.711 | 0.711 | 41.0% | 36.6% | −5.28 | **+23.34** | 127.21 | 127.05 |
| 101010 Energy Equip | HAL/BKR | 0.609 | **0.544** | 0.666 | 35.5% | 32.5% | **−14.70** | −10.10 | 32.25 | 60.49 |
| 151010 Chemicals | EMN/CE | 0.592 | 0.607 | 0.359 | 33.8% | 55.6% | +5.32 | **+25.64** | 69.95 | 44.72 |
| 151040 Metals | CLF/NUE | 0.518 | 0.659 | 1.165 | 69.0% | 30.7% | +4.82 | −4.22 | 11.52 | 257.29 |

### Consumer / Homebuilders / Staples

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 252010 Homebuilders | KBH/DHI | 0.852 | 0.812 | 0.935 | 38.4% | 35.0% | −0.41 | **+11.48** | 54.97 | 143.06 |
| 253020 Hotels | H/MAR | 0.764 | **0.698** | 0.986 | 33.9% | 26.3% | −10.03 | +1.28 | 174.06 | 372.83 |
| 252010 Homebuilders | TOL/NVR | 0.719 | 0.775 | 0.887 | 34.1% | 27.7% | +0.18 | +4.44 | 145.89 | 6147.05 |
| 255040 Specialty Retail | ROST/TJX | 0.588 | 0.652 | 0.769 | 25.6% | 19.6% | **+14.53** | +9.39 | 251.07 | 157.34 |
| 251020 Automobiles | F/GM | 0.576 | **0.510** | 0.638 | 36.9% | 33.3% | −10.04 | +6.29 | 14.68 | 88.86 |
| 303010 Household Prod | CLX/CHD | 0.548 | 0.693 | 0.720 | 29.9% | 22.8% | −2.57 | +6.76 | 95.53 | 98.81 |
| 303010 Household Prod | KMB/PG | 0.538 | 0.727 | 0.749 | 27.2% | 19.5% | +0.08 | **+13.80** | 109.31 | 144.49 |

### Fresh Q2-2026 divergence candidates (discovery sweep)

| GICS | Pair (A/B) | 252d | 60d | β | vol A | vol B | 1M spr | 3M spr | Last A | Last B |
|---|---|---|---|---|---|---|---|---|---|---|
| 202020 Prof Services | EFX/TRU | 0.845 | 0.878 | 0.785 | 39.0% | 42.0% | +0.87 | **−12.18** | 172.62 | 78.62 |
| 201040 Electrical Equip | VRT/NVT | 0.697 | **0.825** | 1.022 | 64.4% | 43.9% | **−18.58** | **−23.22** | 241.57 | 153.83 |
| 201040 Electrical Equip | HUBB/NVT | 0.641 | 0.669 | 0.458 | 31.4% | 43.9% | +0.27 | −3.85 | 472.55 | 153.83 |
| 201040 Electrical Equip | VRT/GEV | 0.626 | 0.678 | 0.777 | 64.4% | 51.9% | −9.73 | −19.58 | 241.57 | 990.29 |
| 201040 Electrical Equip | VRT/HUBB | 0.559 | 0.631 | 1.146 | 64.4% | 31.4% | **−18.84** | **−19.36** | 241.57 | 472.55 |

## PART 1B — BELOW the 0.50 spec floor, 0.30–0.49 band — CONTEXT / SL1 IDEATION ONLY

Per §19 the 0.50 bar **derives from** Strategy E's spec_hash-frozen Entry criterion 3 and is **not** a screen tune. These are recorded `below_spec_floor=true` and are **never** entry candidates. §19 caps this at **3 per call**, binding both this table and the fields-JSON `passed` items — the same three pairs appear in both.

| Pair | 252d | 60d | Why it is recorded anyway |
|---|---|---|---|
| **AMD/NVDA** (453010) | **0.492** | 0.567 | **Third consecutive month below the floor** (0.49 June, 0.4933 July, 0.492 now). Was July's best-performing thesis (+13.6pp) — a standing example of a genuinely profitable idea E's own frozen criterion correctly refuses to call a pair. At three months this is an **established sub-floor pattern**, not a monthly novelty, and is exactly the judgment-native Redesign-B ideation evidence §19 contemplates. |
| **AAP/ORLY** (255040) | **0.499** | 0.545 | Misses by **0.001**. Deliberately **not** rounded up — the same discipline applied to AVGO/MRVL's 0.4963 last cycle. Recorded to make the point that the floor is mechanical and is not negotiated at the third decimal. (BMY/MRK also landed on 0.499 and is likewise held below the rail.) |
| **ZBH/SYK** (351010) | **0.493** | **0.735** | The **widest 60d-over-252d gap in the entire 89-pair population (+0.242)**. The trailing window — which spans the February tariff-IEEPA ruling and the Feb–June Iran conflict — materially **understates** this pair's current hedge quality. The cleanest live illustration that a trailing-window and a current-regime correlation can disagree by enough to flip a gate. It still does not advance, because the spec floor is defined on the 252-day number. |

## PART 1C — BELOW the 0.30 population rail — OUT OF POPULATION

Recorded compactly because the **negative result is itself the finding**.

| Pair | 252d | 60d | Note |
|---|---|---|---|
| WBD/NFLX (502020) | **−0.141** | −0.017 | **Negative.** The two legs of the "same" media industry move in opposite directions. |
| LYV/SPOT (502020) | 0.138 | 0.271 | Media dead zone. |
| EA/TTWO (502020) | 0.204 | −0.071 | 60-day goes **negative**. |
| PARA/FOXA (502020) | 0.226 | 0.182 | Media dead zone; PARA is now PSKY post-merger. |
| YUM/QSR (253020) | 0.275 | 0.275 | Restaurants: no common variance. |
| NDAQ/CME (402030) | 0.317 | 0.503 | Exchanges diverge structurally (listings vs derivatives volume). |
| ILMN/DHR (352030) | 0.318 | **0.132** | **Sharpest hedge breakdown in the population.** |
| KDP/MNST (302010) | 0.324 | 0.407 | |
| BIIB/VRTX (352010) | 0.333 | 0.468 | Biotech single-asset risk dominates. |
| PFE/LLY (352020) | 0.350 | 0.527 | Large pharma: pipeline idiosyncrasy dominates. |
| PODD/DXCM (351010) | 0.358 | 0.420 | 3M spread −41.6pp on a non-pair. |
| SBUX/CMG (253020) | 0.360 | 0.485 | |
| TMUS/CMCSA (501010) | 0.375 | 0.465 | |
| INTC/TXN (453010) | 0.411 | 0.674 | |
| PCG/NEE (551010) | 0.443 | 0.590 | PCG's wildfire-liability idiosyncrasy dominates. |
| MDT/BSX (351010) | 0.445 | 0.638 | |
| TXT/GD (201010) | 0.462 | 0.500 | |
| GILD/AMGN (352010) | 0.468 | 0.615 | |
| CR/ITW (201060) | 0.470 | **0.386** | Strong same-day-print narrative from the discovery sweep — **and not a pair.** Below floor **and** decaying. |
| HPQ/DELL (452020) | 0.473 | 0.497 | |
| EFX/VRSK (202020) | 0.481 | 0.694 | Weaker expression of the EFX thesis; EFX/TRU at 0.845 dominates it. |
| MAS/CARR (201020) | 0.493 | 0.598 | |
| CVS/CI (351020) | 0.495 | 0.582 | |
| MRVL/AVGO (453010) | 0.496 | 0.595 | Second consecutive month just under the floor. |
| BMY/MRK (352020) | 0.499 | 0.680 | Misses by 0.001. Not rounded. |

## PART 1D — unmeasurable / withheld

| Pair | Reason |
|---|---|
| SYF/DFS, SPR/HWM, JNPR/ANET | Delistings — structurally invalid, permanent exclusion (above) |
| **NCLH/RCL** | **Confirmed corrupt series** — RCL's contract id returns SPOT's data, reproducing on sequential solo calls. Withheld. |
| **FITB/HBAN** | FITB carries a frozen-print IBKR defect (identical 53.42 close for six sessions, 2026-06-24 → 07-01, reproduced on independent re-fetch). Correlation and vol biased low. **Excluded on data quality, not thesis.** |

## PART 1E — reconciliation of the 2026-08-01 shortlist

| Prior pair | Prior tier | Status | Reason (public-information) |
|---|---|---|---|
| MTZ/PWR (0.742) | TOP | **DROP** | **The single largest reversal this cycle.** MTZ's gap-down traced to a genuine guidance shortfall and a sizeable analyst target cut (JPM −33%), while PWR simultaneously beat and was upgraded. That is the **earned** divergence pattern the strategy exists to avoid, not a narrative one. Second, independent reason: **MTZ is now long in the B book.** Both legs now confirmed reporting 2026-10-29. |
| CB/TRV (0.715) | TOP | **KEEP — TOP** | No disqualifying news; fresh sell-side downgrades on TRV strengthen the short leg. CB Q3 confirmed 2026-10-20. |
| PPG/SHW (0.732) | TOP | **KEEP — demoted to REST** | SHW (short leg) had the stronger, cleaner quarter — the beginning of the same earned pattern that killed MTZ/PWR, at smaller magnitude. SHW Q3 confirmed 2026-10-27; PPG same-day is a Zacks **estimate**, not confirmed. |
| PANW/CRWD (0.783) | REST | **KEEP** | **PANW FQ4 confirmed 2026-08-24** (a MarketBeat "Aug 17" is a labelled template estimate and is wrong). **CRWD FQ2 confirmed 2026-09-02.** Correction: aggregators calling the CyberArk deal an "August 2026" event are wrong — it **closed 2026-02-11**. |
| COF/AXP (0.769) | REST | **KEEP, flagged** | COF Q3 confirmed 2026-10-20; AXP Q3 confirmed 2026-10-23. COF's discount looks partly credit/integration-driven rather than purely narrative. |
| FTNT/CRWD (0.628) | REST | **KEEP** | FTNT's beat is a positive skepticism-check result. Structurally mutually exclusive with PANW/CRWD. |
| WFC/C (0.695) | REST | **KEEP** | **C's Q2 10-Q still UNFILED as of 2026-08-03 — verified directly against SEC EDGAR** (most recent is Q1, period ended 2026-03-31, filed ~2026-05-07). Both report Q3 on the same day, **2026-10-13**, confirmed from both issuers independently. A reported Fed lifting of WFC's asset cap could **not** be date-verified and is flagged unverified rather than relied upon. |
| ELV/UNH (0.659) | REST (bottom) | **DROP this cycle** | **UNH's Q2 10-Q still UNFILED as of 2026-08-03 — verified against SEC EDGAR** (most recent Q1, filed 2026-05-15). Dropped not on a data failure but on fit: third consecutive month moving against, and UNH's discount is substantially a **disclosed regulatory/litigation risk premium** (unresolved criminal + civil DOJ MA-billing investigation, plus the Claritev antitrust probe reported 2026-07-16) — a legitimate public fact pattern rather than a narrative mispricing. Displaced by MCHP/ADI. |
| LII/TT (0.615) | REST | **DEMOTE → not advanced** | Same pattern as MTZ/PWR at smaller scale: the long leg cut guidance on a real end-market problem (residential HVAC), the short leg beat and raised on a real one (commercial/data-center bookings). Fundamental divergence, not narrative. |
| COR/MCK (0.714) | REST | **KEEP — promoted to TOP** | **Both dates confirmed from each issuer's own IR release: 2026-08-05** (COR pre-market, MCK after close). The most live catalyst of any pair in the screen. |

---

# PART 2 — Ranked shortlist of divergence theses (public-information-only)

**How this ranking was produced.** Twelve **new** candidate pairs were researched from public sources by independent agents, then put through **three adversarial critics** — a public-source provenance auditor (Strategy E disadvantage 2.6), an earned-gap skeptic, and a numbers/dates fact-checker. **Seven of the twelve were rejected or dropped.** The prior ten-pair shortlist was separately reconciled (PART 1E). Every surviving pair carries an explicit earned-case counter-argument; **a pair with no stated counter-argument was not allowed to advance.**

**Tier coding.** **TOP** = highest-conviction narrative-outpaces-fundamental thesis with a dated public catalyst and a correlation comfortably above the spec floor. **REST** = supportive but carrying a correlation, valuation-decay, catalyst-timing or thesis-purity caveat. M4 reads this section verbatim, ordered by reconvergence proximity. All ten meet the ≥0.50 spec floor on measured 252-day correlation.

### 1) Long COR / Short MCK — Health Care Distributors (351020) — **TOP (carry-forward)**
- **(a) L/S.** **MCK = leader/short** (~$856.19; FQ4 2026-05-07 adj EPS $11.69 vs $11.57 — a bare 1% beat — on a revenue **miss**; +11.5% across July; ~19.4× forward, plus a new $5.0B buyback). **COR = laggard/long** (~$311.34; FQ2 2026-05-05 adj EPS $4.75 and revenue both missed on GLP-1/biosimilar mix, but FY26 EPS guidance was **raised** to $17.65–17.90; fell ~16.7% on the print).
- **(b) Divergence thesis.** Corr **0.714**, 60d **0.730** (stable), β 0.761. McKesson's richer multiple rests on an AI/specialty-oncology narrative and capital return rather than on the quarter itself, which was a 1% EPS beat on a revenue miss. Cencora delivered comparable underlying growth (adj EPS +7.5% YoY) and **also** raised guidance, and was marked down for a mix effect it characterised as temporary.
- **(c) Reconvergence indicators.** (i) **BOTH report 2026-08-05 — confirmed this session from each issuer's own IR release.** Two days out; resolves much of the thesis in one session, in either direction. (ii) Cardinal Health FQ4 (~mid-Aug) as a three-way read-through. (iii) Public CMS / GLP-1 reimbursement developments.
- **(d) Borrow/cost fit.** MCK not in this cycle's live SLB sample; large-cap GC, no evidence of special borrow. Sampled peers ran 0.25–0.43%, immaterial against the 15%-of-return ceiling. Re-quote at execution.
- **(e) Execution.** Individual-stock, fractional both legs; ~$0.35/order. Both legs' filings (early May) are the **oldest** in the advanced set — the 08-05 print re-establishes recency for both at once.
- **(f) Tier: TOP.** First on catalyst proximity, not divergence magnitude (−3.50pp 1M). **Honest risk:** distributor mix is opaque even in filings; if MCK's specialty/oncology mix genuinely commands a higher multiple, COR's discount is a quality discount.

### 2) Long CB / Short TRV — Insurance (403010) — **TOP (carry-forward)**
- **(a) L/S.** **TRV = leader/short** (~$374.36; Q2 2026-07-17 adj EPS $10.04 vs ~$5.39 est — an 86% beat — combined ratio 83.6% vs 95.1% est; +11.88% across July). **CB = laggard/long** (~$350.68; Q2 2026-07-21 core operating EPS $7.26 vs ~$6.70, +18.2% YoY, combined ratio **83.8%**, tangible book +17.1% YoY, record net investment income $1.88B — ended July **−0.30%**).
- **(b) Divergence thesis.** Corr **0.715**, 60d **0.738** (strengthening). TRV's blowout was driven overwhelmingly by **catastrophe losses falling to $518M from $927M YoY** — a weather-dependent, explicitly non-repeatable input — yet the re-rating pushed TRV's forward P/E **above** Chubb's. On repeatable measures the two are level or favour Chubb: combined ratios within 20bp, and Chubb adds record investment income and faster tangible-book compounding while TRV's TBV/share missed by 4.9%. Measured July spread **+12.17pp**, 3-month **+15.36pp** — the divergence **widened** since the prior screen.
- **(c) Reconvergence indicators.** (i) **CB Q3 confirmed 2026-10-20**; TRV Q3 historically mid-October, not confirmed. That quarter spans **peak Atlantic hurricane season**, making catastrophe-loss normalisation a mechanically dated event rather than a hoped-for one. (ii) Any Q3 cat-loss disclosure returning TRV toward run-rate. (iii) Chubb's Q3 net-premium-written growth resolving its one miss.
- **(d) Borrow/cost fit.** TRV not in the live sample; both large-cap GC insurers, no evidence of special borrow.
- **(e) Execution.** **Structurally the safest pair in the screen** — vols 19.3% (CB) and 20.6% (TRV) are the **lowest of any candidate**, so hedge-ratio error costs least here.
- **(f) Tier: TOP.** Reconciliation found fresh sell-side downgrades on TRV, strengthening the short leg. **Honest risk:** if TRV's underlying current-accident-year loss picks are genuinely improving (tort reform, pricing) rather than lucky weather, the re-rating is earned.

### 3) Long EFX / Short TRU — Professional Services (202020) — **REST (top of stack), NEW**
- **(a) L/S.** **TRU = leader/short** (~$78.62; Q2 2026-07-28 revenue $1.31B **+14.9% YoY**, beat, **raised** full-year guidance on financial-services strength; rose >8%). **EFX = laggard/long** (~$172.62; Q2 2026-07-21 revenue $1.70B +10.6–11% in line, adj EPS $2.25 vs $2.20 — a beat — but Q3 EPS guidance below consensus and the stock fell sharply).
- **(b) Divergence thesis.** Corr **0.845**, 60d **0.878** — **the highest measured correlation of any live thesis in this screen**, and strengthening. Both are consumer-credit-bureau businesses in the same 6-digit industry with heavily overlapping end-markets. EFX beat on EPS and met on revenue and was marked down on guidance; TRU, selling into much of the same US consumer-credit cycle, printed accelerating growth and was rewarded. Measured 3-month spread **−12.18pp**.
- **(c) Reconvergence indicators.** (i) **EFX Q3 2026 (~late Oct, not confirmed)** — the direct test of the $2.15–2.25 Q3 guide that caused the de-rating. (ii) TRU Q3 (~late Oct, not confirmed). (iii) Monthly public US mortgage-application and existing-home-sales data — the shared driver EFX itself cited.
- **(d) Borrow/cost fit.** **TRU measured live: 0.25% fee rate, 1,800,000 shares available** — GC, ample, no hard-to-borrow flag. On a $150 short leg held three months, ~$0.09. Immaterial.
- **(e) Execution.** Both legs far above the $35 commission break-even; ~$0.35/order.
- **(f) Tier: REST (top of stack) — DEMOTED FROM TOP by the earned-gap critic**, and the caveat is material: EFX's guidance cut was **explicitly attributed by the company to a tough mortgage market**, an exposure TRU carries far less of (TRU's growth was led by financial services, not mortgage). That is a real, current, asymmetric fundamental factor, not pure narrative. It advances on correlation quality and on the size of the reaction relative to the information, with that asymmetry stated rather than buried. **Provenance caveat:** several analyst price-target claims in the underlying research carried no traceable URL and have been **excluded** from this write-up rather than repeated.

### 4) Long MCHP / Short ADI — Semiconductors (453010) — **REST, NEW**
- **(a) L/S.** **ADI = leader/short** (~$367.41; fell less — July −5.5%, 3M −7.6% — while posting its own solid quarter; FQ2 reported and 10-Q filed 2026-05-20). **MCHP = laggard/long** (~$74.29; down **16.2% in July / 20.9% over three months**; Q4/FY2026 reported 2026-05-07, 10-K filed 2026-05-21).
- **(b) Divergence thesis.** Corr **0.802**, 60d **0.869** — high **and strengthening**, one of the better-hedged pairs in the screen. Both are analog/embedded semiconductor makers exposed to the same industrial and automotive end-markets. Measured 3-month spread **−13.30pp**, 1-month −10.70pp.
- **(c) Reconvergence indicators.** (i) **ADI FQ3 confirmed 2026-08-19** (company press release 2026-07-23). (ii) MCHP's next report is **an aggregator estimate only** — sources disagree between ~Aug 6 and ~Aug 14 and **no company announcement was found**; treat as unconfirmed. (iii) Public book-to-bill and inventory-days disclosures from both, the shared cycle indicator.
- **(d) Borrow/cost fit.** ADI not in the live SLB sample; mega-cap GC, no evidence of special borrow.
- **(e) Execution.** MCHP's ~$74 share price and ADI's ~$367 both clear the $35 break-even; ~$0.35/order.
- **(f) Tier: REST.** **The only one of twelve new pairs the earned-gap critic did not drop or demote** (KEEP_WITH_CAVEAT). **Recency verified this session against SEC EDGAR — both legs PASS** with ~two weeks' margin, no knife-edge. **Honest risk (the critic's caveat, stated):** ADI has genuinely broader and higher-margin growth, and MCHP's GAAP EPS of $0.22 / very high trailing P/E is propped up by preferred-dividend and restructuring accounting — Microchip is working through a real inventory-correction cycle with utilisation and margin damage, so part of the discount is earned.

### 5) Long PPG / Short SHW — Chemicals (151010) — **REST (carry-forward, demoted from TOP)**
- **(a) L/S.** **Both reported the same day, 2026-07-28.** **SHW = leader/short** (~$340.85; adj EPS $3.70 vs $3.50, revenue $6.79B vs $6.61B, guidance raised; +8.1%). **PPG = laggard/long** (~$110.52; adj EPS $2.23, a **two-cent** miss, revenue $4.5B +7% and a beat, sixth consecutive quarter of organic growth, full-year guide **reaffirmed**; −1.3% on the day, −9.86% across July).
- **(b) Divergence thesis.** Corr **0.732**, 60d **0.718** (roughly stable). Same group, same architectural/industrial coatings end-markets, same raw-material inputs, **same-day prints** — a genuinely controlled comparison that removes the "different quarters, different macro" confound weakening most of the rest of this list. The information delta was small; the price delta was ~9.4 points in a session.
- **(c) Reconvergence indicators.** (i) **SHW Q3 confirmed 2026-10-27**; PPG Q3 same-day is a Zacks **estimate**, explicitly not confirmed — flagged rather than asserted. (ii) Monthly US Census new-residential-construction and existing-home-sales releases. (iii) FOMC decisions via housing turnover.
- **(d) Borrow/cost fit.** SHW short interest 2.76% of float, 3.5 days to cover; no evidence of special borrow.
- **(e) Execution.** Standard; ~$0.35/order.
- **(f) Tier: REST — demoted from TOP.** Reconciliation flagged that SHW (the short leg) simply had the stronger, cleaner quarter — the beginning of the same earned-divergence pattern that killed MTZ/PWR, at smaller magnitude. Re-underwrite at the next refresh if PPG does not show relative strength.

### 6) Long VRT / Short NVT — Electrical Equipment (201040) — **REST, NEW**
- **(a) L/S.** **NVT = leader/short** (~$153.83; Q2 2026-07-31 record sales $1.471B **+53% reported / +47% organic**, adj EPS $1.45 +69% YoY, backlog $2.5B, FY26 guidance raised hard to 37–39% reported growth and $5.00–5.10 adj EPS). **VRT = laggard/long** (~$241.57; Q2 2026-07-29 adj EPS $1.52 beat $1.43 by 6.4%, adj operating margin +410bp to 22.6%, and FY26 guidance **raised across every metric** — but revenue $3.274B missed consensus by ~$109M (−3.2%), attributed by management to "multi-phase project execution and temporary supply chain congestion." Stock fell **−17.3%** on the print).
- **(b) Divergence thesis.** Corr **0.697**, 60d **0.825** — one of the largest correlation **strengthenings** in the population, so the hedge is in better condition now than the trailing year implies. Both legs sell into the identical AI-datacenter power/thermal buildout, reported two trading days apart, and were treated in opposite directions. Measured 1-month spread **−18.58pp**, 3-month **−23.22pp**.
- **(c) Reconvergence indicators.** (i) **VRT Q3 confirmed 2026-10-28 (after close)** — management's own Q3 guide of $3.65–3.85B revenue and $1.77–1.83 adj EPS already bakes in conversion of the deferred revenue, making this a **direct falsification test** of the "timing not demand" explanation. (ii) NVT Q3 estimated ~2026-10-30 (Yahoo consensus calendar — **estimated, not company-confirmed**).
- **(d) Borrow/cost fit.** **NVT measured live: 0.4081% fee rate, 3,200,000 shares available** — GC, ample. Short interest 2.52% of float, days-to-cover 2.0, and **falling** (−13.3% from the prior reading). Not a crowded short.
- **(e) Execution.** VRT's **64.4% annualized vol is the highest of any advanced long leg** — beta-adjusted sizing matters more here than anywhere else in the shortlist.
- **(f) Tier: REST. Two corrections applied to the underlying research and stated rather than buried:** (i) the thesis originally proposed *"sell-side channel checks on SmartRun/OneCore project timing"* as a catalyst — **"channel checks" is an explicitly banned non-public source under E's disadvantage-2.6 confrontation, and that catalyst has been STRUCK**; (ii) NVT's widely-quoted "+8.73%" print-day move is a **mid-afternoon intraday snapshot (15:03 EDT), not a close-to-close return** — the measured close-to-close July figure is −3.85%, and the intraday number is not used here. **Honest risk (why REST, not TOP):** VRT's revenue disappointment is **not** a one-off — Q1 2026 guidance was already ~2.3% light and the stock fell then too, with management citing execution friction on large deployments **both times**. A repeating pattern of slippage as deal size scales is a legitimate fundamental risk, and NVT is genuinely growing faster (47% organic vs VRT's 18%).

### 7) Long PANW / Short CRWD — Software (451030) — **REST (carry-forward)**
- **(a) L/S.** **CRWD = leader/short** (~$190.86 post-4:1 split; ~146× forward). **PANW = laggard/long** (~$331.83; FQ3 revenue +31% YoY; ~85× forward).
- **(b) Divergence thesis.** Corr **0.783**, 60d **0.871** (strengthening) — structurally the best-hedged carry-forward. CRWD trades at a ~62-point forward-multiple premium despite PANW growing revenue faster (31% vs 26%).
- **(c) Reconvergence indicators.** (i) **PANW FQ4 confirmed 2026-08-24** — corroborated by two independent sources; a MarketBeat "estimated Aug 17" is a **labelled template estimate and is wrong**. (ii) **CRWD FQ2 confirmed 2026-09-02.** (iii) CRWD short interest rose ~284% MoM to 2026-07-15 (from a low base, to 2.74% of float).
- **(d) Borrow/cost fit.** CRWD short-interest aggregators disagree materially — treat as noisy, **not** as hard-to-borrow evidence. **CRWD is the one name in this shortlist warranting an individual SLB check before entry**, given the short-interest build; it was not reached in this cycle's live sample.
- **(e) Execution.** Standard.
- **(f) Tier: REST.** **Correction:** several aggregators describe the PANW/CyberArk deal as an "August 2026" event — it **closed 2026-02-11**. **Do not run concurrently with §8 — same short leg.**

### 8) Long FTNT / Short CRWD — Software (451030) — **REST (alternative expression of §7)**
- **(a) L/S.** **CRWD = leader/short** (as §7). **FTNT = laggard/long** (~$161.95; Q2 2026-07-29 beat on billings, FY revenue guide raised to ~19% growth; ~46× forward).
- **(b) Divergence thesis.** Corr **0.628**, 60d **0.726**. Same short leg as §7 but a materially **fresher long-leg catalyst**. The tell: on 2026-07-29 CRWD rose as much as +11% and PANW +7% **on Fortinet's news** — a sympathy re-rating with no name-level information, on the group's most expensive multiple.
- **(c) Reconvergence indicators.** (i) **CRWD FQ2 confirmed 2026-09-02** — the first CRWD-specific datapoint since the sympathy rally. (ii) PANW FQ4 confirmed 2026-08-24 as a group read-through. (iii) FTNT Q3 (~early-to-mid Nov, not confirmed).
- **(d) Borrow/cost fit.** As §7.
- **(e) Execution.** Standard.
- **(f) Tier: REST. MUTUALLY EXCLUSIVE WITH §7** — both short CRWD; running both would double a single-name short against the 10% per-name envelope. **M4 should queue at most one.** The trade-off is hedge quality (§7, corr 0.783) versus catalyst freshness (§8).

### 9) Long COF / Short AXP — Consumer Finance (402020) — **REST (carry-forward)**
- **(a) L/S.** **AXP = leader/short** (~$336.25; Q2 2026-07-24 EPS $4.53 +11%, revenue +10%, card-member spend +9% — best in three years — FY26 **revenue** guidance raised but **profit** guidance held flat; fell ~4.3% on precisely that mismatch). **COF = laggard/long** (~$209.01; Q2 2026-07-21 adj EPS $5.81 vs ~$4.80, a 21% beat, revenue $15.8B +27–30% YoY, $2.5B Discover synergy target reaffirmed; ~10.4× forward).
- **(b) Divergence thesis.** Corr **0.769**, 60d 0.755, β **0.926** — nearly dollar-neutral, an unusually clean structure. AXP carries a premium-affluent-consumer multiple the market itself flagged as cracking when margin guidance failed to follow the revenue raise. COF trades at less than half that multiple because acquisition and CECL day-one provisioning distort GAAP earnings.
- **(c) Reconvergence indicators.** (i) **COF Q3 confirmed 2026-10-20.** (ii) **AXP Q3 confirmed 2026-10-23** (official IR release) — a second consecutive "raise revenue, hold profit" print would confirm the margin-narrative crack. (iii) Public CFPB/regulatory commentary on the Discover network integration.
- **(d) Borrow/cost fit.** COF short interest ~2.36% of float; no evidence of special borrow on AXP.
- **(e) Execution.** Standard.
- **(f) Tier: REST, flagged.** Already gained 5.4pp before this cycle. **Honest risk:** COF's discount looks partly credit- and integration-driven rather than purely narrative — a legitimate execution-risk premium on synergy realisation.

### 10) Long WFC / Short C — Banks (401010) — **REST (carry-forward, reduced conviction)**
- **(a) L/S.** **C = leader/short** (~$132.45; Q2 beat all 20 estimates, ROTCE 13%, revenue at a 10-year high; ~11.50× forward). **WFC = laggard/long** (~$86.45; Q2 EPS $2.00 vs $1.72, revenue $22.6B +9%, record IB fees >$900M, dividend +11%; ~11.66× forward).
- **(b) Divergence thesis (contrarian, decayed).** Corr **0.695**, 60d **0.644** — **one of the few pairs where the hedge is weakening**, which counts against it. The pair worked +6.07pp on the measured July window, but the mechanism was a valuation-driven sector rotation and an Oppenheimer downgrade, not fundamental divergence — both banks beat decisively. Forward P/Es are now nearly identical.
- **(c) Reconvergence indicators.** (i) **Both report Q3 on the same day, 2026-10-13** — confirmed independently from WFC's own IR page and Citi's published multi-quarter schedule. (ii) **C's Q2 10-Q remains UNFILED as of 2026-08-03 — verified directly against SEC EDGAR**; the first detailed look under the headline beat is still pending. (iii) A reported Fed lifting of WFC's long-standing asset cap, with Goldman adding WFC to its Conviction List — **the timing could not be pinned down and is flagged unverified-as-to-date rather than relied upon.**
- **(d) Borrow/cost fit.** Both GC; no evidence of special borrow on C.
- **(e) Execution.** Standard.
- **(f) Tier: REST, reduced conviction.** Two of three original supports have decayed: the Fed held **all** banks' stress capital buffers flat to 2027, so "C carries the highest SCB" is no longer differentiating, and the consensus-upside gap compressed. Retained on structure and residual valuation edge only.

---

## Considered and NOT advanced (beyond PART 1E's drops)

| Pair | 252d | Why not |
|---|---|---|
| **NOC/LMT** | 0.692 | **DROP — decisive.** NOC's own CFO stated on the Q2 call that, normalising for a prior-year divestiture, the entire $0.57 YoY EPS increase was largely driven by **remeasurement of uncertain tax positions**. The "beat" the thesis rested on is a tax artifact. |
| **PKG/IP** | 0.721 | **DROP.** IP announced (2026-01-29) a **12–15 month separation into two independent public companies**. A corporate separation on the short leg, likely to complete inside E's 1–6 month holding period, is a thesis-invalidation event by E's own exit rules and makes the legs non-comparable. |
| **TFC/MTB** | 0.847 | **DROP** despite the second-highest correlation in the population. TFC's NII/NIM shortfall is a **twice-repeated guidance cut** (3–4% → 2–3% → 1–1.5%) — a trend driven by asset/liability duration mix, i.e. structural and earned, not a narrative gap. (Recency verified: both legs PASS.) |
| **XPO/ODFL** | 0.758 | **DROP.** ODFL's valuation premium over XPO is a well-documented decade-plus structural feature — a non-union owner-operator network and minimal leverage versus a debt-funded serial acquirer — not a recent dislocation. Also: the GICS code is **203040 Ground Transportation**, correcting the 203010 used in the research brief. |
| **DVN/EOG** | 0.841 | **REJECT.** The **Devon–Coterra merger completed 2026-05-07**, days after the correlation window opened, mechanically cutting Devon's oil share of production from ~46% to ~34%. The legs are no longer the same business, and July's ~20% oil round trip makes this a commodity-direction bet in pair clothing — the same failure the prior cycle rejected FCX/SCCO for. |
| **PGR/ALL** | 0.734 | **REJECT on a mechanical gate.** ALL's most recent filing (Q1, 2026-04-29) is **96 days old — outside the 90-day recency gate** — and ALL does not report Q2 until 2026-08-05. Ineligible regardless of thesis. |
| **AAL/DAL** | 0.827 | **REJECT.** AAL's guided FY26 breakeven and Q3 loss trace to a **disclosed structural balance-sheet gap** (AAL net debt $30.7B vs DAL $13.6B, sub-investment-grade with ~1.2× interest coverage). A leverage-driven selloff during a fuel-price spike is earned. |
| **RVTY/TMO** | 0.706 | **REJECT.** A timing gap, not a narrative-vs-fundamentals gap: TMO's rally tracks its own hard Q2 numbers (broad four-segment beat, fourth straight EPS beat, real guidance raise) and RVTY simply hasn't reported since. |
| **TER/AMAT** | 0.732 | **REJECT.** 60-day correlation (0.870) runs **above** the 252-day (0.732) — the pair is converging in co-movement, and TER already outperformed by 8.0pp in July, so part of the 3-month gap has reconverged. Echoes the prior cycle's MU/AMAT group-effect rejection. |
| **VRT/GEV** | 0.626 | **DROP — cross-strategy.** GEV is open long in the D book as of 2026-08-03; an E short of GEV would largely net out against it at book level. |
| **VRT/HUBB, HUBB/NVT** | 0.559 / 0.641 | Not advanced — dominated by VRT/NVT (§6), which has both the better correlation and the cleaner catalyst. HUBB/NVT additionally has almost no divergence (+0.27pp 1M). |

---

## Tier summary and ordering

**TOP (2):** §1 COR/MCK (corr 0.714, catalyst in 2 days), §2 CB/TRV (corr 0.715, lowest vols in the screen, divergence widened).
**REST (8):** §3 EFX/TRU, §4 MCHP/ADI, §5 PPG/SHW, §6 VRT/NVT, §7 PANW/CRWD, §8 FTNT/CRWD *(mutually exclusive with §7)*, §9 COF/AXP, §10 WFC/C.

Total shortlist **10 pairs** — 3 new (EFX/TRU, MCHP/ADI, VRT/NVT), 7 carried forward. Two prior TOP pairs dropped (MTZ/PWR on earned divergence plus a B-book conflict; ELV/UNH displaced on fit), and LII/TT demoted out.

**Ordering for M4 by reconvergence-indicator proximity:** §1 COR/MCK (**2026-08-05**, both legs, confirmed) → §4 MCHP/ADI (**ADI 2026-08-19 confirmed**; MCHP mid-Aug, estimate only) → §7 PANW/CRWD (**2026-08-24**) → §8 FTNT/CRWD (**2026-09-02**) → §10 WFC/C (**2026-10-13**, both legs) → §2 CB/TRV (**CB 2026-10-20**) → §9 COF/AXP (**2026-10-20 / 10-23**) → §5 PPG/SHW (**SHW 2026-10-27**) → §6 VRT/NVT (**VRT 2026-10-28**) → §3 EFX/TRU (~late Oct, unconfirmed).

**Execution disposition.** Individual-stock pair execution is **feasible and cheap**, and the standing `execution-feasibility-deferred` qualifier should be discharged: fractional shorts are permitted on the live platform, round-trip commission is **0.42% of gross**, and short borrow on the sampled legs runs **0.25–0.43%** with ample availability. **What blocks entry is no longer execution** — it is E's fundamental DO-NOT-ACTIVATE call (divergence review pending), `state.trading_enabled = FALSE`, and the open Tier-1 defect on E's pre-mortem. **M4 should treat PART 2 as research feedstock for E's reactivation, not as a queue to drain into orders this month.**

---

## Data-provenance and defect notes

- **FMP remains largely unusable.** `chart`, `quote`, `company`/`market-cap` return ACCESS DENIED for essentially every symbol. Refinement on the prior cycle's diagnosis: it is **not purely plan-gating** — one agent obtained **three successful calls and then hit a session-wide quota**, confirmed by a different FMP tool also failing afterward. Exception: FMP served WFC and C, and its closes matched IBKR's **exactly** (86.45 / 132.45 on 2026-07-31) — the only independent cross-validation of the IBKR series available, and it passed.
- **Market caps are screening-grade ESTIMATES.** Neither IBKR's snapshot (no market-cap field) nor FMP exposes live market cap for most tickers. Where reported they are last price × approximate shares outstanding; the one checkable case (WFC ~$259B estimated vs FMP-confirmed $261.4B) landed within 1%. Two agents correctly **declined to report market caps at all** rather than fabricate them from stale recalled share counts.
- **ADV is IBKR's `avg_90d_usd_volume`** (90-day, not the 30-day the screen nominally specifies) — stated rather than papered over. Every advanced name clears the $10M floor by more than an order of magnitude, so the distinction changes no disposition.
- **CORRECTION TO THE 2026-08-01 DEFECT DIAGNOSIS — the `get_price_history` series-swap is CONTRACT-LEVEL, not a batching artifact, and the sequential-fetch mitigation does NOT catch it.** The August edition attributed the swap to parallel batching and prescribed one-call-per-message. This cycle produced evidence on both sides and the batching theory is falsified as a complete explanation:
  - *Consistent with batching:* one agent's initial 28-ticker batched call returned **DVN and IP silently swapped**; the other 26 tickers in that batch were correct.
  - *Inconsistent with batching, and decisive:* another agent found `get_price_history` for **RCL's contract id (11520) returns data byte-identical to SPOT's series (contract 312496724)** — reproducing across **three** fetches with different parameters, **including fully sequential, single-ticker, non-batched calls.** Confirmed genuinely distinct instruments via `get_price_snapshot` (RCL live 322.8 vs SPOT 504–505). A batching race cannot explain a defect that reproduces on an isolated solo call.
  - **Operative conclusion: the only reliable detection is cross-checking every series against an INDEPENDENT endpoint**, not sequencing the calls. Sequencing remains worth doing — it removed the long-blob manual-transcription errors that bit two agents this cycle — but it is **not sufficient**.
  - **Verification performed before publication:** all **48 legs** across every advanced and carried-forward pair were re-verified against live `get_price_snapshot` readings. **All 48 passed**, every live price within ~4% of its 2026-07-31 close (largest deviation TER at −3.72%). The DVN/IP pair was additionally confirmed by **both contract id and company description** — `754442` = "DEVON ENERGY CORP", `8511` = "INTERNATIONAL PAPER CO" — with the two live prices moving in **opposite** directions rather than converging, which is the signature a genuine swap would leave.
  - **Report to W5/D3 as a standing infrastructure defect.** Any routine consuming `get_price_history` — batched or not — is exposed until the connector is fixed.
- **Two measurement agents made manual transcription errors reading long batched tool responses, and both caught themselves** — one mis-copied DY/EME/LII/TT, another mis-assigned FOXA←CMG, LYV←KBH and TTWO←LYV and detected it with a systematic `difflib` duplicate-detection sweep. Both re-fetched individually and re-verified. Recorded because it is a failure mode **independent** of the MCP defect: parse tool responses mechanically, never by eye.
- **Cross-cycle measurement validation.** Correlations independently re-measured this session reproduce the 2026-08-01 edition to within ~0.002 on every carried pair: WFC/C 0.695 vs 0.695, TRV/CB 0.715 vs 0.713, COF/AXP 0.769 vs 0.770, MTZ/PWR 0.742 vs 0.741, LII/TT 0.615 vs 0.615; MTZ/PWR's July spread reproduces at −29.17pp vs −29.2pp. Two independent pipelines agreeing to three decimals is meaningful evidence both are sound.
- **Cross-batch ticker validation.** Three tickers were measured independently by different agents and agree to the cent: HAL $32.25 (batches 5 and 7), ITW $286.95 (batches 4 and 7), CRWD $190.86 (batch 2, both its pairs, and the prior cycle). A shared-scratchpad collision risk was identified during the run; this check confirms it did not materialise.
- **Harness note for the operator (not a data issue).** Two sub-agents reported that the coordinator's mid-run directive arrived in a form they judged unauthenticated and declined to treat its factual claims as established, while still adopting the verification practices it recommended. Both reached correct results independently — including one that **resisted a factually wrong price hint from the coordinator** and verified against the data instead. Worth knowing that orchestrator-to-subagent directives currently read as untrusted input to a careful agent, which in this instance produced the right behaviour.

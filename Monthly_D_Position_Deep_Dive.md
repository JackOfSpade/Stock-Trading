2026-08

# Monthly D Position Deep-Dive — August 2026 cycle (review window 2026-07-01 → 2026-08-01)

**IMMEDIATE-ACTION flag: NONE.** No D position shows material thesis invalidation this cycle. Across 8 names and 11 tranches there are **37 at-entry invalidation criteria** (AMZN 5, GOOGL 5, TSM 3, UBER 4, ISRG 4, CRM 5, DIS 5, RTX 6): **36 are NOT BREACHED**, and the remaining one — CRM criterion 2 — is clear on the single quarter available (+13% cRPO cc against a 10% floor) but its two-consecutive-quarter test **cannot yet be run**, because Salesforce's January fiscal year means no new quarter has printed since entry. Every position recommendation is **HOLD**.

**Span covered.** 2026-07-01 (M3's last successful completion) → 2026-08-01. `state.routine_catchup_window` gives `window_days = 30.99` against a `monthly_ftd` fallback of 31 — cadence-normal, **no missed monthly cycle**, no multi-period catch-up sub-sections required. Six of the eight positions were opened *after* the prior M3 ran, so for those the span is entry-date → today and this is their **first** M3 deep-dive; only RTX and DIS carry a full prior-month comparison.

---

## Scope and book state

**Scope is roster-derived.** This routine covers every roster-active strategy with `review_cadence: long_horizon` in `strategy/roster.yaml` — currently **exactly D** (`roster_state: adopted`, `per_strategy_routine: null`), so today's scope is unchanged. A future SISA `long_horizon` graduate would appear here automatically as its own `## Strategy <code>` section.

**The book grew from 2 names to 8 since the last cycle.** The prior M3 (2026-07) covered RTX and DIS only and flagged, for a third consecutive cycle, that D sat at **2/5 against its concurrent-position floor**. The Q3 thesis drain (D2 2026-07-08/09 → 07-30) closed that gap: D now holds **8 distinct names across 11 tranches**, comfortably above the minimum-5 floor. **That under-deployment indicator is resolved and should stop being carried forward.**

| Name | Tranches | Shares | Cost basis | Mark (07-31 close) | Market value | Unrealized | CaR % of NAV | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **AMZN** | 2 (07-09, 07-30) | 0.3464 | $88.2367 | $271.58 | $93.64 | **+$5.40 (+6.1%)** | 3.57% | HOLD |
| **GOOGL** | 2 (07-09, 07-26) | 0.2577 | $87.8234 | $354.20 | $91.28 | +$3.45 (+3.9%) | 3.55% | HOLD |
| **TSM** | 2 (07-21, 07-29) | 0.1550 | $64.0134 | $404.00 | $62.62 | −$1.39 (−2.2%) | 2.59% | HOLD |
| **UBER** | 1 (07-09) | 0.5156 | $37.7457 | $70.45 | $36.32 | −$1.42 (−3.9%) | 1.53% | HOLD |
| **ISRG** | 1 (07-20) | 0.1091 | $38.1316 | $353.33 | $38.55 | +$0.42 (+1.1%) | 1.54% | HOLD |
| **CRM** | 1 (07-09) | 0.2275 | $36.4811 | $183.38 | $41.72 | **+$5.24 (+14.4%)** | 1.48% | HOLD |
| **DIS** | 1 (05-07) | 0.2822 | $31.4142 | $96.19 | $27.14 | **−$4.27 (−13.6%)** | 1.27% | HOLD |
| **RTX** | 1 (04-27) | 0.1601 | $28.3215 | $215.22 | $34.46 | **+$6.14 (+21.7%)** | 1.15% | HOLD |
| **Total** | **11** | — | **$412.16** | — | **$425.73** | **+$13.57** | **16.68%** | — |

*Marks are 2026-07-31 regular-session closes read from the IBKR connector; 2026-08-01 is not a trading day (`state.market_calendar.is_trading_day = FALSE`), so no 08-01 print exists. `analytics.strategy_nav` shows `deployed_mv` $426.80 against these $425.73 — a small timing difference between the NAV view's mark and the connector snapshot, not a reconciliation break.*

**Envelope compliance (Rev 43 sizing).** Capital-at-Risk for long equity is the full position notional (no stops), measured here against D NAV of **$2,471.35**:
- **Per-name CaR ≤ 10%** — largest is AMZN at **3.57%**. All eight comply with wide margin.
- **Per-strategy deployed CaR ≤ 75%** — aggregate **16.68%**. Complies.
- **GICS sector ≤ 30% of NAV** — largest bucket is Communication Services (GOOGL + DIS) at **$118.42 = 4.79%** of NAV. Then Info Tech (CRM + TSM) 4.22%, Consumer Discretionary (AMZN) 3.79%, Industrials (RTX + UBER) 2.86%, Health Care (ISRG) 1.56%. All far inside the cap.

**D engine state (informational; not exit-triggering).** `perf.strategy_daily` 2026-07-31: `deployed_unit_value` **1.0499** (+4.99% total return on deployed capital), `peak_unit_value` 1.0499, `current_drawdown` **0.00%**, `sgov_index` 1.0096, **`excess_vs_sgov` +3.99%**, `deployed_days` 67, `closed_trades` 0, `gate_n` 30. This is a marked improvement on the prior cycle's −1.71% / −2.33% excess. All `perf.kill_flags` are **FALSE** (`drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`). `beta_hat` 0.742 and `alpha_annualized` 1.100 are computed but `beta_min_n_met = FALSE`, so **the alpha estimate is not yet usable** and no edge-decay read should be drawn from it. The 30-trade gate (0/30) and the m2m underperformance trigger (needs ≥756 deployed days) remain structurally inactive for D — a documented, accepted property, not a flaw.

**Router state (informational; does NOT alter disposition).** D router technical signal = **ACTIVATE** (SPY Trend NEUTRAL; Yield-Curve Sustained-Inversion NOT-SUSTAINED). `div-D-202606-1` orchestrator resolved 2026-07-06 to a binding **ACTIVATE, UNCHANGED**, with the new-entry block staying lifted. Current `state.current_regime` fundamental axis (2026-07-01 M1a): **reflation-tilt + neutral risk**. Per Strategy.md's router-deactivation-does-not-force-exits rule, every disposition below is **criterion-driven, not regime-driven**.

---

## Cross-cutting findings

These are visible only across the book, not from any single position, and are the substantive output of this cycle.

### F-1. No D position has a usable thesis-COMPLETION criterion — a systematic Entry-criterion-4 gap

Strategy D Entry criterion 4 requires that a thesis specify **BOTH** completion criteria (narrative-fulfilment markers) **AND** invalidation criteria, immutable for the position's life. Reading all eight entry records this cycle: **not one carries a discrete, testable completion marker.** Six (AMZN, CRM, GOOGL, ISRG, TSM, UBER) state none at all — each independently constructed, each omitting the same required element. The remaining two carry *reassessment* triggers that are explicitly not completion markers: RTX's Q1'27 falsifiable-milestone reassessment, and DIS's Q3 FY26 checkpoint. The TSM and AMZN entry records each flag the absence themselves as an "honest gap."

The consequence is concrete, not bookkeeping. **Every D position today can exit only on invalidation.** There is no "thesis fulfilled, take the win" path in the book, which structurally biases D toward holding winners indefinitely — and it makes one of M3's own four permitted recommendations, *"close on thesis completion,"* currently **unreachable for every position under review**. RTX is the live illustration: all five of its Q1'27 falsifiable milestones are already satisfied three quarters early, and there is still no defined mechanism by which that could ever read as completion.

**This is not fixable here, and deliberately is not fixed here.** Invalidation and completion criteria are immutable for a position's life, so no criterion may be added to an open position retroactively — doing so would be exactly the thesis-evasion the immutability rule exists to prevent. The finding belongs to thesis *construction* discipline for future D entries. It is routed to M4 for onward handling rather than actioned in this file. The open `PENDING_DRAFT` queue item **`revise-premortem-D-2026-a3`** (strategy D, due 2026-07-31, currently `pending` with conservative default "NO-EDIT pending routing resolution"), together with the 2026-07-30 AR_orc **cycle-5 TIER 1 DEFECT — REVISION REQUIRED** outcome on the Strategy D pre-mortem, is the natural adjacent venue.

### F-2. The book's largest thematic exposure has its principal emerging risk uncovered by any criterion

AMZN, GOOGL and TSM are three expressions of one trade — the AI-capex cycle, with TSM the supplier and AMZN/GOOGL two of the payers. Combined CaR is **9.71% of D NAV, 58% of all deployed D capital**, and it is invisible to the 30%-of-NAV GICS test because the three sit in three different sectors (Consumer Discretionary, Communication Services, Information Technology).

The cycle strengthened materially this window on every measure the theses actually test: AWS +37% YoY accelerating a 5th straight quarter, Google Cloud +82% with backlog crossing $500B, TSM's own capex guide raised to $60–64B, and four-for-four hyperscaler capex raises. **But the same window produced the first hard evidence of what that build costs the payers:** Amazon's TTM free cash flow is **−$7.6B** (from +$18.2B a year earlier) with 2026 capex guidance raised to ~$220B, and Alphabet printed its **first-ever negative-FCF quarter** at −$5.86B with FY26 capex guidance raised to $195–205B and buybacks still paused.

**Neither AMZN's five criteria nor GOOGL's five name free cash flow, capex intensity, or ROIC.** The risk is real, it is correlated across the two largest positions in the book, and no invalidation criterion would register it. Per the immutability rule this is recorded, not acted on — but it is the single most important thing for future cycles to watch, and the market has already shown it can reprice this quickly: on the same night AMZN rose 15.3% and MSFT 15.5% on capex read as monetized, **META fell 7.95%** on capex read as dilutive. AMZN's own add-tranche entry named that regime flip as its residual risk.

### F-3. Four criterion-relevant events land in the three days after this cycle closes

| Date | Event | Which criterion it bears on |
|---|---|---|
| **2026-08-03** | J&J investor call on Ottava (FDA-cleared 2026-07-22) | ISRG criterion 4 — the first live test of "competitor discloses displacing dV at named large IDNs" now that a credible competitor is cleared |
| **2026-08-05** | **DIS Q3 FY26 earnings, CONFIRMED**, before market | DIS criteria 1 (third consecutive SVOD-margin point), 2 (guidance), 3 (Q3 cumulative buyback) — the first live test of the reframed Subtype-B thesis since entry |
| **2026-08-05** | FCC reply-comment deadline in the ABC licence proceeding | DIS criterion 5 (escalation trigger) |
| **2026-08-05** | **UBER Q2 2026 earnings, CONFIRMED**, before market | UBER criteria 1–3 — the first genuinely new quarter since entry |

None of these is routed to a research-deferral. See the note on that choice below.

### F-4. Two ledger data defects — flagged for correction, not actioned here

Both were found by reading entry records against `state.current_positions`. **M3 is research-only and has not written to either row.**

- **RTX (`D:RTX:2026-04-27`) — field transposition, and the more consequential of the two.** The row carries `time_exit_date = 2027-04-27` with `ltcg_date = NULL`. The entry record specifies **no maximum hold and no time exit** — it states verbatim that the position "runs to thesis-invalidation by (i)-(vi) above OR negative outcome on the falsifiable-milestone reassessment at Q1'27 earnings." 2027-04-27 is exactly 12 months after execution, i.e. the value `ltcg_date` should hold. Strategy D has no maximum hold by design. **Left uncorrected, a future routine reading `time_exit_date` could stage an unfounded forced exit in April 2027** — the precise outcome D's no-max-hold rule exists to prevent.
- **DIS (`D:DIS:2026-05-07`) — `ltcg_date` is NULL.** The entry record's own pending-queue subsection states the 12-month LTCG-eligible date as **2027-05-08**.

### F-5. Source-reliability finding

A secondary blog (tikr.com, 2026-07-27) asserts Intuitive **raised** FY2026 procedure guidance to 14–16%. The primary company release and earnings call confirm guidance was **reaffirmed at 13.5–15.5%** with a midpoint lean. The same source is the sole origin of an unverified "Q1 China placements were just 4 units" claim. Recorded here so a future cycle does not pick either up as fact. More broadly, this cycle's packets separate primary (SEC/8-K/10-Q/IR/transcript) from secondary sourcing throughout, and several load-bearing figures are explicitly labelled secondary-pending-primary — most notably the hyperscaler capex guidance figures underpinning TSM's criterion 3.

### F-6. On why nothing is routed to "further research" this cycle

M4 converts an M3 "further research" recommendation into a `PENDING_ANALYSIS` research-deferral whose **`conservative_default` is to exit the position if unresolved.** That default is appropriate for a genuine, decision-blocking information gap. It is not appropriate for any gap found this cycle: every open item above is either (a) a dated event arriving on a known date within days (F-3), or (b) a criterion-design or ledger issue that an exit would not resolve (F-1, F-4). Attaching an exit-if-unresolved default to a thesis whose every criterion is currently clear would be disproportionate to the evidence. All open items are therefore carried forward as **monitoring items for M4/M5**, explicitly not as deferrals.

### F-7. Correlation-bucket recompute — no bucket forms, and it sharpens F-2

Strategy D Entry criterion 5 requires the daily-return correlation matrix to be **recomputed monthly**. Since Rev 35 (owner directive) bucket membership is **monitored-only/informational** — neither capped nor entry-blocking — so this is reported, not enforced.

Pairwise Pearson correlations of simple daily returns across all 8 held names:

| | AMZN | CRM | DIS | GOOGL | ISRG | RTX | TSM | UBER |
|---|---|---|---|---|---|---|---|---|
| **AMZN** | 1.000 | 0.166 | 0.191 | **0.519** | 0.231 | 0.066 | 0.326 | 0.252 |
| **CRM** | 0.166 | 1.000 | 0.192 | 0.059 | 0.224 | −0.090 | −0.124 | 0.234 |
| **DIS** | 0.191 | 0.192 | 1.000 | 0.234 | 0.309 | 0.126 | 0.123 | 0.297 |
| **GOOGL** | 0.519 | 0.059 | 0.234 | 1.000 | 0.297 | 0.093 | 0.354 | 0.267 |
| **ISRG** | 0.231 | 0.224 | 0.309 | 0.297 | 1.000 | 0.198 | 0.148 | 0.240 |
| **RTX** | 0.066 | −0.090 | 0.126 | 0.093 | 0.198 | 1.000 | 0.050 | 0.108 |
| **TSM** | 0.326 | −0.124 | 0.123 | 0.354 | 0.148 | 0.050 | 1.000 | 0.245 |
| **UBER** | 0.252 | 0.234 | 0.297 | 0.267 | 0.240 | 0.108 | 0.245 | 1.000 |

**Pairs > 0.6: NONE. Pairs > 0.7: NONE.** Highest is AMZN–GOOGL at **0.519**; then GOOGL–TSM 0.354, AMZN–TSM 0.326. **No correlation bucket forms at the 0.6 entry threshold, and no post-entry-emergent 0.7 pair exists.**

**Window limitation, stated rather than papered over:** the computation used **208 daily returns over 209 common trading dates, 2025-10-01 → 2026-07-31** — roughly 10 months, **not** the full trailing-252-day window the criterion specifies. Six of the eight names were bought inside the last four weeks, so a longer window would measure pre-ownership co-movement in any case; but the shortfall is a real deviation from the specified method and is recorded as such. Values were computed from adjusted closes and **independently re-verified** by a second calculation over the same aligned date set.

**This materially sharpens F-2.** The three AI-capex names are the three most correlated pairs in the entire book (0.33–0.52) — clearly elevated against a book median near 0.20 — yet all sit **below** the 0.6 bucket threshold. So the AI-capex concentration is a **shared-fundamental-driver** concentration, not (yet) a realised-return-correlation one. Both facts matter: the correlation test would not flag this exposure today, which is precisely why F-2 is worth stating separately rather than leaving to the mechanical screen.

---

# Per-position deep-dives

## Position — AMZN (Amazon.com) — Subtype B (trend-continuation)

**Tranches (2).** `D:AMZN:2026-07-09` 0.1554 sh, cost basis $37.4893, LTCG 2027-07-09 (filled ~$243.00 limit) · `D:AMZN:2026-07-30` (add) 0.1910 sh, cost basis $50.7474, LTCG 2027-07-31 (filled 2026-07-31 @ $263.859). **Aggregate 0.3464 sh / $88.2367 cost basis; mark $271.58 (2026-07-31 close) = $93.64 MV, +$5.40 unrealized (+6.1%).** Aggregate CaR 3.57% of D NAV — the book's largest single-name exposure, inside the 10% envelope.
**Span covered:** entry (2026-07-09) → 2026-08-01. First M3 deep-dive.

### 1. Current thesis status — INTACT, strengthening

Original thesis (`c39e644a` 2026-07-08; add `1dcbdf5a` 2026-07-30): AWS is re-accelerating after several years of deceleration on AI/cloud demand. The Subtype-B trend metric is AWS revenue YoY ≥20% with operating margin ~30%+ and a non-declining backlog, supported by Trainium custom-silicon adoption and intact Anthropic/OpenAI compute commitments. The ~$200B/yr capex build is explicitly framed as monetizing on a 6–24 month lag, held under a "live watch" guarded by the margin/ROIC criteria.

The thesis is intact and strengthening on primary-source data. **The one open item carried from the 2026-07-30 add is now CLOSED:** that entry recorded AWS backlog as UNBREACHED but noted the Q2 2026 ~$496B point was secondary-sourced pending the 10-Q. The **Q2 2026 10-Q was filed 2026-07-31** and discloses commitments not yet recognized of **~$496B as of 2026-06-30, weighted-average remaining life 6.4 years** — confirming the figure exactly.

**Gap carried forward (not invented here):** neither entry states a discrete *completion* criterion. Consistent with Subtype-B design (trend-continuation positions exit on invalidation, not on a narrative-fulfilment marker), but recorded so a later cycle does not read its absence as a completion call. This is the same structural gap noted below for CRM, UBER and TSM — see the book-level note.

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| AWS revenue re-acceleration | **Progressing** | YoY 17.0 → 17.5 → 20.0 → 24.0 → 28.0 → **37.0%** across Q1'25→Q2'26 — 5th consecutive accelerating quarter, fastest in 18 quarters (8-K Ex-99.1, SEC EDGAR, 2026-07-30) |
| AWS operating margin | **Progressing** | 39.5 → 32.9 → 34.6 → 35.0 → 37.7 → **39.4%** — Q2'26 is the series high (same filing) |
| AWS backlog / RPO | **Progressing** | $200B (9/30/25) → $244B (12/31/25) → $364B (3/31/26) → **$496B (6/30/26)**; WAL 3.8 → 4.1 → 5.5 → 6.4 yr. All four points now primary-sourced from 10-Q/10-K "Unearned Revenue" notes; monotonic, no sequential decline |
| Trainium / custom silicon | **Progressing** | Chips business run-rate >$25B, triple-digit YoY; new adopters incl. NEURA Robotics, Odyssey, TwelveLabs, Decart, Poolside, Uber, Pinterest (Q2'26 release, ir.aboutamazon.com) |
| Anthropic / OpenAI commitments | **Progressing / strengthening** | Q2'26 release verbatim: "the two leading AI labs in the world, Anthropic and OpenAI, making multi-year, multi-gigawatt commitments" to Trainium. The $53.4B non-operating pretax gain (primarily the Anthropic stake markup) is directionally consistent with a strengthening relationship |
| Capex → monetization lag / ROIC | **Mixed — demand progressing, near-term cash worsening** | 2026 capex guidance **raised to ~$220B from ~$200B** (memory-cost driven), per Jassy on the 2026-07-30 call. **TTM FCF −$7.6B vs +$18.2B a year earlier** (8-K Ex-99.1). Management frames this as demand-outpacing-capacity, not oversupply. Not an invalidation criterion as written — see §7 |

### 3. Fundamental developments (2026-07-01 → 2026-08-01)

- **2026-07-07/08** — Amazon priced $25B of AI-related debt (424B5/FWP) into a softening AI-credit tape; cited at entry as a discount-rate caution.
- **2026-07-15** — AWS S-team reshuffle: Dave Brown (19-yr tenure) departing, replaced by Dave Treadwell effective 2026-08-01 (Reuters, reporting an internal memo). Ordinary senior rotation — **Garman remains AWS CEO**. Not thesis-relevant.
- **2026-07-30 (after close)** — **Q2 2026 8-K (Item 2.02)**, Ex-99.1: total net sales **$200.606B (+20% YoY, first $200B quarter)**; consolidated operating income $27.461B (+43%, 13.7% margin vs 11.4%); GAAP net income $62.647B / $5.75 diluted EPS **including a $53.4B non-operating pretax gain "primarily from investments in Anthropic"**; TTM FCF −$7.604B. **AWS: net sales $42.232B (+37% YoY), operating income $16.621B, margin 39.4%.** Q3'26 guide: net sales $197–202B, operating income $22.5–26.5B. *Primary:* sec.gov/Archives/edgar/data/1018724/000101872426000024/amzn-20260630xex991.htm.
- **2026-07-31** — **10-Q filed**, confirming the $496B backlog / 6.4-yr WAL (see §1).
- **2026-07-30/31 price action** — closed $235.50 pre-print (+3.90%), after-hours ~$257–258, then **$271.58 (+15.32% vs the pre-print close)** on 07-31. Cross-hyperscaler same night: Azure +43% (MSFT +15.5%), Google Cloud +82%, META −7.95% on a capex-raise-plus-EPS-miss.
- **Ongoing** — **FTC v. Amazon** marketplace-monopoly bench trial set for **2026-10-13** (Judge John H. Chun, W.D. Wash.). Concerns retail/marketplace seller-pricing conduct, **not AWS**; it does not touch any of the five invalidation criteria but is a material near-term event for the stock.

### 4. Invalidation criteria check — 5/5 NOT BREACHED

Re-verified against a six-quarter AWS series cross-checked directly against SEC EDGAR primary filings, not merely against the 2026-07-30 entry's own table.

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "AWS YoY <18% 2 consec Q" | **NOT BREACHED** | 17.0, 17.5, 20.0, 24.0, 28.0, **37.0%**. The only sub-18% pair is Q1–Q2 2025, >1 year old; every quarter since has accelerated | 8-K Ex-99.1 series, SEC EDGAR, as of Q2'26 |
| 2 | "AWS op-margin <~30% 2 consec Q" | **NOT BREACHED** | 39.5, 32.9, 34.6, 35.0, 37.7, **39.4%** — never below 30% in six quarters; Q2'26 series high | Same |
| 3 | "AWS backlog declines seq 2 consec Q" | **NOT BREACHED — open item now closed** | $200B → $244B → $364B → **$496B**, monotonic. Q2'26 figure now primary-confirmed by the 10-Q filed 2026-07-31 (WAL 6.4 yr) | 10-Q/10-K "Unearned Revenue" notes, SEC EDGAR |
| 4 | "Anthropic/OpenAI commits renegotiated down/churned" | **NOT BREACHED** | "multi-year, multi-gigawatt commitments" — unchanged/strengthened vs Q1'26 ("up to five gigawatts" Anthropic, "~two gigawatts" OpenAI) | Q2'26 8-K Ex-99.1, 2026-07-30 |
| 5 | "metric-immutability if AWS segment reporting restructures >=2Q" | **NOT BREACHED** | All six quarters report the unchanged three-segment structure (North America / International / AWS) on unchanged definitions | Same series |

### 5. Sector & secular theme context

The hyperscaler capex race is intensifying, not cooling — all three major clouds raised 2026 capex guidance this cycle. **AWS's +37% was the slowest of the big three this quarter** (Azure +43%, Google Cloud +82%): AWS is re-accelerating off a far larger base, gaining absolute dollars while ceding relative growth-rate share — a nuance the AWS-specific (not share-relative) criteria do not test. The market is currently rewarding capex it reads as monetized (AMZN +15.3%, MSFT +15.5%) and punishing capex it reads as dilutive (META −7.95% the same night); the 2026-07-30 entry itself flagged that regime as the residual fragility, since a flip would make the negative TTM FCF far more expensive.

### 6. Long-term tax treatment

LTCG lines 2027-07-09 and 2027-07-31 — both ~11–12 months out. No completion marker is defined (Subtype B, open-ended trend hold), so there is no LTCG/completion timing collision to coordinate. Per Rev 39, exit timing would not be deferred for LTCG in any case.

### 7. Recommendation — **HOLD**

All five immutable criteria are NOT BREACHED against a fully primary-source-confirmed six-quarter series, and the deciding evidence is the AWS segment data itself (+37% YoY accelerating a 5th straight quarter, 39.4% margin at a series high, $496B backlog at 6.4-yr WAL) — **not** the headline GAAP EPS, which is dominated by the non-cash $53.4B Anthropic mark and should not be read as thesis evidence.

**Information gaps (tracked, none decision-blocking):**
- **TTM FCF −$7.6B** is a real and growing cash cost of the capex build that **no written criterion captures**. Not grounds to act under Strategy D's rules, but the single most important quarter-over-quarter watch item, because the "regime stops rewarding unmonetized capex" scenario is the one the entry record itself named as residual risk.
- AWS backlog for Q1'25 and Q2'25 remains **NOT FOUND / UNVERIFIED**; immaterial (the four most recent quarters are complete and rising), closable by pulling those two 10-Qs' Unearned Revenue notes.
- The ~$220B 2026 capex figure is sourced to the earnings **call transcript** (primary company communication, not an SEC-filed document); confirm against Q3'26 filings.
- **Next hard checkpoint:** Q3 2026 earnings ~2026-10-29 (**UNCONFIRMED**). FTC bench trial 2026-10-13 — awareness item, not a criterion.

---

## Position — GOOGL (Alphabet) — Subtype B (trend-continuation) with a Subtype-A-style regulatory overlay

**Tranches (2).** `D:GOOGL:2026-07-09` 0.1043 sh, cost basis $37.5322, LTCG 2027-07-09 · `D:GOOGL:2026-07-26` (add) 0.1534 sh, cost basis $50.2912, LTCG 2027-07-27 (filled 2026-07-27 @ $325.56, conviction HIGH). **Aggregate 0.2577 sh / $87.8234 cost basis; mark $354.20 (2026-07-31 close) = $91.28 MV, +$3.45 unrealized (+3.9%).** Aggregate CaR 3.55% of D NAV — second-largest name, inside the 10% envelope.
**Span covered:** 2026-07-01 → 2026-08-01 (both tranches fall inside this window).

### 1. Current thesis status — INTACT, and moving favourably rather than merely not breaching

Original thesis (`706bf712`, 2026-07-08/09, GO/HIGH; add `fd464178`, 2026-07-26, GO/HIGH, draining the queued `add-thesis-GOOGL-D-20260722` item and inheriting tranche 1's criteria for the position's life): Google Cloud is becoming a durable "second engine" alongside Search, evidenced at entry by Q1 CY2026 Cloud revenue of $20.03B (+63% YoY) with expanding operating margin and a backlog that had nearly doubled sequentially to ~$460B. Gemini and AI Overviews are framed as **defending** rather than cannibalising core Search. A regulatory overlay treats the then-current state of the US search antitrust remedy (behavioral, no Chrome/Android divestiture) as a load-bearing precondition — **a structural remedy anywhere would be the problem.** Trend metric: Cloud revenue ≥25% YoY.

The add tranche was triggered by a dip-with-intact-thesis (−10.6% vs cost) **and** strengthened conviction, and the strengthening was real: Cloud accelerated +63% → +82%, margin 20.7% → 35.6% YoY, backlog crossed $500B for the first time.

**Gap:** no discrete completion marker distinct from the invalidation list. Same Subtype-B pattern as the rest of the 2026-07 cohort — see book-level finding F-1.

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| Google Cloud as durable second engine | **Progressing — accelerating on all three metrics, two consecutive prints** | Q1 CY26: revenue $20.03B (+63% YoY), op income $6.6B, **margin 32.9%** (vs 17.8% YoY), backlog $462B (~2× QoQ). Q2 CY26: revenue **$24.77B (+82% YoY)**, op income $8.81B, **margin 35.6%** (vs 20.7% YoY), backlog **$514B** (+$50B+ sequentially, first $500B cross) — Alphabet 8-K Ex-99.1, SEC EDGAR, 2026-07-22 (primary) |
| Gemini / AI Overviews defending Search | **Progressing — with an execution-risk yellow flag** | Search & other revenue **+17% YoY to $63.27B** in Q2; AI Mode >1B MAU since global expansion; Gemini app 950M MAU (Alphabet Q2 2026 call, abc.xyz, 2026-07-22). **Counter-signal:** Gemini 3.5 Pro missed its June 2026 GA target and remains unshipped, attributed to disappointing coding-benchmark results on a retraining pass, concurrent with four senior DeepMind researchers departing to Anthropic in the week of 2026-06-21/27 (Bloomberg 2026-07-16; LA Times 2026-07-17). This bears on **frontier-model competitiveness, not on the Search revenue line**, which accelerated in the same window |
| Antitrust/regulatory posture | Risk overlay, not a growth driver — see criterion 4 | — |

### 3. Fundamental developments (2026-07-01 → 2026-08-01)

- **~2026-06-21/27** — Four senior Google DeepMind researchers depart for Anthropic (secondary).
- **2026-07-16** — Bloomberg/9to5Google report **Gemini 3.5 Pro delayed** past its June GA target on disappointing coding benchmarks. Stock fell ~3.2% intraday.
- **2026-07-22 — Alphabet Q2 2026** (primary: 8-K Ex-99.1, sec.gov/Archives/edgar/data/1652044/000165204426000066/googexhibit991q22026.htm):
  - **Google Cloud revenue $24,768M, +81.8% YoY**; op income **$8,814M**; **margin 35.6%** vs 20.7% a year ago and up from 32.9% sequentially — expanding on both comparisons. **Backlog/RPO $514B**, up >$50B sequentially from $462B; company expects to recognise "just over 50%" as revenue over the next 24 months.
  - Consolidated revenue $119.80B (+24% YoY, +23% cc), operating income $40.77B (+30%), operating margin 34% (+2pp). Net income $112.11B, diluted EPS $9.11 — **including a $99.0B other-income gain, mostly unrealised equity-securities marks (+$77.1B to net income, +$6.26 to diluted EPS)**. As with AMZN's Anthropic mark, the headline EPS is not thesis evidence.
  - Capex $44.92B in Q2 (2× YoY); **FY26 capex guidance raised to $195–205B** (from $180–190B).
  - **Free cash flow −$5,855M — Alphabet's first negative-FCF quarter** (operating cash flow $39.07B less capex $44.92B); TTM FCF $53.27B.
  - **No buybacks disclosed** (the pause that began Q1 2026 continues). A $49.6B equity raise (Class A/C plus mandatory convertible preferred) completed June 2026, plus a $40B equity distribution agreement, both earmarked for AI infrastructure capex.
- **2026-07-23** — **EU Commission fines Google €890M under the DMA**: €460M (Search self-preferencing) + €430M (Play "steering" restrictions). Both order Google to end the conduct within a compliance window — **behavioral, no divestiture, no structural element** (primary: digital-markets-act.ec.europa.eu).
- **2026-07-24 onward** — Plaintiffs'-side securities-fraud "investigations" announced by several law firms around the 07-16 and 07-22/23 drops. **These are plaintiff-firm client-solicitation notices, not SEC or DOJ enforcement actions**; no government investigation was found. Recorded so a future cycle does not mistake them for regulatory action.
- **2026-07-24** — Moody's flags AI capex as a sector-wide credit-quality risk across six hyperscalers including Alphabet. **No rating action against Alphabet** — Aa2 stable as of the 2026-06-04 note on the equity raise, leverage ~0.7×. Sector commentary only.
- **2026-07-30** — DOJ and state AGs file a D.C. Circuit appellate brief arguing Judge Mehta's Sept-2025 search remedies are too weak, seeking reversal of the provision allowing Google to keep paying search distributors, while upholding the data-sharing mandates.

### 4. Invalidation criteria check — 5/5 NOT BREACHED

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "Cloud rev YoY <20% 2 consec Q" | **NOT BREACHED** | Q1 CY26 **+63%**; Q2 CY26 **+82%**. Both far above the 20% floor and **accelerating** | Q1 2026 call (2026-04-29); 8-K Ex-99.1 (2026-07-22, primary) |
| 2 | "Cloud op-margin contracts 2 consec Q" | **NOT BREACHED** | Q1 **32.9%** (vs 17.8% YoY); Q2 **35.6%** (vs 20.7% YoY, and up sequentially from 32.9%). **Expansion on both YoY and sequential comparisons in both quarters** | Same |
| 3 | "Cloud RPO/backlog declines seq 2 consec Q" | **NOT BREACHED** | Q1 $462B (up from ~$240B); Q2 **$514B** (+$50B+ sequentially). Rising in both quarters | Same |
| 4 | "adverse structural remedy" | **NOT BREACHED — verified to present-day currency across all four live proceedings** | See the rundown below | Primary docket and case-page checks dated 2026-08-01 |
| 5 | "metric-immutability if Cloud rev stops being reported comparably >=2Q" | **NOT BREACHED** | Google Cloud reported as a discrete, comparable segment with consistent revenue/op-income disclosure in both Q1 and Q2 2026. No segment redefinition | Q1/Q2 2026 8-K segment tables (primary) |

#### Criterion 4 in detail — structural vs behavioral, all four proceedings, as of 2026-08-01

This is the position's load-bearing criterion and the one place in the entire D book where a criterion's status could not be settled from news coverage alone, so it was checked against primary dockets directly.

- **(a) US DOJ search monopoly** (*US v. Google*, D.D.C. 1:20-cv-03010-APM, Judge Mehta). Liability Aug 2024. **Remedies ruling 2025-09-02 REJECTED divestiture of Chrome/Android and ordered behavioral relief only** (ban on exclusive default-distribution contracts; mandated search-index and user-interaction data sharing; syndication offer requirement; technical compliance committee). Google appealed Jan 2026; DOJ and state AGs cross-appealed by 2026-02-03. Google's stay motion was **denied 2026-05-08**, so the behavioral remedy is **in force** during appeal. DOJ's 2026-07-30 brief attacks the *scope of behavioral relief*. Oral argument expected late 2026 / early 2027. **No structural remedy ordered or in force.**
- **(b) US DOJ ad-tech** (*US v. Google*, E.D. Va. 1:23-cv-00108, Judge Brinkema). Liability 2025-04-17 (monopolisation of publisher ad server and ad exchange, plus unlawful tying). Remedies trial concluded 2025-11-21; DOJ sought **AdX divestiture with contingent DFP divestiture** — the single highest-probability source of an actual structural order anywhere. **VERIFIED 2026-08-01 against the CourtListener docket: NO remedies opinion, order, or final judgment has issued.** The most recent entries are routine attorney appearance/withdrawal orders (#1843–1848, 2026-06-03/16); date of last known filing **2026-06-16**. Brinkema indicated at closing she would decide structural-vs-behavioral in principle first, and cautioned in Nov 2025 that no decision should be expected until 2026.
- **(c) EU DMA.** The 2026-07-23 €890M decisions are **conduct/behavioral compliance orders — no divestiture, no structural element** (primary: EC DMA press release).
- **(d) EU ad-tech (Art. 102, Case AT.40670) — the genuinely open flank.** The 2025-09-05 decision fined Google €2.95B and stated the Commission's **preliminary view that only divestiture of part of Google's ad-tech business** would resolve the structural conflict of interest — but **did not order one**, instead giving Google 60 days to propose measures. Google submitted a **behavioral-only** plan on 2025-11-14 and filed a General Court annulment action on 2026-01-12 (Case T-794/25, a separate track). **VERIFIED 2026-08-01 against the Commission's own case page: "Last decision date: 05.09.2025" — the Commission has not ruled on the compliance plan.**
- **General sweep 2026-07-18 → 2026-08-01:** no structural or divestiture remedy against Alphabet landed in any jurisdiction. The only Alphabet antitrust action in the window is the 07-23 DMA fine, which is behavioral.

**Net:** every enforcement action that has actually concluded — US search remedies and both DMA decisions — landed **behavioral**. Two proceedings remain live and are the only paths by which a structural remedy could materialise: **Brinkema's pending ad-tech remedies ruling** and **the Commission's pending AT.40670 compliance-plan assessment.** Both were confirmed undecided today against primary sources, so **criterion 4 is NOT BREACHED as a positively-evidenced fact, not as an absence of coverage.**

### 5. Sector & secular theme context

Hyperscaler AI capex is sector-wide, not GOOGL-specific: combined big-four 2026 capex guidance is ~$725B, up ~77% from 2025's ~$410B; Moody's projects ~$785B across six tracked names in 2026 rising toward ~$1T in 2027, and flags FCF compression plus rising direct and off-balance-sheet lease obligations (~$460B direct debt, ~$1.2T lease commitments across the six) as a sector credit pressure point. Within that group **Google Cloud's +82% outpaced both AWS (+37%) and Azure (+43%) this quarter** — though GOOGL remains the smallest of the Big Three by share (most recent sourced full-market data, Q2 2025: AWS ~30%, Azure ~20%, Google Cloud ~13%), so it is growing fastest off the smallest base. The frontier-model layer is the one place the competitive picture softened (Gemini 3.5 Pro slip, researcher attrition), and it is visible in neither the Search nor Cloud revenue lines, both of which accelerated. The regulatory backdrop is genuinely multi-front and global, which is exactly why the position's criterion is written narrowly to **structural-versus-behavioral only** rather than to regulatory news generally.

### 6. Long-term tax treatment

LTCG lines **2027-07-09** and **2027-07-27**, both >11 months out. Nothing in the window interacts with either. No max hold. Because no completion marker is defined (§1), the position's only defined exit path is an invalidation breach — reviewer note, not itself invalidating.

### 7. Recommendation — **HOLD**

The three quantitative Cloud criteria did not merely avoid breach — all three moved **favourably and accelerated** across the two quarters reported since entry. The regulatory criterion is unbreached and, unusually, that is established here by direct primary-source verification of the two live dockets rather than inferred from silence. The Gemini 3.5 Pro delay is a real competitiveness signal but maps onto none of the five criteria and is, under Strategy D's own rules, explicitly non-exit-triggering.

**Information gaps (tracked, none decision-blocking):**
- **Brinkema's US ad-tech remedies ruling (E.D. Va. 1:23-cv-00108)** — undecided as of 2026-08-01; DOJ's ask is AdX divestiture. **If it lands before the next M3 pass it must be triaged immediately against criterion 4 rather than held for the monthly cycle**, since it is the highest-probability structural order in existence against this name.
- **EU AT.40670 compliance-plan assessment** — the Commission has said on the record that only divestiture may resolve the conflict, and has not ruled on Google's behavioral-only plan. Same immediate-triage treatment applies. Watch competition-cases.ec.europa.eu/cases/AT.40670 for a decision date past 2025-09-05.
- **Q3 2026 10-Q** will show whether the negative-FCF quarter was a one-off or the start of a pattern. **FCF is not one of the five criteria** — see book-level finding F-2, where this recurs at AMZN too.
- **Documentation-accuracy note on the thesis record:** the entry record characterises the DOJ search case as "resolved FAVOURABLY on appeal." That was not accurate at construction time and is not accurate now — the appeal remains open at the D.C. Circuit with oral argument not yet held. The *substance* the thesis relies on (the remedy is behavioral, and is in force) is correct; the procedural characterisation is not. Recorded for the thesis record; not a criterion breach.
- **Next hard checkpoint:** Q3 2026 earnings **2026-10-28, UNCONFIRMED** (Wall Street Horizon flags it unconfirmed; Alphabet IR has not formally announced).

---

## Position — TSM (Taiwan Semiconductor, ADR) — Subtype B (trend-continuation)

**Tranches (2).** `D:TSM:2026-07-21` 0.0891 sh, cost basis $38.1224, LTCG 2027-07-21 (filled MARKET @ $423.93) · `D:TSM:2026-07-29` (add) 0.0659 sh, cost basis $25.8910, LTCG 2027-07-30 (filled MARKET @ $388.99). **Aggregate 0.1550 sh / $64.0134 cost basis; mark $404.00 (2026-07-31 close) = $62.62 MV, −$1.39 unrealized (−2.2%).** Aggregate CaR 2.59% of D NAV (per-name envelope 10%).
**Span covered:** entry (2026-07-21) → 2026-08-01. First M3 deep-dive for this position.

### 1. Current thesis status — INTACT, strengthened on in-window primary evidence

Original thesis (DEFER `a78dac64` 2026-07-08 → GO `0edb56ed` 2026-07-17 → add `32042c0f` 2026-07-29): TSM is the sole scaled leading-edge AI-accelerator foundry — the widest structural moat in the D screen universe. The Subtype-B trend metric is the conjunction *USD revenue growth ≥15% YoY **and** GM ≥55% **and** a rising sub-7nm mix*, sustained over ≥12 months.

The thesis holds, and this window did more than fail to break it: TSM's own FY26 capex guide was **raised** ($52–56B Jan → "closer to $56B" Apr → **$60–64B** on the 2026-07-16 call), and all four major hyperscalers raised 2026 capex guidance in their own Q2-26 prints. Criterion 3 names a "structural AI-capex reset" as the invalidation event; the window's evidence runs in the opposite direction, not merely short of the trigger.

**Honest gap carried forward from the entry record (not invented here):** the entry defines no discrete *completion* marker separate from the trend-continuation test itself. The 2026-07-29 add-tranche entry flags this explicitly. This is a thesis-construction gap, not an invalidation signal — recorded so a later cycle does not mistake its absence for a completion call.

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| Leading-edge foundry demand / pricing power | **Progressing** | Packaging capacity "so tight that now it's limiting my customers' growth" — C.C. Wei, TSMC 2Q26 call transcript, investor.tsmc.com, 2026-07-16 |
| N2/A16 ramp | **Progressing** | N2 = 3% of Q2 wafer revenue (first commercial quarter); "steep ramp-up of 2-nanometer" guided for Q3; A16 on track H2-2026, guidance unchanged (TSMC 2Q26 Earnings Release, 2026-07-16) |
| Sub-7nm (advanced-tech) revenue mix | **Progressing** | 74% (Q1 CY26) → **77%** (Q2 CY26), both from TSMC's own Earnings Release PDFs (2026-04-16, 2026-07-16) |
| Arizona / US capacity buildout | **Progressing — materially accelerated** | New **$100B incremental** US commitment announced 2026-07-16/17; total $165B → **$265B**, 4 new fabs / 12 US facilities (TSMC PR pr.tsmc.com; NIST/Commerce release; NYT 2026-07-16/17) |
| TSM's own AI/HPC capex commitment | **Progressing** | FY26 capex guide raised to **$60–64B** on the 2Q26 call; CFO: capex over the next three years "even more significantly higher than the past three years" |

Five drivers assessed; five progressing. None stalled, none reversed.

### 3. Fundamental developments (2026-07-01 → 2026-08-01)

- **2026-07-13** — June 2026 monthly revenue NT$442.68B, +6.2% MoM, **+67.9% YoY**; 1H26 NT$2,404.48B, +35.6% YoY. *Primary:* pr.tsmc.com/english/news/3323.
- **2026-07-16** — **Q2 CY2026 results** (SEC 6-K, EDGAR CIK 1046179, accession 000104617926000451; Earnings Release PDF, investor.tsmc.com): USD revenue **$40.20B (+33.7% YoY, +12.0% QoQ**, high end of guidance); **GM 67.7%**; operating margin 60.3%; advanced-tech (≥7nm) mix **77%**. Q3 guide $44.6–45.8B revenue / 65–67% GM.
- **2026-07-16/17** — FY26 capex raised to $60–64B; **$100B incremental Arizona commitment** (cumulative $265B).
- **2026-07-21** — D tranche 1 filled, 0.0891 sh @ $423.93 MARKET.
- **2026-07-28** — **Magnitude-7.1 Kumamoto (Japan) earthquake.** JASM fab evacuated precautionarily; structural inspections found buildings sound; operations resumed gradually; second-fab construction temporarily paused for safety. **No production-impact or wafer-loss figure has been disclosed by TSMC as of 2026-08-01.** (Reuters 2026-07-28; Digitimes 2026-07-29.) *Caution recorded:* secondary reports citing an "up to 30,000 wafers" scrap figure trace to an unrelated 2025 quake and are **not** attributable to this event on current sourcing.
- **2026-07-29** — Broad semis/AI-capex sell-off (SK Hynix DRAM-oversupply miss, Korean circuit breakers, hawkish FOMC hold): TSM −5.0% intraday **with no TSM-specific news**. D added tranche 2 into this dip; it filled the next session at $388.99 (TSM closed $403.31 that day, +8.2%).
- **Late July 2026** — Hyperscaler Q2-26 capex guidance all **raised**: Alphabet $195–205B (from $180–190B), Amazon ~$200B (from ~$150–175B), Microsoft ~$190B (from ~$120–150B), Meta $115–135B (from ~$100–115B). **SECONDARY-sourced** (earnings-call compilations; not pulled from each issuer's own 8-K/10-Q this cycle) — see §7 gap. Investor reaction to the raises was mixed/skeptical (CNBC 2026-07-28), a multiple concern about the *payers*, not a volume signal for TSM's order book.
- **Nvidia:** no Q2/FY2027 print inside this window (next expected late August 2026, exact date UNVERIFIED). Reported 2026 Nvidia "production cuts" are **consumer GeForce/gaming SKUs** (30–40%, driven by GDDR/HBM memory reallocation *toward* AI datacenter parts) — a demand-exceeds-supply signal, not an AI order cut.
- **Competitive:** Intel 18A (backside power live now vs TSMC N2P 2026 / Samsung 2027) remains the nearest threat, status unchanged since entry; no yield or customer-win data this window moves it. Sub-7nm mix continued rising.

### 4. Invalidation criteria check — 3/3 NOT BREACHED

Both two-consecutive-quarter tests have **both** required quarters' data (Q1 and Q2 CY2026); neither is a single-quarter inference.

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "GM <55% OR USD rev YoY <15% for 2 consecutive quarters" | **NOT BREACHED** | Q1 CY26: GM 66.2%, USD rev +40.6% YoY. Q2 CY26: GM 67.7%, USD rev +33.7% YoY. Neither quarter breaches either limb. | TSMC Earnings Release PDFs (SEC 6-K-filed), 2026-04-16 & 2026-07-16 |
| 2 | "N2/A16 ramp pushed out OR sub-7nm share declines 2 consecutive quarters" | **NOT BREACHED** | No pushout language in either release or call; N2 at 3% of Q2 wafer revenue with a guided steep Q3 ramp; A16 unchanged H2-2026. Sub-7nm mix **rose** 74%→77%. | TSMC 1Q26/2Q26 Earnings Releases + 2Q26 call transcript |
| 3 | "structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop)" | **NOT BREACHED — evidence points the opposite way** | TSM FY26 capex guide **raised** to $60–64B in-window; packaging capacity described as constrained-high ("limiting my customers' growth"), not slackening; four-for-four hyperscaler capex **raises**; no Nvidia AI/datacenter order-cut evidence found. | TSMC 2Q26 call transcript 2026-07-16 (primary); hyperscaler capex **secondary** |

### 5. Sector & secular theme context

The AI-capex cycle intensified rather than decelerated inside this window. The dominant near-term risks visible are **not** AI-demand problems: (a) a commodity-DRAM oversupply scare (SK Hynix miss, CXMT Shanghai IPO) that dragged TSM by sector correlation on 07-29 with no logic read-through, and (b) investor skepticism about hyperscaler capex *ROI* — a valuation-multiple concern about TSM's customers, not their order volumes. The Kumamoto quake is a genuine new operational risk, but it touches a Kyushu/JASM fab, **not** TSM's core Taiwan leading-edge capacity, and remains unquantified.

### 6. Long-term tax treatment

LTCG lines: tranche 1 **2027-07-21**, tranche 2 **2027-07-30** — both ~11.7 months out. No completion-timing interaction: D has no max hold, and per Rev 39 exit timing is governed solely by thesis completion/invalidation with no LTCG deferral preference. Nothing to coordinate this cycle.

### 7. Recommendation — **HOLD**

All three at-entry invalidation criteria are NOT BREACHED on primary-source data covering both required quarters, and the criterion most exposed to the macro tape (3, AI-capex reset) is contradicted rather than merely untriggered. No exit condition is met; no information gap is material enough to threaten the hold.

**Information gaps (tracked, none decision-blocking):**
- **Kumamoto production impact — NOT DISCLOSED.** TSMC's next monthly revenue release (July figures, expected ~mid-August 2026 on the June report's 2026-07-13 lag) is the first data point that could show an effect. *Trigger:* if a material production loss is quantified, re-check driver "N2/A16 ramp" and criterion 2 promptly rather than waiting for Q3.
- **TSMC July 2026 monthly revenue NOT YET PUBLISHED** as of 2026-08-01 (investor.tsmc.com monthly-revenue July row blank).
- **Hyperscaler capex figures are SECONDARY-sourced.** Worth a direct 8-K/10-Q check next cycle if criterion 3 ever becomes close-run; it is not close-run now.
- **Next hard checkpoint:** Q3 CY2026 print, ~2026-10-15 (**estimated — TSMC has not published a Q3 date**), which supplies the third consecutive quarter for criteria 1 and 2.

---

## Position — UBER (Uber Technologies) — Subtype B (trend-continuation)

**Tranche (1).** `D:UBER:2026-07-09` 0.5156 sh, cost basis $37.7457 (~$73.20/sh), LTCG 2027-07-09. **Mark $70.45 (2026-07-31 close) = $36.32 MV, −$1.42 unrealized (−3.9%).** CaR 1.53% of D NAV.
**Span covered:** entry (2026-07-09) → 2026-08-01. First M3 deep-dive.

### 1. Current thesis status — INTACT

Original thesis (`d2a37460`, 2026-07-08 — the only D-strategy UBER entry): marketplace-scale compounding. Uber's dual-sided (Mobility + Delivery) global marketplace compounds Gross Bookings at mid-to-high-teens-or-better constant currency while adjusted-EBITDA margin (% of GB) expands, funded by an Uber One subscription flywheel and a **capital-efficient two-sided AV hedge** — aggregating AV demand for third-party operators (Waymo and others) rather than building its own stack, while taking minority equity/prepay stakes in emerging AV suppliers so it captures upside whichever technology wins. At entry: Q1 CY2026 GB $53.7B (+25% reported / +21% cc), Mobility +25%, Delivery +28%, Uber One >50M members, adj-EBITDA $2.48B (+33%) = 4.62% of GB vs 4.36% prior year.

**Q2 2026 has not yet been reported — the print is 2026-08-05, four days after this review.** So criteria 1–3, each a two-consecutive-quarter test, have **zero new quarters of data since entry**; the two most recent reported quarters remain Q4 2025 and Q1 2026, both already known at entry.

**Gap:** no completion criterion is stated in the entry record (same Subtype-B pattern as AMZN/CRM/TSM).

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| GB scale compounding | **Progressing** | cc growth accelerated three straight quarters through Q1 2026 = **+21% cc** (+25% reported), the "third consecutive quarter" of 21%+ cc per the CFO (Q1 2026 release & prepared remarks, investor.uber.com, 2026-05-06) |
| Uber One flywheel | **Progressing** | 46M members Q4 2025 (+55% YoY) → **>50M** Q1 2026, now **>50% of total platform GB**; members spend ~3× non-members |
| Adj-EBITDA margin expansion | **Progressing** | Q4 2025 **4.6%** of GB (+40bps YoY); Q1 2026 **4.62%** ($2,481M/$53,720M) vs 4.36% ($1,868M/$42,818M), **+26bps YoY** |
| AV two-sided hedge | **Progressing — but the risk character has changed** | AV mobility trips +10× YoY, live in 8 cities as of the Q1 2026 call (targeting 15 by YE2026), >30 AV partners. **However:** Uber has committed **>$10B** (~$2.5B direct equity + ~$7.5B vehicle purchase commitments) to owned/exclusive fleets — Lucid (11.5% stake / 35,000 vehicles), Rivian ($1.25B / 50,000 robotaxis) — that will compete **head-to-head with Waymo in SF, Dallas and London by late 2026**, even as Waymo vehicles keep running on Uber's app in Austin/Atlanta (~250k paid rides/week per Uber's own Q1 call). Secondary commentary (Electrek 2026-05-15; Road to Autonomy) frames this as a "strategic split." This is the hedge working as designed — both sides monetized — but the *partnership* framing in the entry thesis is now materially more adversarial |

### 3. Fundamental developments (2026-07-09 → 2026-08-01)

- **2026-07-08** — Waymo announces driverless expansion to four new US cities (San Diego, Las Vegas, Tampa, Denver), employee-first, pushing past 10 fully-driverless US markets (CNBC, CBT News).
- **2026-07-13** — Uber confirms **Q2 2026 earnings for 2026-08-05, before market** (Uber IR press release, primary; Wall Street Horizon marks CONFIRMED).
- **2026-07-16 — Public takeover offer for Delivery Hero.** All-cash **€41.50/share, equity value ~$14.8B**; Delivery Hero's management and supervisory boards recommend acceptance. Expands the combined footprint from 79 to **99 markets** and pro-forma combined GB to **$236B** (2025 basis); financed with cash plus a ~€14B committed bridge facility; guided accretive to non-GAAP EPS with high-single-digit accretion by year 3; **closing expected H2 2027** pending merger-control clearances. **Largest acquisition in Uber's history by a wide margin — announced, not closed.**
- **2026-07-21/22** — Federal judge (Gregory Woods, SDNY) grants Uber and Lyft a **preliminary injunction** blocking NYC Local Law 52 ("just cause" driver-deactivation) from taking effect 2026-07-28, finding likely success on impairment-of-contract grounds (*Uber Technologies, Inc. v. City of New York*, Nos. 1:26-cv-4893/4931-GHW). Favourable to driver-supply cost structure.
- **2026-07-23** — New shareholder derivative suit (led by the Police and Fire Retirement System of the City of Detroit) alleging the board and executives concealed sexual-assault-related safety data; cites 3,571 active related SF federal-court suits as of 2026-06-01 (Forbes). **Reputational/governance risk; not thesis-metric-relevant.**
- **Ongoing** — FTC v. Uber (Uber One "cancel anytime" / ROSCA billing) unresolved; DOJ v. Uber (ADA pattern-or-practice; motion to dismiss denied 2026-03-05, now in discovery) unresolved.

### 4. Invalidation criteria check — 4/4 NOT BREACHED

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "GB cc YoY <~15% 2 consec Q" | **NOT BREACHED** | Q4 2025 **+22% cc**; Q1 2026 **+21% cc**. Both far above ~15%. Q2 2026 not yet reported (2026-08-05) | Uber Q4 2025 release 2026-02-04; Q1 2026 release 2026-05-06 (both primary) |
| 2 | "adj-EBITDA margin (% of GB) contracts YoY 2 consec Q" | **NOT BREACHED** | Q4 2025 4.6% of GB (+40bps YoY); Q1 2026 4.62% (+26bps YoY). Both quarters show **expansion — the opposite of the trigger condition** | Q4 2025 prepared remarks; Q1 2026 release financial tables |
| 3 | "Uber One membership stalls/declines seq" | **NOT BREACHED** | Q4 2025 >46M (+55% YoY) → Q1 2026 **>50M** (~+9% sequential), now >50% of platform GB. Sequential growth accelerating | Same |
| 4 | "metric-immutability if GB disclosure structurally changes" | **NOT BREACHED** | No structural redefinition of the GB metric in Q4 2025 or Q1 2026. *Adjacent, not a breach:* Q1 2026 **revenue** growth (+14% reported) was depressed ~9pp by agency-vs-principal revenue-recognition changes in certain markets — a **revenue** recognition shift, not a change to GB. **Forward watch item:** the pending Delivery Hero acquisition will eventually require integrating a large new international delivery business — re-check GB segment-disclosure continuity once it closes | Q1 2026 release (primary); Delivery Hero deal statements 2026-07-16 |

**Scope observation (reported, not acted on):** none of the four immutable criteria addresses driver/labour-classification risk, though that is a live and material structural risk for the sector. This is a gap in **what the criteria were written to cover**, not a measurement failure. Per the immutability rule it is recorded as an observation only — criteria are not rewritten mid-life.

### 5. Sector & secular theme context

**AV competition is the core structural risk**, and as of end-July 2026 three models run in parallel. **Waymo** (Alphabet): >10 fully-driverless US markets, July expansion to Las Vegas (live 07-08/09, employee-first) with San Diego/Tampa/Denver following, targeting 20+ cities plus Tokyo and London; ~3,500–4,000 vehicles; ~500k paid rides/week aiming at 1M by year-end; $126B valuation off a $16B Feb-2026 raise. (Waymo paused public *freeway* rides in late May 2026 pending a software update; surface-street service unaffected.) **Tesla Robotaxi**: driverless in Austin, Dallas, Houston and — new in July 2026 — Miami (07-03), Orlando and Tampa (both 07-21); SF Bay Area still requires a safety driver under CA law. **Tesla is a direct competitive threat entirely outside Uber's platform — it does not distribute through Uber's app.** **Uber itself** runs the hybrid: still hosting Waymo in Austin/Atlanta while committing >$10B to owned/exclusive fleets competing against Waymo in some of the same cities. None of this breaches a criterion, but it is the largest multi-year swing factor in the thesis.

**Delivery consolidation:** the pending $14.8B Delivery Hero deal would materially expand delivery scale (99 markets, $236B pro-forma GB) — a significant tailwind to driver #1 if it closes, while introducing integration, antitrust and bridge-financing risk through H2 2027.

**Labour/regulatory (not covered by the criteria):** net favourable in-window. Wins: the NYC Local Law 52 injunction; an Amsterdam Court of Appeal ruling that drivers are independent contractors (Jan 2026); a similar French ruling (Jul 2025); the US DOL's Feb 2026 NPRM proposing an employer-friendly contractor standard (comments closed 2026-04-28, final rule pending). Open risks: the **EU Platform Work Directive transposition deadline of 2026-12-02** (presumption of employment) with France/Germany/Ireland/Italy still drafting; and the California Prop-22 "contractual failure" suit filed April 2026.

### 6. Long-term tax treatment

LTCG 2027-07-09, ~11 months out. No max hold, no near-term tax pressure. The −3.9% mark is an immaterial short-term move and explicitly not exit-triggering under Strategy D.

### 7. Recommendation — **HOLD**

All four immutable criteria are NOT BREACHED against the two most recently reported quarters, with GB cc growth far above the floor, margin **expanding** rather than contracting, and Uber One growing sequentially. Every named driver is progressing. The qualitative change worth recording is the AV posture: Uber has moved from pure demand aggregation toward simultaneous fleet ownership. That deepens the two-sided hedge as designed **and** raises direct competitive exposure to Waymo in markets where it previously only distributed Waymo's rides — evolution consistent with the entry thesis, not a violation of it, but a change in the risk character of driver #4 that merits close quarterly tracking.

**Information gaps (tracked, none decision-blocking):**
- **Q2 2026 print, 2026-08-05 (CONFIRMED)** — four days after this review; the first genuinely new quarter since entry and the first real post-entry test of criteria 1–3. **Carry-forward for M4/M5, not a research-deferral** (no criterion is close to triggering, so attaching an exit-if-unresolved default would be disproportionate).
- Delivery Hero terms and merger-clearance timeline — could eventually affect GB segment disclosure (criterion 4) on closing (H2 2027 target).
- NYC Local Law 52 merits outcome (the injunction is preliminary, not final).
- EU Platform Work Directive member-state transposition ahead of the 2026-12-02 deadline.
- Next cycle should also check whether Uber's Q2 print or 10-Q characterises the Waymo relationship further, given the "strategic split" narrative in secondary press.

---

## Position — ISRG (Intuitive Surgical) — Subtype B (trend-continuation)

**Tranche (1).** `D:ISRG:2026-07-20` 0.1091 sh, cost basis $38.1316 (≈$349.51/sh), LTCG 2027-07-20. **Mark $353.33 (2026-07-31 close) = $38.55 MV, +$0.42 unrealized (+1.1%).** CaR 1.54% of D NAV.
**Span covered:** entry (2026-07-20) → 2026-08-01 — 12 days. First M3 deep-dive.
*Not to be confused with the separate `B:ISRG:2026-07-21` Strategy-B position in the same name, which is out of M3's scope and runs on its own mechanical convergence/time-exit rules.*

### 1. Current thesis status — INTACT

Original thesis, two records: **2026-07-08 DEFER** (`82f3bc45`, MEDIUM-HIGH) constructed the thesis, judged it GO-quality, and deliberately deferred entry 8 trading days to avoid deploying a fresh long-horizon position into the imminent 2026-07-16 print. **2026-07-17 GO** (`9de1893a`) drained the re-screen the day after that print, with all four criteria checked NOT MET, and staged a marketable DAY BUY at 2% starter sizing — deliberately not scaled up, because of a two-sided caveat that worldwide procedure growth ticked 16% → 15% with the US decelerating.

Thesis: da Vinci is a razor-and-blades installed-base annuity — procedure volume plus a growing system base drive recurring instruments/accessories and service revenue, with da Vinci 5 as an ASP/margin upgrade cycle. Named trend metric: worldwide da Vinci procedure growth ≥13% YoY.

The thesis holds. Both quarters with data clear every criterion, and the **entry captured the post-drop price**: the stock fell ~14% to a 52-week low on 2026-07-16/17 on a *beat-and-reaffirm* quarter, and the position is modestly up since.

**Gap:** no completion criterion is stated in either record. As written the position has **no defined exit path other than an invalidation breach** — the same Subtype-B pattern as AMZN/CRM/UBER/TSM/GOOGL. See the book-level note.

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| Worldwide da Vinci procedure growth (≥13% trend metric) | **Progressing** | Q1 CY26 **+16%**; Q2 CY26 **+15%** — both above the 13% trend floor and well above the 10% invalidation floor (Intuitive Q2 2026 press release, isrg.intuitive.com, 2026-07-16) |
| System placements / installed base | **Progressing** | Q1: 431 placements (232 dV5) vs 367 prior-year; installed base 11,395 (+12%). Q2: **468 placements (246 dV5)** vs 395 prior-year; installed base **11,710 (+12%)** |
| Recurring revenue vs procedure growth | **Progressing / accelerating** | Q1: I&A revenue +23% vs procedures +16%. Q2: I&A **+18%** vs procedures **+15%**. Recurring revenue (I&A $1.73B + Services $472.4M) outgrew procedures in **both** quarters. *Caveat recorded:* the Q1 release flags "customer buying patterns" as a contributing factor, so Q1's spread is not purely procedure-driven |
| da Vinci 5 upgrade cycle / margin uplift | **Progressing** | dV5 placements 180 → **246** units YoY in Q2; non-GAAP gross-margin guidance **raised** from 67.5–68.5% to **68.0–69.0%**, both ranges already absorbing a ~1.0% revenue tariff drag |
| Competitive moat (no named-IDN displacement) | **Intact, but facing its first real US regulatory competition in two decades** | J&J's **Ottava received FDA De Novo marketing authorization 2026-07-22** (primary: jnj.com) — a clearance to compete, **not** a displacement claim. Medtronic's Hugo cleared previously; CMR Surgical (Versius Plus) pursuing US entry. No competitor has disclosed displacing da Vinci at any named IDN |

### 3. Fundamental developments (window, with the load-bearing Q1/Q2 prints carried for context)

- **2026-04-21/22** — Q1 CY2026 (primary, company release): revenue $2.77B (+23% YoY), I&A +23% to $1.69B, da Vinci procedures +16%, 431 placements (232 dV5), installed base 11,395 (+12%), non-GAAP EPS $2.50 vs ~$2.11 consensus. FY26 procedure guide **raised** to 13.5–15.5%.
- **2026-07-16, 4:05pm ET** — **Q2 CY2026** (primary, isrg.intuitive.com): revenue **$2.89B (+19% YoY)**, GAAP EPS $2.29, non-GAAP EPS **$2.80** vs ~$2.51 consensus; **da Vinci procedures +15%**, Ion procedures +36%, worldwide combined +16%; **468 placements (246 dV5)**; installed base 11,710 (+12%); I&A **+18%** to $1.73B. FY2026 procedure guidance **REAFFIRMED at 13.5–15.5%** with new language "expects to be closer to the midpoint of this range"; non-GAAP GM guide raised to 68.0–69.0%. Results include a one-time **$28M / $0.08 per share** IEEPA tariff-refund benefit.
- **2026-07-16/17** — Stock fell **~14% to $345.42, a 52-week low, on a beat**. Attributed (secondary: Investopedia, IBD, Motley Fool, StockStory) to: (a) guidance reaffirmed rather than raised, read as a deceleration signal; (b) CFO commentary that Q2 **US** da Vinci procedure growth (+12%) saw "a modest adverse impact" from ACA enhanced-premium-subsidy expiration plus continued high-single-digit decline in bariatric cases tied to GLP-1 adoption; (c) reports of softening overall hospital surgical volumes and visibility into open Class II instrument recalls.
- **2026-07-20** — D entry filled, 0.1091 sh.
- **2026-07-22** — **J&J Ottava FDA De Novo authorization** for multiple general-surgery procedures (gastric bypass, gastrectomy, cholecystectomy, splenectomy, gastric sleeve, small-bowel resection, appendectomy, lysis of adhesions). **J&J scheduled an investor call on Ottava for 2026-08-03** — two days after this cycle closes. *Primary: jnj.com press release.*
- **2026-07-23** — Intuitive amended/restated its bylaws re: disregarding director-nominee votes from shareholders not complying with SEC universal-proxy rules (secondary summary of an 8-K). Governance/procedural; not thesis-material.
- **Ongoing (primary, FDA accessdata recall database)** — several open **Class II** recalls on da Vinci / dV5 components (cannula-mount screws susceptible to breaking; console column motor connector; camera-controller/vision-cart testing-standard nonconformance), mostly initiated Nov 2025–Apr 2026. Referenced by secondary press as a sentiment factor. **None alleges competitor displacement or names an IDN switching away from da Vinci.**

**Source-reliability finding (recorded deliberately).** A secondary blog (tikr.com, 2026-07-27) claims FY2026 da Vinci procedure guidance was "raised to 14%–16%" post-Q2. **This directly contradicts the primary source** — the company release and call confirm guidance was *reaffirmed* at 13.5–15.5% with a midpoint lean. The same source is the sole origin of an unverified "Q1 China placements were just 4 units" figure. **Treat all tikr.com figures in this name as unverified;** the company release is authoritative. Recorded so a future cycle does not pick the claim up as fact.

### 4. Invalidation criteria check — 4/4 NOT BREACHED

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "procedure growth <10% YoY 2 consec Q" | **NOT BREACHED** | Q1 CY26 **+16%**, Q2 CY26 **+15%**. Zero of the last two quarters below 10% | Intuitive Q1 (2026-04-21) and Q2 (2026-07-16) press releases, primary |
| 2 | "placements decline YoY 2 consec Q" | **NOT BREACHED** | Q1 431 vs 367 (+17.4%); Q2 468 vs 395 (+18.5%). **Both quarters grew YoY** | Same |
| 3 | "recurring-rev decouples down from procedures" | **NOT BREACHED** | Q1 I&A +23% > procedures +16%; Q2 I&A +18% > procedures +15%. Recurring revenue outgrew procedures in both quarters — accelerating, not decoupling downward | Same (financial-summary / income-statement sections) |
| 4 | "competitor discloses displacing dV at named large IDNs" | **NOT BREACHED** | No competitor disclosure of displacing da Vinci at any named large IDN. J&J Ottava's 2026-07-22 De Novo authorization is a **regulatory clearance to compete, not a displacement claim**; Medtronic Hugo and CMR Versius likewise name no IDN switching from da Vinci | jnj.com 2026-07-22 (primary); Maryland Daily Record, MedTechDive (secondary context) |

**Measurability note on criterion 4:** this is inherently a negative/absence test. It is measurable as NOT BREACHED today but can never be confirmed permanently satisfied — the correct ongoing discipline is a recurring competitor-disclosure search each M3 cycle, which is what was run here.

### 5. Sector & secular theme context

The multi-decade robotic-surgery adoption curve — the core of the thesis — remains intact. Three cross-currents developed in this window:

- **The first credible US regulatory competition in over two decades.** J&J's Ottava (table-integrated, general-surgery indication) cleared 2026-07-22, joining Medtronic's Hugo (urologic, cleared prior year) and CMR's Versius pursuing a US beachhead. This is the most consequential structural development for criterion 4 going forward: it creates the *regulatory precondition* for a future named-IDN displacement claim, even though none exists today.
- **Demand-side headwinds management named itself:** ACA enhanced-premium-subsidy expiration modestly dented US procedure growth; GLP-1 adoption continues to suppress bariatric volumes (high-single-digit YoY decline in that sub-segment). Under Strategy D these are precisely the "quarterly results and macro shifts that don't bear on the multi-year thesis" carve-out — **not exit-triggering unless they surface as a two-consecutive-quarter breach of criterion 1, which they have not.**
- **Tariff/China exposure:** FY2026 guidance embeds a ~1.0% revenue tariff impact in the GM range; Q2 carried a one-time $28M IEEPA refund. Manufacturing exposure is disclosed in Mexico (instruments/accessories) and Germany (endoscopes). **China-specific revenue/placement granularity is NOT DISCLOSED** in the sources reviewed — the only figure found is the unreliable secondary claim noted above.

### 6. Long-term tax treatment

LTCG 2027-07-20 — a 12-day-old position, so the horizon is not remotely a near-term consideration. No max hold. Because no completion marker is defined (§1), there is currently no mechanism that would prompt an exit on thesis *fulfilment* — only on invalidation. Flagged as a structural gap in the entry record; not resolvable by this packet.

### 7. Recommendation — **HOLD**

All four criteria are NOT BREACHED across both available quarters, with procedure growth comfortably above both the 13% trend metric and the 10% invalidation floor, placements growing rather than declining, and recurring revenue outgrowing procedures. The 2026-07-16/17 −14% move was a multiple de-rating on a beat-and-reaffirm quarter — the GO entry's own framing — and is explicitly not exit-triggering.

**Information gaps (tracked, none decision-blocking):**
- **J&J's Ottava investor call, 2026-08-03** — two days after this cycle. The next cycle should check that call and subsequent J&J messaging specifically for a **named-IDN displacement claim**, since Ottava is now cleared and commercial-traction claims are the most direct live test of criterion 4 available.
- **Q2 2026 10-Q** should be pulled directly to confirm China placement/revenue granularity; the only figure in circulation is from a source demonstrated unreliable in this same name.
- **Q3 CY2026 earnings date ~2026-10-20 is a third-party ESTIMATE**, not company-confirmed; confirm from isrg.intuitive.com/events-and-presentations.
- **Watch the Q1 "customer buying patterns" caveat:** if I&A growth compresses toward procedure growth in Q3, criterion 3 would still be unbreached but the spread would be normalizing rather than decoupling — worth noting, not acting on.

---

## Position — CRM (Salesforce) — Subtype B (trend-continuation)

**Tranche (1).** `D:CRM:2026-07-09` 0.2275 sh, cost basis $36.4811, LTCG 2027-07-09. **Mark $183.38 (2026-07-31 close) = $41.72 MV, +$5.24 unrealized (+14.4%).** CaR 1.48% of D NAV.
**Span covered:** entry (2026-07-09) → 2026-08-01. First M3 deep-dive.

### 1. Current thesis status — INTACT, but this is a low-information-content verdict

Original thesis (`0c68c3c1`, 2026-07-08, GO at MEDIUM-HIGH — the only D-strategy CRM entry): enterprise AI-agent monetization. Agentforce (agentic AI) and Data 360 are converting into a fast-growing, high-margin ARR stream layered onto ~150k existing customers, with **over half of Agentforce/Data-360 bookings coming from expansion of existing accounts rather than new logos**. The trend metric is explicitly **Agentforce+Data-360 ARR growth ≥50% YoY AND cRPO in the low double digits.** Entry was a disciplined below-market limit buy (0.35% under prior close) into a stock down ~37% YTD — framed as valuation-supported entry, not momentum.

**The honest caveat governs this whole section: Salesforce runs a January fiscal year, and the position's entire life to date sits inside a single inter-earnings gap.** The last print — **Q1 FY27, reported 2026-05-27** — *predates the entry itself*; the next, Q2 FY27, is not expected until early September. So "intact" here means principally that **nothing has yet had the opportunity to break**, not that fresh evidence confirmed the trend.

**Gap:** no completion criterion is stated in the entry record (same Subtype-B pattern as AMZN/UBER/TSM).

### 2. Multi-year driver check

*All figures below are from the Q1 FY27 print (2026-05-27) — the same data the thesis was built on. No new quarterly disclosure occurred inside this window.*

| Driver | Status | Evidence (source, date) |
|---|---|---|
| Agentforce + Data 360 ARR growth (≥50% YoY) | **Progressing** (as of last report) | Agentforce ARR $1.2B **+205% YoY**; Agentforce+Data 360 ARR ~$3.4B, **>200% YoY** (Salesforce IR release, 2026-05-27) |
| cRPO growth (low-double-digit cc) | **Progressing** (as of last report) | cRPO $33.6B, **+14% nominal / +13% cc** (8-K Ex-99.1, SEC EDGAR, primary). Q2 FY27 cRPO *guided* ~13% cc — guidance, not an actual |
| Non-GAAP operating margin (no YoY contraction) | **Progressing** | Q1 FY27 **34.8%** vs Q1 FY26 32.3% — **+250bps YoY** |
| FY27 revenue guide (no ≥~10% cut) | **Progressing** | Guidance **RAISED** to $45.9–46.2B (+11% YoY at midpoint) at the Q1 FY27 print. No change since |
| Existing-base expansion motion | **Progressing** (qualitative, unchanged) | Q1 FY27 call: "More than 50% of Agentforce and Data 360 bookings in Q1 came from existing customers expanding" |

### 3. Fundamental developments (2026-07-09 → 2026-08-01)

- **2026-07-21 — Morgan Stanley downgrade.** Adam Wood cut CRM Overweight → Equal-Weight, PT $287 → $185 (−35%), framed explicitly as *"AI thesis intact, timing concerns, cRPO weakness"* — a call about the **pacing** of monetization, not a claim that disclosed metrics deteriorated. Stock fell as much as −3.9% intraday, closed −2.2% at $170.06. *Secondary* (GuruFocus, Yahoo/24-7 Wall St syndication; the note itself not retrieved). **Under Strategy D a sell-side rating change is not an invalidation trigger.**
- **2026-07-24 — VA "Missionforce" contract.** US Department of Veterans Affairs awarded Salesforce a **$1.6B three-year Agentic Enterprise License Agreement** (a *ceiling*, not booked revenue — base year plus two renewal options; VA orders as needed) covering AI contact-centre support, scheduling and care coordination for ~17M veterans. Shares rose >4%. *Primary:* Salesforce press release, 2026-07-24.
- **Sector-wide multiple compression** — CRM down ~31–35% YTD through the window; Adobe and Intuit fell the same day as the MS downgrade, indicating a software-sector re-rating rather than a CRM-specific execution event.
- **Context predating but bearing on the window:** the Fin (ex-Intercom) acquisition ~$3.6B signed 2026-06-15 (expected to close Q4 FY27, reaffirmed as no impact to FY27 guidance) and m3ter (consumption billing/metering for Agentforce Revenue Management) closed 2026-07-01. Both continue the AI-monetization infrastructure buildout.
- **Starboard Value stake — UNRESOLVED/CONFLICTING.** Secondary aggregators contradict each other (full exit in Q1 2026 vs a ~50% stake increase to 1.3M shares); the latter appears to be a re-syndication of an **August 2025** CNBC piece about Q2 **2025**. The underlying 13F was not retrieved. **Not thesis-relevant; must not be cited as fact.**
- **No management change and no thesis-relevant 8-K** located inside the window.

### 4. Invalidation criteria check — 4/5 NOT BREACHED, 1 not yet evaluable

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "Agentforce/Data-360 ARR growth <~50% YoY" | **NOT BREACHED** (no new data in window) | Agentforce ARR $1.2B +205% YoY; combined ~$3.4B, >200% YoY | Salesforce IR release, Q1 FY27 (period ended 2026-04-30, reported 2026-05-27) |
| 2 | "cRPO <10% cc 2 consec Q" | **NOT BREACHED on the single available quarter; the two-quarter test CANNOT YET BE RUN** | Q1 FY27 cRPO **+13% cc** — above the 10% floor. The second data point needed to test "2 consecutive" (Q2 FY27) has not printed. Q2 is *guided* ~13% cc, but guidance is not an actual | 8-K Ex-99.1, SEC EDGAR (primary), balance date 2026-04-30 |
| 3 | "non-GAAP op margin contracts YoY" | **NOT BREACHED** | 34.8% vs 32.3% — expanded +250bps YoY | Q1 FY27 release, 2026-05-27 |
| 4 | "FY27 rev guide cut <~10%" | **NOT BREACHED** | Guide **RAISED** to $45.9–46.2B (+11%); no revision since | Q1 FY27 release; CNBC 2026-05-27 |
| 5 | "metric-immutability if Agentforce ARR stops being disclosed in original form >=2Q (CRM moving to disaggregated revenue reporting FY28)" | **NOT BREACHED — 0 of the required ≥2Q have accrued** | Salesforce announced (with the Q1 FY27 print) a shift to two disaggregated revenue **segment** categories — "Agentforce Apps" and "Data 360, Platform & Other" — replacing legacy cloud lines, with recast FY25–FY26 comparatives and full transition to segment-only reporting **beginning FY28**. That is a *segment-revenue* change, distinct from the **Agentforce ARR KPI** ($1.2B / $3.4B), **which was still disclosed in its original form at the Q1 FY27 print.** The non-disclosure clock has not begun | "FY27 Disclosure Update" investor presentation (company IR, primary); Q1 FY27 8-K Ex-99.1 confirms the ARR KPI still disclosed |

### 5. Sector & secular theme context

Enterprise agentic-AI adoption is accelerating broadly (Gartner projects 40% of enterprise applications will embed AI agents by end-2026, up from <5% in 2025 — secondary). Salesforce contests this against at least three well-capitalized classes of rival: Microsoft (Copilot Studio / M365 Agents), ServiceNow (Now Platform AI Agents), and **the frontier model vendors themselves** shipping agent-building primitives (OpenAI AgentKit, Google Vertex AI Agent Builder, Anthropic's Claude Agent SDK) that could over time disintermediate platform-specific agent layers. In-window reviews characterise Agentforce as differentiated for CRM-native workflows with data resident in Hyperforce tenancy (the lock-in argument), but note ServiceNow currently leads on agent governance and that Salesforce needs paid add-ons (Shield, Trust Layer) to match — a competitive vulnerability worth tracking, **not yet quantified as share loss**. Meanwhile the software-sector de-rating (Adobe/Intuit moving in sympathy) suggests much of CRM's YTD decline is macro "will AI cannibalize SaaS seats" repricing — precisely the category Strategy D carves out as **not** invalidating.

### 6. Long-term tax treatment

LTCG 2027-07-09, ~11 months out. No max hold. Nothing in the window bears on this — no partial sale, tax-lot event, or corporate action. The next catalyst inside the LTCG window is the Q2 FY27 print (~early September), which supplies the second cRPO data point.

### 7. Recommendation — **HOLD**

Every evaluable criterion reads NOT BREACHED and every driver is progressing in the direction it was at entry. The verdict is stated with its limitation attached: no new quarterly disclosure has occurred since entry, so this is confirmation-by-absence-of-contradiction, not fresh corroboration. The one material in-window event — the Morgan Stanley downgrade — is a **timing/pacing** call that under Strategy D is explicitly not exit-triggering, and the VA award is a genuine (if ceiling-not-revenue) commercial datapoint on the other side.

**Information gaps (tracked, none decision-blocking):**
- **Criterion 2's two-quarter test is un-runnable until Q2 FY27 prints** — the single most important near-term resolution point for this position.
- **Q2 FY27 earnings date UNCONFIRMED** — aggregator estimate ~2026-09-02; no Salesforce IR release announcing it had been located as of 2026-08-01 (the Q2 FY26 analogue printed 2025-09-03, so early September is the expected pattern).
- **Criterion 5 needs active monitoring from Q2 FY27 forward**: confirm at each print whether Agentforce ARR survives as a **standalone KPI** once FY28 segment-only reporting takes full effect. The clock is at 0 of ≥2 quarters.
- No completion criterion exists in the entry record — see the book-level note.
- Starboard 13F conflict unresolved; not thesis-relevant, must not be cited as fact.

---

## Position — DIS (The Walt Disney Company) — Subtype B (trend-continuation)

**Tranche (1).** `D:DIS:2026-05-07` 0.2822 sh, cost basis $31.4142. **Mark $96.19 (2026-07-31 close) = $27.14 MV, −$4.27 unrealized (−13.6%)** — the book's worst performer. CaR 1.27% of D NAV.
**Span covered:** 2026-07-01 → 2026-08-01.

### 1. Current thesis status — INTACT

Original thesis (`86df19dd`, 2026-05-07): a re-screen of an April 2026 NO-GO once three trigger conditions cleared on the Q2 FY26 print. Entertainment SVOD operating margin, having crossed double digits for the first time in Q2 FY26 (**10.6%**, up from Q1 FY26's 8.4%), sustains ≥10% over 12+ months, compounding with reaffirmed FY26 guidance (~12% adj EPS growth ex-53rd-week, ~16% incl.) and an accelerated buyback (raised $7B → "at least $8B" FY26). The primary driver was deliberately **reframed from "management-execution-quality" (the original NO-GO basis, a KL #4 pre-mortem residual) to financial-metric-traceable** — the SVOD margin trajectory itself — with management execution retained only as a bounded secondary contributor.

**Nothing in the window changed a reported metric**: Disney's last primary financial disclosure remains the Q2 FY26 8-K/10-Q (2026-05-06/07). The thesis holds on unchanged data. The window's substance is regulatory escalation and a pending divestiture, neither of which trips a criterion.

### 2. Multi-year driver check

| Driver | Status | Evidence (source, date) |
|---|---|---|
| SVOD operating margin ≥10% sustained | **Progressing** | 10.6% in Q2 FY26 (qtr ended 2026-03-28); guide reaffirmed "at least 10% for full fiscal year 2026" (8-K Ex-99.1, SEC EDGAR, 2026-05-06). No new print in window |
| FY26 adj EPS growth ~12% ex-53rd-week | **Progressing / unchanged** | Guidance issued 2026-05-06; **no revision and no guide-update 8-K in the window** |
| FY27 double-digit adj EPS growth | **Progressing / unchanged** | Reaffirmed at the Q2 print; not re-addressed in window |
| Buyback ≥$8B FY26 | **Progressing — ahead of pace** | H1 FY26 (six months to 2026-03-28) repurchases **$5.5B** per the 10-Q cash-flow statement — **69% of the full-year $8B target already executed at the half** |
| Management continuity (secondary, bounded) | **Progressing** | D'Amaro's team executing announced pillars: divesting the A+E Global Media 50% linear-TV stake to Hearst for >$1B — the first strategic divestiture under D'Amaro, consistent with "reduce linear exposure, reallocate to streaming/tech", not a reversal. CFO Johnston has separately said Disney does not plan to spin off or sell ABC/ESPN; the A+E sale is a mid-tier cable JV exit, not a core-network divestiture |

### 3. Fundamental developments (2026-07-01 → 2026-08-01)

- **2026-07-14** — **Disney IR confirms Q3 FY26 earnings for Wednesday 2026-08-05, 8:30am ET, before market open** (investors.thewaltdisneycompany.com, primary; Wall Street Horizon marks it CONFIRMED). **This resolves the prior cycle's carried-forward flag** ("~2026-08-05 unconfirmed, specifically not Aug-12") in favour of **2026-08-05 — four days after this M3 cycle closes.**
- **Through July, escalating — FCC review of ABC's 8 TV-station licences** (opened by Chairman Carr, late April 2026). The public-comment period closed **2026-07-29** with >150,000 comments; ABC/Disney filed a formal reply on 2026-07-29/30 urging dismissal of the proceeding as "retaliation" tied to the Jimmy Kimmel/late-night controversy. **Reply-comment deadline is 2026-08-05** — the same day as the Q3 print. CNN reports the likely next step is "a referral for an official hearing, sometime in August," and that Disney executives are privately weighing a First Amendment lawsuit. **No final FCC order has issued and no Disney 8-K claiming material adverse EPS impact exists.** *All litigation-posture detail here is secondary reporting* (Reuters, CNN, Hollywood Reporter, Variety, LA Times, 2026-07-24 → 07-30); the primary sources would be the FCC docket and any future Disney 8-K.
- **2026-07-30/31** — Disney to sell its 50% A+E Global Media stake (A&E, History, Lifetime, FYI) to JV partner Hearst for **>$1B all-cash**, expected to be formally announced with the 2026-08-05 print (Bloomberg Law, TheWrap, dealroom.co — **trade press citing people familiar; not yet an 8-K** as of 2026-08-01).
- **No 8-K, 10-Q, or guidance revision was located for DIS inside the window itself.**

### 4. Invalidation criteria check — 5/5 NOT BREACHED / NOT TRIGGERED

| # | Criterion (abbreviated; full text in the position record) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | Primary — Entertainment SVOD op margin <8% for 2 consecutive quarters | **NOT BREACHED** | Last two reported quarters: Q1 FY26 **8.4%**, Q2 FY26 **10.6%** — both above the 8% floor and above the 8.4% baseline net of the −40bps tolerance. No new quarter printed in window | 8-K Ex-99.1, SEC EDGAR, 2026-05-06 |
| 2 | Secondary — FY26 adj EPS growth guide cut to ≤6% | **NOT BREACHED** | Guidance stands at ~12% ex-53rd-week / ~16% incl., last reaffirmed 2026-05-06; **no revision and no guide-cut 8-K in the window** | Q2 FY26 shareholder letter / 8-K |
| 3 | Buyback — ≤$3B at H1 close, **≤$5B at Q3 FY26 print**, or suspension/reduction 8-K | **NOT BREACHED — and the Q3 leg is now un-breachable by arithmetic** | H1 FY26 repurchases **$5.5B**, far above the ≤$3B H1 floor. **These are cumulative fiscal-year-to-date checkpoints and cumulative repurchases are monotonic — H1's $5.5B already exceeds the $5B Q3 floor, so the Q3 leg cannot be tripped short of a restatement.** Only the third limb (a suspension/reduction 8-K) remains live, and none has been filed | 10-Q cash-flow statement, SEC EDGAR, filed ~2026-05-07. *This arithmetic closure is M3's synthesis, not a company disclosure* |
| 4 | Metric-immutability — SVOD OI/margin undisclosed in current form ≥2 consecutive quarters | **NOT BREACHED** | Disclosed in current form in both Q1 and Q2 FY26; no segment-reporting restructuring announced. No new print in window to start a non-conforming count | Q2 FY26 8-K Ex-99.1 |
| 5 | Regulatory-impairment **escalation** (FCC final order **AND** Disney 8-K of material adverse FY26/FY27 EPS impact) — *review trigger, NOT auto-invalidation* | **NOT TRIGGERED** | The review is active and escalating, but **both prongs are required and neither is met**: no final FCC order, no Disney 8-K claiming material adverse EPS impact. Escalation profile materially higher than at the prior cycle | Secondary reporting 2026-07-24 → 07-30; no primary FCC order or 8-K located |

### 5. Sector & secular theme context

Streaming margin competition persists (Netflix's segment margin structurally leads, per the entry's own May 2026 framing; not re-verified this cycle). The "media companies politicized by content decisions" theme is sharpening: the ABC licence fight runs in parallel to Paramount-Skydance's own regulatory exposure — the same outside counsel (Beth Wilkinson) represents both — which argues for a **sector-wide regulatory-risk premium on legacy broadcast licence holders rather than a DIS-idiosyncratic event.** The secular linear→streaming rotation is evidenced structurally by the A+E divestiture (exiting a profitable but declining linear cable JV) — consistent with, not contrary to, the SVOD-centric thesis. Parks/consumer-discretionary macro sensitivity flagged at entry stays a background risk; Q3 Experiences data is not yet out.

### 6. Long-term tax treatment — **DATA-QUALITY DEFECT, flagged not fixed**

The position record's `ltcg_date` is **NULL**. The entry record's own pending-queue subsection (2026-05-07) states the 12-month LTCG-eligible date as **2027-05-08**. This is a `state.current_positions` gap that should be corrected to 2027-05-08 by the ledger owner — **not re-derived or written by this research packet.** Nothing this cycle changes the horizon; the first falsifiable checkpoint is the now-confirmed 2026-08-05 print.

### 7. Recommendation — **HOLD**

All five criteria are NOT BREACHED / NOT TRIGGERED. Both quantitative drivers are tracking at or ahead of plan (H1 buyback at 69% of the full-year target; SVOD margin 10.6% vs a ≥10% commitment), and FY26 guidance is unrevised through the window. The −13.6% mark-to-market is explicitly **not** exit-triggering under Strategy D.

**Two dated items land four days after this cycle closes and belong in M4/M5's carry-forward, not in a research-deferral:**
- **Q3 FY26 print, 2026-08-05 (CONFIRMED)** — supplies the third consecutive SVOD-margin point (making criterion 1's two-quarter test live on fresh data), the Q3 cumulative buyback figure, and any guidance reaffirmation/revision. **This is the first live test of the reframed Subtype-B thesis since entry.**
- **FCC reply-comment deadline, also 2026-08-05**, with a possible referral-to-hearing during August. A referral would *not* trip criterion 5 (which needs a final order **and** an 8-K), but would raise the escalation profile further.

**Why not "further research":** criterion 5 is a *conditional future* review trigger, not a present information gap, and the gating facts arrive on a known date four days out. Routing this to a research-deferral would attach M4's `conservative_default = exit if unresolved` to a thesis whose every criterion is currently clear — disproportionate to the evidence. Carry-forward, not deferral.

---

## Position — RTX (RTX Corporation) — Subtype B (trend-continuation)

**Tranche (1).** `D:RTX:2026-04-27` 0.1601 sh, cost basis $28.3215 (incl. commission + DRIP). **Mark $215.22 (2026-07-31 close) = $34.46 MV, +$6.14 unrealized (+21.7%)** — the book's best performer. CaR 1.15% of D NAV. **Oldest D position (97 days).**
**Span covered:** 2026-07-01 → 2026-08-01 (prior M3 cycle → today).

### 1. Current thesis status — INTACT, strengthening on a beat-and-raise

Original thesis (`a98bc693`, 2026-04-26): aerospace/defense prime entered counter-cyclically on a sentiment-driven −7.7% post-Q1 pullback judged not thesis-breaking. Drivers: (a) GTF/PW1100 recovery — AOG reduction, MRO ramp, GTF Advantage entry; (b) record and growing commercial+defense backlog giving multi-year revenue visibility; (c) FY26 FCF/EPS guide trajectory; (d) US defense-procurement tailwind. A price-based stop proposed during construction was **explicitly dropped** as contrary to Strategy D's no-stop design.

**Q2 2026 (2026-07-23) was a beat-and-raise across the board, and five of six criteria moved *further* from breach.** All five Q1'27 falsifiable milestones are already satisfied or on track — three quarters early. Notably the backlog milestone (≥$280B by Q1'27) is **already exceeded at $289B**.

**In-window D-strategy decision:** `92a66e1c` (2026-07-26) — **NO-GO on an add tranche**, declined *solely* on Entry criterion 6 momentum-deferral (+9.2% two-session move to a fresh 30-day high on 3–4× volume). It explicitly reaffirmed the six-criterion hard gate as unbreached and left the existing position untouched. This M3 independently re-verified the underlying Q2 facts against primary sources; they check out.

### 2. Multi-year driver check (against the entry's named Q1'27 falsifiable milestones)

| Driver / milestone | Status | Evidence (source, date) |
|---|---|---|
| AOGs down ≥25% from YE2025 | **Progressing — ahead of the Q1'27 target** | "AOG levels down 25% year-to-date", on 43% YoY MRO output growth and 23% lower turnaround time (Q2'26 call, Calio/Mitchill, 2026-07-23) |
| GTF Advantage EIS in 2026 | **Progressing, on schedule** | "Pratt received aircraft certification for the GTF Advantage engine and started its deliveries to Airbus… entry into service later this year and full production cutover in 2028" (Q2'26 call, Calio). EASA cert validated 2026-04-17 |
| Backlog ≥$280B by Q1'27 | **Already exceeded** | **$289B** at Q2'26 vs $271B Q1'26 and $268B Q4'25 (Q2'26 press release, 2026-07-23) |
| FY26 adj EPS within $6.70–6.90 | **Exceeding — guide raised above the original band** | FY26 adj EPS guide raised to **$7.10–7.25** (Q2'26 press release) |
| Defense organic growth ≥mid-single-digits/qtr | **Well above threshold** | Raytheon segment sales $8.269B, **+18% organic**; FY26 Raytheon outlook raised to "high single digits to low double digits" organic (Q2'26 call, Nathan Ware) |

### 3. Fundamental developments (2026-07-01 → 2026-08-01)

- **2026-07-07** — Airbus and P&W jointly state the A220 GTF reliability crisis is "on track for resolution by end of 2026"; officials call the A220 AOG crisis essentially over (Leeham News — *secondary, paywalled, not independently confirmed against a primary filing*).
- **2026-07-20/22** — **Farnborough:** GTF surpasses 800 orders/commitments YTD 2026; order backlog >8,000 engines; >14,000 lifetime orders/commitments across 90+ customers (RTX/PRNewswire, primary).
- **2026-07-23 — Q2 2026 results** (press release + 8-K/10-Q same date): adjusted sales **$24.7B (+14% reported, +16% organic)**; GAAP EPS $1.57; **adj EPS $1.89 (+21% YoY)** vs $1.66 consensus. Segments: Collins $8.21B (~+13% organic), Pratt $8.89B (+17% organic; commercial aftermarket +25%, military +23%, commercial OE −8% on mix), Raytheon $8.27B (+18% organic). **Backlog $289B** ($170B commercial / $119B defense), +22% YoY, **+6% sequentially**. Q2 FCF $2.878B (vs −$0.072B Q2'25); H1 FCF $4.187B. **FY26 guidance raised:** adj sales $95.0–96.0B (from $92.5–93.5B), organic 8–9% (from 5–6%), adj EPS $7.10–7.25, **FCF $8.50–8.75B** (from $8.25–8.75B). Raytheon Q2 bookings $19.9B, **book-to-bill 2.42**. Agreed to sell Raytheon's Blue Canyon Technologies for $620M.
  - **$69M pre-tax charge "related to a litigation matter"**, described by management as non-operational; the public release does **not** identify which matter. **UNVERIFIED** — see §7.
  - Per the Q2 10-Q: Pratt powder-metal accrued customer compensation **reduced to $0.4B** (from the ~$3B 2023 charge base) with ~$150M of related payments in Q2 — a drawdown of the known issue, not a new charge.
- **2026-07-23 (call)** — Calio on FY27 defense, verbatim: *"we're encouraged to see bipartisan support for a significant increase in 2027 defense spending. The base budget request of $1.1 trillion represents a roughly 25% increase year-over-year, along with meaningful increases in funding for RTX priority programs, including Tomahawk, LTAMDS and Standard Missile."*
- **~2026-07-30** — $1.3B F135 sustainment contract awarded (Pratt & Whitney, PRNewswire).
- **Price:** $194.88 (07-22) → $212.32 (07-23, **+8.95%** on the beat-and-raise) → $215.22 (07-31).

### 4. Invalidation criteria check — 6/6 NOT BREACHED

| # | Criterion (verbatim) | Verdict | Measured | Source / as-of |
|---|---|---|---|---|
| 1 | "Material adverse Airbus damages ruling > $2B" | **NOT BREACHED** | **No ruling of any kind has issued.** Airbus's formal damages claim (escalated March 2026) remains unresolved and unquantified; reported potential exposure is characterised as "hundreds of millions" — below $2B even hypothetically. Q2 10-Q language: litigation matters "not expected to have a material adverse effect" | Reuters 2026-03-19; RTX Q2'26 10-Q. **Measurability note:** this criterion can only ever read NOT BREACHED until an actual adjudicated or settled figure exists — a pending unquantified claim cannot partially trip it |
| 2 | "New powder-metal-style mass quality event > $1B incremental charge" | **NOT BREACHED** | No new quality event. The 2023-origin program is winding **down**: accrued compensation reduced to $0.4B, ~$150M routine payments in Q2 | RTX Q2'26 10-Q, 2026-07-23 |
| 3 | "GTF Advantage EIS slips beyond Q1'27" | **NOT BREACHED** | No slip. First production engines delivered to Airbus in Q2'26; EIS reaffirmed "later this year [2026]" — well inside the Q1'27 bar | Q2'26 call (Calio, verbatim), 2026-07-23 |
| 4 | "Backlog declines two consecutive quarters" | **NOT BREACHED — opposite trend** | $268B (Q4'25) → $271B (Q1'26) → **$289B (Q2'26)**, +6% sequential / +22% YoY. Both quarters shown; neither declined | Q2'26 press release + call, 2026-07-23 |
| 5 | "FY26 FCF guide cut below $7.5B floor" | **NOT BREACHED — guide raised** | FY26 FCF guide **raised** to $8.50–8.75B. The bottom of the range is $1.0B above the invalidation floor | Q2'26 press release, 2026-07-23 |
| 6 | "FY27 defense procurement cut >=10% YoY" | **NOT BREACHED — opposite trend** | FY27 DoD **request** $1.5T (incl. $1.15T discretionary base + $350B reconciliation), a ~25% base increase; House Appropriations FY27 Defense bill $1.072T discretionary / $248.3B procurement (subcommittee markup 2026-06-10), with explicit growth for Tomahawk, LTAMDS, Standard Missile, THAAD, PAC-3 | Q2'26 call (Calio); House Approps FY27 summary 2026-06-10; CSIS; CRS R49023. **Measurability note:** not fully measurable as *enacted* law until FY27 appropriations conclude (Q4 2026 / Q1 2027); the current read is at request/markup stage and is unambiguously not a cut |

### 5. Sector & secular theme context

Aerospace OEM/aftermarket demand is robust across all three segments (double-digit organic growth each). Commercial aftermarket strength is structurally tied to airlines flying older jets longer while GTF fleet issues resolve — a near-term tailwind to Pratt's economics even as remediation continues. Defense demand is pulled by conflict-driven munitions restocking and a historically large (though **not yet enacted**) FY27 request, plus strong international bookings (Raytheon backlog now 48% international, +4pp YoY). Peer primes reported similarly strong results, corroborating a **sector-wide, not RTX-idiosyncratic**, upcycle. The Airbus/Pratt engine-allocation dispute (deliveries vs MRO material priority) remains genuine sector friction but has not escalated to an outcome or capped three consecutive guidance raises.

### 6. Long-term tax treatment — **DATA-QUALITY DEFECT, flagged not fixed**

The entry record specifies a 12+ month timeline "LTCG-eligible per 2.23" with a **Q1'27 falsifiable-milestone reassessment** — explicitly a *reassessment trigger, not a hold limit or scheduled exit*. The entry states verbatim: *"D long position has no price-based stop per Strategy.md design; the position runs to thesis-invalidation by (i)-(vi) above OR negative outcome on the falsifiable-milestone reassessment at Q1'27 earnings."* **Nowhere does the entry specify a maximum hold or time exit** — consistent with Strategy D having no max hold.

The `state.current_positions` row nevertheless carries **`time_exit_date = 2027-04-27` with `ltcg_date = NULL`**. 2027-04-27 is exactly 12 months after the 2026-04-27 execution — i.e. it is what `ltcg_date` should hold. **The two fields' values appear to have been transposed at write time.** No entry-record basis exists for a time exit. *Not corrected here* (M3 is research-only); flagged for ledger adjudication — left uncorrected, a future routine reading `time_exit_date` could stage an unfounded forced exit in April 2027.

### 7. Recommendation — **HOLD**

All six criteria are unambiguously NOT BREACHED and five moved *further* from breach this quarter. All five Q1'27 falsifiable milestones are satisfied or on track three quarters early. The only in-window D decision (2026-07-26) declined an *add* on entry-timing discipline while affirming thesis health — it is not a signal about the existing position.

**Information gaps (tracked, none decision-blocking):**
- **The $69M Q2 litigation charge is unattributed.** The 10-Q Legal Proceedings / Commitments & Contingencies note (Note 16, filed 2026-07-23) would establish whether it relates to Airbus, GTF litigation, or something unrelated. Worth pulling directly next cycle if criterion 1 ever becomes close-run; it is not close-run now.
- **Airbus damages claim:** no forum, quantum, or timeline disclosed as of 2026-07-31. Next disclosure would come via a 10-Q/10-K legal-proceedings update or a definitive report of a filed arbitration/suit.
- **FY27 appropriations not enacted** (House markup only). Re-check the enacted topline and RTX-relevant program lines once appropriations finalize (Q4 2026 or a CR period).
- **Ledger defect above** — the one item genuinely needing action, by the ledger owner, not by an exit.
- **Next hard checkpoint:** Q3 2026 earnings **2026-10-20** (Yahoo Finance calendar; FMP calendar plan-blocked this session, so **not cross-checked against a primary IR release**).

---

# Carry-forward for M4 / M5

## Recommendation summary

| Name | Criteria status | Recommendation | Citation |
|---|---|---|---|
| AMZN | 5/5 NOT BREACHED | **HOLD** | No criterion met. AWS +37% YoY (5th consecutive acceleration), margin 39.4% (series high), backlog $496B primary-confirmed by the 10-Q filed 2026-07-31 |
| GOOGL | 5/5 NOT BREACHED | **HOLD** | No criterion met. Cloud +82% YoY, margin 35.6%, backlog $514B; **no structural remedy in any jurisdiction**, verified 2026-08-01 against the E.D. Va. docket and the EU AT.40670 case page |
| TSM | 3/3 NOT BREACHED | **HOLD** | No criterion met. GM 67.7% and USD rev +33.7% YoY across both required quarters; sub-7nm mix rising 74%→77%; criterion 3 contradicted by TSM's own capex raise to $60–64B |
| UBER | 4/4 NOT BREACHED | **HOLD** | No criterion met. GB cc +22%/+21% across the two required quarters; adj-EBITDA margin **expanding** (+40bps, +26bps YoY); Uber One 46M→>50M |
| ISRG | 4/4 NOT BREACHED | **HOLD** | No criterion met. Procedures +16%/+15%; placements +17.4%/+18.5% YoY; recurring revenue outgrew procedures in both quarters; no named-IDN displacement disclosed |
| CRM | 4/5 NOT BREACHED, 1 not yet evaluable | **HOLD** | No criterion met. Criterion 2's two-quarter cRPO test **cannot be run until Q2 FY27 prints (~Sept 2026)**; the single available quarter is +13% cc, above the 10% floor |
| DIS | 5/5 NOT BREACHED / NOT TRIGGERED | **HOLD** | No criterion met. SVOD margin 8.4%/10.6% vs an 8% floor; H1 buyback $5.5B vs a ≤$3B floor; criterion 5 requires **both** a final FCC order and a Disney 8-K of material adverse EPS impact — neither exists |
| RTX | 6/6 NOT BREACHED | **HOLD** | No criterion met. Backlog $289B (+6% seq); FY26 FCF guide **raised** to $8.50–8.75B vs a $7.5B floor; GTF Advantage EIS on schedule for 2026; five of six criteria moved further from breach |

**No exits staged. No research-deferrals raised** — see finding F-6 for the reasoning. **No IMMEDIATE-ACTION flag**, therefore no `ops.sp_raise_alert('warning','M3','immediate_action_flagged',...)` call is due this cycle.

## Dated items M4/M5 should carry (monitoring, not deferrals)

| Date | Item | Bears on |
|---|---|---|
| 2026-08-03 | J&J Ottava investor call | ISRG criterion 4 — first live test now that a credible competitor is FDA-cleared |
| 2026-08-05 | **DIS Q3 FY26 earnings (CONFIRMED)** | DIS criteria 1, 2, 3 — first live test of the reframed Subtype-B thesis since entry |
| 2026-08-05 | FCC reply-comment deadline, ABC licence proceeding | DIS criterion 5 (escalation trigger) |
| 2026-08-05 | **UBER Q2 2026 earnings (CONFIRMED)** | UBER criteria 1–3 — first genuinely new quarter since entry |
| ~2026-09-02 (**unconfirmed**) | CRM Q2 FY27 earnings | CRM criterion 2 — first time the two-quarter cRPO test becomes runnable; also starts criterion 5's disclosure-immutability clock |
| ~2026-10-15 (**estimated**) | TSM Q3 CY2026 | TSM criteria 1, 2 — third consecutive quarter |
| ~2026-10-20 / 10-28 / 10-29 (**all unconfirmed**) | RTX, GOOGL, AMZN Q3 prints | Respective criteria |
| **Any time — triage immediately, do not hold for the monthly cycle** | Brinkema's US ad-tech remedies ruling (E.D. Va. 1:23-cv-00108); EU AT.40670 compliance-plan decision | **GOOGL criterion 4** — the only two live paths to a structural remedy |
| Mid-August 2026 | TSMC July monthly revenue | First data point that could reveal Kumamoto earthquake production impact (currently NOT DISCLOSED) |

## Items requiring action by an owner other than M4's exit path

1. **RTX ledger field transposition** (`D:RTX:2026-04-27`): `time_exit_date = 2027-04-27` with `ltcg_date = NULL`. The entry record specifies **no time exit**; Strategy D has **no maximum hold**. 2027-04-27 is the LTCG date. Left uncorrected this could stage an unfounded forced exit in April 2027. **The highest-priority hygiene item in this file.**
2. **DIS `ltcg_date` is NULL** (`D:DIS:2026-05-07`); the entry record states 2027-05-08.
3. **Finding F-1** — the systematic absence of thesis-completion criteria across the whole D book — is a *thesis-construction* discipline matter for future entries, **not** retroactively fixable on open positions (criteria are immutable for a position's life). Routed to M4 for onward handling; the open `revise-premortem-D-2026-a3` queue item and the 2026-07-30 AR_orc cycle-5 TIER 1 DEFECT outcome are the natural venue.
4. **Finding F-2** — capex-driven FCF compression at AMZN (TTM −$7.6B) and GOOGL (first negative-FCF quarter, −$5.86B) is uncovered by any invalidation criterion in either thesis, and correlated across the book's two largest positions. Recorded for future thesis construction; not actionable against open positions.

## Method and sourcing notes

- Every invalidation criterion was tested against **primary sources** where they exist — SEC 8-K/10-Q/10-K filings, company IR releases, earnings-call transcripts, the FDA recall database, court dockets, and EU Commission case pages — with secondary reporting labelled as such throughout. Two-consecutive-quarter tests were evaluated on **both** required quarters or explicitly reported as not-yet-runnable; none was inferred from a single quarter.
- Load-bearing figures that remain **secondary-sourced pending primary confirmation** are flagged in place: the hyperscaler capex guidance underpinning TSM's criterion 3; Amazon's ~$220B capex figure (earnings call, not an SEC filing); the DIS A+E/Hearst divestiture (trade press, no 8-K yet).
- One secondary source was found to be **factually wrong** and is recorded in F-5 so a later cycle does not adopt its claims.
- The correlation matrix (F-7) was computed from adjusted closes and independently re-verified; its window shortfall versus the specified 252 days is stated rather than glossed.

2026-08

# Monthly D Position Deep-Dive — August 2026 cycle, monthly_ftd fire (review window 2026-08-01 → 2026-08-03)

**IMMEDIATE-ACTION flag: NONE.** No D position shows material thesis invalidation. Across **9 names and 12 tranches** there are **39 at-entry invalidation criteria** (AMZN 5, GOOGL 5, TSM 3, UBER 4, ISRG 4, CRM 5, DIS 5, RTX 6, GEV 2): **38 are NOT BREACHED**, and the remaining one — CRM criterion 2 — is clear on the single quarter available (+13% cRPO against a 10% floor) but its two-consecutive-quarter test **still cannot be run**, because Salesforce's January fiscal year means no new quarter has printed since entry.

**Eight recommendations are HOLD. One — GEV — is FURTHER RESEARCH**, and it is *not* a thesis-health call: GEV's two invalidation criteria are the furthest from breach of anything in the book. The gap is an **entry-eligibility** question the entry record itself raised and pre-committed to resolving *before* capital was committed, and which was still open when the order was crafted and filled. See **F-8**, which is the substantive new finding of this cycle.

---

## Why this file was rewritten, and what "span covered" means here

**This edition SUPERSEDES the 2026-08-01 edition of this file.** M3 fired twice inside the 2026-08 monthly period:

- **2026-08-01 (Saturday)** — completed 08:25 MT, wrote the 8-name edition. 2026-08-01 is **not a trading day** (`state.market_calendar.is_trading_day = FALSE`).
- **2026-08-03 (Monday)** — this run. 2026-08-03 **is** the first *trading* day of August, i.e. the canonical `monthly_ftd` slot.

The same-day double-run guard is keyed to `run_date` and correctly did not fire (0 completed M3 rows for 2026-08-03). The same Aug-01/Aug-03 double-fire hit M1a, M1b and M2; **M2 likewise re-ran today and rewrote its August edition**, so this is a fleet-wide boundary artifact, not an M3-specific fault. Recording it here so a future audit does not read two August M3 completions as a duplicate-work defect.

**Span covered — stated honestly, two ways.** `state.routine_catchup_window` gives M3 `window_days = 2.01` against a `monthly_ftd` fallback of 31 — **cadence-normal, no missed monthly cycle, no multi-period catch-up sub-sections required.**

- **Incremental research window: 2026-08-01 → 2026-08-03.** For the eight carried names this is a two-day window and it is genuinely near-empty: independent sweeps found **no 8-K, no 10-Q, no material corporate event and no new company-specific analyst trigger** dated 08-01 through 08-03 for AMZN, GOOGL, TSM, UBER, DIS or CRM; one program press release for RTX; one third-party event (J&J's Ottava call) for ISRG. That is reported as a clean empty window rather than padded.
- **What this edition therefore adds over the 08-01 edition, and why it is not a re-print:** (1) a **ninth position, GEV, opened and filled today** — a full first deep-dive, and a materially different book; (2) **F-4's two ledger defects are now CORRECTED** and verified as such; (3) **three of the four dated events F-3 flagged have now resolved or are resolvable**, most importantly the J&J Ottava call bearing on ISRG criterion 4; (4) the **macro regime changed** — the 2026-08-01 edition read the fundamental axis as "reflation-tilt + neutral risk" from the stale 2026-07-01 M1a; today's M1a/M1b scored it **stagflationary shock + hawkish policy**, and SPY Trend was re-measured **NEUTRAL → UP**; (5) **F-8**, an entry-eligibility finding that did not exist on 08-01 because the position did not exist on 08-01.

**Scope is roster-derived.** This routine covers every roster-active strategy with `review_cadence: long_horizon` in `strategy/roster.yaml`. Enumerated this run: A, B, C, E are `reactive`; **D alone is `long_horizon`** (`roster_state: adopted`, `per_strategy_routine: null`). Scope is therefore exactly D, unchanged. A future SISA `long_horizon` graduate would appear here automatically as its own `## Strategy <code>` section.

---

## Scope and book state

**The book grew from 8 names to 9, and from 11 tranches to 12.** The new name is **GE Vernova (GEV)**, entered today via D2's drain of the overdue `rescreen-GEV-D-20260731` queue item. D remains comfortably above its concurrent-position floor of 5.

| Name | Tranches | Shares | Cost basis | Mark (08-03) | Market value | Unrealized | CaR % of NAV | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **GEV** | 1 (08-03) | 0.1244 | $120.66 | $994.24 | $123.68 | +$3.03 (+2.5%) | 4.88% | **FURTHER RESEARCH** |
| **AMZN** | 2 (07-09, 07-30) | 0.3464 | $88.2367 | $285.82 | $99.01 | **+$10.77 (+12.2%)** | 3.57% | HOLD |
| **GOOGL** | 2 (07-09, 07-26) | 0.2577 | $87.8234 | $368.50 | $94.96 | +$7.14 (+8.1%) | 3.55% | HOLD |
| **TSM** | 2 (07-21, 07-29) | 0.1550 | $64.0134 | $402.76 | $62.43 | −$1.59 (−2.5%) | 2.59% | HOLD |
| **ISRG** | 1 (07-20) | 0.1091 | $38.1316 | $371.76 | $40.56 | +$2.43 (+6.4%) | 1.54% | HOLD |
| **UBER** | 1 (07-09) | 0.5156 | $37.7457 | $71.47 | $36.85 | −$0.90 (−2.4%) | 1.53% | HOLD |
| **CRM** | 1 (07-09) | 0.2275 | $36.4811 | $189.50 | $43.11 | **+$6.63 (+18.2%)** | 1.48% | HOLD |
| **DIS** | 1 (05-07) | 0.2822 | $31.4142 | $98.13 | $27.69 | **−$3.72 (−11.8%)** | 1.27% | HOLD |
| **RTX** | 1 (04-27) | 0.1601 | $28.3215 | $216.14 | $34.60 | **+$6.28 (+22.2%)** | 1.15% | HOLD |
| **Total** | **12** | — | **$532.82** | — | **$562.90** | **+$30.07 (+5.64%)** | **21.56%** | — |

*Marks are the **2026-08-03 IBKR connector snapshot** (`get_account_positions`), read directly from the authenticated account — the authoritative source per Operating_Protocols.md §11. Secondary aggregator quote pages disagreed with these on several names by material amounts (most sharply ISRG, where an aggregator showed a 08-03 range of $340.61–$355.00 against the connector's $371.76). The connector figures are internally consistent with its own `daily_pnl` field on every name, and are used throughout; the aggregator divergence is recorded in **F-5** rather than silently dropped.*

*ISRG's row is the **Strategy D tranche only** (0.1091 sh). The account also holds a separate `B:ISRG:2026-07-21` position of 0.1388 sh; the connector reports the combined 0.2479 sh, which has been split back out here. The B tranche is out of scope for this routine.*

**Envelope compliance (Rev 43 sizing).** Capital-at-Risk for long-only equity is the full position notional — there is no stop, so the honest worst case is total loss. Measured against D NAV of **$2,471.35**.

*A methodological ambiguity, stated rather than silently resolved:* Strategy D defines CaR as a percentage of strategy portfolio value **at entry**, which is when the budget is *set* — but for an ongoing monitoring check the honest current worst case is the **current market value**, not the historical cost basis. The prior edition used cost basis. **Both are reported below, and every rail passes under either.** Cost-basis figures are the ones carried in the table above, because they are what makes cycle-over-cycle comparison meaningful.

- **Per-name CaR ≤ 10%** — largest is **GEV at 4.88% on cost basis / 5.00% on market value**, which displaces AMZN (3.57% / 4.01%) as the book's largest single-name exposure. All nine comply with wide margin on both bases.
- **Per-strategy deployed CaR ≤ 75%** — aggregate **21.56% on cost basis / 22.78% on market value**, up from 16.68% last cycle on the GEV entry. Complies with very wide margin.
- **GICS sector ≤ 30% of NAV** — the largest bucket **changed this cycle**. It is now **Industrials (RTX + UBER + GEV) at $186.72 = 7.56%** of NAV on cost basis (7.87% on market value), up from 2.86%; then Communication Services (GOOGL + DIS) 4.83%, Info Tech (TSM + CRM) 4.07%, Consumer Discretionary (AMZN) 3.57%, Health Care (ISRG) 1.54%. All far inside the cap. (UBER is Industrials / Passenger Ground Transportation post-2023 GICS revision; GEV is Industrials / Electrical Equipment.)

**NAV denominator caveat — and it is not staleness, it is a filter defect.** `analytics.strategy_nav` reads `nav = $2,471.35` with `deployed_mv = $426.80`. That `deployed_mv` **excludes GEV entirely** — recomputing the book from `state.current_positions` *without* GEV reproduces both `deployed_mv` and `unrealized_pnl` to the cent. The GEV entry note complained it was "sized off a stale `analytics.strategy_nav`"; the measurement pass for this file identified the actual mechanism, which is a **case-sensitive status filter plus a missing curated mark**, not staleness. **See F-11** — it is a recurring, cross-strategy defect, not a GEV quirk.

Using **$2,471.35 as the NAV denominator is nonetheless correct**: `nav` is built from deposits + realized + unrealized + dividends, the GEV deployment is cash-to-equity *within* D, and it is the same denominator both the entry and the 08-01 edition used — so the percentages here are comparable across cycles. Every CaR figure in this file is computed from `state.current_positions` directly and is therefore unaffected by the view defect. It is `deployed_mv` that is wrong, not `nav`.

**D engine state (informational; not exit-triggering).** `perf.strategy_daily` 2026-07-31 (latest computed row): `deployed_unit_value` **1.049893** (+4.99% total return on deployed capital), `peak_unit_value` 1.049893, `current_drawdown` **0.00%**, `sgov_index` 1.009624, **`excess_vs_sgov` +3.99%**, `deployed_days` 67, `closed_trades` 0, `gate_n` 30. All `perf.kill_flags` are **FALSE** (`drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`). `beta_hat` 0.7416 and `alpha_annualized` 1.1001 are computed but `beta_min_n_met = FALSE`, so **the alpha estimate is not usable** and no edge-decay read may be drawn from it. The 30-trade gate (0/30) and the m2m underperformance trigger (needs ≥756 deployed days) remain structurally inactive for D — a documented, accepted property, not a flaw.

**Regime and router state (informational; does NOT alter disposition).** This is a real change from the 08-01 edition, which was reading a month-old scoring.

- **Fundamental axis, re-scored today (M1a, `as_of 2026-08-01`): "stagflationary shock + hawkish policy."** Three of five axes moved: growth **decelerating** (flip down — June payrolls +57k vs ~110k consensus with Apr/May revised −74k, Q2 GDP advance +1.5% vs Q1 +2.1%, retail ex-autos −0.2%); inflation **stable** (flip from reaccelerating — June CPI −0.4% MoM but Brent +20.5% inside the same month reverses the driver); policy **hawkish** (July 29 FOMC held 3.50–3.75% on a 9–3 vote with three dissents for a hike, the first identical-alternative triple dissent since Sep 2016; futures ~66% odds of a September **hike**; 10Y +24bp, 30Y +30bp on the month); risk **neutral**; shock **acute** (Iran ceasefire collapsed 07-08, Hormuz transits −66/70%, ME sovereign spreads ~402bp, widest since Oct 2022).
- **Technical signals, freshly measured today by M1b** (they had been frozen at a 2026-06-03 snapshot for 61 days — see F-5): **SPY_TREND = UP** (close 747.03 > 50d 744.99 > 200d 700.39), changed from the stale NEUTRAL; **SUSTAINED_INVERSION = NOT-SUSTAINED** (10Y 4.75 ≥ 2Y 4.28); VIX_REGIME NORMAL at 15.99.
- **D router technical rule** — (SPY Trend UP **or** NEUTRAL) **and** inversion NOT-SUSTAINED — therefore reads **ACTIVATE**, now on a freshly-measured UP rather than an inherited stale NEUTRAL. `div-D-202606-1` orchestrator resolved 2026-07-06 to a binding **ACTIVATE, UNCHANGED**, with the new-entry block staying lifted and a discount-rate-sensitivity name-selection/sizing caution attached. M1b's August fundamental call for D is **DO-NOT-ACTIVATE**, and M1b flags that this month it is **raw rather than override-manufactured** (the inflation-reaccelerating + hawkish precondition that produced June's override no longer fires) — material new evidence for the D divergence, which M4 will queue for review.
- **This changes no disposition below.** Per Strategy D's explicit rule, *"router deactivation does not force exits on existing D positions"* — existing positions run to thesis invalidation or completion. Every recommendation in this file is **criterion-driven, not regime-driven.** The regime shift is nonetheless load-bearing *context* for two names in particular: GEV and the AI-capex cluster are the most duration-sensitive, capital-intensive holdings in the book, and a live September-hike probability is exactly the discount-rate risk the router's own caution names.

---

## Cross-cutting findings

These are visible only across the book, not from any single position, and are the substantive output of this cycle.

### F-8 (NEW, and the most important finding this cycle). GEV's entry cleared a criterion the framework had already flagged as unresolved — and the flag said to resolve it *before* committing capital

This finding did not exist on 08-01 because the position did not exist on 08-01.

**The sequence, from the decision record itself:**

1. **`6e9b0031` (2026-08-03, D2) — GEV GO, MEDIUM 50.** Entry criterion 2 ("thesis constructed from the last 8 quarters of earnings call transcripts (minimum), last 2 annual reports…") was called **PASS WITH AN HONEST GAP**: nine standalone post-spinoff quarters exist, clearing the *count* floor, but FMP's `earningsTranscript`/`statements`/`analyst` endpoints were **plan-gated (access denied)**, so no verbatim transcript text was read. The entry records the transcript and annual-report legs as "**THIN** — recorded as a real, not cosmetic, gap." The GO was logged **staged-but-halted** (no order, `state.trading_enabled = FALSE`).
2. **`e2fd2424` (same session) — BA NO-GO, MEDIUM 50.** BA hit the *identical* tooling wall, did a second WebFetch pass recovering only 4 of 8 quarters with any content (2 at quote level, zero for quarters 5–8), and called criterion 2 **NOT MET** — reasoning that "last 8 quarters (minimum)" is a floor, and "an unmet conjunctive minimum is not rounded up merely because the shortfall is a tooling limitation rather than a fact about the company."
3. **`6efeeb13` (same session) — a self-raised `correction`/FLAGGED entry** recording that the two assessments reached **opposite verdicts on the same fact**, and stating plainly: *"BA is the more rigorous reading, and it did more work to reach it."* It declares **"GEV GO IS THEREFORE PROVISIONAL ON THIS POINT,"** notes there was no capital consequence because the gate was FALSE, routes the interpretive question to **W5**, and instructs: **"THE NEXT SESSION THAT FINDS THE GATE TRUE MUST RESOLVE THIS BEFORE CRAFTING THE GEV ENTRY."**
4. **What actually happened.** A later session crafted the order **under an owner-authorized trading-enable exception while `state.trading_enabled` was still FALSE**, and it filled. The position note carries the flag forward verbatim — *"Thesis carries a criterion-2 PROVISIONAL flag"* — so this was **not** concealed or forgotten; it was recorded and proceeded past. But the W5 adjudication has **not** occurred, and the pre-commitment in step 3 was therefore not honoured.
5. **This cycle's own research did not close the gap either — it reproduced it.** The GEV research pass run for this file hit the same wall from the other side: every FMP endpoint returned **rate-limit errors** for the entire session, on top of the pre-existing plan-gating. No verbatim transcript text for any of the last 8 quarters was obtained. The gap is not narrowing on its own.

**Why this is worth a recommendation rather than a note.** The question is not whether GEV's thesis is healthy — it is, conspicuously (see F-9 and the GEV section: both invalidation criteria are further from breach than anything else in the book, and both of the trend figures the thesis names were independently confirmed against primary SEC-hosted releases this cycle). The question is whether the position was **eligible to be opened**. If BA's reading is right — and the framework's own correction entry says BA is the more rigorous reading — then criterion 2 is a hard floor that **no** D candidate can currently clear in this tooling environment, and GEV's entry did not clear it. That is a materially larger claim than one position, which is exactly why `6efeeb13` said it should be "adjudicated deliberately, not settled by whichever assessment happens to run first on a given evening."

**Routing.** GEV's recommendation is therefore **further research**, citing this specific information gap. M4 converts that into a `PENDING_ANALYSIS` research-deferral. Two things M4 should carry:
- **The resolving venue already exists and is named: W5**, with two distinct questions — (i) *interpretive*: is the 8-quarter transcript minimum a hard floor that fails a thesis when unmet, or is a documented substitute evidence base admissible? (ii) *infrastructure*: the FMP plan tier gating `earningsTranscript`/`statements`/`analyst` is an **owner-actionable subscription question**, not something a routine can fix. Set `due_date` to the next W5 run rather than the next trading day.
- **The standard `conservative_default` of "exit the position if unresolved" is defensible here specifically because this is an eligibility question rather than a thesis-health question** — if the criterion was genuinely unmet, the conservative action is not to hold. That said, M4 should note in the queue context that the thesis itself is in the strongest mechanical health in the book, so an unresolved-at-deadline exit would be a *process* exit, not a *thesis* exit, and should be logged as such.

**One more consequence worth stating.** Until W5 adjudicates, **every future D thesis will keep hitting this and resolving it ad hoc** — the correction entry says exactly that. GEV is not the defect; the unadjudicated floor is.

### F-1 (UPDATED — partially closed). The systematic thesis-COMPLETION gap is closed for new entries, and remains permanently open for the eight legacy positions

The 08-01 edition found that **not one** of the then-eight D entry records carried a discrete, testable completion marker, making M3's own *"close on thesis completion"* recommendation unreachable for every position under review.

**GEV closes this for new entries, and does so by explicit reference to the finding.** Its entry record writes completion criteria under the heading *"COMPLETION CRITERIA (written deliberately checkable — M3 2026-08-01 found a SYSTEMATIC gap that no D position carries a usable completion criterion)"*, and specifies: completion when **both** hold in the same or a later quarterly print — **(i) reported backlog ≥ $200B**, **and (ii) trailing-4-quarter total-company organic orders growth has decelerated to ≤ 25% YoY for at least one quarter**. Both legs are checkable against a disclosed figure each print. That is a genuine, mechanical completion test, and it is the first one in the D book.

**This is a real closure of the construction-discipline half of F-1, in one cycle, without any intervention from M4.** It is worth recording that the loop worked: M3 raised a construction-discipline defect, and the next thesis constructed carried the fix.

**What remains open, permanently.** The eight legacy positions cannot be retrofitted — completion and invalidation criteria are **immutable for a position's life**, and adding one now would be precisely the thesis-evasion the immutability rule exists to prevent. So **8 of 9 D positions can still exit only on invalidation**, and RTX remains the live illustration: all five of its Q1'27 falsifiable milestones are already satisfied three quarters early, with no defined mechanism by which that could ever read as completion. The structural bias toward holding winners indefinitely persists for the legacy book and will only wash out as those positions turn over.

The open `PENDING_DRAFT` queue item **`revise-premortem-D-2026-a3`** (strategy D, due 2026-07-31, status `pending`, conservative default "NO-EDIT pending routing resolution" — now flagged stale by D3) together with the 2026-07-30 AR_orc **cycle-5 TIER 1 DEFECT — REVISION REQUIRED** outcome on the Strategy D pre-mortem remains the natural venue for the residual.

### F-9 (was F-2, now materially sharpened). The AI-capex cluster is no longer three names on the compute side — it is four, and GEV joined it from the power side

AMZN, GOOGL and TSM are three expressions of one trade: the AI-capex cycle, with TSM the supplier and AMZN/GOOGL two of the payers. **GEV is a fourth expression of the same macro driver, entered from the opposite end of the value chain** — it monetizes the *power and grid* side of the same AI-datacenter buildout the other three monetize on the *compute* side. GEV's own entry record says this in as many words, and weighed it into sizing rather than into the gate.

**The concentration arithmetic, on cost basis against NAV $2,471.35:**

| | Cost basis | % of D NAV | % of deployed D capital |
|---|---|---|---|
| AMZN + GOOGL + TSM (compute side) | $240.07 | 9.71% | 45.1% |
| GEV (power side) | $120.66 | 4.88% | 22.6% |
| **Combined AI-capex theme** | **$360.73** | **14.60%** | **67.7%** |

**More than two-thirds of all deployed D capital now sits behind one macro driver**, up from 58% last cycle. It remains **completely invisible to the 30%-of-NAV GICS test**, because the four names sit in four different GICS sectors (Consumer Discretionary, Communication Services, Information Technology, Industrials). The mechanical screen will never flag this, by construction.

**And this cycle the concentration stopped being purely thematic.** The 08-01 edition characterised the AI-capex exposure as "a **shared-fundamental-driver** concentration, not (yet) a realised-return-correlation one," noting that the three compute-side names were the book's most correlated pairs (0.33–0.52) yet all sat below the 0.6 bucket threshold. **That characterisation now needs qualifying on one pair.** The full-252-day recompute in F-7 puts **TSM–GEV at 0.587** — the **highest correlation in the book**, displacing AMZN–GOOGL (0.475), and **1.3 percentage points below the bucket-formation threshold**. The supplier of the compute side and the supplier of the power side of the same buildout now co-move at nearly bucket-forming levels, on 252 days of actual returns.

Three things follow, and they should be held together rather than collapsed into either an alarm or a dismissal:
- **Nothing is enforced, and nothing should be.** No bucket forms at 0.6; bucket membership has been monitored-only since Rev 35 in any case; and post-entry monitoring explicitly *does not force exits on already-held positions*. This is not a disposition input.
- **The entry saw the thematic adjacency and priced it, but not this.** GEV's sizing rationale names the AI-capex cluster adjacency as one of three factors sizing the position *down*, and its concentration section states GEV "is not in that bucket by sector but shares the macro driver from the supply side." That judgment was correct and was made on fundamentals. What it did **not** have was the measured 0.587 — the entry's own correlation screen ran against the pre-GEV book.
- **The trajectory is what matters, not the level.** 0.587 today is below threshold. If it crosses 0.6 the pair becomes a two-position correlation bucket for the purposes of subsequent entries; **the material consequence would land on the *next* AI-capex-adjacent candidate, not on TSM or GEV.** Recomputing this pair is now the highest-value line item in next cycle's F-7.

The underlying risk is unchanged in kind and larger in size: a single macro driver behind 67.7% of deployed capital, with **no invalidation criterion in any of the four theses naming free cash flow, capex intensity, ROIC, or cross-position correlation.**

**The cycle strengthened again on every measure the theses actually test** — AWS +37% YoY accelerating a 5th straight quarter with backlog primary-confirmed at $496B; Google Cloud +82% with backlog crossing $500B to $514B; TSM's capex guide raised to $60–64B with CoWoS sold out through 2026; GEV's organic orders +88% with gas equipment + slot reservations growing 100GW → 116GW in a single quarter.

**And the same window continues to produce hard evidence of what the build costs the payers.** Amazon's TTM free cash flow is **−$7.6B** (primary: driven by a $66.1B YoY increase in property-and-equipment purchases) with 2026 capex guidance raised $20B to **~$220B**; Alphabet printed **−$5,855M FCF** — its first-ever negative-FCF quarter, primary-confirmed from the SEC-filed Ex-99.1 — with FY26 capex guidance $195–205B, **$0 of buybacks in the quarter** (against $13,238M in Q2 2025, the first zero-buyback quarter since Q4 2017), and ~$49.6B of equity plus ~$20.3B of senior notes raised to fund infrastructure instead.

**Neither AMZN's five criteria nor GOOGL's five name free cash flow, capex intensity, or ROIC.** GEV's two criteria name only orders growth. The risk is real, it is now correlated across **four** positions rather than three, and no invalidation criterion anywhere in the book would register it. Per the immutability rule this is recorded, not acted on — but it is the single most important thing for future cycles to watch, and the market has already shown it reprices this fast: on the same night AMZN rose 15.3% and MSFT 15.5% on capex read as monetized, **META fell 7.95%** on capex read as dilutive.

**The new regime read sharpens it further.** A hawkish policy axis with ~66% market-implied odds of a September *hike*, a 10Y up 24bp on the month, and an acute external energy shock is the least favourable discount-rate backdrop this cluster has faced since the positions were opened. Nothing here trips a criterion. It is the reason F-9 is stated as the book's principal uncovered risk rather than as background colour.

### F-10 (NEW). GEV's supporting "$200B by 2027" framing is not confirmed by any primary written source — the only primary written target is 2028

GEV's entry cites backlog "$176B on track to the $200B/2027 marker," and its completion criterion (i) is "reported backlog ≥ $200B."

- **Primary written source:** GE Vernova's **2025 Investor Update (2025-12-09)** states the company expects to grow backlog from $135B to **~$200B by year-end 2028**.
- **The "2027" pull-forward appears only in secondary coverage of the Q1'26 and Q2'26 earnings calls.** It could not be found in any primary written release — the Q1'26 press release contains no reference to a $200B milestone or timeline at all. It appears to be a **verbal** update made on an earnings call, which is precisely the primary-transcript access this environment cannot reach.

**This does not affect the criterion.** Completion criterion (i) is date-free — it tests the disclosed backlog figure against $200B whenever that print arrives. What it affects is the *expected timeline* the thesis is implicitly underwriting, and it is a second, independent instance of the same root cause as F-8: **a load-bearing claim that lives only in an earnings call this stack cannot read.** Backlog at $176.3B (Q2'26) is running ahead of the original 2028 pace either way, so the direction of the error is favourable — but "2027" should be carried as **secondary/unverified**, not as a company commitment.

### F-3 (UPDATED — three of four dated events resolved). What actually landed

| Date | Event | Criterion | **Resolution as of 2026-08-03** |
|---|---|---|---|
| **2026-08-03** | J&J investor call on Ottava (FDA De Novo 2026-07-22) | ISRG criterion 4 | **RESOLVED — criterion NOT BREACHED.** J&J's language, identical across its 07-22 release, jnjmedtech.com and all coverage located, is that Ottava will "commercially launch with **select customers** in the U.S." **No hospital, IDN or health system was named, anywhere, in any source.** No pricing and no installed-base figures were disclosed. *Caveat stated rather than glossed:* the substantive readout of the 8:00am ET call itself was **not yet indexed** at research time, so this verdict rests on J&J's own pre-call and launch-framing language plus all coverage available. **Carried to D1/W3 for a re-check once call coverage indexes** — this is a monitoring item, not a deferral. |
| **2026-08-05** | DIS Q3 FY26 earnings, **CONFIRMED**, 8:30am ET before market | DIS criteria 1, 2, 3 | **NOT YET REPORTED** — two days out. Date re-confirmed against Disney IR. |
| **2026-08-05** | FCC reply-comment deadline, ABC licence proceeding | DIS criterion 5 | **NOT YET REACHED.** **No FCC order of any kind has been issued**, and **no Disney 8-K** characterising the proceeding as a material adverse EPS impact exists. Criterion 5 requires **both**; neither prong is met. |
| **2026-08-05** | UBER Q2 2026 earnings, **CONFIRMED**, 8:00am ET before market | UBER criteria 1–3 | **NOT YET REPORTED** — two days out. Date re-confirmed against Uber IR. |

The two 08-05 prints are now **two days out rather than four**, and both are the first genuinely new quarter for their respective theses. They are the highest-value near-term events in the book and are carried to M4/M5 as monitoring items.

### F-4 (CLOSED). Both ledger defects are corrected — and one new provisional-basis item replaces them

**Both defects the 08-01 edition raised have been fixed**, by an append-only correction (`bigquery/121`, run_id `1635f901-13d8-4291-9ee6-cf43eba4f612`), verified this cycle directly against `events.position_events`:

- **`D:RTX:2026-04-27`** — the erroneous `time_exit_date = 2027-04-27` has been **moved to `ltcg_date`**, and `time_exit_date` is now **NULL**. The correction note cites the entry record's specification of no maximum hold. **The risk of an unfounded forced exit in April 2027 is eliminated.** This was flagged as the highest-priority hygiene item in the file and it is closed.
- **`D:DIS:2026-05-07`** — `ltcg_date` is now **2027-05-08**, matching the entry record. Closed.

Both corrections were made append-only with all non-date fields echoed forward unchanged — the correct mechanism. **No further action; do not re-raise.**

**One new, much smaller ledger item replaces them.** `D:GEV:2026-08-03` is still the **PROVISIONAL staging-time OPEN row**: `cost_basis = 123.92` (a staging estimate of 0.1244 × $996.175). **The order has filled** — the IBKR connector shows 0.1244 sh at an average price of **$969.9059**, i.e. a real basis near **$120.66** before commission, roughly **$2.9 lower** than the provisional figure, because the fill came in below the staging reference. `ltcg_date` is provisionally 2027-08-04. **This is ordinary and expected**: D2a Step 0 supersedes the provisional row on fill reconciliation, per the STAGING-OPEN KEY INVARIANT. M3 is research-only and has written nothing. It is recorded so that (a) this file's use of the *actual* $120.66 basis rather than the ledger's $123.92 is traceable, and (b) if D2a has not reconciled by the next cycle, that becomes a real defect rather than a timing artifact.

### F-5 (UPDATED). Source-reliability findings — one prior finding independently re-confirmed, three new ones

- **The tikr.com claim is REFUTED again, independently.** A secondary blog (tikr.com, 2026-07-27) asserts Intuitive **raised** FY2026 procedure guidance to 14–16%. A fresh, independent research pass this cycle confirms guidance was **reaffirmed at 13.5–15.5%** with management guiding toward the **midpoint** — corroborated across the company release, the Q2 earnings-call transcript and multiple independent summaries. No source supports 14–16%. What *was* raised at Q2 is non-GAAP **gross margin** guidance, to 68–69%. Treat all tikr.com figures in this name as unverified.
- **NEW — a sub-agent research error, corrected here rather than propagated.** One research pass this cycle flagged a "possible naming mismatch" in TSM invalidation criterion 2, suggesting that "A16" might not be a TSMC node and that the node after N2 is "A14." **That flag is wrong and is not adopted.** A16 (1.6nm-class, with Super Power Rail backside power delivery) is a disclosed TSMC node targeted for H2 2026; A14 is the *subsequent* node targeted for 2028. Both exist; the criterion's wording is correct as written. Recorded because a downstream cycle reading the raw research would otherwise inherit a false ambiguity about a live invalidation criterion.
- **NEW — connector-vs-aggregator price divergence.** Secondary aggregator quote pages disagreed with the IBKR connector on 08-03 marks, in one case badly (ISRG: aggregator day-range $340.61–$355.00 vs connector $371.76), and disagreed with *each other* on 07-31 closes for GOOGL across four sources spanning $354.20–$360.21. The connector figures are used throughout and are internally consistent with the connector's own `daily_pnl`. Aggregator quote pages should not be treated as interchangeable with the connector for mark-to-market.
- **NEW — two 07-31 closes carried in the 08-01 edition are corrected.** A three-way reconciliation this cycle (IBKR connector snapshot + BigQuery `state.daily_marks_curated` + an independent external provider, all agreeing) establishes the 2026-07-31 closes as **GOOGL $356.13** and **CRM $184.02**. The 08-01 edition carried **$354.20** and **$183.38** respectively. The differences are small and change no criterion, no envelope rail and no recommendation, but the corrected figures are the ones used in this file's percentage-change arithmetic. The other seven names' 07-31 closes reconciled exactly.
- **NEW — the IBKR `get_price_history` series-swap defect is REPRODUCED and its scope is worse than "batching."** M2 (2026-08-03) escalated this as a standing infrastructure defect and re-diagnosed it as contract-level rather than batch-induced. This cycle's measurement pass independently confirmed it and quantified it: a single batched call across the nine D contract_ids returned **7 of 9 series mislabelled**, in a *clean permutation* — a TSM↔RTX↔GEV three-cycle plus UBER↔DIS and ISRG↔CRM swaps — with only AMZN and GOOGL correctly attached to their own contract_id. The failure is silent and the data is well-formed, so nothing about the response signals the error. **Mitigation applied here, and it should be the standard:** every ticker was individually re-fetched and cross-verified against at least two independent endpoints before any figure was used. Sequential fetching alone is *not* sufficient. This corroborates M2's escalation to W5/D3 with a second, independent reproduction and a precise permutation signature.
- **NEW — the technical-signal plane was stale for 61 days and has just been repaired.** `events.regime_events` scope `TECHNICAL_SIGNAL` had not been written since 2026-06-03; every reading of SPY Trend in the interim — **including the 08-01 edition of this file, which reported "SPY Trend NEUTRAL"** — came from that frozen snapshot, itself sourced from the retired `Regime_State.md`. M1b re-measured all four keys today and SPY Trend moved **NEUTRAL → UP**. VIX_REGIME was written for the first time ever. This did not change D's router state (both UP and NEUTRAL satisfy the rule) but it did mean the prior edition's router paragraph rested on a 61-day-old input, which is worth knowing when comparing the two editions.

### F-6 (UPDATED). Why exactly one position is routed to "further research" this cycle, and eight are not

M4 converts an M3 "further research" recommendation into a `PENDING_ANALYSIS` research-deferral whose **`conservative_default` is to exit the position if unresolved.** That default is appropriate for a genuine, decision-blocking gap and disproportionate otherwise. Applying that test honestly:

- **GEV → further research.** The gap is named, specific, adjudicable, has an identified venue (W5), and — decisively — the framework's *own* correction entry pre-committed to resolving it before capital was committed, and capital has now been committed. An eligibility question is exactly the kind where "exit if unresolved" is the proportionate conservative default. See F-8.
- **The other eight → no deferral.** Every open item on them is either (a) a dated event arriving on a known date within days (F-3), or (b) a criterion-design issue that an exit would not resolve (F-1). Attaching an exit-if-unresolved default to a thesis whose every criterion is currently clear, over a gap an exit cannot close, would be disproportionate to the evidence. They are carried forward as **monitoring items for M4/M5**, explicitly not as deferrals.

Note the contrast with the 08-01 edition, which routed **nothing** to further research and reasoned that no gap that cycle warranted an exit default. That reasoning was right on the facts then available and is unchanged for the eight names it covered; the ninth position did not exist.

### F-7 (UPDATED). Correlation-bucket recompute — now 9×9

Strategy D Entry criterion 5 requires the daily-return correlation matrix to be **recomputed monthly**. Since Rev 35 (owner directive) bucket membership is **monitored-only/informational** — neither capped nor entry-blocking — so this is reported, not enforced.

**This cycle's recompute reached the full specified window — a real methodological improvement on the prior edition.** Pairwise Pearson correlations of simple daily returns across all **nine** held names, computed over **252 daily returns across 253 common trading dates, 2025-07-30 → 2026-07-31**. The 08-01 edition managed only 208 returns and recorded the shortfall as a deviation; **that shortfall is closed — this is the full trailing-252-day window Entry criterion 5 specifies.** GE Vernova, despite its April-2024 spin-off, has complete daily history across the entire window: 252/252 returns, no gaps, no availability shortfall.

|        | AMZN | GOOGL | TSM | UBER | ISRG | CRM | DIS | RTX | GEV |
|---|---|---|---|---|---|---|---|---|---|
| **AMZN** | 1.000 | 0.475 | 0.296 | 0.253 | 0.206 | 0.162 | 0.195 | 0.050 | 0.207 |
| **GOOGL** | 0.475 | 1.000 | 0.339 | 0.257 | 0.217 | 0.081 | 0.203 | 0.081 | 0.200 |
| **TSM** | 0.296 | 0.339 | 1.000 | 0.231 | 0.137 | −0.131 | 0.101 | 0.065 | **0.587** |
| **UBER** | 0.253 | 0.257 | 0.231 | 1.000 | 0.210 | 0.213 | 0.262 | 0.091 | 0.020 |
| **ISRG** | 0.206 | 0.217 | 0.137 | 0.210 | 1.000 | 0.214 | 0.312 | 0.188 | 0.087 |
| **CRM** | 0.162 | 0.081 | −0.131 | 0.213 | 0.214 | 1.000 | 0.197 | −0.093 | −0.214 |
| **DIS** | 0.195 | 0.203 | 0.101 | 0.262 | 0.312 | 0.197 | 1.000 | 0.129 | −0.046 |
| **RTX** | 0.050 | 0.081 | 0.065 | 0.091 | 0.188 | −0.093 | 0.129 | 1.000 | 0.183 |
| **GEV** | 0.207 | 0.200 | **0.587** | 0.020 | 0.087 | −0.214 | −0.046 | 0.183 | 1.000 |

**Pairs > 0.6: NONE. Pairs > 0.7: NONE.** No correlation bucket forms at the 0.6 entry threshold, and no post-entry-emergent 0.7 pair exists.

**Top five pairs: TSM–GEV 0.587 · AMZN–GOOGL 0.475 · GOOGL–TSM 0.339 · ISRG–DIS 0.312 · AMZN–TSM 0.296.**

**Verification.** Values were computed from adjusted closes and **independently re-verified** by recomputing the top five pairs from raw unadjusted closes over the identical aligned date set — all five agree to within 0.002, so there is no dividend-adjustment sensitivity. Separately, the underlying price series was validated at the source: every ticker's 2026-07-31 close in the correlation pull matches both the IBKR connector snapshot and BigQuery ground truth exactly, which is the stronger provenance check (see F-5 on the price-history defect that made this necessary).

**The headline number is TSM–GEV at 0.587, and it is the most important line in this section.** It is the **highest correlation in the entire book**, it displaces AMZN–GOOGL (0.475) which led the prior cycle, and it sits **1.3 percentage points below the 0.6 bucket-formation threshold**. On today's data no bucket forms and nothing is enforced — but this is the first time the AI-capex concentration has shown up as a *realised-return* correlation rather than only as a shared fundamental driver, and it did so immediately on the new position's entry. See F-9, which this substantially rewrites.

*Note the two-sided character of the book's diversification, which the matrix makes visible: GEV is simultaneously the most correlated name with TSM (+0.587) and among the most **negatively** correlated with CRM (−0.214) and DIS (−0.046). The book's median pairwise correlation remains near 0.20.*

### F-11 (NEW, verified two ways). `analytics.strategy_nav` is silently dropping the GEV position — and the cause is a recurring staging-time defect, not a one-off

The measurement pass for this file found that `analytics.strategy_nav` reports `deployed_mv = $426.80` and `unrealized_pnl = $14.63` for D. **Recomputing the book from `state.current_positions` *excluding GEV* reproduces both figures to the cent** ($426.8007 and $14.6331). The view is not stale — **it is filtering the position out.**

**Two independent causes, both directly visible in the data:**

1. **Case-sensitive status literal.** `state.current_positions.status` for `D:GEV:2026-08-03` is the lowercase string **`open`**, while every reconciled row carries uppercase **`OPEN`**. BigQuery string equality is case-sensitive, so the `WHERE status = 'OPEN'` filter used by the view's `open_pos` CTE excludes it.
2. **No curated mark.** `state.daily_marks_curated` has **zero rows for GEV**, so the view's `latest_close` CTE has nothing to join to — which would exclude the position a second, independent way even if the status literal matched.

**This is not new, and that is the finding.** The `B:MSCI:2026-07-27` reconciliation note records D2a having corrected *exactly this* — *"corrects that row's status literal (lowercase `open` → uppercase `OPEN`), which the `status='OPEN'` views (`analytics.strategy_nav`, `state.daily_briefing`, `weekly_report`) filter on."* So the staging-time provisional-OPEN writer emits lowercase, and the defect is repaired only when D2a Step 0 reconciles on fill. **`B:MTZ:2026-08-03` carries the same lowercase `open` right now**, so this is a cross-strategy pattern, not a D quirk: *every* position spends the window between staging and D2a reconciliation invisible to the NAV view and to the daily briefing.

**Why it matters, concretely.** GEV's own entry record notes it was *"sized off a stale `analytics.strategy_nav`."* This is the mechanism behind that complaint, and the consequence is circular: a position sized against a NAV view is invisible to that same view until reconciled, so **any subsequent sizing decision taken in the same window understates deployed capital** — here by $123.68, roughly 22% of true deployed notional. On a small book that is material to a 75%-of-NAV rail computation.

**Not actioned here.** M3 is research-only and has written nothing. The immediate instance self-heals when D2a Step 0 reconciles the GEV fill (F-4). The *recurring* defect — a staging-time writer emitting a status literal that the consuming views filter on — is a data-hygiene item for **W5/D3**, and the durable fix belongs at the writer or in the views' predicate, not in repeated post-hoc corrections. The percentages in this file are unaffected: they are computed from `state.current_positions` directly, not from the view.

---

# Per-position deep-dives

## Position — GEV (GE Vernova) — Subtype B (trend-continuation) — **NEW THIS CYCLE**

**Tranche (1).** `D:GEV:2026-08-03`, 0.1244 sh. Ledger carries the **provisional** staging basis $123.92; **actual fill 0.1244 sh at an average $969.9059 → real basis ≈ $120.66** before commission (D2a Step 0 will supersede — see F-4). Mark $994.24 (08-03 connector) = **$123.68 MV, +$3.03 unrealized (+2.5%)**. CaR **4.88% of D NAV — the book's largest single-name exposure**, inside the 10% envelope with margin. LTCG provisionally 2027-08-04.
**Span covered:** entry (2026-08-03) → 2026-08-03. **First M3 deep-dive; the position is hours old.**

### 1. Current thesis status — INTACT; too new to have been tested by events

The original thesis (`6e9b0031`, D2 2026-08-03, GO at MEDIUM 50, draining the overdue `rescreen-GEV-D-20260731` item): the global buildout of electric grid infrastructure and gas/nuclear generation — driven by AI-datacenter load growth, industrial reshoring/electrification and grid modernization capex — is a multi-year secular demand cycle in which GEV holds a top-2 global position in heavy-duty gas turbines. **Subtype B confirmed, not A**: the $200B backlog marker is a management-articulated trajectory marker for a continuing trend, not a discrete pass/fail event, and no future-dated catalyst with a publicly-known resolution date exists at all — so the dual-signal typing rule never engages.

The entry resolved a criterion-6 momentum deferral **decisively rather than marginally**: last close before entry $990.29 against a 52-week high of $1,195.49 (intraday ~$1,195.94 on 2026-07-06), a trailing-30-day return of **−13.62%** and a drawdown from the high of **−17.16%**. Both legs of the rally-pause recheck fired independently. This is a genuine correction, not a technicality.

**Thesis status is INTACT** — but the honest characterisation is that the position has existed for one session, and nothing has had the opportunity to test it. What *has* happened this cycle is that the thesis's two load-bearing numbers were **independently verified against primary sources** (below), which is a stronger statement than "nothing broke."

### 2. Multi-year driver check

| Driver | Verdict | Evidence |
|---|---|---|
| **Total-company organic orders growth (the named trend metric)** | **PROGRESSING, accelerating** | +8% → +4% → +55% → +65% → **+71% → +88%** across Q1'25→Q2'26 |
| Gas Power equipment + slot reservation agreements | PROGRESSING, and the target was raised | 100GW → **116GW** in Q2 alone; year-end-2026 target raised from 110GW to **≥125GW** across two consecutive primary releases; SRAs 56GW → 63GW sequentially |
| Electrification / grid equipment | PROGRESSING strongly | Q2 revenue $3,637M (+68% reported, +29% organic); EBITDA margin 18.4% (**+700bps organic**); equipment backlog $40.6B **+69% YoY**; data-center orders $2.7B in Q2, >$5B in H1 — more than double all of FY2025 |
| Backlog toward the $200B completion leg | PROGRESSING | $116B (spin) → $150.2B (FY25) → $163B (Q1'26) → **$176.3B (Q2'26)**, +$13.0B sequential |
| Nuclear / SMR (BWRX-300) | PROGRESSING | Darlington (OPG) 4 units — provincial and OPG approval obtained, first-unit construction underway, shaft excavation complete, RPV manufacturing in progress; two further US tech-selects/early-work agreements in Q2 |
| **Wind** | **DETERIORATING — and explicitly designated not-exit-triggering at entry** | Q2 revenue −11% organic; orders **−40% organic**; EBITDA loss widened to **$(275)M** (−13.6% margin, down 630bps); FY26 segment loss guided ~$(0.4)B; ~900 job cuts in offshore incl. ~360 (~60%) at two French sites |
| Tariffs | IMPROVING | FY26 net impact guided $250–350M at Q1, **revised down to $100–200M** at Q2 (secondary — see below) |

**Every driver except Wind is progressing, and Wind's deterioration was named at entry as explicitly not exit-triggering on its own.** That is not the thesis excusing bad news after the fact — it is written into the immutable criteria set, before the fact.

### 3. Fundamental developments (entry → 2026-08-03)

**Q2 2026, reported 2026-07-22 (PRIMARY — SEC 8-K, accession 000199681026000147, press release fetched directly from the SEC-hosted exhibit):** revenue **$11,104M** (+22% reported, +12% organic); net income $649M; adjusted EBITDA $1,250M (11.3% margin, +340bps organic); **orders $24.2B, +88% organic**; backlog **$176.3B**; operating cash flow $5.5B; **free cash flow $5.1B — more than all of FY2025**; cash $13.1B. Segments: Power revenue $5,477M (+14%), orders **$16,729M, +134% organic**, EBITDA margin 18.8%; Electrification revenue $3,637M, EBITDA margin 18.4%; Wind revenue $2,026M, orders −40% organic, EBITDA $(275)M.

**FY2026 guidance RAISED at the same print (PRIMARY):** revenue $45.5–46.5B (from $44.5–45.5B); **free cash flow $11.5–12.5B (from $6.5–7.5B — a near-doubling)**; adjusted EBITDA margin 12–14% unchanged; Power organic revenue growth raised to 18–20%; Electrification revenue raised to $14.5–15.0B.

**Other events since 2026-06-01:** Jefferies PT $1,350 → $1,210, Buy maintained (06-11); former Power CEO Zingoni's advisory transition ended 06-30, Eric Gray now holds the consolidated Power segment CEO role; Robotech Automation acquisition closed July (value not disclosed); 52-week intraday high ~$1,195.94 (07-06); Barclays downgraded **Siemens Energy** to Underweight on a peak-cycle gas-turbine thesis and GEV fell ~7% on read-across despite not being the subject (07-07); $0.50/share dividend paid (07-14); Niskayuna Advanced Research Center expansion opened (~$100M, 07-16); China XD Electric divestiture ~$0.6B pre-tax proceeds referenced in the Q2 release. **Post-print sell-side skewed to PT raises**: Morgan Stanley $1,250 → $1,350 (07-23), TD Cowen $1,220 → $1,235 (07-23), Mizuho $913 → $949 (07-24); **no fresh post-print downgrade was found.**

**Strictly 08-01 → 08-03: NO EVENTS FOUND.** No company-specific news item dated in the window was located.

**The bear case, recorded at entry and not softened here.** A same-print, same-session **Strategy B MEDIUM-HIGH NO-GO** concluded this exact quarter was information-driven bad news, on the reasoning that Utilities rose +2.25% that day — best-performing sector, on the identical data-center-demand theme — while GEV fell −8.69%. Q2 EPS reportedly missed badly ($2.47 vs ~$3.17 consensus; **SECONDARY, not reconciled to a primary GAAP EPS table**). The 2015–2020 gas-turbine downturn that nearly killed GE Power is the direct institutional memory for the overbuild risk. Segment-CEO turnover during a capacity-scaling-sensitive period. Mitsubishi Power and Siemens Energy are full-scale rivals with their own capacity expansion, and the ~25–30% share figure is a snapshot, not a moat — competitive share figures across sources are mutually inconsistent (GEV cited anywhere in 18.5–30%, Mitsubishi ~35% in one dataset) and **could not be reconciled to a single authoritative number**.

**Vineyard Wind litigation — an open, unquantified tail risk (SECONDARY throughout).** GE Renewables sought to exit its turbine/service contract at the 800MW Vineyard Wind 1 project after a Haliade-X blade failure (fibreglass fragments ashore on Nantucket, July 2024; a $10.5M settlement to local businesses was paid). Vineyard Wind sued for **$853M** to block the exit; GE Renewables countersued claiming ~$300M owed to it while Vineyard Wind claims GE owes ~$500M. A Massachusetts judge issued and, in **July 2026**, reaffirmed a preliminary injunction compelling GE Renewables to keep servicing the project, rejecting GE's bid to compel arbitration. **No ultimate liability is knowable.** This is not covered by either invalidation criterion.

### 4. Invalidation criteria check — 2/2 NOT BREACHED, by the widest margin in the book

| # | Criterion (immutable, verbatim substance) | Verdict | Measured |
|---|---|---|---|
| 1 | Total-company organic orders growth YoY falls **below +15% for 2 consecutive quarters** | **NOT BREACHED — nowhere near** | Trailing readings **+65% / +71% / +88%**, accelerating. The threshold was deliberately set far below the entry reading so normal moderation off an extreme base is not mistaken for invalidation |
| 2 | **Metric-immutability** — auto-invalidate if GEV stops disclosing total-company organic orders growth in comparable form for 2 consecutive quarters | **NOT BREACHED** | Disclosed in comparable form in every quarterly release fetched, Q1'25 through Q2'26; 0 of the required 2 non-conforming quarters have accrued |

**The two figures the thesis names were independently verified this cycle and both CHECK OUT.** The Q1'26 +71% and Q2'26 +88% readings were confirmed by directly fetching the SEC-hosted press releases (`gevpressrelease1q26.htm`, `gevpressrelease2q26.htm`) rather than by accepting the entry record's own numbers. The full series — +8%, +4%, +55%, +65%, +71%, +88% — is primary or primary-adjacent throughout.

Explicitly designated **NOT exit-triggering on their own** at entry, and therefore not treated as such here: further Wind deterioration, additional tariff-guidance revisions, short-term price action. All three occurred or persisted this window; none is an invalidation event.

### 5. Sector and theme context

US electricity consumption is inflecting after two decades of flatness — ~1.7%/yr growth 2020–2025 against ~0.1%/yr 2005–2019 — and US utility capex ran ~$215B in 2025 (+24% YoY) with forecasts toward ~$1.3T cumulative 2026–2030 (SECONDARY). Data-center power demand estimates **vary widely across sources and are not reconciled** (~31GW in 2025 rising to 41GW or as high as 75.8GW in 2026, depending on methodology); the direction is unambiguous, the magnitude is not, and this file does not adopt a single figure. Siemens Energy carries a record ~€154B backlog "booked out until FY2028," which corroborates the cycle's breadth while also being the basis for Barclays' peak-cycle downgrade of that name.

**One measured fact the entry could not have had.** GEV's entry ran its correlation screen against the pre-GEV book and concluded, correctly on fundamentals, that GEV "is not in that bucket by sector but shares the macro driver from the supply side." This cycle's post-entry recompute puts **TSM–GEV at 0.587 over a full 252-day window — the highest pair in the book**, and 1.3pp below the 0.6 bucket threshold. No bucket forms, nothing is enforced, and post-entry monitoring explicitly does not force exits. But it means the thematic adjacency the entry priced qualitatively is now also measurable in realised returns, and the pair is the one to watch. See F-7 and F-9.

**The regime read is a genuine headwind for this specific position.** GEV is the most capital-intensive, longest-duration name in the D book, entered into a **hawkish policy axis with ~66% market-implied odds of a September hike** and a 10Y that rose 24bp on the month. `div-D-202606-1`'s binding ACTIVATE carries an explicit *discount-rate-sensitivity name-selection and sizing caution*, and the entry's own sizing rationale cites that caution as one of three factors sizing the position **down**. Nothing here trips a criterion. It is the reason the position is MEDIUM conviction rather than HIGH.

### 6. Long-term tax treatment

LTCG qualification provisionally **2027-08-04** — approximately **12 months out**, the longest runway in the book. No completion signal is remotely near (see below), so there is no LTCG-timing coordination question. Per Rev 39 there is in any case no preference to delay a criterion-triggered exit for LTCG qualification.

**Completion status — worth stating because GEV is the only position where it can be stated.** Completion requires **both** (i) backlog ≥ $200B **and** (ii) trailing-4-quarter organic orders growth decelerated to ≤25% YoY for at least one quarter. **Neither leg is close.** Backlog is $176.3B, ~88% of the way to the first leg; orders are running 55% → 65% → 71% → 88%, i.e. accelerating — the *opposite* of the deceleration the second leg requires. **The position is early in its structural arc by both of its own tests**, which is exactly what a fresh Subtype-B entry should look like.

### Recommendation — **FURTHER RESEARCH**

**Not on thesis health.** Both invalidation criteria are NOT BREACHED by the widest margin of any position in this file, the named trend metric is accelerating, both of the thesis's load-bearing figures were independently primary-verified this cycle, and the position is the only one in the book carrying a checkable completion criterion.

**The specific information gap** (Entry criterion 2, per F-8): *is Strategy D Entry criterion 2's "last 8 quarters of earnings call transcripts (minimum)" a hard floor that fails a thesis when unmet, or is a documented substitute evidence base admissible?* GEV's GO was recorded by its own author as **PROVISIONAL on this point**; a same-session sibling thesis (BA) reached the **opposite** verdict on the identical tooling limitation and was refused; the framework's own correction entry judged BA's the more rigorous reading and instructed that the question be resolved **before** the GEV entry was crafted. It was not — the order was crafted under an owner-authorized trading-enable exception with the flag still open, and filled. This cycle's research pass **reproduced the gap rather than closing it** (all FMP endpoints rate-limited on top of being plan-gated; no verbatim transcript obtained for any quarter).

**Resolving venue and timing:** W5, which already holds both the interpretive and the infrastructure question. `due_date` should be the next W5 run, not the next trading day.

---

## Position — AMZN (Amazon.com) — Subtype B (trend-continuation)

**Tranches (2).** `D:AMZN:2026-07-09` 0.1554 sh, basis $37.4893, LTCG 2027-07-09 · `D:AMZN:2026-07-30` (add) 0.1910 sh, basis $50.7474, LTCG 2027-07-31, filled 2026-07-31 @ $263.859. **Aggregate 0.3464 sh / $88.2367 basis; mark $285.82 = $99.01 MV, +$10.77 (+12.2%).** CaR 3.57% of D NAV.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental). Prior full review 2026-07-09 → 2026-08-01.

**1. Thesis status — INTACT, strengthening.** AWS is re-accelerating after years of deceleration, on AI/cloud demand; the trend metric is AWS revenue growth with an operating-margin floor and a non-declining backlog, supported by Trainium adoption and the Anthropic/OpenAI compute commitments. Unchanged and confirmed.

**2. Driver check.** AWS revenue re-acceleration **PROGRESSING** — 17.0 → 17.5 → 20.0 → 24.0 → 28.0 → **37.0%** YoY, a fifth consecutive accelerating quarter and the fastest in 18 quarters, on **$42.2B** of Q2 segment revenue. AWS operating margin **PROGRESSING** — 39.5 → 32.9 → 34.6 → 35.0 → 37.7 → **39.4%** ($16.6B operating income vs $10.2B a year earlier), a series high. Backlog **PROGRESSING** — $244B → $364B → **$496B**, weighted-average remaining life **6.4 years**. Trainium **PROGRESSING** — chips run-rate >$25B, triple-digit YoY. Anthropic/OpenAI commitments **PROGRESSING** — "multi-year, multi-gigawatt commitments." Capex→monetization **MIXED**: demand progressing, near-term cash worsening (see F-9).

**3. Fundamental developments in the incremental window: NONE.** No SEC filing, no material corporate news, no new company-specific analyst trigger dated 08-01 through 08-03. The cluster of price-target raises circulating on 08-02 (Wedbush → $310, Benchmark → $400, Rosenblatt, plus JPMorgan $365 / Truist $350 / RBC $330 / Barclays $365 / Goldman $375 / KeyCorp $350) are **republications of actions dated 2026-07-31**, the post-earnings session — pre-window, not new.

**What the window did produce is a primary-source upgrade on a load-bearing figure.** The 08-01 edition reported the $496B backlog as 10-Q-confirmed; this cycle pinned the filing precisely — **Q2 2026 10-Q filed 2026-07-30, accession 0001018724-26-000026**, main document `amzn-20260630.htm`, with the revenue note reading verbatim: *"For contracts with original terms that exceed one year, those commitments not yet recognized were approximately $496 billion as of June 30, 2026. The weighted-average remaining life of our long-term contracts is 6.4 years."* Criterion 3's Q2 data point is now unambiguously primary. (Note: some secondary sources date this filing 07-31; the EDGAR filing index reads 07-30 and is treated as authoritative.)

**4. Invalidation criteria — 5/5 NOT BREACHED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | AWS YoY <18% for 2 consecutive Q | NOT BREACHED | 17.0, 17.5, 20.0, 24.0, 28.0, **37.0%** — the only sub-18% pair is Q1–Q2 2025, over a year old |
| 2 | AWS op-margin <~30% for 2 consecutive Q | NOT BREACHED | never below 30% in six quarters; **39.4%** series high |
| 3 | AWS backlog declines sequentially 2 consecutive Q | NOT BREACHED — **grew ~36% sequentially** | $244B → $364B → **$496B**, primary-confirmed in the filed 10-Q |
| 4 | Anthropic/OpenAI commits renegotiated down or churned | NOT BREACHED | language unchanged or strengthened |
| 5 | Metric-immutability if AWS segment reporting restructures ≥2Q | NOT BREACHED | unchanged three-segment structure across all six quarters |

**5. Sector/theme.** See F-9. The nuance no criterion tests: AWS's +37% was the *slowest* of the big three this quarter (Azure +43%, Google Cloud +82%) — re-accelerating off a much larger base while ceding relative share.

**6. Tax.** LTCG 2027-07-09 and 2027-07-31, both ~11–12 months out. No completion marker exists (F-1); no LTCG-timing coordination available.

**Recommendation — HOLD.** No criterion met; all five NOT BREACHED on a primary-confirmed six-quarter series, with criterion 3's Q2 point now traceable to the filed 10-Q rather than a secondary report.

---

## Position — GOOGL (Alphabet) — Subtype B with a regulatory overlay

**Tranches (2).** `D:GOOGL:2026-07-09` 0.1043 sh, basis $37.5322, LTCG 2027-07-09 · `D:GOOGL:2026-07-26` (add) 0.1534 sh, basis $50.2912, LTCG 2027-07-27, filled 2026-07-27 @ $325.56. **Aggregate 0.2577 sh / $87.8234 basis; mark $368.50 = $94.96 MV, +$7.14 (+8.1%).** CaR 3.55%.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT, strengthening on the growth leg; regulatory overlay unchanged.** Google Cloud is becoming a durable second engine alongside Search; Gemini/AI Overviews defend rather than cannibalize Search; the regulatory overlay treats the current *behavioral-only* remedy state as load-bearing — a structural remedy anywhere would be the problem.

**2. Driver check.** Cloud as a second engine **PROGRESSING, accelerating on all three metrics for two consecutive prints** — revenue $20.03B (+63%) → **$24,768M (+82%)**; operating margin 32.9% → **35.6%** ($8,814M operating income); backlog $462B → **$514B**, the first $500B cross, with the company stating it expects to recognize just over 50% of total backlog as revenue within 24 months. Search defence **PROGRESSING with an execution-risk yellow flag** — Search revenue +17% to $63.27B, AI Mode >1B MAU, Gemini app 950M MAU, against the Gemini 3.5 Pro GA slip and four senior DeepMind departures in late June. Regulatory posture — a risk overlay, not a growth driver; see criterion 4.

**3. Fundamental developments in the incremental window: NONE.** No SEC filing, no material corporate news, no new rating change dated 08-01 through 08-03. The late-July PT cuts (Phillip $425, Cantor $420, JPMorgan $420) are dated ~07-27/28, pre-window.

**4. Invalidation criteria — 5/5 NOT BREACHED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | Cloud revenue YoY <20% for 2 consecutive Q | NOT BREACHED | +63%, **+82%** — accelerating |
| 2 | Cloud op-margin contracts 2 consecutive Q | NOT BREACHED | 32.9% (vs 17.8% YoY), **35.6%** (vs 20.7% YoY) — expansion both YoY and sequentially |
| 3 | Cloud RPO/backlog declines sequentially 2 consecutive Q | NOT BREACHED | $462B → **$514B**, +~$52B sequentially |
| 4 | **Adverse structural remedy** | **NOT BREACHED — re-verified as of 2026-08-03** | see below |
| 5 | Metric-immutability if Cloud revenue stops being reported comparably ≥2Q | NOT BREACHED | consistent segment disclosure both quarters |

**Criterion 4 — re-verified this cycle across all four live proceedings, and the answer to the only question that matters is a clean no.**

- **US search monopoly (Judge Mehta, D.D.C.)** — remedies order **issued and finalized**, and it **explicitly rejected** structural relief: no Chrome or Android divestiture, behavioral remedies only. On appeal at the D.C. Circuit; DOJ's 2026-07-28 appellate brief seeks to strengthen data-sharing remedies and reverse the denied payment ban — **it does not seek a breakup on appeal either.** This case is resolved *without* structural remedy.
- **US ad-tech (Judge Brinkema, E.D. Va.)** — liability found 2025-04-17; remedies trial closed with argument 2025-11-21; Brinkema's self-imposed 2026-03-31 deadline **passed without a ruling**. A law-firm client update dated **July 2026** still describes the remedies decision as "awaited." **No source confirms a ruling as of 2026-08-03.** Still pending.
- **EU AT.40670 (ad-tech)** — €2.95B infringement decision 2025-09-05; provisional non-confidential text published January 2026. The Commission's **preliminary** view is that a structural remedy may be needed; Google's submitted proposal is **behavioral only**. **No final decision ordering divestiture has been issued.** Still under evaluation.
- **EU DMA** — first-ever DMA non-compliance fines against Google issued 2026-07-23: **€890M** total (€460M Search self-preferencing, €430M Play steering), 60-day compliance clock to ~2026-09-21, periodic penalties threatened up to 5% of average daily worldwide turnover. **No divestiture component.**

**Direct answer: no court or regulator anywhere has ordered a divestiture or breakup of any Google business as of 2026-08-03.** The one venue where a US remedies order is final rejected structural relief; the two venues where divestiture remains on the table are both undecided. Criterion 4 is NOT BREACHED on verification, not on silence.

**5. Sector/theme.** See F-9. Alphabet is the sharpest single expression of the capex-cost problem: −$5,855M FCF, $0 buybacks against $13,238M a year earlier, and ~$70B raised across equity and notes in the quarter to fund infrastructure.

**6. Tax.** LTCG 2027-07-09 and 2027-07-27, both >11 months out. No completion marker (F-1) — the only exit path is invalidation.

**Recommendation — HOLD.** No criterion met. All three quantitative Cloud criteria accelerated; the regulatory criterion is unbreached on direct, re-run verification of all four proceedings rather than on absence of news.

---

## Position — TSM (Taiwan Semiconductor, ADR) — Subtype B

**Tranches (2).** `D:TSM:2026-07-21` 0.0891 sh, basis $38.1224, LTCG 2027-07-21 · `D:TSM:2026-07-29` (add) 0.0659 sh, basis $25.8910, LTCG 2027-07-30, filled @ $388.99. **Aggregate 0.1550 sh / $64.0134 basis; mark $402.76 = $62.43 MV, −$1.59 (−2.5%).** CaR 2.59%.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT.** TSM is the sole scaled leading-edge AI-accelerator foundry, the widest structural moat in D's screen universe. The trend metric is a conjunction: USD revenue growth ≥15% YoY **and** gross margin ≥55% **and** a rising sub-7nm mix, sustained ≥12 months.

**2. Driver check.** Leading-edge demand/pricing power **PROGRESSING** — packaging capacity described by management as "so tight that now it's limiting my customers' growth." N2/A16 ramp **PROGRESSING** — N2 at 3% of Q2 wafer revenue in its first commercial quarter, actively ramping through Q3; A16 on track for H2-2026. Sub-7nm mix **PROGRESSING** — 74% → **77%** (2nm 3%, 3nm 30%, 5nm 33%, 7nm 11%). Arizona buildout **PROGRESSING, materially accelerated** — an additional $100B commitment taking the cumulative figure to $265B. TSM's own capex **PROGRESSING** — FY26 guide **$60–64B**, alongside a full-year revenue growth outlook of "slightly above 40%."

**3. Fundamental developments in the incremental window: NONE.** No 6-K or 20-F filed 08-01 through 08-03; no material corporate event located.

**Two open items resolved to a definite status rather than left hanging.**
- **July 2026 monthly revenue: NOT YET PUBLISHED.** TSMC's June release was filed **2026-07-13** (delayed from the ~10th by a typhoon closure); on that cadence July revenue is expected **~2026-08-10**, after this window. This remains the first data point that could reveal any Kumamoto earthquake production impact, which is **still not disclosed**.
- **CoWoS / order-cut evidence: none, and the evidence runs the other way.** Nvidia is reported to have booked ~800,000–850,000 CoWoS wafers for 2026, more than half of TSMC's capacity, with bookings extending several years out; CoWoS is described as sold out through 2026 with capacity targeted at ~125,000–130,000 wafers/month by year-end. One item surfaced a **Google TPU** production-target cut (reportedly 4M → 3M units for 2026) attributed to CoWoS packaging constraints — that is a customer-side adjustment caused by TSMC capacity being scarce, i.e. the opposite of an order cut, and it is **SECONDARY and not independently verified**.

**4. Invalidation criteria — 3/3 NOT BREACHED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | GM <55% **or** USD revenue YoY <15%, for 2 consecutive Q | NOT BREACHED | Q1 GM 66.2% / revenue +40.6%; Q2 GM **67.7%** / revenue **+33.7%** ($40.2B) |
| 2 | N2/A16 ramp pushed out **or** sub-7nm share declines 2 consecutive Q | NOT BREACHED | no pushout language anywhere; mix rose 74% → **77%** |
| 3 | Structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop) | NOT BREACHED — **contradicted, not merely untriggered** | capex guide raised to $60–64B; CoWoS sold out through 2026; no Nvidia order-cut evidence |

*On criterion 2, see F-5: a research pass this cycle flagged "A16" as possibly not a TSMC node. That flag is wrong and is not adopted — A16 (1.6nm-class, Super Power Rail) is a disclosed TSMC node targeted for H2 2026, and A14 is the subsequent node targeted for 2028. The criterion's wording is correct as written.*

**Forward-looking margin note, not a criterion event.** Q3 gross margin is guided **65–67%** against Q2's 67.7%, with management attributing the 3–4 point dilution explicitly to the N2 ramp. That is well above the 55% floor and is ramp economics, not deterioration — but it is the direction criterion 1 watches, and worth carrying.

**5. Sector/theme.** See F-9. Near-term price risk in this name has repeatedly been non-thesis: commodity-DRAM oversupply dragging TSM by sector correlation, and skepticism about *customers'* capex ROI rather than about TSM's order volumes.

**6. Tax.** LTCG 2027-07-21 and 2027-07-30, both ~11.7 months out. No completion marker (F-1).

**Recommendation — HOLD.** No criterion met; criterion 3 is contradicted by TSM's own capex raise and by sold-out CoWoS rather than merely untriggered.

---

## Position — UBER (Uber Technologies) — Subtype B

**Tranche (1).** `D:UBER:2026-07-09` 0.5156 sh, basis $37.7457, LTCG 2027-07-09. **Mark $71.47 = $36.85 MV, −$0.90 (−2.4%).** CaR 1.53%.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT, and about to be tested for the first time.** Marketplace-scale compounding: the dual-sided Mobility + Delivery marketplace compounds Gross Bookings at mid-to-high-teens-plus constant currency while adjusted-EBITDA margin as a percentage of GB expands, funded by the Uber One flywheel and a capital-efficient two-sided AV hedge.

**The framing caveat is unchanged and is the most important sentence in this section: Q2 2026 has still not reported.** The print is **2026-08-05 before market, re-confirmed against Uber IR** — now two days out. Criteria 1–3 are each two-consecutive-quarter tests, and **zero new quarters have printed since entry**; the most recent reported quarters remain Q4 2025 and Q1 2026, both already known at entry. "Intact" here means nothing has had the opportunity to break it.

**2. Driver check (on the two most recently reported quarters).** GB scale compounding **PROGRESSING** — Q1 2026 GB $53.7B, **+25% reported / +21% cc**, a third consecutive quarter at 21%+ cc. Uber One flywheel **PROGRESSING** — 46M at end-2025 → **>50M** in Q1 2026, roughly +4M sequentially, driving ~50% of platform GB. Adjusted-EBITDA margin **PROGRESSING** — Q1 2026 $2,481M on $53,720M GB = **4.62%**, +26bps YoY, with EBITDA growth (+33%) outpacing GB growth (+25%). AV two-sided hedge **PROGRESSING, but with a changed risk character** — AV trips +10× YoY across 8 live cities, >30 partners, while Uber has committed >$10B (~$2.5B direct equity plus ~$7.5B vehicle purchase commitments; Lucid 11.5%/35,000 vehicles, Rivian $1.25B/50,000 robotaxis) to owned or exclusive fleets that compete head-to-head with Waymo — even as Waymo still runs on Uber's app in some markets.

**3. Fundamental developments in the incremental window: essentially none.** No 8-K, no earnings, no new corporate action dated 08-01 through 08-03. One in-window item is continuation coverage (CNBC, 08-01) of the Uber/Waymo relationship change and the D.C.-area gig-labour politics of AV expansion — **the underlying Uber-Waymo split was reported ~2026-07-24, before the window**, so the 08-01 piece is follow-on analysis, not a new corporate event. It is worth carrying: how Uber characterizes the Waymo relationship in its Q2 materials is a genuine read on whether the "aggregate third-party AV demand" leg of the thesis is intact.

**4. Invalidation criteria — 4/4 NOT BREACHED** (against the two most recently reported quarters; no new data since entry).

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | GB cc YoY <~15% for 2 consecutive Q | NOT BREACHED | Q4'25 +22% cc, Q1'26 +21% cc |
| 2 | Adj-EBITDA margin (% of GB) contracts YoY 2 consecutive Q | NOT BREACHED | +40bps YoY, then +26bps YoY — expansion in both |
| 3 | Uber One membership stalls or declines sequentially | NOT BREACHED | 46M → >50M, ~+9% sequentially |
| 4 | Metric-immutability if GB disclosure structurally changes | NOT BREACHED | no GB redefinition; forward watch is the Delivery Hero integration once it closes (target H2 2027) |

*Scope observation carried forward, not acted on: none of the four criteria addresses driver/labour-classification risk.*

**5. Sector/theme.** AV competition remains the core structural risk, now running as three parallel models — Waymo scaling driverless across >10 US markets, Tesla Robotaxi expanding entirely outside Uber's platform, and Uber itself running a hybrid posture of hosting Waymo while funding >$10B of fleets that compete with it. The pending $14.8B Delivery Hero acquisition (announced 2026-07-16, all-cash €41.50/share, 79 → 99 markets, close targeted H2 2027) is a material tailwind if it closes and the principal live threat to criterion 4 when it does.

**6. Tax.** LTCG 2027-07-09, ~11 months out. No maximum hold; no completion marker (F-1).

**Recommendation — HOLD.** No criterion met against the two most recently reported quarters. **Explicitly flagged as the position whose evidentiary basis is thinnest**, entirely because its first new quarter arrives in two days — a monitoring item for M4/M5, not a deferral (F-6).

---

## Position — ISRG (Intuitive Surgical) — Subtype B

**Tranche (1).** `D:ISRG:2026-07-20` 0.1091 sh, basis $38.1316, LTCG 2027-07-20. **Mark $371.76 = $40.56 MV, +$2.43 (+6.4%).** CaR 1.54%. *Strategy-D tranche only; the separate `B:ISRG:2026-07-21` position is out of scope.*
**Span covered:** 2026-08-01 → 2026-08-03 (incremental). **This is the position whose flagged dated event actually landed in the window.**

**1. Thesis status — INTACT.** The da Vinci installed base is a razor-and-blades annuity: procedure volume plus a growing system base drive recurring instrument and service revenue, with da Vinci 5 as an ASP and margin upgrade cycle. Named trend metric: worldwide da Vinci procedure growth ≥13% YoY.

**2. Driver check.** Procedure growth **PROGRESSING** — Q1 +16%, Q2 **+15%** (da Vinci; Ion +36%, combined ~16%), both above the 13% trend floor and well above the 10% invalidation floor. Placements / installed base **PROGRESSING** — Q1 431 placements (232 dV5) vs 367; Q2 **468 (246 dV5)** vs 395, **+18% YoY**; installed base **11,710, +12% YoY** (Ion 1,096, +21%). Recurring revenue vs procedures **PROGRESSING** — Q2 recurring revenue **$2.47B, +19% YoY, 85% of total**, outgrowing procedures. dV5 upgrade cycle **PROGRESSING** — 180 → 246 dV5 placements YoY; non-GAAP gross-margin guidance **raised** to 68.0–69.0%. Competitive moat **INTACT, now facing its first real US regulatory competition in two decades.**

**3. Fundamental developments — the Ottava call landed today.**

**J&J's Ottava investor call, 2026-08-03, 8:00am ET**, following the 2026-07-22 FDA De Novo authorization. **The disclosed commercial framing is "commercially launch with select customers in the U.S., focusing on early customer success while working to expand into additional indications and regulatory jurisdictions over time"** — language identical across J&J's own release, jnjmedtech.com and every secondary source located. **No hospital, IDN or health system was named, in any source.** No Ottava pricing was disclosed. No installed-base or unit figures were disclosed. Secondary coverage adds an intent to accelerate launches in Japan and Western Europe.

**Caveat, stated rather than glossed:** the substantive readout of the call *itself* had **not yet been indexed** at research time — the call's timing coincides with this research window. The criterion-4 verdict below therefore rests on J&J's own pre-call and launch-framing language plus all coverage available as of writing, which is consistent and unambiguous, but is not the same as having read the call transcript. **This is carried to D1/W3 for a re-check once call coverage indexes** — a monitoring item, not a deferral.

Analyst posture ahead of the call (secondary, late July): J.P. Morgan reported physician checks still favouring Intuitive; Jefferies expected no meaningful J&J revenue impact before 2028; UBS upgraded ISRG to Buy while cutting its target to $500.

No ISRG-specific 8-K or corporate action was found dated 08-01 through 08-03 beyond routine institutional-holding filings.

**4. Invalidation criteria — 4/4 NOT BREACHED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | Procedure growth <10% YoY for 2 consecutive Q | NOT BREACHED | +16%, +15% |
| 2 | Placements decline YoY for 2 consecutive Q | NOT BREACHED | 431 vs 367 (+17.4%); 468 vs 395 (+18.5%) |
| 3 | Recurring revenue decouples downward from procedures | NOT BREACHED | recurring +19% vs procedures +15% |
| 4 | **Competitor discloses displacing dV at named large IDNs** | **NOT BREACHED — tested today against the single most likely triggering event and it did not trigger** | J&J named **no** customer; "select customers," no names, no pricing, no installed base |

*Measurability note carried forward: criterion 4 is a negative/absence test — measurable as NOT BREACHED today, never permanently confirmable. Re-searching competitor disclosures each cycle is the correct discipline, and this cycle it was tested against the highest-probability event available.*

**FY2026 guidance — the tikr.com claim is refuted a second time, independently.** Guidance is **reaffirmed at 13.5–15.5%** da Vinci procedure growth, with management guiding toward the **midpoint** — confirmed across the company release, the Q2 call transcript and multiple independent summaries. **No source supports the "raised to 14–16%" claim.** What was raised at Q2 is non-GAAP gross margin, to 68–69%.

**5. Sector/theme.** The multi-decade robotic-surgery adoption curve is intact. Ottava's clearance creates the *regulatory precondition* for a future displacement claim — joining Medtronic Hugo and CMR Versius in pursuing a US beachhead — but creates no displacement today. The demand-side headwinds management named (ACA subsidy expiration, GLP-1-driven bariatric decline, softening hospital surgical volumes) fall squarely inside Strategy D's "macro shifts that don't bear on the multi-year thesis" carve-out and are not exit-triggering unless they surface as a two-consecutive-quarter breach of criterion 1.

**6. Tax.** LTCG 2027-07-20; the position is two weeks old. No completion marker (F-1).

**Recommendation — HOLD.** No criterion met. Criterion 4 was tested this cycle against the most credible competitive event available and returned a clean negative — the strongest evidentiary result in the book this window.

---

## Position — CRM (Salesforce) — Subtype B

**Tranche (1).** `D:CRM:2026-07-09` 0.2275 sh, basis $36.4811, LTCG 2027-07-09. **Mark $189.50 = $43.11 MV, +$6.63 (+18.2%) — the book's best percentage performer this cycle.** CaR 1.48%.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT, with the same standing limitation.** Enterprise AI-agent monetization: Agentforce plus Data 360 converting into a fast-growing, high-margin ARR stream across ~150k existing customers, with more than half of bookings coming from expansion of existing accounts. Trend metric: Agentforce + Data-360 ARR growth ≥50% YoY **and** cRPO in low double digits.

**The limitation is structural and unchanged.** Salesforce runs a January fiscal year. The position's entire life sits inside a single inter-earnings gap: the last print — **Q1 FY27, reported 2026-05-27** — *predates entry itself*, and the next has not arrived. "Intact" means nothing has yet had the opportunity to break it, not that fresh evidence has confirmed it.

**2. Driver check (all figures from the Q1 FY27 print, the same data the thesis was built on).** Agentforce + Data 360 ARR **PROGRESSING** — Agentforce $1.2B, **+205% YoY**; combined ~$3.4B. cRPO **PROGRESSING** — $33.6B, +14%. Non-GAAP operating margin **PROGRESSING** — **34.8%**, +250bps YoY, a record. FY27 revenue guide **PROGRESSING** — raised to **$45.9–46.2B**, ~+11% YoY. Existing-base expansion **PROGRESSING** (qualitative, unchanged).

**3. Fundamental developments in the incremental window: none material.** The only in-window item located is a routine institutional position change (Carmignac Gestion, 08-03) — not a corporate action. The new EVP of Engineering hire (Krishna Kumar Parthasarathy, ex-Microsoft) was announced **2026-07-30**, just before the window, amid continued executive churn. No 8-K was found dated 2026-07-01 through 2026-08-03.

**A dating conflict worth carrying, because it moves a criterion's testability.** Two secondary sources give **different** Q2 FY27 report dates: one cites **2026-08-26 after market close**, another **2026-09-02**. **No primary Salesforce announcement of the date was located.** The 08-01 edition carried ~09-02 as the single unconfirmed estimate; the earlier of the two dates would make criterion 2's two-quarter cRPO test runnable **three weeks sooner than previously assumed**, i.e. potentially before the next monthly cycle. M4/M5 should watch for the IR announcement rather than assuming September.

**4. Invalidation criteria — 4/5 NOT BREACHED, 1 not yet evaluable.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | Agentforce/Data-360 ARR growth <~50% YoY | NOT BREACHED (no new data in window) | $1.2B, +205%; combined ~$3.4B |
| 2 | cRPO <10% cc for 2 consecutive Q | NOT BREACHED on the single available quarter; **the two-quarter test STILL CANNOT BE RUN** | Q1 FY27 +13% cc, above the 10% floor; Q2 FY27 has not printed. *Sourcing caveat: whether the reported +14%/+13% figure is the cc or the nominal number was not separately broken out in the sources available this cycle — the criterion tests cc, and the distinction is not decision-relevant at a +13/14% reading against a 10% floor, but it is recorded* |
| 3 | Non-GAAP op margin contracts YoY | NOT BREACHED | 34.8% vs 32.3%, +250bps |
| 4 | FY27 revenue guide cut <~10% | NOT BREACHED | guide **raised** to $45.9–46.2B |
| 5 | Metric-immutability if Agentforce ARR stops being disclosed in original form ≥2Q (CRM moves to disaggregated revenue reporting in FY28) | NOT BREACHED — **0 of the required ≥2 quarters have accrued** | the segment-revenue change is distinct from the Agentforce ARR KPI, which was still disclosed in original form at the Q1 FY27 print; the non-disclosure clock has not begun |

**5. Sector/theme.** Enterprise agentic-AI adoption is accelerating broadly, but the competitive question is unresolved: Microsoft (Copilot Studio / M365 Agents), ServiceNow, and the frontier model vendors' own agent-building primitives could all disintermediate a platform-specific agent layer. Much of CRM's steep 2026 decline (~31–38% YTD across sources) appears to be sector-wide "AI cannibalizes SaaS seats" repricing — a category Strategy D explicitly carves out as not invalidating. The Morgan Stanley downgrade of 2026-07-21 (Overweight → Equal-Weight, PT $287 → $185) was framed as *"AI thesis intact, timing concerns"* — a pacing call, and under Strategy D a sell-side rating change is not an invalidation trigger.

**6. Tax.** LTCG 2027-07-09, ~11 months out. No completion marker (F-1). The next catalyst inside the LTCG window is the Q2 FY27 print, which supplies the second cRPO data point.

**Recommendation — HOLD.** Every evaluable criterion NOT BREACHED; every driver progressing in the same direction as at entry. Stated with its limitation: **this is confirmation by absence of contradiction, not fresh corroboration**, and it will remain so until Q2 FY27 prints. That is a known, dated, self-resolving gap — a monitoring item, not a deferral (F-6).

---

## Position — DIS (The Walt Disney Company) — Subtype B

**Tranche (1).** `D:DIS:2026-05-07` 0.2822 sh, basis $31.4142, **`ltcg_date` now correctly 2027-05-08 (F-4 closed)**. **Mark $98.13 = $27.69 MV, −$3.72 (−11.8%) — the book's worst performer, though the loss narrowed from −13.6% last cycle.** CaR 1.27%.
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT on unchanged data.** Entertainment SVOD operating margin, having crossed double digits for the first time in Q2 FY26, sustains ≥10% over 12+ months, compounding with reaffirmed FY26 guidance and an accelerated buyback. The primary driver was deliberately reframed at entry from "management-execution-quality" to the financial-metric-traceable SVOD margin trajectory, with management execution retained only as a bounded secondary contributor.

**Nothing in the window changed a reported metric.** The last primary financial disclosure remains the Q2 FY26 8-K/10-Q of 2026-05-06/07. The thesis holds on unchanged data, and **the position is two days from its first live test since entry.**

**2. Driver check.** SVOD margin ≥10% **PROGRESSING** — 10.6% in Q2 FY26 (operating income $582M, **+88% YoY**), with the company reaffirming "at least 10% for full fiscal year 2026." FY26 adjusted EPS growth **PROGRESSING/unchanged** — ~12% ex-53rd-week (~16% including), raised at Q2, **no revision and no guidance-update 8-K in the window**. FY27 double-digit adjusted EPS growth **unchanged**. Buyback **PROGRESSING, well ahead of pace** — **$5.5B** repurchased in H1 FY26 (51M shares, per the 10-Q cash-flow statement) against a full-year target raised to **at least $8B**, i.e. 69% executed at the half. Management continuity **PROGRESSING** — the A+E Global Media 50% linear-TV stake sale to Hearst (>$1B) is a mid-tier cable-JV exit consistent with the announced strategic pillars, and the CFO has separately said Disney does not plan to spin off or sell ABC/ESPN.

**3. Fundamental developments in the incremental window: NONE.** No 8-K, no material corporate or regulatory news dated 08-01 through 08-03.

**Both flagged 08-05 events remain pending and both are now two days out.** Q3 FY26 earnings are **re-confirmed for 2026-08-05, 8:30am ET before market**. The FCC reply-comment deadline in the ABC licence proceeding is the same day. On the FCC matter: **no order of any kind has been issued**, and **no Disney 8-K** characterising it as a material adverse impact exists — Disney's public posture has been to ask the FCC to reject the petitions to deny as "punitive," not to make a materiality disclosure. *Sourcing note: the docket number circulating in secondary coverage as "Media Bureau Docket No. 26-131" is **secondary-sourced and not confirmed against a primary FCC ECFS page** — treat as tentative. All litigation-posture detail on this proceeding remains secondary reporting.*

**4. Invalidation criteria — 5/5 NOT BREACHED / NOT TRIGGERED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | **Primary** — Entertainment SVOD operating margin <8% for 2 consecutive Q | NOT BREACHED | Q1 FY26 **8.4%**, Q2 FY26 **10.6%** — both above the 8% floor and above the baseline net of the −40bps tolerance. *Q4 FY25's operating income rose $99M to $352M, directionally supportive, but its margin percentage is **NOT VERIFIED** from a primary source and is not relied on* |
| 2 | **Secondary** — FY26 adjusted EPS growth guide cut to ≤6% | NOT BREACHED | guidance stands at ~12% ex-53rd-week / ~16% including, reaffirmed 2026-05-06, unrevised through the window |
| 3 | **Buyback** — ≤$3B at H1 close, ≤$5B at the Q3 FY26 print, or a suspension/reduction 8-K | NOT BREACHED — **the Q3 leg is now un-breachable by arithmetic** | H1's $5.5B already exceeds the $5B Q3 floor, and cumulative buyback is monotonic. Only the suspension/reduction-8-K limb remains live, and none has been filed. *This arithmetic closure is M3's synthesis, not a company disclosure* |
| 4 | Metric-immutability — SVOD OI/margin undisclosed in current form ≥2 consecutive Q | NOT BREACHED | disclosed in current form in both Q1 and Q2 FY26 |
| 5 | **Regulatory-impairment escalation** — a final FCC order materially restricting station ownership **AND** a Disney 8-K of material adverse FY26/FY27 EPS impact. *An escalation-to-review trigger, NOT auto-invalidation, per its own text* | **NOT TRIGGERED** | **both prongs are required; neither is met.** No final order; no 8-K |

**5. Sector/theme.** The "media companies politicized by content decisions" theme continues to sharpen — the ABC licence fight runs parallel to Paramount-Skydance's own regulatory exposure, which argues for a **sector-wide** regulatory-risk premium on legacy broadcast-licence holders rather than a DIS-idiosyncratic one. The A+E divestiture is evidence of the secular linear→streaming rotation proceeding on plan.

**6. Tax.** LTCG **2027-05-08**, ~9 months out — the nearest in the book, and now correctly recorded following the F-4 correction. The entry's Q3 FY26 checkpoint is a *reassessment* trigger, not a completion marker (F-1).

**Recommendation — HOLD.** No criterion met or triggered; both quantitative drivers are tracking at or ahead of plan and FY26 guidance is unrevised. The −11.8% mark is explicitly not exit-triggering under Strategy D. **The 08-05 print is the first live test of the reframed thesis since entry** and is carried as a monitoring item.

---

## Position — RTX (RTX Corporation) — Subtype B

**Tranche (1).** `D:RTX:2026-04-27` 0.1601 sh, basis $28.3215, **`time_exit_date` now correctly NULL and `ltcg_date` 2027-04-27 (F-4 closed)**. **Mark $216.14 = $34.60 MV, +$6.28 (+22.2%) — the book's best absolute and percentage performer.** CaR 1.15%. **Oldest D position (98 days).**
**Span covered:** 2026-08-01 → 2026-08-03 (incremental).

**1. Thesis status — INTACT, materially strengthened.** An aerospace/defense prime entered counter-cyclically on a sentiment-driven post-Q1 pullback judged not thesis-breaking. Drivers: GTF/PW1100 recovery, record and growing commercial-plus-defense backlog, the FY26 FCF/EPS guidance trajectory, and the US defense-procurement tailwind.

**2. Driver check — against the entry's own named Q1'27 falsifiable milestones, all five of which are satisfied or on track three quarters early.** AOGs down ≥25% from YE2025 **PROGRESSING, ahead of target** — down 25% year-to-date on 43% YoY MRO output growth and 23% lower turnaround time. GTF Advantage entry into service **PROGRESSING, on or ahead of schedule** (see criterion 3). Backlog ≥$280B by Q1'27 **ALREADY EXCEEDED** — **$289B** at Q2'26. FY26 adjusted EPS within $6.70–6.90 **EXCEEDING** — raised to **$7.10–7.25**. Defense organic growth ≥mid-single-digits **WELL ABOVE** — Raytheon segment +18% organic, FY26 outlook raised to "high single digits to low double digits."

**3. Fundamental developments in the incremental window: one program milestone, no filings.** Raytheon delivered and installed the first **SPY-6(V)4 radar array** at the Surface Combat Systems Center, Wallops Island (2026-08-03) — a milestone for the Navy Flight IIA destroyer modernization/backfit program, and a company press release rather than an 8-K. **No 8-K has been filed since the 2026-07-23 Q2-earnings 8-K.** The $1.3B F135 sustainment IDIQ award was announced 2026-07-31, just before the window.

**4. Invalidation criteria — 6/6 NOT BREACHED.**

| # | Criterion | Verdict | Measured |
|---|---|---|---|
| 1 | Material adverse Airbus damages ruling >$2B | NOT BREACHED | **No ruling has been issued.** Airbus's formal damages claim (confirmed 2026-03-19) remains in litigation/negotiation. Reported potential exposure is in the hundreds of millions; the 10-Q states "not expected to have a material adverse effect." *Measurability note: can only ever read NOT BREACHED until an adjudicated or settled figure exists* |
| 2 | New powder-metal-style mass quality event >$1B incremental charge | NOT BREACHED | no new event; the 2023-origin program is winding down — accrued customer compensation reduced to **$0.4B**, with ~$150M of routine payments in Q2 (a drawdown, not a new charge) |
| 3 | GTF Advantage EIS slips beyond Q1'27 | NOT BREACHED — **and the margin is wider than previously understood** | see below |
| 4 | Backlog declines two consecutive quarters | NOT BREACHED — opposite trend | $268B → $271B → **$289B** ($170B commercial / $119B defense), **+22% YoY, +6% sequentially** |
| 5 | FY26 FCF guide cut below the $7.5B floor | NOT BREACHED — guide **raised** | **$8.50–8.75B**, a full $1.0B above the floor |
| 6 | FY27 defense procurement cut ≥10% YoY | NOT BREACHED — opposite trend | FY27 request $1.5T total ($1.15T discretionary base + $350B reconciliation), ~25% base increase; House Appropriations FY27 DOD bill funds several lines above request. *Measurability note: not fully measurable as **enacted** until FY27 appropriations conclude (Q4 2026 / Q1 2027); the current read is at request/markup stage and is unambiguously not a cut* |

**Criterion 3 — a disambiguation this cycle, which widens the margin.** Research this cycle surfaced that the "Q1 2027" date is doing two different jobs across sources. **Base GTF Advantage entry into service has already effectively begun**: EASA certified the GTF Advantage-powered A320neo family in **April 2026**, and the first production shipset went to Airbus in **May 2026**. The "late 2026, more likely Q1 2027" timing that circulates attaches to a **distinct "Hot Section Plus" retrofit/upgrade package**, not to base EIS. Full production-standard cutover remains targeted for early 2028. Either reading leaves criterion 3 NOT BREACHED, and the base-EIS reading leaves it not breached by a wide margin. *Recorded as a sourcing nuance: no primary RTX/P&W document disambiguating the two milestones was read directly, so the distinction itself is **not primary-confirmed** — but the criterion's verdict does not turn on it.*

**5. Sector/theme.** Demand is robust across all three segments. Commercial aftermarket strength is structurally tied to airlines flying older aircraft longer while GTF issues resolve. Defense demand is pulled by conflict-driven munitions restocking, a historically large (not yet enacted) FY27 request, and strong international bookings — Raytheon's backlog is now 48% international, +4pp YoY. Peer primes reported similarly strong results, corroborating a sector-wide rather than RTX-idiosyncratic upcycle. **The acute shock overlay in this month's regime scoring is, uniquely in this book, a tailwind rather than a headwind for this position** — though nothing in the thesis depends on it and it is not treated as evidence.

**6. Tax.** LTCG **2027-04-27**, ~9 months out, now correctly recorded following the F-4 correction. **There is no time exit and no maximum hold** — the entry states verbatim that the position "runs to thesis-invalidation by (i)-(vi) above OR negative outcome on the falsifiable-milestone reassessment at Q1'27 earnings." The Q1'27 reassessment is a *reassessment* trigger, not a completion marker, and RTX remains F-1's live illustration: all five milestones already satisfied, with no mechanism by which that reads as completion.

**Recommendation — HOLD.** No criterion met; all six unambiguously NOT BREACHED, five having moved further from breach in the most recent quarter.

---

## Summary — recommendations

| Name | Criteria status | Recommendation | Citation |
|---|---|---|---|
| **GEV** | **2/2 NOT BREACHED** | **FURTHER RESEARCH** | **Not a thesis-health call.** Information gap: Strategy D **Entry criterion 2** — is the "last 8 quarters of earnings call transcripts (minimum)" a hard floor, or is a documented substitute evidence base admissible? The GO was recorded PROVISIONAL on this point; a same-session sibling thesis (BA) was **refused** on the identical limitation; the framework's own correction entry required resolution **before** crafting, and the order was crafted and filled with the flag open. Venue: **W5**. See F-8 |
| AMZN | 5/5 NOT BREACHED | **HOLD** | No criterion met. AWS +37% YoY (5th consecutive acceleration), margin 39.4% (series high), backlog **$496B primary-confirmed in the 10-Q filed 2026-07-30**, WAL 6.4yr |
| GOOGL | 5/5 NOT BREACHED | **HOLD** | No criterion met. Cloud +82% YoY, margin 35.6%, backlog $514B; **no structural remedy ordered in any jurisdiction**, re-verified 2026-08-03 across all four proceedings — Mehta's final order rejected divestiture; Brinkema and EU AT.40670 both still undecided |
| TSM | 3/3 NOT BREACHED | **HOLD** | No criterion met. GM 67.7%, USD revenue +33.7% YoY across both required quarters; sub-7nm mix 74%→77%; criterion 3 **contradicted** by the capex raise to $60–64B and CoWoS sold out through 2026 |
| UBER | 4/4 NOT BREACHED | **HOLD** | No criterion met. GB cc +22%/+21% across the two required quarters; adj-EBITDA margin **expanding** (+40bps, +26bps YoY); Uber One 46M→>50M. **Thinnest evidentiary basis in the book — first new quarter prints 2026-08-05** |
| ISRG | 4/4 NOT BREACHED | **HOLD** | No criterion met. Procedures +16%/+15%; placements +17.4%/+18.5%; recurring revenue +19% outgrew procedures. **Criterion 4 tested today against J&J's Ottava call: no IDN, hospital or health system named anywhere** |
| CRM | 4/5 NOT BREACHED, 1 not yet evaluable | **HOLD** | No criterion met. Criterion 2's two-quarter cRPO test **still cannot be run**; the single available quarter is +13% cc against a 10% floor. Report date conflicted across sources (08-26 vs 09-02) — may become runnable sooner than assumed |
| DIS | 5/5 NOT BREACHED / NOT TRIGGERED | **HOLD** | No criterion met. SVOD margin 8.4%/10.6% against an 8% floor; H1 buyback $5.5B against a ≤$5B Q3 floor, making that leg un-breachable; criterion 5 requires **both** a final FCC order and a Disney 8-K — **neither exists** |
| RTX | 6/6 NOT BREACHED | **HOLD** | No criterion met. Backlog $289B (+22% YoY, +6% seq); FY26 FCF guide **raised** to $8.50–8.75B against a $7.5B floor; GTF Advantage base EIS already begun (EASA cert April 2026) |

**No exits staged. One research-deferral raised (GEV).** **No IMMEDIATE-ACTION flag**, therefore no `ops.sp_raise_alert('warning','M3','immediate_action_flagged',...)` call is due this cycle.

## Dated items M4/M5 should carry (monitoring, not deferrals)

| Date | Item | Bears on |
|---|---|---|
| **2026-08-05** | **DIS Q3 FY26 earnings (CONFIRMED, 8:30am ET)** | DIS criteria 1, 2, 3 — first live test of the reframed thesis since entry; supplies a third consecutive SVOD-margin point |
| **2026-08-05** | FCC reply-comment deadline, ABC licence proceeding | DIS criterion 5 (escalation trigger; needs a final order **and** an 8-K, so the deadline alone cannot trip it) |
| **2026-08-05** | **UBER Q2 2026 earnings (CONFIRMED, 8:00am ET)** | UBER criteria 1–3 — first genuinely new quarter since entry |
| **~2026-08-10** | TSMC July monthly revenue | First data point that could reveal any Kumamoto earthquake production impact (still **NOT DISCLOSED**) |
| **2026-08-26 or ~2026-09-02 (sources conflict)** | CRM Q2 FY27 earnings | CRM criterion 2 — first time the two-quarter cRPO test becomes runnable; also starts criterion 5's disclosure-immutability clock. **Watch for the IR announcement rather than assuming September** |
| **~late Oct 2026** | GEV Q3'26 print | GEV criteria 1–2 — first new data point on the named trend metric since entry; also the next backlog reading against the $200B completion leg |
| ~2026-10-15 (estimated) | TSM Q3 CY2026 | TSM criteria 1, 2 — third consecutive quarter; also the first print under the guided 65–67% GM |
| ~2026-10-20 / 10-28 / 10-29 (all unconfirmed) | RTX, GOOGL, AMZN Q3 prints | Respective criteria |
| **Any time — triage immediately, do not hold for the monthly cycle** | Brinkema's US ad-tech remedies ruling (E.D. Va.); EU AT.40670 decision | **GOOGL criterion 4** — the only two live paths to a structural remedy anywhere |
| **Whenever call coverage indexes** | J&J Ottava 2026-08-03 investor-call readout | **ISRG criterion 4** — this cycle's verdict rests on J&J's launch-framing language, not on the call transcript; re-check via D1/W3 |
| ~2026-09-21 | Alphabet DMA 60-day compliance deadline | GOOGL — no divestiture component, monitoring only |

## Items requiring action by an owner other than M4's exit path

1. **The Strategy D Entry-criterion-2 adjudication is the highest-priority open item in this file, and it is not M4's to settle.** Two questions, both routed to **W5**: (i) *interpretive* — is the 8-quarter transcript minimum a hard floor that fails a thesis when unmet, or is a documented substitute evidence base admissible? (ii) *infrastructure* — the FMP plan tier gates `earningsTranscript`, `statements` and `analyst`, which is an **owner-actionable subscription question**, not something a routine can fix. Until one resolves, **every future D thesis will keep hitting this and resolving it ad hoc, inconsistently** — and this cycle's own research pass hit it again, compounded by session-wide FMP rate-limiting. See F-8.
2. **Finding F-1 residual** — the systematic absence of thesis-completion criteria across the **eight legacy** D positions is a construction-discipline matter that is **not retroactively fixable** (criteria are immutable for a position's life). GEV has closed it for new entries. The open `revise-premortem-D-2026-a3` queue item — now flagged stale by D3 — and the 2026-07-30 AR_orc cycle-5 TIER 1 DEFECT outcome remain the natural venue for the residual.
3. **Finding F-9** — the AI-capex theme now stands at **14.60% of D NAV and 67.7% of deployed D capital across four names in four GICS sectors**, with capex-driven FCF compression at the two payers (AMZN TTM FCF −$7.6B; GOOGL first negative-FCF quarter −$5,855M, zero buybacks) uncovered by **any** invalidation criterion in **any** of the four theses. Recorded for future thesis construction; not actionable against open positions.
4. **`D:GEV:2026-08-03` still carries its provisional staging cost basis** ($123.92 against a real ≈$120.66). Routine — D2a Step 0 supersedes on fill reconciliation. Becomes a genuine defect only if unreconciled by the next cycle. See F-4.
5. **Prior cycle's two ledger defects are CLOSED** (RTX field transposition, DIS NULL `ltcg_date`), both corrected append-only by `bigquery/121` and verified this cycle. **Do not re-raise.**
6. **Data-hygiene item for W5/D3 — the staging-time lowercase-`open` status literal (F-11).** `analytics.strategy_nav`, and by extension `state.daily_briefing` and `weekly_report`, filter on `status = 'OPEN'` and therefore **silently drop every position between staging and D2a reconciliation**. `D:GEV:2026-08-03` and `B:MTZ:2026-08-03` both carry lowercase `open` right now; D2a has repaired exactly this before (`B:MSCI:2026-07-27`). The durable fix belongs at the writer or in the views' predicate, not in repeated post-hoc corrections — the current pattern means positions are sized against a NAV view that cannot see the most recently staged positions.
7. **Infrastructure defect corroborated for W5/D3 — IBKR `get_price_history` contract-level series swap (F-5).** Independently reproduced this cycle with a precise signature: 7 of 9 series mislabelled in a clean permutation on a single batched call. Silent, well-formed, and **not fixable by sequential fetching**. Any routine consuming this tool needs an independent-endpoint cross-check. This is a second reproduction of the defect M2 escalated the same day.
8. **M4 is unblocked and should be re-fired.** It halted 2026-08-01 on the M1a→M1b chain break; M1a, M1b and M2 have all completed today, and this file satisfies its M3 dependency and freshness gate (marker 2026-08). The 2026-08-01 `missing_dependency` criticals for M1b and M4 are still open in `ops.alerts` and are now stale.

## Method and sourcing notes

- **Two-day incremental window, reported as such.** For the eight carried names the research window is 2026-08-01 → 2026-08-03 and is genuinely near-empty. Empty windows are reported as "NO EVENTS FOUND IN WINDOW" rather than padded with re-narrated prior-cycle material; the prior cycle's findings are re-verified and carried, not re-derived. GEV is the exception and received a full first deep-dive.
- **Every invalidation criterion was tested against primary sources where they exist** — SEC 8-K/10-Q/10-K filings and EDGAR-hosted exhibits, company IR releases, earnings-call transcripts, court dockets and EU Commission case pages. Two-consecutive-quarter tests were evaluated on **both** required quarters or explicitly reported as not-yet-runnable; none was inferred from a single quarter.
- **Three figures were upgraded from secondary to primary this cycle**: AMZN's $496B backlog (10-Q accession 0001018724-26-000026, filed 2026-07-30, verbatim revenue-note text); Alphabet's −$5,855M FCF and $0 buyback (SEC-filed Ex-99.1); GEV's entire six-quarter organic-orders series (SEC-hosted press-release exhibits fetched directly).
- **Load-bearing figures that remain SECONDARY pending primary confirmation are flagged in place**: the hyperscaler capex guidance underpinning TSM's criterion 3; Amazon's ~$220B capex figure (earnings call, not an SEC filing); Alphabet's $195–205B FY26 capex range; GEV's tariff figures ($250–350M → $100–200M — the Q2 press release contains no tariff dollar figure at all); GEV's Q2 EPS miss; the "$200B by 2027" backlog framing (**primary written source says 2028** — see F-10); the FCC docket number 26-131; TSM's exact node-mix table.
- **Sub-agent output was not taken at face value.** One research pass this cycle produced a false flag on TSM invalidation criterion 2 (claiming "A16" may not be a TSMC node); it was checked and **rejected**, not propagated. See F-5.
- **Marks are the IBKR connector, not aggregators.** Aggregator quote pages diverged materially from the connector on 08-03 and from each other on 07-31 closes; the connector is authoritative per Operating_Protocols.md §11 and is internally consistent with its own `daily_pnl` on every name. See F-5.
- **The correlation matrix (F-7) reached the full specified window this cycle** — 252 daily returns over 253 common trading dates, 2025-07-30 → 2026-07-31, across all nine names including GEV. The prior edition's 208-return shortfall is closed. Values were computed from adjusted closes and independently re-verified against raw unadjusted closes over the identical date set (top five pairs agree to within 0.002), with the underlying series validated at source against the IBKR connector and BigQuery.
- **Nothing in this file was estimated and presented as reported.** Where a figure could not be verified it is labelled NOT VERIFIED in place; where sources conflict, both readings are given rather than one silently chosen (CRM's report date, GEV's $200B target year, GEV's competitive share, DIS's Q4 FY25 SVOD margin). Where a criterion's two-quarter test cannot yet be run, it is reported as not-yet-runnable rather than inferred from one quarter.
- **M3 is research-only. This routine wrote nothing to `state.*`, `events.*` or `perf.*`** beyond its own `ops.run_log` rows. Every ledger observation above (GEV's provisional basis, the lowercase status literal, the `strategy_nav` exclusion) is reported for its owner, not repaired here.

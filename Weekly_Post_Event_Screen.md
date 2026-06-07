2026-W24

# Weekly Post-Event Screen — Strategy B (deep research)

**Run:** Sunday 2026-06-07 MT (ISO week 2026-W24, the upcoming trading week; consistent with the W1 batch committed today).
**Screen window — prior 10 trading days:** **2026-05-22 → 2026-06-05** (5/25 Memorial Day was a market holiday). Trading days in window: 5/22, 5/26, 5/27, 5/28, 5/29, 6/1, 6/2, 6/3, 6/4, 6/5.
**Universe filter:** US-listed common equity, market cap ≥ $2B, 30-day ADV ≥ $10M, close-to-close move ≥ 5% (either direction) on a day in the window, attributable to a public event.

## Operating context (binds the screen)

- **Strategy B router = ACTIVATE** (`state.current_regime`, 2026-06-03): SPY Trend NEUTRAL (≠ DOWN), VIX not HIGH. B entries are admissible this week.
- **Macro caveat (material to B).** Fri 6/5 was a genuine risk-off session: Nasdaq −4.18% (worst since Apr 2025), S&P −2.64%, led by an AI-capex de-rating (AVGO custom-XPU-ramp miss + Micron/Broadcom −~20% over two days, ~$1T chip-complex value erased) compounded by a hot May NFP (+172K vs ~+80K) → higher-for-longer. SPY Trend is judged still NEUTRAL (single −2.6% day from a 5/31 record), so B stays active — but **B's own router rationale warns that in/near macro-cascade conditions "overreaction" is hard to distinguish from regime change.** Any event-day move that lands inside the 6/4–6/5 risk-off (esp. tech/AI-power) is partially tape-driven and must be decomposed before a mean-reversion thesis is credited.
- **Open positions (exclusions/dedup).** Strategy A: **none open** → the "exclude open A name" and A↔B simultaneous-holding constraints have no live conflict this week. Open Strategy B names (not new-entry candidates): **AZO, HCA, TJX, ZBRA** (BRC closed 6/5 on convergence; D book: RTX, DIS).
- **"NO-GO records are context, not barriers."** Names carrying a prior-window NO-GO are re-examinable on fresh evidence and are surfaced below; they are not auto-excluded. Where fresh analysis does not overturn the decisive flaw, they are listed as *resolved context* and are NOT re-ranked into the actionable shortlist (re-queuing a robust sub-pattern NO-GO would only re-derive the same disposition and burn a D2 cycle).
- **Methodology note.** This window was already screened name-by-name by the daily D1 scan → D2 thesis-construction pipeline (the `events.decision_log` B register shows ~30 candidates evaluated 5/22–6/6). This W2 screen reconciles that daily record into the full universe, adds the non-earnings event movers the daily earnings cadence does not systematically sweep (M&A, capital actions, ASCO/clinical), verifies the genuinely-live candidates' magnitudes against the IBKR connector, and ranks only what remains actionable.

---

# PART 1 — Qualifying universe (≥5% close-to-close, event-driven, ≥$2B, ADV≥$10M)

Sorted by event date, most recent first. "Day-0" = the close-to-close reaction day (the session after an AMC print). Disposition column reflects the daily-cadence record in `events.decision_log` unless marked **LIVE/NEW**. Magnitudes marked *(verified)* were confirmed against IBKR `get_price_history` this run; others are the daily-scan magnitude (criterion-1 cleared = the name went to full criterion-4 thesis).

### A. Earnings / guidance events

| Ticker | Name | Event date (Day-0) | Event type | Move (close-to-close) | Dir | Disposition (sub-pattern) |
|---|---|---|---|---|---|---|
| **LULU** | Lululemon Athletica | print 6/4 AMC (Day-0 6/5) | Q1 FY26 earnings + **FY26 guide cut** | **−8.56%** *(verified, 124.92→114.23)* | DOWN | **LIVE — thesis queued (`thesis-LULU-B-20260608`, due 6/8)**; SP4c/SP6 risk flagged |
| AVGO | Broadcom | print 6/3 AMC (Day-0 6/4) | Q2 FY26 earnings (AI-networking rev miss) | ≥5% | DOWN | NO-GO (SP3 pre-print-rally absorption, beat-and-fade) |
| CPRI | Capri Holdings | Day-0 6/4 | Q4 FY26 earnings + analyst action | +8.05% | UP | NO-GO (SP6; also prior 6/2 SP5 / 6/3 event-verification entries) |
| THO | THOR Industries | Day-0 6/4 | FQ3 2026 earnings | ≥5% | DOWN | NO-GO (SP6 negative + 4c overlay) |
| ANF | Abercrombie & Fitch | print ~6/2–6/4 | Q1 FY26 earnings (Q2 guide miss) | ~≥5% (event-day measurement artifact) | DOWN | NO-GO (SP6; criterion-4 information-driven) |
| GTLB | GitLab | print 6/2 AMC (Day-0 6/3) | Q1 FY27 earnings | ≥5% | UP | NO-GO (SP1) |
| HRL | Hormel Foods | Day-0 6/3 | Q2 FY26 earnings (relief rally) | ≥5% | UP | NO-GO (SP8 candidate; criterion-3 degenerate) |
| DLTR | Dollar Tree | Day-0 6/3 | Q1 FY27 earnings | ≥5% | UP | NO-GO (criterion-4; split sell-side, no SP1 trigger) |
| MDT | Medtronic | Day-0 6/3 | Q4 FY26 earnings | ≥5% | UP | **GO (SP1)** — staged LONG; never filled, re-crafted 6/6 (DAY $78.25, instr id 100) |
| A | Agilent Technologies | Day-0 6/1 | Q2 FY26 earnings | ≥5% | UP | NO-GO (SP1; ~72%) |
| DELL | Dell Technologies | Day-0 6/2 | Q1 FY27 earnings | ≥5% | UP | NO-GO (SP1 most-extreme breadth / layered-1+3) |
| HPE | Hewlett Packard Enterprise | Day-0 6/2 | Q2 FY26 earnings | ≥5% | UP | NO-GO (SP1 most-extreme PT-raise tier; ~78%) |
| NTAP | NetApp | Day-0 6/2 | Q4 FY26 earnings | ≥5% | UP | NO-GO (SP1 multi-firm bull-ratification) |
| OKTA | Okta | Day-0 6/2 | Q1 FY27 earnings | ≥5% | UP | NO-GO (SP1 + stock-above-PT-cluster; ~76%) |
| SNOW | Snowflake | Day-0 6/2 | Q1 FY27 earnings | ≥5% | UP | NO-GO (SP1 layered-1+3 / AMD-analogue; ~75%) |
| ZS | Zscaler | Day-0 6/2 | Q3 FY26 earnings | ≥5% | UP | NO-GO (criterion-4; stock within new cut-PT cluster; ~80%) |
| SAIC | Science Applications Intl | print 6/2 BMO | Q1 FY27 earnings | ≥5% | mixed | NO-GO (SP1 / stock-at-PT-consensus; ~72%) |
| BBWI | Bath & Body Works | Day-0 6/2 | Q1 FY26 earnings | ≥5% | UP | NO-GO (SP6/SP7 mass-PT-cut ratification) |
| BBY | Best Buy | Day-0 6/2 | Q1 FY27 earnings | ≥5% | UP | NO-GO (SP8 + SP3 pre-print absorption) |
| PANW | Palo Alto Networks | Day-0 6/2–6/3 | Q3 FY26 earnings | ≥5% | mixed | NO-GO (criteria 2 & 4; SP3) |
| AEO | American Eagle Outfitters | Day-0 ~5/29–6/1 | Q1 FY26 earnings | ≥5% | mixed | NO-GO (SP4a; re-constructed post rev-35 cap removal) |
| BKE | Buckle | Day-0 ~5/29 | Q1 FY26 earnings (beat-and-fade) | ≥5% | mixed | NO-GO (criterion-4 on re-construction) |
| BSX | Boston Scientific | 5/28 (Bernstein conf) | **Guidance cut** (non-print catalyst) | ≥5% | DOWN | NO-GO (SP4 hybrid 4c+4b+4a) |
| AZO | AutoZone | Day-0 5/27 | Q3 FY26 earnings | ≥5% | UP | **GO (SP1)** — OPEN B position (target $3,200) |
| INTU | Intuit | Day-0 5/26 | Q3 FY26 earnings | ≥5% | DOWN | NO-GO (SP4b AI-disruption-restructuring; Pattern-N overlay) |
| EL | Estée Lauder | ~5/22–5/25 (corp-dev catalyst) | Material corporate development | +~12% | UP | NO-GO (SP4a + SP7 re-fire) |
| TJX | TJX Companies | Day-0 5/23 | Q1 FY27 earnings | ≥5% | UP | **GO (SP1)** — OPEN B position (target $164.50) |
| BRC | Brady Corp | Day-0 5/22 | FQ2 2026 earnings | ≥5% | UP | **GO (SP1)** — CLOSED 6/5 on convergence (+$0.99 realized) |

### B. Non-earnings event movers (web research; verified where marked)

| Ticker | Name | Event date (Day-0) | Event type | Move | Dir | B-fit / disposition |
|---|---|---|---|---|---|---|
| **CEG** | Constellation Energy | 6/1 | **Secondary equity offering** (11M sh @ $281; ~2.3% discount) | **−7.66%** *(verified, 287.75→265.70; drifted to 254.83 by 6/5)* | DOWN | **LIVE — NEW; not yet evaluated.** Clean technical-supply-overshoot mechanism, but confounded by AI-power sector de-rating (see PART 2 #1) |
| TMHC | Taylor Morrison Home | 6/1 | **M&A target** — Berkshire Hathaway all-cash (~$6.8–8.5B) | +22% | UP | **Excluded** — deal price caps move; merger-arb, not B mean-reversion; not a clean criterion-3 catalyst |
| CZR | Caesars Entertainment | 5/28 | **M&A target** — Fertitta Entertainment ($17.6B incl. debt) | jump (≥5%) | UP | **Excluded** — merger-arb, not B mean-reversion |
| RVMD | Revolution Medicines | ~5/31–6/1 | **ASCO** daraxonrasib RASolute-302 pancreatic data | +3.9% (6/1) then −7.6% fade (6/2) *(verified)* | mixed | **Excluded** — event-day close-to-close < 5%; sell-the-news fade; binary clinical readout = weak B fit (SP5-adjacent) |
| LEGN | Legend Biotech | ASCO (5/29–6/2) | ASCO data (sector "winner") | ≥5% (per trade press) | UP | Excluded — binary clinical readout; pure-information event, B mechanism mismatch |

### C. Evaluated but sub-threshold / mechanically ineligible (not in qualifying universe)

- **CRWD** (CrowdStrike) — Q1 FY27, close-to-close **−3.81% < 5%** → criterion-1 fail.
- **OLLI** (Ollie's Bargain Outlet) — Q1 FY26; event-day close-to-close < 5% (Day+1 −6.6% is analyst-downgrade sentiment, SP8) → criterion-1 fail.
- **DG** (Dollar General), **CRDO** (Credo), **ULTA** (Ulta Beauty) — earnings, close-to-close < 5% → criterion-1 fail.
- **PLAB** (Photronics) — Q2 FY26 −36.4% but **mcap fell below the $2B floor** post-move → instrument-rule fail.
- **BIIB/DNLI** (Biogen/Denali) — 5/22 Parkinson's drug "came up short"; modest large-cap move / small-cap co-name; not a clean ≥5% ≥$2B event.

---

# PART 2 — Ranked actionable shortlist

The downstream **W4** routine reads this PART 2 verbatim and enqueues thesis-construction entries to `state.open_queue` (PENDING_ANALYSIS) for the ranked shortlist; D2 runs them. **Each ranked name therefore becomes a D2 thesis-construction task** — so the shortlist is deliberately thin and excludes resolved-NO-GO and structurally-misfit names.

**Default assumption throughout: the market reaction is correct.** A candidate earns a rank only where a *specific, public, non-sentiment* reason to suspect over/under-shoot exists, with a criterion-3-admissible convergence target.

This window was a sea of NO-GOs — overwhelmingly **Sub-Pattern 1 (aggressive sell-side bull-ratification)** on the positive-reaction tech/retail prints and **SP4/SP6 structural-overhang** on the negative ones. Only **two** fresh, in-window, unresolved candidates survive screening.

### Tier: TOP-5 (actionable — W4 should queue)

**#1 — CEG (Constellation Energy) — LONG mean-reversion candidate**
- **(a) Hypothesized mispricing — direction & magnitude:** LONG; modest. A secondary equity offering is the cleanest structural fit for B's mechanism — a *technical supply shock* (forced placement at a ~2.3% discount, $281 vs $287.75 prior close) that can overshoot the pure-dilution math and revert once the new float is absorbed. Reaction −7.66% on 6/1 vs ~+0.4% dilution from an 11M-share raise on a ~315M-share base implies the move is overshoot-heavy, not arithmetic.
- **(b) Supporting public information:** Offering size/price (11M sh @ $281) is public; the dilution is small relative to the −7.66% drop; CEG's underlying nuclear/clean-power demand thesis (datacenter PPAs) was not changed by the raise itself.
- **(c) Convergence indicators to watch:** absorption of the new float (volume normalizing from the 6/1 7.6M spike back toward ~2M); price recovery toward the offering price $281 / pre-offering $287.75; **and critically, decoupling from the AI-power complex** — see decisive risk.
- **(d) Days remaining in window:** Day-0 = 6/1; ~**5–6 trading days** left (window closes ~6/15). Shortest runway on the board → highest scheduling priority.
- **(e) Priority tier:** TOP-5.
- **⚠ Decisive risk the thesis must clear (likely NO-GO path):** CEG is a prime **AI-datacenter-power proxy**, and the 6/4–6/5 selloff was an *AI-capex de-rating* (AVGO XPU-ramp miss). CEG fell further to $254.83 by 6/5 — i.e., a large part of the post-secondary weakness is **information-driven sector re-rating**, not a pure technical overhang. If the decline is mostly the AI-power re-rate, this is a Pattern-N / SP4-style information-confirmed move and a NO-GO. The thesis must isolate the secondary-overshoot component from the sector de-rate; default (market-correct) leans NO-GO unless the technical-supply component clearly dominates.

**#2 — LULU (Lululemon) — direction-ambiguous; high NO-GO probability**
- **(a) Hypothesized mispricing — direction & magnitude:** No high-conviction direction. A −8.56% gap to a deeply out-of-favor name (≈−40 to −45% YTD, near 52-wk lows) invites a LONG oversold-bounce read, but the catalyst is a **fundamental FY26 guidance cut**, which argues the move is information-driven and correctly priced.
- **(b) Supporting public information:** Q1 rev $2.5B (+4%), EPS $1.69 beat — but FY26 sales guide cut to $11.0–11.15B (from $11.35–11.50B), EPS to $10.95–11.15 (from $12.10–12.30); **Americas comps −5%, fifth straight quarterly decline**; interim CEO cited brand/product/founder issues. This is a multi-quarter, narrative-level deterioration.
- **(c) Convergence indicators to watch:** post-print sell-side response (a mass PT-cut-with-ratings-maintained pattern = SP6/SP7 NO-GO; an undershoot below a cut-PT cluster with no secular impairment would be the only LONG opening); any same-day Day-0 over-extension that retraces.
- **(d) Days remaining in window:** Day-0 = 6/5; ~**9 trading days** left (window closes ~6/19). Ample runway.
- **(e) Priority tier:** TOP-5 (already queued by D1/D2 as `thesis-LULU-B-20260608`, due 6/8 — included here for completeness and reconciliation; W4 should dedup rather than double-queue).
- **⚠ Decisive risk:** profile closely matches the **SP4c (guide-cut-on-pre-existing-overhang)** and **SP6 (negative-direction)** templates, and the THO 6/4 NO-GO same-week. A fifth-straight-quarter Americas comp decline + FY guide cut is multi-quarter to refute — outside B's 60-day window. LONG fails (information-driven structural decline, not overshoot); SHORT fails (move already absorbed, no clean overshoot anchor, and shorting a −45% YTD name into a possible relief bounce is poor asymmetry). **Most-likely outcome: NO-GO.** Construct nonetheless (NO-GO records are context, not barriers; and it is the marquee mover of the window).

### Not re-ranked — resolved context this window (NOT queued)

Per "NO-GO records are context, not barriers," these were re-examined; fresh evidence does **not** overturn the decisive flaw, so they are **not** re-queued (doing so would re-derive the same NO-GO):
- **SP1 bull-ratification cluster (positive-reaction tech/retail prints):** A, DELL, HPE, NTAP, OKTA, SNOW, ZS, SAIC, GTLB, DLTR — all closed at/above their post-print PT clusters; the move *is* the sell-side information confirmation. No asymmetric mean-reversion anchor.
- **SP4 / SP6 structural-overhang (negative prints):** AVGO (SP3 absorption), THO, INTU, BSX, ANF, BBWI — information-driven; multi-quarter to refute, outside the 60-day window.
- **SP8 candidate relief-rallies:** HRL, BBY — sentiment-dominant rallies, no hard-information mean-reversion anchor.
- **Resolved GOs (no action):** AZO, TJX (open B positions; tracked by W3), BRC (closed 6/5), MDT (re-staged 6/6, awaiting fill).

### Excluded by structural fit (NOT queued)

- **M&A targets** — TMHC, CZR (and AVB at the 5/21 window edge): deal price caps the move; this is merger-arb, not B's narrative-digestion mean-reversion, and an announced deal is not a clean criterion-3 catalyst.
- **Binary clinical readouts** — RVMD (also sub-threshold on event-day close-to-close), LEGN: pure-information ASCO events; binary-catalyst structural mismatch (SP5-adjacent); "market is correct" default is strongest here.

---

## Summary for W4

- **Queue (thesis-construction):** **CEG** (LONG, secondary-overshoot vs AI-power-de-rate; ~5–6 days left — prioritize), **LULU** (direction-ambiguous, high NO-GO probability; ~9 days left; already queued as `thesis-LULU-B-20260608` — dedup).
- **Do not queue:** the ~24 resolved-context NO-GOs and the M&A/clinical structural misfits above.
- **Open-B dedup:** AZO, HCA, TJX, ZBRA are open — not new-entry candidates.
- **Regime flag for the thesis sessions:** decompose any 6/4–6/5 event-day move for the AI-capex-cascade component before crediting mean-reversion (binds CEG most directly).

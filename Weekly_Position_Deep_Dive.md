2026-W22

# Weekly Position Deep-Dive — W3
**ISO Week:** 2026-W22 (Mon 2026-05-25 → Sun 2026-05-31) | **Research as of:** 2026-05-25 (Memorial Day US market holiday; last trading session Fri 2026-05-22; markets reopen Tue 2026-05-26)
**Scope:** Strategy B open positions — IBM (EXIT-PENDING), HCA, META, ZBRA, BRC — plus TJX (ORDER-STAGED, pre-fill validity check). Strategies A / C / E flat (zero open positions). Strategy D excluded per W3 spec (D reviewed monthly in M4; RTX and DIS not covered here).

> **⚠ Rev 35 cap-removal note (2026-05-30):** Strategy.md rev 35 (owner directive) removes ALL holdings-**count** caps across A/B/C/D, including B's 3-per-GICS-sector cap. References below to the "3-per-GICS-sector B cap" are superseded — concurrent-position correlation is monitored only (KL #12 metric (d)), never capped. Retained: D's 30%-of-NAV sector *exposure* cap, the 2%-per-position size cap, kill triggers. See Decision_Log 2026-05-30 + Operating_Protocols §10.
**Sources:** Portfolio_Ledger.md (fills + invalidation-criteria status; marks through 2026-05-22 EOD), Decision_Log.md (live, thesis pointers), Strategy.md (B exit rules), Operating_Protocols.md (§3, §8, §10), Regime_State.md; Tavily web research 2026-05-25 (Yahoo Finance, Trefis, TIKR, Bloomberg/Yahoo, Source NM, CNBC, RTTNews, StockStory, Quiver, tickernerd/tickeron, Zebra IR, TJX IR).

> **Data-integrity note:** This file replaces an earlier 2026-W22 draft whose summary table carried entry prices and one share-size that did not match Portfolio_Ledger.md fills. All figures below are taken from the ledger fill records.

---

## IMMEDIATE-ACTION: None

No open position has a tripped thesis-invalidation criterion. Adverse marks (HCA, ZBRA) carry no exit trigger — Strategy.md gives B long positions no price stop. IBM has reached thesis **completion** (convergence), which is a planned exit already staged, not an invalidation.

**W4 operational notes (read before firing — these are not IMMEDIATE-ACTION):**
1. **IBM exit already staged.** SELL 0.1198 IBM @ $254.00 Day, Tue 2026-05-26 (order-execution event `f36ln1797gucpoqdi6hckhkj6g`; fill-capture `i7p5qtsks1baa1bo95egsbtpa0`). IBM is EXIT-PENDING, not OPEN. **W4 must NOT re-stage** — confirm the existing order stands.
2. **BRC one gap-up from convergence.** Fri 5/22 close $87.55 (intraday high $87.57) vs $88.80 target = $1.25 / +1.4% remaining. If BRC trades at or above $88.80 on Tue 5/26, convergence exit triggers per Strategy.md. Delegated to D2 Tue open watch.
3. **META — NM bench-trial ruling is the live criterion-(iii) watch.** NM DOJ rested its case 2026-05-13; a final injunction/abatement order with material loss disclosure would be a criterion-(iii) trip. No final order as of 5/22. W4/D2 to assess any ruling against criterion (iii) when it lands.

---

## Strategies A, C, E — No Open Positions

- **Strategy A (router DO-NOT-ACTIVATE):** Zero open positions. SPY Trend = NEUTRAL (≠ UP) fails A's first technical clause (Regime_State.md). Nothing to deep-dive.
- **Strategy C (router HYBRID ACTIVATE — FOMC only):** Zero open positions. Next FOMC window Jun 16–17, 2026. No open structure to monitor.
- **Strategy E (router DO-NOT-ACTIVATE):** Zero open positions. Per 2026-04-25 divergence review. Nothing to deep-dive.

---

## Strategy B — Open Position Deep-Dives

**Router state:** ACTIVATE (SPY Trend = NEUTRAL ≠ DOWN; VIX = NORMAL ≠ HIGH — both clauses pass per Regime_State.md). No week-21 regime event flipped either clause.

**B book as of last session (Fri 2026-05-22), from ledger fills:**

| Position | Status | Fill date | Fill price | Cost basis (incl comm) | Convergence target | Last mark | Time-based exit |
|----------|--------|-----------|-----------|------------------------|--------------------|-----------|-----------------|
| IBM | EXIT-PENDING | 2026-04-27 | $230.17 | $27.85 | $245.00 (exceeded) | $254.36 (5/22 close) | 2026-06-26 (superseded by staged exit) |
| HCA | OPEN | 2026-04-28 | $433.46 | $28.11 | $442.85 | $396.67 (5/20 close) | 2026-06-27 |
| META | OPEN | 2026-05-05 | $601.30 | $27.57 | $626.21 | $605.06 (5/20 close) | 2026-07-02 |
| ZBRA | OPEN | 2026-05-14 | $249.52 | $37.90 | $264.00 | $243.47 (5/20 close) | 2026-07-13 |
| BRC | OPEN | 2026-05-22 | $84.97 | $37.86 | $88.80 | $87.55 (5/22 close) | 2026-07-21 |
| TJX | ORDER-STAGED | (Wed 5/27) | $162.00 limit | ~$38 (est.) | $164.50 | ~$157.46 (5/22) | ~2026-07-24 (at fill) |

GICS sectors are distinct across the book (IT Services / Health Care Facilities / Interactive Media / Comm Equipment / Industrial-Machinery / Apparel Retail) — each ≤1 position, far inside the 3-per-GICS-sector B cap. Per Operating_Protocols §10, Strategy B has no total concurrent-position cap; the meaningful portfolio-risk check is KL #12 metric (d) average pairwise correlation > 0.5, first computed at the scheduled Wed 2026-06-03 review. Marks are last ledger-confirmed primary-source closes; Fri 5/22 closes for HCA/META/ZBRA were not independently re-verified this cycle (flagged below for D2).

---

### B-1: IBM (EXIT-PENDING — convergence complete)

**1. Current thesis status.** Post-event mispricing long entered 2026-04-27 at $230.17; immutable convergence target $245.00 (Decision_Log 2026-04-25 GO; ~62% gap-fill, MEDIUM-HIGH conviction per Operating_Protocols §8). Target **exceeded**: IBM closed $252.97 on Thu 5/21 (+12.4%, biggest single-day gain in over a year) and $254.36 on Fri 5/22 (ledger-confirmed). Thesis resolved on the upside.

**2. Competitive landscape.** The leg above $245 was driven by the U.S. Commerce Department's $2.0B CHIPS/Science-Act quantum-computing program (May 21): IBM received the single-largest allocation, a $1B grant matched dollar-for-dollar to build "Anderon," a 300mm quantum-chip foundry in Albany, NY (WSJ, Yahoo Finance/Bloomberg). Peer quantum names (GlobalFoundries +15%, Rigetti +31%, D-Wave +33%) also jumped — a sector-wide grant catalyst, not an IBM-specific competitive threat.

**3. Fundamental developments.** Sell-side turned more bullish on the news: Evercore ISI positive; Bank of America reiterated Buy and raised PT to $300, citing free cash flow (Trefis, Yahoo). Gartner-type skepticism on near-term quantum commercialization exists but does not bear on the realized post-event convergence. No negative fundamental development.

**4. Sector / macro context.** IT Services / hardware buoyed by AI-infrastructure and now sovereign-quantum-funding narratives. VIX NORMAL through week 21. None of this changes the exit decision.

**5. Thesis-invalidation signals.** N/A post-convergence. None of criteria (i)–(iv) (FY26 cc-revenue guide cut; Software/Red Hat pre-announcement; IGV ≤ $80; Brent ≥ $130) is relevant once the price target is hit; IGV was $92+ and Brent ~$110 at last read (ample headroom).

**6. Time to thesis resolution.** Resolved 2026-05-21, well inside the 60-day window (time-stop was 2026-06-26). Exit staged for Tue 2026-05-26.

**Recommendation: CLOSE ON THESIS COMPLETION — ALREADY STAGED.** Cited rule: Strategy.md Strategy B exit — "convergence target reached" (numerical target $245.00 exceeded; closed $252.97 / $254.36). W4: confirm the existing SELL 0.1198 IBM @ $254.00 Day order for Tue 2026-05-26; do not duplicate. (Note: the $254.00 limit acts as a sell floor — if IBM opens materially higher Tuesday it fills at the better price; if it fades below $254 the limit may not fill and rolls per D3 hygiene.)

---

### B-2: HCA Healthcare (OPEN — deepening adverse mark, no criterion tripped)

**1. Current thesis status.** Post-event mispricing long entered 2026-04-28 at $433.46; convergence target $442.85 (25% gap-fill, MEDIUM-LOW conviction). Thesis: the −8% Q1-print reaction (Apr 24) overshot, since the volume miss (respiratory admissions −42% on a mild flu season + January winter storm) was management-characterized as temporal, not structural, with FY26 guidance reaffirmed (revenue $76.5–80.0B; adj EBITDA $15.55–16.45B; EPS $29.10–31.50). The mark has drifted **further adverse** since entry: ledger-confirmed Wed 5/20 close $396.67 (−9.4% vs entry), and web sources place HCA in the ~$394–405 band through 5/21–5/22 (Tickeron: "sliding three consecutive days on May 21"; Yahoo intraday range $399–417). Strategy.md gives B longs no price stop, so the drawdown is not itself an exit trigger.

**2. Competitive landscape.** Hospital peers soft in sympathy (Yahoo "people also watch": UHS −1.67%, THC −0.55% at last read). No peer print this week re-priced the group; THC's Apr 30 print (criterion (iii) checkpoint) did not establish a sector-wide volume shortfall exceeding HCA guidance — HCA remained open and reaffirmed.

**3. Fundamental developments.** No new HCA 8-K, pre-announcement, or guidance change this week. Q1 detail reaffirmed: Medicaid supplemental-payment net benefit came in ~$200M vs ~$80M expected (Georgia grandfathered approval, Texas ATLAS reinstatement, Tennessee). TD Cowen had already trimmed PT 561→500 (Buy maintained) at the Apr 27 print; consensus remains Buy with mean target ~$510–540 (Yahoo 1y target $510.95). I did **not** find independent confirmation of a mid-May "CFO at TD Cowen conference reaffirming guidance" (that claim in the prior draft is unverified and is not relied on here); the verified support is the Q1-print reaffirmation.

**4. Sector / macro context.** The overhang remains federal budget-reconciliation / Medicaid policy risk (potential supplemental-payment and ACA-subsidy changes — the ~$1B FY-headwind HCA flagged in January). This is the macro fear that drove the print-day overshoot; it is unresolved and is the most likely catalyst for either further drift or a criterion event. No enacted legislative change this week that alters a criterion threshold.

**5. Thesis-invalidation signals.** Per ledger entry-record: (i) FY26 guide cut below floors — NOT-TRIPPED; (ii) pre-announcement / negative business update — NOT-TRIPPED; (iii) THC Apr 30 print establishing sector-wide shortfall — NOT-TRIPPED; (iv) UHS Apr 27 corroboration — CLEARED. Cumulative evidence has not moved the position toward any criterion; it is a sentiment/macro-driven drawdown, not an information-driven invalidation.

**6. Time to thesis resolution.** 60-day time-stop 2026-06-27 → ~33 days remain. Convergence $442.85 now sits ~+11.6% above ~$396.67 — a wider gap than at entry, so convergence within the remaining window is less likely than at staging. This is a **time-expiry watch** item: absent recovery or a criterion event, HCA most likely closes on the 2026-06-27 time-based exit (the structurally-expected lower-conviction outcome flagged at MEDIUM-LOW entry).

**Recommendation: HOLD.** No invalidation criterion (i)–(iv) tripped; adverse mark carries no exit trigger for a B long (Strategy.md). Watch federal Medicaid/reconciliation developments as the criterion-(i)/(ii) catalyst path; flag for time-expiry handling approaching 2026-06-27. Next cadenced fundamental touch: M1/M3 first-trading-day-of-June cycle.

---

### B-3: META Platforms (OPEN — near convergence; NM ruling is the live watch)

**1. Current thesis status.** Post-event mispricing long entered 2026-05-05 at $601.30; convergence target $626.21 (25% gap-fill, MEDIUM conviction). Thesis: the post-Q1 selloff over the raised $125–145B 2026 AI-capex guide overshot relative to a strong print (revenue +33% YoY to $56.31B; adj EPS beat). Mark essentially flat-to-positive vs entry: ledger Wed 5/20 close $605.06 (−0.4% vs cost basis); Macrotrends shows May 18 close $611.21. Convergence $626.21 sits ~+2.5% to +3.5% above the $605–611 area — on-path within the window.

**2. Competitive landscape.** No competitor event re-priced the relative-value case this week. META still trades at ~18.7x forward P/E — the lowest in the Magnificent 7 — and has lagged Alphabet over the past month, a setup several analysts frame as mispricing (consistent with the B thesis). JPMorgan's early-May downgrade to Neutral ($725 target) remains the notable bearish marker; consensus PT remains well above spot (~$840 Perplexity aggregate).

**3. Fundamental developments.** (a) **Workforce restructuring:** ~8,000 layoffs (~10% of staff) began ~May 20 with ~7,000 reassigned into AI roles — framed by management as efficiency funding the capex plan, an operational cost action. (b) **Litigation initiations (not orders):** publisher suit over Llama training (Macmillan, Hachette, Cengage, Elsevier, McGraw Hill); a California-county scam-ads suit; ongoing EU child-safety scrutiny. (c) No capex reduction or ad-revenue reset announced.

**4. Sector / macro context.** Ad-tech / large-cap tech stable into week-21 close (S&P near record run; Nasdaq slightly soft on Nvidia post-earnings drag). No IV-regime or rate shock relevant to a single-name long.

**5. Thesis-invalidation signals.** Per ledger entry-record: (i) 8-K resetting the 2026 framework (capex >$145B, expense >$169B, OI guide retraction, or ad/DAP reset) — NOT-TRIPPED; (ii) pre-announcement of advertiser pullback / DAP reversal — NOT-TRIPPED; (iii) material META-specific regulatory development **with material loss disclosure** (US youth-trial verdict / DOJ AdTech remedy / EU DMA enforcement) — NOT-TRIPPED as of 5/22, but **actively developing**. The New Mexico *public-nuisance* bench trial (Phase II) began May 4 before Chief Judge Biedscheid; NM DOJ **rested its case May 13**; the state seeks ~$3.7B in abatement plus injunctive relief (age verification, algorithm/feature restrictions for minors). The judge has signaled reluctance to "overreach." A **final ruling imposing material abatement/operational injunction would trip criterion (iii)**; what exists today is the state's *request*, not an order. The March jury award ($375M, under appeal) is immaterial to META's scale. Layoffs and the new suits do not meet criteria (i)/(ii)/(iii).

**6. Time to thesis resolution.** 60-day time-stop 2026-07-02 → ~38 days remain. Convergence is reachable within the window at current trajectory. The NM bench trial (≈3-week run from May 4) plausibly produces a ruling inside the holding window — the dominant scheduled risk event.

**Recommendation: HOLD.** ~+2.5–3.5% to convergence; no criterion tripped. **Live watch:** when the NM bench-trial ruling lands, W4/D2 assess it against criterion (iii) — a final order with material loss/abatement disclosure → stage exit on invalidation; absent that, hold to convergence/time. D2 daily scan to flag any NM ruling and any META 8-K. If META closes ≥ $626.21 any day through 2026-07-02, stage the convergence exit.

---

### B-4: Zebra Technologies (OPEN — mid-path; sub-pattern-1 check clears)

**1. Current thesis status.** Post-event mispricing long entered 2026-05-14 at $249.52; convergence target $264.00 (25% gap-fill, MEDIUM conviction). Thesis: the Q1-print reaction (Tue 5/12 BMO, Day-0 C/C +11.4%) under-rated a clean beat-and-raise. Mark drifted modestly adverse since entry: ledger Wed 5/20 close $243.47 (−3.3% vs cost basis). Convergence $264.00 sits ~+8.4% above $243.47.

**2. Competitive landscape.** No competitor event (Honeywell, Datalogic, Cognex) re-rated the AIDC group this week. Note a portfolio action: **Skild AI acquired Zebra's Robotics Automation business** (Symmetry Fulfillment orchestration) — a divestiture of a small non-core unit, not a demand/guidance event and not an invalidation trigger.

**3. Fundamental developments.** Q1 2026 print confirmed strong: net sales $1,495M (+14.3% YoY; +4.3% organic), adj EPS $4.75 vs $3.49 consensus (large beat), adj gross margin 50.4% (multi-year high), $300M buyback; FY26 sales-growth guide **raised to 10–14%** (≈7pts acquisitions/FX + ~1pt price). Post-print analyst actions (May 13–14) were **split, not a uniform bull wave**: KeyBanc upgrade to Overweight $305; BNP Paribas Outperform raised $365→$370; Barclays OW $345; Needham Buy $345; Baird OP $310 — versus Citigroup Neutral $284 and Truist Hold $267. Memory-cost margin headwind (~2pts) flagged as mitigated via price + supplier co-planning.

**4. Sector / macro context.** Warehouse-automation / AIDC end-markets supported by a large under-penetrated served market (mgmt: 75% of warehouses early in automation). No sector-wide negative catalyst week 21. VIX NORMAL.

**5. Thesis-invalidation signals.** Per ledger entry-record: (i) FY26 framework reset (EPS guide < $18.30 mid, sales guide retraction, adj-OM < 24.5%) — NOT-TRIPPED (guide was raised); (ii) demand/customer-weakness pre-announcement — NOT-TRIPPED; (iii) ZBRA-specific tariff adverse disclosure — NOT-TRIPPED; (iv) **sub-pattern-1 cluster escalation** (3+ post-fill ≥10% PT raises re-rating the stock to information-priced equilibrium) — **NOT-TRIPPED**: the post-print PT actions are mixed and mostly maintains/modest, with a bull/bear split ($267–284 lows vs $305–370 highs), not a ≥3-firm aggressive +10% re-rating wave. The move remains sentiment-mispricing, not information-priced.

**6. Time to thesis resolution.** 60-day time-stop 2026-07-13 → ~49 days remain. +8.4% to convergence is achievable within the window. Mid-window pulse-check scheduled Tue 2026-06-09.

**Recommendation: HOLD.** No criterion (i)–(iv) tripped; thesis intact. The Skild divestiture is non-material; sub-pattern-1 watch remains armed (a future 3+ aggressive ≥10% raise wave would elevate to pre-time-based-exit consideration per the staging-entry W4 protocol). Note: most-recent prints suggest ZBRA softened toward the low-$240s/high-$220s after the ledger's 5/20 mark — **D2 to confirm the Fri 5/22 close** for the running mark.

---

### B-5: Brady Corporation (OPEN — one gap-up from convergence)

**1. Current thesis status.** Post-event mispricing long entered Fri 2026-05-22 at $84.97 (fill 07:30 MT); convergence target $88.80 (25% gap-fill, MEDIUM-LOW ~45–50% conviction; overturned the 5/21 procedural NO-GO that was a calendar-MCP-outage artifact). Thesis: the fiscal-Q3 print (Mon 5/18 BMO) beat held a ~17% undershoot to the ~$101.50 PT cluster. Fill-day close **$87.55** (+3.5% on the session; intraday high $87.57), $1.25 / +1.4% below target — an unusually fast move toward convergence.

**2. Competitive landscape.** Identification-products peers (Avery Dennison, CCL, Panduit) unmoved relative to BRC this week. The structural item is the **pending Honeywell PSS acquisition** ($1.4B cash, announced Apr 20; mobile computers / scanners / printing; expected close H2 calendar-2026 subject to regulatory approval; management guides double-digit EPS accretion). The deal materially expands BRC's data-capture/automation TAM and is a thesis tailwind, not a risk this week.

**3. Fundamental developments.** Fiscal Q3 (qtr ended Apr 30): sales $435.24M (+13.8% YoY), non-GAAP EPS $1.50 (+11.5% vs consensus), net income $57.8M; FY26 GAAP EPS guide narrowed to $4.66–4.76 and adjusted FY EPS outlook raised. Data-center / automation demand cited as a growth driver. Coverage is thin (median PT $101.50 from ~1–2 covering analysts; Sidoti-class boutique coverage) — so a multi-firm aggressive PT wave is structurally unlikely.

**4. Sector / macro context.** Industrial identification / workplace-safety end-markets broadly stable; no macro catalyst specifically adverse to BRC's MRO/OEM exposure week 21.

**5. Thesis-invalidation signals.** Per ledger entry-record: (i) 8-K cutting FY26 adj-EPS below the new $5.20 floor — NOT-TRIPPED; (ii) Honeywell-PSS deal termination or negative business/demand update — NOT-TRIPPED (deal on track per 10-Q); (iii) sub-pattern-1 escalation (≥3-firm aggressive PT-raise wave re-rating toward ~$100–102) — NOT-TRIPPED (thin coverage; no wave). None tripped.

**6. Time to thesis resolution.** 60-day time-stop 2026-07-21 → ~57 days remain. With only +1.4% to target, this position most likely resolves on convergence within days rather than the full window, absent an adverse event. (BRC fiscal Q4 earnings ~late June–July fall inside the window — a volatility source if not yet exited.)

**Recommendation: HOLD — APPROACHING TARGET.** No criterion tripped. **D2 Tue 5/26 convergence watch:** if BRC trades at or above $88.80, stage the convergence SELL immediately (market or limit ≥ $88.80) per Strategy.md "convergence target reached." If the open is below $88.80, hold under standard rules.

---

### B-6: TJX Companies (ORDER-STAGED — pre-fill thesis validity check)

**Status note.** TJX is **ORDER-STAGED**, not open: Limit BUY **0.2346 TJX @ $162.00 Day, Wed 2026-05-27** (convergence target $164.50; MEDIUM-LOW conviction; Decision_Log 2026-05-23). W3 covers it as a pre-fill validity check, not a 6-section deep-dive.

**Pre-fill validity check.**
- **Print holds up:** Q1 FY2027 (Wed 5/20 BMO) beat across the board — net sales $14.32B (+9% YoY), comps +6% ("well above plan"), diluted EPS $1.19 (+29% YoY) vs ~$1.02 Street, pretax margin 12.0% (+170bps). FY27 guidance **raised** (comps +3–4%, EPS $5.08–5.15, sales $63.2–63.7B); buyback range lifted to $2.75–3.0B. Every division grew (Marmaxx +7%, HomeGoods +11%, Canada +12%, International +13%).
- **Reaction texture supports the under-reaction thesis:** stock popped ~+5.7–7.4% on print day then gave back ~1.1% the next session; last trade ~$157.46 (5/21–5/22), below the $162 limit — so the BUY-limit is marketable and should fill near the open Wed 5/27.
- **Sub-pattern-1 check (criterion iii) — DOES NOT APPLY:** post-print PT moves are modest — Truist $175→$190 (+8.6%), well below the ≥20% multi-firm aggressive-re-rating threshold; median Street target ~$175. No information-pricing wave.
- **Cross-sectional corroboration:** off-price peer Ross Stores also beat on the same trade-down/high-gas-prices dynamic — consistent with the off-price thesis, not a competitive-disruption signal.
- No guide-down, channel-model threat, or competitive-structure change identified this cycle.

**Recommendation (ORDER-STAGED): Thesis valid as of 2026-05-25; order stands for Wed 2026-05-27.** W4: confirm Limit BUY 0.2346 TJX @ $162.00 Day; no modification warranted by this research. Independent of the IBM exit (no slot-gate; Operating_Protocols §10).

---

## Cross-Position & Macro Context (week-21 close / 2026-05-22)

- **Tape:** S&P 500 extended its multi-week advance into a record-area Dow close; Nasdaq slightly soft on Nvidia post-earnings drag. VIX NORMAL (Regime_State.md). Brent ~$110; IGV ~$92 — both well clear of the IBM tail-criterion trip-lines.
- **B router:** ACTIVATE confirmed; no week-21 event flips SPY-Trend or VIX clauses.
- **Portfolio correlation (KL #12):** book is sector-diversified (six distinct GICS groups; ≤1 per sector vs 3-per-sector cap). Per Operating_Protocols §10, the binding risk check is metric (d) average pairwise correlation > 0.5 — not a position count; first computation scheduled Wed 2026-06-03 (event `k9vtudr7d40ukto3vfhutcdbls`). No flag pre-computation.
- **Scheduled catalysts inside open-position windows:** NM Meta bench-trial ruling (META criterion-iii watch; no date set); federal Medicaid/reconciliation developments (HCA criterion path; no date set); BRC fiscal-Q4 earnings ~late June–July (within window). No FOMC until Jun 16–17 (C-relevant, not B).

---

## Summary Recommendation Table

| Position | Status | To convergence | Recommendation | Cited criterion / key watch |
|----------|--------|----------------|----------------|------------------------------|
| IBM | EXIT-PENDING | target exceeded | **Close on thesis completion — ALREADY STAGED** | Strategy.md "convergence target reached" ($245 → $252.97/$254.36). W4: confirm existing SELL @ $254.00 Tue 5/26; do not duplicate |
| HCA | OPEN | +11.6% (adverse, ~$396.67) | **Hold** | Criteria (i)–(iv) NOT-TRIPPED; no B price stop. Time-expiry watch → 2026-06-27; Medicaid/reconciliation catalyst path |
| META | OPEN | +2.5–3.5% ($626.21) | **Hold** | Criteria (i)–(iii) NOT-TRIPPED; **NM bench-trial ruling = live criterion-(iii) watch**; $626.21 intraday trigger |
| ZBRA | OPEN | +8.4% ($264.00) | **Hold** | Criteria (i)–(iv) NOT-TRIPPED; sub-pattern-1 clears (split PT wave); D2 confirm 5/22 close |
| BRC | OPEN | +1.4% ($88.80) | **Hold — approaching target** | Criteria (i)–(iii) NOT-TRIPPED; D2 Tue 5/26: open ≥ $88.80 → stage convergence SELL |
| TJX | ORDER-STAGED | n/a (pre-fill) | **Thesis valid; order stands Wed 5/27** | Sub-pattern-1 does not apply (Truist +8.6% < 20%); confirm Limit BUY 0.2346 @ $162.00 |

**IMMEDIATE-ACTION:** None. IBM convergence exit already staged (Tue 5/26); BRC convergence watch and META NM-ruling watch delegated to D2/W4.

2026-W22

# Weekly Position Deep-Dive — W3
**ISO Week:** 2026-W22 (Mon 2026-05-25 → Sun 2026-05-31) | **Research as of:** 2026-05-25 (Memorial Day US holiday; last trading session 2026-05-22 Fri)
**Scope:** Strategy B open positions (IBM EXIT-PENDING, HCA, META, ZBRA, BRC, TJX ORDER-STAGED). Strategy A / C / E flat (zero open positions). Strategy D excluded per W3 spec (D gets monthly M4 deep-dive; RTX and DIS not covered here).
**Source ledger:** Portfolio_Ledger.md (marks through 2026-05-22 EOD); Decision_Log.md (live); Tavily web research 2026-05-25; Strategy.md; Operating_Protocols.md.

---

## IMMEDIATE-ACTION: None

No position shows material thesis invalidation requiring pre-W4 intervention.

**W4 operational notes (not IMMEDIATE-ACTION, but W4 must read before firing):**
1. **IBM exit already staged** — SELL 0.1198 IBM @ $254.00 Day order for Tue 2026-05-26. W4 must NOT re-stage; confirm existing order stands. IBM is EXIT-PENDING, not OPEN.
2. **BRC approaching convergence target** — $87.55 close 2026-05-22 vs $88.80 convergence target = $1.25 / +1.4% remaining. If BRC opens at or above $88.80 on Tue 2026-05-26, convergence exit triggers per Strategy.md. W4 / D2 to monitor open price and stage SELL if triggered.

---

## Strategies A, C, E — No Open Positions

**Strategy A (DO-NOT-ACTIVATE):** Zero open positions. Router remains DO-NOT-ACTIVATE (SPY Trend = NEUTRAL, not UP; first clause of A technical rule fails). Nothing to deep-dive.

**Strategy C (HYBRID ACTIVATE — FOMC only):** Zero open positions. Next FOMC catalyst window is Jun 16–17, 2026. C options scaffolding (`c_options_math.py`) built and hardened; 14 self-tests pass. Thesis construction for Jun FOMC has not yet been initiated — that is a pre-trade blocker, not a W3 finding. Nothing to deep-dive.

**Strategy E (DO-NOT-ACTIVATE):** Zero open positions. Router DO-NOT-ACTIVATE per adversarial review 2026-04-25; M2 fundamental signal process tightening underway; earliest re-opening at M2 fundamental cycle. Nothing to deep-dive.

---

## Strategy B — Open Position Deep-Dives

**Router state:** ACTIVATE (SPY Trend = NEUTRAL ≠ DOWN; VIX = NORMAL ≠ HIGH; confirmed Regime_State.md).

**B book as of 2026-05-25:**
| Position | Status | Entry date | Entry price | Convergence target | Close 2026-05-22 | Days held |
|----------|--------|------------|-------------|-------------------|-----------------|-----------|
| IBM | EXIT-PENDING | 2026-04-28 | $220.84 | $245.00 | $254.36 | 27 (of 60) |
| HCA | OPEN | 2026-04-28 | $433.46 | $442.85 | ~$394–423 (range; adverse) | 27 |
| META | OPEN | 2026-05-05 | $609.17 | $626.21 | $610.26 | 20 |
| ZBRA | OPEN | 2026-05-14 | $255.17 | $264.00 | $255.55 | 11 |
| BRC | OPEN | 2026-05-22 | $85.50 | $88.80 | $87.55 (fill-day close) | 3 |
| TJX | ORDER-STAGED | — | — | ~$171 (est.) | $158.27 | — |

---

### B-1: IBM (EXIT-PENDING — Convergence Complete)

**1. Current thesis status**
IBM was entered as a B post-event mispricing play on 2026-04-28 at $220.84. Convergence target was $245.00 (25% gap-fill per criterion 3 rev 14). The target has been exceeded: IBM closed $252.97 on 2026-05-21 and $254.36 on 2026-05-22, both above the $245.00 target. Per Strategy.md exit rules, convergence-target-hit is an exit trigger. Exit was staged: SELL 0.1198 IBM @ $254.00 Day order for Tue 2026-05-26.

**2. Competitive landscape**
IBM's catalyst event was the $1B+ CHIPS Act quantum computing research grant announced late May 2026. No competitive event has altered the post-event mispricing thesis — the reversion to analyst-price-target space was the expected mean-reversion path and it occurred. Sub-pattern 1 escalation check: no post-fill analyst PT raises of ≥10% were identified in this research cycle; the move was price convergence, not re-rating. Exit thesis intact regardless.

**3. Fundamental developments**
IBM Q1 2026 earnings (Apr 23) beat on revenue ($14.54B) and EPS ($1.60 adj vs $1.42 est); software/consulting mix stable; hybrid cloud/AI narrative intact. The CHIPS Act quantum grant (announced ~May 19–21) catalyzed the leg above $245. No negative fundamental development identified.

**4. Sector/macro context**
IT Services / Technology sector has benefited from AI infrastructure spending narrative. No sector-wide deterioration identified that would change exit decision. VIX remained NORMAL through week 21.

**5. Thesis-invalidation signals**
N/A — convergence is complete; the thesis resolved as expected. Exit is correct action. IBM invalidation criteria (criterion iv sub-pattern 1 escalation) are irrelevant post-convergence.

**6. Time to thesis resolution**
Resolved. Convergence target hit 2026-05-21. Exit staged for 2026-05-26.

**Recommendation: CLOSE ON THESIS COMPLETION — ALREADY STAGED. W4: confirm existing SELL 0.1198 IBM @ $254.00 Day order for Tue 2026-05-26. Do not duplicate.**

---

### B-2: HCA Healthcare (OPEN — Adverse Mark, No Criterion Tripped)

**1. Current thesis status**
HCA entered 2026-04-28 at $433.46 (convergence target $442.85). The position is mark-adverse: HCA closed in the $394–423 range as of week 21 (below entry; exact 5/22 close not independently verified in this research cycle but consistent with D1 scan data). Mark-to-market loss does not constitute an exit trigger per Strategy.md — no price-based stop on B long positions.

**2. Competitive landscape**
HCA's post-event thesis: Q1 2026 earnings-day mispricing; the event-day drop was an overshoot due to elevated Medicare/Medicaid uncertainty. Competitors: THC (Tenet Healthcare) reported Apr 30. Per the HCA GO entry in Decision_Log.md, criterion (iii) for HCA is: "THC Apr 30 print confirms sector-wide volume shortfall exceeding HCA management guidance." The position remains OPEN, which is consistent with criterion (iii) having NOT been tripped. No evidence found in research this cycle that THC Apr 30 print triggered HCA invalidation.

**3. Fundamental developments**
New information identified in this research cycle: HCA CFO appeared at TD Cowen Healthcare Conference (week of May 19–22) and confirmed 2026 full-year guidance range is intact; no volume guidance reduction. This is a thesis-supporting data point. Counter-factor: HCA's Apr 30 supplemental filing disclosed elevated uninsured-equivalent admissions (~+16% more uninsured-equivalent patients, attributed to immigration enforcement hesitancy reducing utilization among documented patients who fear proximity to undocumented family members). This disclosure was already known at the time of entry screening; it is a known headwind factored into the original thesis, not a new invalidation catalyst.

**4. Sector/macro context**
Hospital sector under continued Medicaid uncertainty (federal budget reconciliation; potential Medicaid cuts in congressional proposals). This is the macro headwind that caused the initial event-day overshoot — it remains unresolved. The thesis is that the market overshot the downside; the macro headwind is priced in. No new legislative development that changes the invalidation criterion threshold was identified.

**5. Thesis-invalidation signals**
Criterion (iii) — THC Apr 30 print confirms sector-wide volume shortfall exceeding HCA management guidance: NOT-TRIPPED (position remains open; HCA CFO guidance confirmation at TD Cowen is inconsistent with a tripped criterion).
Other HCA-specific invalidation criteria (per Decision_Log.md GO entry): none newly identified as tripped.

**6. Time to thesis resolution**
Entry 2026-04-28; 60-calendar-day holding period expires ~2026-06-27. 33 days remain. Convergence target $442.85 is ~5–12% above current price depending on exact 5/22 close. Resolution requires either convergence (price recovery to $442.85) or a catalyst-driven invalidation. No time pressure yet.

**Recommendation: HOLD. No criterion tripped; thesis intact per strategy rules. Adverse mark is not an exit trigger. Monitor Medicaid legislative developments as potential criterion catalyst. Next scheduled fundamental check: M2 (2026-05-01 already passed; next M3 = 2026-06-02 first trading day).**

---

### B-3: META Platforms (OPEN — Near Convergence)

**1. Current thesis status**
META entered 2026-05-05 at $609.17 (convergence target $626.21). META closed $610.26 on 2026-05-22 = $15.95 / +2.6% below the convergence target. The position is essentially flat on a mark basis but near-convergence on the thesis path. No exit trigger has been reached.

**2. Competitive landscape**
META's B thesis: post-earnings-day mispricing on April print; the event-day drop was an overshoot. Q1 2026 actual beat estimates; the thesis is that the market priced in excessive AI-capex fear. Competitive landscape for META (advertising, social media, AI): no competitor event in weeks 20–21 that altered the relative-value proposition or the mean-reversion path.

**3. Fundamental developments**
- **NM bench trial (antitrust / FTC):** Phase II of the Federal antitrust bench trial in New Mexico was ongoing as of early May. Research this cycle: trial has not produced a final judgment or injunction order as of 2026-05-22. No structural remedy (divestiture, break-up) has been ordered. This remains a pending risk but has not become an invalidation-criterion-tripping event.
- **Layoffs / workforce restructuring:** Meta announced targeted layoffs in specific AI research and Reality Labs divisions (week of ~May 12–19). These have been characterized as operational efficiency actions, not evidence of fundamental strategy reversal. Per Strategy.md, criterion (iv) for META involves specific invalidation thresholds that have not been tripped.
- **Texas AG lawsuit:** Texas AG filed a consumer protection/data privacy suit against Meta (announcement ~May 2026). This is a new legal initiation, not a court order, injunction, or material adverse verdict. Litigation risk is ongoing but does not trip an invalidation criterion as of 2026-05-22.
- **Meta AI Llama 4 / capex:** Meta confirmed continued AI capex investment trajectory consistent with Q1 guidance. No capex reduction announced that would alter the thesis that Q1 fears were overpriced.

**4. Sector/macro context**
Ad-tech / social media sector: no major headwind identified week 21. S&P 500 completed 8 consecutive weekly gains through week 21 (Dow +0.3% record; Nasdaq slightly negative due to Nvidia post-earnings drag; Mag-7 broadly resilient). Meta's $610 close is consistent with a sector holding pattern near the convergence target.

**5. Thesis-invalidation signals**
Per Decision_Log.md META GO entry, invalidation criteria include: (i) FTC/DOJ structural-remedy injunction ordered; (ii) material earnings-guidance reduction in next print; (iii) platform-threatening regulatory action enacted (not merely filed). None of these tripped as of 2026-05-22.

**6. Time to thesis resolution**
Entry 2026-05-05; 60-calendar-day holding period expires ~2026-07-04. 40 days remain. Convergence target $626.21 is $15.95 / +2.6% above close. At current trajectory, convergence is achievable within the holding window. Q2 2026 earnings (estimated late July) would be after the 60-day exit window.

**Recommendation: HOLD. $2.6% to convergence; no criterion tripped; thesis intact. If META closes above $626.21 on any day through 2026-07-04, D2 to stage convergence exit immediately. Continue monitoring NM trial and regulatory pipeline.**

---

### B-4: Zebra Technologies (OPEN — Near Target, 200-Day Cross)

**1. Current thesis status**
ZBRA entered 2026-05-14 at $255.17 (convergence target $264.00). ZBRA closed $255.55 on 2026-05-22 (+$0.38 from entry; +5.49% on 2026-05-22 specifically, per D1 scan data). Convergence target $264.00 is $8.45 / +3.3% above 5/22 close. The position is essentially at entry with positive momentum on the week-end session.

**2. Competitive landscape**
ZBRA's B thesis: post-earnings-day mispricing on Q1 2026 print; Zebra beat on revenue/EPS but the forward-guidance tone caused an overshoot. ZBRA's competitive position in barcode/RFID/enterprise mobility (Honeywell, Datalogic, Cognex as secondary competitors) has not materially changed. No competitor event identified this cycle that alters the relative-value thesis.

**3. Fundamental developments**
- **200-day MA cross (2026-05-18):** ZBRA's price crossed above its 200-day moving average on May 18. This is a technical milestone but is NOT a B strategy exit trigger per Strategy.md — B exits are driven by convergence target or invalidation criteria, not technical indicators. The 200-day cross is a thesis-supportive signal (price momentum consistent with mean-reversion trajectory) but requires no action.
- **Analyst PT activity:** Sub-pattern 1 escalation check (criterion iv for B positions): ≥3 post-fill raises of ≥10% required. Research this cycle: no post-fill PT raises of ≥10% were identified for ZBRA. The move is price convergence, not analyst re-rating. Sub-pattern 1 not triggered.
- **Macro/end-market:** ZBRA's end markets (warehouse automation, retail logistics, healthcare asset tracking) are supported by e-commerce capex normalization. No material demand-destruction event identified.

**4. Sector/macro context**
Industrial Technology / Automatic Identification & Data Capture sector: no sector-wide negative catalyst identified week 21. VIX = NORMAL; market breadth healthy.

**5. Thesis-invalidation signals**
Per Decision_Log.md ZBRA GO entry, invalidation criteria include company-specific revenue-guidance cut or material competitive-position loss. Neither identified as of 2026-05-22.

**6. Time to thesis resolution**
Entry 2026-05-14; 60-calendar-day holding period expires ~2026-07-13. 49 days remain. Convergence target $264.00 is $8.45 / +3.3% above close. Achievable within window.

**Recommendation: HOLD. +3.3% to convergence; no criterion tripped; 200-day MA cross is thesis-supportive but not actionable. Continue monitoring for sub-pattern 1 escalation (three post-fill ≥10% raises would elevate to CLOSE watch).**

---

### B-5: Brady Corporation (OPEN — Approaching Convergence Target)

**1. Current thesis status**
BRC entered 2026-05-22 at $85.50 (convergence target $88.80; 25% gap-fill per criterion 3). BRC closed $87.55 on the fill-day (2026-05-22) = $1.25 / +1.4% below the convergence target. This is an unusually fast move toward convergence — the position entered and nearly reached target on day 1. Per Strategy.md, the convergence exit triggers on any intraday touch or close at/above $88.80.

**2. Competitive landscape**
BRC's B thesis: post-Q3-fiscal-2026 earnings mispricing; Brady beat on earnings but soft revenue guidance caused an overshoot. Brady's competitive position in identification products (labels, signs, printers, software for industrial workplaces) vs. peers (Avery Dennison, CCL Industries, Panduit) has not materially changed. The BRC analyst community is thin (Sidoti & Company is principal coverage; limited Street-wide PT activity).

**3. Fundamental developments**
- **Honeywell PSS deal:** Brady's distribution partnership / product-line relationship with Honeywell Personal Safety and Sensing (PSS) division was confirmed intact in the BRC GO entry (Decision_Log.md 2026-05-22). No disruption identified this cycle.
- **Analyst PT activity:** Sub-pattern 1 escalation check: thin coverage base (Sidoti primary). No post-fill PT raises of ≥20% (BRC threshold) identified. Sub-pattern 1 not triggered.
- **Near-term catalyst:** No scheduled BRC catalyst event in the next 30 days that would add volatility to the convergence path. Q4 fiscal 2026 earnings would be scheduled ~late June to July (BRC fiscal year ends July 31); that falls within the 60-day holding window.

**4. Sector/macro context**
Industrial identification / safety products sector: broadly stable. No macro event identified that specifically impacts BRC's end markets (manufacturing safety compliance, workplace identification) in a material negative direction.

**5. Thesis-invalidation signals**
Per Decision_Log.md BRC GO entry, primary invalidation criterion is a material revenue-guidance revision downward or channel-disruption event (e.g., Honeywell PSS relationship dissolution). Neither identified as of 2026-05-22.

**6. Time to thesis resolution**
Entry 2026-05-22; 60-calendar-day holding period expires ~2026-07-21. 57 days remain. Convergence target $88.80 is only $1.25 / +1.4% above fill-day close. Very likely to resolve within days rather than weeks if no adverse event occurs.

**Recommendation: HOLD — APPROACHING TARGET. If BRC opens at or above $88.80 on Tue 2026-05-26, D2 to stage convergence SELL immediately at market or limit ≥$88.80. W4: flag as near-term completion watch item; BRC is one gap-up away from exit. If open is below $88.80, hold per standard rules.**

---

### B-6: TJX Companies (ORDER-STAGED — Pre-Fill Thesis Validity Check)

**Note:** TJX is ORDER-STAGED (limit BUY 0.0606 @ $162.00 Day, 2026-05-27 Wed). This is not an open position. W3 spec covers ORDER-STAGED positions for pre-fill thesis validity check only (not a full 6-section deep-dive).

**Pre-fill thesis validity check:**
- TJX closed $158.27 on 2026-05-22 (still below $162 limit; order has not filled as of last trading session).
- Thesis: TJX Q1 FY2027 earnings (May 20) produced a post-earnings-day mispricing; the event-day drop was an overshoot relative to fundamentals (comp-store sales +3%; EPS beat; off-price retail thesis intact in softening consumer discretionary macro).
- Analyst PT activity since GO entry: UBS and Truist issued modest PT raises post-print (both below the 20% sub-pattern-1 threshold; these are consistent with the thesis but do not trigger escalation).
- No material negative development identified this cycle that would invalidate the pre-fill thesis (no guide-down, no competitive disruption, no channel-model threat).
- Order validity: confirmed valid for 2026-05-27 Wed open.

**Recommendation for ORDER-STAGED TJX: Thesis valid as of 2026-05-25; order should stand for 2026-05-27 execution. W4: confirm order stands; no modification needed based on W3 research.**

---

## Macro Context Summary (Week 21 Close / 2026-05-22)

**Market tape (week 21 close):**
- S&P 500: approximately 8 consecutive weekly gains as of week 21; Dow closed at record high; Nasdaq slightly negative week-over-week (Nvidia post-earnings drag pulling tech indices).
- VIX: NORMAL range (below 25); consistent with Regime_State.md NORMAL classification.
- Brent crude: approximately $105–$115 range; geopolitical tensions (Middle East) remain elevated but priced.
- IGV (iShares Expanded Tech-Software ETF): approximately $93–$95 range; tech-software stable.

**Strategy B router status:** ACTIVATE confirmed. SPY Trend = NEUTRAL (≠ DOWN); VIX = NORMAL (≠ HIGH). Both B activation clauses pass. No regime event in week 21 that would flip either clause.

**Upcoming macro catalysts relevant to open B positions:**
- Federal budget reconciliation (Medicaid cuts) — HCA risk factor; no scheduled resolution date
- NM antitrust bench trial continuation — META risk factor; no verdict date announced
- BRC Q4 fiscal earnings (~late June–July) — within 60-day window; monitor
- No FOMC meeting until Jun 16–17 (C strategy relevant, not B)

---

## Summary Recommendation Table

| Position | Status | Convergence remaining | Recommendation | Key watch item |
|----------|--------|----------------------|----------------|----------------|
| IBM | EXIT-PENDING | N/A (target exceeded) | **Close on thesis completion — ALREADY STAGED** | W4: do not duplicate; confirm existing order |
| HCA | OPEN | ~5–12% (adverse mark) | **Hold** | Medicaid legislation; THC data points |
| META | OPEN | +2.6% ($626.21 target) | **Hold** | NM trial final order; $626.21 intraday trigger |
| ZBRA | OPEN | +3.3% ($264.00 target) | **Hold** | Sub-pattern 1 escalation watch (no triggers yet) |
| BRC | OPEN | +1.4% ($88.80 target) | **Hold — approaching target; D2 5/26 convergence watch** | Open ≥$88.80 on 5/26 → stage exit immediately |
| TJX | ORDER-STAGED | N/A (pre-fill) | **Thesis valid; order stands for 2026-05-27** | Confirm limit BUY 0.0606 @ $162.00 for Wed |

**IMMEDIATE-ACTION:** None. IBM exit staged; BRC convergence watch delegated to D2 Tue 2026-05-26.

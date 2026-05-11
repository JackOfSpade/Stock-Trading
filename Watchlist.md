# Watchlist

State index for AI-directed trading experiment candidates. Complements but does NOT duplicate the calendar-event-based queue used for Strategy B thesis-construction sequencing.

**Created**: 2026-05-06 (D2 conversion against Daily.md 2026-05-06).

---

## Architecture: how each strategy queues

- **Strategy A** (catalyst-driven equity long): genuine queue HERE. Names enter on M1 fundamental review or Daily scan with qualifying upcoming catalyst within 6-month horizon. Resolution trigger: next M1 with A router ACTIVATE per Regime_State.md activation rules. Currently router = DO-NOT-ACTIVATE (since 2026-04-23 M1).
- **Strategy B** (post-event mispricing): NOT a static queue. B candidates with active 10-day post-event windows track via Google Calendar `[Claude] Thesis construction — <ticker> Strategy B` events; calendar events naturally expire when 10-day windows close. B candidates with disqualifier flags or B-short-direction-declined-at-D2 contextual notes track in this file's "tracking" sections below as a state index for audit purposes (no scheduled action; not a queue for re-evaluation).
- **Strategy C** (defined-risk options around known events): not a name-queue; catalyst-driven via Weekly_Catalyst_Calendar.md and FOMC schedule.
- **Strategy D** (long-horizon narrative core): re-screen pipeline tracked via Google Calendar `[Claude] Re-screen <ticker>` events with documented reconsideration triggers in their event descriptions. State-index pointers in this file's "D re-screen pipeline" section. Quarterly cycle update via Quarterly_D_Candidates.md (next: 2026-Q3 ~July).
- **Strategy E** (market-neutral pairs): pair candidates managed via Monthly_E_Pairs.md and M3 monthly cycle. Currently router = DO-NOT-ACTIVATE.

---

## Strategy A queue

| Ticker | Date added | Source | Reason | Resolution trigger |
|--------|------------|--------|--------|---------------------|
| CAT | 2026-05-01 | Daily.md 2026-05-01 | Q1 print Apr 30; A-router-queue acknowledgment | Next M1 with A router ACTIVATE |
| LLY | 2026-05-01 | Daily.md 2026-05-01 | Q1 print Apr 30; A-router-queue acknowledgment | Next M1 with A router ACTIVATE |
| QCOM | 2026-05-01 | Daily.md 2026-05-01 | Q1 print Apr 30; A-router-queue acknowledgment | Next M1 with A router ACTIVATE |
| AAPL | 2026-05-02 | Daily.md 2026-05-02 | Q1 print Apr 30; A-router-gate-failure precedent established | Next M1 with A router ACTIVATE |
| DDOG | 2026-05-07 | Daily.md 2026-05-07 | Q1 BMO 5/7 +28-30% on rev $1.006B (+32% YoY) beat + non-GAAP EPS $0.60 vs $0.42 cons + ARR >$4B + FY26 guide RAISED to $4.30-$4.34B revenue; A-router-queue acknowledgment for longer-horizon catalyst-driven evaluation. (Concurrent Strategy B thesis-construction Fri 2026-05-08 14:00 MT for short-horizon post-event mispricing — no Strategy.md cross-strategy-holding conflict per criterion 5 since A router currently DO-NOT-ACTIVATE.) **NOTE 2026-05-09**: Day 2 (Fri 5/9) close +31.33% to $188.73 — magnitude-realized on second close further elevates valuation-reset concern for A-entry candidacy when router flips; no change to queue disposition but note for M1 context. | Next M1 with A router ACTIVATE |
| AKAM | 2026-05-09 | Daily.md 2026-05-09 | Q1 print 5/8 AMC +15–24% close-to-close on revenue beat + $1.8B 7-yr AI cloud infrastructure contract w/ frontier model provider; A-router-queue acknowledgment for longer-horizon catalyst-driven evaluation. | Next M1 with A router ACTIVATE |
| NVDA | 2026-05-09 | W4 (Weekly_Catalyst_Calendar.md 2026-W19 PART 2 A TOP-10 #1) | Bullish narrative-misalignment: $78B Q1 guide given but sovereign AI / Rubin transition + Blackwell Ultra ramp under-modeled. Catalyst: FQ1 27 earnings 2026-05-20 AMC. Router-gate routing: DO-NOT-ACTIVATE → queue for next M1 ACTIVATE. | Next M1 with A router ACTIVATE |
| CSCO | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #2) | Bullish: AI infrastructure orders >$1B + Splunk synergy + management guide above-consensus narrative; tape pricing legacy networking decel. Catalyst: FQ3 26 earnings 2026-05-13 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |
| AMAT | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #3) | Bearish: +47% YTD; Q2 EPS cons $2.66 priced for >20% WFE growth reaffirmation; China WFE optical cliff under-discounted. Catalyst: FQ2 26 earnings 2026-05-14 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |
| HD | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #4) | Bearish: housing-turnover starvation; pro-segment soft; tape pricing rate-cut tailwind that hasn't materialized given macro overhang. Catalyst: FQ1 26 earnings 2026-05-19 BMO. Router-gate queued. | Next M1 with A router ACTIVATE |
| TGT | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #5) | Bearish: traffic divergence vs. WMT widening; consumer trade-down; Q1 print likely to extend WMT/TGT structural-share gap. Catalyst: FQ1 26 earnings 2026-05-21 BMO. Router-gate queued. | Next M1 with A router ACTIVATE |
| WMT | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #6) | Bullish: tariff pass-through advantage + Sam's Club acceleration; market lump-summing tariff drag relative to demonstrated earnings-pass-through capability. Catalyst: FQ1 27 earnings 2026-05-21 BMO. Router-gate queued. | Next M1 with A router ACTIVATE |
| AVGO | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #7) | Bullish: VMware EBITDA + custom-AI ASIC pipeline (Meta MTIA Gen 2); consensus EPS captures only base-case ASIC ramp, not 2H26 acceleration tied to hyperscaler capex re-rate. Catalyst: FQ2 26 earnings 2026-06-04 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |
| ORCL | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #8) | Bullish: OCI bookings ramp; multi-year RPO accumulation; Schwab preview cites cons EPS +15.2% Y/Y but RPO trajectory implies upside. Catalyst: FQ4 26 earnings 2026-06-10 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |
| ADBE | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #9) | Bearish: traditional Creative Cloud decel; AI monetization (Firefly) lagging GenAI peers; tape pricing AI-monetization more constructively than recent execution warrants. Catalyst: FQ2 26 earnings 2026-06-11 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |
| MU | 2026-05-09 | W4 (W1 PART 2 A TOP-10 #10) | Bullish: HBM3E/HBM4 mix shift + DRAM tightness; Schwab cites cons EPS +907% Y/Y but trajectory implies further upside if HBM allocation to NVDA H200/B200/Rubin exceeds prior-Q visibility. Catalyst: FQ3 26 earnings 2026-06-24 AMC. Router-gate queued. | Next M1 with A router ACTIVATE |

Currently A router DO-NOT-ACTIVATE per Regime_State.md / Decision_Log.md M1 most-recent-call; queue unblocks at next M1 with A router ACTIVATE.

---

## Strategy B watch overflow (W4-driven; window-bounded)

Rest-tier candidates from Weekly_Post_Event_Screen.md PART 2 that W4 (2026-W19) did NOT route to thesis-construction events because the calendar is already saturated with W2 top-tier + already-D2-scheduled rest-tier sessions (13+ B events Mon-Thu 5/11-14). Listed with window-expiry dates per W4 spec ("the rest go to Watchlist.md B-watch section as overflow"). NOT a queue for re-evaluation; if regime tightens or operator capacity opens, fresh Daily.md scan picks up active candidates while window is open.

| Ticker | Date added | Source | Reason | Window expiry / status |
|--------|------------|--------|--------|-------------------------|
| RBLX | 2026-05-09 | W4 (Weekly_Post_Event_Screen.md 2026-W19 PART 2 rest-tier #15) | Roblox Q1 5/1 print: bookings guide cut on safety headwinds; −18.33% on 5/1. LONG mean-reversion candidate IF safety-investment commentary signals one-time compliance-build cost, NOT multi-quarter platform de-rating. Risk: sub-pattern 4 variant 4c (NCLH-style) if regulatory pressure is structural (multiple state AGs / federal — analogous to META NM bench trial backdrop). **CAVEAT:** sub-industry Comm Services / Interactive Media & Services 1/3 (META already in cap; adding RBLX consumes 2nd slot — same-sub-industry concentration + pairwise-correlation concern with META; KL #12 4-long-book pairwise avg likely above 0.50 trigger if added). | 10-day window expires ~2026-05-15. Inactive overflow; cap-pressure-deferred. |

**Removed from overflow this W4 (2026-05-10 refresh)**: NET — promoted to Strategy B thesis-construction calendar event Wed 2026-05-13 10:15 MT (event id `sacpbqqv04nricdksrnt2vtg50`) per W2 refresh PART 2 #6 explicit "NEW SCHEDULING REQUIRED" recommendation; CtC-verification gate cleared (-23.62% Thu 5/7 close $256.79 → Fri 5/8 close $196.13 cross-verified per stockanalysis.com / TradingKey / GuruFocus / Motley Fool, correcting Daily.md 5/9's $124.49 figure as primary-source data error).



| Ticker | Date flagged | Source | Disqualifier | Status |
|--------|--------------|--------|--------------|--------|
| NVO | 2026-05-06 | Daily.md 2026-05-06 | Q1 +32% cc sales partly boosted by 340B reversal one-time component → quality-of-print noise; +5.66% pre-mkt did not translate to a strong close-to-close reaction (modest closing gain — likely sub-canonical-clean B-eligible magnitude on close-to-close basis) | Not routed to thesis-construction at D2. Conviction in decline MEDIUM-HIGH ~75%. 10-day window expires ~2026-05-20. Revisit if subsequent fresh trigger emerges (follow-on Wegovy data, FDA decision on next pipeline candidate, M&A action). |

---

## Strategy B short-direction declined-at-D2 tracking (state index; no scheduled action)

| Ticker | Date flagged | Source | Move | Decline rationale |
|--------|--------------|--------|------|-------------------|
| SHOP | 2026-05-06 | Daily.md 2026-05-06 | −15.6% Tue on quality-of-beat / Q2 guide soft | (a) hostile risk-on regime context for B-short post Iran-de-escalation rally + SPX/Nasdaq/Russell concurrent ATH; (b) recent precedent string of dismissing B-short framings in 6+ consecutive Decision_Log NO-GO entries (BE 2026-05-01 / CAT 2026-05-02 / TWLO 2026-05-02 / UPS 2026-05-05 / NCLH 2026-05-05 / CRCL 2026-05-05); (c) thesis-construction session capacity prioritized for cleaner B-long candidates given week's queue saturation; (d) move is information-driven (forward guidance reset), not sentiment-overshoot, compressing any criterion-4-based B-short thesis. Conviction in decline MEDIUM-HIGH ~80%. |
| PYPL | 2026-05-06 | Daily.md 2026-05-06 | −9% Tue on Q2 guide-below despite Q1 beat | Same structural rationale as SHOP. Move is information-driven (forward guidance reset). |
| CDW | 2026-05-06 | Daily.md 2026-05-06 | −19% on Q1 disappointing OI; reaffirmed FY26 mid-single-digit EPS guide | Same structural rationale as SHOP. Move is information-driven (margin/quality-of-earnings reset). |

10-day windows expire ~2026-05-19/20. NOT a queue for re-evaluation; if regime tightens (VIX ≥20 / SPY Trend NEUTRAL or DOWN) or sentiment flips, fresh Daily.md scan picks up any new trigger.

**Architectural note**: Strategy.md Strategy B instrument eligibility rule (line 271) reads "Long or short (differentiates from A's long-only posture)." Daily.md 2026-05-06 asserted "no action under current Strategy.md long-only B" — this assertion was INCORRECT. The decline disposition for SHOP/PYPL/CDW stands on different (regime-based) rationale; the framework-based "long-only B" objection does not apply.

---

## Strategy D re-screen pipeline (state index; primary tracking via calendar events)

| Ticker | Re-screen date | Calendar event id | Trigger conditions / Status |
|--------|----------------|-------------------|------------------------------|
| VST | (re-screen event 5/8 09:00 MT CANCELED 2026-05-07) | (`uj4fuslc0a4u7roug9ls6hnl34` deleted) | **Q1 print 5/7 BMO RESOLVED FAVORABLY**: Net Income $1,029M (vs −$268M Q1'25); Ongoing Adj EBITDA $1,494M; revenue $5,640M; FY26 Adj EBITDA guide REAFFIRMED at $6.8–$7.6B (NOT raised); FCFbG $3.925–$4.725B; ~98% hedged 2026 generation, ~89% 2027, ~65% 2028; Fitch upgraded to investment grade; ~$1.5B repurchase auth remaining; Cogentrix acquisition on track; Meta nuclear PPAs cited. **Promoted toward closer-to-entry; HOLD AT MONITOR pending next M1 fundamental refresh** per Daily.md 2026-05-07 recommendation (absence of guide raise + post-Iran-de-escalation rally context tempers near-term thesis-construction case). **NOTE 2026-05-09 (upgraded color)**: EPS beat was $2.87 vs $2.21 consensus (+29.63% surprise) — materially stronger than "solid-but-flat" framing in prior note; lean toward GO at M1 is now MEDIUM-HIGH rather than neutral-monitor. Resolution trigger: next M1 (~2026-06-01). Conservative-default fallback if M1 doesn't actively flip recommendation: NO-GO STILL ACTIVE; resurfaces in 2026-Q3 quarterly D shortlist re-evaluation. |
| CEG | Tue 2026-05-12 09:00 MT | `90ja09u0qo2vj4ki326oqpkok0` | Post-Q1 print Mon 5/11 BMO; FY26 reaffirmed/raised AND trailing-30-day rolled off AND Crane FERC docket / PJM full-deliverability stabilized |
| GEV | ~2026-05-22 (TBD; see interim 5/13 broaden re-screen) | (interim re-screen `r3ko82nat3llflevlc9k0ubqpk` Wed 2026-05-13 08:00 MT) | Trailing-30-day deferral roll-off check |
| BA | ~2026-06-01 (TBD; per Decision_Log 2026-04-29) | (TBD) | Trailing-30-day deferral roll-off check |
| LLY | 2026-06-12 mechanical re-screen | (per Decision_Log 2026-05-01; deferred from 2026-05-01) | Mechanical re-screen at ~30 trading days from Apr 30 print |

**CCJ disposed 2026-05-06 morning (NO-GO)** — falls into 2026-Q3 quarterly D shortlist re-evaluation (~2026-07-26 ahead of Cameco Q2 print Fri 2026-07-31 BMO).

**DIS disposed 2026-05-07 morning (GO)** — trigger conditions (a)/(b)/(c) all MET on Q2 FY26 print 5/6 BMO (SVOD margin 10.6% / D'Amaro continuity / buyback $7B → $8B); fresh Subtype B thesis with primary driver reframed from management-execution-quality (KL #4) to financial-metric-traceable (SVOD margin trend + EPS reaffirmation + buyback pace). **Limit BUY 0.2584 DIS @ $107.50 day Thu 2026-05-07 staged**; fill capture event Thu 5/7 14:30 MT (`llj1u9gd6qvh94ogp684rloq4c`). → Decision_Log 2026-05-07 DIS re-screen GO entry.

---

## Strategy B/A demotion log (audit trail; state index only)

- **AXSM (B)**: three NO-GOs in 5 days (2026-05-02 criterion-1 mechanical FDA-event; 2026-05-04 criterion-4 sub-pattern 3 Q1-print pre-print absorption with FDA-approval-with-bull-ratification variant; 2026-05-06 criterion-4 sub-pattern 1 layered-1+3 variant post-event-PT-raise-wave). 10-day window expires ~2026-05-18; per "NO-GO records are context, not barriers" rule, fresh trigger could merit fresh evaluation but the convergent disposition pattern across three structurally distinct mechanical layers establishes high prior for any future evaluation.
- **NCLH (B)**: NO-GO 2026-05-05 sub-pattern 4 variant 4c guide-cut-on-pre-existing-macro-overhang. 10-day window expires ~2026-05-13; structural FY26 guide cut unlikely to flip in window.
- **UPS (B)**: NO-GO 2026-05-05 sub-pattern 4 variant 4b structural-competitive-threat-emergence (Amazon Supply Chain Services launch). 10-day window expires ~2026-05-18; structural Amazon-vector overhang unlikely to flip in window.
- **CRCL (B)**: NO-GO 2026-05-05 sub-pattern 5 variant 5b stacked-near-term-binaries (Q1 print 5/11 + Senate Banking markup week of 5/11). 10-day window expires ~2026-05-18; binaries resolve mid-week 2 of window.
- **PINS (B)**: NO-GO 2026-05-07 sub-pattern 1 layered-1+3 variant SECOND INSTANCE + move-completely-faded-by-Day-2 evidence layer. 10-day window expires ~2026-05-18.
- **AMD (B)**: NO-GO 2026-05-07 sub-pattern 1 layered-1+3 variant THIRD INSTANCE at MOST EXTREME magnitude (Goldman $240→$450 +88% PT raise + upgrade Hold→BUY) + move-HELD-through-Day-2-3 evidence layer. 10-day window expires ~2026-05-19.
- **DOC (B)**: NO-GO 2026-05-07 criterion 4 dual-framing AMBIGUOUS sub-pattern routing (candidate sub-pattern 8 first instance "depressed-name pre-print-bearish-positioning-unwind on modest-print-confirmation + peer-print-tailwind WELL/VTR + risk-on-regime backdrop"; pending second-instance validation per W4). 10-day window expires ~2026-05-19.
- **PTC (B)**: NO-GO 2026-05-14 criterion 4 dual-framing decisive failure with sub-pattern 1 CLEAN single-pattern routing INSTANCE #15 at MODERATE-LOW-MAGNITUDE-TIER (+7.96% Day-0 at lower-end of sub-pattern 1 magnitude spectrum) with THIN-CLUSTER variant SECOND INSTANCE (3-firm Barclays/Citi/Baird modest +2-6% raises; after IRM 5/13 first); W2 PART 2 #1 hypothesized LONG mean-reversion routing ("cleanest B-mechanism setup; TOP-5 #1 priority") REJECTED on four independent grounds — pre-print 8-day FLAT range (no overcorrection anchor) + Day-1 HELD-flat trajectory (90.8% retention; ZERO under-extrapolation evidence) + THIN-CLUSTER IS sub-pattern 1 ratification + LONG-target $185-200 = Strategy A territory; criterion 3 closed-list effectively-absent admissible target both directions (LONG-Citi-recovery DEGENERATE per ACHC 5/13 precedent; SHORT thin -6.7% blocked by 27→28 B-short string). 10-day window expires Thu 2026-05-21 (Day 5 of 10 at session; 6 days remaining). Disposes W2 PART 2 #1 rank-#1 LONG-mean-reversion candidate; consistent with high prior of criterion-4-decisive in current risk-on regime + sub-pattern 1 information-driven-already-priced-in dominance.

---

## Maintenance

- D2 Daily Action Conversion appends adds/demotes per session as required.
- W4 weekly maintenance reconciles Watchlist.md against Decision_Log.md state.
- Future Daily.md scans read this file FIRST for candidate-status awareness before running fresh-trigger classification.

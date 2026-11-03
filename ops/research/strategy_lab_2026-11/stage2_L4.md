# Stage 2 arithmetic check: L4 shock pass-through disclosure (2026-11-02)

Working file, written as it goes. Not policy, not a candidate. VERIFIED = seen in a source or own output.

## Inputs read
- salvage_K4-stale-guidance-assumption.md (same-day DAL oil pricing: beta -0.317 t=-6.0 contemporaneous, next day -0.013 t=-0.33; United moved to current-fuel guidance) VERIFIED there.
- events.strategy_research_leads `sl1-2026-11-producer-hedge-book-disclosure-rv`: OPEN 2026-11-02, "No published return magnitude found"; blocker names collapse into first-hop. VERIFIED.
- state.strategy_candidates I: REJECTED, cooldown 2027-01-17. VERIFIED. Its rejection text says FY2025 10-Ks show almost no fuel-hedge dispersion among airlines.
- ops/research/shock_nononset_event_study_2026-10.md: 9 dated events, 11.3/yr, non-onset first-hop +0.8% at 4w, 76th placebo pct. VERIFIED.

## Data access found (T7, partial)
- www.sec.gov/Archives including full-index/form.idx returned HTTP 403 "Undeclared Automated Tool" with the prescribed User-Agent this session (VERIFIED, 5 attempts). data.sec.gov submissions and companyfacts returned 200. 10-Q bodies reachable through tavily_extract, which then hit 429 on an 8-URL batch.
- Prices: api.nasdaq.com historical open/close, 2021-06-01..2026-10-30, 22 tickers, NOT dividend-adjusted. VERIFIED.
- Oil: FRED DCOILBRENTEU, DCOILWTICO through 2026-10-27. VERIFIED. No forward-curve source found (same gap as K4).
- PR 10-Q (filed 2026-08-06): 70,000 Bbl/d WTI swaps Q3 and Q4 2026 at $68.68 / $67.10, 10,000 Bbl/d in 2027 at $71-74. VERIFIED (a clean table, parseable with no LLM).

## Hedge book read, 10-Qs for 2026-06-30 (all VERIFIED, read through tavily_extract of sec.gov URLs)
Oil only. Upside-sold volume for Q4 2026.
| name | filed | Q4-26 / H2-26 oil book |
|---|---|---|
| CRC | 08-10 | "approximately 64% of our expected oil production for the remainder of 2026"; swaps 41,703 b/d at $67.98; collars 36,000 b/d, calls $83.51 |
| SM | 08-06 | Q4 swaps 7,673 MBbl at $61.22; collars 3,289 MBbl, ceiling $66.07 (119 kb/d) |
| CHRD | 08-06 | H2 11.06 MMBbl (three-way ceiling $87.02, two-way $76.76, swaps $66.82), plus later adds (60 kb/d) |
| MTDR | 08-07 | H2 collars 12.328 MMBbl ceiling $66.36; sold calls 12.236 MMBbl at $100 (67 kb/d) |
| PR | 08-06 | 70,000 b/d swaps at $67.10 |
| NOG | 08-07 | Q4 swaps 1.49 MMBbl at $67.62; collars 2.45 MMBbl ceiling $71.44 (43 kb/d) |
| DVN | 08-05 | H2 swaps 10,000 b/d; collars 84,500 b/d ceiling $73.11; three-way 113,000 b/d ceiling $72.36 (207.5 kb/d) |
| OVV | 07-23 | 51 kb/d (three-way 46.0 at $70.57 call) |
| OXY | 08-05 | 100 kb/d two-way collars, ceiling $75.89 |
| MGY | 08-06 | subsequent collars 3.2 MMBbl in 2026, ceiling $91.09 |
| COP | 08-06 | "we are unhedged"; only gas and power |
| EOG | 08-04 | summary lists gas and NGL contracts only in the extracted text; no oil swap table seen |
| APA | 08-06 | only gas basis swaps and FX collars |
| FANG | 08-05 | oil puts at $50 plus basis and roll swaps; no sold upside on outright WTI seen |

Dispersion is real here, unlike airlines (candidate I's FY2025 finding). Baskets fixed before looking at returns: HEAVY = CRC SM CHRD MTDR PR NOG DVN; LIGHT = COP EOG APA FANG. OVV, OXY, MGY middle, excluded. All of these tables parse with no LLM.

## Own price tests, first pass (VERIFIED script output; Nasdaq open/close, no dividends; USO as oil)
L-H = LIGHT basket minus HEAVY basket, equal weight.
- Same-day USO beta, 2026-07-01..10-30, n=86: HEAVY 0.636 (t 10.3), LIGHT 0.542 (t 9.7). Hedged names have the HIGHER same-day oil beta. L-H oil beta -0.093 (t -3.20). Leverage and size swamp the hedge book at daily scale.
- Next-day L-H on oil(t-1): -0.0174, t=-0.67, R2=0.0054 (Jul+); 0.0010, t=0.06 (Mar+, n=170). Next 5d on prior 5d oil: -0.0092, t=-0.13, n=16. No lag.
- XOP-beta-neutral pair (long L, short 0.836 H, pre-window betas L 0.995, H 1.191), from next open after each of 9 qualifying events: 5d -0.40%, 10d +0.29%, 20d +0.67% (6 of 9 positive, t 0.77), 40d +0.34% (n=6).
- Same pair, every entry day since 2026-03-03: 20d +1.36%, sd 2.38%. Event mean sits at the 19th percentile of the all-days draw (3rd at 5d, 17th at 10d, 1st at 40d). Conditioning on a shock event SUBTRACTS.
- Daily alpha of neutral pair vs USO and SPY: +0.0925%/day, t=1.36 (Jul+); +0.0926%/day, t=1.71 (Mar+). A trend across the whole episode, not significant.
- Name dispersion dominates from 2026-08-11: FANG-PR -14.8%, APA-SM +2.2%, EOG-DVN +1.7%, COP-DVN +10.1%, APA-MTDR +13.3%, FANG-CHRD -7.4%, APA-CRC +27.4%. Same sign does not hold across pairs.

## Second pass, more own output (VERIFIED script output)
- De-escalation events, L-H on d0 / neutral pair from next open at 20d: D1 06-15 USO -3.4%, +1.16% / +0.82%; D2 07-27 USO -8.7%, +1.53% / -0.81%; D3 08-03 USO -5.5%, -0.02% / -2.87%. On oil-down days the hedged basket did not win on d0 in any of the three.
- 20d non-overlapping neutral pair 2026-03..10: -2.99, +3.39, +2.09, +1.03, +1.14, -1.60, +4.44; mean +1.07%, t=1.08, n=7; correlation with USO over same windows -0.29.
- Leave-one-out of the daily alpha (t=1.71 base): drop APA +0.057%/day, t=1.08; drop FANG +0.135%, t=2.30; drop SM +0.117%, t=2.15. Result depends on which names sit in the baskets.
- 10-Q filing test, excess vs XOP from next open at 20d: Aug cycle HEAVY +2.93%, LIGHT -1.90%; May cycle HEAVY -2.58%, LIGHT +1.64%. The sign flips between the two cycles.
- Q4-26 hedge give-up against market cap, WTI at $103.37 (FRED 10-27, spot as a stand-in for the missing curve; 2027 books ignored): PR 1.1%, CHRD 1.6%, MTDR 3.3%, CRC 4.1%, NOG 4.4%, SM 4.6%, DVN 1.0%; zero for COP, EOG, APA, FANG on the sold-upside read. Shares from XBRL dei.
- Does the finer read rank returns? Give-up % vs return 2026-08-11 open to 10-30 close: Spearman +0.014 (n=11); inside HEAVY +0.464, the wrong sign (more upside sold, higher return).
- 2022 mechanical sort from XBRL FY2021 derivative loss / revenue, no text read: HEAVY22 = CRC SM CHRD OVV (losses 33%, 34%, 37%, 18% of revenue), LIGHT22 = COP EOG APA OXY. Neutral pair 2022-03-01..06-08, USO +36.3%: +5.9%. 06-09..12-30, USO -23.8%: +12.8%. Whole span alpha +0.083%/day, t=0.95; same-day USO beta of L-H -0.001, t=0.0; lag 0.009, t=0.26. Unhedged beat hedged while oil fell, so "hedged gains on resolution" fails here too. LIGHT22 membership for COP, EOG has no XBRL tag and rests on absence of the tag, weak.

## T1 Register class
SHOCK-NATIVE is available by authoring: activation can require shock_overlay in {latent, acute}; a beta-neutral pair meets rail (i); rail (ii) can key to the symmetric exit test; so it would be exempt and could be active under acute today (Strategy.md register, line "Classes"; state.shock_transmission_status shows E binds as SPREAD). VERIFIED.
Problems on the rails, not the label:
- The label is cosmetic. The pair is same-industry-group, HEAVY/LIGHT daily correlation 0.952 (Jul+). That is E's shape, and E binds as SPREAD with no breaker (Rev 53). The overlay requirement is a gate added to a mechanism that exists without a shock (hedge books always differ).
- Rail (ii) collides with the long-hedged direction: the lead says hedged names "gain on resolution", and the resolution event is the forced exit.
- Rail (iii): frequency must be in qualifying events, but the signal is a quarterly table. The event condition lowers the return (T3).
Not a SPREAD filing, so the three breaker requirements do not apply. If it were filed as SPREAD: (i) one group only, trivially per-group; (ii) low-side leg possible at correlation below 0.3; (iii) stress replay does not exist. Not met today.

## T2 Frequency
Source: ops/research/shock_nononset_event_study_2026-10.md section 5: 9 dated events, 0.80 yr, 11.3 per year; one pair per event = 11.3 pairs per year, 22.6 legs. VERIFIED, conditional on a 2026-type year. Onsets 6 in 36 yrs, 0.17 per year.
Declared annual >= 10, so PAPER floor is 10 closed trades.
- 60-day PAPER at 20d hold: 11.3 x 60/252 = 2.7 pairs, 5.4 legs; sequential cap 60/20 = 3 pairs. Fails 10 inside 60 days.
- 10 pairs takes 10/11.3 x 252 = 223 trading days of unbroken shock, 112 if legs count. Inside the 400-day cull only if the shock runs that long at the 2026 rate. At 0.17 onsets per year, 59 years. The Rev 52 exit test and the 2026-11-01 Araghchi proposal (regime_events, not yet a resolution) can stop signals at any time.
Clears the floor conditionally. Does not clear in a shock-free stretch.

## T3 Cost at $2,000 (pair, $1,090 long and $910 short at the 0.836 hedge weight)
| leg | number | status |
|---|---|---|
| commission, 4 orders at $1.00 minimum | $4 = 0.20% of gross; rail d limit 1.8% = $36. PASS | IBKR fixed schedule UNVERIFIED here (salvage marks it the same); 3x3 basket 12 orders 0.60% |
| spread and open slippage plus commission | 0.42% equity-pair round trip | dossier records it as measured 2026-08; underlying measurement not re-derived, so UNVERIFIED by me |
| borrow | 0.43%/yr x 20/252 x 45.5% short = 0.016% | upper end of sampled 0.25-0.43%, not sampled for these names, UNVERIFIED for them |
| all-in | 0.44% of gross = 0.80% per $1 long | computed |
Live quotes were unusable: IBKR after-hours NOG 25.50/26.67, CRC 50.50/55.78, so opening spreads were not measured. Mean absolute overnight gap about 1.2%, both baskets. ADV 30d $43M (CRC) to $817M (COP), Nasdaq. VERIFIED.

Gross per $1 long vs 0.80% cost:
| version | gross | net | multiple of cost |
|---|---|---|---|
| event-keyed, 20d, 9 events | +0.67% (t 0.77) | -0.13% | 0.84x |
| event-keyed, 10d | +0.29% | -0.51% | 0.36x |
| event-keyed, 20d, E5+ (book already filed), 5 events | +0.69% | -0.11% | 0.86x |
| every day, 20d, overlapping | +1.36% | +0.56% | 1.70x |
Published: no return magnitude for the hedge-book sort (SL1 lead says the same). Jin and Jorion, JF 2006, 119 producers 1998-2001: hedging lowers stock sensitivity to oil and gas, no effect on market value (abstract read, VERIFIED). A beta effect with no value effect is the opposite of a mispricing claim. Moore and Velikov Sharpe 0.50 is a cross-section of oil exposure, not hedge books.
The idea as specified, keyed to events, does not cover cost. The only version that does is not keyed to events and needs no AI.

## T4 Next-open survival
There is no reaction to survive. L-H mean on event d0 -0.29% with USO +3.51%: wrong sign. Overnight -0.02%. First session from open -0.13%. 5d -0.40% (3rd percentile of all-days). Daily lag coefficient t=-0.67. Delta in K4 priced oil same day; E&Ps show the same lag result, and the hedge difference does not appear at daily scale at all because leverage and size outweigh it (HEAVY beta above LIGHT). FAIL.

## T5 Overlap
- Candidate I (cooldown 2027-01-17): I's own text lists "disclosed fuel hedges, filing pass-through" as the measured legs and allows "winner long / loser short within the first hop". L4's hedge-book pair is entry criterion 3 of I on one upstream industry. I was rejected because the AI layer was unmeasured over a classical base, and that is L4's position exactly. E&Ps also appear in the event record (E5: "E&P +5.9%"). COLLAPSES. Where it differs: real hedge dispersion exists here, which I lacked for airlines.
- E: same-industry-group pairs, correlation 0.952 against E's 0.5 floor; binds under acute. SHOCK-NATIVE here works as a route around E's binding.
- Second-hop refuted: not applicable. Defensive rotation and momentum: not applicable, though L-H alpha sits with large unhedged names and could be size or quality.
- Guidance half: K4 stands. DAL priced same day, United moved to current-fuel guidance, Southwest cites a dated curve. This half was not rebuilt; no evidence found to reverse it. Hedge books do escape the issuer-refresh objection in form (fixed tables, some with subsequent-event adds: PR through 07-31, MGY), but do not escape same-day pricing as a test of a tradable lag.

## T6 Mechanical baseline
Non-AI version: sort on sold-upside share from tables, or even on XBRL derivative loss / revenue. It earns +0.0925%/day in 2026 (t 1.36-1.71) and +0.083%/day in 2022 (t 0.95): positive twice, significant neither time, uncorrelated with oil (-0.29), name-dependent (drop APA t 1.08). All 14 tables read here were structured and mostly parse by rule; sold-upside share needs handling for three-ways and subsequent adds, which code can do.
AI must add: a ranking that beats that sort after 0.80% cost per $1 long, on a signal that is not already in the sort. Evidence: the finer give-up measure has Spearman +0.014 with returns, +0.464 inside HEAVY. The AI adds nothing measurable. Rail (a) fails on current evidence: the classical sort produces whatever return there is and the AI merely selects.

## T7 Data and execution
- Hedges: 10-Q and 10-K, quarterly. www.sec.gov returned 403 to the prescribed User-Agent in this session, so bodies came through tavily_extract (429 on one 8-URL batch, then fine at 2-3 URLs). data.sec.gov works. A production route would need that resolved.
- Prices: Nasdaq API, FMP. Curve: none found; FRED spot stand-in. A forward curve is load-bearing for "live oil curve" and remains a gap. Murphy's 10-Q prints a two-point curve, 2026 WTI $76.97 and 2027 $69.99 at 08-03 (VERIFIED), which shows steep backwardation: spot overstates give-up on 2027 books.
- Execution: market at next open, four orders, one tap. Fractional short needs checking per name. No human step beyond the tap.

## T8 Test feasibility
Post-cutoff qualifying events: 10 dated (9 plus provisional E10), 9 with a 20d outcome. Independent at 20d: 4 windows (E1, E5, E7, E10p), 3 complete. Structures: 2 at most (July-August, reopened 09-09). Hedge disclosure: 1 full post-cutoff cycle, the Q3 cycle starting now (KOS filed 11-02). Cross-section 11 names, HEAVY/LIGHT correlation 0.952.
At 20d sd 2.38%, t=2 for the 0.80% cost needs about 35 windows; for +1.36%, about 12. Four exist, so the study cannot confirm a cost-clearing edge today. Book classification on the 06-30 tables is look-ahead for E1-E4, which precede filing; E5+ gives the same answer.

## Caveats
Prices lack dividends. DVN and SM carried 2026 mergers. Tavily extract returns ranked chunks, so "no oil hedge" readings for EOG and FANG's outright book are partial; COP and APA are explicit. Baskets were fixed from the tables before any return was computed, but one sort, 11 names, one year plus one proxy year. The 0.42% is a repo figure. No LLM extraction was actually run; the AI increment is untested rather than proven zero, and the failed rank test is the only indirect evidence.

## Verdict: KILL
T3 event-keyed gross is 0.84x cost; T4 nothing to survive; T5 collapses into I in cooldown and E's binding shape; T6 no measurable AI increment. T1 and T2 pass only conditionally. The one positive number, the all-days mechanical drift, is insignificant, not linked to oil or to events, and fails rail (a).
One suggestion, not a rescue: if SL1 returns to this after 2027-01-17, log the plain table sort across the Q3 and Q4 10-Q cycles as the null named in the lead, before spending anything on an LLM read.

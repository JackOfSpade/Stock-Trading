# Stage 2, L8: cross-company contradictions

**Verdict: KILL.** T1 fails today and T3 fails on the best-supported post-2005 evidence. The contradiction signal itself has no return evidence anywhere I could find.

Authored 2026-11-02. Working notes, not policy. Numbers are VERIFIED only if seen in a source or own output.

## Evidence collected so far

- Cohen and Frazzini 2008: customer-momentum long-short, monthly alpha over 150 bp, sample 1980-2004. VERIFIED (RePEc abstract).
- Replication (dmurav.com, v2026-09-06): in sample VW L/S 1.371%/mo (t=3.36). Out of sample 2005-2024: 0.092%/mo (t=0.34), FF3 0.149% (t=0.53), FF4 0.152% (t=0.50); 38,875 links, 100,822 stock-months, 240 months. Author notes conservative mapping may attenuate. VERIFIED.
- arXiv 2301.11394: 2005-2018 out-of-sample; EW L/S CAPM alpha 0.67%/mo (t=2.25); VW 0.61% (t=1.49); customer factor negative return in 2005-2018; contemporaneous firm vs customer portfolio correlation 0.26 vs 0.12 random. VERIFIED.
- state.strategy_candidates: only live cooldown row is I, first-hop shock, 2027-01-17. No supplier/customer candidate. VERIFIED by query.

## Further evidence (appended as gathered)

- Ali and Hirshleifer (NBER 25201): connected-stock momentum alpha 1.68%/mo (t=9.67); customer and customer/supplier-industry momentum alphas insignificant or negative after controlling for it. Mechanical, non-AI, and it subsumes the link effect. VERIFIED (abstract).
- McLean and Pontiff: average post-publication decay about 35%. VERIFIED.
- Bianchi et al. 2026 (SSRN 7149643): firms' voluntary discussion of major customers on calls, links from 10-K major-customer disclosures, sentence-level FinBERT, 44,102 calls in the snippet (cut off mid-sentence). Page fetch failed, so returns result UNVERIFIED.
- state.arsenal_rails.max_roundtrip_commission_pct = 1.8. VERIFIED query.
- state.shock_transmission_status: E = SPREAD, exempt_by_class false, override_applies true, basis "binds: class SPREAD". VERIFIED query. No gate row exists for any strategy.
- IBKR fixed schedule: USD 0.005/share, min USD 1.00/order, max 1% of trade value. VERIFIED (ibkr commissions page).
- FMP earningsTranscript: plan-gated, access denied (ops/connector_tools.yaml). Transcripts reachable only through Tavily. VERIFIED repo text.
- IBKR get_company_connections has no customer or supplier link type (schema enumerates theme, product, country, region, competitor). VERIFIED. IBKR get_earnings_insight recap carries impacted_companies with company_relationship such as Supplier: AAPL 2026-07-30 recap lists 8, of which Supplier = Hon Hai, TSMC, Qualcomm; only QCOM is a US primary listing. VERIFIED.

## Link-breadth measurement (own reading, 10-K text via Tavily; sec.gov direct returned 403 rate-limit all session)

Sample frame: seeded random 60 S&P 500 + 40 S&P 400 (seed 20261102), 98 with a 10-K. I read 33, chosen as the B2B-looking names, so this tilts in the idea's favour.
- Named tradable customer (8): CIEN-T, KLAC-TSM, ENTG-TSM, CHD-WMT, SN-AMZN/COST/WMT, ALSN-PCAR (plus Daimler, Traton foreign), MCK-CVS, MZTI-WMT.
- Customer >=10% but unnamed or anonymised (12): TTMI, ZBRA, NTAP, KVUE, SMTC, RMBS, MP, BDC, AOS, OKE, FTI, ELAN. CIEN also hides its largest ("a cloud provider", 17.9%).
- Named but not tradable (2): CF-CHS, KTOS-US Government.
- No >=10% customer surfaced (11): AMZN, APH, GRMN, HUBB, ATI, CTVA, MLI, APD, LII, ROK, TECH.
Rates: 8/33 = 24% of read names; 8/98 = 8.2% floor for the frame if the unread 65 are all zero. Hubs: WMT 3 of 8, TSM 2 of 8, so links are not independent.
Caveat: the extract is query-reranked and can miss a disclosure, so "none surfaced" is not proof of none.

## Post-cutoff pilot (headline level only)

IBKR recaps, 8 names, 2026-07-01 to 2026-11-02 (`search_earnings_insights`). VERIFIED output: 6 recaps, all Q2 season (WMT 08-20, MCK 08-05, CVS 08-05, CHD 07-31, KLAC 07-28, PCAR 07-28). None for ALSN or TSM, and none for any of the 8 from the Q3 season so far.
- CHD-WMT: both beat and raised. No conflict at headline level. CHD reported 07-31, WMT 08-20, about 14 trading days apart, so the signal cannot form until the later report.
- MCK-CVS: both beat and raised, same day. No conflict at headline level.
- KLAC-TSM and ALSN-PCAR: one side missing, not comparable.
So 0 contradictions from 2 comparable pairs. Titles only, not the calls: far too thin to estimate a rate, but it is the only observation there is.

## T1 Register: FAIL today

Class SPREAD (long and short, market factor netted), across industry groups. `state.shock_transmission_status`: E, the only SPREAD row, shows exempt_by_class false, override_applies true, and no gate defined. VERIFIED. Under acute, L8 would be forced to DO-NOT-ACTIVATE.
It is not SHOCK-NATIVE: its activation is earnings seasons, not shock_overlay, and it does not key to the rubric's exit test.
Breaker requirements (strategy/02_regime_router.md, Rev 53):
- (i) Per-industry-group leg: awkward by construction. Pairs span groups, so a group population has to be invented, for example by supplier group, with few pairs per group given 46-227 links in total.
- (ii) Low-side leg keyed to own breakdown invalidation: firm vs customer-portfolio correlation is 0.26 (arXiv 2301.11394, VERIFIED), and E's breakdown line is 0.3. A correlation-based low-side leg would sit tripped from day one, or be set so low it means nothing. Any non-correlation invalidation would be new, unproven machinery.
- (iii) Stress replay showing it trips: needs a dated, point-in-time link panel plus historical transcripts. Neither is reachable in the current data access (see T7).
It also needs an owner revision and adversarial review. None of this can happen today. Open from stage 1: whether a bound design still records SHADOW and PAPER signals is unresolved, and L8 would inherit that.

## T2 Frequency: load-bearing number not measured

No source gives a contradiction rate. Funnel, all computed in `L8_final.py`:
- Named tradable link rate: 8.2% floor to 24.2% (own read above). VERIFIED as read, B2B-tilted.
- Links per named supplier 1.25 (10 of 8) and cross-group share 4 of 8 (CIEN-T, CHD-WMT, SN-WMT etc., MZTI-WMT). KLAC-TSM, ENTG-TSM, ALSN-PCAR and MCK-CVS sit in the same GICS group. Group assignment is from my own knowledge, UNVERIFIED.
- Cross-group tradable links: 46-136 on the S&P 900 frame, 77-227 on a 1,500-name >=$2B universe (that size UNVERIFIED). Cross-check: the replication's conservative mapping has 38,875 links over 20 fiscal years, about 1,944 a year, and about 420 suppliers a month at all caps. VERIFIED, and consistent with a much smaller liquid subset.
- Contradiction rate 2-10% per link-season: UNVERIFIED assumption.
- Result: 3.7-91 signals a year, taking one pair as one round trip. Per 60 trading days: 0.9-22, before removing holds that have not closed. Signals cluster in seasons, so a 60-day PAPER catches about one season.
- Floor: at 3.7 a year, floor 3, about 206 trading days. At 10 a year, floor 10, about 252 days. At 91 a year, floor 10, about 28 days. All are before the 400-day cull, so frequency is not what kills it. It does depend on an unmeasured rate.
- Hub risk: WMT in 3 of 8 links and TSM in 2 of 8, so signals are not independent.

## T3 Cost vs edge: FAIL on best-supported edge

All per dollar of leg notional, since L/S returns are per $1 long and $1 short.
- Commission: IBKR fixed, $1 minimum per order, 4 orders = $4 on $2,000 a leg = 20 bp of a leg, 0.10% of $4,000 gross. At $1,000 a leg it is 0.20% of gross. Rail d (1.8%): PASS. VERIFIED schedule.
- Spread and open slippage: 5 bp a side large, 14 bp a side mid. UNVERIFIED assumption. Large is consistent with the repo's 5-10 bp spread line in news_reaction_paper_book_2026-10.md.
- Borrow: 0.25% a year general collateral UNVERIFIED, 2.5 bp over 25 days; a 3% warm borrow would be 30 bp. No locate data for any name.
- All-in at 25 days: large 42.5 bp, mid 78.5 bp.
Gross at 25 days (monthly x 25/21):
| Source | Monthly | 25d gross | Net large | Net mid |
|---|---|---|---|---|
| Replication VW 2005-24 (t=0.34) | 0.092% | 11 bp | -32 | -68 |
| Replication FF4 (t=0.50) | 0.152% | 18 bp | -24 | -60 |
| arXiv 2005-18 VW alpha (t=1.49) | 0.61% | 73 bp | +30 | -6 |
| arXiv 2005-18 EW alpha (t=2.25) | 0.67% | 80 bp | +37 | +1 |
| C&F in sample, VW, 1980-2004 | 1.376% | 164 bp | not a live number | |
The two post-2005 sources disagree. The longer, later sample is near zero, and its author warns the conservative mapping may attenuate it. arXiv reports the customer factor negative over 2005-18, and its EW L/S is the only significant row, tilted to smaller names. EW vs VW labelling in the arXiv extract is inferred from table order and its text. At 40 days arXiv nets +72 to +84 bp large, but that scales a one-month effect linearly, which nothing supports. In C&F's own sample, large caps with high common ownership earned 0.611%/mo EW (t=1.05) vs 2.703% for low common ownership, VERIFIED from Table IX. The liquid, watched names L8 can trade were weak even before publication.

## T4 Next-open: not shown

- The signal forms at the later of the two reports, up to about 14 trading days after the first (CHD-WMT), so next-open entry is mechanically fine.
- Whether anything is left is the question. Replication suggests little post-2005. arXiv 2409.06255: indirect 1-day news effect on suppliers more than 10x smaller than the direct one (VERIFIED, global and Japanese samples). SMU LLM paper: sentiment mostly incorporated on the first trading day (VERIFIED). Neither tests contradictions.
- No event study of customer-supplier contradictions found in 3 searches. UNVERIFIED either way.

## T5 Overlap

- Second-hop (refuted): different test. That was industry baskets after an oil shock, built from input-output links; pooled 4-week hedged CAR +0.6% vs +0.1% placebo. L8 is firm-level, earnings-season, text-based. The refutation does not transfer, though the dossier rests on the same C&F diffusion premise that has since decayed.
- E: same-group pairs >=$10B, L8 cross-group. Half of the links found are same-group, which the cross-group rule removes, and those would otherwise overlap E.
- B: a contradiction on a name with a >=5% event move, inside 10 trading days, is also a B setup; B is long-biased, L8 hedged. Partial overlap.
- Cooldowns: only I (first-hop, 2027-01-17), not applicable. Defensive rotation, convexity, momentum participation: none. Customer momentum is itself a momentum spillover, which is close to H in spirit if the AI adds nothing.

## T6 Mechanical baseline

Non-AI customer momentum: 0.092%/mo VW 2005-24, or 0.61-0.67% on the friendlier sample. Ali and Hirshleifer: customer-momentum alpha is insignificant or negative after connected-stock momentum (1.68%/mo, t=9.67, on shared analyst coverage), which needs no LLM. VERIFIED abstract. That also suggests analysts are the ones who connect these names, at least for covered stocks.
The AI must add: a contradiction call that picks the correct side, worth more than 42-79 bp per round trip on top of a near-zero baseline. Nothing measured shows it does. A conflict does not say who is right: share shift, mix, inventory timing and customer-specific programs reconcile most apparent conflicts, and the direction rule is undefined. Rail (a) would rest on an assertion.
Claim "few read both sides" is weakened: the IBKR recap itself is a machine-written read-through naming Supplier links with a rating (AAPL 2026-07-30 lists Hon Hai, TSMC, Qualcomm). VERIFIED.

## T7 Data and execution

- Links: 10-K text. Reachable via data.sec.gov (200) plus Tavily extract. Direct sec.gov Archives returned 403 rate-limit all session, and the form.idx files too. Annual and often anonymised: 12 of 33 hide a >=10% customer, and CIEN hides its largest. IBKR get_company_connections has no customer or supplier link type (schema). IBKR recap impacted_companies is partial and largely foreign suppliers.
- Transcripts: FMP earningsTranscript denied (ops/connector_tools.yaml). Tavily only, coverage not measured. IBKR recaps missed 2 of 8 names in Q2 and all 8 in Q3 so far.
- Execution: two MARKET legs at next open, two confirm taps, nothing beyond that. No locate check is reachable before the short leg, a pair could leg in single-sided if one tap or fill fails. No human analytic step.
- No point-in-time link panel is reachable, so no backtest.

## T8 Test feasibility

- Post-cutoff seasons: Q2 2026 (complete) and Q3 2026 (in progress). 2 independent windows, with holds of 10-40 days covering most of each season.
- Implied signals: 1.8-45 under the T2 assumptions. Labelled now: 0.
- Pair sd at 25 days: 11.5% (30% vol, rho 0.26) to 15.3% (40% vol). For t=1.96: 979-1,741 trades at mu 0.72%, 127-226 at mu 2%. At the top modelled frequency, 979 trades takes about 129 months and 127 trades about 17 months. The PAPER floor of 10 trades cannot distinguish this from noise.

## Open load-bearing unknowns

1. Contradiction rate per link-season: no source, only 2 headline-level pairs.
2. Any return evidence for a contradiction signal.
3. True post-2005 link edge in >=$2B names: the two studies disagree.
4. Open slippage and borrow for the actual legs.
5. Transcript coverage at breadth via Tavily.

## One suggestion, if anyone reopens it

Hand-label the cross-group links for Q2 2026 from actual calls, freeze the labels and direction rule, then score them. It costs no trades, and a rate near zero ends the idea for good.

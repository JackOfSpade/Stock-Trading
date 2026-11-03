# Stage 2 arithmetic check: L1 deal-document merger arb and squeeze-out bump variant

Date 2026-11-02. Working file, not policy. Arithmetic from `l1.py` in the session scratchpad; each result is restated here.

**Verdict: KILL.** It cannot be active under acute today (T1). The base arb has about zero or negative expected excess at the current spreads and published break rates (T3, T6). The only direct evidence says an off-the-shelf LLM scores worse than the calibrated market (T6). The bump variant's arithmetic is not obviously bad, but it is a long-only legal-bargaining premium that the AI merely selects, it binds under acute, and its base rate is 23 years old and microcap.

K1 findings are cited as "K1 #n" and not redone. K1's own labels carry over.

## Data limits

- **EDGAR:** form.idx returned HTTP 403 ("Undeclared Automated Tool") with the specified User-Agent on all 8 quarters, 2025 Q1 to 2026 Q4, and again with Accept-Encoding gzip on 2026 Q3. Not worked around. So there is NO fresh count of SC 13E3 or 13D filings. EDGAR counts below come from K1 section 4A (run 2026-10-25).
- **FMP chart:** ACCESS DENIED (plan tier). IBKR weekly bars were used, so event-level prices are weekly bars, not exact next-open prints.
- **Quotes:** IBKR snapshots read after the 2026-11-02 close (status REALTIME, chart_end 21:32Z). After-hours spreads run wider than regular-session spreads, so half-spreads may be overstated. DSGR's 34.81/43.77 quote is unusable.
- **Tavily:** extract returned 429 late in the run. Subramanian was read from the PDF via WebFetch's saved copy and pdftotext.
- **Not looked up:** SGOV yield. The 3.75-4.00% Fed range is used as the carry proxy.

## T1 Register class

Source: `Strategy.md` register section (Classes; Re-exemption requirements), `bigquery/264_shock_register_rev53_e_binds.sql`. VERIFIED.

| Expression | Class | Active under acute today? |
|---|---|---|
| Long target, cash deal | DIRECTIONAL-LONG. It is a net-long expression, and K1 #1 (Mitchell & Pulvino) describes the payoff as a short index put. | **No. Binds, and this class has no exemption route.** |
| Bump variant, long target | DIRECTIONAL-LONG | **No. Same.** |
| Long target / short acquirer, stock deal | SPREAD | **No. Binds until a breaker is landed.** |
| Any form as SHOCK-NATIVE | Not eligible | Activation does not require shock_overlay in {latent, acute}, and the cash and bump forms are net long. |

Can the SPREAD breaker be met?
- (i) Per-industry-group leg: buildable by grouping pending-deal spreads by GICS group. Thin, because a group would often hold 0-2 deals.
- (ii) Low-side leg keyed to its own breakdown invalidation: buildable, for example on deal-spread widening past a set level. No such invalidation exists yet.
- (iii) Stress replay showing it trips: NOT done. It needs a deal-spread history that this session could not obtain, because FMP is gated and EDGAR is blocked.
- Also needs owner revision plus adversarial review. Not met today.

Also binding: stage 1's open question about whether a bound strategy accrues SHADOW or PAPER evidence applies in full here.

**T1: FAIL for today, on evidence.** A-E also bind, so this is not unique to L1. It does not kill the idea permanently by itself.

## T2 Frequency and PAPER floor

Base arb. Universe source: K1 section 4A, EDGAR run. DEFM14A 279/yr, 248 non-SPAC, 162 with float >= $200M, 63 >= $2B (K1, VERIFIED there). ListingTrack shows 117 active deals today, up from 115 in K1 (VERIFIED, Tavily extract). The LLM-disagreement filter rate is unknown, so signal rates below are scenarios (UNVERIFIED).

Hold: closed-deal CDF from K1 C1, p25 77d, median 105.5d, p75 160d, p90 246d. The 0 point at 30d is my assumption. Averaged over entry dates, about 10.1% of entries close inside 60 trading days (about 87 calendar days).

| Signals/yr | Entries in 60td | Closed in 60td | Trading days to 10 closed | Concurrent positions | Capital at $2,000 |
|---|---|---|---|---|---|
| 162 | 38.6 | 3.9 | 88 | 46.8 | $93,649 |
| 80 | 19.0 | 1.9 | 104 | 23.1 | $46,247 |
| 40 | 9.5 | 1.0 | 136 | 11.6 | $23,123 |
| 20 | 4.8 | 0.5 | 199 | 5.8 | $11,562 |
| 10 | 2.4 | 0.2 | 325 | 2.9 | $5,781 |

The 60-day window itself yields nowhere near 10 closed trades, but the floor clears before the 400-day cull at every rate shown. **PAPER floor: PASS on time.**

Live capital is a separate problem. K1 quotes about $4,700-$4,990 per strategy (dated 2026-08-05, not re-read). That holds about 2 positions at the floor against 100-150 deals/yr at large strategies (K1 #10, UNVERIFIED). One break costs about 30% of $2,000, or about $600. This is the concentration that K1 section 5 item 6 warned about.

Bump variant. Rate: 38 controller freeze-outs/yr of all sizes, 2000-2003 (Subramanian, VERIFIED, pdftotext). Houlihan Lokey counted 33 going-private deals in 2023 (WebSearch summary, UNVERIFIED, and not a controller-only count). No current count, because EDGAR is blocked. Investable rate (US-listed, liquid enough) is UNVERIFIED.

| Annual | Floor | Hold (trading days) | Closed in 60td | Trading days to floor |
|---|---|---|---|---|
| 8 | 4 | 111 (161 cal days, Subramanian mean) | 0 | ~237 |
| 8 | 4 | 250 (PRTH-like) | 0 | ~376 |
| 6 | 3 | 111 | 0 | ~237 |
| 6 | 3 | 250 | 0 | ~376 |
| 4 | 3 | 250 | 0 | ~439, **past the 400 cull** |

PRTH's first proposal was disclosed in November 2025 and it is still pending about 51 weeks later (VERIFIED, press release and IBKR bars). So the variant is marginal at modern holds and low counts.

## T3 Cost and gross edge

Commission assumption: IBKR tiered $0.0035/share with $0.35 minimum, fixed $0.005/share with $1 minimum. The $0.35 minimum is in `Experiment_Parameters.md` via K1. The per-share rates are from memory, UNVERIFIED.

| Name | Shares at $2,000 | Commission round trip, fixed | Half-spread | Held to close (one commission side + half-spread) | Sold on break (two sides, two half-spreads) |
|---|---|---|---|---|---|
| ADT | 203 | 0.102% | 0.05% | 0.10% | 0.20% |
| SGRY | 86 | 0.100% | 0.30% | 0.35% | 0.70% |
| PRTH | 252 | 0.126% | 0.38% | 0.44% | 0.89% |

**Rail d: PASS** (commission about 0.1% against 1.8%). Stock deals, two legs at $2,000 each: 4 sides at $1 is 0.20% of the long notional, plus half-spreads on each leg, plus borrow (no data, as in K1). UNVERIFIED for borrow.

Spreads at the ask, 2026-11-02 (VERIFIED quotes; offers from ListingTrack and press releases; close dates are my assumption from "Q1 2027" and "early 2027" wording):

| Name | Offer | Ask | Gross | Days assumed | Annualized |
|---|---|---|---|---|---|
| ADT | 10.00 | 9.85 | 1.52% | 149 | 3.7% |
| SGRY | 23.50 | 23.17 | 1.42% | 149 | 3.5% |
| PERI | 11.70 | 11.40 | 2.63% | 118 | 8.1% |
| PRTH | 8.05 | 7.93 | 1.51% | 180 (no date seen) | 3.1% |
| DSGR | 35.00 | last 35.00 | about 0 | n/a | n/a |

ListingTrack printed PERI 2.45%, ADT 1.21%, ULBI 2.43%, SGRY 1.29% (VERIFIED). Basis not stated. UBS median annualized about 4% at end-2025 (K1 #17, UNVERIFIED) agrees with this small set. Four of five sit at or below the 3.75-4.00% carry. PERI is the exception, and this is a sample of 5 recent deals, not a distribution.

Best-supported gross edge per trade, in excess of carry:
- HFRI about 200bp/yr over risk-free (K1 #15, UNVERIFIED): 0.58% at 105.5d, 0.96% at 175d.
- Mitchell & Pulvino about 4%/yr after costs, 1963-1998 (K1 #1, VERIFIED): 1.16% at 105.5d. Old, and K1 records decay since.
- Baker & Savasoglu 0.6-0.9%/mo, 1981-1996 (K1 #2, VERIFIED): 2.1-3.1% at 105.5d. Older still.
- Current-spread EV below is at or below zero.

All-in cost of 0.10-0.44% consumes about 17-76% of the 0.58% recent-premium estimate. Those figures come from a diversified index, and at 2-12 positions a break dominates.

**T3: rail d passes. Edge after cost is about zero on recent evidence.**

## T4 Next-open survival

- **Base arb:** a spread is still present days after announcement (ADT 1.52% four days on, PERI 2.63% one day on). So entry is possible. That shows a remaining carry, not an edge. PASS on mechanics.
- **Bump variant:** the stock can trade below the first offer after disclosure, which is what the idea needs. Weekly-open entries, from IBKR bars. VERIFIED prices, but my timing of disclosure against the bar:

| Case | First offer | Entry | Entry vs first | Final | Latest | Return to date |
|---|---|---|---|---|---|---|
| DSGR | 29.50 | 25.99 (week of 2026-03-16) | -11.9% | 35.00 | 34.98 | +34.6% |
| PRTH | under about 6.19 ("more than 30%" below 8.05) | 5.62 (week of 2025-11-10) | at least -9.2% | 8.05 | 7.91 | +40.7% |

These two came up in a search for raised prices, so they are **selected and carry no weight as a rate**. PRTH also ran about 7.31 to 5.39 from June to August 2026 (weekly closes), a drawdown of about 26% before the deal. **T4 for the bump variant: UNVERIFIED** across any unselected sample.

## T5 Overlap and dead ideas

- **B:** first-offer proposals are large event moves. On names with >= $2B cap and >= $10M ADV, the bump variant is inside B's event window unless the "pinned by own all-cash deal" exclusion catches it. A non-binding proposal is not a signed deal, so overlap with B looks direct (my reading of the task's B definition; the exclusion's exact text was not read). Cash-deal arb is what B now excludes.
- **E:** stock-deal pairs in the same group with >= $10B caps resemble E's instrument, with a different mechanism. EQT/RRC is an example. Partial overlap, and the same binding.
- **A:** a long held toward a dated catalyst. Partial conceptual overlap only.
- **Dead ideas and cooldowns:** none match. `state.strategy_candidates` has no row matching merger, arb, squeeze-out or 13e-3. The only live cooldown is I, REJECTED, to 2027-01-17. VERIFIED (own queries).

**T5: PASS for the base arb. Material overlap with B for the variant.**

## T6 Mechanical baseline and AI increment

**Baseline, buy every deal.** ADT at the ask: +1.52% if it closes, -30.3% to the unaffected $6.87 ($10.00 / 1.456). Implied completion 95.2%.

| Break rate | ADT EV | PRTH EV (implied 96.2%, break -38.5%) |
|---|---|---|
| 5% | -0.07% | -0.49% |
| 9% | -1.34% | -2.08% |
| 12% | -2.29% | -3.28% |
| 14% | -2.93% | -4.08% |

Caveats: two deals; K1 #11's 9-12% counts renegotiation as breakage, which overstates the loss; and PRTH's unaffected price is a year old. Still, the sign agrees with the HFRI and ARBNX record: thin, and about zero after retail costs (K1 #1 about 2%/yr for individuals, K1 #13 ARBNX 3.53% over 10 years).

**What the AI must add.** A completion estimate better than a calibrated market on deals where the spread is wrong, reliably enough to overcome a -30% tail. At 2-12 positions, that has to hold on few trades.

**What the evidence shows (K1 3A, VERIFIED).** Class-balanced Brier:

| Forecaster | Brier |
|---|---|
| Fine-tuned GPT-4o | 0.151 |
| XGBoost | 0.186 |
| Calibrated market | 0.199 |
| GPT-4o off the shelf | 0.201 |
| GPT-5.1 | 0.214 |
| Gemini-3-Pro | 0.231 |
| Claude-3.7-Sonnet | 0.259 |

The off-the-shelf LLM increment is negative, and Claude scored worst in this set. The only win needed 1,244 hindsight-labelled deals of fine-tuning, which this system does not have. No study reports P&L. Cao et al. attribute hedge-fund skill to downside handling, not forecasting (K1 #3). **AI increment: none measured, and negative in the one direct test for the setup this system would run.**

**Bump variant baseline, buy every controller first offer.** Subramanian, n=96, June 2001 to December 2003 (VERIFIED, Table 1): increase over first offer mean 14.3%, median 10.4%; mergers 18.1%/11.6%; tender offers 7.2%/4.2%; success 79.2%; initiation to close mean 161 days. Median deal value **$14.5M**, so not an investable population today. Bumps are for successful deals only.

My EV, assuming failure returns to the unaffected price (first-offer premium 26.9% derived from the 45.0% final premium):

| Entry vs first offer | Success | Fail | EV |
|---|---|---|---|
| -10% | +27.0% | -12.4% | +18.8% |
| -5% | +20.3% | -17.0% | +12.5% |
| 0% | +14.3% | -21.2% | +6.9% |
| +3% | +11.0% | -23.5% | +3.8% |
| +5% | +8.9% | -24.9% | +1.8% |
| +8% | +5.8% | -27.0% | -1.0% |

At the median bump and entry at first offer, EV is +3.8%. Breakeven entry is about +7% over first offer. So **this does not die on arithmetic**, if 2001-2003 holds and entry prices are at or below first offer.

Recent cases, not a sample:

| Case | First | Final | Change |
|---|---|---|---|
| DSGR | 29.50 | 35.00 | +18.6% |
| PRTH | under about 6.19 | 8.05 | over +30% |
| Penske (cap well over $2B) | 210 | 212 | **+0.95%** |
| ReNew | 8.00 | 7.02 | **-12.25%** |

(Press releases and Enerdatics page for DSGR, PRTH, ReNew; WebSearch summary for Penske.) The largest, most investable case got under 1%, and one offer was cut. That spread is at odds with using a 14.3% mean. SB 21 (2025) also changed Delaware's controller safe harbor (Diligent page, seen in a search result), so the 2001-2003 bargaining regime may not carry over.

**Rail (a) for the variant:** the return is a legal and bargaining premium. "Buy every first offer" captures it with no AI. The AI would have to predict bump size from 13D, 13E-3 and committee records, and no evidence for that was found. **FAIL on rail a: a premium the AI merely selects.**

## T7 Data and execution

- Inputs: public filings (agreements, 13D, 13E-3, 14D-9) and IBKR quotes. No human step for reading. EDGAR 403 here needs resolving for any routine use. Whether routines hit the same block is UNVERIFIED.
- Orders: market at next open with a confirm tap. Cash-merger exit is automatic at close, with no extra step.
- **Tender offers:** participating may need an IBKR corporate-action election, a human step beyond the confirm tap unless the position is sold or held to the back-end merger. UNVERIFIED; not tested.
- No intraday monitoring: a break is taken as a gap at the next open. Acceptable for this idea, since the loss is a gap anyway.
- Stock-deal shorts: borrow and locate not checked. Hedge ratio resets are not addressed.

**T7: no fatal blocker found. Two items UNVERIFIED.**

## T8 Post-cutoff test

- **Base arb:** DEFM14A July to 25 Oct 2026: 19 + 21 + 24 + 21 = 85 filings (K1 counts, Oct partial). Scaled by 162/248: about 56 at >= $200M float (my scaling, UNVERIFIED). Most of those were signed before filing, some before July, so the contamination-safe count by signing date is lower and was not measured.
- Lifetime breaks expected from 56 deals at 9-14%: about 5-8. Few have resolved, at a 105-day median hold. That is one 4-month window under one regime, far too few negatives for a Brier comparison, against 404 test deals and about 55 negatives (K1) in the only study.
- **Bump:** first offers found from July 2026: Penske (22 Jul), 111 Inc (16 Sep). One search only, so a lower bound. Resolved: Penske only, n=1. Definitive agreements from July 2026 on earlier proposals: Perfect (10 Jul), DSGR (week of 13 Jul by price jump), ReNew (11 Aug), PRTH (21 Sep), Penske (15 Oct); their first offers mostly predate the cutoff, so they are not clean.

**T8: FAIL for any near-term test of the AI claim, on power.**

## Result by check

| Check | Base arb | Bump variant |
|---|---|---|
| T1 | FAIL today | FAIL today |
| T2 | PASS on time, capital thin | Marginal, 0 closed in 60td |
| T3 | Rail d PASS, edge about zero | Rail d PASS, edge unproven |
| T4 | PASS mechanics, no edge shown | UNVERIFIED |
| T5 | PASS | B overlap |
| T6 | FAIL | Arithmetic positive on stale data, rail a FAIL |
| T7 | No blocker | No blocker |
| T8 | FAIL on power | FAIL on power |

## One suggestion, not a rescue

If the bump variant is ever revisited, first run an unselected event study of all US-listed controller first offers since 2020: price at next open against first offer, final price, days to close, and outcome. It needs EDGAR access. That one table settles whether the 2001-2003 numbers still hold. It would not cure the rail a failure.

## Sources opened or seen

- Repo: `Strategy.md`, `bigquery/264_shock_register_rev53_e_binds.sql`, `salvage_K1-merger-arb.md`, `stage1_ideas.md`
- BigQuery: `state.strategy_candidates` (SELECT only)
- IBKR: weekly bars DSGR, PRTH; snapshots ADT, SGRY, PERI, PRTH, DSGR
- https://www.listingtrack.io/mergers/active-ma
- https://law.yale.edu/sites/default/files/documents/pdf/subramanian.pdf (Table 1)
- https://law.stanford.edu/wp-content/uploads/2016/09/5HarvBusLRev205.pdf (snippet only)
- https://prioritycommerce.com/news/priority-technology-holdings-inc-announces-definitive-agreement-with-investor-group-led-by-chairman-and-ceo-thomas-priore-to-take-company-private
- https://investor.distributionsolutionsgroup.com/news-releases/news-release-details/distribution-solutions-group-be-taken-private-affiliates-lkcm
- https://www.enerdatics.com/insights/why-a-year-of-negotiation-left-renew-shareholders-with-a-lower-price-than-first-offered
- https://www.sec.gov/Archives/edgar/data/1899830/000110465926082398/tm2619936d1_ex99-1.htm (Perfect, search result)
- https://www.sec.gov/Archives/edgar/data/0001738906/000110465926108394/tm2625457d1_ex99-2.htm (111 Inc, search summary)
- https://www.paulweiss.com/insights/client-news/penske-automotive-group-to-be-acquired-by-penske-corporation-and-mitsui-co and https://www.sec.gov/Archives/edgar/data/0001019849/000114036126039664/ef20083688_ex99-1.htm (Penske, search summary)
- https://www.diligent.com/resources/blog/ad-hoc-committee (SB 21, search result)
- https://hedgefundalpha.com/news/houlihan-lokey-2023-going-private-transaction/ (search summary)

# Stage 2, L6: SEC comment-letter severity

Working file, not policy. Date 2026-11-02. Nothing here is a lead or a candidate.

**Verdict: KILL.**

Three findings decide it:

1. The target population does not exist as written. A thread is released only after the review closes, so "unresolved" cannot be observed at release.
2. The best-supported gross edge, after a next-open entry, is about 0.36% at day +15 and 0.77% at day +50. All-in cost is about 0.65-1.10%.
3. It is a SPREAD with no breaker, so it binds under acute today.

Label key: VERIFIED means I saw the number in a source or in my own output. UNVERIFIED means it is an assumption or could not be confirmed.

## Access limits on this run

- **EDGAR form.idx was not read.** HTTP 403 "Undeclared Automated Tool" on every attempt with the prescribed User-Agent: the 16-quarter loop (curl exit 56), then 3 direct checks spread over several minutes (VERIFIED). The SEC page asks for company-specific information in the User-Agent. I did not change the assigned User-Agent, add the owner's email or spoof a browser. Sibling files L1, L4, L7 and L10 record the same 403.
- **So thread counts are second-hand.** They come from Finrep's published count of EDGAR daily indexes and from audit-firm reports, not my own count.
- **FMP `secFilings` search by form type:** refused as above the current plan tier (VERIFIED).
- **SSRN and the Ryans 2016 working paper were not opened.** Its numbers are only as quoted in Edwards, Klassen and Pinto (2019).

## T1 Register class

- **Class:** SPREAD. Single-name short against a sector ETF nets the market factor (`Strategy.md`, Shock Transmission Register, Classes paragraph). VERIFIED.
- **Not SHOCK-NATIVE.** Activation does not require `shock_overlay` in {latent, acute}, and the frequency is not stated in shock events.
- **Active under acute today: NO.** A strategy with no row binds. Rev 53 states that no SPREAD row carries a breaker today, and E binds for that reason. VERIFIED.

Can the three breaker requirements be met?

| Requirement | Possible? | How |
|---|---|---|
| (i) Per-industry-group leg | In principle | Measure each short's residual to its group ETF and trip on a group-local shock |
| (ii) Low-side leg keyed to its own breakdown invalidation | In principle | Trip when the 60-day correlation of short versus hedge falls below a floor |
| (iii) Stress replay showing it trips | Not today | No position history exists. A replay needs a historical signal series, which needs the LLM run over past threads with a form.idx or Audit Analytics source |

The breaker also needs an owner revision and adversarial review. It does not exist now.

The open question in `stage1_ideas.md` also applies here: whether a bound strategy still records signals in SHADOW and PAPER is unsettled.

## T2 Frequency

### Letters released

Source: Finrep, counted from EDGAR daily indexes, last updated 2026-10-16. https://www.finrep.ai/blog/sec-comment-letters (VERIFIED)

| Release quarter | UPLOAD | CORRESP | Median age, days | Over 180 days old |
|---|---|---|---|---|
| Q3 2025 | 2,278 | 3,160 | 103 | 25% |
| Q4 2025 | 349 | 348 | 140 | 33% |
| Q1 2026 | 885 | 1,137 | 181 | 50% |
| Q2 2026 | 868 | 1,606 | 84 | 33% |
| Q3 2026 | 1,120 | 1,696 | 217 | 66% |
| Q4 2026 to Oct 14 | 41 | 47 | 225 | 93% |

- Rolling four quarters: 4,380 UPLOAD to Q2 2026, then 3,222 to Q3 2026 (my sum, VERIFIED).
- These counts cover all form types, including registration statements, so most are not periodic-report reviews.
- Monthly UPLOAD: 2025 Jul 418, Aug 1,039, Sep 821, Oct 0, Nov 83, Dec 266. 2026 Jan 354, Feb 219, Mar 312, Apr 137, May 515, Jun 216, Jul 337, Aug 335, Sep 448, Oct 1-14 41. Releases come in bursts. October had zero or near zero in both years: none in October 2025, none Oct 1-12 2026.

### Periodic-report letters

- PwC, letters on 10-K and 10-Q: 1,270 for 7/2024-6/2025, 487 for 7/2025-6/2026 (VERIFIED). The later figure is truncated by release lag, so it is a floor. https://viewpoint.pwc.com/dt/us/en/pwc/sec_comment_letters/comment_letter_trends_DM/SEC_comment_letters.html
- Deloitte: about 3,400 companies reviewed in FY2024, about a quarter drew a letter, so about 850 companies (VERIFIED as quoted by Deloitte and Finrep).
- Ryans (2021): 17,719 10-K conversations, roughly 1,610 per year if the span is 2006-2016 (the span comes from the paper's topic-trend discussion). Final matched sample 8,483 (VERIFIED).

### Liquid and severe subset

| Step | Value | Status |
|---|---|---|
| UPLOAD share of letters | 5,541 / 13,535 = 0.409 | VERIFIED arithmetic |
| Conversation length | 4.63 letters (Ryans) | VERIFIED |
| UPLOAD per thread | 1.90 | Derived; mixes two eras |
| Threads per year | 1,270 / 1.90 = 670; 487 / 1.90 = 257 | Derived |
| Over $700M float | 53% of letters (EY, year to June 2025) | VERIFIED |
| At least $2B cap and $10M ADV | 35% of threads | **UNVERIFIED assumption** |
| "Severe" share | 10% (assumption) to 28.2% (Ryans NB restatement flag rate) | Mixed |

**Result: about 9 to 66 signals per year** at the 35% liquidity share. That falls in a range, because the 257-670 thread base is itself uncertain. The range rises to 38-100 at the 53% float ceiling, which is not a liquidity filter. My own form.idx count, which the task asked for, could not be done.

### PAPER arithmetic, my output

| Signals per year | Hold 20d: closed in 60d | Hold 40d: closed in 60d | Hold 60d: closed in 60d | Days to 10 closed (20 / 40 / 60d hold) |
|---|---|---|---|---|
| 8 | 1.3 | 0.6 | 0 | 335 / 355 / 375 |
| 12 | 1.9 | 1.0 | 0 | 230 / 250 / 270 |
| 20 | 3.2 | 1.6 | 0 | 146 / 166 / 186 |
| 30 | 4.8 | 2.4 | 0 | 104 / 124 / 144 |
| 60 | 9.5 | 4.8 | 0 | 62 / 82 / 102 |

- It does not clear the 10-trade floor inside the first 60 paper days.
- It clears before the 400-day cull at every rate shown.
- T2 is a pass on the cull, with a thin margin at about 8 per year, and with the thread count second-hand.

**The word "unresolved" removes nearly all of this count.** See T4.

## T3 Cost at $2,000

| Item | Value | Status |
|---|---|---|
| Equity-pair round trip, both legs | 0.42% | VERIFIED as recorded in `ops/research/shock_native_candidate_dossier_2026-10-19.md`, rail (d) rows; the 2026-08 measurement itself was not opened |
| Rail d (limit 1.8%) | 0.42% passes | VERIFIED comparison |
| Spread and slippage at the open | 0.20% | UNVERIFIED assumption |
| Borrow, 0.4% a year (near the sampled 0.25-0.43%) | 0.03 / 0.06 / 0.10% at 20 / 40 / 60d | Computed |
| Borrow, 3% a year | 0.24 / 0.48 / 0.71% | UNVERIFIED rate |
| Borrow, 10% a year | 0.79 / 1.59 / 2.38% | UNVERIFIED rate |

**All-in:**

| Annual borrow | 20d | 40d | 60d |
|---|---|---|---|
| 0.4% | 0.65% | 0.68% | 0.72% |
| 3% | 0.86% | 1.10% | 1.33% |
| 10% | 1.41% | 2.21% | 3.00% |

Severely flagged names are the ones most likely to carry elevated borrow, though that was not measured here.

### Gross edge

| Source | Finding | Status |
|---|---|---|
| Dechow, Lawrence, Ryans (working paper, Nov 2013), Table 6 | Revenue-recognition letters, n = 1,560: CAR -23.2 bp at +1, -43.7 bp at +5, -59.0 bp at +15. 54.1% negative at +15. Other 10-K letters, n = 6,404: +40.5 bp at +15. Size-portfolio adjusted | VERIFIED, read |
| Dechow et al. (2016), as quoted by Edwards et al. | -0.3% at release, -1% over days 0-50 | VERIFIED secondary |
| Ryans (RAST 2021), all letters | CAR[-1,1] mean 0.000, CAR[-1,10] +0.001, CAR[-1,90] +0.005, median -0.002. SD of the 90-day CAR 16.3% | VERIFIED, read |
| Ryans (2016 working paper), as quoted by Edwards et al. | "Important" letters: no reaction at disclosure and insignificant at 90 days. With at least 3 EDGAR downloads: -1.3% short window and -6% over 90 days | VERIFIED secondary only |
| Edwards, Klassen, Pinto (2019) | n about 10,450: 3-day CAR -0.1%, 50-day CAR -0.2%, SD 24.1%. Revenue and fair-value coefficients not different from zero on the 50-day test. Tax coefficient significant only at 10% | VERIFIED, read |
| Yang (2019), citing the US literature | Average two-day release reaction 0.0005. Only 0.5% of reviewed firms materially restate during correspondence | VERIFIED secondary |
| Johnston and Petacchi (2017) | Little support for reading a letter as a sign of poor reporting quality. Spreads tighten and ERCs rise after resolution | VERIFIED, abstract as returned by search |
| Hassan (2024, Research Square) | Could not read; no numbers obtained | Not used |

The -6% figure is not usable:

- It conditions on downloads observed after release.
- Its window is 90 days against a 20-60 day design.
- It was not read at the primary source.
- The unconditional "important" result in the same passage is insignificant.

### Net, from next-open entry

| Horizon | Gross | Cost (low borrow) | Net |
|---|---|---|---|
| +15 days | 0.36% | 0.65% | **-0.29%** |
| +50 days | 0.77% | 0.68-0.72% | **+0.05 to +0.09%** |

- With 3% borrow the +50 day case is negative: 0.77% against about 1.1-1.3%.
- The return cannot be recovered through the classifier on this evidence. Ryans' restatement signal raises the next-year restatement rate from 6.7% to 10.8%, so 89% of flagged letters do not restate. It shows no earnings difference (0.018 versus 0.016).
- Illustration: if a restatement costs an assumed 10% (UNVERIFIED), a 4.1 point lift is worth about 0.41%. The write-down flag (27.3% versus 21.8%) at the same assumption is about 0.55%. Both are below cost.

**Power (my output):** detecting 1% per trade at t = 2 needs about 1,063 trades at SD 16.3% and about 2,323 at SD 24.1%. PAPER's 10 trades cannot distinguish this from zero.

**T3 fails on evidence.** Commission alone passes rail d. The all-in edge is at or below cost.

## T4 Next-open survival

**The drift is not purely a day-0 reaction.** In Dechow, 61% of the +15 move (35.8 of 59 bp) comes after day +1, which reads as slow drift. Timing alone would pass. Three other facts fail it.

1. **"Unresolved" has no population at release.** The conversation continues until all questions are resolved, and only then is it released (Yang 2019, describing US practice). The earliest release is 20 business days after the review completes (EY, Dechow, Finrep). VERIFIED. So every released thread is closed. The closest thing an LLM could grade is an issue closed by a promise to change future filings. Costco's 2026 thread is the example: two comments, agreed changes, closed 22 days after the first letter.
2. **The news is now about 7 months old.** Median letter age at release was 217 days in Q3 2026, against 103 a year earlier. 66% were over 180 days and only 17% under 90 days. Costco's letter went public 203 days after it was written. VERIFIED. Dechow's sample sits at a median lag of about 20 business days after review completion, with 45 days as the earlier minimum. A later 10-K or 10-Q may already carry the changed disclosure, so the 2006-2016 drift may not carry over. No study of the current lag was found.
3. **Informed money moves before release.** Dechow: abnormal increases in insider sales of 46-65% in the 5 days before disclosure of revenue-recognition letters, and 109-126% for high short-interest firms. Geiger, Johnson, Jones and Kumas (Management Science, per the GMU summary): mutual funds net sold about $724,000 per firm in the 6 days after receipt, more for critical letters and longer threads, with significant gains over 45 days. VERIFIED, with the second from a university news summary. The release is the end of that information advantage, not the start.

**T4 fails on evidence**, on the unresolved filter and on staleness.

## T5 Overlap

| Idea | Overlap |
|---|---|
| A pre-event longs | None; long-only |
| B post-event | None on trigger. B needs a 5% event-day move. A release is rarely a price event |
| C FOMC options | None |
| D narrative core | Low; opposite sign, possible conflict if D holds a flagged name |
| E pairs | Partial on structure (SPREAD, same binding reason), not on signal |
| Dead ideas | None. `state.strategy_candidates` holds only F, G, H, I, none about comment letters. `events.strategy_research_leads` has no row mentioning comment letters (query returned 0 rows, VERIFIED) |

T5 passes.

## T6 Mechanical baseline

- **Non-AI version:** tag revenue-recognition letters, or count letters in a thread. Dechow gives -59 bp at +15 and, secondary, -1% at +50. The rule is a keyword search.
- **Earlier text classifier:** Naive Bayes in Ryans predicts the restatement outcome with 60.1% univariate lift. It is non-LLM, and the paper reports no trading return on it.
- **LLM evidence:** one search found no study applying an LLM to UPLOAD letters for returns. Absence from one search is weak evidence.
- **What the AI must add:** severity grading that beats the revenue-recognition keyword rule by enough to at least double the net-of-next-open gross, from about 0.77% to more than about 1.3-1.5% at 40-60 days, on names with $2B or more of cap, on letters about 7 months old. It must do this in a hedged short, with an unknown borrow bill.
- **Measured so far: nothing.** Rail (a) reads acceptably in form, since grading is narrative synthesis. No evidence supports it in substance.

## T7 Data and execution

- UPLOAD and CORRESP are free public EDGAR documents. No human step beyond the confirm tap. Execution is ordinary market orders: short and long ETF.
- **Feed trap:** the SEC says letters are indexed by filing date, not release date, and the release date is in the raw text header per Dechow. Finrep says its daily-index count lands on the release day. These conflict and I could not test it. A form.idx scan may miss new releases, so the feed design needs a current-filings route.
- **Access is unproven from routines.** EDGAR returned 403 all session on this host. `salvage_K4` records that sec.gov worked during earlier research, so the block may be specific to the User-Agent or the moment. A routine's User-Agent and cloud host were not tested.
- Borrow availability and fee route at decision time: UNVERIFIED.

T7 passes in form, with the access gap above.

## T8 Test feasibility

- **Post-cutoff letters:** 337 + 335 + 448 + 41 = **1,161 UPLOAD**, Jul 1 to Oct 14, 2026, all form types (VERIFIED, my sum of Finrep's monthly counts). Oct 15 to Nov 2 unknown.
- **Liquid severe subset:** about 6-30 events. This assumes 30-50% periodic-review share, 1.9 letters per thread, 35% liquid, 10-28.2% severe. All UNVERIFIED.
- **Independent windows:** about 86 trading days from Jul 1 to Nov 2. That is about 2 non-overlapping 40-day windows and about 1 non-overlapping 60-day window. Release dates are clustered and unknown at day level.
- **Power:** at about 6-30 events, against about 1,000+ needed, the test cannot separate the effect from zero.
- A contamination-safe test is mechanically possible, since the releases post-date the cutoff. It would need my own form.idx or header pull. It cannot decide the question now.

## Summary

| Check | Result |
|---|---|
| T1 | Fails today: SPREAD, binds, no breaker |
| T2 | Passes the cull; misses the floor at 60 days; count second-hand |
| T3 | Fails: net at or below zero |
| T4 | Fails: unresolved is an empty set; news about 7 months old |
| T5 | Passes |
| T6 | No measured AI addition |
| T7 | Passes in form; feed and access unproven |
| T8 | Too few events and windows |

**One suggestion, not a rescue.** If this is ever reopened, drop the release event and test the letter as an input to a reading of the next 10-K or 10-Q: does the promised change actually appear? That is a different idea and would need its own arithmetic.

## Open load-bearing unknowns

- My own form.idx thread count and liquid-name share (blocked by 403).
- Actual borrow fees on flagged names.
- Whether the Dechow and Ryans drift survives a median 217-day release lag.
- Primary read of Dechow (2016, published), Ryans (2016) and Geiger et al.

## Sources

- Ryans (2021), RAST 26: https://lbsresearch.london.edu/id/eprint/1268/1/comment_letter_text_20191102.pdf
- Dechow, Lawrence, Ryans (Nov 2013 working paper): https://sa.sufe.edu.cn/_upload/article/files/3e/a4/d94a09df43e8be1e30ed1bba4685/f440566c-ac11-48b8-a700-f3a2e219d549.pdf
- Edwards, Klassen, Pinto (2019): https://www.nhh.no/globalassets/departments/accounting-auditing-and-law/seminar-papers/ekp-nhh.pdf
- Yang (2019): https://mitsloan.mit.edu/sites/default/files/inline-files/Real-time%20comment%20letters.pdf
- Johnston and Petacchi (2017): https://ideas.repec.org/a/wly/coacre/v34y2017i2p1128-1155.html
- Geiger et al., GMU summary: https://business.gmu.edu/news/2022-04/how-investors-profit-private-sec-correspondence
- Finrep: https://www.finrep.ai/blog/sec-comment-letters
- PwC: https://viewpoint.pwc.com/dt/us/en/pwc/sec_comment_letters/comment_letter_trends_DM/SEC_comment_letters.html
- EY (11 Sep 2025): https://www.ey.com/content/dam/ey-unified-site/ey-com/en-us/technical/accountinglink/documents/ey-secru28204-251us-09-11-2025.pdf
- Deloitte: https://www.deloitte.com/us/en/services/audit-assurance/articles/a-roadmap-to-sec-comment-letter-considerations-including-industry-insights.html
- SEC on indexing: https://www.sec.gov/answers/edgarletters.htm

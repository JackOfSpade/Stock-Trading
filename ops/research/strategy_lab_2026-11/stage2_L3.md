# Stage 2, L3: Missing analyst reader (arithmetic kill check)

Authored 2026-11-02. Read-only research. Nothing here is a lead or a candidate.

Idea tested: an LLM reads earnings calls of $300M-$2B US firms with 0-2 analysts, scores information content against the initial reaction, and trades the residual both ways, hedged vs IWM or a sector ETF, for 20-60 trading days.

## Verdict: KILL

Three checks fail on evidence:

- **T3 cost against edge.** The mechanical gross edge measured here is +0.26% at 20 days and +0.99% at 60 days. The all-in round trip is 0.84% to 1.47%.
- **T4 next-open survival.** Nothing statistically distinguishable from zero remains after a next-open entry, at any horizon tested.
- **T1 register.** The idea is SPREAD class with no breaker, so it is forced to DO-NOT-ACTIVATE under acute today.

T6 adds that the whole return would have to come from an LLM lift that nobody has measured in this universe. T2, rail d and T8 pass. The idea does not fail on frequency, data access or commission.

The one thing not measured is the LLM's lift itself, because that needs a masked replay. It is the only route back, and it is stated as the single suggestion at the end.

## Summary table

| Check | Result | Key number | Status |
|---|---|---|---|
| T1 Register | FAIL today | SPREAD, 0 of 3 breaker requirements met | VERIFIED text, class is my reading |
| T2 Frequency | PASS | about 800-1,300 readable calls a year | VERIFIED counts, estimated scaling |
| T3 Cost | Rail d PASS, edge FAIL | Commission 0.20%, all-in 0.84-1.47%, gross 0.26-0.99% | VERIFIED own output, IBKR fee schedule UNVERIFIED |
| T4 Next-open | FAIL | 5d +0.11% (t 0.50), 20d +0.26% (t 0.67), 60d +0.99% (t 1.30) | VERIFIED own output |
| T5 Overlap | Marginal | Same edge sentence as B, disjoint cap band | VERIFIED text |
| T6 Baseline | FAIL | Baseline about zero, LLM lift unmeasured | VERIFIED own output |
| T7 Data | PASS with fragility | Transcripts listed for 20 of 32 sampled names | VERIFIED |
| T8 Test feasibility | PASS on count, thin on independence | 808 events, 68 dates, about 2 seasons | VERIFIED |

## T1 Register class

**Class: SPREAD.** The idea is hedged and two-way, with the market factor netted. VERIFIED rule text: `Strategy.md`, Shock Transmission Register, Rev 53. The classification is my reading, since the idea has no register row.

It cannot be SHOCK-NATIVE, because its activation does not require `shock_overlay` in {latent, acute}. Earnings calls happen regardless of the shock.

**Under acute today: forced DO-NOT-ACTIVATE.** The rule applies unless the row carries a breaker meeting all three requirements. None is met today:

| Requirement | Can it be met? |
|---|---|
| (i) Per-industry-group leg | Buildable in principle by grouping stock-vs-hedge correlation by industry group. No such series exists, and a group mapping would need a data source. FMP `company` batch calls were denied on this plan. |
| (ii) Low-side leg keyed to its own breakdown invalidation | No natural form. E's invalidation is a pair correlation below 0.3. L3 has no such invariant, and the measured correlation to IWM is already low: median 0.28, quartiles 0.18 to 0.40, beta 0.71 (n=298, trailing about 120 days, own output). A 0.3 floor would be breached by about half the universe on day one. |
| (iii) Stress replay showing it trips | Not done. It would need (i) and (ii) first, then an owner revision and an adversarial review. E has not cleared this either. |

Side finding: with correlation near 0.28, the IWM hedge removes only about 8% of variance (0.28 squared). The position is close to pure idiosyncratic risk carrying an extra hedge cost. A sector ETF hedge was not measured.

The open question from stage 1, whether a bound strategy still accrues SHADOW and PAPER evidence, also applies here and is unresolved.

## T2 Frequency

Source: Nasdaq earnings calendar, `api.nasdaq.com/api/calendar/earnings?date=YYYY-MM-DD`, 478 weekdays from 2025-01-02 to 2026-11-02, 14 of them empty. Filter: `marketCap` $300M-$2B and `noOfEsts` <= 2.

| Window | Events in cap band | Events with <= 2 estimates | Tickers | Dates |
|---|---|---|---|---|
| 2025 | 4,612 | 2,105 | 686 | 200 |
| 2026 H1 | 2,422 | 1,143 | 668 | 105 |
| 2026-07-01 onward | 1,631 | 808 | 646 | 68 |

All VERIFIED own output. Caveats on the universe:

- `noOfEsts` is an estimate count, not an analyst count, and 1,608 band events had no value and were excluded rather than treated as zero.
- A second measure disagrees. A stratified sample of 115 operating firms from the IBKR screener, read from stockanalysis.com forecast pages, gave 16 with no analyst data, 16 with 1-2 analysts and 83 with 3 or more. That is 28% at 0-2, against 46% by `noOfEsts`.
- The no-data group contains false zeros. LGIH, MMI and HPK showed no analyst data while holding regular calls.
- The cap filter uses the calendar's own market cap field. I did not confirm whether it is point-in-time.

Readable calls per year, scaling by the 20 of 32 transcript rate from T7:

- `noOfEsts` basis: 2,105 x 20/32 = about 1,316.
- Sample basis: 4,612 x 32/115 x 20/32 = about 802.

These scalings are estimates built from VERIFIED inputs.

At a top-quartile residual rule, that gives about 200-330 signals a year, so the declared rate is above 10 and PAPER needs 10 closed trades.

| Annual round trips | Hold | Closed in a 60-day PAPER | Trading days to 10 closed |
|---|---|---|---|
| 12 | 20d | 1.9 | 230 |
| 40 | 20d | 6.3 | 83 |
| 40 | 60d | 0 | 123 |
| 200 | 20d | 31.7 | 33 |
| 200 | 60d | 0 | 73 |

**The floor clears before the 400-day cull at every rate shown.** At the 60-day hold, no trade can close inside the first 60 days. These figures assume even arrival. Real arrivals cluster: peak day 91 events (2026-05-07), then 81 (2026-08-05). At about 80,000 characters per transcript (ODC Q4 FY2026, measured), a peak day is a large read for a once-a-day run. Fleet quota impact was not measured.

**Clearing the floor proves nothing here.** Per-trade standard deviation is 14.0% at 20 days and 26.0% at 60 days (own output):

| Standard deviation | True edge | Trades needed for t = 2 | Standard error at 10 trades | Standard error at 30 trades |
|---|---|---|---|---|
| 14% | 1% | 784 | 4.4% | 2.6% |
| 26% | 1% | 2,704 | 8.2% | 4.7% |
| 14% | 2% | 196 | 4.4% | 2.6% |
| 26% | 2% | 676 | 8.2% | 4.7% |

The PAPER gates would mostly pass or fail on noise.

## T3 Cost at $2,000

| Leg | Cost | Source | Status |
|---|---|---|---|
| Commission, 4 orders (stock in and out, hedge in and out) at $1 minimum | $4 = 0.20% | $0.005 a share, $1 minimum. IBKR's page returned 403, so the schedule comes from `salvage_K4` and is itself marked unverified there. | UNVERIFIED schedule |
| Stock spread, round trip, midday-style | 0.62% median, 1.18% 75th percentile | Abdi-Ranaldo estimator on 299 sampled tickers, last 250 days | VERIFIED own output, noisy, floors at 0 for the lowest quartile |
| Same, 2013 reference | Medians 0.072% to 0.370% across $250M-$2B at $20 and up | SEC DERA small-cap study, Table 4, all stocks in the bin, excludes the first five minutes | VERIFIED, dated |
| Opening premium | Assumed 1x to 3x | One ETF study reports the first five minutes at nearly 3x. I found no US small-cap figure. | UNVERIFIED |
| IWM spread | about 0.02% | Retail source quoting $0.01-$0.03 a share | UNVERIFIED |
| Borrow on the short side, 40-day hold | 0.08% at 0.5%/yr, 0.16% at 1%, 0.80% at 5%, 3.18% at 20% | Arithmetic | VERIFIED arithmetic |

Borrow availability in the cap band from the IBKR screener: 655 of 1,767 listings above a 1% fee, and 205 above 5%. The denominator includes SPACs, preferreds and funds. VERIFIED counts, not specific to low-coverage names.

All-in long-side round trip, commission + spread x opening multiple + IWM:

| Spread basis | 1x | 2x | 3x |
|---|---|---|---|
| Own median 0.62% | 0.84% | 1.47% | 2.09% |
| Own 75th percentile 1.18% | 1.40% | 2.58% | 3.77% |
| SEC 2013, $250-500M, $40+ (0.37%) | 0.59% | 0.96% | 1.33% |
| SEC 2013, $500M-$1B, $20-40 (0.125%) | 0.35% | 0.47% | 0.59% |

Working range: 0.84% to 1.47%, plus borrow on shorts. The dated 2013 figures describe all stocks in a bin and exclude the opening minutes, so they are a floor rather than the estimate. Nasdaq reports that losing coverage widens spreads, which points the same way.

**Rail d passes:** 0.20% commission against the 1.8% ceiling (`state.arsenal_rails.max_roundtrip_commission_pct` = 1.8, VERIFIED).

Market-order evidence from one name, one day: FLXS on 2026-11-02 opened with 878 shares at 73.80, then had no trade for 13 minutes. The next print was 73.64 to 73.56, and consecutive later prints bounced as much as 0.75% (73.26 to 72.71). VERIFIED IBKR 1-minute bars. This is an anecdote, not a sample. IBKR after-hours quotes were far too wide to use for spreads and were discarded (for example CIX bid 15.05, ask 53.07).

### Best-supported gross edge per trade

| Source | Period | Gross per trade | Usable? |
|---|---|---|---|
| Own baseline, follow reaction, hedged, next-open | 2025-01 to 2026 | 20d +0.26%, 60d +0.99%, both insignificant | Yes, most recent and closest to the design |
| Demers and Vega, press-release net optimism plus SUE, small firms | 1998-2006 | 22% vs 13% annualized long-short, about 5.5% per 60 days, so about 2.75% per leg | Pre-dates the decay, press releases not calls, not LLM |
| Price, Doran, Peterson, Bliss | 2004-2007, about 2,800 calls | Tone predicts 60-day returns, concentrated in non-dividend payers. Abstract only, no return figure seen. | Dated, lexicon-based, not low-coverage specific |
| LLM on calls vs lexicon, next-month long-short | not seen | 8.4% vs 4.2% a year, about 0.7% a month long-short, about 0.35% per leg | UNVERIFIED, a vendor blog with no primary source, universe not stated |
| Martineau 2022 | to 2019 | Analyst surprises fail to predict 60-day returns since 2016 even for microcaps. Random-walk surprises in microcaps persist no more than five days. | VERIFIED PDF text |
| Subrahmanyam 2025 via UCLA Anderson Review | 2001-2024 | Drift factor t 2.18 with microcaps, 1.43 without | VERIFIED secondary |

Only the 1998-2006 figure clears cost. Every recent measurement sits at or below it.

## T4 Next-open survival

Design: the 298 tickers are a seeded random draw from the low-estimate universe. Nearly all calendar rows (3,976 of 4,056) have no reliable time, so the reaction window is close(i-1) to close(i+1) and entry is the open of i+2. That matches reading a transcript after the reaction on a once-a-day decision. Returns are net of IWM over the same interval, signed by reaction direction.

1,355 events, 298 tickers, 20-22 months of events. Median absolute reaction 5.61%. Median absolute overnight gap at entry 0.77%.

| Group | Horizon | n | Mean | Median | t | Month-cluster t |
|---|---|---|---|---|---|---|
| All | 5d | 1,319 | +0.11% | +0.17% | 0.50 | 0.83 |
| All | 20d | 1,311 | +0.26% | +0.30% | 0.67 | 0.42 |
| All | 40d | 1,295 | +0.01% | +0.20% | 0.01 | 0.83 |
| All | 60d | 1,180 | +0.99% | +0.79% | 1.30 | 1.12 |
| Top quartile reaction (>= 11.1%) | 5d | 333 | +0.48% | +0.43% | 0.83 | 0.62 |
| Top quartile | 20d | 332 | +0.83% | +0.88% | 0.86 | 0.14 |
| Top quartile | 40d | 325 | +0.14% | -0.01% | 0.10 | 0.05 |
| Top quartile | 60d | 296 | -0.73% | +1.08% | -0.40 | -0.78 |
| Top quartile, $300-700M | 20d | 148 | -0.24% | +1.53% | -0.17 | -1.16 |
| Top quartile, $700M-$2B | 20d | 184 | +1.69% | +0.72% | 1.29 | 1.52 |
| Follow EPS surprise | 20d | 1,187 | +0.24% | -0.04% | 0.59 | not computed |
| Follow EPS surprise | 60d | 1,071 | +0.56% | +0.03% | 0.71 | not computed |

Asymmetry, reported because it is the strongest evidence against this verdict:

| Group | Horizon | n | Signed mean | Median | t | Month-cluster t |
|---|---|---|---|---|---|---|
| Top quartile UP | 20d | 160 | +3.21% | +1.35% | 2.48 | 2.04 |
| Top quartile UP | 60d | 138 | +1.40% | -1.63% | 0.58 | 0.81 |
| Top quartile DOWN, shorted | 20d | 172 | -1.38% | +0.87% | -0.98 | -1.11 |
| Top quartile DOWN, shorted | 60d | 158 | -2.59% | +2.27% | -0.99 | -1.31 |

This does not rescue the idea:

- It is one significant cell among many tested.
- It decays by 60 days.
- The universe itself runs +1.09% mean and +0.03% median at 20 days before any signal, so part of it is skew and survivorship.
- The short side, which the idea needs, has a negative mean.
- A long-only version would be DIRECTIONAL-LONG-BIASED, which binds, and would be B in a smaller band.

Limits of this study:

- Prices come from tickers still quoted today, so delisted losers are under-represented (survivorship).
- Returns are not dividend-adjusted.
- The `noOfEsts` universe is broader than strict 0-2 coverage, and it is not filtered for firms that actually held a call.
- 22 months is short, and overlapping events inflate the plain t statistics, which is why month-clustered t is shown.
- Seasons differ: at 60 days by quarter, +0.76, -1.59, +4.04, -1.05, +2.41, +0.36, +3.52 (%).

**Result: the mechanical effect is a day-0 reaction with nothing dependable left after next open.** This tests the reaction-following baseline, not the LLM residual.

## T5 Overlap

- **B:** the closest overlap and an uncomfortable one. B's edge sentence is judging whether the immediate reaction to a public event over- or under-shot its information content, resolved over weeks, entry within 10 trading days, up to about 60 days (`strategy/04_strategy_b.md`). L3 is that sentence applied to smaller firms.
  - It differs on cap band (B floor $2B, L3 ceiling $2B, so the universes are disjoint), on the coverage screen, and on being hedged and two-way.
  - B needs a >=5% event-day move and L3 as stated does not, but L3's largest signals would be the same event type.
  - Rail (b) material difference is arguable, and a reviewer could read L3 as a B parameter change.
- **A:** pre-event, no overlap. **C:** options around FOMC, no overlap. **D:** long-horizon large-cap core, no overlap, though both read transcripts. **E:** same-group large-cap pairs, no overlap in universe.
- **Dead ideas:** not a restatement of first-hop drift, second-hop transmission, defensive rotation, index convexity or momentum participation. `state.strategy_candidates` holds only F, G, H and I, and I's cooldown to 2027-01-17 is on a different archetype. VERIFIED query.
- **Rail (a) precedent:** the I rejection says an edge used only to select within a classical wrapper fails, and that LLM news predictability is short-horizon, small-cap and weakest on the short side. L3's measurable part is PEAD, and it needs 20-60 days and a short leg.

## T6 Mechanical baseline

Non-AI versions (own output, gross, hedged, next-open):

- Follow reaction: +0.26% at 20d, +0.99% at 60d.
- Follow EPS surprise: +0.24% at 20d, +0.56% at 60d.
- Top quartile reaction: +0.83% at 20d, -0.73% at 60d.

None is significant, and all sit at or below the 0.84-1.47% cost.

What the AI must add: its signal must separate winners from losers well enough to earn about 1-1.5% net of a baseline near zero. That means a gross of about 2-3% per trade at 20-60 days, on both sides, in a universe where the measured standard deviation is 14-26%.

**The AI's lift here is unmeasured.** I found no source comparing an LLM with a lexicon or mechanical baseline on 0-2 analyst, sub-$2B firms. The closest paper found, Ghosal 2026 on SSRN, could not be opened. The S&P 500 PEAD work noted in a 2026 Springer review is large-cap only and that review itself flags the small-cap gap. Stage 0 also found no post-cutoff or masked LLM test. So the AI's contribution is an assumption.

There is also a structural doubt. Calls with zero or one analyst have thin Q&A, and Q&A is where Price et al. found the incremental power. One Booth workshop snippet says small caps struggle to get analysts on calls (search excerpt only, UNVERIFIED).

## T7 Data and execution

| Input | Route | Result |
|---|---|---|
| Earnings dates, caps, estimate counts | Nasdaq calendar API | Worked with the declared research User-Agent. 98% of rows have no time. |
| Transcripts | stockanalysis.com `/stocks/{t}/transcripts/` | 20 of 32 sampled low-coverage names list 2025-26 transcripts. 12 of 32 list none. Full text confirmed for ODC Q4 FY2026, about 80,000 characters, no login. Benzinga, Webull and Quartr also carry ODC. |
| Analyst counts | stockanalysis.com forecast pages | Text parse only, with false zeros |
| Prices | Nasdaq historical API | All 300 sampled tickers plus IWM parsed. 298 tickers produced usable events. |
| FMP analyst, calendar history, market cap | MCP | All denied on this plan |
| EDGAR form index | curl with the prescribed User-Agent | HTTP 403, "Undeclared Automated Tool". Not retried with other identities. |

The 12 names with no listed transcript may or may not hold calls (ATLO appears to, per MarketBeat and Quartr). Publication latency after a call was not measured. Seeking Alpha states about six hours, UNVERIFIED for these names. No licensed or contractual transcript feed was established, and I did not check the terms of use of the sources above.

Human steps beyond the confirm tap: none identified. Size is not a constraint: median dollar ADV $6.9M, 25th percentile $3.3M, against $2,000. A market order at the open in a name with minutes between trades is exposed to whatever the opening print is, and the system cannot react intraday.

## T8 Test feasibility

- Post-cutoff events (2026-07-01 onward, <= 2 estimates): 808 across 646 tickers on 68 dates. VERIFIED.
- With a listed transcript, at 20 of 32: about 505. Estimate.
- Priced sample: 262 events on 50 dates, 218 with a 20-day outcome, 87 with a 60-day outcome. VERIFIED.
- Independent windows: about 86 trading days, so 4 non-overlapping 20-day windows and 1 60-day window, spanning about 2 earnings seasons. Within a season, events share market and factor shocks, so the effective sample is far below the event count.
- Post-cutoff baseline: 20d +1.32% (t 1.57, month-cluster t 3.45 on 3 months), 60d +3.52% (t 1.96, 87 events, only 2 months). Too few months to read. Compare 2025 Q1 and Q2 at 20d: -0.92% and -0.53%.

A masked LLM replay is feasible on count, weak on independence.

## One suggestion, not a rescue

If this is ever reopened, run one masked replay before anything else. Score the roughly 218 post-cutoff transcripts with outcomes, with ticker and date masked, and test whether the score beats the sign-of-reaction baseline after 1.5% cost on both sides. A null result closes L3 for good. Until that exists, L3 has no measured return driver.

## Method notes and disclosures

- Scripts and raw data are in the session scratchpad, not the repo.
- An early request to Nasdaq carrying a browser-style User-Agent was refused by this session's permission classifier. The full calendar and price pulls then used the declared `strategy-research jacksterwu-research` agent. Before that refusal, one Nasdaq price probe and the stockanalysis.com coverage and transcript fetches used `Mozilla/5.0 (Macintosh) strategy-research`, which has a browser-style token as well as the research label. One later stockanalysis.com page used the declared agent.
- Tavily returned 429 partway through, so later searches used WebSearch.
- No orders, alerts, watchlists, git actions or BigQuery writes were made. The IBKR screener was run through `preview_screener`, which saves nothing.

## Sources

- SEC DERA, small-cap liquidity study, 2013 data: https://www.sec.gov/marketstructure/research/small_cap_liquidity.pdf
- Martineau, Rest in Peace PEAD, CFR 2022: https://cfr.ivo-welch.org/published/papers/martineau2021rest.pdf
- UCLA Anderson Review on Subrahmanyam 2025: https://anderson-review.ucla.edu/is-post-earnings-announcement-drift-a-thing-again
- Demers and Vega, INSEAD WP 2010/33: https://flora.insead.edu/fichiersti_wp/inseadwp2010/2010-33.pdf
- Price, Doran, Peterson, Bliss, JBF 2012: https://www.sciencedirect.com/science/article/abs/pii/S0378426611002901
- Nasdaq Economic Institute, 2026-10-01: https://www.nasdaq.com/economic-institute/the-print/quarter-of-companies-no-analyst-coverage
- Springer review, 2026: https://link.springer.com/article/10.1007/s44163-026-01334-9
- Vendor blog, UNVERIFIED LLM figures: https://medium.com/@axionquant/how-to-turn-earnings-call-transcripts-into-a-signal-345857680b0e
- Nasdaq calendar and historical APIs, stockanalysis.com, IBKR connector, `state.strategy_candidates`, `state.arsenal_rails`, `Strategy.md` Rev 53, `strategy/04_strategy_b.md`.

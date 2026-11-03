# Stage 2, L5: AI-consensus overnight fade

As of 2026-11-02. Read-only working file, not policy.

**Verdict: KILL.**

**Every book result below is POST HOC.** The hypothesis came from the same book it is tested on, so these numbers cannot confirm it.

## Why it dies

1. **The AI adds nothing measurable (T6, rail a).** A non-AI rule, fading any universe name with a day-0 SPY-excess move of at least 2%, earns +0.428% per trade on the same 7 dates. The unanimous fade earns +0.574%. The paired difference is +0.145% (t = 0.16). Unanimous votes share the sign of the day-0 move 69% (UP) and 76% (DOWN) of the time, and many of the headlines simply report the move. The driver is a classical reversal bet that the votes merely select, which is the ground that rejected F, H and I.
2. **The stated mechanism has the wrong sign (T4).** The idea says agreement pushes the open too far. Where the open did move with the vote, the fade earned -0.100% at 1 day, positive on 2 of 7 dates. That subset also cannot be chosen, because the market order is crafted before the open prints.
3. **It cannot be active today (T1).** It is SPREAD class, bound under acute, and has no breaker.
4. **It needs a human step beyond the tap (T7).** Every short leg needs an operator short-inventory reading. Almost all the return sits on the short side.

The sample is too small to prove the edge is zero, and this kill does not rest on it being zero. It rests on points 1 to 4. The one result that survives is unanimous versus non-unanimous, reported in T3 and T6.

## Data

| item | value | status |
|---|---|---|
| Calls scored | 1,078 on 9 call dates, 2026-10-20 to 2026-11-01 | VERIFIED, query Q1 |
| Directional calls (UP or DOWN) | 479 | VERIFIED, Q4 |
| Unanimous directional calls (agreement 1.0, 5 of 5) | 231 calls, 143 ticker-days | VERIFIED, Q4 |
| Unanimous calls realized | 1d: 160 calls on 7 dates. 3d: 133 on 5. 5d: 71 on 3 | VERIFIED, Q4 |
| Marks | 2026-10-06 to 2026-10-30, 19 sessions, 41 tickers | VERIFIED, Q5 |
| Universe | 40 fixed large caps | VERIFIED, `bigquery/261_news_reaction_paper_book.sql` |

Conventions:
- **Fade sign:** short a modal-UP call, long a modal-DOWN call. FLAT calls are excluded.
- **Return:** SPY-excess, open to open, entry at the first open after `call_date`. This is `state.news_reaction_call_returns`, so every number is already after a next-open entry.
- **Weighting:** several headlines on one ticker-date are averaged to one position. Names are equal-weighted within a date, then dates are equal-weighted.
- **Tests:** t on date means, plus an exact two-sided sign-flip p over all sign assignments.
- **Hedge:** a 1.0 beta to SPY is assumed. High-beta names leak market moves into these numbers, and that was not corrected.

## Main result: date-clustered, SPY-excess, fade sign (POST HOC)

Per-date values in percent, in order of call date (10-20, 21, 22, 25, 26, 27, 28). Per-date values from Q2, statistics computed in Python from those values. VERIFIED as arithmetic.

| group | horizon | per-date fade return | dates | mean | t | positive | sign-flip p |
|---|---|---|---|---|---|---|---|
| Unanimous | 1d | 2.159, 0.456, 0.052, -0.120, -0.478, -0.330, 2.278 | 7 | **+0.574** | 1.31 | 4/7 | 0.344 |
| Unanimous | 3d | 2.568, 0.186, 2.299, -1.096, 0.792 | 5 | **+0.950** | 1.40 | 4/5 | 0.312 |
| Unanimous | 5d | -1.748, -0.595, -2.954 | 3 | **-1.766** | -2.59 | 0/3 | 0.250 |
| Non-unanimous | 1d | -0.042, -0.232, 0.596, 0.248, -1.101, -0.235, 1.094 | 7 | **+0.047** | 0.18 | 3/7 | 0.875 |
| Non-unanimous | 3d | -0.374, -0.458, 1.746, -1.163, 0.521 | 5 | **+0.054** | 0.11 | 2/5 | 0.875 |
| Non-unanimous | 5d | 0.058, -2.531, -5.647 | 3 | **-2.707** | -1.64 | 1/3 | 0.500 |

Unanimous minus non-unanimous, paired by date:

| horizon | dates | mean | t | positive | sign-flip p |
|---|---|---|---|---|---|
| 1d | 7 | +0.527 | 1.44 | 4/7 | 0.203 |
| 3d | 5 | +0.895 | 1.72 | 5/5 | 0.062 |
| 5d | 3 | +0.941 | 0.68 | 2/3 | 0.500 |

Independent windows, not just dates:

| horizon | call dates | non-overlapping windows |
|---|---|---|
| 1d | 7 | 7 |
| 3d | 5 | 2 |
| 5d | 3 | 1 |

The 5-day row is a single market window.

Robustness of the unanimous 1d mean:

| cut | n | mean | t | note |
|---|---|---|---|---|
| Winsorized at +/-5% (Q3) | 7 | +0.550 | 1.51 | |
| Date medians (Q3) | 7 | +0.752 | 2.05 | sign-flip p 0.078 |
| Headline published after that date's 16:00 ET close (Q2) | 7 | +0.605 | 1.14 | |
| Dropping 10-20 and 10-28 | 5 | **-0.084** | -0.52 | those dates hold 6 and 8 names |
| Short side only (fade UP) | 7 | +0.908 | 1.37 | |
| Long side only (fade DOWN) | 7 | +0.138 | 0.35 | |

The mean depends on two thin dates. The window is also one earnings season, under one acute shock.

## T1 Register class: FAIL today

- **Class: SPREAD.** Each position is hedged against SPY, so the market factor is netted. It is not a pair. VERIFIED against the class text in `strategy/02_regime_router.md`.
- **Status under acute: binds.** A newcomer's row defaults to binds, and no SPREAD row carries a gate today. E itself has bound since Rev 53. Forced to DO-NOT-ACTIVATE.
- **SHOCK-NATIVE is unavailable.** Activation does not require `shock_overlay`, and frequency is daily, not per shock event.

The three breaker requirements:

| requirement | can it be met? |
|---|---|
| (i) Per-industry-group leg | Buildable in principle, for example on residual correlation by group. Nothing exists. The rail was written for pairs, and single names against SPY have no pair population. |
| (ii) Low-side leg keyed to its own breakdown invalidation | No such invalidation exists. A 1-5 day fade has no defined relationship that can break down, so one would have to be invented. |
| (iii) Stress replay showing it trips | A price-only gate can be replayed. The votes cannot: they start 2026-10-20, and regenerating older ones with a June 2026 cutoff model is contaminated. A replay would test the gate, not the strategy. |

A gate would also need an owner revision and adversarial review. None of this can happen today.

## T2 Frequency: PASS

- **Source:** Q4, 143 unanimous directional ticker-days over 9 call dates, or 15.9 per date (231 calls, 25.7 per date). VERIFIED.
- **Annual candidates:** about 250 firings gives about 3,970 ticker-days. The 250 is UNVERIFIED, inferred from D1's Sun-Thu cadence.
- **A cap is required.** The idea states none, and 16 names plus hedges is about 32 orders per day. As an assumption, a cap of 1 position per day gives 250 round trips per year.
- **Closed trades in a 60-day PAPER:** 60 at a 1-day hold with one position per day. 12 at a 5-day hold with one slot. Declared annual is at least 10, so the floor is 10. It clears, well before the 400-day cull.
- **Not checked:** the 2 regime cells gate depends on the market. The whole sample so far sits in one shock state.

## T3 Cost: rail d PASS, net edge not distinguishable from zero

All-in round trip at $2,000 stock notional plus a $2,000 SPY hedge:

| leg | low (Tiered) | central (Fixed) | high (Fixed) | status |
|---|---|---|---|---|
| Stock commission | 0.035% | 0.10% | 0.10% | VERIFIED: IBKR page, $1.00 Fixed and $0.35 Tiered minimum per order |
| SPY hedge commission | 0.035% | 0.10% | 0.10% | same |
| Stock spread and slippage | 0.05% | 0.075% | 0.10% | Project assumption, 5-10 bp in the book memo |
| SPY spread and slippage | 0.01% | 0.015% | 0.02% | UNVERIFIED, my assumption |
| Borrow, 1 to 5 days at 0.43% a year | 0.001-0.006% | same | same | Rate is the project's sampled 0.25-0.43%, not checked per name |
| **Total** | **0.13%** | **0.29-0.30%** | **0.32-0.33%** | computed |

The project's measured equity-pair round trip is 0.42% (`ops/research/shock_native_candidate_dossier_2026-10-19.md`), used as the stress case. I did not trace that figure to its original measurement. Which plan the account is on was not checked, so the Fixed case is treated as central.

Rail d: commission of 0.20% (Fixed) against the 1.8% ceiling (`state.arsenal_rails`, VERIFIED). Passes easily.

Against the best-supported gross edge, unanimous 1d +0.574% (UNVERIFIED as a real edge, t = 1.31):

| cost | net | t |
|---|---|---|
| 0.30% | +0.27% | 0.64 |
| 0.42% | +0.15% | 0.36 |

- The 3d gross of +0.950% clears costs on point estimate, on 2 independent windows.
- The 5d gross of -1.766% does not.
- Dropping the two thin dates gives -0.084% gross, below any cost.
- At +0.27% net and the observed date sd of 1.16%, t = 2 needs about 75 dates. At +0.10% it needs about 541.
- At 1 position per day, the drag is about $1,500 a year.

## T4 Next-open survival: FAIL on mechanism

The book already enters at the next open, so nothing here is a day-0 fill. But the premise is that agreement pushes the open too far, and that needs a gap in the direction of the vote.

| measure | 1d mean | t | positive | note |
|---|---|---|---|---|
| Fade sign x SPY-excess gap, unanimous | -0.288 | -0.95 | 2/7 | The open moves slightly with the vote |
| Gap moved WITH the vote (the idea's own case) | **-0.100** | -0.20 | 2/7 | 3d +0.569, 5d -1.463 |
| Gap moved AGAINST the vote | +1.213 | 2.80 | 6/7 | sign-flip p 0.031 |

- All the 1-day return comes from names where the open had already gone against the vote. That is continuation of the gap, not a fade of an overshoot.
- Neither split can be traded. Orders are MARKET at the open and are crafted before it prints. It is also one of many cuts on 7 dates.
- **Votes are mostly not overnight reads.** D1 votes around 22:15 UTC, about 18:15 ET on most runs (Q6), so news after that is unseen. 143 of 231 unanimous directional calls (62%) were published after that date's close. The rest had up to a session of trading behind them.

## T5 Overlap: partial, not decisive

- **Lead J:** L5 is J's inverse, on the same votes and the same book. J's latest row records net_mu -0.544% and excess vs SPY -0.076% (Q7, VERIFIED). SL1 will propose closing J at its 2026-12-02 fire if date-clustered excess is still <= 0 over at least 20 dates.
- **B:** the long leg (buying after bad news) resembles B's post-event overreaction. All 40 names clear B's cap and ADV floors (UNVERIFIED per name; they are liquid large caps). B needs a move of at least 5%, while the mean unanimous-DOWN day-0 excess move is -2.2%, so overlap is a minority. Not counted.
- **A, C, D, E:** no structural overlap. E is same-group pairs. L5 has no pair.
- **Dead ideas and cooldowns:** `state.strategy_candidates` holds F, G, H and I only. F and G cooled off 2026-10-25, H on 2026-11-01. I runs to 2027-01-17, on a different archetype. None bars this idea.

## T6 Mechanical baseline: FAIL

| non-AI rule (no LLM) | horizon | dates | mean | t | positive |
|---|---|---|---|---|---|
| Fade day-0 excess move >= 2%, same 7 dates | 1d | 7 | +0.428 | 0.42 | 4/7 |
| Fade day-0 excess move >= 2%, all dates | 1d | 16 | +0.272 | 0.57 | 9/16 |
| same | 3d | 14 | -0.145 | -0.21 | 6/14 |
| same | 5d | 12 | -1.819 | -2.54 | 3/12 |
| Fade overnight gap >= 1%, same 7 dates | 1d | 7 | -0.599 | -0.70 | 2/7 |
| Fade overnight gap >= 1%, all dates | 1d | 17 | -0.235 | -0.49 | 8/17 |
| same | 3d | 15 | -0.678 | -1.06 | 5/15 |
| same | 5d | 13 | -1.184 | -1.27 | 4/13 |

Source: Q8 and Q9. Call dates are matched to the last session on or before the call date, so 10-25 maps to 10-23.

**What the votes appear to be reading (Q10):**

| modal direction | agreement | n | mean day-0 excess | day-0 sign matches vote | price words in headline |
|---|---|---|---|---|---|
| UP | unanimous | 138 | +1.373% | 68.8% | 41.3% |
| UP | not unanimous | 140 | +0.580% | 52.1% | 27.1% |
| DOWN | unanimous | 79 | -2.202% | 75.9% | 46.8% |
| DOWN | not unanimous | 71 | -1.226% | 76.1% | 35.2% |

Sample headlines from the unanimous set include "Stock Jumps 2.8% - Here's What Happened" and "Shares Up 3.6% - Time to Buy?" (VERIFIED, Q11). The price-word share comes from a rough regex that also counts any percentage in a headline, so it can miss or over-count. It is not a precise rate.

**What the AI would have to add:** return beyond fading the same price move. Measured:
- Against the day-0 fade: +0.145% (t = 0.16, 3/7 positive).
- Against the gap fade: +1.173% (t = 1.25, 5/7 positive).
- Against non-unanimous votes: +0.527% at 1d and +0.895% at 3d, the latter 5/5 positive with p 0.062.

The last line is the only thing pointing toward information in the votes. But unanimity also tracks a larger day-0 move, so it may be measuring the size of the move. That was not separated here. This is one of many post hoc cuts, on 7 dates.

**Rail a fails either way.** The vote is used as a contrary marker of salience, not as narrative synthesis, contradiction surfacing or cross-disciplinary reading. Even if the sign holds, the return is a reversal premium the AI selects.

**External evidence is thin and leans the other way:**
- Lopez-Lira and Tang (JFE 2026): prices drift in the direction of the LLM's read for 1-2 days, the opposite of a fade. Strategy Sharpe fell from 6.54 in late 2021 to 1.22 in early 2024 as adoption rose, read as better efficiency, not overshoot. Via the Swedroe summary and the RePEc abstract, VERIFIED at snippet level only.
- Lou, Polk and Skouras: no close-to-close short-term reversal in their value-weight, non-microcap sample, though reversal appears in the overnight and intraday pieces. VERIFIED at snippet level.
- SSRN 4307675: large daytime returns followed by strong-sentiment overnight news lead to reversal. It uses no LLM consensus, which makes it a classical baseline. Snippet only, the page fetch failed.
- One targeted search found no study showing LLM unanimity causes an opening overshoot. That is absence in one search, not proof of absence.

**The causal story cannot be observed from this data.** Five Sonnet reads with one prompt are our own agreement, not the market's. We have no data on what other participants' models read.

## T7 Data and execution: FAIL on the human step

- **Inputs:** automated. Google News RSS, Nasdaq RSS and Nasdaq historical are key-less and already run in D1 through `scripts/paper_book.py`.
- **Human step:** `Operating_Protocols.md` makes short-availability a documented operator step, because no connector exposes borrow data. The operator reads the IBKR Client Portal inventory and reports back, and the lead J row records this as fail-closed. The protocol calls it the same shape as a confirm tap, but it is a separate human action. Under the limit given for this check (confirm tap and deposits only), it fails.
- **It cannot be designed away cheaply.** UP fades are shorts and DOWN fades need a short SPY hedge. Going long-only drops the short side, which carries +0.908 of the return against +0.138.
- **Also:** about 32 orders a day would mean 32 confirm taps uncapped. Five Sonnet reads per headline on about 120 headlines a day draw on the fleet's shared quota, already flagged by SL1.

## T8 Test feasibility: possible, but only as a new test

- **Post-cutoff events:** all of them, since the book started 2026-10-20. 231 unanimous directional calls, 143 ticker-days. VERIFIED.
- **Independent units today:** 7 dates and 7 windows at 1d, 5 dates and 2 windows at 3d, 3 dates and 1 window at 5d.
- **Contamination:** safe by construction, timestamped before entry.
- **Limitation:** post hoc on this sample, one earnings season, one shock state. A valid test needs dates after this one, with the fade sign fixed in advance.
- **Time needed:** about 75 dates, or about 15 weeks at 5 firings a week, for t = 2 if the +0.27% net were real. UNVERIFIED projection.

## Scorecard

| check | result | deciding number |
|---|---|---|
| T1 Register | FAIL today | SPREAD, binds, no breaker |
| T2 Frequency | PASS | 15.9 ticker-days per date, 60 closed trades at cap 1 per day |
| T3 Cost | Rail d PASS, net not distinguishable from zero | +0.27% net, t = 0.64 |
| T4 Next-open | FAIL on mechanism | -0.100% where the open moved with the vote |
| T5 Overlap | Partial | Inverse of lead J |
| T6 Baseline | FAIL | AI adds +0.145%, t = 0.16 |
| T7 Execution | FAIL | Operator short-inventory step |
| T8 Test | Feasible, prospective only | 7 / 5 / 3 dates |

## One suggestion

The votes are stored, so this costs nothing to re-run at SL1's 2026-12-02 fire: the same query on dates after 2026-11-02 only, with the fade sign fixed now. That would settle whether the unanimous versus non-unanimous gap is real. It would not change this verdict, because T1, T6 and T7 do not depend on it.

## Queries

All run through `execute_sql_readonly`, project `stock-trading-498512`, on 2026-11-02.

- **Q1** Per call date: count, tickers, direction counts, unanimous counts, realized counts from `state.news_reaction_call_returns`.
- **Q2** Per variant and call date, from `state.news_reaction_call_returns` joined to `state.news_reaction_marks_curated` for the gap: first average to ticker, then `AVG(s*x)`, where `s = IF(direction='UP',-1,1)`, `x = ret_Nd - spy_ret_Nd`, `FLAT` excluded. Variants: unanimous (`agreement_score = 1`), non-unanimous, by side, post-close (`published_ts` at or after 16:00 New York on `call_date`), gap with the vote (`gapx*s < 0`), gap against (`gapx*s >= 0`). `gapx` = entry open over prior close, less the same for SPY.
- **Q3** Unanimity by date: median and +/-5% winsorized fade return at 1d.
- **Q4** Totals: calls, directional, unanimous, ticker-days, realized counts and dates by horizon, plus `state.arsenal_rails`.
- **Q5** Marks range and outliers from `state.news_reaction_marks_curated`.
- **Q6** Timing per call date: `call_ts` range, headline age, count published after that date's close.
- **Q7** `events.strategy_research_leads` for the J lead, and `state.news_reaction_paper_book_readiness`.
- **Q8** Non-AI day-0 fade: per day-0 session, `-SIGN(d0x)*x` for names with `ABS(d0x) >= 0.02`, entry at the next open, marks only.
- **Q9** Non-AI gap fade: per entry date, `-SIGN(gapx)*x` for names with `ABS(gapx) >= 0.01`.
- **Q10** Vote against day-0: by direction and unanimity, mean day-0 excess, share with matching sign, regex share of price words in the headline.
- **Q11** Largest unanimous 1d moves with headlines.

Web sources: IBKR stock commissions (interactivebrokers.com/en/pricing/commissions-stocks.php), Swedroe summary (larryswedroe.substack.com/p/can-chatgpt-forecast-stock-price), RePEc abstract for Lopez-Lira and Tang, Lou, Polk and Skouras (personal.lse.ac.uk/polk/research/TugOfWar.pdf), SSRN abstract 4307675.

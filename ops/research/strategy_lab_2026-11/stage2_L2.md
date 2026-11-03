# Stage 2 arithmetic check, L2: refinancing and covenant reader

Working file, not policy. 2026-11-02. VERIFIED means seen in a source or in my own script output. UNVERIFIED means assumed or not found.

## Verdict: KILL

Four checks fail on evidence: T1, T3, T4 and T6.

1. **It cannot be active today.** It would be a SPREAD row, and no SPREAD breaker exists. Its long-improver leg would bind regardless.
2. **Gross edge does not cover cost.** On 620 tradable filing events from 2023 to 2026, the short earned +0.9% to +3.2% gross per trade (20-60 days). The sample's mean all-in cost was 2.2-2.7%, before a 0.56-0.84% SGOV hurdle.
3. **The short return sits in expensive borrow.** The 82% of trades with a fee under 1% lost money gross over 40 and 60 days. The over-10% bucket earned +6.4% and +19.4% gross, but its mean fee is 77%/yr.
4. **Newly appearing covenant language adds nothing after next-open entry at 20-40 days.** That is the mechanical stand-in for "worsened". Its 20-40 day difference versus compliant filers has the wrong sign and is insignificant. Repeat filers, which is distress level and not change, drive the only significant number. That is a classical factor, so it fails rail (a).

**Borrow, the suspected killer, is only half the story.** Median borrow is cheap (0.41%/yr) and rail (d) passes easily. The kill is that the effect only pays where borrow is not cheap, which matches Muravyev, Pearson and Pollet.

## Method for my own event study (all VERIFIED script output unless noted)

- **Events:** EDGAR full-text search (EFTS), 10-Q and 10-K, 2023-01-01 to 2026-11-02, no amendments.
- **Treated (T):** any of `"was/were not in compliance" "financial covenant"`, `"obtained/received a waiver" "covenant"`, `"covenant relief"`, `"forbearance agreement"`, `"substantial doubt" "financial covenant"`. That gave 2,514 ticker-date events.
- **Control (C):** `"we were in compliance with" "financial covenants"`, capped at 300 hits per quarter, 4,188 events. Prices were pulled for T tickers and a random 300 C-only tickers.
- **Subsets:**
  - `new` = first T hit for that ticker in 365 days, my stand-in for "worsened". It is left-censored in 2023, so every first hit that year counts as new.
  - `breach` = the was/were-not-in-compliance or waiver phrases.
  - Tradable = price at or above $3 and 20-day ADV at or above $2M.
- **Prices:** Nasdaq historical API (split-adjusted, no dividends). 1,564 of 2,492 T events with a usable ticker have prices.
- **Entry:** open of t0+2, because filing time is unknown and an after-close filing is only read the next day. Hold H trading days to close.
- **Hedge:** `x` = stock minus IWM. `bx` = stock minus 60-day beta times IWM. A short earns the negative of these.
- **Inference:** quarter-clustered t on quarter means, winsorized at -100%/+150%.
- **Scripts and raw output:** `/private/tmp/claude-501/-Users-jack--claude-spares-spare-YOT00C/df96b944-d471-4a74-83f8-15366b3d403b/scratchpad/work/` (ev2.py, px.py, study.py, study2.py, s3.py, study_out.txt, usa.txt).

**Bias warnings:**
- **Survivorship.** 37% of T events have no prices, and 326 of the 1,028 requested tickers returned no data. Delisted and bankrupt names are probably among them, which understates the short. Magnitude UNVERIFIED.
- **Proxy.** Phrase hits are a mechanical stand-in. No LLM classified anything, so the LLM's increment is unmeasured, not measured as zero.
- **Boilerplate.** Some hits are boilerplate. The broader phrase sets catch names such as MMM, FCX and RSG.
- **Look-ahead in fees.** Borrow fees are the 2026-11-02 IBKR snapshot applied to all history, not the fee at entry. A name that fell may be expensive only now, so sorting on today's fee is look-ahead.

## T1 Register class: FAIL today

- **Class:** a hedged short against an ETF is SPREAD. With "clear improvers" long it is still SPREAD only if the book is netted. VERIFIED: Strategy.md `### Shock Transmission Register` says "No `SPREAD` row carries one today, so E binds". `state.shock_transmission_status` shows E as `binds: class SPREAD`. A candidate with no row reads `binds: no register row (default)`.
- **Regime:** M1R 2026-11-02 reads "shock_overlay stays acute", Brent 113.43, VIX 19.42 (`state.current_regime`). L2 is forced to DO-NOT-ACTIVATE.
- **SHOCK-NATIVE is not available.** Activation must REQUIRE the overlay in {latent, acute}, and a covenant reader triggers on filings. Its stated condition is the hiking cycle, not the shock.
- **Can the three breaker requirements be met?** Not today, and only awkwardly later:
  - (i) Per-industry-group leg: the rule is written for pair correlation within a group. L2 has single names against a broad ETF, so there are no group pairs. It would need a new measure, for example each name's correlation to its group ETF. Possible, unbuilt.
  - (ii) Low-side leg keyed to its own breakdown invalidation: L2 has none. A thesis short should decouple from its hedge, so correlation breakdown is partly the thesis working, not a failure. This is the hardest of the three.
  - (iii) Stress replay showing it trips: doable once (i) and (ii) exist.
  - It also needs an owner revision and adversarial review. E, the only SPREAD row, has not had one landed since Rev 53 (2026-10-23).
- **Open:** stage 1's SL3 question, whether a bound strategy still accrues SHADOW and PAPER evidence, decides whether L2 could even collect evidence during acute.

## T2 Frequency: PASS on arithmetic (proxy)

Tradable events per calendar year (2026 is partial, VERIFIED output):

| set | 2023 | 2024 | 2025 | 2026 to date |
|---|---|---|---|---|
| T all | 152 | 147 | 192 | 129 |
| T new | 90 (censored) | 44 | 55 | 36 |
| T breach | 38 | 35 | 58 | 31 |
| T breach new | 32 (censored) | 15 | 27 | 13 |
| T breach new, ADV >= $10M | 19 | 8 | 18 | 10 |

- **Source:** EFTS queries above via `ev2.py`, filtered in `study2.py`.
- **Declared rate:** 15-30 round trips a year is the honest proxy for a selective reader (UNVERIFIED as an LLM output rate). At 10 or more a year, the PAPER floor is 10 closed trades.

Closed trades inside a 60-trading-day PAPER, assuming uniform arrival (the rate is my arithmetic, arrival is clustered in filing seasons):

| annual | H=20 | H=40 | H=60 | trading days to 10 closed at H=40 | under 400? |
|---|---|---|---|---|---|
| 15 | 2.4 | 1.2 | 0.0 | 208 | yes |
| 20 | 3.2 | 1.6 | 0.0 | 166 | yes |
| 30 | 4.8 | 2.4 | 0.0 | 124 | yes |

A 60-day PAPER cannot close 10 trades. The floor clears at about 124-208 trading days at H=40, well inside the 400-day cull, provided SL3 lets a bound strategy record trades.

Breach-new events cluster heavily by quarter: 20 in 2023Q1, then 6, 3, 3, then 10, 1, 3, 1, then 14, 5, 5, 3. Only about 2-3 independent bets arrive per year.

## T3 Cost: FAIL against edge, PASS on rail (d)

Sources, all VERIFIED unless marked:
- IBKR Fixed: USD 0.005/share, $1 minimum, 1% maximum (IBKR commissions page).
- Short proceeds interest: 0% on USD 0-100,000 (IBKR short-sale-cost page), so no rebate at this size.
- Borrow: IBKR `shortstock` feed `usa.txt`, 2026-11-02 16:27 stamp, 20,145 rows.
- Spread: Abdi-Ranaldo estimate from bars, median 0.72% for T breach new and 0.50% for T all, versus 0.41% for control.
- Open-print slippage of 0.25% each way, and IWM cost of 0.02%: UNVERIFIED assumptions.

Round trip at $2,000 short plus $2,000 IWM hedge, every leg (`cost.py`):

| case | commission | spread | slippage | IWM | borrow | total |
|---|---|---|---|---|---|---|
| Liquid $20, fee 0.4%, spread 0.3%, 40d | $4.00 (0.20%) | $6 | $10 | $0.40 | $0.89 | 1.06% |
| Median flag $10, fee 0.42%, spread 1%, 40d | $4.00 (0.20%) | $20 | $10 | $0.40 | $0.93 | 1.77% |
| p75 $6, fee 1.67%, spread 1.5%, 40d | $5.33 (0.27%) | $30 | $10 | $0.40 | $3.71 | 2.47% |
| p90 $5, fee 6.77%, spread 2%, 40d | $6.00 (0.30%) | $40 | $10 | $0.40 | $15.04 | 3.57% |
| BALY $13.48, fee 47.6%, 40d | $4.00 (0.20%) | $10 | $10 | $0.40 | $105.78 | 6.51% |

**Rail (d) passes.** Commission is 0.20-0.30% against the 1.8% ceiling (`state.arsenal_rails`).

**Borrow, IBKR feed (VERIFIED):**
- Whole file: median 1.22%, mean 10.34%. The file includes illiquid rows.
- T tradable: median 0.41%, mean 4.56%, p90 3.72%, 18.4% above 1%, 7.8% above 5%, 4.9% above 10%, 5 names absent.
- First-pass non-compliance list (62 tickers, any size): median 0.42%, mean 11.68%, 7 not in the file.
- Worst names:

| name | fee %/yr |
|---|---|
| REED | 303.75 |
| VIVK | 149.88 |
| DRCT | 115.94 |
| CYCU | 110.35 |
| LVLU | 82.78 |
| BOXL | 75.54 |
| BALY | 47.60 |
| LCID | 13.13 |

**Gross versus cost, short leg (`study2.py`, cost is event-specific; borrow counts calendar days via H x 1.4/360):**

| set | hedge | H | n | gross mean | gross median | mean cost | net mean | p5 net | worst net |
|---|---|---|---|---|---|---|---|---|---|
| T all | IWM | 40 | 607 | +0.93% | +1.93% | 2.57% | -1.61% | -42.9% | -460% |
| T all | IWM | 60 | 587 | +2.07% | +3.41% | 2.73% | -0.63% | -45.1% | -216% |
| T all | beta | 60 | 587 | +3.22% | +3.76% | 2.73% | +0.56% | -45.3% | -216% |
| T new | beta | 40 | 218 | +0.45% | +2.29% | 2.18% | -1.70% | -40.3% | -276% |
| T new | beta | 60 | 215 | +2.15% | +3.74% | 2.10% | +0.06% | -44.5% | -109% |
| T breach new | IWM | 20 | 83 | +0.30% | +2.10% | 1.97% | -1.67% | -24.8% | -36% |
| T breach new | IWM | 40 | 83 | -0.24% | +0.45% | 2.08% | -2.32% | -27.1% | -85% |
| T breach new | beta | 60 | 82 | +2.19% | +4.12% | 2.19% | 0.00% | -59.6% | -85% |

- **Best cell:** T all, beta hedge, 60 days: +0.56% net, before the SGOV hurdle of 0.84% (3.53% yield from the 2026-07-24 figure in the F rejection, stale and UNVERIFIED for today, over 60 of 252 days). Removing my slippage assumption adds 0.5%, which brings it to about +0.2% after SGOV on a -216% worst case.
- **Skew:** positive medians with weak means are the short-squeeze tail. A name can return more than the whole position.

**By borrow bucket, T all (look-ahead caveat above):**

| fee | H | n | mean fee | gross | borrow | all costs | net |
|---|---|---|---|---|---|---|---|
| under 1% | 40 | 494 | 0.4% | -0.85% | 0.06% | 1.73% | -2.58% |
| under 1% | 60 | 478 | 0.4% | -0.37% | 0.09% | 1.74% | -2.11% |
| 1-5% | 40 | 65 | 2.5% | +3.81% | 0.38% | 2.35% | +1.46% |
| 1-5% | 60 | 65 | 2.5% | +11.16% | 0.57% | 2.54% | +8.63% |
| 5-10% | 40 | 18 | 7.4% | +4.57% | 1.15% | 3.57% | +0.99% |
| 5-10% | 60 | 18 | 7.4% | +4.03% | 1.72% | 4.15% | -0.11% |
| over 10% | 40 | 30 | 77.1% | +6.41% | 12.00% | 16.44% | -10.03% |
| over 10% | 60 | 26 | 71.9% | +19.39% | 16.78% | 20.40% | -1.01% |

The 1-5% cell is the only one that looks positive, and it has 65 trades. Today's fee is a look-ahead sort, and recently fallen names are the ones with raised fees, so I do not count it as evidence. Testing it needs fees as of entry date, which I could not get.

**Literature, same direction (VERIFIED from the papers and their summaries):**
- Muravyev, Pearson, Pollet (JF 2025): 162 anomalies earn 0.14%/month before fees, due to the short leg, and -0.01% after fees. They earn nothing before fees once the 12% high-fee stock-dates are removed. Decile-one mean fee is 2.7%/yr, with 3.76-10.01%/yr in the worst five.
- Top distress decile is -0.61%/month against deciles 6-9, which themselves earn +0.24%/month more than lower deciles (JFQA 2026). The short only works at the extreme end.
- Friewald, Nagler, Wagner: high-leverage firms earn the highest returns in every refinancing-intensity tertile (1.09%, 0.96%, 0.88%/month). Return rises with refinancing intensity, the wrong sign for a refinancing short. Pre-2017 sample.

## T4 Next-open survival: FAIL for "worsened"

Differences versus compliant control, in percent, clustered by quarter (`study2.py`, t in brackets):

| set | day 0 | close t-1 to entry open | x20 | x40 | x60 | bx60 |
|---|---|---|---|---|---|---|
| T all (n=620) | -1.17 (-2.97) | -0.70 (-1.22) | -0.87 (-1.12) | -1.07 (-0.69) | -3.01 (-1.78) | -4.42 (-3.35) |
| T repeat (n=395) | -1.43 (-2.96) | -0.67 (-0.97) | -1.48 (-1.58) | -1.68 (-1.00) | -3.53 (-1.75) | -4.94 (-3.17) |
| T new (n=225) | -0.87 (-1.08) | -1.08 (-0.99) | +2.30 (0.82) | +1.81 (0.62) | -0.53 (-0.20) | -2.50 (-1.00) |
| T new 2024+ (n=135) | -0.61 (-0.58) | -0.47 (-0.36) | +4.28 (1.17) | +4.27 (1.14) | +2.36 (0.81) | +0.27 (0.11) |
| T breach new (n=87) | +0.40 (0.22) | -1.27 (-0.73) | -0.33 (-0.13) | -0.75 (-0.45) | -3.10 (-0.86) | -4.10 (-0.93) |

- **The covenant language does draw a day-0 reaction** (-1.17%, t -2.97). Literature agrees: Beneish and Press -3.52% over 3 days; Stice -0.79/-0.83% at earnings and about -0.45% on filing date.
- **Part of it is already gone or reversed by the open a next-open entry can reach.** The gap shrinks from -1.17% to -0.70% and loses significance.
- **After entry, the 20-40 day difference is insignificant in every row.** The only significant number is beta-hedged 60 days, and it is stronger for repeats than for new events. So it reads as level of distress, not new information.
- **The sign flips year to year.** T all x40 by Q3 season: -7.01% (2023), +4.24% (2024), +4.17% (2025), -9.56% (2026). Q1 season: -3.86, +1.13, +0.61, +6.09.
- **Prior literature on the post-event period is adverse.** Nini, Smith, Sufi (2009) and Griffin, Lont, McClune document positive returns in the months after a violation, as reported by Stice. I did not read the originals.

**Lazy Prices decay.** The paper claims no announcement reaction and slow accrual, which is the opposite shape from covenant text.
- **Short leg:** quintile-1 alpha in the value-weighted tables is -0.13 to -0.44%/month, about 38-70% of the long-short spread. That is 0.25-0.84% gross over 40 trading days, and 0.10-0.35% after applying the 58% McLean-Pontiff post-publication decay (generic decay, not measured on this anomaly).
- **Below any all-in cost here.** Q1 average shorting fee was 71.7 bp.
- **2006-2026 replication (github.com/Shardul-Pandit/Lazy-Prices, S&P 500, annual filings only, one amateur repo):** full 10-K -10 bp/month (t -1.19). Risk Factors +21 bp/month (t 2.08), 12 bp after costs (t 1.31). MD&A opposite sign. Embedding-based similarity on Risk Factors had no return spread (-1 bp), though it surfaces new passages, a warning for "the LLM reads meaning". Large-cap sample, so it does not settle small caps.

**The 422 bp lead:** I could not find its source. My own test confirms the same day-0 shape here.

## T5 Overlap

- **B:** a filing reaction of at least 5% is a B trigger. Share of tradable events with |day 0 and day 1 abnormal| at or above 5%: 40% (T new), 47% (T breach new), 48% (T all). Declines of at least 5% are 25-28% of all events in those sets. B is long-biased and already covers post-event mispricing, including shorts with a 10% borrow exit (`strategy/04_strategy_b.md`). Market cap of events not measured against B's $2B floor.
- **A:** no direct overlap. A long-improver leg near a refinancing date resembles pre-event catalyst longs.
- **C:** none. D: minor, D's narrative work may read the same filings.
- **E:** different. E is same-group pairs at $10B or more, L2 is a single name against an ETF, but it shares the SPREAD binding.
- **Dead ideas:** no named cooldown applies (`state.strategy_candidates` holds F, G, H, I; I runs to 2027-01-17 and is a different archetype). `events.strategy_research_leads` has 0 rows matching covenant, refinanc or lazy price. The rail (a) ground that rejected F, H and I, a classical premium the AI merely selects, applies directly.
- **Sibling:** L4 uses the same footnote-reading pipeline. L2 and L4 would compete for read budget.

## T6 Mechanical baseline: AI adds nothing measurable, rail (a) fails

- **Non-AI version:** a phrase search, short against IWM, earns +0.9% to +3.2% gross and about -1.6% to +0.6% net, before SGOV (table above).
- **What the AI must add, in numbers:** at n=82-218 and about 2.1% cost, it must lift gross per trade by at least 2-3% over the phrase search, and do it in names with fee under 5%, where the phrase search earns -0.31% (H=40) and +1.01% (H=60) gross. The whole cost and hurdle stack is about 2.4-2.7%.
- **Evidence that it does:** none. The change signal (`new`) is weaker than the level signal (`repeat`). The AI's claimed edge is detecting change, so the only significant effect is the part it does not contribute. This is a phrase proxy, not an LLM.
- **Other evidence:**
  - arXiv 2610.24268: 13 LLMs on 10-Q MD&A. Best RankIC with fundamentals is 0.077 on the event day and 0.057 the next day. Fundamentals, not text, added the increment (+0.0089, t 2.55; +0.0098, t 2.84). Only day-0 and day+1 are tested, which are not reachable from a next-open entry after a daily read. Read from an extract, not in full.
  - Earlier rejection text in `state.strategy_candidates` cites LLM predictability as next-day-to-days, small-cap and long-side, weakest on the short side.
- **Readers have a head start:** full-text search returns the flagged names in seconds, so "labor-heavy reading at breadth" (the stage 1 reason others leave it) is weak. Search load check: 2,470 10-Qs contain "covenant" in Jul-Sep 2026, and 1,657 contain "credit agreement" in Aug 1-14 2026 alone, but only 212 hit `"not in compliance" "covenant" "amendment"`.

## T7 Data and execution: workable, no extra human step in normal flow

- **Reachable from this host (VERIFIED):** EFTS works with the required User-Agent. `form.idx` under full-index returned 403 with that same User-Agent (SEC "Undeclared Automated Tool" page), including on a retry. Nasdaq historical API works. IBKR public short feed works and carries borrow and shares available by contract id. IBKR snapshot works (read-only, no orders placed).
- **UNVERIFIED:** whether the FTP feed is reachable from the scheduled routine host; EDGAR document fetch from there.
- **Execution risk:**
  - Market short at the open on a name needs locate at confirm time, which can reject. AVAILABLE counts are often thin: BOXL 35,000, DRCT 45,000, LVLU 55,000, TEAD 55,000.
  - Recall or buy-in during a 20-60 day hold, and the SSR short-sale restriction on a name down 10%, are forced events. Rates and frequency UNVERIFIED.
  - After-hours spreads sampled on 2026-11-02 are not representative and were not used in the cost table (for example PRAA 18.11/22.00, XBP 2.50/2.95).
- **Human:** only the confirm tap in normal flow. No intraday monitoring exists, so a squeeze of the -100% to -460% kind runs until the next daily decision. The mandatory short stop used by E is the natural control and would itself add stop-out cost not modeled here.

## T8 Test feasibility: mechanically yes, statistically no

Post-cutoff (2026-07-01 onward, VERIFIED output, tradable):

| set | events | tickers | filing dates | with x20 / x40 / x60 exit |
|---|---|---|---|---|
| T all | 46 | 43 | 20 | 38 / 38 / 18 |
| T new | 14 | 14 | 10 | 9 / 9 / 6 |
| T breach | 12 | 11 | 8 | 9 / 9 / 4 |
| T breach new | 7 | 7 | 6 | 5 / 5 / 4 |

Raw count before the price and tradability filters: 229 filings and 190 tickers across a broader four-phrase query.

**Independent windows:** effectively one closed season (July-August 2026) and one just opening (late October). 20-60 day holds overlap within a season, so "20 dates" overstates independence.

**Power:** x40 standard deviation is 18.7-25.6%, and 30.4% for x60. Detecting a 2% edge at t=2 takes 349-657 events (924 for x60); 1% takes about 1,400-2,600. With n=38, the smallest detectable effect is 6.1-8.3%. At 15-30 round trips a year this is decades.

**Post-cutoff result, the best number for the idea, and it should be stated:** T all x40 -9.56% (median -4.63%, n=38, 26% positive) against control +0.59%, naive t -2.70. Clustered, this is one season. Same-season results in prior years include +4.24% and +4.17%.
- It is carried by high-fee names. Short gross is +48.17% for the 5 names with fee over 5% (VIVK, CYCU, BOXL, CRMT plus one, fees up to 150%), and +3.71% (median +3.54%) for the 33 at fee under 1%.
- That +3.71% over about 2 months, one season, is suggestive but not distinguishable from zero against the historical sign flips. It is also a phrase search, so it says nothing about the AI.
- T breach new at x40 is +3.21% mean (wrong sign), -5.09% median, n=5.

## Open, load-bearing unknowns

1. Borrow fee as of entry date, historically. Only today's snapshot was available, which contaminates every fee-bucket result, especially the 1-5% cell.
2. Delisted and bankrupt names missing from prices (37% of T events have none), which understates the short side by an unknown amount.
3. No LLM was run. The increment over phrase search is unmeasured.
4. Whether a bound strategy accrues SHADOW and PAPER evidence under acute (stage 1 open question).
5. Slippage at the open for these names (0.25% each way is assumed).

## One suggestion, not a rescue

If this is ever reopened, first run the same event study with point-in-time borrow fees and delisting returns. If the under-5% fee bucket is still negative before cost, nothing about an LLM reader can fix it.

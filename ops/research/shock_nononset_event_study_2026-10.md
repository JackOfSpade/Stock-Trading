# Non-onset event study: does FIRST-HOP hedged drift also follow within-episode shock events in 2026? (2026-10-19)

**Answer, in one line.** Pooled over the 8 non-onset, rubric-qualifying escalation events of 2026 that have a
4-week window, the first-hop hedged CAR at 4 weeks is **+0.8% (bootstrap 95% CI -1.1% to +2.5%), 6 of 8 positive,
76th percentile of the onset study's placebo distribution** on ETF-first proxies (+1.5%, 81st, on stock baskets;
+1.1%, 78th, on French 49 industries for the 4 events that source covers). That does NOT reach the onset study's
bar (95th percentile). The implied frequency is 11.3 qualifying escalation events per calendar year (9 dated events
in 0.80 yr), i.e. 22.6 trades/yr at one pair per event and two trades per pair, so the 30-trade gate would take
about 1.3 years rather than decades. Restart condition (1) on the lead is therefore MEASURED and NEGATIVE: the
events are countable, but the drift after them is not distinguishable from the base rate at the horizon the
candidate would trade.

**What this is.** The measurement SL1's 2026-10-19 rejection of candidate I named as restart condition (1) on the
lead `interactive-2026-10-shock-first-hop-continuation-hedged`: placebo-test first-hop hedged drift after EVERY
rubric-qualifying event of 2026, not just the onset. It reuses the onset study
(`ops/research/shock_episode_event_study_2026-10.md`, `scripts/research/shock_episode_event_study.py`) without
redesign; the new script `scripts/research/shock_nononset_event_study.py` imports it. It is an input to SL1's next
synthesis. It is not a candidate row, touches no roster, Strategy.md, Claude_Task_Plan.md or `strategy/` file, and
does not alter the archetype cooldown (2027-01-17).

**Reproduce** (the onset study's `linkmap` and `prices` stages populate the data dir; downloads ~60 MB, not in the repo):

```bash
python scripts/research/shock_episode_event_study.py linkmap --data-dir /tmp/shock_study
python scripts/research/shock_episode_event_study.py prices  --data-dir /tmp/shock_study --source french
python scripts/research/shock_episode_event_study.py prices  --data-dir /tmp/shock_study --source nasdaq
python scripts/research/shock_nononset_event_study.py --data-dir /tmp/shock_study --source nasdaq
python scripts/research/shock_nononset_event_study.py --data-dir /tmp/shock_study --source nasdaq --baskets-only
python scripts/research/shock_nononset_event_study.py --data-dir /tmp/shock_study --source french
```

Data vintage: Nasdaq daily closes through 2026-10-16; Kenneth French daily files through 2026-08-31; BEA 2023 use
table. Placebo draws are seeded identically to the onset study, so for a given vintage the placebo windows are the
onset memo's own.

## 1. Method (what is reused, what is added)

Reused unchanged from the onset study: the BEA link map and its 7 first-hop industries (211 oil and gas extraction,
324 petroleum products, 486 pipelines, 213 mining support, 481 air transport, 483 water transport, 22 utilities);
the two price sources and their proxy tables (`nasdaq`: XOP CRAK AMLP OIH JETS SEA XLU ETF-first or 48 stock-basket
members, SPY as market; `french`: Oil + Trans + Util value-weighted portfolios, Fama-French market factor); the
equal-weighted first-hop basket; OLS beta over the 252 trading days before the event; `d0` = the event day's own
hedged return, `CAR_h` = cumulative hedged return over trading days 1..5h AFTER the event day (what a day-1 entry
could earn); the placebo construction byte for byte (same eligibility rule, same seed, same draw order, 500 windows).

Added, because the calendar forces it: the 2026 events are 1-15 weeks old, so the longer horizons do not exist
yet. Each horizon is reported for the events that have it and the pooled statistics carry their own n per cell;
the placebo comparison for horizon h is the mean of n_h placebo windows drawn without replacement, 2000 times, and
the "percentile" is where the pooled event mean falls in that distribution (the onset study's statistic). A second
addition is a NON-OVERLAPPING subset: the July and September events are days apart and their windows share most of
their trading days, so they are not independent draws; the subset keeps an event only if it is at least 20 trading
days after the previous kept one (E1, E5, E7).

**Operational reading of the Rev 48 rubric** (Strategy.md `### Shock / overlay grading rubric`): a qualifying event
is a dated development, attributable to a named geopolitical or trade channel, with a measurable leg. For this
list the leg is read as EITHER a stored-BZUSD (`state.signal_marks_curated`) close-to-close move of more than
$5/bbl in the shock direction over the event session and the next, OR an explicitly recorded trade-flow leg
(declared strait closure, blockade, transit collapse, export-pipeline halt, a state halting trade). Tiers: `strict`
= a dated kinetic or trade-flow development named in the warehouse row AND the oil leg, or named as THE qualifying
event by the live M1a grading; `rubric` = qualifies on the text but the row pins no single dated kinetic
development, or the live grading did not name it; `provisional` = dates not established in the warehouse. The
primary set is strict + rubric; the strict subset is reported alongside; provisional events are measured but not
pooled. De-escalation events (oil down, flows restored) are the opposite trade and are reported sign-flipped as a
sensitivity only.

## 2. The 2026 event list (built from the warehouse, not from memory)

Sources: `events.regime_events` `shock_overlay` rows (M1a monthly gradings 2026-06-01 .. 2026-10-01) and
`events.decision_log` router-review / regime / research-screen rows. Brent = stored BZUSD closes (session before,
event session, next session).

| Id | d0 (first session) | Development | Kind / tier | Source row(s) | Brent t-1 / d0 / d0+1 | Leg |
|---|---|---|---|---|---|---|
| onset | 2026-03-02 | Iran war onset (2026-02-28) | onset | onset study | n/a (series starts 06-01) | in the onset study; excluded here |
| E1 | 2026-07-08 | Ceasefire collapse: US strikes 80+ targets, Iran hits Gulf bases, June ceasefire declared over (07-07/08) | escalation / strict | decision_log `4d1d251d`; regime_events `6b16af77` | 71.99 / 74.16 / 78.02 | +6.03 two-session |
| E2 | 2026-07-13 | IRGC declares the Strait of Hormuz closed "until further notice" (Sun 07-12), two vessels struck | escalation / strict | decision_log `99a56801`, `28b940de` | 76.01 / 83.30 / 84.73 | +7.29; closure declared |
| E3 | 2026-07-22 | Resumed strike waves and Gulf shipping attacks; Brent +6% to resumption highs, through $100 next session | escalation / rubric | decision_log `5bf282fd`, `aed40624`; regime_events `6b16af77` | 91.01 / 94.07 / 100.69 | +9.68; no single dated kinetic development in the row |
| E4 | 2026-07-29 | Iranian ballistic-missile attack on US Gulf forces (07-28/29) | escalation / strict | regime_events `6b16af77` (M1a 2026-08-01) | 84.09 / 90.74 / 86.88 | +6.65 single session |
| E5 | 2026-08-10 | Iran hardens Hormuz reopening preconditions; E&P +5.9%, refiners +5.8%, tankers -1.7% | escalation / rubric | decision_log `a7fde137` | 83.55 / 87.72 / 88.91 | +5.36 two-session (marginal) |
| E6 | 2026-08-19 | UAE halts all trade and financial dealings with Iran after missile fire on Emirati maritime targets | escalation / strict | regime_events `ba8ae2cf` (M1a 2026-09-01) | 91.02 / 91.62 / 93.78 | trade-flow leg (oil +2.76 only) |
| E7 | 2026-09-09 | Gulf shipping attacks open the September escalation | escalation / strict | regime_events `3b6d1923` (M1a 2026-10-01) | 99.39 / 101.21 / 107.63 | +8.24 two-session |
| E8 | 2026-09-11 | Drone strikes on the Saudi East-West export pipeline halt Red Sea loadings of 3.9 mb/d (reported 09-10/11) | escalation / strict | regime_events `3b6d1923` (named as the most recent qualifying event); decision_log `db7dc01c` | 107.63 / 104.61 / 105.68 | trade-flow leg (oil -3.02) |
| E9 | 2026-09-23 | Armed-group blockade of Libya's El Sharara field (about a third of Libyan output) plus a proposed US diesel-export ban | escalation / rubric | decision_log `e01d9ca6` | 98.53 / 103.08 / 106.60 | +8.07; not named by M1a 10-01 |
| E10 | 2026-10-08 | Hormuz tanker strikes 09-28..10-04 (Kpler: 10 tankers; transits 7 on 10-06) and Houthi attacks; incident dates not established | escalation / provisional | decision_log `c2f7afe6`, `eb64b71d` (W1 2026-10-11) | 100.20 / 104.28 / 104.72 | +4.52; only the 1-week horizon exists |
| D1 | 2026-06-15 | Mid-June ceasefire framework restores near-normal Hormuz flows | de-escalation / sensitivity | regime_events `14e621ac` (M1a 2026-07-01) | 87.33 / 83.17 / 78.96 | -8.37 |
| D2 | 2026-07-27 | Weekend US-Iran talks "by far the most serious"; threatened attack "may be unnecessary" | de-escalation / sensitivity | decision_log `aed40624` | 96.78 / 88.36 / 84.09 | -12.69 |
| D3 | 2026-08-03 | US strike called off 08-02 on claimed deal progress; Iran denies talks 08-03 | de-escalation / sensitivity | regime_events `6b16af77`; decision_log `b090c1d6` | 87.93 / 83.77 / 79.36 | -8.57 |

Considered and not counted: 2026-07-31 IRGC strikes on Kuwait (`6b16af77`; Brent +1.05 then -4.16, no recorded
trade-flow leg); 2026-08-01 D1 flag of Hormuz tanker attacks and reported US strikes on Iranian energy
infrastructure (`b090c1d6`; reversed within 48 h, no stored close more than $5 up); 2026-08-24 50% tariff on about
$20B of goods (`ba8ae2cf`; rubric-qualifying but off the petroleum channel the link map enumerates); 2026-08-03 joint
currency intervention (`ba8ae2cf`; FX leg, off-channel, same session as D3); 2026-09-15 D1 "drones strike the
East-West pipeline" (`db7dc01c`; the same development as E8, and M1a 10-01 counts 09-11 and not 09-15);
2026-09-29 Brent -9.12 (Yanbu loading resumption plus a contract roll worth about -6.43, per `3b6d1923`).

**The pre-June gap, stated once.** The regime scoring began 2026-04-22 and the `shock_overlay` axis on 2026-06-01,
so no warehouse row DATES a within-episode event between the onset and June, although the June grading itself
cites a $128 April peak and a 60-day MOU. The appendix applies the same oil-leg rule to the BNO Brent ETF for
March-May and finds 7 distinct up-clusters and 5 down-clusters: undated, unattributed, and therefore NOT counted,
but a reminder that the 9 dated events are a lower bound on the year's count and the 0.80-year denominator an
undercount of the rate during an active structure.

## 3. Results: first-hop hedged CAR after non-onset events

Nasdaq data, ETF-first proxies (7 series per event; SPY market). Blank = horizon not yet observable.

| Event | d0 | β | d0 | 1w | 2w | 4w | 6w | 8w | 12w | 4w percentile among single placebo windows |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| E1 | 2026-07-08 | 0.49 | +1.3% | +0.8% | +3.5% | +1.3% | +6.1% | +6.8% | +3.3% | 71st |
| E2 | 2026-07-13 | 0.48 | +1.5% | +1.4% | +2.3% | +2.2% | +5.2% | +6.8% | +3.5% | 79th |
| E3 | 2026-07-22 | 0.46 | +0.6% | +0.1% | -2.2% | +2.6% | +3.3% | +3.4% | +0.9% | 82nd |
| E4 | 2026-07-29 | 0.46 | +0.7% | -2.2% | +0.7% | +1.7% | +4.1% | +0.0% | | 73rd |
| E5 | 2026-08-10 | 0.43 | +1.6% | +3.0% | +3.0% | +4.6% | +0.9% | +1.4% | | 90th |
| E6 | 2026-08-19 | 0.41 | -0.2% | -0.9% | +0.7% | +0.8% | -2.8% | -1.7% | | 66th |
| E7 | 2026-09-09 | 0.39 | +0.5% | -1.6% | -4.6% | -4.2% | | | | 17th |
| E8 | 2026-09-11 | 0.39 | +0.0% | -1.4% | -4.2% | -2.6% | | | | 27th |
| E9 | 2026-09-23 | 0.38 | -0.5% | -1.1% | +0.4% | | | | | |
| E10 (provisional) | 2026-10-08 | 0.40 | +1.5% | -0.9% | | | | | | |

**Pooled, with the placebo comparison** (mean [bootstrap 95% CI over events], positive/n; placebo mean over the 500
windows; percentile of the pooled mean among pooled means of the same n placebo windows):

| Set and source | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| **Primary (E1-E9), Nasdaq ETF-first** | -0.2% [-1.1, +0.9] 4/9 | -0.0% [-2.0, +1.7] 6/9 | **+0.8% [-1.1, +2.5] 6/8** | +2.8% [+0.3, +4.9] 5/6 | +2.8% [+0.2, +5.3] 5/6 | +2.6% [+0.9, +3.5] 3/3 |
| placebo mean / percentile | -0.2% / 49th | -0.1% / 53rd | -0.3% / **76th** | -0.3% / 91st | -0.4% / 89th | -0.8% / 80th |
| Strict (E1 E2 E4 E6 E7 E8), ETF-first | -0.6% 2/6 | -0.2% 4/6 | -0.2% [-2.1, +1.6] 4/6 | +3.1% 3/4 | +3.0% 3/4 | +3.4% 2/2 |
| percentile | 33rd | 50th | 57th | 88th | 86th | 80th |
| Non-overlapping (E1 E5 E7), ETF-first | +0.7% 2/3 | +0.6% 2/3 | +0.5% [-4.2, +4.6] 2/3 | +3.5% 2/2 | +4.1% 2/2 | +3.3% 1/1 |
| percentile | 76th | 70th | 70th | 83rd | 83rd | 76th |
| Primary, Nasdaq stock baskets (48 series) | +0.0% 3/9 | +0.3% 6/9 | +1.5% [+0.1, +3.0] 6/8 | +3.8% 5/6 | +4.7% 6/6 | +5.2% 3/3 |
| percentile | 56th | 58th | 81st | 92nd | 93rd | 86th |
| Primary, French 49 (E1-E6 only; data end 08-31) | +0.0% 3/6 | +1.0% 4/5 | +1.1% [+0.6, +1.5] 4/4 | +4.2% 2/2 | n/a | n/a |
| percentile | 51st | 88th | 78th | 97th | n/a | n/a |
| De-escalation (D1-D3), SIGN-FLIPPED (short the first hop), ETF-first | +0.1% 2/3 | -0.5% 2/3 | -2.7% 0/3 | -4.7% 0/3 | -2.0% 1/3 | -9.4% 0/1 |
| percentile | 47th | 34th | 12th | 8th | 25th | 8th |
| Reference: the 2026-03-02 onset alone, ETF-first (onset study's row) | -1.0% | -0.0% | +7.4% | -0.7% | -1.4% | -5.7% |
| percentile | 35th | 53rd | 94th | 53rd | 52nd | 24th |
| Onset study, 6 onsets 1990-2026, French (for comparison) | +0.6% 3/6 | +1.3% 4/6 | +1.9% 4/6 | +1.0% 4/6 | +1.0% 4/6 | +1.2% 4/6 |
| percentile | 90th | 96th | 95th | 73rd | 64th | 64th |

Dispersion: the SD across the 2026 events is BELOW the SD across single placebo windows at every horizon (ETF-first
4w: 2.9% vs 4.7%; 8w: 3.5% vs 6.5%), the opposite of the onset study's finding for onsets (3.9% vs 2.6% at 4w). The
2026 non-onset windows are less dispersed than random windows because they are mostly the same window.

**Per industry, pooled over the primary events** (ETF-first; mean hedged CAR, positive/n):

| Industry | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo 4w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211 oil and gas (XOP) | +2.1% 9/9 | -0.5% 3/9 | +1.1% 6/9 | +4.2% 6/8 | +9.1% 5/6 | +11.1% 6/6 | +13.5% 3/3 | -0.6% |
| 324 refiners (CRAK) | +1.5% 7/9 | +0.9% 3/9 | +2.5% 6/9 | +6.6% 7/8 | +13.6% 6/6 | +17.3% 6/6 | +21.7% 3/3 | -0.4% |
| 213 oil services (OIH) | +1.4% 7/9 | -2.1% 3/9 | -0.7% 5/9 | -0.5% 4/8 | +3.8% 4/6 | +2.2% 4/6 | -1.7% 0/3 | -1.0% |
| 486 pipelines (AMLP) | +0.5% 6/9 | -0.7% 2/9 | -0.8% 4/9 | -0.5% 6/8 | +0.3% 4/6 | -0.2% 3/6 | -2.4% 0/3 | +0.0% |
| 483 shipping (SEA) | +0.5% 7/9 | +2.1% 7/9 | +1.7% 4/9 | +4.7% 8/8 | +8.7% 6/6 | +9.6% 6/6 | +14.6% 3/3 | +0.4% |
| 481 airlines (JETS) | -1.3% 0/9 | +0.3% 5/9 | -1.7% 3/9 | -5.3% 1/8 | -9.4% 0/6 | -12.9% 0/6 | -16.2% 0/3 | -0.3% |
| 22 utilities (XLU) | -0.4% 2/9 | -1.5% 1/9 | -2.4% 4/9 | -3.8% 1/8 | -6.5% 0/6 | -7.6% 0/6 | -11.5% 0/3 | -0.5% |

(Stock baskets give the same ordering with larger magnitudes: refiners +13.4% at 4w, 8 of 8; airlines -7.2%, 1 of 8.)

## 4. Reading the numbers

1. **At the horizon the candidate would trade (2-4 weeks), non-onset events show no drift distinguishable from the
   base rate.** Pooled 4-week first-hop hedged CAR is +0.8% (ETF-first), +1.5% (baskets), +1.1% (French), at the
   76th / 81st / 78th placebo percentile; 1- and 2-week CARs are at the 49th-58th percentile with 4-6 of 9 positive.
   The strict subset is weaker (-0.2% at 4 weeks, 57th), and the non-overlapping subset, the only one that
   approximates independent draws, is +0.5% at 4 weeks on n = 3 (70th). None of these reaches the 95th percentile
   the onset study's 4-week number sat at, and the per-event 4-week percentiles range from 17th (E7) to 90th (E5):
   two of the three September events are negative at every horizon.

2. **The longer horizons look better (6-8 weeks at the 86th-93rd percentile) and should not be read as an effect.**
   Only the July events (E1-E5) have 6-week-plus windows; they are five entries into one refiner-led energy rally,
   their windows overlap by 60-90%, and the Q3 regime retrospective (`decision_log 4c0487f7`) records that quarter as
   "Energy +15.8% led". The non-overlapping subset has n = 2 at those horizons. This is one episode's trend counted
   several times, which is also why the dispersion across events is BELOW the placebo dispersion.

3. **The de-escalation sensitivity says the drift is structural, not event-conditional.** Shorting the first hop
   after the three de-escalation events would have LOST 2.7% at 4 weeks and 4.7% at 6 (0 of 3 positive, 8th-12th
   percentile): the first-hop basket kept rising after oil fell $8-13 on ceasefire and talks news, exactly as it rose
   after oil jumped on escalation news. A basket that rises after both signs of event is tracking the quarter's
   energy trend, not repricing each event over 2-4 weeks. For the onset study's mechanism (first-order supply-shock
   repricing continuing for 2-4 weeks after the news) this is a negative control that fails.

4. **The per-industry dispersion is large and consistent in sign (refiners and shipping up, airlines and utilities
   down, every event), and it is post hoc.** A long-refiners / short-airlines expression over the July-October
   events would have returned about +12% hedged at 4 weeks on ETF proxies. That spread is not what the onset study
   measured, was not pre-registered, is again mostly one structure's trend, and is the directional sector bet
   (long the shock's winners, short its losers) that the SHOCK-NATIVE rail (i) forbids as a net-directional
   expression and that B's register row and the router's `acute` cell already touch. It is recorded here so that
   SL1 sees it, not as evidence for candidate I's judgment layer, which this study cannot measure.

5. **The events ARE countable, so the frequency objection is resolved in the candidate's favour and the evidence
   objection is not.** 9 dated non-onset escalation events in 2026 through 2026-10-19 (6 strict), all inside an
   active shock structure, against the warehouse's dating window that only begins 2026-06-01.

## 5. Frequency and the 30-trade arithmetic

Two trades per pair (the two legs), per SL1's 2026-10-19 arithmetic. Two denominators: the calendar year observed
so far (0.80 yr; treats January-May, when the warehouse dated nothing, as zero, an undercount) and the window in
which the axis existed (2026-06-01 .. 2026-10-19, 0.38 yr; all of it inside an active structure, an overcount for a
year with quiet months).

| Event set | Denominator | Events | Events / yr | Pairs / event | Trades / yr | Years to 30 trades |
|---|---|---:|---:|---:|---:|---:|
| Primary (9 events) | calendar YTD, 0.80 yr | 9 | 11.3 | 1 | 22.6 | 1.33 |
| | | | | 2 | 45.2 | 0.66 |
| | | | | 3 | 67.7 | 0.44 |
| Primary | dated window, 0.38 yr | 9 | 23.5 | 1 | 46.9 | 0.64 |
| Strict (6 events) | calendar YTD, 0.80 yr | 6 | 7.5 | 1 | 15.1 | 1.99 |
| | | | | 2 | 30.1 | 1.00 |
| Strict | dated window, 0.38 yr | 6 | 15.6 | 1 | 31.3 | 0.96 |
| Onset-only (the SL1 objection) | 6 onsets / 36 yr | | 0.17 | 1 | 0.3 | about 90 |

So, if "qualifying event" is the frequency unit, the 30-trade PROBE gate is reachable in roughly one to two years of
a shock year at one pair per event. The unit is consistent with this measurement, which is the point of restart
condition (2). It is a rate conditional on a year like 2026; in a year with no structure the count is zero, which
the candidate's declared band would have to say.

## 6. Caveats that bound every number above

n = 9 events from ONE shock structure in ONE year, five of them inside five weeks; the windows overlap, so the
effective n at 6 weeks and beyond is about 2. The 12-week horizon exists for three July events only, and nothing
after 2026-07-22 has one yet (re-run after 2027-01 for the full set). Industry-level proxies, survivorship-selected
baskets, no dividend adjustment on the Nasdaq series (small at these horizons). The rubric's "> $5/bbl" leg is read
off a continuous stored Brent series that carries contract-roll steps (`decision_log 2026-10-02` ops-note; one
candidate was excluded for exactly that). The event list excludes undated pre-June developments by construction
(appendix) and two September-October candidate sessions the warehouse did not attribute (BNO up-clusters on
2026-09-01 and 2026-10-01, appendix). The judgment layer the candidate claims is not measured here and cannot be
measured from this data.

## 7. Verdict

The drift after non-onset rubric-qualifying events does NOT reach the onset study's bar. Pooled over the 8
non-onset escalation events of 2026 with a 4-week window, first-hop hedged CAR is +0.8% (95% CI -1.1% to +2.5%,
6 of 8 positive) at the 76th placebo percentile on ETF proxies, +1.5% (81st) on stock baskets and +1.1% (78th) on
French industries, against the onset study's +1.9% at the 95th; the strict subset is -0.2% (57th) and the
non-overlapping subset +0.5% (70th). The 6-8-week cells that sit at the 86th-93rd percentile are five overlapping
entries into one July-October refiner rally, and the same basket kept rising after the three de-escalation events
(shorting it there lost 2.7% at 4 weeks, 12th percentile), so what the 2026 data show after a within-episode event
is the quarter's energy trend, not an event-conditional 2-4-week repricing. Restart condition (1) on the lead is
therefore met as a measurement and answered in the negative; condition (2) is answered in the affirmative (events
are countable: 11.3 per calendar year to date, 22.6 trades per year at one pair per event, about 1.3 years to the
30-trade gate); condition (3), the per-name judgment layer, remains unmeasured. The archetype cooldown to
2027-01-17 is untouched.

## Appendix A. Pre-June Brent proxy scan (undated in the warehouse; NOT counted)

The rubric's oil leg applied to the BNO Brent ETF (api.nasdaq.com, split-adjusted closes), two-session move of at
least 5% in magnitude, clusters at least 5 sessions apart. 2026-03-03 .. 2026-05-31: **7 up-clusters** (03-03
+10.9%, 03-12 +11.3%, 03-27 +8.1%, 04-06 +8.6%, 04-21 +10.1%, 04-29 +9.8%, 05-12 +7.1%) and **5 down-clusters**
(03-23, 04-01, 04-09, 05-06, 05-21). None is attributed to a dated development by any warehouse row, so none is
counted. The same rule over 2026-06-01 .. 2026-10-16 returns 07-07, 07-14, 07-23, 07-30, 08-10, 09-01, 09-09, 09-24,
10-01: it recovers E1-E5, E7 and E9 and adds two sessions (09-01, 10-01) the warehouse did not attribute to a
development, which is the expected behaviour of a price-only rule and the reason the primary list is built from the
warehouse rows rather than from prices.

## Appendix B. Raw script output (verbatim; reproducible with the commands at the top)

### B.1 Nasdaq, ETF-first

### Non-onset events: source `nasdaq`, proxies `ETF-first`, first hop = 211 324 486 213 481 483 22

Price span 2016-10-19 .. 2026-10-16; market = SPY; 500 placebo windows (the onset study's own draws). `d0` = event-day hedged return; `Nw` = hedged CAR over trading days 1..5N after the event day; a blank cell means the horizon is not yet observable.

| Event | d0 | kind / tier | series n | β | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| E1 Ceasefire collapse: US strikes 80+ targets, Iran hits Gulf b | 2026-07-08 | escalation / strict | 7 | 0.49 | +1.3% | +0.8% | +3.5% | +1.3% | +6.1% | +6.8% | +3.3% |
| E2 IRGC declares Strait of Hormuz closed 'until further notice' | 2026-07-13 | escalation / strict | 7 | 0.48 | +1.5% | +1.4% | +2.3% | +2.2% | +5.2% | +6.8% | +3.5% |
| E3 Resumed strike waves / Gulf shipping attacks: Brent +6% to r | 2026-07-22 | escalation / rubric | 7 | 0.46 | +0.6% | +0.1% | -2.2% | +2.6% | +3.3% | +3.4% | +0.9% |
| E4 Iranian ballistic-missile attack on US Gulf forces (07-28/29 | 2026-07-29 | escalation / strict | 7 | 0.46 | +0.7% | -2.2% | +0.7% | +1.7% | +4.1% | +0.0% |  |
| E5 Iran hardens Hormuz reopening preconditions; energy complex  | 2026-08-10 | escalation / rubric | 7 | 0.43 | +1.6% | +3.0% | +3.0% | +4.6% | +0.9% | +1.4% |  |
| E6 UAE halts all trade and financial dealings with Iran after m | 2026-08-19 | escalation / strict | 7 | 0.41 | -0.2% | -0.9% | +0.7% | +0.8% | -2.8% | -1.7% |  |
| E7 Gulf shipping attacks open the September escalation | 2026-09-09 | escalation / strict | 7 | 0.39 | +0.5% | -1.6% | -4.6% | -4.2% |  |  |  |
| E8 Drone strikes on Saudi export (East-West) pipeline halt Red  | 2026-09-11 | escalation / strict | 7 | 0.39 | +0.0% | -1.4% | -4.2% | -2.6% |  |  |  |
| E9 Armed-group blockade of Libya's El Sharara field (about a th | 2026-09-23 | escalation / rubric | 7 | 0.38 | -0.5% | -1.1% | +0.4% |  |  |  |  |
| E10 Hormuz tanker strikes 09-28..10-04 (Kpler: 10 tankers; trans | 2026-10-08 | escalation / provisional | 7 | 0.40 | +1.5% | -0.9% |  |  |  |  |  |
| D1 Mid-June ceasefire framework restores near-normal Hormuz flo | 2026-06-15 | deescalation / sensitivity | 7 | 0.52 | -2.1% | -0.3% | -1.0% | +2.5% | +5.5% | +5.8% | +9.4% |
| D2 Weekend US-Iran talks 'by far the most serious'; threatened  | 2026-07-27 | deescalation / sensitivity | 7 | 0.46 | -1.1% | +0.3% | -0.0% | +3.0% | +4.5% | +0.9% |  |
| D3 US strike called off 08-02 on claimed deal progress; Iran de | 2026-08-03 | deescalation / sensitivity | 7 | 0.45 | -0.7% | -0.3% | +2.7% | +2.6% | +4.2% | -0.8% |  |

**Primary: all rubric-qualifying NON-ONSET escalation events (strict + rubric tiers; provisional excluded)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -0.2% [-1.1%, +0.9%] 4/9 | -0.0% [-2.0%, +1.7%] 6/9 | +0.8% [-1.1%, +2.5%] 6/8 | +2.8% [+0.3%, +4.9%] 5/6 | +2.8% [+0.2%, +5.3%] 5/6 | +2.6% [+0.9%, +3.5%] 3/3 |
| Placebo mean (500 windows) | -0.2% | -0.1% | -0.3% | -0.3% | -0.4% | -0.8% |
| Percentile of the pooled mean among same-n placebo pooled means | 49th | 53th | 76th | 91th | 89th | 80th |
| Dispersion: SD across events vs SD across single placebo windows | +1.7% vs +2.3% | +3.0% vs +3.4% | +2.9% vs +4.7% | +3.3% vs +5.9% | +3.5% vs +6.5% | +1.4% vs +7.2% |

**Strict subset**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -0.6% [-1.6%, +0.5%] 2/6 | -0.2% [-2.8%, +2.1%] 4/6 | -0.2% [-2.1%, +1.6%] 4/6 | +3.1% [-0.8%, +5.7%] 3/4 | +3.0% [-0.8%, +6.8%] 3/4 | +3.4% [+3.3%, +3.5%] 2/2 |
| Placebo mean (500 windows) | -0.2% | -0.1% | -0.3% | -0.3% | -0.4% | -0.8% |
| Percentile of the pooled mean among same-n placebo pooled means | 33th | 50th | 57th | 88th | 86th | 80th |
| Dispersion: SD across events vs SD across single placebo windows | +1.4% vs +2.3% | +3.4% vs +3.4% | +2.6% vs +4.7% | +4.1% vs +5.9% | +4.5% vs +6.5% | +0.2% vs +7.2% |

**Non-overlapping subset (each kept event >= 20 trading days after the previous kept one): E1, E5, E7**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +0.7% [-1.6%, +3.0%] 2/3 | +0.6% [-4.6%, +3.5%] 2/3 | +0.5% [-4.2%, +4.6%] 2/3 | +3.5% [+0.9%, +6.1%] 2/2 | +4.1% [+1.4%, +6.8%] 2/2 | +3.3% [+3.3%, +3.3%] 1/1 |
| Placebo mean (500 windows) | -0.2% | -0.1% | -0.3% | -0.3% | -0.4% | -0.8% |
| Percentile of the pooled mean among same-n placebo pooled means | 76th | 70th | 70th | 83th | 83th | 76th |
| Dispersion: SD across events vs SD across single placebo windows | +2.3% vs +2.3% | +4.5% vs +3.4% | +4.4% vs +4.7% | +3.6% vs +5.9% | +3.9% vs +6.5% | n/a |

**Sensitivity: de-escalation events, SIGN-FLIPPED (i.e. short the first hop)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +0.1% [-0.3%, +0.3%] 2/3 | -0.5% [-2.7%, +1.0%] 2/3 | -2.7% [-3.0%, -2.5%] 0/3 | -4.7% [-5.5%, -4.2%] 0/3 | -2.0% [-5.8%, +0.8%] 1/3 | -9.4% [-9.4%, -9.4%] 0/1 |
| Placebo mean (500 windows) | +0.2% | +0.1% | +0.3% | +0.3% | +0.4% | +0.8% |
| Percentile of the pooled mean among same-n placebo pooled means | 47th | 34th | 12th | 8th | 25th | 8th |
| Dispersion: SD across events vs SD across single placebo windows | +0.3% vs +2.3% | +1.9% vs +3.4% | +0.3% vs +4.7% | +0.7% vs +5.9% | +3.5% vs +6.5% | n/a |

**Reference: the 2026-03-02 onset alone, same source (the onset study's row)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -1.0% [-1.0%, -1.0%] 0/1 | -0.0% [-0.0%, -0.0%] 0/1 | +7.4% [+7.4%, +7.4%] 1/1 | -0.7% [-0.7%, -0.7%] 0/1 | -1.4% [-1.4%, -1.4%] 0/1 | -5.7% [-5.7%, -5.7%] 0/1 |
| Placebo mean (500 windows) | -0.2% | -0.1% | -0.3% | -0.3% | -0.4% | -0.8% |
| Percentile of the pooled mean among same-n placebo pooled means | 35th | 53th | 94th | 53th | 52th | 24th |
| Dispersion: SD across events vs SD across single placebo windows | n/a | n/a | n/a | n/a | n/a | n/a |

**Per-industry first-hop drift, pooled over the primary events** (mean hedged CAR; k/n = positive events / events with the horizon)

| Industry | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo mean 4w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211 | +2.1% 9/9 | -0.5% 3/9 | +1.1% 6/9 | +4.2% 6/8 | +9.1% 5/6 | +11.1% 6/6 | +13.5% 3/3 | -0.6% |
| 213 | +1.4% 7/9 | -2.1% 3/9 | -0.7% 5/9 | -0.5% 4/8 | +3.8% 4/6 | +2.2% 4/6 | -1.7% 0/3 | -1.0% |
| 22 | -0.4% 2/9 | -1.5% 1/9 | -2.4% 4/9 | -3.8% 1/8 | -6.5% 0/6 | -7.6% 0/6 | -11.5% 0/3 | -0.5% |
| 324 | +1.5% 7/9 | +0.9% 3/9 | +2.5% 6/9 | +6.6% 7/8 | +13.6% 6/6 | +17.3% 6/6 | +21.7% 3/3 | -0.4% |
| 481 | -1.3% 0/9 | +0.3% 5/9 | -1.7% 3/9 | -5.3% 1/8 | -9.4% 0/6 | -12.9% 0/6 | -16.2% 0/3 | -0.3% |
| 483 | +0.5% 7/9 | +2.1% 7/9 | +1.7% 4/9 | +4.7% 8/8 | +8.7% 6/6 | +9.6% 6/6 | +14.6% 3/3 | +0.4% |
| 486 | +0.5% 6/9 | -0.7% 2/9 | -0.8% 4/9 | -0.5% 6/8 | +0.3% 4/6 | -0.2% 3/6 | -2.4% 0/3 | +0.0% |

**Per-event percentile among single placebo windows (4w)**: E1 71th; E2 79th; E3 82th; E4 73th; E5 90th; E6 66th; E7 17th; E8 27th

**Coverage**: E1: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E2: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E3: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E4: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E5: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E6: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E7: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E8: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E9: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; E10: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; D1: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; D2: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU; D3: 211:XOP, 324:CRAK, 486:AMLP, 213:OIH, 481:JETS, 483:SEA, 22:XLU

**Frequency arithmetic** (two trades per pair; two denominators, see the constants' comment)

| Event set | denominator | events 2026 YTD | events/yr | pairs/event | trades/yr | years to 30 trades |
|---|---|---:|---:|---:|---:|---:|
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 1 | 22.6 | 1.33 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 2 | 45.2 | 0.66 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 3 | 67.7 | 0.44 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 1 | 46.9 | 0.64 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 2 | 93.9 | 0.32 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 3 | 140.8 | 0.21 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 1 | 15.1 | 1.99 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 2 | 30.1 | 1.00 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 3 | 45.2 | 0.66 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 1 | 31.3 | 0.96 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 2 | 62.6 | 0.48 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 3 | 93.9 | 0.32 |

### B.2 Nasdaq, stock baskets only

### Non-onset events: source `nasdaq`, proxies `baskets only`, first hop = 211 324 486 213 481 483 22

Price span 2016-10-19 .. 2026-10-16; market = SPY; 500 placebo windows (the onset study's own draws). `d0` = event-day hedged return; `Nw` = hedged CAR over trading days 1..5N after the event day; a blank cell means the horizon is not yet observable.

| Event | d0 | kind / tier | series n | β | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| E1 Ceasefire collapse: US strikes 80+ targets, Iran hits Gulf b | 2026-07-08 | escalation / strict | 48 | 0.36 | +2.1% | +0.5% | +3.1% | +0.4% | +5.9% | +7.8% | +5.5% |
| E2 IRGC declares Strait of Hormuz closed 'until further notice' | 2026-07-13 | escalation / strict | 48 | 0.35 | +1.6% | +1.3% | +2.0% | +1.4% | +4.4% | +6.8% | +5.7% |
| E3 Resumed strike waves / Gulf shipping attacks: Brent +6% to r | 2026-07-22 | escalation / rubric | 48 | 0.33 | +0.2% | -0.3% | -2.6% | +2.9% | +4.8% | +5.4% | +4.5% |
| E4 Iranian ballistic-missile attack on US Gulf forces (07-28/29 | 2026-07-29 | escalation / strict | 48 | 0.32 | +0.1% | -2.2% | +1.4% | +2.5% | +5.5% | +2.0% |  |
| E5 Iran hardens Hormuz reopening preconditions; energy complex  | 2026-08-10 | escalation / rubric | 48 | 0.30 | +2.0% | +3.8% | +2.9% | +5.4% | +2.7% | +4.3% |  |
| E6 UAE halts all trade and financial dealings with Iran after m | 2026-08-19 | escalation / strict | 48 | 0.28 | -0.7% | -0.7% | +1.9% | +2.4% | -0.5% | +1.6% |  |
| E7 Gulf shipping attacks open the September escalation | 2026-09-09 | escalation / strict | 48 | 0.26 | +0.5% | -0.7% | -3.6% | -2.1% |  |  |  |
| E8 Drone strikes on Saudi export (East-West) pipeline halt Red  | 2026-09-11 | escalation / strict | 48 | 0.26 | +0.3% | -0.5% | -3.9% | -0.8% |  |  |  |
| E9 Armed-group blockade of Libya's El Sharara field (about a th | 2026-09-23 | escalation / rubric | 48 | 0.26 | -0.6% | -1.3% | +1.6% |  |  |  |  |
| E10 Hormuz tanker strikes 09-28..10-04 (Kpler: 10 tankers; trans | 2026-10-08 | escalation / provisional | 48 | 0.28 | +2.1% | -0.8% |  |  |  |  |  |
| D1 Mid-June ceasefire framework restores near-normal Hormuz flo | 2026-06-15 | deescalation / sensitivity | 48 | 0.39 | -2.5% | +1.0% | -0.5% | +3.8% | +6.2% | +7.2% | +11.4% |
| D2 Weekend US-Iran talks 'by far the most serious'; threatened  | 2026-07-27 | deescalation / sensitivity | 48 | 0.32 | -1.0% | -0.3% | -0.4% | +2.5% | +5.0% | +2.3% |  |
| D3 US strike called off 08-02 on claimed deal progress; Iran de | 2026-08-03 | deescalation / sensitivity | 48 | 0.33 | -0.9% | -0.2% | +3.6% | +3.7% | +6.2% | +1.2% |  |

**Primary: all rubric-qualifying NON-ONSET escalation events (strict + rubric tiers; provisional excluded)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +0.0% [-0.9%, +1.2%] 3/9 | +0.3% [-1.6%, +2.0%] 6/9 | +1.5% [+0.1%, +3.0%] 6/8 | +3.8% [+2.0%, +5.3%] 5/6 | +4.7% [+2.8%, +6.5%] 6/6 | +5.2% [+4.5%, +5.7%] 3/3 |
| Placebo mean (500 windows) | -0.1% | +0.0% | -0.1% | +0.1% | +0.2% | +0.1% |
| Percentile of the pooled mean among same-n placebo pooled means | 56th | 58th | 81th | 92th | 93th | 86th |
| Dispersion: SD across events vs SD across single placebo windows | +1.7% vs +2.7% | +2.8% vs +4.0% | +2.3% vs +5.3% | +2.4% vs +6.6% | +2.5% vs +7.2% | +0.6% vs +7.9% |

**Strict subset**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -0.4% [-1.2%, +0.5%] 2/6 | +0.1% [-2.0%, +2.2%] 4/6 | +0.7% [-0.7%, +2.0%] 4/6 | +3.8% [+1.0%, +5.7%] 3/4 | +4.6% [+1.8%, +7.3%] 4/4 | +5.6% [+5.5%, +5.7%] 2/2 |
| Placebo mean (500 windows) | -0.1% | +0.0% | -0.1% | +0.1% | +0.2% | +0.1% |
| Percentile of the pooled mean among same-n placebo pooled means | 41th | 55th | 66th | 87th | 88th | 83th |
| Dispersion: SD across events vs SD across single placebo windows | +1.2% vs +2.7% | +3.1% vs +4.0% | +1.8% vs +5.3% | +2.9% vs +6.6% | +3.2% vs +7.2% | +0.1% vs +7.9% |

**Non-overlapping subset (each kept event >= 20 trading days after the previous kept one): E1, E5, E7**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +1.2% [-0.7%, +3.8%] 2/3 | +0.8% [-3.6%, +3.1%] 2/3 | +1.2% [-2.1%, +5.4%] 2/3 | +4.3% [+2.7%, +5.9%] 2/2 | +6.1% [+4.3%, +7.8%] 2/2 | +5.5% [+5.5%, +5.5%] 1/1 |
| Placebo mean (500 windows) | -0.1% | +0.0% | -0.1% | +0.1% | +0.2% | +0.1% |
| Percentile of the pooled mean among same-n placebo pooled means | 81th | 66th | 74th | 84th | 86th | 78th |
| Dispersion: SD across events vs SD across single placebo windows | +2.3% vs +2.7% | +3.8% vs +4.0% | +3.8% vs +5.3% | +2.2% vs +6.6% | +2.5% vs +7.2% | n/a |

**Sensitivity: de-escalation events, SIGN-FLIPPED (i.e. short the first hop)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -0.2% [-1.0%, +0.3%] 2/3 | -0.9% [-3.6%, +0.5%] 2/3 | -3.3% [-3.8%, -2.5%] 0/3 | -5.8% [-6.2%, -5.0%] 0/3 | -3.6% [-7.2%, -1.2%] 0/3 | -11.4% [-11.4%, -11.4%] 0/1 |
| Placebo mean (500 windows) | +0.1% | -0.0% | +0.1% | -0.1% | -0.2% | -0.1% |
| Percentile of the pooled mean among same-n placebo pooled means | 43th | 33th | 12th | 8th | 21th | 10th |
| Dispersion: SD across events vs SD across single placebo windows | +0.7% vs +2.7% | +2.4% vs +4.0% | +0.7% vs +5.3% | +0.7% vs +6.6% | +3.2% vs +7.2% | n/a |

**Reference: the 2026-03-02 onset alone, same source (the onset study's row)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -2.1% [-2.1%, -2.1%] 0/1 | -0.4% [-0.4%, -0.4%] 0/1 | +10.1% [+10.1%, +10.1%] 1/1 | -0.5% [-0.5%, -0.5%] 0/1 | -0.2% [-0.2%, -0.2%] 0/1 | -3.6% [-3.6%, -3.6%] 0/1 |
| Placebo mean (500 windows) | -0.1% | +0.0% | -0.1% | +0.1% | +0.2% | +0.1% |
| Percentile of the pooled mean among same-n placebo pooled means | 18th | 46th | 96th | 50th | 54th | 35th |
| Dispersion: SD across events vs SD across single placebo windows | n/a | n/a | n/a | n/a | n/a | n/a |

**Per-industry first-hop drift, pooled over the primary events** (mean hedged CAR; k/n = positive events / events with the horizon)

| Industry | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo mean 4w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211 | +2.2% 9/9 | -0.9% 3/9 | +1.2% 6/9 | +4.4% 7/8 | +8.9% 5/6 | +10.6% 6/6 | +14.8% 3/3 | -0.5% |
| 213 | +1.6% 7/9 | -2.0% 3/9 | -0.6% 5/9 | +0.5% 4/8 | +6.5% 4/6 | +4.8% 4/6 | +1.4% 2/3 | -0.9% |
| 22 | -0.5% 2/9 | -1.5% 1/9 | -2.4% 1/9 | -3.9% 0/8 | -6.5% 0/6 | -7.7% 0/6 | -11.3% 0/3 | -0.6% |
| 324 | +2.1% 6/9 | +3.6% 7/9 | +5.8% 6/9 | +13.4% 8/8 | +22.0% 6/6 | +30.5% 6/6 | +42.0% 3/3 | -0.3% |
| 481 | -1.7% 2/9 | +0.5% 5/9 | -2.1% 4/9 | -7.2% 1/8 | -13.3% 0/6 | -17.3% 0/6 | -21.9% 0/3 | -0.0% |
| 483 | +0.2% 4/9 | +1.1% 6/9 | +1.0% 5/9 | +3.3% 6/8 | +7.6% 6/6 | +10.0% 6/6 | +12.5% 3/3 | +1.2% |
| 486 | +0.3% 6/9 | -0.8% 3/9 | -0.8% 4/9 | +0.2% 3/8 | +1.4% 5/6 | +1.8% 5/6 | -1.0% 1/3 | +0.5% |

**Per-event percentile among single placebo windows (4w)**: E1 60th; E2 68th; E3 79th; E4 77th; E5 91th; E6 76th; E7 33th; E8 49th

**Coverage**: E1: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E2: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E3: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E4: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E5: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E6: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E7: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E8: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E9: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; E10: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; D1: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; D2: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8; D3: 211:basketx7, 324:basketx6, 486:basketx7, 213:basketx7, 481:basketx8, 483:basketx5, 22:basketx8

**Frequency arithmetic** (two trades per pair; two denominators, see the constants' comment)

| Event set | denominator | events 2026 YTD | events/yr | pairs/event | trades/yr | years to 30 trades |
|---|---|---:|---:|---:|---:|---:|
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 1 | 22.6 | 1.33 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 2 | 45.2 | 0.66 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 3 | 67.7 | 0.44 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 1 | 46.9 | 0.64 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 2 | 93.9 | 0.32 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 3 | 140.8 | 0.21 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 1 | 15.1 | 1.99 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 2 | 30.1 | 1.00 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 3 | 45.2 | 0.66 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 1 | 31.3 | 0.96 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 2 | 62.6 | 0.48 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 3 | 93.9 | 0.32 |

### B.3 French 49 industries (data end 2026-08-31)

### Non-onset events: source `french`, proxies `French 49 industries`, first hop = 211 324 486 213 481 483 22

Price span 1985-01-02 .. 2026-08-31; market = Fama-French Mkt-RF + RF; 500 placebo windows (the onset study's own draws). `d0` = event-day hedged return; `Nw` = hedged CAR over trading days 1..5N after the event day; a blank cell means the horizon is not yet observable.

| Event | d0 | kind / tier | series n | β | d0 | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| E1 Ceasefire collapse: US strikes 80+ targets, Iran hits Gulf b | 2026-07-08 | escalation / strict | 3 | 0.28 | +0.1% | +0.8% | +3.6% | +0.5% | +5.1% |  |  |
| E2 IRGC declares Strait of Hormuz closed 'until further notice' | 2026-07-13 | escalation / strict | 3 | 0.28 | +1.6% | +0.9% | +1.5% | +0.8% | +3.3% |  |  |
| E3 Resumed strike waves / Gulf shipping attacks: Brent +6% to r | 2026-07-22 | escalation / rubric | 3 | 0.26 | +0.9% | -0.5% | -3.1% | +1.6% |  |  |  |
| E4 Iranian ballistic-missile attack on US Gulf forces (07-28/29 | 2026-07-29 | escalation / strict | 3 | 0.25 | +0.6% | -2.5% | +0.4% | +1.5% |  |  |  |
| E5 Iran hardens Hormuz reopening preconditions; energy complex  | 2026-08-10 | escalation / rubric | 3 | 0.22 | +1.5% | +2.1% | +2.4% |  |  |  |  |
| E6 UAE halts all trade and financial dealings with Iran after m | 2026-08-19 | escalation / strict | 3 | 0.21 | +0.2% | -0.7% |  |  |  |  |  |
| E7 Gulf shipping attacks open the September escalation | 2026-09-09 | escalation / strict | | skipped: after the price span | | | | | | | |
| E8 Drone strikes on Saudi export (East-West) pipeline halt Red  | 2026-09-11 | escalation / strict | | skipped: after the price span | | | | | | | |
| E9 Armed-group blockade of Libya's El Sharara field (about a th | 2026-09-23 | escalation / rubric | | skipped: after the price span | | | | | | | |
| E10 Hormuz tanker strikes 09-28..10-04 (Kpler: 10 tankers; trans | 2026-10-08 | escalation / provisional | | skipped: after the price span | | | | | | | |
| D1 Mid-June ceasefire framework restores near-normal Hormuz flo | 2026-06-15 | deescalation / sensitivity | 3 | 0.31 | -1.4% | -0.2% | -0.3% | +2.4% | +4.9% | +4.9% |  |
| D2 Weekend US-Iran talks 'by far the most serious'; threatened  | 2026-07-27 | deescalation / sensitivity | 3 | 0.25 | -1.3% | -1.2% | -0.6% | +1.9% |  |  |  |
| D3 US strike called off 08-02 on claimed deal progress; Iran de | 2026-08-03 | deescalation / sensitivity | 3 | 0.24 | -0.5% | +0.6% | +2.8% | +1.8% |  |  |  |

**Primary: all rubric-qualifying NON-ONSET escalation events (strict + rubric tiers; provisional excluded)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +0.0% [-1.1%, +1.2%] 3/6 | +1.0% [-1.3%, +2.7%] 4/5 | +1.1% [+0.6%, +1.5%] 4/4 | +4.2% [+3.3%, +5.1%] 2/2 | n/a | n/a |
| Placebo mean (500 windows) | -0.0% | +0.0% | +0.2% | +0.3% | n/a | n/a |
| Percentile of the pooled mean among same-n placebo pooled means | 51th | 88th | 78th | 97th | n/a | n/a |
| Dispersion: SD across events vs SD across single placebo windows | +1.6% vs +1.3% | +2.6% vs +1.9% | +0.5% vs +2.6% | +1.3% vs +3.2% | n/a | n/a |

**Strict subset**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -0.4% [-1.7%, +0.8%] 2/4 | +1.8% [+0.4%, +3.6%] 3/3 | +0.9% [+0.5%, +1.5%] 3/3 | +4.2% [+3.3%, +5.1%] 2/2 | n/a | n/a |
| Placebo mean (500 windows) | -0.0% | +0.0% | +0.2% | +0.3% | n/a | n/a |
| Percentile of the pooled mean among same-n placebo pooled means | 26th | 96th | 71th | 96th | n/a | n/a |
| Dispersion: SD across events vs SD across single placebo windows | +1.6% vs +1.3% | +1.6% vs +1.9% | +0.5% vs +2.6% | +1.3% vs +3.2% | n/a | n/a |

**Non-overlapping subset (each kept event >= 20 trading days after the previous kept one): E1, E5**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +1.5% [+0.8%, +2.1%] 2/2 | +3.0% [+2.4%, +3.6%] 2/2 | +0.5% [+0.5%, +0.5%] 1/1 | +5.1% [+5.1%, +5.1%] 1/1 | n/a | n/a |
| Placebo mean (500 windows) | -0.0% | +0.0% | +0.2% | +0.3% | n/a | n/a |
| Percentile of the pooled mean among same-n placebo pooled means | 95th | 98th | 58th | 92th | n/a | n/a |
| Dispersion: SD across events vs SD across single placebo windows | +1.0% vs +1.3% | +0.8% vs +1.9% | n/a | n/a | n/a | n/a |

**Sensitivity: de-escalation events, SIGN-FLIPPED (i.e. short the first hop)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | +0.3% [-0.6%, +1.2%] 2/3 | -0.6% [-2.8%, +0.6%] 2/3 | -2.0% [-2.4%, -1.8%] 0/3 | -4.9% [-4.9%, -4.9%] 0/1 | -4.9% [-4.9%, -4.9%] 0/1 | n/a |
| Placebo mean (500 windows) | +0.0% | -0.0% | -0.2% | -0.3% | -0.5% | n/a |
| Percentile of the pooled mean among same-n placebo pooled means | 66th | 28th | 9th | 8th | 11th | n/a |
| Dispersion: SD across events vs SD across single placebo windows | +0.9% vs +1.3% | +1.8% vs +1.9% | +0.3% vs +2.6% | n/a | n/a | n/a |

**Reference: the 2026-03-02 onset alone, same source (the onset study's row)**

| Statistic | 1w | 2w | 4w | 6w | 8w | 12w |
|---|---:|---:|---:|---:|---:|---:|
| Pooled mean [bootstrap 95% CI], positive/n | -1.1% [-1.1%, -1.1%] 0/1 | +0.4% [+0.4%, +0.4%] 1/1 | +6.0% [+6.0%, +6.0%] 1/1 | -2.0% [-2.0%, -2.0%] 0/1 | -1.9% [-1.9%, -1.9%] 0/1 | -6.1% [-6.1%, -6.1%] 0/1 |
| Placebo mean (500 windows) | -0.0% | +0.0% | +0.2% | +0.3% | +0.5% | +0.5% |
| Percentile of the pooled mean among same-n placebo pooled means | 16th | 58th | 98th | 21th | 24th | 6th |
| Dispersion: SD across events vs SD across single placebo windows | n/a | n/a | n/a | n/a | n/a | n/a |

**Per-industry first-hop drift, pooled over the primary events** (mean hedged CAR; k/n = positive events / events with the horizon)

| Industry | d0 | 1w | 2w | 4w | 6w | 8w | 12w | placebo mean 4w |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 211:Oil | +2.3% 6/6 | +0.6% 3/6 | +3.9% 4/5 | +7.6% 4/4 | +15.0% 2/2 | n/a | n/a | +0.1% |
| 22:Util | +0.1% 2/6 | -0.9% 1/6 | -1.1% 2/5 | -3.7% 0/4 | -3.5% 0/2 | n/a | n/a | +0.5% |
| 486:Trans | +0.0% 3/6 | +0.3% 5/6 | +0.2% 3/5 | -0.6% 1/4 | +1.1% 2/2 | n/a | n/a | +0.0% |

**Per-event percentile among single placebo windows (4w)**: E1 56th; E2 62th; E3 73th; E4 72th

**Coverage**: E1: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; E2: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; E3: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; E4: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; E5: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; E6: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; D1: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; D2: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util; D3: 211:Oil, 324:folded, 486:Trans, 213:folded, 481:folded, 483:folded, 22:Util

**Frequency arithmetic** (two trades per pair; two denominators, see the constants' comment)

| Event set | denominator | events 2026 YTD | events/yr | pairs/event | trades/yr | years to 30 trades |
|---|---|---:|---:|---:|---:|---:|
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 1 | 22.6 | 1.33 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 2 | 45.2 | 0.66 |
| primary (all rubric-qualifying escalation events) | calendar YTD (0.80 yr) | 9 | 11.3 | 3 | 67.7 | 0.44 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 1 | 46.9 | 0.64 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 2 | 93.9 | 0.32 |
| primary (all rubric-qualifying escalation events) | dated window 06-01..10-19 (0.38 yr) | 9 | 23.5 | 3 | 140.8 | 0.21 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 1 | 15.1 | 1.99 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 2 | 30.1 | 1.00 |
| strict subset | calendar YTD (0.80 yr) | 6 | 7.5 | 3 | 45.2 | 0.66 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 1 | 31.3 | 0.96 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 2 | 62.6 | 0.48 |
| strict subset | dated window 06-01..10-19 (0.38 yr) | 6 | 15.6 | 3 | 93.9 | 0.32 |

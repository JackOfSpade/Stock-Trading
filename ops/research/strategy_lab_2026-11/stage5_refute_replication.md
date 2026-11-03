# Stage 5 refutation, lens: replication and look-ahead

Code: scratchpad `r5/` (`common.py`, `a1.py` to `a9.py`), written from scratch; no project script was imported. Read-only apart from this file. No network, git or BigQuery. Everything here is post hoc.

Samples: **A** = the 300, **H** = the 80 holdout, **P** = pooled A+H, always scores 0 and +1 only unless stated. Returns are 20-day open-to-open net of IWM. "Raw" means not winsorized.

## Verdict

**WEAKENED, not refuted.** The arithmetic and the event timing hold up. I found no off-by-one, split, stale-bar, entry or transcript-date error that creates the result. I did find one look-ahead the pre-registration does not disclose: the market-cap filter uses a snapshot from about late October 2026, after nearly every exit. I also found that the holdout confirmation is weak evidence: its three conditions pass 25% of the time on shuffled labels, and it rests on two winners, one of them from a single news gap the day before exit.

## 1. Replication of prices (favours the finding)

All 380 events were recomputed from raw Nasdaq bars, not only 60.

| check | result |
|---|---|
| reaction, r5, r10, r20 versus key.json and results files | 0 differences above 1e-9 |
| entry date versus key | 0 mismatches |
| trading days from entry to exit on the IWM calendar | exactly 20 for all 380 |
| ticker bars missing or extra against the IWM calendar, close(i-1) to exit | 0 and 0 |
| open outside the day's high-low range, entry window | 0 bars |
| reaction printed in the pack header versus key | 0 mismatches |
| event date not a trading day | 0 |
| same bars in the earlier `es/px` fetch | 132 tickers, 16,596 bars, 0 differences |
| A/H overlap | 0 ids; 1 ticker (SCHL) in both, different quarters |

The recomputation shares the pipeline's definition, so it proves the code does what the pre-registration says, not that Nasdaq's prints are right. No second price source was checked, because network calls were not allowed. The `es/px` comparison is the same vendor fetched earlier the same day.

Hand check, ADV: reaction 25.34/41.72-1 = -39.26%; stock 31.49/25.22-1 = +24.86%; IWM 293.70/300.46-1 = -2.25%; net +27.11%. It matches.

**Splits and bad bars.** Split-like overnight ratios in the window: GTE, NABL and VPG on the event day (earnings moves, in the reaction and not in the return), HZO on day 12 (35.68 to 51.885 on 7.7M shares against 0.2M, so a news event, score 0). No +1 event has a split-like ratio. One stale case: GBLI (score 0) has 6 flat or zero-volume bars; removing it moves the pooled gap from +2.64% to +2.68%. Adjustment for splits and dividends cannot be proven from one source, but no unexplained jump exists inside a hold window.

## 2. Timing and look-ahead in the return (favours the finding)

- Entry is open(i+2); the header reaction ends at close(i+1). Nothing the reader sees postdates entry.
- Reader audit from agent logs (`wf_b4fa981b-474`, `wf_0afc15f0-e42`): label, prompt path and Read path agree on 330/330 and 80/80. Stored score and reason equal the agent's output on 300/300 and 80/80. In the holdout, tools were Read plus StructuredOutput only and the model was `claude-sonnet-5-5`; the A run's summary records the same. So no id mismatch.
- Holdout order is clean by file times: `pack_h` and `secure_h/key.json` were created at 18:41:23, the same second as the pre-registration edit; reads ran 18:41:37 to 18:42:43 (local time).
- Call date minus event date: 0 on 261, +1 on 118, -1 on 1 (KOPN, score 0).
- From the greeting in each transcript I classed calls as morning or afternoon. The largest move falls where it should, so event dates are aligned:

| class | n | mean abs move day i | day i+1 | gap to entry |
|---|---|---:|---:|---:|
| morning call on i | 126 | 8.1% | 3.4% | 1.1% |
| afternoon call on i | 102 | 2.9% | 10.3% | 1.3% |
| morning call on i+1 | 110 | 2.0% | 6.3% | 1.1% |

- **Call after the reaction window** (afternoon call on i+1): 3 events, GAIN, RLJ, GSBC, all score 0. So none of the +1 reads has this problem. 5 more have unknown call time on i+1 (2 are +1: PNTG +0.8%, NPKI +4.2%). None matters to the means.
- **Publication.** No per-transcript timestamp exists. Each page says transcripts come from Quartr and are "published within hours" of the call, and "Last updated" equals the call date on 380/380. That field could simply copy the call date, so it is weak. But the shortest call-to-entry time is about 15 hours on the 3 late events and about 21 hours or more on the rest, so timing is unlikely to bind.
- **The gap before entry is not captured**: +1 minus 0 on the net gap from close(i+1) to open(i+2) is A 0.00%, H -0.64%, P -0.13%. The reader is not being credited with an overnight move.

### Neighbouring timing (raw r20, +1 minus 0, week-clustered t)

| spec | A | H | P |
|---|---|---|---|
| pre-registered | +2.80 (2.34) | +2.03 (0.57) | +2.64 (1.71) |
| exit 1 day early | +2.33 (1.89) | +2.04 (0.57) | +2.27 (1.45) |
| exit 1 day late | +3.14 (2.67) | +1.66 (0.53) | +2.82 (2.01) |
| enter and exit 1 day late | +2.98 (2.19) | +2.36 (0.99) | +2.83 (2.00) |
| enter and exit 2 days late | +3.23 (2.71) | +2.20 (0.87) | +2.99 (2.28) |
| close(i+2) to close(i+22) | +2.68 (2.61) | +1.65 (0.63) | +2.45 (1.98) |
| placebo: 20 days before event | +0.34 (0.31) | +0.45 (0.32) | +0.35 (0.40) |
| placebo: entry-day open to close | +0.37 (0.98) | +0.04 (0.05) | +0.31 (0.88) |

The gap does not depend on an exact day, and the pre-event placebo is near zero. The accrual is gradual (P: +0.05 day 1, +1.56 day 5, +1.39 day 10, +2.00 day 15), which is not what a data error looks like. This is the strongest evidence in favour from this lens.

Subgroups by call timing do not agree across samples, so I read them as noise:

| class | A | H | P |
|---|---|---|---|
| morning, call on i | -1.11 | +7.73 | +0.39 |
| morning, call on i+1 | +6.77 | -4.61 | +4.83 |
| afternoon, call on i | +3.18 | +1.31 | +2.27 |

## 3. Look-ahead found: the market-cap filter

`ev.py` keeps rows with `marketCap` in $300M-$2B, but the Nasdaq calendar returns a recent value, not one as of the row's date.

- Of 1,225 tickers with several dates from 2025-01 to 2026-11, 1,094 show one identical cap on every date. LNN shows 1,094,589,570 on seven of its eight dates across 22 months; the odd one is January 2026.
- Dating the snapshot: for 50 tickers where a stale January or February 2026 value also exists, I grid-searched the date pair that best explains the change in cap by the change in price. Median absolute error is lowest at 2026-10-28 (0.058), and clearly worse for earlier dates (0.113 mid-Sep, 0.128 late Jul, 0.185 end Jun). So the snapshot is about mid to late October. The grid is coarse (3-day steps, 50 tickers), so treat it as a rough date.
- The latest exit in the sample is 2026-10-26. **The filter therefore looks at market cap at about or after the exit date.** The pre-registration's accepted limits do not list this.

What it does: names that ended inside the band are kept, so names that started inside and rose above $2B or fell below $300M are gone, and names that started outside and moved in are included.

Implied cap at the event (snapshot times close(i-1)/close(2026-10-28)):

- 37 of 380 (9.7%) were outside the band at the event: 12 below $300M (mean r20 +10.6%, risers) and 25 above $2B (mean r20 -5.2%, fallers). Their scores: 26 at 0, 10 at +1, 1 at -1.
- Dropping those 37 raises the effect:

| | A | H | P |
|---|---|---|---|
| all | +2.80 (2.34) | +2.03 (0.57) | +2.64 (1.71) |
| in band at event | +4.15 (4.60) | +2.60 (0.68) | +3.81 (3.03) |

That favours the finding on the part I can see, but it is **only half a correction and it flatters the result**. It removes +1 fallers such as AADX (-30.2%) and KALU (-14.6%), while the mirror-image names cannot be added back: stocks in band at the event that later left it. Those are unread and unpriced. The Jul-Sep calendar has 319 such candidate events with `noOfEsts` <= 2 (snapshot cap $150-300M or $2-3.5B), and 2 have local prices.

Bound on the missing names, assuming a roll-out rate like the 9.7% seen on the way in. The returns below are my assumptions, not measurements:

| added events | pooled gap |
|---|---|
| none | +2.64% |
| 5 in +1, 14 in 0, same return in both groups (+30% or -25%) | +2.46 to +2.56% |
| 5 in +1 at -15%, 14 in 0 at +15% | +1.09% |
| 3 in +1 at -25%, 8 in 0 at +30% | +1.00% |
| 5 in +1 at -25%, 14 in 0 at +30% (extreme) | -0.11% |

Only an adverse split between groups hurts much, and I have no evidence of one. The universe's level is a separate point: dropping sub-$300M losers while also dropping $2B+ winners has an unknown net effect on the +1.1% universe mean, which bears on holdout condition 2.

By snapshot-cap quintile the gap is uneven, with no clear reading:

| quintile (cut points $448M, $648M, $970M, $1.40B) | A | H | P (n1/n0) |
|---|---|---|---|
| lowest | +7.56 | +0.74 | +6.26 (21/54) |
| 2 | +2.73 | +4.36 | +2.99 (20/55) |
| 3 | -0.89 | -0.86 | -0.37 (17/59) |
| 4 | +4.72 | +8.57 | +5.63 (17/58) |
| highest | +0.08 | -0.38 | 0.00 (27/48) |

The lowest band is where survival selection removes the most losers, and it carries the largest A gap, though it barely shows in H (4 names). The gap is zero for the 27 largest +1 names. A narrow slice, $600M-$1B, is negative in both samples: A -2.21, H -2.76, P -2.22 (n1=24, t -0.80). I would not rely on that slice alone.

**The fix** is a rebuilt universe from a point-in-time cap (shares times price at the event), reading and scoring the newly included events. It needs network and new reads, so it was not done.

## 4. "Low coverage" is not established

`noOfEsts` does not behave like an analyst count. Jul-Sep calendar: median 6 for caps above $20B, with 14% at 2 or fewer; LLY shows 3 on 2026-08-05. In the $300M-$2B band the median is 2 and 61% are at 2 or fewer. The sample includes LCID, BTDR, CLSK, BXMT, SOPH and AEHR, which are not obscure. The pre-registration said the field is "broader", but "low-coverage small caps" is a stronger label than the data supports.

## 5. Masking audit (380 packs)

**No outcome leak found.** Company and date masking is leaky, as the pilot suggested.

| item | documents |
|---|---|
| 4-digit year remaining | 0 |
| ticker remaining as a whole word | 0 |
| bare month names remaining | 309 (1,562 uses) |
| the call's own month named literally | 104 |
| weekday names | 38 |
| `'27`-style year | 2 tokens |
| slash patterns | 55; some are dates like 6/30, many are ratios like 80/20 |
| unmasked web domains | 167, such as www.donegalgroup.com, redwoodtrust.com, jjill.com, investors.krispykreme.com |
| site footer | 380 (Quartr note, masked date) |

- The site summary sits at the start of the body, about 300 characters. In 360 documents it is cut with everything before "Operator"; in the other 20 the first 1,000 characters are dropped. Of the 2 documents with summary-like words in the opening, both are transcript text (NVGS, ITRN). Non-"Operator" starts are 6/102 among +1 and 14/274 among 0, so they do not concentrate in +1.
- Phrases about events after the call: 11 matches, all boilerplate about a replay or follow-up "following the call". Sampled pack tails end in the site footer with no later content.
- Reasons: my pattern search finds none saying "since the call" or describing a move after the reaction. 8 cite 2027, 2 cite 2026 and 1 cites 2028, so readers can place the calendar year despite masking. Only 9 dollar figures across all reasons are absent from their transcript (some are formatting), and the one suspicious price claim I traced, AHRT's "$5.50 to $7.08", is in the transcript.
- The 167 readable domains fit the 91% recognition rate. Recognition does not reveal returns if Sonnet 5.5's knowledge cutoff really is before July 2026. **I could not verify that cutoff**: it is an assumption of the pre-registration, and I tested only that reasons do not cite outcomes.

## 6. Group statistics recomputed

Winsorizing as pre-registered, separately per sample. At n=80 the formula takes the minimum and maximum, so H is effectively raw. A's w20 equals my own exactly.

| | n1 / n0 | mean +1 | mean 0 | gap | median +1 / 0 | hit rate +1 / 0 |
|---|---|---:|---:|---:|---:|---|
| A | 80 / 219 | +3.17% | +0.30% | **+2.87%** | +1.51 / -0.53 | 61% / 48% |
| H | 22 / 55 | +2.55% | +0.52% | **+2.03%** | +3.52 / -0.22 | 64% / 49% |
| P (winsorized on P) | 102 / 274 | +3.07% | +0.36% | **+2.71%** | +2.40 / -0.47 | 62% / 48% |

The stated results replicate exactly.

| inference | A | H | P |
|---|---:|---:|---:|
| t, entry week (as reported) | **2.55** (G=11) | **0.57** (G=11) | **1.84** (G=12) |
| t, ticker (about event level) | 1.95 | 0.75 | 2.12 |
| t, entry date | 2.22 (G=36) | 0.75 (G=25) | 2.24 (G=39) |
| t, exit week | 3.29 | 0.62 | 3.57 |
| week fixed effects, gap (t) | 2.70 (2.44) | 2.47 (0.66) | 2.74 (1.78) |
| wild cluster bootstrap p, one-sided | 0.009 | 0.267 | 0.028 |
| within-week permutation p, one-sided | 0.041 | 0.202 | 0.017 |
| event bootstrap 95% CI of gap | [0.00, 5.69] | [-3.34, 7.47] | [0.25, 5.33] |
| leave one week out, range | 2.38 to 3.90 | 0.38 to 5.75 | 2.05 to 4.25 |

Notes:

- In A the week-clustered t (2.55) is higher than the event-level t (1.95). Clustering usually lowers t. With 11 unequal clusters, two holding two-thirds of events, the small-G standard error is probably too low. I would read A at about 2.0, not 2.55.
- 20-day windows overlap across all weeks, so weeks are not independent. Clustering by month is meaningless with 3 clusters (t 4.5 to 18 in A and P), and I report it only to say so. About 4 independent windows exist, as the pre-registration says.
- The P p-values are not clean: P includes the A sample that generated the hypothesis.

## 7. How much the holdout confirmation is worth

**False-confirm rate.** Shuffling H's labels within week 20,000 times, keeping H's returns:

| true effect added to +1 | all three conditions pass |
|---:|---:|
| 0 | **25.1%** |
| +1.5% | 43.6% |
| +2.87% (A's estimate) | 62.6% |
| +4.0% | 76.6% |

So passing has a likelihood ratio of about 2.5 for "effect as large as A" against "no effect". That is mild support. Condition 2 is easier than it looks because H's unconditional mean is already +1.10% net of IWM.

**Two names carry it.** H without ELMT: gap +1.03, condition 1 fails. Without ODD: +0.94, conditions 1 and 2 fail. Without both: -0.17. Removing top names from one group only is an unfair test (removing the top two from both groups leaves +0.78), but with 22 events it shows how little is holding the mean. The median is steadier: the median gap is +3.74, and median(+1) stays near +2.8% with both names removed.

**ELMT is one news gap.** Entry 8/17 at 18.65; close 16.19 on 9/11; open 22.47 on 9/14 on 14.0M shares against 0.14M the session before; exit 9/15 at open 21.99; close that day 19.57. It looks like a real print, not a data error, since the volume confirms it. I did not establish the news. At the 9/11 close the trade was about -13% before IWM. At the close of exit day it is about +5%. ELMT is +23.6% as scored. The other top names are ODD +25.6% and TKNO +11.7%.

**Neighbouring specs on H's three conditions.** Pass on: pre-registered, exit 1 day early, exit 1 day late, enter 1 day late, open to close, in-band at event, beta adjusted. Fail on: enter 2 days late (mean +1 = +1.38%), close to close (mean +1 = +1.16%), no IWM netting (mean +1 = +0.14%). The gap condition and the median condition hold in all of these; only the level condition fails.

## 8. IWM netting and beta

This goes slightly beyond the lens, but it is part of checking the net return.

- IWM fell over the windows: mean 20-day -1.97% (range -6.5% to +3.9%). Before netting, +1 made **A +1.00%, H +0.14%, P +0.81%**. Most of the positive +1 level comes from IWM's fall, so the long leg alone has little level. The pre-registration's hedged form is the relevant one, but a hedged book depends on that spread holding when IWM rises, and this sample has little of that.
- +1 entries fell in slightly worse IWM windows (P -2.22% against -1.88%), and mean betas are below 1 (from pre-event bars, May to the event: P 0.86 for +1, 0.82 for 0). So some of the gap may be a low-beta stock looking good against a falling index.

| raw gap (t) | A | H | P |
|---|---|---|---|
| net of IWM | +2.80 (2.34) | +2.03 (0.57) | +2.64 (1.71) |
| no netting | +2.41 (1.79) | +1.89 (0.55) | +2.29 (1.44) |
| own beta | +2.09 (1.53) | +1.66 (0.44) | +2.02 (1.20) |
| beta shrunk half to 1 | +2.45 (1.93) | +1.84 (0.51) | +2.33 (1.45) |
| own beta, week fixed effects | +1.91 (1.39) | +2.17 (0.54) | +2.02 (1.15) |

So about 0.3 to 0.6 points of the pooled 2.64 may be benchmark exposure. Betas use only about 2 to 5 months of bars, so they are noisy, which itself lowers t.

**Dividends.** Returns omit them. REIT, BDC and bank-type calls (3 or more FFO, NAV, non-accrual or NIM mentions) are P 15.7% of +1 and 16.4% of 0, so there is no pooled bias. In H the split is 4.5% against 23.6%, which understates 0 and flatters +1 by perhaps 0.1 to 0.2 points. That is my rough estimate, not a measurement. Excluding those names: A +2.68 (1.70), H +2.11 (0.55), P +2.54 (1.30).

## 9. Not checked

- No second price source, because network was not allowed.
- No actual transcript publication times.
- Sonnet 5.5's actual knowledge cutoff.
- Returns of names lost to the cap filter.
- Delisted names: only 2 Jul-Sep rows have a blank cap (SPMC, PARA), but a delisted name may vanish from the calendar altogether, so this does not bound it.
- Selection from 619 in-band events to 380 with a matched transcript. The 239 dropped are unread.

## 10. Comparisons tried

About 46 distinct specifications on returns: timing classes 5, timing shifts 8, placebo and path 10, cap filters and quintiles 11, netting and beta 5, ex-yield 1, name removals 6. Most ran on A, H and P, so about 130 cells. In addition 7 ways of computing inference, and 10 specs of the holdout conditions. None was pre-registered. Expect some extreme cells by chance, including the $600M-$1B flip and the timing subgroups.

## Sample of recomputed events (60: 30 +1, 30 score 0)

All 380 were recomputed; this is a seeded sample with 22 from A and 8 from H in each group. "mine" and "file" are net r20 in %.

| s | ticker | score | event | call | close(i-1) | close(i+1) | react % | entry | open | exit | open | IWM in | IWM out | mine | file |
|---|---|---|---|---|---:|---:|---:|---|---:|---|---:|---:|---:|---:|---:|
| A | ADV | +1 | 2026-08-05 | 2026-08-05 | 41.72 | 25.34 | -39.26 | 2026-08-07 | 25.22 | 2026-09-04 | 31.49 | 300.46 | 293.70 | +27.11 | +27.11 |
| H | ARKO | +1 | 2026-08-07 | 2026-08-07 | 7.29 | 4.70 | -35.53 | 2026-08-11 | 4.69 | 2026-09-09 | 4.70 | 300.93 | 293.46 | +2.70 | +2.70 |
| A | ASTE | +1 | 2026-08-05 | 2026-08-05 | 52.25 | 44.18 | -15.44 | 2026-08-07 | 44.20 | 2026-09-04 | 42.33 | 300.46 | 293.70 | -1.98 | -1.98 |
| H | BWFG | +1 | 2026-07-23 | 2026-07-23 | 59.50 | 62.21 | +4.55 | 2026-07-27 | 62.41 | 2026-08-24 | 66.20 | 293.98 | 299.55 | +4.18 | +4.18 |
| A | CARL | +1 | 2026-08-05 | 2026-08-05 | 13.43 | 13.70 | +2.01 | 2026-08-07 | 13.70 | 2026-09-04 | 15.38 | 300.46 | 293.70 | +14.51 | +14.51 |
| H | CCSI | +1 | 2026-08-06 | 2026-08-06 | 38.17 | 35.14 | -7.94 | 2026-08-10 | 35.52 | 2026-09-08 | 34.99 | 300.51 | 295.34 | +0.23 | +0.23 |
| A | CINT | +1 | 2026-08-11 | 2026-08-11 | 3.63 | 3.62 | -0.28 | 2026-08-13 | 3.54 | 2026-09-11 | 3.08 | 304.04 | 290.71 | -8.61 | -8.61 |
| A | CLSK | +1 | 2026-08-06 | 2026-08-06 | 13.50 | 12.30 | -8.89 | 2026-08-10 | 12.29 | 2026-09-08 | 12.70 | 300.51 | 295.34 | +5.06 | +5.06 |
| A | CPS | +1 | 2026-08-05 | 2026-08-06 | 30.76 | 27.63 | -10.18 | 2026-08-07 | 28.51 | 2026-09-04 | 26.60 | 300.46 | 293.70 | -4.45 | -4.45 |
| A | ESTA | +1 | 2026-08-06 | 2026-08-06 | 91.25 | 77.42 | -15.16 | 2026-08-10 | 76.66 | 2026-09-08 | 74.08 | 300.51 | 295.34 | -1.65 | -1.65 |
| H | FOSL | +1 | 2026-08-12 | 2026-08-12 | 5.24 | 5.58 | +6.49 | 2026-08-14 | 5.64 | 2026-09-14 | 4.64 | 303.28 | 287.49 | -12.52 | -12.52 |
| A | GNK | +1 | 2026-08-05 | 2026-08-06 | 25.97 | 25.13 | -3.23 | 2026-08-07 | 25.12 | 2026-09-04 | 27.26 | 300.46 | 293.70 | +10.77 | +10.77 |
| A | LOB | +1 | 2026-07-22 | 2026-07-23 | 41.67 | 42.65 | +2.35 | 2026-07-24 | 42.87 | 2026-08-21 | 41.06 | 293.41 | 299.85 | -6.42 | -6.42 |
| H | LPTH | +1 | 2026-09-10 | 2026-09-10 | 10.14 | 9.20 | -9.27 | 2026-09-14 | 8.85 | 2026-10-12 | 9.56 | 287.49 | 278.47 | +11.16 | +11.16 |
| A | LSAK | +1 | 2026-09-09 | 2026-09-10 | 4.52 | 4.49 | -0.66 | 2026-09-11 | 4.49 | 2026-10-09 | 4.76 | 290.71 | 278.21 | +10.31 | +10.31 |
| A | LUXE | +1 | 2026-09-16 | 2026-09-16 | 7.15 | 9.48 | +32.59 | 2026-09-18 | 9.48 | 2026-10-16 | 9.68 | 284.92 | 275.52 | +5.41 | +5.41 |
| H | MTUS | +1 | 2026-08-03 | 2026-08-04 | 20.12 | 21.56 | +7.16 | 2026-08-05 | 22.02 | 2026-09-02 | 19.04 | 302.43 | 291.54 | -9.93 | -9.93 |
| A | NVRI | +1 | 2026-08-11 | 2026-08-11 | 21.87 | 20.73 | -5.21 | 2026-08-13 | 20.68 | 2026-09-11 | 22.62 | 304.04 | 290.71 | +13.77 | +13.77 |
| A | OOMA | +1 | 2026-08-26 | 2026-08-26 | 20.59 | 23.04 | +11.90 | 2026-08-28 | 23.05 | 2026-09-28 | 21.63 | 299.70 | 280.33 | +0.30 | +0.30 |
| A | OPFI | +1 | 2026-08-10 | 2026-08-10 | 9.40 | 6.59 | -29.89 | 2026-08-12 | 6.65 | 2026-09-10 | 7.50 | 303.02 | 288.48 | +17.58 | +17.58 |
| A | PRE | +1 | 2026-08-18 | 2026-08-18 | 19.37 | 18.76 | -3.15 | 2026-08-20 | 18.76 | 2026-09-18 | 24.41 | 299.27 | 284.92 | +34.91 | +34.91 |
| H | PRSU | +1 | 2026-08-05 | 2026-08-05 | 51.59 | 47.67 | -7.60 | 2026-08-07 | 47.33 | 2026-09-04 | 47.62 | 300.46 | 293.70 | +2.86 | +2.86 |
| A | RDVT | +1 | 2026-08-10 | 2026-08-10 | 65.48 | 71.22 | +8.76 | 2026-08-12 | 72.81 | 2026-09-10 | 74.07 | 303.02 | 288.48 | +6.53 | +6.53 |
| A | RERE | +1 | 2026-08-20 | 2026-08-20 | 4.59 | 4.16 | -9.37 | 2026-08-24 | 4.13 | 2026-09-22 | 4.00 | 299.55 | 287.68 | +0.81 | +0.81 |
| A | SNDA | +1 | 2026-08-10 | 2026-08-10 | 40.30 | 38.92 | -3.42 | 2026-08-12 | 38.75 | 2026-09-10 | 39.76 | 303.02 | 288.48 | +7.40 | +7.40 |
| A | SWIM | +1 | 2026-08-04 | 2026-08-04 | 5.64 | 7.30 | +29.43 | 2026-08-06 | 7.29 | 2026-09-03 | 6.92 | 299.60 | 295.79 | -3.80 | -3.80 |
| H | TKNO | +1 | 2026-08-05 | 2026-08-05 | 5.52 | 6.53 | +18.30 | 2026-08-07 | 6.53 | 2026-09-04 | 7.15 | 300.46 | 293.70 | +11.74 | +11.74 |
| A | VSTS | +1 | 2026-08-11 | 2026-08-11 | 13.87 | 14.16 | +2.09 | 2026-08-13 | 14.24 | 2026-09-11 | 13.02 | 304.04 | 290.71 | -4.18 | -4.18 |
| A | WLDN | +1 | 2026-08-06 | 2026-08-06 | 74.13 | 86.24 | +16.34 | 2026-08-10 | 85.42 | 2026-09-08 | 85.14 | 300.51 | 295.34 | +1.39 | +1.39 |
| A | WTBA | +1 | 2026-07-23 | 2026-07-23 | 26.62 | 27.27 | +2.44 | 2026-07-27 | 27.62 | 2026-08-24 | 28.51 | 293.98 | 299.55 | +1.33 | +1.33 |
| H | ALX | +0 | 2026-08-03 | 2026-08-04 | 255.00 | 273.84 | +7.39 | 2026-08-05 | 271.99 | 2026-09-02 | 270.64 | 302.43 | 291.54 | +3.10 | +3.10 |
| A | CAC | +0 | 2026-07-28 | 2026-07-28 | 54.81 | 58.48 | +6.69 | 2026-07-30 | 58.48 | 2026-08-27 | 56.15 | 291.15 | 298.77 | -6.60 | -6.60 |
| A | CCEC | +0 | 2026-07-29 | 2026-07-29 | 22.66 | 22.39 | -1.19 | 2026-07-31 | 22.00 | 2026-08-28 | 22.70 | 293.56 | 299.70 | +1.09 | +1.09 |
| A | CRI | +0 | 2026-07-31 | 2026-07-31 | 37.79 | 39.89 | +5.56 | 2026-08-04 | 38.89 | 2026-09-01 | 31.27 | 297.59 | 291.98 | -17.71 | -17.71 |
| A | CRNC | +0 | 2026-08-06 | 2026-08-06 | 9.22 | 9.14 | -0.81 | 2026-08-10 | 9.01 | 2026-09-08 | 8.57 | 300.51 | 295.34 | -3.16 | -3.16 |
| A | DAKT | +0 | 2026-09-02 | 2026-09-02 | 19.36 | 19.48 | +0.62 | 2026-09-04 | 19.47 | 2026-10-05 | 17.93 | 293.70 | 281.95 | -3.91 | -3.91 |
| H | DHC | +0 | 2026-08-03 | 2026-08-04 | 8.90 | 8.80 | -1.12 | 2026-08-05 | 8.86 | 2026-09-02 | 7.67 | 302.43 | 291.54 | -9.83 | -9.83 |
| H | DOLE | +0 | 2026-08-10 | 2026-08-10 | 13.83 | 12.96 | -6.29 | 2026-08-12 | 13.00 | 2026-09-10 | 13.82 | 303.02 | 288.48 | +11.11 | +11.11 |
| H | EVLV | +0 | 2026-08-11 | 2026-08-11 | 5.86 | 5.72 | -2.39 | 2026-08-13 | 5.80 | 2026-09-11 | 5.00 | 304.04 | 290.71 | -9.41 | -9.41 |
| A | FCEL | +0 | 2026-09-02 | 2026-09-02 | 17.08 | 14.67 | -14.11 | 2026-09-04 | 14.52 | 2026-10-05 | 18.11 | 293.70 | 281.95 | +28.73 | +28.73 |
| A | GLP | +0 | 2026-08-07 | 2026-08-07 | 48.52 | 50.01 | +3.07 | 2026-08-11 | 49.60 | 2026-09-09 | 53.48 | 300.93 | 293.46 | +10.30 | +10.30 |
| A | HCSG | +0 | 2026-07-22 | 2026-07-22 | 24.80 | 22.43 | -9.58 | 2026-07-24 | 22.42 | 2026-08-21 | 23.17 | 293.41 | 299.85 | +1.15 | +1.15 |
| A | HTZ | +0 | 2026-08-06 | 2026-08-06 | 1.56 | 2.27 | +45.51 | 2026-08-10 | 2.15 | 2026-09-08 | 2.30 | 300.51 | 295.34 | +8.70 | +8.70 |
| A | IIIN | +0 | 2026-07-16 | 2026-07-16 | 29.64 | 31.00 | +4.59 | 2026-07-20 | 30.90 | 2026-08-17 | 32.47 | 295.01 | 303.96 | +2.05 | +2.05 |
| A | JCAP | +0 | 2026-08-13 | 2026-08-13 | 21.10 | 24.00 | +13.74 | 2026-08-17 | 23.87 | 2026-09-15 | 21.35 | 303.96 | 286.62 | -4.85 | -4.85 |
| H | JKS | +0 | 2026-08-26 | 2026-08-26 | 15.50 | 13.51 | -12.84 | 2026-08-28 | 13.37 | 2026-09-28 | 9.58 | 299.70 | 280.33 | -21.88 | -21.88 |
| H | KOPN | +0 | 2026-08-11 | 2026-08-10 | 4.21 | 5.02 | +19.24 | 2026-08-13 | 4.84 | 2026-09-11 | 4.39 | 304.04 | 290.71 | -4.91 | -4.91 |
| A | LMRI | +0 | 2026-08-12 | 2026-08-12 | 11.66 | 12.20 | +4.63 | 2026-08-14 | 12.20 | 2026-09-14 | 11.44 | 303.28 | 287.49 | -1.02 | -1.02 |
| A | MATV | +0 | 2026-08-05 | 2026-08-06 | 9.20 | 11.68 | +26.96 | 2026-08-07 | 11.39 | 2026-09-04 | 12.54 | 300.46 | 293.70 | +12.35 | +12.35 |
| H | NVGS | +0 | 2026-08-04 | 2026-08-05 | 21.80 | 20.57 | -5.64 | 2026-08-06 | 21.13 | 2026-09-03 | 22.70 | 299.60 | 295.79 | +8.70 | +8.70 |
| A | NXRT | +0 | 2026-08-04 | 2026-08-04 | 25.91 | 24.76 | -4.44 | 2026-08-06 | 24.83 | 2026-09-03 | 24.40 | 299.60 | 295.79 | -0.46 | -0.46 |
| A | OEC | +0 | 2026-08-05 | 2026-08-06 | 6.66 | 7.60 | +14.11 | 2026-08-07 | 7.34 | 2026-09-04 | 5.85 | 300.46 | 293.70 | -18.05 | -18.05 |
| A | OFIX | +0 | 2026-08-05 | 2026-08-05 | 12.20 | 10.60 | -13.11 | 2026-08-07 | 10.44 | 2026-09-04 | 9.22 | 300.46 | 293.70 | -9.44 | -9.44 |
| A | PAX | +0 | 2026-07-31 | 2026-07-31 | 10.97 | 11.17 | +1.82 | 2026-08-04 | 11.30 | 2026-09-01 | 11.16 | 297.59 | 291.98 | +0.65 | +0.65 |
| A | SHIP | +0 | 2026-07-30 | 2026-07-30 | 16.09 | 17.49 | +8.70 | 2026-08-03 | 17.89 | 2026-08-31 | 17.90 | 292.90 | 295.09 | -0.69 | -0.69 |
| A | SIND | +0 | 2026-08-14 | 2026-08-14 | 17.00 | 16.69 | -1.82 | 2026-08-18 | 16.90 | 2026-09-16 | 14.45 | 302.45 | 285.63 | -8.94 | -8.94 |
| A | SOPH | +0 | 2026-08-04 | 2026-08-04 | 5.69 | 6.30 | +10.72 | 2026-08-06 | 6.25 | 2026-09-03 | 8.30 | 299.60 | 295.79 | +34.07 | +34.07 |
| A | TFIN | +0 | 2026-07-21 | 2026-07-22 | 77.85 | 81.08 | +4.15 | 2026-07-23 | 81.10 | 2026-08-20 | 73.62 | 290.87 | 299.27 | -12.11 | -12.11 |
| H | TMC | +0 | 2026-08-13 | 2026-08-13 | 4.47 | 4.01 | -10.29 | 2026-08-17 | 4.05 | 2026-09-15 | 3.81 | 303.96 | 286.62 | -0.22 | -0.22 |
| A | TNC | +0 | 2026-08-05 | 2026-08-06 | 89.22 | 76.90 | -13.81 | 2026-08-07 | 78.42 | 2026-09-04 | 70.23 | 300.46 | 293.70 | -8.19 | -8.19 |
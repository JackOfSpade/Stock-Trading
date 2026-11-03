# Stage 4, L3: masked LLM reader test, pre-registration

Written 2026-11-02 before any reader ran and before any score existed. Changing a constant below after readers start invalidates the test.

## Question

Does a prompt-only LLM reading an earnings call add return over the reaction itself, in low-coverage small caps, after a next-open entry?

A pass does not create a candidate. It can only justify a lead with a prospective paper book, and L3 would still bind under the acute override with no breaker. A fail closes L3.

## Sample

- Events: Nasdaq calendar, market cap $300M-$2B, `noOfEsts` <= 2, alphabetic ticker, event date 2026-07-01 to 2026-09-28 (619 events before transcript filtering). All are after the June 2026 model knowledge cutoff.
- Transcript: from stockanalysis.com, call date within one calendar day of the event date, at least 5,000 characters after cleaning.
- Prices: Nasdaq historical API. Event dropped if it lacks an entry or a 20-day exit.
- At most 300 events, chosen by seeded shuffle (seed 20261102) if more qualify.

## Timing

Let i be the first trading day on or after the event date. Reaction is close(i-1) to close(i+1). Entry is open(i+2). Exit is the open 20 trading days later. Returns are net of IWM over the same open-to-open interval. Secondary horizons are 5 and 10 trading days.

## Reader

- One read per event, Sonnet 5.5 where the API allows. If blocked, the model used is recorded and all events use the same model.
- Input: the masked transcript and the signed reaction. Company, ticker, speaker names and calendar dates are masked. The site's summary, price widgets and navigation are removed.
- Output: score in {-2, -1, 0, +1, +2} for the expected 20-day return relative to small caps from the next open, a one-line reason, and whether the reader recognizes the company.
- Each read runs in a fresh agent of a type that does not receive the repo's context files, and the transcripts are audited for tool use beyond reading the one file.
- 30 randomly chosen events are read a second time, only to measure test-retest noise. The first read is the score.
- Recognized events are reported separately (see the amendment below).

## Primary test

Long group: score > 0. Short group: score < 0. Spread = mean(long) - mean(short) of 20-day net returns, winsorized at 1% and 99% over the whole sample.

L3 passes only if ALL hold:

1. Spread >= 3.0%, which is about 1.5% cost per leg.
2. t >= 1.65 with standard errors clustered by entry week.
3. Spread exceeds the baseline spread by >= 1.5%. Baseline: long if reaction > 0, short if reaction < 0, on the same events.
4. At or above the 95th percentile of 2,000 placebos that permute scores within entry week.
5. The unwinsorized spread has the same sign.

Each group needs at least 30 events, otherwise the result is reported as inconclusive and L3 stays closed on stage 2 grounds.

## Reported but not gating

Each leg separately, by month, rank correlation of score and return, secondary horizons, test-retest agreement, and recognized events.

## Known limits, accepted in advance

- Tickers come from names still quoted today, so delisted losers are under-represented.
- Returns are not dividend-adjusted.
- About 13 weeks of events and about 4 independent 20-day windows, all in one regime. With per-trade standard deviation near 14%, the test can reject but cannot prove an edge.
- Publication time of each transcript is unknown; entry at open(i+2) assumes it was available by then.
- `noOfEsts` is broader than a strict 0-2 analyst count.

## Amendment, 2026-11-02, before the full run

A 3-read pilot, with no returns computed, had 2 of 3 readers report recognizing the company from business detail despite the masking. Excluding recognized events would discard most of the sample. All events are after the model cutoff, so recognition cannot reveal the outcome; it can only bring in the firm's earlier history.

Change: the primary test uses all events. A sixth pass condition is added: the spread among events NOT recognized must have the same sign as the primary spread, if that subset has at least 30 events per group. The three pilot files are re-read in the full run; pilot scores are not used.

## Result of the primary test and holdout pre-registration, 2026-11-02

The primary test is INCONCLUSIVE under the rule above: readers scored 80 long, 1 short and 219 neutral, so the short group has fewer than 30 events. L3 therefore stays closed on stage 2 grounds. The primary test has no second chance.

A pattern appeared that was not pre-registered: score +1 beat score 0 by 2.87% at 20 days (clustered t 2.55, 96.4th placebo percentile). It was found after seeing the returns, so it is a hypothesis only.

Holdout test, fixed before any holdout read: the 80 eligible events left out of the seeded 300 were never read. They are read once each with the identical prompt and model. All three must hold for the pattern to count as confirmed:

1. Winsorized mean(+1) minus mean(0) >= 1.5%.
2. Winsorized mean(+1) >= 1.5%, the mid-range cost per trade.
3. Median(+1) > median(0).

Each group needs at least 10 events, otherwise the result is inconclusive. Clustered t is reported but not gating, because 80 events cannot carry it. A confirmation still creates no candidate. It can only justify a prospective paper book, and the long-hedged form would still bind under the acute override with no breaker.

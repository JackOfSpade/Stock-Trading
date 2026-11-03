# Prospective test: L3 reader score +1, Q3 2026 reporting season

Fixed 2026-11-02, before the first read and before any of these events' entries. Changing a constant after the first live read invalidates the test. Owner approved starting this test on 2026-11-02.

## Hypothesis

Earnings calls an LLM reader scores +1 earn more over 20 trading days from the next open, net of IWM, than calls it scores 0, by enough to pay for trading.

This is a test, not a strategy. Confirmation creates no lead, candidate or order by itself. A hedged long form would still bind under the acute override without a breaker, and any next step needs an owner decision.

## Universe

- Nasdaq calendar events dated 2026-10-30 to 2026-11-27, alphabetic ticker.
- Market cap $300M-$2B and `noOfEsts` <= 2, as read from the calendar on the morning of the run, not a later snapshot.
- The analyst count from the stockanalysis.com forecast page is recorded for every event but does not exclude anyone (see the amendment).
- Transcript from stockanalysis.com, call date within one calendar day of the event, at least 5,000 characters after cleaning.
- Every event considered is logged in `events.jsonl` with its outcome, including drops. The universe is fixed at run time, so later delistings stay in.

## Timing

Let i be the first trading day on or after the event date. Reaction is close(i-1) to close(i+1). The run happens around 08:30 ET on trading day i+2. Planned entry is the open of i+2, and exit is the open 20 trading days later. Returns are net of IWM over the same interval. If a name stops trading, its last close is the exit.

## Reader

Identical to the stage 4 prompt and masking: one read per event, Sonnet 5.5, Explore agent, one file, fresh agent. No fallback model in the primary: an event that cannot be read this way is logged as missed.

## What counts

- LIVE: read timestamp before 09:30 ET on the planned entry day. Only LIVE events enter the primary test.
- LATE: read after that, for example because the transcript appeared late or the app was closed. Reported separately and never in the primary.
- Returns are not computed or viewed before the final scoring, on or after 2027-01-04.

## Primary test

Winsorized at 1% and 99% over all LIVE events. Requires at least 30 events each in score +1 and score 0, otherwise INCONCLUSIVE. CONFIRMED only if ALL hold:

1. Mean(+1) minus mean(0) >= 1.5%.
2. Mean(+1) >= 1.5%, the mid-range cost per trade.
3. Median(+1) > median(0).
4. t >= 1.65, clustered by entry week.
5. Beta-adjusted difference >= 1.0%, using each stock's beta to IWM over the 60 sessions ending at close(i-1).
6. At or above the 95th percentile of 5,000 placebos that permute scores within entry week.
7. Among events not recognized by the reader, the difference has the same sign, if each group has at least 30 events.

Anything else is NOT CONFIRMED, and the pattern is closed.

## Reported, not gating

The subset with 2 or fewer analysts, score -1 and -2 events, LATE events, 5 and 10 day horizons, recognized vs not, large vs small reaction, EPS beats vs misses, transcript miss rate, drops, and how many reads were LIVE.

## Known limits

- One season in one regime, with about 4 independent 20-day windows.
- Opening fill is assumed at the open print; the cost bar is an assumption.
- Readers usually recognize the company, so firm history may contribute.
- `noOfEsts` and the forecast page are both imperfect coverage measures.
- Runs depend on a remote routine firing before the open, and on its environment reaching the data sources.

## Amendment, 2026-11-02, before the first read

The first draft excluded events with 3 or more analysts on the forecast page. A dry run with no reads and no returns found 8 of the first 10 calendar events had 3 or more, so the screen would leave too few +1 events to test, and would also change the population the pattern came from. The test now uses the same population as stage 4, and the subset with 2 or fewer analysts is reported without gating. The population is therefore small caps with few estimates, not firms with no analyst coverage.

## Amendment, 2026-11-02, before the first read: moved to a temporary remote routine

At the owner's request the daily run moved from a local desktop task to a temporary remote routine, so it does not depend on the Mac. Consequences, all fixed before any read:

- Reader prompt and masking are unchanged, except for one added line asking for the answer as JSON, because cloud readers return text rather than a forced schema.
- `read_ts` is the ledger's ingest time, which is later than the actual read and so errs toward LATE.
- Per-read tool audits are not available in the cloud run, so tool use is no longer checked. The readers are told to use one file only, and the agent type receives no repo context.
- The ledger and code live in a chain of dated git tags (`strategy-lab/prospective/<date>`), not on main or a branch. Only the masked packs and raw pages stay out of git.

# Strategy lab 2026-11: checkpoint

Updated 2026-11-02 after stage 5. Nothing in this directory is committed. No lead, candidate, BigQuery row or fleet instruction has been written.

## Where it stands

No candidate. Nine of ten ideas are dead on stage 2 evidence. L3 failed to produce a usable primary test, but one pattern inside it survived three attempts to break it and is worth a forward test.

## Stage 2

All 10 ideas returned KILL. Details are in `stage2_L*.md`. Only SHOCK-NATIVE designs can run under the acute override without an owner-landed breaker, and both tested (L4, L9) failed on economics.

## Stage 4: L3 masked reader test

Rules: `stage4_L3_preregistration.md`, fixed before the reads. Sample: post-cutoff earnings calls of small caps with 2 or fewer estimates, read by Sonnet 5.5 with names and dates masked. Returns are 20 trading days from open(i+2), net of IWM.

| Test | Pre-registered? | Result |
|---|---|---|
| Primary long/short on 300 events | Yes | INCONCLUSIVE: 80 long, 1 short, 219 neutral. L3 as a two-sided design stays closed |
| +1 vs 0 on those 300 | No, found after seeing returns | +2.87%, clustered t 2.55 |
| +1 vs 0 on 80 unread events | Yes, rules fixed first | +1 (n=22) mean +2.55%, median +3.52%; 0 (n=55) mean +0.52%, median -0.22%; all three conditions held; t 0.57 |
| Pooled, descriptive | No | +1 (n=102) +3.03%; 0 (n=274) +0.34%; t 1.84 |

## Stage 5: three skeptics

| Check | Verdict | Main finding |
|---|---|---|
| Replication and look-ahead (`stage5_refute_replication.md`) | Weakened | All 380 returns recomputed with no differences. Market-cap filter uses a late October snapshot, a universe look-ahead |
| Factors (`stage5_refute_factors.md`) | Weakened | No measured factor explains the gap, but no beta-adjusted pooled version reaches t 1.65 |
| Non-LLM proxy (`stage5_refute_proxy.md`) | Survives | Word and phrase proxies predict neither the premium nor returns |

Standing against the pattern:

- The holdout's three conditions pass 25% of the time on shuffled labels, so the likelihood ratio is only about 2.5.
- The holdout's mean gap goes to about zero without its top two winners, and it is negative in the weeks holding 65% of events. Its median stays positive.
- One season in one regime, about 4 independent 20-day windows. IWM averaged -1.97%, and before netting +1 made only +0.81% pooled.
- The premium sits almost entirely in events the reader said it recognized (92 of 102). 347 of 380 events were recognized overall, so the masking mostly failed at hiding identity, and firm history may be doing the work.
- It appears only after large moves. Unplanned, it appears only among EPS beats.
- `noOfEsts` is not a clean analyst count: the sample includes names like LCID, so "low coverage" is not established.
- The Sonnet 5.5 cutoff is taken from the session's stated value and was not independently verified.
- The skeptics ran about 475 comparisons, all post hoc.

Standing for it: no pipeline error, nothing the reader saw postdates entry, signs and hit rates match out of sample (61% vs 48%, 64% vs 49%), and the gap accrues gradually rather than as a gap at entry.

## Even if real

A long-hedged form would be SPREAD class with no breaker, so it binds under the acute override today. It also shares B's edge sentence in a smaller cap band, which a reviewer could read as a B variant.

## Prospective test: temporary remote routines

The owner approved a prospective test on the Q3 reporting season on 2026-11-02, and asked for it to run as temporary remote routines so it does not depend on the Mac. Rules and code are in `prospective/`, and the temporary routines are recorded in `prospective/TASKS.md`. Request their deletion after the final report on 2027-01-04.

The planned stricter coverage screen was dropped before any read, because it left too few events and changed the population. See the amendment in `prospective/PREREGISTRATION.md`.

Separately, with owner approval: record the results as `events.strategy_research_leads` events so SL1 can read them on 2026-12-02, and commit this directory.

## Models

Sonnet 5.5 ran the 410 reader agents and the proxy check. An API safeguard flag (`reasoning_extraction`) stopped 3 stage 0 agents, not retried; all 10 stage 2 agents and 2 stage 5 agents, which ran on Opus with unchanged prompts.

## Reproducing

`stage4_L3_fetch.py`, `stage4_L3_build.py`, `stage4_L3_score.py`, `stage4_L3_exploratory.py`, plus the key and results JSON here. Transcripts and raw prices stay in the session scratchpad and are not kept: refetch them if needed.

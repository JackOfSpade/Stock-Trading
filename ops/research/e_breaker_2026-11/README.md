# Strategy E pair-correlation breaker — replay dataset (2026-11)

Data-only deliverable for a stress replay. It defines and evaluates no gate.

## Files

- `replay_data.py` — standard-library-only script. Holds the 76 pairs (`PAIRS`), fetches daily closes, computes weekly pair statistics, and exposes pure functions (`pearson`, `trailing_window`, `rolling_pearson`, `trailing_zscore`, `last_date_per_iso_week`, `parse_nasdaq_row`, `parse_nasdaq_payload`).
- `pairs_gics.csv` — the 76 pairs with GICS industry group (4-digit) and industry (6-digit) codes. Every row has source `model-assigned, unverified`; cells left empty where the code was not certain (`ACM/J`, and the 6-digit cells of `MDB/SNOW`). The designer must verify it.
- `series/pair_stats_weekly.csv` — `date,pair,c60,c252,z252`, one row per pair per ISO week (last common trading date of the week), 4 dp, sorted by date then pair. Empty cell = incomplete window.
- `series/coverage.csv` — `ticker,first_date,last_date,n_closes,status` (`ok`, `short_history` = first close after 2017-01-01, `fetch_failed`).
- `_raw/` — scratch cache of raw Nasdaq JSON. Discarded after the job; never commit it (the repo is public).

## Regenerate

From the repository root:

    python3 ops/research/e_breaker_2026-11/replay_data.py

Tests (offline): `python3 -m pytest tests/test_e_breaker_replay.py`

## Method

- Source: `https://api.nasdaq.com/api/quote/{TICKER}/historical?assetclass=stocks&fromdate=2016-01-01&todate=2026-11-06&limit=9999`, about 1 s between requests, at most 2 retries with backoff. A ticker whose `_raw/{TICKER}.json` exists is not re-fetched.
- Log returns are close-to-close on the intersection of both legs' trading dates.
- `c60` / `c252`: Pearson correlation of the trailing 60 / 252 log returns of the two legs.
- `z252`: (log(P_A/P_B) minus its trailing 252-day mean) / trailing 252-day sample standard deviation. The window includes the current day.
- A value needs a full window, otherwise it is empty. A zero-variance window is also empty.

## Caveats

- Nasdaq closes are split-adjusted but NOT dividend-adjusted, so returns exclude dividends.
- Survivorship: today's pair list is applied backwards; pairs were chosen with hindsight and delisted or merged names are absent.
- Short histories: some legs listed after 2017-01-01 (for example GEV, VRT, CRWD, SNOW, DELL and other recent listings or spin-offs). They appear as `short_history` in `coverage.csv`, and their pairs have empty statistics until a full window exists.
- Ticker symbols are today's (for example `BNY` replaced `BK` in 2025); history under a former symbol may be missing.
- GICS codes are model-assigned and unverified.

## Coverage summary

Generated 2026-11-07 in the primary checkout (raw cache kept outside the repo with `--raw-dir`):

- 144 tickers: 134 ok, 10 short_history (BKR, CRWD, DELL, DOW, GEV, IR, MDB, NVT, SNOW, VRT), 0 fetch_failed.
  Nasdaq returns at most ten years, so every series starts 2016-11-07.
- Earliest weekly date with at least 60 pairs having a c252 value: 2017-11-10. 38,268 weekly rows.

## Replay result (2026-11-07): FAIL, E stays bound

`replay_gate.py` implements `PREREGISTRATION.md`; outputs are in `results/`. Frozen thresholds from the
2017-11 to 2021-12 calibration months: T_H = 0.92, S_L = 0.06.

| Criterion | Result | Evidence |
|---|---|---|
| 1 Substantive trips | FAIL | Both calibration windows trip; held out, W-2022 and W-2025TARIFF trip, W-2023BANKS and W-2026GULF never do (2 of 4, needs 3) |
| 2 Group-local power | FAIL | Banks (401010) median 60-day correlation 0.81-0.82 in Mar-May 2023, none below 0.3: the gate never sees the bank run |
| 3 Lead time | FAIL | 21 of 47 held-out stress months tripped at their opening measurement (44.7%, needs 50%) |
| 4 False-bind ceiling | FAIL | Tripped in 26 of 59 held-out months (44.1%, ceiling 40%) |
| 5 Discrimination | PASS | Mean outcome 0.086 tripped vs 0.074 clear |

An independent audit of the code against the pre-registration (Offload report job, 2026-11-07) found no bug
that changes the verdict: criteria 1 and 2 fail under every reading of the spec.

What it shows: pair correlation is the wrong instrument for this breaker. In the 2023 bank run, bank pair
correlations barely moved while their spreads diverged sharply (RF/KEY z252 went from +1.2 to +3.2 in two weeks),
and in the 2026 Gulf window no group median passed 0.90. A shock confined to one industry shows up in spread
divergence, not in correlation, so neither Rev 53 leg as written can see it.

Weakness in the pre-registration itself, found by the audit: the stress-month definition is too loose (any
group of 3+ tickers with half its pairs blowing out), so 47 of 57 held-out months count as stress, and
criteria 3 and 4 cannot both hold at that rate. This does not rescue the gate, because criteria 1 and 2 fail
independently of it. Any successor design needs a new pre-registration and held-out data it has not seen;
2017-2026 has now been seen.

## v2 (spread divergence), 2026-11-07: CLOSED at the in-sample check

`PREREGISTRATION_v2.md` added per-industry and population legs on 4-week spread widening
(`|z252(t)| - |z252(t-4)|`) and set its thresholds by a fixed 95th-percentile rule over 2017-11 to 2026-11
(`results_v2/thresholds.json`: T_D 1.96, S_DP 0.18, T_H 0.93, S_L 0.07, B90 0.153). It required two in-sample
non-vacuity checks before any forward test could matter.

| Check | Result | Evidence (`results_v2/insample.json`) |
|---|---|---|
| S1 COVID window trips on D or DP | PASS | Tripped every week from 2020-03-06 to 2020-04-03 |
| S2 Banks (401010) trips on D in the 2023 bank run | FAIL | Banks median widening peaked at 0.59 (week of 2023-03-17) against T_D 1.96 |
| S3 in-sample bound share and outcomes (no pass mark) | — | Bound 19% of weeks; mean later blowout 0.080 when bound vs 0.092 when clear |

S2 failing closes v2: the pre-registration makes S1 and S2 a precondition for proposing the gate, so the
forward test (first score 2027-06-07) has nothing to decide and is not scheduled. The thresholds stay frozen
as recorded.

What it shows:
- In the bank run, the five bank pairs' spreads moved in both directions, so a group median of widening
  cancels out. The divergence was real, but no per-industry median sees a shock that moves pairs both ways.
- In-sample, weeks where spreads had just widened were followed by LESS further widening than other weeks.
  Widened spreads tend to come back, which is E's own thesis, and the opposite of what a divergence breaker
  needs.

Both correlation (v1) and median spread widening (v2) fail to isolate the group-local shock Rev 53 is written
around. Any v3 would be a third design fitted after seeing the same 2017-2026 data, so it is not attempted here.

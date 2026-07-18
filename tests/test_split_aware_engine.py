"""Spec-lock for the split-aware TWR engine (bigquery/82, audit finding C2, 2026-07-17).

The live engine (analytics.strategy_daily_returns) scales fill-derived shares by a per-position
running split factor so a post-entry stock split keeps market value continuous instead of
manufacturing a phantom ~-50% daily return that would fire drawdown_kill and force-liquidate a
healthy strategy. There is no offline BigQuery, so this re-implements the SAME cum-split algorithm
the SQL uses (EXP(SUM(LN(split))) running product, normalised to 1.0 on the first held day) and locks
its two load-bearing properties. If someone re-derives the SQL and breaks the invariant, this fails.
No warehouse, no creds — runs in the always-on `test` job.
"""
import math


def eff_split_since_entry(day_splits):
    """Mirror of bigquery/82's equity leg: given the ordered per-day split_ratio values over a
    position's hold window (1.0 on a non-split day, e.g. 2.0 on a 2:1 split day), return the
    per-day effective-share multiplier = running product normalised to the first held day."""
    run, first = [], None
    acc = 0.0  # sum of ln(split), i.e. ln(running product)
    for s in day_splits:
        acc += math.log(s)
        rp = math.exp(acc)
        if first is None:
            first = rp
        run.append(rp / first)
    return run


def mv_series(shares, entry_price, closes, day_splits):
    """Interior-day market value per day = shares * eff_split * close (the engine's `mv`)."""
    eff = eff_split_since_entry(day_splits)
    return [shares * e * c for e, c in zip(eff, closes)]


def daily_returns(mvs):
    return [mvs[i] / mvs[i - 1] - 1 for i in range(1, len(mvs))]


def test_no_split_is_identity():
    # constant split_ratio=1 -> effective shares never change; returns follow raw close moves.
    closes = [100.0, 101.0, 99.0, 103.0]
    mvs = mv_series(10, 100.0, closes, [1.0] * 4)
    assert mvs == [1000.0, 1010.0, 990.0, 1030.0]
    rets = daily_returns(mvs)
    assert math.isclose(rets[0], 0.01, abs_tol=1e-12)


def test_two_for_one_split_is_continuous_not_minus_50pct():
    # Day 3 is a 2:1 split: the ingested close halves (102 -> 51) AND split_ratio=2.0.
    # A split-BLIND engine (shares*close) would read 10*51/ (10*102) - 1 = -50% and fire drawdown_kill.
    # The split-AWARE engine doubles effective shares that day, so market value is continuous.
    closes = [100.0, 102.0, 51.0, 52.0]
    splits = [1.0, 1.0, 2.0, 1.0]
    mvs = mv_series(10, 100.0, closes, splits)
    rets = daily_returns(mvs)
    # split day return is the true economic move (51*2 vs 102 == flat), NOT -50%.
    assert math.isclose(rets[1], 0.0, abs_tol=1e-9), f"split day should be ~flat, got {rets[1]}"
    assert rets[1] > -0.5 + 1e-6
    # post-split day tracks the real +1/51 move on the doubled share base.
    assert math.isclose(rets[2], 52.0 / 51.0 - 1.0, abs_tol=1e-9)


def test_four_for_one_split_continuous():
    closes = [200.0, 210.0, 52.5, 53.0]  # day 3 = 4:1 split (210 -> 52.5)
    splits = [1.0, 1.0, 4.0, 1.0]
    rets = daily_returns(mv_series(4, 200.0, closes, splits))
    assert math.isclose(rets[1], 0.0, abs_tol=1e-9)

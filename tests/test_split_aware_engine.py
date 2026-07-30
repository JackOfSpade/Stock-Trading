"""Split-aware TWR engine: real spec-lock on bigquery/82's SQL + property tests on a mirror
algorithm (test-gap fix, 2026-07-29).

THE GAP THIS CLOSES. Before this fix, the file's docstring claimed "If someone re-derives the SQL
and breaks the invariant, this fails" but every test here only exercised a Python re-implementation
of the cum-split algorithm against ITSELF — bigquery/82_split_aware_engine.sql was never read. A
re-derivation of the live view that dropped the split factor entirely (reverting to bigquery/40's
original split-blind `shares * close`, the exact phantom -50%-return bug bigquery/82 exists to fix)
would have left every test in this file green. That is worse than no test: it advertised coverage
that did not exist.

TWO KINDS OF TEST NOW LIVE HERE:
  1. test_bigquery_82_* — an actual spec-lock. Reads bigquery/82_split_aware_engine.sql off disk and
     regex-asserts its two load-bearing constructs are present: the LN-domain running product
     (EXP(SUM(LN(split)) OVER (... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))) and its
     normalisation to 1.0 on the first held day (SAFE_DIVIDE(rp, FIRST_VALUE(rp) OVER (...))). The
     regexes tolerate whitespace/identifier-name reformatting (\\w+ for column names, \\s+ for
     layout) but require the exact algebraic shape, so a genuine re-derivation that changes the
     algorithm — not just its formatting — fails this test. There is no offline BigQuery to execute
     the view against, so this is a structural (text-level) lock, not a behavioral one.
  2. test_no_split_is_identity / test_two_for_one_split_is_continuous_not_minus_50pct /
     test_four_for_one_split_continuous — property tests of a hand-written Python mirror of the SAME
     algorithm (running product normalised to the first held day), proving the ALGORITHM is
     economically correct (a split keeps market value continuous, not a phantom ~-50% return). These
     do NOT read bigquery/82 and would stay green even if the live SQL diverged from this mirror —
     that is what test #1 above is for. Keep both: #1 catches "the SQL stopped matching this design",
     #2 catches "this design would have been wrong in the first place".

No warehouse, no creds — runs in the always-on `test` job.
"""
import math
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_82 = os.path.join(ROOT, "bigquery", "82_split_aware_engine.sql")

# LN-domain running product of the per-day split_ratio, over the position's whole hold window
# (UNBOUNDED PRECEDING -> CURRENT ROW). This is the actual fix in bigquery/82: multiplying split
# ratios via EXP(SUM(LN(...))) rather than a plain running product avoids the numeric-overflow /
# rounding issues NUMERIC-domain PRODUCT-over-window would have (BigQuery has no windowed PRODUCT
# aggregate at all, hence the log-sum-exp trick). \w+ tolerates a column rename (day_split ->
# anything); \s+ tolerates reformatting. A re-derivation that reverts to split-blind shares*close
# (bigquery/40's original phantom -50%-return bug) or that computes the factor any other way fails
# this regex.
RUNNING_SPLIT_PRODUCT_RE = re.compile(
    r"EXP\(SUM\(LN\(\w+\)\)\s*OVER\s*\(\s*PARTITION\s+BY\s+\w+\s*ORDER\s+BY\s+\w+\s*"
    r"ROWS\s+BETWEEN\s+UNBOUNDED\s+PRECEDING\s+AND\s+CURRENT\s+ROW\s*\)\)",
    re.IGNORECASE,
)

# Normalisation of that running product to 1.0 on the first held day (SAFE_DIVIDE(rp,
# FIRST_VALUE(rp) OVER (PARTITION BY position ORDER BY date))) — this is what makes the multiplier
# an "effective shares SINCE ENTRY" factor rather than an absolute split-adjustment-since-inception
# factor, which would double-count any split that happened before the position was even opened.
NORMALIZE_TO_FIRST_HELD_DAY_RE = re.compile(
    r"SAFE_DIVIDE\(\s*\w+\s*,\s*FIRST_VALUE\(\w+\)\s*OVER\s*\(\s*PARTITION\s+BY\s+\w+\s*ORDER\s+BY\s+\w+\s*\)\)",
    re.IGNORECASE,
)


def _read_bigquery_82():
    # Single read site in this file — not worth the sys.path bootstrap just to pull in
    # lib.textio.read_text for one call (see scripts/lib/textio.py's own guidance).
    with open(BIGQUERY_82, encoding="utf-8") as f:
        return f.read()


def test_bigquery_82_uses_ln_domain_running_split_product():
    sql = _read_bigquery_82()
    assert RUNNING_SPLIT_PRODUCT_RE.search(sql), (
        "bigquery/82_split_aware_engine.sql no longer contains the EXP(SUM(LN(split)) OVER (... ROWS "
        "BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) running-product construct — the split-aware "
        "engine may have been re-derived to something split-blind (the bigquery/40 phantom-return bug "
        "this file exists to fix) or to a different, unverified algorithm."
    )


def test_bigquery_82_normalizes_split_factor_to_first_held_day():
    sql = _read_bigquery_82()
    assert NORMALIZE_TO_FIRST_HELD_DAY_RE.search(sql), (
        "bigquery/82_split_aware_engine.sql no longer normalises the running split product to the "
        "first held day (SAFE_DIVIDE(rp, FIRST_VALUE(rp) OVER (...))) — without this, a split that "
        "happened before a position's entry date would double-count into that position's effective "
        "share multiplier."
    )


# ---- property tests on a Python mirror of the same algorithm (see module docstring #2) -----------

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

#!/usr/bin/env python3
"""Reference implementation of state.strategy_paper_regime_cells (bigquery/268_paper_regime_cells_carry_forward.sql).

Pinned by tests/test_paper_regime_cells.py on tests/fixtures/paper_regime_cells_vectors.json; the same vectors
were run through the live view body in BigQuery when bigquery/268 landed.

Per strategy, paper days are taken in incubation_day order. A day is KEPT when its cumulative excess is not
NULL and the technical-regime series gives it a cell. Each kept day's log marginal excess is
ln((1 + excess) / (1 + base)), where base is the cumulative excess on the previous kept day (0 before the
first), so a skipped day's change rolls into the next kept day. A ratio that cannot be logged is unloggable
(BigQuery SAFE.LN / SAFE_DIVIDE return NULL). A cell is demonstrated with >= 5 kept days, no unloggable day
and a compounded in-cell excess >= 0.
"""
import math

MIN_DAYS = 5


def _safe_log_ratio(excess, base):
    denom = 1 + base
    if denom == 0:
        return None
    ratio = (1 + excess) / denom
    return math.log(ratio) if ratio > 0 else None


def regime_cells(paper_rows, series):
    """paper_rows: iterable of (strategy_code, incubation_day, excess or None). series: {day: cell or None}.
    Returns {(strategy_code, cell): {paper_days_in_cell, unloggable_days, cell_excess, demonstrated}}."""
    by_strategy = {}
    for code, day, excess in paper_rows:
        by_strategy.setdefault(code, []).append((day, excess))
    acc = {}
    for code, rows in by_strategy.items():
        base = 0.0
        for day, excess in sorted(rows):
            cell = series.get(day)
            if excess is None or cell is None:
                continue
            lr = _safe_log_ratio(excess, base)
            a = acc.setdefault((code, cell), {"n": 0, "unloggable": 0, "log_sum": 0.0})
            a["n"] += 1
            if lr is None:
                a["unloggable"] += 1
            else:
                a["log_sum"] += lr
            base = excess
    out = {}
    for key, a in acc.items():
        out[key] = {
            "paper_days_in_cell": a["n"],
            "unloggable_days": a["unloggable"],
            "cell_excess": math.exp(a["log_sum"]) - 1,
            "demonstrated": a["n"] >= MIN_DAYS and a["unloggable"] == 0 and a["log_sum"] >= 0,
        }
    return out

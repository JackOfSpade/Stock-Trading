"""
strategy_math.strategy_a — Strategy A (catalyst-driven equity long, pre-event) mechanical
rules. Source: strategy/03_strategy_a.md (GENERATED from Strategy.md — this module's
constants must be kept in sync with that file's canonical text; a drift is caught by
scripts/check_roster_consistency.py check R-F via the spec_hash comparison).
"""

from __future__ import annotations

from .common import days_between

# Instrument eligibility rule (strategy/03_strategy_a.md "Instrument eligibility rule")
MIN_MARKET_CAP_USD = 2_000_000_000
MIN_ADV_30D_USD = 10_000_000

# Exit rules — "Maximum hold 12 months from entry (hard time stop)"
MAX_HOLD_DAYS = 365


def meets_instrument_eligibility(market_cap_usd: float, adv_30d_usd: float) -> bool:
    """Market cap >= $2B AND 30-day average daily dollar volume >= $10M.
    Strategy/03_strategy_a.md: "Market cap >= $2B at entry (screens small-caps where
    hallucination rates are elevated per 2.3)" + "30-day average daily volume >= $10M
    (execution liquidity)".
    """
    return market_cap_usd >= MIN_MARKET_CAP_USD and adv_30d_usd >= MIN_ADV_30D_USD


def hit_time_stop(entry_date, as_of_date) -> bool:
    """Maximum hold 12 months (365 days) from entry — a hard time stop, not a judgment
    call. strategy/03_strategy_a.md: "positions held > 12 months by design belong in D,
    not A. A hitting 12 months with no resolution indicates thesis timeline was
    miscalibrated — force exit generates diagnostic signal."
    """
    return days_between(entry_date, as_of_date) >= MAX_HOLD_DAYS

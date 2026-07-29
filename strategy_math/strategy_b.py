"""
strategy_math.strategy_b — Strategy B (post-event mispricing exploitation) mechanical
rules. Source: strategy/04_strategy_b.md (GENERATED from Strategy.md).
"""

from __future__ import annotations

from .common import days_between

# Instrument eligibility rule
MIN_MARKET_CAP_USD = 2_000_000_000
MIN_ADV_30D_USD = 10_000_000

# Entry criterion 1 — "immediate price reaction of >= 5% in either direction
# (measured as close-to-close move on event day)"
MIN_EVENT_REACTION_PCT = 0.05

# Entry criterion 3 — "entry through convergence expected within 60 days"
MAX_CONVERGENCE_TIMELINE_DAYS = 60

# Exit — "Timeline expiry at 60 days from entry"
TIMELINE_EXPIRY_DAYS = 60

# Exit — short borrow rate spike: "above 10% annualized"
SHORT_BORROW_RATE_LIMIT = 0.10

# Exit — short stop-loss (rev 13): "close the short if the underlying rises >= 25%
# from short-entry price"
SHORT_STOP_LOSS_PCT = 0.25


def meets_instrument_eligibility(market_cap_usd: float, adv_30d_usd: float) -> bool:
    """Market cap >= $2B AND 30-day ADV >= $10M (identical bar to Strategy A)."""
    return market_cap_usd >= MIN_MARKET_CAP_USD and adv_30d_usd >= MIN_ADV_30D_USD


def event_reaction_qualifies(close_before_event: float, close_on_event_day: float) -> bool:
    """Entry criterion 1: the event-day close-to-close move must be >= 5% in EITHER
    direction. strategy/04_strategy_b.md: "Public event occurred within the last 10
    trading days, producing an immediate price reaction of >= 5% in either direction
    (measured as close-to-close move on event day)". (The "within the last 10 trading
    days" recency check is a date comparison the caller performs separately — this
    function is the magnitude test only.)
    """
    if close_before_event <= 0:
        raise ValueError(f"close_before_event = {close_before_event} (must be > 0).")
    pct_move = abs(close_on_event_day - close_before_event) / close_before_event
    return pct_move >= MIN_EVENT_REACTION_PCT


def convergence_timeline_ok(entry_date, target_convergence_date) -> bool:
    """Entry criterion 3: the named convergence target/event must fall within 60 days
    of entry. strategy/04_strategy_b.md: "Specific timeline: entry through convergence
    expected within 60 days."
    """
    return 0 <= days_between(entry_date, target_convergence_date) <= MAX_CONVERGENCE_TIMELINE_DAYS


def timeline_expired(entry_date, as_of_date) -> bool:
    """Exit rule: "Timeline expiry at 60 days from entry (thesis is stale; market had
    ample absorption time and did not converge)".
    """
    return days_between(entry_date, as_of_date) >= TIMELINE_EXPIRY_DAYS


def short_borrow_rate_exceeded(borrow_rate_annualized: float) -> bool:
    """Exit rule (short positions only): "borrow rate spike above 10% annualized
    (short-financing cost overwhelms thesis)".
    """
    return borrow_rate_annualized > SHORT_BORROW_RATE_LIMIT


def short_stop_loss_triggered(short_entry_price: float, current_price: float) -> bool:
    """Exit rule (short positions only, rev 13): "close the short if the underlying
    rises >= 25% from short-entry price." Asymmetric-by-design — long positions have
    no equivalent stop (strategy/04_strategy_b.md: long downside is bounded at -100%
    of position, so sizing alone already bounds worst-case long loss at the thesis's
    stated risk budget without an explicit stop).

    Rev 39 (owner directive 2026-07-28) makes this stop LOAD-BEARING rather than
    supplementary: under thesis-scaled risk budgeting the position size IS the risk
    control, but that only works where downside is bounded. Short downside is
    unbounded, so this stop is what makes a short's Capital at Risk finite at all —
    CaR = notional * 0.25. It is mandatory and is the one deliberate exception to the
    experiment's no-price-based-stops posture.
    """
    if short_entry_price <= 0:
        raise ValueError(f"short_entry_price = {short_entry_price} (must be > 0).")
    return current_price >= short_entry_price * (1 + SHORT_STOP_LOSS_PCT)

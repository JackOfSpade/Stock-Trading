"""Render BigQuery NUMERIC values exactly, independently of Decimal's ambient context."""
from decimal import Decimal

SCALE = 9
INTEGER_DIGITS = 29


def numeric_text(value: Decimal, *, trim_scale: bool = False) -> str:
    """Return CAST(NUMERIC AS STRING) text, refusing non-finite/out-of-range values.

    Decimal.normalize() rounds to the active context (28 digits by default), while
    NUMERIC supports 38 digits. Work directly from the coefficient instead. Prices
    may ignore insignificant fractional zeroes; checked decision arguments retain
    their existing strict scale validation.
    """
    if not value.is_finite():
        raise ValueError("is not finite")
    _, coefficient, exponent = value.as_tuple()
    if trim_scale and exponent < 0:
        coefficient = list(coefficient)
        while coefficient and coefficient[-1] == 0 and exponent < 0:
            coefficient.pop()
            exponent += 1
    if exponent < -SCALE:
        raise ValueError(f"has more than {SCALE} decimal places; BigQuery NUMERIC would round it")
    if value == 0:
        return "0"
    # Check before formatting: a huge exponent must not allocate an enormous string.
    if value.adjusted() >= INTEGER_DIGITS:
        raise ValueError("is out of NUMERIC range")
    rendered = format(value, "f")
    return rendered.rstrip("0").rstrip(".") if "." in rendered else rendered

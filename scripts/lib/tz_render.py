"""Shared "detect the display tz, then render a BigQuery timestamp string in it" core.

scripts/alert_relay.py's get_user_tz()/fmt_ts() and ops/dashboard/generate_dashboard.py's
get_user_tz()/fmt_ts() independently implemented the same ~30 lines (SELECT tz FROM
state.user_tz with a NULL/error fallback to 'America/Denver', then parse+localize a
CAST(... AS STRING) BigQuery timestamp) and had already silently drifted from each other before
this consolidation (2026-07-20 dedup audit, finding C14) — the same duplicate-then-independently-
patched pattern scripts/lib/bq_json.py's docstring documents for the bq-invoke/JSON-parse half of
these same two files. Concretely, alert_relay.py unconditionally overwrote tzinfo with UTC after
parsing (discarding any offset the string actually carried) while generate_dashboard.py only
overwrote it when the parse produced a naive datetime; alert_relay.py never stripped a trailing
"Z"; and the two caught different (though practically equivalent) exception sets. This module
keeps the STRICTER of the two behaviors as the one shared core going forward.

Each call site's own falsy-v handling and fallback LABEL format ("... UTC" vs "... (UTC)") differ
by design (each is locked by that site's own pre-existing test suite) and deliberately stay out
of this module, in each site's thin wrapper — see the ADJUST note on finding C14.
"""
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
except ImportError:  # pragma: no cover — stdlib since 3.9; CI/runners pin >=3.9
    ZoneInfo = None
    ZoneInfoNotFoundError = KeyError


def get_display_tz(query_fn, project):
    """Detected DISPLAY timezone (state.user_tz — bigquery/20_user_prefs.sql). Cosmetic only —
    any failure (empty result set, NULL tz value, or the query itself raising) falls back to
    America/Denver silently, so a bad/absent tz can never be more than a display quirk.

    `query_fn` is the CALLER's own bq-invoke wrapper (e.g. alert_relay.bq / generate_dashboard.q),
    invoked here with a single SQL-string positional arg. Callers pass their own module-level
    function object (not a value captured at import time) so a test's
    `monkeypatch.setattr(<module>, "<query_fn name>", ...)` is still honored end to end."""
    try:
        rows = query_fn(f"SELECT tz FROM `{project}.state.user_tz`")
        return (rows[0]["tz"] if rows else None) or "America/Denver"
    except Exception:  # noqa: BLE001 - cosmetic only; any failure falls back to America/Denver per this function's docstring
        return "America/Denver"


def render_ts(v, tz_name):
    """Parse a BigQuery timestamp string and localize it to tz_name, formatted "YYYY-MM-DD HH:MM
    (tz_name)". Strips a trailing " UTC" or "Z" (either can appear across the two current wire
    formats callers have seen: CAST(... AS STRING) and a hand-built "...Z" fixture) before
    parsing, and only overwrites a naive parse's tzinfo with UTC — a parse that already carried an
    explicit offset (BigQuery's real wire format always does: "...+00") keeps that offset rather
    than having it silently discarded.

    Callers own the falsy-v / falsy-tz_name guard and the exception fallback string: this raises
    ValueError (unparseable timestamp string) or ZoneInfoNotFoundError (bad/unsupported IANA
    tz_name, e.g. an unvalidated value from the Calendar connector) on failure rather than
    swallowing either, since the two current call sites disagree on what to return when it fails.
    """
    s = str(v).strip()
    if s.endswith(" UTC"):
        s = s[:-4]
    elif s.endswith("Z"):
        s = s[:-1] + "+00:00"
    dt = datetime.fromisoformat(s)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(ZoneInfo(tz_name)).strftime("%Y-%m-%d %H:%M") + f" ({tz_name})"

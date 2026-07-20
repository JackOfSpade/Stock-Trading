"""Direct unit coverage for the shared lib scripts/lib/tz_render.py.

This module is the de-duplicated single implementation that scripts/alert_relay.py and
ops/dashboard/generate_dashboard.py both wrap (2026-07-20 dedup audit, finding C14) — before this
consolidation the two sites' get_user_tz()/fmt_ts() had already independently drifted (alert_relay.py
unconditionally overwrote a parsed datetime's tzinfo with UTC, discarding any real offset; generate_
dashboard.py only did so for a naive parse, and also stripped a trailing "Z" that alert_relay.py never
handled). These tests pin the STRICTER shared core directly, on top of the two call sites' own
tests/test_alert_relay.py / tests/test_generate_dashboard.py suites (both left unmodified), which
pin each thin wrapper's own falsy-v handling and fallback label.
"""
import pytest

from scripts.lib.tz_render import ZoneInfoNotFoundError, get_display_tz, render_ts


# ---- get_display_tz(): happy path + NULL/empty/error fallback to Denver -----------------------

def test_get_display_tz_happy_path():
    assert get_display_tz(lambda sql: [{"tz": "Europe/London"}], "proj") == "Europe/London"


def test_get_display_tz_null_value_falls_back_to_denver():
    # A NULL state.user_tz.tz (row present, value None) must coalesce to Denver — returning None
    # here would make render_ts(v, None) raise TypeError in a caller that doesn't guard it first.
    assert get_display_tz(lambda sql: [{"tz": None}], "proj") == "America/Denver"


def test_get_display_tz_empty_rows_falls_back_to_denver():
    assert get_display_tz(lambda sql: [], "proj") == "America/Denver"


def test_get_display_tz_query_error_falls_back_to_denver():
    def _boom(sql):
        raise RuntimeError("bq down")
    assert get_display_tz(_boom, "proj") == "America/Denver"


def test_get_display_tz_passes_project_qualified_sql():
    # Locks the SELECT shape callers rely on (state.user_tz, backtick-qualified by project).
    seen = {}

    def _capture(sql):
        seen["sql"] = sql
        return [{"tz": "UTC"}]
    get_display_tz(_capture, "my-proj-123")
    assert "`my-proj-123.state.user_tz`" in seen["sql"]


# ---- render_ts(): strip rules (" UTC" / "Z") ---------------------------------------------------

def test_render_ts_strips_trailing_space_utc_suffix():
    assert render_ts("2026-07-04 12:00:00 UTC", "UTC") == "2026-07-04 12:00 (UTC)"


def test_render_ts_strips_trailing_z_suffix():
    assert render_ts("2026-07-04T12:00:00Z", "UTC") == "2026-07-04 12:00 (UTC)"


def test_render_ts_bigquery_cast_as_string_wire_form():
    # Real wire format (verified against live BigQuery): "YYYY-MM-DD HH:MM:SS[.ffffff]+00" — a
    # space date/time separator and an explicit "+00" offset, no "Z" and no literal "UTC".
    assert render_ts("2026-07-09 18:26:21.157141+00", "America/Denver") == "2026-07-09 12:26 (America/Denver)"


# ---- render_ts(): only overwrite tzinfo when the parse is naive (the actual bug this
#      consolidation fixes for alert_relay.py, which used to overwrite unconditionally) ----------

def test_render_ts_naive_string_is_assumed_utc():
    # No offset in the string at all -> treated as UTC (matches both sites' prior behavior for the
    # naive case).
    assert render_ts("2026-07-04 12:00:00", "UTC") == "2026-07-04 12:00 (UTC)"


def test_render_ts_preserves_a_non_utc_offset_instead_of_overwriting_it():
    # A parse that already carries an explicit (non-UTC) offset must be honored, not silently
    # discarded and replaced with UTC. 12:00 at +05:00 is 07:00 UTC == 07:00 at UTC display tz.
    assert render_ts("2026-07-04 12:00:00+05:00", "UTC") == "2026-07-04 07:00 (UTC)"


def test_render_ts_utc_offset_wire_form_matches_z_suffixed_equivalent():
    z_result = render_ts("2026-07-04T12:00:00Z", "America/Denver")
    plus_offset_result = render_ts("2026-07-04 12:00:00+00:00", "America/Denver")
    assert z_result == plus_offset_result


# ---- render_ts(): failure modes callers must catch ---------------------------------------------

def test_render_ts_unparseable_string_raises_value_error():
    with pytest.raises(ValueError):
        render_ts("not-a-timestamp", "America/Denver")


def test_render_ts_bad_timezone_raises_zoneinfo_not_found_error():
    with pytest.raises(ZoneInfoNotFoundError):
        render_ts("2026-06-28 05:00:00", "Not/A_Real_Zone")

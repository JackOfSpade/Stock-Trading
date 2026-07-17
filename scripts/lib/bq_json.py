"""Shared bq-CLI stdout -> JSON parser.

`bq query --format=json` sometimes prints a human banner (e.g. "Waiting on bqjob...") before the
JSON array, so callers slice from the first '['. This exact parsing logic was independently
duplicated (and independently bug-fixed after a production incident — "parse bq JSON, not CSV —
KeyError on first run") in scripts/dbt_parity.py, scripts/alert_relay.py, and
ops/dashboard/generate_dashboard.py. Consolidated here so a future fix lands in one place
(2026-07-14 audit finding).
"""
import json


def parse_bq_json_stdout(stdout: str) -> list[dict]:
    """Return bq's JSON row array, tolerating non-JSON status text before it.

    `bq query --format=json` should emit a JSON array of row objects, but the CLI can prepend
    human-readable status output. Older call sites sliced from the first '['; that still fails
    closed when a banner itself contains bracketed text. Try each possible array boundary until
    one parses as the complete trailing value.
    """
    s = stdout.strip()
    last_error = None
    for i, ch in enumerate(s):
        if ch != "[":
            continue
        try:
            rows = json.loads(s[i:])
        except json.JSONDecodeError as e:
            last_error = e
            continue
        if not isinstance(rows, list):
            raise ValueError("bq JSON output was not a row array")
        if any(not isinstance(row, dict) for row in rows):
            raise ValueError("bq JSON output rows were not objects")
        return rows
    if last_error is not None:
        raise last_error
    return []

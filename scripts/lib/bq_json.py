"""Shared bq-CLI stdout -> JSON parser.

`bq query --format=json` sometimes prints a human banner (e.g. "Waiting on bqjob...") before the
JSON array, so callers slice from the first '['. This exact parsing logic was independently
duplicated (and independently bug-fixed after a production incident — "parse bq JSON, not CSV —
KeyError on first run") in scripts/dbt_parity.py, scripts/alert_relay.py, and
ops/dashboard/generate_dashboard.py. Consolidated here so a future fix lands in one place
(2026-07-14 audit finding).
"""
import json


def parse_bq_json_stdout(stdout):
    s = stdout.strip()
    i = s.find("[")
    return json.loads(s[i:]) if i != -1 else []

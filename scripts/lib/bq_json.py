"""Shared bq-CLI stdout -> JSON parser, and the shared bq-CLI invoke wrapper built on top of it.

`bq query --format=json` sometimes prints a human banner (e.g. "Waiting on bqjob...") before the
JSON array, so callers slice from the first '['. This exact parsing logic was independently
duplicated (and independently bug-fixed after a production incident — "parse bq JSON, not CSV —
KeyError on first run") in scripts/dbt_parity.py, scripts/alert_relay.py, and
ops/dashboard/generate_dashboard.py. Consolidated here so a future fix lands in one place
(2026-07-14 audit finding).

run_bq_query(), below, completes that same extraction for the subprocess-invoke half of the
pattern: scripts/dbt_parity.py, scripts/check_live_roster_parity.py, scripts/alert_relay.py, and
scripts/check_live_sql_parity.py each independently defined a `bq(sql[, project])` that ran the
identical bq CLI invocation (subprocess.run with --format=json, TimeoutExpired -> RuntimeError,
nonzero returncode -> RuntimeError, else parse_bq_json_stdout) and had already silently drifted
from each other (differing --max_rows values, one missing the sql-snippet suffix on its timeout
message) before this consolidation (2026-07-18 dedup-sweep audit).
"""
import json
import subprocess


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


def run_bq_query(sql, project, max_rows=None, timeout=600):
    """Run a read-only `bq query` and return the parsed JSON row list.

    The shared invoke half of the bq()-wrapper pattern duplicated across scripts/dbt_parity.py,
    scripts/check_live_roster_parity.py, scripts/alert_relay.py, and scripts/check_live_sql_parity.py
    (see module docstring). `max_rows=None` omits --max_rows entirely, matching
    check_live_sql_parity.py's existing no-flag behavior; callers that previously passed
    --max_rows=N keep doing so by passing max_rows=N here.
    """
    argv = ["bq", "--project_id=" + project, "--quiet", "--headless", "--format=json",
            "query", "--use_legacy_sql=false"]
    if max_rows is not None:
        argv.append(f"--max_rows={max_rows}")
    argv.append(sql)
    try:
        out = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s: {sql[:120]}") from e
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return parse_bq_json_stdout(out.stdout)

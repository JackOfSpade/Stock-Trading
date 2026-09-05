#!/usr/bin/env python3
"""Single-source the Apps Script version constants: .gs file <-> bigquery/43's MERGE seed
(2026-07-14 self-improvement audit finding).

WHY THIS EXISTS. ops/monitoring/alert_emailer.gs's ALERT_SCRIPT_VERSION and
ops/weekly_report/weekly_report.gs's SCRIPT_VERSION are each hand-kept in lockstep with
bigquery/43_script_version_registry.sql's MERGE seed (state.expected_script_versions), which
state.script_version_drift compares against ops.heartbeat.version to catch "repo fixed but the
live out-of-band script not redeployed." Every other cross-file constant this codebase maintains
this way (ops/cadence.yaml, strategy/roster.yaml's rails) has a dedicated CI script that fails the
build on drift — this pairing had none: a future .gs version bump that forgets to also bump the
seed (or vice versa) would silently break state.script_version_drift with no CI signal.

Usage:  python scripts/check_script_version_consistency.py    # exit 0 if consistent, 1 + diff if not
"""
import bisect
import collections
import os
import re

# ORGANIZATION FIX (2026-08-31 code-quality pass, contracts#2): this file predates lib.textio.py
# (2026-07-15 vs 2026-07-29) and its two bare open(path, encoding="utf-8").read() call sites survived
# the 2026-08-08 whole-repo consolidation pass untouched -- every sibling checker on this audit surface
# (check_handoff_contracts.py, check_superseded_by_discipline.py, check_superseded_markers.py,
# check_sq_version_registry.py) already reads through lib.textio.read_text() exclusively.
#
# SIBLING PARITY (roster-group bug, 2026-09-04): the same consolidation logic applies to comment
# stripping and duplicate-row detection. check_sq_version_registry.py -- which describes ITSELF as this
# script's pairing check "ported to scheduled queries" -- guards both halves for a structurally identical
# MERGE seed, while parse_seed_versions() here was a raw-text `dict(findall())`. See that function's
# docstring for the two demonstrated failure modes.
from lib.report import fail_or_ok
from lib.sql_files import line_offsets, strip_sql_comments
from lib.textio import read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALERT_GS = os.path.join(ROOT, "ops", "monitoring", "alert_emailer.gs")
WEEKLY_GS = os.path.join(ROOT, "ops", "weekly_report", "weekly_report.gs")
REGISTRY_SQL = os.path.join(ROOT, "bigquery", "43_script_version_registry.sql")

# Whitespace-tolerant: alert_emailer.gs aligns with extra spaces before '=', weekly_report.gs does not.
GS_VERSION = re.compile(r"const\s+(?:ALERT_)?SCRIPT_VERSION\s*=\s*'([^']+)'")
SEED_ROW = re.compile(r"STRUCT\('(\w+)'\s+AS\s+script_name,\s*'([^']+)'\s+AS\s+expected_version")

# script_name (bigquery/43's MERGE seed key, == ops.heartbeat.source) -> .gs file path.
SCRIPTS = {"alert_emailer": ALERT_GS, "weekly_report": WEEKLY_GS}


def parse_gs_version(path):
    m = GS_VERSION.search(read_text(path))
    return m.group(1) if m else None


def parse_seed_versions():
    """({script_name: expected_version}, errors) from bigquery/43's MERGE seed STRUCT rows.

    Both guards below mirror check_sq_version_registry.py's parse_registry(), which enforces the exact
    same shape for bigquery/63's registry seed and had carried both since 2026-08-06 while this,
    its self-described twin, had neither (roster-group bug, 2026-09-04 — paired mechanisms drift).

    COMMENT STRIPPING. This used to be `dict(SEED_ROW.findall(read_text(REGISTRY_SQL)))` over RAW text,
    so a commented-out prior seed row counted as a live one. Reproduced: inserting a DR-note aside in
    this repo's own idiom before the `ON T.script_name = S.script_name` line —
    `-- PRIOR (v9, kept for the DR record):` / `--   STRUCT('weekly_report' AS script_name, 'v8' AS
    expected_version, ...)` — made this BLOCKING gate print "version const is 'v9' but ... expects 'v8'"
    and exit 1, with no real drift and no change to the live MERGE. bigquery/43 is the most-edited file
    in this group (touched on every .gs version bump) and its git_note fields are already multi-thousand-
    character prose change-logs, so narrating a prior row's STRUCT in a comment is a natural next edit.
    THE TRAP, checked before this landed: those git_note literals contain many `--` sequences INSIDE
    single-quoted strings (198 in the file, 25 of which survive stripping — re-measured 2026-09-05
    after the WR-2 APPLY STATE header edit; re-measure again on any bigquery/43 edit), so a naive stripper would
    blank the rest of the file mid-string. lib/sql_files.py's strip_sql_comments() is string-literal-aware
    (_string_literal_end) and is a verified no-op here: same length, same newline count, same parse.

    DUPLICATE ROW DETECTION. A plain {name: version} dict silently collapses two STRUCT rows sharing a
    script_name to whichever finditer() visits LAST — exit 0, no parse error — while bigquery/43's MERGE
    (`ON T.script_name = S.script_name`, unconditional WHEN MATCHED) is rejected by BigQuery at APPLY
    time for exactly that source ("UPDATE/MERGE must match at most one source row for each target row").
    Track every line each script_name is seen on so a duplicate fails loud, naming both line numbers."""
    raw = read_text(REGISTRY_SQL)
    stripped = strip_sql_comments(raw)
    # line_offsets() over the RAW text is valid against the STRIPPED text too: strip_sql_comments()
    # blanks to spaces and keeps every newline, so offsets are identical (same convention as
    # check_sq_version_registry.py's collect_bigquery()). bisect_right gives the 1-based line number.
    offsets = line_offsets(raw)
    rows = {}
    lines_by_name = collections.defaultdict(list)
    for m in SEED_ROW.finditer(stripped):
        name, version = m.group(1), m.group(2)
        lines_by_name[name].append(bisect.bisect_right(offsets, m.start()))
        rows[name] = version
    errors = []
    for name, seen_at in sorted(lines_by_name.items()):
        if len(seen_at) > 1:
            errors.append(
                f"bigquery/43_script_version_registry.sql: duplicate MERGE seed row for "
                f"script_name='{name}' at lines {', '.join(str(n) for n in sorted(seen_at))} — that "
                f"file's MERGE (`ON T.script_name = S.script_name`, unconditional WHEN MATCHED) is "
                f"rejected by BigQuery at apply time when the source has more than one row matching the "
                f"same target row ('UPDATE/MERGE must match at most one source row for each target "
                f"row'); this checker used to silently keep only the last-parsed row and exit 0. Keep "
                f"exactly one STRUCT row per script_name.")
    return rows, errors


def main():
    seed, errors = parse_seed_versions()
    for script_name, gs_path in SCRIPTS.items():
        gs_version = parse_gs_version(gs_path)
        rel = os.path.relpath(gs_path, ROOT)
        if gs_version is None:
            errors.append(f"{rel}: could not find a SCRIPT_VERSION/ALERT_SCRIPT_VERSION const "
                          f"(regex may need updating if the declaration shape changed)")
            continue
        seed_version = seed.get(script_name)
        if seed_version is None:
            errors.append(f"bigquery/43_script_version_registry.sql: no MERGE seed row for "
                          f"script_name='{script_name}' (expected one matching {rel})")
        elif gs_version != seed_version:
            errors.append(f"{rel}'s version const is '{gs_version}' but "
                          f"bigquery/43_script_version_registry.sql's seed for '{script_name}' "
                          f"expects '{seed_version}' — bump the seed in the SAME commit that bumps "
                          f"the .gs version const")

    # REFACTOR (2026-08-31 code-quality pass, cross-cutting#0): shared FAIL/OK block, see
    # lib/report.py's module docstring.
    return fail_or_ok(
        "SCRIPT VERSION CONSISTENCY", errors,
        f"SCRIPT VERSION CONSISTENCY: OK — {len(SCRIPTS)} script(s) agree with "
        f"bigquery/43_script_version_registry.sql's seed.",
    )


if __name__ == "__main__":
    raise SystemExit(main())

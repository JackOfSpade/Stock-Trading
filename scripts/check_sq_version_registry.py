#!/usr/bin/env python3
"""Single-source the scheduled-query heartbeat version: bigquery/75+supersessions' `ops.sp_sq_<name>`
procedure body <-> bigquery/63's registry MERGE seed (2026-08-06, alert-triage follow-up).

WHY THIS EXISTS. Each `ops.sp_sq_<name>` wrapper procedure (originally defined in
bigquery/75_scheduled_query_wrappers.sql, some later redefined via `CREATE OR REPLACE PROCEDURE` in a
higher-numbered file) ends with a self-reported
`CALL ops.sp_beat_heartbeat('sq:<name>', '<version>', ...)` literal. bigquery/63's
state.scheduled_query_version_drift view compares that live-reported version against
bigquery/63_scheduled_query_version_registry.sql's MERGE seed row for the same `sq_name` — the SAME
pairing check_script_version_consistency.py already enforces for the .gs/bigquery-43 pair, ported to
scheduled queries. The drift class it feeds, `scheduled_query_version_drift`, has NO row in
ops.alert_policy, so a WARNING it raises can never auto-resolve: it recurs nightly until someone hand-
fixes the registry. That happened twice with zero CI signal before this script existed: commit 0b9fd49
bumped daily_staging_cap_check's heartbeat literal v4 -> v5 in bigquery/75 without bumping bigquery/63's
seed, and commit 9a67c22 added cadence_check logic in a superseding file without bumping the heartbeat
literal at all.

APPLY-IN-ORDER SUPERSESSION. bigquery/*.sql is apply-in-order (see check_superseded_markers.py's
header): several `ops.sp_sq_<name>` procedures are redefined via `CREATE OR REPLACE PROCEDURE` in more
than one numbered file (cadence_check: 75, 111, 120, 128, 132; fire_drill_alert_lifecycle: 75, 134), and
the HIGHEST-numbered file's body is the one that is actually deployed live. Comparing bigquery/75's
literal unconditionally for those two would silently read a stale, already-superseded version and miss
real drift (or false-flag a non-drift). This script resolves the winning definition PER PROCEDURE the
same order-independent way check_superseded_markers.py's violations() does (group occurrences by
object identity, canonical file = max(file number)) rather than assuming bigquery/75 is always current.

ALSO CHECKS TWO ASYMMETRIES that are bugs even with no version mismatch: a bigquery/63 registry row
whose sq_name has no corresponding `ops.sp_sq_<name>` procedure anywhere in bigquery/*.sql (a dead
registry entry, or a typo'd sq_name that can never be satisfied), and a procedure with a `sq:` heartbeat
that has no bigquery/63 registry row at all (drift can never even be evaluated for it).

KNOWN TRAP, deliberately avoided: bigquery/63's git_note strings are long free-text change-logs
containing things like "v3, 2026-07-17" and "bigquery/75's SQ_VERSION" — text that trivially false-
matches a loose "look for a version-shaped token" regex. This script never does a loose scan: it anchors
on the exact `STRUCT('<sq_name>', '<version>', '<git_note>', <interval>)` shape (first row's fields
carry `AS <col>` labels per BigQuery UNNEST(ARRAY<STRUCT...>) syntax, later rows are positional-only —
both are matched) and treats the quoted fields as escape-aware string literals (`(?:\\.|[^'\\])*`, the
same construction strip_sql_comments() uses for its own literal scanning) so an embedded `\'` inside a
git_note (cadence_check's note has several, e.g. "...W5\'s weekly belt-and-suspenders..." and
"...bigquery/79_b3_promotion.sql\'s header spec...") does not truncate the match early and shift every
subsequent field. `--` line comments and `/* */` block comments are stripped (via
scripts/lib/sql_files.py's strip_sql_comments(), shared with check_superseded_markers.py) before any
regex runs, so commented-out CALL/STRUCT text can never be mistaken for a live definition.

Read-only, no BigQuery/dbt CLI needed — pure text parsing of files already in the repo.

Usage:  python scripts/check_sq_version_registry.py   # exit 0 if consistent, 1 + diff if not
"""
import bisect
import collections
import os
import re

from lib.report import fail_or_ok
from lib.sql_files import (
    line_offsets, numbered_sql_files, resolve_canonical, strip_sql_comments,
)
from lib.textio import read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")
REGISTRY_SQL = os.path.join(ROOT, "bigquery", "63_scheduled_query_version_registry.sql")
REGISTRY_REL = "bigquery/63_scheduled_query_version_registry.sql"

PROJECT = "stock-trading-498512"

# `CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_<name>`(` — the wrapper definitions,
# possibly repeated across multiple numbered files (apply-in-order supersession, see module docstring).
PROC_DDL = re.compile(
    rf"CREATE\s+OR\s+REPLACE\s+PROCEDURE\s+`{re.escape(PROJECT)}\.ops\.sp_sq_(\w+)`\s*\(",
    re.IGNORECASE,
)

# `CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:<name>', '<version>', ...)` — an escape-aware
# quoted-string match for the version field (BigQuery string literals in this repo backslash-escape an
# embedded quote, e.g. bigquery/63's own git_note text), so a lone `\'` inside a note nearby can't
# truncate a match early. Only the first two args are needed here.
HEARTBEAT_CALL = re.compile(
    rf"CALL\s+`{re.escape(PROJECT)}\.ops\.sp_beat_heartbeat`\(\s*"
    r"'sq:(\w+)'\s*,\s*"
    r"'((?:\\.|[^'\\])*)'",
    re.IGNORECASE,
)

# `STRUCT('<sq_name>', '<expected_version>', '<git_note>', <expected_interval_hours>)` inside bigquery/
# 63's MERGE seed. The first row in the UNNEST(ARRAY<STRUCT...>) list carries `AS <col>` labels (they
# infer the struct's field names/types for every later row); every later row is positional-only. Both
# shapes are matched. Quoted fields use the same escape-aware pattern as HEARTBEAT_CALL above.
STRUCT_ROW = re.compile(
    r"STRUCT\(\s*"
    r"'((?:\\.|[^'\\])*)'(?:\s+AS\s+sq_name)?\s*,\s*"
    r"'((?:\\.|[^'\\])*)'(?:\s+AS\s+expected_version)?\s*,\s*"
    r"'((?:\\.|[^'\\])*)'(?:\s+AS\s+git_note)?\s*,\s*"
    r"(\d+)(?:\s+AS\s+expected_interval_hours)?"
    r"\s*\)",
    re.IGNORECASE | re.DOTALL,
)


def _line_no(offsets, pos):
    """1-based line number for `offsets` (scripts/lib/sql_files.py's line_offsets(), see its
    docstring) via bisect — the 1-based half of the two conventions that helper supports."""
    return bisect.bisect_right(offsets, pos)


def collect_bigquery():
    """(proc_defs, heartbeat_calls): both {name: [(number, filename, pos), ...]} (heartbeat_calls'
    tuples carry a trailing version too), plus {filename: line_offsets} for line-number lookups.

    Walks bigquery/*.sql in NUMERIC apply order via numbered_sql_files() (not `sorted(os.listdir())`'s
    lexical order — see scripts/lib/sql_files.py's own header for why that distinction matters once the
    directory crosses 99 files) and strips `--`/`/* */` comments first via strip_sql_comments(), so a
    commented-out CREATE/CALL can never be mistaken for a live one. strip_sql_comments() preserves every
    character's original position and every newline, so offsets computed against the ORIGINAL text are
    still valid line lookups against the stripped text that was actually searched.
    """
    proc_defs = collections.defaultdict(list)
    heartbeat_calls = collections.defaultdict(list)
    offsets_by_file = {}
    for number, path in numbered_sql_files(BIGQUERY_DIR):
        if os.path.isdir(path):
            continue
        fn = os.path.basename(path)
        raw = read_text(path)
        stripped = strip_sql_comments(raw)
        offsets = line_offsets(raw)
        offsets_by_file[fn] = offsets
        for m in PROC_DDL.finditer(stripped):
            proc_defs[m.group(1)].append((number, fn, m.start()))
        for m in HEARTBEAT_CALL.finditer(stripped):
            heartbeat_calls[m.group(1)].append((number, fn, m.start(), m.group(2)))
    return proc_defs, heartbeat_calls, offsets_by_file


def parse_registry():
    """({sq_name: (expected_version, line_no)}, errors) from bigquery/63's MERGE seed STRUCT rows.

    DUPLICATE sq_name DETECTION (2026-08-06 adversarial audit, D5). A plain {name: (...)} dict build
    silently collapses two STRUCT rows sharing the same sq_name to whichever one finditer() visits
    LAST — no parse error, exit 0. That is a false GREEN for a condition that makes the LIVE MERGE
    FAIL at apply time: bigquery/63's MERGE uses `ON T.sq_name = S.sq_name` with an unconditional
    WHEN MATCHED, and BigQuery rejects a MERGE whose source has more than one row matching the same
    target row ("UPDATE/MERGE must match at most one source row for each target row"). Track every
    line each sq_name is seen on so a duplicate is reported by name AND by both (or more) line
    numbers, instead of silently keeping only the last-parsed row.
    """
    raw = read_text(REGISTRY_SQL)
    stripped = strip_sql_comments(raw)
    offsets = line_offsets(raw)
    rows = {}
    lines_by_name = collections.defaultdict(list)
    for m in STRUCT_ROW.finditer(stripped):
        name, version = m.group(1), m.group(2)
        line_no = _line_no(offsets, m.start())
        lines_by_name[name].append(line_no)
        rows[name] = (version, line_no)
    errors = []
    for name, seen_at in sorted(lines_by_name.items()):
        if len(seen_at) > 1:
            errors.append(
                f"{REGISTRY_REL}: duplicate registry row for sq_name='{name}' at lines "
                f"{', '.join(str(n) for n in sorted(seen_at))} — BigQuery's MERGE (`ON T.sq_name = "
                f"S.sq_name`, unconditional WHEN MATCHED) rejects a source with more than one row "
                f"matching the same target row at apply time ('UPDATE/MERGE must match at most one "
                f"source row for each target row'); this checker used to silently keep only the "
                f"last-parsed row and exit 0. Keep exactly one STRUCT row per sq_name.")
    return rows, errors


def resolve_winners(proc_defs, heartbeat_calls, offsets_by_file):
    """{name: (version, filename, line_no)} — the ACTUALLY-DEPLOYED heartbeat literal per procedure,
    apply-in-order aware: for each `ops.sp_sq_<name>`, the canonical definition is the HIGHEST-numbered
    file among its occurrences (order-independent max(), same logic as check_superseded_markers.py's
    violations() — see that script's module docstring for why max() over parsed file numbers needs no
    iteration-order care). Within that winning file, the matching heartbeat CALL is the one whose
    sq:<name> equals this procedure's name and whose file-number equals the winning number; when a file
    legitimately contains more than one CALL for the same name (not expected today), the one appearing
    LAST in the file wins, matching CREATE-OR-REPLACE-within-a-file semantics (a later statement in the
    same file always supersedes an earlier one in the same apply pass).

    Returns errors (list of str) too, for the pathological case where a procedure's winning file has no
    matching heartbeat CALL at all (so no version can be compared for it) — AND (D6, 2026-08-06
    adversarial audit) for the case where MORE THAN ONE DISTINCT FILE shares the winning number: a bare
    max() cannot tell which of two same-numbered files is the real canonical one (bigquery/*.sql's NN_
    prefix is not guaranteed unique — see scripts/lib/sql_files.py's resolve_canonical()), so silently
    indexing [0] would risk validating the WRONG file's heartbeat literal with no signal at all. This is
    dormant on the real tree today (verified: bigquery/114_period_aware_dependency_gate.sql and
    bigquery/114_selfheal_log_created_outcome.sql both carry leading number 114, but neither defines an
    `ops.sp_sq_*` procedure, so no `name` here ever has two occurrences tied at the same winning number)
    — a FUTURE colliding file that adds one would previously have been silently, and possibly wrongly,
    resolved instead of raising this error.
    """
    winners, errors = {}, []
    for name, occurrences in proc_defs.items():
        winner_number, winner_files = resolve_canonical(occurrences)
        if len(winner_files) > 1:
            errors.append(
                f"ops.sp_sq_{name}: AMBIGUOUS canonical definition — bigquery/{winner_number} is the "
                f"winning (highest) leading number among {sorted(n for n, _, _ in occurrences)}, but "
                f"{len(winner_files)} DIFFERENT files share that number and each defines "
                f"`CREATE OR REPLACE PROCEDURE ops.sp_sq_{name}`: "
                f"{', '.join('bigquery/' + fn for fn in winner_files)}. resolve_winners() cannot "
                f"silently choose between them — renumber one file so the leading number is unique, "
                f"or determine which definition is actually deployed and delete/renumber the other."
            )
            continue
        winner_fn = winner_files[0]
        candidates = [
            (pos, version)
            for n, fn, pos, version in heartbeat_calls.get(name, [])
            if n == winner_number and fn == winner_fn
        ]
        if not candidates:
            errors.append(
                f"ops.sp_sq_{name}: winning definition is bigquery/{winner_fn} (highest-numbered of "
                f"{sorted(n for n, _, _ in occurrences)}) but no `CALL ops.sp_beat_heartbeat('sq:{name}', "
                f"...)` literal was found inside bigquery/{winner_fn} — cannot determine its deployed "
                f"version"
            )
            continue
        pos, version = max(candidates, key=lambda t: t[0])
        winners[name] = (version, winner_fn, _line_no(offsets_by_file[winner_fn], pos))
    return winners, errors


def main():
    proc_defs, heartbeat_calls, offsets_by_file = collect_bigquery()
    winners, resolve_errors = resolve_winners(proc_defs, heartbeat_calls, offsets_by_file)
    registry, registry_errors = parse_registry()

    errors = list(resolve_errors) + list(registry_errors)

    procedure_names = set(proc_defs)
    heartbeat_names = set(heartbeat_calls)
    registry_names = set(registry)

    for name in sorted(registry_names - procedure_names):
        _, reg_line = registry[name]
        errors.append(
            f"{REGISTRY_REL}:{reg_line} has a registry row for sq_name='{name}' but no "
            f"`CREATE OR REPLACE PROCEDURE ops.sp_sq_{name}` exists anywhere in bigquery/*.sql — dead "
            f"registry row (or a typo'd sq_name that can never match a live heartbeat)"
        )

    for name in sorted(heartbeat_names - registry_names):
        winner = winners.get(name)
        where = f"bigquery/{winner[1]}:{winner[2]}" if winner else "bigquery/*.sql"
        errors.append(
            f"ops.sp_sq_{name} ({where}) beats heartbeat 'sq:{name}' but {REGISTRY_REL} has no "
            f"registry row for sq_name='{name}' — its drift can never be evaluated; add a STRUCT row"
        )

    for name in sorted(set(winners) & registry_names):
        body_version, body_fn, body_line = winners[name]
        reg_version, reg_line = registry[name]
        if body_version != reg_version:
            errors.append(
                f"ops.sp_sq_{name}: body reports '{body_version}' (bigquery/{body_fn}:{body_line}) but "
                f"{REGISTRY_REL}:{reg_line}'s registry row for sq_name='{name}' expects '{reg_version}' "
                f"— bump the registry MERGE seed in the SAME commit that bumps the heartbeat literal"
            )

    # REFACTOR (2026-08-31 code-quality pass, cross-cutting#0): shared FAIL/OK block, see
    # lib/report.py's module docstring. sort=True reproduces the `sorted(errors)` this checker's
    # `errors` list needed at print time (it's assembled out of several independent scan passes, not
    # already in report order).
    return fail_or_ok(
        "SCHEDULED-QUERY VERSION REGISTRY", errors,
        f"SCHEDULED-QUERY VERSION REGISTRY: OK — {len(winners)} ops.sp_sq_* procedure(s) agree with "
        f"{REGISTRY_REL}'s registry (apply-in-order winner resolved for each).",
        sort=True,
    )


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Fail CI if a cross-routine handoff contract is unpinned: an OMITTED queue drain-close, a
NOT NULL/no-default BigQuery column a routine writes but Claude_Task_Plan.md never names, or a
ROW-mediated handoff whose consumer pins no concrete discovery predicate.

WHY THIS EXISTS. Six instances of ONE defect class were found by ad-hoc sweeps in three days
(2026-08-18/19), none by CI:
  1. SL3->SL5 PENDING_ROSTER handoff pinned no `queue`/`item_key` (both NOT NULL, no default).
  2. SL5's PENDING_ROSTER drain never stated its own terminal-status close.
  3. SL5's change_key pinned no literal.
  4. AR_orc's artifact_version_drift close was written into a branch the resolving session never
     executes (the close instruction sat in the WITHHOLD branch of the gate that raised it, but the
     session that eventually resolves it takes the gate's EQUAL-SHA branch and never reads that far).
  5. SL5's PENDING_DRAFT drain (owned by SL2) never stated its own close.
  6. events.strategy_research_leads.lead_id/event_type/archetype -- NOT NULL, no default, never named
     anywhere in the plan.
All six are now fixed in Claude_Task_Plan.md; this script is the mechanical guard that keeps them
fixed and catches the next instance of the same shape. Claude_Task_Plan.md's own D3 VENUE-CLAIM
HONORING CHECK states the principle this script exists to enforce: "A prose rule restated repeatedly
is evidently not self-enforcing on its own; a mechanical check is."

Claude_Task_Plan.md (~1MB) is CANONICAL; task_plan/*.md are generated slices (scripts/split_task_plan.py
--check already guards them in CI). This script parses the MONOLITH directly and reuses
scripts/split_task_plan.py's own split() (itself built on scripts/lib/routine_manifest.py's
ROUTINE_SUFFIX / heading_to_id, the same primitives print_routines.py and check_cadence_consistency.py
use) to carve it into per-routine sections -- so this gate can never disagree with those tools about
what a routine section is.

CHECK A -- QUEUE DRAIN-CLOSE COMPLETENESS (ops/handoff_contracts.yaml `queue_lanes`).
For each declared lane (queue, terminal_status, one-or-more drainer routine ids, why), assert that AT
LEAST ONE of the lane's drainer routines' OWN section states a close instruction: a line containing
(case-insensitive) the word "insert", the token "queue_events", AND the terminal_status value used
either quote/backtick-delimited (`'complete'`, `` `complete` ``) or immediately after "status ="/"status:"
-- e.g. "status = complete". That second form is deliberately narrower than a bare `\bcomplete\b`
scan: PENDING_REVIEW's OWN intermediate status is the compound token "attacker-complete", and a plain
word-boundary regex matches "complete" INSIDE that hyphenated compound (a hyphen is a regex word
boundary) -- which would let AR_att's own line ("... with status = attacker-complete") satisfy the
close pattern for AR_orc's lane even after AR_orc's real close is deleted, defeating the "catches the
defect" self-test below. Requiring either delimiter quoting or a direct "status ="/"status:" prefix
excludes that compound while still matching every real close in this document today (verified: all
four -- D2/SL2/SL5/AR_orc -- land on exactly one physical line each).

QUEUE-LITERAL SCOPE is the drainer's own section as a whole (not the same tight window as the
terminal-status+insert-phrase pair): AR_orc's real close (Step 5, "insert a `queue_events` row (same
`item_key`) with status = complete") does not repeat the literal "PENDING_REVIEW" on its own line --
the routine only ever processes one lane, so restating the lane name at every step would be pure
noise -- while D2/SL2/SL5's closes do carry their queue literal on the same line as a documented,
load-bearing style choice ("CLOSE THE DRAINED <QUEUE> ITEM" bullets). Requiring same-line co-location
for ALL THREE tokens would therefore spuriously fail AR_orc's already-correct close; requiring only
the terminal-status+insert-phrase pair to be tightly co-located (this is the actual "is there a close
INSTRUCTION here" question) while checking the queue literal is at least named somewhere in that same
drainer's own section (this is "is the instruction about THIS lane") is the narrower, defensible
choice that still fails cleanly the moment a close instruction is deleted outright -- see the
self-test in this repo's PR/commit history for the two engineered-failure runs this design was
checked against (SL2 PENDING_DRAFT close removed; SL1's lead_id pin removed for CHECK B).

Sections come from scripts.split_task_plan.split(), which returns (rid, title, group_intro, body) per
routine. This check scans BODY ONLY, never group_intro: the ADVERSARIAL REVIEWS group_intro (the
"Pending_Adversarial_Reviews.md -- queue file schema" block, shared by AR_att and AR_orc alike)
itself contains the phrase "INSERT INTO events.queue_events with queue='PENDING_REVIEW'; status
transitions (pending->attacker-complete->complete/superseded)" -- which would satisfy the close
pattern for BOTH drainers regardless of whether either routine's OWN section states a real close,
because it is boilerplate shared across the whole group, not routine-specific instruction. Scoping to
body (the routine's own section, excluding shared group boilerplate) closes that hole; it is also
the more faithful reading of "the DRAINER routine's OWN section" the spec asks for.

ALSO asserts the YAML's queue->drainers map stays consistent with the machine-readable
`allowed_map` inside bigquery/180_probe_register_queue_lane.sql (state.queue_venue_claim_unwired) --
so ops/handoff_contracts.yaml cannot silently drift from the live venue-claim truth in either
direction (a queue/drainer set present in one but not the other is a FAIL, named explicitly).

CHECK B -- REQUIRED-COLUMN NAMING (ops/handoff_contracts.yaml `required_column_naming`).
Parses every `CREATE [OR REPLACE] TABLE [IF NOT EXISTS] project.(events|ops).<name>` in bigquery/*.sql
(numeric apply order via scripts/lib/sql_files.py, so a table CREATEd in one file and later
CREATE-OR-REPLACEd in another resolves to its LAST-in-apply-order definition -- see
parse_create_table_bodies()'s docstring for the one observed exception, which is a byte-identical
verbatim mirror and therefore order-independent in practice) and extracts columns that are NOT NULL
with no DEFAULT. For each such table the YAML lists under `write_targets`, asserts every one of those
column names appears at least once, ANYWHERE, in Claude_Task_Plan.md. This is a NAME-PRESENCE check,
not a semantic one -- deliberate, so it is near-zero false positive: a name that appears anywhere is
assumed to have been placed there on purpose, and the only failure mode this check flags is total
ABSENCE, which is exactly what all six founding instances were.

`write_targets` is a curated list (see the YAML file's own header for the full methodology): unlike
CHECK A's queue lanes, a CREATE TABLE statement carries no machine-readable "who writes this" fact,
so there is no independent source to diff against. Tables written ONLY through a stored procedure
that supplies the required columns from literal CALL arguments (ops.run_log via
sp_routine_start/sp_log_run, ops.alerts via sp_raise_alert*, events.decision_log via sp_log_decision,
events.adversarial_reviews via sp_write_adversarial_review) are listed under `procedure_wrapped`
instead and are NOT checked for name-presence -- the routine never composes those columns as free
text, so requiring the literal name in prose would defend nothing. Tables that are pure external-data
ingestion mirrors, internal SP-managed mutexes, or written only by infra/CI outside the routine fleet
are named under `excluded_tables` with a reason, never silently dropped.

Usage:  python scripts/check_handoff_contracts.py    # exit 0 if consistent, 1 + violations if not
CHECK C -- ROW-MEDIATED HANDOFF DISCOVERY PREDICATES (ops/handoff_contracts.yaml `row_handoffs`).
Added 2026-08-20 after a SEVENTH instance of the class, and the first one neither existing check
could see. SL5 branch (3) TERMINATED-deregister -- the one roster-mutation branch that REMOVES a
strategy and releases its capital -- named its input ("a TERMINATED events.strategy_lifecycle row")
and pinned no query for it, while SL5's own dispatch paragraph requires all three of its inputs be
read and found empty before declaring a no-op. CHECK A could not see it (nothing travels through
events.queue_events on this path) and CHECK B passed throughout, because CHECK B asserts only that a
NOT NULL column's NAME appears SOMEWHERE in the ~1MB plan -- `to_state` and `strategy_code` appear
dozens of times for unrelated reasons. A name-presence check cannot distinguish "the consumer has a
runnable query" from "the consumer has a sentence."
  C1 (consumer): the consumer routine's OWN section must contain a real discovery query -- some
     SELECT followed within QUERY_WINDOW_CHARS by both the table and the discovery-value literal.
     Proximity rather than fenced-block parsing on purpose: Claude_Task_Plan.md NESTS fences (each
     routine instruction is itself a ``` block and a pinned query is a ``` block inside it), so a
     non-greedy fence regex closes on the inner opener and splits the very query it is seeking.
  C2 (producers): every producer routine's OWN section must name each `pinned_columns` entry, so the
     row the consumer discovers carries the fields its predicate reads. This is what catches the
     other half of the same defect: `from_state` is NULLABLE with no default, SL5 derives the
     branch's idempotency key as CONCAT(strategy_code, ':', from_state, '->TERMINATED'), and
     BigQuery's CONCAT returns NULL if ANY argument is NULL -- so an unpinned from_state both
     defeats the NOT EXISTS anti-join (rediscovering the same termination every cycle forever) and
     violates ops.roster_change_log.change_key STRING NOT NULL.
Verified against history at authoring time: CHECK C fails on the pre-fix plan (2 errors) AND on the
commit that pinned only the consumer side (1 error), passing only once both producers pin too.

"""
import os
import re
import sys

try:
    # This module's own reads go through lib.textio.load_yaml() below, so `yaml` is not referenced
    # directly here -- the import stays only for this fail-fast, actionable ImportError guard (same
    # idiom as check_prose_invariants.py / check_autonomy_consistency.py).
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.sql_files import numbered_sql_files, strip_sql_comments
from lib.textio import load_yaml, read_text
from split_task_plan import split as split_task_plan_sections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "ops", "handoff_contracts.yaml")
TASK_PLAN_PATH = os.path.join(ROOT, "Claude_Task_Plan.md")
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")
ALLOWED_MAP_SOURCE = os.path.join(BIGQUERY_DIR, "180_probe_register_queue_lane.sql")
PROJECT = "stock-trading-498512"

# ============================================================================================
# Shared: per-routine section text (scripts/split_task_plan.split(), BODY ONLY -- see module
# docstring "Sections come from ..." for why group_intro is deliberately excluded).
# ============================================================================================


def routine_bodies(text):
    """{routine_id: body_text} for every routine section split_task_plan.split() finds.

    A duplicate routine id (should never happen -- split_task_plan.py's own build() guards against
    it with a defensive rename) is concatenated rather than silently overwritten, so this check would
    still see both bodies' content rather than losing one to a collision it did not cause.
    """
    _preamble, routines = split_task_plan_sections(text)
    bodies = {}
    for rid, _title, _group_intro, body in routines:
        bodies[rid] = bodies.get(rid, "") + body
    return bodies


# ============================================================================================
# CHECK A -- queue drain-close completeness
# ============================================================================================

INSERT_TOKEN = re.compile(r"\binsert\b", re.IGNORECASE)
QUEUE_EVENTS_TOKEN = re.compile(r"\bqueue_events\b", re.IGNORECASE)


def terminal_status_pattern(value):
    """A line matches iff `value` appears either quote/backtick-delimited or directly after
    "status ="/"status:" -- see the module docstring for why a bare \\bvalue\\b scan is unsafe here
    (it would match a hyphenated compound status like "attacker-complete")."""
    v = re.escape(value)
    return re.compile(
        rf"""(?:['"`]{v}['"`])|(?:\bstatus\s*[:=]\s*['"`]?{v}\b)""",
        re.IGNORECASE,
    )


def has_close_instruction(body, terminal_status):
    """True iff some physical line in `body` co-locates (same line) an "insert" token, the
    "queue_events" token, and the terminal-status literal in one of its two safe forms."""
    pat = terminal_status_pattern(terminal_status)
    for line in body.splitlines():
        if INSERT_TOKEN.search(line) and QUEUE_EVENTS_TOKEN.search(line) and pat.search(line):
            return True
    return False


def has_queue_literal(body, queue):
    return re.search(r"\b" + re.escape(queue) + r"\b", body) is not None


# The allowed_map STRUCT literal inside bigquery/180's `allowed_map AS (SELECT * FROM UNNEST([...]))`
# CTE -- see that file's own header for why it is the canonical queue->drainer source.
ALLOWED_MAP_STRUCT = re.compile(
    r"STRUCT\(\s*'([A-Z_]+)'\s+AS\s+queue\s*,\s*\[(.*?)\]\s+AS\s+allowed_drainers\s*\)",
    re.IGNORECASE | re.DOTALL,
)
DRAINER_LITERAL = re.compile(r"'([^']+)'")


def parse_allowed_map(path):
    """{queue: [drainer, ...]} parsed from bigquery/180's allowed_map CTE. Scoped to the
    `allowed_map AS (` ... matching `)` block so an unrelated STRUCT(...) literal elsewhere in the
    file (there is none today, but this is a live SQL file, not a fixture) can never be picked up."""
    text = strip_sql_comments(read_text(path))
    m = re.search(r"allowed_map\s+AS\s*\(", text, re.IGNORECASE)
    if not m:
        return None
    open_idx = m.end() - 1
    close_idx = _find_matching_paren(text, open_idx)
    if close_idx == -1:
        return None
    block = text[open_idx:close_idx]
    out = {}
    for qm in ALLOWED_MAP_STRUCT.finditer(block):
        queue = qm.group(1)
        drainers = DRAINER_LITERAL.findall(qm.group(2))
        out[queue] = drainers
    return out


def check_a(spec, bodies, errors):
    lanes = spec.get("queue_lanes") or []
    excluded = spec.get("excluded_queues") or []
    if not lanes:
        errors.append("CHECK A: ops/handoff_contracts.yaml has no `queue_lanes` entries")
        return 0

    checked = 0
    for lane in lanes:
        queue = lane.get("queue")
        terminal_status = lane.get("terminal_status")
        drainers = lane.get("drainers") or []
        why = (lane.get("why") or "").strip()
        if not queue or not terminal_status or not drainers:
            errors.append(f"CHECK A: queue_lanes entry {lane!r} is missing queue/terminal_status/drainers")
            continue
        if not why:
            errors.append(f"CHECK A: queue_lanes entry for {queue!r} is missing a `why`")

        per_drainer = []
        satisfied = False
        for rid in drainers:
            body = bodies.get(rid)
            if body is None:
                per_drainer.append(f"{rid}: NOT FOUND as a routine section in Claude_Task_Plan.md")
                continue
            has_close = has_close_instruction(body, terminal_status)
            has_literal = has_queue_literal(body, queue)
            if has_close and has_literal:
                satisfied = True
                break
            missing = []
            if not has_close:
                missing.append(
                    f"no line co-locates insert + queue_events + terminal-status "
                    f"{terminal_status!r}"
                )
            if not has_literal:
                missing.append(f"the queue literal {queue!r} does not appear anywhere in its section")
            per_drainer.append(f"{rid}: " + "; ".join(missing))
        checked += 1
        if not satisfied:
            errors.append(
                f"CHECK A: queue {queue!r} (terminal_status={terminal_status!r}) has no drain-close "
                f"instruction in ANY of its declared drainer(s) {drainers}: " + " | ".join(per_drainer)
            )

    for ex in excluded:
        if not (ex.get("queue") and (ex.get("why") or "").strip()):
            errors.append(f"CHECK A: excluded_queues entry {ex!r} is missing queue/why")

    # Consistency: YAML queue_lanes <-> bigquery/180's allowed_map, both directions.
    live_map = parse_allowed_map(ALLOWED_MAP_SOURCE)
    if live_map is None:
        errors.append(f"CHECK A: could not locate an allowed_map CTE in {ALLOWED_MAP_SOURCE}")
    else:
        yaml_map = {lane.get("queue"): sorted(lane.get("drainers") or []) for lane in lanes}
        live_map_sorted = {q: sorted(d) for q, d in live_map.items()}
        excluded_names = {ex.get("queue") for ex in excluded}
        for queue, drainers in live_map_sorted.items():
            if queue not in yaml_map:
                errors.append(
                    f"CHECK A: bigquery/180's allowed_map has queue {queue!r} -> {drainers} that is "
                    f"absent from ops/handoff_contracts.yaml queue_lanes (YAML has drifted from the "
                    f"live venue-claim source)"
                )
            elif yaml_map[queue] != drainers:
                errors.append(
                    f"CHECK A: queue {queue!r} drainers disagree -- bigquery/180 allowed_map says "
                    f"{drainers}, ops/handoff_contracts.yaml says {yaml_map[queue]}"
                )
        for queue in yaml_map:
            if queue not in live_map_sorted:
                errors.append(
                    f"CHECK A: ops/handoff_contracts.yaml queue_lanes has {queue!r} which is absent "
                    f"from bigquery/180's allowed_map (register it there, or this YAML has drifted)"
                )
        for queue in excluded_names:
            if queue in live_map_sorted:
                errors.append(
                    f"CHECK A: {queue!r} is listed in excluded_queues but bigquery/180's allowed_map "
                    f"DOES register it as a drain-to-completion lane -- the exclusion is stale"
                )
    return checked


# ============================================================================================
# CHECK B -- required-column naming
# ============================================================================================

CREATE_TABLE_RE = re.compile(
    r"CREATE\s+(?:OR\s+REPLACE\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?"
    rf"`{re.escape(PROJECT)}\.(events|ops)\.(\w+)`\s*\(",
    re.IGNORECASE,
)
COLNAME_RE = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)\b")
TABLE_CONSTRAINT_PREFIXES = ("PRIMARY KEY", "FOREIGN KEY", "CONSTRAINT", "CHECK")


def _skip_literal(text, i):
    """Index just past the SQL string literal starting at text[i] (which must be `'` or `"`).

    Handles triple-quoted literals, backslash escapes, and an unterminated single-line literal
    (which ends at the newline) -- the same literal grammar lib.sql_files.strip_sql_comments walks,
    because both consume the same bigquery/*.sql text. The structural scanners below MUST use this:
    strip_sql_comments deliberately copies literals through verbatim, so an OPTIONS(description=
    "...") free-text carrying `>`, `(` or `)` would otherwise be counted as nesting and silently
    swallow every column after it.
    """
    quote = text[i]
    n = len(text)
    triple = text[i:i + 3] == quote * 3
    end = quote * 3 if triple else quote
    j = i + (3 if triple else 1)
    while j < n:
        if not triple and text[j] == "\\":
            j += 2
            continue
        if text[j:j + len(end)] == end:
            return j + len(end)
        if not triple and text[j] == "\n":
            return j
        j += 1
    return n


def _find_matching_paren(text, open_idx):
    """Index of the `)` matching the `(` at open_idx, or -1 if it is never closed. String literals
    are skipped whole (see _skip_literal)."""
    depth = 0
    i = open_idx
    n = len(text)
    while i < n:
        c = text[i]
        if c in ("'", '"'):
            i = _skip_literal(text, i)
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _split_top_level_commas(s):
    """Split `s` on commas at depth 0, treating (), [], and <> (ARRAY<...>/STRUCT<...> generics,
    which may themselves contain a top-level comma, e.g. STRUCT<a INT64, b STRING>) as nesting.
    String literals are copied through verbatim and never contribute depth or split points (see
    _skip_literal)."""
    depth = 0
    parts, cur = [], []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in ("'", '"'):
            j = _skip_literal(s, i)
            cur.append(s[i:j])
            i = j
            continue
        if c in "([<":
            depth += 1
        elif c in ")]>":
            depth -= 1
        if c == "," and depth == 0:
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(c)
        i += 1
    parts.append("".join(cur))
    return parts


def _type_clause(column_def):
    """The portion of a column definition before OPTIONS(...) or any quote character -- the only
    portion that can legally carry NOT NULL / DEFAULT, so scanning only this avoids a false match
    inside an OPTIONS(description="...") free-text string (several tables' descriptions contain the
    literal words "default" or "not null" as English prose, not as a constraint)."""
    cut = len(column_def)
    m = re.search(r"\bOPTIONS\s*\(", column_def, re.IGNORECASE)
    if m:
        cut = min(cut, m.start())
    for qc in ("'", '"'):
        qi = column_def.find(qc)
        if qi != -1:
            cut = min(cut, qi)
    return column_def[:cut]


def parse_create_table_bodies(bigquery_dir):
    """{(dataset, table): column_body_text} using each table's LAST-in-apply-order CREATE TABLE
    definition (numeric apply order via lib.sql_files.numbered_sql_files -- NOT lexical directory
    order, which misorders any 3-digit file against a 2-digit one, per that module's own docstring).

    "Last wins" matches live BigQuery semantics for CREATE OR REPLACE TABLE (ops.ticker_backfill,
    ops.routine_catalog) directly. It does NOT literally match CREATE TABLE IF NOT EXISTS semantics
    (there, the FIRST applied definition is the one that actually creates the table; a later
    IF-NOT-EXISTS re-declaration is a no-op against a live table). The one IF-NOT-EXISTS table
    defined twice in this tree today, ops.loop_promotion_log (bigquery/71 + bigquery/84), is a
    byte-identical verbatim mirror by design (bigquery/84's own comment: "Verbatim mirror of
    bigquery/71's block so this file is self-contained and apply-order-tolerant") -- so first-wins
    and last-wins resolve to the identical column set here, and "last wins" is used uniformly rather
    than branching on the CREATE variant, which would add complexity with no behavioral difference on
    the current tree. A future genuinely-conflicting IF-NOT-EXISTS duplicate would need this function
    revisited.
    """
    bodies = {}
    for _num, path in numbered_sql_files(bigquery_dir):
        text = strip_sql_comments(read_text(path))
        for m in CREATE_TABLE_RE.finditer(text):
            dataset, table = m.group(1), m.group(2)
            open_idx = m.end() - 1
            close_idx = _find_matching_paren(text, open_idx)
            if close_idx == -1:
                continue  # malformed DDL; not this check's job to diagnose
            bodies[(dataset, table)] = text[open_idx + 1 : close_idx]
    return bodies


def required_not_null_columns(column_body):
    """Column names that are NOT NULL with no DEFAULT, from one CREATE TABLE's parenthesized body."""
    cols = []
    for part in _split_top_level_commas(column_body):
        part = part.strip()
        if not part:
            continue
        if part.upper().startswith(TABLE_CONSTRAINT_PREFIXES):
            continue
        cm = COLNAME_RE.match(part)
        if not cm:
            continue
        tc = _type_clause(part)
        has_not_null = re.search(r"\bNOT\s+NULL\b", tc, re.IGNORECASE) is not None
        has_default = re.search(r"\bDEFAULT\b", tc, re.IGNORECASE) is not None
        if has_not_null and not has_default:
            cols.append(cm.group(1))
    return cols


def check_b(spec, task_plan_text, errors):
    rcn = spec.get("required_column_naming") or {}
    write_targets = rcn.get("write_targets") or []
    procedure_wrapped = rcn.get("procedure_wrapped") or []
    excluded_tables = rcn.get("excluded_tables") or []
    if not write_targets:
        errors.append("CHECK B: ops/handoff_contracts.yaml has no `required_column_naming.write_targets` entries")
        return 0

    table_bodies = parse_create_table_bodies(BIGQUERY_DIR)

    def resolve(table_name):
        dataset, _, name = table_name.partition(".")
        return table_bodies.get((dataset, name))

    seen_tables = set()
    checked = 0
    for entry in write_targets:
        table = entry.get("table")
        why = (entry.get("why") or "").strip()
        if not table or not why:
            errors.append(f"CHECK B: write_targets entry {entry!r} is missing table/why")
            continue
        if table in seen_tables:
            errors.append(f"CHECK B: write_targets lists {table!r} more than once")
        seen_tables.add(table)
        body = resolve(table)
        if body is None:
            errors.append(f"CHECK B: write_targets table {table!r} has no CREATE TABLE in bigquery/*.sql")
            continue
        required = required_not_null_columns(body)
        checked += 1
        missing = [c for c in required if not re.search(r"\b" + re.escape(c) + r"\b", task_plan_text)]
        if missing:
            errors.append(
                f"CHECK B: {table} is NOT NULL/no-default on {missing} but Claude_Task_Plan.md never "
                f"names {'this column' if len(missing) == 1 else 'these columns'} anywhere "
                f"(required columns: {required}; why {table} is in scope: {why})"
            )

    for entry in procedure_wrapped:
        table = entry.get("table")
        procedure = (entry.get("procedure") or "").strip()
        why = (entry.get("why") or "").strip()
        if not table or not procedure or not why:
            errors.append(f"CHECK B: procedure_wrapped entry {entry!r} is missing table/procedure/why")
            continue
        if table in seen_tables:
            errors.append(f"CHECK B: {table!r} appears in both write_targets and procedure_wrapped")
        seen_tables.add(table)
        if resolve(table) is None:
            errors.append(f"CHECK B: procedure_wrapped table {table!r} has no CREATE TABLE in bigquery/*.sql")

    for entry in excluded_tables:
        table = entry.get("table")
        why = (entry.get("why") or "").strip()
        if not table or not why:
            errors.append(f"CHECK B: excluded_tables entry {entry!r} is missing table/why")
            continue
        if table in seen_tables:
            errors.append(f"CHECK B: {table!r} appears in excluded_tables as well as write_targets/procedure_wrapped")
        seen_tables.add(table)
        if resolve(table) is None:
            errors.append(f"CHECK B: excluded_tables table {table!r} has no CREATE TABLE in bigquery/*.sql")

    # Completeness: every events./ops. table with >=1 required column must be accounted for exactly
    # once above (write_targets, procedure_wrapped, or excluded_tables) -- an unrecognized table is
    # neither a pass nor a silent skip, it is a gap in this spec's own coverage.
    for (dataset, name), body in table_bodies.items():
        table = f"{dataset}.{name}"
        if table in seen_tables:
            continue
        if required_not_null_columns(body):
            errors.append(
                f"CHECK B: {table} has NOT NULL/no-default column(s) but is not listed in "
                f"write_targets, procedure_wrapped, or excluded_tables -- classify it "
                f"(ops/handoff_contracts.yaml)"
            )
    return checked



# ============================================================================================
# CHECK C -- row-mediated handoff discovery predicates
# ============================================================================================

SELECT_TOKEN = re.compile(r"\bSELECT\b", re.IGNORECASE)

# How far past a SELECT the table + discovery value must appear for the three to count as ONE
# query. Sized to a generous single statement: SL5 branch (3)'s pinned predicate is ~430 chars.
# Proximity, NOT fenced-block parsing: Claude_Task_Plan.md nests fences (each routine's whole
# instruction is itself a ``` block, and a pinned query is a ``` block INSIDE it), so a
# non-greedy fence regex closes on the inner opener and silently splits the query it is looking for.
QUERY_WINDOW_CHARS = 800


def has_discovery_query(body, table, discovery_value):
    """True iff some SELECT is followed, within QUERY_WINDOW_CHARS, by both the table and the
    discovery value as a literal. The table matches on its bare name (a real query writes it
    fully qualified: `stock-trading-498512.events.strategy_lifecycle`)."""
    bare = table.split(".")[-1]
    tbl = re.compile(r"\b" + re.escape(bare) + r"\b")
    v = re.escape(discovery_value)
    val = re.compile(rf"""(?:['"`]{v}['"`])|(?:=\s*['"`]?{v}\b)""")
    for m in SELECT_TOKEN.finditer(body):
        window = body[m.start():m.start() + QUERY_WINDOW_CHARS]
        if tbl.search(window) and val.search(window):
            return True
    return False


def check_c(spec, bodies, errors):
    entries = spec.get("row_handoffs") or []
    checked = 0
    for e in entries:
        table = e.get("table")
        value = e.get("discovery_value")
        consumer = e.get("consumer")
        producers = e.get("producers") or []
        pinned = e.get("pinned_columns") or []
        why = (e.get("why") or "").strip()
        if not (table and value and consumer and producers and pinned):
            errors.append(
                f"CHECK C: row_handoffs entry {e!r} is missing "
                f"table/discovery_value/consumer/producers/pinned_columns")
            continue
        if not why:
            errors.append(f"CHECK C: row_handoffs entry for {table!r} is missing a `why`")

        # C1 -- the consumer must hold a runnable discovery predicate, not a prose mention.
        cbody = bodies.get(consumer)
        if cbody is None:
            errors.append(
                f"CHECK C: consumer {consumer!r} for {table!r} is NOT a routine section in "
                f"Claude_Task_Plan.md")
        elif not has_discovery_query(cbody, table, value):
            errors.append(
                f"CHECK C: consumer {consumer!r} {e.get('consumer_branch') or ''} names {table!r} as an "
                f"input but its section has NO discovery query -- no SELECT is followed within "
                f"{QUERY_WINDOW_CHARS} chars by both {table.split('.')[-1]!r} and the {value!r} literal. "
                f"A prose mention is not a "
                f"predicate: pin the query verbatim so the implementing session cannot invent one.")

        # C2 -- every producer must pin the fields that predicate reads.
        for rid in producers:
            pbody = bodies.get(rid)
            if pbody is None:
                errors.append(
                    f"CHECK C: producer {rid!r} for {table!r} is NOT a routine section in "
                    f"Claude_Task_Plan.md")
                continue
            missing = [c for c in pinned if not re.search(r"\b" + re.escape(c) + r"\b", pbody)]
            if missing:
                errors.append(
                    f"CHECK C: producer {rid!r} writes {table!r} but its section never names "
                    f"{missing} -- the consumer {consumer!r} reads {pinned} off that row, so an "
                    f"unnamed field is left to the writing session to omit (a nullable column then "
                    f"lands NULL and silently breaks the consumer's key derivation).")
        checked += 1
    return checked


# ============================================================================================


def main():
    if not os.path.exists(SPEC_PATH):
        print(f"HANDOFF CONTRACTS: FAIL\n\n - spec file not found: {SPEC_PATH}")
        return 1
    spec = load_yaml(SPEC_PATH)
    if not spec:
        print(f"HANDOFF CONTRACTS: FAIL\n\n - {SPEC_PATH} is empty or failed to parse")
        return 1

    task_plan_text = read_text(TASK_PLAN_PATH)
    bodies = routine_bodies(task_plan_text)

    errors = []
    lanes_checked = check_a(spec, bodies, errors)
    tables_checked = check_b(spec, task_plan_text, errors)
    rows_checked = check_c(spec, bodies, errors)

    if errors:
        print("HANDOFF CONTRACTS: FAIL\n")
        for e in errors:
            print(" - " + e)
        return 1

    n_procedure_wrapped = len((spec.get("required_column_naming") or {}).get("procedure_wrapped") or [])
    n_excluded_queues = len(spec.get("excluded_queues") or [])
    print(
        f"HANDOFF CONTRACTS: OK -- CHECK A: {lanes_checked} queue lane(s) drain-close-verified "
        f"({n_excluded_queues} excluded with reason); CHECK B: {tables_checked} write-target "
        f"table(s) column-name-verified ({n_procedure_wrapped} procedure-wrapped exemptions); "
        f"CHECK C: {rows_checked} row-mediated handoff(s) discovery-predicate-verified."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

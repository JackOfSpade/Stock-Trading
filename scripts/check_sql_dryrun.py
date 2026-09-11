#!/usr/bin/env python3
"""Dry-run bigquery/*.sql via `bq query --dry_run` and FAIL CI on a SYNTAX (parse-class) error only.

WHY (2026-07-17 whole-system audit follow-up). The bigquery/*.sql DDL is applied to live BigQuery by
hand (MCP / console). Nothing in the pipeline parsed it before it went live — pytest, `dbt parse`, and
the prose checks never touch the raw hand-SQL — so a pure syntax error reached the apply step
undetected: `mode=''manual''` inside a single-quoted string (BigQuery escapes a quote with \\' , not '')
parsed as two adjacent string literals and aborted the whole script. This closes that gap.

NO DDL GRANT / NO OVER-PRIVILEGE. This runs with the EXISTING READ-ONLY WIF service account
(roles/bigquery.dataViewer + jobUser — the same one dbt-parity uses). BigQuery COMPILES a dry-run
(parse -> resolve) before it authorizes the DDL operation, so:
  * a SYNTAX-broken CREATE/PROCEDURE returns "Syntax error ..." at parse time regardless of whether the
    identity could perform the create  -> we BLOCK on it (an unambiguous, permission-independent bug);
  * a syntactically-VALID CREATE the read-only SA cannot perform returns "Access Denied ..."           -> TOLERATE;
  * a reference to an object not yet live (a new sibling created later in the same change) returns
    "Not found ..." / "Unrecognized name ..."                                                          -> TOLERATE;
  * a transient/infra error                                                                            -> TOLERATE (fail-open, like dbt-parity's skips).
So the gate blocks ONLY on a parse failure — it can never false-block on a permission/reference message.

SELF-CHECK CANARY — FAIL CLOSED. Before trusting a clean result, the script proves its own environment
can actually detect a syntax error: it dry-runs a known-BAD trivial SELECT ("SELECT 1 FROM") — a pure
parse error needing no DDL/table perms — and asserts it classifies as 'syntax'. If the canary does NOT
surface as a syntax error (bq/auth misconfigured, or a future BigQuery that authorizes before it
parses), a "clean" pass over the real files would be unverifiable — so the gate exits 1 instead of
reporting an OK it cannot stand behind (same discipline as dbt_parity's checked==0 guard and
check_live_sql_parity's fail-closed exits; 2026-07-18 audit — previously this only printed a
::warning:: and fell through, so a broken environment green-lit every merge).

KNOWN, VERIFIED LIMITATION — A LEADING DDL SUPPRESSES SEMANTIC ANALYSIS OF EVERYTHING AFTER IT
(2026-08-03). BigQuery's SCRIPT dry-run does not keep semantically analyzing a multi-statement script
past its first DDL statement. Reproduced directly against live BigQuery:
  * `SELECT 1 AS warmup; SELECT 'x' AS a WHERE NOT EXISTS (SELECT 1);` (no DDL at all) -> dry run
    ERRORS: "Query without FROM clause cannot have a WHERE clause" — correctly caught.
  * `CREATE TABLE IF NOT EXISTS <t> (a STRING); SELECT 'x' AS a WHERE NOT EXISTS (SELECT 1);` — the
    SAME illegal statement, now preceded by a leading CREATE — dry-runs CLEAN.
  * A 4-statement script hiding an unknown column, a no-FROM WHERE, AND an undefined function, all
    after a leading DDL, ALSO dry-ran CLEAN.
  * Pure PARSE/lexer errors (e.g. this file's own mode=''manual'' concatenated-string-literal bug) ARE
    still caught even after a DDL, because the ENTIRE script is parsed before any statement executes —
    only semantic RESOLUTION stops early.
Consequence: bigquery/133_sl1_research_leads_and_record_corrections.sql's two idempotency guards were
written as `INSERT INTO t (cols) SELECT <bare literals> WHERE NOT EXISTS (...)` — illegal in GoogleSQL
("Query without FROM clause cannot have a WHERE clause") — and this gate reported the file as "0 SYNTAX
ERRORS" anyway, because the file's own leading `CREATE TABLE IF NOT EXISTS` suppressed analysis of
every statement after it. The real apply failed partway through and left a partially-applied, empty
table live. A per-statement splitter is NOT the fix FOR THIS CLASS: 37 bigquery/*.sql files contain
`BEGIN`, 36 contain `CREATE OR REPLACE PROCEDURE`, and 29 contain `DECLARE`, so a general splitter is
fragile against this repo's actual SQL shapes — and it would not even have caught THIS bug, because the
INSERT targeted a table that did not exist yet, which returns "Not found ..." -> already TOLERATED by
design, splitter or not. That reasoning is UNCHANGED and still holds for the no-FROM-WHERE class: this
module still fixes it with `no_from_where_violations()` below, a small, credential-free STATIC lint for
this exact illegal shape, run BEFORE any `bq` call — so it still protects when the dry-run job is
skipped, `bq` is unavailable, or a leading DDL blinds the dry-run to everything after it. It is
deliberately narrow (this one illegal shape only), not a general semantic-analysis replacement, which
is why a clean dry-run result for a file containing a DDL statement is reported below as
"parse-validated" (proves the script PARSES) rather than "validated" (would wrongly imply it will
apply), with an explicit caveat line printed for any run that includes such a file.

WIDENED 2026-08-08 — THE SAME SHAPE INSIDE A `CREATE VIEW` / UNION ARM ALSO ESCAPED IT. The lint
originally keyed off `INSERT INTO ... SELECT` only, because that idempotency-guard idiom was the one
observed bug. bigquery/151_connector_tool_inventory.sql then hit a SIBLING instance the narrower lint
could not see at all: a `CREATE OR REPLACE VIEW ... AS ... UNION ALL SELECT <literals> WHERE NOT EXISTS
(...)` whose second UNION ALL arm had the identical illegal shape — no `INSERT INTO` anywhere in the
statement, so `_INSERT_INTO_RE` never matched and the lint reported zero violations while BigQuery
rejected the file at apply time with the exact "Query without FROM clause cannot have a WHERE clause"
error. `no_from_where_violations()` now scans from EVERY top-level `SELECT` keyword in the masked text
— not just ones following `INSERT INTO` — so it catches this shape in a bare statement, a
`CREATE VIEW`/`CREATE TABLE ... AS` body, any `UNION`/`UNION ALL`/`INTERSECT`/`EXCEPT` arm at any
nesting level, and the original `INSERT INTO ... SELECT` case, all through one code path (see
`_scan_select_clause`'s docstring for how each SELECT's own clause boundary is determined).

PER-STATEMENT PASS FOR A DIFFERENT CLASS, OPT-IN ONLY, BECAUSE CI CANNOT USE IT (2026-09-11,
bigquery/234_staged_order_notice_resolve_decorrelated.sql's landing incident — see that file's header
for the full account). bigquery/233_staged_order_window_dead_on_arrival.sql landed a
`CREATE VIEW ...; CREATE PROCEDURE ...` script whose PROCEDURE body contained a CORRELATED
`NOT EXISTS` against a VIEW that itself contains a LEFT JOIN — an unambiguous ANALYSIS rejection
("Correlated subqueries that reference other tables are not supported unless they can be
de-correlated, such as by transforming them into an efficient JOIN"), deterministic and
data-independent (it failed on an EMPTY view — it never depended on any row existing).

FIRST-ORDER VS SECOND-ORDER REASON THIS REACHED LIVE, and why that distinction changes the fix. The
KNOWN, VERIFIED LIMITATION above (a leading DDL suppresses semantic analysis of everything after it)
is only the SECOND-order reason 233 passed CI green — it explains why, IF the CI identity could
otherwise have reached semantic analysis of the CREATE PROCEDURE, the leading CREATE VIEW would have
blinded it. But the FIRST-order reason is simpler and was verified directly against the ACTUAL CI run
that landed 233 (`gh run view 34508595794 --log`, ci.yml, the dbt-parity/SQL-syntax job, keyless WIF),
verbatim:
    SQL dry-run: 4 file(s) — 0 parse-validated, 4 tolerated (permission/reference), 0 inconclusive,
    0 SYNTAX ERROR(S).
      - tolerated (...): bigquery/229_staged_order_confirm_notice.sql
      - tolerated (...): bigquery/233_staged_order_window_dead_on_arrival.sql
      - tolerated (...): bigquery/63_scheduled_query_version_registry.sql
      - tolerated (...): bigquery/75_scheduled_query_wrappers.sql
ZERO parse-validated, FOUR tolerated — EVERY DDL-bearing file that push touched, not just 233. The
keyless WIF SA (roles/bigquery.dataViewer + jobUser, see the NO DDL GRANT section above) gets
"Access Denied" on the CREATE itself before BigQuery ever reaches body validation, so `classify()`
returns "tolerated" regardless of statement position, leading DDL or none. This means: IN CI, this
gate's dry-run is PARSE-CLASS ONLY, full stop — it can catch a syntax error (parsing happens before
authorization, see the NO DDL GRANT section) but can NEVER catch a semantic/analysis-class defect,
because it never gets far enough to be denied selectively; splitting the script into per-statement
pieces would not have changed this outcome even one bit, since EVERY one of those pieces is still a
CREATE the SA cannot perform. Granting the CI SA create/alter permission is not on the table (IAM
grants are owner-only in this repo, and the read-only CI posture is deliberate) — so semantic
validation of a CREATE structurally REQUIRES a privileged identity, which CI structurally does not
have. `--per-statement` (below) is built for that privileged-identity case, not for CI.

Measured, LOCALLY, under the project OWNER's own privileged `bq` credentials (2026-09-11, NOT the CI
SA — this is the identity difference the paragraph above exists to name):
  * `CREATE PROCEDURE <bad body>` alone -> dry run FAILS: "Error validating procedure body (add
    OPTIONS(strict_mode=false) to suppress): Query error: Query error: Correlated subqueries that
    reference other tables are not supported unless they can be de-correlated, such as by
    transforming them into an efficient JOIN. at [3:3]"
  * `CREATE VIEW ...; CREATE PROCEDURE <same bad body>` as a script -> dry run CLEAN (the KNOWN,
    VERIFIED LIMITATION above, now confirmed to matter only once an identity is actually privileged
    enough to reach semantic analysis at all).
So a CREATE PROCEDURE's body IS validated in strict_mode the instant a privileged identity dry-runs it
ALONE — isolating it produces a decisive answer whenever the caller can actually perform the create.
`per_statement_dryrun_targets()` below adds exactly that, GATED BEHIND THE `--per-statement` FLAG
(OFF BY DEFAULT): for each file, every top-level CREATE statement AFTER the first (the first is
already covered by the whole-file pass) is dry-run on its own — but ONLY when it is ALSO the
apply-in-order FINAL definition of its object per `check_live_sql_parity.find_final_definitions()`.
That scoping is CORRECTNESS, not an optimisation: this repo's supersede-only discipline
(bigquery/README.md's "Supersede discipline" section) keeps a superseded object's CREATE statement in
its original file FOREVER, unmodified, as the DR-rebuild apply-in-order record — bigquery/233 still
contains the broken procedure body today, on purpose, and bigquery/234 now supersedes it. Dry-running
233's copy individually would fail forever on landed, deliberately-frozen history, turning this gate
permanently red. See `classify()`'s new "analysis" kind (ANALYSIS_MARKERS) for how a result from
either pass — whole-file OR per-statement — gets to BLOCK, and `main()` for how `--per-statement` is
wired in as an explicit, off-by-default opt-in that never runs in CI or the scheduled sweep (neither
workflow passes it, so both see byte-identical behavior and cost to before this change) and is meant
to be run manually, by a privileged identity, before applying a multi-CREATE file live — exactly the
gap `scripts/apply_sql_file.py`'s own ">1 top-level CREATE" refusal message now names (see that
script's `check_canonical_provenance()`).

Usage:  python scripts/check_sql_dryrun.py <file.sql> [<file.sql> ...]
        python scripts/check_sql_dryrun.py --per-statement <file.sql> [<file.sql> ...]   # opt-in;
            see PER-STATEMENT PASS above — only useful run by a PRIVILEGED identity (never in CI)
Requires the `bq` CLI authed (WIF in CI; local gcloud otherwise). Exit 0 = no syntax errors, no
analysis-class errors, and no static-lint violations (or nothing to check); exit 1 = at least one file
has a syntax error, an analysis-class error (only reachable in practice under a privileged identity —
see above), a no-FROM-WHERE static-lint violation, or the canary self-check failed.
"""
import os
import re
import subprocess
import sys

# Reused, not reimplemented (see module docstring's PER-STATEMENT PASS section) — the same repo-side
# parsing machinery scripts/apply_sql_file.py already imports from this module for its own canonical-
# provenance gate, an established, tested import direction (both are pure-text functions over files
# already on disk; neither needs a BigQuery client).
from check_live_sql_parity import (
    CREATE_STMT,
    NEXT_TOP_LEVEL,
    canonicalize,
    extract_body,
    find_final_definitions,
    find_procedure_body_end,
    sql_tokens,
)
from lib.sql_files import _string_literal_end, normalize_kind, strip_sql_comments

PROJECT = "stock-trading-498512"

# BigQuery parse-class markers — an unambiguous syntax bug (block). Lower-cased substring match.
SYNTAX_MARKERS = (
    "syntax error",
    "concatenated string literals",     # the exact 2026-07-17 bug wording
    "expected keyword",
    "expected end of input",
    "unexpected keyword",
    "illegal input character",
    "unclosed",
    "invalid escape sequence",
)
# Permission / reference markers — expected for a read-only SA dry-running DDL, or an intra-change
# dependency (a new object created later in the same push) not yet live. Tolerate (non-blocking).
TOLERATE_MARKERS = (
    "access denied",
    "permission",
    "does not have",
    "user does not have",
    "not found",
    "unrecognized name",
    "already exists",
    "billing",
)
# ANALYSIS-class marker (2026-09-11, bigquery/234's landing incident — see module docstring's
# PER-STATEMENT PASS section) — an unambiguous, permission- and reference-INDEPENDENT semantic
# rejection: BigQuery refusing a correlated subquery it cannot rewrite into a join. Deliberately a
# single, narrow, VERBATIM marker (BigQuery's own wording, observed live) rather than a broader
# "correlated subqueries" substring, so this can never accidentally swallow a message this gate
# should keep tolerating. Checked AFTER TOLERATE_MARKERS in classify() — never before — because a
# CREATE PROCEDURE dry-run wraps its inner failure as "Error validating procedure body (...): Query
# error: <inner>", and for a brand-new sibling object not yet live the inner error is a completely
# ordinary "Not found: Table ..." that must stay TOLERATED exactly as it already is for the
# whole-file pass; this marker only ever matches the one specific de-correlation rejection, which
# TOLERATE_MARKERS' substrings never do, so the ordering is belt-and-suspenders rather than
# load-bearing today — but it is the CORRECT order to state, since a future, broader ANALYSIS
# marker could otherwise start shadowing a legitimate permission/reference tolerate case.
ANALYSIS_MARKERS = (
    "correlated subqueries that reference other tables",
)


def classify(exit_code, output):
    """'ok' | 'syntax' (BLOCK) | 'tolerated' (perm/ref) | 'analysis' (BLOCK) | 'unknown' (transient,
    non-blocking). Order is load-bearing: SYNTAX -> TOLERATE -> ANALYSIS -> unknown — see
    ANALYSIS_MARKERS' own comment for why TOLERATE must be checked first.

    WHITESPACE-COLLAPSED BEFORE MATCHING (2026-09-11, live probe during the ANALYSIS_MARKERS
    addition). The `bq` CLI hard-wraps a long error message across multiple lines at some column
    width even when stdout is not a real terminal — reproduced live: the exact de-correlation error
    came back as "...Query error: Correlated\\nsubqueries that reference other tables are not
    supported...", splitting the multi-word ANALYSIS_MARKERS phrase across a newline and defeating a
    naive substring match on the raw text. SYNTAX_MARKERS/TOLERATE_MARKERS happened to survive this
    unnoticed only because every existing marker there is short enough (1-2 words) that this repo's
    observed wrap points had not yet split one — this fix protects all three marker tuples the same
    way, not just the new one, rather than leaving that as a latent, width-dependent flake."""
    if exit_code == 0:
        return "ok"
    low = re.sub(r"\s+", " ", output or "").lower()
    if any(m in low for m in SYNTAX_MARKERS):
        return "syntax"
    if any(m in low for m in TOLERATE_MARKERS):
        return "tolerated"
    if any(m in low for m in ANALYSIS_MARKERS):
        return "analysis"
    return "unknown"


def _bq_dry_run(sql_text=None, sql_path=None):
    """Run `bq query --dry_run` from a string or a file; return (exit_code, combined_output)."""
    cmd = ["bq", "--project_id=" + PROJECT, "--quiet", "--headless",
           "query", "--use_legacy_sql=false", "--dry_run"]
    try:
        if sql_path is not None:
            with open(sql_path, encoding="utf-8") as fh:
                p = subprocess.run(cmd, stdin=fh, capture_output=True, text=True, timeout=180)
        else:
            p = subprocess.run(cmd, input=sql_text, capture_output=True, text=True, timeout=180)
    except Exception as e:  # noqa: BLE001 — a harness/timeout error is non-blocking (tolerated)
        return 1, f"harness-error: {e}"
    return p.returncode, (p.stderr or p.stdout or "").strip()


def canary_ok():
    """True if the environment can detect a syntax error on a trivial, permission-free SELECT."""
    rc, out = _bq_dry_run(sql_text="SELECT 1 FROM")   # pure parse error, no tables/DDL involved
    return classify(rc, out) == "syntax"


def is_template(path):
    """True for a fill-in-the-blanks TEMPLATE file, which is UNPARSEABLE BY DESIGN.

    bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql is the live example: its header states
    "TEMPLATE, NOT auto-applied ... BEFORE running: fill in the 5 placeholders below", and it carries
    literal <TRANSFER_DATE> / <SGOV_SELL_SHARES> markers the operator substitutes before the one-time
    manual run. BigQuery rejects it with `Syntax error: Unexpected "<"` — correctly, because a template
    is not valid SQL until filled in. Blocking CI on that is a FALSE POSITIVE, and a latent landmine: it
    stays invisible until someone edits the file (even a comment), at which point the path-gated CI step
    picks it up and reds the build on a file that is correct by design. Found 2026-07-18 by the first
    full-repo sweep (82 files: 81 clean, this the only "error").

    Detected by the `_TEMPLATE.sql` filename convention rather than by scanning for <PLACEHOLDER>
    markers on purpose: BigQuery's own type syntax (ARRAY<STRING>, STRUCT<a INT64>) matches any
    reasonable placeholder regex, so a marker-based rule would silently skip real files. The filename is
    an explicit, greppable opt-out, and skips are PRINTED (never silent) so a template cannot hide
    breakage.
    """
    return os.path.basename(path).upper().endswith("_TEMPLATE.SQL")


# ==== PER-STATEMENT PASS: statements the whole-file pass structurally cannot analyse ================
#
# See the module docstring's PER-STATEMENT PASS section for WHY this exists and why it does not
# contradict the 2026-08-03 "a per-statement splitter is NOT the fix" argument made about the
# no-FROM-WHERE class. Short version: a CREATE PROCEDURE dry-run VALIDATES ITS OWN BODY in
# strict_mode the instant it is submitted alone, so isolating a SECOND-or-later top-level CREATE
# statement (the ones a leading DDL earlier in the same script blinds the whole-file pass to)
# produces a decisive, permission-independent answer for exactly the class documented there.


def _extract_statement_text(txt, m, obj_type):
    """The complete, standalone text (header through its TRUE end, always terminated with a literal
    ';') of the top-level CREATE statement whose check_live_sql_parity.CREATE_STMT match is `m` in
    file text `txt` — what per_statement_dryrun_targets() submits to `bq query --dry_run` alone.

    Mirrors check_live_sql_parity.extract_body()'s own boundary-finding exactly (same NEXT_TOP_LEVEL
    boundary; same find_procedure_body_end() nesting-aware scan for a PROCEDURE — see that function's
    docstring for why naive BEGIN/END counting is wrong) but KEEPS the CREATE header extract_body()
    strips off: a standalone dry-run needs a complete, self-contained statement, where extract_body()
    only ever needed the body half for a text comparison against a live INFORMATION_SCHEMA definition.

    For a PROCEDURE, the end is find_procedure_body_end()'s matching END — deliberately NOT the wider
    NEXT_TOP_LEVEL boundary, which can include a trailing, unrelated free-standing BEGIN...END block
    appended after the procedure's own END in the same file (the exact bigquery/146 shape
    find_procedure_body_end()'s docstring describes): submitting that trailing block along with this
    CREATE would dry-run something this statement never claimed to contain. Falls back to the wider
    NEXT_TOP_LEVEL-bounded text only if no BEGIN, or no matching END, can be found at all — "should
    never happen against well-formed DDL", extract_body()'s own words for the identical fallback.

    For a VIEW / TABLE FUNCTION / scalar FUNCTION there is no inner BEGIN...END to bound more tightly
    than NEXT_TOP_LEVEL's own boundary (the next top-level CREATE/DML/DDL keyword, or EOF).
    """
    start = m.start()
    next_m = NEXT_TOP_LEVEL.search(txt, start + 1)
    end = next_m.start() if next_m else len(txt)
    stmt = txt[start:end]
    if obj_type == "PROCEDURE":
        begin_at = next(
            (tstart for kind, val, tstart, _tend in sql_tokens(stmt)
             if kind == "T" and val.upper() == "BEGIN"),
            None)
        if begin_at is not None:
            end_m = find_procedure_body_end(stmt, begin_at)
            if end_m is not None:
                stmt = stmt[:end_m]
    stmt = stmt.rstrip()
    if not stmt.endswith(";"):
        stmt += ";"
    return stmt


def _is_final_create(path, txt, m, obj_type, dataset, name, final):
    """True iff the CREATE_STMT match `m` in file `path` is the apply-in-order FINAL definition of
    `(dataset, name)`, per check_live_sql_parity.find_final_definitions()'s own resolution — the same
    question that script asks to decide what live BigQuery currently should hold.

    THIS IS A CORRECTNESS GATE, NOT AN OPTIMISATION (module docstring's PER-STATEMENT PASS section).
    bigquery/*.sql's supersede-only discipline (bigquery/README.md "Supersede discipline") keeps a
    superseded object's CREATE statement live in its original file FOREVER, unmodified, as the
    DR-rebuild apply-in-order record. bigquery/233_staged_order_window_dead_on_arrival.sql is the
    concrete case this closes: it still contains the broken ops.sp_sq_daily_staging_cap_check body,
    on purpose, and bigquery/234_staged_order_notice_resolve_decorrelated.sql now supersedes it.
    Dry-running 233's copy individually would fail FOREVER on landed, deliberately-frozen history —
    turning this gate permanently red on a file nobody is going to (or should) touch again.

    Checking (dataset, name) membership in `final` alone is not enough — it would still fire on a
    superseded occurrence that merely shares its object's name with the real final one — so this also
    requires the SOURCE FILE to match (ruling out 233 once 234 exists) and the extracted body to
    canonicalize identically to find_final_definitions()'s own stored body (ruling out an EARLIER,
    superseded occurrence of the same object inside the SAME file, and confirming this really is the
    occurrence that walk selected, not merely one sharing its filename)."""
    entry = final.get((dataset, name))
    if entry is None:
        return False
    entry_obj_type, _entry_project, entry_source_file, entry_body = entry
    if entry_obj_type != obj_type or entry_source_file != os.path.basename(path):
        return False
    body = extract_body(txt, m.start(), obj_type)
    if body is None:
        return False
    return canonicalize(body) == canonicalize(entry_body)


def per_statement_dryrun_targets(path, txt, final):
    """[(dataset, name, obj_type, statement_text), ...] for every SUBSEQUENT top-level CREATE
    statement in `txt` (skipping the FIRST — the whole-file pass in main() already semantically
    analyses it; see the module docstring's PER-STATEMENT PASS section) that is ALSO the apply-in-
    order FINAL definition of its object (_is_final_create()).

    A superseded occurrence, a free-standing DML/DDL statement (CREATE_STMT only ever matches
    CREATE OR REPLACE VIEW/PROCEDURE/TABLE FUNCTION/FUNCTION — a MERGE/INSERT/UPDATE/DROP is never
    returned here, by construction, the same "skip non-CREATE statements" scoping check_live_sql_
    parity.py's own comparison already applies), or a statement for an object no bigquery/*.sql
    file's final state defines, is never returned: dry-running any of those individually would either
    be meaningless (superseded, deliberately-frozen history) or is legitimately out of this pass's
    scope (a free-standing DML/DDL statement can depend on live data state in a way a credential-free,
    per-statement re-submission cannot honestly evaluate any better than the whole-file pass already
    does — noise, not signal)."""
    matches = list(CREATE_STMT.finditer(txt))
    targets = []
    for m in matches[1:]:
        kind, _project, dataset, name = m.groups()
        obj_type = normalize_kind(kind)
        if not _is_final_create(path, txt, m, obj_type, dataset, name, final):
            continue
        targets.append((dataset, name, obj_type, _extract_statement_text(txt, m, obj_type)))
    return targets


# ==== STATIC, CREDENTIAL-FREE LINT: a SELECT expression-list reaching WHERE with no FROM ============
#
# Closes the blind spot documented in the module docstring's KNOWN, VERIFIED LIMITATION section: a
# leading DDL statement in a bigquery/*.sql script suppresses BigQuery's OWN script-dry-run semantic
# analysis of everything after it, so this exact illegal shape (an idempotency-guard idiom used
# throughout bigquery/*.sql — originally seen under `INSERT INTO ... SELECT`, and 2026-08-08 also
# under a `CREATE VIEW`'s `UNION ALL` arm) can reach live apply undetected by `bq query --dry_run`
# alone. This check needs no `bq`, no credentials, and no network — it is pure text analysis — so it
# runs first and can still protect a push even when the dry-run job itself is skipped or `bq` is
# unavailable. It scans from every top-level `SELECT` keyword rather than keying off `INSERT INTO`, so
# it catches the shape wherever a SELECT's own clause can appear: a bare statement, an
# `INSERT INTO ... SELECT`, a `CREATE VIEW`/`CREATE TABLE ... AS` body, a CTE, or any
# `UNION`/`UNION ALL`/`INTERSECT`/`EXCEPT` arm at any nesting level.

_DDL_KEYWORD_RE = re.compile(r"\b(CREATE|ALTER|DROP)\b", re.IGNORECASE)
_SELECT_KEYWORD_RE = re.compile(r"\bSELECT\b", re.IGNORECASE)
_FROM_KEYWORD_RE = re.compile(r"\bFROM\b", re.IGNORECASE)
_WHERE_KEYWORD_RE = re.compile(r"\bWHERE\b", re.IGNORECASE)
_SET_OP_KEYWORD_RE = re.compile(r"\b(?:UNION|INTERSECT|EXCEPT)\b", re.IGNORECASE)


def _blank_string_literals(text):
    """Blank the CONTENTS (and, for string literals, the delimiters too) of every quoted region in
    `text` with spaces, preserving every newline and the overall length — the same length/newline-
    preserving contract as `lib.sql_files.strip_sql_comments` (whose literal SPAN is found by the
    exact same shared `_string_literal_end` helper this function calls below — see that helper's
    docstring for why the walk lives in one place instead of two), so a position or line number
    computed against the result still lands correctly against the ORIGINAL text.

    Handles BOTH string literals ('...', "...", triple-quoted) AND backtick-quoted identifiers
    (`` `p.d.t` ``). Backticks are load-bearing here, not just for completeness: GoogleSQL has no
    backtick-escape mechanism at all — an identifier simply ends at the NEXT backtick — so an
    apostrophe, double-quote, or `;` inside one is NOT a real string-literal delimiter or statement
    terminator, but leaving backticks untracked lets its contents masquerade as one. Two concrete,
    reproduced failure modes this closes:
      * FALSE POSITIVE — `` SELECT `o'clock` AS a FROM src WHERE ... `` : the apostrophe inside the
        backtick identifier used to open a fake string literal that swallowed the real top-level FROM,
        wrongly flagging legal SQL.
      * FALSE NEGATIVE — `` SELECT 'x' AS `c;d` WHERE NOT EXISTS (SELECT 1) `` : the `;` inside the
        backtick identifier used to be read as a top-level statement terminator, stopping the scan
        before it ever reached the real (illegal, no-FROM) WHERE.
    A backtick identifier's CONTENTS are blanked like a string literal's, but its two backtick
    DELIMITERS are left in place (not blanked to space) rather than consumed into the blanked region —
    an arbitrary choice since nothing downstream matches on a bare backtick, kept only to make the
    masked text stay visually recognizable as "an identifier sat here" when eyeballed.

    Meant to be applied to the OUTPUT of `strip_sql_comments` (comments already blanked), giving text
    where neither a doc comment nor a quoted string's prose can accidentally satisfy a keyword regex —
    this repo's decision notes and descriptions routinely contain the plain English words "from" and
    "where" (e.g. bigquery/133's own correction prose), and BigQuery identifiers/notes routinely
    contain literal parentheses (e.g. "REJECTED ... on rail (a)") that would otherwise corrupt a
    naive paren-depth count.
    """
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "`":
            j = i + 1
            while j < n and text[j] not in ("`", "\n"):
                j += 1
            if j < n and text[j] == "`":
                # Well-formed identifier: blank the interior, keep both backticks in place so the
                # region's own length and every newline inside it are unchanged.
                out.append("`")
                out.append("".join(ch if ch == "\n" else " " for ch in text[i + 1:j]))
                out.append("`")
                i = j + 1
            else:
                # No closing backtick before end-of-line/text: not a well-formed identifier region —
                # leave this single backtick as ordinary text (mirrors the unterminated single-line
                # string literal handling just below: stop rather than over-consume).
                out.append(c)
                i += 1
            continue
        if c in ("'", '"'):
            j = _string_literal_end(text, i)
            out.append("".join(ch if ch == "\n" else " " for ch in text[i:j]))
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _masked_sql(sql_text):
    """`sql_text` with comments AND the contents of every string literal and backtick-quoted
    identifier blanked to spaces — same length/newline contract as the original, so any position
    found in this text is directly usable against `sql_text` itself (for excerpts) or for computing
    an exact original-file line number."""
    return _blank_string_literals(strip_sql_comments(sql_text))


def _scan_select_clause(masked, start):
    """From `start` (just past ONE `SELECT` keyword match in `masked`), scan forward tracking paren
    depth from 0 — relative to THIS select's own clause, not the file — and return one of:
      ("ok", None)             — this SELECT's own clause reaches a top-level FROM before any
          top-level WHERE, or leaves its own clause (a set operator, a statement-terminating ';', or
          the closing paren of whatever contains it) before ever reaching a WHERE at all — not the
          illegal shape (this also covers a bare `SELECT 1` / `SELECT <literals>` with neither FROM
          nor WHERE, and an `INSERT ... VALUES` statement, which never matches this function at all
          because it has no SELECT keyword to start a scan from).
      ("violation", where_pos) — this SELECT's own clause reaches a top-level WHERE before any
          top-level FROM — the exact illegal shape ("Query without FROM clause cannot have a WHERE
          clause").
    "This SELECT's own clause" / "top-level" means depth 0 relative to THIS scan's own start, and the
    scan stops the instant it would leave that clause:
      * a `(` bumps depth; a `)` while depth is already 0 means we have reached the closing paren of
        whatever GROUP CONTAINS this SELECT (a subquery, a CTE, a `CREATE VIEW`/`CREATE TABLE ... AS`
        body) — that paren is not this clause's own, so the scan stops (ok) rather than going negative;
      * a top-level UNION/UNION ALL/UNION DISTINCT/INTERSECT/EXCEPT ends THIS arm's clause — whatever
        follows belongs to the NEXT set-operation arm, which gets its own independent scan because it
        starts with its own SELECT keyword (the caller iterates every SELECT match in the file, not
        just the first);
      * a top-level ';' ends the statement.
    Every SELECT keyword in the file is scanned independently, each with its own depth-0 baseline, so
    one SELECT's scan can never mistake ANOTHER select's FROM/WHERE for its own: a nested
    `WHERE NOT EXISTS (SELECT 1 FROM t WHERE ...)` guard's inner FROM/WHERE sit one level deeper inside
    the OUTER scan (because entering the guard's own '(' bumps that scan's depth to 1 first) and are
    resolved instead by the INNER SELECT's own, separately-triggered scan; a CTE's inner
    `SELECT ... FROM ...` is likewise sealed inside its own parens; and a UNION/INTERSECT/EXCEPT arm's
    WHERE can never be "satisfied" by a FROM belonging to a sibling arm, because the set-operator
    boundary stops each arm's scan before it can see past it.
    """
    depth = 0
    pos = start
    n = len(masked)
    while pos < n:
        ch = masked[pos]
        if ch == "(":
            depth += 1
            pos += 1
            continue
        if ch == ")":
            if depth == 0:
                return "ok", None
            depth -= 1
            pos += 1
            continue
        if depth == 0:
            if ch == ";":
                return "ok", None
            if _FROM_KEYWORD_RE.match(masked, pos):
                return "ok", None
            if _WHERE_KEYWORD_RE.match(masked, pos):
                return "violation", pos
            if _SET_OP_KEYWORD_RE.match(masked, pos):
                return "ok", None
        pos += 1
    return "ok", None


def _excerpt(original_text, start_pos, end_pos, max_len=180):
    """Whitespace-collapsed snippet of `original_text[start_pos:end_pos]`, trimmed to at most
    `max_len` characters keeping the TAIL (closest to the reported problem) when longer."""
    snippet = re.sub(r"\s+", " ", original_text[start_pos:end_pos]).strip()
    if len(snippet) > max_len:
        snippet = "..." + snippet[-(max_len - 3):]
    return snippet


def no_from_where_violations(sql_text):
    """Return a list of (line_number, excerpt) for a SELECT expression-list that carries a WHERE with
    no FROM clause — illegal in GoogleSQL ("Query without FROM clause cannot have a WHERE clause")
    and, per this module's KNOWN, VERIFIED LIMITATION, invisible to `bq query --dry_run` whenever it
    follows a DDL statement earlier in the same script. Catches the shape WHEREVER a SELECT's own
    clause can appear — a bare statement, an `INSERT INTO ... SELECT`, a `CREATE VIEW`/
    `CREATE TABLE ... AS` body, a CTE, or a `UNION`/`UNION ALL`/`INTERSECT`/`EXCEPT` arm at any
    nesting level (the 2026-08-08 bigquery/151 case: a `CREATE OR REPLACE VIEW ... AS ... UNION ALL
    SELECT <literals> WHERE NOT EXISTS (...)` arm with no `INSERT INTO` anywhere in the statement).

    Operates on a comment-, string-literal-, AND backtick-identifier-blanked copy of `sql_text` (see
    `_masked_sql` / `_blank_string_literals`, built on `lib.sql_files.strip_sql_comments`) so a
    keyword match can never land inside a `-- FROM ...` doc comment, inside the English prose of a
    quoted decision note or description, or inside a backtick-quoted identifier that happens to
    contain a `'`, `"`, or `;` (e.g. `` `o'clock` ``, `` `c;d` ``). Both blanking passes preserve every
    character's position and every newline, so `line_number` is computed EXACTLY against the masked
    text and is correct for the ORIGINAL file — not a best-effort estimate.

    For every top-level `SELECT` keyword found in the masked text (an `INSERT ... VALUES` statement
    has none at all, so it never matches and is implicitly skipped), `_scan_select_clause` walks
    forward from just past that SELECT tracking paren depth from 0 — relative to THAT select's own
    clause — and flags a violation only when ITS OWN top-level `WHERE` is reached before its own
    top-level `FROM`. Because every SELECT gets its own independent, self-contained scan: a nested
    `WHERE NOT EXISTS (SELECT 1 FROM t WHERE ...)` guard's inner FROM/WHERE sit one paren level deeper
    inside the OUTER scan and are instead resolved by the INNER SELECT's own scan; a CTE's inner
    `SELECT ... FROM ...` is sealed inside its own parens the same way; and a set-operation arm's own
    WHERE can never be masked by (or mistakenly blamed on) a sibling arm's FROM, because a top-level
    UNION/INTERSECT/EXCEPT ends the current arm's scan before it can see past the boundary.
    """
    masked = _masked_sql(sql_text)
    violations = []
    for m in _SELECT_KEYWORD_RE.finditer(masked):
        kind, where_pos = _scan_select_clause(masked, m.end())
        if kind != "violation":
            continue
        line_number = masked.count("\n", 0, where_pos) + 1
        excerpt = _excerpt(sql_text, m.start(), min(where_pos + 60, len(sql_text)))
        violations.append((line_number, excerpt))
    return violations


def _contains_ddl(sql_text):
    """True if `sql_text` contains a real (non-comment, non-literal) CREATE/ALTER/DROP keyword —
    used only for the summary-line caveat (Change 2), not for the blocking lint above."""
    return bool(_DDL_KEYWORD_RE.search(_masked_sql(sql_text)))


def main(argv):
    # --per-statement is OFF BY DEFAULT (2026-09-11 re-scope — see module docstring's PER-STATEMENT
    # PASS section for why): it adds real `bq` dry-run cost and is only load-bearing when run by a
    # PRIVILEGED identity (a local operator/agent session with actual create/alter permission on the
    # target datasets), never in CI (the keyless WIF SA is read-only and TOLERATEs every CREATE
    # outright — see that section for the measured CI run proving this). Passing it here changes
    # nothing about ci.yml or sql-dryrun-sweep.yml, which never pass it and so see byte-identical
    # behavior and cost to before this change.
    per_statement = "--per-statement" in argv[1:]
    files = [a for a in argv[1:] if not a.startswith("-")]
    templates = [f for f in files if is_template(f)]
    files = [f for f in files if not is_template(f)]
    for f in templates:
        print(f"  - skipped (fill-in-the-blanks TEMPLATE — unparseable until placeholders are "
              f"substituted; not part of the apply-in-order sequence): {f}")
    if not files:
        print("check_sql_dryrun: no bigquery/*.sql files to validate — nothing to do.")
        return 0

    # ---- STATIC LINT (no credentials, runs BEFORE any `bq` call) --------------------------------
    # A file that can't be read is left out of `file_texts` (and so out of the lint and the DDL
    # caveat below) rather than crashing main() outright — the same fail-soft treatment
    # `_bq_dry_run` already gives an unreadable path (its own `open()` is wrapped, degrading to a
    # non-blocking "harness-error" -> inconclusive), so a bad path degrades consistently either way.
    file_texts = {}
    for f in files:
        try:
            with open(f, encoding="utf-8") as fh:
                file_texts[f] = fh.read()
        except OSError as e:
            print(f"  - static lint skipped (could not read file): {f} :: {e}")

    lint_violations = [(f, ln, ex) for f in files if f in file_texts
                        for ln, ex in no_from_where_violations(file_texts[f])]
    if lint_violations:
        print("::error::check_sql_dryrun STATIC LINT — found a SELECT expression-list reaching WHERE "
              "with NO FROM clause. THE RULE: GoogleSQL rejects a SELECT expression-list that carries a "
              "WHERE with no FROM (\"Query without FROM clause cannot have a WHERE clause\") — this is "
              "the exact idempotency-guard idiom used throughout bigquery/*.sql, just missing its FROM. "
              "It can appear in a bare statement, an INSERT INTO ... SELECT, a CREATE VIEW/CREATE "
              "TABLE ... AS body, or a UNION/UNION ALL/INTERSECT/EXCEPT arm at any nesting level. "
              "WHY A DRY-RUN CANNOT CATCH THIS: BigQuery's script dry-run stops semantically analyzing "
              "a script after its first DDL statement (verified 2026-08-03 — see this module's "
              "docstring), so a file with a leading CREATE/ALTER/DROP can dry-run CLEAN while a later "
              "statement like this one would fail at real apply time. THE FIX: add `FROM (SELECT 1)` "
              "(or `FROM UNNEST([1])`) between the SELECT's literal list and its WHERE, matching the "
              "correct form already used elsewhere in bigquery/*.sql (e.g. "
              "`SELECT ... FROM (SELECT 1) WHERE NOT EXISTS (...)`).")
        for f, line_number, excerpt in lint_violations:
            print(f"  ✗ NO-FROM-WHERE (blocks merge): {f}:{line_number} :: {excerpt}")
        return 1

    if not canary_ok():
        print("::error::check_sql_dryrun self-check canary FAILED — 'SELECT 1 FROM' did not surface as "
              "a syntax error in this environment (bq/auth misconfigured, or BigQuery authorized before "
              "parsing). A clean pass would be unverifiable, so the gate FAILS CLOSED instead of "
              "green-lighting files it cannot actually check. Fix the environment (or investigate a "
              "BigQuery behavior change) and re-run.")
        return 1

    # find_final_definitions() is a pure repo-side text walk (no `bq`, no network — see its own
    # docstring) so it costs nothing to compute even when --per-statement ends up finding no
    # multi-CREATE file to use it against — but it is still gated on the flag below (not called at
    # all when --per-statement is absent), so a default-mode run touches exactly the files it always
    # did and nothing more.
    final_definitions = find_final_definitions() if per_statement else None

    syntax_errs, tolerated, unknown, analysis_errs, ok = [], [], [], [], 0
    per_statement_checked = 0
    for f in files:
        rc, out = _bq_dry_run(sql_path=f)
        kind = classify(rc, out)
        first = out.splitlines()[0][:220] if out else ""
        if kind == "ok":
            ok += 1
        elif kind == "syntax":
            syntax_errs.append((f, first))
        elif kind == "tolerated":
            tolerated.append(f)
        elif kind == "analysis":
            # Reachable from the WHOLE-FILE pass too (not only --per-statement below): a single-
            # CREATE-statement file dry-run by a PRIVILEGED identity (no leading DDL to blind
            # anything) can hit this directly, e.g. bigquery/234_staged_order_notice_resolve_
            # decorrelated.sql's own procedure body if it still carried the bug. classify()'s new
            # "analysis" kind must be handled here unconditionally, or a privileged local run would
            # silently fall through to the `else` (non-blocking "unknown") branch below instead of
            # blocking. See module docstring's PER-STATEMENT PASS section.
            analysis_errs.append((f, first))
        else:
            unknown.append((f, first))

        # ---- PER-STATEMENT PASS, OPT-IN ONLY (--per-statement) ------------------------------------
        # See module docstring's PER-STATEMENT PASS section: default-off because the CI identity
        # cannot benefit from it (every CREATE it dry-runs TOLERATEs on Access Denied, whole-file or
        # per-statement, before semantic analysis is ever reached) — this is for a privileged local
        # run only. Only runs against files this loop was ALREADY ABLE TO READ (file_texts, built
        # above for the static lint) — a file that couldn't be opened degrades the same way it
        # already does for the lint and the DDL caveat: silently excluded, never crashing main().
        if not per_statement:
            continue
        text = file_texts.get(f)
        if text is None:
            continue
        for dataset, name, obj_type, stmt_text in per_statement_dryrun_targets(f, text, final_definitions):
            per_statement_checked += 1
            rc2, out2 = _bq_dry_run(sql_text=stmt_text)
            kind2 = classify(rc2, out2)
            first2 = out2.splitlines()[0][:220] if out2 else ""
            label = f"{f} :: {dataset}.{name} ({obj_type}, per-statement pass)"
            if kind2 == "ok":
                pass                                    # nothing further to report for this statement
            elif kind2 == "syntax":
                syntax_errs.append((label, first2))
            elif kind2 == "tolerated":
                tolerated.append(label)
            elif kind2 == "analysis":
                analysis_errs.append((label, first2))
            else:
                unknown.append((label, first2))

    print(f"SQL dry-run: {len(files)} file(s) — {ok} parse-validated, {len(tolerated)} tolerated "
          f"(permission/reference), {len(unknown)} inconclusive, {len(syntax_errs)} SYNTAX ERROR(S), "
          f"{len(analysis_errs)} ANALYSIS ERROR(S).")
    if not per_statement:
        print("  (--per-statement not passed: only the whole-file pass ran — see module docstring's "
              "PER-STATEMENT PASS section for when to add it.)")
    if per_statement_checked:
        print(f"  per-statement pass: {per_statement_checked} additional top-level CREATE statement(s) "
              f"dry-run individually (scoped to apply-in-order FINAL definitions only — see module "
              f"docstring's PER-STATEMENT PASS section).")
    ddl_files = [f for f in files if f in file_texts and _contains_ddl(file_texts[f])]
    if ddl_files:
        print(f"NOTE: {len(ddl_files)} of {len(files)} file(s) contain a DDL statement (CREATE/ALTER/"
              f"DROP) — BigQuery's script dry-run does NOT semantically analyze any statement AFTER the "
              f"first DDL in a script (verified 2026-08-03; see this module's docstring). "
              f"'Parse-validated' proves those files PARSE, not that they will APPLY cleanly — the "
              f"no-FROM-WHERE static lint above closes this one specific illegal shape (a SELECT "
              f"expression-list reaching WHERE with no FROM) wherever it occurs — bare statement, "
              f"INSERT ... SELECT, CREATE VIEW/CREATE TABLE ... AS body, or any UNION/INTERSECT/EXCEPT "
              f"arm — but it is not a general semantic-analysis replacement: other classes this same "
              f"blind spot can hide (an unknown column, an undefined function, a bad JOIN) are not "
              f"caught by this lint and remain undetected until real apply.")
    for f in tolerated:
        print(f"  - tolerated (read-only SA can't dry-run this DDL, or a not-yet-live sibling ref): {f}")
    for f, e in unknown:
        print(f"  - inconclusive / non-blocking: {f} :: {e}")
    for f, e in syntax_errs:
        print(f"  ✗ SYNTAX ERROR (blocks merge): {f} :: {e}")
    for f, e in analysis_errs:
        print(f"  ✗ ANALYSIS ERROR (blocks merge): {f} :: {e}")

    if syntax_errs:
        print("\nPARSE FAILURE — a bigquery/*.sql file would abort at parse time on apply (the exact class "
              "that reached live apply 2026-07-17). Fix the syntax before merge.")
    if analysis_errs:
        surfaced_by = ("this file's PER-STATEMENT PASS (--per-statement)" if per_statement
                       else "the whole-file dry-run pass directly (no --per-statement needed here — "
                            "this file has no leading DDL blinding it)")
        print("\n::error::check_sql_dryrun ANALYSIS ERROR — BigQuery rejected a correlated "
              "subquery whose inner source it cannot de-correlate into an efficient JOIN (in practice: "
              f"the inner source is itself a VIEW/SELECT that contains a JOIN). This was surfaced by "
              f"{surfaced_by}. When it takes a leading DDL in the SAME script to hide this (the KNOWN, "
              "VERIFIED LIMITATION above: a leading DDL statement suppresses semantic analysis of every "
              "statement after it), that is exactly how bigquery/233_staged_order_window_dead_on_"
              "arrival.sql's CREATE VIEW; CREATE PROCEDURE script hid this same rejection and reached live "
              "apply, where it failed on every run — re-run this checker with --per-statement (as a "
              "PRIVILEGED identity; CI's read-only SA cannot use it, see module docstring) on a multi-"
              "CREATE file to catch that shape too. See bigquery/234_staged_order_notice_resolve_"
              "decorrelated.sql's header for the full incident and the three sanctioned fixes, by "
              "statement kind: (1) DML — pre-materialise the inner source into an ARRAY<STRING> "
              "scripting variable, then rewrite as NOT EXISTS (SELECT 1 FROM UNNEST(...)); (2) a "
              "VIEW/SELECT — rewrite as LEFT JOIN + IS NULL, the idiom bigquery/59_catchup_autofire.sql "
              "records (commit ff08a8b); (3) split one inequality-correlated EXISTS into two uncorrelated "
              "ones joined by AND, as ops.sp_sq_safety_critical_dml_watch "
              "(bigquery/75_scheduled_query_wrappers.sql) does. Pick by statement kind, not by habit.")
    if syntax_errs or analysis_errs:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

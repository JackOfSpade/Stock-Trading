#!/usr/bin/env python3
"""Compare live BigQuery view/procedure definitions against the bigquery/*.sql apply-in-order
"final effective definition" (2026-07-14 self-improvement audit finding).

WHY THIS EXISTS. Nothing in this repo's CI (or any scripts/check_*.py) ever asserted that the LAST
CREATE OR REPLACE for a given object name across bigquery/01..NN matches what is actually deployed.
That gap is exactly how a 2026-07-11 partial re-apply of bigquery/23_trading_control.sql silently
reverted state.trading_enabled to a pre-fix, self-latching formula for several days with no CI
signal (see bigquery/47_trading_enabled_resync.sql) — scripts/dbt_parity.py only compares dbt
models against live views, and never reads bigquery/*.sql at all.

HOW. For each object name, the LAST bigquery/NN_*.sql file (numeric order) that CREATE OR REPLACEs
it is the "final effective definition" — later files deliberately redefine objects created by
earlier ones (documented apply-in-order discipline; see bigquery/README.md). This script extracts
that final body text, fetches the live object's definition via BigQuery's INFORMATION_SCHEMA (read-
only), and compares them with whitespace collapsed to a single space.

NOT wired into CI's sandboxed pytest suite (it needs live BigQuery credentials) — instead it runs
daily via .github/workflows/live-sql-parity.yml (keyless WIF, same read-only SA as dbt-parity),
decoupled from push events since an in-flight bigquery/*.sql edit is *expected* to diverge from
not-yet-live-applied BigQuery (see that workflow's header for why). `--offline` runs just the
repo-side extraction (no bq calls) for local iteration on the parser itself.

VALIDATION STATUS (2026-07-14): the repo-side extraction (find_final_definitions/extract_body) was
verified offline against the real bigquery/*.sql tree -- 137 objects parse cleanly, the apply-order
"last file wins" resolution was spot-checked against several known redefinitions, and the FORMAT()-
string false-positive case (bigquery/17_restore_drill.sql) does not trip the parser.

COMPARATOR FIX (2026-07-16, live-sql-parity self-heal audit RES-3 step 0): the first live run
(issue #10, 2026-07-16) reported ~24 PROCEDURE objects as DRIFT purely because
INFORMATION_SCHEMA.ROUTINES.routine_definition for a PROCEDURE INCLUDES the outer BEGIN...END
wrapper (verified live on ops.sp_log_decision: definition starts 'BEGIN\n') while extract_body()
was stripping it from the repo side -- fixed in extract_body's PROCEDURE branch. A second,
orthogonal false-positive class (live definitions retaining trailing comments the repo-side
extraction already stripped) is fixed by normalize_tail(), now applied to both sides. See
tests/test_check_live_sql_parity.py for both regression tests.

DROP-AWARENESS FIX (2026-07-28). find_final_definitions() used to build its expected-object set from
CREATE OR REPLACE statements only, ignoring bigquery/*.sql's DROP statements entirely — so an object
LIVE deliberately dropped (bigquery/92/103's park-allocator/calibration views, retired by bigquery/
104 and 108, whose own comments say "DO NOT re-create live") stayed expected forever, found nothing
live, and was silently filed as an inconclusive skip rather than being excluded. Two fixes: (1)
find_final_definitions() now removes an object from the expected set on a DROP and re-adds it on a
later CREATE OR REPLACE, processing both in TEXTUAL apply order within each file (see DROP_STMT and
that function's docstring); (2) main() now distinguishes a live lookup that FAILED (exception —
inconclusive, stays a "skipped" entry, never fails the run by itself) from a live lookup that
SUCCEEDED with zero rows for an object still genuinely expected (positive evidence of a real
deployment gap — a new "missing_objects" category, printed distinctly, non-zero exit, and kept under
its OWN JSON key, separate from "findings", because the correct downstream action differs — CREATE,
not re-apply — and the compensating rails differ too; see write_json_out()'s docstring).

SELF-HEAL CONSUMPTION OF missing_objects — OWNER DIRECTIVE 2026-07-28 (SUPERSEDES the original
"human-authorized step only" design this comment stated when the category was introduced, above).
missing_objects is now consumed AUTONOMOUSLY, with no human approval step, by the same D3
CI-FINDINGS ADJUDICATION self-heal loop that already re-applies drifted "findings" objects
(Claude_Task_Plan.md D3, new branch (d)) — consistent with this repo's standing SISA posture that
compensating controls are MECHANICAL RAILS, not a human review gate (CLAUDE.md). This script's own
job is unchanged by that directive: it only detects and reports (this docstring + write_json_out()'s
docstring below are the only things that changed here). The rails that make autonomous creation safe
live in D3's prose, not in this file: the existing >=2-daily-run persistence requirement, the existing
7-day non-convergence latch, the existing 10-objects-per-session bound (now shared across re-apply +
create), a NEW mechanical DROP-guard (grep bigquery/*.sql for a DROP of the object before creating —
an independent second check against resurrecting something bigquery/92/108 deliberately retired, that
does not depend on this script's own DROP_STMT parsing being correct), and NEVER creating a TABLE
object (mirrors the existing never-re-apply-a-TABLE rule for drifted "findings"). See
.github/workflows/live-sql-parity.yml's "CI-findings bridge" step for how a missing_objects entry
reaches ops.ci_findings — detail begins with the literal marker "MISSING: " so the CI-findings
consumer can tell a missing-object row apart from a drift row without re-deriving it.

Usage:  python scripts/check_live_sql_parity.py --project stock-trading-498512
        python scripts/check_live_sql_parity.py --offline   # parser self-check only, no bq calls
        python scripts/check_live_sql_parity.py --project stock-trading-498512 --json-out /tmp/findings.json
"""
import argparse
import os
import re
import subprocess  # noqa: F401 — kept so tests can monkeypatch subprocess.run/TimeoutExpired at the module level
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import run_bq_query
from lib.sql_files import sql_file_paths

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")

# A genuine top-level statement starts at column 0 (^, re.MULTILINE) — an indented occurrence
# (e.g. bigquery/17_restore_drill.sql's "CREATE OR REPLACE TABLE ..." embedded inside a FORMAT()
# string literal passed to EXECUTE IMMEDIATE) must NOT match.
CREATE_STMT = re.compile(
    r"^CREATE\s+OR\s+REPLACE\s+(VIEW|PROCEDURE|TABLE FUNCTION)\s+`([\w-]+)\.(\w+)\.(\w+)`",
    re.MULTILINE,
)

# Boundary for extract_body: the NEXT top-level (column-0) statement ends the current object's body.
# CREATE_STMT only recognizes the three object types this script COMPARES (VIEW/PROCEDURE/TABLE
# FUNCTION), but bigquery/*.sql also carries top-level CREATE TABLE [IF NOT EXISTS], scalar CREATE OR
# REPLACE FUNCTION, CREATE OR REPLACE MODEL, and CREATE SCHEMA between comparable objects. Using
# CREATE_STMT itself as the end boundary let those foreign DDL blocks BLEED into the preceding
# object's extracted body — 10 live objects mis-parsed into a permanent false DRIFT that also fed the
# RES-3 self-heal candidate loop (2026-07-17 code-quality audit). Matching any top-level CREATE
# keyword fixed that class.
#
# But top-level *non-CREATE* statements bleed the same way: bigquery/67_ci_findings_bridge.sql ends
# `CREATE OR REPLACE VIEW state.ci_findings_open AS SELECT … ;` and then, in the SAME file, runs a
# standalone `MERGE state.expected_scheduled_query_versions …` registry bump. A CREATE-only boundary
# swept that MERGE into the view's extracted body, so its repo-side text could NEVER match the live
# `view_definition` (which is only the SELECT) — a permanent false DRIFT that normalize_tail can't
# strip because the tail is a whole statement, not a comment (2026-07-17 parallel-refactor audit,
# HIGH; regression-guarded by tests/test_check_live_sql_parity.py). So the boundary now also stops at
# the start of a top-level DML/DDL statement.
#
# The keyword list is deliberately RESTRICTED (not a bare ^\w+): a column-0 keyword can only ever be
# a new top-level statement, never an identifier that happens to begin a line. BEGIN is deliberately
# EXCLUDED — it opens a PROCEDURE's OWN body (extract_body slices a procedure from its `BEGIN`), and
# every statement *inside* a procedure's BEGIN…END is indented in this repo (verified: no compared
# body holds a column-0 DML keyword after this fix), so a column-0 MERGE/INSERT/etc. is always a
# following top-level statement, not procedure-internal. Order matters: the two-word CREATE forms
# precede their one-word prefixes so alternation picks the longer.
NEXT_TOP_LEVEL = re.compile(
    r"^(?:"
    r"CREATE\s+(?:OR\s+REPLACE\s+)?"
    r"(?:MATERIALIZED\s+VIEW|TABLE\s+FUNCTION|VIEW|PROCEDURE|TABLE|FUNCTION|MODEL|SCHEMA)"
    r"|INSERT|MERGE|UPDATE|DELETE|TRUNCATE|DROP|ALTER|GRANT|REVOKE|CALL|EXPORT|ASSERT"
    r")\b",
    re.MULTILINE,
)

# A DROP that removes an object from find_final_definitions()'s expected set (2026-07-28 DROP-
# awareness fix — see that function's docstring for the concrete bug this closes). Same column-0
# (^, re.MULTILINE) anchor CREATE_STMT relies on for the same reason: a genuine top-level DROP
# statement always starts a line at column 0 in this repo's DDL, so a "DROP" that appears inside a
# `-- comment` (the line starts with "--", never "DROP") or inside an indented string literal (e.g.
# a FORMAT()/EXECUTE IMMEDIATE payload, mirroring bigquery/17_restore_drill.sql's embedded CREATE)
# can never match. Object types are the real forms used in bigquery/*.sql today (VIEW, TABLE,
# PROCEDURE, FUNCTION, TABLE FUNCTION) plus MATERIALIZED VIEW for completeness.
#
# ALTERNATION ORDER (TABLE FUNCTION vs TABLE — DEFECT, fixed 2026-07-28): unlike the MATERIALIZED
# VIEW / VIEW pair, where a real collision is provably impossible (VIEW alone can never match text
# that starts with MATERIALIZED), TABLE actually IS a literal prefix of TABLE FUNCTION — the bare
# TABLE alternative can start consuming "DROP TABLE FUNCTION ..." at the TABLE token before the
# parser discovers, several groups later, that "FUNCTION" doesn't fit where a `.`-joined identifier
# is required. Before this fix DROP_STMT had NO TABLE FUNCTION alternative at all, so real BigQuery
# "DROP TABLE FUNCTION [IF EXISTS] <id>" DDL (this repo has three live TABLE FUNCTION objects today:
# analytics.fn_order_guard, analytics.fn_order_guard_options, analytics.find_precedents) produced a
# COMPLETE non-match — confirmed live pre-fix. TABLE\s+FUNCTION is therefore listed BEFORE the bare
# TABLE alternative, the same longest-first discipline NEXT_TOP_LEVEL's own MATERIALIZED VIEW /
# TABLE FUNCTION / VIEW ordering already uses (see that pattern's comment above) — so the longer
# form is the one actually tried and matched, rather than relying on Python re's alternation
# backtracking (trying TABLE first, failing past it, then retrying TABLE FUNCTION) to recover the
# right answer. Both would produce the same match here since Python's re does backtrack across
# alternatives, but ordering it explicitly keeps DROP_STMT correct by inspection instead of by an
# engine behavior a future reader would have to reason through.
#
# Identifier: bigquery/104's and bigquery/108's real DROP statements are fully backtick-quoted
# (`` `project.dataset.name` ``), but this repo also writes a PARTIALLY-backtick-quoted form
# elsewhere — backticks around the project id only (e.g. bigquery/18/75's
# `` `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA... ``) — so each of the three identifier
# segments gets its OWN optional backtick pair instead of requiring one single backtick-wrapped
# whole; both forms parse identically. `[\w-]+` for the project id (BigQuery project ids may
# contain hyphens, mirroring CREATE_STMT's own project-id group) and `\w+` for dataset/name (no
# hyphen allowed in a dataset or object name).
#
# KNOWN, ACCEPTED LIMIT (found by adversarial review 2026-07-28 — do NOT "fix" without reading this).
# The `^` + re.MULTILINE anchor is what keeps the word DROP inside a `--` line comment or a
# `/* block */` from matching: a real top-level DROP in this repo's DDL always starts at column 0,
# and a comment line starts with `-` or `*`. Verified against every DROP and comment in bigquery/*.sql.
# It does NOT, however, protect against a column-0 `DROP ...` sitting inside a triple-quoted
# ("""...""") multi-line string literal passed to EXECUTE IMMEDIATE — that WOULD match and would
# silently remove a still-live object from the expected set, which is the exact blind-spot class this
# whole DROP-awareness change exists to close. It is left as-is deliberately, on two grounds:
# (1) CREATE_STMT above has the byte-identical weakness against the same construct, so tightening only
# DROP_STMT would make the two parsers disagree about what counts as a statement — worse than a
# symmetric, documented limit; and (2) the only real triple-quoted EXECUTE IMMEDIATE blocks in the
# repo (bigquery/75_scheduled_query_wrappers.sql, 2 of them) contain nothing but EXPORT DATA
# OPTIONS(...), always indented, never a column-0 DROP or CREATE. If a future file ever embeds DDL at
# column 0 inside a string literal, fix BOTH regexes together by stripping string literals before
# matching — do not special-case one of them.
DROP_STMT = re.compile(
    r"^DROP\s+(MATERIALIZED\s+VIEW|TABLE\s+FUNCTION|VIEW|TABLE|PROCEDURE|FUNCTION)\s+"
    r"(?:IF\s+EXISTS\s+)?"
    r"`?([\w-]+)`?\.`?(\w+)`?\.`?(\w+)`?",
    re.MULTILINE,
)


def numbered_sql_files():
    """bigquery/NN_*.sql files in NUMERIC apply-order (not lexical — NN is zero-padded to 2 digits
    today, but sort by the leading integer explicitly so this stays correct if that ever changes).

    Delegates to scripts/lib/sql_files.py — the shared apply-order walk this module's own copy was
    consolidated into (codebase audit 2026-07-26) after check_dbt_view_coverage.py was found still
    walking `sorted(os.listdir(...))` (lexical) and mis-ordering every 3-digit bigquery/*.sql file
    against this repo's now-100+-file tree; see that module's docstring for the reproduced bug."""
    return sql_file_paths(BIGQUERY_DIR)


def normalize_tail(body):
    """Strip trailing comment-only / blank lines, then exactly one trailing ';'.

    Applied to BOTH the repo-extracted body (extract_body, below) AND the live
    INFORMATION_SCHEMA body (main(), before comparison) -- fixed 2026-07-16 (live-sql-parity
    self-heal audit, RES-3 step 0b). Before this fix only the repo side was normalized: live view/
    routine definitions retain trailing comments and whitespace that the repo file's next-statement
    boundary already excludes on the repo side, so those objects would never converge and would
    report DRIFT forever regardless of any re-apply -- a second, orthogonal false-positive class
    from the PROCEDURE-wrapper bug fixed in the same step (see extract_body's obj_type == "PROCEDURE"
    branch).
    """
    lines = body.splitlines()
    while lines and (not lines[-1].strip() or lines[-1].strip().startswith("--")):
        lines.pop()
    body = "\n".join(lines)
    body = body.rstrip()
    if body.endswith(";"):
        body = body[:-1]
    return body


def extract_body(txt, start, obj_type):
    """Given the file text and the start offset of a CREATE_STMT match, return the object's body:
    the preamble (CREATE ... AS / ... BEGIN) is dropped, keeping only what INFORMATION_SCHEMA's
    view_definition/routine_definition itself contains."""
    # Find the end of this statement: the next top-level CREATE of ANY kind (NEXT_TOP_LEVEL — not
    # just the three COMPARED object types), or end of file. See NEXT_TOP_LEVEL's comment.
    next_m = NEXT_TOP_LEVEL.search(txt, start + 1)
    end = next_m.start() if next_m else len(txt)
    stmt = txt[start:end]

    if obj_type == "PROCEDURE":
        # Fixed 2026-07-16 (live-sql-parity self-heal audit, RES-3 step 0a): live
        # INFORMATION_SCHEMA.ROUTINES.routine_definition for a PROCEDURE INCLUDES the outer
        # BEGIN...END wrapper (verified live 2026-07-16 on ops.sp_log_decision: definition starts
        # 'BEGIN\n') -- so the repo-side body must keep it too, sliced from m.start() (not
        # m.end()), or every procedure would spuriously DRIFT against a live body that has the
        # wrapper the repo side stripped. This was the ~24-procedure false-positive class behind
        # issue #10.
        m = re.search(r"\bBEGIN\b", stmt)
        if not m:
            return None
        body = stmt[m.start():]
    else:  # VIEW / TABLE FUNCTION
        # The first standalone "AS" (followed by whitespace) after the CREATE header — the AS that
        # starts the SELECT/body. A column-alias "AS" can never appear textually before this header
        # AS, so the first `\bAS\b(?=\s)` is always the header AS in both the end-of-line style
        # (`… AS\n  SELECT`) and the inline style (`… AS SELECT`). An earlier variant preferred the
        # first `AS\s*\n`, which on an inline `AS SELECT` header skipped to a later `col AS\n`
        # column alias and sliced off the front of the SELECT; removing that branch is byte-
        # identical across all live objects and closes that latent trap (2026-07-17 audit).
        m = re.search(r"\bAS\b(?=\s)", stmt)
        if not m:
            return None
        body = stmt[m.end():]

    body = normalize_tail(body)
    if obj_type == "TABLE FUNCTION":
        # The outer wrapping ")" that closes the function's parameter list is part of the
        # preamble captured differently per call site; TABLE FUNCTION bodies in this repo are a
        # single AS ( ... ) wrapper — strip one matching outer paren pair if present. A naive
        # startswith("(")/endswith(")") check strips a leading paren that is NOT actually matched
        # by the trailing one whenever the body's true shape is a set operation of parenthesized
        # branches with no extra outer wrap (e.g. `(SELECT a) UNION ALL (SELECT b)`), corrupting an
        # otherwise-balanced body. Only strip when paren depth returns to 0 exactly at the last
        # character — i.e. the leading "(" really is the one that closes at the trailing ")" —
        # never earlier (2026-07-18 audit fix). This assumes no unbalanced parens appear inside a
        # string literal in this position, true for this repo's DDL today; a full string-literal-
        # aware scan (like canonicalize's tokenizer) is unneeded here.
        stripped = body.strip()
        if stripped.startswith("(") and stripped.endswith(")"):
            depth = 0
            true_wrapper = False
            for idx, ch in enumerate(stripped):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        true_wrapper = idx == len(stripped) - 1
                        break
            if true_wrapper:
                body = stripped[1:-1]
    return body.strip()


def canonicalize(sql):
    """Reduce SQL to a form that ignores everything BigQuery does NOT preserve, so the comparison
    tests MEANING rather than formatting.

    WHY (2026-07-18). BigQuery does not store a view/routine definition verbatim — it RE-SERIALIZES
    it. Measured against this repo's live warehouse, the stored text differs from the applied text by:
      * comments STRIPPED entirely (both -- line and block);
      * whitespace adjacent to punctuation REMOVED (`AS ( SELECT` -> `AS (SELECT`);
      * identifier backticks dropped in some definitions;
      * string-quote style re-serialized ('x' <-> "x").
    collapse() (whitespace -> single space) survives none of that, so ANY comment edit in bigquery/*.sql
    — the single most common kind of edit in this repo — made its object mismatch FOREVER, regardless
    of re-apply. Measured effect: 70 of 179 objects (39%) reported DRIFT, of which 65 were pure
    formatting and only 5 were real. A gate that is 93% false positive is not a gate; it trains the
    reader to ignore the one signal that matters, which is exactly how the 2026-07-11
    state.trading_enabled revert survived for days.

    So: strip comments, drop backticks, normalize simple string-literal quoting, and keep whitespace
    ONLY where it is semantically load-bearing (between two word/string tokens). String literals are
    passed through VERBATIM — a `--` or extra space INSIDE a literal is content, not formatting, and
    must still count as drift (ops.sp_score_theater's prompt text differing by an em-dash vs hyphen is
    a real finding this must not swallow).
    """
    if not sql:
        return sql
    toks, i, n = [], 0, len(sql)
    while i < n:
        c = sql[i]
        if c in ("'", '"'):                                  # string literal — verbatim
            quote = c
            triple = sql[i:i + 3] == quote * 3
            if triple:
                j = sql.find(quote * 3, i + 3)
                j = n if j < 0 else j + 3
            else:
                j = i + 1
                while j < n:
                    if sql[j] == "\\":
                        j += 2
                        continue
                    if sql[j] == quote:
                        j += 1
                        break
                    if sql[j] == "\n":                       # unterminated — stop at the newline
                        break
                    j += 1
            lit = sql[i:j]
            # Normalize quote STYLE only when the content contains neither quote, so re-quoting is
            # unambiguous and cannot change the literal's value.
            if not triple and len(lit) >= 2 and lit[0] == lit[-1] and lit[0] in "'\"":
                inner = lit[1:-1]
                if '"' not in inner and "'" not in inner:
                    lit = "'" + inner + "'"
            toks.append(("S", lit))
            i = j
            continue
        if sql.startswith("--", i):
            j = sql.find("\n", i)
            i = n if j < 0 else j
            continue
        if sql.startswith("/*", i):
            j = sql.find("*/", i)
            i = n if j < 0 else j + 2
            continue
        if c == "`":                                         # identifier quoting is not semantic
            i += 1
            continue
        if c.isspace():
            while i < n and sql[i].isspace():
                i += 1
            toks.append(("W", " "))
            continue
        if c.isalnum() or c == "_":
            j = i
            while j < n and (sql[j].isalnum() or sql[j] == "_"):
                j += 1
            toks.append(("T", sql[i:j]))
            i = j
            continue
        toks.append(("P", c))
        i += 1

    # Removing a comment leaves the whitespace on BOTH sides of it as separate runs; merge them, or
    # `wins -- note\n  FROM` canonicalizes to "wins  FROM" (two spaces) and never matches live.
    merged = []
    for t in toks:
        if t[0] == "W" and merged and merged[-1][0] == "W":
            continue
        merged.append(t)

    out = []
    for k, (kind, val) in enumerate(merged):
        if kind != "W":
            out.append(val)
            continue
        prev = next((merged[x] for x in range(k - 1, -1, -1) if merged[x][0] != "W"), None)
        nxt = next((merged[x] for x in range(k + 1, len(merged)) if merged[x][0] != "W"), None)
        if prev and nxt and prev[0] in ("T", "S") and nxt[0] in ("T", "S"):
            out.append(" ")                                  # load-bearing: `SELECT x` != `SELECTx`
    return "".join(out)


def find_final_definitions():
    """{(dataset, name): (obj_type, project, source_file, body)} — the LAST apply-in-order
    definition of each object across bigquery/*.sql, DROP-aware.

    DROP-AWARE FIX (2026-07-28). Earlier versions built the expected-object set from CREATE OR
    REPLACE statements ONLY and ignored bigquery/*.sql's DROP statements entirely — so an object
    LIVE deliberately dropped stayed in the expected set forever. Concretely: bigquery/92_park_
    allocator.sql's three state.park_* views (park_allocator_promotion_readiness, park_switch_
    budget, park_control_latest) are retired outright by bigquery/108_park_allocator_immediate_
    binding.sql ("DO NOT re-create live — 108 drops it"), and analytics.calibration_return_shrunk
    (bigquery/103_adaptive_shortfall_budget.sql) is retired the same way by bigquery/104_strip_
    pretrade_rails.sql. Every scheduled live-sql-parity run found nothing live for those four
    objects, filed them under "no live object found", conflated that with a transient lookup
    failure, and reported PASS regardless — so those four objects were silently NEVER actually
    verified by this checker since the day they were dropped, even though live is exactly correct
    (see tests/test_check_live_sql_parity.py's real-repo regression test). See main()'s
    missing_objects handling for the complementary half of this fix: an object that is STILL
    expected (never dropped, or dropped-then-not-recreated is exactly what this function now
    reflects) but genuinely absent live is now a distinct, non-zero-exit finding category rather
    than being silently swallowed as a skip.

    CREATE and DROP are applied in TEXTUAL ORDER WITHIN EACH FILE — not "all CREATEs in the file,
    then all DROPs" — because a single file can legitimately do both to the same object (drop an
    old view and recreate it under the same name, or vice versa); only processing them in the
    order they actually appear reproduces what apply-in-order really does to the live object.
    """
    final = {}
    for path in numbered_sql_files():
        txt = open(path, encoding="utf-8").read()
        events = [(m.start(), "CREATE", m) for m in CREATE_STMT.finditer(txt)]
        events += [(m.start(), "DROP", m) for m in DROP_STMT.finditer(txt)]
        events.sort(key=lambda e: e[0])
        for _start, kind, m in events:
            if kind == "CREATE":
                obj_type, project, dataset, name = m.groups()
                body = extract_body(txt, m.start(), obj_type)
                if body is None:
                    continue
                final[(dataset, name)] = (obj_type, project, os.path.basename(path), body)
            else:  # DROP — remove from the expected set; a no-op if it was never (or no longer) present.
                _obj_type, _project, dataset, name = m.groups()
                final.pop((dataset, name), None)
    return final


def bq(sql, project):
    # Delegates to lib/bq_json.py's run_bq_query — the shared invoke wrapper this module's copy
    # was consolidated into (2026-07-18 dedup-sweep audit).
    return run_bq_query(sql, project)


def live_definition(project, dataset, name, obj_type):
    if obj_type == "PROCEDURE":
        rows = bq(
            f"SELECT routine_definition FROM `{project}`.{dataset}.INFORMATION_SCHEMA.ROUTINES "
            f"WHERE routine_name = '{name}' AND routine_type = 'PROCEDURE'", project)
    elif obj_type == "TABLE FUNCTION":
        rows = bq(
            f"SELECT routine_definition FROM `{project}`.{dataset}.INFORMATION_SCHEMA.ROUTINES "
            f"WHERE routine_name = '{name}' AND routine_type = 'TABLE FUNCTION'", project)
    else:
        rows = bq(
            f"SELECT view_definition FROM `{project}`.{dataset}.INFORMATION_SCHEMA.VIEWS "
            f"WHERE table_name = '{name}'", project)
    if not rows:
        return None
    key = "routine_definition" if obj_type != "VIEW" else "view_definition"
    return rows[0].get(key)


def write_json_out(json_out_path, findings, missing_live, missing_objects):
    """Write the --json-out findings file (RES-3 step 1, live-sql-parity self-heal audit
    2026-07-16; `missing_objects` added 2026-07-28 DROP-awareness fix, FIX 3).

    THREE distinct categories, each under its OWN JSON key — do not merge any of them:

      * "findings"         -- a real MISMATCH: the object exists both in the repo's final-effective
                               bigquery/*.sql and live, but the text differs. Self-heal action:
                               RE-APPLY the repo's current definition — the object already exists
                               live, so this only corrects drift, it does not create anything new.
      * "skipped"           -- a live LOOKUP FAILED (exception: bq/auth error, timeout, etc.) --
                               NOT evidence of drift or of absence, just an inconclusive read. Never
                               a self-heal candidate; can starve `checked` to 0, which main()'s
                               separate checked==0 fail-closed guard catches, but a lookup failure
                               never fails the run by itself.
      * "missing_objects"   -- the live lookup SUCCEEDED and returned zero rows: POSITIVE evidence
                               the object genuinely does not exist live, even though the repo's
                               final-effective bigquery/*.sql still expects it -- a real, currently-
                               invisible deployment gap. This fails the run (non-zero exit). Self-heal
                               action: CREATE the object from the repo's current definition.

                               WHY THIS STAYS A SEPARATE KEY, NOT MERGED INTO "findings" (both before
                               and after the 2026-07-28 directive below): a "findings" row means "this
                               object exists live but drifted" -> re-apply (CREATE OR REPLACE is a
                               straight swap of something already there). A "missing_objects" row means
                               "this object does not exist live at all" -> CREATE. Those two actions
                               are not interchangeable, and a consumer must not have to re-derive which
                               one applies from the object's live-absence — the JSON key says so
                               directly.

                               CONSUMPTION -- OWNER DIRECTIVE 2026-07-28 SUPERSEDES the original
                               design recorded in an earlier revision of this docstring, which kept
                               missing_objects "out of any self-heal consumer's reach on purpose" and
                               said auto-creating "must stay a human-authorized step." That reasoning
                               is superseded: missing_objects IS now consumed autonomously, no human
                               approval step, by the same D3 CI-FINDINGS ADJUDICATION loop that already
                               re-applies drifted "findings" objects (Claude_Task_Plan.md D3, branch
                               (d)) -- consistent with this repo's standing SISA posture that
                               compensating controls are MECHANICAL RAILS, not human review (CLAUDE.md).
                               Those rails (living in D3's prose, not here, since this script only
                               detects/reports) are: the existing >=2-daily-run persistence
                               requirement (skip a same-day-first-detected finding — the window in
                               which someone lands a new bigquery/NN file and applies it live minutes
                               later, where creating it underneath them would race); the existing
                               7-day non-convergence latch (re-flagged after a recent heal -> alert,
                               do not retry); the existing 10-objects-per-session bound (now shared
                               across re-apply + create, not doubled); a NEW mechanical DROP-guard
                               (grep bigquery/*.sql for a DROP of the object before creating -- an
                               independent second check against resurrecting something bigquery/92/108
                               deliberately retired, that does not depend on this script's own
                               DROP_STMT parsing being correct); and NEVER creating a TABLE object
                               (mirrors the existing never-re-apply-a-TABLE rule for "findings"). See
                               .github/workflows/live-sql-parity.yml for how a missing_objects entry
                               reaches ops.ci_findings: its `detail` begins with the literal marker
                               "MISSING: " so the CI-findings consumer can tell a missing-object row
                               apart from a drift row without re-deriving it from anything else.
    """
    import json
    from datetime import datetime, timezone

    payload = {
        "checked_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "findings": findings,
        "skipped": missing_live,
        "missing_objects": missing_objects,
    }
    with open(json_out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")


def main():
    # argparse (mirroring check_live_roster_parity.py) so both the two-token (`--project X`) and
    # GNU `--project=X` invocation forms work identically, and an unrecognized flag is a hard error
    # instead of a silent no-op (2026-07-20 cross-cutting audit: the old hand-rolled argv loop only
    # matched the two-token form, so `--project=X` silently kept the hardcoded default project).
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="stock-trading-498512")
    ap.add_argument("--offline", action="store_true")
    ap.add_argument("--json-out", default=None)
    args = ap.parse_args()
    offline = args.offline
    project = args.project
    json_out = args.json_out

    final = find_final_definitions()
    print(f"Parsed {len(final)} final-effective object definitions from bigquery/*.sql.")
    if offline:
        print("--offline: parser structure check only, no live comparison performed.")
        return 0

    mismatches, findings, missing_live, missing_objects, checked = [], [], [], [], 0
    for (dataset, name), (obj_type, _obj_project, source_file, body) in sorted(final.items()):
        try:
            # Use the CLI-supplied --project (default stock-trading-498512), not the project parsed
            # from the object's own CREATE statement text, so --project is an actual, honored
            # override rather than a parsed-but-ignored argument.
            live_body = live_definition(project, dataset, name, obj_type)
        except Exception as e:
            # Lookup FAILED (transient/auth/timeout) -- inconclusive, NOT evidence of anything.
            # Keep this branch exactly as it was: a skip, never a finding, never a fail on its own.
            missing_live.append(f"{dataset}.{name} ({source_file}): live lookup failed: {e}")
            continue
        if live_body is None:
            # FIX 2 (2026-07-28): the lookup SUCCEEDED and returned zero rows -- positive evidence
            # the object is genuinely absent live, distinct from the lookup-failure branch above.
            # Previously both landed in the same missing_live bucket, so a real, currently-invisible
            # deployment gap (the repo's final-effective bigquery/*.sql still expects an object that
            # was never applied live) silently reported PASS forever. See find_final_definitions()'s
            # docstring for the four concrete objects this used to hide (now DROP-excluded there, so
            # only a GENUINE gap reaches this branch today).
            missing_objects.append(
                f"{dataset}.{name} ({source_file}): no live object found -- repo's final-effective "
                f"bigquery/*.sql expects this object but live has none (lookup succeeded, zero rows)")
            continue
        checked += 1
        # normalize_tail applied to the live body too (RES-3 step 0b) -- live view/routine
        # definitions retain trailing comments the repo-side extraction already strips, a second
        # never-converging false-positive class alongside the PROCEDURE-wrapper bug above.
        # canonicalize (not collapse): BigQuery re-serializes stored definitions — comments stripped,
        # whitespace around punctuation removed, backticks/quote-style normalized — so a raw-text
        # compare reported 70/179 objects as DRIFT when only 5 differed in MEANING (2026-07-18).
        if canonicalize(body) != canonicalize(normalize_tail(live_body)):
            mismatches.append(f"{dataset}.{name} — live definition does NOT match the final "
                              f"effective definition in {source_file}")
            findings.append({"dataset": dataset, "name": name, "object_type": obj_type,
                              "source_file": source_file})

    print(f"Compared {checked} objects against live BigQuery; {len(mismatches)} mismatched, "
          f"{len(missing_objects)} missing live (expected but absent), "
          f"{len(missing_live)} could not be checked (lookup failed).")
    for m in missing_live:
        print(f"  - skipped: {m}")
    for m in missing_objects:
        print(f"  ! MISSING: {m}")
    for m in mismatches:
        print(f"  ✗ DRIFT: {m}")

    if json_out:
        write_json_out(json_out, findings, missing_live, missing_objects)

    if mismatches:
        print("\nLIVE SQL PARITY FAILED — re-apply the final-effective bigquery/*.sql definition "
              "for the listed object(s) via the BigQuery MCP/console.")
    if missing_objects:
        # FIX 2/3 (2026-07-28): a genuine absence is a real, currently-invisible deployment gap --
        # fails the run same as a mismatch, but the messaging (and the JSON category) stays distinct
        # because the REMEDY differs: a mismatch is re-applied, an absence is CREATED. See
        # write_json_out()'s docstring. This checker itself never creates anything either way.
        print("\nLIVE SQL PARITY: MISSING OBJECT(S) — the repo's final-effective bigquery/*.sql "
              "declares object(s) with no live counterpart (the lookup succeeded and found nothing "
              "-- this is not a transient lookup failure). These are delivered to ops.ci_findings "
              "with a 'MISSING: ' detail prefix and created autonomously by D3's self-heal branch "
              "(d) under its mechanical rails (owner directive 2026-07-28); this checker only "
              "reports them.")
    if mismatches or missing_objects:
        return 1
    if checked == 0:
        # Fail closed on ZERO verification. If every object fell into missing_live — a systemic bq/WIF
        # auth failure making every live_definition() raise, or (should-never-happen) an empty/broken
        # parse of bigquery/*.sql — then no parity was actually proven, so reporting OK would be a
        # vacuous green on zero comparisons. This mirrors dbt_parity.py's checked==0 guard; the daily
        # WIF workflow (.github/workflows/live-sql-parity.yml) gates on this exit code, so a fail-open
        # here would silently hide a completely broken parity gate (2026-07-17 parallel-refactor audit).
        print("\nLIVE SQL PARITY NOT VERIFIED — 0 objects were verified against live BigQuery (every "
              "object was skipped — a systemic bq/auth failure — or none parsed from bigquery/*.sql); "
              "refusing to report OK on zero comparisons.")
        return 1
    print("OK: every checked object's live definition matches its final-effective bigquery/*.sql source.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

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
table live. A per-statement splitter is NOT the fix: 37 bigquery/*.sql files contain `BEGIN`, 36
contain `CREATE OR REPLACE PROCEDURE`, and 29 contain `DECLARE`, so a splitter is fragile against this
repo's actual SQL shapes — and it would not even have caught THIS bug, because the INSERT targeted a
table that did not exist yet, which returns "Not found ..." -> already TOLERATED by design, splitter or
not. Instead, `no_from_where_violations()` below is a small, credential-free STATIC lint for this exact
illegal shape, run BEFORE any `bq` call — so it still protects when the dry-run job is skipped, `bq` is
unavailable, or (as happened here) a leading DDL blinds the dry-run to everything after it. It is
deliberately narrow (this one illegal shape only), not a general semantic-analysis replacement, which
is why a clean dry-run result for a file containing a DDL statement is reported below as
"parse-validated" (proves the script PARSES) rather than "validated" (would wrongly imply it will
apply), with an explicit caveat line printed for any run that includes such a file.

Usage:  python scripts/check_sql_dryrun.py <file.sql> [<file.sql> ...]
Requires the `bq` CLI authed (WIF in CI; local gcloud otherwise). Exit 0 = no syntax errors and no
static-lint violations (or nothing to check); exit 1 = at least one file has a syntax error, a
no-FROM-WHERE static-lint violation, or the canary self-check failed.
"""
import os
import re
import subprocess
import sys

from lib.sql_files import strip_sql_comments

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


def classify(exit_code, output):
    """'ok' | 'syntax' (BLOCK) | 'tolerated' (perm/ref) | 'unknown' (transient, non-blocking)."""
    if exit_code == 0:
        return "ok"
    low = (output or "").lower()
    if any(m in low for m in SYNTAX_MARKERS):
        return "syntax"
    if any(m in low for m in TOLERATE_MARKERS):
        return "tolerated"
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


# ==== STATIC, CREDENTIAL-FREE LINT: `INSERT ... SELECT <literals> WHERE ...` with no FROM ==========
#
# Closes the blind spot documented in the module docstring's KNOWN, VERIFIED LIMITATION section: a
# leading DDL statement in a bigquery/*.sql script suppresses BigQuery's OWN script-dry-run semantic
# analysis of everything after it, so this exact illegal shape (an idempotency-guard idiom used
# throughout bigquery/*.sql) can reach live apply undetected by `bq query --dry_run` alone. This check
# needs no `bq`, no credentials, and no network — it is pure text analysis — so it runs first and can
# still protect a push even when the dry-run job itself is skipped or `bq` is unavailable.

_DDL_KEYWORD_RE = re.compile(r"\b(CREATE|ALTER|DROP)\b", re.IGNORECASE)
_INSERT_INTO_RE = re.compile(r"\bINSERT\s+INTO\b", re.IGNORECASE)
_SELECT_KEYWORD_RE = re.compile(r"\bSELECT\b", re.IGNORECASE)
_FROM_KEYWORD_RE = re.compile(r"\bFROM\b", re.IGNORECASE)
_WHERE_KEYWORD_RE = re.compile(r"\bWHERE\b", re.IGNORECASE)


def _blank_string_literals(text):
    """Blank the CONTENTS (and, for string literals, the delimiters too) of every quoted region in
    `text` with spaces, preserving every newline and the overall length — the same length/newline-
    preserving contract as `lib.sql_files.strip_sql_comments` (whose literal-walking logic this
    mirrors), so a position or line number computed against the result still lands correctly against
    the ORIGINAL text.

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
            quote = c
            triple = text[i:i + 3] == quote * 3
            j = i + (3 if triple else 1)
            end = quote * 3 if triple else quote
            while j < n:
                if not triple and text[j] == "\\":
                    j += 2
                    continue
                if text[j:j + len(end)] == end:
                    j += len(end)
                    break
                if not triple and text[j] == "\n":   # unterminated single-line literal — stop here
                    break
                j += 1
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


def _scan_insert_select(masked, start):
    """From `start` (just past an `INSERT INTO` match in `masked`), scan forward tracking paren depth
    from 0 and return one of:
      ("not_applicable", None) — this INSERT never reaches a top-level SELECT before its own
          terminating top-level ';' — e.g. an `INSERT ... VALUES (...)` statement, which has no
          SELECT at all, so the no-FROM-WHERE shape does not apply. (There is no dedicated VALUES
          fast-path: the general depth-0 scan below already falls through to "not_applicable" for
          any statement shape that never sets `seen_select`, VALUES included — confirmed redundant
          by mutation testing, 2026-08-03.)
      ("ok", None)             — the statement's SELECT reaches a top-level FROM before any top-level
          WHERE (or has no WHERE at all) — not the illegal shape.
      ("violation", where_pos) — the statement's SELECT reaches a top-level WHERE before any top-level
          FROM — the exact illegal shape ("Query without FROM clause cannot have a WHERE clause").
    "Top-level" means at paren depth 0 relative to this statement's own start: a nested
    `WHERE NOT EXISTS (SELECT 1 FROM t WHERE ...)` guard is one level DEEPER (inside its own parens),
    so its FROM/WHERE never confuse the outer statement's own classification; likewise a CTE
    (`WITH r AS (SELECT ... FROM ...), ... SELECT ... FROM r`) has its per-CTE SELECT/FROM sealed
    inside the CTE's own parens, and only the CTE's own FINAL outer SELECT is ever seen at depth 0.
    """
    depth = 0
    pos = start
    n = len(masked)
    seen_select = False
    while pos < n:
        ch = masked[pos]
        if ch == "(":
            depth += 1
            pos += 1
            continue
        if ch == ")":
            depth -= 1
            pos += 1
            continue
        if depth == 0:
            if ch == ";":
                break
            if not seen_select:
                sm = _SELECT_KEYWORD_RE.match(masked, pos)
                if sm:
                    seen_select = True
                    pos = sm.end()
                    continue
            else:
                if _FROM_KEYWORD_RE.match(masked, pos):
                    return "ok", None
                if _WHERE_KEYWORD_RE.match(masked, pos):
                    return "violation", pos
        pos += 1
    return ("ok" if seen_select else "not_applicable"), None


def _excerpt(original_text, start_pos, end_pos, max_len=180):
    """Whitespace-collapsed snippet of `original_text[start_pos:end_pos]`, trimmed to at most
    `max_len` characters keeping the TAIL (closest to the reported problem) when longer."""
    snippet = re.sub(r"\s+", " ", original_text[start_pos:end_pos]).strip()
    if len(snippet) > max_len:
        snippet = "..." + snippet[-(max_len - 3):]
    return snippet


def no_from_where_violations(sql_text):
    """Return a list of (line_number, excerpt) for `INSERT ... SELECT <literals> WHERE ...`
    statements that have no FROM clause — illegal in GoogleSQL ("Query without FROM clause cannot
    have a WHERE clause") and, per this module's KNOWN, VERIFIED LIMITATION, invisible to
    `bq query --dry_run` whenever it follows a DDL statement earlier in the same script.

    Operates on a comment-, string-literal-, AND backtick-identifier-blanked copy of `sql_text` (see
    `_masked_sql` / `_blank_string_literals`, built on `lib.sql_files.strip_sql_comments`) so a
    keyword match can never land inside a `-- FROM ...` doc comment, inside the English prose of a
    quoted decision note or description, or inside a backtick-quoted identifier that happens to
    contain a `'`, `"`, or `;` (e.g. `` `o'clock` ``, `` `c;d` ``). Both blanking passes preserve every
    character's position and every newline, so `line_number` is computed EXACTLY against the masked
    text and is correct for the ORIGINAL file — not a best-effort estimate.

    For each `INSERT INTO <table> (<cols>)? SELECT ...` (an `INSERT ... VALUES` statement is a
    different shape entirely and is skipped — see `_scan_insert_select`), this walks forward tracking
    paren depth from 0 and flags a violation only when the statement's own TOP-LEVEL `WHERE` is
    reached before its top-level `FROM`. A nested `WHERE NOT EXISTS (SELECT 1 FROM t WHERE ...)` — the
    idempotency guard's inner half — sits one paren level deeper and never confuses this, and neither
    does a CTE or a subquery earlier in the same SELECT list.
    """
    masked = _masked_sql(sql_text)
    violations = []
    for m in _INSERT_INTO_RE.finditer(masked):
        kind, where_pos = _scan_insert_select(masked, m.end())
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
        print("::error::check_sql_dryrun STATIC LINT — found `INSERT ... SELECT <literals> WHERE ...` "
              "with NO FROM clause. THE RULE: GoogleSQL rejects a SELECT expression-list that carries a "
              "WHERE with no FROM (\"Query without FROM clause cannot have a WHERE clause\") — this is "
              "the exact idempotency-guard idiom used throughout bigquery/*.sql, just missing its FROM. "
              "WHY A DRY-RUN CANNOT CATCH THIS: BigQuery's script dry-run stops semantically analyzing "
              "a script after its first DDL statement (verified 2026-08-03 — see this module's "
              "docstring), so a file with a leading CREATE/ALTER/DROP can dry-run CLEAN while a later "
              "statement like this one would fail at real apply time. THE FIX: add `FROM (SELECT 1)` "
              "between the SELECT's literal list and its WHERE, matching the correct form already used "
              "elsewhere in bigquery/*.sql (e.g. `SELECT ... FROM (SELECT 1) WHERE NOT EXISTS (...)`).")
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

    syntax_errs, tolerated, unknown, ok = [], [], [], 0
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
        else:
            unknown.append((f, first))

    print(f"SQL dry-run: {len(files)} file(s) — {ok} parse-validated, {len(tolerated)} tolerated "
          f"(permission/reference), {len(unknown)} inconclusive, {len(syntax_errs)} SYNTAX ERROR(S).")
    ddl_files = [f for f in files if f in file_texts and _contains_ddl(file_texts[f])]
    if ddl_files:
        print(f"NOTE: {len(ddl_files)} of {len(files)} file(s) contain a DDL statement (CREATE/ALTER/"
              f"DROP) — BigQuery's script dry-run does NOT semantically analyze any statement AFTER the "
              f"first DDL in a script (verified 2026-08-03; see this module's docstring). "
              f"'Parse-validated' proves those files PARSE, not that they will APPLY cleanly — the "
              f"no-FROM-WHERE static lint above closes one such gap, but not every possible one.")
    for f in tolerated:
        print(f"  - tolerated (read-only SA can't dry-run this DDL, or a not-yet-live sibling ref): {f}")
    for f, e in unknown:
        print(f"  - inconclusive / non-blocking: {f} :: {e}")
    for f, e in syntax_errs:
        print(f"  ✗ SYNTAX ERROR (blocks merge): {f} :: {e}")

    if syntax_errs:
        print("\nPARSE FAILURE — a bigquery/*.sql file would abort at parse time on apply (the exact class "
              "that reached live apply 2026-07-17). Fix the syntax before merge.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

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

Usage:  python scripts/check_sql_dryrun.py <file.sql> [<file.sql> ...]
Requires the `bq` CLI authed (WIF in CI; local gcloud otherwise). Exit 0 = no syntax errors (or nothing
to check); exit 1 = at least one file has a syntax error, or the canary self-check failed.
"""
import os
import subprocess
import sys

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

    print(f"SQL dry-run: {len(files)} file(s) — {ok} validated, {len(tolerated)} tolerated (permission/"
          f"reference), {len(unknown)} inconclusive, {len(syntax_errs)} SYNTAX ERROR(S).")
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

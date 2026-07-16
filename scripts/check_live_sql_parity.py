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

Usage:  python scripts/check_live_sql_parity.py --project stock-trading-498512
        python scripts/check_live_sql_parity.py --offline   # parser self-check only, no bq calls
        python scripts/check_live_sql_parity.py --project stock-trading-498512 --json-out /tmp/findings.json
"""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.bq_json import parse_bq_json_stdout

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")

# A genuine top-level statement starts at column 0 (^, re.MULTILINE) — an indented occurrence
# (e.g. bigquery/17_restore_drill.sql's "CREATE OR REPLACE TABLE ..." embedded inside a FORMAT()
# string literal passed to EXECUTE IMMEDIATE) must NOT match.
CREATE_STMT = re.compile(
    r"^CREATE\s+OR\s+REPLACE\s+(VIEW|PROCEDURE|TABLE FUNCTION)\s+`([\w-]+)\.(\w+)\.(\w+)`",
    re.MULTILINE,
)


def numbered_sql_files():
    """bigquery/NN_*.sql files in NUMERIC apply-order (not lexical — NN is zero-padded to 2 digits
    today, but sort by the leading integer explicitly so this stays correct if that ever changes)."""
    files = []
    for fn in os.listdir(BIGQUERY_DIR):
        m = re.match(r"^(\d+)_.*\.sql$", fn)
        if m:
            files.append((int(m.group(1)), os.path.join(BIGQUERY_DIR, fn)))
    return [path for _, path in sorted(files)]


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
    # Find the end of this statement: the next top-level CREATE_STMT, or end of file.
    next_m = CREATE_STMT.search(txt, start + 1)
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
        # The first standalone " AS " after the CREATE line's closing backtick/paren. Split on the
        # last-preceding-newline-terminated " AS" to avoid matching an "AS" inside a column alias
        # on the same preamble line (rare in this codebase's style, but the split targets the AS
        # that starts the SELECT/body, identified as the first "AS\n" or "AS " immediately
        # followed by whitespace+SELECT/WITH on the next non-blank content).
        m = re.search(r"\bAS\b\s*\n", stmt)
        if not m:
            m = re.search(r"\bAS\b(?=\s)", stmt)
        if not m:
            return None
        body = stmt[m.end():]

    body = normalize_tail(body)
    if obj_type == "TABLE FUNCTION":
        # The outer wrapping ")" that closes the function's parameter list is part of the
        # preamble captured differently per call site; TABLE FUNCTION bodies in this repo are a
        # single AS ( ... ) wrapper — strip one matching outer paren pair if present.
        stripped = body.strip()
        if stripped.startswith("(") and stripped.endswith(")"):
            body = stripped[1:-1]
    return body.strip()


def collapse(s):
    return " ".join(s.split()) if s else s


def find_final_definitions():
    """{(dataset, name): (obj_type, project, source_file, body)} — the LAST apply-in-order
    definition of each object across bigquery/*.sql."""
    final = {}
    for path in numbered_sql_files():
        txt = open(path, encoding="utf-8").read()
        for m in CREATE_STMT.finditer(txt):
            obj_type, project, dataset, name = m.groups()
            body = extract_body(txt, m.start(), obj_type)
            if body is None:
                continue
            final[(dataset, name)] = (obj_type, project, os.path.basename(path), body)
    return final


def bq(sql, project):
    try:
        out = subprocess.run(
            ["bq", "--project_id=" + project, "--quiet", "--headless", "--format=json",
             "query", "--use_legacy_sql=false", sql],
            capture_output=True, text=True, timeout=600,
        )
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"bq query timed out after {e.timeout}s: {sql[:120]}") from e
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return parse_bq_json_stdout(out.stdout)


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


def write_json_out(json_out_path, findings, missing_live):
    """Write the --json-out findings file (RES-3 step 1, live-sql-parity self-heal audit
    2026-07-16). `findings` are structured mismatch dicts (dataset/name/object_type/source_file);
    `missing_live` (lookup failures) go ONLY into "skipped", never "findings" -- a lookup failure
    is not evidence of drift and must never be treated as a self-heal candidate."""
    import json
    from datetime import datetime, timezone

    payload = {
        "checked_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "findings": findings,
        "skipped": missing_live,
    }
    with open(json_out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")


def main():
    offline = "--offline" in sys.argv
    project = "stock-trading-498512"
    json_out = None
    for i, a in enumerate(sys.argv):
        if a == "--project" and i + 1 < len(sys.argv):
            project = sys.argv[i + 1]
        if a == "--json-out" and i + 1 < len(sys.argv):
            json_out = sys.argv[i + 1]

    final = find_final_definitions()
    print(f"Parsed {len(final)} final-effective object definitions from bigquery/*.sql.")
    if offline:
        print("--offline: parser structure check only, no live comparison performed.")
        return 0

    mismatches, findings, missing_live, checked = [], [], [], 0
    for (dataset, name), (obj_type, _obj_project, source_file, body) in sorted(final.items()):
        try:
            # Use the CLI-supplied --project (default stock-trading-498512), not the project parsed
            # from the object's own CREATE statement text, so --project is an actual, honored
            # override rather than a parsed-but-ignored argument.
            live_body = live_definition(project, dataset, name, obj_type)
        except Exception as e:
            missing_live.append(f"{dataset}.{name} ({source_file}): live lookup failed: {e}")
            continue
        if live_body is None:
            missing_live.append(f"{dataset}.{name} ({source_file}): no live object found")
            continue
        checked += 1
        # normalize_tail applied to the live body too (RES-3 step 0b) -- live view/routine
        # definitions retain trailing comments the repo-side extraction already strips, a second
        # never-converging false-positive class alongside the PROCEDURE-wrapper bug above.
        if collapse(body) != collapse(normalize_tail(live_body)):
            mismatches.append(f"{dataset}.{name} — live definition does NOT match the final "
                              f"effective definition in {source_file}")
            findings.append({"dataset": dataset, "name": name, "object_type": obj_type,
                              "source_file": source_file})

    print(f"Compared {checked} objects against live BigQuery; {len(mismatches)} mismatched, "
          f"{len(missing_live)} could not be checked.")
    for m in missing_live:
        print(f"  - skipped: {m}")
    for m in mismatches:
        print(f"  ✗ DRIFT: {m}")

    if json_out:
        write_json_out(json_out, findings, missing_live)

    if mismatches:
        print("\nLIVE SQL PARITY FAILED — re-apply the final-effective bigquery/*.sql definition "
              "for the listed object(s) via the BigQuery MCP/console.")
        return 1
    print("OK: every checked object's live definition matches its final-effective bigquery/*.sql source.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

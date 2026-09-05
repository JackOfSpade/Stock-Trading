#!/usr/bin/env python3
"""Coverage check: which live state/analytics/perf VIEWs have neither a dbt model nor a declared
dbt source (2026-07-14 self-improvement audit finding).

WHY. scripts/dbt_parity.py only proves row-level parity for views that already HAVE a dbt model —
it has no way to notice a bigquery/*.sql view that was never ported or declared out-of-scope. A
reproducible count (this script) found 70 of 113 live state/analytics/perf views (62%) with no dbt
presence at all, including several pure-SELECT views feeding the autonomous Strategy Arsenal
lifecycle's readiness/kill gates that therefore have ZERO row-level parity protection. This is a
coverage gap, not a correctness bug: a view is legitimately "out of scope" if it depends on
ML.*/AI.*/VECTOR_SEARCH (dbt/README.md's own stated criterion for what dbt owns) or is procedure-
maintained — this script does not try to judge that; it only prints the uncovered list so a human
can triage "port it" vs "declare it out of scope" for each one.

Read-only, no BigQuery/dbt CLI needed — pure text parsing of files already in the repo.

Usage:  python scripts/check_dbt_view_coverage.py     # exit 0 if fully covered, 1 + list if not
Wired BLOCKING in .github/workflows/ci.yml's `checks` job (step "dbt view coverage (ENFORCING as of
2026-09-01 — backlog is zero)", path-gated via `dbt_needed` on bigquery/**, dbt/** or
requirements-ci.txt), and re-run against main's merged tip by auto-merge-claude.yml's post-merge
coverage check. It was advisory (`|| true`) until 2026-09-01, when the 102-view backlog was burned
down to zero — a permanently-red advisory is indistinguishable from a broken one, so this earns its
keep instead by failing the build on a NEW live view with no dbt model and no source declaration.
There is still no baseline/allowlist here (unlike check_cadence/roster/autonomy_consistency.py): the
uncovered list is printed in full, and today it is empty. A bug in THIS file therefore reddens CI —
weigh changes accordingly.
"""
import os
import re
import sys

try:
    import yaml  # noqa: F401 — kept only for this early, actionable failure message; the actual
    # parsing below goes through lib.textio.load_yaml() (2026-07-29), which imports yaml itself and
    # would raise the SAME missing-dependency error, just as a bare traceback instead of this one.
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

from lib.sql_files import DBT_DATASETS, numbered_sql_files, strip_sql_comments
from lib.textio import load_yaml, read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")
DBT_MODELS_DIR = os.path.join(ROOT, "dbt", "models")
DBT_SOURCES_YML = os.path.join(ROOT, "dbt", "models", "sources.yml")

# dataset folder name == BigQuery dataset name, for both bigquery/*.sql views and dbt/models/*/*.sql.
# DEDUP (sql-parity#0, 2026-08-31 code-quality pass): this used to be its own locally-declared
# tuple, `("state", "analytics", "perf")`, duplicating dbt_parity.py's `DATASET_FOLDERS` — same
# three datasets, different name, different order. Now shared via scripts/lib/sql_files.py's
# DBT_DATASETS. The element order below (state, perf, analytics — dbt_parity.py's original order,
# not this file's prior alphabetical-ish one) is a no-op for THIS script: every use of DATASETS
# here is a for-loop feeding a `set` or an `in` membership test, and every dataset-bearing list
# this script prints is already routed through `sorted()` at the print site (main()'s
# `uncovered = sorted(live - covered)`), so this script's observable output does not depend on
# iteration order — see sql_files.py's docstring for the caller (dbt_parity.py) that DOES depend
# on it, which is why that caller's order was the one kept.
DATASETS = DBT_DATASETS

# ANCHORED at column 0 (^, re.MULTILINE) — 2026-09-02 adversarial review. Before this fix these two
# matched CREATE OR REPLACE VIEW / DROP VIEW ANYWHERE in the comment-stripped text, with no defense
# against a string literal: check_live_sql_parity.py's sibling CREATE_STMT/DROP_STMT regexes already
# anchor the same way, specifically so a CREATE/DROP embedded in a FORMAT()/EXECUTE IMMEDIATE payload
# (the documented bigquery/17_restore_drill.sql idiom) can never match — see that module's own
# "KNOWN, ACCEPTED LIMIT" comment. Reproduced live here: a file whose only top-level statement is a
# PROCEDURE containing `EXECUTE IMMEDIATE "CREATE OR REPLACE VIEW ...`stock-trading-498512.state.x`
# AS SELECT 1";` registered state.x as a phantom "live view" — an object never actually created by a
# real top-level DDL statement, just referenced inside a dynamic-SQL string. That phantom then fed
# main()'s `uncovered = sorted(live - covered)` as pure noise in a report whose whole stated value
# (module docstring) is "a trustworthy count." A genuine top-level CREATE/DROP VIEW always starts a
# line at column 0 in this repo's DDL, so the anchor alone closes the reproduced case: the payload
# above sits indented inside a quoted string, never at column 0. Residual, deliberately-accepted
# limit (matching DROP_STMT's own precedent): a column-0 CREATE/DROP VIEW inside a TRIPLE-quoted,
# multi-line EXECUTE IMMEDIATE string would still match — no string-literal masking is added here to
# close that, because today's only triple-quoted EXECUTE IMMEDIATE blocks (bigquery/75) contain only
# EXPORT DATA, never a column-0 CREATE/DROP, and lib.sql_files has no literal-masking helper to reuse
# (strip_sql_comments() deliberately copies literals verbatim rather than masking them).
VIEW_DDL = re.compile(
    r"^CREATE\s+OR\s+REPLACE\s+VIEW\s+`stock-trading-498512\.(state|analytics|perf)\.(\w+)`",
    re.IGNORECASE | re.MULTILINE,
)
DROP_VIEW_DDL = re.compile(
    r"^DROP\s+VIEW\s+(?:IF\s+EXISTS\s+)?`stock-trading-498512\.(state|analytics|perf)\.(\w+)`",
    re.IGNORECASE | re.MULTILINE,
)


def live_views():
    """(dataset, name) for every active VIEW across bigquery/*.sql in NUMERIC apply order.
    A view created in an earlier file and dropped in a later file is not live.

    BUG FIX (codebase audit 2026-07-26): this used to walk `sorted(os.listdir(BIGQUERY_DIR))` —
    LEXICAL order, which agreed with apply order only while every file number shared the same
    digit-width. Once bigquery/ grew past 99 files, lexical sort put "100_..." (and every other
    3-digit file) BEFORE "10_...", "75_...", "92_...", so a later-numbered DROP VIEW (e.g.
    bigquery/108_park_allocator_immediate_binding.sql) was applied to `found` BEFORE the earlier-
    numbered CREATE OR REPLACE VIEW of the same name (bigquery/75_.../92_...) that this script's
    own apply-order model says comes first — the CREATE then "won" the discard()/add() race and 3
    already-dropped views (state.park_allocator_promotion_readiness, state.park_switch_budget,
    state.park_control_latest) were reported live. numbered_sql_files() (scripts/lib/sql_files.py,
    already used by check_live_sql_parity.py and dbt_parity.py) sorts by the parsed leading
    integer instead, so this now applies CREATE/DROP in the same order the objects are actually
    (re-)created live."""
    found = set()
    numbered = numbered_sql_files(BIGQUERY_DIR)
    # An UNNUMBERED bigquery/*.sql has no declared apply position, so numbered_sql_files() excludes it.
    # Before the 2026-07-26 consolidation this function scanned every *.sql regardless of prefix, so
    # dropping them silently would be a scope narrowing in a COVERAGE scanner — a view could stop being
    # reported just because its file lacked an NN_ prefix, which is the same silent-skip class this
    # audit was closing elsewhere (adversarial review, codebase audit 2026-07-26). There are none today
    # (the NN_ convention is universal — see bigquery/README.md), so instead of guessing an apply
    # position for one, scan it LAST and say so out loud: its CREATE/DROP ordering relative to the
    # numbered files is genuinely undefined, and that is a repo-layout problem to fix, not to paper over.
    numbered_paths = {path for _n, path in numbered}
    unnumbered = sorted(
        os.path.join(BIGQUERY_DIR, fn) for fn in os.listdir(BIGQUERY_DIR)
        if fn.endswith(".sql") and os.path.join(BIGQUERY_DIR, fn) not in numbered_paths
    )
    if unnumbered:
        print(f"WARNING: {len(unnumbered)} bigquery/*.sql file(s) have no NN_ apply-order prefix and are "
              f"scanned LAST, with undefined CREATE/DROP ordering vs the numbered files: "
              f"{[os.path.basename(p) for p in unnumbered]}")
    for path in [p for _n, p in numbered] + unnumbered:
        if os.path.isdir(path):
            continue
        # BUG FIX (2026-07-29): VIEW_DDL/DROP_VIEW_DDL used to match raw file text with no comment
        # handling — the same gap confirmed live in check_superseded_markers.py's OBJECT_DDL (a
        # `-- CREATE OR REPLACE TABLE ...` doc-comment line, bigquery/02_ai_layer.sql:23, parsed as a
        # real definition there). No commented-out VIEW DDL for a state/analytics/perf object exists
        # in the tree today, so this was latent here rather than already wrong, but it's the same
        # class of bug and shares the same fix: strip comments (scripts/lib/sql_files.py) before
        # matching, consolidated so a future fix to one caller can't be forgotten in the other.
        txt = strip_sql_comments(read_text(path))
        # CREATE and DROP are applied in TEXTUAL ORDER WITHIN EACH FILE (quality pass 2026-08-22).
        # This used to run two separate whole-file loops — every CREATE first, then every DROP —
        # so a DROP always won over a CREATE in the same file no matter which came later in the
        # text. A view DROPped and then re-CREATEd further down one file (real apply-in-order
        # semantics leave it LIVE) was therefore reported as not live, silently vanishing from both
        # the counted-live total and the uncovered list, since a set-difference against a set it was
        # never added to cannot flag it either way.
        #
        # check_live_sql_parity.py's find_final_definitions() already merges the two event kinds by
        # match position for exactly this reason and has a regression test for it
        # (test_drop_then_create_same_file_leaves_object_expected); this sibling scanner had not
        # adopted it until the 2026-08-22 pass above. Latent on today's tree — no file both creates
        # and drops the same view — and the impact was bounded, when this was written, by the script
        # being advisory-only. That mitigation is GONE (2026-09-01: it now BLOCKS the build — see the
        # module docstring), so a wrong answer here strands branches, which only sharpens the original
        # point: a divergence between two scanners that must agree about what is live is the kind that
        # goes unnoticed until it matters.
        events = [(m.start(), True, m.group(1), m.group(2)) for m in VIEW_DDL.finditer(txt)]
        events += [(m.start(), False, m.group(1), m.group(2)) for m in DROP_VIEW_DDL.finditer(txt)]
        for _pos, is_create, dataset, name in sorted(events, key=lambda e: e[0]):
            if is_create:
                found.add((dataset, name))
            else:
                found.discard((dataset, name))
    return found


def dbt_model_names():
    """(dataset, name) for every dbt/models/<dataset>/*.sql model file (excluding schema.yml)."""
    found = set()
    for dataset in DATASETS:
        d = os.path.join(DBT_MODELS_DIR, dataset)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".sql"):
                found.add((dataset, fn[:-4]))
    return found


def dbt_source_names():
    """(dataset, name) for every table declared under a dbt source block whose (possibly-overridden)
    dataset — spelled `schema:` (dbt's canonical key) or `dataset:` (its BigQuery alias), else the
    block's own `name:` — is one of state/analytics/perf.

    KEY PRECEDENCE FIX (2026-09-04 quality pass). This read `src.get("dataset") or src.get("name")`,
    honouring ONLY the alias. dbt's own resolution is the authority: UnparsedSourceDefinition declares
    the field as `schema` (there is no `dataset` field), and dbt/parser/schemas.py runs
    `credentials.translate_aliases(data, recurse=True)` over every source dict, where dbt-bigquery's
    _ALIASES maps legacy `dataset` -> `schema`. So both spellings are valid input, `schema:` is the
    one dbt's docs use, and a source written that way resolved to the BLOCK NAME here — which is not
    in DATASETS for the `- name: state_external` / `schema: state` shape this repo already uses with
    the other spelling, so every table under it silently dropped out of `covered` and its views
    reddened this now-BLOCKING gate as falsely uncovered (the mirror shape, `- name: state` /
    `schema: other`, fails OPEN instead, crediting coverage dbt does not provide). Zero blocks in
    dbt/models/sources.yml spell it `schema:` today, so this is a strict widening with no verdict
    change. scripts/gen_dbt_port.py's source_index() is the other reader of the same file and already
    used this precedence — see its docstring for why the two must not drift apart again.

    Uses lib.textio.load_yaml() (2026-07-29). This is a small BEHAVIOR FIX, not the pure no-op
    refactor it was first described as: for its whole committed history this function was the bare
    one-liner `yaml.safe_load(open(DBT_SOURCES_YML, ...)) or {}` with NO missing-file guard, so an
    absent dbt/models/sources.yml raised an uncaught FileNotFoundError out of main() rather than
    reporting zero dbt-covered views. (An unlanded in-flight pass had just hand-rolled an
    `os.path.exists()` early-return here — that hand-rolled guard is exactly the duplication
    load_yaml() exists to collapse, which is why it never landed separately.) Now: a missing file
    yields `{}`, `doc.get("sources", []) or []` iterates zero times, and `found` stays empty. The
    empty-file and comments-only cases are unchanged — `or {}` already covered those."""
    found = set()
    doc = load_yaml(DBT_SOURCES_YML)
    for src in doc.get("sources", []) or []:
        # `.get("name")`, not `src["name"]`: a malformed block degrades to a miss rather than raising
        # a KeyError inside a blocking gate (its sibling reader, gen_dbt_port.py's source_index(), is
        # a GENERATOR and deliberately keeps the loud spelling — see that function's docstring).
        dataset = src.get("schema") or src.get("dataset") or src.get("name")
        if dataset not in DATASETS:
            continue
        for tbl in src.get("tables", []) or []:
            name = tbl.get("name")
            if name:
                found.add((dataset, name))
    return found


def main():
    live = live_views()
    covered = dbt_model_names() | dbt_source_names()
    uncovered = sorted(live - covered)

    print(f"dbt view coverage: {len(live)} live state/analytics/perf views, "
          f"{len(covered)} dbt-covered (model or source), {len(uncovered)} uncovered.")
    if uncovered:
        print("\nUncovered (neither a dbt model nor a declared dbt source) — for each, either port "
              "it as a dbt model, or add it to dbt/models/sources.yml as an explicitly out-of-scope "
              "source (e.g. it depends on ML.*/AI.*/VECTOR_SEARCH, or is procedure-maintained):")
        for dataset, name in uncovered:
            print(f"  - {dataset}.{name}")
        return 1
    print("OK: every live state/analytics/perf view is either a dbt model or a declared dbt source.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

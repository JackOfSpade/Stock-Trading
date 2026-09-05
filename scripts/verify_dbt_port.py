#!/usr/bin/env python3
"""Prove a dbt model is a FAITHFUL port of its canonical bigquery/*.sql view body.

WHY THIS EXISTS (dbt view-coverage burn-down, 2026-08-22). dbt/ is a PARALLEL-RUN port: every model
must re-express a bigquery/*.sql view exactly, and an unfaithful port is worse than no port at all --
it reports false DRIFT against live, or (worse) silently blesses a model that is not the view it
claims to mirror. scripts/dbt_parity.py proves that against LIVE data, but it needs BigQuery
credentials, costs one query per model, and therefore only runs in CI.

This proves the same property OFFLINE and for free: `dbt compile` renders ref()/source() into
fully-qualified identifiers, so the compiled text IS what dbt would run, and comparing it to the
canonical view body as normalized TOKEN STREAMS is an exact equivalence check. Use it when porting a
view (before pushing anything at live-parity cost), and to re-check a model after editing it.

Token-equal here implies dbt_parity.py must also agree, because the two sides are the same SQL.

Compiles the model offline (dbt compile renders ref()/source() into fully-qualified identifiers),
then compares the compiled SQL against the canonical body as NORMALIZED TOKEN STREAMS:
comments stripped, whitespace collapsed, and BigQuery's two identifier-quoting styles
(`proj.ds.name` vs `proj`.`ds`.`name`) unified.

A token-equal result means dbt_parity.py's live EXCEPT comparison must also agree -- the compiled
text IS what dbt would run. Anything else is printed as a unified diff for a human to judge.

Usage:
  verify_dbt_port.py <model_name> [<model_name> ...]   # compile just these, then compare
  verify_dbt_port.py --all                             # every model under dbt/models/{state,perf,analytics}
  verify_dbt_port.py --all --use-compiled              # skip the compile; reuse dbt/target/compiled

`--use-compiled` exists so CI can run this for FREE. The warehouse-validation job already runs
`dbt compile`; re-compiling here would duplicate ~a minute of work for no new information. It is
also the mode that makes this affordable as an ALWAYS-ON gate over all ~186 models, which is what
lets `scripts/dbt_parity.py` keep its expensive LIVE row comparison bounded (dbt/parity_live_scope.yml).
With --use-compiled, a model with no compiled artifact is a FAILURE, not a skip: silently passing a
model nobody compiled is exactly the vacuous-green this gate exists to prevent.
"""
import difflib
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

from lib.dynload import load_module_from_path  # noqa: E402
from lib.sql_files import DBT_DATASETS  # noqa: E402

# The importlib "load a repo .py as a module" recipe this file used to carry as its own private
# _load_module_from_path() now lives in scripts/lib/dynload.py (cross-cutting dedup, quality pass
# 2026-09-04 -- it had grown three hand-copies: here, tests/conftest.py and scripts/gen_dbt_port.py).
# That function's rationale comment moved there VERBATIM and still governs: the helper must NOT come
# from tests/conftest.py, which does `import pytest` at module scope and would put a hard pytest
# dependency on this BLOCKING ci.yml step for the sake of a ~6-line helper. lib/dynload.py imports
# nothing but the stdlib, so nothing about that 2026-08-31 fix is undone here.
P = load_module_from_path("check_live_sql_parity", os.path.join(REPO, "scripts", "check_live_sql_parity.py"))
FINAL = P.find_final_definitions()


def canonical_body(dataset, name):
    d = FINAL.get((dataset, name))
    return d[3] if d else None


def normalize(sql):
    """Comment-stripped, quote-unified, whitespace-collapsed token stream."""
    # `proj`.`ds`.`name`  ->  `proj.ds.name`   (dbt's rendering vs the repo's literal style)
    sql = re.sub(r"`([^`]+)`\.`([^`]+)`\.`([^`]+)`", r"`\1.\2.\3`", sql)
    sql = re.sub(r"`([^`]+)`\.`([^`]+)`", r"`\1.\2`", sql)
    out = []
    for kind, val, _s, _e in P.sql_tokens(sql):   # drops comments; keeps literals verbatim
        if kind == "W":
            continue
        out.append(val if kind == "S" else val.upper())
    return out


def compiled_path(model):
    # DEDUP + BUG FIX (2026-09-02 audit): this used to hand-copy the dataset list as its own tuple
    # `("state", "analytics", "perf")` -- a THIRD, differently-ordered spelling of the same constant
    # all_model_names() below already imports as DBT_DATASETS. Order is provably irrelevant here
    # (this just tests os.path.exists per (ds, model) and returns on the first hit), so reusing the
    # canonical import is a pure drop-in -- but it closes a real latent gap: a dataset added to
    # DBT_DATASETS in the future would make all_model_names() enumerate models under it correctly
    # while this loop kept never looking there, silently misdiagnosing every model in the new
    # dataset as FAIL "no compiled output found" even after a correct `dbt compile`.
    for ds in DBT_DATASETS:
        p = os.path.join(REPO, "dbt", "target", "compiled", "stock_trading", "models", ds, f"{model}.sql")
        if os.path.exists(p):
            return ds, p
    return None, None


def resolve_profiles_dir():
    """(profiles_dir, owned) -- DBT_PROFILES_DIR to run `dbt compile` under, and whether THIS CALL
    created it. Respects an already-set env var (owned=False: not ours to delete, the caller does
    not own that directory), else materializes dbt/profiles.ci.yml -- the single checked-in CI
    profile ci.yml's `dbt` and `dbt-parity` jobs already treat as canonical (see that file's own
    header) -- into a fresh tempdir as profiles.yml (owned=True: the caller should rmtree it).

    BUG FIX (2026-08-31 code-quality pass): this used to hardcode DBT_PROFILES_DIR="/tmp/dbtprof",
    a path nothing in the repo ever created or populated (`grep -rn dbtprof .` had exactly one
    hit: that line) -- `dbt compile` failed immediately with "Invalid value for '--profiles-dir'"
    on any checkout without a coincidentally pre-existing /tmp/dbtprof. Every other dbt-invoking
    path (ci.yml, live-sql-parity.yml) instead does
    `mkdir -p ~/.dbt && cp dbt/profiles.ci.yml ~/.dbt/profiles.yml`; this mirrors that convention
    with a private tempdir rather than the shared ~/.dbt so two concurrent porting sessions can't
    race on the same profiles.yml.

    LEAK FIX (2026-09-02 audit): the tempdir this function creates was never cleaned up -- nothing
    in this file called shutil.rmtree() or registered any cleanup, so every invocation of the
    interactive porting workflow this function exists for ("Use it when porting a view ... and to
    re-check a model after editing it" -- this module's own docstring) left one more orphaned
    /tmp/dbtprof-XXXXXXXX/ behind, unbounded. Returning the ownership flag lets main() clean up only
    the directory THIS call created, never a caller-supplied DBT_PROFILES_DIR this function does not
    own."""
    existing = os.environ.get("DBT_PROFILES_DIR")
    if existing:
        return existing, False
    profiles_dir = tempfile.mkdtemp(prefix="dbtprof-")
    shutil.copy(os.path.join(REPO, "dbt", "profiles.ci.yml"), os.path.join(profiles_dir, "profiles.yml"))
    return profiles_dir, True


def all_model_names():
    """Every model under dbt/models/{state,perf,analytics} (model names are globally unique).

    DBT_DATASETS is now imported once at module level (2026-09-02 audit) rather than re-imported
    locally here every call -- compiled_path() above needed the same constant and used to hand-copy
    it as a differently-ordered tuple instead of reusing this import; see that function's comment."""
    out = []
    for ds in DBT_DATASETS:
        d = os.path.join(REPO, "dbt", "models", ds)
        if os.path.isdir(d):
            out += [fn[:-4] for fn in sorted(os.listdir(d)) if fn.endswith(".sql")]
    return out


def main(argv):
    # FLAG HANDLING (2026-09-04 quality pass). This used to be membership tests alone, so ANY
    # unrecognized --flag was silently ignored — and with no positional model, silently meant
    # --all: `verify_dbt_port.py --help` ran a real ~186-model dbt compile instead of printing
    # the Usage block the docstring advertises. Recognized flags stay membership-tested (no
    # argparse — CI's `--all --use-compiled` invocation in ci.yml and auto-merge-claude.yml is
    # unchanged); everything else --prefixed is now a loud exit 2, because a typo like `--al`
    # falling through to the full-fleet path is exactly the silent fail-open this file's own
    # --use-compiled note ("a model with no compiled artifact is a FAILURE, not a skip") rejects.
    usage = __doc__[__doc__.index("Usage:"):__doc__.index("`--use-compiled`")].rstrip()
    if "-h" in argv or "--help" in argv:
        print(usage)
        return 0
    unknown = [a for a in argv if a.startswith("--") and a not in ("--all", "--use-compiled")]
    if unknown:
        print(f"unknown flag(s): {' '.join(unknown)}\n{usage}")
        return 2
    use_compiled = "--use-compiled" in argv
    models = [a for a in argv if not a.startswith("--")]
    if "--all" in argv or not models:
        models = all_model_names()
    if not models:
        print("no models found under dbt/models/ — refusing to report OK on zero comparisons")
        return 2

    if not use_compiled:
        profiles_dir, owned = resolve_profiles_dir()
        env = dict(os.environ, DBT_PROFILES_DIR=profiles_dir)
        try:
            r = subprocess.run(
                ["dbt", "compile", "--target", "ci", "--select", " ".join(models)],
                cwd=os.path.join(REPO, "dbt"), env=env, capture_output=True, text=True, timeout=600)
        finally:
            # Clean up only the tempdir THIS call created -- never a caller-supplied
            # DBT_PROFILES_DIR (owned=False), which this function does not own. See
            # resolve_profiles_dir()'s "LEAK FIX" note: this used to never run at all.
            if owned:
                shutil.rmtree(profiles_dir, ignore_errors=True)
        if r.returncode != 0:
            print("dbt compile FAILED:\n" + (r.stdout or "")[-3000:])
            return 2

    bad = 0
    for m in models:
        ds, path = compiled_path(m)
        if not path:
            print(f"FAIL {m}: no compiled output found")
            bad += 1
            continue
        with open(path, encoding="utf-8") as f:
            comp = f.read()
        canon = canonical_body(ds, m)
        if canon is None:
            print(f"FAIL {m}: no canonical bigquery definition for {ds}.{m}")
            bad += 1
            continue
        a, b = normalize(canon), normalize(comp)
        if a == b:
            print(f"OK   {m:44} ({ds}) token-identical to canonical")
        else:
            bad += 1
            print(f"DIFF {m:44} ({ds})  canonical={len(a)} tok, compiled={len(b)} tok")
            for line in list(difflib.unified_diff(a, b, "canonical", "compiled", lineterm="", n=2))[:40]:
                print("      " + line)
    print(f"\n{len(models) - bad}/{len(models)} faithful")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

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
import importlib.util
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "scripts"))


def _load_module_from_path(name, *rel_parts):
    """Local copy of tests/conftest.py's load_module_from_path (bug fix, 2026-08-31 code-quality
    pass): this was previously `from conftest import load_module_from_path` after inserting
    tests/ onto sys.path, making this the only scripts/ file that reaches into tests/ -- and
    tests/conftest.py does `import pytest` at module scope, so it pulled in a hard pytest
    dependency purely as a side effect of wanting this ~6-line helper. Every sibling checker
    (check_live_sql_parity.py, dbt_parity.py, check_dbt_view_coverage.py, check_sql_dryrun.py) is
    self-contained; this restores that."""
    path = os.path.join(REPO, *rel_parts)
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


P = _load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")
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
    for ds in ("state", "analytics", "perf"):
        p = os.path.join(REPO, "dbt", "target", "compiled", "stock_trading", "models", ds, f"{model}.sql")
        if os.path.exists(p):
            return ds, p
    return None, None


def resolve_profiles_dir():
    """DBT_PROFILES_DIR to run `dbt compile` under: respect an already-set env var, else
    materialize dbt/profiles.ci.yml -- the single checked-in CI profile ci.yml's `dbt` and
    `dbt-parity` jobs already treat as canonical (see that file's own header) -- into a fresh
    tempdir as profiles.yml.

    BUG FIX (2026-08-31 code-quality pass): this used to hardcode DBT_PROFILES_DIR="/tmp/dbtprof",
    a path nothing in the repo ever created or populated (`grep -rn dbtprof .` had exactly one
    hit: that line) -- `dbt compile` failed immediately with "Invalid value for '--profiles-dir'"
    on any checkout without a coincidentally pre-existing /tmp/dbtprof. Every other dbt-invoking
    path (ci.yml, live-sql-parity.yml) instead does
    `mkdir -p ~/.dbt && cp dbt/profiles.ci.yml ~/.dbt/profiles.yml`; this mirrors that convention
    with a private tempdir rather than the shared ~/.dbt so two concurrent porting sessions can't
    race on the same profiles.yml."""
    existing = os.environ.get("DBT_PROFILES_DIR")
    if existing:
        return existing
    profiles_dir = tempfile.mkdtemp(prefix="dbtprof-")
    shutil.copy(os.path.join(REPO, "dbt", "profiles.ci.yml"), os.path.join(profiles_dir, "profiles.yml"))
    return profiles_dir


def all_model_names():
    """Every model under dbt/models/{state,perf,analytics} (model names are globally unique)."""
    from lib.sql_files import DBT_DATASETS
    out = []
    for ds in DBT_DATASETS:
        d = os.path.join(REPO, "dbt", "models", ds)
        if os.path.isdir(d):
            out += [fn[:-4] for fn in sorted(os.listdir(d)) if fn.endswith(".sql")]
    return out


def main(argv):
    use_compiled = "--use-compiled" in argv
    models = [a for a in argv if not a.startswith("--")]
    if "--all" in argv or not models:
        models = all_model_names()
    if not models:
        print("no models found under dbt/models/ — refusing to report OK on zero comparisons")
        return 2

    if not use_compiled:
        env = dict(os.environ, DBT_PROFILES_DIR=resolve_profiles_dir())
        r = subprocess.run(
            ["dbt", "compile", "--target", "ci", "--select", " ".join(models)],
            cwd=os.path.join(REPO, "dbt"), env=env, capture_output=True, text=True, timeout=600)
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

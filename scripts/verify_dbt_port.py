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

Usage: verify_port.py <model_name> [<model_name> ...]
"""
import difflib
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "scripts"))
sys.path.insert(0, os.path.join(REPO, "tests"))
from conftest import load_module_from_path  # noqa: E402

P = load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")
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


def main(models):
    env = dict(os.environ, DBT_PROFILES_DIR="/tmp/dbtprof")
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

#!/usr/bin/env python3
"""Generate a parallel-run dbt model from a canonical `bigquery/*.sql` view body.

WHY (dbt view-coverage burn-down, continued 2026-09-01). `scripts/check_dbt_view_coverage.py` had
102 live state/analytics/perf views with neither a dbt model nor a declared source. 101 of the 102
are pure SELECT and therefore portable; the port is MECHANICAL -- the only edit a faithful port makes
to the canonical body is substituting `ref()`/`source()` for fully-qualified object names. Doing that
by hand 101 times is exactly the kind of transcription work that produces silent, unfaithful ports,
so it is scripted here and PROVED by `scripts/verify_dbt_port.py` (offline `dbt compile` + normalized
token comparison against the same canonical body).

The substitution table is derived, never hand-kept:
  * a name that is (or will be) a dbt MODEL under dbt/models/{state,perf,analytics}  -> {{ ref('name') }}
  * a name declared in dbt/models/sources.yml                                         -> {{ source('src','name') }}
  * `analytics.fn_is_occ_option_symbol` -> left FULLY QUALIFIED. dbt has no ref() for a scalar UDF,
    and the existing ported models already reference it that way (dbt/README.md records this).
  * anything else -> reported as UNRESOLVED and NOT written, so a missing source declaration fails
    loudly here instead of surfacing later as a `dbt parse` error or an unfaithful port.

Usage:
  python scripts/gen_dbt_port.py --list                 # what is uncovered, and how each would resolve
  python scripts/gen_dbt_port.py --list state.foo       # dry-run THOSE views: same checks, no write
  python scripts/gen_dbt_port.py --all                  # write every resolvable uncovered view
  python scripts/gen_dbt_port.py state.foo analytics.bar
"""
import argparse
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

import yaml  # noqa: E402
from lib.dynload import load_module_from_path  # noqa: E402
from lib.sql_files import DBT_DATASETS  # noqa: E402

PROJECT = "stock-trading-498512"
MODELS_ROOT = os.path.join(REPO, "dbt", "models")
SOURCES_YML = os.path.join(MODELS_ROOT, "sources.yml")
# dbt has no ref() for a scalar UDF; ported models call it fully qualified (dbt/README.md).
UDF_PASSTHROUGH = {("analytics", "fn_is_occ_option_symbol")}

# NOT ported, by standing decision in dbt/README.md ("Deliberately NOT ported"): the body is not a
# pure SELECT -- it computes ML.DISTANCE over embeddings produced by a REMOTE MODEL, so dbt cannot
# own it and `dbt build` at cutover could not reproduce it. Declared in sources.yml instead, which
# is what "covered" means for an object dbt reads but must never build. Verified 2026-09-01 against
# the canonical body with comments STRIPPED (a first pass flagged two more on comment text alone --
# the regex-scans-its-own-comments trap this repo has hit before): this is the ONLY one of the 102
# uncovered views whose executable SQL touches ML./AI./VECTOR_SEARCH.
NOT_PORTED = {("analytics", "theater_independence")}


def _load(name, *rel):
    """Load REPO/<rel...> as a module named `name` (used for check_live_sql_parity.py and
    check_dbt_view_coverage.py, neither of which is an importable package).

    A thin wrapper over scripts/lib/dynload.py's shared loader since the 2026-09-04 quality pass --
    the importlib recipe it used to inline here (with `import importlib.util` buried in the body) was
    the third of three hand-copies, alongside tests/conftest.py's and scripts/verify_dbt_port.py's.
    The NAME and the `(name, *rel)` signature are deliberately kept: tests/test_gen_dbt_port.py
    monkeypatches `gdp._load` with a `fake_load(name, *rel)` stand-in to keep main() off the real
    checkers, so this is a call-site contract, not a private detail free to be renamed away."""
    return load_module_from_path(name, os.path.join(REPO, *rel))


def model_names():
    """{name} for every existing dbt model file (model names are globally unique in dbt)."""
    out = set()
    for ds in DBT_DATASETS:
        d = os.path.join(MODELS_ROOT, ds)
        if os.path.isdir(d):
            out |= {fn[:-4] for fn in os.listdir(d) if fn.endswith(".sql")}
    return out


def source_index():
    """{(dataset, table): source_name} from sources.yml.

    KEY PRECEDENCE, and its PAIR (2026-09-04 quality pass). `schema:` is dbt's canonical spelling for
    a source's dataset (UnparsedSourceDefinition declares `schema`, and dbt-bigquery's credential
    _ALIASES maps the legacy `dataset:` onto it before the source parser sees it), so both spellings
    are valid input and `schema` wins. scripts/check_dbt_view_coverage.py's dbt_source_names() is the
    OTHER reader of this same file and used to honour only `dataset:`, so a source block written the
    documented dbt way resolved here and was dropped there — it now uses the identical precedence.
    Change one and change the other: gen_dbt_port --list computes its `covered` set from that
    function while substituting refs from THIS one, so a divergence makes the two disagree about the
    same source block.

    Deliberately NOT routed through lib.textio.load_yaml() like its sibling: an ABSENT sources.yml
    must be a loud FileNotFoundError in a GENERATOR (a silently empty index would report every
    qualified name in every body as an unresolved ref), where in the coverage checker it correctly
    reports zero dbt-covered views. The `or {}` / `or []` guards below cover the other half of what
    load_yaml() provides — an empty document, or a bare `sources:` key, both of which yaml parses to
    None and neither of which used to survive the `.get()` below."""
    with open(SOURCES_YML, encoding="utf-8") as fh:
        doc = yaml.safe_load(fh) or {}
    idx = {}
    for src in doc.get("sources", []) or []:
        ds = src.get("schema") or src.get("dataset") or src["name"]
        for tbl in src.get("tables", []) or []:
            idx[(ds, tbl["name"])] = src["name"]
    return idx


# Both BigQuery quoting styles: `proj.ds.name` and `proj`.`ds`.`name`.
QUALIFIED = re.compile(
    r"`" + re.escape(PROJECT) + r"\.(\w+)\.(\w+)`"
    r"|`" + re.escape(PROJECT) + r"`\.`(\w+)`\.`(\w+)`"
)


def substitute(body, known_models, sources, self_name):
    """Return (new_body, unresolved). Never rewrites the object's own name."""
    unresolved = set()

    def repl(m):
        ds = m.group(1) or m.group(3)
        name = m.group(2) or m.group(4)
        if (ds, name) in UDF_PASSTHROUGH:
            return m.group(0)
        if name != self_name and ds in DBT_DATASETS and name in known_models:
            return "{{ ref('%s') }}" % name
        src = sources.get((ds, name))
        if src:
            return "{{ source('%s', '%s') }}" % (src, name)
        unresolved.add(f"{ds}.{name}")
        return m.group(0)

    return QUALIFIED.sub(repl, body), unresolved


# HEADER is stamped on EVERY generated port, including a REGENERATION of a port that has existed for
# weeks. It therefore must not assert anything this script cannot know at generation time. It used to
# open "Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence, so
# check_dbt_view_coverage.py reported it uncovered and it carried no port at all" — a hardcoded date
# and an origin story, both FALSE for any port that already existed. Found 2026-09-02 regenerating
# state/owner_confirmation_liveness.sql (a port added 2026-08-22), whose true header the operator then
# had to restore by hand, exactly as dbt/models/state/catchup_refire_readiness.sql's was on the same
# day. Provenance — when a port was added, and which canonical file it was REPOINTED from — is
# hand-maintained in the file and survives regeneration only if a human puts it back; this constant
# states only what is true of every run. Do not reintroduce a literal date here.
HEADER = (
    "-- Parallel-run dbt port of bigquery/{src}:{ds}.{name} — canonical source is that file until\n"
    "-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the\n"
    "-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical\n"
    "-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.\n"
    "-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put\n"
    "-- back by the person who regenerates it.\n"
)


def _structurally_eligible(v, final):
    """Would `v` (a "dataset.name" string) survive the NOT_PORTED / no-CREATE / not-a-VIEW skip
    branches in the per-target loop below, judging ONLY from `final` (find_final_definitions())?
    Does NOT check unresolved refs -- that can only be known after substitute() runs, so a v that
    passes this can still be skipped later for its own unresolved refs (see resolvable_targets())."""
    ds, name = v.split(".", 1)
    if (ds, name) in NOT_PORTED:
        return False
    ent = final.get((ds, name))
    return ent is not None and ent[0] == "VIEW"


def resolvable_targets(targets, final):
    """The subset of `targets` structurally eligible to be written this run -- i.e. every `targets`
    entry MINUS the ones that will hit the NOT_PORTED / no-CREATE / not-a-VIEW skip branches. Used to
    build `known_models` for substitute() so a same-batch view that will never be written cannot be
    ref()'d anyway (see main()'s "BUG" comment at its call site for the failure this closes)."""
    return [v for v in targets if _structurally_eligible(v, final)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("views", nargs="*")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    clsp = _load("check_live_sql_parity", "scripts", "check_live_sql_parity.py")
    cov = _load("check_dbt_view_coverage", "scripts", "check_dbt_view_coverage.py")
    final = clsp.find_final_definitions()
    sources = source_index()

    targets = args.views
    # `--list` DISCOVERS only when no views were named. BUG FIX (2026-09-04 quality pass): this was
    # `if args.all or args.list:`, so `--list state.foo` silently threw the named view away and
    # re-scanned for uncovered ones instead — reporting "would write 0, skipped 0" identically to a
    # bare `--list`. Since the coverage backlog reached zero (2026-09-01) `live_views() - covered` is
    # empty, so BOTH discovery flags now produce nothing and naming a view explicitly is the only
    # remaining use of this tool — with `--list` its only non-destructive one, the per-target loop's
    # `if args.list: ... continue` dry run below. `--all` still overrides named views unconditionally:
    # "write every resolvable uncovered view" is its documented meaning (see the module docstring's
    # Usage block), not a dry-run modifier.
    if args.all or (args.list and not targets):
        covered = cov.dbt_model_names() | cov.dbt_source_names()
        targets = [f"{ds}.{n}" for (ds, n) in sorted(cov.live_views() - covered)]

    # A view being ported may reference another view being ported in the same pass -- but ONLY if
    # that co-processed view will actually be WRITTEN this run. `known` used to be built from every
    # name in `targets` unconditionally, before the per-target loop below had checked whether each
    # one even survives the NOT_PORTED / no-CREATE / not-a-VIEW / unresolved-refs skip branches.
    #
    # BUG (dbt view-coverage burn-down, 2026-09-02 audit): a batch containing state.foo_helper (a
    # TABLE, so it hits the "not a VIEW" skip) and state.foo_derived (a VIEW whose body references
    # foo_helper) put "foo_helper" into `known` regardless of the skip. substitute() then rewrote
    # foo_derived's reference to `{{ ref('foo_helper') }}` -- a ref to a model that is never written
    # to disk. foo_derived.sql landed with a dangling ref, and `dbt compile`/`dbt parse` (including
    # verify_dbt_port.py's own compile step and CI's `dbt` job) failed on it with "depends on a node
    # named 'foo_helper' which was not found" -- with nothing in this script's own SKIP output
    # pointing at foo_derived as the file that would break. --list mode had the identical bug: it
    # runs the same substitute() call and would have reported "foo_derived: OK".
    #
    # Fix: pre-filter `targets` to the names that are STRUCTURALLY eligible (resolvable_targets():
    # not NOT_PORTED, has a live CREATE, and that CREATE is a VIEW) before folding them into `known`.
    # This closes 3 of the 4 skip categories exactly, since all three are knowable up front with no
    # dependency on substitute() itself. The 4th (a same-batch VIEW that is itself skipped for ITS
    # OWN unresolved refs, and is in turn referenced by a third same-batch view -- a two-hop cascade)
    # is a rarer, separate case that would need a small fixed-point loop to close fully; not
    # attempted here since it is not the scenario this fix targets. The per-target loop below still
    # walks the FULL `targets` list unchanged, so every SKIP message still prints exactly as before.
    known = model_names() | {v.split(".", 1)[1] for v in resolvable_targets(targets, final)}

    # LINT FIX (2026-09-02 audit): the `append(...); continue` one-liners below used to pack an
    # append and a `continue` onto the same physical line with a semicolon (ruff E702, part of the
    # E7 group this repo's pyproject.toml selects). Pre-existing on every branch in this loop, not
    # behavioral -- splitting each onto two lines changes nothing about which branch is taken or
    # what gets appended, it only lets `ruff check scripts/gen_dbt_port.py` actually pass.
    written, skipped = [], []
    for v in targets:
        ds, name = v.split(".", 1)
        if (ds, name) in NOT_PORTED:
            skipped.append((v, "NOT_PORTED (remote-model/ML backed) — belongs in sources.yml"))
            continue
        ent = final.get((ds, name))
        if ent is None:
            skipped.append((v, "no CREATE in bigquery/*.sql"))
            continue
        obj_type, _proj, srcfile, body = ent[0], ent[1], ent[2], ent[3]
        if obj_type != "VIEW":
            skipped.append((v, f"not a VIEW ({obj_type})"))
            continue
        new_body, unresolved = substitute(body, known, sources, name)
        if unresolved:
            skipped.append((v, "unresolved refs: " + ", ".join(sorted(unresolved))))
            continue
        if args.list:
            written.append((v, "OK"))
            continue
        path = os.path.join(MODELS_ROOT, ds, f"{name}.sql")
        header = HEADER.format(src=os.path.basename(srcfile), ds=ds, name=name)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(header + new_body.strip() + "\n")
        written.append((v, path))

    for v, why in skipped:
        print(f"SKIP  {v}: {why}")
    print(f"{'would write' if args.list else 'wrote'} {len(written)}, skipped {len(skipped)}")
    return 1 if skipped else 0


if __name__ == "__main__":
    raise SystemExit(main())

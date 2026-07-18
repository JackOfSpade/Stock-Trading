"""Guard scripts/check_sql_dryrun.py's classify() — the load-bearing decision that turns a
`bq query --dry_run` result into block / tolerate / ok (2026-07-17 audit follow-up).

The gate must BLOCK on a parse-class error (the mode=''manual'' class that reached live apply) and must
TOLERATE the permission/reference messages a READ-ONLY SA legitimately gets when dry-running DDL — a
regression either way silently breaks the gate (false-blocks every merge, or never catches a syntax
bug). Pure offline unit tests (no warehouse, no bq) — runs in the always-on `test` job.
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_sql_dryrun.py")
    spec = importlib.util.spec_from_file_location("check_sql_dryrun", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


csd = _load()


def test_exit_zero_is_ok():
    assert csd.classify(0, "Query successfully validated. ... 0 bytes ...") == "ok"


def test_the_actual_2026_07_17_bug_blocks():
    # BigQuery's exact wording for the mode=''manual'' bug.
    msg = ("Error in query string: Syntax error: concatenated string literals must be separated by "
           "whitespace or comments at [779:38]")
    assert csd.classify(1, msg) == "syntax"


def test_generic_syntax_errors_block():
    for msg in [
        "Syntax error: Unexpected keyword FROM at [3:1]",
        "Syntax error: Expected end of input but got identifier",
        "Syntax error: Illegal input character",
    ]:
        assert csd.classify(1, msg) == "syntax", msg


def test_readonly_sa_permission_denied_on_ddl_is_tolerated():
    # A syntactically-VALID CREATE the read-only SA cannot perform — NOT a syntax bug.
    msg = ("Access Denied: Table stock-trading-498512:state.foo: User does not have permission to "
           "update/create ...")
    assert csd.classify(1, msg) == "tolerated"


def test_not_yet_live_sibling_reference_is_tolerated():
    # A new object created later in the same change — reference resolution fails, not a syntax bug.
    for msg in [
        "Not found: Table stock-trading-498512:state.brand_new_view was not found in location US",
        "Unrecognized name: breach_hard at [12:9]",
    ]:
        assert csd.classify(1, msg) == "tolerated", msg


def test_transient_infra_error_is_unknown_not_blocking():
    # A network/quota hiccup must not false-block a merge — it is inconclusive, not a syntax error.
    assert csd.classify(1, "harness-error: bq query timed out after 180s") == "unknown"
    assert csd.classify(1, "Exceeded rate limits: too many api requests") == "unknown"


def test_syntax_wins_over_tolerate_when_both_present():
    # Parse failures surface before authorization, but be explicit: a syntax marker must win.
    msg = "Syntax error: unexpected keyword; also the user does not have permission"
    assert csd.classify(1, msg) == "syntax"

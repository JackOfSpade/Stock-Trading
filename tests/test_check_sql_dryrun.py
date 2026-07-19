"""Guard scripts/check_sql_dryrun.py's classify() — the load-bearing decision that turns a
`bq query --dry_run` result into block / tolerate / ok (2026-07-17 audit follow-up).

The gate must BLOCK on a parse-class error (the mode=''manual'' class that reached live apply) and must
TOLERATE the permission/reference messages a READ-ONLY SA legitimately gets when dry-running DDL — a
regression either way silently breaks the gate (false-blocks every merge, or never catches a syntax
bug). Pure offline unit tests (no warehouse, no bq) — runs in the always-on `test` job.
"""
from conftest import load_module_from_path

csd = load_module_from_path("check_sql_dryrun", "scripts", "check_sql_dryrun.py")


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


# ---- is_template(): fill-in-the-blanks files are unparseable BY DESIGN --------------------------
# 2026-07-18, first full-repo sweep (82 files): the ONLY "syntax error" was
# bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql, whose header says "TEMPLATE, NOT
# auto-applied ... fill in the 5 placeholders below" and which carries literal <TRANSFER_DATE>
# markers. BigQuery rejects it with `Unexpected "<"` — correctly. Blocking CI on it is a false
# positive AND a latent landmine: the path-gated CI step only sees the file once someone edits it
# (even a comment), so the build would red on a file that is correct by design.


def test_template_files_are_recognised():
    assert csd.is_template("bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql") is True
    assert csd.is_template("56_park_policy_voo_manual_cutover_TEMPLATE.sql") is True
    # case-insensitive on the suffix
    assert csd.is_template("bigquery/99_thing_template.sql") is True


def test_ordinary_sql_files_are_not_treated_as_templates():
    # The guard must be narrow: a normal file must still be dry-run and still be able to FAIL.
    for path in ("bigquery/34_alert_lifecycle.sql",
                 "bigquery/78_book_drawdown_rebase_and_staleness_gate.sql",
                 "bigquery/03_twr_engine.sql",
                 "bigquery/template_helpers.sql"):        # 'template' not as the _TEMPLATE suffix
        assert csd.is_template(path) is False, path


def test_template_detection_is_filename_based_not_placeholder_based():
    # Deliberate design choice: a <PLACEHOLDER>-marker regex would also match BigQuery's own type
    # syntax (ARRAY<STRING>, STRUCT<a INT64>) and would silently skip REAL files. Pin that a file
    # containing such type syntax in its NAME-less form is never auto-skipped.
    assert csd.is_template("bigquery/40_options_marks.sql") is False


def test_main_skips_templates_without_failing(monkeypatch, capsys):
    # A template-only invocation must exit 0, and must PRINT the skip (never silent — a template must
    # not be able to hide breakage).
    monkeypatch.setattr(csd, "canary_ok", lambda: True)
    called = []
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: called.append(sql_path) or (0, "ok"))
    rc = csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql"])
    out = capsys.readouterr().out
    assert rc == 0
    assert called == [], "a template must never be sent to bq --dry_run"
    assert "skipped" in out and "TEMPLATE" in out


def test_canary_failure_fails_closed(monkeypatch, capsys):
    # 2026-07-18 audit: if the environment can't detect a KNOWN syntax error, a "clean" pass over the
    # real files proves nothing — the gate must exit 1, not print a warning and green-light the merge
    # (the pre-fix behavior). Same discipline as dbt_parity's checked==0 fail-closed guard.
    monkeypatch.setattr(csd, "canary_ok", lambda: False)
    called = []
    monkeypatch.setattr(csd, "_bq_dry_run", lambda sql_path: called.append(sql_path) or (0, "ok"))
    rc = csd.main(["check_sql_dryrun.py", "bigquery/34_real.sql"])
    out = capsys.readouterr().out
    assert rc == 1
    assert "FAILS CLOSED" in out
    assert called == [], "no point dry-running files in an environment proven unable to catch errors"


def test_canary_not_consulted_when_nothing_to_check(monkeypatch):
    # Vacuous invocations (template-only / empty) exit 0 without spending a canary call — there is no
    # clean-pass claim to verify, so a broken environment must not red an empty change.
    monkeypatch.setattr(csd, "canary_ok", lambda: (_ for _ in ()).throw(AssertionError("must not run")))
    assert csd.main(["check_sql_dryrun.py"]) == 0
    assert csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql"]) == 0


def test_main_still_blocks_a_real_syntax_error_alongside_a_template(monkeypatch, capsys):
    # The skip must not become a hole: a genuine syntax error in a NON-template file still blocks,
    # even when a template rides along in the same invocation.
    monkeypatch.setattr(csd, "canary_ok", lambda: True)

    def fake(sql_path):
        return (1, 'Error in query string: Syntax error: Unexpected "(" at [21:18]')
    monkeypatch.setattr(csd, "_bq_dry_run", fake)
    rc = csd.main(["check_sql_dryrun.py", "bigquery/56_x_TEMPLATE.sql", "bigquery/34_real.sql"])
    out = capsys.readouterr().out
    assert rc == 1
    assert "34_real.sql" in out and "SYNTAX ERROR" in out

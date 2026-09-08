"""Guard scripts/apply_sql_file.py's canonical-provenance gate (2026-09-08, DESIGN_followups.md
FIX 4) — the check that runs BEFORE any dry-run or apply and turns the script's standing permission
grant (`Bash(python3 scripts/apply_sql_file.py *)`) from "may run arbitrary SQL live" into "may apply
repo-canonical SQL live" (see that script's module docstring, CANONICAL-PROVENANCE GATE section).

check_canonical_provenance() takes no BigQuery client and does no network I/O (pure text matched
against a caller-supplied `final` dict, the same shape check_live_sql_parity.find_final_definitions()
returns), so every test below runs fully offline — the gate is the whole point of testing separately
from main()'s dry-run/apply plumbing, which DOES need a live client and is deliberately NOT exercised
here (that plumbing was already covered pre-FIX-4 and is unchanged by this file).

Sample SQL below deliberately uses a fake dataset/object name (`state.fix4_test_object`, an object
that does not exist in bigquery/*.sql) so these tests can inject a synthetic `final` dict rather than
depending on any real, evolving bigquery/*.sql object staying byte-identical over time — the one
exception is test_real_sp_log_run_extraction_matches_canonical below, which intentionally uses the
REAL bigquery/230_run_outcome_notification.sql ops.sp_log_run definition (mirrors the VERIFY step run
by hand against the actual repo) precisely to prove the gate also works end-to-end against real,
non-synthetic extraction — not just against hand-built fixtures.
"""
import os

from conftest import load_module_from_path

asf = load_module_from_path("apply_sql_file", "scripts", "apply_sql_file.py")
clsp = load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = "stock-trading-498512"

CANONICAL_VIEW_SQL = (
    "CREATE OR REPLACE VIEW `stock-trading-498512.state.fix4_test_object` AS\n"
    "SELECT 1 AS x, 'ok' AS status\n"
)

# The body check_live_sql_parity.extract_body() would pull from CANONICAL_VIEW_SQL — computed via
# the REAL function (not hand-copied) so a future change to extract_body()'s VIEW-body slicing can
# never silently desync this fixture from what the gate actually compares.
_m = clsp.CREATE_STMT.search(CANONICAL_VIEW_SQL)
CANONICAL_BODY = clsp.extract_body(CANONICAL_VIEW_SQL, _m.start(), "VIEW")

FINAL_OK = {
    ("state", "fix4_test_object"): ("VIEW", PROJECT, "999_fake_test_object.sql", CANONICAL_BODY),
}


# ---- the canonical, matching case -----------------------------------------------------------------
def test_canonical_create_file_passes_the_gate():
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", CANONICAL_VIEW_SQL, FINAL_OK)
    assert ok is True
    assert noncanonical is False
    assert "canonical" in message
    assert "999_fake_test_object.sql" in message


# ---- tampered body: REFUSED, not silently accepted -------------------------------------------------
def test_tampered_body_is_refused():
    tampered_sql = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.fix4_test_object` AS\n"
        "SELECT 2 AS x, 'ok' AS status\n"          # 1 -> 2: a one-token tamper
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", tampered_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "does NOT match" in message
    assert "first divergence" in message           # the diff hint fired


def test_one_character_tamper_inside_the_body_is_refused():
    # A single-character edit deep in the body (not just the leading token) -- proves the gate is a
    # real byte comparison, not a length/prefix heuristic.
    tampered_sql = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.fix4_test_object` AS\n"
        "SELECT 1 AS x, 'okk' AS status\n"          # 'ok' -> 'okk'
    )
    ok, _noncanonical, message = asf.check_canonical_provenance("f.sql", tampered_sql, FINAL_OK)
    assert ok is False
    assert "does NOT match" in message


# ---- object absent from the repo's canonical set: REFUSED ------------------------------------------
def test_object_absent_from_repo_is_refused():
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", CANONICAL_VIEW_SQL, {})
    assert ok is False
    assert noncanonical is False
    assert "absent from find_final_definitions()" in message


# ---- appended-statement bypass (FIX A, adversarial review 2026-09-08): a statement tacked on AFTER
# ---- the genuine canonical CREATE body is never compared by points 1-2 alone, but the script still
# ---- sends the WHOLE FILE to BigQuery -- so it must be refused here, before any dry-run/apply.
def test_appended_delete_after_canonical_create_is_refused():
    appended_sql = (
        CANONICAL_VIEW_SQL
        + "DELETE FROM `stock-trading-498512.state.fix4_test_object` WHERE TRUE;\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", appended_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "follows the CREATE" in message
    assert "DELETE" in message


def test_appended_merge_after_canonical_create_is_refused():
    appended_sql = (
        CANONICAL_VIEW_SQL
        + "MERGE INTO `stock-trading-498512.state.fix4_test_object` T "
        + "USING (SELECT 1 AS x) S ON T.x = S.x WHEN MATCHED THEN UPDATE SET T.x = 2;\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", appended_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "follows the CREATE" in message


def test_appended_drop_after_canonical_create_is_refused():
    appended_sql = CANONICAL_VIEW_SQL + "DROP TABLE `stock-trading-498512.state.some_other_table`;\n"
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", appended_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "follows the CREATE" in message


# ---- comments/blank lines after the canonical CREATE: NOT a bypass -- must not over-refuse ----------
def test_canonical_create_followed_only_by_comments_is_accepted():
    commented_sql = (
        CANONICAL_VIEW_SQL
        + "\n-- a trailing note about this view\n"
        + "/* and a\n   block comment */\n\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", commented_sql, FINAL_OK)
    assert ok is True
    assert noncanonical is False
    assert "canonical" in message


# ---- text before the CREATE that is not a comment: REFUSED (module docstring point 4, prepend half) -
def test_text_before_the_create_is_refused():
    prefixed_sql = "SELECT 1;\n" + CANONICAL_VIEW_SQL
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", prefixed_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "precedes the CREATE" in message


def test_comment_before_the_create_is_accepted():
    # The prepend-side counterpart of test_canonical_create_followed_only_by_comments_is_accepted --
    # a header COMMENT ahead of the CREATE (this repo's own bigquery/*.sql convention) must not
    # over-refuse.
    commented_prefix_sql = "-- header comment for this object\n" + CANONICAL_VIEW_SQL
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", commented_prefix_sql, FINAL_OK)
    assert ok is True
    assert noncanonical is False


# ---- CREATE naming a different GCP project: REFUSED (FIX B, module docstring point 5) ---------------
def test_different_project_id_is_refused():
    diff_project_sql = (
        "CREATE OR REPLACE VIEW `some-other-project.state.fix4_test_object` AS\n"
        "SELECT 1 AS x, 'ok' AS status\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", diff_project_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "some-other-project" in message
    assert PROJECT in message


# ---- two top-level CREATEs: REFUSED regardless of --allow-noncanonical -----------------------------
def test_two_create_statements_in_one_file_is_refused():
    two_creates_sql = (
        CANONICAL_VIEW_SQL
        + "CREATE OR REPLACE VIEW `stock-trading-498512.state.fix4_test_object_2` AS\n"
        + "SELECT 2 AS x\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", two_creates_sql, FINAL_OK)
    assert ok is False
    assert noncanonical is False
    assert "2 top-level CREATE OR REPLACE statements" in message
    assert "exactly ONE statement per file" in message


# ---- non-CREATE (DML) file: gate reports noncanonical=True, does not itself refuse ------------------
def test_non_create_dml_file_is_reported_noncanonical_not_ok_by_itself():
    dml_sql = (
        "MERGE INTO `stock-trading-498512.ops.scheduled_query_version_registry` T\n"
        "USING (SELECT 'x' AS routine_name) S ON T.routine_name = S.routine_name\n"
        "WHEN MATCHED THEN UPDATE SET T.expected_version = 1;\n"
    )
    ok, noncanonical, message = asf.check_canonical_provenance("f.sql", dml_sql, FINAL_OK)
    assert noncanonical is True
    assert ok is True          # not itself a failure -- main() decides based on --allow-noncanonical
    assert "cannot be canonically matched" in message


# ---- main(): non-CREATE file refused WITHOUT --allow-noncanonical, never touching BigQuery ----------
def test_main_refuses_noncreate_file_without_the_flag_and_never_touches_bigquery(monkeypatch, capsys, tmp_path):
    dml_path = tmp_path / "63_registry_merge.sql"
    dml_path.write_text(
        "MERGE INTO `stock-trading-498512.ops.scheduled_query_version_registry` T\n"
        "USING (SELECT 'x' AS routine_name) S ON T.routine_name = S.routine_name\n"
        "WHEN MATCHED THEN UPDATE SET T.expected_version = 1;\n",
        encoding="utf-8")
    monkeypatch.setattr(asf.bigquery, "Client",
                         lambda **kw: (_ for _ in ()).throw(AssertionError("client must not be constructed")))
    rc = asf.main([str(dml_path)])
    assert rc == 1
    err = capsys.readouterr().err
    assert "REFUSED" in err
    assert "--allow-noncanonical" in err


# ---- main(): --allow-noncanonical applies the SAME file, with a loud warning, past the gate ---------
def test_main_allows_noncreate_file_with_the_flag_and_reaches_dry_run(monkeypatch, capsys, tmp_path):
    dml_path = tmp_path / "63_registry_merge.sql"
    dml_path.write_text(
        "MERGE INTO `stock-trading-498512.ops.scheduled_query_version_registry` T\n"
        "USING (SELECT 'x' AS routine_name) S ON T.routine_name = S.routine_name\n"
        "WHEN MATCHED THEN UPDATE SET T.expected_version = 1;\n",
        encoding="utf-8")

    class FakeJobConfig:
        def __init__(self, **kw):
            self.kw = kw

    class FakeClient:
        def __init__(self, **kw):
            pass

        def query(self, sql, job_config=None):
            return object()  # dry_run path: caller never calls .result() on this

    monkeypatch.setattr(asf.bigquery, "Client", FakeClient)
    monkeypatch.setattr(asf.bigquery, "QueryJobConfig", FakeJobConfig)
    rc = asf.main(["--dry-run", "--allow-noncanonical", str(dml_path)])
    assert rc == 0
    out = capsys.readouterr().out
    assert "allow-noncanonical set" in out
    assert "dry run   : OK" in out


# ---- main(): a canonical CREATE file needs no flag and reaches dry-run normally ----------------------
def test_main_canonical_file_passes_gate_without_any_flag(monkeypatch, capsys, tmp_path):
    view_path = tmp_path / "999_fake_test_object.sql"
    view_path.write_text(CANONICAL_VIEW_SQL, encoding="utf-8")

    class FakeClient:
        def __init__(self, **kw):
            pass

        def query(self, sql, job_config=None):
            return object()

    monkeypatch.setattr(asf, "find_final_definitions", lambda: FINAL_OK)
    monkeypatch.setattr(asf.bigquery, "Client", FakeClient)
    monkeypatch.setattr(asf.bigquery, "QueryJobConfig", lambda **kw: kw)
    rc = asf.main(["--dry-run", str(view_path)])
    assert rc == 0
    out = capsys.readouterr().out
    assert "gate      : OK" in out


# ---- main(): a tampered CREATE file is refused before BigQuery is ever touched -----------------------
def test_main_refuses_tampered_file_and_never_touches_bigquery(monkeypatch, capsys, tmp_path):
    view_path = tmp_path / "999_fake_test_object.sql"
    view_path.write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.fix4_test_object` AS\n"
        "SELECT 999 AS x, 'ok' AS status\n",
        encoding="utf-8")

    monkeypatch.setattr(asf, "find_final_definitions", lambda: FINAL_OK)
    monkeypatch.setattr(asf.bigquery, "Client",
                         lambda **kw: (_ for _ in ()).throw(AssertionError("client must not be constructed")))
    rc = asf.main([str(view_path)])
    assert rc == 1
    err = capsys.readouterr().err
    assert "REFUSED" in err
    assert "does NOT match" in err


# ---- real-repo end-to-end proof (mirrors the VERIFY step run by hand) -------------------------------
def test_real_sp_log_run_extraction_matches_canonical():
    """The REAL ops.sp_log_run CREATE OR REPLACE PROCEDURE statement, extracted fresh from
    bigquery/230_run_outcome_notification.sql (the file that is ITS OWN final-effective definition —
    find_final_definitions()'s value for this key comes from this exact file, see
    tests/test_check_live_sql_parity.py's apply-order tests for the general pattern), must pass the
    gate against the real repo's own find_final_definitions() -- proving the gate isn't only correct
    against the synthetic fixtures above."""
    path = os.path.join(ROOT, "bigquery", "230_run_outcome_notification.sql")
    txt = clsp.read_text(path)
    m = clsp.CREATE_STMT.search(txt, txt.index("ops.sp_log_run"))
    assert m is not None
    assert m.group(3) == "ops" and m.group(4) == "sp_log_run"
    end_m = clsp.NEXT_TOP_LEVEL.search(txt, m.start() + 1)
    end = end_m.start() if end_m else len(txt)
    fresh_extract = txt[m.start():end]

    final = clsp.find_final_definitions()
    ok, noncanonical, message = asf.check_canonical_provenance("fresh.sql", fresh_extract, final)
    assert noncanonical is False
    assert ok is True, message
    assert "ops.sp_log_run" in message


def test_real_sp_log_run_extraction_with_one_changed_character_is_refused():
    path = os.path.join(ROOT, "bigquery", "230_run_outcome_notification.sql")
    txt = clsp.read_text(path)
    m = clsp.CREATE_STMT.search(txt, txt.index("ops.sp_log_run"))
    end_m = clsp.NEXT_TOP_LEVEL.search(txt, m.start() + 1)
    end = end_m.start() if end_m else len(txt)
    fresh_extract = txt[m.start():end]

    # Flip one character deep INSIDE THE BODY, and specifically inside a STRING LITERAL argument to
    # sp_raise_alert_once (`'ops.sp_log_run'`, the alert's `item_key`) -- not the CREATE header's own
    # object name (tampering that renames the object and hits "absent from find_final_definitions()"
    # instead) and not a `--` comment occurrence (canonicalize() strips comments entirely, so a
    # comment-only tamper is invisible to the compare -- confirmed while writing this test: an earlier
    # version of it picked the trailing `-- (ops.sp_log_run)` comment and the gate correctly did NOT
    # flag it, because it truly is not part of the compared body). A string literal is passed through
    # canonicalize() VERBATIM (see that function's docstring), so a one-character edit inside one is
    # guaranteed to change the canonicalized comparison.
    needle = "'ops.sp_log_run'"
    idx = fresh_extract.index(needle)
    assert idx > fresh_extract.index("BEGIN")   # confirm the chosen occurrence really is in the body
    tampered = fresh_extract[:idx] + "'ops.sp_log_ruz'" + fresh_extract[idx + len(needle):]
    assert tampered != fresh_extract

    final = clsp.find_final_definitions()
    ok, noncanonical, message = asf.check_canonical_provenance("tampered.sql", tampered, final)
    assert noncanonical is False
    assert ok is False
    assert "does NOT match" in message

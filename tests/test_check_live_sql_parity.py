"""Offline tests for scripts/check_live_sql_parity.py's repo-side extraction (no BigQuery needed).

Locks in the two properties verified by hand while writing this script: (1) apply-in-order
resolution picks the LAST bigquery/NN_*.sql file that CREATE OR REPLACEs a given object, and (2) an
indented CREATE OR REPLACE embedded inside a FORMAT() string literal (bigquery/17_restore_drill.sql)
must never be mistaken for a real top-level statement.
"""
import json
import os
import shutil
import subprocess
import sys

import pytest

from conftest import load_module_from_path
from lib.sql_files import strip_sql_comments

clsp = load_module_from_path("check_live_sql_parity", "scripts", "check_live_sql_parity.py")


def test_parses_the_real_repo_without_crashing():
    final = clsp.find_final_definitions()
    assert len(final) > 100  # 137 at time of writing; a generous floor so new files don't break this


def test_apply_order_last_file_wins_for_a_known_redefinition():
    final = clsp.find_final_definitions()
    # bigquery/107 (2026-07-26 halt-echo missed_run exclusion) supersedes 97, which superseded 78,
    # which superseded 47, which superseded 34, which superseded 23, for state.trading_enabled.
    _, _, source_file, _ = final[("state", "trading_enabled")]
    assert source_file == "107_halt_echo_missed_run_gate.sql"
    # bigquery/107 also supersedes 97's/78's/34's state.trading_enabled_mechanical (same gate cluster).
    _, _, source_file2, _ = final[("state", "trading_enabled_mechanical")]
    assert source_file2 == "107_halt_echo_missed_run_gate.sql"


def test_real_repo_known_dropped_park_and_calibration_views_are_absent():
    # REGRESSION TEST for the DROP-awareness bug (2026-07-28): before the fix,
    # find_final_definitions() ignored bigquery/104's and bigquery/108's DROP VIEW statements
    # entirely, so these four deliberately-retired views stayed in the expected set forever even
    # though bigquery/92's/103's own comments say "DO NOT re-create live -- 104/108 drops it." Live
    # is exactly correct here; the checker used to be wrong.
    final = clsp.find_final_definitions()
    for dataset, name in [
        ("analytics", "calibration_return_shrunk"),
        ("state", "park_allocator_promotion_readiness"),
        ("state", "park_switch_budget"),
        ("state", "park_control_latest"),
    ]:
        assert (dataset, name) not in final, f"{dataset}.{name} should be DROP-excluded from the expected set"


# ---- DROP-awareness (2026-07-28 fix): find_final_definitions() must remove a DROPped object from
# the expected set, and must resolve a DROP/CREATE mix on the SAME object within a single file by
# TEXTUAL order (not "all creates then all drops"). -------------------------------------------------
def test_drop_in_later_file_removes_object_from_expected_set(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_drop.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") not in clsp.find_final_definitions()


def test_drop_then_create_same_file_leaves_object_expected(tmp_path, monkeypatch):
    # A file that drops an object and recreates it LATER in the SAME file (textually after the
    # DROP) must leave it expected -- this is exactly what apply-in-order does to the live object.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_drop_then_recreate.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n\n"
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 2 AS x;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    final = clsp.find_final_definitions()
    assert ("state", "foo") in final
    _ot, _p, src, body = final[("state", "foo")]
    assert src == "02_drop_then_recreate.sql"
    assert "2 AS x" in body


def test_create_then_drop_same_file_leaves_object_not_expected(tmp_path, monkeypatch):
    # The mirror case: CREATE then DROP later in the SAME file must leave it NOT expected. If this
    # were resolved by statement TYPE ("all creates, then all drops") instead of textual order, both
    # this test and the one above would get the SAME (wrong) answer for whichever one doesn't match
    # file-order-of-statement-kind processing.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create_then_drop.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n\n"
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") not in clsp.find_final_definitions()


def test_drop_earlier_file_create_later_file_leaves_object_expected(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_drop.sql").write_text(
        "DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;\n"
    )
    (d / "02_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    final = clsp.find_final_definitions()
    assert ("state", "foo") in final
    _ot, _p, src, _body = final[("state", "foo")]
    assert src == "02_create.sql"


def test_drop_table_function_removes_object_from_expected_set(tmp_path, monkeypatch):
    # DEFECT regression (2026-07-28): before DROP_STMT gained a TABLE FUNCTION alternative, a real
    # "DROP TABLE FUNCTION ..." statement produced NO match at all, so find_final_definitions() never
    # removed a retired TABLE FUNCTION from the expected set -- it stayed expected forever.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_foo`(p INT64)\n"
        "AS (\n  SELECT p AS x\n);\n"
    )
    (d / "02_drop.sql").write_text(
        "DROP TABLE FUNCTION IF EXISTS `stock-trading-498512.analytics.fn_foo`;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("analytics", "fn_foo") not in clsp.find_final_definitions()


def test_drop_stmt_matches_every_real_object_type_form():
    cases = [
        ("DROP VIEW `stock-trading-498512.state.foo`;",
         "VIEW", "state", "foo"),
        ("DROP VIEW IF EXISTS `stock-trading-498512.state.foo`;",
         "VIEW", "state", "foo"),
        ("DROP TABLE `stock-trading-498512.ops.foo`;",
         "TABLE", "ops", "foo"),
        ("DROP TABLE IF EXISTS `stock-trading-498512.ops.foo`;",
         "TABLE", "ops", "foo"),
        ("DROP PROCEDURE `stock-trading-498512.ops.sp_foo`;",
         "PROCEDURE", "ops", "sp_foo"),
        ("DROP PROCEDURE IF EXISTS `stock-trading-498512.ops.sp_foo`;",
         "PROCEDURE", "ops", "sp_foo"),
        ("DROP FUNCTION `stock-trading-498512.analytics.fn_foo`;",
         "FUNCTION", "analytics", "fn_foo"),
        ("DROP FUNCTION IF EXISTS `stock-trading-498512.analytics.fn_foo`;",
         "FUNCTION", "analytics", "fn_foo"),
        ("DROP MATERIALIZED VIEW `stock-trading-498512.analytics.mv_foo`;",
         "MATERIALIZED VIEW", "analytics", "mv_foo"),
        ("DROP MATERIALIZED VIEW IF EXISTS `stock-trading-498512.analytics.mv_foo`;",
         "MATERIALIZED VIEW", "analytics", "mv_foo"),
        # DEFECT regression (2026-07-28): DROP_STMT previously had no TABLE FUNCTION alternative at
        # all, so real BigQuery "DROP TABLE FUNCTION [IF EXISTS] <id>" DDL (this repo has three live
        # TABLE FUNCTION objects: analytics.fn_order_guard, analytics.fn_order_guard_options,
        # analytics.find_precedents) produced a COMPLETE non-match -- the bare TABLE alternative
        # cannot complete the pattern against "FUNCTION [IF EXISTS] <id>" either, since "FUNCTION"
        # gets consumed as the identifier's project-id group and there is no following ".".
        ("DROP TABLE FUNCTION `stock-trading-498512.analytics.fn_foo`;",
         "TABLE FUNCTION", "analytics", "fn_foo"),
        ("DROP TABLE FUNCTION IF EXISTS `stock-trading-498512.analytics.fn_foo`;",
         "TABLE FUNCTION", "analytics", "fn_foo"),
    ]
    for txt, expected_type, expected_dataset, expected_name in cases:
        m = clsp.DROP_STMT.search(txt)
        assert m is not None, f"DROP_STMT did not match: {txt}"
        obj_type, project, dataset, name = m.groups()
        assert " ".join(obj_type.split()) == expected_type, txt
        assert (project, dataset, name) == ("stock-trading-498512", expected_dataset, expected_name), txt


def test_drop_stmt_matches_partially_backtick_quoted_identifier():
    # bigquery/104's and bigquery/108's real DROP statements fully backtick-quote the identifier
    # (`` `project.dataset.name` ``), but this repo also writes the PARTIALLY-quoted form elsewhere
    # (backticks around the project id only) -- DROP_STMT must accept both.
    txt = "DROP VIEW IF EXISTS `stock-trading-498512`.state.foo;"
    m = clsp.DROP_STMT.search(txt)
    assert m is not None
    assert m.groups() == ("VIEW", "stock-trading-498512", "state", "foo")


def test_drop_word_inside_comment_or_string_literal_does_not_remove_object(tmp_path, monkeypatch):
    # A "DROP" that is NOT a genuine top-level statement -- inside a `--` comment, or inside a
    # string literal passed to EXECUTE IMMEDIATE/FORMAT() (mirroring bigquery/17_restore_drill.sql's
    # embedded CREATE) -- must never remove the object from the expected set. Both cases here are
    # safe for the SAME reason CREATE_STMT already is: the DROP text is not at column 0.
    d = tmp_path / "bigquery"
    d.mkdir()
    (d / "01_create.sql").write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\nSELECT 1 AS x;\n"
    )
    (d / "02_not_a_real_drop.sql").write_text(
        "-- DROP VIEW IF EXISTS `stock-trading-498512.state.foo`; (do NOT actually drop this)\n"
        "BEGIN\n"
        "  EXECUTE IMMEDIATE FORMAT(\n"
        "      \"DROP VIEW IF EXISTS `stock-trading-498512.state.foo`\");\n"
        "END;\n"
    )
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    assert ("state", "foo") in clsp.find_final_definitions()


def test_embedded_format_string_create_statement_is_not_a_false_positive():
    # bigquery/17_restore_drill.sql contains an indented "CREATE OR REPLACE TABLE ..." inside a
    # FORMAT() string literal passed to EXECUTE IMMEDIATE — the column-0-anchored regex must skip it.
    final = clsp.find_final_definitions()
    assert ("events_restore_drill", "%s__typed") not in final
    assert not any("events_restore_drill" in name for (_, name) in final)


def test_extract_body_strips_view_preamble_and_trailing_semicolon():
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"


def test_extract_body_retains_procedure_begin_end_wrapper():
    # Fixed 2026-07-16 (live-sql-parity self-heal audit, RES-3 step 0a): live
    # INFORMATION_SCHEMA.ROUTINES.routine_definition for a PROCEDURE INCLUDES the outer
    # BEGIN...END wrapper (verified live on ops.sp_log_decision, definition starts 'BEGIN\n'), so
    # the repo-side extraction must keep it too -- stripping it (the old behavior this test used to
    # assert) made every procedure spuriously DRIFT against the live body, the ~24-object
    # false-positive class behind issue #10.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  SELECT x;\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == "BEGIN\n  SELECT x;\nEND"


# ---- PROCEDURE body BLEED past its own END (2026-08-08 fix) ---------------------------------------
# NEXT_TOP_LEVEL deliberately excludes BEGIN from its boundary keywords (it has to -- BEGIN is what
# STARTS a procedure's own body), so nothing in the old extract_body stopped a PROCEDURE's body at
# its own closing END either. bigquery/146_adversarial_review_writer_serialization.sql's
# ops.sp_write_adversarial_review procedure ends its own body at line 193's `END;`, and the file then
# runs an entirely separate, free-standing `BEGIN ... END` one-time repair script before the next
# real top-level statement -- naive extraction swallowed that second block whole, producing a
# 209-line body (true: 147) containing identifiers that exist ONLY in the unrelated repair block, and
# a permanent false DRIFT against the live definition. find_procedure_body_end() fixes this with a
# real nesting-aware scan; these tests pin the fix directly (revert extract_body's PROCEDURE branch
# to `body = stmt[m.start():]` and every test below fails).
def test_extract_body_procedure_stops_at_own_end_not_a_following_standalone_begin_end_block():
    # Synthetic shape mirroring bigquery/146 exactly: a nested BEGIN TRANSACTION/COMMIT TRANSACTION
    # inside the procedure's OWN body (which must NOT open a new nesting level), then a standalone
    # BEGIN...END block after the procedure's true end (which must NOT bleed into the body).
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  DECLARE mutex_rows INT64;\n"
        "  BEGIN TRANSACTION;\n"
        "  SET mutex_rows = 1;\n"
        "  COMMIT TRANSACTION;\n"
        "  SELECT x;\n"
        "END;\n"
        "\n"
        "-- a separate, later, one-time repair script -- NOT part of sp_foo's body\n"
        "BEGIN\n"
        "DECLARE json_string_target_ids ARRAY<STRING> DEFAULT [];\n"
        "SELECT 'JSON type repair';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  DECLARE mutex_rows INT64;\n"
        "  BEGIN TRANSACTION;\n"
        "  SET mutex_rows = 1;\n"
        "  COMMIT TRANSACTION;\n"
        "  SELECT x;\n"
        "END"
    )
    for leaked in ("json_string_target_ids", "JSON type repair"):
        assert leaked not in body


def test_extract_body_procedure_case_expression_bare_end_does_not_truncate_body_early():
    # A CASE *expression* (this repo's only form -- `CASE WHEN ... END`) closes with a BARE END, the
    # same token that closes a BEGIN block. If CASE were not tracked as its own opener, this bare END
    # would be miscounted as closing the procedure's outer BEGIN one statement early, silently
    # dropping everything after the CASE from the extracted body (and, since a following standalone
    # block exists here too, would also fail to exclude it -- the truncation lands in the wrong
    # place, not just the wrong length).
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_case`(x INT64)\n"
        "BEGIN\n"
        "  DECLARE y STRING;\n"
        "  SET y = CASE WHEN x > 0 THEN 'pos' ELSE 'neg' END;\n"
        "  SELECT y;\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  DECLARE y STRING;\n"
        "  SET y = CASE WHEN x > 0 THEN 'pos' ELSE 'neg' END;\n"
        "  SELECT y;\n"
        "END"
    )
    assert "unrelated later block" not in body


# ---- CASE *statement* END CASE mishandled as a NON_BEGIN_END_SUFFIX no-op (2026-08-08 fix) --------
# The nesting-aware rewrite above (find_procedure_body_end()) tracks CASE as a depth-incrementing
# opener (needed for the CASE-expression bare-END case just above), but its very first version put
# "CASE" in NON_BEGIN_END_SUFFIX -- the same "recognize and skip, don't touch depth" bucket as END
# IF/WHILE/LOOP/FOR. That is correct for IF/WHILE/LOOP/FOR (their openers never increment depth, so
# their two-word closer is a genuine no-op) but wrong for CASE: CASE's own opener DID increment depth,
# so a same-treatment `END CASE` left depth permanently one level too high, the procedure's own END
# was never found at depth 0, and the body bled past it into whatever followed -- reintroducing
# exactly the class of bug this whole rewrite exists to fix (see module docstring's 2026-08-08 entry
# and find_procedure_body_end()'s docstring). These tests pin the fix directly (revert the "if
# nxt_word == CASE" branch in find_procedure_body_end()'s END handling, or put "CASE" back in
# NON_BEGIN_END_SUFFIX, and every test below fails).
def test_extract_body_procedure_case_statement_end_case_does_not_bleed_into_following_block():
    # BigQuery's imperative CASE *statement* form -- `CASE x WHEN ... END CASE;` -- as opposed to the
    # CASE *expression* form tested above. This is the exact synthetic shape from the CONFIRMED
    # defect report: without the fix, depth never returns to zero at the procedure's own `END;`, so
    # find_procedure_body_end() keeps scanning past it, matches the LATER free-standing block's END
    # instead, and the trailing "unrelated later block" text leaks into the extracted body.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_case_stmt`(x INT64)\n"
        "BEGIN\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    WHEN 2 THEN SELECT 'two';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "  SELECT 'done';\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    WHEN 2 THEN SELECT 'two';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "  SELECT 'done';\n"
        "END"
    )
    assert "unrelated later block" not in body


def test_extract_body_procedure_case_statement_and_case_expression_both_forms_in_one_procedure():
    # Both CASE forms in the SAME procedure: a CASE *expression* (bare END, inside a SET) and a CASE
    # *statement* (END CASE) as separate top-level statements in the body. Each closer must decrement
    # only its own opener's depth -- if either were miscounted the body would either truncate early
    # (bare END mistaken for the outer BEGIN's own END) or bleed into the trailing block (END CASE
    # never decrementing).
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_case_both`(x INT64)\n"
        "BEGIN\n"
        "  DECLARE y STRING;\n"
        "  SET y = CASE WHEN x > 0 THEN 'pos' ELSE 'neg' END;\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "  SELECT y;\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  DECLARE y STRING;\n"
        "  SET y = CASE WHEN x > 0 THEN 'pos' ELSE 'neg' END;\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "  SELECT y;\n"
        "END"
    )
    assert "unrelated later block" not in body


def test_extract_body_procedure_case_statement_nested_inside_if():
    # A CASE statement nested inside an IF block: two depth-incrementing constructs (IF does NOT
    # increment depth -- only CASE and BEGIN do -- so this really exercises CASE opening/closing
    # correctly while a non-depth-affecting IF...END IF wraps it) must not disturb the outer
    # procedure's own depth accounting.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_case_in_if`(x INT64)\n"
        "BEGIN\n"
        "  IF x > 0 THEN\n"
        "    CASE x\n"
        "      WHEN 1 THEN SELECT 'one';\n"
        "      ELSE SELECT 'other';\n"
        "    END CASE;\n"
        "  END IF;\n"
        "  SELECT 'done';\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  IF x > 0 THEN\n"
        "    CASE x\n"
        "      WHEN 1 THEN SELECT 'one';\n"
        "      ELSE SELECT 'other';\n"
        "    END CASE;\n"
        "  END IF;\n"
        "  SELECT 'done';\n"
        "END"
    )
    assert "unrelated later block" not in body


def test_extract_body_procedure_end_case_immediately_before_trailing_standalone_block():
    # END CASE as the LAST statement before the procedure's own END (no intervening statement) --
    # the tightest version of the bleed: if depth is even one level too high at this point, the very
    # next token scanned is the procedure's own `END;`, which would itself be misread as closing the
    # inner CASE rather than the outer BEGIN, walking straight into the trailing free-standing block.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_case_last`(x INT64)\n"
        "BEGIN\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  CASE x\n"
        "    WHEN 1 THEN SELECT 'one';\n"
        "    ELSE SELECT 'other';\n"
        "  END CASE;\n"
        "END"
    )
    assert "unrelated later block" not in body


def test_extract_body_procedure_for_loop_end_for_does_not_confuse_nesting():
    # Mirrors bigquery/17_restore_drill.sql's real shape: a FOR...END FOR loop containing its own
    # nested BEGIN...EXCEPTION...END handler, inside the procedure's outer BEGIN, followed by a
    # standalone block that must stay excluded.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_restore`()\n"
        "BEGIN\n"
        "  FOR rec IN (SELECT 1 AS n) DO\n"
        "    BEGIN\n"
        "      SELECT rec.n;\n"
        "    EXCEPTION WHEN ERROR THEN\n"
        "      SELECT @@error.message;\n"
        "    END;\n"
        "  END FOR;\n"
        "  SELECT 'done';\n"
        "END;\n"
        "\n"
        "BEGIN\n"
        "SELECT 'unrelated later block';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body.startswith("BEGIN\n  FOR rec IN")
    assert body.endswith("SELECT 'done';\nEND")
    assert "unrelated later block" not in body


def test_extract_body_procedure_end_semicolon_immediately_before_a_fresh_if_is_not_end_if():
    # "END;" immediately followed by an unrelated, fresh "IF ... THEN" statement (a real shape --
    # bigquery/17_restore_drill.sql's EXCEPTION-handling BEGIN...END closes right before its own
    # next IF) must NOT be misread as the two-word "END IF" closer: that would both skip the real
    # END's depth decrement and silently swallow the following IF into whatever comes next.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  BEGIN\n"
        "    SELECT x;\n"
        "  END;\n"
        "  IF x > 0 THEN\n"
        "    SELECT 'positive';\n"
        "  END IF;\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == (
        "BEGIN\n"
        "  BEGIN\n"
        "    SELECT x;\n"
        "  END;\n"
        "  IF x > 0 THEN\n"
        "    SELECT 'positive';\n"
        "  END IF;\n"
        "END"
    )


def test_find_procedure_body_end_ignores_keywords_inside_string_literals_and_comments():
    # A string literal or comment containing the literal text "BEGIN"/"END"/"CASE" must never affect
    # the nesting depth -- reuses sql_tokens()'s existing string/comment handling (shared with
    # canonicalize()), not a second, independently-written scanner.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  -- a comment mentioning BEGIN and END and CASE that must be ignored\n"
        "  SELECT 'contains the words BEGIN TRANSACTION and END CASE as plain text';\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    # The comment/literal text is kept VERBATIM in the extracted body (only ignored for the
    # keyword-nesting scan itself) -- this test's point is that neither one caused the scan to
    # miscount depth and truncate/extend the body, not that they were stripped.
    assert body == (
        "BEGIN\n"
        "  -- a comment mentioning BEGIN and END and CASE that must be ignored\n"
        "  SELECT 'contains the words BEGIN TRANSACTION and END CASE as plain text';\n"
        "END"
    )


def test_find_procedure_body_end_end_while_and_end_loop_do_not_affect_nesting():
    # Defensive coverage for the two BigQuery scripting loop forms this repo does not currently use
    # (WHILE...END WHILE, LOOP...END LOOP) -- same self-identifying-closer treatment as END IF/END
    # FOR, per find_procedure_body_end()'s docstring.
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  DECLARE i INT64 DEFAULT 0;\n"
        "  WHILE i < 3 DO\n"
        "    SET i = i + 1;\n"
        "  END WHILE;\n"
        "  LOOP\n"
        "    LEAVE;\n"
        "  END LOOP;\n"
        "  SELECT i;\n"
        "END;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body.endswith("SELECT i;\nEND")
    assert body.startswith("BEGIN\n  DECLARE i INT64 DEFAULT 0;\n  WHILE i < 3 DO")


def test_real_repo_sp_write_adversarial_review_excludes_leaked_repair_block_identifiers():
    # Direct lock on the real object behind the HIGH finding (2026-08-08): bigquery/146's procedure
    # body must never contain identifiers that exist ONLY in the separate, later, free-standing
    # one-time JSON-repair BEGIN...END block in the same file.
    final = clsp.find_final_definitions()
    obj_type, _project, source, body = final[("ops", "sp_write_adversarial_review")]
    assert obj_type == "PROCEDURE"
    assert source == "146_adversarial_review_writer_serialization.sql"
    for leaked in ("json_string_target_ids", "repair_mutex_rows", "JSON type repair"):
        assert leaked not in body
    assert body.startswith("BEGIN")
    assert body.rstrip().endswith("END")
    # True body is lines 47-193 of the source file (BEGIN through its own matching END, wrapper
    # included -- see extract_body's PROCEDURE branch) -- 147 lines, not the pre-fix 209.
    assert len(body.splitlines()) == 147


def test_normalize_tail_matches_repo_extraction_despite_live_trailing_comments():
    # A live-style body (INFORMATION_SCHEMA definition retaining a trailing comment/blank line the
    # repo-side next-statement boundary already excludes) must normalize to the same text as the
    # repo-extracted body once normalize_tail is applied to both (RES-3 step 0b).
    repo_txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
    )
    m = clsp.CREATE_STMT.search(repo_txt)
    repo_body = clsp.extract_body(repo_txt, m.start(), "VIEW")

    live_style_body = "SELECT 1 AS x\nFROM bar;\n-- trailing live comment\n\n"
    assert clsp.normalize_tail(live_style_body) == repo_body


def test_view_body_stops_at_a_following_non_compared_create(monkeypatch):
    # 2026-07-17 audit: CREATE_STMT only recognizes VIEW/PROCEDURE/TABLE FUNCTION, so when one of
    # those is followed by a top-level CREATE TABLE / scalar CREATE FUNCTION / CREATE MODEL /
    # CREATE SCHEMA, the older boundary (CREATE_STMT.search) skipped past it and BLED that foreign
    # DDL into the object's extracted body -> permanent false DRIFT. The boundary now stops at ANY
    # top-level CREATE (NEXT_TOP_LEVEL).
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
        "\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.sink` (\n"
        "  id INT64\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"
    assert "CREATE TABLE" not in body


def test_procedure_body_stops_at_a_following_create_table(monkeypatch):
    # Same boundary bug, PROCEDURE side: sp_log_run's body used to swallow the CREATE TABLE
    # IF NOT EXISTS ops.alerts that follows its own END; (bigquery/10_observability.sql).
    txt = (
        "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_foo`(x INT64)\n"
        "BEGIN\n"
        "  SELECT x;\n"
        "END;\n"
        "\n"
        "CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.alerts` (\n"
        "  id INT64\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "PROCEDURE")
    assert body == "BEGIN\n  SELECT x;\nEND"
    assert "CREATE TABLE" not in body


def test_inline_as_select_header_is_not_sliced_by_a_column_alias(monkeypatch):
    # 2026-07-17 audit: an inline `... AS SELECT` header (AS and SELECT on one line) with a later
    # `expr AS\n` column alias used to make the old first-branch (`AS\s*\n`) match the alias instead
    # of the header AS, dropping `SELECT ... AS` off the front. Using the first standalone AS fixes it.
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS SELECT\n"
        "  a AS\n"
        "  b\n"
        "FROM t;\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body.startswith("SELECT")
    assert body == "SELECT\n  a AS\n  b\nFROM t"


def test_no_object_in_the_real_tree_bleeds_a_foreign_statement_into_its_body():
    # Strong invariant guarding the boundary fix against regression: no extracted body may contain a
    # column-0 top-level statement (CREATE *or* a DML/DDL statement like MERGE/INSERT/... that follows
    # the object). The old guard only rejected a bled ^CREATE, so it could not catch the ci_findings_open
    # MERGE bleed (2026-07-17 HIGH); this broadened set matches NEXT_TOP_LEVEL's own keyword list so any
    # bled top-level statement fails the invariant.
    import re
    top = re.compile(r"^(CREATE|INSERT|MERGE|UPDATE|DELETE|TRUNCATE|DROP|ALTER|GRANT|REVOKE|CALL|EXPORT|ASSERT)\b",
                     re.MULTILINE)
    final = clsp.find_final_definitions()
    bled = [f"{ds}.{nm}" for (ds, nm), (_ot, _p, _src, body) in final.items() if top.search(body)]
    assert bled == [], f"objects bleeding a foreign top-level statement into their body: {bled}"


def test_view_body_stops_at_a_following_top_level_merge():
    # 2026-07-17 HIGH regression: bigquery/67 ends `CREATE OR REPLACE VIEW state.ci_findings_open AS
    # SELECT … ;` then runs a standalone `MERGE …` registry bump. A CREATE-only boundary swept the
    # MERGE into the view body -> permanent false DRIFT vs the live view_definition (just the SELECT).
    txt = (
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.foo` AS\n"
        "SELECT 1 AS x\n"
        "FROM bar;\n"
        "\n"
        "-- a standalone registry-bump comment\n"
        "MERGE `stock-trading-498512.state.reg` T\n"
        "USING (SELECT 'a' AS k) S ON T.k = S.k\n"
        "WHEN NOT MATCHED THEN INSERT (k) VALUES (S.k);\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "VIEW")
    assert body == "SELECT 1 AS x\nFROM bar"
    assert "MERGE" not in body


def test_ci_findings_open_real_body_has_no_bled_merge():
    # Direct lock on the real object behind the HIGH finding: its final-effective body must be only the
    # SELECT, never the trailing MERGE from bigquery/67_ci_findings_bridge.sql. Since 2026-07-18 the
    # canonical definition is bigquery/86 (adds episode-aware first_detected); the synthetic bleed test
    # above still locks the 67-shaped statement-boundary behavior itself.
    final = clsp.find_final_definitions()
    _ot, _p, src, body = final[("state", "ci_findings_open")]
    assert src == "86_ci_findings_first_detected.sql"
    assert "MERGE" not in body
    assert body.strip().endswith("ON e.workflow = o.workflow AND e.finding_key = o.finding_key")


def test_final_operating_date_boundaries_are_pinned_to_denver():
    """Final live SQL must never compare an operating date with UTC-truncated timestamps."""
    final = clsp.find_final_definitions()
    cases = [
        (("analytics", "strategy_nav"), "127_strategy_nav_dust_exclusion.sql",
         "DATE(immutable_since, 'America/Denver')", "DATE(immutable_since)"),
        (("state", "param_oos_degradation"), "37_self_improvement_autonomy.sql",
         "DATE(lc.change_ts, 'America/Denver')", "DATE(lc.change_ts)"),
        (("state", "catchup_refire_failures"), "59_catchup_autofire.sql",
         "DATE(attempted_ts, 'America/Denver')", "DATE(attempted_ts)"),
        (("state", "strategy_probe_progress"), "126_dust_operational_hardening.sql",
         "DATE(p.immutable_since, 'America/Denver')", "DATE(p.immutable_since)"),
        (("state", "strategy_retirement_candidacy"), "81_arsenal_fixes.sql",
         "CURRENT_DATE('America/Denver')", "CURRENT_DATE()"),
        (("state", "ci_findings_open"), "86_ci_findings_first_detected.sql",
         "DATE(e.first_open_ts, 'America/Denver')", "DATE(e.first_open_ts)"),
    ]
    for key, expected_source, safe_form, unsafe_form in cases:
        _object_type, _path, source, body = final[key]
        code = strip_sql_comments(body)
        assert source == expected_source
        assert safe_form in code
        assert unsafe_form not in code


def test_strategy_nav_dbt_mirror_pins_capital_eligibility_to_denver():
    path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "dbt", "models", "analytics",
                        "strategy_nav.sql")
    with open(path, encoding="utf-8") as f:
        code = strip_sql_comments(f.read())
    assert "DATE(immutable_since, 'America/Denver')" in code
    assert "DATE(immutable_since)" not in code


# ---- extract_body: TABLE FUNCTION branch (single AS ( ... ) wrapper) ------------------------------
def test_extract_body_table_function_strips_outer_paren_wrapper():
    # All live TABLE FUNCTIONs in this repo are a single `AS ( SELECT ... )` wrapper; extract_body
    # drops the one outer paren pair. Exercised only against live BigQuery before now.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS (\n"
        "  SELECT p AS y\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "SELECT p AS y"


def test_extract_body_table_function_no_outer_wrapper_is_left_intact():
    # 2026-07-18 audit fix: a body shaped `(SELECT a) UNION ALL (SELECT b)` — no extra outer wrap —
    # merely starts/ends with a paren, but the leading "(" is NOT matched by the trailing ")". The
    # old naive startswith/endswith strip corrupted this into unbalanced garbage; the paren-depth
    # guard must leave both inner paren pairs intact.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS\n"
        "  (SELECT p AS y) UNION ALL (SELECT p + 1 AS y)\n"
        ";\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "(SELECT p AS y) UNION ALL (SELECT p + 1 AS y)"


def test_extract_body_table_function_genuine_wrapper_around_union_stays_correct():
    # The genuine-wrapper counterpart: an actual `AS ( ... )` wrapper around a union of parenthesized
    # subqueries must still have exactly its own outer pair stripped, since paren depth here DOES
    # return to 0 only at the final character.
    txt = (
        "CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_x`(p INT64)\n"
        "AS (\n"
        "  (SELECT p AS y) UNION ALL (SELECT p + 1 AS y)\n"
        ");\n"
    )
    m = clsp.CREATE_STMT.search(txt)
    body = clsp.extract_body(txt, m.start(), "TABLE FUNCTION")
    assert body == "(SELECT p AS y) UNION ALL (SELECT p + 1 AS y)"


# ---- bq(): thin delegation to lib/bq_json.run_bq_query -- the shared subprocess-invoke/JSON-parse/
# returncode/timeout contract is proven ONCE on run_bq_query itself (tests/test_bq_json.py); this
# just pins that THIS caller forwards sql/project with no extra fixed args when max_rows is omitted
# (plain delegation, unlike roster/dbt_parity/alert_relay's max_rows=N) (C3 dedup, 2026-07-20 audit).
# max_rows became an optional passthrough (2026-07-30 batching fix, see BATCH_MAX_ROWS) -- the
# second test below pins that half.
def test_bq_delegates_to_run_bq_query_with_no_extra_fixed_args(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project):
        captured["sql"], captured["project"] = sql, project
        return [{"view_definition": "SELECT 1"}]
    monkeypatch.setattr(clsp, "run_bq_query", fake_run_bq_query)
    assert clsp.bq("SELECT 1", "proj") == [{"view_definition": "SELECT 1"}]
    assert captured == {"sql": "SELECT 1", "project": "proj"}


def test_bq_forwards_max_rows_only_when_explicitly_given(monkeypatch):
    captured = {}

    def fake_run_bq_query(sql, project, max_rows=None):
        captured["max_rows"] = max_rows
        return []
    monkeypatch.setattr(clsp, "run_bq_query", fake_run_bq_query)
    clsp.bq("SELECT 1", "proj", max_rows=5000)
    assert captured["max_rows"] == 5000


# ---- batched live lookups (2026-07-30 perf fix): fetch_live_definitions() / resolve_live_
# definition() replaced the old one-`bq query`-per-OBJECT live_definition() (199 sequential
# round-trips against the real repo, ~10 billable CI min/day) with ~5 batched INFORMATION_SCHEMA
# queries total. These tests cover: the batch-result parser (given a synthetic INFORMATION_SCHEMA
# result set, produces the right per-object definitions), that every object KIND is routed to the
# right INFORMATION_SCHEMA source, and — the load-bearing safety property — that a batch-query
# FAILURE marks every object in that dataset SKIPPED, never MISSING. -------------------------------

def test_parse_views_batch_maps_table_name_to_definition():
    rows = [
        {"table_name": "foo", "view_definition": "SELECT 1 AS x"},
        {"table_name": "bar", "view_definition": "SELECT 2 AS y"},
    ]
    assert clsp.parse_views_batch(rows) == {
        "foo": "SELECT 1 AS x",
        "bar": "SELECT 2 AS y",
    }


def test_parse_views_batch_empty_result_is_empty_dict():
    assert clsp.parse_views_batch([]) == {}


def test_parse_routines_batch_keys_by_name_and_type():
    # Keyed by (name, type), not name alone -- so a same-named PROCEDURE and TABLE FUNCTION in the
    # same dataset (not observed in this repo today, but the old per-object query's own
    # `routine_type = '<type>'` filter guarded against it) can never shadow each other.
    rows = [
        {"routine_name": "sp_foo", "routine_type": "PROCEDURE", "routine_definition": "BEGIN SELECT 1; END"},
        {"routine_name": "fn_x", "routine_type": "TABLE FUNCTION", "routine_definition": "SELECT 1"},
    ]
    assert clsp.parse_routines_batch(rows) == {
        ("sp_foo", "PROCEDURE"): "BEGIN SELECT 1; END",
        ("fn_x", "TABLE FUNCTION"): "SELECT 1",
    }


def test_fetch_live_definitions_routes_view_kind_to_information_schema_views(monkeypatch):
    seen = []

    def fake_bq(sql, project, max_rows=None):
        seen.append((sql, project, max_rows))
        return [{"table_name": "foo", "view_definition": "SELECT 1 AS x"}]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    final = {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")}
    views, routines = clsp.fetch_live_definitions("proj", final)
    assert len(seen) == 1
    sql, project, max_rows = seen[0]
    assert "INFORMATION_SCHEMA.VIEWS" in sql and "state" in sql
    assert project == "proj"
    assert views == {"state": {"foo": "SELECT 1 AS x"}}
    assert routines == {}
    # REGRESSION (2026-07-30, found by this fix's own live equivalence proof): `bq query` caps
    # results at 100 rows by default, and the real repo's `state` dataset alone has 111 views — an
    # unbounded batched query silently truncated and reported 11 real objects as false MISSING. The
    # batched query must always request enough rows to cover a full dataset.
    assert max_rows == clsp.BATCH_MAX_ROWS
    assert max_rows is not None and max_rows > 200  # generous margin above any real dataset today


def test_fetch_live_definitions_routes_procedure_and_table_function_to_information_schema_routines(monkeypatch):
    seen = []

    def fake_bq(sql, project, max_rows=None):
        seen.append(sql)
        return [
            {"routine_name": "sp_foo", "routine_type": "PROCEDURE", "routine_definition": "BEGIN SELECT 1; END"},
            {"routine_name": "fn_x", "routine_type": "TABLE FUNCTION", "routine_definition": "SELECT 1"},
        ]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    final = {
        ("ops", "sp_foo"): ("PROCEDURE", "proj", "01.sql", "BEGIN SELECT 1; END"),
        ("ops", "fn_x"): ("TABLE FUNCTION", "proj", "01.sql", "SELECT 1"),
    }
    views, routines = clsp.fetch_live_definitions("proj", final)
    # ONE query covers BOTH kinds for the dataset (WHERE routine_type IN (...)), not one per kind.
    assert len(seen) == 1
    assert "INFORMATION_SCHEMA.ROUTINES" in seen[0]
    assert "routine_type IN ('PROCEDURE', 'TABLE FUNCTION')" in seen[0]
    assert views == {}
    assert routines == {"ops": {
        ("sp_foo", "PROCEDURE"): "BEGIN SELECT 1; END",
        ("fn_x", "TABLE FUNCTION"): "SELECT 1",
    }}


def test_fetch_live_definitions_issues_one_query_per_dataset_not_per_object(monkeypatch):
    # The N+1 fix itself: 4 objects across 2 datasets, all VIEWs, must be exactly 2 queries.
    calls = []

    def fake_bq(sql, project, max_rows=None):
        calls.append(sql)
        return []
    monkeypatch.setattr(clsp, "bq", fake_bq)
    final = {
        ("state", "a"): ("VIEW", "proj", "01.sql", "x"),
        ("state", "b"): ("VIEW", "proj", "01.sql", "x"),
        ("analytics", "c"): ("VIEW", "proj", "01.sql", "x"),
        ("analytics", "d"): ("VIEW", "proj", "01.sql", "x"),
    }
    clsp.fetch_live_definitions("proj", final)
    assert len(calls) == 2  # one per dataset, not one per object (would be 4)


def test_fetch_live_definitions_requests_more_than_the_bq_cli_default_row_cap(monkeypatch):
    # DEFECT regression (2026-07-30, found via this fix's own live equivalence proof): `bq query`
    # caps results at 100 rows unless --max_rows is given explicitly (verified: `bq query --help`
    # -> "How many rows to return in the result. (default: '100')"). The real repo's `state` dataset
    # has 111 VIEW objects -- an unbounded batched query silently returned only 100 of them and 11
    # real, live objects were reported as false MISSING (positive evidence of absence that could
    # trigger an incorrect autonomous CREATE under the 2026-07-28 directive). Simulates the CLI's
    # own truncation behavior directly: fake_bq returns AT MOST `max_rows` rows, mirroring what the
    # real `bq` binary does, so a caller that forgets to pass a big enough max_rows would see this
    # test fail with a truncated dataset, exactly like the live incident did.
    all_rows = [{"table_name": f"v{i}", "view_definition": f"SELECT {i}"} for i in range(150)]

    def fake_bq(sql, project, max_rows=None):
        cap = max_rows if max_rows is not None else 100  # bq CLI's own default
        return all_rows[:cap]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    final = {("state", f"v{i}"): ("VIEW", "proj", "01.sql", "x") for i in range(150)}
    views, routines = clsp.fetch_live_definitions("proj", final)
    assert len(views["state"]) == 150, (
        f"only got {len(views['state'])} of 150 rows -- fetch_live_definitions is not requesting "
        f"enough rows to cover a dataset larger than bq's 100-row CLI default")
    for i in range(150):
        assert clsp.resolve_live_definition(views, routines, "state", f"v{i}", "VIEW") == f"SELECT {i}"


def test_fetch_live_definitions_covers_all_three_real_object_kinds_across_datasets(monkeypatch):
    # Enumerates all THREE kinds CREATE_STMT ever produces (VIEW, PROCEDURE, TABLE FUNCTION) spread
    # across separate datasets, and asserts each lands in the correct batch bucket with none lost —
    # a coverage regression here would silently drop objects from the check entirely.
    def fake_bq(sql, project, max_rows=None):
        if "INFORMATION_SCHEMA.VIEWS" in sql:
            return [{"table_name": "v1", "view_definition": "SELECT 1"}]
        return [
            {"routine_name": "sp1", "routine_type": "PROCEDURE", "routine_definition": "BEGIN SELECT 1; END"},
            {"routine_name": "tf1", "routine_type": "TABLE FUNCTION", "routine_definition": "SELECT 1"},
        ]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    final = {
        ("state", "v1"): ("VIEW", "proj", "01.sql", "x"),
        ("ops", "sp1"): ("PROCEDURE", "proj", "01.sql", "x"),
        ("analytics", "tf1"): ("TABLE FUNCTION", "proj", "01.sql", "x"),
    }
    views, routines = clsp.fetch_live_definitions("proj", final)
    assert clsp.resolve_live_definition(views, routines, "state", "v1", "VIEW") == "SELECT 1"
    assert clsp.resolve_live_definition(views, routines, "ops", "sp1", "PROCEDURE") == "BEGIN SELECT 1; END"
    assert clsp.resolve_live_definition(views, routines, "analytics", "tf1", "TABLE FUNCTION") == "SELECT 1"


def test_resolve_live_definition_returns_definition_on_a_match():
    views = {"state": {"foo": "SELECT 1 AS x"}}
    assert clsp.resolve_live_definition(views, {}, "state", "foo", "VIEW") == "SELECT 1 AS x"


def test_resolve_live_definition_returns_none_when_batch_succeeded_but_object_absent():
    # SUCCESSFUL batch, object genuinely not in it -- positive evidence of absence (MISSING), not a
    # skip. main() distinguishes this from the exception case below purely by return vs raise.
    views = {"state": {"other": "SELECT 1 AS x"}}
    assert clsp.resolve_live_definition(views, {}, "state", "gone", "VIEW") is None


def test_resolve_live_definition_reraises_a_failed_batch_query_for_every_object_in_that_dataset():
    # THE SAFETY PROPERTY (2026-07-28 missing-vs-skipped contract, restated for batching): a FAILED
    # batch query for a dataset must never be misread as "BigQuery said these don't exist" for the
    # objects in it -- it must re-raise so the caller's try/except files them as SKIPPED, exactly
    # like a failed per-object lookup used to. A false MISSING here could trigger an autonomous
    # CREATE against production.
    boom = RuntimeError("bq auth error: could not refresh WIF token")
    views = {"state": boom}
    for name in ("foo", "bar", "anything"):
        try:
            clsp.resolve_live_definition(views, {}, "state", name, "VIEW")
            raise AssertionError(f"expected {name} to re-raise the stored batch failure")
        except RuntimeError as e:
            assert e is boom  # the SAME exception object, not a new/different one


def test_resolve_live_definition_routine_kinds_use_the_type_scoped_key():
    routines = {"ops": {("sp_foo", "PROCEDURE"): "BEGIN SELECT 1; END"}}
    assert clsp.resolve_live_definition({}, routines, "ops", "sp_foo", "PROCEDURE") == "BEGIN SELECT 1; END"
    # A TABLE FUNCTION with the same name in the same dataset must not match the PROCEDURE's key.
    assert clsp.resolve_live_definition({}, routines, "ops", "sp_foo", "TABLE FUNCTION") is None


def test_resolve_live_definition_missing_dataset_entirely_is_treated_as_no_match():
    # A dataset with no expected objects of a kind never gets a batch query issued for it at all
    # (fetch_live_definitions only queries datasets that need it) -- .get(dataset, {}) must treat an
    # absent dataset key the same as "found nothing", not KeyError.
    assert clsp.resolve_live_definition({}, {}, "state", "foo", "VIEW") is None


# ---- main(): --project CLI-flag plumbing through to fetch_live_definitions()/bq() ------------------
def test_main_passes_project_flag_through(monkeypatch):
    # Locks the exact bug class the code comment at main()'s live-lookup call site guards against
    # ("a parsed-but-ignored argument") -- mirrors
    # test_check_live_roster_parity.py's test_main_passes_project_flag_through.
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--project", "custom-proj-9"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_fetch(project, final):
        captured["project"] = project
        return {}, {}
    monkeypatch.setattr(clsp, "fetch_live_definitions", fake_fetch)
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda v, r, ds, nm, ot: "SELECT 1 AS x")
    assert clsp.main() == 0
    assert captured["project"] == "custom-proj-9"


def test_main_passes_project_flag_through_gnu_equals_form(monkeypatch):
    # Same lock as test_main_passes_project_flag_through above, but pins the GNU `--project=X`
    # single-token form specifically. This is the half of the 2026-07-20 fix the two-token form alone
    # doesn't cover: the OLD hand-rolled argv loop only matched `--project X` (two tokens), so
    # `--project=X` silently kept the hardcoded default project -- a test using only the two-token
    # form would have passed against that old buggy code too and missed the regression entirely.
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--project=custom-proj-9"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_fetch(project, final):
        captured["project"] = project
        return {}, {}
    monkeypatch.setattr(clsp, "fetch_live_definitions", fake_fetch)
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda v, r, ds, nm, ot: "SELECT 1 AS x")
    assert clsp.main() == 0
    assert captured["project"] == "custom-proj-9"


def test_main_unrecognized_flag_is_hard_error(monkeypatch):
    # argparse turns an unknown flag into a hard SystemExit (argparse's usage-error exit) instead of
    # the old hand-rolled argv loop's silent no-op -- pins the other half of the 2026-07-20 fix.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--bogus"])
    with pytest.raises(SystemExit):
        clsp.main()


def test_main_default_project_is_stock_trading(monkeypatch):
    captured = {}
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})

    def fake_fetch(project, final):
        captured["project"] = project
        return {}, {}
    monkeypatch.setattr(clsp, "fetch_live_definitions", fake_fetch)
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda v, r, ds, nm, ot: "SELECT 1 AS x")
    assert clsp.main() == 0
    assert captured["project"] == "stock-trading-498512"


# ---- main(): offline flag, drift/clean exit codes, and the missing-live skip ----------------------
def test_main_offline_returns_0_without_touching_bq(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--offline"])

    def _forbidden(*a, **k):
        raise AssertionError("fetch_live_definitions must not be called in --offline mode")
    monkeypatch.setattr(clsp, "fetch_live_definitions", _forbidden)
    assert clsp.main() == 0
    assert "offline" in capsys.readouterr().out.lower()


def test_main_reports_ok_when_live_matches_after_whitespace_collapse(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))
    # Live body differs only by whitespace -> collapse() equalizes -> no drift.
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda v, r, ds, nm, ot: "SELECT   1   AS x")
    assert clsp.main() == 0
    assert "OK:" in capsys.readouterr().out


def test_main_reports_drift_and_exits_1(monkeypatch, capsys):
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions",
                        lambda: {("state", "foo"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x")})
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda *a: "SELECT 2 AS x")
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "DRIFT" in out and "state.foo" in out


def test_main_missing_object_is_a_distinct_finding_and_fails_the_run(monkeypatch, capsys):
    # FIX 2 (2026-07-28): a live lookup that SUCCEEDS with zero rows is POSITIVE evidence of
    # absence for an object the repo's final-effective bigquery/*.sql still expects -- distinct
    # from a lookup FAILURE (exception, tested separately below) -- and must fail the run, not be
    # silently swallowed as an inconclusive skip the way it used to be.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "present"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))

    def fake_resolve(views, routines, ds, nm, ot):
        return None if nm == "gone" else "SELECT 1 AS x"   # 'present' matches; 'gone' not found live
    monkeypatch.setattr(clsp, "resolve_live_definition", fake_resolve)
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "MISSING" in out and "state.gone" in out and "no live object found" in out
    assert "DRIFT" not in out   # a genuine absence is not a text-mismatch drift


def test_main_lookup_exception_is_a_skip_and_does_not_fail_the_run_alone(monkeypatch, capsys):
    # The OTHER half of FIX 2: an exception during lookup (transient/auth/timeout, or -- as of the
    # 2026-07-30 batching fix -- a whole dataset's batch query failing) must stay a SKIP -- never
    # promoted to missing_objects or findings -- and must not, by itself, fail an otherwise-clean run
    # (a second object still verifies clean, so checked>0).
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "present"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "flaky"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
    })
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))

    def fake_resolve(views, routines, ds, nm, ot):
        if nm == "flaky":
            raise RuntimeError("timeout")
        return "SELECT 1 AS x"
    monkeypatch.setattr(clsp, "resolve_live_definition", fake_resolve)
    assert clsp.main() == 0
    out = capsys.readouterr().out
    assert "skipped" in out and "state.flaky" in out and "live lookup failed" in out
    assert "MISSING" not in out


def test_main_lookup_exception_from_a_shared_failed_batch_skips_every_object_in_that_dataset(monkeypatch, capsys):
    # End-to-end version of the batching safety property, through the REAL fetch_live_definitions()/
    # resolve_live_definition() (not stubbed): a dataset whose single batch query fails must skip
    # EVERY object that dataset covers -- never report any of them MISSING.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "a"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "b"): ("VIEW", "proj", "01.sql", "SELECT 2 AS y"),
        ("ops", "sp_ok"): ("PROCEDURE", "proj", "01.sql", "BEGIN SELECT 1; END"),
    })

    def fake_bq(sql, project, max_rows=None):
        if "state" in sql:
            raise RuntimeError("bq auth error: could not refresh WIF token")
        return [{"routine_name": "sp_ok", "routine_type": "PROCEDURE", "routine_definition": "BEGIN SELECT 1; END"}]
    monkeypatch.setattr(clsp, "bq", fake_bq)
    assert clsp.main() == 0  # ops.sp_ok verified clean; state's failure is a skip, not a failure on its own
    out = capsys.readouterr().out
    assert "skipped" in out and "state.a" in out and "state.b" in out
    assert "MISSING" not in out
    assert "DRIFT" not in out


def test_main_fails_closed_when_every_object_is_skipped(monkeypatch, capsys):
    # 2026-07-17 parallel-refactor audit: a systemic live-read failure (every lookup raises — WIF/
    # auth broken) sends ALL objects to missing_live, checked stays 0. Reporting OK would be a
    # vacuous green on zero comparisons that hides a completely broken gate; must fail closed instead.
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py"])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "a"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "b"): ("VIEW", "proj", "02.sql", "SELECT 2 AS y"),
    })
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))

    def boom(*a):
        raise RuntimeError("bq auth error: could not refresh WIF token")
    monkeypatch.setattr(clsp, "resolve_live_definition", boom)
    assert clsp.main() == 1
    out = capsys.readouterr().out
    assert "NOT VERIFIED" in out and "zero comparisons" in out


def test_main_json_out_writes_findings_skips_and_missing_objects(tmp_path, monkeypatch):
    # FIX 2/3 (2026-07-28): three distinct outcomes across three objects -- a real mismatch (a
    # "findings" re-apply self-heal candidate), a lookup exception (a "skipped" inconclusive read),
    # and a genuine absence (a "missing_objects" CREATE self-heal candidate as of the 2026-07-28
    # owner directive -- non-zero exit, but its own category, NEVER merged into "findings", because
    # the two categories drive different self-heal actions -- re-apply vs. create; see
    # write_json_out()'s docstring).
    out_path = tmp_path / "findings.json"
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--json-out", str(out_path)])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "drifted"): ("VIEW", "proj", "01.sql", "SELECT 1 AS x"),
        ("state", "gone"): ("VIEW", "proj", "02.sql", "SELECT 9 AS z"),
        ("state", "flaky"): ("VIEW", "proj", "03.sql", "SELECT 3 AS w"),
    })
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))

    def fake_resolve(views, routines, ds, nm, ot):
        if nm == "gone":
            return None                    # lookup succeeded, zero rows -> missing_objects
        if nm == "flaky":
            raise RuntimeError("timeout")  # lookup failed -> skipped
        return "SELECT 2 AS x"             # drifted mismatches -> findings
    monkeypatch.setattr(clsp, "resolve_live_definition", fake_resolve)
    assert clsp.main() == 1
    payload = json.loads(out_path.read_text())
    assert [f["name"] for f in payload["findings"]] == ["drifted"]     # only the real mismatch is a finding
    assert not any("gone" in f["name"] for f in payload["findings"])   # absence never lands in "findings"
                                                                        # (own key -> own self-heal action,
                                                                        # not "never a self-heal candidate")
    assert any("flaky" in s for s in payload["skipped"])               # the lookup failure is a skip
    assert not any("gone" in s for s in payload["skipped"])            # ...and absence is no longer a skip
    assert any("gone" in s for s in payload["missing_objects"])        # absence gets its own category
    assert "checked_at" in payload


def test_missing_objects_key_extraction_matches_workflow_jq_pattern(tmp_path, monkeypatch):
    """Pins the jq<->Python coupling DEFECT (2026-07-28): .github/workflows/live-sql-parity.yml
    extracts the "<dataset>.<name>" key from each `missing_objects` string with the jq filter (used
    TWICE there -- the per-object ops.ci_findings INSERT loop and the auto-resolve exclusion-set
    UNION query):

        capture("^(?<key>\\S+) \\(")

    jq's capture() never errors on a non-match -- it just omits the named field, so `.key` reads
    null and `-r` renders it as an EMPTY STRING -- if the f-string format main() uses to build a
    missing_objects entry ("<dataset>.<name> (<source_file>): no live object found -- ...") in
    scripts/check_live_sql_parity.py ever changes shape, the workflow would silently write
    ops.ci_findings rows with an empty finding_key instead of failing loudly. Nothing else in this
    repo tests that coupling.

    This test generates a REAL missing_objects entry through the actual main()/write_json_out() code
    path (never hand-writes the string), then shells out to jq with the SAME literal pattern above
    (skipped if jq is not installed) and asserts the extracted key equals the expected
    "<dataset>.<name>". A future editor of either side (this test or the workflow's jq line) should
    update the other in the same pass.
    """
    if shutil.which("jq") is None:
        pytest.skip("jq not installed")
    out_path = tmp_path / "findings.json"
    monkeypatch.setattr(sys, "argv", ["check_live_sql_parity.py", "--json-out", str(out_path)])
    monkeypatch.setattr(clsp, "find_final_definitions", lambda: {
        ("state", "gone"): ("VIEW", "proj", "02_gone.sql", "SELECT 9 AS z"),
    })
    monkeypatch.setattr(clsp, "fetch_live_definitions", lambda project, final: ({}, {}))
    monkeypatch.setattr(clsp, "resolve_live_definition", lambda v, r, ds, nm, ot: None)
    assert clsp.main() == 1
    payload = json.loads(out_path.read_text())
    assert len(payload["missing_objects"]) == 1

    # The SAME anchored jq filter .github/workflows/live-sql-parity.yml applies (both call sites):
    #     jq --argjson i "$i" -r '.missing_objects[$i] | capture("^(?<key>\\S+) \\(") | .key'
    # (a raw string here, not a plain one, so the two literal backslashes before S/( in the jq
    # program source survive Python's own string-literal unescaping -- jq's double-quoted-string
    # grammar requires "\\S"/"\\(" to produce a single literal backslash for the regex engine; a
    # single backslash in the jq source ("\S") is an invalid jq string escape and errors out.)
    result = subprocess.run(
        ["jq", "--argjson", "i", "0", "-r",
         r'.missing_objects[$i] | capture("^(?<key>\\S+) \\(") | .key'],
        input=json.dumps(payload), capture_output=True, text=True, check=True,
    )
    extracted_key = result.stdout.strip()
    assert extracted_key == "state.gone", (
        f"jq extraction from a REAL missing_objects entry {payload['missing_objects'][0]!r} produced "
        f"{extracted_key!r}, not the expected '<dataset>.<name>' -- the workflow's jq pattern and "
        f"check_live_sql_parity.py's f-string format have drifted apart")


# ---- write_json_out(): structured findings/skipped/missing_objects payload ------------------------
def test_write_json_out_shape(tmp_path):
    out_path = tmp_path / "f.json"
    clsp.write_json_out(str(out_path),
                        [{"dataset": "state", "name": "foo", "object_type": "VIEW", "source_file": "01.sql"}],
                        ["state.bar (02.sql): live lookup failed: timeout"],
                        ["state.baz (03.sql): no live object found -- repo's final-effective "
                         "bigquery/*.sql expects this object but live has none (lookup succeeded, "
                         "zero rows)"])
    payload = json.loads(out_path.read_text())
    assert payload["findings"][0]["name"] == "foo"
    assert payload["skipped"] == ["state.bar (02.sql): live lookup failed: timeout"]
    assert payload["missing_objects"] == [
        "state.baz (03.sql): no live object found -- repo's final-effective bigquery/*.sql expects "
        "this object but live has none (lookup succeeded, zero rows)"]
    assert payload["checked_at"].endswith("Z")


# ---- numbered_sql_files(): NUMERIC (not lexical) apply-order --------------------------------------
def test_numbered_sql_files_sorts_numerically_not_lexically(tmp_path, monkeypatch):
    d = tmp_path / "bigquery"
    d.mkdir()
    for fn in ("2_b.sql", "10_c.sql", "1_a.sql", "notes.md", "readme_no_number.sql"):
        (d / fn).write_text("-- x\n")
    monkeypatch.setattr(clsp, "BIGQUERY_DIR", str(d))
    got = [os.path.basename(p) for p in clsp.numbered_sql_files()]
    assert got == ["1_a.sql", "2_b.sql", "10_c.sql"]   # numeric order; unnumbered/non-sql excluded


# ---- canonicalize(): compare MEANING, not formatting (2026-07-18) -----------------------------
# BigQuery RE-SERIALIZES stored view/routine definitions: comments stripped, whitespace next to
# punctuation removed, backticks dropped, string-quote style normalized. The old raw-text compare
# (collapse) therefore reported 70 of 179 objects as DRIFT when only 5 differed in meaning — a 93%
# false-positive rate on the very gate meant to catch the 2026-07-11 silent trading_enabled revert.
# Each test below pins one measured false-positive class; the LAST group pins that real drift still
# fires, so the fix cannot blind the check.

def _same(a, b):
    return clsp.canonicalize(a) == clsp.canonicalize(b)


def test_canonicalize_ignores_comments_the_live_definition_does_not_keep():
    repo = "SELECT a,  -- why this column exists\n       b\nFROM t"
    live = "SELECT a, b FROM t"
    assert _same(repo, live)


def test_canonicalize_ignores_whitespace_adjacent_to_punctuation():
    # The single most common shape: repo `AS (\n  SELECT`, live `AS (SELECT`.
    assert _same("WITH c AS (\n  SELECT 1\n)\nSELECT * FROM c", "WITH c AS (SELECT 1)SELECT * FROM c")
    assert _same("COALESCE(( SELECT 1 ), 0)", "COALESCE((SELECT 1),0)")


def test_canonicalize_ignores_identifier_backticks():
    assert _same("SELECT * FROM `proj.ds.tbl`", "SELECT * FROM proj.ds.tbl")


def test_canonicalize_ignores_string_quote_style():
    assert _same("WHERE series = 'deployed_unit_value'", 'WHERE series = "deployed_unit_value"')


def test_canonicalize_merges_whitespace_left_behind_by_a_removed_comment():
    # Stripping a comment leaves whitespace on BOTH sides; unmerged it yields "wins  FROM" (two
    # spaces) and never matches live. This was the bug that kept 24 objects "drifted" mid-fix.
    assert _same("SELECT wins   -- note\n   FROM t", "SELECT wins FROM t")


def test_canonicalize_keeps_whitespace_that_separates_words():
    # Must NOT fuse tokens: `SELECT x` is not `SELECTx`.
    assert not _same("SELECT x", "SELECTx")
    assert clsp.canonicalize("SELECT   x") == "SELECT x"


# ---- the check must still SEE real drift ------------------------------------------------------

def test_canonicalize_still_detects_an_added_predicate():
    # The measured ops.sp_assert_deps / state.cadence_watch finding: live carries a 14-day window
    # the repo lacks. This is real drift and must survive canonicalization.
    repo = "WHERE r.routine=d AND r.status='completed')"
    live = "WHERE r.routine=d AND r.status='completed' AND r.run_date>=DATE_SUB(in_run_date,INTERVAL 14 DAY))"
    assert not _same(repo, live)


def test_canonicalize_still_detects_an_added_statement():
    # The measured gate-procedure finding: live has a self-heal CALL block the repo lacks.
    repo = "BEGIN DECLARE v BOOL; SET v=(SELECT x FROM t); END"
    live = ("BEGIN DECLARE v BOOL; BEGIN CALL ops.sp_auto_resolve_alerts(); "
            "EXCEPTION WHEN ERROR THEN SELECT @@error.message; END; SET v=(SELECT x FROM t); END")
    assert not _same(repo, live)


def test_canonicalize_treats_string_CONTENT_as_significant():
    # A `--`, an em-dash, or extra spacing INSIDE a literal is content, not formatting. The measured
    # ops.sp_score_theater finding (em-dash vs hyphen in a prompt string) must NOT be swallowed.
    assert not _same("SELECT 'diverges from the attacker — rather than'",
                     "SELECT 'diverges from the attacker - rather than'")
    assert not _same("SELECT 'a  b'", "SELECT 'a b'")
    assert not _same("SELECT 'keep -- this'", "SELECT 'keep'")


def test_canonicalize_handles_empty_and_none():
    assert clsp.canonicalize("") == ""
    assert clsp.canonicalize(None) is None

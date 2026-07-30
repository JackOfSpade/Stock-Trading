"""Guard scripts/lib/sql_files.py's numbered_sql_files()/sql_file_paths() — the shared bigquery/*.sql
apply-order walk (codebase audit 2026-07-26). The whole point of this module is that NUMERIC order
(not lexical `sorted(os.listdir(...))` order) is used once bigquery/ has both 2-digit and 3-digit
file numbers; a regression back to lexical sort here would silently reopen the exact
check_dbt_view_coverage.py bug this module was extracted to fix.
"""
import os

from lib.sql_files import numbered_sql_files, sql_file_paths, strip_sql_comments


def test_numbered_sql_files_sorts_numerically_not_lexically(tmp_path):
    # The regression case: lexical sort puts "100_..." before "95_..." because '1' < '9' as the
    # first character. Numeric sort must put 95 before 100.
    (tmp_path / "100_b.sql").write_text("-- x\n")
    (tmp_path / "95_a.sql").write_text("-- x\n")
    got = numbered_sql_files(str(tmp_path))
    assert got == [(95, str(tmp_path / "95_a.sql")), (100, str(tmp_path / "100_b.sql"))]


def test_numbered_sql_files_mixed_digit_widths(tmp_path):
    for fn in ("2_b.sql", "10_c.sql", "1_a.sql"):
        (tmp_path / fn).write_text("-- x\n")
    got = [(n, os.path.basename(p)) for n, p in numbered_sql_files(str(tmp_path))]
    assert got == [(1, "1_a.sql"), (2, "2_b.sql"), (10, "10_c.sql")]


def test_numbered_sql_files_excludes_unnumbered_and_non_sql(tmp_path):
    (tmp_path / "01_a.sql").write_text("-- x\n")
    (tmp_path / "README.md").write_text("not sql\n")
    (tmp_path / "notes.sql").write_text("-- no leading number\n")
    got = [os.path.basename(p) for _, p in numbered_sql_files(str(tmp_path))]
    assert got == ["01_a.sql"]


def test_numbered_sql_files_empty_dir(tmp_path):
    assert numbered_sql_files(str(tmp_path)) == []


def test_sql_file_paths_matches_numbered_sql_files_paths_only(tmp_path):
    (tmp_path / "100_b.sql").write_text("-- x\n")
    (tmp_path / "95_a.sql").write_text("-- x\n")
    pairs = numbered_sql_files(str(tmp_path))
    assert sql_file_paths(str(tmp_path)) == [path for _, path in pairs]
    # and it's the numerically-sorted order, not lexical
    assert [p.split("/")[-1] for p in sql_file_paths(str(tmp_path))] == ["95_a.sql", "100_b.sql"]


# ---- strip_sql_comments(): comment-hiding for check_superseded_markers.py / -----------------------
# check_dbt_view_coverage.py's DDL regexes (2026-07-29 bug hunt)

def test_strip_sql_comments_blanks_a_line_comment():
    # The confirmed-live regression case: bigquery/02_ai_layer.sql:23's "Reproduce:" recipe has a
    # commented-out CREATE that check_superseded_markers.py's OBJECT_DDL used to match as real DDL.
    text = "SELECT 1;\n--   CREATE OR REPLACE TABLE `p.d.t` AS\n--   SELECT 2 FROM x;\nSELECT 3;\n"
    stripped = strip_sql_comments(text)
    assert "CREATE" not in stripped
    assert "SELECT 2" not in stripped
    assert "SELECT 1" in stripped and "SELECT 3" in stripped


def test_strip_sql_comments_preserves_length_and_newlines():
    # Callers (check_superseded_markers.py's definitions()) map a match.start() in the STRIPPED text
    # back to a line number using offsets built from the ORIGINAL text — that only works if stripping
    # never changes the text's length or where its newlines fall.
    text = "AAA\n-- comment one\nBBB\n/* block\ncomment */\nCCC\n"
    stripped = strip_sql_comments(text)
    assert len(stripped) == len(text)
    assert [i for i, c in enumerate(text) if c == "\n"] == [i for i, c in enumerate(stripped) if c == "\n"]


def test_strip_sql_comments_blanks_a_block_comment_keeping_internal_newlines():
    text = "AAA\n/* CREATE OR REPLACE VIEW `p.d.t`\n   spanning two lines */\nBBB\n"
    stripped = strip_sql_comments(text)
    assert "CREATE" not in stripped
    assert stripped.count("\n") == text.count("\n")
    assert "AAA" in stripped and "BBB" in stripped


def test_strip_sql_comments_does_not_treat_a_dash_dash_inside_a_string_literal_as_a_comment():
    # This repo routinely uses a bare `--` as an em-dash inside a quoted description (e.g.
    # bigquery/03_twr_engine.sql:229's TWR-chain error message) -- a comment-stripper that doesn't
    # track string literals would corrupt the literal and could hide real code sharing its line.
    text = "SELECT 'clamped to avoid NULL -- corrupting the chain' AS msg, CREATE_LOOKS_LIKE_CODE;\n"
    stripped = strip_sql_comments(text)
    assert "corrupting the chain" in stripped
    assert "CREATE_LOOKS_LIKE_CODE" in stripped


def test_strip_sql_comments_handles_double_quoted_and_unterminated_literals():
    # Double-quoted literal survives verbatim; an unterminated single-line literal (no closing quote
    # before EOL) must not run the string-scan off the end of the file looking for a close.
    text = 'SELECT "a -- b" AS x;\nSELECT \'unterminated\n-- real comment after\nSELECT 1;\n'
    stripped = strip_sql_comments(text)
    assert "a -- b" in stripped
    assert "real comment" not in stripped
    assert "SELECT 1" in stripped


def test_strip_sql_comments_empty_string():
    assert strip_sql_comments("") == ""

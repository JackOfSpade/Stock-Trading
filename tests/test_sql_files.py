"""Guard scripts/lib/sql_files.py's numbered_sql_files()/sql_file_paths() — the shared bigquery/*.sql
apply-order walk (codebase audit 2026-07-26). The whole point of this module is that NUMERIC order
(not lexical `sorted(os.listdir(...))` order) is used once bigquery/ has both 2-digit and 3-digit
file numbers; a regression back to lexical sort here would silently reopen the exact
check_dbt_view_coverage.py bug this module was extracted to fix.

Also guards OBJECT_DDL/normalize_kind() and line_offsets() (2026-08-08 dedup): previously two
hand-written, independently-drifting copies in check_superseded_markers.py and
check_superseded_by_discipline.py (OBJECT_DDL/normalize_kind), and in check_superseded_markers.py and
check_sq_version_registry.py (line_offsets). Both are BLOCKING CI gates, so a regression here can
silently blind either one to a class of bigquery/*.sql definition or mis-locate every line number it
reports.
"""
import bisect
import os

from lib.sql_files import (
    OBJECT_DDL,
    line_offsets,
    normalize_kind,
    numbered_sql_files,
    resolve_canonical,
    sql_file_paths,
    strip_sql_comments,
)

PROJECT = "stock-trading-498512"


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


# ---- line_offsets(): shared by check_superseded_markers.py (0-based) and ---------------------------
# check_sq_version_registry.py (1-based via its own _line_no() wrapper) (2026-08-08 dedup)

def test_line_offsets_no_newlines_is_just_the_start():
    assert line_offsets("no newlines here") == [0]


def test_line_offsets_empty_string():
    assert line_offsets("") == [0]


def test_line_offsets_matches_manual_count_across_several_lines():
    # "a\nbb\nccc\n" -> line starts at 0 ("a"), 2 ("bb"), 5 ("ccc"), 9 (the empty line after the
    # trailing newline). Written out longhand rather than derived, so this test can't share a bug
    # with the implementation it's checking.
    text = "a\nbb\nccc\n"
    assert line_offsets(text) == [0, 2, 5, 9]


def test_line_offsets_bisect_recovers_both_the_0_based_and_1_based_line_conventions():
    # The two real callers want different conventions from the SAME offsets list (see this module's
    # docstring): check_superseded_markers.py does `bisect.bisect_right(offsets, pos) - 1` for a
    # 0-based line index; check_sq_version_registry.py's _line_no() does the bare bisect for a
    # 1-based line number. Both must land on "ccc" (line 3 / index 2) for a position inside it.
    text = "a\nbb\nccc\n"
    offsets = line_offsets(text)
    pos = text.index("ccc")
    assert bisect.bisect_right(offsets, pos) - 1 == 2   # 0-based: text.splitlines()[2] == "ccc"
    assert bisect.bisect_right(offsets, pos) == 3        # 1-based line number


# ---- normalize_kind(): shared by check_superseded_markers.py and ------------------------------------
# check_superseded_by_discipline.py, pre-consolidation spelled two different (but equivalent) ways
# (2026-08-08 dedup)

def test_normalize_kind_uppercases_a_single_word():
    assert normalize_kind("view") == "VIEW"
    assert normalize_kind("procedure") == "PROCEDURE"


def test_normalize_kind_collapses_internal_whitespace_to_a_single_space():
    # OBJECT_DDL's `\s+` between two keywords can capture a newline when a CREATE statement is
    # legally wrapped across lines (e.g. "TABLE\n  FUNCTION"); the normalized kind must still read
    # as the single canonical string used everywhere else ("TABLE FUNCTION").
    assert normalize_kind("table\n  function") == "TABLE FUNCTION"
    assert normalize_kind("materialized   view") == "MATERIALIZED VIEW"


# ---- OBJECT_DDL: shared by check_superseded_markers.py and check_superseded_by_discipline.py --------
# (2026-08-08 dedup; the two pre-consolidation copies differed only in ALTERNATION ORDER, verified
# behaviorally identical — see scripts/lib/sql_files.py's module docstring)

def test_object_ddl_matches_every_kind_with_correct_groups():
    cases = [
        ("VIEW", f"CREATE OR REPLACE VIEW `{PROJECT}.state.thing` AS SELECT 1;", "state"),
        ("MATERIALIZED VIEW", f"CREATE MATERIALIZED VIEW `{PROJECT}.state.thing` AS SELECT 1;", "state"),
        ("TABLE FUNCTION",
         f"CREATE OR REPLACE TABLE FUNCTION `{PROJECT}.analytics.thing`() AS SELECT 1;", "analytics"),
        ("FUNCTION", f"CREATE OR REPLACE FUNCTION `{PROJECT}.ops.thing`() AS (1);", "ops"),
        ("PROCEDURE",
         f"CREATE OR REPLACE PROCEDURE `{PROJECT}.ops.thing`() BEGIN SELECT 1; END;", "ops"),
        ("TABLE", f"CREATE TABLE `{PROJECT}.state.thing` (a INT64);", "state"),
    ]
    for kind, ddl, dataset in cases:
        m = OBJECT_DDL.search(ddl)
        assert m is not None, ddl
        assert normalize_kind(m.group(1)) == kind, ddl
        assert (m.group(2), m.group(3)) == (dataset, "thing")


# ---- resolve_canonical(): the D6 duplicate-number ambiguity contract ---------------------------
# Three BLOCKING gates (check_cadence_consistency.py, check_sq_version_registry.py,
# check_superseded_by_discipline.py) resolve "which bigquery/*.sql file is canonical for this
# object" through this one function and then branch on `len(winner_filenames) > 1` to fail loud on
# an ambiguous duplicate NN prefix. It had NO direct coverage until the 2026-08-22 quality pass —
# only transitive exercise through the three callers' own fixtures, none of which construct a tie.
def test_resolve_canonical_returns_the_highest_number_and_its_single_file():
    occs = [(90, "090_a.sql"), (114, "114_b.sql"), (35, "035_c.sql")]
    assert resolve_canonical(occs) == (114, ["114_b.sql"])


def test_resolve_canonical_returns_every_file_tied_at_the_winning_number():
    """The D6 contract: a duplicate NN prefix on a TRACKED object must surface ALL colliding
    filenames so the caller can report an explicit ambiguity error, never silently pick one."""
    occs = [(114, "114_selfheal.sql"), (114, "114_period_gate.sql"), (90, "090_older.sql")]
    assert resolve_canonical(occs) == (114, ["114_period_gate.sql", "114_selfheal.sql"])


def test_resolve_canonical_dedupes_repeated_filenames_at_the_winning_number():
    # Several matches inside ONE file (the common case: a file mentioning the same object twice)
    # is not an ambiguity — it must collapse to a single filename, or every caller's
    # `len(winner_files) > 1` check would fire a false ambiguity error.
    occs = [(114, "114_b.sql", 10), (114, "114_b.sql", 400), (90, "090_a.sql", 5)]
    assert resolve_canonical(occs) == (114, ["114_b.sql"])


def test_resolve_canonical_ignores_trailing_tuple_elements():
    # Callers pass (number, filename, match_position); the extra element is absorbed by `*_`.
    assert resolve_canonical([(7, "007_x.sql", 123, "extra")]) == (7, ["007_x.sql"])


def test_resolve_canonical_accepts_a_generator_without_losing_the_tied_set():
    """REGRESSION (quality pass 2026-08-22). The docstring advertises `occurrences` as "an iterable
    of tuples", but the body scanned it TWICE — max(), then the tied-set comprehension. A generator
    was exhausted by the first pass, so winner_filenames came back EMPTY: the ambiguity branch
    could never fire and the caller's follow-on `winner_filenames[0]` raised IndexError, crashing
    out of the fail-clean error-collection path these gates depend on. Every caller passes a list
    today, so the defect was latent — this pins the documented contract so it stays true."""
    occs = [(114, "114_b.sql"), (114, "114_a.sql"), (90, "090_c.sql")]
    from_list = resolve_canonical(occs)
    from_generator = resolve_canonical(o for o in occs)
    assert from_generator == from_list == (114, ["114_a.sql", "114_b.sql"])


def test_object_ddl_table_function_is_not_shadowed_by_the_shorter_table_alternative():
    # The one pair in this alternation where ORDER could matter: TABLE is a prefix of TABLE FUNCTION.
    # Both pre-consolidation copies listed TABLE FUNCTION before TABLE (so this always passed), but
    # pin it explicitly so a future reordering that puts TABLE first fails loud instead of silently
    # truncating every TABLE FUNCTION match to a plain TABLE kind.
    ddl = f"CREATE OR REPLACE TABLE FUNCTION `{PROJECT}.analytics.find_precedents`() AS SELECT 1;"
    m = OBJECT_DDL.search(ddl)
    assert m is not None
    assert normalize_kind(m.group(1)) == "TABLE FUNCTION"


def test_object_ddl_ignores_if_not_exists_and_a_different_project():
    ddl_if_not_exists = f"CREATE TABLE IF NOT EXISTS `{PROJECT}.state.thing` (a INT64);"
    m = OBJECT_DDL.search(ddl_if_not_exists)
    assert m is not None
    assert (m.group(1).upper(), m.group(2), m.group(3)) == ("TABLE", "state", "thing")

    other_project = "CREATE TABLE `some-other-project.state.thing` (a INT64);"
    assert OBJECT_DDL.search(other_project) is None

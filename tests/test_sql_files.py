"""Guard scripts/lib/sql_files.py's numbered_sql_files()/sql_file_paths() — the shared bigquery/*.sql
apply-order walk (codebase audit 2026-07-26). The whole point of this module is that NUMERIC order
(not lexical `sorted(os.listdir(...))` order) is used once bigquery/ has both 2-digit and 3-digit
file numbers; a regression back to lexical sort here would silently reopen the exact
check_dbt_view_coverage.py bug this module was extracted to fix.
"""
import os

from lib.sql_files import numbered_sql_files, sql_file_paths


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

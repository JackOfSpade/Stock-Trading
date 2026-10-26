"""Guard scripts/check_shock_register_lockstep.py — Strategy.md register table <-> SQL seed lockstep.

Each failure test mutates a tmp copy of the REAL files (so the fixture cannot drift from the shape the
checker must parse), asserts the mutation actually happened, and then asserts both the exit code and
that the diagnostic names the specific strategy and column — never a generic substring.
"""
import os
import re

from conftest import load_module_from_path

cs = load_module_from_path("check_shock_register_lockstep", "scripts", "check_shock_register_lockstep.py")

REAL_REPO = cs.REPO
REAL_SQL_REL, _ = cs.resolve_sql()
SQL_NAME = os.path.basename(REAL_SQL_REL)


def _read(rel):
    with open(os.path.join(REAL_REPO, rel), encoding="utf-8") as f:
        return f.read()


def _make_repo(tmp_path, monkeypatch, md=None, sql=None):
    (tmp_path / "bigquery").mkdir()
    (tmp_path / "Strategy.md").write_text(md if md is not None else _read("Strategy.md"), encoding="utf-8")
    (tmp_path / "bigquery" / SQL_NAME).write_text(sql if sql is not None else _read(REAL_SQL_REL), encoding="utf-8")
    monkeypatch.setattr(cs, "REPO", str(tmp_path))


# Rev 53 (2026-10-23) withdrew E's gate, so the live register has no numeric gate left. The gate-value
# tests run on the Rev 50 shape instead: bigquery/257's seed (E gated 0.85 / 0.60 / 35) and a Strategy.md
# whose E row is restored to match it.
REV50_SQL_REL = "bigquery/257_shock_transmission_register.sql"
REV50_E_ROW = "| E | SPREAD | yes | 0.85 | 60% | 35 | status-quo | Rev 50 gated row (test fixture). |"


def _gated_fixture():
    md = _read("Strategy.md")
    row = next(line for line in md.splitlines() if line.startswith("| E | SPREAD |"))
    gated_md = md.replace(row, REV50_E_ROW, 1)
    assert gated_md != md
    return gated_md, _read(REV50_SQL_REL)


def _run(capsys):
    rc = cs.main()
    out = capsys.readouterr()
    return rc, out.out, out.err


# (1) ------------------------------------------------------------------------------------------

def test_real_repo_passes(capsys):
    rc, out, err = _run(capsys)
    assert rc == 0, err
    assert "agree on 5 rows: A, B, C, D, E" in out
    assert err == ""


def test_real_repo_parses_expected_e_row():
    table = cs.parse_table(_read("Strategy.md"))
    sql = cs.parse_sql(_read(REAL_SQL_REL), REAL_SQL_REL)
    assert sorted(table) == sorted(sql) == ["A", "B", "C", "D", "E"]
    e = sql["E"][1]
    # Rev 53: E binds, no gate (router review premortem-router-2026-a1 cycle 1, T1-1)
    assert e["transmission_class"] == "SPREAD"
    assert e["exempt_by_class"] is False
    assert e["gate_median_60d_max"] is None and e["gate_share_ge_080_max"] is None and e["gate_max_age_days"] is None
    # the note is a long prose literal with commas and parentheses inside the quotes; it must parse as ONE
    # field (BigQuery has no '' escape -- a doubled quote is a syntax error -- so the seed avoids apostrophes)
    assert "exemption withdrawn" in e["note"]
    assert "'" not in e["note"]
    assert table["E"][1]["exempt_by_class"] is False and table["E"][1]["gate_share_ge_080_max"] is None
    assert sql["A"][1]["gate_median_60d_max"] is None and table["A"][1]["gate_median_60d_max"] is None


def test_rev50_seed_still_parses_gated_e_row():
    sql = cs.parse_sql(_read(REV50_SQL_REL), REV50_SQL_REL)
    e = sql["E"][1]
    assert e["exempt_by_class"] is True
    assert e["gate_median_60d_max"] == cs.Decimal("0.85")
    assert e["gate_share_ge_080_max"] == cs.Decimal("0.60")
    assert e["gate_max_age_days"] == 35
    assert "failure channel E itself names" in e["note"]


def test_table_reexempting_e_fails_naming_e_and_exempt(tmp_path, monkeypatch, capsys):
    md = _read("Strategy.md")
    mutated = md.replace("| E | SPREAD | no |", "| E | SPREAD | yes |", 1)
    assert mutated != md
    _make_repo(tmp_path, monkeypatch, md=mutated)
    rc, _out, err = _run(capsys)
    assert rc == 1
    mism = [line for line in err.splitlines() if "MISMATCH" in line]
    assert len(mism) == 1
    assert re.match(r"ERROR: Strategy\.md:\d+: strategy E column 'Exempt by class' \(exempt_by_class\) MISMATCH", mism[0])


# (2) ------------------------------------------------------------------------------------------

def test_table_median_gate_change_fails_naming_e_and_median(tmp_path, monkeypatch, capsys):
    md, sql = _gated_fixture()
    mutated = md.replace("| E | SPREAD | yes | 0.85 |", "| E | SPREAD | yes | 0.90 |", 1)
    assert mutated != md
    _make_repo(tmp_path, monkeypatch, md=mutated, sql=sql)
    rc, _out, err = _run(capsys)
    assert rc == 1
    mism = [line for line in err.splitlines() if "MISMATCH" in line]
    assert len(mism) == 1
    assert re.match(r"ERROR: Strategy\.md:\d+: strategy E column '.*median.*' \(gate_median_60d_max\) MISMATCH", mism[0])
    assert "table 0.90" in mism[0] and "0.85" in mism[0]


# (3) ------------------------------------------------------------------------------------------

def test_sql_struct_removed_fails_naming_missing_code(tmp_path, monkeypatch, capsys):
    sql = _read(REAL_SQL_REL)
    mutated = re.sub(r"(?m)^\s*STRUCT\('D',.*\n", "", sql, count=1)
    assert mutated != sql
    _make_repo(tmp_path, monkeypatch, sql=mutated)
    rc, _out, err = _run(capsys)
    assert rc == 1
    assert re.search(r"Strategy\.md:\d+: strategy D present in Strategy\.md but MISSING from the SQL seed", err)
    assert "strategy C present" not in err and "strategy E present" not in err


# (4) ------------------------------------------------------------------------------------------

def test_duplicated_table_row_fails(tmp_path, monkeypatch, capsys):
    md = _read("Strategy.md")
    row = next(line for line in md.splitlines() if line.startswith("| A | DIRECTIONAL-LONG |"))
    mutated = md.replace(row + "\n", row + "\n" + row + "\n", 1)
    assert mutated != md
    _make_repo(tmp_path, monkeypatch, md=mutated)
    rc, _out, err = _run(capsys)
    assert rc == 1
    assert re.search(r"Strategy\.md:\d+: duplicate strategy code A in the Strategy\.md register table "
                     r"\(first at Strategy\.md:\d+\)", err)


# (5) ------------------------------------------------------------------------------------------

def test_missing_table_header_fails(tmp_path, monkeypatch, capsys):
    md = _read("Strategy.md")
    header = next(line for line in md.splitlines() if line.startswith("| Strategy | Transmission class |"))
    mutated = md.replace(header + "\n", "", 1)
    assert mutated != md
    _make_repo(tmp_path, monkeypatch, md=mutated)
    rc, out, err = _run(capsys)
    assert rc == 1
    assert "Strategy.md:1: MISSING ANCHOR — could not find the Shock Transmission Register table header" in err
    assert out == ""


def test_missing_insert_anchor_fails(tmp_path, monkeypatch, capsys):
    sql = _read(REAL_SQL_REL)
    mutated = sql.replace(cs.INSERT_ANCHOR, "INSERT INTO `stock-trading-498512.ops.something_else`")
    assert mutated != sql
    _make_repo(tmp_path, monkeypatch, sql=mutated)
    rc, _out, err = _run(capsys)
    assert rc == 1
    assert "MISSING ANCHOR — no bigquery/NNN_*.sql contains" in err


# (6) ------------------------------------------------------------------------------------------

def test_share_percent_vs_numeric_equal():
    t = cs._parse_table_value("60%", "num", "x:1", "E", "share")
    assert cs._equal(t, cs._parse_sql_value("NUMERIC '0.60'"), "num")
    assert not cs._equal(t, cs._parse_sql_value("NUMERIC '0.50'"), "num")


def test_share_sql_changed_to_050_fails_naming_e_and_share(tmp_path, monkeypatch, capsys):
    md, sql = _gated_fixture()
    mutated = sql.replace("NUMERIC '0.60'", "NUMERIC '0.50'", 1)
    assert mutated != sql
    _make_repo(tmp_path, monkeypatch, md=md, sql=mutated)
    rc, _out, err = _run(capsys)
    assert rc == 1
    mism = [line for line in err.splitlines() if "MISMATCH" in line]
    assert len(mism) == 1
    assert re.match(r"ERROR: Strategy\.md:\d+: strategy E column '.*share.*' \(gate_share_ge_080_max\) MISMATCH", mism[0])
    assert "table 0.6" in mism[0] and "0.50" in mism[0]


# resolution -----------------------------------------------------------------------------------

def test_higher_numbered_reregistration_file_supersedes(tmp_path, monkeypatch, capsys):
    md, sql = _gated_fixture()
    _make_repo(tmp_path, monkeypatch, md=md, sql=sql)
    later = sql.replace("35,", "40,", 1)
    assert later != sql
    (tmp_path / "bigquery" / "999_shock_reregistration.sql").write_text(later, encoding="utf-8")
    rc, _out, err = _run(capsys)
    assert rc == 1
    assert re.search(r"strategy E column '.*max measurement age.*' \(gate_max_age_days\) MISMATCH — table 35 vs "
                     r"bigquery/999_shock_reregistration\.sql:\d+ 40", err)

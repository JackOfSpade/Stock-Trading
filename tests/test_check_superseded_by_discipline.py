"""Regression tests for the append-only correction-reader checker.

TEST-COVERAGE FIX (2026-08-31 code-quality pass, contracts#1). This file previously had 3 tests, none
of which exercised the two failure modes the script's own docstring names as its reason for existing:
  1. The ALLOWLIST staleness self-defense (`stale = sorted(set(ALLOWLIST) - used_allowlist)`) -- what
     stops the real 21-entry ALLOWLIST from silently outliving its subjects -- had zero coverage.
  2. `_definition_segments()`'s own docstring is literally titled "THE BUG THIS SHAPE EXISTS TO FIX":
     a free-standing statement (ALTER/UPDATE/INSERT/...) sitting between two CREATEs used to silently
     inherit the PRECEDING object's ALLOWLIST reason by text position -- the real bigquery/143 incident
     this script was written to close -- and no synthetic fixture recreated that shape to prove the fix
     holds for a NEW instance; the only coverage was test_real_repo_passes_the_superseded_by_discipline_
     gate(), an integration smoke test against the CURRENT live tree that cannot detect a regression
     that stays green on today's specific file contents.
test_free_standing_statement_between_two_creates_gets_its_own_violation and
test_stale_allowlist_entry_is_reported_and_fails below close those two gaps with synthetic bigquery/
trees, mirroring test_check_superseded_markers.py's own plant-a-tree-and-monkeypatch-BIGQUERY_DIR
convention (already used by this file's own `_tree()` helper).
"""
from conftest import load_module_from_path


cs = load_module_from_path("check_superseded_by_discipline", "scripts", "check_superseded_by_discipline.py")


def _tree(tmp_path, files, monkeypatch):
    directory = tmp_path / "bigquery"
    directory.mkdir()
    for name, text in files.items():
        (directory / name).write_text(text, encoding="utf-8")
    monkeypatch.setattr(cs, "BIGQUERY_DIR", str(directory))
    monkeypatch.setattr(cs, "ALLOWLIST", {})


def test_real_repo_passes_the_superseded_by_discipline_gate():
    assert cs.main() == 0


def test_control_flow_on_a_procedure_parameter_is_not_a_row_filter(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_writer.sql": """
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_writer`(p_superseded_by STRING)
BEGIN
  IF p_superseded_by IS NULL THEN
    SELECT 1;
  END IF;
END;
""",
    }, monkeypatch)
    assert cs.main() == 0


def test_real_inverted_filter_is_still_rejected(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_bad_view.sql": """
CREATE OR REPLACE VIEW `stock-trading-498512.state.bad` AS
SELECT *
FROM `stock-trading-498512.events.adversarial_reviews` a
WHERE a.superseded_by IS NULL;
""",
    }, monkeypatch)
    assert cs.main() == 1


def test_free_standing_statement_between_two_creates_gets_its_own_violation(tmp_path, monkeypatch, capsys):
    """Recreates the bigquery/143 shape `_definition_segments()` exists to fix (see that function's
    own "THE BUG THIS SHAPE EXISTS TO FIX" docstring): a free-standing UPDATE sitting between a VIEW's
    CREATE and a later PROCEDURE's CREATE must be evaluated on ITS OWN merits, not silently absorbed
    into the PRECEDING view's ALLOWLIST reason just because it sits after that view's text.

    The view's own definition legitimately reads events.decision_log raw (it IS the anti-join) and is
    allowlisted for exactly that; the free-standing UPDATE reads the same raw table for an unrelated
    reason and carries NO allowlist entry of its own -- so main() must still fail, and specifically on
    the free-standing statement, proving the UPDATE did not ride the view's pass.
    """
    filename = "10_writer.sql"
    _tree(tmp_path, {
        filename: """
CREATE OR REPLACE VIEW `stock-trading-498512.state.decision_log_current` AS
SELECT *
FROM `stock-trading-498512.events.decision_log`
WHERE entry_id NOT IN (SELECT superseded_by FROM `stock-trading-498512.events.decision_log` WHERE superseded_by IS NOT NULL);

UPDATE `stock-trading-498512.analytics.some_table` T
SET x = (SELECT y FROM `stock-trading-498512.events.decision_log` WHERE entry_id = T.source_id);

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_noop`()
BEGIN
  SELECT 1;
END;
""",
    }, monkeypatch)
    # Allowlist ONLY the view's own canonical definition -- never the free-standing UPDATE.
    monkeypatch.setattr(cs, "ALLOWLIST", {
        (filename, "state.decision_log_current"):
            "test fixture: this view IS the anti-join, so it must read the base table.",
    })
    rc = cs.main()
    out = capsys.readouterr().out
    assert rc == 1
    assert "a file-level statement (outside any CREATE definition)" in out, out
    # The VIEW's own canonical definition must NOT be reported -- it is correctly allowlisted, and the
    # whole point of this test is that the UPDATE does not get to ride that pass.
    assert "canonical definition of state.decision_log_current" not in out, out


def test_stale_allowlist_entry_is_reported_and_fails(tmp_path, monkeypatch, capsys):
    """The ALLOWLIST staleness self-defense (`stale = sorted(set(ALLOWLIST) - used_allowlist)`) is
    what stops the real, 21-entry ALLOWLIST from silently outliving its subjects. An entry that points
    at an object which no longer reads the raw guarded table at all -- because the object's definition
    changed, or the entry was mistyped -- must fail main() under STALE ALLOWLIST, not sit unused
    forever with nothing to catch it going quietly wrong."""
    filename = "10_clean_view.sql"
    _tree(tmp_path, {
        filename: """
CREATE OR REPLACE VIEW `stock-trading-498512.state.clean_view` AS
SELECT 1 AS a;
""",
    }, monkeypatch)
    # This entry's subject (state.clean_view) reads nothing at all, let alone a guarded table raw --
    # exactly the "outlived its subject" shape the staleness sweep exists to catch.
    monkeypatch.setattr(cs, "ALLOWLIST", {
        (filename, "state.clean_view"): "test fixture: stale on purpose -- nothing here reads a guarded table.",
    })
    rc = cs.main()
    out = capsys.readouterr().out
    assert rc == 1
    assert "STALE ALLOWLIST" in out, out
    assert filename in out and "state.clean_view" in out, out

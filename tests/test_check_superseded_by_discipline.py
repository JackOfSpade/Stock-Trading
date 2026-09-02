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


def test_string_literal_begin_in_procedure_signature_does_not_hide_a_trailing_raw_read(tmp_path, monkeypatch, capsys):
    """Locating a PROCEDURE's own body-opening BEGIN used to be a raw, un-tokenized `\\bBEGIN\\b` regex
    search over the chunk text (mirroring check_live_sql_parity.extract_body()'s OLD, since-fixed
    approach — see that function's 2026-08-22 comment). A STRING DEFAULT parameter note containing the
    word BEGIN (e.g. "Runs once at the BEGIN of the trading day") won that match before the real body
    keyword did, so find_procedure_body_end() was handed an offset inside the procedure's own
    signature, found no matching END for a BEGIN that was never really there, and returned None.

    `if body_end is not None: ... chunk = chunk[:body_end]` is skipped entirely when None -- so NO
    truncation happened, and the whole segment (procedure body PLUS a trailing free-standing UPDATE up
    to the next CREATE) was folded into the procedure's own (dataset, name) key and silently rode ITS
    allowlist entry. That is exactly the bigquery/143 bug _definition_segments() exists to prevent,
    reintroduced through this different vector.

    The procedure's own raw read of events.decision_log IS allowlisted below (it's the only entry);
    the free-standing UPDATE's raw read is NOT and must earn its own violation. Against the pre-fix
    PROCEDURE_BEGIN regex, `begin.start()` lands inside the STRING DEFAULT literal,
    find_procedure_body_end() returns None, and the free-standing UPDATE rides the procedure's pass —
    main() returns 0. Against the fix (sql_tokens()-based location, which skips string-literal
    content), BEGIN is correctly found at the real body opener, the procedure body is truncated at its
    own END, and the UPDATE is scanned and reported on its own merits.
    """
    filename = "01_fake.sql"
    _tree(tmp_path, {
        filename: """
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_example`(
  in_note STRING DEFAULT 'Runs once at the BEGIN of the trading day'
)
BEGIN
  SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`;
END;

UPDATE `stock-trading-498512.analytics.unrelated_table` T
SET c = (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log` d WHERE d.x = T.x);
""",
    }, monkeypatch)
    monkeypatch.setattr(cs, "ALLOWLIST", {
        (filename, "ops.sp_example"): "test fixture: pretend legit reason for the procedure's OWN read.",
    })
    rc = cs.main()
    out = capsys.readouterr().out
    assert rc == 1, out
    assert "a file-level statement (outside any CREATE definition)" in out, out
    # The PROCEDURE's own canonical definition must NOT be reported -- it is correctly allowlisted;
    # the whole point is that the free-standing UPDATE does not get to ride that pass by having its
    # text folded into the procedure's body via a mislocated BEGIN.
    assert "canonical definition of ops.sp_example" not in out, out


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

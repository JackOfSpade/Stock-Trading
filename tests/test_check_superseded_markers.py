"""Guard scripts/check_superseded_markers.py — the mechanical enforcement of bigquery/*.sql's
supersede-only discipline (2026-07-18).

That discipline is otherwise enforced only by hand-written comments, and it silently rotted twice:
once when bigquery/23's state.trading_enabled was re-applied live in isolation (clobbering 34's
already-deployed fix and re-latching the trading gate for 3+ days), and once when 47 was left
asserting it was "the new single source of truth" long after 78 superseded it, with 23 and 34 both
pointing forward to the by-then-stale 47. The checker exists to make that impossible to reintroduce,
so it must itself be proven to FIRE — a checker that vacuously passes is worse than none.

These build synthetic bigquery/ trees in tmp_path and point the module's BIGQUERY_DIR at them, so no
assertion depends on the real repo's evolving contents (except the one live-guard test, which pins
that the repo currently has no NEW violations).
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_superseded_markers.py")
    spec = importlib.util.spec_from_file_location("check_superseded_markers", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cs = _load()

DDL = "CREATE OR REPLACE VIEW `stock-trading-498512.state.thing` AS SELECT 1 AS a;\n"


def _tree(tmp_path, files, monkeypatch):
    """files = {filename: text}; point the checker at this synthetic bigquery/ dir."""
    d = tmp_path / "bigquery"
    d.mkdir(exist_ok=True)
    for name, text in files.items():
        (d / name).write_text(text, encoding="utf-8")
    monkeypatch.setattr(cs, "BIGQUERY_DIR", str(d))
    monkeypatch.setattr(cs, "BASELINE", frozenset())
    return d


# ---- the live guard -------------------------------------------------------------------------

def test_real_repo_has_no_new_violations():
    # The whole point: the repo must stay clean of NEW unmarked/stale-pointer definitions.
    new, _still, stale = cs.violations()
    assert new == [], f"new superseded-marker violation(s): {new}"
    assert stale == [], f"stale BASELINE entry/entries — delete them from the script: {stale}"


def test_real_repo_trading_enabled_cluster_is_marked():
    # The cluster that motivated this check (23/34/47 -> 78, and 33/34's _mechanical -> 78) must be
    # compliant, and must NOT be sitting in the grandfather list.
    for entry in (("VIEW", "state", "trading_enabled", "23_trading_control.sql"),
                  ("VIEW", "state", "trading_enabled", "34_alert_lifecycle.sql"),
                  ("VIEW", "state", "trading_enabled", "47_trading_enabled_resync.sql"),
                  ("VIEW", "state", "trading_enabled_mechanical", "33_gate_ordering_fix.sql"),
                  ("VIEW", "state", "trading_enabled_mechanical", "34_alert_lifecycle.sql")):
        assert entry not in cs.BASELINE, f"{entry} must be genuinely marked, not baselined"


# ---- marks_superseded(): both halves are load-bearing ----------------------------------------

def test_marker_needs_both_the_word_and_the_canonical_pointer():
    assert cs.marks_superseded("-- SUPERSEDED LIVE by bigquery/78_foo.sql", 78) is True
    # a supersede word with no pointer at all is not enough
    assert cs.marks_superseded("-- SUPERSEDED, do not apply", 78) is False
    # a pointer with no supersede word is not enough (e.g. a passing mention of 78)
    assert cs.marks_superseded("-- see bigquery/78_foo.sql for context", 78) is False


def test_marker_accepts_the_repo_reference_spellings():
    for text in ("-- superseded by bigquery/78_book.sql",
                 "-- SUPERSEDED — see 78_book_drawdown.sql",
                 "-- superseded live by 78"):
        assert cs.marks_superseded(text, 78) is True, text


def test_zero_padded_file_numbers_match():
    # bigquery/03_twr_engine.sql is canonical for some objects; a "3" or "03" pointer must both work.
    assert cs.marks_superseded("-- superseded by bigquery/03_twr_engine.sql", 3) is True
    assert cs.marks_superseded("-- superseded by bigquery/3", 3) is True


# ---- the two failure modes it must catch ------------------------------------------------------

def test_unmarked_old_definition_is_flagged(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_old.sql": "-- just an ordinary header\n" + DDL,
        "20_new.sql": "-- ===== state.thing — REDEFINED (SUPERSEDES bigquery/10) =====\n" + DDL,
    }, monkeypatch)
    new, _still, _stale = cs.violations()
    assert len(new) == 1
    (kind, ds, name, fn), canonical_file, _line = new[0]
    assert (kind, ds, name, fn) == ("VIEW", "state", "thing", "10_old.sql")
    assert canonical_file == "20_new.sql"


def test_pointer_to_an_intermediate_that_is_itself_superseded_is_flagged(tmp_path, monkeypatch):
    # THE regression this check was written for: 23/34 pointed at 47, but 78 had superseded 47, so
    # every path through the chain dead-ended at a non-canonical file. Naming the intermediate must
    # NOT satisfy the check — only the CURRENT canonical file does.
    _tree(tmp_path, {
        "10_old.sql": "-- SUPERSEDED LIVE by bigquery/20_mid.sql\n" + DDL,   # stale: 30 is canonical now
        "20_mid.sql": "-- SUPERSEDED LIVE by bigquery/30_new.sql\n" + DDL,   # correctly points at 30
        "30_new.sql": "-- canonical\n" + DDL,
    }, monkeypatch)
    new, _still, _stale = cs.violations()
    assert [v[0][3] for v in new] == ["10_old.sql"], "only the stale-pointer file should be flagged"
    assert new[0][1] == "30_new.sql"


def test_marked_old_definition_passes(tmp_path, monkeypatch):
    _tree(tmp_path, {
        "10_old.sql": "-- SUPERSEDED LIVE by bigquery/20_new.sql — do not re-apply.\n" + DDL,
        "20_new.sql": "-- canonical\n" + DDL,
    }, monkeypatch)
    assert cs.violations()[0] == []


def test_top_of_file_banner_counts_not_just_the_line_above(tmp_path, monkeypatch):
    # bigquery/47 carries its banner at the top of the file, far above the CREATE — that must satisfy
    # the check (the operator sees it on opening the file).
    _tree(tmp_path, {
        "10_old.sql": ("-- ==== SUPERSEDED — DO NOT APPLY: see bigquery/20_new.sql ====\n"
                       "-- (long rationale)\n\nSELECT 1;\n\n-- unrelated section comment\n" + DDL),
        "20_new.sql": "-- canonical\n" + DDL,
    }, monkeypatch)
    assert cs.violations()[0] == []


def test_single_definition_is_never_flagged(tmp_path, monkeypatch):
    # An object defined in exactly one file has nothing to be superseded by.
    _tree(tmp_path, {"10_only.sql": "-- no marker needed\n" + DDL}, monkeypatch)
    assert cs.violations()[0] == []


def test_non_view_object_kinds_are_covered(tmp_path, monkeypatch):
    # PROCEDUREs/TABLE FUNCTIONs carry the same re-apply hazard as views.
    proc = "CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_x`() BEGIN SELECT 1; END;\n"
    _tree(tmp_path, {"10_old.sql": "-- header\n" + proc, "20_new.sql": "-- canonical\n" + proc},
          monkeypatch)
    new, _still, _stale = cs.violations()
    assert [v[0][:3] for v in new] == [("PROCEDURE", "ops", "sp_x")]


# ---- baseline behaviour ------------------------------------------------------------------------

def test_baselined_violation_does_not_fail_but_is_reported(tmp_path, monkeypatch):
    _tree(tmp_path, {"10_old.sql": "-- header\n" + DDL, "20_new.sql": "-- canonical\n" + DDL},
          monkeypatch)
    monkeypatch.setattr(cs, "BASELINE", frozenset({("VIEW", "state", "thing", "10_old.sql")}))
    new, still, stale = cs.violations()
    assert new == [] and stale == []
    assert [v[0][3] for v in still] == ["10_old.sql"]
    assert cs.main() == 0


def test_baseline_that_is_now_compliant_fails_as_stale(tmp_path, monkeypatch):
    # Guards the allowlist against outliving its subjects: once the marker is added, the entry must be
    # deleted, else the baseline silently re-grants an exemption nobody is using.
    _tree(tmp_path, {"10_old.sql": "-- SUPERSEDED by bigquery/20_new.sql\n" + DDL,
                     "20_new.sql": "-- canonical\n" + DDL}, monkeypatch)
    monkeypatch.setattr(cs, "BASELINE", frozenset({("VIEW", "state", "thing", "10_old.sql")}))
    new, _still, stale = cs.violations()
    assert new == []
    assert stale == [("VIEW", "state", "thing", "10_old.sql")]
    assert cs.main() == 1, "a stale baseline entry must fail the check"


def test_main_returns_1_on_a_new_violation(tmp_path, monkeypatch):
    _tree(tmp_path, {"10_old.sql": "-- header\n" + DDL, "20_new.sql": "-- canonical\n" + DDL},
          monkeypatch)
    assert cs.main() == 1

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
from conftest import load_module_from_path

cs = load_module_from_path("check_superseded_markers", "scripts", "check_superseded_markers.py")

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
                 "-- SUPERSEDED — see 78_book_drawdown.sql"):
        assert cs.marks_superseded(text, 78) is True, text


def test_bare_number_is_not_a_file_pointer():
    # 2026-07-18 audit: a bare \b78\b used to satisfy the pointer half, so the word "superseded"
    # plus ANY coincidental standalone 78 (a line reference, a threshold, a date fragment) passed
    # the gate while pointing the operator at nothing. The pointer must look like a file reference.
    assert cs.marks_superseded("-- superseded live by 78", 78) is False
    assert cs.marks_superseded(
        "-- This superseded an older formula; alert retries back off for 78 seconds.", 78) is False
    assert cs.marks_superseded(
        "-- SUPERSEDED — the -15% tier moved (see line 78 of the runbook)", 78) is False
    # ...and the two real file-reference spellings still pass right next to noise numbers.
    assert cs.marks_superseded("-- superseded (was 78 lines) — see bigquery/78_book.sql", 78) is True


def test_zero_padded_file_numbers_match():
    # bigquery/03_twr_engine.sql is canonical for some objects; a "3" or "03" pointer must both work.
    assert cs.marks_superseded("-- superseded by bigquery/03_twr_engine.sql", 3) is True
    assert cs.marks_superseded("-- superseded by bigquery/3", 3) is True


def test_pointer_accepts_uppercase_first_letter_after_numeric_prefix():
    # NUMBERED_FILE (^(\d+)_.*\.sql$) doesn't forbid an uppercase first letter after the numeric
    # prefix (e.g. a future 99_ParkRebalance.sql). The "bigquery/NN\b" alternative can't carry this
    # case either: '_' is a \w char, so there's no \b between the digits and the underscore in
    # "bigquery/99_ParkRebalance.sql" -- it's the second alternative's character class that must
    # accept the uppercase letter.
    assert cs.marks_superseded("-- SUPERSEDED by bigquery/99_ParkRebalance.sql", 99) is True


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


def test_commented_out_create_is_not_treated_as_a_real_definition(tmp_path, monkeypatch):
    # BUG FIX (2026-07-29, confirmed live): OBJECT_DDL used to match a CREATE inside a `--` comment
    # as though it were a real definition -- exactly bigquery/02_ai_layer.sql:23's "Reproduce:" doc
    # recipe (`--   CREATE OR REPLACE TABLE ...`). Here the ONLY genuine definition of state.thing
    # is in 20_new.sql; 10_old.sql merely MENTIONS the object inside a "Reproduce:"-style comment
    # block (each line prefixed "--   ", matching the real repo instance). Pre-fix, definitions()
    # recorded this as a SECOND occurrence in 10_old.sql, so `occurrences` had two distinct
    # filenames and 20_new.sql was wrongly required to carry a "SUPERSEDES 10" marker it has no
    # reason to carry. Post-fix, there is exactly one real definition -> nothing to flag.
    commented = "-- Reproduce:\n" + "\n".join("--   " + line for line in DDL.splitlines()) + "\n"
    _tree(tmp_path, {
        "10_old.sql": commented,
        "20_new.sql": "-- canonical, sole real definition\n" + DDL,
    }, monkeypatch)
    found = cs.definitions()
    assert ("VIEW", "state", "thing") in found
    occurrences = found[("VIEW", "state", "thing")]
    assert [fn for _n, fn, _idx in occurrences] == ["20_new.sql"], (
        f"the commented-out CREATE in 10_old.sql must not be recorded as a definition: {occurrences}")
    new, still, stale = cs.violations()
    assert new == [] and still == [] and stale == []


WRAPPED_DDL = "CREATE OR REPLACE VIEW\n  `stock-trading-498512.state.thing` AS SELECT 1 AS a;\n"


def test_wrapped_create_in_the_newer_file_is_still_detected(tmp_path, monkeypatch):
    # A CREATE keyword and its backtick-quoted name split across two physical lines (legal, common
    # BigQuery style) must still be recorded as an occurrence of the object -- otherwise the newer
    # file's definition silently vanishes, `occurrences` collapses to a single filename, and the OLD
    # unmarked definition below is never even compared against it (the exact dead-end-chain trap
    # this check exists to catch).
    _tree(tmp_path, {
        "10_old.sql": "-- just an ordinary header\n" + DDL,
        "20_new.sql": "-- ===== state.thing — REDEFINED =====\n" + WRAPPED_DDL,
    }, monkeypatch)
    new, _still, _stale = cs.violations()
    assert len(new) == 1
    (kind, ds, name, fn), canonical_file, _line = new[0]
    assert (kind, ds, name, fn) == ("VIEW", "state", "thing", "10_old.sql")
    assert canonical_file == "20_new.sql"


def test_wrapped_create_in_the_older_file_is_still_detected(tmp_path, monkeypatch):
    # Same collapse, opposite direction: the OLDER file wraps its CREATE. It must still be recognized
    # so the unmarked older definition is compared against the (single-line) newer one and flagged,
    # rather than silently passing because `occurrences` only ever saw one filename.
    _tree(tmp_path, {
        "10_old.sql": "-- just an ordinary header\n" + WRAPPED_DDL,
        "20_new.sql": "-- ===== state.thing — REDEFINED =====\n" + DDL,
    }, monkeypatch)
    new, _still, _stale = cs.violations()
    assert len(new) == 1
    (kind, ds, name, fn), canonical_file, _line = new[0]
    assert (kind, ds, name, fn) == ("VIEW", "state", "thing", "10_old.sql")
    assert canonical_file == "20_new.sql"


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


def test_baselined_entry_with_a_stale_pointer_is_not_exempt(tmp_path, monkeypatch):
    # BASELINE grandfathers only the silent no-marker case. An entry whose comment ACTIVELY points
    # at a non-canonical occurrence (10 names 20, but 30 has since superseded 20) is the exact
    # dead-end-chain trap the checker exists for and must be flagged as NEW despite the baseline —
    # found live 2026-07-18 in 5 baselined entries (35/51's roster and 35/52's shadow-readiness
    # chains, 40's backward-only "supersedes 03") whose pointers all dead-ended mid-chain.
    _tree(tmp_path, {
        "10_old.sql": "-- SUPERSEDED LIVE by bigquery/20_mid.sql\n" + DDL,
        "20_mid.sql": "-- SUPERSEDED LIVE by bigquery/30_new.sql\n" + DDL,
        "30_new.sql": "-- canonical\n" + DDL,
    }, monkeypatch)
    monkeypatch.setattr(cs, "BASELINE", frozenset({("VIEW", "state", "thing", "10_old.sql")}))
    new, still, _stale = cs.violations()
    assert [v[0][3] for v in new] == ["10_old.sql"], "stale pointer must override the baseline"
    assert still == []
    assert cs.main() == 1


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

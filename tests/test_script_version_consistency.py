"""Guard scripts/check_script_version_consistency.py's own regex parsers (2026-07-14 audit finding).

A checker whose regex vacuously stops matching is worse than no checker — these fixtures pin the
real-world whitespace variants (alert_emailer.gs aligns with extra spaces; weekly_report.gs does
not) and prove a genuine mismatch is caught, not silently skipped.
"""
from conftest import load_module_from_path

svc = load_module_from_path("check_script_version_consistency", "scripts", "check_script_version_consistency.py")


def test_gs_version_regex_handles_alert_emailer_whitespace_alignment():
    assert svc.GS_VERSION.search("const ALERT_SCRIPT_VERSION = 'v1';   // bump on every change").group(1) == "v1"


def test_gs_version_regex_handles_weekly_report_no_alignment():
    assert svc.GS_VERSION.search("const SCRIPT_VERSION = 'v2';       // bump on every change").group(1) == "v2"


def test_seed_row_regex_matches_known_good_shape():
    txt = "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'some note' AS git_note),"
    got = dict(svc.SEED_ROW.findall(txt))
    assert got == {"alert_emailer": "v1"}


def test_real_repo_is_consistent():
    assert svc.main() == 0


def _rig(tmp_path, monkeypatch, alert_gs_text, weekly_gs_text, registry_text):
    # main() only ever consults SCRIPTS (via .items()) and REGISTRY_SQL — never ALERT_GS/WEEKLY_GS
    # directly (those are read once at import time solely to build SCRIPTS) — so patching SCRIPTS
    # to point at the tmp .gs files is the only redirect main() actually needs.
    alert_gs = tmp_path / "alert_emailer.gs"
    alert_gs.write_text(alert_gs_text)
    weekly_gs = tmp_path / "weekly_report.gs"
    weekly_gs.write_text(weekly_gs_text)
    registry = tmp_path / "43.sql"
    registry.write_text(registry_text)
    monkeypatch.setattr(svc, "REGISTRY_SQL", str(registry))
    monkeypatch.setattr(svc, "SCRIPTS", {"alert_emailer": str(alert_gs), "weekly_report": str(weekly_gs)})


def test_mismatch_between_gs_and_seed_is_caught(tmp_path, monkeypatch, capsys):
    _rig(
        tmp_path, monkeypatch,
        "const ALERT_SCRIPT_VERSION = 'v99';\n",
        "const SCRIPT_VERSION = 'v2';\n",
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n",
    )
    assert svc.main() == 1
    out = capsys.readouterr().out
    assert "v99" in out and "v1" in out


def test_gs_const_that_the_regex_cannot_find_is_caught(tmp_path, monkeypatch, capsys):
    # The one branch that fires when GS_VERSION stops matching (a renamed const, or double quotes the
    # single-quote regex doesn't accept) — parse_gs_version returns None — was never exercised. A
    # vacuously-non-matching regex is the exact failure mode this checker exists to prevent, so its
    # own "could not find" path must be proven to FAIL, not silently pass (2026-07-17 audit).
    _rig(
        tmp_path, monkeypatch,
        'const ALERT_SCRIPT_VERSION = "v1";\n',   # double quotes -> GS_VERSION (single-quote) misses
        "const SCRIPT_VERSION = 'v2';\n",
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n",
    )
    assert svc.main() == 1
    assert "could not find a SCRIPT_VERSION" in capsys.readouterr().out


def test_missing_seed_row_is_caught(tmp_path, monkeypatch):
    _rig(
        tmp_path, monkeypatch,
        "const ALERT_SCRIPT_VERSION = 'v1';\n",
        "const SCRIPT_VERSION = 'v2';\n",
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n",
    )
    assert svc.main() == 1


# ---- parse_seed_versions(): the two guards check_sq_version_registry.py's parse_registry() has
#      enforced for the structurally identical bigquery/63 seed since 2026-08-06, which this — its
#      self-described twin for the .gs/bigquery-43 pair — lacked until 2026-09-04 ----
def test_commented_out_prior_seed_row_does_not_false_fail(tmp_path, monkeypatch, capsys):
    # A DR-note aside narrating the PRIOR seed row, in this repo's own idiom. On raw text it parsed as a
    # live row and (being textually last) won the dict build, so this BLOCKING gate reported a version
    # mismatch that does not exist and blocked every merge with no change to the live MERGE at all.
    _rig(
        tmp_path, monkeypatch,
        "const ALERT_SCRIPT_VERSION = 'v1';\n",
        "const SCRIPT_VERSION = 'v2';\n",
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n"
        "-- PRIOR (v1, kept for the DR record):\n"
        "--   STRUCT('weekly_report' AS script_name, 'v1' AS expected_version, 'prior note' AS git_note)\n"
        "ON T.script_name = S.script_name\n",
    )
    assert svc.main() == 0, capsys.readouterr().out


def test_duplicate_seed_row_is_caught(tmp_path, monkeypatch, capsys):
    # Two LIVE rows for one script_name: the pre-fix dict build kept the last silently (exit 0) while
    # bigquery/43's `ON T.script_name = S.script_name` MERGE would be rejected at apply time. Both
    # rows agree on the version here, deliberately — so the ONLY thing that can fail is the duplicate
    # guard itself, not the ordinary mismatch comparison.
    _rig(
        tmp_path, monkeypatch,
        "const ALERT_SCRIPT_VERSION = 'v1';\n",
        "const SCRIPT_VERSION = 'v2';\n",
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'dup' AS git_note)\n",
    )
    assert svc.main() == 1
    out = capsys.readouterr().out
    assert "duplicate MERGE seed row" in out and "weekly_report" in out
    assert "lines 2, 3" in out                    # both offending line numbers, not just the last


def test_stripping_is_string_literal_aware_on_the_real_registry():
    # THE TRAP this fix had to clear: bigquery/43's git_note fields are multi-thousand-character prose
    # containing many `--` sequences INSIDE single-quoted string literals, so a naive comment stripper
    # would blank the rest of the file from the first one and drop every later seed row. Pin that the
    # stripped parse still equals the raw parse on the REAL file, and that both rows survive.
    raw = svc.read_text(svc.REGISTRY_SQL)
    assert "--" in raw
    rows, errors = svc.parse_seed_versions()
    assert errors == []
    assert dict(svc.SEED_ROW.findall(raw)) == rows
    assert set(rows) == set(svc.SCRIPTS)

"""Guard scripts/check_script_version_consistency.py's own regex parsers (2026-07-14 audit finding).

A checker whose regex vacuously stops matching is worse than no checker — these fixtures pin the
real-world whitespace variants (alert_emailer.gs aligns with extra spaces; weekly_report.gs does
not) and prove a genuine mismatch is caught, not silently skipped.
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_script_version_consistency.py")
    spec = importlib.util.spec_from_file_location("check_script_version_consistency", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


svc = _load()


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


def test_mismatch_between_gs_and_seed_is_caught(tmp_path, monkeypatch, capsys):
    alert_gs = tmp_path / "alert_emailer.gs"
    alert_gs.write_text("const ALERT_SCRIPT_VERSION = 'v99';\n")
    weekly_gs = tmp_path / "weekly_report.gs"
    weekly_gs.write_text("const SCRIPT_VERSION = 'v2';\n")
    registry = tmp_path / "43.sql"
    registry.write_text(
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n"
    )
    monkeypatch.setattr(svc, "ALERT_GS", str(alert_gs))
    monkeypatch.setattr(svc, "WEEKLY_GS", str(weekly_gs))
    monkeypatch.setattr(svc, "REGISTRY_SQL", str(registry))
    monkeypatch.setattr(svc, "SCRIPTS", {"alert_emailer": str(alert_gs), "weekly_report": str(weekly_gs)})
    assert svc.main() == 1
    out = capsys.readouterr().out
    assert "v99" in out and "v1" in out


def test_gs_const_that_the_regex_cannot_find_is_caught(tmp_path, monkeypatch, capsys):
    # The one branch that fires when GS_VERSION stops matching (a renamed const, or double quotes the
    # single-quote regex doesn't accept) — parse_gs_version returns None — was never exercised. A
    # vacuously-non-matching regex is the exact failure mode this checker exists to prevent, so its
    # own "could not find" path must be proven to FAIL, not silently pass (2026-07-17 audit).
    alert_gs = tmp_path / "alert_emailer.gs"
    alert_gs.write_text('const ALERT_SCRIPT_VERSION = "v1";\n')   # double quotes -> GS_VERSION (single-quote) misses
    weekly_gs = tmp_path / "weekly_report.gs"
    weekly_gs.write_text("const SCRIPT_VERSION = 'v2';\n")
    registry = tmp_path / "43.sql"
    registry.write_text(
        "STRUCT('alert_emailer' AS script_name, 'v1' AS expected_version, 'note' AS git_note),\n"
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n"
    )
    monkeypatch.setattr(svc, "ALERT_GS", str(alert_gs))
    monkeypatch.setattr(svc, "WEEKLY_GS", str(weekly_gs))
    monkeypatch.setattr(svc, "REGISTRY_SQL", str(registry))
    monkeypatch.setattr(svc, "SCRIPTS", {"alert_emailer": str(alert_gs), "weekly_report": str(weekly_gs)})
    assert svc.main() == 1
    assert "could not find a SCRIPT_VERSION" in capsys.readouterr().out


def test_missing_seed_row_is_caught(tmp_path, monkeypatch):
    alert_gs = tmp_path / "alert_emailer.gs"
    alert_gs.write_text("const ALERT_SCRIPT_VERSION = 'v1';\n")
    weekly_gs = tmp_path / "weekly_report.gs"
    weekly_gs.write_text("const SCRIPT_VERSION = 'v2';\n")
    registry = tmp_path / "43.sql"
    registry.write_text(
        "STRUCT('weekly_report' AS script_name, 'v2' AS expected_version, 'note' AS git_note)\n"
    )
    monkeypatch.setattr(svc, "ALERT_GS", str(alert_gs))
    monkeypatch.setattr(svc, "WEEKLY_GS", str(weekly_gs))
    monkeypatch.setattr(svc, "REGISTRY_SQL", str(registry))
    monkeypatch.setattr(svc, "SCRIPTS", {"alert_emailer": str(alert_gs), "weekly_report": str(weekly_gs)})
    assert svc.main() == 1

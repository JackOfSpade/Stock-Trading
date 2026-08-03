"""Guard scripts/check_cadence_marker.py's period arithmetic and its change-scoped period check
(2026-08-03, added with the checker after the M1b marker mis-stamp).

Two things need pinning. (1) The period arithmetic — a checker that computes the wrong "current
month" would either wave through the exact bug it exists to catch or fail every clean push. (2) The
change-scoping: the period check must fire on a marker the push CHANGED and stay silent on an idle
file, because the first design (anchor on the file's last commit) failed both ways — an unrelated
bulk edit re-dated three idle Weekly_*.md files, and a shallow clone has no authoring commit to read.
"""
import datetime

from conftest import load_module_from_path

svc = load_module_from_path("check_cadence_marker", "scripts", "check_cadence_marker.py")


def _dt(y, m, d, hour=12):
    return datetime.datetime(y, m, d, hour, tzinfo=svc.OPERATING_TZ)


# --- period arithmetic -------------------------------------------------------------------------

def test_monthly_current_is_the_month_the_write_happened_in():
    # The M1b bug in one assertion: a run on 2026-07-01 stamps 2026-07, never the scored 2026-06.
    assert svc.expected_marker("monthly", "current", _dt(2026, 7, 1)) == "2026-07"


def test_monthly_prior_rolls_the_year_at_january():
    assert svc.expected_marker("monthly", "prior", _dt(2026, 1, 15)) == "2025-12"


def test_quarterly_current_and_prior():
    assert svc.expected_marker("quarterly", "current", _dt(2026, 8, 3)) == "2026-Q3"
    assert svc.expected_marker("quarterly", "prior", _dt(2026, 8, 3)) == "2026-Q2"


def test_quarterly_prior_rolls_the_year_at_q1():
    assert svc.expected_marker("quarterly", "prior", _dt(2026, 2, 10)) == "2025-Q4"


def test_quarter_boundaries_are_inclusive_of_the_first_month():
    assert svc.expected_marker("quarterly", "current", _dt(2026, 4, 1)) == "2026-Q2"
    assert svc.expected_marker("quarterly", "current", _dt(2026, 3, 31)) == "2026-Q1"


def test_weekly_uses_iso_week_so_a_sunday_run_stamps_the_week_that_started_monday():
    # W1/W2/W3 run Sunday; ISO weeks are Mon-Sun, so Sunday 2026-07-26 is still the week of 07-20.
    assert _dt(2026, 7, 26).date().isoweekday() == 7
    assert svc.expected_marker("weekly", "current", _dt(2026, 7, 26)) == "2026-W30"
    assert svc.expected_marker("weekly", "current", _dt(2026, 7, 28)) == "2026-W31"


def test_daily_and_annual():
    assert svc.expected_marker("daily", "current", _dt(2026, 8, 2)) == "2026-08-02"
    assert svc.expected_marker("annual", "current", _dt(2026, 8, 2)) == "2026"


def test_operating_plane_is_denver_not_utc():
    # A 04:19 UTC commit is still the PREVIOUS day in Denver — the whole reason Daily.md markers
    # must be evaluated on the operating plane (bigquery/20_user_prefs.sql).
    utc_evening = datetime.datetime(2026, 8, 3, 4, 19, tzinfo=datetime.timezone.utc)
    local = utc_evening.astimezone(svc.OPERATING_TZ)
    assert svc.expected_marker("daily", "current", local) == "2026-08-02"


# --- marker shapes -----------------------------------------------------------------------------

def test_shapes_accept_the_live_repo_formats():
    assert svc.MARKER_SHAPE["daily"].match("2026-08-02")
    assert svc.MARKER_SHAPE["weekly"].match("2026-W30")
    assert svc.MARKER_SHAPE["monthly"].match("2026-08")
    assert svc.MARKER_SHAPE["quarterly"].match("2026-Q3")
    assert svc.MARKER_SHAPE["annual"].match("2026")


def test_shapes_reject_a_title_on_line_one():
    # The historical Quarterly_Regime.md regression: '#' title on line 1, marker pushed to line 3.
    assert not svc.MARKER_SHAPE["quarterly"].match("# Quarterly Regime")
    assert not svc.MARKER_SHAPE["monthly"].match("# Monthly Fundamental")


def test_monthly_shape_rejects_a_daily_marker_and_vice_versa():
    assert not svc.MARKER_SHAPE["monthly"].match("2026-08-02")
    assert not svc.MARKER_SHAPE["daily"].match("2026-08")
    assert not svc.MARKER_SHAPE["quarterly"].match("2026-Q5")


# --- end-to-end main(), with git stubbed --------------------------------------------------------

def _rig(tmp_path, monkeypatch, *, marker, base_marker, cadence="monthly", offset="current",
         write_iso="2026-08-03T11:35:00+00:00", base="abc123"):
    """Point main() at one temp cadence file and stub every git touchpoint.

    base_marker=None models a file that did not exist at the base revision (a first write).
    """
    name = "Monthly_Fundamental.md"
    (tmp_path / name).write_text(marker + "\n\nbody\n")
    monkeypatch.setattr(svc, "ROOT", str(tmp_path))
    monkeypatch.setattr(svc, "CADENCE_FILES", {name: (cadence, offset)})
    monkeypatch.setattr(svc, "resolve_base", lambda: base)
    monkeypatch.setattr(svc, "first_line_at", lambda rev, path: base_marker)
    monkeypatch.setattr(
        svc, "write_dt",
        lambda b, p: datetime.datetime.fromisoformat(write_iso).astimezone(svc.OPERATING_TZ))
    return name


def test_the_real_m1b_mis_stamp_is_caught(tmp_path, monkeypatch, capsys):
    # Verbatim replay of 2026-07-01: run in July, stamped with the scored month June.
    _rig(tmp_path, monkeypatch, marker="2026-06", base_marker="2026-05",
         write_iso="2026-07-01T14:49:55+00:00")
    assert svc.main() == 1
    out = capsys.readouterr().out
    assert "CADENCE MARKER: FAIL" in out
    assert "'2026-06'" in out and "'2026-07'" in out


def test_correct_marker_passes(tmp_path, monkeypatch, capsys):
    _rig(tmp_path, monkeypatch, marker="2026-08", base_marker="2026-06")
    assert svc.main() == 0
    assert "period verified" in capsys.readouterr().out


def test_idle_file_is_not_period_checked(tmp_path, monkeypatch, capsys):
    # Marker identical at base => this push did not write it => its authoring date is unknowable
    # here, so no period claim is made. This is the case that made the last-commit anchor unusable.
    _rig(tmp_path, monkeypatch, marker="2026-06", base_marker="2026-06",
         write_iso="2026-08-03T11:35:00+00:00")
    assert svc.main() == 0
    assert "no marker changed in this push" in capsys.readouterr().out


def test_first_write_of_a_new_file_is_period_checked(tmp_path, monkeypatch, capsys):
    _rig(tmp_path, monkeypatch, marker="2026-07", base_marker=None)
    assert svc.main() == 1
    assert "'2026-08'" in capsys.readouterr().out


def test_retrospective_file_stamps_the_prior_period(tmp_path, monkeypatch, capsys):
    # Q1/Q3 are retrospective: a Q3 run stamps 2026-Q2, and stamping 2026-Q3 is the error.
    _rig(tmp_path, monkeypatch, marker="2026-Q2", base_marker="2026-Q1",
         cadence="quarterly", offset="prior")
    assert svc.main() == 0
    _rig(tmp_path, monkeypatch, marker="2026-Q3", base_marker="2026-Q1",
         cadence="quarterly", offset="prior")
    assert svc.main() == 1
    assert "PRIOR" in capsys.readouterr().out


def test_bad_shape_fails_before_any_period_check(tmp_path, monkeypatch, capsys):
    _rig(tmp_path, monkeypatch, marker="# Monthly Fundamental", base_marker="2026-06")
    assert svc.main() == 1
    assert "not a bare monthly marker" in capsys.readouterr().out


def test_missing_file_is_reported_not_skipped(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(svc, "ROOT", str(tmp_path))
    monkeypatch.setattr(svc, "CADENCE_FILES", {"Gone.md": ("monthly", "current")})
    assert svc.main() == 1
    assert "not present in the repo" in capsys.readouterr().out


def test_unresolvable_base_says_so_loudly_instead_of_claiming_a_period_check(tmp_path, monkeypatch,
                                                                            capsys):
    _rig(tmp_path, monkeypatch, marker="2026-08", base_marker="2026-06", base=None)
    assert svc.main() == 0
    out = capsys.readouterr().out
    assert "Period check SKIPPED" in out and "fetch-depth: 0" in out


def test_real_repo_is_consistent():
    assert svc.main() == 0

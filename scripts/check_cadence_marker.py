#!/usr/bin/env python3
"""Cadence-output first-line period markers are well-formed, and a marker CHANGED in this push
stamps the period the push happened in (2026-08-03, after the M1b marker mis-stamp).

WHY THIS EXISTS. Every cadence-output file's first line is a bare period marker, and
`Claude_Task_Plan.md` §"File-write conventions for routine outputs" fixes per routine whether that
marker is the CURRENT period (M1b/M2/M3/Q2, forward-looking) or the PRIOR one (Q1/Q3, retrospective).
Until now nothing in code checked it. The only enforcement was prose at `Claude_Task_Plan.md`'s
"Upstream-output FRESHNESS check", executed by the *consuming* routine (W4/M4/Q4/A3) against its
upstreams — so a producing routine that mis-stamped its OWN file was invisible until a consumer next
ran. That is exactly what happened: the 2026-07-01 M1b run stamped `Monthly_Fundamental.md` with the
month it had SCORED (`2026-06`) instead of the month it was RUNNING IN (`2026-07`), and nothing caught
it until M4's freshness gate halted on 2026-08-01 — a month later, mid-incident, where it was misread
as the file being "two cycles stale" when in fact the July cycle had run fine.

TWO CHECKS, DELIBERATELY DIFFERENT IN SCOPE.

1. SHAPE — every file, always, no git needed. The first line must be a bare marker of the right
   cadence shape, literally first: no '#' title, no blockquote above it (a 2026-06/07 Q1 run put the
   title on line 1 and the marker on line 3).

2. PERIOD — only files whose FIRST LINE changed in this push. This restriction is the whole design,
   not a shortcut. A cadence file legitimately sits idle between runs: today `Weekly_*.md` reads
   `2026-W30` while the current week is later, and that is correct, not drift. So "is this marker
   right?" is only answerable as "was it right WHEN IT WAS WRITTEN" — and the only write whose date
   we can know reliably is one contained in the range under test. Anchoring instead on the file's
   last commit is WRONG twice over: an unrelated bulk spec edit that touches a cadence file without
   changing line 1 would re-date it (measured: the "A1 redesign" commit touched all three
   `Weekly_*.md`), and in a shallow clone — which is what `actions/checkout` produces by default and
   what this working copy is — the authoring commit of an idle file is simply not in history, so
   `git log` reports the graft boundary and every idle file fails. Comparing line 1 against the base
   revision needs only the base blob, which the range under test always has.

Dates are converted to America/Denver, the pinned OPERATING plane (`bigquery/20_user_prefs.sql`; a
UTC-evening commit has already rolled to the next calendar day, which would misjudge every Daily.md).

Usage:  python scripts/check_cadence_marker.py    # exit 0 if consistent, 1 + diff if not
"""
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.report import fail_or_ok

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The pinned OPERATING timezone. Deliberately hardcoded, not looked up — see CLAUDE.md
# "Making the OPERATING timezone plane dynamic" (settled: never dynamic).
OPERATING_TZ = ZoneInfo("America/Denver")

# filename -> (cadence class, offset)
#   offset "current" = the period containing the write; "prior" = the period before it (retrospective).
# Source of truth: Claude_Task_Plan.md §"File-write conventions for routine outputs".
CADENCE_FILES = {
    "Daily.md": ("daily", "current"),
    "Weekly_Catalyst_Calendar.md": ("weekly", "current"),
    "Weekly_Post_Event_Screen.md": ("weekly", "current"),
    "Weekly_Position_Deep_Dive.md": ("weekly", "current"),
    "Monthly_Fundamental.md": ("monthly", "current"),
    "Monthly_E_Pairs.md": ("monthly", "current"),
    "Monthly_D_Position_Deep_Dive.md": ("monthly", "current"),
    "Quarterly_Regime.md": ("quarterly", "prior"),
    "Quarterly_D_Candidates.md": ("quarterly", "current"),
    "Quarterly_AI_Foundation_Delta.md": ("quarterly", "prior"),
    "Annual_AI_Foundation_Sweep.md": ("annual", "current"),
    "Annual_Constraint_Audit.md": ("annual", "current"),
}

# Shape of each cadence class's marker. Weekly is `YYYY-Www` in every live file and every consumer;
# the plan's prose renders it `YYYY-WW`, which is the same convention written loosely.
MARKER_SHAPE = {
    "daily": re.compile(r"^\d{4}-\d{2}-\d{2}$"),
    "weekly": re.compile(r"^\d{4}-W\d{2}$"),
    "monthly": re.compile(r"^\d{4}-\d{2}$"),
    "quarterly": re.compile(r"^\d{4}-Q[1-4]$"),
    "annual": re.compile(r"^\d{4}$"),
}


def _git(*args):
    """Run a git command; return stripped stdout, or None if git failed."""
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True,
                              check=True).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def resolve_base():
    """The revision this push is measured against.

    merge-base(HEAD, origin/main) is the real diff base for a routine branch; HEAD~1 is the fallback
    for a local run or a detached checkout. Returns None when neither resolves (a shallow clone whose
    graft point IS HEAD, or a root commit) — the caller reports that rather than silently passing.
    """
    for rev in ("origin/main", "main"):
        base = _git("merge-base", "HEAD", rev)
        if base:
            return base
    return _git("rev-parse", "HEAD~1")


def first_line_at(rev, rel_path):
    """First line of rel_path at revision `rev`, or None if the file did not exist there."""
    blob = _git("show", f"{rev}:{rel_path}")
    if blob is None:
        return None
    return blob.split("\n", 1)[0].rstrip()


def write_dt(base, rel_path):
    """When the marker under test was written: the newest commit in base..HEAD touching rel_path.

    Falls back to HEAD's own date (a working-tree edit not yet committed, which is the local
    pre-commit case) so the check is usable before the commit exists.
    """
    stamp = _git("log", "-1", "--format=%aI", f"{base}..HEAD", "--", rel_path) or _git(
        "log", "-1", "--format=%aI", "HEAD")
    if not stamp:
        return None
    return datetime.fromisoformat(stamp).astimezone(OPERATING_TZ)


def expected_marker(cadence, offset, dt):
    """The marker a file of this cadence class, written at `dt`, must carry.

    DEFENSIVE FIX (2026-08-31 code-quality pass, cadence#4): daily and weekly used to silently
    IGNORE `offset` and always return the marker for the period CONTAINING `dt`, unlike monthly/
    quarterly/annual, which explicitly branch on `offset == "prior"`. Every LIVE CADENCE_FILES entry
    for daily/weekly is offset="current" today (verified: zero daily+"prior" and zero weekly+"prior"
    entries above), and Claude_Task_Plan.md's own File-write-conventions section documents weekly as
    a single global "always current, never look-ahead" rule rather than a per-routine choice the way
    monthly/quarterly is -- so this was dormant, not a live bug (a 2026-08-31 adversarial re-check
    of the original finding confirmed exactly that and REFUTED the live-impact claim). It is made
    total anyway, purely defensively: monthly/quarterly already show a retrospective variant is a
    foreseeable addition for a NEW routine, and a future ("weekly", "prior") or ("daily", "prior")
    CADENCE_FILES entry must compute the right marker instead of silently falling through to the
    CURRENT period's -- reproducing, for daily/weekly, the exact undetected-for-a-month 2026-07-01
    M1b mis-stamp this whole checker exists to catch. Zero behavior change for any offset="current"
    call (every call today): tests/test_check_cadence_marker.py pins both the unchanged current-
    period behavior and the new prior-period arithmetic."""
    d = dt.date()
    if cadence == "daily":
        if offset == "prior":
            d = d - timedelta(days=1)
        return d.isoformat()
    if cadence == "weekly":
        if offset == "prior":
            d = d - timedelta(weeks=1)
        iso_year, iso_week, _ = d.isocalendar()
        return f"{iso_year}-W{iso_week:02d}"
    if cadence == "monthly":
        year, month = d.year, d.month
        if offset == "prior":
            year, month = (year - 1, 12) if month == 1 else (year, month - 1)
        return f"{year}-{month:02d}"
    if cadence == "quarterly":
        year, quarter = d.year, (d.month - 1) // 3 + 1
        if offset == "prior":
            year, quarter = (year - 1, 4) if quarter == 1 else (year, quarter - 1)
        return f"{year}-Q{quarter}"
    if cadence == "annual":
        return str(d.year - 1 if offset == "prior" else d.year)
    raise ValueError(f"unknown cadence class {cadence!r}")


def main():
    errors = []
    base = resolve_base()
    shaped = 0
    period_checked = []

    for name, (cadence, offset) in sorted(CADENCE_FILES.items()):
        path = os.path.join(ROOT, name)
        if not os.path.exists(path):
            errors.append(f"{name}: listed in the conventions table but not present in the repo "
                          f"(delete it from CADENCE_FILES if the routine was retired)")
            continue

        with open(path, encoding="utf-8") as fh:
            marker = fh.readline().rstrip("\n")

        # CHECK 1 — shape, always.
        if not MARKER_SHAPE[cadence].match(marker):
            errors.append(f"{name}: first line is {marker!r}, which is not a bare {cadence} marker. "
                          f"The marker must be literally the FIRST line — before any '#' title or "
                          f"blockquote (a 2026-06/07 Q1 run put the title on line 1; corrected).")
            continue
        shaped += 1

        # CHECK 2 — period, only if this push changed the marker.
        if base is None:
            continue
        if first_line_at(base, name) == marker:
            continue  # marker untouched in this range; its authoring date is not knowable here

        dt = write_dt(base, name)
        if dt is None:
            continue
        want = expected_marker(cadence, offset, dt)
        period_checked.append(name)
        if marker != want:
            errors.append(
                f"{name}: this push sets the first-line marker to {marker!r}, but the write is dated "
                f"{dt.isoformat()} (America/Denver), whose {offset} {cadence} period is {want!r}. "
                f"Per Claude_Task_Plan.md §'File-write conventions' this file stamps the "
                f"{offset.upper()} period. A forward-looking routine stamping the period it SCORED "
                f"instead of the one it RAN IN is the 2026-07-01 M1b mis-stamp this check exists to "
                f"catch — it went undetected for a month until M4's freshness gate halted on it."
            )

    # REFACTOR (2026-08-31 code-quality pass, cross-cutting#0): shared FAIL/OK block, see
    # lib/report.py's module docstring. `ok_line` is picked from the same three branches as before;
    # computing it unconditionally (rather than only in the former no-errors branch) is a no-op on a
    # FAIL run, since `base`/`shaped`/`period_checked` are all already set by the loop above
    # regardless of whether `errors` ended up non-empty, and fail_or_ok() never looks at `ok_line`
    # when `errors` is non-empty.
    if base is None:
        ok_line = (f"CADENCE MARKER: OK — {shaped} marker(s) well-formed. Period check SKIPPED: no "
                   f"diff base (shallow clone grafted at HEAD, or a root commit). If this appears in "
                   f"CI, give the job `fetch-depth: 0` so the period check actually runs.")
    elif period_checked:
        ok_line = (f"CADENCE MARKER: OK — {shaped} marker(s) well-formed; period verified for the "
                   f"{len(period_checked)} changed in this push ({', '.join(sorted(period_checked))}).")
    else:
        ok_line = (f"CADENCE MARKER: OK — {shaped} marker(s) well-formed; no marker changed in this "
                   f"push, so no period check was owed.")
    return fail_or_ok("CADENCE MARKER", errors, ok_line)


if __name__ == "__main__":
    raise SystemExit(main())

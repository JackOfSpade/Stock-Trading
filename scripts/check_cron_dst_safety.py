#!/usr/bin/env python3
"""Assert every fixed-UTC routine cron still satisfies its cadence contract in BOTH DST seasons.

WHY THIS EXISTS
---------------
The whole routine fleet runs on fixed-UTC crons (`expected_trigger.recurrence: custom_cron`).
Nothing in it is DST-aware -- verified 2026-08-01 against the live API, where every trigger reports
`created_via: "http_api"` and the trigger schema has no timezone field at all. That is a deliberate
choice (see CLAUDE.md "Making the OPERATING timezone plane dynamic"): fixed-UTC keeps the schedule
version-controlled, API-manageable, losslessly restorable from ops/routine_backup.json, and
auto-correctable by Q4 step E / OPS0 STEP 3, which only self-heal the custom_cron cohort.

The price is that a fixed-UTC cron slides one hour EARLIER in America/Denver local terms when MST
starts, and a constraint expressed in LOCAL time can therefore hold in summer and break in winter.
That has already bitten this repo twice:

  * OPS2 shipped as `0 3 * * *` = 21:00 MDT but 20:00 MST, which fell BEFORE the 21:00 MT
    needs_attention deadline it was written to run after. Owner retimed it to `15 4 * * *`
    on 2026-07-27.
  * W1 shipped as `0 6 * * 0` = Sunday 00:00 MDT but SATURDAY 23:00 MST. Since
    bigquery/114_period_aware_dependency_gate.sql buckets `weekly_sun` by the Sunday of
    `in_run_date`'s week, a Saturday run_date lands outside its own week's window, so W4
    (`depends_on: [W1, W2, W3]`) would have hard-blocked every Sunday from 2026-11-08, and W1
    would have tripped period_watch as missed every week. Found 2026-08-01, before it fired.

Both are the same bug class and both were found by hand. This checker makes the class mechanical.

WHAT IT CHECKS, per routine with a concrete `cron_utc`
-----------------------------------------------------
  1. DAY/PERIOD INTEGRITY -- the local calendar day the cron lands on must still satisfy the
     routine's monitor_class in every season the cron actually fires in:
       daily_sun_thu  -> local weekday is Sunday..Thursday (the DAILY-TIER FRI/SAT CONSOLIDATION)
       weekly_sun     -> local weekday is Sunday
       monthly_ftd    -> local day-of-month equals the cron's day-of-month
       quarterly_ftd  -> local day-of-month equals the cron's day-of-month
       annual_ftd     -> local day-of-month AND month equal the cron's
     This is the W1 defect.
  2. LOCAL-WINDOW INTEGRITY -- an EVENING-slot daily routine (EVENING_WINDOW_ROUTINE_IDS below) must
     land strictly after the market close and strictly before `cadence_watch_deadline_local`, in every
     season. This is the OPS2 defect. Routine-ID-based, NOT monitor_class-based, since 2026-08-08: the
     daily-tier Fri/Sat consolidation merged the former `daily_trading` cohort (D1/D2a/D2/SL3, which
     needed this window) and the former `daily_all` cohort (D3/OPS0/OPS1/OPS2, which do NOT all share
     one intraday window -- OPS1 is a pre-market probe, OPS0/OPS2 deliberately fire AFTER the
     deadline) into one shared `daily_sun_thu` class, so monitor_class alone can no longer tell the two
     groups apart. Re-keying to a bare id literal (EVENING_WINDOW_ROUTINE_IDS) fixed the immediate
     false-green but reopened the same failure class one level up -- nothing tied that literal back to
     ops/cadence.yaml, so a FUTURE routine added to daily_sun_thu could again escape unnoticed, just
     without a monitor_class rename to blame. daily_sun_thu_coverage_errors() closes that: every
     daily_sun_thu id in ops/cadence.yaml must be named in EITHER EVENING_WINDOW_ROUTINE_IDS OR its
     explicit complement NON_WINDOW_DAILY_SUN_THU_IDS (the former `daily_all` cohort, with a reason
     recorded per id) -- an id in neither is UNCLASSIFIED and fails CI loudly instead of silently
     passing unchecked.
  3. DOCUMENTATION TRUTH -- `time_local`, when present, must equal the MDT (summer) rendering of
     `cron_utc`. Before 2026-08-01 OPS2's `time_local` was silently the MST reading while every
     other routine's was the MDT reading, so a reader deriving a UTC cron from `time_local` got
     OPS2 an hour early. A single documented convention, enforced, removes that trap.

Seasons are derived from the cron itself rather than assumed: an annual routine that only ever
fires in January is checked against MST alone, because it has no summer firing to check.

Exit 0 = all good. Exit 1 = at least one violation. Run from the repo root.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

# ops/cadence.yaml's `routines:` key can legitimately be present but valueless (YAML parses a bare
# `routines:` to None, not []); dict.get's default only fires when the KEY is missing, not when its
# value is None. lib.routine_manifest.cadence_routines() is the shared, hardened accessor for this --
# gen_routine_lists.py already had this guard, and a 2026-07-29 pass propagated it to
# check_cadence_consistency.py's load_cadence()/cadence_duplicate_ids() and print_routines.py's
# load_cadence(), but this script's own load_cadence() hand-rolled a SEPARATE, still-unguarded
# extraction (`cad["routines"] if ... else cad`) that pass never reached -- a fifth copy of the same
# fragile idiom (2026-08-08 audit finding). Import only; scripts/lib/** is owned by another agent.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.routine_manifest import cadence_routines
from lib.textio import load_yaml

CADENCE = Path("ops/cadence.yaml")
BACKUP = Path("ops/routine_backup.json")
DENVER = ZoneInfo("America/Denver")
UTC = ZoneInfo("UTC")

# A non-leap reference year, only used to enumerate firing instants. DST rules have been stable
# since 2007 (2nd Sunday March -> 1st Sunday November); this is deliberately a constant rather than
# "the current year" so the checker is deterministic and its tests cannot drift under the calendar.
REF_YEAR = 2027

# Market close in the OPERATING plane. US equity close is 16:00 America/New_York year-round, and
# Denver is always New_York minus 2h (both observe DST on identical dates), so this is 14:00 MT in
# BOTH seasons -- it is not itself a DST hazard. What moves is the fixed-UTC routine, toward it.
MARKET_CLOSE_LOCAL = (14, 0)

# monitor_class -> how the local calendar day must line up with the cron's own day fields.
PERIOD_CLASSES = {
    "weekly_sun": "weekday_sunday",
    "daily_sun_thu": "weekday_sun_thu",
    "monthly_ftd": "same_dom",
    "quarterly_ftd": "same_dom",
    "annual_ftd": "same_dom_and_month",
}

# Check 2 (LOCAL-WINDOW INTEGRITY): the EVENING-slot daily routines that must land strictly after the
# market close and strictly before cadence_watch_deadline_local. Routine-ID-based, not monitor_class-
# based (2026-08-08 daily-tier Fri/Sat consolidation, ops/cadence.yaml) -- these four WERE exactly the
# monitor_class: daily_trading cohort before that migration folded them, together with D3/OPS0/OPS1/
# OPS2, into one shared daily_sun_thu class. Kept as an explicit id set rather than re-deriving it from
# monitor_class (which can no longer make this distinction) so this check's SCOPE stays exactly what it
# was, byte-for-byte, rather than silently widening to the whole daily_sun_thu cohort (which would
# wrongly flag OPS1's deliberate pre-market slot and OPS0/OPS2's deliberate after-deadline slots) or
# silently narrowing to nothing (the regression this fix corrects: mclass == "daily_trading" stopped
# matching any routine the moment this migration landed, which would have silently disarmed this whole
# check for D1/D2a/D2/SL3 with no test failure to catch it).
EVENING_WINDOW_ROUTINE_IDS = {"D1", "D2a", "D2", "SL3"}

# The REMAINING daily_sun_thu members, explicitly exempted from check 2 -- the former daily_all
# cohort -- with the reason recorded per id. Deliberately NOT derived from time_local: D3's own
# time_local ("18:45") ALSO renders inside the (market_close, deadline) window today, so a pure
# time-based derivation would silently pull D3 into the window-checked set even though its real
# constraint is "runs after D2", not "runs in the evening window" -- checked against the current
# ops/cadence.yaml before choosing this shape (2026-08-08). There is no OTHER field left in
# ops/cadence.yaml that reconstructs the pre-2026-08-08 daily_trading/daily_all split (both
# collapsed onto the single daily_sun_thu monitor_class that day), so, like
# EVENING_WINDOW_ROUTINE_IDS itself, this stays a declared judgment call rather than a derived one --
# see daily_sun_thu_coverage_errors() below for the mechanism that keeps BOTH sets honest against
# ops/cadence.yaml going forward, so this pair can no longer drift silently the way the bare
# `mclass == "daily_trading"` literal did.
NON_WINDOW_DAILY_SUN_THU_IDS = {
    "D3",     # runs after D2; not itself close/deadline-bound
    "OPS0",   # cadence dispatcher -- deliberately fires AFTER the deadline
    "OPS1",   # pre-market connector probe -- fires hours BEFORE the close
    "OPS2",   # catch-up executor -- deliberately fires AFTER the deadline
}


def daily_sun_thu_coverage_errors(routines) -> list[str]:
    """FAIL LOUD if ops/cadence.yaml's actual `monitor_class: daily_sun_thu` membership diverges
    from the union of EVENING_WINDOW_ROUTINE_IDS and NON_WINDOW_DAILY_SUN_THU_IDS above.

    THIS IS THE SELF-MAINTENANCE GUARD the two hand-kept id sets need. Before this function existed,
    "absent from EVENING_WINDOW_ROUTINE_IDS" was already the correct, permanent state for D3/OPS0/
    OPS1/OPS2 -- so a THIRD case, a brand-new daily_sun_thu routine nobody has classified either way
    yet, was indistinguishable from an intentionally-exempt one by inspecting EVENING_WINDOW_ROUTINE_
    IDS alone. That is exactly the shape of the regression this checker was re-keyed to fix in the
    first place: `mclass == "daily_trading"` silently stopped matching anything the day the daily-tier
    Fri/Sat consolidation merged the classes, with no test failure to catch it. Re-keying check 2 to a
    bare id literal removed the false green, but introduced a NEW way to go silently stale: nothing
    compared that literal back to ops/cadence.yaml. This closes that loop by requiring every
    daily_sun_thu id to be named in EXACTLY ONE of the two sets:
      * daily_sun_thu in ops/cadence.yaml but in NEITHER set -> UNCLASSIFIED. A routine was added (or
        re-classified) to the evening-slot cohort and nobody decided whether it needs the window
        check. This is the case a future `git diff` adding a new post-close daily routine must trip.
      * named in either set but no longer daily_sun_thu in ops/cadence.yaml (renamed / retired /
        reclassified) -> STALE. A classification decision nothing keeps current.
      * named in BOTH sets -> a self-contradiction in this file itself.
    """
    actual = {r.get("id") for r in routines if r.get("monitor_class") == "daily_sun_thu"}
    errs: list[str] = []

    overlap = EVENING_WINDOW_ROUTINE_IDS & NON_WINDOW_DAILY_SUN_THU_IDS
    if overlap:
        errs.append(
            f"scripts/check_cron_dst_safety.py: {sorted(overlap)} appear in BOTH "
            f"EVENING_WINDOW_ROUTINE_IDS and NON_WINDOW_DAILY_SUN_THU_IDS -- pick one."
        )

    unclassified = actual - (EVENING_WINDOW_ROUTINE_IDS | NON_WINDOW_DAILY_SUN_THU_IDS)
    if unclassified:
        errs.append(
            f"{sorted(unclassified)}: monitor_class=daily_sun_thu in ops/cadence.yaml but named in "
            f"neither EVENING_WINDOW_ROUTINE_IDS nor NON_WINDOW_DAILY_SUN_THU_IDS in "
            f"scripts/check_cron_dst_safety.py. Add it to EVENING_WINDOW_ROUTINE_IDS (if it must run "
            f"after the close and before the cadence_watch deadline) or to "
            f"NON_WINDOW_DAILY_SUN_THU_IDS with a reason (if it deliberately does not) before this "
            f"checker can validate it."
        )

    stale = (EVENING_WINDOW_ROUTINE_IDS | NON_WINDOW_DAILY_SUN_THU_IDS) - actual
    if stale:
        errs.append(
            f"{sorted(stale)}: named in EVENING_WINDOW_ROUTINE_IDS or NON_WINDOW_DAILY_SUN_THU_IDS "
            f"in scripts/check_cron_dst_safety.py but no longer monitor_class=daily_sun_thu in "
            f"ops/cadence.yaml (renamed, retired, or reclassified) -- remove the stale entry."
        )
    return errs


class CronParseError(ValueError):
    """Raised on any cron syntax this checker does not positively understand."""


def parse_field(field: str, lo: int, hi: int, what: str) -> set[int]:
    """Parse one cron field into the set of values it matches.

    Deliberately supports ONLY `*`, a bare integer, and a comma list of integers -- the three forms
    actually used in ops/cadence.yaml. Anything else (step values, ranges, names) raises rather than
    being silently treated as a wildcard: a checker that quietly accepts what it cannot evaluate
    reports success on exactly the schedules that most need evaluating.
    """
    if field == "*":
        return set(range(lo, hi + 1))
    out: set[int] = set()
    for part in field.split(","):
        part = part.strip()
        if not part.isdigit():
            raise CronParseError(f"unsupported {what} field {field!r} (only '*', N, and N,N,N)")
        val = int(part)
        if not lo <= val <= hi:
            raise CronParseError(f"{what} value {val} out of range {lo}..{hi} in {field!r}")
        out.add(val)
    return out


def cron_firings(cron: str):
    """Every UTC firing instant of a 5-field cron across REF_YEAR.

    Day-of-month and day-of-week are intersected (AND), not unioned. Standard cron ORs them when
    both are restricted, but no routine in this repo restricts both, and AND is the fail-closed
    reading: it can only ever yield a subset, never invent a firing the schedule does not have.
    """
    fields = cron.split()
    if len(fields) != 5:
        raise CronParseError(f"expected 5 cron fields, got {len(fields)} in {cron!r}")
    minute_f, hour_f, dom_f, mon_f, dow_f = fields
    minutes = parse_field(minute_f, 0, 59, "minute")
    hours = parse_field(hour_f, 0, 23, "hour")
    doms = parse_field(dom_f, 1, 31, "day-of-month")
    months = parse_field(mon_f, 1, 12, "month")
    dows = parse_field(dow_f, 0, 6, "day-of-week")

    day = datetime(REF_YEAR, 1, 1, tzinfo=UTC)
    end = datetime(REF_YEAR + 1, 1, 1, tzinfo=UTC)
    while day < end:
        # cron day-of-week: 0 = Sunday. Python weekday(): 0 = Monday. isoweekday() % 7 maps
        # Sunday(7)->0, Monday(1)->1, ... which is exactly the cron convention.
        if day.month in months and day.day in doms and (day.isoweekday() % 7) in dows:
            for h in sorted(hours):
                for m in sorted(minutes):
                    yield day.replace(hour=h, minute=m)
        day += timedelta(days=1)


def load_cadence():
    doc = load_yaml(CADENCE)
    routines = cadence_routines(doc)
    deadline = doc.get("cadence_watch_deadline_local", "21:00")
    hh, mm = (int(x) for x in str(deadline).split(":"))
    return routines, (hh, mm)


def backup_snapshot_errors(routines) -> list[str]:
    """The restore path must not be able to reinstate a schedule this checker never validated.

    ops/routine_backup.json is what `routine_backup.py restore` replays after an accidental
    deletion (the 2026-08-01 incident). Its `cron_expression` is a SEPARATE copy of the schedule
    from cadence.yaml's `cron_utc`, and `routine_backup.py check` compares instructions, profiles
    and trigger_ids but NOT crons -- verified 2026-08-01, when the snapshot still held W1's
    Saturday-landing `0 6 * * 0` and `check` passed clean. Without this, a recovery would silently
    undo a DST fix, which is the worst possible moment to reintroduce one.
    """
    if not BACKUP.exists():
        return []
    try:
        snap = json.loads(BACKUP.read_text()).get("routines", {})
    except (OSError, ValueError) as exc:
        return [f"ops/routine_backup.json unreadable: {exc}"]
    errs = []
    for r in routines:
        rid = r.get("id")
        et = r.get("expected_trigger") or {}
        want = et.get("cron_utc")
        if et.get("recurrence") != "custom_cron" or not want or want == "TO_POPULATE":
            continue
        got = (snap.get(rid) or {}).get("cron_expression")
        if got is not None and got != want:
            errs.append(
                f"{rid}: ops/routine_backup.json cron_expression {got!r} disagrees with the "
                f"DST-validated cron_utc {want!r} in ops/cadence.yaml — a restore would reinstate "
                f"an unchecked schedule. Re-ingest the snapshot after changing a live cron."
            )
    return errs


def check() -> int:
    routines, deadline_local = load_cadence()
    errors: list[str] = []
    rows: list[tuple[str, str, str, str, str]] = []

    errors.extend(daily_sun_thu_coverage_errors(routines))

    for r in routines:
        rid = r.get("id")
        et = r.get("expected_trigger") or {}
        if et.get("recurrence") != "custom_cron":
            continue
        cron = et.get("cron_utc")
        if not cron or cron == "TO_POPULATE":
            continue  # bootstrap placeholder; check_cadence_consistency.py owns that case

        try:
            firings = list(cron_firings(cron))
        except CronParseError as exc:
            errors.append(f"{rid}: {exc}")
            continue
        if not firings:
            errors.append(f"{rid}: cron_utc {cron!r} never fires in {REF_YEAR}")
            continue

        cron_dom = cron.split()[2]
        cron_mon = cron.split()[3]
        # Reuse parse_field rather than string-comparing the raw field: a zero-padded but perfectly
        # valid field ("01") is accepted by parse_field and by cron_firings, so an ad-hoc
        # `str(local.day) in cron_dom.split(",")` would report a bogus period-shift violation on a
        # schedule that is actually correct. cron_firings above has already proven both fields parse.
        dom_vals = parse_field(cron_dom, 1, 31, "day-of-month")
        mon_vals = parse_field(cron_mon, 1, 12, "month")
        mclass = r.get("monitor_class")
        per_season: dict[bool, list[datetime]] = {}
        for inst in firings:
            local = inst.astimezone(DENVER)
            per_season.setdefault(bool(local.dst()), []).append(local)

        def render(is_dst: bool, per_season: dict[bool, list[datetime]] = per_season) -> str:
            # Every DISTINCT local HH:MM the season fires at, not just the first -- a comma-list hour
            # field (parse_field supports these for ANY cron field, e.g. quarterly's "1,4,7,10" months)
            # produces more than one daily firing, and showing only got[0] hid the second firing from
            # the printed table even on a clean run, not just from the check-2 window logic below
            # (2026-08-08 audit finding, same root cause as that loop's own probe=locals_[0] bug).
            # per_season is bound as a default arg (not a free closure over the outer loop variable)
            # so this function can never accidentally read a LATER iteration's dict (B023).
            got = per_season.get(is_dst)
            if not got:
                return "-"
            return ",".join(sorted({t.strftime("%H:%M") for t in got}))

        rows.append((rid, cron, render(True), render(False), mclass or "-"))

        for is_dst, locals_ in sorted(per_season.items(), reverse=True):
            season = "MDT" if is_dst else "MST"

            # ---- 1. day / period integrity -------------------------------------------------
            rule = PERIOD_CLASSES.get(mclass)
            for local in locals_:
                if rule == "weekday_sunday" and local.isoweekday() != 7:
                    errors.append(
                        f"{rid}: cron_utc {cron!r} lands on {local:%A} {local:%Y-%m-%d %H:%M} "
                        f"local in {season}, but monitor_class={mclass} requires Sunday. "
                        f"bigquery/114 buckets this class by the Sunday of the run week, so a "
                        f"non-Sunday run_date falls outside its own period window."
                    )
                    break
                if rule == "weekday_sun_thu" and local.isoweekday() not in (7, 1, 2, 3, 4):
                    errors.append(
                        f"{rid}: cron_utc {cron!r} lands on {local:%A} {local:%Y-%m-%d %H:%M} "
                        f"local in {season}, but monitor_class={mclass} requires Sunday-Thursday "
                        f"(ops/cadence.yaml's DAILY-TIER FRI/SAT CONSOLIDATION). bigquery/12 derives "
                        f"state.cadence_expected_today for this class in America/Denver, so a Fri/Sat "
                        f"local run_date is outside the routine's own window."
                    )
                    break
                if rule in ("same_dom", "same_dom_and_month") and cron_dom != "*":
                    if local.day not in dom_vals:
                        errors.append(
                            f"{rid}: cron_utc {cron!r} lands on local day-of-month {local.day} "
                            f"({local:%Y-%m-%d %H:%M}) in {season}, but the cron says "
                            f"day-of-month {cron_dom} — the period key would shift."
                        )
                        break
                if rule == "same_dom_and_month" and cron_mon != "*":
                    if local.month not in mon_vals:
                        errors.append(
                            f"{rid}: cron_utc {cron!r} lands in local month {local.month} "
                            f"({local:%Y-%m-%d %H:%M}) in {season}, but the cron says "
                            f"month {cron_mon}."
                        )
                        break

            # ---- 2. local-window integrity (the OPS2 defect) --------------------------------
            # Checks EVERY firing in the season, not just locals_[0] -- check 1 above already loops
            # `for local in locals_:` for the same reason. parse_field supports comma lists on ANY
            # field (already exercised for quarterly months), so e.g. "0 3,22 * * *" fires twice a
            # day; probing only the first firing left a second firing landing at/after the deadline
            # invisible and this script exiting 0 -- exactly the shape of the 2026-07-27 OPS2 defect
            # this checker exists to catch, just on the second firing instead of the first
            # (2026-08-08 audit finding).
            if rid in EVENING_WINDOW_ROUTINE_IDS:
                for probe in locals_:
                    hm = (probe.hour, probe.minute)
                    if hm <= MARKET_CLOSE_LOCAL:
                        errors.append(
                            f"{rid}: cron_utc {cron!r} renders {probe:%H:%M} MT in {season}, at or "
                            f"before the {MARKET_CLOSE_LOCAL[0]:02d}:{MARKET_CLOSE_LOCAL[1]:02d} MT "
                            f"market close, but {rid} is an evening-slot routine that runs after the close."
                        )
                    if hm >= deadline_local:
                        errors.append(
                            f"{rid}: cron_utc {cron!r} renders {probe:%H:%M} MT in {season}, at or "
                            f"after the {deadline_local[0]:02d}:{deadline_local[1]:02d} MT "
                            f"cadence_watch deadline (this is the 2026-07-27 OPS2 defect)."
                        )

        # ---- 3. documentation truth ------------------------------------------------------
        tl = et.get("time_local")
        if tl:
            summer = per_season.get(True)
            winter = per_season.get(False)
            ref, ref_season = (summer, "MDT") if summer else (winter, "MST")
            want = ref[0].strftime("%H:%M")
            if tl != want:
                errors.append(
                    f"{rid}: time_local {tl!r} does not match cron_utc {cron!r}, which renders "
                    f"{want} {ref_season}. time_local documents the {ref_season} rendering for "
                    f"every routine — a second convention is the 2026-07 OPS2 trap, where a "
                    f"reader deriving UTC from time_local got the routine an hour early."
                )

    errors.extend(backup_snapshot_errors(routines))

    print(f"{'routine':<8} {'cron_utc':<18} {'MDT':<6} {'MST':<6} monitor_class")
    for rid, cron, mdt, mst, mclass in rows:
        print(f"{rid:<8} {cron:<18} {mdt:<6} {mst:<6} {mclass}")
    print(f"\n{len(rows)} custom_cron routines checked against both DST seasons "
          f"(reference year {REF_YEAR}).")

    if errors:
        print(f"\nFAIL — {len(errors)} DST-safety violation(s):\n", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print("OK — every cron satisfies its cadence contract in both seasons.")
    return 0


if __name__ == "__main__":
    sys.exit(check())

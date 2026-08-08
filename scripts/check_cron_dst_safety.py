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
       weekly_sun     -> local weekday is Sunday
       monthly_ftd    -> local day-of-month equals the cron's day-of-month
       quarterly_ftd  -> local day-of-month equals the cron's day-of-month
       annual_ftd     -> local day-of-month AND month equal the cron's
     This is the W1 defect.
  2. LOCAL-WINDOW INTEGRITY -- a `daily_trading` routine must land strictly after the market close
     and strictly before `cadence_watch_deadline_local`, in every season. This is the OPS2 defect.
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
    "monthly_ftd": "same_dom",
    "quarterly_ftd": "same_dom",
    "annual_ftd": "same_dom_and_month",
}


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
                if rule in ("same_dom", "same_dom_and_month") and cron_dom != "*":
                    if str(local.day) not in cron_dom.split(","):
                        errors.append(
                            f"{rid}: cron_utc {cron!r} lands on local day-of-month {local.day} "
                            f"({local:%Y-%m-%d %H:%M}) in {season}, but the cron says "
                            f"day-of-month {cron_dom} — the period key would shift."
                        )
                        break
                if rule == "same_dom_and_month" and cron_mon != "*":
                    if str(local.month) not in cron_mon.split(","):
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
            if mclass == "daily_trading":
                for probe in locals_:
                    hm = (probe.hour, probe.minute)
                    if hm <= MARKET_CLOSE_LOCAL:
                        errors.append(
                            f"{rid}: cron_utc {cron!r} renders {probe:%H:%M} MT in {season}, at or "
                            f"before the {MARKET_CLOSE_LOCAL[0]:02d}:{MARKET_CLOSE_LOCAL[1]:02d} MT "
                            f"market close, but monitor_class=daily_trading runs after the close."
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

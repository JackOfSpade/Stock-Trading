"""Guard scripts/check_cron_dst_safety.py -- the both-DST-seasons cron contract checker.

Every test writes its own cadence.yaml into tmp_path and monkeypatches cs.CADENCE at the module
level; nothing here reads or writes the real ops/cadence.yaml (the fixture-clobber trap this repo
has hit twice -- see tests/test_routine_backup.py's header). write_cadence() ALSO points cs.BACKUP
at a nonexistent tmp_path file by default (backup_snapshot_errors() no-ops when BACKUP.exists() is
False), for the same reason: check() unconditionally calls backup_snapshot_errors(), which reads
cs.BACKUP, and several tests below reuse real fleet routine ids (D1, SL3, OPS2, W1) with synthetic
cron/time_local values that do NOT always match those ids' live ops/routine_backup.json entries. Before
this default, those tests silently depended on the real snapshot file's CURRENT content agreeing with
their synthetic fixture by coincidence -- true only as long as nobody edited ops/routine_backup.json
for that id. The 2026-08-08 daily-tier Fri/Sat cron migration changed D1/SL3/OPS2's real
cron_expression (added a day-of-week list) and broke exactly that coincidence, failing
test_daily_trading_inside_window_passes / test_deadline_is_read_from_cadence_not_hardcoded /
test_ops2_mdt_time_local_passes with an unrelated "disagrees with the DST-validated cron_utc" error --
a real bug in the test's isolation, not in the migration. The dedicated backup_snapshot_errors tests
near the bottom of this file re-monkeypatch cs.BACKUP to their own tmp_path snapshot AFTER calling
write_cadence(), which overrides this default (last monkeypatch.setattr wins), so their coverage of
the real backup-divergence behavior is unchanged. write_cadence() ALSO resets cs.EVENING_WINDOW_
ROUTINE_IDS and cs.NON_WINDOW_DAILY_SUN_THU_IDS to empty sets by default, for the analogous reason:
daily_sun_thu_coverage_errors() compares the loaded cadence.yaml's actual daily_sun_thu membership
against those two sets FLEET-WIDE, so an unpatched real (or stale synthetic) set would flag every
member absent from a test's minimal fixture as "stale". Tests below that care about window-check
membership re-patch one or both of these two AFTER calling write_cadence(), same convention as BACKUP.

The two REGRESSION tests below are the point of the file. Both encode a defect that actually
shipped and was found by hand:

  * test_w1_saturday_in_mst_is_caught -- W1's `0 6 * * 0` is Sunday 00:00 MDT but SATURDAY 23:00
    MST. Would have hard-blocked W4 every Sunday from 2026-11-08.
  * test_ops2_mst_time_local_convention_is_caught -- OPS2's time_local was the MST rendering while
    every other routine's was MDT, so deriving a UTC cron from it landed an hour early.

If either stops failing, the checker has gone blind to the exact class it was written for.
"""
import pytest

from conftest import load_module_from_path

cs = load_module_from_path("check_cron_dst_safety", "scripts", "check_cron_dst_safety.py")


def write_cadence(tmp_path, monkeypatch, routines, deadline="21:00"):
    """Build a minimal cadence.yaml containing only `routines` and point the checker at it."""
    lines = [f'cadence_watch_deadline_local: "{deadline}"', "routines:"]
    for r in routines:
        lines.append(f"  - id: {r['id']}")
        lines.append(f"    monitor_class: {r['monitor_class']}")
        lines.append("    expected_trigger:")
        lines.append("      recurrence: custom_cron")
        lines.append(f"      cron_utc: \"{r['cron']}\"")
        if r.get("time_local"):
            lines.append(f"      time_local: \"{r['time_local']}\"")
        lines.append("      enabled: true")
    path = tmp_path / "cadence.yaml"
    path.write_text("\n".join(lines) + "\n")
    monkeypatch.setattr(cs, "CADENCE", path)
    # Isolate from the real ops/routine_backup.json too -- see the module docstring above.
    # Individual tests that want to exercise backup_snapshot_errors() re-patch cs.BACKUP afterward.
    monkeypatch.setattr(cs, "BACKUP", tmp_path / "_no_backup_snapshot_in_this_test.json")
    # Isolate from the REAL, growing EVENING_WINDOW_ROUTINE_IDS / NON_WINDOW_DAILY_SUN_THU_IDS too
    # (added alongside daily_sun_thu_coverage_errors(), same reasoning as the BACKUP isolation
    # above): daily_sun_thu_coverage_errors() is a FLEET-WIDE invariant -- it flags every id named
    # in either real set that this cadence.yaml doesn't also carry as monitor_class: daily_sun_thu
    # as STALE. A minimal single-routine fixture is never the whole real fleet, so comparing against
    # the real, unpatched sets would flag all 8 real daily_sun_thu ids as stale on every such fixture,
    # regardless of what that test actually means to exercise. Individual tests that DO want to
    # exercise the coverage machinery (or a real window-membership id like "D1"/"SL3") re-patch these
    # two AFTER calling write_cadence(), same last-monkeypatch-wins convention as cs.BACKUP.
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", set())
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", set())
    return path


# ---- field parsing: the fail-closed property ------------------------------------------------

def test_parse_field_supported_forms():
    assert cs.parse_field("*", 0, 6, "dow") == {0, 1, 2, 3, 4, 5, 6}
    assert cs.parse_field("3", 0, 23, "hour") == {3}
    assert cs.parse_field("1,4,7,10", 1, 12, "month") == {1, 4, 7, 10}


@pytest.mark.parametrize("bad", ["*/5", "1-5", "MON", "", "1,", "1-3,5"])
def test_parse_field_rejects_what_it_cannot_evaluate(bad):
    # A checker that silently treats unsupported syntax as a wildcard would report success on
    # precisely the schedules that most need evaluating. Fail closed instead.
    with pytest.raises(cs.CronParseError):
        cs.parse_field(bad, 0, 59, "minute")


def test_parse_field_rejects_out_of_range():
    with pytest.raises(cs.CronParseError):
        cs.parse_field("25", 0, 23, "hour")


@pytest.mark.parametrize("bad", ["0 6 * *", "0 6 * * 0 extra", ""])
def test_cron_firings_rejects_wrong_field_count(bad):
    with pytest.raises(cs.CronParseError):
        list(cs.cron_firings(bad))


def test_cron_firings_counts():
    # 2027 has 52 Sundays; a weekly cron fires once on each.
    assert len(list(cs.cron_firings("0 6 * * 0"))) == 52
    # monthly-on-the-1st -> 12; quarterly-on-the-2nd of 4 months -> 4; annual -> 1.
    assert len(list(cs.cron_firings("0 11 1 * *"))) == 12
    assert len(list(cs.cron_firings("0 17 2 1,4,7,10 *"))) == 4
    assert len(list(cs.cron_firings("0 17 1 1 *"))) == 1


# ---- REGRESSION: the two defects that actually shipped ---------------------------------------

def test_w1_saturday_in_mst_is_caught(tmp_path, monkeypatch, capsys):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "W1", "monitor_class": "weekly_sun", "cron": "0 6 * * 0", "time_local": "00:00"},
    ])
    assert cs.check() == 1
    err = capsys.readouterr().err
    assert "W1" in err and "Saturday" in err and "requires Sunday" in err


def test_w1_retimed_cron_passes(tmp_path, monkeypatch):
    # The actual fix that shipped: 30 7 * * 0 is 01:30 MDT / 00:30 MST, Sunday in both.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "W1", "monitor_class": "weekly_sun", "cron": "30 7 * * 0", "time_local": "01:30"},
    ])
    assert cs.check() == 0


def test_ops2_mst_time_local_convention_is_caught(tmp_path, monkeypatch, capsys):
    # `15 4 * * *` is 22:15 MDT / 21:15 MST. Recording the MST reading is the trap.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "OPS2", "monitor_class": "daily_all", "cron": "15 4 * * *", "time_local": "21:15"},
    ])
    assert cs.check() == 1
    assert "22:15 MDT" in capsys.readouterr().err


def test_ops2_mdt_time_local_passes(tmp_path, monkeypatch):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "OPS2", "monitor_class": "daily_all", "cron": "15 4 * * *", "time_local": "22:15"},
    ])
    assert cs.check() == 0


# ---- local-window integrity (evening-slot daily routines) --------------------------------------
#
# Check 2 (LOCAL-WINDOW INTEGRITY) became ROUTINE-ID-based, not monitor_class-based, on 2026-08-08
# (the daily-tier Fri/Sat consolidation folded the former daily_trading cohort -- D1/D2a/D2/SL3, which
# needs this window -- and the former daily_all cohort -- D3/OPS0/OPS1/OPS2, which does NOT all share
# one intraday window -- into one shared daily_sun_thu monitor_class). These tests monkeypatch
# cs.EVENING_WINDOW_ROUTINE_IDS to {"DX"} so the synthetic "DX" id this file otherwise uses
# (decoupled from any real routine identity, same convention as "MX"/"GUI" elsewhere in this file)
# still exercises the window logic without hardcoding a real fleet id into the test. The patch runs
# AFTER write_cadence() (not before) so it wins over write_cadence()'s own default reset of
# EVENING_WINDOW_ROUTINE_IDS to an empty set -- see write_cadence()'s docstring.

def test_daily_trading_before_market_close_in_mst_is_caught(tmp_path, monkeypatch, capsys):
    # 19:30 UTC -> 13:30 MDT / 12:30 MST. Summer is fine; winter falls before the 14:00 close.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_trading", "cron": "30 19 * * *"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    assert cs.check() == 1
    assert "market close" in capsys.readouterr().err


def test_daily_trading_past_deadline_is_caught(tmp_path, monkeypatch, capsys):
    # 04:30 UTC -> 22:30 MDT, past the 21:00 MT cadence_watch deadline.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_trading", "cron": "30 4 * * *"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    assert cs.check() == 1
    assert "deadline" in capsys.readouterr().err


def test_daily_trading_inside_window_passes(tmp_path, monkeypatch):
    # D1 is a real EVENING_WINDOW_ROUTINE_IDS member. write_cadence() now resets that set to empty
    # by default (daily_sun_thu_coverage_errors' isolation, see its own docstring), so this test
    # re-patches it explicitly to {"D1"} afterward instead of relying on the unpatched real global.
    # monitor_class is daily_sun_thu (not the legacy "daily_trading" other tests in this section
    # use) so daily_sun_thu_coverage_errors() sees D1 correctly classified rather than stale.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "D1", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"D1"})
    assert cs.check() == 0


def test_second_comma_hour_firing_past_deadline_is_caught(tmp_path, monkeypatch, capsys):
    # REGRESSION (2026-08-08): parse_field supports comma lists for ANY cron field (already exercised
    # for quarterly months, e.g. "1,4,7,10"), so "0 2,4 * * *" fires twice a day -- 02:00 UTC (20:00
    # MDT / 19:00 MST, inside the window) and 04:00 UTC (22:00 MDT / 21:00 MST, at/past the 21:00
    # deadline). sorted(hours) always visits the smaller hour first, so the old check's `probe =
    # locals_[0]` only ever saw the harmless 02:00 UTC firing -- the second firing's deadline
    # violation was invisible and check() exited 0. Exactly the shape of the 2026-07-27 OPS2 defect
    # this checker exists to catch, on a firing the old code never looked at.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_trading", "cron": "0 2,4 * * *"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    assert cs.check() == 1
    assert "deadline" in capsys.readouterr().err


# ---- daily_sun_thu coverage (EVENING_WINDOW_ROUTINE_IDS self-maintenance guard) ----------------
#
# REGRESSION GUARD (2026-08-08 follow-up): re-keying check 2 off a bare EVENING_WINDOW_ROUTINE_IDS
# literal fixed the immediate `mclass == "daily_trading"` false-green, but nothing tied that literal
# back to ops/cadence.yaml, so a routine added to daily_sun_thu later could again escape the window
# check with no CI signal -- the same failure shape one level up. daily_sun_thu_coverage_errors()
# closes that: every daily_sun_thu id must be named in EXACTLY ONE of EVENING_WINDOW_ROUTINE_IDS or
# NON_WINDOW_DAILY_SUN_THU_IDS. These tests monkeypatch BOTH sets to synthetic ids, same convention
# as the "DX" pattern above -- AFTER calling write_cadence() so the synthetic values win over
# write_cadence()'s own default reset to empty sets -- so they exercise the mechanism without
# depending on the real fleet's current membership.

def test_daily_sun_thu_unclassified_routine_is_caught(tmp_path, monkeypatch, capsys):
    # DZ carries monitor_class: daily_sun_thu but is named in neither set -- exactly what adding a
    # new post-close evening (or non-window) daily routine to ops/cadence.yaml without updating
    # either allowlist looks like. Must fail CI, not silently under-cover it.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
        {"id": "DY", "monitor_class": "daily_sun_thu", "cron": "30 4 * * 1,2,3,4,5", "time_local": "22:30"},
        {"id": "DZ", "monitor_class": "daily_sun_thu", "cron": "0 23 * * 0,1,2,3,4", "time_local": "17:00"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DY"})
    assert cs.check() == 1
    err = capsys.readouterr().err
    assert "['DZ']" in err
    assert "neither EVENING_WINDOW_ROUTINE_IDS nor NON_WINDOW_DAILY_SUN_THU_IDS" in err


def test_daily_sun_thu_fully_classified_passes(tmp_path, monkeypatch):
    # Same shape as above, but DZ is dropped -- DX/DY are each named in exactly one set, so this
    # must pass. Proves the guard does not over-fire on a correctly classified cohort.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
        {"id": "DY", "monitor_class": "daily_sun_thu", "cron": "30 4 * * 1,2,3,4,5", "time_local": "22:30"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DY"})
    assert cs.check() == 0


def test_daily_sun_thu_stale_classification_entry_is_caught(tmp_path, monkeypatch, capsys):
    # NON_WINDOW_DAILY_SUN_THU_IDS names "DY", but ops/cadence.yaml no longer has a daily_sun_thu
    # routine by that id (renamed/retired/reclassified) -- a stale entry is also drift, not silence.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DY"})
    assert cs.check() == 1
    err = capsys.readouterr().err
    assert "['DY']" in err
    assert "no longer monitor_class=daily_sun_thu" in err


def test_daily_sun_thu_overlap_between_sets_is_caught(tmp_path, monkeypatch, capsys):
    # A routine id named in BOTH sets is a self-contradiction in this file, independent of what
    # ops/cadence.yaml says.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DX"})
    assert cs.check() == 1
    assert "appear in BOTH" in capsys.readouterr().err


def test_daily_sun_thu_coverage_ignores_other_monitor_classes(tmp_path, monkeypatch):
    # A routine outside daily_sun_thu entirely (e.g. weekly_sun) must never trip this guard, even
    # if it is absent from both id sets -- the guard is scoped to daily_sun_thu only.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22 * * 0,1,2,3,4", "time_local": "16:00"},
        {"id": "WX", "monitor_class": "weekly_sun", "cron": "0 8 * * 0"},
    ])
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"DX"})
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", set())
    assert cs.check() == 0


def test_real_evening_window_ids_are_exactly_classified():
    # The real EVENING_WINDOW_ROUTINE_IDS / NON_WINDOW_DAILY_SUN_THU_IDS pair, checked directly
    # against the module constants (not a fixture) -- disjoint, and their union is exactly today's
    # real daily_sun_thu cohort.
    assert cs.EVENING_WINDOW_ROUTINE_IDS == {"D1", "D2a", "D2", "SL3"}
    assert cs.NON_WINDOW_DAILY_SUN_THU_IDS == {"D3", "OPS0", "OPS1", "OPS2"}
    assert not (cs.EVENING_WINDOW_ROUTINE_IDS & cs.NON_WINDOW_DAILY_SUN_THU_IDS)


def test_deadline_is_read_from_cadence_not_hardcoded(tmp_path, monkeypatch):
    # Same cron, stricter declared deadline -> must start failing. Proves the check is wired to
    # cadence_watch_deadline_local rather than a constant that silently ignores the file.
    # write_cadence() resets EVENING_WINDOW_ROUTINE_IDS on EVERY call, so "SL3" must be re-patched
    # in after each one, not just once up front. monitor_class is daily_sun_thu (SL3's real class)
    # so daily_sun_thu_coverage_errors() sees it correctly classified rather than stale.
    routine = [{"id": "SL3", "monitor_class": "daily_sun_thu", "cron": "0 2 * * 1,2,3,4,5"}]
    write_cadence(tmp_path, monkeypatch, routine, deadline="21:00")
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"SL3"})
    assert cs.check() == 0            # 20:00 MDT / 19:00 MST, both clear
    write_cadence(tmp_path, monkeypatch, routine, deadline="18:00")
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", {"SL3"})
    assert cs.check() == 1


# ---- period classes -------------------------------------------------------------------------

def test_monthly_shifted_off_its_day_is_caught(tmp_path, monkeypatch, capsys):
    # 05:00 UTC on the 1st is 23:00 local on the LAST day of the previous month, in both seasons.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "MX", "monitor_class": "monthly_ftd", "cron": "0 5 1 * *"},
    ])
    assert cs.check() == 1
    assert "day-of-month" in capsys.readouterr().err


def test_annual_is_checked_only_in_the_season_it_fires(tmp_path, monkeypatch):
    # A1 fires once, in January (MST). It has no summer instance, so demanding an MDT rendering
    # would be a false positive -- the checker must derive seasons from the cron itself.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "A1", "monitor_class": "annual_ftd", "cron": "0 17 1 1 *"},
    ])
    assert cs.check() == 0


def test_quarterly_holds_its_day_in_both_seasons(tmp_path, monkeypatch):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "Q1", "monitor_class": "quarterly_ftd", "cron": "0 17 2 1,4,7,10 *"},
    ])
    assert cs.check() == 0


# ---- scope / plumbing -------------------------------------------------------------------------

def test_non_custom_cron_routines_are_skipped(tmp_path, monkeypatch):
    # A `daily` recurrence carries no cron_utc to evaluate; check_cadence_consistency.py owns it.
    path = tmp_path / "cadence.yaml"
    path.write_text(
        'cadence_watch_deadline_local: "21:00"\n'
        "routines:\n"
        "  - id: GUI\n"
        "    monitor_class: weekly_sun\n"
        "    expected_trigger:\n"
        "      recurrence: weekly\n"
        '      time_local: "00:00"\n'
        "      enabled: true\n"
    )
    monkeypatch.setattr(cs, "CADENCE", path)
    # This test bypasses write_cadence() and builds its own path, so it does NOT inherit that
    # helper's default EVENING_WINDOW_ROUTINE_IDS/NON_WINDOW_DAILY_SUN_THU_IDS isolation -- patch
    # both explicitly (GUI's monitor_class is weekly_sun, not daily_sun_thu, so these should be
    # no-ops for daily_sun_thu_coverage_errors(), but the real, unpatched sets would otherwise
    # report all real fleet members as stale against this minimal fixture).
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", set())
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", set())
    assert cs.check() == 0


def test_to_populate_placeholder_is_skipped(tmp_path, monkeypatch):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "NEW", "monitor_class": "weekly_sun", "cron": "TO_POPULATE"},
    ])
    assert cs.check() == 0


def test_bare_routines_key_does_not_crash(tmp_path, monkeypatch):
    # REGRESSION (2026-08-08): load_cadence() hand-rolled its own `cad["routines"] if ... else cad`
    # extraction instead of importing lib.routine_manifest.cadence_routines() -- the shared accessor
    # that already closed this exact trap at check_cadence_consistency.py's load_cadence() /
    # cadence_duplicate_ids() and print_routines.py's load_cadence() (2026-07-29), but that pass never
    # reached this script's separate copy. A bare `routines:` key parses to None (YAML), not [], so
    # the old code returned None for `routines` and check() crashed with `TypeError: 'NoneType' object
    # is not iterable` on `for r in routines:` instead of reporting an empty, clean cadence file.
    path = tmp_path / "cadence.yaml"
    path.write_text('cadence_watch_deadline_local: "21:00"\nroutines:\n')
    monkeypatch.setattr(cs, "CADENCE", path)
    # Bypasses write_cadence() -- see test_non_custom_cron_routines_are_skipped's comment above for
    # why these two need an explicit reset here too.
    monkeypatch.setattr(cs, "EVENING_WINDOW_ROUTINE_IDS", set())
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", set())
    assert cs.check() == 0


def test_backup_snapshot_cron_divergence_is_caught(tmp_path, monkeypatch, capsys):
    # REGRESSION: routine_backup.py's own `check` compares instructions/profiles/trigger_ids but
    # NOT crons, so on 2026-08-01 the snapshot still held W1's Saturday-landing `0 6 * * 0` while
    # cadence.yaml had the fix, and it passed clean. A restore would have undone the DST fix.
    write_cadence(tmp_path, monkeypatch, [
        {"id": "W1", "monitor_class": "weekly_sun", "cron": "30 7 * * 0", "time_local": "01:30"},
    ])
    snap = tmp_path / "routine_backup.json"
    snap.write_text('{"routines": {"W1": {"cron_expression": "0 6 * * 0"}}}')
    monkeypatch.setattr(cs, "BACKUP", snap)
    assert cs.check() == 1
    assert "would reinstate an unchecked schedule" in capsys.readouterr().err


def test_backup_snapshot_agreement_passes(tmp_path, monkeypatch):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "W1", "monitor_class": "weekly_sun", "cron": "30 7 * * 0", "time_local": "01:30"},
    ])
    snap = tmp_path / "routine_backup.json"
    snap.write_text('{"routines": {"W1": {"cron_expression": "30 7 * * 0"}}}')
    monkeypatch.setattr(cs, "BACKUP", snap)
    assert cs.check() == 0


def test_missing_backup_file_is_not_an_error(tmp_path, monkeypatch):
    write_cadence(tmp_path, monkeypatch, [
        {"id": "W1", "monitor_class": "weekly_sun", "cron": "30 7 * * 0", "time_local": "01:30"},
    ])
    monkeypatch.setattr(cs, "BACKUP", tmp_path / "does_not_exist.json")
    assert cs.check() == 0


def test_real_cadence_file_passes():
    # The live ops/cadence.yaml must satisfy its own contract. Read-only: no monkeypatch, so this
    # exercises the real CADENCE path exactly as CI runs it.
    assert cs.check() == 0


# ---- check 3 (documentation truth) accepts ANY firing of a multi-firing cron --------------------
def test_time_local_may_document_the_second_firing_of_a_multi_firing_cron(tmp_path, monkeypatch):
    """REGRESSION (quality pass 2026-08-22). `0 22,23 * * 0,1,2,3,4` fires twice daily and renders as BOTH
    16:00 and 17:00 MDT -- the table this script prints says exactly that. Check 3 compared
    time_local against ref[0] only, so it rejected a correctly-documented "17:00" with the message
    "...which renders 16:00 MDT", contradicting its own output one line below.

    This is the identical `probe = locals_[0]` bug class that check 2 (local-window integrity) was
    explicitly fixed for on 2026-08-08; the fix was never applied to check 3. Latent today -- no
    live routine combines a comma-listed hour field with a time_local -- but parse_field supports
    comma lists on any field, so the first routine that needs a second daily firing hits it."""
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22,23 * * 0,1,2,3,4",
         "time_local": "17:00"},
    ])
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DX"})
    assert cs.check() == 0


def test_time_local_may_also_document_the_first_firing_of_a_multi_firing_cron(tmp_path, monkeypatch):
    """The other firing of the same cron stays valid too -- the fix widens the accepted set, it
    does not move it."""
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22,23 * * 0,1,2,3,4",
         "time_local": "16:00"},
    ])
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DX"})
    assert cs.check() == 0


def test_time_local_matching_no_firing_of_a_multi_firing_cron_is_still_caught(tmp_path, monkeypatch, capsys):
    """...and the gate is not weakened: a time_local matching NEITHER firing still fails, and the
    error now names every valid rendering instead of only the first."""
    write_cadence(tmp_path, monkeypatch, [
        {"id": "DX", "monitor_class": "daily_sun_thu", "cron": "0 22,23 * * 0,1,2,3,4",
         "time_local": "18:00"},
    ])
    monkeypatch.setattr(cs, "NON_WINDOW_DAILY_SUN_THU_IDS", {"DX"})
    assert cs.check() == 1
    assert "16:00, 17:00 MDT" in capsys.readouterr().err

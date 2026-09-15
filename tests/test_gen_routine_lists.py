"""Guard scripts/gen_routine_lists.py — the generator for bigquery/12/15/24/105/114/132/205/241's
marker-delimited routine-list STRUCT regions (ARCH-3 Item 30b). This module had NO dedicated test before now:
scripts/check_cadence_consistency.py only *checks* the regions agree with ops/cadence.yaml, while
this script GENERATES them, so a generator bug (wrong filter, wrong indent, a stale --check that
never flags drift) had zero coverage.

All tests run against tmp_path fixtures (never the real bigquery/*.sql, ops/cadence.yaml, or
Claude_Task_Plan.md), so a --write test can never touch a committed file.
"""
import os
import sys

import pytest

from conftest import load_module_from_path

gr = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")


# ---- gen_12_region: calendar-class rows (monitor_class not in queue_driven/None) ------------------
def test_gen_12_region_emits_one_row_per_calendar_routine_with_correct_indent_and_commas():
    routines = [
        {"id": "D1", "monitor_class": "daily_trading"},
        {"id": "W1", "monitor_class": "weekly_sun"},
    ]
    got = gr.gen_12_region(routines)
    assert got == (
        "    STRUCT('D1' AS routine, 'daily_trading' AS schedule),\n"
        "    STRUCT('W1' AS routine, 'weekly_sun' AS schedule)"
    )
    # 4-space indent (matches the surrounding UNNEST block), comma on every row but the last.
    assert got.splitlines()[0].startswith("    STRUCT(")
    assert not got.rstrip().endswith(",")


def test_gen_12_region_excludes_queue_driven_routines():
    routines = [
        {"id": "D1", "monitor_class": "daily_trading"},
        {"id": "QX", "monitor_class": "queue_driven"},
    ]
    got = gr.gen_12_region(routines)
    assert "QX" not in got
    assert "D1" in got


def test_gen_12_region_excludes_and_does_not_crash_on_none_monitor_class():
    # Documented 2026-07-17 fix: a malformed cadence.yaml routine with a missing/None monitor_class
    # is DROPPED here (the `not in (queue_driven, None)` filter), rather than kept and then raising
    # KeyError on r['monitor_class'] in the f-string. check_cadence_consistency.py flags the missing
    # key loudly, so omitting it here masks nothing.
    routines = [
        {"id": "D1", "monitor_class": "daily_trading"},
        {"id": "BAD"},                       # no monitor_class key at all
        {"id": "ALSOBAD", "monitor_class": None},
    ]
    got = gr.gen_12_region(routines)          # must not raise
    assert "BAD" not in got and "ALSOBAD" not in got
    assert got == "    STRUCT('D1' AS routine, 'daily_trading' AS schedule)"


def test_gen_12_region_empty_when_no_calendar_routines():
    assert gr.gen_12_region([{"id": "QX", "monitor_class": "queue_driven"}]) == ""


# ---- gen_15_region: ALL routines, instruction derived from the plan heading ----------------------
# Every call below passes prior= and today= explicitly (never the defaults) so these tests are
# deterministic and never read the real bigquery/15 file or the real clock (parse_catalog_since()'s
# and datetime.date.today()'s own defaults are exercised separately, in
# test_gen_15_region_defaults_read_the_real_file_and_clock_when_not_passed below).
def test_gen_15_region_emits_all_routines_with_derived_instruction():
    routines = [{"id": "D1", "monitor_class": "daily_trading"},
                {"id": "AR_att", "monitor_class": "queue_driven"}]
    head_by_id = {"D1": "D1. Market Development Scan — deep research",
                  "AR_att": "Adversarial Review Attacker — regular routine"}
    got = gr.gen_15_region(routines, head_by_id, prior={}, today="2026-08-19")
    assert got == (
        "  STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1 — deep research.' AS canonical_instruction, "
        "DATE '2026-08-19' AS canonical_since),\n"
        "  STRUCT('AR_att' AS routine, 'Read Claude_Task_Plan.md. Perform Adversarial Review Attacker — regular routine.' "
        "AS canonical_instruction, DATE '2026-08-19' AS canonical_since)"
    )
    # 2-space indent (matches bigquery/15's block, shallower than 12/24), queue_driven routines INCLUDED.
    assert got.splitlines()[0].startswith("  STRUCT(")


def test_gen_15_region_empty_instruction_when_heading_missing():
    # A routine with no matching plan heading yet gets an empty instruction string — check B/C flag
    # that loudly rather than the generator guessing. Absent from `prior` too, so canonical_since seeds
    # to `today` (covered more directly by test_gen_15_region_seeds_canonical_since_when_absent_from_prior).
    got = gr.gen_15_region([{"id": "GHOST", "monitor_class": "daily_trading"}], {}, prior={}, today="2026-08-19")
    assert got == "  STRUCT('GHOST' AS routine, '' AS canonical_instruction, DATE '2026-08-19' AS canonical_since)"


# ---- gen_15_region: canonical_since preserve-vs-restamp contract (bigquery/183, 2026-08-19) -------
def test_gen_15_region_preserves_canonical_since_when_instruction_unchanged():
    # STABILITY CONTRACT: a routine whose derived instruction matches what `prior` already has keeps
    # its OLD canonical_since date verbatim, even though `today` is a later date — this is what makes
    # a --check run on any later day regenerate a byte-identical region (see gen_15_region's docstring).
    routines = [{"id": "D1", "monitor_class": "daily_trading"}]
    head_by_id = {"D1": "D1. Market Development Scan — deep research"}
    instr = "Read Claude_Task_Plan.md. Perform D1 — deep research."
    got = gr.gen_15_region(routines, head_by_id, prior={"D1": (instr, "2026-08-17")}, today="2026-08-19")
    assert got == (
        "  STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1 — deep research.' "
        "AS canonical_instruction, DATE '2026-08-17' AS canonical_since)"
    )


def test_gen_15_region_restamps_canonical_since_when_instruction_changes():
    # The complementary half: when the derived instruction differs from what `prior` held for that
    # routine (a real heading/type-tag change), canonical_since is re-stamped to `today` -- the one
    # case a --check run must flag as stale until --write catches it up.
    routines = [{"id": "D1", "monitor_class": "daily_trading"}]
    head_by_id = {"D1": "D1. Market Development Scan — regular routine"}    # type tag changed
    old_instr = "Read Claude_Task_Plan.md. Perform D1 — deep research."
    got = gr.gen_15_region(routines, head_by_id, prior={"D1": (old_instr, "2026-08-17")}, today="2026-08-19")
    assert got == (
        "  STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1 — regular routine.' "
        "AS canonical_instruction, DATE '2026-08-19' AS canonical_since)"
    )


def test_gen_15_region_seeds_canonical_since_when_absent_from_prior():
    # A routine with no entry in `prior` at all (brand new, or `prior={}`) seeds to `today` regardless
    # of its derived instruction -- there is no earlier date to preserve.
    routines = [{"id": "NEWROUTINE", "monitor_class": "daily_trading"}]
    head_by_id = {"NEWROUTINE": "NEWROUTINE. Brand New Thing — regular routine"}
    got = gr.gen_15_region(routines, head_by_id, prior={}, today="2026-08-19")
    assert got == (
        "  STRUCT('NEWROUTINE' AS routine, 'Read Claude_Task_Plan.md. Perform NEWROUTINE — regular routine.' "
        "AS canonical_instruction, DATE '2026-08-19' AS canonical_since)"
    )


def test_gen_15_region_defaults_read_the_real_file_and_clock_when_not_passed(monkeypatch):
    # `prior` defaults to parse_catalog_since() (the REAL bigquery/15 file) and `today` defaults to
    # datetime.datetime.now(OPERATING_TZ).date().isoformat() -- both replaced here with deterministic
    # stand-ins (rather than mutating the real stdlib datetime module, which every other test in the
    # process shares) so this test proves the DEFAULT wiring itself, not just the explicit-args path
    # every other test in this section uses.
    monkeypatch.setattr(gr, "parse_catalog_since", lambda: {"D1": (
        "Read Claude_Task_Plan.md. Perform D1 — deep research.", "2026-01-01")})

    class _FixedToday:
        @staticmethod
        def isoformat():
            return "2026-08-19"

    class _FixedNow:
        @staticmethod
        def date():
            return _FixedToday()

    class _FixedDatetimeClass:
        @staticmethod
        def now(tz=None):
            # The default clock must be read in the pinned OPERATING plane, never naive local.
            assert tz is gr.OPERATING_TZ
            return _FixedNow()

    class _FixedDatetimeModule:
        datetime = _FixedDatetimeClass

    monkeypatch.setattr(gr, "datetime", _FixedDatetimeModule)

    routines = [{"id": "D1", "monitor_class": "daily_trading"}]
    head_by_id = {"D1": "D1. Market Development Scan — deep research"}
    got = gr.gen_15_region(routines, head_by_id)
    # Unchanged instruction -> the DEFAULT-sourced prior's date (2026-01-01) is preserved, proving
    # both defaults were actually consulted rather than silently falling back to something else.
    assert "DATE '2026-01-01' AS canonical_since" in got


# ---- parse_catalog_since(): the paired reader for gen_15_region's `prior` argument -----------------
def test_parse_catalog_since_round_trips_gen_15_region_output(tmp_path):
    # parse_catalog_since() must recover exactly what gen_15_region() emitted, INCLUDING an
    # apostrophe-bearing instruction (escaped ' -> '' in the SQL literal, un-escaped back on read) --
    # the same round-trip contract CATALOG_ROW_RE/_sql_str's docstrings both call out by name.
    routines = [{"id": "D1", "monitor_class": "daily_trading"},
                {"id": "AR_att", "monitor_class": "queue_driven"}]
    head_by_id = {"D1": "D1. Market Development Scan — deep research",
                  "AR_att": "O'Brien Review Attacker — regular routine"}
    body = gr.gen_15_region(routines, head_by_id, prior={}, today="2026-08-19")
    sql = gr.BEGIN_MARKER + gr.wanted_region(body) + gr.END_MARKER
    p = tmp_path / "15.sql"
    p.write_text(sql)
    got = gr.parse_catalog_since(str(p))
    assert got == {
        "D1": ("Read Claude_Task_Plan.md. Perform D1 — deep research.", "2026-08-19"),
        "AR_att": ("Read Claude_Task_Plan.md. Perform O'Brien Review Attacker — regular routine.", "2026-08-19"),
    }


def test_sql_str_escapes_single_quotes_and_mirrors_check_b_unescape():
    # _sql_str escapes ' -> '' for the single-quoted SQL literal; check_cadence_consistency.py check B
    # (parse_catalog_sql) does the exact inverse ('' -> ') when it reads the row back. Pin both the
    # escape and its reversibility so the two byte-identical derivations stay in lockstep.
    assert gr._sql_str("no quotes here") == "no quotes here"        # no-op when nothing to escape
    assert gr._sql_str("O'Brien") == "O''Brien"
    assert gr._sql_str("a'b'c").replace("''", "'") == "a'b'c"       # round-trips through check B's inverse


def test_gen_15_region_escapes_apostrophe_in_heading():
    # Apostrophe SUPPORT (coordinated with check B's un-escape): the heading's ' is escaped to '' in
    # the single-quoted SQL literal, producing VALID BigQuery SQL (BigQuery stores the un-escaped
    # value). check B un-escapes '' -> ' when parsing the row back so want_catalog (raw heading) matches.
    # GENERIC FORM (2026-08-17): a CODED heading's description (where an apostrophe would live) is now
    # dropped from the instruction entirely, so a coded id no longer exercises this path. Use an
    # UNCODED heading (no "<id>. " prefix, same shape as AR_att/AR_orc) instead -- the one remaining
    # case where a heading's full text, apostrophe included, still reaches the generated SQL.
    got = gr.gen_15_region([{"id": "AR_att"}], {"AR_att": "O'Brien Review Attacker — regular routine"},
                            prior={}, today="2026-08-19")
    assert got == ("  STRUCT('AR_att' AS routine, 'Read Claude_Task_Plan.md. Perform O''Brien "
                   "Review Attacker — regular routine.' AS canonical_instruction, "
                   "DATE '2026-08-19' AS canonical_since)")
    # Mirror of check B: un-escaping the instruction recovers the raw text want_catalog derives.
    assert "Perform O''Brien Review Attacker" in got
    assert got.replace("''", "'").count("O'Brien") == 1


# ---- gen_24_region: only the four period classes -------------------------------------------------
def test_gen_24_region_keeps_only_period_class_routines():
    routines = [
        {"id": "D1", "monitor_class": "daily_trading"},   # not a period class -> dropped
        {"id": "W1", "monitor_class": "weekly_sun"},
        {"id": "M2", "monitor_class": "monthly_ftd"},
        {"id": "Q4", "monitor_class": "quarterly_ftd"},
        {"id": "A1", "monitor_class": "annual_ftd"},
    ]
    got = gr.gen_24_region(routines)
    assert "D1" not in got
    assert got == (
        "    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class),\n"
        "    STRUCT('M2' AS routine, 'monthly_ftd' AS monitor_class),\n"
        "    STRUCT('Q4' AS routine, 'quarterly_ftd' AS monitor_class),\n"
        "    STRUCT('A1' AS routine, 'annual_ftd' AS monitor_class)"
    )
    assert set(gr.PERIOD_CLASSES) == {"weekly_sun", "monthly_ftd", "quarterly_ftd", "annual_ftd"}


def test_gen_24_region_drops_none_monitor_class_without_crashing():
    got = gr.gen_24_region([{"id": "BAD"}, {"id": "W1", "monitor_class": "weekly_sun"}])
    assert got == "    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class)"


# ---- gen_105_region: ALL routines (calendar AND queue_driven) ------------------------------------
def test_gen_105_region_emits_one_row_per_routine_including_queue_driven():
    routines = [
        {"id": "D1", "monitor_class": "daily_trading"},
        {"id": "AR_att", "monitor_class": "queue_driven"},
        {"id": "W1", "monitor_class": "weekly_sun"},
    ]
    got = gr.gen_105_region(routines)
    assert got == (
        "    STRUCT('D1' AS routine, 'daily_trading' AS monitor_class),\n"
        "    STRUCT('AR_att' AS routine, 'queue_driven' AS monitor_class),\n"
        "    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class)"
    )
    # 4-space indent (matches the surrounding UNNEST block), comma on every row but the last.
    assert got.splitlines()[0].startswith("    STRUCT(")
    assert not got.rstrip().endswith(",")


def test_gen_105_region_drops_none_monitor_class_without_crashing():
    got = gr.gen_105_region([{"id": "BAD"}, {"id": "D1", "monitor_class": "daily_trading"}])
    assert got == "    STRUCT('D1' AS routine, 'daily_trading' AS monitor_class)"


def test_gen_105_region_empty_when_no_routines():
    assert gr.gen_105_region([]) == ""


# ---- _cron_utc_to_denver_dow: cron_utc -> BigQuery-numbered Denver day-set (gen_241_region) --------
# gen_241_region's own filter/format is exercised only indirectly, through build_targets() (see
# test_build_targets_returns_eight_targets), so this is the ONLY place that pins the actual
# same-day/previous-day/wraparound ARITHMETIC -- --check can only ever catch DRIFT against a stale
# file, never a self-consistently wrong answer, so these are the sole guard against the shift or the
# +1 conversion silently coming out wrong.
def test_cron_utc_to_denver_dow_same_day_when_hour_is_at_or_after_the_denver_offset():
    # M1R's real shape: 13:00 UTC is well past DENVER_UTC_OFFSET_HOURS_MDT (6), so no day shift is
    # needed -- cron dow 0,1,2,3,4 (Sun-Thu) maps straight across to BigQuery 1,2,3,4,5 via the flat +1.
    assert gr._cron_utc_to_denver_dow("M1R", "0 13 * * 0,1,2,3,4") == [1, 2, 3, 4, 5]


def test_cron_utc_to_denver_dow_shifts_to_the_previous_denver_day_before_the_offset_hour():
    # AR_att/AR_orc/SL2/SL5's real shape: 00:00 UTC has already rolled past Denver local midnight, so
    # cron dow 1,2,3,4,5 (Mon-Fri) each shift back one cron day (-> 0,1,2,3,4) BEFORE the +1 -- landing
    # on the identical [1,2,3,4,5] BigQuery result as the same-day case above, but via the shifted path.
    assert gr._cron_utc_to_denver_dow("AR_att", "0 0 * * 1,2,3,4,5") == [1, 2, 3, 4, 5]


def test_cron_utc_to_denver_dow_sunday_wraps_to_bigquery_saturday_not_negative():
    # The wraparound case none of the five real queue_driven owners exercise today (see
    # DENVER_UTC_OFFSET_HOURS_MDT's own "latent, not live" note): a cron dow of 0 (Sunday) shifted back
    # a day must land on cron Saturday (6), not -1 -- `(d - 1) % 7` is non-negative for Python's `%`
    # with a positive divisor, which is the whole reason the shift happens in cron-numbered space
    # before the +1. BigQuery EXTRACT(DAYOFWEEK): Saturday = 7.
    assert gr._cron_utc_to_denver_dow("TESTROUTINE", "0 1 * * 0") == [7]


def test_cron_utc_to_denver_dow_raises_systemexit_on_malformed_cron():
    # A cron_utc that isn't a 5-field string (e.g. a routine with no expected_trigger.cron_utc at all,
    # which defaults to "") must fail LOUDLY naming the routine, not silently guess a day-set.
    with pytest.raises(SystemExit, match=r"TESTROUTINE: expected_trigger\.cron_utc '' is not a "
                                          r"5-field cron"):
        gr._cron_utc_to_denver_dow("TESTROUTINE", "")


# ---- wanted_region / current_region / write_region round-trip ------------------------------------
def test_wanted_region_padding_is_exact():
    assert gr.wanted_region("BODY") == "\nBODY\n  "


def _sql_with_region(body_between):
    """A minimal SQL file whose marker region currently holds `body_between` verbatim."""
    return (
        "CREATE OR REPLACE VIEW `x.y.z` AS\n"
        "SELECT * FROM UNNEST([\n"
        + gr.BEGIN_MARKER + body_between + gr.END_MARKER + "\n"
        "]);\n"
    )


# ---- _region_bounds(): the single shared marker-finding helper (2026-08-08 dedup) ------------------
def test_region_bounds_returns_marker_positions():
    txt = _sql_with_region("\nBODY\n  ")
    b, e = gr._region_bounds(txt, "somepath.sql")
    assert txt[b:b + len(gr.BEGIN_MARKER)] == gr.BEGIN_MARKER
    assert txt[e:e + len(gr.END_MARKER)] == gr.END_MARKER


def test_region_bounds_raises_systemexit_naming_the_path():
    with pytest.raises(SystemExit, match=r"somepath\.sql: could not find BEGIN/END"):
        gr._region_bounds("no markers here", "somepath.sql")


def test_current_region_returns_exact_text_between_markers(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text(_sql_with_region("\n    STRUCT('D1' AS routine, 'daily_trading' AS schedule)\n  "))
    assert gr.current_region(str(p)) == "\n    STRUCT('D1' AS routine, 'daily_trading' AS schedule)\n  "


def test_current_region_none_when_markers_absent(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text("no markers here\n")
    assert gr.current_region(str(p)) is None


def test_write_region_replaces_region_and_reports_change_then_idempotent(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text(_sql_with_region("\nSTALE\n  "))
    body = "    STRUCT('D1' AS routine, 'daily_trading' AS schedule)"
    assert gr.write_region(str(p), body) is True            # first write changes the file
    assert gr.current_region(str(p)) == gr.wanted_region(body)
    assert gr.write_region(str(p), body) is False           # second write is a no-op
    # Surrounding SQL preserved.
    txt = p.read_text()
    assert txt.startswith("CREATE OR REPLACE VIEW `x.y.z` AS")
    assert txt.rstrip().endswith("]);")


def test_write_region_raises_systemexit_when_markers_missing(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text("no markers here\n")
    with pytest.raises(SystemExit):
        gr.write_region(str(p), "anything")


# ---- main() --write / --check end-to-end ---------------------------------------------------------
def _wire_fixture(tmp_path, monkeypatch, *, plan_headings=True, extra_routine=""):
    plan = tmp_path / "Claude_Task_Plan.md"
    if plan_headings:
        plan.write_text(
            "## D1. Market Development Scan — deep research\nbody\n\n"
            "## W1. Catalyst Calendar (Strategies A and C) — deep research\nbody\n"
        )
    else:
        plan.write_text("# no routine headings\n")
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        "routines:\n"
        "  - id: D1\n    monitor_class: daily_trading\n"
        "  - id: W1\n    monitor_class: weekly_sun\n"
        + extra_routine
    )
    f12 = tmp_path / "12.sql"
    f15 = tmp_path / "15.sql"
    f24 = tmp_path / "24.sql"
    f105 = tmp_path / "105.sql"
    # 114 (ops.sp_assert_deps' period_class CTE) is the 5th target, added 2026-07-28. It MUST be wired
    # here too: build_targets() returns it unconditionally, so leaving it unpatched would point a
    # tmp-path test at the REAL repo file and let a --write test mutate the working tree.
    f114 = tmp_path / "114.sql"
    # 132 (state.queue_driven_silence_watch, 2026-08-03) is the 6th target. Same lockstep rule as 114
    # above: unpatched, a --write test would mutate the REAL bigquery/132 in the working tree.
    f132 = tmp_path / "132.sql"
    # 205 (the SUPERSEDING, live copy of ops.sp_assert_deps' period_class CTE — see build_targets()'s
    # own comment) is the 7th target, registered 2026-09-04. Same lockstep rule again, and here it is
    # the sharpest: bigquery/205 is a frozen, live-parity-checked file, so an unpatched
    # ALERT_MSG_STABILITY_SQL would let the --write round-trip tests below overwrite its real 20-row
    # period_class region with this fixture's single W1 row, mid-test-run.
    f205 = tmp_path / "205.sql"
    # 241 (state.queue_driven_missed_fire_watch's `routines` CTE, gen_241_region) is the 8th target.
    # Same lockstep rule as 114/132/205 above: unpatched, a --write test below would reach PAST this
    # fixture and overwrite the real, 1000+-line bigquery/241_queue_driven_per_day_missed_fire.sql with
    # whatever this fixture's cadence.yaml happens to carry (empty when it has no queue_driven routine,
    # a one-row body when a test adds one) -- exactly the cross-test clobber
    # tests/test_cadence_consistency.py::_patch_gen_paths' own comment already records biting three
    # times, once per target added (105, 114, 132), now with an 8th chance to recur.
    f241 = tmp_path / "241.sql"
    for f in (f12, f15, f24, f105, f114, f132, f205, f241):
        f.write_text(_sql_with_region("\nSTALE\n  "))
    monkeypatch.setattr(gr, "PLAN", str(plan))
    monkeypatch.setattr(gr, "CADENCE", str(cadence))
    monkeypatch.setattr(gr, "CADENCE_MONITOR_SQL", str(f12))
    monkeypatch.setattr(gr, "ROUTINE_CATALOG_SQL", str(f15))
    monkeypatch.setattr(gr, "PERIOD_WATCH_SQL", str(f24))
    monkeypatch.setattr(gr, "ROUTINE_CATCHUP_SQL", str(f105))
    monkeypatch.setattr(gr, "DEP_GATE_SQL", str(f114))
    monkeypatch.setattr(gr, "QUEUE_SILENCE_SQL", str(f132))
    monkeypatch.setattr(gr, "ALERT_MSG_STABILITY_SQL", str(f205))
    monkeypatch.setattr(gr, "QUEUE_DRIVEN_MISSED_FIRE_SQL", str(f241))
    return f12, f15, f24, f105, f114, f132, f241, f205


def test_main_write_then_check_is_a_clean_round_trip(tmp_path, monkeypatch, capsys):
    f12, f15, f24, f105, _f114, _f132, _f241, _f205 = _wire_fixture(tmp_path, monkeypatch)

    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    assert "regenerated" in capsys.readouterr().out

    # 12 gets both calendar routines; 24 gets only the weekly one; 15 gets both with instructions;
    # 105 gets both (it takes the full roster, calendar AND queue_driven alike).
    assert "STRUCT('D1' AS routine, 'daily_trading' AS schedule)" in f12.read_text()
    assert "STRUCT('W1' AS routine, 'weekly_sun' AS schedule)" in f12.read_text()
    assert "D1" not in f24.read_text() and "STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class)" in f24.read_text()
    assert "Perform D1 — deep research." in f15.read_text()
    assert "STRUCT('D1' AS routine, 'daily_trading' AS monitor_class)" in f105.read_text()
    assert "STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class)" in f105.read_text()

    # --check now agrees (exit 0), and --write again is a no-op.
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 0
    assert "OK" in capsys.readouterr().out

    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    assert "already current" in capsys.readouterr().out


def test_main_check_returns_1_and_reports_stale_region(tmp_path, monkeypatch, capsys):
    _wire_fixture(tmp_path, monkeypatch)  # files still hold the "STALE" placeholder
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 1
    assert "STALE" in capsys.readouterr().out


def test_main_check_returns_1_when_a_target_lacks_markers(tmp_path, monkeypatch, capsys):
    # --check on a file with no markers must report the marker problem (current_region()==None path)
    # and fail, NOT silently pass — a stripped/renamed marker would otherwise hide real staleness.
    f12, _f15, _f24, _f105, _f114, _f132, _f241, _f205 = _wire_fixture(tmp_path, monkeypatch)
    f12.write_text("a file with no markers at all\n")
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 1
    assert "could not find BEGIN/END GENERATED ROUTINE LIST markers" in capsys.readouterr().out


def test_main_requires_exactly_one_of_write_or_check(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py"])
    with pytest.raises(SystemExit):
        gr.main()


def test_main_write_check_round_trips_with_an_apostrophe_heading(tmp_path, monkeypatch):
    # Apostrophe SUPPORT end to end: --write emits ESCAPED, valid SQL for a heading with an apostrophe,
    # and --check round-trips clean against it. (check B's paired '' -> ' un-escape lives in the
    # non-owned check_cadence_consistency.py — see partC-report.md for that half of the change.)
    # GENERIC FORM (2026-08-17): a CODED heading's description (where an apostrophe would live) is now
    # dropped from the instruction, so this needs an UNCODED heading (no "<id>. " prefix, same shape as
    # AR_att/AR_orc) to keep exercising the escape/round-trip path at all.
    # AR_att's expected_trigger.cron_utc is required now that 241 is an 8th, unconditional target:
    # gen_241_region() feeds every queue_driven routine's cron_utc through _cron_utc_to_denver_dow(),
    # which raises SystemExit on a routine with no (or an empty) cron_utc -- so an AR_att row with no
    # expected_trigger block would take main()'s --write down before this test ever reaches its
    # apostrophe assertions. 00:00 UTC Mon-Fri is AR_att's real ops/cadence.yaml shape (pre-offset ->
    # Denver Sun-Thu, same as every other queue_driven routine today).
    _f12, f15, _f24, _f105, _f114, _f132, _f241, _f205 = _wire_fixture(
        tmp_path, monkeypatch,
        extra_routine=("  - id: AR_att\n    monitor_class: queue_driven\n"
                       "    expected_trigger:\n      cron_utc: '0 0 * * 1,2,3,4,5'\n"))
    plan = tmp_path / "Claude_Task_Plan.md"      # add an uncoded heading carrying an apostrophe
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "## W1. Catalyst Calendar (Strategies A and C) — deep research\nbody\n\n"
        "## O'Brien Review Attacker — regular routine\nbody\n"
    )
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--write"])
    assert gr.main() == 0
    assert "Perform O''Brien Review Attacker — regular routine." in f15.read_text()   # escaped in the SQL literal
    monkeypatch.setattr(sys, "argv", ["gen_routine_lists.py", "--check"])
    assert gr.main() == 0                                                       # self-consistent round-trip


def test_build_targets_returns_eight_targets(tmp_path, monkeypatch):
    # The fixture carries a queue_driven routine ON PURPOSE (2026-09-04 quality pass). With the default
    # `extra_routine=""` cadence -- D1 + W1 only -- `queue_ids` was necessarily EMPTY, so the partition
    # assertions below held for ANY behavior of gen_132_region and this test could not fail: mutating
    # gen_132_region to return "" (emptying bigquery/132's watch list entirely) left all tests in
    # this file green. gen_132_region is not exercised anywhere else in this file, and the only backstop
    # was cross-file -- tests/test_cadence_consistency.py::test_gen_routine_lists_against_real_repo_
    # write_is_noop, which detects it only by WRITING the emptied region into the real, frozen
    # bigquery/132 and failing dirty (the clobber mode that file's own _patch_gen_paths comment records
    # as having bitten three times). One queue_driven id in the fixture makes the partition real here.
    # AR_att's expected_trigger.cron_utc is required now that 241 (gen_241_region) is an 8th,
    # unconditional target -- see test_main_write_check_round_trips_with_an_apostrophe_heading's own
    # comment on the same requirement.
    _wire_fixture(
        tmp_path, monkeypatch,
        extra_routine=("  - id: AR_att\n    monitor_class: queue_driven\n"
                       "    expected_trigger:\n      cron_utc: '0 0 * * 1,2,3,4,5'\n"))
    targets = gr.build_targets()
    assert len(targets) == 8
    assert [os.path.basename(p) for p, _ in targets] == [
        "12.sql", "15.sql", "24.sql", "105.sql", "114.sql", "132.sql", "241.sql", "205.sql"]
    # 12 and 132 must PARTITION the roster: every routine is either calendar-class (12) or
    # queue_driven (132), never neither. A routine absent from both would be watched by nothing --
    # exactly the SL2/SL5 hole bigquery/132 closes.
    bodies = {os.path.basename(p): body for p, body in targets}

    def _ids(body):
        return {ln.split("'")[1] for ln in body.splitlines() if ln.strip().startswith("STRUCT(")}

    all_ids = {r["id"] for r in gr.load_cadence_routines() if r.get("monitor_class") is not None}
    calendar_ids, queue_ids = _ids(bodies["12.sql"]), _ids(bodies["132.sql"])
    assert queue_ids == {"AR_att"}, "gen_132_region dropped the queue_driven routine"
    assert calendar_ids | queue_ids == all_ids, "a routine is in neither watch list"
    assert not (calendar_ids & queue_ids), "a routine is in both watch lists"
    # 241 (gen_241_region) applies the SAME queue_driven filter gen_132_region does, so it must name
    # exactly the same routines -- the two regions can never disagree about WHICH routines are
    # queue-driven (see gen_241_region's own docstring and build_targets()'s comment on this target).
    assert _ids(bodies["241.sql"]) == queue_ids, "gen_241_region disagrees with gen_132_region"
    # 114 (ops.sp_assert_deps' period_class CTE, 2026-07-28) and 205 (the SUPERSEDING, LIVE copy of
    # that same procedure, registered as a target 2026-09-04) both reuse gen_24_region, so all three
    # bodies must be BYTE-IDENTICAL -- that identity is the guarantee the FATAL dependency gate and
    # state.cadence_period_watch can never disagree about which routines are period-cadence, and
    # covering 205 here is what keeps the DEPLOYED copy of the gate inside that guarantee.
    assert bodies["114.sql"] == bodies["24.sql"]
    assert bodies["205.sql"] == bodies["24.sql"]


def test_build_targets_drops_205_when_only_the_dep_gate_is_redirected(tmp_path, monkeypatch):
    """PAIRED-PATH GUARD (see build_targets()). bigquery/114 and bigquery/205 are two copies of ONE
    procedure, so a fixture that redirects DEP_GATE_SQL at a tmp tree but leaves ALERT_MSG_STABILITY_SQL
    pointing at the real repo is mis-wired -- and an unguarded 8th target would then let `--write` reach
    PAST the fixture and overwrite the real, frozen, live-parity-checked bigquery/205 with the fixture's
    one-row period_class list. tests/test_cadence_consistency.py::_patch_gen_paths was exactly that
    shape until it was wired for 205 in the 2026-09-04 pass (it now takes an `sql205`, and an `sql241`
    since this pass, and patches all eight; its own comment records this cross-test clobber biting
    three times -- once per generated target added -- and notes the guard is consequently DORMANT for
    those tests). Pin that the target drops out instead, so the NEXT fixture that forgets is safe.

    241 (gen_241_region, unlike 205) carries NO conditional guard of its own -- it is unconditionally
    appended in build_targets() before the `if` block below runs -- so it is unaffected by this
    redirect and must still appear in `names` even while 205 is dropped."""
    _wire_fixture(tmp_path, monkeypatch)
    monkeypatch.setattr(gr, "ALERT_MSG_STABILITY_SQL",
                        os.path.join(gr.ROOT, "bigquery", "205_alert_message_stability.sql"))
    names = [os.path.basename(p) for p, _ in gr.build_targets()]
    assert names == ["12.sql", "15.sql", "24.sql", "105.sql", "114.sql", "132.sql", "241.sql"]
    # ...and with BOTH patched (the normal _wire_fixture wiring) it comes back, still last (241 is
    # appended before the conditional 205 in build_targets()).
    monkeypatch.setattr(gr, "ALERT_MSG_STABILITY_SQL", str(tmp_path / "205.sql"))
    assert [os.path.basename(p) for p, _ in gr.build_targets()][-1] == "205.sql"


# ---- load_cadence_routines / load_headings_by_id edge behavior ------------------------------------
def test_load_cadence_routines_empty_and_no_routines_key(tmp_path, monkeypatch):
    cadence = tmp_path / "cadence.yaml"
    monkeypatch.setattr(gr, "CADENCE", str(cadence))
    cadence.write_text("")                       # empty file -> yaml.safe_load returns None
    assert gr.load_cadence_routines() == []
    cadence.write_text("timezone: America/Denver\n")   # present but no 'routines:' key
    assert gr.load_cadence_routines() == []


def test_load_headings_by_id_drops_none_mapping_and_last_wins_on_duplicate(tmp_path, monkeypatch):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(
        "## D1. First — deep research\nbody\n\n"
        "## D1. Duplicate id, different heading — deep research\nbody\n\n"
        "## An unmappable heading with no id — regular routine\nbody\n"
    )
    monkeypatch.setattr(gr, "PLAN", str(plan))
    got = gr.load_headings_by_id()
    # heading_to_id(...) is None for the unmappable heading -> the `if heading_to_id(h)` guard drops it.
    assert set(got) == {"D1"}
    # Two headings map to D1; dict-comprehension keeps the LAST (matches build_triggers_manifest dedup).
    assert got["D1"] == "D1. Duplicate id, different heading — deep research"

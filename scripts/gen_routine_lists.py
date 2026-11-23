#!/usr/bin/env python3
"""Generate the routine-list STRUCT rows for bigquery/12/15/24/105/114/132/205/241/280 from
ops/cadence.yaml + Claude_Task_Plan.md (+ ops/routine_backup.json for 280).

WHY THIS EXISTS (ARCH-3 Item 30b, closing the deferred hand-copy hole). bigquery/12
(state.cadence_expected_today), bigquery/15 (ops.routine_catalog), bigquery/24
(state.cadence_period_watch), and bigquery/105 (state.routine_catchup_window) each independently
hand-carry a list of routine STRUCT rows that must stay byte-consistent with ops/cadence.yaml.
scripts/check_cadence_consistency.py's checks A/B/J only CHECK the first three's agreement --
nothing GENERATES the rows, so adding/renaming/rescheduling a routine still required hand-editing
multiple files (the deferred half of Item 30b). This script generates the row text for a
marker-delimited region inside each file, so a routine change only requires editing ops/cadence.yaml
(+ a Claude_Task_Plan.md heading for a brand-new routine) and re-running --write.

It does NOT generate bigquery/31_catchup_notify.sql or bigquery/59_catchup_autofire.sql's catchup-safe
UNNEST lists (those stay hand-kept, declared judgment calls -- check_cadence_consistency.py's check K
CHECKS them against cadence.yaml's catchup_safe field instead), and does NOT generate the
Claude_Task_Plan.md ROUTINE INVENTORY table (check L checks that by hand-authored convention too).

Regions generated (marker-delimited, one BEGIN/END pair per file):
  bigquery/12_cadence_monitor.sql   -- state.cadence_expected_today's `routines` CTE STRUCT rows,
                                        one per calendar-class routine (monitor_class != queue_driven),
                                        in ops/cadence.yaml order.
  bigquery/15_routine_catalog.sql   -- ops.routine_catalog's STRUCT rows, ALL routines, cadence.yaml
                                        order, instruction text derived from the matching
                                        Claude_Task_Plan.md heading exactly as check B does.
  bigquery/24_cadence_period_watch.sql -- state.cadence_period_watch's `routines` CTE STRUCT rows,
                                        one per routine whose monitor_class is a period class
                                        (weekly_sun/monthly_ftd/quarterly_ftd/annual_ftd), cadence.yaml
                                        order.
  bigquery/105_routine_catchup_window.sql -- state.routine_catchup_window's `routines` CTE STRUCT
                                        rows, ALL routines INCLUDING the 4 queue_driven ids (unlike
                                        bigquery/12's calendar-only filter -- this is the one region
                                        that needs the full routine roster), cadence.yaml order.
  bigquery/114_period_aware_dependency_gate.sql -- ops.sp_assert_deps' `period_class` CTE STRUCT rows.
                                        BYTE-IDENTICAL to the bigquery/24 region (same gen_24_region
                                        call): the dependency gate resolves a dep's period window from
                                        the same (routine -> monitor_class) mapping the period watch
                                        view uses, so the gate and the monitor cannot disagree about
                                        which routines are period-cadence. 114 embeds the list rather
                                        than joining state.cadence_period_watch because it is a FATAL,
                                        unwrapped gate that must not gain a runtime view dependency.
  bigquery/132_queue_driven_silence_watch.sql -- state.queue_driven_silence_watch's `routines` CTE
                                        STRUCT rows, ONLY the queue_driven routines -- the exact
                                        complement of the bigquery/12 region. Those five sit outside
                                        state.cadence_expected_today and therefore outside BOTH
                                        cadence nets; 132 is the only thing watching them.
  bigquery/205_alert_message_stability.sql -- ops.sp_assert_deps' `period_class` CTE STRUCT rows
                                        AGAIN, and this is the LIVE copy: bigquery/205 CREATE-OR-
                                        REPLACEs the same procedure ("canonical body from bigquery/114,
                                        message stabilised"), so 205 is the DEPLOYED definition and
                                        bigquery/114 above is now the DR-record-only one. Byte-identical
                                        to the 24 and 114 regions (same gen_24_region call), for the
                                        same reason 114 reuses it.
  bigquery/280_instruction_drift_full_text.sql -- state.routine_canonical_full_instruction's STRUCT
                                        rows (added 2026-11-23): one per FLEET routine in
                                        ops/trigger_ids.json order (never `_meta`, never a
                                        `personal_*` entry), carrying the FULL canonical trigger
                                        instruction from ops/routine_backup.json (core one-liner PLUS
                                        the standing operator paragraphs) and its canonical_full_since
                                        date. The ONE region whose source is routine_backup.json rather
                                        than cadence.yaml + the plan; see gen_280_region().

Usage:
  python scripts/gen_routine_lists.py --write   # regenerate all 9 marker regions in place
  python scripts/gen_routine_lists.py --check   # exit 1 + diff if any region is stale

Markers (exactly one BEGIN/END pair per file, wrapping ONLY the STRUCT rows -- the surrounding
`SELECT * FROM UNNEST([ ... ])` / `FROM UNNEST([ ... ])` SQL stays hand-kept):
  -- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
  -- END GENERATED ROUTINE LIST
"""
import argparse
import datetime
import json
import os
import re
import sys
from zoneinfo import ZoneInfo

try:
    # this module's own reads now go through lib.textio.load_yaml() (2026-07-29 textio
    # adoption), so `yaml` is no longer referenced directly here, but the import stays for this
    # fail-fast ImportError guard (a clear "pip install pyyaml" message beats textio.py's own bare
    # ImportError traceback).
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

from lib.routine_manifest import (
    parse_routine_headings, heading_to_id, instruction_text, cadence_routines,
)
from lib.sql_files import SQL_QUOTED_BODY, sql_quote, sql_unquote
from lib.textio import read_text, read_text_preserving_newlines, load_yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")

CADENCE_MONITOR_SQL = os.path.join(ROOT, "bigquery", "12_cadence_monitor.sql")
ROUTINE_CATALOG_SQL = os.path.join(ROOT, "bigquery", "15_routine_catalog.sql")
PERIOD_WATCH_SQL = os.path.join(ROOT, "bigquery", "24_cadence_period_watch.sql")
ROUTINE_CATCHUP_SQL = os.path.join(ROOT, "bigquery", "105_routine_catchup_window.sql")
DEP_GATE_SQL = os.path.join(ROOT, "bigquery", "114_period_aware_dependency_gate.sql")
# The SUPERSEDING copy of the same ops.sp_assert_deps procedure DEP_GATE_SQL declares -- bigquery/205
# CREATE-OR-REPLACEs it ("canonical body from bigquery/114, message stabilised"), so 205 carries the
# period_class rows that are actually DEPLOYED and 114's copy is DR-record only. Registered as a target
# 2026-09-04; see build_targets() for the hole that left open while it was not one.
ALERT_MSG_STABILITY_SQL = os.path.join(ROOT, "bigquery", "205_alert_message_stability.sql")

# The pinned OPERATING timezone. Deliberately hardcoded, not looked up — see CLAUDE.md
# "Making the OPERATING timezone plane dynamic" (settled: never dynamic).
OPERATING_TZ = ZoneInfo("America/Denver")

BEGIN_MARKER = "-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)"
END_MARKER = "-- END GENERATED ROUTINE LIST"

PERIOD_CLASSES = ("weekly_sun", "monthly_ftd", "quarterly_ftd", "annual_ftd")


def load_cadence_routines():
    """Ordered list of routine dicts, in ops/cadence.yaml file order (the canonical order every
    generated region reproduces)."""
    doc = load_yaml(CADENCE)
    return cadence_routines(doc)


def load_headings_by_id():
    return {heading_to_id(h): h for h in parse_routine_headings(PLAN) if heading_to_id(h)}


def gen_12_region(routines):
    """state.cadence_expected_today rows: one per calendar-class routine (monitor_class !=
    queue_driven), cadence.yaml order, 4-space indent matching the surrounding UNNEST([ block."""
    # Exclude both queue_driven AND a missing/None monitor_class (a malformed cadence.yaml routine):
    # the old `!= "queue_driven"` filter kept a None-monitor_class row, then the f-string's
    # r['monitor_class'] bracket-access raised KeyError, unlike the parallel gen_24_region whose
    # `in PERIOD_CLASSES` filter already drops None. check_cadence_consistency.py flags the missing
    # key loudly (`{rid}: missing monitor_class`), so omitting the row here masks nothing (2026-07-17).
    rows = [r for r in routines if r.get("monitor_class") not in ("queue_driven", None)]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS schedule){comma}")
    return "\n".join(lines)


CATALOG_ROW_RE = re.compile(
    r"STRUCT\('([^']+)' AS routine, '(" + SQL_QUOTED_BODY + r")' AS canonical_instruction, "
    r"DATE '(\d{4}-\d{2}-\d{2})' AS canonical_since\)")


def parse_catalog_since(path=None):
    """{routine: (canonical_instruction, canonical_since)} parsed back out of the CURRENT
    bigquery/15 generated region. Used only to PRESERVE an existing canonical_since across a
    regeneration whose instruction text for that routine did not change (see gen_15_region)."""
    txt = read_text(path or ROUTINE_CATALOG_SQL)
    return {rid: (sql_unquote(instr), since)
            for rid, instr, since in CATALOG_ROW_RE.findall(txt)}


def gen_15_region(routines, head_by_id, prior=None, today=None):
    """ops.routine_catalog rows: ALL routines, cadence.yaml order, instruction text derived from the
    matching plan heading exactly as check_cadence_consistency.py's check B derives want_catalog, so
    the generated output stays byte-compatible with that check. A routine with no plan heading yet
    (should not happen in a consistent tree) gets an empty instruction string -- check B/C will flag
    that loudly rather than this generator silently guessing.

    A heading may contain an apostrophe; it is backslash-escaped for the single-quoted GoogleSQL
    literal by lib.sql_files.sql_quote (the doubled '' form is NOT valid GoogleSQL). check B
    (check_cadence_consistency.parse_catalog_sql) and parse_catalog_since() both read the row back
    through the paired sql_unquote(), so the escaping and un-escaping live in one module. Byte-identical on the current tree --
    no routine heading contains an apostrophe today, so this only changes output once one does.
    (check B's regex stops at the instruction literal's closing quote and does not require the STRUCT
    to end there, so the third field below is invisible to it -- deliberately, so this column can move
    without touching that check.)

    canonical_since (added 2026-08-19) is the DATE this routine's canonical_instruction last CHANGED.
    state.instruction_drift (bigquery/183) needs it because its "live" side is not a live read of the
    web-UI trigger at all -- it is the text the routine TRANSCRIBED THE LAST TIME IT RAN
    (state.routine_last_instruction <- ops.run_log.instruction). A sample logged BEFORE the canonical
    text changed is therefore not evidence about the live trigger in either direction, and reporting it
    as `drifted` asserts a fact the view cannot observe. See bigquery/183's header for the incident.

    STABILITY CONTRACT (why --check does not thrash): the date is PRESERVED verbatim whenever this
    routine's derived instruction equals the one already stored in the file, and only re-stamped to
    `today` when the text actually changes. So a --check run on any later day regenerates a
    byte-identical region and passes; the one run that changes a heading stamps that day's date and
    CI then requires --write, exactly as it already does for the text itself. A routine absent from
    the current file (brand new) seeds to today.

    `today` is the OPERATING-plane (America/Denver) date, not the container's ~UTC date: bigquery/183
    compares canonical_since against ops.run_log.run_date, which is keyed in that plane, and the
    repo-writing routines all fire 18:45-22:30 MT -- i.e. the next UTC calendar day."""
    prior = parse_catalog_since() if prior is None else prior
    today = today or datetime.datetime.now(OPERATING_TZ).date().isoformat()
    lines = []
    n = len(routines)
    for i, r in enumerate(routines):
        rid = r["id"]
        heading = head_by_id.get(rid)
        instr = instruction_text(heading) if heading else ""
        prior_instr, prior_since = prior.get(rid, (None, None))
        # Fleet-wide seed date for canonical_since: 2026-08-17, commit 29f6547 ("routine-instruction
        # format decoupling"), which dropped every routine's descriptive TITLE from the canonical
        # instruction so the remote trigger references only the stable routine ID. Any routine whose
        # stored date is still 2026-08-17 has not had its instruction text changed since that migration.
        # (This note used to hang on a module-level CANONICAL_SINCE_SEED = "2026-08-17" constant that no
        # code ever read -- the date semantics it explains live HERE, in the preserve-vs-restamp choice,
        # so it was reattached and the never-read constant dropped, 2026-09-04. Only "still this value"
        # became "still 2026-08-17"; the constant it pointed at no longer exists to name.)
        since = prior_since if (prior_since and prior_instr == instr) else today
        comma = "," if i < n - 1 else ""
        # rid is a constrained \w+ id (never quoted), so only the free-text instruction needs escaping
        # -- and check B un-escapes only the instruction capture, so escaping only it keeps the two
        # derivations matched.
        lines.append(f"  STRUCT('{rid}' AS routine, '{sql_quote(instr)}' AS canonical_instruction, "
                     f"DATE '{since}' AS canonical_since){comma}")
    return "\n".join(lines)


def gen_24_region(routines):
    """state.cadence_period_watch rows: routines whose monitor_class is one of the four period
    classes, cadence.yaml order, 4-space indent matching the surrounding UNNEST([ block."""
    rows = [r for r in routines if r.get("monitor_class") in PERIOD_CLASSES]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


def gen_105_region(routines):
    """state.routine_catchup_window rows: ALL routines, INCLUDING the 4 queue_driven ids (unlike
    gen_12_region's calendar-only filter and gen_24_region's period-only filter), cadence.yaml
    order, 4-space indent matching the surrounding UNNEST([ block. This is the one generated region
    that needs the full routine roster -- state.routine_catchup_window computes a catch-up
    evidence window for every routine, calendar-predictable or queue_driven alike (owner directive
    2026-07-25; see bigquery/105_routine_catchup_window.sql's header)."""
    rows = [r for r in routines if r.get("monitor_class") is not None]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


def _region_bounds(txt, path):
    """(begin_index, end_index) of the marker positions in `txt`. RAISES SystemExit on missing/out-of-
    order markers -- the single shared bounds-finder for this module. Before 2026-08-08 this exact
    `txt.find(BEGIN_MARKER)` / `txt.find(END_MARKER)` / `e < b` check was duplicated verbatim in
    current_region() below (which returned None on failure instead of raising), so the two paths could
    silently drift apart if one copy's finding logic were ever tweaked without the other. Unified on
    the RAISING behavior (the stricter/louder of the two) because write_region() below -- a mutating
    operation -- must never proceed past a missing region; current_region() (read-only, used by --check
    to keep reporting every OTHER target's staleness) adapts that into its own None-on-failure contract
    by catching the SystemExit itself, rather than re-implementing the search."""
    b = txt.find(BEGIN_MARKER)
    e = txt.find(END_MARKER)
    if b == -1 or e == -1 or e < b:
        raise SystemExit(f"{path}: could not find BEGIN/END GENERATED ROUTINE LIST markers")
    return b, e


def current_region(path):
    """The exact text currently between the markers (excluding the marker lines themselves), or None
    if the markers are not present in the file (adapted from _region_bounds' SystemExit -- see that
    function's docstring)."""
    txt = read_text(path)
    try:
        b, e = _region_bounds(txt, path)
    except SystemExit:
        return None
    return txt[b + len(BEGIN_MARKER):e]


def wanted_region(body):
    """The canonical marker-region text (including the newline padding on each side) a `body` of
    STRUCT-row lines is rendered into -- shared by --write (what gets written) and --check (what is
    compared against) so the two can never drift from each other."""
    return "\n" + body + "\n  "


def write_region(path, body):
    # Newline-preserving read AND write (lib.textio.read_text_preserving_newlines + newline=""): the
    # generator rewrites only the marked region, so the rest of the file must round-trip byte-exact;
    # read_text()'s universal-newline translation plus a plain "w" open would have rewritten a CRLF
    # file as LF outside the region on the first --write (2026-10-31; same reason split_task_plan.py
    # uses this pair).
    txt = read_text_preserving_newlines(path)
    b, e = _region_bounds(txt, path)
    new_txt = txt[:b + len(BEGIN_MARKER)] + wanted_region(body) + txt[e:]
    if new_txt != txt:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(new_txt)
        return True
    return False


QUEUE_SILENCE_SQL = os.path.join(ROOT, "bigquery", "132_queue_driven_silence_watch.sql")
QUEUE_DRIVEN_MISSED_FIRE_SQL = os.path.join(ROOT, "bigquery", "241_queue_driven_per_day_missed_fire.sql")


def gen_132_region(routines):
    """state.queue_driven_silence_watch rows: ONLY the queue_driven routines -- the exact complement
    of gen_12_region's calendar-class filter. These four are excluded from
    state.cadence_expected_today by construction, so neither state.cadence_watch nor
    state.cadence_period_watch can see them; bigquery/132 is their only net. Generating the list here
    (rather than hand-keeping it) means adding a 5th queue_driven routine to ops/cadence.yaml cannot
    silently leave it unwatched. cadence.yaml order, 4-space indent matching the surrounding
    UNNEST([ block."""
    rows = [r for r in routines if r.get("monitor_class") == "queue_driven"]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class){comma}")
    return "\n".join(lines)


# The UTC hour at/after which a queue-driven owner's cron_utc fires on the SAME Denver calendar day it
# serves (MDT offset -- Denver is UTC-6 in MDT, the season ops/cadence.yaml's time_local documents and
# check_cron_dst_safety.py enforces). Deliberately DUPLICATES check_cadence_consistency.py's own
# DENVER_UTC_OFFSET_HOURS_MDT rather than importing it: that check already derives the identical
# same-day/previous-day split for the same five routines (its check Q), but a GENERATOR importing a
# constant out of the CHECKER that validates the generator's own target would invert this file's
# dependency direction (gen_routine_lists.py has no import of check_cadence_consistency.py anywhere
# today, and this one constant is not worth starting that). MDT ONLY -- latent, not live: no
# queue-driven owner's cron_utc hour falls in the 06:00-06:59 UTC band today.
DENVER_UTC_OFFSET_HOURS_MDT = 6


def _cron_utc_to_denver_dow(routine_id, cron_utc):
    """[BigQuery EXTRACT(DAYOFWEEK) values (1=Sunday..7=Saturday), ...], sorted and deduped, for the
    Denver calendar day(s) a 5-field `cron_utc` string actually FIRES on -- derived from its hour +
    day-of-week fields, never hand-copied. Two numbering systems meet here:
      - cron day-of-week: 0=Sunday .. 6=Saturday (the field ops/cadence.yaml's cron_utc strings use).
      - BigQuery EXTRACT(DAYOFWEEK): 1=Sunday .. 7=Saturday -- exactly one higher throughout, so that
        half of the conversion is a flat +1 with no wraparound of its own.
    The wraparound that DOES need handling is the UTC-to-Denver DAY shift: a cron firing before
    DENVER_UTC_OFFSET_HOURS_MDT UTC has already rolled past Denver local midnight, so its own
    day-of-week field names the day AFTER the Denver day it actually serves -- e.g. a cron_utc dow
    entry of 1 (Monday) fired at 00:xx UTC is really a Denver-SUNDAY (cron 0) fire, which is BigQuery
    1. `(d - 1) % 7` performs that shift in cron-numbered space -- Python's `%` is non-negative for a
    positive divisor, so cron Sunday (0) shifts to cron Saturday (6), not -1 -- BEFORE the +1
    conversion to BigQuery numbering. A slot at/after the boundary hour needs no shift at all: its own
    dow field already names the Denver day it fires on."""
    fields = cron_utc.split()
    if len(fields) != 5:
        raise SystemExit(f"{routine_id}: expected_trigger.cron_utc {cron_utc!r} is not a 5-field cron "
                         f"-- gen_241_region cannot derive its Denver day-set")
    try:
        hour = int(fields[1])
    except ValueError:
        raise SystemExit(f"{routine_id}: expected_trigger.cron_utc hour field {fields[1]!r} is not a "
                         f"plain integer -- gen_241_region cannot derive its Denver day-set") from None
    try:
        cron_dows = [int(x) for x in fields[4].split(",")]
    except ValueError:
        raise SystemExit(f"{routine_id}: expected_trigger.cron_utc day-of-week field {fields[4]!r} is "
                         f"not a comma-separated list of plain integers -- gen_241_region cannot "
                         f"derive its Denver day-set") from None
    if any(d < 0 or d > 6 for d in cron_dows):
        raise SystemExit(f"{routine_id}: expected_trigger.cron_utc day-of-week field {fields[4]!r} has "
                         f"a value outside 0-6 (cron Sunday=0..Saturday=6)")
    if hour == DENVER_UTC_OFFSET_HOURS_MDT:
        # 06:xx UTC is 00:xx MDT (same Denver day) but 23:xx MST (the PREVIOUS Denver day): no single
        # day-set is right all year, so refuse rather than silently encode the MDT answer.
        raise SystemExit(f"{routine_id}: expected_trigger.cron_utc {cron_utc!r} fires in the 06:xx UTC "
                         f"hour, which straddles Denver midnight across DST -- gen_241_region cannot "
                         f"derive one Denver day-set for it; move the slot out of that hour")
    same_day = hour >= DENVER_UTC_OFFSET_HOURS_MDT
    denver_cron_dows = cron_dows if same_day else [(d - 1) % 7 for d in cron_dows]
    return sorted({d + 1 for d in denver_cron_dows})


def gen_241_region(routines):
    """state.queue_driven_missed_fire_watch rows: the SAME queue_driven filter gen_132_region uses (so
    the two regions can never disagree about WHICH routines are queue-driven -- see build_targets()'s
    comment on the 241 target), plus each routine's Denver calendar day-set, DERIVED from
    expected_trigger.cron_utc via _cron_utc_to_denver_dow() rather than hand-copied. Today all five
    queue_driven owners spell Denver Sun-Thu, but through two different UTC cron shapes: M1R's 13:00
    UTC slot lands on the SAME Denver day (cron dow 0,1,2,3,4 needs no shift), while
    AR_att/AR_orc/SL2/SL5's 00:00-01:25 UTC slots land on the PREVIOUS Denver day (cron dow 1,2,3,4,5
    shifts back by one) -- see ops/cadence.yaml's M1R entry and check Q in
    scripts/check_cadence_consistency.py, which both narrate the identical split. Hardcoding
    [1,2,3,4,5] here would silently stop matching the day a 6th queue_driven owner's cron used a shape
    neither of those two already covers. cadence.yaml order, 4-space indent matching the surrounding
    UNNEST([ block."""
    rows = [r for r in routines if r.get("monitor_class") == "queue_driven"]
    lines = []
    for i, r in enumerate(rows):
        comma = "," if i < len(rows) - 1 else ""
        cron_utc = str((r.get("expected_trigger") or {}).get("cron_utc", ""))
        denver_dow = _cron_utc_to_denver_dow(r["id"], cron_utc)
        dow_literal = "[" + ",".join(str(d) for d in denver_dow) + "]"
        lines.append(f"    STRUCT('{r['id']}' AS routine, '{r['monitor_class']}' AS monitor_class, "
                     f"{dow_literal} AS denver_dow){comma}")
    return "\n".join(lines)


# ---- bigquery/280: the FULL canonical trigger instruction per fleet routine (2026-11-23) ----------
# state.instruction_drift's core-line check (bigquery/201) compares only the one-liner in
# ops.routine_catalog, so a change in the standing operator paragraphs (Spawn Sonnet / Do not give
# final response / SEARCH GUARD) was structurally invisible to it -- commit 6c01e91 added a sentence to
# every SEARCH GUARD in ops/routine_backup.json on 2026-11-16, the live triggers stayed un-rolled-out
# for a week, and the nightly check reported "0 drifted" throughout. bigquery/280 adds a full-text
# comparison; this region is its canonical side, generated from the same routine_backup.json
# `scripts/routine_backup.py check` validates and OPS0/Q4 step E diff the live triggers against.
ROUTINE_BACKUP_JSON = os.path.join(ROOT, "ops", "routine_backup.json")
TRIGGER_IDS_JSON = os.path.join(ROOT, "ops", "trigger_ids.json")
FULL_INSTRUCTION_SQL = os.path.join(ROOT, "bigquery", "280_instruction_drift_full_text.sql")

# The "this sample is a placeholder summary, not a transcription" pattern. It is written ONCE here and
# must appear VERBATIM (as the r'...' literal) in bigquery/280's state.instruction_drift body --
# tests/test_gen_routine_lists_full_text.py pins that lockstep, and gen_280_region() refuses a
# canonical instruction that would itself match it (a canonical that looks like a placeholder could
# never produce full-text evidence, silently disabling the check for that routine). The syntax used
# is the common subset of Python `re` and BigQuery RE2: case-insensitive flag group, character
# classes, alternation. Measured placeholder shapes it must catch (ops.run_log, 2026-11-16..18):
#   "SEARCH GUARD. [...Parallel search guard paragraph per trigger...]"
#   "[Parallel Search guard paragraph per stored trigger]"   "[Parallel Search guard paragraph]"
# while canonical text's own brackets ("[Routine paused]") must NOT match.
PLACEHOLDER_PATTERN = (r"(?i)\[\s*(\.\.\.|…)|\[[^\]]*(paragraph|guard|omitted|truncated|elided|"
                       r"abridged|redacted|snip|per trigger|per stored|verbatim)[^\]]*\]")
PLACEHOLDER_RE = re.compile(PLACEHOLDER_PATTERN)

FULL_ROW_RE = re.compile(
    r"STRUCT\('([^']+)' AS routine, r'''(.*?)''' AS canonical_full_instruction, "
    r"DATE '(\d{4}-\d{2}-\d{2})' AS canonical_full_since, "
    r"(?:r'''(.*?)'''|CAST\(NULL AS STRING\)) AS superseded_full_instruction\)", re.DOTALL)


def _load_json(path):
    # json.load preserves key order, which load_full_instructions() relies on (trigger_ids.json order).
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_full_instructions(backup_path=None, ids_path=None):
    """[(routine, full_instruction)] for every FLEET routine, in ops/trigger_ids.json order. The fleet
    is trigger_ids.json minus its `_meta` key; routine_backup.json additionally carries the operator's
    `personal_*` triggers, which are not fleet routines, never log to ops.run_log under a catalog id,
    and are deliberately left out. RAISES SystemExit (never guesses) when a fleet routine has no
    non-empty string instruction in routine_backup.json -- `routine_backup.py check` would flag the
    same tree, and an empty canonical here would make every sample a false full-text drift."""
    ids = _load_json(ids_path or TRIGGER_IDS_JSON)
    backup = _load_json(backup_path or ROUTINE_BACKUP_JSON)
    routines = (backup or {}).get("routines") or {}
    out = []
    for rid in ids:
        if rid == "_meta" or rid.startswith("personal_"):
            continue
        instr = (routines.get(rid) or {}).get("instruction")
        if not isinstance(instr, str) or not instr.strip():
            raise SystemExit(f"{rid}: ops/routine_backup.json has no instruction for this fleet routine "
                             f"-- gen_280_region cannot build its canonical full instruction")
        out.append((rid, instr))
    return out


def parse_full_since(path=None):
    """{routine: (canonical_full_instruction, canonical_full_since, superseded_full_instruction or None)}
    parsed back out of the CURRENT bigquery/280 generated region -- the same preserve-on-unchanged role
    parse_catalog_since() plays for bigquery/15. A missing file or region parses to {} (every routine
    then seeds to today with no superseded text)."""
    p = path or FULL_INSTRUCTION_SQL
    if not os.path.exists(p):
        return {}
    region = current_region(p) or ""
    # A NULL superseded text takes the CAST(NULL ...) branch, so findall yields "" for group 4.
    return {rid: (instr, since, sup or None)
            for rid, instr, since, sup in FULL_ROW_RE.findall(region)}


def _check_raw_literal_safe(rid, instr):
    """A raw triple-quoted GoogleSQL literal r'''...''' cannot carry its own delimiter, and a body
    ending in ' would fuse with the closing '''. Backslashes are refused too: raw makes them literal in
    BigQuery, but lib.sql_files' tokenizer (strip_sql_comments, verify_dbt_port, check_live_sql_parity)
    treats a backslash as an escape regardless of the r prefix, so one could desynchronise those
    parsers from BigQuery's. Refusing is cheap -- no fleet instruction contains any of these today."""
    if "'''" in instr:
        raise SystemExit(f"{rid}: instruction contains ''' -- cannot be emitted as a raw triple-quoted literal")
    if instr.endswith("'") or instr.startswith("'"):
        raise SystemExit(f"{rid}: instruction starts/ends with ' -- would fuse with the ''' delimiter")
    if "\\" in instr:
        raise SystemExit(f"{rid}: instruction contains a backslash -- refused (see _check_raw_literal_safe)")
    if "\r" in instr:
        raise SystemExit(f"{rid}: instruction contains a carriage return -- refused (newline-preserving round trip)")
    if PLACEHOLDER_RE.search(instr):
        raise SystemExit(f"{rid}: canonical instruction itself matches PLACEHOLDER_PATTERN -- no logged "
                         f"sample could ever count as full-text evidence; narrow the pattern or the text")


def _raw_or_null(text):
    return "CAST(NULL AS STRING)" if text is None else "r'''" + text + "'''"


def gen_280_region(full, prior=None, today=None, since_floor=None):
    """state.routine_canonical_full_instruction rows: one per fleet routine (load_full_instructions()
    order), 2-space indent matching the surrounding `SELECT * FROM UNNEST([` block.

    canonical_full_since has EXACTLY canonical_since's semantics (bigquery/183/201, gen_15_region): a
    logged sample whose run_date is on/before it cannot be evidence about the CURRENT canonical, so a
    mismatch on it is reported as unproven, never as drifted. Same STABILITY CONTRACT as gen_15_region:
    the date is PRESERVED verbatim while this routine's full instruction is unchanged versus the region
    already in the file, and re-stamped to `today` only when the text changes (or the routine is new),
    so --check on any later day regenerates a byte-identical region.

    `today` is the OPERATING-plane (America/Denver) date, as in gen_15_region and for the same reason:
    the view compares it against ops.run_log.run_date, which is keyed in that plane.

    SEED (2026-11-23): every routine starts at 2026-11-23, the day the owner rolled 6c01e91's SEARCH
    GUARD sentence out to the 33 live triggers (08:10-08:18Z). Pre-rollout FULL transcriptions are still
    some routines' latest samples (D2/D2a, 2026-11-22); without the seed they would raise a drift
    alert about triggers that are now correct -- the 2026-08-19 false-alarm class bigquery/183 fixed.

    superseded_full_instruction (adversarial review 2026-11-23): the canonical text this routine's
    CURRENT text replaced -- taken from the prior region when the text changes, PRESERVED while it is
    unchanged, NULL for a routine with no earlier version. A logged sample equal to it is PROOF the live
    trigger was never rolled out, whatever its length; the 0.85 length rule alone cannot see a stale
    trigger once the new canonical is more than ~15% longer (the 2026-11-14 SEARCH GUARD addition grew
    every canonical ~530 -> ~1936 chars). Only ONE version back is kept; a trigger two edits stale falls
    back to the length rule. SEED: the pre-6c01e91 text (6c01e91^:ops/routine_backup.json) for all 33.

    since_floor (`--write --full-since YYYY-MM-DD`): raise every canonical_full_since earlier than that
    date to it -- the supported way to record that the live rollout landed after the --write day (see
    the bigquery/280 header, LANDING). Never lowers a date; the preserve rule then keeps the raised date
    on every later --check."""
    prior = parse_full_since() if prior is None else prior
    today = today or datetime.datetime.now(OPERATING_TZ).date().isoformat()
    lines = []
    n = len(full)
    for i, (rid, instr) in enumerate(full):
        _check_raw_literal_safe(rid, instr)
        prior_instr, prior_since, prior_sup = (tuple(prior.get(rid, ())) + (None, None, None))[:3]
        if prior_since and prior_instr == instr:
            since, sup = prior_since, prior_sup
        elif prior_instr is not None:
            since, sup = today, prior_instr       # text changed: the old canonical becomes the superseded one
        else:
            since, sup = today, None              # new routine
        if since_floor and since < since_floor:
            since = since_floor
        if sup is not None:
            _check_raw_literal_safe(rid, sup)
        comma = "," if i < n - 1 else ""
        lines.append(f"  STRUCT('{rid}' AS routine, r'''{instr}''' AS canonical_full_instruction, "
                     f"DATE '{since}' AS canonical_full_since, "
                     f"{_raw_or_null(sup)} AS superseded_full_instruction){comma}")
    return "\n".join(lines)


class GenError(str):
    """A target body that could not be generated. build_targets() stores one in place of the 280 body
    when routine_backup.json holds an instruction gen_280_region refuses, so --check / --write still
    process the other eight regions and report the 280 failure on its own."""


# Printed whenever bigquery/280 is stale (--check) or rewritten (--write): the whole landing, in order.
# Step 3 BEFORE step 4 matters -- a trigger rolled out while the LIVE canonical view still carries the
# old text makes every new full transcription read as a mismatch against the old one.
FULL_LANDING_STEPS = (
    "  bigquery/280 landing, in order:\n"
    "    1. python scripts/gen_routine_lists.py --write\n"
    "    2. python scripts/gen_dbt_port.py state.routine_canonical_full_instruction  (then put back the\n"
    "       port's hand-kept Provenance lines)\n"
    "    3. after merge, apply bigquery/280 statement (1) live yourself -- do not wait for D3 self-heal\n"
    "    4. only then roll the changed instructions out to the live triggers\n"
    "    5. if the rollout landed on a later day than step 1, re-run step 1 with --full-since <rollout\n"
    "       date> and land + apply that too, so pre-rollout transcriptions are not raised as drift")


def build_targets(since_floor=None):
    routines = load_cadence_routines()
    head_by_id = load_headings_by_id()
    targets = [
        (CADENCE_MONITOR_SQL, gen_12_region(routines)),
        (ROUTINE_CATALOG_SQL, gen_15_region(routines, head_by_id)),
        (PERIOD_WATCH_SQL, gen_24_region(routines)),
        (ROUTINE_CATCHUP_SQL, gen_105_region(routines)),
        # bigquery/114 needs the IDENTICAL (routine, monitor_class) period-class rows as bigquery/24 --
        # ops.sp_assert_deps resolves a dependency's period window from the same mapping the period
        # watch view uses -- so it reuses gen_24_region verbatim rather than defining a near-duplicate
        # generator. The two regions are byte-identical by construction, which is the point: the gate
        # and the monitor can never disagree about which routines are period-cadence. 114 embeds the
        # list (instead of joining state.cadence_period_watch) because it is a FATAL, unwrapped gate
        # that must not gain a runtime view dependency -- see that file's header.
        (DEP_GATE_SQL, gen_24_region(routines)),
        # bigquery/132 takes the COMPLEMENT of bigquery/12's list: 12 carries every calendar-class
        # routine, 132 carries every queue_driven one. Between them the two regions partition the
        # roster, so a routine cannot be absent from both and end up watched by nothing -- which is
        # precisely the hole bigquery/132 was written to close (SL2/SL5, 2026-08-03).
        (QUEUE_SILENCE_SQL, gen_132_region(routines)),
        # bigquery/241 takes the SAME queue_driven set as bigquery/132 -- gen_241_region applies the
        # identical `monitor_class == "queue_driven"` filter gen_132_region uses (rather than deriving
        # its own), so the two regions can never disagree about WHICH routines are queue-driven. 241
        # additionally carries each routine's Denver calendar day-set (denver_dow), DERIVED from
        # expected_trigger.cron_utc rather than hand-copied -- the five owners spell "Denver Sun-Thu"
        # through two different UTC cron shapes (see gen_241_region's own docstring), so hardcoding the
        # day-set here would silently stop matching the day a 6th owner used a shape neither shape
        # already covers.
        (QUEUE_DRIVEN_MISSED_FIRE_SQL, gen_241_region(routines)),
    ]
    # bigquery/205 is the THIRD gen_24_region consumer, and the one that matters most at runtime: it
    # CREATE-OR-REPLACEs the SAME ops.sp_assert_deps procedure bigquery/114 declares (205's own section
    # header: "(1) ops.sp_assert_deps — canonical body from bigquery/114, message stabilised"), so
    # 205 -- being the highest-numbered definition in the apply-in-order record -- is the copy that is
    # LIVE, and 114's is the DR-rebuild copy.
    #
    # REGISTERED 2026-09-04 (quality pass). bigquery/205 shipped already carrying the BEGIN/END
    # GENERATED ROUTINE LIST markers, but the commit that added it never added it here, so --write
    # regenerated only the DR-only 114 copy and --check never validated 205 at all -- a marker
    # promising generator maintenance that did not exist. Consequence had a routine been added to or
    # reclassified in ops/cadence.yaml: 24 and 114 update, --check stays green, and the LIVE gate's
    # period_class CTE keeps the OLD mapping -- `LEFT JOIN period_class pc ON pc.routine = d` then
    # leaves period_start NULL for that routine, dropping it into sp_assert_deps' strict daily/queue
    # branch, where a weekly/monthly dep can only be satisfied by a completion on in_run_date itself.
    # That FATALLY blocks every dependent routine on most days, i.e. exactly the false-block
    # bigquery/114 was written to prevent (commit f5bbade). The region was already byte-identical to
    # gen_24_region's output when this was registered, so adding it changed no SQL file; a FUTURE
    # cadence change will now edit bigquery/205 too, which is intended -- and, like any canonical SQL
    # edit, owes a live re-apply before check_live_sql_parity.py's next run.
    #
    # PAIRED-PATH GUARD (the `if` below). On a real run ALERT_MSG_STABILITY_SQL and DEP_GATE_SQL are
    # both ROOT/bigquery, so the condition is ALWAYS true and 205 is ALWAYS a target -- this does not
    # weaken the gate. It exists for TEST FIXTURES: 114 and 205 are two copies of ONE procedure, so a
    # fixture that redirects the dependency gate at a tmp tree without redirecting this twin is
    # mis-wired, and an unguarded append would then let a --write reach PAST the fixture and overwrite
    # the real, frozen, live-parity-checked bigquery/205 with the fixture's one-row period_class list.
    # That cross-test clobber is not hypothetical: tests/test_cadence_consistency.py::_patch_gen_paths'
    # own comment records it biting three times, once per generated target added (105 on 2026-07-25,
    # 114 on 2026-07-28, 132 on 2026-08-03), each time because a fixture was not updated in lockstep.
    # Deriving the skip from DEP_GATE_SQL rather than trusting every fixture to be updated makes this
    # seventh target unable to become the fourth occurrence. A fixture that patches BOTH (see
    # tests/test_gen_routine_lists.py::_wire_fixture) keeps the target and exercises it normally.
    if os.path.dirname(ALERT_MSG_STABILITY_SQL) == os.path.dirname(DEP_GATE_SQL):
        targets.append((ALERT_MSG_STABILITY_SQL, gen_24_region(routines)))
    # bigquery/280 (9th target, 2026-11-23): the FULL canonical instruction per fleet routine, from
    # ops/routine_backup.json. Same PAIRED-PATH GUARD shape as 205 above, keyed on ROUTINE_CATALOG_SQL
    # (its sibling canonical, bigquery/15): on a real run both sit in ROOT/bigquery so the target is
    # ALWAYS present and --check ALWAYS validates it; a test fixture that redirects the catalog into
    # tmp_path without also redirecting FULL_INSTRUCTION_SQL skips it instead of letting a --write
    # reach past the fixture into the real, live-parity-checked bigquery/280 (the clobber
    # tests/test_cadence_consistency.py::_patch_gen_paths records biting three times). The JSON is
    # read only inside the guard, so such fixtures need no routine_backup.json of their own.
    if os.path.dirname(FULL_INSTRUCTION_SQL) == os.path.dirname(ROUTINE_CATALOG_SQL):
        try:
            body280 = gen_280_region(load_full_instructions(), since_floor=since_floor)
        except SystemExit as e:
            body280 = GenError(str(e))
        targets.append((FULL_INSTRUCTION_SQL, body280))
    return targets


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--write", action="store_true", help="regenerate every marker region in place")
    g.add_argument("--check", action="store_true", help="exit 1 + diff if any region is stale")
    ap.add_argument("--full-since", metavar="YYYY-MM-DD", default=None,
                    help="with --write only: raise every bigquery/280 canonical_full_since earlier than "
                         "this date to it (records the day the live trigger rollout landed)")
    args = ap.parse_args()
    if args.full_since is not None:
        if not args.write:
            ap.error("--full-since is only valid with --write")
        try:
            datetime.date.fromisoformat(args.full_since)
        except ValueError:
            ap.error(f"--full-since: not a YYYY-MM-DD date: {args.full_since!r}")

    targets = build_targets(since_floor=args.full_since)
    errors = [(p, b) for p, b in targets if isinstance(b, GenError)]
    targets = [(p, b) for p, b in targets if not isinstance(b, GenError)]
    for path, err in errors:
        print(f"{os.path.relpath(path, ROOT)}: CANNOT GENERATE -- {err} (every other region is still "
              f"processed)")

    if args.write:
        changed = []
        for path, body in targets:
            if write_region(path, body):
                changed.append(path)
        if changed:
            print(f"gen_routine_lists --write: regenerated "
                  f"{', '.join(os.path.relpath(p, ROOT) for p in changed)}.")
        else:
            print(f"gen_routine_lists --write: all {len(targets)} regions already current (no-op).")
        if FULL_INSTRUCTION_SQL in changed:
            print(FULL_LANDING_STEPS)
        return 1 if errors else 0

    # --check
    drift = False
    for path, body in targets:
        rel = os.path.relpath(path, ROOT)
        current = current_region(path)
        if current is None:
            print(f"{rel}: could not find BEGIN/END GENERATED ROUTINE LIST markers")
            drift = True
            continue
        want = wanted_region(body)
        if current != want:
            drift = True
            print(f"{rel}: GENERATED ROUTINE LIST region is STALE vs ops/cadence.yaml + "
                  f"Claude_Task_Plan.md + ops/routine_backup.json -- run "
                  f"`python scripts/gen_routine_lists.py --write`")
            if path == FULL_INSTRUCTION_SQL:
                print(FULL_LANDING_STEPS)
    if drift or errors:
        return 1
    print("gen_routine_lists --check: OK -- bigquery/12, 15, 24, 105, 114, 132, 205, 241, 280 generated "
          "regions match ops/cadence.yaml + Claude_Task_Plan.md + ops/routine_backup.json.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Guard the cadence single-source GATE's own parsers (stack review 2026-06-24, RUNBOOK §25 C2).

scripts/check_cadence_consistency.py scrapes routine→class and routine→instruction maps out of the
hand-formatted bigquery/12 + 15 SQL with regexes. If a benign SQL reformat makes a regex stop matching,
the check can pass VACUOUSLY for the changed side — exactly the §22-class drift the gate exists to catch.
These tests feed known-good and deliberately-drifted snippets and assert the parsers behave, so a regex
that rots is caught by CI instead of silently disarming the gate.

No warehouse, no creds — pure offline parser tests (run in the always-on `test` job).
"""
import yaml

from conftest import load_module_from_path

cc = load_module_from_path("check_cadence_consistency", "scripts", "check_cadence_consistency.py")


def test_routine_suffix_dead_reexport_removed():
    # The unused ROUTINE_SUFFIX re-export was removed (2026-07-17): heading parsing is delegated
    # entirely to lib.routine_manifest, nothing in this module references the name, and no other
    # module imports it from here. Guards against a future re-introduction of the dead binding.
    assert not hasattr(cc, "ROUTINE_SUFFIX")
    assert not hasattr(cc, "_ROUTINE_SUFFIX")


# ---- heading_to_id: the id-extraction rule the catalog + expected maps key on ----
def test_heading_to_id_handles_all_id_shapes():
    assert cc.heading_to_id("D1. Market Development Scan — deep research") == "D1"
    assert cc.heading_to_id("M1a. Strategy-Blind Regime Scoring — deep research") == "M1a"
    assert cc.heading_to_id("Adversarial Review Attacker — regular routine") == "AR_att"
    assert cc.heading_to_id("Adversarial Review Orchestrator — regular routine") == "AR_orc"
    assert cc.heading_to_id("no leading id here") is None


# ---- parse_expected_sql: the STRUCT(... AS routine, ... AS schedule) scraper ----
def test_parse_expected_sql_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "12.sql"
    f.write_text(
        "STRUCT('D1'  AS routine, 'daily_trading' AS schedule),\n"
        "STRUCT('W1'  AS routine, 'weekly_sun'    AS schedule)\n"
    )
    monkeypatch.setattr(cc, "CADENCE_SQL", str(f))
    assert cc.parse_expected_sql() == {"D1": "daily_trading", "W1": "weekly_sun"}


def test_parse_expected_sql_empty_on_reformat_is_caught(tmp_path, monkeypatch):
    # A reformat that breaks the regex (double quotes / renamed label) must yield {} — main() then flags
    # "could not parse any STRUCT(... AS schedule) rows", NOT a vacuous pass.
    f = tmp_path / "12.sql"
    f.write_text('STRUCT("D1" AS routine, "daily_trading" AS schedule_class)\n')
    monkeypatch.setattr(cc, "CADENCE_SQL", str(f))
    assert cc.parse_expected_sql() == {}


# ---- parse_catalog_sql: the optional-`AS routine` group the verifier flagged as the real risk ----
def test_parse_catalog_sql_handles_first_labelled_and_shorthand_rows(tmp_path, monkeypatch):
    f = tmp_path / "15.sql"
    f.write_text(
        "STRUCT('D1'  AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — deep research.' AS canonical_instruction),\n"
        "STRUCT('D2',  'Read Claude_Task_Plan.md. Perform D2. Daily Action Conversion — regular routine.'),\n"
    )
    monkeypatch.setattr(cc, "CATALOG_SQL", str(f))
    got = cc.parse_catalog_sql()
    assert got["D1"].startswith("Read Claude_Task_Plan.md. Perform D1.")
    assert got["D2"] == "Read Claude_Task_Plan.md. Perform D2. Daily Action Conversion — regular routine."


def test_parse_catalog_sql_empty_on_reformat_is_caught(tmp_path, monkeypatch):
    f = tmp_path / "15.sql"
    f.write_text("STRUCT('D1' AS routine, \"Read Claude_Task_Plan.md. Perform D1.\")\n")  # double-quoted instr
    monkeypatch.setattr(cc, "CATALOG_SQL", str(f))
    assert cc.parse_catalog_sql() == {}


def test_parse_catalog_sql_unescapes_doubled_single_quotes(tmp_path, monkeypatch):
    # gen_routine_lists.py gen_15_region escapes ' -> '' for the single-quoted SQL literal when a
    # routine heading contains an apostrophe; parse_catalog_sql must un-escape '' -> ' so the parsed
    # instruction matches want_catalog's raw heading text. Paired half of the coordinated apostrophe
    # support (mirror of gen_15_region's escaping). Two apostrophes in one instruction to be thorough.
    f = tmp_path / "15.sql"
    f.write_text(
        "STRUCT('D9' AS routine, 'Read Claude_Task_Plan.md. Perform D9. "
        "O''Brien''s Screen — regular routine.' AS canonical_instruction),\n"
    )
    monkeypatch.setattr(cc, "CATALOG_SQL", str(f))
    assert cc.parse_catalog_sql()["D9"] == \
        "Read Claude_Task_Plan.md. Perform D9. O'Brien's Screen — regular routine."


# ---- parse_deadline_sql: the cadence_watch deadline-guard TIME literal (check D) ----
def test_parse_deadline_sql_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "12.sql"
    f.write_text(
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')\n"
        "  ) AS needs_attention,\n"
    )
    monkeypatch.setattr(cc, "CADENCE_SQL", str(f))
    assert cc.parse_deadline_sql() == ["21:00"]


def test_parse_deadline_sql_empty_on_reformat_is_caught(tmp_path, monkeypatch):
    # If the guard clause is reshaped so the regex stops matching, the parser must yield [] —
    # main() then flags "could not parse ... deadline-guard literal", NOT a vacuous pass.
    f = tmp_path / "12.sql"
    f.write_text("   AND DATETIME(e.today, MAKE_TIME(21,0,0)) <= CURRENT_DATETIME('America/Denver')\n")
    monkeypatch.setattr(cc, "CADENCE_SQL", str(f))
    assert cc.parse_deadline_sql() == []


def test_cadence_deadline_yaml_reads_quoted_hhmm(tmp_path, monkeypatch):
    f = tmp_path / "cadence.yaml"
    f.write_text('timezone: America/Denver\ncadence_watch_deadline_local: "21:00"\nroutines: []\n')
    monkeypatch.setattr(cc, "CADENCE", str(f))
    assert cc.cadence_deadline_yaml() == "21:00"


def test_cadence_deadline_yaml_unquoted_is_not_a_string(tmp_path, monkeypatch):
    # An UNquoted 21:00 is YAML 1.1 base-60 (= 1260, an int) — main()'s HHMM/str check rejects it.
    f = tmp_path / "cadence.yaml"
    f.write_text("cadence_watch_deadline_local: 21:00\nroutines: []\n")
    monkeypatch.setattr(cc, "CADENCE", str(f))
    val = cc.cadence_deadline_yaml()
    assert not (isinstance(val, str) and cc.HHMM.match(val))


# ---- E. parse_period_grace_sql / cadence_period_grace_yaml: the period-miss grace-day scrapers ----
def test_parse_period_grace_sql_matches_known_good(tmp_path, monkeypatch):
    # Mirrors the real shape in bigquery/24_cadence_period_watch.sql (comments/whitespace trimmed).
    f = tmp_path / "24.sql"
    f.write_text(
        "    (SELECT cal_date FROM `p.d.market_calendar`\n"
        "       WHERE is_trading_day AND DATE_TRUNC(cal_date, MONTH) = p.month_start\n"
        "       ORDER BY cal_date LIMIT 1 OFFSET 2) AS month_grace_day,\n"
        "    (SELECT cal_date FROM `p.d.market_calendar`\n"
        "       WHERE is_trading_day AND DATE_TRUNC(cal_date, QUARTER) = p.quarter_start\n"
        "       ORDER BY cal_date LIMIT 1 OFFSET 2) AS quarter_grace_day,\n"
        "    (SELECT cal_date FROM `p.d.market_calendar`\n"
        "       WHERE is_trading_day AND DATE_TRUNC(cal_date, YEAR) = p.year_start\n"
        "       ORDER BY cal_date LIMIT 1 OFFSET 4) AS year_grace_day\n"
        "      WHEN 'weekly_sun'    THEN DATETIME(DATE_ADD(n.week_start, INTERVAL 1 DAY), TIME '21:00:00')\n"
    )
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(f))
    assert cc.parse_period_grace_sql() == {
        "monthly_ftd": 3, "quarterly_ftd": 3, "annual_ftd": 5, "weekly_sun": 1,
    }


def test_parse_period_grace_sql_empty_on_reformat_is_caught(tmp_path, monkeypatch):
    # A reformat that breaks the OFFSET/label regex (extra space before the closing paren, and a
    # renamed alias) must yield {} for the broken rows, NOT silently keep matching — main()'s check E
    # then flags a per-class parse failure instead of vacuously passing.
    f = tmp_path / "24.sql"
    f.write_text(
        "       ORDER BY cal_date LIMIT 1 OFFSET 2 ) AS month_graceday,\n"
        "      WHEN 'weekly_sun'    THEN DATETIME(DATE_ADD(n.week_start, INTERVAL 1, DAY), TIME '21:00:00')\n"
    )
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(f))
    assert cc.parse_period_grace_sql() == {}


def test_parse_period_grace_sql_returns_none_when_file_absent(tmp_path, monkeypatch):
    # Pre-2026-07-03 checkouts don't have bigquery/24_cadence_period_watch.sql yet — main() must skip
    # check E silently (None), not treat a missing file as "zero grace values configured" (which would
    # be indistinguishable from a broken regex — see the reformat test above).
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(tmp_path / "does_not_exist.sql"))
    assert cc.parse_period_grace_sql() is None


def test_cadence_period_grace_yaml_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "cadence.yaml"
    f.write_text(
        "timezone: America/Denver\n"
        "period_grace_days:\n"
        "  weekly_sun: 1\n"
        "  monthly_ftd: 3\n"
        "  quarterly_ftd: 3\n"
        "  annual_ftd: 5\n"
        "routines: []\n"
    )
    monkeypatch.setattr(cc, "CADENCE", str(f))
    assert cc.cadence_period_grace_yaml() == {
        "weekly_sun": 1, "monthly_ftd": 3, "quarterly_ftd": 3, "annual_ftd": 5,
    }


def test_cadence_period_grace_yaml_missing_key_is_none(tmp_path, monkeypatch):
    f = tmp_path / "cadence.yaml"
    f.write_text("timezone: America/Denver\nroutines: []\n")
    monkeypatch.setattr(cc, "CADENCE", str(f))
    assert cc.cadence_period_grace_yaml() is None


# ---- F. generate_triggers_manifest: the ops/triggers.json canonical-map generator -------------------
def test_generate_triggers_manifest_matches_known_good_shape():
    head_by_id = {
        "D1": "D1. Market Development Scan — deep research",
        "W1": "W1. Catalyst Calendar (A, C) — deep research",
    }
    cad = {
        "D1": {"monitor_class": "daily_trading"},
        "W1": {"monitor_class": "weekly_sun"},
    }
    assert cc.generate_triggers_manifest(head_by_id, cad) == {
        "D1": {"monitor_class": "daily_trading",
               "instruction": "Read Claude_Task_Plan.md. Perform D1. Market Development Scan — deep research."},
        "W1": {"monitor_class": "weekly_sun",
               "instruction": "Read Claude_Task_Plan.md. Perform W1. Catalyst Calendar (A, C) — deep research."},
    }


def test_generate_triggers_manifest_excludes_ids_not_in_cadence():
    # A plan heading whose id has no (or no longer has a) matching ops/cadence.yaml routine must NOT
    # silently appear in the generated manifest — regression guard for the "if rid in cad" filter that
    # keeps ops/triggers.json from ever citing a routine cadence.yaml doesn't know about.
    head_by_id = {"D1": "D1. Market Development Scan — deep research",
                  "ZZ": "ZZ. Ghost Routine — deep research"}
    cad = {"D1": {"monitor_class": "daily_trading"}}
    got = cc.generate_triggers_manifest(head_by_id, cad)
    assert set(got) == {"D1"}
    assert got["D1"]["monitor_class"] == "daily_trading"


# ---- check_depends_on: dangling/typo'd depends_on references must be caught, not pass vacuously ----
def test_check_depends_on_flags_dangling_reference():
    cad = {"D1": {"depends_on": []}, "D2": {"depends_on": ["D1", "GHOST"]}}
    errs = cc.check_depends_on(cad)
    assert len(errs) == 1
    assert "D2" in errs[0] and "GHOST" in errs[0]


def test_check_depends_on_clean_chain_is_silent():
    cad = {"D1": {"depends_on": []}, "D2": {"depends_on": ["D1"]}, "D3": {}}
    assert cc.check_depends_on(cad) == []


def test_check_depends_on_against_real_cadence_yaml_is_clean():
    # The real ops/cadence.yaml's actual depends_on chains must all resolve cleanly today.
    assert cc.check_depends_on(cc.load_cadence()) == []


# ---- main() end-to-end fixture: a minimal, self-contained repo copy that reaches checks F/G/H
#      cleanly (2026-07-14 audit finding — check F previously had zero end-to-end coverage of
#      main()'s actual fail path; only the pure generate_triggers_manifest() helper was tested) ----
def _write_check_fixture(tmp_path):
    plan = tmp_path / "Claude_Task_Plan.md"
    # Includes a minimal but valid ROUTINE INVENTORY table (check L) so the many callers below that
    # exercise a DIFFERENT check via this shared fixture aren't incidentally tripped by check L's
    # 2026-07-29 hard-error-on-missing-table change; tests that want to exercise check L itself either
    # overwrite plan.write_text() with their own table (see the check-L section further down) or use
    # _write_ar_att_fixture's dedicated fixture. Also carries a valid SAME-DAY DOUBLE-RUN GUARD copy
    # for every EVENING_DAILY_GUARD_IDS routine (check M), for the same reason: check M's "sentinel
    # absent -> skip silently" gate was removed (2026-08-08 audit finding — see check_cadence_
    # consistency.py), so a plan carrying none of this text now fails check M loudly, and every caller
    # of this shared fixture below that isn't testing check M itself needs a clean copy so it isn't
    # incidentally tripped by an unrelated check (uses _guard_line, defined further down for the
    # check-M section itself — forward reference is fine, this is only ever called from a test body).
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
        "\n---\n\n"
        "Shared Observability guard SAME-DAY DOUBLE-RUN GUARD (CYCLE-AWARE VARIANT):\n"
        + _guard_line("D1") + _guard_line("D2") + _guard_line("D2a")
        + _guard_line("D3") + _guard_line("SL3")
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    cadence_sql = tmp_path / "12.sql"
    cadence_sql.write_text(
        "STRUCT('D1'  AS routine, 'daily_trading' AS schedule)\n"
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')\n"
    )
    catalog_sql = tmp_path / "15.sql"
    catalog_sql.write_text(
        "STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — deep research.' AS canonical_instruction)\n"
    )
    return plan, cadence, cadence_sql, catalog_sql


def _cadence_ids_from_yaml(cadence_path):
    """Routine ids read directly out of a fixture cadence.yaml file (NOT via cc.load_cadence(), which
    requires cc.CADENCE to already be monkeypatched to this exact path -- this helper is called from
    _patch_fixture_paths() itself while that patching is still happening, so it must not depend on
    it)."""
    doc = yaml.safe_load(open(cadence_path, encoding="utf-8")) or {}
    return [r["id"] for r in (doc.get("routines") or [])]


def _write_stalled_runs_fixture(tmp_path, ids, filename="900_test_stalled_runs.sql"):
    """Writes a canonical-shaped `CREATE OR REPLACE VIEW ...state.stalled_runs` definition into
    tmp_path/filename, with a `cls` CTE UNNEST([...]) STRUCT list carrying exactly `ids` -- the first
    entry labelled (`... AS routine, ... AS min_stale_hours`) and every later one positional, matching
    the real bigquery/148 body's own mixed spelling (check O's CLS_ENTRY_RE must handle both). The
    chosen leading number (900) and filename never collide with any other fixture file this test module
    writes into tmp_path elsewhere -- none of those use the `NN_description.sql` two-part naming
    numbered_sql_files() requires (they are all bare `NN.sql`, e.g. "12.sql"/"59.sql"), so reusing
    tmp_path itself as STALLED_RUNS_BIGQUERY_DIR (see _patch_fixture_paths) is safe. Returns the
    written Path."""
    structs = [
        (f"STRUCT('{rid}' AS routine, 6 AS min_stale_hours)" if i == 0 else f"STRUCT('{rid}', 6)")
        for i, rid in enumerate(ids)
    ]
    f = tmp_path / filename
    f.write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS\n"
        "WITH cls AS (\n"
        "  SELECT * FROM UNNEST([\n"
        "    " + ", ".join(structs) + "\n"
        "  ])\n"
        "),\n"
        "started AS (SELECT 1 AS routine)\n"
        "SELECT * FROM started;\n"
    )
    return f


def _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql):
    monkeypatch.setattr(cc, "PLAN", str(plan))
    monkeypatch.setattr(cc, "CADENCE", str(cadence))
    monkeypatch.setattr(cc, "CADENCE_SQL", str(cadence_sql))
    monkeypatch.setattr(cc, "CATALOG_SQL", str(catalog_sql))
    # check O: point STALLED_RUNS_BIGQUERY_DIR (a constant kept SEPARATE from BIGQUERY_DIR -- see its
    # own comment in check_cadence_consistency.py) at this SAME tmp_path fixture directory, and drop in
    # a canonical state.stalled_runs definition whose `cls` CTE lists EXACTLY the routine ids currently
    # in `cadence` -- so check O stays silently clean by default for every OTHER check's fixture below,
    # the same way check D-extended's real-repo coincidence keeps cadence_watch_deadline_local clean
    # today (that check is deliberately left UNPATCHED here, still scanning the real bigquery/
    # directory -- see STALLED_RUNS_BIGQUERY_DIR's own comment for why). Tests that want to exercise
    # check O itself overwrite this fixture file (_write_stalled_runs_fixture) or cadence.yaml's
    # routine set afterwards.
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(tmp_path))
    _write_stalled_runs_fixture(tmp_path, _cadence_ids_from_yaml(cadence))
    # check N's mirror scan is now resolved at call time (the model_mirror_files()
    # call-time-resolution fix) from CADENCE/OWNER_ACTIONS/PLAN/CATALOG_SQL -- without patching
    # OWNER_ACTIONS too, a fixture test would silently scan the REAL repo's OWNER_ACTIONS.md instead
    # of a fixture file. Default it to an absent path (skipped silently, same convention as the other
    # "pre-feature checkout" paths below); tests that want to exercise check N's mirror-scan logic
    # point this at a real fixture file themselves.
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(tmp_path / "absent_owner_actions.md"))
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(tmp_path / "absent.sql"))
    monkeypatch.setattr(cc, "TRIGGERS_JSON", str(tmp_path / "absent_triggers.json"))
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(tmp_path / "absent_trigger_ids.json"))
    monkeypatch.setattr(cc, "AUTO_MERGE_YML", str(tmp_path / "absent_auto_merge.yml"))
    # checks J/K's dependent files are absent in this minimal fixture (same "skip silently"
    # convention as PERIOD_WATCH_SQL above for check E/J). Check L is NOT in this "skip silently"
    # group -- since 2026-07-29 a missing/unparseable ROUTINE INVENTORY table is a hard error, so
    # _write_check_fixture's plan carries a minimal-but-valid table by default instead.
    monkeypatch.setattr(cc, "CATCHUP_NOTIFY_SQL", str(tmp_path / "absent_31.sql"))
    monkeypatch.setattr(cc, "CATCHUP_AUTOFIRE_SQL", str(tmp_path / "absent_59.sql"))
    # check M's membership cross-check (evening_slot_guard_membership_errors) compares
    # EVENING_DAILY_GUARD_IDS/NOON_CLAUSE_EXEMPT_EVENING_IDS -- the REAL 11-routine evening-slot
    # cohort -- against THIS fixture's `cad`, which normally carries only D1 with no expected_trigger
    # at all. Left unpatched, every one of this shared fixture's ~40 callers (which exercise checks
    # A/B/C/G/H/J/K/L/N/O, not this new membership check) would get a spurious STALE error for the 10
    # real ids the minimal cad never declares. Isolate it here the same way
    # tests/test_check_cron_dst_safety.py's write_cadence() isolates the analogous
    # daily_sun_thu_coverage_errors() from its own minimal fixtures (there via resetting the two id
    # sets to empty) -- here via a no-op override of the check function itself, because
    # EVENING_DAILY_GUARD_IDS is ALSO what check M's own per-id loop iterates (built into
    # GUARD_QUERY_RE at import time), so resetting that tuple itself would silently disarm check M's
    # unrelated, already-passing per-id loop for every one of these ~40 callers too. Tests that want to
    # exercise the membership check itself call cc.evening_slot_guard_membership_errors(cad) directly
    # (with cc.EVENING_DAILY_GUARD_IDS / cc.NOON_CLAUSE_EXEMPT_EVENING_IDS monkeypatched to small
    # synthetic sets and a matching synthetic cad) rather than going through this shared fixture --
    # see the "check M membership cross-check" tests below.
    monkeypatch.setattr(cc, "evening_slot_guard_membership_errors", lambda cad: [])


def test_stale_triggers_json_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    triggers = tmp_path / "triggers.json"
    triggers.write_text('{"D1": {"monitor_class": "WRONG", "instruction": "WRONG"}}')
    monkeypatch.setattr(cc, "TRIGGERS_JSON", str(triggers))
    assert cc.main() == 1
    assert "ops/triggers.json is STALE" in capsys.readouterr().out


def test_malformed_triggers_json_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    triggers = tmp_path / "triggers.json"
    triggers.write_text("{not valid json")
    monkeypatch.setattr(cc, "TRIGGERS_JSON", str(triggers))
    assert cc.main() == 1
    assert "could not parse as JSON" in capsys.readouterr().out


# ---- checks A/B: main()-level drift injection for the script's two founding checks (the parsers
#      are unit-tested above; this drives main()'s actual comparison branches end to end) ----
def test_check_a_schedule_class_mismatch_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence_sql.write_text(
        "STRUCT('D1'  AS routine, 'daily_all' AS schedule)\n"  # cadence.yaml says daily_trading
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')\n"
    )
    assert cc.main() == 1
    assert "schedule class mismatch" in capsys.readouterr().out


def test_check_b_instruction_drift_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    catalog_sql.write_text(
        "STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1. Wrong instruction text.' "
        "AS canonical_instruction)\n"
    )
    assert cc.main() == 1
    assert "routine_catalog instruction drift" in capsys.readouterr().out


def test_check_b_follows_the_shared_instruction_text_template(tmp_path, monkeypatch, capsys):
    # Coupling test for the 2026-07-20 extraction (codebase audit 2026-07-26): check B's want_catalog
    # must be COMPUTED by calling lib.routine_manifest.instruction_text, not by re-literalizing its
    # f-string. Reproduce the exact failure mode an auditor hit: vary instruction_text's template (here,
    # append an " (URGENT)" suffix -- kept inside parse_catalog_sql's "Perform ..." prefix match so the
    # SQL-scraper regex, a separate concern, still parses it) and regenerate 15_routine_catalog.sql to
    # match the NEW template (as gen_routine_lists.py --write would, since it also calls the shared
    # helper). If check B still had its own hardcoded "Perform {h}." f-string blind to this patch, it
    # would report a false instruction-drift error for D1 even though catalog and template agree -- the
    # diff would misdirect a maintainer toward cadence.yaml/plan headings instead of the real culprit.
    # With the dedup in place this must be clean.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)

    def patched_instruction_text(heading):
        return f"Read Claude_Task_Plan.md. Perform {heading} (URGENT)."
    monkeypatch.setattr(cc, "instruction_text", patched_instruction_text)

    catalog_sql.write_text(
        "STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — "
        "deep research (URGENT).' AS canonical_instruction)\n"
    )
    assert cc.main() == 0
    assert "routine_catalog instruction drift" not in capsys.readouterr().out


def test_check_b_hardcoded_literal_would_be_caught_by_the_coupling_test(tmp_path, monkeypatch, capsys):
    # Sanity check that the coupling test above actually HAS teeth: if want_catalog were still the old
    # hardcoded f-string (blind to the patched instruction_text), the SAME patched-template fixture
    # would report a drift -- proving the previous test only passes because check B genuinely delegates
    # to instruction_text now, not because the assertion is vacuous.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    catalog_sql.write_text(
        "STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — "
        "deep research (URGENT).' AS canonical_instruction)\n"
    )
    # do NOT monkeypatch cc.instruction_text here -- this reproduces main() computing want_catalog
    # with the OLD, un-patched (hardcoded-equivalent) template against the NEW catalog content.
    assert cc.main() == 1
    assert "routine_catalog instruction drift" in capsys.readouterr().out


# ---- check G: ops/trigger_ids.json duplicate/stale/missing-entry handling ----
def test_trigger_ids_duplicate_trigger_id_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    ids = tmp_path / "trigger_ids.json"
    ids.write_text('{"D1": {"trigger_id": "trig_SAME", "verified_via": "api"}, '
                   '"ZZ_NOT_IN_CADENCE": {"trigger_id": "trig_SAME", "verified_via": "api"}}')
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(ids))
    out = cc.main()
    text = capsys.readouterr().out
    assert out == 1
    assert "trig_SAME" in text and "shared by routines" in text


def test_trigger_ids_stale_entry_for_removed_routine_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    ids = tmp_path / "trigger_ids.json"
    ids.write_text('{"D1": {"trigger_id": "trig_A", "verified_via": "api"}, '
                   '"ZZ_GONE": {"trigger_id": "trig_B", "verified_via": "api"}}')
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(ids))
    assert cc.main() == 1
    assert "ZZ_GONE" in capsys.readouterr().out


def test_trigger_ids_missing_entry_for_new_routine_is_warn_only(tmp_path, monkeypatch, capsys):
    # A cad routine with no trigger_ids.json entry yet is expected/transient — must NOT fail the
    # build, only print an informational NOTE.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    ids = tmp_path / "trigger_ids.json"
    ids.write_text('{"_meta": {}}')
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(ids))
    assert cc.main() == 0
    assert "D1" in capsys.readouterr().out


# ---- check H: auto-merge-claude.yml's routine_re must accept every cadence.yaml id ----
# NOTE on isolation: _patch_fixture_paths does NOT touch AUTO_MERGE_DECISION_SH, so by default it
# still points at the REAL scripts/auto_merge_decision.sh, which is always complete (contains every
# live routine id). Check H validates EVERY allowlist copy found, not first-match-wins, so a broken
# AUTO_MERGE_YML fixture still produces its own error regardless of what AUTO_MERGE_DECISION_SH says
# -- the "missing" test below already passes for the right reason (if check H ever stopped reading
# AUTO_MERGE_YML at all, this fixture's missing D1 would no longer surface and main() would flip from
# 1 to 0, failing the assertion). The "clean"/main()==0 test is the one that was vacuous: with
# AUTO_MERGE_DECISION_SH left un-isolated, the real script's completeness alone is enough to make
# main() return 0 even if check H stopped reading AUTO_MERGE_YML entirely, so it must also patch
# AUTO_MERGE_DECISION_SH to an absent path to actually isolate AUTO_MERGE_YML.
def test_auto_merge_routine_re_missing_a_cadence_id_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    auto_merge = tmp_path / "auto-merge.yml"
    auto_merge.write_text("routine_re='^(D2|D3)$'\n")
    monkeypatch.setattr(cc, "AUTO_MERGE_YML", str(auto_merge))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "routine_re" in out


def test_auto_merge_routine_re_accepting_the_cadence_id_is_clean(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # Isolate AUTO_MERGE_YML: without also pointing AUTO_MERGE_DECISION_SH at an absent path, the
    # real (always-complete) scripts/auto_merge_decision.sh would still be read and would contribute
    # zero errors regardless of what this fixture's AUTO_MERGE_YML says, making the main()==0
    # assertion pass even if check H stopped reading AUTO_MERGE_YML altogether.
    monkeypatch.setattr(cc, "AUTO_MERGE_DECISION_SH", str(tmp_path / "absent_auto_merge_decision.sh"))
    auto_merge = tmp_path / "auto-merge.yml"
    auto_merge.write_text("routine_re='^(D1|D2|D3)$'\n")
    monkeypatch.setattr(cc, "AUTO_MERGE_YML", str(auto_merge))
    assert cc.main() == 0


def test_auto_merge_routine_re_missing_a_cadence_id_is_caught_via_decision_sh(tmp_path, monkeypatch, capsys):
    # Symmetric coverage for the OTHER allowlist location: scripts/auto_merge_decision.sh (the
    # sourced helper the literal moved into on 2026-07-29). Isolate AUTO_MERGE_DECISION_SH the same
    # way the tests above isolate AUTO_MERGE_YML -- _patch_fixture_paths already points AUTO_MERGE_YML
    # at an absent path by default, so only this fixture's incomplete .sh is read.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    decision_sh = tmp_path / "auto_merge_decision.sh"
    decision_sh.write_text("routine_re='^(D2|D3)$'\n")
    monkeypatch.setattr(cc, "AUTO_MERGE_DECISION_SH", str(decision_sh))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "routine_re" in out


def test_auto_merge_routine_re_both_locations_missing_is_caught(tmp_path, monkeypatch, capsys):
    # REGRESSION (2026-08-08): `if allowlist_paths:` had no `else` -- when NEITHER
    # scripts/auto_merge_decision.sh nor .github/workflows/auto-merge-claude.yml can be found, check H
    # used to quietly do nothing (zero errors), same silent-no-op shape check M's substring gate had.
    # _patch_fixture_paths already points AUTO_MERGE_YML at an absent path by default; isolate
    # AUTO_MERGE_DECISION_SH the same way (mirrors the isolation the "clean" test above needs) so this
    # fixture has neither location.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    monkeypatch.setattr(cc, "AUTO_MERGE_DECISION_SH", str(tmp_path / "absent_auto_merge_decision.sh"))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "could not find the RUNBOOK §38 marker-write routine allowlist source" in out
    assert "check H validated nothing" in out


# ---- check J: parse_period_watch_routines_sql — bigquery/24's post-normalization labelled rows ----
def test_parse_period_watch_routines_sql_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "24.sql"
    f.write_text(
        "    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class),\n"
        "    STRUCT('M1a' AS routine, 'monthly_ftd' AS monitor_class)\n"
    )
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(f))
    assert cc.parse_period_watch_routines_sql() == {"W1": "weekly_sun", "M1a": "monthly_ftd"}


def test_parse_period_watch_routines_sql_empty_on_reformat_is_caught(tmp_path, monkeypatch):
    # Pre-normalization shorthand (no `AS monitor_class` label on every row) must yield {} — main()
    # then flags "could not parse ... STRUCT(... AS monitor_class) rows", not a vacuous pass.
    f = tmp_path / "24.sql"
    f.write_text("STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class), STRUCT('W2','weekly_sun')\n")
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(f))
    assert cc.parse_period_watch_routines_sql() == {"W1": "weekly_sun"}


def test_parse_period_watch_routines_sql_returns_none_when_file_absent(tmp_path, monkeypatch):
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(tmp_path / "does_not_exist.sql"))
    assert cc.parse_period_watch_routines_sql() is None


# ---- check K: parse_unnest_routine_ids — 31/59's comment-stripped UNNEST([...]) AS routine list ----
def test_parse_unnest_routine_ids_strips_comments_59_shaped_fixture(tmp_path, monkeypatch):
    f = tmp_path / "59.sql"
    f.write_text(
        "CREATE OR REPLACE VIEW `p.d.period_catchup_available` AS\n"
        "WITH catchup_safe_period_routines AS (\n"
        "  SELECT routine FROM UNNEST([\n"
        "    'W1', 'W2', 'W3', 'W5',                    -- weekly research/consolidation (W4 excluded)\n"
        "    'M1a', 'M1b', 'M2', 'M3', 'M5',             -- monthly research/consolidation\n"
        "    'Q1', 'Q2', 'Q3', 'SL1',                    -- quarterly research/consolidation\n"
        "    'A1', 'A2'                                  -- annual research\n"
        "    -- SL4 (monthly) deliberately excluded: a discretionary-retirement PROPOSAL is capital-\n"
        "    -- adjacent enough to warrant the existing human-visible alert only.\n"
        "  ]) AS routine\n"
        ")\n"
        "SELECT w.routine FROM `p.d.cadence_period_watch` w JOIN catchup_safe_period_routines s USING (routine);\n"
    )
    monkeypatch.setattr(cc, "CATCHUP_AUTOFIRE_SQL", str(f))
    got = cc.parse_unnest_routine_ids(cc.CATCHUP_AUTOFIRE_SQL)
    # 'SL4' only ever appears inside a `--` comment here — comment-stripping must exclude it.
    assert got == ["W1", "W2", "W3", "W5", "M1a", "M1b", "M2", "M3", "M5", "Q1", "Q2", "Q3", "SL1", "A1", "A2"]
    assert "SL4" not in got


def test_parse_unnest_routine_ids_returns_none_when_file_absent(tmp_path, monkeypatch):
    monkeypatch.setattr(cc, "CATCHUP_NOTIFY_SQL", str(tmp_path / "does_not_exist.sql"))
    assert cc.parse_unnest_routine_ids(cc.CATCHUP_NOTIFY_SQL) is None


def test_parse_unnest_routine_ids_returns_none_when_bracket_missing(tmp_path, monkeypatch):
    f = tmp_path / "31.sql"
    f.write_text("SELECT routine FROM some_other_table\n")
    assert cc.parse_unnest_routine_ids(str(f)) is None


def test_check_k_removing_w5_from_59_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # give the fixture cadence.yaml a catchup_safe-true period routine (W5) so 59's list is checked
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
        "  - id: W5\n"
        "    monitor_class: weekly_sun\n"
        "    catchup_safe: true\n"
    )
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## W5. Factbase & Analytics Consolidation — regular routine\nbody\n"
    )
    autofire = tmp_path / "59.sql"
    autofire.write_text("SELECT routine FROM UNNEST(['W1']) AS routine\n")  # W5 missing
    monkeypatch.setattr(cc, "CATCHUP_AUTOFIRE_SQL", str(autofire))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "59_catchup_autofire.sql" in out and "DRIFT" in out


def test_check_k_present_but_unparseable_59_fails_loud_not_silent(tmp_path, monkeypatch, capsys):
    # 2026-07-17 audit: parse_unnest_routine_ids returns None for BOTH "file absent" and "bracket
    # unparseable". main() must FAIL (not silently skip) when the file EXISTS but its UNNEST bracket
    # no longer matches — otherwise a valid SQL reformat (`AS  routine`, `UNNEST(ARRAY[...]`) silently
    # disarms the only drift guard bigquery/59 has.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
        "  - id: W5\n"
        "    monitor_class: weekly_sun\n"
        "    catchup_safe: true\n"
    )
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## W5. Factbase & Analytics Consolidation — regular routine\nbody\n"
    )
    autofire = tmp_path / "59.sql"
    # Reformatted so UNNEST_ROUTINE_BRACKET no longer matches: double space before `routine`.
    autofire.write_text("SELECT routine FROM UNNEST(['W5']) AS  routine\n")
    monkeypatch.setattr(cc, "CATCHUP_AUTOFIRE_SQL", str(autofire))
    assert cc.parse_unnest_routine_ids(str(autofire)) is None  # confirm the reformat breaks parsing
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "59_catchup_autofire.sql" in out and "DISARMED" in out


def test_check_k_missing_catchup_safe_key_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"  # no catchup_safe key at all
    )
    assert cc.main() == 1
    assert "missing catchup_safe boolean" in capsys.readouterr().out


# ---- check L: parse_inventory_table — the ROUTINE INVENTORY table section, strictly scoped ----
def test_parse_inventory_table_scoping_excludes_slice_map_rows(tmp_path):
    plan = tmp_path / "plan.md"
    plan.write_text(
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
        "| **AR_att** | Adversarial Review Attacker | Daily¹ · regular | r | w | out.md |\n"
        "\n---\n\n"
        "# OPERATING MODEL\n\n"
        "Some other table further down that must NOT be swept into the inventory rows:\n\n"
        "| Routine(s) | Load | Must NOT load |\n"
        "|---|---|---|\n"
        "| **AR_attacker** | the artifact under review only | any strategy slice |\n"
        "\n---\n"
    )
    rows = cc.parse_inventory_table(str(plan))
    ids = [rid for rid, _cell in rows]
    assert ids == ["D1", "AR_att"]
    assert "AR_attacker" not in ids


def test_parse_inventory_table_returns_none_when_heading_absent(tmp_path):
    plan = tmp_path / "plan.md"
    plan.write_text("## D1. Market Development Scan — deep research\nbody\n")
    assert cc.parse_inventory_table(str(plan)) is None


def test_check_l_flipping_cadence_cell_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Weekly · research | r | w | Daily.md |\n"
        "\n---\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "ROUTINE INVENTORY cadence cell 'Weekly'" in out


def test_check_l_deleting_a_row_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "\n---\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1: in ops/cadence.yaml but missing a row in Claude_Task_Plan.md's ROUTINE INVENTORY table" in out


# ---- check L: main()'s handling of parse_inventory_table's None return -- 2026-07-29 replaced a
#      defeatable "still mentions the loose INVENTORY_SENTINEL substring?" disambiguation (present but
#      substring-gone => silently SKIPPED, reproducing the exact pre-fix bug for exactly the class of
#      edit -- a heading rewording -- it was supposed to catch) with a single unconditional hard error.
#      These four cover: reworded-but-substring-survives, reworded-so-substring-also-drops (the proven
#      defeat), heading/table entirely absent, and the real repo (no false positive). ----
def test_check_l_heading_reworded_substring_retained_is_a_hard_error(tmp_path, monkeypatch, capsys):
    # Old heuristic: "ROUTINE INVENTORY" substring survives this rewording -> reported DISARMED (still
    # a failure). New behavior: same hard error as every other None case, no DISARMED-specific wording.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE INVENTORY TABLE & BIGQUERY RESPONSIBILITIES\n\n"  # reworded; still contains the substring
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
        "\n---\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "could not locate the exact heading" in out
    assert cc.INVENTORY_HEADING in out
    assert "reworded" in out and "deleted" in out


def test_check_l_heading_reworded_substring_also_dropped_is_caught(tmp_path, monkeypatch, capsys):
    # PROVEN DEFEAT of the old heuristic (2026-07-29): this rewording drops the "ROUTINE INVENTORY"
    # substring too, so parse_inventory_table returned None and BOTH old branches missed it --
    # main() exited 0 SILENTLY, reproducing the exact bug check L exists to catch. Must now be a hard
    # failure like every other None case.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE ROSTER & BIGQUERY RESPONSIBILITIES\n\n"  # substring "ROUTINE INVENTORY" gone too
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
        "\n---\n"
    )
    assert "ROUTINE INVENTORY" not in plan.read_text()  # confirm the old sentinel substring is truly gone
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "could not locate the exact heading" in out
    assert cc.INVENTORY_HEADING in out


def test_check_l_heading_and_table_entirely_absent_is_caught(tmp_path, monkeypatch, capsys):
    # The changed contract: a plan with NO ROUTINE INVENTORY section at all (formerly the "pre-feature
    # checkout" silent-skip case) is now a hard failure too -- Claude_Task_Plan.md is not optional and
    # the table is a mandatory section of it, so there is no legitimate skip case left.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text("## D1. Market Development Scan — deep research\nbody\n")  # no ROUTINE INVENTORY section
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "could not locate the exact heading" in out
    assert cc.INVENTORY_HEADING in out


def test_check_l_against_real_repo_plan_has_no_false_positive():
    # The real, unmodified Claude_Task_Plan.md must still parse cleanly under the new hard-error
    # contract -- a regression here would fail check L (and thus CI) for every routine change.
    rows = cc.parse_inventory_table(cc.PLAN)
    assert rows is not None
    assert len(rows) > 0


# ---- scripts/gen_routine_lists.py: --write / --check round trip (ARCH-3 Item 30b) ----
def _write_gen_fixture(tmp_path):
    plan = tmp_path / "plan.md"
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## W1. Catalyst Calendar (A, C) — deep research\nbody\n"
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
        "  - id: W1\n"
        "    monitor_class: weekly_sun\n"
        "    catchup_safe: true\n"
    )
    marker_body = (
        "-- header\nblah AS (\n  SELECT * FROM UNNEST([\n"
        "-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)\n"
        "-- END GENERATED ROUTINE LIST\n  ])\n)\n"
    )
    sql12 = tmp_path / "12.sql"
    sql12.write_text(marker_body)
    sql15 = tmp_path / "15.sql"
    sql15.write_text(marker_body.replace("blah AS (\n  SELECT * FROM UNNEST([", "SELECT routine FROM UNNEST(["))
    sql24 = tmp_path / "24.sql"
    sql24.write_text(marker_body)
    sql105 = tmp_path / "105.sql"
    sql105.write_text(marker_body)
    sql114 = tmp_path / "114.sql"
    sql114.write_text(marker_body)
    sql132 = tmp_path / "132.sql"
    sql132.write_text(marker_body)
    return plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132


def _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132):
    # MUST patch every build_targets() entry, including ROUTINE_CATCHUP_SQL and DEP_GATE_SQL —
    # otherwise a test that calls gen.write_region() for all of build_targets() writes real content
    # straight into the actual repo's bigquery/105_routine_catchup_window.sql (or
    # bigquery/114_period_aware_dependency_gate.sql) as a side effect (monkeypatch only undoes attribute
    # patches at teardown, not a file write that already happened). Bit the real-repo no-op test below
    # TWICE now — once the day ROUTINE_CATCHUP_SQL/gen_105_region were added (2026-07-25), and again the
    # day DEP_GATE_SQL was added (2026-07-28) — both times because this helper was not updated in
    # lockstep. EVERY future generated target must be added here too. The failure is confusing when it
    # lands: the no-op test writes the CORRECT content back, so it fails while leaving the working tree
    # looking clean, which reads like a flaky test rather than the cross-test clobber it actually is.
    # THIRD occurrence 2026-08-03, when QUEUE_SILENCE_SQL/gen_132_region were added. Same failure,
    # same cause, same fix. If you are adding a 7th generated target: patch it HERE, in
    # tests/test_gen_routine_lists.py::_wire_fixture, AND in that file's build_targets() count test.
    monkeypatch.setattr(gen, "PLAN", str(plan))
    monkeypatch.setattr(gen, "CADENCE", str(cadence))
    monkeypatch.setattr(gen, "CADENCE_MONITOR_SQL", str(sql12))
    monkeypatch.setattr(gen, "ROUTINE_CATALOG_SQL", str(sql15))
    monkeypatch.setattr(gen, "PERIOD_WATCH_SQL", str(sql24))
    monkeypatch.setattr(gen, "ROUTINE_CATCHUP_SQL", str(sql105))
    monkeypatch.setattr(gen, "DEP_GATE_SQL", str(sql114))
    monkeypatch.setattr(gen, "QUEUE_SILENCE_SQL", str(sql132))


def test_gen_routine_lists_write_then_check_is_clean(tmp_path, monkeypatch):
    gen = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")
    plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132 = _write_gen_fixture(tmp_path)
    _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132)
    # --write: populates the marker regions
    for path, body in gen.build_targets():
        gen.write_region(path, body)
    # a second --write is a byte-level no-op
    changed_again = any(gen.write_region(path, body) for path, body in gen.build_targets())
    assert changed_again is False
    # --check: clean
    for path, body in gen.build_targets():
        assert gen.current_region(path) == gen.wanted_region(body)


def test_gen_routine_lists_check_is_dirty_after_row_deleted(tmp_path, monkeypatch):
    gen = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")
    plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132 = _write_gen_fixture(tmp_path)
    _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24, sql105, sql114, sql132)
    for path, body in gen.build_targets():
        gen.write_region(path, body)
    # delete W1 from cadence.yaml (simulating drift) without re-running --write
    cadence.write_text(
        "timezone: America/Denver\n"
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    dirty = False
    for path, body in gen.build_targets():
        if gen.current_region(path) != gen.wanted_region(body):
            dirty = True
    assert dirty is True


def test_gen_routine_lists_against_real_repo_write_is_noop():
    # The real, already-normalized bigquery/12/15/24/105/114/132 must be a byte-level no-op for --write, and
    # --check must pass clean (proves the generator reproduces today's routine-fleet state exactly).
    gen = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")
    changed = [path for path, body in gen.build_targets() if gen.write_region(path, body)]
    assert changed == []
    for path, body in gen.build_targets():
        assert gen.current_region(path) == gen.wanted_region(body)


def test_gen_12_region_tolerates_missing_monitor_class_like_gen_24():
    # #10 (2026-07-17 audit): a malformed cadence.yaml routine with no monitor_class must not crash
    # gen_12_region with a KeyError (the old `!= "queue_driven"` filter kept the None row, then the
    # f-string bracket-accessed r['monitor_class']). It now silently omits the row, matching the
    # parallel gen_24_region; check_cadence_consistency.py flags the missing key loudly.
    gen = load_module_from_path("gen_routine_lists", "scripts", "gen_routine_lists.py")
    assert gen.gen_12_region([{"id": "X9"}]) == ""
    assert gen.gen_24_region([{"id": "X9"}]) == ""
    # a well-formed row alongside a malformed one still renders the good one, drops the bad one
    rows = [{"id": "D1", "monitor_class": "daily_trading"}, {"id": "X9"}]
    out = gen.gen_12_region(rows)
    assert "'D1'" in out and "'X9'" not in out


# ==================================================================================================
# Coverage added by the parallel refactor (2026-07-17, Part B). These pin branches that previously
# ran ONLY via the aggregate `main()==0` end-to-end tests — precisely the vacuous-pass class this
# module's docstring exists to prevent — plus the new catchup_list_errors() check-K helper.
# All offline / no creds.
# ==================================================================================================

# ---- catchup_list_errors(): the extracted check-K helper (bigquery/31 daily + bigquery/59 period
#      share it). The daily/31 side previously had NO error-level coverage — only the 59 side did. ----
def test_catchup_list_errors_absent_file_is_silent(tmp_path):
    cad = {"D1": {"catchup_safe": True, "monitor_class": "daily_trading"}}
    assert cc.catchup_list_errors(cad, str(tmp_path / "absent.sql"),
                                  "bigquery/31_catchup_notify.sql", "daily", cc.DAILY_CLASSES) == []


def test_catchup_list_errors_matching_list_is_silent(tmp_path):
    f = tmp_path / "31.sql"
    f.write_text("SELECT routine FROM UNNEST(['D1']) AS routine\n")
    cad = {"D1": {"catchup_safe": True, "monitor_class": "daily_trading"}}
    assert cc.catchup_list_errors(cad, str(f), "bigquery/31_catchup_notify.sql",
                                  "daily", cc.DAILY_CLASSES) == []


def test_catchup_list_errors_daily_drift_31_side_is_caught(tmp_path):
    f = tmp_path / "31.sql"
    f.write_text("SELECT routine FROM UNNEST(['ZZ']) AS routine\n")  # cadence wants D1, file has ZZ
    cad = {"D1": {"catchup_safe": True, "monitor_class": "daily_trading"}}
    errs = cc.catchup_list_errors(cad, str(f), "bigquery/31_catchup_notify.sql", "daily", cc.DAILY_CLASSES)
    assert len(errs) == 1
    assert "bigquery/31_catchup_notify.sql catchup-safe daily UNNEST list DRIFT" in errs[0]
    assert "['ZZ']" in errs[0] and "['D1']" in errs[0]


def test_catchup_list_errors_daily_disarmed_31_side_is_caught(tmp_path):
    f = tmp_path / "31.sql"
    f.write_text("SELECT routine FROM UNNEST(['D1']) AS  routine\n")  # double space breaks the bracket regex
    cad = {"D1": {"catchup_safe": True, "monitor_class": "daily_trading"}}
    assert cc.parse_unnest_routine_ids(str(f)) is None  # confirm the reformat disarms parsing
    errs = cc.catchup_list_errors(cad, str(f), "bigquery/31_catchup_notify.sql", "daily", cc.DAILY_CLASSES)
    assert len(errs) == 1
    assert "bigquery/31_catchup_notify.sql" in errs[0] and "DISARMED" in errs[0]


# ---- check M: the H1 evening-slot SAME-DAY guard noon-threshold clause (main() had no unit test) ----
def _guard_line(rid, with_noon=True, broken=False):
    # Mirrors the real Claude_Task_Plan.md guard query shape. `broken` spaces out status='completed'
    # so GUARD_QUERY_RE stops matching (the regex-rot / DISARMED case); `with_noon=False` drops the
    # noon clause (the MISSING case).
    completed = "status = 'completed'" if broken else "status='completed'"
    noon = (" AND DATETIME(log_ts,'America/Denver') >= "
            "DATETIME(<today, America/Denver>, TIME '12:00:00')") if with_noon else ""
    return f"{rid} guard: `routine='{rid}' AND run_date=<today, America/Denver> AND {completed}{noon}`\n"


def _plan_with_guards(d1=True, d2=True, d2a=True, d3=True, sl3=True, d1_broken=False):
    # Keeps the D1 heading (check C) and adds the SAME-DAY sentinel + one guard query per
    # EVENING_DAILY_GUARD_IDS routine. D2/D2a/D3/SL3 appear only in guard-query BODY text, never as
    # `## ` headings, so they create no phantom routines. Also carries a minimal valid ROUTINE
    # INVENTORY table for D1 (check L) since these tests wholesale-replace _write_check_fixture's plan
    # text via plan.write_text() -- without it, check L's 2026-07-29 hard-error-on-missing-table would
    # fail every test built from this helper, including the happy-path one, for a reason unrelated to
    # what check M is testing here.
    return ("## D1. Market Development Scan — deep research\nbody\n\n"
            "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
            "| ID | Routine | Cadence · Type | reads | writes | out |\n"
            "|---|---|---|---|---|---|\n"
            "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
            "\n---\n\n"
            "Shared Observability guard SAME-DAY DOUBLE-RUN GUARD (CYCLE-AWARE VARIANT):\n"
            + _guard_line("D1", with_noon=d1, broken=d1_broken)
            + _guard_line("D2", with_noon=d2)
            + _guard_line("D2a", with_noon=d2a)
            + _guard_line("D3", with_noon=d3)
            + _guard_line("SL3", with_noon=sl3))


def test_check_m_happy_path_all_guards_have_noon_clause(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(_plan_with_guards())
    assert cc.main() == 0


def test_check_m_missing_noon_clause_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(_plan_with_guards(d1=False))  # D1's guard copy loses its noon clause
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "MISSING the noon-threshold clause" in out


def test_check_m_disarmed_when_guard_query_unparseable_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(_plan_with_guards(d1_broken=True))  # D1's query no longer matches GUARD_QUERY_RE
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "D1" in out and "DISARMED" in out


def test_check_m_total_absence_of_sentinel_is_caught(tmp_path, monkeypatch, capsys):
    # REGRESSION (2026-08-08): check M used to be wrapped in `if "SAME-DAY DOUBLE-RUN GUARD" in
    # plan_txt:`, so a plan carrying NONE of that text (the sentinel renamed, or the whole section
    # removed) made the check skip silently rather than flag all four EVENING_DAILY_GUARD_IDS routines
    # as DISARMED. _write_check_fixture's own default plan has no guard text, so the plain, unmodified
    # fixture already exercises this -- no plan override needed.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n\n"
        "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
        "| ID | Routine | Cadence · Type | reads | writes | out |\n"
        "|---|---|---|---|---|---|\n"
        "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
        "\n---\n"
    )  # same as _write_check_fixture's own plan, minus the guard text this test is about
    assert cc.main() == 1
    out = capsys.readouterr().out
    for rid in cc.EVENING_DAILY_GUARD_IDS:
        assert f"{rid}: could not find its SAME-DAY DOUBLE-RUN GUARD" in out


# ---- check M membership cross-check: evening_slot_guard_membership_errors (2026-08-09) -------------
# Mirrors tests/test_check_cron_dst_safety.py's daily_sun_thu_coverage_errors() tests: call the pure
# function directly with EVENING_DAILY_GUARD_IDS / NOON_CLAUSE_EXEMPT_EVENING_IDS monkeypatched to
# small synthetic sets and a matching synthetic cad, bypassing main() entirely. This is deliberate, not
# a shortcut: _patch_fixture_paths (above) permanently no-ops evening_slot_guard_membership_errors for
# every main()-level test in this file (see its own comment for why -- EVENING_DAILY_GUARD_IDS also
# drives GUARD_QUERY_RE, built at import time, so patching that tuple for a main()-level test would
# risk a stale-dict KeyError in check M's own unrelated per-id loop), so these direct calls are the
# ONLY coverage this function gets. Same convention as check_depends_on's own direct-call tests above.
def _cad_with_time_local(entries):
    """{id: {"expected_trigger": {"time_local": tl}}} from [(id, tl), ...] -- the minimal cad shape
    evening_slot_guard_membership_errors() reads (only expected_trigger.time_local matters to it)."""
    return {rid: {"expected_trigger": {"time_local": tl}} for rid, tl in entries}


def test_evening_slot_membership_unclassified_id_is_caught(monkeypatch):
    monkeypatch.setattr(cc, "EVENING_DAILY_GUARD_IDS", ("DX",))
    monkeypatch.setattr(cc, "NOON_CLAUSE_EXEMPT_EVENING_IDS", {})
    # DY is evening-slot (>= 16:00) but classified in neither set -- a new or re-timed routine nobody
    # has decided about yet.
    cad = _cad_with_time_local([("DX", "16:00"), ("DY", "19:30")])
    errs = cc.evening_slot_guard_membership_errors(cad)
    assert len(errs) == 1
    assert "['DY']" in errs[0]
    assert "NEITHER EVENING_DAILY_GUARD_IDS nor NOON_CLAUSE_EXEMPT_EVENING_IDS" in errs[0]


def test_evening_slot_membership_stale_id_retimed_is_caught(monkeypatch):
    # NOON_CLAUSE_EXEMPT_EVENING_IDS still names 'DZ', but ops/cadence.yaml no longer has it as an
    # evening-slot routine (retimed to a morning slot here; retired/renamed is the other real-world
    # shape, covered separately below).
    monkeypatch.setattr(cc, "EVENING_DAILY_GUARD_IDS", ("DX",))
    monkeypatch.setattr(cc, "NOON_CLAUSE_EXEMPT_EVENING_IDS", {"DZ": "reason"})
    cad = _cad_with_time_local([("DX", "16:00"), ("DZ", "06:30")])
    errs = cc.evening_slot_guard_membership_errors(cad)
    assert len(errs) == 1
    assert "['DZ']" in errs[0]
    assert "no longer expected_trigger.time_local" in errs[0]


def test_evening_slot_membership_stale_id_removed_from_cadence_is_caught(monkeypatch):
    # Same STALE case, but 'DZ' was removed from ops/cadence.yaml entirely rather than retimed.
    monkeypatch.setattr(cc, "EVENING_DAILY_GUARD_IDS", ("DX",))
    monkeypatch.setattr(cc, "NOON_CLAUSE_EXEMPT_EVENING_IDS", {"DZ": "reason"})
    cad = _cad_with_time_local([("DX", "16:00")])
    errs = cc.evening_slot_guard_membership_errors(cad)
    assert len(errs) == 1
    assert "['DZ']" in errs[0]


def test_evening_slot_membership_overlap_is_caught(monkeypatch):
    monkeypatch.setattr(cc, "EVENING_DAILY_GUARD_IDS", ("DX",))
    monkeypatch.setattr(cc, "NOON_CLAUSE_EXEMPT_EVENING_IDS", {"DX": "reason"})
    cad = _cad_with_time_local([("DX", "16:00")])
    errs = cc.evening_slot_guard_membership_errors(cad)
    assert len(errs) == 1
    assert "['DX']" in errs[0]
    assert "BOTH EVENING_DAILY_GUARD_IDS and NOON_CLAUSE_EXEMPT_EVENING_IDS" in errs[0]


def test_evening_slot_membership_correctly_classified_baseline_is_clean(monkeypatch):
    monkeypatch.setattr(cc, "EVENING_DAILY_GUARD_IDS", ("DX",))
    monkeypatch.setattr(cc, "NOON_CLAUSE_EXEMPT_EVENING_IDS", {"DY": "queue-driven, not calendar-clocked"})
    cad = _cad_with_time_local([
        ("DX", "16:00"),   # guarded evening-slot routine
        ("DY", "19:30"),   # exempt evening-slot routine
        ("DZ", "06:30"),   # a morning-slot routine -- not an evening-slot candidate at all
    ])
    assert cc.evening_slot_guard_membership_errors(cad) == []


def test_evening_slot_membership_against_real_repo_is_clean():
    # The real, unmodified ops/cadence.yaml and the real EVENING_DAILY_GUARD_IDS /
    # NOON_CLAUSE_EXEMPT_EVENING_IDS classification must agree today (verified 2026-08-09: exactly the
    # 11 evening-slot routines D1/D2a/D2/AR_att/AR_orc/D3/SL2/SL5/SL3/OPS2/OPS0 split 5/6 across the two
    # sets) -- a regression here would fail this AND check M in main() for every cadence.yaml change.
    assert cc.evening_slot_guard_membership_errors(cc.load_cadence()) == []


# ---- check N: MODEL OF RECORD mirrors (added 2026-07-28; had ZERO tests -- this section closes that
#      gap). Renamed from a collision with check M above: both blocks had labelled themselves "M". ----
def test_check_n_missing_routine_model_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # _write_check_fixture's cadence.yaml normally declares routine_model (added alongside check N)
    # -- overwrite it here to deliberately omit the key, so this test can exercise check N's
    # "missing" branch.
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "ops/cadence.yaml: missing top-level 'routine_model'" in out


def test_check_n_malformed_routine_model_bad_shape_is_caught(tmp_path, monkeypatch, capsys):
    # A string that lacks the 'claude-' prefix must be rejected by MODEL_ID_VALID.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: opus-5\n"  # missing the 'claude-' prefix
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "routine_model must be a bare Claude model id" in out and "opus-5" in out


def test_check_n_malformed_routine_model_non_string_is_caught(tmp_path, monkeypatch, capsys):
    # The isinstance(model, str) half of the guard is a SEPARATE branch from MODEL_ID_VALID.match --
    # a non-string (here, a YAML int) must be caught too, not just a badly-shaped string.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: 5\n"  # a YAML int, not a string
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "routine_model must be a bare Claude model id" in out


def test_check_n_malformed_routine_model_trailing_punctuation_is_caught(tmp_path, monkeypatch):
    # DEFECT (2026-07-28): MODEL_ID_CORE's tail class ([a-z0-9.\-]*) admits a trailing '-' or '.', so
    # MODEL_ID_VALID.fullmatch() alone accepts a value like 'claude-opus-5-' as well-formed -- but
    # MODEL_ID_RE's trailing \b cannot terminate a match right after that same non-word character, so
    # the mirror scanner recovers only the SHORTER token 'claude-opus-5' from prose naming this exact
    # value. Left unchecked, check_model_of_record() would then report BOTH a genuine mirror line AND
    # this very ops/cadence.yaml routine_model line as drifted -- a self-contradictory report pointing
    # the author at the line that IS the source value. The validation gate now rejects any
    # routine_model whose last character is not alphanumeric. Asserted one value at a time so a
    # failure names the exact offending value.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    malformed = [
        "claude-opus-5-",    # trailing hyphen
        "claude-opus-5.",    # trailing dot
        "claude-opus-5-.",   # trailing hyphen-then-dot
    ]
    for value in malformed:
        cadence.write_text(
            "timezone: America/Denver\n"
            'cadence_watch_deadline_local: "21:00"\n'
            f"routine_model: {value}\n"
            "routines:\n"
            "  - id: D1\n"
            "    monitor_class: daily_trading\n"
            "    catchup_safe: true\n"
        )
        errs, model = cc.check_model_of_record()
        assert len(errs) == 1 and "routine_model must be a bare Claude model id" in errs[0] \
            and value in errs[0], f"{value!r} should be rejected as malformed (trailing punctuation): {errs}"
        assert model is None, f"{value!r}: a malformed routine_model must return model=None"
    # Non-regression: the well-formed value (no trailing punctuation) must still be accepted.
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    errs, model = cc.check_model_of_record()
    assert errs == [] and model == "claude-opus-5"


def test_check_n_happy_path_mirror_matches_is_clean(tmp_path, monkeypatch):
    # A fixture mirror file (OWNER_ACTIONS, monkeypatchable per the model_mirror_files()
    # call-time-resolution fix) quoting the SAME id as cadence.yaml's routine_model must be silent.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("All remote routines run claude-opus-5 today.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    assert cc.main() == 0


def test_check_n_drifted_mirror_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("All remote routines run claude-sonnet-5 today.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    assert cc.main() == 1
    out = capsys.readouterr().out
    # file:line, both ids, and the model-id-exempt remediation hint must all be present.
    assert "OWNER_ACTIONS.md:1:" in out
    assert "claude-sonnet-5" in out and "claude-opus-5" in out
    assert "model-id-exempt" in out


def test_check_n_model_id_exempt_marker_suppresses_drift(tmp_path, monkeypatch):
    # The SAME drifted line as above, but carrying the model-id-exempt marker, must be silent.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text(
        "Historically the fleet also tried claude-sonnet-5 (model-id-exempt — illustrative only).\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    assert cc.main() == 0


def test_check_n_fixture_model_mismatch_does_not_leak_into_real_repo_files(tmp_path, monkeypatch, capsys):
    # REGRESSION TEST for the model_mirror_files() call-time-resolution cross-contamination bug.
    # Before that fix, MODEL_MIRROR_FILES was a
    # module-level list built ONCE at import time from hardcoded os.path.join(ROOT, ...) calls -- it
    # could never be monkeypatched, so check_model_of_record() read the routine_model VALUE from this
    # fixture's (correctly monkeypatched) cadence.yaml but SCANNED the real repo's OWNER_ACTIONS.md /
    # Claude_Task_Plan.md / bigquery/15_routine_catalog.sql / ops/cadence.yaml. A fixture using a model
    # id different from the real repo's routine_model (claude-opus-5) then spuriously flagged every
    # REAL mirror site as drifted, misdirecting a maintainer at real files that were never touched by
    # this test. Must FAIL on pre-fix code (real paths appear in the output), PASS after (they don't).
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-sonnet-5\n"  # deliberately DIFFERENT from the real repo's claude-opus-5
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    cc.main()
    out = capsys.readouterr().out
    assert "OWNER_ACTIONS.md" not in out
    assert "bigquery/15_routine_catalog.sql" not in out
    assert "ops/cadence.yaml:" not in out  # the REAL ops/cadence.yaml -- a different file from the fixture's


# ---- check N: LOUD-BY-DEFAULT matching + precise SUBTRACTION (2026-07-28 adversarial review, THREE
#      rounds -- see the comment block above MODEL_ID_CORE in check_cadence_consistency.py for the full
#      history). Round 1 (a shape-tightened MODEL_ID_CORE) and Round 2 (an unsound "extends the correct
#      id" subtraction, DEFECT A) were both tried and REVERTED; Round 2's replacement, a version-shaped
#      bound on the ONE surviving subtraction (NOT_A_MODEL_PREFIXES, DEFECT B), is current. Tests below
#      are grouped: (1) the one surviving subtraction class (tooling prefixes) stays narrow and correct,
#      including its DEFECT-B version bound, (2) each of the concrete regressions from all three rounds
#      now has a dedicated test that would have caught it, (3) the surviving pre-existing coverage
#      (URL-strip, bracket suffix, dedup ordering, VALID-vs-RE coupling) is kept unchanged. ----
_NOT_A_MODEL_PREFIX_TOKENS = [
    "claude-code",
    "claude-code-action",
    "claude-code-settings.json",
    "claude-agent-sdk-with-your-claude-plan",
    "claude-cli",
    "claude-cli-tools",
    "claude-desktop",
    "claude-desktop-app",
]

_MODEL_ID_GENUINE_IDS = [
    "claude-opus-5",
    "claude-sonnet-5",
    "claude-fable-5",
    "claude-opus-4-8",
    "claude-haiku-4-5-20251001",
]


def test_check_n_not_a_model_prefix_tokens_are_not_flagged(tmp_path, monkeypatch):
    # Table-driven, one token per NOT_A_MODEL_PREFIXES entry (claude-code/claude-agent-sdk/claude-cli/
    # claude-desktop) plus a couple of realistic extensions of each -- these name CLI/SDK tooling, never
    # a model, and must be subtracted regardless of what routine_model is set to. Asserted one token at
    # a time so a failure names the exact offender instead of a single opaque "some token matched".
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for token in _NOT_A_MODEL_PREFIX_TOKENS:
        owner_actions.write_text(f"See {token} for details.\n")
        errs, _ = cc.check_model_of_record()
        assert errs == [], f"{token!r} was wrongly flagged as a model id: {errs}"


def test_check_n_genuine_model_ids_are_flagged_when_they_differ(tmp_path, monkeypatch):
    # Each id here is a real Claude model id shape; with routine_model set to something else, every one
    # of them must still be caught as drift. Asserted one id at a time (same reason as above).
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # routine_model deliberately outside _MODEL_ID_GENUINE_IDS, so every one of them is a genuine drift.
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-titan-9\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for model_id in _MODEL_ID_GENUINE_IDS:
        owner_actions.write_text(f"The fleet runs {model_id} today.\n")
        errs, _ = cc.check_model_of_record()
        assert len(errs) == 1 and model_id in errs[0], (
            f"{model_id!r} was NOT flagged as drifted from claude-titan-9: {errs}")


def test_check_n_bracket_suffixed_model_id_is_still_flagged(tmp_path, monkeypatch):
    # "claude-opus-5" inside "claude-opus-5[1m]" (a context-window-suffix convention seen in prose) must
    # still be recognized as the bare id: MODEL_ID_CORE's character class ([a-z0-9.\-]) does not include
    # '[', so the broad match naturally stops at "claude-opus-5" and "[1m]" plays no part in tokenization.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-titan-9\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("Context window: claude-opus-5[1m] supports 1M tokens.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-opus-5" in errs[0]


def test_check_n_model_id_inside_url_is_not_flagged(tmp_path, monkeypatch):
    # A model id inside a plain URL (no trailing bracket/quote to bound against) is still stripped by
    # URL_RE and so is NOT flagged -- the general "URL span is a citation, not an assertion" case.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See https://example.com/claude-sonnet-5 for corroboration.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert errs == []


def test_check_n_model_card_slug_with_correct_routine_model_is_now_flagged_via_exempt_marker(
        tmp_path, monkeypatch):
    # DEFECT A (2026-07-28 adversarial review): the OLD design subtracted a citation slug that merely
    # EXTENDS the correct routine_model ("claude-opus-5-model-card", no http(s) prefix -- so the
    # URL-strip defense alone could not have saved it) as "clean, not a fleet assertion". That was
    # UNSOUND -- shape alone cannot distinguish a citation slug from a real, different sibling model id
    # extending the same prefix (see the DEFECT-A regression test below for the live repros that proved
    # it). The subtraction was DELETED: a bare (non-URL) 'claude-opus-5-model-card' is now FLAGGED like
    # any other differing id, and the documented remedy is the 'model-id-exempt' marker -- assert both
    # halves of that intended author workflow.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See anthropic.com/news/claude-opus-5-model-card for the model card.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-opus-5-model-card" in errs[0]
    # Adding the marker to the SAME line makes it clean -- the intended author remediation workflow.
    owner_actions.write_text(
        "See anthropic.com/news/claude-opus-5-model-card for the model card. (model-id-exempt)\n")
    errs, _ = cc.check_model_of_record()
    assert errs == []


def test_check_n_slug_extending_a_different_model_is_still_flagged(tmp_path, monkeypatch):
    # A citation slug extending a DIFFERENT id (the fleet runs opus-5; this line cites an opus-4-8
    # system card) is FLAGGED -- erring loud -- and the author resolves it with 'model-id-exempt' if the
    # line is genuinely just a citation, not a fleet assertion. Post-DEFECT-A this is no longer a special
    # "asymmetric" case: with the "extends the correct id" subtraction deleted entirely, EVERY extension
    # slug is flagged the same way, including one that extends the CORRECT id (see the exempt-marker
    # test above) -- kept as its own test because a citation of a genuinely different sibling model is
    # the case most likely to recur in this repo's prose (see OWNER_ACTIONS.md's own migration notes).
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See anthropic.com/news/claude-opus-4-8-system-card for the model card.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-opus-4-8-system-card" in errs[0]


def test_check_n_numeric_extension_of_routine_model_is_flagged_not_subtracted(tmp_path, monkeypatch):
    # "claude-opus-50" STARTS WITH routine_model "claude-opus-5" character-for-character, but the next
    # character is a digit ('0'), not '-'/'.' -- it names a DIFFERENT model (opus 50, not opus 5).
    # NOT_A_MODEL_PREFIXES doesn't match it at all (it isn't a tooling name), so it is flagged
    # regardless -- but this pins the shape as a standing regression guard, since it is exactly the kind
    # of "extends the correct id" token the deleted DEFECT-A subtraction used to key off of.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("The fleet now runs claude-opus-50 today.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-opus-50" in errs[0]


def test_check_n_routine_model_hitting_not_a_model_prefix_is_rejected(tmp_path, monkeypatch, capsys):
    # Step-6 guard: a routine_model value that itself hits NOT_A_MODEL_PREFIXES (e.g. 'claude-code')
    # could never be found by the scanner -- every mirror token starting with it would be subtracted as
    # tooling too -- which would make the whole check vacuously pass. Must be rejected the same way a
    # badly-shaped routine_model already is (same "malformed" error family).
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-code\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "routine_model must be a bare Claude model id" in out and "claude-code" in out


# ---- check N regression tests: each of the three concrete defects the 2026-07-28 over-tightening
#      introduced, and that the loud-by-default redesign fixes -- one test per repro named in the
#      redesign's own comment block, so a future re-tightening trips these first. ----
def test_check_n_regression_claude_opus_4_latest_stale_mirror_is_flagged(tmp_path, monkeypatch, capsys):
    # HIGH regression #1: the over-tightened MODEL_ID_RE matched 'claude-opus-4-latest' (the real
    # -latest/-preview alias convention) ZERO times, so a fixture with a genuinely stale OWNER_ACTIONS.md
    # mirror printed "CADENCE CONSISTENCY: OK ... matches all mirror sites" and exited 0 -- silent
    # false-clean. Driven end-to-end via main() (not just check_model_of_record()) to reproduce the
    # exact observed failure mode: a wrong exit code plus a misleadingly clean report.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("The fleet runs claude-opus-4-latest today.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "CADENCE CONSISTENCY: OK" not in out
    assert "claude-opus-4-latest" in out


_DIGIT_LED_HISTORICAL_MODEL_IDS = [
    "claude-3-5-sonnet-20241022",
    "claude-3-opus-20240229",
    "claude-5-opus",
]


def test_check_n_regression_digit_led_historical_ids_are_each_flagged(tmp_path, monkeypatch):
    # HIGH regression #2: the over-tightened MODEL_ID_CORE required a LETTER immediately after the
    # family hyphen ('claude-[a-z]+...'), so a real historical Anthropic id with a DIGIT right after
    # 'claude-' matched ZERO times. Asserted per-id so a failure names the exact offender instead of an
    # opaque "some id slipped through".
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for model_id in _DIGIT_LED_HISTORICAL_MODEL_IDS:
        owner_actions.write_text(f"The fleet used to run {model_id}.\n")
        errs, _ = cc.check_model_of_record()
        assert len(errs) == 1 and model_id in errs[0], (
            f"{model_id!r} was NOT flagged (digit-right-after-'claude-' regression): {errs}")


_DEFECT_A_EXTENSION_IDS = [
    "claude-opus-5-preview",
    "claude-opus-5-latest",
    "claude-opus-5-beta",
    "claude-opus-5-exp",
    "claude-opus-5-20250219",
    "claude-opus-5-1",
    "claude-opus-5.1",
]


def test_check_n_regression_defect_a_extension_ids_are_each_flagged(tmp_path, monkeypatch):
    # DEFECT A regression test (2026-07-28 adversarial review): each id below is a real, DIFFERENT
    # model id shape that EXTENDS the correct routine_model ('claude-opus-5') character-for-character.
    # The now-deleted "extends the correct id" subtraction swallowed every one of these silently
    # (confirmed live, zero errors, before the fix) -- the exact silent false-clean this check exists to
    # prevent. Asserted per-id so a failure names the exact offender instead of an opaque "some id
    # slipped through", and so a future re-introduction of that subtraction trips this test first.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for model_id in _DEFECT_A_EXTENSION_IDS:
        owner_actions.write_text(f"All remote routines run {model_id} today.\n")
        errs, _ = cc.check_model_of_record()
        assert len(errs) == 1 and model_id in errs[0], (
            f"{model_id!r} was NOT flagged (DEFECT A regression -- the deleted 'extends the correct "
            f"id' subtraction would have silently swallowed this as clean): {errs}")


_DEFECT_B_VERSION_SHAPED_TOOLING_TOKENS = ["claude-code-5", "claude-code-4-8", "claude-cli-2.1"]
_DEFECT_B_GENUINE_TOOLING_EXTENSION_TOKENS = [
    "claude-code", "claude-code-action", "claude-code-settings.json", "claude-agent-sdk-python",
]


def test_check_n_defect_b_tooling_prefix_version_bound(tmp_path, monkeypatch):
    # DEFECT B (2026-07-28 adversarial review): NOT_A_MODEL_PREFIXES exists to subtract CLI/SDK tooling
    # names, never a model -- but matching it with a blunt str.startswith() silently swallowed a
    # hypothetical real model sharing a tooling prefix's name (confirmed live: 'claude-code-5' returned
    # zero errors before the fix). Bound it: subtract ONLY when the remainder right after the matched
    # prefix does NOT look version-shaped ('-' or '.' then a DIGIT). Both directions asserted here so a
    # regression toward either "too loose" (swallows a real id) or "too strict" (flags genuine tooling
    # mentions) is caught.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for token in _DEFECT_B_VERSION_SHAPED_TOOLING_TOKENS:
        owner_actions.write_text(f"The fleet now runs {token} today.\n")
        errs, _ = cc.check_model_of_record()
        assert len(errs) == 1 and token in errs[0], (
            f"{token!r} should be FLAGGED (version-shaped tooling-prefix extension): {errs}")
    for token in _DEFECT_B_GENUINE_TOOLING_EXTENSION_TOKENS:
        owner_actions.write_text(f"See {token} for details.\n")
        errs, _ = cc.check_model_of_record()
        assert errs == [], f"{token!r} should be SUBTRACTED (genuine tooling extension): {errs}"


def test_check_n_block_scalar_routine_model_trailing_newline_is_malformed_and_single_line(
        tmp_path, monkeypatch, capsys):
    # A YAML block scalar (routine_model: |) yields "claude-opus-5\n". A bare '$'-anchored
    # MODEL_ID_VALID would PASS this ('$' also matches just before a trailing newline), then leak the
    # raw embedded newline into the per-mirror mismatch f-string, breaking the single-line " - " bullet
    # report. fullmatch must reject it outright as malformed instead.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: |\n"
        "  claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    hit = [ln for ln in out.splitlines() if "routine_model must be a bare Claude model id" in ln]
    assert len(hit) == 1, f"expected exactly one single-line malformed report, got: {hit}"
    # the malformed value's real newline is ESCAPED by repr() ('\n' as the two characters backslash-n),
    # not embedded raw -- confirm the bullet was not split across two printed lines by a real newline.
    assert "\\n" in hit[0]


def test_check_n_two_wrong_ids_on_one_line_report_in_first_appearance_order(tmp_path, monkeypatch):
    # dict.fromkeys(...) preserves FIRST-APPEARANCE (left-to-right) order while de-duping, instead of
    # set(...) whose iteration order varies with PYTHONHASHSEED. Assert the EXACT order (not just "both
    # present") so this test would catch a regression back to set() even under hash randomization.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("Tried both claude-sonnet-5 and claude-fable-5 during evaluation.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()  # both differ from routine_model claude-opus-5
    assert len(errs) == 2
    assert "claude-sonnet-5" in errs[0] and "claude-fable-5" not in errs[0]
    assert "claude-fable-5" in errs[1] and "claude-sonnet-5" not in errs[1]


def test_check_n_model_id_valid_and_model_id_re_shape_cannot_drift_apart():
    # MODEL_ID_VALID (the routine_model well-formedness gate) and MODEL_ID_RE (the mirror scanner) are
    # both built from the single MODEL_ID_CORE pattern (defect 2c) -- but sharing a source doesn't stop
    # a future hand-edit of one without the other. Guard: every id routine_model could legitimately hold
    # must satisfy MODEL_ID_VALID, AND running MODEL_ID_RE over the bare id must find EXACTLY that id --
    # if a future edit widens/narrows one regex without the other, this fails.
    for model_id in _MODEL_ID_GENUINE_IDS:
        assert cc.MODEL_ID_VALID.fullmatch(model_id), f"{model_id!r} should satisfy MODEL_ID_VALID"
        assert cc.MODEL_ID_RE.findall(model_id) == [model_id], (
            f"MODEL_ID_RE does not recognize well-formed routine_model value {model_id!r} as a model id")


# ---- check N's MODEL_EXEMPT word-boundary fix (HIGH, 2026-07-28): MODEL_EXEMPT anchored with \b on both sides. Pre-fix it was an
#      unanchored substring search, and check_model_of_record() skips the ENTIRE line on a match -- so an
#      ordinary word containing 'model-id-exempt' as an infix silently suppressed a REAL drift reported
#      on the same line. Confirmed live pre-fix: a line naming a genuinely stale id but also containing
#      "model-id-exemption-only" printed "CADENCE CONSISTENCY: OK" and exited 0. ----
def test_check_n_exempt_marker_word_boundary_per_string(tmp_path, monkeypatch):
    # Each line below names the SAME stale id (claude-sonnet-5, differing from the fixture's
    # routine_model claude-opus-5) but varies only the marker-shaped text following it. Asserted one
    # string at a time so a failure names the exact offender, per the task's per-string requirement.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    cases = [
        # (line, should_still_be_flagged)
        ("The fleet upgraded from claude-sonnet-5 last quarter; that citation is "
         "model-id-exemption-only, not a live assertion.", True),
        ("The fleet upgraded from claude-sonnet-5 last quarter (model-id-exempted, not current).", True),
        ("The fleet upgraded from claude-sonnet-5 last quarter (nonmodel-id-exempt).", True),
        ("The fleet upgraded from claude-sonnet-5 last quarter (model-id-exempt).", False),
        ("The fleet upgraded from claude-sonnet-5 last quarter. model-id-exempt.", False),
    ]
    for line, should_flag in cases:
        owner_actions.write_text(line + "\n")
        errs, _ = cc.check_model_of_record()
        flagged = len(errs) == 1 and "claude-sonnet-5" in errs[0]
        assert flagged == should_flag, (
            f"{line!r}: expected flagged={should_flag} but got errs={errs}")


# ---- check N's MODEL_ID_RE leading-\b-removal fix (HIGH, 2026-07-28): MODEL_ID_RE's leading \b dropped (trailing \b kept). Pre-fix, a
#      dropped-space typo that fused an id into the previous word hid it from the scanner entirely. ----
def test_check_n_regression_glued_no_space_id_is_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("Fleet nowclaude-sonnet-5 is the model.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-5" in errs[0]


def test_check_n_regression_glued_no_space_id_after_verb_is_flagged(tmp_path, monkeypatch):
    # Second glued-typo shape named in the redesign (a different preceding word), kept as its own test
    # since the task calls out both 'nowclaude-sonnet-5' and 'runsclaude-sonnet-5' as live repros.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("The fleet runsclaude-sonnet-5 today.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-5" in errs[0]


# ---- check N's URL_RE delimiter-bounding fix (MEDIUM, operator-requested, 2026-07-28): URL_RE's
#      character class also excludes ',' ';' '|' '<' '(' '[' '{' -- natural sentence delimiters it
#      previously still admitted, so a genuine stale id sitting right after one of them (still on the
#      same line as the URL) was eaten along with the URL and never scanned. One test per delimiter,
#      plus one confirming the genuine in-URL-path citation case (no delimiter before the slug) is
#      still NOT flagged. The markdown-link closing-paren delimiter is covered by
#      test_check_n_url_delimiter_markdown_paren_stale_id_is_flagged BELOW, which also carries the
#      Round-1 greedy-URL_RE regression that once lived in a separate test of its own (the two
#      asserted the same shape with the same id, so they were merged 2026-07-28 rather than kept as a
#      false distinction). ----
def test_check_n_url_delimiter_comma_stale_id_is_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See https://example.com/x,claude-sonnet-4 is stale\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-4" in errs[0]


def test_check_n_url_delimiter_semicolon_stale_id_is_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See https://example.com/x;claude-sonnet-4 is stale\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-4" in errs[0]


def test_check_n_url_delimiter_pipe_stale_id_is_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("See https://example.com/x|claude-sonnet-4 is stale\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-4" in errs[0]


def test_check_n_url_delimiter_angle_bracket_stale_id_is_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("<https://example.com/x>claude-sonnet-4 remains\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-4" in errs[0]


def test_check_n_url_delimiter_markdown_paren_stale_id_is_flagged(tmp_path, monkeypatch):
    # Covers TWO things with the same shape, merged into one test (2026-07-28: the two were previously
    # separate tests with the identical id/context and a docstring on this one falsely claiming the
    # other test covered "a different id/context" -- it didn't):
    #   1. The original Round-1 regression: the old greedy URL_RE (r"https?://\S+", bounded only by
    #      whitespace) swallowed a genuine model id sitting immediately after a markdown link's closing
    #      ')' with no space. URL_RE now stops at the closing bracket, so the id is left behind and
    #      still scanned.
    #   2. The later URL_RE delimiter-bounding fix's explicit table row for this exact shape, alongside
    #      its siblings above (comma, semicolon, pipe, angle bracket).
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text("[t](https://example.com/x)claude-sonnet-4 remains\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-4" in errs[0]


def test_check_n_genuine_url_citation_slug_still_not_flagged(tmp_path, monkeypatch):
    # URL_RE delimiter-bounding regression guard: a genuine model-id-shaped slug living INSIDE a URL
    # path with NO delimiter before it (an ordinary citation, e.g. an Anthropic model-card URL) must
    # remain unflagged -- that fix only bounds the strip at extra DELIMITER characters, it must not
    # start splitting on ordinary path segments.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for line in [
        "see https://anthropic.com/news/claude-opus-4-8-system-card for the announcement\n",
        "docs at https://docs.anthropic.com/claude-opus-4-8 today\n",
    ]:
        owner_actions.write_text(line)
        errs, _ = cc.check_model_of_record()
        assert errs == [], f"{line!r} should not be flagged: {errs}"


# ---- check I: expected_trigger structural validation (every failure branch was untested) ----
def _setup_check_i(tmp_path, monkeypatch, routine_block):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n" + routine_block)
    ids = tmp_path / "trigger_ids.json"
    ids.write_text('{"D1": {"trigger_id": "trig_A", "verified_via": "api"}}')
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(ids))


def test_check_i_well_formed_expected_trigger_is_clean(tmp_path, monkeypatch):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
                   "    expected_trigger:\n      recurrence: daily\n      enabled: true\n"
                   '      time_local: "09:30"\n')
    assert cc.main() == 0


def test_check_i_missing_expected_trigger_with_live_id_is_caught(tmp_path, monkeypatch, capsys):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n")
    assert cc.main() == 1
    assert "no 'expected_trigger'" in capsys.readouterr().out


def test_check_i_bad_recurrence_is_caught(tmp_path, monkeypatch, capsys):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
                   "    expected_trigger:\n      recurrence: hourly\n      enabled: true\n")
    assert cc.main() == 1
    assert "recurrence='hourly'" in capsys.readouterr().out


def test_check_i_missing_enabled_is_caught(tmp_path, monkeypatch, capsys):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
                   "    expected_trigger:\n      recurrence: daily\n" '      time_local: "09:30"\n')
    assert cc.main() == 1
    assert "missing 'enabled'" in capsys.readouterr().out


def test_check_i_bad_time_local_is_caught(tmp_path, monkeypatch, capsys):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
                   "    expected_trigger:\n      recurrence: daily\n      enabled: true\n"
                   '      time_local: "9:30"\n')  # not HH:MM (single-digit hour)
    assert cc.main() == 1
    assert "time_local must be a quoted" in capsys.readouterr().out


def test_check_i_empty_cron_utc_is_caught(tmp_path, monkeypatch, capsys):
    _setup_check_i(tmp_path, monkeypatch,
                   "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
                   "    expected_trigger:\n      recurrence: custom_cron\n      enabled: true\n"
                   '      cron_utc: ""\n')
    assert cc.main() == 1
    assert "cron_utc must be a non-empty string" in capsys.readouterr().out


# ---- check D: the 'multiple distinct deadline literals' branch (only the single-literal path was hit) ----
def test_check_d_multiple_distinct_deadline_literals_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence_sql.write_text(
        "STRUCT('D1'  AS routine, 'daily_trading' AS schedule)\n"
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')\n"
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '22:00:00')\n")
    assert cc.main() == 1
    assert "multiple distinct deadline literals" in capsys.readouterr().out


# ---- monitor_class presence + vocabulary; duplicate plan-heading detection ----
def test_missing_monitor_class_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n  - id: D1\n    catchup_safe: true\n")  # monitor_class omitted entirely
    assert cc.main() == 1
    assert "missing monitor_class in ops/cadence.yaml" in capsys.readouterr().out


def test_bad_monitor_class_vocabulary_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n  - id: D1\n    monitor_class: hourly_bogus\n    catchup_safe: true\n")
    assert cc.main() == 1
    assert "monitor_class 'hourly_bogus' not in" in capsys.readouterr().out


def test_duplicate_plan_heading_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## D1. Market Development Scan — deep research\nbody\n")
    assert cc.main() == 1
    assert "duplicate Claude_Task_Plan.md heading for id D1" in capsys.readouterr().out


def test_duplicate_cadence_routine_id_is_caught(tmp_path, monkeypatch, capsys):
    # A copy-pasted routines: entry sharing an id is valid YAML (no parse error) -- load_cadence()'s
    # dict comprehension would otherwise silently keep only the second entry with zero signal.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
        "  - id: D1\n"
        "    monitor_class: daily_all\n"
        "    catchup_safe: true\n"
    )
    assert cc.main() == 1
    assert ("ops/cadence.yaml: duplicate routine id 'D1' — each routine id must appear exactly once"
            in capsys.readouterr().out)


def test_cadence_duplicate_ids_helper_directly(tmp_path, monkeypatch):
    f = tmp_path / "cadence.yaml"
    f.write_text(
        "routines:\n"
        "  - id: D1\n    monitor_class: daily_trading\n"
        "  - id: D2\n    monitor_class: daily_trading\n"
        "  - id: D1\n    monitor_class: daily_all\n"
    )
    monkeypatch.setattr(cc, "CADENCE", str(f))
    assert cc.cadence_duplicate_ids() == ["D1"]


def test_load_cadence_and_duplicate_ids_do_not_crash_on_bare_routines_key(tmp_path, monkeypatch):
    # 2026-07-29: `routines:` with nothing under it parses to {"routines": None} (YAML), not a missing
    # key -- `doc.get("routines", [])`'s default only fires when the KEY is absent, so this exact shape
    # crashed load_cadence() and cadence_duplicate_ids() with TypeError: 'NoneType' object is not
    # iterable pre-fix (confirmed live against the pre-fix `doc.get("routines", [])` idiom). Both now
    # route through lib.routine_manifest.cadence_routines(), which guards the None case.
    f = tmp_path / "cadence.yaml"
    f.write_text("timezone: America/Denver\nroutines:\n")
    monkeypatch.setattr(cc, "CADENCE", str(f))
    assert cc.load_cadence() == {}
    assert cc.cadence_duplicate_ids() == []


# ---- check L: the AR_att 'Daily¹' footnote branch (queue_driven behind a Daily-cadence cell) ----
_AR_ATT_PLAN = (
    "## D1. Market Development Scan — deep research\nbody\n"
    "## Adversarial Review Attacker — regular routine\nbody\n\n"
    "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES\n\n"
    "| ID | Routine | Cadence · Type | reads | writes | out |\n"
    "|---|---|---|---|---|---|\n"
    "| **D1** | Market Development Scan | Daily · research | r | w | Daily.md |\n"
    "| **AR_att** | Adversarial Review Attacker | Daily¹ · regular | r | w | out.md |\n"
    "\n---\n\n"
    # check M now runs unconditionally (2026-08-08); D1 is in EVENING_DAILY_GUARD_IDS, so this
    # fixture needs a valid guard copy too, same as _write_check_fixture's default plan above.
    "Shared Observability guard SAME-DAY DOUBLE-RUN GUARD (CYCLE-AWARE VARIANT):\n"
    + _guard_line("D1") + _guard_line("D2") + _guard_line("D2a")
    + _guard_line("D3") + _guard_line("SL3"))
_AR_ATT_CADENCE = (
    "timezone: America/Denver\n"
    'cadence_watch_deadline_local: "21:00"\n'
    "routine_model: claude-opus-5\n"
    "routines:\n"
    "  - id: D1\n    monitor_class: daily_trading\n    catchup_safe: true\n"
    "  - id: AR_att\n    monitor_class: queue_driven\n    catchup_safe: false\n")
_AR_ATT_SQL15 = (
    "STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — deep research.' AS canonical_instruction),\n"
    "STRUCT('AR_att', 'Read Claude_Task_Plan.md. Perform Adversarial Review Attacker — regular routine.')\n")


def _write_ar_att_fixture(tmp_path, plan_text):
    plan = tmp_path / "Claude_Task_Plan.md"
    plan.write_text(plan_text)
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(_AR_ATT_CADENCE)
    cadence_sql = tmp_path / "12.sql"
    cadence_sql.write_text(
        "STRUCT('D1'  AS routine, 'daily_trading' AS schedule)\n"
        "   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')\n")
    catalog_sql = tmp_path / "15.sql"
    catalog_sql.write_text(_AR_ATT_SQL15)
    return plan, cadence, cadence_sql, catalog_sql


def test_check_l_ar_att_daily_footnote_maps_to_queue_driven(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_ar_att_fixture(tmp_path, _AR_ATT_PLAN)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    assert cc.main() == 0  # 'Daily¹' on AR_att legitimately encodes queue_driven


def test_check_l_ar_att_plain_daily_without_footnote_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_ar_att_fixture(
        tmp_path, _AR_ATT_PLAN.replace("Daily¹ · regular", "Daily · regular"))
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    assert cc.main() == 1
    # plain 'Daily' implies a daily_* class, but AR_att is queue_driven -> the footnote is required.
    assert "ROUTINE INVENTORY cadence cell 'Daily'" in capsys.readouterr().out


# ---- aggregate real-repo sanity check (2026-07-18 audit: collapses five byte-identical
#      `assert cc.main() == 0` tests that were previously scattered under misleading per-check names —
#      test_real_triggers_json_check_passes / test_auto_merge_routine_re_against_real_files_is_clean /
#      test_check_j_against_real_files_is_clean / test_check_k_against_real_files_is_clean /
#      test_check_l_against_real_files_is_clean. All five ran the same unpatched cc.main() against the
#      live repo, so a real-repo regression in ANY check made all five fail identically and misdirected
#      CI triage toward the wrong check letters. One canonical test has identical detection power. ----
def test_main_against_real_repo_is_clean():
    # The real, unmodified ops/cadence.yaml + Claude_Task_Plan.md + bigquery/12/15/24 +
    # ops/triggers.json + ops/trigger_ids.json + .github/workflows/auto-merge-claude.yml must all
    # still agree — the full, unpatched end-to-end happy path.
    assert cc.main() == 0


# ---- check N's _tooling_prefix_hides_version glued-digit fix (HIGH, 2026-07-28): _tooling_prefix_hides_version now also treats a digit GLUED
#      directly onto a NOT_A_MODEL_PREFIXES token (no '-'/'.' separator) as version-shaped, not ordinary
#      tooling. Pre-fix, only a SEPARATED version ('claude-code-5') was recognized -- a digit glued
#      straight on ('claude-code5') fell through both branches of the old check and was silently
#      SUBTRACTED as tooling. Confirmed live pre-fix: a mirror line "The fleet now runs claude-code5
#      today, replacing an older configuration." with routine_model='claude-opus-5' made main() print
#      "CADENCE CONSISTENCY: OK ... matches all mirror sites" and exited 0. Same for claude-code58,
#      claude-cli9, claude-desktop3, claude-agent-sdk7. ----
_GLUED_DIGIT_VERSION_SHAPED_TOOLING_TOKENS = [
    "claude-code5", "claude-code58", "claude-cli9", "claude-desktop3", "claude-agent-sdk7",
]
# Non-regression: a tooling token whose remainder starts with a LETTER (no version signal at all,
# glued or separated) must still be subtracted, exactly as before this fix -- 'claude-codebase' is the
# new case this fix must NOT start flagging (its remainder 'base' starts with a letter, not a digit).
_GLUED_DIGIT_GENUINE_TOOLING_EXTENSION_TOKENS = [
    "claude-code", "claude-codebase", "claude-code-action", "claude-code-settings.json",
    "claude-agent-sdk-python",
]


def test_check_n_defect_b_glued_digit_tooling_prefix_also_flagged(tmp_path, monkeypatch):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    for token in _GLUED_DIGIT_VERSION_SHAPED_TOOLING_TOKENS:
        owner_actions.write_text(f"The fleet now runs {token} today, replacing an older configuration.\n")
        errs, _ = cc.check_model_of_record()
        assert len(errs) == 1 and token in errs[0], (
            f"{token!r} should be FLAGGED (digit glued directly onto tooling prefix, no separator): {errs}")
    for token in _GLUED_DIGIT_GENUINE_TOOLING_EXTENSION_TOKENS:
        owner_actions.write_text(f"See {token} for details.\n")
        errs, _ = cc.check_model_of_record()
        assert errs == [], (
            f"{token!r} should still be SUBTRACTED (genuine tooling extension, non-regression): {errs}")


def test_check_n_defect_b_glued_digit_helper_directly():
    # Same table, asserted straight against the helper functions this fix actually changed -- pins the
    # unit-level contract independently of check_model_of_record()'s line-scanning plumbing.
    for token in _GLUED_DIGIT_VERSION_SHAPED_TOOLING_TOKENS:
        assert not cc._is_subtracted_non_assertion(token), (
            f"{token!r} should NOT be subtracted (version-shaped, glued digit)")
    for token in _GLUED_DIGIT_GENUINE_TOOLING_EXTENSION_TOKENS:
        assert cc._is_subtracted_non_assertion(token), (
            f"{token!r} should be subtracted (genuine tooling extension)")


# ---- check N's MODEL_EXEMPT hyphen-continuation fix (HIGH, 2026-07-28): MODEL_EXEMPT's trailing \b (satisfied by ANY non-word
#      character, including '-') let a LONGER hyphen-continued token that merely STARTS WITH the marker
#      -- a filename or config-key mention like 'model-id-exempt-list.md' or 'model-id-exempt-routines:'
#      -- also match. Since check_model_of_record() skips the ENTIRE line on a MODEL_EXEMPT match, such a
#      false hit silently suppressed a genuine drift reported on the same line. Fixed by replacing the
#      trailing \b with a negative lookahead, `(?![-\w])`, that additionally rejects a hyphen
#      continuation. ----
def test_check_n_exempt_marker_rejects_hyphen_continuation_per_string():
    # Table asserted directly against the compiled MODEL_EXEMPT regex, one string at a time so a
    # failure names the exact offending string instead of an opaque "some case failed".
    cases = [
        ("model-id-exempt", True),
        ("x model-id-exempt.", True),
        ("marked model-id-exempt, a cite", True),  # natural prose comma
        ("model-id-exempt-list.md", False),
        ("model-id-exempt-routines:", False),
        ("model-id-exemption-only", False),
        ("model-id-exempted", False),
        ("nonmodel-id-exempt", False),
    ]
    for text, should_suppress in cases:
        matched = bool(cc.MODEL_EXEMPT.search(text))
        assert matched == should_suppress, (
            f"{text!r}: expected suppress={should_suppress}, got {matched}")


def test_check_n_exempt_marker_hyphen_continued_filename_does_not_hide_real_drift(tmp_path, monkeypatch):
    # The worst-case consequence of the pre-fix bug: a line with a GENUINE stale id that also happens to
    # mention a hyphen-continued marker-shaped filename ('model-id-exempt-list.md') must still be
    # flagged -- the marker must not accidentally suppress the whole line just because it is a PREFIX of
    # a longer, unrelated hyphenated token.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)  # routine_model: claude-opus-5
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    owner_actions = tmp_path / "OWNER_ACTIONS.md"
    owner_actions.write_text(
        "The fleet upgraded from claude-sonnet-5 last quarter; see model-id-exempt-list.md for the "
        "historical roster.\n")
    monkeypatch.setattr(cc, "OWNER_ACTIONS", str(owner_actions))
    errs, _ = cc.check_model_of_record()
    assert len(errs) == 1 and "claude-sonnet-5" in errs[0]


# ---- check O: state.stalled_runs' `cls` CTE routine list vs ops/cadence.yaml's routine ids, BOTH
# directions (2026-08-08 audit follow-up to bigquery/148). `state.stalled_runs` is the ONLY thing that
# ever raises the `routine_stalled` alert, and its `JOIN cls c USING (routine)` INNER join silently
# drops any routine id absent from the hand-maintained `cls` list before the terminal-row check or
# elapsed-hours threshold ever run -- exactly what let OPS0/OPS1/OPS2 hang undetected for weeks after
# being added to ops/cadence.yaml with no matching `cls` edit. Fixture tests reuse _write_check_fixture
# / _patch_fixture_paths (which now also drops a matching, auto-generated stalled_runs fixture into the
# SAME tmp_path via _write_stalled_runs_fixture -- see that helper and _patch_fixture_paths's own
# comment), so check O stays clean by default and these tests only need to introduce ONE deliberate
# drift each. ----
def test_check_o_against_real_repo_matches_cadence_yaml():
    # Direct parser-level assertion against the real repo (complements test_main_against_real_repo_is_
    # clean's aggregate main()==0 with a targeted check of check O's own parser): the canonical
    # bigquery/*.sql file's `cls` CTE ids must equal ops/cadence.yaml's routine ids exactly, in both
    # directions, and resolution must find a real, unambiguous file.
    cls_ids, number, fn, ambiguous = cc.parse_stalled_runs_cls_ids()
    assert ambiguous is None
    assert fn is not None and number is not None
    assert cls_ids  # non-empty -- exercises the vacuity guard's happy path on the real repo
    assert set(cls_ids) == set(cc.load_cadence())


def test_check_o_cadence_routine_missing_from_cls_is_caught(tmp_path, monkeypatch, capsys):
    # THE regression test for the actual bug: a routine added to ops/cadence.yaml with no matching edit
    # to state.stalled_runs' `cls` CTE (the OPS0/OPS1/OPS2 gap) must be caught, not silently pass.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # _patch_fixture_paths already wrote a stalled_runs fixture matching cadence.yaml's DEFAULT routine
    # set ({D1}) at patch time. Add W5 to cadence.yaml now, WITHOUT touching that (now-stale) cls
    # fixture file -- reproducing the real defect exactly: a routine present in cadence.yaml but never
    # mirrored into `cls`.
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routine_model: claude-opus-5\n"
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"
        "    catchup_safe: true\n"
        "  - id: W5\n"
        "    monitor_class: weekly_sun\n"
        "    catchup_safe: true\n"
    )
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## W5. Factbase & Analytics Consolidation — regular routine\nbody\n"
    )
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert ("W5: in ops/cadence.yaml but MISSING from bigquery/900_test_stalled_runs.sql's "
            "state.stalled_runs `cls` CTE" in out)
    assert "OPS0/OPS1/OPS2" in out
    # D1 (still in both cadence.yaml and the stale cls fixture) must NOT be flagged by check O.
    assert "D1: in ops/cadence.yaml but MISSING from" not in out


def test_check_o_cls_extra_routine_not_in_cadence_is_caught(tmp_path, monkeypatch, capsys):
    # The OTHER direction: a stale `cls` entry for a routine no longer in ops/cadence.yaml (retired or
    # renamed) must also be caught.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    # Overwrite the auto-generated cls fixture (which exactly matches cadence.yaml's {D1}) with one
    # carrying an extra id cadence.yaml has never heard of.
    _write_stalled_runs_fixture(tmp_path, ["D1", "ZZ_RETIRED"])
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert ("ZZ_RETIRED: in bigquery/900_test_stalled_runs.sql's state.stalled_runs `cls` CTE but not "
            "a routine id in ops/cadence.yaml" in out)


def test_check_o_vacuity_guard_canonical_file_not_found_errors(tmp_path, monkeypatch, capsys):
    # If NO bigquery/*.sql file defines `CREATE OR REPLACE VIEW state.stalled_runs` at all, check O
    # must ERROR loudly -- never a silent pass (requirement: "a checker that quietly validates nothing
    # is the exact failure class this repo keeps getting bitten by").
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    empty_dir = tmp_path / "empty_bigquery_dir"
    empty_dir.mkdir()
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(empty_dir))
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert ("could not find any bigquery/*.sql file defining `CREATE OR REPLACE VIEW "
            "state.stalled_runs` at all" in out)


def test_check_o_vacuity_guard_empty_cls_list_errors(tmp_path, monkeypatch, capsys):
    # The view IS found, but its `cls` CTE parses to ZERO ids (e.g. a reformat that breaks CLS_CTE_
    # UNNEST_RE or CLS_ENTRY_RE) -- must ERROR, not silently validate nothing.
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    _write_stalled_runs_fixture(tmp_path, [])  # cls CTE present but empty
    assert cc.main() == 1
    out = capsys.readouterr().out
    assert "could not parse any routine id out of state.stalled_runs' `cls` CTE" in out
    assert "DISARMED" in out


# ---- parser-level unit coverage for CLS_CTE_UNNEST_RE / CLS_ENTRY_RE directly (regex-rot guard, same
#      discipline as the other scrapers' "_matches_known_good" / "_empty_on_reformat_is_caught" pairs
#      earlier in this file) ----
def test_parse_stalled_runs_cls_ids_matches_known_good(tmp_path, monkeypatch):
    f = tmp_path / "900_stalled.sql"
    f.write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS\n"
        "WITH cls AS (\n"
        "  SELECT * FROM UNNEST([\n"
        "    STRUCT('D1' AS routine, 6 AS min_stale_hours), STRUCT('W1', 18)\n"
        "  ])\n"
        "),\n"
        "started AS (SELECT 1 AS routine)\n"
        "SELECT * FROM started;\n"
    )
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(tmp_path))
    ids, _number, fn, ambiguous = cc.parse_stalled_runs_cls_ids()
    assert ambiguous is None
    assert fn == "900_stalled.sql"
    assert ids == ["D1", "W1"]


def test_parse_stalled_runs_cls_ids_strips_comments_so_prose_struct_is_ignored(tmp_path, monkeypatch):
    # A commented-out or illustrative STRUCT('X', 6) mentioned in the view's own header prose (bigquery/
    # 148's real header narrates past `cls` entries by name) must never be read as a live entry.
    f = tmp_path / "900_stalled.sql"
    f.write_text(
        "-- e.g. STRUCT('GHOST', 6) is NOT a real entry, just an example in this comment\n"
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS\n"
        "WITH cls AS (\n"
        "  SELECT * FROM UNNEST([\n"
        "    STRUCT('D1' AS routine, 6 AS min_stale_hours)\n"
        "  ])\n"
        "),\n"
        "started AS (SELECT 1 AS routine)\n"
        "SELECT * FROM started;\n"
    )
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(tmp_path))
    ids, _number, _fn, _ambiguous = cc.parse_stalled_runs_cls_ids()
    assert ids == ["D1"]
    assert "GHOST" not in ids


def test_parse_stalled_runs_cls_ids_returns_none_filename_when_view_absent(tmp_path, monkeypatch):
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(tmp_path))  # empty dir, no .sql files
    ids, _number, fn, ambiguous = cc.parse_stalled_runs_cls_ids()
    assert ids == [] and fn is None and ambiguous is None


def test_parse_stalled_runs_cls_ids_resolves_the_highest_numbered_definition(tmp_path, monkeypatch):
    # The view has already moved once for real (bigquery/18 -> bigquery/148); the parser must always
    # resolve to the HIGHEST-numbered file defining it, mirroring find_canonical_cadence_watch_file()'s
    # own superseded-object resolution (check D).
    old = tmp_path / "18_old.sql"
    old.write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS\n"
        "WITH cls AS (\n  SELECT * FROM UNNEST([\n    STRUCT('D1' AS routine, 6 AS min_stale_hours)\n"
        "  ])\n),\nstarted AS (SELECT 1 AS routine)\nSELECT * FROM started;\n"
    )
    new = tmp_path / "148_new.sql"
    new.write_text(
        "CREATE OR REPLACE VIEW `stock-trading-498512.state.stalled_runs` AS\n"
        "WITH cls AS (\n  SELECT * FROM UNNEST([\n    STRUCT('D1' AS routine, 6 AS min_stale_hours), "
        "STRUCT('OPS0', 6)\n  ])\n),\nstarted AS (SELECT 1 AS routine)\nSELECT * FROM started;\n"
    )
    monkeypatch.setattr(cc, "STALLED_RUNS_BIGQUERY_DIR", str(tmp_path))
    ids, number, fn, ambiguous = cc.parse_stalled_runs_cls_ids()
    assert ambiguous is None
    assert number == 148 and fn == "148_new.sql"
    assert ids == ["D1", "OPS0"]

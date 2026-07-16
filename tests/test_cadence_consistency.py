"""Guard the cadence single-source GATE's own parsers (stack review 2026-06-24, RUNBOOK §25 C2).

scripts/check_cadence_consistency.py scrapes routine→class and routine→instruction maps out of the
hand-formatted bigquery/12 + 15 SQL with regexes. If a benign SQL reformat makes a regex stop matching,
the check can pass VACUOUSLY for the changed side — exactly the §22-class drift the gate exists to catch.
These tests feed known-good and deliberately-drifted snippets and assert the parsers behave, so a regex
that rots is caught by CI instead of silently disarming the gate.

No warehouse, no creds — pure offline parser tests (run in the always-on `test` job).
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_cadence_consistency.py")
    spec = importlib.util.spec_from_file_location("check_cadence_consistency", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cc = _load()


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
    plan.write_text("## D1. Market Development Scan — deep research\nbody\n")
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
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


def _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql):
    monkeypatch.setattr(cc, "PLAN", str(plan))
    monkeypatch.setattr(cc, "CADENCE", str(cadence))
    monkeypatch.setattr(cc, "CADENCE_SQL", str(cadence_sql))
    monkeypatch.setattr(cc, "CATALOG_SQL", str(catalog_sql))
    monkeypatch.setattr(cc, "PERIOD_WATCH_SQL", str(tmp_path / "absent.sql"))
    monkeypatch.setattr(cc, "TRIGGERS_JSON", str(tmp_path / "absent_triggers.json"))
    monkeypatch.setattr(cc, "TRIGGER_IDS_JSON", str(tmp_path / "absent_trigger_ids.json"))
    monkeypatch.setattr(cc, "AUTO_MERGE_YML", str(tmp_path / "absent_auto_merge.yml"))
    # checks J/K/L's dependent files are absent in this minimal fixture (same "skip silently"
    # convention as PERIOD_WATCH_SQL above for check E/J) — the plan fixture also has no ROUTINE
    # INVENTORY heading, so check L skips too (parse_inventory_table returns None).
    monkeypatch.setattr(cc, "CATCHUP_NOTIFY_SQL", str(tmp_path / "absent_31.sql"))
    monkeypatch.setattr(cc, "CATCHUP_AUTOFIRE_SQL", str(tmp_path / "absent_59.sql"))


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


def test_real_triggers_json_check_passes(tmp_path, monkeypatch):
    # Sanity: the real, unmodified ops/triggers.json + cadence.yaml + Claude_Task_Plan.md must
    # still agree (this exercises check F's happy path end to end, not just the fixture).
    assert cc.main() == 0


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
    auto_merge = tmp_path / "auto-merge.yml"
    auto_merge.write_text("routine_re='^(D1|D2|D3)$'\n")
    monkeypatch.setattr(cc, "AUTO_MERGE_YML", str(auto_merge))
    assert cc.main() == 0


def test_auto_merge_routine_re_against_real_files_is_clean():
    # The real ops/cadence.yaml + .github/workflows/auto-merge-claude.yml must already agree.
    assert cc.main() == 0


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


def test_check_j_against_real_files_is_clean():
    assert cc.main() == 0


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


def test_check_k_missing_catchup_safe_key_is_caught(tmp_path, monkeypatch, capsys):
    plan, cadence, cadence_sql, catalog_sql = _write_check_fixture(tmp_path)
    _patch_fixture_paths(monkeypatch, tmp_path, plan, cadence, cadence_sql, catalog_sql)
    cadence.write_text(
        "timezone: America/Denver\n"
        'cadence_watch_deadline_local: "21:00"\n'
        "routines:\n"
        "  - id: D1\n"
        "    monitor_class: daily_trading\n"  # no catchup_safe key at all
    )
    assert cc.main() == 1
    assert "missing catchup_safe boolean" in capsys.readouterr().out


def test_check_k_against_real_files_is_clean():
    assert cc.main() == 0


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


def test_check_l_against_real_files_is_clean():
    assert cc.main() == 0


# ---- scripts/gen_routine_lists.py: --write / --check round trip (ARCH-3 Item 30b) ----
def _load_gen():
    import importlib.util
    path = os.path.join(ROOT, "scripts", "gen_routine_lists.py")
    spec = importlib.util.spec_from_file_location("gen_routine_lists", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _write_gen_fixture(tmp_path):
    plan = tmp_path / "plan.md"
    plan.write_text(
        "## D1. Market Development Scan — deep research\nbody\n"
        "## W1. Catalyst Calendar (A, C) — deep research\nbody\n"
    )
    cadence = tmp_path / "cadence.yaml"
    cadence.write_text(
        "timezone: America/Denver\n"
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
    return plan, cadence, sql12, sql15, sql24


def _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24):
    monkeypatch.setattr(gen, "PLAN", str(plan))
    monkeypatch.setattr(gen, "CADENCE", str(cadence))
    monkeypatch.setattr(gen, "CADENCE_MONITOR_SQL", str(sql12))
    monkeypatch.setattr(gen, "ROUTINE_CATALOG_SQL", str(sql15))
    monkeypatch.setattr(gen, "PERIOD_WATCH_SQL", str(sql24))


def test_gen_routine_lists_write_then_check_is_clean(tmp_path, monkeypatch):
    gen = _load_gen()
    plan, cadence, sql12, sql15, sql24 = _write_gen_fixture(tmp_path)
    _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24)
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
    gen = _load_gen()
    plan, cadence, sql12, sql15, sql24 = _write_gen_fixture(tmp_path)
    _patch_gen_paths(monkeypatch, gen, plan, cadence, sql12, sql15, sql24)
    for path, body in gen.build_targets():
        gen.write_region(path, body)
    # delete W1 from cadence.yaml (simulating drift) without re-running --write
    cadence.write_text(
        "timezone: America/Denver\n"
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
    # The real, already-normalized bigquery/12/15/24 must be a byte-level no-op for --write, and
    # --check must pass clean (proves the generator reproduces today's 30-routine state exactly).
    gen = _load_gen()
    changed = [path for path, body in gen.build_targets() if gen.write_region(path, body)]
    assert changed == []
    for path, body in gen.build_targets():
        assert gen.current_region(path) == gen.wanted_region(body)

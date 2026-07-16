"""Guard the roster single-source GATE itself (ITEM 5, 2026-07-11 — CI gate for autonomous roster
mutations had ZERO tests; 2 of the 9 SISA-day bugs were in scripts/check_roster_consistency.py).

scripts/check_roster_consistency.py scrapes strategy/roster.yaml + bigquery/35_strategy_arsenal.sql's
seed block + Strategy.md + strategy/ slices + Claude_Task_Plan.md with regexes, and forbids bare
roster literals / fixed divisors in the live derived SQL. If a regex rots, or a perturbation slips
through, the gate can PASS VACUOUSLY exactly where it exists to fail loudly (RUNBOOK, autonomy
kill-triggers). This mirrors tests/test_cadence_consistency.py's exact pattern: copy the REAL repo
fixtures into tmp_path, run main() against the real repo unmodified (must be OK), then perturb one
surface at a time and assert the run fails with the expected check id (R-A / R-B / R-C / R-D / R-E).

No warehouse, no creds — pure offline fixture/parser tests (run in the always-on `test` job).
"""
import importlib.util
import os
import shutil

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load():
    path = os.path.join(ROOT, "scripts", "check_roster_consistency.py")
    spec = importlib.util.spec_from_file_location("check_roster_consistency", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


rc = _load()


# ---- fixture scaffolding: copy the REAL repo files into tmp_path, then let each test mutate ----
REAL_PATHS = {
    "ROSTER": rc.ROSTER,
    "STRATEGY_MD": rc.STRATEGY_MD,
    "PLAN": rc.PLAN,
    "CADENCE": rc.CADENCE,
    "ARSENAL_SQL": rc.ARSENAL_SQL,
}
REAL_DERIVED_LIVE_SQL = list(rc.DERIVED_LIVE_SQL)
REAL_DBT_RECONCILE = rc.DBT_RECONCILE
REAL_DBT_SCHEMA_ACCEPTED_VALUES = rc.DBT_SCHEMA_ACCEPTED_VALUES
REAL_STRATEGY_DIR = rc.STRATEGY_DIR
REAL_STRATEGY_MATH_DIR = rc.STRATEGY_MATH_DIR
REAL_C_OPTIONS_MATH = rc.C_OPTIONS_MATH


@pytest.fixture
def repo_copy(tmp_path, monkeypatch):
    """Copy every file/dir the checker reads into tmp_path and repoint the module's module-level
    path constants at the copies, exactly like test_cadence_consistency.py monkeypatches CADENCE_SQL
    etc. — so each test can mutate ONE surface and leave the rest identical to the real repo."""
    dst_root = tmp_path / "repo"
    dst_root.mkdir()

    # strategy/ (roster.yaml + the slices) as a whole directory.
    shutil.copytree(REAL_STRATEGY_DIR, dst_root / "strategy")
    monkeypatch.setattr(rc, "ROSTER", str(dst_root / "strategy" / "roster.yaml"))
    monkeypatch.setattr(rc, "STRATEGY_DIR", str(dst_root / "strategy"))

    # top-level single files.
    shutil.copy(REAL_PATHS["STRATEGY_MD"], dst_root / "Strategy.md")
    monkeypatch.setattr(rc, "STRATEGY_MD", str(dst_root / "Strategy.md"))
    shutil.copy(REAL_PATHS["PLAN"], dst_root / "Claude_Task_Plan.md")
    monkeypatch.setattr(rc, "PLAN", str(dst_root / "Claude_Task_Plan.md"))
    shutil.copy(REAL_PATHS["CADENCE"], dst_root / "cadence.yaml")
    monkeypatch.setattr(rc, "CADENCE", str(dst_root / "cadence.yaml"))

    # bigquery/35 (the seed) — needs to live in a "bigquery" dir name only insofar as the module
    # just uses the absolute path constant; no relative-path assumptions inside check_roster_consistency.
    (dst_root / "bigquery").mkdir()
    shutil.copy(REAL_PATHS["ARSENAL_SQL"], dst_root / "bigquery" / "35_strategy_arsenal.sql")
    monkeypatch.setattr(rc, "ARSENAL_SQL", str(dst_root / "bigquery" / "35_strategy_arsenal.sql"))

    # the roster-derived live SQL files (R-B) + the dbt reconcile test (R-C).
    derived_copies = []
    for src in REAL_DERIVED_LIVE_SQL:
        dst = dst_root / "bigquery" / os.path.basename(src)
        shutil.copy(src, dst)
        derived_copies.append(str(dst))
    monkeypatch.setattr(rc, "DERIVED_LIVE_SQL", derived_copies)

    (dst_root / "dbt_tests").mkdir()
    dbt_dst = dst_root / "dbt_tests" / "assert_cash_flows_reconcile.sql"
    shutil.copy(REAL_DBT_RECONCILE, dbt_dst)
    monkeypatch.setattr(rc, "DBT_RECONCILE", str(dbt_dst))

    # dbt/models/analytics/schema.yml (R-G's accepted_values(strategy) cross-check).
    (dst_root / "dbt_models_analytics").mkdir()
    schema_dst = dst_root / "dbt_models_analytics" / "schema.yml"
    shutil.copy(REAL_DBT_SCHEMA_ACCEPTED_VALUES, schema_dst)
    monkeypatch.setattr(rc, "DBT_SCHEMA_ACCEPTED_VALUES", str(schema_dst))

    # strategy_math/ package + c_options_math.py (R-F spec_hash inputs) — copied so a test can mutate
    # a math module and have spec_hash_inputs() (a function re-reading these monkeypatched constants,
    # not a frozen dict built from the real ROOT) actually see the mutated copy.
    shutil.copytree(REAL_STRATEGY_MATH_DIR, dst_root / "strategy_math")
    monkeypatch.setattr(rc, "STRATEGY_MATH_DIR", str(dst_root / "strategy_math"))
    shutil.copy(REAL_C_OPTIONS_MATH, dst_root / "c_options_math.py")
    monkeypatch.setattr(rc, "C_OPTIONS_MATH", str(dst_root / "c_options_math.py"))

    return dst_root


def _read(p):
    return open(p, encoding="utf-8").read()


def _write(p, text):
    open(p, "w", encoding="utf-8").write(text)


# ---- (a) the real repo passes cleanly, unmodified ----
def test_real_repo_is_consistent():
    assert rc.main() == 0


# ---- (a2) the fixture-copy harness itself reproduces a clean pass (sanity: copies == real inputs) ----
def test_repo_copy_fixture_also_passes(repo_copy):
    assert rc.main() == 0


# ---- (b1) wrong seed-tuple order: SEED_ROW must capture to_state, not from_state ----
def test_seed_row_from_state_to_state_swap_is_caught(repo_copy):
    # A PAPER->PROBE-shaped row for a hypothetical 'Z' code where the writer put the code where
    # from_state should be does not apply here directly; instead exercise the documented regression:
    # a literal tuple row whose to_state slot is swapped with a lifecycle-state-shaped from_state so
    # the parser would (if it regressed to the old first-quoted-token bug) read the WRONG state and
    # silently make 'A' look inactive. We flip A's seed from a clean ADOPTED to a state whose active-ness
    # differs depending on which slot is read: from_state='ADOPTED', to_state='REJECTED'.
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    old = "FROM UNNEST(['A','B','C','D','E']) AS code"
    assert old in txt
    # Replace the founding UNNEST batch (all ADOPTED) with a literal tuple row for 'A' whose from_state
    # is itself a lifecycle-state ('ADOPTED') and whose to_state is 'REJECTED' — after the swap, A is no
    # longer roster-active per the seed, but roster.yaml still says A is adopted -> R-A mismatch.
    new = old.replace("['A','B','C','D','E']", "['B','C','D','E']")
    txt = txt.replace(old, new)
    txt += (
        "\nINSERT INTO `stock-trading-498512.events.strategy_lifecycle` "
        "(event_ts, strategy_code, from_state, to_state, driver_routine, note)\n"
        "SELECT TIMESTAMP(DATE '2026-04-23'), 'A', 'ADOPTED', 'REJECTED', 'test-swap', 'test'\n"
        "FROM (SELECT 1) WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.strategy_lifecycle` "
        "WHERE driver_routine = 'test-swap');\n"
    )
    _write(arsenal, txt)
    rc_code = rc.main()
    assert rc_code == 1


def test_seed_row_regex_captures_to_state_not_from_state_directly():
    # Direct unit-level regression guard (not full main()): SEED_ROW must capture to_state=ADOPTED, not
    # from_state=PAPER, for a realistic PAPER->PROBE-shaped literal row — the exact bug fixed 2026-07-10b.
    snippet = "('F', 'PAPER', 'PROBE', 'SL5', 'graduated')"
    m = rc.SEED_ROW.search(snippet)
    assert m is not None
    assert m.group(1) == "F"
    assert m.group(2) == "PROBE"   # NOT 'PAPER' — the from_state/to_state swap bug this guards against


# ---- (b2) missing Strategy.md '## Strategy' section ----
def test_missing_strategy_md_section_is_caught(repo_copy):
    p = rc.STRATEGY_MD
    txt = _read(p)
    # Remove the '## Strategy E' heading line entirely so headings_in() no longer finds code E,
    # desyncing Strategy.md from roster.yaml's active set.
    new_txt = txt.replace("## Strategy E: Market-neutral narrative-divergence pairs",
                          "## Not A Strategy Heading Anymore E")
    assert new_txt != txt
    _write(p, new_txt)
    assert rc.main() == 1


# ---- (b3) UNNEST-literal vs literal-row drift (seed set != roster.yaml set) ----
def test_unnest_seed_drift_from_roster_yaml_is_caught(repo_copy):
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    old = "FROM UNNEST(['A','B','C','D','E']) AS code"
    assert old in txt
    # Drop 'E' from the seed batch so the seed set is {A,B,C,D} while roster.yaml/Strategy.md/slices
    # all still say {A,B,C,D,E}.
    _write(arsenal, txt.replace(old, "FROM UNNEST(['A','B','C','D']) AS code"))
    assert rc.main() == 1


# ---- (b4) a bare ['A'..'E'] literal reintroduced in derived SQL (R-B) ----
def test_bare_literal_reintroduced_in_derived_sql_is_caught(repo_copy):
    target = [p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql")][0]
    txt = _read(target)
    txt += "\n-- regression: someone reintroduced a bare roster literal\nSELECT * FROM UNNEST(['A','B','C','D','E']) AS strat;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b5) a '/5' divisor reintroduced in derived SQL (R-B) ----
def test_fixed_divisor_reintroduced_in_derived_sql_is_caught(repo_copy):
    target = [p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql")][0]
    txt = _read(target)
    txt += "\n-- regression: someone hardcoded an equal split again\nSELECT amount / 5 AS per_strategy_amount FROM t;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b6) a '/5' divisor reintroduced in the dbt reconcile test (R-C) ----
def test_fixed_divisor_reintroduced_in_dbt_reconcile_is_caught(repo_copy):
    p = rc.DBT_RECONCILE
    txt = _read(p)
    txt += "\n-- regression: hardcoded roster size\nSELECT amount / 5 AS expected_share FROM cash_flows\n"
    _write(p, txt)
    assert rc.main() == 1


# ---- (b7) roster.yaml active-set mismatch vs the seed (drop a strategy from roster.yaml only) ----
def test_roster_yaml_active_set_mismatch_vs_seed_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    # Flip strategy D's roster_state from adopted to rejected in roster.yaml ONLY (leave the bigquery/35
    # seed, Strategy.md, slices, and the plan slice-map all saying D is still active) -> R-A mismatch.
    old = (
        "  - code: D\n"
        '    name: "Long-horizon narrative-screened equity core"\n'
        "    archetype: long-horizon-concentrated-equity\n"
        "    roster_state: adopted\n"
    )
    assert old in txt, "fixture assumption about roster.yaml's D block shape drifted — update this test"
    new = old.replace("roster_state: adopted", "roster_state: rejected")
    _write(p, txt.replace(old, new))
    assert rc.main() == 1


# ---- (b8) R-D: per_strategy_routine names a routine id not in ops/cadence.yaml ----
def test_per_strategy_routine_not_in_cadence_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    old = "  - code: D\n"
    assert old in txt
    # D currently has per_strategy_routine: null — give it a bogus routine id that cadence.yaml
    # definitely does not define.
    old_field = (
        "    per_strategy_routine: null      # D's long-horizon candidate screen runs inside the Q2 quarterly routine,\n"
        "                                    #   not a dedicated per-strategy routine.\n"
    )
    assert old_field in txt, "fixture assumption about D's per_strategy_routine comment shape drifted"
    new_field = "    per_strategy_routine: ZZ_not_a_real_routine\n"
    _write(p, txt.replace(old_field, new_field))
    assert rc.main() == 1


# ---- (b9) R-E: a rails literal disagrees between roster.yaml and bigquery/35's arsenal_rails consts ----
def test_rails_literal_disagreement_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    old = "  n_max: 8                       # roster CEILING"
    assert old in txt
    _write(p, txt.replace(old, "  n_max: 99                      # roster CEILING"))
    assert rc.main() == 1


# ---- (b9b) R-E: a rails key DELETED ENTIRELY from roster.yaml must also be caught, not just a
#      mismatched value — the original loops only compared when the key was present, so deleting
#      it left NOTHING to compare against and R-E vacuously passed (2026-07-14 audit finding).
def test_rails_key_missing_entirely_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    old = "  n_min: 2                       # roster FLOOR: SL4 never proposes retirement below this; a hit\n"
    assert old in txt, "fixture assumption about roster.yaml's n_min line drifted"
    _write(p, txt.replace(old, ""))
    assert rc.main() == 1


# ---- (b5b) R-B: a bare literal split across two lines (a SQL formatter line-wrap) must still be
#      caught — the original line-by-line scan matched neither line (2026-07-14 audit finding).
def test_bare_literal_split_across_lines_is_caught(repo_copy):
    target = [p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql")][0]
    txt = _read(target)
    txt += "\nSELECT * FROM UNNEST(['A',\n  'B','C','D','E']) AS strat;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b5c) R-B: a fixed divisor split across two lines, "amount" on either side of the wrap ----
def test_fixed_divisor_split_across_lines_amount_before_wrap_is_caught(repo_copy):
    target = [p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql")][0]
    txt = _read(target)
    txt += "\nSELECT amount /\n  5 AS per_strategy_amount FROM t;\n"
    _write(target, txt)
    assert rc.main() == 1


def test_fixed_divisor_split_across_lines_amount_after_wrap_is_caught(repo_copy):
    target = [p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql")][0]
    txt = _read(target)
    txt += "\nSELECT x /\n  5 AS amount_per_strategy FROM t;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b6b) R-C: the adjacency guard must not false-fail on unrelated slash-digit prose ----
def test_unrelated_slash_digit_comment_does_not_false_fail_r_c(repo_copy):
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + "\n-- see RUNBOOK section 5/6 for the tolerance rationale\n")
    assert rc.main() == 0


# ---- (b10) R-A: Claude_Task_Plan.md slice-map row removed for a still-active code ----
def test_missing_slicemap_row_is_caught(repo_copy):
    p = rc.PLAN
    txt = _read(p)
    old = "| **M2** (E) | `07_strategy_e.md` + `01` | other strategy slices |\n"
    assert old in txt, "fixture assumption about the plan's M2/E slice-map row shape drifted"
    _write(p, txt.replace(old, ""))
    assert rc.main() == 1


# ---- (b11) R-A: a strategy/ slice's own heading drifts to [CANDIDATE], desyncing from roster.yaml ----
def test_slice_heading_marked_candidate_desyncs_from_roster_is_caught(repo_copy):
    slice_path = os.path.join(rc.STRATEGY_DIR, "07_strategy_e.md")
    txt = _read(slice_path)
    old = "## Strategy E: Market-neutral narrative-divergence pairs"
    assert old in txt
    _write(slice_path, txt.replace(old, "## Strategy E [CANDIDATE]: Market-neutral narrative-divergence pairs"))
    assert rc.main() == 1


# ---- (b12) R-F: a spec-locked strategy's declared spec_hash no longer matches its .md + module (ITEM
# 28 self-improvement audit, coverage gap closed 2026-07-11 adversarial self-audit — R-F had ZERO tests) ----
def test_spec_hash_mismatch_on_own_module_is_caught(repo_copy):
    # Mutate strategy_a.py itself (not common.py) — the simplest single-file drift case.
    p = os.path.join(rc.STRATEGY_MATH_DIR, "strategy_a.py")
    txt = _read(p)
    _write(p, txt + "\n# regression: locked machinery edited post spec-lock\n")
    assert rc.main() == 1


def test_spec_hash_mismatch_on_shared_common_py_is_caught(repo_copy):
    # BUG-FIX regression guard: common.py (imported by strategy_a/b/d/e.py) must be part of every
    # dependent strategy's hash — this is exactly the bug the 2026-07-11 adversarial self-audit found
    # and fixed (common.py was silently omitted from the original hash inputs).
    p = os.path.join(rc.STRATEGY_MATH_DIR, "common.py")
    txt = _read(p)
    _write(p, txt + "\n# regression: shared math module edited post spec-lock\n")
    assert rc.main() == 1


def test_spec_hash_mismatch_on_c_options_math_is_caught(repo_copy):
    # C's math module lives at repo root (c_options_math.py), not in strategy_math/ — a separate path
    # constant (C_OPTIONS_MATH), separately monkeypatchable; exercise it too.
    p = rc.C_OPTIONS_MATH
    txt = _read(p)
    _write(p, txt + "\n# regression: C's math module edited post spec-lock\n")
    assert rc.main() == 1


def test_spec_hash_missing_on_spec_locked_strategy_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    old = '    spec_hash: "8503569a0b6dfc6a252141472d806b170fa7c73287187ebb7d3a8238de4a4eda"   # sha256(strategy/03_strategy_a.md || strategy_math/strategy_a.py || strategy_math/common.py), rev 2026-07-11 R-F\n'
    assert old in txt, "fixture assumption about A's spec_hash line shape/value drifted — update this test"
    _write(p, txt.replace(old, ""))
    assert rc.main() == 1


def test_spec_hash_wrong_value_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    old = "8503569a0b6dfc6a252141472d806b170fa7c73287187ebb7d3a8238de4a4eda"
    assert old in txt, "fixture assumption about A's spec_hash value drifted — update this test"
    _write(p, txt.replace(old, "0" * 64))
    assert rc.main() == 1


# ---- (b13) R-F: a spec-locked strategy with NO spec_hash_inputs() entry is a visible NOTE, not a FAIL
# (must not become a de facto CI gate on SISA's autonomous strategy promotion — CLAUDE.md settled
# decision) ----
def test_spec_locked_strategy_without_math_module_is_a_non_blocking_note(repo_copy, capsys):
    p = rc.ROSTER
    txt = _read(p)
    # Append a hypothetical strategy 'F', incubating (roster_state: shadow -> NOT roster-active, so this
    # cannot trip R-A/R-B/etc.) but already spec_locked_since (SISA's SHADOW-entry freeze doctrine) —
    # and, realistically, with no strategy_math/strategy_f.py, since SL2 does not generate one today.
    fake_strategy = (
        "\n  - code: F\n"
        '    name: "Test-only hypothetical strategy (no math module)"\n'
        "    archetype: test-only\n"
        "    roster_state: shadow\n"
        "    edges_exploited: []\n"
        "    disadvantages_compensated: []\n"
        "    per_strategy_routine: null\n"
        "    adopted_date: null\n"
        "    spec_locked_since: 2026-07-11\n"
        "    immutable_since: null\n"
        "    retired_date: null\n"
        "    is_restart_of: null\n"
        "    revision_history:\n"
        "      - date: 2026-07-11\n"
        '        note: "test fixture only"\n'
    )
    _write(p, txt + fake_strategy)
    rc_code = rc.main()
    out = capsys.readouterr().out
    assert rc_code == 0, "a spec-locked strategy missing from spec_hash_inputs() must NOT fail the build"
    assert "'F'" in out and "no spec_hash_inputs() entry" in out


# ---- (b14) R-G: dbt schema.yml accepted_values(strategy) drifts from the roster-active set ----
def test_schema_yml_accepted_values_drift_is_caught(repo_copy):
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    old = "values: ['A', 'B', 'C', 'D', 'E']"
    assert txt.count(old) >= 1, "fixture assumption about schema.yml's accepted_values lists drifted"
    _write(p, txt.replace(old, "values: ['A', 'B', 'C', 'D']", 1))
    assert rc.main() == 1


def test_schema_yml_unrelated_accepted_values_block_is_not_flagged(repo_copy):
    # conviction_features.decision's accepted_values(['GO']) must never be compared against the
    # roster set — R-G only inspects columns literally named `strategy`.
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    assert "values: ['GO']" in txt, "fixture assumption about the decision column's accepted_values drifted"
    assert rc.main() == 0


# ---- R-H: candidate-feed dataset name (2026-07-15 self-improvement audit) ----
def test_events_strategy_candidates_in_plan_is_caught(repo_copy):
    # the live table is state.strategy_candidates; a stray events.strategy_candidates reference in
    # Claude_Task_Plan.md must fail CI.
    p = rc.PLAN
    txt = _read(p)
    assert "state.strategy_candidates" in txt, "fixture assumption about PLAN's candidate-feed name drifted"
    _write(p, txt.replace("state.strategy_candidates", "events.strategy_candidates", 1))
    assert rc.main() == 1


def test_events_strategy_candidates_in_cadence_is_caught(repo_copy):
    p = rc.CADENCE
    txt = _read(p)
    assert "state.strategy_candidates" in txt, "fixture assumption about cadence.yaml's candidate-feed name drifted"
    _write(p, txt.replace("state.strategy_candidates", "events.strategy_candidates", 1))
    assert rc.main() == 1


# ---- skip semantics: pre-2026-07-10 checkout without strategy/roster.yaml is a clean SKIP ----
def test_missing_roster_yaml_is_a_clean_skip(repo_copy):
    os.remove(rc.ROSTER)
    assert rc.main() == 0


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))

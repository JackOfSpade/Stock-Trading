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
import re
import os
import shutil

import pytest

from conftest import load_module_from_path

rc = load_module_from_path("check_roster_consistency", "scripts", "check_roster_consistency.py")


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
REAL_SCENARIOS_YAML = rc.SCENARIOS_YAML
REAL_DECLARED_FREQUENCY_SQL = rc.DECLARED_FREQUENCY_SQL


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
    # R-F's shared locked prose and combined pre-mortem source are distinct module-level paths, not
    # inferred by the legacy spec_hash_inputs() map. Repoint both so a provenance test mutates only the
    # copied fixture, never the real working tree.
    monkeypatch.setattr(rc, "SHARED_LOCKED_OPERATIONAL_PROSE", tuple(
        str(dst_root / "strategy" / name) for name in (
            "00_preamble.md",
            "01_shared_regime_vocabulary.md",
            "02_regime_router.md",
            "09_regime_scoring_strategy_blind_monthly.md",
        )))
    monkeypatch.setattr(rc, "PRE_MORTEMS", str(dst_root / "strategy" / "08_pre_mortems.md"))

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

    # bigquery/166 (R-L's declared-frequency seed source) — a separately monkeypatchable copy, mirroring
    # ARSENAL_SQL above, so a shape-rot / coverage-gap test can mutate it without touching the real repo
    # file (roster#1 test-quality fix, 2026-08-31 code-quality pass — R-L previously had zero test coverage).
    freq_dst = dst_root / "bigquery" / os.path.basename(REAL_DECLARED_FREQUENCY_SQL)
    shutil.copy(REAL_DECLARED_FREQUENCY_SQL, freq_dst)
    monkeypatch.setattr(rc, "DECLARED_FREQUENCY_SQL", str(freq_dst))

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

    # tests/golden_scenarios/scenarios.yaml (R-K's prose-regression coverage source). Copied + repointed
    # so an R-K perturbation test can overwrite/remove it in the tmp repo without touching the real
    # fixture set — repo_copy previously left rc.SCENARIOS_YAML pointing at the real file, so R-K was
    # untestable and every repo_copy test silently read the real scenarios (2026-07-17 audit).
    (dst_root / "golden_scenarios").mkdir()
    scen_dst = dst_root / "golden_scenarios" / "scenarios.yaml"
    shutil.copy(REAL_SCENARIOS_YAML, scen_dst)
    monkeypatch.setattr(rc, "SCENARIOS_YAML", str(scen_dst))

    return dst_root


def _scenarios_covering(codes):
    """Build a minimal valid scenarios.yaml body giving prose-mention (path b) coverage to exactly the
    given roster codes — used to drive R-K to a known covered-set without editing the real 23-fixture set."""
    lines = ["scenarios:"]
    for c in codes:
        lines += [
            f"  - id: cover-{c}",
            f"    situation: Strategy {c} decision setup with concrete facts.",
            "    governing_files: [Strategy.md]",
            "    expected_decision: ACTIVATE",
            f"    rationale: Strategy {c} activation rule applies.",
        ]
    return "\n".join(lines) + "\n"


def _shadow_f_entry():
    """A minimal SHADOW roster entry for a hypothetical strategy F (not roster-active, not spec-locked)
    to append to roster.yaml — used by the R-K SHADOW/PAPER-enforcement tests."""
    return (
        "\n  - code: F\n"
        '    name: "Shadow test strategy"\n'
        "    archetype: test-only\n"
        "    roster_state: shadow\n"
        "    edges_exploited: []\n"
        "    disadvantages_compensated: []\n"
        "    per_strategy_routine: null\n"
        "    adopted_date: null\n"
        "    spec_locked_since: null\n"
        "    immutable_since: null\n"
        "    retired_date: null\n"
        "    is_restart_of: null\n"
    )


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


def test_unnest_seed_batch_captures_to_state_not_from_state(repo_copy):
    # #2 (2026-07-17 audit): the UNNEST-batch state extraction must read to_state, NOT from_state, on
    # a batch whose from_state is a real quoted state — the identical swap SEED_ROW is already guarded
    # against (above), left unpatched on the UNNEST path. Append a batch retiring A (from_state=
    # 'ADOPTED', to_state='TERMINATED'); the later to_state must win, dropping A from the active set.
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    txt += (
        "\nINSERT INTO `stock-trading-498512.events.strategy_lifecycle` "
        "(event_ts, strategy_code, from_state, to_state, driver_routine, note)\n"
        "SELECT TIMESTAMP(DATE '2026-08-01'), code, 'ADOPTED', 'TERMINATED', 'test-retire', 'test'\n"
        "FROM UNNEST(['A']) AS code "
        "WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.strategy_lifecycle` "
        "WHERE driver_routine = 'test-retire');\n"
    )
    _write(arsenal, txt)
    active, _n = rc.seed_active_codes()
    # The old first-quoted-token bug would read from_state 'ADOPTED' and keep A active.
    assert active == {"B", "C", "D", "E"}
    # End-to-end this surfaces as an R-A mismatch (roster.yaml still says A is adopted).
    assert rc.main() == 1


# ---- roster_active_codes(): a roster.yaml entry missing 'code' must not crash (roster-group audit,
#      2026-08-08 — was `s["code"]`, an uncaught KeyError that killed the checker before it ever
#      reached the error-collection/report step this file's other R-checks rely on) ----
def test_roster_active_codes_missing_code_field_does_not_crash():
    doc = {"strategies": [
        {"roster_state": "adopted"},                 # no 'code' key at all -- must not raise KeyError
        {"code": "", "roster_state": "probe"},        # falsy code -- must not be treated as a real code
        {"code": "A", "roster_state": "adopted"},
    ]}
    assert rc.roster_active_codes(doc) == {"A"}


def test_missing_code_field_on_active_entry_is_a_clean_fail_not_a_crash(repo_copy, capsys):
    # End-to-end: strip strategy D's 'code' key from roster.yaml but leave its roster_state (adopted)
    # and every other surface (bigquery/35 seed, Strategy.md, slices, plan slice-map) unmodified. D
    # then silently drops out of roster_codes, so R-A's ordinary set-comparison (not a bespoke message)
    # catches it as "'D' in <surface> but not roster.yaml" -- a clean FAIL, not an uncaught traceback.
    p = rc.ROSTER
    txt = _read(p)
    old = "  - code: D\n    name:"
    assert old in txt, "fixture assumption about roster.yaml's D block shape drifted"
    _write(p, txt.replace(old, "  - name:", 1))
    assert rc.main() == 1               # must NOT raise KeyError
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out
    assert "'D'" in out


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
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    txt += "\n-- regression: someone reintroduced a bare roster literal\nSELECT * FROM UNNEST(['A','B','C','D','E']) AS strat;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b5) a '/5' divisor reintroduced in derived SQL (R-B) ----
def test_fixed_divisor_reintroduced_in_derived_sql_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
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
    marker = (
        "  - code: D\n"
        '    name: "Long-horizon narrative-screened equity core"\n'
        "    archetype: long-horizon-concentrated-equity\n"
    )
    assert marker in txt, "fixture assumption about roster.yaml's D block shape drifted — update this test"
    # D's roster_state line is the first "    roster_state: adopted\n" AFTER the marker above (fields
    # between archetype and roster_state, e.g. review_cadence, may change shape without breaking this).
    start = txt.index(marker) + len(marker)
    state_line = "    roster_state: adopted\n"
    state_idx = txt.index(state_line, start)
    new_txt = txt[:state_idx] + "    roster_state: rejected\n" + txt[state_idx + len(state_line):]
    _write(p, new_txt)
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
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    txt += "\nSELECT * FROM UNNEST(['A',\n  'B','C','D','E']) AS strat;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b5c) R-B: a fixed divisor split across two lines, "amount" on either side of the wrap ----
def test_fixed_divisor_split_across_lines_amount_before_wrap_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    txt += "\nSELECT amount /\n  5 AS per_strategy_amount FROM t;\n"
    _write(target, txt)
    assert rc.main() == 1


def test_fixed_divisor_split_across_lines_amount_after_wrap_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    txt += "\nSELECT x /\n  5 AS amount_per_strategy FROM t;\n"
    _write(target, txt)
    assert rc.main() == 1


# ---- (b6c) R-C: a fixed divisor split across two lines in the dbt reconcile test (2026-07-17) ----
def test_fixed_divisor_split_across_lines_in_dbt_reconcile_is_caught(repo_copy):
    # #3: R-C now scans full-text like R-B, so a formatter-wrapped `amount /\n  5` divisor in the
    # reconcile test is caught — the old line-by-line scan missed it (vacuous pass).
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + "\nSELECT amount /\n  5 AS expected_share FROM cash_flows\n")
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


def test_spec_hash_mismatch_on_shared_locked_operational_prose_is_caught(repo_copy):
    # The shared preamble governs every frozen strategy but is not in any own strategy slice. Its absence
    # from R-F was a provenance gap: a live doctrine edit could pass without touching any hash input.
    p = rc.SHARED_LOCKED_OPERATIONAL_PROSE[0]
    _write(p, _read(p) + "\n<!-- regression: shared locked operational prose changed -->\n")
    assert rc.main() == 1


def test_spec_hash_mismatch_on_shared_regime_router_slice_is_caught(repo_copy):
    # This shared operative slice is outside every own strategy section, so it needs the same coverage
    # as the preamble rather than relying on incidental strategy-slice changes.
    p = next(path for path in rc.SHARED_LOCKED_OPERATIONAL_PROSE
             if path.endswith("02_regime_router.md"))
    _write(p, _read(p) + "\n<!-- regression: shared router machinery changed -->\n")
    assert rc.main() == 1


def test_spec_hash_mismatch_on_own_pre_mortem_is_caught(repo_copy):
    # Append within A's H3-delimited pre-mortem body (before B's next H3). This must invalidate A's
    # spec_hash even though strategy/03_strategy_a.md and its math module remain byte-identical.
    p = rc.PRE_MORTEMS
    txt = _read(p)
    anchor = "### Pre-mortem: Strategy B"
    assert anchor in txt
    _write(p, txt.replace(anchor,
                          "<!-- regression: A accepted pre-mortem changed -->\n\n" + anchor,
                          1))
    assert rc.main() == 1


def test_spec_hash_mismatch_on_shared_router_pre_mortem_is_caught(repo_copy):
    # The router pre-mortem governs every strategy's activation environment and therefore belongs in
    # every digest, even though it appears before the per-strategy H3 sections.
    p = rc.PRE_MORTEMS
    txt = _read(p)
    anchor = "### Pre-mortem: Strategy A"
    assert anchor in txt
    _write(p, txt.replace(anchor,
                          "<!-- regression: shared router accepted pre-mortem changed -->\n\n" + anchor,
                          1))
    assert rc.main() == 1


def test_spec_hash_pre_mortem_extraction_is_strategy_scoped_and_heading_based(repo_copy):
    # Inserting text in B's segment must not perturb A's digest; using headings rather than line ranges
    # makes this true even though both segments live in one generated file.
    inputs = rc.spec_hash_inputs()
    a_before = rc.compute_spec_hash("A", inputs=inputs)
    b_before = rc.compute_spec_hash("B", inputs=inputs)
    p = rc.PRE_MORTEMS
    txt = _read(p)
    anchor = "### Pre-mortem: Strategy C"
    assert anchor in txt
    _write(p, txt.replace(anchor,
                          "<!-- regression: B pre-mortem insertion -->\n\n" + anchor,
                          1))
    assert rc.compute_spec_hash("A", inputs=inputs) == a_before
    assert rc.compute_spec_hash("B", inputs=inputs) != b_before


def test_spec_hash_pre_mortem_extraction_ignores_h3_examples_inside_code_fences(repo_copy):
    # A fenced Markdown example that looks exactly like A's heading is content in the shared router
    # pre-mortem, not a duplicate A section and not an early section boundary.
    a_before = rc.pre_mortem_segment("A")
    p = rc.PRE_MORTEMS
    txt = _read(p)
    anchor = "### Pre-mortem: Strategy A"
    assert anchor in txt
    fenced_example = "```markdown\n### Pre-mortem: Strategy A\nexample only\n```\n\n"
    _write(p, txt.replace(anchor, fenced_example + anchor, 1))
    assert rc.pre_mortem_segment("A") == a_before


def test_spec_hash_malformed_pre_mortem_heading_is_a_clear_r_f_failure(repo_copy, capsys):
    # A wrong heading depth must not turn into a silent whole-file hash or a traceback.
    p = rc.PRE_MORTEMS
    txt = _read(p)
    old = "### Pre-mortem: Strategy A"
    assert old in txt
    _write(p, txt.replace(old, "#### Pre-mortem: Strategy A", 1))
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "R-F" in out and "malformed required pre-mortem heading" in out


def test_spec_hash_missing_pre_mortem_file_is_a_clear_r_f_failure(repo_copy, capsys):
    os.remove(rc.PRE_MORTEMS)
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "R-F" in out and "08_pre_mortems.md" in out and "is missing" in out


def _first_spec_hash_line(txt):
    """A's spec_hash line, DERIVED not hardcoded.

    These two tests used to pin A's literal hash. That made them a tripwire on every
    legitimate spec_hash recompute (they drifted twice on 2026-08-05 alone, during the
    Rev 43 propagation and again during the CaR-envelope retirement) — a maintenance
    cost with no detection value, since R-F itself already verifies the hash is correct.
    What these tests actually need is "the first strategy's spec_hash line, whatever it
    currently is", so derive it.
    """
    m = re.search(r'^    spec_hash: "([a-f0-9]{64})".*$', txt, re.M)
    assert m, "no spec_hash line found in roster.yaml — fixture assumption genuinely broken"
    return m.group(0) + "\n", m.group(1)


def test_spec_hash_missing_on_spec_locked_strategy_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    line, _ = _first_spec_hash_line(txt)
    _write(p, txt.replace(line, ""))
    assert rc.main() == 1


def test_spec_hash_wrong_value_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    _, value = _first_spec_hash_line(txt)
    _write(p, txt.replace(value, "0" * 64))
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
    # F is a SHADOW strategy, so R-K now enforces golden-scenario coverage for it (2026-07-17: a
    # slice-less SHADOW/PAPER strategy is no longer a non-blocking note — see R-K tests below). Give F
    # coverage via a 'Strategy F' prose mention so the ONLY thing left to observe is R-F's non-blocking
    # spec_hash note (this test's actual subject); otherwise R-K would fail the build for uncovered F.
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCDEF"))
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


# ---- R-G vacuous-pass fix: ALL accepted_values(strategy) blocks DELETED (not just made stale) must
#      still FAIL, not pass vacuously because the inner loop body never ran (roster-group audit,
#      2026-08-08 — see check_roster_consistency.py's `found_blocks` comment) ----
def test_schema_yml_all_accepted_values_strategy_blocks_deleted_is_caught(repo_copy, capsys):
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    block = "          - accepted_values:\n              values: ['A', 'B', 'C', 'D', 'E']\n"
    count = txt.count(block)
    assert count >= 1, "fixture assumption about schema.yml's accepted_values(strategy) block shape drifted"
    # Strip every strategy-column accepted_values block but leave the `strategy` columns and their
    # other tests (not_null/unique) in place — this is "the tests were deleted", not "the file/columns
    # were deleted", the exact gap the found_blocks counter exists to close.
    _write(p, txt.replace(block, "", count))
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out
    assert "R-G" in out and "ZERO accepted_values tests" in out


def test_schema_yml_unrelated_accepted_values_block_is_not_flagged(repo_copy):
    # conviction_features.decision's accepted_values must never be compared against the roster set —
    # R-G only inspects columns literally named `strategy`. Widened 2026-07-30 from ['GO'] to
    # ['GO', 'GO (add tranche)'] when conviction_features moved to a GO-FAMILY filter (bigquery/116);
    # the literal below is a FIXTURE-EXISTENCE guard, so that `main() == 0` below is a real assertion
    # about R-G ignoring this block rather than a vacuous pass once the block no longer exists.
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    assert "values: ['GO', 'GO (add tranche)']" in txt, (
        "fixture assumption about the decision column's accepted_values drifted"
    )
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


# ---- R-I: review_cadence declared for every roster-active strategy (2026-07-15 self-improvement audit) ----
def test_review_cadence_invalid_value_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    assert "review_cadence: reactive" in txt, "fixture assumption about roster.yaml's review_cadence field drifted"
    _write(p, txt.replace("review_cadence: reactive", "review_cadence: bogus_value", 1))
    assert rc.main() == 1


def test_review_cadence_missing_field_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    doc = rc.yaml.safe_load(txt)
    strat_a = next(s for s in doc["strategies"] if s["code"] == "A")
    assert strat_a.get("review_cadence") == "reactive", "fixture assumption about strategy A's review_cadence drifted"
    del strat_a["review_cadence"]
    _write(p, rc.yaml.dump(doc, sort_keys=False))
    assert rc.main() == 1


def test_review_cadence_valid_values_pass(repo_copy):
    # sanity: both valid values are accepted, not just the real repo's current mix.
    p = rc.ROSTER
    txt = _read(p)
    assert "review_cadence: long_horizon" in txt, "fixture assumption about strategy D's review_cadence drifted"
    assert rc.main() == 0


# ---- skip semantics: pre-2026-07-10 checkout without strategy/roster.yaml is a clean SKIP ----
def test_missing_roster_yaml_is_a_clean_skip(repo_copy):
    os.remove(rc.ROSTER)
    assert rc.main() == 0


# =====================================================================================================
# 2026-07-17 parallel-refactor coverage additions (adversarial-audit findings). Each locks in a
# checker behavior that had no regression test, or a fix landed in this pass.
# =====================================================================================================

# ---- R-B: the widened bare-literal detector catches double-quoted + single-element roster lists that
#      the original single-quote/two-element-minimum pattern silently let through (2026-07-17 fix) ----
def test_bare_literal_double_quoted_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    # BigQuery accepts double-quoted string literals; a re-hardcoded roster written this way used to
    # evade R-B entirely (BARE_LITERAL was single-quote only).
    _write(target, txt + '\nSELECT * FROM UNNEST(["A","B","C","D","E"]) AS strat;\n')
    assert rc.main() == 1


def test_bare_literal_single_element_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    # A subset/special-case hardcode of ONE code (list without a comma) also used to evade the
    # two-element-minimum pattern.
    _write(target, txt + "\nSELECT * FROM UNNEST(['A']) AS strat;\n")
    assert rc.main() == 1


# ---- R-B / R-C: a fixed divisor written leading-operator style (operator at the start of the
#      continuation line, sqlfluff/dbt default) must still be caught — the own-line-only context
#      window missed exactly the wrap it claimed to cover (2026-07-17 fix) ----
def test_leading_operator_divisor_in_derived_sql_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + "\nSELECT SUM(cf.amount)\n  / 5 AS per_strategy FROM t;\n")
    assert rc.main() == 1


def test_leading_operator_divisor_in_dbt_reconcile_is_caught(repo_copy):
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + "\nSELECT SUM(deposit_amount)\n  / 5 AS expected_share FROM cash_flows\n")
    assert rc.main() == 1


# ---- R-B: the "amount"-adjacency SUPPRESSION direction (a `/N` on a line with no money token is
#      ignored) — R-C had this test but R-B's identical guard did not (2026-07-17 audit) ----
def test_unrelated_slash_digit_in_derived_sql_without_amount_does_not_fail(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + "\n-- see RUNBOOK section 5/6 for the split rationale\n")
    assert rc.main() == 0


# ---- R-C: the cash_flow / deposit adjacency alternates (not just 'amount') are exercised ----
def test_fixed_divisor_near_deposit_token_is_caught(repo_copy):
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + "\nSELECT total_deposit / 5 AS share FROM cash_flows\n")
    assert rc.main() == 1


# ---- R-B / R-C: the fixed-divisor-via-ALIASED-money-column fail-open hole (codebase audit
#      2026-07-26 — an auditor reproduced this against the pre-fix code). _divisor_context()'s
#      adjacency window only sees the divisor's own source line(s), never where the money value
#      going into SUM(...) originally came from — so a plain, ordinary restyle that lifts `cf.amount`
#      into a CTE alias before summing carried NO 'amount' token anywhere near the divisor, and the
#      textbook forbidden equal-split `/ 5` sailed through both R-B and R-C clean. These fixtures pin
#      the fix (_money_alias_names() / _money_nearby()): the alias's OWN origin column is what gets
#      checked, not just the divisor's immediate text. ----
def test_fixed_divisor_via_column_alias_in_derived_sql_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- regression: money value reaches the divisor via a column alias, not the bare 'amount' token\n"
        "WITH renamed AS (\n"
        "  SELECT cf.amount AS raw, a.s AS strategy\n"
        "  FROM active a CROSS JOIN cash_flows cf\n"
        "  GROUP BY a.s\n"
        ")\n"
        "SELECT SUM(raw)\n"
        "  / 5 AS equal_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_fixed_divisor_via_column_alias_in_dbt_reconcile_is_caught(repo_copy):
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + (
        "\n-- regression: same aliased-money-column restyle in the dbt reconcile test\n"
        "WITH renamed AS (\n"
        "  SELECT cf.amount AS raw FROM cash_flows cf\n"
        ")\n"
        "SELECT SUM(raw)\n"
        "  / 5 AS expected_share\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


# ---- R-B/R-C: the money column's name only has to CONTAIN a marker, not equal it ----
#      QUALITY PASS 2026-08-22. _money_alias_names() tested `source.lower() in known` — EXACT
#      equality against the markers — while its own partner _money_nearby() has always matched
#      markers by SUBSTRING (`marker in ctx`). The two halves of one guard disagreed, and the alias
#      path was the weaker one: a real money column whose name merely CONTAINS a marker evaded
#      detection the moment it was aliased, reopening the very fail-open hole above.
#
#      `total_deposits` is not a hypothetical name — bigquery/22_cash_flows.sql ships it today, and
#      dbt/tests/assert_cash_flows_reconcile.sql references `strategy_nav_deposits_total`. Every
#      pre-existing alias fixture in this file uses the literal word `amount`, which is exactly why
#      the gap had zero coverage.
def test_fixed_divisor_via_substring_named_money_column_alias_is_caught_in_derived_sql(repo_copy):
    # R-B's marker set is ("amount",), so the money column here CONTAINS 'amount' without being it.
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- regression: the money column CONTAINS 'amount' rather than being exactly 'amount'\n"
        "WITH renamed AS (\n"
        "  SELECT cf.deposit_amount AS td FROM cash_flows cf\n"
        ")\n"
        "SELECT SUM(td)\n"
        "  / 5 AS equal_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_fixed_divisor_via_substring_named_money_column_alias_is_caught_in_dbt_reconcile(repo_copy):
    # R-C's marker set is ("amount", "cash_flow", "deposit"); `total_deposits` contains 'deposit'
    # and is a column name this repo really ships (bigquery/22_cash_flows.sql).
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + (
        "\n-- regression: the money column CONTAINS 'deposit' rather than being exactly 'deposit'\n"
        "WITH renamed AS (\n"
        "  SELECT total_deposits AS td FROM cash_flows\n"
        ")\n"
        "SELECT SUM(td)\n"
        "  / 5 AS expected_share\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_substring_marker_alias_resolution_does_not_credit_an_unrelated_column(repo_copy):
    """The widened matching must not start crediting non-money columns. `strategy_count` contains
    no money marker as a substring either, so aliasing it resolves nothing and the divisor beside
    it stays unflagged — the same false-positive guard the exact-match version already had."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- an alias bound to an UNRELATED (non-money) column must not be treated as money\n"
        "WITH renamed AS (\n"
        "  SELECT strategy_count AS n FROM active\n"
        ")\n"
        "SELECT SUM(n)\n"
        "  / 5 AS not_a_money_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 0


# ---- R-B: a MULTI-HOP alias (renamed twice before reaching the divisor) is no less a restyle than a
#      single hop, and must still resolve transitively (_money_alias_names()'s fixed-point loop) ----
def test_fixed_divisor_via_multi_hop_alias_is_caught(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- regression: money value renamed TWICE before the divisor sees it\n"
        "WITH base AS (\n"
        "  SELECT cf.amount AS raw FROM cash_flows cf\n"
        "),\n"
        "renamed AS (\n"
        "  SELECT raw AS raw2 FROM base\n"
        ")\n"
        "SELECT SUM(raw2)\n"
        "  / 5 AS equal_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


# ---- R-B: the alias-resolution fix must NOT reopen a false positive. An alias bound to an UNRELATED
#      (non-money) column, sitting next to an unrelated `/N`, must still pass — proving the fix checks
#      the alias's actual origin column, not merely "some alias exists nearby" (codebase audit
#      2026-07-26). ----
def test_unrelated_alias_near_unrelated_divisor_does_not_false_fail(repo_copy):
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- unrelated alias (no money column anywhere in its origin) next to an unrelated divisor\n"
        "WITH renamed AS (\n"
        "  SELECT strategy_count AS n FROM some_unrelated_table\n"
        ")\n"
        "SELECT n\n"
        "  / 5 AS unrelated_ratio\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 0


def test_type_cast_does_not_poison_the_money_alias_set(repo_copy):
    """R-B/R-C false-positive guard (codebase audit 2026-07-26, adversarial review of the alias fix).

    `CAST(cf.amount AS NUMERIC)` has the same `<x> AS <y>` shape as a column alias, so alias resolution
    used to credit the bare TYPE KEYWORD ("NUMERIC") as a money alias for the whole file — after which
    ANY unrelated `/N` sitting near ANY other cast to that same type false-tripped this gate. R-B/R-C is
    CI-BLOCKING, so that direction of failure blocks every merge, not just this check; a defensive CAST
    is idiomatic in this repo's own SQL, so it was one ordinary edit away from firing."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- a money column cast to a type, then a totally unrelated divisor near the same type name\n"
        "SELECT CAST(amount AS NUMERIC) AS amt FROM `stock-trading-498512.events.cash_flows`;\n"
        "SELECT CAST(tier_width AS NUMERIC)\n"
        "  / 3 AS third\n"
        "FROM `stock-trading-498512.state.unrelated`;\n"
    ))
    assert rc.main() == 0


def test_type_cast_exclusion_does_not_reopen_the_alias_hole(repo_copy):
    """The other half: excluding type names must not stop a REAL aliased equal-split from being caught,
    including when the same file also contains a type cast (codebase audit 2026-07-26)."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\nSELECT CAST(amount AS NUMERIC) AS amt FROM `stock-trading-498512.events.cash_flows`;\n"
        "WITH aliased AS (\n"
        "  SELECT cf.amount AS raw, a.s AS strategy\n"
        "  FROM active a CROSS JOIN `stock-trading-498512.events.cash_flows` cf GROUP BY a.s\n"
        ")\n"
        "SELECT SUM(raw)\n"
        "  / 5 AS equal_split\n"
        "FROM aliased;\n"
    ))
    assert rc.main() == 1


# ---- R-B/R-C: the AGGREGATE-sourced money-alias fail-open hole (roster#3, code-quality pass 2026-08-31,
#      VERIFIED CONFIRMED). MONEY_ALIAS_BINDING only resolves a SIMPLE `<col> AS <alias>` binding — its
#      source side must be a single bare identifier — so it structurally cannot match `SUM(cf.amount) AS
#      total_deposits`, an ordinary aggregation restyle, not a contrived pattern
#      (bigquery/22_cash_flows.sql:180 already ships the ROUND(SUM(...)) shape live today). Left
#      unresolved, a divisor fed by an aggregate-sourced money alias whose name avoids every marker
#      substring sails through R-B/R-C clean — reproduced end-to-end against the pre-fix code (see
#      MONEY_ALIAS_AGG_BINDING's comment). These fixtures pin the fix
#      (MONEY_ALIAS_AGG_BINDING / MONEY_ALIAS_ROUND_SUM_BINDING). ----
def test_fixed_divisor_via_aggregate_alias_in_derived_sql_is_caught(repo_copy):
    """The exact reproduction from the finding: `SUM(cf.amount) AS running_total` then
    `running_total / 5` — 'running_total' contains none of R-B's marker substrings, so only alias
    resolution (not the direct substring check) can catch this."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- regression: money value reaches the divisor via an AGGREGATE alias (SUM), not a bare column\n"
        "WITH renamed AS (\n"
        "  SELECT SUM(cf.amount) AS running_total\n"
        "  FROM cash_flows cf\n"
        ")\n"
        "SELECT running_total\n"
        "  / 5 AS equal_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_fixed_divisor_via_aggregate_alias_in_dbt_reconcile_is_caught(repo_copy):
    """Same aggregate-alias fail-open, R-C side (dbt reconcile test)."""
    p = rc.DBT_RECONCILE
    txt = _read(p)
    _write(p, txt + (
        "\n-- regression: same aggregate-alias restyle in the dbt reconcile test\n"
        "WITH renamed AS (\n"
        "  SELECT SUM(cf.amount) AS running_total FROM cash_flows cf\n"
        ")\n"
        "SELECT running_total\n"
        "  / 5 AS expected_share\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_fixed_divisor_via_round_sum_alias_is_caught(repo_copy):
    """The ROUND(SUM(...)) shape this repo actually ships (bigquery/22_cash_flows.sql:180's
    `ROUND(SUM(amount),2) AS total_deposits`) must resolve too, not just bare SUM(...)."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("22_cash_flows.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- regression: ROUND(SUM(...)) aggregate alias, the exact shape bigquery/22 already ships\n"
        "WITH renamed AS (\n"
        "  SELECT ROUND(SUM(amount),2) AS grand_total\n"
        "  FROM cash_flows\n"
        ")\n"
        "SELECT grand_total\n"
        "  / 5 AS equal_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 1


def test_aggregate_alias_over_unrelated_column_does_not_false_fail(repo_copy):
    """The aggregate-alias fix must not start crediting SUM(...) over an UNRELATED (non-money) column as
    money-adjacent, mirroring test_unrelated_alias_near_unrelated_divisor_does_not_false_fail above."""
    target = next(p for p in rc.DERIVED_LIVE_SQL if p.endswith("26_process_metrics.sql"))
    txt = _read(target)
    _write(target, txt + (
        "\n-- SUM over an unrelated (non-money) column must not be treated as money\n"
        "WITH renamed AS (\n"
        "  SELECT SUM(strategy_count) AS n FROM active\n"
        ")\n"
        "SELECT n\n"
        "  / 5 AS not_a_money_split\n"
        "FROM renamed;\n"
    ))
    assert rc.main() == 0


# ---- R-E: the cooldown_days sub-block (a SEPARATE comparison loop from the top-level rails) —
#      both the mismatch and the missing-key vacuous-pass directions (2026-07-17 audit) ----
def test_cooldown_rail_disagreement_is_caught(repo_copy):
    p = rc.ROSTER
    txt = _read(p)
    assert "post_termination: 180" in txt, "fixture assumption about roster.yaml's cooldown drifted"
    _write(p, txt.replace("post_termination: 180", "post_termination: 5"))
    assert rc.main() == 1


def test_cooldown_rail_key_missing_is_caught(repo_copy):
    p = rc.ROSTER
    doc = rc.yaml.safe_load(_read(p))
    assert doc["rails"]["cooldown_days"].get("post_keep") == 90, "fixture assumption about post_keep drifted"
    del doc["rails"]["cooldown_days"]["post_keep"]
    _write(p, rc.yaml.dump(doc, sort_keys=False))
    assert rc.main() == 1


# ---- R-E: the rail-constant parser rot guard (parsed < RAIL_NAMES count) — the analog of the
#      autonomy suite's regex-rot tests, previously unexercised (2026-07-17 audit) ----
def test_rail_const_shape_rot_is_caught(repo_copy, capsys):
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    assert "8  AS n_max," in txt, "fixture assumption about the arsenal_rails consts CTE shape drifted"
    # Break one `<N> AS <name>` const so RAIL_CONST no longer matches it -> only 7/8 parse.
    _write(arsenal, txt.replace("8  AS n_max,", "n_max = 8,"))
    assert rc.main() == 1
    assert "rail constants" in capsys.readouterr().out


# ---- R-E: a present-but-non-integer rail value is a CLEAN error, not an int() crash (2026-07-17 fix) ----
def test_rail_non_integer_value_is_a_clean_fail(repo_copy, capsys):
    p = rc.ROSTER
    txt = _read(p)
    # Blank n_min's value (YAML null) — it stays a PRESENT key (skips the clean 'missing' branch) and
    # used to hit an unguarded int(None) -> traceback instead of a clean R-E error.
    assert "n_min: 2 " in txt, "fixture assumption about roster.yaml's n_min line drifted"
    _write(p, txt.replace("n_min: 2 ", "n_min:  ", 1))
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "is not an integer" in out


# ---- R-E: a fractional rail value must NOT be silently truncated by int() (2026-07-29 bug hunt).
# int(2.7) == 2 in Python, and roster.yaml's real n_min (2) matches bigquery/35's real n_min SQL
# constant (2) -- so under the pre-fix code, writing n_min: 2.7 truncated to 2, "agreed" with the SQL
# constant, and the build stayed GREEN even though the YAML never actually declared 2. Confirmed this
# fails against the pre-fix code: reverting _compare_rails() to `val = int(container[yaml_key])` makes
# this exact test see rc.main() == 0 (no "is a float" text at all), not 1 -- the truncated 2.7->2
# silently equals arsenal_rails.n_min=2.
def test_rail_fractional_value_is_not_silently_truncated_is_caught(repo_copy, capsys):
    p = rc.ROSTER
    txt = _read(p)
    assert "n_min: 2 " in txt, "fixture assumption about roster.yaml's n_min line drifted"
    _write(p, txt.replace("n_min: 2 ", "n_min: 2.7 ", 1))
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "is a float" in out


# ---- R-E: an INTEGRAL float (2.0) is a deliberate design choice, not an oversight -- also rejected,
# not silently coerced to int(2.0) == 2, since roster.yaml's rails: are documented as plain integer
# counts and this file is mutated autonomously by SL1-SL5 with no human review (see _compare_rails()'s
# docstring for the full rationale).
def test_rail_integral_float_value_is_also_rejected_not_silently_coerced(repo_copy, capsys):
    p = rc.ROSTER
    txt = _read(p)
    assert "n_min: 2 " in txt, "fixture assumption about roster.yaml's n_min line drifted"
    _write(p, txt.replace("n_min: 2 ", "n_min: 2.0 ", 1))
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "is a float" in out


# ---- R-F: editing a LOCKED strategy's .md slice trips its spec_hash (MEMORY records this explicitly),
#      and a missing spec_hash input file is a clean error — neither was tested (2026-07-17 audit) ----
def test_spec_hash_mismatch_on_md_slice_is_caught(repo_copy):
    p = os.path.join(rc.STRATEGY_DIR, "03_strategy_a.md")
    _write(p, _read(p) + "\n<!-- regression: locked strategy doc edited post spec-lock -->\n")
    assert rc.main() == 1


def test_spec_hash_missing_input_file_is_caught(repo_copy, capsys):
    os.remove(os.path.join(rc.STRATEGY_MATH_DIR, "strategy_a.py"))
    assert rc.main() == 1
    assert "are missing" in capsys.readouterr().out


# ---- C0: R-F must be numbering-agnostic for the .md slice, exactly like R-A (2026-07-20 fix) ----
def test_content_free_locked_slice_rename_keeps_r_f_green(repo_copy):
    # A pure filename renumber of a spec-locked strategy's .md slice — ZERO byte changes to its
    # content, so nothing about the locked machinery actually changed — must NOT trip R-F. Before the
    # C0 fix, spec_hash_inputs() hardcoded each code's .md path as a literal numbered filename
    # ("03_strategy_a.md"), so this exact rename spuriously FAILed with a misleading "spec_hash
    # input(s) ... are missing" message even though R-A (which reads the heading, not the filename)
    # stayed green throughout — the asymmetry this finding closes.
    old_path = os.path.join(rc.STRATEGY_DIR, "03_strategy_a.md")
    new_path = os.path.join(rc.STRATEGY_DIR, "09_strategy_a.md")
    assert os.path.exists(old_path)
    os.rename(old_path, new_path)
    assert rc.main() == 0


# ---- R-A: the three dedicated fail-LOUD guards (empty Strategy.md headings, ARSENAL_SQL absent,
#      zero seed rows) — each only incidentally exercised before (2026-07-17 audit) ----
def test_empty_strategy_md_headings_is_caught(repo_copy, capsys):
    p = rc.STRATEGY_MD
    # Break every '## Strategy <code>' heading so STRATEGY_HEADING matches nothing -> md_codes empty.
    _write(p, _read(p).replace("## Strategy ", "## Strat "))
    assert rc.main() == 1
    assert "STRATEGY_HEADING" in capsys.readouterr().out


def test_arsenal_sql_absent_is_caught(repo_copy):
    os.remove(rc.ARSENAL_SQL)
    assert rc.main() == 1


def test_zero_seed_rows_is_caught(repo_copy, capsys):
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    old = "FROM UNNEST(['A','B','C','D','E']) AS code"
    assert old in txt
    # Rename the seed batch's `AS code` alias so UNNEST_SEED_BLOCK no longer matches (the sole seed
    # source per the founding batch) -> zero code/to_state rows parse.
    _write(arsenal, txt.replace(old, "FROM UNNEST(['A','B','C','D','E']) AS strat_code"))
    assert rc.main() == 1
    assert "parsed zero" in capsys.readouterr().out


# ---- R-A: missing top-level input files are CLEAN R-A/R-D errors, not open() tracebacks (2026-07-17 fix) ----
def test_missing_strategy_md_is_a_clean_fail(repo_copy, capsys):
    os.remove(rc.STRATEGY_MD)
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "Strategy.md is missing" in out


def test_missing_plan_is_a_clean_fail(repo_copy, capsys):
    os.remove(rc.PLAN)
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "Claude_Task_Plan.md is missing" in out


def test_missing_cadence_is_a_clean_fail(repo_copy, capsys):
    os.remove(rc.CADENCE)
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "ops/cadence.yaml is missing" in out


# ---- R-G: 2026-07-18 fix — a missing dbt/models/analytics/schema.yml was the one file-existence guard
#      in this script with no `else` branch, so it silently no-op'd (zero errors, zero notes) instead of
#      failing loud like every sibling single-file guard (STRATEGY_MD/PLAN/ARSENAL_SQL/CADENCE/DBT_RECONCILE
#      above) ----
def test_missing_schema_yml_is_a_clean_fail(repo_copy, capsys):
    os.remove(rc.DBT_SCHEMA_ACCEPTED_VALUES)
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "ROSTER CONSISTENCY: FAIL" in out and "dbt/models/analytics/schema.yml is missing" in out


# ---- strategies-null: a present-but-null `strategies:` key is a clean FAIL, not a `for s in None`
#      TypeError traceback (2026-07-17 fix — 3 sibling sites had forgotten the `or []` guard) ----
def test_strategies_null_is_a_clean_fail(repo_copy, capsys):
    p = rc.ROSTER
    doc = rc.yaml.safe_load(_read(p))
    doc["strategies"] = None            # present key, null value (e.g. a partial/interrupted SL5 write)
    _write(p, rc.yaml.dump(doc, sort_keys=False))
    assert rc.main() == 1               # must NOT raise; a clean, bridge-parseable FAIL
    assert "ROSTER CONSISTENCY: FAIL" in capsys.readouterr().out


# ---- R-G: an empty accepted_values(strategy) list is FLAGGED (not silently clean), and a non-mapping
#      accepted_values is a clean error, not an AttributeError crash (2026-07-17 fixes) ----
def test_schema_yml_empty_accepted_values_is_caught(repo_copy):
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    old = "values: ['A', 'B', 'C', 'D', 'E']"
    assert old in txt, "fixture assumption about schema.yml's accepted_values lists drifted"
    _write(p, txt.replace(old, "values: []", 1))
    assert rc.main() == 1


def test_schema_yml_nonmapping_accepted_values_is_a_clean_fail(repo_copy, capsys):
    p = rc.DBT_SCHEMA_ACCEPTED_VALUES
    txt = _read(p)
    # accepted_values authored as a bare list instead of a {values: [...]} mapping — used to
    # AttributeError on `.get`; now a clean R-G error.
    old = "accepted_values:\n              values: ['A', 'B', 'C', 'D', 'E']"
    if old not in txt:                  # tolerate an indentation drift in the real schema.yml
        import re as _re
        m = _re.search(r"accepted_values:\s*\n\s*values: \['A', 'B', 'C', 'D', 'E'\]", txt)
        assert m, "fixture assumption about schema.yml's accepted_values block shape drifted"
        old = m.group(0)
    _write(p, txt.replace(old, "accepted_values: ['A', 'B', 'C', 'D', 'E']", 1))
    assert rc.main() == 1
    assert "not a {values: [...]} mapping" in capsys.readouterr().out


# ---- R-J: arsenal_regime_coverage cell tokens must equal the strategy/01 shared vocabulary — the H7
#      bug class had ZERO tests (2026-07-17 audit) ----
def test_regime_spy_trend_cell_drift_is_caught(repo_copy):
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    assert "UNNEST(['UP','NEUTRAL','DOWN']) AS spy_trend" in txt
    # The exact pre-H7 mismatch: cells say UPTREND/RANGE/DOWNTREND, vocab says UP/NEUTRAL/DOWN.
    _write(arsenal, txt.replace("UNNEST(['UP','NEUTRAL','DOWN']) AS spy_trend",
                                "UNNEST(['UPTREND','RANGE','DOWNTREND']) AS spy_trend"))
    assert rc.main() == 1


def test_regime_vix_cell_drift_is_caught(repo_copy):
    arsenal = rc.ARSENAL_SQL
    txt = _read(arsenal)
    assert "UNNEST(['LOW','NORMAL','HIGH']) AS vix_regime" in txt
    _write(arsenal, txt.replace("UNNEST(['LOW','NORMAL','HIGH']) AS vix_regime",
                                "UNNEST(['LOW_VIX','ELEVATED_VIX','HIGH_VIX']) AS vix_regime"))
    assert rc.main() == 1


def test_regime_vocabulary_side_drift_is_caught(repo_copy):
    # A drift on the strategy/01 VOCABULARY side (not the SQL cell side) must also fail R-J.
    p = os.path.join(rc.STRATEGY_DIR, "01_shared_regime_vocabulary.md")
    txt = _read(p)
    assert "- **UP:**" in txt
    _write(p, txt.replace("- **UP:**", "- **UPWARD:**"))
    assert rc.main() == 1


def test_shared_regime_tokens_are_section_scoped():
    # Unit-level lock on shared_regime_tokens(): the SPY/VIX sets are exactly the router vocabulary and
    # do NOT leak the yield-curve NORMAL/INVERTED or breadth HEALTHY/WEAK bullets lower in the same file.
    spy, vix, _path = rc.shared_regime_tokens()
    assert spy == {"UP", "NEUTRAL", "DOWN"}
    assert vix == {"LOW", "NORMAL", "HIGH"}
    assert "INVERTED" not in vix and "HEALTHY" not in vix


# ---- R-K: golden-scenario prose-regression coverage — the check had ZERO tests, and repo_copy never
#      repointed SCENARIOS_YAML so no perturbation was even possible (2026-07-17 audit) ----
def test_uncovered_adopted_strategy_is_caught(repo_copy, capsys):
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCD"))   # E adopted but uncovered
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "R-K" in out and "'E'" in out


def test_slice_based_coverage_path_a_is_honored(repo_copy):
    # Coverage via governing_files naming E's own slice (path a), with NO 'Strategy E' prose anywhere.
    body = _scenarios_covering("ABCD") + (
        "  - id: e-via-slice\n"
        "    situation: A market-neutral pairs setup with no code word in the prose.\n"
        "    governing_files: ['07_strategy_e.md']\n"
        "    expected_decision: ACTIVATE\n"
        "    rationale: The per-strategy slice governs this decision.\n"
    )
    _write(rc.SCENARIOS_YAML, body)
    assert rc.main() == 0


def test_scenarios_absent_skips_r_k_cleanly(repo_copy):
    os.remove(rc.SCENARIOS_YAML)         # scenario_docs() -> None -> R-K skips, rest still passes
    assert rc.main() == 0


def test_shadow_strategy_with_slice_but_no_coverage_is_caught(repo_copy, capsys):
    # A SHADOW strategy WITH a slice file but no golden-scenario coverage must FAIL R-K.
    (open(os.path.join(rc.STRATEGY_DIR, "08_strategy_f.md"), "w", encoding="utf-8")
     .write("## Strategy F [CANDIDATE]: shadow test strategy\n\nbody\n"))
    _write(rc.ROSTER, _read(rc.ROSTER) + _shadow_f_entry())
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCDE"))   # A-E covered, F is not
    assert rc.main() == 1
    assert "R-K" in capsys.readouterr().out


def test_slice_less_shadow_strategy_without_coverage_is_caught(repo_copy, capsys):
    # 2026-07-17 (owner direction): a SHADOW/PAPER strategy with NO slice AND no coverage is a
    # half-applied SL5 SHADOW-register that must FAIL. R-A/R-D never inspect a non-active entry, so R-K
    # is the only gate — previously this was a non-blocking note (zero enforcement, a vacuous pass).
    _write(rc.ROSTER, _read(rc.ROSTER) + _shadow_f_entry())   # F: shadow, no slice
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCDE"))   # A-E covered, F not
    assert rc.main() == 1
    assert "R-K" in capsys.readouterr().out


def test_slice_less_shadow_strategy_with_prose_coverage_passes(repo_copy):
    # A slice-less SHADOW strategy CAN still satisfy R-K via a 'Strategy F' prose mention (path b) —
    # the enforcement requires coverage, not a slice specifically.
    _write(rc.ROSTER, _read(rc.ROSTER) + _shadow_f_entry())   # F: shadow, no slice
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCDEF"))  # F covered by a prose mention
    assert rc.main() == 0


def test_heading_present_filename_mismatched_slice_still_enforces_coverage(repo_copy, capsys):
    # 2026-07-18 fix: R-K's slice-presence test must reuse R-A's heading-based sl_codes, not a fresh
    # `*_strategy_<code>.md` filename glob — a slice whose heading correctly reads '## Strategy E' but
    # whose filename does not end in `_strategy_e.md` (plausible for a SISA-synthesized code beyond
    # split_strategy.py's a-e-only slug regex) must still count as "has a slice", so the real
    # `if code not in covered` check still runs instead of vacuously skipping behind a false "already
    # reported by R-A" note. Rename E's real slice to a mismatched filename (its heading text — and
    # therefore sl_codes, which R-A also reads — is unaffected by the rename) and strip E's coverage.
    # NOTE (updated 2026-07-20, C0 fix): this rename no longer incidentally trips R-F. Before C0,
    # spec_hash_inputs() hardcoded the literal 07_strategy_e.md path, so main() exited 1 even under the
    # pre-2026-07-18 R-K glob code, and it was the R-K-specific substring assertions below — not the bare
    # exit code — that discriminated pre/post-R-K-fix (the pre-fix code vacuously note-and-skips E's
    # coverage, a false "already reported by R-A" note instead of "NO golden-scenario coverage"). Now that
    # R-F discovers the .md slice by heading (numbering/filename-agnostic, like R-A), this rename alone
    # would leave R-F green (see test_content_free_locked_slice_rename_keeps_r_f_green below) — the exit
    # 1 asserted here comes solely from R-K's own coverage check, which is this test's actual subject.
    slice_path = os.path.join(rc.STRATEGY_DIR, "07_strategy_e.md")
    renamed_path = os.path.join(rc.STRATEGY_DIR, "07_strategy_e_market_neutral_pairs.md")
    os.rename(slice_path, renamed_path)
    _write(rc.SCENARIOS_YAML, _scenarios_covering("ABCD"))   # E adopted but given ZERO coverage
    assert rc.main() == 1
    out = capsys.readouterr().out
    assert "R-K" in out and "'E'" in out and "NO golden-scenario coverage" in out
    assert "already reported by R-A" not in out
    assert "R-F" not in out   # C0: the rename alone must not ALSO trip R-F anymore


def test_slice_less_probe_adopted_missing_slice_stays_a_note(repo_copy, capsys):
    # A PROBE/ADOPTED (roster-active) strategy missing its slice is caught by R-A (heading absent from
    # slice_codes); R-K keeps that a non-blocking note to avoid double-reporting — exit is already 1.
    slice_path = os.path.join(rc.STRATEGY_DIR, "07_strategy_e.md")
    os.remove(slice_path)                                     # remove adopted E's slice
    assert rc.main() == 1                                     # R-A fails on the missing E heading
    out = capsys.readouterr().out
    assert "R-A" in out                                       # the authoritative failure
    assert "already reported by R-A" in out                  # R-K's non-blocking note, not a 2nd error


# ---- R-H: the reported line number (a bespoke formula distinct from the _line_no idiom) is correct ----
def test_r_h_reports_the_offending_line_number(repo_copy, capsys):
    p = rc.PLAN
    txt = _read(p)
    idx = txt.index("state.strategy_candidates")
    expected_line = txt[:idx].count("\n") + 1
    _write(p, txt[:idx] + "events.strategy_candidates" + txt[idx + len("state.strategy_candidates"):])
    assert rc.main() == 1
    assert f"Claude_Task_Plan.md:{expected_line}" in capsys.readouterr().out


# ---- slicemap end-of-file tolerance: 'Strategy reading' as the LAST H2 must still yield its codes
#      (the `(?=^##\s|\Z)` fix), rather than an empty section -> spurious R-A mismatch (2026-07-17 fix) ----
def test_slicemap_reads_last_section_to_eof(tmp_path, monkeypatch):
    plan = tmp_path / "plan.md"
    plan.write_text(
        "## Something earlier\n\nblah\n\n"
        "## Strategy reading\n\n"
        "| **M1** (A) | `03_strategy_a.md` | x |\n"
        "| **M2** (B) | `04_strategy_b.md` | x |\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(rc, "PLAN", str(plan))
    assert rc.slicemap_codes() == {"A", "B"}


# =====================================================================================================
# R-L: declared-frequency seed coverage (added 2026-08-11) had ZERO test coverage — roster#1, code-quality
# pass 2026-08-31. Mirrors the R-A UNNEST_SEED_BLOCK / R-E RAIL_CONST regex-rot precedent: (1) a happy-path
# check against the real fixture, (2) a shape-rot guard so a regex that stops matching degrades LOUDLY (a
# visible NOTE), not silently, and (3) a coverage-gap guard naming the specific missing code.
# =====================================================================================================
def test_declared_frequency_seed_codes_happy_path():
    # Direct unit-level check against the REAL repo file (roster_active_codes() also currently == this
    # set today) — mirrors seed_active_codes()'s own precedent of an un-fixtured direct-repo assertion.
    assert rc.declared_frequency_seed_codes() == {"A", "B", "C", "D", "E"}


def test_declared_frequency_seed_block_shape_rot_is_caught(repo_copy, capsys):
    # Break the block's own anchor (the `AS seed` alias DECLARED_FREQUENCY_SEED_BLOCK requires) so the
    # regex no longer matches at all — declared_frequency_seed_codes() must return None (not silently
    # empty), and main() must print the "could not locate" NOTE rather than going dark with zero signal.
    p = rc.DECLARED_FREQUENCY_SQL
    txt = _read(p)
    assert "]) AS seed" in txt, "fixture assumption about bigquery/166's seed block alias drifted"
    _write(p, txt.replace("]) AS seed", "]) AS renamed_seed"))
    assert rc.declared_frequency_seed_codes() is None
    rc_code = rc.main()
    out = capsys.readouterr().out
    assert rc_code == 0, "R-L is non-blocking by design (CLAUDE.md SISA posture) — must not fail the build"
    assert "R-L" in out and "could not locate" in out


def test_declared_frequency_seed_coverage_gap_is_caught(repo_copy, capsys):
    # Remove strategy E's seed STRUCT row entirely (E stays roster-active per every other surface) — the
    # NOTE must name E specifically, non-blocking (exit 0), matching R-F's own NOTE-only branch.
    p = rc.DECLARED_FREQUENCY_SQL
    txt = _read(p)
    old = ("  STRUCT('E', '6-12 pair theses per year (12-24 trades counting both legs).', "
           "'strategy/07_strategy_e.md:68', FALSE)\n")
    assert old in txt, "fixture assumption about bigquery/166's E seed row shape drifted"
    _write(p, txt.replace(old, ""))
    assert rc.declared_frequency_seed_codes() == {"A", "B", "C", "D"}
    rc_code = rc.main()
    out = capsys.readouterr().out
    assert rc_code == 0, "R-L is non-blocking by design — a coverage gap must not fail the build"
    assert "R-L" in out and "'E'" in out and "state.strategy_declared_frequency" in out


# =====================================================================================================
# R-M: spec_hash_inputs()'s hand-maintained module list vs each hashed module's REAL import graph —
# roster#2, code-quality pass 2026-08-31.
# =====================================================================================================
def test_local_strategy_math_imports_recognizes_absolute_form(tmp_path):
    """_local_strategy_math_imports() must recognize the ABSOLUTE import spelling (`from strategy_math.X
    import ...` / `from strategy_math import X`) — the only form a module OUTSIDE the strategy_math/
    package (like c_options_math.py, which lives at repo root) could ever use, since a relative import
    requires being inside the package."""
    mod = tmp_path / "outside_pkg.py"
    mod.write_text(
        "from strategy_math.common import days_between\nfrom strategy_math import strategy_a\n",
        encoding="utf-8",
    )
    found = rc._local_strategy_math_imports(str(mod))
    assert found == {
        os.path.join(rc.STRATEGY_MATH_DIR, "common.py"),
        os.path.join(rc.STRATEGY_MATH_DIR, "strategy_a.py"),
    }


def test_local_strategy_math_imports_recognizes_relative_bare_form(tmp_path, monkeypatch):
    """The `from . import common, strategy_a` bare-relative form (no explicit dotted module) must resolve
    each imported NAME as its own submodule, mirroring strategy_math/__init__.py's own import line."""
    monkeypatch.setattr(rc, "STRATEGY_MATH_DIR", str(tmp_path))
    mod = tmp_path / "inside_pkg.py"
    mod.write_text("from . import common, strategy_a\n", encoding="utf-8")
    found = rc._local_strategy_math_imports(str(mod))
    assert found == {str(tmp_path / "common.py"), str(tmp_path / "strategy_a.py")}


def test_local_strategy_math_imports_ignores_unrelated_and_missing_modules(tmp_path):
    """A stdlib import and a from-elsewhere-package import must not be mistaken for a strategy_math/
    dependency, and a module path that does not exist must return an empty set rather than crash (the
    caller's own R-F file-existence check already reports a missing hashed module elsewhere)."""
    mod = tmp_path / "mixed_imports.py"
    mod.write_text("import math\nfrom dataclasses import dataclass\nfrom typing import List\n",
                    encoding="utf-8")
    assert rc._local_strategy_math_imports(str(mod)) == set()
    assert rc._local_strategy_math_imports(str(tmp_path / "does_not_exist.py")) == set()


def test_module_coverage_gap_is_empty_against_the_real_repo():
    """Sanity: today's real repo has zero R-M coverage gaps — A/B/D/E each import only
    strategy_math/common.py (already listed in module_paths_by_code), and C's c_options_math.py imports
    nothing from strategy_math/ at all (self-contained, per its own docstring)."""
    assert rc.spec_hash_module_coverage_gaps() == []


def test_module_coverage_gap_detects_untracked_import(repo_copy):
    """spec_hash_module_coverage_gaps() must name the code + missing module when a spec-hash-covered
    strategy's own hashed file imports a strategy_math/ submodule that module_paths_by_code does not list
    — reproduces the exact drift class spec_hash_inputs()'s own docstring records already happened once
    (common.py silently omitted from the original hash until the 2026-07-11 adversarial self-audit caught
    it by inspection, not by any mechanical guard)."""
    p = os.path.join(rc.STRATEGY_MATH_DIR, "strategy_a.py")
    txt = _read(p)
    assert "from .common import days_between" in txt, "fixture assumption about strategy_a.py's import drifted"
    _write(p, txt + "\nfrom .sizing import position_size  # test-only untracked import\n")
    gaps = rc.spec_hash_module_coverage_gaps()
    assert any("'A'" in g and "sizing.py" in g for g in gaps)


def test_module_coverage_gap_note_is_non_blocking_even_after_spec_hash_is_kept_current(repo_copy, capsys):
    """R-M is non-blocking (main() == 0) even in the case that would make it matter most: the operator
    dutifully recomputed A's spec_hash after adding the untracked import (so R-F itself reports clean),
    but module_paths_by_code['A'] was never told about the new module — the exact silent spec-hash
    blind-spot R-M exists to surface as a visible NOTE, not a build failure (mirrors R-F's own NOTE-only
    branch for a spec-locked code missing a spec_hash_inputs() entry entirely)."""
    p = os.path.join(rc.STRATEGY_MATH_DIR, "strategy_a.py")
    txt = _read(p)
    assert "from .common import days_between" in txt, "fixture assumption about strategy_a.py's import drifted"
    _write(p, txt + "\nfrom .sizing import position_size  # test-only untracked import\n")
    # Recompute + write the now-correct spec_hash for A so R-F itself reports clean, isolating R-M's note.
    new_hash = rc.compute_spec_hash("A")
    roster_txt = _read(rc.ROSTER)
    _old_line, old_hash = _first_spec_hash_line(roster_txt)
    _write(rc.ROSTER, roster_txt.replace(old_hash, new_hash))
    rc_code = rc.main()
    out = capsys.readouterr().out
    assert rc_code == 0, "R-M must not fail the build on its own"
    assert "R-M" in out and "'A'" in out and "sizing.py" in out


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))

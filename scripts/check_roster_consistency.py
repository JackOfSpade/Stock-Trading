#!/usr/bin/env python3
"""Single-source the ROSTER: fail CI if strategy/roster.yaml drifts from its mirrors + derived SQL.

WHY THIS EXISTS (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive). Making strategy
add/delete fully autonomous (ops/RUNBOOK.md §39; ops/autonomy_levels.yaml loop `strategy_arsenal`) means
routines SL1-SL5 now edit the roster with no human PR review. The compensating control on the CONSISTENCY
axis is this gate — the roster analog of scripts/check_cadence_consistency.py — which makes an internally
inconsistent roster a BUILD FAILURE, so a half-applied SL5 fanout (roster.yaml flipped but a slice /
section / seed / derived-SQL not) can never merge (auto-merge only merges on green CI).

SOURCE OF TRUTH: strategy/roster.yaml (the roster analog of ops/cadence.yaml). Every other surface must
agree with it. If strategy/roster.yaml is ABSENT (a pre-2026-07-10 checkout, before the arsenal loop
landed) every check is SKIPPED cleanly (green) — exactly as check_cadence_consistency.py skips check E when
bigquery/24 is absent.

CHECKS
  R-A  ROSTER SET AGREEMENT. The set of ROSTER-ACTIVE strategy codes (roster.yaml strategies whose
       roster_state is a finalized live state — probe or adopted, i.e. is_active; SHADOW/PAPER candidates
       live in a `## Strategy <code> [CANDIDATE]` namespace and are deliberately NOT yet roster-active)
       must be IDENTICAL across all of:
         (1) strategy/roster.yaml            — strategies[].code where roster_state in {probe, adopted}
         (2) state.strategy_roster seed      — bigquery/35_strategy_arsenal.sql: the seeded lifecycle rows,
                                               either a literal tuple row (..., 'A', ..., 'ADOPTED', ...) or
                                               a batch `SELECT ..., 'ADOPTED', ... FROM UNNEST(['A',...]) AS
                                               code` block (the founding-batch shape); the LAST row/block per
                                               code wins (append-only). Active = latest to_state in
                                               {PROBE, ADOPTED}. (If the seed shape changes again, update
                                               SEED_ROW / UNNEST_SEED_BLOCK.)
         (3) Strategy.md                     — '## Strategy <code>' section headings, EXCLUDING '[CANDIDATE]'
         (4) strategy/ slices                — each generated per-strategy slice's own '## Strategy <code>'
                                               heading (numbering-agnostic: read the heading, not the
                                               filename, so the stable code-keyed slice band can renumber)
         (5) Claude_Task_Plan.md slice-map   — the per-strategy rows under '## Strategy reading' that
                                               reference a `NN_strategy_<code>.md` slice
       Any surface that differs -> FAIL naming the symmetric difference.

  R-B  NO BARE ROSTER LITERAL / FIXED DIVISOR in the LIVE derived SQL. None of
         bigquery/22_cash_flows.sql, bigquery/26_process_metrics.sql, dbt/models/analytics/strategy_nav.sql
       may contain a bare `['A','B',...]` UNNEST literal, nor a fixed `/ 5` equal-split divisor on a line
       that splits `amount`. They MUST read `state.active_strategy_codes` / an as-of-flow-date
       `COUNT(*) FROM state.strategy_roster ... WHERE r.is_active AND r.adopted_date <= cf.flow_date`
       instead. FAIL naming file:line. (bigquery/04_analytics.sql is the SUPERSEDED/dead strategy_nav — it
       is EXEMPT from this hard check; it should carry an explicit dead-code marker so its stale literal is
       never mistaken for live.) The adjacency guard resolves simple `<col> AS <alias>` bindings
       (_money_alias_names(), codebase audit 2026-07-26) so a divisor fed by an ALIASED money column (e.g.
       `cf.amount AS raw` ... `SUM(raw) / 5`) is still caught — see that function's docstring for the hole
       this closes.

  R-C  COUNT-AGNOSTIC dbt RECONCILE TEST. dbt/tests/assert_cash_flows_reconcile.sql must not hardcode the
       roster size: no `/ 5` divisor and no `amount/5` / 'exactly 5' assumption. The reconciliation (sum of
       each strategy's attributed deposits + redistributions == its cash_flows) must hold for ANY roster
       size. FAIL if a 5-hardcode remains. (Test CONTENT edit only — NOT a dbt-ownership change; the
       settled decision to keep dbt as a test/validation layer stands.) Same alias-resolution adjacency
       guard as R-B (codebase audit 2026-07-26).

  R-D  PER-STRATEGY ROUTINE EXISTS. Every non-null strategies[].per_strategy_routine in roster.yaml must be
       a routine id present in ops/cadence.yaml, so a strategy that declares its own scheduled routine can
       never reference a routine the cadence single-source doesn't know about. FAIL naming code + routine.

  R-E  RAILS LITERAL AGREEMENT (added rev 2026-07-10b, code-review finding #9). bigquery/35_strategy_arsenal.sql's
       state.arsenal_rails view hardcodes the anti-churn rails (n_min, n_max, k_incubate, k_regime,
       max_roundtrip_commission_bps, adoption_rate_window_days, and the three cooldown_days) as SQL
       constants that DUPLICATE
       strategy/roster.yaml's `rails:` block. That view's own comment claims these are "cross-checked by
       scripts/check_roster_consistency.py, exactly as the cadence deadline literal is ... checked by
       check_cadence_consistency.py" — this check makes that claim true instead of aspirational. FAIL
       naming which rail disagrees and its two values.

  R-G  DBT SCHEMA.YML ACCEPTED_VALUES AGREEMENT (added 2026-07-14 audit finding; this index entry itself
       was missing until the 2026-07-29 bug hunt — the check has run since 07-14, it just was not listed
       here, which is exactly the "an unlisted check is invisible to a maintainer" failure this index
       exists to prevent). dbt/models/analytics/schema.yml's generic `accepted_values` tests on any
       column literally named `strategy` hardcode a roster snapshot (e.g. `values: ['A','B','C','D','E']`)
       — the same bare-literal drift class as R-B, living in schema.yml instead of derived SQL. CLAUDE.md's
       settled decision makes strategy add/delete fully autonomous (SISA), so a hardcoded list here would
       silently start failing `dbt test` (advisory-only, see ci.yml) the moment the roster changes with no
       human touch. FAIL if any such accepted_values set != the roster-active set, is empty, or is not a
       `{values: [...]}` mapping. FAIL (not skip) if dbt/models/analytics/schema.yml itself is missing —
       unlike bigquery/35 (R-A/R-E's skip trigger), this file is expected to always exist.

  R-H  CANDIDATE-FEED DATASET NAME (added 2026-07-15, self-improvement audit CONFIRMED GAP
       strategy-candidates-dataset-mismatch). The live SISA candidate-intake table is
       `state.strategy_candidates` (bigquery/35_strategy_arsenal.sql CREATE TABLE) — there is no
       `events.strategy_candidates` object anywhere live. Claude_Task_Plan.md and ops/cadence.yaml
       previously named the WRONG dataset (`events.`) in 9 places (D1/Q1/Q3/A1's write instructions +
       SL1's read instructions), which would have made every SISA candidate-emission instruction target
       a table that does not exist. FAIL if the literal string `events.strategy_candidates` reappears in
       either file.

  R-I  REVIEW-CADENCE DECLARED (added 2026-07-15, self-improvement audit CONFIRMED GAP
       sisa-graduate-no-signal-path). Every ROSTER-ACTIVE strategy (probe/adopted) must declare
       `review_cadence: reactive|long_horizon` in strategy/roster.yaml — the field D1's daily
       opportunity check and W3's weekly position deep-dive now read to decide whether a strategy is
       in scope, replacing a hardcoded 'A, B, C, or E' enumeration that had no mechanism to pick up a
       future SISA graduate. FAIL naming which strategy is missing the field or has an invalid value.

  R-J  REGIME-COVERAGE VOCABULARY AGREEMENT (added 2026-07-17, finding H7). bigquery/35_strategy_arsenal.sql's
       state.arsenal_regime_coverage view builds its 9 cells from two UNNEST literals
       (`UNNEST([...]) AS spy_trend` x `UNNEST([...]) AS vix_regime`). Those tokens MUST equal the
       IMMUTABLE shared regime vocabulary parsed from strategy/01_shared_regime_vocabulary.md
       (spy_trend IN {UP,NEUTRAL,DOWN} from the '### SPY Trend State' section, vix_regime IN
       {LOW,NORMAL,HIGH} from '### VIX Regime') — the exact tokens SL3 stamps onto
       analytics.strategy_incubation_perf.regime_cell. The pre-H7 literals (UPTREND/RANGE/DOWNTREND x
       LOW_VIX/ELEVATED_VIX/HIGH_VIX) matched no writer, so every cov/gap-fill string-equality join
       missed and all 9 cells read is_gap=TRUE forever, biasing SL1's zero-coverage synthesis. This makes
       the arsenal_regime_coverage header's own claim ("the strategy/01 shared vocabulary") a checked
       invariant. FAIL naming the disagreeing token set and its two values.

  R-K  GOLDEN-SCENARIO PROSE-REGRESSION COVERAGE (added 2026-07-17, finding DEF-4 — the golden-scenario
       expansion gap. Named R-K, NOT R-J: the DEF-4 brief said "R-J" but that id was already taken by the
       regime-coverage vocabulary check above (finding H7), so this one takes the next free letter.).
       CLAUDE.md makes strategy add/delete fully autonomous (SISA), and the golden fixture set
       (tests/golden_scenarios/scenarios.yaml) is the ONLY behavioral gate on the DECISION prose an
       adopted strategy runs on — but nothing forced a NEW strategy's decision prose to get any
       prose-regression coverage, so SISA could adopt a strategy whose activation/entry wording could
       silently flip forever unguarded. This check makes that a BUILD FAILURE: every strategy in
       strategy/roster.yaml whose roster_state is SHADOW / PAPER / PROBE / ADOPTED must be referenced by
       >= 1 scenario in scenarios.yaml. A scenario "references" code X if EITHER (a) a governing_files
       entry is X's own per-strategy slice `NN_strategy_<x>.md` (the explicit signal SL5's SHADOW-register
       step stamps on the >=2 scenarios it authors in the same commit that registers the strategy — the
       proven "same-commit-or-CI-fails" enforcement, exactly like R-A on the bigquery/35 seed), OR (b) it
       names "Strategy X" as a whole token in its id/situation/rationale (the founding A-E fixtures' signal
       — they pin the aggregate Strategy.md, not a slice, and each names its strategy, so all five pass
       today with no fixture edit). This is a MECHANICAL consistency gate the autonomous registrar
       satisfies itself in-band, NOT a human review/approval gate on strategy add (SISA no-human-gate
       posture preserved — R-A already blocks a half-applied fanout the same way). FAIL naming the
       uncovered strategy + its state. If scenarios.yaml is ABSENT (pre-ITEM-20 checkout) this check
       SKIPS cleanly, exactly as R-A/R-E skip a missing bigquery/35.

  R-F  SPEC-LOCK HASH AGREEMENT (added rev 2026-07-11, Item 28 self-improvement audit; hardened
       2026-07-11 adversarial self-audit; provenance coverage expanded 2026-08-07). Each strategy's
       LOCKED machinery — the shared locked operational prose (strategy/00_preamble.md,
       01_shared_regime_vocabulary.md, 02_regime_router.md, and 09_regime_scoring_strategy_blind_monthly.md),
       the shared heading-delimited Regime router pre-mortem, its own strategy/0N_strategy_<code>.md slice,
       its own heading-delimited pre-mortem segment in strategy/08_pre_mortems.md, and its corresponding
       math module(s) (strategy_math/strategy_<code>.py
       + strategy_math/common.py for A/B/D/E — common.py is shared math EVERY one of those imports, so a
       change there is spec drift too, not invisible just because no single strategy's own file changed;
       c_options_math.py alone for C, which is self-contained) — freezes at SHADOW entry (Experiment_
       Parameters.md immutability doctrine). strategy/roster.yaml's per-strategy `spec_hash` field is a
       sha256 over those inputs' bytes in that order (the pre-mortem uses only the named strategy's
       heading-delimited segment, not every strategy's accepted record), concatenated; this check
       recomputes it and FAILs if a SPEC_HASH_INPUTS-covered spec-locked
       strategy (spec_locked_since is set) either has no spec_hash recorded, or its recorded spec_hash no
       longer matches the current files — meaning locked machinery drifted post-lock via a silent edit
       instead of a terminate-and-restart-as-new. A spec-locked strategy code NOT YET in SPEC_HASH_INPUTS
       (e.g. a strategy SISA synthesizes autonomously, since its SL2 authoring routine does not today
       generate a strategy_math module) prints a visible, NON-blocking NOTE instead of failing — hard-
       failing there would make R-F a de facto CI gate on autonomous strategy promotion, which CLAUDE.md's
       settled decision forbids (update SPEC_HASH_INPUTS by hand once that strategy has a math module).

  R-L  DECLARED-FREQUENCY SEED COVERAGE (added 2026-08-11, capital-dormancy-sweep gap). bigquery/166_
       capital_dormancy_sweep.sql seeds state.strategy_declared_frequency -- one hand-maintained row per
       strategy (declared_frequency_text, source_citation, is_low_frequency_by_design) that the capital-
       dormancy-sweep eligibility view (state.strategy_capital_dormancy) and bigquery/167_nomadic_capital.sql's
       NOMADIC classification both join against. A strategy with NO row there is not skipped or flagged by
       that live SQL -- it is silently treated as is_low_frequency_by_design=FALSE (fail-open: "not
       nomadic", holds standing capital like any other strategy). CLAUDE.md's settled SISA decision means
       SL1-SL5 can adopt a new strategy (F, G, H, ...) with no human step, and this seed table is NOT
       regenerated by that pipeline, so a newly-adopted strategy would silently miss the nomadic-capital
       mechanism with nothing to warn about it. This check parses the seeded strategy codes straight out of
       bigquery/166_capital_dormancy_sweep.sql's own SQL text (CI has no BigQuery credentials for this
       script, so the live table can never be queried) and prints a visible, NON-blocking NOTE naming any
       roster-active (probe/adopted) strategy missing a row -- hard-failing here would make a hand-
       maintained seed a de facto CI gate on autonomous strategy adoption, exactly the posture CLAUDE.md
       forbids (same rationale as R-F's own NOTE-only branch above). If the seed block itself cannot be
       located at all (bigquery/166 missing, or its INSERT/UNNEST shape changes), this check prints a NOTE
       saying so instead of failing or crashing.

Usage:  python scripts/check_roster_consistency.py        # exit 0 if consistent, 1 + diff if not
"""
import glob
import hashlib
import os
import re
import sys

try:
    # this module's own reads now go through lib.textio.load_yaml() (2026-07-29 textio
    # adoption), so `yaml` is no longer referenced directly here, but the import stays for (1) this
    # fail-fast ImportError guard (a clear "pip install pyyaml" message beats textio.py's own bare
    # ImportError traceback) and (2) tests/test_roster_consistency.py's direct rc.yaml.safe_load()/
    # rc.yaml.dump() access when building a perturbed fixture.
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.textio import read_bytes, read_text, load_yaml
from lib.md_fence import fence_mask
from lib.roster_common import roster_active_codes

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROSTER = os.path.join(ROOT, "strategy", "roster.yaml")
STRATEGY_MD = os.path.join(ROOT, "Strategy.md")
STRATEGY_DIR = os.path.join(ROOT, "strategy")
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")
ARSENAL_SQL = os.path.join(ROOT, "bigquery", "35_strategy_arsenal.sql")
# R-K: the golden-scenario prose-regression fixture set (tests/golden_scenarios/scenarios.yaml). A
# module global (not a frozen constant read once) so tests can monkeypatch it, like every other path here.
SCENARIOS_YAML = os.path.join(ROOT, "tests", "golden_scenarios", "scenarios.yaml")
# R-L: the file that seeds state.strategy_declared_frequency (bigquery/166_capital_dormancy_sweep.sql). A
# module global, not a frozen constant, matching every other path here.
DECLARED_FREQUENCY_SQL = os.path.join(ROOT, "bigquery", "166_capital_dormancy_sweep.sql")

# The LIVE roster-derived SQL that must carry NO bare ['A'..] literal / fixed /5 divisor (R-B).
DERIVED_LIVE_SQL = [
    os.path.join(ROOT, "bigquery", "22_cash_flows.sql"),
    os.path.join(ROOT, "bigquery", "26_process_metrics.sql"),
    os.path.join(ROOT, "dbt", "models", "analytics", "strategy_nav.sql"),
]
DBT_RECONCILE = os.path.join(ROOT, "dbt", "tests", "assert_cash_flows_reconcile.sql")
# R-G: dbt generic `accepted_values` tests on the `strategy` column that hardcode roster-active
# codes -- same bare-literal drift class as R-B, living in schema.yml instead of derived SQL.
DBT_SCHEMA_ACCEPTED_VALUES = os.path.join(ROOT, "dbt", "models", "analytics", "schema.yml")
STRATEGY_MATH_DIR = os.path.join(ROOT, "strategy_math")
C_OPTIONS_MATH = os.path.join(ROOT, "c_options_math.py")
# R-F's shared locked operational prose.  These slices govern every strategy's immutable operating
# environment but are not in any individual strategy slice. Keep this an explicit ordered tuple rather
# than globbing strategy/*.md: the document-completion checklist, INDEX, and README are not frozen trading
# machinery and must not create spurious hash churn.
SHARED_LOCKED_OPERATIONAL_PROSE = (
    os.path.join(STRATEGY_DIR, "00_preamble.md"),
    os.path.join(STRATEGY_DIR, "01_shared_regime_vocabulary.md"),
    os.path.join(STRATEGY_DIR, "02_regime_router.md"),
    os.path.join(STRATEGY_DIR, "09_regime_scoring_strategy_blind_monthly.md"),
)
# R-F hashes only each strategy's own accepted pre-mortem segment from this generated slice.  A module
# global (rather than an inline path) keeps it monkeypatchable in the fixture-copy tests, like
# STRATEGY_DIR / C_OPTIONS_MATH.
PRE_MORTEMS = os.path.join(STRATEGY_DIR, "08_pre_mortems.md")


def _find_slice_by_heading(code):
    """R-F helper: the strategy/ slice file whose OWN '## Strategy <code>' heading is `code` — reuses
    headings_in()/STRATEGY_HEADING, the exact machinery slice_codes()/R-A already use, so this lookup is
    numbering-agnostic in precisely the way R-A's own docstring promises (read the heading, not the
    filename, so the stable code-keyed slice band can renumber). Returns None if no slice's heading
    matches `code` at all (the slice was deleted, or its heading itself rotted) — a real gap, not a
    renumber, so the caller falls back to reporting it as a missing spec_hash input, same as always
    (C0 fix, 2026-07-20: spec_hash_inputs() previously hardcoded each code's .md path as a literal
    numbered filename, so a content-free slice renumber — which R-A tolerates by design — spuriously
    FAILed R-F with a misleading "missing" message for machinery that was not actually lost)."""
    for p in sorted(glob.glob(os.path.join(STRATEGY_DIR, "*_strategy_*.md"))):
        if code in headings_in(read_text(p)):
            return p
    return None


def spec_hash_inputs():
    """R-F: strategy code -> (spec .md slice, [corresponding math module(s)]) whose bytes are hashed
    into roster.yaml's spec_hash alongside SHARED_LOCKED_OPERATIONAL_PROSE and the code's own
    heading-delimited pre-mortem segment. A FUNCTION (not a frozen module-level dict) so it re-reads
    STRATEGY_DIR / STRATEGY_MATH_DIR / C_OPTIONS_MATH on every call — those three are monkeypatchable module globals
    (tests/test_roster_consistency.py's repo_copy fixture points them at a tmp_path copy), exactly like
    every other path this file's checks read; a frozen dict built once at import time from the real ROOT
    would silently ignore that monkeypatching and defeat fixture-based drift tests (BUG FIX, rev
    2026-07-11 adversarial self-audit).

    The .md slice path is DISCOVERED via _find_slice_by_heading(), not hardcoded by number (C0 fix,
    2026-07-20) — a spec-locked strategy's slice can be renumbered (or given a descriptive slug suffix,
    like R-K's mismatched-filename fixture) with zero content change and R-F keeps tracking the right
    file, exactly as R-A already tolerates. Only the math module path(s) below stay as literal constants:
    strategy_math/ is not scanned by heading, so renaming a math module IS a real drift event, not a
    tolerated renumber.

    The shared operating slices, shared router pre-mortem, and each strategy's own pre-mortem are
    deliberately hashed by compute_spec_hash(), rather than copied into this mapping: the first group is
    common to every covered code and the latter two are heading-delimited byte segments, not standalone
    files. This avoids the prior provenance hole where an accepted pre-mortem or shared operational
    machinery could drift without changing any spec_hash. C predates strategy_math/ (its math already
    lived in c_options_math.py at repo root, self-contained,
    no shared-module dependency); A/B/D/E use the strategy_math/ package added in Item 28 and each
    imports strategy_math/common.py for shared math (OLS/correlation/day-count/sizing) — common.py is
    included in EVERY A/B/D/E hash (but not C's) so a change to that shared module is ALSO caught as spec
    drift, not silently invisible to R-F just because no single strategy's own file changed (BUG FIX, rev
    2026-07-11 adversarial self-audit — common.py was omitted from the original hash).

    Add a new code here when its math module is wired up. A spec-locked strategy code NOT in this dict is
    NOT hard-failed by R-F (see the loop below) — SISA's autonomous SL2 authoring routine does not today
    generate a strategy_math module for a newly-synthesized strategy, so hard-failing here would silently
    turn this detective control into a de facto CI gate on autonomous strategy promotion (a "no human/CI
    gate on strategy add" violation, CLAUDE.md settled decision) the first time SISA promotes a genuinely
    new strategy past SHADOW. Instead it prints a visible, non-blocking NOTE — see R-F's report section.
    """
    module_paths_by_code = {
        "A": [os.path.join(STRATEGY_MATH_DIR, "strategy_a.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")],
        "B": [os.path.join(STRATEGY_MATH_DIR, "strategy_b.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")],
        "C": [C_OPTIONS_MATH],
        "D": [os.path.join(STRATEGY_MATH_DIR, "strategy_d.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")],
        "E": [os.path.join(STRATEGY_MATH_DIR, "strategy_e.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")],
    }
    out = {}
    for code, module_paths in module_paths_by_code.items():
        # No slice heading matched at all (not a renumber — the slice is genuinely gone, or its heading
        # rotted): fall back to a path that provably does not exist, so the existing "spec_hash input(s)
        # ... are missing" R-F error still fires unchanged, rather than a None-path crash.
        md_path = _find_slice_by_heading(code) or os.path.join(
            STRATEGY_DIR, f"MISSING_STRATEGY_{code}_SLICE.md")
        out[code] = (md_path, module_paths)
    return out

LIFECYCLE_STATES = ("CANDIDATE", "QUALIFYING", "AUTHORING", "UNDER_REVIEW", "SHADOW", "PAPER",
                    "PROBE", "ADOPTED", "RETIREMENT_PROPOSED", "TERMINATED", "POST_MORTEM", "REJECTED")
# ACTIVE_STATES_YAML now lives in lib/roster_common.py, shared with check_live_roster_parity.py
# (roster-group audit, 2026-08-08 dedup) — see that module's docstring.
ACTIVE_STATES_SQL = {"PROBE", "ADOPTED"}       # seed to_state values meaning is_active
# R-K: the roster_state values (lowercase, as roster.yaml writes them) that require golden-scenario
# coverage — every incubating-or-live phase from SHADOW entry onward. SHADOW is the moment the candidate's
# machinery freezes and its decision prose becomes real, so coverage is required from there, not only at
# PROBE (is_active). CANDIDATE/QUALIFYING/AUTHORING/UNDER_REVIEW/RETIRED/TERMINATED are out of scope.
GOLDEN_COVERAGE_STATES = {"shadow", "paper", "probe", "adopted"}

# '## Strategy <CODE> ...' heading (Strategy.md + each generated slice). '[CANDIDATE]' = not roster-active.
STRATEGY_HEADING = re.compile(r"^##\s+Strategy\s+([A-Z]{1,3})\b([^\n]*)$", re.M)
# A bare UNNEST roster literal, e.g. ['A','B',...], ["A","B",...], or a single-element ['A'] special-case
# (codes are 1-3 letters, matching STRATEGY_HEADING / SEED_ROW) — the thing R-B forbids. BigQuery Standard
# SQL accepts single- AND double-quoted string literals equally, and a hardcode can pin one code, so the
# quote class is ['"] (matched pair via backreference) and the element after the first code may be a comma
# (multi-element list) OR the closing bracket (single-element list). The original single-quote-only,
# two-element-minimum pattern let `["A","B",...]` and `['A']` evade R-B entirely (2026-07-17 audit). The
# comment notation `['A'..'E']` (using `..`, not a comma) still does NOT match — nor does a STRUCT array.
BARE_LITERAL = re.compile(r"\[\s*(['\"])[A-Z]{1,3}\1\s*[,\]]")
# A fixed equal-split divisor `/ N` for ANY integer N (R-B / R-C forbid a fixed divisor, and the roster
# size is not always 5 — SISA resizes N autonomously — so match any /<int>, not just /5).
FIXED_DIVISOR = re.compile(r"/\s*\d+\b")
# A SIMPLE `<col> AS <alias>` binding — one identifier, optionally table-qualified (`cf.amount`), followed
# by `AS <alias>` (case-insensitive). Deliberately restricted to a single bare identifier on the source
# side (NOT an arbitrary expression like `SUM(amount) AS total` or `a + b AS x`) so alias resolution stays
# the same precise instrument the audit asked for, rather than a blind widen that would start crediting
# any expression merely mentioning a money column as "the" money value (R-B / R-C, codebase audit
# 2026-07-26 — see _money_alias_names()).
MONEY_ALIAS_BINDING = re.compile(r"(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)\s+AS\s+([A-Za-z_]\w*)", re.I)
# BigQuery type names, excluded from ever being captured as the ALIAS half of a MONEY_ALIAS_BINDING.
# WHY (codebase audit 2026-07-26, adversarial review of this same fix): `<x> AS <y>` is also the shape of
# a type cast, so `CAST(cf.amount AS NUMERIC)` matched with source="amount", alias="NUMERIC" — which
# resolved the bare TYPE KEYWORD into the money-alias set for the whole file. _money_nearby() then
# whole-word-matches that set against every other divisor's window, so any unrelated `/N` sitting near
# any other CAST(... AS NUMERIC) would false-trip R-B/R-C. That direction of failure is the expensive
# one: R-B/R-C is CI-BLOCKING, so a false positive blocks EVERY merge, not just this check. A defensive
# CAST is idiomatic in this repo's own SQL (bigquery/03_twr_engine.sql, /100, /102), so this was one
# ordinary edit away from firing.
SQL_TYPE_NAMES = frozenset("""
    string bytes int64 int smallint integer bigint tinyint byteint numeric decimal bignumeric bigdecimal
    float64 float bool boolean date datetime time timestamp interval geography json array struct range
""".split())
# A per-strategy slice filename referenced in the plan slice-map, e.g. `06_strategy_d.md`.
SLICE_FILE_REF = re.compile(r"\d+_strategy_([a-z]{1,3})\.md")
# A rail constant in bigquery/35's `consts AS (SELECT 2 AS n_min, ...)` CTE, e.g. "8  AS n_max,".
RAIL_NAMES = (
    "n_min", "n_max", "k_incubate", "k_regime", "max_roundtrip_commission_bps",
    "adoption_rate_window_days", "reject_cooldown_days", "terminate_cooldown_days",
    "keep_cooldown_days",
)
RAIL_CONST = re.compile(r"(\d+)\s+AS\s+(" + "|".join(RAIL_NAMES) + r")\b")
# roster.yaml rails: key -> the arsenal_rails SQL constant name it must equal.
ROSTER_RAIL_KEY_TO_SQL_NAME = {
    "n_min": "n_min", "n_max": "n_max", "k_incubate": "k_incubate", "k_regime": "k_regime",
    "max_roundtrip_commission_bps": "max_roundtrip_commission_bps",
    "adoption_rate_window_days": "adoption_rate_window_days",
}
ROSTER_COOLDOWN_KEY_TO_SQL_NAME = {
    "post_rejection": "reject_cooldown_days",
    "post_termination": "terminate_cooldown_days",
    "post_keep": "keep_cooldown_days",
}
# A seed VALUES row associating a code with a lifecycle to_state (last row per code wins = latest state).
# Two seed SHAPES are recognized (SL5 will use the VALUES shape for one-at-a-time PROBE finalizations;
# the founding batch used the UNNEST shape to seed all five at once with one shared to_state):
#   (1) literal tuple:  (..., 'A', <from_state>, 'ADOPTED', ...)             -- SEED_ROW
#   (2) batch UNNEST:   SELECT ..., 'ADOPTED', ... FROM UNNEST(['A',...]) AS code  -- UNNEST_SEED_BLOCK
# BUG FIX (rev 2026-07-10b, code-review finding #2): the standard events.strategy_lifecycle column order
# is (event_ts, strategy_code, from_state, to_state, ...) — from_state is itself either NULL-ish or a
# quoted lifecycle-state string (e.g. a strategy going PAPER->PROBE has from_state='PAPER'). The original
# SEED_ROW regex captured the FIRST quoted lifecycle-state token after the code, which is from_state, not
# to_state, on any row where from_state is a real (non-NULL) state — verified directly: it read a
# PAPER->PROBE transition as if the code were 'PAPER'. SEED_ROW now explicitly requires the from_state
# slot (NULL / CAST(NULL AS STRING) / a quoted state) between the code and the to_state it captures.
SEED_ROW = re.compile(
    r"'([A-Z]{1,3})'"
    r"\s*,\s*(?:NULL|CAST\(\s*NULL\s+AS\s+STRING\s*\)|'[A-Z_]+')"
    r"\s*,\s*'(" + "|".join(LIFECYCLE_STATES) + r")'"
)
UNNEST_SEED_BLOCK = re.compile(
    r"SELECT\b(?P<select>.*?)\bFROM\s+UNNEST\(\s*\[(?P<codes>(?:\s*'[A-Z]{1,3}'\s*,?\s*)+)\]\s*\)\s+AS\s+code",
    re.S,
)


def _line_no(txt, pos):
    """1-based line number of byte offset `pos` in `txt`."""
    return txt.count("\n", 0, pos) + 1


def _divisor_context(txt, m):
    """(1-based line number, source-line context) for a FIXED_DIVISOR match `m` in `txt`. R-B / R-C
    test whether a money token (amount / cash_flow / deposit) sits next to the divisor to distinguish
    a forbidden equal-split from an unrelated `/N`. Callers layer _money_alias_names() on top of this
    context window (codebase audit 2026-07-26) to also catch a money value that reaches the divisor via
    a column ALIAS rather than the bare column name — see that function's docstring; this function's own
    remit stays exactly "adjacent source lines", unchanged.

    The context spans the match's own first line through its last line, so an internally-wrapped
    `amount /`⏎`5` keeps `amount` in view (FIXED_DIVISOR's `\\s*` spans the newline). When the `/` is the
    FIRST non-space character of its own line — leading-operator SQL style (sqlfluff/dbt
    `operator_new_lines: before`, e.g. `SUM(amount)`⏎`  / 5`) — the money token sits on the PRECEDING
    line, so the context is extended back to include it. A mid-line `/N` (e.g. a `section 5/6` comment)
    is NOT widened, so an unrelated preceding line can never false-trip the adjacency guard (2026-07-17
    audit: the own-line-only window missed exactly the leading-operator wrap it claimed to cover)."""
    n = _line_no(txt, m.start())
    line_start = txt.rfind("\n", 0, m.start()) + 1
    ctx_end = txt.find("\n", m.end())
    if ctx_end == -1:
        ctx_end = len(txt)
    ctx_start = line_start
    if txt[line_start:m.start()].strip() == "":     # operator is first non-space on its line -> reach back
        ctx_start = (txt.rfind("\n", 0, line_start - 1) + 1) if line_start > 0 else 0
    return n, txt[ctx_start:ctx_end]


def _money_alias_names(txt, markers):
    """R-B / R-C (codebase audit 2026-07-26 — CI-BLOCKING fixed-divisor fail-open hole): the set of alias
    names in `txt` that a MONEY_ALIAS_BINDING (`<col> AS <alias>`) traces back, transitively, to one of
    `markers` (e.g. {"amount"} for R-B; {"amount","cash_flow","deposit"} for R-C).

    THE HOLE THIS CLOSES: _divisor_context()'s adjacency window only sees the divisor's own source
    line(s); it never looks at where the money value going into `SUM(...)` originally came from. An
    ordinary SQL restyle that lifts a money column into a CTE under an alias —
        SELECT cf.amount AS raw, a.s AS strategy FROM active a CROSS JOIN cash_flows cf GROUP BY a.s
        )
        SELECT SUM(raw) / 5 AS equal_split
    — leaves NO "amount" (or "cash_flow"/"deposit") token anywhere in the divisor's own-line-or-wrapped
    context, so the R-B `"amount" in ctx` / R-C `"amount" in ctx or ...` guard never fires and a textbook
    forbidden equal-split divisor passes CI clean. An auditor reproduced this directly against the pre-fix
    code (2026-07-26).

    WHY ALIAS RESOLUTION, NOT A BIGGER BLIND LOOKBACK: the 1-line (+leading-operator-wrap) window is
    deliberate (see _divisor_context's own docstring, 2026-07-17 audit) to keep an unrelated `/N` — a
    "section 5/6" comment, an unrelated rail constant — from false-tripping the guard just because it
    happens to sit near a money-flavored word. Widening the window instead of resolving aliases would
    trade this fail-open hole for a fail-closed one (a false CI block, which the unit's own brief flags as
    the constraint that matters most: it would block ALL CI, not just this check). Resolving the alias's
    OWN origin column is the precise fix: it only credits a divisor as money-adjacent when the identifier
    actually IN that window really does trace back to a money column somewhere in the same file, not
    merely because some other line happens to also mention "amount".

    Deliberately restricted to SIMPLE bindings (MONEY_ALIAS_BINDING requires exactly one bare identifier,
    optionally table-qualified, before `AS`) — an aggregate or arithmetic expression (`SUM(amount) AS
    total`, `a+b AS x`) is NOT resolved, so this stays "the alias's origin column", not "anything that
    mentions a money column anywhere in its expression" (which would start crediting unrelated derived
    values as money-adjacent and reopen a different false-negative class). Resolution is transitive via a
    fixed-point loop (`cf.amount AS raw` then `raw AS raw2` resolves raw2 too), because a multi-hop rename
    is no less a restyle than a single hop.

    File-scoped (re-scans the whole file text, like every other regex check here) rather than
    statement-scoped: DERIVED_LIVE_SQL / DBT_RECONCILE are each a single focused file with one cash-flow
    concern, so a same-named alias colliding with an unrelated meaning elsewhere in the SAME file is not a
    realistic false-positive vector in practice — verified empirically against the real repo (see
    check_roster_consistency.py's own `python scripts/check_roster_consistency.py` run) that this adds
    zero aliases (and therefore zero behavior change) on the actual DERIVED_LIVE_SQL / DBT_RECONCILE
    files, which alias no money column today."""
    known = {marker.lower() for marker in markers}
    aliases = set()
    # Drop type-cast matches: `CAST(cf.amount AS NUMERIC)` has the same `<x> AS <y>` shape as a column
    # alias, and crediting the TYPE KEYWORD as a money alias would false-trip this CI-BLOCKING gate on any
    # unrelated divisor elsewhere in the file that happens to sit near another cast to the same type
    # (SQL_TYPE_NAMES, codebase audit 2026-07-26 — adversarial review of this fix).
    bindings = [(s, a) for s, a in MONEY_ALIAS_BINDING.findall(txt) if a.lower() not in SQL_TYPE_NAMES]
    changed = True
    while changed:
        changed = False
        for source, alias in bindings:
            if alias.lower() in known:
                continue
            if source.lower() in known:
                known.add(alias.lower())
                aliases.add(alias)
                changed = True
    return aliases


def _money_nearby(ctx, markers, money_aliases):
    """True if `ctx` (a _divisor_context() window) contains either a bare money `marker` substring (the
    original R-B/R-C adjacency check) OR a whole-word mention of a resolved money `money_aliases` name
    (_money_alias_names() — codebase audit 2026-07-26). Whole-word (`\\b`) matching on the alias side only,
    matching the STRUCTURE of the pre-existing marker check but avoiding a short alias name (e.g. `raw`)
    accidentally substring-matching an unrelated longer identifier."""
    if any(marker in ctx for marker in markers):
        return True
    if not money_aliases:
        return False
    alias_pattern = r"\b(?:" + "|".join(re.escape(a) for a in money_aliases) + r")\b"
    return re.search(alias_pattern, ctx) is not None


def diff_msg(name_a, a, name_b, b):
    parts = []
    only_a = sorted(a - b)
    only_b = sorted(b - a)
    if only_a:
        parts.append(f"in {name_a} but not {name_b}: {only_a}")
    if only_b:
        parts.append(f"in {name_b} but not {name_a}: {only_b}")
    return "R-A roster set mismatch — " + "; ".join(parts)


def headings_in(text):
    return {m.group(1) for m in STRATEGY_HEADING.finditer(text)
            if "[CANDIDATE]" not in m.group(2).upper()}


def roster_doc():
    return load_yaml(ROSTER)


# roster_active_codes() now lives in lib/roster_common.py, imported above (roster-group audit,
# 2026-08-08 dedup) — see that module's docstring for the s["code"] -> s.get("code") KeyError fix
# that motivated pulling this out alongside the dedup.


def slice_codes():
    out = set()
    for p in sorted(glob.glob(os.path.join(STRATEGY_DIR, "*_strategy_*.md"))):
        out |= headings_in(read_text(p))
    return out


def slicemap_codes():
    txt = read_text(PLAN)
    # `(?=^##\s|\Z)`: terminate the section at the next H2 OR end-of-file, so 'Strategy reading' being
    # the LAST H2 in the plan doesn't silently yield an empty section -> spurious R-A full-roster
    # mismatch. Mirrors shared_regime_tokens()'s `(?=^###\s|\Z)` precedent (2026-07-17 audit).
    m = re.search(r"^##\s+Strategy reading\b.*?(?=^##\s|\Z)", txt, re.M | re.S)
    section = m.group(0) if m else ""
    return {c.upper() for c in SLICE_FILE_REF.findall(section)}


PRE_MORTEM_HEADING = re.compile(r"^###\s+Pre-mortem:\s+(.+?)\s*$")
H3_HEADING = re.compile(r"^###\s+")


class SpecHashInputError(ValueError):
    """A required R-F input is absent or structurally malformed."""


def pre_mortem_section(label):
    """Return the exact, heading-delimited `label` pre-mortem bytes for R-F.

    A pre-mortem is an H3 section (`### Pre-mortem: <label>`) whose body runs through the next H3 or EOF.
    Extracting by heading rather than by today's line numbers makes insertion of another segment or
    ordinary edits to a preceding segment harmless, while still detecting a missing, duplicated,
    wrongly-levelled, or empty target section as a clear R-F input failure.
    """
    if not os.path.exists(PRE_MORTEMS):
        raise SpecHashInputError(
            f"shared pre-mortem file {os.path.relpath(PRE_MORTEMS, ROOT)} is missing")
    try:
        raw = read_bytes(PRE_MORTEMS)
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise SpecHashInputError(
            f"shared pre-mortem file {os.path.relpath(PRE_MORTEMS, ROOT)} is not valid UTF-8") from exc

    # Work from raw-decoded text with line endings retained. This preserves the exact on-disk bytes
    # when the selected segment is encoded again, and fence_mask prevents a `### Pre-mortem: ...`
    # example inside a Markdown code fence from becoming a structural heading or section boundary.
    chunks = text.splitlines(keepends=True)
    lines = [chunk.rstrip("\r\n") for chunk in chunks]
    in_fence = fence_mask(lines)
    headings = []
    h3_offsets = []
    offset = 0
    for i, (chunk, line) in enumerate(zip(chunks, lines, strict=True)):  # lines is a 1:1 comprehension over chunks
        if not in_fence[i]:
            if H3_HEADING.match(line):
                h3_offsets.append(offset)
            match = PRE_MORTEM_HEADING.match(line)
            if match:
                headings.append((match.group(1), offset))
        offset += len(chunk)

    matches = [start for found_label, start in headings if found_label == label]
    expected = f"### Pre-mortem: {label}"
    if not matches:
        # A loose occurrence makes the most common structural rot (wrong heading depth, spelling, or
        # trailing title text) actionable instead of looking like an unexplained absent pre-mortem.
        loose = re.search(rf"^#+\s+Pre-mortem:\s+{re.escape(label)}\b.*$", text, re.M)
        detail = "malformed" if loose else "missing"
        raise SpecHashInputError(
            f"{detail} required pre-mortem heading {expected!r} in "
            f"{os.path.relpath(PRE_MORTEMS, ROOT)}")
    if len(matches) != 1:
        raise SpecHashInputError(
            f"duplicate required pre-mortem heading {expected!r} in "
            f"{os.path.relpath(PRE_MORTEMS, ROOT)}")

    start = matches[0]
    end = next((heading_start for heading_start in h3_offsets if heading_start > start), len(text))
    segment = text[start:end]
    # A heading followed only by whitespace is not an accepted pre-mortem and must not silently become
    # a tiny yet valid hash input.
    body = segment[segment.find("\n") + 1:] if "\n" in segment else ""
    if not body.strip():
        raise SpecHashInputError(
            f"empty required pre-mortem segment {expected!r} in "
            f"{os.path.relpath(PRE_MORTEMS, ROOT)}")
    return segment.encode("utf-8")


def pre_mortem_segment(code):
    """Compatibility wrapper for `code`'s own R-F pre-mortem segment."""
    return pre_mortem_section(f"Strategy {code}")


def compute_spec_hash(code, inputs=None):
    """sha256 over shared prose || router pre-mortem || own slice || own pre-mortem || modules (R-F).

    `inputs` lets a caller pass an already-computed spec_hash_inputs() dict to avoid recomputing it
    per-code in a loop; defaults to a fresh call.  pre_mortem_segment() intentionally runs for each code:
    it provides clear structural errors instead of silently hashing the entire combined document.
    """
    md_path, module_paths = (inputs or spec_hash_inputs())[code]
    h = hashlib.sha256()
    for shared_path in SHARED_LOCKED_OPERATIONAL_PROSE:
        h.update(read_bytes(shared_path))
    h.update(pre_mortem_section("Regime router"))
    h.update(read_bytes(md_path))
    h.update(pre_mortem_segment(code))
    for module_path in module_paths:
        h.update(read_bytes(module_path))
    return h.hexdigest()


def arsenal_rails_sql_consts():
    txt = read_text(ARSENAL_SQL)
    return {name: int(val) for val, name in RAIL_CONST.findall(txt)}


def _compare_rails(mapping, container, prefix, sql_consts, errors):
    """R-E: compare each roster.yaml rail key against its arsenal_rails SQL constant, appending a clean
    error for a missing key or a value mismatch. `mapping` is {yaml_key: sql_name}; `container` is the
    roster.yaml sub-dict holding the values; `prefix` is the message label ('rails.' or
    'rails.cooldown_days.'). A SQL const absent from `sql_consts` is skipped (already reported by the
    RAIL_NAMES count guard). The top-level-rails and cooldowns loops were byte-for-byte identical bar the
    container and label, and had already drifted once (the missing-key branch was hand-added to only both
    copies in the 2026-07-14 audit) — consolidated here so the next hardening lands once (2026-07-17
    audit). A present-but-non-integer value (a null/blanked `n_min:` from a bad merge) is reported cleanly
    instead of crashing on int() — the delete-key branch was already clean, but a blanked key skipped it
    and hit an unguarded int().

    BUG FIX (2026-07-29 bug hunt): `int()` SILENTLY TRUNCATES a float instead of raising — int(2.7) == 2
    — so a fractional rail (`n_min: 2.7`) used to compare as if roster.yaml had said 2, and could "agree"
    with bigquery/35's SQL constant on a number the YAML never actually declared. EVERY float is now
    rejected here, not just fractional ones: rails.* is documented throughout roster.yaml as plain
    integer counts, and this file is mutated autonomously by SL1-SL5 with no human review (SISA), so even
    an integral `2.0` is itself worth flagging as suspicious drift (e.g. a stray float computation in a
    generator) rather than silently normalizing it to `2`."""
    for yaml_key, sql_name in mapping.items():
        if sql_name not in sql_consts:
            continue
        if yaml_key not in container:
            errors.append(f"R-E: roster.yaml {prefix}{yaml_key} is missing but "
                          f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]} exists")
            continue
        raw = container[yaml_key]
        if isinstance(raw, float):
            errors.append(f"R-E: roster.yaml {prefix}{yaml_key}={raw!r} is a float, not an integer — cannot "
                          f"compare against bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}"
                          f"={sql_consts[sql_name]} (int() would silently truncate it — fix the YAML to a "
                          f"plain integer literal)")
            continue
        try:
            val = int(raw)
        except (TypeError, ValueError):
            errors.append(f"R-E: roster.yaml {prefix}{yaml_key}={raw!r} is not an integer — "
                          f"cannot compare against bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}"
                          f"={sql_consts[sql_name]}")
            continue
        if val != sql_consts[sql_name]:
            errors.append(f"R-E: roster.yaml {prefix}{yaml_key}={container[yaml_key]} but "
                          f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]}")


# R-J: a bolded regime-token bullet in strategy/01, e.g. `- **UP:** SPY close > ...`.
SHARED_VOCAB_BULLET = re.compile(r"^-\s+\*\*([A-Z][A-Z_]*):\*\*", re.M)


def shared_regime_tokens():
    """R-J: parse the immutable SPY-trend and VIX-regime token SETS from strategy/01_shared_regime_
    vocabulary.md (spy = {UP,DOWN,NEUTRAL} under '### SPY Trend State'; vix = {LOW,NORMAL,HIGH} under
    '### VIX Regime'). Returns (spy_set, vix_set, path); (None, None, path) if the file is absent.

    The vocab path is derived from STRATEGY_DIR at CALL time (not a frozen module global built once from
    the real ROOT) so the tests/test_roster_consistency.py repo_copy fixture — which copies the whole
    strategy/ dir and monkeypatches STRATEGY_DIR at the tmp copy — is honored, exactly as spec_hash_inputs()
    re-reads STRATEGY_DIR/STRATEGY_MATH_DIR on every call. Section-scoped so the NORMAL/INVERTED yield-curve
    and HEALTHY/WEAK breadth labels lower in the same file can never leak into the SPY/VIX token sets."""
    path = os.path.join(STRATEGY_DIR, "01_shared_regime_vocabulary.md")
    if not os.path.exists(path):
        return None, None, path
    txt = read_text(path)

    def section_tokens(header):
        m = re.search(r"^###\s+" + re.escape(header) + r"\s*$(.*?)(?=^###\s|\Z)", txt, re.M | re.S)
        return set(SHARED_VOCAB_BULLET.findall(m.group(1))) if m else set()

    return section_tokens("SPY Trend State"), section_tokens("VIX Regime"), path


def arsenal_coverage_cell_tokens():
    """R-J: extract the two `UNNEST([...]) AS spy_trend` / `... AS vix_regime` cell literals from
    bigquery/35_strategy_arsenal.sql's state.arsenal_regime_coverage `cells` CTE. Returns
    (spy_set, vix_set); either element is None if its literal cannot be located. The `AS code` seed
    UNNEST (a different alias) cannot collide."""
    txt = read_text(ARSENAL_SQL)

    def toks(alias):
        m = re.search(r"UNNEST\(\s*\[([^\]]*)\]\s*\)\s+AS\s+" + alias + r"\b", txt)
        return set(re.findall(r"'([A-Z_]+)'", m.group(1))) if m else None

    return toks("spy_trend"), toks("vix_regime")


# R-K: a "Strategy <CODE>" whole-token mention in a founding fixture's prose (id/situation/rationale).
# `[A-Z]{1,3}\b` matches only the 1-3-letter uppercase code (so "Strategy Arsenal" does not match code
# 'A' — after 'A' comes lowercase 'r', no word boundary), mirroring STRATEGY_HEADING / SEED_ROW.
SCENARIO_STRATEGY_MENTION = re.compile(r"\bStrategy\s+([A-Z]{1,3})\b")


def scenario_docs():
    """R-K: load the golden-scenario fixtures -> list of scenario dicts. Returns None (not []) when the
    file is ABSENT, so main() can SKIP R-K cleanly on a pre-ITEM-20 checkout — distinct from a present-but-
    empty file (which yields [] and legitimately covers nothing). SCENARIOS_YAML is read at CALL time so a
    monkeypatched path is honored, like slice_codes()/shared_regime_tokens()."""
    if not os.path.exists(SCENARIOS_YAML):
        return None
    doc = load_yaml(SCENARIOS_YAML)
    return doc.get("scenarios", []) or []


def golden_covered_codes(scenarios):
    """R-K: the set of strategy codes the fixture set gives prose-regression coverage. A scenario covers
    code X if EITHER (a) a governing_files entry is X's own per-strategy slice `NN_strategy_<x>.md` (the
    signal SL5 stamps on new-strategy fixtures — numbering-agnostic via SLICE_FILE_REF), OR (b) it names
    "Strategy X" as a whole token in its id/situation/rationale (the founding A-E fixtures, which pin the
    aggregate Strategy.md and name their strategy in prose)."""
    covered = set()
    for sc in scenarios:
        if not isinstance(sc, dict):
            continue
        for g in sc.get("governing_files", []) or []:
            m = SLICE_FILE_REF.search(str(g))
            if m:
                covered.add(m.group(1).upper())
        text = " ".join(str(sc.get(k, "") or "") for k in ("id", "situation", "rationale"))
        for m in SCENARIO_STRATEGY_MENTION.finditer(text):
            covered.add(m.group(1))
    return covered


def seed_active_codes():
    # BUG FIX (rev 2026-07-10b, code-review finding #2): the previous version processed ALL SEED_ROW
    # matches in one pass, then ALL UNNEST_SEED_BLOCK matches in a second pass, so an UNNEST block always
    # overrode a literal-tuple row for the same code regardless of which actually appears LATER in the
    # file. Both match kinds are now merged into a single list of (start_pos, code, state) events and
    # applied in true textual order, so "the last row/block per code wins" is what actually happens.
    txt = read_text(ARSENAL_SQL)
    events = []
    for m in SEED_ROW.finditer(txt):
        events.append((m.start(), m.group(1), m.group(2)))
    for m in UNNEST_SEED_BLOCK.finditer(txt):
        # Capture to_state, NOT from_state. The SELECT projection is (event_ts, code, from_state,
        # to_state, driver_routine, note); grabbing the FIRST quoted lifecycle-state read from_state
        # instead of to_state on any batch whose from_state is a real quoted state (e.g. a
        # PAPER->PROBE / ADOPTED->TERMINATED batch retirement) — the exact swap SEED_ROW was hardened
        # against (lines above) but the UNNEST path was left unpatched (2026-07-17 audit). Anchor on
        # the bare `code` loop-var column + the from_state slot, mirroring SEED_ROW, so the founding
        # batch (from_state = CAST(NULL AS STRING)) still reads 'ADOPTED' and a future quoted-
        # from_state batch reads its true to_state.
        state_m = re.search(
            r"\bcode\b\s*,\s*(?:NULL|CAST\(\s*NULL\s+AS\s+STRING\s*\)|'[A-Z_]+')"
            r"\s*,\s*'(" + "|".join(LIFECYCLE_STATES) + r")'",
            m.group("select"))
        if not state_m:
            continue
        state = state_m.group(1)
        for code in re.findall(r"'([A-Z]{1,3})'", m.group("codes")):
            events.append((m.start(), code, state))
    events.sort(key=lambda e: e[0])
    latest = {}
    for _, code, state in events:
        latest[code] = state          # true textual order: later position wins
    return {c for c, s in latest.items() if s in ACTIVE_STATES_SQL}, len(latest)


# R-L: the state.strategy_declared_frequency seed block in bigquery/166 -- `INSERT INTO
# ...state.strategy_declared_frequency... SELECT * FROM UNNEST([STRUCT('A' AS strategy_code, ...), ...]) AS
# seed`. Anchored on the INSERT's own target table name AND the seed query's `AS seed` alias (not just any
# UNNEST([...STRUCT(...)...]) shape in the file -- bigquery/166 also has an unrelated
# `STRUCT(enabled, reason, set_by, control_ts)` row-value elsewhere), so an unrelated STRUCT(...) literal
# cannot be mistaken for this seed. Only ever scans DECLARED_FREQUENCY_SQL, never this checker's own source
# text (the self-match trap a regex/grep-based checker can fall into).
DECLARED_FREQUENCY_SEED_BLOCK = re.compile(
    r"INSERT\s+INTO\s+`[^`]*state\.strategy_declared_frequency`.*?"
    r"FROM\s+UNNEST\(\s*\[(?P<structs>.*?)\]\s*\)\s+AS\s+seed",
    re.S,
)
# The leading quoted strategy_code inside each STRUCT(...) row of that block -- the first-row shape
# `STRUCT('A' AS strategy_code, ...)` and the positional shape every row after it uses, `STRUCT('B', ...)`.
DECLARED_FREQUENCY_STRUCT_CODE = re.compile(r"STRUCT\(\s*'([A-Z]{1,3})'")


def declared_frequency_seed_codes():
    """R-L: the set of strategy codes seeded into state.strategy_declared_frequency, parsed straight out of
    bigquery/166_capital_dormancy_sweep.sql's own SQL text -- CI has no BigQuery credentials for this
    script, so the live table can never be queried, the same offline-parse posture seed_active_codes()
    already uses against bigquery/35's state.strategy_roster seed. Returns None (not an empty set) if
    bigquery/166 is absent or its INSERT/UNNEST seed shape cannot be located at all, so the caller can tell
    "genuinely zero rows parsed" apart from "could not find the block" and print a clean NOTE for the
    latter instead of silently treating it as zero coverage."""
    if not os.path.exists(DECLARED_FREQUENCY_SQL):
        return None
    txt = read_text(DECLARED_FREQUENCY_SQL)
    m = DECLARED_FREQUENCY_SEED_BLOCK.search(txt)
    if not m:
        return None
    return set(DECLARED_FREQUENCY_STRUCT_CODE.findall(m.group("structs")))


def main():
    if not os.path.exists(ROSTER):
        print("ROSTER CONSISTENCY: SKIP — strategy/roster.yaml absent (pre-2026-07-10 checkout, before the "
              "Strategy Arsenal loop landed). Nothing to check.")
        return 0

    errors = []
    notes = []   # visible, NON-blocking observations (R-F coverage gaps) — never fail CI, see R-F below
    doc = roster_doc()
    roster_codes = roster_active_codes(doc)

    # ---- R-A: roster set agreement across all five surfaces ----
    # Guard the top-level inputs the same way ARSENAL_SQL / the derived SQL / DBT_RECONCILE are guarded
    # below: a missing Strategy.md / Claude_Task_Plan.md should be a clean R-A error, not an uncaught
    # open() traceback that never prints the contractual `ROSTER CONSISTENCY: FAIL` line CI/BigQuery
    # bridges parse (2026-07-17 audit — R-H even carries a now-reachable PLAN/CADENCE guard).
    if not os.path.exists(STRATEGY_MD):
        errors.append("R-A: Strategy.md is missing — cannot compare its '## Strategy' sections against "
                      "strategy/roster.yaml's roster-active set")
        md_codes = set()
    else:
        md_codes = headings_in(read_text(STRATEGY_MD))
        if not md_codes:
            errors.append("R-A: found no non-candidate '## Strategy <code>' heading in Strategy.md "
                          "(STRATEGY_HEADING rotted, or Strategy.md is empty?)")
    sl_codes = slice_codes()
    if not os.path.exists(PLAN):
        errors.append("R-A: Claude_Task_Plan.md is missing — cannot read the '## Strategy reading' "
                      "slice-map")
        map_codes = set()
    else:
        map_codes = slicemap_codes()
    if not os.path.exists(ARSENAL_SQL):
        errors.append("R-A: bigquery/35_strategy_arsenal.sql absent but strategy/roster.yaml exists — the "
                      "state.strategy_roster seed has no source to compare against")
        seed_codes = set()
    else:
        seed_codes, n_seed = seed_active_codes()
        if n_seed == 0:
            errors.append("R-A: parsed zero code/to_state seed rows from bigquery/35_strategy_arsenal.sql "
                          "— did the seed VALUES shape change? (update SEED_ROW). Each founding row must "
                          "quote the code then its to_state, e.g. (..., 'A', ..., 'ADOPTED', ...).")
    for other_name, other in (("Strategy.md '## Strategy' sections", md_codes),
                              ("strategy/ slices", sl_codes),
                              ("Claude_Task_Plan.md slice-map", map_codes),
                              ("state.strategy_roster seed (bigquery/35)", seed_codes)):
        if other != roster_codes:
            errors.append(diff_msg("strategy/roster.yaml (roster-active)", roster_codes, other_name, other))

    # ---- R-B: no bare literal / fixed divisor in the LIVE derived SQL ----
    # Full-text (not line-by-line) scan: a line-by-line search cannot detect the exact pattern it
    # exists to forbid if a SQL formatter wraps it across two lines (2026-07-14 audit finding,
    # confirmed empirically: `['A',\n  'B','C','D','E']` matched BARE_LITERAL on neither line).
    for path in DERIVED_LIVE_SQL:
        rel = os.path.relpath(path, ROOT)
        if not os.path.exists(path):
            errors.append(f"R-B: expected roster-derived file {rel} is missing")
            continue
        txt = read_text(path)
        for m in BARE_LITERAL.finditer(txt):
            n = _line_no(txt, m.start())
            snippet = " ".join(m.group(0).split())
            errors.append(f"R-B: {rel}:{n} still has a bare ['A','B',...] roster literal — read "
                          f"`state.active_strategy_codes` instead: {snippet}")
        # money_aliases: resolve `<col> AS <alias>` bindings before scanning divisors (codebase audit
        # 2026-07-26) so a money value that reaches the divisor via an aliased column — not the bare
        # `amount` token — still trips the adjacency guard below. See _money_alias_names() docstring.
        money_aliases = _money_alias_names(txt, ("amount",))
        for m in FIXED_DIVISOR.finditer(txt):
            n, ctx = _divisor_context(txt, m)
            if _money_nearby(ctx, ("amount",), money_aliases):
                errors.append(f"R-B: {rel}:{n} still has a fixed `/ N` equal-split divisor — use an "
                              f"as-of-flow-date COUNT(*) FROM state.strategy_roster: {ctx.strip()}")

    # ---- R-C: count-agnostic dbt reconcile test ----
    if not os.path.exists(DBT_RECONCILE):
        errors.append("R-C: dbt/tests/assert_cash_flows_reconcile.sql is missing")
    else:
        # Full-text (not line-by-line) scan, mirroring R-B: a line-by-line search cannot see a
        # divisor a SQL formatter wrapped across two lines (`amount /\n  5`) — the exact vacuous-pass
        # R-B was hardened against but R-C was not (2026-07-17 audit). FIXED_DIVISOR's `\s*` spans the
        # newline in a full-text scan. Adjacency guard (matching R-B's "amount" co-occurrence): without
        # it ANY unrelated N/M-shaped text (e.g. a RUNBOOK "section 5/6" reference) trips FIXED_DIVISOR
        # and false-fails CI. _divisor_context() spans the match's first line through its last line (and
        # reaches back one line for a leading-operator wrap) so the amount/cash_flow/deposit token is
        # still found when the wrap separates it from the divisor. money_aliases: same alias-resolution
        # layer as R-B (codebase audit 2026-07-26) so an aliased money column (e.g. `cf.amount AS raw`
        # then `SUM(raw) / 5`) still trips this guard — see _money_alias_names() docstring.
        txt = read_text(DBT_RECONCILE)
        money_aliases = _money_alias_names(txt, ("amount", "cash_flow", "deposit"))
        for m in FIXED_DIVISOR.finditer(txt):
            n, ctx = _divisor_context(txt, m)
            if _money_nearby(ctx, ("amount", "cash_flow", "deposit"), money_aliases):
                errors.append(f"R-C: dbt/tests/assert_cash_flows_reconcile.sql:{n} hardcodes the roster "
                              f"size (a `/ N` amount-split assumption) — the reconciliation must be "
                              f"count-agnostic (per-strategy sum): {ctx.strip()}")

    # ---- R-D: per-strategy routines named in roster.yaml exist in cadence.yaml ----
    if not os.path.exists(CADENCE):
        errors.append("R-D: ops/cadence.yaml is missing — cannot validate that per_strategy_routine "
                      "references name a real routine id")
    else:
        cad = load_yaml(CADENCE)
        cad_ids = {r["id"] for r in cad.get("routines", []) or [] if "id" in r}
        for s in doc.get("strategies", []) or []:
            rt = s.get("per_strategy_routine")
            if rt and rt not in cad_ids:
                errors.append(f"R-D: strategy {s.get('code')!r} names per_strategy_routine '{rt}' which is "
                              f"NOT a routine id in ops/cadence.yaml")

    # ---- R-E: bigquery/35's arsenal_rails SQL constants agree with roster.yaml's rails block ----
    rails_doc = doc.get("rails", {}) or {}
    if not os.path.exists(ARSENAL_SQL):
        errors.append("R-E: bigquery/35_strategy_arsenal.sql absent but strategy/roster.yaml has a rails "
                      "block — nothing to compare arsenal_rails' SQL constants against")
    else:
        sql_consts = arsenal_rails_sql_consts()
        if len(sql_consts) < len(RAIL_NAMES):
            errors.append(f"R-E: parsed only {len(sql_consts)}/{len(RAIL_NAMES)} rail constants from "
                          f"bigquery/35_strategy_arsenal.sql's consts CTE — did the `<N> AS <name>` shape "
                          f"change? (update RAIL_CONST)")
        # Both loops must fire on a MISSING yaml key too, not just a mismatched one — a key silently
        # deleted from roster.yaml's rails block (accidental deletion, bad merge, a partial rails:
        # block copy-paste) previously left the corresponding SQL constant with NOTHING to compare
        # against, so R-E vacuously passed (2026-07-14 audit finding, confirmed empirically: deleting
        # rails.n_min end-to-end still printed "ROSTER CONSISTENCY: OK"). _compare_rails() carries that
        # missing-key branch (and a present-but-non-integer clean error) for BOTH the top-level rails
        # and the nested cooldown_days sub-block.
        _compare_rails(ROSTER_RAIL_KEY_TO_SQL_NAME, rails_doc, "rails.", sql_consts, errors)
        cooldowns = rails_doc.get("cooldown_days", {}) or {}
        _compare_rails(ROSTER_COOLDOWN_KEY_TO_SQL_NAME, cooldowns, "rails.cooldown_days.", sql_consts, errors)

    # ---- R-F: spec-locked strategies' machinery hash agrees with roster.yaml's spec_hash ----
    spec_inputs = spec_hash_inputs()
    for s in doc.get("strategies", []) or []:
        code = s.get("code")
        if not s.get("spec_locked_since"):
            continue
        if code not in spec_inputs:
            # NON-blocking by design (see spec_hash_inputs() docstring): a spec-locked strategy with no
            # wired-up math module is a real coverage gap worth surfacing, but hard-failing here would
            # make R-F a de facto CI gate on SISA's autonomous strategy promotion the first time it
            # promotes a genuinely new strategy — exactly the "no gate on strategy add" line CLAUDE.md
            # draws. Visible note only; does not affect exit code.
            notes.append(f"R-F: strategy {code!r} is spec_locked_since={s.get('spec_locked_since')} but has "
                         f"no spec_hash_inputs() entry — its locked machinery is NOT drift-checked by R-F. "
                         f"Add a strategy_math module for it (or extend spec_hash_inputs() to its existing "
                         f"math) and register the path there to close the gap.")
            continue
        md_path, module_paths = spec_inputs[code]
        missing = [p for p in [*SHARED_LOCKED_OPERATIONAL_PROSE, md_path, *module_paths]
                   if not os.path.exists(p)]
        if missing:
            errors.append(f"R-F: strategy {code!r} is spec_locked_since={s.get('spec_locked_since')} but its "
                          f"spec_hash input(s) {[os.path.relpath(p, ROOT) for p in missing]} are missing")
            continue
        try:
            actual = compute_spec_hash(code, inputs=spec_inputs)
        except SpecHashInputError as exc:
            errors.append(f"R-F: strategy {code!r} is spec_locked_since={s.get('spec_locked_since')} but its "
                          f"{exc}")
            continue
        declared = s.get("spec_hash")
        inputs_desc = " + ".join(
            [*(os.path.relpath(p, ROOT) for p in SHARED_LOCKED_OPERATIONAL_PROSE),
             f"{os.path.relpath(PRE_MORTEMS, ROOT)}: Pre-mortem Regime router",
             os.path.relpath(md_path, ROOT),
             f"{os.path.relpath(PRE_MORTEMS, ROOT)}: Pre-mortem Strategy {code}",
             *(os.path.relpath(p, ROOT) for p in module_paths)])
        if not declared:
            errors.append(f"R-F: strategy {code!r} is spec_locked_since={s.get('spec_locked_since')} but "
                          f"roster.yaml has no spec_hash — add spec_hash: \"{actual}\"")
        elif declared != actual:
            errors.append(f"R-F: strategy {code!r} spec_hash mismatch — roster.yaml declares {declared!r} but "
                          f"{inputs_desc} now hash to {actual!r}. Locked machinery changed post spec-lock "
                          f"({s.get('spec_locked_since')}) — per Experiment_Parameters.md this requires "
                          f"terminate-and-restart-as-new, not a silent edit; if this IS a genuine restart, "
                          f"update spec_hash together with is_restart_of/spec_locked_since.")

    # ---- R-G: dbt schema.yml accepted_values tests on the `strategy` column must track the roster
    # (2026-07-14 audit finding) — CLAUDE.md's settled decision makes strategy add/delete fully
    # autonomous (SISA), so roster.yaml's active-code set can grow/shrink with no human touch at
    # any time; these 4 hardcoded ['A'..'E'] lists would then silently start failing `dbt test`
    # (advisory-only — see ci.yml) at exactly the moment operators most need a clean signal. Only
    # ever inspects columns literally named `strategy`, so it cannot trip on the unrelated
    # `conviction_features.decision` accepted_values block in the same file (that block widened
    # 2026-07-30 from ['GO'] to ['GO', 'GO (add tranche)'] with bigquery/116's GO-family filter — the
    # exact value is irrelevant here precisely because the column is not named `strategy`). ----
    if os.path.exists(DBT_SCHEMA_ACCEPTED_VALUES):
        schema_doc = load_yaml(DBT_SCHEMA_ACCEPTED_VALUES)
        found_blocks = 0        # see the zero-found check below — this is what makes R-G non-vacuous
        for model in schema_doc.get("models", []) or []:
            for col in model.get("columns", []) or []:
                if col.get("name") != "strategy":
                    continue
                for test in col.get("tests", []) or []:
                    if not isinstance(test, dict) or "accepted_values" not in test:
                        continue
                    found_blocks += 1
                    av = test["accepted_values"]
                    if not isinstance(av, dict):
                        # `accepted_values` authored as a bare list/scalar instead of a {values: [...]}
                        # mapping (malformed dbt YAML) previously AttributeError'd on `.get` -> uncaught
                        # traceback rather than a clean R-G FAIL line (2026-07-17 audit).
                        errors.append(
                            f"R-G: dbt/models/analytics/schema.yml model {model.get('name')!r} column "
                            f"'strategy' accepted_values is not a {{values: [...]}} mapping ({av!r})")
                        continue
                    codes = set(av.get("values", []) or [])
                    # No `codes and` short-circuit: an accepted_values(strategy) degenerated to
                    # `values: []` (or a dropped `values:` key) is a roster-vs-schema divergence that must
                    # be FLAGGED, not treated as clean by the falsy-empty-set skip (2026-07-17 audit —
                    # R-G is the CI-blocking guard; ci.yml's dbt accepted_values test is advisory-only).
                    if codes != roster_codes:
                        errors.append(
                            f"R-G: dbt/models/analytics/schema.yml model {model.get('name')!r} column "
                            f"'strategy' accepted_values {sorted(codes)} no longer matches the roster-active "
                            f"set {sorted(roster_codes)} — update this list (or drop the test) alongside "
                            f"the roster change.")
        # VACUOUS-PASS FIX (roster-group audit, 2026-08-08): the loop above only ever FAILS on a STALE
        # block — if every accepted_values(strategy) block is instead DELETED outright, `found_blocks`
        # stays 0, the loop body never executes, and R-G printed clean. That makes deleting the very
        # tests R-G exists to police the easiest way to silence it — the file still EXISTS (so the
        # `else` branch below never fires either) with zero qualifying blocks inside. Flag that
        # zero-found case explicitly instead of trusting an empty loop to mean "nothing to report".
        if found_blocks == 0:
            errors.append(
                "R-G: dbt/models/analytics/schema.yml parsed but contains ZERO accepted_values tests on "
                "a `strategy` column — either every such test was deleted (silencing the very roster-vs-"
                "schema drift check R-G exists to police) or the schema shape changed underneath this "
                "scan. Restore at least one accepted_values(strategy) test (or, if the shape genuinely "
                "changed, update R-G's column-name scan to match it).")
    else:
        errors.append("R-G: dbt/models/analytics/schema.yml is missing — cannot validate that "
                      "accepted_values(strategy) tests track the roster")

    # ---- R-H: candidate-feed dataset name (2026-07-15 self-improvement audit) ----
    # The live SISA candidate-intake table is state.strategy_candidates (bigquery/35); no
    # events.strategy_candidates object exists. A stray reintroduction of the wrong dataset name here
    # would silently point D1/Q1/Q3/A1's write instructions (and SL1's read instructions) at a
    # nonexistent table again.
    for path in (PLAN, CADENCE):
        if not os.path.exists(path):
            continue
        txt = read_text(path)
        if "events.strategy_candidates" in txt:
            rel = os.path.relpath(path, ROOT)
            n = txt.split("events.strategy_candidates")[0].count("\n") + 1
            errors.append(f"R-H: {rel}:{n} references `events.strategy_candidates`, which does not "
                          f"exist live — the SISA candidate-intake table is `state.strategy_candidates` "
                          f"(bigquery/35_strategy_arsenal.sql). Fix the dataset name.")

    # ---- R-I: review_cadence declared for every roster-active strategy (2026-07-15 self-improvement
    # audit) — D1/W3 read this field instead of a hardcoded strategy-letter enumeration; a
    # roster-active strategy missing it (or with an invalid value) would silently drop out of BOTH
    # D1's daily opportunity check and W3's weekly position deep-dive.
    VALID_REVIEW_CADENCE = {"reactive", "long_horizon"}
    for s in doc.get("strategies", []) or []:
        code = s.get("code")
        if code not in roster_codes:
            continue   # candidate/shadow/paper/terminated entries are out of scope for this check
        rc = s.get("review_cadence")
        if rc not in VALID_REVIEW_CADENCE:
            errors.append(f"R-I: strategy/roster.yaml strategy {code!r} has review_cadence={rc!r} — "
                          f"must be one of {sorted(VALID_REVIEW_CADENCE)}. D1/W3 read this field to "
                          f"decide whether {code} is in scope for the daily opportunity check / weekly "
                          f"position deep-dive.")

    # ---- R-J: arsenal_regime_coverage cell tokens == the strategy/01 shared regime vocabulary ----
    # (H7 fix, 2026-07-17). Only runs when bigquery/35 exists (its absence is already reported by R-A/R-E).
    if os.path.exists(ARSENAL_SQL):
        spy_vocab, vix_vocab, vocab_path = shared_regime_tokens()
        if spy_vocab is None:
            errors.append(f"R-J: {os.path.relpath(vocab_path, ROOT)} absent — cannot source the canonical "
                          f"SPY-trend / VIX-regime tokens that arsenal_regime_coverage's cells must equal.")
        elif not spy_vocab or not vix_vocab:
            errors.append("R-J: parsed zero SPY-trend and/or VIX-regime tokens from "
                          "strategy/01_shared_regime_vocabulary.md — did the '### SPY Trend State' / "
                          "'### VIX Regime' heading or the bolded-bullet shape change? (update "
                          "SHARED_VOCAB_BULLET / the section headers).")
        else:
            spy_cells, vix_cells = arsenal_coverage_cell_tokens()
            if spy_cells is None or vix_cells is None:
                errors.append("R-J: could not locate both `UNNEST([...]) AS spy_trend` and "
                              "`... AS vix_regime` cell literals in bigquery/35_strategy_arsenal.sql's "
                              "arsenal_regime_coverage view — did the `cells` CTE shape change?")
            else:
                if spy_cells != spy_vocab:
                    errors.append(f"R-J: bigquery/35 arsenal_regime_coverage spy_trend cell tokens "
                                  f"{sorted(spy_cells)} != strategy/01 shared vocabulary {sorted(spy_vocab)} "
                                  f"— align the UNNEST literal with the immutable SPY Trend State tokens.")
                if vix_cells != vix_vocab:
                    errors.append(f"R-J: bigquery/35 arsenal_regime_coverage vix_regime cell tokens "
                                  f"{sorted(vix_cells)} != strategy/01 shared vocabulary {sorted(vix_vocab)} "
                                  f"— align the UNNEST literal with the immutable VIX Regime tokens.")

    # ---- R-K: golden-scenario prose-regression coverage for every SHADOW/PAPER/PROBE/ADOPTED strategy
    # (2026-07-17, finding DEF-4) — SISA can adopt a strategy whose DECISION prose (activation / entry
    # rules) has zero behavioral coverage; the golden fixture set is the only gate that reads what a
    # routine would DECIDE, and nothing forced a newcomer into it. This makes an uncovered incubating/live
    # strategy a BUILD FAILURE, so SL5's SHADOW-register step (which authors >=2 scenarios in the same
    # commit that adds the roster.yaml entry) is enforced "same-commit-or-CI-fails", exactly like R-A on
    # the bigquery/35 seed. Mechanical consistency gate, NOT a human review gate on strategy add. ----
    scenarios = scenario_docs()
    if scenarios is not None:  # None = scenarios.yaml absent (pre-ITEM-20 checkout) -> skip cleanly
        covered = golden_covered_codes(scenarios)
        for s in doc.get("strategies", []) or []:
            code = s.get("code")
            state = str(s.get("roster_state", "")).lower()
            if state not in GOLDEN_COVERAGE_STATES:
                continue
            # Coverage is DEFINED via the strategy's own per-strategy slice (governing_files) or a
            # 'Strategy <code>' prose mention. A missing slice is handled by state:
            #   PROBE/ADOPTED (roster-active): R-A INDEPENDENTLY FAILs (the slice heading is absent from
            #     slice_codes()), so keep a non-blocking note here to avoid double-reporting the same
            #     missing-slice condition — the exit code is already 1 via R-A.
            #   SHADOW/PAPER: R-A/R-D never inspect a non-active entry (roster_active_codes filters to
            #     probe/adopted), so R-K is the ONLY gate. Do NOT skip — fall through to the coverage
            #     check, so a half-applied SL5 SHADOW-register (roster entry lands but its slice + >=2
            #     scenarios do NOT) FAILs here, exactly like R-A blocks a half-applied fanout. A
            #     slice-less SHADOW/PAPER code can still satisfy R-K via a 'Strategy <code>' prose mention
            #     (path b); only a code with NO coverage at all fails. This is a MECHANICAL
            #     same-commit-or-CI-fails gate the autonomous registrar satisfies in-band (SL5 authors the
            #     slice + scenarios in the same commit), NOT a human review gate on strategy add — so it
            #     does not reverse the SISA no-human-gate posture (CLAUDE.md settled decision; R-K's own
            #     doc frames it as mechanical). Fixed 2026-07-17 on owner direction — the prior slice-less
            #     non-blocking note left SHADOW/PAPER wholly un-enforced (a real vacuous-pass gap).
            if code not in sl_codes:
                if code in roster_codes:                          # PROBE/ADOPTED — R-A already fails
                    notes.append(
                        f"R-K: strategy {code!r} (roster_state={state}) has no per-strategy slice file — "
                        f"the missing slice is already reported by R-A (roster-active heading absent); "
                        f"coverage not separately re-checked here (non-blocking).")
                    continue
                # SHADOW/PAPER: no independent guard exists — enforce coverage (prose path b) below.
            if code not in covered:
                errors.append(
                    f"R-K: strategy {code!r} (roster_state={state}) has NO golden-scenario coverage in "
                    f"tests/golden_scenarios/scenarios.yaml — every SHADOW/PAPER/PROBE/ADOPTED strategy "
                    f"must be referenced by >=1 scenario (its per-strategy slice "
                    f"'NN_strategy_{str(code).lower()}.md' in governing_files, or a 'Strategy {code}' "
                    f"prose mention). SL5's SHADOW-register step authors >=2 fixtures (one "
                    f"router-ACTIVATE, one router-DO-NOT-ACTIVATE boundary) in the SAME commit that "
                    f"registers the strategy, so its decision prose cannot land with zero "
                    f"prose-regression coverage.")

    # ---- R-L: every roster-active strategy has a state.strategy_declared_frequency seed row (2026-08-11,
    # capital-dormancy-sweep gap) -- a missing row is silently treated as is_low_frequency_by_design=FALSE
    # (fail-open, "not nomadic") by the live SQL, and SISA can adopt a new strategy with no human step to
    # ever add one. NON-blocking by design, matching R-F's own NOTE-only branch: hard-failing here would
    # make a hand-maintained seed a de facto CI gate on autonomous strategy adoption, which CLAUDE.md's
    # settled decision forbids.
    freq_codes = declared_frequency_seed_codes()
    if freq_codes is None:
        notes.append(
            f"R-L: could not locate the state.strategy_declared_frequency seed block in "
            f"{os.path.relpath(DECLARED_FREQUENCY_SQL, ROOT)} (file missing, or its INSERT/UNNEST seed "
            f"shape changed) — skipping the declared-frequency coverage check (non-blocking).")
    else:
        for code in sorted(roster_codes - freq_codes):
            notes.append(
                f"R-L: roster-active strategy {code!r} has no row in state.strategy_declared_frequency "
                f"({os.path.relpath(DECLARED_FREQUENCY_SQL, ROOT)}) — the capital-dormancy-sweep "
                f"eligibility view and bigquery/167_nomadic_capital.sql's NOMADIC classification both treat "
                f"a missing row as is_low_frequency_by_design=FALSE (fail-open: holds standing capital like "
                f"any other strategy, never swept as dormant or excluded as nomadic). Add a seed row to "
                f"bigquery/166_capital_dormancy_sweep.sql sourced from strategy/0N_strategy_{code.lower()}"
                f".md's 'Declared expected frequency' section. Non-blocking: SISA's SL1-SL5 can adopt a new "
                f"strategy with no human step, and hard-failing here would turn this hand-maintained seed "
                f"into a de facto CI gate on autonomous strategy adoption (CLAUDE.md's settled decision "
                f"forbids that — same rationale as R-F's own NOTE-only branch).")

    # ---- report ----
    if errors:
        print("ROSTER CONSISTENCY: FAIL\n")
        for e in errors:
            print(" - " + e)
        if notes:
            print("\nNOTES (non-blocking):")
            for n in notes:
                print(" - " + n)
        print("\nFix strategy/roster.yaml and its mirrors (the state.strategy_roster seed in "
              "bigquery/35_strategy_arsenal.sql, Strategy.md '## Strategy' sections, strategy/ slices, the "
              "Claude_Task_Plan.md slice-map) + the roster-derived SQL so they agree, then re-run. This is "
              "the roster analog of scripts/check_cadence_consistency.py (see ops/RUNBOOK.md §39).")
        return 1

    print(f"ROSTER CONSISTENCY: OK — {len(roster_codes)} roster-active strategies ({sorted(roster_codes)}) "
          f"agree across roster.yaml, the bigquery/35 seed, Strategy.md, the strategy/ slices, and the plan "
          f"slice-map; no bare roster literal or fixed /5 divisor in the live derived SQL; the dbt reconcile "
          f"test is count-agnostic; arsenal_rails' SQL constants agree with roster.yaml's rails block; every "
          f"SPEC_HASH_INPUTS-covered spec-locked strategy's spec_hash agrees with shared operational prose, "
          f"the shared router and own pre-mortem segments, its .md slice, and math module(s); dbt "
          f"schema.yml accepted_values(strategy) tests agree with the roster-active set; "
          f"no stray events.strategy_candidates dataset-name reference; every roster-active strategy "
          f"declares a valid review_cadence; arsenal_regime_coverage's cell tokens equal the strategy/01 "
          f"shared regime vocabulary; every SHADOW/PAPER/PROBE/ADOPTED strategy has >=1 golden-scenario "
          f"fixture.")
    if notes:
        print("\nNOTES (non-blocking):")
        for n in notes:
            print(" - " + n)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

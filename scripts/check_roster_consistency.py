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
       never mistaken for live.)

  R-C  COUNT-AGNOSTIC dbt RECONCILE TEST. dbt/tests/assert_cash_flows_reconcile.sql must not hardcode the
       roster size: no `/ 5` divisor and no `amount/5` / 'exactly 5' assumption. The reconciliation (sum of
       each strategy's attributed deposits + redistributions == its cash_flows) must hold for ANY roster
       size. FAIL if a 5-hardcode remains. (Test CONTENT edit only — NOT a dbt-ownership change; the
       settled decision to keep dbt as a test/validation layer stands.)

  R-D  PER-STRATEGY ROUTINE EXISTS. Every non-null strategies[].per_strategy_routine in roster.yaml must be
       a routine id present in ops/cadence.yaml, so a strategy that declares its own scheduled routine can
       never reference a routine the cadence single-source doesn't know about. FAIL naming code + routine.

  R-E  RAILS LITERAL AGREEMENT (added rev 2026-07-10b, code-review finding #9). bigquery/35_strategy_arsenal.sql's
       state.arsenal_rails view hardcodes the anti-churn rails (n_min, n_max, k_incubate, k_regime,
       adoption_rate_window_days, and the three cooldown_days) as SQL constants that DUPLICATE
       strategy/roster.yaml's `rails:` block. That view's own comment claims these are "cross-checked by
       scripts/check_roster_consistency.py, exactly as the cadence deadline literal is ... checked by
       check_cadence_consistency.py" — this check makes that claim true instead of aspirational. FAIL
       naming which rail disagrees and its two values.

  R-F  SPEC-LOCK HASH AGREEMENT (added rev 2026-07-11, Item 28 self-improvement audit; hardened
       2026-07-11 adversarial self-audit). Each strategy's LOCKED machinery — its strategy/0N_strategy_
       <code>.md slice plus its corresponding math module(s) (strategy_math/strategy_<code>.py +
       strategy_math/common.py for A/B/D/E — common.py is shared math EVERY one of those imports, so a
       change there is spec drift too, not invisible just because no single strategy's own file changed;
       c_options_math.py alone for C, which is self-contained) — freezes at SHADOW entry (Experiment_
       Parameters.md immutability doctrine). strategy/roster.yaml's per-strategy `spec_hash` field is a
       sha256 over exactly those files' bytes (.md then each module in SPEC_HASH_INPUTS order,
       concatenated); this check recomputes it and FAILs if a SPEC_HASH_INPUTS-covered spec-locked
       strategy (spec_locked_since is set) either has no spec_hash recorded, or its recorded spec_hash no
       longer matches the current files — meaning locked machinery drifted post-lock via a silent edit
       instead of a terminate-and-restart-as-new. A spec-locked strategy code NOT YET in SPEC_HASH_INPUTS
       (e.g. a strategy SISA synthesizes autonomously, since its SL2 authoring routine does not today
       generate a strategy_math module) prints a visible, NON-blocking NOTE instead of failing — hard-
       failing there would make R-F a de facto CI gate on autonomous strategy promotion, which CLAUDE.md's
       settled decision forbids (update SPEC_HASH_INPUTS by hand once that strategy has a math module).

Usage:  python scripts/check_roster_consistency.py        # exit 0 if consistent, 1 + diff if not
"""
import glob
import hashlib
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROSTER = os.path.join(ROOT, "strategy", "roster.yaml")
STRATEGY_MD = os.path.join(ROOT, "Strategy.md")
STRATEGY_DIR = os.path.join(ROOT, "strategy")
PLAN = os.path.join(ROOT, "Claude_Task_Plan.md")
CADENCE = os.path.join(ROOT, "ops", "cadence.yaml")
ARSENAL_SQL = os.path.join(ROOT, "bigquery", "35_strategy_arsenal.sql")

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


def spec_hash_inputs():
    """R-F: strategy code -> (spec .md slice, [corresponding math module(s)]) whose bytes are hashed
    into roster.yaml's spec_hash. A FUNCTION (not a frozen module-level dict) so it re-reads STRATEGY_DIR
    / STRATEGY_MATH_DIR / C_OPTIONS_MATH on every call — those three are monkeypatchable module globals
    (tests/test_roster_consistency.py's repo_copy fixture points them at a tmp_path copy), exactly like
    every other path this file's checks read; a frozen dict built once at import time from the real ROOT
    would silently ignore that monkeypatching and defeat fixture-based drift tests (BUG FIX, rev
    2026-07-11 adversarial self-audit).

    C predates strategy_math/ (its math already lived in c_options_math.py at repo root, self-contained,
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
    return {
        "A": (os.path.join(STRATEGY_DIR, "03_strategy_a.md"),
              [os.path.join(STRATEGY_MATH_DIR, "strategy_a.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")]),
        "B": (os.path.join(STRATEGY_DIR, "04_strategy_b.md"),
              [os.path.join(STRATEGY_MATH_DIR, "strategy_b.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")]),
        "C": (os.path.join(STRATEGY_DIR, "05_strategy_c.md"),
              [C_OPTIONS_MATH]),
        "D": (os.path.join(STRATEGY_DIR, "06_strategy_d.md"),
              [os.path.join(STRATEGY_MATH_DIR, "strategy_d.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")]),
        "E": (os.path.join(STRATEGY_DIR, "07_strategy_e.md"),
              [os.path.join(STRATEGY_MATH_DIR, "strategy_e.py"), os.path.join(STRATEGY_MATH_DIR, "common.py")]),
    }

LIFECYCLE_STATES = ("CANDIDATE", "QUALIFYING", "AUTHORING", "UNDER_REVIEW", "SHADOW", "PAPER",
                    "PROBE", "ADOPTED", "RETIREMENT_PROPOSED", "TERMINATED", "POST_MORTEM", "REJECTED")
ACTIVE_STATES_YAML = {"probe", "adopted"}      # roster.yaml roster_state values meaning is_active
ACTIVE_STATES_SQL = {"PROBE", "ADOPTED"}       # seed to_state values meaning is_active

# '## Strategy <CODE> ...' heading (Strategy.md + each generated slice). '[CANDIDATE]' = not roster-active.
STRATEGY_HEADING = re.compile(r"^##\s+Strategy\s+([A-Z]{1,3})\b([^\n]*)$", re.M)
# A bare UNNEST roster literal, e.g. ['A','B',...] or ['AB','CD',...] (codes are 1-3 letters, matching
# STRATEGY_HEADING / SEED_ROW) — the thing R-B forbids.
BARE_LITERAL = re.compile(r"\[\s*'[A-Z]{1,3}'\s*,\s*'[A-Z]{1,3}'")
# A fixed equal-split divisor `/ N` for ANY integer N (R-B / R-C forbid a fixed divisor, and the roster
# size is not always 5 — SISA resizes N autonomously — so match any /<int>, not just /5).
FIXED_DIVISOR = re.compile(r"/\s*\d+\b")
# A per-strategy slice filename referenced in the plan slice-map, e.g. `06_strategy_d.md`.
SLICE_FILE_REF = re.compile(r"\d+_strategy_([a-z]{1,3})\.md")
# A rail constant in bigquery/35's `consts AS (SELECT 2 AS n_min, ...)` CTE, e.g. "8  AS n_max,".
RAIL_NAMES = ("n_min", "n_max", "k_incubate", "k_regime", "adoption_rate_window_days",
              "reject_cooldown_days", "terminate_cooldown_days", "keep_cooldown_days")
RAIL_CONST = re.compile(r"(\d+)\s+AS\s+(" + "|".join(RAIL_NAMES) + r")\b")
# roster.yaml rails: key -> the arsenal_rails SQL constant name it must equal.
ROSTER_RAIL_KEY_TO_SQL_NAME = {
    "n_min": "n_min", "n_max": "n_max", "k_incubate": "k_incubate", "k_regime": "k_regime",
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
    return yaml.safe_load(open(ROSTER, encoding="utf-8")) or {}


def roster_active_codes(doc):
    return {s["code"] for s in doc.get("strategies", [])
            if str(s.get("roster_state", "")).lower() in ACTIVE_STATES_YAML}


def slice_codes():
    out = set()
    for p in sorted(glob.glob(os.path.join(STRATEGY_DIR, "*_strategy_*.md"))):
        out |= headings_in(open(p, encoding="utf-8").read())
    return out


def slicemap_codes():
    txt = open(PLAN, encoding="utf-8").read()
    m = re.search(r"^##\s+Strategy reading\b.*?(?=^##\s)", txt, re.M | re.S)
    section = m.group(0) if m else ""
    return {c.upper() for c in SLICE_FILE_REF.findall(section)}


def compute_spec_hash(code, inputs=None):
    """sha256 over (.md slice bytes || each module's bytes, in spec_hash_inputs() list order) for a
    spec_hash_inputs()-mapped code (R-F). `inputs` lets a caller pass an already-computed
    spec_hash_inputs() dict to avoid recomputing it per-code in a loop; defaults to a fresh call."""
    md_path, module_paths = (inputs or spec_hash_inputs())[code]
    h = hashlib.sha256()
    h.update(open(md_path, "rb").read())
    for module_path in module_paths:
        h.update(open(module_path, "rb").read())
    return h.hexdigest()


def arsenal_rails_sql_consts():
    txt = open(ARSENAL_SQL, encoding="utf-8").read()
    return {name: int(val) for val, name in RAIL_CONST.findall(txt)}


def seed_active_codes():
    # BUG FIX (rev 2026-07-10b, code-review finding #2): the previous version processed ALL SEED_ROW
    # matches in one pass, then ALL UNNEST_SEED_BLOCK matches in a second pass, so an UNNEST block always
    # overrode a literal-tuple row for the same code regardless of which actually appears LATER in the
    # file. Both match kinds are now merged into a single list of (start_pos, code, state) events and
    # applied in true textual order, so "the last row/block per code wins" is what actually happens.
    txt = open(ARSENAL_SQL, encoding="utf-8").read()
    events = []
    for m in SEED_ROW.finditer(txt):
        events.append((m.start(), m.group(1), m.group(2)))
    for m in UNNEST_SEED_BLOCK.finditer(txt):
        state_m = re.search(r"'(" + "|".join(LIFECYCLE_STATES) + r")'", m.group("select"))
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
    md_codes = headings_in(open(STRATEGY_MD, encoding="utf-8").read())
    sl_codes = slice_codes()
    map_codes = slicemap_codes()
    if not md_codes:
        errors.append("R-A: found no non-candidate '## Strategy <code>' heading in Strategy.md "
                      "(STRATEGY_HEADING rotted, or Strategy.md is empty?)")
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
        txt = open(path, encoding="utf-8").read()
        for m in BARE_LITERAL.finditer(txt):
            n = txt.count("\n", 0, m.start()) + 1
            snippet = " ".join(m.group(0).split())
            errors.append(f"R-B: {rel}:{n} still has a bare ['A','B',...] roster literal — read "
                          f"`state.active_strategy_codes` instead: {snippet}")
        for m in FIXED_DIVISOR.finditer(txt):
            n = txt.count("\n", 0, m.start()) + 1
            # Context spans the match's FIRST line through its LAST line (m.end() bounds the right
            # edge, not m.start()) so "amount" is still found when it sits on the divisor's own
            # line rather than the line containing "/" — a line-wrapped divisor can put either
            # token on either side of the wrap.
            ctx_start = txt.rfind("\n", 0, m.start()) + 1
            ctx_end = txt.find("\n", m.end())
            ctx = txt[ctx_start: ctx_end if ctx_end != -1 else len(txt)]
            if "amount" in ctx:
                errors.append(f"R-B: {rel}:{n} still has a fixed `/ N` equal-split divisor — use an "
                              f"as-of-flow-date COUNT(*) FROM state.strategy_roster: {ctx.strip()}")

    # ---- R-C: count-agnostic dbt reconcile test ----
    if not os.path.exists(DBT_RECONCILE):
        errors.append("R-C: dbt/tests/assert_cash_flows_reconcile.sql is missing")
    else:
        for n, line in enumerate(open(DBT_RECONCILE, encoding="utf-8"), 1):
            # Adjacency guard (matching R-B's "amount" co-occurrence requirement): without it, ANY
            # unrelated N/M-shaped text in this file (e.g. a RUNBOOK section reference like
            # "section 5/6") trips FIXED_DIVISOR and false-fails CI (2026-07-14 audit finding). The
            # separate `"amount/5" in ...` clause was also dead code — FIXED_DIVISOR already
            # matches that exact substring, so it added no coverage.
            if FIXED_DIVISOR.search(line) and ("amount" in line or "cash_flow" in line or "deposit" in line):
                errors.append(f"R-C: dbt/tests/assert_cash_flows_reconcile.sql:{n} hardcodes the roster "
                              f"size (a `/ 5` / amount/5 assumption) — the reconciliation must be "
                              f"count-agnostic (per-strategy sum): {line.strip()}")

    # ---- R-D: per-strategy routines named in roster.yaml exist in cadence.yaml ----
    cad = yaml.safe_load(open(CADENCE, encoding="utf-8")) or {}
    cad_ids = {r["id"] for r in cad.get("routines", [])}
    for s in doc.get("strategies", []):
        rt = s.get("per_strategy_routine")
        if rt and rt not in cad_ids:
            errors.append(f"R-D: strategy {s.get('code')!r} names per_strategy_routine '{rt}' which is NOT "
                          f"a routine id in ops/cadence.yaml")

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
        # Both loops below must fire on a MISSING yaml key too, not just a mismatched one — a key
        # silently deleted from roster.yaml's rails block (accidental deletion, bad merge, a
        # partial rails: block copy-paste) previously left the corresponding SQL constant with
        # NOTHING to compare against, so R-E vacuously passed (2026-07-14 audit finding, confirmed
        # empirically: deleting rails.n_min end-to-end still printed "ROSTER CONSISTENCY: OK").
        for yaml_key, sql_name in ROSTER_RAIL_KEY_TO_SQL_NAME.items():
            if sql_name not in sql_consts:
                continue  # already reported by the len(sql_consts) < len(RAIL_NAMES) check above
            if yaml_key not in rails_doc:
                errors.append(f"R-E: roster.yaml rails.{yaml_key} is missing but "
                              f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]} exists")
            elif int(rails_doc[yaml_key]) != sql_consts[sql_name]:
                errors.append(f"R-E: roster.yaml rails.{yaml_key}={rails_doc[yaml_key]} but "
                              f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]}")
        cooldowns = rails_doc.get("cooldown_days", {}) or {}
        for yaml_key, sql_name in ROSTER_COOLDOWN_KEY_TO_SQL_NAME.items():
            if sql_name not in sql_consts:
                continue
            if yaml_key not in cooldowns:
                errors.append(f"R-E: roster.yaml rails.cooldown_days.{yaml_key} is missing but "
                              f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]} exists")
            elif int(cooldowns[yaml_key]) != sql_consts[sql_name]:
                errors.append(f"R-E: roster.yaml rails.cooldown_days.{yaml_key}={cooldowns[yaml_key]} but "
                              f"bigquery/35_strategy_arsenal.sql arsenal_rails.{sql_name}={sql_consts[sql_name]}")

    # ---- R-F: spec-locked strategies' machinery hash agrees with roster.yaml's spec_hash ----
    spec_inputs = spec_hash_inputs()
    for s in doc.get("strategies", []):
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
        missing = [p for p in [md_path, *module_paths] if not os.path.exists(p)]
        if missing:
            errors.append(f"R-F: strategy {code!r} is spec_locked_since={s.get('spec_locked_since')} but its "
                          f"spec_hash input(s) {[os.path.relpath(p, ROOT) for p in missing]} are missing")
            continue
        actual = compute_spec_hash(code, inputs=spec_inputs)
        declared = s.get("spec_hash")
        inputs_desc = " + ".join(os.path.relpath(p, ROOT) for p in [md_path, *module_paths])
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
    # `conviction_features.decision` accepted_values(['GO']) block in the same file. ----
    if os.path.exists(DBT_SCHEMA_ACCEPTED_VALUES):
        schema_doc = yaml.safe_load(open(DBT_SCHEMA_ACCEPTED_VALUES, encoding="utf-8")) or {}
        for model in schema_doc.get("models", []) or []:
            for col in model.get("columns", []) or []:
                if col.get("name") != "strategy":
                    continue
                for test in col.get("tests", []) or []:
                    if not isinstance(test, dict) or "accepted_values" not in test:
                        continue
                    codes = set((test["accepted_values"] or {}).get("values", []) or [])
                    if codes and codes != roster_codes:
                        errors.append(
                            f"R-G: dbt/models/analytics/schema.yml model {model.get('name')!r} column "
                            f"'strategy' accepted_values {sorted(codes)} no longer matches the roster-active "
                            f"set {sorted(roster_codes)} — update this list (or drop the test) alongside "
                            f"the roster change.")

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
          f"SPEC_HASH_INPUTS-covered spec-locked strategy's spec_hash agrees with its .md slice + math "
          f"module(s); dbt schema.yml accepted_values(strategy) tests agree with the roster-active set.")
    if notes:
        print("\nNOTES (non-blocking):")
        for n in notes:
            print(" - " + n)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

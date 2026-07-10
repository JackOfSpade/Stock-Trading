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

Usage:  python scripts/check_roster_consistency.py        # exit 0 if consistent, 1 + diff if not
"""
import glob
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

LIFECYCLE_STATES = ("CANDIDATE", "QUALIFYING", "AUTHORING", "UNDER_REVIEW", "SHADOW", "PAPER",
                    "PROBE", "ADOPTED", "RETIREMENT_PROPOSED", "TERMINATED", "POST_MORTEM", "REJECTED")
ACTIVE_STATES_YAML = {"probe", "adopted"}      # roster.yaml roster_state values meaning is_active
ACTIVE_STATES_SQL = {"PROBE", "ADOPTED"}       # seed to_state values meaning is_active

# '## Strategy <CODE> ...' heading (Strategy.md + each generated slice). '[CANDIDATE]' = not roster-active.
STRATEGY_HEADING = re.compile(r"^##\s+Strategy\s+([A-Z]{1,3})\b([^\n]*)$", re.M)
# A bare UNNEST roster literal, e.g. ['A','B',...] (any spacing) — the thing R-B forbids.
BARE_LITERAL = re.compile(r"\[\s*'[A-Z]'\s*,\s*'[A-Z]'")
# A fixed equal-split divisor `/ 5` (the /N literal R-B / R-C forbid).
FIXED_DIVISOR = re.compile(r"/\s*5\b")
# A per-strategy slice filename referenced in the plan slice-map, e.g. `06_strategy_d.md`.
SLICE_FILE_REF = re.compile(r"\d+_strategy_([a-z]{1,3})\.md")
# A seed VALUES row associating a code with a lifecycle to_state (last row per code wins = latest state).
# Two seed SHAPES are recognized (SL5 will use the VALUES shape for one-at-a-time PROBE finalizations;
# the founding batch used the UNNEST shape to seed all five at once with one shared to_state):
#   (1) literal tuple:  (..., 'A', ..., 'ADOPTED', ...)                      -- SEED_ROW
#   (2) batch UNNEST:   SELECT ..., 'ADOPTED', ... FROM UNNEST(['A',...]) AS code  -- UNNEST_SEED_BLOCK
SEED_ROW = re.compile(r"'([A-Z]{1,3})'[^)\n]*?'(" + "|".join(LIFECYCLE_STATES) + r")'")
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


def seed_active_codes():
    txt = open(ARSENAL_SQL, encoding="utf-8").read()
    latest = {}
    for code, state in SEED_ROW.findall(txt):
        latest[code] = state          # append-only seed: later row wins
    for m in UNNEST_SEED_BLOCK.finditer(txt):
        state_m = re.search(r"'(" + "|".join(LIFECYCLE_STATES) + r")'", m.group("select"))
        if not state_m:
            continue
        state = state_m.group(1)
        for code in re.findall(r"'([A-Z]{1,3})'", m.group("codes")):
            latest[code] = state      # append-only seed: later block wins (by textual order)
    return {c for c, s in latest.items() if s in ACTIVE_STATES_SQL}, len(latest)


def main():
    if not os.path.exists(ROSTER):
        print("ROSTER CONSISTENCY: SKIP — strategy/roster.yaml absent (pre-2026-07-10 checkout, before the "
              "Strategy Arsenal loop landed). Nothing to check.")
        return 0

    errors = []
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
    for path in DERIVED_LIVE_SQL:
        rel = os.path.relpath(path, ROOT)
        if not os.path.exists(path):
            errors.append(f"R-B: expected roster-derived file {rel} is missing")
            continue
        for n, line in enumerate(open(path, encoding="utf-8"), 1):
            if BARE_LITERAL.search(line):
                errors.append(f"R-B: {rel}:{n} still has a bare ['A','B',...] roster literal — read "
                              f"`state.active_strategy_codes` instead: {line.strip()}")
            if FIXED_DIVISOR.search(line) and "amount" in line:
                errors.append(f"R-B: {rel}:{n} still has a fixed `/ 5` equal-split divisor — use an "
                              f"as-of-flow-date COUNT(*) FROM state.strategy_roster: {line.strip()}")

    # ---- R-C: count-agnostic dbt reconcile test ----
    if not os.path.exists(DBT_RECONCILE):
        errors.append("R-C: dbt/tests/assert_cash_flows_reconcile.sql is missing")
    else:
        for n, line in enumerate(open(DBT_RECONCILE, encoding="utf-8"), 1):
            if FIXED_DIVISOR.search(line) or "amount/5" in line.replace(" ", ""):
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

    # ---- report ----
    if errors:
        print("ROSTER CONSISTENCY: FAIL\n")
        for e in errors:
            print(" - " + e)
        print("\nFix strategy/roster.yaml and its mirrors (the state.strategy_roster seed in "
              "bigquery/35_strategy_arsenal.sql, Strategy.md '## Strategy' sections, strategy/ slices, the "
              "Claude_Task_Plan.md slice-map) + the roster-derived SQL so they agree, then re-run. This is "
              "the roster analog of scripts/check_cadence_consistency.py (see ops/RUNBOOK.md §39).")
        return 1

    print(f"ROSTER CONSISTENCY: OK — {len(roster_codes)} roster-active strategies ({sorted(roster_codes)}) "
          f"agree across roster.yaml, the bigquery/35 seed, Strategy.md, the strategy/ slices, and the plan "
          f"slice-map; no bare roster literal or fixed /5 divisor in the live derived SQL; the dbt reconcile "
          f"test is count-agnostic.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

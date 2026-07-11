#!/usr/bin/env python3
"""Golden-scenario prose regression runner (ITEM 20, 2026-07-11).

WHY THIS EXISTS. This system's real source code is prose (Strategy.md, Operating_Protocols.md,
Claude_Task_Plan.md routine bodies) read fresh by an LLM every routine run. Every existing CI check
(scripts/check_cadence_consistency.py, check_roster_consistency.py, check_autonomy_consistency.py,
split_strategy.py --check) is a STRUCTURAL fact scraper — none of them evaluate what a routine would
DECIDE when it reads the prose. tests/golden_scenarios/scenarios.yaml pins 20 concrete decision
scenarios (regime-router edge cases, kill-trigger/gate mechanics, Strategy B entry criteria) with an
expected GO/NO-GO | CONTINUE/TERMINATE | ACTIVATE/DO-NOT-ACTIVATE call and the specific rule that
produces it. This script is the runner.

TWO MODES, matching the two-job split in .github/workflows/golden-scenarios.yml:

  --offline (default; NO NETWORK; the CI HARD GATE)
      Pure schema validation: every scenario has the required fields, ids are unique, every
      governing_file exists on disk, and expected_decision starts with a recognized token. This is
      deterministic and must stay green on every push — it is what keeps the golden set itself from
      silently rotting (a scenario with a typo'd expected_decision or a renamed governing_file would
      otherwise vacuously "pass" any real check forever).

  --live (NETWORK; calls a model; ADVISORY ONLY — see the workflow header for why this never hard-
      blocks a merge)
      For each scenario, reads the CURRENT text of its governing_files, sends the pinned
      EVAL_PROMPT_TEMPLATE below to a Claude model, parses a DECISION: line from the reply, and diffs
      it against expected_decision's leading token. Prints a pass/fail table and, for the first
      leading-token mismatch on a NON-EMPTY governing_files reread, prints a GitHub Actions
      `::warning::` annotation plus the exact (never-executed) events.queue_events INSERT a routine
      COULD run to file it as review_type='prose-regression' for later mechanical follow-up — this
      script does not execute that INSERT (no BigQuery write credentials in CI, and per the operating
      model a human review/PR gate is never the compensating control for a self-improvement loop; see
      CLAUDE.md "Settled decisions"). Requires ANTHROPIC_API_KEY. Always exits 0 (advisory) unless the
      offline schema gate itself fails first, or setup fails outright (missing API key/library), which
      is reported but still does not fail the *build* — the workflow's continue-on-error covers that.

Usage:
  python tests/golden_scenarios/run_golden.py --offline
  python tests/golden_scenarios/run_golden.py --live [--model MODEL_ID] [--scenario ID ...]
"""
import argparse
import os
import sys

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCENARIOS_PATH = os.path.join(ROOT, "tests", "golden_scenarios", "scenarios.yaml")

REQUIRED_FIELDS = ("id", "situation", "governing_files", "expected_decision", "rationale")

# Vocabulary the offline schema check accepts as a valid expected_decision LEADING token (free text may
# follow in parentheses, e.g. "CONTINUE (routes to review, not direct terminate)" — see scenarios.yaml's
# schema comment). Keeps a typo'd/empty expected_decision from silently validating, without constraining
# the free-text qualifier that follows it.
DECISION_LEAD_TOKENS = ("GO", "NO-GO", "CONTINUE", "TERMINATE", "ACTIVATE", "DO-NOT-ACTIVATE")

# Default live-mode model. Pin/verify before relying on this — model ids retire on Anthropic's normal
# cadence (see this repo's Quarterly_AI_Foundation_Delta.md for the current lineup); override with
# --model or the ANTHROPIC_MODEL env var rather than editing this default in place, so a stale default
# here is a one-line CLI override away, not a code change.
DEFAULT_MODEL = os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-5")

# Pinned eval prompt (ITEM 20 requirement: "Pin the eval prompt in-repo"). Deliberately mirrors how a
# routine session is actually run: given the CURRENT governing prose verbatim (no memorized/cached
# knowledge of a prior revision) plus one self-contained scenario, decide mechanically and literally.
EVAL_PROMPT_TEMPLATE = """You are evaluating ONE pinned regression scenario against this trading \
system's CURRENT governing prose. Read the governing-file excerpts below exactly as given below — do \
not rely on any outside/remembered knowledge of a prior revision of these files. Apply the rules \
mechanically and literally, exactly as an autonomous routine session executing Claude_Task_Plan.md \
would, with no added judgment beyond what the cited rule requires.

=== GOVERNING FILES (verbatim, current repo state) ===
{governing_files_text}

=== SCENARIO ===
{situation}

Respond with EXACTLY two lines and nothing else:
DECISION: <one of GO | NO-GO | CONTINUE | TERMINATE | ACTIVATE | DO-NOT-ACTIVATE>
RATIONALE: <one sentence citing the specific rule/section/threshold you applied>
"""

QUEUE_INSERT_TEMPLATE = """-- SPEC ONLY — never executed by this script (no BigQuery write credentials in CI; a routine with
-- write access may choose to file this for real). review_type='prose-regression' per ITEM 20.
INSERT INTO `stock-trading-498512.events.queue_events`
  (queue, item_key, item_type, status, note, payload)
VALUES (
  'PENDING_REVIEW',
  '{scenario_id}',
  'prose-regression',
  'pending',
  'golden-scenario decision flip: {scenario_id} expected {expected!r} got {actual!r}',
  JSON '{{"review_type": "prose-regression", "scenario_id": "{scenario_id}", "expected": {expected!r}, "actual": {actual!r}, "governing_files": {governing_files!r}}}'
);"""


def load_scenarios(path=SCENARIOS_PATH):
    with open(path) as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict) or "scenarios" not in data:
        raise ValueError("scenarios.yaml must be a mapping with a top-level 'scenarios' list")
    scenarios = data["scenarios"]
    if not isinstance(scenarios, list) or not scenarios:
        raise ValueError("scenarios.yaml 'scenarios' must be a non-empty list")
    return scenarios


def validate_offline(scenarios):
    """Pure schema + file-existence validation. No network, no model call. Returns a list of error
    strings (empty list = pass). This is the function the CI hard gate depends on."""
    errors = []
    seen_ids = set()
    for i, sc in enumerate(scenarios):
        label = sc.get("id", f"<index {i}>") if isinstance(sc, dict) else f"<index {i}>"
        if not isinstance(sc, dict):
            errors.append(f"{label}: scenario entry is not a mapping")
            continue

        for field in REQUIRED_FIELDS:
            val = sc.get(field)
            if val is None or (isinstance(val, str) and not val.strip()):
                errors.append(f"{label}: missing or empty required field '{field}'")

        sid = sc.get("id")
        if sid:
            if sid in seen_ids:
                errors.append(f"{label}: duplicate scenario id '{sid}'")
            seen_ids.add(sid)

        gov = sc.get("governing_files")
        if isinstance(gov, list):
            if not gov:
                errors.append(f"{label}: governing_files must be a non-empty list")
            for gf in gov:
                if not isinstance(gf, str):
                    errors.append(f"{label}: governing_files entry {gf!r} is not a string")
                    continue
                full = os.path.join(ROOT, gf)
                if not os.path.isfile(full):
                    errors.append(f"{label}: governing_file '{gf}' does not exist at {full}")
        elif gov is not None:
            errors.append(f"{label}: governing_files must be a list, got {type(gov).__name__}")

        decision = sc.get("expected_decision")
        if isinstance(decision, str) and decision.strip():
            lead = decision.strip().upper()
            if not any(lead.startswith(tok) for tok in DECISION_LEAD_TOKENS):
                errors.append(
                    f"{label}: expected_decision '{decision}' does not start with a recognized token "
                    f"{DECISION_LEAD_TOKENS} — likely a typo, or the vocabulary needs a deliberate addition"
                )
    return errors


def _leading_token(decision_text):
    """Extract the leading DECISION_LEAD_TOKENS token from a free-text decision string, for grading."""
    if not decision_text:
        return None
    lead = decision_text.strip().upper()
    # Longest-first so 'DO-NOT-ACTIVATE' isn't misread as a partial 'NO-GO'/'ACTIVATE' match.
    for tok in sorted(DECISION_LEAD_TOKENS, key=len, reverse=True):
        if lead.startswith(tok):
            return tok
    return None


def run_live(scenarios, model, scenario_ids=None):
    """Call a Claude model per scenario and diff its decision vs. the pinned expected_decision.
    Advisory only — never returns a failing process exit code by itself; the caller decides."""
    try:
        import anthropic
    except ImportError:
        print(
            "::warning::anthropic package not installed — live golden-scenario run skipped "
            "(pip install anthropic). Offline schema validation is unaffected.",
            file=sys.stderr,
        )
        return []

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print(
            "::notice::ANTHROPIC_API_KEY not set — live golden-scenario run skipped (opt-in). "
            "Offline schema validation is unaffected.",
            file=sys.stderr,
        )
        return []

    client = anthropic.Anthropic(api_key=api_key)
    results = []
    file_cache = {}

    for sc in scenarios:
        sid = sc.get("id")
        if scenario_ids and sid not in scenario_ids:
            continue

        gov_text_parts = []
        for gf in sc.get("governing_files", []):
            if gf not in file_cache:
                with open(os.path.join(ROOT, gf), encoding="utf-8") as fh:
                    file_cache[gf] = fh.read()
            gov_text_parts.append(f"----- {gf} -----\n{file_cache[gf]}")
        prompt = EVAL_PROMPT_TEMPLATE.format(
            governing_files_text="\n\n".join(gov_text_parts),
            situation=sc.get("situation", "").strip(),
        )

        try:
            resp = client.messages.create(
                model=model,
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}],
            )
            reply = "".join(
                block.text for block in resp.content if getattr(block, "type", None) == "text"
            )
        except Exception as exc:  # noqa: BLE001 — advisory path, any failure is reported, not raised
            print(f"::warning::{sid}: model call failed — {exc}", file=sys.stderr)
            results.append({"id": sid, "expected": sc.get("expected_decision"), "actual": None,
                             "match": None, "reply": str(exc)})
            continue

        actual_line = next((ln for ln in reply.splitlines() if ln.strip().upper().startswith("DECISION:")), "")
        actual_decision = actual_line.split(":", 1)[1].strip() if ":" in actual_line else reply.strip()
        expected_tok = _leading_token(sc.get("expected_decision"))
        actual_tok = _leading_token(actual_decision)
        match = expected_tok is not None and expected_tok == actual_tok

        results.append({
            "id": sid, "expected": sc.get("expected_decision"), "actual": actual_decision,
            "match": match, "reply": reply,
        })

        if not match:
            print(
                f"::warning file=tests/golden_scenarios/scenarios.yaml::{sid} decision flip — "
                f"expected '{sc.get('expected_decision')}' got '{actual_decision}'. "
                f"Governing files: {sc.get('governing_files')}."
            )
            print(QUEUE_INSERT_TEMPLATE.format(
                scenario_id=sid,
                expected=sc.get("expected_decision"),
                actual=actual_decision,
                governing_files=sc.get("governing_files"),
            ))

    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--offline", action="store_true", help="offline schema validation only (no network); default")
    mode.add_argument("--live", action="store_true", help="call a model and diff decisions (network; advisory)")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"model id for --live (default {DEFAULT_MODEL})")
    parser.add_argument("--scenario", action="append", dest="scenario_ids", default=None,
                         help="restrict --live to this scenario id (repeatable)")
    args = parser.parse_args()

    try:
        scenarios = load_scenarios()
    except (OSError, ValueError) as exc:
        print(f"FATAL: could not load {SCENARIOS_PATH}: {exc}", file=sys.stderr)
        return 1

    # The offline schema gate ALWAYS runs first, in both modes — a broken fixture file must never be
    # masked by a live run that happens to still produce plausible-looking output.
    errors = validate_offline(scenarios)
    if errors:
        print(f"FAIL — {len(errors)} golden-scenario schema error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"OK — {len(scenarios)} golden scenarios pass offline schema validation "
          f"(unique ids, required fields present, every governing_file exists, "
          f"expected_decision vocabulary recognized).")

    if not args.live:
        return 0

    print(f"\nLive mode — model={args.model}, {len(scenarios)} scenario(s) "
          f"(filter: {args.scenario_ids or 'all'})")
    results = run_live(scenarios, args.model, scenario_ids=args.scenario_ids)
    if not results:
        print("Live run produced no results (skipped — see notice/warning above). Advisory: exit 0.")
        return 0

    n_match = sum(1 for r in results if r["match"] is True)
    n_flip = sum(1 for r in results if r["match"] is False)
    n_err = sum(1 for r in results if r["match"] is None)
    print(f"\nLive results: {n_match} match, {n_flip} flip(s), {n_err} error(s) out of {len(results)}.")
    for r in results:
        status = "MATCH" if r["match"] else ("ERROR" if r["match"] is None else "FLIP")
        print(f"  [{status}] {r['id']}: expected={r['expected']!r} actual={r['actual']!r}")

    # Advisory only — see module docstring. A flip or an error is reported (already emitted as
    # ::warning:: above) but never fails the process; the workflow's continue-on-error is the other
    # half of that contract for when this runs in CI.
    return 0


if __name__ == "__main__":
    sys.exit(main())

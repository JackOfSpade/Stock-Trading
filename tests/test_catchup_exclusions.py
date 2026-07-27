"""Guard OPS2 (Catch-up Executor) catch-up-safety invariants (OPS2 adversarial review 2026-07-27).

OPS2 (Claude_Task_Plan.md '## OPS2. Catch-up Executor') inline-EXECUTES any routine flagged
catchup_safe in ops/cadence.yaml and present in state.catchup_refire_readiness
(bigquery/59_catchup_autofire.sql / bigquery/90_catchup_inprogress_guard.sql). That is a strictly
higher-consequence action than OPS0's older "fire the trigger and let a human confirm" recovery: OPS2
runs the routine's OWN steps end to end with no human in the loop for that specific catch-up. The
order-crafting/capital-adjacent routines (D2, D2a, W4, M4, Q4, A3, SL4) are deliberately EXCLUDED from
catchup_safe for exactly this reason (see bigquery/59's and bigquery/90's own comments), so an
accidental catchup_safe: true flip on any of them — or a stray reappearance in one of the hand-kept
UNNEST allowlists those two files carry — would make that routine auto-refireable (OPS0) and
auto-executable (OPS2) with no adversarial-review gate. These two tests pin both surfaces so a future
edit to ops/cadence.yaml or the SQL cannot silently reopen that gap.

No warehouse, no creds — pure offline parser tests (run in the always-on `test` job).
"""
import pathlib
import re

import yaml

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CADENCE_YAML = REPO_ROOT / "ops" / "cadence.yaml"
CATCHUP_AUTOFIRE_SQL = REPO_ROOT / "bigquery" / "59_catchup_autofire.sql"
CATCHUP_INPROGRESS_GUARD_SQL = REPO_ROOT / "bigquery" / "90_catchup_inprogress_guard.sql"
TASK_PLAN = REPO_ROOT / "Claude_Task_Plan.md"
D3_SLICE = REPO_ROOT / "task_plan" / "D3.md"

# The order-crafting / capital-adjacent routines that must NEVER be catchup_safe (bigquery/59's and
# bigquery/90's own header comments: D2/D2a "daily", W4/M4/Q4/A3 "action-conversion", SL4 "discretionary-
# retirement proposal capital-adjacent enough to warrant the existing human-visible alert only").
ORDER_CRAFT_ROUTINE_IDS = ("D2", "D2a", "W4", "M4", "Q4", "A3", "SL4")

_LINE_COMMENT = re.compile(r"--[^\n]*")
_UNNEST_BRACKET = re.compile(r"UNNEST\(\[(.*?)\]\)", re.S)
_QUOTED_ID = re.compile(r"'([A-Za-z0-9_]+)'")


def _all_unnest_ids(path):
    """Union of every quoted id inside ANY `UNNEST([...])` bracket in `path`, `--` line comments
    stripped first so a comment merely NAMING an excluded id (e.g. "-- SL4 excluded") can never be
    mistaken for a live allowlist entry. Deliberately scans every bracket in the file (via
    re.finditer), not just the first — bigquery/90_catchup_inprogress_guard.sql carries TWO
    catchup-safe UNNEST lists (daily, then period; see its module docstring), and a first-match-only
    scan would silently miss the second."""
    txt = _LINE_COMMENT.sub("", path.read_text(encoding="utf-8"))
    ids = set()
    for m in _UNNEST_BRACKET.finditer(txt):
        ids.update(_QUOTED_ID.findall(m.group(1)))
    return ids


def _section(heading_prefix, text):
    """Body of the FIRST '## <heading_prefix...' Claude_Task_Plan.md section, from its heading line
    up to (not including) the NEXT '## ' heading — same heading-to-heading scoping convention
    scripts/check_cadence_consistency.py's parse_inventory_table uses for its own section carve-out."""
    lines = text.splitlines()
    start = None
    for i, ln in enumerate(lines):
        if ln.startswith(f"## {heading_prefix}"):
            start = i
            break
    assert start is not None, f"no '## {heading_prefix}' heading found in Claude_Task_Plan.md"
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    return "\n".join(lines[start:end])


def test_order_crafting_routines_stay_catchup_excluded():
    """OPS2 adversarial review 2026-07-27.

    D2/D2a/W4/M4/Q4/A3/SL4 craft orders or move capital and must never become catch-up-eligible:
    OPS0 auto-REFIRES a catchup_safe miss's trigger, and OPS2 goes further and auto-EXECUTES it
    inline, with no human gate either way. Pins two independent surfaces:

    1. ops/cadence.yaml's declared `catchup_safe` boolean for each of these 7 ids is False (the
       source of truth scripts/check_cadence_consistency.py's check K reads).
    2. None of the 7 ids appear inside the hand-kept catchup_safe UNNEST([...]) allowlists in
       bigquery/59_catchup_autofire.sql or bigquery/90_catchup_inprogress_guard.sql (the latter
       reproduces bigquery/59's — and bigquery/31's — lists inertly for query purposes, per its own
       module docstring, but a stray edit there would still feed a live BigQuery view OPS2 reads).

    A flip on either surface is high-consequence and easy to miss in review (one boolean; one id in
    a long comma list) — this test exists so CI catches it instead of a live incident.
    """
    doc = yaml.safe_load(CADENCE_YAML.read_text(encoding="utf-8")) or {}
    routines = {r["id"]: r for r in doc.get("routines", [])}

    for rid in ORDER_CRAFT_ROUTINE_IDS:
        assert rid in routines, f"{rid}: not declared in ops/cadence.yaml at all"
        assert routines[rid].get("catchup_safe") is False, (
            f"{rid}: ops/cadence.yaml catchup_safe must be False (order-crafting/capital-adjacent "
            f"routine) — got {routines[rid].get('catchup_safe')!r}. A flip to True would make {rid} "
            f"auto-refireable by OPS0 and auto-executable inline by OPS2 with no human gate."
        )

    for path in (CATCHUP_AUTOFIRE_SQL, CATCHUP_INPROGRESS_GUARD_SQL):
        ids = _all_unnest_ids(path)
        leaked = [rid for rid in ORDER_CRAFT_ROUTINE_IDS if rid in ids]
        assert not leaked, (
            f"{path.name}: order-crafting routine(s) {leaked} appear inside a hand-kept "
            f"catchup_safe UNNEST([...]) allowlist — this would make them catch-up-eligible"
        )


def test_ops2_retains_order_craft_slice_scan():
    """OPS2 adversarial review 2026-07-27.

    OPS2 inline-executes another routine's ENTIRE slice at full fidelity, but is granted IBKR
    READ-ONLY tools only — it must never inline-run a routine that crafts orders. STEP 2's
    "ORDER-CRAFT SLICE-SCAN" is the runtime guard: it greps the target routine's own slice for
    `create_order_instruction` / `delete_order_instruction` and DEFERS if found, rather than trusting
    the (hand-maintained, comment-driven) exclusion lists in bigquery/59/90 alone. D3 is the concrete
    case this guard exists for — D3 IS catchup_safe (daily miss recovery is safe and valuable) yet
    ALSO crafts orders (its persist-and-wait DAY re-craft), so it is the one routine that would
    otherwise slip past the SCOPE GUARDRAIL (item 1, which only excludes D2/D2a/W4/M4/Q4/A3/SL4) and
    get inline-executed by a read-only session.

    Asserts both halves of the guard are still present in Claude_Task_Plan.md's OPS2 section (the
    marker AND the create_order_instruction reference it greps for), plus the premise check: D3's own
    generated slice (task_plan/D3.md) really does still contain create_order_instruction. If this
    premise ever stops being true (D3 stops crafting orders), the guard's purpose for D3 specifically
    has changed and this test should be revisited rather than just updated to keep passing.
    """
    text = TASK_PLAN.read_text(encoding="utf-8")
    ops2_section = _section("OPS2.", text)
    assert "ORDER-CRAFT SLICE-SCAN" in ops2_section, (
        "OPS2's Claude_Task_Plan.md section no longer contains the ORDER-CRAFT SLICE-SCAN marker — "
        "the runtime guard that stops read-only OPS2 from inline-running an order-crafting routine "
        "like D3 may have been removed or renamed."
    )
    assert "create_order_instruction" in ops2_section, (
        "OPS2's Claude_Task_Plan.md section no longer references create_order_instruction — the "
        "ORDER-CRAFT SLICE-SCAN greps the target routine's slice for this exact string; without it "
        "the scan cannot detect an order-crafting routine at all."
    )

    # Premise check: D3 really is an order-crafter OPS2 must defer.
    assert D3_SLICE.exists(), f"{D3_SLICE} does not exist — run scripts/split_task_plan.py"
    d3_text = D3_SLICE.read_text(encoding="utf-8")
    assert "create_order_instruction" in d3_text, (
        "task_plan/D3.md no longer contains create_order_instruction — the premise that D3 is an "
        "order-crafting routine OPS2 must defer (rather than inline-execute) has changed; revisit "
        "this test and OPS2's ORDER-CRAFT SLICE-SCAN documentation together."
    )

"""Guard OPS2 (Catch-up Executor) catch-up-safety invariants (OPS2 adversarial review 2026-07-27).

OPS2 (Claude_Task_Plan.md '## OPS2. Catch-up Executor') inline-EXECUTES any routine flagged
catchup_safe in ops/cadence.yaml and present in state.catchup_refire_readiness
(bigquery/59_catchup_autofire.sql / bigquery/90_catchup_inprogress_guard.sql). That is a strictly
higher-consequence action than OPS0's older "fire the trigger and let a human confirm" recovery: OPS2
runs the routine's OWN steps end to end with no human in the loop for that specific catch-up. The
order-crafting/capital-adjacent routines (D2, D2a, M4, Q4, A3, SL4) are deliberately EXCLUDED from
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

from lib.routine_manifest import cadence_routines

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CADENCE_YAML = REPO_ROOT / "ops" / "cadence.yaml"
CATCHUP_AUTOFIRE_SQL = REPO_ROOT / "bigquery" / "59_catchup_autofire.sql"
CATCHUP_INPROGRESS_GUARD_SQL = REPO_ROOT / "bigquery" / "90_catchup_inprogress_guard.sql"
TASK_PLAN = REPO_ROOT / "Claude_Task_Plan.md"
D3_SLICE = REPO_ROOT / "task_plan" / "D3.md"
D1_SLICE = REPO_ROOT / "task_plan" / "D1.md"

_ORDER_CRAFT_STRINGS = ("create_order_instruction", "delete_order_instruction")

# The order-crafting / capital-adjacent routines that must NEVER be catchup_safe (bigquery/59's and
# bigquery/90's own header comments: D2/D2a "daily", M4/Q4/A3 "action-conversion", SL4 "discretionary-
# retirement proposal capital-adjacent enough to warrant the existing human-visible alert only"). W4 was
# intentionally removed in the daily/weekly ownership redesign: it now writes idempotent queue handoffs
# only, so a late catch-up reproduces its same-day result safely.
ORDER_CRAFT_ROUTINE_IDS = ("D2", "D2a", "M4", "Q4", "A3", "SL4")

_LINE_COMMENT = re.compile(r"--[^\n]*")
_UNNEST_BRACKET = re.compile(r"UNNEST\(\[(.*?)\]\)", re.S)
_QUOTED_ID = re.compile(r"'([A-Za-z0-9_]+)'")

# --- SCOPE GUARDRAIL prose pinning (see test_scope_guardrail_prose_matches_exclusion_set) ---
# Anchor on the guardrail's own name rather than on the routine ids, so the scan cannot be satisfied
# by the very list it is meant to verify. Case-insensitive and hyphen-or-space tolerant: the four
# restatements spell it "scope-guardrail exclusion set", "SCOPE GUARDRAIL applies verbatim",
# "SCOPE GUARDRAIL (restated", and "SCOPE GUARDRAIL - defense-in-depth".
_SCOPE_GUARDRAIL_ANCHOR = re.compile(r"scope[- ]guardrail", re.I)
# A routine id as the plan writes them: D1, D2a, W4, M1a, Q4, A3, SL4, OPS0. Deliberately generic
# (letters + digits + optional lowercase suffix) so a DROPPED id shortens the run rather than making
# the pattern silently fail to match -- a regex spelling out the seven expected ids would go vacuous
# in exactly the direction this test exists to catch.
_ROUTINE_ID = r"[A-Z]{1,3}\d+[a-z]?"
# Three-or-more comma-separated ids, tolerating "A3, or SL4" as well as "A3, SL4" and the set-builder
# form "{D2, ..., SL4}". Applied ONLY to anchor lines: Claude_Task_Plan.md carries 22 other id runs,
# including the near-miss "D2, D3, W4, M4, Q4, A1, A3" (the action-conversion tier, a genuinely
# DIFFERENT set) -- an unanchored scan would false-positive on it and on every "D1, D2, D3" in prose.
_ID_RUN = re.compile(rf"{_ROUTINE_ID}(?:,\s*(?:or\s+)?{_ROUTINE_ID}){{2,}}")
_ID_IN_RUN = re.compile(_ROUTINE_ID)
# Claude_Task_Plan.md restates the exclusion set in four places (shared REFIREABLE preamble; D3's
# OPS0 WATCHDOG-FALLBACK; OPS0's own SCOPE GUARDRAIL; OPS2's defense-in-depth item 1). A fifth anchor
# line exists (OPS2's read-access-scope paragraph) that REFERENCES the guardrail without restating
# the ids -- it correctly yields no run and is not counted.
EXPECTED_GUARDRAIL_RESTATEMENTS = 4


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


def _own_body(slice_path):
    """A generated task_plan/<ID>.md slice's OWN body — from its routine's `## <ID>.` heading (always
    the LAST `## ` heading in the file, since scripts/split_task_plan.py prepends the shared preamble/
    FILE-CONVENTIONS boilerplate before every routine's own section and a slice holds exactly one
    routine) to end of file. This is the OPS2 ORDER-CRAFT SLICE-SCAN fix's own isolation: the shared
    preamble mentions create_order_instruction/delete_order_instruction repeatedly (IBKR connector
    usage prose), so scanning the WHOLE slice file is a false positive for every routine, order-crafting
    or not — see Claude_Task_Plan.md's OPS2 STEP 2 item 2 for the incident this fixed."""
    lines = slice_path.read_text(encoding="utf-8").splitlines()
    heading_idxs = [i for i, ln in enumerate(lines) if ln.startswith("## ")]
    assert heading_idxs, f"{slice_path}: no '## ' heading found at all"
    return "\n".join(lines[heading_idxs[-1]:])


def test_order_crafting_routines_stay_catchup_excluded():
    """OPS2 adversarial review 2026-07-27.

    D2/D2a/M4/Q4/A3/SL4 craft orders or move capital and must never become catch-up-eligible:
    OPS0 auto-REFIRES a catchup_safe miss's trigger, and OPS2 goes further and auto-EXECUTES it
    inline, with no human gate either way. Pins two independent surfaces:

    1. ops/cadence.yaml's declared `catchup_safe` boolean for each of these 6 ids is False (the
       source of truth scripts/check_cadence_consistency.py's check K reads).
    2. None of the 6 ids appear inside the hand-kept catchup_safe UNNEST([...]) allowlists in
       bigquery/59_catchup_autofire.sql or bigquery/90_catchup_inprogress_guard.sql (the latter
       reproduces bigquery/59's — and bigquery/31's — lists inertly for query purposes, per its own
       module docstring, but a stray edit there would still feed a live BigQuery view OPS2 reads).

    A flip on either surface is high-consequence and easy to miss in review (one boolean; one id in
    a long comma list) — this test exists so CI catches it instead of a live incident.
    """
    doc = yaml.safe_load(CADENCE_YAML.read_text(encoding="utf-8")) or {}
    # cadence_routines() guards a bare `routines:` key (PyYAML -> None), which doc.get("routines", [])
    # does NOT catch (the default only fires when the KEY is absent) -- an unguarded reader raises
    # TypeError: 'NoneType' object is not iterable on that YAML shape instead of a clean assertion
    # failure. Migrated to match the other four readers (2026-07-29 miss).
    routines = {r["id"]: r for r in cadence_routines(doc)}

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


def test_queue_only_w4_stays_catchup_safe():
    """W4 no longer crafts/stages orders, so its idempotent handoff is safe to recover.

    This is the complement to the capital-adjacent exclusion above.  W4's queue-only
    redesign deliberately made it recoverable by OPS0/OPS2; a stale copy of the old
    never-refire list would otherwise turn a harmless missed research handoff into a
    week-long manual alert.  Pin both the manifest declaration and the two live SQL
    readiness allowlists.
    """
    doc = yaml.safe_load(CADENCE_YAML.read_text(encoding="utf-8")) or {}
    routines = {r["id"]: r for r in cadence_routines(doc)}
    assert routines["W4"].get("catchup_safe") is True
    for path in (CATCHUP_AUTOFIRE_SQL, CATCHUP_INPROGRESS_GUARD_SQL):
        assert "W4" in _all_unnest_ids(path), (
            f"{path.name}: queue-only W4 is missing from the catchup-safe allowlist; "
            "keep the manifest and both readiness surfaces aligned."
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
    otherwise slip past the SCOPE GUARDRAIL (item 1, which only excludes D2/D2a/M4/Q4/A3/SL4) and
    get inline-executed by a read-only session.

    Asserts both halves of the guard are still present in Claude_Task_Plan.md's OPS2 section (the
    marker AND the create_order_instruction reference it greps for), that the spec text actually
    scopes the scan to the target routine's OWN section rather than its whole generated slice (2026-07-27
    adversarial review — a whole-file grep is a false positive for EVERY catchup_safe routine, since
    the shared preamble every slice is prefixed with also mentions both strings repeatedly, which would
    make OPS2 defer everything and never inline-execute anything), and the DISCRIMINATING premise
    check: D3's OWN section (isolated from its slice, not the whole file) contains
    create_order_instruction/delete_order_instruction, while a non-order-crafting catchup_safe
    routine's (D1's) OWN section does NOT — proving the scan actually has power to tell the two apart
    once correctly scoped. If either premise ever stops being true (D3 stops crafting orders, or D1
    starts), the guard's purpose has changed and this test should be revisited rather than just updated
    to keep passing.
    """
    text = TASK_PLAN.read_text(encoding="utf-8")
    ops2_section = _section("OPS2.", text)
    assert "ORDER-CRAFT SLICE-SCAN" in ops2_section, (
        "OPS2's Claude_Task_Plan.md section no longer contains the ORDER-CRAFT SLICE-SCAN marker — "
        "the runtime guard that stops OPS2 from inline-running an order-crafting routine like D3 may "
        "have been removed or renamed."
    )
    assert "create_order_instruction" in ops2_section, (
        "OPS2's Claude_Task_Plan.md section no longer references create_order_instruction — the "
        "ORDER-CRAFT SLICE-SCAN greps the target routine's slice for this exact string; without it "
        "the scan cannot detect an order-crafting routine at all."
    )
    assert "OWN section" in ops2_section and "never the whole file" in ops2_section, (
        "OPS2's ORDER-CRAFT SLICE-SCAN no longer scopes the grep to the target routine's OWN section — "
        "scanning the whole generated slice hits the shared preamble's own "
        "create_order_instruction/delete_order_instruction mentions (IBKR connector usage prose) and "
        "would false-positive on EVERY catchup_safe routine, defeating OPS2 entirely (2026-07-27 "
        "adversarial review finding)."
    )

    # Premise check, made DISCRIMINATING (2026-07-27 review): scanning D3's OWN section (not its whole
    # slice, which is contaminated by the shared preamble's own order-craft mentions) finds the strings,
    # while D1's OWN section — a genuinely research-only, order-crafting-free catchup_safe routine —
    # does not. A test that only checked "the string appears somewhere in D3.md" would pass even if the
    # scan were scoped wrong (it would ALSO appear somewhere in D1.md, via the preamble), which is
    # exactly the bug this isolation exists to catch.
    assert D3_SLICE.exists(), f"{D3_SLICE} does not exist — run scripts/split_task_plan.py"
    assert D1_SLICE.exists(), f"{D1_SLICE} does not exist — run scripts/split_task_plan.py"
    d3_body = _own_body(D3_SLICE)
    d1_body = _own_body(D1_SLICE)
    assert any(s in d3_body for s in _ORDER_CRAFT_STRINGS), (
        "task_plan/D3.md's OWN section (isolated from the shared preamble) no longer contains "
        "create_order_instruction/delete_order_instruction — the premise that D3 is an order-crafting "
        "routine OPS2 must defer (rather than inline-execute) has changed; revisit this test and "
        "OPS2's ORDER-CRAFT SLICE-SCAN documentation together."
    )
    leaked = [s for s in _ORDER_CRAFT_STRINGS if s in d1_body]
    assert not leaked, (
        f"task_plan/D1.md's OWN section unexpectedly contains {leaked} — D1 is a research-only "
        "catchup_safe routine with no order-craft step; if this is now genuine, D1 must move into "
        "OPS2's SCOPE GUARDRAIL exclusion set, not just this test's expectation. (If instead this "
        "assertion is merely picking up preamble contamination again, _own_body()'s isolation itself "
        "has regressed — the exact false-positive-for-everything bug the 2026-07-27 review found.)"
    )


def test_scope_guardrail_prose_matches_exclusion_set():
    """Pin Claude_Task_Plan.md's four SCOPE GUARDRAIL restatements to ORDER_CRAFT_ROUTINE_IDS
    (interactive triage 2026-08-05).

    The two tests above pin the MACHINE surfaces — ops/cadence.yaml's `catchup_safe` booleans and the
    hand-kept UNNEST allowlists in bigquery/59 and bigquery/90 — so `state.catchup_refire_readiness`
    cannot start emitting an order-crafting routine. What was NOT pinned is the PROSE, and the prose is
    itself a live runtime surface here: OPS0, OPS2, D3 and the dependency-wait ACTIVE REPAIR path are
    Claude sessions that read these sentences as their operating instructions. Claude_Task_Plan.md:1686
    calls its copy "defense-in-depth" precisely because it is meant to hold when the view is wrong —
    a layer that has silently rotted is worse than no layer, because the other layers are documented
    as relying on it.

    The realistic failure is a one-token edit: dropping `M4,` while rewording a neighbouring clause, or
    adding a routine to one restatement and not the other three. Nothing in CI would notice today — the
    tuple above and cadence.yaml would still agree with each other, and split_task_plan.py --check would
    happily propagate the drifted sentence into every generated task_plan/*.md slice.

    Scoping notes (both are deliberate, and both are the difference between a real test and a vacuous
    one):

    * ANCHOR ON THE GUARDRAIL'S NAME, NOT ON THE IDS. Matching the literal string
      "D2, D2a, M4, Q4, A3, SL4" would make the test pass whenever the prose drifted — the pattern
      would simply stop matching, and an occurrence-count assertion is the only thing standing between
      that and a silent pass. Anchoring on /scope[- ]guardrail/i and extracting whatever id run follows
      inverts that: drift changes the extracted SET, which is compared, rather than the match count.
    * ANCHOR, DON'T SCAN THE WHOLE FILE. Claude_Task_Plan.md contains 22 other comma-separated routine
      runs, including "D2, D3, W4, M4, Q4, A1, A3" (the action-conversion tier — five ids overlap, two
      differ). An unanchored scan would fail on that legitimate, unrelated list.

    Only Claude_Task_Plan.md is read: the task_plan/*.md slices are generated from it and are already
    pinned to it by scripts/split_task_plan.py --check in both ci.yml and auto-merge-claude.yml, so
    checking the source covers the slices without making this test depend on generated artifacts.
    """
    expected = set(ORDER_CRAFT_ROUTINE_IDS)
    found = []  # (line_no, [ids])
    for lineno, line in enumerate(TASK_PLAN.read_text(encoding="utf-8").splitlines(), 1):
        if not _SCOPE_GUARDRAIL_ANCHOR.search(line):
            continue
        for run in _ID_RUN.findall(line):
            found.append((lineno, _ID_IN_RUN.findall(run)))

    assert len(found) == EXPECTED_GUARDRAIL_RESTATEMENTS, (
        f"expected {EXPECTED_GUARDRAIL_RESTATEMENTS} SCOPE GUARDRAIL exclusion-set restatements in "
        f"Claude_Task_Plan.md, found {len(found)} at line(s) {[n for n, _ in found]}. A DROP means a "
        "guardrail restatement was deleted or reworded past recognition — OPS0/OPS2/D3 read these "
        "sentences as their operating instructions, so restore it. An ADDITION is fine if deliberate: "
        "bump EXPECTED_GUARDRAIL_RESTATEMENTS. Do not 'fix' this by loosening the anchor."
    )

    for lineno, ids in found:
        assert set(ids) == expected, (
            f"Claude_Task_Plan.md:{lineno}: SCOPE GUARDRAIL exclusion set has drifted from "
            f"ORDER_CRAFT_ROUTINE_IDS.\n"
            f"  prose says: {ids}\n"
            f"  expected:   {sorted(expected)}\n"
            f"  missing from prose: {sorted(expected - set(ids)) or 'none'}\n"
            f"  extra in prose:     {sorted(set(ids) - expected) or 'none'}\n"
            "A routine MISSING from the prose is the dangerous direction: OPS0's re-fire step and "
            "OPS2's inline-execute step are prose-driven, so an omitted id can be auto-refired or "
            "auto-executed with no human gate the moment the readiness view also regresses. If the "
            "exclusion set genuinely changed, update ops/cadence.yaml, bigquery/59, bigquery/90, "
            "ORDER_CRAFT_ROUTINE_IDS and ALL "
            f"{EXPECTED_GUARDRAIL_RESTATEMENTS} restatements together."
        )

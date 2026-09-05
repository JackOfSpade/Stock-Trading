#!/usr/bin/env python3
"""Guard ops/autonomy_levels.yaml stage citations against prose/SQL drift (self-improvement audit,
built ahead of the first stage promotion, 2026-07-04).

WHY THIS EXISTS. ops/cadence.yaml has scripts/check_cadence_consistency.py to catch drift between the
YAML source of truth and the hand-kept SQL/prose that cites it. ops/autonomy_levels.yaml — the register
of each self-improvement loop's current autonomy `stage` (dormant / shadow / record_only /
active_pr_gated / active_auto) — has NO equivalent guard. Prose (Claude_Task_Plan.md) and SQL headers
(bigquery/27_process_reliability.sql) both cite a loop's stage inline, e.g.:

    "... DORMANT per `ops/autonomy_levels.yaml`, loop `process_reliability` ..."      (Claude_Task_Plan.md)
    "-- STATUS: DORMANT per ops/autonomy_levels.yaml (loop id `process_reliability`)" (bigquery/27_*.sql)

Nothing today would catch a citation going stale after a loop is promoted (or a copy-pasted-then-
forgotten citation). Every loop is `dormant` as of 2026-07-04 — nothing has drifted yet — but the ask is
to build this BEFORE the first promotion, not after the first silent drift, reusing
check_cadence_consistency.py's proven regex-scrape-and-diff pattern (kept as a separate small script,
matching that file's own multi-check CLI convention, since this guards an unrelated YAML register).

HOW: ops/autonomy_levels.yaml is the source of truth ({loop id: stage}). KNOWN_CITATION_FILES are the
files grepped (2026-07-04) to currently contain a stage citation — each MUST yield >=1 citation, so a
regex that rots (a reformat that silently stops matching) fails loud instead of vacuously passing (the
exact class of bug tests/test_cadence_consistency.py guards check_cadence_consistency.py's own parsers
against). EXTRA_SCAN_GLOBS is scanned too, best-effort, so a NEW citation added elsewhere later is still
validated even though it isn't required. Every citation found (required or extra) must have its stage
match ops/autonomy_levels.yaml's current value for that loop id (case-insensitive), and must name a loop
id that still exists in the register.

Usage:  python scripts/check_autonomy_consistency.py     # exit 0 if consistent, 1 + diff if not
"""
import glob
import os
import re
import sys

try:
    # This module's own reads now go through lib.textio.load_yaml()/read_text() (2026-07-29 textio
    # adoption), so `yaml` is not referenced directly below, but the import stays for (1) this fail-fast
    # ImportError guard and (2) tests/test_autonomy_consistency.py's direct ac.yaml.safe_load() access
    # when reading the real ops/autonomy_levels.yaml for a real-repo sanity assertion.
    import yaml  # noqa: F401
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from None

from lib.report import fail_or_ok
from lib.sql_files import OBJECT_DDL, normalize_kind, numbered_sql_files, resolve_canonical, strip_sql_comments
from lib.textio import read_text, load_yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTONOMY = os.path.join(ROOT, "ops", "autonomy_levels.yaml")
# ARCH-1 wrapper migration (2026-07-16): bigquery/scheduled_queries/cadence_check.sql is now a frozen
# one-line CALL wrapper (bigquery/scheduled_queries/README.md) — the actual
# constant_tuning_loop_heartbeat_missing check body (the 'loop:<id>' UNNEST literals this script scans
# for) lives in the ops.sp_sq_cadence_check procedure defined in bigquery/75_scheduled_query_wrappers.sql.
#
# APPLY-IN-ORDER CORRECTION (roster-group bug, 2026-09-04): the sentence above was written when
# bigquery/75 was the ONLY definition, and it is no longer where the deployed body lives — 15 files now
# carry a `CREATE OR REPLACE PROCEDURE ops.sp_sq_cadence_check` (75, 111, 120, 128, 132, 142, 147, 149,
# 150, 153, 157, 159, 172, 186, 205), and bigquery/*.sql is apply-in-order, so the HIGHEST-numbered
# definition is the live one. Hard-pinning bigquery/75 meant this dead-man's-switch coverage gate was
# validating a body 14 supersessions stale: a future supersession that dropped a loop from the detection
# literal would pass clean (fail-OPEN), and — more likely near-term — a NEWLY promoted active_auto loop
# whose heartbeat literal lands in a new superseding file (the standing rule from bigquery/111's header)
# would be reported missing and block every merge (false FAIL). CADENCE_SQL stays as the module-level
# path constant tests monkeypatch and as the fallback anchor (it also names the directory to scan);
# canonical_cadence_sql() below resolves the actual winner at CALL time, exactly as
# check_sq_version_registry.py's resolve_winners() does for the same procedure family. The repo already
# treats this stale-pin class as a defect: Claude_Task_Plan.md carries a 2026-08-20 D3 correction for a
# bullet that named bigquery/75 as an edit target "which has been wrong since bigquery/111 superseded it".
CADENCE_SQL = os.path.join(ROOT, "bigquery", "75_scheduled_query_wrappers.sql")
CADENCE_PROC = "sp_sq_cadence_check"

# Loops intentionally NOT in cadence_check.sql's constant_tuning_loop_heartbeat_missing UNNEST list —
# each for its own declared reason, not a silent gap:
#   strategy_arsenal   — carries its OWN heartbeat + dead-man's switch elsewhere (SL1/SL3/SL4
#                         heartbeats + cadence dead-man views in bigquery/12,18,24).
#   capital_allocator  — added 2026-07-19 (AI_DECISION_REDESIGN.md §3 Redesign A). Carries NO heartbeat
#                         of its own, dedicated or otherwise: it is not a scheduled/cadence routine but
#                         an inline step inside D2's STRATEGY TERMINATIONS handler, AR_orc's m2m-
#                         termination handler, and D2's §13.C deposit-recording flow. The two D2-hosted
#                         paths carry D2's own run_log/cadence dead-man coverage (daily_trading class);
#                         the AR_orc path is queue_driven (deliberately OUTSIDE the calendar nets) and is
#                         covered only CONDITIONALLY by D3's queue_item_stale scan — i.e. detection there
#                         requires a review item actually sitting stale in the queue (2026-07-19 review
#                         F4: do not read this carve-out as claiming uniform coverage). The
#                         event this loop fires on (a strategy termination or a deposit) is legitimately
#                         rare/irregular (terminations: zero so far), so a standalone 10-day-quiet cadence
#                         alarm modeled on a daily/weekly loop would be constant false-positive noise, not
#                         a real gap — see this loop's ops/autonomy_levels.yaml gate_to_next_stage note.
# This is the ONE declared place for this carve-out — add here (not silently) if a future active_auto
# loop self-monitors or has no independent cadence to alarm on.
# - research_screener (2026-07-19, Redesign C): fires only inline within D1/W2/M2's own runs, each of
#   which already carries run_log/cadence dead-man coverage — a standalone quiet-loop alarm would only
#   re-alarm what the D1/W2/M2 cadence checks already catch (same posture as capital_allocator above).
HEARTBEAT_SELF_MONITORED_LOOPS = {"strategy_arsenal", "capital_allocator", "research_screener"}

# The register's own PROMOTION RULE vocabulary/ordering — a loop's stage may never exceed its ceiling.
STAGE_ORDER = ["dormant", "shadow", "record_only", "active_pr_gated", "active_auto"]

# Files grepped (2026-07-04) to currently contain a "<STAGE> per ops/autonomy_levels.yaml" citation.
# Each of these MUST produce >=1 citation match — an empty result here means the regex rotted (a
# reformat of the citation text), not that the citation was legitimately removed (see main()).
KNOWN_CITATION_FILES = [
    os.path.join(ROOT, "Claude_Task_Plan.md"),
    os.path.join(ROOT, "bigquery", "27_process_reliability.sql"),
]

# Best-effort extra scan for citations that might appear elsewhere in the future — validated the same
# way, but a zero-match file here is not itself an error (unlike KNOWN_CITATION_FILES above).
EXTRA_SCAN_GLOBS = [
    os.path.join(ROOT, "*.md"),
    os.path.join(ROOT, "ops", "*.md"),
    os.path.join(ROOT, "bigquery", "*.md"),   # e.g. bigquery/README.md — carried a stage citation that
                                              #   went unscanned (a live-stale DORMANT for a now-active_auto
                                              #   loop) until this glob was added (2026-07-17 audit).
    os.path.join(ROOT, "bigquery", "*.sql"),
    os.path.join(ROOT, "bigquery", "scheduled_queries", "*.sql"),
]

# Matches both citation styles already in the repo:
#   "DORMANT per `ops/autonomy_levels.yaml`, loop `process_reliability`"           (Claude_Task_Plan.md)
#   "STATUS: DORMANT per ops/autonomy_levels.yaml (loop id `process_reliability`)" (bigquery/27_*.sql)
# Tolerant of optional backticks around the filename and either "loop `id`" or "loop id `id`" phrasing,
# so a small punctuation reformat doesn't rot the regex, but a genuine restructure (see
# tests/test_autonomy_consistency.py) still correctly yields no match.
# The id class includes digits ([a-z0-9_]+): load_stages() accepts loop ids verbatim, and this
# repo's routine/loop namespace uses digits heavily (D1, SL1-SL5, W5...), so a digit-bearing loop id
# is plausible. A restrictive [a-z_]+ here would silently fail to match a citation to such a loop —
# a vacuous pass (stale citation never flagged) — and the twin parser in cadence_heartbeat_loops()
# would false-positive a coverage gap for it (2026-07-17 audit).
CITATION_RE = re.compile(
    r"(?P<stage>[A-Za-z][A-Za-z_]*)\s+per\s+`?ops/autonomy_levels\.yaml`?"
    r"[^\n]{0,40}?loop(?:\s+id)?\s+`(?P<id>[a-z0-9_]+)`"
)

# A THIRD citation style, in the reverse word order — loop id first, stage second:
#   "-- WHY (W5 2026-08-03, self-improvement loop `process_reliability`, active_auto per
#    ops/autonomy_levels.yaml):"                                            (bigquery/129_*.sql)
# CITATION_RE above can never match this: its `...yaml`[^\n]{0,40}?loop` tail requires the loop id to
# come AFTER the filename. Added 2026-09-04 after measuring the gap — 9 citations in the scanned corpus
# are written as "<stage> per ops/autonomy_levels.yaml" (across 6 files) and CITATION_RE validated only
# 8 of them, leaving bigquery/129's
# citation entirely unchecked inside a glob (`bigquery/*.sql`) that exists precisely so "a NEW citation
# added elsewhere later is still validated". That citation happens to be CORRECT today, so this closes a
# coverage hole rather than fixing a wrong answer — the same class as the 2026-07-17 `bigquery/*.md`
# glob addition, which was made for a citation that had gone live-stale while unscanned.
# TWO deliberate narrowings, both load-bearing:
#   - the STAGE half is restricted to the STAGE_ORDER vocabulary, not [A-Za-z_]+ as in CITATION_RE.
#     Reading right-to-left, an unrestricted stage word would capture any ordinary sentence noun
#     preceding "per ops/autonomy_levels.yaml" (e.g. "... loop `x` is documented per
#     ops/autonomy_levels.yaml") and report a false DRIFT. CITATION_RE can afford the loose class
#     because its stage is anchored by what FOLLOWS; this one is not.
#   - re.IGNORECASE on the stage alternation only. Every FORWARD citation in the repo spells the stage
#     in UPPERCASE ("DORMANT per ..."); bigquery/129 happens to use lowercase. Matching only lowercase
#     here would close exactly today's instance and leave "loop `x`, ACTIVE_AUTO per ..." invisible —
#     a half-closed hole, which is worse than a visible one. _check_citations() already lowercases the
#     cited stage before comparing, so nothing downstream changes.
CITATION_RE_REVERSED = re.compile(
    r"loop(?:\s+id)?\s+`(?P<id>[a-z0-9_]+)`"
    r"[^\n]{0,60}?(?P<stage>(?i:" + "|".join(STAGE_ORDER) + r"))\s+per\s+`?ops/autonomy_levels\.yaml`?"
)


def load_stages():
    """{loop id: current stage} from ops/autonomy_levels.yaml."""
    doc = load_yaml(AUTONOMY)
    return {loop["id"]: loop.get("stage") for loop in (doc.get("loops") or []) if "id" in loop}


def find_citations(path):
    """[(cited_stage, loop_id), ...] in one file, in document order. [] if the file doesn't exist or has
    no citations.

    Unions BOTH word orders — CITATION_RE (stage first) and CITATION_RE_REVERSED (loop id first) — rather
    than loosening CITATION_RE itself, so its forward-order rationale above stays intact and each pattern
    keeps the anchoring that makes its own stage capture safe. De-duplicated by (start offset, stage, id)
    so a citation both patterns happen to match at the same position is counted once."""
    if not os.path.exists(path):
        return []
    txt = read_text(path)
    seen = set()
    for pattern in (CITATION_RE, CITATION_RE_REVERSED):
        for m in pattern.finditer(txt):
            seen.add((m.start(), m.group("stage"), m.group("id")))
    return [(stage, loop_id) for _pos, stage, loop_id in sorted(seen)]


def _check_citations(path, stages, errors):
    rel = os.path.relpath(path, ROOT)
    found = find_citations(path)
    for cited_stage, loop_id in found:
        if loop_id not in stages:
            errors.append(f"{rel}: cites unknown loop id '{loop_id}' (not in ops/autonomy_levels.yaml "
                          f"— renamed/removed loop with a stale citation?)")
            continue
        actual = stages[loop_id]
        if actual is None:
            errors.append(f"{rel}: loop '{loop_id}' has no 'stage' set in ops/autonomy_levels.yaml")
        elif cited_stage.lower() != actual.lower():
            errors.append(f"{rel}: cites stage '{cited_stage}' for loop '{loop_id}' but "
                          f"ops/autonomy_levels.yaml says stage='{actual}' — DRIFT (fix the stale "
                          f"citation, or if the loop was genuinely promoted, this citation is exactly "
                          f"what should have been updated in the same commit)")
    return found


def active_auto_loops():
    """Set of loop ids whose stage == 'active_auto' in ops/autonomy_levels.yaml."""
    return {lid for lid, st in load_stages().items() if (st or "").lower() == "active_auto"}


def canonical_cadence_sql():
    """(path, errors) — the bigquery/*.sql file whose `ops.sp_sq_cadence_check` body is the one actually
    DEPLOYED, resolved apply-in-order (highest leading NN wins) rather than hard-pinned to CADENCE_SQL.
    See CADENCE_SQL's own comment for the stale-pin bug this closes; the resolution itself mirrors
    check_sq_version_registry.py's resolve_winners(), which solves the identical problem for the same
    procedure family, and reuses lib/sql_files.py's shared OBJECT_DDL/numbered_sql_files() parsers so
    there is one spelling of "find an object's definitions in apply order", not a third hand-rolled copy.

    Resolved at CALL time, never at import: tests/test_autonomy_consistency.py monkeypatches CADENCE_SQL
    to a tmp file, and an import-time resolution would silently ignore that. Those tmp files carry no
    `NN_` prefix, so numbered_sql_files() finds nothing in the tmp directory and the FALLBACK below
    returns the monkeypatched path unchanged — which is also the right answer for a checkout where
    bigquery/ is absent entirely.

    Returns (None, [error]) — not a silently-chosen path — when two DIFFERENT files share the winning
    leading number and both define this procedure. resolve_canonical()'s contract is explicit that a
    caller must never index [0] on the tied set (duplicate NN prefixes exist in this repo today: 114 x2,
    185 x2), because picking one at random would validate the WRONG body with no signal at all. A None
    path makes cadence_heartbeat_loops() report "nothing to compare" while the error itself fails the
    gate — fail-closed, not fail-silent."""
    bigquery_dir = os.path.dirname(CADENCE_SQL)
    if not os.path.isdir(bigquery_dir):
        return CADENCE_SQL, []
    occurrences = []
    for number, path in numbered_sql_files(bigquery_dir):
        if os.path.isdir(path):
            continue
        raw = read_text(path)
        if CADENCE_PROC not in raw:      # cheap pre-filter; the OBJECT_DDL scan below is authoritative
            continue
        # strip_sql_comments() first: a `-- CREATE OR REPLACE PROCEDURE ops.sp_sq_cadence_check` line
        # inside a doc comment is not a definition (the exact class lib/sql_files.py's helper exists for
        # — confirmed live at bigquery/02_ai_layer.sql:23 for a sibling checker).
        for m in OBJECT_DDL.finditer(strip_sql_comments(raw)):
            if (normalize_kind(m.group(1)), m.group(2), m.group(3)) == ("PROCEDURE", "ops", CADENCE_PROC):
                occurrences.append((number, path))
                break
    if not occurrences:
        # No definition found anywhere (a pre-bigquery/75 checkout, a tmp fixture dir, or a DDL-shape
        # change): fall back to the pinned path, whose own existence check downstream still applies.
        return CADENCE_SQL, []
    winner_number, winner_paths = resolve_canonical(occurrences)
    if len(winner_paths) > 1:
        return None, [
            f"ops.{CADENCE_PROC}: AMBIGUOUS canonical definition — bigquery/{winner_number} is the "
            f"winning (highest) leading number, but {len(winner_paths)} DIFFERENT files share it and "
            f"each defines `CREATE OR REPLACE PROCEDURE ops.{CADENCE_PROC}`: "
            f"{', '.join('bigquery/' + os.path.basename(p) for p in winner_paths)}. This gate cannot "
            f"silently choose between them (it would validate the wrong body's dead-man's-switch list) "
            f"— renumber one file, or delete the definition that is not actually deployed."]
    return winner_paths[0], []


def cadence_heartbeat_loops():
    """Loop ids monitored by cadence_check.sql's constant_tuning_loop_heartbeat_missing switch
    (its 'loop:<id>' UNNEST literals). None if the file is missing. This is the UNION across every
    'loop:<id>' literal in the file — used for the rot / file-missing signals; the actual coverage
    requirement uses cadence_detection_loops() (the DETECTION-list-only view, see below).

    KNOWN LIMIT (worth recording, unchanged by the 2026-09-04 canonical-resolution fix): this scans the
    WHOLE canonical file, not just the sp_sq_cadence_check procedure body. That was harmless while the
    pin was bigquery/75 and stays harmless today (bigquery/205 is a multi-object file yet still yields
    exactly the same 2 loop-bearing UNNEST blocks and the same 7-loop set as all 14 earlier definitions,
    measured), but a future canonical file carrying an UNRELATED `'loop:<id>'` UNNEST literal would join
    cadence_detection_loops()'s intersection and could narrow it into a false FAIL."""
    path, _errors = canonical_cadence_sql()
    if path is None or not os.path.exists(path):
        return None
    # strip_sql_comments() before the literal scan, same reasoning as canonical_cadence_sql() above: a
    # commented-out `'loop:<id>'` literal is not a live dead-man's switch. Not hypothetical — bigquery/
    # 71_research_quality_promotion.sql already carries one inside a `--` comment today (it is not a
    # cadence_check definition file, so it never reaches here, but the idiom is established).
    txt = strip_sql_comments(read_text(path))
    # [a-z0-9_]+ (not [a-z_]+): match a digit-bearing loop id too — see CITATION_RE's comment.
    return set(re.findall(r"'loop:([a-z0-9_]+)'", txt))


def cadence_detection_loops():
    """Loop ids that appear in EVERY 'loop:<id>' UNNEST literal in the cadence SQL — i.e. their
    intersection. None if the file is missing.

    The canonical ops.sp_sq_cadence_check body (bigquery/75 when this was written; resolved
    apply-in-order since 2026-09-04 — see canonical_cadence_sql()) carries the loop list TWICE:
    the IF EXISTS DETECTION literal
    that actually fires the constant_tuning_loop_heartbeat_missing alarm, and a STRING_AGG MESSAGE
    literal that only builds the alert text. A loop present in the message list but MISSING from the
    detection list has NO working dead-man's switch, yet cadence_heartbeat_loops()'s whole-file UNION
    would still count it as monitored — a latent fail-OPEN in a safety guard (2026-07-17 audit). Since
    the detection list is a subset of (or equal to) the message list, requiring membership in the
    intersection of all loop-bearing UNNEST literals enforces detection-list membership without
    hardcoding which literal is which. Returns set() if no loop-bearing UNNEST literal is found (the
    caller already handles the rot/empty case via cadence_heartbeat_loops())."""
    path, _errors = canonical_cadence_sql()
    if path is None or not os.path.exists(path):
        return None
    # Comments stripped for the same reason as in cadence_heartbeat_loops() — and it matters MORE here:
    # a commented-out UNNEST block bearing loop literals would add a whole extra set to the intersection
    # below and could narrow it, i.e. false-FAIL this gate off a documentation aside.
    txt = strip_sql_comments(read_text(path))
    blocks = re.findall(r"UNNEST\(\s*\[([^\]]*'loop:[^\]]*)\]\s*\)", txt)
    loop_sets = [set(re.findall(r"'loop:([a-z0-9_]+)'", b)) for b in blocks]
    loop_sets = [s for s in loop_sets if s]
    return set.intersection(*loop_sets) if loop_sets else set()


def _check_cadence_heartbeat_coverage(errors):
    """Every active_auto loop (except the self-monitoring ones) MUST appear in cadence_check.sql's
    dead-man's-switch list — an active_auto loop with no heartbeat alarm is the exact gap
    meta_monitoring_heartbeat (ops/autonomy_levels.yaml) forbids. Only the fail-OPEN direction (a
    promoted loop missing from the SQL) is an error; a stale literal for a demoted loop is fail-safe.

    The file NAMED in both error strings below is the apply-in-order-resolved canonical definition, not
    the hardcoded bigquery/75 the messages used to spell (2026-09-04) — pointing an operator at a
    superseded file is how a fix lands in a body that is never applied. Nothing in the repo or the tests
    asserts on the old literal filename (checked before changing it)."""
    cadence_path, resolve_errors = canonical_cadence_sql()
    errors.extend(resolve_errors)
    monitored = cadence_heartbeat_loops()
    if monitored is None:
        # The canonical cadence-check SQL is not present in this checkout (or its definition is
        # AMBIGUOUS, already reported above); nothing to compare.
        return
    rel = os.path.relpath(cadence_path, ROOT)
    expected = active_auto_loops() - HEARTBEAT_SELF_MONITORED_LOOPS
    if expected and not monitored:
        errors.append(f"{rel} (ops.{CADENCE_PROC}): found no "
                      "'loop:<id>' heartbeat literals — the constant_tuning_loop_heartbeat_missing UNNEST "
                      "list was reformatted (regex rotted) or removed; fix the regex here or restore the list")
        return
    # Require each expected loop in the DETECTION literal (intersection of all loop: UNNEST lists), not
    # merely the whole-file union: a loop present only in the message-text literal has no working alarm.
    missing = expected - cadence_detection_loops()
    if missing:
        errors.append(
            f"{rel} (ops.{CADENCE_PROC}): "
            f"constant_tuning_loop_heartbeat_missing does NOT monitor active_auto loop(s) {sorted(missing)} "
            "— an active_auto loop with no dead-man's switch is the gap meta_monitoring_heartbeat "
            "forbids; add 'loop:<id>' to BOTH UNNEST literals in that procedure body (in a NEW "
            "higher-numbered bigquery/*.sql supersession, per bigquery/111's header rule), or if it "
            "self-monitors (like strategy_arsenal) add it to HEARTBEAT_SELF_MONITORED_LOOPS in "
            "scripts/check_autonomy_consistency.py")


def duplicate_loop_ids(loops):
    """[id, ...] (sorted, deduped) for any loop id appearing more than once in ops/autonomy_levels.yaml's
    'loops' list. load_stages()'s dict comprehension above silently keeps only the LAST such entry
    (valid YAML -- a duplicate `id:` across list items, not a duplicate mapping key) when, say, a
    copy-pasted-then-half-edited block leaves two entries sharing the same id (this file's own
    docstring already worries about a copy-pasted-then-forgotten citation, line 14 -- a copy-pasted
    loop block is the same failure mode one level up). Every other structural hazard in this register
    (unknown stage/ceiling vocabulary, stage>ceiling, stale citations) has a dedicated fail-loud check;
    a duplicated id had none, so active_auto_loops()/_check_citations()/_check_cadence_heartbeat_
    coverage() would all silently validate against whichever duplicate happened to be listed last."""
    ids = [loop["id"] for loop in loops if "id" in loop]
    return sorted({i for i in ids if ids.count(i) > 1})


def check_stage_ceiling_invariant(loops):
    """Error strings for any loop (a list of {id, stage, ceiling, ...} dicts, e.g. ops/autonomy_levels.yaml's
    top-level 'loops' list) with an unknown stage/ceiling vocabulary word, or whose stage exceeds its
    ceiling — the register's own PROMOTION RULE forbids a stage above its ceiling."""
    errors = []
    for loop in loops:
        lid, st, ceil_ = loop.get("id"), loop.get("stage"), loop.get("ceiling")
        if st is None and ceil_ is not None:
            # `stage` is the register's core field (its whole purpose is to record each loop's CURRENT
            # stage); a loop that declares a ceiling but has no stage is a dropped/indented-out `stage:`
            # line, which otherwise passes silently — active_auto_loops() then omits it and its heartbeat
            # coverage is never demanded (2026-07-17 audit). Gate on stage-absent specifically, not
            # ceiling-absent: a stage-present/ceiling-absent loop is a valid not-yet-capped entry.
            errors.append(f"ops/autonomy_levels.yaml: loop '{lid}' declares a ceiling '{ceil_}' but has no "
                          f"'stage' — the register's core field is missing (a dropped/indented-out "
                          f"'stage:' line?)")
        if st is not None and st not in STAGE_ORDER:
            errors.append(f"ops/autonomy_levels.yaml: loop '{lid}' has unknown stage '{st}' "
                          f"(not one of {STAGE_ORDER})")
        if ceil_ is not None and ceil_ not in STAGE_ORDER:
            errors.append(f"ops/autonomy_levels.yaml: loop '{lid}' has unknown ceiling '{ceil_}' "
                          f"(not one of {STAGE_ORDER})")
        if (st in STAGE_ORDER and ceil_ in STAGE_ORDER
                and STAGE_ORDER.index(st) > STAGE_ORDER.index(ceil_)):
            errors.append(f"ops/autonomy_levels.yaml: loop '{lid}' stage '{st}' EXCEEDS its ceiling "
                          f"'{ceil_}' — the register's PROMOTION RULE forbids a stage above its ceiling")
    return errors


def main():
    stages = load_stages()
    errors = []
    total_citations = 0

    # ---- stage enum + stage<=ceiling invariant (register self-consistency) ----
    # BUG FIX (2026-07-29 bug hunt): this exact "if exists: parse else: {}" guard is the same hand-rolled
    # missing-file idiom load_stages() carried above — the working-tree diff had RE-INTRODUCED it twice in
    # this one file (see lib/textio.py's docstring, point 2). load_yaml() already returns {} for an absent
    # OR empty document, so both copies collapse to one call.
    _doc = load_yaml(AUTONOMY)
    errors.extend(check_stage_ceiling_invariant(_doc.get("loops") or []))
    for lid in duplicate_loop_ids(_doc.get("loops") or []):
        errors.append(f"ops/autonomy_levels.yaml: loop '{lid}' id is duplicated in the loops list — "
                      f"each loop id must appear exactly once")

    _check_cadence_heartbeat_coverage(errors)

    for path in KNOWN_CITATION_FILES:
        rel = os.path.relpath(path, ROOT)
        found = _check_citations(path, stages, errors)
        if not found:
            errors.append(f"{rel}: expected >=1 autonomy-stage citation (seen 2026-07-04) but found "
                          f"none — either the citation text was reformatted (regex rotted; fix "
                          f"CITATION_RE) or it was removed (then drop this file from "
                          f"KNOWN_CITATION_FILES in scripts/check_autonomy_consistency.py)")
        total_citations += len(found)

    known_set = {os.path.normpath(p) for p in KNOWN_CITATION_FILES}
    extra_files = sorted(
        p for pattern in EXTRA_SCAN_GLOBS for p in glob.glob(pattern)
        if os.path.normpath(p) not in known_set
    )
    for path in extra_files:
        total_citations += len(_check_citations(path, stages, errors))

    # REFACTOR (2026-08-31 code-quality pass, cross-cutting#0): this FAIL/OK block used to be
    # hand-rolled here, byte-identical to a dozen sibling checkers' own copy — see lib/report.py's
    # module docstring for the duplication class and why fail_or_ok() now owns it.
    return fail_or_ok(
        "AUTONOMY CONSISTENCY", errors,
        f"AUTONOMY CONSISTENCY: OK — {total_citations} stage citation(s) match "
        f"ops/autonomy_levels.yaml ({len(stages)} registered loop(s)).",
        hint=("Fix the stale prose/SQL citation OR ops/autonomy_levels.yaml so they agree. A loop's "
              "cited stage must never claim MORE autonomy than the register currently grants."),
    )


if __name__ == "__main__":
    raise SystemExit(main())

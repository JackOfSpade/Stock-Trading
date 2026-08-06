#!/usr/bin/env python3
"""Blocking check: every SUPERSEDED bigquery/*.sql object definition must SAY it is superseded, and
must name the CURRENT canonical file (2026-07-18).

WHY THIS EXISTS. bigquery/*.sql is apply-in-order and supersede-only: when a view/procedure needs to
change, a NEW numbered file redefines it and the older definition is kept, unmodified, as the
DR-rebuild record. That discipline is enforced only by hand-written comments — and it has silently
rotted more than once, each time leaving a live trap:

  * 2026-07-11 (commit e82cc96): bigquery/23's state.trading_enabled was re-applied live IN ISOLATION
    to add the snapshot_stale term, silently clobbering bigquery/34's already-deployed trading_halted
    exclusion and reintroducing a self-latching trading gate for 3+ days. bigquery/47 was written to
    repair exactly that.
  * 2026-07-18: bigquery/47 was found STILL asserting "THIS FILE is the new single source of truth"
    nine months of commits after bigquery/78 superseded it — while 23 and 34 both pointed forward to
    47. Every path through the chain dead-ended at a file that was itself no longer canonical, and
    state.trading_enabled_mechanical (defined in 33, 34 and 78) had no marker anywhere at all.

Re-applying a superseded definition is not cosmetic. For the trading gate it would have reverted the
drawdown AND-term from `breach_hard` (-40% catastrophe) to the -15% soft tier — hard-halting ALL
trading on a drawdown meant only to pause new entries — and let staleness gate-echoes re-latch the
gate closed, on a view that gates every order-staging step. A stale pointer is the same trap one link
further down the chain, which is precisely what a human reviewer keeps missing and a machine will not.

THE RULE. For each object defined by a `CREATE [OR REPLACE] <kind> `stock-trading-498512.<ds>.<name>``
in MORE THAN ONE numbered bigquery/NN_*.sql file, the HIGHEST-numbered file is canonical. Every
lower-numbered definition must carry — in the contiguous comment block immediately above its CREATE
statement, or in the file's top-of-file header — BOTH:
  * a "supersed*" word (SUPERSEDED / supersedes / superseding), and
  * a pointer to the CURRENT canonical file number ("bigquery/78", "78_book_...", or a bare 78).
Pointing only at an INTERMEDIATE file that is itself superseded does NOT satisfy the check — that is
the exact dead-end chain this exists to prevent. The canonical file declaring "SUPERSEDES 47" also
does not count: the operator at risk is the one reading the OLD file, who never sees the new one.

BASELINE. Pre-existing unmarked definitions (19 at introduction 2026-07-18; 5 burned down same day
when their pointers were found actively stale, see below) are grandfathered below so this can land
blocking without a full comment sweep. NEW violations fail CI, so the class cannot grow. An entry
whose comment block actively points at a non-canonical file is NEVER exempt, baselined or not —
grandfathering covers only the silent no-marker case, not a live wrong pointer. The baseline is
also checked for ROT in the other direction: once an entry is marked (or stops being multi-defined),
the check FAILS telling you to delete it, so the allowlist can't quietly outlive its subjects.

Read-only, no BigQuery/dbt CLI needed — pure text parsing of files already in the repo.

Usage:  python scripts/check_superseded_markers.py   # exit 0 = OK; 1 = new violation or stale baseline
"""
import bisect
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.sql_files import numbered_sql_files, strip_sql_comments  # noqa: E402
from lib.textio import read_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")

PROJECT = "stock-trading-498512"

# Object kinds whose redefinition can silently change live behaviour if re-applied out of order.
OBJECT_DDL = re.compile(
    r"CREATE\s+(?:OR\s+REPLACE\s+)?"
    r"(VIEW|MATERIALIZED\s+VIEW|TABLE\s+FUNCTION|FUNCTION|PROCEDURE|TABLE)\s+"
    r"(?:IF\s+NOT\s+EXISTS\s+)?"
    rf"`{re.escape(PROJECT)}\.(\w+)\.(\w+)`",
    re.IGNORECASE,
)

# Pre-existing unmarked definitions (2026-07-18). BURN-DOWN LIST, not a permanent exemption: add a
# proper "SUPERSEDED ... see bigquery/<canonical>" marker above the CREATE, then DELETE the entry here
# (the stale-baseline guard in main() will tell you to).
BASELINE = frozenset({
    ("TABLE FUNCTION", "analytics", "find_precedents", "02_ai_layer.sql"),
    ("VIEW", "analytics", "strategy_daily_returns", "03_twr_engine.sql"),
    ("VIEW", "perf", "kill_flags", "03_twr_engine.sql"),
    ("VIEW", "state", "sgov_position", "13_sgov_reconciliation.sql"),
    ("VIEW", "state", "sgov_reconciliation", "13_sgov_reconciliation.sql"),
    ("VIEW", "state", "automation_heartbeat", "16_automation_health.sql"),
    ("VIEW", "state", "cash_flows_backfill_check", "22_cash_flows.sql"),
    ("VIEW", "state", "book_drawdown_watch", "23_trading_control.sql"),
    ("PROCEDURE", "ops", "sp_auto_resolve_alerts", "34_alert_lifecycle.sql"),
    ("TABLE", "ops", "loop_promotion_log", "71_research_quality_promotion.sql"),
})


def _header_block(lines):
    """The file's leading contiguous comment/blank block (a top-of-file SUPERSEDED banner)."""
    out = []
    for ln in lines:
        if ln.strip().startswith("--") or not ln.strip():
            out.append(ln)
        else:
            break
    return "\n".join(out)


def _preceding_comment(lines, idx):
    """The contiguous comment/blank block immediately above lines[idx] (a per-statement marker)."""
    out, i = [], idx - 1
    while i >= 0:
        s = lines[i].strip()
        if s.startswith("--") or not s:
            out.append(lines[i])
            i -= 1
        else:
            break
    return "\n".join(reversed(out))


def _line_offsets(text):
    """Cumulative start-of-line character offsets in `text`, for mapping a regex match.start() back
    to a 0-based line index (matching `text.splitlines()` indexing) via bisect."""
    offsets = [0]
    for m in re.finditer("\n", text):
        offsets.append(m.end())
    return offsets


def definitions():
    """{(kind, dataset, name): [(number, filename, line_index), ...]} across numbered bigquery/*.sql.

    Iterates via scripts/lib/sql_files.py's numbered_sql_files() — the shared NN-prefix parser this
    script's own NUMBERED_FILE regex was consolidated into (codebase audit 2026-07-26). NOTE this is
    a pure dedup, not a bug fix here: violations() below determines each object's canonical file via
    max(n for n, _, _ in occurrences), which is order-independent, so the lexical-vs-numeric mismatch
    that made check_dbt_view_coverage.py's found.add()/discard() apply CREATE/DROP out of order can't
    happen to this script's max()-based logic regardless of what order definitions() visits files in."""
    found = collections.defaultdict(list)
    for number, path in numbered_sql_files(BIGQUERY_DIR):
        if os.path.isdir(path):
            continue
        fn = os.path.basename(path)
        text = read_text(path)
        # Match against the WHOLE file text, not line-by-line: `\s+` in OBJECT_DDL already spans
        # newlines, so a CREATE statement legally wrapped across two lines (e.g. the keyword and the
        # backtick-quoted name on separate lines, a common BigQuery style) is still recognized here.
        # A per-line search would silently never record that occurrence at all -- collapsing
        # `occurrences` to a single filename and letting an unmarked OLDER definition slip through
        # uncompared, the exact dead-end-chain trap this script exists to catch (see header).
        #
        # BUG FIX (2026-07-29, confirmed live): OBJECT_DDL used to run against the raw file text, so
        # a `-- CREATE OR REPLACE TABLE ...` line inside a documentation comment (bigquery/
        # 02_ai_layer.sql:23's "Reproduce:" recipe for the ticker-backfill migration) parsed as a REAL
        # object definition. strip_sql_comments() blanks comment text with same-length whitespace
        # (newlines untouched), so OBJECT_DDL.finditer() below can no longer match inside one, while
        # `offsets` — built from the UNSTRIPPED text — still maps a match's char offset back to the
        # right line, since stripping never changes the text's length or line breaks.
        offsets = _line_offsets(text)
        for hit in OBJECT_DDL.finditer(strip_sql_comments(text)):
            kind = " ".join(hit.group(1).upper().split())
            line_idx = bisect.bisect_right(offsets, hit.start()) - 1
            found[(kind, hit.group(2), hit.group(3))].append((number, fn, line_idx))
    return found


def marks_superseded(text, canonical_number):
    """True when `text` both calls itself superseded AND points at the CURRENT canonical file.

    The pointer must look like an actual FILE reference — "bigquery/78", "78_book_..." — not a bare
    number. A bare \b78\b alternative used to be accepted (2026-07-18 audit): combined with the mere
    presence of the word "superseded" ANYWHERE in the same comment block, any coincidental standalone
    occurrence of the canonical number (a line reference, a threshold, a date fragment) silently
    satisfied the gate while pointing the operator nowhere — exactly the stale-pointer trap this
    check exists to catch.
    """
    if "supersed" not in text.lower():
        return False
    n = canonical_number
    return bool(
        re.search(rf"bigquery/0*{n}\b", text)
        # [A-Za-z]: the NN_ prefix (scripts/lib/sql_files.py's NUMBERED_FILE: ^(\d+)_.*\.sql$)
        # doesn't forbid an uppercase first letter after the numeric prefix (e.g. a future
        # 99_ParkRebalance.sql), so a correctly-marked pointer to one must not be rejected just
        # because this class was hardcoded lowercase-only.
        or re.search(rf"\b0*{n}_[A-Za-z]", text)
    )


def violations():
    """(sorted new_violations, sorted still_baselined, sorted stale_baseline_entries)."""
    cache, found = {}, definitions()
    new, still = [], []
    live_keys = set()
    for (kind, ds, name), occurrences in found.items():
        if len({fn for _, fn, _ in occurrences}) < 2:
            continue
        canonical = max(n for n, _, _ in occurrences)
        for number, fn, idx in occurrences:
            if number == canonical:
                continue
            entry = (kind, ds, name, fn)
            if fn not in cache:
                lines = read_text(os.path.join(BIGQUERY_DIR, fn)).splitlines()
                cache[fn] = (lines, _header_block(lines))
            lines, header = cache[fn]
            context = _preceding_comment(lines, idx) + "\n" + header
            if marks_superseded(context, canonical):
                continue
            # Only STILL-VIOLATING entries count as "live" for the stale-baseline diff below: a
            # baselined entry that has since been marked must show up as stale so it gets deleted,
            # not stay silently exempted forever because the definition still exists.
            live_keys.add(entry)
            canonical_file = next(f for n, f, _ in occurrences if n == canonical)
            # BASELINE grandfathers only the no-marker-at-all case. A definition whose comment
            # block actively points at some OTHER superseded occurrence of the same object (a
            # stale/dead-end pointer, or a canonical-file "SUPERSEDES <old>" read in the old file's
            # direction) is the exact 47-style trap in this script's header and is never exempt.
            other_numbers = {n for n, _, _ in occurrences}
            stale_pointer = any(
                n not in (number, canonical) and marks_superseded(context, n)
                for n in other_numbers
            )
            is_exempt = entry in BASELINE and not stale_pointer
            (still if is_exempt else new).append((entry, canonical_file, idx + 1))
    stale = sorted(BASELINE - live_keys)
    return sorted(new), sorted(still), stale


# ---- CONTRADICTORY "SUPERSEDED LIVE" CLAIM DETECTION (2026-08-06 adversarial audit, D7) --------------
# violations() above has a blind spot: `if marks_superseded(context, canonical): continue` short-
# circuits the instant ANY valid pointer to the canonical file appears anywhere in the merged comment
# blob (preceding comment + file header) — so a SECOND, STALE "SUPERSEDED LIVE by bigquery/N" banner
# for the SAME object, naming a DIFFERENT (non-canonical) file, sitting right next to a correct one, is
# never even inspected. Confirmed live (2026-08-06): bigquery/75, 111, and 120 each carried an older
# "SUPERSEDED LIVE by bigquery/128 ... current single source of truth" banner stacked directly above a
# newer, correct "SUPERSEDED LIVE by bigquery/142 ..." banner for `ops.sp_sq_cadence_check` — two
# competing "this IS the current truth" claims naming different files — and violations() reported zero
# new violations for all three (marks_superseded(context, 142) was True, so the loop `continue`d before
# ever looking at the stale 128 claim sitting in the same block). Fixed in place the same commit as this
# check (see bigquery/75/111/120's reworded banners: the stale claim now reads as history, not a second
# competing "current" assertion).
#
# This check is INDEPENDENT of that short-circuit: it inspects the raw, immediately-preceding comment
# block for every non-canonical occurrence and fails the instant it contains MORE THAN ONE DISTINCT
# "SUPERSEDED LIVE by bigquery/NN" target — regardless of whether one of them happens to be correct — so
# it can no longer be short-circuited by a correct pointer sitting elsewhere in the same blob.
#
# SCOPED TO THE IMMEDIATE PRECEDING COMMENT ONLY — deliberately NOT `+ header` the way marks_superseded()
# is: several files legitimately carry a DIFFERENT object's own "SUPERSEDED LIVE by bigquery/NN" banner
# inside the shared top-of-file header (e.g. bigquery/48_cadence_monitor_unbounded.sql's header carries
# the state.cadence_watch VIEW's own banner, ABOVE a separate, independently-marked ops.sp_assert_deps
# PROCEDURE further down the same file). Folding the header in here would cross-contaminate one object's
# genuine, single claim with an unrelated object's claim living earlier in the same file and false-flag
# it as a contradiction. The immediately preceding comment block is specific to THIS occurrence's own
# CREATE statement and cannot cross-contaminate between two different objects in the same file this way
# (measured empirically against the real tree while building this check: scoping to `_preceding_comment`
# alone finds exactly the 3 real 2026-08-06 instances above, plus 2 more pre-existing, unrelated ones —
# see CONTRADICTION_BASELINE below; scoping to `_preceding_comment + header` instead spuriously flags 9
# additional object pairs that merely share a file with a differently-targeted, unrelated banner).
SUPERSEDED_LIVE_CLAIM = re.compile(r"SUPERSEDED LIVE by bigquery/0*(\d+)")

# Pre-existing stacked-claim contradictions, predating this 2026-08-06 hardening and NOT part of the
# sp_sq_cadence_check defect it was written to catch (found while scoping the check above — same shape,
# different object, a separate, already-existing issue this fix does not address). BURN-DOWN LIST, same
# discipline as BASELINE above: reword the STALE banner (the one NOT naming the true canonical file)
# into a historical note that no longer claims to be "the current single source of truth" for the
# object — see bigquery/75/111/120's `ops.sp_sq_cadence_check` banners (this same commit) for the
# pattern to follow — then DELETE the entry here (the stale-baseline guard below will tell you to).
CONTRADICTION_BASELINE = frozenset({
    ("VIEW", "analytics", "declared_vs_realized", "26_process_metrics.sql"),
    ("VIEW", "analytics", "declared_vs_realized", "118_decision_record_audit_followups.sql"),
})


def contradiction_violations():
    """(sorted new_contradictions, sorted still_baselined, sorted stale_baseline_entries) — same
    three-way shape as violations() above, but for the SUPERSEDED-LIVE-CLAIM-contradiction rule, kept
    as an INDEPENDENT pass (not folded into violations() itself, and violations() is unchanged) so it
    can never be short-circuited by marks_superseded()'s own canonical-pointer check — see the module
    comment above. Each `new`/`still` entry is (entry, claims, line) where claims is the sorted list of
    every DISTINCT bigquery/NN number the block claims as "current single source of truth" (len > 1,
    always, or it wouldn't be here)."""
    found = definitions()
    new, still, live_keys = [], [], set()
    cache = {}
    for (kind, ds, name), occurrences in found.items():
        if len({fn for _, fn, _ in occurrences}) < 2:
            continue
        canonical = max(n for n, _, _ in occurrences)
        for number, fn, idx in occurrences:
            if number == canonical:
                continue
            if fn not in cache:
                cache[fn] = read_text(os.path.join(BIGQUERY_DIR, fn)).splitlines()
            own_comment = _preceding_comment(cache[fn], idx)
            claims = sorted({int(n) for n in SUPERSEDED_LIVE_CLAIM.findall(own_comment)})
            if len(claims) <= 1:
                continue
            entry = (kind, ds, name, fn)
            live_keys.add(entry)
            (still if entry in CONTRADICTION_BASELINE else new).append((entry, claims, idx + 1))
    stale = sorted(CONTRADICTION_BASELINE - live_keys)
    return sorted(new), sorted(still), stale


def main():
    new, still, stale = violations()
    c_new, c_still, c_stale = contradiction_violations()

    print(f"superseded-marker check: {len(new) + len(c_new)} new violation(s), "
          f"{len(still) + len(c_still)} baselined, {len(stale) + len(c_stale)} stale baseline entry/entries.")

    if still:
        print("\nBaselined (pre-existing backlog — safe to burn down any time):")
        for (kind, ds, name, fn), canonical_file, line in still:
            print(f"  - {kind} {ds}.{name} in bigquery/{fn}:{line} -> canonical is bigquery/{canonical_file}")

    if c_still:
        print("\nContradiction-baselined (pre-existing STACKED \"SUPERSEDED LIVE\" claims naming "
              "different files for the same object — safe to burn down any time; see "
              "CONTRADICTION_BASELINE in scripts/check_superseded_markers.py):")
        for (kind, ds, name, fn), claims, line in c_still:
            named = ", ".join(f"bigquery/{n}" for n in claims)
            print(f"  - {kind} {ds}.{name} in bigquery/{fn}:{line} claims [{named}] as \"current single "
                  f"source of truth\"")

    if stale:
        print("\nSTALE BASELINE — these entries are now compliant (or no longer multi-defined). Delete "
              "them from BASELINE in scripts/check_superseded_markers.py so the allowlist can't outlive "
              "its subjects:")
        for kind, ds, name, fn in stale:
            print(f"  - (\"{kind}\", \"{ds}\", \"{name}\", \"{fn}\")")

    if c_stale:
        print("\nSTALE CONTRADICTION BASELINE — these entries no longer contain a stacked contradictory "
              "claim (or are no longer multi-defined). Delete them from CONTRADICTION_BASELINE in "
              "scripts/check_superseded_markers.py so the allowlist can't outlive its subjects:")
        for kind, ds, name, fn in c_stale:
            print(f"  - (\"{kind}\", \"{ds}\", \"{name}\", \"{fn}\")")

    if new or c_new:
        if new:
            print("\nFAIL — a superseded definition does not say so, or points at a file that is ITSELF "
                  "superseded. An operator reading it would think it is canonical and could re-apply it "
                  "live, silently reverting the newer definition (see this script's header for the two "
                  "times that already happened). Add a comment above the CREATE statement naming the "
                  "CURRENT canonical file, e.g.:")
            print("    -- SUPERSEDED LIVE by bigquery/<NN>_<name>.sql — current single source of truth for")
            print("    -- this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only.")
            print("    -- DO NOT re-apply this CREATE statement live in isolation.")
            for (kind, ds, name, fn), canonical_file, line in new:
                print(f"  ✗ {kind} {ds}.{name} in bigquery/{fn}:{line} -> must name bigquery/{canonical_file}")
        if c_new:
            print("\nFAIL — a comment block claims MORE THAN ONE file as the \"current single source of "
                  "truth\" for the same object (stacked, contradictory SUPERSEDED LIVE banners). At most "
                  "one file can truly be canonical — reword the STALE claim into a historical note (it "
                  "no longer IS the current truth, even though it once was) instead of leaving it "
                  "standing as a second, competing assertion. See bigquery/75_scheduled_query_wrappers."
                  "sql's ops.sp_sq_cadence_check banners for the pattern.")
            for (kind, ds, name, fn), claims, line in c_new:
                named = ", ".join(f"bigquery/{n}" for n in claims)
                print(f"  ✗ {kind} {ds}.{name} in bigquery/{fn}:{line} names conflicting current-truth "
                      f"targets: [{named}]")
        return 1

    if stale or c_stale:
        return 1

    print("OK: every superseded bigquery/*.sql definition names the current canonical file "
          "(or is a known baselined item).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

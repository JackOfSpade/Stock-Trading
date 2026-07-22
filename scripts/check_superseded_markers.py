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

NUMBERED_FILE = re.compile(r"^(\d+)_.*\.sql$")

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
    ("VIEW", "state", "daily_staging_totals", "23_trading_control.sql"),
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
    """{(kind, dataset, name): [(number, filename, line_index), ...]} across numbered bigquery/*.sql."""
    found = collections.defaultdict(list)
    for fn in sorted(os.listdir(BIGQUERY_DIR)):
        m = NUMBERED_FILE.match(fn)
        path = os.path.join(BIGQUERY_DIR, fn)
        if not m or os.path.isdir(path):
            continue
        text = open(path, encoding="utf-8").read()
        # Match against the WHOLE file text, not line-by-line: `\s+` in OBJECT_DDL already spans
        # newlines, so a CREATE statement legally wrapped across two lines (e.g. the keyword and the
        # backtick-quoted name on separate lines, a common BigQuery style) is still recognized here.
        # A per-line search would silently never record that occurrence at all -- collapsing
        # `occurrences` to a single filename and letting an unmarked OLDER definition slip through
        # uncompared, the exact dead-end-chain trap this script exists to catch (see header).
        offsets = _line_offsets(text)
        for hit in OBJECT_DDL.finditer(text):
            kind = " ".join(hit.group(1).upper().split())
            line_idx = bisect.bisect_right(offsets, hit.start()) - 1
            found[(kind, hit.group(2), hit.group(3))].append((int(m.group(1)), fn, line_idx))
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
        # [A-Za-z]: NUMBERED_FILE (^(\d+)_.*\.sql$) doesn't forbid an uppercase first letter after the
        # numeric prefix (e.g. a future 99_ParkRebalance.sql), so a correctly-marked pointer to one
        # must not be rejected just because this class was hardcoded lowercase-only.
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
                lines = open(os.path.join(BIGQUERY_DIR, fn), encoding="utf-8").read().splitlines()
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


def main():
    new, still, stale = violations()

    print(f"superseded-marker check: {len(new)} new violation(s), "
          f"{len(still)} baselined, {len(stale)} stale baseline entry/entries.")

    if still:
        print("\nBaselined (pre-existing backlog — safe to burn down any time):")
        for (kind, ds, name, fn), canonical_file, line in still:
            print(f"  - {kind} {ds}.{name} in bigquery/{fn}:{line} -> canonical is bigquery/{canonical_file}")

    if stale:
        print("\nSTALE BASELINE — these entries are now compliant (or no longer multi-defined). Delete "
              "them from BASELINE in scripts/check_superseded_markers.py so the allowlist can't outlive "
              "its subjects:")
        for kind, ds, name, fn in stale:
            print(f"  - (\"{kind}\", \"{ds}\", \"{name}\", \"{fn}\")")

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
        return 1

    if stale:
        return 1

    print("OK: every superseded bigquery/*.sql definition names the current canonical file "
          "(or is a known baselined item).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

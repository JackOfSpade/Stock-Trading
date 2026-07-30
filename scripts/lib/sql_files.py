"""Canonical apply-order walk over bigquery/*.sql (codebase audit 2026-07-26), plus a shared
comment-stripping helper for the DDL-matching regexes that walk it (2026-07-29 bug hunt).

WHY THIS EXISTS. bigquery/*.sql is apply-in-order: file NN's DDL is applied strictly after file
MM's whenever NN > MM (see bigquery/README.md, check_superseded_markers.py's header). Several
scripts need to walk that tree IN APPLY ORDER — to resolve "final effective definition"
(check_live_sql_parity.py), to determine which CREATE/DROP pairs are still live
(check_dbt_view_coverage.py), or to find the highest-numbered definition of an object
(check_superseded_markers.py). `sorted(os.listdir(...))` is LEXICAL, not numeric, and the two
only agree while every NN shares the same digit-width.

That stopped being true the moment bigquery/ grew past 99 files: lexical sort puts "100_..."
BEFORE "10_...", "75_...", and "92_...", because '1' < '7' < '9' as the first *character*, and a
"100" prefix is a lexical match for "10" plus a trailing "0_...". Any caller that walks
`sorted(os.listdir(BIGQUERY_DIR))` and applies CREATE/DROP (or last-writer-wins) sequencing over
that order gets the apply order WRONG for every 3-digit file relative to any 2-digit (or shorter)
file whose numeric value is actually larger.

Concretely (codebase audit 2026-07-26): check_dbt_view_coverage.py's live_views() walked
bigquery/*.sql in `sorted(os.listdir(...))` order, so bigquery/108_park_allocator_immediate_
binding.sql's `DROP VIEW state.park_control_latest` (etc.) was applied — lexically — BEFORE
bigquery/75_scheduled_query_wrappers.sql and bigquery/92_park_allocator.sql's `CREATE OR REPLACE
VIEW` of the same names, so the later (in real apply order) CREATE won the found.add()/discard()
race and 3 already-dropped views were reported live. The defect is bidirectional: the same
lexical-vs-numeric mismatch can just as easily discard() a genuinely-still-live view (a DROP in a
lower-numbered-but-lexically-later file wrongly "wins" over a CREATE in a higher-numbered-but-
lexically-earlier one) — exactly the failure check_dbt_view_coverage.py exists to catch, silently
inverted.

check_live_sql_parity.py's numbered_sql_files() and dbt_parity.py's docstring both already knew
this ("NN is zero-padded to 2 digits today, but sort by the leading integer explicitly so this
stays correct if that ever changes") — that "if it ever changes" is exactly what happened when
bigquery/ crossed 99 files, and check_dbt_view_coverage.py never got the same fix. This module is
the one place that logic now lives, so every caller shares one tested implementation instead of
each re-deriving (and one of them forgetting) the same numeric-vs-lexical distinction.

check_superseded_markers.py is a DIFFERENT case and worth stating explicitly, so nobody later
"fixes" a bug there that never existed: it groups occurrences by object name and takes `max()` over
the parsed numbers to find the canonical file, which is order-INDEPENDENT — iteration order never
changes which file wins there, only the order results are collected in. It was converted to this
helper anyway, but purely to retire its duplicate copy of the `^(\\d+)_.*\\.sql$` prefix regex (one
parser, one place); that conversion is a no-op on its output, NOT a bug fix.

strip_sql_comments() (below) is a SEPARATE consolidation, added 2026-07-29: check_superseded_
markers.py's OBJECT_DDL and check_dbt_view_coverage.py's VIEW_DDL/DROP_VIEW_DDL each matched CREATE/
DROP statements against raw file text with no comment handling, so a `-- CREATE OR REPLACE ...` line
inside a doc comment parsed as a real definition (confirmed live: bigquery/02_ai_layer.sql:23). Both
now strip comments through this one function first. check_live_sql_parity.py's CREATE_STMT/DROP_STMT
do NOT use it — they already anchor every match to column 0 (`^`, re.MULTILINE), which a `--`-prefixed
comment line can never satisfy, so that script has its own, already-correct comment defense and gains
nothing from switching (see its own module docstring's "KNOWN, ACCEPTED LIMIT" note before changing
that).
"""
import os
import re

NUMBERED_FILE = re.compile(r"^(\d+)_.*\.sql$")


def numbered_sql_files(bigquery_dir):
    """(number, path) pairs for every bigquery/NN_*.sql file in `bigquery_dir`, sorted by the
    parsed leading integer — NUMERIC apply order, not `sorted(os.listdir(...))`'s lexical order.
    A file with no leading `NN_` prefix (e.g. a README) is excluded — it has no declared apply
    position, so there is no correct place to put it in an apply-ordered walk. That matches the prior
    behavior of check_live_sql_parity.py and check_superseded_markers.py (both already required the
    prefix) but NOT of check_dbt_view_coverage.py, which used to scan every `*.sql` regardless; that
    caller handles the difference itself rather than silently narrowing its coverage scan (see its
    live_views() — adversarial review, codebase audit 2026-07-26). Dormant either way: every file in
    bigquery/ follows the NN_ convention today."""
    files = []
    for fn in os.listdir(bigquery_dir):
        m = NUMBERED_FILE.match(fn)
        if m:
            files.append((int(m.group(1)), os.path.join(bigquery_dir, fn)))
    return sorted(files)


def sql_file_paths(bigquery_dir):
    """Just the paths from numbered_sql_files(), in the same numeric apply order — the thin
    accessor for callers (e.g. check_live_sql_parity.py) that only ever used the path half of the
    pair."""
    return [path for _, path in numbered_sql_files(bigquery_dir)]


def strip_sql_comments(text):
    """Blank out `--` line comments and `/* ... */` block comments in `text`, replacing every
    stripped character with a space and leaving every newline in place — so the RETURN VALUE has
    the exact same length and line breaks as the input, and any offset/line-number a caller
    computed against the original text (e.g. check_superseded_markers.py's bisect over
    _line_offsets()) still lands on the right character after stripping.

    String literals ('...', "...", triple-quoted) are copied verbatim and never treated as
    containing a comment: this repo routinely uses a bare `--` as an em-dash inside a quoted
    description (e.g. bigquery/03_twr_engine.sql:229's TWR-chain error message, or
    bigquery/100_market_only_order_guard.sql's guard-rejection strings), and blanking through one
    would both corrupt the literal and, in principle, hide a real statement that happened to share
    a line with it. Backtick-quoted identifiers are NOT tracked as literals — this repo's
    identifiers never contain `--` or `/*` (verified against bigquery/*.sql today), so treating a
    backtick-quoted name as ordinary text is a no-op in practice.

    WHY THIS EXISTS (2026-07-29 bug hunt). check_superseded_markers.py's OBJECT_DDL matched a
    `--   CREATE OR REPLACE TABLE ...` line inside a documentation "Reproduce:" recipe
    (bigquery/02_ai_layer.sql:23) as though it were a REAL object definition — confirmed live via a
    one-line scan over bigquery/*.sql. check_dbt_view_coverage.py's VIEW_DDL/DROP_VIEW_DDL had the
    identical gap (no caller had ever hit it there only because no commented-out VIEW DDL for a
    state/analytics/perf object exists in the tree today — the bug was latent, not absent). Both
    callers now run this over the file text before matching, instead of each re-deriving its own
    (previously absent) comment handling.
    """
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in ("'", '"'):
            quote = c
            triple = text[i:i + 3] == quote * 3
            j = i + (3 if triple else 1)
            end = quote * 3 if triple else quote
            while j < n:
                if not triple and text[j] == "\\":
                    j += 2
                    continue
                if text[j:j + len(end)] == end:
                    j += len(end)
                    break
                if not triple and text[j] == "\n":   # unterminated single-line literal — stop here
                    break
                j += 1
            out.append(text[i:j])
            i = j
            continue
        if text.startswith("--", i):
            eol = text.find("\n", i)
            stop = n if eol < 0 else eol
            out.append(" " * (stop - i))
            i = stop
            continue
        if text.startswith("/*", i):
            close = text.find("*/", i + 2)
            stop = n if close < 0 else close + 2
            out.append("".join(ch if ch == "\n" else " " for ch in text[i:stop]))
            i = stop
            continue
        out.append(c)
        i += 1
    return "".join(out)

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

OBJECT_DDL/normalize_kind() and line_offsets() (below) are a THIRD consolidation (2026-08-08).
check_superseded_markers.py and check_superseded_by_discipline.py had each hand-written their own copy
of the CREATE-statement object-definition regex and its kind-whitespace-normalization step — both are
BLOCKING CI gates over the same 234 bigquery/*.sql files, so a drift between the copies would let one
gate silently stop seeing a class of definition the other still catches. Diffed character-by-character
before unifying: the two copies had already drifted to a different ALTERNATION ORDER inside the
capture group (markers.py tried `VIEW` before `MATERIALIZED\\s+VIEW`/`TABLE\\s+FUNCTION`; discipline.py
tried `TABLE\\s+FUNCTION` first) but this is NOT a behavior difference — regex alternation only diverges
when a SHORTER alternative that would also match sits before a LONGER one sharing the same prefix at
the same start position, and the only such pair in this set is TABLE / TABLE\\s+FUNCTION, which both
copies already ordered TABLE\\s+FUNCTION-before-TABLE. Confirmed with a byte-for-byte stdout diff of
both gates over the full bigquery/*.sql tree, before and after this consolidation (identical). Separately,
check_superseded_markers.py's `_line_offsets()` and check_sq_version_registry.py's helper of the same
name were byte-identical already (only their docstrings differed, describing each caller's own
0-based-vs-1-based bisect convention) — moved here unchanged.
"""
import os
import re

NUMBERED_FILE = re.compile(r"^(\d+)_.*\.sql$")

# Used only to build OBJECT_DDL below. Callers that need this project id for their OWN regexes/messages
# (e.g. check_superseded_by_discipline.py's WRITE_POSITION-adjacent read-position scan, or any script's
# error text) keep their own `PROJECT = "stock-trading-498512"` constant — this one is private to this
# module's own regex construction, not a second public spelling of the same string for callers to pick
# between.
_PROJECT = "stock-trading-498512"

# Object kinds whose redefinition can silently change live behaviour if re-applied out of order.
# Group 1 = kind, group 2 = dataset, group 3 = name.
OBJECT_DDL = re.compile(
    r"CREATE\s+(?:OR\s+REPLACE\s+)?"
    r"(TABLE\s+FUNCTION|MATERIALIZED\s+VIEW|VIEW|FUNCTION|PROCEDURE|TABLE)\s+"
    r"(?:IF\s+NOT\s+EXISTS\s+)?"
    rf"`{re.escape(_PROJECT)}\.(\w+)\.(\w+)`",
    re.IGNORECASE,
)


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


def resolve_canonical(occurrences):
    """(winner_number, winner_filenames) — the highest-numbered file(s) among `occurrences`, an
    iterable of tuples whose first two elements are (number, filename) (any trailing elements, e.g.
    a match position, are ignored via `*_`). winner_filenames is the SORTED, DEDUPED list of every
    DISTINCT filename tied at winner_number — length 1 in the overwhelmingly common case, but NOT
    provably always 1: `numbered_sql_files()`'s NN_ prefix is not required to be unique (see its own
    docstring), so two files can legitimately share a leading number (e.g. bigquery/
    114_period_aware_dependency_gate.sql and bigquery/114_selfheal_log_created_outcome.sql, both
    live in this repo today) and, should a FUTURE file at a duplicated number define an object a
    caller here is tracking, `max()` alone can no longer tell the two apart.

    THE BUG THIS EXISTS TO FIX (2026-08-06 adversarial audit, D6): check_sq_version_registry.py's
    resolve_winners() and check_cadence_consistency.py's find_canonical_cadence_watch_file() each
    independently computed `max(n for n, ... in occurrences)` and then silently assumed exactly one
    filename carried that number ("a single file number maps to exactly one filename" — true only
    because it happened to be true, never because anything enforced it). A future duplicate-number
    collision on a TRACKED object would have made either checker silently validate whichever of the
    two colliding files happened to sort first, instead of failing loud — the exact class of
    false-green these checkers exist to prevent. This is dormant on the CURRENT tree (verified:
    neither bigquery/114 file defines an object either caller tracks), which is why it must return
    the full tied set rather than raising outright: raising here would turn a currently-harmless
    duplicate NN prefix into an unconditional hard failure the callers cannot selectively silence for
    the (common, legitimate) case where the collision never touches a tracked object. Callers MUST
    check `len(winner_filenames) > 1` themselves and report an explicit ambiguity error naming every
    colliding filename — never index [0] unconditionally.
    """
    winner_number = max(n for n, _fn, *_ in occurrences)
    winner_filenames = sorted({fn for n, fn, *_ in occurrences if n == winner_number})
    return winner_number, winner_filenames


def strip_sql_comments(text):
    """Blank out `--` line comments and `/* ... */` block comments in `text`, replacing every
    stripped character with a space and leaving every newline in place — so the RETURN VALUE has
    the exact same length and line breaks as the input, and any offset/line-number a caller
    computed against the original text (e.g. check_superseded_markers.py's bisect over this
    module's line_offsets()) still lands on the right character after stripping.

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


def normalize_kind(raw):
    """Collapse a captured OBJECT_DDL kind (group 1) to one whitespace-normalized, upper-cased form
    — "TABLE FUNCTION", never "TABLE  FUNCTION" or "table\\nfunction". OBJECT_DDL's alternatives use
    `\\s+` between two keywords (TABLE_\\s+FUNCTION, MATERIALIZED\\s+VIEW), so a CREATE statement
    legally wrapped across lines can capture internal whitespace wider than a single space; the
    alternation itself never captures LEADING or TRAILING whitespace, so there is nothing to strip
    there.

    check_superseded_markers.py and check_superseded_by_discipline.py each spelled this differently
    pre-consolidation (`" ".join(x.upper().split())` vs `re.sub(r"\\s+", " ", x).upper()`) but the two
    were byte-for-byte equivalent on every input OBJECT_DDL can produce — one spelling now (2026-08-08
    dedup)."""
    return " ".join(raw.upper().split())


def line_offsets(text):
    """Cumulative start-of-line character offsets in `text`: offsets[i] is the character position
    where line i begins (0-based). Pass a regex match's `.start()` to `bisect.bisect_right(offsets,
    pos)` to get a 1-based line number, or subtract 1 from that for a 0-based line index matching
    `text.splitlines()` indexing — callers differ on which they want (check_superseded_markers.py
    uses the 0-based form directly; check_sq_version_registry.py's own `_line_no()` helper wraps the
    1-based form), so this returns the raw offsets rather than picking one convention for them.

    Moved here 2026-08-08: check_superseded_markers.py and check_sq_version_registry.py each carried
    their own copy, already byte-identical apart from a docstring difference describing which of the
    two bisect conventions above their own caller used."""
    offsets = [0]
    for m in re.finditer("\n", text):
        offsets.append(m.end())
    return offsets

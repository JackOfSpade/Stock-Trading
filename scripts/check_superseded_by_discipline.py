#!/usr/bin/env python3
"""Blocking check: the superseded_by append-only correction discipline, for every table that has it
(2026-08-06). TWO independent checks over CANONICAL bigquery/*.sql definitions.

THE CONVENTION. A correction is a NEW row that reproduces the record and sets its own `superseded_by`
to the OBSOLETE row's id. The obsolete row is left untouched forever, for audit. So a reader must
exclude the row that is NAMED:

    <pk> NOT IN (SELECT superseded_by FROM <table> WHERE superseded_by IS NOT NULL)

`state.decision_log_current` (bigquery/144) and `state.adversarial_reviews_current` (bigquery/143) are
where that anti-join is written ONCE. A reader that goes to a base table instead silently returns BOTH
the obsolete row and its replacement — no error, no alert, just a double-count or a stale verdict.
That invisibility is exactly why this needs a machine check rather than a convention.

CHECK 1 — READ POSITION. Every canonical object that reads a guarded table must read its _current
view, unless it is in ALLOWLIST with a stated reason.

CHECK 2 — INVERTED PREDICATE. `superseded_by IS NULL` is backwards by construction and is blocked
outright, with no allowlist. See the INVERTED_PREDICATE comment below.

WHY BOTH EXIST. events.decision_log has carried this convention since bigquery/122 (2026-08-01) with
NOTHING enforcing it, and by 2026-08-06 it had rotted in both directions at once:
  * state.go_without_order's canonical definition (bigquery/105:215) carried the INVERTED predicate,
    copied forward verbatim from bigquery/18:223 during a redefinition about something else. Check 2
    exists because of it.
  * 8 canonical consumers read the raw table with no exclusion at all, including analytics.
    thesis_outcomes — the root source for calibration, declared_vs_realized, process_scorecard and a
    W5 alert. Check 1 exists because of them.
Both read CLEAN at the time, purely by accident: bigquery/116 and /118 had justified leaving the
convention unenforced as "currently INERT either way — superseded_by is populated on 0 of 496 rows",
and by 2026-08-06 that figure was 3, including a thesis-construction GO. An inert-today defect stops
being inert without anyone noticing; that is the whole failure mode here.

DECISION_LOG IS NOT ADVERSARIAL_REVIEWS. adversarial_reviews gets a blanket "all canonical readers use
the view" rule because every one of its readers wants final-effective rows. decision_log's consumers
are genuinely heterogeneous — state.freshness is a dead-man's switch, state.embedding_health is a
row-count parity check, analytics.decision_embeddings is a raw substrate — and filtering those would
BREAK them. Hence the allowlist, with a reason on every entry.

WHAT IS CHECKED. Only the CANONICAL definition of each object — the highest-numbered file that defines
it, resolved exactly like check_superseded_markers.py does. A superseded definition in a lower-numbered
file is DR-rebuild history that is never re-applied, so a raw read (or an inverted predicate) there is
expected and is not a finding — bigquery/18, /105 and /116 all still contain the inverted form and are
correctly silent.

KNOWN BLIND SPOTS — two, both static-text-scan limits. Do not read this checker's silence as proof.
  1. DYNAMIC SQL. A table reached through EXECUTE IMMEDIATE FORMAT(...) is invisible.
     ops.sp_restore_drill (bigquery/17:90) does exactly this, looping every events.* table by name; it
     never appears as a violation and cannot be allowlisted, because there is no literal
     `project.dataset.table` for the regex to find. Its raw read happens to be correct on the merits
     (row-count restore fidelity needs the true physical count). Any future dynamic reader is unseen.
  2. UNQUALIFIED REFERENCES. _read_positions matches only the fully backtick-qualified
     `project.dataset.table` form. A read written as `dataset.table`, unquoted, or split-qualified
     (`project`.dataset.table) is invisible. Verified 2026-08-06: zero such references exist in
     bigquery/*.sql today, which is why the pattern stays narrow — broadening it would false-positive
     on prose. If the house style ever changes, broaden it.

Read-only, no BigQuery/dbt CLI needed — pure text parsing of files already in the repo.

Usage:  python scripts/check_superseded_by_discipline.py  # exit 0 = OK; 1 = violation or stale allowlist
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib.sql_files import numbered_sql_files, resolve_canonical, strip_sql_comments  # noqa: E402
from lib.textio import read_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_DIR = os.path.join(ROOT, "bigquery")

PROJECT = "stock-trading-498512"

# Tables whose readers must go through a *_current view.
GUARDED_TABLES = {
    "events.adversarial_reviews": "state.adversarial_reviews_current",
    "events.decision_log": "state.decision_log_current",
}

# CHECK 2 — the inverted predicate, which is NEVER correct for either table.
#
# A WHERE/AND/OR predicate on `superseded_by IS NULL` selects the rows NOBODY has corrected PLUS the
# obsolete rows, and DROPS every correction row (whose superseded_by is populated by definition). It is
# backwards by construction, so unlike the read-position check below this one needs no allowlist.
#
# The predicate introducer is material: stored-procedure control flow legitimately needs `IF
# p_superseded_by IS NULL THEN` to distinguish a normal append from a correction.  That is not a row
# filter and must not make this checker red.
#
# This is not theoretical. state.go_without_order carried it in its canonical definition
# (bigquery/105:215) from 2026-07-25 until 2026-08-06, copied forward verbatim from bigquery/18:223
# during a redefinition that was about something else entirely. It read clean only because no GO
# decision had yet been corrected inside its 2-to-9-day window. bigquery/122:43 warns against exactly
# this form in prose; prose did not stop it, so this does.
INVERTED_PREDICATE = re.compile(
    r"\b(?:WHERE|AND|OR)\s+(?:[A-Za-z_][A-Za-z0-9_]*\.)?superseded_by\s+IS\s+NULL\b",
    re.IGNORECASE,
)

# ALLOWLIST pseudo-object name for statements that live outside any CREATE (migrations, backfills).
FILE_LEVEL = "<file-level statements>"

# Group 1 = object kind (CAPTURING — _definition_segments needs it to know whether a body may
# legitimately contain DML). Group 2 = dataset, group 3 = name.
OBJECT_DDL = re.compile(
    r"CREATE\s+(?:OR\s+REPLACE\s+)?"
    r"(TABLE\s+FUNCTION|MATERIALIZED\s+VIEW|VIEW|FUNCTION|PROCEDURE|TABLE)\s+"
    r"(?:IF\s+NOT\s+EXISTS\s+)?"
    rf"`{re.escape(PROJECT)}\.(\w+)\.(\w+)`",
    re.IGNORECASE,
)

# Classifying a reference as a READ.
#
# The obvious implementation — require FROM or JOIN immediately before the backticked name — is WRONG,
# and was the first version of this script. It silently misses a comma-style implicit join:
#     FROM `...state.strategy_roster` r, `...events.adversarial_reviews` a
# where the second table is preceded by a comma and an alias, not by FROM/JOIN. That is not a
# hypothetical idiom: this repo already uses it live in bigquery/10, /23, /34, /78, /94, /97, /107,
# /130 and /134. A future file reading adversarial_reviews in the house style would have sailed
# straight through the check. (Found by adversarial review of this script before it landed.)
#
# So invert the test: EVERY backtick-qualified occurrence is a read UNLESS it sits in a write position.
# Failing open toward "this is a read" is the safe direction — a false positive is a one-line ALLOWLIST
# entry with a reason, a false negative is a silently wrong query. Bare quoted strings (bigquery/17,
# /18, /19 keep the table name in single-quoted watch lists) never match, because the pattern requires
# the backtick-qualified `project.dataset.table` form.
# The leading (?:^|[^A-Za-z0-9_]) anchor matters: without it, an identifier or phrase whose TAIL is a
# write keyword — e.g. `LAST_UPDATE \`...events.decision_log\`` — matches "UPDATE" and the reference is
# silently reclassified as a write and dropped from _read_positions, i.e. a false negative that hides a
# genuine raw read. No live occurrence today; found auditing this script 2026-08-06.
WRITE_POSITION = re.compile(
    r"(?:^|[^A-Za-z0-9_])"
    r"(?:INSERT\s+INTO"
    r"|ALTER\s+TABLE"
    r"|TRUNCATE\s+TABLE"
    r"|DELETE\s+FROM"
    r"|UPDATE"
    r"|MERGE(?:\s+INTO)?"
    r"|CREATE\s+(?:OR\s+REPLACE\s+)?"
    r"(?:TABLE\s+FUNCTION|MATERIALIZED\s+VIEW|VIEW|FUNCTION|PROCEDURE|TABLE)"
    r"(?:\s+IF\s+NOT\s+EXISTS)?"
    r")\s+$",
    re.IGNORECASE,
)


def _read_positions(body, table_fqn):
    """Offsets in `body` where `table_fqn` is referenced in a READ (non-write) position."""
    ref = re.compile(rf"`{re.escape(PROJECT)}\.{re.escape(table_fqn)}`")
    hits = []
    for m in ref.finditer(body):
        preceding = body[max(0, m.start() - 60):m.start()]
        if not WRITE_POSITION.search(preceding):
            hits.append(m.start())
    return hits


# (bigquery filename, "dataset.object") pairs whose canonical definition may legitimately read the raw
# table. Every entry needs a reason. Checked for ROT in both directions: an entry that no longer reads
# the raw table (or is no longer canonical) FAILS, so this list cannot quietly outlive its subjects.
ALLOWLIST = {
    ("143_adversarial_review_correction_path.sql", "state.adversarial_reviews_current"):
        "This view IS the anti-join — it must read the base table to define the filtered set.",
    ("143_adversarial_review_correction_path.sql", "ops.sp_score_cross_model_referee"):
        "Its outer duplicate-guard NOT EXISTS deliberately tests the RAW table: refusing to insert a "
        "second referee_gemini row when ANY referee row exists (superseded or not) is strictly more "
        "conservative than testing the current view, and this procedure must never double-write.",
    ("146_adversarial_review_writer_serialization.sql", "ops.sp_write_adversarial_review"):
        "Its correction branch must inspect the exact physical target named by p_superseded_by and "
        "prove every carried review field matches before appending. The current view intentionally "
        "hides that target, so it cannot validate correction identity or preserve immutable metadata.",
    # ---- events.decision_log (bigquery/144). Audited 2026-08-06; this population is genuinely
    # HETEROGENEOUS, unlike adversarial_reviews. Forcing these onto the filtered view would break a
    # dead-man's switch and a row-count parity check, so decision_log gets an allowlist rather than
    # adversarial_reviews' blanket rule.
    ("144_decision_log_correction_consumers.sql", "state.decision_log_current"):
        "This view IS the anti-join — it must read the base table to define the filtered set.",
    ("10_observability.sql", "state.freshness"):
        "DEAD-MAN'S SWITCH. MAX(entry_date) is a proxy for 'was this table written recently'. A "
        "correction append IS such a write, so a filtered read would report STALE on a day whose only "
        "write was a correction — turning a safety monitor into a false alarm.",
    ("02_ai_layer.sql", "state.embedding_health"):
        "ROW-COUNT PARITY. Compares decision_log's physical row count 1:1 against "
        "analytics.decision_embeddings. Both sides must count obsolete rows or the parity check "
        "desyncs permanently and reports a phantom embedding gap.",
    ("18_stack_review_fixes.sql", "state.embedding_scale_watch"):
        "CAPACITY ADVISORY. Tracks proximity to the 5,000-row VECTOR INDEX threshold; it needs the true "
        "physical row count BigQuery will actually scan, not the final-effective subset.",
    ("02_ai_layer.sql", "analytics.decision_embeddings"):
        "RAW SUBSTRATE. Every decision_log row is embedded, obsolete ones included; the anti-join "
        "correctly lives one layer up, inside analytics.find_precedents' candidate pool (bigquery/122). "
        "Filtering here would also desync state.embedding_health's 1:1 parity check above.",
    ("02_ai_layer.sql", "ops.sp_embed_pending"):
        "Materializes analytics.decision_embeddings — same raw-substrate reasoning as that table.",
    ("122_decision_correction_append_only.sql", "analytics.find_precedents"):
        "IS the anti-join, and correctly places it INSIDE the VECTOR_SEARCH candidate pool ahead of "
        "QUALIFY/LIMIT so a filtered-out row does not consume one of the ten returned slots.",
    ("122_decision_correction_append_only.sql", "state.research_screen_calls"):
        "Carries the correct anti-join inline (verified live 2026-08-06: correct direction, not the "
        "inverted form).",
    ("122_decision_correction_append_only.sql", "state.add_candidate_reviews"):
        "Carries the correct anti-join inline (verified live 2026-08-06: correct direction).",
    ("92_park_allocator.sql", "state.park_switch_budget"):
        "DEAD OBJECT — bigquery/108_park_allocator_immediate_binding.sql:84 DROPs this view live (the "
        "owner's immediate-binding redesign removed the budget/cooldown concept). 92's body is "
        "DR-rebuild history for an object that does not exist in BigQuery.",
    ("92_park_allocator.sql", "state.park_allocator_promotion_readiness"):
        "DEAD OBJECT — dropped live by bigquery/108:79, same redesign as park_switch_budget above.",

    # ---- FILE-LEVEL statements (outside any CREATE). Surfaced only after the 2026-08-06
    # _definition_segments fix; before that they were folded into the preceding object's body and
    # could ride on ITS reason. Every one below is an IDENTITY/EXISTENCE check on a specific physical
    # row, not an analytical read — the whole point is "does this exact row exist", which a
    # correction-filtered view cannot answer.
    ("36_strategy_arsenal_seed.sql", FILE_LEVEL):
        "One-time owner-directive seed guarded by IF NOT EXISTS on (entry_type, entry_date, title). It "
        "asks whether the seed row was already written, so it must see the physical row even if that "
        "row is later superseded — otherwise a re-apply would duplicate the directive.",
    ("55_park_policy_voo_seed.sql", FILE_LEVEL):
        "Same one-time owner-directive seed shape as bigquery/36 above.",
    ("101_market_only_decision_seed.sql", FILE_LEVEL):
        "Same one-time owner-directive seed shape as bigquery/36 above.",
    ("121_position_horizon_date_corrections.sql", FILE_LEVEL):
        "One-time migration whose ASSERTs check COUNT(*)=1 for specific literal entry_ids before "
        "mutating. A physical-row existence assertion; filtering it would make the guard lie.",
    ("133_sl1_research_leads_and_record_corrections.sql", FILE_LEVEL):
        "Its IF NOT EXISTS guards test `WHERE superseded_by = '<id>'` — i.e. whether a CORRECTION row "
        "has already landed. Only the raw table can answer that; the _current view deliberately hides "
        "the very relationship being probed.",
    ("143_adversarial_review_correction_path.sql", FILE_LEVEL):
        "The analytics.theater_judge cycle_number backfill UPDATE. It reconstructs which cycle the OLD, "
        "cycle-blind ops.sp_score_theater actually judged at each row's scored_ts — a historical "
        "reconstruction of what that procedure saw, which was the unfiltered table. (Inert either way "
        "today: 0 of 72 adversarial_reviews rows are superseded. Reviewed on its own merits here rather "
        "than inherited from the adjacent view's entry, which is exactly the bug this key class fixes.)",

    # ---- events.adversarial_reviews (bigquery/143).
    ("04_analytics.sql", "analytics.review_embeddings"):
        "Dead object. bigquery/04:19 records that no routine reads review_embeddings or "
        "theater_independence anymore (self-improvement audit 2026-07-15 confirmed zero live "
        "consumers); it is a one-shot materialized ML.GENERATE_EMBEDDING table retained under this "
        "repo's retain-don't-delete convention and is never re-run. Repointing it would re-bill Vertex "
        "AI embedding spend for an object nothing reads.",
}


# A free-standing statement at column 0. Used to find where an object's own CREATE statement ENDS.
# Column-0 anchored on purpose: inside a PROCEDURE body (and inside any CTE/MERGE) this repo always
# indents, so an indented `WHEN MATCHED THEN UPDATE SET` or a nested `INSERT` never matches.
STANDALONE_STMT = re.compile(
    r"^(?:ALTER|UPDATE|INSERT|DELETE|MERGE|CALL|DROP|TRUNCATE|GRANT|REVOKE)\b",
    re.IGNORECASE | re.MULTILINE,
)


def _definition_segments(text):
    """([(dataset, name, body)], [unowned_chunk]) for `text`.

    THE BUG THIS SHAPE EXISTS TO FIX (found auditing this script, 2026-08-06). The obvious
    implementation — body runs from one CREATE to the start of the NEXT CREATE — silently folds any
    free-standing DML sitting between two CREATEs into the PRECEDING object's body. That is not
    hypothetical: bigquery/143 has

        CREATE OR REPLACE VIEW state.adversarial_reviews_current AS ... ;
        ALTER TABLE analytics.theater_judge ADD COLUMN cycle_number INT64;
        UPDATE analytics.theater_judge T SET cycle_number = (SELECT ... FROM events.adversarial_reviews ...)
        CREATE OR REPLACE PROCEDURE ops.sp_score_theater() ...

    so that backfill UPDATE's TWO raw reads of a guarded table were attributed to
    state.adversarial_reviews_current and passed CHECK 1 solely because that FQN already carried an
    ALLOWLIST entry for an entirely unrelated reason ("this view IS the anti-join"). The statement's
    own reads were never reviewed on their merits — they got a free pass by text position. The
    checker's core promise ("every raw read is allowlisted WITH A REASON") did not actually hold.

    So: a VIEW/TABLE segment ends at the first column-0 standalone statement after its CREATE, and
    everything from there to the next CREATE is returned as UNOWNED, scanned separately, and must earn
    its own ALLOWLIST entry. PROCEDURE/FUNCTION segments are NOT truncated — their bodies legitimately
    contain DML between BEGIN and END (always indented in this repo, so column-0 anchoring already
    protects them, but the kind check makes it explicit rather than incidental).

    Text before the first CREATE is unowned too (file header, preamble ALTERs) — previously skipped
    entirely, now scanned.
    """
    matches = list(OBJECT_DDL.finditer(text))
    out = []
    unowned = []
    if matches:
        unowned.append(text[:matches[0].start()])
    else:
        unowned.append(text)
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        kind = re.sub(r"\s+", " ", m.group(1)).upper()
        chunk = text[m.start():end]
        if kind not in ("PROCEDURE", "FUNCTION", "TABLE FUNCTION"):
            # Look for a column-0 standalone statement AFTER this CREATE's own first line.
            after_create = chunk[m.end() - m.start():]
            cut = STANDALONE_STMT.search(after_create)
            if cut:
                split_at = (m.end() - m.start()) + cut.start()
                unowned.append(chunk[split_at:])
                chunk = chunk[:split_at]
        out.append((m.group(2), m.group(3), chunk))
    return out, unowned


def main():
    stripped_by_path = {}
    occurrences = {}  # "ds.name" -> [(number, filename, body)]

    unowned_by_file = {}  # filename -> concatenated text belonging to no object definition

    for number, path in numbered_sql_files(BIGQUERY_DIR):
        text = strip_sql_comments(read_text(path))
        stripped_by_path[path] = text
        segments, unowned = _definition_segments(text)
        for dataset, name, body in segments:
            occurrences.setdefault(f"{dataset}.{name}", []).append(
                (number, os.path.basename(path), body)
            )
        unowned_by_file[os.path.basename(path)] = "\n".join(unowned)

    violations = []
    inverted = []
    ambiguities = []
    used_allowlist = set()

    # Free-standing statements (ALTER/UPDATE/INSERT/... outside any CREATE). These used to be folded
    # into the preceding object's body and could ride on ITS allowlist reason; they now earn their own
    # entry, keyed on the pseudo-object "<file-level statements>". CHECK 2 applies here too — an
    # inverted predicate in a migration statement is just as wrong as one in a view.
    for filename, text in unowned_by_file.items():
        if not text.strip():
            continue
        if INVERTED_PREDICATE.search(text):
            inverted.append(
                f"{filename}: a file-level statement (outside any CREATE) filters on "
                f"`superseded_by IS NULL` — that is BACKWARDS"
            )
        for table_fqn, current_view in GUARDED_TABLES.items():
            if not _read_positions(text, table_fqn):
                continue
            key = (filename, FILE_LEVEL)
            if key in ALLOWLIST:
                used_allowlist.add(key)
                continue
            violations.append(
                f"{filename}: a file-level statement (outside any CREATE definition) reads "
                f"`{PROJECT}.{table_fqn}` directly — it must read `{PROJECT}.{current_view}`, or be "
                f"added to ALLOWLIST under {FILE_LEVEL!r} WITH A REASON"
            )

    for fqn, occs in occurrences.items():
        winner_number, winner_filenames = resolve_canonical(occs)
        if len(winner_filenames) > 1:
            ambiguities.append(
                f"{fqn}: file number {winner_number} maps to multiple filenames "
                f"({', '.join(winner_filenames)}) — cannot resolve a canonical definition"
            )
            continue
        canonical_fn = winner_filenames[0]
        body = next(b for n, fn, b in occs if n == winner_number and fn == canonical_fn)

        # CHECK 2 — no allowlist: this predicate is backwards for every table that has the convention.
        if INVERTED_PREDICATE.search(body):
            inverted.append(
                f"{canonical_fn}: canonical definition of {fqn} filters on `superseded_by IS NULL` — "
                f"that is BACKWARDS. It keeps the OBSOLETE row and drops the CORRECTION"
            )

        for table_fqn, current_view in GUARDED_TABLES.items():
            if not _read_positions(body, table_fqn):
                continue
            key = (canonical_fn, fqn)
            if key in ALLOWLIST:
                used_allowlist.add(key)
                continue
            violations.append(
                f"{canonical_fn}: canonical definition of {fqn} reads `{PROJECT}.{table_fqn}` "
                f"directly — it must read `{PROJECT}.{current_view}` so a superseded correction "
                f"target is excluded"
            )

    stale = sorted(set(ALLOWLIST) - used_allowlist)

    if ambiguities:
        print("superseded-by discipline check: AMBIGUOUS canonical resolution\n")
        for a in ambiguities:
            print(f"  ! {a}")
        print("\nFAIL — resolve the duplicate file number before this check can be trusted.")
        return 1

    if inverted:
        print(f"superseded-by discipline check: {len(inverted)} INVERTED predicate(s)\n")
        for v in inverted:
            print(f"  ✗ {v}")
        print(
            "\nFAIL — `superseded_by IS NULL` is never correct. The CORRECTION row is the one whose\n"
            "superseded_by is populated, so that filter keeps the row you meant to retire and drops the\n"
            "replacement. Exclude the NAMED TARGET instead:\n"
            "    entry_id NOT IN (SELECT superseded_by FROM <table> WHERE superseded_by IS NOT NULL)\n"
            "or just read the table's _current view. See bigquery/122's header."
        )
        return 1

    if violations:
        print(f"superseded-by discipline check: {len(violations)} violation(s)\n")
        for v in violations:
            print(f"  ✗ {v}")
        print(
            "\nFAIL — this reader would see BOTH a corrupted/obsolete row and its replacement.\n"
            "Repoint it at the table's _current view (bigquery/143 for adversarial_reviews,\n"
            "bigquery/144 for decision_log), or, if the raw read is genuinely correct (a row-count\n"
            "parity check, a freshness dead-man's switch, an embedding substrate), add it to ALLOWLIST\n"
            "in this script WITH A REASON."
        )
        return 1

    if stale:
        print("superseded-by discipline check: STALE ALLOWLIST\n")
        for fn, fqn in stale:
            print(f"  ✗ ({fn}, {fqn}) no longer reads the raw table, or is no longer canonical")
        print("\nFAIL — delete the stale entry/entries from ALLOWLIST so it cannot outlive its subject.")
        return 1

    print(
        f"OK: every canonical reader of {', '.join(GUARDED_TABLES)} goes through its _current view "
        f"({len(ALLOWLIST)} documented exception(s))."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

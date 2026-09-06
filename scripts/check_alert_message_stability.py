#!/usr/bin/env python3
"""PROTOTYPE check: every `ops.sp_raise_alert_once(...)` MESSAGE argument built with a
`STRING_AGG(...)` must render the SAME STRING for the SAME underlying set of rows — or `_once`'s
exact-string-equality dedup silently degenerates into a fresh unresolved alert row (and a fresh
email) on every run of an UNCHANGED condition.

THE DEFECT CLASS (measured twice in production; see bigquery/205_alert_message_stability.sql and
bigquery/227_alert_message_stability_ordering.sql for the sibling defect and the two live
incidents this guards against). `ops.sp_raise_alert_once` (bigquery/10_observability.sql) dedups
with exactly:

    IF NOT EXISTS (SELECT 1 FROM ops.alerts
                   WHERE NOT resolved AND category = in_category AND message = in_message)

KNOWN BLIND SPOT, DISCLOSED DELIBERATELY. This check isolates the MESSAGE ARGUMENT of each
`sp_raise_alert_once(...)` call and then looks for `STRING_AGG` inside it. A call that instead
assigns the aggregate to a VARIABLE first and interpolates the variable later is invisible to it:

    SET missing = (SELECT STRING_AGG(w.routine, ', ' ORDER BY w.routine) FROM ...);
    ... FORMAT('... %s ...', missing) ...

`ops.sp_assert_deps` (the `missing_dependency` CRITICAL, called by EVERY routine in the fleet, and
the single highest-traffic alert site there is) is built exactly that way. Its aggregate happens to
be a total order today, so nothing is wrong right now — but a future edit that made it unstable
would sail past this guard. Following the variable would mean tracing assignments across statements,
a substantially larger and more fragile parser than the token-span scan used here, and a fragile
guard that reports confidently is worse than a narrow one that states its limits. So: this check
covers the INLINE form only. Treat a green run as "no inline offender", NOT as "every alert message
in the fleet is stable".

EXACT STRING EQUALITY on (category, message) — the payload argument is never compared. So a
STRING_AGG(...) that helps build a message must render the SAME STRING for the SAME underlying
rows every time it is evaluated. It fails to when its ordering is not a TOTAL order over the
aggregated rows:
  * no ORDER BY at all -> element order is unspecified outright, or
  * ORDER BY <key> where the printed expression carries fields BEYOND <key> -> tied rows have no
    guaranteed relative order in BigQuery, so the identical open set can render as a different
    string on a later run.
When that happens, `_once` degenerates into a plain `sp_raise_alert`: an unchanged condition
raises a NEW unresolved alert row every run, each separately emailed.

WHAT THIS SCRIPT DOES.
1. Determines the FINAL-EFFECTIVE definition of every bigquery/*.sql object by reusing
   scripts/check_live_sql_parity.find_final_definitions() (imported, not reimplemented) — see
   that function's own docstring for why a naive whole-tree scan would flag intentionally-frozen
   SUPERSEDED definitions kept only as DR-rebuild history (bigquery/*.sql is apply-in-order and
   supersede-only; see bigquery/README.md / check_superseded_markers.py's header).
2. Within each final body, locates every `CALL ...sp_raise_alert_once(...)` and isolates its 4th
   positional argument (the message) via token/paren-depth-aware scanning
   (check_live_sql_parity.sql_tokens() — the same string-literal-and-comment-aware tokenizer that
   backs the live-sql-parity gate itself, reused rather than reimplemented so a second,
   independently-written scanner can never quietly drift from the first — see
   scripts/lib/sql_files.py's docstring for the repeated cost of exactly that kind of drift in
   this repo).
3. Inside the isolated message argument, finds every `STRING_AGG(<expr>, <sep> [ORDER BY <keys>]
   [LIMIT n])` and FLAGS it when there is no ORDER BY at all, or when the bare column identifiers
   referenced in <expr> are not a SUBSET of the identifiers referenced in <keys>.
4. A hardcoded ALLOWLIST (below) exempts sites already verified TOTAL by a uniqueness argument
   this static parser cannot see — a hardcoded UNNEST literal, or a base table written only
   through a MERGE keyed on the same column the message orders by. Modeled on
   scripts/check_superseded_markers.py's BASELINE pattern, including its ANTI-ROT behaviour: an
   allowlisted site that no longer trips the underlying check is reported as a FAILURE, so a
   fixed (or since-rewritten) site cannot silently keep its exemption forever.

WHY COMMENTS CANNOT FOOL THIS SCANNER (this repo has been bitten by exactly this trap before —
see feedback_refactor_traps_checkers_and_regex.md / scripts/lib/sql_files.py's strip_sql_comments()
history). Two independent reasons, not one:
  (a) find_final_definitions() extracts each object's body starting at its own `BEGIN` (procedure)
      or header `AS` (view/function) — never the file's top-of-file `--` comment block, which sits
      BEFORE the `CREATE` statement itself. bigquery/205's and bigquery/227's headers each quote an
      offending `STRING_AGG(... ORDER BY ...)` snippet in prose; neither is ever handed to this
      scanner, because neither is part of any object's extracted body in the first place.
  (b) Even a comment sitting INSIDE a body (between BEGIN and END) is invisible: sql_tokens()
      consumes `--` and `/* */` comments silently as part of tokenizing and never yields them, so a
      commented-out CALL or STRING_AGG snippet produces no tokens for this scanner to match at all.
See tests/test_check_alert_message_stability.py for a regression test pinning exactly this.

WHAT THIS SCRIPT DOES NOT DO. It does not detect a MOVING VALUE embedded directly in a message
(a run date, a row count, a dollar figure) — that is bigquery/205's defect class, already swept by
hand once and not re-checked here. It does not run any BigQuery query, and it makes no network
call: pure text/token parsing over files already in the repo, safe for the sandboxed `checks` CI
job. It is a PROTOTYPE: not wired into .github/workflows/ci.yml or the OPS0 adopt-gate coverage
list (scripts/check_adopt_gate_coverage.py) — see this script's own delivery notes for what wiring
either would require.

Usage:  python scripts/check_alert_message_stability.py   # exit 0 = OK; 1 = new finding or stale allowlist
"""
import sys

from check_live_sql_parity import find_final_definitions, sql_tokens

# NOTE: no ROOT/BIGQUERY_DIR constant here — find_final_definitions() takes no arguments and
# resolves bigquery/*.sql through check_live_sql_parity's OWN module-level BIGQUERY_DIR. Tests
# that need a synthetic tree monkeypatch find_final_definitions() itself (see
# tests/test_check_alert_message_stability.py) rather than that constant, precisely because a
# `from X import Y` binds this module's `find_final_definitions` name to a specific function
# object whose closure over BIGQUERY_DIR lives in check_live_sql_parity's namespace, not this
# one — monkeypatching a constant on the wrong module object is a silent no-op.

# ---------------------------------------------------------------------------------------------
# GoogleSQL keyword / bare-type stop-list. Deliberately GENEROUS (per this check's own design
# brief): a bare word here is never treated as a "column identifier" even where the "not
# immediately followed by (" rule alone would already exclude it (CONCAT, CAST, COALESCE, FORMAT,
# IF are all normally followed by "(" and so would be excluded anyway) -- listing them too is
# cheap, harmless redundancy against a future syntax variant (e.g. a bare type name used in a CAST
# target, which never has its own "(") slipping through as a fake "column".
#
# Sourced from: GoogleSQL's reserved-keyword list (ALL/AND/ANY/.../WITHIN -- see
# https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#reserved_keywords, quoted
# from memory and cross-checked against every keyword actually observed inside a
# `sp_raise_alert_once` message argument in this repo's own bigquery/*.sql tree) plus the scalar
# type names GoogleSQL allows as a bare CAST/table-function-signature target (STRING, INT64, ...).
# A false NEGATIVE here (a real column name that happens to collide with a keyword) would make an
# unstable site look stable -- the unsafe direction -- so keep this list generous rather than
# tight; see this file's own report for the fragility this implies.
_RESERVED_KEYWORDS = frozenset({
    "ALL", "AND", "ANY", "ARRAY", "AS", "ASC", "ASSERT_ROWS_MODIFIED", "AT", "BETWEEN", "BY",
    "CASE", "CAST", "COLLATE", "CONTAINS", "CREATE", "CROSS", "CUBE", "CURRENT", "DEFAULT",
    "DEFINE", "DESC", "DISTINCT", "ELSE", "END", "ENUM", "ESCAPE", "EXCEPT", "EXCLUDE", "EXISTS",
    "EXTRACT", "FALSE", "FETCH", "FOLLOWING", "FOR", "FROM", "FULL", "GROUP", "GROUPING",
    "GROUPS", "HASH", "HAVING", "IF", "IGNORE", "IN", "INNER", "INTERSECT", "INTERVAL", "INTO",
    "IS", "JOIN", "LATERAL", "LEFT", "LIKE", "LIMIT", "LOOKUP", "MERGE", "NATURAL", "NEW", "NO",
    "NOT", "NULL", "NULLS", "OF", "ON", "OR", "ORDER", "OUTER", "OVER", "PARTITION",
    "PRECEDING", "PROTO", "RANGE", "RECURSIVE", "RESPECT", "RIGHT", "ROLLUP", "ROWS", "SELECT",
    "SET", "SOME", "STRUCT", "TABLESAMPLE", "THEN", "TO", "TREAT", "TRUE", "UNBOUNDED", "UNION",
    "UNNEST", "USING", "WHEN", "WHERE", "WINDOW", "WITH", "WITHIN",
    # Bare scalar/complex type names (CAST(x AS <TYPE>), no trailing "(") -- not independently
    # reserved in GoogleSQL, but never a real column name in this repo's own bigquery/*.sql tree.
    "STRING", "INT64", "INTEGER", "FLOAT64", "FLOAT", "NUMERIC", "BIGNUMERIC", "BOOL", "BOOLEAN",
    "BYTES", "DATE", "DATETIME", "TIME", "TIMESTAMP", "JSON", "GEOGRAPHY",
    # Explicitly called out in this check's own design brief, kept even where already covered by
    # the "not followed by (" function-call rule above (belt-and-suspenders, see the paragraph
    # above this frozenset for why that redundancy is deliberate).
    "CONCAT", "COALESCE", "FORMAT",
})

TARGET_PROC = "SP_RAISE_ALERT_ONCE"

# 0-based positional argument indices in `sp_raise_alert_once(severity, source, category,
# message, payload)` — the signature is fixed in bigquery/10_observability.sql and every call
# site in the tree passes exactly 5 positional arguments (verified empirically: main() reports any
# call site with a different arg count as an ANOMALY rather than silently mis-indexing).
_CATEGORY_ARG_INDEX = 2
_MESSAGE_ARG_INDEX = 3
_EXPECTED_ARG_COUNT = 5


# ---------------------------------------------------------------------------------------------
# ALLOWLIST — sites verified TOTAL by a uniqueness argument this static parser cannot see. Every
# entry needs an inline reason. Checked for ROT in BOTH directions by main(): an entry that no
# longer trips the underlying check (fixed, rewritten, or no longer present) is reported as a
# FAILURE so the allowlist can never quietly outlive its subject (same discipline as
# scripts/check_superseded_markers.py's BASELINE and scripts/check_superseded_by_discipline.py's
# ALLOWLIST).
#
# Keyed on (dataset, name, category) — `category` (the CALL's own 3rd positional literal) is the
# stable human identity of a specific alert site, independent of which object currently defines
# it (a category can move file-to-file across a supersede without changing identity).
#
# EACH ENTRY WAS FOUND EMPIRICALLY by running this checker against the current tree and reading
# bigquery/227_alert_message_stability_ordering.sql's "DELIBERATELY NOT CHANGED" list for the
# uniqueness argument the parser itself cannot verify.
ALLOWLIST = {
    ("ops", "sp_sq_cadence_check", "period_missed"):
        "This site's message aggregates over state.cadence_period_watch (bigquery/24_cadence_"
        "period_watch.sql), which is built over a HARDCODED 20-element UNNEST literal naming "
        "every W/M/Q/A-cadence routine exactly ONCE (see bigquery/114's `-- BEGIN GENERATED "
        "ROUTINE LIST` block, kept in step by scripts/gen_routine_lists.py). ORDER BY routine is "
        "therefore already a total order — no two rows can ever tie on `routine` — even though "
        "the message also prints monitor_class and period_start, because those are FUNCTIONALLY "
        "DETERMINED by `routine` via the view's own CASE expression. Verified against the live "
        "view definition, 227's header.",
    ("ops", "sp_sq_cadence_check", "scheduled_query_version_drift"):
        "state.expected_scheduled_query_versions is a BASE TABLE written only through "
        "`MERGE ... ON T.sq_name = S.sq_name` (see bigquery/111), so `sq_name` structurally "
        "cannot repeat across rows -- ORDER BY sq_name is a total order regardless of what else "
        "the message prints. 227's header.",
    ("ops", "sp_sq_cadence_check", "scheduled_query_stale"):
        "Same registry as scheduled_query_version_drift directly above -- keyed on sq_name, a "
        "MERGE-upserted base table, structurally unique. 227's header.",
    ("ops", "sp_sq_cadence_check", "script_version_drift"):
        "state.script_version_drift's registry (script_name) is a BASE TABLE written only through "
        "a MERGE keyed on script_name (same shape as the sq_name registries above), so "
        "ORDER BY script_name is a total order. 227's header.",
    ("ops", "sp_sq_cadence_check", "ddl_drift"):
        "state.ddl_drift (bigquery/19_stack_review_fixes_2.sql) is a live diff of "
        "INFORMATION_SCHEMA.COLUMNS against bigquery/01_schema.sql; (table_name, column_name) is "
        "that view's actual uniqueness key -- an INFORMATION_SCHEMA row is one COLUMN of one "
        "TABLE, so the pair cannot repeat. `drift_reasons` (the field the message prints beyond "
        "the ORDER BY pair) is FUNCTIONALLY DETERMINED by that same (table_name, column_name) key, "
        "not an independent tie-breaker, so ties on the ORDER BY key are impossible and no printed "
        "field can ever land in a different order across ties that do not exist. 227's header "
        "names this site as verified-total but (unlike period_missed and the sq_name/script_name "
        "registries) does not spell out that drift_reasons is narrower than the ORDER BY -- this "
        "entry exists because this checker's subset rule cannot see the INFORMATION_SCHEMA "
        "uniqueness fact on its own and would otherwise flag it as a false positive.",
    # NOTE (2026-09-06): process_constant_evidence_invalidated USED to need an entry here.
    # bigquery/227 instead spells its ORDER BY as `routine, deadline_key, change_key,
    # old_value, new_value` -- a SUPERSET of every field the message prints -- so the site
    # now satisfies the subset rule on its own merits and needs no uniqueness argument
    # this parser cannot see. That is the preferred shape for any NEW site: widen the
    # ORDER BY until it covers what the message prints, rather than adding an exception.
}


def _skip_ws(tokens, i):
    """Index of the first token at or after `i` that is not whitespace (kind 'W'). May equal
    len(tokens) if none remains."""
    n = len(tokens)
    while i < n and tokens[i][0] == "W":
        i += 1
    return i


def _match_paren(tokens, open_i):
    """Index of the 'P' ')' token matching the 'P' '(' token at tokens[open_i], or None if the
    parens are unbalanced from that point on. Depth-aware: only counts 'P' tokens, so a "(" or ")"
    appearing inside a string literal ('S' token) or an identifier never affects the count --
    sql_tokens() already keeps those atomic."""
    assert tokens[open_i] == ("P", "(", tokens[open_i][2], tokens[open_i][3])
    depth = 1
    for j in range(open_i + 1, len(tokens)):
        kind, val = tokens[j][0], tokens[j][1]
        if kind == "P" and val == "(":
            depth += 1
        elif kind == "P" and val == ")":
            depth -= 1
            if depth == 0:
                return j
    return None


def _top_level_commas(tokens, open_i, close_i):
    """Indices of 'P' ',' tokens strictly between open_i and close_i whose paren depth relative
    to open_i is exactly 0 (i.e. immediately inside this pair, not inside a NESTED call's own
    parens) -- the argument separators for the call/function opened at open_i."""
    depth = 0
    commas = []
    for j in range(open_i + 1, close_i):
        kind, val = tokens[j][0], tokens[j][1]
        if kind == "P" and val == "(":
            depth += 1
        elif kind == "P" and val == ")":
            depth -= 1
        elif kind == "P" and val == "," and depth == 0:
            commas.append(j)
    return commas


def _split_args(tokens, open_i, close_i):
    """[(start, end), ...] token-index spans (half-open, excluding the separating commas and the
    enclosing parens themselves) for each top-level argument of the call/function opened at
    open_i and closed at close_i."""
    commas = _top_level_commas(tokens, open_i, close_i)
    bounds = [open_i, *commas, close_i]
    return [(bounds[k] + 1, bounds[k + 1]) for k in range(len(bounds) - 1)]


def _is_identifier_token(tokens, i):
    """True if tokens[i] is a 'T' token this check treats as a bare COLUMN identifier: not a
    keyword/type in the stop-list, not a pure-digit literal, and not immediately followed (or, for
    a dotted qualifier, immediately preceded) by something that means it is actually a function
    name or a table-alias qualifier rather than the column itself."""
    kind, val = tokens[i][0], tokens[i][1]
    if kind != "T":
        return False
    if val.upper() in _RESERVED_KEYWORDS:
        return False
    if val.isdigit():
        return False
    nxt = _skip_ws(tokens, i + 1)
    if nxt < len(tokens) and tokens[nxt][0] == "P" and tokens[nxt][1] in ("(", "."):
        # Followed by "(" -> this token is a FUNCTION NAME, not a column.
        # Followed by "." -> this token is a QUALIFIER (e.g. the "t" in "t.routine"); only the
        # final segment after the last "." is treated as the column identifier.
        return False
    return True


def _extract_identifiers(tokens, start, end):
    """{UPPERCASED identifier, ...} referenced as bare columns anywhere in tokens[start:end]."""
    return {tokens[i][1].upper() for i in range(start, end) if _is_identifier_token(tokens, i)}


def _find_top_level(tokens, start, end, words):
    """Index of the first token in tokens[start:end] whose upper() is words[0], where the
    immediately-following non-whitespace tokens continue to match words[1], words[2], ... in
    sequence -- restricted to paren-depth 0 relative to `start` (so an "ORDER BY" inside a nested
    function call's own arguments, e.g. a window function, is not mistaken for the STRING_AGG's
    own ORDER BY). Returns (match_start, index_just_past_last_word) or (None, None)."""
    depth = 0
    i = start
    while i < end:
        kind, val = tokens[i][0], tokens[i][1]
        if kind == "P" and val == "(":
            depth += 1
        elif kind == "P" and val == ")":
            depth -= 1
        elif depth == 0 and kind == "T" and val.upper() == words[0]:
            j = i
            ok = True
            for w in words[1:]:
                j = _skip_ws(tokens, j + 1)
                if j >= end or tokens[j][0] != "T" or tokens[j][1].upper() != w:
                    ok = False
                    break
            if ok:
                return i, j + 1
        i += 1
    return None, None


def _find_string_aggs(tokens, start, end):
    """[(expr_start, expr_end, order_start_or_None, order_end_or_None, whole_start, whole_end)]
    for every STRING_AGG(...) call in tokens[start:end]. The scan resumes right after each match's
    own closing paren (not before it), so a STRING_AGG nested inside another STRING_AGG's <expr>
    (not seen in this repo, but not ruled out) is still found on a later iteration of the same
    linear walk -- no actual recursion needed."""
    out = []
    i = start
    while i < end:
        kind, val = tokens[i][0], tokens[i][1]
        if kind == "T" and val.upper() == "STRING_AGG":
            open_i = _skip_ws(tokens, i + 1)
            if open_i < end and tokens[open_i] == ("P", "(", tokens[open_i][2], tokens[open_i][3]):
                close_i = _match_paren(tokens, open_i)
                if close_i is not None and close_i <= end:
                    order_start, after_order_by = _find_top_level(
                        tokens, open_i + 1, close_i, ["ORDER", "BY"])
                    if order_start is None:
                        expr_arg_end = close_i
                        keys_start = keys_end = None
                    else:
                        expr_arg_end = order_start
                        limit_start, _ = _find_top_level(
                            tokens, after_order_by, close_i, ["LIMIT"])
                        keys_start, keys_end = after_order_by, (
                            limit_start if limit_start is not None else close_i)
                    # <expr> is the FIRST top-level comma-separated argument before ORDER BY (or
                    # before the closing paren, if there is no ORDER BY at all) -- a second
                    # argument there, if present, is the delimiter and is not inspected: this
                    # check's rule is about the identifiers STRING_AGG PRINTS (its first argument),
                    # never about the fixed separator text between them.
                    pre_args = _split_args(tokens, open_i, expr_arg_end)
                    expr_start, expr_end = pre_args[0] if pre_args else (open_i + 1, expr_arg_end)
                    out.append((expr_start, expr_end, keys_start, keys_end, i, close_i + 1))
                    i = close_i
                    continue
        i += 1
    return out


def _find_alert_once_calls(tokens):
    """[(category_start, category_end, message_start, message_end, whole_start, whole_end,
    anomaly_or_None)] for every `sp_raise_alert_once(...)` invocation found in `tokens`.
    `anomaly_or_None` is a human-readable string when the call did not have exactly
    _EXPECTED_ARG_COUNT positional arguments (message/category spans are None in that case) --
    reported separately by main() rather than silently mis-indexing into a malformed call."""
    out = []
    i = 0
    n = len(tokens)
    while i < n:
        kind, val = tokens[i][0], tokens[i][1]
        if kind == "T" and val.upper() == TARGET_PROC:
            open_i = _skip_ws(tokens, i + 1)
            if open_i < n and tokens[open_i][0] == "P" and tokens[open_i][1] == "(":
                close_i = _match_paren(tokens, open_i)
                if close_i is not None:
                    args = _split_args(tokens, open_i, close_i)
                    if len(args) != _EXPECTED_ARG_COUNT:
                        out.append((None, None, None, None, i, close_i + 1,
                                    f"expected {_EXPECTED_ARG_COUNT} positional arguments, found "
                                    f"{len(args)}"))
                    else:
                        cs, ce = args[_CATEGORY_ARG_INDEX]
                        ms, me = args[_MESSAGE_ARG_INDEX]
                        out.append((cs, ce, ms, me, i, close_i + 1, None))
                    i = close_i
                    continue
        i += 1
    return out


def _literal_string_value(tokens, start, end):
    """The unquoted text of tokens[start:end] if it is EXACTLY one 'S' string-literal token
    (ignoring surrounding whitespace), else None. Used to recover the plain category name from a
    literal 3rd argument like 'period_missed' -- every call site in the tree passes a literal
    here, but a future dynamically-built category is handled gracefully (falls back to a
    positional label) rather than crashing."""
    idxs = [k for k in range(start, end) if tokens[k][0] != "W"]
    if len(idxs) != 1 or tokens[idxs[0]][0] != "S":
        return None
    raw = tokens[idxs[0]][1]
    quote = raw[0]
    if raw[:3] == quote * 3:
        return raw[3:-3]
    return raw[1:-1]


def find_sites():
    """[(dataset, name, category_or_label, ordered_flag, missing_keys)] for every message-argument
    STRING_AGG the RULE would flag (no ORDER BY, or expr identifiers not a subset of ORDER BY key
    identifiers), across every final-effective bigquery/*.sql object. Also returns a separate list
    of (dataset, name, anomaly) for any sp_raise_alert_once call whose argument count is not the
    expected 5 -- reported but not itself a stability finding."""
    findings = []
    anomalies = []
    for (dataset, name), (_obj_type, _project, _source_file, body) in find_final_definitions().items():
        tokens = list(sql_tokens(body))
        for cs, ce, ms, me, _ws, _we, anomaly in _find_alert_once_calls(tokens):
            if anomaly is not None:
                anomalies.append((dataset, name, anomaly))
                continue
            category = _literal_string_value(tokens, cs, ce) or "<non-literal category>"
            for expr_s, expr_e, keys_s, keys_e, _sws, _swe in _find_string_aggs(tokens, ms, me):
                expr_ids = _extract_identifiers(tokens, expr_s, expr_e)
                if keys_s is None:
                    findings.append((dataset, name, category, False, sorted(expr_ids)))
                    continue
                key_ids = _extract_identifiers(tokens, keys_s, keys_e)
                missing = sorted(expr_ids - key_ids)
                if missing:
                    findings.append((dataset, name, category, True, missing))
    return findings, anomalies


def main():
    findings, anomalies = find_sites()

    used_allowlist = set()
    new = []
    for dataset, name, category, ordered, missing in findings:
        key = (dataset, name, category)
        if key in ALLOWLIST:
            used_allowlist.add(key)
            continue
        new.append((dataset, name, category, ordered, missing))

    stale = sorted(set(ALLOWLIST) - used_allowlist)

    print(f"alert-message-stability check: {len(new)} new finding(s), {len(used_allowlist)} "
          f"allowlisted, {len(stale)} stale allowlist entry/entries, {len(anomalies)} call-site "
          f"anomal(y/ies).")

    if anomalies:
        print("\nCall sites with an unexpected argument count (not a stability finding on their "
              "own, but this checker cannot analyze their message argument):")
        for dataset, name, anomaly in sorted(anomalies):
            print(f"  ? {dataset}.{name}: {anomaly}")

    if new:
        print("\nFAIL — STRING_AGG in a sp_raise_alert_once message is not a TOTAL order over its "
              "rows, so an UNCHANGED condition can render a DIFFERENT string on a later run and "
              "defeat _once's exact-match dedup (see bigquery/227_alert_message_stability_"
              "ordering.sql):")
        for dataset, name, category, ordered, missing in sorted(new):
            if not ordered:
                print(f"  ✗ {dataset}.{name} [{category}]: STRING_AGG has NO ORDER BY at all")
            else:
                print(f"  ✗ {dataset}.{name} [{category}]: ORDER BY is narrower than the printed "
                      f"expression — missing {missing} from the ORDER BY key")
        print("\nFix: order by the WHOLE printed expression, or by a key PROVEN to uniquely "
              "identify the source rows (and add a reasoned ALLOWLIST entry in this script if so, "
              "modeled on the existing entries).")

    if stale:
        print("\nSTALE ALLOWLIST — these entries no longer trip the underlying check (fixed, "
              "rewritten, or no longer present). Delete them from ALLOWLIST in "
              "scripts/check_alert_message_stability.py so it cannot outlive its subject:")
        for dataset, name, category in stale:
            print(f"  - (\"{dataset}\", \"{name}\", \"{category}\")")

    if new or stale:
        return 1

    print(f"OK: every STRING_AGG feeding a sp_raise_alert_once message is a total order over its "
          f"rows ({len(ALLOWLIST)} documented exception(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

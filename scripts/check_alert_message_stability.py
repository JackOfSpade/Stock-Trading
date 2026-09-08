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
job. WIRING (this paragraph used to say "It is a PROTOTYPE: not wired into ci.yml or the OPS0
adopt-gate coverage list" — that went stale the day it landed and was corrected 2026-09-07): it IS
wired, as a BLOCKING step in .github/workflows/ci.yml's `checks` job and in
auto-merge-claude.yml's post-merge coverage mirror, and check_adopt_gate_coverage.py therefore
derives it into OPS0 STEP 4d precondition 5 automatically. A new pass added to this file needs no
further plumbing — which is exactly why the 2026-09-07 prose pass was added HERE rather than as a
second script.

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



# =============================================================================================
# PROSE PASS (added 2026-09-07) — sp_raise_alert_once call sites that live in TASK-PLAN PROSE.
#
# WHY A SECOND PASS EXISTS. Everything above this line parses `bigquery/*.sql`. But most of this
# fleet's alerts are not raised by SQL at all: they are raised by a ROUTINE — a memoryless Claude
# session that reads a template out of Claude_Task_Plan.md and composes the CALL at run time. That
# makes the prose templates the LEAST deterministic place a dedup key can live, and the one place
# neither bigquery/205 (moving values) nor bigquery/227 (STRING_AGG ordering) nor the SQL pass above
# can see. On 2026-09-07 a triage of two open W5 warnings found ELEVEN defective prose templates,
# including three whose message literal could not even parse (rule 4 below).
#
# THE RULE THIS ENFORCES. Every `<...>` placeholder appearing inside the MESSAGE argument of a prose
# `sp_raise_alert_once(...)` must be REGISTERED below with a one-line stability argument. This is a
# "declare your placeholders" gate rather than a semantic judgement: a static checker cannot know
# whether `<n>` is a stable cycle number or a drifting row count, but it CAN force whoever adds one
# to say which, and it can catch the free-form shapes (`<object + error>`) mechanically by their
# absence from the registry. ANTI-ROT, modeled on ALLOWLIST above and check_superseded_markers.py:
# a registered placeholder that no longer appears anywhere is reported as STALE and fails the run,
# so an entry cannot outlive its subject.
#
# IT ALSO ENFORCES RULE 4 (quote escaping), on BOTH `sp_raise_alert` and `sp_raise_alert_once`:
# GoogleSQL rejects `''` as an apostrophe escape ("concatenated string literals must be separated by
# whitespace or comments"), so a template carrying it does not raise a degraded alert — it raises
# NOTHING, and the condition it was watching goes unannounced. Three sites carried it on 2026-09-07.
#
# SCOPE. Claude_Task_Plan.md ONLY. task_plan/*.md are GENERATED from it by scripts/split_task_plan.py
# (CI enforces they are in sync via `--check`), so scanning both would double-report every finding.
# =============================================================================================

PROSE_SOURCE = "Claude_Task_Plan.md"

# placeholder -> why substituting it cannot change the rendered string for an UNCHANGED condition.
PROSE_PLACEHOLDERS = {
    "<strategy-codes>": "regime_restore_shortfall / strategy_funds_deficit: the strategy codes, pinned at "
                        "each site to DISTINCT, ASCENDING, comma-joined, no spaces. The SET is the identity.",
    "<source-values>": "cash_flow_source_unknown: the offending events.cash_flows source values, pinned to "
                       "DISTINCT, ASCENDING, comma-joined, no spaces.",
    "<guard-reasons>": "order_guard_block: the guard's reason codes, pinned to DISTINCT, ASCENDING, "
                       "comma-joined, no spaces.",
    "<affected_review>": "prompt_injection_attempt: the review artifact the attempt targeted. One open row "
                         "per affected review; the attacker text itself stays in the payload.",
    "<alert_id>": "spec_defect_notice_stalled (W5 SPEC-DEFECT NOTICE INTAKE escalation, 2026-09-08): the "
                  "underlying info-severity ops.alerts row's own alert_id -- an assigned identifier, stable "
                  "for the life of that row, never a count or a date. One open escalation row per stalled "
                  "alert_id.",
    "<the EXACT STABLE message below>": "regime_sweep_blocked / regime_restore_blocked / nomadic_sweep_blocked "
                                        "/ rerisking_limb_fired: a POINTER, not a substitution -- each site "
                                        "gives the full message as a verbatim literal immediately below with "
                                        "'use verbatim, with no interpolation'. Pinned by construction.",
    "<ticker + strategy-if-known + first-seen-in-connector date>":
        "position_reconciliation_lag: pinned to the FIRST-SEEN date (not today's) by the 2026-07-20 root-cause "
        "fix, precisely so it stays constant while the occurrence persists.",
    "<Connector>": "connector_reauth_needed: the connector's own name (BigQuery, Gmail, ...). One open row per connector.",
    "<as_of>": "catchup_refire_blocked: names WHICH scheduled slot was missed — part of the identity, not a measurement.",
    "<branch>": "stranded_branch: the git branch name. One open row per stranded branch.",
    "<dataset.object>": "live_sql_parity_*: the fully-qualified object name. One open row per object.",
    "<dataset-tables>": "backup_per_table_row_drop: affected tables, pinned to DISTINCT, ASCENDING, comma-joined, no spaces.",
    "<dropping file>": "live_sql_parity_missing_but_dropped: the bigquery/NN_*.sql filename that DROPs the object — a filename, constant for the condition.",
    "<entry_id>": "go_without_order: the id of the specific GO decision. One open row per stranded GO.",
    "<expected>": "upstream_marker_mismatch: the marker the current period expects — fixed for that period.",
    "<found>": "upstream_marker_mismatch: the marker actually present. It changes only if the upstream rewrites the file, which IS a different condition.",
    "<item_key>": "queue_item_stale / review_handoff_stuck: the queue item's own key.",
    "<item_type>": "queue_item_stale: the item's type, constant for that item.",
    "<n>": "review_handoff_stuck (AR_orc): the review CYCLE number. Cycle 3 is cycle 3 — an identifier of which cycle stuck, not a running count.",
    "<park vehicle>": "connector (D2a): the park ETF symbol. A symbol, not a measurement.",
    "<prevented|exit handed to D2>": "prefill_invalidation: a two-value enumerated alternation, both spellings fixed at the site.",
    "<probe symbol>": "connector (D2a): the probe ticker. A symbol, not a measurement.",
    "<queue>": "queue_item_stale: the queue's name.",
    "<review id>": "echo_suspect_exhausted / review_handoff_stuck: the review artifact's id.",
    "<review_type>": "echo_suspect_exhausted / review_handoff_stuck: the review class, constant for that review.",
    "<routine>": "several: the routine's own id (D1, OPS0, ...). Constant for the life of the condition.",
    "<run_date>": "unlanded_completed_run: names WHICH run failed to land — identity, not a measurement.",
    "<strategies>": "wash_sale_exposure: the strategies involved, pinned at the site to DISTINCT, ASCENDING, comma-joined, no spaces.",
    "<strategy>": "several: a single strategy code (A-E, PARK). Constant for the life of the condition.",
    "<ticker>": "several: the instrument symbol.",
    "<trigger_id>": "catchup_refire_blocked: the claude.ai trigger id, constant per routine.",
    "<upstream>": "upstream_marker_mismatch: the upstream routine's id.",
}

_PROSE_CALL_RE = __import__("re").compile(r"sp_raise_alert(_once)?\s*\(")


def _prose_call_args(text, open_paren):
    """Split one prose CALL's argument list. Returns (args, closed) where each arg is
    (raw_text, literal_value_or_None). Quote-aware: a `'` opens a literal, `\'` stays inside it,
    and a `)` inside a literal does not close the call."""
    args, buf, i = [], [], open_paren + 1
    in_str, depth = False, 0
    while i < len(text):
        ch = text[i]
        if in_str:
            if ch == "\\" and i + 1 < len(text):
                buf.append(text[i:i + 2]); i += 2; continue
            if ch == "'":
                in_str = False
            buf.append(ch); i += 1; continue
        if ch == "'":
            in_str = True; buf.append(ch); i += 1; continue
        if ch == "(":
            depth += 1; buf.append(ch); i += 1; continue
        if ch == ")":
            if depth == 0:
                args.append("".join(buf))
                return args, True
            depth -= 1; buf.append(ch); i += 1; continue
        if ch == "," and depth == 0:
            args.append("".join(buf)); buf = []; i += 1; continue
        if ch == "`" and depth == 0:
            # ran off the end of the markdown inline-code span without a closing paren
            return args + ["".join(buf)], False
        buf.append(ch); i += 1
    return args + ["".join(buf)], False


def _as_literal(raw):
    """The single-quoted string literal in `raw`, with \' unescaped, or None if it is not one."""
    s = raw.strip()
    if len(s) < 2 or not s.startswith("'") or not s.endswith("'"):
        return None
    return s[1:-1].replace("\\'", "'")


def find_prose_sites(text=None):
    """(unregistered, quote_defects, used, sql_built, anomalies) over Claude_Task_Plan.md's prose CALL
    sites. `text` overrides the file read -- used by the tests to drive a synthetic document, so the
    regression suite never depends on the live plan's current contents (which change most days)."""
    import os
    import re as _re
    if text is None:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        path = os.path.join(root, PROSE_SOURCE)
        text = open(path, encoding="utf-8").read()

    unregistered, quote_defects, used, sql_built, anomalies = [], [], set(), [], []
    for m in _PROSE_CALL_RE.finditer(text):
        is_once = m.group(1) is not None
        args, closed = _prose_call_args(text, m.end() - 1)
        if not closed or len(args) < 4:
            continue  # ran off the inline-code span: a narrative mention, not a template

        # A NARRATIVE MENTION elides arguments with an ellipsis ("sp_raise_alert_once('critical', …,
        # 'trading_halted', …)"). Those are prose ABOUT a call, not the call's own spec, and the real
        # template for that category lives elsewhere in this file. Skipping them is what keeps this
        # pass's output signal rather than noise -- 25 of the 29 sites on first run were these.
        if any(("\u2026" in a) or ("..." in a) for a in args):
            continue

        category = _as_literal(args[2]) or "<non-literal category>"

        # RULE 4 applies to BOTH sp_raise_alert and sp_raise_alert_once: an unparseable literal does
        # not raise a degraded alert, it raises nothing.
        for idx, raw in enumerate(args):
            lit = _as_literal(raw)
            if lit is not None and "''" in lit:
                quote_defects.append((category, idx, lit[:90]))

        if not is_once:
            continue

        raw_msg = args[3].strip()
        message = _as_literal(raw_msg)
        if message is None:
            # An UNQUOTED bare placeholder as the whole message ("<reasons joined>") is the free-form
            # shape rule 2 exists for -- hold it to the registry exactly as a quoted one.
            if _re.fullmatch(r"<[^<>]*>", raw_msg):
                message = raw_msg
            elif raw_msg.upper().startswith(("CONCAT(", "FORMAT(")):
                # DISCLOSED BLIND SPOT. The message is assembled by a SQL expression written inside
                # prose. Judging its stability needs the same value-level reasoning bigquery/205 did
                # by hand, which this static pass cannot do -- so these are LISTED, never silently
                # dropped, and never counted as pass.
                sql_built.append((category, raw_msg[:100]))
                continue
            else:
                anomalies.append((category, "message argument is neither a literal, a bare "
                                            "placeholder, nor a CONCAT/FORMAT expression"))
                continue

        for ph in _re.findall(r"<[^<>]*>", message):
            if ph in PROSE_PLACEHOLDERS:
                used.add(ph)
            else:
                unregistered.append((category, ph))
    return unregistered, quote_defects, used, sql_built, anomalies


def main():
    findings, anomalies = find_sites()
    prose_unregistered, prose_quote, prose_used, prose_sql_built, prose_anomalies = find_prose_sites()
    prose_stale = sorted(set(PROSE_PLACEHOLDERS) - prose_used)

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
    print(f"prose pass ({PROSE_SOURCE}): {len(prose_unregistered)} unregistered placeholder(s), "
          f"{len(prose_quote)} quote-escape defect(s), {len(prose_used)} registered placeholder(s) in "
          f"use, {len(prose_stale)} stale registry entry/entries, {len(prose_sql_built)} SQL-built "
          f"message(s) (not analyzable here), {len(prose_anomalies)} anomal(y/ies).")

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

    if prose_quote:
        print("\nFAIL — a prose alert message literal escapes an apostrophe as '' . GoogleSQL rejects "
              "that outright (\"concatenated string literals must be separated by whitespace or "
              "comments\"), so the CALL does not raise a degraded alert — it raises NOTHING, and the "
              "condition it watches goes unannounced:")
        for category, idx, snippet in sorted(prose_quote):
            print(f"  \u2717 [{category}] argument {idx}: {snippet!r}")
        print("\nFix: use \\' , or rewrite the sentence to avoid the apostrophe (preferred — one "
              "less character for a routine to transcribe wrongly).")

    if prose_unregistered:
        print("\nFAIL — a placeholder in a prose sp_raise_alert_once MESSAGE is not registered in "
              "PROSE_PLACEHOLDERS. The message is the dedup key and is rendered by a memoryless "
              "routine at run time, so an unpinned placeholder re-renders differently every run and "
              "_once degenerates into a fresh alert + email on an UNCHANGED condition:")
        for category, ph in sorted(set(prose_unregistered)):
            print(f"  \u2717 [{category}] {ph}")
        print("\nFix: substitute a NAMED field into the fixed sentence (never a free-form "
              "\"describe it\" placeholder), pin the rendering if it is multi-valued, and add the "
              "placeholder to PROSE_PLACEHOLDERS with its one-line stability argument.")

    if prose_sql_built:
        print("\nNOT COVERED (disclosed blind spot) — prose templates whose message is assembled by a "
              "CONCAT/FORMAT expression. Their stability has to be judged by reading the values they "
              "interpolate, which this static pass cannot do. Listed so they are never mistaken for "
              "checked:")
        for category, snippet in sorted(prose_sql_built):
            print(f"  ~ [{category}] {snippet}")

    if prose_anomalies:
        print("\nCall sites whose message argument this checker could not read as a literal:")
        for category, why in sorted(prose_anomalies):
            print(f"  ? [{category}]: {why}")

    if prose_stale:
        print("\nSTALE PROSE REGISTRY — these placeholders appear in no prose message any more. "
              "Delete them from PROSE_PLACEHOLDERS so an entry cannot outlive its subject:")
        for ph in prose_stale:
            print(f"  - {ph}")

    if new or stale or prose_unregistered or prose_quote or prose_stale:
        return 1

    print(f"OK: every STRING_AGG feeding a sp_raise_alert_once message is a total order over its "
          f"rows ({len(ALLOWLIST)} documented exception(s)), and every prose message placeholder is "
          f"registered ({len(PROSE_PLACEHOLDERS)} placeholder(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

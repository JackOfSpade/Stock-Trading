"""Split-aware TWR engine: real spec-lock on bigquery/82's SQL + property tests on a mirror
algorithm (test-gap fix, 2026-07-29; wiring-lock added 2026-07-30).

THE GAP THIS CLOSES. Before this fix, the file's docstring claimed "If someone re-derives the SQL
and breaks the invariant, this fails" but every test here only exercised a Python re-implementation
of the cum-split algorithm against ITSELF — bigquery/82_split_aware_engine.sql was never read. A
re-derivation of the live view that dropped the split factor entirely (reverting to bigquery/40's
original split-blind `shares * close`, the exact phantom -50%-return bug bigquery/82 exists to fix)
would have left every test in this file green. That is worse than no test: it advertised coverage
that did not exist.

THREE KINDS OF TEST NOW LIVE HERE:
  1. test_bigquery_82_* (presence) — reads bigquery/82_split_aware_engine.sql off disk and
     regex-asserts its two load-bearing constructs are present ANYWHERE in the file: the LN-domain
     running product (EXP(SUM(LN(split)) OVER (... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT
     ROW))) and its normalisation to 1.0 on the first held day (SAFE_DIVIDE(rp, FIRST_VALUE(rp)
     OVER (...))). The regexes tolerate whitespace/identifier-name reformatting (\\w+ for column
     names, \\s+ for layout) but require the exact algebraic shape. There is no offline BigQuery to
     execute the view against, so this is a structural (text-level) lock, not a behavioral one.
     LIMIT (why #3 below exists): presence alone does not prove the resulting `eff` factor is
     actually WIRED INTO the output. A re-derivation could leave `equity_runprod`/`eff` computed and
     textually in place (so both regexes still match) while the final projection reverts to raw
     `shares * close` / `shares * dividend` — the exact phantom -50%-return regression this file
     exists to prevent — and tests #1 alone would stay green.
  2. test_no_split_is_identity / test_two_for_one_split_is_continuous_not_minus_50pct /
     test_four_for_one_split_continuous — property tests of a hand-written Python mirror of the SAME
     algorithm (running product normalised to the first held day), proving the ALGORITHM is
     economically correct (a split keeps market value continuous, not a phantom ~-50% return). These
     do NOT read bigquery/82 and would stay green even if the live SQL diverged from this mirror —
     that is what #1/#3 are for.
  3. _projection_expr() / _is_split_wired() + test_bigquery_82_mv_and_div_cash_projections_are_
     actually_split_wired (wiring) — extracts the actual `mv`/`div_cash` projection expressions by
     alias (paren-aware, comment-stripped) and asserts they reference `eff` and `shares` as
     standalone identifiers. This is what catches the "computed but dropped before the output" shape
     that #1 cannot. test_projection_expr_* proves the helper itself is non-vacuous against synthetic
     good/bad SQL shapes (see that section below) — independent of whatever bigquery/82 currently
     contains.

No warehouse, no creds — runs in the always-on `test` job.
"""
import math
import os
import re

from lib.sql_files import strip_sql_comments

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIGQUERY_82 = os.path.join(ROOT, "bigquery", "82_split_aware_engine.sql")

# LN-domain running product of the per-day split_ratio, over the position's whole hold window
# (UNBOUNDED PRECEDING -> CURRENT ROW). This is the actual fix in bigquery/82: multiplying split
# ratios via EXP(SUM(LN(...))) rather than a plain running product avoids the numeric-overflow /
# rounding issues NUMERIC-domain PRODUCT-over-window would have (BigQuery has no windowed PRODUCT
# aggregate at all, hence the log-sum-exp trick). \w+ tolerates a column rename (day_split ->
# anything); \s+ tolerates reformatting. A re-derivation that reverts to split-blind shares*close
# (bigquery/40's original phantom -50%-return bug) or that computes the factor any other way fails
# this regex.
RUNNING_SPLIT_PRODUCT_RE = re.compile(
    r"EXP\(SUM\(LN\(\w+\)\)\s*OVER\s*\(\s*PARTITION\s+BY\s+\w+\s*ORDER\s+BY\s+\w+\s*"
    r"ROWS\s+BETWEEN\s+UNBOUNDED\s+PRECEDING\s+AND\s+CURRENT\s+ROW\s*\)\)",
    re.IGNORECASE,
)

# Normalisation of that running product to 1.0 on the first held day (SAFE_DIVIDE(rp,
# FIRST_VALUE(rp) OVER (PARTITION BY position ORDER BY date))) — this is what makes the multiplier
# an "effective shares SINCE ENTRY" factor rather than an absolute split-adjustment-since-inception
# factor, which would double-count any split that happened before the position was even opened.
NORMALIZE_TO_FIRST_HELD_DAY_RE = re.compile(
    r"SAFE_DIVIDE\(\s*\w+\s*,\s*FIRST_VALUE\(\w+\)\s*OVER\s*\(\s*PARTITION\s+BY\s+\w+\s*ORDER\s+BY\s+\w+\s*\)\)",
    re.IGNORECASE,
)


def _read_bigquery_82():
    # Single read site in this file — not worth the sys.path bootstrap just to pull in
    # lib.textio.read_text for one call (see scripts/lib/textio.py's own guidance).
    with open(BIGQUERY_82, encoding="utf-8") as f:
        return f.read()


def test_bigquery_82_uses_ln_domain_running_split_product():
    sql = _read_bigquery_82()
    assert RUNNING_SPLIT_PRODUCT_RE.search(sql), (
        "bigquery/82_split_aware_engine.sql no longer contains the EXP(SUM(LN(split)) OVER (... ROWS "
        "BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) running-product construct — the split-aware "
        "engine may have been re-derived to something split-blind (the bigquery/40 phantom-return bug "
        "this file exists to fix) or to a different, unverified algorithm."
    )


def test_bigquery_82_normalizes_split_factor_to_first_held_day():
    sql = _read_bigquery_82()
    assert NORMALIZE_TO_FIRST_HELD_DAY_RE.search(sql), (
        "bigquery/82_split_aware_engine.sql no longer normalises the running split product to the "
        "first held day (SAFE_DIVIDE(rp, FIRST_VALUE(rp) OVER (...))) — without this, a split that "
        "happened before a position's entry date would double-count into that position's effective "
        "share multiplier."
    )


# ---- wiring lock: does the `eff` factor actually reach the OUTPUT projection? (module docstring #3,
# 2026-07-30 gap-close) --------------------------------------------------------------------------
#
# RUNNING_SPLIT_PRODUCT_RE / NORMALIZE_TO_FIRST_HELD_DAY_RE above only prove the split-factor CTEs
# exist somewhere in the file. A re-derivation could leave `equity_runprod`/`eff` computed and
# textually in place (both regexes still match) while `equity_held`'s final SELECT reverts to raw
# `shares * close` / `shares * dividend` — the exact bigquery/40 phantom -50%-return bug this file
# exists to fix — and the two tests above would stay green. `_projection_expr` extracts the actual
# expression text feeding a given output alias so the assertion below can check WIRING, not presence.

def _is_word_char(ch):
    """True if `ch` (a single character, or "") counts as a "word" character for `\\b`-style
    boundary purposes — alnum or underscore. Used to hand-check a SELECT-keyword boundary while
    walking `_projection_expr`'s backward scan char-by-char (a plain `\\bSELECT\\b` regex can't be
    applied mid-walk since we don't yet know where the substring starts until we're standing on it)."""
    return ch.isalnum() or ch == "_"


def _projection_expr(sql, alias):
    """Return the SQL expression text immediately preceding `AS <alias>` in `sql` (the first such
    occurrence), or None if no `AS <alias>` is found.

    Runs `strip_sql_comments()` (scripts/lib/sql_files.py — position-preserving, verified 116/116
    files length/newline-safe) over `sql` FIRST, so a `--`/`/* */` comment that happens to mention
    the alias's expected identifiers (e.g. `shares * close /* times eff */ AS mv`) can never leak
    into the extracted expression and falsely satisfy a wiring check.

    Walks BACKWARD from `AS <alias>` tracking paren depth, and stops at the nearest comma or SELECT
    keyword that sits at the SAME paren depth as the alias itself — not just the nearest comma. This
    matters because the real `mv` expression contains commas INSIDE a function call
    (`IF(mark_date = exit_date, exit_price, close)`); a naive backward scan to the nearest `,` would
    wrongly stop inside that call and return a truncated (and wrong) expression. `AS` is matched
    case-insensititively with `\\s+` between it and the alias, so arbitrary whitespace/newlines and
    `as`/`As`/`AS` all resolve the same way.
    """
    stripped = strip_sql_comments(sql)
    m = re.search(r"\bAS\s+" + re.escape(alias) + r"\b", stripped, re.IGNORECASE)
    if m is None:
        return None
    as_start = m.start()
    depth = 0
    i = as_start - 1
    boundary = 0  # fallback: start of the (stripped) text, if nothing bounds the expression earlier
    while i >= 0:
        c = stripped[i]
        if c == ")":
            depth += 1
        elif c == "(":
            depth -= 1
            if depth < 0:
                # walked past an unmatched '(' relative to the alias — that open paren belongs to an
                # ENCLOSING expression (e.g. a subquery's own '('), not ours; stop just after it.
                boundary = i + 1
                break
        elif depth == 0:
            if c == ",":
                boundary = i + 1
                break
            if stripped[i:i + 6].upper() == "SELECT":
                before = stripped[i - 1] if i > 0 else ""
                after = stripped[i + 6] if i + 6 < len(stripped) else ""
                if not _is_word_char(before) and not _is_word_char(after):
                    boundary = i + 6
                    break
        i -= 1
    return stripped[boundary:as_start].strip()


def _is_split_wired(expr):
    """True iff `expr` references both `eff` and `shares` as STANDALONE identifiers (word-boundary
    matched: `\\beff\\b` does NOT match inside `eff_split_since_entry` or `effective`, since `_` and
    alnum chars are both "word" chars for `\\b` purposes — a substring match would let those false-
    positive). None (alias not found) is treated as not-wired."""
    if expr is None:
        return False
    return bool(
        re.search(r"\beff\b", expr, re.IGNORECASE) and re.search(r"\bshares\b", expr, re.IGNORECASE)
    )


def test_bigquery_82_mv_and_div_cash_projections_are_actually_split_wired():
    """THE wiring spec-lock. Presence tests above only prove the eff/rp CTEs exist SOMEWHERE in the
    file; this proves the resulting `eff` factor is actually WIRED INTO the output projection, not
    computed and then silently dropped on the way to `mv`/`div_cash`."""
    sql = _read_bigquery_82()
    mv_expr = _projection_expr(sql, "mv")
    div_expr = _projection_expr(sql, "div_cash")
    assert mv_expr is not None, "no `AS mv` projection found in bigquery/82_split_aware_engine.sql"
    assert div_expr is not None, (
        "no `AS div_cash` projection found in bigquery/82_split_aware_engine.sql"
    )
    # Pin the exact extracted text too (not just the wiring bool) so a change to the shape of these
    # two expressions specifically is visible in a failing assertion diff, not just a bare False.
    assert mv_expr == "shares * eff * IF(mark_date = exit_date, exit_price, close)", mv_expr
    assert div_expr == "shares * eff * dividend", div_expr
    assert _is_split_wired(mv_expr), (
        f"bigquery/82's `mv` projection ({mv_expr!r}) no longer references both `eff` and `shares` — "
        "the split factor may have been computed but dropped before reaching the output (the exact "
        "phantom -50%-return regression this file exists to prevent)."
    )
    assert _is_split_wired(div_expr), (
        f"bigquery/82's `div_cash` projection ({div_expr!r}) no longer references both `eff` and "
        "`shares` — same regression class as `mv` above, on the dividend leg."
    )


# ---- non-vacuity proof: synthetic SQL fed straight to the helper above, no file mutation needed ----
# (proves the wiring lock would actually catch the regression it claims to catch, permanently — not
# just against today's bigquery/82 text)

def test_projection_expr_good_mv_shape_passes_wiring_check():
    sql = "SELECT other, shares * eff * close AS mv FROM t"
    expr = _projection_expr(sql, "mv")
    assert expr == "shares * eff * close"
    assert _is_split_wired(expr)


def test_projection_expr_regression_shape_mv_drops_eff_and_fails_wiring_check():
    # THE regression this whole test file exists to catch: eff/rp CTEs could stay textually present
    # elsewhere in the file (satisfying RUNNING_SPLIT_PRODUCT_RE/NORMALIZE_TO_FIRST_HELD_DAY_RE) while
    # the final `mv` projection reverts to split-blind `shares * close`.
    sql = "SELECT other, shares * close AS mv FROM t"
    expr = _projection_expr(sql, "mv")
    assert expr == "shares * close"
    assert not _is_split_wired(expr)


def test_projection_expr_good_div_cash_shape_passes_wiring_check():
    sql = "SELECT other, shares * eff * dividend AS div_cash FROM t"
    expr = _projection_expr(sql, "div_cash")
    assert expr == "shares * eff * dividend"
    assert _is_split_wired(expr)


def test_projection_expr_regression_shape_div_cash_drops_eff_and_fails_wiring_check():
    sql = "SELECT other, shares * dividend AS div_cash FROM t"
    expr = _projection_expr(sql, "div_cash")
    assert expr == "shares * dividend"
    assert not _is_split_wired(expr)


def test_projection_expr_reordered_mv_is_not_order_brittle():
    # `eff` before `shares` (real file has `shares * eff * ...`) must pass just the same — the check
    # is presence-of-both-identifiers, not a fixed operand order.
    sql = "SELECT other, eff * shares * close AS mv FROM t"
    expr = _projection_expr(sql, "mv")
    assert _is_split_wired(expr)


def test_projection_expr_comment_only_eff_mention_fails_wiring_check():
    # Proves comment-stripping is load-bearing: `eff` appears ONLY inside a /* ... */ comment, never
    # in real code reaching `mv`. Without stripping first, a naive text search for "eff" would wrongly
    # pass this.
    sql = "SELECT other, shares * close /* times eff */ AS mv FROM t"
    expr = _projection_expr(sql, "mv")
    assert "eff" not in expr
    assert not _is_split_wired(expr)


def test_projection_expr_multi_comma_real_shape_paren_aware_walk_passes():
    # Proves the paren-aware backward walk: the REAL `mv` expression contains commas INSIDE an
    # IF(...) call (`IF(mark_date = exit_date, exit_price, close)`) that a naive `[^,]*`-style
    # backward scan to the nearest comma would wrongly treat as the projection-list separator,
    # truncating the extracted expression (and, in the real file, losing `eff` entirely since it sits
    # to the left of the truncation point).
    sql = "SELECT multiplier, shares * eff * IF(a = b, c, d) AS mv, next_col AS other"
    expr = _projection_expr(sql, "mv")
    assert expr == "shares * eff * IF(a = b, c, d)"
    assert _is_split_wired(expr)


# ---- brittleness check: innocuous edits must NOT break the new checks (design item 5) --------------

def test_projection_expr_tolerates_extra_whitespace():
    sql = "SELECT x,    shares   *   eff   *   close     AS     mv   FROM t"
    assert _is_split_wired(_projection_expr(sql, "mv"))


def test_projection_expr_tolerates_line_break_mid_expression():
    sql = "SELECT x,\n  shares * eff *\n    close AS mv\nFROM t"
    assert _is_split_wired(_projection_expr(sql, "mv"))


def test_projection_expr_tolerates_as_case_variants():
    for as_spelling in ("as", "As", "aS", "AS"):
        sql = f"SELECT x, shares * eff * close {as_spelling} mv FROM t"
        assert _is_split_wired(_projection_expr(sql, "mv")), as_spelling


def test_projection_expr_tolerates_trailing_comment_after_projection():
    sql = "SELECT x, shares * eff * close AS mv -- ok\n, y AS z"
    assert _is_split_wired(_projection_expr(sql, "mv"))


def test_projection_expr_tolerates_inline_block_comment_mid_expression():
    # The EXISTING RUNNING_SPLIT_PRODUCT_RE (module-level, above) is NOT comment-aware: inserting a
    # /* ... */ comment mid-construct breaks its match (confirmed: matching it against
    # 'EXP(SUM(LN(day_split)) OVER (PARTITION BY position_key /* note */ ORDER BY mark_date ROWS
    # BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))' returns no match, vs a match with the comment
    # removed) — a prior reviewer flagged exactly this brittleness. That regex is left unchanged here
    # (it locks a different property and this task does not touch it), but THIS helper strips comments
    # first via strip_sql_comments(), so the same class of innocuous mid-expression comment does NOT
    # break the wiring check.
    sql = "SELECT x, shares * eff /* note */ * close AS mv FROM t"
    assert _is_split_wired(_projection_expr(sql, "mv"))


# ---- property tests on a Python mirror of the same algorithm (see module docstring #2) -----------

def eff_split_since_entry(day_splits):
    """Mirror of bigquery/82's equity leg: given the ordered per-day split_ratio values over a
    position's hold window (1.0 on a non-split day, e.g. 2.0 on a 2:1 split day), return the
    per-day effective-share multiplier = running product normalised to the first held day."""
    run, first = [], None
    acc = 0.0  # sum of ln(split), i.e. ln(running product)
    for s in day_splits:
        acc += math.log(s)
        rp = math.exp(acc)
        if first is None:
            first = rp
        run.append(rp / first)
    return run


def mv_series(shares, entry_price, closes, day_splits):
    """Interior-day market value per day = shares * eff_split * close (the engine's `mv`)."""
    eff = eff_split_since_entry(day_splits)
    # eff has one entry per day_splits item; closes is the same per-day series (mirrors bigquery/82's
    # per-day join) — a length mismatch would be a fixture bug, so catch it rather than truncate silently.
    return [shares * e * c for e, c in zip(eff, closes, strict=True)]


def daily_returns(mvs):
    return [mvs[i] / mvs[i - 1] - 1 for i in range(1, len(mvs))]


def test_no_split_is_identity():
    # constant split_ratio=1 -> effective shares never change; returns follow raw close moves.
    closes = [100.0, 101.0, 99.0, 103.0]
    mvs = mv_series(10, 100.0, closes, [1.0] * 4)
    assert mvs == [1000.0, 1010.0, 990.0, 1030.0]
    rets = daily_returns(mvs)
    assert math.isclose(rets[0], 0.01, abs_tol=1e-12)


def test_two_for_one_split_is_continuous_not_minus_50pct():
    # Day 3 is a 2:1 split: the ingested close halves (102 -> 51) AND split_ratio=2.0.
    # A split-BLIND engine (shares*close) would read 10*51/ (10*102) - 1 = -50% and fire drawdown_kill.
    # The split-AWARE engine doubles effective shares that day, so market value is continuous.
    closes = [100.0, 102.0, 51.0, 52.0]
    splits = [1.0, 1.0, 2.0, 1.0]
    mvs = mv_series(10, 100.0, closes, splits)
    rets = daily_returns(mvs)
    # split day return is the true economic move (51*2 vs 102 == flat), NOT -50%.
    assert math.isclose(rets[1], 0.0, abs_tol=1e-9), f"split day should be ~flat, got {rets[1]}"
    assert rets[1] > -0.5 + 1e-6
    # post-split day tracks the real +1/51 move on the doubled share base.
    assert math.isclose(rets[2], 52.0 / 51.0 - 1.0, abs_tol=1e-9)


def test_four_for_one_split_continuous():
    closes = [200.0, 210.0, 52.5, 53.0]  # day 3 = 4:1 split (210 -> 52.5)
    splits = [1.0, 1.0, 4.0, 1.0]
    rets = daily_returns(mv_series(4, 200.0, closes, splits))
    assert math.isclose(rets[1], 0.0, abs_tol=1e-9)

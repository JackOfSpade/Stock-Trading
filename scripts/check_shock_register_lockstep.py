#!/usr/bin/env python3
"""Assert Strategy.md's Shock Transmission Register table agrees with the SQL seed rows, row for row.

WHY THIS EXISTS. Rev 50 (owner directive 2026-10-19) made the `shock_overlay = acute` reconciliation
rule bind BY DEFAULT and let a per-strategy register exempt a strategy whose mechanism the shock is not
transmitted into. The register lives in TWO places:

  * Strategy.md `## Regime router` -> "**Shock Transmission Register (Rev 50, ...)**" — the markdown
    table, which is the canonical SPEC;
  * bigquery/257_shock_transmission_register.sql (or any later re-registration file) — the seed rows of
    `ops.shock_transmission_register`, which `state.shock_transmission_status` evaluates into the one
    boolean M1b step 2 actually reads, `override_applies`.

The two drift in individually silent ways. A class or exempt flag changed in the prose only means the
runtime keeps applying (or keeps waiving) the acute override exactly as before, while every reader of
Strategy.md believes otherwise. A gate threshold changed in the SQL only is a criteria change made
under no revision at all — precisely the "criteria drift under loss pressure" the judgment-native
machinery requirements forbid. Both files say a row is changed "in both or in neither"; this script is
what makes that sentence true.

WHAT IS COMPARED, per strategy code: transmission class (exact), exempt flag (table yes/no vs SQL
TRUE/FALSE), median-correlation gate, share-at->=0.80 gate (table percent such as `60%` -> 0.60),
max measurement age, horizon class. A dash in the table means NULL in the SQL. The table's Basis column
and the SQL `note` field are prose and are NOT compared.

A MISSING ANCHOR IS A FAILURE. If the table header or the INSERT ... FROM UNNEST([...]) block cannot be
found, or either yields zero rows, this exits 1 — never a vacuous pass where an empty set compares equal
to another empty set.

The SQL file is RESOLVED, not hardcoded: the highest-numbered bigquery/NNN_*.sql containing the
register INSERT wins, so a later re-registration file supersedes 257 automatically (the same
apply-in-order rule scripts/check_roster_notice_lockstep.py uses for sp_auto_resolve_alerts).

Exit 0 and one summary line on agreement; exit 1 with file:line diagnostics otherwise. Stdlib only.
"""
import os
import re
import sys
from decimal import Decimal, InvalidOperation

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STRATEGY_MD = "Strategy.md"
INSERT_ANCHOR = "INSERT INTO `stock-trading-498512.ops.shock_transmission_register`"

TABLE_HEADER = [
    "Strategy",
    "Transmission class",
    "Exempt by class",
    "Gate: median 60d pair correlation re-binds at ≥",
    "Gate: share of pairs with 60d correlation ≥ 0.80 re-binds at ≥",
    "Gate: max measurement age (days)",
    "Horizon class (limb b)",
    "Basis",
]

# SQL STRUCT field order (the first STRUCT's `AS` aliases must match this, if present).
SQL_FIELDS = [
    "strategy_code",
    "transmission_class",
    "exempt_by_class",
    "gate_median_60d_max",
    "gate_share_ge_080_max",
    "gate_max_age_days",
    "horizon_class",
    "note",
]

# Compared columns: (sql field name, table header label, kind)
COMPARED = [
    ("transmission_class", TABLE_HEADER[1], "str"),
    ("exempt_by_class", TABLE_HEADER[2], "bool"),
    ("gate_median_60d_max", TABLE_HEADER[3], "num"),
    ("gate_share_ge_080_max", TABLE_HEADER[4], "num"),
    ("gate_max_age_days", TABLE_HEADER[5], "int"),
    ("horizon_class", TABLE_HEADER[6], "str"),
]

TOLERANCE = Decimal("1e-9")
DASHES = {"—", "–", "-"}  # noqa: RUF001 -- the table writes an em/en dash for "no gate"; both are accepted


class CheckError(Exception):
    """A located failure: carries a file:line-prefixed message."""


# ---------------------------------------------------------------- markdown table ----------------

def _clean_cell(cell):
    """Strip whitespace and surrounding markdown bold/italic/code markers from a table cell."""
    s = cell.strip()
    prev = None
    while s != prev:
        prev = s
        for marker in ("**", "__", "*", "_", "`"):
            if len(s) >= 2 * len(marker) and s.startswith(marker) and s.endswith(marker):
                s = s[len(marker):-len(marker)].strip()
    return s


def _split_row(line):
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [_clean_cell(c) for c in s.split("|")]


def _parse_table_value(raw, kind, where, code, label):
    if kind == "str":
        if not raw or raw in DASHES:
            raise CheckError(f"{where}: strategy {code} column '{label}': empty value")
        return raw
    if kind == "bool":
        low = raw.lower()
        if low == "yes":
            return True
        if low == "no":
            return False
        raise CheckError(f"{where}: strategy {code} column '{label}': expected yes/no, got {raw!r}")
    if raw in DASHES:
        return None
    if kind == "num":
        txt = raw.replace(" ", "")
        pct = txt.endswith("%")
        if pct:
            txt = txt[:-1]
        try:
            val = Decimal(txt)
        except InvalidOperation:
            raise CheckError(f"{where}: strategy {code} column '{label}': not a number or dash: {raw!r}") from None
        return val / 100 if pct else val
    if kind == "int":
        if not re.fullmatch(r"\d+", raw):
            raise CheckError(f"{where}: strategy {code} column '{label}': expected an integer or dash, got {raw!r}")
        return int(raw)
    raise AssertionError(kind)


def parse_table(text, rel=STRATEGY_MD):
    """Return {code: (line_no, {field: value})} from the register table. Raises CheckError."""
    lines = text.splitlines()
    header_idx = None
    for i, line in enumerate(lines):
        if line.lstrip().startswith("|") and _split_row(line) == TABLE_HEADER:
            header_idx = i
            break
    if header_idx is None:
        raise CheckError(
            f"{rel}:1: MISSING ANCHOR — could not find the Shock Transmission Register table header "
            f"(| {' | '.join(TABLE_HEADER)} |). Fix the anchor rather than letting this guard pass vacuously.")
    sep_idx = header_idx + 1
    if sep_idx >= len(lines) or not re.fullmatch(r"\s*\|?(\s*:?-+:?\s*\|)+\s*:?-*:?\s*", lines[sep_idx]):
        raise CheckError(f"{rel}:{sep_idx + 1}: Shock Transmission Register header is not followed by a |---| separator row")
    rows = {}
    errors = []
    for i in range(sep_idx + 1, len(lines)):
        line = lines[i]
        if not line.lstrip().startswith("|"):
            break
        lineno = i + 1
        where = f"{rel}:{lineno}"
        cells = _split_row(line)
        if len(cells) < len(TABLE_HEADER):
            errors.append(f"{where}: register row has {len(cells)} cells, expected {len(TABLE_HEADER)}")
            continue
        code = cells[0]
        if not code:
            errors.append(f"{where}: register row has an empty Strategy cell")
            continue
        if code in rows:
            errors.append(f"{where}: duplicate strategy code {code} in the Strategy.md register table "
                          f"(first at {rel}:{rows[code][0]})")
            continue
        vals = {}
        try:
            for idx, (field, label, kind) in enumerate(COMPARED, start=1):
                vals[field] = _parse_table_value(cells[idx], kind, where, code, label)
        except CheckError as e:
            errors.append(str(e))
            continue
        rows[code] = (lineno, vals)
    if errors:
        raise CheckError("\n".join(errors))
    if not rows:
        raise CheckError(f"{rel}:{header_idx + 1}: the Shock Transmission Register table has ZERO rows")
    return rows


# ---------------------------------------------------------------- SQL seed ----------------------

def _line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def _skip_string(text, i):
    """text[i] is a quote; return the index just past the closing quote (handles '' and backslash)."""
    q = text[i]
    j = i + 1
    n = len(text)
    while j < n:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == q:
            if j + 1 < n and text[j + 1] == q:
                j += 2
                continue
            return j + 1
        j += 1
    raise ValueError(f"unterminated string literal starting at line {_line_of(text, i)}")


def _scan_close(text, i, end=None):
    """i is just past an opening ( or [. Return the index of the matching close, string/comment aware."""
    depth = 0
    n = len(text) if end is None else end
    while i < n:
        c = text[i]
        if c in "'\"":
            i = _skip_string(text, i)
            continue
        if c == "-" and text.startswith("--", i):
            nl = text.find("\n", i)
            i = n if nl == -1 else nl
            continue
        if c in "([":
            depth += 1
        elif c in ")]":
            if depth == 0:
                return i
            depth -= 1
        i += 1
    raise ValueError("unbalanced brackets")


def _split_args(text, start, end):
    """Split text[start:end] on top-level commas; return [(abs_start, arg_text)]."""
    args = []
    depth = 0
    i = start
    seg = start
    while i < end:
        c = text[i]
        if c in "'\"":
            i = _skip_string(text, i)
            continue
        if c in "([":
            depth += 1
        elif c in ")]":
            depth -= 1
        elif c == "," and depth == 0:
            args.append((seg, text[seg:i]))
            seg = i + 1
        i += 1
    args.append((seg, text[seg:end]))
    return args


_ALIAS_RE = re.compile(r"^(.*?)\s+AS\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", re.DOTALL | re.IGNORECASE)


def _strip_alias(arg):
    s = arg.strip()
    # Only strip a trailing alias that follows a complete value (ends in a quote, digit, word or paren).
    # `CAST(NULL AS NUMERIC)` alone never matches (it ends in ')'); with an alias the regex
    # backtracks to the complete CAST(...) expression.
    m = _ALIAS_RE.match(s)
    if m:
        return m.group(1).strip(), m.group(2)
    return s, None


def _parse_sql_value(s):
    if re.fullmatch(r"(?i)NULL", s) or re.fullmatch(r"(?is)CAST\s*\(\s*NULL\s+AS\s+\w+\s*\)", s):
        return None
    if re.fullmatch(r"(?i)TRUE", s):
        return True
    if re.fullmatch(r"(?i)FALSE", s):
        return False
    m = re.fullmatch(r"(?is)(?:NUMERIC|BIGNUMERIC|DECIMAL)\s*'([^']*)'", s)
    if m:
        try:
            return Decimal(m.group(1).strip())
        except InvalidOperation:
            raise ValueError(f"bad NUMERIC literal {s!r}") from None
    if re.fullmatch(r"-?\d+", s):
        return int(s)
    if re.fullmatch(r"-?\d+\.\d*|-?\.\d+", s):
        return Decimal(s)
    if len(s) >= 2 and s[0] in "'\"" and s[-1] == s[0]:
        if _skip_string(s, 0) != len(s):
            raise ValueError(f"adjacent string literals are not supported: {s!r}")
        q = s[0]
        inner = s[1:-1].replace(q + q, q)
        return re.sub(r"\\(.)", r"\1", inner)
    raise ValueError(f"unrecognised SQL value {s!r}")


def parse_sql(text, rel):
    """Return {code: (line_no, {field: value})} from the register INSERT's UNNEST block."""
    a = text.find(INSERT_ANCHOR)
    if a == -1:
        raise CheckError(f"{rel}:1: MISSING ANCHOR — no `{INSERT_ANCHOR}` statement")
    m = re.compile(r"FROM\s+UNNEST\s*\(\s*\[", re.IGNORECASE).search(text, a)
    if not m:
        raise CheckError(f"{rel}:{_line_of(text, a)}: MISSING ANCHOR — register INSERT has no FROM UNNEST([ ... ]) block")
    body_start = m.end()
    try:
        body_end = _scan_close(text, body_start)
    except ValueError as e:
        raise CheckError(f"{rel}:{_line_of(text, body_start)}: cannot parse the UNNEST block — {e}") from e
    rows = {}
    errors = []
    i = body_start
    struct_re = re.compile(r"STRUCT\s*\(", re.IGNORECASE)
    first = True
    while True:
        while i < body_end and (text[i].isspace() or text[i] == ","):
            i += 1
        if i < body_end and text.startswith("--", i):
            nl = text.find("\n", i)
            i = body_end if nl == -1 or nl > body_end else nl
            continue
        if i >= body_end:
            break
        sm = struct_re.match(text, i)
        if not sm:
            raise CheckError(f"{rel}:{_line_of(text, i)}: unexpected text in the UNNEST block (expected STRUCT(...))")
        lineno = _line_of(text, i)
        where = f"{rel}:{lineno}"
        try:
            close = _scan_close(text, sm.end(), body_end)
            args = _split_args(text, sm.end(), close)
        except ValueError as e:
            raise CheckError(f"{where}: cannot parse STRUCT — {e}") from e
        i = close + 1
        if len(args) != len(SQL_FIELDS):
            errors.append(f"{where}: STRUCT has {len(args)} fields, expected {len(SQL_FIELDS)} ({', '.join(SQL_FIELDS)})")
            first = False
            continue
        vals = {}
        try:
            for idx, (_, arg) in enumerate(args):
                value_txt, alias = _strip_alias(arg)
                if alias is not None and alias != SQL_FIELDS[idx]:
                    raise ValueError(f"field {idx + 1} is aliased {alias!r}, expected {SQL_FIELDS[idx]!r}")
                if first and alias is None:
                    raise ValueError(f"first STRUCT field {idx + 1} has no `AS {SQL_FIELDS[idx]}` alias")
                vals[SQL_FIELDS[idx]] = _parse_sql_value(value_txt)
        except ValueError as e:
            errors.append(f"{where}: {e}")
            first = False
            continue
        first = False
        code = vals["strategy_code"]
        if not isinstance(code, str) or not code:
            errors.append(f"{where}: STRUCT strategy_code is not a non-empty string literal")
            continue
        bad = []
        for field, _label, kind in COMPARED:
            v = vals[field]
            if kind == "str" and not isinstance(v, str):
                bad.append(f"{field} must be a string literal")
            elif kind == "bool" and not isinstance(v, bool):
                bad.append(f"{field} must be TRUE/FALSE")
            elif kind == "num":
                if isinstance(v, bool) or not (v is None or isinstance(v, (Decimal, int))):
                    bad.append(f"{field} must be NUMERIC or NULL")
                elif isinstance(v, int):
                    vals[field] = Decimal(v)
            elif kind == "int" and (isinstance(v, bool) or not (v is None or isinstance(v, int))):
                bad.append(f"{field} must be an integer or NULL")
        if bad:
            errors.append(f"{where}: strategy {code}: " + "; ".join(bad))
            continue
        if code in rows:
            errors.append(f"{where}: duplicate strategy code {code} in the SQL seed (first at {rel}:{rows[code][0]})")
            continue
        rows[code] = (lineno, vals)
    if errors:
        raise CheckError("\n".join(errors))
    if not rows:
        raise CheckError(f"{rel}:{_line_of(text, body_start)}: the register UNNEST block has ZERO STRUCT rows")
    return rows


def resolve_sql():
    """(relpath, text) of the highest-numbered bigquery/NNN_*.sql containing the register INSERT."""
    bq = os.path.join(REPO, "bigquery")
    best = None
    if os.path.isdir(bq):
        for fn in sorted(os.listdir(bq)):
            m = re.match(r"^(\d+)_.*\.sql$", fn)
            if not m:
                continue
            with open(os.path.join(bq, fn), encoding="utf-8") as f:
                text = f.read()
            if INSERT_ANCHOR in text:
                key = (int(m.group(1)), fn)
                if best is None or key > best[0]:
                    best = (key, fn, text)
    if best is None:
        raise CheckError(f"bigquery/:1: MISSING ANCHOR — no bigquery/NNN_*.sql contains `{INSERT_ANCHOR}`")
    return f"bigquery/{best[1]}", best[2]


# ---------------------------------------------------------------- comparison --------------------

def _fmt(v):
    if v is None:
        return "NULL/—"
    if isinstance(v, bool):
        return "TRUE/yes" if v else "FALSE/no"
    return str(v)


def _equal(a, b, kind):
    if a is None or b is None:
        return a is None and b is None
    if kind == "num":
        return abs(Decimal(a) - Decimal(b)) <= TOLERANCE
    return a == b


def compare(table_rows, sql_rows, md_rel, sql_rel):
    errors = []
    for code in sorted(set(table_rows) | set(sql_rows)):
        if code not in sql_rows:
            errors.append(f"{md_rel}:{table_rows[code][0]}: strategy {code} present in {md_rel} but MISSING from the SQL seed ({sql_rel})")
            continue
        if code not in table_rows:
            errors.append(f"{sql_rel}:{sql_rows[code][0]}: strategy {code} present in the SQL seed but MISSING from the {md_rel} register table")
            continue
        t_line, t_vals = table_rows[code]
        s_line, s_vals = sql_rows[code]
        for field, label, kind in COMPARED:
            if not _equal(t_vals[field], s_vals[field], kind):
                errors.append(
                    f"{md_rel}:{t_line}: strategy {code} column '{label}' ({field}) MISMATCH — "
                    f"table {_fmt(t_vals[field])} vs {sql_rel}:{s_line} {_fmt(s_vals[field])}")
    return errors


def main():
    try:
        sql_rel, sql_text = resolve_sql()
        with open(os.path.join(REPO, STRATEGY_MD), encoding="utf-8") as f:
            md_text = f.read()
    except (CheckError, OSError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    failures = []
    table_rows = sql_rows = None
    try:
        table_rows = parse_table(md_text, STRATEGY_MD)
    except CheckError as e:
        failures.append(str(e))
    try:
        sql_rows = parse_sql(sql_text, sql_rel)
    except CheckError as e:
        failures.append(str(e))
    if table_rows is not None and sql_rows is not None:
        failures.extend(compare(table_rows, sql_rows, STRATEGY_MD, sql_rel))
    if failures:
        for block in failures:
            for line in block.splitlines():
                print(f"ERROR: {line}", file=sys.stderr)
        print("\n  Strategy.md's Shock Transmission Register is the spec; the SQL seed is its runtime mirror.\n"
              "  Change a row in BOTH places or in neither.", file=sys.stderr)
        return 1
    print(f"SHOCK-REGISTER LOCKSTEP: OK — {STRATEGY_MD} register table and {sql_rel} seed agree on "
          f"{len(table_rows)} rows: {', '.join(sorted(table_rows))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

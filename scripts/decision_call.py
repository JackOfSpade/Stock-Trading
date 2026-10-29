#!/usr/bin/env python3
"""Generate a digest-checked `ops.sp_log_decision_checked` CALL (bigquery/270) from a saved JSON file.
Standard library only; it writes to BigQuery nothing -- the routine issues the generated SQL itself.

WHY THIS EXISTS. The BigQuery MCP tool takes SQL text, never a file, so a decision_log row is copied
token by token by whichever agent issues the CALL. On 2026-10-28 D1's issuing sub-agent re-typed the
~50KB single-name research-screen CALL and landed two transcription defects (a fanout date and a
dropped legend key) in row 72e9607d; nothing caught it in-write, because ops.sp_log_decision checks
nothing and stores `SAFE.PARSE_JSON(in_fields_json)`, so a dropped brace would even land `fields` NULL
without an error. D1 found it by an improvised per-key readback and replaced it append-only
(c8a50e56; ops.alerts `decision_log_large_call_retyped_in_transit`). So, as in scripts/paper_book.py:

  * the CALL carries the SHA-256 of every argument as this script rendered it, and
    ops.sp_log_decision_checked recomputes it from what BigQuery received and REFUSES the write on a
    mismatch, so a damaged call writes nothing and is simply re-issued;
  * the emitted SQL is printable ASCII (non-ASCII written as \\uXXXX escapes), so a copy that "tidies" a
    curly quote or a non-breaking space cannot fail the same call on every retry;
  * the procedure appends tag 'sha256:<digest>' to the row and is idempotent on it: a re-issue after a
    lost response returns the existing entry_id instead of a duplicate;
  * every string literal is wrapped into pieces of at most WRAP characters on their own lines
    (GoogleSQL concatenates adjacent literals), so no line of call.sql is too long for an issuing agent
    to read whole -- a ~50KB single-line fields literal can only be re-assembled from fragments, which
    is the re-typing this exists to remove;
  * readback.sql is short and carries no payload, so it can be re-typed safely.

Digest: lowercase hex SHA-256 of the 16 arguments, in the procedure's order, joined by U+001F. A STRING,
DATE or NUMERIC argument is 'N' when NULL, else 'S' + its rendering (a DATE as YYYY-MM-DD, a NUMERIC as
BigQuery's CAST(... AS STRING), e.g. 75, 0.5, 100). An ARRAY argument is 'A' followed by its elements,
each rendered as above, joined by U+001E (NULL or empty array: just 'A').

Input JSON keys (the procedure's argument names without `in_`): entry_date, entry_type, title and
source_session are required; strategy, ticker, decision, conviction, conviction_pct, sub_pattern,
theater_check, body_md, fields, refs, tags, superseded_by are optional. `fields` is an object (serialised
here, compactly, with non-ASCII kept) or an already-serialised string. Any other key is an error.

Usage (<S> is a scratch directory outside the repository):
  python3 scripts/decision_call.py <S>/decision.json --out <S>/decision
writes <S>/decision/call.sql (issue it verbatim; it returns entry_id, outcome, sha256) and
<S>/decision/readback.sql (lists the landed row by date and digest tag; empty = not written). Exits 2, writing
nothing, on any invalid input.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import date
from decimal import Decimal, InvalidOperation

PROJECT = "stock-trading-498512"
PROC = f"`{PROJECT}.ops.sp_log_decision_checked`"
TABLE = f"`{PROJECT}.events.decision_log`"
FIELD_SEP = "\x1f"
ELEM_SEP = "\x1e"

# The procedure's argument order. Changing it, or any rendering below, moves every digest.
ARGS = [
    ("entry_date", "date"), ("entry_type", "str"), ("strategy", "str"), ("ticker", "str"),
    ("decision", "str"), ("conviction", "str"), ("conviction_pct", "numeric"),
    ("sub_pattern", "str"), ("theater_check", "str"), ("title", "str"), ("body_md", "str"),
    ("fields", "json"), ("refs", "array"), ("tags", "array"), ("superseded_by", "str"),
    ("source_session", "str"),
]
REQUIRED = {"entry_date", "entry_type", "title", "source_session"}
NUMERIC_SCALE = 9  # BigQuery NUMERIC keeps 9 decimals; a rounded value could never match its digest
NUMERIC_INT_DIGITS = 29
WRAP = 400  # max characters of one literal piece per line of call.sql


class InputError(ValueError):
    pass


def sql_str(value: str, wrap: int | None = None, indent: str = "") -> str:
    """A GoogleSQL quoted literal whose value is exactly `value`, written in printable ASCII only.

    With `wrap`, the literal is split into adjacent quoted pieces of at most `wrap` characters, one per
    line; an escape sequence is never split across pieces.
    """
    out = []
    for ch in value:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == "'":
            out.append("\\'")
        elif 0x20 <= o < 0x7F:
            out.append(ch)
        elif o <= 0xFFFF:
            out.append("\\u%04x" % o)
        else:
            out.append("\\U%08x" % o)
    if not wrap:
        return "'" + "".join(out) + "'"
    pieces, cur, n = [], [], 0
    for tok in out:
        if cur and n + len(tok) > wrap:
            pieces.append("'" + "".join(cur) + "'")
            cur, n = [], 0
        cur.append(tok)
        n += len(tok)
    pieces.append("'" + "".join(cur) + "'")
    return ("\n" + indent).join(pieces)


def _check_text(key: str, value: str) -> str:
    try:
        value.encode("utf-8")
    except UnicodeEncodeError:
        raise InputError(f"{key} is not valid Unicode (lone surrogate)") from None
    return value


def render_numeric(key: str, value) -> str:
    """BigQuery's CAST(NUMERIC AS STRING): no exponent, no trailing zeros, no trailing point."""
    if isinstance(value, bool) or not isinstance(value, (int, float, str)):
        raise InputError(f"{key} must be a number")
    try:
        d = Decimal(str(value))
    except InvalidOperation:
        raise InputError(f"{key} is not a number: {value!r}") from None
    if not d.is_finite():
        raise InputError(f"{key} is not finite")
    if d.as_tuple().exponent < -NUMERIC_SCALE:
        raise InputError(f"{key} has more than {NUMERIC_SCALE} decimals; BigQuery NUMERIC would round it")
    if d == 0:
        return "0"
    s = format(d.normalize(), "f")
    if len(s.lstrip("-").split(".")[0]) > NUMERIC_INT_DIGITS:
        raise InputError(f"{key} is out of NUMERIC range")
    return s


def normalise(raw: dict) -> dict:
    """Validate the input and return {arg: python value or None}, every string exactly as it will be sent."""
    if not isinstance(raw, dict):
        raise InputError("input must be a JSON object")
    known = {k for k, _ in ARGS}
    unknown = sorted(set(raw) - known)
    if unknown:
        raise InputError(f"unknown key(s): {', '.join(unknown)}")
    out = {}
    for key, kind in ARGS:
        value = raw.get(key)
        if value is None:
            if key in REQUIRED:
                raise InputError(f"{key} is required")
            out[key] = None
            continue
        if kind == "date":
            if not isinstance(value, str):
                raise InputError(f"{key} must be YYYY-MM-DD")
            try:
                out[key] = date.fromisoformat(value).isoformat()
            except ValueError:
                raise InputError(f"{key} must be YYYY-MM-DD") from None
            if out[key] != value:
                raise InputError(f"{key} must be YYYY-MM-DD")
        elif kind == "str":
            if not isinstance(value, str):
                raise InputError(f"{key} must be a string")
            if key in REQUIRED and not value.strip():
                raise InputError(f"{key} is blank")
            out[key] = _check_text(key, value)
        elif kind == "numeric":
            out[key] = render_numeric(key, value)
        elif kind == "json":
            if isinstance(value, str):
                try:
                    parsed = json.loads(value)
                except ValueError as e:
                    raise InputError(f"{key} is not valid JSON: {e}") from None
                text = value
            else:
                parsed = value
                try:
                    text = json.dumps(value, ensure_ascii=False, separators=(",", ":"), allow_nan=False)
                except ValueError as e:
                    raise InputError(f"{key}: {e}") from None
            if not isinstance(parsed, dict):
                raise InputError(f"{key} must be a JSON object")
            out[key] = _check_text(key, text)
        elif kind == "array":
            if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
                raise InputError(f"{key} must be a list of strings")
            out[key] = [_check_text(key, v) for v in value]
    return out


def digest(args: dict) -> str:
    parts = []
    for key, kind in ARGS:
        value = args[key]
        if kind == "array":
            parts.append("A" + ELEM_SEP.join("S" + v for v in (value or [])))
        else:
            parts.append("N" if value is None else "S" + value)
    return hashlib.sha256(FIELD_SEP.join(parts).encode("utf-8")).hexdigest()


def sql_value(kind: str, value) -> str:
    if kind == "array":
        return "CAST([" + ", ".join(sql_str(v) for v in (value or [])) + "] AS ARRAY<STRING>)"
    if value is None:
        return {"date": "CAST(NULL AS DATE)", "numeric": "CAST(NULL AS NUMERIC)"}.get(kind, "CAST(NULL AS STRING)")
    if kind == "date":
        return f"DATE '{value}'"
    if kind == "numeric":
        return f"NUMERIC '{value}'"
    return sql_str(value, WRAP, "  ")


def call_sql(args: dict) -> str:
    sha = digest(args)
    lines = [f"  {sql_value(kind, args[key])},  -- in_{key}" for key, kind in ARGS]
    lines.append(f"  '{sha}'  -- in_expected_sha256")
    return f"CALL {PROC}(\n" + "\n".join(lines) + "\n);\n"


def readback_sql(args: dict) -> str:
    return (
        "SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,\n"
        "  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes\n"
        f"FROM {TABLE}\n"
        f"WHERE entry_date = DATE '{args['entry_date']}'\n"
        f"  AND 'sha256:{digest(args)}' IN UNNEST(tags)\n"
        "ORDER BY event_ts;\n"
    )


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("input", help="JSON file of sp_log_decision arguments")
    p.add_argument("--out", required=True, help="output directory for call.sql and readback.sql")
    a = p.parse_args(argv)
    try:
        with open(a.input, encoding="utf-8") as f:
            raw = json.load(f)
        args = normalise(raw)
    except (OSError, ValueError) as e:
        print(f"decision_call: {e}", file=sys.stderr)
        return 2
    call = call_sql(args)
    assert re.fullmatch(r"[\x20-\x7e\n]*", call), "emitted SQL must be printable ASCII"
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "call.sql"), "w", encoding="ascii") as f:
        f.write(call)
    with open(os.path.join(a.out, "readback.sql"), "w", encoding="ascii") as f:
        f.write(readback_sql(args))
    print(f"call.sql {len(call)} bytes, sha256 {digest(args)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

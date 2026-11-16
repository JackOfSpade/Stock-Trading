"""The ONE GoogleSQL string-literal renderer for generated BigQuery calls.

scripts/decision_call.py and scripts/paper_book.py each carried a byte-identical copy of this escaper
loop. Both feed digest-checked procedures (the SQL side recomputes a digest over the decoded value and
refuses a mismatch), so the two renderings must never drift: a fix to one copy alone would make the
other tool's calls decode to a different value than it hashed. One copy here (2026-11-16).
"""


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

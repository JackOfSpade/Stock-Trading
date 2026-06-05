#!/usr/bin/env python3
"""Parse Regime_State.md → regime_events.jsonl.

Two scopes emitted:
  scope='TECHNICAL_SIGNAL'   one row per indicator (SPY_Trend, VIX, YC, Sustained_Inversion, Breadth)
  scope='STRATEGY_ACTIVATION' one row per strategy (A..E + router) carrying current state + theater-check

Activation State Change History pipe-table is also emitted as STRATEGY_ACTIVATION events
backdated to the change date so the latest-wins state view picks up the most-recent row.
"""
import re, json, pathlib
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Regime_State.md"
OUT = ROOT / "bigquery" / "out"

def first(rx, s, flags=0, group=1):
    if not s: return None
    m = re.search(rx, s, flags)
    return m.group(group) if m else None

def section(text, header_rx):
    m = re.search(header_rx, text, re.MULTILINE)
    if not m: return None
    end = re.search(r'^(?:##|---)\s', text[m.end():], re.MULTILINE)
    return text[m.end():m.end() + (end.start() if end else len(text))]

def parse_last_updated(text):
    m = re.search(r'\*\*Last updated:\*\*\s+(\d{4}-\d{2}-\d{2})', text)
    return m.group(1) if m else "2026-06-03"

def parse_technical(text, as_of):
    """Pull the bolded indicator state lines from the Current Technical Signal States table."""
    sec = section(text, r'^##\s+Current Technical Signal States\b')
    if not sec: return []
    rows = []
    for label, key in [
        ("SPY Trend State", "SPY_TREND"),
        ("VIX close", "VIX_REGIME"),
        ("Yield Curve State", "YIELD_CURVE"),
        ("Yield Curve Sustained Inversion Flag", "SUSTAINED_INVERSION"),
        ("Equity Breadth State", "EQUITY_BREADTH"),
    ]:
        # capture the **bold state** at end of the row
        rx = re.compile(rf'\|\s*\*?\*?{re.escape(label)}\*?\*?\s*\|[^|]*\|\s*\*\*([A-Z\-]+)\*\*\s*\|')
        m = rx.search(sec)
        if m:
            rows.append({
                "as_of_date": as_of, "scope": "TECHNICAL_SIGNAL",
                "key": key, "value": m.group(1), "numeric_value": None,
                "divergence_id": None, "theater_check": None,
                "rationale": label, "source_review_ref": "Regime_State.md",
            })
    return rows

def parse_strategy_blocks(text, as_of):
    sec = section(text, r'^##\s+Current Per-Strategy Activation States\b')
    if not sec: return []
    out = []
    blocks = re.split(r'^###\s+Strategy\s+([A-E])\b[^\n]*\n', sec, flags=re.MULTILINE)
    for i in range(1, len(blocks), 2):
        strat, body = blocks[i], blocks[i + 1]
        state = first(r'\*\*Current activation state:\*\*\s*([A-Z\- ]+?)(?:$|\n)', body)
        tc = first(r'\*\*Theater-check flag[^:]*:\*\*\s*(CONVERGENT|DIVERGENT|MIXED)', body)
        div_id = first(r'`(div-[A-E]-\d{6}-\d+)`', body)
        out.append({
            "as_of_date": as_of, "scope": "STRATEGY_ACTIVATION",
            "key": strat, "value": (state or "").strip(),
            "numeric_value": None,
            "divergence_id": div_id, "theater_check": tc,
            "rationale": first(r'\*\*Fundamental signal[^:]*:\*\*\s*([^\n]+)', body),
            "source_review_ref": "Regime_State.md",
        })
    return out

def parse_history(text):
    """Activation State Change History pipe-table — each row is a backdated event."""
    sec = section(text, r'^##\s+Activation State Change History\b')
    if not sec: return []
    rows = []
    for m in re.finditer(
        r'^\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*([A-E]|router)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|\n]+?)\s*\|',
        sec, re.MULTILINE):
        date, strat, prior, new_state, trigger, review = (g.strip() for g in m.groups())
        rows.append({
            "as_of_date": date, "scope": "STRATEGY_ACTIVATION",
            "key": strat, "value": new_state,
            "numeric_value": None,
            "divergence_id": first(r'(div-[A-E]-\d{6}-\d+)', trigger + " " + review),
            "theater_check": None,
            "rationale": f"{trigger} (prior: {prior})",
            "source_review_ref": review,
        })
    return rows

def main():
    text = SRC.read_text(encoding="utf-8")
    as_of = parse_last_updated(text)
    rows = parse_technical(text, as_of) + parse_history(text) + parse_strategy_blocks(text, as_of)
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "regime_events.jsonl", "w") as f:
        for r in rows: f.write(json.dumps(r) + "\n")
    print(f"regime_events: {len(rows)}")
    print("  by scope:    ", dict(Counter(r['scope'] for r in rows)))
    print("  STRATEGY rows by key:", dict(Counter(r['key'] for r in rows if r['scope']=='STRATEGY_ACTIVATION')))
    print("  TECH rows by key:    ", dict(Counter(r['key'] for r in rows if r['scope']=='TECHNICAL_SIGNAL')))
    print("\nSAMPLE (5):")
    for r in rows[:5]:
        print(f"  {r['as_of_date']} {r['scope']:<22} {r['key']:<22} value={r['value']!r} theater={r['theater_check']}")

if __name__ == "__main__":
    main()

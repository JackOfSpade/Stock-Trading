#!/usr/bin/env python3
"""Parse Portfolio_Ledger.md → NDJSON for position_events / trade_fills / parking_events.

Three outputs:
  position_events.jsonl  — one OPEN/CLOSED/EXIT-PENDING/ORDER-STAGED row per position block
  trade_fills.jsonl      — extracted from each position's '**Order details**' line
  parking_events.jsonl   — SGOV Parking Activity pipe-table rows

Position blocks live under '## Position thesis details' as H3 headers:
    ### [Strategy X] TICKER — STATUS YYYY-MM-DD ...
Bold-field bullets follow: **Source thesis**, **Order details**, **Convergence target**,
**Time-based exit**, **12-mo LTCG eligible date**, **Invalidation criteria status**,
**Mark-to-market**, **Holding-period notes**, **CLOSED** / **EXIT-PENDING**.
"""
import re, json, base64, pathlib
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Portfolio_Ledger.md"
OUT = ROOT / "bigquery" / "out"

POS_HEADER = re.compile(
    r'^###\s+\[Strategy\s+([A-E])\]\s+([A-Z0-9\.\-/]+)\s+(?:—|--)\s+'
    r'(OPEN|CLOSED|EXIT-PENDING|ORDER-STAGED)\b[^\n]*?(\d{4}-\d{2}-\d{2})?',
    re.MULTILINE,
)
SECTION_HEADER = re.compile(r'^##\s+', re.MULTILINE)
PARKING_ROW = re.compile(
    r'^\|\s*(\d{4}-\d{2}-\d{2})[^|]*\|\s*([^|]+?)\s*\|\s*'
    r'([\d\.\-]+)\s*\|\s*\$?([\d\.,]+)\s*\|\s*\$?([\d\.\-]+)\s*\|\s*'
    r'\$?([\d\.,]+)\s*\|\s*([^|\n]*?)\s*\|',
    re.MULTILINE,
)

NUM = lambda s: float(s.replace(',', '').replace('$', '').strip()) if s and s.strip() else None

def split_position_blocks(text):
    """Find the 'Position thesis details' section and yield (header_match, block_text)."""
    # locate the section
    start = re.search(r'^##\s+Position thesis details', text, re.MULTILINE)
    if not start:
        return
    end = re.search(SECTION_HEADER, text[start.end():])
    region = text[start.end():start.end() + (end.start() if end else len(text))]
    heads = list(POS_HEADER.finditer(region))
    heads.append(None)
    for i in range(len(heads) - 1):
        m = heads[i]
        j_start = m.start()
        j_end = heads[i + 1].start() if heads[i + 1] else len(region)
        yield m, region[j_start:j_end]

def field(label, block):
    """Extract '- **Label**: value' (multiline) value text."""
    rx = re.compile(
        rf'^-\s+\*\*{re.escape(label)}\*\*:\s*(.+?)(?=^-\s+\*\*|\Z)',
        re.MULTILINE | re.DOTALL,
    )
    m = rx.search(block)
    return m.group(1).strip() if m else None

def first(rx, s, flags=0, group=1):
    if not s:
        return None
    m = re.search(rx, s, flags)
    return m.group(group) if m else None

def parse_invalidation(block):
    """Convert the (i)..(vi) invalidation-criteria bullets to a list of {criterion,status,as_of}."""
    raw = field("Invalidation criteria status", block)
    if not raw:
        return None
    items = []
    for cm in re.finditer(
        r'^\s*[-•]?\s*\(([iv]+)\)\s+([^\n]*?)\s*(?:—|--)\s*([^\n.]+)',
        raw, re.MULTILINE | re.IGNORECASE,
    ):
        items.append({
            "criterion": cm.group(1),
            "description": cm.group(2).strip()[:200],
            "status_raw": cm.group(3).strip()[:200],
        })
    return items or None

def parse_fill(order_details, ticker, strategy):
    """Pull fill price/shares/commission from '**Order details**' free text."""
    if not order_details:
        return None
    txt = order_details
    # FILLED YYYY-MM-DD HH:MM:SS [TZ] at $PRICE
    m_dt = re.search(r'FILLED\s+(\d{4}-\d{2}-\d{2})\s+(\d{1,2}:\d{2}:\d{2})\s*([A-Z]{2,3})?', txt)
    if not m_dt:
        return None
    fill_date, fill_time, fill_tz = m_dt.group(1), m_dt.group(2), m_dt.group(3) or "ET"
    price = first(r'at\s+\$([\d,]+\.\d+)', txt[m_dt.end():])
    if not price:
        price = first(r'\$([\d,]+\.\d+)\s+exact-limit', txt)
    shares = first(r'(?:BUY|SELL)\s+([\d\.]+)\s+' + re.escape(ticker), txt) \
          or first(r'([\d\.]+)\s+shares?', txt)
    comm = first(r'commission\s+\$([\d\.,]+)', txt)
    principal = first(r'principal\s+\$([\d\.,]+)', txt)
    side = "BUY" if "BUY" in txt[:80] else ("SELL" if "SELL" in txt[:80] else None)
    # synthesize a deterministic trade_id from the fill stamp (real trade_ids only arrive via the connector;
    # this lets the curated view dedup against future connector ingest by overwriting on natural-key match)
    trade_id_synthetic = f"migration:{ticker}:{fill_date}T{fill_time}:{side}"
    return {
        "trade_id": trade_id_synthetic,
        "fill_ts": f"{fill_date}T{fill_time}",
        "fill_tz": fill_tz,
        "strategy": strategy, "ticker": ticker, "side": side,
        "shares": NUM(shares), "price": NUM(price),
        "commission": NUM(comm), "principal": NUM(principal),
        "is_synthetic": True,
    }

def parse_positions(text, rows_pos, rows_fills):
    for m, block in split_position_blocks(text):
        strategy, ticker, status, raw_date = m.group(1), m.group(2), m.group(3), m.group(4)
        order = field("Order details", block)
        fill = parse_fill(order, ticker, strategy)
        event_date = (fill["fill_ts"][:10] if fill else raw_date) or "2026-04-22"
        conv = first(r'\$([\d,]+\.\d+)', field("Convergence target", block) or "")
        tex = first(r'(\d{4}-\d{2}-\d{2})', field("Time-based exit", block) or "")
        ltcg = first(r'(\d{4}-\d{2}-\d{2})', field("12-mo LTCG eligible date", block) or "")
        position_key = f"{strategy}:{ticker}:{event_date}"
        note = (block.splitlines()[0] if block else "")[:300]
        rows_pos.append({
            "position_key": position_key,
            "event_ts": event_date + "T16:00:00",
            "event_type": "OPEN" if status == "ORDER-STAGED" else ("CLOSE" if status == "CLOSED" else "OPEN"),
            "status": status,
            "strategy": strategy, "ticker": ticker,
            "cost_basis": (fill["principal"] if fill else None),
            "shares": (fill["shares"] if fill else None),
            "convergence_target": NUM(conv),
            "time_exit_date": tex,
            "ltcg_date": ltcg,
            "invalidation_status_json": parse_invalidation(block),
            "conviction": first(r'\b(MEDIUM-HIGH|MEDIUM-LOW|HIGHEST|HIGH|MEDIUM|LOW)\b',
                                 field("Source thesis", block) or block),
            "model_at_entry": None,
            "source_thesis_ref": first(r'Decision_Log\s+(\d{4}-\d{2}-\d{2})', field("Source thesis", block) or ""),
            "note_b64": base64.b64encode(note.encode("utf-8")).decode("ascii"),
        })
        if fill:
            fill["source_thesis_ref"] = first(r'Decision_Log\s+(\d{4}-\d{2}-\d{2})', field("Source thesis", block) or "")
            rows_fills.append(fill)

def parse_parking(text, rows_park):
    """Pipe-table SGOV Parking Activity (lines after '### SGOV Parking Activity')."""
    start = re.search(r'^###\s+SGOV Parking Activity\s*$', text, re.MULTILINE)
    if not start:
        return
    end = re.search(r'^(?:###|##)\s', text[start.end():], re.MULTILINE)
    region = text[start.end():start.end() + (end.start() if end else len(text))]
    for pm in PARKING_ROW.finditer(region):
        date, action, shares, price, comm, gross, order_id = pm.groups()
        action_clean = action.strip()
        side = "BUY" if action_clean.lower().startswith("buy") else (
            "SELL" if action_clean.lower().startswith("sell") else action_clean[:20])
        rows_park.append({
            "action_date": date,
            "action": side,
            "shares": NUM(shares), "price": NUM(price),
            "commission": NUM(comm), "gross": NUM(gross),
            "order_id": order_id.strip()[:120] or None,
            "note": action_clean[:200],
        })

def main():
    text = SRC.read_text(encoding="utf-8")
    OUT.mkdir(parents=True, exist_ok=True)
    rows_pos, rows_fills, rows_park = [], [], []
    parse_positions(text, rows_pos, rows_fills)
    parse_parking(text, rows_park)
    with open(OUT / "position_events.jsonl", "w") as f:
        for r in rows_pos: f.write(json.dumps(r) + "\n")
    with open(OUT / "trade_fills.jsonl", "w") as f:
        for r in rows_fills: f.write(json.dumps(r) + "\n")
    with open(OUT / "parking_events.jsonl", "w") as f:
        for r in rows_park: f.write(json.dumps(r) + "\n")

    print(f"position_events: {len(rows_pos)}")
    print("  by status:    ", dict(Counter(r['status'] for r in rows_pos)))
    print("  by strategy:  ", dict(Counter(r['strategy'] for r in rows_pos)))
    print(f"trade_fills:     {len(rows_fills)}   (synthetic from ledger; will be superseded by connector ingest by natural-key match)")
    print(f"parking_events:  {len(rows_park)}")
    print("  by action:    ", dict(Counter(r['action'] for r in rows_park)))
    print("\nSAMPLE POSITIONS:")
    for r in rows_pos[:5]:
        print(f"  [{r['strategy']}] {r['ticker']:<6} {r['status']:<14} cost=${r['cost_basis']} conv=${r['convergence_target']} ltcg={r['ltcg_date']}")
    print("\nSAMPLE FILLS:")
    for r in rows_fills[:3]:
        print(f"  {r['fill_ts']} {r['side']} {r['shares']} {r['ticker']} @ ${r['price']} comm=${r['commission']}")
    print("\nSAMPLE PARKING:")
    for r in rows_park[:3]:
        print(f"  {r['action_date']} {r['action']} {r['shares']} SGOV @ ${r['price']} order_id={r['order_id'][:40] if r['order_id'] else None}")

if __name__ == "__main__":
    main()

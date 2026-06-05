#!/usr/bin/env python3
"""Parse the three queue files → queue_events.jsonl.

Source files (YAML-ish, '---'-delimited blocks of '- key: value' / 'key: value'):
  - Pending_Analysis.md            → queue='PENDING_ANALYSIS'
  - Pending_Adversarial_Reviews.md → queue='PENDING_REVIEW'
  - Watchlist.md                   → queue='WATCHLIST' (pipe-table rows; ticker keyed)

Each row is one INSERT into events.queue_events; the state.open_queue view takes
the latest event per (queue, item_key).
"""
import re, json, base64, pathlib
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "bigquery" / "out"

def parse_yaml_blocks(text, queue):
    """Split on '---' lines and parse each block's '- key: value' / 'key: value' pairs.
    Multi-line 'key: |' values are kept verbatim as a single string."""
    rows = []
    blocks = re.split(r'^---\s*$', text, flags=re.MULTILINE)
    for blk in blocks:
        if not re.search(r'^-?\s*id\s*:', blk, re.MULTILINE):
            continue
        rec = {}
        lines = blk.splitlines()
        i = 0
        while i < len(lines):
            ln = lines[i]
            m = re.match(r'^\s*-?\s*([A-Za-z_]+)\s*:\s*(.*)$', ln)
            if not m:
                i += 1; continue
            k, v = m.group(1), m.group(2).rstrip()
            if v.strip() == "|":
                # collect indented continuation lines
                buf = []
                j = i + 1
                while j < len(lines) and (lines[j].startswith("  ") or lines[j].strip() == ""):
                    if lines[j].startswith("  "):
                        buf.append(lines[j][2:])
                    j += 1
                rec[k] = "\n".join(buf).strip()
                i = j
            else:
                rec[k] = v.strip()
                i += 1
        if not rec.get("id"):
            continue
        rows.append({
            "queue": queue,
            "item_key": rec.get("id"),
            "item_type": rec.get("analysis_type") or rec.get("review_type"),
            "status": rec.get("status", "pending"),
            "strategy": rec.get("strategy") if rec.get("strategy") in {"A","B","C","D","E","router"} else None,
            "ticker": (rec.get("ticker_or_pair") or "").split()[0][:20] or None,
            "due_date": rec.get("due_date") or rec.get("attacker_due_date") or rec.get("orchestrator_due_date"),
            "conservative_default": (rec.get("conservative_default") or "")[:1000],
            "artifact_path": rec.get("artifact_path"),
            "payload_json": rec,
            "note_b64": base64.b64encode(((rec.get("context") or rec.get("trigger_context") or "")[:8000]).encode("utf-8")).decode("ascii"),
        })
    return rows

def parse_watchlist(text):
    """Watchlist.md is pipe-tables per strategy; each row → a WATCHLIST queue event."""
    rows = []
    # Detect '## Strategy X ...' section markers + pipe-table rows
    sections = re.split(r'^##\s+(.+?)$', text, flags=re.MULTILINE)
    # sections = [pre, header1, body1, header2, body2, ...]
    for i in range(1, len(sections), 2):
        header, body = sections[i].strip(), sections[i + 1]
        strategy = None
        sm = re.search(r'Strategy\s+([A-E])\b', header)
        if sm: strategy = sm.group(1)
        for rm in re.finditer(
            r'^\|\s*([A-Z0-9\.\-/]{1,8})\s*\|\s*(\d{4}-\d{2}-\d{2})?\s*\|([^|]*)\|([^|]*)\|([^|\n]+)\|',
            body, re.MULTILINE):
            ticker, date_added, source, reason, status = (g.strip() for g in rm.groups())
            if ticker in {"Ticker", "----", ""}:
                continue
            rows.append({
                "queue": "WATCHLIST",
                "item_key": f"{strategy or 'X'}:{ticker}:{date_added or ''}",
                "item_type": header[:60],
                "status": "pending" if "EXPIRED" not in status.upper() and "RESOLVED" not in status.upper() else "complete",
                "strategy": strategy,
                "ticker": ticker,
                "due_date": None,
                "conservative_default": None,
                "artifact_path": "Watchlist.md",
                "payload_json": {"source": source, "reason": reason[:500], "status": status[:200]},
                "note_b64": base64.b64encode(reason.encode("utf-8")).decode("ascii"),
            })
    return rows

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    rows += parse_yaml_blocks((ROOT / "Pending_Analysis.md").read_text(encoding="utf-8"), "PENDING_ANALYSIS")
    rows += parse_yaml_blocks((ROOT / "Pending_Adversarial_Reviews.md").read_text(encoding="utf-8"), "PENDING_REVIEW")
    # Completed/superseded entries D3 swept out of the live queues live here — unified into the
    # same queue_events table with status='complete' (one table, not a separate "archive").
    rows += parse_yaml_blocks((ROOT / "Archived_Analysis.md").read_text(encoding="utf-8"), "PENDING_ANALYSIS")
    rows += parse_yaml_blocks((ROOT / "Archived_Adversarial_Reviews.md").read_text(encoding="utf-8"), "PENDING_REVIEW")
    rows += parse_watchlist((ROOT / "Watchlist.md").read_text(encoding="utf-8"))
    with open(OUT / "queue_events.jsonl", "w") as f:
        for r in rows: f.write(json.dumps(r) + "\n")
    print(f"queue_events: {len(rows)}")
    print("  by queue:   ", dict(Counter(r['queue'] for r in rows)))
    print("  by status:  ", dict(Counter(r['status'] for r in rows)))
    print("  by strategy:", dict(Counter(r['strategy'] for r in rows)))
    print("\nSAMPLE (5):")
    for r in rows[:5]:
        print(f"  {r['queue']:<18} {r['item_key']:<32} status={r['status']:<10} due={r['due_date']}")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Parse Decision_Log markdown (3 header eras) -> NDJSON rows for events.decision_log.

body_md is the source of truth; structured columns are best-effort and get refined
later via AI.GENERATE_TABLE. Bodies are base64-encoded in the NDJSON so the messy
markdown loads into BigQuery without quote/newline escaping issues.

Header eras handled:
  ## 2026-04-26 Strategy D thesis ...        (H2, unbracketed, live early)
  ## 2026-05-22 — BRC fill capture           (H2, em-dash)
  ### [2026-06-03] Divergence ...            (H3, bracketed, live recent)
  ### 2026-04-22 Experiment inception ...    (H3, unbracketed, archive)
  # [archived] 2026-04-23 ... -> file        (H1 stub: SKIPPED)
"""
import re, json, base64, pathlib
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
FILES = [
    ("Decision_Log.md", "live"),
    ("Decision_Log_Archive_2026_Q2.md", "archive"),
    ("Decision_Log_Migration_Entry.md", "migration"),
]
HEADER_RE = re.compile(r'^(#{1,3})\s+(\[archived\]\s+)?\[?(\d{4}-\d{2}-\d{2})\]?\s*(.*)$')

TYPE_RULES = [
    ("thesis construction", "thesis-construction"), ("thesis-construction", "thesis-construction"),
    ("b-thesis", "thesis-construction"), ("b thesis", "thesis-construction"),
    ("divergence adversarial", "divergence-review"), ("divergence", "divergence-review"),
    ("router state change", "router-state-change"), ("router activation", "router-state-change"),
    ("foundation-change", "foundation-change-assessment"), ("foundation change", "foundation-change-assessment"),
    ("pre-mortem", "pre-mortem"), ("premortem", "pre-mortem"),
    ("runaway", "runaway-review"), ("mark-to-market", "m2m-review"), ("m2m", "m2m-review"),
    ("redistribution", "redistribution-review"), ("termination", "strategy-termination"),
    ("theater-check survey", "theater-survey"), ("fill capture", "fill-capture"),
    ("fill-capture", "fill-capture"), ("action conversion", "action-conversion"),
    ("correction", "correction"), ("gate", "gate-session"), ("inception", "inception"),
    ("hf frontier", "hf-capability-capture"), ("architectural decision", "framework-change"),
]

def classify(title, body):
    t = (title + " " + body[:400]).lower()
    for k, v in TYPE_RULES:
        if k in t:
            return v
    return "other"

def first(rx, s, flags=0):
    m = re.search(rx, s, flags)
    return m.group(1) if m else None

def parse_file(path, era, rows):
    lines = path.read_text(encoding="utf-8").splitlines()
    heads = [(i, m) for i, ln in enumerate(lines) if (m := HEADER_RE.match(ln))]
    heads.append((len(lines), None))
    for idx in range(len(heads) - 1):
        i, m = heads[idx]
        j = heads[idx + 1][0]
        if m.group(2):                     # [archived] stub -> skip block
            continue
        date = m.group(3)
        title = m.group(4).strip().lstrip("—-").strip()
        body = "\n".join(lines[i:j]).strip()
        conv = first(r'[Cc]onviction[^\n]*?\b(HIGHEST|HIGH|MEDIUM-HIGH|MEDIUM-LOW|MEDIUM|LOW)\b', body) \
            or first(r'\b(MEDIUM-HIGH|MEDIUM-LOW)\b', body)
        rows.append({
            "entry_date": date,
            "entry_type": classify(title, body),
            "strategy": first(r'Strategy\s+([A-E])\b', title + " " + body),
            "ticker": None,
            "decision": first(r'\b(NO-GO|GO|DO-NOT-ACTIVATE|ACTIVATE|TERMINATE|HOLD|HYBRID)\b', title),
            "conviction": conv,
            "sub_pattern": first(r'\b(SP\d[a-d]?|sub-pattern\s+\d+[a-d]?|Pattern\s+N)\b', body, re.I),
            "theater_check": first(r'[Tt]heater-check[^\n]*?\b(CONVERGENT|DIVERGENT|MIXED)\b', body),
            "title": title[:500],
            "title_b64": base64.b64encode(title.encode("utf-8")).decode("ascii"),
            "body_b64": base64.b64encode(body.encode("utf-8")).decode("ascii"),
            "source": f"migration:{path.name}",
            "era": era,
        })

def main():
    rows = []
    for fn, era in FILES:
        p = ROOT / fn
        if p.exists():
            parse_file(p, era, rows)
    outdir = ROOT / "bigquery" / "out"
    outdir.mkdir(parents=True, exist_ok=True)
    with open(outdir / "decision_log.jsonl", "w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    print(f"TOTAL entries: {len(rows)}")
    print("by era:        ", dict(Counter(r['era'] for r in rows)))
    print("by entry_type: ", dict(Counter(r['entry_type'] for r in rows)))
    print("by strategy:   ", dict(Counter(r['strategy'] for r in rows)))
    print("conviction !=NULL:", sum(1 for r in rows if r['conviction']),
          " sub_pattern !=NULL:", sum(1 for r in rows if r['sub_pattern']),
          " theater !=NULL:", sum(1 for r in rows if r['theater_check']))
    ds = sorted(r['entry_date'] for r in rows)
    print("date range:    ", ds[0], "->", ds[-1])
    avg = sum(len(base64.b64decode(r['body_b64'])) for r in rows) / max(len(rows), 1)
    print(f"avg body chars: {avg:.0f}")
    print("\nSAMPLE (first 4):")
    for r in rows[:4]:
        print(f"  [{r['entry_date']}] {r['entry_type']:<22} S={r['strategy']} :: {r['title'][:72]}")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Parse Adversarial_Review_*_{attacker,orchestrator}.md → adversarial_reviews.jsonl."""
import re, json, base64, pathlib
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "bigquery" / "out"

def parse_one(path):
    text = path.read_text(encoding="utf-8")
    role = "attacker" if "_attacker.md" in path.name else "orchestrator"
    review_id = re.search(r'Adversarial_Review_([^_]+)_', path.name).group(1)
    # header values are bold-bulleted '- id: …' style
    def hv(key):
        m = re.search(rf'^\s*-\s*{key}\s*:\s*(.+?)$', text, re.MULTILINE)
        return m.group(1).strip() if m else None
    rt = hv("review_type")
    strat = hv("strategy")
    date = hv("date")
    cyc = hv("cycle_number")
    if date:
        date = re.search(r'(\d{4}-\d{2}-\d{2})', date).group(1) if re.search(r'\d{4}-\d{2}-\d{2}', date) else None
    # verdict + theater-check
    verdict = None
    for h in (r'^##\s+Final verdict\b[^\n]*\n+([^\n]+)',
              r'^##\s+Verdict\b[^\n]*\n+([^\n]+)',
              r'\*\*Binding decision:\*\*\s*([^\n]+)'):
        m = re.search(h, text, re.MULTILINE)
        if m: verdict = m.group(1).strip("* "); break
    tc = re.search(r'(?:Theater-check flag[^:]*:|^##\s+Theater-check flag[^\n]*\n+)[^A-Z]*?(CONVERGENT|DIVERGENT|MIXED)', text, re.MULTILINE)
    # weaknesses: '### W1 (Tier N) — title' or '### MW1 — title'
    weaknesses = []
    for wm in re.finditer(r'^###\s+(W\d+|MW\d+)\s*(?:\((Tier\s*\d+)\))?\s*(?:—|--)\s*([^\n]+)', text, re.MULTILINE):
        weaknesses.append({"id": wm.group(1), "tier": wm.group(2), "title": wm.group(3).strip()[:300]})
    return {
        "review_id": review_id,
        "review_type": rt,
        "strategy": strat,
        "role": role,
        "review_date": date,
        "cycle_number": int(cyc) if cyc and cyc.isdigit() else None,
        "verdict": (verdict or "")[:400],
        "theater_check": tc.group(1) if tc else None,
        "weaknesses_json": weaknesses,
        "artifact_path": str(path.relative_to(ROOT)),
        "body_b64": base64.b64encode(text.encode("utf-8")).decode("ascii"),
    }

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    paths = sorted(ROOT.glob("Adversarial_Review_*.md"))
    rows = [parse_one(p) for p in paths]
    with open(OUT / "adversarial_reviews.jsonl", "w") as f:
        for r in rows: f.write(json.dumps(r) + "\n")
    print(f"adversarial_reviews: {len(rows)} (from {len(paths)} files)")
    print("  by review_type:", dict(Counter(r['review_type'] for r in rows)))
    print("  by role:       ", dict(Counter(r['role'] for r in rows)))
    print("  by theater:    ", dict(Counter(r['theater_check'] for r in rows)))
    for r in rows:
        print(f"  {r['review_id']:<22} {r['role']:<13} verdict={r['verdict'][:60]!r}")

if __name__ == "__main__":
    main()

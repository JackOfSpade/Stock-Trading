import json, re, os, time, subprocess, datetime as dt

ROOT = os.path.dirname(os.path.abspath(__file__))
EV = os.path.join(ROOT, "..", "es", "ev.json")
UA = "strategy-research jacksterwu-research"
RAW = os.path.join(ROOT, "raw")
PX = os.path.join(ROOT, "px")
os.makedirs(RAW, exist_ok=True)
os.makedirs(PX, exist_ok=True)


def get(url, extra=()):
    time.sleep(0.8)
    r = subprocess.run(["curl", "-s", "-A", UA, "-m", "30", *extra, url], capture_output=True)
    return r.stdout.decode("utf-8", "ignore")


MON = {m: i + 1 for i, m in enumerate("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split())}
ev = [e for e in json.load(open(EV))
      if e["ne"] is not None and e["ne"] <= 2 and "2026-07-01" <= e["d"] <= "2026-09-28" and e["s"].isalpha()]
out = []
for n, e in enumerate(ev):
    s = e["s"].lower()
    html = get(f"https://stockanalysis.com/stocks/{s}/transcripts/")
    links = sorted(set(re.findall(rf'/stocks/{s}/transcripts/(\d+)-([^"\'\s<>\\/]+)/', html)), key=lambda x: -int(x[0]))
    found = None
    for lid, slug in links[:3]:
        page = get(f"https://stockanalysis.com/stocks/{s}/transcripts/{lid}-{slug}/")
        m = re.search(r"Earnings Call:\s*(?:<[^>]+>\s*)*[^<]{0,40}?(?:<[^>]+>\s*)*([A-Z][a-z]{2}) (\d{1,2}), (\d{4})", page)
        if not m:
            t = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", page))
            m = re.search(r"Earnings Call: .{0,40}?([A-Z][a-z]{2}) (\d{1,2}), (\d{4})", t)
        if not m or m.group(1) not in MON:
            continue
        call = dt.date(int(m.group(3)), MON[m.group(1)], int(m.group(2)))
        gap = abs((call - dt.date.fromisoformat(e["d"])).days)
        if gap <= 1:
            f = os.path.join(RAW, f"{e['s']}_{e['d']}.html")
            open(f, "w").write(page)
            found = dict(e, call=str(call), file=f)
            break
        if call < dt.date.fromisoformat(e["d"]) - dt.timedelta(days=2):
            break
    if found:
        out.append(found)
    if n % 25 == 0:
        print(n, len(ev), "matched", len(out), flush=True)
        json.dump(out, open(os.path.join(ROOT, "matched.json"), "w"))
json.dump(out, open(os.path.join(ROOT, "matched.json"), "w"))
print("matched", len(out), "of", len(ev), flush=True)

syms = sorted({m["s"] for m in out}) + ["IWM"]
for s in syms:
    f = os.path.join(PX, s + ".json")
    if os.path.exists(f) and os.path.getsize(f) > 500:
        continue
    cls = "etf" if s == "IWM" else "stocks"
    b = get(f"https://api.nasdaq.com/api/quote/{s}/historical?assetclass={cls}&fromdate=2026-05-01&todate=2026-11-02&limit=200",
            ("-H", "Accept: application/json"))
    open(f, "w").write(b)
print("prices done", len(syms), flush=True)

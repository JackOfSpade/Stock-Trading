import json, re, os, html as H, hashlib, random, bisect

ROOT = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(ROOT, "pack")
SEC = os.path.join(ROOT, "secure")
os.makedirs(PACK, exist_ok=True)
os.makedirs(SEC, exist_ok=True)


def px(s):
    try:
        rows = json.load(open(f"{ROOT}/px/{s}.json"))["data"]["tradesTable"]["rows"]
    except Exception:
        return None
    o = []
    for r in rows:
        try:
            m, d, y = r["date"].split("/")
            g = lambda k: float(r[k].replace("$", "").replace(",", ""))
            o.append((f"{y}-{m}-{d}", g("open"), g("close")))
        except Exception:
            pass
    return sorted(o)


iwm = {r[0]: r for r in px("IWM")}
MONTHS = r"(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\.?"
STOP = {"inc", "corp", "corporation", "company", "co", "ltd", "limited", "plc", "the", "holdings", "holding", "group",
        "of", "and", "class", "common", "stock", "shares", "trust", "bancorp", "financial", "bank", "energy", "american",
        "america", "national", "first", "international", "technologies", "therapeutics", "sa", "nv", "lp", "llc",
        "pharmaceuticals", "industries", "systems", "partners", "new", "global", "capital", "services", "solutions"}


def clean(page, e):
    t = re.sub(r"<script.*?</script>|<style.*?</style>", " ", page, flags=re.S)
    t = H.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", t)))
    a = t.find("Download Transcript Full Transcript Full Summary")
    b = t.rfind("Download Transcript Speakers")
    if a < 0 or b < a:
        return None, []
    body = t[a + len("Download Transcript Full Transcript Full Summary"):b]
    # Drop the site's generated summary: everything before the first Operator line, else first 1,000 characters.
    i = body.find("Operator ")
    body = body[i:] if 0 <= i < 3000 else body[1000:]
    sp = t[b:b + 1500]
    return body, re.findall(r"\b([A-Z][a-zA-Z'\-]+ [A-Z][a-zA-Z'\-]+)\b", sp.split("Install The App")[0])


def mask(body, e, speakers):
    words = [w for w in re.findall(r"[A-Za-z][A-Za-z&'\-]+", e["n"] or "") if w.lower() not in STOP and len(w) > 2]
    full = re.sub(r"\s*\(The\)|,?\s*(Inc|Corp|Corporation|Ltd|Limited|Plc|Company)\.?.*$", "", e["n"] or "", flags=re.I).strip()
    if full:
        body = re.sub(re.escape(full), "[COMPANY]", body, flags=re.I)
    for w in words[:3]:
        body = re.sub(rf"\b{re.escape(w)}\b", "[COMPANY]", body, flags=re.I if len(w) > 4 else 0)
    body = re.sub(rf"\b{re.escape(e['s'])}\b", "[COMPANY]", body)
    for sp in set(speakers):
        for tok in sp.split():
            if tok.lower() not in {"full", "summary", "speakers", "download", "transcript", "chief", "officer"}:
                body = re.sub(rf"\b{re.escape(tok)}\b", "[PERSON]", body)
    # Speaker-turn names: a capitalized pair followed by a role word, or listed after "With me" phrasing.
    ROLE = r"(?:Chief|President|CEO|CFO|COO|CTO|Corporate|Vice|VP|SVP|EVP|Senior|Director|Analyst|Head|Executive|General|Investor|Managing|Treasurer|Founder|Chairman|Chairwoman|Chair|Secretary|Partner|Principal|Research|Equity|Controller|Lead)"
    names = set(re.findall(rf"\b([A-Z][a-z'\-]+ (?:[A-Z]\. )?[A-Z][a-zA-Z'\-]+)(?:,)? {ROLE}\b", body))
    names |= set(re.findall(r"\b([A-Z][a-z'\-]+ [A-Z][a-zA-Z'\-]+), (?:our|the) ", body))
    for nm in names:
        for tok in nm.replace(".", " ").split():
            if len(tok) > 2 and tok.lower() not in {"good", "thank", "thanks", "the", "our", "and", "operator", "question", "next", "with"}:
                body = re.sub(rf"\b{re.escape(tok)}\b", "[PERSON]", body)
    body = re.sub(r"\b(Thank you|Thanks|Hi|Hey|Good morning|Good afternoon),? [A-Z][a-z]+\b", r"\1, [PERSON]", body)
    body = re.sub(rf"\b{MONTHS} \d{{1,2}}(?:st|nd|rd|th)?(?:,? \d{{4}})?", "[DATE]", body)
    body = re.sub(rf"\b{MONTHS} \d{{4}}", "[DATE]", body)
    body = re.sub(r"\b(?:19|20)\d{2}\b", "[YEAR]", body)
    body = re.sub(r"\bFY ?\d{2}\b|\bF?Q[1-4] ?(?:FY)?\d{2}\b", "[PERIOD]", body)
    return body


m = json.load(open(f"{ROOT}/matched.json"))
print("matched", len(m))
rows, dropped = [], {"short": 0, "px": 0, "exit": 0, "dup": 0}
seen = set()
for e in m:
    if (e["s"], e["d"]) in seen:
        dropped["dup"] += 1
        continue
    seen.add((e["s"], e["d"]))
    body, sp = clean(open(e["file"]).read(), e)
    if not body or len(body) < 5000:
        dropped["short"] += 1
        continue
    r = px(e["s"])
    if not r:
        dropped["px"] += 1
        continue
    ds = [x[0] for x in r]
    i = bisect.bisect_left(ds, e["d"])
    if i < 1 or i + 2 + 20 >= len(ds) + 0 or i + 2 >= len(ds):
        dropped["exit"] += 1
        continue
    reaction = r[i + 1][2] / r[i - 1][2] - 1
    entry = r[i + 2]
    rets = {}
    ok = True
    for h in (5, 10, 20):
        ex = r[i + 2 + h]
        if entry[0] not in iwm or ex[0] not in iwm or entry[1] <= 0 or ex[1] <= 0:
            ok = False
            break
        rets[h] = (ex[1] / entry[1] - 1) - (iwm[ex[0]][1] / iwm[entry[0]][1] - 1)
    if not ok:
        dropped["exit"] += 1
        continue
    rows.append(dict(s=e["s"], d=e["d"], call=e["call"], n=e["n"], ne=e["ne"], mc=e["mc"], entry=entry[0], reaction=reaction,
                     r5=rets[5], r10=rets[10], r20=rets[20], body=mask(body, e, sp)))
print("eligible", len(rows), "dropped", dropped)
random.Random(20261102).shuffle(rows)
rows = rows[:300]
retest = random.Random(202611021).sample(range(len(rows)), min(30, len(rows)))
key = []
for k, r in enumerate(rows):
    hid = hashlib.sha1(f"20261102|{r['s']}|{r['d']}".encode()).hexdigest()[:12]
    open(f"{PACK}/{hid}.txt", "w").write(f"Share price move across the earnings release (two sessions): {r['reaction']*100:+.1f}%\n\nTRANSCRIPT\n{r.pop('body')}\n")
    key.append(dict(r, id=hid, retest=k in retest))
json.dump(key, open(f"{SEC}/key.json", "w"))
L = sorted(os.path.getsize(f"{PACK}/{x['id']}.txt") for x in key)
print("final", len(key), "median chars", L[len(L)//2], "max", L[-1], "total MB", sum(L)/1e6)
import collections
print(collections.Counter(x["d"][:7] for x in key), "entry weeks", len({__import__('datetime').date.fromisoformat(x['entry']).isocalendar()[:2] for x in key}))
# Leak check
leak = 0
for x in key[:len(key)]:
    t = open(f"{PACK}/{x['id']}.txt").read()
    if re.search(rf"\b{re.escape(x['s'])}\b", t):
        leak += 1
print("ticker leaks", leak)
print(open(f"{PACK}/{key[0]['id']}.txt").read()[:1500])

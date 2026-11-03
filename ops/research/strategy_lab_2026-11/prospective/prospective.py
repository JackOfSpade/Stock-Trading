"""Daily pipeline for the prospective L3 test. Rules are in PREREGISTRATION.md.

  prepare [--asof YYYY-MM-DD] [--limit N] [--dry]   build masked packs for today's events, print reader ids as JSON
  ingest --reads FILE --asof YYYY-MM-DD             append reader results to the hash-chained ledger
  publish --asof YYYY-MM-DD                         commit this directory and push it as a dated tag
  status                                            counts only; never computes returns
  score                                             final scoring; refuses before 2027-01-04
"""
import argparse
import collections
import datetime as dt
import glob
import hashlib
import html as H
import json
import math
import os
import random
import re
import statistics as st
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.abspath(__file__))
PRIV = os.path.join(ROOT, "_private")
PACK = os.path.join(PRIV, "pack")
RAW = os.path.join(PRIV, "raw")
RUN = os.path.join(ROOT, "run")
LEDGER = os.path.join(ROOT, "scores.jsonl")
EVENTS = os.path.join(ROOT, "events.jsonl")
UA = "strategy-research jacksterwu-research"
FIRST_EVENT, LAST_EVENT = "2026-10-30", "2026-11-27"
SCORE_FROM = "2027-01-04"
HOLIDAYS = {"2026-11-26", "2026-12-25", "2027-01-01", "2027-01-18", "2027-02-15"}
MON = {m: i + 1 for i, m in enumerate("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split())}
for d in (PACK, RAW, RUN):
    os.makedirs(d, exist_ok=True)


def is_td(d):
    return d.weekday() < 5 and str(d) not in HOLIDAYS


def prev_td(d):
    d -= dt.timedelta(days=1)
    while not is_td(d):
        d -= dt.timedelta(days=1)
    return d


def next_td(d):
    d += dt.timedelta(days=1)
    while not is_td(d):
        d += dt.timedelta(days=1)
    return d


def get(url, extra=()):
    time.sleep(0.8)
    r = subprocess.run(["curl", "-s", "-A", UA, "-m", "30", *extra, url], capture_output=True)
    return r.stdout.decode("utf-8", "ignore")


def plain(page):
    t = re.sub(r"<script.*?</script>|<style.*?</style>", " ", page, flags=re.S)
    return H.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", t)))


def bars(s, frm="2026-05-01", to=None):
    cls = "etf" if s == "IWM" else "stocks"
    to = to or str(dt.date.today())
    b = get(f"https://api.nasdaq.com/api/quote/{s}/historical?assetclass={cls}&fromdate={frm}&todate={to}&limit=400", ("-H", "Accept: application/json"))
    out = []
    try:
        for r in json.loads(b)["data"]["tradesTable"]["rows"]:
            m, d, y = r["date"].split("/")
            g = lambda k: float(r[k].replace("$", "").replace(",", ""))
            out.append((f"{y}-{m}-{d}", g("open"), g("close")))
    except Exception:
        pass
    return sorted(out)


# ---- cleaning and masking: same rules as stage4_L3_build.py ----
MONTHS = r"(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\.?"
STOP = {"inc", "corp", "corporation", "company", "co", "ltd", "limited", "plc", "the", "holdings", "holding", "group",
        "of", "and", "class", "common", "stock", "shares", "trust", "bancorp", "financial", "bank", "energy", "american",
        "america", "national", "first", "international", "technologies", "therapeutics", "sa", "nv", "lp", "llc",
        "pharmaceuticals", "industries", "systems", "partners", "new", "global", "capital", "services", "solutions"}


def clean(page):
    t = plain(page)
    a = t.find("Download Transcript Full Transcript Full Summary")
    b = t.rfind("Download Transcript Speakers")
    if a < 0 or b < a:
        return None, []
    body = t[a + len("Download Transcript Full Transcript Full Summary"):b]
    i = body.find("Operator ")
    body = body[i:] if 0 <= i < 3000 else body[1000:]
    sp = t[b:b + 1500]
    return body, re.findall(r"\b([A-Z][a-zA-Z'\-]+ [A-Z][a-zA-Z'\-]+)\b", sp.split("Install The App")[0])


def mask(body, name, sym, speakers):
    name = name or ""
    words = [w for w in re.findall(r"[A-Za-z][A-Za-z&'\-]+", name) if w.lower() not in STOP and len(w) > 2]
    full = re.sub(r"\s*\(The\)|,?\s*(Inc|Corp|Corporation|Ltd|Limited|Plc|Company)\.?.*$", "", name, flags=re.I).strip()
    if full:
        body = re.sub(re.escape(full), "[COMPANY]", body, flags=re.I)
    for w in words[:3]:
        body = re.sub(rf"\b{re.escape(w)}\b", "[COMPANY]", body, flags=re.I if len(w) > 4 else 0)
    body = re.sub(rf"\b{re.escape(sym)}\b", "[COMPANY]", body)
    for sp in set(speakers):
        for tok in sp.split():
            if tok.lower() not in {"full", "summary", "speakers", "download", "transcript", "chief", "officer"}:
                body = re.sub(rf"\b{re.escape(tok)}\b", "[PERSON]", body)
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
    return re.sub(r"\bFY ?\d{2}\b|\bF?Q[1-4] ?(?:FY)?\d{2}\b", "[PERIOD]", body)


def find_transcript(sym, d):
    s = sym.lower()
    lst = get(f"https://stockanalysis.com/stocks/{s}/transcripts/")
    links = sorted(set(re.findall(rf'/stocks/{s}/transcripts/(\d+)-([^"\'\s<>\\/]+)/', lst)), key=lambda x: -int(x[0]))
    for lid, slug in links[:3]:
        page = get(f"https://stockanalysis.com/stocks/{s}/transcripts/{lid}-{slug}/")
        m = re.search(r"Earnings Call: .{0,40}?([A-Z][a-z]{2}) (\d{1,2}), (\d{4})", plain(page))
        if not m or m.group(1) not in MON:
            continue
        call = dt.date(int(m.group(3)), MON[m.group(1)], int(m.group(2)))
        if abs((call - d).days) <= 1:
            return page, str(call), lst
        if call < d - dt.timedelta(days=2):
            break
    return None, None, lst


def site_close(page, want):
    m = re.search(r"([\d,]+\.\d+) [-+][\d,.]+ \([-+]?[\d.]+%\) At close: ([A-Z][a-z]{2}) (\d{1,2}), (\d{4})", plain(page))
    if m and str(dt.date(int(m.group(4)), MON[m.group(2)], int(m.group(3)))) == want:
        return float(m.group(1).replace(",", ""))
    return None


def append(path, row):
    with open(path, "a") as f:
        f.write(json.dumps(row, sort_keys=True) + "\n")


def ledger_rows():
    return [json.loads(x) for x in open(LEDGER)] if os.path.exists(LEDGER) else []


def event_rows():
    return [json.loads(x) for x in open(EVENTS)] if os.path.exists(EVENTS) else []


def consider(e, I, P, T, late, dry):
    """Returns a reader row, or None with the event's status logged."""
    d = dt.date.fromisoformat(e["d"])
    status = dict(s=e["s"], d=e["d"], i=str(I), p=str(P), run=str(T), mc=e["mc"], ne=e["ne"], late=late, dry=dry)

    def done(st_):
        if dry:
            print("dry", e["s"], e["d"], st_, status.get("analysts"), file=sys.stderr)
        else:
            append(EVENTS, dict(status, status=st_))
        return None

    fc = get(f"https://stockanalysis.com/stocks/{e['s'].lower()}/forecast/")
    m = re.search(r"According to (\d+) analysts?", fc)
    analysts = int(m.group(1)) if m else (1 if re.search(r"According to (one|an?) analyst", fc) else None)
    status["analysts"] = analysts
    page, call, lst = find_transcript(e["s"], d)
    if not page:
        return done("no_transcript")
    body, sp = clean(page)
    if not body or len(body) < 5000:
        return done("short_transcript")
    r = bars(e["s"])
    ds = [x[0] for x in r]
    prior = str(prev_td(I))
    if prior not in ds:
        return done("no_prior_close")
    c0 = r[ds.index(prior)][2]
    c1 = r[ds.index(str(P))][2] if str(P) in ds else site_close(lst, str(P))
    if c1 is None:
        return done("no_reaction_close")
    reaction = c1 / c0 - 1
    hid = hashlib.sha1(f"prospective|{e['s']}|{e['d']}".encode()).hexdigest()[:12]
    txt = f"Share price move across the earnings release (two sessions): {reaction*100:+.1f}%\n\nTRANSCRIPT\n{mask(body, e['n'], e['s'], sp)}\n"
    if re.search(rf"\b{re.escape(e['s'])}\b", txt):
        return done("ticker_leak")
    with open(f"{PACK}/{hid}.txt", "w") as f:
        f.write(txt)
    with open(f"{RAW}/{e['s']}_{e['d']}.html", "w") as f:
        f.write(page)
    if not dry:
        append(EVENTS, dict(status, status="prepared", id=hid, call=call))
    return dict(id=hid, s=e["s"], d=e["d"], call=call, n=e["n"], ne=e["ne"], mc=e["mc"], analysts=analysts, i=str(I), p=str(P),
                entry=str(T), run=str(T), reaction=reaction, close_i_minus1=c0, close_i_plus1=c1, late=late,
                pack_sha256=hashlib.sha256(txt.encode()).hexdigest())


def calendar(day):
    b = get(f"https://api.nasdaq.com/api/calendar/earnings?date={day}", ("-H", "Accept: application/json"))
    try:
        rows = (json.loads(b).get("data") or {}).get("rows") or []
    except Exception:
        return None
    out = []
    for r in rows:
        try:
            mc = float((r.get("marketCap") or "").replace("$", "").replace(",", ""))
        except ValueError:
            continue
        ne = r.get("noOfEsts") or ""
        if 3e8 <= mc <= 2e9 and str(ne).isdigit() and int(ne) <= 2 and r["symbol"].isalpha():
            out.append(dict(d=str(day), s=r["symbol"], mc=mc, ne=int(ne), n=r.get("name"), eps=r.get("eps"), fc=r.get("epsForecast")))
    return out


def prepare(a):
    T = dt.date.fromisoformat(a.asof) if a.asof else dt.date.today()
    if not is_td(T):
        print(json.dumps(dict(status="NOT_A_TRADING_DAY", ids=[])))
        return
    runfile = f"{RUN}/{T}.json"
    if os.path.exists(runfile) and not a.dry:
        prior = json.load(open(runfile))
        done_ids = {x["id"] for x in ledger_rows()}
        print(json.dumps(dict(status="ALREADY_PREPARED", ids=[x["id"] for x in prior["readers"] if x["id"] not in done_ids])))
        return
    P = prev_td(T)
    I = prev_td(P)
    lo = prev_td(I)
    if str(I) > LAST_EVENT and str(prev_td(I)) >= LAST_EVENT:
        print(json.dumps(dict(status="SEASON_DONE", ids=[])))
        return
    days = []
    x = lo + dt.timedelta(days=1)
    while x <= I:
        if FIRST_EVENT <= str(x) <= LAST_EVENT:
            days.append(x)
        x += dt.timedelta(days=1)
    readers, fail = [], []
    seen = {(r["s"], r["d"]) for r in event_rows() if r["status"] == "prepared"}
    ev = []
    for day in days:
        c = calendar(day)
        if c is None:
            fail.append(str(day))
        else:
            ev += c
    if a.limit:
        ev = ev[: a.limit]
    for e in ev:
        if (e["s"], e["d"]) in seen:
            continue
        r = consider(e, I, P, T, False, a.dry)
        if r:
            readers.append(r)
    # Retry missing transcripts from the previous two runs, flagged LATE so they stay out of the primary test.
    if not a.dry:
        recent = [r for r in event_rows() if r["status"] == "no_transcript" and not r["late"] and r["run"] in {str(P), str(prev_td(P))}]
        for r in recent:
            if (r["s"], r["d"]) in seen:
                continue
            e = dict(d=r["d"], s=r["s"], mc=r["mc"], ne=r["ne"], n=None)
            for c_ev in calendar(dt.date.fromisoformat(r["d"])) or []:
                if c_ev["s"] == r["s"]:
                    e = c_ev
            rr = consider(e, dt.date.fromisoformat(r["i"]), dt.date.fromisoformat(r["p"]), T, True, False)
            if rr:
                rr["entry"] = str(next_td(dt.date.fromisoformat(r["p"])))
                readers.append(rr)
    out = dict(run=str(T), i=str(I), p=str(P), days=[str(d) for d in days], calendar_failures=fail, candidates=len(ev), readers=readers)
    if a.dry:
        print(json.dumps(dict(status="DRY", candidates=len(ev), readers=[{k: x[k] for k in ("id", "s", "d", "call", "analysts", "reaction", "entry")} for x in readers])))
        return
    with open(runfile, "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(dict(status="READY", run=str(T), candidates=len(ev), calendar_failures=fail, pack_dir=PACK, ids=[x["id"] for x in readers])))


def ingest(a):
    T = a.asof
    run = json.load(open(f"{RUN}/{T}.json"))
    meta = {x["id"]: x for x in run["readers"]}
    rows = ledger_rows()
    have = {x["id"] for x in rows}
    prev = rows[-1]["row_sha256"] if rows else "genesis"
    reads = json.load(open(a.reads))
    now = dt.datetime.now(dt.timezone.utc)
    added, missing, invalid = 0, [], []
    for hid, m in meta.items():
        if hid in have:
            continue
        r = reads.get(hid)
        if r is None:
            missing.append(hid)
            continue
        if r.get("score") not in (-2, -1, 0, 1, 2) or not isinstance(r.get("recognized_company"), bool) or not isinstance(r.get("reason"), str):
            invalid.append(hid)
            continue
        entry_open = dt.datetime.fromisoformat(m["entry"] + "T14:30:00+00:00")  # 09:30 ET; the window is entirely EST.
        row = dict(m, score=r["score"], reason=r["reason"], recognized=r["recognized_company"], read_ts=now.isoformat(), model="claude-sonnet-5-5 requested",
                   tools=None, tools_clean=None, live=(not m["late"]) and now < entry_open, prev_sha256=prev)
        row["row_sha256"] = hashlib.sha256(json.dumps(row, sort_keys=True).encode()).hexdigest()
        prev = row["row_sha256"]
        append(LEDGER, row)
        added += 1
    unknown = sorted(set(reads) - set(meta))
    for hid in missing + invalid:
        append(EVENTS, dict(id=hid, s=meta[hid]["s"], d=meta[hid]["d"], run=T, late=meta[hid]["late"], status="not_read"))
    print(json.dumps(dict(run=T, added=added, missing=missing, invalid=invalid, unknown_ids=unknown, ledger_total=len(have) + added)))


def publish(a):
    def git(*c):
        return subprocess.run(["git", *c], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()

    tag = f"strategy-lab/prospective/{a.asof}"
    git("add", "-A", ".")
    if git("status", "--porcelain", "."):
        git("-c", "user.name=Claude", "-c", "user.email=noreply@anthropic.com", "commit", "-m",
            f"Strategy lab prospective test: daily ledger {a.asof} [skip ci]\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>")
    git("tag", "-f", tag)
    git("push", "--force", "origin", f"refs/tags/{tag}")
    print(json.dumps(dict(pushed=tag, commit=git("rev-parse", "HEAD"))))


def status(_):
    rows = ledger_rows()
    ev = event_rows()
    print(json.dumps(dict(ledger=len(rows), live=sum(x["live"] for x in rows), late=sum(not x["live"] for x in rows),
                          scores=dict(collections.Counter(x["score"] for x in rows if x["live"])),
                          recognized=sum(x["recognized"] for x in rows), models=dict(collections.Counter(x["model"] for x in rows)),
                          event_status=dict(collections.Counter(x["status"] for x in ev)),
                          last_read=max((x["read_ts"] for x in rows), default=None)), indent=1))


def score(_):
    if str(dt.date.today()) < SCORE_FROM:
        raise SystemExit(f"Refusing to compute returns before {SCORE_FROM}. See PREREGISTRATION.md.")
    rows = ledger_rows()
    prev = "genesis"
    for r in rows:
        body = {k: v for k, v in r.items() if k != "row_sha256"}
        assert r["prev_sha256"] == prev and hashlib.sha256(json.dumps(body, sort_keys=True).encode()).hexdigest() == r["row_sha256"], "ledger chain broken at " + r["id"]
        prev = r["row_sha256"]
    iwm = bars("IWM")
    iw = {x[0]: x for x in iwm}
    ids = [x[0] for x in iwm]
    out_rows = []
    for x in rows:
        b = bars(x["s"])
        ds = [y[0] for y in b]
        if x["entry"] not in ds or x["entry"] not in iw:
            x["no_entry"] = True
            out_rows.append(x)
            continue
        k = ds.index(x["entry"])
        ki = ids.index(x["entry"])
        for h in (5, 10, 20):
            if ki + h >= len(ids):
                continue
            exit_day = ids[ki + h]
            if exit_day in ds:
                ex = b[ds.index(exit_day)][1]
                x[f"delisted{h}"] = False
            else:
                ex = b[-1][2]
                x[f"delisted{h}"] = True
            x[f"s{h}"] = ex / b[k][1] - 1
            x[f"m{h}"] = iw[exit_day][1] / iw[x["entry"]][1] - 1
            x[f"r{h}"] = x[f"s{h}"] - x[f"m{h}"]
        # Beta over the 60 sessions ending at close(i-1).
        end = ds.index(str(prev_td(dt.date.fromisoformat(x["i"]))))
        pairs = []
        for j in range(max(1, end - 59), end + 1):
            a0, a1 = b[j - 1], b[j]
            if a0[0] in iw and a1[0] in iw:
                pairs.append((a1[2] / a0[2] - 1, iw[a1[0]][2] / iw[a0[0]][2] - 1))
        if len(pairs) >= 30 and "r20" in x:
            mx = st.mean(p[1] for p in pairs)
            my = st.mean(p[0] for p in pairs)
            x["beta"] = sum((p[1] - mx) * (p[0] - my) for p in pairs) / sum((p[1] - mx) ** 2 for p in pairs)
            x["rb20"] = x["s20"] - x["beta"] * x["m20"]
        x["week"] = "%d-%02d" % dt.date.fromisoformat(x["entry"]).isocalendar()[:2]
        out_rows.append(x)
    L = [x for x in out_rows if x["live"] and "r20" in x]
    v = sorted(x["r20"] for x in L)
    lo, hi = v[int(0.01 * (len(v) - 1))], v[math.ceil(0.99 * (len(v) - 1))]
    for x in L:
        x["w20"] = min(hi, max(lo, x["r20"]))
    A = [x for x in L if x["score"] == 1]
    Z = [x for x in L if x["score"] == 0]

    def cl(rs, f):
        z = [1 if x["score"] == 1 else 0 for x in rs]
        y = [x[f] for x in rs]
        n = len(rs)
        zb, yb = st.mean(z), st.mean(y)
        S = sum((q - zb) ** 2 for q in z)
        be = sum((q - zb) * (c - yb) for q, c in zip(z, y)) / S
        a0 = yb - be * zb
        g = collections.defaultdict(float)
        for x, q, c in zip(rs, z, y):
            g[x["week"]] += (q - zb) * (c - a0 - be * q)
        G = len(g)
        var = sum(u ** 2 for u in g.values()) / S ** 2 * (G / (G - 1)) * ((n - 1) / (n - 2))
        return be, be / math.sqrt(var), G

    res = dict(n_live=len(L), n1=len(A), n0=len(Z), score_counts=dict(collections.Counter(x["score"] for x in L)))
    if len(A) >= 30 and len(Z) >= 30:
        d, t, G = cl(A + Z, "w20")
        m1, m0 = st.mean(x["w20"] for x in A), st.mean(x["w20"] for x in Z)
        dmed = st.median(x["r20"] for x in A) > st.median(x["r20"] for x in Z)
        B1 = [x["rb20"] for x in A if "rb20" in x]
        B0 = [x["rb20"] for x in Z if "rb20" in x]
        bd = st.mean(B1) - st.mean(B0)
        rng = random.Random(20261102)
        byw = collections.defaultdict(list)
        for x in A + Z:
            byw[x["week"]].append(x)
        pl = []
        for _i in range(5000):
            a1, a0 = [], []
            for g in byw.values():
                sc = [x["score"] for x in g]
                rng.shuffle(sc)
                for x, c in zip(g, sc):
                    (a1 if c == 1 else a0).append(x["w20"])
            pl.append(st.mean(a1) - st.mean(a0))
        pct = sum(p <= d for p in pl) / len(pl) * 100
        nr1 = [x["w20"] for x in A if not x["recognized"]]
        nr0 = [x["w20"] for x in Z if not x["recognized"]]
        nrok = True if len(nr1) < 30 or len(nr0) < 30 else (st.mean(nr1) - st.mean(nr0)) * d > 0
        cond = dict(c1_diff_ge_1_5=d >= 0.015, c2_mean_ge_1_5=m1 >= 0.015, c3_median=dmed, c4_t_ge_1_65=t >= 1.65, c5_beta_diff_ge_1=bd >= 0.01,
                    c6_placebo_ge_95=pct >= 95, c7_unrecognized_sign=nrok)
        res.update(diff=d, mean1=m1, mean0=m0, median1=st.median(x["r20"] for x in A), median0=st.median(x["r20"] for x in Z), t=t, clusters=G,
                   beta_diff=bd, placebo_pct=pct, unrecognized=dict(n1=len(nr1), n0=len(nr0)), conditions=cond,
                   verdict="CONFIRMED" if all(cond.values()) else "NOT CONFIRMED")
    else:
        res["verdict"] = "INCONCLUSIVE"
    res["negative_scores"] = [dict(s=x["s"], score=x["score"], r20=x["r20"]) for x in L if x["score"] < 0]
    Lt = [x for x in out_rows if not x["live"] and "r20" in x]
    res["late"] = dict(n=len(Lt), mean_1=st.mean([x["r20"] for x in Lt if x["score"] == 1]) if any(x["score"] == 1 for x in Lt) else None,
                       mean_0=st.mean([x["r20"] for x in Lt if x["score"] == 0]) if any(x["score"] == 0 for x in Lt) else None)
    for f in ("r5", "r10"):
        a1 = [x[f] for x in A if f in x]
        a0 = [x[f] for x in Z if f in x]
        res[f"diff_{f}"] = st.mean(a1) - st.mean(a0) if a1 and a0 else None
    strict1 = [x["w20"] for x in A if x.get("analysts") is None or x["analysts"] <= 2]
    strict0 = [x["w20"] for x in Z if x.get("analysts") is None or x["analysts"] <= 2]
    res["analysts_le_2_subset"] = dict(n1=len(strict1), n0=len(strict0), diff=st.mean(strict1) - st.mean(strict0) if strict1 and strict0 else None)
    res["delisted_20d"] = sum(x.get("delisted20", False) for x in L)
    res["event_status"] = dict(collections.Counter(x["status"] for x in event_rows()))
    with open(os.path.join(ROOT, "final_results.json"), "w") as f:
        json.dump(dict(summary=res, rows=out_rows), f, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("prepare")
    p.add_argument("--asof")
    p.add_argument("--limit", type=int)
    p.add_argument("--dry", action="store_true")
    p = sub.add_parser("ingest")
    p.add_argument("--reads", required=True)
    p.add_argument("--asof", required=True)
    p = sub.add_parser("publish")
    p.add_argument("--asof", required=True)
    sub.add_parser("status")
    sub.add_parser("score")
    a = ap.parse_args()
    dict(prepare=prepare, ingest=ingest, publish=publish, status=status, score=score)[a.cmd](a)

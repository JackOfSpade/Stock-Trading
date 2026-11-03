"""Score the stage 4 L3 reader test exactly as stage4_L3_preregistration.md specifies.

Usage: stage4_L3_score.py <key.json> <workflow transcript dir> <output json>
"""
import collections
import datetime as dt
import glob
import json
import math
import random
import statistics as st
import sys

key = {x["id"]: x for x in json.load(open(sys.argv[1]))}
wf = sys.argv[2]

first, retest = {}, {}
for line in open(f"{wf}/journal.jsonl"):
    d = json.loads(line)
    if d.get("type") != "result" or not isinstance(d.get("result"), dict):
        continue
    label = d.get("label") or ""
    meta = None
    r = d["result"]
    if "score" not in r:
        continue
    d["_r"] = r
    first.setdefault("_raw", []).append(r)
raw = first.pop("_raw")

# The journal stores results in completion order, so take labels from each agent's own prompt.
audit = collections.Counter()
models = collections.Counter()
for p in glob.glob(f"{wf}/agent-*.jsonl"):
    meta = json.load(open(p.replace(".jsonl", ".meta.json")))
    label = meta.get("description", "")
    tag, _, hid = label.partition(":")
    res = None
    tools = []
    for line in open(p):
        r = json.loads(line)
        if r.get("type") != "assistant":
            continue
        m = r.get("message") or {}
        models[m.get("model")] += 1
        for b in m.get("content") or []:
            if isinstance(b, dict) and b.get("type") == "tool_use":
                tools.append(b["name"])
                if b["name"] == "StructuredOutput":
                    res = b["input"]
    audit[tuple(sorted(tools))] += 1
    if res:
        (first if tag == "read" else retest)[hid] = res

rows = []
for hid, r in first.items():
    k = key[hid]
    rows.append(dict(id=hid, s=k["s"], d=k["d"], entry=k["entry"], reaction=k["reaction"], r5=k["r5"], r10=k["r10"], r20=k["r20"],
                     score=r["score"], recognized=r["recognized_company"], reason=r["reason"],
                     week="%d-%02d" % dt.date.fromisoformat(k["entry"]).isocalendar()[:2]))


def wins(vals):
    v = sorted(vals)
    lo, hi = v[int(0.01 * (len(v) - 1))], v[math.ceil(0.99 * (len(v) - 1))]
    return lambda x: min(hi, max(lo, x))


W = wins([x["r20"] for x in rows])
for x in rows:
    x["w20"] = W(x["r20"])


def spread(rs, sig, field="w20"):
    L = [x[field] for x in rs if sig(x) > 0]
    S = [x[field] for x in rs if sig(x) < 0]
    if not L or not S:
        return None, len(L), len(S)
    return st.mean(L) - st.mean(S), len(L), len(S)


def clustered_t(rs, sig, field="w20"):
    # Regress return on a +1/-1 side indicator, with cluster-robust variance by entry week.
    R = [x for x in rs if sig(x) != 0]
    z = [1 if sig(x) > 0 else 0 for x in R]
    y = [x[field] for x in R]
    n = len(R)
    zb, yb = st.mean(z), st.mean(y)
    Szz = sum((a - zb) ** 2 for a in z)
    b = sum((a - zb) * (c - yb) for a, c in zip(z, y)) / Szz
    a0 = yb - b * zb
    cl = collections.defaultdict(float)
    for x, a, c in zip(R, z, y):
        cl[x["week"]] += (a - zb) * (c - a0 - b * a)
    G = len(cl)
    var = sum(v ** 2 for v in cl.values()) / Szz ** 2 * (G / (G - 1)) * ((n - 1) / (n - 2))
    return b, b / math.sqrt(var), G


score = lambda x: x["score"]
react = lambda x: 1 if x["reaction"] > 0 else (-1 if x["reaction"] < 0 else 0)
sp, nl, ns = spread(rows, score)
out = dict(n=len(rows), retest_n=len(retest), audit={str(k): v for k, v in audit.items()}, models=dict(models),
           score_counts=dict(collections.Counter(x["score"] for x in rows)),
           recognized=sum(x["recognized"] for x in rows), n_long=nl, n_short=ns)
if nl < 30 or ns < 30:
    out["verdict"] = "INCONCLUSIVE: a group has fewer than 30 events"
b, t, G = clustered_t(rows, score) if nl and ns else (None, None, None)
bs, bl, bsn = spread(rows, react)
rng = random.Random(20261102)
byw = collections.defaultdict(list)
for x in rows:
    byw[x["week"]].append(x)
pl = []
for _ in range(2000):
    s = 0
    Lv, Sv = [], []
    for w, g in byw.items():
        sc = [x["score"] for x in g]
        rng.shuffle(sc)
        for x, c in zip(g, sc):
            if c > 0:
                Lv.append(x["w20"])
            elif c < 0:
                Sv.append(x["w20"])
    pl.append(st.mean(Lv) - st.mean(Sv))
pct = sum(p <= sp for p in pl) / len(pl) * 100
raw_sp = spread(rows, score, "r20")[0]
nr = [x for x in rows if not x["recognized"]]
nr_sp, nr_l, nr_s = spread(nr, score)
c = dict(c1_spread_ge_3=sp >= 0.03, c2_t_ge_165=t >= 1.65, c3_beats_baseline_by_15=(sp - bs) >= 0.015, c4_placebo_ge_95=pct >= 95,
         c5_raw_same_sign=(raw_sp * sp) > 0,
         c6_unrecognized_same_sign=(nr_sp is None or nr_l < 30 or nr_s < 30 or (nr_sp * sp) > 0))
out.update(spread=sp, t_clustered=t, clusters=G, baseline_spread=bs, baseline_n=(bl, bsn), baseline_t=clustered_t(rows, react)[1],
           placebo_pct=pct, raw_spread=raw_sp, unrecognized=dict(spread=nr_sp, n_long=nr_l, n_short=nr_s), conditions=c)
out.setdefault("verdict", "PASS" if all(c.values()) else "FAIL")


def rank(v):
    o = sorted(range(len(v)), key=lambda i: v[i])
    r = [0.0] * len(v)
    i = 0
    while i < len(v):
        j = i
        while j + 1 < len(v) and v[o[j + 1]] == v[o[i]]:
            j += 1
        for k in range(i, j + 1):
            r[o[k]] = (i + j) / 2
        i = j + 1
    return r


def corr(a, b):
    return st.correlation(a, b)


out["rank_corr_score_r20"] = corr(rank([x["score"] for x in rows]), rank([x["w20"] for x in rows]))
out["legs"] = {f"score_{s}": dict(n=sum(x["score"] == s for x in rows),
                                  mean_w20=(st.mean([x["w20"] for x in rows if x["score"] == s]) if any(x["score"] == s for x in rows) else None))
               for s in (-2, -1, 0, 1, 2)}
out["universe_mean_w20"] = st.mean(x["w20"] for x in rows)
out["by_month"] = {m: dict(zip(("spread", "n_long", "n_short"), spread([x for x in rows if x["d"][:7] == m], score)))
                   for m in sorted({x["d"][:7] for x in rows})}
for h in ("r5", "r10"):
    out[f"spread_{h}"] = spread(rows, score, h)[0]
out["score_vs_reaction_sign"] = dict(collections.Counter((x["score"] > 0) - (x["score"] < 0) == react(x) for x in rows if x["score"] != 0))
same = [(first[i]["score"], retest[i]["score"]) for i in retest if i in first]
out["retest"] = dict(n=len(same), exact=sum(a == b for a, b in same), same_sign=sum(((a > 0) - (a < 0)) == ((b > 0) - (b < 0)) for a, b in same),
                     corr=corr([a for a, _ in same], [b for _, b in same]) if len({a for a, _ in same}) > 1 and len({b for _, b in same}) > 1 else None)
out["weeks"] = {w: len(g) for w, g in sorted(byw.items())}
json.dump(dict(summary=out, rows=[{k: v for k, v in x.items()} for x in rows]), open(sys.argv[3], "w"), indent=1)
print(json.dumps(out, indent=1))

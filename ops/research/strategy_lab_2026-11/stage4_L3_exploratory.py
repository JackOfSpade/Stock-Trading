"""Exploratory, NOT pre-registered: score +1 versus score 0, since readers almost never scored below zero.

Anything here is a hypothesis for a forward test, never a pass. Usage: stage4_L3_exploratory.py <stage4_L3_results.json>
"""
import collections
import json
import math
import random
import statistics as st
import sys

rows = json.load(open(sys.argv[1]))["rows"]
A = [x for x in rows if x["score"] == 1]
B = [x for x in rows if x["score"] == 0]


def clustered(rs, field):
    z = [1 if x["score"] == 1 else 0 for x in rs]
    y = [x[field] for x in rs]
    n = len(rs)
    zb, yb = st.mean(z), st.mean(y)
    S = sum((a - zb) ** 2 for a in z)
    b = sum((a - zb) * (c - yb) for a, c in zip(z, y)) / S
    a0 = yb - b * zb
    cl = collections.defaultdict(float)
    for x, a, c in zip(rs, z, y):
        cl[x["week"]] += (a - zb) * (c - a0 - b * a)
    G = len(cl)
    v = sum(u ** 2 for u in cl.values()) / S ** 2 * (G / (G - 1)) * ((n - 1) / (n - 2))
    return b, b / math.sqrt(v), G


rs = A + B
out = {}
for f in ("w20", "r20", "r5", "r10"):
    b, t, G = clustered(rs, f)
    out[f] = dict(diff=b, t=t, clusters=G, mean_1=st.mean(x[f] for x in A), mean_0=st.mean(x[f] for x in B),
                  median_1=st.median(x[f] for x in A), median_0=st.median(x[f] for x in B))
rng = random.Random(1)
byw = collections.defaultdict(list)
for x in rs:
    byw[x["week"]].append(x)
obs = out["w20"]["diff"]
pl = []
for _ in range(5000):
    L, Z = [], []
    for g in byw.values():
        sc = [x["score"] for x in g]
        rng.shuffle(sc)
        for x, c in zip(g, sc):
            (L if c == 1 else Z).append(x["w20"])
    pl.append(st.mean(L) - st.mean(Z))
out["placebo_pct"] = sum(p <= obs for p in pl) / len(pl) * 100
out["hit_rate_1"] = sum(x["r20"] > 0 for x in A) / len(A)
out["hit_rate_0"] = sum(x["r20"] > 0 for x in B) / len(B)
srt = sorted(A, key=lambda x: -x["r20"])
out["top_winners_1"] = [(x["s"], round(x["r20"], 3)) for x in srt[:6]]
out["worst_1"] = [(x["s"], round(x["r20"], 3)) for x in srt[-4:]]
for k in (1, 3, 5):
    t = srt[k:]
    out[f"mean_1_drop_top_{k}"] = st.mean(x["r20"] for x in t)
for lab, f in (("reaction_up", lambda x: x["reaction"] > 0), ("reaction_down", lambda x: x["reaction"] < 0)):
    a = [x["w20"] for x in A if f(x)]
    b = [x["w20"] for x in B if f(x)]
    out[lab] = dict(n1=len(a), n0=len(b), mean1=st.mean(a), mean0=st.mean(b))
mid = st.median(abs(x["reaction"]) for x in rs)
for lab, f in (("big_move", lambda x: abs(x["reaction"]) >= mid), ("small_move", lambda x: abs(x["reaction"]) < mid)):
    a = [x["w20"] for x in A if f(x)]
    b = [x["w20"] for x in B if f(x)]
    out[lab] = dict(n1=len(a), n0=len(b), mean1=st.mean(a), mean0=st.mean(b))
for G in sorted({x["d"][:7] for x in rs}):
    a = [x["w20"] for x in A if x["d"][:7] == G]
    b = [x["w20"] for x in B if x["d"][:7] == G]
    out[G] = dict(n1=len(a), n0=len(b), mean1=st.mean(a) if a else None, mean0=st.mean(b) if b else None)
weeks = {}
for w in sorted(byw):
    a = [x["w20"] for x in A if x["week"] == w]
    b = [x["w20"] for x in B if x["week"] == w]
    weeks[w] = (len(a), len(b), round(st.mean(a), 4) if a else None, round(st.mean(b), 4) if b else None)
out["by_week"] = weeks
out["net_long_leg_at_cost"] = {str(c): st.mean(x["w20"] for x in A) - c for c in (0.0084, 0.0147, 0.0209)}
print(json.dumps(out, indent=1))

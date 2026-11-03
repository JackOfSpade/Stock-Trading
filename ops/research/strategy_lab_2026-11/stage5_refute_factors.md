# Stage 5 refutation, lens: factor explanation

All of this is post hoc. Sample labels: A = the 300, H = the 80 holdout, P = pooled. Gaps are score +1 minus score 0, in percentage points of 20-day return net of IWM unless stated.

**Result:** factors do not explain the gap, but the holdout's support is thin for other reasons. Verdict for this lens: WEAKENED. Section 10 has the conclusion.

## Feature code

All later steps in this file exec the block below. Characteristics use data through close(i-1), the last close before the event, so nothing from the reaction or the holding period leaks in.

<!--FEAT-->
```python
import json, bisect, math, re, os, collections
import numpy as np, pandas as pd
T = "/private/tmp/claude-501/-Users-jack--claude-spares-spare-YOT00C/df96b944-d471-4a74-83f8-15366b3d403b/scratchpad/t3"
R = "/Users/jack/Desktop/My Apps/Stock-Trading/ops/research/strategy_lab_2026-11"

def loadpx(s):
    rows = json.load(open(f"{T}/px/{s}.json"))["data"]["tradesTable"]["rows"]
    o = []
    for r in rows:
        try:
            m, d, y = r["date"].split("/")
            g = lambda k: float(r[k].replace("$", "").replace(",", ""))
            def n(k):
                try: return g(k)
                except Exception: return float("nan")
            o.append((f"{y}-{m}-{d}", g("open"), g("close"), n("volume"), n("high"), n("low")))
        except Exception:
            pass
    return pd.DataFrame(sorted(o), columns="date open close volume high low".split()).set_index("date")

PX = {f[:-5]: loadpx(f[:-5]) for f in sorted(os.listdir(f"{T}/px"))}
IWM = PX["IWM"]
iwc = IWM.close.pct_change()
WIN = 40  # trailing trading days

def chars_asof(s, last):
    """Characteristics of s using closes up to and including date `last`."""
    p = PX[s]
    p = p[p.index <= last]
    if len(p) < 21:
        return None
    w = p.iloc[-(WIN + 1):]
    r = w.close.pct_change().dropna()
    m = iwc.reindex(r.index)
    ml = iwc.shift(1).reindex(r.index)
    ok = m.notna() & ml.notna()
    X = np.column_stack([np.ones(ok.sum()), m[ok]])
    b = np.linalg.lstsq(X, r[ok].values, rcond=None)[0]
    res = r[ok].values - X @ b
    X2 = np.column_stack([np.ones(ok.sum()), m[ok], ml[ok]])
    b2 = np.linalg.lstsq(X2, r[ok].values, rcond=None)[0]
    close = p.close.values
    def mom(n):
        if len(close) <= n: return np.nan
        a, z = p.index[-n - 1], p.index[-1]
        return close[-1] / close[-n - 1] - 1 - (IWM.close[z] / IWM.close[a] - 1)
    dv = (w.close * w.volume).iloc[-20:]
    return dict(beta=b[1], dimson=b2[1] + b2[2], vol=r.std() * math.sqrt(252), ivol=res.std() * math.sqrt(252),
                mom20=mom(20), mom40=mom(min(40, len(close) - 1)), dv=dv.median(), price=close[-1],
                amihud=(r.abs() / (w.close * w.volume).reindex(r.index)).replace(np.inf, np.nan).mean() * 1e6,
                nwin=len(r), bigmove=int((r.abs() > 0.4).sum()))

def window(s, entry, h=20):
    p = PX[s]
    ds = list(p.index)
    if entry not in p.index: return None
    a = ds.index(entry)
    if a + h >= len(ds): return None
    ex = ds[a + h]
    if ex not in IWM.index: return None
    return p.open.iloc[a + h] / p.open.iloc[a] - 1, IWM.open[ex] / IWM.open[entry] - 1, ex

def wins(v):
    s = sorted(v)
    lo, hi = s[int(0.01 * (len(s) - 1))], s[math.ceil(0.99 * (len(s) - 1))]
    return lambda x: min(hi, max(lo, x))

A = json.load(open(f"{R}/stage4_L3_results.json"))["rows"]
H = json.load(open(f"{R}/stage4_L3_holdout_results.json"))
for x in H: x["recognized"] = x.get("rec")
KA = {x["id"]: x for x in json.load(open(f"{T}/secure/key.json"))}
KH = {x["id"]: x for x in json.load(open(f"{T}/secure_h/key.json"))}
WH = wins([x["r20"] for x in H])
rec = []
for samp, rows, K, pack in (("A", A, KA, "pack"), ("H", H, KH, "pack_h")):
    for x in rows:
        k = K[x["id"]]
        p = PX[x["s"]]; ds = list(p.index)
        i = bisect.bisect_left(ds, x["d"])
        c = chars_asof(x["s"], ds[i - 1])
        w = window(x["s"], x["entry"])
        d = dict(samp=samp, id=x["id"], s=x["s"], d=x["d"], entry=x["entry"], exit=w[2], score=x["score"], week=x["week"],
                 rec=bool(x["recognized"]), reaction=x["reaction"], r5=x["r5"], r10=x["r10"], r20=x["r20"],
                 w20=x["w20"] if samp == "A" else WH(x["r20"]), rs=w[0], ri=w[1], mc=k["mc"], ne=k["ne"], preok=i - 1)
        d.update(c)
        rec.append(d)
D = pd.DataFrame(rec)
D["lmc"] = np.log(D.mc); D["ldv"] = np.log(D.dv); D["lpx"] = np.log(D.price); D["absreact"] = D.reaction.abs()
D["lamihud"] = np.log(D.amihud.clip(lower=1e-9))
D["ones"] = D.score == 1

SECT = {
 "bank": r"net interest margin|net interest income|deposit|loan growth|allowance for credit|nonperforming|non-performing",
 "insurance": r"combined ratio|premiums? written|underwriting|policyholder|reinsurance",
 "reit": r"funds from operations|\bffo\b|same-store noi|\bnoi\b|occupancy|cap rate|tenant",
 "biotech": r"clinical|phase [123i]|\bfda\b|patients?|trial|pivotal|\bnda\b|\bbla\b",
 "medtech": r"reimbursement|surgeon|procedure volume|medical device|hospital|510\(k\)",
 "energy": r"barrels?|\bboe\b|drilling|rigs?\b|midstream|permian|natural gas|lng\b|refin",
 "mining": r"ounces?|\baisc\b|all-in sustaining|tonnes?|\bmine\b|\bmill\b|lithium|uranium|copper",
 "software": r"\barr\b|saas|annual recurring|subscription|net retention|platform|\bcloud\b",
 "semi_hw": r"semiconductor|wafer|fab\b|data center|chips?\b|photonics|optical",
 "consumer": r"same-store sales|comparable sales|comp sales|restaurant|guest|apparel|retail|e-commerce|consumer",
 "industrial": r"backlog|book-to-bill|aftermarket|manufacturing|fleet|tons?\b|freight|industrial|defense",
}
def sector(t):
    t = t.lower()
    n = max(len(t) / 1000, 1)
    sc = {k: len(re.findall(v, t)) / n for k, v in SECT.items()}
    k = max(sc, key=sc.get)
    return k if sc[k] >= 0.25 else "other"
secs = {}
for samp, pack in (("A", "pack"), ("H", "pack_h")):
    for i in D[D.samp == samp].id:
        secs[i] = sector(open(f"{T}/{pack}/{i}.txt").read())
D["sector"] = D.id.map(secs)

def ols_cl(df, y, xs, fe=None, cl="week", wild=0, seed=7):
    """OLS with CR1 cluster SE on `ones` first. Optionally FE dummies; optional wild cluster bootstrap p for first regressor."""
    d = df.dropna(subset=[y] + xs).copy()
    Xc = [np.ones(len(d))] + [d[c].astype(float).values for c in xs]
    names = ["const"] + xs
    if fe:
        dm = pd.get_dummies(d[fe], drop_first=True).astype(float)
        for c in dm: Xc.append(dm[c].values); names.append(f"fe_{c}")
    X = np.column_stack(Xc); Y = d[y].astype(float).values
    XtXi = np.linalg.pinv(X.T @ X)
    b = XtXi @ X.T @ Y
    e = Y - X @ b
    groups = d[cl].values
    G = len(set(groups)); n, k = X.shape
    def se_of(e):
        M = np.zeros((k, k))
        for g in set(groups):
            ix = groups == g
            u = X[ix].T @ e[ix]
            M += np.outer(u, u)
        V = XtXi @ M @ XtXi * (G / (G - 1)) * ((n - 1) / (n - k))
        return np.sqrt(np.diag(V))
    se = se_of(e)
    out = dict(b=b[1], se=se[1], t=b[1] / se[1], n=n, G=G, coef=dict(zip(names, b)), ts=dict(zip(names, b / se)))
    if wild:
        rng = np.random.default_rng(seed)
        X0 = np.delete(X, 1, axis=1)
        b0 = np.linalg.lstsq(X0, Y, rcond=None)[0]
        fit0 = X0 @ b0; e0 = Y - fit0
        gl = sorted(set(groups)); idx = np.array([gl.index(g) for g in groups])
        webb = np.array([-math.sqrt(1.5), -1, -math.sqrt(.5), math.sqrt(.5), 1, math.sqrt(1.5)])
        cnt = 0
        for _ in range(wild):
            w = rng.choice(webb, len(gl))
            Ys = fit0 + e0 * w[idx]
            bs = XtXi @ X.T @ Ys
            ts = bs[1] / se_of(Ys - X @ bs)[1]
            cnt += abs(ts) >= abs(out["t"])
        out["wild_p"] = cnt / wild
    return out

def S(k):
    d = D[D.score.isin([0, 1])]
    return d if k == "P" else d[d.samp == k]
```
<!--/FEAT-->

The later steps ran as inline scripts that exec this block, so no other file was written. Their methods are described in each section.

Definitions:
- Beta, Dimson beta, vol and idiosyncratic vol use 40 daily returns ending at close(i-1). 22 is the shortest window, and almost all events have 40.
- mom20 and mom40 are net of IWM.
- Dollar volume is the 20-day median. Price is close(i-1).
- Clustered t is CR1 by entry week. Wild p is a Webb-weight wild cluster bootstrap (999 to 2,000 draws) with the null imposed, because 11-12 unbalanced clusters flatter the t.
- All gaps compare +1 with 0. The four -1 events (1 in A, 3 in H) are left out.
- A is winsorized as in the scoring script. The same rule on H clips nothing, because at n=80 the 1% and 99% indices are the minimum and maximum. So H is effectively unwinsorized. P keeps each sample's own values; winsorizing across the pooled sample gives +2.71% (t 1.84, wild p 0.062).

Data check: `r20` recomputes exactly from the price files (maximum difference 0). There are no duplicate events, and one ticker appears in both A and H. One holding-window move above 40% (HZO +47%) is in score 0, so it works against the finding.

## 1. Baseline

| sample | +1 / 0 | gap | clustered t | wild p |
|---|---|---|---|---|
| A | 80 / 219 | +2.87% | 2.55 | 0.017-0.019 |
| H | 22 / 55 | +2.03% | 0.57 | 0.59 |
| P | 102 / 274 | +2.69% | 1.81 | 0.067-0.070 |

## 2. Does +1 tilt on a characteristic?

Means, with the within-week difference and its t. Mann-Whitney p is in brackets.

| characteristic | A +1 / 0 | A wk t | H +1 / 0 | H wk t | P +1 / 0 | P wk t (MW p) |
|---|---|---|---|---|---|---|
| beta | 0.85 / 0.82 | -0.35 | 1.28 / 1.05 | 0.50 | 0.94 / 0.87 | 0.20 (0.77) |
| median beta | 0.54 / 0.60 | | 0.75 / 0.76 | | 0.57 / 0.63 | |
| Dimson beta | 0.94 / 0.85 | 0.32 | 1.26 / 1.04 | 0.54 | 1.01 / 0.89 | 0.59 (0.85) |
| vol | 0.478 / 0.485 | -0.97 | 0.509 / 0.523 | -0.42 | 0.485 / 0.493 | -0.86 (0.91) |
| idiosyncratic vol | 0.436 / 0.446 | -1.11 | 0.445 / 0.471 | -0.75 | 0.438 / 0.451 | -1.19 (0.92) |
| mom20 | +1.0% / +0.7% | 0.48 | -0.1% / -0.6% | 0.60 | +0.8% / +0.4% | 0.60 (0.83) |
| mom40 | +2.4% / -0.9% | 1.90 | -0.2% / -4.9% | 3.12 | +1.8% / -1.7% | 2.30 (0.17) |
| reaction | +0.1% / +2.4% | -1.82 | +0.1% / +0.8% | -0.35 | +0.1% / +2.1% | -1.49 (0.16) |
| abs. reaction | 8.9% / 9.3% | -0.62 | 9.6% / 8.5% | 0.42 | 9.1% / 9.2% | -0.34 (0.97) |
| log snapshot market cap (median $M) | 858 / 768 | 1.91 | 835 / 809 | 0.08 | 858 / 777 | 1.55 (0.34) |
| log point-in-time cap estimate (median $M) | 877 / 850 | 1.42 | 795 / 1015 | -0.75 | 837 / 856 | 0.84 |
| estimate count | 1.64 / 1.52 | 1.83 | 1.32 / 1.47 | -1.19 | 1.57 / 1.51 | 1.52 (0.32) |
| log dollar volume (median $M) | 7.4 / 6.2 | 0.27 | 8.0 / 7.9 | -0.70 | 7.4 / 7.1 | -0.05 (0.85) |
| log price (median $) | 19.6 / 16.1 | 4.42 | 19.2 / 12.6 | 2.47 | 19.6 / 15.4 | 6.10 (0.019) |
| Amihud illiquidity (log) | -5.81 / -5.82 | -0.22 | -5.87 / -6.03 | 1.06 | -5.82 / -5.86 | 0.06 (0.96) |
| EPS beat rate | 64% / 61% | 0.72 | 64% / 51% | 0.84 | 64% / 59% | 0.90 |
| recognized by reader | 90% / 91% | | 91% / 93% | | 90% / 92% | |

Findings:
- The only consistent tilts are a higher share price (about 33% higher in P) and somewhat higher 40-day momentum. Everything else is near zero.
- There is no beta or volatility tilt in A or P.
- H has a mean-beta tilt of +0.23 that comes from a few extreme names, and the medians are equal.

Realized over the holding window (look-ahead, diagnostic only), +1 versus 0:
- Beta: A 1.03 / 0.98 (t -0.03), H 1.74 / 1.20 (t 2.24), P 1.18 / 1.03 (t 1.05).
- Vol: A t -0.74, H t 1.21, P t 0.25.

So in H the +1 names did behave as higher beta after the fact, while IWM was falling. That works against the finding, not for it.

## 3. Could a tilt alone give 2-3%?

**The period.** IWM fell over most holding windows. Mean 20-day IWM return by entry period:
- Weeks up to 31: +2.2%
- Weeks 32-33: -2.5%
- Weeks 34 onward: -4.7%
- Whole sample: -2.0%

So on IWM-net returns, a beta below 1 earns a mechanical boost.

**Arithmetic.** A 2.5% gap from beta alone would need the +1 group's beta to be about 1.14 below the 0 group's, given a mean IWM return of -2.2%. The within-week beta tilt is:
- A: -0.03, 95% CI -0.22 to +0.16, worth +0.42% to -0.30%
- H: +0.16, CI -0.55 to +0.86, worth +1.26% to -2.00%
- P: +0.02, CI -0.21 to +0.26, worth +0.42% to -0.51%

**Event-level beta drag**, mean of (beta-1) × IWM return, +1 minus 0. This includes timing covariance, not only mean beta.
- A: +0.74% raw, +0.48% Dimson
- H: -0.58%, -0.93%
- P: +0.44%, +0.16%

This is the largest factor contribution I found in A, about a quarter of A's gap. It reverses in H.

**Tilt × premium.** Premia were estimated on score 0 only, with week fixed effects, on 10 characteristics jointly. Predicted within-week gap against actual:
- A: -0.36% against +2.64%
- H: +0.67% against +2.35%
- P: -0.39% against +2.67%

The largest single contribution is price, and in A and P it goes the wrong way (A -0.72%, P -0.42%, H +1.08%). A higher price predicts lower returns among score 0 names.

**Worst case for one factor**, taking the CI edge of the tilt times the CI edge of the premium:
- P: 0.3-1.3% per factor (beta 0.95, vol 0.71, mom40 0.57, price 1.00, estimate count 1.27)
- A: 0.5-1.9%
- H: 0.3-5.0%, so uninformative because its intervals are too wide

No single factor at its worst case reaches the pooled gap.

**By market state.**
- IWM up windows: A +2.91%, H -0.41% (n=4 / 12), P +2.26%
- IWM down windows: A +2.86%, H +2.60%, P +2.81%

The gap does not switch on and off with the market, as a beta story would predict.

**Terciles (P).** The gap is positive in all three terciles of beta, vol, mom20, mom40, price, dollar volume, reaction and abs. reaction. It is negative in only one size cell (middle market cap, -1.4%). The gap is largest in high vol (+4.6%, against +2.0% and +1.8%), and H's gaps there are noisy.

Score 0 vol premium, high minus low: +1.5%. With a tilt of about zero, that contributes nothing.

## 4. Regression of the 20-day return on +1

Controls in the "all" row: beta, vol, mom20, mom40, reaction, abs. reaction, log snapshot cap, log dollar volume, log price, estimate count.

| controls | A | H | P |
|---|---|---|---|
| none | +2.87 (t 2.55, p 0.017) | +2.03 (0.57, 0.60) | +2.69 (1.81, 0.070) |
| none + week FE | +2.70 (2.40, 0.013) | +2.47 (0.61, 0.54) | +2.73 (1.73, 0.085) |
| none + sector FE | +2.92 (2.22, 0.069) | +1.65 (0.44, 0.70) | +2.99 (1.89, 0.071) |
| beta | +2.89 (2.45) | +2.12 (0.60) | +2.74 (1.78) |
| beta + vol | +2.93 (2.55) | +2.32 (0.69) | +2.82 (1.86) |
| momentum | +2.87 (2.41) | +2.32 (0.65) | +2.73 (1.80) |
| reaction | +2.78 (2.37) | +1.73 (0.54) | +2.64 (1.78) |
| size + dollar volume | +2.85 (2.50) | +1.95 (0.55) | +2.65 (1.79) |
| price | +3.29 (3.04) | +1.87 (0.51) | +3.02 (2.13) |
| all | +3.21 (2.41, 0.029) | +0.91 (0.34, 0.75) | +3.02 (2.03, 0.037) |
| all + week FE | +3.24 (2.60, 0.010) | +1.71 (0.51, 0.60) | +3.23 (2.05, 0.024) |
| all + sector FE | +3.17 (1.95, 0.107) | +0.26 (0.08, 0.96) | +3.24 (2.07, 0.029) |
| all + week + sector FE | +3.35 (2.01, 0.096) | +3.04 (0.72, 0.45) | +3.51 (2.03, 0.041) |
| all with point-in-time size, week FE | +3.41 (2.72, 0.002) | +1.52 (0.41, 0.69) | +3.28 (2.00, 0.028) |
| all without size, week FE | +3.32 (2.65, 0.008) | +1.69 (0.49, 0.63) | +3.29 (2.03, 0.025) |
| all + EPS beat + surprise, week FE | +3.35 (2.75, 0.007) | +1.97 (0.72, 0.43) | +3.38 (2.08, 0.025) |

Findings:
- In A and P, controls leave the gap the same or larger and improve the t. Part of that is price acting as a suppressor.
- In H the coefficient moves between +0.26 and +3.04 depending on the specification. With 77 events and 10-plus controls, H cannot separate these.
- Pooled control coefficients (all + week FE) are not factor loadings that explain anything: beta -1.4% per unit (t -1.2), vol +1.9% (t 0.8), mom20 -0.098 (t -1.7), price -1.0% per log unit (t -2.3).

Sector rule: the highest keyword-per-1,000-characters rate across 11 lists, or "other" when below 0.25. It is a crude rule and I did not validate it by hand.
- Sector mix differs little: chi-squared p is A 0.18, H 0.08, P 0.22.
- Sector-mix effect on the gap, using score 0 sector means: A -0.70%, H -0.41%, P -0.70%, so sector mix works against the finding.
- Leave-one-sector-out P range: +1.80% (without consumer) to +3.30%. H range: +0.52% (without industrial) to +2.96%.
- Largest within-sector gaps in P: consumer +7.44% (n=17 / 36), industrial +5.01% (22 / 56). Banks, software, biotech and "other" are about zero or slightly negative. The effect is not broad across sectors, though cells are small.

## 5. Beta-adjusted returns

r_stock - b × r_IWM, winsorized within each sample.

| b | A gap | H gap | P gap | P medians +1 / 0 |
|---|---|---|---|---|
| 1 (reported) | +2.87 (t 2.55, p 0.017) | +2.03 (0.57, 0.60) | +2.69 (1.81, 0.070) | +2.40 / -0.47 |
| 0 (raw return) | +2.44 (1.89, 0.089) | +1.89 (0.55, 0.60) | +2.32 (1.49, 0.172) | -0.11 / -1.73 |
| pre-event beta | +2.17 (1.50, 0.257) | +2.61 (0.59, 0.58) | +2.28 (1.24, 0.271) | +1.14 / -0.14 |
| Dimson beta | +2.44 (1.75, 0.169) | +2.96 (0.68, 0.53) | +2.56 (1.44, 0.206) | +1.37 / -0.56 |
| shrunk 0.5b + 0.5 | +2.58 (2.12, 0.037) | +2.32 (0.59, 0.59) | +2.53 (1.56, 0.150) | +1.77 / -0.03 |
| beta clipped to 0-2.5 | +2.35 (1.76, 0.148) | +2.08 (0.54, 0.61) | +2.30 (1.38, 0.222) | +0.89 / -0.09 |
| realized holding beta (look-ahead) | +2.30 (1.92, 0.094) | +3.30 (0.87, 0.39) | +2.54 (1.59, 0.139) | +1.54 / +0.31 |

This is the one place the statistics degrade materially, and it needs a fair reading:
- The size barely moves. A falls by up to 0.70 points (the mechanical piece from section 3), H rises, and P falls by 0.13-0.41.
- The t falls because the standard errors rise and the point estimate falls. 40-day betas are noisy, running from -2.0 to +6.2, and multiplying them by a -2% to -5% IWM return adds noise.
- The cleanest evidence for that reading is the matched benchmark in section 6, which uses the same-window returns of similar names instead of a noisy scalar beta. There the gap and t hold up.
- Even so, no beta-adjusted pooled version reaches t 1.65 or wild p 0.10. A skeptic may fairly say significance does not survive beta adjustment, even though the size does.

H's three confirmation conditions all still hold under all four pre-event beta variants and under week demeaning.

## 6. Matched benchmark and calendar-time factors

**Same-window characteristic match.** For each event, I took the 10 nearest names by standardized characteristics, as of that event's own pre-event date, from a pool excluding all 102 +1 names (277 names). The benchmark is their same-window IWM-net open-to-open return, clipped at -60% and +80%.

| match on | A benchmark gap, adj. gap | H benchmark gap, adj. gap | P benchmark gap, adj. gap |
|---|---|---|---|
| beta | +0.06, +2.79 (2.18, 0.065) | -0.72, +2.75 (0.72, 0.48) | -0.11, +2.79 (1.81, 0.039) |
| vol | -0.02, +2.90 (1.80, 0.128) | +0.25, +1.78 (0.45, 0.68) | +0.04, +2.67 (1.40, 0.267) |
| beta + vol | -0.52, +3.45 (3.39, 0.035) | -0.50, +2.53 (0.59, 0.57) | -0.52, +3.27 (2.21, 0.034) |
| momentum | -0.05, +2.86 (2.39, 0.018) | -0.05, +2.09 (0.65, 0.52) | -0.05, +2.69 (1.83, 0.064) |
| size + dollar volume | +0.28, +2.55 (1.75, 0.137) | +1.73, +0.30 (0.09, 0.95) | +0.57, +2.09 (1.28, 0.271) |
| price | +0.20, +2.70 (2.39, 0.043) | -1.50, +3.53 (0.98, 0.31) | -0.17, +2.89 (2.03, 0.022) |
| all seven | -0.93, +3.69 (3.14, 0.052) | +0.58, +1.45 (0.55, 0.59) | -0.62, +3.23 (2.62, 0.039) |

The benchmark difference is the amount a factor explanation can claim. In A and P it never exceeds +0.57 points, and it is usually about zero or negative. Two H cells fall below the 1.5% condition (size + dollar volume +0.30, all seven +1.45), but H's benchmark differences are themselves mostly noise.

**Calendar-time.** Daily equal-weight long +1 minus long 0, regressed on IWM and tercile factors formed on 2026-06-30 characteristics. Clean factors use only non +1 names (273 names). Alpha is scaled to 20 days; Newey-West 5 lags. The days are few (32-55) and the factors come from the same small pool, so treat this as weak.

| sample, minimum names per side | days | IWM only | + VOL | + VOL, MOM, SIZE, PRICE |
|---|---|---|---|---|
| A, 5 | 44 | +3.71 (1.71) | +2.08 (1.04), VOL load 0.23 (t 1.0) | +3.82 (1.89) |
| A, 10 | 32 | +3.16 (2.40) | +2.76 (2.12), load 0.07 | +3.65 (4.69) |
| H, 3 | 38 | +11.01 (1.53) | +10.38 (1.18) | +3.62 (0.78) |
| P, 5 | 51 | +6.46 (2.84) | +4.97 (2.30), load 0.24 (t 1.4) | +6.92 (3.20) |
| P, 10 | 37 | +4.19 (2.15) | +4.39 (1.89), load -0.03 | +4.56 (3.39) |

- The VOL factor was the one that moved during the period: about +10.6% from Aug 1 to Oct 6 while IWM fell 3.4%. The A, 5-name specification has the most damaging result, with alpha falling by 44% and t 1.04. But it does not hold with a 10-name minimum, and the fuller model restores the alpha.
- Day-weighted alphas exceed event-level gaps because they give the thin late-season days the same weight as peak days.
- The first run used factors contaminated by +1 names, with Newey-West 20 lags on 44 days. It gave A + VOL +1.68 (t 1.01), and the conclusion is the same.

**Stratified permutation**, one-sided p, 5,000 draws, permuting labels within strata.

| strata | A | H | P |
|---|---|---|---|
| week | 0.037 | 0.208 | 0.019 |
| week × vol tercile | 0.104 | 0.441 | 0.058 |
| period × beta tercile | 0.032 | 0.261 | 0.031 |
| period × vol tercile | 0.031 | 0.255 | 0.029 |
| period × price tercile | 0.024 | 0.242 | 0.020 |
| period × mom40 tercile | 0.049 | 0.095 | 0.036 |
| sector × period | 0.017 | 0.301 | 0.021 |

Periods are weeks up to 31, 32-33, and 34 onward. Week × vol cells are thin, so that row has few effective permutations, and it is the only one that weakens P noticeably.

**EPS surprise (post-earnings drift).** This is the classic factor a reader could be capturing. There is no meaningful tilt (beat rate above), and controlling for it does not reduce the gap. EPS beat is not itself a positive predictor here: beat alone is -1.18% in P (t -1.02).

An unplanned result: the gap exists only among EPS beats.
- Beats: A +4.86%, H +2.63%, P +4.44%
- Misses: A -0.39%, H +0.91%, P -0.07%
- Interaction: A +5.25 (t 2.83, wild p 0.115), H +1.72 (t 0.40), P +4.51 (t 2.35, wild p 0.139)

This is one of about 400 cuts. Treat it as a hypothesis only.

## 7. Where the holdout gap comes from (not a factor effect, but this is the main weakness I found)

| entry weeks | A +1 / 0, gap | H +1 / 0, gap | P +1 / 0, gap | P medians +1 / 0 |
|---|---|---|---|---|
| up to 31 | 13 / 43, +3.11 | 4 / 11, +1.10 | 17 / 54, +2.63 | +1.33 / -0.94 |
| 32-33 (65% of events) | 54 / 144, +2.08 | 14 / 34, **-3.08** | 68 / 178, +1.04 | +1.00 / +0.07 |
| 34 onward | 13 / 32, +5.81 | 4 / 10, **+20.58** | 17 / 42, +9.29 | +5.82 / -1.84 |

- H without weeks 34 onward: gap **-2.09%** (t -1.10), +1 mean **-0.56%**, medians +1.46 / +0.43. That fails holdout conditions 1 and 2 and passes 3. I chose this cut after seeing the weekly table, so it is post hoc.
- P without weeks 34 onward: +1.40% (t 1.28, wild p 0.28). A: +2.32% (t 2.12, wild p 0.067).
- H's four late +1 events: ELMT +23.6% (beta 3.75), ODD +25.6% (2.90), LPTH +11.2% (6.23), NSSC +5.8% (0.81).
- Those three high-beta names rose while IWM fell about 4.7%, so IWM beta cannot be the source. Matched on all seven characteristics, their benchmarks are small (+7.7%, +2.0%, -2.8%) and they remain large winners. This looks idiosyncratic or thematic, not factor.
- Dropping H's top +1 winners (one-sided and harsh):
  - Top 1: gap +0.94%, +1 mean +1.45%
  - Top 2: gap -0.17%, +1 mean +0.34%
  - Top 4: gap -1.41%, +1 mean -0.89%
  - H's +1 median stays positive throughout (+1.46% to +2.86%) and above the score 0 median (-0.22%).
- Week-level A gaps are positive in 8 of 10 weeks with both groups, H in 5 of 8. Equal-weighting weeks: A mean +6.73% (median +4.13%, t 1.54), P mean +8.51% (median +4.36%, t 1.91). Those means are inflated by a single-pair week: week 29 is AEHR +41.6% (+1) against GSBC -0.8% (0).
- The late effect is partly an A pattern too (+5.81%, with medians +5.41 / -1.84), so it is not only H's noise. Late reporters include many off-calendar consumer names, and consumer is the sector with the largest gap. I did not test that further.

## 8. Survivorship and selection

**619 starting events.** 380 got a transcript (61.4%) and 239 did not (38.6%). All 380 then had prices and an exit, so nothing was dropped for that reason. 300 + 80 = 380.

| | transcript (380) | none (239) | test |
|---|---|---|---|
| median market cap | $787M | $733M | MWU p 0.047 |
| mean market cap | $914M | $829M | |
| P25 / P75 | $485M / $1,286M | $450M / $1,083M | |
| estimate count = 2 | 53% | 41% | chi-squared p 0.005 |
| EPS beat | 60% | 51% | chi-squared p 0.041 |

- Transcript rate by market-cap quintile, small to large: 58%, 62%, 54%, 63%, 70%. Only the top quintile stands out.
- Rate by month: July 53%, August 65%, September 67% (p 0.027).
- So names without a transcript are moderately smaller, less covered and less often beat. The difference is real but modest.
- A sample of the missing names includes live, ordinary companies, such as OMCL, AIN, MNKD and PCB. This looks more like a site or matching gap than delisting, but I cannot verify that without network access.

**Returns of the missing.** 106 of the 239 have prices in an earlier stage's cache, plus 185 of the 380. These are not a random sample, and every one traded to 2026-10-30.
- Mean IWM-net 20-day: missing +1.7% (median +0.9%), transcript +1.1% (median -0.1%). Welch p 0.68.
- No sign that the missing group was worse. That does not test the +1 gap, because missing events have no scores.

**Upstream filter (I consider this more important than the transcript split).** The calendar `marketCap` is not point-in-time.
- 543 of the 604 tickers with more than one event show an identical market cap on every date from 2025 to 2026.
- GBX shows $1,209M on both 2025-07-01 and 2026-10-26, for example.
- So the $300M-$2B band was applied using a later snapshot, which depends on the outcome.
- If the snapshot is about current, I estimate 45 of the 380 were outside the band at the event, and 102 were within 25% of a bound. This assumes constant shares and a snapshot at the 2026-10-30 close, which I cannot confirm.
- 200 calendar rows with estimate count <= 2 sit just outside the band ($200-300M: 99, $2-3B: 101), against 620 inside. Some of those were in-band at the event and got dropped because of how they moved afterwards.
- This trims both tails, and nothing suggests it favours +1 over 0. Events at least 25% inside the bounds have gaps of A +3.76%, H +3.73%, P +3.78% (n=276), which is larger than the full sample. But the excluded winners and losers cannot be recovered.
- The snapshot also makes `lmc` a look-ahead control, which is why I re-ran with the point-in-time estimate and with no size control (section 4). Results are the same.

**Other filters.**
- 235 calendar rows in the band have a blank `noOfEsts` and were excluded, which may be exactly the lowest-coverage names.
- Rows missing market cap are rare (23 of 4,694, and only 2 with estimate count <= 2).
- So delisting losses cannot be seen in this data. The price and transcript steps only reach names still quoted, as the pre-registration accepts.

## 9. Comparisons tried

About 399 cells across roughly 60 distinct analyses, counting each sample separately:
- 54 tilt tests
- 60 controlled regressions
- 27 beta-adjusted or condition checks
- 51 tercile cells
- 21 period cuts
- 71 sector cells (mostly descriptive)
- 21 stratified permutations
- 21 matched benchmarks
- 63 calendar-time specifications
- 10 beat or drop-winner cuts

Many are highly correlated. Isolated extreme cells should not be read as evidence in either direction. This includes the price tilt (t 6.10 in P), the +1 × beat interaction, and the H late-week split.

## 10. Conclusion for this lens

**Factors do not explain the gap.** There is no beta or volatility tilt in A or P, and tilt × premium predicts -0.39% in P against +2.67% actual. In A and P the gap is the same or larger under controls and matched benchmarks. Neither a beta nor a volatility tilt alone can plausibly give 2-3% in this period: that would need a beta gap of about 1.14 against a measured one near 0.

**Limits on that conclusion.**
1. The largest mechanical factor piece is +0.74 points in A, about a quarter of A's gap, and it does not appear in H.
2. No beta-adjusted pooled version reaches t 1.65 (P t 1.24 to 1.59), although the size holds at +2.28 to +2.56. I read that mainly as beta noise, but it does mean the significance is not robust.
3. One calendar-time specification with a VOL factor halves A's alpha, though it does not hold under stricter or fuller versions.
4. Controls cannot rule out an unmeasured theme factor, since the sample has 12 entry weeks and one regime. The late-season winners look thematic.

**The evidence is weaker than the headline, for reasons other than factors.** H's pass depends on 4 events in weeks 34 onward and 2 large winners. In weeks 32-33, 65% of events, H's gap is -3.08% and P's is +1.04%. These cuts are post hoc.

Verdict for this lens: WEAKENED. The effect size survives factor adjustment. The confirmation's strength does not survive this inspection.

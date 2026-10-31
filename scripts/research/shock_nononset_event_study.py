#!/usr/bin/env python3
"""Does FIRST-HOP hedged industry drift also follow NON-ONSET rubric-qualifying shock events (2026)?

Companion to scripts/research/shock_episode_event_study.py (the onset study). That study measured the
market-hedged drift of the first-hop petroleum basket after the ONSET of six supply shocks 1990-2026
(+1.9% at 4 weeks pooled, 95th placebo percentile) and nothing else. SL1 rejected candidate I on
2026-10-19 partly because the candidate declared its frequency in qualifying events per year while the
evidence covered onsets only (about 0.17 per year), and the lead
`interactive-2026-10-shock-first-hop-continuation-hedged` carries, as restart condition (1), exactly the
measurement this script makes: placebo-test first-hop hedged drift after EVERY rubric-qualifying event of
2026 (ceasefire collapses, strait closures, strike waves, re-escalations), not just the onset.

Nothing is redesigned. This module IMPORTS the onset study and reuses, unchanged:
  - its link map (BEA 2023 use table; the 7 first-hop industries 211 324 486 213 481 483 22),
  - its price sources (`french` = Kenneth French 49 industries + Fama-French market; `nasdaq` = the ETF /
    stock-basket proxy table with SPY as market), its loaders and the `hop_return_series` construction,
  - its hedging rule (OLS beta over the 252 trading days before the event; CAR over trading days 1..5h
    AFTER the event day, so d0 is the announcement reaction and the CAR is what a day-1 entry could earn),
  - its placebo construction, byte for byte: the same eligibility rule (trading days >= 26 weeks from any
    of the eight listed episodes, 1991+), the same SEED, the same draw order (12 placebo onsets, then the
    500-draw distribution), so the placebo windows are the identical set the onset memo's tables used for
    a given data vintage.

The ONE methodological addition is forced by the calendar: the 2026 events are 1-15 weeks old, so the
longer horizons do not exist yet. `car_profile` in the onset study refuses a window that cannot reach 12
weeks; here `partial_profile` reports every horizon whose 5h trading days are observable and None for the
rest, and every pooled statistic is computed per horizon over the events that have it (n is printed in
every cell). The placebo comparison matches that n: the pooled placebo distribution for horizon h is the
mean of n_h placebo windows drawn without replacement from the 500, 2000 times.

Event list: built from the warehouse, not from memory (the memo's Section 2 cites a row id per event).
It is a constant here so that a re-run reproduces the memo; add a row only with its source row id.

Usage (after the onset study's `linkmap` and `prices` stages have populated <data-dir>):

    python scripts/research/shock_nononset_event_study.py --data-dir <dir> --source nasdaq
    python scripts/research/shock_nononset_event_study.py --data-dir <dir> --source nasdaq --baskets-only
    python scripts/research/shock_nononset_event_study.py --data-dir <dir> --source french

Dependencies: standard library + numpy + pandas (+ the onset module next to this file). No network.
"""

from __future__ import annotations

import argparse
import datetime as dt
import importlib
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
onset = importlib.import_module("shock_episode_event_study")

HORIZONS = onset.HORIZONS_WEEKS  # (1, 2, 4, 6, 8, 12)
MARKET = onset.MARKET
# Two denominators, both reported: the calendar year observed so far (treats Jan-May, when the warehouse
# dated no events, as zero -> an UNDER-count), and the window in which the shock_overlay axis has existed
# and dated events (2026-06-01 .. 2026-10-19, all of it inside an active shock structure -> an OVER-count
# for a calendar year with quiet months).
YEAR_FRACTION_2026 = (dt.date(2026, 10, 19) - dt.date(2026, 1, 1)).days / 365.0  # 0.80
DATED_WINDOW_YEARS = (dt.date(2026, 10, 19) - dt.date(2026, 6, 1)).days / 365.0  # 0.38

# ---------------------------------------------------------------------------------------------------
# The 2026 event list. Every row names the warehouse row it comes from. `d0` = the first trading session
# on/after the development (the session whose close-to-close move carries the news). `brent` = stored
# state.signal_marks_curated BZUSD closes: the session before the event, d0, d0+1 (two-session move is
# the rubric's "> $5/bbl attributable" leg as operationalised in the memo). `tier`:
#   strict  - a dated kinetic / trade-flow development named in the row AND a > $5 Brent leg, or named as
#             THE qualifying event by the live M1a grading (3b6d1923 names 2026-09-11 explicitly);
#   rubric  - qualifies on the rubric's text (oil leg > $5 attributable to a named geopolitical channel,
#             or an explicit trade-flow leg) but the row does not pin a single dated kinetic development,
#             or the live grading did not name it; reported in the primary set and dropped in the strict one.
#   provisional - dates not established in the warehouse (W1 eb64b71d says so); only short horizons exist.
# kind: 'escalation' (oil up / flows cut: the first-hop LONG direction the onset study measured) or
#       'deescalation' (oil down / flows restored: reported sign-flipped, as a sensitivity only).
# ---------------------------------------------------------------------------------------------------
EVENTS = [
    # id, d0, label, kind, tier, source rows, (brent t-1, d0, d0+1)
    ("E1", "2026-07-08", "Ceasefire collapse: US strikes 80+ targets, Iran hits Gulf bases, ceasefire declared over (07-07/08)",
     "escalation", "strict", "decision_log 4d1d251d (router-review 2026-07-08); regime_events 6b16af77", (71.99, 74.16, 78.02)),
    ("E2", "2026-07-13", "IRGC declares Strait of Hormuz closed 'until further notice' (Sun 07-12); two vessels struck",
     "escalation", "strict", "decision_log 99a56801 (2026-07-12), 28b940de (2026-07-14)", (76.01, 83.30, 84.73)),
    ("E3", "2026-07-22", "Resumed strike waves / Gulf shipping attacks: Brent +6% to resumption highs, through $100 next session",
     "escalation", "rubric", "decision_log 5bf282fd (2026-07-22), aed40624 (2026-07-26); regime_events 6b16af77", (91.01, 94.07, 100.69)),
    ("E4", "2026-07-29", "Iranian ballistic-missile attack on US Gulf forces (07-28/29)",
     "escalation", "strict", "regime_events 6b16af77 (M1a 2026-08-01)", (84.09, 90.74, 86.88)),
    ("E5", "2026-08-10", "Iran hardens Hormuz reopening preconditions; energy complex +4-6%, tankers -1.7%",
     "escalation", "rubric", "decision_log a7fde137 (2026-08-10)", (83.55, 87.72, 88.91)),
    ("E6", "2026-08-19", "UAE halts all trade and financial dealings with Iran after missile fire on Emirati maritime targets",
     "escalation", "strict", "regime_events ba8ae2cf (M1a 2026-09-01)", (91.02, 91.62, 93.78)),
    ("E7", "2026-09-09", "Gulf shipping attacks open the September escalation",
     "escalation", "strict", "regime_events 3b6d1923 (M1a 2026-10-01)", (99.39, 101.21, 107.63)),
    ("E8", "2026-09-11", "Drone strikes on Saudi export (East-West) pipeline halt Red Sea loadings of 3.9 mb/d (reported 09-10/11)",
     "escalation", "strict", "regime_events 3b6d1923 (named as the most recent qualifying event); decision_log db7dc01c (09-15 screen)", (107.63, 104.61, 105.68)),
    ("E9", "2026-09-23", "Armed-group blockade of Libya's El Sharara field (about a third of Libyan output) + proposed US diesel-export ban",
     "escalation", "rubric", "decision_log e01d9ca6 (2026-09-23 sector screen)", (98.53, 103.08, 106.60)),
    ("E10", "2026-10-08", "Hormuz tanker strikes 09-28..10-04 (Kpler: 10 tankers; transits 7 on 10-06), Houthi attacks; dates unestablished",
     "escalation", "provisional", "decision_log c2f7afe6 (2026-10-08), eb64b71d (W1 2026-10-11)", (100.20, 104.28, 104.72)),
    ("D1", "2026-06-15", "Mid-June ceasefire framework restores near-normal Hormuz flows (Brent to pre-war levels)",
     "deescalation", "sensitivity", "regime_events 14e621ac (M1a 2026-07-01)", (87.33, 83.17, 78.96)),
    ("D2", "2026-07-27", "Weekend US-Iran talks 'by far the most serious'; threatened attack 'may be unnecessary'",
     "deescalation", "sensitivity", "decision_log aed40624 (2026-07-26)", (96.78, 88.36, 84.09)),
    ("D3", "2026-08-03", "US strike called off 08-02 on claimed deal progress; Iran denies talks 08-03",
     "deescalation", "sensitivity", "regime_events 6b16af77; decision_log b090c1d6 (2026-08-03)", (87.93, 83.77, 79.36)),
]

# Considered and NOT counted (listed in the memo with the reason):
NOT_COUNTED = [
    ("2026-03-02", "Iran war onset (2026-02-28)", "ONSET: already in the onset study; excluded here by construction"),
    ("2026-07-31", "IRGC strikes on US targets in Kuwait (regime_events 6b16af77)", "Brent +1.05 then -4.16; no trade-flow leg recorded: fails leg (i)"),
    ("2026-08-01", "D1 flag: Hormuz tanker attacks, reported US strikes on Iranian energy infrastructure (decision_log b090c1d6)", "reversed within 48h (strike called off); no stored close > $5 up"),
    ("2026-08-24", "50% US tariff on about $20B of goods from the largest trading partner, effective 08-22 (regime_events ba8ae2cf)", "rubric-qualifying but OFF the petroleum channel the first-hop map enumerates"),
    ("2026-08-03", "First-since-1998 joint currency intervention up to $85B (regime_events ba8ae2cf)", "rubric-qualifying FX leg, off-channel; same session as D3"),
    ("2026-09-15", "D1: drones strike Saudi East-West pipeline, shutdown (decision_log db7dc01c)", "same development as E8; M1a 3b6d1923 counts 09-11 as the qualifying event and does not count 09-15 separately"),
    ("2026-09-29", "Brent -9.12 (Yanbu loading resumption 09-27 + Nov->Dec contract roll worth about -6.43)", "contract-roll artefact per 3b6d1923; not an event"),
    ("2026-03..05", "April peak (~$128), 60-day MOU, within-war escalations before 2026-06-01", "UNDATED IN THE WAREHOUSE: regime scoring began 2026-04-22 and the shock_overlay axis 2026-06-01; see the memo's appendix"),
]


# ---------------------------------------------------------------------------------------------------
# Measurement
# ---------------------------------------------------------------------------------------------------


def partial_profile(hop: pd.Series, mkt: pd.Series, pos: int, dates: pd.DatetimeIndex) -> dict | None:
    """Same arithmetic as onset.car_profile, but reports each horizon only if its 5h post-event trading
    days are observable (None otherwise) instead of refusing the whole window."""
    beta = onset.estimate_beta(hop, mkt, pos)
    if beta is None:
        return None
    avail = len(dates) - 1 - pos  # trading days observable after the event day
    post_m = mkt.iloc[pos : pos + avail + 1]
    post_y = hop.iloc[pos : pos + avail + 1]
    hedged = (post_y - beta * post_m).fillna(0.0)
    out = {"beta": beta, "d0": float(hedged.iloc[0]), "days_available": int(avail)}
    drift = hedged.iloc[1:].cumsum()
    for h in HORIZONS:
        out[f"car_{h}w"] = float(drift.iloc[5 * h - 1]) if avail >= 5 * h else None
    return out


def event_window(rets, dates, d0: pd.Timestamp, first_codes, source, etf_first) -> dict:
    pos = dates.get_indexer([d0])[0]
    if pos < 0:
        return {"skipped": True, "reason": "event day not in the price calendar"}
    if pos < onset.BETA_WINDOW:
        return {"skipped": True, "reason": "insufficient pre-event history"}
    start = dates[pos - onset.BETA_WINDOW]
    end = dates[min(pos + max(HORIZONS) * 5, len(dates) - 1)]
    h1, cov1, _, per1 = onset.hop_return_series(rets, first_codes, set(), start, end, source, etf_first)
    if h1 is None:
        return {"skipped": True, "reason": "first hop has < 3 covered industries", "coverage_first": cov1}
    p1 = partial_profile(h1, rets[MARKET], pos, dates)
    if p1 is None:
        return {"skipped": True, "reason": "beta window too short", "coverage_first": cov1}
    inds = {}
    for k, ser in per1.items():
        pr = partial_profile(ser, rets[MARKET], pos, dates)
        if pr:
            inds[k] = pr
    return {"skipped": False, "coverage_first": cov1, "first": p1, "industries": inds}


def same_placebos_as_onset_study(rets, dates, first_codes, second_codes, source, etf_first):
    """Reproduce the onset study's placebo draws exactly: same eligibility, same SEED, same order."""
    rng = np.random.default_rng(onset.SEED)
    eligible = onset.placebo_eligible_positions(dates, max(HORIZONS))

    def draw(n):
        rows, tries = [], 0
        while len(rows) < n and tries < 20 * n:
            tries += 1
            pos = int(rng.choice(eligible))
            r = onset.run_window(rets, dates, dates[pos], first_codes, second_codes, source, etf_first)
            if r and not r.get("skipped"):
                rows.append(r)
        return rows

    draw(onset.PLACEBO_N)  # the 12 "placebo onsets" of the memo tables; drawn only to keep the rng in step
    dist = draw(onset.PLACEBO_DIST_N)
    return dist, rng


def pooled(vals: np.ndarray, rng) -> dict:
    boots = np.array([rng.choice(vals, size=len(vals), replace=True).mean() for _ in range(onset.BOOTSTRAP_REPS)])
    return {"n": len(vals), "mean": float(vals.mean()), "ci_lo": float(np.percentile(boots, 2.5)),
            "ci_hi": float(np.percentile(boots, 97.5)), "n_pos": int((vals > 0).sum()),
            "sd": float(vals.std(ddof=1)) if len(vals) > 1 else None}


def compare(events: list[dict], placebo_first: dict[str, np.ndarray], rng, sign: float = 1.0) -> dict:
    """Pooled per horizon over the events that have it; percentile of the pooled mean among pooled means
    of n_h placebo windows; dispersion vs single placebo windows."""
    out = {}
    for h in HORIZONS:
        v = np.array([sign * e["first"][f"car_{h}w"] for e in events if not e.get("skipped") and e["first"][f"car_{h}w"] is not None])
        if len(v) == 0:
            out[f"{h}w"] = None
            continue
        st = pooled(v, rng)
        pl = placebo_first[f"{h}w"] * sign
        m = len(v)
        pooled_pl = np.array([rng.choice(pl, size=m, replace=False).mean() for _ in range(onset.BOOTSTRAP_REPS)])
        st["pct_of_placebo_pooled"] = float((pooled_pl < st["mean"]).mean())
        st["placebo_mean"] = float(pl.mean())
        st["placebo_single_sd"] = float(pl.std(ddof=1))
        st["single_pct"] = [float((pl < x).mean()) for x in v]
        out[f"{h}w"] = st
    return out


def frequency_arithmetic(n_primary: int, n_strict: int) -> list[dict]:
    rows = []
    for label, n in (("primary (all rubric-qualifying escalation events)", n_primary), ("strict subset", n_strict)):
        for denom_label, denom in (("calendar YTD (0.80 yr)", YEAR_FRACTION_2026), ("dated window 06-01..10-19 (0.38 yr)", DATED_WINDOW_YEARS)):
            per_yr = n / denom
            for pairs in (1, 2, 3):
                trades = per_yr * pairs * 2  # two trades per pair (the two legs), per SL1's 2026-10-19 arithmetic
                rows.append({"set": label, "denominator": denom_label, "events_2026_ytd": n, "events_per_yr": per_yr,
                             "pairs_per_event": pairs, "trades_per_yr": trades, "years_to_30_trades": 30 / trades if trades else None})
    return rows


# ---------------------------------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------------------------------


def _p(x):
    return "n/a" if x is None else f"{100 * x:+.1f}%"


def render(res: dict) -> str:
    L = []
    src = res["source"]
    prox = "French 49 industries" if src == "french" else ("ETF-first" if res["etf_first"] else "baskets only")
    L.append(f"### Non-onset events: source `{src}`, proxies `{prox}`, first hop = {' '.join(res['first_hop'])}\n")
    L.append(f"Price span {res['price_span'][0]} .. {res['price_span'][1]}; market = {res['market']}; "
             f"{res['placebo_dist_n']} placebo windows (the onset study's own draws). "
             "`d0` = event-day hedged return; `Nw` = hedged CAR over trading days 1..5N after the event day; "
             "a blank cell means the horizon is not yet observable.\n")
    L.append("| Event | d0 | kind / tier | series n | β | d0 | " + " | ".join(f"{h}w" for h in HORIZONS) + " |")
    L.append("|---|---|---|---|---:|---:|" + "|".join("---:" for _ in HORIZONS) + "|")
    for e in res["events"]:
        if e.get("skipped"):
            L.append(f"| {e['id']} {e['label'][:60]} | {e['d0']} | {e['kind']} / {e['tier']} | | skipped: {e['reason']} |" + " |" * (len(HORIZONS) + 1))
            continue
        n1 = sum(len(c["members"]) for c in e["coverage_first"].values() if c["kind"] in ("french", "etf", "basket"))
        cells = [_p(e["first"][f"car_{h}w"]) if e["first"][f"car_{h}w"] is not None else "" for h in HORIZONS]
        L.append(f"| {e['id']} {e['label'][:60]} | {e['d0']} | {e['kind']} / {e['tier']} | {n1} | {e['first']['beta']:.2f} | {_p(e['first']['d0'])} | " + " | ".join(cells) + " |")

    def pooled_rows(title, st):
        L.append(f"\n**{title}**\n")
        L.append("| Statistic | " + " | ".join(f"{h}w" for h in HORIZONS) + " |")
        L.append("|---|" + "|".join("---:" for _ in HORIZONS) + "|")
        L.append("| Pooled mean [bootstrap 95% CI], positive/n | " + " | ".join(
            "n/a" if not st[f"{h}w"] else f"{_p(st[f'{h}w']['mean'])} [{_p(st[f'{h}w']['ci_lo'])}, {_p(st[f'{h}w']['ci_hi'])}] {st[f'{h}w']['n_pos']}/{st[f'{h}w']['n']}" for h in HORIZONS) + " |")
        L.append("| Placebo mean (500 windows) | " + " | ".join("n/a" if not st[f"{h}w"] else _p(st[f"{h}w"]["placebo_mean"]) for h in HORIZONS) + " |")
        L.append("| Percentile of the pooled mean among same-n placebo pooled means | " + " | ".join(
            "n/a" if not st[f"{h}w"] else f"{100 * st[f'{h}w']['pct_of_placebo_pooled']:.0f}th" for h in HORIZONS) + " |")
        L.append("| Dispersion: SD across events vs SD across single placebo windows | " + " | ".join(
            "n/a" if not st[f"{h}w"] or st[f"{h}w"]["sd"] is None else f"{_p(st[f'{h}w']['sd'])} vs {_p(st[f'{h}w']['placebo_single_sd'])}" for h in HORIZONS) + " |")

    pooled_rows("Primary: all rubric-qualifying NON-ONSET escalation events (strict + rubric tiers; provisional excluded)", res["stats"]["primary"])
    pooled_rows("Strict subset", res["stats"]["strict"])
    pooled_rows("Non-overlapping subset (each kept event >= 20 trading days after the previous kept one): " + ", ".join(res["nonoverlap_ids"]), res["stats"]["nonoverlap"])
    if res["stats"].get("deescalation"):
        pooled_rows("Sensitivity: de-escalation events, SIGN-FLIPPED (i.e. short the first hop)", res["stats"]["deescalation"])
    if res["stats"].get("onset_2026"):
        pooled_rows("Reference: the 2026-03-02 onset alone, same source (the onset study's row)", res["stats"]["onset_2026"])

    L.append("\n**Per-industry first-hop drift, pooled over the primary events** (mean hedged CAR; k/n = positive events / events with the horizon)\n")
    L.append("| Industry | d0 | " + " | ".join(f"{h}w" for h in HORIZONS) + " | placebo mean 4w |")
    L.append("|---|---:|" + "|".join("---:" for _ in HORIZONS) + "|---:|")
    for k, row in res["industry_stats"].items():
        cells = []
        for h in ("d0", *HORIZONS):
            c = row.get(f"{h}")
            cells.append("n/a" if not c else f"{_p(c['mean'])} {c['n_pos']}/{c['n']}")
        L.append(f"| {k} | " + " | ".join(cells) + f" | {_p(row.get('placebo_4w'))} |")

    L.append("\n**Per-event percentile among single placebo windows (4w)**: " + "; ".join(
        f"{e['id']} {100 * p:.0f}th" for e, p in res["single_pct_4w"]))
    L.append("\n**Coverage**: " + "; ".join(
        f"{e['id']}: " + ", ".join(f"{c}:{'+'.join(cv['members']) if cv['kind'] in ('french', 'etf') else (cv['kind'] + ('x%d' % len(cv['members']) if cv['kind'] == 'basket' else ''))}" for c, cv in e["coverage_first"].items())
        for e in res["events"] if not e.get("skipped")))
    return "\n".join(L)


# ---------------------------------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------------------------------


def run(data_dir: Path, source: str, etf_first: bool) -> dict:
    linkmap = json.loads((data_dir / "linkmap.json").read_text())
    rets = onset.load_returns(data_dir, source)
    dates = rets.index
    first_codes = [e["code"] for e in linkmap["first_hop"]]
    second_codes = [e["code"] for e in linkmap["second_hop_weighted"]]

    events = []
    for eid, d0, label, kind, tier, src, brent in EVENTS:
        ts = pd.Timestamp(d0)
        base = {"id": eid, "d0": d0, "label": label, "kind": kind, "tier": tier, "source_rows": src, "brent": brent}
        if ts > dates[-1]:
            events.append({**base, "skipped": True, "reason": "after the price span"})
            continue
        day = onset.first_trading_day(dates, d0)
        r = event_window(rets, dates, day, first_codes, source, etf_first)
        events.append({**base, "d0_traded": str(day.date()), **r})

    dist, rng = same_placebos_as_onset_study(rets, dates, first_codes, second_codes, source, etf_first)
    placebo_first = {f"{h}w": np.array([r["first"][f"car_{h}w"] for r in dist]) for h in HORIZONS}

    live = [e for e in events if not e.get("skipped")]
    primary = [e for e in live if e["kind"] == "escalation" and e["tier"] in ("strict", "rubric")]
    strict = [e for e in live if e["kind"] == "escalation" and e["tier"] == "strict"]
    deesc = [e for e in live if e["kind"] == "deescalation"]
    # Non-overlapping subset: the July and September events sit days apart, so their post-event windows
    # share most of their trading days and are not independent draws. Keep an event only if its d0 is at
    # least 20 trading days (the 4-week horizon) after the last kept event's d0.
    nonoverlap, last = [], None
    for e in primary:
        pos = dates.get_indexer([pd.Timestamp(e["d0_traded"])])[0]
        if last is None or pos - last >= 20:
            nonoverlap.append(e)
            last = pos
    stats = {"primary": compare(primary, placebo_first, rng), "strict": compare(strict, placebo_first, rng),
             "nonoverlap": compare(nonoverlap, placebo_first, rng)}
    if deesc:
        stats["deescalation"] = compare(deesc, placebo_first, rng, sign=-1.0)
    # reference: the 2026 onset through the same code path (full 12w available)
    onset_day = onset.first_trading_day(dates, "2026-02-28")
    r = event_window(rets, dates, onset_day, first_codes, source, etf_first)
    if not r.get("skipped"):
        stats["onset_2026"] = compare([r], placebo_first, rng)

    industry_stats = {}
    keys = sorted({k for e in primary for k in e["industries"]})
    pl_ind = {}
    for k in keys:
        row = {}
        for h in ("d0", *HORIZONS):
            f = "d0" if h == "d0" else f"car_{h}w"
            v = np.array([e["industries"][k][f] for e in primary if k in e["industries"] and e["industries"][k][f] is not None])
            row[f"{h}"] = {"n": len(v), "mean": float(v.mean()), "n_pos": int((v > 0).sum())} if len(v) else None
        pv = [d["industries"][k]["car_4w"] for d in dist if k in d.get("industries", {}) and d["industries"][k]["hop"] == "first"]
        pl_ind[k] = float(np.mean(pv)) if pv else None
        row["placebo_4w"] = pl_ind[k]
        industry_stats[k] = row

    single_pct_4w = []
    st4 = stats["primary"]["4w"]
    if st4:
        with4 = [e for e in primary if e["first"]["car_4w"] is not None]
        single_pct_4w = list(zip(with4, st4["single_pct"], strict=True))

    res = {
        "source": source, "etf_first": etf_first, "market": "Fama-French Mkt-RF + RF" if source == "french" else "SPY",
        "first_hop": first_codes, "events": events, "stats": stats, "industry_stats": industry_stats,
        "placebo_dist_n": len(dist), "price_span": [str(dates[0].date()), str(dates[-1].date())],
        "single_pct_4w": single_pct_4w, "nonoverlap_ids": [e["id"] for e in nonoverlap],
        "frequency": frequency_arithmetic(len([e for e in EVENTS if e[3] == "escalation" and e[4] in ("strict", "rubric")]),
                                          len([e for e in EVENTS if e[3] == "escalation" and e[4] == "strict"])),
        "not_counted": NOT_COUNTED,
    }
    tag = f"{source}_{'etf' if etf_first else 'basket'}"
    (data_dir / f"nononset_{tag}.json").write_text(json.dumps(res, indent=1, default=str))
    print(render(res))
    print("\n**Frequency arithmetic** (two trades per pair; two denominators, see the constants' comment)\n")
    print("| Event set | denominator | events 2026 YTD | events/yr | pairs/event | trades/yr | years to 30 trades |")
    print("|---|---|---:|---:|---:|---:|---:|")
    for f in res["frequency"]:
        print(f"| {f['set']} | {f['denominator']} | {f['events_2026_ytd']} | {f['events_per_yr']:.1f} | {f['pairs_per_event']} | {f['trades_per_yr']:.1f} | {f['years_to_30_trades']:.2f} |")
    return res


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--data-dir", type=Path, required=True, help="the onset study's data dir (linkmap.json + prices)")
    ap.add_argument("--source", choices=["french", "nasdaq", "yahoo"], default="nasdaq")
    ap.add_argument("--baskets-only", action="store_true")
    a = ap.parse_args(argv)
    run(a.data_dir, a.source, not a.baskets_only)
    return 0


if __name__ == "__main__":
    sys.exit(main())

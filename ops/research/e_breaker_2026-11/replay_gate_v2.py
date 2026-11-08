"""Strategy E re-exemption breaker v2 (spread divergence), per PREREGISTRATION_v2.md (standard library only).

Pure functions come first; file I/O and the command line are at the bottom.

    python3 ops/research/e_breaker_2026-11/replay_gate_v2.py insample
    python3 ops/research/e_breaker_2026-11/replay_gate_v2.py forward --series <later pair_stats_weekly.csv>

Ambiguities resolved (most literal reading taken; items the spec now settles are not listed):
1. A pair's "row four rows earlier / later" is counted in THAT pair's own list of week-keyed rows. The sticky
   window and "weekly measurement" are counted on the global list of week dates.
2. Sticky membership: c252 >= 0.50 at t or at any of the 12 global measurement dates before t.
3. A pair in P(t) needs non-missing c60(t), z252(t) and z252 at its row four earlier; a missing value (empty or
   non-finite cell) is a missing value, not a skipped row.
4. Group floor, pooling and the "6-digit cell empty uses 4-digit" rule are v1's build_groups, unchanged.
5. Leg D/H statistic for a week is the MAXIMUM group median; ties are broken by the smaller group key. A week with
   no computable group, or an empty P(t) for DP / L-pop, cannot be computed and counts as tripped.
6. L-group: low = group pairs with c60 < 0.3; trips if low >= 2 AND 2 * low >= group pairs.
7. Thresholds are rounded to 2 dp; B90 is NOT rounded. Weeks whose statistic is undefined are left out of the
   quantile input. A single value is its own quantile.
8. History = global dates from the first with >= 40 pairs carrying c252 through 2026-11-06 inclusive.
9. A week is "closed" (has an outcome) when its blowout share is defined, i.e. at least one pair has an outcome.
10. A (integrity) in a measurement: P(t) has fewer than 20 pairs, or no rows at that date.
11. F2 is computed in integers (100 * bound <= 35 * weeks). F3 needs 2 * bound-stress-weeks >= stress weeks. F4
    needs both bound and clear weeks to exist and the mean blowout share of bound weeks to be strictly greater.
    F1 failing gives INCONCLUSIVE regardless of F2-F4; otherwise PASS needs F2-F4, else FAIL.
12. The history digest hashes the raw CSV cell strings of rows dated <= 2026-11-06, sorted by (date, pair), as
    lines 'date,pair,c60,c252,z252' joined with newlines (a trailing newline after the last line).
13. The as-of's own ISO week is dropped unless as-of is a Saturday or Sunday (the week is then over).
14. After an INCONCLUSIVE, the next real score must be dated on or after the first scheduled date (2027-06-07,
    2027-09-06, 2027-12-06) strictly later than the last real score's as-of date.
"""
import argparse
import csv
import hashlib
import importlib.util
import json
import math
import statistics
import sys
from datetime import date as _date
from pathlib import Path

HERE = Path(__file__).resolve().parent

_spec = importlib.util.spec_from_file_location("e_breaker_replay_gate_v1", HERE / "replay_gate.py")
v1 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(v1)

# ---- constants fixed by the pre-registration -------------------------------------------------------------
FLOOR = 0.50
STICKY_LOOKBACK = 12
LOOKBACK_ROWS = 4
LOW_CORR = 0.3
DP_WIDEN = 1.0
BLOWOUT_MARGIN = 1.0
MIN_POP = 20
CALIB_MIN_PAIRS = 40
HISTORY_END = "2026-11-06"
FORWARD_START = "2026-11-09"
EARLIEST_SCORE = "2027-06-07"
SCORE_SCHEDULE = ("2027-06-07", "2027-09-06", "2027-12-06")
FINAL_SCORE_DATE = "2027-12-06"
BANKS_CODE = "401010"
S1_WINDOW = ("2020-02-15", "2020-04-30")
S2_WINDOW = ("2023-03-01", "2023-05-31")
F1_MIN_WEEKS = 26
F1_MIN_STRESS = 3
F2_CEILING_PCT = 35
STRESS_GROUP_MIN = 3
LOG_NAME = "scoring_log.jsonl"

parse_float = v1.parse_float
build_groups = v1.build_groups
load_gics = v1.load_gics


# ---- series construction ---------------------------------------------------------------------------------
def finite_float(cell):
    """Empty, unparseable-as-missing or non-finite (nan/inf) cell -> None, else float."""
    x = parse_float(cell)
    return x if x is not None and math.isfinite(x) else None


def truncate_rows(rows, cutoff, drop_week_of=None):
    """Rows dated <= cutoff (ISO strings). If drop_week_of is a date string, also drop every row in that ISO
    week unless that date is a Saturday or Sunday (the week is then over)."""
    drop = None
    if drop_week_of is not None:
        d = _date.fromisoformat(drop_week_of)
        if d.isoweekday() <= 5:
            drop = d.isocalendar()[:2]
    return [r for r in rows if r["date"] <= cutoff
            and (drop is None or _date.fromisoformat(r["date"]).isocalendar()[:2] != drop)]


def build_series(rows):
    """rows: dicts date,pair,c60,c252,z252 -> {week_date: {pair: (c60, c252, z252)}}. Each row is keyed to its
    ISO week, dated by the latest row date in that week across all pairs. Non-finite values are missing; a
    duplicate (week, pair) row raises ValueError."""
    weeks = {}
    for r in rows:
        weeks.setdefault(_date.fromisoformat(r["date"]).isocalendar()[:2], []).append(r)
    series = {}
    for members in weeks.values():
        wd = max(r["date"] for r in members)
        cell = {}
        for r in members:
            if r["pair"] in cell:
                raise ValueError(f"duplicate row for pair {r['pair']} in the ISO week dated {wd}")
            cell[r["pair"]] = (finite_float(r.get("c60")), finite_float(r.get("c252")),
                               finite_float(r.get("z252")))
        series[wd] = cell
    return series


def history_digest(rows):
    """SHA-256 over rows dated <= HISTORY_END, sorted by (date, pair), as 'date,pair,c60,c252,z252' lines with
    the CSV cell strings as read."""
    hist = sorted((r for r in rows if r["date"] <= HISTORY_END), key=lambda r: (r["date"], r["pair"]))
    text = "".join(",".join((r["date"], r["pair"], r.get("c60") or "", r.get("c252") or "",
                             r.get("z252") or "")) + "\n" for r in hist)
    return hashlib.sha256(text.encode()).hexdigest()


def build_pair_rows(series):
    """{pair: [(date, c60, c252, z252), ...]} in date order (the pair's own rows)."""
    out = {}
    for d in sorted(series):
        for p, v in series[d].items():
            out.setdefault(p, []).append((d, v[0], v[1], v[2]))
    return out


def row_offset(pair_rows, pair, date, offset):
    """The pair's row `offset` rows after (negative = before) its row at `date`, or None."""
    rows = pair_rows.get(pair, [])
    for k, r in enumerate(rows):
        if r[0] == date:
            j = k + offset
            return rows[j] if 0 <= j < len(rows) else None
    return None


def first_history_week(series, min_pairs=CALIB_MIN_PAIRS):
    for d in sorted(series):
        if sum(1 for v in series[d].values() if v[1] is not None) >= min_pairs:
            return d
    return None


# ---- population and widening -----------------------------------------------------------------------------
def widening(pair_rows, pair, date):
    """w(p,t) = |z252(t)| - |z252 four of the pair's own rows earlier|; None if either is missing."""
    now = row_offset(pair_rows, pair, date, 0)
    before = row_offset(pair_rows, pair, date, -LOOKBACK_ROWS)
    if now is None or before is None or now[3] is None or before[3] is None:
        return None
    return abs(now[3]) - abs(before[3])


def population(series, dates, i, pair_rows, floor=FLOOR, lookback=STICKY_LOOKBACK):
    """P(t) at dates[i]: sticky c252 >= floor over t and the previous `lookback` measurements, AND c60(t),
    z252(t) and the z252 four of the pair's rows earlier present. Sorted list."""
    members = set()
    for j in range(max(0, i - lookback), i + 1):
        for p, v in series.get(dates[j], {}).items():
            if v[1] is not None and v[1] >= floor:
                members.add(p)
    now = series.get(dates[i], {})
    return sorted(p for p in members
                  if p in now and now[p][0] is not None and widening(pair_rows, p, dates[i]) is not None)


# ---- legs ------------------------------------------------------------------------------------------------
def max_group(group_values):
    """(max value, group) over groups with a value; ties -> smaller key; (None, None) if none."""
    vals = {k: v for k, v in group_values.items() if v is not None}
    if not vals:
        return None, None
    key = sorted(vals, key=lambda k: (-vals[k], k))[0]
    return vals[key], key


def leg_d(group_widening_medians, t_d):
    """Leg D: any group's median w >= T_D. Returns (tripped, max, group). Not computable -> tripped."""
    m, k = max_group(group_widening_medians)
    return (True if m is None else m >= t_d), m, k


def leg_h(group_c60_medians, t_h):
    """Leg H: any group's median c60 >= T_H."""
    m, k = max_group(group_c60_medians)
    return (True if m is None else m >= t_h), m, k


def dp_share(widenings):
    """Share of P(t) pairs with w > 1.0 (strict); None for an empty population."""
    if not widenings:
        return None
    return sum(1 for w in widenings if w > DP_WIDEN) / len(widenings)


def leg_dp(widenings, s_dp):
    share = dp_share(widenings)
    return (True if share is None else share >= s_dp), share


def leg_l_pop(low_count, n_pairs, s_l):
    if n_pairs <= 0:
        return True, None
    share = low_count / n_pairs
    return share >= s_l, share


def leg_l_group(group_low_counts):
    """{key: (low, n_pairs)} -> sorted keys with >= 2 low pairs AND low >= half of the group's pairs."""
    return sorted(k for k, (low, n) in group_low_counts.items() if low >= 2 and 2 * low >= n)


def leg_a(n_pairs, present=True):
    """Integrity (fail-closed): missing measurement or fewer than 20 pairs in P(t)."""
    return (not present) or n_pairs < MIN_POP


# ---- thresholds ------------------------------------------------------------------------------------------
def quantile_cut(values, index):
    """statistics.quantiles(values, n=100, method='inclusive')[index]; None if empty, the value if single."""
    vals = list(values)
    if not vals:
        return None
    if len(vals) == 1:
        return float(vals[0])
    return statistics.quantiles(vals, n=100, method="inclusive")[index]


def p95(values):
    return quantile_cut(values, 94)


def p90(values):
    return quantile_cut(values, 89)


def derive_thresholds(stats):
    """stats: per-history-week raw stats (week_stat output). Returns the frozen-threshold dict."""
    def col(key):
        return [s[key] for s in stats if s[key] is not None]

    def r2(x):
        return None if x is None else round(x, 2)

    return {
        "T_D": r2(p95(col("max_d"))), "S_DP": r2(p95(col("dp_share"))),
        "T_H": r2(p95(col("max_h"))), "S_L": r2(p95(col("l_pop_share"))),
        "B90": p90(col("blowout_share")),
        "history_start": stats[0]["date"] if stats else None,
        "history_end": stats[-1]["date"] if stats else None,
        "n_history_weeks": len(stats),
    }


# ---- per-week statistics (threshold-free) ----------------------------------------------------------------
def median_of(values):
    return statistics.median(values) if values else None


def pair_blowout(pair_rows, pair, date):
    """|z(t+4 rows)| - |z(t)| > 1.0 using the pair's row four rows later; None if unavailable."""
    now = row_offset(pair_rows, pair, date, 0)
    later = row_offset(pair_rows, pair, date, LOOKBACK_ROWS)
    if now is None or later is None or now[3] is None or later[3] is None:
        return None
    return abs(later[3]) - abs(now[3]) > BLOWOUT_MARGIN


def week_stat(series, dates, i, gics, pair_rows):
    d = dates[i]
    pairs = population(series, dates, i, pair_rows)
    w = {p: widening(pair_rows, p, d) for p in pairs}
    c60 = {p: series[d][p][0] for p in pairs}
    flags = {p: pair_blowout(pair_rows, p, d) for p in pairs}
    groups = {}
    for key, plist in build_groups(pairs, gics).items():
        outs = [flags[p] for p in plist if flags[p] is not None]
        groups[key] = {
            "pairs": len(plist),
            "d_median": median_of([w[p] for p in plist]),
            "h_median": median_of([c60[p] for p in plist]),
            "low": sum(1 for p in plist if c60[p] < LOW_CORR),
            "n_out": len(outs), "n_blow": sum(1 for f in outs if f),
        }
    outs = [f for f in flags.values() if f is not None]
    max_d, max_d_group = max_group({k: g["d_median"] for k, g in groups.items()})
    max_h, max_h_group = max_group({k: g["h_median"] for k, g in groups.items()})
    low = sum(1 for v in c60.values() if v < LOW_CORR)
    return {
        "date": d, "present": d in series and len(series[d]) > 0, "n_pairs": len(pairs),
        "widenings": list(w.values()), "groups": groups,
        "max_d": max_d, "max_d_group": max_d_group, "max_h": max_h, "max_h_group": max_h_group,
        "dp_share": dp_share(list(w.values())), "low_count": low,
        "l_pop_share": (low / len(pairs)) if pairs else None,
        "blowout_share": (sum(1 for f in outs if f) / len(outs)) if outs else None,
    }


def week_stats(series, dates, gics, pair_rows=None):
    pair_rows = pair_rows if pair_rows is not None else build_pair_rows(series)
    return [week_stat(series, dates, i, gics, pair_rows) for i in range(len(dates))]


# ---- evaluation with frozen thresholds -------------------------------------------------------------------
def stress_flag(blowout_share, b90, group_outcomes):
    """Stress: share >= B90, OR a group of >= 3 pairs with >= 3 pairs-with-outcome and >= two thirds of those
    blowing out. group_outcomes: iterable of (n_pairs, n_out, n_blow)."""
    if blowout_share is not None and b90 is not None and blowout_share >= b90:
        return True
    return any(size >= STRESS_GROUP_MIN and n >= STRESS_GROUP_MIN and 3 * b >= 2 * n
               for size, n, b in group_outcomes)


def evaluate_week(stat, thr):
    groups = stat["groups"]
    d_trip, max_d, max_d_group = leg_d({k: g["d_median"] for k, g in groups.items()}, thr["T_D"])
    dp_trip, dp = leg_dp(stat["widenings"], thr["S_DP"])
    h_trip, max_h, max_h_group = leg_h({k: g["h_median"] for k, g in groups.items()}, thr["T_H"])
    lp_trip, lp = leg_l_pop(stat["low_count"], stat["n_pairs"], thr["S_L"])
    lg_keys = leg_l_group({k: (g["low"], g["pairs"]) for k, g in groups.items()})
    l_trip = lp_trip or bool(lg_keys)
    a_trip = leg_a(stat["n_pairs"], stat["present"])
    legs = [n for n, f in (("D", d_trip), ("DP", dp_trip), ("H", h_trip), ("L", l_trip), ("A", a_trip)) if f]
    return {
        "date": stat["date"], "n_pairs": stat["n_pairs"],
        "max_d": max_d, "max_d_group": max_d_group, "dp_share": dp,
        "max_h": max_h, "max_h_group": max_h_group, "l_pop_share": lp,
        "l_group_trips": ";".join(lg_keys), "legs_tripped": ";".join(legs),
        "breaker_tripped": bool(legs), "leg_d": d_trip, "leg_dp": dp_trip,
        "blowout_share": stat["blowout_share"],
        "stress": stress_flag(stat["blowout_share"], thr["B90"],
                              [(g["pairs"], g["n_out"], g["n_blow"]) for g in groups.values()]),
        "d_groups": {k: g["d_median"] for k, g in groups.items()},
    }


# ---- in-sample checks ------------------------------------------------------------------------------------
def in_window(date, window):
    return window[0] <= date <= window[1]


def insample_checks(records):
    s1 = [r for r in records if in_window(r["date"], S1_WINDOW) and (r["leg_d"] or r["leg_dp"])]
    banks = [{"date": r["date"], "banks_d_median": r["d_groups"].get(BANKS_CODE),
              "trips": r["d_groups"].get(BANKS_CODE) is not None and r["leg_d_banks"]}
             for r in records if in_window(r["date"], S2_WINDOW)]
    bound = [r for r in records if r["breaker_tripped"]]
    clear = [r for r in records if not r["breaker_tripped"]]

    def mean_out(rs):
        vals = [r["blowout_share"] for r in rs if r["blowout_share"] is not None]
        return sum(vals) / len(vals) if vals else None

    return {
        "S1": {"window": list(S1_WINDOW), "weeks_tripped": [r["date"] for r in s1], "pass": bool(s1)},
        "S2": {"window": list(S2_WINDOW), "banks_code": BANKS_CODE, "weekly_banks_d_medians": banks,
               "pass": any(b["trips"] for b in banks)},
        "S3": {"n_weeks": len(records), "bound_weeks": len(bound),
               "bound_share": (len(bound) / len(records)) if records else None,
               "mean_blowout_bound": mean_out(bound), "mean_blowout_clear": mean_out(clear),
               "note": "in-sample; no pass mark; not evidence of power"},
    }


# ---- forward criteria ------------------------------------------------------------------------------------
def score_forward(weeks):
    """weeks: dicts with breaker_tripped, stress, blowout_share (outcome-closed forward weeks)."""
    n = len(weeks)
    stress = [w for w in weeks if w["stress"]]
    bound = [w for w in weeks if w["breaker_tripped"]]
    clear = [w for w in weeks if not w["breaker_tripped"]]
    bound_stress = [w for w in stress if w["breaker_tripped"]]

    def mean_out(rs):
        vals = [w["blowout_share"] for w in rs if w["blowout_share"] is not None]
        return sum(vals) / len(vals) if vals else None

    mb, mc = mean_out(bound), mean_out(clear)
    f1 = n >= F1_MIN_WEEKS and len(stress) >= F1_MIN_STRESS
    f2 = n > 0 and 100 * len(bound) <= F2_CEILING_PCT * n
    f3 = bool(stress) and 2 * len(bound_stress) >= len(stress)
    f4 = mb is not None and mc is not None and mb > mc
    overall = "INCONCLUSIVE" if not f1 else ("PASS" if (f2 and f3 and f4) else "FAIL")
    return {
        "n_forward_weeks": n, "n_stress_weeks": len(stress), "n_bound_weeks": len(bound),
        "bound_share": (len(bound) / n) if n else None,
        "stress_weeks_bound": len(bound_stress),
        "mean_blowout_bound": mb, "mean_blowout_clear": mc,
        "F1": f1, "F2": f2, "F3": f3, "F4": f4, "overall": overall,
    }


def forward_weeks(records, as_of):
    """Evaluated weeks: dated FORWARD_START..as_of with a closed outcome."""
    return [r for r in records
            if FORWARD_START <= r["date"] <= as_of and r["blowout_share"] is not None]


# ---- guards ----------------------------------------------------------------------------------------------
def write_thresholds(path, thr):
    """Write frozen thresholds; an existing file is never overwritten."""
    path = Path(path)
    if path.exists():
        raise FileExistsError(f"{path} exists; thresholds are frozen")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(thr, indent=2, sort_keys=True) + "\n")


def parse_as_of(text):
    """Strict ISO date (YYYY-MM-DD) -> date; ValueError otherwise."""
    d = _date.fromisoformat(text)
    if d.isoformat() != text:
        raise ValueError(f"not a YYYY-MM-DD date: {text!r}")
    return d


def read_log(rdir):
    path = Path(rdir) / LOG_NAME
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def append_log(rdir, entry):
    with open(Path(rdir) / LOG_NAME, "a") as fh:
        fh.write(json.dumps(entry, sort_keys=True) + "\n")


def score_refusal(as_of, today, log):
    """Reason a real (non-peek) score must be refused, or None. as_of, today: ISO strings."""
    if today < as_of:
        return f"as-of {as_of} is in the future (today {today})"
    if as_of < EARLIEST_SCORE:
        return f"scoring is not allowed before {EARLIEST_SCORE} (as-of {as_of}); pass --peek for a non-score look"
    scores = [e for e in log if e.get("kind") == "score"]
    if any(e.get("overall") in ("PASS", "FAIL") for e in scores):
        return "a PASS or FAIL score is already logged; the forward test is closed"
    if any(e.get("as_of", "") >= FINAL_SCORE_DATE for e in scores):
        return f"a score dated on or after {FINAL_SCORE_DATE} is already logged; the forward test is closed"
    if scores:
        last = max(e["as_of"] for e in scores)
        nxt = next((d for d in SCORE_SCHEDULE if d > last), None)
        if nxt is None or as_of < nxt:
            return f"after an INCONCLUSIVE score the next score must be dated on or after {nxt}"
    return None


# ---- I/O -------------------------------------------------------------------------------------------------
def read_csv(path):
    with open(path, newline="") as fh:
        return list(csv.DictReader(fh))


def load_inputs(rows, gics_path):
    series = build_series(rows)
    gics = load_gics(read_csv(gics_path))
    return series, sorted(series), gics


def records_with_banks(stats, thr):
    recs = []
    for s in stats:
        r = evaluate_week(s, thr)
        b = r["d_groups"].get(BANKS_CODE)
        r["leg_d_banks"] = b is not None and b >= thr["T_D"]
        recs.append(r)
    return recs


WEEKLY_COLS = ["date", "n_pairs", "max_d_median", "max_d_group", "dp_share", "max_h_median", "max_h_group",
               "l_pop_share", "l_group_trips", "legs_tripped", "breaker_tripped", "blowout_share", "stress"]


def _fmt(x):
    return "" if x is None else (f"{x:.6f}" if isinstance(x, float) else x)


def cmd_insample(args):
    rdir = Path(args.results_dir)
    tpath = rdir / "thresholds.json"
    if tpath.exists():
        print(f"REFUSED: {tpath} exists; thresholds are frozen")
        return 2
    all_rows = read_csv(args.series)
    rows = truncate_rows(all_rows, HISTORY_END)
    series, dates, gics = load_inputs(rows, args.gics)
    start = first_history_week(series)
    if start is None:
        print("no week with enough pairs carrying c252")
        return 1
    rdir.mkdir(parents=True, exist_ok=True)
    pair_rows = build_pair_rows(series)
    stats = week_stats(series, dates, gics, pair_rows)
    hist = [s for s in stats if start <= s["date"] <= HISTORY_END]
    thr = derive_thresholds(hist)
    thr["history_sha256"] = history_digest(all_rows)
    write_thresholds(tpath, thr)
    recs = records_with_banks(hist, thr)
    with open(rdir / "weekly_insample.csv", "w", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(WEEKLY_COLS)
        for r in recs:
            w.writerow([_fmt(x) for x in (
                r["date"], r["n_pairs"], r["max_d"], r["max_d_group"], r["dp_share"], r["max_h"],
                r["max_h_group"], r["l_pop_share"], r["l_group_trips"], r["legs_tripped"],
                r["breaker_tripped"], r["blowout_share"], r["stress"])])
    checks = insample_checks(recs)
    (rdir / "insample.json").write_text(json.dumps(checks, indent=2, sort_keys=True) + "\n")
    print("thresholds:", json.dumps(thr, sort_keys=True))
    print(f"S1 pass={checks['S1']['pass']}  S2 pass={checks['S2']['pass']}")
    print("S3:", json.dumps(checks["S3"], sort_keys=True))
    return 0


def cmd_forward(args, today):
    today_s = today.isoformat()
    try:
        as_of = parse_as_of(args.as_of).isoformat() if args.as_of else today_s
    except ValueError as exc:
        print(f"REFUSED: invalid --as-of: {exc}")
        return 2
    rdir = Path(args.results_dir)
    log = read_log(rdir)
    if not args.peek:
        reason = score_refusal(as_of, today_s, log)
        if reason:
            print(f"REFUSED: {reason}")
            return 2
        if (rdir / f"forward_{as_of}.json").exists():
            print(f"REFUSED: forward_{as_of}.json already exists and is never overwritten")
            return 2
    tpath = rdir / "thresholds.json"
    if not tpath.exists():
        print(f"ERROR: frozen thresholds missing: {tpath}")
        return 1
    if args.peek:
        print("!" * 70)
        print("WARNING: --peek. A peek is NOT a score. Do not act on it or tune anything from it.")
        print("!" * 70)
    thr = json.loads(tpath.read_text())
    all_rows = read_csv(args.series)
    revised = history_digest(all_rows) != thr.get("history_sha256")
    series, dates, gics = load_inputs(truncate_rows(all_rows, as_of, drop_week_of=as_of), args.gics)
    recs = [evaluate_week(s, thr) for s in week_stats(series, dates, gics)]
    result = score_forward(forward_weeks(recs, as_of))
    result.update({"as_of": as_of, "peek": bool(args.peek), "thresholds": thr, "history_revised": revised})
    rdir.mkdir(parents=True, exist_ok=True)
    if args.peek:
        n = 1
        while (rdir / f"peek_{as_of}_{n}.json").exists():
            n += 1
        out = rdir / f"peek_{as_of}_{n}.json"
    else:
        out = rdir / f"forward_{as_of}.json"
    with open(out, "x") as fh:
        fh.write(json.dumps(result, indent=2, sort_keys=True) + "\n")
    append_log(rdir, {"kind": "peek" if args.peek else "score", "as_of": as_of, "logged_on": today_s,
                      "overall": result["overall"], "file": out.name, "history_revised": revised})
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


def main(argv=None, today=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("insample", "forward"):
        sp = sub.add_parser(name)
        sp.add_argument("--series", required=(name == "forward"),
                        default=str(HERE / "series" / "pair_stats_weekly.csv"))
        sp.add_argument("--gics", default=str(HERE / "pairs_gics.csv"))
        sp.add_argument("--results-dir", default=str(HERE / "results_v2"))
        if name == "forward":
            sp.add_argument("--as-of", default=None)
            sp.add_argument("--peek", action="store_true")
    args = ap.parse_args(argv)
    if args.cmd == "insample":
        return cmd_insample(args)
    return cmd_forward(args, today if today is not None else _date.today())


if __name__ == "__main__":
    sys.exit(main())

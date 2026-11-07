"""Stress replay of the Strategy E re-exemption breaker, per PREREGISTRATION.md (standard library only).

Pure functions (population, grouping, legs, thresholds, outcome, stress, criteria) come first; file I/O and the
command line are at the bottom. Nothing here chooses or tunes a rule: every constant below is quoted from the
pre-registration. Run from anywhere:

    python3 ops/research/e_breaker_2026-11/replay_gate.py
"""
import argparse
import csv
import json
import statistics
from collections import defaultdict
from datetime import date as _date
from pathlib import Path

HERE = Path(__file__).resolve().parent

# ---- constants fixed by the pre-registration -------------------------------------------------------------
FLOOR = 0.50            # M2 population floor: 252-day correlation >= 0.50
STICKY_LOOKBACK = 3     # ... or in the population at any of the three previous measurements
MIN_TICKERS = 3         # group floor: distinct tickers
MIN_PAIRS = 2           # group floor: pairs
LOW_CORR = 0.3          # E's breakdown invalidation: 60-day correlation < 0.3
LEG_A_MIN_PAIRS = 20    # leg A: P(t) fewer than 20 pairs
MAX_AGE_DAYS = 35       # runtime proposal: 35-day maximum age
CALIB_MIN_PAIRS = 40    # calibration starts at first week with >= 40 pairs carrying a 252-day value
CALIB_END = "2021-12-31"
BLOWOUT_MARGIN = 1.0
BLOWOUT_WEEKS = 4
STRESS_GROUP_OUTCOME = 0.5
FALSE_BIND_CEILING = 0.40
BANKS_CODE = "401010"

CALIBRATION_WINDOWS = {
    "W-2018Q4": ("2018-10-01", "2018-12-31"),
    "W-2020COVID": ("2020-02-15", "2020-04-30"),
}
HELDOUT_WINDOWS = {
    "W-2022": ("2022-02-15", "2022-06-30"),
    "W-2023BANKS": ("2023-03-01", "2023-05-31"),
    "W-2025TARIFF": ("2025-03-25", "2025-05-15"),
    "W-2026GULF": ("2026-02-28", "2026-10-31"),
}


# ---- parsing / series construction -----------------------------------------------------------------------
def parse_float(cell):
    """Empty / missing cell -> None, else float."""
    if cell is None:
        return None
    cell = str(cell).strip()
    if cell == "":
        return None
    return float(cell)


def build_series(rows):
    """rows: dicts with date,pair,c60,c252,z252 -> {date: {pair: (c60, c252, z252)}} (None = missing)."""
    series = defaultdict(dict)
    for r in rows:
        series[r["date"]][r["pair"]] = (parse_float(r.get("c60")), parse_float(r.get("c252")),
                                        parse_float(r.get("z252")))
    return dict(series)


def load_gics(rows):
    """rows: dicts of pairs_gics.csv -> {pair: (code4 or None, code6 or None)}; empty cell -> None."""
    out = {}
    for r in rows:
        c4 = (r.get("gics_industry_group_4digit") or "").strip() or None
        c6 = (r.get("gics_industry_6digit") or "").strip() or None
        out[r["pair"]] = (c4, c6)
    return out


def tickers_of(pair):
    return [t.strip() for t in pair.split("/")]


def week_index(iso_date):
    """Index of the ISO week (Monday-based) containing the date; consecutive weeks differ by exactly 1."""
    d = _date.fromisoformat(iso_date)
    return (d.toordinal() - 1) // 7


def monthly_dates(dates):
    """Last weekly row date of each calendar month, ascending."""
    last = {}
    for d in sorted(set(dates)):
        last[d[:7]] = d
    return [last[m] for m in sorted(last)]


def weekly_dates(dates):
    return sorted(set(dates))


def first_week_with_252(series, min_pairs=CALIB_MIN_PAIRS):
    """First weekly date with at least min_pairs pairs carrying a 252-day value, or None."""
    for d in sorted(series):
        if sum(1 for v in series[d].values() if v[1] is not None) >= min_pairs:
            return d
    return None


# ---- population -------------------------------------------------------------------------------------------
def floor_members(series, d, floor=FLOOR):
    """Pairs in M2's floor population at date d (c252 >= floor)."""
    return {p for p, v in series.get(d, {}).items() if v[1] is not None and v[1] >= floor}


def population(series, dates, i, floor=FLOOR, lookback=STICKY_LOOKBACK):
    """P(t) at dates[i]: pairs with c252 >= floor at t or at any of the previous `lookback` measurements
    (dates[i-lookback:i]), AND having a c60 value at t. Sorted list."""
    members = set()
    for j in range(max(0, i - lookback), i + 1):
        members |= floor_members(series, dates[j], floor)
    now = series.get(dates[i], {})
    return sorted(p for p in members if p in now and now[p][0] is not None)


# ---- grouping / pooling -----------------------------------------------------------------------------------
def distinct_tickers(pairs):
    return len({t for p in pairs for t in tickers_of(p)})


def group_ok(pairs):
    """Group floor: at least 3 distinct tickers AND at least 2 pairs."""
    return len(pairs) >= MIN_PAIRS and distinct_tickers(pairs) >= MIN_TICKERS


def build_groups(pairs, gics):
    """Group the pairs of P(t) by 6-digit code (pair with an empty 6-digit code uses its 4-digit code).
    A 6-digit group below the floor is pooled into its 4-digit parent; pairs whose own group is the 4-digit
    code join that same parent pool. A parent still below the floor contributes to population-wide legs only.
    Returns {group_key: sorted pairs}; keys are 6-digit or 4-digit code strings."""
    by6 = defaultdict(list)
    pools = defaultdict(list)
    for p in pairs:
        c4, c6 = gics.get(p, (None, None))
        if c6 is not None:
            by6[c6].append((p, c4))
        elif c4 is not None:
            pools[c4].append(p)
    groups = {}
    for c6, members in by6.items():
        plist = [p for p, _ in members]
        if group_ok(plist):
            groups[c6] = sorted(plist)
        else:
            for p, c4 in members:
                if c4 is not None:
                    pools[c4].append(p)
    for c4, plist in pools.items():
        if group_ok(plist):
            groups[c4] = sorted(plist)
    return groups


# ---- legs -------------------------------------------------------------------------------------------------
def median_of(values):
    return statistics.median(values) if values else None


def leg_h(group_medians, t_h):
    """Leg H: trips if any group's median c60 >= T_H. Returns (tripped, max_median, max_group).
    No computable group -> cannot be computed -> counts as tripped."""
    vals = {k: m for k, m in group_medians.items() if m is not None}
    if not vals:
        return True, None, None
    key = sorted(vals, key=lambda k: (-vals[k], k))[0]
    return vals[key] >= t_h, vals[key], key


def leg_l_pop(low_count, n_pairs, s_l):
    """L-pop: share of P(t) pairs with c60 < 0.3 is >= S_L. Returns (tripped, share). Empty P -> tripped."""
    if n_pairs <= 0:
        return True, None
    share = low_count / n_pairs
    return share >= s_l, share


def leg_l_group(group_low_counts):
    """L-group: groups {key: (low_count, n_pairs)} with at least half of pairs below 0.3. Returns sorted keys."""
    return sorted(k for k, (low, n) in group_low_counts.items() if n > 0 and 2 * low >= n)


def leg_a(measurement_date, as_of_date, n_pairs, max_age_days=MAX_AGE_DAYS, min_pairs=LEG_A_MIN_PAIRS):
    """Leg A (fail-closed): missing measurement, older than max age, or fewer than 20 pairs in P(t)."""
    if measurement_date is None:
        return True
    age = (_date.fromisoformat(as_of_date) - _date.fromisoformat(measurement_date)).days
    return age > max_age_days or n_pairs < min_pairs


# ---- thresholds -------------------------------------------------------------------------------------------
def percentile90(values):
    """90th percentile = 90th cut point of statistics.quantiles(n=100, method='inclusive'); None if empty."""
    vals = list(values)
    if not vals:
        return None
    if len(vals) == 1:
        return float(vals[0])
    return statistics.quantiles(vals, n=100, method="inclusive")[89]


def derive_thresholds(stats, start, end=CALIB_END):
    """T_H, S_L from stats (monthly) with start <= date <= end. Values rounded to 2 decimals."""
    cal = [s for s in stats if start <= s["date"] <= end]
    maxes = [s["max_group_median"] for s in cal if s["max_group_median"] is not None]
    shares = [s["l_pop_share"] for s in cal if s["l_pop_share"] is not None]
    t_h, s_l = percentile90(maxes), percentile90(shares)
    return {
        "T_H": None if t_h is None else round(t_h, 2),
        "S_L": None if s_l is None else round(s_l, 2),
        "calibration_start": start, "calibration_end": end,
        "n_calibration_months": len(cal),
        "n_months_max_group_median": len(maxes), "n_months_l_pop_share": len(shares),
        "T_H_unrounded": t_h, "S_L_unrounded": s_l,
    }


# ---- outcome ----------------------------------------------------------------------------------------------
def blowout(z_now, z_later, margin=BLOWOUT_MARGIN):
    """|z(t+4w)| - |z(t)| > margin (strict). None if either z is missing."""
    if z_now is None or z_later is None:
        return None
    return abs(z_later) - abs(z_now) > margin


def share_true(flags):
    """Share of True among non-None flags; (share or None, denominator)."""
    vals = [f for f in flags if f is not None]
    if not vals:
        return None, 0
    return sum(1 for f in vals if f) / len(vals), len(vals)


# ---- per-measurement statistics (no thresholds needed) -----------------------------------------------------
def build_z_lookup(series):
    """{(pair, week_index): z252} for the outcome look-ahead (row 4 ISO weeks later)."""
    out = {}
    for d, rows in series.items():
        w = week_index(d)
        for p, v in rows.items():
            out[(p, w)] = v[2]
    return out


def pair_blowout(series, z_lookup, pair, d):
    """blowout flag for pair at date d using the row BLOWOUT_WEEKS ISO weeks later; None if not available."""
    z_now = series[d][pair][2]
    later = (pair, week_index(d) + BLOWOUT_WEEKS)
    if later not in z_lookup:
        return None
    return blowout(z_now, z_lookup[later])


def compute_stat(series, dates, i, gics, z_lookup):
    """Threshold-free statistics of measurement dates[i]."""
    d = dates[i]
    pairs = population(series, dates, i)
    c60 = {p: series[d][p][0] for p in pairs}
    flags = {p: pair_blowout(series, z_lookup, p, d) for p in pairs}
    low = sum(1 for v in c60.values() if v < LOW_CORR)
    groups = {}
    for key, plist in build_groups(pairs, gics).items():
        g_out, g_n = share_true([flags[p] for p in plist])
        groups[key] = {
            "pairs": len(plist), "tickers": distinct_tickers(plist),
            "median": median_of([c60[p] for p in plist]),
            "low": sum(1 for p in plist if c60[p] < LOW_CORR),
            "outcome": g_out, "n_outcome": g_n,
        }
    pop_out, n_out = share_true(list(flags.values()))
    maxima = [g["median"] for g in groups.values()]
    return {
        "date": d, "n_pairs": len(pairs), "pop_median_c60": median_of(list(c60.values())),
        "low_count": low, "l_pop_share": (low / len(pairs)) if pairs else None,
        "max_group_median": max(maxima) if maxima else None,
        "groups": groups, "pop_outcome": pop_out, "n_outcome": n_out,
        "measurement_present": d in series and len(series[d]) > 0,
    }


def compute_stats(series, dates, gics):
    z_lookup = build_z_lookup(series)
    return [compute_stat(series, dates, i, gics, z_lookup) for i in range(len(dates))]


# ---- evaluation with frozen thresholds ---------------------------------------------------------------------
def stress_flag(pop_outcome, p90, group_outcomes):
    """Stress: population outcome >= 90th percentile of all months, OR any group with >= 3 distinct tickers has
    outcome >= 0.5. group_outcomes: iterable of (distinct_tickers, outcome or None)."""
    if pop_outcome is not None and p90 is not None and pop_outcome >= p90:
        return True
    return any(o is not None and t >= MIN_TICKERS and o >= STRESS_GROUP_OUTCOME for t, o in group_outcomes)


def evaluate_stat(stat, t_h, s_l, max_age_days=MAX_AGE_DAYS):
    groups = stat["groups"]
    h_trip, max_med, max_grp = leg_h({k: g["median"] for k, g in groups.items()}, t_h)
    lp_trip, share = leg_l_pop(stat["low_count"], stat["n_pairs"], s_l)
    lg_keys = leg_l_group({k: (g["low"], g["pairs"]) for k, g in groups.items()})
    a_trip = leg_a(stat["date"] if stat["measurement_present"] else None, stat["date"],
                   stat["n_pairs"], max_age_days)
    l_trip = lp_trip or bool(lg_keys)
    legs = [n for n, f in (("H", h_trip), ("L", l_trip), ("A", a_trip)) if f]
    return {
        "date": stat["date"], "n_pairs": stat["n_pairs"],
        "max_group_median": max_med, "max_group": max_grp,
        "pop_median_c60": stat["pop_median_c60"], "l_pop_share": share,
        "leg_h": h_trip, "leg_l_pop": lp_trip, "leg_l_group": bool(lg_keys),
        "l_group_trips": ";".join(lg_keys), "leg_l": l_trip, "leg_a": a_trip,
        "legs_tripped": ";".join(legs), "breaker_tripped": bool(legs),
        "pop_outcome": stat["pop_outcome"], "n_outcome": stat["n_outcome"],
        "groups": groups, "stress": False,
    }


def evaluate_series(stats, t_h, s_l):
    """Evaluate every measurement and set stress flags (p90 over all measurements of this series)."""
    recs = [evaluate_stat(s, t_h, s_l) for s in stats]
    p90 = percentile90([r["pop_outcome"] for r in recs if r["pop_outcome"] is not None])
    for r in recs:
        r["stress"] = stress_flag(r["pop_outcome"], p90,
                                  [(g["tickers"], g["outcome"]) for g in r["groups"].values()])
        r["outcome_p90"] = p90
    return recs, p90


# ---- windows / criteria --------------------------------------------------------------------------------------
def in_window(d, window):
    return window[0] <= d <= window[1]


def records_in_windows(records, windows):
    """Records whose date lies in any of the windows (each record once)."""
    return [r for r in records if any(in_window(r["date"], w) for w in windows)]


def mean_of(values):
    return sum(values) / len(values) if values else None


def criterion_1(records, calib_windows=None, held_windows=None):
    calib_windows = CALIBRATION_WINDOWS if calib_windows is None else calib_windows
    held_windows = HELDOUT_WINDOWS if held_windows is None else held_windows

    def hit(win):
        months = [r for r in records if in_window(r["date"], win)]
        # Substantive = a leg tripped on a COMPUTED statistic. A fail-closed trip because no group or no
        # population exists is leg-A-like and does not count (PREREGISTRATION.md criterion 1).
        sub = [r["date"] for r in months
               if (r["leg_h"] and r["max_group_median"] is not None)
               or (r["leg_l_pop"] and r["l_pop_share"] is not None)
               or r["leg_l_group"]]
        return {"months": len(months), "substantive_trip_months": sub, "hit": bool(sub)}

    cal = {n: hit(w) for n, w in calib_windows.items()}
    held = {n: hit(w) for n, w in held_windows.items()}
    n_held = sum(1 for v in held.values() if v["hit"])
    ok = all(v["hit"] for v in cal.values()) and n_held >= 3
    return {"pass": ok, "evidence": {"calibration": cal, "held_out": held, "held_out_windows_hit": n_held,
                                     "held_out_required": 3, "held_out_total": len(held)}}


def criterion_2(records, window, t_h, s_l, code=BANKS_CODE):
    """In some month of the window the per-group leg H or L-group trips on group `code` while the population-wide
    median c60 < T_H and L-pop share < S_L (same month)."""
    months = []
    for r in records:
        if not in_window(r["date"], window):
            continue
        g = r["groups"].get(code)
        b_h = bool(g) and g["median"] is not None and g["median"] >= t_h
        b_l = bool(g) and g["pairs"] > 0 and 2 * g["low"] >= g["pairs"]
        pop_med, share = r["pop_median_c60"], r["l_pop_share"]
        pop_quiet = (pop_med is not None and share is not None and pop_med < t_h and share < s_l)
        months.append({
            "date": r["date"], "banks_present_as_group": bool(g),
            "banks_median_c60": g["median"] if g else None,
            "banks_share_below_0.3": (g["low"] / g["pairs"]) if g else None,
            "banks_leg_h": b_h, "banks_l_group": b_l,
            "pop_median_c60": pop_med, "pop_l_pop_share": share,
            "pop_median_below_T_H": pop_med is not None and pop_med < t_h,
            "pop_share_below_S_L": share is not None and share < s_l,
            "banks_trip_and_pop_quiet": (b_h or b_l) and pop_quiet,
        })
    ok = any(m["banks_trip_and_pop_quiet"] for m in months)
    return {"pass": ok, "evidence": {"window": list(window), "group": code, "T_H": t_h, "S_L": s_l,
                                     "months": months}}


def criterion_3(held_records):
    """At least half of the held-out stress months have the breaker tripped at their own measurement."""
    stress = [r for r in held_records if r["stress"]]
    tripped = [r for r in stress if r["breaker_tripped"]]
    frac = len(tripped) / len(stress) if stress else None
    ok = bool(stress) and 2 * len(tripped) >= len(stress)
    return {"pass": ok, "evidence": {
        "n_stress_months": len(stress), "n_tripped_at_open": len(tripped), "fraction": frac, "required": 0.5,
        "stress_dates": [r["date"] for r in stress], "tripped_dates": [r["date"] for r in tripped]}}


def criterion_4(held_records):
    """Breaker tripped in at most 40% of held-out months (integer arithmetic: 5 * tripped <= 2 * months)."""
    n = len(held_records)
    k = sum(1 for r in held_records if r["breaker_tripped"])
    ok = n > 0 and 5 * k <= 2 * n
    return {"pass": ok, "evidence": {"n_months": n, "n_tripped": k, "false_bind_fraction": (k / n) if n else None,
                                     "ceiling": FALSE_BIND_CEILING}}


def criterion_5(held_records):
    """Mean population outcome in tripped months > mean in clear months (months with a defined outcome)."""
    t = [r["pop_outcome"] for r in held_records if r["breaker_tripped"] and r["pop_outcome"] is not None]
    c = [r["pop_outcome"] for r in held_records if not r["breaker_tripped"] and r["pop_outcome"] is not None]
    mt, mc = mean_of(t), mean_of(c)
    ok = mt is not None and mc is not None and mt > mc
    return {"pass": ok, "evidence": {"n_tripped_months": len(t), "mean_outcome_tripped": mt,
                                     "n_clear_months": len(c), "mean_outcome_clear": mc}}


def evaluate_criteria(records, t_h, s_l):
    # Criteria 3-5 read the whole held-out PERIOD (every measurement after the calibration end), not only
    # the named stress windows: a false-bind ceiling measured inside crises would be meaningless.
    held = [r for r in records if r["date"] > CALIB_END]
    crit = {
        "1_substantive_trips": criterion_1(records),
        "2_group_local_power": criterion_2(records, HELDOUT_WINDOWS["W-2023BANKS"], t_h, s_l),
        "3_lead_time": criterion_3(held),
        "4_false_bind_ceiling": criterion_4(held),
        "5_discrimination": criterion_5(held),
    }
    crit["all_pass"] = all(v["pass"] for k, v in crit.items() if k != "all_pass")
    return crit


# ---- I/O ----------------------------------------------------------------------------------------------------
CSV_COLUMNS = ["date", "n_pairs", "max_group_median", "max_group", "pop_median_c60", "l_pop_share",
               "leg_l_pop", "leg_l_group", "l_group_trips", "leg_h", "leg_l", "leg_a", "legs_tripped",
               "breaker_tripped", "pop_outcome", "n_outcome", "stress"]


def _cell(v):
    if v is None:
        return ""
    if isinstance(v, bool):
        return int(v)
    if isinstance(v, float):
        return f"{v:.6f}"
    return v


def write_records_csv(path, records):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(CSV_COLUMNS)
        for r in records:
            w.writerow([_cell(r[c]) for c in CSV_COLUMNS])


def write_json(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as fh:
        json.dump(obj, fh, indent=2, sort_keys=True, default=str)
        fh.write("\n")


def read_csv_rows(path):
    path = Path(path)
    if not path.is_file():
        raise FileNotFoundError(f"required input CSV is missing: {path}")
    with open(path, newline="") as fh:
        return list(csv.DictReader(fh))


def run_replay(series, gics):
    """Pure end-to-end replay on in-memory data. Returns dict with monthly/weekly records, thresholds, criteria."""
    all_dates = sorted(series)
    m_dates, w_dates = monthly_dates(all_dates), weekly_dates(all_dates)
    start = first_week_with_252(series)
    if start is None:
        raise ValueError(f"no week has at least {CALIB_MIN_PAIRS} pairs with a 252-day value")
    m_stats = compute_stats(series, m_dates, gics)
    th = derive_thresholds(m_stats, start)
    if th["T_H"] is None or th["S_L"] is None:
        raise ValueError("calibration window has no computable months; thresholds cannot be derived")
    monthly, m_p90 = evaluate_series(m_stats, th["T_H"], th["S_L"])
    weekly, w_p90 = evaluate_series(compute_stats(series, w_dates, gics), th["T_H"], th["S_L"])
    th["monthly_outcome_p90"], th["weekly_outcome_p90"] = m_p90, w_p90
    crit = evaluate_criteria(monthly, th["T_H"], th["S_L"])
    return {"monthly": monthly, "weekly": weekly, "thresholds": th, "criteria": crit}


def _fmt(x):
    return "n/a" if x is None else (f"{x:.4f}" if isinstance(x, float) else str(x))


def print_summary(result):
    th, crit = result["thresholds"], result["criteria"]
    print(f"Calibration start {th['calibration_start']}  T_H={th['T_H']}  S_L={th['S_L']}  "
          f"(months: {th['n_calibration_months']})")
    print(f"Monthly months: {len(result['monthly'])}; weekly rows: {len(result['weekly'])} (weekly: comparison only)")
    for name, c in crit.items():
        if name == "all_pass":
            continue
        print(f"  criterion {name}: {'PASS' if c['pass'] else 'FAIL'}")
        for k, v in c["evidence"].items():
            if k == "months":
                for m in v:
                    print(f"      {m['date']}: banks median={_fmt(m['banks_median_c60'])} "
                          f"banks share<0.3={_fmt(m['banks_share_below_0.3'])} "
                          f"banks H={m['banks_leg_h']} L-group={m['banks_l_group']} | "
                          f"pop median={_fmt(m['pop_median_c60'])} pop L-pop share={_fmt(m['pop_l_pop_share'])} "
                          f"-> trip&pop-quiet={m['banks_trip_and_pop_quiet']}")
            elif isinstance(v, (dict, list)):
                print(f"      {k}: {json.dumps(v, default=str)}")
            else:
                print(f"      {k}: {_fmt(v)}")
    print("OVERALL:", "PASS" if crit["all_pass"] else "FAIL (E stays bound)")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--base-dir", default=str(HERE), help="directory holding series/ and pairs_gics.csv")
    ap.add_argument("--results-dir", default=None, help="output directory (default: <base-dir>/results)")
    args = ap.parse_args(argv)
    base = Path(args.base_dir)
    out_dir = Path(args.results_dir) if args.results_dir else base / "results"
    series = build_series(read_csv_rows(base / "series" / "pair_stats_weekly.csv"))
    gics = load_gics(read_csv_rows(base / "pairs_gics.csv"))
    result = run_replay(series, gics)
    out_dir.mkdir(parents=True, exist_ok=True)
    write_records_csv(out_dir / "monthly.csv", result["monthly"])
    write_records_csv(out_dir / "weekly.csv", result["weekly"])
    write_json(out_dir / "thresholds.json", result["thresholds"])
    write_json(out_dir / "criteria.json", result["criteria"])
    print_summary(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

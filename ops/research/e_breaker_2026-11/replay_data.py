#!/usr/bin/env python3
"""Historical dataset builder for the Strategy E pair-correlation breaker replay.

Standard library only. Fetches daily closes from the Nasdaq historical endpoint
for every distinct ticker in PAIRS, caches the raw JSON responses under
``ops/research/e_breaker_2026-11/_raw/`` (scratch; never committed), and writes
weekly pair statistics (c60, c252, z252) plus a coverage table to ``series/``.

Regenerate (from the repository root):

    python3 ops/research/e_breaker_2026-11/replay_data.py

This script builds data only; it defines no gate and evaluates none.
"""
import argparse
import csv
import datetime as dt
import json
import math
import statistics
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW_DIR = HERE / "_raw"
SERIES_DIR = HERE / "series"

FROM_DATE = "2016-01-01"
TO_DATE = "2026-11-06"
SHORT_HISTORY_CUTOFF = "2017-01-01"  # first close after this date => short_history
W_SHORT = 60
W_LONG = 252
SLEEP_SECONDS = 1.0
MAX_RETRIES = 2  # retries after the first attempt

URL_TEMPLATE = (
    "https://api.nasdaq.com/api/quote/{ticker}/historical"
    "?assetclass=stocks&fromdate={fromdate}&todate={todate}&limit=9999"
)
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json",
}

_PAIRS_TEXT = """
AAL/DAL AAP/ORLY ACM/J AIG/HIG ALL/PGR AMD/NVDA APA/FANG AVGO/MRVL BAX/BDX
BEN/TROW CAG/GIS CB/TRV CLF/NUE CLX/CHD CMI/PCAR CNC/MOH COF/AXP COR/MCK
CVS/CI DLTR/DG DOV/IR DOW/LYB DVN/EOG DY/EME EFX/TRU EFX/VRSK ELV/UNH
EMN/CE EXC/AEP F/GM FCX/SCCO FDX/UPS FITB/HBAN FTNT/CRWD GILD/AMGN GS/MS
H/MAR HAL/BKR HAL/SLB HPE/DELL HUBB/NVT INTC/TXN IP/PKG KBH/DHI KMB/PG
LII/TT LRCX/KLAC MCHP/ADI MDB/SNOW MET/PRU MTZ/PWR MU/AMAT NOC/LMT NOW/WDAY
ON/NXPI PANW/CRWD PEP/KO PPG/SHW RF/KEY RJF/LPLA ROST/TJX RVTY/TMO STT/BNY
SWK/ITW TER/AMAT TFC/MTB TOL/NVR TXT/GD USB/PNC VRT/GEV VRT/HUBB VRT/NVT
WDC/STX WFC/C XPO/ODFL ZBH/SYK
"""
PAIRS = tuple(_PAIRS_TEXT.split())


def split_pair(pair):
    """'A/B' -> ('A', 'B')."""
    a, b = pair.split("/")
    return a, b


def distinct_tickers(pairs=PAIRS):
    return sorted({t for p in pairs for t in split_pair(p)})


# ----------------------------------------------------------------- parsing

def parse_nasdaq_date(text):
    """'MM/DD/YYYY' -> 'YYYY-MM-DD'. Raises ValueError on bad input."""
    return dt.datetime.strptime(text.strip(), "%m/%d/%Y").date().isoformat()


def parse_close(text):
    """'$1,234.56' -> 1234.56; 'N/A', '', None or non-positive -> None."""
    if text is None:
        return None
    s = str(text).strip().replace("$", "").replace(",", "")
    if not s or s.upper() == "N/A":
        return None
    try:
        v = float(s)
    except ValueError:
        return None
    if not math.isfinite(v) or v <= 0:
        return None
    return v


def parse_nasdaq_row(row):
    """One Nasdaq row dict -> (iso_date, close) or None if date/close unusable."""
    try:
        d = parse_nasdaq_date(row.get("date", ""))
    except (ValueError, AttributeError):
        return None
    c = parse_close(row.get("close"))
    if c is None:
        return None
    return d, c


def parse_nasdaq_payload(payload):
    """Full response dict -> sorted list of (iso_date, close), duplicates collapsed."""
    data = (payload or {}).get("data") or {}
    table = data.get("tradesTable") or {}
    rows = table.get("rows") or []
    out = {}
    for row in rows:
        parsed = parse_nasdaq_row(row)
        if parsed:
            out[parsed[0]] = parsed[1]
    return sorted(out.items())


# ------------------------------------------------------------- pure maths

def log_returns(prices):
    """Close-to-close log returns; len(result) == len(prices) - 1."""
    return [math.log(prices[i] / prices[i - 1]) for i in range(1, len(prices))]


def pearson(x, y):
    """Pearson correlation; None if undefined (len < 2 or zero variance)."""
    if len(x) != len(y):
        raise ValueError("pearson: length mismatch")
    n = len(x)
    if n < 2:
        return None
    mx = math.fsum(x) / n
    my = math.fsum(y) / n
    sxy = math.fsum((a - mx) * (b - my) for a, b in zip(x, y, strict=True))
    sxx = math.fsum((a - mx) ** 2 for a in x)
    syy = math.fsum((b - my) ** 2 for b in y)
    if sxx <= 0 or syy <= 0:
        return None
    return sxy / math.sqrt(sxx * syy)


def trailing_window(values, end, window):
    """The `window` values ending at index `end` inclusive, or None if fewer exist."""
    if window < 1:
        raise ValueError("window must be >= 1")
    if end < 0 or end >= len(values) or end + 1 < window:
        return None
    return values[end + 1 - window:end + 1]


def rolling_pearson(x, y, end, window):
    """Pearson over the trailing `window` pairs ending at `end`; None if short."""
    wx = trailing_window(x, end, window)
    wy = trailing_window(y, end, window)
    if wx is None or wy is None:
        return None
    return pearson(wx, wy)


def trailing_zscore(values, end, window):
    """(values[end] - mean(window)) / sample-stdev(window), window ending at `end`
    inclusive. None if the window is short, has < 2 points, or has zero spread."""
    w = trailing_window(values, end, window)
    if w is None or len(w) < 2:
        return None
    sd = statistics.stdev(w)
    if sd <= 0:
        return None
    return (values[end] - statistics.fmean(w)) / sd


# ------------------------------------------------------------ week buckets

def iso_week_key(date_text):
    """'YYYY-MM-DD' -> (iso_year, iso_week)."""
    iso = dt.date.fromisoformat(date_text).isocalendar()
    return iso[0], iso[1]


def last_date_per_iso_week(dates):
    """Last (max) date of each ISO week among `dates`; sorted ascending."""
    best = {}
    for d in dates:
        k = iso_week_key(d)
        if k not in best or d > best[k]:
            best[k] = d
    return sorted(best.values())


# ----------------------------------------------------------- pair statistics

def pair_stats_at(dates, prices_a, prices_b, idx_list=None):
    """Stats for one pair on its common dates.

    `dates`, `prices_a`, `prices_b` are aligned lists on the intersection of
    both legs' trading dates. Returns {date: (c60, c252, z252)} for the dates at
    positions `idx_list` (default: all). Return i is log(P[i]/P[i-1]), so a
    window of N returns ending at i needs i >= N; the z-score window is N
    log-price-ratio levels ending at i (needs i >= N-1). Short windows -> None.
    """
    ra = log_returns(prices_a)
    rb = log_returns(prices_b)
    # return list index j corresponds to price index j+1
    spread = [math.log(a / b) for a, b in zip(prices_a, prices_b, strict=True)]
    out = {}
    for i in (range(len(dates)) if idx_list is None else idx_list):
        j = i - 1
        c60 = rolling_pearson(ra, rb, j, W_SHORT) if j >= 0 else None
        c252 = rolling_pearson(ra, rb, j, W_LONG) if j >= 0 else None
        z252 = trailing_zscore(spread, i, W_LONG)
        out[dates[i]] = (c60, c252, z252)
    return out


def common_series(closes_a, closes_b):
    """Intersect two [(date, close)] lists -> (dates, prices_a, prices_b)."""
    da = dict(closes_a)
    db = dict(closes_b)
    dates = sorted(set(da) & set(db))
    return dates, [da[d] for d in dates], [db[d] for d in dates]


def weekly_rows(closes, pairs=PAIRS):
    """closes: {ticker: [(date, close)]} -> sorted list of row lists
    [date, pair, c60, c252, z252] with values rounded to 4 dp ('' if empty)."""
    rows = []
    for pair in pairs:
        a, b = split_pair(pair)
        if not closes.get(a) or not closes.get(b):
            continue
        dates, pa, pb = common_series(closes[a], closes[b])
        if len(dates) < 2:
            continue
        keep = set(last_date_per_iso_week(dates))
        idx = [i for i, d in enumerate(dates) if d in keep]
        stats = pair_stats_at(dates, pa, pb, idx)
        for d, vals in stats.items():
            rows.append([d, pair] + ["" if v is None else f"{round(v, 4):.4f}" for v in vals])
    rows.sort(key=lambda r: (r[0], r[1]))
    return rows


def coverage_status(first_date, n_closes):
    if n_closes == 0 or first_date is None:
        return "fetch_failed"
    if first_date > SHORT_HISTORY_CUTOFF:
        return "short_history"
    return "ok"


# ------------------------------------------------------------------ network

def fetch_raw(ticker, fromdate=FROM_DATE, todate=TO_DATE):
    """GET the Nasdaq historical JSON; retries at most twice with backoff.
    Returns (payload_or_None, error_text_or_None)."""
    url = URL_TEMPLATE.format(ticker=ticker, fromdate=fromdate, todate=todate)
    err = None
    for attempt in range(MAX_RETRIES + 1):
        if attempt:
            time.sleep(3.0 * attempt)
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode("utf-8", "ignore")
            payload = json.loads(body)
            if not parse_nasdaq_payload(payload):
                err = "HTTP 200 but no rows: " + body[:200].replace("\n", " ")
                continue
            return payload, None
        except urllib.error.HTTPError as e:
            err = f"HTTP {e.code}: " + e.read().decode("utf-8", "ignore")[:200]
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as e:
            err = f"{type(e).__name__}: {e}"
    return None, err


def load_ticker(ticker, raw_dir=RAW_DIR, sleep=SLEEP_SECONDS):
    """Cached fetch. Returns (closes, error). Network skipped if cache exists."""
    cache = Path(raw_dir) / f"{ticker}.json"
    if cache.exists():
        return parse_nasdaq_payload(json.loads(cache.read_text())), None
    time.sleep(sleep)
    payload, err = fetch_raw(ticker)
    if payload is None:
        return [], err
    Path(raw_dir).mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(payload))
    return parse_nasdaq_payload(payload), None


# --------------------------------------------------------------------- main

def write_csv(path, header, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--raw-dir", default=str(RAW_DIR))
    ap.add_argument("--series-dir", default=str(SERIES_DIR))
    ap.add_argument("--sleep", type=float, default=SLEEP_SECONDS)
    args = ap.parse_args(argv)

    closes, errors = {}, {}
    for t in distinct_tickers():
        closes[t], err = load_ticker(t, args.raw_dir, args.sleep)
        if err:
            errors[t] = err
            print(f"{t}: FAILED {err}", flush=True)

    series_dir = Path(args.series_dir)
    cov = []
    for t in distinct_tickers():
        c = closes[t]
        first = c[0][0] if c else None
        last = c[-1][0] if c else None
        cov.append([t, first or "", last or "", len(c), coverage_status(first, len(c))])
    write_csv(series_dir / "coverage.csv",
              ["ticker", "first_date", "last_date", "n_closes", "status"], cov)

    n_failed = sum(1 for r in cov if r[4] == "fetch_failed")
    if n_failed > len(cov) / 2:
        print("Most tickers failed; not writing pair_stats_weekly.csv", flush=True)
        return 1
    rows = weekly_rows(closes)
    write_csv(series_dir / "pair_stats_weekly.csv",
              ["date", "pair", "c60", "c252", "z252"], rows)

    counts = {}
    for r in cov:
        counts[r[4]] = counts.get(r[4], 0) + 1
    per_date = {}
    for r in rows:
        if r[3] != "":
            per_date[r[0]] = per_date.get(r[0], 0) + 1
    first60 = next((d for d in sorted(per_date) if per_date[d] >= 60), None)
    print("status counts:", counts)
    print("earliest weekly date with >=60 pairs having c252:", first60)
    print("rows:", len(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Public-data event study: do SECOND-HOP industries drift after an oil / geopolitical supply shock?

Research tool for the shock-native candidate (ops/research/shock_native_candidate_dossier_2026-10-19.md,
Strategy.md Rev 50). It answers one question SL1 needs and no published source measures: after a
qualifying oil/geopolitical supply shock, do industries TWO economic hops from petroleum (industries
whose main suppliers or customers are themselves first-hop exposed) drift, market-hedged, over 1-12
weeks -- and by how much, per episode and pooled, against a placebo base rate?

Design constraints (from the dossier, Section 3.6): the link map must be STATIC and PUBLIC so that no
LLM memorisation contaminates the backtest. It is the BEA input-output USE table (summary level, 2023,
after redefinitions, producers' prices -- the Menzly & Ozbas 2010 source), downloaded from BEA's
static bundle and parsed with the standard library only. Nothing here touches BigQuery, live
triggers or the strategy spec.

Three price sources, selectable with --source (all public, no key):
  french   Kenneth French's daily value-weighted 49-industry portfolios (CRSP universe, 1926-, no
           survivorship bias) plus the daily Fama-French market factor. The BEA hop lists are mapped
           to French's SIC-based industries (FRENCH_MAP). This is the only source that covers the
           1990 / 2003 / 2011 episodes, so it is the long-history primary.
  nasdaq   api.nasdaq.com historical quotes for the ETF / stock-basket proxy table (PROXIES): daily
           closes, split-adjusted, NOT dividend-adjusted, and capped at ~10 years of history, so it
           covers the 2019 / 2022 / 2026 episodes (+ the 2020 control) only. ETF-era cross-check.
  yahoo    Yahoo Finance v8 chart endpoint for the same proxy table (dividend-adjusted, full
           history). Implemented with the cookie+crumb handshake, but at the time of writing
           (2026-10-19) query1/query2.finance.yahoo.com answered HTTP 429 to every request from
           this host for the whole session, so no result in the memo comes from it.

Pipeline (each stage is a subcommand; `all` runs them in order):

    python scripts/research/shock_episode_event_study.py all --data-dir <dir> --source french

  bea       download AllTablesIO.zip (~16 MB) from apps.bea.gov into <data-dir>/bea/
  linkmap   parse the 2023 summary use table -> first-hop / second-hop industry lists (+ shares)
  prices    download the chosen source's daily data into <data-dir>/<source>/
  study     run the event study, print the markdown tables, write <data-dir>/results_<tag>.json

Link-map rules (fixed before any price was looked at; see the memo for the rationale):
  universe     the 71 summary industries minus government (5), 'Management of companies' (55, a
               holding-company overhead row with no product) and 'Housing' (HS, an imputation) = 64.
  direct(j)    max( petroleum INPUT share, petroleum OUTPUT share ), where petroleum = commodities
               211 (oil & gas extraction) + 324 (petroleum & coal products); input share is per
               dollar of j's total industry output, output share per dollar of j's commodity output.
  first hop    top decile (7 of 64) by direct(j).
  second hop   two rules, both reported:
               'weighted' (primary): score(j) = sum over first-hop i NOT in {211, 324} of
                   [ a(i->j) + a(j->i) ] * direct(i)   -- a two-hop transmission coefficient; the link
                   is weighted by how petroleum-exposed the intermediate industry is, and the direct
                   petroleum commodities are excluded as intermediates so that 'second hop' cannot
                   collapse into 'direct petroleum buyers ranked 8-13'.
               'literal': the brief's wording -- top decile of the rest by max(input share, output
                   share) to ALL first-hop industries including 211/324.
               In both, second hop = top decile (6 of 57) of the non-first-hop universe.

Measurement: for each episode onset (first trading day on/after the trigger date) and horizon
h in {1,2,4,6,8,12} weeks (5h trading days), the hop basket's cumulative market-hedged return
CAR_h = sum_{t=1..5h} (r_t - beta * m_t), beta from OLS over the 252 trading days before onset,
market = the Fama-French market factor (french) or SPY (nasdaq / yahoo). Reported: second-hop CAR, first-hop CAR,
and the spread second - first. Pooled mean over episodes with a percentile bootstrap over episodes
(n is tiny; the CI is honest about that), and the same statistics over 12 seeded placebo onsets
(random trading days >= 26 weeks from any listed event) plus a 500-draw placebo distribution for
the percentile of the pooled shock-episode mean.

Dependencies: standard library + numpy + pandas. No tests exercise the network.
"""

from __future__ import annotations

import argparse
import datetime as dt
import http.cookiejar
import io
import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

import numpy as np
import pandas as pd

# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------

BEA_ZIP_URL = "https://apps.bea.gov/industry/iTables%20Static%20Files/AllTablesIO.zip"
BEA_USE_XLSX = "IOUse_After_Redefinitions_PRO_1997-2023_Summary.xlsx"
BEA_YEAR = "2023"
PETROLEUM = ("211", "324")
EXCLUDED_INDUSTRIES = {"GFGD", "GFGN", "GFE", "GSLG", "GSLE", "55", "HS"}

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
MARKET = "MKT"  # column name of the market series inside the returns frame, whatever the source
FRENCH_49_URL = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/49_Industry_Portfolios_daily_CSV.zip"
FRENCH_FACTORS_URL = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip"
NASDAQ_URL = "https://api.nasdaq.com/api/quote/{ticker}/historical?assetclass={cls}&fromdate={start}&todate={end}&limit=20000"
NASDAQ_YEARS = 10
HORIZONS_WEEKS = (1, 2, 4, 6, 8, 12)
BETA_WINDOW = 252
MIN_BETA_OBS = 200
MIN_BASKET_MEMBERS = 3
MIN_INDUSTRIES_PER_HOP = 3
PLACEBO_N = 12
PLACEBO_DIST_N = 500
PLACEBO_EXCLUSION_WEEKS = 26
BOOTSTRAP_REPS = 2000
SEED = 20261019

# Episodes: (label, trigger date, kind). Onset = first trading day on/after the trigger date.
EPISODES = [
    ("1990 Iraq-Kuwait", "1990-08-02", "shock"),
    ("2003 Iraq", "2003-03-19", "shock"),
    ("2011 Libya", "2011-02-15", "shock"),
    ("2019 Abqaiq", "2019-09-16", "shock"),
    ("2022 Ukraine", "2022-02-24", "shock"),
    ("2026 Iran / Hormuz", "2026-02-28", "shock"),
    ("2008-07 oil peak (demand, control)", "2008-07-14", "control"),
    ("2020-03 COVID / price war (demand, control)", "2020-03-09", "control"),
]

# BEA summary industry -> Kenneth French 49-industry portfolio(s) (SIC-based; Siccodes49.txt). Several BEA
# industries fold into one French industry; a hop is the equal-weighted mean over the DISTINCT French
# industries it maps to, and a French industry already used by the first hop is never also a second-hop
# member (so 487OS / 482 / 484, which fold into 'Trans' with air, water and pipelines, drop out of
# the second hop under this source -- stated in the memo).
FRENCH_MAP: dict[str, list[str]] = {
    "211": ["Oil"], "324": ["Oil"], "213": ["Oil"],
    "486": ["Trans"], "481": ["Trans"], "483": ["Trans"], "482": ["Trans"], "484": ["Trans"], "487OS": ["Trans"],
    "22": ["Util"],
    "212": ["Mines", "Coal"], "327": ["BldMt"], "523": ["Fin"], "561": ["BusSv"], "532RL": ["BusSv"],
    "325": ["Chems"], "332": ["FabPr"], "331": ["Steel"], "333": ["Mach"], "493": ["BusSv"], "562": ["BusSv"],
    "521CI": ["Banks"], "722": ["Meals"], "721": ["Meals"], "445": ["Rtail"], "452": ["Rtail"], "322": ["Paper"],
    "ORE": ["RlEst"], "326": ["Rubbr"], "111CA": ["Agric"], "42": ["Whlsl"], "4A0": ["Rtail"], "441": ["Rtail"],
}

# Proxy table. ETF first where a matched sub-industry ETF exists; otherwise an equal-weighted basket
# of large US-listed names in the matched GICS sub-industry (chosen from today's constituents --
# a SURVIVORSHIP-biased rule; stated in the memo). A basket member is used only when its price
# history covers the beta window and the full 12-week horizon of the episode.
PROXIES: dict[str, dict] = {
    # ---- first hop candidates (every industry the link map can select needs an entry) ----
    "211": {"etf": "XOP", "basket": ["XOM", "CVX", "COP", "EOG", "OXY", "DVN", "APA", "HES"]},
    "324": {"etf": "CRAK", "basket": ["VLO", "MPC", "PSX", "DINO", "PBF", "CVI"]},
    "486": {"etf": "AMLP", "basket": ["KMI", "WMB", "OKE", "EPD", "ET", "MPLX", "TRGP", "PAA"]},
    "213": {"etf": "OIH", "basket": ["SLB", "HAL", "BKR", "NOV", "FTI", "HP", "PTEN"]},
    "481": {"etf": "JETS", "basket": ["DAL", "UAL", "AAL", "LUV", "ALK", "JBLU", "SKYW", "ALGT"]},
    "483": {"etf": "SEA", "basket": ["KEX", "MATX", "FRO", "GOGL", "STNG", "DAC"]},
    "22": {"etf": "XLU", "basket": ["NEE", "DUK", "SO", "D", "AEP", "EXC", "SRE", "XEL"]},
    # ---- second hop candidates ----
    "487OS": {"etf": None, "basket": ["FDX", "UPS", "EXPD", "CHRW", "LSTR", "HUBG", "FWRD"]},
    "212": {"etf": "XME", "basket": ["FCX", "NEM", "VMC", "MLM", "BTU", "CLF", "HL", "RGLD"]},
    "532RL": {"etf": None, "basket": ["URI", "CAR", "AER", "AL", "GATX", "R", "WSC"]},
    "523": {"etf": "IAI", "basket": ["GS", "MS", "SCHW", "ICE", "CME", "NDAQ", "RJF", "LPLA"]},
    "561": {"etf": None, "basket": ["BKNG", "EXPE", "RHI", "MAN", "ROL", "ABM", "ADT"]},
    "327": {"etf": None, "basket": ["EXP", "OC", "USLM", "CRH", "APOG", "MLM"]},
    "482": {"etf": None, "basket": ["UNP", "CSX", "NSC", "CP", "CNI"]},
    "484": {"etf": None, "basket": ["ODFL", "JBHT", "KNX", "SAIA", "XPO", "WERN", "ARCB"]},
    "325": {"etf": None, "basket": ["LIN", "SHW", "APD", "ECL", "DD", "DOW", "LYB", "PPG"]},
    "332": {"etf": None, "basket": ["PH", "ETN", "SNA", "SWK", "TKR", "ATI", "MLI", "WOR"]},
    "331": {"etf": "SLX", "basket": ["NUE", "STLD", "CLF", "X", "AA", "CMC", "RS", "ATI"]},
    "333": {"etf": None, "basket": ["CAT", "DE", "ITW", "DOV", "IR", "CMI", "PCAR", "XYL"]},
    "493": {"etf": None, "basket": ["PLD", "EXR", "PSA", "CUBE", "REXR", "FR", "EGP"]},
    "562": {"etf": None, "basket": ["WM", "RSG", "WCN", "CLH", "CWST", "SRCL"]},
    "521CI": {"etf": "KBE", "basket": ["JPM", "BAC", "WFC", "C", "USB", "PNC", "TFC", "COF"]},
    "722": {"etf": None, "basket": ["MCD", "SBUX", "CMG", "YUM", "DRI", "QSR", "DPZ", "TXRH"]},
    "721": {"etf": None, "basket": ["MAR", "HLT", "H", "WH", "CHH", "IHG"]},
    "445": {"etf": None, "basket": ["KR", "ACI", "SFM", "CASY", "WMK", "IMKTA"]},
    "452": {"etf": None, "basket": ["WMT", "COST", "TGT", "DG", "DLTR", "BJ", "OLLI"]},
    "322": {"etf": None, "basket": ["IP", "PKG", "GPK", "SON", "SW", "CLW"]},
    "ORE": {"etf": "IYR", "basket": ["SPG", "O", "AVB", "EQR", "VTR", "WELL", "BXP", "ARE"]},
    "326": {"etf": None, "basket": ["BERY", "AMCR", "TRS", "CSL", "GT", "CTB"]},
    "111CA": {"etf": "MOO", "basket": ["ADM", "BG", "CALM", "TSN", "FDP", "AGRO"]},
}


# --------------------------------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------------------------------


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def http_get(url: str, opener: urllib.request.OpenerDirector | None = None, timeout: int = 120) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    op = opener or urllib.request.build_opener()
    with op.open(req, timeout=timeout) as resp:
        return resp.read()


# --------------------------------------------------------------------------------------------------
# Stage 1: BEA download + stdlib xlsx parse
# --------------------------------------------------------------------------------------------------


def cmd_bea(data_dir: Path) -> Path:
    out = data_dir / "bea"
    out.mkdir(parents=True, exist_ok=True)
    zpath = out / "AllTablesIO.zip"
    if not zpath.exists():
        log(f"downloading {BEA_ZIP_URL}")
        zpath.write_bytes(http_get(BEA_ZIP_URL, timeout=600))
    xpath = out / BEA_USE_XLSX
    if not xpath.exists():
        with zipfile.ZipFile(zpath) as z:
            xpath.write_bytes(z.read(BEA_USE_XLSX))
    log(f"BEA use table at {xpath} ({xpath.stat().st_size} bytes)")
    return xpath


def _col_index(ref: str) -> int:
    letters = re.match(r"[A-Z]+", ref).group(0)
    n = 0
    for ch in letters:
        n = n * 26 + ord(ch) - 64
    return n


def read_xlsx_sheet(xlsx_path: Path, sheet_name: str) -> dict[int, dict[int, str]]:
    """Return {row_number: {col_number: cell_text}} for one sheet, using only the standard library."""
    ns = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
    rns = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
    with zipfile.ZipFile(xlsx_path) as z:
        shared = [
            "".join(t.text or "" for t in si.iter(ns + "t"))
            for si in ET.fromstring(z.read("xl/sharedStrings.xml"))
        ]
        wb = ET.fromstring(z.read("xl/workbook.xml"))
        rid = None
        for sh in wb.iter(ns + "sheet"):
            if sh.get("name") == sheet_name:
                rid = sh.get(rns + "id")
        if rid is None:
            raise KeyError(f"sheet {sheet_name!r} not in {xlsx_path.name}")
        rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        target = None
        for rel in rels:
            if rel.get("Id") == rid:
                target = rel.get("Target")
        root = ET.fromstring(z.read("xl/" + target.lstrip("/").removeprefix("xl/")))
    rows: dict[int, dict[int, str]] = {}
    for r in root.iter(ns + "row"):
        d: dict[int, str] = {}
        for c in r.iter(ns + "c"):
            v = c.find(ns + "v")
            if v is None:
                continue
            d[_col_index(c.get("r"))] = shared[int(v.text)] if c.get("t") == "s" else v.text
        rows[int(r.get("r"))] = d
    return rows


def _num(x: str | None) -> float:
    try:
        return float(x)
    except (TypeError, ValueError):
        return 0.0  # BEA prints '...' for suppressed / zero cells


class UseTable:
    """Summary-level use table: U[commodity, industry], total industry output, total commodity output."""

    def __init__(self, rows: dict[int, dict[int, str]]):
        # Layout verified 2026-10-19: row 6 = industry codes from col 3, row 7 = names, commodity rows
        # 8.. until the 'Total Intermediate' row; col 74 = Total Intermediate, col 96 = Total Commodity
        # Output; the 'Total Industry Output' row is the last numeric row.
        hdr, names_row = rows[6], rows[7]
        # industry columns run from col 3 up to (not including) the 'Total Intermediate' column; the
        # final-use columns (F010 ...) that follow it are not industries.
        ti_col = min(k for k, v in names_row.items() if v == "Total Intermediate")
        self.ind_codes = [hdr[k] for k in sorted(hdr) if 3 <= k < ti_col]
        ind_cols = {hdr[k]: k for k in sorted(hdr) if 3 <= k < ti_col}
        self.names: dict[str, str] = {}
        self.U: dict[tuple[str, str], float] = {}
        self.tco: dict[str, float] = {}
        tio_row = None
        tco_col = None
        for k, v in names_row.items():
            if v == "Total Commodity Output":
                tco_col = k
        for rn in sorted(rows):
            d = rows[rn]
            if d.get(2) == "Total Industry Output":
                tio_row = rn
        if tco_col is None or tio_row is None:
            raise ValueError("use-table layout changed: Total Commodity Output / Total Industry Output not found")
        for rn in sorted(rows):
            if rn <= 7 or rn >= tio_row:
                continue
            d = rows[rn]
            code = d.get(1)
            if not code or code.startswith("V00") or d.get(2) in ("Total Intermediate", "Total Value Added"):
                continue
            self.names[code] = d.get(2, "")
            self.tco[code] = _num(d.get(tco_col))
            for ind, k in ind_cols.items():
                self.U[(code, ind)] = _num(d.get(k))
        self.tio = {ind: _num(rows[tio_row].get(k)) for ind, k in ind_cols.items()}

    def a_in(self, commodity: str, industry: str) -> float:
        """Input coefficient: dollars of `commodity` used per dollar of `industry` output."""
        return self.U.get((commodity, industry), 0.0) / self.tio[industry] if self.tio[industry] else 0.0

    def a_out(self, commodity: str, industry: str) -> float:
        """Sales share: fraction of `commodity`'s total output sold to `industry`."""
        return self.U.get((commodity, industry), 0.0) / self.tco[commodity] if self.tco[commodity] else 0.0


def build_linkmap(table: UseTable) -> dict:
    universe = [c for c in table.ind_codes if c not in EXCLUDED_INDUSTRIES]
    direct = {}
    for j in universe:
        s_in = sum(table.a_in(c, j) for c in PETROLEUM)
        s_out = sum(table.a_out(j, c) for c in PETROLEUM)
        direct[j] = {"in": s_in, "out": s_out, "score": max(s_in, s_out)}
    n1 = math.ceil(len(universe) / 10)
    first = sorted(universe, key=lambda j: -direct[j]["score"])[:n1]
    rest = [j for j in universe if j not in first]
    n2 = math.ceil(len(rest) / 10)

    first_np = [i for i in first if i not in PETROLEUM]
    weighted = {}
    for j in rest:
        parts = {i: (table.a_in(i, j) + table.a_out(j, i)) * direct[i]["score"] for i in first_np}
        weighted[j] = {"score": sum(parts.values()), "parts": parts}
    literal = {}
    for j in rest:
        s_in = sum(table.a_in(i, j) for i in first)
        s_out = sum(table.a_out(j, i) for i in first)
        literal[j] = {"in": s_in, "out": s_out, "score": max(s_in, s_out)}
    second_w = sorted(rest, key=lambda j: -weighted[j]["score"])[:n2]
    second_l = sorted(rest, key=lambda j: -literal[j]["score"])[:n2]
    return {
        "bea_year": BEA_YEAR,
        "universe_n": len(universe),
        "first_hop": [{"code": j, "name": table.names[j], **direct[j]} for j in first],
        "second_hop_weighted": [{"code": j, "name": table.names[j], **weighted[j]} for j in second_w],
        "second_hop_literal": [{"code": j, "name": table.names[j], **literal[j]} for j in second_l],
        "direct_all": {j: direct[j] for j in universe},
    }


def cmd_linkmap(data_dir: Path) -> dict:
    xpath = cmd_bea(data_dir)
    table = UseTable(read_xlsx_sheet(xpath, BEA_YEAR))
    lm = build_linkmap(table)
    (data_dir / "linkmap.json").write_text(json.dumps(lm, indent=1))
    log("first hop: " + ", ".join(f"{e['code']} ({e['score']:.3f})" for e in lm["first_hop"]))
    log("second hop (weighted): " + ", ".join(f"{e['code']} ({e['score']:.4f})" for e in lm["second_hop_weighted"]))
    log("second hop (literal): " + ", ".join(f"{e['code']} ({e['score']:.3f})" for e in lm["second_hop_literal"]))
    missing = [e["code"] for k in ("first_hop", "second_hop_weighted", "second_hop_literal") for e in lm[k] if e["code"] not in PROXIES]
    if missing:
        raise SystemExit(f"no proxy row for selected industries: {missing}")
    return lm


# --------------------------------------------------------------------------------------------------
# Stage 2: prices (Yahoo v8 chart; cookie + crumb handshake, paced, retried)
# --------------------------------------------------------------------------------------------------


class Yahoo:
    def __init__(self) -> None:
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))
        self.crumb = ""

    def handshake(self) -> None:
        try:
            http_get("https://fc.yahoo.com", self.opener, timeout=30)
        except urllib.error.HTTPError:
            pass  # fc.yahoo.com answers 404 but sets the A3 cookie; that is the point of the call
        self.crumb = http_get("https://query2.finance.yahoo.com/v1/test/getcrumb", self.opener, timeout=30).decode()
        if not self.crumb or "Too Many" in self.crumb:
            raise RuntimeError(f"Yahoo crumb handshake failed: {self.crumb!r}")

    def chart(self, ticker: str) -> dict:
        q = urllib.parse.urlencode(
            {"period1": 0, "period2": 9_999_999_999, "interval": "1d", "events": "div,split", "crumb": self.crumb}
        )
        url = f"https://query2.finance.yahoo.com/v8/finance/chart/{urllib.parse.quote(ticker)}?{q}"
        delay = 5.0
        for attempt in range(6):
            try:
                return json.loads(http_get(url, self.opener, timeout=60))
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return {"chart": {"result": None, "error": {"code": "404", "description": "not found"}}}
                if e.code != 429 or attempt == 5:
                    raise
                log(f"  429 on {ticker}; sleeping {delay:.0f}s then re-handshaking")
                time.sleep(delay)
                delay *= 2
                self.handshake()
        raise RuntimeError("unreachable")


def all_tickers(linkmap: dict) -> list[tuple[str, str]]:
    """(ticker, 'etf'|'stocks') for every proxy the selected industries can need, plus SPY as market."""
    codes = [e["code"] for k in ("first_hop", "second_hop_weighted", "second_hop_literal") for e in linkmap[k]]
    out = {"SPY": "etf"}
    for c in dict.fromkeys(codes):
        p = PROXIES[c]
        if p["etf"]:
            out[p["etf"]] = "etf"
        for t in p["basket"]:
            out[t] = "stocks"
    return sorted(out.items())


def download_yahoo(linkmap: dict, out: Path, pace: float) -> None:
    todo = [t for t, _ in all_tickers(linkmap) if not (out / f"{t}.json").exists()]
    log(f"yahoo: {len(todo)} tickers to download")
    if not todo:
        return
    y = Yahoo()
    y.handshake()
    for i, t in enumerate(todo, 1):
        d = y.chart(t)
        (out / f"{t}.json").write_text(json.dumps(d))
        res = d["chart"]["result"]
        n = len(res[0]["timestamp"]) if res and res[0].get("timestamp") else 0
        log(f"  [{i}/{len(todo)}] {t}: {n} bars")
        time.sleep(pace)


def download_nasdaq(linkmap: dict, out: Path, pace: float) -> None:
    today = dt.date.today()
    start = today.replace(year=today.year - NASDAQ_YEARS)
    todo = [(t, cls) for t, cls in all_tickers(linkmap) if not (out / f"{t}.json").exists()]
    log(f"nasdaq: {len(todo)} tickers to download ({start} .. {today})")
    for i, (t, cls) in enumerate(todo, 1):
        url = NASDAQ_URL.format(ticker=urllib.parse.quote(t), cls=cls, start=start, end=today)
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                body = resp.read()
        except urllib.error.HTTPError as e:
            log(f"  [{i}/{len(todo)}] {t}: HTTP {e.code}, skipped")
            time.sleep(pace)
            continue
        d = json.loads(body)
        n = (d.get("data") or {}).get("totalRecords") or 0
        (out / f"{t}.json").write_text(json.dumps(d))
        log(f"  [{i}/{len(todo)}] {t}: {n} rows")
        time.sleep(pace)


def download_french(out: Path) -> None:
    for url, name in ((FRENCH_49_URL, "49_Industry_Portfolios_Daily.csv"), (FRENCH_FACTORS_URL, "F-F_Research_Data_Factors_daily.csv")):
        if (out / name).exists():
            continue
        log(f"downloading {url}")
        z = zipfile.ZipFile(io.BytesIO(http_get(url, timeout=300)))
        member = next(m for m in z.namelist() if m.lower().endswith(".csv"))
        (out / name).write_bytes(z.read(member))


def cmd_prices(data_dir: Path, source: str, pace: float = 1.5) -> None:
    linkmap = json.loads((data_dir / "linkmap.json").read_text())
    out = data_dir / source
    out.mkdir(parents=True, exist_ok=True)
    if source == "yahoo":
        download_yahoo(linkmap, out, pace)
    elif source == "nasdaq":
        download_nasdaq(linkmap, out, pace)
    else:
        download_french(out)


# ---- loading: every source becomes one daily simple-return frame with a MARKET column ----


def load_yahoo(out: Path) -> pd.DataFrame:
    series = {}
    for p in sorted(out.glob("*.json")):
        d = json.loads(p.read_text())
        res = d["chart"]["result"]
        if not res or not res[0].get("timestamp"):
            continue
        r = res[0]
        ind = r["indicators"]
        close = ind.get("adjclose", [{}])[0].get("adjclose") or ind["quote"][0]["close"]
        idx = pd.to_datetime(r["timestamp"], unit="s", utc=True).tz_convert("America/New_York").normalize().tz_localize(None)
        s = pd.Series(close, index=idx, dtype="float64", name=p.stem)
        series[p.stem] = s[~s.index.duplicated(keep="last")].dropna()
    px = pd.DataFrame(series).sort_index().rename(columns={"SPY": MARKET})
    return _px_to_rets(px)


def load_nasdaq(out: Path) -> pd.DataFrame:
    series = {}
    for p in sorted(out.glob("*.json")):
        d = json.loads(p.read_text())
        rows = ((d.get("data") or {}).get("tradesTable") or {}).get("rows") or []
        if not rows:
            continue
        idx = pd.to_datetime([r["date"] for r in rows], format="%m/%d/%Y")
        vals = [float(str(r["close"]).replace("$", "").replace(",", "")) for r in rows]
        s = pd.Series(vals, index=idx, dtype="float64", name=p.stem).sort_index()
        series[p.stem] = s[~s.index.duplicated(keep="last")]
    px = pd.DataFrame(series).sort_index().rename(columns={"SPY": MARKET})
    return _px_to_rets(px)


def _px_to_rets(px: pd.DataFrame) -> pd.DataFrame:
    if MARKET not in px:
        raise SystemExit("market series (SPY) missing from the price directory")
    px = px.reindex(px.index[px[MARKET].notna()])  # trading-day calendar = market series
    return px.pct_change(fill_method=None)


def _read_french_block(path: Path, header_startswith: str) -> pd.DataFrame:
    """French CSVs hold several blocks; take the first block whose title starts with `header_startswith`
    (or the first block when the file has a single untitled one) and parse its YYYYMMDD rows."""
    lines = path.read_text(encoding="latin-1").splitlines()
    i = 0
    if header_startswith:
        while i < len(lines) and not lines[i].strip().startswith(header_startswith):
            i += 1
        i += 1
    while i < len(lines) and not lines[i].startswith(","):
        i += 1
    cols = [c.strip() for c in lines[i].split(",")]
    cols[0] = "date"
    body = []
    for ln in lines[i + 1 :]:
        if not re.match(r"^\d{8},", ln):
            break
        body.append(ln)
    df = pd.read_csv(io.StringIO("\n".join(body)), header=None, names=cols)
    df["date"] = pd.to_datetime(df["date"].astype(str), format="%Y%m%d")
    df = df.set_index("date").astype("float64")
    df = df.mask(df <= -99.0)  # -99.99 / -999 = missing
    return df / 100.0


def load_french(out: Path) -> pd.DataFrame:
    ind = _read_french_block(out / "49_Industry_Portfolios_Daily.csv", "Average Value Weighted Returns -- Daily")
    fac = _read_french_block(out / "F-F_Research_Data_Factors_daily.csv", "")
    mkt = (fac["Mkt-RF"] + fac["RF"]).rename(MARKET)
    rets = ind.join(mkt, how="inner")
    return rets


def load_returns(data_dir: Path, source: str) -> pd.DataFrame:
    out = data_dir / source
    rets = {"yahoo": load_yahoo, "nasdaq": load_nasdaq, "french": load_french}[source](out)
    return rets[rets.index >= "1985-01-01"]


# --------------------------------------------------------------------------------------------------
# Stage 3: the event study
# --------------------------------------------------------------------------------------------------


def _covered(rets: pd.DataFrame, col: str, start: pd.Timestamp, end: pd.Timestamp) -> bool:
    if col not in rets:
        return False
    w = rets[col].loc[start:end]
    return len(w) > 0 and w.notna().mean() > 0.98 and rets[col].first_valid_index() <= start


def hop_return_series(
    rets: pd.DataFrame, codes: list[str], exclude: set[str], start: pd.Timestamp, end: pd.Timestamp, source: str, etf_first: bool
) -> tuple[pd.Series | None, dict, set[str], dict[str, pd.Series]]:
    """Daily return series of one hop over [start, end], equal-weighted across its industry series.
    french: industry = its mapped French portfolio(s) (a French portfolio already used by the first hop,
    or by an earlier industry of the same hop, is 'folded' and not double-counted); nasdaq/yahoo:
    industry = its ETF (when etf_first and covered) else an equal-weighted basket of covered members.
    Returns (hop series, coverage, columns used, per-industry series)."""
    cov: dict[str, dict] = {}
    parts: list[pd.Series] = []
    per: dict[str, pd.Series] = {}
    used: set[str] = set()
    for c in codes:
        if source == "french":
            mapped = FRENCH_MAP.get(c, [])
            members = [f for f in mapped if f not in exclude and f not in used and _covered(rets, f, start, end)]
            if members:
                used.update(members)
                cov[c] = {"kind": "french", "members": members}
                for m in members:
                    parts.append(rets[m])
                    per[f"{c}:{m}"] = rets[m]
            elif any(f in exclude or f in used for f in mapped):
                cov[c] = {"kind": "folded", "members": mapped}
            else:
                cov[c] = {"kind": "missing", "members": []}
            continue
        p = PROXIES[c]
        etf = p["etf"] if etf_first and p["etf"] else None
        if etf and _covered(rets, etf, start, end):
            cov[c] = {"kind": "etf", "members": [etf]}
            parts.append(rets[etf])
            per[c] = rets[etf]
            used.add(etf)
            continue
        members = [t for t in p["basket"] if t not in used and _covered(rets, t, start, end)]
        if len(members) >= MIN_BASKET_MEMBERS:
            cov[c] = {"kind": "basket", "members": members}
            parts.append(rets[members].mean(axis=1))
            per[c] = parts[-1]
            used.update(members)
        else:
            cov[c] = {"kind": "missing", "members": members}
    if len(parts) < MIN_INDUSTRIES_PER_HOP:
        return None, cov, used, per
    return pd.concat(parts, axis=1).mean(axis=1), cov, used, per


def car_profile(hop: pd.Series, mkt: pd.Series, onset_pos: int, dates: pd.DatetimeIndex) -> dict | None:
    """Beta from the BETA_WINDOW days before onset. d0 = hedged return on the onset day itself (the
    announcement reaction, not tradeable by a strategy that reads the news that morning); car_{h}w =
    cumulative hedged return over trading days 1..5h AFTER onset (the drift a day-1 entry could earn)."""
    pre = slice(max(0, onset_pos - BETA_WINDOW), onset_pos)
    x = mkt.iloc[pre]
    y = hop.iloc[pre]
    ok = x.notna() & y.notna()
    if ok.sum() < MIN_BETA_OBS:
        return None
    x, y = x[ok], y[ok]
    beta = float(np.cov(x, y, ddof=1)[0, 1] / np.var(x, ddof=1))
    max_h = max(HORIZONS_WEEKS) * 5
    if onset_pos + max_h >= len(dates):
        return None
    post_m = mkt.iloc[onset_pos : onset_pos + max_h + 1]
    post_y = hop.iloc[onset_pos : onset_pos + max_h + 1]
    hedged = (post_y - beta * post_m).fillna(0.0)
    out = {"beta": beta, "d0": float(hedged.iloc[0]), "d0_raw": float(post_y.fillna(0.0).iloc[0])}
    drift = hedged.iloc[1:].cumsum()
    raw = post_y.fillna(0.0).iloc[1:].cumsum()
    mk = post_m.fillna(0.0).iloc[1:].cumsum()
    for h in HORIZONS_WEEKS:
        out[f"car_{h}w"] = float(drift.iloc[5 * h - 1])
        out[f"raw_{h}w"] = float(raw.iloc[5 * h - 1])
        out[f"mkt_{h}w"] = float(mk.iloc[5 * h - 1])
    return out


def run_window(rets, dates, onset: pd.Timestamp, first_codes, second_codes, source: str, etf_first: bool) -> dict | None:
    onset_pos = dates.get_indexer([onset])[0]
    if onset_pos < BETA_WINDOW:
        return None
    start = dates[onset_pos - BETA_WINDOW]
    end_pos = onset_pos + max(HORIZONS_WEEKS) * 5
    if end_pos >= len(dates):
        return None
    end = dates[end_pos]
    mkt = rets[MARKET]
    h1, cov1, used1, per1 = hop_return_series(rets, first_codes, set(), start, end, source, etf_first)
    h2, cov2, _, per2 = hop_return_series(rets, second_codes, used1, start, end, source, etf_first)
    base = {"onset": str(onset.date()), "coverage_first": cov1, "coverage_second": cov2}
    if h1 is None or h2 is None:
        return {**base, "skipped": True}
    p1 = car_profile(h1, mkt, onset_pos, dates)
    p2 = car_profile(h2, mkt, onset_pos, dates)
    if p1 is None or p2 is None:
        return {**base, "skipped": True}
    res = {**base, "skipped": False, "first": p1, "second": p2}
    res["spread"] = {f"car_{h}w": p2[f"car_{h}w"] - p1[f"car_{h}w"] for h in HORIZONS_WEEKS}
    res["spread"]["d0"] = p2["d0"] - p1["d0"]
    res["industries"] = {}
    for hop, per in (("first", per1), ("second", per2)):
        for k, ser in per.items():
            prof = car_profile(ser, mkt, onset_pos, dates)
            if prof:
                res["industries"][k] = {"hop": hop, **prof}
    return res


def first_trading_day(dates: pd.DatetimeIndex, d: str) -> pd.Timestamp:
    ts = pd.Timestamp(d)
    i = dates.searchsorted(ts)
    return dates[i]


def pooled_stats(rows: list[dict], key: str, rng: np.random.Generator) -> dict:
    out = {}
    for h in ("d0", *HORIZONS_WEEKS):
        field = "d0" if h == "d0" else f"car_{h}w"
        v = np.array([r[key][field] for r in rows if not r.get("skipped")])
        if len(v) == 0:
            out[f"{h}w"] = None
            continue
        boots = np.array([rng.choice(v, size=len(v), replace=True).mean() for _ in range(BOOTSTRAP_REPS)])
        out[f"{h}w"] = {
            "n": len(v),
            "mean": float(v.mean()),
            "median": float(np.median(v)),
            "ci_lo": float(np.percentile(boots, 2.5)),
            "ci_hi": float(np.percentile(boots, 97.5)),
            "n_pos": int((v > 0).sum()),
        }
    return out


def cmd_study(data_dir: Path, source: str, hop2_rule: str, etf_first: bool) -> dict:
    linkmap = json.loads((data_dir / "linkmap.json").read_text())
    rets = load_returns(data_dir, source)
    dates = rets.index
    first_codes = [e["code"] for e in linkmap["first_hop"]]
    second_codes = [e["code"] for e in linkmap[f"second_hop_{hop2_rule}"]]

    episodes = []
    for label, trig, kind in EPISODES:
        if pd.Timestamp(trig) < dates[BETA_WINDOW] or pd.Timestamp(trig) > dates[-1]:
            episodes.append({"label": label, "trigger": trig, "kind": kind, "onset": trig, "skipped": True,
                             "reason": "outside the source's data span", "coverage_first": {}, "coverage_second": {}})
            continue
        onset = first_trading_day(dates, trig)
        r = run_window(rets, dates, onset, first_codes, second_codes, source, etf_first)
        if r is None:
            r = {"onset": str(onset.date()), "skipped": True, "coverage_first": {}, "coverage_second": {}}
        r.update({"label": label, "trigger": trig, "kind": kind})
        episodes.append(r)

    # placebos: trading days >= 26 weeks from any listed event, within the span where windows fit
    rng = np.random.default_rng(SEED)
    event_onsets = [first_trading_day(dates, t) for _, t, _ in EPISODES]
    excl_days = PLACEBO_EXCLUSION_WEEKS * 5
    lo = BETA_WINDOW
    hi = len(dates) - max(HORIZONS_WEEKS) * 5 - 1
    eligible = []
    for pos in range(lo, hi):
        if dates[pos] < pd.Timestamp("1991-01-01"):
            continue
        if all(abs(pos - dates.get_indexer([e])[0]) > excl_days for e in event_onsets):
            eligible.append(pos)
    eligible = np.array(eligible)

    def draw_placebos(n: int) -> list[dict]:
        rows = []
        tries = 0
        while len(rows) < n and tries < 20 * n:
            tries += 1
            pos = int(rng.choice(eligible))
            r = run_window(rets, dates, dates[pos], first_codes, second_codes, source, etf_first)
            if r and not r.get("skipped"):
                r["label"] = f"placebo {dates[pos].date()}"
                rows.append(r)
        return rows

    placebo12 = draw_placebos(PLACEBO_N)
    placebo_dist = draw_placebos(PLACEBO_DIST_N)

    shocks = [e for e in episodes if e["kind"] == "shock" and not e.get("skipped")]
    controls = [e for e in episodes if e["kind"] == "control" and not e.get("skipped")]
    stats = {}
    for name, rows in (("shocks", shocks), ("controls", controls), ("placebo12", placebo12), ("placebo_dist", placebo_dist)):
        stats[name] = {k: pooled_stats(rows, k, rng) for k in ("spread", "second", "first")}
    # percentile of the pooled shock mean within the placebo-distribution of same-size pooled means
    pct = {}
    for k in ("spread", "second", "first"):
        pct[k] = {}
        for h in HORIZONS_WEEKS:
            v = np.array([r[k][f"car_{h}w"] for r in placebo_dist])
            obs = stats["shocks"][k][f"{h}w"]["mean"] if stats["shocks"][k][f"{h}w"] else None
            if obs is None or len(v) == 0:
                pct[k][f"{h}w"] = None
                continue
            m = len(shocks)
            pooled = np.array([rng.choice(v, size=m, replace=False).mean() for _ in range(BOOTSTRAP_REPS)])
            shock_v = np.array([r[k][f"car_{h}w"] for r in shocks])
            pct[k][f"{h}w"] = {
                "pct_of_placebo_pooled": float((pooled < obs).mean()),
                "placebo_single_sd": float(v.std(ddof=1)),
                "shock_sd": float(shock_v.std(ddof=1)) if len(shock_v) > 1 else None,
            }
    # per-industry pooled drift (shock episodes vs the placebo distribution), for the breakdown table
    ind_keys = sorted({k for r in shocks for k in r.get("industries", {})})
    industry_stats = {}
    for k in ind_keys:
        row = {"hop": next(r["industries"][k]["hop"] for r in shocks if k in r.get("industries", {}))}
        for name, rows in (("shocks", shocks), ("placebo_dist", placebo_dist)):
            for h in ("d0", *HORIZONS_WEEKS):
                field = "d0" if h == "d0" else f"car_{h}w"
                v = np.array([r["industries"][k][field] for r in rows if k in r.get("industries", {})])
                row[f"{name}_{h}"] = {"n": len(v), "mean": float(v.mean()), "n_pos": int((v > 0).sum())} if len(v) else None
        industry_stats[k] = row
    results = {
        "industry_stats": industry_stats,
        "source": source,
        "hop2_rule": hop2_rule,
        "etf_first": etf_first,
        "market": "Fama-French Mkt-RF + RF" if source == "french" else "SPY",
        "first_hop": first_codes,
        "second_hop": second_codes,
        "episodes": episodes,
        "placebo12": placebo12,
        "placebo_dist_n": len(placebo_dist),
        "stats": stats,
        "percentiles": pct,
        "price_span": [str(dates[0].date()), str(dates[-1].date())],
    }
    tag = f"{source}_{hop2_rule}_{'etf' if etf_first else 'basket'}"
    (data_dir / f"results_{tag}.json").write_text(json.dumps(results, indent=1, default=str))
    print(render_markdown(results, linkmap))
    return results


# --------------------------------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------------------------------


def _pct(x: float | None) -> str:
    return "n/a" if x is None else f"{100 * x:+.1f}%"


def render_markdown(res: dict, linkmap: dict) -> str:
    L = []
    hs = HORIZONS_WEEKS
    cols = ("d0", *hs)
    prox = "French 49 industries" if res["source"] == "french" else ("ETF-first" if res["etf_first"] else "baskets only")
    L.append(f"### Results: source `{res['source']}`, second-hop rule `{res['hop2_rule']}`, proxies `{prox}`\n")
    L.append("Market-hedged returns (beta from the prior 252 trading days vs " + res["market"] + "). "
             "`d0` = the onset day's own hedged return (announcement reaction); `Nw` = cumulative hedged drift over "
             "trading days 1..5N AFTER the onset day, i.e. what a day-1 entry could earn. "
             "Pooled rows: mean [bootstrap 95% CI over episodes] and the count of positive episodes.\n")
    hdr = "| Episode | Onset | series n1/n2 | β1 / β2 | " + " | ".join(str(c) if c == "d0" else f"{c}w" for c in cols) + " |"
    sep = "|---|---|---|---|" + "|".join("---:" for _ in cols) + "|"

    def n_series(cov: dict) -> int:
        return sum(len(c["members"]) for c in cov.values() if c["kind"] in ("french", "etf", "basket"))

    for key, title in (("spread", "Spread: second hop minus first hop"), ("second", "Second hop (hedged)"), ("first", "First hop (hedged)")):
        L.append(f"\n**{title}**\n")
        L.append(hdr)
        L.append(sep)
        for e in res["episodes"]:
            n1, n2 = n_series(e.get("coverage_first", {})), n_series(e.get("coverage_second", {}))
            if e.get("skipped"):
                why = e.get("reason", "insufficient coverage")
                L.append(f"| {e['label']} | {e['onset']} | {n1}/{n2} | - | skipped: {why} |" + " |" * (len(cols) - 1))
                continue
            b = f"{e['first']['beta']:.2f} / {e['second']['beta']:.2f}"
            vals = [e[key]["d0"] if c == "d0" else e[key][f"car_{c}w"] for c in cols]
            L.append(f"| {e['label']} | {e['onset']} | {n1}/{n2} | {b} | " + " | ".join(_pct(v) for v in vals) + " |")
        for name, lab in (("shocks", "**Pooled shocks** mean"), ("controls", "Pooled demand controls mean"), ("placebo12", "12 placebo onsets mean"), ("placebo_dist", f"{res['placebo_dist_n']} placebo onsets mean")):
            st = res["stats"][name][key]
            cells = []
            for c in cols:
                sname = "d0w" if c == "d0" else f"{c}w"
                st_c = st.get(sname)
                cells.append("n/a" if not st_c else f"{_pct(st_c['mean'])} [{_pct(st_c['ci_lo'])}, {_pct(st_c['ci_hi'])}] {st_c['n_pos']}/{st_c['n']}>0")
            L.append(f"| {lab} | | | | " + " | ".join(cells) + " |")
        cells = []
        for c in cols:
            if c == "d0":
                cells.append("")
                continue
            p = res["percentiles"][key][f"{c}w"]
            cells.append("n/a" if not p else f"{100 * p['pct_of_placebo_pooled']:.0f}th pct")
        L.append("| Shock pooled mean's percentile in the placebo pooled-mean distribution | | | | " + " | ".join(cells) + " |")
        cells = []
        for c in cols:
            if c == "d0":
                cells.append("")
                continue
            p = res["percentiles"][key][f"{c}w"]
            cells.append("n/a" if not p or p["shock_sd"] is None else f"{_pct(p['shock_sd'])} vs {_pct(p['placebo_single_sd'])}")
        L.append("| Dispersion: SD across shock episodes vs SD across single placebo windows | | | | " + " | ".join(cells) + " |")

    L.append("\n**Per-industry drift, pooled over the shock episodes vs the placebo base rate** "
             "(mean hedged CAR; `k/n` = positive episodes)\n")
    L.append("| Industry (hop) | d0 | " + " | ".join(f"{h}w" for h in hs) + " | placebo 12w |")
    L.append("|---|---:|" + "|".join("---:" for _ in hs) + "|---:|")
    for k, row in res["industry_stats"].items():
        cells = []
        for h in ("d0", *hs):
            st_c = row.get(f"shocks_{h}")
            cells.append("n/a" if not st_c else f"{_pct(st_c['mean'])} {st_c['n_pos']}/{st_c['n']}")
        pl = row.get(f"placebo_dist_{hs[-1]}")
        L.append(f"| {k} ({row['hop']}) | " + " | ".join(cells) + f" | {'n/a' if not pl else _pct(pl['mean'])} |")

    L.append("\n**Coverage** (industry: proxy used per episode; `folded` = its French portfolio is already counted)\n")
    for e in res["episodes"]:
        parts = []
        for hop in ("coverage_first", "coverage_second"):
            for c, cv in e.get(hop, {}).items():
                if cv["kind"] == "basket":
                    tag = f"basket x{len(cv['members'])}"
                elif cv["kind"] in ("french", "etf"):
                    tag = "+".join(cv["members"])
                else:
                    tag = cv["kind"]
                parts.append(f"{c}:{tag}")
        L.append(f"- {e['label']}: " + ", ".join(parts))
    return "\n".join(L)


# --------------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("stage", choices=["bea", "linkmap", "prices", "study", "all"])
    ap.add_argument("--data-dir", type=Path, required=True, help="scratch directory for downloads and results")
    ap.add_argument("--source", choices=["french", "nasdaq", "yahoo"], default="french")
    ap.add_argument("--hop2-rule", choices=["weighted", "literal"], default="weighted")
    ap.add_argument("--baskets-only", action="store_true", help="ignore ETFs; use stock baskets everywhere")
    ap.add_argument("--pace", type=float, default=1.5, help="seconds between Yahoo requests")
    a = ap.parse_args(argv)
    a.data_dir.mkdir(parents=True, exist_ok=True)
    if a.stage in ("bea",):
        cmd_bea(a.data_dir)
    if a.stage in ("linkmap", "all"):
        cmd_linkmap(a.data_dir)
    if a.stage in ("prices", "all"):
        cmd_prices(a.data_dir, a.source, a.pace)
    if a.stage in ("study", "all"):
        cmd_study(a.data_dir, a.source, a.hop2_rule, not a.baskets_only)
    return 0


if __name__ == "__main__":
    sys.exit(main())

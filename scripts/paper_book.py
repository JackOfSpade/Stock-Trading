#!/usr/bin/env python3
"""The data path of D1's NEWS-REACTION PAPER BOOK (bigquery/261): fetch URLs, headline selection, and
digest-guarded INSERTs with their readback. Standard library only; it fetches nothing and writes to
BigQuery nothing -- D1 runs the curl commands and issues the generated SQL itself.

WHY THIS EXISTS. The BigQuery MCP tool takes SQL text, never a file, so every row D1 writes is copied
token by token by whichever agent issues the call. On 2026-10-20 a sub-agent copying three ~30KB INSERTs
corrupted 3 of 120 Google News `source_url` values (long base64); only an improvised fingerprint readback
caught it, and the repair was an in-place UPDATE on an append-only events table (ops.alerts 5638e932,
`d1_subagent_sql_retype_corrupts_writes`). So:

  * every row carries `row_sha` (16 hex of a SHA-256 of its fields) computed HERE from the saved source
    files, and the INSERT admits a row only if BigQuery recomputes the same digest from the values it
    received. A row damaged in transit is skipped, never written, so there is nothing to repair;
  * the digest is taken over BigQuery's renderings of the TYPED values (CAST(... AS STRING),
    FORMAT_TIMESTAMP(..., 'UTC'), TO_JSON_STRING), so the same expression re-checks a row after it lands;
  * the emitted SQL is printable ASCII (non-ASCII written as \\uXXXX escapes), so a copy that "tidies" a
    curly quote or a non-breaking space cannot fail the same row on every retry;
  * the admit condition is both the WHERE clause and the value of the NOT NULL date column, so a batch
    that loses its WHERE in transit fails outright instead of landing rows it should have skipped;
  * readback.sql reports what is absent or wrong -- calls by headline number, marks per bar by ticker --
    and `--only` re-emits just that.

It also removes the hand-made steps around the write: `urls` builds every fetch URL (query terms
URL-encoded), `headlines` selects headlines from the saved RSS by a pinned alias map instead of judgment
(on 2026-10-20 "Dwayne Johnson ..." was scored for JNJ and "Cop shoots ..." for COP) and writes the
numbered reader list, and `calls` derives headline_hash, direction (modal vote; a tied mode is FLAT) and
agreement_score (modal count / k) from the raw inputs. The pre-registered constants below come from
ops/research/news_reaction_paper_book_2026-10.md section 1; changing any of them re-opens the book.

Usage (<S> is a scratch directory outside the repository; D is state.trading_day_today.today):
  python3 scripts/paper_book.py urls --today D [--from YYYY-MM-DD --only T,...]   # TSV: file, accept, url
  python3 scripts/paper_book.py marks --nasdaq-dir <S>/nasdaq --out <S>/marks [--only T,...]
  python3 scripts/paper_book.py headlines --rss-dir <S>/rss --since <ISO-8601 UTC> --out <S>/headlines.json
  python3 scripts/paper_book.py calls <S>/headlines.json --votes V1.json V2.json V3.json V4.json V5.json \\
      --call-date D --session ID --out <S>/calls [--only 3,17]
  (`marks ROWS.json` and `calls` rows carrying inline "votes" exist for tests.)
`headlines` also writes <S>/readers.txt, the numbered list the blind readers receive. Each Vn.json is one
reader's votes keyed by headline number, {"1": "UP", "2": "FLAT", ...}: every vote UP | DOWN | FLAT, every
headline number present exactly once. `marks`/`calls` write <out>/batch_NN.sql (issue them one at a time,
each after the previous one finished, text verbatim) and <out>/readback.sql (it checks every input row,
whatever --only selected). Re-run with the SAME inputs when re-issuing, so the numbers keep meaning the
same rows. Exits 2, writing nothing, on any invalid input.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from email.utils import parsedate_to_datetime
from urllib.parse import quote_plus

PROJECT = "stock-trading-498512"
CALLS_TABLE = f"`{PROJECT}.events.news_reaction_calls`"
MARKS_TABLE = f"`{PROJECT}.events.news_reaction_marks`"
MARKS_CURATED = f"`{PROJECT}.state.news_reaction_marks_curated`"

# Pre-registered (memo section 1). Changing any of these re-opens the book.
LEAD_ID = "interactive-2026-10-news-reaction-confidence-gated-long-short"
K = 5
HORIZON_DAYS = 1
HEADLINE_CAP = 3
VOTES = ("UP", "DOWN", "FLAT")
BENCHMARK = "SPY"

# The 40 UNIVERSE tickers of ops.news_reaction_universe (bigquery/261 seed; tests pin the two together)
# -> (Google News query term, aliases). A headline is kept for a ticker only if it contains one of its
# aliases as a whole word, CASE-SENSITIVELY: proper nouns are capitalised in headlines, while "cop",
# "Ups" and "meta-analysis" are not. Editing this map, CUE_TICKERS, EXCLUDE, BROKERS or NON_NEWS changes
# which headlines are scored from then on (not a section-1 constant): date the change in the memo.
UNIVERSE = {
    "AAPL": ("Apple", ("Apple", "AAPL")),
    "MSFT": ("Microsoft", ("Microsoft", "MSFT")),
    "NVDA": ("Nvidia", ("Nvidia", "NVIDIA", "NVDA")),
    "AMZN": ("Amazon", ("Amazon", "AMZN", "AWS")),
    "GOOGL": ("Alphabet", ("Alphabet", "Google", "GOOGL", "GOOG")),
    "META": ("Meta", ("Meta", "Facebook", "Instagram", "WhatsApp", "META")),
    "TSLA": ("Tesla", ("Tesla", "TSLA")),
    "AVGO": ("Broadcom", ("Broadcom", "AVGO")),
    "JPM": ("JPMorgan", ("JPMorgan", "JP Morgan", "J.P. Morgan", "JPM")),
    "BAC": ("Bank of America", ("Bank of America", "BofA", "BAC")),
    "GS": ("Goldman Sachs", ("Goldman Sachs", "Goldman")),
    "V": ("Visa", ("Visa",)),
    "MA": ("Mastercard", ("Mastercard", "MasterCard")),
    "UNH": ("UnitedHealth", ("UnitedHealth", "Optum", "UNH")),
    "LLY": ("Eli Lilly", ("Eli Lilly", "Eli lilly", "Lilly", "LLY")),
    "JNJ": ("Johnson & Johnson", ("Johnson & Johnson", "J&J", "JNJ")),
    "PFE": ("Pfizer", ("Pfizer", "PFE")),
    "MRK": ("Merck", ("Merck", "MRK")),
    "ABBV": ("AbbVie", ("AbbVie", "Abbvie", "ABBV")),
    "XOM": ("Exxon Mobil", ("Exxon", "ExxonMobil", "XOM")),
    "CVX": ("Chevron", ("Chevron", "CVX")),
    "COP": ("ConocoPhillips", ("ConocoPhillips", "Conoco")),
    "CAT": ("Caterpillar", ("Caterpillar",)),
    "DE": ("Deere", ("Deere",)),
    "BA": ("Boeing", ("Boeing",)),
    "GE": ("GE Aerospace", ("GE Aerospace", "General Electric")),
    "HON": ("Honeywell", ("Honeywell",)),
    "UPS": ("United Parcel Service", ("United Parcel Service", "UPS")),
    "WMT": ("Walmart", ("Walmart", "Wal-Mart", "WMT")),
    "COST": ("Costco", ("Costco",)),
    "HD": ("Home Depot", ("Home Depot",)),
    "NKE": ("Nike", ("Nike", "NIKE", "NKE")),
    "MCD": ("McDonald's", ("McDonald's", "McDonalds", "MCD")),
    "DIS": ("Disney", ("Disney",)),
    "NFLX": ("Netflix", ("Netflix", "NFLX")),
    "CRM": ("Salesforce", ("Salesforce",)),
    "ORCL": ("Oracle", ("Oracle", "ORCL")),
    "AMD": ("AMD", ("AMD", "Advanced Micro Devices")),
    "INTC": ("Intel", ("Intel", "INTC")),
    "QCOM": ("Qualcomm", ("Qualcomm", "QCOM")),
}
ALL_TICKERS = (*sorted(UNIVERSE), BENCHMARK)
# Tickers that are ordinary words or initials ("V", "DE", "BA", "GE", "CAT", "COST" ...) are not aliases of
# themselves, but count when the headline marks them as a security: "$GE", "(GE)", "NYSE:GE", or followed by
# stock / shares / earnings / a quarter. On GE's 2026-10-20 earnings day most of its headlines were "GE ...".
CUE_TICKERS = ("V", "MA", "GS", "CAT", "DE", "BA", "GE", "COP", "COST", "HD", "DIS", "CRM")
# A headline naming one of these is about a DIFFERENT listed company, dropped even if it matches an alias.
# Measured 2026-10-21: all three of HON's 2026-10-20 headlines were about the separately traded Honeywell
# Aerospace (HONA), and MRK's feed carried Merck KGaA's own listing and deals.
EXCLUDE = {
    "HON": ("Honeywell Aerospace", "HONA", "Honeywell Automation India", "Solstice"),
    "MRK": ("Merck KGaA", "KGaA", "EMD Serono", "Merck Group", "Darmstadt"),
    # Title Case defeats the case-sensitive aliases for these two common phrases
    "META": ("Meta-Analysis", "Meta-analysis", "Meta Analysis"),
    "ORCL": ("Oracle of Omaha",),
}
# The banks' feeds are dominated by the bank acting as an analyst on OTHER companies ("JPMorgan lifts target
# for Colgate", "Goldman Sachs says ..."): measured 2026-10-21, all 3 JPM and all 3 GS picks were such items.
# For these tickers a headline matching BROKER_ACTION is dropped unless it also carries the ticker itself.
BROKERS = ("JPM", "GS", "BAC")
_BANK = r"(?:JPMorgan|JP Morgan|J\.P\. Morgan|Goldman Sachs|Goldman|Bank of America|BofA)"
BROKER_ACTION = re.compile(
    r"\b(?:price targets?|targets?|ratings?|upgrades?|downgrades?|coverage|overweight|underweight|outperform|"
    r"underperform|brokers?|weighs? in|strategists?|economists?|analysts?|reiterates?|reiterated|maintains?|"
    r"maintained|initiates?|initiated|reaffirms?|(?:raises?|raised|lifts?|lowers?|lowered|cuts?) expectations|"
    r"(?:forecasts?|expectations?|estimates?|outlook|predictions?)\s+(?:\w+\s+){0,3}for)\b|"
    rf"\b{_BANK}(?:\s+(?-i:[A-Z])[\w&.]*){{0,3}}\s+"
    r"(?:says|sees|predicts|warns|expects|forecasts|estimates|thinks|picks|likes|recommends)\b|"
    rf"\bstock:\s*{_BANK}\b",
    re.IGNORECASE)
# ... but a bank's OWN results, guidance and CEO are its news even in analyst vocabulary ("JPMorgan profit tops
# analyst expectations"), unless the headline names another company as the object of the call.
BANK_OWN_NEWS = re.compile(r"\b(?:profit|earnings|quarter(?:ly)?|Q[1-4]|revenue|results|CEO|net interest|guidance|"
                           r"dividend|buyback|shares (?:rise|fall|jump|drop|slide|climb|gain|sink))\b", re.IGNORECASE)
OTHER_OBJECT = re.compile(r"\b(?:targets?|ratings?|coverage|forecasts?|expectations?|estimates?|outlook|upgrades?|"
                          r"downgrades?)\s+(?:\w+\s+){0,3}(?:for|on|of)\s+(?-i:[A-Z])|^(?-i:[A-Z]{1,5}) (?:Stock|Shares)\b|"
                          rf"\bstock:\s*{_BANK}\b", re.IGNORECASE)
# Quote, chart, option-chain and forecast pages carry no event but take a cap slot.
NON_NEWS = ("share price, forecast & analysis", "stock price, news, quote", "interactive stock chart",
            "options chain", "latest stock news and headlines", "price today:", "stock price today",
            "stock forecast for 20", "depositary receipts")

SCORER_ROUTINE = "D1"
MARKS_SOURCE = "nasdaq-historical"
RESCORE_LOOKBACK_DAYS = 4  # a story already called on any of the previous 4 calendar days is not re-called
MARKS_WINDOW_DAYS = 14
BATCH_CHARS = 24000  # tuple text per statement; keeps every file under the 30,000-char tool output limit
READBACK_CHARS = 28000  # whole readback text per file; a longer one is split into readback_NN.sql by ticker
SEP = "\x1f"  # ASCII unit separator between digest fields; rejected inside any field value
DIGEST_HEX = 16  # 64 bits: a random copy error passes the guard with probability 2**-64
READBACK_HEX = 8  # per-bar marks readback prefix (a false "ok" needs a 2**-32 collision)
WS = r"[\t\n\f\r ]+"  # the whitespace class both sides collapse; RE2's \s is ASCII-only, so name it exactly

CALL_COLUMNS = ("call_date, lead_id, ticker, headline_hash, headline, published_ts, source, source_url, "
                "direction, agreement_score, k, votes_json, horizon_days, scorer_routine, scorer_session")
MARK_COLUMNS = "mark_date, ticker, open_px, close_px, source"


class RowError(ValueError):
    pass


# ----- digests: the Python side and the SQL side must render every field identically -----

def calls_digest_sql(a: str) -> str:
    """Row digest over BigQuery's renderings of a stored or about-to-be-stored calls row aliased `a`."""
    fields = [
        f"CAST({a}.call_date AS STRING)", f"{a}.lead_id", f"CAST({a}.k AS STRING)",
        f"CAST({a}.horizon_days AS STRING)", f"{a}.scorer_routine", f"IFNULL({a}.scorer_session, '')",
        f"{a}.ticker", f"{a}.headline_hash", f"{a}.headline",
        f"IFNULL(FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', {a}.published_ts, 'UTC'), '')",
        f"{a}.source", f"IFNULL({a}.source_url, '')", f"{a}.direction",
        f"CAST({a}.agreement_score AS STRING)", f"TO_JSON_STRING({a}.votes_json)",
    ]
    return f"LEFT(TO_HEX(SHA256(ARRAY_TO_STRING([{', '.join(fields)}], '\\x1f'))), {DIGEST_HEX})"


def marks_digest_sql(a: str, n: int = DIGEST_HEX) -> str:
    fields = [f"CAST({a}.mark_date AS STRING)", f"{a}.ticker", f"CAST({a}.open_px AS STRING)",
              f"CAST({a}.close_px AS STRING)", f"{a}.source"]
    return f"LEFT(TO_HEX(SHA256(ARRAY_TO_STRING([{', '.join(fields)}], '\\x1f'))), {n})"


def story_sql(expr: str) -> str:
    """story_key() in GoogleSQL: the same title with its trailing ' - <outlet>' removed, so syndicated copies
    of one story match. Equal to the Python side for every title whose whitespace is in WS."""
    c = f"REGEXP_REPLACE({expr}, r'{WS}', ' ')"
    return (f"LEFT(TO_HEX(SHA256(LOWER(TRIM(IF(STRPOS({c}, ' - ') > 0, REGEXP_EXTRACT({c}, r'^(.*) - '), {c}), "
            f"' ')))), {DIGEST_HEX})")


def digest(fields: list[str]) -> str:
    return hashlib.sha256(SEP.join(fields).encode("utf-8")).hexdigest()[:DIGEST_HEX]


def headline_hash(headline: str) -> str:
    return hashlib.sha256(" ".join(headline.split()).lower().encode("utf-8")).hexdigest()


def story_key(headline: str) -> str:
    s = re.sub(WS, " ", headline)
    if " - " in s:
        s = s.rsplit(" - ", 1)[0]
    return hashlib.sha256(s.strip(" ").lower().encode("utf-8")).hexdigest()[:DIGEST_HEX]


def sql_str(value: str) -> str:
    """A GoogleSQL quoted literal whose value is exactly `value`, written in printable ASCII only."""
    out = []
    for ch in value:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == "'":
            out.append("\\'")
        elif 0x20 <= o < 0x7F:
            out.append(ch)
        elif o <= 0xFFFF:
            out.append("\\u%04x" % o)
        else:
            out.append("\\U%08x" % o)
    return "'" + "".join(out) + "'"


# ----- input normalisation -----

def text(row: dict, key: str, required: bool = True) -> str:
    value = row.get(key)
    if value is None or value == "":
        if required:
            raise RowError(f"{key} is required")
        return ""
    if not isinstance(value, str):
        raise RowError(f"{key} must be a string, got {type(value).__name__}")
    if SEP in value:
        raise RowError(f"{key} contains the digest separator U+001F")
    try:
        value.encode("utf-8")
    except UnicodeEncodeError:
        raise RowError(f"{key} is not valid Unicode (lone surrogate)") from None
    return value


def parse_ts(value) -> datetime:
    s = str(value).strip()
    try:
        dt = datetime.fromisoformat(s[:-1] + "+00:00" if s.endswith(("Z", "z")) else s)
    except ValueError:
        try:
            dt = parsedate_to_datetime(s)
        except (TypeError, ValueError, IndexError):
            raise RowError(f"timestamp {value!r} is neither ISO-8601 nor RFC-822") from None
    if dt.tzinfo is None:
        raise RowError(f"timestamp {value!r} has no time zone")
    return dt.astimezone(timezone.utc)


def norm_ts(value) -> str:
    if value is None or value == "":
        return ""
    return parse_ts(value).strftime("%Y-%m-%dT%H:%M:%SZ")


def norm_date(value) -> str:
    s = str(value or "").strip()
    for fmt in ("%Y-%m-%d", "%m/%d/%Y"):
        try:
            return datetime.strptime(s, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    raise RowError(f"date {value!r} is neither YYYY-MM-DD nor MM/DD/YYYY")


def norm_px(value, key: str) -> str:
    s = str(value if value is not None else "").strip().replace("$", "").replace(",", "")
    try:
        d = Decimal(s)
    except InvalidOperation:
        raise RowError(f"{key} {value!r} is not a number") from None
    if not d.is_finite() or d <= 0:
        raise RowError(f"{key} {value!r} must be a positive price")
    d = d.normalize()
    if d.as_tuple().exponent < -9:  # NUMERIC keeps 9 decimals; a rounded value could never match its digest
        raise RowError(f"{key} {value!r} has more than 9 decimal places")
    return format(d, "f")  # the same text CAST(NUMERIC AS STRING) renders


def call_direction(votes: list[str]) -> tuple[str, str]:
    counts = {v: votes.count(v) for v in VOTES}
    top = max(counts.values())
    modes = [v for v in VOTES if counts[v] == top]
    direction = modes[0] if len(modes) == 1 else "FLAT"
    return direction, format((Decimal(top) / Decimal(K)).normalize(), "f")


# ----- fetch URLs and headline selection -----

def fetch_urls(today: str, since: str | None = None, only: set | None = None) -> list[tuple[str, str, str]]:
    """(relative output file, Accept header, URL) for every fetch the step makes, query terms URL-encoded.
    `since` widens the marks window back to that date (the history re-fetch after a restatement)."""
    d = date.fromisoformat(norm_date(today))
    start = date.fromisoformat(norm_date(since)) if since else d - timedelta(days=MARKS_WINDOW_DAYS)
    if start > d:
        raise RowError(f"--from {start} is after --today {d}")
    limit = (d - start).days + 6
    out = []
    for t in ALL_TICKERS:
        if only and t not in only:
            continue
        cls = "etf" if t == BENCHMARK else "stocks"
        out.append((f"nasdaq/{t}.json", "application/json",
                    f"https://api.nasdaq.com/api/quote/{t}/historical?assetclass={cls}"
                    f"&fromdate={start}&todate={d}&limit={limit}"))
        if t == BENCHMARK or since:
            continue
        # when:2d, not 1d: the SCAN WINDOW can reach 48 h (weekends); --since does the exact cut
        out.append((f"rss/{t}.google.xml", "*/*",
                    "https://news.google.com/rss/search?q=" + quote_plus(f"{UNIVERSE[t][0]} stock when:2d")
                    + "&hl=en-US&gl=US&ceid=US:en"))
        out.append((f"rss/{t}.nasdaq.xml", "*/*", f"https://www.nasdaq.com/feed/rssoutbound?symbol={t}"))
    return out


def whole_words(names) -> re.Pattern:
    names = sorted(names, key=len, reverse=True)
    return re.compile(r"(?<![A-Za-z0-9])(?:" + "|".join(re.escape(n) for n in names) + r")(?![A-Za-z0-9])")


def ticker_cue(ticker: str) -> re.Pattern:
    t = re.escape(ticker)
    return re.compile(rf"\$(?:{t})(?![A-Za-z0-9])|\((?:(?:NYSE|NASDAQ|Nasdaq|NYSEARCA):)?{t}\)|"
                      rf"(?<![A-Za-z0-9]){t}(?= (?:[Ss]tock|STOCK|[Ss]hares|[Ee]arnings|Q[1-4](?![0-9])))")


def names_company(ticker: str, title: str) -> bool:
    title = title.replace("\u2019", "'")
    if any(p in title.lower() for p in NON_NEWS):
        return False
    if ticker in EXCLUDE and whole_words(EXCLUDE[ticker]).search(title):
        return False
    cue = ticker in CUE_TICKERS and bool(ticker_cue(ticker).search(title))
    if not (whole_words(UNIVERSE[ticker][1]).search(title) or cue):
        return False
    if ticker in BROKERS and not (cue or whole_words((ticker,)).search(title)):
        if OTHER_OBJECT.search(title):
            return False
        if BROKER_ACTION.search(title) and not BANK_OWN_NEWS.search(title):
            return False
    return True


def read_rss(path: str, source: str) -> list[dict]:
    root = ET.parse(path).getroot()
    items = []
    for it in root.iter("item"):
        title, link, pub = it.findtext("title"), it.findtext("link"), it.findtext("pubDate")
        if not title or not pub:
            continue
        try:  # one malformed item is dropped, never the whole feed
            items.append({"headline": text({"h": title.strip()}, "h"), "published_ts": norm_ts(pub),
                          "source": source, "source_url": (link or "").strip() or None})
        except RowError:
            continue
    return items


def select_headlines(rss_dir: str, since: str) -> tuple[list[dict], dict, list[str]]:
    """Per UNIVERSE ticker: items published at or after `since` that name the company, de-duplicated on the
    story (the title without its outlet suffix), newest first, at most HEADLINE_CAP; Nasdaq RSS fills only
    the slots Google left empty. Returns (rows in ticker order, {ticker: note} for every ticker under cap or
    with a missing / unreadable feed file, sorted tickers whose Google feed was missing or unreadable)."""
    since_dt = parse_ts(since)
    rows, notes, google_unreadable = [], {}, []
    for t in sorted(UNIVERSE):
        kept, seen, problems = [], set(), []
        for feed, source in (("google", "google-news-rss"), ("nasdaq", "nasdaq-rss")):
            if len(kept) >= HEADLINE_CAP:
                break
            path = os.path.join(rss_dir, f"{t}.{feed}.xml")
            try:
                items = read_rss(path, source)
            except FileNotFoundError:
                problems.append(f"no {feed} file (the fetch wrote nothing)")
                if feed == "google":
                    google_unreadable.append(t)
                continue
            except (OSError, ET.ParseError, ValueError) as e:
                problems.append(f"{feed} feed unreadable ({str(e).splitlines()[0][:60]})")
                if feed == "google":
                    google_unreadable.append(t)
                continue
            fresh = [i for i in items if parse_ts(i["published_ts"]) >= since_dt and names_company(t, i["headline"])]
            for i in sorted(fresh, key=lambda i: i["published_ts"], reverse=True):
                keys = (story_key(i["headline"]), headline_hash(i["headline"]))
                if not seen.intersection(keys) and len(kept) < HEADLINE_CAP:
                    seen.update(keys)
                    kept.append(dict(i, ticker=t))
        if len(kept) < HEADLINE_CAP or problems:
            notes[t] = f"{len(kept)} headline(s)" + (f"; {'; '.join(problems)}" if problems else "")
        rows.extend(kept)
    return rows, notes, sorted(google_unreadable)


def reader_list(rows: list[dict]) -> str:
    """The only thing a blind reader receives: number, ticker, timestamp, headline. No URL, no price."""
    return "".join(f"{n}\t{r['ticker']}\t{r['published_ts']}\t{' '.join(r['headline'].split())}\n"
                   for n, r in enumerate(rows, 1))


# ----- calls -----

def attach_votes(raw: list, reader_votes: list) -> list:
    """Merge the k readers' {headline number: vote} maps onto the headline rows by number, never by position."""
    if len(reader_votes) != K:
        raise RowError(f"--votes needs exactly k={K} reader files, got {len(reader_votes)}")
    want = {str(n) for n in range(1, len(raw) + 1)}
    errors, by_reader = [], []
    for i, votes in enumerate(reader_votes, 1):
        if not isinstance(votes, dict):
            errors.append(f"reader {i}: votes file must be a JSON object keyed by headline number")
            continue
        keyed = {str(k).strip(): v for k, v in votes.items()}
        if len(keyed) != len(votes):
            errors.append(f"reader {i}: a headline number appears more than once")
        if set(keyed) - want:
            errors.append(f"reader {i}: unknown headline numbers {sorted(set(keyed) - want)}")
        if want - set(keyed):
            errors.append(f"reader {i}: no vote for headline numbers {sorted(int(n) for n in want - set(keyed))}")
        by_reader.append(keyed)
    if errors:
        raise RowError("\n".join(errors))
    merged = []
    for n, row in enumerate(raw, 1):
        if not isinstance(row, dict):
            raise RowError(f"row {n}: row must be a JSON object")
        if row.get("votes") is not None:
            raise RowError(f"row {n}: carries inline votes as well as --votes files")
        merged.append(dict(row, votes=[keyed[str(n)] for keyed in by_reader]))
    return merged


def build_calls(raw: list, call_date: str, session: str) -> list[dict]:
    rows, errors, seen, stories, per_ticker = [], [], set(), set(), {}
    for n, r in enumerate(raw, 1):
        try:
            if not isinstance(r, dict):
                raise RowError("row must be a JSON object")
            ticker = text(r, "ticker").strip().upper()
            if ticker not in UNIVERSE:
                raise RowError(f"{ticker} is not a UNIVERSE ticker")
            headline = text(r, "headline")
            hh = headline_hash(headline)
            if r.get("headline_hash") not in (None, "", hh):
                raise RowError(f"headline_hash {r['headline_hash']!r} != the hash of its headline ({hh})")
            votes = r.get("votes")
            if not isinstance(votes, list) or len(votes) != K:
                raise RowError(f"votes must be a list of exactly k={K} votes")
            votes = [str(v).strip().upper() for v in votes]
            if any(v not in VOTES for v in votes):
                raise RowError(f"votes {votes} may only contain {'/'.join(VOTES)}")
            story = story_key(headline)
            if (ticker, hh) in seen or (ticker, story) in stories:
                raise RowError(f"duplicate headline or syndicated copy for {ticker} (headline_hash {hh[:8]})")
            seen.add((ticker, hh))
            stories.add((ticker, story))
            per_ticker[ticker] = per_ticker.get(ticker, 0) + 1
            if per_ticker[ticker] > HEADLINE_CAP:
                raise RowError(f"more than {HEADLINE_CAP} headlines for {ticker} (the pre-registered cap)")
            direction, agreement = call_direction(votes)
            row = {
                "n": n, "ticker": ticker, "headline_hash": hh, "story": story, "headline": headline,
                "published_ts": norm_ts(r.get("published_ts")), "source": text(r, "source"),
                "source_url": text(r, "source_url", required=False), "direction": direction,
                "agreement_score": agreement, "votes_json": json.dumps(votes, separators=(",", ":")),
            }
        except RowError as e:
            errors.append(f"row {n}: {e}")
            continue
        row["row_sha"] = digest([
            call_date, LEAD_ID, str(K), str(HORIZON_DAYS), SCORER_ROUTINE, session, row["ticker"],
            row["headline_hash"], row["headline"], row["published_ts"], row["source"], row["source_url"],
            row["direction"], row["agreement_score"], row["votes_json"],
        ])
        rows.append(row)
    if errors:
        raise RowError("\n".join(errors))
    return rows


def tuple_sql(r: dict, keys: tuple) -> str:
    return "  (" + ", ".join([str(r["n"])] + [sql_str(r[k]) for k in keys]) + ")"


CALL_TUPLE_KEYS = ("ticker", "headline_hash", "headline", "published_ts", "source", "source_url", "direction",
                   "agreement_score", "votes_json", "row_sha")
MARK_TUPLE_KEYS = ("mark_date", "ticker", "open_px", "close_px", "row_sha")


def calls_batch_sql(rows: list[dict], call_date: str, session: str, label: str) -> str:
    tuples = ",\n".join(tuple_sql(r, CALL_TUPLE_KEYS) for r in rows)
    d = f"DATE {sql_str(call_date)}"
    return f"""-- scripts/paper_book.py calls {label}. Issue this text VERBATIM, after the previous batch finished.
-- A row is written only if its literal arrived intact (row_sha), its story has no call on {call_date} or the
-- {RESCORE_LOOKBACK_DAYS} days before, and its ticker stays within {HEADLINE_CAP} calls for the day. readback.sql names every skipped row.
INSERT INTO {CALLS_TABLE} ({CALL_COLUMNS})
WITH t AS (
  SELECT {d} AS call_date, {sql_str(LEAD_ID)} AS lead_id, v.ticker, v.headline_hash, v.headline,
         TIMESTAMP(NULLIF(v.published_ts, '')) AS published_ts, v.source, NULLIF(v.source_url, '') AS source_url,
         v.direction, CAST(v.agreement_score AS NUMERIC) AS agreement_score, {K} AS k,
         PARSE_JSON(v.votes_json) AS votes_json, {HORIZON_DAYS} AS horizon_days,
         {sql_str(SCORER_ROUTINE)} AS scorer_routine, {sql_str(session)} AS scorer_session, v.row_sha
  FROM UNNEST(ARRAY<STRUCT<n INT64, ticker STRING, headline_hash STRING, headline STRING, published_ts STRING,
       source STRING, source_url STRING, direction STRING, agreement_score STRING, votes_json STRING,
       row_sha STRING>>[
{tuples}
  ]) AS v
),
g AS (
  -- everything below reads only digest-guarded values: the story, the window and the cap order
  SELECT t.*, {calls_digest_sql('t')} = t.row_sha
           AND NOT EXISTS (SELECT 1 FROM {CALLS_TABLE} x
                           WHERE x.ticker = t.ticker
                             AND x.call_date BETWEEN DATE_SUB(t.call_date, INTERVAL {RESCORE_LOOKBACK_DAYS} DAY) AND t.call_date
                             AND (x.headline_hash = t.headline_hash OR {story_sql('x.headline')} = {story_sql('t.headline')})) AS eligible
  FROM t
),
a AS (
  SELECT g.*, g.eligible AND IFNULL(today.n, 0) + ROW_NUMBER() OVER (
           PARTITION BY g.ticker, g.eligible ORDER BY g.published_ts DESC, g.headline_hash) <= {HEADLINE_CAP} AS admit
  FROM g
  LEFT JOIN (SELECT call_date, ticker, COUNT(*) AS n FROM {CALLS_TABLE} GROUP BY call_date, ticker) AS today
    ON today.ticker = g.ticker AND today.call_date = g.call_date
)
SELECT IF(a.admit, a.call_date, NULL), a.lead_id, a.ticker, a.headline_hash, a.headline, a.published_ts, a.source,
       a.source_url, a.direction, a.agreement_score, a.k, a.votes_json, a.horizon_days, a.scorer_routine,
       a.scorer_session
FROM a
WHERE a.admit
"""


def calls_readback_sql(rows: list[dict], call_date: str, session: str) -> str:
    tuples = ",\n".join(
        f"  ({r['n']}, {sql_str(r['ticker'])}, {sql_str(r['headline_hash'][:DIGEST_HEX])}, {sql_str(r['story'])}, "
        f"{sql_str(r['row_sha'])})" for r in rows)
    d = f"DATE {sql_str(call_date)}"
    return f"""-- scripts/paper_book.py calls readback ({len(rows)} rows, call_date {call_date}). Issue after the last batch.
-- ok: stored and reproduces its row_sha. missing_rows: re-run with --only <missing_rows>. Correctly not written:
-- earlier_session_rows (another session called this headline today; its call stands), already_called_rows (the
-- story, or a syndicated copy of it, was called on {call_date} or the {RESCORE_LOOKBACK_DAYS} days before), capped_rows (the ticker
-- already holds {HEADLINE_CAP} calls today). Defects, to report and never UPDATE or DELETE: mismatch_rows, duplicate_rows,
-- over_cap_tickers (more than {HEADLINE_CAP} calls stored for a ticker today).
WITH e AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<n INT64, ticker STRING, hh STRING, story STRING, sha STRING>>[
{tuples}
  ])
),
recent AS (
  SELECT x.*, {story_sql('x.headline')} AS story FROM {CALLS_TABLE} x
  WHERE x.call_date BETWEEN DATE_SUB({d}, INTERVAL {RESCORE_LOOKBACK_DAYS} DAY) AND {d}
),
hits AS (
  SELECT e.n, e.ticker, e.hh, e.story,
         COUNTIF(x.call_date = {d} AND STARTS_WITH(x.headline_hash, e.hh)) AS stored,
         LOGICAL_OR(x.call_date = {d} AND STARTS_WITH(x.headline_hash, e.hh) AND {calls_digest_sql('x')} = e.sha) AS any_ok,
         LOGICAL_OR(x.call_date = {d} AND STARTS_WITH(x.headline_hash, e.hh)
                    AND IFNULL(x.scorer_session != {sql_str(session)}, FALSE)) AS other_session,
         COUNTIF(NOT (x.call_date = {d} AND STARTS_WITH(x.headline_hash, e.hh))) AS twins
  FROM e
  LEFT JOIN recent x ON x.ticker = e.ticker AND (x.story = e.story OR STARTS_WITH(x.headline_hash, e.hh))
  GROUP BY e.n, e.ticker, e.hh, e.story
),
today AS (SELECT ticker, COUNT(*) AS n FROM {CALLS_TABLE} WHERE call_date = {d} GROUP BY ticker),
s AS (
  SELECT h.n,
    CASE
      WHEN h.stored > 1 OR (h.stored = 1 AND h.twins > 0) THEN 'duplicate'
      WHEN IFNULL(h.any_ok, FALSE) THEN 'ok'
      WHEN h.stored = 1 AND IFNULL(h.other_session, FALSE) THEN 'earlier_session'
      WHEN h.stored = 1 THEN 'mismatch'
      WHEN h.twins > 0 THEN 'already_called'
      WHEN IFNULL(c.n, 0) >= {HEADLINE_CAP} THEN 'capped'
      ELSE 'missing'
    END AS status
  FROM hits h
  LEFT JOIN today c ON c.ticker = h.ticker
)
SELECT {len(rows)} AS rows_expected,
  COUNTIF(status = 'ok') AS ok,
  IFNULL(STRING_AGG(IF(status = 'missing', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS missing_rows,
  IFNULL(STRING_AGG(IF(status = 'earlier_session', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS earlier_session_rows,
  IFNULL(STRING_AGG(IF(status = 'already_called', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS already_called_rows,
  IFNULL(STRING_AGG(IF(status = 'capped', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS capped_rows,
  IFNULL(STRING_AGG(IF(status = 'mismatch', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS mismatch_rows,
  IFNULL(STRING_AGG(IF(status = 'duplicate', CAST(n AS STRING), NULL), ',' ORDER BY n), '') AS duplicate_rows,
  (SELECT IFNULL(STRING_AGG(ticker, ',' ORDER BY ticker), '') FROM today WHERE n > {HEADLINE_CAP}) AS over_cap_tickers
FROM s
"""


# ----- marks -----

def build_marks(raw: list) -> list[dict]:
    rows, errors, seen = [], [], set()
    for n, r in enumerate(raw, 1):
        try:
            if not isinstance(r, dict):
                raise RowError("row must be a JSON object")
            ticker = text(r, "ticker").strip().upper()
            mark_date = norm_date(r.get("mark_date"))
            if (ticker, mark_date) in seen:
                raise RowError(f"duplicate mark for {ticker} on {mark_date}")
            seen.add((ticker, mark_date))
            row = {"n": n, "mark_date": mark_date, "ticker": ticker,
                   "open_px": norm_px(r.get("open_px"), "open_px"),
                   "close_px": norm_px(r.get("close_px"), "close_px")}
        except RowError as e:
            errors.append(f"row {n}: {e}")
            continue
        row["row_sha"] = digest([row["mark_date"], row["ticker"], row["open_px"], row["close_px"], MARKS_SOURCE])
        rows.append(row)
    if errors:
        raise RowError("\n".join(errors))
    return rows


def load_nasdaq_dir(raw_dir: str) -> tuple[list, list]:
    """Raw Nasdaq historical responses (<TICKER>.json) for the 41 pinned tickers -> marks input rows, plus
    the tickers skipped whole: no file, an unparseable file, or any bar that does not parse (an interior
    hole would shift every later return pairing)."""
    raw, skipped = [], []
    for ticker in ALL_TICKERS:
        try:
            with open(os.path.join(raw_dir, f"{ticker}.json"), encoding="utf-8") as f:
                bars = json.load(f)["data"]["tradesTable"]["rows"]
            if not bars:
                raise RowError("no bars")
            rows = [{"mark_date": b["date"], "ticker": ticker, "open_px": b["open"], "close_px": b["close"]}
                    for b in bars]
            build_marks(rows)  # validate every bar before admitting any of this ticker's rows
        except FileNotFoundError:
            skipped.append(f"{ticker} (no file: the fetch wrote nothing)")
            continue
        except (OSError, ValueError, KeyError, TypeError) as e:  # RowError / JSONDecodeError are ValueErrors
            skipped.append(f"{ticker} ({str(e).splitlines()[0][:80]})")
            continue
        raw.extend(rows)
    return raw, skipped


def marks_batch_sql(rows: list[dict], label: str) -> str:
    tuples = ",\n".join(tuple_sql(r, MARK_TUPLE_KEYS) for r in rows)
    return f"""-- scripts/paper_book.py marks {label}. Issue this text VERBATIM, after the previous batch finished.
-- A bar is written when its literal arrived intact (row_sha) and its (mark_date, ticker) is absent OR its curated
-- values differ (a split or restatement at source): the newer ingest then wins in the curated view, append-only.
INSERT INTO {MARKS_TABLE} ({MARK_COLUMNS})
WITH t AS (
  SELECT DATE(v.mark_date) AS mark_date, v.ticker, CAST(v.open_px AS NUMERIC) AS open_px,
         CAST(v.close_px AS NUMERIC) AS close_px, {sql_str(MARKS_SOURCE)} AS source, v.row_sha
  FROM UNNEST(ARRAY<STRUCT<n INT64, mark_date STRING, ticker STRING, open_px STRING, close_px STRING,
       row_sha STRING>>[
{tuples}
  ]) AS v
),
a AS (
  SELECT t.*, {marks_digest_sql('t')} = t.row_sha
           AND NOT EXISTS (SELECT 1 FROM {MARKS_CURATED} c
                           WHERE c.mark_date = t.mark_date AND c.ticker = t.ticker
                             AND c.open_px = t.open_px AND c.close_px = t.close_px) AS admit
  FROM t
)
SELECT IF(a.admit, a.mark_date, NULL), a.ticker, a.open_px, a.close_px, a.source
FROM a
WHERE a.admit
"""


def marks_readback_sql(rows: list[dict]) -> str:
    """Per bar, aggregated by ticker: a fetched date with no curated bar is missing, one whose curated bar holds
    other values differs. The two are independent, so a restated history is visible even beside a new bar."""
    tuples = ",\n".join(f"  ({sql_str(r['ticker'])}, {sql_str(r['mark_date'])}, {sql_str(r['row_sha'][:READBACK_HEX])})"
                        for r in sorted(rows, key=lambda r: (r["ticker"], r["mark_date"])))
    n_tickers = len({r["ticker"] for r in rows})
    return f"""-- scripts/paper_book.py marks readback ({n_tickers} tickers, {len(rows)} bars). Issue it BEFORE and AFTER the batches.
-- BEFORE: missing_tickers is expected (today's new bars); differs_tickers = stored bars that no longer match the
-- source (a split or restatement) -> RESTATEMENT RE-BASE. AFTER: missing_tickers or differs_tickers -> --only
-- <those tickers>, at most two rounds; whatever survives is reported. Never UPDATE or DELETE a mark.
WITH e AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<ticker STRING, d STRING, sha STRING>>[
{tuples}
  ])
),
s AS (
  SELECT e.ticker,
    CASE WHEN c.ticker IS NULL THEN 'missing'
         WHEN {marks_digest_sql('c', READBACK_HEX)} = e.sha THEN 'ok'
         ELSE 'differs' END AS status
  FROM e
  LEFT JOIN {MARKS_CURATED} c ON c.ticker = e.ticker AND c.mark_date = DATE(e.d)
)
SELECT {n_tickers} AS tickers_expected, {len(rows)} AS bars_expected,
  COUNTIF(status = 'ok') AS bars_ok,
  IFNULL(STRING_AGG(DISTINCT IF(status = 'missing', ticker, NULL), ',' ORDER BY IF(status = 'missing', ticker, NULL)), '')
    AS missing_tickers,
  IFNULL(STRING_AGG(DISTINCT IF(status = 'differs', ticker, NULL), ',' ORDER BY IF(status = 'differs', ticker, NULL)), '')
    AS differs_tickers
FROM s
"""


# ----- generation -----

def parse_only(spec: str | None, rows: list[dict], kind: str) -> list[dict]:
    """--only takes input row numbers (calls) or tickers (marks); returns the rows to send."""
    if not spec:
        return rows
    tokens = [t.strip() for t in spec.split(",") if t.strip()]
    if kind == "calls":
        if not all(t.isdigit() for t in tokens):
            raise RowError(f"--only {spec!r}: calls take comma-separated row numbers")
        picked = {int(t) for t in tokens}
        bad = sorted(picked - {r["n"] for r in rows})
        if bad:
            raise RowError(f"--only rows {bad} are not input rows (1..{len(rows)})")
        return [r for r in rows if r["n"] in picked]
    picked = {t.upper() for t in tokens}
    bad = sorted(picked - {r["ticker"] for r in rows})
    if bad:
        raise RowError(f"--only tickers {bad} are not in the input")
    return [r for r in rows if r["ticker"] in picked]


def batches(rows: list[dict], keys: tuple, budget: int = BATCH_CHARS) -> list[list[dict]]:
    """Whole tickers per statement (a ticker split across batches would let the per-statement cap count go
    stale), the fewest statements within `budget` chars of tuples, filled evenly rather than big + stub."""
    groups = {}
    for r in rows:
        groups.setdefault(r["ticker"], []).append(r)
    sized = [(g, sum(len(tuple_sql(r, keys)) + 2 for r in g)) for g in groups.values()]
    total = sum(s for _, s in sized)
    target = total / max(1, -(-total // budget))
    out, size = [], 0
    for g, s in sized:
        if out and size + s <= budget and size + s / 2 <= target:
            out[-1].extend(g)
            size += s
        else:
            out.append(list(g))
            size = s
    return out


def readback_parts(rows: list[dict], build) -> list[list[dict]]:
    """Whole tickers per readback part (first-appearance order, as batches() groups them), packed greedily so
    each part's `build(part)` text stays within READBACK_CHARS; a ticker over the limit on its own gets a part
    of its own. Only called once the readback of ALL rows is already over the limit."""
    groups = {}
    for r in rows:
        groups.setdefault(r["ticker"], []).append(r)
    parts = []
    for g in groups.values():
        if parts and len(build(parts[-1] + g)) <= READBACK_CHARS:
            parts[-1].extend(g)
        else:
            parts.append(list(g))
    return parts


def generate(kind: str, raw: list, out_dir: str, call_date: str | None = None, session: str | None = None,
             only: str | None = None, votes: list | None = None,
             budget: int = BATCH_CHARS) -> tuple[list[str], list[str]]:
    """Write DIR/batch_NN.sql + DIR/readback.sql (or DIR/readback_NN.sql when one readback would exceed
    READBACK_CHARS); return (batch paths, readback paths). Raises RowError on bad input."""
    if kind == "calls" and isinstance(raw, list) and not raw:
        raise RowError("the input must be a non-empty JSON array (0 headlines: skip steps 4 and 5)")
    if not isinstance(raw, list) or not raw:
        raise RowError("the input must be a non-empty JSON array")
    if kind == "calls":
        if not call_date or not session:
            raise RowError("calls needs --call-date and --session")
        call_date = norm_date(call_date)
        session = text({"session": session}, "session")
        if votes is not None:
            raw = attach_votes(raw, votes)
        rows = build_calls(raw, call_date, session)
        keys = CALL_TUPLE_KEYS
    else:
        if votes is not None:
            raise RowError("--votes applies to calls only")
        rows = build_marks(raw)
        keys = MARK_TUPLE_KEYS
    send = parse_only(only, rows, kind)
    os.makedirs(out_dir, exist_ok=True)
    for name in os.listdir(out_dir):  # a stale batch or readback from an earlier invocation must never be re-issued
        if name.endswith(".sql") and (name.startswith(("batch_", "readback_")) or name == "readback.sql"):
            os.remove(os.path.join(out_dir, name))
    paths = []
    chunks = batches(send, keys, budget)
    for i, chunk in enumerate(chunks, 1):
        what = (f"input rows {', '.join(str(r['n']) for r in chunk)}" if kind == "calls"
                else f"{len(chunk)} bars of {', '.join(sorted({r['ticker'] for r in chunk}))}")
        label = f"batch {i}/{len(chunks)} ({what})"
        sql = calls_batch_sql(chunk, call_date, session, label) if kind == "calls" else marks_batch_sql(chunk, label)
        paths.append(os.path.join(out_dir, f"batch_{i:02d}.sql"))
        with open(paths[-1], "w", encoding="ascii") as f:
            f.write(sql)
    if kind == "calls":
        def build(part):
            return calls_readback_sql(part, call_date, session)
    else:
        build = marks_readback_sql
    readback = build(rows)
    if len(readback) <= READBACK_CHARS:
        texts = [("readback.sql", readback)]
    else:  # each part is a standalone query whose expected counts cover only its own rows
        texts = [(f"readback_{i:02d}.sql", build(part))
                 for i, part in enumerate(readback_parts(rows, build), 1)]
    readback_paths = []
    for name, sql in texts:
        readback_paths.append(os.path.join(out_dir, name))
        with open(readback_paths[-1], "w", encoding="ascii") as f:
            f.write(sql)
    return paths, readback_paths


def _no_duplicate_keys(pairs: list) -> dict:
    keys = [k for k, _ in pairs]
    dupes = sorted({k for k in keys if keys.count(k) > 1})
    if dupes:
        raise RowError(f"duplicate keys {dupes}")
    return dict(pairs)


def _load_json(path: str):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f, object_pairs_hook=_no_duplicate_keys)
    except ValueError as e:  # name the file: five --votes files look alike
        raise RowError(f"{path}: {e}") from None


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("kind", choices=("urls", "marks", "headlines", "calls"))
    p.add_argument("rows", nargs="?", help="calls: headlines.json; marks: a ROWS.json instead of --nasdaq-dir")
    p.add_argument("--out", help="marks/calls: directory for batch_NN.sql + readback.sql; headlines: the JSON file")
    p.add_argument("--today", help="urls: state.trading_day_today.today (YYYY-MM-DD)")
    p.add_argument("--from", dest="since_date", help="urls: widen the marks window back to this date (history re-fetch)")
    p.add_argument("--call-date", help="calls: state.trading_day_today.today (YYYY-MM-DD)")
    p.add_argument("--session", help="calls: this run's session id (scorer_session)")
    p.add_argument("--votes", nargs="+", metavar="VOTES.json", help=f"calls: the k={K} readers' vote files")
    p.add_argument("--nasdaq-dir", help="marks: directory of raw Nasdaq historical <TICKER>.json responses")
    p.add_argument("--rss-dir", help="headlines: directory of raw <TICKER>.google.xml / <TICKER>.nasdaq.xml feeds")
    p.add_argument("--since", help="headlines: the SCAN WINDOW start, ISO-8601 with a zone")
    p.add_argument("--only", help="calls: row numbers; marks and urls: tickers")
    a = p.parse_args(argv)
    skipped = []
    try:
        if a.kind == "urls":
            if not a.today:
                raise RowError("urls needs --today")
            only = {t.strip().upper() for t in a.only.split(",")} if a.only else None
            for path, accept, url in fetch_urls(a.today, a.since_date, only):
                print(f"{path}\t{accept}\t{url}")
            return 0
        if not a.out:
            raise RowError(f"{a.kind} needs --out")
        if a.kind == "headlines":
            if not (a.rss_dir and a.since):
                raise RowError("headlines needs --rss-dir and --since")
            rows, notes, google_unreadable = select_headlines(a.rss_dir, a.since)
            with open(a.out, "w", encoding="utf-8") as f:
                json.dump(rows, f, ensure_ascii=False, indent=1)
            readers = os.path.join(os.path.dirname(os.path.abspath(a.out)), "readers.txt")
            with open(readers, "w", encoding="utf-8") as f:
                f.write(reader_list(rows))
            print(f"headlines: {len(rows)} written to {a.out}; the numbered reader list is {readers}")
            for t, note in sorted(notes.items()):
                print(f"under cap: {t}: {note}")
            if not rows:  # a defined path, not an error: there is nothing to vote on or write today
                print("headlines: 0 written -- no calls today: skip steps 4 and 5")
            if google_unreadable:
                print(f"google feed missing or unreadable: {len(google_unreadable)} of {len(UNIVERSE)} tickers "
                      f"({', '.join(google_unreadable)})")
            return 0
        if (a.rows is None) == (a.nasdaq_dir is None) or (a.nasdaq_dir and a.kind != "marks"):
            raise RowError("give exactly one input: ROWS.json, or --nasdaq-dir for marks")
        if a.nasdaq_dir:
            raw, skipped = load_nasdaq_dir(a.nasdaq_dir)
        else:
            raw = _load_json(a.rows)
        votes = [_load_json(v) for v in a.votes] if a.votes else None
        paths, readback_paths = generate(a.kind, raw, a.out, a.call_date, a.session, a.only, votes=votes)
    except (OSError, ValueError) as e:  # RowError and json.JSONDecodeError are both ValueErrors
        print(f"paper_book: nothing written -- {e}", file=sys.stderr)
        for s in skipped:
            print(f"  skipped ticker: {s}", file=sys.stderr)
        return 2
    print(f"{a.kind}: {len(raw)} input rows; {len(paths)} batch file(s) to issue verbatim, one at a time:")
    for path in paths:
        print(f"  {path}")
    # together the readback files check every input row, whatever --only selected
    print("then issue each readback file (any order; each checks only its own rows):")
    for path in readback_paths:
        print(f"  {path}")
    for s in skipped:
        print(f"skipped ticker (nothing written for it): {s}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

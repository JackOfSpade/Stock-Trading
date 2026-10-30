"""Pins scripts/paper_book.py, the data path of D1's NEWS-REACTION PAPER BOOK.

The digests in tests/fixtures/paper_book_vectors.json were reproduced by BigQuery from the STORED rows on
2026-10-21, so a change here that moves a digest means the Python and SQL sides have diverged and every
guarded row would be skipped.
"""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
import re
import tempfile
import unittest
from pathlib import Path
from typing import ClassVar

ROOT = Path(__file__).resolve().parent.parent
_SPEC = importlib.util.spec_from_file_location("paper_book", ROOT / "scripts" / "paper_book.py")
pb = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(pb)

with open(ROOT / "tests" / "fixtures" / "paper_book_vectors.json", encoding="utf-8") as _fh:
    VECTORS = json.load(_fh)

_ESC = re.compile(r"\\(U[0-9a-fA-F]{8}|u[0-9a-fA-F]{4}|.)")


def decode_sql_str(lit: str) -> str:
    """Decode the subset of GoogleSQL quoted-string escapes sql_str emits."""
    assert lit[0] == lit[-1] == "'"

    def one(m):
        e = m.group(1)
        return chr(int(e[1:], 16)) if e[0] in "uU" and len(e) > 1 else e

    return _ESC.sub(one, lit[1:-1])


def headline(i: int, ticker: str = "AAPL") -> dict:
    return {"ticker": ticker, "headline": f"Headline number {i} for {ticker}",
            "published_ts": f"2026-10-20T20:{i % 60:02d}:00Z", "source": "google-news-rss",
            "source_url": f"https://news.google.com/rss/articles/CBMi{i}?oc=5"}


def with_votes(row: dict, votes=("UP", "UP", "UP", "UP", "FLAT")) -> dict:
    return dict(row, votes=list(votes))


def rss(items) -> str:
    body = "".join(f"<item><title>{t}</title><link>https://news.google.com/rss/articles/{i}</link>"
                   f"<pubDate>{p}</pubDate></item>" for i, (t, p) in enumerate(items))
    return f'<?xml version="1.0"?><rss version="2.0"><channel><title>x</title>{body}</channel></rss>'


class LiveVerifiedVectors(unittest.TestCase):
    def test_calls_digests_match_bigquery(self):
        c = VECTORS["calls"]
        rows = pb.build_calls(c["rows"], c["call_date"], c["session"])
        self.assertEqual(len(rows), len(c["expected"]))
        for row, exp in zip(rows, c["expected"], strict=True):
            self.assertEqual(row["headline_hash"], exp["headline_hash"])
            self.assertEqual(row["direction"], exp["direction"])
            self.assertEqual(row["agreement_score"], exp["agreement_score"])
            self.assertEqual(row["row_sha"], exp["row_sha16"])

    def test_marks_digests_match_bigquery(self):
        m = VECTORS["marks"]
        rows = pb.build_marks(m["rows"])
        for row, exp in zip(rows, m["expected"], strict=True):
            self.assertEqual((row["mark_date"], row["open_px"], row["close_px"], row["row_sha"]),
                             (exp["mark_date"], exp["open_px"], exp["close_px"], exp["row_sha16"]))

    def test_digest_sql_renders_in_utc_and_covers_the_session(self):
        sql = pb.calls_digest_sql("x")
        self.assertIn("FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', x.published_ts, 'UTC')", sql)
        self.assertIn("IFNULL(x.scorer_session, '')", sql)


class Universe(unittest.TestCase):
    def test_matches_the_bigquery_261_seed(self):
        seed = (ROOT / "bigquery" / "261_news_reaction_paper_book.sql").read_text(encoding="utf-8")
        universe = set(re.findall(r"STRUCT\('([A-Z]+)'(?: AS ticker)?, 'UNIVERSE'", seed))
        self.assertEqual(universe, set(pb.UNIVERSE))
        self.assertEqual(len(pb.ALL_TICKERS), 41)
        self.assertEqual(pb.ALL_TICKERS[-1], "SPY")

    def test_relevance_is_case_sensitive_whole_word(self):
        keep = [("JNJ", "Johnson & Johnson (JNJ) Investigation"), ("COP", "ConocoPhillips (NYSE:COP) Share Price"),
                ("UPS", "United Parcel Service (NYSE:UPS) Shares Climb"), ("MCD", "McDonald\u2019s value menu"),
                ("META", "Meta weighs on the Nasdaq"), ("HON", "Is Honeywell Stock A Real Bargain?"),
                ("LLY", "Form 4 Eli lilly For: 20 October"), ("GE", "GE stock reports USD 2.25 adjusted EPS pre-market"),
                ("GE", "GE (GE) Q3 Earnings: Taking a Look at Key Metrics"), ("JPM", "JPMorgan profit jumps 12% on dealmaking"),
                ("JPM", "JPMorgan (JPM): Can New Branches Keep Winning Profitable Customers?"),
                ("BAC", "BAC Investors Have Opportunity to Lead Bank of America Securities Fraud Lawsuit"),
                ("GS", "Goldman Sachs Is Paying Up to $2.25 Billion for an ETF Business"),
                ("MRK", "What Happens To Merck Stock If Keytruda Sales Stop Growing?"),
                ("JPM", "JPMorgan Chase third-quarter profit tops analyst expectations"),
                ("GS", "Goldman Sachs beats estimates for third-quarter profit on trading boom"),
                ("BAC", "Bank of America raises full-year outlook for net interest income"),
                ("JPM", "JPMorgan CEO Jamie Dimon warns of more credit cockroaches")]
        drop = [("JNJ", "Dwayne Johnson Is Completely Unrecognizable"), ("COP", "Cop shoots dead teen son"),
                ("UPS", "10+ Best Games Like Schedule 1 For Grown Ups"), ("META", "A meta-analysis of trials"),
                ("INTC", "New intelligence report"), ("V", "Visas tightened for students"),
                ("HON", "Top Honeywell Aerospace (HONA) Competitors 2026"), ("GE", "GE Vernova unveils a turbine"),
                ("JPM", "Marsh & McLennan stock: JPMorgan lifts target to USD 218.00"),
                ("JPM", "LSE Group stock: JPMorgan reiterates Buy ahead of the Xetra open"),
                ("JPM", "JPMorgan Asset Management sees Bitcoin beating stocks"),
                ("JPM", "JPMorgan Chase & Co. Forecasts Strong Price Appreciation for Zions Bancorporation"),
                ("GS", "'Risk appetite' for stocks is the worst since March, Goldman Sachs says"),
                ("BAC", "Ameriprise's Advisor Retention Issues Cast Shadow Over Its Stock: BofA"),
                ("MRK", "Merck KGaA swallows Silence Therapeutics in billion-dollar deal"),
                ("COP", "ConocoPhillips (NYSE:COP) Share Price, Forecast & Analysis - Stocks Down Under"),
                ("AMD", "AMD 261021 595.00C (AMD261021C595000) Stock Options Chain | Quotes & News"),
                ("GS", "LLY Stock Hits All-Time High After Goldman Sachs Raises Price Target Ahead Of Q3 Earnings"),
                ("JPM", "JPMorgan lifts target for Credicorp stock ahead of Q3 earnings"),
                ("META", "A New Meta-Analysis Of Sleep Trials"), ("ORCL", "The Oracle of Omaha Sells More Stock")]
        for t, title in keep:
            self.assertTrue(pb.names_company(t, title), (t, title))
        for t, title in drop:
            self.assertFalse(pb.names_company(t, title), (t, title))

    def test_urls_are_encoded_and_cover_every_ticker(self):
        rows = pb.fetch_urls("2026-10-21")
        self.assertEqual(sum(1 for f, _, _ in rows if f.startswith("nasdaq/")), 41)
        self.assertEqual(sum(1 for f, _, _ in rows if f.endswith(".google.xml")), 40)
        jnj = next(u for f, _, u in rows if f == "rss/JNJ.google.xml")
        self.assertIn("q=Johnson+%26+Johnson+stock+when%3A2d", jnj)
        spy = next(u for f, _, u in rows if f == "nasdaq/SPY.json")
        self.assertIn("assetclass=etf&fromdate=2026-10-07&todate=2026-10-21&limit=20", spy)
        for _, _, u in rows:
            self.assertNotRegex(u, r"\s")

    def test_history_refetch_urls(self):
        rows = pb.fetch_urls("2026-10-21", since="2026-10-06", only={"NVDA"})
        self.assertEqual([f for f, _, _ in rows], ["nasdaq/NVDA.json"])
        self.assertIn("fromdate=2026-10-06&todate=2026-10-21&limit=21", rows[0][2])


class SqlLiteral(unittest.TestCase):
    CASES: ClassVar[list] = ["plain", "it's", "back\\slash", "Apple\u2019s \u2014 caf\u00e9", "rocket \U0001f680",
                             "tab\tnew\nline", "'", "\\'", ""]

    def test_round_trips_and_is_printable_ascii(self):
        for s in self.CASES:
            lit = pb.sql_str(s)
            self.assertRegex(lit, r"^[ -~]*$", s)
            self.assertEqual(decode_sql_str(lit), s)

    def test_never_emits_sql92_quote_doubling(self):
        self.assertNotIn("''", pb.sql_str("it's"))


class Derivations(unittest.TestCase):
    def test_modal_direction_and_agreement(self):
        cases = {
            ("UP",) * 5: ("UP", "1"),
            ("UP", "UP", "UP", "UP", "DOWN"): ("UP", "0.8"),
            ("DOWN", "DOWN", "DOWN", "UP", "UP"): ("DOWN", "0.6"),
            ("FLAT", "FLAT", "FLAT", "UP", "DOWN"): ("FLAT", "0.6"),
            ("UP", "UP", "DOWN", "DOWN", "FLAT"): ("FLAT", "0.4"),  # tied mode records FLAT
            ("FLAT", "FLAT", "UP", "UP", "DOWN"): ("FLAT", "0.4"),
        }
        for votes, want in cases.items():
            self.assertEqual(pb.call_direction(list(votes)), want, votes)

    def test_headline_hash_is_lowercased_whitespace_collapsed(self):
        want = hashlib.sha256("apple stock falls 1%".encode()).hexdigest()
        self.assertEqual(pb.headline_hash("  Apple   Stock\tFalls 1%\n"), want)

    def test_timestamps_normalise_to_utc_seconds(self):
        self.assertEqual(pb.norm_ts("2026-10-20T21:05:01Z"), "2026-10-20T21:05:01Z")
        self.assertEqual(pb.norm_ts("2026-10-20T23:05:01.5+02:00"), "2026-10-20T21:05:01Z")
        self.assertEqual(pb.norm_ts("Tue, 20 Oct 2026 21:05:01 GMT"), "2026-10-20T21:05:01Z")
        self.assertEqual(pb.norm_ts(None), "")
        with self.assertRaises(pb.RowError):
            pb.norm_ts("2026-10-20T21:05:01")  # no zone

    def test_nasdaq_prices_and_dates(self):
        self.assertEqual(pb.norm_px("$1,234.50", "open_px"), "1234.5")
        self.assertEqual(pb.norm_px("100.00", "open_px"), "100")
        self.assertEqual(pb.norm_px("$340.775", "open_px"), "340.775")
        self.assertEqual(pb.norm_date("10/20/2026"), "2026-10-20")
        for bad in ("N/A", "0", "-5", "", None, "1.0000000001"):
            with self.assertRaises(pb.RowError, msg=bad):
                pb.norm_px(bad, "open_px")

    def test_prices_keep_full_numeric_precision_and_ignore_context_rounding(self):
        from decimal import localcontext

        with localcontext() as ctx:
            ctx.prec = 6
            self.assertEqual(pb.norm_px("12345678901234567890123456789.1234567890", "open_px"),
                             "12345678901234567890123456789.123456789")
            self.assertEqual(pb.norm_px("1.0000000000", "open_px"), "1")
        for bad in ("1e29", "1e999999999", "1.0000000001"):
            with self.assertRaises(pb.RowError):
                pb.norm_px(bad, "open_px")


    def test_marks_reject_a_ticker_outside_the_pinned_set(self):
        # A free-form ticker reached the batch file's `-- ... (N bars of <tickers>)` header verbatim,
        # so an embedded newline put arbitrary SQL on a line of its own.
        bar = {"mark_date": "10/20/2026", "open_px": "1", "close_px": "1"}
        self.assertEqual(len(pb.build_marks([dict(bar, ticker=pb.ALL_TICKERS[0])])), 1)
        for bad in ("ZZZZ", pb.ALL_TICKERS[0] + "\nDELETE FROM x WHERE TRUE;--"):
            with self.assertRaisesRegex(pb.RowError, "is not one of the", msg=bad):
                pb.build_marks([dict(bar, ticker=bad)])

class HeadlineSelection(unittest.TestCase):
    def test_window_relevance_dedup_cap_and_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            google = [("Johnson &amp; Johnson raises guidance - A", "Tue, 20 Oct 2026 21:00:00 GMT"),
                      ("Dwayne Johnson films a sequel - B", "Tue, 20 Oct 2026 21:30:00 GMT"),
                      ("Johnson &amp; Johnson raises guidance - B2", "Tue, 20 Oct 2026 21:20:00 GMT"),  # syndicated copy
                      ("J&amp;J wins a patent case - C", "Mon, 19 Oct 2026 10:00:00 GMT")]  # before the window
            nasdaq = [("JNJ shares rise on guidance - D", "Tue, 20 Oct 2026 22:00:00 GMT"),
                      ("JNJ options volume spikes - E", "Tue, 20 Oct 2026 19:00:00 GMT"),
                      ("Unrelated market wrap - F", "Tue, 20 Oct 2026 23:00:00 GMT")]
            for name, items in (("JNJ.google.xml", google), ("JNJ.nasdaq.xml", nasdaq)):
                with open(os.path.join(tmp, name), "w", encoding="utf-8") as f:
                    f.write(rss(items))
            rows, notes, google_unreadable = pb.select_headlines(tmp, "2026-10-20T00:00:00Z")
        self.assertEqual(google_unreadable, sorted(t for t in pb.UNIVERSE if t != "JNJ"))
        self.assertEqual(len(google_unreadable), 39)
        self.assertNotIn("JNJ", google_unreadable)
        jnj = [(r["headline"], r["source"]) for r in rows if r["ticker"] == "JNJ"]
        self.assertEqual(jnj, [("Johnson & Johnson raises guidance - B2", "google-news-rss"),
                               ("JNJ shares rise on guidance - D", "nasdaq-rss"),
                               ("JNJ options volume spikes - E", "nasdaq-rss")])
        lines = pb.reader_list(rows).splitlines()
        self.assertEqual(lines[0], "1\tJNJ\t2026-10-20T21:20:00Z\tJohnson & Johnson raises guidance - B2")
        self.assertNotIn("http", pb.reader_list(rows))
        self.assertNotIn("JNJ", notes)
        self.assertEqual(notes["AAPL"], "0 headline(s); no google file (the fetch wrote nothing); "
                                        "no nasdaq file (the fetch wrote nothing)")


class InputValidation(unittest.TestCase):
    def _bad(self, rows, msg):
        with self.assertRaisesRegex(pb.RowError, msg):
            pb.build_calls(rows, "2026-10-21", "s")

    def test_rejects_preregistration_violations(self):
        self._bad([with_votes(headline(1), ("UP",) * 4)], "exactly k=5")
        self._bad([with_votes(headline(1), ("UP", "UP", "UP", "UP", "MAYBE"))], "may only contain")
        self._bad([with_votes(headline(i)) for i in range(4)], "more than 3 headlines for AAPL")
        self._bad([with_votes(headline(1)), with_votes(dict(headline(1), headline="headline NUMBER 1  for aapl"))],
                  "duplicate headline")
        self._bad([with_votes(dict(headline(1), headline="Apple story - Outlet A")),
                   with_votes(dict(headline(2), headline="Apple story - Outlet B"))], "syndicated copy")
        self._bad([with_votes(headline(1, "ZZZZ"))], "not a UNIVERSE ticker")

    def test_rejects_a_supplied_headline_hash_that_disagrees(self):
        self._bad([with_votes(dict(headline(1), headline_hash="0" * 64))], "!= the hash of its headline")

    def test_rejects_the_digest_separator(self):
        self._bad([with_votes(dict(headline(1), headline="a\x1fb"))], "separator")

    def test_same_headline_under_two_tickers_is_allowed(self):
        rows = pb.build_calls([with_votes(headline(1, "AAPL")), with_votes(dict(headline(1, "AAPL"), ticker="MSFT"))],
                              "2026-10-21", "s")
        self.assertEqual(len(rows), 2)

    def test_votes_files_merge_by_number_not_position(self):
        heads = [headline(1), headline(2)]
        readers = [{"2": "DOWN", "1": "UP"}] * 4 + [{"1": "UP", "2": "UP"}]
        merged = pb.attach_votes(heads, readers)
        self.assertEqual(merged[0]["votes"], ["UP"] * 5)
        self.assertEqual(merged[1]["votes"], ["DOWN"] * 4 + ["UP"])

    def test_votes_files_must_cover_every_headline_exactly(self):
        heads = [headline(1), headline(2)]
        full = {"1": "UP", "2": "UP"}
        with self.assertRaisesRegex(pb.RowError, "no vote for headline numbers \\[2\\]"):
            pb.attach_votes(heads, [full] * 4 + [{"1": "UP"}])
        with self.assertRaisesRegex(pb.RowError, "unknown headline numbers"):
            pb.attach_votes(heads, [full] * 4 + [dict(full, **{"3": "UP"})])
        with self.assertRaisesRegex(pb.RowError, "exactly k=5 reader files"):
            pb.attach_votes(heads, [full] * 4)


class Generation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out = os.path.join(self.tmp.name, "out")

    def tearDown(self):
        self.tmp.cleanup()

    def _calls(self, n, **kw):
        tickers = sorted(pb.UNIVERSE)
        raw = [with_votes(headline(i, tickers[(i - 1) // 3])) for i in range(1, n + 1)]
        return pb.generate("calls", raw, self.out, "2026-10-21", "session_test", **kw)

    def _read(self, path):
        with open(path, encoding="ascii") as f:
            return f.read()

    def test_batches_stay_within_budget_and_cover_every_row_once(self):
        paths, readbacks = self._calls(120, budget=6000)
        tickers = []
        self.assertGreater(len(paths), 1)
        self.assertEqual(len(readbacks), 1)
        seen = []
        for p in paths:
            sql = self._read(p)
            mine = [int(n) for n in re.findall(r"(?m)^  \((\d+), '[A-Z]+', '[0-9a-f]{64}'", sql)]
            seen += mine
            tickers.append({re.search(r"(?m)^  \(" + str(n) + r", '([A-Z]+)'", sql).group(1) for n in mine})
            self.assertIn(pb.calls_digest_sql("t") + " = t.row_sha", sql)
            self.assertIn(pb.story_sql("x.headline") + " = " + pb.story_sql("t.headline"), sql)  # from guarded values
            self.assertIn("SELECT IF(a.admit, a.call_date, NULL)", sql)  # a lost WHERE fails the NOT NULL column
            self.assertIn("WHERE a.admit", sql)
            self.assertIn("PARTITION BY g.ticker, g.eligible ORDER BY g.published_ts DESC, g.headline_hash) <= 3", sql)
            self.assertIn("INTERVAL 4 DAY", sql)
        self.assertEqual(sorted(seen), list(range(1, 121)))
        for i, a in enumerate(tickers):  # whole tickers per batch: the per-statement cap count cannot go stale
            for b in tickers[i + 1:]:
                self.assertFalse(a & b)

    def test_default_batches_fit_the_tool_output_limit(self):
        long_url = "https://news.google.com/rss/articles/" + "A" * 600 + "?oc=5"
        tickers = sorted(pb.UNIVERSE)
        raw = [with_votes(dict(headline(i, tickers[(i - 1) // 3]), source_url=long_url)) for i in range(1, 121)]
        paths, readbacks = pb.generate("calls", raw, self.out, "2026-10-21", "s")
        for p in paths + readbacks:
            self.assertLess(os.path.getsize(p), 30000, p)

    def test_readback_checks_every_row_even_with_only(self):
        paths, readbacks = self._calls(9, only="2,7")
        self.assertEqual(re.findall(r"(?m)^  \((\d+), '[A-Z]+', '[0-9a-f]{64}'", self._read(paths[0])), ["2", "7"])
        self.assertEqual(len(readbacks), 1)
        readback = self._read(readbacks[0])
        self.assertEqual(len(re.findall(r"(?m)^  \(\d+, '[A-Z]+', '[0-9a-f]{16}', '[0-9a-f]{16}', '[0-9a-f]{16}'\)",
                                        readback)), 9)
        for col in ("missing_rows", "earlier_session_rows", "already_called_rows", "capped_rows", "mismatch_rows",
                    "duplicate_rows", "over_cap_tickers"):
            self.assertIn(f"AS {col}", readback)

    def test_rerun_removes_stale_batches(self):
        self._calls(120, budget=6000)
        paths, readbacks = self._calls(3)
        self.assertEqual(sorted(f for f in os.listdir(self.out) if f.startswith("batch_")), ["batch_01.sql"])
        self.assertEqual(len(paths) + len(readbacks), 2)
        self.assertEqual(len(readbacks), 1)

    def test_only_rejects_unknown_rows_and_tickers(self):
        with self.assertRaises(pb.RowError):
            self._calls(3, only="4")
        with self.assertRaises(pb.RowError):
            pb.generate("marks", VECTORS["marks"]["rows"], self.out, only="ZZZZ")

    def test_marks_are_revision_aware_and_read_back_per_bar(self):
        paths, readbacks = pb.generate("marks", VECTORS["marks"]["rows"], self.out, only="spy")
        batch = self._read(paths[0])
        self.assertEqual(re.findall(r"(?m)^  \(\d+, '[\d-]+', '([A-Z]+)'", batch), ["SPY"] * 2)
        self.assertIn("AND c.open_px = t.open_px AND c.close_px = t.close_px", batch)
        self.assertIn("SELECT IF(a.admit, a.mark_date, NULL)", batch)
        self.assertEqual(len(readbacks), 1)
        readback = self._read(readbacks[0])
        for exp in VECTORS["marks"]["expected"]:  # every bar, not a per-ticker window
            self.assertIn(f"'{exp['mark_date']}', '{exp['row_sha16'][:8]}')", readback)
        self.assertIn("AS missing_tickers", readback)
        self.assertIn("AS differs_tickers", readback)

    def test_nasdaq_dir_reports_every_pinned_ticker_it_could_not_use(self):
        raw_dir = os.path.join(self.tmp.name, "nasdaq")
        os.makedirs(raw_dir)
        good = {"data": {"tradesTable": {"rows": [
            {"date": "10/20/2026", "open": "$215.98", "close": "$216.47"},
            {"date": "10/19/2026", "open": "$1,210.00", "close": "$1,212.25"}]}}}
        bad = {"data": {"tradesTable": {"rows": [
            {"date": "10/20/2026", "open": "$15.00", "close": "$15.10"},
            {"date": "10/19/2026", "open": "N/A", "close": "$15.00"}]}}}
        empty = {"data": {"tradesTable": {"rows": None}}}
        for name, body in (("NVDA", good), ("INTC", bad), ("XOM", empty), ("ZZZZ", good)):
            with open(os.path.join(raw_dir, f"{name}.json"), "w", encoding="utf-8") as f:
                json.dump(body, f)
        with open(os.path.join(raw_dir, "SPY.json"), "w", encoding="utf-8") as f:
            f.write("<html>blocked</html>")
        raw, skipped = pb.load_nasdaq_dir(raw_dir)
        self.assertEqual([(r["ticker"], r["open_px"]) for r in raw], [("NVDA", "$215.98"), ("NVDA", "$1,210.00")])
        self.assertEqual(len(skipped), 40)  # every pinned ticker but NVDA; the stray ZZZZ file is ignored
        reasons = {s.split()[0]: s for s in skipped}
        self.assertIn("no file", reasons["AAPL"])
        self.assertIn("open_px 'N/A'", reasons["INTC"])
        self.assertIn("SPY", reasons)
        self.assertEqual([r["open_px"] for r in pb.build_marks(raw)], ["215.98", "1210"])

    def test_every_emitted_file_is_printable_ascii(self):
        c = VECTORS["calls"]
        paths, readbacks = pb.generate("calls", c["rows"], self.out, c["call_date"], c["session"])
        for p in paths + readbacks:
            self.assertRegex(self._read(p), r"^[\x20-\x7e\n]*$", p)

    def _large_marks(self):
        days, d = [], pb.date(2026, 6, 1)
        while len(days) < 80:
            if d.weekday() < 5:
                days.append(d.isoformat())
            d += pb.timedelta(days=1)
        return [{"ticker": t, "mark_date": day, "open_px": "100.25", "close_px": "101.5"}
                for t in pb.ALL_TICKERS for day in days]

    def _readback_files(self):
        return sorted(f for f in os.listdir(self.out) if re.fullmatch(r"readback(_\d+)?\.sql", f))

    def test_large_marks_readback_splits_by_whole_ticker(self):
        raw = self._large_marks()
        _, readbacks = pb.generate("marks", raw, self.out)
        self.assertGreater(len(readbacks), 1)
        self.assertFalse(os.path.exists(os.path.join(self.out, "readback.sql")))
        self.assertEqual([os.path.basename(p) for p in readbacks],
                         [f"readback_{i:02d}.sql" for i in range(1, len(readbacks) + 1)])
        pairs, owner = [], {}
        for p in readbacks:
            self.assertLess(os.path.getsize(p), 30000, p)
            sql = self._read(p)
            self.assertLessEqual(len(sql), pb.READBACK_CHARS, p)
            mine = re.findall(r"(?m)^  \('([A-Z]+)', '(\d{4}-\d{2}-\d{2})', '[0-9a-f]{8}'\)", sql)
            self.assertTrue(mine, p)
            for t in {t for t, _ in mine}:
                self.assertNotIn(t, owner, f"{t} in {owner.get(t)} and {p}")
                owner[t] = p
            m = re.search(r"SELECT (\d+) AS tickers_expected, (\d+) AS bars_expected", sql)
            self.assertEqual((int(m.group(1)), int(m.group(2))), (len({t for t, _ in mine}), len(mine)), p)
            pairs += mine
        want = [(r["ticker"], r["mark_date"]) for r in raw]
        self.assertEqual(len(pairs), len(want))
        self.assertEqual(sorted(pairs), sorted(want))
        self.assertEqual(len(set(pairs)), len(pairs))

    def test_small_marks_readback_stays_one_file(self):
        _, readbacks = pb.generate("marks", VECTORS["marks"]["rows"], self.out)
        self.assertEqual(len(readbacks), 1)
        self.assertTrue(readbacks[0].endswith(os.sep + "readback.sql"), readbacks[0])
        self.assertEqual(self._readback_files(), ["readback.sql"])

    def test_rerun_removes_stale_readbacks(self):
        _, big = pb.generate("marks", self._large_marks(), self.out)
        self.assertGreater(len(big), 1)
        pb.generate("marks", VECTORS["marks"]["rows"], self.out)
        self.assertEqual(self._readback_files(), ["readback.sql"])
        _, again = pb.generate("marks", self._large_marks(), self.out)
        self.assertEqual(self._readback_files(), sorted(os.path.basename(p) for p in again))
        self.assertNotIn("readback.sql", self._readback_files())

    def test_empty_calls_input_names_the_zero_headline_path(self):
        with self.assertRaises(pb.RowError) as cm:
            pb.generate("calls", [], self.out, "2026-10-21", "s")
        self.assertIn("(0 headlines: skip steps 4 and 5)", str(cm.exception))
        with self.assertRaises(pb.RowError) as cm:
            pb.generate("marks", [], self.out)
        self.assertEqual(str(cm.exception), "the input must be a non-empty JSON array")


class CommandLine(unittest.TestCase):
    def _main(self, argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = pb.main(argv)
        return code, out.getvalue(), err.getvalue()

    def test_invalid_input_exits_2_and_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            rows = os.path.join(tmp, "h.json")
            with open(rows, "w", encoding="utf-8") as f:
                json.dump([with_votes(headline(1), ("UP",) * 3)], f)
            out = os.path.join(tmp, "out")
            code, _, err = self._main(["calls", rows, "--call-date", "2026-10-21", "--session", "s", "--out", out])
            self.assertEqual(code, 2)
            self.assertIn("nothing written", err)
            self.assertFalse(os.path.exists(out))

    def test_a_broken_votes_file_is_named(self):
        with tempfile.TemporaryDirectory() as tmp:
            rows = os.path.join(tmp, "h.json")
            with open(rows, "w", encoding="utf-8") as f:
                json.dump([headline(1)], f)
            votes = []
            for i in range(5):
                votes.append(os.path.join(tmp, f"v{i}.json"))
                with open(votes[-1], "w", encoding="utf-8") as f:
                    f.write('{"1": "UP", "1": "DOWN"}' if i == 2 else '{"1": "UP"}')
            code, _, err = self._main(["calls", rows, "--votes", *votes, "--call-date", "2026-10-21",
                                       "--session", "s", "--out", os.path.join(tmp, "out")])
            self.assertEqual(code, 2)
            self.assertIn("v2.json: duplicate keys", err)

    def test_happy_path_prints_the_files_to_issue(self):
        with tempfile.TemporaryDirectory() as tmp:
            rows = os.path.join(tmp, "h.json")
            with open(rows, "w", encoding="utf-8") as f:
                json.dump([headline(1), headline(2)], f)
            votes = []
            for i in range(5):
                votes.append(os.path.join(tmp, f"v{i}.json"))
                with open(votes[-1], "w", encoding="utf-8") as f:
                    json.dump({"1": "UP", "2": "DOWN"}, f)
            code, out, _ = self._main(["calls", rows, "--votes", *votes, "--call-date", "2026-10-21",
                                       "--session", "s", "--out", os.path.join(tmp, "out")])
            self.assertEqual(code, 0)
            self.assertIn("batch_01.sql", out)
            self.assertIn("readback.sql", out)

    def test_zero_headline_day_has_a_defined_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            rss_dir = os.path.join(tmp, "rss")
            os.makedirs(rss_dir)
            out_file = os.path.join(tmp, "headlines.json")
            code, out, _ = self._main(["headlines", "--rss-dir", rss_dir, "--since", "2026-10-20T00:00:00Z",
                                       "--out", out_file])
            self.assertEqual(code, 0)
            with open(out_file, encoding="utf-8") as f:
                self.assertEqual(json.load(f), [])
        lines = out.splitlines()
        self.assertIn("headlines: 0 written -- no calls today: skip steps 4 and 5", lines)
        google = [line for line in lines if line.startswith("google feed missing or unreadable: ")]
        self.assertEqual(google, ["google feed missing or unreadable: 40 of 40 tickers ("
                                  + ", ".join(sorted(pb.UNIVERSE)) + ")"])

    def test_urls_prints_tab_separated_lines(self):
        code, out, _ = self._main(["urls", "--today", "2026-10-21"])
        self.assertEqual(code, 0)
        lines = out.splitlines()
        self.assertEqual(len(lines), 121)
        self.assertTrue(all(len(line.split("\t")) == 3 for line in lines))


class StoryKey(unittest.TestCase):
    def test_outlet_suffix_and_whitespace_do_not_matter(self):
        a = pb.story_key("What Are Walmart Investors Betting On? - Yahoo Finance")
        self.assertEqual(a, pb.story_key("What Are Walmart Investors Betting On? - Trefis"))
        self.assertEqual(a, pb.story_key("what are walmart  investors betting on?\t- Trefis"))
        self.assertNotEqual(a, pb.story_key("What Are Walmart Investors Selling? - Trefis"))
        # only the LAST " - " is the outlet; the body may contain its own
        self.assertNotEqual(pb.story_key("GE Down 3.8% - Here's Why - MarketBeat"), pb.story_key("GE Down 3.8% - MarketBeat"))

    def test_sql_side_strips_the_same_suffix(self):
        sql = pb.story_sql("x.headline")
        self.assertIn("REGEXP_EXTRACT(", sql)
        self.assertIn("r'^(.*) - '", sql)
        self.assertIn(pb.WS, sql)


if __name__ == "__main__":
    unittest.main()

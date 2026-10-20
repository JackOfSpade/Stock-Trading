"""Text-level guards for the J-lead news-reaction paper book (bigquery/261, bigquery/262).

Stdlib only (unittest + re + os + pathlib) so it runs under the plain interpreter as well as pytest.
Pre-registration record: ops/research/news_reaction_paper_book_2026-10.md.
"""
import os
import re
import unittest
from pathlib import Path

ROOT = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BQ = ROOT / "bigquery"
F261 = BQ / "261_news_reaction_paper_book.sql"
F262 = BQ / "262_pending_qualification_queue_lane.sql"
PROJECT = "stock-trading-498512"

CREATE_RE = re.compile(
    r"^CREATE\s+(?:OR\s+REPLACE\s+)?(TABLE|VIEW)\s+(?:IF\s+NOT\s+EXISTS\s+)?"
    r"`stock-trading-498512\.([a-z_]+\.[a-z_]+)`",
    re.MULTILINE | re.IGNORECASE,
)


def read(path):
    return Path(path).read_text(encoding="utf-8")


def strip_line_comments(sql):
    return "\n".join(ln.split("--", 1)[0] for ln in sql.splitlines())


def statement_starting_at(sql, name):
    """Text of the statement whose CREATE line names `name`, up to its terminating semicolon."""
    m = re.search(r"^CREATE[^\n]*`" + re.escape(PROJECT + "." + name) + r"`", sql, re.MULTILINE)
    if not m:
        return ""
    end = sql.find(";", m.start())
    return sql[m.start():end if end != -1 else len(sql)]


class Test261(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = read(F261)
        cls.code = strip_line_comments(cls.sql)

    def test_defines_exactly_the_six_objects_in_order(self):
        found = [(k.upper(), n) for k, n in CREATE_RE.findall(self.code)]
        self.assertEqual(found, [
            ("TABLE", "ops.news_reaction_universe"),
            ("TABLE", "events.news_reaction_marks"),
            ("VIEW", "state.news_reaction_marks_curated"),
            ("TABLE", "events.news_reaction_calls"),
            ("VIEW", "state.news_reaction_call_returns"),
            ("VIEW", "state.news_reaction_paper_book_readiness"),
        ])

    def test_no_block_comments(self):
        self.assertNotIn("/*", self.sql)
        self.assertNotIn("*/", self.sql)

    def test_no_sql_standard_quote_escaping(self):
        self.assertNotIn("''", self.code)

    def test_seed_has_40_universe_rows_and_one_spy_benchmark(self):
        m = re.search(r"INSERT INTO `stock-trading-498512\.ops\.news_reaction_universe`(.*?);",
                      self.code, re.DOTALL)
        self.assertIsNotNone(m)
        seed = m.group(1)
        self.assertEqual(len(re.findall(r"'UNIVERSE'", seed)), 40)
        self.assertEqual(len(re.findall(r"'BENCHMARK'", seed)), 1)
        self.assertRegex(seed, r"STRUCT\('SPY',\s*'BENCHMARK'")
        tickers = re.findall(r"STRUCT\('([A-Z.]+)'", seed)
        self.assertEqual(len(tickers), 41)
        self.assertEqual(len(set(tickers)), 41)
        self.assertIn("WHERE NOT EXISTS", seed)
        self.assertIn("DATE '2026-10-20'", seed)

    def test_marks_curated_view_dedups_latest_ingest(self):
        body = statement_starting_at(self.code, "state.news_reaction_marks_curated")
        self.assertIn("PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC", body)

    def test_readiness_view_carries_preregistered_constants(self):
        body = statement_starting_at(self.code, "state.news_reaction_paper_book_readiness")
        self.assertRegex(body, r"\b0\.8 AS agreement_gate\b")
        self.assertRegex(body, r"\b0\.002 AS cost_round_trip\b")
        self.assertRegex(body, r"\b30 AS n_min\b")
        self.assertRegex(body, r"COALESCE\([^;]*FALSE\)\s+AS\s+ready\b")

    def test_calls_table_declares_every_not_null_column(self):
        body = statement_starting_at(self.code, "events.news_reaction_calls")
        for col in ("call_id", "call_ts", "call_date", "lead_id", "ticker", "headline_hash",
                    "headline", "source", "direction", "agreement_score", "k", "horizon_days",
                    "scorer_routine"):
            self.assertRegex(body, r"(?m)^\s*" + col + r"\s+[A-Z0-9]+[^\n,]*NOT NULL", col)
        for col in ("published_ts", "source_url", "votes_json", "scorer_session", "note"):
            line = re.search(r"(?m)^\s*" + col + r"\s+[^\n]*$", body)
            self.assertIsNotNone(line, col)
            self.assertNotIn("NOT NULL", line.group(0), col)

    def test_call_returns_has_no_correlated_subquery(self):
        body = statement_starting_at(self.code, "state.news_reaction_call_returns")
        self.assertTrue(body)
        # CTE heads ("name AS (SELECT") are fine; a subquery used as an expression is not.
        self.assertNotRegex(body, r"(?i)(?:[=<>,]|\bIN|\bEXISTS|\bSELECT)\s*\(\s*SELECT\b")
        self.assertIn("ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date)", body)
        for col in ("entry_date", "entry_open", "exit_date", "ret_1d", "ret_3d", "ret_5d",
                    "spy_ret_1d", "spy_ret_3d", "spy_ret_5d", "realized_return",
                    "realized_spy_return"):
            self.assertRegex(body, r"\b" + col + r"\b", col)


class Test262(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = read(F262)
        cls.code = strip_line_comments(cls.sql)

    def test_defines_exactly_one_view(self):
        self.assertEqual([n for _, n in CREATE_RE.findall(self.code)],
                         ["state.queue_venue_claim_unwired"])

    def test_allowed_map_has_six_lanes_with_qualification_to_sl1(self):
        m = re.search(r"allowed_map AS \((.*?)\n\),", self.code, re.DOTALL)
        self.assertIsNotNone(m)
        lanes = dict(re.findall(r"STRUCT\('([A-Z_]+)'\s+AS queue,\s*\[([^\]]*)\]", m.group(1)))
        self.assertEqual(set(lanes), {
            "PENDING_ANALYSIS", "PENDING_REVIEW", "PENDING_DRAFT", "PENDING_ROSTER",
            "PENDING_REGIME_REFRESH", "PENDING_QUALIFICATION"})
        self.assertEqual(lanes["PENDING_QUALIFICATION"].strip(), "'SL1'")
        self.assertEqual(lanes["PENDING_REGIME_REFRESH"].strip(), "'M1R'")

    def test_only_file_above_225_creating_the_view(self):
        hits = []
        for p in sorted(BQ.glob("*.sql")):
            num = re.match(r"(\d+)_", p.name)
            if not num or int(num.group(1)) <= 225:
                continue
            code = strip_line_comments(read(p))
            if re.search(r"CREATE\s+(OR\s+REPLACE\s+)?VIEW\s+`stock-trading-498512\.state\."
                         r"queue_venue_claim_unwired`", code):
                hits.append(p.name)
        self.assertEqual(hits, [F262.name])

    def test_body_carried_forward_from_225(self):
        def view_body(text):
            start = text.index("CREATE OR REPLACE VIEW `stock-trading-498512.state."
                               "queue_venue_claim_unwired`")
            end = text.index("\n  );\n", start)
            return text[start:end]

        old = view_body(read(BQ / "225_regime_refresh_queue_lane.sql"))
        new = view_body(self.sql)
        start = new.index("    STRUCT('PENDING_REGIME_REFRESH' AS queue, ['M1R'] AS allowed_drainers)")
        end = new.index("  ])\n),\ncandidates AS (")
        rebuilt = (new[:start]
                   + "    STRUCT('PENDING_REGIME_REFRESH' AS queue, ['M1R'] AS allowed_drainers)\n"
                   + new[end:])
        self.assertEqual(rebuilt, old)


class TestSupersededMarkers(unittest.TestCase):
    def test_each_prior_definition_points_at_262(self):
        for name in ("160_queue_venue_claim_detector.sql", "180_probe_register_queue_lane.sql",
                     "199_queue_venue_claim_status_normalisation.sql",
                     "225_regime_refresh_queue_lane.sql"):
            text = read(BQ / name)
            lines = text.splitlines()
            idx = next(i for i, ln in enumerate(lines)
                       if ln.startswith("CREATE OR REPLACE VIEW `stock-trading-498512.state."
                                        "queue_venue_claim_unwired`"))
            block, i = [], idx - 1
            while i >= 0 and (lines[i].strip().startswith("--") or not lines[i].strip()):
                block.append(lines[i])
                i -= 1
            block_text = "\n".join(block)
            self.assertIn("SUPERSEDED LIVE by bigquery/262_pending_qualification_queue_lane.sql",
                          block_text, name)

    def test_199_keeps_original_pointer_as_a_historical_note(self):
        # Append-only discipline: the 2026-09-05 pointer to 225 stays, demoted to a historical note
        # (scripts/check_superseded_markers.py forbids two stacked "SUPERSEDED LIVE by" claims).
        text = read(BQ / "199_queue_venue_claim_status_normalisation.sql")
        self.assertIn("Superseded (2026-09-05) by bigquery/225_regime_refresh_queue_lane.sql", text)
        self.assertEqual(text.count("SUPERSEDED LIVE by bigquery/2"), 1)


class TestContractsAndSources(unittest.TestCase):
    def test_handoff_contracts_entries(self):
        text = read(ROOT / "ops" / "handoff_contracts.yaml")
        self.assertRegex(text, r"- queue: PENDING_QUALIFICATION\n\s+terminal_status: complete\n"
                               r"\s+drainers: \[SL1\]\n\s+why:")
        for table in ("events.news_reaction_calls", "events.news_reaction_marks",
                      "ops.news_reaction_universe"):
            self.assertRegex(text, r"- table: " + re.escape(table) + r"\n\s+why: \S")

    def test_dbt_sources_declare_both_tables(self):
        text = read(ROOT / "dbt" / "models" / "sources.yml")
        self.assertRegex(text, r"(?m)^      - name: news_reaction_calls$")
        self.assertRegex(text, r"(?m)^      - name: news_reaction_marks$")


if __name__ == "__main__":
    unittest.main()

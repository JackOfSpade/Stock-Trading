"""Pins state.strategy_paper_regime_cells (bigquery/268) via scripts/paper_regime_cells.py on fixed vectors.

The vectors were also run through the live view body in BigQuery when bigquery/268 landed (2026-10-25). The
text guards below keep the canonical SQL on the carry-forward shape the reference implements.
"""

import importlib.util
import json
import math
import random
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_SPEC = importlib.util.spec_from_file_location("paper_regime_cells", ROOT / "scripts" / "paper_regime_cells.py")
prc = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(prc)

FIXTURE = ROOT / "tests" / "fixtures" / "paper_regime_cells_vectors.json"
with open(FIXTURE, encoding="utf-8") as _fh:
    CASES = {c["name"]: c for c in json.load(_fh)["cases"]}

CANONICAL_SQL = ROOT / "bigquery" / "268_paper_regime_cells_carry_forward.sql"


def _run(case):
    rows = [tuple(r) for r in case["paper"]]
    return prc.regime_cells(rows, case["series"])


class TestVectors(unittest.TestCase):
    def test_every_vector_matches(self):
        for name, case in CASES.items():
            with self.subTest(case=name):
                got = _run(case)
                want = {(e["strategy_code"], e["regime_cell"]): e for e in case["expected"]}
                self.assertEqual(set(got), set(want))
                for key, exp in want.items():
                    g = got[key]
                    self.assertEqual(g["paper_days_in_cell"], exp["paper_days_in_cell"])
                    self.assertEqual(g["unloggable_days"], exp["unloggable_days"])
                    self.assertEqual(g["demonstrated"], exp["demonstrated"])
                    if "cell_excess" in exp:
                        self.assertAlmostEqual(g["cell_excess"], exp["cell_excess"], places=9)

    def test_gap_day_loss_is_not_dropped(self):
        # The 267 defect: the fall from +3% to -5% on the cell-less day vanished and the cell read +6.25%.
        got = _run(CASES["gap_day_loss_is_carried"])[("X", "UP/LOW")]
        self.assertAlmostEqual(got["cell_excess"], -0.02, places=9)
        self.assertFalse(got["demonstrated"])


class TestCarryForwardInvariant(unittest.TestCase):
    def test_cells_compound_to_latest_kept_index(self):
        # Over any sequence, the product of every cell's (1 + cell_excess) equals 1 + the cumulative excess on
        # the last kept day: no change between kept days is lost, wherever the gaps fall.
        rng = random.Random(20261025)
        cells = ["UP/LOW", "UP/NORMAL", "NEUTRAL/NORMAL", None]
        for trial in range(200):
            excess, rows, series = 0.0, [], {}
            for i in range(rng.randint(1, 40)):
                day = f"2027-{1 + i // 28:02d}-{1 + i % 28:02d}"
                excess = (1 + excess) * (1 + rng.uniform(-0.03, 0.03)) - 1
                rows.append(("X", day, None if rng.random() < 0.1 else excess))
                series[day] = rng.choice(cells)
            kept = [e for d, e in [(r[1], r[2]) for r in rows] if e is not None and series[d] is not None]
            out = prc.regime_cells(rows, series)
            product = math.prod(1 + v["cell_excess"] for v in out.values())
            target = 1 + kept[-1] if kept else 1.0
            with self.subTest(trial=trial):
                self.assertAlmostEqual(product, target, places=9)


class TestCanonicalSqlShape(unittest.TestCase):
    def setUp(self):
        self.sql = CANONICAL_SQL.read_text(encoding="utf-8")

    def test_series_join_keeps_every_paper_day(self):
        self.assertRegex(self.sql, r"LEFT JOIN `stock-trading-498512\.state\.technical_regime_daily` t")

    def test_base_is_last_kept_day(self):
        self.assertIn("LAST_VALUE(IF(regime_cell IS NOT NULL, excess, NULL) IGNORE NULLS)", self.sql)
        # The 267 base (over every paper day) must not come back.
        self.assertIsNone(re.search(r"LAST_VALUE\(excess IGNORE NULLS\)", self.sql))

    def test_demonstrated_rule_matches_reference(self):
        self.assertIn(f"COUNT(*) >= {prc.MIN_DAYS} AND COUNTIF(log_rel_excess IS NULL) = 0 AND SUM(log_rel_excess) >= 0",
                      self.sql)


if __name__ == "__main__":
    unittest.main()

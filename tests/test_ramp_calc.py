"""Pins the LIVE_RAMP_DESIGN.md section 3.3 ramp algorithm (scripts/ramp_calc.py) on fixed vectors."""

import importlib.util
import json
import random
import unittest
from pathlib import Path
from typing import ClassVar

ROOT = Path(__file__).resolve().parent.parent
_SPEC = importlib.util.spec_from_file_location("ramp_calc", ROOT / "scripts" / "ramp_calc.py")
ramp_calc = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(ramp_calc)

FIXTURE = ROOT / "tests" / "fixtures" / "ramp_vectors.json"
with open(FIXTURE, encoding="utf-8") as _fh:
    CASES = {c["name"]: c for c in json.load(_fh)["cases"]}

FLOAT_FIELDS = ("score", "cum_llr")
EXACT_FIELDS = ("trades_n", "evidence_kill", "evidence_confirmed", "graduation_ready", "last_surprise_idx")
NAMED = (
    "ten_inline_wins",
    "nine_wins_one_loss",
    "surprise_halves",
    "second_surprise_floors",
    "overlap_discount",
    "no_edge_kills",
    "empty",
)


def _summary(case):
    path = ramp_calc.run_case(case)
    return path, ramp_calc.ramp_summary(path, case["params"]["opening_score"])


class FixtureCases(unittest.TestCase):
    def _check(self, name):
        case = CASES[name]
        _, got = _summary(case)
        exp = case["expected"]
        for f in FLOAT_FIELDS:
            self.assertAlmostEqual(got[f], exp[f], places=9, msg="%s.%s" % (name, f))
        for f in EXACT_FIELDS:
            self.assertEqual(got[f], exp[f], msg="%s.%s" % (name, f))
        return got

    def test_all_named_cases_present(self):
        for name in NAMED:
            self.assertIn(name, CASES)

    def test_every_fixture_case(self):
        for name in CASES:
            with self.subTest(case=name):
                self._check(name)

    def test_ten_inline_wins(self):
        got = self._check("ten_inline_wins")
        self.assertEqual(got["score"], 1.0)
        self.assertIs(got["graduation_ready"], True)

    def test_nine_wins_one_loss(self):
        got = self._check("nine_wins_one_loss")
        self.assertAlmostEqual(got["score"], 0.8, places=9)

    def test_surprise_halves(self):
        got = self._check("surprise_halves")
        self.assertAlmostEqual(got["score"], 0.35, places=9)
        self.assertEqual(got["last_surprise_idx"], 6)

    def test_second_surprise_floors(self):
        got = self._check("second_surprise_floors")
        self.assertEqual(got["score"], 0.0)
        self.assertEqual(got["last_surprise_idx"], 9)

    def test_overlap_discount(self):
        got = self._check("overlap_discount")
        self.assertAlmostEqual(got["score"], 0.3, places=9)
        path = ramp_calc.run_case(CASES["overlap_discount"])
        for row in path:
            self.assertEqual(row["n_overlap"], 2)
            self.assertAlmostEqual(row["w"], 1.0 / 3.0, places=9)

    def test_no_edge_kills(self):
        got = self._check("no_edge_kills")
        self.assertIs(got["evidence_kill"], True)
        self.assertLessEqual(got["cum_llr"], -1.5581)

    def test_empty(self):
        got = self._check("empty")
        self.assertEqual(got["score"], CASES["empty"]["params"]["opening_score"])
        self.assertEqual(got["trades_n"], 0)
        self.assertIsNone(got["last_surprise_idx"])


class ExplicitBehaviour(unittest.TestCase):
    TRADE: ClassVar[list[dict[str, object]]] = [
        {"key": "a", "entry_date": "2026-01-01", "exit_date": "2026-01-02", "r": 0.02}
    ]

    def test_validation_errors(self):
        bad = [
            {"mu": 0.0, "sigma": 0.06, "opening_score": 0.2},
            {"mu": -0.01, "sigma": 0.06, "opening_score": 0.2},
            {"mu": 0.02, "sigma": 0.0, "opening_score": 0.2},
            {"mu": 0.02, "sigma": 0.06, "opening_score": -0.1},
            {"mu": 0.02, "sigma": 0.06, "opening_score": 1.1},
            {"mu": 0.02, "sigma": 0.06, "opening_score": 0.2, "calibration_trades": 0},
            {"mu": 0.02, "sigma": 0.06, "opening_score": 0.2, "tail_loss_5pct": 0.0},
            {"mu": 0.02, "sigma": 0.06, "opening_score": 0.2, "tail_loss_5pct": 0.05},
        ]
        for kw in bad:
            with self.subTest(kw=kw):
                with self.assertRaises(ValueError):
                    ramp_calc.ramp_path(self.TRADE, **kw)
        with self.assertRaises(ValueError):
            ramp_calc.deployable_cap(0.5, 13000, 0)

    def test_ordering_independence(self):
        for name in ("second_surprise_floors", "no_edge_kills"):
            case = CASES[name]
            base = ramp_calc.run_case(case)
            shuffled = dict(case)
            trades = list(case["trades"])
            random.Random(7).shuffle(trades)
            self.assertNotEqual([t["key"] for t in trades], [t["key"] for t in case["trades"]])
            shuffled["trades"] = trades
            self.assertEqual(ramp_calc.run_case(shuffled), base)

    def test_overlap_counts_match_closed_interval_reference(self):
        rng = random.Random(821)
        trades = []
        for n in range(250):
            entry = rng.randrange(1, 24)
            exit_day = rng.randrange(entry, 29)
            trades.append({"key": str(n), "entry_date": f"2026-01-{entry:02d}",
                           "exit_date": f"2026-01-{exit_day:02d}", "r": 0.02})
        by_key = {t["key"]: t for t in trades}
        path = ramp_calc.ramp_path(trades, mu=0.02, sigma=0.06, opening_score=0.2)
        for row in path:
            t = by_key[row["key"]]
            expected = sum(other["entry_date"] <= t["exit_date"] and t["entry_date"] <= other["exit_date"]
                           for other in trades) - 1
            self.assertEqual(row["n_overlap"], expected)

    def test_inverted_trade_dates_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "entry_date"):
            ramp_calc.ramp_path([dict(self.TRADE[0], entry_date="2026-01-03")],
                                mu=0.02, sigma=0.06, opening_score=0.2)

    def test_increment_clip_on_huge_win(self):
        trades = [{"key": "w", "entry_date": "2026-01-01", "exit_date": "2026-01-02", "r": 0.5}]
        path = ramp_calc.ramp_path(trades, mu=0.02, sigma=0.06, opening_score=0.2)
        self.assertAlmostEqual(path[0]["inc"], 0.15, places=9)
        self.assertAlmostEqual(path[0]["score_after"], 0.35, places=9)
        self.assertIs(path[0]["surprise"], False)

    def test_increment_clip_on_huge_non_surprise_loss(self):
        trades = [{"key": "l", "entry_date": "2026-01-01", "exit_date": "2026-01-02", "r": -0.5}]
        path = ramp_calc.ramp_path(trades, mu=0.02, sigma=0.06, opening_score=0.9, tail_loss_5pct=-0.90)
        self.assertIs(path[0]["surprise"], False)
        self.assertAlmostEqual(path[0]["inc"], -0.5, places=9)
        self.assertAlmostEqual(path[0]["score_after"], 0.4, places=9)

    def test_deployable_cap_todays_book(self):
        got = ramp_calc.deployable_cap(0.5, 13000, 5)
        self.assertAlmostEqual(got["floor_usd"], 2000.0, places=6)
        self.assertAlmostEqual(got["full_usd"], 2600.0, places=6)
        self.assertAlmostEqual(got["cap_usd"], 2300.0, places=6)

    def test_deployable_cap_nav_relative_floor(self):
        got = ramp_calc.deployable_cap(0.0, 200000, 5)
        self.assertAlmostEqual(got["floor_usd"], 4000.0, places=6)
        self.assertAlmostEqual(got["cap_usd"], 4000.0, places=6)

    def test_defaults(self):
        self.assertEqual(
            ramp_calc.DEFAULTS,
            {
                "calibration_trades": 10,
                "loss_asymmetry": 2.0,
                "surprise_cut": 0.5,
                "surprise_window_trades": 5,
                "sprt_alpha": 0.05,
                "sprt_beta": 0.20,
            },
        )


if __name__ == "__main__":
    unittest.main()

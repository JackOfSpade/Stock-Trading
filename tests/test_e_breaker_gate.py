"""Offline tests for ops/research/e_breaker_2026-11/replay_gate.py (synthetic in-memory data only)."""
import importlib.util
from pathlib import Path

import pytest

_PATH = Path(__file__).resolve().parent.parent / "ops" / "research" / "e_breaker_2026-11" / "replay_gate.py"
_spec = importlib.util.spec_from_file_location("e_breaker_replay_gate", _PATH)
rg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rg)

MDATES = ["2020-01-31", "2020-02-28", "2020-03-31", "2020-04-30", "2020-05-29"]


def test_sticky_membership_keeps_then_drops():
    # A/B is >= 0.50 only at the first measurement; C/D never is; E/F is >= 0.50 at t but has no c60.
    series = {}
    for i, d in enumerate(MDATES):
        series[d] = {
            "A/B": (0.5, 0.60 if i == 0 else 0.40, None),
            "C/D": (0.5, 0.49, None),
            "E/F": (None, 0.80, None),
        }
    assert rg.population(series, MDATES, 0) == ["A/B"]
    assert rg.population(series, MDATES, 1) == ["A/B"]   # 1 month after
    assert rg.population(series, MDATES, 3) == ["A/B"]   # exactly 3 measurements after: still sticky
    assert rg.population(series, MDATES, 4) == []        # 4 measurements after: dropped
    # exactly 0.50 counts as in the floor population
    series2 = {MDATES[0]: {"G/H": (0.1, 0.50, None)}}
    assert rg.population(series2, MDATES, 0) == ["G/H"]


def test_distinct_ticker_group_floor():
    assert rg.distinct_tickers(["A/B", "A/C"]) == 3
    assert rg.group_ok(["A/B", "A/C"]) is True        # 2 pairs, 3 distinct tickers
    assert rg.group_ok(["A/B", "B/A"]) is False       # 2 pairs but only 2 distinct tickers
    assert rg.group_ok(["A/B"]) is False              # 1 pair
    assert rg.group_ok(["A/B", "C/D"]) is True        # 4 tickers


def test_pooling_to_four_digit_parent():
    gics = {
        "A/B": ("4010", "401010"),   # lone 6-digit group -> pooled
        "C/D": ("4010", "401020"),   # lone 6-digit group -> pooled with A/B into 4010
        "E/F": ("2510", "251010"),
        "E/G": ("2510", "251010"),   # 2 pairs, tickers E,F,G = 3 -> stays own group
        "H/I": ("3010", "301010"),   # pooled into 3010 but parent has 1 pair -> population only
        "J/K": ("2020", None),       # 4-digit-only, alone -> population only
        "L/M": (None, None),         # no codes -> population only
    }
    groups = rg.build_groups(sorted(gics), gics)
    assert groups == {"4010": ["A/B", "C/D"], "251010": ["E/F", "E/G"]}


def test_four_digit_only_pair_joins_parent_pool():
    gics = {"A/B": ("4010", "401010"), "C/D": ("4010", None)}
    assert rg.build_groups(["A/B", "C/D"], gics) == {"4010": ["A/B", "C/D"]}


def test_leg_h_threshold_is_inclusive():
    assert rg.leg_h({"g1": 0.5, "g2": 0.62}, 0.62) == (True, 0.62, "g2")
    assert rg.leg_h({"g1": 0.5, "g2": 0.62}, 0.63) == (False, 0.62, "g2")
    assert rg.leg_h({"g1": 0.62, "g2": 0.62}, 0.62)[2] == "g1"   # tie -> first key
    assert rg.leg_h({}, 0.62) == (True, None, None)              # cannot be computed -> tripped


def test_leg_l_pop_at_threshold():
    assert rg.leg_l_pop(2, 10, 0.2) == (True, 0.2)
    assert rg.leg_l_pop(1, 10, 0.2) == (False, 0.1)
    assert rg.leg_l_pop(0, 0, 0.2) == (True, None)


def test_leg_l_group_half_below():
    got = rg.leg_l_group({"a": (2, 4), "b": (1, 3), "c": (1, 2), "d": (0, 0), "e": (0, 2)})
    assert got == ["a", "c"]   # exactly half trips; 1 of 3 does not


def test_low_corr_is_strict_below_0_3():
    series = {MDATES[0]: {"A/B": (0.30, 0.9, None), "A/C": (0.2999, 0.9, None)}}
    gics = {"A/B": ("1010", "101010"), "A/C": ("1010", "101010")}
    stat = rg.compute_stat(series, MDATES, 0, gics, {})
    assert stat["low_count"] == 1
    assert stat["groups"]["101010"]["low"] == 1


def test_leg_a_missing_age_and_min_pairs():
    assert rg.leg_a(None, "2020-01-31", 50) is True
    assert rg.leg_a("2020-01-31", "2020-01-31", 20) is False
    assert rg.leg_a("2020-01-31", "2020-01-31", 19) is True
    assert rg.leg_a("2020-01-01", "2020-02-05", 50) is False   # age 35 days
    assert rg.leg_a("2020-01-01", "2020-02-06", 50) is True    # age 36 days


def test_percentile_rule_known_lists():
    assert rg.percentile90(list(range(1, 102))) == pytest.approx(91.0)
    assert rg.percentile90([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) == pytest.approx(9.1)
    assert rg.percentile90([]) is None
    stats = [{"date": "2018-01-05", "max_group_median": 0.99, "l_pop_share": 0.99},   # before start
             {"date": "2022-01-07", "max_group_median": 0.99, "l_pop_share": 0.99}]   # after end
    for k in range(1, 11):
        stats.append({"date": f"2019-01-{k:02d}", "max_group_median": k / 10, "l_pop_share": k / 100})
    th = rg.derive_thresholds(stats, "2018-06-01")
    assert th["T_H"] == 0.91
    assert th["S_L"] == 0.09
    assert th["n_calibration_months"] == 10


def test_blowout_hand_computed_strict():
    assert rg.blowout(0.5, -1.6) is True      # 1.6 - 0.5 = 1.1 > 1.0
    assert rg.blowout(0.5, 1.5) is False      # exactly 1.0 is not > 1.0
    assert rg.blowout(-2.0, 1.0) is False     # reconverging
    assert rg.blowout(None, 1.0) is None
    assert rg.blowout(1.0, None) is None


def test_outcome_excludes_pair_without_row_four_weeks_later():
    d0, d4 = "2020-01-03", "2020-01-31"   # exactly 4 ISO weeks apart
    series = {
        d0: {"A/B": (0.9, 0.8, 0.5), "C/D": (0.2, 0.7, 1.0), "E/F": (0.4, 0.6, 0.3)},
        d4: {"A/B": (0.9, 0.8, 1.6), "C/D": (0.9, 0.8, 2.0)},
    }
    lookup = rg.build_z_lookup(series)
    assert rg.pair_blowout(series, lookup, "A/B", d0) is True    # 1.6 - 0.5 = 1.1
    assert rg.pair_blowout(series, lookup, "C/D", d0) is False   # 2.0 - 1.0 = 1.0 exactly
    assert rg.pair_blowout(series, lookup, "E/F", d0) is None    # no row 4 weeks later
    stat = rg.compute_stat(series, [d0], 0, {}, lookup)
    assert stat["n_pairs"] == 3
    assert stat["pop_outcome"] == pytest.approx(0.5)             # 1 of 2 with an outcome
    assert stat["n_outcome"] == 2
    assert stat["low_count"] == 1
    assert stat["l_pop_share"] == pytest.approx(1 / 3)
    assert stat["pop_median_c60"] == pytest.approx(0.4)


def _stat(median, low, pairs=4, tickers=6, n_pairs=25, low_count=0, date="2020-01-31"):
    return {"date": date, "n_pairs": n_pairs, "pop_median_c60": 0.5, "low_count": low_count,
            "l_pop_share": low_count / n_pairs, "max_group_median": median,
            "groups": {"401010": {"pairs": pairs, "tickers": tickers, "median": median, "low": low,
                                  "outcome": None, "n_outcome": 0}},
            "pop_outcome": None, "n_outcome": 0, "measurement_present": True}


def test_evaluate_stat_legs():
    r = rg.evaluate_stat(_stat(0.70, 0), 0.70, 0.20)
    assert r["legs_tripped"] == "H" and r["breaker_tripped"] is True
    assert r["max_group"] == "401010"
    r = rg.evaluate_stat(_stat(0.69, 0), 0.70, 0.20)
    assert r["legs_tripped"] == "" and r["breaker_tripped"] is False
    r = rg.evaluate_stat(_stat(0.30, 2), 0.70, 0.20)          # 2 of 4 below 0.3 -> L-group
    assert r["legs_tripped"] == "L" and r["l_group_trips"] == "401010"
    r = rg.evaluate_stat(_stat(0.30, 0, low_count=5), 0.70, 0.20)   # 5/25 = 0.2 -> L-pop
    assert r["leg_l_pop"] is True and r["leg_l_group"] is False
    r = rg.evaluate_stat(_stat(0.30, 0, n_pairs=19), 0.70, 0.20)    # fewer than 20 pairs -> A
    assert r["legs_tripped"] == "A"
    assert r["leg_h"] is False and r["leg_l"] is False


def test_stress_flag_rules():
    assert rg.stress_flag(0.30, 0.30, []) is True
    assert rg.stress_flag(0.29, 0.30, []) is False
    assert rg.stress_flag(None, 0.30, []) is False
    assert rg.stress_flag(0.1, 0.30, [(3, 0.5)]) is True
    assert rg.stress_flag(0.1, 0.30, [(3, 0.49)]) is False
    assert rg.stress_flag(0.1, 0.30, [(2, 0.9)]) is False   # group below 3 distinct tickers


def test_monthly_dates_and_calibration_start():
    assert rg.monthly_dates(["2020-02-28", "2020-01-03", "2020-01-31", "2020-02-07"]) == \
        ["2020-01-31", "2020-02-28"]
    series = {"2019-01-04": {"A/B": (None, 0.9, None), "C/D": (None, None, None)},
              "2019-01-11": {"A/B": (None, 0.9, None), "C/D": (None, 0.1, None)}}
    assert rg.first_week_with_252(series, 2) == "2019-01-11"
    assert rg.first_week_with_252(series, 3) is None


def test_windows_inclusive():
    w = ("2023-03-01", "2023-05-31")
    assert rg.in_window("2023-03-01", w) and rg.in_window("2023-05-31", w)
    assert not rg.in_window("2023-02-28", w) and not rg.in_window("2023-06-01", w)
    assert len(rg.HELDOUT_WINDOWS) == 4 and len(rg.CALIBRATION_WINDOWS) == 2


def _recs(flags, **extra):
    return [dict({"date": f"2024-{i + 1:02d}-28", "breaker_tripped": f}, **extra) for i, f in enumerate(flags)]


def test_criterion_4_false_bind_fraction():
    at_40 = rg.criterion_4(_recs([True] * 4 + [False] * 6))
    assert at_40["pass"] is True
    assert at_40["evidence"]["false_bind_fraction"] == pytest.approx(0.4)
    assert at_40["evidence"]["n_tripped"] == 4 and at_40["evidence"]["n_months"] == 10
    above = rg.criterion_4(_recs([True] * 5 + [False] * 5))
    assert above["pass"] is False
    assert above["evidence"]["false_bind_fraction"] == pytest.approx(0.5)
    assert rg.criterion_4(_recs([True] * 2 + [False] * 3))["pass"] is True    # 2 of 5 = 40%
    assert rg.criterion_4(_recs([True] * 3 + [False] * 2))["pass"] is False   # 3 of 5 = 60%
    assert rg.criterion_4([])["pass"] is False


def test_criterion_3_lead_time_half():
    recs = [{"date": "d1", "stress": True, "breaker_tripped": True},
            {"date": "d2", "stress": True, "breaker_tripped": False},
            {"date": "d3", "stress": False, "breaker_tripped": True}]
    c = rg.criterion_3(recs)
    assert c["pass"] is True and c["evidence"]["n_stress_months"] == 2
    assert c["evidence"]["n_tripped_at_open"] == 1
    recs.append({"date": "d4", "stress": True, "breaker_tripped": False})
    assert rg.criterion_3(recs)["pass"] is False   # 1 of 3
    assert rg.criterion_3([])["pass"] is False


def test_criterion_5_discrimination():
    # binary fractions so the means are exact
    recs = [{"breaker_tripped": True, "pop_outcome": 0.5}, {"breaker_tripped": True, "pop_outcome": 0.25},
            {"breaker_tripped": False, "pop_outcome": 0.125}, {"breaker_tripped": False, "pop_outcome": 0.25},
            {"breaker_tripped": False, "pop_outcome": None}]
    c = rg.criterion_5(recs)
    assert c["evidence"]["mean_outcome_tripped"] == pytest.approx(0.375)
    assert c["evidence"]["mean_outcome_clear"] == pytest.approx(0.1875)
    assert c["evidence"]["n_clear_months"] == 2   # month without an outcome is excluded
    assert c["pass"] is True
    recs[2]["pop_outcome"] = 0.5   # clear mean becomes 0.375: equal -> not strictly greater
    assert rg.criterion_5(recs)["pass"] is False
    recs[2]["pop_outcome"] = 0.75  # clear mean 0.5 > 0.375
    assert rg.criterion_5(recs)["pass"] is False


def _bank_rec(date, bank_median, bank_low, pop_median, pop_share):
    return {"date": date, "pop_median_c60": pop_median, "l_pop_share": pop_share,
            "groups": {"401010": {"pairs": 4, "tickers": 6, "median": bank_median, "low": bank_low}}}


def test_criterion_2_banks_vs_population():
    w = ("2023-03-01", "2023-05-31")
    recs = [_bank_rec("2023-02-28", 0.9, 0, 0.5, 0.0),     # outside window, ignored
            _bank_rec("2023-03-31", 0.60, 1, 0.50, 0.05)]  # banks quiet
    assert rg.criterion_2(recs, w, 0.70, 0.20)["pass"] is False
    recs.append(_bank_rec("2023-04-28", 0.70, 0, 0.50, 0.05))   # banks H at exactly T_H, population quiet
    c = rg.criterion_2(recs, w, 0.70, 0.20)
    assert c["pass"] is True
    assert [m["date"] for m in c["evidence"]["months"]] == ["2023-03-31", "2023-04-28"]
    assert c["evidence"]["months"][1]["banks_median_c60"] == pytest.approx(0.70)
    # banks L-group trips (2 of 4 below 0.3) but population L-pop at S_L would trip alone -> not "local"
    recs2 = [_bank_rec("2023-03-31", 0.40, 2, 0.50, 0.20)]
    assert rg.criterion_2(recs2, w, 0.70, 0.20)["pass"] is False
    recs3 = [_bank_rec("2023-03-31", 0.40, 2, 0.50, 0.19)]
    assert rg.criterion_2(recs3, w, 0.70, 0.20)["pass"] is True
    # population median at T_H would trip on its own
    recs4 = [_bank_rec("2023-03-31", 0.80, 0, 0.70, 0.0)]
    assert rg.criterion_2(recs4, w, 0.70, 0.20)["pass"] is False


def test_criterion_1_substantive_trips_exclude_leg_a():
    cal = {"C1": ("2018-10-01", "2018-12-31"), "C2": ("2020-02-15", "2020-04-30")}
    held = {"H1": ("2022-01-01", "2022-01-31"), "H2": ("2023-01-01", "2023-01-31"),
            "H3": ("2024-01-01", "2024-01-31"), "H4": ("2025-01-01", "2025-01-31")}

    def rec(d, h=False, lo=False, a=False, computed=True):
        return {"date": d, "leg_h": h, "leg_l": lo, "leg_l_pop": lo, "leg_l_group": False, "leg_a": a,
                "max_group_median": 0.9 if computed else None,
                "l_pop_share": 0.2 if computed else None}

    recs = [rec("2018-11-30", h=True), rec("2020-03-31", lo=True), rec("2022-01-28", h=True),
            rec("2023-01-31", lo=True), rec("2024-01-31", a=True), rec("2025-01-31", h=True)]
    c = rg.criterion_1(recs, cal, held)
    assert c["pass"] is True and c["evidence"]["held_out_windows_hit"] == 3   # leg A alone does not count
    recs[5] = rec("2025-01-31", a=True)
    c = rg.criterion_1(recs, cal, held)
    assert c["pass"] is False and c["evidence"]["held_out_windows_hit"] == 2
    recs[5] = rec("2025-01-31", h=True)
    recs[0] = rec("2018-11-30", a=True)   # a calibration window without a substantive trip fails
    assert rg.criterion_1(recs, cal, held)["pass"] is False
    # a fail-closed H trip with no computed group statistic is not substantive
    recs[0] = rec("2018-11-30", h=True, computed=False)
    assert rg.criterion_1(recs, cal, held)["pass"] is False
    recs[0] = rec("2018-11-30", h=True)
    assert rg.criterion_1(recs, cal, held)["pass"] is True

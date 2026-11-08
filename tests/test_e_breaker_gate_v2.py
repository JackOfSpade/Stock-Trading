"""Offline tests for ops/research/e_breaker_2026-11/replay_gate_v2.py (synthetic in-memory data only)."""
import importlib.util
import json
import tempfile
from datetime import date, timedelta
from pathlib import Path

import pytest

_PATH = Path(__file__).resolve().parent.parent / "ops" / "research" / "e_breaker_2026-11" / "replay_gate_v2.py"
_spec = importlib.util.spec_from_file_location("e_breaker_replay_gate_v2", _PATH)
g2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(g2)


def weekly(n, start=date(2024, 1, 5)):
    return [(start + timedelta(weeks=k)).isoformat() for k in range(n)]


def test_widening_uses_pairs_own_row_four_rows_earlier():
    dates = weekly(8)
    # pair skips dates[2]; its own rows are d0,d1,d3,d4,d5,d6,d7. At d6 (own index 5) four earlier is d1.
    zs = {dates[0]: 9.0, dates[1]: 1.0, dates[3]: 2.0, dates[4]: 3.0, dates[5]: 4.0, dates[6]: -3.5,
          dates[7]: 5.0}
    series = {d: {"A/B": (0.5, 0.6, z)} for d, z in zs.items()}
    series[dates[2]] = {"C/D": (0.5, 0.6, 0.0)}
    pr = g2.build_pair_rows(series)
    assert g2.widening(pr, "A/B", dates[6]) == pytest.approx(3.5 - 1.0)
    # the global four-dates-earlier row (d2) does not exist for this pair; d1 is used, not d0/d2
    assert g2.widening(pr, "A/B", dates[3]) is None
    assert g2.widening(pr, "A/B", dates[5]) == pytest.approx(abs(4.0) - abs(9.0))


def test_sticky_population_twelve_weeks():
    dates = weekly(20)
    series = {}
    for i, d in enumerate(dates):
        series[d] = {"A/B": (0.5, 0.60 if i == 4 else 0.40, 1.0), "C/D": (0.5, 0.49, 1.0),
                     "E/F": (None, 0.80, 1.0)}
    pr = g2.build_pair_rows(series)
    assert g2.population(series, dates, 4, pr) == ["A/B"]
    assert g2.population(series, dates, 16, pr) == ["A/B"]     # exactly 12 weeks later: still in
    assert g2.population(series, dates, 17, pr) == []          # 13 weeks later: out
    assert g2.population(series, dates, 3, pr) == []           # before membership (and E/F has no c60)
    # needs z252 four rows earlier
    series2 = {d: {"A/B": (0.5, 0.6, None if k == 0 else 1.0)} for k, d in enumerate(dates[:8])}
    pr2 = g2.build_pair_rows(series2)
    assert g2.population(series2, dates[:8], 4, pr2) == []
    assert g2.population(series2, dates[:8], 5, pr2) == ["A/B"]


def test_leg_d_at_threshold_and_just_below():
    assert g2.leg_d({"x": 0.80, "y": 0.1}, 0.80)[0] is True
    assert g2.leg_d({"x": 0.7999, "y": 0.1}, 0.80)[0] is False
    trip, m, k = g2.leg_d({"b": 1.0, "a": 1.0}, 0.5)
    assert (trip, m, k) == (True, 1.0, "a")
    assert g2.leg_d({}, 0.5)[0] is True        # cannot compute -> tripped


def test_leg_dp_strict_and_share_floor():
    assert g2.dp_share([1.0, 1.0, 1.0, 1.0]) == pytest.approx(0.0)     # w == 1.0 is not > 1.0
    assert g2.dp_share([1.01, 1.0, 0.5, 2.0]) == pytest.approx(0.5)
    assert g2.leg_dp([1.01, 1.0, 0.5, 2.0], 0.5) == (True, pytest.approx(0.5))
    assert g2.leg_dp([1.01, 1.0, 0.5, 2.0], 0.51)[0] is False
    assert g2.leg_dp([], 0.5) == (True, None)


def test_leg_l_group_needs_two_low_and_half():
    assert g2.leg_l_group({"a": (1, 2)}) == []                  # 1 of 2 low: does NOT trip
    assert g2.leg_l_group({"a": (2, 4)}) == ["a"]               # exactly half, 2 low
    assert g2.leg_l_group({"a": (2, 5)}) == []                  # under half
    assert g2.leg_l_group({"a": (1, 1)}) == []
    assert g2.leg_l_group({"b": (3, 3), "a": (2, 3)}) == ["a", "b"]
    assert g2.leg_l_pop(1, 4, 0.25) == (True, pytest.approx(0.25))
    assert g2.leg_a(19) is True and g2.leg_a(20) is False and g2.leg_a(30, present=False) is True


def test_ninety_fifth_percentile_rule():
    values = list(range(1, 102))                                # 1..101
    assert g2.p95(values) == pytest.approx(96.0)
    assert g2.p90(values) == pytest.approx(91.0)
    assert g2.quantile_cut([5.0], 94) == 5.0
    assert g2.quantile_cut([], 94) is None
    stats = [{"date": f"d{k}", "max_d": float(k), "dp_share": 0.1, "max_h": 0.5, "l_pop_share": 0.2,
              "blowout_share": float(k)} for k in range(1, 102)]
    thr = g2.derive_thresholds(stats)
    assert thr["T_D"] == 96.0 and thr["B90"] == pytest.approx(91.0)
    assert thr["S_DP"] == 0.1 and thr["n_history_weeks"] == 101
    assert thr["history_start"] == "d1" and thr["history_end"] == "d101"


def test_forward_blowout_uses_row_four_rows_later():
    dates = weekly(8)
    # pair skips dates[1]: rows d0,d2,d3,d4,d5,d6,d7; four rows after d0 is d5.
    zs = {dates[0]: 0.5, dates[2]: 9.0, dates[3]: 9.0, dates[4]: 9.0, dates[5]: -1.6, dates[6]: 0.0,
          dates[7]: 0.0}
    series = {d: {"A/B": (0.5, 0.6, z)} for d, z in zs.items()}
    pr = g2.build_pair_rows(series)
    assert g2.pair_blowout(pr, "A/B", dates[0]) is True          # 1.6 - 0.5 = 1.1 > 1.0
    zs[dates[5]] = -1.5                                          # exactly 1.0: not strict >
    series = {d: {"A/B": (0.5, 0.6, z)} for d, z in zs.items()}
    assert g2.pair_blowout(g2.build_pair_rows(series), "A/B", dates[0]) is False
    assert g2.pair_blowout(pr, "A/B", dates[7]) is None          # no row four later


def test_stress_via_each_prong():
    assert g2.stress_flag(0.30, 0.30, []) is True                # share prong, exactly at B90
    assert g2.stress_flag(0.29, 0.30, []) is False
    assert g2.stress_flag(0.0, 0.30, [(3, 3, 2)]) is True        # 2 of 3 = two thirds
    assert g2.stress_flag(0.0, 0.30, [(3, 3, 1)]) is False
    assert g2.stress_flag(0.0, 0.30, [(2, 2, 2)]) is False       # group under 3 pairs
    assert g2.stress_flag(0.0, 0.30, [(3, 2, 2)]) is False       # 3-pair group, only 2 with an outcome
    assert g2.stress_flag(None, 0.30, [(6, 6, 4)]) is True


def _weeks(n, bound, stress_idx, bound_idx_extra=()):
    out = []
    for k in range(n):
        b = k in bound
        out.append({"breaker_tripped": b, "stress": k in stress_idx,
                    "blowout_share": 0.5 if b else 0.1})
    return out


def test_f1_inconclusive_with_25_weeks_or_2_stress():
    ok = g2.score_forward(_weeks(26, {0, 1, 2}, {0, 1, 2}))
    assert ok["F1"] is True and ok["overall"] == "PASS"
    short = g2.score_forward(_weeks(25, {0, 1, 2}, {0, 1, 2}))
    assert short["F1"] is False and short["overall"] == "INCONCLUSIVE"
    few = g2.score_forward(_weeks(30, {0, 1}, {0, 1}))
    assert few["F1"] is False and few["overall"] == "INCONCLUSIVE"


def test_f2_exactly_35_percent_passes_above_fails():
    at = g2.score_forward(_weeks(40, set(range(14)), {0, 1, 2}))      # 14/40 = 35%
    assert at["F2"] is True and at["overall"] == "PASS"
    above = g2.score_forward(_weeks(40, set(range(15)), {0, 1, 2}))   # 37.5%
    assert above["F2"] is False and above["overall"] == "FAIL"


def test_f3_f4():
    # 4 stress weeks, only 1 bound: F3 fails; 2 bound passes (half)
    assert g2.score_forward(_weeks(30, {0, 5}, {0, 1, 2, 3}))["F3"] is False
    assert g2.score_forward(_weeks(30, {0, 1}, {0, 1, 2, 3}))["F3"] is True
    flat = [{"breaker_tripped": k < 3, "stress": k < 3, "blowout_share": 0.25} for k in range(30)]
    r = g2.score_forward(flat)
    assert r["F4"] is False and r["overall"] == "FAIL"        # equal means: not strictly greater
    assert r["mean_blowout_bound"] == pytest.approx(0.25)


def test_forward_weeks_filter():
    recs = [{"date": "2026-11-06", "blowout_share": 0.1}, {"date": "2026-11-13", "blowout_share": 0.2},
            {"date": "2026-11-20", "blowout_share": None}, {"date": "2028-01-07", "blowout_share": 0.3}]
    got = g2.forward_weeks(recs, "2027-06-07")
    assert [r["date"] for r in got] == ["2026-11-13"]


def _row(d, pair, c60="0.6", c252="0.8", z="0.5"):
    return {"date": d, "pair": pair, "c60": c60, "c252": c252, "z252": z}


def test_as_of_malformed_rejected():
    with tempfile.TemporaryDirectory() as tmp:
        for bad in ("2027/06/07", "20270607", "tomorrow", "2027-13-01"):
            rc = g2.main(["forward", "--series", str(Path(tmp) / "none.csv"), "--as-of", bad,
                          "--results-dir", tmp], today=date(2027, 7, 1))
            assert rc == 2
        assert list(Path(tmp).iterdir()) == []


def _cli_setup(tmp, rows=None, digest=None):
    tmp = Path(tmp)
    rows = rows if rows is not None else [_row("2026-11-06", "A1/B1"), _row("2026-11-13", "A1/B1")]
    with open(tmp / "series.csv", "w", newline="") as fh:
        fh.write("date,pair,c60,c252,z252\n")
        for r in rows:
            fh.write(",".join((r["date"], r["pair"], r["c60"] or "", r["c252"] or "", r["z252"] or "")) + "\n")
    (tmp / "gics.csv").write_text("pair,gics_industry_group_4digit,gics_industry_6digit\nA1/B1,1010,101010\n")
    rdir = tmp / "res"
    rdir.mkdir()
    thr = {"T_D": 1.0, "S_DP": 0.5, "T_H": 0.9, "S_L": 0.5, "B90": 0.9,
           "history_sha256": digest if digest is not None else g2.history_digest(rows)}
    (rdir / "thresholds.json").write_text(json.dumps(thr))
    return rdir, ["forward", "--series", str(tmp / "series.csv"), "--gics", str(tmp / "gics.csv"),
                  "--results-dir", str(rdir)]


def test_future_as_of_rejected_with_injected_today():
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp)
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 1)) == 2
        assert g2.main([*base, "--as-of", "2027-06-06"], today=date(2027, 6, 8)) == 2   # before 2027-06-07
        assert sorted(p.name for p in rdir.iterdir()) == ["thresholds.json"]


def test_peek_file_naming_and_log_append():
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp)
        for _ in range(2):
            assert g2.main([*base, "--as-of", "2027-06-07", "--peek"], today=date(2027, 6, 1)) == 0
        names = sorted(p.name for p in rdir.iterdir())
        assert names == ["peek_2027-06-07_1.json", "peek_2027-06-07_2.json", "scoring_log.jsonl",
                         "thresholds.json"]
        assert json.loads((rdir / "peek_2027-06-07_1.json").read_text())["peek"] is True
        log = g2.read_log(rdir)
        assert [e["kind"] for e in log] == ["peek", "peek"]
        # a peek is allowed at any date and does not count as a score
        assert g2.main([*base, "--as-of", "2026-11-20", "--peek"], today=date(2026, 11, 7)) == 0
        assert g2.score_refusal("2027-06-07", "2027-06-08", g2.read_log(rdir)) is None


def test_peek_without_thresholds_errors():
    with tempfile.TemporaryDirectory() as tmp:
        rc = g2.main(["forward", "--series", str(Path(tmp) / "none.csv"), "--as-of", "2027-06-06",
                      "--results-dir", tmp, "--peek"], today=date(2027, 7, 1))
        assert rc == 1
        assert not (Path(tmp) / "thresholds.json").exists()


def test_refusal_after_pass_or_fail_and_after_final_date():
    for verdict in ("PASS", "FAIL"):
        log = [{"kind": "score", "as_of": "2027-06-07", "overall": verdict}]
        assert g2.score_refusal("2027-12-06", "2028-01-01", log) is not None
    assert g2.score_refusal("2027-12-06", "2028-01-01", [{"kind": "peek", "as_of": "2027-06-07",
                                                           "overall": "PASS"}]) is None
    final = [{"kind": "score", "as_of": "2027-12-06", "overall": "INCONCLUSIVE"}]
    assert g2.score_refusal("2028-01-03", "2028-02-01", final) is not None
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp)
        g2.append_log(rdir, {"kind": "score", "as_of": "2027-06-07", "overall": "PASS"})
        assert g2.main([*base, "--as-of", "2027-09-06"], today=date(2027, 9, 7)) == 2
        assert not (rdir / "forward_2027-09-06.json").exists()


def test_inconclusive_schedule_and_no_overwrite():
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp)
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 8)) == 0
        out = rdir / "forward_2027-06-07.json"
        first = out.read_text()
        assert json.loads(first)["overall"] == "INCONCLUSIVE"
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 9)) == 2   # file exists
        assert out.read_text() == first
        assert g2.main([*base, "--as-of", "2027-06-14"], today=date(2027, 6, 15)) == 2  # before 2027-09-06
        assert g2.main([*base, "--as-of", "2027-09-06"], today=date(2027, 9, 7)) == 0
        assert g2.main([*base, "--as-of", "2027-10-01"], today=date(2027, 10, 2)) == 2  # before 2027-12-06
        assert g2.main([*base, "--as-of", "2027-12-06"], today=date(2027, 12, 6)) == 0
        assert g2.main([*base, "--as-of", "2028-01-03"], today=date(2028, 1, 4)) == 2   # closed
        log = g2.read_log(rdir)
        assert [e["as_of"] for e in log] == ["2027-06-07", "2027-09-06", "2027-12-06"]
        assert all(e["kind"] == "score" for e in log)
    with tempfile.TemporaryDirectory() as tmp:       # a pre-existing forward file is never overwritten
        rdir, base = _cli_setup(tmp)
        (rdir / "forward_2027-06-07.json").write_text("keep")
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 8)) == 2
        assert (rdir / "forward_2027-06-07.json").read_text() == "keep"
        assert not (rdir / "scoring_log.jsonl").exists()


def test_history_digest_mismatch_sets_history_revised():
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp)
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 8)) == 0
        assert json.loads((rdir / "forward_2027-06-07.json").read_text())["history_revised"] is False
    with tempfile.TemporaryDirectory() as tmp:
        rdir, base = _cli_setup(tmp, digest="0" * 64)
        assert g2.main([*base, "--as-of", "2027-06-07"], today=date(2027, 6, 8)) == 0
        res = json.loads((rdir / "forward_2027-06-07.json").read_text())
        assert res["history_revised"] is True and res["thresholds"]["T_D"] == 1.0
    # digest: canonical, order independent, ignores rows after 2026-11-06, sensitive to cell strings
    a = [_row("2026-11-06", "A1/B1"), _row("2026-10-30", "A1/B1")]
    assert g2.history_digest(a) == g2.history_digest(list(reversed(a)))
    assert g2.history_digest(a) == g2.history_digest([*a, _row("2026-11-13", "A1/B1")])
    assert g2.history_digest(a) != g2.history_digest([_row("2026-11-06", "A1/B1", z="0.50"), a[1]])


def test_no_recompute_option_and_thresholds_never_overwritten():
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "results_v2" / "thresholds.json"
        g2.write_thresholds(path, {"T_D": 1.0})
        with pytest.raises(FileExistsError):
            g2.write_thresholds(path, {"T_D": 2.0})
        assert '"T_D": 1.0' in path.read_text()
        assert g2.main(["insample", "--results-dir", str(path.parent), "--series", str(Path(tmp) / "x.csv")]) == 2
        with pytest.raises(SystemExit):
            g2.main(["insample", "--recompute", "--results-dir", str(path.parent)])
        assert '"T_D": 1.0' in path.read_text()


def test_truncation_row_after_as_of_cannot_change_outcome():
    dates = weekly(6)
    rows = [_row(d, "A1/B1", z=z) for d, z in zip(dates, ["0.5", "0.5", "0.5", "0.5", "0.5", "3.0"], strict=False)]
    full = g2.build_pair_rows(g2.build_series(rows))
    assert g2.pair_blowout(full, "A1/B1", dates[1]) is True
    cut = g2.build_pair_rows(g2.build_series(g2.truncate_rows(rows, dates[4], drop_week_of=dates[4])))
    assert g2.pair_blowout(cut, "A1/B1", dates[1]) is None      # t+4 row is later than as-of: no outcome
    assert [r["date"] for r in g2.truncate_rows(rows, dates[2])] == dates[:3]


def test_truncation_drops_unfinished_as_of_week():
    rows = [_row("2024-01-05", "A1/B1"), _row("2024-01-09", "A1/B1"), _row("2024-01-10", "C1/D1")]
    keep = lambda cutoff: [r["date"] for r in g2.truncate_rows(rows, cutoff, drop_week_of=cutoff)]  # noqa: E731
    assert keep("2024-01-10") == ["2024-01-05"]            # Wednesday: its week is unfinished
    assert keep("2024-01-12") == ["2024-01-05"]            # Friday: still dropped (literal rule)
    rows.append(_row("2024-01-12", "A1/B1"))
    assert keep("2024-01-13") == ["2024-01-05", "2024-01-09", "2024-01-10", "2024-01-12"]   # Saturday: kept
    assert [r["date"] for r in g2.truncate_rows(rows, "2024-01-10")] == ["2024-01-05", "2024-01-09",
                                                                         "2024-01-10"]


def test_week_keying_merges_off_day_row():
    rows = [_row("2024-01-04", "C1/D1"), _row("2024-01-05", "A1/B1"), _row("2024-01-12", "A1/B1"),
            _row("2024-01-11", "C1/D1")]
    series = g2.build_series(rows)
    assert sorted(series) == ["2024-01-05", "2024-01-12"]
    assert sorted(series["2024-01-05"]) == ["A1/B1", "C1/D1"]
    assert sorted(series["2024-01-12"]) == ["A1/B1", "C1/D1"]
    # ISO weeks, not seven-day gaps: Monday and the previous Friday are different weeks
    assert sorted(g2.build_series([_row("2024-01-05", "A1/B1"), _row("2024-01-08", "A1/B1")])) == [
        "2024-01-05", "2024-01-08"]


def test_non_finite_values_are_missing():
    series = g2.build_series([_row("2024-01-05", "A1/B1", c60="nan", c252="inf", z="-inf"),
                              _row("2024-01-05", "C1/D1", c60="0.5", c252="0.7", z="1e400")])
    assert series["2024-01-05"]["A1/B1"] == (None, None, None)
    assert series["2024-01-05"]["C1/D1"] == (0.5, 0.7, None)


def test_duplicate_week_pair_row_raises():
    with pytest.raises(ValueError):
        g2.build_series([_row("2024-01-04", "A1/B1"), _row("2024-01-05", "A1/B1")])
    with pytest.raises(ValueError):
        g2.build_series([_row("2024-01-05", "A1/B1"), _row("2024-01-05", "A1/B1")])


def _three_pair_week(third_has_outcome):
    dates = weekly(9)
    pairs = ["A1/B1", "C1/D1", "E1/F1"]
    series = {}
    for k, d in enumerate(dates):
        z = 3.0 if k == 8 else 0.0
        series[d] = {p: (0.6, 0.8, z) for p in pairs if third_has_outcome or p != "E1/F1" or k != 8}
    gics = dict.fromkeys(pairs, ("1010", "101010"))
    pr = g2.build_pair_rows(series)
    stat = g2.week_stat(series, dates, 4, gics, pr)
    thr = {"T_D": 99.0, "S_DP": 2.0, "T_H": 99.0, "S_L": 2.0, "B90": 1.5}
    return stat, g2.evaluate_week(stat, thr)


def test_stress_prong_two_needs_three_pairs_with_outcome():
    stat, ev = _three_pair_week(False)
    assert stat["groups"]["101010"]["pairs"] == 3 and stat["groups"]["101010"]["n_out"] == 2
    assert ev["stress"] is False                    # 2 of 2 blow out, but only two pairs have an outcome
    stat, ev = _three_pair_week(True)
    assert stat["groups"]["101010"]["n_out"] == 3 and ev["stress"] is True


def test_end_to_end_synthetic_legs_and_insample_checks():
    dates = []
    d = date(2019, 1, 4)
    while d <= date(2023, 8, 25):
        dates.append(d)
        d += timedelta(weeks=1)
    codes = ["401010", "201010", "151010", "251010", "351010", "451010", "501010", "551010"]
    pairs, gics = [], {}
    for gi, code in enumerate(codes):
        for j in range(3):
            p = f"A{gi}{j}/B{gi}{j}"
            pairs.append(p)
            gics[p] = (code[:4], code)
    covid_jump = date(2020, 3, 13)
    banks_jump = date(2023, 4, 7)
    lowc_from = date(2023, 6, 2)
    rows = []
    for d in dates:
        for p in pairs:
            gi = int(p[1])
            z, c60 = 0.5, 0.6
            if gi == 1 and d >= covid_jump and d < covid_jump + timedelta(weeks=6):
                z = 2.5
            if gi == 0 and d >= banks_jump:
                z = 3.0
            if gi == 2 and d >= lowc_from and p[2] in "01":      # 2 of 3 pairs with c60 < 0.3
                c60 = 0.2
            rows.append(_row(d.isoformat(), p, c60=repr(c60), c252="0.8", z=repr(z)))
    series = g2.build_series(rows)
    ds = sorted(series)
    pr = g2.build_pair_rows(series)
    stats = g2.week_stats(series, ds, gics, pr)
    thr = {"T_D": 1.0, "S_DP": 0.5, "T_H": 0.95, "S_L": 0.5, "B90": 0.9}
    recs = g2.records_with_banks(stats, thr)
    by = {r["date"]: r for r in recs}
    cov = by[covid_jump.isoformat()]
    assert cov["leg_d"] is True and cov["max_d_group"] == "201010" and "D" in cov["legs_tripped"].split(";")
    bnk = by[banks_jump.isoformat()]
    assert bnk["leg_d_banks"] is True and bnk["max_d_group"] == "401010"
    quiet = by[date(2022, 6, 3).isoformat()]
    assert quiet["breaker_tripped"] is False and quiet["legs_tripped"] == ""
    lw = by[(lowc_from + timedelta(weeks=1)).isoformat()]
    assert "L" in lw["legs_tripped"].split(";") and lw["l_group_trips"] == "151010"
    # stress: the banks group (3 pairs) blows out four weeks before the jump is visible in z
    assert by[(banks_jump - timedelta(weeks=4)).isoformat()]["stress"] is True
    checks = g2.insample_checks(recs)
    assert checks["S1"]["pass"] is True and checks["S2"]["pass"] is True
    assert checks["S2"]["banks_code"] == "401010"
    assert checks["S3"]["n_weeks"] == len(recs)

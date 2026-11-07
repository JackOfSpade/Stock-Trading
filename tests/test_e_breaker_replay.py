"""Offline tests for ops/research/e_breaker_2026-11/replay_data.py (no network)."""
import importlib.util
import math
from pathlib import Path

import pytest

_PATH = Path(__file__).resolve().parent.parent / "ops" / "research" / "e_breaker_2026-11" / "replay_data.py"
_spec = importlib.util.spec_from_file_location("e_breaker_replay_data", _PATH)
rd = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rd)


def test_pairs_constant():
    assert len(rd.PAIRS) == 76
    assert len(set(rd.PAIRS)) == 76
    assert all(p.count("/") == 1 for p in rd.PAIRS)
    assert rd.PAIRS[0] == "AAL/DAL"
    assert rd.PAIRS[-1] == "ZBH/SYK"


def test_pearson_perfect_positive():
    assert rd.pearson([1, 2, 3, 4], [10, 20, 30, 40]) == pytest.approx(1.0)


def test_pearson_perfect_negative():
    assert rd.pearson([1, 2, 3, 4], [8, 6, 4, 2]) == pytest.approx(-1.0)


def test_pearson_hand_computed():
    # mean x=3, mean y=4; Sxy=6, Sxx=10, Syy=6 -> 6/sqrt(60)
    r = rd.pearson([1, 2, 3, 4, 5], [2, 4, 5, 4, 5])
    assert r == pytest.approx(6 / math.sqrt(60))
    assert r == pytest.approx(0.7745966692, abs=1e-9)


def test_pearson_undefined_cases():
    assert rd.pearson([1, 1, 1], [1, 2, 3]) is None  # zero variance
    assert rd.pearson([1.0], [2.0]) is None
    with pytest.raises(ValueError):
        rd.pearson([1, 2], [1, 2, 3])


def test_trailing_window_refuses_short_window():
    vals = [1, 2, 3, 4, 5]
    assert rd.trailing_window(vals, 4, 5) == [1, 2, 3, 4, 5]
    assert rd.trailing_window(vals, 4, 3) == [3, 4, 5]
    assert rd.trailing_window(vals, 3, 5) is None  # only 4 values up to index 3
    assert rd.trailing_window(vals, 4, 6) is None
    assert rd.rolling_pearson(vals, vals, 3, 5) is None
    assert rd.rolling_pearson(vals, vals, 4, 5) == pytest.approx(1.0)
    with pytest.raises(ValueError):
        rd.trailing_window(vals, 4, 0)


def test_zscore_hand_computed():
    vals = [1, 2, 3, 4, 10]
    # window mean 4, squared deviations 9+4+1+0+36=50, sample var 12.5
    assert rd.trailing_zscore(vals, 4, 5) == pytest.approx(6 / math.sqrt(12.5))
    assert rd.trailing_zscore(vals, 4, 5) == pytest.approx(1.6970562748, abs=1e-9)
    # last 3 values [3,4,10]: mean 17/3, sample var 43/3 /... computed below
    mean = 17 / 3
    var = ((3 - mean) ** 2 + (4 - mean) ** 2 + (10 - mean) ** 2) / 2
    assert rd.trailing_zscore(vals, 4, 3) == pytest.approx((10 - mean) / math.sqrt(var))
    assert rd.trailing_zscore(vals, 3, 5) is None  # short window
    assert rd.trailing_zscore([5, 5, 5], 2, 3) is None  # zero spread


def test_log_returns():
    r = rd.log_returns([100.0, 110.0, 99.0])
    assert r == pytest.approx([math.log(1.1), math.log(0.9)])


def test_pair_stats_window_requirements():
    prices = [100.0 + i + (i % 3) for i in range(300)]
    dates = [f"d{i:03d}" for i in range(300)]
    st = rd.pair_stats_at(dates, prices, prices)
    assert st["d059"][0] is None  # only 59 returns
    assert st["d060"][0] == pytest.approx(1.0)
    assert st["d251"][1] is None  # only 251 returns
    assert st["d252"][1] == pytest.approx(1.0)
    assert st["d250"][2] is None  # only 251 spread levels
    # identical legs -> spread is identically zero -> zero stdev -> empty z
    assert st["d299"][2] is None


def test_iso_week_bucketing_across_year_boundary():
    # 2020-12-31 (Thu) and 2021-01-01 (Fri) both belong to ISO week 2020-W53.
    assert rd.iso_week_key("2020-12-31") == (2020, 53)
    assert rd.iso_week_key("2021-01-01") == (2020, 53)
    assert rd.iso_week_key("2021-01-04") == (2021, 1)
    assert rd.iso_week_key("2018-12-31") == (2019, 1)
    dates = ["2020-12-28", "2020-12-29", "2020-12-31", "2021-01-01",
             "2021-01-04", "2021-01-05"]
    assert rd.last_date_per_iso_week(dates) == ["2021-01-01", "2021-01-05"]
    # unsorted input still picks the max date in the week
    assert rd.last_date_per_iso_week(["2021-01-01", "2020-12-28"]) == ["2021-01-01"]


def test_parse_nasdaq_row():
    row = {"date": "11/06/2026", "close": "$1,234.56", "volume": "1,000",
           "open": "$1.00", "high": "$2.00", "low": "$0.50"}
    d, c = rd.parse_nasdaq_row(row)
    assert d == "2026-11-06"
    assert c == pytest.approx(1234.56)
    assert rd.parse_nasdaq_row({"date": "01/05/2016", "close": "N/A"}) is None
    assert rd.parse_nasdaq_row({"date": "garbage", "close": "$5.00"}) is None
    assert rd.parse_close("$12.30") == pytest.approx(12.30)
    assert rd.parse_close("N/A") is None
    assert rd.parse_nasdaq_date("12/31/2020") == "2020-12-31"


def test_parse_nasdaq_payload_sorted_and_skips_na():
    payload = {"data": {"tradesTable": {"rows": [
        {"date": "01/05/2016", "close": "$20.50"},
        {"date": "01/04/2016", "close": "$19.00"},
        {"date": "01/06/2016", "close": "N/A"},
    ]}}}
    assert rd.parse_nasdaq_payload(payload) == [("2016-01-04", 19.0), ("2016-01-05", 20.5)]
    assert rd.parse_nasdaq_payload({"data": {"tradesTable": None}}) == []
    assert rd.parse_nasdaq_payload(None) == []


def test_coverage_status():
    assert rd.coverage_status(None, 0) == "fetch_failed"
    assert rd.coverage_status("2016-01-04", 2500) == "ok"
    assert rd.coverage_status("2017-01-01", 2500) == "ok"
    assert rd.coverage_status("2017-01-03", 2500) == "short_history"

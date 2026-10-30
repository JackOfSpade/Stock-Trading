"""Offline algorithm checks; research-only dependencies are optional in minimal CI."""
from pathlib import Path
import sys

import pytest

np = pytest.importorskip("numpy")
pd = pytest.importorskip("pandas")

from conftest import load_module_from_path  # noqa: E402

onset = load_module_from_path("shock_episode_tests", "scripts", "research", "shock_episode_event_study.py")
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts" / "research"))
nononset = load_module_from_path("shock_nononset_tests", "scripts", "research", "shock_nononset_event_study.py")


def test_second_hop_excludes_first_hop_etfs_and_basket_members(monkeypatch):
    monkeypatch.setattr(onset, "MIN_INDUSTRIES_PER_HOP", 1)
    monkeypatch.setattr(onset, "PROXIES", {"test": {"etf": "ETF", "basket": ["A", "B", "C", "D"]}})
    days = pd.bdate_range("2025-01-01", periods=300)
    returns = pd.DataFrame({"ETF": 0.9, "A": 0.8, "B": 0.1, "C": 0.2, "D": 0.3}, index=days)
    result, coverage, used, _ = onset.hop_return_series(
        returns, ["test"], {"ETF", "A"}, days[0], days[-1], "nasdaq", True)
    assert coverage["test"] == {"kind": "basket", "members": ["B", "C", "D"]}
    assert used == {"B", "C", "D"}
    np.testing.assert_allclose(result, 0.2)


def test_an_etf_is_counted_once_per_hop(monkeypatch):
    monkeypatch.setattr(onset, "MIN_INDUSTRIES_PER_HOP", 1)
    monkeypatch.setattr(onset, "PROXIES", {"a": {"etf": "ETF", "basket": []},
                                           "b": {"etf": "ETF", "basket": []}})
    days = pd.bdate_range("2025-01-01", periods=300)
    returns = pd.DataFrame({"ETF": 0.1}, index=days)
    _, coverage, _, per = onset.hop_return_series(
        returns, ["a", "b"], set(), days[0], days[-1], "nasdaq", True)
    assert coverage["a"]["kind"] == "etf"
    assert coverage["b"]["kind"] == "missing"
    assert set(per) == {"a"}


def test_beta_and_profiles_refuse_a_constant_market():
    days = pd.bdate_range("2024-01-01", periods=400)
    market = pd.Series(0.0, index=days)
    hop = pd.Series(0.01, index=days)
    assert onset.estimate_beta(hop, market, 300) is None
    assert onset.car_profile(hop, market, 300, days) is None
    assert nononset.partial_profile(hop, market, 300, days) is None


def test_full_and_partial_profiles_use_the_same_estimated_beta():
    days = pd.bdate_range("2024-01-01", periods=400)
    market = pd.Series(np.random.default_rng(8).normal(0, 0.01, len(days)), index=days)
    hop = 2 * market + 0.001
    full = onset.car_profile(hop, market, 300, days)
    partial = nononset.partial_profile(hop, market, 300, days)
    assert full["beta"] == pytest.approx(2)
    for key in ("beta", "d0", *(f"car_{h}w" for h in onset.HORIZONS_WEEKS)):
        assert partial[key] == pytest.approx(full[key])

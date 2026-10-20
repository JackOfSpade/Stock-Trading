"""Reference implementation of the live-ramp score algorithm (LIVE_RAMP_DESIGN.md section 3.3).

analytics.fn_ramp_path (the BigQuery JavaScript UDF in bigquery/259_live_ramp.sql) must produce
identical results; tests/fixtures/ramp_vectors.json is the shared contract between the two.

Standard library only. Usage: python3 scripts/ramp_calc.py tests/fixtures/ramp_vectors.json
"""

import json
import math
import sys

DEFAULTS = {
    "calibration_trades": 10,
    "loss_asymmetry": 2.0,
    "surprise_cut": 0.5,
    "surprise_window_trades": 5,
    "sprt_alpha": 0.05,
    "sprt_beta": 0.20,
}

_PLACES = 10


def _rd(x):
    return round(float(x), _PLACES)


def _order_key(t):
    return (t["exit_date"], t["entry_date"], t.get("key") or "")


def ramp_path(
    trades,
    mu,
    sigma,
    opening_score,
    tail_loss_5pct=None,
    calibration_trades=10,
    loss_asymmetry=2.0,
    surprise_cut=0.5,
    surprise_window_trades=5,
    sprt_alpha=0.05,
    sprt_beta=0.20,
):
    if mu <= 0:
        raise ValueError("mu must be > 0")
    if sigma <= 0:
        raise ValueError("sigma must be > 0")
    if opening_score < 0 or opening_score > 1:
        raise ValueError("opening_score must be in [0, 1]")
    if calibration_trades <= 0:
        raise ValueError("calibration_trades must be > 0")
    if tail_loss_5pct is not None and tail_loss_5pct >= 0:
        raise ValueError("tail_loss_5pct must be < 0")

    ordered = sorted(trades, key=_order_key)
    n = len(ordered)
    overlaps = []
    for a in range(n):
        ta = ordered[a]
        cnt = 0
        for b in range(n):
            if a == b:
                continue
            tb = ordered[b]
            if tb["entry_date"] <= ta["exit_date"] and ta["entry_date"] <= tb["exit_date"]:
                cnt += 1
        overlaps.append(cnt)

    if tail_loss_5pct is None:
        tail_loss_5pct = mu - 1.645 * sigma
    kill_bound = math.log(sprt_beta / (1.0 - sprt_alpha))
    confirm_bound = math.log((1.0 - sprt_beta) / sprt_alpha)

    s = float(opening_score)
    cum_llr = 0.0
    last_surprise = None
    out = []
    for i, t in enumerate(ordered, start=1):
        n_overlap = overlaps[i - 1]
        w = 1.0 / (1 + n_overlap)
        r = float(t["r"])
        llr = (r * mu - mu * mu / 2.0) / (sigma * sigma)
        cum_llr += llr
        if r <= tail_loss_5pct:
            surprise = True
            if last_surprise is not None and i - last_surprise <= surprise_window_trades:
                s = 0.0
            else:
                s = s * surprise_cut
            last_surprise = i
            inc = 0.0
        else:
            surprise = False
            raw = (r / mu) / calibration_trades
            if r < 0:
                raw *= loss_asymmetry
            inc = w * min(0.15, max(-0.5, raw))
            s = min(1.0, max(0.0, s + inc))
        evidence_kill = cum_llr <= kill_bound
        evidence_confirmed = cum_llr >= confirm_bound
        out.append(
            {
                "idx": i,
                "key": t.get("key"),
                "r": _rd(r),
                "w": _rd(w),
                "n_overlap": n_overlap,
                "llr": _rd(llr),
                "cum_llr": _rd(cum_llr),
                "surprise": bool(surprise),
                "inc": _rd(inc),
                "score_after": _rd(s),
                "evidence_kill": bool(evidence_kill),
                "evidence_confirmed": bool(evidence_confirmed),
            }
        )
    return out


def ramp_summary(path, opening_score):
    if path:
        last = path[-1]
        score = last["score_after"]
        cum_llr = last["cum_llr"]
        evidence_kill = last["evidence_kill"]
        evidence_confirmed = last["evidence_confirmed"]
    else:
        score = opening_score
        cum_llr = 0.0
        evidence_kill = False
        evidence_confirmed = False
    last_surprise_idx = None
    for row in path:
        if row["surprise"]:
            last_surprise_idx = row["idx"]
    return {
        "score": score,
        "trades_n": len(path),
        "cum_llr": cum_llr,
        "evidence_kill": evidence_kill,
        "evidence_confirmed": evidence_confirmed,
        "graduation_ready": score >= 1.0,
        "last_surprise_idx": last_surprise_idx,
    }


def deployable_cap(score, book_nav, active_count, floor_pct_nav=0.02, cost_min_usd=2000.0):
    if active_count <= 0:
        raise ValueError("active_count must be > 0")
    floor_usd = max(cost_min_usd, floor_pct_nav * book_nav)
    full_usd = book_nav / active_count
    cap_usd = floor_usd + score * max(0.0, full_usd - floor_usd)
    return {"floor_usd": floor_usd, "full_usd": full_usd, "cap_usd": cap_usd}


def run_case(case):
    p = case["params"]
    return ramp_path(
        case["trades"],
        mu=p["mu"],
        sigma=p["sigma"],
        opening_score=p["opening_score"],
        tail_loss_5pct=p.get("tail_loss_5pct"),
        calibration_trades=p.get("calibration_trades", DEFAULTS["calibration_trades"]),
        loss_asymmetry=p.get("loss_asymmetry", DEFAULTS["loss_asymmetry"]),
        surprise_cut=p.get("surprise_cut", DEFAULTS["surprise_cut"]),
        surprise_window_trades=p.get("surprise_window_trades", DEFAULTS["surprise_window_trades"]),
        sprt_alpha=p.get("sprt_alpha", DEFAULTS["sprt_alpha"]),
        sprt_beta=p.get("sprt_beta", DEFAULTS["sprt_beta"]),
    )


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        sys.stderr.write("usage: ramp_calc.py <fixture.json>\n")
        sys.exit(2)
    with open(argv[0], encoding="utf-8") as fh:
        fixture = json.load(fh)
    result = {}
    for case in fixture["cases"]:
        result[case["name"]] = run_case(case)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

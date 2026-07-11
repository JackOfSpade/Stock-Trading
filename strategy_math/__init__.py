"""
strategy_math — mechanical rule extraction for Strategies A, B, D, E
(self-improvement audit ITEM 28, 2026-07-11; finding "code-ify strategy mechanics").

Per each strategy's own "Classical-method delegation" section (strategy/03,04,06,07*.md)
and AI_Trading_Foundation.md's classical-method-delegation doctrine (2.11/2.12 — "all
numerical work goes to code, not AI reasoning") — this package is the same pattern
c_options_math.py already provides for Strategy C, extended to A/B/D/E.

SCOPE, DELIBERATELY NARROW: every function here implements a rule ALREADY WRITTEN in
the cited strategy .md section — a threshold, a formula, a date comparison. This module
invents NO new trading logic and makes NO entry/exit DECISIONS. The narrative judgment
that produces a thesis (is this catalyst real, is this narrative divergence genuine) stays
squarely in LLM reasoning — that IS the AI edge (AI_Trading_Foundation.md Part 1) and is
explicitly NOT candidate for code-ification. A routine calls these functions for the
numeric/mechanical gates a thesis must ALSO clear, exactly as it already calls
c_options_math.py for Strategy C's math.

Each strategy's locked machinery (this package's corresponding module + the strategy's
own strategy/0N_strategy_*.md slice) is content-hashed into strategy/roster.yaml's
`spec_hash` field once that strategy passes SHADOW entry (spec_locked_since) — verified
by scripts/check_roster_consistency.py check R-F. A change to either file after that
point is a drift, exactly like any other post-spec-lock machinery edit (Experiment_
Parameters.md's immutability doctrine) — it requires the strategy to terminate-and-
restart-as-new, not a silent in-place edit.

DESIGN CONSTRAINTS (mirrors c_options_math.py):
- Pure Python stdlib + math only (no numpy/scipy/pandas assumed available).
- All inputs explicit; no implicit "today" — callers pass dates/as_of explicitly.
- No I/O: no BigQuery, no IBKR connector calls. These are pure functions over
  numbers/dates a routine has already fetched. Test coverage is threshold-boundary
  synthetic cases (mirroring c_options_math.py's own test convention), not scraped
  historical fills — decision_log does not carry the underlying numeric inputs
  (market cap, ADV, correlation-at-entry) as clean structured columns, so a true
  historical-reproduction fixture set is not practically buildable from repo data.
"""

from . import common, strategy_a, strategy_b, strategy_d, strategy_e  # noqa: F401

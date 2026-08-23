-- ===== 197: state.price_level_criterion_drift — dividend drift on immutable price-LEVEL exits =====
-- (2026-08-23 — the mechanical half of the fix for W3's criterion_dividend_distortion, alert 070cc2f0.)
--
-- WHAT HAPPENED, and it is a real loss, not a near miss. B:MSCI:2026-07-27's invalidation criterion
-- (2) named "a fresh close below the 550.79 post-event trough". 550.79 was the 2026-07-24 CLOSING
-- LOW -- a CUM-DIVIDEND price. MSCI went ex-dividend 2.05 on 2026-08-14. The 2026-08-17 close of
-- 550.68 -- a POST-EX price -- was therefore read as a breach by 0.11 (0.020%) against a line that
-- was 2.05 (0.372%) too high for it: the distortion was 18.6x the breach margin. The economically
-- equivalent post-ex line is 548.74, and 550.68 sits 1.94 ABOVE it. On a like-for-like total-return
-- basis the criterion was NOT breached. D2 staged the exit on 2026-08-18 anyway and the position
-- closed at a realized -2.819387.
--
-- THE GENERIC FORM, which is why this is an object and not a note: ANY immutable price-LEVEL exit
-- test on a dividend-paying name drifts against its own economics on every ex-date thereafter --
-- always in the fire-earlier direction for a downside invalidation line, and in the never-fires
-- direction for an upside convergence target. The level is frozen at entry; the price series is not.
--
-- BLAST RADIUS -- MEASURED 2026-08-23 over ALL 18 positions that have ever carried an
-- invalidation_status, and it is NOT MSCI-only. The detector's actionable set --
-- `is_exit_criterion AND NOT likely_fundamental_context` -- resolves to exactly THREE genuine
-- price-level criteria, and all three are Strategy B: B:FTV:2026-07-29 (invalidation_3,
-- $58.22/$59.54), B:MSCI:2026-07-27 (invalidation_2, 550.79) and B:MTZ:2026-08-03 (invalidation_1,
-- 278.00). Zero false positives and zero false negatives against a hand-read of the corpus.
-- The three rows it flags but correctly EXCLUDES from that set are the reason both flags exist:
-- B:FTV invalidation_2 ("narrows/cuts the FY26 adj EPS guide below $2.95-3.05") is an EPS GUIDANCE
-- range, not a price -- caught by likely_fundamental_context; B:FTV not_exit_triggering ($98.65) and
-- D:DIS not_exit_triggering (45.00, a notional) are not criteria at all -- caught by is_exit_criterion.
-- SEPARATELY, and larger: `convergence_target` is a structured NUMERIC price level, is "immutable from
-- entry" (strategy/04_strategy_b.md:27), and 13 Strategy B positions have carried one.
--
-- WHAT IS EXPOSED *TODAY*, stated exactly so nobody reads more urgency into this than is there
-- (measured 2026-08-23): NOTHING. All 13 currently-open positions are Strategy D and every one of
-- their criteria is FUNDAMENTAL -- revenue growth, margins, backlog, guidance -- with no price level
-- among them; Strategy D is explicitly no-stop by design (D:RTX's draft price criterion "stock breaks
-- $130 on heavy volume" was DROPPED at entry for contradicting it). There are ZERO open Strategy B
-- positions, so all 13 convergence targets and all three price-level criteria sit on CLOSED positions.
-- This view therefore returns only the one benign D:DIS `not_exit_triggering` row today, and that is
-- the correct answer, not a broken detector.
--
-- SO WHY BUILD IT NOW: because "inert today" is a countdown, not a safety property. Every price-level
-- criterion in this book's entire history belongs to Strategy B, B is currently router
-- DO-NOT-ACTIVATE with ~0 NAV, and the moment B is re-capitalized the whole surface is live again --
-- 13 convergence targets plus every newly drafted criterion. The 2026-08-17 MSCI instance cost only
-- -2.82 because B was already capital-depleted; the identical defect on a funded position scales with
-- the position. The detector has to exist BEFORE the exposure returns, or it gets rediscovered the
-- same way this one was.
--
-- WHAT THIS FILE DOES *NOT* DO -- deliberately, and this is the load-bearing design constraint.
-- It does NOT rewrite, adjust, or override any criterion. `invalidation_status` is IMMUTABLE for the
-- life of the position (Claude_Task_Plan.md:590, strategy/03 + strategy/06 "immutable through the
-- position's life", strategy/04:27 for the convergence target), and Claude_Task_Plan.md:590's
-- "an omitted field is a destroyed field" rule makes any in-place edit a data-loss risk on top of a
-- doctrine violation. This view is an OBSERVATION layer: it surfaces the arithmetic -- the level, the
-- dividends that have accrued against it, and the economically equivalent adjusted level -- so the
-- routine that EVALUATES the criterion nets the dividend out at fire time. The criterion text stays
-- byte-identical forever; only the reading of it becomes dividend-aware.
--
-- WHY A VIEW AND NOT A PROSE RULE ALONE. W3 2026-08-17 DID catch this prospectively: it published the
-- pre-computed 548.74 line in Weekly_Position_Deep_Dive.md and wrote "if criterion 2 fires, W4/D2 must
-- net out the 2.05 before reading the breach as thesis deterioration". D2 staged the exit 6h56m later
-- and never saw it -- because Weekly_Position_Deep_Dive.md is not in D2's read-access scope
-- (Claude_Task_Plan.md:1896) and is not in D1's either, and because W3's disposition was HOLD, so
-- neither of W4's two delivery channels (a `weekly-thesis-action` recommendation or a
-- `WEEKLY-THESIS-ACTION` flag) was armed. The system had NO channel for a standing conditional
-- correction to reach the routine that later tests the criterion. A second prose note would have the
-- same fate; a queryable object in BigQuery is in every routine's read scope by default.
--
-- PRECEDENT: state.mark_discontinuity_watch (bigquery/92_park_allocator.sql:539) already nets a
-- same-day dividend out of a price delta before flagging a discontinuity -- the identical arithmetic,
-- applied to a different guard. This extends that idea to exit thresholds.
--
-- Additive -- new object, supersedes nothing.

CREATE OR REPLACE VIEW `stock-trading-498512.state.price_level_criterion_drift` AS
WITH open_pos AS (
  SELECT
    cp.position_key, cp.ticker, cp.strategy, cp.convergence_target, cp.invalidation_status,
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', SPLIT(cp.position_key, ':')[SAFE_OFFSET(2)]),
      DATE(cp.event_ts)
    ) AS entry_date
  FROM `stock-trading-498512.state.current_positions` cp
  WHERE cp.event_type <> 'CLOSE'
),
-- Flat `"key":value` pairs out of the invalidation_status JSON. The criteria are free-text prose under
-- arbitrary keys (invalidation_1..N, a_/b_/c_ variants, plus non-criterion keys such as
-- not_exit_triggering / provenance / verification_note), and JSON_VALUE cannot take a non-constant
-- path, so the pairs are extracted textually.
--
-- BOTH STRING- AND NUMBER-VALUED KEYS ARE CAPTURED (number arm added 2026-08-23 in review). The first
-- draft matched only string values on the reasoning that "a price level is always inside prose". That
-- is not a safe assumption about this book's own writers: D:GEV:2026-08-03 ALREADY stores
-- `invalidation_threshold_pct: 15` and `invalidation_consecutive_quarters: 2` as bare JSON numbers
-- under `invalidation_`-prefixed keys. A future criterion storing a price the same way would have
-- vanished from the detector entirely -- returning zero rows, indistinguishable from "no criterion",
-- and bypassing the price regex and the classifier alike. KNOWN RESIDUAL: a JSON ARRAY value is still
-- skipped (D:GEV's not_exit_triggering is one); arrays are not a criterion shape any writer uses for a
-- price level today, and widening to them would mean parsing nested JSON textually for no live gain.
pairs_str AS (
  SELECT
    op.*,
    REGEXP_EXTRACT(pair, r'^"([^"]+)":')      AS json_key,
    REGEXP_EXTRACT(pair, r'^"[^"]+":"(.*)"$') AS json_val
  FROM open_pos op,
  UNNEST(REGEXP_EXTRACT_ALL(TO_JSON_STRING(op.invalidation_status), r'"[a-zA-Z0-9_]+":"(?:[^"\\]|\\.)*"')) AS pair
),
pairs_num AS (
  SELECT
    op.*,
    REGEXP_EXTRACT(pair, r'^"([^"]+)":')                        AS json_key,
    REGEXP_EXTRACT(pair, r'^"[^"]+":(-?[0-9]+(?:\.[0-9]+)?)$')  AS json_val
  FROM open_pos op,
  UNNEST(REGEXP_EXTRACT_ALL(TO_JSON_STRING(op.invalidation_status), r'"[a-zA-Z0-9_]+":-?[0-9]+(?:\.[0-9]+)?')) AS pair
),
pairs AS (
  SELECT * FROM pairs_str
  UNION ALL
  SELECT * FROM pairs_num
),
-- PERCENTAGES ARE STRIPPED BEFORE EXTRACTION, NOT FILTERED AFTER (corrected 2026-08-23 in review).
-- The first draft gated the WHOLE value with a trailing `([^0-9%]|$)` guard and then extracted with a
-- LOOSE pattern. That leaks: once any genuine price admits the row, every other two-decimal number in
-- the same string is extracted too, percentages included -- "a move of 12.34% brings it below 56.78
-- support" would have emitted a spurious 12.34 price level. Removing `<number>%` tokens up front makes
-- the exclusion per-match instead of per-row, so the guard cannot be bypassed by co-occurrence.
scrubbed AS (
  SELECT p.*, REGEXP_REPLACE(p.json_val, r'[0-9]+(?:\.[0-9]+)?\s*%', ' ') AS scrubbed_val
  FROM pairs p
),
-- PRICE-LEVEL DETECTOR. A figure with EXACTLY two decimals, optional `$`, optional comma thousands.
-- Three corrections over the first draft, each of which was a silent miss or a silent wrong value:
--   * `{1,3}(?:,[0-9]{3})*` instead of `{2,5}` -- "$1,850.00" previously extracted as **850.00**, a
--     silently WRONG number rather than a miss, which is the worst failure mode available here;
--   * one integer digit is now allowed -- a sub-$10 level ("$9.75") previously matched nothing at all;
--   * percentages are scrubbed above rather than guarded here.
-- The two-decimal requirement still does the discriminating work against this corpus's
-- percentage-and-count thresholds ("<18%", "below 8% for 2 consecutive quarters", "-40bps",
-- "$7B run-rate", "$7.5B floor", "GM <55%"). A ROUND-NUMBER level ("stock breaks $130") is still NOT
-- matched, deliberately: loosening to bare integers re-admits "$2B damages", "$200B backlog" and every
-- other integer-dollar fundamental in the book. That gap is closed at the DRAFTING end instead --
-- Claude_Task_Plan.md's PRICE-LEVEL CRITERION DRAFTING RULE requires price levels to be written with a
-- `$` and two decimals -- which is the right place for a convention a regex cannot infer.
levels AS (
  SELECT
    s.position_key, s.ticker, s.strategy, s.entry_date, s.invalidation_status,
    'invalidation_status' AS criterion_source,
    s.json_key            AS criterion_key,
    SAFE_CAST(REPLACE(REPLACE(lvl, '$', ''), ',', '') AS NUMERIC) AS price_level,
    s.json_val            AS criterion_text,
    -- An actual exit test, as opposed to a key that merely mentions a number. `completion_criteri`
    -- is included (added 2026-08-23 in review): a completion criterion IS an exit trigger, and
    -- D:GEV/D:DIS both carry one, so omitting it would have under-reported the exit surface.
    REGEXP_CONTAINS(s.json_key, r'^(invalidation_|completion_criteri|[a-z]_)') AS is_exit_criterion,
    -- A two-decimal dollar figure in a FUNDAMENTAL sentence is not a price level. B:FTV's
    -- invalidation_2 is "narrows/cuts the FY26 adj EPS guide below $2.95-3.05" -- an EPS range that
    -- looks exactly like a sub-$10 share price to a regex. Netting a dividend out of an EPS threshold
    -- would be nonsense, so the reader needs this labelled rather than silently mixed in. Reported,
    -- never used to DROP a row: recall is the property that matters, since a missed price level is an
    -- undetected exposure while a labelled false positive costs one glance.
    REGEXP_CONTAINS(LOWER(s.json_val), r'(eps|guide|guidance|margin|revenue|arr\b|rpo|backlog|bps|notional|ebitda|cash flow|fcf|buyback)') AS likely_fundamental_context
  FROM scrubbed s,
  UNNEST(REGEXP_EXTRACT_ALL(s.scrubbed_val, r'\$?[0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}')) AS lvl

  UNION ALL

  -- The structured sibling: Strategy B's convergence_target is a NUMERIC price level, immutable from
  -- entry, and drifts the same way (an ex-date lowers the series, so an UPSIDE target recedes).
  SELECT
    op.position_key, op.ticker, op.strategy, op.entry_date, op.invalidation_status,
    'convergence_target' AS criterion_source,
    'convergence_target' AS criterion_key,
    op.convergence_target AS price_level,
    CAST(op.convergence_target AS STRING) AS criterion_text,
    TRUE  AS is_exit_criterion,
    FALSE AS likely_fundamental_context
  FROM open_pos op
  WHERE op.convergence_target IS NOT NULL
),
resolved AS (
  SELECT
    l.*,
    -- THE REFERENCE DATE IS THE FIELD THE SYSTEM DOES NOT YET RECORD, and its absence is the root
    -- cause. 550.79 was observed on 2026-07-24, three days BEFORE the 2026-07-27 entry, so entry_date
    -- is not a safe proxy -- it is a LOWER BOUND on the netting window. `price_level_ref_date` is the
    -- optional at-entry key the drafting rule now requires (Claude_Task_Plan.md, PRICE-LEVEL CRITERION
    -- DRAFTING RULE); when present it is authoritative, when absent this view says so rather than
    -- silently pretending entry_date is right.
    SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(l.invalidation_status, '$.price_level_ref_date')) IS NOT NULL
      AS reference_date_declared,
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(l.invalidation_status, '$.price_level_ref_date')),
      l.entry_date
    ) AS reference_date
  FROM levels l
)
SELECT
  r.position_key,
  r.ticker,
  r.strategy,
  r.criterion_source,
  r.criterion_key,
  r.is_exit_criterion,
  r.likely_fundamental_context,
  -- The one column a routine should filter on: a genuine, dividend-exposed price test.
  (r.is_exit_criterion AND NOT r.likely_fundamental_context) AS actionable_price_level,
  r.price_level,
  r.entry_date,
  r.reference_date,
  r.reference_date_declared,
  -- events.daily_marks stamps a cash dividend on its EX-DATE row (verified against MSCI's 2.05 on
  -- 2026-08-14). Netting window is (reference_date, today]. Correlated per row rather than joined
  -- back, which also removes the fan-out/drop risk a join on a non-unique (key, level) tuple carries.
  (SELECT IFNULL(SUM(dm.dividend), 0)
     FROM `stock-trading-498512.events.daily_marks` dm
    WHERE dm.ticker = r.ticker
      AND dm.mark_date > r.reference_date
      AND dm.mark_date <= CURRENT_DATE('America/Denver')) AS cum_dividend_since_reference,
  r.price_level - (SELECT IFNULL(SUM(dm.dividend), 0)
     FROM `stock-trading-498512.events.daily_marks` dm
    WHERE dm.ticker = r.ticker
      AND dm.mark_date > r.reference_date
      AND dm.mark_date <= CURRENT_DATE('America/Denver')) AS dividend_adjusted_level,
  -- COVERAGE HONESTY. events.daily_marks only covers tickers the book actually HELD, and only from
  -- 2026-04-17. If the first mark for this ticker post-dates the reference date, the sum above is
  -- INCOMPLETE and a zero means "not observed", never "no dividend was paid". B:MSCI is exactly this
  -- case: its reference date 2026-07-24 precedes its first MSCI mark on 2026-07-28. FMP's
  -- `calendar` / `dividends-calendar` endpoint (the date-range form, which is NOT plan-gated on this
  -- tier -- verified 2026-08-23, unlike `dividends-company` which IS) is the fallback for the
  -- uncovered head of the window.
  (SELECT MIN(dm.mark_date) FROM `stock-trading-498512.events.daily_marks` dm
    WHERE dm.ticker = r.ticker) AS first_mark_date,
  COALESCE((SELECT MIN(dm.mark_date) FROM `stock-trading-498512.events.daily_marks` dm
    WHERE dm.ticker = r.ticker) <= r.reference_date, FALSE) AS marks_cover_reference,
  ((SELECT IFNULL(SUM(dm.dividend), 0)
      FROM `stock-trading-498512.events.daily_marks` dm
     WHERE dm.ticker = r.ticker
       AND dm.mark_date > r.reference_date
       AND dm.mark_date <= CURRENT_DATE('America/Denver')) > 0) AS has_dividend_drift,
  r.criterion_text,
  CURRENT_TIMESTAMP() AS checked_at
FROM resolved r
ORDER BY r.position_key, r.criterion_source, r.criterion_key;

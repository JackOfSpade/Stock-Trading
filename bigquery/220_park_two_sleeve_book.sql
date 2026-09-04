-- 220_park_two_sleeve_book.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 2.
-- Project: stock-trading-498512. Generalizes the park book from ONE vehicle to TWO SLEEVES with a
-- defensive fraction f. Apply after 219.
--
-- SUPERSEDES the definitions of state.park_policy_current and state.park_position_current in
-- bigquery/92_park_allocator.sql (chain: 54 -> 92 -> 220). 92 keeps state.park_menu and everything
-- else it defines.
--
-- ============================ WHAT CHANGES, AND WHAT DELIBERATELY DOES NOT ======================
-- events.park_policy_changes gains THREE nullable columns — target_f_pct, risk_sleeve,
-- defensive_sleeve — by ALTER TABLE ADD COLUMN, which is additive and leaves every existing row
-- untouched. `vehicle` STAYS POPULATED and NOT-NULL-in-practice: dbt/models/sources.yml carries a
-- live not_null test on it, and D2 keeps writing it as the MAJORITY sleeve (tie at f=50 -> the RISK
-- sleeve wins, so a 50/50 book reads 'VOO'). Do not drop it.
--
-- LEGACY ROWS MAP CLEANLY, so no backfill is needed and DR replay is unaffected. A row with
-- target_f_pct IS NULL is a pre-v4 single-vehicle policy and means exactly what it always meant:
--   vehicle = 'VOO'  -> f = 0   (all risk sleeve)
--   vehicle = anything else -> f = 100, with that vehicle AS the defensive sleeve
-- That mapping is applied in the view below, never by rewriting history.
--
-- ============================ THE STRANDED-LEG DESTROYER, AND THE ONE-LINE FIX =================
-- The dangerous object in this whole migration is Operating_Protocols.md §13.E's stranded-leg rule:
-- "any park-book ticker that is NOT the current policy vehicle and is held above 0.0005 shares is a
-- stranded leg -- craft a full SELL". Under a two-sleeve book at 0<f<100, the SECOND sleeve matches
-- that predicate exactly, so D2a would liquidate half the book within one pass and re-craft the SELL
-- every session the tap was declined. That is not a theoretical risk: the backstop is persistent by
-- design, which is a feature everywhere else.
--
-- The fix is to redefine the flag rather than chase every consumer:
--     is_policy_vehicle := target_weight_pct > 0
-- Under a binary book this is byte-for-byte the old behaviour (one sleeve at 100, everything else at
-- 0). Under a graded book BOTH sleeves carry weight > 0, so both are policy vehicles and neither is
-- stranded — while a vehicle the book is genuinely leaving drops to weight 0 and is still swept. Every
-- existing consumer of is_policy_vehicle therefore becomes correct under two sleeves without being
-- edited, and the backstop keeps its persistence instead of being suppressed. is_target_sleeve and
-- target_weight_pct are added alongside for consumers that want the richer signal.
--
-- ============================ PHASE-2 SAFETY PIN (mechanical, not prose) ========================
-- Phase 2 lands the PLUMBING only; the ladder does not bind until Phase 3. The pin is enforced
-- MECHANICALLY rather than by an instruction nobody re-reads: state.park_policy_current exposes
-- `graded_enabled`, which is TRUE only once a schema-version marker row exists in
-- events.park_policy_changes (note LIKE 'PARK-V4-SCHEMA-VERSION%'). D2's PARK ALLOCATION CONVERSION
-- checklist REFUSES any target_f_pct outside {0,100} while graded_enabled is FALSE. BigQuery has no
-- CHECK constraints, so the guard lives in the checklist — but the FLAG is computed here, so the
-- checklist reads one boolean instead of re-deriving a condition it could get wrong.
--
-- CASH IS BARRED AS A FRACTIONAL SLEEVE (design doc §2.1). analytics.park_nav_daily's park_mv is
-- instrument-only, so a fractional CASH sleeve would make park TWR grade a book that does not exist.
-- CASH remains legal as a 100% degenerate policy. Asserted at the foot of this file.

ALTER TABLE `stock-trading-498512.events.park_policy_changes`
  ADD COLUMN IF NOT EXISTS target_f_pct INT64,
  ADD COLUMN IF NOT EXISTS risk_sleeve STRING,
  ADD COLUMN IF NOT EXISTS defensive_sleeve STRING;

-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_policy_current` AS
WITH latest AS (
  SELECT vehicle, effective_date, note, target_f_pct, risk_sleeve, defensive_sleeve
  FROM `stock-trading-498512.events.park_policy_changes`
  QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC) = 1
),
marker AS (
  SELECT COUNT(*) > 0 AS graded_enabled
  FROM `stock-trading-498512.events.park_policy_changes`
  WHERE note LIKE 'PARK-V4-SCHEMA-VERSION%'
)
SELECT
  l.vehicle,
  l.effective_date,
  l.note,
  -- Legacy rows carry no target_f_pct; they mean what they always meant.
  COALESCE(l.target_f_pct, IF(l.vehicle = 'VOO', 0, 100))            AS target_f_pct,
  COALESCE(l.risk_sleeve, 'VOO')                                     AS risk_sleeve,
  COALESCE(l.defensive_sleeve, IF(l.vehicle = 'VOO', 'SGOV', l.vehicle)) AS defensive_sleeve,
  m.graded_enabled
FROM latest l CROSS JOIN marker m;

-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_position_current` AS
WITH cur AS (
  SELECT risk_sleeve, defensive_sleeve, target_f_pct FROM `stock-trading-498512.state.park_policy_current`
),
-- The two sleeves and their TARGET weights. A sleeve at weight 0 is a vehicle the book is leaving.
targets AS (
  SELECT cur.risk_sleeve      AS ticker, 100 - cur.target_f_pct AS target_weight_pct FROM cur
  UNION ALL
  SELECT cur.defensive_sleeve AS ticker, cur.target_f_pct       AS target_weight_pct FROM cur
),
-- Collapse in case both sleeves name the same ticker (a degenerate but legal policy).
targets_dedup AS (
  SELECT ticker, SUM(target_weight_pct) AS target_weight_pct
  FROM targets GROUP BY ticker
),
sleeve_rows AS (
  SELECT
    t.ticker,
    COALESCE(pp.events_shares, 0)              AS events_shares,
    COALESCE(pp.buy_shares, 0)                 AS buy_shares,
    COALESCE(pp.sell_shares, 0)                AS sell_shares,
    COALESCE(pp.drip_shares, 0)                AS drip_shares,
    COALESCE(pp.events_park_net_cash, 0)       AS events_park_net_cash,
    COALESCE(pp.parking_commissions_total, 0)  AS parking_commissions_total,
    COALESCE(pp.parking_event_count, 0)        AS parking_event_count,
    pp.last_parking_date                       AS last_parking_date,
    t.target_weight_pct,
    TRUE                                       AS is_target_sleeve
  FROM targets_dedup t
  LEFT JOIN `stock-trading-498512.state.park_position` pp ON pp.ticker = t.ticker
),
-- Anything held above dust that is NOT a named sleeve. Under a binary book this is the old
-- residual_rows set exactly; under a graded book the second sleeve is NOT here, which is the point.
residual_rows AS (
  SELECT
    pp.ticker,
    pp.events_shares, pp.buy_shares, pp.sell_shares, pp.drip_shares,
    pp.events_park_net_cash, pp.parking_commissions_total, pp.parking_event_count, pp.last_parking_date,
    0   AS target_weight_pct,
    FALSE AS is_target_sleeve
  FROM `stock-trading-498512.state.park_position` pp
  WHERE ABS(pp.events_shares) > 0.0005
    AND pp.ticker NOT IN (SELECT ticker FROM targets_dedup)
)
SELECT
  ticker, events_shares, buy_shares, sell_shares, drip_shares,
  events_park_net_cash, parking_commissions_total, parking_event_count, last_parking_date,
  target_weight_pct,
  is_target_sleeve,
  -- COMPATIBILITY, AND THE STRANDED-LEG FIX IN ONE LINE. Every pre-v4 consumer reads this column and
  -- keeps working: under a binary book it is identical to the old flag, and under a graded book both
  -- weighted sleeves are policy vehicles so neither is treated as stranded.
  target_weight_pct > 0 AS is_policy_vehicle
FROM (
  SELECT * FROM sleeve_rows
  UNION ALL
  SELECT * FROM residual_rows
);

-- ============================ POST-CONDITIONS ==================================================
-- (1) Legacy mapping is correct on the live book: the current policy is VOO (effective 2026-09-03),
-- which under the legacy rule is f=0 with SGOV as the named defensive sleeve.
ASSERT (
  SELECT target_f_pct = 0 AND risk_sleeve = 'VOO' AND defensive_sleeve = 'SGOV'
  FROM `stock-trading-498512.state.park_policy_current`
) AS '220: legacy VOO policy must map to f=0 / VOO risk / SGOV defensive.';

-- (2) The Phase-2 pin is CLOSED until the schema-version marker lands.
ASSERT (
  SELECT NOT graded_enabled FROM `stock-trading-498512.state.park_policy_current`
) AS '220: graded_enabled must be FALSE until the PARK-V4-SCHEMA-VERSION marker row is written.';

-- (3) ANTI-MASK: no ticker the book actually holds above dust may be BOTH a weighted sleeve and
-- flagged stranded. This is the assertion that would have caught the two-sleeve destroyer.
ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.state.park_position_current`
  WHERE target_weight_pct > 0 AND NOT is_policy_vehicle
) AS '220: a weighted sleeve must never be flagged as a stranded leg.';

-- (4) CASH is barred as a fractional sleeve.
ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.state.park_policy_current`
  WHERE target_f_pct NOT IN (0, 100)
    AND 'CASH' IN (risk_sleeve, defensive_sleeve)
) AS '220: CASH may not be a sleeve at any 0<f<100 (park_mv is instrument-only).';

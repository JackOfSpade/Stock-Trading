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
-- PHASE 3 ACTIVATED 2026-09-04 by owner directive: the graded ladder now sizes LIVE idle capital.
-- The activation marker is in bigquery/221; the mechanical pin is state.park_policy_current.
-- graded_enabled. The Phase-1 framing below is RETAINED DELIBERATELY as the record of what was
-- measured BEFORE activation -- do not delete it, and do not read it as current scope.
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

-- ============================ STRUCTURAL INVARIANTS ===========================================
-- ORDERING IS LOAD-BEARING (fixed 2026-09-04). BigQuery aborts at the FIRST failing ASSERT, so the
-- replay-invariant structural checks must come BEFORE any dated receipt. They previously sat last,
-- underneath a receipt that had already gone false live (the Phase-2 pin, which asserted
-- NOT graded_enabled and was invalidated by the activation marker hours later) — which made every
-- structural check below it UNREACHABLE on every future apply. These four hold at EVERY point of an
-- apply-in-order rebuild, before and after activation.

-- (1) SLEEVE WEIGHTS MATCH THE POLICY. The defensive sleeve carries exactly target_f_pct and the risk
-- sleeve exactly its complement. THIS is the check that catches a sign error or a dropped UNION arm
-- in the weight assignment — the real two-sleeve destroyer class. The previous form of this
-- assertion compared target_weight_pct > 0 against is_policy_vehicle, which the view DEFINES three
-- lines apart as `target_weight_pct > 0 AS is_policy_vehicle`; it was tautological and passed 9-for-9
-- against a simulated sign error and a dropped UNION arm at f in {0,50,100}.
-- The `ticker != <other> sleeve` guards keep the DEGENERATE same-ticker policy (declared legal above,
-- and collapsed to one row by targets_dedup) from tripping this. Do NOT strengthen this to
-- COUNT(*) = 2 for the same reason: it would hard-fail a sanctioned migration.
ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.state.park_position_current` pos
  CROSS JOIN `stock-trading-498512.state.park_policy_current` pol
  WHERE (pos.ticker = pol.defensive_sleeve AND pos.ticker != pol.risk_sleeve
         AND pos.target_weight_pct != pol.target_f_pct)
     OR (pos.ticker = pol.risk_sleeve AND pos.ticker != pol.defensive_sleeve
         AND pos.target_weight_pct != 100 - pol.target_f_pct)
) AS '220: each named sleeve must carry exactly its policy weight.';

-- (2) The target sleeves partition the book exactly once.
ASSERT (
  SELECT SUM(target_weight_pct) = 100
  FROM `stock-trading-498512.state.park_position_current`
  WHERE is_target_sleeve
) AS '220: target sleeve weights must sum to 100.';

-- (3) CASH is barred as a fractional sleeve.
ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.state.park_policy_current`
  WHERE target_f_pct NOT IN (0, 100)
    AND 'CASH' IN (risk_sleeve, defensive_sleeve)
) AS '220: CASH may not be a sleeve at any 0<f<100 (park_mv is instrument-only).';

-- (4) THE PHASE PIN, AS A BICONDITIONAL rather than a dated state. graded_enabled must be TRUE if and
-- only if a schema-version marker row exists. This is the replay-invariant form of the old assert:
-- true BEFORE activation (no marker, pin closed) and true AFTER it (marker, pin open), so a DR
-- rebuild passes at both points instead of aborting the moment 221 lands.
ASSERT (
  SELECT p.graded_enabled = (
    SELECT COUNT(*) > 0 FROM `stock-trading-498512.events.park_policy_changes`
    WHERE note LIKE 'PARK-V4-SCHEMA-VERSION%')
  FROM `stock-trading-498512.state.park_policy_current` p
) AS '220: graded_enabled must be TRUE exactly when a PARK-V4-SCHEMA-VERSION marker row exists.';

-- ============================ POST-CONDITIONS (measured 2026-09-04) ============================
-- DATED RECEIPT, NOT AN INVARIANT — it pins the book as it stood at landing and is EXPECTED to go
-- false the first time the ladder actually moves f off 0. When that happens, RE-PIN it to the newly
-- measured values; do NOT delete it. It is deliberately LAST so it can never mask the four above.
-- (Same convention as dbt/tests/assert_wash_sale_allocation_invariants.sql's expiring pins.)
-- Legacy mapping on the live book: policy VOO effective 2026-09-03, which under the legacy rule
-- (target_f_pct IS NULL -> IF(vehicle='VOO', 0, 100)) is f=0 with SGOV as the named defensive sleeve.
ASSERT (
  SELECT target_f_pct = 0 AND risk_sleeve = 'VOO' AND defensive_sleeve = 'SGOV'
  FROM `stock-trading-498512.state.park_policy_current`
) AS '220: legacy VOO policy must map to f=0 / VOO risk / SGOV defensive (dated receipt).';

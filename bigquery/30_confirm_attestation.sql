-- Confirm-event attestation (self-improvement audit WO-5, 2026-07-03). Project: stock-trading-498512.
-- Apply after 01_schema.sql (state.open_orders) + 10_observability.sql (ops.sp_raise_alert_once).
--
-- WHY: Claude_Task_Plan.md's D3 already WALKS state.open_orders and repairs a missing confirm-order
-- calendar event in-session (create/repair the event, re-craft the instruction if needed) — but it wrote
-- no durable record that the check happened or what it found. Every other reconciliation loop in this
-- system (state.embedding_health, state.cadence_watch, state.go_without_order) writes a BigQuery
-- attestation precisely so absence-of-problem is independently verifiable rather than merely assumed
-- from a routine's own chat summary — this confirm-event-completeness check was the one loop without
-- one. A D3 session that crashed BEFORE reaching this step, or a Calendar-connector write that silently
-- failed, was otherwise invisible until the missed-confirmation hard-stop (Claude_Task_Plan.md D3) fires
-- DAYS later on an order that never got confirmed.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.confirm_event_snapshot` (
  snapshot_id STRING DEFAULT GENERATE_UUID(),
  snapshot_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  snapshot_date DATE NOT NULL,        -- operating day (America/Denver) this D3 run attested for
  item_key STRING NOT NULL,           -- state.open_orders.item_key
  ticker STRING,
  side STRING,
  entry_window_close DATE,
  confirm_event_found BOOL NOT NULL,
  calendar_event_id STRING,           -- the matched [Claude] Confirm order event id, if found
  repaired BOOL DEFAULT FALSE         -- TRUE if D3 had to create/repair the event this run
) PARTITION BY snapshot_date
OPTIONS(description='Daily D3 attestation: for each still-pending state.open_orders row, whether a matching [Claude] Confirm order calendar event was found (and whether D3 had to repair it this run). Self-improvement audit WO-5.');

-- Latest attestation per item_key.
CREATE OR REPLACE VIEW `stock-trading-498512.state.confirm_event_latest` AS
SELECT *
FROM `stock-trading-498512.ops.confirm_event_snapshot`
QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY snapshot_ts DESC) = 1;

-- state.staged_without_confirm — a pending staged order with either NO recent attestation (D3 has not
-- checked it in >30h, covering a skipped/failed D3 run) or an attestation that found no confirm event
-- (D3 checked and its own repair may itself have failed, e.g. a Calendar connector outage mid-run).
-- Self-bootstrapping (same philosophy as state.cadence_watch / state.stalled_runs): a row staged in the
-- last 30h is NEVER flagged here even with zero attestation history — it is simply too new for a D3
-- cycle to have reached it yet, which is expected, not a finding.
-- CRAFTABILITY SCOPING (2026-07-20, closes D3's 2026-07-19 confirm_event_gap finding 9dd23ed4): this
-- view predated the 2026-07-09 rescoping under which a CRAFTABLE order (equity/ETF/single-leg-options
-- instruction crafted via create_order_instruction) has NO confirm-order calendar event by design —
-- the instruction's own IBKR notification is its human confirm surface — so calendar attestation only
-- applies to NON-craftable (manual-entry) orders. The craftability marker is the recorded
-- payload.instruction_id (state.open_orders.instruction_id): a crafted order always records it at
-- staging (STAGING ATOMICITY gate), so its presence = craftable = exempt from calendar attestation.
-- Fail-closed on the interesting failure: a craft that never recorded an instruction_id (atomicity
-- breach, or a genuinely manual order) still flags here exactly as before. Liveness of the crafted
-- instruction itself is NOT this view's job — that is owned by D2a's registry reconciliation + D3's
-- instruction-verify/persist-and-wait re-craft (a DAY instruction expiring nightly is designed, not
-- drift).
CREATE OR REPLACE VIEW `stock-trading-498512.state.staged_without_confirm` AS
SELECT
  o.item_key, o.ticker, o.side, o.entry_window_close, o.staged_ts,
  c.snapshot_ts AS last_attested_ts,
  c.confirm_event_found,
  CASE
    WHEN c.snapshot_id IS NULL THEN 'never_attested'
    WHEN NOT c.confirm_event_found THEN 'confirm_event_missing'
    ELSE 'attestation_stale'
  END AS flag_reason
FROM `stock-trading-498512.state.open_orders` o
LEFT JOIN `stock-trading-498512.state.confirm_event_latest` c USING (item_key)
WHERE o.status = 'pending'
  AND o.instruction_id IS NULL   -- craftability scoping (2026-07-20): see header note above
  AND o.staged_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR)
  AND (c.snapshot_id IS NULL
       OR NOT c.confirm_event_found
       OR c.snapshot_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR));

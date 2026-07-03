-- NO-GO counterfactual shadow-tracking — makes the B taxonomy bidirectional (2026-07-03, self-
-- improvement audit S-3). Project: stock-trading-498512. Apply after 01_schema.sql (events.decision_log)
-- + 03_twr_engine.sql (state.daily_marks_curated).
--
-- PROBLEM: the B_Sub_Pattern_Taxonomy.md loop records ONLY avoided (NO-GO) trades and never checks
-- whether the avoided name actually underperformed — pure survivorship/confirmation-bias exposure. A
-- wrong NO-GO pattern (one that avoids names that then do fine) is never corrected because its
-- counterfactual outcome is never observed.
--
-- FIX: a shadow table logs a NO-GO's ticker + reference price at decision time; a LATER W5 cycle closes
-- it out by fetching the ticker's price after `horizon_days` and computing the EXCESS return vs SGOV
-- (self-improvement audit critique fix — NOT raw price: in a rising month most names go up on beta, so
-- raw-price "did it rise" would mislabel nearly every NO-GO as "wrong" regardless of the pattern's real
-- skill; excess-vs-SGOV isolates the stock-specific move from market direction, the same benchmark this
-- whole system already uses everywhere else). SGOV's own price is already event-sourced
-- (state.daily_marks_curated), so only the NO-GO'd ticker's price needs an external (FMP) fetch — done
-- by the W5 routine, never by this SQL layer, which only computes derived fields from whatever has been
-- written. Reported as raw X/Y tallies per sub-pattern, NEVER a p-value (small-sample discipline).

-- ===== events.nogo_shadow =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.nogo_shadow` (
  event_id STRING DEFAULT GENERATE_UUID(),
  logged_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  decision_log_entry_id STRING,     -- FK to the NO-GO's events.decision_log row
  ticker STRING NOT NULL,
  sub_pattern STRING,               -- the B_Sub_Pattern_Taxonomy.md category, if the NO-GO cites one
  nogo_date DATE NOT NULL,
  horizon_days INT64 DEFAULT 21,
  entry_ref_price NUMERIC,          -- ticker price at NO-GO time (FMP quote, written by W5)
  forward_price NUMERIC,            -- ticker price after horizon_days (NULL until W5 closes it out)
  forward_price_date DATE,
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY nogo_date
OPTIONS(description='Shadow-tracks NO-GO decisions: logged at decision time (ticker + entry price), closed out by W5 after horizon_days with a forward price. analytics.nogo_counterfactual computes excess return vs SGOV over the same window. Makes the B taxonomy bidirectional (self-improvement audit S-3).');

-- ===== analytics.nogo_counterfactual — per-shadow-row excess return vs SGOV =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual` AS
WITH sgov AS (
  SELECT mark_date, close FROM `stock-trading-498512.state.daily_marks_curated` WHERE ticker = 'SGOV'
)
SELECT
  s.event_id, s.decision_log_entry_id, s.ticker, s.sub_pattern, s.nogo_date, s.horizon_days,
  s.entry_ref_price, s.forward_price, s.forward_price_date,
  s.forward_price IS NOT NULL AS closed_out,
  sgov_entry.close AS sgov_ref_price,
  sgov_fwd.close AS sgov_forward_price,
  SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1 AS ticker_forward_return,
  SAFE_DIVIDE(sgov_fwd.close, sgov_entry.close) - 1 AS sgov_forward_return,
  (SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.close, sgov_entry.close) - 1) AS excess_return_vs_sgov,
  -- B is long-biased by construction (Strategy.md) -- for the dominant long-framed NO-GO, avoiding a
  -- name that then underperformed the SGOV park (excess <= 0) means the avoidance was directionally
  -- correct. A short-framed NO-GO would invert this reading; sub_pattern/note should flag that case for
  -- manual re-interpretation rather than trusting this column blindly.
  ((SAFE_DIVIDE(s.forward_price, s.entry_ref_price) - 1)
    - (SAFE_DIVIDE(sgov_fwd.close, sgov_entry.close) - 1)) <= 0 AS would_nogo_have_been_correct_long_framing
FROM `stock-trading-498512.events.nogo_shadow` s
LEFT JOIN sgov sgov_entry ON sgov_entry.mark_date = s.nogo_date
LEFT JOIN sgov sgov_fwd ON sgov_fwd.mark_date = s.forward_price_date;

-- ===== analytics.nogo_counterfactual_summary — per-sub-pattern raw tally (never a rate to act on) =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.nogo_counterfactual_summary` AS
SELECT
  COALESCE(sub_pattern, '(unclassified)') AS sub_pattern,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Directional-only flag; a below-chance tally is a candidate for a human taxonomy review, never an
  -- automatic demotion (small-sample multiple-testing risk across many sub-patterns).
  (COUNTIF(closed_out) >= 5) AS min_n_met
FROM `stock-trading-498512.analytics.nogo_counterfactual`
GROUP BY sub_pattern
ORDER BY n_shadowed DESC;

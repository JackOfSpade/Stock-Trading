-- ===== 263: state.shock_price_leg_status -- the shock rubric's price leg, measured per session, as a refresh trigger =====
-- (Rev 52, owner directive 2026-10-22, interactive session. Companion to the Strategy.md
-- `### Shock / overlay grading rubric` symmetry rewrite and the `### Pre-mortem: Regime router` Section 6
-- scenario-3 symmetric refresh landed in the same change.)
--
-- WHAT THIS IS FOR. Rev 52 makes the out-of-cycle fundamental refresh disjunctive in BOTH directions:
-- every de-risking trigger has a re-risking mirror, and ANY ONE trigger, either way, makes a refresh
-- permitted and required. One trigger pair is pure arithmetic on stored data, and this view is it:
--   shock_price_leg_entry -- the price leg turns ELEVATED while the standing shock_overlay is `latent`
--                            (only then: under `acute` the axis cannot rise further);
--   shock_price_leg_exit  -- the price leg turns NOT ELEVATED while the standing shock_overlay is
--                            `acute` only (review fix, Rev 52: under `latent` the price leg cannot
--                            lower the grade, so each trigger fires only where it can move it).
-- It reports the rubric's price leg once per BZUSD session from the structure anchor through the latest
-- mark, so a consumer reads a TRANSITION between two rows, never a level against a hand-copied number.
-- It is a TRIGGER PROXY and nothing more. The grade belongs to M1a (monthly) and M1R (out-of-cycle),
-- whose recorded baseline / peak / current triplet stays authoritative for the verdict; this view
-- grades nothing, writes nothing, and a refresh it triggers re-runs the blind scoring machinery.
--
-- WHICH RUNS FIRE (D2 applies this; Strategy.md scenario 3, review fix). A price-leg run is the unbroken
-- sequence of rows reading one half's condition. THE SCORER READ SESSION is the last BZUSD session
-- strictly before the latest shock_overlay scoring row's as_of_date (M1a or M1R) that was ALREADY STORED
-- when that scoring was written: its state.signal_marks_curated ingest_ts is at or before that row's
-- event_ts. Both halves bind. M1a fires before the open and can finish the next day (the as_of_date
-- 2026-10-01 row, written 2026-10-02, recorded current 98.03 for 2026-09-30), and a Sunday M1R
-- (13:00 UTC) cannot see Friday's close, which D2a ingests at about 22:40 UTC that Sunday. A restated
-- mark carries a later ingest_ts, so it can only move the read session earlier, toward firing.
-- (1) A run that began at or before the scorer read session was read by that scoring: under a standing
-- `acute` the EXIT re-arms 10 trading sessions after the scorer read session if that same run is still
-- going (gap (2) below; the re-arm costs at most one re-score per 10 sessions); otherwise (the entry
-- under `latent`) the run it read is answered and does not fire again. (2) ANY run that began after the
-- scorer read session fires at its start, including a new exit run that starts inside the 10-session
-- re-arm window after an earlier read run ended. Both triggers are REFRESH-ONLY: D2 logs them and D2a
-- queues the blind re-score; neither gets a same-evening router review or writes an activation.
--
-- ONE THRESHOLD, BOTH WAYS. `price_leg_elevated` <=> brent_peak > brent_baseline AND brent_close >=
-- brent_midpoint (baseline + 50% of the elevation) AND NOT plateau_band_holds. The same line serves the
-- way up and the way down. It replaces Rev 48's 50%-retrace downgrade leg and bigquery/224's leg (b)
-- retracement test, both of which only ever measured the way down.
--
-- ANCHOR. events.regime_events scope FUNDAMENTAL_AXIS key shock_overlay, deduped to one reading per
-- as_of_date with bigquery/01_schema.sql's ORDER BY event_ts DESC, event_id DESC tiebreaker (the same
-- dedup bigquery/224 uses, for the same reason: without it the run boundaries could move between query
-- runs). A blank value is a non-observation. Gaps and islands then find the current non-`none` run (an
-- open shock structure) and, inside it, the most recent `acute` run. `structure_anchor` is that acute
-- run's first as_of_date; if the open structure holds no `acute`, it is the start of the structure.
-- When the latest reading is `none` -- no structure open, so no price leg to read -- or there is no
-- reading at all, the view returns ZERO rows.
--
-- BASELINE. The median of the 60 BZUSD closes strictly before the anchor, or of all available closes if
-- fewer than 60 -- bigquery/224's convention, kept verbatim. Closes come from state.signal_marks_curated
-- (the deduped reader surface over bigquery/217's backfill), NEVER the raw events.signal_marks table,
-- and are restricted to state.market_calendar trading days so a 60-row window is 60 SESSIONS. With zero
-- baseline observations the view returns ZERO rows. An empty result therefore means the price leg
-- CANNOT BE READ; it is never a NOT ELEVATED reading, and a consumer must not treat it as one.
--
-- PLATEAU, PRICE HALF ONLY. The rubric's plateau re-base needs BOTH (a) all of Brent's trailing 10
-- closes within +/-5% of their own median and (b) no qualifying escalation event dated inside those 10
-- sessions. `plateau_median` and `plateau_obs` cover the trailing <= 10 rows including this one, computed
-- over the FULL curated series BEFORE rows are filtered to mark_date >= structure_anchor, so the first
-- rows after the anchor still see a full window. `plateau_band_holds` is TRUE only when plateau_obs = 10
-- AND the window's MIN >= 0.95 x plateau_median AND its MAX <= 1.05 x plateau_median. The stored series
-- is read as recorded: a front-month roll gap is not adjusted. A window PERCENTILE_CONT accepts no
-- frame, so the window is collected with ARRAY_AGG and its median taken over UNNEST, on a
-- single-relation source so the correlated subquery never sits over a JOIN.
--
-- NUMERIC THROUGHOUT. PERCENTILE_CONT(close, NUMERIC '0.5') returns NUMERIC where the FLOAT64 literal
-- 0.5 would return FLOAT64 (measured 2026-10-22), and the midpoint is computed as baseline +
-- (peak - baseline) / 2, so "at or above the midpoint" and the inclusive +/-5% band are exact decimal
-- comparisons, never float boundaries.
--
-- KNOWN PROXY GAPS -- read these before treating a row as the rubric's answer.
--   (1) ANCHOR. This view anchors at the start of the `acute` run. M1a anchors its baseline at the
--       FIRST QUALIFYING EVENT, a dated judgment no table records. The two disagree today: this view's
--       baseline is 84.73 over 43 sessions (anchor 2026-08-01), while the 2026-10-01 scoring recorded
--       87.20.
--   (2) PLATEAU EVENT HALF. Half (b) is not SQL-measurable, so the view applies half (a) alone and the
--       band holds at least as often as the rubric's re-base can fire. On any one session, under a
--       standing `acute`, that errs toward firing shock_price_leg_exit; a false positive costs one
--       blind re-score. It does NOT err that way over time: a re-score that HELD `acute` because a
--       qualifying event sat inside the plateau window leaves the exit serviced while the band keeps
--       holding, and when that event leaves the window the event half clears with no new price
--       signal for this view to show. So, while the standing value is `acute`, D2 RE-ARMS a
--       still-running exit 10 trading sessions after the scorer read session (WHICH RUNS FIRE above)
--       -- the re-arm costs at most one re-score per 10 sessions; it does not re-arm under `latent`,
--       where lowering needs a qualifying resolution event that D1 flags (Strategy.md
--       `### Pre-mortem: Regime router` Section 6 scenario 3, review fix). Under a standing `latent`,
--       the only case where the price half alone hides an entry the rubric would see -- a qualifying
--       event dated inside the window -- is the case D1's geopolitical_qualifying_event trigger
--       already fires on.
--   (3) A RE-BASE IS NOT PERSISTED. The band test is per row. When a window stops holding, the row
--       reverts to the anchor baseline, whereas a re-base the rubric actually fired holds the elevation
--       at zero until the next qualifying event. Under a standing `latent` that can fire a
--       shock_price_leg_entry the blind re-score then rejects (one re-score); under a standing `acute`
--       the band can flicker (measured below: band TRUE 2026-10-13..10-16, FALSE 2026-10-19..10-20,
--       TRUE 2026-10-21). Serviced-once semantics fire each run once; an exit run that restarts after a
--       flicker is a new run, and under WHICH RUNS FIRE above it fires at its start (one blind
--       re-score) when it began after the scorer read session, even inside the re-arm window.
--   (4) STALE ANCHOR UNDER `latent`. After an `acute` run gives way to `latent` inside the same open
--       structure, the view keeps that most recent `acute` run's anchor, and with it that run's
--       baseline and peak, where the rubric may since have re-based. An entry false positive this
--       causes costs one blind re-score, which rejects it; the trigger is refresh-only, so it writes
--       no activation in the meantime (Strategy.md scenario 3, review fix).
--
-- MEASURED OUTPUT ON THE DAY OF WRITING (2026-10-22, read-only against live data), for the record:
--   shock_overlay readings 2026-06-01 latent, 2026-07-01 latent, 2026-08-01 / 09-01 / 10-01 acute, so the
--   open structure starts 2026-06-01 and structure_anchor = 2026-08-01 (a Saturday; first row 2026-08-03).
--   brent_baseline 84.73 over 43 observations: the curated BZUSD series begins 2026-06-01, so the
--   60-session window is short by 17 and runs 2026-06-01..2026-07-31.
--   brent_peak 109.86 (2026-10-16), brent_midpoint 97.295.
--   2026-10-21: close 108.82; window 2026-10-08..2026-10-21, closes 104.28..109.86, plateau_median
--   106.125, band 100.81875..111.43125 holds -> basis 'plateau_band', price_leg_elevated FALSE.
--   2026-10-19 and 2026-10-20 read 'elevated': their windows still hold 2026-10-07's 100.20, below 95%
--   of the window median. The band also held 2026-08-21..2026-09-03 and 2026-10-13..2026-10-16;
--   2026-09-29 (96.16) is the only 'retraced' row; 2026-08-03..08-07 read 'no_elevation'.
--   Scorer read session (WHICH RUNS FIRE above; measured 2026-10-23, read-only): the latest scoring
--   (as_of_date 2026-10-01, written 2026-10-02) gives 2026-09-30; a simulated Sunday 2026-10-18 M1R
--   gives 2026-10-15 (Friday's close not yet stored); a simulated Monday 2026-10-19 M1R gives 2026-10-16.
--
-- CONSUMERS (two). (1) Claude_Task_Plan.md `## D2. Daily Action Conversion` item 4, the MEASURED
-- OUT-OF-CYCLE REFRESH TRIGGER bullet: its DETECT query reads this view for shock_price_leg_exit
-- (standing `acute` only) and shock_price_leg_entry (standing `latent` only), under WHICH RUNS
-- FIRE above. (2) `## W3. Open-Position Deep-Dive`, for reporting only: its MEASURE FROM THE GOVERNING
-- SURFACE paragraph reads this view as the mechanical price-leg proxy between scorings; it drives no
-- trigger and no grade. It succeeds state.rerisking_limb_status (bigquery/224), which Rev 52 retires:
-- that view stays defined live and is not dropped.
--
-- NO COLUMN IS NAMED `eligible`. `price_leg_elevated` is one leg of one axis, read on one session. It is
-- not a grade, it does not authorise any routine to score a fundamental axis, and it never authorises a
-- flip of anything.
--
-- APPLY: live via the BigQuery MCP after 262, together with the generated dbt mirror
-- (dbt/models/state/shock_price_leg_status.sql). Defines exactly one view and creates nothing else: no
-- table, no writer, no alert registration.

-- ===== state.shock_price_leg_status =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.shock_price_leg_status` AS
WITH shock_per_day AS (
  -- One shock_overlay reading per as_of_date. bigquery/01_schema.sql's tiebreaker.
  SELECT as_of_date, value
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope = 'FUNDAMENTAL_AXIS' AND key = 'shock_overlay'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY as_of_date
                             ORDER BY event_ts DESC, event_id DESC) = 1
),
shock_observed AS (
  -- A blank value is a non-observation, not a grade change (bigquery/224's guard, applied here).
  SELECT as_of_date, value, value = 'none' AS is_none
  FROM shock_per_day
  WHERE TRIM(COALESCE(value, '')) != ''
),
shock_seq AS (
  SELECT *,
         LAG(value)   OVER (ORDER BY as_of_date) AS prev_value,
         LAG(is_none) OVER (ORDER BY as_of_date) AS prev_is_none
  FROM shock_observed
),
shock_marked AS (
  -- Gaps and islands twice over: value_run_id breaks at every grade change, structure_run_id only
  -- at a none <-> non-none boundary. A structure boundary is always a grade change too, so every
  -- value run lies wholly inside one structure run.
  SELECT *,
         COUNTIF(prev_value IS NULL OR prev_value != value) OVER (
             ORDER BY as_of_date
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS value_run_id,
         COUNTIF(prev_is_none IS NULL OR prev_is_none != is_none) OVER (
             ORDER BY as_of_date
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS structure_run_id
  FROM shock_seq
),
shock_latest AS (
  SELECT value AS shock_overlay_state, is_none, structure_run_id
  FROM shock_marked
  QUALIFY ROW_NUMBER() OVER (ORDER BY as_of_date DESC) = 1
),
value_runs AS (
  SELECT value, value_run_id, structure_run_id, MIN(as_of_date) AS run_start
  FROM shock_marked
  GROUP BY value, value_run_id, structure_run_id
),
anchor AS (
  -- Zero rows when the latest reading is `none` (WHERE + GROUP BY over nothing) or when there is no
  -- reading at all. Otherwise: the start of the most recent `acute` run inside the current non-none
  -- run, else the start of that non-none run.
  SELECT
    sl.shock_overlay_state,
    COALESCE(MAX(IF(vr.value = 'acute', vr.run_start, NULL)), MIN(vr.run_start)) AS structure_anchor
  FROM shock_latest sl
  JOIN value_runs vr ON vr.structure_run_id = sl.structure_run_id
  WHERE NOT sl.is_none
  GROUP BY sl.shock_overlay_state
),
brent AS (
  -- Curated reader surface only, never the raw events.signal_marks table. Trading days only, so a
  -- 60-row window is 60 SESSIONS (bigquery/224's convention). A NULL close is not an observation.
  SELECT m.mark_date, m.close
  FROM `stock-trading-498512.state.signal_marks_curated` m
  JOIN `stock-trading-498512.state.market_calendar` c
    ON c.cal_date = m.mark_date AND c.is_trading_day
  WHERE m.ticker = 'BZUSD' AND m.close IS NOT NULL
),
brent_plateau AS (
  -- Trailing <=10-session window over the FULL series, BEFORE the anchor filter below, so the first
  -- rows after the anchor still see a full window.
  SELECT
    mark_date,
    close,
    ARRAY_AGG(close) OVER w AS plateau_closes,
    COUNT(*)         OVER w AS plateau_obs,
    MIN(close)       OVER w AS plateau_min,
    MAX(close)       OVER w AS plateau_max
  FROM brent
  WINDOW w AS (ORDER BY mark_date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
),
brent_plateau_median AS (
  -- A window PERCENTILE_CONT takes no frame, so the window is collected as an array and its median
  -- taken over UNNEST -- the same PERCENTILE_CONT the baseline uses. Kept on a single-relation
  -- source so the correlated subquery never sits over a JOIN.
  SELECT
    p.*,
    (SELECT PERCENTILE_CONT(x, NUMERIC '0.5') OVER () FROM UNNEST(p.plateau_closes) AS x LIMIT 1)
      AS plateau_median
  FROM brent_plateau p
),
baseline_window AS (
  SELECT b.mark_date, b.close
  FROM brent b
  CROSS JOIN anchor a
  WHERE b.mark_date < a.structure_anchor
  QUALIFY ROW_NUMBER() OVER (ORDER BY b.mark_date DESC) <= 60
),
baseline AS (
  -- One row always (an aggregate with no GROUP BY): brent_baseline_obs = 0 on an empty window, which
  -- the WHERE in `anchored` turns into zero output rows.
  SELECT ANY_VALUE(med) AS brent_baseline, COUNT(*) AS brent_baseline_obs
  FROM (SELECT PERCENTILE_CONT(close, NUMERIC '0.5') OVER () AS med FROM baseline_window)
),
anchored AS (
  -- WHERE runs before the window, so brent_peak is the running max from the anchor, not from the
  -- start of the series.
  SELECT
    p.mark_date,
    a.shock_overlay_state,
    a.structure_anchor,
    bl.brent_baseline,
    bl.brent_baseline_obs,
    p.close AS brent_close,
    MAX(p.close) OVER (ORDER BY p.mark_date
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS brent_peak,
    p.plateau_median,
    p.plateau_obs,
    p.plateau_min,
    p.plateau_max
  FROM brent_plateau_median p
  CROSS JOIN anchor a
  CROSS JOIN baseline bl
  WHERE p.mark_date >= a.structure_anchor AND bl.brent_baseline_obs > 0
),
scored AS (
  SELECT
    *,
    brent_baseline + (brent_peak - brent_baseline) / 2 AS brent_midpoint,
    COALESCE(plateau_obs = 10
               AND plateau_min >= NUMERIC '0.95' * plateau_median
               AND plateau_max <= NUMERIC '1.05' * plateau_median,
             FALSE)                                    AS plateau_band_holds
  FROM anchored
)
SELECT
  mark_date,
  shock_overlay_state,
  structure_anchor,
  brent_baseline,
  brent_baseline_obs,
  brent_close,
  brent_peak,
  brent_midpoint,
  plateau_median,
  plateau_obs,
  plateau_band_holds,
  brent_peak > brent_baseline AND brent_close >= brent_midpoint AND NOT plateau_band_holds
                                                       AS price_leg_elevated,
  CASE
    WHEN plateau_band_holds             THEN 'plateau_band'
    WHEN brent_peak <= brent_baseline   THEN 'no_elevation'
    WHEN brent_close >= brent_midpoint  THEN 'elevated'
    ELSE 'retraced'
  END                                                  AS basis
FROM scored
ORDER BY mark_date;

-- VERIFICATION (run after apply; read-only).
-- SELECT mark_date, shock_overlay_state, structure_anchor, brent_baseline, brent_baseline_obs,
--        brent_close, brent_peak, brent_midpoint, plateau_median, plateau_obs, plateau_band_holds,
--        price_leg_elevated, basis
-- FROM `stock-trading-498512.state.shock_price_leg_status` ORDER BY mark_date DESC LIMIT 15;
--   -- 2026-10-22 (Denver): structure_anchor 2026-08-01, brent_baseline 84.73 over 43 observations,
--   -- brent_peak 109.86, brent_midpoint 97.295 on every row from 2026-10-16. 2026-10-21 reads
--   -- plateau_median 106.125, plateau_band_holds TRUE, price_leg_elevated FALSE, basis 'plateau_band';
--   -- 2026-10-19 and 2026-10-20 read 'elevated'; 2026-10-13..2026-10-16 read 'plateau_band'.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

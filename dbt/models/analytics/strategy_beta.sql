-- Parallel-run dbt port of bigquery/39_beta_adjusted_alpha.sql:analytics.strategy_beta — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH joined AS (
  SELECT sdr.as_of_date, sdr.strategy, sdr.r_deployed, spy.r_spy
  FROM {{ ref('strategy_daily_returns') }} sdr
  JOIN {{ ref('spy_daily_return') }} spy USING (as_of_date)
),
windowed AS (
  SELECT
    as_of_date, strategy, r_deployed, r_spy,
    COUNT(*) OVER w AS n_obs,
    SAFE_DIVIDE(COVAR_SAMP(r_deployed, r_spy) OVER w, VAR_SAMP(r_spy) OVER w) AS beta_hat,
    AVG(r_deployed) OVER w
      - SAFE_DIVIDE(COVAR_SAMP(r_deployed, r_spy) OVER w, VAR_SAMP(r_spy) OVER w) * AVG(r_spy) OVER w
      AS alpha_daily_hat
  FROM joined
  WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date ROWS BETWEEN 59 PRECEDING AND CURRENT ROW)
)
SELECT
  as_of_date, strategy, n_obs, beta_hat, alpha_daily_hat,
  -- Annualized alpha (compounds the daily-regression intercept over ~252 trading days) — the
  -- human-readable magnitude every consumer below actually reads. Floored at -100% when the daily
  -- intercept implies a total-or-worse loss (base <= 0): POWER's even exponent (252) would otherwise
  -- flip a catastrophically-negative alpha_daily_hat into a large POSITIVE alpha_annualized, which
  -- would spuriously SATISFY the `alpha_annualized <= 0` suppression term below (adversarial
  -- self-audit fix, rev 2026-07-11).
  IF(1 + alpha_daily_hat <= 0, -1.0, POWER(1 + alpha_daily_hat, 252) - 1) AS alpha_annualized,
  (n_obs >= 40) AS min_n_met
FROM windowed

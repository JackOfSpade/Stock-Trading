<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Shared regime vocabulary

Every strategy's activation rule references the same set of regime measurements. Centralizing these definitions prevents per-strategy drift in terminology and ensures the fundamental analysis template produces consistent per-strategy outputs. These definitions are immutable once the experiment begins.

### SPY Trend State

Computed daily from SPY daily close prices.

- **UP:** SPY close > SPY 50-day simple moving average AND SPY 50-day SMA > SPY 200-day SMA
- **DOWN:** SPY close < SPY 50-day SMA AND SPY 50-day SMA < SPY 200-day SMA
- **NEUTRAL:** any other combination

### VIX Regime

Computed daily from CBOE VIX daily close.

- **LOW:** VIX close < 15
- **NORMAL:** 15 ≤ VIX close ≤ 25
- **HIGH:** VIX close > 25

### Yield Curve State

Computed daily from 10-year and 2-year Treasury constant-maturity yields.

- **INVERTED:** 10Y yield < 2Y yield
- **NORMAL:** 10Y yield ≥ 2Y yield

### Yield Curve Sustained Inversion Flag

- **SUSTAINED:** Yield Curve State has been INVERTED for ≥ 18 consecutive months
- **NOT-SUSTAINED:** otherwise

Historically, sustained yield curve inversion precedes regime shifts where long-horizon equity theses compress under macro stress. Used only by Strategy D, which is uniquely exposed to multi-year macro path.

### Equity Breadth State

Computed daily from the percentage of S&P 500 constituents closing above their own 200-day SMA.

- **HEALTHY:** ≥ 50%
- **WEAK:** < 50%

Broad participation distinguishes genuine uptrends from narrow mega-cap-only rallies, which are fragile to rotation.

### Not in vocabulary

Sector-specific indicators, sentiment indices beyond VIX, and narrative indicators produced by AI are deliberately excluded from the shared vocabulary. The technical half of the router must be mechanically computable with no AI classification (per `Experiment_Parameters.md` regime router requirements). AI-classified regime judgments enter only through the fundamental analysis half.

---


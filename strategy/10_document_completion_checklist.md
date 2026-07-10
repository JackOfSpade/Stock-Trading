<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Document completion checklist

Before first trade:

- [ ] Adversarial review of each pre-mortem (one per strategy plus the one-time router pre-mortem) via the Attacker + Orchestrator routine pair per `Claude_Task_Plan.md`
- [ ] Revisions to any pre-mortem that fails adversarial review (authored by SL2 for a newcomer)
- [ ] Binding graduation verdict from AR_orc — the former "third-session adjudication if the first two disagree" step is superseded (rev 2026-07-10, Strategy Arsenal autonomy conversion, owner directive) by additional Attacker + Orchestrator cycles to the soft cap plus AR_orc's binding verdict and the bigquery/11 theater-judge
- [ ] Each strategy's pre-mortem completes its full lifecycle (original + adversarial + revision + binding verdict) before THAT strategy's first PROBE trade — scoped per-strategy at its own entry, not to a founding N+1 cohort before one shared first trade (N = current `state.strategy_roster` size)
- [ ] External ledger set up to track strategy portfolios independently
- [ ] Classical-method code delegation scaffolding operational for options math (C), correlation and beta computation (E), and sector/concentration checks (A, B, D)
- [ ] First monthly fundamental analysis completed; initial router states established

Once a strategy's spec locks at SHADOW entry (`spec_locked_since`), every threshold and template of THAT strategy is immutable for its life per `Experiment_Parameters.md` (two-tier immutability — see the Immutability clause near the top of this document; rev 2026-07-10, Strategy Arsenal autonomy conversion, owner directive). Roster membership and N remain versioned policy, revised only through the Strategy Arsenal Lifecycle.

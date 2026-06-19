<!-- GENERATED from Strategy.md by scripts/split_strategy.py — DO NOT EDIT.
     Strategy.md is canonical; regenerate after editing it. -->

## Document completion checklist

Before first trade:

- [ ] Adversarial review of each pre-mortem (one per strategy plus router) via Attacker + Orchestrator routine pair per `Claude_Task_Plan.md`
- [ ] Revisions to any pre-mortem that fails adversarial review
- [ ] Third-session adjudication if first two disagree on pre-mortem sufficiency
- [ ] All N+1 pre-mortems must complete (original + adversarial + revision + adjudication) before any strategy's first trade
- [ ] External ledger set up to track strategy portfolios independently
- [ ] Classical-method code delegation scaffolding operational for options math (C), correlation and beta computation (E), and sector/concentration checks (A, B, D)
- [ ] First monthly fundamental analysis completed; initial router states established

Once the first trade executes, every threshold and template in this document is immutable per `Experiment_Parameters.md`.

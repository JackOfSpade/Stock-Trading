# `strategy/` — generated slices of Strategy.md (P3-1)

These files are **generated** from the canonical `Strategy.md` by
`scripts/split_strategy.py`. They are a read-optimized *view*, not a new source of truth.

## Why
- **Context/cost/latency:** `Strategy.md` is ~339 KB and routines load it whole at session
  start. A strategy routine only needs its own section + the shared preamble/router.
- **Blinding as architecture:** the experiment requires M1a to *not* read strategy sections,
  and an adversarial attacker to *not* read beyond its artifact. Today that's enforced by
  instruction (a flagged "remember-to" fragility). Loading a single slice makes the boundary
  physical instead of trusted.

## Rules
- **Do NOT edit these files.** Edit `Strategy.md`, then run `python scripts/split_strategy.py`.
- CI runs `python scripts/split_strategy.py --check` so a stale slice fails the build.

## Status: PARALLEL-RUN (not yet a cutover)
`Strategy.md` remains canonical and every routine still reads it today. Re-pointing routine
read-instructions (in `Claude_Task_Plan.md` / `Operating_Protocols.md`) at these slices is a
**separate, owner-gated step** — the same parallel-run-then-flip discipline the system used for
its `.md`→BigQuery migration. Nothing here changes behavior until that flip is made.

## Follow-up (not done here)
`08_pre_mortems.md` is still whole (~264 KB). Splitting it per-strategy would complete the
blinding win for adversarial reviews; deferred because it requires parsing sub-headings and
mapping each pre-mortem to its strategy — do it when wiring the read-instruction cutover.

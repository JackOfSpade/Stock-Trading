# `strategy/` — generated slices of Strategy.md (P3-1)

These files are **generated** from the canonical `Strategy.md` by
`scripts/split_strategy.py`. They are a read-optimized *view*, not a new source of truth.
> **Exception — `roster.yaml` is NOT generated.** `strategy/roster.yaml` (added 2026-07-10, SISA autonomy conversion) is the one hand/routine-maintained file in this directory: `split_strategy.py` neither writes nor reads it, and the **Do NOT edit** rule below does **not** apply to it. It is the checked-in single source of truth for roster membership (written only by the arsenal routine SL5), CI-checked by `scripts/check_roster_consistency.py`. See its own header for the edit discipline.

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

## Status: canonical source + generated slices (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive)
`Strategy.md` remains the single canonical source and these slices remain **generated / DO-NOT-EDIT**. Slice (re)generation is no longer an owner-gated cutover: it is folded into the autonomous Strategy Arsenal Lifecycle — whenever SL2 authors a candidate section or SL5 registers/retires a roster member, the routine runs `python scripts/split_strategy.py` as part of its roster fanout, and CI's `python scripts/split_strategy.py --check` guarantees the slices stay byte-identical to `Strategy.md` (a stale slice fails the build, and auto-merge only merges on green CI). This follows the same D2a autonomous-cutover discipline (readiness view + idempotency marker + self-executing commit/push, never a chat question — `ops/RUNBOOK.md` §36) the system now uses for roster changes, replacing the former parallel-run-then-owner-flip sign-off. Editing a slice by hand is still forbidden; edit `Strategy.md` (or let SL2/SL5 edit it) and regenerate.

## Follow-up (not done here)
`08_pre_mortems.md` is still whole (~264 KB). Splitting it per-strategy would complete the
blinding win for adversarial reviews; deferred because it requires parsing sub-headings and
mapping each pre-mortem to its strategy — do it when wiring the read-instruction cutover.

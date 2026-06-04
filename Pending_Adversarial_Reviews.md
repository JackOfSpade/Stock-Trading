# Pending Adversarial Reviews — queue

Queue file for structured adversarial reviews (pre-mortem, divergence-review, m2m-termination, scope-widening-adjudication) per `Claude_Task_Plan.md` ADVERSARIAL REVIEWS section. Triggering routines (M5, A3, kill-trigger handlers) write entries here; review routines (Attacker / Orchestrator) read entries and produce outputs per file handoff. (Capital redistribution after a strategy terminates is NOT a review — it is deterministic, handled inline by the termination handler; see Experiment_Parameters.md "Strategy termination and capital redistribution.")

Each entry is a YAML-style block separated by `---`. Entries are appended in order of creation; once an entry reaches a terminal `status` (`complete`/`superseded`) D3 Calendar Hygiene sweeps it daily to `Archived_Adversarial_Reviews.md` and removes it from this live file (full clear — no pointer; see Operating_Protocols.md §12 / Claude_Task_Plan.md "Queue lifecycle and daily archive policy"), so this file holds only actionable entries.

Schema reference (per `Claude_Task_Plan.md`):
- `id`: unique identifier (e.g., `div-D-202605-1`, `premortem-strategyB-cycle3`, `m2m-D-202609`).
- `review_type`: one of `pre-mortem | divergence-review | m2m-termination | scope-widening-adjudication`.
- `strategy`: `A | B | C | D | E | router`.
- `trigger_context`: one paragraph of context.
- `artifact_path`: relative repo path to the artifact under review.
- `prior_state`: free-form text describing system state pending review.
- `attacker_due_date`: next trading day after queue creation (America/Denver).
- `orchestrator_due_date`: one trading day after `attacker_due_date`.
- `status`: `pending | attacker-complete | complete | superseded`.
- `attacker_output_path` / `orchestrator_output_path`: set by the respective routine when it completes.
- `cycle_number`: integer; `1` for first cycle of a given artifact; `n/a` for non-cycling review types.
- `notes`: free-form, optional.

_No actionable entries; completed/superseded entries are in `Archived_Adversarial_Reviews.md`._

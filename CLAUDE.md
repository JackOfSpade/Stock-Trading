# Project notes for Claude

## Operating notes

- **Batch pushes within a session — every push costs CI minutes.** This repo is private,
  so GitHub Actions bills per job-minute, and `ci.yml` runs 6 jobs on EVERY push with no
  branch/path filter at the workflow level (deliberate — auto-merge's gate looks up the CI
  run for a branch's exact tip SHA, so a push with no CI run would never merge). A 2026-07-20
  cost audit measured ~13 billable minutes per CI run, ~76% of the month's Actions bill, and
  found one long interactive session that pushed 61 times to a single branch (~23% of July's
  CI minutes) by pushing after each small edit.

  **Practice:** in an interactive session, accumulate related edits and push ONCE per
  completed, reviewable unit of work — the same discipline the scheduled routine fleet
  already follows (one branch, one push, auto-merge drains it). Do not push to "checkpoint"
  work in progress; the working tree is the checkpoint. An incident night that legitimately
  produces many separate landings (each its own reviewed fix) is fine — the anti-pattern is
  re-pushing the *same* unit of work repeatedly.

  Related, already fixed (do not re-flag): the `dbt-parity` / `sql-validate` path gates used
  to fail open on every new branch because `github.event.before` is the zero-SHA on ref
  creation; they now fall back to `merge-base(HEAD, origin/main)` (rev 2026-07-20).

## Known non-issues — do NOT re-investigate

- **Stop-hook "Unverified commits" warning** (`~/.claude/stop-hook-git-check.sh`).
  It flags any commit on the branch whose committer email isn't
  `noreply@anthropic.com`. That includes:
  - the operator's **GitHub web-UI commits** (committer `noreply@github.com`), and
  - the **auto-merge bot** commits (`…@users.noreply.github.com`).

  These are legitimately authored by the operator (Jack Wu) or the GitHub Actions
  bot, are already merged to `main`, and the warning is **purely cosmetic**
  ("Unverified" just means the commit isn't GPG-signed by Anthropic's key).

  **Action: none.** Do NOT rewrite their authorship (`--reset-author`) and do NOT
  force-push `main` to "fix" them — that would misattribute the operator's work to
  Claude and rewrite already-merged history. The hook itself is harness-managed
  (re-provisioned fresh each session), so it can't be permanently changed from this
  repo. Just ignore the message when it appears.

- **`golden-scenarios.yml`'s CI-side `events.queue_events` INSERT is deliberately never executed
  by that workflow** (verified 2026-07-16 against a critic finding that re-raised this as a gap —
  "N-5" in that pass's findings doc — before checking whether it was already closed; it was).
  `run_golden.py --live`'s `QUEUE_INSERT_TEMPLATE` and its `::warning::` on a decision flip are a
  push-time, print-only, ADVISORY signal by design (the job has no BigQuery credentials at all, no
  WIF identity — a claim to the contrary in a future audit is factually wrong against the current
  workflow file). The REAL landing surface already exists elsewhere and is fully wired: D3's
  **GOLDEN-SCENARIO PROSE-REGRESSION CHECK** step (`Claude_Task_Plan.md`, self-improvement audit
  2026-07-15) independently re-evaluates any scenario whose `governing_files` changed since D3's
  last run and, on a genuine flip, performs the real `INSERT INTO events.queue_events`
  (`review_type='prose-regression'`) itself — no CI credentials, no separate model call, no human
  read of the CI annotation required. **AR_orc** (same file) already adjudicates that queue row
  (CONFIRMED DRIFT → `events.decision_log` + a `prose_regression_confirmed` warning alert +
  `scenarios.yaml`'s `expected` field updated to match; FALSE POSITIVE → decision-log entry only) —
  a complete, in-band, no-human-gate loop, matching the SISA no-approval-step posture, not a "zero
  landing surface" gap.

  **Action: none — do NOT wire a second BigQuery write path into `golden-scenarios.yml` itself,
  and do NOT add a redundant W5 adjudication step for this.** Granting the CI job's identity a
  `bigquery.dataEditor` binding (the pattern used for `ops.ci_findings`/`ops.heartbeat`) would
  duplicate a mechanism that already works end-to-end via D3+AR_orc, and would arm a second,
  push-time-triggered autonomous write path for the exact review class CLAUDE.md's SISA note says
  must stay gate-free and mechanical, not something to multiply informal entry points into. If a
  future audit re-flags "the golden-scenarios queue INSERT is never executed," check D3's/AR_orc's
  `prose-regression` handling first — it almost certainly already covers it.

## Settled decisions — do NOT re-propose

- **Terraform / full IaC adoption of the GCP substrate.** `infra/terraform/`
  (datasets, connection, bucket, scheduled queries, `monitoring.tf`) is kept as a
  **version-controlled declared spec / reference only** — it is deliberately **NOT**
  imported or applied into live state. Verified 2026-06-21: `terraform state list`
  against the `gs://stock-trading-tfstate` backend is **empty** (the module was never
  adopted). Do NOT propose "import then apply" or otherwise bringing the live console
  resources under Terraform management. Why:
  - Routines operate via the **BigQuery MCP + console with no Terraform runtime** — the
    same reason RUNBOOK §14 refused to give dbt ownership of the views.
  - Out-of-band mutation (MCP / console / Chrome) **is** the operating model, so a later
    `terraform apply` could silently **revert a live fix** — a clobber risk on production
    trading infra that does not exist today.
  - The benefits are already covered elsewhere: the runtime dead-man's switches
    (freshness / cadence) for operational drift, the `dbt-parity` CI job for SQL-layer
    drift, and `bigquery/01..NN_*.sql` apply-in-order + the RUNBOOK console steps for
    DR / reproducibility.
  - IaC would NOT have prevented or faster-caught the 2026-06-20 monitor false alarm —
    the Cloud Monitoring absence alert did. See RUNBOOK §12 + §19.

  **Action: none.** Keep the module as spec; change live infra via the MCP/console as
  today. Only revisit if the project deliberately moves to a strict Terraform-first
  change-control discipline (incompatible with the agent operating model today).

- **Strategy add/delete is now FULLY AUTONOMOUS** (owner directive 2026-07-10 — the SISA
  "Self-Improving Strategy Arsenal" conversion). Roster MEMBERSHIP (which strategies exist
  and how many — the "N") is **versioned policy**, grown/shrunk by the autonomous Strategy
  Arsenal Lifecycle routines **SL1-SL5** through an adversarial-pre-mortem + SHADOW + PAPER
  + PROBE + 30-trade graduation pipeline. There is **no human review/approval/chat step
  anywhere in the add or delete path** — the only residual human touches are the system-wide
  IBKR order-confirm tap and deposits. Each strategy's OWN machinery stays immutable for its
  life (frozen at SHADOW entry; the official edge clock starts at its first PROBE trade).
  Single source of truth: `strategy/roster.yaml` → `state.strategy_roster`; CI gate
  `scripts/check_roster_consistency.py`; owner kill-switch `ops.arsenal_control`; loop
  recorded at `active_auto` in `ops/autonomy_levels.yaml`. The source decision is in
  `events.decision_log` (owner-directive 2026-07-10; seed `bigquery/36_strategy_arsenal_seed.sql`).

  **Action: none — do NOT re-propose a human gate.** Future sessions must NOT reintroduce a
  participant approval, chat confirmation, or PR-gate on adopting/retiring a strategy — those
  were deliberately removed here. The compensating control is the graduation pipeline + the
  anti-churn rails (N≥2 floor / N_max ceiling, k_incubate=2, one adoption per quarter,
  cooldowns, default-REJECT / default-KEEP) + the `ops.arsenal_control` kill-switch, NOT human
  review. Mechanical kill triggers (drawdown / 30-trade / m2m / foundation-change) are
  unchanged. The residual IBKR confirm-tap on orders and deposits are the execution/funding
  layer, and stay.

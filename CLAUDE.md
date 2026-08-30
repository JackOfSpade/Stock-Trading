# Project notes for Claude

## Operating notes

- **Batch pushes within a session — every push costs CI minutes.** This repo is private,
  so GitHub Actions bills per job-minute (ceil per job), and `ci.yml` runs on EVERY push with
  no branch/path filter at the workflow level (deliberate — auto-merge's gate looks up the CI
  run for a branch's exact tip SHA, so a push with no CI run would never merge). A 2026-07-20
  cost audit measured ~13 billable minutes per CI run under the then-6-job layout, ~76% of that
  month's Actions bill, and found one long interactive session that pushed 61 times to a single
  branch (~23% of July's CI minutes) by pushing after each small edit. Since the 2026-07-30 job
  consolidation `ci.yml` is 2 jobs and a routine push bills ~4 minutes (measured 2026-08-21 from
  the Actions jobs API: `checks` ~148 s → 3 min + `warehouse-validation` ~26 s → 1 min, runs
  32448847866 / 32437747452) — cheaper, but the batching discipline below is unchanged.

- **Scheduled workflows cost Actions minutes with NO push — and per-push is almost always MORE
  expensive, not less.** Measured 2026-08-30. `ci.yml` runs on every push at ~4 billable min, and the
  repo takes **~290 pushes/month** (daily push-count series measured 2026-08-30: median ~7.5
  CI runs/day, mean ~9.1/day — day-to-day count swings widely, so lean on the ~290/month figure,
  not the per-day median, when costing this). A DAILY cron is 30 runs/month. So
  converting any cron to a push trigger multiplies its cost ~10x, and path filters do not rescue it
  (`bigquery/` changed on 24 of 30 days, `ops/` 18, `scripts/` 17). Two crons are also *semantically*
  impossible per-push: `stranded-branch-check` detects a merge that did NOT happen (no event exists to
  fire on), and `live-sql-parity` detects console/MCP edits that produce no commit at all. **Do not
  re-propose "move the scheduled checks to per-push to save money" — it is arithmetically backwards.**

  **A measurement trap that already caught one audit:** GitHub's scheduled-trigger delivery is
  best-effort and its rate SWINGS. `alert-relay`'s `*/30` cron delivered 18-41 runs/day through
  2026-08-26, then collapsed to 3-7/day from 2026-08-27 during a platform-side scheduling backlog
  (confirmed platform-side, not repo-side: push-triggered `ci.yml` runs showed ZERO delay in the same
  window, while three unrelated scheduled workflows all slipped 4-11h simultaneously). An audit that
  sampled only the tail concluded ~7 runs/day and undercounted that one workflow by ~4x. **Always
  sample 3+ weeks of run history before costing a scheduled workflow, never the last few days.**

  2026-08-30 retune, for anyone reviewing why these cadences look the way they do: `alert-relay`
  `*/30` → `0 */2` (every 2h; it is the BACKUP channel, `alert_emailer.gs` is primary at
  `POLL_HOURS = 2`, and a backup never needs to poll faster than the primary it backs up — this
  was ~892 min/mo, ~60% of the whole scheduled bill). An earlier cut of this same retune briefly
  shifted the run onto a staggered every-2h offset (starting at 01:00 UTC instead of 00:00 UTC) to
  land an alerts run 5 min before the 13:05 orders run and keep the window step's anchor reset
  harmless, but a brute-force sweep over independent per-run scheduling delays showed the staggered
  and plain even-hour schedules both left the same 80-min hole, so the alignment bought nothing and
  was reverted — the hole is closed by the window step's margin=130 instead (see alert-relay.yml's
  `on.schedule` comment and scripts/alert_relay.py, which document that reverted history directly).
  Any other prose describing that staggered-hour offset as still in effect is stale;
  `sql-dryrun-sweep` weekly → monthly; `stranded-branch-check` `*/6` → uniform
  8h; `golden-prose-daily.yml` and `gemini-key-health.yml` deleted (see the golden-scenarios note
  below). `live-sql-parity` and `offsite-backup` cadences were deliberately NOT touched.

  **Practice:** in an interactive session, accumulate related edits and push ONCE per
  completed, reviewable unit of work — the same discipline the scheduled routine fleet
  already follows (one branch, one push, auto-merge drains it). Do not push to "checkpoint"
  work in progress; the working tree is the checkpoint. An incident night that legitimately
  produces many separate landings (each its own reviewed fix) is fine — the anti-pattern is
  re-pushing the *same* unit of work repeatedly.

  Related, already fixed (do not re-flag): the `dbt-parity` / `sql-validate` path gates used
  to fail open on every new branch because `github.event.before` is the zero-SHA on ref
  creation; they now fall back to `merge-base(HEAD, origin/main)` (rev 2026-07-20).

- **Interactive sessions must ASK before `git commit` / `git push` — the autonomous-routine
  gate-free posture (SISA, D1–W5, SL1–SL5, etc.) does NOT extend to a chat session with the
  operator.** Incident 2026-07-21: in an interactive session responding to an operator-forwarded
  alert email ("investigate and fix"), Claude committed and pushed a doc fix on its own initiative,
  reasoning from this file's extensive description of the autonomous scheduled-routine fleet
  (which commits/pushes with no human gate by explicit owner directive) instead of recognizing
  that authorization is scoped to *those* routines, not to interactive sessions. Claude's own
  standing operating instructions already say never to commit without being explicitly asked —
  this file's push-discipline guidance above is about *cost* (batch, don't checkpoint) **if and
  when** a push happens; it is not, and was never intended as, blanket authorization to skip
  asking in a chat session.

  **Practice:** in an interactive session, Claude proposes the fix and asks before running
  `git commit` / `git push` (or checks explicitly before doing so), even for a fix that mirrors
  something a scheduled routine would do autonomously. The scheduled/cron routine fleet's
  gate-free posture is a separate, explicitly owner-directed operating mode (`ops/autonomy_levels.yaml`)
  and does not carry over to chat sessions merely because the same repo and the same kinds of
  fixes are involved. If the operator wants a given interactive session to operate autonomously
  end-to-end, they say so in that session.

## Known non-issues — do NOT re-investigate

- **An unexplained `updated_at` bump on a claude.ai routine trigger.** The RemoteTrigger/routines API
  exposes `updated_at` but has **no actor/author field**, so an out-of-band trigger edit can be DATED
  but never ATTRIBUTED. Observed 2026-08-21: a browser session read the fleet, saw all 32 triggers
  updated in a 09:57–10:10 UTC window ~20s apart, and correctly could not tell whether that was the
  operator, another session, or something scheduled (it was an earlier browser session's own queue
  driver, doing an authorized rollout).

  **Action: do NOT go hunting for an audit trail — there is none to find, and none can be built from
  this API.** A bump on its own is evidence of neither intrusion nor safety. The question that CAN be
  answered is whether the live instruction still matches canonical, and that is already covered:
  Q4 step E clause (b) / OPS0 STEP 3 diff every live trigger against `ops/routine_backup.json`'s FULL
  instruction (core + the standing operator paragraphs, CI-validated by `scripts/routine_backup.py`
  `check` (2)) and self-correct any divergence, whoever caused it. Check that diff, not the timestamp.

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

- **Duplicate numeric prefixes in `bigquery/` (`114_*` x2, `185_*` x2).** Two routines landing SQL on the
  same evening each pick "the next number" independently and collide — `185_append_only_integrity_promotion_flip.sql`
  (D3, 01:09Z) and `185_sl2_notice_alert_lifecycle.sql` (SL2, 01:21Z) on 2026-08-19; `114_period_aware_dependency_gate.sql`
  and `114_selfheal_log_created_outcome.sql` on 2026-07-28/29. **Verified harmless 2026-08-19 (OPS2): in BOTH pairs the
  two files touch DISJOINT objects** (one creates a procedure, the sibling is DML/INSERT-only), so the apply-in-order
  DR-rebuild record replays to the same end state in either order — and lexical sort makes that order deterministic
  anyway. The 114 pair has coexisted ~3 weeks with no incident.

  **Action: none — and specifically do NOT renumber a landed `bigquery/*.sql` file to "fix" this.** The filenames are
  cited by number throughout `Claude_Task_Plan.md`, the RUNBOOK and the slices, and are load-bearing for superseded
  markers and `scripts/check_live_sql_parity.py`; renaming one to tidy a prefix breaks those references for a purely
  cosmetic gain. Do NOT add a CI check that fails on duplicate prefixes either, unless you first renumber the two
  existing pairs — it would turn `main` red on landed, working history. A shared prefix is TOLERATED; only a genuine
  same-OBJECT collision (two files creating or altering the SAME object where replay order changes the result) is a
  defect worth acting on, and neither existing pair is one. Check object overlap before concluding otherwise.

- **`golden-scenarios.yml`'s CI-side `events.queue_events` INSERT is deliberately never executed
  by that workflow** (verified 2026-07-16 against a critic finding that re-raised this as a gap —
  "N-5" in that pass's findings doc — before checking whether it was already closed; it was).
  `run_golden.py --live`'s `QUEUE_INSERT_TEMPLATE` and its `::warning::` on a decision flip are a
  CI-side, print-only, ADVISORY signal by design. Its history: per-push until 2026-08-21, then daily
  via `golden-prose-daily.yml`, then **RETIRED OUTRIGHT on 2026-08-30** — the daily job was deleted, so
  NO CI workflow re-evaluates scenarios live any more. It was removed because its flips were measured
  to be FALSE POSITIVES, not regressions: it reported a flip on every run (PA-02, RS-02, KT-07) while
  D3 re-evaluated the same scenarios and logged ZERO flips (`events.decision_log`, 29 of 33 on both
  2026-08-25 and 2026-08-26). The decisive case: KT-07 flipped 2026-08-28 while its ONLY governing file
  (`Experiment_Parameters.md`) had zero commits — prose that did not change cannot regress, so the flip
  was free-tier judge noise. It was degraded too, evaluating only 15 of 33 scenarios on its last run
  (`Gemini model ladder exhausted — HTTP 503`). `gemini-key-health.yml` was deleted in the same pass:
  it existed only to watch `GEMINI_API_KEY`, whose only functional consumer was that daily job. The
  remaining workflow (`golden-scenarios.yml`) has no BigQuery credentials at all and no WIF identity —
  a claim to the contrary in a future audit is factually wrong against it. The REAL landing surface
  already exists elsewhere and is fully wired: D3's
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

- **Making the OPERATING timezone plane dynamic / "detect the current location at runtime."**
  Asked and settled 2026-08-01, when the operator relocated Colorado → Toronto for ~6 months.
  The three planes (`bigquery/20_user_prefs.sql` is the reference):
  - **OPERATING** — trading-day keys, cadence, dead-man switches — **pinned `America/Denver`**,
    ~93 call sites. Never dynamic.
  - **MARKET** — session semantics — `America/New_York`, ~8 sites. A physical fact, not a preference.
  - **DISPLAY** — how a timestamp is RENDERED to the human — `state.user_tz`, **already dynamic**:
    D3 reads the Google Calendar primary-calendar `timeZone` daily and writes `ops.user_prefs`
    only on a difference. This is the ONLY plane that follows the operator, and it already works
    (it picked up `America/Toronto` on 2026-08-01).

  **A dynamic operating plane IS technically possible** — BigQuery accepts a subquery as the
  timezone argument (`CURRENT_DATE((SELECT tz FROM state.user_tz))` compiles and runs; verified
  2026-08-01). Do NOT take "it compiles" as evidence it is a good idea. It is rejected on
  correctness:
  - A date boundary there is the **partition key for records**, not a display preference. Denver
    (UTC−6) and Toronto (UTC−4) disagree about the calendar date for a two-hour band each night,
    and **OPS0 (04:30 UTC) and OPS2 (04:15 UTC) both fire inside it** — a dynamic plane would have
    silently moved their `run_date` by a day the moment the operator landed. Day-keyed dedup gates
    then see either a skipped day or a doubled day, with nothing to alert on.
  - Historical rows do not re-plane themselves, so every relocation leaves a permanent seam through
    the trailing-63d windows, `deployed_days >= 252`, and the 30-trade graduation counter.
  - It reopens the 2026-05-27 bug class (a UTC-vs-Denver mixup deleted a same-day order-confirmation
    event) — the exact incident `bigquery/20_user_prefs.sql` cites as the reason for the pin.

  **Anthropic's execution-host location is the worst candidate of all** and must never become the
  anchor: it is an infrastructure detail that can change per-run, per-region, or on any deploy with
  no notice; it is ~UTC in the container anyway; and it cannot reach the SQL call sites regardless,
  since those are evaluated by BigQuery, not by the routine's host.

  **Action: none.** If a future session wants to de-personalize the anchor, the ONLY legitimate
  form is a deliberate, versioned, one-time migration of the operating plane to `America/New_York`
  (a fact about the exchange rather than about the operator) — ~93 call sites plus re-tuning the
  21:00 MT deadline, and it still eats the historical seam once. That is its own project and the
  owner has not asked for it. It is NOT a runtime lookup, and `America/Denver` remaining
  "hardcoded" is the feature, not the defect.

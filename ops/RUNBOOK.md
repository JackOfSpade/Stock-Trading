# Operations Runbook

Companion to the analysis fixes. **Repo artifacts and additive BigQuery objects are already
done.** This file lists the steps that need the GCP/GitHub **console** (which automation cannot
click) plus the staged adoptions. Each item says what it solves (P0–P3 from the analysis).

> **2026-06-19 stack-review fixes (A1–D2).** A second review found the control plane was *coded but
> not operating* (empty `ops.run_log`; scheduled queries showing no recurring execution; everything
> running under one personal OAuth identity). The fixes below are now in the repo:
> - **IaC** — `infra/terraform/` codifies the datasets, the Vertex connection, the GCS backup bucket,
>   the budget, and **all four scheduled queries** (freshness, embed, backup, **new cadence check**).
>   This replaces the "click in console" steps in §1–§3 (see **§12**). The scheduled queries are
>   genuinely live only once `terraform apply` (or the console steps) runs — do that first.
> - **Run-logging** — `ops.sp_routine_start`/`sp_routine_end` + `ops.sp_assert_deps`
>   (`bigquery/12_cadence_monitor.sql`) give every routine one-call logging + a dependency gate
>   (see **§7**, **§13**). Data currency is also proven independently by
>   `state.freshness.marks_fresh`/`engine_fresh`.
> - **Cadence monitor** — `state.cadence_watch` + `bigquery/scheduled_queries/cadence_check.sql`
>   (self-bootstrapping: only alerts on routines that have adopted logging).
> - **SGOV reconciliation** — `state.sgov_reconciliation` event-sources the SGOV holding; the
>   hand-kept per-strategy share ledger is dissolved (Operating_Protocols §13).
> - **dbt** — `dbt/` is a tested, parallel-run modeling layer over the derived views (see **§14**).
> - **Credential resilience** — see **§15**.
> - **CI/dashboard** — `dbt parse` + keyless WIF SQL dry-run added to CI; a Pages workflow publishes
>   the dashboard (see **§5**, **§16**).

---

## 0. What is already live (no action needed)
- **CI** (`.github/workflows/ci.yml`): runs the options-math self-test + `pytest` + the
  `strategy/` slice-drift check on every push/PR. *(P0-1, P2-3)*
- **BigQuery objects deployed & verified** (additive, idempotent):
  `bigquery/09_market_calendar.sql` → `events.market_holidays`, `state.market_calendar`,
  `state.trading_day_today`; `bigquery/10_observability.sql` → `ops.run_log`, `ops.alerts`,
  `ops.sp_log_run`, `ops.sp_raise_alert[_once]`, `state.freshness`, `state.system_health`,
  `state.gate_watch`; `bigquery/11_theater_judge.sql` → `analytics.theater_judge`,
  `ops.sp_score_theater`, `analytics.theater_check_calibration`;
  `bigquery/12_cadence_monitor.sql` → `state.cadence_expected_today`, `state.cadence_watch`,
  `ops.sp_assert_deps`, `ops.sp_routine_start`, `ops.sp_routine_end`;
  `bigquery/13_sgov_reconciliation.sql` → `state.sgov_position`, `state.sgov_reconciliation`;
  and D2's run is logged by the routine via `ops.sp_routine_start`/`sp_routine_end` (not self-logged
  by `ops.sp_daily_refresh`).
- Quick check anytime: `SELECT * FROM state.system_health;` (want `all_green = TRUE`);
  `SELECT * FROM state.cadence_watch WHERE needs_attention;` (want zero rows);
  `SELECT * FROM state.sgov_reconciliation;` (events-side SGOV shares to compare to the connector).

To re-apply or move to a fresh project, run `bigquery/01..11_*.sql` in order via the BigQuery MCP
`execute_sql` (same pattern the existing files use).

---

## 1. Scheduled queries — **the dead-man's switch** *(P0-2, P0-3)*
Until these exist, the procedures only run when a session calls them (a skipped session =
silent drift). Bodies are in `bigquery/scheduled_queries/` (see that folder's README).

> **PREFERRED PATH (2026-06-19): apply via Terraform.** `infra/terraform/scheduled_queries.tf`
> codifies all four scheduled queries (single-sourcing the SQL bodies from
> `bigquery/scheduled_queries/`), with `email_preferences.enable_failure_email = true` on the
> RAISE-ing ones. Run `terraform apply` (after the one-time `import` of existing resources — see
> `infra/terraform/README.md` and §12) instead of hand-creating them. **A second review found these
> scheduled queries were NOT actually running** (no recurring execution in 30 days of job history),
> so this is the step that makes the dead-man's switch real. The console steps below remain valid as
> a manual fallback.

BigQuery Studio → **Scheduled queries → Create**. **BigQuery schedules are UTC** (the UI's
local-time label is misleading) — use the UTC times below so the check lands in the Denver
evening *after* D2 year-round:
1. **Embeddings heal** — paste `embed_pending.sql`; daily ~06:00 UTC; Location US. (Timing is
   irrelevant — the embedder is idempotent.)
2. **Freshness check** — paste `daily_freshness_check.sql`; **daily at 05:00 UTC** (≈ 22:30 MDT /
   21:30 MST — evening, after D2; NOT 21:30 UTC, which is 15:30 MDT = *before* D2 and would
   false-alarm every trading day). Under **Notifications**, enable *Send email on failure* — the
   query RAISEs when `system_health` isn't green, so that email IS the alert (no Pub/Sub needed).
3. **Cadence check** — paste `cadence_check.sql`; **daily at 05:15 UTC** (after D2/D3, like the
   freshness check). Enable *Send email on failure* — it RAISEs when a *monitored* routine
   (one that has logged a `completed` run in the last 14 days) was expected today but did not run.
   Self-bootstrapping, so it never false-alarms on routines that don't yet self-log. *(A3)*
4. The new scheduling UI no longer exposes `maximum_bytes_billed`; don't worry about it — all
   queries scan < 2 MB. Cost is bounded by the budget alert in §2. *(P2-2)*

---

## 2. Cost guardrails *(P2-2)*
- GCP Console → **Billing → Budgets & alerts** → budget on project `stock-trading-498512`
  with email thresholds (Vertex embeddings/Gemini/AI.FORECAST are the only billed pieces;
  they're pennies, but unattended scheduled jobs should be capped).
- Prefer `execute_sql_readonly` for agent reads. (`maximum_bytes_billed` isn't settable on
  scheduled queries in the current UI; the scheduled scans are tiny, so the budget alert is the
  guardrail.)

---

## 3. Backups of the event store *(P2-1)*
`events.*` is now the irreplaceable source of truth; only 7-day time-travel protects it today.
Bucket + lifecycle are **DONE** (`gs://stock-trading-backups`, US, delete > 400 days). To automate
the actual backups with **no Cloud Run job and no key**, use the BigQuery scheduled query
`bigquery/scheduled_queries/backup_events_export.sql` (it `EXPORT DATA`s every `events.*` table to
the bucket as dated Parquet, straight from BigQuery):
1. Grant the scheduled query's service account `roles/storage.objectAdmin` on `gs://stock-trading-backups`.
2. Create the scheduled query: daily ~05:30 UTC (after the freshness check); Location US; no destination.
3. *(Alternative, ad-hoc / full export)* run `BUCKET=gs://stock-trading-backups scripts/backup_events.sh`
   from Cloud Shell — same Parquet layout, uses the `bq` CLI; good for a one-off verification.
4. (Optional, auditability) have D2 run `scripts/state_snapshot.sh` and commit
   `state_snapshots/` — restores the "git diff shows what changed today" property the
   `.md`→BigQuery cutover gave up, without resurrecting the retired live-state files.

---

## 4. Dashboard *(P1-4)*
Two options (pick one):
- **No console:** schedule `python ops/dashboard/generate_dashboard.py` (needs `bq` auth) and
  serve `ops/dashboard/index.html` via GitHub Pages / commit it. Self-contained HTML.
- **Looker Studio:** New report → BigQuery connector → `state.system_health`,
  `perf.strategy_daily`, `analytics.strategy_nav`, `ops.alerts`, `state.gate_watch`.

---

## 5. Make CI actually gate merges *(P0-1)* — DONE
`auto-merge-claude.yml` now triggers on the **CI** workflow's completion (`workflow_run`) instead
of on push, and merges a `claude/*` branch only if the CI run for that branch's **exact tip
commit** concluded `success`. Because the gate keys off the whole CI *run* conclusion, it covers
every required job (`options-math tests`, `dbt parse`, and the keyless-WIF `BigQuery SQL dry-run`
when configured — §6); the `lint` job is `continue-on-error` (advisory), so it never affects the
gate. A red build is skipped (and retried automatically when its CI later turns green), so a broken
commit no longer reaches `main` — all without human intervention or changing the direct-push model.
Fail-closed: in-progress / missing / API-error states are treated as "not green".
Considered but rejected: re-running the tests inside the merge job (duplicates CI and, in the
drain-all loop, would need a per-branch checkout+test), and branch protection + required checks
(would force PRs, abandoning the direct-push model).

## 6. CI SQL validation — `dbt parse` (always-on) + optional keyless-WIF dry-run *(P2-3, D2)*
The always-on SQL gate is the **`dbt` job's offline `dbt parse`** (no creds, runs on every push;
validates the modeling layer + that every ref/source/test resolves). That is the recommended gate.

The separate **`sql-validate`** job (live `bq --dry_run` of every `bigquery/*.sql` under keyless
GitHub→GCP Workload Identity Federation) is **OPT-IN and OFF by default** — and we recommend leaving
it off. Why: dry-running the DDL files (`CREATE TABLE/MODEL/VIEW`) requires **CREATE/DDL permissions
on the production datasets** (events/ops/analytics/state), *even in `--dry_run`*. Granting a
CI/PR-triggered identity write+DDL on the append-only source of truth over-privileges it for marginal
value, and a live dry-run does **not** catch the runtime-only bugs we actually hit (e.g. the
`EXPORT DATA` JSON-serialization error — its own comment notes dry-run misses it). So the CI service
account (`gh-ci-runner`) is kept **read-only** (`jobUser` + `dataViewer` + `connectionUser`).

WIF itself is set up (provider `github-pool/github-provider`, SA `gh-ci-runner@…`, repo variables
`GCP_WIF_PROVIDER` + `GCP_WIF_SERVICE_ACCOUNT`) and powers any future keyless need (e.g. a `dbt build`
or §16's dashboard). To turn the live SQL dry-run ON anyway, the owner must:
1. Enable the **Cloud Resource Manager API** (`gcloud services enable cloudresourcemanager.googleapis.com`)
   and the IAM Service Account Credentials API (already enabled).
2. Grant `gh-ci-runner` the DDL perms the dry-run needs (`roles/bigquery.dataEditor` on
   events/ops/analytics/state/perf + `bigquery.models.create` on `ops`) — accepting the
   over-privilege tradeoff above.
3. Set repo variable **`RUN_SQL_DRYRUN=true`**.
Until all three are set the job skips cleanly (green). SQL is also dry-run via the BigQuery MCP during
development, which is the practical safety net.

---

## 7. Adopt `run_log` + `alerts` in the routines *(P1-1, P0-4)* — convention DONE; enforcement HARDENED 2026-06-19
A **global convention** in `Claude_Task_Plan.md` ("## Observability — run logging & failure
alerts") binds every routine (D1–A3 + the adversarial attacker/orchestrator), with D2 as the
worked example.

> **FINDING (2026-06-19): `ops.run_log` was EMPTY in production** — the convention is instruction-only
> and the agent was skipping it, so `state.freshness.d2_ran_last_trading_day` was permanently FALSE
> (only marks/engine freshness actually worked). **Fixes applied:**
> - `ops.sp_routine_start` / `ops.sp_routine_end` collapse start/end logging (+ a dependency gate)
>   into one call each, lowering the "remember-to" surface; now demonstrably adopted in production
>   (D1/D2/D3/AR routines logging). Data currency is independently proven by
>   `state.freshness.marks_fresh`/`engine_fresh` (which read the data tables, not `run_log`).
> - `state.cadence_watch` + `cadence_check.sql` catch a *monitored* routine that skips a scheduled run.
> A routine becomes monitored automatically the first time it logs, so adoption is incremental and
> never false-alarms. Verify adoption: `SELECT routine, MAX(run_date) FROM ops.run_log GROUP BY 1`.

For reference, the calls each routine makes (see also `ops/cadence.yaml` `defaults`):
- **Start/end of every routine:** `CALL ops.sp_log_run('<id>', <run_date>, 'started'|'completed'|'failed'|'halted', <session>, <branch>, <rows>, <error>, <note>)`.
  This populates `state.freshness.d2_ran_last_trading_day` and the audit trail.
- **On any hard-stop** (cash tripwire > $1, dual-path max-loss disagreement, embedding
  unhealthy, merge-conflict PR, stale data): `CALL ops.sp_raise_alert('critical', '<routine>',
  '<category>', '<message>', '<payload_json>')` **and** create a `[Claude] ATTENTION …`
  calendar event so the unmonitored failure reaches the operator.

## 8. Extend the market-holiday calendar yearly *(P1-3)*
Each December, append next year's NYSE/Nasdaq full closes (+ any early closes) to
`events.market_holidays` (MERGE in `bigquery/09_market_calendar.sql` is the template) and extend
the date range in `state.market_calendar` if needed.

## 9. Strategy slices — cutover DONE (via authoritative read convention) *(P3-1)*
`strategy/*.md` are generated from `Strategy.md` (`scripts/split_strategy.py`; CI guards drift).
The cutover is now done at the instruction layer: `Claude_Task_Plan.md` "Strategy reading — use the
generated `strategy/` slices" is an **authoritative** routine→slice map that overrides any in-body
"Read Strategy.md (… section)" — per-strategy routines load only their slice(s) + `01`, so blinding
is a file boundary and context shrinks. `Strategy.md` stays canonical (fallback + regenerate source).

**Known exception — M1a.** The slices split on top-level `##`, and the "Regime router" slice (`02`)
bundles M1a's regime-scoring template WITH the M1b strategy-mapping + reconciliation rules that name
strategies A/D — so no slice gives the strategy-blind M1a a clean file. M1a therefore still reads the
named `### Fundamental analysis template (monthly)` sub-section of `Strategy.md` (+ `01`), discipline-
blinded as before. To make M1a's blinding a true file boundary, restructure `Strategy.md` so the M1a
inputs are a separate top-level section from the M1b mapping, then the splitter can emit an M1a-clean
slice. Deferred (needs a canonical-spec edit).

## 10. Theater judge — run it *(P3-2)*
Add to **W5**: `CALL ops.sp_score_theater();` then read `analytics.theater_check_calibration`
to compare the objective judge against the orchestrator's self-certified theater_check. Billed
(Gemini) but tiny — only scores not-yet-scored paired reviews.

## 11. Conviction gate watch *(P3-3)*
No action now (B at 5/30, D at 0/30 closed). `state.gate_watch` surfaces proximity; revisit the
gated conviction model (`bigquery/04_analytics.sql`) when `approaching_gate` flips TRUE.

---

## 12. Infrastructure as code — Terraform *(A1, A4)*
`infra/terraform/` codifies the GCP substrate that previously lived only as console state: the 5
datasets, the `us.vertex` connection, the `gs://stock-trading-backups` bucket + lifecycle, the budget
alert, and **all four scheduled queries** (single-sourcing the SQL bodies from
`bigquery/scheduled_queries/`). Most resources ALREADY EXIST, so the flow is **import, then apply**:
1. `cd infra/terraform && terraform init`.
2. `terraform import` each existing resource (datasets, connection, bucket) — exact commands in
   `infra/terraform/README.md`. After import, `terraform plan` should show ~no changes for them.
3. Set `billing_account` + `notification_emails` in `terraform.tfvars` (copy `.example`).
4. `terraform apply` — this is what actually CREATES the scheduled queries (the dead-man's switch),
   which the 2026-06-19 review found were never running.
Owner decisions: the `billing_account` id; whether to use a remote GCS state backend (commented in
`versions.tf`); and whether the backup export runs under owner creds (default) or a dedicated SA.

## 13. Cadence monitor + dependency gate *(A3, C1)* — DONE (deployed)
`bigquery/12_cadence_monitor.sql` is applied. `state.cadence_watch` shows, per operating day, which
routines were expected (per `ops/cadence.yaml`, encoded in `state.cadence_expected_today`) and whether
they logged `completed`; `cadence_check.sql` (schedule it, §1) alerts on a *monitored* miss.
Routines call `ops.sp_routine_start('<ID>', <denver_today>, <session>, <branch>, <deps>, <instruction>)` /
`ops.sp_routine_end(...)`; the `<deps>` array hard-gates the run via `ops.sp_assert_deps` (self-
bootstrapping — a not-yet-logging upstream is treated as satisfied, so it is safe to declare deps now),
and `<instruction>` (the verbatim trigger text the session received) is recorded in
`ops.run_log.instruction` → `state.routine_last_instruction` so the **live web-UI trigger text is
verifiable by query** (no screenshots): `SELECT * FROM state.routine_last_instruction;` and diff
against `python scripts/print_routines.py` (the canonical). No console action beyond scheduling
`cadence_check.sql`.

## 14. dbt — TEST/VALIDATION layer (view-ownership cutover NOT pursued — decided 2026-06-19) *(B2, B3)*
`dbt/` ports the pure-SELECT derived views (state/perf/analytics) into dbt models with a dependency
DAG + data tests, INCLUDING the load-bearing invariants the review flagged (reserved_cash formula,
queue `event_ts` latest-wins, daily-marks no-double-count, one-row health views). CI runs `dbt parse`
offline on every push; run the assertions against BigQuery on demand with `cd dbt && dbt deps && dbt test`
(uses your `oauth` profile or WIF). **This is dbt's role here: a continuous structure + invariant
TEST layer.**

**Decision: do NOT transfer view OWNERSHIP to dbt** (i.e., do not remove the view DDL from
`bigquery/*.sql`). Reasons specific to this system: (1) routine sessions run on the BigQuery MCP and
have **no dbt runtime**, so if dbt owned the views, a session could neither rebuild nor change them;
(2) the disaster-recovery / fresh-project path is "apply `bigquery/01..13_*.sql` in order via the MCP"
— removing the view DDL breaks that single-command rebuild; (3) it can't be validated here (no dbt in
this environment) that `dbt build` reproduces every view byte-identically, and these are live trading
views. So `bigquery/*.sql` stays the **canonical runtime owner** of the views; `dbt/` is the test
mirror (kept in sync as a parallel-run port; `dbt parse` drift is the guard). If a true ownership
cutover is ever wanted, it must FIRST wire an operational dbt runner (e.g. a scheduled `dbt build`
into a scratch dataset, with the CI SA granted dataEditor only on that scratch dataset) and validate
byte-parity — only then remove the DDL. See `dbt/README.md`.

## 15. Operational identity & credential resilience *(C3)*
**Finding (2026-06-19):** 30 days of BigQuery job history ran under a SINGLE principal —
`jacksterwu@gmail.com` (owner OAuth). There is no autonomous service identity; the only service
account, `bq-loader@…`, last ran on the migration day and its key was deleted. Risks: if that OAuth
grant lapses or the operator is unavailable, the whole system stalls — and the dead-man's switch would
stall with it (it ran under the same identity).
- **Make the monitor independent of the agent.** Run the freshness + cadence + backup scheduled
  queries (§1, via Terraform §12) under the **BigQuery Data Transfer service identity** (or a
  dedicated SA), NOT the interactive OAuth session — so the alarm can still fire when the agent's
  identity is the thing that failed. (Email-on-failure is already enabled on them.)
- **Document expiry + rotation.** Record the OAuth grant / MCP-connector token lifetimes for BigQuery,
  IBKR, and Calendar, and a rotation/re-consent procedure, so an expiry is planned, not a silent outage.
- **Heartbeat.** The freshness email is the liveness signal; if it stops arriving entirely (vs. firing
  red), that absence is itself the alert — note this so a silent scheduler death is noticed.

## 16. Publish the health dashboard *(D1)*
`.github/workflows/dashboard.yml` builds `ops/dashboard/index.html` from BigQuery and deploys it to
GitHub Pages. **OFF by default and double-gated** (the page shows live trading data): enable only by
setting repo variables `PUBLISH_DASHBOARD=true` **and** the WIF vars (§6), and only on a PRIVATE repo
with access-controlled Pages (Settings → Pages → Private), or accept public exposure. **On a personal
(non-Enterprise) repo, Pages publishes PUBLICLY even for a private repo — so do NOT use the Pages path
there.**

### Recommended hosted option — Looker Studio (Google-auth gated, no public exposure)
This is the recommended way to get a continuously-fresh hosted dashboard without exposing live data.
It stays private to your Google account unless you explicitly share it; viewing requires Google login.
1. Go to https://lookerstudio.google.com → **Create → Report** → add a **BigQuery** data source.
2. Authorize, pick project `stock-trading-498512`, and add these as data sources (Custom query or
   table per view), each in **US**:
   - `state.system_health` (the green/red rollup — put `all_green` on a scorecard up top)
   - `perf.kill_flags` (per-strategy drawdown / excess / closed-trades / firing flags)
   - `analytics.strategy_nav` (NAV / available_funds / sizing_base_2pct)
   - `state.cadence_watch` (filter `needs_attention = true` — a table that should stay empty)
   - `ops.alerts` (filter `resolved = false` — open alerts)
   - `ops.run_log` (recent routine runs)
3. Build the report (scorecards + tables); set the data-source **freshness** to ~1 hour.
4. **Keep it private:** do NOT use "Share → Anyone with the link." Share only to your own Google
   account / specific addresses. (Optional: point the data sources at a dedicated read-only viewer
   service account instead of "Owner's credentials.")
This needs no repo/CI changes and no `PUBLISH_DASHBOARD`. The static `ops/dashboard/generate_dashboard.py`
remains for ad-hoc local viewing (`python ops/dashboard/generate_dashboard.py` → open `index.html`).

## 17. Public-exposure guardrail — enforce `iam.disablePublicIamGrants` *(security, deferred)*
From the 2026-06-19 public-exposure audit. IAM is clean today (no `allUsers` /
`allAuthenticatedUsers` on the project or any BigQuery dataset, GCS bucket has Public Access
Prevention enforced), but nothing *prevents* a future accidental public grant. The
`iam.disablePublicIamGrants` org-policy constraint rejects any such binding outright — turning
"clean today" into "can't be made public by accident."

**Not actionable yet:** the constraint can only target a resource under a **Google Cloud
Organization**, and `stock-trading-498512` is a standalone project with no Org (the Org Policies
page returns "select a resource under an organization"). When/if you attach the project to an Org
(requires Google Workspace or Cloud Identity + domain verification — owner-only setup):
1. IAM & Admin → **Organization Policies** → constraint **`iam.disablePublicIamGrants`** ("Disable
   public IAM grants") → set **Enforced** at the org or project level.
   CLI: `gcloud resource-manager org-policies enable-enforce iam.disablePublicIamGrants --project=stock-trading-498512`
   (only succeeds once the project is under an Org where the constraint is available).
2. Related, optional: enforce `iam.allowedPolicyMemberDomains` (Domain restricted sharing) to
   confine bindings to your own domain.

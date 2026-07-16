# Owner actions

Everything Claude could apply without you (schema, views, procedures, scheduled-query SQL bodies,
repo docs) is already applied live and merged to `main`. This file is the complete list of the
handful of things only you can do — a GCP console click, a `bq`/`gcloud` command run with your own
credentials, an Apps Script paste (`script.google.com` isn't reachable from here), or a tax election
with your broker. Nothing in this system is blocked or unsafe while these are outstanding — every
item below is explicitly designed to fail closed / no-op / stay on its existing fallback until you
act. Dated passes below; most recent first.

---

# 2026-07-16 research_quality_feedback promotion substrate (LC-4 other parts, loop-completeness audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet. (LC-4's other half — adding
`loop:research_quality_feedback` to `cadence_check.sql`'s dead-man UNNEST arrays — landed earlier in
this same sequence and is not repeated here.)

## M. Apply `bigquery/71_research_quality_promotion.sql` live via the BigQuery MCP/console

**What it's for:** completes the `research_quality_feedback` loop's persistence substrate so its
SHADOW -> ACTIVE_AUTO promotion is no longer an unowned "future, separately-committed edit." Creates
`ops.loop_promotion_log` (durable promotion idempotency marker; `CREATE TABLE IF NOT EXISTS`, safe to
double-apply if a sibling loop-promotion change also defines it), `ops.research_quality_observations`
(per-cycle observation log, the `ops.process_reliability_observations` analog this loop was missing),
and `state.research_quality_promotion_readiness` (3-consecutive-W5-cycle `min_n_met` persistence AND
not-already-promoted). Apply order: after `66_research_quality_feedback.sql`.

**Action:** run the DDL/view statements in `bigquery/71_research_quality_promotion.sql` via the
BigQuery MCP or console (this session was not permitted to call BigQuery directly). Not urgent — the
readiness view is fail-closed empty until W5's RESEARCH-QUALITY FEEDBACK bullet starts writing
`ops.research_quality_observations` rows (which itself requires `n_closed >= 1` cells; account-wide
total is currently 7 GO theses, 3 closed), so nothing depends on this being applied same-day. Apply
whenever convenient, ideally before this round's commits are pushed to `main`.

---

# 2026-07-16 AR_orc echo_suspect_cap_reached cool-off close (CC-2, consumption-closure audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## L. Verify the CC-2 dry-run acceptance test live, then clean up the synthetic rows in the same session

**What it's for:** CC-2 adds `Claude_Task_Plan.md` AR_orc **STEP 0.5 — ECHO-SUSPECT COOL-OFF
RE-ADJUDICATION** plus a Step 4 resolve-tail and a Step 3.5 alert-text fix, so a review that hits the
`echo_suspect_cap_reached` critical (2+ failed theater-independence checks) is retried automatically
every >=14 days instead of parking `state.trading_enabled` open-ended pending an owner session. This
session deliberately did **not** run the dry run against live BigQuery (out of scope for a
local-only round — no MCP calls were made). No live `echo_suspect_cap_reached` alert has ever fired
(confirmed latent, zero occurrences), so this is not urgent, but please verify the mechanism once
before or shortly after the Claude_Task_Plan.md STEP 0.5 text goes live:

**Action — dry run (needs the BigQuery MCP or console, run in ONE session so cleanup isn't skipped):**
1. Insert a synthetic alert: `INSERT INTO ops.alerts (alert_ts, severity, source_routine, category, message, resolved, payload) VALUES (TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 4 DAY), 'info', 'AR_orc', 'echo_suspect_cap_reached', 'TEST-REVIEW-CC2-DRYRUN — dry-run synthetic row, do not action', FALSE, JSON '{}')` — `severity='info'` deliberately, so it never enters `blocking_criticals` and never halts trading (a `severity='critical'` synthetic row would, for the duration of the test).
2. Run (or wait for) the next AR_orc fire. Confirm exactly one new `events.queue_events` row appears with `JSON_VALUE(payload,'$.echo_suspect_cooloff')='true'` and one `events.decision_log` row with `entry_type='echo-cooloff-requeue'`.
3. Run AR_orc again (same day or within the 14-day window). Confirm it enqueues nothing further for this test review id (the 14-day gate holds).
4. **Cleanup in the same session:** `UPDATE ops.alerts SET resolved=TRUE, resolved_note='dry-run' WHERE category='echo_suspect_cap_reached' AND message LIKE '%TEST-REVIEW-CC2-DRYRUN%'` AND set the synthetic `events.queue_events` row's `status='abandoned'` (note `'dry-run'`) so queue-driven AR_att never picks it up and attacks a nonexistent artifact.

Not urgent (latent path, zero live occurrences) — do whenever convenient, ideally before this round's
commits are pushed to `main`.

---

# 2026-07-16 SISA retirement round-trip fix (LC-1/CC-4, loop-completeness audit) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## K. Apply `bigquery/70_retirement_proposed_is_active.sql` live via the BigQuery MCP/console

**What it's for:** redefines `state.strategy_roster` so `is_active` includes `RETIREMENT_PROPOSED`
(currently a strategy under retirement review silently drops out of `is_active` — and therefore out
of M4 §H's kill-trigger sweep, `state.active_strategy_codes`, and `state.arsenal_rails.active_count`
— for the whole adversarial-review window, even though a retirement PROPOSAL is default-KEEP).
Supersedes the live `state.strategy_roster` view currently deployed from `bigquery/51_strategy_roster_dates_tz.sql`.
Apply order: after `51_strategy_roster_dates_tz.sql`, same as every other `bigquery/NN_*.sql` file
(see `bigquery/README.md`).

**Action:** run the `CREATE OR REPLACE VIEW` statement in
`bigquery/70_retirement_proposed_is_active.sql` via the BigQuery MCP or console (this session was
not permitted to call BigQuery directly). Not urgent — `state.strategy_retirement_candidacy` requires
`deployed_days >= 252` and the founding batch's clock started 2026-04-23, so SL4 cannot fire its
first proposal before ~2027-04 (0 `RETIREMENT_PROPOSED` rows exist today), but apply it whenever
convenient so it's in place well before then.

---

# 2026-07-16 Live-SQL-parity self-heal (RES-3, issue #10) — local-only implementation round

This pass was done as a **local-only** implementation (commits sit on the working branch, not
pushed) per that round's ground rules — nothing below is live yet.

## H. Apply `bigquery/69_live_sql_parity_selfheal.sql` live via the BigQuery MCP/console

**What it's for:** `ops.parity_selfheal_log`, the append-only latch/idempotency table
Claude_Task_Plan.md's new D3 **LIVE-SQL-PARITY SELF-HEAL** step reads/writes to avoid re-applying
the same drifted object every day and to detect a non-converging heal (comparator bug / competing
live writer) within a 7-day window. Apply order: after `47_trading_enabled_resync.sql`, same as
every other `bigquery/NN_*.sql` file (see `bigquery/README.md`).

**Action:** run the `CREATE TABLE IF NOT EXISTS` statement in `bigquery/69_live_sql_parity_selfheal.sql`
via the BigQuery MCP or console (this session was not permitted to call BigQuery directly).

## I. Decide the findings-file→`main` delivery path for `live-sql-parity.yml` (deliberately deferred)

**What it's for:** the corrected spec for this improvement called for `live-sql-parity.yml`'s daily
run to commit its `--json-out` findings (now implemented, script-side) to
`ops/monitoring/live_sql_parity_findings.json` via a bot identity and `git push origin HEAD:main`
directly (no PR — repo is private/free-plan, no branch protection to enforce one). **This session
deliberately did NOT implement that push step** — widening the workflow's `contents: read` →
`contents: write` and adding an autonomous `git push`-to-`main` retry loop would arm a standing,
unattended CI→main push pathway with zero human review, which conflicts with this implementation
round's own ground rules (no pushes without your review) even though the mechanism would only ever
fire once merged and running for real. See the `if:`-gated comment block in
`.github/workflows/live-sql-parity.yml` (right after the "Compare live BigQuery definitions..."
step) for exactly what was left out.

`ops/monitoring/live_sql_parity_findings.json` is seeded as a static `{"checked_at": null,
"findings": []}` placeholder so the new D3 step never 404s reading it — it will just stay empty
(fail-closed, no self-heal candidates, no functional regression) until you decide how findings
should reach `main`. Options, roughly in the order this pass would recommend them:
1. **Accept the direct-push design as originally spec'd** (lowest complexity; this repo already has
   an owner-approved precedent for bot-authored commits landing on `main` without a human eye per
   `CLAUDE.md`'s auto-merge-bot note) — wire the step back in per the spec text preserved in the
   workflow's comment block.
2. **Route it through a PR instead**, relying on the existing auto-merge-on-green-CI bot — a
   materially different code path (no literal `git push` to `main` in the workflow itself) but likely
   an equivalent outcome once merged, since the auto-merge bot itself runs unattended.
3. **Reuse the `ops.ci_findings` / `state.ci_findings_open` bridge** already built for this same
   issue #10 by `bigquery/67_ci_findings_bridge.sql` (CC-1) instead of a second, JSON-file-based
   path — once item G below (the `gh-ci-runner@` grant) lands, that bridge already carries
   `live-sql-parity` findings into BigQuery with no git push at all. Note this would leave two
   overlapping self-heal mechanisms for the same finding class (CC-1's CI-FINDINGS ADJUDICATION D3
   step + this pass's LIVE-SQL-PARITY SELF-HEAL D3 step, both in `Claude_Task_Plan.md`) — worth
   reconciling into one rather than running both once either delivery path is live end-to-end.

**If skipped:** exactly today's behavior continues — `live-sql-parity.yml` opens/refreshes the GitHub
issue and (once item G lands) mirrors into `ops.ci_findings` as before; the new self-heal step
simply has nothing to do.

## J. Comparator fix (already applied, no owner action) — for awareness only

`scripts/check_live_sql_parity.py`'s PROCEDURE-wrapper and trailing-comment false-positive bugs
(the ~24-object class behind issue #10) are fixed and covered by
`tests/test_check_live_sql_parity.py` in this same local pass. No live action needed — this is a
repo-only fix that will simply produce a smaller, more accurate finding set the next time the
workflow runs post-merge.

---

# 2026-07-16 CI findings bridge (CC-1, issue #10 consumption-closure)

## G. GCP IAM grant — let CI write CI-guard findings into BigQuery (CC-1)

**What it's for:** four CI guards (`live-sql-parity.yml` daily, `keyless-sa-audit.yml` /
`wif-binding-audit.yml` / `guard-config-audit.yml` monthly) each open/refresh a deduped GitHub issue
on a finding, but nothing automated ever reads those issues today — live-sql-parity's own Actions run
even stays green on drift (issue #10, opened 2026-07-16T09:34Z, unconsumed while run 29487150663
concluded `success`). `bigquery/67_ci_findings_bridge.sql` + the four workflow edits wire each guard
to also INSERT an open/resolved marker row into `ops.ci_findings`, consumed by `cadence_check.sql`
(raises/auto-resolves a `ci_finding` warning, emailed via the alert-emailer) and by D3's new
CI-FINDINGS ADJUDICATION step (`Claude_Task_Plan.md`). This grant is what makes the write actually
land — until it does, every INSERT no-ops with a `::warning::` annotation and the GH-issue path is
completely unaffected (no functional loss today).

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.ci_findings
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*` (it
already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds write
access to exactly one table). This is the **second instance** of the same narrow class already proven
live for `ops.routine_commit_markers` (item 3 below; rows `source='auto-merge-claude.yml'` verified
live 2026-07-14/07-15).

**If skipped:** workflows warn and behave exactly as today — the GitHub-issue finding/dedup/close path
is entirely independent of this grant.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_ci_findings_editor`, mirroring
`gh_ci_runner_routine_commit_markers_editor` — per the standing Terraform-is-spec-only decision
(`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

**Also needs a re-paste (folds into item B below, now further updated):** `bigquery/67`'s registry
MERGE bumps `state.expected_scheduled_query_versions`'s `cadence_check` row to `v4`; the live
`cadence_check` scheduled query needs the updated body (SQ_VERSION v3→v4 — since consolidated same
day with the CC-3/RES-4/CC-7 consumption-closure pass into ONE v4, not a further v5 — adds the
`ci_finding` raise/auto-resolve block, the `scheduled_query_version_drift` / `probe_funding_stalled` /
`cash_flows_backfill_broken` record-only warning blocks, `loop:research_quality_feedback` in both
dead-man UNNEST lists, and the `immediate_action_flagged`/`process_scorecard_signal` auto-age
additions) re-pasted in the same console session per `bigquery/README.md`'s convention — apply
`bigquery/67_ci_findings_bridge.sql` and `bigquery/68_cash_flows_backfill_check_dated.sql`, then
re-paste `cadence_check.sql` (single consolidated v4 body), since the registry bump is what keeps
`state.scheduled_query_version_drift` green afterward. **Also residual (not owner-blocked, but not
yet run this pass):** `bigquery/63_scheduled_query_version_registry.sql`'s MERGE seed row for
`cadence_check` was updated in-repo to `v4` with a consolidated git_note — a future BigQuery-MCP
session must re-run that MERGE statement live so `state.expected_scheduled_query_versions` matches
before the console re-paste below is checked against it.

---

# 2026-07-15 self-improvement audit (20 gaps + 5 architecture recommendations)

All 20 confirmed gaps + all 5 architecture recommendations are implemented, verified live, and
merged to this branch (`jack/pensive-fermi-jxha2b`) — see `bigquery/README.md` entries 57-66 and
`git log` for the full commit trail. Verified before writing this section: every item below was
checked against live BigQuery state / `gh` CLI output just now, not assumed from memory.

## A. Register `OPS0` as a live routine trigger (Gap 4 — Cadence Watchdog)

`OPS0. Cadence Watchdog` is a new regular routine (`Claude_Task_Plan.md`) with a full entry in
`ops/triggers.json`, but has no live trigger yet — confirmed via
`scripts/check_cadence_consistency.py`, which prints (non-fatally): *"ops/trigger_ids.json has no
entry yet for `['OPS0']`"*.

**AUTOMATED 2026-07-16 (resilience audit, RES-1/OAE-1 merge): this is no longer a required owner
action.** `Claude_Task_Plan.md`'s D3 section now carries a generalized TRIGGER SELF-REGISTRATION
step, and `OPS0`'s own STEP 2 item 3 now self-registers rather than paging the operator. On the
next live session that reaches either of those branches with `RemoteTrigger` access, it will:
verify no prior create already happened (checks `events.decision_log`
`entry_type='trigger-self-registration'` and `ops.catchup_refire_log` `outcome='trigger_created'`
first, so this is safe to leave to happen opportunistically — it will not double-create), then
call `RemoteTrigger create` with instruction = `ops/triggers.json`'s `OPS0` string verbatim and
cron `30 4 * * *` (fixed UTC = 10:30 PM MDT / 9:30 PM MST — deliberately inside the 21:00–24:00
America/Denver daily-miss visibility window year-round per `bigquery/48_cadence_monitor_unbounded.sql:52-59`,
and clear of the 05:15 UTC `cadence_check` scheduled-query snapshot; this slot is now recorded in
`ops/cadence.yaml`'s WEB-UI TRIGGER AUDIT block so the self-registration step's slot lookup does
not fail closed), record the returned id in `ops/trigger_ids.json`, log the decision, and raise an
info alert. This section remains only as the fallback if a `trigger_create_unsupported` or
`trigger_slot_unrecorded` warning ever fires, or if you'd rather not wait for an opportunistic
self-registration run.

**Manual fallback action, if you want it live sooner:** create a trigger the same way every other
routine trigger was created (RemoteTrigger `create` / Chrome console) — name
"OPS0. Cadence Watchdog — regular routine"; instruction/message content EXACTLY
`Read Claude_Task_Plan.md. Perform OPS0. Cadence Watchdog — regular routine.` (verbatim from
`ops/triggers.json` key `OPS0`); recurrence = a fixed-UTC daily cron `30 4 * * *` (10:30 PM MDT /
9:30 PM MST — do NOT use the native DST-aware Daily picker with a plain local time here, since an
API-created trigger stores a literal UTC cron, not a DST-relative local slot). Then record the
returned `trig_...` id in `ops/trigger_ids.json` (alphabetical, between `M5` and `Q1`) with
`"verified_via": "api"`, and run `python3 scripts/check_cadence_consistency.py` to confirm the
missing-entry NOTE disappears.

```verify
id: A
type: composite
probe: bq query "SELECT COUNT(*) n FROM `stock-trading-498512.ops.run_log` WHERE routine='OPS0' AND status='completed'" AND grep -q '"OPS0"' ops/trigger_ids.json
done_when: n>0 AND grep exits 0
```

## B. Apply the ARCH-1 scheduled-query wrapper migration, THEN paste the new one-line CALL bodies (Gap 12 — closes the re-paste class PERMANENTLY)

**SUPERSEDED (2026-07-16, ARCH-1 wrapper migration, `bigquery/75_scheduled_query_wrappers.sql`) —**
the prior version of this item asked you to re-paste each scheduled query's full body directly; that
would still leave every future edit needing another re-paste. Instead, all 12 scheduled-query bodies
have been frozen as one-line `CALL ops.sp_sq_<name>()` wrappers over stored procedures now defined in
`bigquery/75_scheduled_query_wrappers.sql` — once this migration is live + pasted, **no scheduled
query in this directory will ever need a console re-paste again**; future logic changes happen
entirely in `bigquery/75` + a `CREATE OR REPLACE PROCEDURE` applied via the BigQuery MCP.

**Step 1 (routine/session action, NOT yours — do not do this yourself):** a future MCP-enabled Claude
session must, in order: (a) run the two scratch pre-flight tests documented in `bigquery/75`'s header
(`EXPORT DATA` and `CREATE TEMP TABLE` each inside a throwaway stored procedure) — these were
deliberately NOT run live by the session that wrote `bigquery/75` (it operated under a no-BigQuery-
MCP-calls constraint this pass); (b) apply the 12 (or fewer, if either pre-flight test is rejected and
the affected procedure(s) are excluded — see that file's header for the exact fallback) `CREATE OR
REPLACE PROCEDURE` statements from `bigquery/75_scheduled_query_wrappers.sql` live; (c) apply the
edited `bigquery/63_scheduled_query_version_registry.sql` MERGE (new expected versions, `v2`
everywhere except `cadence_check` which is `v5`).

**Step 2 (your action, only AFTER step 1 is confirmed done — verify first:**
`SELECT routine_name FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.ROUTINES` WHERE routine_name
LIKE 'sp\_sq\_%'` **should list all the migrated `sp_sq_<name>` procedures):** re-paste each of the 12
`bigquery/scheduled_queries/<name>.sql` files' NEW one-line body (just `CALL
\`stock-trading-498512.ops.sp_sq_<name>\`();\`` plus its frozen header comment) into its existing
BigQuery Studio → Scheduled Queries entry (same paste-and-save flow as ever, `ops/RUNBOOK.md §1`):
`embed_pending`, `daily_freshness_check`, `cadence_check`, `integrity_check`,
`safety_critical_dml_watch`, `daily_staging_cap_check`, `backup_events_export`, `ops_export`,
`delivery_canary`, `restore_drill`, `fire_drill_order_guard`, `fire_drill_alert_lifecycle`.
`safety_critical_dml_watch` is not registered as a live scheduled query at all yet (2026-07-11 item
#2 below) — **create it fresh with this NEW one-line wrapper body**, not the old inline body, unless
that item's own note says the CREATE TEMP TABLE pre-flight was rejected (in which case use the old
inline body from that item, unchanged).

**If you paste Step 2 before Step 1 has actually happened:** the `CALL` errors (the procedure doesn't
exist yet) and the notify-enabled jobs email you — fail-visible, not a silent regression, by design
(`bigquery/75`'s SEQUENCING note).

After both steps: `SELECT * FROM state.scheduled_query_version_drift` should show `drift = FALSE` /
`monitored = TRUE` for every migrated wrapper within a day. **If skipped:** no functional loss — each
query keeps running its OLD inline body exactly as before (nothing here changes live behavior on its
own); you just won't get body-drift detection until both steps happen (self-bootstrapping:
`monitored` stays `FALSE`, no false alarm).

```verify
id: B
type: bq
probe: SELECT COUNTIF(monitored AND NOT drift) n FROM `stock-trading-498512.state.scheduled_query_version_drift`
done_when: n=12
```

## C. GCP IAM grant — dashboard build liveness heartbeat (Architect recommendation #3)

`ops/dashboard/generate_dashboard.py` now best-effort-writes `ops.heartbeat(source='dashboard')` at
the end of a successful build (`bigquery/58_dashboard_heartbeat.sql`), but the workflow's
`gh-ci-runner@` WIF identity is read-only today, so the write silently no-ops until granted:
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.heartbeat
```
Table-scoped — `gh-ci-runner@` gains write access to exactly `ops.heartbeat`, nothing else.
**If skipped:** the dashboard keeps publishing exactly as before; `'dashboard'` just never appears
as `monitored` in `state.automation_heartbeat`, which is the correct fail-quiet default, not a bug.

**Prerequisite mini-edit (already landed, OAE-5 2026-07-16):** `ops/dashboard/generate_dashboard.py`'s
heartbeat write now appends `' (ci)'` to the note when `GITHUB_ACTIONS=='true'`, so a scheduled/CI
build is deterministically distinguishable from a session-window build — replaces the fragile
hardcoded `EXTRACT(HOUR)=7` heuristic (the dashboard cron is 05:20Z but observed delayed starts run
07:21-07:33Z). No owner action for this part; the grant above is still needed for either version of
the note to land live.

```verify
id: C
type: bq
probe: SELECT COUNT(*) n FROM `stock-trading-498512.ops.heartbeat` WHERE source='dashboard' AND note LIKE '% (ci)%' AND beat_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
done_when: n>0
```

## D. Re-enable `alert-relay.yml` (currently `disabled_manually`)

**Checked live** (`gh workflow list --all`): `Alert relay (webhook push)` shows
`disabled_manually`. Claude's auto-mode permission classifier correctly declined to re-enable a
manually-disabled GitHub Actions workflow via `gh api -X PUT .../enable` on its own — that's a
platform-state change outside "implement my recommendations" authorization, not a bug.

**UPDATE 2026-07-16 (OAE-6, self-provisioned second channel) — this is now a ONE-PASTE job, not
three separate owner decisions.** `scripts/alert_relay.py`'s `post()` now has a plain-text branch for
`ntfy.sh` (self-provisioned, capability-URL push topic — no signup, no owner-run webhook endpoint to
stand up) — see item E below for why this shrinks the remaining owner surface to "run these 4
commands, then subscribe on your phone." This session's own hard ground rules for this pass forbid
running `gh secret set` / `gh workflow enable` / any other mutating `gh`/`gcloud`/`bq` command itself
(local-only implementation round — commands land here as text, not as executed actions), so the
commands below were deliberately NOT run this pass; they are exactly what the OAE-6 spec would have
run automatically had this round's ground rules allowed a live gh-mutation this time.

**Action — run once, with your own `gh` credentials (or in a future session explicitly authorized to
run mutating `gh` commands):**
```bash
TOPIC="stock-trading-$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
gh secret set ALERT_WEBHOOK_URL --body "https://ntfy.sh/$TOPIC"
gh workflow enable "Alert relay (webhook push)"
curl -s -d "channel test — subscribe me" -H "Title: Stock-Trading" "https://ntfy.sh/$TOPIC"
gh workflow run "Alert relay (webhook push)" -f mode=heartbeat
```
The `-f mode=heartbeat` flag is REQUIRED: the dispatch default (`mode=alerts`) deliberately swallows a
POST failure (`alert_relay.py`'s best-effort design), so a default-mode green run proves nothing;
`heartbeat` is the one mode whose POST failure fails the run — the only way to actually prove the new
ntfy topic works end to end. Confirm the dispatched run is green (`gh run list
--workflow="Alert relay (webhook push)" -L1`), then note the topic URL and subscribe to it (ntfy app,
or open the URL in a browser) — that's the entire remaining human step; see item E below for the
follow-up durable in-band notice this system will send once it can see the secret is set.

```verify
id: D
type: gh
probe: gh api "repos/${GITHUB_REPOSITORY}/actions/workflows" --jq '.workflows[] | select(.path==".github/workflows/alert-relay.yml") | .state'
done_when: output == 'active'
```

## E. Add 3 missing GitHub Actions secrets

**Checked live** (`gh secret list`): zero repo secrets exist today. Three are referenced across
workflows and are all currently no-ops without them (each usage is already guarded/best-effort —
nothing fails from their absence, they just don't do anything):
- `ALERT_WEBHOOK_URL` — **UPDATE 2026-07-16 (OAE-6):** the code side is DONE — `scripts/alert_relay.py`
  posts plain text (not JSON) when `WEBHOOK_URL` contains `ntfy.sh`, covered by
  `tests/test_alert_relay.py`'s new ntfy-branch unit test; `scripts/notify_webhook.sh` (used by the
  offsite/keyless/wif audits) got an optional readability branch for the same case, documented as a
  best-effort JSON-string delivery otherwise (see that script's header). What's left is
  self-provisioning the actual secret (capability-URL model, 128-bit random topic name, no signup, no
  owner-run endpoint) — see item D's 4-command block above, which sets this secret as its first step.
  To upgrade to an authenticated/self-hosted endpoint later, just replace the secret value; nothing
  else in the pipeline needs to change. Once set, a durable in-band notice
  (`ops.sp_raise_alert('warning', 'OPS', 'second_channel_ready', ...)`, emailed by `alert_emailer.gs`
  since `warning` is in its `SEVERITIES` list) should be raised via the BigQuery MCP/console in a
  future session, pointing at the actual `https://ntfy.sh/<topic>` URL to subscribe to — this session
  made no live BigQuery calls (local-only round) so it was not raised yet.

```verify
id: E-webhook
type: env
probe: read HAS_ALERT_WEBHOOK_URL (workflow exports secrets.ALERT_WEBHOOK_URL != '' — a workflow token cannot `gh secret list`)
done_when: == 'true'
```
- `OFFSITE_BACKUP_GCS` — read by `guard-config-audit.yml`, `offsite-backup.yml`. A GCS destination
  (bucket/path) for the offsite backup export; without it, `offsite-backup.yml` presumably no-ops or
  fails its own step — worth checking that workflow's recent run history once this is set. Genuinely
  owner-owned external resource — not self-provisionable the way the webhook topic above is.

```verify
id: E-offsite
type: env
probe: read HAS_OFFSITE_BACKUP_GCS
done_when: == 'true'
```
- `ANTHROPIC_API_KEY` — read by `golden-scenarios.yml`. Without it, the workflow's `HAVE_KEY` check
  reads false and (per that workflow's own design) it falls back to a documented lower-fidelity mode
  rather than failing — check that workflow's file for the exact fallback behavior before assuming
  urgency here. Genuinely owner-owned external resource.

```verify
id: E-anthropic
type: env
probe: read HAS_ANTHROPIC_API_KEY
done_when: == 'true'
```
**If skipped:** every consumer above already fails closed/quiet without these — nothing is silently
broken; `OFFSITE_BACKUP_GCS`/`ANTHROPIC_API_KEY` unlock functionality that's currently inert, not fix
something currently wrong. `ALERT_WEBHOOK_URL` is now a single 4-command paste (item D) plus a phone
subscribe tap, not three separate decisions.

## F. Resolved — BigQuery per-user daily query quota was hit during this session (no action needed)

**Transient, self-cleared within ~10 minutes — checked live, confirmed resolved.** The
`dbt↔live row-level parity (keyless WIF)` CI job failed on 2 pushes in a row this session with
*"Custom quota exceeded: Your usage exceeded the custom quota for QueryUsagePerUserPerDay, which is
set by your administrator"* — a BigQuery cost-control quota you (or a prior setup pass) configured,
not a code bug; every other CI job on both runs passed. Because the repo var `DBT_PARITY=block`
(`gh variable list`) deliberately makes this job a hard merge gate (`.github/workflows/ci.yml` —
`continue-on-error: false` when set), the whole `CI` run read as failed and auto-merge correctly
declined to merge 3 commits for a short window — exactly as `DBT_PARITY=block` is designed to do.
Almost certainly caused by this session's own unusually heavy live-verification query volume (every
gap in this pass was checked against live BigQuery before and after applying) hitting a
`QueryUsagePerUserPerDay` ceiling. The very next push's `dbt↔live row-level parity` run came back
green (headroom freed up / quota window rolled over), and the existing auto-merge automation caught
up the whole backlog in one shot: `git merge-base --is-ancestor <branch tip> origin/main` now returns
true — `main` is fully current through this session's last commit. **Action: none.** Documented here
only so a future session doesn't need to re-diagnose the same transient failure if it recurs; if
`dbt↔live row-level parity` starts failing repeatedly with this exact message on ordinary
(non-audit-scale) pushes going forward, raise the custom quota at
https://docs.cloud.google.com/bigquery/redirects/increase-query-cost-quota. Do not weaken
`DBT_PARITY=block` to work around a recurrence — it caught a real resource ceiling correctly here,
not a misfire.

**RE-VERIFIED LIVE 2026-07-16 (OAE-5 owner-selfservice audit — the original audit spec for this item
assumed a same-day recurrence; checked against live `gh`/`git` state instead of trusting that
snapshot):** `dbt↔live row-level parity` run 29469270140 did fail once more with this exact quota
message, but the very next run (same commit range) came back green, and both `85c18c1` (this
section's earlier "Mark resolved" commit) and `d06ce71` are now confirmed `git merge-base
--is-ancestor`-true against `origin/main` — the backlog is merged, matching this section's "Resolved"
framing above, not a still-open recurrence. The verify fence below auto-closes on that same
already-true condition the first time the scheduled verifier runs.

```verify
id: F-quota
type: repo
probe: git fetch origin main --quiet && git merge-base --is-ancestor 85c18c1 origin/main
done_when: exit 0
```

---

# Owner actions — 2026-07-11 self-improvement audit (Items 1-30)

**RESOLVED (checked live 2026-07-16, OAE-5 owner-selfservice audit):** the billing-failure symptom
below is gone — every CI run today (`gh run list`) completes normally, the branch's backlog has been
draining via auto-merge all day (most recently 2026-07-16T19:22Z), and `main` is fully current through
this session's predecessor commits. No action needed on the billing item itself; kept below for the
historical record.

**Symptom (as of 2026-07-11):** every CI job on the working branch fails immediately with *"The job
was not started because recent account payments have failed or your spending limit needs to be
increased."* This is not a code or workflow problem — it's your GitHub account's billing state.

**Action:** GitHub → **Settings → Billing & plans** → fix the payment method / raise the spending
limit. Nothing is broken in the meantime: the auto-merge gate correctly reads a billing-failed run as
CI failure and skips the merge (fail-closed, per `tests/test_auto_merge_logic.sh`), so no commit gets
merged without green CI. One commit (`d58c7cc`, the Item 29 closing note — documentation only, zero
schema/live-data impact) is currently stuck on the branch waiting for this fix. Once billing is
resolved, either re-run the failed workflow from the Actions tab, or push an empty/trivial commit to
retrigger CI — it should merge cleanly on the next green run.

---

## [DONE 2026-07-16 — auto-verified] 1. Apps Script re-pastes (script.google.com — Claude cannot reach this surface)

  *(auto-verified 2026-07-16: state.script_version_drift shows alert_emailer v1=v1, weekly_report
  v3=v3, both monitored, drift=FALSE — the re-pastes described below already happened live.)*

Two scripts changed this session. Both are in the **"Stock-Trading Automation"** Apps Script project
(see `ops/RUNBOOK.md` / memory `reference_apps_script_project`). For each, open the project at
script.google.com, open the named file, select all, paste the repo's current version, save, and
(if prompted) redeploy. Prefer pasting the **whole file** over hand-editing — the repo copy is the
source of truth and a partial edit risks drifting from it.

- **`ops/monitoring/alert_emailer.gs`** — two changes bundled in:
  1. **(Item 17)** A new recurring re-select for `termination_close_staged` alerts: unlike every other
     alert (emailed once via `notified_ts`), a staged DRAWDOWN/m2m-termination close order now keeps
     re-appearing in the ~2h poll (distinct subject marker) until D2a's fill reconciliation resolves
     it — so a dismissed/missed push notification for a termination close can't go silently unfollowed
     the way it could before this session.
  2. **(Item 23)** A `SCRIPT_VERSION = 'v1'` constant, reported in the script's existing
     `ops.heartbeat` beat. Lets `state.script_version_drift` (see item 2 below) detect if a future
     repo change to this file is ever deployed *without* being re-pasted.
  - Verified: `node --check` clean on the repo copy.

- **`ops/weekly_report/weekly_report.gs`** — **(Item 23)** the same `SCRIPT_VERSION = 'v1'` constant +
  heartbeat report, no other functional change this pass.

**Why this matters if skipped:** nothing breaks — `state.script_version_drift` just won't have
anything to compare against yet (self-bootstrapping: it never fires until a script has reported a
version at least once), and Item 17's stronger termination-close alerting simply doesn't take effect
until the paste happens. The existing one-shot alert still fires either way.

---

## 2. Register a new scheduled query — `safety_critical_dml_watch.sql` (Item 6)

**What it does:** every 6h, RAISEs (fails the job → BigQuery's built-in failure email) and writes a
critical `ops.alerts` row if anything ran a raw `UPDATE`/`DELETE`/`MERGE`/`TRUNCATE` against
`ops.trading_control`, `ops.arsenal_control`, `events.strategy_lifecycle`, or `perf.strategy_daily` in
the last 24h — the four tables that are supposed to be mutated only by `INSERT` (or, for
`perf.strategy_daily`, only by the one named nightly rebuild). This is the compensating detective
control for the fact that every routine shares one owner-OAuth principal, so IAM alone can't prevent
an out-of-band mutation.

**Action (BigQuery Studio → Scheduled queries → Create, same flow as every other scheduled query in
`ops/RUNBOOK.md` §1):**
1. Paste `bigquery/scheduled_queries/safety_critical_dml_watch.sql` — **as of the ARCH-1 wrapper
   migration (2026-07-16, §B above) this is now the frozen one-line `CALL
   \`stock-trading-498512.ops.sp_sq_safety_critical_dml_watch\`();\`` body, NOT the old inline
   check text**, PROVIDED §B's Step 1 (the `CREATE TEMP TABLE`-in-a-procedure pre-flight test) has
   already passed and `ops.sp_sq_safety_critical_dml_watch` exists live. If that pre-flight was
   rejected (see `bigquery/75_scheduled_query_wrappers.sql`'s header / `bigquery/scheduled_queries/
   README.md`), paste the file's OLD inline body instead (still in git history / that file's
   pre-migration content) — functionally identical either way, just not on the frozen-wrapper path.
2. Schedule: every 6 hours. Location: US.
3. Run as: the **same service account you already use for `integrity_check.sql`** — it needs
   `roles/bigquery.resourceViewer`, which that SA should already have, so **no new IAM grant is
   needed if you register it under the same identity**.
4. Under Notifications, enable **"Send email on failure"** — the query RAISEs on a real hit, so that
   email *is* the alert.

```verify
id: sq-dml-watch
type: bq
probe: SELECT COUNTIF(monitored) n FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE sq_name='safety_critical_dml_watch'
done_when: n=1
```

**`[DECISION / not auto-verifiable — no verify block]`**

**Optional, one-time hardening — independent 2nd alert channel (Cloud Monitoring):** so a dead/broken
scheduler can't also silence the DML alarm. Full 5-step console procedure (enable BigQuery Data
Access audit logs → build the Logs Explorer filter → create a logs-based alert policy → optional
fire-drill to confirm the exact audit-log field names → document the finished policy in
`infra/terraform/monitoring.tf` as spec) is written out in `ops/RUNBOOK.md` §15, "2nd channel (owner
action, one-time, Cloud Monitoring console)". Not required for the primary channel (step 1-4 above) to
work; do this whenever convenient.

---

## [DONE 2026-07-16 — auto-verified] 3. GCP IAM grant — let CI self-heal a missed `ops.run_log` write (Item 3, RUNBOOK §38)

  *(auto-verified 2026-07-16: ops.routine_commit_markers has rows with source='auto-merge-claude.yml'
  dated 2026-07-14/07-15 — the grant below is live and the CI marker write works.)*

**What it's for:** closes the 2026-07-06..08 incident class where a routine's real output lands on
`main` but its `ops.run_log` completion write never happens (harness session-lifecycle issue, not a
repo bug — root cause is outside this repo's visibility). The fix already runs today as a **manual**
backfill when caught; this grant lets CI do it **automatically** on every merge instead.

**Action — run once, with your own `gcloud`/`bq` credentials:**
```
bq add-iam-policy-binding \
  --member="serviceAccount:gh-ci-runner@stock-trading-498512.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" \
  stock-trading-498512:ops.routine_commit_markers
```
This is a **table-scoped** grant — `gh-ci-runner@` stays read-only everywhere else in `ops.*`
(it already has `jobUser`/`dataViewer`/`connectionUser` project-wide per RUNBOOK §6/§15; this adds
write access to exactly one table). It cannot reach `ops.run_log` or `ops.alerts` directly — only
`ops.sp_backfill_run_log_from_markers()` (run under your own identity, like every other procedure)
actually writes those, off the marker rows this grant lets CI insert.

**If skipped:** no functional loss today. `auto-merge-claude.yml`'s marker-write step no-ops/warns
cleanly without this grant, and the existing manual-backfill fallback (`ops.sp_backfill_run_log_from_markers()`
called by hand, or by the nightly `cadence_check.sql` pass) is fully intact either way — this grant
only removes the "manual" part.

The grant's scope is also declared (never applied) in `infra/terraform/iam.tf` as
`google_bigquery_table_iam_member.gh_ci_runner_routine_commit_markers_editor`, purely so its blast
radius is reviewable in-repo before you run the command above — per the standing Terraform-is-spec-only
decision (`CLAUDE.md`), do NOT `terraform apply` this file; the `bq` command above is the real grant.

---

## 4. Elect (or confirm) your IBKR cost-basis method (Item 18) — `[DECISION / not auto-verifiable — no verify block]`

**What changed:** `analytics.tax_lots` / `state.wash_sale_exposure`
(`bigquery/41_tax_lots.sql`) now detect account-wide wash sales (a same-ticker BUY within 30 calendar
days of ANY strategy's loss-realizing SELL — checked across strategies, not just within one, since the
IRS wash-sale rule is a taxpayer-level rule and this system now runs up to 8 independent strategies
that can legitimately trade the same ticker). This is **detection/reporting only** — IBKR's own
1099-B, computed off your account's actual elected method, remains the authoritative tax figure.

**Action:** this repo's lot construction assumes **FIFO** (the typical IBKR default) purely to build
its own internal lots. If you have elected — or ever elect — a different method with IBKR (e.g.
specific-lot ID), say so explicitly (in chat, or by editing `Experiment_Parameters.md`'s tax-lot
caveat note directly) — otherwise `analytics.tax_lots` will silently diverge from your broker's own
lot-by-lot 1099-B accounting (total shares/proceeds still reconcile either way, just not lot-by-lot).
If you're already on FIFO / haven't touched the election, no action needed — this is a "confirm or
correct an assumption," not a blocking requirement.

---

## 5. Read and decide — Agent SDK / headless-harness migration (Item 26, informational) — `[DECISION / not auto-verifiable — no verify block]`

`ops/spikes/agent-sdk-orchestration-2026Q3.md` is a feasibility report (no repo/live changes) on
moving routines off the interactive claude.ai web-UI onto a headless, scheduled harness. Bottom line:
**conditional GO for a D1-only pilot** (read/judgment-only, no IBKR orders), **unconditional NO-GO**
for anything that calls the IBKR connector until a separate spike resolves headless IBKR auth (no
first-party OAuth path exists today; the unofficial local-execution-only community IBKR MCP servers
are explicitly unsuited for real-money order placement without a dedicated security review this spike
doesn't attempt). This is a **decision for you, not an action required** — nothing changes unless you
say to proceed with the D1 pilot. Item 29 (a "thin order gateway" for mechanically enforcing the
order-guard before every IBKR order) is downstream of this and stays closed (see `ops/RUNBOOK.md` §40)
until this spike's IBKR gap is separately resolved.

**CORRECTED 2026-07-11 (owner fact-check) — the spike's cost-neutrality claim was wrong.** The spike
originally claimed migrating a routine's token cost was "unchanged, not a new cost line" because a
2026-06-15 Anthropic billing change already moved headless/Agent-SDK usage onto a separate API-rate
credit. That change was **paused before taking effect** — Anthropic's own Help Center confirms headless/
Agent-SDK usage still draws from the owner's Claude **subscription** limits today, not a metered pool.
Separately, the harness in (b) would call Claude via the **Managed Agents API** — a different product
surface from the subscription login, billed at standard per-token API rates with no subscription
discount. So piloting D1 on this harness would very likely convert D1's token cost from "bundled into
the flat subscription" to "real, metered API dollars per run" (one estimate: subscription pricing
subsidizes agent usage ~15-30x vs. API rates) — the opposite of the original "near-zero, cost-neutral"
framing. Also worth noting: the original urgency case for this migration (fixing the §38 run_log gap)
is now moot regardless of cost — Item 3 (this same 2026-07-11 session) closed that gap for free with no
migration needed (`ops/RUNBOOK.md` §38). Get an actual per-token cost estimate before deciding to pilot;
see the corrected `ops/spikes/agent-sdk-orchestration-2026Q3.md` (c) for detail.

---

## Not an owner action — flagged for the record

- **Item 30b** (deferred, not attempted this pass): collapsing the routine-list hand-copy-then-CI-check
  pattern across `bigquery/12/15/24` + `Claude_Task_Plan.md`'s ROUTINE INVENTORY table into a
  generator off `ops/cadence.yaml`. Genuine refactor with real risk of breaking the cadence-consistency
  CI gate if rushed — explicitly scoped as a future engineering follow-up, not something you need to
  do or decide.
- **`AI_Trading_Foundation.md`'s in-use-Claude-version field** (Item 30a) is now flagged rather than
  silently overwritten (this repo can't query which model a web-UI session actually ran on) — it will
  resolve itself via the document's own existing version-change protocol at the next Q3/A1 cycle; no
  action needed from you specifically.

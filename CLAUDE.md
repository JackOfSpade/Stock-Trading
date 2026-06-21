# Project notes for Claude

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

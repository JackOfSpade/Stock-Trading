# Agent SDK orchestration feasibility spike — 2026 Q3

**Item 26.** Status: **REPORT ONLY — no repo/live changes besides this file.** This is a feasibility
writeup for the owner to decide on, not a migration and not a proposal in progress. Nothing here changes
`ops/cadence.yaml`, any live BigQuery object, or any web-UI trigger. Author: Claude (agent), 2026-07-11.

**Read first (this report assumes and cites):** `ops/RUNBOOK.md` §15 (Operational identity & credential
resilience), `ops/cadence.yaml` (header + the 2026-07-10 web-UI trigger audit block),
`BigQuery_System_Redesign_v2.md`, `ops/RUNBOOK.md` §38 (`ops.run_log` completion write silently skipped).

**Scope note on "Items 3-4."** This task packet refers to two other in-flight review items ("Items 3-4")
as already neutralizing §38's worst symptom. Those items are not artifacts inside this repo (no file here
enumerates a numbered task list beyond `ops/RUNBOOK.md`'s own §-numbering), so this report treats that
claim as given context from the task brief rather than something independently verified against a repo
artifact — see part (e) for how it's used and why it doesn't change this spike's conclusion either way.

---

## Executive summary

- **(a)** The five MCP connectors this system uses today (`claude_ai_Interactive_Brokers_IBKR`,
  `claude_ai_Gmail`, `claude_ai_Google_Calendar`, `claude_ai_FMP`, `claude_ai_Tavily`) are **claude.ai
  product-managed, per-user delegated-OAuth connectors** — confirmed against current Anthropic docs, not
  assumed. They are **not** reachable from a headless process outside claude.ai. Moving any of D1-D3
  outside claude.ai requires **provisioning entirely new, separate credentials** for each external
  service, not "pointing the same connector" at a different runtime. Anthropic's separate **Claude
  Managed Agents API** (beta, header `managed-agents-2026-04-01`) is a genuinely headless, cron-schedulable
  product with a **Vaults** credential mechanism built for exactly this — but it is its own onboarding
  project per connector, and for **IBKR specifically there is no clean first-party OAuth path today** (see
  (a) for detail). Gmail/Calendar/FMP/Tavily are each a moderate, boundable lift; IBKR is the long pole.
- **(b)** A Cloud Scheduler → Cloud Run job harness whose **own wrapper code** (not the agent's own tool
  calls) writes the terminal `ops.run_log` row in a `try/finally` makes the exact §38 failure class
  (real output landed, zero `ops.run_log` rows) **structurally impossible** for any reason internal to the
  agent's session (token/context cutoff, container reclamation mid-reasoning) — because the write no longer
  depends on the agent remembering to make one more MCP call. Cloud Scheduler natively supports IANA
  timezones with correct wall-clock DST semantics and arbitrary POSIX cron (including month-of-year),
  which kills the two structural bugs `ops/cadence.yaml` documents as **permanent platform limitations** of
  today's web-UI trigger picker (no month/quarter recurrence type; UTC-only fixed-hour Custom cron; the
  ~6h-early bug fixed by hand 2026-07-10). `ops.sp_assert_deps` stays exactly as-is, called by the harness
  before it even starts the agent — defense-in-depth, cheaper (fails before spending any tokens), and
  unchanged in its fail-closed semantics.
- **(c)** Marginal infra cost is **near-zero** (Cloud Scheduler + Cloud Run job compute both sit inside
  free tiers at this system's run volume). Model-token cost does not change — these routines already run
  as headless Claude-Code-on-Web sessions, already billed on the separate Agent SDK/API-rate credit since
  the 2026-06-15 billing change, not on interactive chat limits. The real cost is one-time **engineering
  + credential-provisioning effort**, concentrated entirely in the IBKR leg.
- **(d) GO** (conditional) for a **D1-only** pilot, web-UI D1 trigger **paused, not deleted**, as fallback.
  D1 is read/judgment-heavy and places no IBKR orders, so it fully exercises the run_log/cadence fix and
  the non-IBKR credential-provisioning question while completely sidestepping the IBKR headless-auth
  problem. Do **not** extend the pattern to D2/D2a or any order-placing routine until IBKR headless auth is
  separately resolved (out of scope here).
- **(e)** Per this task's own framing, "Items 3-4" already reduce §38's worst symptom independent of this
  migration. Separately verifiable in-repo: RUNBOOK §38's own 2026-07-09 hardening already shrank a
  recurrence's cleanup to "a bare `ops.run_log` backfill, no manual alert UPDATE." That **lowers the
  urgency of migrating specifically to fix §38** — the stronger, unmitigated-today justification for this
  migration is the cadence.yaml UTC/DST bug class and the missing month/quarter recurrence type, which have
  **no existing mitigation** the way §38 now does.

---

## (a) Can the IBKR/Gmail/Calendar/FMP/Tavily MCP connectors be invoked from a headless Agent SDK process OUTSIDE claude.ai?

**Short answer: not as configured today. Plainly: this is a different-design problem, not a
different-runtime problem, for moves 1-3 (D1/D2a/D2) as long as they touch the connectors this system
uses.**

### What these connectors actually are

RUNBOOK §15's own framing already flags this ("the connectors appear to be claude.ai-managed interactive
OAuth grants") and current Anthropic documentation confirms it directly: **"Connectors use per-user
delegated OAuth, with data flowing between the in-boundary MCP proxy and the connected service using the
individual user's credentials."** [Claude connector authentication](https://sunpeak.ai/blogs/claude-connector-oauth-authentication/),
[Authentication for connectors](https://claude.com/docs/connectors/building/authentication). This proxy is
scoped to the claude.ai consumer product surface. Directly confirming the boundary in both directions,
Anthropic's own MCP tunnels documentation states: **"MCP tunnels created through the Console are not
available as connectors in claude.ai."** [MCP tunnels](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview)
— i.e., the two surfaces (claude.ai Connectors vs. the API/Managed-Agents world) are deliberately siloed,
not two views onto the same OAuth grant. There is no documented path to reuse a claude.ai per-user
connector grant from an API-driven session.

### What a headless option actually looks like today

Anthropic ships a genuinely separate, headless, API-first product for exactly this shape of work: **Claude
Managed Agents** (beta header `managed-agents-2026-04-01`), which supports:
- **Scheduled deployments** — native cron (`schedule.type: "cron"`, standard POSIX 5-field expression) +
  an explicit **IANA timezone** field, with documented correct wall-clock DST handling ("Cron schedules use
  literal wall-clock matching, so `0 20 * * *` in `America/New_York` fires at 8PM local time regardless of
  whether EST or EDT is in effect"). [Scheduled deployments](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)
- **Vaults** — a credential store separate from claude.ai's connector OAuth, supporting `mcp_oauth`
  (stores an access+refresh token pair, auto-refreshed by Anthropic on your behalf), `static_bearer` (a
  fixed API key/token), and `environment_variable` (egress-only secret substitution for direct API/CLI
  calls, so the model's own context never sees the raw secret). [Vaults](https://platform.claude.com/docs/en/managed-agents/vaults)
- **MCP tunnels** (research preview) — lets a Managed Agents session reach an MCP server running inside
  your own private network over an outbound-only Cloudflare-backed tunnel, with per-server OAuth/bearer
  auth independent of the tunnel itself. [MCP tunnels](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview)

This is a real, usable headless surface — but every credential in it must be **provisioned fresh**, it is
not a bridge to the claude.ai connector grants already sitting in RUNBOOK §15's credential table. Per
external service:

| Connector today | Headless equivalent effort | Notes |
|---|---|---|
| **Tavily** (web search) | Low | Tavily issues a plain API key; drops into a `static_bearer`/`environment_variable` Vault credential directly. |
| **FMP** (market data) | Low | Same — FMP is API-key auth, no OAuth dance needed. |
| **Google Calendar** | Moderate | Needs a fresh Google Cloud OAuth client + one-time interactive consent to mint an access+refresh token pair, stored as an `mcp_oauth` Vault credential (Anthropic auto-refreshes thereafter). This is new setup, not a reuse of the existing claude.ai Google grant — RUNBOOK §15's existing "Owner Google OAuth" row is the claude.ai one and is out of reach here. |
| **Gmail** (draft-only today) | Moderate | Same Google OAuth mechanics as Calendar; can share the same OAuth client/consent if scoped together. |
| **IBKR** (fills/positions/quotes/order-craft) | **High — the long pole** | IBKR has no first-party OAuth2 the way Google/Slack do; the connector today is a brokerage session/token per IBKR's own policy, periodically re-auth'd (RUNBOOK §15's own credential table already documents this: "session/token per IBKR's policy; can require periodic re-auth"). Unofficial community IBKR MCP servers exist with a "headless mode" (stored credentials + TOTP-2FA override), but their own documentation is explicit that they are **"strictly designed for local execution... never run on public servers"** — precisely the deployment shape (an internet-reachable Cloud Run job) this spike is sketching, which makes them an inappropriate fit for real-money order placement without a much deeper security review this spike does not attempt. [Interactive Brokers MCP server](https://github.com/code-rabi/interactive-brokers-mcp) |

**Plain statement per the task's ask:** because the live connectors are claude.ai-managed OAuth, **moves
1-3 (D1, D2a, D2 — anything that reads/writes via IBKR, Gmail, Calendar, FMP, or Tavily) need a different
design, not a lift-and-shift, if they migrate off claude.ai.** For Tavily/FMP that different design is
cheap (an API key in a Vault). For Calendar/Gmail it is a bounded one-time OAuth-app setup. For **IBKR it
is genuinely unresolved** — this spike does not recommend a path for headless IBKR order placement, and
recommends the pilot scope in (d) be chosen specifically to avoid needing one yet.

---

## (b) Sketch: Cloud Scheduler + minimal Agent SDK harness (Cloud Run job)

### Why this shape

The core idea the task asks for: move the `ops.run_log` terminal write **out of the agent's own tool-call
trace and into deterministic wrapper code that always runs**, so §38's failure mode (the agent's own
run_log MCP call never happening because the session died first) cannot recur structurally, and use a
scheduler with real IANA-timezone cron so the two documented `ops/cadence.yaml` platform limitations
(no month/quarter recurrence type; UTC-only fixed-hour Custom cron, previously off by ~6h until the
2026-07-10 hand-fix) stop being permanent-accepted limitations.

### Components

```
Cloud Scheduler job "d1-trigger"
  schedule: cron expression, IANA tz "America/Denver" (native — no UTC translation needed)
  target: HTTP POST to a Cloud Run job execution (OIDC-authenticated, Scheduler's own service
          identity — NOT the operator's interactive OAuth, closing the RUNBOOK §15 "monitor
          identity == agent identity" gap for this routine's trigger specifically)
        |
        v
Cloud Run job "routine-harness" (container, per-routine or parameterized by routine id)
  run_date := today in America/Denver (computed IN the harness, not passed by cron, so a
              late-firing execution still resolves the correct trading day)
  session_id := a fresh UUID minted by the harness (replaces the ad-hoc session identifiers
                routines self-report today)
  branch := harness-controlled (same auto-merge branch-naming convention as today)

  try:
      # 1. FATAL dependency gate — unchanged procedure, called by the HARNESS before spending
      #    any agent tokens (strictly cheaper than today, where a dependency-gated routine still
      #    burns a session's opening tokens before hitting the RAISE inside the SQL call).
      bq_client.query("CALL `stock-trading-498512.ops.sp_assert_deps`('D1', [], @run_date)")
      #    ^ unchanged signature, unchanged fail-closed RAISE + critical alert. Kept as
      #      defense-in-depth exactly as instructed — this file does not touch 12_cadence_monitor.sql.

      # 2. Best-effort start log — same as today's sp_routine_start, but the HARNESS calls it,
      #    not the agent, so the row exists before a single agent token is spent.
      bq_client.query("CALL `stock-trading-498512.ops.sp_routine_start`('D1', @run_date,
                        @session_id, @branch, 'Read Claude_Task_Plan.md. Perform D1. ...')")

      # 3. Run the agent. This is the ONLY step that can be long, slow, or interrupted.
      result = agent_sdk.query(
          prompt=canonical_instruction_text,       # identical text to today's web-UI trigger,
                                                     # preserving state.routine_last_instruction
                                                     # drift-detection parity (RUNBOOK §22/§24)
          mcp_servers=[...],                        # per (a): NOT the claude.ai connectors —
                                                     # freshly provisioned Vault-backed equivalents
          max_turns=..., timeout=...,
      )
      status, rows_written, error_msg = interpret(result)   # 'completed' | 'failed'

  except Exception as e:
      status, error_msg = 'failed', str(e)          # covers SDK timeout, tool error, crash —
                                                      # anything that reaches Python still lands here

  finally:
      # 4. THE FIX: this call is unconditional. It runs whether step 3 succeeded, raised, or
      #    timed out mid-stream — the one property §38 shows the current architecture lacks,
      #    because there the terminal write is just another MCP call INSIDE the same agent
      #    session that might not reach it. Here it is ordinary host-language control flow the
      #    LLM cannot skip by running out of budget.
      bq_client.query("CALL `stock-trading-498512.ops.sp_routine_end`('D1', @run_date, @status,
                        @session_id, @branch, @rows_written, @error_msg, @note)")
```

### What this does and does not fix

- **Fixes structurally:** a §38-shaped "real output landed, zero `ops.run_log` rows" strand for any
  failure whose root cause lives *inside* the agent SDK call (context/token cutoff, an unhandled tool
  exception, a hang past `timeout`). The `finally` block is the mechanism; it needs no new BigQuery DDL —
  `ops.sp_routine_end` already exists (`bigquery/12_cadence_monitor.sql`) and is reused unmodified.
- **Kills the cadence.yaml bug class, not just documents around it:** `ops/cadence.yaml`'s own header
  records the monthly/quarterly/annual cohort as "forced onto raw Custom cron... no timezone concept, just
  a fixed UTC hour... PERMANENT PLATFORM LIMITATION" and the Q1-4/SL1/A1-3 cohort as having fired ~6h early
  until a 2026-07-10 hand-fix. Cloud Scheduler's cron **has** a month field and **does** accept an IANA
  timezone natively (confirmed against Anthropic's own scheduled-deployments doc showing the identical
  primitive: `"schedule": {"type": "cron", "expression": "0 20 * * 5", "timezone": "America/New_York"}` —
  same POSIX-cron-plus-IANA-tz shape GCP's Cloud Scheduler uses). A quarterly routine becomes an ordinary
  cron expression (`0 18 1 1,4,7,10 *` for "1st of Jan/Apr/Jul/Oct at 18:00 local") with no synthetic
  UTC-offset math and no recurring MST/MDT hand-correction.
- **Does NOT fix, and does not need to:** `ops.sp_assert_deps` stays exactly as-is (unmodified procedure,
  unmodified fail-closed RAISE) — kept as defense-in-depth per the task's own instruction, now additionally
  useful as a cheap pre-flight the harness runs before paying for any agent tokens.
- **Does NOT remove** `state.cadence_watch` / `state.cadence_period_watch` — those stay as an independent
  check. A Cloud Scheduler misconfiguration, an IAM break, or the Cloud Run job failing to even start are
  failure modes upstream of this harness's own `try/finally` (the job never runs at all), so the existing
  dead-man's-switch discipline remains necessary, not redundant. It gets *better* evidence to work with:
  Cloud Run job execution history is itself visible in Cloud Logging/Monitoring, independent of
  `ops.run_log` — a second, independent trail the current architecture doesn't have at all today.
- **Residual gap to flag honestly:** the harness process itself could still be hard-killed (OOM, forced
  eviction) between entering the `try` and reaching `finally` in a way no language-level construct can
  intercept. This is a strictly narrower, better-instrumented failure surface than today's (a whole
  claude.ai session dying silently) — Cloud Run surfaces a killed-execution status in its own operational
  logs regardless of what BigQuery shows, so even this residual case is no longer *silent* the way §38's
  incidents were.

### On "Items 3-4" / alternate implementation

Anthropic's own **Claude Managed Agents scheduled deployments** (see (a)) are a ready-made version of the
same primitive — native IANA-tz cron, a `deployment_run` record independent of session outcome, and
webhook events on deployment lifecycle changes. Using that instead of hand-rolling Cloud Scheduler + Cloud
Run would remove the Cloud Scheduler/Cloud Run leg entirely, at the cost of moving the terminal `run_log`
write to a webhook handler instead of an in-process `finally` (functionally equivalent — a webhook that
fires on `deployment_run` completion is just as "outside the agent's own control flow" as a Python
`finally` block, since a `deployment_run` record is written by Anthropic's own infra even on a hard
session failure per the docs above). Flagged here as a viable alternative shape for the eventual pilot
design, not a recommendation to prefer one over the other today — either satisfies the (b) requirement
identically; the GCP-native sketch above is kept as the primary answer because it keeps the whole substrate
inside `stock-trading-498512`'s existing operating model (BigQuery MCP + console, no new vendor surface).

---

## (c) Rough cost

- **Cloud Scheduler:** $0.10/job/month after 3 free jobs/month per project. A D1-only pilot = 1 job = free.
  Full 20-routine migration (D1,D2a,D2,D3,SL3,AR_att,AR_orc,SL2,SL5,W1-5,M1a-5,SL4,Q1-4,SL1,A1-3) ≈ 17
  billable jobs × $0.10 ≈ **$1.70/month** — noise.
- **Cloud Run job compute:** billed per vCPU-second/GiB-second only while the container executes,
  against a monthly free tier of 180,000 vCPU-seconds + 360,000 GiB-seconds. A harness that runs a few
  minutes/day (the wrapper itself, excluding whatever the Agent SDK call streams for) stays inside the free
  tier by a wide margin even summed across all routines. **Effectively $0/month** at this system's run
  volume.
- **Model/token cost — unchanged, not a new cost line.** These routines already run as headless
  Claude-Code-on-Web sessions. Per Anthropic's 2026-06-15 billing change, headless Claude Code / Agent SDK
  usage already runs on a separate Agent-SDK credit billed at standard API per-token rates, not on
  interactive chat limits — so moving the *same* work into a Cloud Run-invoked Agent SDK call bills the
  same tokens at the same rate; it does not add a new cost, and could plausibly reduce token spend for
  routines whose mechanical steps move further into deterministic harness code. [Claude Code billing change](https://www.buildthisnow.com/blog/guide/mechanics/claude-billing-change-june-2026)
- **The real cost is one-time engineering + credential-provisioning effort**, not recurring infra spend:
  building/testing the harness container, and — per (a) — provisioning fresh Vault credentials for
  Tavily/FMP (cheap) and Calendar/Gmail (a bounded OAuth-app setup). IBKR headless auth is explicitly
  **not** costed here because this spike does not recommend attempting it yet (see (a), (d)).
- **Rough total for the D1-only pilot: under $5/month in infra, dominated by rounding — not a material
  new cost line.** The Calendar/Gmail OAuth-app setup (if D1 needs them) is a few hours of one-time work,
  not a recurring cost.

---

## (d) GO/NO-GO recommendation

**CONDITIONAL GO — pilot D1 only, on this harness shape, with the existing web-UI D1 trigger PAUSED
(not deleted) as same-day fallback.**

Why D1 specifically:
- D1 is judgment + read-mostly (market scan → `INSERT`s into `events.decision_log` /
  `events.regime_events`; per `ops/cadence.yaml` D1 `writes: [Daily.md, events.decision_log,
  events.regime_events]`). It places **no IBKR orders** — that's D2 — so the pilot fully sidesteps the
  one genuinely unresolved leg from part (a) (IBKR headless auth) while still validating everything else
  end-to-end: the harness's `try/finally` run_log discipline, native-tz Cloud Scheduler cron, and
  provisioning non-claude.ai credentials for D1's actual dependencies (news/web search, market data;
  Calendar only if D1's own workflow needs it — verify against `Claude_Task_Plan.md`'s D1 section before
  provisioning, don't provision Gmail/Calendar speculatively).
- D1 already runs on the platform's native Daily/Weekdays picker, which `ops/cadence.yaml`'s own audit
  block confirms is "genuinely DST-aware — shows MDT/MST." **Be honest that this means D1 is not where the
  UTC/DST bug class currently bites** — that bug is isolated to the monthly/quarterly/annual cohort forced
  onto raw Custom cron. The pilot's timezone win for D1 itself is mostly about *proving the harness pattern
  works*, not fixing a live D1 bug; the bigger cadence-bug payoff would come from later piloting the
  pattern on a monthly/quarterly routine (M-series or Q-series) — worth flagging as the natural **second**
  pilot candidate once D1 has proven the harness, still without touching an order-placing routine (M4/Q4
  place orders; M1a/M2/M3/Q1/Q2/Q3 do not).

Conditions before flipping D1's primary execution to the harness:
1. Confirm exactly which non-claude.ai credentials D1 needs by re-reading its `Claude_Task_Plan.md`
   section (not guessed here) and provision only those.
2. Run the harness in parallel (shadow) against the live web-UI D1 for a burn-in window, comparing
   `ops.run_log` completion + output parity, before treating the harness as authoritative.
3. Keep the web-UI D1 trigger **paused**, not archived — a same-day, zero-engineering fallback if the
   harness misbehaves.
4. **Do not** extend this pattern to D2/D2a or any order-touching routine until IBKR headless auth is
   separately resolved in its own spike — this report deliberately does not attempt that design, per (a).

**NO-GO, unconditionally, for any routine that calls the IBKR connector until a follow-up spike closes the
gap identified in (a).** Building a Cloud Run job that runs an unofficial, "local-execution-only" IBKR MCP
server with stored 2FA-override credentials, reachable from a scheduler, for real-money order placement,
without a dedicated security review, would be a materially worse posture than today's interactive,
per-session brokerage auth — not a durability improvement.

---

## (e) Urgency note — Items 3-4 already reduce §38's worst symptom

Per this task's own framing, two sibling review items ("Items 3-4") already neutralize §38's worst symptom
regardless of whether this migration ever happens. Independently verifiable in this repo: `ops/RUNBOOK.md`
§38's own "Mitigating hardening applied (2026-07-09)" section already closed the compounding part of the
2026-07-06..08 incident — the `staleness` auto-resolve rule now excludes `category != 'trading_halted'`, so
a recurrence's cleanup is "the honest `ops.run_log` backfill alone... no manual `ops.alerts` UPDATE needed
at all" (§38, verbatim), down from the three manual `UPDATE`s the original incident required. §38's root
cause itself is explicitly left **open** ("a harness session-lifecycle question... this repo has no
visibility into harness-side session timing") — this spike's (b) sketch is precisely the kind of fix that
would close that open root cause structurally (by moving the terminal write outside the LLM's own session
lifecycle entirely), which is worth recording, but:

- The **blast radius**, not the root cause, is what's already mitigated. §38's own "Watch-trigger" section
  says a 4th occurrence "would be strong evidence of a systematic harness-side cutoff... worth escalating
  past repo-side mitigation" — as of this writing that 4th occurrence has not been reported back to this
  spike, so the urgency bar §38 itself set has not been crossed.
- **This lowers, but does not zero, the case for migrating specifically to fix §38.** The stronger,
  currently-*un*mitigated justification for this migration is the `ops/cadence.yaml` UTC/DST bug class and
  the missing month/quarter recurrence type — both are labeled "PERMANENT PLATFORM LIMITATION... not a bug
  to keep re-investigating" in the manifest itself, i.e. today's platform has **no** compensating mitigation
  for those, unlike §38 which now has one. If the owner is weighing GO/NO-GO purely on "how urgent is this,"
  the honest answer is: **not urgent for §38** (already mitigated to a bare backfill), **moderately
  valuable for the cadence-cron bug class** (no mitigation exists today, and the fix is structural rather
  than another hand-correction), and **high-value but zero-urgency for the general observability upside**
  (an independent Cloud Logging trail, deterministic harness code) since nothing is currently on fire.

---

## Sources

- [MCP connector — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector)
- [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)
- [Remote MCP servers — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/remote-mcp-servers)
- [Claude Connector Authentication: How OAuth Works and When You Need It](https://sunpeak.ai/blogs/claude-connector-oauth-authentication/)
- [Connect to external tools with MCP — Claude API Docs (Agent SDK)](https://platform.claude.com/docs/en/agent-sdk/mcp)
- [Authentication for connectors — Claude.ai Documentation](https://claude.com/docs/connectors/building/authentication)
- [Claude Managed Agents overview](https://platform.claude.com/docs/en/managed-agents/overview)
- [Scheduled deployments — Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)
- [Authenticate with vaults — Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/vaults)
- [MCP tunnels — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview)
- [What's new in Claude Managed Agents (scheduled deployments + vaults), Anthropic blog](https://claude.com/blog/whats-new-in-claude-managed-agents)
- [Claude Managed Agents Add Cron Schedules and Credential Vaults — TechTimes](https://www.techtimes.com/articles/318163/20260610/claude-managed-agents-add-cron-schedules-credential-vaultsanthropic-beta-puts-agents-autopilot.htm)
- [Interactive Brokers MCP Server (unofficial, headless-mode caveats)](https://github.com/code-rabi/interactive-brokers-mcp)
- [Claude Code Billing Change June 15, 2026](https://www.buildthisnow.com/blog/guide/mechanics/claude-billing-change-june-2026)
- In-repo: `ops/RUNBOOK.md` §15, §38; `ops/cadence.yaml` (header + 2026-07-10 web-UI trigger audit block);
  `bigquery/12_cadence_monitor.sql` (`ops.sp_assert_deps`, `ops.sp_routine_start/end`);
  `bigquery/32_d2a_cutover_readiness.sql` (readiness-view/idempotency-marker convention referenced by
  analogy in (b), not modified or reused directly here).

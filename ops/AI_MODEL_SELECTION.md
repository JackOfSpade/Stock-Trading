# AI model and effort selection

Status: policy and record. Last updated 2026-11-14.

Read this before re-testing any AI call in this repository. It records which
model and effort each call uses, why that setting was chosen, and what has
actually been measured. A call marked **Proven** needs no re-test unless a
re-test trigger applies. A call marked **Needs test** has no measurement yet
and cannot be called selected.

This file is adapted from a sibling project's `docs/ai-model-selection.md`,
keeping only that document's non-live philosophy. Nothing in this repository
sits on a request path: every AI call here is either a cron routine or a
BigQuery job. Selection is therefore about cost and quality, and about
nothing else.

## Where settings live

**Remote routines.** Model ONLY. The model is set per routine in the claude.ai
routine config (claude.ai/code/routines). The web form also shows an Effort
level selector when the model offers one, but the routine API stores only
`model` — there is no effort field (verified 2026-11-14 via RemoteTrigger get
on A1) — so every routine runs at its model's default effort and the only
thing a routine can be tuned to is a model. The canonical and
backup instruction text is `ops/routine_backup.json`. `ops/cadence.yaml`
`routine_model` is the single fleet model (`claude-opus-5-5`) and stays; see
"Decision: routine models" below.

**Subagents inside routines.** The model is named in each routine instruction
in `ops/routine_backup.json`: "Spawn Sonnet 5.5 model sub-agents to do the
grunt work. Save your processing (Opus 5.5) for design/analysis/orchestration".

**BigQuery remote models.** `bigquery/02_ai_layer.sql` defines `ops.text_embed`
(ENDPOINT `text-embedding-005`) and `ops.gemini` (ENDPOINT `gemini-2.5-flash`,
SUPERSEDED — see the next sentence). Both use the `us.vertex` connection in
project `stock-trading-498512`. `bigquery/276_gemini_model_upgrade.sql`
(2026-11-14) repoints `ops.gemini` at ENDPOINT `gemini-4-hydrogen` and moves
`analytics.theater_judge.model`'s DEFAULT to `gemini-4-hydrogen`; that file is
applied live on 2026-11-14 with the owner's OK.

**Golden-scenario judge.** `tests/golden_scenarios/run_golden.py` runs a
Gemini free-tier ladder, and only when passed `--live`.

## Policy

Every call in this repository is non-live. One rule governs the setting of
every call: use the cheapest setting whose quality is within noise of the
best setting tested.

**Hard exclusions.**

- Never `max` effort, for Claude models.
- Never Fable.
- Always the latest model in a family. Never test, and never pin, an older
  version.
- Record the resolved model id with every result.

**Candidate models.** Claude Haiku, Sonnet and Opus for the routines, and
Gemini on the BigQuery surface. There is no third provider.

**Gemini model rule.** A Gemini call uses the NEWEST Gemini model that has a
free tier on the Gemini Developer API — today `gemini-4-hydrogen` — even
where the surface that actually issues it (Vertex AI / BigQuery) has no free
tier and bills every call. Newest-with-a-free-tier, not newest-available:
`gemini-4-carbon` and `gemini-4-argon` have no free tier, so they are not
candidates. Read from aistudio.google.com/docs/pricing on 2026-11-14, the
free tier covered `gemini-4-hydrogen`, `gemini-3.8-flash`,
`gemini-3.6-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite`,
`gemini-embedding-2` and `gemini-embedding-001`. Free-tier prompts are "used
to improve Google's products". That applies only to calls made on the free
tier itself, which today is only the golden-scenario script; the BigQuery
calls go through Vertex AI, which is paid and does not use prompts that way.

**Rule for every call (all calls here are non-live).** Seven steps, in order:

1. Order candidate settings by MEASURED cost per call, cheapest first. Do not
   assume tier order. An input-heavy call can make a higher effort cost the
   same as a lower one.
2. Test the cheapest setting on the hardest few real inputs first. Pass means
   the caller's own validator or parser accepts the output at about the
   production rate, and a blind judge (or planted defects, for audit and
   judge calls) finds it within noise of the reference.
3. Stop climbing at the first setting that passes. Confirm it on all captured
   inputs with a second run. If confirmation fails, go up one step.
4. Retry cost counts. Run time is not a criterion.
5. Measure the noise floor. Run the reference setting twice, or include an
   unchanged rerun as a control arm. A gap smaller than that is not a
   difference.
6. For a call whose output feeds another step, judge the downstream result,
   not only the call's own output. A routine's decision feeds orders; the
   theater judge feeds `strategy_adoption_readiness`; embeddings feed
   `find_precedents`.
7. Every call is proven by a test. Small spend is not proof. Running on the
   cheapest setting that exists is not proof either: it still needs one
   comparison against a stronger setting, otherwise the call is "Needs
   quality check". Keep tests proportionate, meaning the smallest replay that
   answers the question.

**Re-test triggers.** Re-test a call when any of these happens:

- a new model release in a family;
- a changed prompt, instruction, or schema for that call;
- a changed validator or parser;
- a new candidate provider;
- a production signal: quality drift, or rising failures.

**Results are tied to model versions.** When a newer version of a family is
released, earlier results for that family become history. Calls whose ladder
included that family get a new assessment.

**Trading-system constraints on testing.**

- Tests never place orders.
- Tests never write production tables. A replay is read-only, or it writes
  only to the test-run table.
- Routine blinding walls stay intact. A judge or a replay must not see data a
  routine is blinded from.
- Routine replays draw on the same weekly Claude quota as the live fleet and
  as chat. Schedule them away from fleet windows and keep them small.

## Decision: routine models (owner, 2026-11-14)

Every trading routine stays on Opus 5.5 (`claude-opus-5-5`) with Sonnet 5.5
subagents. Earlier the same day the owner allowed per-routine models; after a
judgment review of each routine (no tests run) the owner chose to keep the
uniform setup, so the single `routine_model` key, CI check N and the
instruction text stay as they are.

- **Not tested.** This is an owner decision, not a ladder result. Every
  routine row below stays "Needs test" in the policy's terms; re-open it only
  if a re-test trigger applies (for example, the weekly quota running out, or
  a new Opus or Sonnet release).
- **Model only.** The routine API stores `model` and no effort field (verified
  2026-11-14 via a RemoteTrigger get on A1), so routines run at Opus's default
  effort.
- **Verified live 2026-11-14:** all 33 trading routines run
  `claude-opus-5-5`, the newest Opus. 32 instruct Sonnet 5.5 subagents, the
  newest Sonnet. OPS2 has no subagent line on purpose (owner-confirmed
  2026-07-28): it re-runs missed routines inline at full Opus fidelity.
- **Judgment notes, for a future re-test.** If quota ever gets tight, the
  routines most likely to hold up on Sonnet are OPS1, OPS0 and SL5 (daily,
  mechanical) and W4, W5 (weekly). The ones to keep on Opus regardless are
  D1, D2, D2a, AR_att, AR_orc, SL2, SL3 and OPS2.

## AI call inventory and status

Status legend:

- **Proven**: a ladder ran on the current model version, the cheapest passing
  setting sits within the noise floor, and the run is recorded.
- **Partial**: some arms ran, but the ladder is incomplete (for example, the
  confirmation run is missing).
- **Needs test**: no measurement exists for this call.
- **Needs quality check**: the call runs on the cheapest setting that exists,
  with no comparison against a stronger setting.

Today NO call is Proven. Every row below is "Needs test" unless stated
otherwise.

### Table A: BigQuery calls

Measured from region-us `INFORMATION_SCHEMA.JOBS_BY_PROJECT`, top-level query
jobs only, 2026-08-16 to 2026-11-14 (America/Denver dates).

| Call | Model | Callers | Jobs (90d) | Active days | Failed jobs | Output health | Status |
|---|---|---|---|---|---|---|---|
| Decision embed on every decision write: `ops.sp_log_decision` -> `ops.sp_embed_pending` (`bigquery/116_decision_record_analyzability.sql`) | text-embedding-005 | most routines | 954 | 68 | 38 | — | Needs test |
| `find_precedents` query embed: `analytics.find_precedents` (`bigquery/29_precedent_outcomes.sql`) | text-embedding-005 | routines (about 16 plan uses) | 286 | 63 | 0 | — | Needs test |
| `sp_embed_pending` called directly (`bigquery/253_embed_pending_concurrent_dedupe.sql`) | text-embedding-005 | routines | 134 | 45 | 3 | — | Needs test |
| Scheduled embed sweep `ops.sp_sq_embed_pending` (`bigquery/75_scheduled_query_wrappers.sql`) | text-embedding-005 | daily scheduled query | 111 | 90 | 0 | — | Needs test |
| Theater judge `ops.sp_score_theater` (`bigquery/11_theater_judge.sql`, redefined in `143_adversarial_review_correction_path.sql`) | gemini-4-hydrogen (since 2026-11-14, `bigquery/276`; was gemini-2.5-flash) | AR_orc, a strategy-adoption step, W5 | 135 | 58 | 4 | 47 of 47 attacker/orchestrator review pairs scored, 0 null verdicts | Needs test |
| Cross-model referee `ops.sp_score_cross_model_referee` (`bigquery/44_cross_model_referee.sql`, redefined in `143_adversarial_review_correction_path.sql`) | gemini-4-hydrogen (since 2026-11-14, `bigquery/276`; was gemini-2.5-flash) | W5, SHADOW mode (verdict gates nothing yet) | 33 | 14 | 0 | 27 verdicts (ACTIVATE / DO-NOT-ACTIVATE) | Needs test |

Notes on Table A:

- The embeddings table `analytics.decision_embeddings` holds 2,818 rows, 0 of
  them with an error status or an empty vector.
- Every failed job above was a caller-side SQL error: bad literal
  concatenation, digest-mismatch refusals, wrong column names. None was a
  Vertex or Gemini failure.
- Slot use for all six calls is about 88 slot-hours in 90 days. Vertex bills
  the model calls separately.
- Changing the embedding model requires re-embedding every stored vector, and
  keeping query and stored vectors on the same model.

### Table B: Remote routines (claude.ai)

All 33 trading routines currently run on `claude-opus-5-5` with Sonnet 5.5
subagents. All are "Needs test".

| Routine | Cron (UTC) | Main model | Subagents | Status |
|---|---|---|---|---|
| A1 | `0 17 1 1 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| A2 | `15 20 1 1 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| A3 | `0 21 1 1 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| AR_att | `0 0 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| AR_orc | `35 0 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| D1 | `0 22 * * 0-4` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| D2 | `15 23 * * 0-4` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| D2a | `40 22 * * 0-4` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| D3 | `45 0 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M1R | `0 13 * * 0-4` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M1a | `0 11 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M1b | `0 12 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M2 | `0 13 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M3 | `0 14 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M4 | `0 15 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| M5 | `0 16 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| OPS0 | `30 4 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| OPS1 | `30 12 * * 0-4` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| OPS2 | `15 4 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| Q1 | `0 17 2 1,4,7,10 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| Q2 | `0 18 2 1,4,7,10 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| Q3 | `0 19 2 1,4,7,10 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| Q4 | `0 20 2 1,4,7,10 *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| SL1 | `0 21 2 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| SL2 | `5 1 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| SL3 | `0 2 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| SL4 | `30 16 1 * *` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| SL5 | `25 1 * * 1-5` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| W1 | `30 7 * * 0` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| W2 | `0 8 * * 0` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| W3 | `0 9 * * 0` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| W4 | `30 9 * * 0` | claude-opus-5-5 | Sonnet 5.5 | Needs test |
| W5 | `0 5 * * 1` | claude-opus-5-5 | Sonnet 5.5 | Needs test |

Notes on Table B:

- Two personal routines in `ops/routine_backup.json` are not part of the
  trading system and are out of scope here.
- The TEMP strategy-lab routines are deliberately outside the fleet manifests
  and are out of scope until deleted (after the 2027-01-04 report).
- Per-routine token and cost data is not yet measured. Measuring it is the
  first step of the routine ladder.

### Table C: Other calls

| Call | Where | Setting | Status |
|---|---|---|---|
| Golden-scenario judge | `tests/golden_scenarios/run_golden.py --live` | Gemini free-tier ladder: gemini-4-hydrogen -> gemini-3.8-flash -> gemini-3.5-flash-lite | Not in use (retired from CI 2026-08-30; test only if revived) |
| One-off ticker backfill | comment in `bigquery/02_ai_layer.sql` (2026-06) | One-off run | Historical, not in use |

## How to measure

**Record every test run in a BigQuery table.** Records belong in tables, not
in Markdown.

Planned table: `ops.ai_test_runs`, one row per arm, with columns `run_id`,
`call`, `setting` (model:effort), `resolved_model_id`, `n`, `valid`, `failed`,
`cost_usd`, `agreement`/`score`, `noise_floor`, `judge`, `notes`,
`started_ts`, `finished_ts`, `status` (running / finished / interrupted).

The table does NOT exist yet. Creating it is DDL and needs the owner's OK.
Until it exists, keep run evidence in a durable folder outside any session
scratchpad, and copy it in when the table lands. A run records itself when it
starts and as results land, so an interrupted run is never lost.

**BigQuery calls.** Replay past inputs read-only.

- Theater judge and referee: the inputs are rows of
  `events.adversarial_reviews` (attacker and orchestrator bodies). Call
  `AI.GENERATE_TABLE` or `AI.GENERATE` against a candidate remote model in a
  SELECT only, and compare with the stored verdicts (`analytics.theater_judge`
  and the referee_gemini rows). Add planted cases: a copied orchestrator
  transcript must be judged not independent.
- Embeddings: compare retrieval, not vectors. For a fixed set of
  `find_precedents` queries, measure the overlap of the top-k precedent sets
  between models. A candidate must re-embed a sample of decision_log entries
  in a scratch table.

**Routines.** A replay needs a read-only harness: dry-run mode, no orders, no
production writes. Run it against past dates' inputs. Judge decisions blind
against the production run. The noise floor is two production-setting replays.

This is the most expensive test. Do it last, one routine at a time, starting
with read-only routines (W1-W4, the M-series research routines) before the
decision routines (D1, D2, D2a, SL*, AR_*).

## New model release playbook

Adapted from the sibling document:

1. Regression check every affected call on the new version, one run at the
   current setting. On failure, treat the call as untested and ladder it in
   full.
2. Re-check measured cost before stepping down. Skip steps that cannot save
   money.
3. Step down one rung at a time, and stop at the first rung that fails
   (quality beyond the noise floor).
4. A new version of a cheaper family gets one probe from above on every call
   that is set on a more expensive family.
5. A new family (other than Haiku, Sonnet, Opus or Gemini) is slotted in by
   price and tested at all efforts below max. Fable and max stay excluded.
6. Record the results, and update this file's rows and the "Model versions
   tested" table.

## Model versions tested

| Date | Versions tested | Notes |
|---|---|---|
| 2026-11-14 | none yet | Inventory and BigQuery usage measurement only; no ladders run. |

## Open gaps (2026-11-14)

1. Every call is "Needs test".
2. `gemini-2.5-flash` is deprecated (no longer selectable in AI Studio; API
   requests auto-route elsewhere from 2026-12-01). `bigquery/276` moved the
   theater judge and the cross-model referee to `gemini-4-hydrogen` live on
   2026-11-14; neither has been re-tested on it yet.
3. Embeddings stay on `text-embedding-005` pending an owner decision.
   `gemini-embedding-2` has a free tier on the Gemini Developer API, but a
   switch re-embeds all 2,818 vectors in `analytics.decision_embeddings`, and
   `text-embedding-005`'s currency is still unchecked.
4. Routines are kept on Opus 5.5 by owner decision, untested (see "Decision:
   routine models").
5. The `ops.ai_test_runs` table needs the owner's OK.
6. Done 2026-11-14: `bigquery/276` applied live; the judge and referee now
   call `gemini-4-hydrogen`.
7. The routine replay harness does not exist.
8. Per-routine cost is not measured.

Suggested order: theater judge and referee first (cheap, read-only replay),
then embeddings, then routines.

## Log

### 2026-11-14 — model upgrade to the newest free-tier Gemini

- 2026-11-14: owner dropped DeepSeek as a candidate.
- Owner directive: every Gemini text model in this repo moves to the newest
  Gemini model that has a free tier on the Gemini Developer API — today
  `gemini-4-hydrogen` — even where the surface that issues the call, Vertex AI
  via BigQuery, has no free tier and bills every call. `gemini-4-carbon` and
  `gemini-4-argon` have no free tier, so they are not candidates. Free-tier
  prompts are "used to improve Google's products".
- New `bigquery/276_gemini_model_upgrade.sql`: moves the
  `analytics.theater_judge.model` DEFAULT and the `ops.gemini` ENDPOINT to
  `gemini-4-hydrogen`. Idempotent; existing judge rows keep their recorded
  model. Applied live the same day with the owner's OK; verified by a structured
  `AI.GENERATE_TABLE` call through `ops.gemini`.
- Live read-only probe (2026-11-14): `AI.GENERATE` over `us.vertex` answered
  "OK" for `gemini-4-hydrogen`, `gemini-3.8-flash` and `gemini-2.5-flash`, so
  the new endpoint is callable from BigQuery today. Vertex bills per call; the
  volume is about 170 judge calls per 90 days, so the upgrade costs cents.
- Golden-scenario ladder re-chosen best-first: `gemini-4-hydrogen` ->
  `gemini-3.8-flash` -> `gemini-3.5-flash-lite`, all free tier.
  `gemini-3.5-flash` and `gemini-3-flash-preview` are no longer listed on the
  pricing page. Per-model free-tier RPM/RPD for this key's project are NOT
  verified (Google no longer publishes them on that page) — probe
  `generateContent` with the project key before the next `--live` run.
- Candidate models are now Claude Haiku/Sonnet/Opus for routines and Gemini on
  the BigQuery surface.
- Routines: the routine API stores only `model`, with no effort field
  (verified via a RemoteTrigger get on A1), so routine tuning is model-only
  and routines run at the model's default effort.
- Embeddings unchanged: `text-embedding-005` stays until the owner decides on
  `gemini-embedding-2` (free tier, but a switch re-embeds all 2,818 vectors).

### 2026-11-14 — inventory and usage measurement

- Created this file from the sibling project's policy, carrying over only the
  non-live, cost-and-quality philosophy.
- Owner decisions: per-routine models allowed (later the same day reversed:
  the fleet stays uniform, see the decision section).
- Measured BigQuery usage over 90 days for the six AI calls: 954 / 286 / 134 /
  111 embedding jobs and 135 / 33 judge and referee jobs. All failures were
  caller-side SQL errors.
- Confirmed that the claude.ai routine web form exposes a per-routine model
  selector. The API behind it is
  model-only — see the entry above.

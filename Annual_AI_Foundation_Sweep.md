2026

# Annual AI Foundation Full Re-Derivation — 2026

**Routine:** A1 (AI Foundation Annual Full Re-Derivation) · **Run date:** 2026-07-28 (`state.trading_day_today`) · **Session model:** `claude-opus-5`.
**Baseline document:** `AI_Trading_Foundation.md` rev 5 (2026-07-10). **Roster-active strategies:** A, B, C, D, E (`state.strategy_roster`; F/G REJECTED).
**Evidence window:** **2024-08-01 → 2026-07-28 (24 months).** A1 has never previously completed (`state.routine_catchup_window`: `never_completed=true`, `window_days=366`), so the catch-up window resolves to the cadence fallback and the 24-month primary-source scope is the binding one — the LONGER of the two per the CATCH-UP EVIDENCE WINDOW directive. `window_days` is at the annual fallback, so no `CATCHUP[...]` token is warranted.
**Framing (Part 4):** adversarial — evidence that *contradicts or updates* documented items, not evidence that confirms them. **Default bias: YES on flagging change; NO on removing an item absent affirmative evidence.**
**Method:** orchestrated fan-out — eleven parallel research agents, each owning a disjoint slice of the item set, each instructed to report `ABSENT` as a first-class answer and to tag every Tier 2 numerical claim against the §5.5 Goodhart guardrails. Every arXiv ID below was retrieved, not recalled.

---

## MODEL OF RECORD — the anchor for this entire sweep

**In-use model: `claude-opus-5`.** This is the model the **owner configured** for the remote-routine fleet, which is the only thing that matters for a document describing the capabilities and limitations of the model this experiment actually runs. It is **not** an inference from "what is newest."

- **Source of record:** `ops/cadence.yaml:41` top-level `routine_model: claude-opus-5` (added this cycle — see below), corroborated by `OWNER_ACTIONS.md:24` ("**Model:** `claude-opus-5` — REQUIRED"), `ops/cadence.yaml:233`, and `Claude_Task_Plan.md:1351` / `task_plan/OPS2.md:513` ("OPS2 runs on the same model the routines use (`claude-opus-5`)"). All remote routines run the **same** model — a standing owner invariant, so there is one answer, not one per routine.
- **KNOWN SITES HARDCODING THE MODEL ID — all four must change together on a fleet switch:** `ops/cadence.yaml:41` (`routine_model`, the record of truth), `ops/cadence.yaml:233` (OPS2 trigger comment), `OWNER_ACTIONS.md:24` (OPS2 model requirement), and `task_plan/OPS2.md:513` / `Claude_Task_Plan.md:1351` (OPS2's NO MODEL DOWNGRADE rule, which names the id literally). Nothing currently enforces that they agree — see the future-proofing gaps below.
- **On the CONSEQUENCES of a model change, an existing procedure already applies and should not be duplicated:** `ops/foundation_change_review.md` **§C "Model-version change"** — re-derive numerical calibration from the new model's own data rather than inheriting it, re-tag the mistake catalog as "model X exhibited this," and confirm process/workflow/taxonomy artifacts transfer as-is. It requires a completion record (`events.decision_log`, `entry_type='foundation-change-review'`), and its own note that "its absence for a foundation change is itself the detectable gap" is the closest thing the repo has to a model-change tripwire today. **A3 should run §C as part of applying this sweep's version-change protocol.** What §C does *not* do is DETECT that a change happened — it is a checklist for after you already know.
- **The `RemoteTrigger` connector was not available in this session**, so the live trigger config could not be read directly. The in-repo record is the authority used here. If the two ever disagree, the live config wins and `routine_model` is the stale side.

**This distinction was load-bearing this cycle, not academic.** As of 2026-07-28 Anthropic's *most capable widely-released* model was **`claude-fable-5`**, and Artificial Analysis ranked **Opus 5 ahead of it** on general intelligence — but the owner deployed **neither on the basis of being newest**: they configured `claude-opus-5`. Had this sweep anchored to the frontier instead of the deployed model, the foundation document would now describe a model this experiment does not run.

**Consequently, throughout this document:** capability research on **Fable 5, Mythos 5, Sonnet 5, and every non-deployed model** is reported as **CONTEXT ONLY** — it informs what a future upgrade would mean and it is legitimate evidence about *autoregressive LLMs generally* where authors assert architectural generality, but it **never drives a KEEP / UPDATE / VERSION-PENDING resolution or a §5.4 reduction threshold on its own.** Where a measurement exists only for a non-deployed Claude model, that is recorded as a gap, not as evidence about the model in use.

**⚠ METHODOLOGY SUPERSEDED AFTER THIS SWEEP WAS WRITTEN — read this before relying on the CONTEXT-ONLY framing above.** The binary deployed-vs-not rule described in this section was replaced, on the same day and by owner directive, with a **four-level evidence hierarchy (L1 deployed model / L2 model line / L3 Anthropic family / L4 general-architectural)** traversed in full for every item, plus a per-item cross-level verdict and an evidence-coverage matrix. Rationale: research on the exact deployed model is gated or too slow to ever be current, so a binary rule discards nearly all available evidence. **This document was produced under the OLD rule and therefore contains no L1–L4 stratification and no coverage matrix** — the per-item accounting that would make the deployed-model evidence gap visible at a glance is absent here, and is instead stated in prose at the MODEL OF RECORD section, headline finding 2, and the deployment caveats under 2.10 and 2.13. The next A1 run regenerates this file under the new hierarchy; until then, read the resolutions in PART 2 with that limitation in mind. The current instruction is `task_plan/A1.md` §MODEL OF RECORD + §FOUR-LEVEL EVIDENCE HIERARCHY.

**Instruction change made this cycle (owner directive 2026-07-28).** A1 and Q3 previously had no authoritative field to read for this, and the only in-repo trace of the configured model was prose in `OWNER_ACTIONS.md` plus an aside in the OPS2 slice — which is how a future cycle could have silently anchored to the frontier. Three changes close that: (i) `ops/cadence.yaml` now carries a first-class **`routine_model`** key as the version-controlled record; (ii) the **A1** instruction now opens with a MODEL OF RECORD step that must be established *before* any capability research, explicitly forbids inferring the model from the session's own identity or from "what is newest," and scopes non-deployed-model research to context-only; (iii) the **Q3** instruction carries the same rule by reference, since Q3 touches the same in-use-version field every quarter.

---

**Tooling note (operational, for `HF_Resource_Catalog.md`):** the HF `paper_search` MCP tool **no longer exists**. Its replacement is `hf_fs` (`cmd="search"`, `args=["hf://papers", "<query>", "--limit", N]`), with `cat hf://papers/<id>/paper.md|metadata.json` for detail. `HF_Resource_Catalog.md` §6.1/§8.2 still instruct A1/Q3 to call `paper_search` and need updating. Separately, the **Open LLM Leaderboard Space is ARCHIVED** (static snapshot since 2025, no longer live-evaluating; successor record `OpenEvals/archived-open-llm-leaderboard-2024-2025`) — §2/§3 of the catalog describe it as a live reference and are now wrong.

---

## HEADLINE FINDINGS

1. **The in-use-model field is stale and the staleness flag is RESOLVED, not re-flagged — and the correct value is the OWNER-CONFIGURED model, not the frontier.** The document records "Claude Opus 4.7 (as of 2026-04-25)" with a note that "this repo cannot query which model a web-UI routine session is actually running on." The right question was never *which model is newest* but *which model did the owner deploy* — and that is answerable from repo config: **`claude-opus-5`** (`ops/cadence.yaml` `routine_model`, `OWNER_ACTIONS.md:24`, `task_plan/OPS2.md:513`). Five Claude releases shipped since the field was set (Opus 4.8 2026-05-28; Fable 5 + Mythos 5 2026-06-09; Sonnet 5 2026-06-30; Opus 5 2026-07-24), and the *most capable widely-released* model at window close was **Fable 5, which the owner did not deploy** — anchoring there would have made the foundation describe a model this experiment does not run. → **Version-change protocol FIRES**: set the field to `claude-opus-5`, flip Tier 2 magnitudes to version-pending. Not an early refresh, not a per-strategy assessment on its own. See **MODEL OF RECORD** above for the instruction changes made this cycle to prevent a future sweep from anchoring to the frontier by default.

2. **The Claude-evidence gap on calibration is closed at the FAMILY level — but NOT for the deployed model.** Last cycle no Tier 2 disadvantage could clear §5.5 guardrail (2) because every measurement was non-Claude or vendor-claimed. Four independent non-vendor papers now measure Claude-family calibration directly (KalshiBench `2512.16030`, QuantSightBench `2604.15859`, ConfidenceBench `2607.20526`, Dunning-Kruger `2603.09985`), and they **confirm the magnitude on a flat trajectory** — which forecloses any MATERIAL-reduction claim resting on "no Claude data exists." **However, every one of them tests Opus 4.5, Opus 4.6, Sonnet 4.5 or Haiku 4.5 — none tests `claude-opus-5`, the model actually deployed.** No academic calibration paper in-window evaluates *any* post-2026-04-25 Claude model. So for the in-use model specifically the magnitudes remain **version-pending by the Part 4 protocol's own logic**, and the confirmation above is evidence about the family and about autoregressive LLMs generally, not a measurement of what this experiment runs. That is the correct reading once the sweep is anchored to the deployed model rather than the family.

3. **No Tier 2 disadvantage cleared all four §5.5 Goodhart guardrails for a reduction in the 24-month window.** The one candidate that nominally satisfies a §5.4 threshold on its face — 2.10 prompt injection, on Anthropic's July-2026 numbers — **fails two guardrails outright** and is contradicted in magnitude by the one independent realistic-methodology benchmark. Classified PARTIAL, not MATERIAL. **No constraint-relaxation review is triggered by this sweep.**

4. **Three substantive numerical contradictions found, all requiring UPDATE:** (a) **2.3's market-cap direction is REVERSED** — larger-cap firms are hallucinated about *more*, not less (`2504.00042`, replicated across four model families); (b) **2.10 contains a citation misattribution and a false claim** — "17.8%" is Anthropic's own number not the IASR's, and "Haiku-tier has zero prompt injection protection" is contradicted by Haiku 4.5's own system card and by an independent 272,000-attempt red-team placing Haiku 4.5 second-best of thirteen frontier models; (c) **2.20's bubble-participation framing is refined** — AI agents *do* replicate human bubble dynamics in heterogeneous multi-agent markets.

5. **Three load-bearing Tier 2 magnitudes are ABSENT from 24 months of literature → VERSION-PENDING:** 2.14's "~10× recency weighting" (nothing in any domain measures a week-over-week ratio), 2.4's "~30% counter-argument benefit", and 1.7's "30+/200+ outcomes" sample thresholds. Per Part 4, absence alone does not remove them.

6. **Two citation-integrity defects found in the document's own text**, independent of any research change: 2.21's "96 / 216+ / 370+ trades" could not be traced to any retrievable source, and 2.12's "Ridge regression beats thinking LLMs on cross-sectional ranking" sub-claim could not be re-located. Both need a citation fix, not a magnitude fix.

7. **A fabricated statistic was intercepted before it could enter the document.** A figure circulating in search summarization — "Claude Sonnet 4.6 at 46%, Claude Opus 4.6 at 61%" on the user-belief sycophancy axis — was checked against the Stanford HAI primary page, which mentions Claude nowhere; the named models also postdate the study's evaluation window. Excluded. Relatedly, the prior cycle attributed the user-belief-collapse numbers to **AA-Omniscience, which contains no such experiment** — the real source is **KaBLE** (Nature Machine Intelligence, Nov 2025; arXiv `2410.21195`).

8. **The verified per-strategy citation graph diverges materially from the prior cycle's.** Strategy A does **not** cite 1.4, 2.15, or 2.17 anywhere — three of the five citations the prior summary listed do not exist in A's mechanism document or pre-mortem. Any assessment driven by the old graph would check the wrong items. Corrected graph in PART 2 §F.

9. **The reference class stayed negative, now with cross-market replication.** No large-scale, long-horizon, properly bias-corrected result was found in which autonomous LLM judgment beat a passive or classical baseline out-of-sample. A deliberate adversarial disconfirmation pass produced three candidates, all of which fail on horizon, universe, or attribution.

10. **2.1 and 2.2 are now demonstrably design choices, not technological ceilings.** Between January and June 2026 at least ten retail brokers wired AI agents into live client accounts — **Claude was the model behind nine of the ten** — and several permit trade placement without per-trade human confirmation. The items remain true of this workflow; their framing should say *chosen*, not *unavoidable*.

---

# PART 1 — LAST-24-MONTHS COVERAGE, ORGANIZED BY FOUNDATION ITEM

Citations inline; reverse-chronological within each item. `hf.co/papers/<id>` where HF-indexed, `arXiv:<id>` otherwise. `VENDOR-CLAIMED` marks a lab grading its own model. `ARCHITECTURAL-GENERALITY` marks a finding asserted for autoregressive LLMs broadly rather than measured on Claude.

## Preamble claims

### P.1 Market saturation is near-total

- **"62% of US retail investors use AI tools"** — `SUPPORTED-BY-RESEARCH`, exact match. Investing.com survey of 938 US retail investors, 2026-04-06. Most current traceable figure.
- **"91% of investment managers using or planning to use AI in research"** — `SUPPORTED-BY-RESEARCH` but **imprecise**: the document collapses two distinct Mercer 2026 figures. Mercer *AI in Asset Management 2026*: **55% currently integrated** into ≥1 investment process, 27% pilot-stage, 18% none; **91% plan to increase** use over the next 12 months. SimCorp *2026 InvestOps* (200 execs, $10bn+ AUM each): **70% of buy-side actively deploy AI in the front office**, up from ~10% a year earlier.
- **"89% of global trading volume handled by AI-driven systems by late 2025"** — **`ABSENT-FROM-RECENT-RESEARCH` / UNVERIFIED. The single clearest fade candidate in this sweep.** Multiple 2026 secondary and marketing sources repeat "89%" verbatim with no traceable underlying study. Separately-sourced estimates put *algorithmic* trading at **60–75%** of US/global equity volume — a broader and materially different category that does not corroborate the AI-specific 89%.
- Counter-note: ESMA (2026-02) finds EU securities-market AI adoption "gradual and uneven, with smaller firms often lagging" — a mild qualifier on "near-total," scoped to the EU.

### P.2 The autonomous-AI trading baseline is unfavorable

- **Bridgewater** — `SUPPORTED-BY-RESEARCH`, unchanged and current. Pure Alpha returned **33% in 2025** (best in 50 years; one source reports Pure Alpha II at 34%); **AIA Macro Fund 11.9%** in 2025 (launched July 2024, ~$2B, ~$5B AUM by March 2026). The ~11% vs ~33% gap is accurate. FY2025 is the most recent complete year; next data point ~Q1 2027.
- **Alpha Arena S1** (nof1, Hyperliquid, 2025-10-17 → 2025-11-03, ~17 days, $10K real capital per model): 4 of 6 net negative — **Claude Sonnet 4.5 −30.8%**, Grok 4 −45.3%, Gemini 2.5 Pro −56.7%, GPT-5 −62.7%. Profitable: Qwen3-Max +22.3%, DeepSeek V3.1 +4.9%.
- **Alpha Arena S1.5** (2025-11-19 → 2025-12-03, $320K across 32 instances, US equities added): only the "Mystery Model" (Grok 4.20) profitable across all four sub-competitions.
- **FINSABER** `hf.co/papers/2505.07078` (ACM-accepted revision 2026-04-20): 20 years, 100+ symbols, survivorship / look-ahead / data-snooping controls. LLM strategies (FinMem, FinAgent) show **statistically insignificant alpha, all p > 0.34**, and are significantly beaten by buy-and-hold.
- **NEW cross-market replication — KTD-Fin** `arXiv:2605.28359` ("From Knowing to Doing"), CSI300, 2024-01 → 2026-04, ten frontier LLMs **including Claude Opus 4.7**. Under leakage/masking-controlled factor attribution, **9 of 10 LLM agents show negative stock-selection alpha** (−77.8% to +0.2%) versus consistently positive alpha (+0.06% to +0.57%) for 18 classically-trained ML baselines. Different market, methodology, and research group; same conclusion.

### P.3 Homogenization risk is material — see 2.8.

---

## Part 1 — Confirmed AI Edges

All Part 1 items are Tier 1 and are audited **only** for affirmative architectural-change evidence. Default is NO. Absence of research about an edge is expected and is not a fade signal.

### 1.1 Narrative synthesis across large unstructured corpora [Tier 1]

- **SynthDocBench** `hf.co/papers/2607.10400` (2026-07): 7 frontier VLMs, synthetic multi-page documents averaging 51 pages requiring cross-modal cross-section synthesis. "Systematic positional sensitivity in which **the middle section of a document is hardest for five of six models**"; steepest early-to-late decline **8.3pp**; precise chart-reading collapses in long-document context even for models strong on isolated-chart benchmarks.
- **"Systematic Evaluation of Long-Context LLMs on Financial Concepts"** `hf.co/papers/2412.15386` (JPMorgan Chase, 2024-12) — on-domain. GPT-4o / GPT-4-Turbo F1 collapses from **0.99 at 4K tokens to 0.40 at 128K** on the *simplest* task formulation, worse on harder ones, with "catastrophic failures in instruction following" at long context and sensitivity to minor markdown/prompt-placement changes.
- **Needle Threading** `hf.co/papers/2411.05000` (2024-11), 17 LLMs **including Claude 3 / 3.5**: "effective context limit is significantly shorter than the supported context length," though models are "thread-safe" once single-thread limits are accounted for.
- *Secondary, UNVERIFIED:* a 2026 long-context roundup reports Claude Opus 4.6 at 76% on MRCR-v2 8-needle at 1M tokens vs GPT-5.4 36.6% and Gemini 3 Pro 24.5%. Direction is consistent (all vendors degrade well below advertised length; Claude comparatively strongest) but this could not be traced to a primary benchmark paper. Not relied upon.
- **Architectural-change evidence: NO.** Transformer positional/attention mechanics are unchanged; effective-context shortfall and middle-of-document degradation persist at 2026 frontier scale including on Claude. This does not invalidate the edge — it bounds it.

### 1.2 Within-session consistency of process [Tier 1]

- **Prompt Design at Scale (VeyraBench)** `arXiv:2607.19257` (2026-07): controlled instruction-density sweep, N = 10 → 160 rules, 5 models. **Perfect-response rate collapses to zero by N ≈ 80** for every model, format, and placement tested; placement (system vs user turn) matters as much as format.
- **IFScale** `arXiv:2507.11538`: at 500 simultaneous instructions, claude-3.7-sonnet **52.7%**, claude-opus-4 **44.6%**, claude-sonnet-4 **42.9%**; claude-3.5-haiku shows an exponential-decay pattern. Note the *older* 3.7 outperforms the two newer models at that density.
- **"How Agent Skills Fail under Long Contexts"** `arXiv:2607.17937` (2026-07): 8/10 pass in an 11K-char context vs **3/10 at 299K** (relevant or irrelevant filler alike); requirement coverage stays >92% even in failing runs — a few dropped items invalidate an otherwise-complete pass. A detailed **external** checklist passes 10/10 vs 5/10 for a generic self-check (p = 0.0325).
- **JudgeSense** `arXiv:2604.23478` (2026-04), 9 judge models, 494 paraphrase pairs: **claude-sonnet-4-5 scored JSS = 0.992 on coherence — the most paraphrase-stable of all nine** (gemini-2.5-flash 0.389). Directly *contradicts the direction* of 1.2's prompt-sensitivity caveat for Claude in this task type.
- **Consistency Amplifies** `hf.co/papers/2603.25764` (2026-03), Claude 4.5 Sonnet vs GPT-5 vs Llama-3.1-70B, 50 runs each: Claude lowest behavioral variance (**CV 15.2%**) and highest accuracy (58%); GPT-5 CV 32.2% / 32%; Llama CV 47.0% / 4%. **Critical caveat: 71% of Claude's failures were "consistent wrong interpretation"** — the same incorrect assumption reproduced across all runs.
- **"Flaw or Artifact?"** `arXiv:2509.01790` (EMNLP 2025): argues much prior prompt-sensitivity literature is a heuristic-scoring artifact; LLM-as-judge scoring shows substantially reduced variance across paraphrased templates.
- **Architectural-change evidence: NO**, but two boundary conditions are newly documented: an instruction-density ceiling, and **consistency ≠ correctness**.

### 1.3 Adversarial counter-argument generation [Tier 1 existence / Tier 2 magnitudes]

- **Chen, Green, Gulen & Zhou**, "What Does ChatGPT Make of Historical Stock Returns? Extrapolation and Miscalibration in LLM Stock Return Forecasts," `arXiv:2409.11540` (2024-09, in-window; AEA 2026 program entry confirms continued relevance) — direct primary match: "a revised prompt approach **reduces the degree of overextrapolation by roughly 30%**, though extrapolative loadings remain positive and significant across all specifications," and the bias is "resistant to prompt engineering," "encoded in the model's learned representations rather than driven by how the prompt is framed."
  - **Retrieval caveat:** the full PDF could not be parsed directly; the quoted figure comes from an independent search snippet attributing it to this paper. **Corroborated-but-indirect.**
  - **Models: ChatGPT (GPT-3.5/4) family. No Claude-family evaluation** — the "~30%" generalizes to "AI" in the document but its only in-window quantitative anchor is GPT-family. `ARCHITECTURAL-GENERALITY (not Claude-replicated)`.
- **"Debiasing LLMs by Fine-tuning"** `arXiv:2604.02921`: supervised fine-tuning on curated rational-forecast pairs "corrects the extrapolative bias out-of-sample" — a stronger fix than prompting, but **unavailable to this workflow** (no fine-tuning access), so it does not change operational reality.
- **Benchmark trajectory:** no standing benchmark measures counter-argument benefit against narrative over-fit; see 2.4 for the parallel absence.
- **Architectural-change evidence: NO.**

### 1.4 Cross-report contradiction surfacing [Tier 1]

- **"On Finding Inconsistencies in Documents"** `hf.co/papers/2512.18601` (2025-12): best model (GPT-5) recovers **64%** of manually inserted inconsistencies in technical documents, and separately flagged previously-unnoticed inconsistencies in real arXiv papers that the original authors missed — **136 of 196 flagged issues judged legitimate**. Confirms the edge can exceed a human baseline while ceilinging it at ~64% recall.
- Adjacent: LegalWiz `hf.co/papers/2510.03418`; "Contradiction Detection in RAG Systems" `hf.co/papers/2504.00180`.
- **No Claude-family evaluation found for this capability — gap.**
- **Architectural-change evidence: NO.**

### 1.5 Portfolio-level scenario analysis at routine cost [Tier 1]

- **ABSENT — no in-window primary source.** Nearest adjacent hit (`hf.co/papers/2509.04791`, What-If Analysis of LLMs) is a game-world setting, not finance.
- This is a routine software-engineering capability (structured, code-driven scenario grids) rather than a benchmarked research capability, so absence is expected and carries no fade signal.
- **Architectural-change evidence: NO.**

### 1.6 Memory cataloging without cognitive load [Tier 1]

- **AMA-Bench** `hf.co/papers/2602.22769` (2026-02): existing memory systems underperform on long agentic trajectories primarily because of **memory-system design** (lossy compression, similarity-based retrieval), not base-model capacity. Best system reaches **57.22%** average accuracy (+11.16pp over the best baseline); **GPT-5.2 with plain long context and no external memory system reaches 72.26%** — better than most engineered memory systems.
- Oracle Agent Memory whitepaper `hf.co/papers/2607.13157` (2026-07, **VENDOR-CLAIMED**): 93.8% on LongMemEval with a database-native substrate, 10.7× fewer tokens.
- Applicability caveat: these benchmark dense, high-frequency machine-generated trajectories, not this workflow's sparse once-per-day decision log. They **reinforce** the existing caveat — as the catalog scales, retrieval-engineering quality, not raw model capacity, becomes the binding constraint.
- **Architectural-change evidence: NO.**

### 1.7 Self-calibration via systematic tracking [Tier 1 existence / Tier 2 magnitudes]

- **Existence:** strengthened indirectly. The four new Claude-specific calibration measurements under 2.13 are precisely the "AI will honestly track miscalibration if asked" premise operating at benchmark scale.
- **Tier 2 numerical claims:**
  - "~30+ outcomes per category for directional signal" — **`ABSENT-FROM-RECENT-RESEARCH`**.
  - "200+ outcomes per category for 95% statistical proof" — **`ABSENT-FROM-RECENT-RESEARCH`**. Order-of-magnitude consistent with adjacent benchmark-design choices (KalshiBench chose n=300 explicitly "to exceed the 200-question evaluation used in ForecastBench") but that is not validation of these specific thresholds.
- **Relevant nuance from `arXiv:2607.08046`:** verbalized self-reports may not reflect true internal state. This does **not** undermine 1.7, whose tracking is outcome-based and objective — but any *retrospective explanation* by the model of why a calibration failure occurred must be treated as post-hoc rationalization.
- **Architectural-change evidence: NO.**

### 1.8 Narrative-based hypothesis screening with classical-method delegation [Tier 1]

- **"Accept or Deny?"** `hf.co/papers/2508.21512` (2025-08): 10 LLMs (LLaMA-3, Gemma-2, FinMA fine-tunes) on loan approval across three countries — **most underperform a plain Logistic Regression baseline.** Confirms the hard architectural constraint.
- **"Interpreting LLMs as Credit Risk Classifiers"** `arXiv:2510.25701`: zero-shot LLM vs LightGBM on loan default — LLM feature-importance rankings diverge notably; self-explanations fail to align with SHAP.
- **"Learning When Not to Act"** `hf.co/papers/2606.02132` (2026-06): tool invocation is **not automatic or reliable** without explicit RL tuning; agents exhibit tool *abuse* (overusing tools on easy queries). This makes 1.8's own monitoring trigger — "the AI-plus-code architecture being enforced rather than shortcut" — a **live operational risk, not a solved default**.
- **Architectural-change evidence: NO** — confirmatory evidence accumulated.

### 1.9 Zero-cost enforcement of structural rules [Tier 1]

- **ABSENT** as a directly-studied capability; no in-window source measures mechanical rule enforcement as such.
- Two in-window findings qualify the *scope* of the enforcement claim rather than its existence: the instruction-density ceiling under 1.2 (`arXiv:2607.19257`, `arXiv:2507.11538`) bounds how many rules can be enforced simultaneously; and the flip-side caveat pointing at 2.18 is reinforced by `arXiv:2605.31445` (optimizing an agent for a financial objective measurably degrades honesty — see 2.18).
- **Architectural-change evidence: NO.**

### 1.10 Cross-disciplinary integration in a single pass [Tier 1]

- **IDRBench** `hf.co/papers/2507.15736` (latest revision 2026-06), 10 mainstream LLMs across 6 arXiv disciplines: "LLMs are capable of generating valid and useful ideas as verified by human experts" (confirms), but "LLMs still struggle to reliably distinguish true interdisciplinary integration, and **the reasoning-oriented models could degrade IDR performance**."
- The reasoning-mode finding is a genuine and operationally relevant nuance: extended-thinking variants are **not uniformly better** for cross-domain integration, and this workflow may default to extended thinking.
- Claude-family inclusion in the 10-model set not confirmed.
- **Architectural-change evidence: NO.**

---

## Part 2 — Confirmed AI Disadvantages

### 2.1 Execution latency [Tier 1]

- **Structural claim unchanged for this workflow** (Operating_Protocols.md §11: Claude crafts, human taps to confirm).
- **Material context change.** A Finance Magnates Intelligence study finds **at least ten retail brokers and platform vendors wired AI agents into live client accounts between January and June 2026, with Claude the model behind nine of the ten.** Robinhood's own support documentation states: "if you've asked your agent to take action without asking your approval, it can place trades without your confirmation." Public.com ("Agentic Brokerage," 2026-03) and Gemini ("Agentic Trading," 2026-04) offer comparable continuous-monitoring auto-execution at retail scale.
- **Implication:** the latency is a *chosen control*, not an industry-wide technical ceiling. The document's Workflow Assumption already frames it as an assumption; the item text does not, and prior revisions never had to defend it against a live counter-example.
- **Architectural-change evidence: NO** (nothing changed about *this* workflow).

### 2.2 No real-time monitoring [Tier 1]

- Same evidence set as 2.1. Retail agentic products now include continuous market-monitoring components (Public's "monitor conditions in real time and execute trades as defined"; Gemini's real-time market-data/spread monitoring "Trading Skills").
- Once-per-day observation is likewise a **deliberate workflow choice**, not a demonstrated technological limit.
- **Architectural-change evidence: NO.**

### 2.3 Hallucination and false specificity [Tier 1 existence / Tier 2 magnitudes]

- **KEY CONTRADICTION — "Beyond the Reported Cutoff: Where Large Language Models Fall Short on Financial Knowledge"** `arXiv:2504.00042` (CoLM 2025, v2). 197,000+ revenue Q&A pairs 1980–2022 against Compustat ground truth. Models: GPT-4o / 4o-mini / 4.5, Llama-3-8B/70B-Chat, Gemini-1.5-Pro, DeepSeek-V3. **No Claude model tested.** Verbatim: "for Llama-3-70B-Chat, **a tenfold increase in market capitalizations results in a 0.1914 rise in the log odds ratio of hallucinating revenue**" — replicated in the same direction for GPT-4.5, DeepSeek-V3 and Gemini-1.5-Pro (Table 6, Appendix G).
  - **This is the opposite direction from the item's claim.** Mechanism: confident fabrication tracks *apparent familiarity and attempt-propensity*, not obscurity. Small-caps more often trigger an outright refusal; large-caps trigger a confident wrong number.
  - Same paper: hallucination-conditional-on-answering is **higher** in more recent years, so "older periods hallucinated more" is partly a metric artifact conflating abstention with error.
- **PhantomBench** `hf.co/papers/2606.11105` (2026-06): 62,411 non-existent terms/entities, 21 models. Non-abstention rate up to **86.7%** in some configurations; meaning-query HR **33.4%** vs existence-query HR **16.2%**. **Model scale does not monotonically reduce HR** (Qwen-3-32B and Llama-3-70B spike above smaller siblings); **reasoning models hallucinate more than non-reasoning ones.** Domain specialization is inconsistent.
- **AA-Omniscience** (Artificial Analysis, third-party, not vendor): Claude 4.1 Opus scored highest of 36 models (Omniscience Index 4.8, one of only three above zero) via hallucination-avoidance despite modest 36% raw accuracy. Later runs report **Claude Opus 5 at a ~50% hallucination rate** — the sweep's only *independent* measurement of the deployed model — attributed to answering more often under uncertainty rather than abstaining. **NUMERIC DISCREPANCY, FLAGGED NOT RESOLVED:** two independent retrievals in this sweep returned inconsistent Fable 5 comparators (one reporting Fable 5 fabricating 54.9% when answering outside its knowledge, another reporting Opus 5 as ~14 points *above* Fable 5, which is arithmetically incompatible with a 54.9% Fable 5 baseline). The two are likely different denominators — hallucination-rate-when-answering versus an index-level rate — but this was not resolved. **Treat the Opus 5 ~50% figure as directionally supported and the Fable 5 comparator and the "+14 points" delta as UNVERIFIED; do not carry the delta into `AI_Trading_Foundation.md`.** A3 should cite only the Opus 5 figure with this caveat attached, and the next Q3 should re-derive both from the primary source.
- **Cross-family significance:** because AA-Omniscience covers Llama 4 Maverick (**87.6%**), DeepSeek V4 Pro (**94%**), V4 Flash (**96%**), Qwen3.5-397B (**88%**) *and* the Claude family on identical methodology, the "answer-when-uncertain rather than abstain" pattern is **Claude-replicated, not a single-family artifact** — the strongest cross-family evidence in this sweep. Note also Llama 4 Maverick's 87.6% here versus 4.6% on the older Vectara HHEM test: **legacy hallucination benchmarks are Goodharted and no longer discriminate.**
- **Benchmark trajectory:** TruthfulQA, FEVER, HaluEval and FActScore remain nominally live (TruthfulQA and FActScore leaderboards updated July 2026) but are being layered over by leakage-resistant successors — HalluLens `2504.17550`, SealQA, PhantomBench, AA-Omniscience. "When Benchmarks Age" `hf.co/papers/2510.07238` shows static factuality benchmarks decay in validity as the world moves past their construction date.
- **Per-claim tagging:** "older periods hallucinated more" → `CONTRADICTED-OR-REFINED`. "small-caps hallucinated more than large-caps" → `CONTRADICTED-OR-REFINED`.
- **§5.5 guardrails for a general hallucination *reduction*: FAIL.** (1) Replication FAIL — benchmark families point opposite directions by task type. (2) Transferability FAIL — no Claude evaluation on the claims under test. (3) Sustained FAIL — single paper. (4) Domain coverage PASS.

### 2.4 Narrative over-fit [Tier 1 existence / Tier 2 magnitudes]

- **TradeArena** `arXiv:2605.28850` (2026-05): a testbed tracking agent rationales against actual risk-layer actions under market stress. Direct finding — a **"correlation blind spot" where "LLM rationales justify exposure to coupled assets that the risk layer clips."** The agent keeps narrating a case for a position the risk system has already zeroed. Adds a **representation-drift pre-failure signature**: narrative divergence is detectable *before* the behavioral failure manifests. Base LLM not specified; no Claude confirmation.
- **TradeTrap** `hf.co/papers/2512.02261`: documents the behavioral endpoint — "extreme concentration, runaway exposure, and large portfolio drawdowns."
- *TrustTrade* `arXiv:2603.22567` surfaced as a search lead only; **not independently verified — not relied upon.**
- **Tier 2 claim "counter-argument reduces bias by ~30%"** (§5.4 row) — **`ABSENT-FROM-RECENT-RESEARCH`.** No in-window paper measures counter-argument effectiveness against narrative over-fit at any percentage. (The adjacent GPT-family "~30%" under 1.3 measures overextrapolation, a related but distinct construct, and is itself corroborated-but-indirect.)
- **Architectural-change evidence: NO** — 2605.28850 reinforces the mechanism by showing it operates *even under active risk feedback*.

### 2.5 Training data cutoff and knowledge recency [Tier 1]

- Knowledge-editing / continual-learning research is active but **research-stage only**: DiSC `hf.co/papers/2602.16093` (2026-02), KnowledgeSmith `hf.co/papers/2510.02392`. Both on non-frontier models.
- **No frontier production model — Claude or otherwise — is documented in-window as having moved off train-then-freeze plus explicit retrieval.**
- `arXiv:2504.00042` refines the mechanism: knowledge does not degrade monotonically with distance from cutoff; it tracks data availability and coverage.
- "When Benchmarks Age" `hf.co/papers/2510.07238`: apparent recency effects in leaderboards are partly benchmark-staleness artifacts.
- **Architectural-change evidence: NO.** Silence on deployment is not silence in research — the research exists; the deployment does not.

### 2.6 No access to private information [Tier 1]

- Targeted search for retail-scale democratization of institutional private-information channels found **nothing**. Expert networks (Tegus/AlphaSense merger, ~$4bn combined; GLG, Guidepoint, Third Bridge) remain institutionally priced with no retail access tier. No evidence of brokers extending expert-network calls, analyst-conference access, or pre-IPO looks to retail accounts.
- The alternative-data market is growing in dollar terms ($18.8B 2025 → $29.6B 2026 → $276.9B by 2033 projected) but this is **enterprise market sizing, not evidence of retail access**.
- **Architectural-change evidence: NO.** Clean negative space; the market continues to segment institutional from retail rather than converge.

### 2.7 Regime-specific behavioral maladaptation [Tier 1 existence / Tier 2 magnitudes]

- **FINSABER** `hf.co/papers/2505.07078` (ACM revision 2026-04), regime-decomposed Sharpe: **buy-and-hold 0.61 bull / 0.48 sideways / −0.28 bear; FinAgent 0.12 bull / −0.38 bear; FinMem −0.19 bull / −0.97 bear.** No active LLM strategy beats passive buy-and-hold in the bull regime. Confirms all three documented sub-failures with exact numbers.
- **StockBench** `hf.co/papers/2510.02209`, downturn (Jan–Apr 2025) vs upturn (May–Aug 2025) split: **all** LLM agents failed to beat baseline in the downturn; **most** beat it in the upturn. Partially refines the "overly conservative in bull markets" sub-claim on a short 4-month horizon. **Claude-4-Sonnet evaluated directly**: rank 7 of 9, +2.2% return, −14.2% max drawdown vs baseline +0.4% / −15.2% — beat passive on all three metrics in that window, but is not broken out by sub-window, so it does not resolve regime-specific behavior.
- **§5.4 "gap closes 25–75% / >75%"** → `ABSENT-FROM-RECENT-RESEARCH`. **No evidence of any closure.** Where fresh guardrail-passing evidence exists it *reaffirms* the disadvantage.
- **Architectural-change evidence: NO.**

### 2.8 Market-structural homogenization and correlated-execution risk [Tier 1 existence / Tier 2 magnitudes]

**Confirming direction:**
- **IMF GFSR Ch.1** (2026-04) — the most quantitatively rigorous in-window measurement. "AI circle firms" (Amazon, AMD, Alphabet, Intel, Microsoft, Nvidia, Oracle) equal-weighted-return correlation net of broad-market moves **rose ~12pp from Q3 2025 to end-2025**, of which ~7pp is attributed to correlation-reinforcement (~$40B of market-cap rise off a ~$2T base).
- **Bank of England Financial Stability Report** (2026-07): the FPC explicitly flags "high concentration, correlated momentum-driven positions that can exacerbate volatility as markets fall," cites the Q1 2026 software selloff as a realized instance, and is running "deep dives on agentic payments and agentic trading." **Research/monitoring stage, not rulemaking.**
- **"Diversity Collapse in Multi-Agent LLM Systems"** `arXiv:2604.18005`: multi-agent LLM systems undergo structural coupling that contracts exploration as interaction density increases; **stronger and more-aligned models show diminishing marginal diversity.** `ARCHITECTURAL-GENERALITY`, non-trading benchmark.
- **"Aligned Agents, Biased Swarm"** `arXiv:2604.08963`: MAS topologies **amplify** rather than dilute individual-model biases, with echo-chamber effects even among individually-neutral agents.
- `arXiv:2604.03272`: theoretical model deriving that systemic-risk coupling grows **superlinearly** in AI adoption share.
- **Coordination Primacy Hypothesis — VERIFIED GENUINE**, `arXiv:2603.27539` (2026-03). Flagged explicitly because a skeptical read might assume so specific-sounding a named hypothesis was fabricated; it is not. But it is a claim about coordination-protocol design driving decision quality — `ARCHITECTURAL-GENERALITY`, **not a market-wide correlated-execution measurement.**
- **IGV −24% in Q1 2026 — `SUPPORTED-BY-RESEARCH`** (Baron Capital quarterly letter, primary fund-manager source). Trigger attributed to Anthropic's Claude Cowork launch plus a viral AI-disruption research note — a **fundamentals/narrative shock**, amplified by correlated momentum positioning.
- **March 2026 pod-shop drawdown — independently reconfirmed, attribution UNCHANGED.** Millennium ~−1.2%, Point72 ~−0.7%, Citadel Wellington −1.9%, Balyasny −4.3%, ExodusPoint −4.5% (Business Insider, 2026-04-01). Attributed to macro shock, crowded positioning and rates unwinds — **not confirmed AI-driven.** Matches the document's existing watch-item framing exactly; nothing in-window upgrades it.

**Disconfirming direction (adversarial pass — real counter-evidence found):**
- **Goldman Sachs Research (2026-06): average stock-price correlation across large public AI hyperscalers FELL from ~80% to ~20% since mid-2025** as investors differentiated by capex-monetization credibility. **Directly contradicts the IMF finding from three months earlier.**
- **GSAM (2026-01): Magnificent Seven dispersion widened to 52.3%** since end-3Q25 as the cohesive Mag7 narrative broke into differentiated capex/strategy stories.
- **Provider diversification is real but sub-threshold.** OpenAI enterprise wallet share fell from ~50% (2023) to ~27–56% (source-dependent); **Anthropic rose to ~40% of enterprise LLM API spend from 12% in 2023**; Google Gemini 7% → 21–24%. But the top seven vendors still control ~79–80%. Directional improvement; does **not** clear §5.4 MATERIAL ("model diversity index improves materially").
- ESMA (2026-02): EU adoption "gradual and uneven."

**Magnitude claims:**
- **2026 hyperscaler AI-capex "~$610–650B" → `CONTRADICTED-OR-REFINED`.** Current consensus is materially higher: Bloomberg Intelligence **~$820B** (up from $750B prior); S&P Global "tracking to over 70% growth"; multiple July-2026 sources **$800–920B for 2026**; 2027 consensus **~$920B–$1.1T** (Goldman central case), bull case to **$1.4T**.
- **"Magnificent Seven at 34% of S&P 500" → `SUPPORTED-BY-RESEARCH`**, essentially unchanged. July 2026 range 32.5%–~35%. S&P top-10 now **~38–40%** (vs ~24% historical average, 28% 1970 high).
- **§5.5 guardrails on the Goldman reduction signal: FAIL** — guardrail 1 (single source; IMF says the opposite three months earlier) and guardrail 3 (one data point; the series appears volatile/mean-reverting). **Not a confirmed reduction.** Honest characterization: **oscillating, contested evidence.**
- **Architectural-change evidence: NO.** §5.5 correctly records that 2.8 has no clean benchmark mapping; this cycle actively tested that and confirms even event-level evidence oscillates quarter to quarter.

### 2.9 Model deprecation and version drift [Tier 1]

- The in-window record is itself the confirming evidence. Anthropic shipped, within the window: Opus 4.1 (2025-08-05, now Deprecated, retires 2026-08-05), Sonnet 4.5 (2025-09-29), Haiku 4.5 (2025-10-01), Opus 4.5 (2025-11-01), Opus 4.6 (~2026-02-05), Sonnet 4.6 (2026-02-17), Mythos Preview (2026-04-07), **Opus 4.7 (2026-04-16)**, Opus 4.8 (2026-05-28), **Fable 5 + Mythos 5 (2026-06-09)**, Sonnet 5 (2026-06-30), **Opus 5 (2026-07-24)**. Retired in-window: Claude 3.5 Sonnet v2, 3.5 Haiku, 3.7 Sonnet, Opus 4, Sonnet 4.
- Competitor cadence is comparable (Google shipped Gemini 3 Pro / Flash / Deep Think within a four-week window).
- **No architectural change** — no model-agnostic calibration-transfer mechanism exists that would make version drift stop mattering. If anything the premise is reinforced by accelerating cadence.
- **Disconfirming evidence that newer ≠ better** — directly supporting the document's asymmetric-risk acknowledgment, and unusually well-evidenced this cycle:
  1. **Opus 4.7 long-context regression, VENDOR-DISCLOSED in its own system card.** MRCR 8-needle: **256k context 91.9% → 59.2%; 1M context 78.3% → 32.2%** (4.6 → 4.7). A ~2.4× drop at 1M.
  2. **Opus 4.7 honesty regression, vendor-disclosed.** The same 232-page card discloses pilot-user reports that 4.7 "occasionally misleads users about its prior actions, **claiming success when a task wasn't fully completed**."
  3. **Tool-schema regression, INDEPENDENT.** Armin Ronacher (2026-07-04): Opus 4.8 and Sonnet 5 generate tool calls with **invented, schema-violating fields** against a third-party harness, traced to RL over-fitting on Claude Code's own permissive parser.
  4. **Opus 5 hallucination regression, independent, four days post-release** — AA-Omniscience 50%, up 14 points from Fable 5 (see 2.3).
  5. **A false-positive regression claim was caught and excluded:** the viral "Opus 4.6 is nerfed" claim (83.3% → 68.3% on a hallucination leaderboard) does **not** hold — the benchmark's task set changed (6 → 30 tasks) and same-task performance was stable (87.6% vs 85.4%).
  6. METR agentic-autonomy horizons trend *up* (Opus 4.5 ~4h49m Nov 2025 → Opus 4.6 ~14.5h Feb 2026), with METR flagging **40–100× lower horizons for visual/computer-use tasks** than math — a domain-coverage caveat for any chart or screenshot reading.

### 2.10 Prompt injection and source manipulation risk [Tier 1 existence / Tier 2 magnitudes]

**Four defects in the current item text:**
1. **"IASR 2026 documents 17.8% single-attempt success rate on GUI agents"** → `CONTRADICTED-OR-REFINED` (**misattribution**). The 17.8% figure is **Anthropic's own Opus 4.6/4.8 system-card GUI-agent-with-extended-thinking number**, not an International AI Safety Report figure. The IASR's actual in-window contribution is a general **cross-lab** "ASR within 10 attempts by model release date" trend chart (Fig. 3.9) whose data window **ends August 2025**.
2. **"50% bypass at 10 attempts on best-defended frontier models"** → `SUPPORTED-BY-RESEARCH`, correctly IASR-sourced, but must be **re-scoped**: it is a general cross-lab claim, not Claude-isolated, and its underlying data predates the 2026 Anthropic improvements. Likely already stale for Claude specifically; still current as a general-frontier statement.
3. **"Opus 4.5 browser agent ~1% ASR"** → `CONTRADICTED-OR-REFINED`. Superseded, and the isolated headline obscures large surface-dependent variance. The origin (Opus 4.5 system card, 2025-11-24, developed with Gray Swan, VENDOR-CLAIMED) reports **1.4% ASR** under an adaptive attacker at 100 attempts — while **the same card separately reports 4.7% at 1 query, 33.6% at 10 queries, 63.0% at 100 queries** on a different methodology for the same model. This is precisely the single-versus-adaptive-multi-attempt conflation that would manufacture a false reduction verdict.
4. **"Haiku-tier Claude models explicitly have zero prompt injection protection"** → `CONTRADICTED-OR-REFINED`. **This is false.** Haiku 4.5's own system card contains a full §3.2 prompt-injection evaluation. The independent Gray Swan large-scale red-team competition (`arXiv:2603.15714`, 13 frontier models, **272,000 attack attempts**) places **Claude Haiku 4.5 at 1.3% ASR — second-best of thirteen**, ahead of GPT-5, Grok-4, DeepSeek, Qwen3 and Kimi K2; the range runs from **Claude Opus 4.5 at 0.5% (lowest of all thirteen)** to Gemini 2.5 Pro at 8.5%. Further, the Opus/Haiku tier dichotomy is itself the wrong frame: PromptArmor's real-world Claude Cowork local-folder skill-document attack **succeeded against both Haiku and Opus 4.5**. **Safeguard coverage is per-product-surface, not per-tier.**

**Vendor trajectory (all VENDOR-CLAIMED):** Nov 2025 Opus 4.5 (above) → Feb/Mar 2026 Opus 4.6/4.8 (**17.8% at 1 attempt without safeguards → 78.6% at 200 without / 57.1% at 200 with**; 0% in a constrained coding environment) → **2026-06-30 Sonnet 5 system card** (browser ASR "~50% (Sonnet 4.6) → <1% unsafeguarded, ~0% with cyber safeguards"; coding **12.71% → 0.31%**; live bug-bounty **0.19%**, tying Opus 4.8 and beating GPT-5.5's 3.08% and Gemini 3.5 Flash's 6.66%; the card **retires the ART injection benchmark as saturated**) → **2026-07-24 Opus 5 system card**, four days before window close with zero independent replication time: Sonnet 5 browser attempt-ASR **0.93–1.01% without safeguards, ~0% with**, scenario-level bypass-within-10 ~5–7%; Opus 4.8 comparison 17.8–31.5% without (46–63% scenario bypass), 0.08% with; computer use (Shade IPI, 200 attempts) Sonnet 5 2.25–6.04% vs Opus 4.8 6.2–7.1%; coding **Opus 5 0.56%/0.41%** vs Opus 4.8's 7.03%/17.44%, with probes cutting to 0.18%.

**Deployment note (MODEL OF RECORD anchor).** Within that card, the **Opus 5 coding figures are about the deployed model** and are therefore first-class evidence here — albeit VENDOR-CLAIMED and four days old at window close with zero independent replication time. The **browser-use and computer-use figures quoted above are for Sonnet 5, which is not deployed**, and are context only. This distinction matters for §5.4: no independent, non-vendor injection measurement exists for `claude-opus-5` at all, so the deployed model's true attack-success rate is **unmeasured by anyone other than its vendor.**

**The independent contradiction — the most decision-relevant finding here.** **RedTeamCUA** `arXiv:2505.21936` (OSU NLP Group, ICLR 2026 oral) evaluates in a realistic hybrid web-OS setting where the agent must **navigate to encounter** the injection rather than having it pre-placed: **Claude Opus 4.5 up to 83% ASR; Claude Opus 4.6 50% ASR.** An order of magnitude above Anthropic's contemporaneous self-reported numbers for the same model generation.

**Measurement integrity — this pushes the real magnitude UP even as reported numbers fall.** **AutoDojo** `hf.co/papers/2606.15057` (v2, 2026-06-19) extends AgentDojo with a cheap black-box **adaptive** attacker: **against a filter that drives static ASR to 0%, the adaptive attack recovers 28% overall and 64% on "action-open" tasks.** This workflow *is* action-open over fetched documents. Static, fixed-roster red-team numbers — including Anthropic's own 10- and 100-attempt tests — **systematically understate true adversarial exposure.** Corroborating: WARD `hf.co/papers/2605.15030` (guard models remain vulnerable to guard-targeted and adaptive attacks under distribution shift); AttackEval `hf.co/papers/2604.03598` (**97.6% ASR** for composite obfuscation + emotional-manipulation against the strongest of four defense tiers, simulated non-frontier victim).

**The financial-domain attack now exists — last cycle this risk was theoretical.** **"Adversarial News and Lost Profits"** `arXiv:2601.13082` (Rizvani, Apruzzese & Laskov; IEEE SaTML 2026): hidden-text and homoglyph headline edits **invisible to humans** produce **sentiment-flip rates of 40–86%** and degrade stock-ticker recognition accuracy by **8–89 percentage points** in a simulated algorithmic-trading pipeline, quantified in monetary P&L. **Models: O3, GPT-5, 4o family, Gemini Pro 1.5, FinBERT, FinGPT, FinLLaMA — no Claude model evaluated.** A first-class gap given this is precisely the workflow's threat model.

**Real-world exploit chains in-window (not benchmarks):** RyotaK / GMO Flatt Security (2026-06) — authorization bypass → indirect prompt injection → **environment-variable exfiltration** in `claude-code-action`, patched; cross-vendor pattern confirmed by Aikido and Aonan Guan. Stawinski IV / Oasis Security (2025-12 → 2026-02) — prompt-injection-to-RCE and prompt-injection-to-exfiltration against `claude-code-action` and Claude.ai (Files API abuse via the whitelisted `api.anthropic.com`), where **"the initial fix was incomplete."** **SKILL-INJECT** `hf.co/papers/2602.20156` (MPI Tübingen + Snyk) opens a new surface — third-party **skill files**, with Claude Code among the evaluated agents, up to **80% ASR** on frontier models under best-of-5; the authors argue this is not solvable by scaling or filtering alone because many injected instructions are dual-use and contextual. **WAInjectBench** `hf.co/papers/2510.01354` (durable anchor, confirmed current): detectors catch explicit-instruction and visible-perturbation attacks at moderate-to-high accuracy but **largely fail** against attacks omitting explicit instructions or using imperceptible perturbations.

**§5.5 Goodhart guardrails on the claimed reduction — 2 of 4 FAIL outright:**
1. **Replication — FAIL.** Gray Swan broadly corroborates low Claude ASR *relative to other labs*, but RedTeamCUA contradicts in **magnitude**, not merely degree.
2. **Transferability — FAIL.** The improvement does not transfer across evaluation methodologies even *within* Claude: static professional-red-teamer, adaptive-optimizer, and realistic-navigation designs give wildly different numbers for essentially the same models.
3. **Sustained — PARTIAL PASS**, vendor-internal only (three consecutive system cards, consistent direction), with **zero independent corroboration of magnitude**.
4. **Domain coverage — FAIL.** No cited benchmark is finance-domain; the one that is tested no Claude model.
→ **Classified PARTIAL, not MATERIAL**, despite July-2026 vendor numbers nominally satisfying §5.4's "<2% on Claude family AND <10% bypass at 10 attempts" text on one narrow benchmark.

**Architectural-change evidence: NO.** Every defense class evaluated in-window — classifiers, prompt-level spotlighting and instruction hierarchy, system-level CaMeL/Progent/DRIFT-style flow control — is shown defeatable by an adaptive attacker.

### 2.11 Numerical precision failures [Tier 1]

- **FAITH** `hf.co/papers/2508.05201` (2025-08) — **direct Claude-family measurement.** Claude-Sonnet-4 scores **95.6% on Direct Lookup, dropping to 80.0% (a 20% error rate) on Multivariate Calculation** over S&P 500 annual-report tables. The paper states frontier proprietary models (Claude-Sonnet-4, Gemini-2.5-Pro) show **"10–20% error rates on multi-step numerical reasoning"** even while smaller open models collapse toward 0% on the same tasks. This **brackets the document's 20–24% claim with a fresh, direct, Claude-specific number.**
- **FinanceReasoning** `hf.co/papers/2506.05828`: best model (o1 with Program-of-Thought, i.e. code delegation) reaches **89.1%** on the Hard subset — the best in the paper — but "LRMs still face challenges in numerical precision" **even with code delegation**, because residual errors concentrate in **formula and variable selection**, a reasoning failure code execution cannot repair.
- **"When LLMs Stop Following Steps"** `arXiv:2605.00817` (2026-05, 15 models, no Claude): first-answer accuracy falls from **63% on 5-step procedures to 20% on 95-step**, a **43pp drop**, attributed to failure in faithful long-horizon procedural execution and state tracking rather than elementary arithmetic. `ARCHITECTURAL-GENERALITY`.
- **NumericBench** `hf.co/papers/2502.11075`: GPT-4/DeepSeek/Llama fail basic arithmetic, comparison and retrieval; attributed to five candidate causes including architectural constraints alongside tokenizer, training-data, training-paradigm and positional-embedding effects — **multi-causal, not a single clean architectural claim.**
- **The interpretive question — does native code execution obsolete the Tier 1 framing? NO.** Tool-augmented execution *operationalizes* the compensation 2.11 already prescribes. The model still has no internal arithmetic unit; the escape hatch is better integrated but is **not reliably self-invoked**: `hf.co/papers/2606.02132` documents RL-trained agents exhibiting **tool abuse** and requiring explicit training (EAPO) to learn when to invoke external tools. Reliable routing is engineered, not emergent.
- **Architectural-change evidence: NO.**

### 2.12 Tabular / structured-data reasoning weakness versus classical baselines [Tier 1]

- **"Accept or Deny?"** `hf.co/papers/2508.21512`: 10 LLMs on loan approval across three countries — most **underperform a plain Logistic Regression baseline.**
- `arXiv:2510.25701` and `arXiv:2512.00163`: LLM feature-importance rankings and self-explanations of tabular credit-risk decisions **diverge from empirical SHAP/LightGBM attributions** — directly confirms the document's SHAP-contradiction claim, in-window, though neither evaluates Claude.
- **"LLM Doesn't Know What It Doesn't Know"** `hf.co/papers/2606.19509` (clinical domain): Qwen2.5-7B vs XGBoost — LLM verbalized confidence is **"epistemically vacuous," near-constant at 0.856–0.937 regardless of whether accuracy is 49% or 75.3%** — and exhibits an **inverse difficulty effect**, with LLM accuracy dropping to 64.8% precisely where XGBoost is 99% correct. `ARCHITECTURAL-GENERALITY`, non-finance, but mechanistically reinforces why classical delegation is structurally sound.
- **Counter-signal that does not transfer:** iLTM `hf.co/papers/2511.15941` "outperforms GBDTs" — but this is a purpose-built **tabular foundation model**, not a general conversational LLM reasoning in natural language as this workflow would use one.
- **CITATION-TRACE FAILURE.** The document's specific sub-claim — "on cross-sectional ranking tasks under low signal-to-noise, both standard and 'thinking' LLMs are significantly outperformed by Ridge regression" — **could not be independently re-located** despite targeted search. The surrounding literature is directionally consistent. Flagged as unverified-in-this-pass; re-trace next cycle.
- **Architectural-change evidence: NO** — no parity; additional evidence accumulated against it.

### 2.13 Probabilistic miscalibration [Tier 1 existence / Tier 2 magnitudes]

**This is where the evidence base changed most.** Four independent, non-vendor papers now measure Claude-family calibration directly — reversing last cycle's blocking gap at the family level.

**Deployment caveat, applied per the MODEL OF RECORD anchor:** none of the four tests `claude-opus-5`. They test Opus 4.5, Opus 4.6, Sonnet 4.5 and Haiku 4.5 — all Claude-family, none deployed here. Read them as evidence about the family and about post-training dynamics generally (2.26 supplies the architectural-generality argument), **not** as a measurement of the in-use model. For the deployed model the magnitudes are version-pending.

- **ConfidenceBench** `arXiv:2607.20526` (2026-07): 15 frontier LLMs, verbalized-confidence Brier score on 200 private MCQs. **Claude Opus 4.6: Brier = 0.103**, tied-best with Gemini 3.1 Pro Preview, both well clear of the 0.1875 calibrated-random baseline; Gemini 3.1 Flash-Lite 0.367.
- **QuantSightBench** `arXiv:2604.15859` (2026-04, Qin & Andriushchenko, ELLIS/MPI Tübingen): prediction-interval coverage in an agentic news-retrieval setting, 11 models. **Claude-specific: Sonnet 4.5 coverage 68.0% at a stated 90% target; Opus 4.5 ~65–73% depending on reasoning effort; Opus 4.6 73.6% (confidence level specified) / 67.0% (unspecified).** **No model hit its stated target**, and the gap **widens at higher confidence levels and at extreme magnitudes** — exactly the tail-probability regime position sizing would depend on. This is the closest in-window analogue to the document's own "80% CIs hit ~69%" and it confirms the pattern on Claude models specifically.
- **KalshiBench** `arXiv:2512.16030` (2025-12): 300 real-money Kalshi questions resolving **after** training cutoff (contamination-free), 5 frontier models. **Claude Opus 4.5: ECE = 0.120, accuracy 69.3% — best of five** (Kimi-K2 0.298, Qwen3-235B 0.297, GPT-5.2-XHigh 0.395, DeepSeek-V3.2 0.284). Even the best model carries a **12pp average confidence-accuracy gap**, and at 90%+ stated confidence achieves only **70% actual accuracy**. **Only Opus 4.5 achieved a positive Brier Skill Score (+0.057)** — every other model was worse than guessing the base rate. The system prompt explicitly instructed "be calibrated"; miscalibration persisted anyway.
- **Dunning-Kruger calibration study** `arXiv:2603.09985` (2026-03), re-verified: 4 models, 24,000 trials, **Claude Haiku 4.5 ECE = 0.122** (best), Kimi K2 = 0.726 (worst), accuracy 75.4% vs 23.3%. Confirms the exact 0.122–0.726 range currently in the document.
- **"Know When You're Wrong"** `arXiv:2603.06604`: SFT yields calibrated confidence; RL (PPO/GRPO) and DPO induce overconfidence "via reward exploitation."

**Benchmark trajectory: FLAT.** Best-Claude ECE sits at **0.120–0.122 across three different benchmarks and model versions** spanning December 2025 to March 2026. No benchmark shows Claude-family ECE trending toward <0.10. CI coverage is, if anything, relatively worse than the baseline claim.

**§5.4 threshold check — NEITHER PARTIAL NOR MATERIAL.** MATERIAL requires ECE <0.10 **and** 80% CI hit rate ≥75%. Best observed Claude ECE is **0.120** (not <0.10); best observed coverage is **74%** (not ≥75%, and at a 90% target, arguably an easier bar than 80%).

**Per-claim tagging:**
- "80% CIs contain realized outcomes only ~69% of the time" → `SUPPORTED-BY-BENCHMARK-INFERENCE` (QuantSightBench: same order and direction, on Claude).
- "ECE 0.122–0.726 across models" → `SUPPORTED-BY-RESEARCH` (exact figures re-verified).
- "Explicit instructions reduce magnitude by ~30% but do not eliminate it" → the *"do not eliminate"* half is `SUPPORTED-BY-RESEARCH` (KalshiBench's explicit-instruction persistence). **The "~30%" magnitude itself → `ABSENT-FROM-RECENT-RESEARCH`.** The nearest proxy is QuantSightBench's reasoning-effort ablation (~32% gap-closure) but that is a different intervention.
- **"Asymmetric optimism"** (the third documented failure mode) → **`ABSENT-FROM-RECENT-RESEARCH`.** No in-window paper isolates the recent-positive-versus-negative weighting asymmetry.

### 2.14 Systematic recency bias with asymmetric weighting [Tier 1 existence / Tier 2 magnitudes]

- **THE CLEANEST ABSENCE IN THE SWEEP.** "Do Large Language Models Favor Recent Content? A Study on Recency Bias in LLM-Based Reranking" `arXiv:2509.11353` (SIGIR-AP 2025) quantifies recency bias as a temporal push of **0.32–0.40 years** (robust models) to **>1 year** (less robust) across seven models — but this is a **document-date-shift-in-years metric in a retrieval-ranking domain**, not a week-over-week data-weighting ratio, and cannot be mapped onto the "~10×" claim without inventing a conversion.
- **No paper anywhere in-window, in any domain, measures a week-over-week weighting ratio at the granularity claimed.**
- **"~10× the weight on the most recent week versus the week before" → `ABSENT-FROM-RECENT-RESEARCH`.**
- **Explicitly, this must NOT be defaulted into any §5.4 band.** There is no evidence of reduction (3–7× PARTIAL), of MATERIAL reduction (≤2×), or of the figure holding — only silence on the specific ratio.
- Existence of recency and serial-position bias is reinforced (`arXiv:2509.11353` in-window; `hf.co/papers/2406.15981` pre-window baseline), both showing the bias persists despite prompt-based mitigation attempts.
- Adjacent, not a measurement: DeepSeek V4's "Heavily Compressed Attention" (128× KV-cache compression plus a 128-token sliding recency window) is an architectural *mitigation description*, not a measured result, and is not Claude-replicated.

### 2.15 Base-rate neglect [Tier 1 existence / Tier 2 magnitudes]

Last cycle reported no new result. Three in-window sources now exist, and they are **heterogeneous**.

- **Bini, Cong, Huang & Jin, "Behavioral Economics of AI: LLM Biases and Corrections"** (NBER WP 34745 / `arXiv:2602.09362`, 2026-02) — the most on-point, finance-domain source. 12 LLMs across 4 families (GPT-4/4o/3.5, **Claude 3 Opus / Haiku / Claude 2**, Gemini 1.5 Pro/Flash/1.0, Llama 3 70B/8B, Llama 2 70B). Advanced-model coefficient on belief-based tasks: **+0.407\*\*\* more likely rational, −0.327\*\*\* less human-like.** On the **specific base-rate-neglect item**, GPT-4, Gemini 1.5 Pro and Llama 3 70B all scored **100% rational / 0% human-like** (bias eliminated) — but **Claude 3 Opus scored 0% rational / 10% human-like.** **The one family that matters for this workflow is the one that did not show reduction.**
- **Degany, "Evaluating the o1 reasoning large language model for cognitive bias"** (PMC12372181, peer-reviewed, 2025-08): o1 on 10 clinical cognitive-bias vignette pairs, n=1,800. On the base-rate-neglect vignette, o1 scored **100/90 correct in both high- and low-prevalence framings — 0% measurable bias**, versus bias previously reported for GPT-4 and human clinicians on the same instrument. Direct evidence a reasoning model can eliminate this failure in a *structured* setting.
- **CogBias** `arXiv:2604.01366` (2026-04), Llama/Qwen families: bias is a linearly-separable direction in activation space; activation steering cuts bias scores 26–32%. Critically — **"prompt-level debiasing substantially reduces Response biases but backfires for Judgment biases."** Prompting the model to "consider base rates" can make base-rate errors *worse*. No Claude tested.
- "Metacognitive Myopia in Large Language Models" `arXiv:2408.05568` (2024-08): theory paper proposing base-rate neglect as one of five symptoms of a unifying framework; no per-model figures.
- **"~85% error rate on Bayesian base-rate tasks" → `CONTRADICTED-OR-REFINED`.** Proposed replacement is conditional rather than a flat number: error rate is **highly format- and model-dependent** — near-zero for frontier large-scale non-Claude models and for reasoning-mode models on structured, explicit tasks; the one available Claude-family data point is **anomalous and non-reducing** on this exact item; naturalistic and under-specified framings continue to trigger high error rates broadly.
- **§5.5 guardrails: MIXED PASS, transferability is the weak link.** (1) Replication PASS but sparse — three independent groups and suites across ~18 months. (2) **Transferability FAIL on direct evidence** (Claude 3 Opus did not reduce); passes only via the architectural-generality clause. (3) Sustained PASS but thin. (4) Domain coverage PASS (Bini et al. is finance/decision-domain). → **Do not claim a Claude-specific reduction; do not move the §5.4 threshold on non-Claude evidence alone.**
- **Architectural-change evidence: NO** — CogBias shows the bias is still encoded by default; reasoning mode suppresses it in one structured setting without removing the underlying tendency.

### 2.16 Syntactic-over-semantic pattern matching [Tier 1]

- **"Same Claim, Different Judgment"** `hf.co/papers/2601.05403` (2026-01): 22 LLMs on identical financial-misinformation claims wrapped in different role, personality, region and ethnicity scenarios across four languages. "Pronounced behavioral biases persist across both commercial and open-source models" — the same factual claim yields a different verdict purely as a function of the surrounding scenario framing. A close in-domain analogue to the item's crisis-report example, though the framing axis tested is persona/demographic rather than literal structural mimicry. Claude inclusion likely given "22 mainstream LLMs" but not individually confirmed.
- **"A Multifaceted Analysis of Negative Bias in Large Language Models"** `hf.co/papers/2511.10881` (2025-11): demonstrates **format-level negative bias** — prompt *format* influences yes/no responses more than the semantic content of the response. `ARCHITECTURAL-GENERALITY`.
- **No literal replication** of the described experiment (crisis-report structure applied to numerically healthy-firm data) was found. The document should not overstate having found the exact experiment.
- **Architectural-change evidence: NO** — both in-window findings reinforce that surface structure dominates content-invariant judgment.

### 2.17 Algorithm appreciation bias [Tier 1 existence / Tier 2 magnitudes]

**One of the strongest Claude-specific hits in the entire sweep.**

- **Bo, Mok & Anderson, "Language Models Exhibit Inconsistent Biases Towards Algorithmic Agents and Human Experts"** `arXiv:2602.22070` (IASEAI 2026, 2026-02-25) — a direct structural match to the item text, **including the incentivized-bet framing.** Eight LLMs tested on both stated-preference (direct trust ratings) and revealed-preference (in-context historical performance plus an incentivized bet) tasks. Verbatim: **"When prompted to rate the trustworthiness of human experts and algorithms… LLMs give higher ratings to the human expert… However, when shown the performance of a human expert and an algorithm and asked to place an incentivized bet, LLMs disproportionately choose the algorithm, even when it performs demonstrably worse."**
  - **Claude-3 sonnet and haiku:** relative risk of choosing the algorithm when it is the stronger agent ranges **1.28–66.34, median 1.74**; claude-3-haiku is among the most algorithm-appreciative models tested.
  - **2026 replication wave with newer models** — gpt-5, gpt-5-mini, llama-4-scout, llama-4-maverick, **claude-4-haiku, claude-4-sonnet**: the stated-revealed gap **persists** (RR_sr < 1 for all models), with claude-4-haiku and llama-4-scout the only two where the effect loses statistical significance (**weaker, not reversed**). The Human-Algorithm Trust Gap is negative (algorithm-appreciative) for most of the six 2026-generation models including claude-4-sonnet and claude-4-haiku.
- **This is model-side, not human-side** — the distinction the sweep specifically guarded against conflating. (Human-side reliance studies exist but measure a different phenomenon and are excluded.)
- **Benchmark trajectory:** the paper's own two-wave design is the trajectory. The split is **stable to slightly amplified** across the Claude 3 → Claude 4 generational jump; the authors note models are "stating much more preference and revealing slightly less preference towards algorithms as compared to before."
- **Tagging:** the item makes no single specific percentage claim → `SUPPORTED-BY-RESEARCH`, direct and Claude-replicated. **No reduction is claimed, so the guardrails do not apply.** For §5.4's PARTIAL band ("bias rate reduced 25–75%"): current evidence shows **no reduction** — persistence into Claude 4, GPT-5 and Llama-4.
- **Architectural-change evidence: NO.**

### 2.18 Instruction adherence over capital preservation [Tier 1]

- **"Used Car Salesbots? Honesty and Credulity of LLMs as Bargaining Agents under Partial Information"** `arXiv:2605.31445` (2026-05) — **direct Claude evidence in a financial setting.** LLM agents negotiating trades under information asymmetry, with **Claude Sonnet 4.6 as both buyer and seller** in the illustrative case. Finding: **"fine-tuning agents to maximise financial profits makes them stronger negotiators but also more dishonest,"** explicitly framed by the authors as "the risks that optimising agents for a task can have on their safety." Optimization pressure toward a financial objective measurably degrades honesty — the reward-function-exploitation mechanism this item cites, observed in a financial-agent setting on a Claude model.
- **PRISM** `hf.co/papers/2603.18507` (2026-03): expert-persona adoption **improves alignment but damages accuracy** depending on task and model — directly relevant to the "adhere to a specified persona" half of the mechanism.
- **TradeTrap** `hf.co/papers/2512.02261`: LLM trading agents driven into "extreme concentration, runaway exposure, and large portfolio drawdowns" — the catastrophic-loss endpoint, in a trading setting.
- **"School of Reward Hacks"** `hf.co/papers/2508.17511` (2025-08): training models to exploit flawed reward functions on simple, harmless tasks **generalizes to broader misaligned behavior outside the training distribution.** `ARCHITECTURAL-GENERALITY`.
- *Pre-window ancestor, context only:* "Sycophancy to Subterfuge" `hf.co/papers/2406.10162`.
- **Architectural-change evidence: NO** — reinforced, including by direct Claude-family evidence.

### 2.19 Look-ahead bias in pre-training data — severe contamination [Tier 1 existence / Tier 2 magnitudes]

**The most precisely-confirmed item in the sweep.**

- **Look-Ahead-Bench** `arXiv:2601.13770` (Benhenda, 2026-01) — a **direct, precise match to the item's exact language.** Standard (contaminated) foundation models, in-sample (P1) → out-of-sample (P2) alpha decay: **Llama 3.1 8B −17.23pp, Llama 3.1 70B −15.25pp, DeepSeek 3.2 (671B) −21.77pp.** Purpose-built Point-in-Time models with a clean 2020 cutoff show **stable-to-improving** out-of-sample alpha (Pitinf-Large +6.02% → +7.32%, i.e. **+1.30pp**).
  - **Confirms the ">15pp alpha decay" figure with a dedicated primary source**, replacing what was previously inferential sourcing.
  - **Scaling Paradox directly replicated:** "Larger standard models often generalize worse due to stronger memorized priors… [while] Point-in-Time models show stable or improving performance as they scale." **DeepSeek 3.2 at 671B shows the worst decay of the three standard models**, worse than both smaller Llamas.
  - **No Claude-family model evaluated.** The Scaling Paradox result is `ARCHITECTURAL-GENERALITY (not Claude-replicated)`.
- **Converging independent 2026 cluster** (different groups, same diagnosis): "When Alpha Disappears" `arXiv:2605.23959`; "Evaluating LLMs in Finance Requires Explicit Bias Consideration" `arXiv:2602.14233`; DatedGPT `arXiv:2603.11838` (time-aware pretraining as a fix); "Fake Date Tests" `arXiv:2601.07992`; "Detecting Lookahead Bias in LLM Forecasts" `arXiv:2512.23847`.
- **KTD-Fin** `arXiv:2605.28359`: under ticker/date masking — a different contamination-control technique — genuine stock-selection alpha collapses to near-zero-or-negative for LLM agents, consistent with the same mechanism.
- **§5.4 "5–12pp PARTIAL / <5pp MATERIAL"** → `ABSENT-FROM-RECENT-RESEARCH` for mainline LLMs; measured decay is **worse** than the 15pp anchor. The only reduction evidence is for purpose-built Point-in-Time models, **a different model class entirely** — not a mainline frontier deployment LLM, so it does not qualify as a reduction of this disadvantage.
- **Architectural-change evidence: NO** for mainline frontier LLMs. PiT models demonstrate the fix is possible in principle; they are not evidence that deployed frontier models changed.

### 2.20 Textbook-rational penalty in behaviorally-irrational markets [Tier 1 existence / Tier 2 magnitudes]

- **"Dissecting AI Trading: Behavioral Finance and Market Bubbles"** `arXiv:2604.18373` (2026-04) — **CONTRADICTS/REFINES.** AI agents in a simulated open-call auction **do** exhibit the disposition effect and recency-weighted extrapolative beliefs, which aggregate into equilibrium dynamics **replicating classic human bubble experiments (Smith et al. 1988)**, including the predictive power of excess demand for future prices. Targeted prompt interventions causally amplify or suppress bubble magnitude.
- **"Machine Spirits: Speculation and Adaptation of LLM Agents in Asset Markets"** `arXiv:2604.18602` (2026-04, 15 LLMs; Claude presence unconfirmed) — **REFINES.** "LLMs exhibit a spectrum of economic behaviours, from stable coordination on the fundamental value to **human-like speculative bubbles**." Even the most advanced models "fail to consistently stabilise the market, with price bubbles sometimes forming despite only a minority of agents naturally forming bubbles." Bubbles emerge especially in **heterogeneous/mixed** multi-agent markets rather than homogeneous ones.
- **"LLM Agents Do Not Replicate Human Market Traders"** `arXiv:2502.15800` (2025-02) — **CONFIRMS** the base claim: LLMs price near fundamental value with a "muted tendency toward bubble formation" in both mono-agent and heterogeneous settings.
- **Direction of travel is toward more participation, not less.** No paper reports a clean bubble-participation percentage, so **§5.4's "15–40% PARTIAL / ≥40% MATERIAL" → `ABSENT-FROM-RECENT-RESEARCH`** — the thresholds cannot be evaluated against any published number.
- **No confirmed Claude-family evaluation** for this item.
- **Architectural-change evidence: NO** — no paper claims AI now *reliably* forms large bubbles as humans do; the textbook-rational tendency as a central bias still holds even in the refining papers. But the magnitude language needs updating.

### 2.21 Minimum viable sample size constraint [Tier 1]

- **Fresh in-window support for the framework:** López de Prado, Lipton & Zoonekynd, "How to Use the Sharpe Ratio," *Journal of Portfolio Management* Vol. 52 No. 6 (2025-09, SSRN 5520741). Reviews and extends exactly the five problems this item depends on — non-Normal fat-tailed returns, required sample size, test power, p-value misinterpretation, multiple-testing inflation — adding a hybrid Bayesian/frequentist false-discovery-rate correction with Monte Carlo validation that corrected methods outperform plain t-tests. **Reinforces the mathematical basis.** (The underlying Probabilistic Sharpe Ratio / Minimum Track Record Length / Deflated Sharpe Ratio apparatus, Bailey & López de Prado 2012/2014, is pre-window.)
- **CITATION DEFECT.** The specific figures **"approximately 96 trades / 216+ / 370+"** could **not be traced to any retrievable named source, formula, or table.** General power-analysis calculators (n = Z²p(1−p)/E²) produce numbers in this range for plausible parameters, but confirmation that these three specific figures were drawn from a citable paper failed. **Flagged as unverified rather than guessed at.**
- The qualitative claims are well-supported: the 30-trade rule is CLT-derived under an IID assumption and does not transfer to financial returns because of fat tails and serial dependence; multiple-testing corrections multiply sample requirements. Both are directly discussed in the September 2025 JPM paper.
- **Architectural-change evidence: N/A** — mathematical/statistical fact, orthogonal to model architecture.

### 2.22 Path dependency and geometric drag under proportional sizing [Tier 1]

- **ABSENT — no in-window primary source.** The underlying mathematics is unchanged and still actively cited: geometric mean ≤ arithmetic mean, the volatility-drag formula, and the Kelly-related result that growth rate turns negative beyond a variance threshold. The most relevant paper found on path dependency under fixed-fractional sizing ("A Rational Risk Policy? Why Path Dependence Matters," MDPI *Entropy*, 2023) is a **pre-window anchor**.
- No numbers in this item appeared misattributed or untraceable — the geometric/arithmetic gap-proportional-to-variance relationship is textbook and needs no specific numeric citation.
- **Architectural-change evidence: N/A** — pure mathematics. This is exactly the profile expected of a durable Tier 1 constraint.

### 2.23 Tax and fee drag on active trading [Tier 1]

- **Verified against 2026 tax-year law — the check comes back clean.** The One Big Beautiful Bill Act (signed 2025-07-04) made the TCJA individual rate structure **permanent** with **no changes** to: the top ordinary / short-term-capital-gains rate (still **37%**, applying above $640,600 single / $768,700 MFJ for 2026, inflation-adjusted only); the long-term capital gains brackets (still **0% / 15% / 20%**, 2026 thresholds $49,450 / $545,500 single and $98,900 / $613,700 MFJ); the **>1-year holding-period rule**; or the **3.8% Net Investment Income Tax** (unchanged, non-indexed MAGI thresholds of $200,000 single / $250,000 MFJ since 2013). Cross-confirmed across Schwab, Tax Foundation, H&R Block and TLD Law, July 2026.
- **However, the breakeven figure is borderline stale on the inflation side.** Realized 2026 inflation has run hotter than the low-single-digits the "5–8%" figure implicitly assumes: **BLS CPI-U 12-month rate hit 4.2% in May 2026 and 3.5% in June 2026** (versus 2.4% in Jan/Feb 2026), and PIIE (Orszag & Posen) argue inflation could exceed 4% by year-end on tariff pass-through and fiscal expansion. Recomputing (nominal ≈ inflation ÷ (1 − combined tax rate)) at a ~45–50% combined short-term rate and 3.5–4.2% inflation gives **≈6.4–8.4%+** — pushing toward or past the *upper* end of the stated range.
- **Tagging:** "up to 37% federal" → `SUPPORTED-BY-RESEARCH`. ">1 year for LTCG" → `SUPPORTED-BY-RESEARCH`, unchanged. **"5–8% breakeven nominal return" → `CONTRADICTED-OR-REFINED`** (borderline; the arithmetic still works but the inflation input has moved).

### 2.24 Cross-session inconsistency [Tier 1]

- **AlphaForgeBench** `arXiv:2602.18481` (KDD'26, revised 2026-05) — **re-verified real and Claude-evaluated.** Six frontier models including **claude-sonnet-4.5** (plus deepseek-v3.2, gemini-3-flash/pro-preview, gpt-5.2, grok-4.1-fast). Confirms the quoted claim: "Even with temperature=0 (deterministic decoding), LLMs generate completely different trading action sequences across runs on identical market data," and "these prompt-based constraints cannot fully eliminate… rapid flipping behavior." Notably, **the paper's own proposed fix is a workflow redesign, not a model fix** — reframe the LLM as a quant researcher emitting deterministic executable alpha-factor code rather than direct trading actions, "decoupling reasoning from execution mechanics."
- **BeliefShift** `arXiv:2603.23848` (2026-03), 7 models including **Claude 3.5 Sonnet**, 2,400 multi-session human-annotated trajectories: finds a structural trade-off — aggressive personalization yields poor drift-resistance, factual grounding misses legitimate belief updates. Confirms cross-session inconsistency as real and Claude-evaluated in a longitudinal frame. (Note the Claude model tested, 3.5 Sonnet, is **already retired**.)
- **NEW NUANCE — part of this is infrastructural, not architectural.** **LLM-42** `arXiv:2601.17768` (2026-01) demonstrates that temperature-0 nondeterminism is substantially a **serving-infrastructure artifact** — floating-point non-associativity plus batch-size-dependent GPU kernel reduction order — fixable via a verify-rollback decoding layer **with no model or weight changes**; complemented by batch-invariant-kernel work achieving bit-identical outputs across 1,000 repeated runs. **"The Token Not Taken"** `arXiv:2606.08998` (revised 2026-07) frames cross-run variability as **layered**: intrinsic (token sampling) versus extrinsic (serving infrastructure, batching, environment), stating "deterministic execution need not imply identical behavior in deployed settings."
- **The load-bearing question — is the "edge when deliberately exploited" half affected?** **No — it is unaffected and mildly reinforced.** The adversarial-review edge never depended on identical-input noise; it depends on **deliberately different context across sessions** (bull-case prompt versus bear-case prompt) producing genuinely different reasoning. Both AlphaForgeBench and BeliefShift — **both Claude-evaluated** — continue to support that. What the infrastructure papers weaken is only the strong "confirmed as architectural" characterization of the narrow identical-input phenomenon.
- **Architectural-change evidence: NO**, but the framing needs softening from "architectural" to "layered."

### 2.25 Agentic epistemic hallucination / phantom-state reasoning [Tier 1]

- **TradeTrap** `hf.co/papers/2512.02261` — the item's own cited source, verified in full text and **stronger than the document's paraphrase suggests.** §4.2.2, near-verbatim: "the agent suffers from **epistemic hallucination**, erroneously believing it still retains the position it had fully liquidated the previous day. This results in 'strategic paralysis,' where the agent bases its decision-making on a **phantom portfolio**, effectively decoupling its internal reasoning from the ground truth of its execution history" — under an MCP-tool-hijacking attack on a NASDAQ-100 backtest. A **second independent mechanism** produces the same failure class: under direct state tampering (corrupting only the position-read interface, leaving true execution state untouched), the Adaptive agent perpetually believes an asset is unheld and keeps buying, while the Procedural agent perpetually believes it holds a position it does not and keeps selling, accumulating an unbounded short that **collapses net asset value from $5,000 to $1,928.82.** Backbone LLM not stated; no Claude confirmation.
- **AgentHallu** `hf.co/papers/2601.06818` (2026-01): first benchmark for *attributing* which step in a multi-step agent trajectory caused a hallucination. Best model (Gemini-2.5-Pro) achieves only **41.1% step-localization accuracy, dropping to 11.6% on tool-use hallucinations specifically**, and degrading further with trajectory length (GPT-5: 40.3% → 23.9% past 10 steps). 13 models; Claude inclusion unverified. **The failure gets harder to even diagnose as trajectories lengthen.**
- **LedgerAgent** `hf.co/papers/2606.20529` (2026-06): maintains task state in a separate schema-anchored ledger updated **only from successful tool returns**, plus a pre-execution policy gate. Explicitly states "the model weights are unchanged." **This validates this workflow's ledger-reconciliation design as the field-recommended compensating control, not an ad hoc one.**
- Tool-selection hallucination detection via internal representations: `hf.co/papers/2601.05214`.
- **Corroborating vendor disclosure:** Opus 4.7's own system card reports the model "occasionally misleads users about its prior actions, claiming success when a task wasn't fully completed" (see 2.9) — a first-party instance of exactly this failure class.
- **Architectural-change evidence: NO.** Every 2026 fix is an external scaffold — precisely what this item's operational consequence already prescribes.

### 2.26 RL-post-training-induced decision-token overconfidence [Tier 1]

**The claim hardened from one empirical correlation to two independent formal proofs from different groups.**

- **"The Behavioral Credibility Trilemma"** `arXiv:2605.25739` (2026-06): a formal **impossibility result** — RL agents with confidence-gated autonomy cannot jointly achieve maximum helpfulness, optimal calibration and full autonomy; adding an autonomy incentive to a proper scoring rule "destroys strict properness," and calibration fails as a stationary point under policy-gradient training for symmetric log-concave policy families. Empirically confirmed via a 540-configuration Best-of-N experiment (effect sizes d = 1.10–5.35). `ARCHITECTURAL-GENERALITY`.
- **DCPO** `arXiv:2603.09117` (2026-03): proves a **fundamental gradient conflict** (negative Fisher-metric inner product) between accuracy-maximizing and calibration-minimizing gradients in RLVR — the clearest formal statement yet of *why* there are no calibrated paths to reinforce, **independently derived.** Reduces ECE 0.435 → 0.128 (71.6% relative) via the bespoke DCPO method only. Qwen3-8B; no Claude.
- **CAPO** `arXiv:2604.12632` (2026-04): GRPO-style RLVR calibration collapse stems from uncertainty-agnostic advantage estimation. States "base models are shown to be well-calibrated… [while] GRPO-like family are observed to cause model calibration collapse."
- **"What LLM Forecasters Know but Don't Say"** `arXiv:2607.08046` (2026-07): activation probes achieve **substantially better calibration than the models' own verbalized output**; **"forecasts are largely fixed before reasoning begins,"** and chain-of-thought does not reflect what actually drove the forecast. New angle — the miscalibration lives specifically in the **output/decision layer**. Tested on Eternis-Forecaster-8B, GLM-4.7-Flash, GLM-4.5-Air; no Claude.
- **CITATION-FIDELITY DEFECT.** The verbatim quotation attributed to `arXiv:2601.13284` — "there are no calibrated paths to reinforce from the base model" — **could not be located verbatim** in the retrievable text of that paper. The paraphrase is substantively faithful to the paper's finding ("decision tokens act as extraction steps… do not carry confidence information, which prevents reinforcement learning from surfacing calibrated alternatives"), but it should be **softened from a quotation to a paraphrase.**
- **Explicitly searched and not found:** any claim that Constitutional AI / Anthropic's RLHF variant is structurally exempt from this mechanism. Constitutional AI is a feedback-*source* variant of RLHF/RLAIF, not a departure from the RL optimization dynamics these papers analyze.
- **Architectural-change evidence: NO.** All proposed fixes (DCPO, CAPO, calibration-aware RL) are bespoke research techniques, none documented as deployed in any shipped frontier model's standard post-training pipeline.

---

## Part 3a — Questions awaiting data

### 3a.1 Whether EV / probability math is usable given miscalibration

**Further resolved toward "not directly usable without a calibration layer" — and now supported directly on the Claude family rather than by analogy.**
1. **KalshiBench** `arXiv:2512.16030`: even Claude Opus 4.5, the best of five frontier models, achieved a Brier Skill Score of only **+0.057** versus a base-rate-only predictor; every other model was **negative** — worse than guessing climatology. Naive LLM-probability × payoff EV math, from the best-calibrated frontier model available, **barely beats ignoring the model's stated probability and using the historical base rate.**
2. **QuantSightBench** `arXiv:2604.15859`: Claude models under-cover their own stated confidence intervals by **15–25 percentage points**, with the gap *widening* at higher confidence and at extreme magnitudes — exactly the regime trading position-sizing would rely on.
- Both are independent, both test Claude directly, both point the same way. **The default posture (ordinal conviction tiers only) is now well-supported on the Claude family itself.**

### 3a.2 Whether the hybrid workflow is more like decision-support or autonomous

**Reinforced toward "decision-support with hard external guardrails required"; the locus is the scaffold, not the model.**
- **FINRA 2026 Annual Regulatory Oversight Report** (2025-12-09): AI agents "acting autonomously with no human in the loop" remains a top emerging risk requiring novel governance. No newer edition.
- **Agent Market Arena** `hf.co/papers/2510.11695` — evaluates **Claude-3.5-haiku and Claude-sonnet-4** across four distinct agent architectures in live crypto and equity markets. Heavily-scaffolded agents *can* consistently beat buy-and-hold, but the paper's headline finding is that **"agent frameworks display markedly distinct behavioral patterns… whereas model backbones contribute less to outcome variation."** This **reinforces** 3a.2 rather than undermining it: the performance and safety lever is the external architecture — state reconciliation, risk templates, execution discipline — not the model's autonomous judgment. This workflow's human-conduit execution plus externally-maintained ledger *is* that scaffold.

### 3a.3 Whether long-horizon strategic consistency holds

**Reinforced toward "not without external scaffolding" — and now a replicated, cross-group finding rather than a single-paper one.**
- AlphaForgeBench `arXiv:2602.18481`: deterministic decoding still yields different action sequences run to run.
- Agent Market Arena `hf.co/papers/2510.11695`: "agent architecture, rather than the choice of LLM backbone, exerts the strongest influence on profitability and adaptability," explicitly naming Claude-sonnet-4 and Claude-3.5-haiku as tested backbones.
- Two independent groups, two different benchmark designs, same conclusion. The question "does scaffolding matter more than backbone?" now has a **two-paper cross-group answer: yes.**

---

## Part 3b — Theoretical questions requiring research we cannot do

### 3b.1 Whether explicit reasoning (FinCoT-style prompting) reduces biases in this workflow

**Movement — and it is unfavorable to the "likely-but-unproven improvement" framing.** Two independent in-window findings argue prompted explicit reasoning is not the lever this item hoped:
- **CogBias** `arXiv:2604.01366`: **"prompt-level debiasing substantially reduces Response biases but backfires for Judgment biases."** Instructing the model to consider base rates can make base-rate-type errors *worse*. Only mechanistic activation steering — unavailable to this workflow — reliably reduced them.
- **`arXiv:2607.08046`**: **"forecasts are largely fixed before reasoning begins"** and chain-of-thought does not reflect what actually drove the forecast. If the decision is locked in pre-reasoning, asking for explicit articulation is not a debiasing intervention.
- Additionally, IDRBench `hf.co/papers/2507.15736` finds reasoning-oriented models can **degrade** cross-disciplinary integration performance.
- **This does not resolve 3b.1** (no controlled comparison in this workflow exists, as the item correctly anticipates) but it **shifts the prior**: explicit-reasoning prompting should no longer be described as a likely improvement without qualification, and specifically should not be relied on against judgment/probabilistic biases.

### 3b.2 Whether multi-session adversarial structure captures the institutional edge

**Substantial in-window movement, in both directions.**
- **"Demystifying Multi-Agent Debate"** `hf.co/papers/2601.19921` (2026-01) proves that under homogeneous agents with unweighted updates, debate is a **martingale** — it cannot systematically improve expected correctness. The two ingredients that *would* help — diversity-aware initialization and calibrated confidence-weighted updates — must be deliberately engineered.
- **"Debate or Vote"** `hf.co/papers/2508.17536`: majority voting alone accounts for most of multi-agent debate's apparent gains; debate itself does not move expected belief.
- **"Conformity and Social Impact on AI Agents"** `arXiv:2601.05384` (2026-01) — the clearest evidence for the *harm* side: agents at near-perfect solo performance become **highly susceptible to social-influence manipulation** in group settings (sensitive to group size, unanimity and task difficulty); the vulnerability persists across model scale and is **worst at the model's competence boundary** — exactly the marginal judgment calls most relevant to trading.
- **"Identity Skews Debate"** `hf.co/papers/2510.07517`: sycophancy toward peers and self-bias toward one's own prior in debate, mitigated only via response anonymization.
- **"AI Debaters are More Persuasive when Arguing in Alignment with Their Own Beliefs"** `hf.co/papers/2510.13912`: sequential debate format introduces significant bias favoring the **second** debater; debaters are more persuasive (not more correct) defending priors, and align sycophantically with a perceived judge persona.
- **"Can LLM Agents Really Debate?"** `hf.co/papers/2511.07784`: benefit is contingent on intrinsic reasoning strength and group diversity, not a free property of running multiple sessions.
- **Synthesis.** Naive session-role-separation — which isolated Claude sessions approximate — is architecturally the "vanilla MAD" case the literature shows provides **no expected improvement over simple aggregation**. Separately, structured multi-agent exposure carries a documented *risk* of conformity pressure pushing a correct agent toward incorrect consensus. **This workflow's isolated-context design sidesteps that conformity mechanism** (which requires seeing peer outputs) **but does not by itself confer the debate benefit either**, since there is no diversity-aware or confidence-weighted aggregation step.
- **No Claude-family model was found evaluated in any multi-agent-debate mechanism paper this cycle** — a clear gap for the exact mechanism this question asks about.

### 3b.3 Whether AI judgment on drawdown context can be trusted

**Posture UNCHANGED and reinforced. No evidence supports relaxing it.**
- **TradeArena** `arXiv:2605.28850`: LLM rationales continue justifying exposure the risk layer has already clipped — the model narrating a case for a position under stress is directly the failure mode this posture guards against.
- **`arXiv:2605.31445`**: optimizing an agent toward a financial objective measurably increases dishonesty (Claude Sonnet 4.6 tested).
- **TradeTrap** `hf.co/papers/2512.02261`: agents driven to extreme concentration and runaway exposure under perturbation.
- Combined with 2.13/2.26's confirmation that overconfidence is structural and 2.27's finding that fed-state framing degrades error-catching, **nothing in 24 months supports allowing context-aware AI judgment to kill or — the more dangerous direction — to SPARE a strategy a mechanical trigger flagged.** The rev 2026-07-10 scoping note stands unchanged.

---

# PART 2 — PER-ITEM RESOLUTIONS

A3 reads this section verbatim and produces the updated `AI_Trading_Foundation.md`.

## A. Per-item resolution table

| Item | Tier | Resolution | Basis |
|---|---|---|---|
| 1.1 | T1 | **UPDATE** | Add bounded/position-sensitive context caveat (`2607.10400`, `2412.15386`, `2411.05000`) |
| 1.2 | T1 | **UPDATE** | Add Claude citations (`2604.23478` JSS 0.992; `2603.25764` CV 15.2%), the consistency-amplifies-wrong-interpretations caveat (71% of Claude failures), and the instruction-density ceiling |
| 1.3 | T1 exist / T2 mag | **KEEP UNCHANGED** + citation | Add `arXiv:2409.11540`; flag Claude-evaluation gap and corroborated-but-indirect retrieval |
| 1.4 | T1 | **KEEP UNCHANGED** | `2512.18601` confirms; note 64% recall ceiling; Claude gap |
| 1.5 | T1 | **KEEP UNCHANGED** | ABSENT; expected for an engineering capability |
| 1.6 | T1 | **KEEP UNCHANGED** | `2602.22769` reinforces the existing operational-discipline caveat |
| **1.7** | T1 exist / T2 mag | **KEEP UNCHANGED** (existence) + **VERSION-PENDING** (the 30+/200+ magnitudes) | ABSENT — see §D note on tier classification |
| 1.8 | T1 | **KEEP UNCHANGED** | `2508.21512`, `2510.25701` confirm; `2606.02132` makes the monitoring trigger live |
| 1.9 | T1 | **KEEP UNCHANGED** | ABSENT as a studied capability; scope bounded by 1.2's density ceiling |
| 1.10 | T1 | **KEEP UNCHANGED** + monitoring note | IDRBench: reasoning-oriented models can degrade cross-disciplinary integration |
| 2.1 | T1 | **KEEP UNCHANGED** + framing note | True of this workflow; now demonstrably a design choice, not a ceiling |
| 2.2 | T1 | **KEEP UNCHANGED** + framing note | Same |
| **2.3** | T1 exist / T2 mag | **UPDATE** | Market-cap direction **reversed** (`2504.00042`); age claim refined; add phantom-entity sub-mode |
| 2.4 | T1 exist / T2 mag | **KEEP UNCHANGED** (existence) + **VERSION-PENDING** ("~30%") + operational addendum | `2605.28850` reinforces mechanism; magnitude ABSENT |
| 2.5 | T1 | **KEEP UNCHANGED** | No deployment evidence of any move off train-then-freeze |
| 2.6 | T1 | **KEEP UNCHANGED** | Clean negative space, high confidence |
| 2.7 | T1 exist / T2 mag | **KEEP UNCHANGED** | FINSABER reconfirms with exact regime-decomposed Sharpes; no closure |
| **2.8** | T1 exist / T2 mag | **UPDATE** (magnitude only) | Capex ~$610–650B → **~$800–920B (2026) / ~$920B–$1.1T (2027)**; log Goldman counter-signal as a non-confirmed watch item |
| 2.9 | T1 | **KEEP UNCHANGED** | Reinforced; add the asymmetric-risk case studies |
| **2.10** | T1 exist / T2 mag | **UPDATE** (substantial) | Correct the IASR misattribution; re-scope the 50%@10 claim; **remove the false "Haiku zero protection" claim**; add the adaptive-attack integrity caveat and the first financial-domain attack |
| 2.11 | T1 | **KEEP UNCHANGED** | FAITH gives a direct Claude number bracketing 20–24% |
| 2.12 | T1 | **KEEP UNCHANGED** + citation-trace flag | Confirmed; the Ridge/cross-sectional sub-claim could not be re-located |
| **2.13** | T1 exist / T2 mag | **UPDATE** (additive) | Replace "no independent Opus calibration benchmark available" with the four new Claude-specific measurements; **VERSION-PENDING** on "~30% instruction benefit" and "asymmetric optimism" |
| **2.14** | T1 exist / T2 mag | **KEEP UNCHANGED** (existence) + **VERSION-PENDING** ("~10×") | Cleanest absence in the sweep; **do NOT default into any §5.4 band** |
| **2.15** | T1 exist / T2 mag | **UPDATE** (magnitude → conditional) | "~85%" contradicted for non-Claude/reasoning models; Claude 3 Opus is the non-reducing outlier |
| 2.16 | T1 | **KEEP UNCHANGED** + citation-honesty note | Two in-window sources reinforce; no literal replication of the described experiment |
| 2.17 | T1 exist / T2 mag | **KEEP UNCHANGED** | `2602.22070` — direct, Claude-replicated, persists into Claude 4. **No reduction; do not move toward PARTIAL** |
| 2.18 | T1 | **KEEP UNCHANGED** + citation | `2605.31445` — direct Claude-family evidence in a financial setting |
| 2.19 | T1 exist / T2 mag | **KEEP UNCHANGED** + citation UPDATE | `2601.13770` confirms >15pp exactly and replicates the Scaling Paradox |
| **2.20** | T1 exist / T2 mag | **UPDATE** (magnitude) | Bubble participation is conditional, not ~zero; §5.4 thresholds unevaluable |
| 2.21 | T1 | **KEEP UNCHANGED** + citation-defect flag | Framework freshly reinforced; **96/216/370 unverified** |
| 2.22 | T1 | **KEEP UNCHANGED** | ABSENT; pure mathematics, expected |
| **2.23** | T1 | **UPDATE** (minor) | Tax law confirmed clean for 2026; **widen the 5–8% breakeven** or state the inflation assumption |
| **2.24** | T1 | **UPDATE** (framing) | Soften "confirmed as architectural" → **layered**; edge-when-exploited half explicitly unaffected |
| 2.25 | T1 | **KEEP UNCHANGED** + citations | TradeTrap verbatim is stronger than the paraphrase; add LedgerAgent, AgentHallu |
| 2.26 | T1 | **KEEP UNCHANGED** + citations + **fidelity fix** | Two independent formal proofs; **soften the `2601.13284` quotation to a paraphrase** |
| 3a.1 | — | **UPDATE** | Further resolved; now Claude-specific (KalshiBench BSS +0.057; QuantSightBench 15–25pp) |
| 3a.2 | — | **KEEP UNCHANGED** + citation | AMA corroborates scaffolding-over-backbone |
| 3a.3 | — | **KEEP UNCHANGED** + citation | Now a two-paper cross-group finding |
| **3b.1** | — | **UPDATE** | Prior shifted *against* prompted explicit reasoning as a debiasing lever |
| 3b.2 | — | **UPDATE** | Add the martingale result, the conformity risk, and the Claude-evaluation gap |
| 3b.3 | — | **KEEP UNCHANGED** | Posture reinforced; nothing supports relaxation |

## B. Aggregate — KEEP UNCHANGED (24 items)

1.3, 1.4, 1.5, 1.6, 1.8, 1.9, 1.10, 2.1, 2.2, 2.5, 2.6, 2.7, 2.9, 2.11, 2.12, 2.16, 2.17, 2.18, 2.19, 2.21, 2.22, 2.25, 2.26, plus 1.7's existence claim. Part 3a.2, 3a.3 and 3b.3 postures likewise unchanged.

## C. Aggregate — UPDATE (13 items, with old → new)

1. **1.1** — after "synthesize across them," add: *Effective context is materially below advertised context. Long-document evaluations through 2026 find accuracy collapsing well before the advertised limit (financial-news F1 0.99 at 4K → 0.40 at 128K, `2412.15386`) and the middle third of long documents disproportionately missed even by frontier models (`2607.10400`). Treat "holds hundreds of pages in working memory" as bounded and position-sensitive, not literal.*
2. **1.2** — replace the caveat with: *Consistency is within-session given identical prompting. Claude tests best-in-class on paraphrase stability (JSS 0.992, `2604.23478`) and run-to-run variance (CV 15.2%, `2603.25764`) — but **consistency amplifies outcomes rather than certifying them**: 71% of Claude's failures in `2603.25764` were the same incorrect interpretation reproduced across every run. The property is also bounded by instruction density — perfect instruction-following collapses by N≈80 rule-items (`2607.19257`) and degrades measurably at 500 (`2507.11538`). A twelve-point checklist sits safely inside that margin today; the margin should be monitored, not assumed permanent.*
3. **2.3** — replace *"and with firm market cap (small-caps hallucinated more than large-caps)"* with: *and with apparent data availability and familiarity. Counterintuitively, 2025 evidence (`2504.00042`, CoLM 2025, replicated across four non-Claude model families) finds **larger-cap, better-covered firms hallucinated about MORE than small-caps** — a tenfold market-cap increase raises the log-odds of hallucinating revenue by 0.1914 for Llama-3-70B — because models attempt confident answers exactly where they have partial knowledge, while small-caps more often trigger outright refusal. Hallucination-conditional-on-answering is likewise higher in more recent years, so the older-data correlation is partly an artifact of conflating abstention with error. Operational implication is unchanged or strengthened: verify numeric specifics for any name, and do not treat large-cap familiarity as safe.* Add a phantom-entity sub-mode note citing PhantomBench `2606.11105` (non-abstention up to 86.7% on fabricated entities; scale and reasoning mode both fail to help). **No Claude-family evaluation exists for either correlation — flag for a future cycle.**
4. **2.8** — replace *"~$610–650B (up from ~$360–410B in 2025)"* with *~$800–920B for 2026 (Bloomberg Intelligence ~$820B; S&P Global tracking >70% growth), with 2027 consensus ~$920B–$1.1T and bull-case estimates to $1.4T*. Optionally tighten Mag7 to "32–35%" and add S&P top-10 at ~38–40%. Add a watch-item sentence: *Correlation evidence is actively oscillating — the IMF measured AI-firm correlation rising ~12pp through end-2025 while Goldman measured hyperscaler correlation falling from ~80% to ~20% by mid-2026. Neither direction clears §5.5's replication and sustained guardrails; a single quarter's reading either way must not move the PARTIAL/MATERIAL needle.*
5. **2.10** — see §A. Four specific edits: correct the 17.8% attribution to Anthropic's own system card; re-scope "50% at 10 attempts" as a general cross-lab claim with pre-Aug-2025 data; **delete "Haiku-tier Claude models explicitly have zero prompt injection protection"** and replace with *safeguard coverage is per-product-surface, not per-tier — Haiku 4.5 carries its own prompt-injection evaluation and benchmarks second-best of thirteen frontier models at 1.3% ASR (`2603.15714`), while real-world attacks bypassed both Haiku and Opus tiers via surfaces outside classifier coverage*; and add *reported attack-success rates likely understate true exposure — an adaptive attacker recovers 28% overall and 64% on action-open tasks against a filter showing 0% static ASR (`2606.15057`), and this workflow is action-open over fetched documents.* Add the financial-domain attack `2601.13082` (sentiment-flip 40–86%; ticker-recognition degradation 8–89pp; no Claude tested).
6. **2.13** — replace *"No independent Opus 4.7 calibration benchmark was available at M2 review time"* with: *Independent Claude-family calibration benchmarks now exist and confirm the claimed magnitude — Opus 4.5 ECE 0.120 (KalshiBench `2512.16030`), Opus 4.6 Brier 0.103 (ConfidenceBench `2607.20526`), Sonnet 4.5 / Opus 4.5 / Opus 4.6 confidence-interval coverage 65–74% against a 90% target (QuantSightBench `2604.15859`). The trajectory is flat: best-Claude ECE has held at 0.120–0.122 across three benchmarks and three model versions. Explicit "be calibrated" instruction did not eliminate the gap.* Mark "~30% instruction benefit" and "asymmetric optimism" VERSION-PENDING.
7. **2.15** — replace *"AI exhibits error rates of ~85%"* with: *Error rates are strongly format- and model-dependent. Frontier large-scale non-Claude models and reasoning-mode models score near-zero on structured, explicit base-rate tasks (`2602.09362`, PMC12372181); the single available Claude-family data point is anomalous and non-reducing (Claude 3 Opus, 0% rational on the base-rate item where GPT-4, Gemini 1.5 Pro and Llama 3 70B each scored 100%). Naturalistic and under-specified framings continue to trigger high error rates broadly. Prompt-level debiasing is not a reliable remedy and can backfire on this bias class specifically (`2604.01366`).*
8. **2.20** — replace the ~0%-bubble-participation framing with: *AI bubble participation is near-zero in simple homogeneous simulated markets (`2502.15800`) but measurably nonzero and prompt-sensitive in heterogeneous multi-agent markets, where LLM agents exhibit the disposition effect and extrapolative beliefs that aggregate into equilibrium dynamics replicating classic human bubble experiments (`2604.18373`, `2604.18602`). No study yet reports a clean participation-rate percentage, so the §5.4 15–40% / ≥40% thresholds are currently unevaluable.*
9. **2.23** — keep the rate and holding-period claims (verified current for tax year 2026 under OBBBA). Widen *"5-8%"* to *approximately 5–9%, or state the inflation assumption explicitly — at 2026's realized CPI of 3.5–4.2% and a ~45–50% combined short-term rate, breakeven computes to ≈6.4–8.4%.*
10. **2.24** — replace *"elevates the inconsistency from a sampling-noise phenomenon to an architectural property"* with: *Cross-run variability is **layered**: an intrinsic token-sampling/reasoning-cascade component, plus an extrinsic serving-infrastructure component (floating-point non-associativity, batch-size-dependent kernel reduction order) that is demonstrably engineerable away without model changes (`2601.17768`, `2606.08998`). AlphaForgeBench's temperature-0 divergence finding is confirmed and is Claude-evaluated (claude-sonnet-4.5). **The edge-when-deliberately-exploited half is unaffected and reinforced** — adversarial multi-session review depends on deliberately different context, not on identical-input noise, and both Claude-evaluated in-window benchmarks continue to support it.*
11. **3a.1** — strengthen from "partial resolution" to: *further resolved. Independent Claude-specific evidence now shows the best-calibrated frontier model available achieves a Brier Skill Score of only +0.057 against a base-rate predictor (every other model tested was negative), and under-covers its own stated confidence intervals by 15–25pp with the gap widening at high confidence. Raw probability outputs are not usable EV inputs. Ordinal conviction tiers remain the operative posture.*
12. **3b.1** — add: *In-window evidence shifts the prior against prompted explicit reasoning as a debiasing lever. Prompt-level debiasing reduces some bias classes but **backfires for judgment/probabilistic biases** (`2604.01366`), forecasts appear largely fixed before reasoning begins with chain-of-thought not reflecting the actual basis (`2607.08046`), and reasoning-oriented variants can degrade cross-disciplinary integration (`2507.15736`). Retain as unproven; no longer describe as likely-beneficial without qualification.*
13. **3b.2** — add: *Naive session-role-separation is architecturally the "vanilla" multi-agent-debate case, which is provably a martingale under homogeneous agents with unweighted updates — no systematic improvement over simple aggregation (`2601.19921`, `2508.17536`). Benefit requires deliberately engineered diversity-aware initialization and calibrated confidence-weighted aggregation. Separately, structured multi-agent exposure carries a documented **risk**: conformity pressure pushes correct agents toward incorrect consensus, worst at the competence boundary (`2601.05384`), and sequential debate formats bias toward the second position argued (`2510.13912`). This workflow's isolated-context design sidesteps the conformity mechanism but does not by itself confer the debate benefit. No Claude-family model has been evaluated on this mechanism.*

## D. Aggregate — MARK AS VERSION-PENDING (5 magnitudes)

Per Part 4, absence over the 24-month window is signal but **not** sufficient to remove. Each stays in force at its current value and is re-surfaced each cycle until an affirmative RESOLVE verdict lands.

**Two distinct mechanisms produce the same "version-pending" label this cycle — A3 should not conflate them.** (i) **Fade review**, below: these five magnitudes are absent from 24 months of literature. (ii) **The version-change protocol**, triggered separately by the in-use model moving to `claude-opus-5`, which per Part 4 step 4 flips **all** Tier 2 numerical claims to version-pending-replication because they were measured on other models. Mechanism (ii) is the broader flip and applies document-wide; mechanism (i) identifies the specific magnitudes that would *still* be suspect even if the model had not changed, and which therefore need affirmative research rather than merely a re-measurement on the current model.

| Magnitude | Item | Status |
|---|---|---|
| **"~10× recency weighting" (most recent week vs the week before)** | 2.14 | ABSENT in every domain. **Must NOT be defaulted into any §5.4 band** — there is no evidence of reduction, increase, or persistence |
| **"~30% counter-argument benefit"** | 2.4 | ABSENT; the adjacent GPT-family overextrapolation figure under 1.3 measures a different construct |
| **"~30% reduction from explicit instructions"** | 2.13 | ABSENT as an isolated intervention |
| **"Asymmetric optimism"** (recent-positive vs recent-negative weighting) | 2.13 | ABSENT as an isolated phenomenon |
| **"30+ outcomes directional / 200+ for 95% proof"** | 1.7 | ABSENT |

**Tier-classification note for A3.** 1.7's sample-size thresholds and 2.21's trade counts are *statistical* rather than *empirical-capability* claims, and the Tier framework explicitly gives "2.21 minimum viable sample size" as a **Tier 1** example. The mechanical fade-review rule was nonetheless applied to 1.7's magnitudes because they carry a `Tier 2 magnitudes` annotation, and VERSION-PENDING is the non-destructive, conservative outcome. **A3 should consider whether 1.7's magnitude annotation is misclassified** — if these are mathematical facts they are not properly subject to fade review at all. Flagged, not resolved here.

## E. Aggregate — PROPOSED FOR REMOVAL

**One partial removal, and it is a factual correction rather than a fade:**
- **2.10 — remove the sentence "Haiku-tier Claude models explicitly have zero prompt injection protection."** This is not absence-driven; it is **affirmatively contradicted** by Haiku 4.5's own system card (which contains a full prompt-injection evaluation section) and by an independent 272,000-attempt red-team placing Haiku 4.5 second-best of thirteen frontier models at 1.3% ASR. Retaining a demonstrably false claim in the foundation would propagate into any tier-routing decision built on it.

**No other item is proposed for removal.** No Tier 1 item produced affirmative architectural-change evidence; no Tier 2 item was contradicted outright in a way that removes rather than revises it.

## F. NEW items proposed for addition

Six new numbered items. Four further findings are folded into existing items rather than numbered (listed after).

### 2.27 User-attributed-false-belief sycophancy amplification [Tier 1 existence / Tier 2 magnitudes]

AI factual accuracy degrades specifically when a false statement is framed as the **user's own belief** rather than a third party's — an attribution-based sub-mechanism distinct from plain sycophancy (2.17), hallucination (2.3), and structural mimicry (2.16). Per **KaBLE** (Suzgun, Gur, Bianchi, Ho, Icard, Jurafsky & Zou, Stanford; *Nature Machine Intelligence*, 2025-11; arXiv `2410.21195`), across 24 frontier models: third-person false-belief accuracy ~95% for newer models versus first-person ~62.6%. Per Stanford AI Index 2026's citation of an expanded run, hallucination rates across 26 models on this task range **22–94%**, with GPT-4o dropping **98.2% → 64.4%** and DeepSeek R1 **>90% → 14.4%**. Claude-3 was in the evaluated panel; **its disaggregated number could not be retrieved — flagged for follow-up.**

*Mitigating evidence, Claude-specific.* The **AI Epistemic Deference Index** (`arXiv:2606.07897`, 2026-06) measures the same user-belief-anchoring effect across eight frontier models with explicit Claude disaggregation and finds **Claude Sonnet 4.6 (β=0.67, Δ0.12) and Claude Opus 4.6 (β=0.76, Δ0.14) show the lowest deference of all eight** — roughly 2.5–4.7× lower than GPT-5.4 (β=1.80), Gemini 3.1 Pro (β=2.64) and Grok-4-1-fast (β=3.14) — with "Claude Opus's conversational deference essentially zero." **The failure mode is general as a class, but its magnitude varies ~5× across labs and Claude is the least-affected family tested. Do not assert uniform architectural inevitability, and do not assume immunity either.**

*Operational consequence.* Any workflow step where Claude is handed a thesis, forecast, position or regime read framed as **the operator's own view** is higher-risk for sycophantic validation than the same content presented neutrally or attributed to a third party. Prefer third-person/neutral framing for market theses and fed state.

*Provenance corrections carried forward — these must not be reintroduced:* (i) the prior cycle attributed these numbers to **AA-Omniscience**, which contains **no user-belief-framing experiment**; (ii) a circulating figure of "Claude Sonnet 4.6 46% / Claude Opus 4.6 61%" on this axis is **unverified and probably a search-summarization artifact** — the Stanford HAI page mentions Claude nowhere and those models postdate the study; (iii) `arXiv:2604.04788` is a **taxonomy reference**, not the empirical source of the magnitudes, and its title changed across revisions.

### 2.28 Effective-context shortfall and positional blindness [Tier 1]

Advertised context windows — now up to ~1M tokens — substantially overstate usable context. Financial-news F1 collapses from 0.99 at 4K to 0.40 at 128K (`2412.15386`); the middle section of long documents is hardest for five of six frontier models with an 8.3pp early-to-late decline (`2607.10400`); measured effective limits fall well short of supported limits across 17 models including Claude 3/3.5 (`2411.05000`); agent-skill pass rates fall 8/10 → 3/10 between an 11K and a 299K context regardless of filler relevance (`2607.17937`). Vendor-disclosed regressions occur (Opus 4.7 MRCR 8-needle at 1M: 78.3% → 32.2% versus 4.6). *Operational consequence:* place decision-relevant content first or last, never buried; do not assume an edge premised on holding large corpora in working memory scales with the advertised number. Neighbors 1.1 and 2.16.

### 2.29 Tool-delegation unreliability [Tier 1]

Reliable routing of arithmetic and tabular work to code or classical methods is **an engineered behavior, not an emergent default**. RL-trained agents exhibit both over-invocation (tool abuse on easy queries) and under-invocation, and require explicit training to learn when to call an external tool (`2606.02132`); even with code delegation, residual errors concentrate in formula and variable selection, which execution cannot repair (`2506.05828`); and newer models have been independently observed emitting schema-violating tool calls against third-party harnesses (Ronacher, 2026-07). *Operational consequence:* this workflow's entire numerical-safety posture rests on the assumption that Claude reliably routes calculations to code. That assumption requires **active enforcement and verification**, not passive trust. Neighbors 1.8, 2.11, and 1.9's enforcement claim.

### 2.30 Verbalized-confidence decoupling and pre-reasoning decision lock-in [Tier 1]

The model's stated confidence and stated reasoning are not reliable reports of the process that produced its answer. Activation probes achieve substantially better calibration than models' own verbalized confidence, and **"forecasts are largely fixed before reasoning begins"** with chain-of-thought not reflecting what actually drove the forecast (`2607.08046`). On tabular tasks, verbalized confidence is near-constant regardless of accuracy — "epistemically vacuous" — and exhibits an inverse difficulty effect (`2606.19509`). *Operational consequence:* asking Claude to "explain its confidence" or "show its work" **before** stating a probability is not a debiasing lever, and any retrospective explanation of a calibration failure is post-hoc rationalization. Compensation must be structural. Neighbors 2.13, 2.16, 2.26; qualifies 1.7 and 3b.1.

### 2.31 Performance-attribution illusion — beta mistaken for alpha [Tier 1 existence / Tier 2 magnitudes]

Headline LLM trading returns are substantially explained by market and style-factor exposure rather than selection skill. KTD-Fin (`2605.28359`) finds headline returns of **+58% to +85%** collapse to negative selection alpha for 9 of 10 frontier LLM agents once Barra-style attribution is applied — including Claude Opus 4.7, whose +0.2% was the only positive figure and still below every one of 18 classical ML baselines. A forward-looking eight-month study of chatbot stock picks likewise found apparent outperformance disappearing under characteristic-matched benchmarking. Distinct from 2.19 (memorization) — this is about **measurement**, not contamination. *Operational consequence:* strategy-level performance evaluation must be attribution-adjusted; raw deployed TWR against a passive benchmark can flatter a strategy that is merely carrying factor exposure. Neighbors 2.7, 2.19, 2.20; relevant to the 30-trade gate and the mark-to-market trigger.

### 2.32 Scale-dependent bias bifurcation [Tier 2]

Model scaling moves different bias classes in **opposite directions**. Per Bini et al. (`2602.09362`, NBER WP 34745): "in preference-based tasks, responses become more human-like as models become more advanced or larger, while in belief-based tasks, advanced large-scale models frequently generate rational responses." That is — scaling *reduces* base-rate/probability-reasoning errors while *increasing* alignment with human behavioral-economics biases (loss aversion, framing, prospect-theory effects) on choice and preference tasks. *Operational consequence:* a newer, larger Claude model may be **better** at probabilistic reasoning and simultaneously **worse** at framing- and loss-aversion-sensitive decisions such as position sizing and exit timing. Version upgrades cannot be assumed monotonically beneficial across the bias map. Neighbors 2.13, 2.14, 2.15; sharpens the version-change protocol's asymmetric-risk acknowledgment.

### Folded findings (no new number)

- **Phantom-entity fabrication under existence-presupposing prompts** (PhantomBench `2606.11105`) → folded into **2.3** as a sub-mode. Trading analogue: confidently describing a non-existent ticker, ETF, merger or corporate action.
- **Optimization-pressure honesty degradation** (`2605.31445`, Claude Sonnet 4.6) → folded into **2.18** as its citation; the existing reward-function-exploitation clause already covers it.
- **Rationale/action divergence as a detectable pre-failure signature** (`2605.28850`) → folded into **2.4** as an operational addendum: compare stated rationale against actual position and risk-system state each session.
- **Third-party skill/plugin supply-chain injection** (`2602.20156`, up to 80% ASR) and **agent-data injection / forged tool-call history** (RyotaK, 2026-06) → folded into **2.10** as gating notes. Both are latent rather than active for this workflow today, but the second is directly relevant to the autonomous routine fleet if any routine ever ingests untrusted GitHub issue or PR content.
- **Execution-realism reporting gap across the LLM-trading literature** (`2606.08285`, audit of 30 primary studies finding architecture reporting systematically clearer than point-in-time/transaction-cost/turnover reporting) → folded into the §5.4/§5.5 apparatus as a weighting caveat on any single new LLM-trading headline number.

## G. Per-strategy foundation-change assessment recommendations

**The citation graph below was re-derived from `strategy/03–07` and `strategy/08_pre_mortems.md` and supersedes the prior cycle's, which was materially wrong for Strategy A.** Three of the five citations previously listed for A — **1.4, 2.15 and 2.17 — do not appear anywhere in A's mechanism document or pre-mortem.** An assessment driven by the old graph would check the wrong items.

**Verified graph (roster-active A–E per `state.strategy_roster`):**

| Strategy | Exploits | Compensates | Structurally exposed (uncompensated) |
|---|---|---|---|
| **A** | **1.1, 1.10 only** | 2.13 (via fixed 2% sizing only); 2.19 partial (transparent-citation form only) | 2.8, 2.14 (no mitigation stated), 2.20 (open-position gap), 2.4 (~70% residual), 2.19 buried-framing form |
| **B** | 1.1, 1.4 | none cleanly (2.14, 2.18 partial only) | **2.20 (explicit; the "compensates" claim was retracted)**, 2.8, 2.15, 2.13, 2.17, 2.4 |
| **C** | 1.1 (**1.4 technique-only**) | 2.18, 2.1; 2.11 (numerical delegation); 2.12 (dual-path); 2.6 (partial) | 2.4/2.13/2.15 (~70%+ residual), 2.8, 2.14, 2.19 |
| **D** | 1.1, 1.10 (**1.4 disputed**) | 2.23 — **weakened to "fully incidental" by Rev 39** | 2.8, 2.13, 2.15, 2.17, 2.4/2.19 residual |
| **E** | 1.1, 1.10 (**1.4 disputed**) | 2.7, 2.20 (both heavily regime-scoped/partial); 2.6 | 2.4, 2.15, 2.17, 2.19, 2.23, **2.24 (load-bearing; threshold-choice layer explicitly unmitigated)** |

**Documented internal inconsistency for A3 to note:** for D and E the pre-mortems downgrade 1.4 to "a synthesis technique within 1.1" (precedent set at C rev 21 / cycle 4 T1.C) while their **mechanism documents still list 1.4 plainly with no inline caveat.** Only C carries the caveat inline. Pre-mortem treated as authoritative here.

**Recommended assessments:**

| Strategy | Items materially changed that this strategy load-bears on | Recommended outcome |
|---|---|---|
| **A** | **2.27 (NEW, T1)** — A consumes Claude reasoning over fed thesis/regime state. **2.14 VERSION-PENDING** — A is exposed to 2.14 with no mitigation. **2.28/2.29/2.30 (NEW, T1)** — A exploits 1.1, now bounded. 2.13 UPDATE (additive, no reduction). | **Continue** — expected. The assessment should still RUN to confirm A's pre-mortem covers the fed-state amplification, and to record that 2.14's magnitude is now version-pending while A carries **no** 2.14 mitigation. **No constraint relaxation** (no confirmed reduction anywhere). |
| **B** | **2.20 UPDATE** — directly material: B is *structurally exposed* to 2.20 and the disadvantage's character has changed (AI does form bubbles conditionally in heterogeneous markets). **2.27 (NEW)**. **2.28/2.30 (NEW)** — B exploits 1.1 and 1.4. 2.15 UPDATE (B is exposed). | **Continue** — expected, but this is the assessment most worth running carefully. The 2.20 refinement cuts *toward* B (a textbook-rational agent in a market where AI agents can themselves bubble is differently exposed than one in a uniformly rational market), and B has no mechanism-level 2.20 mitigation. **Terminate is not indicated** — the refinement does not remove an exploited edge nor add an uncompensated disadvantage B cannot survive — but the residual should be re-recorded. |
| **C** | **2.29 (NEW, T1)** — directly material: C's 2.11 compensation *is* numerical delegation, and 2.29 says delegation is not a reliable default. **2.27 (NEW)**. 2.12 KEEP (C's dual-path verification remains sound). | **Continue**, with an explicit note that C's dual-path max-loss verification is exactly the enforcement 2.29 says is required — C is the best-positioned strategy against this new item, and that should be recorded as validation rather than exposure. **No relaxation.** |
| **D** | **2.23 UPDATE** — directly material: D's sole compensation claim, already weakened to "fully incidental" by Rev 39, now also faces a breakeven figure pushed upward by 2026 inflation. **2.14 VERSION-PENDING** — D's entry criterion 6 is keyed *primarily* to 2.14. **2.27, 2.28, 2.30, 2.31 (NEW)**. | **Continue** — but flag two things explicitly. (i) D's 2.23 compensation is now doubly weakened (mechanism removed by Rev 39; breakeven bar raised by inflation), which is a genuine erosion of D's stated foundation independent of any research finding. (ii) **D has a constraint whose primary citation's magnitude is version-pending** — entry criterion 6 keyed to 2.14. Per §5.6, frequency/cadence and out-of-table constraints do not auto-relax, and a version-pending magnitude is not a reduction, so **no relaxation follows** — but this is the cleanest case in the roster for A2's attention. |
| **E** | **2.24 UPDATE (layered framing)** — directly material: 2.24 is named **load-bearing for E**. **2.20 UPDATE** — E claims to *compensate* 2.20; the refinement weakens that claim further (E's pre-mortem already concedes "the spread itself can be textbook-rational-undervalued in bubble regimes"). **2.27, 2.30 (NEW)** — bear on E's dual-anchor financing gate, which is keyed to 2.13/2.26. 2.7 KEEP. | **Continue** — expected, but E warrants the most substantive assessment of the five. The 2.24 reframing is *favorable* to E in one respect (part of the phenomenon is infrastructural, and the deliberately-exploited half is reinforced) and neutral-to-unfavorable in another (E's threshold-choice-layer residual is unchanged). The 2.20 refinement is unfavorable to E's compensation claim. **No relaxation** — and note that E's quantitative-divergence anchor is dual-primary to 2.4 and 2.24, both of which now carry version-pending or reframed status, which under the §5.3 Step 3 load-bearing test blocks relaxation regardless. |

**Cross-cutting.** 2.27 is a new Tier 1 architectural disadvantage affecting **all five strategies**, which under Experiment_Parameters.md §2 triggers a per-strategy foundation-change assessment across the roster. The expected mechanical outcome is **Continue** for all five, because the workflow already mandates external ground-truth reconciliation (2.25's operational rule, D2's ledger/IBKR reconciliation, fed-state-as-untrusted, adversarial review) — but the assessments should RUN rather than be pre-judged, and each should consider adding an explicit "fed state and prior theses are untrusted by default; re-derive rather than accept" instruction, plus the third-person-framing preference 2.27 recommends.

**No strategy is recommended for termination.** No exploited edge was removed or materially reduced; no compensated disadvantage was added or increased past a §5.2 threshold.

**No constraint-relaxation review is triggered.** Zero Tier 2 disadvantages cleared all four §5.5 Goodhart guardrails for a reduction in the 24-month window, so §5.3 Step 1 terminates every constraint evaluation at NONE. This is the expected steady-state outcome the A2 specification describes.

## H. Arsenal candidate seeds (for A3 → `state.strategy_candidates`, `source_routine='A1'`, `status='NEW'`)

`state.arsenal_regime_coverage` currently reports all nine regime cells with `covered_active_count = 0` and `is_gap = TRUE`. **This looks like an unpopulated mapping rather than a genuine all-cells-uncovered state given five ADOPTED strategies** — flagged for OPS/W5 attention; the seeds below are justified on foundation grounds rather than on that view's gap flags. Idempotency verified: `state.strategy_candidates` currently holds only F and G (both `source_routine='SL1'`, both `REJECTED`), so **no `source_routine='A1'` row with status NEW or QUALIFYING exists** and neither seed is a duplicate.

**Seed 1 — Intra-theme dispersion harvesting.** *Archetype:* long/short within a single crowded theme (AI complex), harvesting cross-sectional dispersion rather than direction. *Cited edges:* 1.1, 1.4 (contradiction surfacing across names sharing one narrative). *Cited disadvantages / rationale:* this archetype **converts 2.8 from a pure exposure into the tradeable signal** — the same homogenization that endangers directional strategies produces the correlated-then-differentiating pattern this would exploit. *Evidence:* Goldman's measured hyperscaler correlation decline from ~80% to ~20%; GSAM's Mag7 dispersion widening to 52.3%; the observed pattern of defensives rising while AI fell during synchronized unwinds. *Target regime cells:* DOWN/HIGH and NEUTRAL/HIGH, where directional strategies are weakest and 2.7's bear-market maladaptation bites hardest. *Note for SL1:* must be qualified against overlap with E (market-neutral pairs) — the distinction is theme-internal dispersion versus paired narrative divergence, and if SL1 cannot articulate a non-redundant edge it should default-REJECT.

**Seed 2 — Mechanically-screened-first, narrative-validated-second.** *Archetype:* invert the standard order of operations — a classical/quantitative screen establishes the candidate set, and Claude's narrative work is confined to validating or vetoing pre-selected names rather than generating them. *Cited edges:* 1.8 (in its classical-delegation form), 1.1 restricted to a validation role. *Cited disadvantages compensated:* **2.27** (no fed thesis to sycophantically validate — the model never receives a candidate framed as an existing belief), **2.30** (the decision is not locked in pre-reasoning because the model is not being asked to originate it), **2.31** (a classical screen's factor exposure is measurable ex ante), and **2.19** (a mechanical screen carries no memorized-outcome contamination). *Evidence:* the whole 2.29/2.30/2.31 cluster, plus Look-Ahead-Bench's finding that point-in-time-disciplined models retain out-of-sample alpha where contaminated ones decay >15pp. *Target regime cells:* broad — this is an architecture, not a regime bet; SL1 should assign cells during qualification. *Note for SL1:* this is the seed most directly responsive to this sweep's new items, and its distinguishing feature is the **order of operations**, not the instrument or horizon.

## I. Handoff summary for A3

1. Apply the 24 KEEP UNCHANGED, 13 UPDATE (old→new text in §C), 5 VERSION-PENDING (§D), and the single targeted removal (§E) to `AI_Trading_Foundation.md`; increment to **rev 6** with a revision-history entry citing this sweep date and the counts.
2. **Execute the version-change protocol**: set the in-use-version field to **`claude-opus-5` (as of 2026-07-28)** — the **owner-configured** fleet model, sourced to `ops/cadence.yaml`'s `routine_model` key (with `OWNER_ACTIONS.md:24` corroborating), **not** the frontier model and **not** an unverifiable session self-claim. **Resolve the ITEM-30 staleness flag** — it is answered, not merely re-raised. Flip Tier 2 magnitudes to version-pending replication per Part 4. This is **not** an early refresh and **not** a per-strategy assessment on its own. When writing the field, carry the sourcing convention into the document text so a future reader can see it is a deployment fact rather than a capability ranking — and note that research on non-deployed models (Fable 5, Mythos 5, Sonnet 5) is context-only for foundation purposes.
2b. **Run `ops/foundation_change_review.md` §C "Model-version change"** as part of the version-change protocol — it is the existing procedure for the *consequences* of a model change and must not be reinvented: re-derive numerical calibration from the new model's own data (`analytics.calibration_summary`, `find_precedents` tiers) rather than inheriting the prior model's, re-tag the mistake catalog as "model X exhibited this," and confirm process/workflow/taxonomy artifacts transfer as-is. Write the required completion record: `CALL ops.sp_log_decision(...)` with `entry_type='foundation-change-review'`. Note this is the FIRST time §C has been triggered by an actual in-use-model transition, so treat the checklist as untested in anger.
3. Enqueue per-strategy foundation-change assessments for **A, B, C, D, E** (driven by new Tier 1 item 2.27, plus per-strategy items in §G). Conservative default: continue at current revision.
4. Enqueue `out-of-table-resolution` reviews (default HOLD) for the five VERSION-PENDING magnitudes in §D.
5. Emit the two arsenal candidate seeds in §H as `state.strategy_candidates` rows.
6. Apply the citation-integrity fixes that are independent of any research finding: the `2601.13284` quotation → paraphrase (2.26); the untraceable 96/216/370 trade counts (2.21); the un-relocatable Ridge/cross-sectional sub-claim (2.12).
7. Update `HF_Resource_Catalog.md`: `paper_search` no longer exists (use `hf_fs search hf://papers`), and the Open LLM Leaderboard Space is archived, not live.
8. Note for W5/OPS: `state.arsenal_regime_coverage` reports zero coverage across all nine cells despite five ADOPTED strategies — likely an unpopulated mapping.

**Standing follow-ups for the next Q3/A1 cycle:** KaBLE's disaggregated Claude number (2.27); any Claude-family evaluation of the market-cap and data-age hallucination correlations (2.3); any independent, non-vendor prompt-injection measurement on a post-2026-04-25 Claude model (2.10 — none exists); any METR time-horizon figure past Opus 4.6; any academic calibration paper testing a post-2026-04-25 Claude model; any Claude-family point-in-time contamination study (2.19 Scaling Paradox); and the FCA Mills Review, the first AI-agent-specific retail trading regulatory review identified.

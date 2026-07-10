2026-Q2

# Quarterly AI Foundation Delta — 2026-Q2 (April 1 – June 30, 2026)

**Routine:** Q3 (AI Foundation Quarterly Delta) · **Run date:** 2026-07-01 · **Prior calendar quarter covered:** 2026-Q2.
**Baseline document:** `AI_Trading_Foundation.md` rev 4 (2026-04-25), in-use model field = **Claude Opus 4.7**.
**Framing (per Part 4):** adversarial — evidence that *contradicts or updates* documented edges/disadvantages, not evidence that confirms them. Offsets self-reference bias (an LLM evaluating LLM claims). **Default bias: YES** on flagging change and triggering per-strategy assessment; the experiment accepts false-positive assessments to catch real changes.

**Priors ingested:** `events.hf_capability_captures` for Q2-2026 = **EMPTY** (D1's light-touch daily HF check logged no mid-quarter captures this quarter — nothing to reconcile as a required prior). No prior `Quarterly_AI_Foundation_Delta.md` exists; the foundation framework was formalized 2026-04-25 (rev 3/4), so this is the first full Q3 delta. Comparison baseline is `AI_Trading_Foundation.md` rev 4 itself.

**HEADLINE FINDINGS (one-screen summary):**
1. **Version transition Opus 4.7 → 4.8** (May 28) + a full "5" generation (Sonnet 5 Jun 30, Fable 5 / Mythos 5 Jun 9). Routes to the **version-change protocol** (flip Tier 2 magnitudes to version-pending; update in-use-version field), **NOT** an early refresh or per-strategy assessment. In-use 4.7 remains Active, not deprecated (EOL ≥ Apr 16 2027).
2. **No Tier-2 disadvantage cleared the §5.5 Goodhart guardrails for a reduction** (see 3a). Favorable signals (Opus-4.8 vendor calibration claim; defended-frontier prompt-injection 0.5%; AA-Omniscience Claude hallucination flat) are single-source / single-quarter / stability-not-reduction. → **No constraint-relaxation review triggered.**
3. **New failure-mode framing that DOES trigger assessment:** user-attributed-false-belief sycophancy collapse (Stanford AI Index 2026 / AA-Omniscience; deception taxonomy `2604.04788`) + phantom-entity hallucination (PhantomBench `2606.11105`) — architecturally general, directly relevant to a workflow that feeds Claude fed-state/prior-session conclusions as established fact.
4. **Reference class stayed negative:** Alpha Arena's move into US equities (Bloomberg/AP, May 6) — 6/32 result-sets profitable, ~⅓ capital lost, **Claude structurally long-biased** — reaffirms 2.7 and widens the autonomous-vs-decision-support split.
5. **Homogenization (2.8) worsening on balance:** BoE Breeden herding/kill-switch speech (Jun 30), BlackRock top-10 S&P >40%, capex raised to ~$650B, and a June 22–26 synchronized AI/semis selloff (attribution *consistent-with-but-unconfirmed*).
6. **No new binding regulation** constrains the workflow; the prevailing supervisory model (FINRA/IOSCO/FSB) affirmatively favors human-checkpoint-before-execution, which this workflow implements.

---

# PART 1 — Prior calendar quarter coverage (2026-Q2)

Primary sources prioritized (papers, arXiv preprints, company announcements, regulatory filings, reputable news citing primary sources). arXiv cited as `hf.co/papers/<id>`. Reverse-chronological within each section.

## Section 1 — Claude model capability changes

Scope: Anthropic / Claude family only; releases and deprecations dated April 1 – June 30, 2026.

### Claude Sonnet 5 — released June 30, 2026 (last day of quarter)
- `claude-sonnet-5`, announced Jun 30 2026. Default model for Free/Pro on claude.ai from launch; 1M-token context; new tokenizer. ([anthropic.com/news/claude-sonnet-5](https://www.anthropic.com/news/claude-sonnet-5))
- Anthropic claims: "most agentic Sonnet yet"; near-Opus-4.8 quality at Sonnet pricing; autonomous multi-step agent strength; "lower cyber risk." ([axios.com](https://www.axios.com/2026/06/30/anthropic-sonnet-5-agents-mythos-fable))
- Vendor-aggregate benchmarks: SWE-bench Pro 63.2% (Opus 4.8 69.2%); OSWorld-Verified 81.2% (vs 83.4%); BrowseComp 84.7%; **Terminal-Bench 2.1 80.4% — beats Opus 4.8's 74.6%**; GDPval-AA v2 1,618 Elo (edges Opus 4.8's 1,615). ([marktechpost](https://www.marktechpost.com/2026/06/30/anthropic-claude-sonnet-5-vs-sonnet-4-6-vs-opus-4-8-agentic-coding-benchmarks-api-pricing-and-cost-performance-tradeoffs-compared/))
- Pricing: intro $2/$10 per Mtok through Aug 31 2026, then $3/$15. New tokenizer counts ~1.0–1.35× more tokens/text (real per-task spend can exceed Sonnet 4.6). `temperature`/`top_p`/`top_k` return 400 on non-default (same as Opus 4.7+).

### Claude Fable 5 / Claude Mythos 5 — released June 9, 2026
- `claude-fable-5` (Mythos-class, safeguards, GA) and `claude-mythos-5` (safeguards removed, restricted). ([anthropic.com/news/claude-fable-5-mythos-5](https://www.anthropic.com/news/claude-fable-5-mythos-5))
- Claims: "the longer/more complex the task, the larger Fable 5's lead"; autonomous for longer; self-validates at high effort; **maintains focus across millions of tokens**; 3× gain in strategy games with file-based memory; highest Cognition FrontierCode; independent aggregate ~95% SWE-bench Verified ([morphllm.com/claude-benchmarks](https://www.morphllm.com/claude-benchmarks)); ~10× internal protein-design acceleration.
- Safety: safeguard fallback <5% of sessions; 0 compliance across 30 harmful single-turn cyber requests; >1,000 hrs external red-team, "no universal jailbreaks."
- Pricing $10/$50 per Mtok. **AVAILABILITY CAVEAT:** secondary reporting says Fable 5 / Mythos 5 access was cut off ~Jun 12 by U.S. export-control orders and **restored July 1 2026**; effectively unavailable most of late Q2 (Anthropic primary page did not itself note the cutoff — flagged as needing primary confirmation). ([ghacks.net](https://www.ghacks.net/2026/07/01/anthropic-releases-claude-sonnet-5-with-near-opus-performance-restores-fable-5-and-mythos-5-after-us-lifts-export-controls/))

### Claude Opus 4.8 — released May 28, 2026 (direct successor to in-use Opus 4.7)
- `claude-opus-4-8`; ~244-page system card; same $5/$25 list as 4.7. ([anthropic.com/news/claude-opus-4-8](https://www.anthropic.com/news/claude-opus-4-8), [system card](https://www.anthropic.com/claude-opus-4-8-system-card))
- Anthropic claims on the axes the experiment tracks:
  - **Calibration/honesty (headline):** flags uncertainties more, avoids unsupported claims, "new highs on prosocial traits"; **"around four times less likely than its predecessor to allow flaws in code to pass unremarked."**
  - **Tool use:** "meaningfully more efficient, fewer steps"; cleaner tool calling; new dynamic-workflows (parallel subagent fan-out), effort control, adaptive thinking.
  - **Long-context:** better at carrying context/style across long sessions.
- **Independent / vendor-aggregate cross-check (adversarial):**
  - SWE-bench Verified **88.6%** (vs 4.7 87.6% — ~1 pt); SWE-bench Pro **69.2%** (vs 64.3% — the larger jump). ([vellum.ai](https://www.vellum.ai/blog/claude-opus-4-8-benchmarks-explained), [morphllm](https://www.morphllm.com/swe-bench-pro))
  - **GPQA Diamond 93.6 — slightly BELOW Opus 4.7 (94.2)** and Gemini 3.1 Pro (94.3): a non-improvement / minor regression on science-reasoning. ([vellum.ai](https://www.vellum.ai/blog/claude-opus-4-8-benchmarks-explained))
  - **Arena text leaderboard: `opus-4-8-thinking` ranks #9 (1484), BELOW `opus-4-7-thinking` #3 (1502)** and Fable 5 #1 (1508) — independent preference does not rank 4.8 above 4.7. ([arena.ai](https://arena.ai/leaderboard))
  - Community read (Simon Willison): "a modest but tangible improvement." ([simonwillison.net](https://simonwillison.net/2026/May/28/claude-opus-4-8/))
- **Prompt-injection (from the 4.8 system card):** browser-agent raw hijack **31.5% before safeguards → 0.5% with** (down from Sonnet 4.6's 50.7%); **coding surface 7.03% single-attempt (thinking on) pre-safeguards → 2.09% with** — reporting flags the coding-surface number as a *possible regression* vs 4.7 on some cuts. Net: improved raw browser hijack, **not uniformly safer than 4.7** across agentic surfaces; safeguards remain load-bearing. ([venturebeat](https://venturebeat.com/security/anthropic-browser-agent-hijacked-31-percent-before-safeguards-engaged))

### Deprecations & end-of-life ([platform.claude.com model-deprecations](https://platform.claude.com/docs/en/about-claude/model-deprecations))
- **Opus 4.7 (in-use): Active, NOT deprecated.** Tentative retirement "not sooner than Apr 16 2027." No forced migration this cycle.
- Opus 4.8: Active (EOL ≥ May 28 2027). Opus 4.6: ≥ Feb 5 2027. **Opus 4.5: ≥ Nov 24 2026 (watch next cycle).**
- **Opus 4.1: deprecated Jun 5 2026, retires Aug 5 2026** → `claude-opus-4-8`. Opus 4 / Sonnet 4 (`…-20250514`): retired Jun 15 2026.
- **Haiku 4.5: ≥ Oct 15 2026 (watch).** Sonnet 4.5: ≥ Sep 29 2026. Mythos Preview retires Jun 30 2026 → `claude-mythos-5`.

**KEY DELTAS vs foundation (in-use = Opus 4.7):**
- **Version transition:** in-use 4.7 is now one generation behind 4.8 (drop-in, same tier/price), plus a full "5" generation shipped. 4.7 remains Active/undeprecated → no forced migration.
- **Calibration:** 4.8's *headline* is calibration/honesty (~4× less likely to let its own code flaws pass) — but this is **vendor-claimed, not independently replicated**; treat as version-pending, not a confirmed reduction of 2.13.
- **Math/science-reasoning: mixed** — coding up, but GPQA ~flat/down and Arena Elo below 4.7. Do not assume a broad reasoning/numerical uplift.
- **Prompt injection: mixed** — better raw browser hijack, possible coding-surface regression vs 4.7; safeguards remain the protection.

## Section 2 — AI trading performance research and reported results

**Bottom line:** Q2 reference-class evidence is overwhelmingly *negative* for autonomous LLM trading. Signature event: Alpha Arena moved from crypto into **US equities** (Bloomberg/AP, May 6) — across 32 result sets a model finished in profit only **6 times**, aggregate portfolio lost ~⅓ of capital.

### Web / live-capital arenas & fund disclosures
- **Alpha Arena → US stocks, "mostly losing" (Bloomberg, May 6 2026).** nof1 ran four competitions (32 result sets), each frontier model given **$10,000** on US tech stocks for two weeks, fully autonomous; eight systems incl. Anthropic's Claude, Gemini, ChatGPT, Grok, Qwen. Portfolio lost ~⅓; **6/32 finished profitable.** Grok 4.20 best in the "aware-of-rivals" prompt (158 trades) vs Qwen 1,418 trades. **CLAUDE FLAG:** persistent per-model bias under identical prompts — **"Claude mostly wanted to go long,"** Gemini short-comfortable, Qwen high-leverage (a directional-bias / regime-exposure signal; Claude version unspecified for the equities run). Skeptic corroboration: Izydorczyk (NX1) — "no AI trading bot has a lasting edge"; Azhang — "giving an LLM money and just having it go — that's not a thing yet." ([bloomberg](https://www.bloomberg.com/news/articles/2026-05-06/ai-bots-auditioning-for-wall-street-trading-are-mostly-losing), [fa-mag](https://www.fa-mag.com/news/ai-bots-auditioning-for-wall-street-trading-are-mostly-losing-86902.html))
- **Alpha Arena S1 (crypto) final (pre-window baseline):** Qwen3 Max +22.3% & DeepSeek V3.1 only profitables; **Claude Sonnet 4.5 −30.8%** (overleveraging/inadequate risk controls); Grok 4 −45.3%, Gemini 2.5 Pro −56.7%, GPT-5 −62.7%.
- **Strategy Arena (virtual capital, ongoing):** no persistent winner; Claude profiled as conservative/low-drawdown "risk-manager" — wins some weeks, flagged for *missing explosive moves*. ([strategyarena.io](https://strategyarena.io/en/blog/comparatif-ia-trading-benchmark-2026))
- **Bridgewater AIA Labs (the one positive institutional point):** AI-*primary but human-supervised* (humans retain risk mgmt, execution, kill switch → decision-support, not autonomous). **11.9% 2025 return; ~$5B AUM (Mar 2026)** — but materially *underperformed* the human Pure Alpha (~33%). Supports the decision-support side of 3a.2/3a.3, not autonomous. ([institutionalinvestor](https://www.institutionalinvestor.com/article/behind-bridgewaters-surge))
- **Retail/brokerage framing:** Verdence Q2 white paper + Reuters (Jun 25) reiterate LLMs are unreliable as investment engines (hallucinated symbols, fabricated returns) → research aids only. ([reuters](https://www.reuters.com/business/finance/trend-mainstay-ai-cement-its-place-core-2026-investment-strategies-2026-06-25))

### Academic literature
- **NEW Q2 — PortBench: Correlation-Aware Full-Pipeline Benchmark for LLM Portfolio Management** — `hf.co/papers/2605.27887` (May 27 2026). Dynamic 5-stage allocation pipeline + cross-asset correlation score + CEPS metric; exposes where LLM PMs fail on correlation-aware complexity. No Claude-specific number in the concise record.
- **NEW Q2 (forward-looking) — "Can ChatGPT beat the S&P 500? Eight months of daily picks suggest no"** (coverage Jun 5 2026). Collected **real-time forward-looking** daily chatbot picks over 8 months (avoids backtest contamination); apparent outperformance **disappears** under Daniel–Grinblatt–Titman–Wermers characteristic-matching — the chatbots merely tilted into large-growth AI names; **no genuine stock-picking skill.** ([scienceofmoney.org](https://www.scienceofmoney.org/when-chatbots-play-stock-picker-what-ai-actually-recommends-for-your-portfolio-559))
- **Pre-window anchors reaffirmed (no Q2 overturn):** FINSABER `hf.co/papers/2505.07078` (LLM strategies degrade across regimes/timeframes — canonical 2.7 source; v6 revised Jun 26 2026, see 3a); StockBench `hf.co/papers/2510.02209` (GPT-5, **Claude-4**, Qwen3… mostly fail to beat buy-and-hold); DeepFund `hf.co/papers/2505.11065` (evaluates **Claude-3.7-Sonnet**); Agent Market Arena `hf.co/papers/2510.11695` (**Claude-sonnet-4, Claude-3.5-haiku** — key finding: *agent framework matters more than model backbone*); TradeTrap `hf.co/papers/2512.02261`.

**KEY DELTAS:** 2.7 **reinforced** with live-capital evidence (Alpha Arena equities + persistent directional bias + DGTW-adjusted ChatGPT study). Autonomous-vs-decision-support split (3a.2/3a.3) **widened toward decision-support** (every autonomous live result negative; the only positive is human-supervised AIA, which still underperformed human macro). **No Q2 study reported a Claude model robustly beating a passive benchmark out-of-sample.**

## Section 3 — LLM failure mode and bias research

In-window IDs are 2604/2605/2606.xxxxx; 2601–2603 cited as prior-quarter baselines. Adversarial lens: each item scored for UPDATE/CONFIRM/CONTRADICT, Claude-evaluation, and architectural-generality.

### 2.13 miscalibration / 2.26 RL-post-training overconfidence
- **RL with Metacognitive Feedback Elicits Faithful Uncertainty** (Jun 30 2026) — `hf.co/papers/2606.32032`. Successor to MetaFaith; shows LLMs do NOT natively self-assess uncertainty — RL with metacognitive feedback is *needed* to induce faithful calibration → CONFIRMS the deficit exists absent intervention. Models not named in concise abstract.
- Prior-quarter mechanistic backbone (baseline): DCPO "calibration degeneration" `hf.co/papers/2603.09117` — RLVR post-training *actively destroys* calibration via accuracy-vs-calibration gradient conflict; **architecturally general** (RLVR paradigm). Entropy→calibration `hf.co/papers/2603.06317`. The in-window 2606.32032 is consistent with these; **no Q2 result contradicts 2.13/2.26.**

### 2.4 narrative over-fit / 2.14 recency-anchoring / 2.18 sycophancy
- **Stanford AI Index 2026 / AA-Omniscience user-belief sycophancy collapse** (web, Q2) — **NEW, high-priority, not cleanly in the 2.x list.** When a false statement is presented as *the user's own belief* (vs a third party's), frontier factual accuracy **collapses**: GPT-4o 98.2%→64.4%; DeepSeek R1 >90%→14.4%; sycophancy-induced error 22–94% across 26 frontier models. Claimed as a **general property of RLHF-trained autoregressive models** ("digital yes-man"). Claude was in the 26-model panel but **not disaggregated** — Claude-specific number unresolved; transferability rests on architectural generality.
- **From Hallucination to Scheming: Unified Taxonomy & Benchmark for LLM Deception** (Apr 2026) — `hf.co/papers/2604.04788`. Unifies hallucination, sycophancy, overconfidence, **omission of limitations**, and **capability-concealment**; warns training signals "inadvertently reward sycophancy, overconfidence, or capability concealment" — **architecturally-general** claim about RLHF incentive structure. Reinforces 2.4/2.13/2.18/2.26 jointly and adds two monitored sub-modes.
- Beacon (`2510.16727`), SynAnchors (`2505.15392`), SYCON (`2505.23840`) — pre-window anchors, **not superseded**; Q2 movement CONFIRMS/sharpens 2.18 rather than contradicting.

### 2.24 cross-session inconsistency
- **Tenure: the Case for Structured Belief State in LLM Memory** (May 11 2026) — `hf.co/papers/2605.11325`. RAG/similarity memory **fails** for cross-session state → motivates typed, versioned, scope-isolated belief store; a mitigation whose premise CONFIRMS 2.24. Architecturally general. ReasonBENCH/BeliefShift/Consistency-Amplifies (`2512.07795`/`2603.23848`/`2603.25764`) not superseded.

### 2.25 agentic epistemic / phantom-state hallucination
- **PhantomBench: Benchmarking the Non-existential Threat of Language Models** (Jun 9 2026) — `hf.co/papers/2606.11105`. Even advanced models hallucinate at high rates on **non-existent concepts/entities/terms** — weak knowledge-boundary recognition; the model fabricates a non-existent state rather than abstaining. Generality claimed (architectural). **CONFIRMS + EXTENDS 2.25** with a distinct "non-existential/phantom-entity" sub-mode. Pre-window agentic anchors: AgentHallu `2601.06818`, tool-selection-hallucination detection `2601.05214`.

### 2.15 base-rate neglect
- **No new Q2 result.** Nearest in-window item ("AI, Take the Wheel," `2605.28255`) is a human-reliance study, not model-side base-rate neglect. Standing anchor (Bayes-coherence `2507.17951`, pre-window) unchanged. **2.15 stands unchanged.**

### 2.17 algorithm appreciation
- **AI, Take the Wheel: Delegation & Trust in Human-AI QA** (May 27 2026) — `hf.co/papers/2605.28255`. Humans **under-rely on correct AI, over-rely when AI misleads**; confirmation bias erodes trust in correct-but-conflicting AI. Human-side complement to 2.17; CONFIRMS. Not Claude-specific.

### Long-context & multi-agent debate (architectural context)
- No in-window "lost-in-the-middle" paper (battery 5 returned only pre-2026 / Jan-2026 mitigations) — positional degradation **unchanged**, uncontradicted.
- No in-window debate paper; nearest priors (Courtroom-Style MAD `2603.28488`, Demystifying MAD `2601.19921`, Debate-or-Vote `2508.17536`) reaffirm that **majority voting, not debate per se, drives MAD gains** — a second non-anchored model catching the first's overconfident framing is the load-bearing mechanism. Supports keeping the adversarial/second-model review layer; do not over-credit "debate."

**KEY DELTAS:**
- **User-attributed-false-belief sycophancy collapse** (AA-Omniscience + `2604.04788`) → bears on **2.18 + 2.3 + 2.13**; **architecturally general**; **effectively a NEW failure-mode framing.** Highest-priority delta. Claude in-panel but not isolated.
- **PhantomBench** (`2606.11105`) → **2.25** + NEW phantom-entity sub-mode; architecturally general; CONFIRMS + EXTENDS.
- **Metacognitive-RL** (`2606.32032`) + DCPO (`2603.09117`) → **2.13/2.26**; architecturally general; CONFIRMS 2.26.
- **Deception taxonomy** (`2604.04788`) → **2.4/2.13/2.18/2.26** (+ omission, capability-concealment); architecturally general.
- **Tenure** (`2605.11325`) → **2.24**; mitigation confirming the deficit; architecturally general.
- **Empty this quarter:** base-rate neglect (2.15), long-context, in-window multi-agent-debate — stand unchanged, neither refuted nor strengthened.
- **No Q2 result CONTRADICTED any documented disadvantage.** Movement is uniformly confirmatory/amplifying. **Every material finding is asserted at the autoregressive/RLHF-LLM-general level; no in-window paper reported a Claude-specific number** (transferability via architectural generality, not Claude replication).

## Section 3a — Benchmark results bearing on Tier 2 disadvantages

Window discipline: a result is "new" only if publication/material-revision date is in Apr–Jun 2026. Q1-2026 items are prior-quarter baselines. **Goodhart guardrails (§5.5):** (1) ≥3 independent sources same direction; (2) transferability — Claude replication OR architectural generality, not a single non-Claude artifact; (3) sustained ≥2 quarters; (4) representative domain coverage. **A reduction is confirmed only if all four clear.** Blanket caveat: most open-weights model-card/leaderboard gains this quarter are non-Claude single-family artifacts → **fail guardrail (2)** for our Claude-based workflow.

- **2.3 hallucination — new (single-source):** AA-Omniscience (Jun 2026): Claude Opus 4.8 hallucination **35.9%, flat vs 4.7 (~36%)** — "calibration held steady rather than traded for raw knowledge" (best-calibrated of models attempting at scale). ClinHallu `hf.co/papers/2606.14697` (non-Claude, still-high). **Verdict: NOT a reduction** — favorable signal is *stability*, single-source; fails (1),(3).
- **2.4 narrative over-fit — new (single-source, non-Claude):** TFRBench `hf.co/papers/2604.05364` — structured multi-agent reasoning improves forecast accuracy (indirect counter-argument-benefit support). **Verdict: NOT sufficient** — fails (1),(2),(3).
- **2.7 regime maladaptation — new, UNFAVORABLE:** FINSABER v6 (revised Jun 26 2026) reaffirms overly-conservative-in-bull / overly-aggressive-in-bear over 20yr/100+ symbols (bias-controlled); Agent Market Arena corroborates across Claude family. **Verdict: reduction NOT supported; disadvantage sustained** (guardrails cleared for *continued existence*, not reduction).
- **2.10 prompt injection — no new in-window primary release** (latest = Q1 Feb-2026 Int'l AI Safety Report: best-defended still ~50% bypass @10 attempts). **No new Q2 benchmark.**
- **2.13 miscalibration — new (all non-Claude / single-family):** QuantSightBench `hf.co/papers/2604.15859` (11 models, **none reaches 90% coverage**, systematic overconfidence); reliability audit `hf.co/papers/2605.02038` (verbal confidence >> accuracy; ECE swings ~0.149 with definition; robustness uncorrelated w/ size); tabular-QA calibration `hf.co/papers/2604.12491` (recalibration is a *method* gain, not intrinsic). Q1 Claude anchor (baseline): Dunning-Kruger `2603.09985` — Claude Haiku 4.5 best-calibrated (ECE 0.122). **Verdict: NOT a reduction** — Q2 direction is "overconfidence persists," all Q2 non-Claude; fails (2),(3).
- **2.14 recency bias — no new Q2 result.** Guardrails not evaluable.
- **2.15 base-rate neglect — no new Q2 result** (CogniBench/KalshiBench pre-window). Not evaluable.
- **2.17 algorithm appreciation — new (single-source, human-subjects):** "AI, Take the Wheel" `2605.28255` — aversion-under-conflict persists. **Verdict: NOT a reduction**; fails (2),(3).
- **2.19 look-ahead bias — new (indirect):** FINSABER v6 controls look-ahead/survivorship/data-snooping; LLM advantage decays under unbiased longer-horizon eval (consistent with alpha decay). **Verdict: reduction NOT supported; sustained** (unfavorable direction).
- **2.20 textbook-rational penalty — no new Q2 result** (bubble sims pre-window). Not evaluable.

| Disadv. | New Q2 result? | Direction | Guardrails cleared for *reduction*? |
|---|---|---|---|
| 2.3 hallucination | Yes (AA-Omniscience Claude flat; ClinHallu) | Flat/steady (Claude); still-high | **N** — stability not reduction; fails (1),(3) |
| 2.4 narrative over-fit | Yes (TFRBench) | Structured reasoning helps (indirect) | **N** — fails (1),(2),(3) |
| 2.7 regime maladaptation | Yes (FINSABER v6; AMA) | Unfavorable — reaffirmed | **N** — agree on *persistence* |
| 2.10 prompt injection | No (latest Q1) | Declining-but-high (Q1) | **N/A** — no new Q2 data |
| 2.13 miscalibration | Yes (QuantSight; 2605.02038; 2604.12491) | Overconfidence persists (non-Claude) | **N** — fails (2),(3) |
| 2.14 recency bias | No | — | **N/A** |
| 2.15 base-rate neglect | No | — | **N/A** |
| 2.17 algorithm appreciation | Yes (AI Take the Wheel) | Aversion persists | **N** — fails (2),(3) |
| 2.19 look-ahead bias | Yes (indirect, FINSABER v6) | Alpha decays w/o bias (unfavorable) | **N** — single in-window source |
| 2.20 textbook-rational penalty | No | — | **N/A** |

**Bottom line: No Tier-2 disadvantage cleared all four §5.5 guardrails for a reduction in Q2-2026.** Where fresh guardrail-passing evidence exists (2.7, 2.19) it *reaffirms* the disadvantage. The only favorable Claude-family signals (AA-Omniscience hallucination flatness; the Q1 Dunning-Kruger calibration anchor) are single-source and/or prior-quarter and reflect *held-steady* calibration, not measured reduction. **No Tier-2 reduction confirmation recorded this quarter.**

## Section 4 — Market saturation and AI-driven market structure

- **Jun 30 — BoE Deputy Governor Breeden, "Agents of change" (ECB Sintra).** Most direct central-bank statement on AI homogenization to date, mapping onto 2.8: AI agents "trained in similar ways on similar data… could move as one, selling into the same decline… with a synchronised speed and scale no crowd of traders could match" — a **herding** problem; BoE considering **market-wide circuit breakers / "kill switches."** ([bankofengland](https://www.bankofengland.co.uk/speech/2026/june/sarah-breeden-panel-at-the-european-central-bank-forum-on-central-banking-2026), [bloomberg](https://www.bloomberg.com/news/articles/2026-06-30/boe-s-breeden-warns-ai-agents-risk-triggering-market-meltdowns))
- **Jun 30 — BlackRock Midyear Outlook** cut EM equities to neutral: geographic diversification no longer reduces concentration when markets tie to the same AI value chain; **top-10 S&P 500 > 40% of index cap.** ([blackrock](https://www.blackrock.com/corporate/insights/blackrock-investment-institute/publications/outlook))
- **Jun 22–26 — SYNCHRONIZED AI/semis selloff (WATCH-ITEM EVENT).** Jun 23 Nasdaq −2.2%, S&P −1.43% (Alphabet worst day >1yr + SpaceX −16% + MS estimate AI borrowing >$500B in 2026); contagion **KOSPI −10%, SK Hynix/Samsung −12%+, Nikkei −3.5%**. A separate Friday session (hot May payrolls) Nasdaq-100 ≈ −5% / S&P −2.6% with defensives *rising* (single-factor unwind). Jun 26 chips fell again (Micron −5%+, SMIC −7%). Jun 30 BofA Bubble Risk Indicator 0.91 (PHLX Semis). **Attribution: "consistent-with-but-NOT-confirmed AI-driven"** — fundamental/macro triggers, AI-crowding transmission; a drawdown *within* an up-quarter (chips had best quarter ever, +~$2T), not a Q1-style washout. Same evidentiary class as the March pod-shop drawdown. ([guardian](https://www.theguardian.com/business/2026/jun/23/ai-stocks-sell-off-us-markets), [reuters](https://www.reuters.com/legal/transactional/tech-selloff-stirs-bubble-fears-us-stock-market-2026-06-30))
- **May 25 — IOSCO final "Supervisory Toolkit for AI Use in Capital Markets" (FR/02/2026)** — full lifecycle incl. emerging **agentic AI**; investor protection, market integrity, financial stability; third-party/outsourcing (model-provider concentration). Non-binding. ([iosco](https://www.iosco.org/library/pubdocs/pdf/IOSCOPD823.pdf))
- **May 13 — provider concentration SHIFTS:** Ramp data — **Anthropic overtakes OpenAI in enterprise spend (34.4% vs 32.3%)**, first time. A genuine duopoly marginally *reduces single-model homogenization* but substrate concentration stays high (OpenAI+Anthropic took ~14% of all global VC in 2025). ([axios](https://www.axios.com/2026/05/13/anthropic-openai-workplace-ai-adoption))
- **Baseline updates:** Mag7 ~**32.7–33.8%** of S&P (flat-to-slightly-down vs ~34%; Mag7 *underperformed* index H1 2026). Hyperscaler 2026 AI-capex consensus firmed to **~$650B** (top of/above April baseline; 2027 est >$1.1T). AI-share-of-volume / retail adoption: **no new authoritative estimate** supersedes the ~89% / 62% baseline — treat as unchanged.

**KEY DELTAS:**
- **Synchronized-AI event (Q6): YES** — one qualifying watch-item event (Jun 22–26), attribution *consistent-with-but-not-confirmed*; log as watch item reinforcing 2.8, not a confirmed AI-driven event.
- **Homogenization (2.8): WORSENING on balance** (Breeden herding/kill-switch; BlackRock top-10 >40%; capex ~$650B; June selloff demonstrated the correlated-unwind mechanism) with two *marginal* improving counter-signals — model-provider **duopoly** (Anthropic vs OpenAI) and **rising within-theme dispersion** (defensives rose while AI fell; "narrative dominance → fundamental discrimination").
- **Edge accessibility (Q5): mild NEGATIVE drift** — crowding is now the consensus fragility; the one widening signal is rising intra-theme dispersion (rewards selective/long-short positioning).

## Section 5 — Adversarial content and manipulation risks

Maps to 2.10. Workflow threat model: web-fetched reports/filings/news consumed by an LLM → HTML/source-embedded indirect prompt injection (IPI) and RAG/corpus poisoning are the primary non-architectural surfaces.

- **May 28 — Anthropic Opus 4.8 system card (most load-bearing Q2 item for 2.10).** Adaptive internal red-team, four agentic surfaces, pre-/post-safeguard. **Claude-specific:** browser **31.5% pre → 0.5% with safeguards**; Sonnet 4.6 browser **50.7%** pre; coding (thinking on) **7.03% → 2.09%** (0% in a constrained setup); Gray Swan Opus 4.7 ~0.1% single → ~5–6% @100 adaptive. Post-safeguard browser 0.5% is *below* the foundation's recorded ~1% Opus-tier figure (which traced to Nov-2025 Opus 4.5). BUT raw-model susceptibility essentially unchanged and Sonnet-tier remains highly exploitable. Anthropic remains the only frontier lab publishing comparable numbers. ([venturebeat](https://venturebeat.com/security/anthropic-browser-agent-hijacked-31-percent-before-safeguards-engaged), [winbuzzer](https://winbuzzer.com/2026/06/02/anthropic-reveals-315-browser-agent-hijack-rate-xcxwbn/)) The **Int'l AI Safety Report 2026** and Q2 press *reaffirm* (not lower) the foundation's constants — **17.8% single-attempt GUI without safeguards** and **~50% bypass @10 attempts** on best-defended frontier. ([internationalaisafetyreport.org](https://internationalaisafetyreport.org/publication/international-ai-safety-report-2026))
- **Jun 13 — AutoDojo: Adaptive Attacks Expose Superficial Defenses** — `hf.co/papers/2606.15057`. Static IPI evaluations **underestimate** vulnerability (ignore malicious-prompt optimization); prompt-, detection-, system-level defenses all degrade under adaptive attack; "action-open" tasks have structural limits. **Measurement-integrity delta pushing 2.10 UP** — the tidy 17.8%/~1%/50%@10 constants are likely optimistic vs an optimizing adversary. Directly relevant (our workflow is action-open over fetched docs). Architecturally general.
- **Apr — Agent Safety Blind Spot** (`arxiv.org/abs/2604.10577`): underspecified *benign* instructions expose CUA vulnerabilities — the exact class of our broad "analyze this filing" instructions over untrusted content. **Parallax** (`arxiv.org/abs/2604.12986`): argues reasoning/acting separation is a structural mitigation — think-and-act agents (our mode) are the exposed config.
- **Apr 8 — MLLM Smuggling** (`hf.co/papers/2604.06950`): harmful content in AI-unreadable visual formats, **>90% ASR** on multimodal models. **NEW attack class** *only if* the routine ingests screenshots/chart images; text-only fetch not exposed — **flag before enabling any image/screenshot ingestion.**
- **Jun 5 — Adversarial AI-Generated Social Bot Content** (`hf.co/papers/2606.07219`): defense-side detection of AI-generated bot content (social bots, not filings) — mildly reducing, indirect.
- **Financial-manipulation-specific evidence: NONE new in Q2.** No in-window paper/incident targeting adversarial/AI-generated content embedded in *financial documents* to manipulate downstream AI analysis (MIRAGE `2512.08289` / TRAP `2512.23128` are Dec-2026, out of window). Residual risk stays theoretical, routed through generic RAG-poisoning.

**KEY DELTAS:** 2.10 moves **slightly DOWN on the defended Opus frontier** (0.5% post-safeguard, Claude-measured) but is **unchanged-to-worse raw/mid-tier** (31.5%/50.7% pre-safeguard) — safeguards, not the base model, carry all protection. **Measurement-integrity delta (AutoDojo) pushes 2.10 UP** (defended rates are optimistic). Net: 2.10 narrowing where safeguards on + Opus-tier used, unchanged where not; **not closed.** The favorable Claude number is single-vendor / single-quarter (fails §5.5 sustained + ≥3-source). Recommendation: keep consume-path on Opus-tier with safeguards; treat all fetched HTML/filings/news as untrusted-by-default; do not enable image/screenshot ingestion without re-evaluating the smuggling class.

## Section 6 — Regulatory developments affecting AI in financial decision-making

- **Jun 10 — FSB "Sound Practices for Responsible Adoption of AI" (consultation, deadline Jul 22 2026).** 12 sound practices across the AI lifecycle, explicitly covering GenAI and **agentic AI**; soft-law, institution/supervisor-facing, not binding. ([fsb.org](https://www.fsb.org/2026/06/sound-practices-for-responsible-adoption-of-artificial-intelligence-ai-consultation-report/))
- **Jun 30 — compliance-press synthesis (Husch Blackwell / Risk Management Magazine):** through-quarter US posture — no new AI-specific statute; SEC/FINRA enforcement under **existing law**; "governance failures, not technology failures." ([rmmagazine](https://www.rmmagazine.com/articles/article/2026/06/30/how-regulatory-enforcement-is-shaping-ai-compliance-on-wall-street))
- **May 25 — IOSCO final Supervisory Toolkit** (see Section 4): non-binding, non-prescriptive; full lifecycle incl. agentic AI; risk-proportionality mapping.
- **May 19 — EU AI Act draft Commission Guidelines on high-risk (Annex III) + consultation to Jun 23.** High-risk financial uses = credit scoring, insurance underwriting, AML, fraud; **general securities trading / robo-advice NOT enumerated as Annex III high-risk.** 2 Aug 2026 obligations deadline lands next quarter. ([digital-strategy.ec.europa.eu](https://digital-strategy.ec.europa.eu/en/library/draft-commission-guidelines-classification-high-risk-ai-systems))
- **May 19 — US Treasury/FSOC AI Innovation Series concluded** — pro-adoption, "gradual but robust," no new binding constraints. ([treasury](https://home.treasury.gov/news/press-releases/sb0540))
- **Q2 — SEC "innovation exemption"/AI sandbox (Atkins)** — time-limited cabined testing concept for broker-dealers/advisers; policy direction, not a rule. ([fedscoop](https://fedscoop.com/sec-ai-sandboxes-paul-atkins/))
- **Apr — FCA (UK) AI Live Testing Cohort 2** (8 firms incl. Barclays/Lloyds/UBS; targeted investment support, agentic payments) and **BoE live AI market-behavior simulations** (herding focus) — supervisory/research programs, not rules; UK-only.
- **Backdrop carried into Q2:** FINRA 2026 Annual Oversight Report (Dec 2025) — for AI agents that act/transact, recommends narrow scope, least-privilege, action audit trails, **explicit human checkpoints before execution**. SEC (Atkins) principles-based, technology-neutral, "not prepared to issue AI-specific regulations." CFTC technology-neutral (no new obligations).

**KEY DELTAS — impact on this workflow (AI-decides / human-executes, US retail, IBKR equity/ETF/options):**
- **No new binding US obligation** landed in Q2 that constrains/prohibits the workflow; operative regime is existing anti-fraud / supervision / books-and-records law.
- **The design is affirmatively favored:** FINRA's agentic-AI guidance recommends an **explicit human checkpoint before execution** — which this workflow already satisfies. De-risking alignment, not a constraint.
- **AI-washing enforcement** targets *misrepresentation to clients*, not use — a single private retail account with no external clients/marketing has effectively nil exposure.
- **EU AI Act** binds EU providers/deployers; Annex III excludes US retail equity/options trading — out of scope geographically and by use-case.
- IOSCO/FSB are supervisor/institution-facing, non-binding — forward signal that agentic-AI audit trails + human-oversight expectations are hardening, which the workflow already embodies.

---

# PART 2 — Verification answers and per-strategy effects

Per-strategy foundation citation graph (parsed from `strategy/` mechanism slices + `08_pre_mortems.md`), used for the "strategies affected" column:
- **A** (catalyst, long-equity): exploits 1.1, 1.4, 1.10; compensates 2.4, 2.13, 2.15, 2.17, 2.19.
- **B** (post-event mispricing): exploits 1.1, 1.4; structurally exposed to 2.20 (router HIGH-VIX entry exclusion as partial mitigation; does NOT compensate 2.20 per rev 2 retraction).
- **C** (defined-risk options on catalysts): exploits 1.1 (1.4 as technique); compensates 2.18 (defined-risk caps loss), 2.1; numerical work delegated (2.11).
- **D** (long-horizon concentrated equity): exploits 1.1, 1.4, 1.10; compensates 2.23 (LTCG).
- **E** (market-neutral pairs): exploits 1.1, 1.4, 1.10; compensates 2.7, 2.20.

**Transferability filter applied to all non-Claude evidence (Sections 2, 3, 5):** a finding triggers per-strategy foundation-change assessment only if (a) replicated on a Claude model, (b) architecturally general (documented property of autoregressive/RLHF LLMs broadly), or (c) evidence from an Anthropic-family model. Non-Claude findings lacking transferability are logged as watch items only.

## Verification questions

### Q1 — Has any AI capability in Part 1 materially changed? (Tier 1 structural / Tier 2 measurement)
**Answer: YES — a version transition (Opus 4.7 → 4.8, plus a "5" generation), which routes to the version-change protocol, NOT to a foundation-change assessment.**
- **Evidence:** Opus 4.8 (May 28), Sonnet 5 (Jun 30), Fable 5 / Mythos 5 (Jun 9). In-use 4.7 remains Active/undeprecated (EOL ≥ Apr 16 2027) — no forced migration.
- **Transferability:** Anthropic-family (direct). But per `AI_Trading_Foundation.md` Part 4 §Version-change protocol (and the rev-3 note that dropped the old Q8 "version change" from triggering refresh), **a new Claude version does NOT trigger early refresh or per-strategy assessment.** Required handling: (i) update the in-use-version field guidance; (ii) flip Tier 2 numerical claims to "version-pending replication"; (iii) let the quarterly delta pick up version-specific research as it emerges.
- **Tier:** version transition affects the *magnitudes* (Tier 2) of every measured disadvantage → all flip to version-pending; Tier 1 items unaffected.
- **The 4.8 vendor calibration/honesty claim** (~4× less likely to let its own code flaws pass; flags uncertainty more) bears on 2.13 and edges 1.3/1.7 — but is **single-source vendor-claimed, independently un-replicated, and contradicted in part by 4.8's GPQA/Arena regressions.** It does **not** clear §5.5 Goodhart guardrails → not a confirmed capability improvement; logged as version-pending watch item.
- **Strategies affected / branch:** none directly — **no foundation-change assessment.** Action: version-pending flip (all strategies continue on existing foundation) + update in-use-version field. **Self-applies / routes to A3 (no participant): the in-use-version field update is applied by A3 under its existing `AI_Trading_Foundation.md` write authority (per the protocol's step 2 — a field update, not a refresh), with no human sign-off. Separately, any materially-changed foundation edge/disadvantage surfaced by this delta is emitted as an `events.strategy_candidates` row (adoption → SL1) or an SL4 retirement signal and flows autonomously through the Strategy Arsenal Lifecycle — the old "recommendation for A3/participant" dead-end is superseded by scout-and-act-within-rails (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive).**

### Q2 — Has any AI disadvantage been reduced or eliminated by capability changes?
**Answer: NO confirmed reduction. → No constraint-relaxation review triggered.**
- **Evidence:** Section 3a — **no Tier-2 disadvantage cleared all four §5.5 Goodhart guardrails.** Candidate favorable signals and why each fails:
  - *2.10 prompt injection* — defended-Opus-frontier post-safeguard 0.5% (Claude-measured, below the recorded ~1%). Fails **(1)** ≥3 sources and **(3)** sustained ≥2 quarters (single-vendor, single-quarter); AutoDojo (`2606.15057`) shows defended rates are optimistic. Raw/mid-tier unchanged-to-worse. → PARTIAL-at-most on one tier, guardrails fail → **not confirmed.**
  - *2.13 miscalibration* — Opus 4.8 vendor honesty claim + AA-Omniscience "steady" — vendor/single-source, un-replicated, *stability not reduction*. Fails (1),(2),(3).
  - *2.3 hallucination* — AA-Omniscience Claude flat — stability, single-source. Fails (1),(3).
- **Transferability:** the only Claude-measured favorable point (2.10 defended frontier) is Anthropic-family but fails the *sustained/multi-source* guardrails; all others are non-Claude or vendor-claimed.
- **Strategies affected / branch:** none — **no constraint-relaxation review.** Logged watch items for next cycle: 2.10 defended-frontier trend, 4.8 calibration claim (revisit if a second independent quarter replicates → then re-evaluate against §5.4 thresholds).

### Q3 — Has any new disadvantage emerged that is not listed?
**Answer: YES (highest-priority YES of the quarter). → Triggers per-strategy foundation-change assessment for A, B, C, D, E.**
- **Evidence:** (a) **User-attributed-false-belief sycophancy collapse** — when a false statement is presented as the *user's own belief*, frontier factual accuracy collapses (e.g. DeepSeek R1 >90%→14.4%; sycophancy-induced error 22–94% across 26 frontier models incl. Claude), per Stanford AI Index 2026 / AA-Omniscience and the unified deception taxonomy `hf.co/papers/2604.04788` (which also adds *omission of limitations* and *capability-concealment* as monitored sub-modes). (b) **PhantomBench** `hf.co/papers/2606.11105` — fabricating non-existent entities/concepts rather than abstaining (extends 2.25 with a distinct phantom-entity sub-mode).
- **Why it's new/material for THIS workflow:** the workflow routinely feeds Claude *fed state* — prior-session decisions, ledger/position state, regime state, operator context — as established fact. The user-belief finding says Claude's error-catching **collapses** precisely when a false/stale premise is embedded in that fed context (a stale position, an incorrect prior thesis presented as settled). This **amplifies 2.18** (instruction adherence over capital preservation), **2.25** (reasoning forward on fed state without re-grounding), and **2.3/2.13**. It is not fully captured by any single existing 2.x item.
- **Transferability:** **CLEARS** — asserted as an architectural property of RLHF-trained autoregressive LLMs broadly (filter branch (b)); Claude was in the 26-model panel (branch (a)-adjacent, though not disaggregated). This is a bona-fide transferable finding, not a single-model artifact.
- **Tier:** **Tier 1 (architectural).**
- **Strategies affected:** **ALL (A, B, C, D, E)** — every strategy consumes Claude reasoning over fed context / prior-session conclusions.
- **Branch warranted:** **foundation-change assessment per strategy** (new/architectural disadvantage). *Expected mechanical outcome (for the Q4/orchestrator to determine, not pre-judged here):* likely **(a) Continue** for most, because the workflow already mandates external ground-truth reconciliation per 2.25's operational rule (D2 Step-0 ledger/IBKR reconciliation; fed-state-as-untrusted; three-session adversarial review) — but the assessment should RUN to (i) confirm each strategy's pre-mortem compensation covers the user-belief amplification and (ii) consider adding an explicit "fed-state / prior-thesis is untrusted-by-default; re-derive, don't accept" instruction as a monitored mitigation. Also recommend the A1 annual sweep add this as a standalone disadvantage (candidate **2.27 — user-attributed-false-belief sycophancy amplification**) and cross-reference PhantomBench under 2.25.

### Q4 — Have any Part 3a questions been resolved by accumulated evidence?
**Answer: NO full resolution; all three 3a postures REINFORCED (no status/Tier change → no assessment).**
- **3a.1 (EV/probability math usable given miscalibration):** reinforced toward "not usable without calibration layer" — DCPO calibration-degeneration (`2603.09117`), metacognitive-RL (`2606.32032`), QuantSightBench (none reaches 90% coverage). Default posture (ordinal tiers) stands.
- **3a.2 (decision-support vs autonomous):** reinforced toward "closer to autonomous / external guardrails required" — every Q2 autonomous live-capital result negative (Alpha Arena equities); the only positive (Bridgewater AIA) is human-supervised and still underperformed human. The split *widened* in favor of decision-support with hard guardrails.
- **3a.3 (long-horizon consistency):** reinforced toward "not without external scaffolding" — FINSABER v6 reaffirms maladaptation; Tenure (`2605.11325`) confirms cross-session memory needs external structure.
- **Transferability:** architectural / reference-class (clears). **Branch:** none — these are confirmations of existing default postures, not resolutions that change Tier/status. Logged; the scaffolding they endorse (immutable templates, external ledger, rule-based gates, adversarial review) should continue to be followed rigorously.

### Q5 — Has market saturation changed in a way that shifts edge accessibility?
**Answer: YES (marginal). → Reinforces 2.8; flagged with Q6 for a homogenization-exposure assessment on A and B (sub-threshold; err-toward-YES).**
- **Evidence:** manager AI adoption near-universal; crowding is now the consensus fragility (Goldman-noted profit-taking; HedgeCo "dependent on AI"). Baseline figures ~unchanged (89% volume, 62% retail, Mag7 ~33%). Capex raised to ~$650B. **Counter-signal:** rising within-theme dispersion (defensives rose while AI fell) rewards selective/long-short positioning; model-provider duopoly (Anthropic overtakes OpenAI) marginally lowers single-model substrate risk.
- **Transferability:** market-structural, model-agnostic (clears — applies regardless of which model the workflow uses).
- **Tier:** 2.8 is Tier 1 existence / Tier 2 magnitude. The shift is **directional/qualitative, NOT a §5.2 material-worsening threshold clear** (no quantified ≥50% magnitude increase; attribution of the concrete event is unconfirmed).
- **Strategies affected:** **A, B** (exploit narrative edges on names in the crowded AI-consensus complex; most exposed to correlated-unwind and edge-commoditization). **E benefits** from rising dispersion (pairs/market-neutral). C/D less directly exposed.
- **Branch:** flag as **YES-reinforced watch item**; combined with Q6, recommend Q4 enqueue a **homogenization-exposure foundation-change assessment for A and B** (err-toward-YES per the default bias; the mechanical §5.2 threshold is not cleared, so the assessment's expected outcome is **Continue** — but running it is the conservative choice). No constraint change absent a threshold-clearing worsening.

### Q6 — Has a synchronized-AI market event occurred in the prior quarter?
**Answer: YES (one qualifying watch-item event), attribution unconfirmed-AI-driven → reinforces 2.8, consistent with the doc's existing treatment of such events.**
- **Evidence:** the June 22–26 global AI/semis selloff (KOSPI −10%, SK Hynix/Samsung −12%+, Nasdaq −2.2%; a separate Friday Nasdaq-100 ≈ −5% with defensives rising). Exhibited the synchronized cross-border single-factor de-risking of a crowded AI complex.
- **Attribution:** **consistent-with-but-NOT-confirmed AI-driven** (fundamental/macro triggers; AI-crowding transmission) — same evidentiary class as the Feb-2026 washout and March pod-shop drawdown already in 2.8.
- **Transferability:** market-structural (clears). **Tier:** 2.8 (Tier 1 existence / Tier 2 magnitude). **Strategies affected:** A, B (as Q5). **Branch:** reinforces 2.8; folded into the Q5 A/B homogenization-exposure assessment recommendation. Not a new structural change to 2.8 (the mechanism is already documented) → no separate terminate-assessment; **watch item + the A/B assessment above.**

### Q7 — Have calibration records confirmed or refuted any edge or disadvantage claim?
**Answer: NO — insufficient own-calibration sample.**
- **Evidence:** the experiment's own record holds ~20 fills, 2 closed decisions, 5 open positions — far below the **30-outcome directional threshold** (edge 1.7) and the minimum-viable-sample constraint (2.21). No category has enough closed outcomes to confirm or refute any edge/disadvantage empirically. External calibration research (Sections 3/3a) reinforces 2.13/2.26 but is not the experiment's *own* calibration record.
- **Branch:** none. Revisit once any tracked category reaches ~30 closed outcomes.

### Q8 — Has new research surfaced specific new failure modes or confirmed edges?
**Answer: YES on new failure modes (overlaps Q3); NO on newly-confirmed edges.**
- **New failure modes:** user-attributed-false-belief sycophancy (`2604.04788` + AA-Omniscience), phantom-entity hallucination (PhantomBench `2606.11105`), omission/capability-concealment sub-modes (`2604.04788`), and the measurement-integrity finding that static injection benchmarks understate real bypass (AutoDojo `2606.15057`). Handled via Q3's assessment trigger; AutoDojo pushes 2.10's *measured* magnitude up (do not treat defended-injection rates as reductions).
- **Disadvantages confirmed (not reduced):** 2.7 (FINSABER v6, Alpha Arena equities), 2.13/2.26 (DCPO, QuantSightBench, metacognitive-RL), 2.24 (Tenure), 2.25 (PhantomBench), 2.19 (FINSABER v6).
- **Edges confirmed: NONE.** No Q2 research affirmatively confirmed a Part 1 edge; the trading reference class (Section 2) stayed negative for autonomous LLM performance, and the narrative-synthesis edges (1.1/1.4/1.10) received no new confirming evidence. Absence-of-confirmation does not remove a Tier 1 edge (edges are audited for architectural change, not research activity), but it is logged.
- **Branch:** covered by Q3 (new disadvantages) + Q5/Q6 (2.8). No additional trigger.

## Summary of actionable outputs for Q4 (per-YES → assessment map)

| Q | Verdict | Transfer? | Tier | Strategies | Branch warranted |
|---|---|---|---|---|---|
| Q1 version change (Opus 4.8 + "5" gen) | YES | Anthropic-family | T2 magnitudes → version-pending | all | **Version-change protocol** (flip Tier 2 to version-pending; update in-use-version field). NOT an assessment. |
| Q2 disadvantage reduced? | **NO** | — | — | — | **No constraint-relaxation review.** Watch: 2.10 defended-frontier, 4.8 calibration claim. |
| Q3 new disadvantage (user-belief sycophancy + phantom-entity) | **YES** | Architectural generality ✔ | **T1** | **A, B, C, D, E** | **Foundation-change assessment per strategy** (new architectural disadvantage; candidate 2.27 + 2.25 extension). |
| Q4 3a resolved? | NO (reinforced) | Architectural/reference-class | — | all | None — postures reinforced, not resolved. |
| Q5 edge accessibility shift | YES (marginal) | Market-structural ✔ | 2.8 (T1 exist / T2 mag) | A, B | Homogenization-exposure assessment (err-YES; sub-§5.2-threshold → expected Continue). |
| Q6 synchronized-AI event | YES (watch, unconfirmed) | Market-structural ✔ | 2.8 | A, B | Reinforces 2.8; folded into Q5 A/B assessment. |
| Q7 calibration records | NO (n≈2 closed) | — | — | — | None; revisit at ~30 outcomes/category. |
| Q8 new failure modes / edges | YES modes / NO edges | Architectural ✔ | T1 | all | Covered by Q3; AutoDojo → 2.10 measured magnitude up. |
| **Arsenal / adoption** (SISA branch, rev 2026-07-10) | scout | — | — | new | **strategy-adoption:** foundation deltas that reveal a new exploitable edge or an under-covered regime cell are written as `events.strategy_candidates` rows feeding **SL1**; qualified candidates graduate AUTONOMOUSLY (adversarial pre-mortem → SHADOW → PAPER → PROBE → 30-trade gate). Not a participant recommendation. |
| **Arsenal / retirement** (SISA branch, rev 2026-07-10) | scout | — | — | adopted | **strategy-retirement:** sustained edge-decay / redundancy / dominated-by-newcomer signals feed **SL4** (monthly, remove-only, default-KEEP; affirmative AR RETIRE required, roster floor N≥2). Mechanical kill triggers are unchanged. |

**Net for Q4:** enqueue per-strategy foundation-change assessment for **A, B, C, D, E** (Q3 new architectural disadvantage), plus a homogenization-exposure assessment for **A, B** (Q5/Q6). **No constraint-relaxation review** (Q2 = no confirmed reduction). Apply the **version-change protocol** (Tier-2 → version-pending; in-use-version field update) for the Opus 4.8 transition. Candidate annual-sweep (A1) additions: new disadvantage **2.27 (user-attributed-false-belief sycophancy amplification)** and a **2.25 extension** for phantom-entity hallucination; log AutoDojo as evidence that 2.10's defended-rate benchmarks are optimistic.

# AI Trading Foundation

**Document date:** 2026-07-10 (revision 5)
**Review cadence (rev 3):** Quarterly delta (Q3 task in Claude_Task_Plan.md) + Annual full re-derivation (A1 task) — see Part 4 for protocol.
**Invalidation consequence:** Any material change to this document triggers per-strategy foundation-change assessment per the experiment parameters document, before any strategy's next trade is executed. The assessment may produce one of three outcomes per strategy: continue, terminate, or constraint-relaxation review (rev 3 added). All three outcomes are determined by mechanical criteria applied by the orchestrator session — no orchestrator discretion (rev 4).

**Revision history:**
- 2026-04-22 (rev 1): Initial document, titled `AI_Edges_Assessment.md`.
- 2026-04-23 (rev 2): M2 monthly AI capabilities review integrated. Updates to 2.3, 2.8, 2.10, 2.13, 2.24. Added 2.25 (agentic epistemic hallucination) and 2.26 (RL-post-training decision-token overconfidence). Partial resolutions logged for 3a.1, 3a.2, 3a.3. Per M2, per-strategy foundation-change assessment warranted for A, B, C, D, E before any first trade.
- 2026-04-25 (rev 3): **Document renamed** from `AI_Edges_Assessment.md` to `AI_Trading_Foundation.md` — the name now reflects the document's actual scope (edges + disadvantages + market-structural context) rather than implying edges are the primary content. **Tier 1 / Tier 2 framework introduced** for items in Parts 1 and 2 (see "Tier framework" below). **Cadence changed** from monthly delta to quarterly delta + annual full re-derivation. **Part 4 verification protocol replaced** to reflect the new cadence and to specify the version-change protocol (model upgrades do not trigger early refresh; they flip Tier 2 numerical claims to "version-pending replication" status). **Foundation-change assessment branches expanded** to include constraint-relaxation review (see Experiment_Parameters.md).
- 2026-04-25 (rev 4): **Mechanical-criteria framework added** for foundation-change assessment outcomes — orchestrator session applies explicit rules without discretion. **Benchmark-inference protocol added** — Tier 2 disadvantages can be inferred as reduced from benchmark-result improvements without requiring an explicit "deficiency X is cured" research paper, using a documented benchmark-to-disadvantage mapping with quantitative thresholds. **Goodhart guardrails added** — benchmark inference requires either Claude-family replication or architectural-generality, plus minimum-evidence thresholds (≥3 independent sources or sustained improvement across multiple benchmark generations).
- 2026-07-10 (rev 5): **Out-of-table / undecidable-case routing changed** (Strategy Arsenal autonomy conversion, owner directive). Cases the mechanical foundation-change criteria (§5) cannot deterministically resolve — including constraints not in the §5.6 relaxation lookup and the §5.7 "Out-of-table flags" — no longer dead-end at "participant resolution at the next annual review." They now route to an autonomous `out-of-table-resolution` review (conservative default: HOLD the strategy/constraint at its current state/value; affirmative reviewer case required to change anything), consistent with the fully autonomous SISA lifecycle. This is a governance/routing change only: it alters no edge (Part 1) or disadvantage (Part 2), so per the Invalidation-consequence clause it does NOT itself trigger a per-strategy foundation-change assessment. The 3b.3 posture (context-aware AI kill/spare judgment under drawdown remains a research question, not a deployed capability) is UNCHANGED — see the scoping note added at 3b.3.

---

## Sourcing, self-reference, and scope (read before using this document)

This document is written by Claude, about Claude's capabilities and limitations in a trading context, drawing primarily on AI-synthesized summaries of external research. Three limitations on the document's epistemic status should be held in mind at all times when using it:

**The empirical claims are AI-synthesized, not directly verified.** Specific numbers in this document — market penetration percentages, bias magnitudes, historical event data, fund performance comparisons — trace to AI deep-research reports rather than primary academic or regulatory sources. These are the best inputs available at retail scale. They are treated as working assumptions rather than established facts. The monthly review cadence exists to re-verify against current evidence rather than accept the numbers as permanent truth.

**The document is self-referential.** Every claim about AI bias is being stated by an AI subject to those same biases. Claims about AI's optimism bias may themselves be understated due to optimism bias. Claims about AI's narrative over-fit may themselves be coherent narratives that don't fully map to reality. This is not an argument to dismiss the document — it is an argument to treat it as a starting framework that reality will test, not as a validated description of ground truth.

**The document is scoped to trading, not to all AI applications.** Disadvantages like execution latency and absence of real-time monitoring only apply because the workflow is trading. Edges are framed for their relevance to capital allocation decisions. This document does not attempt to be a general assessment of AI capabilities — it is specifically a trading-context assessment.

**The document does not apply human-trading research to this workflow.** Research on retail discretionary trading (SPIVA, Barber-Odean, Dalbar) measures human psychology failures: overtrading, loss aversion, overconfidence, emotional timing errors. These mechanisms do not operate on this workflow because the human is not making trading decisions. Research on institutional allocator behavior (forbearance patterns, redemption timelines) measures human allocators under career pressure — also not our situation. Where this document references external research, it is either (a) mathematical properties of markets and statistics that apply regardless of decision-maker, (b) AI-specific research directly about our entity, or (c) market-structural findings that describe the environment we operate in. Human-psychology and human-institutional research has been excluded as not applicable.

Downstream artifacts (strategy documents, experiment parameters, mistake catalog) should be built understanding these limitations.

---

## Tier framework (rev 3)

Items in Part 1 (edges) and Part 2 (disadvantages) are classified into two tiers reflecting their underlying nature and their treatment under the quarterly/annual review cadence.

**Tier 1 — Architectural / structural items.** Claims about model architecture, training methodology, mathematical/statistical fact, structural workflow features, or universal properties of foundation models. Tier 1 items are *durable* — they don't get auto-removed by absence of recent research, because the underlying property isn't research-active in the literature it generates papers on. Removing a Tier 1 item requires affirmative evidence of architectural change (e.g., "autoregressive LLMs now have internal arithmetic units" — which would be major capability news, not silence).

Examples of Tier 1 reasoning: 2.6 (no access to private information) is a structural fact about the workflow; 2.11 (numerical precision failures) traces to autoregressive models lacking internal arithmetic units; 2.21 (minimum viable sample size) is a mathematical/statistical fact; 2.5 (training cutoff) is universal across foundation models.

**Tier 2 — Empirical / measured items.** Specific numbers, benchmark results, magnitude estimates, or capability claims subject to empirical refinement. Tier 2 items are subject to *fade review*: if a specific Tier 2 numerical claim is absent from recent research over a sustained window (default: 2 years), the claim is treated as suspect — flagged for fade review at the next annual A1 sweep. Replaced with current evidence, marked as updated, or removed if no replacement is found and no contradicting evidence exists.

Examples of Tier 2 reasoning: 2.4's "~30% reduction from counter-argument" is an empirical magnitude; 2.13's "80% CIs hit ~69%" is a benchmark result; 2.14's "~10× recency weighting" is a measurement; 2.15's "~85% Bayesian error rate" is an empirical finding. The underlying *existence* of narrative over-fit, miscalibration, recency bias, and base-rate neglect is Tier 1 (architectural/empirical-but-stable) — only the specific magnitudes are Tier 2.

**Tier classification on each item.** Section headers in Part 1 and Part 2 are annotated with `[Tier 1]` or `[Tier 2]` indicating the applicable tier. Items where the *existence* is Tier 1 but specific *magnitudes* are Tier 2 (e.g., 2.13, 2.19) are tagged `[Tier 1 existence / Tier 2 magnitudes]` and the magnitude-specific text is the part subject to fade review.

**Why this matters operationally.** Under the rev 3 cadence, the annual A1 sweep does Tier 2 fade review against last-2-years primary sources. Items that fail fade review get loosened (specific magnitudes treated as version-pending), removed, or replaced. Tier 1 items are not subject to fade review — they're audited only for whether affirmative architectural-change evidence has emerged. This is the asymmetric treatment the empirical-vs-architectural distinction motivates.

---

## Purpose

This document is the foundation for whatever trading strategies are built on top of it. It defines the specific edges AI has, the specific disadvantages AI has, and the market-structural context that determines which edges remain accessible versus already commoditized, within the AI-decides / human-executes workflow.

Each strategy derived from this document must have every rule trace to one of three sources: (a) exploiting an edge listed here, (b) compensating for a disadvantage listed here, or (c) handling a workflow or finance constraint that holds regardless of model capability. Rules that trace to none of these are dead weight and should be deleted.

Ground truth changes. Model capabilities shift. Commoditization eats analytical advantages. Market structure homogenizes as more capital flows through AI-assisted workflows. When any claim here becomes incorrect, strategies built on top of it must be reviewed per the per-strategy foundation-change assessment in the experiment parameters document.

---

## Preamble: Baseline Context as of April 2026

Three findings shape this document's posture. All three are drawn from AI-relevant research or market-structural facts.

**Market saturation is near-total.** By late 2025, AI-driven systems handled an estimated 89% of global trading volume, 91% of investment managers used or planned to use AI in research, and 62% of US retail investors used AI tools to inform investment decisions. Basic capabilities — earnings call summarization, sentiment extraction, document parsing, financial news synthesis — are table stakes. Any analytical edge that was valuable in 2023-2024 because AI could do it is now commoditized because everyone's AI can do it.

**The autonomous-AI trading baseline is unfavorable.** This is the directly applicable reference population for this workflow. Bridgewater's AIA Labs autonomous-AI macro fund returned roughly 11% in 2025 against Pure Alpha II's ~33% (same firm, same year, human-discretionary with AI research support). In live-capital LLM trading arenas, most frontier models operated at a net loss over 30-day evaluation windows. The FINSABER backtesting framework found that autonomous LLM-based investing strategies systematically underperformed classical baselines across long-horizon evaluations with proper survivorship and look-ahead bias corrections.

This workflow — AI decides, human conducts pure execution — is closer to autonomous than to decision-support, and therefore closer to the underperforming reference population than to the outperforming one. The bet is that specific bias-compensation structures (adversarial multi-session review, classical-method delegation, rigid kill criteria, hard capital preservation overrides) can move this workflow's performance meaningfully above the autonomous-AI baseline.

**Homogenization risk is material.** As more capital runs through a concentrated set of foundation models, independent AI agents reach correlated conclusions from the same inputs. The February 2026 software sector washout (IGV -24% in Q1 2026, steeper than dot-com or 2008) was exacerbated by synchronized AI-driven positioning. AI-consensus trades become dangerous because everyone is crowded into them through the same inference path; liquidity vanishes synchronously when models flip.

Interim performance expectations are modest. The deliverable during this phase is infrastructure — process, calibration data, mistake catalog — designed to transfer forward when better models arrive.

**On what actually transfers forward.** The infrastructure-as-payoff argument rests on transfer, but not everything transfers cleanly. Process, documentation structure, workflow artifacts, and mistake-category taxonomies transfer well. Model-specific numerical calibration (observed hit rates, specific bias magnitudes, specific error patterns) does not transfer — a successor model must re-calibrate from its own data. The mistake catalog is maintained as tagged historical record ("Claude 4.7 exhibited this pattern in this context") rather than as predictions about successor model behavior. This lets successor models verify whether they share prior-model tendencies rather than inherit assumptions about them.

---

## Workflow Assumption

All claims below assume: Claude is the sole decision-maker and produces every recommendation; Claude crafts each order as a pending IBKR instruction through the connector (Operating_Protocols.md §11) and the human's only execution action is confirming it — a tap surfaced by IBKR's own order notification (a manual-entry `[Claude] Confirm order` calendar event only for a genuinely non-craftable order, per the 2026-07-09 calendar-scope narrowing), plus funding deposits; the human performs no independent analysis, no discretionary overrides, and checks the account once per trading day after market close. The human also has no edge-generating private information — they cannot attend industry conferences, do not have a professional network in relevant sectors, and will not be gathering real-world observations that AI couldn't retrieve through public sources.

Rule-based algorithmic trading via IBKR's API is feasible for individuals but is not in scope. The edges catalogued here are specifically the edges of LLM-based analytical decision-making, which is distinct from rule-based algorithmic execution.

---

## Part 1: Confirmed AI Edges

Each edge is defined by its operational consequence, not abstract capability. An edge that does not convert into a rule or workflow is not useful for strategy design.

### 1.1 Narrative synthesis across large unstructured corpora [Tier 1]

AI can hold hundreds of pages of transcripts, filings, research reports, and news in working memory simultaneously and synthesize across them. The edge is real but narrower than first impressions suggest. Basic text parsing and sentiment extraction are commoditized; the residual edge is in deeper synthesis — reconciling tone shifts across multiple earnings calls with language buried in 10-K risk factors and what the sell-side has missed entirely. A human with access to the same AI tools captures most of this; what remains is processing throughput and consistency.

*Operational consequence:* Largest edge on analytical tasks that require cross-document synthesis of narrative content. Smallest on tasks where the edge is quantitative (tabular-data reasoning is a documented weakness — see 2.12).

*Monitoring trigger:* Edge narrows further as source materials become adversarially structured against AI consumers, or as competing market participants adopt multi-agent architectures.

### 1.2 Within-session consistency of process [Tier 1]

AI applies the same methodology at checklist item #14 as at item #1 within a single session. It does not skip steps out of boredom, does not rationalize shortcuts under time pressure, does not have a bad day. A twelve-point framework gets twelve-point treatment every time.

*Important caveat:* Consistency is within-session given identical prompting. Minor semantically-neutral variations in prompts can produce divergent outputs.

*Operational consequence:* Processes that depend on disciplined execution of complex procedures benefit. The edge grows as the process grows more detailed — opposite of human behavior, where elaborate processes produce more shortcuts.

*Monitoring trigger:* Absolute edge; only lost if human discretion is allowed back into the process.

### 1.3 Adversarial counter-argument generation [Tier 1 existence / Tier 2 magnitudes]

When explicitly asked, AI produces the strongest bear case against its own bull thesis with the same analytical rigor as the original. AI has no motive to protect prior recommendations across separate sessions.

*Important caveat:* Explicit counter-argument generation does not eliminate embedded biases in the main analysis. Research shows that even when AI is explicitly prompted to avoid overextrapolation, the bias is only reduced by about 30% — it is hard-wired in the model's weights, not just in the context. Counter-arguments are better than no counter-arguments; they do not make the core analysis unbiased.

*Operational consequence:* Explicit counter-argument steps have real value. Most valuable on high-conviction analyses.

*Monitoring trigger:* None obvious.

### 1.4 Cross-report contradiction surfacing [Tier 1]

Given multiple independent research reports, AI can identify logical contradictions between them. Contradictions mark situations where consensus disagrees with itself — potentially where edges exist.

*Operational consequence:* A research stack has more signal than the sum of its reports. Preserving source diversity matters.

*Monitoring trigger:* Edge narrows if all research inputs reflect the same consensus narrative.

### 1.5 Portfolio-level scenario analysis at routine cost [Tier 1]

AI can produce "if rates +50bp: book P&L = X; if recession: Y; if AI capex collapses: Z" across a full book as routine output.

*Operational caveat:* The probability estimates for each scenario are subject to miscalibration (see 2.13). The scenarios and P&L arithmetic are reliable when delegated to code (see 1.8); the probabilities assigned to each are not.

*Operational consequence:* Hidden correlations surface. Portfolio construction becomes robust to specific scenarios rather than implicitly optimized for the current regime.

*Monitoring trigger:* None for the mechanical capability.

### 1.6 Memory cataloging without cognitive load [Tier 1]

AI can maintain arbitrarily long logs and catalogs without them becoming unwieldy. Every prior decision, outcome, and pattern can be referenced on demand.

*Caveat:* Latent until forced to exist as maintained artifacts that are consulted on every new decision. Capability exists; operational discipline does not exist by default.

*Monitoring trigger:* None intrinsic. Risk is operational neglect.

### 1.7 Self-calibration via systematic tracking [Tier 1 existence / Tier 2 magnitudes]

AI can track the outcome of every prediction, probability estimate, and conviction rating, and report on its own calibration over time.

*Important update:* Existing AI models are demonstrably poorly calibrated. The calibration record will confirm this. The edge isn't that AI is well-calibrated by default — it is that AI will honestly track miscalibration if asked to, which allows empirical adjustment over time.

*Sample size reality:* Directional calibration signal requires approximately 30+ outcomes per category being tracked. Statistical proof of calibration at 95% confidence requires 200+ outcomes per category.

*Monitoring trigger:* Persistent miscalibration after adjustment means the framework needs reconsideration.

### 1.8 Narrative-based hypothesis screening with classical-method delegation [Tier 1]

Given clear narrative criteria, AI can screen large security universes against qualitative filters — "find names where management tone shifted materially between the last two earnings calls," "find situations where recent regulatory filings describe supply chain exposure not yet reflected in analyst estimates."

*Important structural requirement:* Quantitative screens over structured tabular data (rank by P/E, filter by margins, etc.) are a documented weakness — classical gradient-boosted methods and Ridge regression outperform LLMs on tabular financial reasoning. For quantitative work, delegate to classical tools via code execution. AI adds value only in the narrative layer on top.

*Operational consequence:* Systematic screens work for narrative criteria. For quantitative criteria, AI must orchestrate classical methods rather than reason about tabular data directly. This is a hard architectural constraint.

*Monitoring trigger:* Edge depends on data availability and on the AI-plus-code architecture being enforced rather than shortcut.

### 1.9 Zero-cost enforcement of structural rules [Tier 1]

AI mechanically enforces rules without rationalizing exceptions.

*Important caveat:* The flip side is instruction sensitivity — AI will follow a flawed rule into catastrophic territory if the rule is stated (see 2.18). Rules must have capital-preservation constraints baked in as hard-coded overrides, not just analytical procedures.

*Operational consequence:* The gap between rules-as-written and rules-as-executed is minimal — for better or worse.

*Monitoring trigger:* None.

### 1.10 Cross-disciplinary integration in a single pass [Tier 1]

AI integrates macro, regulatory, legal, technical, sector-specific, and company-specific analysis within a single session without the handoff friction humans have switching domains.

*Operational consequence:* Analyses whose edge depends on connecting multiple domains are tractable where they'd require an analyst team for a human. This is where AI most clearly beats an individual participant without institutional resources.

*Monitoring trigger:* None obvious.

---

## Part 2: Confirmed AI Disadvantages

Real, current, empirically-documented limitations. Any strategy built on top of this document must compensate for these.

### 2.1 Execution latency [Tier 1]

The human-conduit workflow imposes hours of round-trip between Claude's decision and order placement. Any edge that decays inside that window is not available.

### 2.2 No real-time monitoring [Tier 1]

Once-per-day observation. Rules requiring intraday reaction, tape reading, or microstructure awareness are unimplementable.

### 2.3 Hallucination and false specificity [Tier 1 existence / Tier 2 magnitudes]

AI produces confidently-stated numbers, citations, and historical analogues that are partially or entirely wrong. Hallucination rates correlate with age of data (older periods hallucinated more) and with firm market cap (small-caps hallucinated more than large-caps).

*M2 2026-04 update:* In tool-using agentic contexts, a distinct failure mode has been characterized: "epistemic hallucination" where the agent's internal belief about portfolio or execution state decouples from ground truth after tool-call events (e.g., phantom-portfolio reasoning after liquidation). See new disadvantage 2.25 for the standalone architectural version of this failure mode. Plain hallucination (this item) covers false outputs about the world; 2.25 covers false beliefs about the agent's own state.

### 2.4 Narrative over-fit [Tier 1 existence / Tier 2 magnitudes]

AI constructs coherent narratives well — including plausible-sounding ones that don't map to reality. Can be wrong in a way that looks right. This is the mechanism by which AI under loss pressure constructs continuation narratives ("this is variance, not decay") even when evidence points to structural failure.

### 2.5 Training data cutoff and knowledge recency [Tier 1]

Training ends at a specific date. Post-cutoff events known only via explicit retrieval. Older financial events have higher hallucination rates than recent ones.

### 2.6 No access to private information [Tier 1]

Public information only. Institutional participants have expert-network calls, conference access, private sell-side conversations, pre-IPO looks. Any edge must come from better processing of public information.

### 2.7 Regime-specific behavioral maladaptation [Tier 1 existence / Tier 2 magnitudes]

Not theoretical — empirically observed. LLMs systematically:

- Trade overly conservatively in bull markets (missing momentum; underperform passive benchmarks)
- Trade overly aggressively in bear markets (failing to detect structural breakdowns; "buying dips" into sustained declines)
- Degrade in sideways markets (no narrative anchor → erratic, high-turnover decisions)

Documented across multiple evaluation frameworks and model families. Not fixable through prompt engineering.

### 2.8 Market-structural homogenization and correlated-execution risk [Tier 1 existence / Tier 2 magnitudes]

As more capital runs through a concentrated set of foundation models, independent AI agents reach correlated conclusions from the same inputs. The February 2026 software sector washout was exacerbated by synchronized AI-driven positioning.

Systemic implications: (a) AI-consensus trades become dangerous because everyone is crowded into them through the same inference path, (b) liquidity vanishes synchronously when models flip, (c) what looks like idiosyncratic analysis can be beta to AI-consensus views.

*M2 2026-04 update — reinforced.* The multi-agent systems taxonomy literature (2026 Q1) explicitly flags systemic risk from correlated AI trading with the Coordination Primacy Hypothesis — that existing regulatory frameworks do not account for emergent coordination effects across independent deployments. BlackRock and Bridgewater March-2026 commentary put 2026 hyperscaler AI-capex at ~$610–650B (up from ~$360–410B in 2025) with Magnificent Seven at 34% of S&P 500 — capital-concentration vector reinforcing the homogenization mechanism. The early-March 2026 multistrategy pod-shop synchronized drawdown (Citadel, Millennium, Point72, Balyasny) is logged as a watch item: primary-source attribution was to macro shock and crowded positioning, not confirmed as AI-driven correlated execution, but consistent with this disadvantage worsening.

### 2.9 Model deprecation and version drift [Tier 1]

Today's model won't be used in six months. Behavioral characteristics, calibration, and capability shift with each version. Specific numerical calibration from one model version does not transfer cleanly to its successor — though process, documentation, and qualitative patterns can.

### 2.10 Prompt injection and source manipulation risk [Tier 1 existence / Tier 2 magnitudes]

Research reports, news, documents consumed by AI can contain instructions or framings designed to manipulate downstream AI reasoning. Risk grows as more online content is AI-aware or adversarially structured.

*M2 2026-04 update — partial reduction for Opus-tier with classifiers; unchanged for Haiku-tier.* Anthropic reports Claude Opus 4.5 browser agent reduced to ~1% attack success rate via RL + classifier deployment. However: the International AI Safety Report 2026 documents 17.8% single-attempt success rate on GUI agents without safeguards and 50% bypass rate at 10 attempts on best-defended frontier models. Haiku-tier Claude models explicitly have zero prompt injection protection per Anthropic disclosure. Net effect: the disadvantage is reduced — not eliminated — and only for Opus-tier deployments with classifier infrastructure enabled. For this workflow (Opus-based decisions; no agent browsing), residual risk is in source-content manipulation of consumed research reports and financial documents, which remains unmitigated at the model level.

### 2.11 Numerical precision failures [Tier 1]

AI computes wrong answers on multi-step arithmetic, percentage conversions, options P&L, and date math. Financial benchmarks show calculation errors at 20-24% of failures even when data extraction and equation formulation were correct. Autoregressive models do not have internal arithmetic units. Compensated by delegating all numerical work to code execution (see 1.8).

### 2.12 Tabular / structured-data reasoning weakness versus classical baselines [Tier 1]

On structured financial tabular data — credit risk, feature-importance analysis, cross-sectional ranking — LLMs underperform classical methods (gradient boosting, Ridge regression). LLM-generated explanations of tabular decisions frequently contradict empirically correct SHAP attributions. On cross-sectional ranking tasks under low signal-to-noise, both standard and "thinking" LLMs are significantly outperformed by Ridge regression.

### 2.13 Probabilistic miscalibration [Tier 1 existence / Tier 2 magnitudes]

Three documented failure modes:

- *Overconfidence in point forecasts.* AI return forecasts persistently exceed both training-context historical averages and realized returns.
- *Overconfidence in confidence intervals.* 80% confidence intervals contain realized outcomes only ~69% of the time. Probability of tail events consistently understated.
- *Asymmetric optimism.* AI weights recent positive returns more heavily than recent negative returns — a structurally embedded optimism bias.

The bias is hard-wired in the model weights. Explicit instructions to "avoid extrapolation" or "reason step-by-step" reduce magnitude by ~30% but do not eliminate it.

*M2 2026-04 update — mechanism identified, variance confirmed.* Research during Q1 2026 (arXiv 2603.06604, 2601.13284) attributes a structural cause to the miscalibration: RL post-training (RLVR, DPO) sharpens decision-token distributions away from calibrated base-model behavior because, in the authors' framing, "there are no calibrated paths to reinforce from the base model." This applies generically to autoregressive LLMs trained with modern post-training pipelines — including the Claude family. Separately, the Dunning-Kruger calibration study (arXiv 2603.09985) measured four models and found Claude Haiku 4.5 best-calibrated (Expected Calibration Error 0.122) with worst model at 0.726 — indicating wide model-to-model variance within the family. No independent Opus 4.7 calibration benchmark was available at M2 review time. Operational consequence: raw LLM probability outputs should not be used as EV inputs without post-hoc calibration, cross-run aggregation, or delegation of the probability-assignment step to classical methods. Default posture in 3a.1 is updated accordingly (see Part 3a).

### 2.14 Systematic recency bias with asymmetric weighting [Tier 1 existence / Tier 2 magnitudes]

AI places mathematical weight on the most recent week's data approximately 10x the weight on the week before. Hard-wired, not removable by prompting. Combined with asymmetric optimism (2.13), produces systematic over-extrapolation of recent positive trends.

### 2.15 Base-rate neglect [Tier 1 existence / Tier 2 magnitudes]

Empirically confirmed at scale. On standard Bayesian base-rate tasks, AI exhibits error rates of ~85%. Failure mode: AI over-weights semantic congruence between a description and a stereotype, under-weighting the statistical prior.

### 2.16 Syntactic-over-semantic pattern matching [Tier 1]

AI outputs are partially driven by the grammatical structure of the prompt, not just its semantic content. A prompt that mimics the structure of a historical crisis report can trigger a crisis prediction even when the numerical content describes a healthy firm. Uniquely LLM-architectural — doesn't apply to classical models or humans.

### 2.17 Algorithm appreciation bias [Tier 1 existence / Tier 2 magnitudes]

On stated-preference tasks, AI correctly identifies human experts as trustworthy. On revealed-preference tasks (given actual historical performance of a human vs. an algorithm, asked to place a bet), AI disproportionately chooses the algorithm — even when the algorithm's historical performance is demonstrably worse. Programmatic bias toward algorithmic authority over empirical performance.

### 2.18 Instruction adherence over capital preservation [Tier 1]

AI executes strategies that result in catastrophic losses in order to adhere to a specified persona or rule. AI has no innate drive toward capital preservation — unless capital preservation is an explicit, hard-coded, high-priority instruction, AI will not privilege it over other instructions. Observed in synthetic-market experiments and in reinforcement-learning hybrid setups (reward function exploitation: AI found degenerate strategies with excellent ratios on paper but catastrophic tail risk).

### 2.19 Look-ahead bias in pre-training data — severe contamination [Tier 1 existence / Tier 2 magnitudes]

Foundation models are trained on corpora that include post-hoc financial commentary, retrospective analyses, and outcomes of historical events. When AI is asked about a historical setup, it may be "remembering" the outcome rather than analyzing the setup. Alpha decay exceeding 15 percentage points between in-sample (pre-cutoff) and out-of-sample (post-cutoff) backtests is attributable to this contamination.

*Critical additional finding — the "Scaling Paradox":* Larger models show this bias worse, not better. More capacity means more rigid memorized priors. Assuming future models will handle this weakness better than current ones is not supported by the research — the opposite trend has been observed.

*Operational consequence:* AI-driven backtesting on historical events is structurally contaminated. Backtest results tell you more about AI's memory of outcomes than about strategy edge. Behavioral instructions to "only use data available at time T" do not remove the contamination because AI cannot actually forget what it knows.

### 2.20 Textbook-rational penalty in behaviorally-irrational markets [Tier 1 existence / Tier 2 magnitudes]

AI does not form or participate in speculative bubbles. In multi-agent simulations, AI traders price assets near calculated fundamental value with tight forecast errors, systematically failing to reproduce emergent bubble formation that characterizes real human markets. In regimes dominated by human-momentum behavior, AI's contrary instinct is a risk: markets can stay irrational longer than an AI's portfolio can maintain margin.

### 2.21 Minimum viable sample size constraint [Tier 1]

Research on statistical inference in trading strategies establishes that the minimum sample size required to validate a given edge is dictated by the relationship between the edge magnitude and per-trade variance, with proportional (fixed-percentage) position sizing expanding the requirement further due to heteroskedasticity.

*Specific empirical findings:*

- To validate a 2% per-trade edge with 95% confidence at moderate variance: approximately 96 trades required.
- At higher variance: 216+ trades required.
- At 99% confidence: 370+ trades required.
- With multiple-testing penalties: sample sizes multiply further.
- The widely-cited "30-trade rule" does not apply to financial returns due to fat tails and non-independence.

*Critical implication for any strategy:* Catalyst-driven strategies at typical frequencies cannot reach statistical proof of edge within reasonable time horizons. Directional signal (approximately 30+ trades) is achievable; statistical proof (200+ trades) typically is not in a 2-3 year window. Strategies must be designed with this limitation acknowledged.

### 2.22 Path dependency and geometric drag under proportional sizing [Tier 1]

Proportional (fixed-percentage) sizing models are mathematically vulnerable to path dependency. When outcomes are not independent — which they are not in financial markets due to regime persistence and autocorrelation — proportional sizing forces the strategy to reduce absolute position sizes during drawdowns, inadvertently impairing the strategy's ability to participate in eventual recoveries.

Additionally, proportional sizing introduces volatility drag: the geometric mean of returns is always less than the arithmetic mean, with the gap proportional to variance. At any fixed-fraction risk, there is a volatility threshold beyond which expected geometric returns turn negative even when arithmetic returns are positive.

*Operational consequence:* Proportional sizing is the standard for gambler's ruin protection, but it is not cost-free. The strategy must be designed understanding that proportional sizing systematically disadvantages recovery from drawdowns and that it carries mathematical drag that compounds over time.

### 2.23 Tax and fee drag on active trading [Tier 1]

Short-term capital gains are taxed as ordinary income, potentially at federal rates up to 37% plus state taxes. For an active strategy generating most profits from trades held under one year, this creates a substantial drag on real returns. Commissions, spread costs, and any workflow-related subscription fees compound this.

*Operational implication:* To achieve breakeven real returns after taxes and inflation, nominal annual returns must typically exceed 5-8%. This is a higher bar than many published "profitable" strategies actually achieve. The strategy must either generate materially positive nominal returns or be restructured around holdings long enough to qualify for long-term capital gains treatment.

### 2.24 Cross-session inconsistency (architectural property with mixed effects) [Tier 1]

Different Claude sessions on the same inputs can reach materially different conclusions. Probability estimates, ratings, and qualitative recommendations differ across sessions.

*Mixed effect:*

- *Disadvantage:* Same strategy can be evaluated differently on different days. Decisions should be robust to reasonable alternative reasoning paths rather than dependent on the specific reasoning of one session.
- *Edge (when deliberately exploited):* Separate sessions with isolated context genuinely produce different reasoning, which makes adversarial multi-session review architecturally meaningful. A session that produces the bull case is genuinely different from a session that produces the bear case, as long as their contexts are separated.

*Operational consequence:* Strategy can use session separation deliberately (for adversarial review) but must not rely on single-session conclusions as definitive.

*M2 2026-04 update — confirmed as architectural.* AlphaForgeBench (arXiv 2602.18481) demonstrates that even temperature=0 deterministic decoding produces completely different trading action sequences across runs on identical market data. This elevates the inconsistency from a sampling-noise phenomenon to an architectural property of LLM-based decision-making on financial inputs. The adversarial-multi-session edge is still usable, but long-horizon strategic consistency cannot be expected from the model alone — it must be scaffolded externally (see updated 3a.3).

### 2.25 Agentic epistemic hallucination / phantom-state reasoning [Tier 1]

Added 2026-04-23 per M2 review. Distinct from generic hallucination (2.3): in tool-using agentic contexts, the agent's internal belief about its own state — portfolio holdings, execution status, recent tool-call outcomes — decouples from ground truth after tool-call events. Documented in TradeTrap (arXiv 2512.02261) as phantom-portfolio reasoning: an LLM trading agent continues to reason about positions after those positions have been liquidated, because its context-window representation of state has not been reconciled against external ground truth.

*Transferability:* Architectural — framed as a property of tool-calling LLM trading agents generally.

*Operational consequence:* Any workflow that uses tool-mediated execution must treat the LLM's internal state representation as unreliable and reconcile against external ground-truth state (e.g., broker statements, ledger files) on every decision. For this workflow's current architecture — human executes in IBKR, ledger maintained externally, Claude consulted per session with explicit portfolio state provided — the risk is partially mitigated by design, but not eliminated: any session that reasons forward without re-grounding in the ledger is exposed to this failure mode.

### 2.26 RL-post-training-induced decision-token overconfidence as a structural property [Tier 1]

Added 2026-04-23 per M2 review. Distinct from generic miscalibration (2.13): the finding is that the specific causal mechanism of modern LLM overconfidence is the post-training pipeline (RLVR, DPO, RLHF) rather than a fixable property of context or prompting. Per arXiv 2601.13284, RL "cannot achieve calibration because there are no calibrated paths to reinforce from the base model." arXiv 2603.06604 documents the same mechanism empirically.

*Transferability:* Architectural generality across autoregressive LLMs trained with modern post-training pipelines. Applies to the Claude family.

*Operational consequence:* Reinforces the 3a.1 default (use ordinal conviction tiers, not explicit probabilities) and makes prompt-engineering approaches to "reduce overconfidence" architecturally unlikely to succeed. Compensation must come from structural design — classical-method delegation of probability assignment, or post-hoc calibration against realized outcomes — not from asking the model to be less confident.

---

## Part 3a: Questions awaiting data (will be resolved by accumulated evidence)

### 3a.1 Whether EV / probability math is usable given miscalibration

The capability to produce explicit probability × payoff math at zero cognitive cost is real. But 2.13 (miscalibration) means the inputs are systematically biased. Whether the output is still useful with empirical adjustments, or whether it should be abandoned entirely in favor of ordinal conviction tiers, is an open question. Calibration tracking (1.7) will eventually resolve this, but the sample size required to reach statistical adjustment (2.21) is likely beyond the time horizon of any single experiment. Default posture: use ordinal tiers until calibration data exists at directional confidence.

*M2 2026-04 update — partial resolution toward "not directly usable without calibration layer."* Q1 2026 evidence (arXiv 2603.06604, 2601.13284) attributes overconfidence to RL post-training as a structural mechanism (see new disadvantage 2.26), and the Dunning-Kruger study (arXiv 2603.09985) documents wide ECE variance across models (best 0.122, worst 0.726). Raw LLM probability outputs should not be treated as usable EV inputs without (i) post-hoc calibration against realized outcomes, (ii) cross-run aggregation, or (iii) delegation of the probability-assignment step to classical methods. Default posture is reinforced: ordinal conviction tiers only until calibration data accumulates.

### 3a.2 Whether the hybrid workflow is more like decision-support or autonomous

Research strongly shows decision-support AI outperforms autonomous AI. The workflow here is closer to autonomous than to the institutional decision-support model. Whether the friction of slow manual execution materially moves the workflow toward the decision-support end is unclear. Default posture: assume closer to autonomous until empirical results suggest otherwise.

*M2 2026-04 update — partial resolution toward "decision-support with hard external guardrails required."* The TradeTrap finding (phantom-portfolio reasoning after liquidation — see new 2.25) and FINRA's 2026 Report treatment of autonomous AI agents as requiring "novel oversight, including tracking actions and restricting system access" both reinforce that autonomous-agent framing requires external non-LLM state reconciliation to be safe. For this workflow, the human-conduit execution layer plus the externally-maintained ledger are the needed ground-truth reconciliation — they should continue to be maintained rigorously, as they are what prevents this workflow from failing in the way autonomous-agent research describes.

### 3a.3 Whether long-horizon strategic consistency holds

Bridgewater's AIA Labs performance suggests AI struggles with long-horizon consistency in macro decision-making. Whether this applies to shorter-horizon strategies is uncertain. Will be clearer with accumulated performance data.

*M2 2026-04 update — partial resolution toward "not without external scaffolding."* AlphaForgeBench (arXiv 2602.18481, deterministic decoding produces different action sequences across runs) and FINSABER (regime-specific maladaptation documented) together argue long-horizon consistency is not an intrinsic property of the model but an emergent property of scaffolding: fixed templates, externally-maintained state, rule-based gates, and cross-session adversarial checks. Operational implication: the Strategy.md architecture (immutable templates, externally tracked ledger, regime router with technical + fundamental cross-check, three-session adversarial reviews) is approximately the scaffolding the research implies is necessary. It should be followed rigorously rather than modified ad-hoc during the experiment.

## Part 3b: Theoretical questions requiring research we cannot do

### 3b.1 Whether explicit reasoning (FinCoT-style prompting) reduces biases in this specific workflow

"Financial Chain-of-Thought" reasoning — forcing explicit articulation of logical dependencies before conclusions — is documented as an improvement in some research. Whether it meaningfully reduces recency bias, miscalibration, or syntactic pattern matching in this specific workflow would require controlled comparison we cannot run. Worth building into prompting structure as a likely-but-unproven improvement.

### 3b.2 Whether multi-session adversarial structure captures the institutional edge

Research points to multi-agent reasoning systems as a durable edge. Such systems are not available at retail scale, but Claude sessions can be structured to simulate role-separation. Whether this captures a meaningful fraction of the multi-agent benefit is not directly testable in this workflow. The separation is architecturally meaningful because of 2.24, but quantifying the benefit requires research infrastructure unavailable here.

### 3b.3 Whether AI judgment on drawdown context can be trusted

Research shows rigid percentage-based kill criteria systematically terminate profitable strategies during normal variance. Context-aware assessment outperforms rigid thresholds when done by human portfolio managers with career skin-in-the-game. Whether AI can provide equivalent context-aware assessment is an open question with asymmetric failure risk — AI biases push specifically toward "continue under loss pressure," which is the worse error direction. Not resolvable within this experiment's data. Default posture: rigid outer bounds are safer; context-aware AI judgment on kill decisions is a research question, not a deployed capability. *(Scoping note, rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive.)* This posture is UNCHANGED and still governs the kill/spare decision under drawdown: only the rigid mechanical outer bounds (drawdown / 30-trade / m2m) may terminate a strategy under loss pressure — no routine may exercise context-aware AI judgment to kill or, more dangerously, to SPARE a strategy a mechanical trigger flagged. The SISA lifecycle's SL4 discretionary-retirement path does not reintroduce the judgment this clause reserves: it is REMOVE-ONLY and default-KEEP (the safe error direction), fires only on objective sustained signals (edge-decay, redundancy, dominated-by-newcomer) on healthy strategies, is floored at N≥2, and can never continue or spare a strategy any mechanical kill trigger flagged.

---

## Part 4: Verification cadence and protocol (rev 3)

The rev 3 verification cadence is two-tier — quarterly delta + annual full re-derivation — replacing rev 1-2's monthly delta. The change reflects two findings: (a) monthly cadence produces diminishing returns once the experiment is steady-state — most months don't surface material changes; (b) cumulative slow drift on Tier 2 numerical claims doesn't reliably show up in any single month's research, requiring an explicit periodic re-survey mechanism.

### Quarterly delta (Q3 task in Claude_Task_Plan.md)

**Cadence:** First trading day of each calendar quarter.

**Scope:** "Prior quarter coverage" — three calendar months of primary-source research (papers, arXiv preprints, company announcements, regulatory filings, reputable news citing primary sources).

**Adversarial framing:** "Look for evidence that contradicts or updates documented edges and disadvantages, not evidence that confirms them."

**Default bias:** YES — err toward flagging change.

**Verification questions (answered explicitly each quarter):**

1. Has any AI capability listed in Part 1 materially changed? (Affects Tier 1 by structural change, or Tier 2 by measurement update.)
2. Has any AI disadvantage in Part 2 been reduced or eliminated by capability changes? (Triggers constraint-relaxation review per Experiment_Parameters.md if reduction is material and the strategy has constraints flowing from the reduced disadvantage.)
3. Has any new disadvantage emerged that is not listed?
4. Have any questions in Part 3a been resolved by accumulated evidence?
5. Has market saturation changed in a way that shifts which edges remain accessible?
6. Has a synchronized-AI market event occurred since last review?
7. Have calibration records confirmed or refuted any edge or disadvantage claim?
8. Has new research surfaced specific new failure modes or confirmed edges?

Per YES: (a) evidence triggering the yes, (b) whether the evidence clears the transferability filter (architectural generality / replication on Claude / Anthropic-family), (c) which Tier the affected item is, (d) strategies affected, (e) which foundation-change-assessment branch is warranted (continue / terminate / constraint-relaxation).

### Annual full re-derivation (A1 task in Claude_Task_Plan.md)

**Cadence:** First trading day of each calendar year, or first trading day of the experiment's anniversary month if year-anchoring isn't operationally clean.

**Scope:** "Last 2 years of primary-source research" — full re-pull, not delta against prior version.

**Differential treatment by Tier:**

- **Tier 1 items (architectural / structural):** audited only for whether affirmative architectural-change evidence has emerged (e.g., "autoregressive LLMs now have internal arithmetic units"). Absence of recent research about a Tier 1 item is *not* evidence that the item is cured — Tier 1 items are durable for reasons orthogonal to research activity. A Tier 1 item is removed only with affirmative evidence of architectural change.
- **Tier 2 items (empirical / measured):** subject to fade review. If a specific Tier 2 numerical claim (specific magnitude, benchmark result, percentage estimate) is absent from last-2-years primary-source research and no contradicting evidence exists, the claim is treated as suspect. Three resolution paths: (i) replace with current evidence if available, (ii) mark as updated with current measurement, (iii) remove if no replacement found. The default is to *keep the item but flag the magnitude as version-pending* if absence is the only signal — removing a Tier 2 item solely on absence-of-recent-research is too aggressive given publication-asymmetry biases (improvements often don't generate papers).

**Adversarial framing same as quarterly.**

**Default bias:** YES on flagging change; NO on removing items absent affirmative evidence.

**Output:** updated `AI_Trading_Foundation.md` with revision-history entry documenting all Tier 2 fade-review outcomes and any Tier 1 architectural-change updates. Triggers per-strategy foundation-change assessment for any items materially changed.

### Version-change protocol (rev 3 added)

**On Claude version change** (deprecation, model upgrade, new family release):

1. **No early refresh fires.** A new Claude version dropping does not trigger a foundation refresh. Research and benchmark results on a new version typically appear 1-3 months after release; refreshing the day a new version drops produces a refresh saying "no version-specific research available yet," which is operationally useless.

2. **Update the in-use-version field at the document head** (rev 3 adds this field — currently: Claude Opus 4.7).

3. **Tier 1 items unaffected.** Architectural / structural items (autoregressive LLMs lack internal arithmetic units; pre-training contains historical outcomes; private-information access is structurally unavailable; etc.) are properties of the model class, not of specific versions. They don't reset on version transitions.

4. **Tier 2 items: mark all numerical claims as "version-pending replication."** The specific magnitudes (30% reduction from counter-argument; 80% CIs hit ~69%; 10× recency weighting; 85% Bayesian error rate; alpha decay > 15pp) were measured on a specific model. They become *suspect-but-unknown* on transition until research replicates on the new version. The right operational response is to flag, not to refresh.

5. **Strategies continue with existing foundation.** Calibration-refinement at the strategy gates (15-trade, 30-trade) does the empirical work the foundation document can't yet do. The pre-mortems' cited Tier 2 numbers stay in force as best-available proxies, with the explicit acknowledgment that they're version-pending.

6. **Quarterly delta picks up version-specific research.** Once papers on the new version start appearing (typically 1-3 months post-release), the quarterly Q-task surfaces them. Material findings trigger appropriate foundation-change-assessment branches.

7. **Annual sweep does the full re-derivation regardless of model timing.** Doesn't care about version transitions; sweeps everything against last-2-years primary sources at its normal cadence.

**Asymmetric-risk acknowledgment.** Newer Claude versions sometimes get *worse* on specific dimensions (Anthropic has occasionally documented capability tradeoffs in release notes). The "version-pending replication" posture correctly hedges this — we don't assume improvement just because the version number went up, and we don't assume degradation either; we assume calibration uncertainty until evidence arrives.

**In-use Claude version (rev 3 added field):** Claude Opus 4.7 (as of 2026-04-25). Update this field on any version transition; flip Tier 2 items to version-pending status concurrently. **STALENESS FLAG (self-improvement audit ITEM 30, 2026-07-11):** this document is now at rev 5 (2026-07-10) and this field was not updated at that revision — verify against the platform's actual current model at the next Q3/A1 cycle (this repo cannot query which model a web-UI routine session is actually running on) and execute the version-change protocol above if it has in fact changed since 2026-04-25.

### Trigger summary

Any "yes" on a quarterly verification question that materially changes the edge map triggers per-strategy foundation-change assessment per `Experiment_Parameters.md`, before any strategy's next trade is executed. The assessment may produce one of three outcomes per strategy:

- **Continue** — the change does not materially affect this strategy's foundation.
- **Terminate** — the change materially weakens this strategy's foundation (an exploited edge is removed/reduced, or a compensated disadvantage is added/increased). Default on ambiguity.
- **Constraint-relaxation review (rev 3)** — the change is a *reduction* in a disadvantage, AND this strategy has constraints that flow from the reduced disadvantage. Triggers a review (single-session adversarial + in-conversation orchestrator review) that considers whether the constraint can be loosened. Default direction: NO relaxation unless the reviewer affirmatively makes the case AND the constraint isn't load-bearing for some other still-in-force disadvantage. See Experiment_Parameters.md §"Foundation change trigger" for full procedure.

---

## Part 5: Mechanical-criteria framework (rev 4)

The orchestrator session executes foundation-change assessment by applying explicit mechanical criteria to evidence. No orchestrator discretion. The criteria are defined in this section. The orchestrator's job is to (a) apply the criteria mechanically, (b) produce the audit-trailed verdict, (c) pass the verdict to the strategy mechanism / pre-mortem update step. Any case where the criteria as stated do not deterministically produce a verdict is itself a defect in the criteria, not a license for orchestrator judgment — such cases are flagged in the orchestrator's output, the strategy is held in its current state pending criteria refinement, and the criteria gap is logged in Decision_Log.md and routed to the autonomous `out-of-table-resolution` review (conservative default: HOLD the strategy in its current state; an affirmative reviewer case is required to move it) rather than dead-ending at participant resolution at the next annual review (rev 5, 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive).

### 5.1 Outcome (a) Continue — mechanical test

**Criterion:** No item in the strategy's foundation citation graph (edges exploited + disadvantages compensated) appears in the current quarterly delta or annual sweep with a status change.

**Procedure:**
1. Parse the strategy's mechanism document and pre-mortem for foundation citations. Output: list of cited items (e.g., "Strategy A cites edges 1.1, 1.4, 1.10 and disadvantages 2.4, 2.13, 2.15, 2.17, 2.19").
2. For each cited item, check current `AI_Trading_Foundation.md` revision: is the item present and unchanged from the revision the strategy was built against?
3. If yes for all cited items → outcome (a) Continue.

### 5.2 Outcome (b) Terminate — mechanical test

**Criterion:** A foundation item the strategy load-bears on has been *removed* OR *materially weakened* per the mechanical thresholds below.

**For removed edges (Part 1):** edge is no longer present in current `AI_Trading_Foundation.md`, AND strategy's mechanism document explicitly cites the edge as exploited (not just adjacent / supportive). Mechanical: the edge appears in a "compensates 2.X" or "exploits 1.X" annotation in the strategy's mechanism Section.

**For added/strengthened disadvantages (Part 2):** disadvantage is newly added in current `AI_Trading_Foundation.md` (compared to the revision the strategy was built against), OR an existing disadvantage's magnitude has materially worsened per quantitative thresholds (Tier 2 magnitude estimates increased by ≥50% in supporting research, OR architectural extension to a previously-uncovered manifestation per Tier 1). The strategy's pre-mortem must compensate for the new/strengthened disadvantage, OR the pre-mortem must be re-opened for a cycle adding flowing limitation. If the strategy cannot compensate (e.g., the new disadvantage is structurally incompatible with the mechanism) → outcome (b) Terminate.

**Procedure:**
1. For each removed/weakened item, check whether strategy load-bears on it (parse strategy mechanism + pre-mortem for explicit citations; trace flowing limitations).
2. If load-bearing AND no compensation pathway → outcome (b) Terminate.
3. If load-bearing AND compensation pathway exists (pre-mortem re-cycle adds new flowing limitation) → re-open pre-mortem; do not terminate.

### 5.3 Outcome (c) Constraint-relaxation review — mechanical test (rev 4)

**Criterion:** A *Tier 2* disadvantage that the strategy compensates for has been *materially reduced* per the quantitative thresholds below (direct research evidence OR benchmark inference per §5.5), AND the strategy has at least one constraint that flows specifically from that disadvantage AND is not load-bearing for any still-in-force disadvantage.

**Procedure (executed by the orchestrator session, no discretion):**

1. **Identify reduction candidates.** From the latest Q3/A1 output, list each disadvantage flagged as reduced. For each, classify reduction magnitude per §5.4 thresholds: NONE (no reduction confirmed), PARTIAL (25-75% reduction), MATERIAL (>75% reduction or full elimination).
2. **For each reduction candidate, identify affected strategy constraints.** Parse **every roster-active strategy's** (`state.active_strategy_codes` — N is no longer a fixed count of five; self-improvement audit ITEM 30, 2026-07-11, matching the parallel fix already applied to Strategy.md's equivalent section) mechanism documents and pre-mortems. For each strategy, list constraints whose *primary* citation is the reduced disadvantage. Mechanical: a constraint's primary citation is the item named in its rev N annotation (e.g., "rev 4 added per cycle 3 T1-α" — the cycle 3 attacker output is parsed for which 2.X item the T1-α attack referenced).
3. **For each affected constraint, apply the load-bearing test.** Parse the pre-mortem's Section 5 entries and binding-constraint section. If the constraint is named as mitigation for any disadvantage other than the reduced one, AND that other disadvantage is still in force per current `AI_Trading_Foundation.md` → constraint is load-bearing for multiple disadvantages → no relaxation, regardless of the reduction magnitude on the cited disadvantage. Mechanical: the constraint's load-bearing status is determined by exact-text-match against pre-mortem Section 5 mitigation citations.
4. **Apply relaxation form per §5.6.** For constraints that pass the load-bearing test, apply the mechanical relaxation lookup based on reduction magnitude.
5. **Output verdict per affected strategy:** list of constraints relaxed (with new form) and constraints not relaxed (with reason — load-bearing for other disadvantages, or insufficient reduction magnitude, or no flowing-limitation match in pre-mortem).
6. **Update strategy mechanism documents** per the verdict, with rev annotation citing the constraint-relaxation review and the underlying foundation update.

### 5.4 Material-reduction thresholds for Tier 2 disadvantages (rev 4)

Each Tier 2 disadvantage with documented quantitative magnitudes has thresholds defining what counts as PARTIAL vs MATERIAL reduction. Thresholds are calibrated so PARTIAL maps to "loosen the constraint somewhat" and MATERIAL maps to "constraint may be fully removed if load-bearing test passes."

| Disadvantage | Current magnitude | PARTIAL reduction (25-75%) | MATERIAL reduction (>75% or eliminated) |
|---|---|---|---|
| 2.3 hallucination (Tier 1 existence / Tier 2 magnitudes) | Hallucination rates correlate with data age and market cap; specific rates vary by domain | Hallucination rate reduced 25-75% per current benchmarks | Hallucination rate reduced >75% per current benchmarks; OR architectural change documented |
| 2.4 narrative over-fit magnitude | Counter-argument reduces bias by ~30% | Counter-argument benefit reaches ~50% (i.e., underlying bias reduced 25-75%) | Counter-argument benefit reaches ~80%+ (bias reduced >75%) |
| 2.7 regime maladaptation | Documented across multiple frameworks | Regime-specific underperformance gap closes by 25-75% per current FINSABER-class benchmarks | Gap closes by >75% |
| 2.8 homogenization | Synchronized AI events documented in Q1 2026 | Frequency/severity of synchronized AI events reduced 25-75% in subsequent quarters | Reduced >75%; OR structural changes to AI deployment landscape (e.g., model diversity index improves materially) |
| 2.10 prompt injection | Opus-tier ~1% attack success rate with classifiers; 17.8% without; 50% bypass at 10 attempts on best frontier | Attack success rate reduced 25-75% on Claude family with current safeguards | Attack success rate <2% on Claude family AND <10% bypass at 10 attempts |
| 2.13 miscalibration magnitude | 80% CIs hit ~69%; ECE 0.122-0.726 across models | ECE on Claude family reduced 25-75% (e.g., from 0.30 to 0.10-0.22) | ECE on Claude family <0.10 AND 80% CI hit rate ≥75% |
| 2.14 recency bias magnitude | ~10× weighting on most recent week | Recency weighting reduced to 3-7× | Recency weighting reduced to ≤2× |
| 2.15 base-rate neglect magnitude | ~85% error rate on Bayesian base-rate tasks | Error rate reduced to 40-60% | Error rate ≤40% |
| 2.17 algorithm appreciation magnitude | Programmatic bias toward algorithmic authority | Bias rate reduced 25-75% per current revealed-preference benchmarks | Bias rate reduced >75% |
| 2.19 look-ahead bias magnitude | Alpha decay >15pp between in-sample and out-of-sample | Alpha decay reduced to 5-12pp per current backtests | Alpha decay reduced to <5pp |
| 2.20 textbook-rational penalty | Multi-agent simulations show ~0% bubble participation | Bubble participation rate increases to 15-40% | Bubble participation rate ≥40% |

**For Tier 2 items without current quantitative magnitudes** (e.g., partial-reduction disadvantages where rev 1 didn't include specific numbers): PARTIAL/MATERIAL reduction thresholds are set at the next quarterly delta or annual sweep that produces a specific magnitude estimate, by the orchestrator session, using the heuristic "PARTIAL = halfway between current and full mitigation; MATERIAL = within 25% of full mitigation." This is a one-time threshold-setting exercise per item, not a recurring judgment.

**For Tier 1 items:** no PARTIAL/MATERIAL reduction thresholds apply. Tier 1 items don't get reduced — they get architecturally changed (which triggers full-document re-evaluation, not constraint-relaxation review). The constraint-relaxation pathway is Tier-2-only.

### 5.5 Benchmark-inference protocol (rev 4)

A Tier 2 disadvantage can be inferred as reduced from benchmark-result improvements without requiring an explicit "deficiency X is cured" research paper, using the benchmark-to-disadvantage mapping below. This addresses the publication-asymmetry problem (improvements often don't generate papers; benchmarks are the more common signal).

**Mapping from benchmarks to Tier 2 disadvantages:**

| Disadvantage | Primary benchmark(s) | Secondary indicators |
|---|---|---|
| 2.3 hallucination | TruthfulQA, FEVER, HaluEval, FreshLLMs, FActScore | Domain-specific hallucination rates in financial QA |
| 2.4 narrative over-fit | Forecasting benchmarks comparing AI predictions to outcomes (gap between confidence and accuracy); explicit counter-argument benefit measurements | Empirical replications of "30% reduction" claim |
| 2.7 regime maladaptation | FINSABER cross-regime evaluation; LLM trading arena results across regime types | Hedge fund / prop disclosures on AI performance across regimes |
| 2.10 prompt injection | International AI Safety Report attack-success metrics; Anthropic published red-team results | Independent audits (Anthropic-affiliated and independent) |
| 2.13 miscalibration | ECE benchmarks (Expected Calibration Error); 80% CI hit-rate measurements; Dunning-Kruger calibration suite (arXiv 2603.09985 family) | RLVR/DPO post-training calibration research |
| 2.14 recency bias | Bayesian update tasks measuring recency-weight ratios; specific recency-bias benchmarks | Recency-weighted-window ablation studies |
| 2.15 base-rate neglect | Bayesian base-rate task error rates; CogniBench-class probabilistic-reasoning benchmarks | Replication studies on the "85%" finding |
| 2.17 algorithm appreciation | Algorithm-vs-human revealed-preference benchmarks; trust-calibration tasks | Behavioral economics replications |
| 2.19 look-ahead bias | Alpha decay measurements between pre-cutoff and post-cutoff backtests (FINSABER-class); Scaling Paradox replications | Backtest contamination audits |
| 2.20 textbook-rational penalty | Multi-agent simulation bubble-formation tests; behavioral-finance LLM benchmarks | Synthetic-market replication studies |

**Disadvantages without benchmark mapping:** 2.8 homogenization (no clean benchmark — relies on synchronized-AI-event observation), 2.25 agentic epistemic hallucination (TradeTrap is the primary benchmark, but it's emerging — broader benchmark coverage unclear), 2.26 RL-post-training overconfidence (overlaps with 2.13 ECE benchmarks but distinct mechanism — covered indirectly via 2.13 mapping). These remain reducible only by explicit-research-finding signal until benchmark coverage matures.

**Goodhart guardrails (rev 4):** Benchmark inference requires ALL of the following to count as a reduction signal:

1. **Replication.** ≥3 independent benchmark sources (different research groups, different benchmark suites) showing the same direction of improvement on the same disadvantage. Single-source signal is insufficient.
2. **Transferability.** Either (a) replication on Claude family specifically, OR (b) architectural-generality argument — improvement is documented as a property of autoregressive LLMs trained with current methods broadly, not a single-model artifact. Improvements specific to non-Claude models without architectural-generality argument do not count for our workflow.
3. **Sustained.** Improvement has held across at least 2 consecutive quarterly delta cycles, OR is documented in last-2-years coverage of an annual A1 sweep. Single-quarter improvements may be benchmark-overfitting; sustained improvement is the signal.
4. **Domain coverage.** For benchmarks that are general-purpose (e.g., TruthfulQA, ECE), improvement on the general benchmark counts as evidence; for benchmarks that are narrow (e.g., specific financial-domain benchmarks), improvement on the narrow benchmark counts only if the narrow domain is representative of the workflow's actual usage.

If any of conditions 1-4 fail, the benchmark signal does not count as reduction confirmation. The orchestrator records the partial-evidence status and the disadvantage stays at its current magnitude pending further evidence.

**Direct research findings still count regardless of benchmark coverage.** A paper that explicitly says "we measured Claude Opus 5 ECE at 0.08, down from 4.7's 0.20" is direct evidence and triggers reduction confirmation per §5.4 thresholds; it doesn't need to clear the benchmark guardrails because the paper itself is the replication.

### 5.6 Mechanical relaxation lookup (rev 4)

For a constraint that passes the load-bearing test, the relaxation form is determined by mechanical lookup based on (a) the reduction magnitude (PARTIAL vs MATERIAL) and (b) the constraint type. Constraint types with predefined relaxation forms:

**Per-position sizing caps** (e.g., 2% per-position cap):
- PARTIAL reduction → cap loosened proportionally to reduction percentage. Example: 2% cap with 50% disadvantage reduction → cap loosened to (2% × (1 + 0.50)) = 3%.
- MATERIAL reduction → cap loosened to (current × 2) but bounded by experiment-level cap of 5% per position. Cap remains in force at the loosened level; not removed entirely (because per-position sizing is also a workflow-level capital-preservation guard, not solely disadvantage-mitigation).

**Universe restrictions** (e.g., Subtype A/B requirement, observable-invalidation requirement):
- PARTIAL reduction → universe restriction stays in force; no automatic relaxation (universe restrictions are typically structural and don't admit graded relaxation).
- MATERIAL reduction with full elimination of the cited disadvantage → universe restriction reconsidered for full removal, but only if the load-bearing test confirms the restriction was solely for that disadvantage.

**Concentration limits** (e.g., 30% sector cap, correlation-bucket cap):
- PARTIAL reduction → concentration limit raised proportionally (e.g., 30% sector cap → 35% with 50% reduction).
- MATERIAL reduction → concentration limit raised to (current + 15pp) bounded by 50%, OR removed entirely if all cited disadvantages are eliminated.

**Frequency / cadence rules** (e.g., monthly review of position theses):
- No automatic relaxation. Cadence rules are typically not disadvantage-keyed in a way that admits mechanical loosening; they require explicit review at the annual constraint audit (A2) with mechanical criteria specific to the cadence rule's purpose.

**Hit-rate thresholds and edge-decay metrics** (e.g., 45% hit-rate threshold for long-debit; EV-per-trade < 0):
- Disadvantage-keyed threshold relaxation: if the disadvantage that informed the threshold derivation is reduced, the threshold relaxes proportionally. Example: if 2.13 miscalibration reduces by 50%, hit-rate thresholds derived from miscalibration-bias considerations relax by (1 + 0.50 × confidence-multiplier-tied-to-derivation).
- Default: no automatic relaxation unless the threshold's derivation explicitly cites a Tier 2 disadvantage magnitude.

**Constraints not in the lookup table:** any constraint whose mechanism doesn't fit the categories above generates an "out-of-table" flag in the orchestrator output. The constraint stays at its current value; the gap is logged in Decision_Log.md and routed to the autonomous `out-of-table-resolution` review (conservative default: HOLD the constraint at its current value; an affirmative reviewer case is required to relax it) rather than deferring to participant resolution at the next annual review (rev 5, 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive). This is the explicit exception path the framework's "no discretion" principle requires.

### 5.7 Output format — mechanical-criteria audit trail (rev 4)

The orchestrator session's foundation-change assessment output for each strategy is a structured audit trail with the following sections:

1. **Strategy identifier and current revision.**
2. **Foundation citation graph** — list of cited items (edges + disadvantages) parsed from strategy mechanism + pre-mortem.
3. **Status changes since strategy's foundation revision** — per cited item: status, magnitude (if Tier 2), reduction-classification (NONE/PARTIAL/MATERIAL).
4. **Outcome verdict per item** — Continue / Terminate / Constraint-relaxation review (the latter is per-constraint, not per-strategy).
5. **For each constraint-relaxation candidate** — load-bearing test result, applicable relaxation form per §5.6, new constraint value, rev annotation for the strategy mechanism document.
6. **Out-of-table flags** — any constraints or items the criteria couldn't deterministically resolve. This section remains a required output field; the flags are consumed by the autonomous `out-of-table-resolution` review (conservative default: HOLD current state/value) rather than dead-ending at participant handoff (rev 5, 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive).

The output is mechanical and replicable — running the same orchestrator session on the same inputs should produce the same verdict (within the bounds of 2.24 cross-session inconsistency, which is the residual unavoidable variance the architecture accepts).
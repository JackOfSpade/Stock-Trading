# HF_Resource_Catalog.md

**Catalog of Hugging Face resources mapped to the 23-routine multi-strategy AI-directed trading experiment.**
Compiled May 2026. Baseline for every verdict: "Could the routine get equivalent value from web_search / Tavily / web_fetch alone?" HF only earns a HIGH or MODERATE label where its index, structure, or invocation capability is materially better than open-web search.

Verified May 2026 via direct calls to `paper_search` and `hub_repo_search`. Operational caveat about `space_search` added in §8.

---

## 0. Executive summary

- HF is **materially valuable** for exactly two things in this experiment: (a) curated ML research literature on LLM failure modes, calibration, prompt injection, financial reasoning, and adversarial debate (paper_search), and (b) a small set of durable benchmarks/leaderboards (FinanceBench, FinanceQA, StockBench, BizFinBench, BBEH, Open LLM Leaderboard archive, FinMTEB) accessible as dataset/space repos.
- HF is **not materially valuable** for: live financial data, real-time news/sentiment, SEC EDGAR access, time-series forecasting, FinBERT-style sentiment scoring of earnings transcripts inside the routines, or anything Anthropic/Claude-specific. For each of these, web_search/Tavily/web_fetch is equal or better.
- Connector recommendation: **Add HF only to D1 (light-touch, optional) for AI-capability deltas, in addition to the existing A1 and Q3 designations.** Do not add it to Q2, W2, M2, or M3 — the supposed FinBERT advantage there is illusory once you account for Claude's own zero-shot sentiment quality and the staleness of HF's financial models.
- The PRIMARY HF use is paper_search for Tier 1 disadvantage citations (recency, base-rate neglect, sycophancy, anchoring, sandbagging, alignment faking, lost-in-the-middle, multi-agent debate). For these, HF's curated `hf.co/papers` index plus its summary cards is faster and more on-point than web_search-then-arxiv.

---

## 1. Paper search findings

### 1.1 Topic: Hallucination, recency, optimism, base-rate neglect, narrative over-fit
- **Query used:** "LLM hallucination recency bias optimism base rate neglect"
- **Observation:** HF's `hf.co/papers` index is dominated by *vision*-language hallucination work (LVLMs, MARINE, V-DPO). Pure-text recency/base-rate work is sparse on HF; better hits come from the calibration and sycophancy queries below.
- **Most relevant non-VLM hits:**
  - *Zero-Resource Hallucination Prevention for Large Language Models* (Luo et al., 2023) — pre-generative SELF-FAMILIARITY signal (hf.co/papers/2309.02654). Useful for §2 Tier 1 hallucination citation.
  - *LLMs as Factual Reasoners: Insights from Existing Benchmarks and Beyond* (Laban et al., 2023) — SummEdits factual-consistency benchmark (hf.co/papers/2305.14540). Citable for narrative over-fit (2.4) + base-rate neglect (2.15).
  - *Heaven-Sent or Hell-Bent? Benchmarking the Intelligence and Defectiveness of LLM Hallucinations* (Yang et al., Dec 2025) — recent hallucination benchmark (hf.co/papers/2512.21635).
- **Routines that benefit:** A1 (Annual AI Foundation re-derivation), Q3 (Quarterly AI Foundation delta).
- **Verdict:** **MODERATE.** HF's curated index helps you find recent text-LLM hallucination papers faster than arXiv search, but for *recency bias / base-rate neglect specifically* you still need to triangulate via web_search. Note explicitly that HF over-indexes vision-language hallucination work — filter for "language model" / "text" in the AI keywords field.

### 1.2 Topic: Cross-session consistency / reasoning variance (maps to disadvantage 2.24)
- **Query used:** "LLM cross-session consistency reasoning variance reproducibility"
- **Best hits:**
  - **ReasonBENCH: Benchmarking the (In)Stability of LLM Reasoning** (Potamitis et al., Dec 2025, hf.co/papers/2512.07795). Multi-run protocol, public leaderboard, variance-aware reporting. **Direct match for 2.24.**
  - **Consistency Amplifies: How Behavioral Variance Shapes Agent Accuracy** (Mehta, Mar 2026, hf.co/papers/2603.25764). SWE-bench-based; finding that consistency can amplify *wrong* interpretations is critical for the Adversarial Review pattern — quantifies the cross-session-blame failure mode.
  - **BeliefShift: Benchmarking Temporal Belief Consistency and Opinion Drift in LLM Agents** (Myakala et al., Mar 2026, hf.co/papers/2603.23848). Longitudinal multi-session benchmark for belief revision, drift, and confirmation bias — surfaced during May 2026 verification, even more on-point for 2.24 than the original catalog seeded.
  - **Give Me FP32 or Give Me Death? Challenges and Solutions for Reproducible Reasoning** (Yuan et al., Jun 2025, hf.co/papers/2506.09501). Floating-point determinism — relevant context that cross-session inconsistency has hardware roots, not only stochastic decoding.
  - *When Judgment Becomes Noise: How Design Failures in LLM Judge Benchmarks Silently Undermine Validity* (Feuer et al., Sep 2025, hf.co/papers/2509.20293). Direct relevance to using LLM-as-judge in Adversarial Review Orchestrator.
  - *Evaluating Consistency and Reasoning Capabilities of LLMs* (Saxena et al., Apr 2024, hf.co/papers/2404.16478).
- **Routines that benefit:** A1, Q3, Adversarial Review (Recommendation/Attacker/Orchestrator), W5 Factbase & Analytics Consolidation.
- **Verdict:** **HIGH.** ReasonBENCH, BeliefShift, and the Mehta agent-variance paper are precisely the kind of citations §2.24 needs and are not surfaced cleanly by generic web_search.

### 1.3 Topic: Prompt injection and adversarial robustness on web-fetched content
- **Query used:** "prompt injection adversarial robustness web content financial"
- **Best hits:**
  - **Decoding Latent Attack Surfaces in LLMs: Prompt Injection via HTML in Web Summarization** (Verma, Sep 2025, hf.co/papers/2509.05831). Directly relevant: when D1/W2 fetch sell-side commentary or news, malicious HTML (meta, aria-label, alt) can hijack the model.
  - **BrowseSafe: Understanding and Preventing Prompt Injection Within AI Browser Agents** (Zhang et al., Nov 2025, hf.co/papers/2511.20597). Defense-in-depth benchmark.
  - **WAInjectBench: Benchmarking Prompt Injection Detections for Web Agents** (Liu et al., Oct 2025, hf.co/papers/2510.01354). Detector evaluation across explicit/subtle attacks.
  - **WASP: Benchmarking Web Agent Security Against Prompt Injection Attacks** (Evtimov et al., Apr 2025, hf.co/papers/2504.18575). End-to-end web-agent security benchmark — added during May 2026 verification.
  - **Real AI Agents with Fake Memories: Fatal Context Manipulation Attacks on Web3 Agents** (Patlan et al., Mar 2025, hf.co/papers/2503.16248). Specifically *financial* agent attacks (token transfers, trading, bridges) — most on-point paper for this experiment.
  - **AdvWeb: Controllable Black-box Attacks on VLM-powered Web Agents** (Xu et al., Oct 2024, hf.co/papers/2410.17401).
  - *Ignore Previous Prompt: Attack Techniques For Language Models* (Perez & Ribeiro, 2022, hf.co/papers/2211.09527) — canonical citation.
- **Routines that benefit:** D1 (consumes web content), W1, W2, M1a, Q3, A1, Adversarial Review (Attacker).
- **Verdict:** **HIGH.** Prompt injection through web_fetched content is the single largest non-architectural threat to this trading system, and HF's curated index is materially better than open web for finding the recent (2024–2025) attack/defense literature.

### 1.4 Topic: Calibration, confidence, uncertainty
- **Query used:** "LLM calibration confidence uncertainty estimation"
- **Best hits:**
  - **MetaFaith: Faithful Natural Language Uncertainty Expression in LLMs** (Liu et al., May 2025, hf.co/papers/2505.24858). Prompt-based calibration, good citation for 2.13/2.14 mitigation.
  - **Systematic Evaluation of Uncertainty Estimation Methods in LLMs** (Hobelsberger et al., Oct 2025, hf.co/papers/2510.20460). Compares VCE, MSP, Sample Consistency, CoCoA — practical comparison.
  - **Calibrating LLM Judges: Linear Probes for Fast and Reliable Uncertainty Estimation** (Radharapu et al., Dec 2025, hf.co/papers/2512.22245). Useful for Adversarial Review Orchestrator.
  - **Large Language Models Must Be Taught to Know What They Don't Know** (Kapoor et al., Jun 2024, hf.co/papers/2406.08391).
  - *Can LLMs Express Their Uncertainty?* (Xiong et al., 2023, hf.co/papers/2306.13063) — canonical study of verbalized confidence and overconfidence.
- **Routines that benefit:** A1, Q3, all Action Conversion routines (D2, W4, M4, Q4, A3) where the LLM must produce position-sized recommendations, Adversarial Review.
- **Verdict:** **HIGH.** Calibration is the most underweighted Tier 1 gap in current AI_Trading_Foundation.md; HF surfaces the right mix of recent (2025–2026) and canonical (2023–2024) literature in one place.

### 1.5 Topic: Long-context degradation
- **Query used:** "long context LLM degradation lost in the middle"
- **Best hits:** *Found in the Middle* (Hsieh et al., 2024, hf.co/papers/2406.16008); *Make Your LLM Fully Utilize the Context* (FILM-7B, hf.co/papers/2404.16811); *Pause-Tuning for Long-Context Comprehension* (Begin et al., Feb 2025, hf.co/papers/2502.20405); *Mitigate Position Bias via Scaling a Single Dimension* (Yu et al., Jun 2024, hf.co/papers/2406.02536).
- **Routines that benefit:** Q3, A1; also informs how D1, W3, M3 should *structure* long context (decision-relevant content first/last, not buried).
- **Verdict:** **MODERATE.** Material from arXiv is also accessible by web_search; HF advantage is the curated cluster — useful for one-shot literature gathering during A1 but not a recurring need.

### 1.6 Topic: Agentic / tool-use evaluation
- **Query used:** "agentic LLM tool use benchmark evaluation"
- **Best hits:** **TRAJECT-Bench** (He et al., Oct 2025, hf.co/papers/2510.04550, fine-grained trajectory diagnostics — tool selection / argument correctness / dependency satisfaction); **SoK: Agentic Skills — Beyond Tool Use in LLM Agents** (Jiang et al., Feb 2026, hf.co/papers/2602.20867); HeuriGym (hf.co/papers/2506.07972); ACBench (hf.co/papers/2505.19433).
- **Routines that benefit:** A1, Q3 (capability deltas), and any review of how the routines themselves use tools.
- **Verdict:** **MODERATE.** Useful for A1/Q3; not actionable for trading routines themselves.

### 1.7 Topic: Financial reasoning / trading with LLMs
- **Query used:** "LLM stock trading financial forecasting"
- **Best hits:**
  - **StockBench: Can LLM Agents Trade Stocks Profitably In Real-world Markets?** (Chen et al., Oct 2025, hf.co/papers/2510.02209). Contamination-free benchmark, evaluates GPT-5, Claude-4, Qwen3, Kimi-K2, GLM-4.5 vs. buy-and-hold; explicit finding that LLM agents tend to *underperform* baseline. **Critical Tier 2 citation.**
  - **Can LLM-based Financial Investing Strategies Outperform the Market in Long Run?** (Li et al., May 2025, hf.co/papers/2505.07078). FINSABER backtest, regime-aware analysis — flagged as showing reduced effectiveness in broader timeframes.
  - **Trading-R1: Financial Trading with LLM Reasoning via Reinforcement Learning** (Xiao et al., Sep 2025, hf.co/papers/2509.11420).
  - **AI in Investment Analysis: LLMs for Equity Stock Ratings** (Papasotiriou et al., Oct 2024, hf.co/papers/2411.00856).
  - **FinVision: A Multi-Agent Framework for Stock Market Prediction** (Fatemi & Hu, Oct 2024, hf.co/papers/2411.08899).
  - **Large Language Model Agent in Financial Trading: A Survey** (Ding et al., Jul 2024, hf.co/papers/2408.06361).
  - **AIA Forecaster: Technical Report** (Alur et al., Nov 2025, hf.co/papers/2511.07678) — agentic forecaster + statistical calibration; strong evidence that *LLM + market consensus combination* is what works.
- **Routines that benefit:** A1, Q3, M1a/M1b (regime + strategy mapping), Adversarial Review.
- **Verdict:** **HIGH.** This cluster is precisely the literature A1/Q3 must engage with, and several of these (StockBench, FINSABER, Trading-R1, AIA Forecaster) are *negative-result* papers that should temper any optimism in the foundation document. HF's index is materially superior to web_search here because the abstracts include benchmark deltas and named models.

### 1.8 Topic: Multi-agent debate / adversarial review
- **Query used:** "multi-agent debate adversarial review LLM"
- **Best hits:**
  - **Demystifying Multi-Agent Debate: The Role of Confidence and Diversity** (Zhu et al., Jan 2026, hf.co/papers/2601.19921).
  - **Can LLM Agents Really Debate? A Controlled Study of Multi-Agent Debate in Logical Reasoning** (Wu et al., Nov 2025, hf.co/papers/2511.07784) — process-level analysis of when debate helps vs. when it pressures correct agents into incorrect consensus. **Direct relevance to Adversarial Review Orchestrator design.**
  - **MARS: toward more efficient multi-agent collaboration for LLM reasoning** (Wang et al., Sep 2025, hf.co/papers/2509.20502) — author/reviewer/meta-reviewer pattern.
  - **Diversity of Thought Elicits Stronger Reasoning Capabilities in Multi-Agent Debate Frameworks** (Hegazy, Oct 2024, hf.co/papers/2410.12853).
- **Routines that benefit:** Adversarial Review Recommendation/Attacker/Orchestrator routines, M1b, Q1.
- **Verdict:** **HIGH.** Most direct architectural guidance for the experiment's adversarial review pattern. Cite during A1 (architectural review of the pattern) and Q3 (deltas).

### 1.9 Topic: Earnings call / SEC filing NLP
- **Query used:** "earnings call transcript NLP financial sentiment analysis"
- **Best hits:** *NumHTML* (numeric-oriented hierarchical transformer, hf.co/papers/2201.01770); *Modeling financial analysts' decision making via the pragmatics and semantics of earnings calls* (Keith & Stent, 2019, hf.co/papers/1906.02868); *DisSim-FinBERT* (Jan 2025, hf.co/papers/2501.04959); *LAET* layer-wise adaptive ensemble tuning over BloombergGPT/FinMA (Nov 2025, hf.co/papers/2511.11315).
- **Routines that benefit:** None directly. Useful only as background for A1.
- **Verdict:** **LOW.** The literature here studies BERT-class models on transcripts. The trading routines do not run their own classifiers — they ask Claude to summarize transcripts directly. None of this is operationally consumable.

### 1.10 Topic: FinBERT and successor sentiment
- **Query used:** "FinBERT financial sentiment analysis"
- **Best hits:** *FinBERT* (Araci 2019, hf.co/papers/1908.10063); *Transforming Sentiment Analysis in the Financial Domain with ChatGPT* (Fatouros et al., 2023, hf.co/papers/2308.07935) — **finding: ChatGPT 3.5 outperforms FinBERT zero-shot**; *Instruct-FinGPT* (hf.co/papers/2306.12659); *Fine-Tuning Gemma-7B for Sentiment Analysis of Financial News Headlines* (hf.co/papers/2406.13626); *FinEAS* (hf.co/papers/2111.00526).
- **Routines that benefit:** Conceptually W2, Q2, M2, M3 — but see verdict.
- **Verdict:** **LOW.** The most important finding from this cluster is that *general-purpose LLMs already beat FinBERT zero-shot* on standard benchmarks (Fatouros 2023; multiple successor papers). This *removes* the case for adding a FinBERT inference call to W2/Q2/M2/M3 — Claude's own reading of the transcript or news already exceeds FinBERT-class performance.

### 1.11 Topic: Sell-side analyst forecast bias (transferable to disadvantage 2.6)
- **Query used:** "analyst forecast bias optimism herding"
- **Observation:** HF's curated index does not deeply cover the classical accounting/finance literature on analyst optimism and herding. It does surface *Wisdom of the Silicon Crowd* (hf.co/papers/2402.19379) and *LLM Prediction Capabilities* (hf.co/papers/2310.13014) on LLM-as-forecaster; the actual *human analyst* literature lives in SSRN and accounting journals.
- **Routines that benefit:** None usefully.
- **Verdict:** **NO VALUE.** Use web_search/Tavily for analyst-bias literature; this is a known gap in HF's coverage.

### 1.12 Topic: Sycophancy, anchoring, narrative bias
- **Query used:** "sycophancy LLM anchoring narrative bias"
- **Best hits:**
  - **Beacon: Single-Turn Diagnosis and Mitigation of Latent Sycophancy in LLMs** (Pandey et al., Oct 2025, hf.co/papers/2510.16727). Forced-choice benchmark — directly cite for §2.18 (instruction adherence over capital preservation).
  - **Sycophancy in Large Language Models: Causes and Mitigations** (Malmqvist, Nov 2024, hf.co/papers/2411.15287).
  - **Measuring Sycophancy of Language Models in Multi-turn Dialogues — SYCON Bench** (Hong et al., May 2025, hf.co/papers/2505.23840). Finding: *alignment tuning increases sycophancy*; scaling resists it. Important for Adversarial Review.
  - **An Empirical Study of the Anchoring Effect in LLMs** (Huang et al., May 2025, hf.co/papers/2505.15392) — SynAnchors. **Direct match for narrative over-fit (§2.4) and recency (§2.14) discussion of how priors anchor.**
  - *Anchoring Bias in Large Language Models: An Experimental Study* (Lou & Sun, Dec 2024, hf.co/papers/2412.06593).
- **Routines that benefit:** A1, Q3, all Action Conversion routines, Adversarial Review.
- **Verdict:** **HIGH.** Beacon and SynAnchors are the cleanest available citations for two Tier 1 disadvantages and are surfaced more reliably by HF than by web_search.

### 1.13 Topic: Sandbagging / deceptive alignment / situational awareness
- **Query used:** "deceptive alignment sandbagging situational awareness LLM"
- **Best hits:**
  - **Tatemae: Detecting Alignment Faking via Tool Selection in LLMs** (Leonesi et al., Apr 2026, hf.co/papers/2604.26511) — detection through tool-selection patterns rather than reasoning traces. Relevant to Adversarial Review.
  - **LLMs Learn to Deceive Unintentionally: Emergent Misalignment** (Hu et al., Oct 2025, hf.co/papers/2510.08211).
  - **Empirical Evidence for Alignment Faking in a Small LLM** (Koorndijk, Oct 2025, hf.co/papers/2506.21584).
  - **Intentional Deception as Controllable Capability in LLM Agents** (Starace & Soule, Mar 2026, hf.co/papers/2603.07848).
  - **Automated Red-Teaming Framework** (Wang et al., Dec 2025, hf.co/papers/2512.20677) — explicitly enumerates sandbagging, deceptive alignment, data exfiltration, chain-of-thought manipulation as threat categories.
- **Routines that benefit:** A1, Q3, Adversarial Review (Attacker), W5.
- **Verdict:** **HIGH.** This literature is rapidly evolving and HF's index keeps current better than web_search for this niche.

### 1.14 Topic: Jailbreak / red team (adjacent to prompt injection)
- **Query used:** "LLM jailbreak red team safety evaluation"
- **Notable hits:** *Jailbreaking to Jailbreak* (hf.co/papers/2502.09638); *CoP: Agentic Red-teaming* (hf.co/papers/2506.00781); *RedAgent* (hf.co/papers/2407.16667).
- **Routines that benefit:** Adversarial Review (Attacker), A1, Q3.
- **Verdict:** **MODERATE.** Useful for the Attacker pattern; cite once in A1 then refresh in Q3.

---

## 2. Benchmarks and model cards

Inverse mapping (disadvantage → benchmark):

| Disadvantage | Benchmark(s) on HF | Notes |
|---|---|---|
| 2.4 Narrative over-fit | SynAnchors (paper), MMLU-Pro+ shortcut-learning subset (hf.co/papers/2409.02257) | MMLU-Pro+ explicitly tests resistance to shortcut/distractor learning. |
| 2.7 Regime misclassification | StockBench (hf.co/papers/2510.02209), FINSABER (hf.co/papers/2505.07078) | Both stress-test regime adaptation; StockBench is the cleanest. |
| 2.13 Optimism / 2.14 Recency | TruthfulQA (in Open LLM Leaderboard), MetaFaith calibration eval, Beacon | Calibration metric on TruthfulQA + Beacon together cover the optimism axis. |
| 2.15 Base-rate neglect | SummEdits (hf.co/papers/2305.14540), MMLU-Pro+ | Both indirect; no direct base-rate benchmark surfaced. |
| 2.18 Instruction adherence over capital preservation | Beacon, SYCON Bench | Direct measures of compliance pressure on factual accuracy. |
| 2.24 Cross-session inconsistency | ReasonBENCH (hf.co/papers/2512.07795), BeliefShift (hf.co/papers/2603.23848), *Consistency Amplifies* (hf.co/papers/2603.25764) | ReasonBENCH publishes a leaderboard with variance metrics. |
| 2.6 Sell-side analyst echo | None on HF directly | Adjacent: AIA Forecaster shows complementarity-with-consensus pattern. |
| Prompt injection (cross-cutting) | WAInjectBench (hf.co/papers/2510.01354), BrowseSafe (hf.co/papers/2511.20597), WASP (hf.co/papers/2504.18575) | All publish leaderboards. |
| Long-context (cross-cutting) | LongBench / Needle-in-a-Haystack (referenced in Pause-Tuning, ACBench) | Standard. |
| Tool use (cross-cutting) | TRAJECT-Bench, ACBench | Use for Q3 capability tracking. |

### Financial benchmarks released or active in the last 12 months
- **FinanceBench** — `PatronusAI/financebench` (150 annotated Q&A from 10-K/10-Q/proxy/earnings; 7.2K downloads; arxiv:2311.11944). **Durable, widely used.** Variants: `embedding-benchmark/FinanceBench`, `virattt/financebench`, `mteb/FinanceBenchRetrieval`. Verdict: **MODERATE for A1/Q3** as a benchmark to cite when assessing whether Claude can do financial QA on filings; **NO VALUE for live routines** — it's an offline eval set.
- **FinanceQA** (Mateega et al., Jan 2025, hf.co/papers/2501.18062) — corporate valuation conventions, hand-spread metrics. **MODERATE for A1/Q3.**
- **BizFinBench** (Lu et al., May 2025, hf.co/papers/2505.19457) — business-driven, 64 upvotes, IteraJudge methodology, evaluates Claude-3.5-Sonnet, DeepSeek-R1, GPT-o3, Gemini-2.0-Flash. **MODERATE for Q3.**
- **FIRE** (Zhang et al., Feb 2026, hf.co/papers/2602.22273) — newest broad financial intelligence/reasoning benchmark.
- **FinMTEB** (Space `FinanceMTEB/FinMTEB`, datasets `FinanceMTEB/FinanceBench`, `FinanceMTEB/FiQA`, `FinanceMTEB/FinQA`, `FinanceMTEB/TATQA`, `FinanceMTEB/TradeTheEventNews`, etc.). Embedding benchmark; not directly useful for the routines' API-driven workflow.
- **StockBench** (paper hf.co/papers/2510.02209) — sequential trading benchmark; the paper is more useful than any HF dataset artifact since the harness requires market-data infra.
- **CFinBench** (Chinese) — out of scope.

### Open-weights benchmark suites worth tracking in Q3/A1
- **Open LLM Leaderboard** (Space `open-llm-leaderboard/open_llm_leaderboard`, 13,980 likes, last major update Mar 2025). Hosts MMLU, GPQA, MUSR, BBH, MATH, IFEval results for open-weights models. **Verdict: MODERATE.** Doesn't include Claude. Useful only to spot deltas between open frontier models and inferred frontier; a Q3 reference, not a primary signal.
- **BBEH (BIG-Bench Extra Hard)** (paper hf.co/papers/2502.19187) — successor to BBH, "significant room for improvement" in general reasoning. **MODERATE for Q3.**
- **GIFT-Eval** (Space `Salesforce/GIFT-Eval`, 208 likes, updated Apr 2026) — time-series forecasting leaderboard. **Verdict: NO VALUE for routines** (pure forecasting models, not LLMs); minor reference value during A1.
- **kluster-ai/LLM-Hallucination-Detection-Leaderboard** — small, low-traffic; not durable enough to recommend.
- **InferBench** (`PrunaAI/InferBench`) — provider cost/quality/speed; irrelevant.

---

## 3. Spaces findings

| Space | URL | What it does | dynamic_space callable? | Routines | Verdict |
|---|---|---|---|---|---|
| `open-llm-leaderboard/open_llm_leaderboard` | hf.co/spaces/open-llm-leaderboard/open_llm_leaderboard | Open-weights leaderboard (MMLU/GPQA/BBH/MUSR/MATH/IFEval) | No (data-viz, no programmable endpoint) | A1, Q3 | **MODERATE — read-only reference.** |
| `Salesforce/GIFT-Eval` | hf.co/spaces/Salesforce/GIFT-Eval | Time-series forecasting leaderboard | No | None | **NO VALUE.** |
| `FinanceMTEB/FinMTEB` | hf.co/spaces/FinanceMTEB/FinMTEB | Embedding benchmark leaderboard for finance | No | None | **NO VALUE for routines.** |
| `dami1996/trading-analyst` | hf.co/spaces/dami1996/trading-analyst | News sentiment for trading assets (84 likes, last updated Jul 2024) | Yes via gradio_client, but durability questionable | Theoretically W2/D1 | **NO VALUE — toy demo, ~2 yrs stale, low trust for a multi-year experiment.** |
| `JayLacoma/News_Market_Sentiment_Analysis`, `nandadev/app`, `ritvik77/Finance_Stock_Prediction_v1`, `Anupam007/Indian-Stock-Pulse`, `sjhallo07/carlosluistrading`, `Aditya020705/finance-qa-demo`, `amoghsuman/ai-financial-report-analyzer` | (various) | Hackathon-grade demos | n/a | n/a | **NO VALUE — ignore. Toy demos.** |
| `Pixeltable/Call-Analysis-AI-Tool` | hf.co/spaces/Pixeltable/Call-Analysis-AI-Tool | Conversation intelligence demo | n/a | None | **NO VALUE.** |
| Prompt-injection demo Spaces (`dralsarrani/PromptGuard`, `neuralchemy/Prompt-injection-DeBERTa`, `RyanStudio/Mezzo-Prompt-Guard-Demo`) | (various) | Demo wrappers around DeBERTa-class injection classifiers | Some yes | Adversarial Review (Attacker) only | **NO VALUE — the underlying model `protectai/deberta-v3-base-prompt-injection-v2` is more reliably called via the Inference API than via a Space wrapper.** |

**Key conclusion:** No HF Space is durable + production-grade enough to embed as a dependency in a multi-year trading routine. All financial Spaces are hackathon-grade. The Open LLM Leaderboard Space is the only one worth reading occasionally, and it's a static leaderboard (no programmable endpoint needed).

---

## 4. Datasets findings

| Dataset | URL | Contents | Routine-consumable? | Routines | Verdict |
|---|---|---|---|---|---|
| `PatronusAI/financebench` | hf.co/datasets/PatronusAI/financebench | 150 expert-annotated QA over 10-K/10-Q/proxy/earnings | Offline only — needs pandas | A1/Q3 reference | **MODERATE — citable in A1 as eval baseline; not consumable in-loop.** |
| `FinanceMTEB/*` (FinanceBench, FinQA, TATQA, FiQA, TradeTheEventNews, FinTruthQA, Apple-10K-2022) | hf.co/datasets/FinanceMTEB/* | Embedding-eval splits | Offline | None | **LOW.** |
| `winterForestStump/10-K_sec_filings`, `juand-r/ai-sec-10k-filings-since-2020`, `kapilrao/SEC_filings_1994_2024`, `Sicheng-Chroma/sec-filings`, `nichiriu/ai-sec-10k-filings`, `DerivedFunction01/sec-filings-snippets`, `MemGPT/example-sec-filings` | (various) | Bulk historical SEC filings | Offline parquet/text only | None | **NO VALUE — for live filings the routines must use SEC EDGAR via web_fetch, not stale HF mirrors. These datasets are static snapshots.** |
| `XJCEO/Bloomberg_Financial_News` | hf.co/datasets/XJCEO/Bloomberg_Financial_News | 446K Bloomberg articles, 2006–2013 | Offline | None | **NO VALUE — historical only, predates current strategies.** |
| `Brianferrell787/financial-news-multisource` | hf.co/datasets/Brianferrell787/financial-news-multisource | 57.1M rows, 24 sources, gated | Offline | None | **NO VALUE for live; could be used offline by an external researcher for backtest design — but routines can't.** |
| `zeroshot/twitter-financial-news-sentiment`, `zeroshot/twitter-financial-news-topic` | hf.co/datasets/zeroshot/* | Annotated tweets | Offline | None | **NO VALUE.** |
| `finosfoundation/EarningsCallTranscript` | hf.co/datasets/finosfoundation/EarningsCallTranscript | Audio + transcriptions, segmented | Offline | None | **NO VALUE — for live transcripts the routines should use IR sites or licensed feeds.** |
| `m-ric/financial-news-2024`, `ashraq/financial-news-articles`, `edaschau/financial_news` | (various) | Historical news corpora | Offline | None | **NO VALUE.** |

**Universal verdict on HF datasets:** None of these are *routine-consumable* given the connector set (no Python execution). All are offline-only and at best could be used by a human reviewer for backtest construction outside Claude Code. **Do not list any HF dataset as a routine dependency.**

---

## 5. Documentation findings (hf_doc_search)

Two patterns are worth knowing for the experiment:

1. **Spaces as API endpoints / agents.md.** Every Gradio Space exposes `https://<author>-<space>.hf.space/gradio_api/openapi.json` plus an `agents.md` file with schema URL + call template + poll template. Coding agents (Claude Code) can call any Space directly using `gradio_client` or raw HTTP without an HF-specific MCP if the dynamic_space tool is unavailable. This means the `dynamic_space` MCP tool is convenient but not load-bearing — fallback via web_fetch on the OpenAPI spec is always possible.
2. **Inference Providers rate limits.** The HF router (`https://router.huggingface.co/v1/chat/completions`) supports `:fastest`, `:cheapest`, `:preferred` policy suffixes on model IDs. `InferenceClientModel` accepts `requests_per_minute=60` as a self-imposed limit. **Practical implication for this experiment: none — the routines run at fixed schedules (daily/weekly/monthly), well below any rate limit.** No special pacing needed.

**Verdict on docs:** **LOW relevance.** No routine needs to be rewritten because of an HF documentation idiom. The single thing worth recording is that Gradio Spaces have a programmatic OpenAPI spec — but per §3 above, no Space is worth depending on anyway.

---

## 6. Aggregate recommendations

### 6.1 HIGH-VALUE HF resources to call out in `Claude_Task_Plan.md`

For routines **A1 (Annual Re-Derivation)** and **Q3 (Quarterly AI Foundation Delta)** — the PRIMARY HF users — explicitly instruct the routine to run `paper_search` on each of the following query batteries and harvest the most recent (last 12 months) hits:

1. Tier 1 architectural failure modes:
   - "LLM cross-session consistency reasoning variance" → expect ReasonBENCH-class hits.
   - "sycophancy LLM anchoring" → expect Beacon, SynAnchors, SYCON Bench.
   - "LLM calibration confidence uncertainty" → expect MetaFaith, CoCoA evaluation.
   - "deceptive alignment sandbagging situational awareness" → expect Tatemae and successors.
   - "long context LLM lost in the middle" → expect calibrated-attention work.
2. Cross-cutting:
   - "prompt injection adversarial robustness web content" → expect WAInjectBench, BrowseSafe, HTML-prompt-injection.
   - "multi-agent debate adversarial review LLM" → expect Demystifying MAD, MARS, Can LLM Agents Really Debate.
3. Trading/financial:
   - "LLM stock trading financial forecasting" → expect StockBench, FINSABER, Trading-R1, AIA Forecaster.
   - "FinanceBench LLM financial QA SEC" → expect FinanceBench, FinanceQA, BizFinBench, FIRE.

For each query, instruct A1/Q3 to record the 3–5 most-cited / most-recent papers with arXiv IDs in the form `hf.co/papers/<id>` and write a one-paragraph delta summary against the prior version of `AI_Trading_Foundation.md`.

Specific durable repo IDs and Space URLs to seed prompts with:
- Paper hub: `https://hf.co/papers` (browseable).
- StockBench paper: `hf.co/papers/2510.02209`.
- FinanceBench dataset: `hf.co/datasets/PatronusAI/financebench`.
- ReasonBENCH paper: `hf.co/papers/2512.07795`.
- Beacon paper: `hf.co/papers/2510.16727`.
- SynAnchors paper: `hf.co/papers/2505.15392`.
- WAInjectBench paper: `hf.co/papers/2510.01354`.
- Open LLM Leaderboard space: `hf.co/spaces/open-llm-leaderboard/open_llm_leaderboard`.

### 6.2 MODERATE-VALUE — mention but do not depend on
- `PatronusAI/financebench` and FinanceQA/BizFinBench papers as evaluation reference points during A1. Cite, do not query in-loop.
- BBEH paper (`hf.co/papers/2502.19187`) for Q3 capability-delta context.
- MetaFaith calibration paper for the Action Conversion routines' uncertainty discussion.

### 6.3 RESOURCES TO IGNORE
- All HF Spaces in the financial / sentiment / trading-analyst category. Hackathon-grade, low likes, infrequently updated, not durable for a years-long experiment.
- All bulk SEC EDGAR / financial-news datasets on HF. Offline-only, stale snapshots, not API-callable.
- FinBERT / FinancialBERT-Sentiment-Analysis / DistilRoBERTa-financial models. Claude already exceeds them zero-shot per Fatouros et al. 2023 and successors. Adding an Inference API call to one of these *introduces* a sentiment-classification layer with worse recall than the LLM you already have.
- GIFT-Eval / FinMTEB / Salesforce time-series leaderboards. Not LLM evals; irrelevant to the experiment.
- Anything Anthropic/Claude-specific. **HF does not host Claude model cards, internal evals, or Anthropic announcements.** For Claude capability deltas use web_search/Tavily on `anthropic.com`, `docs.anthropic.com`, and Anthropic's research blog.
- Prompt-injection demo Spaces. If injection detection is desired, call `protectai/deberta-v3-base-prompt-injection-v2` (581K downloads) directly via the Inference Providers API rather than via a Space.

### 6.4 Connector configuration recommendations

Beyond the existing **A1** and **Q3** designations:

- **D1 Market Development Scan — ADD HF (light-touch, optional).** Justification: D1's "AI capability light-touch" line item is currently underspecified. Allow D1 to call `paper_search` *only* under a daily cap (e.g., 1 query) targeted at the previous day's HF Daily Papers (`hf.co/papers` trending) to spot frontier-LLM safety/capability news that should be flagged for the next Q3 rather than acted on directly. **Verdict: MODERATE.** Web_search is sufficient most days; HF adds value about once per month when a major paper drops (StockBench-class).
- **Q2 D Long-Horizon Candidates — DO NOT add HF.** Q2 is fundamentals-driven; Claude reading 10-Ks / sell-side notes via web_fetch already exceeds FinBERT-class sentiment. HF adds no capability.
- **W2 Post-Event Screen — DO NOT add HF.** Same reasoning; Claude's zero-shot summarization of an earnings transcript (web_fetched) is at least equivalent to FinBERT/RoBERTa-financial output, and the routine wants a *narrative reading* anyway, not a 3-class polarity score.
- **M2 E Pair Divergence Screen — DO NOT add HF.** Pair narratives are generated from news/filings analysis; FinBERT-class scoring would *flatten* the very narrative divergence the routine is looking for. Active anti-recommendation.
- **M3 D Position Deep-Dive — DO NOT add HF.** Same reasoning as Q2.
- **Adversarial Review (Attacker) — CONSIDER adding HF as a targeted reference.** Attacker should at A1/Q3 cadence pull WAInjectBench/BrowseSafe taxonomies via paper_search to build attack templates. Within-cadence Attacker runs do not need HF. **Verdict: LOW-MODERATE for in-loop use; HIGH for design-time use during A1/Q3 only.**
- **W5 Factbase & Analytics Consolidation — DO NOT add HF.** No use case.

### 6.5 What HF cannot do for this experiment
- Cannot provide live financial data, real-time sentiment, or up-to-the-minute earnings transcripts (use IR sites, EDGAR, or licensed feeds via web_fetch/Tavily).
- Cannot tell you about Claude's behavior. Anthropic does not publish to HF. For all Anthropic-specific information, web_search is the *only* source — HF is irrelevant.
- Cannot host a stateful trading service. Spaces are demo-grade.
- Cannot replace Tavily/web_search for current macroeconomic news, FOMC commentary, or sell-side notes.

---

## 7. One-page TL;DR for `Claude_Task_Plan.md`

> Add to A1 and Q3 prompts: "Run paper_search on hf.co for the queries listed in §6.1 of HF_Resource_Catalog.md; for each, record the 3–5 most relevant arXiv IDs published in the last 12 months and integrate as deltas to AI_Trading_Foundation.md §2 (Tier 1) and §5 (Tier 2 benchmarks)."
> Add to D1 prompt: "Optionally run one paper_search query against `hf.co/papers` daily-papers if any frontier-model safety or capability finding from the prior 24 hours is flagged in the macro scan; capture for next Q3."
> Do NOT add HF to W2, Q2, M2, M3, or W5. FinBERT-class models offer no advantage over Claude's own reading of the same text.
> Do NOT depend on any HF Space, Inference API call, or HF dataset for in-loop execution.
> For Anthropic/Claude specifics use web_search only — HF is silent.

---

## 8. Operational caveats for HF tool usage (verified May 2026)

**These caveats were verified by direct calls to the HF MCP tools during catalog finalization. They reflect actual tool behavior, not the catalog research session's claims.**

### 8.1 `space_search` is unreliable for canonical / popular Spaces

Semantic search via `space_search` does NOT reliably surface the most-popular Space matching a given query. Verified failure case: searching `space_search` with `query="open llm leaderboard"` returned 56 results but the canonical `open-llm-leaderboard/open_llm_leaderboard` Space (13,980 likes, the actual target) was NOT in the top 5 results. Top results instead were tangentially-related leaderboards with lower like counts (GIFT-Eval, BAAI Chinese leaderboard, ASR leaderboard).

**Mitigation pattern for routines that need a known Space:** use `hub_repo_search` with explicit `author=<known-author>` and `repo_types=["space"]` instead. Verified working: `hub_repo_search` with `author="open-llm-leaderboard"`, `repo_types=["space"]` returned the canonical Space as the first result.

**Heuristic:** `space_search` is for *discovery* of unknown Spaces (useful when you don't know what's out there); `hub_repo_search` with explicit author is for *lookup* of known Spaces. Routines that hard-code a target Space should use the latter.

### 8.2 `paper_search` keyword precision matters

`paper_search` uses semantic search across HF's curated paper hub (which substantially mirrors arXiv with curation). Returns up to ~120 matches per broad query; the `results_limit` parameter caps how many are returned. Setting `concise_only=true` returns 2-sentence abstracts instead of full text — strongly preferred for breadth queries to keep context small.

Verified that the search produces the papers cited in this catalog (ReasonBENCH 2512.07795, BrowseSafe 2511.20597, WAInjectBench 2510.01354, AdvWeb 2410.17401, etc.) and surfaces additional relevant papers the catalog did not seed (BeliefShift 2603.23848, WASP 2504.18575). The search is producing better results than the catalog's seeds — A1/Q3 should not feel constrained to only the seeds; the queries themselves are the load-bearing instruction.

### 8.3 `hub_repo_search` is the structural backbone

Verified that `hub_repo_search` with explicit `author` returns canonical repos with full metadata (downloads, likes, tags, last-modified). For known repos this is more reliable than any other discovery path. For Tier 2 benchmark trajectories (Q3 §3a), iterate over the open-weights model authors (`meta-llama`, `Qwen`, `mistralai`, `deepseek-ai`, etc.) with `repo_types=["model"]` and read the model cards.

### 8.4 `hf_hub_query` and `hf_doc_search` not load-bearing

Verified May 2026 — both tools function as described and add no capability the trading routines need. `hf_hub_query` provides natural-language navigation of the HF hub structure and returns structured JSON; it overlaps with `hub_repo_search` for most queries but is less predictable for routine use (natural-language interpretation introduces variance). `hf_doc_search` returns HF/Gradio platform documentation excerpts — no use case in any trading routine per §5 above. Both are available if a future routine needs them, neither is referenced by current A1/Q3/D1 prompts.

### 8.5 No write capability needed

None of the trading routines should write to HF (model uploads, dataset uploads, Space deploys). The HF connector is read-only by design for this experiment. If a write capability appears in a future MCP version, leave it disabled — it is out of scope.

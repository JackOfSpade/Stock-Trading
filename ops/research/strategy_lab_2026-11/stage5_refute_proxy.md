# Stage 5 refutation, lens: is the LLM needed? (non-LLM proxies)

Code and raw outputs: scratchpad p5/ (feat.py, an1.py, an2.py, an3.py, an4.py, out1.txt, out2.txt). All numbers below are post hoc. Sample A = the 300 (score 0 / +1 / one -1), H = the 80 holdout, P = pooled A+H. Returns are 20-day open-to-open net of IWM. "w" = 1/99 winsorized within the sample (H is effectively unwinsorized at n=80). Clustered t = by entry week, 11 clusters in A and H, 12 pooled, so small-G t-values are optimistic.

Proxies (hand-built, not the official LM dictionary): ~40 positive words and ~45 negative words (tone = pos minus neg per 1000 words), a regex count of guidance-raise phrases and of guidance-cut phrases (the cut regex fires on only 2.6% of calls, so it is weak), reaffirm count, counts of "record", "backlog", buyback words, log word count, Q&A share of characters (Q&A start found in 97% of calls), bank flag and biotech flag from vocabulary counts. Also non-text: reaction, |reaction|, log market cap, estimate count, and the 20-day pre-event return net of IWM.

## 1. Replication
A: +1 n=80 mean +3.17%, 0 n=219 mean +0.30%, diff +2.87%, t 2.55. H: +1 n=22 mean +2.55% (median +3.52%), 0 n=55 mean +0.52% (median -0.22%), diff +2.03%, t 0.57. P: diff +2.71%, t 1.84, within-week permutation p 0.018 one-sided (A 0.036, H 0.20). The four -1 events are excluded from these (see section 5).

## 2. Do proxies predict the reader's +1?
Modestly, and more in H than A.
- Univariate AUC for +1 (A / H): tone 0.61 / 0.77; negative-word rate 0.38 / 0.38; guidance-raise flag 0.56 / 0.63; log length 0.60 / 0.46; reaction 0.44 / 0.51; |reaction| 0.48 / 0.58. Everything else near 0.5.
- Multivariate logit (5-fold CV, repeated 20x), text only: AUC 0.60 (A), 0.72 (H), 0.65 (P). Adding reaction and market variables does not help (0.61 / 0.70 / 0.66). Reaction alone: 0.50 in A.
- Train on A, test on H: AUC 0.71-0.74. Train on H, test on A: 0.60-0.62. The top-22 proxy picks in H overlap the reader's +1 on 11-12 of 22 (about 5 expected by chance at the 27% base rate).
So the reader leans toward upbeat, raise-heavy calls, but most +1s are not predictable from word counts.

## 3. Do proxies predict returns as well as +1 does?
No. They predict essentially nothing, and the sign of the tone relation is slightly wrong.
- Spearman rho with w20 (A / H): tone -0.03 / -0.19; raise flag -0.00 / -0.07; backlog count -0.14 / +0.01; Q&A share -0.13 / +0.01; prior 20d drift -0.13 / -0.04; negative rate +0.08 / +0.20. The reader's +1 indicator: +0.13 / +0.10 (P 0.125). No single proxy beats it in both samples with the right sign.
- Cross-validated ridge on the full proxy set, pooled: corr(pred, w20) between -0.004 and 0.024. Train A, test H: 0.04 to 0.17 (the 0.166 is the reaction-only model, driven by |reaction|; text-only 0.04), versus +1 indicator 0.087 in H.
- Selecting the top-22 H events by A-trained proxy score: mean w20 +0.6% (text only) and -0.9% (text+reaction) versus the reader's +2.55%. Top-80 A events by H-trained proxies: +1.4% to +2.1% versus reader +3.17% (and 31-32 of 80 overlap the reader's +1s).

## 4. +1 effect after controlling for proxies
Coefficient on +1, w20, week-clustered SE; scores 0/+1 only.

| controls | A | H | P |
|---|---|---|---|
| none | +2.87% (t 2.55) | +2.03% (0.57) | +2.71% (1.84) |
| reaction, |reaction| | +2.78% (2.37) | +1.73% (0.54) | +2.65% (1.81) |
| + tone | +3.11% (2.45) | +4.02% (1.14) | +3.28% (2.13) |
| + raise/cut flags | +3.07% (2.56) | +4.59% (1.40) | +3.31% (2.35) |
| all text proxies | +3.02% (2.69) | +4.39% (1.04) | +3.04% (2.10) |
| text + reaction | +2.95% (2.48) | +4.50% (1.20) | +3.17% (2.25) |
| + log mc, ne, prior drift | +3.11% (2.64) | +4.19% (1.27) | +3.31% (2.45) |

Other versions: pooled with week fixed effects +3.49% (t 2.52); unwinsorized pooled +3.24% (t 2.29); return residualised on out-of-fold proxy predictions: A +3.20% (t 2.94), H +2.49% (0.66), P +3.26% (2.03). Propensity-stratified (5 strata) ATT: A +2.52%, H +4.90% (3 strata, tiny cells), P +2.77%. Nearest-neighbour matching on the propensity score is unstable: A -0.16%, H +4.96%, P +2.05%. The controls do not shrink the effect; they leave it the same or larger. Mechanical proxies do not explain the +1 premium.

Robustness of the raw gap: leave-one-week-out P range +2.05% to +4.25%. Trimming 5% off each tail of each group: A +2.76% vs -0.26%, H +2.41% vs +0.36%. But dropping the top-k +1 winners only (an unfair test, since it does not trim group 0): H falls to +0.34% after 2 winners and -1.5% after 5, so the 22-event H result rests on a few names (ELMT, ODD, TKNO, RSKD, AORT). Hit rate r20>0: +1 61-64%, 0 47-49%.

## 5. Score -1 events (n=4: 1 in A, 3 in H)
GEMI (A) -6.0% reaction, r20 +26.0%. FLO (H) r20 -9.1%. BETR (H) -5.4%. LCID (H) -26.7%. Mean -3.8% versus +0.4% for score 0; 3 of 4 went the right way, but n=4 and the one A short went sharply the wrong way. Not testable. The 3 H negatives are slightly supportive (a guidance cut, a CEO swap with a dropped target, an expected equity raise).

## 6. Stated driver of every +1 reason (102 read; A 80, H 22)
Primary bucket by reaction at the time of the read (which the reader sees), r20, +1 versus score 0 in the same bucket:

| bucket | A +1 | A 0 | H +1 | H 0 | P +1 | P 0 |
|---|---|---|---|---|---|---|
| drop <= -2.5% ("overreaction") | n33 +4.08% | n74 +0.26% | n9 +3.23% | n18 +1.92% | n42 +3.90% | n92 +0.58% |
| muted (-2.5% to +5%): "good news not priced" | n29 +0.68% | n70 +0.67% | n6 -0.73% | n23 -1.26% | n35 +0.44% | n93 +0.19% |
| jump >= +5%: "drift, mostly priced in" | n18 +5.49% | n75 +0.19% | n7 +4.49% | n14 +1.63% | n25 +5.21% | n89 +0.42% |

This is the most useful finding of the lens. The whole premium sits in the two large-move buckets; where the reader says the market has under-reacted to good news (a third of +1s, the beat-and-raise-but-flat-stock story), +1 earns the same as 0. This replicated in H in sign. About 74% of +1 reasons cite a drop or a big jump, so the +1 label largely encodes "large |reaction| plus a not-awful call", though |reaction| alone has AUC 0.48 to 0.58.

Keyword tags, +1 events only, P (n tagged, mean r20): overdone/overreaction 34, +2.96% (untagged +3.07%); guidance raise language 44, +2.18% (untagged +3.68%); backlog/bookings/pipeline 21, -0.59% (untagged +3.97%); buyback 17, +5.25%; takeover/strategic review 4, +2.43%; bank/credit 11, +0.86%; "drift/already priced" 36, +4.29%; guidance described as conservative 9, +8.07% (mean, median +1.4%); one-offs/tariff refund 14, +0.30%; "yet +1 despite a guidance cut or miss" 7, -2.96%. Stated drivers do not form a clean mechanism: raise language is not better than the rest, and backlog, bank and one-off stories earned about zero or less. Buyback and "conservative guide" stories were highest, on 17 and 9 events, so I would not trust them. Score-0 reasons with the same tags earned ~0 (raise language, n75: -0.03%), which is consistent with the reader adding something on top of the phrase.
Reading of all 102: stated drivers are overwhelmingly a mix of "drop looks overdone" (~35%), "beat-and-raise or strong print, small move" (~35%), "big jump but residual drift" (~25%), and a few takeover/strategic-review optionality names (BVS, RSVR, TCPC). Nearly every reason ends with "limits the score", so the reader is applying a hedge template; the score is about 27% of events regardless.

## 7. Recognition (about 91% of events)
Unrecognized events are few: A 27 (8 scored +1), H 6 (2 scored +1), P 33 (10). Among P unrecognized, +1 averaged -2.19% (median -5.19%) vs score 0 -0.96%; among recognized, +1 +3.60% vs 0 +0.52%. So the premium is entirely in recognized events, which is what firm-history use would predict, but n=10 and the unrecognized group is small enough that this cannot separate "history" from noise. Other checks: the +1 share is the same recognized or not (27% vs 30%); +1 events do not differ from 0 in prior 20d return (A 1.0% vs 0.7%, H -0.1% vs -0.6%), market cap or estimate count; pre-registered condition 6 could not be evaluated (8 unrecognized longs, 0 shorts). Reasons contain details a masked transcript may not hold (rally price levels, "newly IPO'd", named subsidiaries); the average count of reason tokens absent from the transcript is 1.1 for +1 vs 0.9 for 0, and it does not relate to return among +1 (corr -0.02). The reader could be using pre-cutoff knowledge of what the stock traded at, how the prior quarter went, and what the firm's typical guidance behaviour is; none of these is excluded. Names such as Tabacon, Flyover, Flatrock, SpoiledChild leaked through masking in some reasons.

## 8. Does the reader add beyond the mechanical proxies?
On this evidence the premium is not a restatement of the proxies I built: proxies predict +1 only modestly, predict returns not at all, and controlling for them leaves the +1 coefficient at +3.0% to +3.3% (P). That is the part that favours the finding. Against it: (a) the effect lives only in big-move events, so a simple rule using |reaction| plus anything else could have a similar footprint, and I did not build a competing rule (|reaction| alone has rho 0.04-0.15 with returns; in H the reaction-only ridge reached corr 0.17, higher than +1's 0.09); (b) H alone is not significant (t 0.57, with one -2 removal of winners the gap is gone), and the pooled t of 1.84 includes the sample the pattern was found in; (c) the proxy set is crude (short hand list, weak cut regex, no sector control other than bank/biotech flags), so "not explained by these proxies" is weaker than "not explained by any mechanical signal"; (d) the 12 weekly clusters sit in one regime (2026 Q3 earnings season), with 109 and 89 events in two of the weeks.

## Comparison count
Everything is post hoc. Distinct +1-vs-0 effect estimates I tried: about 70 (4 replication, 21 regression/week-FE/unwinsorized/residualised variants, 6 stratification/matching, 12 robustness (leave-one-week, trimming, drop-top-k, 3 permutation), 9 bucket cells, 30 tag cells, 6 recognition cells, 8 proxy-cell splits). Proxy-prediction statistics: about 160 (21 proxies x 3 samples x AUC/rho-p1/rho-w20, plus 4 feature sets x CV/transfer x 3). None was pre-registered. Only the three +1-vs-0 numbers in section 1 and the section 4 coefficients are central; the bucket table (section 6) is the one new pattern and was found by looking, so it needs its own forward test.

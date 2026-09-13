# PARK ALLOCATOR v4 — GRADED ALLOCATION HANDOFF SPEC

Status: **DESIGN COMPLETE, NOT IMPLEMENTED. Owner-mandated handoff** (directive 2026-09-04, in-session:
proportional sizing required + "every other improvement you recommend... complete redesign of how we
handle the allocation of idle capital", full redesign freedom granted). This document is the complete
spec for the implementing instance. It was produced by a 10-agent research/red-team pass (4 recon
including a historical replay against the real tape, 5 adversarial lenses, 1 adjudicator); every rule
below already has the red-team's 15 required changes folded in. Full agent reports:
`~/.claude/projects/-Users-jack-Desktop-My-Apps-Stock-Trading/4f960ac5-f1f1-479b-8ca3-bf5834b4f467/subagents/workflows/wf_0770f68e-cb4/journal.jsonl`
(R1 there holds the exhaustive change-surface inventory; this doc carries the load-bearing subset).
Companion memory notes: `project_park_v4_handoff_state`, `project_park_v4_invariants_draft`.

Until Phase 3 activates, the landed binary **DE-RISK EVIDENCE CARDINALITY** rule (Claude_Task_Plan.md
D1, Operating_Protocols.md §13.F, fixture PA-07, commit 98fd40a) remains the operative rail. Do not
remove it early.

---

## 0. READ FIRST — traps with recorded incidents (likeliest silent violations: 1, 6, 9)

1. **park_allocation_latest HIJACK.** `state.park_allocation_recent.is_call` keys on
   `JSON_VALUE(fields,'$.status') IS NOT NULL`; `_latest` is bare `is_call ORDER BY event_ts DESC
   LIMIT 1`. ANY `entry_type='park-allocation'` row carrying a `fields.status` key written after the
   16:00 call BECOMES the call D2 executes at 17:15. Outcome rows and corrections use a DISTINCT
   entry_type and omit `fields.status`. Worked examples of the safe form: bigquery/213, 214.
2. **Append-only corrections.** Never UPDATE/DELETE `events.*`; corrections are new numbered CALL-only
   files (213/214 precedent); superseded-marker edits to old headers land same commit; NEVER renumber
   a landed `bigquery/*.sql`; run `sp_sq_embed_pending` after any manual decision_log INSERT.
3. **Ask before commit/push** in interactive sessions, always (CLAUDE.md incident 2026-07-21). The
   gate-free posture belongs to the cron fleet only.
4. **Batch pushes; no new crons.** ~4 billable min/push; one push per completed phase; new views ride
   existing D1/D2a runs. Per-push conversion of scheduled work is ~10x cost — settled, don't re-argue.
5. **Worktree isolation.** Routines sweep the shared checkout (commit 98fd40a swept this session's
   uncommitted tree mid-work). Each phase: one worktree, one branch, one push. Review subagents get
   their own worktrees (a reviewer once ran `git stash` on the main tree).
6. **Parity discipline.** Every state/analytics view change needs a token-identical dbt port; live MCP
   apply + repo landing + dbt port + (default-NO) `parity_live_scope.yml` decision = ONE unit of work,
   verified with a fresh `check_live_sql_parity.py` before session end. `sources.yml` carries a live
   `not_null` test on `park_policy_changes.vehicle` — keep it populated (majority sleeve; f=50 tie →
   risk sleeve) or change the test in the same commit. Its "NOT dbt-ported" comment is STALE
   (dbt/models/state/park_policy_current.sql exists) — fix when touching.
7. **Generated files.** `task_plan/*.md` from `split_task_plan.py` (rerun after every
   Claude_Task_Plan.md edit); `ops/triggers.json` from cadence.yaml; editing 00_preamble's park-menu/
   contract lists moves ALL FIVE strategy spec_hashes — recompute same commit.
8. **Timezones / date joins.** New date keys pinned America/Denver; `DATE(ts)` in verification queries
   is UTC and has over-reported before; DATE-grain joins use strict `>` (`>=` admits pre-event rows).
9. **Sign convention.** `dd_from_252d_high` is stored NEGATIVE. The index-axis limb is
   `dd < -0.03`, never "drawdown > 3%". A wrong sign yields a plausible-looking inverted axis.
10. **Alerts.** `sp_raise_alert_once` needs a STABLE message; every new category needs a reachable
    closure path; CI writes `ops.ci_findings`, never `ops.alerts`; durable state keys on tables, never
    on an alert's existence.
11. **Golden.** Fixture rewrites + new fixtures + the hand-maintained count line in scenarios.yaml
    land in the SAME commit as Phase 3; §13's heading text stays byte-stable or all five PA
    `governing_sections` update same commit; `run_golden.py --offline` pre-push; park tokens are
    {GO, NO-GO}; do NOT wire BigQuery writes into golden-scenarios.yml (settled — D3+AR_orc own it).
    The batching-group pin test (`test_golden_section_scope_escape_hatch...`) pins PA-group membership
    — update the pinned id list deliberately, never loosen it to a count.
12. **No price bands.** `fn_order_guard` checks only MARKET/qty>0/ref_price>0 (bigquery/104, owner
    directive). D5's ~2% share-arithmetic cross-check is THIS SPEC's substitute (new in §2.5; evidence
    integrity, not a pre-trade rail — it does not pre-exist in the repo).
13. **Settled, do not re-propose:** 5-day cooldown and HIGH-conviction re-risk gate (both re-measured
    2026-09-03 — they block only the profitable moves), human gates on the park path, Terraform
    adoption, dynamic operating timezone.
14. **Heartbeat.** `loop:park_allocator`'s daily heartbeat (3-trading-day staleness, live body
    bigquery/111) must survive every refactor.
15. **Duplicate-prefix race.** Phases 2 and 3 redefine the SAME objects — a duplicate numeric prefix
    here is the genuine same-OBJECT collision class (unlike the tolerated 114/185/213-214 pairs).
    Check object overlap with any concurrent park-family branch before landing.
16. **Anchor re-assert.** After each phase's live apply:
    `SELECT DISTINCT ai_era_start_date` must equal `2026-07-24`, and TWR-continuity EXCEPT queries
    (old vs new body, both directions, 0 rows) run before applying any park_nav_daily /
    park_counterfactuals successor.

---

## 1. Mandate and measured motivation

**The park** = idle capital (~$15.3k, ~97% of NAV), one vehicle from a 12-instrument menu, chosen
daily by AI judgment (D1 call → D2 conversion → next-open fills, owner confirm-tap per order).

**What v4 fixes** (all re-derived from primary sources, 2026-09-03/04 session):
- The 09-01→09-03 VOO→SGOV→VOO round trip: exit fired on ONE evidence axis, re-entry required TWO;
  cost $214.32 + $107.73 of the $149.18 realized loss reported wash-sale-disallowed at the time (that $107.73 figure was SUPERSEDED 2026-09-04 by bigquery/219 and is now measured at $0.00 pre-rebuy — 13 of its 14 "replacements" were the sale's own basis seen through sibling legs of the same exchange-split order, so a full liquidation was being washed by itself; the realized loss is unaffected, and the 09-04 rebuy is a genuine replacement that does disallow it). Execution blameless.
- AI-era scorecard (anchor 2026-07-24→09-03, post-212 rebase): AI +1.073% vs SGOV +0.402% (+67bp) vs
  never-switch VOO +4.650% (**−357.7bp**) vs rejected rule shadow +2.865% (−179.3bp). Defensive
  excursions **0-for-2**: −2.841pp (SGOV 07-27..08-04) and −1.019pp (SGOV 09-02..09-03). The
  intervening −0.352pp (VOO 08-04..09-02) is the RISK-ON segment BETWEEN them, not an excursion —
  the era opens and closes in VOO, so four policy rows are exactly two CLOSED defensive excursions,
  which is what "4 switches" below already implies. Value-destruction came from defensive
  excursions; all edge over SGOV came from defaulting to VOO. 4 switches / 42 calls — an
  evidence-economics and sizing problem, not churn.
- Two consecutive records overstated a count in the direction of the call (bigquery/213 load-bearing,
  214 harmless). Nothing mechanically verifies cited statistics.
- `shock_overlay` read `acute` 08-14..09-03 continuously — a standing state counted as fresh news.
  `hy_oas` UNTESTABLE for weeks. `conviction_pct` logged on every call, gates nothing.
- Reversal base rates: re-entry cleared ≤2 sessions in 33.3% of 42 analogues; P(VIX back under 20d
  ≤2 sessions | spike setup) = 31%.

**The owner's specific ask:** "a MEDIUM-60 two-axis de-risk moves the same 97% of NAV as a HIGH-95
five-axis one — we need this" → conviction- and evidence-proportional sizing.

---

## 2. Architecture

### 2.1 Two-sleeve book
Risk sleeve (default **VOO**) + defensive sleeve (default **SGOV**). Decision variable = defensive
fraction **f ∈ {0, 25, 50, 75, 100}%**. `state.park_policy_current` generalizes to target weights;
`events.park_policy_changes` rows carry f + sleeve tickers (`vehicle` column stays NOT NULL, populated
as the majority sleeve; f=50 tie → risk sleeve; documented in the ALTER header — a live dbt `not_null`
test depends on it). **CASH may remain a 100% degenerate policy but is BARRED as a sleeve at any
0<f<100** until park_nav_daily carries an explicit cash leg (twr_index is instrument-only; a
fractional CASH sleeve makes the scorecard grade a book that doesn't exist). Phase-2 dry-run asserts
no policy row with 0<f<100 names CASH. Other menu instruments: reachable only via an explicit
SPECIAL-SITUATIONS call (own rationale for why the VOO/SGOV pair is wrong, e.g. duration-rally thesis
→ IEF as defensive sleeve). Menu stays the allowlist rail. VOO↔VTI are treated as
substantially-identical for wash-sale purposes pending owner ratification item 4.

### 2.2 Axis state machine — `state.park_axis_daily` (new view)
Six axes. Each has a **LEVEL** (defensive state, boolean, from primary series) and an **EVENT**
(fired = ENTERED defensive state within the last 2 sessions). Mechanical definitions (conventions
pinned in the view header; these exact forms):

| Axis | Defensive LEVEL iff | Source / reality check |
|---|---|---|
| volatility | VIX > 20d SMA **and** VIX > 15 | SMA built from `events.signal_marks` (park_signal_daily has `vix_med3`, NOT a 20d SMA — the SMA must be built; convention: includes current close) |
| breadth | `EQUITY_BREADTH_PCT` < 66 | `events.regime_events`; carry-forward ≤ 2 sessions, then UNTESTABLE |
| index | SPY < 50dma **or** `dd_from_252d_high` **< −0.03** | `state.park_signal_daily` (dd is stored NEGATIVE — trap #9) |
| rates | 10Y ≥ 4.90 | **LIVE since 2026-09-13.** `events.regime_events` TREASURY_10Y (`numeric_value`), backfilled 2025-07-18.. by bigquery/236, written daily by D2a STEP 1e. Hike-odds limb stays OFF — a deliberate single-limb spec, not a data gap. **Threshold provenance: 4.90 was set with NO firing-rate evidence** (see the note under this table) |
| credit | hy_oas fresh and above bar | UNTESTABLE today (FRED dark, month-old aggregate). HYG/IEF ratio proxy from signal_marks is the candidate feed |
| shock | `shock_overlay='acute'` **and** a commodity/geopolitical PRICE limb confirms (Brent > 95) | NO Brent series exists anywhere in the stack today — the axis CANNOT fire until the feed lands. The overlay alone standing for weeks is a LEVEL, never an EVENT |

Per-axis columns: `as_of_date`, `sessions_since_measured`, `testable BOOL`. A carried level is never
re-stamped fresh. A series coarser than daily grain is UNTESTABLE at daily grain. A never-yet-measured
axis contributes to NEITHER firing counts NOR the standing cap.

**AI judgment preserved:** these are DEFAULTS. The AI may override any LEVEL or EVENT with a named
reason recorded in `fields.axis_overrides` (so decay is defeasible through the same judgment channel
as entry). The cap arithmetic itself is not overridable except via the ±1-step deviation and the
crisis override.

**Phase-1 data decision — MADE AND RECORDED 2026-09-04 (was: choose one; now settled by measurement).**
**Option (a), partial: LAND CREDIT AND SHOCK; RATES STAYS UNTESTABLE AND IS DOCUMENTED.** Verified
this session against live sources, not assumed:
- **credit → LANDABLE NOW, no new feed.** `state.signal_marks_curated` already carries HYG and IEF
  daily, 285 observations back to 2025-07-18. The HY-OAS proxy is the HYG/IEF ratio against its own
  trailing band; it needs no vendor call and no FMP tier.
- **shock → LANDABLE NOW.** FMP `commodity` / `commodities-historical-price-eod-light` symbol
  **`BZUSD`** (Brent) returns clean EOD history on the current plan (verified 2026-09-04). It
  cross-validates against the primary record: BZUSD prints 94.65 on 2026-09-01, exactly the figure
  D1's own 09-01 de-risk record cites. Ingest it into `state.signal_marks_curated` on D2a's existing
  STEP 1d pass — no new routine, no new cron (§0.4).
- **rates → LANDED 2026-09-13.** The daily 10Y now lands STRUCTURALLY as
  `events.regime_events` scope `TECHNICAL_INPUT`, key `TREASURY_10Y`, `numeric_value` — the same
  shape `EQUITY_BREADTH_PCT` uses, so `state.park_axis_daily`'s rates CTE is the breadth CTE with one
  literal changed. History 2025-07-18..2026-09-11 backfilled by `bigquery/236_treasury_10y_signal_feed.sql`
  (287 rows from 288 quotes); D2a STEP 1e writes the row each trading day thereafter.

  **This bullet previously asserted that FMP `economics` returns ACCESS DENIED on the current plan
  tier (verified 2026-09-04), and instructed readers not to re-raise `fmp_quote_plan_gated` for it.
  That was FALSE, and the do-not-re-investigate clause made it self-sealing for nine days.** Re-probed
  live 2026-09-13 against the exact date cited as the denial, `economics`/`treasury-rates` returned a
  full payload for 2026-09-04 (`year10` 4.78, `year2` 4.37). D2a's own `events.regime_events`
  `SUSTAINED_INVERSION` row for that date records the same successful call with the same two figures —
  the routine was demonstrably using the endpoint on the day it was written down as denied — and
  `ops/connector_tools.yaml`'s `economics` entry (`use: required`) never recorded a denial either.
  The real gap was only ever that the 10Y was captured as free text in `rationale`, with no numeric
  column to join on. This is the same "endpoint-level gate wears tool-level wording" trap the FMP tier
  matrix already documents having caused one prior incident (commit d020e50, the 2026-08-26
  `quote`/`batch-quote` case), repeated for `economics` and not caught by the same-day review pass
  (4011a28) that edited text directly beside it.

  **WHAT LANDING IT MOVED — nothing, and that is a measured result rather than an assumption.** The
  §2.7 acceptance f-path is **byte-identical** six-axis vs five-axis (09-01 f=25; 09-02/03/04 f=50),
  and so is the four-arm AI-era aggregate. The reason is arithmetic, not luck: across the 288
  backfilled quotes the 10Y clears 4.90 on exactly **two** sessions — 2026-09-10 (4.95) and 2026-09-11
  (4.96) — and on both of those `cap_pct` was **already clamped at 100** by four other standing axes,
  so `LEAST(100, 25 × standing)` is unchanged when standing goes 4 → 5. The visible deltas are
  confined to `standing_defensive_count` (4 → 5) and `firing_count` (1 → 2) on those two dates,
  `testable_axes` (5 → 6) throughout, and `axis_set_fingerprint`, which now reads
  `breadth+credit+index+rates+shock+volatility`. `ladder_start_date` stays 2026-06-01 because the
  backfill reaches back to the `sessions` CTE's own lower bound.

  **THRESHOLD PROVENANCE — flagged, deliberately not corrected.** On those 288 quotes the axis fires
  **0.69 %** of sessions, against volatility 44.4 %, index 21.1 % and credit 14.3 %. Credit's −50bp
  level came from an explicit REJECTED/ADOPTED firing-rate sweep recorded in bigquery/216's header;
  **10Y ≥ 4.90 had no such study** — it was written while the series was believed unreachable, so no
  firing rate could be computed for it. An axis that fires on 0.69 % of sessions carries very little
  information, and at that rarity it will essentially only ever add standing on days when other axes
  have already engaged the ladder. That is a SPEC question, and §2.2's re-pin rule forbids tuning an
  axis definition to move the numbers — so the threshold is landed **as specified** and the rarity is
  recorded here for the owner to rule on separately. Changing 4.90 means changing this table first.

**Consequence, which the implementer must carry into the acceptance numbers:** the live axis set is
**five** (volatility, breadth, index, credit, shock), not three and not six. `cap = min(100, 25 ×
standing)` is therefore reachable to 100 without the crisis override once four axes stand, so option
(c)'s "f=100 is crisis-only by construction" is NOT adopted. **And per §2.7's re-pin rule, landing the
shock feed CHANGES the pinned replay: Brent closes 94.65 on 09-01 (BELOW the 95 limb → shock NOT
defensive, so 09-01 is unchanged at standing 2 / cap 50 / f=25), but 95.63 on 09-02 and 95.52 on 09-03
(ABOVE → shock ENTERS defensive on 09-02).** On the face of it that lifts 09-02 to standing 3 / cap 75
and, at the logged conviction 60, to f=50 — and then the STRICT decay indexing holds f at 50 on 09-03
rather than decaying to 0. Phase 1's first job is to build the axis view and let the shadow compute
this properly; **the §2.7 acceptance f-path below is the THREE-axis baseline and MUST be re-pinned
from the five-axis shadow in the same commit that lands the feeds.** Do not tune axis definitions to
recover the old numbers — that is the failure mode §2.7's re-pin rule exists to prevent. Note also the
honest direction of this: on the one live episode, the richer axis set makes the ladder look WORSE,
not better. That is exactly the kind of finding Phase 1 exists to surface before any capital moves.

*(Original decision text, retained for the record — **with one CORRECTION flagged 2026-09-13**: option
(a)'s parenthetical "the economics endpoint returned ACCESS DENIED on the current tier, measured
2026-09-04" is **FALSE**. It is left in place unedited because this block is a verbatim historical
record and this repo's convention is to append a correction rather than rewrite the original. FMP
`economics`/`treasury-rates` is not plan-gated — re-probed live 2026-09-13 for that very date. See the
"**rates → not landed YET**" bullet above for the evidence and for what landing the axis actually
requires.)* Choose ONE:
(a) land the three feeds — daily DGS10 via FMP economics, HY-OAS proxy from the HYG/IEF ratio, Brent
via FMP commodity — **verifying FMP plan-tier access FIRST** (the economics endpoint returned ACCESS
DENIED on the current tier, measured 2026-09-04), before the shadow's evidence clock starts; or
(b) renormalize the ladder table to testable-axis count; or (c) document in §13.F that f=100 is
reachable via crisis override only, by construction. **Landing any feed under option (a) re-runs the replay and re-pins §2.7's acceptance f-path and
§3's cost-reduction figures in the SAME commit** — acceptance numbers are always stated against the
axis set actually live. `state.park_axis_daily` stamps its axis-set fingerprint into the shadow's view
header so a stale acceptance table is self-evident rather than something an implementer reconciles by
adjusting axis definitions. `state.park_axis_daily` reports `testable_axes`
weekly through W5; both sides of W5's drift check pin the same anchor AND the same axis set (a
3-testable-axis machine graded as 6-axis is the bigquery/212 wrong-window class).

### 2.3 The ladder (rails on SIZE — same-day binding, no cooldowns, no approval gates)

- `standing_defensive_count` = COUNT of axes whose **LAST MEASURED** level is defensive, over axes
  ever measured. Measurement date never gates membership: a connectors-down day is a no-op (counts
  unchanged → cap unchanged → clamp idempotent); weekend/holiday gaps harmless. A D1 **HOLD** session
  applies NO clamp and writes NO f change. D2's evidence-freshness rail (stale row → HOLD) is
  preserved verbatim for f-target rows.
- **INCREASE (de-risking):** f may rise toward `cap(standing_count)` when (a) ≥1 axis ENTERED
  defensive within the last 2 sessions AND (b) `standing_count ≥ 2`. Cap table: 0→0, 1→25*, 2→50,
  3→75, 4+→100. A single standing axis never engages an increase from 0 (the landed cardinality floor,
  preserved — all 15 measured one-day single-axis episodes in history cost $0). *cap(1)=25 exists for
  the maintenance/decay path only. Deliberate residue, stated for the owner: mid-crash deepening with
  no fresh axis entry licenses no increase except via crisis days or the ±1-step deviation.
- **CRISIS OVERRIDE (entry):** single-session index move ≤ −2.5% or VIX ≥ 28 → treated as 4+ (straight
  to 100 allowed). Measured: 11 qualifying days in ~26 months, all the right days, arriving in 3-day
  clusters; zero since 07-24.
- **MAINTENANCE + DECAY (time-hysteresis; no price hysteresis anywhere):** every session f is clamped
  to `cap(standing_count)`, with: (i) a crisis-entered increase is exempt from the clamp for
  2 sessions; (ii) **the cap steps DOWN on the first MEASURED session at which the lower standing
  count has ALREADY held on the two immediately preceding measured sessions** — i.e. three
  consecutive readings of the lower count, the third being the session that computes and emits the
  clamped call. Unmeasured sessions are skipped, not counted, so an outage gap heals on the THIRD
  measured session post-recovery. Clause (iv)'s 25→0 crossing is EXEMPT from this confirmation —
  that exemption is what makes the 09-03 decay land on 09-03 in the replay. *(This indexing is
  pinned deliberately: the looser reading — counting the session the count first drops as
  confirming session #1 — was simulated over the 284-session tape and produces 36 f-changes /
  72 taps / 7 sub-2-session round trips against STRICT's 31 / 62 / 4, and it re-creates the exact
  07-21 flap §3 credits the confirmation with removing. Do not "simplify" this back.)*
  (iii) any clamp from f ≥ 50 unwinds at most ONE step per session; (iv) a clamp crossing only 25→0
  executes immediately (fast full re-risks preserved — 08-03 and 09-03 were both right). Cap increases
  and AI-initiated re-risk decreases are never delayed. Rationale: the un-dwelled crisis+clamp
  composition was measured as a sell-low/buy-high machine (5 of 6 historical clusters bought back
  higher, −1.3 to −4.3pp per 26 months — several times the allocator's entire +67bp edge).
- **RE-RISK:** decreasing f is always allowed (measured: re-entries have been right).
- **UNTESTABLE FREEZE with release path:** a frozen axis holds its last measured state and cannot
  newly fire. At `sessions_since_measured ≥ 5` with a frozen-DEFENSIVE level, `sp_raise_alert_once`
  fires (stable message keyed on the frozen last-measured date; closure = the axis measuring again;
  frozen-NORMAL axes are inert). While open, every D1 call records keep-counting vs release in
  `fields.axis_overrides` with a named reason. Hard backstop: UNTESTABLE > 20 consecutive sessions →
  the axis drops from the STANDING count (it still can never newly fire), executing through the normal
  session call and decay-confirmation rules — never an out-of-session write. Phase-3 review checklist
  includes: "enumerate every axis-machine state with no exit transition."
- **CONVICTION SIZING (the owner's ask):** suggested target = the step **NEAREST** to
  `conviction_pct × cap`; ties round DOWN (toward less defensive — the measured record's direction);
  AI may deviate ±1 step with a named reason; never above cap. Worked examples: MEDIUM-60 × cap 50 =
  30 → **25**. HIGH-95 × cap 100 = 95 → **100**. Conviction-85 × cap 100 = 85 → **75**. Honest note:
  the CAP does most of the sizing work; conviction moves the answer only near step boundaries. It
  stays in the formula as the owner's ask, but this doc does not oversell it.
- **No f-changing write ever occurs outside a session** (this is what keeps v4 on the right side of
  the v1 rule-table rejection): each D1 session computes the cap, applies decay/confirmation, states
  them, and emits the (possibly clamped) call; D2 converts the weight delta. D1 runs Sun–Thu; the
  Thursday→Sunday dark window is pre-existing and accepted (a Thursday crisis f=100 sitting
  unmodulated ~3 days is named in ratification item 3).

### 2.4 Execution and cash-flow rules (replaces all drafted sweep/band text)

- **SWEEPS** < $1,000: buy ONLY the most-underweight sleeve; if any risk-sleeve loss-sale exists in
  the trailing 30d, route sweeps to the defensive sleeve regardless of underweight. Sweeps ≥ $1,000
  (deposit scale): pro-rata, suppressing any leg under the $25 floor.
- **CONVERGENCE BAND:** converge only when |actual−target| > 10pp AND each resulting leg ≥ $25 — the
  $ term is a per-leg minimum, NEVER an OR-trigger.
- **COVER:** sell from the most overweight-vs-target sleeve; ties/on-target → defensive first;
  empty-sleeve fallthrough to the other.
- **WITHDRAWAL:** an external outflow raises cash pro-rata to target weights whenever a single-sleeve
  raise would breach the band (≈ >$2.6k at f=50 today); below that, defensive-first. Target f is a
  WEIGHT — it re-bases over live park_mv; no policy write for any external flow.
- **NETTING:** before crafting any park leg, net it against any pending or re-crafted opposite-side
  leg for the SAME ticker in `state.open_orders`; craft only the netted order (kills PDT pairing,
  wasted round trips, double-reserved cash). The netted leg is sized off the PROJECTED book (actual
  holdings + all pending same-ticker registry legs), never actual holdings alone; a zero net
  terminalizes the pending opposite row rather than leaving it live.
- **BROKEN ROTATION:** first response is always re-crafting the expired funding leg and bridging one
  settlement cycle; §13.E.4's cover fires only if the debit survives a SECOND cycle, and sells the
  overweight-vs-target sleeve; cover and re-crafted SELL never both stand live for overlapping
  notional. Park step legs ride the existing ORDER_STAGED registry with a stable `item_key` per
  `(sleeve_ticker, side)` — never per (target_f, date) — so a target change supersedes rather than
  stacking siblings. **The step-leg `item_key` namespace stays DISJOINT from `sweep-*` / `cover-*`** —
  supersede-on-same-key is right for step-vs-step and wrong for a sweep; live precedent has a cover
  and a parkswitch leg on the same (ticker, side) coexisting ~23 h on 2026-08-03.

### 2.5 Evidence integrity (Phase 1 — this is the "our mistake" fix, and it ships first)

*(**D5** is the research pass's DELIVERABLE label for this component — that pass numbered deliverables
D1–D7, which collides with the routine-id namespace. **There is no routine "D5" and none is created:**
it is implemented INSIDE D2's PARK ALLOCATION CONVERSION step, `Claude_Task_Plan.md` D2 item 6, per
§0.4 and §13.F's "no new routine, no new trigger, no new cadence entries".)*

- Every numeric claim in a call's rationale must appear in `fields.readings` with source + as-of.
- D2's conversion recomputes counts/threshold-crossings FROM the recorded readings and REFUSES
  conversion when the rationale's arithmetic contradicts them (the bigquery/213 class: counts are
  computed, never asserted). **Polarity is a one-way ratchet:** in the binary era (Phases 1–2) the
  recompute may BLOCK or demote a conversion, and feeds the shadow; it NEVER upgrades a KEEP to a
  conversion or a 1-axis call to 2-axis (mechanical scoring finds MORE 2-axis days — unratcheted, it
  would have flipped the landed rule's $0 KEEP on 09-01 into a −$225 full convert). AI hand-scoring
  stays authoritative for action until Phase 3. D1's new fields contract, D5's recompute, and the
  format fixture land in ONE commit; D5 accepts the legacy readings shape through Phase 2 and
  hard-refuses only from Phase 3. A refusal raises
  `sp_raise_alert_once('park_conversion_refused_evidence_mismatch')` (stable message, details in
  payload; closure = next successful conversion; two consecutive refusals → WARNING). The recompute
  includes the share-arithmetic cross-check: step shares × ref_price within ~2% of Δf × park_mv
  (evidence integrity, not a pre-trade rail — trap #12).

### 2.6 Tax awareness (transparency, not a gate)

A de-risk call states the FIFO-projected realized P&L of the specific step (from park tax lots' open
lots, not position-level unrealized) and the wash-sale-disallowed portion if re-entry occurs within
30d. **A partial step realizes only the lots FIFO actually consumes, so the result is NOT proportional
to Δf and can change SIGN between steps** — project it by consuming `analytics.park_tax_lots` open lots
at the step size actually proposed. Measured on the actual 09-02 book that FIFO schedule is
+$8.86 / −$20.01 / −$58.04 / −$96.91 cumulative at 25/50/75/100% (gross; −$100.06 net at 100%), the
25% step being gain-side — and therefore wash-sale-free — only because the oldest surviving lots that
day were the 6.8877 sh 08-04 block @ 699.25, the cheapest in the book. On a book whose oldest lots are
the losers, a partial step realizes a DISPROPORTIONATE loss. **NOTE THE BASIS SEAM:** the broker's
realized figure for the same full-book sale was −$149.18 (IBKR average cost with the July wash
adjustment, ~707.67/sh, ties to the connector) against repo FIFO's ~705.30/sh — a ~$49 gap that is
BASIS, not commission; the projection is a repo-side estimate and will not equal the 1099-B.
Phase 1 also ships the `state.wash_sale_exposure` refinement: allocate each replacement lot's shares
across qualifying closes oldest-close-first, replacing bigquery/178's per-close independent capping
(which double-counts under ladders). Detection-only; the IBKR 1099-B stays authoritative.

### 2.7 Measurement and learning loop

- `park_nav_daily` successor emits BOTH `target_f` (policy_asof semantics) and
  `actual_defensive_weight` (from holdings CTEs); the one-session policy lead is documented in column
  descriptions; W5's drift check compares the ladder shadow against ACTUAL weight; `target_f` serves
  only the convergence-band read.
- `analytics.park_ladder_shadow` (new, Phase 1): `r_ladder(d) = (1−f(d−1))·r_risk(d) + f(d−1)·r_def(d)`,
  bigquery/179's prev-lag idiom, strict `>` on DATE joins; columns include `ladder_start_date` (first
  date all live axes measurable) and `ladder_index_ai_era` (NULL before
  `GREATEST(ladder_start_date, ai_era_start_date)`); never coalesce an unmeasured axis to "not
  defensive". **ACCEPTANCE RE-PINNED 2026-09-13 TO THE SIX-AXIS SET NOW LIVE** (the three-axis path below is
  SUPERSEDED; kept only to show what moved and why. The 2026-09-04 five-axis re-pin it replaced is
  folded in here rather than kept separately, because landing rates did not move the f-path at all —
  see the next paragraph.) Phase 1 landed the Brent feed (bigquery/217), making the shock axis
  testable, and the 10Y feed (bigquery/236), making rates testable. `axis_set_fingerprint` now reads
  `breadth+credit+index+rates+shock+volatility`. The replay:
  **09-01 standing 2 (breadth, volatility) → cap 50 → f=25; 09-02 standing 3 (shock ENTERS as Brent
  crosses 95) → cap 75 → f=50; 09-03 and 09-04 standing 1 but STRICT confirmation holds the cap at
  75, so f stays 50.**

  **THE SIXTH AXIS CHANGED NO NUMBER IN THIS PATH, and that was verified rather than assumed** — the
  f-path above is byte-identical measured against the five-axis and six-axis views on the same tape.
  The 10Y clears its 4.90 limb on exactly two sessions in the whole backfilled record (2026-09-10
  4.95, 2026-09-11 4.96), and on both `cap_pct` was already clamped at 100 by four other standing
  axes, so `LEAST(100, 25 × standing)` is unmoved by standing going 4 → 5. What did change:
  `testable_axes` 5 → 6, the fingerprint, and `standing_defensive_count` / `firing_count` on those two
  dates only. `ladder_start_date` holds at 2026-06-01.

  Measured four-arm result over the AI era (**34 sessions, 2026-07-24..2026-09-10**), all on one
  close-to-close TOTAL-return ruler inside `analytics.park_ladder_shadow`: never-switch VOO
  **+2.658%** | graded ladder **+2.007%** (3 f-changes, engaged 41.2% of sessions) | actual binary
  allocator **−0.970%** | always-SGOV **+0.502%**. The ladder recovers **+2.977pp** of the allocator's
  shortfall — ~82% of the 3.628pp gap to never switching — while still trailing never-switching by
  0.651pp, and beating always-SGOV by 1.505pp.

  **Note what moved here versus the 2026-09-04 pinning (31 sessions: VOO +4.732% | ladder +2.995% |
  actual +0.758% | SGOV +0.432%), because it is NOT the axis change.** Those figures went stale from
  elapsed tape alone — three more sessions and a market that gave back ground — and the axis-independent
  never-switch arm moved most of all. This is the hazard §2.2's re-pin rule is really guarding against:
  an acceptance table restated only when someone remembers will drift on time even if the machine never
  changes. Read the direction, not the decimals: grading still beats the binary switch (the owner's
  thesis) by a wide margin, and still does NOT establish that the allocator should de-risk at all —
  never-switching remains ahead of every alternative on this tape. n=34 and ONE episode: a direction,
  not a verdict.
  Superseded three-axis acceptance: reproduce the replay table (f=25 only on 09-01/09-02; the 09-02 vol margin
  of 0.04; the 08-11 breadth carry-forward) with these conventions pinned in the header: 20d SMA
  includes current close **and is computed from `state.signal_marks_curated`, NEVER
  `events.signal_marks`** (bigquery/91 mandates the curated view for all consumers; the raw table
  carries a `^VIX / 2026-08-27` duplicate that shifts the 09-02 vol margin from 0.04 to 0.07 and
  would fail this very acceptance test); index limb coded `dd_from_252d_high < -0.03`; breadth
  carry-forward ≤ 2 sessions then UNTESTABLE; decision_log dedup = last well-formed row per Denver
  day; **decay step-down indexing = three consecutive readings of the lower standing count, step on
  the third, 25→0 exempt**; and **SESSION = a trading day from `state.market_calendar`
  (`is_trading_day`), each D1 run being the session for the last trading day ≤ its run date
  (Sunday's run is Friday's session)** — every N-session rule counts against each axis's own
  `as_of_date` in that index, never the run date (D1 runs Sun–Thu, so a holiday week such as Labor
  Day 2026-09-07 otherwise gives two runs sharing one session).
  **Two zero-change decay fixtures**, required because they are the only sequences on the
  2025-07-21..2026-09-03 tape that discriminate the decay-indexing conventions (entering f=50,
  conviction ≥ 0.80, both must produce ZERO f-changes): 2026-07-21/22/23 (VIX 17.05 / 16.64 vs 20d
  17.113 / 16.9705; SPY 748.28 / 747.41 vs 50dma 744.88 / 745.08 — both axes normal on 07-21 and
  07-22, both re-entering 07-23) and 2026-02-25/26/27 (same shape). Structural
  honesty, stated in the view header: the shadow computes from the same axis view, so it is blind to
  frozen-axis stuck states; and it validates only the testable-axis subset (Phase-1 data decision).
- **Excursion outcomes:** rows use `entry_type='park-excursion-outcome'` and carry NO `fields.status`
  key (trap #1). Acceptance: after the first outcome write, assert zero status-bearing non-call rows
  under `entry_type='park-allocation'`; golden fixture asserts an outcome row never surfaces in
  `park_allocation_latest`.
- **Shadow counters:** the shadow reports per-axis boundary-flap counts AND conviction-boundary flap
  counts. At cap 100 the step boundary sits at conviction 62.5 — dead centre of the AI's empirical
  50–76 range with 3–5 point session noise — so conviction flapping is a distinct oscillation source
  from axis flapping and nothing else watches for it.
- **Drift watcher:** D2a raises `sp_raise_alert_once('park_convergence_overdue')` (stable message
  keyed on drift start date) when drift_pp > band for ≥2 consecutive sessions AND no park fill or
  live pending park leg exists; closure = drift in-band or a pending leg appears. **Severities: `park_convergence_overdue` and the
  untestable-freeze alert are both `warning`** — NOT `critical` (which enters `blocking_criticals` and
  would halt order staging including exits) and NOT `info` (which both `alert_relay.py` and
  `alert_emailer.gs` filter out via `severity IN ('critical','warning')`, making it invisible to the
  operator). `park_conversion_refused_evidence_mismatch` is `warning` on first refusal, escalating per
  §2.5. From Phase 3 day 1,
  W5 treats "D2 logged no-op on a day the ladder shadow shows Δf≠0" as a named CRITICAL signature.
- Text corrections owed nearby (same commits as the sections they touch): the Q1 park retrospective
  bullet either lands (outcome rows are its substrate) or §13.F/PARK_ROUTER_DESIGN stop claiming it;
  `sources.yml`'s stale "NOT dbt-ported" sentence; `autonomy_levels`' stale "92 is canonical" prose;
  VOO/VTI equivalence joins into the 178-successor at Phase 4.

---

## 3. The replay's verdict (and its honest limits)

> **RE-PINNED 2026-09-13 against the SIX-AXIS set now live.** Until that date this section had **never
> been re-pinned at all** — not even by the 2026-09-04 five-axis pass (commit d5b4668), which touched
> only §2.7 despite §2.2's rule naming §3's cost-reduction figures explicitly. Its lead bullet had
> consequently gone factually wrong: it described an f-path the machine stopped producing when the
> Brent feed landed. Bullets 1–2 below are re-measured; bullets 3–6 are flagged in place, since they
> rest on reconstructions and base rates rather than on the shadow's current output.

- **08-05..09-03 (22 sessions), re-measured 2026-09-13:** ladder path f=0 through 08-31, then
  **09-01: 25 → 09-02: 50 → 09-03: 50**. Close-to-close: ladder **−0.374%** | actual binary
  **−1.207%** | never-switch VOO **+0.245%** | always-SGOV **+0.306%**. Ladder vs actual
  **+0.833pp ≈ +$127**; ladder vs never-switch **−0.619pp ≈ −$95**.

  *What this bullet used to say, and why it was wrong:* "f=0 every day except 25 on 09-01/09-02,
  decayed to 0 on 09-03. ladder +0.076% | actual binary −1.015% | never-switch VOO +0.441%. Ladder vs
  actual +1.091pp ≈ +$167; ladder vs never-switch −0.365pp ≈ −$56." Two independent drifts are folded
  into that gap and should not be confused. **(a) The axis set richened.** Landing Brent (c0a6c61)
  gave 09-02 a third standing axis → cap 75 → f=50, and the STRICT three-reading decay confirmation
  then HOLDS 50 on 09-03 instead of decaying to 0 — so the ladder now carries defensive weight through
  a session it used to exit. **(b) The tape itself was restated**: even never-switch VOO, which no
  axis can touch, moved +0.441% → +0.245% on the same dates. Landing the rates axis contributed
  **nothing** to either — the 10Y is below 4.90 on every session in this window.
- **The 09-01 episode (re-checked 2026-09-13, still valid):** actual cost −$225 close-to-close
  ($214.32 on real fills). Ladder at f=25: −$56 (**74% cost reduction**). This survives both re-pins
  unchanged because f on 09-01 is still 25 under the six-axis machine — 09-01 has two standing axes
  (breadth, volatility), neither Brent nor the 10Y is defensive that day, so cap 50 and conviction 60
  still round to the 25 step. The landed binary rule's KEEP: $0 — best of all variants, but only
  because the AI hand-counted one axis; MECHANICALLY 09-01 was a 2-axis day (VIX 16.34 > 20d 15.19
  and > 15; breadth 62.62 first sub-66 print), so a mechanical binary rule converts at full size
  (−$225). **The ladder's value is capping mechanically-legitimate conversions at quarter cost, not
  blocking them.**
- **July reconstruction (the strongest motivator, restated honestly):** ladder engages 07-17,
  noise-exits 07-21 on a 0.06-VIX margin (−$52, 4 taps, zero information), re-engages 07-23, decays
  07-31 — two sessions before the actual 08-03 re-risk. Net ≈ −0.60pp vs the actual −2.841pp: **4–5x
  better** (not the ~90% an earlier flap-blind computation implied). With the 2-session decay
  confirmation the 07-21 flap disappears and ~90% is roughly recovered.
- **Oscillation:** zero in the 21-session window, but that window is unrepresentative — over 26
  months the vol axis had 23 episodes, 61% lasting ≤2 sessions, 11 re-firing within ≤2 sessions of
  exit. The fix is TIME-hysteresis (2.3), not price bands: **no price hysteresis anywhere**; re-open
  per-axis bands only if the Phase-1 shadow shows an axis flapping through an ENGAGED boundary
  >~2x/quarter.
- **Tap load:** ~11–15/mo vs today's 10–14. Worst realistic year ≈ 26 step-pairs — fewer pairs than
  the unconstrained binary allocator's annualized 35 — but crisis quarters concentrate (March-2026
  shape: ~6 pairs at 50–75%-of-book scale in 6 weeks). Ratification item 7.
- **Sample honesty:** the live quantification rests on ONE de-risk episode and 21 breadth
  observations, and in that one episode the landed binary rule beat the ladder. The case for the
  ladder is the July reconstruction, the asymmetric-cost logic, and the base rates — not September.

- **Status of the three bullets above (flagged 2026-09-13, NOT re-measured).** The July
  reconstruction, the oscillation base rates and the tap-load projection were computed at design time
  against the then-current machine and are NOT outputs of `analytics.park_ladder_shadow`, so a shadow
  re-run does not refresh them and this pass did not silently restate them. Two are known to be
  axis-set-sensitive and should be re-derived before they are leaned on again: the July
  reconstruction's noise-exit/re-engage dates assume the three-axis standing counts, and the
  oscillation count is a vol-axis-only statistic that says nothing about how six axes interact. The
  tap-load figure is the one most likely to have moved in the WRONG direction — every axis added is
  another way for standing to change, hence another potential step-pair — and adding rates did not
  change it here only because rates is defensive on 0.69% of sessions. Re-deriving all three is its
  own task; flagging them beats leaving them looking freshly measured.

---

## 4. Rollout ruling

Cost structure: fractional-f plumbing ≈ 75–80% of v4 and is identical for any f∉{0,100}; the axis
machine + feeds ≈ 15–20%; D5 ≈ 5%.

**RULING: ship Phase 1 standalone now; hold the Phase-2/3 build until the shadow accumulates 2–3 more
genuine multi-axis episodes (~1 per 6 weeks observed) or the owner explicitly orders immediate build;
then build the FULL five-step v4. No intermediate variant is ever acceptable.**

- **Phase 1 now** — `state.park_axis_daily` (with the one-way ratchet), D5 evidence integrity, the
  ladder shadow, the RC-7 data decision, the wash-sale refinement: ~20–25% of cost, **100% of the
  integrity benefit** (kills the load-bearing-miscount class), starts the evidence clock. It captures
  0% of the P&L benefit — stated plainly.
- **Phase 2** — two-sleeve plumbing, f still mechanically pinned to {0,100}: rewrite in ONE unit of
  work (i) §13.E's stranded-leg predicate → "target weight 0 and held above 0.0005 sh"; (ii)
  bigquery/92's `residual_rows` successor (`is_policy_vehicle` → `is_target_sleeve` + weight,
  preserving the per-sleeve LEFT-JOIN zero-row-gap guarantee); (iii) Claude_Task_Plan.md D2 item 6's
  SELL-craft SELECT; (iv) D2's KEEP/no-op test and EARLY-EXIT checklist → compare TARGET WEIGHTS,
  never a vehicle string (a weight-delta IS a conversion). On completion, write a schema-version
  marker row into `events.park_policy_changes`; D2's checklist REFUSES any f∉{0,100} until the marker
  exists (BigQuery has no CHECK constraints — the guard lives in the checklist, quoted verbatim).
  Acceptance includes the anti-mask fixture: dry-run SELECTs proving a synthetic 25/75 book yields
  ZERO stranded-leg rows and correct per-sleeve reconciliation drift. The pin is MECHANICAL, not
  aspirational prose (green tests miss future-INSERT paths — recorded trap).
- **Phase 3** — ladder + conviction sizing live; supersedes the binary cardinality rule; golden
  rewrites land same commit (PA-01: 3+ axes crisis → GO at f=100; PA-02 KEEP; PA-04 re-risk GO
  untouched; **PA-07 needs NO expected_decision change** — single-axis → bound KEEP + park_watch is
  identical under the ladder floor; only its rationale citation moves). New fixtures: two-axis→cap 50
  with conviction quantization; decay-out with 2-session confirmation; crisis dwell; untestable
  freeze + release; outcome-row non-hijack. Activation is by owner word against a WRITTEN calendar
  checklist (feeds live ≥N sessions; ≥2–3 shadow multi-axis episodes; quantization landed; worked
  examples corrected) — a checklist, never a self-counting readiness gate (the v2 latched-gate class).
- **Phase 4** — special-situations path, VTI equivalence table, adaptive extras.

**Rejected variants (kill chains recorded so no future session re-tries them):**
- Three steps {0,50,100}: same blocking rewrites the moment any f∉{0,100} is legal (~95% of cost),
  half the resolution, and floor quantization maps the owner's headline MEDIUM-60 two-axis case to
  ZERO action.
- Informal partial switch under the current book: **destructive** — §13.E's backstop full-SELLs the
  split within one D2a pass and re-crafts the SELL every session if the tap is declined. The
  backstop's persistence is a feature; give it a machine-readable target, never suppress it.
- Tier-stepping via AOR: every tier step realizes 100% of the book's lots (the measured $107.73
  disallowance shape) vs a 25% step realizing only the moved quarter (+$8.9 gain, zero wash-sale, on
  the actual 09-02 book), plus unchosen duration exposure. This also discharges §11's "AOR covers the
  blend" with numbers.
- Stop at the landed binary rule ("option d"): the strongest cheap baseline — it already delivers the
  highest-EV single intervention (de-risking less) at zero cost, and v4's benefit must be framed
  against IT, not the pre-09-03 status quo. v4's incremental value over (d) is confined to genuine
  multi-axis excursions: ~2.5pp ≈ $385 saved per episode at ~1/6wk observed frequency. If the owner
  reads the scorecard as "stop de-risking entirely," (d) is rational and v4 is over-engineering; v4
  is justified only to KEEP the de-risk capability while capping its measured cost.
- Deferral price of the Phase-2 hold: ~2 episodes ≈ ~$770 foregone ladder savings, against
  mis-building 75–80% of the system on a sample of one live episode in which the ladder LOST to the
  incumbent rule. The wait converts the ratification conversation from argument to data.

---

## 5. OWNER RATIFICATION — seven items, none may be buried

1. **Mechanical decay vs "AI judgment end to end."** Standing: *"v1's deterministic regime→vehicle
   rule table is rejected as the decision-maker — this is an AI-based trading system, and the park
   allocation decision must be AI judgment, end to end"*; *"no thresholds, no lookup table, no
   formula anywhere in the decision path"* (PARK_ROUTER_DESIGN.md). The ladder bounds f's choice-set
   the way the menu bounds the vehicle — rail territory — but the maintenance cap is the park's FIRST
   binding maintenance mechanism ever (prose invalidation sets were never binding), acting only
   THROUGH a daily session that computes, states, and emits the clamped call, with named overrides on
   any axis level or event. A session still decides; rails bound. That is an addition of binding
   authority and only the owner can ratify it.
2. **Conviction sizing vs the 07-26 retirement.** Standing: *"conviction_pct... never gates whether a
   call binds (owner directive 2026-07-26)"*. v4 makes conviction binding on SIZE — a deliberate
   reversal, authorized by the owner's own new ask, presented as reversal, not continuity. Caveat:
   42+ logged calls of conviction_pct had zero consequence — an uncalibrated number is being promoted
   to a control; W5's calibration sample begins at Phase-3 activation and pre-Phase-3 history is
   never pooled.
3. **The 07-26 risk posture itself.** Standing verbatim: *"assume the ai is correct on first analysis
   and accept the risk that ai may be wrong at times... We can always pull out of a trade at any
   time... that's fine with me."* A 2-axis MEDIUM-60 de-risk capped at f≤50 economically assumes the
   first analysis is only half right. The new evidence: the named compensating control has now been
   exercised and priced — defensive excursions 0-for-2, −357.7bp vs never-switch, $214.32 (the $107.73 wash-sale figure once cited here was an artifact, corrected by bigquery/219; the round-trip cost stands) + $107.73
   on one round trip, 33.3% two-session reversal base rate. v4 asks the owner to trade "assume fully
   right" for "size to evidence." Also named here: a Thursday crisis f=100 sits unmodulated ~3 days
   (D1 is Sun–Thu).
4. **VOO↔VTI.** Two standing sentences say VTI *"doubles as the wash-sale alternate after a VOO
   loss-sale"*; the draft says never use it that way. Contradictory — the implementer cannot hold
   both. Recommendation: adopt the conservative reading and edit both standing sentences, noting the
   standing text has the more common tax reading (S&P-500 vs total-market are generally argued NOT
   substantially identical). One explicit owner decision.
5. **Two-sleeve book vs §11's "do not re-propose without new evidence."** Standing: *"Weighted
   multi-vehicle park — deferred option... Rebuilds park machinery and multiplies taps at $9.2k
   scale; AOR covers the blend."* New evidence: (i) the owner's proportional-sizing ask is the
   graduation condition arriving by owner word; (ii) the park is $15.3k; (iii) measured tax asymmetry
   (a partial step realizes only the lots it consumes rather than the whole book — on the actual 09-02
   book a 25% step is gain-side); (iv) "AOR covers the
   blend" refuted with numbers (§4).
6. **Axis view vs the 07-20 evidence-freedom directive.** Standing: *"a briefing view or precomputed
   table is evidence the session may weigh or override, never a mechanical input."* The 07-20 sweep
   granted INPUT-side freedom; output-side rails were expressly not relaxed. The ladder is an
   output-side rail; the named-override channel is the judgment path. The tension is named here so
   the owner sees it, not discovers it.
7. **Tap and burst profile.** ~11–15 park taps/mo average; fewer annual pairs than the binary
   allocator's realized 35; but crisis quarters concentrate (~6 pairs at 50–75%-of-book scale in 6
   weeks, March-2026 shape), and per bigquery/104 the confirm-tap is the SOLE discretionary backstop
   — now exercised ~4x as often at quarter blast radius each. Ratify the burst shape knowingly.

---

## 6. Implementation order for the handoff instance

1. Read this doc end to end, then the journal's R1 inventory (exhaustive change surface) and the
   adjudication (full text: `scratchpad/v4_verdict.md` of session 4f960ac5, or re-derive from the
   journal's final result line).
2. Present §5 (ratification) to the owner; obtain the Phase-2/3 timing decision (§4 ruling: shadow
   first) and the RC-7 data decision.
3. Phase 1 in a worktree: axis view + shadow + D5 + wash-sale refinement + heartbeat/parity/dbt
   discipline per §0. One branch, one push. The Phase-1 acceptance list is in §2.7.
4. Phases 2–4 per §4, each its own worktree/branch/push, each with its acceptance fixtures, each
   ending with the §0-16 anchor re-asserts and a fresh live-parity run.
5. The binary cardinality rule and PA-07 stay operative until Phase 3's commit removes them.

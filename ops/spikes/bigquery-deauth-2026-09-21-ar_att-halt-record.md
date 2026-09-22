# BigQuery connector de-auth, 2026-09-21 — the AR_att slot's halt record

**Status: HALT RECORD, CLOSED as a run. Nothing was written anywhere — no `ops.run_log` row (not even `started`), no `events.adversarial_reviews` transcript, no `events.queue_events` transition, no `ops.alerts` row, no artifact attacked.** Author: Claude (agent), AR_att (Adversarial Review Attacker) slot of 2026-09-21, fired on schedule.

**SAME INCIDENT, SAME THREAD.** Sibling records, all four slots of one outage: `bigquery-deauth-2026-09-21-d1-deferred-writes.md` (degraded), `bigquery-deauth-2026-09-21-d2a-halt-record.md` (halted), `bigquery-deauth-2026-09-21-d2-halt-record.md` (halted). This record does not restate their content. AR_att is the **fourth** slot lost to this outage and the **first non-capital, non-order-staging** routine among them — which is the only reason it is worth its own file rather than a fourth append: its failure mode is not a missed trade, it is a **falsely clean review-lane record**, and nothing in the three sibling records covers that.

**Read first:** `Claude_Task_Plan.md` §Observability → connector pre-flight; `Claude_Task_Plan.md` §Adversarial Review Attacker (and its new CONNECTOR-DOWN DISPOSITION limb, landed with this record); `ops/RUNBOOK.md` §15 / §26.

---

## 1. What happened

The Google-Cloud-BigQuery MCP connector is de-authed. **The BigQuery tools were not exposed to this session at all** — the same signature the D2a and D2 slots recorded hours earlier, and distinct from a call that fails: there was nothing to call, so the pre-flight read (`SELECT * FROM state.trading_day_today`) was **unexecutable rather than failing**. Two independent confirmations, both captured this run:

- A tool search for the BigQuery execute-SQL tools returned **no matching deferred tools**.
- The harness lists `Google-Cloud-BigQuery` under *"MCP servers require authentication before their tools can be used"*, and states this session is non-interactive so the OAuth flow cannot be run from here.

This is the documented **token-expired / re-auth** class, which §Observability's pre-flight bullet routes **past** the TRANSIENT-FAILURE WAIT-AND-RETRY ladder as explicitly non-waitable. No retry was attempted and no re-probe was run — one incident, one thread.

**It is NOT the RUNBOOK §54 platform `403 authentication_failed` class.** That class kills the session mid-run and leaves an orphaned `started` row. This session is alive, and the **IBKR connector is live and healthy** (§4). The failure is scoped to the BigQuery MCP server's own OAuth, exactly as D1 first reported.

**THE OPERATING-PLANE DATE IS 2026-09-21, NOT 2026-09-22, AND THE DISTINCTION IS LOAD-BEARING FOR THIS FILE'S NAME.** Measured at pre-flight: UTC `2026-09-22 00:08`, **Denver `2026-09-21 18:08` (Monday)**, New York `2026-09-21 20:08`. The `today` this routine scans against comes from `state.trading_day_today`, and every `due_date` / `attacker_due_date` / `orchestrator_due_date` in the `PENDING_REVIEW` lane is keyed to the pinned `America/Denver` OPERATING plane (`bigquery/20_user_prefs.sql`). So this fire's `run_date` is **2026-09-21** and this is the **same Denver day** as the three sibling records — one outage, four slots, one date. A session reading the UTC clock would have filed this as `2026-09-22` and split one incident across two dates in the spike directory; that is precisely the plane-mixing error the AR_att section's own 2026-09-17 pin exists to prevent, caught here by measuring both planes rather than trusting the ambient date.

## 2. Disposition: HALT — and why the quiet-day line is the trap, not the blinding

**AR_att HALTS. It does not degrade, and it does not scan.** The argument is structural rather than a matter of degree, and it is stronger here than in D2a's Step 0 case:

| AR_att step | Sole surface | Runnable with no connector? |
|---|---|---|
| STEP 0 stranded-transcript reconciliation | join `state.open_queue_detail` × `state.adversarial_reviews_current` | No |
| Due-entry scan (`attacker_due_date <= today AND status = pending`) | `state.open_queue` | No |
| RESIDUAL SWEEP | `state.open_queue_detail` | No |
| The attack transcript | `ops.sp_write_adversarial_review` | No |
| The `attacker-complete` transition | `events.queue_events` | No |
| Every alert this section can raise | `ops.sp_raise_alert_once` | No |
| Run logging | `ops.run_log` | No |

**Both its sole input and every one of its outputs are BigQuery.** There is nothing to run, and nothing to run *into*.

**THE ONE THING THIS SLOT COULD PHYSICALLY HAVE DONE IS THE ONE THING IT MUST NOT DO.** Exactly as D2's carve-out list decomposed to a single performable trap (`Watchlist.md`), AR_att's does too — and its trap is worse, because it requires no tool at all. The no-op branch's chat line, **"No adversarial reviews due for attacker today."**, is pure text: a halted session can emit it with zero connectivity, and it would look identical to a genuine quiet day.

Emitting it would be a **fabricated measurement**. The section grants exactly three mechanical grounds for a quiet day — STEP 0 clean, no due entry, RESIDUAL SWEEP clean — and this fire has **none of the three**, because all three are BigQuery reads it could not perform. It would also convert an **unreadable** queue into an **asserted-empty** one, the precise UNKNOWN-vs-empty error D2's limb pins for `state.open_queue` ("Record an unreadable `state.open_queue` as UNKNOWN, never as empty — the two are indistinguishable from a halted session and guessing 'empty' fails silently"). And unlike a missed trade, it leaves **no downstream evidence of itself**: a falsely clean AR_att record is indistinguishable from a real one forever after.

**STRICT BLINDING is not loosened by the halt, and offers no escape hatch.** A halted slot must not go hunting for a repo-file substitute for the queue. There is none — `Pending_Adversarial_Reviews.md` is RETIRED under the write-redirect — and manufacturing one would breach both the blinding and the State-provenance rule in the same act.

## 3. What the halt cost — stated as unevaluated, not as clean

| Owed by this slot | Status | Recoverable on replay? |
|---|---|---|
| STEP 0 stranded-transcript reconciliation | **Unevaluated** | **Yes, exactly.** Self-healing by design — STEP 0 exists precisely as the backstop for a fire that ended without advancing, and a stranded row stays visible to the next fire. |
| Due-entry scan + any attack it would have produced | **Unevaluated** | **Yes, exactly.** The scan is a pure function of BigQuery state at replay time; an entry due 09-21 is still due (and overdue) on replay, against the same git-committed artifact that `p_source_commit_sha` pins. Nothing in the artifact decays. |
| RESIDUAL SWEEP | **Unevaluated** | **Yes, with one caveat** — the sweep is condition-keyed and heal-resolved, so a stray row that became drainable *during* the outage is never flagged at all. That is the heal rule working as designed, not a defect, but it means the sweep's coverage of this window is permanently a gap rather than merely deferred. |
| Due-date discipline for any entry due 2026-09-21 | **Slipped** | **No.** Anything due today slips at least one day, and its paired `orchestrator_due_date` slips with it. |
| `ops.run_log` `started` + terminal rows | **Never written** | **No — and must stay a permanent gap by design.** |

**THE CASCADE IS DETERMINISTIC AND IS THE LARGEST SINGLE COST HERE.** AR_orc's due predicate requires `status = 'attacker-complete'`, and that row is **AR_att's exclusive write surface** — AR_orc is explicitly forbidden from manufacturing it, because doing so would self-certify the attacker/orchestrator handoff. So **one AR_att halt deterministically costs the paired AR_orc slot as well**, even if the connector is restored before AR_orc fires. On replay the pair must be run **in order**, AR_att first; an AR_orc run that precedes it will correctly find nothing and must not be read as a quiet lane either.

**WHAT WAS DUE TONIGHT IS UNKNOWN, AND IS RECORDED AS UNKNOWN.** `state.open_queue` was unreadable and no repo file mirrors it.

**A BASE RATE IS AVAILABLE, AND IT IS NOT EVIDENCE.** The AR_att section carries a pinned, measured enqueue distribution for this lane: on the Denver plane, enqueues land on nine dates in the lane's life, the last being **2026-09-05**, making the gap open tonight **16 days**; the documented Denver gaps are 1, 2, 4, 6, 8, 20, 24, 27 days, so 16 days sits comfortably inside the healthy distribution. The lane's **only recurring producer is the month-start `divergence-review` batch** (07-01, 08-03, 09-01 — next expected ~10-01); every other enqueue is episodic. **Read that as a prior on how much was probably lost, never as a finding that nothing was due.** The section is explicit that a multi-week empty lane "neither reassures nor alarms," and a halted fire has strictly less standing to draw a conclusion from it than a healthy one does.

## 4. Perishable connector evidence, captured so the replay does not have to invent it

Measured 2026-09-21 ~18:0x MT:

- **IBKR connector LIVE.** `get_order_instructions` → `{"instructions":[]}`; `get_account_orders` → `{"orders":[]}`. This is the third independent confirmation across the outage (D2a ~16:5x MT, D2 ~17:1x MT, AR_att ~18:0x MT) that the staged-order registry is empty and nothing is stranded at the broker.
- **Git history COMPLETE.** HISTORY-DEPTH PRECHECK step 1 (`git rev-parse --is-shallow-repository`) printed **`false`**, so no deepen was owed and step 2 was correctly **not** run. 1,502 commits reachable from `origin/main`, oldest `e7be4c0` dated 2026-05-08. **Every history claim in this file is therefore conclusive, not boundary-limited.**
- **Incident calendar event** `09q69g3odvhhbiom3drf15uc60`, created 2026-09-21 22:10 UTC by the D1 slot, last updated 23:22 UTC, already carrying the D2a and D2 appends.

## 5. Recorded for their owning surfaces, not acted on from a halted run

- **THE ONLY SURVIVING CHANNEL IS FULL, AND IT FAILED SILENTLY — NEW THIS RUN, AND THE MOST IMPORTANT FINDING IN THIS FILE.** The incident calendar event's description **ends mid-clause**, at "`…B is DO-NOT-ACTIVATE and capital-disabled, and the event dates`", with no closing sentence, no sign-off, and no `====` separator. Measured: two independent API reads (`search_events`, then `get_event`) returned a **byte-identical** truncation at that exact point, and the Google Calendar API does not truncate descriptions on read. **Therefore D2's append was clipped on WRITE**, consistent with the API's 8,192-character `description` cap, which the three existing blocks essentially exhaust. D2's slot received no error it recorded, and the loss is invisible from inside the thread — you can only see it by noticing that a careful author ended a sentence in the middle.

  **This is a defect in the one channel the whole connector-down design depends on.** §Observability is explicit that when BigQuery is down, `ops.alerts` is unreachable and `alert_emailer.gs` has nothing to poll, so "a calendar event is the ONLY surviving channel for this one branch" — and INCIDENT INHERITANCE then routes *every* subsequent routine's escalation into that single event's description. The mechanism therefore **degrades silently with each append and has already lost data on the third**. The exposure is worst exactly when it matters most: a long or wide outage produces more appends, so the channel's capacity falls as the incident grows, and the content lost is the newest — the most recent slot's measured cost account.

  **AR_att's disposition on it: this slot deliberately did NOT amend the event.** `update_event` replaces the `description` wholesale — there is no append primitive — so adding AR_att's block would have required rewriting all ~8 KB and would either have clipped further or destroyed D2's block, which holds the sole record of the deferred park re-risk (~$3.79k of a $15.9k account) and its conviction-15 proportionality note. **Trading a capital-path record for a courtesy line about a non-capital routine is a bad exchange, and the cap means the courtesy line probably would not have persisted anyway.** The operator's required action — re-authorize the connector — is unchanged by this run and is already stated at the top of the event, so nothing actionable is lost by the omission. AR_att's content lives here instead, which is where D2a and D2 put their own full records too ("Full verbatim capture is committed to the repo at `ops/spikes/…`"); the calendar carries the alert, the repo carries the record. **A halted slot must not damage the incident thread in order to sign it.**

  **Durable fix (not AR_att's to land):** the incident thread needs an append target that does not silently cap — the natural form is to keep the calendar event as the short, stable ACTION-REQUIRED banner and point it at a single per-incident repo file that each slot appends to, with the event description rewritten only when the *required operator action* changes. Whoever lands it should also re-read D2's clipped block and restore its lost tail from `bigquery-deauth-2026-09-21-d2-halt-record.md`, which has the full text. **Owner: W5 SPEC-DEFECT NOTICE INTAKE, or OPS0.** Recorded here and not in `ops.alerts`, which is down.

- **RESOLVED — the open question D2a's append left for today.** D2a flagged that if D2's 2026-09-17 park re-risk legs (SELL 37.1486 SGOV / BUY 5.3013 VOO, filled 2026-09-18) had *not* been cleared from the staged-order registry by the 2026-09-20 slot, they would cross the 120-hour `staged_order_reconciliation_overdue` bar around 2026-09-22 evening UTC — with **OPS0, which owns that escalation, blind on this same outage**. The read in §4 settles it: `get_order_instructions` and `get_account_orders` are **both empty**, so the legs **were** cleared and **that bar will not be crossed**. This is out of AR_att's scope and is recorded, not acted on; it is carried into the calendar thread because `ops.alerts` — the ordinary channel for an informational finding — is itself down. **Owner: OPS0.**
- **The grant-expiry cadence, now at four.** 2026-06-26, 2026-08-23, 2026-09-14, 2026-09-21, against a **quarterly** proactive re-auth reminder (next fire 2026-10-01); three of the four were found by a routine hitting the wall rather than by the reminder. D2a already raised this. AR_att's slot adds only that the **blast radius is wider than the capital path** — a single expiry now demonstrably takes the review lane down too, and the review lane has no broker-side fallback of any kind. **Owner: the operator (reminder cadence) / W5 (spec-defect intake).**
- **NOT re-filed here:** the open `ops.alerts` info rows `review_lane_enqueue_silence_unwatched` and `adversarial_review_referee_rows_unhashed`. Both are already on the record with W5 as owner, both are unreachable from a halted run anyway, and the AR_att section explicitly says a later fire should cite them rather than re-file.

## 6. The plan edit this run landed

`Claude_Task_Plan.md` §Adversarial Review Attacker gains its own **CONNECTOR-DOWN DISPOSITION** limb, mirroring the ones D2a and D2 landed hours earlier in this same incident, plus a one-sentence cross-reference from the shared §Observability pre-flight bullet so the next reader finds it from either end. It pins the HALT, the structural reason (§2), the quiet-day-line trap, the AR_orc cascade, and what a halted slot still owes.

**THE GAP HERE IS A DIFFERENT SHAPE FROM D2's AND D2a's, WHICH IS WHY IT IS ITS OWN LIMB AND NOT A CROSS-REFERENCE.** Theirs were *over*-specification: a nearby sentence ("STEP 0 RUNS UNCONDITIONALLY"; the six-item "NOT BLOCKED, ever" carve-out) that read like an override of the shared halt branch. AR_att's is an **asymmetry between two clauses of the same bullet**, verified this run: the pre-flight bullet's scope sentence binds "ALL routines: D1–D3, OPS0, W1–W5, M1a–M5, Q1–Q4, A1–A3, **and the adversarial attacker/orchestrator**" — naming the AR pair explicitly — while the BigQuery-unreachable branch four sentences later dispositions **only** D1 and D2/D2a/D3, names no catch-all, and names neither half of the pair. A full-file search for `CONNECTOR-DOWN`, `DEGRADED MODE`, `unreachable`, `de-auth`, `every other routine` and `all routines`, plus RUNBOOK §15/§26/§53/§54, found nothing that closes it by class. **So AR_att was explicitly ordered to run a probe and given no consequence for failing it** — a strictly worse gap than silence, because the routine is directed into the wall and must then invent its own disposition at the moment it is least able to record the invention.

**This is n=4 for the same defect class in a single outage** — a routine reaching a connector-down pre-flight and finding its own section silent, then deriving the disposition unaided. D1 derived it ad-hoc on 2026-06-26; D2a derived it twice (2026-08-23, 2026-09-21) before landing a limb; D2 landed one the same evening; AR_att makes four. The per-routine limbs are each correct and each load-bearing, but **four independent derivations of an unwritten rule is a missing shared contract, not four coincidences.** The durable fix is a fleet-wide connector-down disposition table in §Observability that assigns *every* routine a branch by class — so the fifth routine reads its answer instead of deriving it. That is not AR_att's to land. **Owner: W5 SPEC-DEFECT NOTICE INTAKE, or OPS0.** It is recorded here and in the calendar thread rather than in `ops.alerts`, which is down.

## 7. Recovery procedure

1. **Re-authorize** the Google Cloud BigQuery connector in claude.ai connector settings.
2. Expect the normal outage signature — `missed_run` + staleness alerts for the slots lost — and resolve per RUNBOOK §26. These are the outage's footprint, not new faults.
3. Land D1's ten deferred writes, then replay **D2a → D2 → D3** for 2026-09-21 (per the sibling records).
4. Replay **AR_att, then AR_orc**, in that order (§3). AR_att's replay runs its ordinary sequence from the top — STEP 0, due scan, RESIDUAL SWEEP — with no special handling: nothing about this halt requires a repair path, because nothing was half-written.
5. **Never backfill this slot as `completed`.** No `ops.run_log` row exists for it and none should be manufactured. The commit carrying this record deliberately does **not** lead with the routine id `AR_att`, which `scripts/auto_merge_decision.sh` (`marker_routine_from_subject`, where `AR_att` is a matched token) plus `bigquery/38`'s `sp_backfill_run_log_from_markers()` would otherwise parse into a phantom `completed` row.

## 8. Disposition summary

| | |
|---|---|
| Slot | AR_att (Adversarial Review Attacker), 2026-09-21 (Denver plane) |
| Disposition | **HALTED** at connector pre-flight. Not degraded, not partially executed. |
| Artifacts attacked | none |
| BigQuery rows written | none, of any kind, in any dataset |
| Calendar | **no second event created**, and the existing one deliberately **not** amended — its description is at the API cap and D2's append was already clipped on write (§5). Alert banner and required operator action are unchanged and intact. |
| Queue drain for 2026-09-21 | **UNKNOWN** — never recorded as empty |
| Quiet day reported? | **No.** All three grounds for one were unevaluated. |
| Repo changes | this record + the AR_att CONNECTOR-DOWN DISPOSITION limb |

# D1 2026-11-05: single-name `research-screen` row not landed

**Status: OPEN.** Author: Claude (agent), D1 run of 2026-11-05 (session `eacaf4d9-977f-5d0f-9de6-2ee8ee3b23ac`).

The 2026-11-05 router-gated single-name move screen (138 passed, 452 compact rejections, 2 dropped below the floor on IBKR)
was generated with `scripts/decision_call.py` into the files in this directory (7 full parts + 1 short part + `call.sql`;
call digest `cb7a075850ab0925e780fdeece52c2f976f711dade4cc32943e90c1606800127`).
The issuing sub-agent staged `part_fields_01.sql` (one row in `ops.decision_call_parts`, verified by readback) and was then
stopped by a provider safety filter while sending part 2. Nothing was written to `events.decision_log` for this screen.
The harness instructed the orchestrator not to take over that agent's work after the safeguard stop, so D1 did not issue the remaining files.

**To land it (interactive session, `ops/RUNBOOK.md` §57):** first run `readback.sql`; if no row exists,
issue every `part_fields_*.sql` verbatim, one at a time (part 01 returns `already_present`), then
`call.sql`, then `readback.sql`. Never retype a file. `single.json` is the source the files were generated from.

Downstream effect: `Daily.md` 2026-11-05's 138 `watchlist` actions carry
`source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-05-single-name-screen-unlanded)` until it lands.
In-run issue `research_screen_write_refused` was filed on 2026-11-05.

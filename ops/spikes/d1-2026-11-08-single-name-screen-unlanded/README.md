# D1 2026-11-08: single-name `research-screen` row not landed

**Status: OPEN.** Author: Claude (agent), D1 run of 2026-11-08 hosted inline by OPS2 (session `session_018igQG2TVr8aqdWb1AozdP2`).

The 2026-11-08 router-gated single-name move screen (session 2026-11-06: 63 passed, 216 compact rejections, 4 dropped below the floor on IBKR)
was generated with `scripts/decision_call.py` into the files in this directory (4 parts + `call.sql`;
call digest `75e5d8d25e1a8014f76da3c44d1efc1b1bd17712d71f523e7d2a34f3907c5111`).
The issuing sub-agent staged `part_fields_01.sql` (outcome `staged`, job `job_9zmgXRsEmBTIC_xEk0fva7S-jC7B`) and was then
stopped by a provider safety filter while sending part 2. Only a truncated copy of part 2 reached BigQuery, and it was rejected with a syntax error before any job ran, so nothing was staged for part 2 and nothing was written to `events.decision_log` for this screen.
The harness instructed the orchestrator not to take over that agent's work after the safeguard stop, so OPS2/D1 did not issue the remaining files. This is the same failure shape as 2026-11-05 (`ops/spikes/d1-2026-11-05-single-name-screen-unlanded/`).

**To land it (interactive session, `ops/RUNBOOK.md` §57):** first run `readback.sql`; if no row exists,
issue every `part_fields_*.sql` verbatim, one at a time (part 01 returns `already_present`), then
`call.sql`, then `readback.sql`. Never retype a file. `single.json` is the source the files were generated from.

Downstream effect: `Daily.md` 2026-11-08's 63 `watchlist` actions carry
`source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)` until it lands.
In-run issue `research_screen_write_refused` was filed on 2026-11-08.

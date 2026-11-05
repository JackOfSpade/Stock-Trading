# D1 2026-11-04: single-name `research-screen` row not landed

**Status: LANDED 2026-11-05** by an interactive session, entry_id `7701d3bc-1d7c-4a3b-9de8-3bf1eb1d91e3`, outcome `written` with the digest below, 93 passed read back. Originally OPEN. Author: Claude (agent), D1 run of 2026-11-04 (session `session_018igQFzEmKHQYowAkqeVnfN`).

The 2026-11-04 router-gated single-name move screen (93 passed, 574 compact rejections) was generated
with `scripts/decision_call.py` into the files in this directory (5 full parts + 1 short part + `call.sql`).
The issuing sub-agent staged `part_fields_01.sql` and was then stopped by a provider safety filter before
issuing the rest. Nothing was written to `events.decision_log` for this screen. D1 did not issue the files
itself after that stop.

**To land it (interactive session, `ops/RUNBOOK.md` §57):** first run `readback.sql`; if no row exists,
issue every `part_fields_*.sql` verbatim, one at a time (part 01 may return `already_present`), then
`call.sql`, then `readback.sql`. Never retype a file. `single.json` is the source the files were generated from.

Downstream effect: `Daily.md` 2026-11-04's 93 `watchlist` actions carry
`source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-04-single-name-screen-unlanded)` until it lands.
In-run issue `research_screen_write_refused` was filed on 2026-11-04.

# Temporary routines for the prospective test

**These routines are TEMPORARY. Request deletion after the final report on 2027-01-04.**

- `[TEMP] Strategy lab reads`: weekdays 13:05 UTC (08:05 ET). It finds nothing to do after 2026-12-01.
- `[TEMP] Strategy lab score`: once, 2027-01-04 14:00 UTC (09:00 ET). It emails its result by raising an owner alert.

They are not in `ops/cadence.yaml`, `ops/triggers.json`, `ops/trigger_ids.json` or `ops/routine_backup.json`, on purpose. The RemoteTrigger API has no delete action: Claude can disable them, and the owner deletes them in the claude.ai routines page. Tags under `strategy-lab/prospective/` hold the code and ledger; keep them until the result has been copied somewhere durable, then they can go too.

The earlier local desktop tasks `strategy-lab-prospective-reads` and `strategy-lab-prospective-score` are replaced by these routines and should be disabled.

The live routine prompts are the source of truth. Read them with RemoteTrigger `get`.

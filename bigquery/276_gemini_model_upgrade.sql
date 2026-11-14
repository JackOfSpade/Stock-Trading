-- bigquery/276_gemini_model_upgrade.sql (2026-11-14)
-- Project: stock-trading-498512.
-- Apply after bigquery/02_ai_layer.sql and bigquery/11_theater_judge.sql (it redefines one object
-- each of those files creates, so DR rebuilds must run them first, in order).
--
-- WHY. The fleet's AI policy (ops/AI_MODEL_SELECTION.md) says to always use the LATEST model in a
-- family, and the owner chose the newest Gemini that has a free tier = gemini-4-hydrogen. Read on
-- 2026-11-14 from Google's Gemini Developer API pricing page (aistudio.google.com/docs/pricing), the
-- free tier covers gemini-4-hydrogen, gemini-3.8-flash, gemini-3.6-flash, gemini-3.5-flash-lite,
-- gemini-3.1-flash-lite, gemini-embedding-2 and gemini-embedding-001; gemini-4-carbon and
-- gemini-4-argon have NO free tier. gemini-2.5-flash — the old ENDPOINT here and the old column
-- default — is deprecated (no longer selectable in AI Studio, and API requests auto-route elsewhere
-- from 2026-12-01), so leaving it in place would silently move the judge off the model its own rows
-- record.
--
-- PROBE (live, read-only, 2026-11-14): AI.GENERATE over connection stock-trading-498512.us.vertex
-- answered "OK" for endpoints gemini-4-hydrogen, gemini-3.8-flash and gemini-2.5-flash, so
-- gemini-4-hydrogen is callable from BigQuery through this connection today. Vertex AI (BigQuery) has
-- no free tier — each call is billed — but the volume is tiny (~170 judge calls per 90 days), so the
-- upgrade costs cents.
--
-- WHAT THIS DOES, and nothing else: (1) moves the analytics.theater_judge.model DEFAULT that
-- ops.sp_score_theater relies on (it never sets `model` itself, so the default stamps every row), and
-- (2) repoints the ops.gemini remote model at the new ENDPOINT.
--
-- Idempotent: CREATE OR REPLACE MODEL is re-runnable and the ALTER converges on the same default, so a
-- DR re-apply is safe.
-- Existing analytics.theater_judge rows KEEP their recorded model — a column DEFAULT only stamps new
-- INSERTs and nothing here rewrites history: the 47 already-scored rows stay attributed to
-- gemini-2.5-flash.
--
-- APPLIED LIVE 2026-11-14 with the owner's OK in chat (jobs job_l5vQybShljQUMs3Ma3KIK8TKzxAB and
-- job_9QdEiuJE7VZOWhcJW-h5TLojx13_). Verified: the column default reads 'gemini-4-hydrogen' and an
-- AI.GENERATE_TABLE call through ops.gemini returned a valid structured answer.
--
-- Supersedes: the ops.gemini ENDPOINT in bigquery/02_ai_layer.sql and the
-- analytics.theater_judge.model DEFAULT in bigquery/11_theater_judge.sql (each now carries a one-line
-- SUPERSEDED marker pointing here). Those two files stay otherwise unmodified for DR-rebuild
-- apply-in-order reference. The text-embedding model (ops.text_embed, text-embedding-005) is NOT
-- touched by this file.

-- (a) Every future theater-judge row records the model that actually answered.
ALTER TABLE `stock-trading-498512.analytics.theater_judge`
  ALTER COLUMN model SET DEFAULT 'gemini-4-hydrogen';

-- (b) The remote model the judge (and anything else calling ops.gemini) actually calls.
CREATE OR REPLACE MODEL `stock-trading-498512.ops.gemini`
  REMOTE WITH CONNECTION `stock-trading-498512.us.vertex`
  OPTIONS (ENDPOINT = 'gemini-4-hydrogen');

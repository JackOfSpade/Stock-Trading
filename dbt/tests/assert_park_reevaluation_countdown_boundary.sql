-- Singular test (passes when ZERO rows): state.park_reevaluation_due must count ONLY episodes that
-- started STRICTLY AFTER activation day.
--
-- WHY THIS LIVES HERE AND NOT AS AN ASSERT IN bigquery/221 — the same reason, and the same mechanism,
-- as dbt/tests/assert_wash_sale_allocation_invariants.sql. BigQuery rejects "WITH RECURSIVE is not
-- supported in ASSERT statements", and this view's dependency chain reaches a recursive definition:
-- state.park_reevaluation_due -> analytics.park_episode_log -> analytics.park_ladder_shadow, whose
-- ladder walk (bigquery/218) is WITH RECURSIVE. 221's original in-file post-condition on this view
-- was therefore UNRUNNABLE from the moment it landed alongside 218 on 2026-09-04 — found by dry run
-- 2026-09-04, not by any run failing, because nothing replays bigquery/*.sql outside a DR rebuild.
--
-- PINNED ON THE DEFECT, NOT ON THE VALUE. The ASSERT this replaces pinned
-- `episodes_since_activation = 0`, a landing-day receipt that the forward test exists to invalidate.
-- This asserts the BOUNDARY RULE instead — the strict `>` in park_reevaluation_due's eps CTE. A `>=`
-- there would admit an episode ALREADY UNDERWAY at activation as a forward-test observation, which is
-- exactly the DATE-grain ordering trap this repo has been bitten by before. Recomputing the count
-- independently makes a silent `>` -> `>=` edit fail loudly, and unlike a zero-episode pin it holds
-- at any episode count, so it can never go red on a working system.
--
-- HONEST BOUND: no episode starts exactly on 2026-09-04 today, so this discriminates `>` from `>=`
-- only once one does. It is a LATENT guard right now, not an active one.

SELECT view_count, recomputed
FROM (
  SELECT
    (SELECT episodes_since_activation FROM {{ ref('park_reevaluation_due') }})   AS view_count,
    (SELECT COUNT(*) FROM {{ ref('park_episode_log') }}
     WHERE episode_start > DATE '2026-09-04')                                    AS recomputed
)
WHERE view_count <> recomputed

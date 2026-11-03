"""Pins the quiet-run fast paths: position in each section, and the rules a quiet fire must not lose."""
import pathlib
import unittest

PLAN = (pathlib.Path(__file__).resolve().parent.parent / "Claude_Task_Plan.md").read_text(encoding="utf-8")
FAST = "**QUIET-RUN FAST PATH"


def section(heading):
    start = PLAN.index(heading)
    end = PLAN.find("\n## ", start + len(heading))
    return PLAN[start:end if end != -1 else len(PLAN)]


def fast_path(heading):
    body = section(heading)
    start = body.index(FAST)
    return body[start:body.index("\n", start)]


ATT = "## Adversarial Review Attacker"
ORC = "## Adversarial Review Orchestrator"
SL3 = "## SL3. Incubation"
SL5 = "## SL5. Strategy Register"


class FastPathTests(unittest.TestCase):
    def test_precedes_the_full_section(self):
        for heading in (ATT, ORC, SL3, SL5):
            body = section(heading)
            self.assertLess(body.index(FAST), body.index("Read access scope"), heading)

    def test_failure_leaves_the_fast_path(self):
        for heading in (ATT, ORC, SL3, SL5):
            text = fast_path(heading)
            self.assertIn("UNKNOWN, never empty", text, heading)
            self.assertIn("leave this fast path", text, heading)
            self.assertIn("spawn no sub-agent", text, heading)
            self.assertIn("status `'completed'`", text, heading)

    def test_gates_stay_on_the_path(self):
        self.assertIn("sp_assert_deps('AR_orc', ['AR_att'], <today>)", fast_path(ORC))
        self.assertIn("sp_assert_deps('SL3', ['D2a'], <today>)", fast_path(SL3))
        self.assertIn("sp_assert_arsenal_enabled('SL3')", fast_path(SL3))
        self.assertIn("sp_assert_deps('SL5', ['AR_orc'], <today>)", fast_path(SL5))
        self.assertIn("sp_assert_arsenal_enabled('SL5')", fast_path(SL5))
        self.assertIn("SAME-DAY DOUBLE-RUN GUARD", fast_path(SL3))

    def test_ar_scans_read_the_payload_dates(self):
        self.assertIn("$.attacker_due_date", fast_path(ATT))
        self.assertIn("$.orchestrator_due_date", fast_path(ORC))

    def test_ar_orc_keeps_all_five_conjuncts(self):
        text = fast_path(ORC)
        for name in ("**STEP 0**", "**STEP 0.5**", "**RESIDUAL SWEEP**", "**NOTICE-CLOSE PASS**", "ALL FIVE"):
            self.assertIn(name, text)

    def test_sl5_scores_before_reading_readiness(self):
        text = fast_path(SL5)
        self.assertLess(text.index("sp_score_theater()"), text.index("strategy_adoption_readiness"))
        self.assertNotIn("most fires", text)

    def test_sl5_keeps_all_three_inputs(self):
        text = fast_path(SL5)
        for name in ("strategy_adoption_readiness", "PENDING_ROSTER", "DISCOVERY QUERY"):
            self.assertIn(name, text)

    def test_sl3_counts_members_by_complement(self):
        self.assertIn("current_state IS NULL OR current_state NOT IN (", fast_path(SL3))

    def test_sl3_quiet_fire_keeps_heartbeat_and_referrals(self):
        text = fast_path(SL3)
        self.assertIn("`arsenal-heartbeat`", text)
        self.assertIn("`['SL3','re-resolve']`", text)
        self.assertIn("decision = NULL", text)

    def test_sl3_checklist_skip_is_scoped_to_zero_members(self):
        self.assertIn("With zero members in the QUIET-RUN FAST PATH's query, run item (i) only", section(SL3))
        self.assertIn("Stale plan text can therefore persist", section(SL3))

    def test_sl3_first_member_audit_runs_before_the_loop(self):
        body = section(SL3)
        step1 = body.index("STEP 1 — UPDATE THE FORWARD-TEST SERIES.")
        self.assertLess(body.index("**FIRST-MEMBER AUDIT.**", step1), body.index("**Catch-up loop", step1))

    def test_sl3_referral_change_and_hosted_run_have_an_exit(self):
        text = fast_path(SL3)
        self.assertIn("land it through the own-PR protocol", text)
        self.assertIn("control returns to OPS2 STEP 2 item 6", text)

    def test_start_is_owed_after_an_early_exit(self):
        for heading in (ATT, ORC, SL3, SL5):
            self.assertIn("still makes it; a fire leaving after it does not repeat it", fast_path(heading), heading)

    def test_repo_line_is_measured(self):
        for heading in (ATT, ORC, SL3, SL5):
            self.assertIn("git status --porcelain", fast_path(heading), heading)


if __name__ == "__main__":
    unittest.main()

"""Pins for D1's one-time re-check of names rejected while B was gated."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
PLAN = (ROOT / "Claude_Task_Plan.md").read_text(encoding="utf-8")
PROTOCOLS = (ROOT / "Operating_Protocols.md").read_text(encoding="utf-8")
HEADING = "**FIRST-FULL-RUN RE-CHECK OF GATED NAMES"


def rule():
    start = PLAN.index(HEADING)
    return PLAN[start: PLAN.index("\n", start)]


class GatedNameRecheckTests(unittest.TestCase):
    def test_rule_sits_inside_d1_screen_once(self):
        self.assertEqual(PLAN.count(HEADING), 1)
        self.assertLess(PLAN.index("**ROUTER-GATED REJECTED FORM"), PLAN.index(HEADING))
        self.assertLess(PLAN.index(HEADING), PLAN.index("**DEAL-PINNED RAIL (Operating_Protocols.md"))

    def test_trigger_is_once_and_ignores_a_failed_read(self):
        text = rule()
        self.assertIn("has `screen_mode='router-gated'`", text)
        self.assertIn("A failed or unrecognised read fails open to FULL mode but does not start this step", text)
        self.assertIn("the next run does not retry it", text)

    def test_selection_is_capped_and_reads_both_row_forms(self):
        text = rule()
        self.assertIn("<= 25", text)
        self.assertIn("r.fields.rejected_compact.ANCHOR_UNRESOLVED", text)
        self.assertIn("JSON_VALUE(i, '$.code') = 'ANCHOR_UNRESOLVED'", text)
        self.assertIn("INTERVAL 21 DAY", text)
        self.assertIn("IFNULL(JSON_VALUE(fields, '$.screen_mode'), 'full') != 'router-gated'", text)

    def test_names_are_remeasured_before_they_can_pass(self):
        text = rule()
        self.assertIn("measure the reaction session on IBKR bars", text)
        self.assertIn("its 10-trading-day window closes on or before today", text)
        self.assertIn("`reason` beginning `gated-recheck:`", text)
        self.assertIn("`fields.gated_recheck`", text)

    def test_rejected_form_fixes_the_code_the_query_reads(self):
        form = PLAN[PLAN.index("**ROUTER-GATED REJECTED FORM"):PLAN.index(HEADING)]
        self.assertIn("always uses the code `ANCHOR_UNRESOLVED`", form)
        self.assertIn("always uses the code `ANCHOR_UNRESOLVED`", PROTOCOLS)

    def test_protocols_allow_the_one_rank_use(self):
        self.assertIn("never a rank key outside the re-check below", PROTOCOLS)
        self.assertIn("the only use of a tuple's figure as a rank key", PROTOCOLS)


if __name__ == "__main__":
    unittest.main()

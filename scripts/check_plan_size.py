#!/usr/bin/env python3
"""Keep blank-line-delimited task-plan paragraphs within a fixed character budget.

The routine inventory table is exempt; it is a CI-checked consistency contract rather
than prose. Rewrite rules in place and keep incident evidence in ops/plan_history/.
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
TASK_PLAN = ROOT / "Claude_Task_Plan.md"
# Next 1,000 above the largest prose paragraph after the 2026-10-30 second pass.
MAX_PARAGRAPH_CHARS = 20_000
INVENTORY_HEADING = "# ROUTINE INVENTORY & BIGQUERY RESPONSIBILITIES"
INVENTORY_HEADER = "| ID | Routine | Cadence · Type | BigQuery reads | BigQuery writes | Cadence `.md` output |"


def oversized_paragraphs(text, limit=MAX_PARAGRAPH_CHARS):
    """Return (starting line, character count) for over-budget prose paragraphs.

    A paragraph is separated by an empty or whitespace-only line. Only the table
    beneath the ROUTINE INVENTORY heading is exempt, never that section's prose or
    a table elsewhere in the plan.
    """
    findings = []
    in_inventory = False
    inventory_table_seen = False
    paragraph_inventory = False
    paragraph = []
    start_line = 1

    def check_paragraph():
        nonlocal inventory_table_seen
        if not paragraph:
            return
        inventory_table = (
            paragraph_inventory
            and not inventory_table_seen
            and paragraph[0] == INVENTORY_HEADER
            and all(line.lstrip().startswith("|") for line in paragraph)
        )
        if inventory_table:
            inventory_table_seen = True
        size = len("\n".join(paragraph))
        if not inventory_table and size > limit:
            findings.append((start_line, size))

    for line_number, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            check_paragraph()
            paragraph = []
            continue
        if re.match(r"^#{1,6}\s+", line):
            in_inventory = line == INVENTORY_HEADING
        if not paragraph:
            start_line = line_number
            paragraph_inventory = in_inventory
        paragraph.append(line)
    check_paragraph()
    return findings


def main():
    findings = oversized_paragraphs(TASK_PLAN.read_text(encoding="utf-8"))
    if findings:
        for line, size in findings:
            print(f"PLAN SIZE: FAIL — Claude_Task_Plan.md:{line}: {size:,} characters "
                  f"exceed the {MAX_PARAGRAPH_CHARS:,}-character paragraph cap. "
                  "Rewrite the current rule in place; move history to ops/plan_history/.")
        return 1
    print(f"PLAN SIZE: OK — paragraphs fit the {MAX_PARAGRAPH_CHARS:,}-character cap "
          "(routine inventory table exempt).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

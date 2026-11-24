"""Guard scripts/plan_section.py: the bounded-parts reader routines use for their own plan section."""
import subprocess
import sys
from pathlib import Path

from conftest import load_module_from_path

ps = load_module_from_path("plan_section", "scripts", "plan_section.py")
ROOT = Path(__file__).resolve().parent.parent


def test_parts_rejoin_to_the_exact_text_and_never_cut_a_line():
    text = "".join(f"line {i} " + "x" * (i * 37 % 900) + "\n" for i in range(400)) + "no newline at end"
    parts = ps.parts_of(text, limit=5000)
    assert "".join(parts) == text
    assert len(parts) > 1
    assert all(p.endswith("\n") for p in parts[:-1])
    assert all(len(p) <= 5000 for p in parts)


def test_a_line_longer_than_the_limit_stays_whole_in_its_own_part():
    text = "short\n" + "y" * 9000 + "\n" + "tail\n"
    parts = ps.parts_of(text, limit=1000)
    assert "".join(parts) == text
    assert "y" * 9000 + "\n" in parts


def test_every_real_routine_section_matches_its_generated_slice():
    text = ps.read_text_preserving_newlines(ps.stp.SRC)
    _preamble, routines = ps.stp.split(text)
    assert routines
    for rid, _title, group_intro, body in routines:
        sec = ps.section(rid, text)
        assert sec == group_intro + body
        assert "".join(ps.parts_of(sec)) == sec
    assert ps.section("NO_SUCH_ROUTINE", text) is None


def test_cli_lists_parts_then_prints_one_and_rejects_bad_input():
    def run(*a):
        return subprocess.run([sys.executable, "scripts/plan_section.py", *a], cwd=ROOT,
                              capture_output=True, text=True, check=False)

    listing = run("D1")
    assert listing.returncode == 0 and "--part 1" in listing.stdout
    part = run("D1", "--part", "1")
    assert part.returncode == 0 and 0 < len(part.stdout) <= ps.PART_CHARS + 20000
    assert run("D1", "--part", "999").returncode == 2
    assert run("NO_SUCH_ROUTINE").returncode == 2
    toc = run("--preamble-toc")
    assert toc.returncode == 0 and "OPERATING MODEL" in toc.stdout

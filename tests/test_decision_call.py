"""Pins scripts/decision_call.py, the generator of digest-checked ops.sp_log_decision_checked CALLs.

VECTOR's digest was reproduced by BigQuery on 2026-10-29 from the procedure's own expression
(bigquery/270), so a change here that moves it means the Python and SQL renderings have diverged and
every generated call would be refused.
"""

import contextlib
import importlib.util
import io
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_SPEC = importlib.util.spec_from_file_location("decision_call", ROOT / "scripts" / "decision_call.py")
dc = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(dc)

VECTOR = {
    "entry_date": "2026-10-28", "entry_type": "research-screen", "strategy": None, "ticker": "ORCL",
    "conviction_pct": 100,
    "title": "D1 2026-10-28 screen — “quoted” it's a\\b",
    "body_md": "line1\nline2 ✓ \U0001d11e tab\tend",
    "fields": {"routine": "D1", "n": [1, 2.5, -0.25], "s": "x\u2019y", "nested": {"z": None, "b": True}},
    "refs": ["a", "b\u2019"], "tags": [], "source_session": "sess-1",
}
VECTOR_SHA = "19edf671479d4ba9dea4e2bc81882238e15d8f315cee5a3760e99e1142aae002"

_ESC = re.compile(r"\\(U[0-9a-fA-F]{8}|u[0-9a-fA-F]{4}|.)")


def decode_sql_str(lit: str) -> str:
    """Decode the subset of GoogleSQL quoted-string escapes sql_str emits."""
    assert lit[0] == lit[-1] == "'"

    def one(m):
        e = m.group(1)
        return chr(int(e[1:], 16)) if e[0] in "uU" and len(e) > 1 else e

    return _ESC.sub(one, lit[1:-1])


_LIT = re.compile(r"'(?:[^'\\]|\\.)*'")


def arg_value(call: str, key: str) -> str:
    """The value of one string argument: its adjacent wrapped pieces, decoded and concatenated."""
    block = re.search(r"(?:\(|  -- in_\w+)\n(.*?),  -- in_" + key + "$", call, re.S | re.M).group(1)
    block = block.rsplit("  -- in_", 1)[-1].split("\n", 1)[-1] if "  -- in_" in block else block
    return "".join(decode_sql_str(m) for m in _LIT.findall(block))


def run(raw, extra=()):
    with tempfile.TemporaryDirectory() as d:
        src = Path(d) / "in.json"
        src.write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            code = dc.main([str(src), "--out", str(Path(d) / "out"), *extra])
        out = Path(d) / "out"
        files = {p.name: p.read_text(encoding="ascii") for p in out.iterdir()} if out.exists() else {}
        return code, files, err.getvalue()


class DigestVector(unittest.TestCase):
    def test_bigquery_reproduced_vector(self):
        self.assertEqual(dc.digest(dc.normalise(VECTOR)), VECTOR_SHA)

    def test_fields_string_and_object_agree_when_text_matches(self):
        args = dc.normalise(VECTOR)
        as_string = dict(VECTOR, fields=args["fields"])
        self.assertEqual(dc.digest(dc.normalise(as_string)), VECTOR_SHA)

    def test_every_argument_is_covered(self):
        base = dc.normalise(VECTOR)
        for key, kind in dc.ARGS:
            changed = dict(base)
            if kind == "array":
                changed[key] = (base[key] or []) + ["x"]
            elif base[key] is None:
                changed[key] = "1" if kind == "numeric" else "x"
            else:
                changed[key] = base[key] + "1"
            self.assertNotEqual(dc.digest(changed), VECTOR_SHA, key)

    def test_null_empty_and_empty_array_are_distinct(self):
        base = dc.normalise(VECTOR)
        self.assertNotEqual(dc.digest(dict(base, strategy=None)), dc.digest(dict(base, strategy="")))
        self.assertNotEqual(dc.digest(dict(base, tags=[])), dc.digest(dict(base, tags=[""])))
        self.assertEqual(dc.digest(dict(base, tags=None)), dc.digest(dict(base, tags=[])))


class NumericRendering(unittest.TestCase):
    # Each pair reproduced live 2026-10-29 by CAST(NUMERIC ... AS STRING).
    def test_matches_bigquery_cast(self):
        for value, want in [(100, "100"), ("0.50", "0.5"), ("1E2", "100"), ("-0.000000001", "-0.000000001"),
                            (0, "0"), (75.5, "75.5")]:
            self.assertEqual(dc.render_numeric("x", value), want, value)

    def test_rejects_what_numeric_would_round(self):
        for bad in ["0.0000000001", "nan", True, "1e40"]:
            with self.assertRaises(dc.InputError):
                dc.render_numeric("x", bad)

    def test_full_numeric_precision_survives_a_small_decimal_context(self):
        from decimal import localcontext

        with localcontext() as ctx:
            ctx.prec = 6
            for value in ["99999999999999999999999999999.999999999", "-12345678901234567890123456789.123456789"]:
                self.assertEqual(dc.render_numeric("x", value), value)

    def test_huge_exponent_is_rejected_before_rendering(self):
        with self.assertRaisesRegex(dc.InputError, "out of NUMERIC range"):
            dc.render_numeric("x", "1e999999999")


class GeneratedSql(unittest.TestCase):
    def test_call_is_ascii_and_literals_decode_to_the_input(self):
        code, files, _ = run(VECTOR)
        self.assertEqual(code, 0)
        call = files["call.sql"]
        self.assertRegex(call, r"\A[\x20-\x7e\n]*\Z")
        self.assertIn(f"'{VECTOR_SHA}'", call)
        args = dc.normalise(VECTOR)
        for key in ("title", "body_md", "fields"):
            self.assertEqual(arg_value(call, key), args[key], key)
        self.assertIn("NUMERIC '100'", call)
        self.assertIn("CAST([] AS ARRAY<STRING>),  -- in_tags", call)

    def test_argument_order_matches_the_procedure(self):
        sql = (ROOT / "bigquery" / "270_decision_log_checked_write.sql").read_text(encoding="utf-8")
        sig = re.search(r"sp_log_decision_checked`\((.*?)\)\nBEGIN", sql, re.S).group(1)
        names = re.findall(r"\bin_(\w+) ", sig)
        want = [("fields_json" if k == "fields" else k) for k, _ in dc.ARGS] + ["expected_sha256"]
        self.assertEqual(names, want)

    def test_readback_carries_no_payload(self):
        code, files, _ = run(VECTOR)
        self.assertEqual(code, 0)
        rb = files["readback.sql"]
        self.assertNotIn("line1", rb)
        self.assertIn(f"'sha256:{VECTOR_SHA}' IN UNNEST(tags)", rb)

    def test_long_literals_wrap_without_splitting_escapes(self):
        body = ("x\u2019'\\" * 300) + "\U0001d11e" * 50
        code, files, _ = run(dict(VECTOR, body_md=body, fields={"k": "v" * 5000}))
        self.assertEqual(code, 0)
        call = files["call.sql"]
        self.assertLessEqual(max(len(line) for line in call.splitlines()), dc.WRAP + 40)
        self.assertEqual(arg_value(call, "body_md"), body)
        self.assertEqual(arg_value(call, "fields"), json.dumps({"k": "v" * 5000}, separators=(",", ":")))


class Rejections(unittest.TestCase):
    def test_invalid_inputs_exit_2_and_write_nothing(self):
        cases = [
            dict(VECTOR, bogus=1),
            {k: v for k, v in VECTOR.items() if k != "title"},
            dict(VECTOR, source_session="  "),
            dict(VECTOR, entry_date="2026-10-28T00:00"),
            dict(VECTOR, fields="[1,2]"),
            dict(VECTOR, fields="{not json"),
            dict(VECTOR, tags=["ok", 3]),
            dict(VECTOR, fields={"x": float("nan")}),
            dict(VECTOR, fields='{"x": NaN}'),
            dict(VECTOR, fields='{"x": Infinity}'),
        ]
        for raw in cases:
            code, files, err = run(raw)
            self.assertEqual(code, 2, raw)
            self.assertEqual(files, {}, raw)
            self.assertIn("decision_call:", err)


class StagedSql(unittest.TestCase):
    PART = re.compile(
        r"\ACALL `stock-trading-498512\.ops\.sp_stage_decision_part`\(\n"
        r"  '([0-9a-f]{64})',  -- in_call_sha256\n"
        r"  '(fields|body_md)',  -- in_arg_name\n"
        r"  (\d+),  -- in_part_no\n"
        r"  (\d+),  -- in_n_parts\n"
        r"  '([0-9a-f]{64})',  -- in_part_sha256\n"
        r"(.*?)  -- in_payload\n\);\n\Z", re.S)
    LITERALS = re.compile(r"\s*'(?:[^'\\]|\\.)*'(?:\s+'(?:[^'\\]|\\.)*')*\s*\Z")

    def check_parts(self, files, raw, keys):
        import hashlib

        args = dc.normalise(raw)
        sha = dc.digest(args)
        for name, text in files.items():
            self.assertLessEqual(len(text), dc.FILE_BUDGET, name)
            self.assertRegex(text, r"\A[\x20-\x7e\n]*\Z", name)
        call = files["call.sql"]
        self.assertTrue(call.startswith(f"CALL {dc.PROC_STAGED}(\n"))
        self.assertIn(f"  '{sha}'  -- in_expected_sha256\n", call)
        self.assertIn("  CAST([" + ", ".join(f"'{k}'" for k in keys) +
                      "] AS ARRAY<STRING>),  -- in_staged_args\n", call)
        for key in keys:
            self.assertIn(f"  CAST(NULL AS STRING),  -- in_{key}\n", call)
            numbered = []
            for name, text in files.items():
                if not name.startswith(f"part_{key}_"):
                    continue
                m = self.PART.fullmatch(text)
                self.assertIsNotNone(m, name)
                call_sha, arg, part_no, n_parts, part_sha, literal = m.groups()
                self.assertEqual(call_sha, sha)
                self.assertEqual(arg, key)
                self.assertEqual(name, f"part_{key}_{int(part_no):02d}.sql")
                self.assertRegex(literal, self.LITERALS)
                payload = "".join(decode_sql_str(lit) for lit in _LIT.findall(literal))
                self.assertEqual(part_sha, hashlib.sha256(payload.encode("utf-8")).hexdigest())
                numbered.append((int(part_no), int(n_parts), payload))
            self.assertGreater(len(numbered), 0)
            numbered.sort()
            self.assertEqual([n for n, _, _ in numbered], list(range(1, len(numbered) + 1)))
            self.assertTrue(all(total == len(numbered) for _, total, _ in numbered))
            self.assertEqual("".join(payload for _, _, payload in numbered), args[key])
        self.assertEqual({name for name in files if name.startswith("part_")},
                         {f"part_{key}_{n:02d}.sql" for key in keys
                          for n in range(1, 1 + sum(name.startswith(f"part_{key}_") for name in files))})

    def test_small_call_is_unchanged(self):
        code, files, _ = run(VECTOR)
        self.assertEqual(code, 0)
        self.assertEqual(set(files), {"call.sql", "readback.sql"})
        self.assertEqual(files["call.sql"], dc.call_sql(dc.normalise(VECTOR)))
        self.assertEqual(files["readback.sql"], dc.readback_sql(dc.normalise(VECTOR)))

    def test_large_fields_parts_reconstruct(self):
        raw = dict(VECTOR, fields={"payload": ("ASCII'\\\né中𝄞🚀" * 11000)})
        code, files, err = run(raw)
        self.assertEqual(code, 0, err)
        self.check_parts(files, raw, ["fields"])
        self.assertEqual(arg_value(files["call.sql"], "body_md"), raw["body_md"])

    def test_large_body_and_fields_both_staged(self):
        raw = dict(VECTOR, fields={"payload": "abcé🚀" * 24000},
                   body_md="quote' slash\\ music𝄞\n" * 5000)
        code, files, err = run(raw)
        self.assertEqual(code, 0, err)
        self.check_parts(files, raw, ["fields", "body_md"])

    def test_stale_parts_removed_on_regeneration(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = Path(d) / "input.json", Path(d) / "out"
            src.write_text(json.dumps(dict(VECTOR, fields={"x": "🚀" * 10000})), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(dc.main([str(src), "--out", str(out)]), 0)
            self.assertTrue(list(out.glob("part_*.sql")))
            src.write_text(json.dumps(VECTOR), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(dc.main([str(src), "--out", str(out)]), 0)
            self.assertEqual({p.name for p in out.iterdir()}, {"call.sql", "readback.sql"})
            self.assertEqual((out / "call.sql").read_text(encoding="ascii"), dc.call_sql(dc.normalise(VECTOR)))

    def test_unsplittable_input_writes_nothing(self):
        raw = dict(VECTOR, title="x" * 30000, fields=None, body_md=None)
        code, files, err = run(raw)
        self.assertEqual(code, 2)
        self.assertEqual(files, {})
        self.assertEqual(err, "decision_call: call exceeds the 24000-character budget even after staging fields and body_md; reduce other arguments\n")

    def test_staged_signature_matches_checked_signature(self):
        checked = (ROOT / "bigquery" / "270_decision_log_checked_write.sql").read_text(encoding="utf-8")
        staged = (ROOT / "bigquery" / "271_decision_log_staged_write.sql").read_text(encoding="utf-8")
        old_sig = re.search(r"sp_log_decision_checked`\((.*?)\)\nBEGIN", checked, re.S).group(1)
        new_sig = re.search(r"sp_log_decision_staged`\((.*?)\)\nBEGIN", staged, re.S).group(1)
        old_params = re.findall(r"\b(in_\w+) (DATE|STRING|NUMERIC|ARRAY<STRING>)", old_sig)
        new_params = re.findall(r"\b(in_\w+) (DATE|STRING|NUMERIC|ARRAY<STRING>)", new_sig)
        self.assertEqual(len(old_params), 17)
        self.assertEqual(new_params, [*old_params[:-1], ("in_staged_args", "ARRAY<STRING>"), old_params[-1]])


if __name__ == "__main__":
    unittest.main()

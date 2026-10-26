import copy
import importlib.util
import pathlib
import tempfile
import unittest
from unittest.mock import patch

PATH = pathlib.Path(__file__).parents[1] / "scripts" / "merge_validated_pr.py"
if not PATH.exists():
    PATH = pathlib.Path(__file__).with_name("merge_validated_pr.py")
spec = importlib.util.spec_from_file_location("merge_policy", PATH)
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class MergePolicyTests(unittest.TestCase):
    def setUp(self):
        self.pr = {"state": "open", "draft": False,
                   "base": {"ref": "main", "repo": {"id": 1}},
                   "head": {"sha": "head", "ref": "claude/x", "repo": {"id": 1}}}
        self.comparison = {"merge_base_commit": {"sha": "base"}}
        self.checks = [{"id": 10, "name": "CI required", "head_sha": "head",
                        "app": {"slug": "github-actions"}, "status": "completed",
                        "conclusion": "success"}]

    def validate(self):
        policy.validate(self.pr, "base", self.comparison, self.checks, ["CI required"])

    def test_current_success_passes(self):
        self.validate()

    def test_missing_failed_pending_cancelled_and_skipped_checks_fail_closed(self):
        for state in [None, "failure", "pending", "cancelled", "skipped", "neutral"]:
            with self.subTest(state=state):
                self.checks[0]["conclusion"] = state
                with self.assertRaises(ValueError):
                    self.validate()

    def test_newer_failed_rerun_overrides_older_success(self):
        rerun = copy.deepcopy(self.checks[0])
        rerun.update(id=11, conclusion="failure")
        self.checks.append(rerun)
        with self.assertRaises(ValueError):
            self.validate()

    def test_other_commit_or_application_cannot_supply_required_check(self):
        for field, value in [("head_sha", "old-head"), ("app", {"slug": "other-app"})]:
            with self.subTest(field=field):
                check = copy.deepcopy(self.checks[0])
                self.checks[0][field] = value
                with self.assertRaises(ValueError):
                    self.validate()
                self.checks[0] = check

    def test_outdated_main_fails(self):
        self.comparison["merge_base_commit"]["sha"] = "old-base"
        with self.assertRaises(ValueError):
            self.validate()

    def test_closed_draft_fork_and_wrong_base_fail(self):
        for change in ["closed", "draft", "fork", "wrong-base"]:
            with self.subTest(change=change):
                original = copy.deepcopy(self.pr)
                if change == "closed":
                    self.pr["state"] = "closed"
                elif change == "draft":
                    self.pr["draft"] = True
                elif change == "fork":
                    self.pr["head"]["repo"]["id"] = 2
                elif change == "wrong-base":
                    self.pr["base"]["ref"] = "development"
                with self.assertRaises(ValueError):
                    self.validate()
                self.pr = original

    def test_all_required_checks_are_needed(self):
        with self.assertRaises(ValueError):
            policy.validate(self.pr, "base", self.comparison, self.checks,
                            ["CI required", "Security required"])

    def test_merge_targets_one_exact_head_then_dispatches_main_validation(self):
        calls = []
        def api(path, paginated=False):
            if path.endswith('/pulls/7'):
                result = copy.deepcopy(self.pr)
                result['merged'] = bool(calls)
                result['merge_commit_sha'] = 'merged'
                return result
            if path.endswith('/git/ref/heads/main'):
                return {'object': {'sha': 'base'}}
            if path.endswith('/git/ref/heads/claude/x'):
                return {'object': {'sha': 'head'}}
            if '/compare/' in path:
                return self.comparison
            if '/check-runs?' in path:
                return [{'check_runs': self.checks}]
            raise AssertionError(path)
        env = {'GITHUB_REPOSITORY': 'owner/repo', 'PR_NUMBER': '7',
               'REQUIRED_CHECKS': '["CI required"]',
               'MAIN_WORKFLOWS': '["ci.yml", "codeql.yml"]'}
        with tempfile.TemporaryDirectory() as directory:
            output = pathlib.Path(directory) / 'output'
            env['GITHUB_OUTPUT'] = str(output)
            with patch.dict(policy.os.environ, env, clear=True), patch.object(policy, 'api', api), \
                    patch.object(policy, 'gh', lambda *args: calls.append(args)):
                policy.main()
            self.assertEqual(output.read_text(), 'base_sha=base\nhead_sha=head\nmerge_sha=merged\n')
        self.assertEqual(calls, [
            ('pr', 'merge', '7', '--repo', 'owner/repo', '--merge', '--match-head-commit', 'head'),
            ('workflow', 'run', 'ci.yml', '--repo', 'owner/repo', '--ref', 'main'),
            ('workflow', 'run', 'codeql.yml', '--repo', 'owner/repo', '--ref', 'main'),
            ('api', '--method', 'DELETE', 'repos/owner/repo/git/refs/heads/claude/x')])

    def delete_head(self, branch_sha=None, error=None):
        calls, reads = [], []
        def api(path, paginated=False):
            reads.append(path)
            if error:
                raise error
            return {'object': {'sha': branch_sha}}
        with patch.object(policy, 'api', api), \
                patch.object(policy, 'gh', lambda *args: calls.append(args)), \
                patch('builtins.print') as printed:
            policy.delete_merged_head('owner/repo', self.pr, 'head')
        return calls, reads, ' '.join(str(c.args) for c in printed.call_args_list)

    def test_merged_head_deleted_only_while_it_names_the_merged_commit(self):
        calls, reads, _ = self.delete_head(branch_sha='head')
        self.assertEqual(reads, ['repos/owner/repo/git/ref/heads/claude/x'])
        self.assertEqual(calls, [('api', '--method', 'DELETE',
                                  'repos/owner/repo/git/refs/heads/claude/x')])

    def test_branch_that_moved_after_merge_is_left_in_place(self):
        calls, _, printed = self.delete_head(branch_sha='newer')
        self.assertEqual(calls, [])
        self.assertIn('moved past the merged head', printed)

    def test_missing_branch_or_api_failure_warns_without_raising(self):
        failure = policy.subprocess.CalledProcessError(1, ['gh'])
        calls, _, printed = self.delete_head(error=failure)
        self.assertEqual(calls, [])
        self.assertIn('::warning::Could not delete merged branch claude/x', printed)

    def test_delete_failure_after_matching_read_warns_without_raising(self):
        def gh(*args):
            raise policy.subprocess.CalledProcessError(1, ['gh'])
        with patch.object(policy, 'api', lambda path, paginated=False: {'object': {'sha': 'head'}}), \
                patch.object(policy, 'gh', gh), patch('builtins.print') as printed:
            policy.delete_merged_head('owner/repo', self.pr, 'head')
        self.assertIn('::warning::', str(printed.call_args_list))

    def test_base_branch_is_never_deleted(self):
        self.pr['head']['ref'] = 'main'
        calls, reads, _ = self.delete_head(branch_sha='head')
        self.assertEqual((calls, reads), ([], []))

    def test_missing_head_ref_skips_delete_without_raising(self):
        del self.pr['head']['ref']
        calls, reads, _ = self.delete_head(branch_sha='head')
        self.assertEqual((calls, reads), ([], []))

    def test_branch_name_is_url_quoted_but_keeps_slashes(self):
        self.pr['head']['ref'] = 'claude/a#b c'
        calls, reads, _ = self.delete_head(branch_sha='head')
        self.assertEqual(reads, ['repos/owner/repo/git/ref/heads/claude/a%23b%20c'])
        self.assertEqual(calls[0][-1], 'repos/owner/repo/git/refs/heads/claude/a%23b%20c')


if __name__ == "__main__":
    unittest.main()

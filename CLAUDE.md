# Project notes for Claude

## Known non-issues — do NOT re-investigate

- **Stop-hook "Unverified commits" warning** (`~/.claude/stop-hook-git-check.sh`).
  It flags any commit on the branch whose committer email isn't
  `noreply@anthropic.com`. That includes:
  - the operator's **GitHub web-UI commits** (committer `noreply@github.com`), and
  - the **auto-merge bot** commits (`…@users.noreply.github.com`).

  These are legitimately authored by the operator (Jack Wu) or the GitHub Actions
  bot, are already merged to `main`, and the warning is **purely cosmetic**
  ("Unverified" just means the commit isn't GPG-signed by Anthropic's key).

  **Action: none.** Do NOT rewrite their authorship (`--reset-author`) and do NOT
  force-push `main` to "fix" them — that would misattribute the operator's work to
  Claude and rewrite already-merged history. The hook itself is harness-managed
  (re-provisioned fresh each session), so it can't be permanently changed from this
  repo. Just ignore the message when it appears.

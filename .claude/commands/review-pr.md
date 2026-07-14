---
allowed-tools: Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr comment:*),Bash(gh pr review:*),Bash(gh api:*)
description: Review a pull request with parallel reviewer subagents
---

Determine the PR number: use the command argument if given, otherwise infer it from the current branch with `gh pr view --json number -q .number`.

Perform a comprehensive code review using subagents for key areas:

- code-quality-reviewer
- performance-reviewer
- test-coverage-reviewer
- documentation-accuracy-reviewer
- security-code-reviewer

Instruct each to only provide noteworthy feedback. Once they finish, review the feedback and post only the feedback that you also deem noteworthy.

Provide feedback using inline comments for specific issues via `gh api repos/{owner}/{repo}/pulls/<pr-number>/comments`.
Use `gh pr comment <pr-number> --body-file -` with stdin for top-level comments.
Keep feedback concise.

---

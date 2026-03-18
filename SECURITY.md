# Security Model

## bypassPermissions

The generated `run.sh` uses `--permission-mode bypassPermissions` because the session is headless — no human is present to approve each tool call.

Safety is enforced **externally by bash**, not by Claude's self-restraint:

| Safety Layer | Enforced By | What It Does |
|---|---|---|
| Never-touch list | Bash (`git diff`) | Reverts if protected files are modified |
| Type checking | Bash (project's typecheck command) | Reverts if types break |
| Build validation | Bash (project's build command) | Reverts if build breaks |
| Atomic commits | Bash | Code + manifest in one commit, no state drift |
| Push after every commit | Bash | Work survives machine failure |
| Circuit breaker | Bash | Stops after 3 no-progress or 5 error iterations |
| Severity budget | Bash | Critical/high first, medium/low later |
| Escalation rules | Claude (PROMPT.md) | Architecture, financial, auth changes get escalated |

## What Claude CANNOT Do

- Access files outside the project directory
- Modify git config, SSH keys, or credentials
- Install global packages
- Make network requests beyond `git push`
- Bypass the never-touch list (bash reverts regardless of what Claude does)
- Auto-merge to main (always creates a PR for human review)

## Tool Restrictions

The `--allowedTools` flag restricts Claude to: Agent, Bash, Read, Write, Edit, Grep, Glob, SendMessage, MultiEdit. No web access, no MCP tools, no file system access outside the project.

## Never-Touch Enforcement

The bash loop checks `git diff` after every iteration against user-confirmed patterns. If ANY file matching a pattern was modified, the **entire iteration is reverted** via `git reset --hard`. This runs in bash — Claude cannot intercept or bypass it.

## Data Safety

- All work happens on a dedicated branch (never touches main)
- Every commit is pushed immediately to the remote
- The PR is never auto-merged — human review is always required
- The manifest (state file) is committed atomically with code changes
- If the machine dies mid-session, all completed work is safe on GitHub

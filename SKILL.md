---
name: overnight
description: Universal autonomous overnight session. Scans any project, discovers all work (security, dead code, performance, tests, etc.), proposes safety rails, then generates a bash loop that launches fresh Claude sessions to fix everything while you sleep. Each iteration is a fresh context — no degradation. Creates a PR for morning review. Use when the user wants autonomous overnight work, says "run while I sleep", "overnight session", "fix everything overnight", or "/overnight".
---

# Universal Overnight Autonomous Session

Scan any project, discover all improvable work, and fix it autonomously overnight using fresh Claude sessions in a bash loop. You are the setup orchestrator — you prepare everything, the bash loop does the execution.

## Quick Start

Tell the user:

> I'll set up an autonomous overnight session. Here's what will happen:
>
> 1. Scan your project and discover all work (security, code quality, performance, tests, etc.)
> 2. Propose a "never touch" safety list for your confirmation
> 3. Generate a manifest of tasks, an orchestrator prompt, and a bash runner
> 4. You start the runner in tmux and go to sleep
> 5. Fresh Claude sessions fix issues in a loop — no context degradation
> 6. A draft PR is created after the first commit, updated as work progresses
> 7. Every commit is pushed immediately — your work is safe even if your machine dies
>
> Ready to start?

After user confirms, follow the Setup Protocol below.

## Setup Protocol

### Step 0: Resume Check

```python
# Check for existing manifest
if .planning/overnight/manifest.json exists:
  pending = count tasks where status == "pending"
  if pending > 0:
    Ask user: "Found {pending} pending tasks from a previous session. Continue or start fresh?"
    - Continue: skip to Step 5 (regenerate PROMPT.md + run.sh with existing manifest)
    - Fresh: move existing files to .planning/overnight/archive/{date}/
```

### Step 1: Project Discovery

Detect the tech stack and validation commands. Read [discovery.md](discovery.md) for the full detection logic.

```bash
# Run baseline checks and record results
mkdir -p .planning/overnight
```

Establish baseline: run typecheck, build, test. Record pass/fail status and the exact commands used.

### Step 2: Work Discovery

Dispatch ALL audit agents in parallel (up to 12 at once). Read [discovery.md](discovery.md) for the full list of audit categories and which to skip based on the detected stack.

Each audit agent:
- Gets a specific category and file scope (max 15-20 files per agent)
- Writes findings to `.planning/overnight/audit-{category}.md`
- Uses structured format: `### [SEVERITY] title` with file, line, issue, fix
- Returns only summary counts in the message
- Runs in the background (`run_in_background: true`)

Launch all applicable agents at once in a single message:
security, dead-code, code-quality, links, performance, ui-accessibility, copy, database, auth, dependencies, type-safety, tests

Wait for all to complete before proceeding to Step 3.

### Step 3: Propose Safety Rails

Analyze the project to detect sensitive areas. Propose a "never touch" list:

```python
never_touch = []

# Auto-detect patterns
if directory "migrations" or "supabase/migrations" exists:
  never_touch.append("migrations/")
if files matching "**/earnings/**" or "**/billing/**" exist:
  never_touch.append("those paths")
if "middleware.ts" or "middleware.js" exists:
  never_touch.append("middleware.*")
if files matching "**/webhook*" exist:
  never_touch.append("webhook handlers")
# Also check CLAUDE.md for "never touch" or "do not modify" sections
```

Present to user:

> Based on my analysis, I recommend these files/directories as "never touch":
>
> - `supabase/migrations/` — database migrations
> - `lib/earnings/service.ts` — financial calculations
> - `middleware.ts` — auth routing
> - ...
>
> Add or remove any?

Wait for user confirmation.

### Step 4: Generate Manifest

Read all `audit-{category}.md` files. Create `manifest.json` with every finding as a task.

See [manifest-schema.md](manifest-schema.md) for the full schema.

Key rules:
- Each finding becomes one task with a unique ID (e.g., SEC-001, DEAD-003)
- Set all statuses to "pending", attempts to 0
- Include the user-confirmed never-touch patterns
- Include detected validation commands
- Set branch name: `overnight/{YYYYMMDD}-{HHMMSS}`
- Record baseline commit SHA

**Deduplication:** After generating all tasks, deduplicate by `file:line`. Overlapping findings from different audit categories (e.g., select("*") found by both performance and database audits) should be merged — keep the first occurrence, drop duplicates.

**Test task tiers:** Split TEST-* tasks into two tiers in the manifest:
- `"test_tier": "scaffold"` — Mechanical test scaffolding the overnight session CAN write (auth guard returns 401, missing field returns 400, basic input validation, happy path smoke tests)
- `"test_tier": "logic"` — Complex logic tests that should be escalated (financial calculations, webhook flows, multi-step payment processing, race conditions)

Also generate:
- `.planning/overnight/MORNING-REVIEW.md` with header template
- `.planning/overnight/progress.md` with session start timestamp

### Step 5: Generate PROMPT.md

Read [prompt-template.md](prompt-template.md) and fill in:
- The never-touch list (from manifest)
- The validation commands (from manifest)

Write to `.planning/overnight/PROMPT.md`.

### Step 6: Generate run.sh

Read [run-template.sh](run-template.sh).

Write to `.planning/overnight/run.sh`.

Make executable: `chmod +x .planning/overnight/run.sh`

### Step 7: Launch Instructions

Tell the user:

> Everything is ready in `.planning/overnight/`
>
> **{N} tasks discovered** across {categories} categories
> ({critical} critical, {high} high, {medium} medium, {low} low)
>
> To start the autonomous session:
> ```bash
> tmux new -s overnight
> bash .planning/overnight/run.sh
> ```
>
> Then go to sleep. Check `.planning/overnight/progress.md` in the morning.
>
> A PR will be created when done (never auto-merges to main).
> Uses your Claude subscription — no extra costs.

## Key Design Decisions

- **Fresh sessions:** Each iteration launches a new `claude -p` process with fresh context. No compaction, no degradation.
- **Bash controls termination:** Claude can't "decide to stop" — the bash loop checks the manifest and decides.
- **Trust but verify:** Bash validates typecheck + build after each iteration. Reverts on failure regardless of what Claude claims.
- **Never-touch is enforced:** Bash checks `git diff` against patterns and auto-reverts violations.
- **Atomic commits:** Code + manifest in one commit. No state drift.
- **Push after every commit:** Every successful iteration is pushed to the remote immediately. If the machine dies, all work is safe on GitHub.
- **Draft PR after first commit:** A draft PR is created after the first successful iteration. Subsequent pushes update it automatically. You can watch progress from your phone.
- **Resume across machines:** Skill detects existing manifest locally OR on a remote branch and offers to continue.
- **Severity-based budget:** First 60% of iterations focus on critical+high tasks. Medium tasks start at 60%. Low tasks only after 80%. This ensures the highest-value work gets done even if the session is cut short.
- **Categorized commits:** Commits are tagged by category (e.g., `fix(security): overnight — ...`, `refactor(dead-code): overnight — ...`) for easier PR review.
- **Token tracking:** Each iteration logs approximate token usage to progress.md so you can see cost in the morning.

## Security Model

This skill runs with elevated permissions. Understand the trade-offs:

### bypassPermissions

The generated `run.sh` uses `--permission-mode bypassPermissions` because:
- The session is **headless** — no human is present to approve each tool call
- Every iteration is a fresh process — it can't accumulate permissions across iterations
- The bash loop provides **external safety checks** that don't rely on Claude's self-restraint:
  - Never-touch enforcement via `git diff` pattern matching
  - Typecheck + build validation after every iteration
  - Auto-revert on any failure
  - Circuit breaker after 3 iterations with no progress

**What this means:** Claude can read/write any file, run any bash command, and create agents without prompts. The never-touch list and build validation are the guardrails — not permissions.

### What the skill CANNOT access

- No network access beyond `git push` (run.sh doesn't use `curl`, `wget`, etc.)
- No access to other repos or directories outside the project
- No ability to modify git config, SSH keys, or credentials
- No ability to install global packages (only project-local)
- The `--allowedTools` flag restricts Claude to: Agent, Bash, Read, Write, Edit, Grep, Glob, SendMessage, MultiEdit

### Never-touch enforcement

The bash loop checks `git diff` after every iteration against the never-touch patterns. If ANY file matching a pattern was modified, the **entire iteration is reverted** via `git reset --hard`. This is enforced by bash, not by Claude — Claude cannot bypass it.

### Data safety

- All work happens on a dedicated branch (never touches main)
- Every commit is pushed immediately — work survives machine failure
- The PR is never auto-merged — human review is always required
- The manifest (state file) is committed atomically with code changes

## Reference Files

- [discovery.md](discovery.md) — Tech stack detection, audit categories, agent prompts
- [prompt-template.md](prompt-template.md) — Template for the orchestrator prompt
- [run-template.sh](run-template.sh) — Template for the bash loop
- [manifest-schema.md](manifest-schema.md) — manifest.json schema and examples

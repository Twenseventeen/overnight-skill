# Manifest Schema

The manifest is the central state file. The bash loop reads it to check completion. Claude reads it to know what to work on. It must always be valid JSON.

## Schema

```json
{
  "project": "ProjectName",
  "branch": "overnight/20260316-220000",
  "created": "2026-03-16T22:00:00Z",
  "baseline": {
    "typecheck": "pass",
    "build": "pass",
    "test": "279 passing",
    "commit": "ae032e5"
  },
  "never_touch": [
    "supabase/migrations/",
    "lib/earnings/service.ts",
    "middleware.ts"
  ],
  "validation_commands": {
    "typecheck": "pnpm check-types",
    "build": "pnpm build",
    "test": "pnpm test",
    "lint": "pnpm lint"
  },
  "tasks": [
    {
      "id": "SEC-001",
      "category": "security",
      "severity": "critical",
      "title": "Payout rate limiter fail-open",
      "file": "apps/web/app/api/payouts/route.ts",
      "line": 45,
      "issue": "Missing operationType param means no rate limiting when Redis down",
      "fix": "Add operationType: 'payout' to rate limiter call",
      "status": "pending",
      "attempts": 0
    }
  ],
  "stats": {
    "total": 198,
    "critical": 17,
    "high": 57,
    "medium": 85,
    "low": 39,
    "completed": 0,
    "escalated": 0,
    "failed": 0
  }
}
```

## Field Reference

### Top-level

| Field | Type | Description |
|-------|------|-------------|
| project | string | Project name (from CLAUDE.md or directory name) |
| branch | string | Git branch name — run.sh reads this for resume |
| created | string | ISO timestamp of manifest creation |
| baseline | object | State of the project before the session started |
| never_touch | string[] | Glob patterns for files/dirs that must not be modified |
| validation_commands | object | Commands to run for typecheck, build, test, lint |
| tasks | Task[] | All discovered tasks |
| stats | object | Summary counts (informational — bash computes its own) |

### Task

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique ID: `{CATEGORY_PREFIX}-{NUMBER}` (e.g., SEC-001) |
| category | string | One of: security, dead-code, performance, type-safety, code-quality, tests, ui-accessibility, links, copy, database, auth, dependencies |
| severity | string | critical, high, medium, or low |
| title | string | Short description of the issue |
| file | string | Exact file path |
| line | number | Line number where the issue is |
| issue | string | What's wrong |
| fix | string | Suggested fix (what the agent should do) |
| status | string | pending, completed, escalated, or failed |
| attempts | number | How many times this task has been attempted |
| last_error | string? | Why it failed (only set when status is "failed") |
| test_tier | string? | Only for TEST-* tasks: `"scaffold"` (mechanical, overnight can fix) or `"logic"` (complex, escalate) |

### Category Prefixes

| Category | Prefix |
|----------|--------|
| security | SEC |
| dead-code | DEAD |
| performance | PERF |
| type-safety | TYPE |
| code-quality | QUAL |
| tests | TEST |
| ui-accessibility | UI |
| links | LINK |
| copy | COPY |
| database | DB |
| auth | AUTH |
| dependencies | DEP |

## Rules

1. **The bash loop reads stats from the tasks array, not the stats block.** The stats block is informational only — keep it roughly accurate but don't obsess.

2. **Tasks should be atomic.** One task = one issue in one file. Don't combine "fix 3 issues in file.ts" into one task.

3. **IDs are unique and never reused.** If a task is escalated and later fixed manually, don't recycle the ID.

4. **Manifest must always be valid JSON.** Write to a temp file and `mv` atomically. Never write partial JSON.

5. **The `attempts` field prevents infinite loops.** If attempts >= 2, the task must be escalated, not retried.

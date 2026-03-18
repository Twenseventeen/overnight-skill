<p align="center">
  <h1 align="center">/overnight</h1>
  <p align="center">
    Autonomous overnight code improvement for <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a>
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
    <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude_Code-skill-blueviolet" alt="Claude Code Skill"></a>
  </p>
</p>

---

Type `/overnight` before bed. Wake up to a PR with hundreds of fixes, a morning briefing of what needs your decision, and a full progress log of everything that happened.

## What Happens

**Before bed** - you run `/overnight` in any project. Claude scans your codebase with 12 parallel audit agents (security, dead code, performance, types, accessibility, etc.), shows you what it found, and asks you to confirm which files should never be touched. You start the runner in tmux and go to sleep.

**While you sleep** - a bash loop launches fresh Claude sessions that pick tasks from the manifest, fix them, run typecheck + build to verify, commit, and push. Each iteration is a new session so there's no context degradation even after 30+ rounds. If anything breaks, the iteration is auto-reverted. A draft PR appears on GitHub after the first commit and updates with every push.

**In the morning** - you have:
- A **PR** with all changes on a dedicated branch (never touches main)
- A **morning briefing** (`MORNING-REVIEW.md`) listing everything that needs your decision - architecture changes, business logic questions, things Claude wasn't sure about
- A **progress log** (`progress.md`) showing what was fixed, what failed, what was escalated, per iteration
- Token usage so you know the cost

## First Run

Production Next.js app, 232 fixes across 237 files, zero failures:

| | |
|---|---|
| Security | Zod validation, rate limiting, timing-safe comparisons |
| Dead code | 900+ lines removed |
| Type safety | Type guards replacing unsafe casts, null checks |
| Performance | Query parallelization, explicit selects, pagination |
| Accessibility | Aria labels, keyboard nav, loading skeletons |
| Links & copy | Broken links fixed, terminology unified |
| Dependencies | Unused packages removed, CVEs patched |

## Install

```bash
bash <(curl -s https://raw.githubusercontent.com/Twenseventeen/overnight-skill/main/install.sh)
```

Or manually:

```bash
git clone https://github.com/Twenseventeen/overnight-skill.git ~/.claude/skills/overnight
```

## Usage

```bash
/overnight
```

Confirm safety rails, then:

```bash
tmux new -s overnight
bash .planning/overnight/run.sh
```

## Safety

Runs headless with `bypassPermissions`. All safety enforced by **bash, not Claude:**

- **Never-touch list** - reverts if protected files are modified
- **Build gate** - typecheck + build must pass or iteration is reverted
- **Circuit breakers** - stops after 3 no-progress or 5 error iterations
- **Atomic commits** - code + state in one commit, pushed immediately
- **Always a PR** - never touches main

See [SECURITY.md](SECURITY.md) for the full model.

## Requirements

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) &middot; Python 3 &middot; Git &middot; macOS or Linux

## Contributing

PRs welcome.

## License

MIT

# Work Discovery

## Tech Stack Detection

Detect the project's tech stack to tailor audits and validation commands.

### Detection Logic

```
Check files in project root:
  package.json + next.config.* → Next.js
  package.json + vite.config.* → Vite/React
  package.json + nuxt.config.* → Nuxt/Vue
  package.json + svelte.config.* → SvelteKit
  package.json (no framework) → Node.js
  Gemfile + config/routes.rb → Rails
  requirements.txt / pyproject.toml / setup.py → Python
  go.mod → Go
  Cargo.toml → Rust
  pom.xml / build.gradle → Java
  *.csproj / *.sln → .NET

Check for database:
  supabase/ → Supabase/PostgreSQL
  prisma/ → Prisma
  drizzle.config.* → Drizzle
  config/database.yml → ActiveRecord
  alembic/ → SQLAlchemy

Check for monorepo:
  pnpm-workspace.yaml → pnpm workspaces
  turbo.json → Turborepo
  lerna.json → Lerna
  nx.json → Nx
```

### Validation Command Detection

```
If pnpm-lock.yaml exists → use pnpm
If yarn.lock exists → use yarn
If package-lock.json exists → use npm
If Gemfile.lock exists → use bundle exec

Detect available scripts from package.json:
  "typecheck" or "check-types" → typecheck command
  "build" → build command
  "test" → test command
  "lint" → lint command

Fallbacks:
  typecheck: "npx tsc --noEmit" (if tsconfig.json exists)
  build: "npm run build"
  test: "npm test"
  lint: "npx eslint ." (if .eslintrc* exists)

For non-JS:
  Go: typecheck="go vet ./...", build="go build ./...", test="go test ./...", lint="golangci-lint run"
  Python: typecheck="mypy .", build="echo ok", test="pytest", lint="ruff check ."
  Rails: typecheck="echo ok", build="echo ok", test="bundle exec rspec", lint="bundle exec rubocop"
  Rust: typecheck="cargo check", build="cargo build", test="cargo test", lint="cargo clippy"
```

## Audit Categories

### Which to Run

Not every category applies to every project. Skip irrelevant ones:

| Category | Skip if... |
|----------|-----------|
| Security | Never skip |
| Dead code | Never skip |
| Code quality | Never skip |
| Type safety | No TypeScript/typed language |
| UI/Accessibility | No frontend (pure API/CLI) |
| Links/Routes | No web frontend |
| Copy/Terminology | No user-facing text |
| Database | No database detected |
| Auth | No auth system detected |
| Dependencies | No package manager detected |
| Performance | Never skip |
| Tests | No test framework detected |

### Agent Prompts

Each agent gets a specific, scoped prompt. Adapt to the detected tech stack.

**IMPORTANT: Heading format consistency.** ALL audit agents MUST use this exact heading format:
```
### [CRITICAL|HIGH|MEDIUM|LOW] {title}
```
Do NOT use `### CRITICAL: title` or `### CRITICAL-01: title` — only the bracket format `### [SEVERITY] title`.

#### Security Audit Agent

```
Audit the following files for security issues:
[list of files, max 15-20]

Find:
- Hardcoded secrets (API keys, passwords, tokens)
- SQL injection vectors (raw queries, string concatenation in queries)
- XSS vectors (unsanitized user input rendered in HTML)
- Missing auth guards on API routes
- Rate limiting gaps on state-changing endpoints
- Error responses that leak stack traces or internal details
- CSRF protection gaps
- Insecure headers

Write ALL findings to .planning/overnight/audit-security.md
Format each finding as:
### [CRITICAL|HIGH|MEDIUM|LOW] {title}
- **File:** exact/path:line
- **Issue:** what's wrong
- **Fix:** exact change needed

Do NOT return findings in your message — write them to the file.
After writing, report only the summary: total, critical, high, medium, low.
```

#### Dead Code Audit Agent

```
Audit the following files for dead code:
[list of files, max 15-20]

Find:
- Unused imports
- Unused exports (exported but never imported elsewhere)
- Orphaned files (exist but no route/import leads to them)
- Dead CSS classes (defined but never used)
- Unused functions/components
- Commented-out code blocks

Method: Cross-reference imports/exports across the codebase.
Use grep to verify whether exports are imported anywhere.

Write ALL findings to .planning/overnight/audit-dead-code.md
[same format as above]
```

#### Code Quality Audit Agent

```
Audit the following files for code quality issues:
[list of files, max 15-20]

Find:
- Files exceeding 400 lines (flag at 400, critical at 800)
- Functions exceeding 50 lines
- Nesting depth > 4 levels
- console.log/warn/error statements
- TODO/FIXME/HACK comments
- Direct object/array mutation patterns
- Magic numbers (unexplained numeric literals)
- Hardcoded strings that should be constants
- Inconsistent naming conventions

Write ALL findings to .planning/overnight/audit-code-quality.md
[same format as above]
```

#### Type Safety Audit Agent

```
Audit the following TypeScript files for type safety issues:
[list of files, max 15-20]

Find:
- `any` type usage
- `as` type assertions (unsafe casts)
- Missing return types on exported functions
- Unsafe property access without null checks (no ?. or if check)
- Untyped function parameters
- @ts-ignore or @ts-expect-error comments

Write ALL findings to .planning/overnight/audit-type-safety.md
[same format as above]
```

#### Performance Audit Agent

```
Audit the following files for performance issues:
[list of files, max 15-20]

Find:
- N+1 query patterns (query inside a loop)
- Sequential queries that could be parallelized (Promise.all)
- select("*") or SELECT * queries (should select specific columns)
- Missing loading states for async pages/components
- Waterfall data fetching (sequential awaits that don't depend on each other)
- Large synchronous operations that could be deferred
- Missing pagination on list queries

Write ALL findings to .planning/overnight/audit-performance.md
[same format as above]
```

#### UI/Accessibility Audit Agent

```
Audit the following UI files for accessibility and consistency issues:
[list of files, max 15-20]

Find:
- Images without alt text
- Icon-only buttons without aria-label
- Heading hierarchy violations (skipped levels, multiple h1)
- Missing loading.tsx for async pages
- Missing error.tsx for route groups
- Hardcoded colors (hex/rgb/hsl) not using theme variables
- Fixed pixel widths without responsive alternatives
- Inconsistent spacing patterns across similar pages

Write ALL findings to .planning/overnight/audit-ui-accessibility.md
[same format as above]
```

#### Links/Routes Audit Agent

```
Audit the following files for broken links and routing issues:
[list of files, max 15-20]

Method:
1. Build a route map from the app directory structure
2. Find all href, Link, redirect, router.push references
3. Cross-reference: flag any link to a non-existent route

Also find:
- Redirect chains (A→B→C)
- Inconsistent paths (trailing slashes, case differences)
- Hardcoded URLs that should be relative

Write ALL findings to .planning/overnight/audit-links.md
[same format as above]
```

#### Copy/Terminology Audit Agent

```
Audit the following files for copy and terminology issues:
[list of files, max 15-20]

Find:
- Placeholder text ("Lorem ipsum", "TODO", "coming soon", "example.com")
- Inconsistent terminology (same concept called different names)
- Typos in user-visible strings
- Mixed language (e.g., German in English UI)
- Outdated references to old feature names

Write ALL findings to .planning/overnight/audit-copy.md
[same format as above]
```

#### Database Audit Agent

```
Audit the following files for database usage issues:
[list of files, max 15-20]

Find:
- select("*") in production code (should be explicit columns)
- Admin/service-role client used where user client would suffice
- Missing error handling on database queries
- Queries without proper typing
- Missing indexes suggested by query patterns
- Transaction boundaries missing for related operations

Write ALL findings to .planning/overnight/audit-database.md
[same format as above]
```

#### Auth Audit Agent

```
Audit the following files for auth and authorization issues:
[list of files, max 15-20]

Find:
- Protected routes accessible without authentication
- Role-based routes accessible by wrong roles
- Admin routes without admin check
- API routes without auth guard
- Missing CSRF protection on state-changing endpoints
- Session/token handling issues

Write ALL findings to .planning/overnight/audit-auth.md
[same format as above]
```

#### Dependencies Audit Agent

```
Audit the project's dependencies for issues.

Do:
1. Run the package manager's audit command (pnpm audit, npm audit, etc.)
2. Check for unused dependencies (in package.json but never imported)
3. Check for duplicate dependencies
4. Flag critically outdated packages

Write ALL findings to .planning/overnight/audit-dependencies.md
[same format as above]
```

#### Test Audit Agent

```
Audit the project's test suite.

Do:
1. Run the test suite, capture results
2. Identify failing tests
3. Identify critical paths with zero test coverage:
   - API routes with no corresponding test file
   - Financial/payment logic without tests
   - Auth flows without tests
4. Identify stale tests (referencing old routes, old text, old APIs)

Write ALL findings to .planning/overnight/audit-tests.md
[same format as above]
```

## File Scope Management

To prevent agent context overflow, limit each agent to 15-20 files.

For large codebases, split audit categories into multiple agents:

```
If app/api/ has > 20 files:
  Security agent 1: app/api/admin/ + app/api/auth/
  Security agent 2: app/api/campaigns/ + app/api/payouts/
  Security agent 3: remaining API routes

If app/ has > 20 page files:
  UI agent 1: app/(public)/ pages
  UI agent 2: app/creator/ pages
  UI agent 3: app/brand/ + app/admin/ pages
```

Each split agent writes to the same category file (append, don't overwrite).

# ERROR HUNTER

**Codebase audit skill for AI agents. Language-agnostic.**

You are auditing a codebase someone else wrote. You have file access and shell access. You do not have the original developer. You do not have a test suite you trust. You do not necessarily have the spec. Your job is to find real bugs, prove they exist with evidence, and report them with enough specificity that a human or another agent can fix them without re-reading the entire codebase.

This document tells you how.

---

## OPERATING RULES

1. **Read before touching.** Never edit, refactor, or "fix" anything during an audit pass. Auditing and fixing are separate phases. Mixing them corrupts your findings.

2. **Evidence-based only.** Every finding you report must include: the exact file and line number, the code snippet demonstrating the bug, a concrete scenario where it manifests, and severity. No "this could be improved" findings. No style opinions. Bugs only.

3. **Reproduce or prove by reasoning.** For every bug you claim, either (a) demonstrate it running (write a minimal test or run the code against inputs that trigger it), or (b) prove it by citing specific language semantics. "Race condition" is not a finding. "Two callers of `increment()` can interleave between lines 47 (read) and 49 (write) because there is no lock or atomic operation in between" is a finding.

4. **Confidence gradient.** Tag every finding CONFIRMED (you reproduced it), LIKELY (strong static reasoning, not reproduced), or POSSIBLE (suspect pattern worth human review). Never present POSSIBLE as CONFIRMED.

5. **Do not speculate about intent.** If code does X and X is wrong, report X is wrong. Do not write "the developer probably meant Y." You do not know what they meant.

6. **Language-agnostic.** Do not assume Python, JavaScript, Go, Rust, Java, C, or anything else. Detect the language from file extensions and contents. Apply the language-specific checks from the Language Primers section.

7. **Do not trust comments, docstrings, or variable names.** They lie. They go stale. Read what the code actually does.

8. **Do not trust the test suite.** Tests prove what they test. A green test suite means nothing when the test coverage is 12% of the code paths. Before trusting tests, measure coverage if possible. If coverage is unknown, assume it's zero.

9. **Stop conditions.** Audit in bounded rounds. Do not audit forever. After each round, report findings and ask whether to continue. Typical stop points are listed in the Audit Workflow section.

10. **No fabrication.** If you cannot determine something, say so. Do not guess at a function's behavior, a library's semantics, or a config value. Read the source or run the code.

---

## PHASE 0: RECONNAISSANCE

Before any auditing logic runs, you must build a map of the codebase. Do not skip this phase. Auditing without a map produces context-free findings that are 50% wrong.

### 0.1 Inventory

Run these commands (or the equivalent in your environment) and record results.

```bash
# File and directory layout
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/__pycache__/*' -not -path '*/venv/*' -not -path '*/.venv/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/target/*' | head -500

# Language breakdown (by file extension)
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | sed -n 's/.*\.\([^.]*\)$/\1/p' | sort | uniq -c | sort -rn | head -20

# Entry points (package manifests, config files)
ls -la package.json pyproject.toml requirements.txt Pipfile Cargo.toml go.mod pom.xml build.gradle Gemfile composer.json mix.exs deno.json 2>/dev/null

# README / docs
ls -la README* CHANGELOG* CONTRIBUTING* docs/ 2>/dev/null

# Config and env
ls -la .env.example .env.sample config/ configs/ 2>/dev/null
find . -name '*.config.*' -not -path '*/node_modules/*' -not -path '*/.git/*' | head -20

# Tests
find . -type d -name 'test' -o -name 'tests' -o -name '__tests__' -o -name 'spec' | head -10
```

### 0.2 Identify what you're looking at

From the inventory, determine:

- **Primary language(s).** Most file extensions point at this.
- **Framework(s).** package.json dependencies, pyproject.toml, go.mod imports. Look for: Next.js, Express, FastAPI, Django, Flask, Rails, Spring, Gin, Actix, etc.
- **Runtime target.** Server (Node, Python, Go binary), browser, mobile, serverless, CLI, daemon, library.
- **Database.** Look for migrations folders, ORM configs (Prisma schema, SQLAlchemy models, Sequelize models, GORM structs). Note the DB engine (Postgres, MySQL, SQLite, MongoDB, DynamoDB).
- **External services.** Scan for SDK imports (`stripe`, `anthropic`, `openai`, `twilio`, `aws-sdk`, `@supabase/supabase-js`, etc).
- **Deployment target.** `vercel.json`, `netlify.toml`, `Dockerfile`, `docker-compose.yml`, `fly.toml`, `railway.json`, k8s manifests.
- **Auth system.** Look for `auth`, `jwt`, `session`, `@supabase/auth`, `next-auth`, `passport`, `devise`, `django.contrib.auth`.

Record this as a one-page "What is this" summary at the top of your report.

### 0.3 Identify entry points

Entry points are where data enters the system. Every bug category has entry-point-specific checks. Find them before you audit.

- **HTTP routes.** Grep for route definitions. Patterns by framework:
  - Express/Fastify: `app.get(`, `app.post(`, `router.get(`, `router.post(`
  - Next.js: files under `pages/api/`, `app/api/`, `app/**/route.ts`
  - FastAPI: `@app.get(`, `@app.post(`, `@router.`
  - Django: `urlpatterns`, `path(`, `re_path(`
  - Flask: `@app.route(`, `@bp.route(`
  - Rails: `config/routes.rb`
  - Go net/http: `http.HandleFunc(`, Chi/Gin: `r.GET(`, `r.POST(`
  - Spring: `@GetMapping`, `@PostMapping`, `@RequestMapping`
- **Background jobs.** Cron entries, queue workers, scheduled functions. Patterns: `vercel.json` crons, Celery tasks, BullMQ queues, Sidekiq workers, Kubernetes CronJobs.
- **Webhooks.** Routes that receive POST from external services. Usually match the HTTP route search above plus names containing `webhook`, `callback`, `hook`.
- **CLI commands.** `bin/`, `cmd/`, `scripts/`, commander/click/cobra definitions.
- **Message consumers.** Kafka consumers, SQS pollers, Pub/Sub subscribers, Redis stream readers.
- **Scheduled tasks inside code.** `setInterval`, `setTimeout` that fire recurring work, goroutines with tickers.

Record a list of entry points with file paths. You will audit each one.

### 0.4 Identify the data layer

Find where data is read from and written to. This is where most real bugs live.

- **Database queries.** Raw SQL in strings, query builder calls, ORM method calls (`.find`, `.create`, `.update`, `.save`, `.query`, `.execute`).
- **External API calls.** `fetch(`, `axios.`, `requests.`, `http.Client`, SDK method calls.
- **File I/O.** `fs.readFile`, `open()`, `ioutil.ReadFile`, bucket/blob storage clients.
- **Cache access.** Redis clients, in-memory caches, memoization decorators.

---

## PHASE 1: THE 10 AUDIT METHODS

These are ten separate analytical passes. Each catches a different class of bug. Run them all. Findings from one method often lead to suspicion for another.

### Method 1. Trust boundary analysis

Every input from outside the process is untrusted. Find every boundary and verify the code validates inputs at the boundary, not after they've been mixed into trusted code.

**Boundaries to check.**

- HTTP request bodies, query strings, path params, headers, cookies
- Webhook payloads (even from trusted vendors - assume forged until signature verified)
- Message queue payloads
- Files uploaded by users
- Environment variables (trusted at read time, but often missing, empty, or wrong type)
- Database reads from tables users can write to
- External API responses

**What to look for.**

```
[ ] Every HTTP handler validates body/params with a schema (zod, pydantic, joi, ajv, marshmallow, etc) OR manual type checks
[ ] Every webhook handler verifies the signature BEFORE accessing the payload
[ ] Every file upload checks size limits, content type, and content itself (magic bytes, not just extension)
[ ] Every env var read is either validated at startup or has a safe default
[ ] SQL queries do not use string concatenation or template literals with user input (SQL injection)
[ ] Shell commands do not use string concatenation with user input (command injection)
[ ] HTML rendering escapes user input (XSS) - check both backend templates and frontend innerHTML/dangerouslySetInnerHTML
[ ] Object lookups by user-supplied key do not allow prototype pollution (JS) or class pollution (Python)
[ ] File path construction does not allow path traversal (../ or absolute paths from user input)
[ ] Deserialization (pickle, unserialize, YAML.load, Marshal) does not accept untrusted input
```

**Grep patterns.**

```bash
# SQL injection candidates
grep -rn -E 'query\(.*\$\{|query\(.*f["\x27]|execute\(.*f["\x27]|SELECT.*\+|INSERT.*\+' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rb' --include='*.java'

# Dangerous deserialization
grep -rn -E 'pickle\.loads|yaml\.load\(|unserialize\(|Marshal\.load|eval\(|new Function\(' --include='*.py' --include='*.js' --include='*.ts' --include='*.rb' --include='*.php'

# Command injection
grep -rn -E 'exec\(|spawn\(|system\(|popen\(|Runtime\.exec|os\.system|subprocess\.(call|run|Popen).*shell=True' --include='*.py' --include='*.js' --include='*.ts' --include='*.go' --include='*.java' --include='*.rb'

# innerHTML / dangerouslySetInnerHTML
grep -rn -E 'innerHTML|dangerouslySetInnerHTML|v-html|{@html' --include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx' --include='*.vue' --include='*.svelte'

# Path traversal candidates
grep -rn -E 'path\.join\(.*req\.|path\.resolve\(.*req\.|open\(.*request\.' --include='*.js' --include='*.ts' --include='*.py'
```

For each match, read the code. Determine if input reaches the dangerous sink without sanitization. If yes, CONFIRMED finding.

### Method 2. Concurrency and race audit

Any shared mutable state accessed from multiple concurrent callers is a race candidate. For each piece of shared state, determine if access is synchronized.

**Sources of concurrency.**

- Multiple HTTP request handlers in the same process
- Goroutines, threads, async tasks
- Message queue workers scaling out
- Multiple serverless function instances
- Cron jobs running alongside request handlers
- Database triggers firing during transactions

**Shared state locations.**

- Module-level variables (especially mutable: `let counter = 0`, `cache = {}`, `self.x = []`)
- Singleton instances
- Database rows read and written by multiple code paths
- Files on disk read and written by multiple processes
- Redis keys
- In-memory caches (Map, dict, LRU cache)

**Patterns that indicate a race bug.**

```
[ ] Read-check-write without atomic operation
    Example: SELECT count; if count < max: INSERT
    Fix: INSERT INTO ... SELECT ... WHERE (SELECT count ...) < max, or UPDATE ... WHERE ... RETURNING
[ ] Check-then-act on filesystem
    Example: if !exists(path): write(path)
    Fix: atomic create (O_EXCL), atomic rename, or lockfile
[ ] Increment without atomic operation
    Example: x = x + 1, counter += 1 on shared state
    Fix: atomic add, database UPDATE ... SET x = x + 1, Redis INCR
[ ] In-memory rate limiter on serverless
    Example: a Map of user_id -> last_request_time stored in a module variable
    Fix: move to Redis, database, or managed rate limiter. Serverless instances don't share memory.
[ ] Transaction scope too narrow or too wide
    Narrow: two related writes happen without BEGIN/COMMIT, partial state visible
    Wide: transaction wraps an external API call, holding a lock for seconds
[ ] Lock acquisition in inconsistent order
    Code path A: lock X then lock Y. Code path B: lock Y then lock X. Deadlock.
[ ] Missing idempotency on webhooks
    Example: webhook handler credits user account. Webhook fires twice. Account credited twice.
    Fix: UNIQUE constraint on provider_event_id, return 200 on duplicate.
```

**How to confirm.**

For a suspected race, write a minimal concurrent reproducer. Example for Node: fire 10 simultaneous HTTP requests with Promise.all. For Python: use threading or asyncio.gather. Measure the final state. If it doesn't match "one logical operation per request," you have a race.

If you cannot run the code, prove the race via execution order. Walk through the critical section with two simulated callers A and B. Show that ordering (A reads, B reads, A writes, B writes) produces an incorrect state.

### Method 3. Error handling audit

Errors are where bugs hide. Code that doesn't handle errors correctly appears to work until the error actually happens.

**Failure modes to check.**

```
[ ] try/catch blocks that swallow errors (catch { } or except: pass)
[ ] Promise rejections not caught (unhandled promise rejection)
[ ] Async functions called without await (fire-and-forget)
[ ] Errors caught and re-thrown as different types that lose context
[ ] Catch blocks that log but don't return, causing code to continue with bad state
[ ] HTTP handlers that don't return on error (continue processing broken request)
[ ] Database transactions that don't ROLLBACK on error path
[ ] Resources (file handles, DB connections, network sockets) not closed on error path
[ ] Retry loops with no max retries (infinite retry on permanent failure)
[ ] Retry loops with no backoff (retry storm against a failing dependency)
[ ] Fallback paths that mask the real error (on failure: return null, return empty array)
[ ] Logging errors without stack traces
```

**Grep patterns.**

```bash
# Swallowed errors
grep -rn -B1 -A2 -E 'catch\s*\([^)]*\)\s*\{\s*\}|except[^:]*:\s*pass|except[^:]*:\s*$|rescue\s*$' --include='*.js' --include='*.ts' --include='*.py' --include='*.rb'

# Fire-and-forget async
grep -rn -E '^\s*(async\s+)?[a-zA-Z_][a-zA-Z0-9_]*\(' --include='*.js' --include='*.ts' | grep -v 'await\|return\|=\s*await\|Promise\.' | head -50
# Then read context around each hit

# No-retry-limit loops
grep -rn -B1 -A5 -E 'while\s*\(\s*true|for\s*\(\s*;\s*;\s*\)|while\s+True:' --include='*.js' --include='*.ts' --include='*.py' --include='*.go'
```

For each match, read the surrounding 20 lines. Determine if the error path is correct.

### Method 4. Resource and cleanup audit

Code that opens resources and doesn't close them causes leaks. Leaks don't show up until the process has been running long enough.

**Resources to track.**

- Database connections (explicit connect/disconnect or connection pools)
- HTTP clients (keep-alive connections, sockets)
- File handles
- Timers and intervals
- Event listeners (EventEmitter, DOM events, RxJS subscriptions, message queue consumers)
- Goroutines (unbounded spawn without wait groups)
- Tokio/asyncio tasks
- Locks and semaphores

**Patterns that indicate a leak.**

```
[ ] Open without a corresponding close in ALL code paths (including error paths)
[ ] setInterval without clearInterval
[ ] addEventListener without removeEventListener (especially in React/Vue components or long-lived processes)
[ ] Goroutines started in a loop without bounded count
[ ] Connection pools without max size
[ ] Memoization caches without size limit or TTL (grows forever)
[ ] Reading entire file into memory when streaming would work
[ ] Loading entire table into memory when pagination would work
```

**Language-specific patterns.**

- Node.js: resources should use `try/finally`, `using` declarations (ES2023+), or `async disposal`. Look for `.end()`, `.close()`, `.destroy()` calls.
- Python: resources should use `with` blocks. Look for files/connections opened outside `with`.
- Go: `defer Close()` immediately after open. Look for any `Open`/`Dial`/`Create` without a `defer` on the next line.
- Rust: ownership should make this impossible, but look for `Rc`/`Arc` cycles, `Box::leak`, explicit `mem::forget`.
- Java: try-with-resources for Closeable.

### Method 5. State machine and invariant audit

Many bugs come from code assuming a state that's no longer true. Identify the state machines in the code (explicit or implicit) and verify every transition.

**How to find state machines.**

- Fields named `status`, `state`, `phase`, `kind`, `type` with text/enum values
- Boolean fields that work together (`is_paid`, `is_shipped`, `is_cancelled`)
- Lifecycle methods: `activate`, `deactivate`, `cancel`, `resolve`, `expire`
- State columns in database schema

**What to audit.**

```
[ ] List all possible values for each state field. Read the code, not the spec.
[ ] For each value, list which transitions are allowed to which other values.
[ ] For each transition, find the code that performs it. Verify:
    - The transition is atomic (database UPDATE, not read-check-write)
    - The starting state is verified (UPDATE ... WHERE status = 'expected_previous')
    - Side effects fire exactly once (not at all if transition fails, not twice if it races)
[ ] Find queries that filter by state. Verify they match the actual possible values (no typos, no missing cases).
[ ] Find switch/match statements on the state field. Verify they handle every case or have a safe default.
[ ] Check for "impossible" combinations of boolean flags. E.g., is_paid=true AND is_cancelled=true. Code assumes this can't happen; data may disagree.
```

### Method 6. Boundary and edge value audit

For every numeric input, every string length, every array size: test the boundaries.

**The standard boundary set.**

```
Integer:    -1, 0, 1, INT_MAX, INT_MIN, NULL
Float:      -0.0, 0.0, NaN, +Infinity, -Infinity, subnormals
String:     "", " ", "\n", "\0", very long, unicode, RTL chars, emoji, null-byte
Array:      [], [one element], [million elements], null, not-an-array
Dict/Map:   {}, missing key, null value, key with special chars
Date:       epoch 0, year 1, year 9999, 1970-01-01, DST transition, leap second
Timestamp:  past, future, now, same as another timestamp to millisecond
Bytes:      empty, single byte, binary 0x00, non-UTF8 sequence
UUID:       valid v4, valid v7, all zeros, wrong length, uppercase vs lowercase
Money:      0, 0.01, largest currency value, negative, currency mismatch
```

**How to apply.**

For each API endpoint, each function that accepts external input, each parsing routine: walk the boundary set. Check:

- Does the code handle this value without crashing?
- Does it produce a sensible result, or does it silently pass garbage downstream?
- Does it reject invalid values at the boundary, or does it accept them and explode in an unrelated code path later?

**Grep-driven sweep.**

```bash
# Division without zero-check nearby
grep -rn -E '/\s*[a-zA-Z_][a-zA-Z0-9_]*|divmod\(|\.div\(' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rb'

# parseInt/Number/Float without isNaN check
grep -rn -B1 -A3 -E 'parseInt\(|parseFloat\(|Number\(|Integer\.parseInt|Float\.parseFloat|int\(|float\(' --include='*.js' --include='*.ts' --include='*.py' --include='*.java'

# Array access without length check
grep -rn -E '\[0\]|\[.*\.length\s*-\s*1\]' --include='*.js' --include='*.ts' | head -20

# String length assumed
grep -rn -E '\.substring\(|\.slice\(|\.substr\(|\[[0-9]+\]|\.charAt\(' --include='*.js' --include='*.ts' | head -20
```

### Method 7. Authentication and authorization audit

Every route, every function, every data access path must answer: "who is allowed to do this, and is that being enforced?"

**Checklist.**

```
[ ] Every HTTP route either requires auth or is explicitly marked public
[ ] Every "requires auth" route verifies the session is valid (not just present)
[ ] Session cookies are HttpOnly, Secure, SameSite=Strict or Lax
[ ] JWT tokens are verified with the correct algorithm (reject 'none', reject alg confusion)
[ ] Authorization checks happen in addition to authentication (user X is authenticated, but can they access resource Y?)
[ ] Row-level security or equivalent is enforced at the database layer, not just the application layer
[ ] Admin routes require an explicit admin check, not just authentication
[ ] Password reset, email change, and account deletion require re-authentication
[ ] Rate limiting is applied to auth endpoints (login, password reset, MFA)
[ ] Tokens for password reset / email verification are single-use and time-limited
[ ] CSRF protection is enabled on state-changing routes (unless the API is token-only)
[ ] CORS is configured restrictively (no wildcard origins on endpoints with credentials)
```

**How to find missing auth.**

List every route from Phase 0. For each, trace the code to determine what auth check runs. Build a table: route, method, auth requirement, admin requirement, what's enforced in code. Flag every row where the code doesn't match what you'd expect.

**Common mistakes.**

- Middleware order wrong: body parser runs before auth, so a 401 response still consumed the body and may have logged sensitive data
- Auth check on read but not on write endpoints
- Authorization check uses user-supplied id instead of session-bound id (IDOR)
- Admin check uses client-supplied "is_admin" header instead of database lookup

### Method 8. Dependency and supply-chain audit

Every external dependency is code you didn't write running in your process. It's also code that can change, break, or become malicious.

**Checks.**

```
[ ] Lockfile committed (package-lock.json, yarn.lock, Pipfile.lock, poetry.lock, Cargo.lock, go.sum)
[ ] Dependencies pinned to specific versions or tight ranges (not "*" or "latest")
[ ] No dependencies from untrusted sources (typosquat check: right spelling, right author)
[ ] No critical dependencies unmaintained (last publish > 2 years, zero recent commits)
[ ] No duplicate dependencies at incompatible versions (npm ls, pipdeptree, go mod graph)
[ ] Dev dependencies not shipped to production
[ ] Known-vulnerable versions flagged (run npm audit, pip-audit, cargo audit, govulncheck)
[ ] No postinstall scripts that run code from dependencies (package.json scripts field)
```

**Commands to run.**

```bash
# JavaScript/TypeScript
npm audit --json 2>/dev/null || pnpm audit --json 2>/dev/null || yarn audit --json 2>/dev/null
npm outdated 2>/dev/null

# Python
pip-audit 2>/dev/null || safety check 2>/dev/null

# Go
govulncheck ./... 2>/dev/null

# Rust
cargo audit 2>/dev/null

# Ruby
bundle audit 2>/dev/null
```

Parse the output. Report any HIGH or CRITICAL vulnerabilities as findings.

### Method 9. Database and persistence audit

The database is where state lives. Bugs here corrupt reality.

**Schema audit.**

```
[ ] Every text column that holds enum-like values has a CHECK constraint
[ ] Every column that should be required has NOT NULL
[ ] Every column that should be unique has a UNIQUE constraint or UNIQUE index
[ ] Foreign keys have ON DELETE behavior specified (CASCADE, SET NULL, RESTRICT)
[ ] Indexes exist for every WHERE clause that runs on a large table
[ ] No columns that grow unbounded without a retention policy
[ ] Timestamp columns use timezone-aware types (TIMESTAMPTZ in Postgres, not TIMESTAMP)
[ ] Money stored as integer cents or Decimal, not float
[ ] Primary keys are not sequential integers exposed in URLs (prefer UUIDs or encoded IDs for external references)
```

**Query audit.**

```
[ ] No SELECT * in production code (schema changes silently break assumptions)
[ ] No N+1 queries (loop that queries inside the iteration)
[ ] LIMIT present on queries over large tables
[ ] Pagination uses keyset/cursor, not OFFSET (OFFSET becomes expensive at high page numbers)
[ ] Transactions are as short as possible (no external API calls inside a transaction)
[ ] UPSERT operations handle conflict correctly (ON CONFLICT DO UPDATE, not DO NOTHING when you need update)
[ ] DELETE operations have WHERE clauses (search codebase for "DELETE FROM" not followed by WHERE within a line or two)
```

**Migration audit.**

```
[ ] Migrations are forward-only (no destructive changes without a rollout plan)
[ ] Migrations can run on a live system (no ALTER TABLE that requires full table lock at scale)
[ ] Migrations have been applied to staging before production (check version table)
```

**Grep patterns.**

```bash
# N+1 query candidates
grep -rn -B2 -A5 -E 'for\s+.*in\s+|forEach\(|\.map\(' --include='*.js' --include='*.ts' --include='*.py' --include='*.rb' | grep -A3 -E 'query|find|select|execute' | head -40

# DELETE without WHERE
grep -rn -E 'DELETE\s+FROM\s+[a-z_]+\s*(;|$|")' --include='*.js' --include='*.ts' --include='*.py' --include='*.sql' --include='*.rb'

# SELECT *
grep -rn -E 'SELECT\s+\*\s+FROM' --include='*.js' --include='*.ts' --include='*.py' --include='*.sql' --include='*.rb' --include='*.go'
```

### Method 10. Configuration and secrets audit

Production bugs often come from configuration, not code.

**Checks.**

```
[ ] No secrets hardcoded in source (API keys, passwords, tokens, signing secrets)
[ ] .env, .env.local, .env.production NOT in git (check .gitignore)
[ ] All env vars the code reads are documented in .env.example or equivalent
[ ] Code fails loudly at startup if required env vars are missing (not silently defaults)
[ ] Env vars with secrets are never logged (search for console.log of env values)
[ ] Debug/verbose flags are off in production (NODE_ENV=production, DEBUG=False, RAILS_ENV=production)
[ ] CORS origins are not wildcarded in production config
[ ] Database URLs use SSL in production
[ ] Feature flags have a default behavior specified
```

**Grep patterns.**

```bash
# Hardcoded secrets (common patterns)
grep -rn -E '(api[_-]?key|secret|password|token)\s*[:=]\s*["\x27][A-Za-z0-9_\-]{20,}' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rb' --include='*.java'

# AWS access keys
grep -rn -E 'AKIA[0-9A-Z]{16}' .

# JWT secrets
grep -rn -E 'jwt.*secret.*["\x27][^"\x27]{10,}' --include='*.js' --include='*.ts' --include='*.py'

# Check .gitignore
cat .gitignore 2>/dev/null | grep -E '\.env|secrets'
```

Run `git log --all --full-history -- "*.env*" 2>/dev/null | head` to check if env files were ever committed and later removed. A committed secret is a leaked secret even if removed later.

---

## PHASE 2: LANGUAGE PRIMERS

Add these checks on top of the general methods, selected by what you found in Phase 0.

### JavaScript / TypeScript

```
[ ] == vs ===: any == in security-relevant comparisons is a finding
[ ] Nullish handling: `||` defaults on 0, '', false (often unintended). Prefer `??`
[ ] Array.forEach with async callback: does not await (fire-and-forget disaster in loops)
[ ] Object spread mutability: shallow only, nested objects share references
[ ] Floating point money: `0.1 + 0.2 !== 0.3`. Money must be integer cents or Decimal library
[ ] Unhandled promise rejection: missing `.catch` or try/await, process may crash
[ ] JSON.parse without try: malformed input crashes the handler
[ ] Prototype pollution: `Object.assign({}, userInput)` where userInput has `__proto__`
[ ] Regex DoS: user-supplied input fed to regex that can backtrack catastrophically
[ ] Date() with string input: parsing is implementation-dependent and often wrong
[ ] Numeric strings from env: `process.env.PORT` is a string; `parseInt` without radix or NaN check
[ ] `new Function()` or `eval()`: remote code execution if input is user-controlled
[ ] TypeScript `as any` casts: type system defeated, check what's being cast
[ ] `// @ts-ignore` and `// @ts-expect-error`: type errors silenced, read each one
[ ] Reach around ORM with raw SQL: check for SQL injection
[ ] Next.js: `getServerSideProps` vs `getStaticProps` correct use, middleware runtime correct
[ ] React: missing useEffect dependencies (stale closures), key prop missing on lists, state updates after unmount
```

### Python

```
[ ] Mutable default arguments: `def f(x=[])` shares the same list across calls
[ ] Bare `except:` catches KeyboardInterrupt and SystemExit
[ ] `except Exception as e: pass` swallows errors
[ ] `==` on strings vs `is`: `is` is identity not equality, works for small ints/short strings by accident
[ ] Integer division in Python 2 codebases: `/` truncated; check Python version in setup
[ ] `yaml.load()` without SafeLoader: arbitrary code execution
[ ] `pickle.loads()` on untrusted data: arbitrary code execution
[ ] `subprocess(..., shell=True)` with user input: command injection
[ ] `requests.get()` without timeout: hangs forever on slow server
[ ] `json.loads` without try: malformed input raises
[ ] Thread safety of class attributes: mutable class-level state is shared across all instances
[ ] GIL assumptions: multi-threading doesn't parallelize CPU work; multiprocessing does
[ ] async/await: `asyncio.gather` vs sequential await, missing await on coroutines
[ ] Django: missing `@login_required`, `@csrf_exempt` unnecessarily used, raw SQL without parameterization
[ ] SQLAlchemy: session scope, missing commits, lazy loading causing N+1
[ ] FastAPI: Pydantic model use on inputs, response_model set correctly
```

### Go

```
[ ] Error returns ignored: `_, _ := fn()` or `fn()` without checking the error
[ ] Goroutine leaks: `go fn()` with no way to stop, no wait group, no context cancellation
[ ] Channel deadlocks: send on unbuffered channel with no receiver, close a channel twice
[ ] defer inside a loop: resource held until function returns, not loop iteration
[ ] Nil map writes: `var m map[string]int; m["key"] = 1` panics
[ ] Slice aliasing: `s2 := s1[0:10]` shares backing array; mutating s2 mutates s1
[ ] Time comparisons: `time.Now()` has monotonic component; use `.Equal()` not `==`
[ ] Context cancellation: passing context through but never checking ctx.Done()
[ ] Shared struct mutation across goroutines: race detector should catch, run `go test -race`
[ ] Interface nil trap: `var err error = (*MyError)(nil); err != nil` is TRUE (typed nil)
[ ] Database/sql: rows.Close() in defer, check rows.Err() after loop
[ ] HTTP handlers: response written after return (no return after WriteHeader in error path)
```

### Rust

```
[ ] `unwrap()` in library code: panics on None/Err, should return Result
[ ] `expect()` with unhelpful message: "this shouldn't fail" is not diagnostic
[ ] `clone()` as copy shortcut: may hide a perf problem or logical bug
[ ] `unsafe` blocks: scrutinize each one, verify invariants
[ ] `Arc<Mutex<T>>` deadlocks: hold two mutexes in inconsistent order
[ ] `async`: `.await` missing on futures, spawning without tracking join handles
[ ] `block_on` inside async context: deadlocks the runtime
[ ] `Drop` order assumptions: fields drop in declaration order, not always what you expect
[ ] `mem::transmute`: guaranteed bug unless you really know what you're doing
[ ] Cargo features: conditional compilation may hide untested code paths
```

### Java / Kotlin

```
[ ] Equals/hashCode contract: override both or neither, must be consistent
[ ] NullPointerException: every field access on a non-Optional reference is a candidate
[ ] Integer overflow: `int * int` silently overflows; use Math.multiplyExact or long
[ ] SimpleDateFormat not thread-safe: used as static/field, concurrency bug
[ ] ExecutorService not shut down: threads leak
[ ] try-with-resources missing on Closeable: resource leak
[ ] Synchronization on mutable reference: synchronized on `this` when `this` is reassigned
[ ] Stream not closed: InputStream/OutputStream/Reader/Writer needs close
[ ] equals on autoboxed types: `Integer i = 1000; i == 1000` false for values > 127
[ ] SQL injection: Statement.execute(userInput) vs PreparedStatement
```

### Ruby

```
[ ] `rescue => e` without specific class: catches everything including StandardError subclasses
[ ] `send(user_input)`: arbitrary method invocation, often RCE
[ ] `eval`, `instance_eval`, `class_eval`: arbitrary code
[ ] `YAML.load`: RCE vs `YAML.safe_load`
[ ] Mass assignment: `User.new(params)` without strong_parameters
[ ] N+1 queries: ActiveRecord lazy loading in iteration, use `includes` or `preload`
[ ] `Time.now` vs `Time.current`: timezone mismatch in Rails
[ ] Migration with `change_column` on large tables: locks the table
```

### PHP

```
[ ] `include` or `require` with user input: RCE
[ ] `extract()` on untrusted array: variable injection
[ ] Loose equality `==`: `"0e123" == "0e456"` is TRUE (type juggling)
[ ] `unserialize` on untrusted data: RCE
[ ] SQL queries without prepared statements
[ ] `file_get_contents` with URL: SSRF if user controls the URL
```

### SQL (any dialect)

```
[ ] String concatenation building queries
[ ] ORDER BY user input: possible SQL injection even with parameters for WHERE
[ ] LIKE patterns from user input: escape % and _
[ ] IN clauses with dynamic size: build parameterized placeholders, don't concatenate
[ ] TRUNCATE, DROP, DELETE accessible via application code path
```

### Shell scripts

```
[ ] Unquoted variable expansion: `rm $file` breaks on spaces
[ ] `set -e` not set: errors don't halt the script
[ ] `set -u` not set: undefined vars silently empty
[ ] `set -o pipefail` not set: pipe failures hidden
[ ] `rm -rf "$x/"` where $x might be empty: `rm -rf /`
[ ] Curl without `-f`: silent failure on HTTP error
[ ] Backticks in shell: command injection if expanded with user input
```

---

## PHASE 3: REPORTING

Every audit produces a report with a specific structure. This is non-negotiable. Downstream tools and humans depend on the format.

### Report structure

```markdown
# AUDIT REPORT: [project name or path]

## Summary

- Files audited: [count]
- Lines of code audited: [count]
- Findings: [count] (P0: N, P1: N, P2: N)
- Confidence breakdown: [CONFIRMED: N, LIKELY: N, POSSIBLE: N]
- Time spent: [duration]

## Codebase Overview

Primary language: [lang]
Frameworks: [list]
Runtime: [server/browser/mobile/etc]
Database: [engine]
External dependencies: [key ones]
Deployment target: [platform]
Auth system: [implementation]

## Findings

[One subsection per finding, in P0 -> P1 -> P2 order]

### [FINDING-ID] [SEVERITY] [CONFIDENCE]: [one-line description]

**File:** path/to/file.ext:line_number
**Category:** [which method found it, e.g., "Method 2: Concurrency"]

**Code:**
```[language]
[exact snippet demonstrating the bug, with 2-3 lines of context above/below]
```

**Bug:**
[1-3 sentences explaining what's wrong. No speculation about intent.]

**Impact:**
[Concrete scenario where the bug manifests. Who sees it, what breaks, what data is at risk.]

**Reproducer:** [required for CONFIRMED findings]
```[language or shell]
[minimal code or command that triggers the bug]
```
OR

**Reasoning:** [required for LIKELY or POSSIBLE findings]
[explanation of why the bug exists based on static analysis of the code]

**Suggested fix:**
[One or two approaches. Don't implement. Just describe.]

---

[next finding]
```

### Finding ID scheme

`[PHASE][METHOD][SEQUENCE]`

- PHASE: single letter, A-Z, incremented per audit run
- METHOD: method number that found it (1-10)
- SEQUENCE: 01, 02, 03... per method within this phase

Examples: `A-01-03` (first audit, Method 1, third finding), `B-05-02` (second audit, Method 5, second finding).

### Severity rubric

- **P0.** Production is broken or data is corrupting RIGHT NOW, or the bug is trivially exploitable. Fix before any other work.
- **P1.** Real bug. Users hit it under normal usage. Fix before next release.
- **P2.** Bug with limited impact, edge case, or hardening. Schedule for fix.

Hardening opportunities that are not bugs (missing CHECK constraints on a field the app validates, for example) are P2 or lower. Not every suggestion is a bug.

### Confidence rubric

- **CONFIRMED.** You have a reproducer or observed the bug running. Highest trust.
- **LIKELY.** Strong static reasoning points at a bug. You have not run it. Explain the reasoning.
- **POSSIBLE.** Pattern matches a known bug family but you cannot prove it without more context. Ask for human review.

If you cannot clearly place a finding in one of these three, you do not have a finding. You have a suspicion. Investigate until you do, or drop it.

---

## AUDIT WORKFLOW

How to run an audit start to finish.

### Round 1: Recon and surface sweep
1. Phase 0 (reconnaissance). Build the map. Do not file any findings.
2. Methods 1, 3, 10 (trust boundaries, error handling, config). These have the highest hit rate on a fresh codebase.
3. Write up findings. STOP. Report and wait for next instruction.

### Round 2: Concurrency and state
1. Methods 2, 5 (concurrency, state machines).
2. If the codebase has background jobs, webhooks, or multi-instance deploy, this round usually finds the most serious bugs.
3. Write up findings. STOP.

### Round 3: Data and resources
1. Methods 4, 6, 9 (resources, boundaries, database).
2. Run dependency scanners (Method 8) in parallel if not yet done.
3. Write up findings. STOP.

### Round 4: Authorization
1. Method 7 (auth/authz). Requires full understanding of the route inventory from Phase 0.
2. Write up findings. STOP.

### Round 5: Language-specific sweep
1. Apply the primer for the detected language(s).
2. Each language primer takes one full pass through relevant files.
3. Write up findings. STOP.

### Round 6: Interaction and second-order bugs
1. Read the findings from Rounds 1-5 together. Look for findings that interact (a race condition made worse by missing error handling, a missing null check exploitable via a missing auth check).
2. These interactions are usually P0 regardless of individual finding severity.
3. Write up findings. Final report.

**Each round produces its own report addendum.** Don't wait until Round 6 to file Round 1 findings. Deliver as you go.

---

## STOP CONDITIONS

An audit is complete when any of these is true.

1. Six rounds have run and Round 6 produced fewer than 3 new findings.
2. A P0 finding blocks further audit (e.g., the codebase doesn't build, tests can't run, core code is so broken that every downstream check is meaningless).
3. Time budget exhausted (instructor-set).
4. Capture-recapture indicates saturation: run two independent passes of the same method, count overlap. If overlap is >80% of the smaller set's findings, that method is saturated.

Never audit forever. Findings after a certain point have diminishing returns. Ship the report.

---

## ANTI-PATTERNS FOR AI AUDITORS

Things that weaken your findings and should be avoided.

**Reporting style issues as bugs.** "This function is long" is not a bug. "This variable name is unclear" is not a bug. The audit is about correctness, security, and reliability, not aesthetics.

**Using phrases like "could potentially" or "might be."** Either the bug exists or it doesn't. If uncertain, tag POSSIBLE and explain what would confirm it. Don't hedge in the finding itself.

**Citing line numbers without verifying them after any file changes.** If the user edits between rounds, re-verify every line number before filing.

**Fabricating commands or syntax.** If you don't know whether a library has a specific method, check the code or the docs. Don't make it up.

**Reporting the same bug twice under different method headers.** Dedupe before writing the report. A race condition found by Method 2 and again by Method 5 is one finding, filed under the more specific method.

**Filing findings without file and line.** Every finding needs coordinates. "The codebase has SQL injection" is not a finding. "src/api/users.ts:47 constructs SQL with string concat on `req.query.sort`" is a finding.

**Assuming your audit is complete after one pass.** It isn't. The "stop conditions" section exists because humans often want you to stop; it doesn't mean the audit was thorough. Err toward running all six rounds.

**Skipping Phase 0.** If you start finding bugs without first building a map of the codebase, your findings lack context. A missing null check in dead code is not a bug. A missing null check in the hot path of a payment handler is P0.

**Trusting a green test run.** Tests prove what they test. They do not prove correctness. Audit on top of tests, not instead.

**Writing fix code in the audit.** The audit phase is separate from the fix phase. Describe the fix. Do not write the fix. Writing fixes while auditing corrupts your remaining-bugs view: "oh, I already fixed that, I don't need to look at it" is how you miss the second instance of the same bug.

---

## FINAL OPERATING PRINCIPLES

1. **Ground every finding in the code.** File, line, snippet, always.
2. **Every finding has severity and confidence.** No exceptions.
3. **Reproduce or reason.** Not "I have a feeling."
4. **Dedupe before reporting.** One bug = one finding.
5. **Run all rounds unless told to stop.** Partial audits miss interaction bugs.
6. **Don't fix during audit.** Report only.
7. **Language-agnostic by default, language-specific when signal is high.**
8. **Assume the code is hostile to itself.** Most bugs are unintended. Some are intended and wrong anyway.
9. **Separate bugs from opinions.** Hold opinions back. Bugs are enough.
10. **Ship the report.** An unfinished audit report delivered is more valuable than a complete one not delivered.

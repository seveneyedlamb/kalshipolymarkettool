# HARPOON CANNON: Agentic Build Guide
## Session-by-session instructions for building with Claude Code or Cursor

Each session = one focused task. Feed the listed context sections. Get working code. Move on.

**THE BRICKLAYER RULE:** Every phase builds ON TOP of the previous phase. Phase 2 does not modify Phase 1 code. Phase 3 does not modify Phase 2 code. You ADD bricks. You do not rip out the foundation to build the roof. Every new feature is an extension, a new file, a new column. If a Phase 2 session requires changing Phase 1 code, something is wrong with the Phase 2 design, not the Phase 1 code.

**Error logging pattern (every session):** Every background function wraps in try/catch/finally. On success: update system_state last_success_[function]. On error: write to error_log with structured details (source, error_type, message, stack, context, input_snapshot, recovery_action). Release locks in finally. See CLAUDE.md.

---

# PHASE 1: THE FOUNDATION
## Revenue target: $0 (self-funded). Ship and prove the thesis.

Prerequisites: Node.js, Supabase project created, Vercel account, Anthropic API key, Polar account, Coinremitter account.

### Session 1: Project Scaffold
**Context:** CLAUDE.md + Project Structure section
**Command:** "Create a Next.js 14+ project with App Router, TypeScript, Tailwind, shadcn/ui. Set up the folder structure from CLAUDE.md. Create all page.tsx and route.ts files as stubs. Set up Supabase client files in lib/supabase/ (browser, server, admin). Create .env.local from the env vars list."

**CRITICAL ORDER OF OPERATIONS:**
1. Create Next.js project with TypeScript first
2. Run `npx shadcn@latest init` IMMEDIATELY (before customizing any colors or CSS). This sets up the base component system and overwrites tailwind.config.ts and globals.css.
3. THEN customize CSS variables for Concept C palette in globals.css.
4. Create .env.local with ALL values QUOTED to handle special characters in base64 keys: `NEXT_PUBLIC_SUPABASE_ANON_KEY="eyJ..."`. Do not leave values unquoted.
5. Set up tsconfig.json with strict mode: `"strict": true`, `"noUncheckedIndexedAccess": true`, `"noImplicitOverride": true`, `"noUnusedLocals": true`. Without strict mode, TypeScript silently allows undefined access on indexed properties, which is the source of many NaN and null bugs.

**next.config.js MUST include:**
```js
const nextConfig = {
  serverExternalPackages: ['@supabase/supabase-js'],
};
export default nextConfig;
```
Without `serverExternalPackages`, Next.js bundles the Supabase admin client, which uses `node:crypto` native modules that break on Vercel serverless.

**Security guard:** Add an ESLint rule or runtime check that throws in development if `lib/supabase/admin.ts` is imported from any client component ('use client'). The admin client contains the service role key and must NEVER reach the browser.

**Verify:** npm run dev shows landing page stub at localhost:3000. All routes resolve without 404. tsconfig strict mode active. shadcn components importable.

### Session 2: Database Setup
**Context:** 001_initial_schema.sql (paste entire file)
**Command:** "Run the SQL in Supabase SQL Editor. Install Supabase CLI. Link project. Generate types: npx supabase gen types typescript --linked > src/types/database.ts. Supabase is now set and forget."
**Verify:** 19 tables visible. Types file has all interfaces. Realtime enabled on picks, anomalies, markets. CRITICAL: verify the handle_new_user trigger exists (Database > Functions in Supabase dashboard). Test it: create a test user via Supabase Auth, confirm user_profiles row appears automatically with matching id and email.

**PREREQUISITE:** Session 2 MUST complete before any other session. All subsequent sessions import from `src/types/database.ts`. Running sessions out of order causes import failures.

**SUPABASE CLI AUTH:** If `supabase gen types` fails, run `supabase login` first, then `supabase link --project-ref <your-project-ref>`. The command requires an authenticated, linked session.

**REALTIME GUARD:** If `ALTER PUBLICATION supabase_realtime ADD TABLE` fails, the user may have disabled Realtime in the Supabase dashboard. Re-enable it at Dashboard > Database > Replication > supabase_realtime publication.

**TRIGGER EDGE CASE:** The `handle_new_user` trigger fires on ALL auth.users inserts, including OAuth and magic link signups. For OAuth providers where `NEW.email` may be null, the trigger uses `COALESCE(NEW.email, '')` to avoid constraint violations. The SQL already handles this via the trigger's INSERT pattern, but verify that OAuth users get a valid user_profiles row.

### Session 3: Platform Connectors
**Context:** CLAUDE.md + API Field Reference section
**Command:** "Build lib/platforms/kalshi.ts, polymarket.ts, types.ts. Unified NormalizedMarket interface. Normalize prices to 0-1 float: parseFloat on yes_bid_dollars (Kalshi), JSON.parse then parseFloat on outcomePrices (Polymarket). Native fetch. Pagination. Rate limits (100ms Kalshi). Validation: reject price > 1.0 or < 0.0."

**CRITICAL SAFETY RULES:**
1. **NaN guard (J01):** After parseFloat, ALWAYS check `if (isNaN(price)) { log warning; skip market; }`. NaN is neither > 1.0 nor < 0.0, so it passes a range check silently and corrupts every downstream calculation.
2. **Kalshi null prices:** `yes_bid_dollars` can be null for suspended markets. `parseFloat(null)` returns NaN. Guard: `if (rawPrice === null || rawPrice === undefined) { skip; }`.
3. **Polymarket outcomePrices try/catch:** Wrap `JSON.parse(outcomePrices)` in try/catch PER MARKET. One malformed string must never crash the entire fetch cycle. On failure: log warning to error_log, skip that market, continue.
4. **Pagination MAX_PAGES guard:** Add `MAX_PAGES = 50` to both pagination loops. If the API returns exactly the page size on every request (API bug), the loop would run forever. Break after 50 iterations with a warning logged.
5. **Nexus tagger uses word boundaries:** Use `\bkeyword\b` regex matching, not simple substring. "trump" must not match "trumpet." "musk" must not match "musket." Use case-insensitive word boundary regex: `new RegExp('\\b' + escapeRegex(keyword) + '\\b', 'i')`.
6. **NormalizedMarket status mapping note:** Kalshi `unopened` and `open` both map to `active`. This means markets that aren't yet tradeable are treated as active. The poller snapshots them, but the scorer should skip markets where `yes_price` is null (not yet priced).

**Verify:** Test script logs market count + sample prices. ALL between 0.0 and 1.0. No NaN.

### Session 4: Nexus Tagger
**Context:** CLAUDE.md + Nexus Config from Engine 1 section
**Command:** "Build lib/nexus/config.ts (keyword lists, entity tiers, policy domains with score weights) and tagger.ts (case-insensitive word-boundary match, nexus_score = min(sum, 1.0))."

**CRITICAL: Use word boundary regex matching, NOT substring.** Simple substring creates false positives: "trump" matches "trumpet," "musk" matches "musket," "china" matches "chinaware." Use `\bkeyword\b` pattern for all keyword and entity matching. Policy domains can use substring (they're single words or short phrases unlikely to collide).

**NOTE:** nexus_score is an ordinal signal (higher = more politically relevant), NOT a probability. A score of 1.0 doesn't mean "100% political" -- it means "many strong signals detected." The scorer uses it as a filter threshold, not a weight.

**Verify:** "Will the US strike Iran before 2027?" returns nexus_score > 0.7 with tags "iran", "military".

### Session 5: Poller
**Context:** CLAUDE.md + Engine 1 section (complete) + Pre-Build Bugs: Poller Lock, Day 1 Anomalies
**Command:** "Build /api/poll-markets. HARPOON_INTERNAL_SECRET check. try/finally with atomic lock. Parallel fetch both platforms. Upsert markets with nexus tagging. Snapshots for nexus>0 only. Anomaly detection (z-score on volume_24h AND yes_price vs 7-day rolling avg, SKIP if <100 snapshots, severity = min(z/5, 1.0), confidence = severity * nexus_score). Whale alert trigger (confidence > 0.75 AND nexus > 0.5). Market resolution detection (prefer platform explicit field, fallback to price >= 0.99). Update last_success_poller. Lock release in finally."

**CRITICAL ANOMALY DETECTION GUARDS:**
1. **NULLIF + COALESCE for stddev:** The z-score formula uses `NULLIF(stddev, 0)` but stddev itself can be NULL (not just 0). Use `COALESCE(NULLIF(stddev, 0), 0)` or check `IF stddev IS NULL OR stddev = 0 THEN skip`. A NULL stddev produces NULL z-score which propagates silently.
2. **CTE upsert is PostgreSQL 12+:** The `WITH old AS (...) upserted AS (INSERT ... RETURNING ...) SELECT ...` pattern requires PostgreSQL 12+. Supabase runs PG 15, so this works. But if testing locally on SQLite or older PG, it fails. Document this as PG-specific SQL.
3. **last_success_poller JSON format:** Must be `'{"at": "2026-04-17T...", "duration_ms": 3421}'`. The admin dashboard parses `duration_ms` from this JSON. Include both fields on every update.
4. **Whale alert fire-and-forget timeout:** The POST to `/api/analyze-urgent` MUST have a short timeout (5 seconds). If the route is slow (Claude API call), the poller's HTTP client may timeout and throw, crashing the poller cycle. Use `fetch(url, { signal: AbortSignal.timeout(5000) })` and swallow any errors.
5. **Resolution detection secondary guard:** The fallback `price >= 0.99` triggers on legitimate high-confidence markets (e.g., "Will the sun rise tomorrow?"). Add a secondary check: only auto-resolve if `price >= 0.99 AND status changed from previous poll`. If the platform already reports the market as resolved, use that. The price heuristic is ONLY for when the platform status is stale.

**Verify:** curl with secret header. Markets populate. Snapshots only for nexus>0. Lock cycles. Kill mid-run, verify lock auto-releases after 3min. CRON TIME BUDGET: measure the full poll cycle duration against a populated (non-empty) database. Target: complete in under 60 seconds so successive one-minute crons never overlap. Target: complete in under 300 seconds (Vercel Pro function timeout). Log the duration on each run to `last_success_poller.value` alongside the timestamp. If the cycle exceeds 45 seconds during the verification pass, stop and review: the most likely causes are (a) sequential platform fetches instead of Promise.allSettled parallelization, (b) per-market anomaly queries instead of a single windowed query, (c) pagination not bounded. Fix before shipping.

### Session 6: Scoring Engine
**Context:** CLAUDE.md + Engine 2 section (complete) + Scoring Prompt + Polyseer + Caveman Compression + Branding Rules + Model Auto-Healing System + Pre-Build Bugs: Scorer Lock, Claude API Parsing
**Command:** "Build engine.ts, prompt.ts, parser.ts, models.ts, and the callWithFallback wrapper at lib/ai/call-with-fallback.ts. SCORING_MODELS is a fallback CHAIN per role (3 positions each: primary, fallback, last-resort). The callWithFallback wrapper reads cached active model from system_state, tries it first, falls back on 404 not_found_error, retries same model on 429/529/5xx, aborts on 401, logs fallback events to error_log with error_type='model_retired'. Every API call in the scoring engine (researcher, analyst, future courtroom calls) goes through this wrapper. NO direct anthropic.messages.create() calls outside the wrapper. TWO prompts (research + scoring from FOUR blocks). Web search tool: use the WEB_SEARCH_TOOL_TYPE constant from models.ts (do NOT hardcode 'web_search_20250305' -- it's a versioned string that changes). cache_control on system messages. /api/analyze-markets route. Atomic scorer_lock. Skip-if-unchanged (last_analyzed_at IS NOT NULL AND recent AND price <3% AND no anomalies) AND rebadge skipped picks to current cycle_id at end of run. Partial batch handling (write what returned, log missing). Direction-aware edge formula. market_price_at_scoring. pick_score + rank. last_success_scorer. Lock in finally. Also build /api/validate-models: weekly cron, dual auth, calls Anthropic GET /v1/models, checks each position of each fallback chain against the live list, logs any retired positions to error_log, updates last_success_model_validator."

**CRITICAL MODEL AUTO-HEALING:**
1. **Cache invalidation on config change:** The callWithFallback wrapper caches the active model in system_state. If the operator updates SCORING_MODELS in models.ts proactively (before a 404 occurs), the cache is stale. Include a config hash or version number in the system_state cache key. When models.ts changes, the hash changes, and the cache is invalidated. Alternatively, add a `config_version` field to the cached value and compare against the current config version on each call.
2. **Rate limit handling between batches:** Anthropic's Sonnet rate limit is ~50 requests/minute. A Pool A batch of 8 markets = 16 API calls (researcher + analyst each). Add a 2-second delay between batches. If a 429 response is received, back off 30 seconds and retry. Log the backoff to error_log.

**CRITICAL PARSER VALIDATION:**
3. **Per-market validation, NOT per-batch:** If Claude returns valid JSON for 7 markets but malformed data for 1, the parser must SKIP the bad market and WRITE the 7 good ones. Do NOT reject the entire batch on one invalid market. Log the invalid market to error_log with the raw response for debugging.
4. **Skip-if-unchanged rebadge guard:** When rebadging skipped picks' cycle_id forward, add `AND resolved = false` to the UPDATE. Without this guard, a pick that was resolved between the last cycle and this one would be resurrected into the current cycle, making it visible on the Pick Board again.
5. **p_neutral and p_aware CHECK constraints:** The picks table has `true_probability int` with a CHECK constraint (0-100), but `p_neutral` and `p_aware` have no CHECK constraints. Add `CHECK (p_neutral IS NULL OR (p_neutral >= 0 AND p_neutral <= 100))` and same for p_aware. This prevents out-of-range values from corrupting evidence_divergence calculations.

**VERIFY ADDITIONS:** Also verify that `web_search_20250305` is NOT hardcoded anywhere in the codebase. It must be imported as `WEB_SEARCH_TOOL_TYPE` from models.ts.

**Verify:** Picks table: rationale, key_evidence (grade+side), p_neutral, p_aware, evidence_gap, what_would_change, cycle_id consistent. Skipped picks appear in latest cycle. Force a 404 by setting SCORING_MODELS.researcher to `['claude-nonexistent-model', 'claude-haiku-4-5', 'claude-haiku-4']` and run analyze-markets once: verify it falls back to position [1], writes error_log entry with error_type='model_retired', updates system_state.active_model_researcher to 'claude-haiku-4-5'. Revert the config. Run validate-models manually: verify it returns the current model list and logs any drift.

### Session 7: Dashboard - Pick Board
**Context:** CLAUDE.md + Dashboard section + Social Sharing section
**Command:** "Pick Board with canonical JOIN query (includes whale alert OR clause). Supabase Realtime on picks. Cards: rank, title, platform badge, direction, live edge (direction-aware), confidence, crowd, anomaly. Tier filter via middleware. Empty state message. Upsell teaser. Share button with affiliate link. Milestone bar."

**CRITICAL QUERY DETAILS:**
1. **DISTINCT ON syntax:** The deduplication query for whale alert + hourly scorer picks uses `DISTINCT ON (market_id)`. PostgreSQL requires the ORDER BY clause to start with the same column: `ORDER BY market_id, pick_score DESC`. Writing `ORDER BY pick_score DESC` without the `market_id` prefix causes a SQL error.
2. **Realtime reconnect handling:** When the Supabase Realtime WebSocket reconnects, it sends the full current state, which can trigger duplicate renders. On reconnect, do a full refetch of picks rather than merging with stale client state. Show a brief "Reconnecting..." indicator (amber dot in header) during the gap.

**Verify:** Harpooner sees 25 picks. Live edge updates. Empty state before first cycle. Share copies affiliate URL.

### Session 8: Dashboard - Pick Detail + Bet Tracker
**Context:** CLAUDE.md + Pick Detail + Bet Tracker + Social Sharing + The Courtroom display spec
**Command:** "Pick detail: rationale, PRO/CON evidence with grade badges, evidence gap, what-would-change, risk factors, social sentiment, community activity, 'Bet on [Platform]' link. 'I Bet This' (DISABLED on resolved/closed markets). 'Final Judgement' button: for Harpooner tier, opens a MODAL WINDOW (not popup) explaining the adversarial trial feature with CTA to upgrade to First Mate. For First Mate/Ahab, button is present but disabled with 'Coming Soon' text (API ships in Phase 2). Bet tracker with direction-aware P&L. Win celebration modal with share. Feedback widget: thumbs up/down on every pick. Thumbs down expands to brief textarea 'What was wrong?' Writes to user_feedback table (feedback_type='pick_rating', pick_id, rating 1 or 5, optional message). Also add 'Send Feedback' link in /dashboard/settings that opens modal with type selector (bug_report, feature_request, general) and message field."

**CRITICAL BET TRACKER SAFETY:**
1. **Server-side market status validation:** The "I Bet This" button is disabled client-side on resolved/closed markets, but a race condition exists where the market resolves between page load and bet submission. The server-side bet insertion MUST verify the market status is 'active' before writing to user_bets. Reject with an error message if the market is no longer tradeable.
2. **Direction-aware P&L formulas (exact):**
   - YES bet resolved YES: `pnl = size_usd * (1 - entry_price) / entry_price`
   - YES bet resolved NO: `pnl = -size_usd`
   - NO bet resolved NO: `pnl = size_usd * entry_price / (1 - entry_price)`
   - NO bet resolved YES: `pnl = -size_usd`
   - Voided/cancelled market: `pnl = 0, was_correct = NULL`
   - Guard: if entry_price is 0 or 1, pnl = 0 (division by zero prevention).
3. **Entry price validation:** Validate that entry_price is between 0.0 and 1.0 (exclusive) before inserting. Reject bets with entry_price = 0 or entry_price = 1 (these are resolved markets).

**Verify:** PRO/CON columns with badges. Bet button disabled on resolved. Final Judgement modal opens for Harpooner with upgrade CTA. Log bet, see in tracker. Share generates correct text. Thumbs up/down writes to user_feedback. Settings feedback modal works.

### Session 9: Payment Integration
**Context:** CLAUDE.md + Payment Rails + Pre-Build Bugs: Idempotency, Chargeback + Phase 1 Business Quick Wins (annual billing, exit survey)
**Command:** "polar.ts + coinremitter.ts. /api/webhook/fiat and /crypto. Signature verify. Idempotency. On success: set tier + payment_provider ('polar'/'coinremitter'). Crypto: set subscription_expires_at +30 days. Commission if referred_by. subscription.canceled from Polar: set subscription_expires_at to current_period_end. Chargeback: ban. Create BOTH monthly AND annual products in Polar (Harpooner $29/mo and $290/yr). Webhook handler maps both monthly and annual product IDs to the same tier. Annual subscriptions: Polar handles the 12-month billing period, no special code needed. Cancellation exit survey: before cancel confirms (on settings billing page or Polar redirect back), show modal with single dropdown (too expensive / not accurate / missing features / found better tool / just testing / other + optional text). Write to user_events with event_type='cancel_confirm' and reason in metadata."

**CRITICAL WEBHOOK DETAILS:**
1. **Polar webhook signature verification:** Polar uses HMAC-SHA256 for webhook signatures. Read the `x-polar-signature` header and verify against the webhook secret. The exact algorithm may change -- read Polar's current webhook docs at docs.polar.sh before implementing. Do NOT assume a specific algorithm without verifying.
2. **Coinremitter webhook verification (callback pattern):** Coinremitter does NOT use HMAC signatures. Instead: receive the webhook, extract the transaction ID from the body, then call Coinremitter's `getTransaction` API to verify the transaction is real, matches the expected amount, and has the correct status. This is a callback-based verification, not signature-based. The build guide's "Signature verify" shorthand is misleading for Coinremitter.
3. **Webhook processing order (K33):** MUST be: (1) signature/callback verification, (2) schema validation, (3) idempotency check (provider_event_id), (4) business logic. Checking idempotency BEFORE signature verification leaks which event_ids exist and lets attackers DoS the UNIQUE constraint.
4. **Polar cancellation events:** Polar may send `subscription.updated` (status changed to canceled) BEFORE `subscription.canceled`. Handle BOTH event types for cancellation. If only listening for `subscription.canceled`, cancellations are missed.
5. **Crypto renewal handling:** When a user pays again after 30 days via Coinremitter, the webhook handler must EXTEND `subscription_expires_at` by another 30 days (not reset it). Check if the user already has an active subscription: if `subscription_expires_at > now()`, add 30 days to the existing expiration. If expired, set to `now() + 30 days`.

**Verify:** Polar test mode works. Cancel sets expiration. Chargeback bans. Annual checkout creates correct subscription. Exit survey modal appears and writes event.

### Session 10: Affiliate System
**Context:** CLAUDE.md + Affiliate Program + Referral Attribution Chain + Fraud Prevention
**Command:** "Referral cookie (90-day persistent, read ?ref= param). After signup: set referred_by from cookie. /dashboard/referrals page. Commission logic. /api/process-payouts. Self-referral prevention."

**CRITICAL REFERRAL FLOW:**
1. **The handle_new_user trigger creates user_profiles BEFORE the auth callback sets referred_by.** The auth callback must UPDATE the existing user_profiles row to set referred_by from the cookie. It is NOT an INSERT. The flow is: user clicks referral link -> cookie set -> user signs up -> trigger creates user_profiles (referred_by = NULL) -> auth callback runs -> UPDATE user_profiles SET referred_by = cookie_value WHERE id = user.id.
2. **Annual subscription commission clawback:** When a referred user on an annual plan ($290) cancels after 1 month, the referrer received $72.50 (25% of $290) but the user only consumed $24.17 of value. Add a clawback policy: if an annual subscriber cancels within 90 days, reduce the referrer's affiliate_balance by the commission amount. Log this to error_log with source='affiliate-clawback'.

**Verify:** Two test accounts. Referral via cookie. Commission credited. Dashboard shows.

### Session 11: Notifications + Crowd Aggregation
**Context:** CLAUDE.md + Notifications + Crowd Aggregation from Operational Concerns
**Command:** "/api/send-notifications with 3/hour throttle. /api/aggregate-crowd: views, bets, watchlist, crowd_yes_pct (CASE WHEN 0 THEN 50.0). Crowd-trending: views > MAX(5*avg, 20). Discord webhooks."

**CRITICAL CROWD AGGREGATION:**
1. **market_views table growth:** The aggregate-crowd cron reads market_views which grows unbounded if check-expirations pruning fails. Ensure the query uses the `idx_views_crowd` index: `WHERE market_id = X AND viewed_at > now() - interval '24 hours'`. If the index isn't used, the query becomes a full table scan.
2. **aggregate-crowd must write last_success_aggregator:** Update system_state key `last_success_aggregator` with `{"at": "...", "duration_ms": ...}` on completion. Without this, the admin dashboard shows RED for the aggregator even though it's running.
3. **crowd_yes_pct zero-bets guard:** `CASE WHEN crowd_bets_24h = 0 THEN 50.0` handles zero bets. Also guard against zero views in the trending detection: if `crowd_views_24h = 0`, the trending formula `views > MAX(5*avg, 20)` correctly returns false (0 > 20), but log a warning if the average is also zero to catch data quality issues.

**Verify:** Discord fires. Throttle blocks 4th. Crowd fields update. crowd_yes_pct = 50 on zero bets.

### Session 12: Landing + Pricing + Admin
**Context:** CLAUDE.md + Landing Page + Competitive Landscape (comparison chart) + Admin + Milestones + Pequod Fleet + Phase 1 Business Quick Wins (status page, email capture, annual billing)
**Command:** "Landing page per spec including: comparison chart from Competitive Landscape section (Free Tools vs Data Terminals vs Harpoon Cannon, 14 feature rows), monthly/annual pricing toggle (annual pre-selected with 'Save 17%' badge), pre-launch email capture variant (email input replaces checkout CTA until Phase 1 ships, store in waitlist table). Pricing with Polar + Coinremitter, both monthly and annual products. Public status page at /status: read system_state last_success timestamps, display simplified RED/YELLOW/GREEN. Landing page footer: 'System Status: Operational' badge linking to /status. Admin dashboard: health dashboard, revenue, error drill-down, affiliates, /admin/feedback page showing recent user_feedback filterable by type with user tier context."

**CRITICAL STATUS PAGE:**
1. **The /status route MUST use the Supabase admin client.** The system_state table has RLS enabled with only a `mrr_cache` public read policy. If the route uses the browser client (anon key), RLS blocks all reads except mrr_cache. Use `createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)`.
2. **Admin health color thresholds (explicit):**
   - Poller: GREEN = last success < 5 min, YELLOW = 5-15 min, RED = > 15 min
   - Scorer: GREEN = last success < 2 hours, YELLOW = 2-6 hours, RED = > 6 hours
   - Aggregator: GREEN = last success < 30 min, YELLOW = 30 min-2 hours, RED = > 2 hours
   - Resolver: GREEN = last success < 25 hours, YELLOW = 25-48 hours, RED = > 48 hours

**Verify:** Landing renders with comparison chart. Monthly/annual toggle switches Polar product IDs. Pre-launch email capture stores emails. /status shows system health. Admin health correct colors. Admin feedback page shows entries. Error log drills down.

### Session 13: Onboarding + Social Sharing + Event Tracking
**Context:** Social Sharing + Notifications + Phase 1 Business Quick Wins (event tracking)
**Command:** "Welcome modal ('Pequod Fleet'). Share buttons everywhere with affiliate links. /api/check-expirations (BOTH rails + snapshot pruning + view pruning). /api/milestone-status with fleet size. Event tracking: create lib/utils/track-event.ts utility function trackEvent(userId, eventType, metadata). Call from: login (auth callback), view_pick (pick detail page load), place_bet (I Bet This submit), upgrade_click (pricing page CTA), share_click (share button), watchlist_add (watchlist toggle), cancel_confirm (exit survey submit), credit_purchase (top-up success), notification_click (Discord link click-through). RLS: INSERT only, no SELECT from frontend. Admin reads via service role."

**CRITICAL EVENT TRACKING:**
1. **trackEvent is WRITE-ONLY.** The user_events table has RLS: INSERT only, no SELECT from frontend. Do NOT add a SELECT to the utility function (e.g., to check if an event already exists). It will be blocked by RLS. If deduplication is needed, do it server-side.
2. **Share button referral_code null guard:** The share URL includes `?ref=[user.referral_code]`. If the user's referral_code is NULL (e.g., created before the trigger was added), the URL becomes `?ref=undefined`. Guard: `user.referral_code || 'unknown'` or skip the ref param entirely if null.

**Verify:** Onboarding shows. Share buttons work. Expiration downgrades. Pruning runs. Events appear in user_events table after login, pick view, and bet placement. Admin can query events.

### Session 14: Security + Deploy
**Context:** CLAUDE.md + Security Hardening section + Operational Concerns (Polar test/live mode, platform API playbook)
**Command:** "Rate limiting (60/min user, 30/min IP). Sessions (active_sessions, tier limits 2/3/5). x-client-id check. Bot blocking. Unicode watermark on rationale. CSP headers. Supabase auth (email confirm, CAPTCHA, 7-day sessions). Skeletons, error boundaries, empty states. Middleware chain: auth > banned > tier NULL > subscription_expires_at real-time check > session > Supabase-down fallback. Deploy to Vercel."

**CRITICAL MIDDLEWARE AND DEPLOYMENT:**
1. **Middleware MUST use Node.js runtime:** Add `export const runtime = 'nodejs'` at the top of middleware.ts. Next.js middleware defaults to Edge Runtime, which doesn't support all Node.js APIs. The middleware uses the Supabase admin client for session writes and tier-expiration UPDATEs, which requires Node.js. Without this declaration, the middleware fails unpredictably on Vercel.
2. **Rate limiting mechanism:** In-memory counters do NOT work on Vercel serverless (counter resets every cold start). Use Vercel Edge Rate Limiting (Pro plan feature) configured in vercel.json. Alternative: Supabase-based counter with atomic increment. Specify which approach in the implementation.
3. **CSP headers must allow Next.js inline scripts:** A strict Content-Security-Policy with `script-src 'self'` blocks Next.js's inline script injection for hydration and RSC payloads. Use: `script-src 'self' 'unsafe-inline' 'unsafe-eval'` or a nonce-based approach. Test that the app loads correctly with CSP enabled before deploying.
4. **Unicode watermark encoding:** The watermark uses zero-width Unicode characters to encode user_id in rationale text. For server-side encoding, use `Buffer.from(userId).toString('base64')`, NOT `btoa()` (which is a browser API, not available in Node.js server components).
5. **Complete .env.local template:** Include ALL variables, not just the 14 "official" ones. Also include: `NODE_ENV=development`, `NEXT_PUBLIC_APP_URL=http://localhost:3000`, and `ANTHROPIC_BASE_URL` (for testing with mock endpoints). Quote ALL values containing special characters.

**Verify:** Full user flow end-to-end. Session limits enforced. Rate limits hit. Watermark visible in source. All crons in Vercel dashboard.
**Deploy checklist (verify BEFORE going live):**
- All 14 env vars set in Vercel production environment
- POLAR_MODE=live (NOT test)
- POLAR_WEBHOOK_SECRET is the PRODUCTION webhook secret (not test)
- POLAR_HARPOONER_PRODUCT_ID and POLAR_HARPOONER_ANNUAL_PRODUCT_ID are production product IDs
- COINREMITTER_API_KEY and COINREMITTER_PASSWORD are production credentials
- CRON_SECRET matches what Vercel generated for cron auth
- All 7 crons visible in Vercel dashboard and firing on schedule
- /status returns 'operational' (poller and scorer have completed at least one cycle)
- Landing page loads, pricing page renders both monthly and annual, checkout redirects to Polar
- Test one full payment cycle in Polar production (use a real $29 charge, refund immediately)
- Supabase RLS: test that browser client CANNOT read error_log or system_state (except mrr_cache)

**Phase 1 complete.** 14 sessions. Foundation laid. Do NOT proceed to Phase 2 until live + stable 72+ hours + generating real picks.

---

# PHASE 2: FIRST FLOOR (Intelligence Layer)
## Revenue target: $5,000 MRR (~130 ships).
## Status: DRAFT. Sessions may change based on Phase 1 learnings.

**Bricklayer check:** Phase 2 ADDS to Phase 1. No Phase 1 files modified.

**New env vars:** ALCHEMY_API_KEY, ALCHEMY_WEBHOOK_SECRET, RESEND_API_KEY, TELEGRAM_BOT_TOKEN, POLAR_FIRSTMATE_PRODUCT_ID, HARPOON_ENCRYPTION_SECRET

**New migration:** 002_phase2.sql (ADDS tables: wallet_events, wallet_profiles. ADDS indexes. Never ALTER Phase 1 tables.)

### Session P2-1: Alchemy Webhook
**Extends:** Nothing. Pure addition.
**Command:** "Build /api/webhook/alchemy. Verify signature. Parse on-chain events (large transactions on Polymarket contracts). Write to wallet_events table. Enhances Category 2 (Insider Activity) signal."
**Verify:** Alchemy test event populates wallet_events.

### Session P2-2: Wallet Tracking + Profiling
**Extends:** Reads wallet_events (P2-1) + markets (Phase 1).
**Command:** "Build lib/wallets/tracker.ts and profiler.ts. Aggregate by wallet: volume, win rate, categories, timing. Classify: whale (>$50K), insider_pattern (high win + pre-announcement), retail. Store in wallet_profiles."
**Verify:** Process test events. Profiles generate with correct classifications.

### Session P2-3: Wallet Intel Dashboard
**Extends:** New page in Phase 1 layout. Reads wallet_profiles.
**Command:** "Build /dashboard/wallets. Top wallets, whale alerts, insider-pattern wallets. Filterable. Click for transaction history."
**Verify:** Page renders. Filters work. Whales highlighted.

### Session P2-4: Telegram + Email Notifications
**Extends:** lib/notifications/dispatcher.ts. ADDS handlers. Does NOT modify Discord.
**Command:** "Add telegram.ts (Bot API) and email.ts (Resend). Update dispatcher to check notify_telegram/notify_email prefs. Same throttle (3/hour total). Same content format."
**Verify:** Telegram receives notification. Throttle works across channels. Discord still works.

### Session P2-5: First Mate Tier
**Extends:** Webhook handlers + tier-features.ts.
**Command:** "Create $99 product in Polar. Update webhook to recognize First Mate. Update tier-features.ts. Pricing page: First Mate active."
**Verify:** First Mate sees 50 picks. Wallet Intel accessible. All channels available.

### Session P2-6: Accuracy Dashboard
**Extends:** New admin page. Reads resolved picks (Phase 1 data).
**Command:** "Build /admin/accuracy. Overall %, by confidence, by edge size, by category, over time. WHERE was_correct IS NOT NULL."
**Verify:** Charts render. Numbers match manual spot-check of resolved picks.

### Session P2-7: The Courtroom (Final Judgement) + Credits + Custom AI
**Extends:** Reads picks (Phase 1). New API route + lib module. Activates the modal button from Phase 1 Session 8.
**Context:** CLAUDE.md + The Courtroom section + Intelligence Credits + Bring Your Own AI sections from architecture doc

**Command:** "This session has three parts. Build them in order.

PART A - Credits: Build the credit consumption logic in lib/utils/credits.ts. It checks the user's monthly allowance from tier config, deducts from monthly allowance first, then falls back to bonus_credits if monthly is exhausted. Returns false if insufficient credits. Build the /api/buy-credits POST route for credit top-ups. Display remaining credits in the dashboard header.

PART B - Courtroom: Build lib/courtroom/trial.ts (Call 1: always Haiku, compressed defense + prosecution + rebuttals). Build lib/courtroom/verdict.ts (Call 2: model from provider factory based on user selection). Build /api/courtroom POST route with this flow: check auth, check tier (403 for Harpooner with modal upsell text), check cache (pick_id + user_id, less than 6 hours old AND price moved less than 5%), if engine is not 'custom' check credits and daily cap (First Mate: 20/day, Ahab: 50/day), call trial then verdict, write to courtroom_verdicts, return verdict. Update Pick Detail page: Final Judgement button with engine dropdown (Standard 1cr / Enhanced 3cr / Premium 10cr). Verdict card display with jury split, ruling, reasoning, sentence, dissent.

PART C - Bring Your Own AI: Read the full BYOAI section of the architecture doc before building anything. Key details the coder must follow:
- Add two new columns to user_profiles: byoai_queries_today (int default 0) and byoai_reset_at (timestamptz default now). This is migration 002.
- BYOAI daily cap is 300 queries per user, NOT the same as the credited calls safety cap (First Mate: 20/day, Ahab: 50/day). These are separate counters for separate systems.
- Daily reset is lazy, checked on each BYOAI call, no cron. If last reset was before start of current UTC day, reset counter to 0.
- Harpooner sees the BYOAI section in Settings VISIBLE but LOCKED with grayed out fields and an upgrade CTA. NOT hidden. They must see what they're missing.
- First Mate and Ahab see an active form: provider dropdown, key input, model dropdown (populated per provider, OpenRouter includes a custom model ID text input option), Save & Test button.
- Save flow: validate inputs, make a lightweight test call to the provider (simple prompt, 10 second timeout), only encrypt and store the key if the test passes.
- After save, key is NEVER returned to the browser. Show masked display with last 4 characters only.
- On-demand features show a radio toggle when BYOAI key is saved: Harpoon Cannon Intelligence (uses credits) vs Custom AI (0 credits, uses daily counter).
- NEVER silently fall back to our credits when their key fails. Show error, let user choose.
- Encryption uses AES-256-GCM with HARPOON_ENCRYPTION_SECRET (separate env var from HARPOON_INTERNAL_SECRET).
- NEVER log decrypted keys anywhere. Not error_log, not console, not response bodies.
- All seven error scenarios in the architecture doc must have distinct user-facing messages."

**Verify:**
1. Full Courtroom flow with Standard, Enhanced, and Premium engines. Verdict renders correctly.
2. Credit display accurate after each use. Monthly deducts first, then bonus.
3. Cache works: same pick within 6 hours serves cached verdict at zero cost.
4. Harpooner: sees BYOAI section in Settings grayed out with upgrade CTA. All fields visible but disabled.
5. First Mate: save a valid OpenAI key. Test call succeeds. Key encrypted in DB (check directly in Supabase, confirm it is gibberish not plaintext). Key preview shows last 4 chars only.
6. Save an INVALID key. Test call fails. Key NOT saved. Error message shown.
7. Trigger Final Judgement with Custom AI selected. Verdict renders. 0 credits consumed. Daily counter incremented.
8. Trigger Final Judgement with Harpoon Cannon Intelligence. Credits consumed. Daily counter NOT incremented.
9. Hit 300 daily limit with BYOAI. Custom AI option disabled with reset time message.
10. Next UTC day: counter resets on first BYOAI call (lazy reset).
11. Remove key from Settings. All custom_ai fields NULL. Toggle disappears from on-demand features.
12. Trigger BYOAI call with a revoked key. Error shown. NO silent fallback to our credits.
13. Check error_log after failed BYOAI call: provider, model, status code logged. API key NOT logged.
14. Harpooner tries POST /api/settings/byoai directly via URL: 403 returned.

**Phase 2 complete.** 7 sessions. ~12 days. Zero Phase 1 code touched.

---

# PHASE 3: SECOND FLOOR (Power Tools)
## Revenue target: $15,000 MRR (~300 ships).
## Status: DRAFT. Sessions WILL change based on Phase 1-2 learnings.

**Bricklayer check:** Phase 3 ADDS to Phase 2. No Phase 1-2 files modified.

**New env vars:** TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER, POLAR_AHAB_PRODUCT_ID, KALSHI_API_KEY_ID, KALSHI_PRIVATE_KEY_PATH, HARPOON_ENCRYPTION_SECRET

**New migration:** 003_phase3.sql (ADDS: user_trading_credentials, api_keys, backtest_runs)

### Session P3-1: Backtester Engine
**Extends:** Reads historical picks + markets (Phase 1 data).
**Command:** "Build lib/backtester/engine.ts. Date range + strategy params. Replay picks vs outcomes. P&L, win rate, drawdown, Sharpe. Write to backtest_runs."
**Verify:** 30-day backtest produces realistic results.

### Session P3-2: Backtester UI
**Extends:** New dashboard page.
**Command:** "/dashboard/backtest. Parameter inputs. Run button. Equity curve, P&L summary, trade list. Save/load strategies."
**Verify:** Configure, run, see chart. Save and reload.

### Session P3-3: Wallet Clustering
**Extends:** Phase 2 wallet data.
**Command:** "lib/wallets/clustering.ts. Temporal correlation + co-occurrence. Flag coordinated_group. Ahab only."
**Verify:** Synthetic coordinated data clusters correctly.

### Session P3-4: REST API
**Extends:** New /api/v1/ routes. Reads Phase 1 picks/markets.
**Command:** "GET /api/v1/picks, /markets, /picks/:id. API key auth via api_keys table. 100 req/hour. Ahab only."
**Verify:** Generate key. Curl with header. JSON responses. Rate limit at 101.

### Session P3-5: Automated Betting Engine
**Extends:** Reads picks (Phase 1). New trading module.
**Command:** "lib/trading/executor.ts + risk.ts. Kalshi RSA-PSS + Polymarket wallet signing. Risk limits. AES-256 credential encryption. Explicit opt-in."
**Verify:** Test trade on Kalshi. Risk limits prevent exceeding max_bet. Credentials encrypted in DB.

### Session P3-6: Auto-Trading UI
**Extends:** P3-5 executor.
**Command:** "/dashboard/trading. Status, P&L, positions, risk gauges, trade log. Emergency stop. Settings."
**Verify:** Enable, see trades. Emergency stop works.

### Session P3-7: SMS Notifications
**Extends:** Phase 2 dispatcher. ADDS Twilio.
**Command:** "lib/notifications/sms.ts. Dispatcher checks notify_sms. Ahab only. Same throttle."
**Verify:** Ahab gets SMS. Harpooner does not.

### Session P3-8: Ahab Tier Launch
**Extends:** Webhooks + tier-features.ts.
**Command:** "$299 Polar product. Webhook handler. tier-features.ts. Pricing page active. All Ahab features gated."
**Verify:** Ahab sees everything. Downgrade removes Ahab features gracefully.

**Phase 3 complete.** 8 sessions. ~16 days. Zero Phase 1-2 code touched.

---

# PHASE 3b: COMMAND CENTER ($25K MRR)
## Status: CONCEPT. Guide written when Phase 3 stable.
See architecture doc: "Phase 3 Feature: Unified Command Center." ~14 days. Account connections, unified trading, arbitrage, portfolio. EXTENDS Phase 3 trading infrastructure.

# PHASE 4: THE WHITE WHALE ($50K MRR)
## Status: CONCEPT. Requires next-gen AI models.
See architecture doc: "Phase 4 Feature: The White Whale." SCORING_MODELS + AUTONOMOUS_MODELS ready. Risk controls ready. Pipeline design ready. Waiting on 95%+ calibrated reasoning models.

---

## Build Order

```
PHASE 1 (14 sessions, ~22 days)
  Foundation. Ship it. Get subscribers.
    |
PHASE 2 (7 sessions, ~12 days)
  Intelligence layer. Wallets. Channels. First Mate.
    |
PHASE 3 (8 sessions, ~16 days)
  Power tools. Backtester. API. Auto-trading. Ahab.
    |
PHASE 3b (~14 days)
  Command Center. Trade both platforms.
    |
PHASE 4 (TBD)
  The White Whale. AI hunts while you sleep.
```

Every phase is a COMPLETE, SHIPPABLE product. The bricklayer does not rush. The bricklayer does not skip layers. The bricklayer builds a house that stands.

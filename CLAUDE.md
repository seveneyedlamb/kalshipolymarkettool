# CLAUDE.md - Harpoon Cannon Project Context

## What This Is
Prediction market intelligence SaaS. Detects insider trading patterns on Kalshi + Polymarket. AI scores true probability, compares to market price, surfaces investment signals where edge exists.

## Stack
- Next.js 14+ (App Router), TypeScript only
- Supabase (PostgreSQL, auth, realtime) - database only, set and forget after migration
- Vercel Pro (hosting, ALL cron jobs, ALL API routes, ALL code execution)
- Claude API (Haiku/Sonnet/Opus, config-driven per tier in lib/utils/models.ts)
- Polar (fiat payments)
- Coinremitter (crypto payments)
- shadcn/ui (components)

## Critical Rules
- **READ SYNC-PROTOCOL.md FIRST.** Before making ANY edit to this project, read the sync protocol. It lists every canonical value, every file that must stay in sync, and the post-edit audit commands. Drift is the #1 threat to this project. The protocol is how we kill it.
- **001_initial_schema.sql IS THE SOURCE OF TRUTH FOR THE DATABASE.** Every column, index, RLS policy, trigger, and system_state seed that should exist in Supabase MUST be in that file. If the architecture doc says a column exists and the SQL doesn't create it, the column doesn't exist. Any schema-related edit to any other document REQUIRES a matching edit to 001_initial_schema.sql in the same session. Period.
- ALL prices stored as 0.00-1.00 float. Kalshi: use `yes_bid_dollars` field (parseFloat). Polymarket: use `outcomePrices` (JSON.parse then parseFloat). NEVER use legacy cent fields.
- ALL timestamps UTC. No timezone conversions server-side. Browser converts for display.
- NO file over 300 lines. Split by responsibility.
- Tier filtering uses `WHERE min_tier IN ([allowed_tiers])` not rank comparison.
- Atomic locks for poller and scorer: `UPDATE system_state SET value='running', updated_at=now() WHERE key='poller_lock' AND (value='idle' OR updated_at < now()-interval '3 min') RETURNING *`
- If no rows returned, another instance is running. Skip this cycle.
- Webhook idempotency: check `payments.provider_event_id` unique constraint before processing.
- AI engine branded "Harpoon Cannon Intelligence" in all user-facing output. Never "Claude" or "Anthropic."
- No refunds. Chargebacks = account ban + legal action.
- Anomaly detection requires MIN 100 snapshots per market before activating.
- Rate limit dashboard pages: 60 req/min per user. Rate limit API routes: 30 req/min per IP.
- Concurrent session limit per tier: Harpooner=2, First Mate=3, Ahab=5. Prune inactive sessions > 30min.
- Watermark rationale text with invisible Unicode encoding user_id before serving.
- SUPABASE_SERVICE_ROLE_KEY: server-side only. NEVER in NEXT_PUBLIC_ vars. NEVER exposed to client.
- Supabase client usage: browser client (client.ts) for client components only. Server client (server.ts) for pages/actions needing user context. Admin client (admin.ts) for ALL cron jobs, webhooks, and internal routes. Using the wrong client = either RLS blocks everything or security is bypassed.
- user_profiles row is created AUTOMATICALLY by the `handle_new_user` database trigger on auth.users INSERT. Frontend does NOT create this row manually. The trigger is in 001_initial_schema.sql.
- Internal/cron routes use DUAL AUTH: accept EITHER `Bearer ${CRON_SECRET}` (Vercel cron) OR `Bearer ${HARPOON_INTERNAL_SECRET}` (internal fire-and-forget calls). Both are valid callers. Without dual auth, either scheduled crons or internal calls fail.
- Poller uses Promise.allSettled (NOT Promise.all) for platform fetches. One platform down must not kill both.
- Platform connectors return NormalizedMarket interface (defined in lib/platforms/types.ts). Poller works ONLY with NormalizedMarket, never raw API responses.
- Middleware checks subscription_expires_at in real-time. If expired, clear tier immediately, don't wait for daily cron. Defense-in-depth.
- Tier upgrades use Polar subscription update API (plan change on existing sub), NOT new checkout. New checkout = double billing.
- Voided/cancelled markets: was_correct = NULL, P&L = 0, excluded from accuracy tracking.
- Market status values (normalized): 'active' (tradeable), 'closed' (trading stopped), 'resolved' (outcome known). Platform mapping: Kalshi unopened/open -> active, closed -> closed, settled -> resolved. Polymarket active=true -> active, closed=true -> closed, resolved -> resolved.
- Pick Detail page (/dashboard/pick/[id]) MUST check pick.min_tier against user's tier before rendering. Harpooner navigating to Ahab pick URL = "Upgrade to unlock" not free analysis.

## Database Tables (19)
markets, snapshots, anomalies, picks, user_profiles, user_bets, user_watchlist, market_views, payments, referrals, affiliate_payouts, notification_log, system_state, error_log, active_sessions, courtroom_verdicts, user_events, user_feedback, waitlist

## Key Query: Pick Board (most-hit query)
```sql
-- Get latest cycle
SELECT cycle_id FROM picks ORDER BY scored_at DESC LIMIT 1;

-- Fetch picks (includes whale alerts from last hour)
SELECT picks.*, markets.yes_price, markets.crowd_views_24h,
       markets.crowd_bets_24h, markets.crowd_yes_pct
FROM picks
JOIN markets ON picks.market_id = markets.id
WHERE (picks.cycle_id = [latest_cycle]
       OR (picks.is_whale_alert = true AND picks.scored_at > now() - interval '1 hour'))
  AND picks.min_tier IN ([user_allowed_tiers])
ORDER BY picks.pick_score DESC
LIMIT [tier_pick_limit]
```

## API Routes (15 Vercel, ALL code execution on Vercel)
poll-markets (cron every min), analyze-markets (cron hourly), analyze-urgent (POST), webhook/fiat (POST), webhook/crypto (POST), send-notifications (POST), resolve-picks (cron daily + on-demand), aggregate-crowd (cron 15min), track-view (POST), check-expirations (cron daily), milestone-status (GET public), process-payouts (cron monthly), validate-models (cron weekly Sun 06:00 UTC), courtroom (POST, Phase 2), settings/byoai (POST save+test / DELETE remove, Phase 2)

## Model Auto-Healing (CRITICAL)
Every Claude API call goes through `lib/ai/call-with-fallback.ts`. NEVER call `anthropic.messages.create()` directly outside the wrapper. SCORING_MODELS and ANALYSIS_ENGINES.{tier}.internal are FALLBACK CHAINS (3 positions each), not single strings. On 404 not_found_error the wrapper tries the next position and caches the winner in system_state. On 429/529/5xx retries same model first, then falls back. On 401 aborts and alerts admin. The weekly /api/validate-models cron proactively calls Anthropic GET /v1/models and warns if positions [0] or [2] have been retired. Admin dashboard Model Health card shows active model per role + fallback events in last 7 days.

## Edge Formula
- YES direction: edge = true_probability - (yes_price * 100)
- NO direction: edge = true_probability - ((1 - yes_price) * 100)

## Ranking Formula
pick_score = (abs(edge) * 0.40) + (confidence_multiplier * 0.25) + (anomaly_bonus * 0.15) + (crowd_bonus * 0.20)

Where:
- confidence_multiplier = { high: 1.0, medium: 0.6, low: 0.3 }
- anomaly_bonus = 1.0 if unexpired anomalies on this market, else 0.0
- crowd_bonus = min(crowd_bets_24h / 50, 1.0) * abs(crowd_yes_pct - 50) / 50
  (50 = CROWD_BET_THRESHOLD, tunable in thresholds.ts)

## Tier Mapping
- Harpooner ($29/mo or $290/yr): sees min_tier IN ('harpooner'), LIMIT 25. Credits: 0. Credited daily cap: 0. BYOAI: locked (upsell).
- First Mate ($99/mo or $990/yr): sees min_tier IN ('harpooner','first_mate'), LIMIT 50. Credits: 150/month. Credited daily cap: 20. BYOAI: enabled, 300/day.
- Ahab ($299/mo or $2,990/yr): no filter, no limit. Credits: 500/month. Credited daily cap: 50. BYOAI: enabled, 300/day.
- Annual billing = 17% discount. Polar handles both monthly and annual products. Webhook maps both IDs to the same tier.
- Env vars: POLAR_HARPOONER_PRODUCT_ID (monthly) + POLAR_HARPOONER_ANNUAL_PRODUCT_ID (annual). Phase 2/3 add FIRSTMATE and AHAB equivalents.

## Token Efficiency
Internal reasoning: caveman mode. Cut filler, fragments fine, symbols ok.
User-facing rationale: complete sentences.
JSON output: compact, no whitespace. Use structured output / tool_use for guaranteed JSON.

## Model Routing
Background scoring (hourly cron, shared infrastructure): ALWAYS Haiku researcher → Sonnet analyst. Same for ALL tiers. Fixed cost. No per-tier model routing on background scoring.
On-demand features (credit-gated, per-user): user selects Standard/Enhanced/Premium (1/3/10 credits). Model resolved from ANALYSIS_ENGINES in tier-features.ts.
Tier differentiation = access breadth (picks, markets, credits), NOT background model quality.
SCORING_MODELS.{role} and ANALYSIS_ENGINES.{tier}.internal are ARRAYS (fallback chains), not strings. Always call through callWithFallback wrapper.

## Credit Consumption (ATOMIC — Phase 2 Session P2-7)
Credit deduction MUST use atomic UPDATE...RETURNING pattern, NEVER read-check-write. Same pattern as poller lock, scorer lock, analyze-urgent throttle. Two SQL statements: (1) try monthly allowance with `WHERE monthly_credits_used + cost <= tier_allowance`, (2) if zero rows, try bonus_credits via RPC with shortfall calculation. Zero rows from both = insufficient credits, return false. Naive read-then-write has a race: two tabs can both read used=149, both pass, both write. This is shipped in Phase 2, not deferred to Phase 3.

## Credit Top-Up Flow (Phase 2 Session P2-7)
Three Polar ONE-TIME products (not subscriptions): Boost ($4.99/100), Power Pack ($12.99/300), Unlimited Warfare ($34.99/1000). Env vars: POLAR_BOOST_PRODUCT_ID, POLAR_POWER_PACK_PRODUCT_ID, POLAR_UNLIMITED_WARFARE_PRODUCT_ID. `/api/buy-credits` POST creates checkout with these IDs + metadata {supabase_user_id, package_type, credit_amount}. Webhook `/api/webhook/fiat` detects one-time vs subscription by product_id and routes to credit-crediting flow: `UPDATE user_profiles SET bonus_credits = bonus_credits + credit_amount`. Logged as event_type='credit_topup' for idempotency. Top-ups do NOT pay affiliate commission.

## The Courtroom (Final Judgement)
On-demand adversarial analysis on Pick Detail page. POST /api/courtroom with pick_id + engine ('standard'/'enhanced'/'premium'/'custom'). First Mate + Ahab only (Harpooner gets modal upsell, zero API cost). 2 API calls: Trial (always Haiku) + Verdict (user-selected engine). Costs 1/3/10 credits per engine, or 0 credits if using BYOAI custom key. Cache 6 hours or until price >5%. Daily safety cap for credited calls: First Mate 20/day, Ahab 50/day. Daily cap for BYOAI calls: 300/user (separate counter).

## Intelligence Credits
On-demand AI features consume credits. Monthly allowance: Harpooner 0, First Mate 150, Ahab 500. Resets 1st of month (check-expirations cron). Purchased credits (bonus_credits) never expire, consumed after monthly. user_profiles columns: monthly_credits_used (int, reset monthly), bonus_credits (int, purchased).

## Branded Analysis Engines (NEVER expose internal model names)
- "Standard Analysis" = Haiku (1 credit)
- "Enhanced Analysis" = Sonnet (3 credits, default)
- "Premium Analysis" = Opus (10 credits)
Users NEVER see Claude, Haiku, Sonnet, Opus, or Anthropic. Mapping in lib/utils/tier-features.ts ANALYSIS_ENGINES.

## Bring Your Own AI
First Mate + Ahab can plug in their own API key (OpenAI, Anthropic, or OpenRouter). Custom AI uses their key, 0 credits consumed. 300 queries per day with their own key (separate from the credited calls cap of 20/day FM, 50/day Ahab). Lazy daily reset at midnight UTC, no cron needed. Provider abstraction in lib/ai/provider.ts. Keys AES-256-GCM encrypted with HARPOON_ENCRYPTION_SECRET (separate env var from HARPOON_INTERNAL_SECRET). NEVER logged, NEVER in error_log, NEVER returned to browser after save. Custom AI does NOT touch background scoring (always our Haiku then Sonnet). NEVER silently fall back to our credits when their key fails. Harpooner sees BYOAI section in Settings VISIBLE but LOCKED with upgrade CTA (NOT hidden). user_profiles columns: custom_ai_provider, custom_ai_key_encrypted, custom_ai_model, byoai_queries_today (int), byoai_reset_at (timestamptz).

## Prompt Caching
System prompt is identical every call. Set cache_control: {type: "ephemeral"} on the system message. Saves 90% on ~2,000 tokens of system prompt per call.

## Skip-if-Unchanged Rule
Skip re-analysis if ALL true:
- markets.last_analyzed_at IS NOT NULL (never skip unanalyzed markets)
- markets.last_analyzed_at > now() - interval '4 hours'
- abs(markets.yes_price - picks.market_price_at_scoring) < 0.03
- no anomalies with detected_at > last_analyzed_at
- not whale-triggered
market_price_at_scoring is set by the engine (= markets.yes_price at time of scoring).

## Packages to Use
- @polar-sh/sdk (Polar payments)
- @supabase/supabase-js
- @anthropic-ai/sdk
- Native fetch for Kalshi + Polymarket APIs (typed wrappers in lib/platforms/)

## Parser Mapping (Claude JSON output → picks table)
- `market_platform_id` → lookup market_id: `SELECT id FROM markets WHERE platform_id = [value]`
- `confidence` → `confidence_level` (normalize lowercase, MUST be high/medium/low, default "low" if unexpected)
- `direction` → normalize uppercase, MUST be YES/NO, REJECT pick if neither
- `true_probability` → validate 0-100 integer, REJECT if out of range or NaN
- `edge` → RECALCULATE from true_probability + market price, do NOT trust Claude's value
- `key_evidence` → jsonb (structured: {text, grade, side}), normalize grade to A/B/C/D
- `social_sentiment` → jsonb
- `evidence_gap` → text (direct)
- `what_would_change` → text (direct)
- Fields set by engine NOT Claude: id, cycle_id, scored_at, min_tier, pick_score, rank, analysis_pool, market_price_at_scoring, is_whale_alert, resolved, was_correct, actual_pnl_pct

## Claude API Response Parsing
Claude with web_search returns multi-block responses. Filter `response.content` for `type === "text"` blocks only. Concatenate `.text` values. Then JSON.parse. Do NOT assume entire response is one JSON string.

## Error Logging Pattern (every background function)
Every cron job and internal route: wrap in try/catch/finally. On success: update `system_state` key `last_success_[function]` with `{"at": new Date().toISOString()}`. On error: write to `error_log` with source, error_type, and structured details (message, stack, context, input_snapshot, recovery_action). Release locks in finally block. See Operational Concerns section for full error entry schema and admin dashboard spec.

## Full Architecture Reference
See HARPOON-CANNON-v3-FINAL.md for complete specification including all schemas, prompts, diagrams, and pre-build bug prevention.

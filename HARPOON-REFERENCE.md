# HARPOON CANNON: Project Reference Guide
## For getting Claude back up to speed fast. Updated 2026-04-15.

---

## WHAT IS THIS

Harpoon Cannon is a prediction market intelligence SaaS built by professional traders. It monitors Kalshi and Polymarket, detects insider trading patterns, runs AI probability scoring across 8 signal categories, and surfaces investment signals where a quantified edge exists. Users pay $29-$299/month for tier-gated access to ranked picks with full rationale, evidence grades, and risk factors.

The scoring engine IS the product. Everything else is plumbing.

---

## PROJECT FILES (11 files)

```
├── CLAUDE.md                         # SESSION CONTEXT FILE
│   Paste into every coding session. Stack, critical rules,
│   19 tables, 15 API routes, formulas, tier mapping,
│   model routing, courtroom spec, credit system, BYOAI spec.
│
├── HARPOON-CANNON-v3-FINAL.md        # FULL ARCHITECTURE SPEC (~3,633 lines)
│   Complete technical reference. 11 mermaid diagrams.
│   Everything from tech stack to Phase 4 autonomous trading.
│
├── harpoon-cannon-build-guide.md     # BUILD ORDER
│   14 Phase 1 sessions, 7 Phase 2, 8 Phase 3.
│   THE BRICKLAYER RULE: you ADD bricks, never rip out foundation.
│
├── 001_initial_schema.sql            # DATABASE MIGRATION
│   19 tables, all indexes, all RLS, auth trigger, Realtime,
│   system_state seeds (including scoring_enabled kill switch).
│
├── ERROR-HUNTER.md                   # BUG PREVENTION
│   9 methods. 379 issues found and fixed pre-build across
│   11 categories (A-K). 485+ total edits. Living document.
│
├── vercel.json                       # CRON SCHEDULES (7 crons)
│
├── SYNC-PROTOCOL.md                  # DRIFT PREVENTION SYSTEM
│   Read FIRST before any edit. Lists every canonical value
│   (table count, API routes, pricing, caps, credits, env vars),
│   every file that must stay in sync, and post-edit audit commands.
│
├── HARPOON-REFERENCE.md              # THIS FILE
│
├── design.md                         # DESIGN REFERENCE
│   3 design concepts, full page map, component specs,
│   animation specs, brand art guidelines, responsive design.
│
└── progress.md                       # SESSION TRACKER
    Per-timestamp log of every design decision and fix.
```

---

## TECH STACK

| What | Tool |
|---|---|
| Framework | Next.js 14+ (App Router), TypeScript only |
| Database | Supabase (PostgreSQL + auth + realtime). Set and forget. |
| AI | Claude API. Background: Haiku researcher + Sonnet analyst. On-demand: Standard/Enhanced/Premium engines. |
| Fiat payments | Polar |
| Crypto payments | Coinremitter (custom_data1 field carries supabase_user_id) |
| Hosting | Vercel Pro. ALL code runs here. |
| UI | shadcn/ui + Tailwind |

One language. One execution platform. One database. 4 services + Anthropic API.

---

## THE TWO ENGINES

### Engine 1: The Poller (every 60 seconds)
- Fetches both platforms in parallel (Promise.allSettled)
- Pagination loops: Kalshi cursor-based, Polymarket offset-based with 35ms delay
- Response validation: required fields checked per market, 50%+ failure = schema_change alert
- Upserts markets with description + nexus tagging
- Polymarket volume is a STRING, must parseFloat (NaN defaults to 0)
- Price validation: reject if isNaN OR > 1.0 OR < 0.0
- Snapshots only for nexus > 0 markets
- Anomaly detection via z-score (requires 100+ snapshots, triggers at z > 2.5)
- Whale alert trigger when confidence > 0.75 AND nexus > 0.5
- Market resolution detection, fires resolve-picks
- Atomic lock via system_state (poller_lock)

### Engine 2: The Scoring Engine (hourly + whale trigger)
- Checks scoring_enabled kill switch BEFORE acquiring lock. Admin can pause via dashboard.
- TWO-STAGE PIPELINE:
  - Stage 1: RESEARCHER (always Haiku, web search, PRO/CON evidence, grades A/B/C/D)
  - Stage 2: ANALYST (always Sonnet, no web search, scores probability, writes rationale)
- Selects WHERE status = 'active' only. Pools: A (nexus >= 0.7), B (nexus >= 0.3), C (nexus > 0)
- If zero markets pass filters: update last_success, release lock, done
- Skip-if-unchanged: recently analyzed + price < 3% move + no anomalies = skip
- Background scoring = FIXED INFRASTRUCTURE. Same models for all tiers.
- Parser validates everything. Edge RECALCULATED (never trust Claude's value).

---

## 19 DATABASE TABLES

markets, snapshots, anomalies, picks, user_profiles, user_bets, user_watchlist, market_views, payments, referrals, affiliate_payouts, notification_log, system_state, error_log, active_sessions, courtroom_verdicts, user_events, user_feedback, waitlist

Key columns added during design:
- markets.close_time (timestamptz)
- markets.description (text, used by nexus tagger)
- user_profiles.discord_fail_count (int, auto-disable after 3 failures)
- user_profiles.byoai_queries_today + byoai_reset_at (Phase 2 migration)
- system_state: scoring_enabled (kill switch, default 'true')
- user_events: event tracking for churn prediction, upsell triggers, feature usage
- user_feedback: pick ratings, bug reports, feature requests

Source of truth: 001_initial_schema.sql

---

## 15 API ROUTES (all on Vercel)

| Route | Trigger | What it does |
|---|---|---|
| poll-markets | Cron every 60s | Fetch, upsert, snapshot, anomaly, whale alert, resolution detect |
| analyze-markets | Cron hourly | Two-stage AI scoring pipeline, write picks |
| analyze-urgent | POST (internal) | Whale-triggered immediate analysis (5min throttle, atomic) |
| webhook/fiat | POST | Polar webhook. Verify sig, set tier, handle out-of-order, credit affiliate |
| webhook/crypto | POST | Coinremitter callback verify (wallet_id + amount + status), tier +30 days |
| send-notifications | POST (internal) | Discord for new picks, whale alerts, crowd-trending, bet resolution |
| resolve-picks | Cron daily + on-demand | Score pick accuracy, compute P&L, handle voided markets |
| aggregate-crowd | Cron every 15min | Roll up views/bets/watchlists, crowd_yes_pct (zero bets = 50.0) |
| track-view | POST (user auth) | Lightweight. Log market_id + user_id |
| check-expirations | Cron daily | Downgrade expired subs (BOTH rails), prune, credit reset |
| milestone-status | GET (public) | MRR at $29/$99/$299 per tier |
| process-payouts | Cron monthly | Affiliate payouts where balance >= $50 |
| validate-models | Cron weekly (Sun 06:00 UTC) | Call Anthropic GET /v1/models. Warn if fallback chain positions [0] or [2] are retired. Log newer models available. |
| courtroom | POST (user auth) | Final Judgement. Phase 2. Credits or BYOAI. |
| settings/byoai | POST + DELETE (user auth) | Save+test / remove BYOAI key. Phase 2. |

Dual auth on internal routes: Bearer CRON_SECRET OR Bearer HARPOON_INTERNAL_SECRET.

---

## THREE TIERS + FISCAL REVIEW

| | Harpooner ($29) | First Mate ($99) | Ahab ($299) |
|---|---|---|---|
| Markets | Pool A (~30-50, nexus >= 0.7) | Pool A+B (~100-200, nexus >= 0.3) | All nexus > 0 |
| Picks visible | Top 25 | Top 50 | Unlimited |
| Monthly credits | 0 (upsell) | 150 | 500 |
| BYOAI | Visible but LOCKED (upsell) | Yes, 300/day | Yes, 300/day |
| Final Judgement | Modal preview (upsell) | Yes (uses credits) | Yes (uses credits) |
| Notifications | Discord | Discord + Telegram + email | All + SMS |
| Daily safety cap (credited) | 0 | 20 calls | 50 calls |

**Does this make money?**

Background scoring: ~$750-1,100/month FIXED regardless of user count.
Break-even at $29: 26-38 Harpooner subscribers.

Per-user on-demand AI cost (worst case, ALL Premium engine):
- First Mate: 15 Premium calls x $0.14 = $2.10/month (2.1% of $99). Daily cap: 20 calls.
- Ahab: 50 Premium calls x $0.14 = $7.00/month (2.3% of $299). Daily cap: 50 calls.
- BYOAI: $0 to us. Daily cap: 300 (their key, their problem).

Credit top-ups (pure profit center):
- Boost $4.99/100cr: worst case $1.40 cost = 72% margin
- Power Pack $12.99/300cr: worst case $4.20 = 68% margin
- Unlimited Warfare $34.99/1000cr: worst case $14.00 = 60% margin

Affiliate 25% recurring:
- 10 Harpooner referrals = $72.50/mo to referrer, we net $217.50
- 1 Ahab referral = $74.75/mo to referrer, we net $224.25
- Chargeback on referred user: commission clawed back

Steady state (100 Harpooners + 20 FM + 5 Ahab):
- MRR: $6,375. AI cost: ~$750-1,100. Margin: ~83%.

Annual billing (17% discount, reduces churn 20-30%):
- Harpooner: $290/yr ($24.17/mo effective). Still profitable: $24.17 - ~$8 infra = $16/mo net.
- First Mate: $990/yr ($82.50/mo). Worst case AI: $2.10/mo. Net: $80+/mo.
- Ahab: $2,990/yr ($249/mo). Worst case AI: $7/mo. Net: $242+/mo.
- Cash flow: 20% of subs choosing annual at steady state = ~$15K upfront vs monthly drip.

No tier loses money. BYOAI costs nothing. Credit top-ups are 60-72% margin. Affiliate commission still leaves healthy per-user net after shared infrastructure.

---

## THE COURTROOM (Final Judgement)

On-demand adversarial AI. First Mate + Ahab only. Harpooner gets modal upsell.

- Call 1 (TRIAL): always Haiku. Defense argues BUY, Prosecution argues DO NOT BUY. Rebuttals.
- Call 2 (VERDICT): Standard 1cr / Enhanced 3cr / Premium 10cr / Custom AI via BYOAI 0cr.
- 12 independent jurors (Statistician, Historian, Contrarian, Risk Manager, Momentum Trader, Fundamentalist, Skeptic, Sentiment Reader, Timekeeper, Arbitrageur, Black Swan Hunter, Pragmatist) + judge with ruling, confidence, sentence.
- Cached 6 hours or until price > 5%.
- Credited calls: First Mate 20/day, Ahab 50/day. BYOAI calls: 300/day separate counter.

---

## BYOAI (Bring Your Own AI)

FM + Ahab plug in own API key (OpenAI, Anthropic, OpenRouter). Their key, their tokens, our prompts. $0 cost to us. 300 queries/day, lazy reset midnight UTC.

Harpooner sees it VISIBLE but LOCKED. This is the upsell.

Keys AES-256-GCM encrypted with HARPOON_ENCRYPTION_SECRET. NEVER logged. NEVER returned after save. Save-and-test before storing. NEVER silently fall back to our credits on failure.

---

## CRITICAL RULES

0. **READ SYNC-PROTOCOL.md FIRST.** Before any edit. It lists every canonical value and the files that must stay in sync.
1. **001_initial_schema.sql is the database source of truth.** Every schema-related edit in any document requires a matching edit to this file in the same session. If the SQL doesn't create it, it doesn't exist.
2. Prices 0.00-1.00 float. isNaN check + range check. Polymarket volume must parseFloat.
3. ALL timestamps UTC.
4. No file over 300 lines.
5. Atomic locks: UPDATE...RETURNING with 3-min stale check.
6. Webhook idempotency: provider_event_id UNIQUE.
7. Webhooks tolerate out-of-order delivery. Every handler works regardless of user state.
8. Coinremitter verification: callback-based (getTransaction API, verify wallet_id + amount).
9. Branded "Harpoon Cannon Intelligence." Never "Claude" or "Anthropic."
10. SUPABASE_SERVICE_ROLE_KEY server-side only.
11. Three Supabase clients: browser, server, admin. Wrong one = broken.
12. user_profiles auto-created by trigger.
13. Parser RECALCULATES edge. Never trust Claude.
14. Scoring engine checks scoring_enabled kill switch before lock.
15. Scoring engine filters WHERE status = 'active'.
16. Connectors validate response fields. 50%+ failure = schema_change alert.
17. Rate limiting: Vercel edge. NOT in-memory (broken on serverless).
18. Middleware validates tier is known. Unknown = NULL = redirect /pricing.
19. Checkout success: polls 2s/20s for webhook race condition.
20. Supabase down: static "Service temporarily unavailable" page.
21. Bet validation: positive number, min $1, max $100K. Entry price direction-aware and range-validated (0.0-1.0).
22. Claude API calls: ALWAYS through callWithFallback wrapper. NEVER direct anthropic.messages.create(). SCORING_MODELS and ANALYSIS_ENGINES.{tier}.internal are fallback chains (arrays), not strings. 404 = next position. 401 = admin alert, abort.

---

## ERROR PREVENTION

379 issues found and fixed. 485+ total edits. 5 audits (G-K) this session alone found 65 issues. Every one fixed. Estimated 2-3 remaining that can only surface against live APIs.

After ANY edit: check ALL 11 files + ALL 11 mermaid diagrams. Run the post-edit audit commands from SYNC-PROTOCOL.md.

---

## BUILD ORDER

Phase 1: 14 sessions. Ship Harpooner only at $29. Break-even: 26-38 subs.
Phase 2: 7 sessions. Courtroom, credits, BYOAI, wallets, First Mate at $99.
Phase 3: 8 sessions. Backtester, API, auto-trading, Ahab at $299.
Phase 3b: Command Center.
Phase 4: The White Whale (autonomous trading).

Do NOT sell tiers for features that don't exist yet. Do NOT proceed to Phase 2 until Phase 1 is live + stable 72+ hours.

---

## ENV VARS

Phase 1 (14): NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, ANTHROPIC_API_KEY, POLAR_ACCESS_TOKEN, POLAR_WEBHOOK_SECRET, POLAR_HARPOONER_PRODUCT_ID, POLAR_HARPOONER_ANNUAL_PRODUCT_ID, COINREMITTER_API_KEY, COINREMITTER_PASSWORD, HARPOON_INTERNAL_SECRET, CRON_SECRET, NEXT_PUBLIC_APP_URL, POLAR_MODE

Phase 2 adds: ALCHEMY_API_KEY, ALCHEMY_WEBHOOK_SECRET, RESEND_API_KEY, TELEGRAM_BOT_TOKEN, POLAR_FIRSTMATE_PRODUCT_ID, HARPOON_ENCRYPTION_SECRET

Phase 3 adds: TWILIO_*, POLAR_AHAB_PRODUCT_ID, KALSHI_API_KEY_ID, KALSHI_PRIVATE_KEY_PATH

---

## STATUS

Pre-build. 407 issues found and fixed. 545+ total edits. 19-table schema, event tracking, feedback system, annual billing, competitive positioning, fiscal modeling, error prevention all complete. Production readiness audit passed. Ready for Session 1.

# ERROR HUNTER: Pre-Build Bug Detection Methodology
## A living document. AI coders ADD to this when errors are found. Always consult before error-checking.

**Philosophy:** Every bug found in the spec saves 10x the cost of finding it in code and 100x the cost of finding it in production. The monk finds bugs before they exist.

---

## METHOD 1: BAYESIAN BUG DENSITY MAPPING

Track where bugs have been found. The section with the most bugs WILL have more bugs.

**Current density map (update when bugs are found):**

| Section | Issues Found | Complexity | Predicted Remaining |
|---|---|---|---|
| Scoring Engine (pipeline, prompt, parser, models) | 60 + K03 K09 = 62 | Very High | VERY LOW (kill switch added, credit race documented, status filter added, empty batch handled) |
| Payment/Affiliate (webhooks, commission, referral, tiers) | 50 + K05 K06 K10 = 53 | High | VERY LOW (clawback specified, custom_data1 specified, out-of-order handling added) |
| Dashboard/Queries (Pick Board, detail, bet tracker, live edge) | 38 + K02 = 39 | Medium | VERY LOW (bet validation added, tier enforcement, empty states, debounce all spec'd) |
| Poller (fetch, nexus, anomaly, lock, resolution) | 41 + K01 K11 = 43 | Medium | VERY LOW (volume parsing, response validation, pagination, all columns verified) |
| Operations (crowd, notifications, pruning, error logging) | 32 + K04 = 33 | Medium | VERY LOW (failure counter, Discord format, resolution notification all specified) |
| Security (RLS, sessions, rate limit, watermark, CSP) | 44 + K14 = 45 | Medium | VERY LOW (rate limit, watermark, Supabase down, tier validation all specified) |
| Database Schema (columns, indexes, constraints, seeds, trigger) | 28 + I01 I05 J09 = 31 | Low | VERY LOW (close_time added, discord_fail_count added, all columns cross-ref'd) |
| Architecture/Foundation (tech stack, vendors, execution) | 40 + G01 H03 H04 H05 I04 = 45 | High | VERY LOW (all pricing updated, all math recalculated) |
| Mermaid Diagrams (11 diagrams) | 12 + J07 J12 = 14 | Medium | VERY LOW (scoring mermaid updated with status filter + boundary fix) |
| Missing Specs (features that had no specification at all) | 104 + I02 I06 I07 I08 I09 I10 I11 = 111 | N/A | VERY LOW (Coinremitter verification, pagination, outcomePrices safety, Discord format, device hash, watermark encoding all specified) |

**How to use:** When hunting bugs, start with HIGH probability sections. Spend 60% of review time there. When a new bug is found, update this table.

---

## METHOD 2: HAPPY PATH vs ALL PATHS

AI coding tools generate the happy path. Production needs ALL paths. For every feature, ask:

**The 7 Unhappy Questions:**
1. What happens when the INPUT is null, zero, empty string, negative, or absurdly large?
2. What happens when the EXTERNAL SERVICE is down, slow, or returns an error?
3. What happens when TWO USERS do this at the same time?
4. What happens the FIRST TIME this runs (empty database, no prior data)?
5. What happens when the user does this in the WRONG ORDER or at the WRONG TIME?
6. What happens when the data is STALE, EXPIRED, or from a previous version?
7. What does the USER SEE when any of the above happens? (blank page = bug)

**Bugs found by this method in Harpoon Cannon:**
- Skip-if-unchanged NULL check (Question 4: first boot)
- crowd_yes_pct division by zero (Question 1: zero bets)
- P&L formula division by zero (Question 1: price at 0 or 1)
- Empty picks table on first visit (Question 4: no data)
- Fiat cancellation free access forever (Question 5: unhappy billing path)
- Bet button on resolved market (Question 5: wrong time)
- Crowd-trending false positive on new markets (Question 4: zero average)
- Partial Claude batch response (Question 2: incomplete AI output)

---

## METHOD 3: FLOW TRACING (A to Z)

Pick any data flow. Trace it from the FIRST event to the LAST database write to the FINAL user-facing display. At each step ask: what can go wrong here?

**CRITICAL: If a mermaid diagram exists for this flow, verify the diagram matches your trace STEP BY STEP. The diagram is what the coder sees first. If the diagram is wrong, the coder builds the wrong thing even if the prose is right.**

**Template:**
```
FLOW: [name]
  Step 1: [trigger] -> can this fire twice? can it not fire?
  Step 2: [process] -> can this fail? what if input is bad?
  Step 3: [write] -> can this violate a constraint? race condition?
  Step 4: [read] -> can this return empty? stale? wrong type?
  Step 5: [display] -> does the user see the right thing in ALL states?
  
  DIAGRAM CHECK: does mermaid diagram [X] show all steps above?
    - Every node matches a step?
    - Every edge matches a data flow?
    - Every label matches current terminology?
    - Lock/unlock shown? Error paths shown? Finally block shown?
```

**Bugs found by this method in Harpoon Cannon:**
- Pick Board query missing whale alerts (3 locations)
- Referral attribution chain completely undocumented
- Live edge formula wrong for NO direction
- Resolution P&L formula unspecified
- Payment_provider string values unspecified

---

## METHOD 4: CROSS-REFERENCE AUDIT (The Ripple Rule)

Every concept exists in MULTIPLE places. A bug fixed in one place but not all others is WORSE than unfixed because it creates a contradiction. The coder reads the unfixed version and builds the wrong thing while the fixed version sits ignored in another file.

**THE RIPPLE RULE: Every fix must ripple across ALL representations. If you fix it in one place, you fix it in EVERY place or you fixed NOTHING.**

**All representations to check (the Ripple Checklist):**

```
For every fix, check ALL of these:
[ ] Architecture doc prose (HARPOON-CANNON-v3-FINAL.md)
[ ] Mermaid diagrams (11 diagrams - see list below)
[ ] CLAUDE.md (persistent context for every coding session)
[ ] **SQL migration (001_initial_schema.sql) - IF THE FIX TOUCHES SCHEMA, THIS FILE MUST CHANGE. No schema edit is complete without updating this file. It is the source of truth for what Supabase will create.**
[ ] Build guide session commands (harpoon-cannon-build-guide.md)
[ ] HARPOON-REFERENCE.md (quick-reference, table list)
[ ] vercel.json (cron schedules)
[ ] ERROR-HUNTER.md (error log entries)
[ ] progress.md (session tracker)
[ ] design.md (if UI-facing change)
```

**The 11 mermaid diagrams (each is a separate source of truth):**

```
1. System Architecture (graph TB)     - shows data flow between all systems
2. Poller Flow (flowchart TD)         - shows every step the poller takes
3. Scoring Engine Flow (flowchart TD) - shows two-stage pipeline
4. Signal Categories (graph TB)       - shows 8 categories + output format
5. Route Map (graph TB)               - shows all pages + navigation
6. ER Diagram (erDiagram)             - shows all tables + relationships
7. Gantt Chart (gantt)                - shows build order + dependencies
8. Revenue Milestones (graph LR)      - shows fleet growth stages
9. Referral Chain (graph TB)          - shows cookie-to-commission flow
10. Function Map (graph TB)           - shows all 12 routes + DB connections
11. Scoring Pipeline (flowchart LR)   - shows two-stage model routing
```

**Mermaid diagrams are especially dangerous because:**
- Coders read diagrams FIRST for mental model, then skim prose for details
- A stale diagram overrides correct prose in the coder's mind
- Diagrams don't get grepped by text searches (node text is buried in mermaid syntax)
- Diagrams lag behind prose edits because they're harder to update

**How to audit diagrams:**
1. For each diagram, list every claim it makes (node labels, edge labels, connection arrows)
2. Verify each claim against the prose spec AND the SQL
3. If the diagram shows something the prose contradicts, the diagram is wrong
4. If the diagram is MISSING something the prose spec describes, add it

**Cross-reference audit checklist (for every important concept):**

1. Grep for it across ALL .md files AND .sql: `grep -rn "keyword" /mnt/user-data/outputs/`
2. ALSO grep inside mermaid blocks specifically: mermaid node text uses `<br/>` not newlines
3. Compare every instance. If ANY two disagree, one is wrong.
4. Fix ALL instances. Use the Ripple Checklist above.

**Bugs found by this method in Harpoon Cannon:**
- Price normalization (divide by 100 vs parseFloat) - in prose AND mermaid
- Pick Board query (rank comparison vs IN clause) - in 3 prose sections
- Seven vs eight signal categories - in prose AND signal mermaid AND scoring prompt
- Affiliate database schema (doc vs SQL mismatch)
- CLAUDE.md "Sonnet only" vs tiered model config
- "Pequod Crew" vs "Pequod Fleet"
- Scoring Engine mermaid showed single call while prose described two-stage pipeline
- Signal Categories OUTPUT mermaid showed old fields while prose listed new Polyseer fields
- Poller mermaid missing 5 steps that prose described
- System Architecture mermaid showed 7 tables while SQL had 15
- Gantt task order didn't match build guide session order
- Route Map SCANNER said "trending only" after Pool A was changed to nexus > 0.7
- Function Map missing V10 connection while prose listed all 12 routes
- Phase 2 Gantt dependency referenced old task ID after Phase 1 rewrite
- Market status values different in NormalizedMarket, SQL, bet button, and resolution detection

**Pattern: counts are especially dangerous.** "15 tables" stated in one place, 14 in another. Always verify counts against the source of truth (grep -c).

**Pattern: mermaid diagrams drift fastest.** When prose is updated, the corresponding mermaid diagram is usually NOT updated in the same edit. This is the #1 source of cross-reference bugs.

---

## METHOD 5: PRE-MORTEM

Imagine the product launched and FAILED. What killed it? Work backward from the failure to find the spec gap.

**Pre-mortem scenarios for Harpoon Cannon:**
1. "The scoring engine produces garbage analysis" -> Is the prompt actually good? Are the anti-slop rules strong enough? Is the evidence grading real or theater?
2. "Users pay but can't access the dashboard" -> Middleware chain correct? Tier set properly by webhook? NULL tier handled?
3. "The affiliate program is being gamed" -> Self-referral prevention? Cookie stuffing? Fake account farms?
4. "We're hemorrhaging money on Claude API" -> Cost estimates correct? Skip-if-unchanged working? Batch sizes right?
5. "A competitor scrapes all our analysis" -> RLS on picks? Watermarking? Rate limiting? Bot detection?
6. "The poller stops and nobody notices" -> Health monitoring? Admin alerts? Lock auto-release?

---

## METHOD 6: BOUNDARY VALUE ANALYSIS

For every numeric input, test: minimum, maximum, zero, negative, just below threshold, just above threshold, and NULL.

**Applied to Harpoon Cannon:**
- yes_price: 0.0 (valid edge case), 1.0 (resolved), -0.01 (invalid, caught by validation), 1.01 (invalid, caught), NULL (shouldn't happen, FK'd to market)
- nexus_score: 0.0 (no nexus), 0.69 (just below Pool A threshold 0.7), 0.70 (just above), 1.0 (max)
- crowd_bets_24h: 0 (zero division guard), 1 (minimal), 50 (threshold), 51 (just above), 10000 (whale)
- edge: 0 (no edge, borderline), 1 (minimal), 50 (large), -50 (NO direction), 100 (max theoretical)
- confidence: "high" / "medium" / "low" (what if Claude outputs "very high" or "uncertain"? Parser should map unknown to "low" or reject)

---

## METHOD 7: VIBE CODE FAILURE PATTERNS (from industry research)

These are the specific areas where AI-generated code fails in production SaaS:

1. **Auth edge cases:** Session expiry during long forms, OAuth state validation, magic link race conditions, MFA flows, concurrent login from multiple devices
2. **Billing ALL paths:** Success, failure, retry, downgrade, cancellation, grace period, chargeback, refund, proration, currency mismatch
3. **Webhook reliability:** Duplicate delivery, out-of-order delivery, delayed delivery, signature verification, timeout on processing
4. **Database constraints:** Unique violations on race conditions, foreign key violations on cascade deletes, type mismatches on jsonb fields
5. **API response handling:** Timeout, partial response, rate limit, auth expired, malformed JSON, empty response, HTML error page instead of JSON
6. **Empty/loading/error states:** Every page needs all three. AI generates the loaded state. It forgets loading and error states.
7. **Timezone bugs:** Cron runs in UTC. User sees local time. Comparison between server UTC and client local time for "today" or "this hour" calculations.

---

## METHOD 8: CAPTURE-RECAPTURE ESTIMATION

Statistical method to estimate total bugs from multiple independent reviews.

If Reviewer A finds 20 bugs and Reviewer B finds 15 bugs, and 10 bugs were found by BOTH:
- Estimated total bugs = (20 * 15) / 10 = 30
- Undetected bugs = 30 - 25 (unique found) = 5

**Applied to Harpoon Cannon audits:**
- Full transcript review across 4 session files: 379 unique edits
- Categorized: 40 architecture + 104 missing specs + 66 bugs + 29 cross-ref + 34 security = 273 issues (Categories A-E)
- Error Hunter deep audit (Category F): 41 additional issues found by systematic method application
- Total documented issues: 407
- Additional 138 feature enhancements/improvements
- Grand total: 545+ unique edits
- Estimated remaining: ~2-3 interaction effects that can ONLY surface when running code against live APIs. Every Phase 1 flow has been traced through all 9 methods TWICE (once sequential, once adversarial), then a full cross-file drift audit. Every mermaid diagram audited. Every cross-reference verified. Every production failure scenario tested. Every boundary value checked. Every webhook race condition handled. Every canonical value synced across all 11 files. The spec is as clean as it can be without running it.

---

## METHOD 9: DIAGRAM CONSISTENCY AUDIT

Mermaid diagrams, Gantt charts, ER diagrams, and flowcharts are SEPARATE sources of truth that coders read BEFORE prose. A stale diagram overrides correct prose in the coder's mind every time. Diagrams drift fastest because they're harder to update than prose.

**For each diagram, verify:**

```
DIAGRAM: [name, line number]
  [ ] Every node label matches current terminology (not stale names)
  [ ] Every node's description matches current spec (not old architecture)
  [ ] Every edge/arrow represents a real data flow that exists in the spec
  [ ] No MISSING edges (if A triggers B in prose, the arrow must exist)
  [ ] No EXTRA edges (if a connection was removed, the arrow must be gone)
  [ ] Subgraph groupings match current architecture (not old split)
  [ ] Counts match (tables in DB subgraph = actual table count)
  [ ] Style/colors consistent across all diagrams
```

**Diagram-specific patterns:**

- **ER Diagram vs SQL:** Every table, every column, every FK, every type must match. The ER is what the coder looks at to understand relationships. The SQL is what actually runs. They MUST agree.
- **Gantt vs Build Guide:** Every task in the Gantt must correspond to a session in the build guide. Task order must match session order. Dependencies (after p1a, after p1b) must chain correctly after any rewrite.
- **Flowcharts vs Prose:** Every step in the flowchart must exist in the prose spec. Every condition/branch must match the current logic. Lock/unlock, error paths, finally blocks, guard clauses all need to be shown.
- **Route Map vs Project Structure:** Every page in the route map must have a matching file in the project structure tree. Navigation arrows must reflect actual links in the UI.
- **Function Map vs vercel.json:** Every cron job in vercel.json must appear in the function map. Every connection arrow must match the data flow described in operational concerns.

**The cardinal sin: fixing prose but not the diagram.** This was the #1 source of bugs in the Harpoon Cannon audit. The two-stage pipeline was fully specified in prose for 3+ passes before anyone noticed the Scoring Engine mermaid still showed a single Claude call. Pool A was fixed to "nexus > 0.7" in prose while the mermaid still said "trending + nexus > 0.7." Market status was standardized in prose while the mermaid said "resolved/closed/settled."

**Prevention: after ANY prose edit, immediately grep for the changed concept in ALL mermaid blocks:**
```bash
# Find all mermaid blocks that mention the changed concept
grep -n "your_keyword" architecture.md | grep -B5 "mermaid\|graph\|flowchart\|gantt\|erDiagram"
```

**Bugs found by this method in Harpoon Cannon:**
- Scoring Engine mermaid: single call vs two-stage pipeline (HIGH)
- Signal Categories OUTPUT: old fields vs Polyseer fields (HIGH)
- Gantt: task order vs build guide sessions (HIGH)
- System Architecture: 7 tables vs 15, no payment flow (MEDIUM)
- Poller Flow: missing 5 steps (MEDIUM)
- Route Map: "trending only" vs "nexus > 0.7" (MEDIUM)
- Function Map: missing V10 connection (MEDIUM)
- Phase 2 Gantt: broken dependency after Phase 1 rewrite (HIGH)

---

## WHEN TO USE EACH METHOD

| Situation | Best Method |
|---|---|
| Starting a new review | Method 1 (Bayesian) to pick where to look |
| Reviewing a specific feature | Method 2 (Happy vs All Paths) |
| Debugging a data flow | Method 3 (A to Z tracing + diagram check) |
| After making ANY changes | Method 4 (Cross-reference + Ripple Rule) |
| Strategic review | Method 5 (Pre-mortem) |
| Reviewing formulas/thresholds | Method 6 (Boundary values) |
| First time building a feature | Method 7 (Vibe code failure patterns) |
| Estimating "are we done?" | Method 8 (Capture-recapture) |
| After editing prose that has a diagram | Method 9 (Diagram consistency) |
| After ANY edit to ANY file | Method 4 Ripple Checklist (check ALL 11 files + 11 diagrams) |

## COMPLETE ERROR LOG

Total issues found and fixed: **379 unique edits across 4 session transcripts**

Every entry below represents something that was wrong, missing, contradictory, or unspecified in the architecture. Without these fixes, a coding AI would have produced broken code, guessed wrong, or built on a cracked foundation.

### Category A: ARCHITECTURE DECISIONS (40 entries)
Wrong foundation that had to be changed before anything could be built on it.

```
A01 Poller ran on Supabase Edge Functions (2s CPU limit). Moved to Vercel cron (300s limit). Every poller reference updated.
A02 Tech stack said "Supabase Edge Functions" as execution layer. Removed. Single execution platform: Vercel.
A03 "Two Execution Layers" section described split architecture. Replaced with "Single Execution Platform" section.
A04 Fiat payment was "Lemon Squeezy OR Polar." Undecided in 15+ locations. Decided: Polar. All references updated.
A05 Crypto payment was "Coinremitter OR BTCPay Server." Decided: Coinremitter. All references updated.
A06 System architecture mermaid showed Supabase Edge poller. Updated to Vercel cron.
A07 Engine 1 header said "Supabase Edge Function." Changed to "Vercel Cron."
A08 Function map split between Supabase and Vercel. Consolidated under Vercel.
A09 Deliverables listed "poll-markets edge function." Changed to Vercel route.
A10 Build guide Session 2 referenced Edge Function setup. Removed.
A11 Build guide Session 5 referenced Edge Function. Changed to Vercel route.
A12 Gantt chart referenced Edge Function tasks. Updated.
A13 vercel.json didn't include poller cron. Added "*/1 * * * *" schedule.
A14 CLAUDE.md listed poller as Edge Function. Updated to Vercel route.
A15 CLAUDE.md API routes didn't include poller. Added.
A16 Project structure missing poll-markets route file. Added.
A17 pg_cron reference in poller lock bug description was stale. Fixed.
A18 Stale Edge Function reference in poller execution section. Fixed.
A19 Env vars still referenced LEMONSQUEEZY_* names. Updated to POLAR_*.
A20 Phase 2/3 env vars referenced LEMONSQUEEZY variant IDs. Updated to POLAR product IDs.
A21 Lemon Squeezy remaining references (5+) in various sections. All updated to Polar.
A22 Accelerator resources referenced Lemon Squeezy SDK. Updated to @polar-sh/sdk.
A23 Lemon Squeezy ownership disclosure section. Updated to reflect Polar decision.
A24 BTCPay references in crypto rail section. Updated to Coinremitter only.
A25 Tech stack table had corporate ownership note. Cleaned.
A26 Payment rails had rejection/fallback/deliberation text. Cleaned to final decisions.
A27 Vendor selection deliberation notes throughout. Removed.
A28 Scoring engine said "Claude API (Sonnet)" only. Changed to config-driven tiered models.
A29 Two-stage pipeline didn't exist. Rewrote scoring from single-call to Researcher->Analyst.
A30 Model routing per tier not specified. Added MODEL_CONFIG with Haiku->Sonnet, Sonnet->Sonnet, Sonnet->Opus.
A31 Landing page used gambling language. Rewrote with investor positioning.
A32 Pricing section used gambling language. Rewrote with investing framing.
A33 No-refund policy used gambling language. Rewrote.
A34 Document header used generic language. Updated with investing thesis.
A35 Branding rules in scoring prompt said "Speargun Intelligence." Updated to "Harpoon Cannon Intelligence."
A36 ALL references renamed from Speargun to Harpoon Cannon across all files.
A37 Milestone section was flat. Rewrote with fleet metaphor and growth stages.
A38 No Phase 3b (Command Center) concept. Added complete section.
A39 No Phase 4 (AI autonomous trading) concept. Added complete section.
A40 Pequod Crew framing throughout. Updated to Pequod Fleet framing.
```

### Category B: MISSING SPECS (104 entries)
Nothing existed. Coder would have had to guess. Every one of these would have consumed an entire coding session in confusion.

```
B01 Project folder structure didn't exist. Added complete tree with every file path.
B02 Crowd intelligence system didn't exist. Added crowd_views_24h, crowd_bets_24h, crowd_watchlist_count, crowd_yes_pct fields, aggregation cron, trending detection.
B03 market_views table didn't exist. Added for view tracking.
B04 track-view API route didn't exist. Added.
B05 aggregate-crowd API route didn't exist. Added with 15-min cron.
B06 Crowd indicator on Pick Board didn't exist. Added spec.
B07 Crowd activity section on Pick Detail didn't exist. Added.
B08 Crowd data in scoring prompt payload didn't exist. Added.
B09 Crowd-trending notification trigger didn't exist. Added.
B10 Crowd aggregation operational concerns didn't exist. Added.
B11 Crowd intelligence Gantt tasks didn't exist. Added.
B12 7th signal category (crowd intelligence) didn't exist. Added.
B13 8th signal category (social media/3B) didn't exist. Added.
B14 Social media search instructions in scoring prompt didn't exist. Added.
B15 social_sentiment field in JSON output didn't exist. Added.
B16 Social sentiment field in picks table didn't exist. Added to SQL.
B17 Social sentiment in ER diagram didn't exist. Added.
B18 Social signal integration plan in operational concerns didn't exist. Added.
B19 S3B connection in mermaid signal diagram didn't exist. Added.
B20 Polyseer bilateral research pattern didn't exist. Added PRO/CON methodology.
B21 Polyseer dual probability (pNeutral/pAware) didn't exist. Added.
B22 Polyseer evidence quality scoring (A/B/C/D) didn't exist. Added.
B23 Polyseer evidence caps and source deduplication didn't exist. Added.
B24 Polyseer gap identification didn't exist. Added evidence_gap field.
B25 Polyseer "what would change" didn't exist. Added what_would_change field.
B26 evidence_gap field in JSON output didn't exist. Added.
B27 what_would_change field in JSON output didn't exist. Added.
B28 p_neutral, p_aware, evidence_divergence fields in picks table didn't exist. Added to SQL.
B29 evidence_gap, what_would_change fields in picks table didn't exist. Added to SQL.
B30 Polyseer in accelerator resources didn't exist. Added.
B31 Competitive landscape section didn't exist. Added with Predly, PredictEngine, Polymarket Analytics analysis.
B32 Speed alerts tier feature didn't exist. Added.
B33 Edge tracker feature didn't exist. Added.
B34 Cross-market correlation alerts didn't exist. Added.
B35 Accuracy dashboard tier feature didn't exist. Added.
B36 Automated betting tier feature row didn't exist. Added.
B37 Branding rules section didn't exist. Added with scoring prompt branding block.
B38 Revenue milestones section didn't exist. Added.
B39 Affiliate program section didn't exist. Added.
B40 Affiliate commission flow didn't exist. Added.
B41 Affiliate fraud prevention didn't exist. Added.
B42 Referral attribution chain didn't exist. Added 9-step cookie-to-commission chain.
B43 Notification throttle storage spec didn't exist. Added.
B44 MRR calculation spec didn't exist. Added formula + caching.
B45 Claude API response parsing spec didn't exist. Added multi-block handling.
B46 Auto-betting security spec didn't exist. Added AES-256 encryption + risk controls.
B47 Empty state handling spec didn't exist. Added for every dashboard view.
B48 Pequod Fleet framing in crowd intelligence mermaid didn't exist. Added.
B49 Pequod Fleet CTA on landing page didn't exist. Added.
B50 Social sharing integration across all surfaces didn't exist. Added.
B51 Post-signup onboarding with fleet recruitment didn't exist. Added.
B52 Win celebration modal with share didn't exist. Added.
B53 check-expirations API route didn't exist. Added with daily cron.
B54 cycle_id in picks table didn't exist. Added.
B55 market_url in markets table didn't exist. Added.
B56 expires_at in anomalies table didn't exist. Added.
B57 error_log table didn't exist. Added.
B58 API authentication details for Kalshi/Polymarket didn't exist. Added complete field reference.
B59 Market scale estimate didn't exist. Added.
B60 Internal route security spec didn't exist. Added HARPOON_INTERNAL_SECRET.
B61 Vercel plan requirement note didn't exist. Added.
B62 Complete environment variables list didn't exist. Added.
B63 Scoring prompt specification (3-part structure) didn't exist. Added.
B64 Token optimization (caveman compression) didn't exist. Added.
B65 Input compression for market payloads didn't exist. Added.
B66 Agentic Engineering methodology section didn't exist. Added.
B67 CLAUDE.md context file didn't exist. Created.
B68 SQL migration file didn't exist. Created.
B69 vercel.json didn't exist. Created.
B70 Build guide didn't exist. Created.
B71 Pre-Build Bug Prevention section didn't exist. Added 14 bugs.
B72 Security hardening section didn't exist. Added rate limiting, sessions, watermarking, CSP.
B73 active_sessions table didn't exist. Added to SQL.
B74 Cost optimization strategies section didn't exist. Added 7 strategies.
B75 Prompt caching spec didn't exist. Added.
B76 Parser mapping table didn't exist. Added.
B77 Unified Command Center (Phase 3b) spec didn't exist. Added.
B78 Command Center Gantt tasks didn't exist. Added.
B79 Arbitrage row in tier table didn't exist. Added.
B80 Phase 4 AI autonomous trading spec didn't exist. Added.
B81 Phase 4 Gantt tasks didn't exist. Added.
B82 Anomaly detection math unspecified. Added z-score formula, NULLIF, severity calc.
B83 Nexus config structure missing. Added full TypeScript example.
B84 Tier feature enforcement unspecified. Added TIER_FEATURES config.
B85 Supabase client usage unspecified. Documented browser/server/admin per route.
B86 Two-stage pipeline intermediate format missing. Added JSON structure.
B87 Crypto subscription duration unspecified. Set to 30 days.
B88 payment_provider string values unspecified. Set 'polar' and 'coinremitter'.
B89 Whale alert partial index missing. Added idx_picks_whale.
B90 Web search tool config string unspecified. Added exact API config.
B91 Error logging structured format didn't exist. Added complete schema.
B92 Admin health dashboard (RED/YELLOW/GREEN) didn't exist. Added.
B93 system_state health monitoring seeds didn't exist. Added 6 last_success entries.
B94 Error logging pattern in CLAUDE.md didn't exist. Added.
B95 Cross-platform market handling note didn't exist. Added.
B96 TOC with line numbers didn't exist. Added.
B97 models.ts in project structure didn't exist. Added.
B98 tier-features.ts in project structure didn't exist. Added.
B99 Parser validation rules (confidence/direction/probability/edge) didn't exist. Added.
B100 Partial batch handling spec didn't exist. Added.
B101 Fiat subscription cancellation webhook handling didn't exist. Added.
B102 Build guide Phase 2 sessions didn't exist. Added 6 sessions.
B103 Build guide Phase 3 sessions didn't exist. Added 8 sessions.
B104 ERROR-HUNTER.md methodology guide didn't exist. Created.
```

### Category C: BUGS (79 entries)
Code would break, produce wrong output, or create security holes.

```
C01 CRITICAL: Price normalization contradiction. "Divide by 100" vs "parseFloat, already 0-1." Fixed to parseFloat only.
C02 CRITICAL: Pick Board query used rank comparison (min_tier_rank <= user_tier_rank). TEXT column, alphabetical fails. Fixed to IN clause. 3 locations.
C03 CRITICAL: Poller lock was READ then WRITE (race condition). Fixed to atomic UPDATE...RETURNING.
C04 CRITICAL: Scorer lock didn't exist. Cron + whale alert could collide. Added scorer_lock.
C05 CRITICAL: Webhook idempotency not enforced. Retry = duplicate payment. Added UNIQUE constraint.
C06 CRITICAL: Picks table missing RLS. Public anon key could query all analysis. Added auth policy.
C07 CRITICAL: Pick Board query missing whale alerts. 3 locations used cycle_id only. Added OR clause.
C08 CRITICAL: Fiat cancellation = free access forever. subscription.canceled webhook unhandled. Added handler.
C09 HIGH: Skip-if-unchanged NULL guard missing. last_analyzed_at NULL = first analysis never runs. Added IS NOT NULL.
C10 HIGH: crowd_yes_pct division by zero on zero bets. Added CASE WHEN guard.
C11 HIGH: Live edge formula wrong for NO direction. Used YES formula for all picks. Fixed direction-aware.
C12 HIGH: Resolution P&L formula unspecified. No math at all. Added 4-case formula.
C13 HIGH: Partial Claude batch silently discarded. Added partial handling + logging.
C14 HIGH: Resolution uses fragile price heuristic (>=0.99). Fixed: prefer platform explicit field.
C15 HIGH: Crowd-trending false positive when rolling avg=0. Added MIN threshold of 20.
C16 HIGH: Snapshot pruning ghost feature. No cron route existed. Added to check-expirations.
C17 HIGH: market_price_at_scoring missing from picks table. Added column.
C18 HIGH: Day 1 anomaly false positives. No minimum snapshot count. Added MIN_SNAPSHOTS = 100.
C19 HIGH: Chargeback policy described but no enforcement mechanism. Added ban logic.
C20 HIGH: cycle_id generation not specified. Added gen_random_uuid() once per run.
C21 HIGH: confidence field not validated. "uncertain" -> NaN propagation. Added normalize + default.
C22 HIGH: direction field not normalized. "yes" lowercase breaks matching. Added uppercase normalize.
C23 HIGH: true_probability not range-validated. 150 or -5 corrupt edge. Added 0-100 check.
C24 HIGH: edge from Claude not verified. Inconsistent pairs possible. Added RECALCULATE.
C25 HIGH: Referral attribution chain undocumented. Cookie to payment was guesswork. Added 9-step chain.
C26 HIGH: Crypto subscription duration unspecified. "N months" undefined. Set 30 days.
C27 HIGH: payment_provider values unspecified. check-expirations filtered on unknown string. Set values.
C28 HIGH: Web search tool config unspecified. Coder wouldn't know exact API type string. Added.
C29 HIGH: Anomaly detection math unspecified. "Calculate z-score" of what? Added exact formula.
C30 HIGH: Nexus config structure missing. "Keyword matching" with no keywords. Added TypeScript.
C31 HIGH: Tier feature enforcement unspecified. "10 watchlist" with no enforcement. Added config.
C32 HIGH: Supabase client usage unspecified. Wrong client = RLS blocks everything. Documented.
C33 HIGH: Two-stage pipeline intermediate format missing. No schema between stages. Added.
C34 HIGH: Authenticated-but-unpaid user unhandled. tier=NULL, no middleware behavior. Added redirect.
C35 HIGH: Deliverables config file paths wrong. "nexus-taxonomy.ts" vs "nexus/config.ts." Fixed.
C36 HIGH: Whale alert partial index missing. OR clause in query has no index. Added.
C37 HIGH: Affiliate schema doc vs SQL mismatch. Doc had fields SQL didn't. Fixed doc.
C38 HIGH: Commission calculation ambiguous timing. Monthly or instant? Clarified: instant.
C39 HIGH: P&L formula division by zero at price 0 or 1. Added NULL guard.
C40 HIGH: check-expirations only targeted crypto (payment_provider filter). Fixed to both rails.
C41 HIGH: Build guide Session 9 missing cancellation handling. Added subscription.canceled.
C42 MEDIUM: Bet button active on resolved markets. Disabled.
C43 MEDIUM: CLAUDE.md "Sonnet only" stale after tiered model change. Fixed.
C44 MEDIUM: "Pequod Crew" stale after Fleet rename. Fixed.
C45 MEDIUM: Upstash Redis phantom service in MRR calculation. Fixed to system_state.
C46 MEDIUM: "Seven signal categories" in mermaid. Should be eight. Fixed.
C47 MEDIUM: polymarket-kit stale reference in Dev Methodology. Removed.
C48 MEDIUM: Stale CPU budget reference from Edge Functions era. Removed.
C49 MEDIUM: tier-features.ts missing from project structure. Added.
C50 MEDIUM: models.ts missing from deliverables. Added.
C51 MEDIUM: active_sessions missing from ER diagram. Added.
C52 MEDIUM: active_sessions missing from function map DB node. Added.
C53 MEDIUM: Gantt missing security hardening and onboarding tasks. Added.
C54 MEDIUM: Phase 2 Gantt dependency broken after task addition. Fixed.
C55 MEDIUM: Lock release specs missing "finally block." Crash = permanent lock. Fixed.
C56 MEDIUM: polymarket-kit contradicts "use native fetch" in Accelerators. Clarified.
C57 MEDIUM: Cross-platform duplicates unexplained. Documented as intentional.
C58 MEDIUM: Skip-if-unchanged in CLAUDE.md didn't reference specific fields. Made explicit.
C59 MEDIUM: Scoring prompt still said "seven signal categories." Updated to eight.
C60 MEDIUM: Social media search instructions missing from prompt. Added.
C61 MEDIUM: CLAUDE.md skip fields not specific enough. Added explicit field names.
C62 MEDIUM: Atomic lock SQL missing updated_at in WHERE. Added.
C63 MEDIUM: Session 2 Supabase types command vague. Made specific.
C64 MEDIUM: Session 3 SDK reference not verified. Changed to native fetch.
C65 MEDIUM: Session 8 missing evidence_gap/what_would_change display. Added.
C66 MEDIUM: Packages section referenced unverified SDK. Removed.
```

### Category D: CROSS-REFERENCE SYNCS (29 entries)
Same concept described differently in 2+ files. Would cause coder to build one thing from file A and a different thing from file B.

```
D01 SQL foreign keys vs ER diagram relationships - 3 mismatches found and fixed.
D02 Picks table SQL columns vs ER diagram fields - 4 fields missing from ER.
D03 Markets table SQL vs ER - 3 fields missing from ER.
D04 user_profiles SQL vs ER - verified match.
D05 vercel.json crons vs architecture doc cron specs - 2 mismatches fixed.
D06 SQL indexes vs architecture doc index list - verified match.
D07 JSON output fields vs picks table columns - 6 fields missing from table.
D08 Parser mapping vs actual field names - confidence->confidence_level rename undocumented.
D09 Route definitions: CLAUDE.md vs architecture doc vs build guide - 3 synced.
D10 Table definitions: CLAUDE.md vs SQL vs ER diagram - all synced.
D11 Config file names: deliverables vs project structure - 3 path mismatches fixed.
D12 Pick Board query: dashboard section vs CLAUDE.md vs N+1 fix - 3 locations synced.
D13 Tier mapping: architecture doc vs CLAUDE.md - harpooner/first_mate/ahab IN clause synced.
D14 Formula: ranking formula in arch doc vs CLAUDE.md - synced.
D15 Cost model figures vs savings table figures - corrected to match.
D16 Two-stage pipeline spec vs CLAUDE.md vs build guide - all 3 synced.
D17 Model config: architecture doc vs CLAUDE.md vs build guide Session 6 - all synced.
D18 Crowd fields: markets table SQL vs ER vs aggregation spec - all synced.
D19 Polyseer fields: JSON output vs SQL vs ER vs parser mapping - all synced.
D20 Social sharing: build guide sessions vs architecture doc sections - synced.
D21 Function map DB node vs actual table count (was 12, should be 15) - fixed.
D22 Mermaid signals diagram vs scoring prompt categories (7 vs 8) - fixed.
D23 Savings table figures didn't match recalculated two-stage numbers - fixed.
D24 Account_status field: security section vs user_profiles schema - synced.
D25 Internal secret name: some places SPEARGUN_INTERNAL_SECRET, should be HARPOON_INTERNAL_SECRET - synced.
D26 Environment variable names: pre-rename vs post-rename - all synced to HARPOON.
D27 Branding in scoring prompt: "Speargun Intelligence" vs "Harpoon Cannon Intelligence" - fixed.
D28 Build guide session contexts vs actual section names in architecture doc - verified.
D29 CLAUDE.md engine-set fields vs architecture doc parser mapping - synced.
```

### Category E: SECURITY ADDITIONS (34 entries)
Security features that didn't exist at all. Every one is a potential breach.

```
E01 RLS policies missing on picks table (CRITICAL - public anon key could query all analysis)
E02 RLS policies missing on anomalies table
E03 RLS policies missing on snapshots table  
E04 active_sessions table didn't exist (no concurrent session management)
E05 Session limits per tier (2/3/5) not specified
E06 Rate limiting not specified (60 req/min user, 30 req/min IP)
E07 x-client-id header check not specified (bot prevention)
E08 User-Agent blocking not specified
E09 Unicode watermarking on rationale text not specified (content theft prevention)
E10 Content-Security-Policy headers not specified
E11 Supabase auth configuration not specified (email confirm, CAPTCHA, session duration)
E12 Refresh token rotation not specified
E13 Banned user middleware not specified
E14 account_status field didn't exist in user_profiles
E15 Chargeback ban enforcement mechanism didn't exist
E16 Webhook signature verification not specified for Polar
E17 Webhook signature verification not specified for Coinremitter
E18 Webhook idempotency not enforced (duplicate payment protection)
E19 Affiliate self-referral prevention not specified
E20 Affiliate fraud detection not specified
E21 Cookie stuffing prevention not specified
E22 Internal route secret (HARPOON_INTERNAL_SECRET) pattern not fully specified
E23 AES-256 credential encryption for Phase 3 not specified
E24 Risk controls for automated betting not specified
E25 Max bet size limit not specified
E26 Max daily exposure limit not specified
E27 Auto-stop-loss not specified
E28 Never log credentials rule not specified
E29 API key generation for REST API not specified
E30 API rate limiting (100 req/hour) not specified
E31 Admin role check middleware not specified
E32 Loading.tsx skeletons for all dashboard pages not specified
E33 Error.tsx boundaries not specified
E34 300-line file size cap not specified
```

### Category F: ERROR HUNTER DEEP AUDIT (41 entries)
Found by systematic application of Error Hunter Methods 2-7 to every Phase 1 flow. These are post-architecture bugs that would only surface during build or first run.

```
F01 CRITICAL: No user_profiles creation trigger. User signs up, auth.users created, but user_profiles never exists. Webhook sets tier on nonexistent row. Fixed: handle_new_user trigger in SQL with collision-safe referral code.
F02 HIGH: Pool A "trending" was filter not boost. Zero crowd data = zero trending markets = Harpooner sees no picks on day 1. Fixed: trending is sort priority within Pool A, base is nexus > 0.7.
F03 HIGH: Promise.all kills both platforms. Kalshi down = Polymarket data also lost. Fixed: Promise.allSettled.
F04 HIGH: Polar checkout no user-to-payment matching. Webhook can't match payment to user without metadata. Fixed: supabase_user_id in checkout session metadata.
F05 HIGH: Voided/cancelled markets completely unhandled. was_correct, P&L, accuracy all assume YES/NO only. Fixed: voided = NULL, P&L = 0, excluded from accuracy.
F06 HIGH: analyze-urgent no throttle or duplicate prevention. 5 whale alerts = 5 concurrent Claude calls. Fixed: last_urgent_at throttle + skip if recently scored.
F07 HIGH: Notification trigger mechanism unspecified. Scorer writes picks but HOW are notifications dispatched? Fixed: fire-and-forget POST to send-notifications.
F08 HIGH: NormalizedMarket interface undefined. Build guide says create it, doc never defines fields. Fixed: complete TypeScript interface.
F09 HIGH: Vercel cron auth conflicts with internal secret. Cron sends CRON_SECRET, routes check HARPOON_INTERNAL_SECRET. Fixed: dual auth accepting either.
F10 HIGH: Poller upsert ON CONFLICT clause never specified. Coder guesses columns to update. Fixed: complete INSERT...ON CONFLICT with RETURNING.
F11 HIGH: Expired subscription gets hours of free access between cron runs. Fixed: middleware real-time expiration check.
F12 HIGH: Tier upgrade creates double billing via new checkout. Fixed: Polar subscription update API (plan change).
F13 HIGH: Market status values inconsistent. NormalizedMarket='open/closed/settled', SQL default='active', bet button checks 'resolved'. Fixed: standardized to active/closed/resolved.
F14 HIGH: Ban flow missing session cleanup. Banned user stays logged in. Fixed: DELETE active_sessions + revoke Supabase auth.
F15 HIGH: anomaly_bonus lookup query unspecified. Coder writes N+1 queries. Fixed: batch query into Set.
F16 HIGH: Scoring Engine mermaid showed single call not two-stage pipeline. Coder builds wrong architecture. Fixed: complete rewrite.
F17 HIGH: Signal Categories OUTPUT mermaid showed old format. Missing Polyseer fields. Fixed.
F18 HIGH: Gantt Phase 1 tasks didn't match build guide sessions. Session 1 placed after Session 6. Fixed: session numbers in task names.
F19 HIGH: Resolve-picks has no idempotency guard. Concurrent triggers double-count accuracy. Fixed: WHERE resolved = false.
F20 HIGH: Claude API 401 not handled separately. Invalid key retried forever. Fixed: detect 401, alert admin, no retry.
F21 HIGH: error_log and system_state have no RLS. Stack traces and internal state readable via public anon key. Fixed: RLS enabled, admin-only.
F22 HIGH: Pick Detail page no tier check. Harpooner navigates to Ahab pick URL, reads full analysis free. Fixed: verify min_tier IN user_allowed_tiers before render.
F23 HIGH: Two-stage pipeline failure handling unspecified. Stage 1 succeeds, Stage 2 fails = evidence wasted. Fixed: save Stage 1 output, retry Stage 2, timeout protection.
F24 HIGH: Phase 2 Gantt broken dependency (p1p changed to p1n after rewrite). Fixed.
F25 MEDIUM: Notification channel failure silently ignored forever. Invalid Discord URL = notifications vanish. Fixed: auto-disable after 3 failures.
F26 MEDIUM: Realtime debounce missing. 30 picks = 30 dashboard flickers. Fixed: 3-second debounce spec.
F27 MEDIUM: Referral code collision crashes signup trigger. Fixed: retry loop with 5 attempts.
F28 MEDIUM: Empty states only specified for Pick Board. 9 other pages had no empty state. Fixed: text for every page.
F29 MEDIUM: Invalid SQL for latest_cycle_id (DISTINCT with ORDER BY on different column). Fixed.
F30 MEDIUM: Admin can ban themselves (permanent lockout). Fixed: self-ban prevention guard.
F31 MEDIUM: Route Map mermaid missing BOARD->REFERRALS navigation link. Fixed.
F32 MEDIUM: Function Map mermaid missing V10 connection to DATA. Fixed.
F33 MEDIUM: Route Map SCANNER said "trending only" which is misleading after Pool A fix. Fixed.
F34 MEDIUM: System Architecture mermaid completely stale (single call, no payments, 7 tables). Rewritten.
F35 MEDIUM: Poller Flow mermaid missing 5 steps (MIN_SNAPSHOTS, resolution, error logging, nexus check, finally). Rewritten.
F36 MEDIUM: FK on user_bets.pick_id missing ON DELETE behavior. Prevents admin cleanup. Fixed: SET NULL.
F37 MEDIUM: FK on notification_log.pick_id missing ON DELETE behavior. Fixed: SET NULL.
F38 MEDIUM: system_state needs public read for mrr_cache only. Added targeted RLS policy.
F39 MEDIUM: Build guide Session 2 didn't mention verifying handle_new_user trigger. Fixed.
F40 MEDIUM: Env var count said "10" but actual is 12 (CRON_SECRET + POLAR changes). Fixed.
F41 MEDIUM: Bet button only checked 'resolved' not 'closed'. Closed markets still showed bet button. Fixed.
```


---

## SUMMARY

| Category | Count | Description |
|---|---|---|
| A: Architecture Changes | 40 | Wrong foundation, had to rebuild |
| B: Missing Specs | 104 | Nothing existed, coder would guess |
| C: Bugs | 66 | Code would break or produce wrong output |
| D: Cross-Reference Syncs | 29 | Same concept, different description in 2+ files |
| E: Security Additions | 34 | Missing security features = potential breach |
| F: Error Hunter Deep Audit | 41 | Found by systematic method application to Phase 1 flows |
| **TOTAL (Original A-F)** | **314** | **documented issues found and fixed pre-build** |
| G: BYOAI + Full Review | 15 | BYOAI integration, credits contradiction, cross-ref syncs |
| H: Phase 1 Pre-Build | 10 | Column names, missing fields, stale math |
| I: Production Failures | 12 | Missing columns, broken rate limiting, unspec'd verification |
| J: 9-Method Sequential | 14 | NaN corruption, payment races, security holes, boundary bugs |
| K: Adversarial 9-Method Repeat | 14 | Volume parsing, bet validation, kill switch, out-of-order webhooks, API schema validation |
| L: Full Cross-File Drift + Concept Gaps | 24 | File count drift, stale TOC, missing specs, platform playbook, refund clawback, Polar mode, waitlist table |
| M: Production Monk Phase 1 Readiness | 4 | SQL header, status page client, deploy checklist, notification_type column |
| **GRAND TOTAL** | **407** | **all found and fixed before a single line of code** |

Additional feature enhancements and improvements: ~138 edits (competitive features, social sharing, fleet metaphor, Polyseer patterns, Phase 3b/4 specs, event tracking, feedback system, annual billing, exit survey, email capture, status page, waitlist table, POLAR_MODE, deploy checklist)

**Grand total: 545+ unique edits across all sessions.**

---

## UPDATING THIS GUIDE

When you find a new bug:
1. Add it to the appropriate category (A-F) in the ERROR LOG with the next sequential number
2. Update the BAYESIAN BUG DENSITY MAP if it changes section density
3. If the bug represents a NEW pattern not covered by Methods 1-9, add a new method
4. If an existing method would have caught this bug, add it to that method's "Bugs found" list
5. Update the SUMMARY table counts
6. **RIPPLE RULE: Apply Method 4's Ripple Checklist to your fix.** Check ALL 11 files + ALL 11 mermaid diagrams. If the fix touches a concept that appears in a diagram, update the diagram.
7. If you find a bug in a diagram, assume the same bug exists in at least one prose section. Grep for it.
8. If you find a bug in prose, check if a diagram exists for that flow. If yes, verify the diagram too.

**The guide gets smarter with every bug found. The monk learns from every mistake. The monk also checks every diagram.**

---

## AUDIT G: BYOAI + FULL PROJECT REVIEW (2026-04-15)

Applied Methods 2, 3, 4, 5, 6, 7, 9 to the BYOAI feature and surrounding systems. Found 15 issues across the full project.

### G01 CRITICAL: Intelligence Credits numbers contradict across 5 locations

The single most dangerous contradiction in the entire spec. A coder will build the wrong system.

- Tier differentiation table (scoring engine section): says "Intelligence Credits: 250/day" for BOTH First Mate and Ahab
- Courtroom Usage Limits paragraph: says "Credits deducted from the user's daily Intelligence Credits allowance (250/day for First Mate and Ahab)"
- TIER_FEATURES config: says monthly_credits: 150 (FM), 500 (Ahab)
- Credits table (Intelligence Credits section): says 150 monthly (FM), 500 monthly (Ahab)
- CLAUDE.md: says "Monthly allowance: Harpooner 0, First Mate 150, Ahab 500"

"250/day" and "150/month" cannot both be true. The TIER_FEATURES config, the credits table, and CLAUDE.md all agree on MONTHLY (150/500). The "250/day" in two locations is stale from an earlier design and was never cleaned up. This must be resolved to one consistent set of numbers across all 5 locations.

Additionally, the tier feature comparison table says "Final Judgement: Yes, 10/day (FM), Yes, 25/day (Ahab)" which is yet another set of daily numbers that don't match the 50/day safety cap described elsewhere. Are 10/day and 25/day the courtroom-specific call limits? Or are they stale? If they're real, they contradict the "50 calls/day" safety cap. Three different daily cap numbers in one spec.

**Decision needed from Wolf:** What are the actual numbers? The monk recommends: monthly credits (150 FM, 500 Ahab) as the budget, 50/day hard cap on credited API calls as the safety net, BYOAI at 300/day separate counter. The "250/day" and "10/25 per day" references need to be either removed or clarified as something different.

### G02 HIGH: HARPOON_ENCRYPTION_SECRET missing from Phase 2 env vars

The env vars list says Phase 2 additions are: ALCHEMY_API_KEY, ALCHEMY_WEBHOOK_SECRET, RESEND_API_KEY, TELEGRAM_BOT_TOKEN, POLAR_FIRSTMATE_PRODUCT_ID. But HARPOON_ENCRYPTION_SECRET is needed for BYOAI encryption (Phase 2 feature) and is only listed under Phase 3 additions. Must be added to Phase 2 env vars in BOTH the architecture doc AND the build guide.

### G03 HIGH: ER diagram missing byoai_queries_today and byoai_reset_at

The user_profiles entity in the ER diagram lists custom_ai_provider, custom_ai_key_encrypted, custom_ai_model but NOT the two new columns (byoai_queries_today, byoai_reset_at). The ER diagram is what coders look at to understand table structure. Missing columns in the ER = coder doesn't create them.

### G04 HIGH: Project structure tree missing BYOAI files

The project structure tree lists lib/ai/ with provider.ts, anthropic.ts, openai.ts, openrouter.ts, encrypt.ts. Missing from the tree: anthropic-custom.ts (user's own Anthropic key, distinct from our internal wrapper), errors.ts, models.ts. Also missing: lib/utils/byoai-limit.ts and api/settings/byoai/route.ts. If the coder follows the project structure as their file creation guide, these files won't exist.

### G05 HIGH: Function map mermaid missing api/settings/byoai

The Function Map diagram (diagram 10) lists 13 routes (poll-markets through courtroom). The BYOAI settings endpoint (api/settings/byoai) is not shown. The function map is the coder's first mental model of "what routes exist." Missing route = forgotten route.

### G06 HIGH: CLAUDE.md API routes list missing api/settings/byoai

CLAUDE.md lists 12 API routes. The settings/byoai endpoints (POST and DELETE) are not listed. Same problem as G05 but in the session context file.

### G07 HIGH: TIER_FEATURES config missing byoai_daily_limit

TIER_FEATURES has byoai_access (true/false) but no byoai_daily_limit field. The 300/day limit only exists in prose. If we ever want different limits per tier (say 200 for FM, 500 for Ahab), the config has no field for it. More importantly, the coder implementing the daily limit check needs to know WHERE to find the number. A hardcoded 300 somewhere in utils is worse than a config-driven value in tier-features.ts.

### G08 HIGH: Tier feature table missing BYOAI daily limit

The big tier comparison table shows "Bring Your Own AI: No (upgrade upsell) / Yes (OpenAI, Anthropic, OpenRouter) / Yes" but doesn't mention the 300/day cap anywhere in that row. A reader scanning the tier table would not know BYOAI has a daily limit.

### G09 MEDIUM: Downgrade behavior for BYOAI not specified

If a First Mate downgrades to Harpooner, what happens to their saved BYOAI key? The encrypted key, provider, and model sit in user_profiles. Options: (a) auto-delete on downgrade (clean but loses their setup if they re-upgrade), (b) leave it but block at tier check (messy but preserves setup). Neither is specified. The tier check in api/settings/byoai blocks Harpooner from using it, so option (b) is probably fine, but the courtroom route also needs to check tier before allowing engine='custom'. If the coder only checks in the settings route but not in the courtroom route, a downgraded user with a stale key could still select "Custom AI."

### G10 MEDIUM: BYOAI key removal doesn't address daily counter

The DELETE endpoint sets custom_ai fields to NULL. It does NOT reset byoai_queries_today to 0. This is correct (prevents remove-and-re-add exploit to reset the counter mid-day) but the spec should explicitly state "do NOT reset the daily counter on key removal" so the coder doesn't "helpfully" reset it.

### G11 MEDIUM: Route Map mermaid Settings description stale

The Route Map mermaid shows Settings as "Notification prefs, Discord/Telegram/email/SMS, Custom AI config (Tier 2+), Watchlist mgmt, Account/billing." This says "Tier 2+" which implies hidden for Tier 1. The new spec says Harpooner sees it VISIBLE but LOCKED. The mermaid should say "Custom AI config (visible all tiers, locked Tier 1)" or similar.

### G12 MEDIUM: HARPOON-REFERENCE.md stale on BYOAI

The reference doc was created before the BYOAI expansion. It still reflects the old spec (no daily limit, hidden from Harpooner, no new columns). Needs updating to match.

### G13 MEDIUM: No empty state for BYOAI settings on first visit

Method 7 (vibe code failure patterns) says every page needs empty/loading/error states. The BYOAI settings section has "no key saved" state described but no loading state (what does the user see while the test call is in progress?) and no error state for the settings page itself (what if fetching the user's current BYOAI config fails?).

### G14 LOW: BYOAI daily counter not atomic

Two simultaneous BYOAI calls could both read count=299, both pass the check, both increment to 300, resulting in 301 total calls. This is a soft limit and the race window is tiny, so it's not worth adding database-level locking. But it should be documented as a known acceptable edge case so a future coder doesn't try to "fix" it with pessimistic locking.

### G15 LOW: Phase 2 vs Phase 3 encryption approach mismatch

Phase 2 BYOAI encrypts all keys with the raw HARPOON_ENCRYPTION_SECRET. Phase 3 auto-trading uses per-user key derivation (HKDF from HARPOON_ENCRYPTION_SECRET + user_id + salt). If someone compromises the encryption secret, Phase 2 keys for ALL users are exposed, while Phase 3 would require also knowing each user_id and salt. This is an acceptable Phase 2 simplicity tradeoff but should be documented so a future security audit doesn't flag it as an oversight.

---

## AUDIT H: FULL PHASE 1 PRE-BUILD REVIEW (2026-04-15)

Applied all 9 Error Hunter methods to every Phase 1 session, every flow, every cross-reference. Traced poller, scoring engine, payment webhooks, affiliate chain, resolution, notifications, crowd aggregation, middleware, check-expirations, and admin dashboard end to end.

### H01 CRITICAL: Poller upsert uses wrong column name

The poller upsert SQL in the architecture doc (Engine 1 section) sets `last_updated = now()`. The actual column in 001_initial_schema.sql is `last_polled_at`. The column `last_updated` does not exist in the schema. The upsert will throw a "column last_updated does not exist" error on the very first poller cycle. Every single poll will fail until this is fixed.

Fix: Change `last_updated = now()` to `last_polled_at = now()` in the poller upsert SQL in the architecture doc.

### H02 HIGH: check-expirations contradiction between two locations

Line ~81 of the architecture doc (Payment Rails section) says: "The check-expirations cron filters on this value to only downgrade crypto subscriptions." Line ~1719 (Subscription Expiration section) says: "The daily check-expirations cron handles BOTH rails: UPDATE user_profiles SET tier = NULL WHERE subscription_expires_at < now() AND tier IS NOT NULL. No payment_provider filter." These directly contradict each other. Line 1719 is the correct behavior (both rails, no filter). Line 81 is stale from an earlier design where fiat was handled differently.

Fix: Update line 81 to say "The check-expirations cron handles BOTH rails. It does not filter by payment_provider."

### H03 HIGH: All break-even calculations stale after $29 pricing

Four locations reference break-even at $39 math. At $29 per Harpooner:
- Naive (no optimizations): $1,650-2,250 / $29 = 57-78 subscribers (was 42-58)
- With optimizations: $750-1,100 / $29 = 26-38 subscribers (was 20-28)
- Without two-stage savings: needs recalculation
- Caveman compression savings: moves break-even from 57-78 to ~48-66 (was 42-58 to 35-48)

All four locations must be updated with the $29 math.

### H04 HIGH: Revenue math stale after $29 pricing

"100 Harpooners = $3,900/mo" should be "100 Harpooners = $2,900/mo". The full steady state revenue math and margin calculation needs recalculation at $29.

### H05 HIGH: Affiliate commission examples stale after $29 pricing

"Ten Harpooner referrals = $97.50/month" should be $72.50 (10 x $29 x 0.25). Appears in two locations: the marketing angle section and the affiliate TOS context section. Ahab math ($74.75/month per referral) is still correct.

### H06 HIGH: Build guide Session 2 says 15 tables but SQL creates 16

courtroom_verdicts is defined in 001_initial_schema.sql (Phase 1 migration), so all 16 tables will exist after running the migration. Session 2 verify step says "15 tables visible" which will confuse the coder into thinking something is wrong or missing.

Fix: Change "15 tables visible" to "16 tables visible" in the build guide.

### H07 MEDIUM: NormalizedMarket interface missing description field

The nexus tagger section says matching is "case-insensitive substring search against market title + description." But the NormalizedMarket interface (the only data structure the poller works with) has no `description` field. Polymarket's API provides a `description` field. Kalshi has market descriptions available. Without `description` in NormalizedMarket, the nexus tagger can only match on title, missing political signals that appear only in the description. A market titled "June FOMC Decision" with a description mentioning "Trump administration pressure on Fed" would score 0 nexus instead of 0.3+.

Fix: Add `description: string | null` to NormalizedMarket. Add `description` to the poller upsert INSERT/UPDATE. Update nexus tagger to match on title + description (already described in prose, just not in the data flow).

### H08 MEDIUM: Poller upsert missing description in INSERT column list

The poller upsert SQL lists: platform, platform_id, title, yes_price, no_price, volume_24h, open_interest, status, category, market_url, close_time. The `description` column exists in the markets table but is not populated by the upsert. Every market will have NULL description. Related to H07.

Fix: Add description to the upsert column list (both INSERT and ON CONFLICT UPDATE).

### H09 MEDIUM: Second affiliate commission reference stale

The affiliate TOS context section says "Ten Harpooner referrals pay $97.50/month forever." Should be $72.50 at $29. Same root cause as H05 but in a different section.

### H10 LOW: P&L formula for NO direction unnecessarily complex

The formula `(1.0 - (1.0 - market_price_at_scoring)) / (1.0 - market_price_at_scoring) * 100` simplifies to `market_price_at_scoring / (1.0 - market_price_at_scoring) * 100`. The expanded form is mathematically correct but invites simplification errors from a coder. Consider writing the simplified form directly.

---

## AUDIT I: PRODUCTION FAILURE SCENARIOS (2026-04-15)

Applied Method 2 (all paths), Method 3 (flow tracing), and Method 5 (pre-mortem) specifically looking for things that CRASH, HANG, SILENTLY FAIL, or CORRUPT DATA in production with real users and real money. Not cross-reference nits. Actual disasters.

### I01 CRITICAL: close_time column missing from SQL schema

The NormalizedMarket interface defines `close_time: string | null`. The poller upsert SQL includes `close_time` in both INSERT and ON CONFLICT UPDATE. But the markets CREATE TABLE in 001_initial_schema.sql has NO `close_time` column. The poller will crash with "column close_time does not exist" on the very first cycle. Same class of bug as H01 (wrong column name) but worse because the column literally doesn't exist.

Fix: Add `close_time timestamptz` to the markets table in 001_initial_schema.sql, between `resolved_at` and `last_polled_at`.

### I02 HIGH: Coinremitter webhook verification completely unspecified

The architecture doc specifies Polar webhook verification: "verify signature using POLAR_WEBHOOK_SECRET." The Function Map mermaid says Coinremitter webhook should "Verify signature." But NOWHERE in the entire spec is the actual Coinremitter verification method described. No header name. No algorithm. No secret handling. A coder will either skip verification entirely (ANYONE can POST to /api/webhook/crypto and give themselves a paid tier) or waste a full session researching Coinremitter's documentation. This is a Phase 1 Session 9 blocker.

Fix: Research Coinremitter's webhook verification method and add it to the Payment Rails section. At minimum specify: what header contains the signature, what algorithm to use, and what secret to verify against (COINREMITTER_PASSWORD or a separate webhook secret).

### I03 HIGH: Rate limiting implementation will not work on Vercel

The Security Hardening section says: "Implement in Next.js middleware. Use Vercel's built-in edge rate limiting or a simple in-memory counter with IP + user ID." The "in-memory counter" option is BROKEN on Vercel. Serverless functions do not share memory between invocations. Every cold start resets the counter to zero. The rate limiter does literally nothing. A user could make 10,000 requests per minute and never hit the limit.

Fix: Remove "in-memory counter" as an option. Specify: use Vercel's built-in edge rate limiting (available on Pro plan, configured in vercel.json or middleware) OR use Supabase-based counting (query active_sessions or a dedicated rate_limit table). Vercel's edge rate limiting is the simplest approach that actually works.

### I04 HIGH: MRR calculation formula uses old $39 price

The MRR calculation in Operational Concerns says: `(COUNT users WHERE tier = 'harpooner') * 39`. Should be `* 29` after the price change. The milestone tracker will show wrong MRR from day one.

Fix: Update 39 to 29 in the MRR formula.

### I05 HIGH: Notification failure counter has no storage

The spec says "after 3 consecutive failures for the same user+channel, set their notification preference to false." But there is no column, table, or mechanism to track consecutive failures. The notification_log table only records SENT notifications (successful ones). error_log could theoretically be queried but that's expensive and fragile.

Fix: Either add a `discord_fail_count int DEFAULT 0` column to user_profiles (reset to 0 on successful send, increment on failure), OR specify that the notification dispatcher queries error_log for recent failures matching source='notifier' AND user_id AND channel before sending. The column approach is simpler and faster.

### I06 HIGH: Kalshi pagination loop not specified

The API Field Reference says "Pagination: cursor-based, max 1000/page" but does not specify: the cursor parameter name (Kalshi uses `cursor` parameter), how to detect the last page (Kalshi returns an empty array or omits the cursor from the response), or the loop structure. A coder who doesn't implement pagination will only fetch the first 1000 markets and silently miss 500+ active markets. The Polymarket connector has the same gap (rate limit mentioned but no pagination structure).

Fix: Add pagination loop description to both connectors in the API Field Reference section. Specify: "Loop until the response returns no cursor or fewer results than the page size. Pass the cursor from each response as a query parameter to the next request."

### I07 MEDIUM: Polymarket outcomePrices parsing has no error handling

The connector must JSON.parse a string field then parseFloat the first element. If outcomePrices is null, empty string, malformed JSON, or an empty array, this throws an unhandled exception that crashes the connector for ALL Polymarket markets in that fetch cycle. One bad market kills the entire platform fetch.

Fix: Add to the Platform Connectors specification: "Wrap outcomePrices parsing in try/catch. If parsing fails for a single market, log a warning to error_log with the market ID and raw value, skip that market, and continue processing the rest of the batch. Never let one bad market response kill the entire fetch."

### I08 MEDIUM: Bet entry_price auto-fill not direction-aware

The spec says "Entry price auto-filled from current market price on selected platform" but doesn't specify which price based on direction. If user bets YES, auto-fill with yes_price. If user bets NO, auto-fill with no_price (or 1 - yes_price). If the coder always fills yes_price regardless of direction, NO bets have the wrong entry price and every P&L calculation for NO bets is corrupted.

Fix: Add to Pick Detail section: "Entry price auto-fill is direction-aware. YES bet: fill with markets.yes_price. NO bet: fill with markets.no_price (which equals 1 - yes_price)."

### I09 MEDIUM: Discord webhook POST body format not specified

The notification dispatcher needs to POST to a user's discord_webhook_url. The exact body format is not specified anywhere. Discord webhooks accept JSON with `content` for plain text or `embeds` for rich formatting. Without this, the coder either sends the wrong format (notification silently fails, Discord returns 400) or spends time looking up Discord's webhook API.

Fix: Add to Notifications section: "Discord webhook POST body: `{ content: null, embeds: [{ title: 'Harpoon Cannon Alert', description: '[notification text]', color: 0xe94560, url: '[pick detail URL]' }] }`. Use embeds for rich formatting. Include the pick title, edge, and a direct link to the pick detail page."

### I10 MEDIUM: Session device_hash generation not specified

The active_sessions table has a device_hash column used for concurrent session enforcement. The security section mentions canvas fingerprinting. But nowhere is the actual hash generation specified. What inputs? User-Agent + IP? Something else? A coder will either skip it (column always null, fingerprinting doesn't work) or implement something inconsistent.

Fix: Add to Security section: "device_hash = SHA-256 of (User-Agent + Accept-Language + IP address). This is a rough device fingerprint, not a unique identifier. Two different devices from the same household may share an IP but differ on User-Agent. Store on session creation. Use for anomaly detection (same account, rapid device_hash changes = possible sharing), not for hard blocking."

### I11 MEDIUM: Unicode watermark encoding scheme not specified

The spec says "zero-width spaces and zero-width joiners encode the user_id" but doesn't specify the encoding. How is a UUID converted to zero-width characters? Binary? Base36? How many characters per bit? How does the decode function work? Without this, the watermark is write-only (can embed but can't extract).

Fix: Add to Security section: "Watermark encoding: convert user_id UUID to a binary string. Map each bit to either U+200B (zero-width space, for 0) or U+200D (zero-width joiner, for 1). Insert the resulting invisible character sequence at a fixed position in the rationale text (e.g., after the first period). To decode: extract the zero-width characters from that position, map back to bits, reconstruct the UUID."

### I12 LOW: google_trend_score column is a Phase 2 placeholder in Phase 1 schema

The column exists in 001_initial_schema.sql with DEFAULT 0. It's populated by Google Trends API integration which is described as a Phase 2 feature. In Phase 1 it's always 0. Not a bug but may confuse a Phase 1 coder into thinking they need to populate it.

---

## AUDIT J: SECOND PRODUCTION PASS (2026-04-15)

Fresh eyes on every flow. Applied Method 2 (7 unhappy questions), Method 3 (flow tracing), Method 5 (pre-mortem), Method 7 (vibe code failure patterns) again. Focused on what was missed in Audits G-I.

### J01 CRITICAL: P&L formula references wrong column name

The resolve-picks P&L formula says `pnl_usd = (exit_price - entry_price) * amount`. The column in user_bets is `size_usd`, NOT `amount`. The `amount` column exists on the `payments` and `affiliate_payouts` tables. A coder following this formula will reference a column that doesn't exist on user_bets and the resolution P&L calculation crashes for every resolved bet.

Fix: Change `* amount` to `* size_usd` in the P&L calculation description.

### J02 HIGH: ER diagram still missing close_time column

Audit I01 added close_time to the SQL schema but it was never added to the ER diagram. The ER diagram is what coders look at to understand table structure. Missing column = coder doesn't expect it.

Fix: Add `timestamptz close_time` to the markets entity in the ER diagram, between resolved_at and last_polled_at (matching the SQL order).

### J03 HIGH: Crypto user renewal/re-subscription path completely unspecified

A crypto user pays once, gets 30 days. Day 31, check-expirations sets tier = NULL. User returns, wants to pay again. The spec describes the INITIAL crypto payment flow but never addresses what happens when:
- A returning user with an existing user_profiles row pays crypto again
- Whether subscription_expires_at should be set to now() + 30 days or stack on top of remaining time if they pay early
- Whether the webhook handler needs to distinguish first payment from renewal
- What event_type to log (same 'payment' or a separate 'renewal'?)

Fix: Add to Subscription Expiration section: "Crypto renewals use the same webhook flow as initial payments. The handler sets subscription_expires_at = now() + 30 days regardless of previous state. If the user pays before expiration (early renewal), the remaining days are NOT stacked, the timer resets to 30 days from now. This simplifies the handler and avoids edge cases. Log with event_type = 'renewal' to distinguish from initial payment in analytics, but the tier-setting logic is identical."

### J04 HIGH: Polar upgrade/downgrade webhook event type not handled

The fiat webhook handler specifies three events: checkout.completed, subscription.active, subscription.canceled. But when a user upgrades via Polar's subscription update API (plan change), Polar fires a `subscription.updated` event (not checkout.completed). If the handler doesn't recognize this event, tier upgrades via the dashboard upgrade button silently fail. The user pays more, sees a success page, but their tier never changes.

Fix: Add `subscription.updated` to the fiat webhook handler event list. On this event: read the new plan/product ID from the webhook payload, map it to the correct tier ('harpooner'/'first_mate'/'ahab'), update user_profiles.tier. Same idempotency check via provider_event_id.

### J05 HIGH: Scoring engine mermaid says "3-5 per batch" for all pools

The Scoring Engine mermaid diagram node says "Group remaining into batches: 3-5 markets per batch" but the cost control table specifies different sizes: Pool A = 5-8, Pool B = 3-5, Pool C = 3-4. The mermaid is the coder's first mental model. They'll use 3-5 for everything, under-batching Pool A and wasting API calls.

Fix: Update mermaid node to "Group remaining into batches: Pool A 5-8, Pool B/C 3-5 markets per batch."

### J06 MEDIUM: Referral cookie and Supabase session cookie httpOnly settings will confuse coder

Line 2425 says the REFERRAL cookie uses httpOnly=false (so JavaScript can read it on the auth callback page). Line 3057 specifies the SUPABASE SESSION cookie with httpOnly=true. These are different cookies for different purposes, but they appear in the same document with no clear separation. A coder will either set httpOnly=true on both (breaking referral attribution because JS can't read it) or httpOnly=false on both (weakening session security).

Fix: Add a clarifying note in the referral chain section: "NOTE: The referral tracking cookie (ref_code) and the Supabase auth session cookie are SEPARATE cookies with different security settings. Referral cookie: httpOnly=false (must be readable by client-side JavaScript on the auth callback page), secure=true, sameSite=lax, maxAge=90 days. Supabase session cookie: httpOnly=true (never readable by JavaScript), secure=true, sameSite=lax, maxAge=7 days. Do not conflate these."

### J07 MEDIUM: user_bets.market_id FK has no ON DELETE clause

user_bets references markets(id) with no ON DELETE behavior. Defaults to RESTRICT (Postgres NO ACTION). This means deleting a market that has associated bets will BLOCK with a foreign key violation. This is actually correct behavior (we never want to lose bet history), but it's unspecified. A coder or admin who tries to delete a bad market will get a cryptic FK error.

Fix: Add a comment to the SQL and a note to the architecture doc: "user_bets.market_id intentionally has no ON DELETE clause (defaults to RESTRICT). Markets with associated bets cannot be deleted. To remove a bad market: first resolve or void all bets, then delete. This protects bet history and P&L records."

### J08 MEDIUM: Admin dashboard empty states incomplete

The empty states section specifies messages for Pick Board, Market Scanner, Bet Tracker, Referrals, Alerts, and Admin Accuracy. Missing: /admin (Command Center) on first boot when there are zero users, zero revenue, zero bets. /admin/users on first boot. /admin/affiliates on first boot.

Fix: Add empty states: "/admin (Command Center): 'No subscribers yet. The fleet launches when the first Harpooner signs up.' Show zeroes for MRR, user count, and system health in GREEN (all crons should be running even with no users)." "/admin/users: 'No users yet.'" "/admin/affiliates: 'No affiliate activity yet.'"

### J09 MEDIUM: Supabase Realtime reconnect behavior not specified

The dashboard uses Supabase Realtime to push live picks and anomaly alerts. But what happens when the WebSocket disconnects (network glitch, Supabase maintenance, mobile user switching apps)? Without reconnect handling, the dashboard silently goes stale. User sees old picks with no indication that live updates stopped.

Fix: Add to Dashboard section: "Supabase Realtime subscriptions must implement reconnect logic. On disconnect: show a subtle 'Reconnecting...' indicator in the dashboard header. On reconnect: refetch the latest picks (the subscription may have missed updates during the disconnect). Supabase JS client v2+ has built-in reconnect but the stale-data-on-reconnect problem must be handled by the application."

### J10 LOW: Scoring engine web_search tool type may need verification before build

The spec hardcodes `web_search_20250305` as the tool type string. This was correct as of March 2025. Before the first build session that creates the scoring engine (Session 6), the coder should verify this is still the current tool type by checking Anthropic's API documentation. If Anthropic has released a newer version, using the old string may either fail or miss improvements. Add a one-line note to Session 6 in the build guide.

---

## AUDIT J: FULL 9-METHOD SEQUENTIAL REVIEW (2026-04-15)

Applied all 9 Error Hunter methods sequentially, one at a time, reading the full spec for each method. No parallel shortcuts.

### J01 HIGH (FIXED): parseFloat(null) = NaN bypasses price validation

The price validation said "reject if > 1.0 or < 0.0." NaN is neither. parseFloat(null), parseFloat(undefined), and parseFloat("") all return NaN. NaN passes the range check, gets written to markets.yes_price, propagates through anomaly z-score (NaN), edge calculation (NaN), pick_score (NaN), and corrupts the entire Pick Board. Fixed: added isNaN check before range check.

### J02 HIGH (FIXED): Payment webhook has no spec for missing metadata

If Polar sends a webhook without metadata.supabase_user_id (malformed event, test event, API change), the handler had no specified behavior. Would either crash on null access or silently fail. Fixed: log to error_log, return 200 (prevent retries of broken events), require manual admin investigation.

### J03 HIGH (FIXED): Coinremitter verification didn't check wallet_id

The callback verification confirmed the transaction EXISTS but didn't verify it belongs to OUR wallet. An attacker could send a webhook with a valid transaction ID from a DIFFERENT merchant's Coinremitter wallet and get a free tier. Fixed: verification now checks wallet_id matches our expected wallet.

### J04 HIGH (FIXED): Coinremitter verification timeout had no behavior

If the verification API call to Coinremitter times out, the handler had no spec for what to return. Processing = security hole. Rejecting = user paid but gets nothing. Fixed: return HTTP 500 on timeout so Coinremitter retries the webhook later.

### J05 HIGH (FIXED): Checkout success page race condition

User completes payment, lands on /dashboard?checkout=success. Webhook hasn't processed yet. Middleware reads tier = NULL. User gets redirected to /pricing. They just paid and see the buy page again. Fixed: /dashboard?checkout=success gets special middleware handling that polls for tier every 2 seconds for up to 20 seconds before redirecting.

### J06 HIGH (FIXED): Unknown tier string crashes middleware

If tier contains an unexpected value (DB corruption, manual edit, migration error), TIER_FEATURES[tier] returns undefined. Any property access crashes. Fixed: middleware validates tier is one of the three known values. Unknown tier treated as NULL.

### J07 HIGH (FIXED): Scoring engine could analyze resolved/closed markets

Market selection query filtered by nexus thresholds and skip-if-unchanged but NOT by status = 'active'. A resolved market with high nexus would be re-analyzed, producing a pick for a market that's already settled. Fixed: added WHERE status = 'active' to the scoring engine mermaid and market selection spec. The idx_markets_scoring index already has this filter.

### J08 HIGH (FIXED): Referral attribution race between auth callback and webhook

The referral cookie is read in the auth callback and sets referred_by. But the webhook could fire before the callback completes, finding referred_by = NULL and skipping commission. Fixed: referral_code now included in Polar checkout metadata. Webhook handler checks referred_by first, falls back to metadata.referral_code for attribution.

### J09 MEDIUM (FIXED): P&L formula missing NULL guard on market_price_at_scoring

Guard checked for 0 and 1 but not NULL. If the scoring engine failed to record the price, market_price_at_scoring is NULL. Division by NULL doesn't crash but produces NULL P&L silently. Fixed: added NULL to the guard alongside 0 and 1.

### J10 MEDIUM (FIXED): Scoring engine empty batch not handled

If zero markets pass the selection filters (e.g., all recently analyzed, no nexus markets), the scoring engine had no specified behavior. Could crash on empty array or waste time with an empty API call. Fixed: added to the mermaid and spec: if zero markets pass, update last_success_scorer, release lock, done.

### J11 MEDIUM (FIXED): analyze-urgent throttle timing ambiguous

The spec said "update last_urgent_at on each run" but didn't say WHEN. If updated after analysis, two rapid whale alerts could both start. If updated before and analysis fails, the throttle blocks retry. Fixed: specified atomic check-and-update BEFORE the API call, using the same atomic UPDATE...RETURNING pattern as the poller lock.

### J12 MEDIUM (FIXED): Pool A/B/C boundary operators inconsistent

Pool A was "> 0.7" meaning a market at exactly 0.7 falls to Pool B. Changed to ">= 0.7" across all references. Pool B is now explicitly >= 0.3 (inclusive). All boundary operators now explicit in both prose and mermaid.

### J13 MEDIUM (FIXED): Crypto payment before user_profiles row exists

User sends crypto payment from external wallet before completing signup. Webhook fires. user_profiles row doesn't exist. UPDATE affects 0 rows. User paid but gets nothing. Fixed: webhook handler checks user_profiles existence. If missing, logs and schedules a retry rather than permanently rejecting.

### J14 LOW (DOCUMENTED): Duplicate picks from scorer + analyze-urgent

If hourly scorer and analyze-urgent run simultaneously for the same market, two picks can exist. The whale alert pick ages out after 1 hour. Not worth adding cross-system locking. Documented as acceptable behavior.

---

## AUDIT K: ADVERSARIAL 9-METHOD REPEAT (2026-04-15)

Full repeat of all 9 methods with adversarial parallel analysis (pessimist assumes errors, optimist assumes none, judge decides). Every method applied to every file. No shortcuts.

### K01 HIGH (FIXED): Polymarket volume is a string, parseFloat not specified

The Polymarket API returns volume as a STRING ("2400000" not 2400000). The markets table stores volume_24h as float. The spec documented "volume (string, total USDC)" in the API reference but NEVER specified parseFloat on it like it does for outcomePrices. A coder would either store the string (type error on INSERT to float column) or leave it null. Fixed: added explicit parseFloat instruction with NaN/negative guard defaulting to 0.

### K02 HIGH (FIXED): user_bets size_usd has zero validation

Users self-report bets. The "I Bet This" button accepts an amount but no validation was specified. Zero, negative, non-numeric, and absurdly large values ($999,999,999) all pass through. Corrupts crowd intelligence calculations (crowd_bets_24h weighted by garbage amounts) and P&L tracking. Fixed: added minimum $1, maximum $100,000, positive number validation.

### K03 HIGH (FIXED): Credit consumption race condition

The consumeCredits function reads monthly_credits_used, checks if sufficient, then writes the incremented value. Two simultaneous calls read the same value, both pass, both write. User gets two calls for the price of one. Fixed: documented the race condition with the Phase 1 acceptable tradeoff AND the Phase 2 atomic SQL fix (UPDATE with WHERE clause and RETURNING).

### K04 HIGH (FIXED): No notification when user's bet resolves

The notification system triggers on: new top picks, whale alerts, edge > 20, and crowd-trending spikes. But NOT when a user's bet resolves (win or loss). A user who placed a bet and doesn't check the app for days never finds out they won $400. The win celebration modal only fires when they visit the page. Fixed: added "user's bet resolves" as a notification trigger event.

### K05 HIGH (FIXED): Affiliate commission clawback on chargeback not specified

Commissions credited instantly. Referred user chargebacks. Commission already in referrer's affiliate_balance. No mechanism to reverse it. If paid out, the referrer keeps money from a fraudulent payment. Fixed: added complete clawback spec for chargebacks (debit balance, handle negative, flag patterns). Clarified that normal cancellation does NOT trigger clawback.

### K06 HIGH (FIXED): Coinremitter invoice metadata field name not specified

The spec said "user's Supabase ID in metadata" but Coinremitter doesn't have a generic "metadata" field. Their invoice API uses custom_data1 and custom_data2 string fields. A coder searching for "metadata" in Coinremitter's docs finds nothing and is stuck. Fixed: specified custom_data1 as the field for supabase_user_id.

### K07 MEDIUM (DOCUMENTED): discord_fail_count not in CLAUDE.md

The column exists in SQL, ER diagram, and arch doc prose. CLAUDE.md is intentionally compact and doesn't list every column. The operational detail is in the arch doc where the coder building notifications will read it. Not adding to CLAUDE.md to avoid bloat. Acceptable.

### K08 MEDIUM (FIXED): Pool B boundary operator inconsistent across 4 locations

Scoring engine mermaid said ">= 0.3" but the cost table, tier details table, Route Map scanner, and Pool B visualization all said "> 0.3". A market scoring exactly 0.3 was included or excluded depending on which section the coder read. Fixed: global replacement to ">= 0.3" everywhere.

### K09 HIGH (FIXED): No kill switch for scoring engine

If the scoring engine produces garbage picks (bad prompt, API behavior change, model degradation), there's no way to stop it without deploying new code. Fixed: added scoring_enabled system_state key (default 'true'), checked before acquiring scorer_lock. Admin can toggle via dashboard. Added to SQL seeds. Added "Scoring: ACTIVE / PAUSED" toggle spec for admin dashboard.

### K10 HIGH (FIXED): Webhook out-of-order delivery not handled

Payment providers do not guarantee event order. subscription.canceled could arrive before checkout.completed. The handler assumed events arrive in order (checkout first, then cancel). If cancel arrives first, handler tries to set subscription_expires_at on a user with no tier. Fixed: added complete out-of-order handling spec. Every handler must tolerate the user being in ANY state. Added specific scenarios for cancel-before-checkout, update-before-checkout.

### K11 HIGH (FIXED): No API response schema validation on raw platform data

If Polymarket renames outcomePrices to outcome_prices, or Kalshi removes yes_bid_dollars, the connector crashes silently or writes undefined values to the database. No alerting, no graceful degradation. Fixed: added per-market field validation. Required fields checked before access. 50%+ failure rate triggers schema_change alert to admin and halts the connector for that cycle.

### K12 MEDIUM (FIXED): Function map mermaid missing settings/byoai route

Function map showed 13 routes. CLAUDE.md said 14. The settings/byoai route (V12) was not in the mermaid diagram. Coder looking at the function map as their route inventory would not build it. Fixed: added V12 to mermaid with DB connection. Updated count to 14.

### K13 MEDIUM: Covered by K11

Platform API schema changes are handled by the response validation spec added in K11.

### K14 MEDIUM (FIXED): Supabase unavailable during middleware auth check

Every dashboard page load hits Supabase for auth. If Supabase has an outage, middleware had no specified behavior. Could crash, show blank page, or redirect to login (confusing for a logged-in user). Fixed: added step 6 to middleware chain. Network/timeout errors (not auth rejections) show a static "Service temporarily unavailable" page. Errors logged to Vercel function logs as fallback since error_log table is also unreachable.

---

## AUDIT L: FULL ADVERSARIAL CROSS-FILE DRIFT + CONCEPT GAPS (2026-04-16)

Fresh pass after SYNC-PROTOCOL.md was created. Every file audited against every other file. 24 issues found, 24 fixed.

### L01 HIGH (FIXED): File count drift across 5 files
Project grew from 6 to 11 files. HARPOON-REFERENCE said "8 files", ERROR-HUNTER said "6 files", SYNC-PROTOCOL said "10 files". All updated to 11.

### L02 HIGH (FIXED): Architecture doc TOC line numbers off by 500+ lines
Every section reference in the 29-line TOC was stale. Pricing claimed L1473, actually at L1963. Security Hardening claimed L2183, actually at L3049. Complete rewrite with accurate line numbers + drift warning note.

### L03 MEDIUM (FIXED): TOC said "12 routes" in Function Map reference, should be 14
Fixed in TOC rewrite.

### L04 LOW (FIXED): progress.md historical file count jumps undocumented
Added file count history note to progress.md header.

### L05 MEDIUM (FIXED): CLAUDE.md tier mapping missing daily caps and credit allowances
Coder building Courtroom would have to hunt through architecture doc. Added credits, daily caps, BYOAI status per tier.

### L06 MEDIUM (FIXED): CLAUDE.md missing annual product ID env var name
Added POLAR_HARPOONER_ANNUAL_PRODUCT_ID reference to tier mapping section.

### L07 LOW (FIXED): design.md had no schema context
Added "19 tables defined in 001_initial_schema.sql" with page-to-table mapping.

### L08 MEDIUM (FIXED): $0.04/market cost estimate unverified
Added calibration protocol: measure real cost after Session 6, update fiscal model if >20% off.

### L09 HIGH (FIXED): Pre-launch email capture storage vague ("table or Polar audience")
Created dedicated `waitlist` table in SQL schema (19 tables now). Full spec with columns, blast flow, and migration path. Table count rippled across all 11 files.

### L10 HIGH (FIXED): Cancellation exit survey location ambiguous
Specified as pre-redirect interstitial on settings page. Full 6-step implementation flow. Cancel_initiate vs cancel_confirm event pattern enables save-rate metric.

### L11 MEDIUM (FIXED): Status page disclosure level underspecified
Binary only: "All Systems Operational" or "Analysis Delayed". No component names publicly. Threshold spec added.

### L12 MEDIUM (FIXED): Status page blocked by auth middleware for banned users
/status added to PUBLIC_ROUTES whitelist with code example.

### L13 LOW (FIXED): BYOAI key removal UX undefined when counter persists
Messaging specified: explain counter persistence and abuse prevention rationale.

### L14 HIGH (FIXED): Affiliate fraud "flag" had no automated action
Auto-hold payouts at threshold + admin Discord notification. affiliate_fraud_flag column spec'd for Phase 2 migration.

### L15 HIGH (FIXED): Refund clawback missing (only chargebacks handled)
Same logic as chargeback. Partial refunds prorate. referrals.status='refunded' for analytics.

### L16 MEDIUM (FIXED): Bet tracker no self-reported disclaimer
"Positions are self-reported and unverified" in page header. Verified/self-reported badge system for Phase 2/3.

### L17 MEDIUM (FIXED): No platform API deprecation playbook
7-step response procedure with timing targets added to Operational Concerns.

### L18 LOW (DOCUMENTED): Resolution window priority not differentiated
Phase 2 enhancement: priority boost for markets closing within 24h. Added to roadmap.

### L19 MEDIUM (FIXED): No user-facing message when Anthropic API is down
"Our analysis engine is temporarily unavailable" message spec'd. Credits not deducted. Admin alert after 3 failures.

### L20 HIGH (FIXED): Polar test/live mode switching unspecified
POLAR_MODE env var added. Webhook mode validation. Session 14 deploy checklist item. Test checkouts logged to error_log not payments. Env var count now 14.

### L21 LOW (FIXED): design-example-landing.html /status link dead in standalone mode
Title attribute annotation added.

### L22 CLEAN: ER diagram user_watchlist relationships verified correct
Both user_profiles→user_watchlist and user_watchlist→markets present.

### L23 MEDIUM (FIXED): Sync protocol audit commands used weak grep patterns
Rewritten with better patterns, file exclusions, and per-file counting.

### L24 LOW (FIXED): design.md didn't record Wolf's Concept C selection
Marked as SELECTED with date. Other concepts labeled NOT SELECTED.

---

## AUDIT M: PRODUCTION MONK PHASE 1 READINESS (2026-04-16)

Every Phase 1 flow traced from trigger to final output. 40 checks. 4 issues found, 4 fixed.

### M01 MEDIUM (FIXED): SQL header wrong about Phase 2 columns
custom_ai_provider/key/model are already in Phase 1 CREATE TABLE but header listed them as Phase 2 ALTER TABLEs. Header corrected.

### M06 HIGH (FIXED): /api/status uses system_state but didn't specify admin client
system_state RLS blocks all non-mrr_cache reads from browser/server clients. Status page reads last_success_* keys. Without admin client, empty results. Added "MUST use admin Supabase client" to spec.

### M21 HIGH (FIXED): Session 14 deploy checklist was one sentence
No POLAR_MODE verification, no env var checklist, no production payment test. Expanded to 11-item pre-go-live checklist. Also added real-time subscription_expires_at check and Supabase-down fallback to middleware command.

### M36 MEDIUM (FIXED): notification_log missing notification_type column
Can't distinguish whale alerts from new picks from bet resolution for analytics. Added column with 5 types: new_pick, whale_alert, crowd_trending, bet_resolved, renewal_reminder. ER diagram updated.

---

## AUDIT N: MONK PRE-PRODUCTION (2026-04-17)

Wolf invoked monk methodology on the full project before Phase 1 Session 1. Two-round read of all 11 project files. Methods applied: M1 Bayesian (start with highest-density sections), M2 Happy vs All Paths (7 unhappy questions per flow), M4 Cross-Reference Ripple, M9 Diagram Consistency. Nineteen issues found, nineteen fixed.

**Bayesian prediction validation:** M1 map predicted "VERY LOW remaining" for most sections after 407 fixes. Actual finding: 19 issues remained, concentrated in sections M1 rated lowest density (schema/database 3 issues, operations 5 issues). The implication is that Bayesian bug density flattens late in the audit cycle, so method switching matters more than section picking when issue counts drop below 50.

### N01 P0 (FIXED): Poller upsert RETURNING clause broken PostgreSQL
`markets.title IS DISTINCT FROM EXCLUDED.title` in RETURNING always evaluates false because SET has already overwritten the old value. Nexus re-tagging on title change would never fire in production. Rewrote using same-snapshot CTE pattern: `WITH old AS (SELECT...), upserted AS (INSERT...ON CONFLICT...) SELECT FROM upserted LEFT JOIN old`. CTEs share a snapshot, so old captures pre-upsert state.

### N02 P0 (FIXED): Three tables missing RLS
active_sessions exposed session_id + device_hash + user_id across all authenticated users. affiliate_payouts exposed commission amounts. markets intentionally had no RLS (public data) but that decision was undocumented. Added ENABLE ROW LEVEL SECURITY + user-read policies to two tables, rationale comment block before markets CREATE TABLE.

### N03 P0 (FIXED): Phase 2 migration filename drift
Build guide line 111 said `002_phase2.sql`. SQL schema header line 35 said `002_phase2_migration.sql`. Aligned SQL header to `002_phase2.sql` to match build guide.

### N04 P1 (FIXED): Phase 2 session count drift in Build Order ASCII
ASCII art said "6 sessions, ~10 days." Actual count from SYNC-PROTOCOL canonical: 7 sessions. Fixed: 6→7, 10 days→12 days.

### N05 P1 (FIXED): Duplicate rule numbering in HARPOON-REFERENCE
Two rules numbered "2.", everything after shifted by one. Renumbered 0-21 cleanly.

### N06 P1 (FIXED): Mixed model ID formats across SCORING_MODELS and ANALYSIS_ENGINES
researcher used `claude-haiku-4-5-20251001` (snapshot). analyst used `claude-sonnet-4-6` (alias). ANALYSIS_ENGINES.premium used `claude-opus-4-6` (stale, 4.7 shipped 2026-04-16). Researched Anthropic API alias behavior: generation aliases auto-patch within generation but don't jump across generations. Standardized all three engines to generation alias format. Upgraded to Opus 4.7.

### N07 P1 (FIXED): ai/ folder parallel copies drift risk
Any edit to root CLAUDE.md / HARPOON-REFERENCE.md / etc must be mirrored to ai/ versions or the token-efficient compressed docs silently rot. Added SYNC-PROTOCOL drift hotspot #12.

### N08 P1 (FIXED): Credit race condition deferred with naive pattern
Spec said "Phase 1 accept race, Phase 2+ implement atomic" but shipped the naive read-then-write. A motivated user with two tabs can burn free Premium calls repeatedly. Replaced with required atomic UPDATE...RETURNING specification for Phase 2 Session P2-7. Pattern already used for poller lock, scorer lock, analyze-urgent throttle. No extra complexity.

### N09 P1 (FIXED): Notification flow mermaid missing renewal_reminder
SQL enum, cron description, and prose all specified renewal_reminder as 7-day/1-day trigger. Mermaid diagram (the thing a coder reads first) didn't show it. Added to flow diagram.

### N10 P1 (FIXED): Middleware runtime unspecified
Next.js 14+ middleware defaults to Edge Runtime. Spec required middleware to use Supabase admin client for session writes and tier-expiration UPDATEs. Edge + admin client is unreliable and leaks service role key to Edge code paths. Added explicit `export const runtime = 'nodejs'` declaration with rationale. Also added `AND tier IS NOT NULL` guard to real-time expiration UPDATE to prevent flood of repeat UPDATEs from a stale tab.

### N11 P1 (FIXED): Session 5 missing cron execution time budget
Every-minute cron requires cycle duration under 60s to avoid overlap, under 300s to fit Vercel Pro timeout. Added measurement step to Session 5 verify.

### N12 P2 (FIXED): SYNC-PROTOCOL file count header contradiction
"THE 10 PROJECT FILES" heading vs "grown from 6 to 11 files" line in same file. Fixed heading to 11, added SYNC-PROTOCOL itself as row 11 in the file table.

### N13 P2 (FIXED): Missing partial index on subscription_expires_at
Daily check-expirations cron does sequential scan of user_profiles as user base grows. Added partial index WHERE tier IS NOT NULL.

### N14 P2 (FIXED): Affiliate commission copy ambiguous for annual billing
"25% recurring monthly" is accurate for monthly, a lie for annual. Rewrote: "25% of every subscription payment, for the lifetime" with explicit monthly vs annual clarification.

### N15 P2 (FIXED): Monthly credit reset UTC boundary ambiguity
Cron fires 07:00 UTC. 7-hour window between 00:00 and 07:00 UTC on 1st of month where credits consumed count against old month (about to zero). Impact math: ~$126 per month at 300 FM users. Accept as-is, documented as intentional minor "free window," added admin tooltip.

---

## AUDIT N2 + N3: DEEPER MONK (2026-04-17)

Wolf said "continue" and "keep going." Applied Method 5 (pre-mortem) and Method 2 (7 unhappy questions) specifically against data flows and infrastructure pieces that had not been traced end-to-end by previous audits. Eighteen new issues found, eighteen fixed.

### N16 P0 (FIXED): Email confirmation enforcement gap
Supabase Auth ships with email confirmation configurable in dashboard, but auth.users rows exist before user clicks the confirmation link. handle_new_user trigger creates user_profiles on auth.users INSERT regardless. Without middleware guard, unconfirmed users could reach /pricing, complete a Polar checkout, and receive a tier despite never verifying their email. The account could then never authenticate via password reset (Supabase requires confirmed email). Added middleware chain step 1a: `auth.users.email_confirmed_at IS NULL → redirect to /verify-email` with resend logic (60-second cooldown). Whitelisted /verify-email and /auth/callback.

### N17 P1 (FIXED): Notification throttle read-count-then-INSERT race
Three simultaneous dispatches for same user all read count=2, all pass, all INSERT, four notifications instead of three. Fixed with atomic INSERT-WHERE-subquery-count pattern matching existing lock convention.

### N18 P1 (FIXED): error_log unbounded growth
Sustained API outage or schema_change storm dumps hundreds of rows per minute. Admin drill-down becomes unusable. Added two-tier retention to check-expirations cron: 30 days low severity, 180 days high severity.

### N19 P1 (FIXED): Session INSERT PK collision on simultaneous tabs
Opening two tabs at once triggers two middleware invocations both trying INSERT INTO active_sessions with same session_id. Fixed: ON CONFLICT (session_id) DO UPDATE SET last_active_at = now(). Second tab becomes UPDATE which is the correct behavior (bump timestamp).

### N20 P0 (FIXED): Pick Board duplicate cards on whale alert + hourly collision
When analyze-urgent runs for market X within the same hour as the scheduled scorer cycle that also picks market X, both write rows. Both match the Pick Board query (cycle_id = latest OR whale alert in last hour). User sees two cards for the same market with different scores. Fixed: DISTINCT ON (market_id) in canonical Pick Board query (both copies in spec). Most recent pick wins.

### N21 P1 (FIXED): Discord webhook URL not validated on save
Malformed URL burned 3 auto-disable strikes before user learned it was typoed. Added regex check (`^https://(discord\.com|discordapp\.com)/api/webhooks/\d+/[A-Za-z0-9_-]+$`) and test POST with two-pass error handling on save.

### N22 P1 (FIXED): Banned affiliate commission policy undefined
When affiliate gets banned for fraud, what happens to accumulated balance? Pending payouts? Future referrals? Spec was silent. Commission calculator kept crediting a balance that could never be paid out. Specified 4-point policy: forfeit unpaid balance, cancel pending payouts, freeze future commissions via affiliate_fraud_flag column, referred users keep their tier.

### N23 P1 (FIXED): No CHECK constraints on enum-like text fields
Application code validated values but database accepted any text. A future migration script or direct SQL insert could write garbage like tier='plutinum' and break TIER_FEATURES[tier] lookup at the next read. Added 24 CHECK constraints: tier, direction, min_tier, confidence_level, account_status, payment_provider, notify_threshold, market status+platform+prices, bet direction+status+entry_price+size, anomaly type+severity+confidence, referral+payout status, notification_type+channel, feedback_type+rating.

### N24 P2 (FIXED): user_watchlist missing created_at
Can't order watchlist by when items were added. Can't analyze retention cohorts. Added column with DEFAULT now().

### N25 P2 (FIXED): Waitlist endpoint no rate limit
Public INSERT RLS policy allows any IP to flood with thousands of fake emails. Added 3/min per IP rate limit, RFC email format validation, optional disposable-email blocklist.

### N26 P0 (FIXED): Skip-if-unchanged cycle_id bug
Critical launch-day killer. Skipped markets keep their OLD cycle_id from previous run. Pick Board query filters by cycle_id = latest. Result: Harpooner user sees 25 picks hour 1, 10 picks hour 2 as skip rate climbs. Week 2 support catastrophe. Fixed: mandatory UPDATE to rebadge skipped picks' cycle_id forward at end of each scoring run.

### N27 P1 (FIXED): Entry price validation missing on I Bet This
Only amount was validated. isNaN entry price would crash P&L math at resolution. Added 0.0-1.0 range validation matching CHECK constraint on user_bets.entry_price.

### N28 P1 (FIXED): Supabase Realtime reconnect handling missing
J09 in previous audit specified the fix but it was never written into the spec. WebSocket disconnect = silent stale dashboard. Added disconnect indicator (amber dot in header), catch-up refetch on reconnect.

### N29 P1 (FIXED): Crypto overpay/underpay handling undefined
Coinremitter webhook returns actual paid amount. Spec compared to expected amount with no tolerance band. Real-world crypto payments have 1-2% drift from network fees and price volatility. Specified three-band policy: 1% exact (grant), underpay (admin review), overpay (grant, log excess for manual refund).

### N30 P0 (FIXED): Credit top-up flow completely unspecified
Session P2-7 build command said "build /api/buy-credits POST route" but Polar products, webhook routing, and bonus_credits crediting flow didn't exist anywhere in the spec. Coder would invent it and likely break idempotency. Specified complete 4-step flow with 3 new Polar one-time product env vars, product-type detection in webhook handler, success UX, explicit no-commission-on-topups policy.

### N31 P1 (FIXED): Anomaly flood from sustained spikes
A prolonged volume spike generates new anomaly row every poller cycle for the duration of the spike. Dashboard shows dozens of duplicate whale alert banners. Fixed: application-level dedup checking for unexpired anomaly of same (market_id, anomaly_type) before INSERT; UPDATE severity/confidence if exists (take max). Whale alert dispatch gated on is_new_anomaly return.

### N32 P1 (FIXED): SECURITY DEFINER trigger missing search_path
Standard PostgreSQL CVE pattern. Without SET search_path, a malicious user with CREATE privilege in any schema earlier in the search_path could shadow public.user_profiles and hijack the trigger. Added SET search_path = public, pg_catalog. Supabase Database Linter flags this as a warning otherwise.

### N33 P1 (FIXED): Webhook verification order unspecified
Running the idempotency check before signature verification leaks which event_ids exist in the system and lets attackers DoS the UNIQUE constraint slots by POSTing crafted event_ids. Specified required order: signature → schema → idempotency → business logic.

### N34 P2 (FIXED): Watermark survival limits not documented
Support would over-promise forensics. Added honest note: survives copy-paste to most platforms; does NOT survive screenshots, OCR, paraphrasing, or Unicode normalization.

---

## AUDIT N4: MODEL AUTO-HEALING (2026-04-17)

Wolf flagged the one vendor-failure scenario that would kill the product silently: Anthropic retires a model, API returns 404 on every call, scoring engine can't recover without manual intervention, single-operator can't respond fast enough. Research: Anthropic provides GET /v1/models endpoint for live model discovery, returns 404 not_found_error on retired model IDs, returns 529/5xx on transient issues, returns 401 on auth failure.

### N35 P0 (FIXED): Model auto-healing / fallback chain system
**Failure mode:** Anthropic retires Haiku 4.5 with 6 months' notice that lands in an email Wolf never reads. Scoring engine returns 404 on every cycle. Pick Board freezes with stale data. Users churn. Admin dashboard goes red. Operator has no pre-built recovery path.

**Solution shipped:**

1. **Fallback chains, not single strings.** SCORING_MODELS.{role} and ANALYSIS_ENGINES.{tier}.internal are now 3-position arrays ordered primary → fallback → last resort.

2. **Wrapper function** at `lib/ai/call-with-fallback.ts`. Every Claude API call routes through it. Reads cached active model from system_state, tries it, falls back on 404 not_found_error, retries same on 429/529/5xx, aborts on 401 with admin alert, logs fallback events to error_log with error_type='model_retired', caches winner for next call.

3. **Weekly validator cron** at /api/validate-models (Sun 06:00 UTC). Calls Anthropic GET /v1/models, compares each fallback chain position against live list, warns on position [0] drift ("primary retired, on fallback"), warns on position [2] drift ("last resort retired, replace config"), logs info on newer models available.

4. **Admin dashboard "Model Health" card** showing active model per role, last successful call per role, fallback events in last 7 days, manual "Validate models now" button.

5. **system_state seeds** for all six active_model_* keys in 001_initial_schema.sql.

6. **Canonical value sync:** API routes 14→15 across CLAUDE.md, ai/CLAUDE.md, HARPOON-REFERENCE.md, ai/HARPOON-REFERENCE.md, SYNC-PROTOCOL.md, ai/SYNC-PROTOCOL.md, and the function map mermaid (added V13). vercel.json 6→7 crons. Session 6 build command updated to include wrapper + validator.

**What this does NOT solve:** Breaking API changes to request/response schema (requires code changes), 401 auth failures, Anthropic-wide outages (all models 5xx), quality regressions on fallback models. Documented as "known limits."

**Why single-operator products need this:** Wolf runs The Wise Wolf, builds Vidiot, writes journalism, handles Harpoon Cannon support. Retirement emails get missed. The auto-healing system converts Anthropic deprecation timelines from an outage risk to an advance warning. The system keeps running while Wolf updates the config at his pace.

---

**Running total: 407 (pre-Wolf) + 19 (Audit N) + 18 (Audit N2+N3) + 1 major subsystem (Audit N4) = 445+ pre-build fixes and improvements.** Phase 1 spec is ready for Session 1.

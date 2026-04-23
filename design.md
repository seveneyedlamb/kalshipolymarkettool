# HARPOON CANNON: Design Reference
## The Monk Designer's Blueprint. Updated 2026-04-15.

---

## DESIGN PHILOSOPHY

Harpoon Cannon is a professional intelligence tool built by traders, for traders. The website is the FIRST impression. It must accomplish three things in under five seconds:

1. "This looks expensive." (Trust, credibility, real company)
2. "This is doing something right now." (Live data, real-time feel)
3. "I need this." (Clear value, obvious edge over what they're using)

The Moby Dick theme is the brand's soul, not its skin. Maritime references should feel like a captain's study, not a pirate birthday party. Think: 1800s woodcut engravings as subtle textures, not clip art. The Rockwell Kent illustration style (black ink, parallel lines, dramatic contrast) is the North Star for brand art.

---

## THREE DESIGN CONCEPTS

The monk designer presents three directions. Wolf chooses one (or combines elements). All three share: dark primary background, real-time data animations, and the Moby Dick DNA.

---

### CONCEPT A: "THE CAPTAIN'S STUDY"

**Tone:** Refined. Dark academia meets Wall Street terminal. The feeling of stepping into a wood-paneled study aboard a 19th-century whaling ship, but the maps on the wall update in real time.

**Color palette:**
- Background: Deep navy #0B1120 (almost black, hint of ocean)
- Surface: #131B2E (cards, panels)
- Accent primary: Antique gold #C9A84C (brass instruments, old maps)
- Accent secondary: Weathered copper #B87333 (aging metal)
- Success: Sea green #2DD4A0
- Danger: Signal red #E94560
- Text primary: #E8DCC8 (aged parchment, warm white)
- Text secondary: #8B9CC7 (soft blue-grey)
- Border: #1E293B (barely visible structure)

**Typography:**
- Display / Headlines: Playfair Display (serif, literary, authoritative)
- Body: DM Sans (clean, modern, readable at small sizes)
- Data / Numbers: JetBrains Mono (monospaced, financial precision)

**Art direction:**
- Rockwell Kent-style woodcut illustrations used SPARINGLY as section dividers and empty state art. Not on every surface. Think: a single whale engraving subtly watermarked behind the hero text at 3-5% opacity. A harpoon cross-section as the loading spinner.
- Subtle parchment paper texture overlay at 2-3% opacity on card backgrounds
- Borders use a fine gold line that suggests old map cartography
- Icons are line-style, thin, elegant (Lucide icon set works)

**Landing page hero:**
- Split layout. Left: headline + subhead + CTA. Right: animated live data feed showing markets being analyzed in real time (ticker symbols scrolling, probability scores calculating, "EDGE FOUND: +23 points" appearing with subtle gold glow)
- Behind both: a barely-visible Rockwell Kent whale illustration at 5% opacity, spanning the full width
- The live feed is the product demo. Visitors SEE the analysis happening before they scroll

**Dashboard feel:**
- Dark panels with gold accent borders on active/selected states
- Cards float slightly with subtle box-shadow (depth, not flat)
- Data tables use monospace font for numbers, alternating row backgrounds at 1-2% difference
- The sidebar navigation uses small maritime icons (anchor for home, telescope for market scanner, compass for settings)

**Memorable detail:** When a whale alert fires, the notification card has a subtle wave animation behind it, like sonar rippling outward from the alert icon.

---

### CONCEPT B: "THE INTELLIGENCE BUREAU"

**Tone:** Cold. Technical. Bloomberg terminal meets military intelligence briefing room. No warmth. Pure data. The maritime references are structural, not decorative. The entire UI communicates: we take this dead seriously.

**Color palette:**
- Background: True black #09090B
- Surface: #111113 (barely lighter)
- Accent primary: Arctic blue #38BDF8 (cold, precise, intelligence)
- Accent secondary: Ice white #F0F9FF
- Success: Terminal green #4ADE80
- Danger: Warning red #F43F5E
- Text primary: #FAFAFA (pure contrast)
- Text secondary: #71717A (zinc grey)
- Border: #27272A (zinc-800, grid lines)

**Typography:**
- Display: Instrument Serif (modern editorial, sharp serifs)
- Body: Geist Sans (Vercel's own font, engineered for interfaces)
- Data: Geist Mono (purpose-built for code and data)

**Art direction:**
- NO woodcut illustrations on the interface itself. The brand art lives on the landing page and marketing materials only.
- The dashboard is pure data. Grid lines. Charts. Numbers. No decoration.
- The landing page uses a single dramatic woodcut illustration as the hero background (a whaling ship at full sail, stylized in the Kent tradition, rendered as an SVG with animated wave lines)
- The contrast between the ornate landing page (1800s maritime art) and the clinical dashboard (pure data) is intentional. It says: "We appreciate the heritage, but when money is on the line, we strip it down to what matters."

**Landing page hero:**
- Full-bleed background: animated SVG of ocean waves (simple sine-wave lines, slow movement, dark blue on black). On top: a glowing grid of live market data, numbers ticking, probability bars filling, edge calculations appearing character by character (like a terminal typing).
- Above the grid: headline in Instrument Serif, large, centered. "Everyone else is guessing. You're going to stop."
- The grid IS the hero. No illustration competes with it. The ocean waves behind are texture, not content.

**Dashboard feel:**
- Zero decoration. Dense data. Tight spacing. Every pixel earns its place.
- Tables dominate. Charts are minimal (line charts, no 3D, no gradients).
- Active states use the arctic blue as a left-border accent (4px solid line on the active card/row)
- Whale alerts use a pulsing blue dot, not a splash animation. Clinical.

**Memorable detail:** The comparison chart on the landing page renders as a "classified document" with redacted-style formatting. Competitor names are visible. Their missing features are struck through with a red line. Harpoon Cannon's features glow in arctic blue.

---

### CONCEPT C: "THE NAUTICAL CHART"

**Tone:** Warm but serious. The aesthetic of a hand-drawn nautical chart that comes alive with real-time data. Old cartography meets data visualization. This is the most brand-forward concept, leaning hardest into the Moby Dick aesthetic while remaining functional.

**Color palette:**
- Background: Deep ocean #0A1628 (darker than navy, lighter than black)
- Surface: #111D33 (ocean midnight)
- Accent primary: Compass rose gold #D4A752
- Accent secondary: Whale bone white #F5F0E8
- Success: Phosphorescent green #22D3A0 (bioluminescence)
- Danger: Sunset red #EF4444
- Text primary: #F5F0E8 (warm parchment white)
- Text secondary: #94A3B8 (fog grey)
- Border: #1E3048 (deep water line)

**Typography:**
- Display: EB Garamond (classic, literary, the font Moby Dick SHOULD have been set in)
- Body: Source Sans 3 (clean, neutral, disappears when reading)
- Data: IBM Plex Mono (technical, precise, industrial heritage)

**Art direction:**
- The entire site has a subtle "old chart paper" texture at 2% opacity
- Section dividers are thin ornamental rules (the kind found in 19th-century book design)
- Navigational chart elements appear as design motifs: compass roses as loading spinners, depth soundings as data labels, latitude/longitude grid lines as subtle background patterns on the dashboard
- Woodcut illustrations are used in THREE specific places: (1) landing page hero background, (2) tier pricing cards (small ship icon for Harpooner, officer's wheel for First Mate, captain's chair for Ahab), (3) empty states
- The overall feeling: you're reading a living document. The chart is ancient but the data flowing through it is seconds old.

**Landing page hero:**
- Background: subtle animated nautical chart grid (thin gold lines, very slow drift, suggesting ocean current). At center: a woodcut-style whale silhouette (SVG, not raster) surfacing from below. The whale's body is filled with scrolling data points (market names, probabilities, edges) in a monospace font, as if the data IS the whale.
- Headline overlaid: EB Garamond, large, warm. Below: the animated analysis feed, styled as chart annotations (handwritten-style labels pointing to data points as they appear).
- The whale-as-data metaphor is the hook. Nobody else has this. It's immediately memorable.

**Dashboard feel:**
- Cards have a subtle rounded border with compass-rose gold accent on hover
- The Pick Board feels like a captain's log: picks are entries, each with a date, a market, and the verdict
- The sidebar uses nautical terminology as labels ("Helm" for dashboard, "Chart Room" for market scanner, "Ship's Log" for bet tracker, "Crow's Nest" for alerts, "Quartermaster" for settings)
- Charts use the gold/green/red palette on the dark ocean background

**Memorable detail:** The milestone progress bar on the landing page and dashboard is a ship sailing across an ocean. As MRR grows, the ship moves from left to right. Milestone markers are islands. The current position has a small flag. This is the Pequod Fleet visualized.

---

## PAGE MAP (Every screen in the system)

### Public Pages (no auth)

| Page | Route | Purpose | Key Elements |
|---|---|---|---|
| Landing | / | Convert visitors to subscribers | Hero with live data, problem statement, how it works, comparison chart, pricing cards (monthly/annual toggle), FAQ, milestone tracker, affiliate CTA, footer with status badge |
| Pricing | /pricing | Checkout flow | Three tiers, monthly/annual toggle, Polar checkout (fiat), Coinremitter checkout (crypto), feature comparison table |
| Login | /login | Authentication | Supabase Auth (email/password, magic link). Clean, minimal. Brand logo + tagline. |
| Signup | /login (same page, toggle) | Registration | Same as login with signup tab. After signup: auto-redirect to /pricing (no free tier). |
| Status | /status | System health (public) | Simplified RED/YELLOW/GREEN for poller, scorer, resolver. "All systems operational" or specific component status. No auth required. |
| Auth Callback | /auth/callback | Supabase redirect handler | Invisible. Processes auth, sets referral cookie, redirects to dashboard or pricing. |

### Dashboard Pages (auth required, tier-gated)

| Page | Route | Purpose | Key Elements |
|---|---|---|---|
| Pick Board | /dashboard | Main view. Ranked picks. | Tier-filtered pick cards (rank, title, platform, direction, edge, confidence, crowd, anomaly badge). Sort/filter controls. Realtime via Supabase. Milestone bar. "Last updated" timestamp. |
| Pick Detail | /dashboard/pick/[id] | Full analysis for one pick | Rationale text, PRO/CON evidence columns with grade badges (A/B/C/D), evidence gap, what-would-change, risk factors, social sentiment, price chart (7 days with anomaly markers), "Bet on [Platform]" link, "I Bet This" button, "Final Judgement" button (modal for Harpooner, disabled+Coming Soon for FM/Ahab in Phase 1), share button, feedback thumbs up/down. |
| Market Scanner | /dashboard/markets | Browse all markets | Tier-filtered table of markets with columns: title, platform, nexus score, yes price, volume, anomaly flag, last analyzed. Click to pick detail if scored, or to platform URL if not. |
| Bet Tracker | /dashboard/bets | Track user's positions | Table of user's bets with: market title, direction, entry price, current price, size, P&L (live, direction-aware), status (active/resolved/voided). Win celebration modal on resolution. |
| Referrals | /dashboard/referrals | Affiliate dashboard | Referral link (copy button), click count, signup count, active subscribers, total earned, pending payout, payout history. Fleet visualization (how many ships recruited). |
| Alert History | /dashboard/alerts | Past notifications | Chronological list of past whale alerts, pick notifications, bet resolution notifications. Read/unread status. Link to relevant pick. |
| Settings | /dashboard/settings | Preferences + billing | Notification preferences (Discord webhook URL, toggle per channel). Watchlist management. Billing section (current tier, next billing date, upgrade/downgrade links to Polar portal, cancel with exit survey). BYOAI section (visible all tiers, locked for Harpooner with upgrade CTA). Send Feedback modal. |

### Admin Pages (auth + is_admin required)

| Page | Route | Purpose | Key Elements |
|---|---|---|---|
| Command Center | /admin | System overview | Health dashboard (RED/YELLOW/GREEN per function with last_success timestamps). Revenue card (MRR, subscriber count by tier, trend). Error log summary (last 24h count by source, drill-down). Scoring engine toggle (ACTIVE/PAUSED). Active markets count. Today's picks count. |
| User Activity | /admin/users | User management | Table: email, tier, signup date, last login, bets placed, revenue generated, referred by, account status. Search + filter. Click to user detail. |
| Affiliates | /admin/affiliates | Affiliate management | Top referrers table: referrer, referral count, active subs, churned, total earned, pending payout, fraud flags. Payout approval interface. |
| Accuracy | /admin/accuracy | Pick performance proof | Charts: accuracy rate over time, by category, by confidence level, by tier pool. Resolution count. Edge tracker total. This is the data that proves the product works. |
| Feedback | /admin/feedback | User feedback review | Table: user, tier, type (pick rating/bug/feature/general), pick context if applicable, rating, message, date. Filter by type. Sort by recency. |
| Error Drill-down | /admin (section) | Error investigation | Expandable error log entries with: source, error type, message, metadata, timestamp. Filter by source, by severity, by time window. |

### Shared Components

| Component | Used In | Description |
|---|---|---|
| Navbar | All dashboard/admin | Logo, current route breadcrumb, user avatar/tier badge, notification bell (unread count) |
| Sidebar | Dashboard | Navigation links with maritime-themed icons. Active state highlight. Tier badge. Collapse on mobile. |
| Pick Card | Pick Board, Landing page | Compact card: rank number, market title, platform badge (Kalshi blue / Polymarket purple), direction arrow (green up / red down), edge percentage, confidence chip (high/med/low), crowd indicator, anomaly flame icon. |
| Evidence Badge | Pick Detail | Colored chip: A = green, B = blue, C = yellow, D = red. Shows source type + grade. |
| Tier Badge | Navbar, Admin | Small chip showing current tier with brand color: Harpooner = bronze, First Mate = silver, Ahab = gold. |
| Milestone Bar | Landing, Dashboard | Progress bar from $0 to next milestone. Ship icon at current position. Percentage label. |
| Toast / Alert | Global | Non-blocking notifications for actions (bet placed, settings saved, error occurred). |
| Modal | Multiple | Courtroom upsell (Harpooner), exit survey (cancel flow), feedback form (settings), win celebration (bet tracker). |
| Loading Skeleton | All pages | Animated placeholder shapes matching the layout of the page being loaded. Never a blank page. |
| Empty State | All data pages | Illustrated message when no data exists yet. Uses brand art (woodcut illustration + helpful text). |
| Share Button | Pick Detail, Bet Tracker | Generates formatted text with affiliate link baked in. Copy to clipboard or share to platform. |
| Live Data Feed | Landing hero | Animated stream of market analysis: market names, probability calculations, "EDGE FOUND" highlights. Simulated from real market names if no live data yet. |
| Comparison Chart | Landing page | Three-column table (Free Tools / Data Terminals / Harpoon Cannon) with checkmark/X per feature row. Animated on scroll into view. |
| Pricing Toggle | Pricing page, Landing | Monthly / Annual switch. Annual pre-selected with "Save 17%" badge. Swaps Polar product IDs. |

---

## RESPONSIVE DESIGN

| Breakpoint | Layout |
|---|---|
| Desktop (1280px+) | Full sidebar + main content. Two-column layouts where applicable. |
| Tablet (768-1279px) | Collapsible sidebar (hamburger menu). Single column. Cards stack vertically. |
| Mobile (< 768px) | Bottom tab navigation (5 tabs: Board, Markets, Bets, Alerts, More). No sidebar. Full-width cards. Simplified pick cards (remove crowd indicator, show only rank + title + edge + direction). |

---

## ANIMATION SPEC (Landing Page)

### Hero Live Data Feed
Simulated (or real) stream of market analysis. Implementation:
1. Array of 50+ real Kalshi/Polymarket market titles (hardcoded for pre-launch, live after Phase 1)
2. Every 2-3 seconds: a new market "enters" the analysis pipeline
3. Animation sequence per market: title appears (fade in left), probability bar fills (0 to calculated value over 1s), edge calculation appears (typewriter effect), if edge > 15: gold "EDGE FOUND" badge pulses in
4. 5-6 markets visible at once, oldest scrolls up and fades out
5. Continuous loop. Never stops. Visitor always sees activity.

### Scroll Animations
- Sections fade + slide up on scroll into viewport (IntersectionObserver, 0.3s ease)
- Comparison chart rows animate left-to-right sequentially (stagger 0.1s per row)
- Pricing cards scale up slightly on hover (transform: scale(1.02), 0.2s)
- Milestone ship moves smoothly when MRR data loads

### Micro-interactions
- Pick cards: subtle border-glow on hover
- Buttons: slight lift (translateY -1px) + shadow increase on hover
- Tier badges: gentle pulse animation on upgrade upsell CTAs
- Whale alert icon: sonar ripple animation (concentric circles fading out)
- Evidence grade badges: tooltip appears on hover with grade meaning

---

## BRAND ART GUIDELINES

### What to commission (or generate):
1. **Hero whale illustration:** Rockwell Kent style woodcut. White whale surfacing from dark water. High contrast. Black ink lines. Will be used as SVG at low opacity behind hero text, and as the og:image for social sharing.
2. **Ship silhouette:** The Pequod at full sail. Used in milestone bar, loading states, and favicon.
3. **Harpoon icon:** Simple, elegant, used as the primary brand mark. Think: a minimalist harpoon that could work at 16x16 favicon size AND 200px hero size.
4. **Section dividers:** Thin ornamental rules inspired by 19th-century book design. 3-4 variations.
5. **Tier icons:** Harpooner (harpoon), First Mate (ship's wheel), Ahab (captain's spyglass). Simple line art.
6. **Empty state illustrations:** Small woodcut vignettes for "no picks yet," "no bets yet," "no alerts yet." Ocean scenes. Not characters. (Barry Moser's approach: ships and sea, no people.)

### What NOT to do:
- No cartoonish whales or pirates
- No clip art anchors or ship wheels as UI chrome
- No full-color maritime paintings (the aesthetic is woodcut/engraving, not oil painting)
- No text in the illustrations (text is always rendered in the UI, never baked into art)
- No overuse of brand art on the dashboard (the dashboard is data-first, art lives on the landing page and empty states)

---

## TECHNICAL NOTES FOR THE CODER

### Schema context
The database has 19 tables defined in `001_initial_schema.sql`. Design pages that read/write data: admin/feedback reads `user_feedback`, admin/users reads `user_profiles` + joins `user_bets` + `payments`, status page reads `system_state` last_success timestamps, event tracking writes to `user_events`, pick detail reads `picks` + `courtroom_verdicts` + `user_feedback`. See the architecture doc ER diagram for full relationships.

### Framework
- Next.js 14+ App Router with TypeScript
- Tailwind CSS for utility classes
- shadcn/ui as the component foundation (customized heavily with brand colors)
- Framer Motion for animations (landing page hero, scroll reveals, micro-interactions)
- Recharts for dashboard charts (or Chart.js if more customization needed)
- Supabase Realtime for live pick updates on the dashboard

### CSS Variables (set in globals.css, consumed by shadcn/ui)
Map the chosen concept's palette to shadcn/ui's variable system:
```
--background, --foreground, --card, --card-foreground,
--primary, --primary-foreground, --secondary, --secondary-foreground,
--accent, --accent-foreground, --muted, --muted-foreground,
--destructive, --destructive-foreground, --border, --ring
```
Dark theme by default. No light theme at launch. (Consider for Phase 2.)

### Font Loading
Use `next/font` for all fonts. Preload display font. Variable fonts preferred for performance.

### Image Handling
Brand illustrations stored as optimized SVGs in `/public/brand/`. Never raster for illustrations. Photos (if any) use next/image with blur placeholder.

### Performance Targets
- Lighthouse: 90+ on all metrics
- LCP under 2.5s
- CLS under 0.1
- Landing page total weight under 500KB (excluding fonts)
- Dashboard first meaningful paint under 1.5s (skeleton + streaming)

---

## DECISION NEEDED FROM WOLF

~~Pick one concept (A, B, or C) or describe a hybrid.~~

**DECIDED: Concept C "The Nautical Chart" selected.** Wolf confirmed 2026-04-15. All three concepts remain documented below for reference, but Concept C is the build target. A working HTML mockup of the landing page exists in `design-example-landing.html`.

- **A ("Captain's Study"):** Warm, literary, gold accents, most brand-forward on the dashboard. Feels premium. (NOT SELECTED)
- **B ("Intelligence Bureau"):** Cold, clinical, arctic blue, brand art ONLY on landing page. Feels technical. (NOT SELECTED)
- **C ("Nautical Chart"):** Balanced. Chart-paper texture, compass motifs, whale-as-data hero. Feels unique. **(SELECTED)**

All three work. All three are professional. The difference is emotional: A says "trust the experts," B says "trust the data," C says "trust the hunt."

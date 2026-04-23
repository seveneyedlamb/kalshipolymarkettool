# SYNC PROTOCOL
## Drift Prevention System for Harpoon Cannon
## Authority: Absolute. Read before every edit.

---

## THE PROBLEM THIS SOLVES

A SaaS spec spread across 11 files has a natural entropy: every edit risks leaving another file stale. Example: one doc says "N tables" and the SQL file creates N-2. The coder reads one, writes the other, and ships a broken migration. We found this exact class of bug 60+ times during audits. It keeps happening because no single person or tool was responsible for enforcing consistency.

This document is that responsibility.

**Rule zero: if you cannot update all affected files in one sitting, do not make the edit.**

---

## THE 11 PROJECT FILES

Every file, what it does, and why it matters. (SYNC-PROTOCOL.md itself is the 11th; it's listed at the bottom as a meta-entry because it governs the other 10.)

| # | File | Role | Updated when |
|---|---|---|---|
| 1 | `001_initial_schema.sql` | **DATABASE SOURCE OF TRUTH.** Exact migration Supabase runs. | Any column, table, index, RLS, or seed change |
| 2 | `HARPOON-CANNON-v3-FINAL.md` | Architecture spec. ~3,600 lines. 11 mermaid diagrams. | Any design or behavior change |
| 3 | `CLAUDE.md` | Per-session context. What coders paste into every session. | Any critical rule, tier, API route, or contract change |
| 4 | `harpoon-cannon-build-guide.md` | Phase-by-phase build order with exact commands. | Any new session-level task or verification step |
| 5 | `HARPOON-REFERENCE.md` | Quick-load reference. Fiscal review. | Any numeric change (price, cap, count, margin) |
| 6 | `ERROR-HUNTER.md` | Bug prevention methodology + error log. | Every bug found, every audit completed |
| 7 | `progress.md` | Per-timestamp session tracker. | Every substantive work session |
| 8 | `vercel.json` | Cron schedules. | Any cron addition, removal, or timing change |
| 9 | `design.md` | Design reference. 3 concepts + page map + component specs. | Any UI structure change |
| 10 | `design-example-landing.html` | Visual mockup of chosen design concept. | Optional. Regenerate when design decisions change. |
| 11 | `SYNC-PROTOCOL.md` | **This file.** Governs drift prevention across all others. | Any new file added, any canonical value list updated, any drift hotspot discovered. |

The 11th pseudo-file: **the 11 mermaid diagrams embedded inside HARPOON-CANNON-v3-FINAL.md**. These are their own source of truth. Drift between prose and diagrams is the most common failure mode.

---

## CANONICAL VALUES

Numbers and facts that MUST match across all files. If you change one, verify all listed locations.

### Table count: 19
Locations that reference this number:
- `001_initial_schema.sql` header (line 6) + CREATE TABLE count
- `HARPOON-CANNON-v3-FINAL.md` ER diagram entities + any prose "19 tables"
- `CLAUDE.md` "## Database Tables (19)" + table list
- `HARPOON-REFERENCE.md` "## 19 DATABASE TABLES" + table list
- `harpoon-cannon-build-guide.md` Session 2 verification "19 tables visible"
- Function map mermaid DATA subgraph (lists all 19)

### API route count: 15
Locations:
- `CLAUDE.md` "## API Routes (15)"
- `HARPOON-CANNON-v3-FINAL.md` function map mermaid + "Total backend functions: 15"
- `HARPOON-REFERENCE.md` "## 15 API ROUTES" + table
- `harpoon-cannon-build-guide.md` session commands (routes referenced by name)
- `vercel.json` 7 crons (validate-models = weekly Sun 06:00)

### Pricing: $29 / $99 / $299 (monthly) | $290 / $990 / $2,990 (annual)
Locations:
- `HARPOON-CANNON-v3-FINAL.md` pricing card copy + differentiator table + break-even math
- `CLAUDE.md` tier configuration + break-even math
- `harpoon-cannon-build-guide.md` Session 9 Polar product IDs reference
- `HARPOON-REFERENCE.md` tier table + fiscal review
- `design.md` pricing card examples
- `design-example-landing.html` data-monthly / data-annual attributes

### Daily safety cap: Harpooner 0 | First Mate 20 | Ahab 50
Locations:
- `HARPOON-CANNON-v3-FINAL.md` TIER_FEATURES config + differentiator table + courtroom section + defense-in-depth section
- `CLAUDE.md` courtroom spec + BYOAI spec
- `harpoon-cannon-build-guide.md` Session 12 (Courtroom build) + BYOAI note
- `HARPOON-REFERENCE.md` tier table + fiscal section

### Monthly credit allowance: Harpooner 0 | First Mate 150 | Ahab 500
Locations:
- `HARPOON-CANNON-v3-FINAL.md` TIER_FEATURES + tier table + fiscal math
- `CLAUDE.md` tier configuration
- `HARPOON-REFERENCE.md` tier table
- `harpoon-cannon-build-guide.md` Session 12 courtroom credit check logic

### BYOAI daily cap: 300/day
Locations:
- `HARPOON-CANNON-v3-FINAL.md` BYOAI section + TIER_FEATURES
- `CLAUDE.md` BYOAI spec
- `HARPOON-REFERENCE.md` BYOAI section
- `harpoon-cannon-build-guide.md` Session P2-7 BYOAI

### Environment variable count: Phase 1 = 14
Locations:
- `HARPOON-CANNON-v3-FINAL.md` "Total at Phase 1 launch: 14 environment variables"
- `HARPOON-REFERENCE.md` "Phase 1 (14):" with full list

### Build session count: Phase 1 = 14 | Phase 2 = 7 | Phase 3 = 8
Locations:
- `HARPOON-CANNON-v3-FINAL.md` Gantt chart + build phase prose
- `harpoon-cannon-build-guide.md` session headings (actual count)
- `HARPOON-REFERENCE.md` build order summary

### Error count: 407 fixed | 545+ total edits
Locations:
- `ERROR-HUNTER.md` grand total + density map
- `HARPOON-REFERENCE.md` status section

---

## PRE-EDIT CHECKLIST

Before making ANY change, ask:

1. **Is this a numeric value (count, price, cap, limit)?**
   - If yes: find it in the Canonical Values section above. Update every listed location.

2. **Is this a schema change (column, table, index, RLS, seed)?**
   - If yes: `001_initial_schema.sql` must change. Plus: the ER diagram. Plus: any prose describing the column. Plus: the table list in CLAUDE.md and HARPOON-REFERENCE.md if a table count changed.

3. **Is this a new API route or route removal?**
   - If yes: the function map mermaid, the file tree, the API route count (14 currently), CLAUDE.md route list, HARPOON-REFERENCE.md route list, and the relevant build session.

4. **Is this a tier change (pricing, limits, features)?**
   - If yes: TIER_FEATURES config, differentiator table, tier table in reference, fiscal math recalculated, pricing cards spec, design.md pricing mention, design-example-landing.html pricing values.

5. **Is this a UI structure change (new page, new component)?**
   - If yes: design.md page map, architecture doc route map mermaid, project structure tree, and potentially build guide session.

6. **Is this an environment variable addition?**
   - If yes: architecture doc env var list + count, reference doc env var list + count, relevant build session.

7. **Is this a cron schedule change?**
   - If yes: vercel.json, architecture doc cron table, build guide Session 14 deploy verification.

---

## POST-EDIT AUDIT COMMANDS

After any edit, run these grep commands to verify nothing drifted:

```bash
# 1. Table count consistency (should all say 19)
echo "SQL CREATE TABLE: $(grep -c '^CREATE TABLE' /mnt/user-data/outputs/001_initial_schema.sql)"
grep -Hn '19 tables\|Tables (19)\|19 DATABASE\|Table count: 19' /mnt/user-data/outputs/*.md /mnt/user-data/outputs/*.sql 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER

# 2. Pricing tier consistency ($29/$99/$299 monthly, $290/$990/$2,990 annual)
for p in '\$29/' '\$99/' '\$299/' '\$290/' '\$990/' '\$2,990'; do
  echo "$p: $(grep -rl "$p" /mnt/user-data/outputs/*.md /mnt/user-data/outputs/*.html 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER | wc -l) files"
done

# 3. Daily cap values (20/day FM, 50/day Ahab, 300/day BYOAI)
grep -rHn '20/day\|50/day\|300/day' /mnt/user-data/outputs/*.md 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER | grep -v SYNC

# 4. Credit allowances (150 FM, 500 Ahab)
grep -rHn '150/month\|500/month' /mnt/user-data/outputs/*.md 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER | grep -v SYNC

# 5. API route count (should say 14 everywhere)
grep -rHn '14.*routes\|14.*API\|14.*backend\|Routes (14' /mnt/user-data/outputs/*.md 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER | grep -v SYNC

# 6. Env var count (Phase 1 = 14)
grep -rHn 'Phase 1.*(14)\|launch: 14' /mnt/user-data/outputs/*.md 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER | grep -v SYNC

# 7. File count (should say 11 everywhere)
grep -rHn '11 files\|FILES (11\|ALL 11 files' /mnt/user-data/outputs/*.md 2>/dev/null | grep -v progress | grep -v ERROR-HUNTER
```

Any output inconsistency is drift. Fix before moving on.

---

## THE 11 MERMAID DIAGRAMS (high-drift zone)

Mermaid diagrams embedded in the architecture doc. Each is a separate source of truth. When prose says something that a diagram shows, BOTH must agree.

1. **System Architecture** (graph TB) - data flow between all systems
2. **Poller Flow** (flowchart TD) - every step the poller takes
3. **Scoring Engine Flow** (flowchart TD) - two-stage pipeline
4. **Signal Categories** (graph TB) - 8 categories + output format
5. **Route Map** (graph TB) - all pages + navigation
6. **ER Diagram** (erDiagram) - all tables + relationships
7. **Gantt Chart** (gantt) - build order + dependencies
8. **Payment Flow** (sequenceDiagram) - webhook handling
9. **Notification Flow** (flowchart TD) - alert dispatch
10. **Courtroom Flow** (flowchart TD) - two-call adversarial AI
11. **Function Map** (graph TB) - all backend functions + DB access

**Drift rule for diagrams:** if a prose change affects a concept shown in a diagram, the diagram must be updated in the same edit. Period.

---

## CRITICAL RULE 0 (APPEARS IN CLAUDE.md AND HARPOON-REFERENCE.md)

> 001_initial_schema.sql IS THE SOURCE OF TRUTH FOR THE DATABASE. Every schema-related edit in any document REQUIRES a matching edit to this file in the same session. Period.

This applies recursively: if you edit the SQL file, you must also verify CLAUDE.md + reference doc table lists + architecture doc ER diagram match.

---

## NEW FILE PROTOCOL

Before adding a new file to the project:

1. Does it belong in an existing file? (Usually yes.)
2. If no, what's its single responsibility?
3. Update this SYNC-PROTOCOL.md file list.
4. Update HARPOON-REFERENCE.md file list.
5. Update ERROR-HUNTER.md post-edit ripple checklist.
6. Update the file count references anywhere they appear.

The project has grown from 6 to 11 files. Adding a 12th should require strong justification.

---

## KNOWN DRIFT HOTSPOTS

History-based list of where drift has appeared before:

1. **Pool A/B threshold operators.** `>= 0.7` vs `> 0.7` split into 4+ locations. Always verify all of them when adjusting nexus thresholds.
2. **Table count header in CLAUDE.md.** The "## Database Tables (N)" header was updated from 16 to 18 but the list below wasn't. Always edit both.
3. **Env var count.** Changed from 12 to 13 when annual product ID was added. Only one of three files was initially updated.
4. **Daily safety cap.** Started at 50 flat for both tiers, then differentiated to 20/50. Had to be fixed in 6 separate locations.
5. **Credited vs BYOAI daily caps.** These are SEPARATE counters. Any prose that says "300/day" must clarify whether it's BYOAI (yes) or credited (no).
6. **Function count in function map mermaid.** Added V12 (settings/byoai) but mermaid still said "13 routes" until audit.
7. **DATA subgraph in function map.** Listed some tables but not all 18 after new tables were added.
8. **Pricing cards.** Monthly/annual toggle added to prose but design-example-landing.html had old monthly-only values until checked.
9. **Table count when adding new tables.** waitlist table (Audit L09) required updating 12 separate locations. Miss one and the coder sees conflicting numbers.
10. **Env var count when adding new vars.** POLAR_MODE (Audit L20) bumped count from 13 to 14. Two files had the count, plus the SYNC-PROTOCOL canonical value. Three places minimum.
11. **Architecture doc TOC line numbers.** Any content insertion shifts all subsequent sections. The TOC is always stale within a few edits. Grep for section headers, don't trust the numbers blindly.
12. **ai/ folder parallel copies.** If an `ai/` subfolder exists in the project root containing compressed/caveman versions of CLAUDE.md, HARPOON-REFERENCE.md, SYNC-PROTOCOL.md, harpoon-cannon-build-guide.md, and design.md (intended for token-efficient injection into coding sessions): any edit to the root version of those files MUST be mirrored into `ai/` in the same commit, OR the `ai/` folder must be regenerated from scratch. Silent drift between root and `ai/` is the exact failure mode this protocol exists to prevent. If the `ai/` folder is no longer used, delete it rather than let it rot.

---

## ENFORCEMENT

Every Claude session that edits this project MUST:

1. Read SYNC-PROTOCOL.md before starting work
2. Run the post-edit audit commands after making changes
3. Report any drift found during the session in progress.md
4. Never declare work "complete" if audit commands show inconsistency

Drift is a bug. Treat it like one.

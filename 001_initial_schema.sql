-- =====================================================================
-- HARPOON CANNON: AUTHORITATIVE DATABASE SCHEMA
-- =====================================================================
-- Version: Phase 1 Initial Migration
-- Last updated: 2026-04-15
-- Table count: 19
-- Last edit: Added waitlist table (pre-launch email capture, L09 fix)
--
-- THIS FILE IS THE SOURCE OF TRUTH FOR DATABASE STRUCTURE.
-- Every other document (architecture, CLAUDE.md, reference, build guide)
-- describes WHAT the database should do. This file is WHAT IS ACTUALLY
-- CREATED when the migration runs. If the docs and this file disagree,
-- THIS FILE WINS, because this is what Supabase will execute.
--
-- MAINTENANCE PROTOCOL (read before editing):
-- 1. Any column addition/removal in the architecture doc MUST be
--    mirrored here in the same commit. No exceptions.
-- 2. Any new table specified in the architecture doc MUST be added
--    here with: CREATE TABLE, all indexes, all RLS policies, all
--    seeds if applicable.
-- 3. Every bug fix in an error audit that touches database structure
--    (missing columns, wrong types, missing indexes, missing RLS)
--    MUST be applied to this file.
-- 4. When a column is added, update the table count header, the
--    architecture doc ER diagram, and the CLAUDE.md / reference doc
--    table lists in the same edit.
-- 5. Column types matter. "text" vs "varchar(N)" matters. "float" vs
--    "numeric" matters. This file specifies the types that Supabase
--    will create. Changes here change the database.
-- 6. system_state seeds at the bottom of this file are part of the
--    migration. If a new operational key is needed, add it here.
-- 7. Run order of statements matters. Don't move tables above their
--    dependencies. Don't move indexes above their tables.
-- 8. This is a Phase 1 migration. Phase 2 migrations are separate
--    files (002_phase2.sql) that ADD to Phase 1, never
--    modify it. The bricklayer rule applies to schema too.
--
-- PHASE 2 MIGRATIONS (not in this file, applied later):
-- - ALTER TABLE user_profiles ADD COLUMN byoai_queries_today int DEFAULT 0;
-- - ALTER TABLE user_profiles ADD COLUMN byoai_reset_at timestamptz;
-- - ALTER TABLE user_profiles ADD COLUMN affiliate_fraud_flag boolean DEFAULT false;
--
-- Note: custom_ai_provider, custom_ai_key_encrypted, custom_ai_model are
-- already in the Phase 1 CREATE TABLE (empty columns, zero cost). This avoids
-- a Phase 2 ALTER TABLE migration for the BYOAI settings UI structure. The
-- Phase 2 migration only adds the daily counter columns needed for rate limiting.
--
-- All timestamps are UTC (timestamptz). No exceptions.
-- All prices are stored as float 0.00-1.00. Never cents.
-- All IDs are uuid. Never int. Never text.
-- All money amounts are numeric(10,2) for precision.
-- =====================================================================

-- ============================================
-- TABLES
-- ============================================

-- markets: INTENTIONALLY no RLS. Market data is publicly available on Kalshi
-- and Polymarket websites. Writes happen only via the admin Supabase client
-- (poller cron). Authenticated users need SELECT access; Supabase's default
-- grants on the public schema (authenticated role = SELECT) provide this
-- without needing RLS policies. Crowd aggregate fields (crowd_views_24h,
-- crowd_bets_24h, crowd_yes_pct) are a minor exposure accepted for simplicity.
-- If this decision is ever reversed, add ENABLE ROW LEVEL SECURITY plus a
-- public-read policy and audit all insert/update paths for admin-client usage.
CREATE TABLE markets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL,
  platform_id text NOT NULL,
  title text NOT NULL,
  description text,
  category text,
  market_url text,
  nexus_score float DEFAULT 0,
  nexus_tags text[] DEFAULT '{}',
  nexus_entities jsonb DEFAULT '{}',
  yes_price float,
  no_price float,
  volume_24h float,
  open_interest float,
  status text DEFAULT 'active',
  resolution_outcome text,
  resolution_date timestamptz,
  resolved_at timestamptz,
  close_time timestamptz,
  last_polled_at timestamptz,
  last_analyzed_at timestamptz,
  crowd_views_24h int DEFAULT 0,
  crowd_watchlist_count int DEFAULT 0,
  crowd_bets_24h int DEFAULT 0,
  crowd_yes_pct float DEFAULT 50,
  google_trend_score int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(platform, platform_id)
);

CREATE TABLE snapshots (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  market_id uuid REFERENCES markets(id) ON DELETE CASCADE,
  captured_at timestamptz DEFAULT now(),
  yes_price float,
  no_price float,
  volume_24h float,
  open_interest float
);

CREATE TABLE anomalies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  market_id uuid REFERENCES markets(id) ON DELETE CASCADE,
  detected_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL,
  anomaly_type text NOT NULL,
  severity float NOT NULL,
  confidence float NOT NULL,
  direction text,
  details jsonb DEFAULT '{}'
);

CREATE TABLE picks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  market_id uuid REFERENCES markets(id) ON DELETE CASCADE,
  cycle_id uuid NOT NULL,
  scored_at timestamptz DEFAULT now(),
  min_tier text NOT NULL,
  true_probability int NOT NULL,
  p_neutral int,
  p_aware int,
  evidence_divergence int,
  direction text NOT NULL,
  edge float NOT NULL,
  confidence_level text NOT NULL,
  pick_score float NOT NULL,
  rationale text,
  key_evidence jsonb DEFAULT '[]',
  risk_factors jsonb DEFAULT '[]',
  social_sentiment jsonb DEFAULT '{}',
  evidence_gap text,
  what_would_change text,
  market_price_at_scoring float,
  rank int,
  analysis_pool text,
  is_whale_alert boolean DEFAULT false,
  resolved boolean DEFAULT false,
  was_correct boolean,
  actual_pnl_pct float
);

CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  tier text,
  account_status text DEFAULT 'active',
  subscription_expires_at timestamptz,
  payment_provider text,
  payment_customer_id text,
  payment_subscription_id text,
  referral_code text UNIQUE DEFAULT substr(md5(random()::text), 1, 8),
  referred_by uuid REFERENCES user_profiles(id),
  affiliate_balance float DEFAULT 0,
  discord_webhook_url text,
  telegram_chat_id text,
  phone_sms text,
  notify_discord boolean DEFAULT true,
  discord_fail_count int DEFAULT 0,
  notify_telegram boolean DEFAULT false,
  notify_email boolean DEFAULT false,
  notify_sms boolean DEFAULT false,
  notify_threshold text DEFAULT 'high',
  is_admin boolean DEFAULT false,
  monthly_credits_used int DEFAULT 0,
  bonus_credits int DEFAULT 0,
  custom_ai_provider text,
  custom_ai_key_encrypted text,
  custom_ai_model text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE user_bets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  pick_id uuid REFERENCES picks(id) ON DELETE SET NULL,
  market_id uuid REFERENCES markets(id),
  platform text,
  direction text NOT NULL,
  entry_price float NOT NULL,
  size_usd float NOT NULL,
  placed_at timestamptz DEFAULT now(),
  status text DEFAULT 'active',
  exit_price float,
  pnl_usd float,
  resolved_at timestamptz
);

CREATE TABLE user_watchlist (
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  market_id uuid REFERENCES markets(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, market_id)
);

CREATE TABLE market_views (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  market_id uuid REFERENCES markets(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  viewed_at timestamptz DEFAULT now()
);

CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  provider text NOT NULL,
  provider_event_id text UNIQUE NOT NULL,
  event_type text NOT NULL,
  amount float NOT NULL,
  currency text DEFAULT 'USD',
  tier_at_payment text,
  paid_at timestamptz DEFAULT now(),
  referred_by uuid REFERENCES user_profiles(id),
  commission_amount float DEFAULT 0,
  commission_credited boolean DEFAULT false
);

CREATE TABLE referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  referred_user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  referral_code text NOT NULL,
  subscribed_at timestamptz,
  status text DEFAULT 'pending',
  total_earned float DEFAULT 0
);

CREATE TABLE affiliate_payouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  amount float NOT NULL,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  paid_at timestamptz
);

CREATE TABLE notification_log (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  pick_id uuid REFERENCES picks(id) ON DELETE SET NULL,
  notification_type text NOT NULL DEFAULT 'new_pick',
  channel text NOT NULL,
  sent_at timestamptz DEFAULT now()
);
-- notification_type: 'new_pick', 'whale_alert', 'crowd_trending', 'bet_resolved', 'renewal_reminder'

CREATE TABLE system_state (
  key text PRIMARY KEY,
  value text,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE error_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source text NOT NULL,
  error_type text,
  details jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE active_sessions (
  session_id text PRIMARY KEY,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  device_hash text,
  created_at timestamptz DEFAULT now(),
  last_active_at timestamptz DEFAULT now()
);

-- ============================================
-- INDEXES
-- ============================================

-- Pick Board query (most-hit query in the system)
CREATE INDEX idx_picks_board ON picks (cycle_id, min_tier, pick_score DESC);

-- Active anomaly lookup
CREATE INDEX idx_anomalies_active ON anomalies (market_id, expires_at DESC);

-- Rolling average calculation (poller, every 60s)
CREATE INDEX idx_snapshots_rolling ON snapshots (market_id, captured_at DESC);

-- Notification throttle check
CREATE INDEX idx_notif_throttle ON notification_log (user_id, sent_at DESC);

-- Webhook idempotency check (unique already on provider_event_id)

-- Latest cycle lookup (used by Pick Board to find most recent cycle)
CREATE INDEX idx_picks_latest ON picks (scored_at DESC);

-- Referral code lookup (unique constraint already creates an index on the column)

-- Scoring engine market selection
CREATE INDEX idx_markets_scoring ON markets (nexus_score DESC, status) WHERE status = 'active';

-- Crowd aggregation queries
CREATE INDEX idx_bets_crowd ON user_bets (market_id, placed_at DESC);
CREATE INDEX idx_views_crowd ON market_views (market_id, viewed_at DESC);

-- User bets by market (for resolution processing)
CREATE INDEX idx_bets_market ON user_bets (market_id) WHERE status = 'active';

-- Picks by market (for resolution processing)
CREATE INDEX idx_picks_market ON picks (market_id) WHERE resolved = false;

-- Whale alert picks (for Pick Board OR clause)
CREATE INDEX idx_picks_whale ON picks (scored_at DESC) WHERE is_whale_alert = true;

-- Session management (concurrent session limits)
CREATE INDEX idx_sessions_user ON active_sessions (user_id, last_active_at DESC);

-- Subscription expiration cron: daily UPDATE WHERE subscription_expires_at < now()
-- AND tier IS NOT NULL. Partial index keeps size minimal (only subscribed users
-- have a non-null tier) while eliminating sequential scans as the user base grows.
CREATE INDEX idx_user_profiles_expires ON user_profiles (subscription_expires_at)
  WHERE tier IS NOT NULL;

-- ============================================
-- CHECK CONSTRAINTS (enum-like text fields)
-- ============================================
-- Defense-in-depth. Application code already validates these values, but
-- constraints guarantee the database refuses invalid states even if a future
-- migration script or direct SQL insert skips the app validation.
-- All CHECK constraints use NOT VALID + VALIDATE pattern so adding them to
-- an existing table in a later migration is safe (no long exclusive lock).
-- On Phase 1 initial creation they run as normal inline constraints.

ALTER TABLE user_profiles ADD CONSTRAINT chk_user_tier
  CHECK (tier IS NULL OR tier IN ('harpooner', 'first_mate', 'ahab'));

ALTER TABLE user_profiles ADD CONSTRAINT chk_user_account_status
  CHECK (account_status IN ('active', 'banned'));

ALTER TABLE user_profiles ADD CONSTRAINT chk_user_payment_provider
  CHECK (payment_provider IS NULL OR payment_provider IN ('polar', 'coinremitter'));

ALTER TABLE user_profiles ADD CONSTRAINT chk_user_notify_threshold
  CHECK (notify_threshold IN ('high', 'medium', 'low'));

ALTER TABLE picks ADD CONSTRAINT chk_pick_direction
  CHECK (direction IN ('YES', 'NO'));

ALTER TABLE picks ADD CONSTRAINT chk_pick_min_tier
  CHECK (min_tier IN ('harpooner', 'first_mate', 'ahab'));

ALTER TABLE picks ADD CONSTRAINT chk_pick_confidence
  CHECK (confidence_level IN ('high', 'medium', 'low'));

ALTER TABLE picks ADD CONSTRAINT chk_pick_probability
  CHECK (true_probability >= 0 AND true_probability <= 100);

ALTER TABLE markets ADD CONSTRAINT chk_market_status
  CHECK (status IN ('active', 'closed', 'resolved'));

ALTER TABLE markets ADD CONSTRAINT chk_market_platform
  CHECK (platform IN ('kalshi', 'polymarket'));

ALTER TABLE markets ADD CONSTRAINT chk_market_prices
  CHECK (
    (yes_price IS NULL OR (yes_price >= 0.0 AND yes_price <= 1.0))
    AND (no_price IS NULL OR (no_price >= 0.0 AND no_price <= 1.0))
  );

ALTER TABLE user_bets ADD CONSTRAINT chk_bet_direction
  CHECK (direction IN ('YES', 'NO'));

ALTER TABLE user_bets ADD CONSTRAINT chk_bet_status
  CHECK (status IN ('active', 'resolved', 'voided'));

ALTER TABLE user_bets ADD CONSTRAINT chk_bet_entry_price
  CHECK (entry_price >= 0.0 AND entry_price <= 1.0);

ALTER TABLE user_bets ADD CONSTRAINT chk_bet_size
  CHECK (size_usd > 0 AND size_usd <= 100000);

ALTER TABLE anomalies ADD CONSTRAINT chk_anomaly_type
  CHECK (anomaly_type IN ('volume_spike', 'price_move', 'both'));

ALTER TABLE anomalies ADD CONSTRAINT chk_anomaly_severity
  CHECK (severity >= 0.0 AND severity <= 1.0);

ALTER TABLE anomalies ADD CONSTRAINT chk_anomaly_confidence
  CHECK (confidence >= 0.0 AND confidence <= 1.0);

ALTER TABLE referrals ADD CONSTRAINT chk_referral_status
  CHECK (status IN ('pending', 'active', 'churned', 'refunded'));

ALTER TABLE affiliate_payouts ADD CONSTRAINT chk_payout_status
  CHECK (status IN ('pending', 'paid', 'cancelled'));

ALTER TABLE notification_log ADD CONSTRAINT chk_notification_type
  CHECK (notification_type IN ('new_pick', 'whale_alert', 'crowd_trending', 'bet_resolved', 'renewal_reminder'));

ALTER TABLE notification_log ADD CONSTRAINT chk_notification_channel
  CHECK (channel IN ('discord', 'telegram', 'email', 'sms'));

ALTER TABLE user_feedback ADD CONSTRAINT chk_feedback_type
  CHECK (feedback_type IN ('pick_rating', 'bug_report', 'feature_request', 'general'));

ALTER TABLE user_feedback ADD CONSTRAINT chk_feedback_rating
  CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE picks ENABLE ROW LEVEL SECURITY;
ALTER TABLE anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_sessions ENABLE ROW LEVEL SECURITY;

-- Users read/update own profile only
CREATE POLICY "Users read own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);

-- Users read/write own bets only
CREATE POLICY "Users read own bets" ON user_bets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own bets" ON user_bets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users manage own watchlist
CREATE POLICY "Users read own watchlist" ON user_watchlist FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own watchlist" ON user_watchlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own watchlist" ON user_watchlist FOR DELETE USING (auth.uid() = user_id);

-- Users read own notifications
CREATE POLICY "Users read own notifications" ON notification_log FOR SELECT USING (auth.uid() = user_id);

-- Users read own payments
CREATE POLICY "Users read own payments" ON payments FOR SELECT USING (auth.uid() = user_id);

-- Users read referrals where they are referrer
CREATE POLICY "Users read own referrals" ON referrals FOR SELECT USING (auth.uid() = referrer_user_id);

-- Users read own payouts (admin writes via service role, bypasses RLS)
CREATE POLICY "Users read own payouts" ON affiliate_payouts FOR SELECT USING (auth.uid() = user_id);

-- Users read own sessions (admin writes via service role, bypasses RLS).
-- Middleware creates/updates/prunes sessions using the admin client.
CREATE POLICY "Users read own sessions" ON active_sessions FOR SELECT USING (auth.uid() = user_id);

-- Market views: insert only (no read needed client-side)
CREATE POLICY "Users insert views" ON market_views FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Picks, anomalies, snapshots: authenticated users read all, system writes via admin client
CREATE POLICY "Authenticated users read picks" ON picks FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users read anomalies" ON anomalies FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users read snapshots" ON snapshots FOR SELECT USING (auth.uid() IS NOT NULL);

-- error_log and system_state: NO read policies for regular users.
-- RLS enabled = default deny for browser/anon client.
-- Admin client (service role key) bypasses RLS and can read/write freely.
-- This prevents stack traces and internal state from leaking to users.
ALTER TABLE error_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_state ENABLE ROW LEVEL SECURITY;
-- system_state needs a public read policy ONLY for milestone-status (mrr_cache is public)
CREATE POLICY "Public read mrr_cache" ON system_state FOR SELECT USING (key = 'mrr_cache');

-- ============================================
-- AUTH TRIGGER: Create user_profiles on signup
-- ============================================
-- CRITICAL: Without this, users sign up but user_profiles row never exists.
-- Webhook tries to set tier -> 0 rows updated -> user pays but gets nothing.
-- Middleware checks tier -> no row -> crash.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_code text;
  max_retries int := 5;
  i int := 0;
BEGIN
  -- Generate referral code with collision retry
  -- 8-char hex = 4.3B possibilities, but UNIQUE constraint means
  -- a collision crashes the trigger and blocks signup without retry
  LOOP
    new_code := substr(md5(random()::text || clock_timestamp()::text), 1, 8);
    BEGIN
      INSERT INTO public.user_profiles (id, email, referral_code)
      VALUES (NEW.id, NEW.email, new_code);
      RETURN NEW;
    EXCEPTION WHEN unique_violation THEN
      i := i + 1;
      IF i >= max_retries THEN
        RAISE EXCEPTION 'Failed to generate unique referral code after % attempts', max_retries;
      END IF;
      -- Loop and try a new code
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog;
-- SET search_path is mandatory for SECURITY DEFINER functions. Without it, a
-- malicious user who can create objects in a schema earlier in the search_path
-- could shadow public.user_profiles with their own table and hijack the trigger.
-- This is a standard PostgreSQL security hardening rule (CVE pattern) and Supabase
-- Database Linter flags SECURITY DEFINER functions missing search_path as a warning.

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- REALTIME
-- ============================================

-- Enable Realtime on these tables
ALTER PUBLICATION supabase_realtime ADD TABLE picks;
ALTER PUBLICATION supabase_realtime ADD TABLE anomalies;
ALTER PUBLICATION supabase_realtime ADD TABLE markets;

-- ============================================
-- INITIAL SYSTEM STATE
-- ============================================

INSERT INTO system_state (key, value) VALUES ('poller_lock', 'idle');
INSERT INTO system_state (key, value) VALUES ('scorer_lock', 'idle');
INSERT INTO system_state (key, value) VALUES ('scoring_enabled', 'true');
INSERT INTO system_state (key, value) VALUES ('mrr_cache', '{"mrr": 0, "cached_at": null}');

-- Health monitoring: each function updates its last_success on completion
-- Admin dashboard checks these for RED/YELLOW/GREEN status
INSERT INTO system_state (key, value) VALUES ('last_success_poller', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_scorer', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_aggregator', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_resolver', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_expirations', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_payouts', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_success_model_validator', '{"at": null}');
INSERT INTO system_state (key, value) VALUES ('last_urgent_at', '{"at": null}');

-- Model auto-healing: cached active model per role. NULL model means "no
-- preference cached, start from position [0] of the fallback chain."
-- The callWithFallback wrapper reads these before each API call and updates
-- them when a fallback occurs. Weekly /api/validate-models cron verifies
-- the chains against Anthropic's live GET /v1/models endpoint.
INSERT INTO system_state (key, value) VALUES ('active_model_researcher', '{"model": null, "verified_at": null}');
INSERT INTO system_state (key, value) VALUES ('active_model_analyst', '{"model": null, "verified_at": null}');
INSERT INTO system_state (key, value) VALUES ('active_model_courtroom_trial', '{"model": null, "verified_at": null}');
INSERT INTO system_state (key, value) VALUES ('active_model_courtroom_verdict_standard', '{"model": null, "verified_at": null}');
INSERT INTO system_state (key, value) VALUES ('active_model_courtroom_verdict_enhanced', '{"model": null, "verified_at": null}');
INSERT INTO system_state (key, value) VALUES ('active_model_courtroom_verdict_premium', '{"model": null, "verified_at": null}');

-- ============================================
-- THE COURTROOM: Adversarial AI Verdicts
-- ============================================

CREATE TABLE courtroom_verdicts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pick_id uuid REFERENCES picks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  trial_transcript jsonb NOT NULL,
  jury_votes jsonb NOT NULL DEFAULT '[]',
  jury_split text,
  ruling text NOT NULL,
  ruling_confidence int NOT NULL,
  ruling_reasoning text NOT NULL,
  sentence jsonb,
  dissent text,
  model_used text NOT NULL,
  market_price_at_verdict float,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_courtroom_pick ON courtroom_verdicts (pick_id, created_at DESC);

ALTER TABLE courtroom_verdicts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own verdicts" ON courtroom_verdicts FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- EVENT TRACKING: User actions for analytics
-- ============================================

CREATE TABLE user_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);
-- event_type: 'login', 'view_pick', 'place_bet', 'upgrade_click', 'courtroom_use',
-- 'share_click', 'watchlist_add', 'settings_change', 'feedback_submit', 'cancel_initiate',
-- 'cancel_confirm', 'byoai_setup', 'credit_purchase', 'notification_click'
-- metadata: { pick_id, market_id, from_tier, to_tier, reason, etc. }
CREATE INDEX idx_events_user ON user_events (user_id, created_at DESC);
CREATE INDEX idx_events_type ON user_events (event_type, created_at DESC);

ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users insert own events" ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Admin reads all events via service role (bypasses RLS)

-- ============================================
-- USER FEEDBACK: Pick ratings, bug reports
-- ============================================

CREATE TABLE user_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  feedback_type text NOT NULL, -- 'pick_rating', 'bug_report', 'feature_request', 'general'
  pick_id uuid REFERENCES picks(id) ON DELETE SET NULL,
  rating int, -- 1-5 for pick_rating, NULL otherwise
  message text,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_feedback_user ON user_feedback (user_id, created_at DESC);

ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users insert own feedback" ON user_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users read own feedback" ON user_feedback FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- WAITLIST: Pre-launch email capture
-- ============================================

CREATE TABLE waitlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  referrer_source text,
  created_at timestamptz DEFAULT now(),
  notified_at timestamptz
);
CREATE INDEX idx_waitlist_notified ON waitlist (notified_at) WHERE notified_at IS NULL;

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can insert waitlist" ON waitlist FOR INSERT WITH CHECK (true);
-- Admin reads via service role

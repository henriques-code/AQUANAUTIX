-- AQUANAUTIX Community — Fase 1
-- Tabelas: user_profiles, community_posts, community_reactions
-- Ghost Mode: NUNCA guardar coordenadas exactas — apenas zone_label (≥5km fuzzy)

CREATE TABLE IF NOT EXISTS user_profiles (
  id         uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   text NOT NULL UNIQUE,
  tier       text NOT NULL DEFAULT 'FREE' CHECK (tier IN ('FREE', 'PRO', 'ELITE')),
  avatar_url text,
  country    text NOT NULL DEFAULT 'PT' CHECK (country IN ('PT', 'ES')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_posts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  zone_label   text NOT NULL,
  photo_url    text NOT NULL,
  species      text NOT NULL,
  weight_kg    numeric(6,3),
  technique    text,
  caption      text,
  oracle_score integer CHECK (oracle_score BETWEEN 0 AND 100),
  is_legal     boolean NOT NULL DEFAULT true,
  country      text NOT NULL DEFAULT 'PT' CHECK (country IN ('PT', 'ES')),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_reactions (
  post_id  uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id  uuid NOT NULL REFERENCES auth.users(id)      ON DELETE CASCADE,
  PRIMARY KEY (post_id, user_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at
  ON community_posts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_posts_country
  ON community_posts(country, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_reactions_post_id
  ON community_reactions(post_id);

-- RLS
ALTER TABLE user_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_reactions ENABLE ROW LEVEL SECURITY;

-- user_profiles
CREATE POLICY "Public read profiles"
  ON user_profiles FOR SELECT USING (true);

CREATE POLICY "Own insert profile"
  ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Own update profile"
  ON user_profiles FOR UPDATE USING (auth.uid() = id);

-- community_posts
CREATE POLICY "Public read posts"
  ON community_posts FOR SELECT USING (true);

CREATE POLICY "Auth insert post"
  ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Own delete post"
  ON community_posts FOR DELETE USING (auth.uid() = user_id);

-- community_reactions
CREATE POLICY "Public read reactions"
  ON community_reactions FOR SELECT USING (true);

CREATE POLICY "Auth manage reactions"
  ON community_reactions FOR ALL USING (auth.uid() = user_id);

-- Bucket community-photos (executar no dashboard Supabase se não existir)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('community-photos', 'community-photos', true)
-- ON CONFLICT DO NOTHING;

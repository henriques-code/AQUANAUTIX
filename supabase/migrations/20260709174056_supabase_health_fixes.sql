-- AQUANAUTIX — Health fixes (Jul 2026)
-- Segurança RPC tier sync, limpeza RLS duplicadas, índices, initplan auth.uid()
-- Idempotente.

-- ─────────────────────────────────────────────────────────────
-- 1) SECURITY: sync_user_subscription_tier — só service_role
--    (REVOKE FROM PUBLIC não remove grants explícitos anon/authenticated)
-- ─────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.sync_user_subscription_tier(uuid, text) TO service_role;

-- PostGIS SECURITY DEFINER helpers — ver migration 20260709174100_postgis_rpc_hardening.sql

-- ─────────────────────────────────────────────────────────────
-- 2) PERFORMANCE: índice duplicado + FK sem índice
-- ─────────────────────────────────────────────────────────────

DROP INDEX IF EXISTS public.idx_analytics_events_name_created;

CREATE INDEX IF NOT EXISTS idx_community_posts_user_id
  ON public.community_posts (user_id);

CREATE INDEX IF NOT EXISTS idx_community_reactions_user_id
  ON public.community_reactions (user_id);

-- ─────────────────────────────────────────────────────────────
-- 3) app_insights — políticas SELECT duplicadas (FOR ALL → só writes)
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "app_insights_no_client_write" ON public.app_insights;
DROP POLICY IF EXISTS "app_insights_no_client_insert" ON public.app_insights;
DROP POLICY IF EXISTS "app_insights_no_client_update" ON public.app_insights;
DROP POLICY IF EXISTS "app_insights_no_client_delete" ON public.app_insights;

CREATE POLICY "app_insights_no_client_insert"
  ON public.app_insights FOR INSERT TO anon, authenticated
  WITH CHECK (false);

CREATE POLICY "app_insights_no_client_update"
  ON public.app_insights FOR UPDATE TO anon, authenticated
  USING (false) WITH CHECK (false);

CREATE POLICY "app_insights_no_client_delete"
  ON public.app_insights FOR DELETE TO anon, authenticated
  USING (false);

DROP POLICY IF EXISTS "app_insights_v2_no_client_write" ON public.app_insights_v2;
DROP POLICY IF EXISTS "app_insights_v2_no_client_insert" ON public.app_insights_v2;
DROP POLICY IF EXISTS "app_insights_v2_no_client_update" ON public.app_insights_v2;
DROP POLICY IF EXISTS "app_insights_v2_no_client_delete" ON public.app_insights_v2;

CREATE POLICY "app_insights_v2_no_client_insert"
  ON public.app_insights_v2 FOR INSERT TO anon, authenticated
  WITH CHECK (false);

CREATE POLICY "app_insights_v2_no_client_update"
  ON public.app_insights_v2 FOR UPDATE TO anon, authenticated
  USING (false) WITH CHECK (false);

CREATE POLICY "app_insights_v2_no_client_delete"
  ON public.app_insights_v2 FOR DELETE TO anon, authenticated
  USING (false);

-- ─────────────────────────────────────────────────────────────
-- 4) community_posts — remover duplicados + initplan
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Auth insert post" ON public.community_posts;
DROP POLICY IF EXISTS "Own delete post" ON public.community_posts;
DROP POLICY IF EXISTS "Public read posts" ON public.community_posts;
DROP POLICY IF EXISTS "community_posts_select_authenticated" ON public.community_posts;

DROP POLICY IF EXISTS "community_posts_select_all" ON public.community_posts;
CREATE POLICY "community_posts_select_all"
  ON public.community_posts FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "community_posts_insert_own" ON public.community_posts;
CREATE POLICY "community_posts_insert_own"
  ON public.community_posts FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "community_posts_delete_own" ON public.community_posts;
CREATE POLICY "community_posts_delete_own"
  ON public.community_posts FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ─────────────────────────────────────────────────────────────
-- 5) community_reactions — remover duplicados + initplan
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Auth manage reactions" ON public.community_reactions;
DROP POLICY IF EXISTS "Public read reactions" ON public.community_reactions;
DROP POLICY IF EXISTS "community_reactions_select_authenticated" ON public.community_reactions;
DROP POLICY IF EXISTS "community_reactions_manage_own" ON public.community_reactions;

DROP POLICY IF EXISTS "community_reactions_select_all" ON public.community_reactions;
CREATE POLICY "community_reactions_select_all"
  ON public.community_reactions FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "community_reactions_insert_own" ON public.community_reactions;
CREATE POLICY "community_reactions_insert_own"
  ON public.community_reactions FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "community_reactions_delete_own" ON public.community_reactions;
CREATE POLICY "community_reactions_delete_own"
  ON public.community_reactions FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ─────────────────────────────────────────────────────────────
-- 6) user_profiles — consolidar SELECT/UPDATE + initplan
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "user_profiles_select_for_social" ON public.user_profiles;
DROP POLICY IF EXISTS "user_profiles_select_own" ON public.user_profiles;
DROP POLICY IF EXISTS "Own update profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Public read profiles" ON public.user_profiles;

DROP POLICY IF EXISTS "user_profiles_select_all" ON public.user_profiles;
CREATE POLICY "user_profiles_select_all"
  ON public.user_profiles FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Own insert profile" ON public.user_profiles;
DROP POLICY IF EXISTS "user_profiles_insert_own" ON public.user_profiles;
CREATE POLICY "user_profiles_insert_own"
  ON public.user_profiles FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = id AND tier = 'FREE');

DROP POLICY IF EXISTS "user_profiles_update_own" ON public.user_profiles;
CREATE POLICY "user_profiles_update_own"
  ON public.user_profiles FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- ─────────────────────────────────────────────────────────────
-- 7) catch_photos — initplan
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "catch_photos_select_public_or_own" ON public.catch_photos;
CREATE POLICY "catch_photos_select_public_or_own"
  ON public.catch_photos FOR SELECT TO anon, authenticated
  USING (privacy = 'public' OR (select auth.uid()) = user_id);

DROP POLICY IF EXISTS "catch_photos_insert_own" ON public.catch_photos;
CREATE POLICY "catch_photos_insert_own"
  ON public.catch_photos FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "catch_photos_update_own" ON public.catch_photos;
CREATE POLICY "catch_photos_update_own"
  ON public.catch_photos FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "catch_photos_delete_own" ON public.catch_photos;
CREATE POLICY "catch_photos_delete_own"
  ON public.catch_photos FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ─────────────────────────────────────────────────────────────
-- 8) analytics_events — initplan (authenticated insert)
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "analytics_events_client_insert" ON public.analytics_events;
CREATE POLICY "analytics_events_client_insert"
  ON public.analytics_events FOR INSERT TO authenticated
  WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────
-- 9) fishing_spots — initplan em policies PRO/ELITE
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "pro spots for pro and elite users" ON public.fishing_spots;
CREATE POLICY "pro spots for pro and elite users"
  ON public.fishing_spots FOR SELECT
  USING (
    tier = 'pro'
    AND EXISTS (
      SELECT 1
      FROM public.user_profiles up
      WHERE up.id = (select auth.uid())
        AND up.tier IN ('PRO', 'ELITE', 'pro', 'elite')
    )
  );

DROP POLICY IF EXISTS "elite spots for elite users only" ON public.fishing_spots;
CREATE POLICY "elite spots for elite users only"
  ON public.fishing_spots FOR SELECT
  USING (
    tier = 'elite'
    AND EXISTS (
      SELECT 1
      FROM public.user_profiles up
      WHERE up.id = (select auth.uid())
        AND up.tier IN ('ELITE', 'elite')
    )
  );

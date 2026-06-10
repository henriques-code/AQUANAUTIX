-- AQUANAUTIX — Security hardening (RLS + storage + tier escalation)
-- Idempotente — aplicar após migrations anteriores.

-- ─────────────────────────────────────────────────────────────
-- 1) catch_photos: SELECT não expor private/friends a terceiros
--    (antes: USING (true) — qualquer cliente lia lat/lng exactos)
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "catch_photos_select_all" ON public.catch_photos;

DROP POLICY IF EXISTS "catch_photos_select_public_or_own" ON public.catch_photos;
CREATE POLICY "catch_photos_select_public_or_own"
  ON public.catch_photos
  FOR SELECT
  TO anon, authenticated
  USING (
    privacy = 'public'
    OR auth.uid() = user_id
  );

-- UPDATE: impedir alterar user_id ou reabrir privacidade alheia
DROP POLICY IF EXISTS "catch_photos_update_own" ON public.catch_photos;
CREATE POLICY "catch_photos_update_own"
  ON public.catch_photos
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- 2) user_profiles: bloquear auto-escalação FREE → PRO/ELITE
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Own insert profile" ON public.user_profiles;
CREATE POLICY "Own insert profile"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id AND tier = 'FREE');

CREATE OR REPLACE FUNCTION public.user_profiles_prevent_tier_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.tier IS DISTINCT FROM OLD.tier THEN
    IF current_setting('request.jwt.claim.role', true) IS DISTINCT FROM 'service_role' THEN
      NEW.tier := OLD.tier;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_profiles_prevent_tier_escalation ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_prevent_tier_escalation
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.user_profiles_prevent_tier_escalation();

-- ─────────────────────────────────────────────────────────────
-- 3) analytics_events: limitar INSERT anónimo (spam)
--    Autenticados mantêm insert; anon só com source=flutter_app
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "analytics_events_client_insert" ON public.analytics_events;
CREATE POLICY "analytics_events_client_insert"
  ON public.analytics_events
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "analytics_events_anon_insert_limited" ON public.analytics_events;
CREATE POLICY "analytics_events_anon_insert_limited"
  ON public.analytics_events
  FOR INSERT
  TO anon
  WITH CHECK (source = 'flutter_app');

-- Mover trigger analytics para schema interno (menos superfície public)
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.analytics_events_set_user_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
BEGIN
  IF NEW.user_id IS NULL AND auth.uid() IS NOT NULL THEN
    NEW.user_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_analytics_events_set_user_id ON public.analytics_events;
CREATE TRIGGER trg_analytics_events_set_user_id
  BEFORE INSERT ON public.analytics_events
  FOR EACH ROW
  EXECUTE FUNCTION private.analytics_events_set_user_id();

DROP FUNCTION IF EXISTS public.analytics_events_set_user_id();

-- ─────────────────────────────────────────────────────────────
-- 4) Storage: buckets + políticas mínimas (paths por user_id)
-- ─────────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('catch-photos', 'catch-photos', true),
  ('community-photos', 'community-photos', true)
ON CONFLICT (id) DO NOTHING;

-- catch-photos: leitura pública; escrita só na pasta auth.uid()/
DROP POLICY IF EXISTS "catch_photos_storage_public_read" ON storage.objects;
CREATE POLICY "catch_photos_storage_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'catch-photos');

DROP POLICY IF EXISTS "catch_photos_storage_auth_insert" ON storage.objects;
CREATE POLICY "catch_photos_storage_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'catch-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "catch_photos_storage_auth_update" ON storage.objects;
CREATE POLICY "catch_photos_storage_auth_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'catch-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'catch-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "catch_photos_storage_auth_delete" ON storage.objects;
CREATE POLICY "catch_photos_storage_auth_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'catch-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- community-photos: mesma regra — path deve começar com user_id
DROP POLICY IF EXISTS "community_photos_storage_public_read" ON storage.objects;
CREATE POLICY "community_photos_storage_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'community-photos');

DROP POLICY IF EXISTS "community_photos_storage_auth_insert" ON storage.objects;
CREATE POLICY "community_photos_storage_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'community-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "community_photos_storage_auth_update" ON storage.objects;
CREATE POLICY "community_photos_storage_auth_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'community-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'community-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "community_photos_storage_auth_delete" ON storage.objects;
CREATE POLICY "community_photos_storage_auth_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'community-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

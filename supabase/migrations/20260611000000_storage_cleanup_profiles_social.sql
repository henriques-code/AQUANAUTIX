-- AQUANAUTIX — Limpeza Storage legado + perfis legíveis na comunidade/mapa
-- Idempotente.

-- ─────────────────────────────────────────────────────────────
-- 1) Storage: remover políticas legadas catch-photos (OR permissivo)
--    Mantém catch_photos_storage_* (pasta auth.uid()/)
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "catch_photos_upload" ON storage.objects;
DROP POLICY IF EXISTS "catch_photos_delete_own" ON storage.objects;
DROP POLICY IF EXISTS "catch_photos_authenticated_read" ON storage.objects;

-- ─────────────────────────────────────────────────────────────
-- 2) user_profiles: leitura social para feed comunidade + mapa
--    tier visível (badge) mas escalacao bloqueada pelo trigger existente
-- ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "user_profiles_select_for_social" ON public.user_profiles;
CREATE POLICY "user_profiles_select_for_social"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (true);

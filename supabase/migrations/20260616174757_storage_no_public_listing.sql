-- AQUANAUTIX — Storage: impedir listagem pública de buckets (lint 0025)
-- Buckets permanecem públicos: getPublicUrl() continua a funcionar sem SELECT em storage.objects.
-- Autenticados mantêm leitura/gestão só na pasta auth.uid()/ (upsert/delete).

-- catch-photos
DROP POLICY IF EXISTS "catch_photos_storage_public_read" ON storage.objects;

DROP POLICY IF EXISTS "catch_photos_storage_auth_read_own" ON storage.objects;
CREATE POLICY "catch_photos_storage_auth_read_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'catch-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- community-photos
DROP POLICY IF EXISTS "community_photos_storage_public_read" ON storage.objects;

DROP POLICY IF EXISTS "community_photos_storage_auth_read_own" ON storage.objects;
CREATE POLICY "community_photos_storage_auth_read_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'community-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

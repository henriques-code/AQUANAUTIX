-- =============================================
-- AQUANAUTIX — catch_photos migration (v2 corrigida)
-- =============================================

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS catch_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  photo_url   TEXT NOT NULL,
  species     TEXT,
  weight_kg   NUMERIC(6,3),
  length_cm   NUMERIC(6,1),
  notes       TEXT,
  lure_type   TEXT,
  technique   TEXT,
  privacy     TEXT NOT NULL DEFAULT 'public'
              CHECK (privacy IN ('public', 'friends', 'private')),
  location    GEOMETRY(Point, 4326) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS catch_photos_location_idx
  ON catch_photos USING GIST (location);

CREATE INDEX IF NOT EXISTS catch_photos_user_idx
  ON catch_photos(user_id);

ALTER TABLE catch_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "catch_photos_select_all" ON catch_photos;
CREATE POLICY "catch_photos_select_all"
  ON catch_photos FOR SELECT USING (true);

DROP POLICY IF EXISTS "catch_photos_insert_own" ON catch_photos;
CREATE POLICY "catch_photos_insert_own"
  ON catch_photos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "catch_photos_update_own" ON catch_photos;
CREATE POLICY "catch_photos_update_own"
  ON catch_photos FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "catch_photos_delete_own" ON catch_photos;
CREATE POLICY "catch_photos_delete_own"
  ON catch_photos FOR DELETE
  USING (auth.uid() = user_id);

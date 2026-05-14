-- =============================================
-- AQUANAUTIX — catch_photos: lat/lng + trigger
-- PostgREST não aceita EWKT directo em geometry;
-- o cliente envia lat/lng e o trigger preenche location.
-- =============================================

ALTER TABLE catch_photos
  ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;

CREATE OR REPLACE FUNCTION public.set_catch_location()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_catch_location ON catch_photos;

CREATE TRIGGER trg_set_catch_location
  BEFORE INSERT OR UPDATE ON catch_photos
  FOR EACH ROW
  EXECUTE FUNCTION public.set_catch_location();

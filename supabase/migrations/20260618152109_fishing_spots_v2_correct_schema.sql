-- Recria fishing_spots com schema completo (supercede 20260617000000).
-- Aplicada directamente via MCP Supabase em 2026-06-18.

DROP TABLE IF EXISTS fishing_spots CASCADE;

CREATE TABLE fishing_spots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  lat FLOAT NOT NULL,
  lon FLOAT NOT NULL,
  location geography(Point,4326) GENERATED ALWAYS AS (ST_MakePoint(lon, lat)) STORED,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free','pro','elite')),
  country TEXT NOT NULL CHECK (country IN ('PT','ES')),
  region TEXT,
  zone_type TEXT,
  species TEXT[] DEFAULT '{}',
  best_season TEXT[] DEFAULT '{}',
  best_bait TEXT[] DEFAULT '{}',
  depth_min FLOAT,
  depth_max FLOAT,
  bottom_type TEXT,
  car_access BOOL DEFAULT true,
  trail_access BOOL DEFAULT true,
  difficulty INT DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5),
  score_avg FLOAT DEFAULT 70,
  photos TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON fishing_spots USING GIST (location);
ALTER TABLE fishing_spots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "free spots public" ON fishing_spots
  FOR SELECT USING (tier = 'free');

CREATE POLICY "pro spots for pro users" ON fishing_spots
  FOR SELECT USING (tier = 'pro' AND auth.role() = 'authenticated');

CREATE POLICY "elite spots for elite users" ON fishing_spots
  FOR SELECT USING (tier = 'elite' AND auth.role() = 'authenticated');

-- Seed 5 spots PT/ES
INSERT INTO fishing_spots (name,lat,lon,country,region,zone_type,tier,species,best_season,best_bait,difficulty,score_avg)
VALUES
  ('Barragem de Alqueva',38.2,-7.5,'PT','Alentejo','barragem','free',
   ARRAY['Achigã','Carpa'],ARRAY['Primavera','Verão'],ARRAY['Shad','Minhoca'],2,82),
  ('Praia de Sesimbra',38.44,-9.1,'PT','Setúbal','costa','free',
   ARRAY['Robalo','Sargo','Corvina'],ARRAY['Outono','Inverno'],ARRAY['Lula','Minhoca'],2,78),
  ('Rio Mondego — Coimbra',40.2,-8.4,'PT','Centro','rio','free',
   ARRAY['Barbo','Achigã','Enguia'],ARRAY['Primavera','Outono'],ARRAY['Milho','Minhoca'],1,71),
  ('Cabo Espichel',38.41,-9.22,'PT','Setúbal','costa','pro',
   ARRAY['Corvina','Sargo','Robalo'],ARRAY['Inverno','Outono'],ARRAY['Lula','Sardineta'],4,85),
  ('Delta del Ebro',40.7,0.9,'ES','Tarragona','rio','pro',
   ARRAY['Lúcio','Lucioperca','Carpa'],ARRAY['Primavera','Verão'],ARRAY['Jig','Minhoca'],2,79);

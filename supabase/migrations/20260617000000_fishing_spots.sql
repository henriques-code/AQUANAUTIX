CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE fishing_spots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  lat FLOAT NOT NULL, lon FLOAT NOT NULL,
  location geography(Point,4326) GENERATED ALWAYS AS (ST_MakePoint(lon, lat)) STORED,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free','pro','elite')),
  country TEXT NOT NULL CHECK (country IN ('PT','ES')),
  region TEXT, zone_type TEXT,
  species TEXT[] DEFAULT '{}',
  best_season TEXT[] DEFAULT '{}',
  best_bait TEXT[] DEFAULT '{}',
  depth_min FLOAT, depth_max FLOAT, bottom_type TEXT,
  car_access BOOL DEFAULT true, trail_access BOOL DEFAULT true,
  difficulty INT DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5),
  score_avg FLOAT DEFAULT 70, photos TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON fishing_spots USING GIST (location);
ALTER TABLE fishing_spots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "free spots public" ON fishing_spots FOR SELECT USING (tier = 'free');

-- Seed 5 spots reais PT
INSERT INTO fishing_spots (name,lat,lon,country,region,zone_type,tier,species,best_season,best_bait,difficulty,score_avg)
VALUES
  ('Barragem de Alqueva',38.2,-7.5,'PT','Alentejo','barragem','free','{"Achigã","Carpa"}','{"Primavera"}','{"Shad","Minhoca"}',2,82),
  ('Praia de Sesimbra',38.44,-9.1,'PT','Setúbal','costa','free','{"Robalo","Sargo"}','{"Outono"}','{"Lula"}',2,78),
  ('Rio Mondego Coimbra',40.2,-8.4,'PT','Centro','rio','free','{"Barbo","Achigã"}','{"Primavera"}','{"Milho"}',1,71),
  ('Cabo Espichel',38.41,-9.22,'PT','Setúbal','costa','pro','{"Corvina","Robalo"}','{"Inverno"}','{"Lula"}',4,85),
  ('Delta del Ebro',40.7,0.9,'ES','Tarragona','rio','pro','{"Lúcio","Carpa"}','{"Primavera"}','{"Jig"}',2,79);

-- Corrige RLS de fishing_spots: policies PRO/ELITE passam a verificar
-- user_profiles.tier em vez de apenas auth.role() = 'authenticated'.
-- Spots FREE continuam públicos (anon + authenticated).
-- Corrige achado médio do security review (Jun 2026).

-- Remover policies desalinhadas
DROP POLICY IF EXISTS "pro spots for pro users"    ON fishing_spots;
DROP POLICY IF EXISTS "elite spots for elite users" ON fishing_spots;

-- PRO: tier PRO ou ELITE em user_profiles
CREATE POLICY "pro spots for pro and elite users"
  ON fishing_spots
  FOR SELECT
  USING (
    tier = 'pro'
    AND EXISTS (
      SELECT 1
      FROM user_profiles up
      WHERE up.id = auth.uid()
        AND up.tier IN ('PRO', 'ELITE', 'pro', 'elite')
    )
  );

-- ELITE: apenas tier ELITE em user_profiles
CREATE POLICY "elite spots for elite users only"
  ON fishing_spots
  FOR SELECT
  USING (
    tier = 'elite'
    AND EXISTS (
      SELECT 1
      FROM user_profiles up
      WHERE up.id = auth.uid()
        AND up.tier IN ('ELITE', 'elite')
    )
  );

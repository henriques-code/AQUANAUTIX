-- AQUANAUTIX — Endurecimento PostGIS + GraphQL (24 Set 2026)
-- 1) public.spatial_ref_sys pertence a supabase_admin: não dá para activar RLS nem revogar
--    os grants (anon/authenticated têm INSERT/UPDATE/DELETE/TRUNCATE via REST).
--    O role postgres tem privilégio TRIGGER, por isso bloqueia-se qualquer escrita
--    que não venha de postgres/supabase_admin (upgrades do PostGIS continuam a funcionar).
-- 2) pg_graphql desactivado: a app usa só REST/RPC. Reversível com: CREATE EXTENSION pg_graphql;

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.block_spatial_ref_sys_writes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF current_user NOT IN ('postgres', 'supabase_admin') THEN
    RAISE EXCEPTION 'spatial_ref_sys is read-only' USING ERRCODE = '42501';
  END IF;
  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION private.block_spatial_ref_sys_writes() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_block_spatial_ref_sys_writes ON public.spatial_ref_sys;
CREATE TRIGGER trg_block_spatial_ref_sys_writes
  BEFORE INSERT OR UPDATE OR DELETE ON public.spatial_ref_sys
  FOR EACH STATEMENT EXECUTE FUNCTION private.block_spatial_ref_sys_writes();

DROP TRIGGER IF EXISTS trg_block_spatial_ref_sys_truncate ON public.spatial_ref_sys;
CREATE TRIGGER trg_block_spatial_ref_sys_truncate
  BEFORE TRUNCATE ON public.spatial_ref_sys
  FOR EACH STATEMENT EXECUTE FUNCTION private.block_spatial_ref_sys_writes();

DROP EXTENSION IF EXISTS pg_graphql;

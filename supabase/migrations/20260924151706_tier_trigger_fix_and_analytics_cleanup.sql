-- AQUANAUTIX — Correcções de segurança (24 Set 2026)
-- 1) Trigger anti-escalação de tier: passa a ler o role em request.jwt.claims (JSON),
--    mantendo o GUC legacy como fallback. Utilizadores continuam bloqueados;
--    service_role (Edge Functions RevenueCat -> sync_user_subscription_tier) passa a conseguir actualizar.
-- 2) analytics_events: a regra created_at := now() (migração 20260901160627) tinha sido aplicada
--    à função em public, mas o trigger usa private.analytics_events_set_user_id(). Move-se a regra
--    para a função correcta e remove-se a cópia em public (SECURITY DEFINER exposta via /rpc).

CREATE OR REPLACE FUNCTION public.user_profiles_prevent_tier_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_role text;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.tier IS DISTINCT FROM OLD.tier THEN
    v_role := coalesce(
      nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
      nullif(current_setting('request.jwt.claim.role', true), '')
    );
    IF v_role IS DISTINCT FROM 'service_role' THEN
      NEW.tier := OLD.tier;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.analytics_events_set_user_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
BEGIN
  IF NEW.user_id IS NULL AND auth.uid() IS NOT NULL THEN
    NEW.user_id := auth.uid();
  END IF;
  NEW.created_at := now();
  RETURN NEW;
END;
$$;

DROP FUNCTION IF EXISTS public.analytics_events_set_user_id();

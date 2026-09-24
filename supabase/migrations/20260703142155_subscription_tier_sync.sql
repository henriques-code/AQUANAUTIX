-- AQUANAUTIX — Sincronização tier user_profiles via RevenueCat (service_role / Edge Functions)
-- Permite actualizar tier após compra sem bypass client-side do trigger anti-escalação.

CREATE OR REPLACE FUNCTION public.sync_user_subscription_tier(
  p_user_id uuid,
  p_tier text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier text;
  v_username text;
  v_base_username text;
  v_suffix int := 0;
BEGIN
  v_tier := upper(trim(p_tier));
  IF v_tier NOT IN ('FREE', 'PRO', 'ELITE') THEN
    RAISE EXCEPTION 'Invalid tier: %', p_tier;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = p_user_id) THEN
    SELECT COALESCE(
      nullif(trim(raw_user_meta_data->>'username'), ''),
      'angler_' || left(replace(p_user_id::text, '-', ''), 8)
    )
    INTO v_base_username
    FROM auth.users
    WHERE id = p_user_id;

    v_username := v_base_username;

    WHILE EXISTS (SELECT 1 FROM user_profiles WHERE username = v_username) LOOP
      v_suffix := v_suffix + 1;
      v_username := v_base_username || '_' || v_suffix::text;
    END LOOP;

    INSERT INTO user_profiles (id, username, tier, country)
    VALUES (p_user_id, v_username, v_tier, 'PT')
    ON CONFLICT (id) DO NOTHING;
  ELSE
    UPDATE user_profiles
    SET tier = v_tier
    WHERE id = p_user_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.sync_user_subscription_tier(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.sync_user_subscription_tier(uuid, text) TO service_role;

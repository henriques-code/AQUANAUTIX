-- AQUANAUTIX — analytics_events (funil, paywall, North Star)
-- Cliente: lib/core/services/analytics_service.dart
-- Idempotente — safe to re-run.

CREATE TABLE IF NOT EXISTS public.analytics_events (
  id         bigserial PRIMARY KEY,
  event_name text NOT NULL,
  params     jsonb NOT NULL DEFAULT '{}'::jsonb,
  source     text NOT NULL DEFAULT 'flutter_app',
  user_id    uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at
  ON public.analytics_events (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_event_name
  ON public.analytics_events (event_name, created_at DESC);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "analytics_events_client_insert" ON public.analytics_events;
CREATE POLICY "analytics_events_client_insert"
  ON public.analytics_events
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "analytics_events_no_client_read" ON public.analytics_events;
CREATE POLICY "analytics_events_no_client_read"
  ON public.analytics_events
  FOR SELECT
  TO anon, authenticated
  USING (false);

-- Opcional: preencher user_id quando autenticado (trigger)
CREATE OR REPLACE FUNCTION public.analytics_events_set_user_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NULL AND auth.uid() IS NOT NULL THEN
    NEW.user_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_analytics_events_set_user_id ON public.analytics_events;
CREATE TRIGGER trg_analytics_events_set_user_id
  BEFORE INSERT ON public.analytics_events
  FOR EACH ROW
  EXECUTE FUNCTION public.analytics_events_set_user_id();

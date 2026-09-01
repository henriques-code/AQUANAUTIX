-- P7 (Etapa 2): analytics_events tinha WITH CHECK (true) sem qualquer limite ->
-- qualquer pedido com a anon key (pública, extraível do APK) podia inserir
-- event_name arbitrário, params jsonb sem limite de tamanho, ou created_at
-- falsificado. Objetivo: reduzir abuso óbvio sem exigir autenticação (guests
-- são telemetria legítima) e sem tocar nos dados existentes.

-- 1) event_name restrito à taxonomia real de lib/core/services/analytics_service.dart
--    (AnalyticsEvents) -- todas as chamadas .track() no cliente usam estas constantes,
--    nenhuma string dinâmica.
ALTER TABLE public.analytics_events DROP CONSTRAINT IF EXISTS analytics_events_event_name_allowed;
ALTER TABLE public.analytics_events
  ADD CONSTRAINT analytics_events_event_name_allowed
  CHECK (event_name IN (
    'app_open',
    'onboarding_complete',
    'paywall_view',
    'paywall_dismiss',
    'paywall_plan_selected',
    'trial_start',
    'purchase_success',
    'subscription_changed',
    'north_star_oracle_view',
    'mission_started',
    'mission_completed',
    'tab_change',
    'module_open',
    'growth_dashboard_view',
    'assistant_open',
    'assistant_photo_send',
    'assistant_voice_used',
    'map_to_oracle',
    'tides_calendar_open',
    'tides_gps_refresh',
    'tides_port_selected',
    'tides_offset_set',
    'bait_radar_open',
    'bait_radar_search',
    'recfishing_intro_view',
    'recfishing_intro_complete',
    'recfishing_logbook_link_open'
  )) NOT VALID;
-- NOT VALID: não reavalia linhas históricas (não apaga/rejeita dados existentes),
-- só passa a aplicar-se a novos INSERTs a partir de agora.

-- 2) source restrito ao único valor usado hoje pelo cliente
ALTER TABLE public.analytics_events DROP CONSTRAINT IF EXISTS analytics_events_source_allowed;
ALTER TABLE public.analytics_events
  ADD CONSTRAINT analytics_events_source_allowed
  CHECK (source IN ('flutter_app')) NOT VALID;

-- 3) limite de tamanho do payload jsonb (8KB - generoso vs. AnalyticsContext.baseParams()
--    + params de evento, que são sempre poucas chaves curtas)
ALTER TABLE public.analytics_events DROP CONSTRAINT IF EXISTS analytics_events_params_size;
ALTER TABLE public.analytics_events
  ADD CONSTRAINT analytics_events_params_size
  CHECK (pg_column_size(params) <= 8192) NOT VALID;

-- 4) created_at deixa de confiar no valor enviado pelo cliente (podia ser usado
--    para inserir eventos com timestamp falso/futuro/passado, poluindo
--    dashboards). Mesmo padrão já usado para user_id (trigger existente).
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
  NEW.created_at := now();
  RETURN NEW;
END;
$$;

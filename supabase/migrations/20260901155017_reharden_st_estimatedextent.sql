-- Reaplicação de 20260709174136_postgis_rpc_hardening: as permissões de EXECUTE
-- em public.st_estimatedextent voltaram a PUBLIC/anon/authenticated (provável
-- reset por upgrade da extensão PostGIS gerido pela Supabase). A app nunca chama
-- esta função (confirmado: nenhuma chamada .rpc('st_estimatedextent...') no cliente
-- Flutter, único RPC usado é get_app_insights_v2). Reduzir para service_role/postgres
-- apenas não quebra mapas/PostGIS porque queries espaciais normais (ST_DWithin,
-- índices GIST) não invocam st_estimatedextent.
--
-- NOTA (Etapa 2, Set 2026): esta migration foi aplicada com sucesso (sem erro),
-- mas verificação posterior confirmou que o REVOKE NÃO teve efeito prático —
-- as três overloads continuam executáveis por anon/authenticated. Causa: as
-- concessões foram feitas pelo role `supabase_admin` (verdadeiro superuser
-- desta plataforma Supabase); o role `postgres` usado nas migrations não é
-- superuser aqui e não tem permissão para revogar grants concedidos por outro
-- role. Corrigir isto requer intervenção da Supabase (suporte) a correr o
-- REVOKE como supabase_admin, ou mover a extensão PostGIS para fora do schema
-- public (alto risco, fora do âmbito desta etapa). Ver relatório da Etapa 2.
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text, boolean) FROM PUBLIC, anon, authenticated;

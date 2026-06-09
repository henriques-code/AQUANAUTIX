# AQUANAUTIX - Security Deploy Checklist

Checklist operacional para manter o hardening de seguranca consistente em todos os ambientes.

## 1) Variaveis de ambiente obrigatorias

Edge Functions (`oracle`, `vision-identify`, `market-recommendations`, `market-track-click`) exigem:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`
- `APP_ORIGIN` (recomendado: `https://aquanautix.vercel.app`)

Notas:
- Nunca expor `SUPABASE_SERVICE_ROLE_KEY` no cliente.
- Nunca empacotar `.env` em assets de build.

## 2) Migracoes SQL

### No repo (`supabase/migrations/`) — aplicar com `supabase db push` ou SQL Editor

| Ficheiro | Notas |
|----------|-------|
| `20260427_app_insights.sql` | Insights v1 (jsonb) |
| `20260427_app_insights_v2.sql` | Insights v2 + seed |
| `20260503_community.sql` | Comunidade Ghost + RLS |
| `20260512000000_catch_photos.sql` | PostGIS + RLS |
| `20260512000001_catch_photos_lat_lng.sql` | Trigger lat/lng |
| `20260609000000_analytics_events.sql` | Analytics funil (RLS insert-only cliente) |

Guia completo: `supabase/README_setup.md`.

### Referenciadas mas ainda nao versionadas no repo

- `supabase/migrations/202604150001_create_function_rate_limits.sql`
- `supabase/migrations/202604150002_market_mvp_backend.sql`

Quando existirem, validar:

- Tabela `public.function_rate_limits` com RLS (anon/authenticated sem acesso directo)

## 3) Deploy de Edge Functions

**Estado:** pasta `supabase/functions/` ainda nao existe neste repo. Quando adicionada, publicar:

- `supabase/functions/oracle/index.ts`
- `supabase/functions/vision-identify/index.ts`
- `supabase/functions/market-recommendations/index.ts`
- `supabase/functions/market-track-click/index.ts`

Verificar no ambiente:

- `oracle` exige `Authorization: Bearer ...`
- `oracle` rejeita origem diferente de `APP_ORIGIN`
- `oracle` aplica limite de tamanho de pergunta e timeout
- `oracle` devolve `429` quando excede rate limit
- `vision-identify` so aceita `storage_path` com prefixo `vision/<user_id>/`
- `market-recommendations` exige auth e devolve top produtos por contexto
- `market-track-click` exige auth e regista clique por `product_id`

## 4) Verificacao funcional pos-deploy

Executar smoke tests:

1. Login valido -> pedido ao `oracle` retorna `200`.
2. Pedido sem token -> `401`.
3. Origem nao permitida -> `403` (quando aplicavel).
4. Prompt gigante (>4000 chars) -> `413`.
5. Burst de pedidos (>12/min por user) -> `429`.
6. `vision-identify` com path de outro user -> `403`.
7. `vision-identify` com path proprio -> `200`.

## 5) Privacidade de spots (frontend)

Confirmar em build:

- `map_screen`: Free mostra coordenadas com menor precisao; PRO detalhado.
- `maps/map_page`: ofuscacao de spots secretos mais agressiva em Free.

## 6) Monitorizacao minima recomendada

- Alertar para picos de `429` e `5xx` em `oracle`.
- Alertar para `403` anormais em `vision-identify`.
- Rever volume/token spend de OpenAI por dia.

## 7) Rollback rapido

Se houver incidente:

1. Desativar chamadas IA no cliente (feature flag).
2. Reverter functions para versao anterior estavel.
3. Manter bloqueios de auth/cors ativos (nao abrir endpoint).
4. Reavaliar logs sem expor segredos.

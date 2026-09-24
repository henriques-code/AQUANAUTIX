# Prompt para o Cursor — Segurança Supabase (24 Set 2026)

> Colar no chat do Cursor em modo **Agent**, numa conversa nova.
> Pré-requisito: MCP `supabase-readonly` ligado (Settings → Tools & MCP → Login) e o `supabase` do plugin desligado.

---

```
Contexto: sessão de segurança Supabase feita a 24 Set 2026 (fora do Cursor). Preciso que fiques a par do estado actual e prepares o terreno para os próximos passos. NÃO escrevas nem alteres código nesta sessão — só leitura e relatório.

## 1. O que já foi corrigido em produção (projecto ycmvqokcfzxkpinvcyhk)
Migrações já aplicadas e presentes no repo:
- supabase/migrations/20260924151706_tier_trigger_fix_and_analytics_cleanup.sql
- supabase/migrations/20260924152102_spatial_ref_sys_guard_and_disable_graphql.sql

Alterações:
a) Trigger `user_profiles_prevent_tier_escalation`: passou a ler o role em `request.jwt.claims` (JSON), com fallback para o GUC legacy. Utilizadores continuam impedidos de mudar o próprio `tier`; o service_role (Edge Functions `revenuecat-webhook` e `sync-subscription-tier` → RPC `sync_user_subscription_tier`) passa a conseguir. Antes, com o GUC legacy, o webhook provavelmente não conseguia promover o tier após compra.
b) Analytics: a regra `created_at := now()` (migração 20260901160627) tinha ficado na função errada (`public`), mas o trigger usa `private.analytics_events_set_user_id()`. Regra movida para a função certa; cópia em `public` removida (estava exposta via /rpc como SECURITY DEFINER).
c) `public.spatial_ref_sys`: anon e authenticated tinham INSERT/UPDATE/DELETE/TRUNCATE via REST (tabela do supabase_admin, sem RLS possível). Adicionado trigger `trg_block_spatial_ref_sys_writes` (+ truncate) que bloqueia escritas de quem não seja postgres/supabase_admin. Testado: DELETE como anon é recusado; SRID 4326 e cálculos de distância OK.
d) `pg_graphql` desactivado (a app usa só REST/RPC). Reversível com `CREATE EXTENSION pg_graphql;`.

Invariantes a respeitar a partir de agora:
- Nunca actualizar `user_profiles.tier` a partir da app. Tier só via service_role.
- Nunca recriar `public.analytics_events_set_user_id()`.
- Não introduzir chamadas GraphQL.

Avisos do Security Advisor que ficam e são aceites (não tentar corrigir):
- `spatial_ref_sys` sem RLS (tabela do supabase_admin; escrita já bloqueada).
- PostGIS no schema public (não suporta SET SCHEMA; mover apagaria colunas geography/geometry).
- `st_estimatedextent` executável por anon/authenticated (grants do supabase_admin; só o suporte Supabase revoga).
- "Leaked password protection" — o João activa no dashboard (Authentication → Passwords).

## 2. Pendente — NÃO implementar agora
Cada ponto terá sessão própria (plano → migração + Flutter → teste no dispositivo WWZLYDXWYXT8PV5D → commit):
P1. `catch_photos` com privacy='public' expõem `lat`, `lng` e `location` exactos a anon → contraria Ghost Mode.
P2. Bucket `catch-photos` é público e sem `file_size_limit` nem `allowed_mime_types` → passar a privado com signed URLs + limites (ex.: 5 MB, image/jpeg,png,heic,webp como o `community-photos`).
P3. `user_profiles` legível por anon (username, tier, country).
P4. `analytics_events`: política `analytics_events_client_insert` com `WITH CHECK (true)` para authenticated.

## 3. A tua tarefa (só leitura)
1. Usa o MCP `supabase-readonly` para confirmar que as alterações da secção 1 estão activas (triggers em user_profiles e spatial_ref_sys, ausência de public.analytics_events_set_user_id, pg_graphql inexistente). Se algo não bater certo, pára e reporta.
2. Mapeia no código Flutter (`lib/`) o impacto de cada ponto pendente:
   - P1: onde a app lê `lat`/`lng`/`location` de `catch_photos` de OUTROS utilizadores (mapa, comunidade, perfil público).
   - P2: onde usa `getPublicUrl`, URLs directos do bucket `catch-photos`, e se comprime imagens antes do upload (tamanho típico).
   - P3: onde lê `user_profiles` sem sessão iniciada (feed Ghost demo, `community_public_profile.dart`, etc.).
   - P4: que eventos envia e se algum depende de campos que uma política mais restrita bloquearia.
3. Resposta em PT-PT, curta: para cada P1–P4 → ficheiros:linhas afectados, risco de regressão, esforço (S/M/L) e ordem recomendada. Sem código, sem refactors, sem novos .md.
```

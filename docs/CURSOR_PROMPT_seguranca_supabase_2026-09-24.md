# Prompt para o Cursor — Estado após sessão de segurança (24 Set 2026)

> Colar no chat do Cursor em modo **Agent**, numa conversa nova.
> Pré-requisito: MCP `supabase-readonly` em **Connected**.

---

```
Contexto: sessão de segurança e configuração feita a 24 Set 2026 (fora do Cursor, com Claude). Preciso que fiques a par do estado actual e prepares o terreno para os próximos passos.
REGRA DESTA SESSÃO: só leitura e relatório. NÃO alteres código, NÃO faças commits, NÃO corras migrações, NÃO mexas em ficheiros.

## 1. Configuração do Cursor (feito)
- Regras novas em .cursor/rules/: `engenheiro-senior.mdc` (postura sénior, sempre activa) e `flutter-supabase-senior.mdc` (Flutter/Supabase; inclui secção "Estado de segurança Supabase (24 Set 2026)"). As regras AQUANAUTIX existentes prevalecem (AUTORIZO para design, Site V2 em pausa, diff mínimo).
- MCP `supabase-readonly` em .cursor/mcp.json → https://mcp.supabase.com/mcp?project_ref=ycmvqokcfzxkpinvcyhk&read_only=true (autenticado, só leitura, só este projecto). O .cursor/mcp.json está no .gitignore — é local, não vai para o repo.
- MCP `supabase` do plugin: desactivado (skills do plugin mantêm-se). MCP `supabase` (User, config global): desactivado.
- Nunca usar nem reactivar um MCP Supabase com escrita.

## 2. Base de dados — corrigido e aplicado em produção (projecto ycmvqokcfzxkpinvcyhk)
Migrações no repo:
- supabase/migrations/20260924151706_tier_trigger_fix_and_analytics_cleanup.sql
- supabase/migrations/20260924152102_spatial_ref_sys_guard_and_disable_graphql.sql

a) Trigger `user_profiles_prevent_tier_escalation`: lê o role em `request.jwt.claims` (fallback GUC legacy). Utilizadores não mudam o próprio tier; service_role (Edge Functions revenuecat-webhook / sync-subscription-tier → RPC sync_user_subscription_tier) consegue. Ainda NÃO testado com compra real — validar na primeira compra sandbox RevenueCat.
b) Analytics: `created_at := now()` passou para `private.analytics_events_set_user_id()` (a função que o trigger usa). Removida a cópia `public.analytics_events_set_user_id()` (estava exposta via /rpc).
c) `public.spatial_ref_sys`: anon/authenticated tinham INSERT/UPDATE/DELETE via REST. Trigger `trg_block_spatial_ref_sys_writes` (+ truncate) bloqueia escritas excepto postgres/supabase_admin. Testado: DELETE como anon recusado; SRID 4326 e distâncias OK.
d) `pg_graphql` desactivado (app usa só REST/RPC). Reversível: CREATE EXTENSION pg_graphql;

Invariantes:
- Nunca actualizar user_profiles.tier a partir da app.
- Nunca recriar public.analytics_events_set_user_id().
- Não introduzir GraphQL.

Avisos do Security Advisor aceites (não tentar corrigir): spatial_ref_sys sem RLS (tabela do supabase_admin; escrita bloqueada), PostGIS no schema public (mover apagaria colunas geography/geometry), st_estimatedextent executável (grants do supabase_admin; só suporte Supabase revoga).

## 3. Git (feito)
- Commit "fix(supabase): tier trigger, analytics, spatial_ref_sys + regras Cursor e MCP readonly" com 5 ficheiros (2 migrações, 2 regras, este prompt em docs/).
- Remoto tinha 2 commits Dependabot (Site V2/package-lock.json). Integração via `git pull --rebase --autostash` + `git push`.

## 4. Pendente
### 4.1 Segurança — cada ponto numa sessão própria (plano → migração + Flutter → teste no dispositivo WWZLYDXWYXT8PV5D → commit)
P1. catch_photos com privacy='public' expõem lat, lng e location exactos a anon → contraria Ghost Mode. (PRIORIDADE ALTA)
P2. Bucket catch-photos público e sem file_size_limit / allowed_mime_types → privado + signed URLs + limites (ex.: 5 MB; image/jpeg, png, heic, webp, como community-photos). (PRIORIDADE ALTA)
P3. user_profiles legível por anon (username, tier, country).
P4. analytics_events: política analytics_events_client_insert com WITH CHECK (true) para authenticated.

### 4.2 Acções manuais do João (não são tarefa tua)
- Supabase Dashboard → Authentication → Passwords → activar "Leaked password protection".
- Cursor → Customize → MCPs: desactivar `vercel` (212 tools) enquanto o Site V2 está em pausa.
- Cursor → Customize → Plugins: desinstalar Stripe, Linear, Zapier, GitLab, Cursor SDK (não usados). Firebase só se a app o usar.
- Cursor → Settings → Agents: activar "File-Deletion Protection".
- Apagar a pasta _to_delete/ na raiz (dois .lock vazios de um commit falhado).

### 4.3 Higiene do repositório (sessão própria, depois da segurança)
- ~630 alterações por commitar: cópias de imagens ("Imagens - Cópia", "Logo Aquanautix - Cópia…"), pasta "Automação Aquanautix" (funil YouTube, outro projecto) e ficheiros marcados como modificados só por fins de linha (LF/CRLF) ou permissões.
- Objectivo: .gitignore para cópias/assets locais, decidir onde vive "Automação Aquanautix", normalizar fins de linha (.gitattributes), sem perder trabalho.

## 5. A tua tarefa (só leitura)
1. Via MCP `supabase-readonly`, confirma que a secção 2 está activa: triggers em user_profiles e spatial_ref_sys, ausência de public.analytics_events_set_user_id, pg_graphql inexistente, migrações 20260924151706 e 20260924152102 em list_migrations. Se algo não bater certo, pára e reporta.
2. Confirma com `git log --oneline -5` e `git status -sb` que o commit de 24 Set está em main e se main está sincronizado com origin/main.
3. Mapeia no código Flutter (lib/) o impacto de P1–P4:
   - P1: onde a app lê lat/lng/location de catch_photos de OUTROS utilizadores (mapa, comunidade, perfil público).
   - P2: onde usa getPublicUrl ou URLs directos do bucket catch-photos, e se comprime imagens antes do upload.
   - P3: onde lê user_profiles sem sessão iniciada (feed Ghost demo, community_public_profile.dart, etc.).
   - P4: que eventos envia e que campos uma política mais restrita poderia bloquear.
4. Higiene: agrupa as alterações de `git status --porcelain` em categorias (só fins de linha / cópias de imagens / Automação Aquanautix / outras reais) com contagens, e propõe (sem aplicar) entradas de .gitignore e um .gitattributes.
5. Resposta em PT-PT, curta: para P1–P4 → ficheiros:linhas afectados, risco de regressão, esforço (S/M/L) e ordem recomendada; depois o resumo de higiene. Sem código, sem refactors, sem novos .md.
```

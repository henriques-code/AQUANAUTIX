# Supabase — AQUANAUTIX

Backend partilhado pela app Flutter: **Auth**, **Postgres (RLS)**, **Storage** e (futuro) **Edge Functions**.

> **Projecto remoto:** `https://ycmvqokcfzxkpinvcyhk.supabase.co`  
> Chaves na raiz do repo: `.env` → injectadas em runtime via `tools/run_dev.ps1` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

---

## Estrutura desta pasta (versionada no mono-repo)

```
supabase/
├── README_setup.md          ← este ficheiro
├── config.toml              ← Supabase CLI (project_id)
├── migrations/              ← SQL idempotente — aplicar por ordem de nome
│   ├── 20260427090000_app_insights.sql
│   ├── 20260427120000_app_insights_v2.sql
│   ├── 20260503_community.sql
│   ├── 20260512000000_catch_photos.sql
│   ├── 20260512000001_catch_photos_lat_lng.sql
│   ├── 20260609000000_analytics_events.sql
│   ├── 20260610000000_security_hardening.sql
│   └── 20260611000000_storage_cleanup_profiles_social.sql
└── scripts/
    └── check_bucket.sql     ← verificar bucket catch-photos
```

**Ainda não versionadas aqui** (referenciadas em `SECURITY_DEPLOY_CHECKLIST.md` — criar ou importar do dashboard):

- `migrations/202604150001_create_function_rate_limits.sql`
- `migrations/202604150002_market_mvp_backend.sql`
- `functions/oracle/`, `functions/vision-identify/`, `functions/market-*`

---

## Tabelas e uso na app

| Migration | Tabelas / objectos | Código Flutter |
|-----------|-------------------|----------------|
| `20260427090000_app_insights.sql` | `app_insights` (jsonb por key) | legado / fallback |
| `20260427120000_app_insights_v2.sql` | `app_insights_v2` (legal, privacy, compliance, confidence) | `AppInsightsService` |
| `20260503_community.sql` | `user_profiles`, `community_posts`, `community_reactions` + RLS | `CommunityRepository`, `CommunityStore` |
| `20260512000000_catch_photos.sql` | `catch_photos` + PostGIS `location` + RLS | `CatchPhotoRepository`, `mapa.dart` |
| `20260512000001_catch_photos_lat_lng.sql` | colunas `lat`/`lng` + trigger `set_catch_location` | insert via lat/lng (PostgREST) |
| `20260609000000_analytics_events.sql` | funil / paywall / North Star | `AnalyticsService` |
| `20260610000000_security_hardening.sql` | RLS catch_photos, tier, storage, analytics | mapa, comunidade, analytics |
| `20260611000000_storage_cleanup_profiles_social.sql` | remove storage legado; perfis legíveis no feed | `CommunityRepository`, mapa |

**Storage buckets (criar no dashboard se não existirem):**

| Bucket | Uso |
|--------|-----|
| `catch-photos` | Fotos de capturas no mapa/logbook |
| `community-photos` | Feed comunidade Ghost (ver comentário na migration community) |

---

## Aplicar migrations

### Opção A — Supabase CLI (recomendado)

```powershell
# Na raiz do repo, com CLI instalada e login feito
supabase link --project-ref ycmvqokcfzxkpinvcyhk
supabase db push
```

### Opção B — SQL Editor (manual)

Dashboard → **SQL Editor** → executar **cada ficheiro** em `migrations/` **por ordem alfabética/data** (nomes já ordenados).

Todas as migrations actuais são **idempotentes** (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`).

---

## Setup catch-photos (pós-migration)

1. Executar `migrations/20260512000000_catch_photos.sql` e `20260512000001_catch_photos_lat_lng.sql`.
2. SQL Editor → colar `scripts/check_bucket.sql`.
   - **Uma linha:** bucket OK.
   - **Vazio:** Storage → New Bucket → `catch-photos`, **Public**.
3. Políticas Storage (se bucket novo):
   - **SELECT** `public` — `bucket_id = 'catch-photos'`
   - **INSERT** `authenticated` — `bucket_id = 'catch-photos'`
4. Validar: `SELECT COUNT(*) FROM catch_photos;` → `0` sem erro.

---

## Setup comunidade (pós-migration)

1. Executar `migrations/20260503_community.sql`.
2. Criar bucket `community-photos` (público) se necessário.
3. A app usa feed demo offline quando Supabase vazio (`community_demo_posts.dart`).

---

## Auth na app

- Bootstrap: `lib/core/supabase_bootstrap.dart` (`dart-define` / env).
- Login Google + email: `lib/screens/login_module.dart`.
- Redirect reset password: `SUPABASE_RESET_REDIRECT` (default `aquanautix://reset-password`).

Sem `SUPABASE_URL` + `SUPABASE_ANON_KEY` a app corre em modo offline (comunidade demo, sem sync).

---

## Verificação rápida pós-deploy

```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'app_insights', 'app_insights_v2',
    'user_profiles', 'community_posts', 'community_reactions',
    'catch_photos', 'analytics_events'
  )
ORDER BY 1;
```

Deve listar **7 tabelas** após todas as migrations aplicadas.

---

## Segurança

- **Nunca** commitar `SUPABASE_SERVICE_ROLE_KEY`.
- RLS activa em todas as tabelas de produto.
- Ghost Mode: `community_posts` só guarda `zone_label` — **nunca** lat/lng exactos na comunidade pública.

Ver também: `SECURITY_DEPLOY_CHECKLIST.md` na raiz do repo.

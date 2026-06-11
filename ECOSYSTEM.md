# AQUANAUTIX — Ecossistema de Serviços

> Documento de referência para engenharia de sistemas.
> **Auditado:** 11 Jun 2026 · alinhado com commit `da3ca79` (app) + `supabase/README_setup.md` (backend).

---

## 1. Serviços Essenciais (produto não funciona sem eles)

| Serviço | Para quê | Onde é usado | Chave / Config |
|---------|----------|--------------|----------------|
| **Vercel** | Hosting do site marketing | `Site V2/` → `aquanautix.vercel.app` | `Site V2/.vercel/` (gerado por `vercel link`) |
| **Supabase** | Auth, DB, Edge Functions, Storage | App Flutter (`supabase_flutter`) + Edge Functions | `SUPABASE_URL` + `SUPABASE_ANON_KEY` no `.env` |
| **Mapbox** | Token bootstrap (app) · mapas no site | Site (`index.html` GL JS v3.3.0) + App (`mapbox_maps_flutter` só init) | `MAPBOX_ACCESS_TOKEN` + `MAPBOX_DOWNLOAD_TOKEN` no `.env` |
| **flutter_map** | Rendering mapa na app (MIUI-safe) | App `mapa.dart` — ArcGIS/OSM/OpenSeaMap | Sem token (tiles públicos) |
| **OpenAI** | Vision Scanner (espécie/peso/legal), Assistente IA | App → Supabase Edge Function `vision-identify` | `OPENAI_API_KEY` no `.env` (nunca expor no cliente) |
| **RevenueCat** | Subscriptions PRO / ELITE | App Flutter (`purchases_flutter`) | `REVENUECAT_API_KEY_ANDROID` + `REVENUECAT_ENTITLEMENT_ID` no `.env` |
| **Supabase `analytics_events`** | Funil, paywall, North Star, D1/D7 (via params) | App (`AnalyticsService`) | Migration `20260609000000_analytics_events.sql` — RLS insert cliente, leitura equipa via dashboard/service role |

---

## 2. Serviços de Suporte

| Serviço | Para quê | Onde é usado |
|---------|----------|--------------|
| **Formspree** (`formspree.io/f/xwpkvjpb`) | Waitlist / Early Access | `Site V2/index.html` → fetch POST |
| **Google Fonts** | Orbitron, IBM Plex Sans, Share Tech Mono | `index.html` + Flutter (`google_fonts`) |
| **OpenWeather** | Previsão meteorológica | App Flutter (`OPENWEATHER_API_KEY`) |
| **Google Places** | Lojas de isco próximas | App Flutter (`GOOGLE_PLACES_API_KEY` — ainda vazia) |
| **ArcGIS / GEBCO** | Batimetria global (fallback + tiles) | `BATHYMETRY_TILES_URL` no `.env` |
| **Open-Meteo** | Marés, tempo, marine API (sem API key) | App Flutter (`lib/core/tides/`) + protótipo `app-demo.html` |
| **OpenSeaMap** | Tiles náuticos | `index.html` overlay |
| **CDN CloudFlare** | SunCalc (solunar) | `index.html` |
| **App Store / Google Play** | Lojas de app | Links em `index.html` (ainda placeholders) |

---

## 3. Backend Supabase — Estado no Repo

A pasta **`supabase/`** existe na raiz do mono-repo (versionada no Git).

```
supabase/
├── config.toml
├── README_setup.md
├── migrations/     (8 ficheiros SQL — ver tabela abaixo)
└── scripts/check_bucket.sql
```

### Migrations versionadas (aplicar por ordem)

| Ficheiro | Conteúdo | App Flutter |
|----------|----------|-------------|
| `20260427090000_app_insights.sql` | `app_insights` (jsonb) | fallback insights |
| `20260427120000_app_insights_v2.sql` | `app_insights_v2` + seed PT/ES | `AppInsightsService` |
| `20260503_community.sql` | comunidade Ghost + RLS | `CommunityRepository` |
| `20260512000000_catch_photos.sql` | `catch_photos` + PostGIS | `CatchPhotoRepository`, mapa |
| `20260512000001_catch_photos_lat_lng.sql` | trigger lat/lng → geometry | inserts PostgREST |
| `20260609000000_analytics_events.sql` | funil / paywall | `AnalyticsService` |
| `20260610000000_security_hardening.sql` | RLS catch_photos, tier, storage | mapa, comunidade |
| `20260611000000_storage_cleanup_profiles_social.sql` | storage legado; perfis feed | `CommunityRepository` |

### Pendente no repo (só referenciado em checklists)

| Item | Estado |
|------|--------|
| `202604150001_create_function_rate_limits.sql` | ❌ não versionado |
| `202604150002_market_mvp_backend.sql` | ❌ não versionado |
| Edge Functions (`oracle`, `vision-identify`, `market-*`) | ❌ pasta `supabase/functions/` ausente |

**Deploy SQL:** `supabase db push` (CLI) ou SQL Editor — ver `supabase/README_setup.md`.

**Projecto remoto:** `ycmvqokcfzxkpinvcyhk.supabase.co`

---

## 4. Variáveis de Ambiente (`.env`) — Todas as Chaves

O ficheiro `.env` está na **raiz do projecto** e é carregado pela app Flutter via `flutter_dotenv`.
Está correctamente em `.gitignore` (nunca vai para Git).

```
SUPABASE_URL              = https://ycmvqokcfzxkpinvcyhk.supabase.co
SUPABASE_ANON_KEY         = eyJ... (JWT anon)
OPENWEATHER_API_KEY       = ✅ preenchida
OPENAI_API_KEY            = ✅ preenchida (sk-proj-...)
MAPBOX_ACCESS_TOKEN       = ✅ preenchida (pk.eyJ...)
MAPBOX_DOWNLOAD_TOKEN     = ✅ preenchida (pk.eyJ...)
BATHYMETRY_TILES_URL      = ✅ ArcGIS/GEBCO configurado
REVENUECAT_API_KEY_ANDROID= ✅ preenchida
REVENUECAT_ENTITLEMENT_ID = pro
GOOGLE_PLACES_API_KEY     = ⚠️ VAZIA — lojas de isco não funcionam
AFFILIATE_ID              = ⚠️ VAZIA — afiliados não activos
```

> O Token Mapbox no **site** (`index.html` linha ~3447) está embutido no JS —
> restringe-o no dashboard Mapbox a `aquanautix.vercel.app` para evitar uso indevido.

---

## 5. Assets — Inventário e Classificação Oficial

### `Site V2/images/` — 23 ficheiros, todos não-vazios

| Grupo | Ficheiros | Uso | Manter? |
|-------|-----------|-----|---------|
| **Protótipo visual oficial (5 ecrãs)** | `screen_1_oraculo.png` … `screen_5_perfil.png` | Referência Site + App | ✅ SIM |
| **Arte de monetização / secções site** | `1_planos.png`, `2_oraculo.png`, `3_alertas.png`, `4_spots.png`, `5_afiliacao.png` | Marketing / `monetization-prototype.html` | ✅ SIM |
| **Thumbnails app (alta resolução)** | `app_1_oraculo.png` … `app_5_perfil.png` | Mockups detalhados | ✅ SIM |
| **Thumbnails app (baixa resolução)** | `app_s1_oraculo.png` … `app_s5_perfil.png` | Export alternativo / screenshots | ⚠️ ver nota |
| **Composites** | `app_overview.png`, `app_5screens_full.png` | Hashes SHA256 diferentes → não são duplicados | ✅ SIM |
| **Hero subaquático** | `underwater_hero.png` (~1,3 MB) | `monetization-prototype.html` background | ✅ SIM |

#### ⚠️ Duplicado real encontrado (hash idêntico):
```
app_s2_mapa.png   == app_s3_vision.png  (SHA256: 841F0B03...)
```
Ambos com 15,5 KB e hash igual — **ficheiros byte-a-byte iguais**.
Um deles pode ser eliminado; confirma qual série é a correcta antes de apagar.

### `assets/` (Flutter) — inventário Jun 2026

| Caminho | Uso |
|---------|-----|
| `assets/video_bg.mp4` | Splash / login (vídeo hero) |
| `assets/marketing/spots/` | Cabo Espichel (`cabo_da_roca.jpg`), Peniche, Sesimbra — Início + Mapa |
| `assets/marketing/catches/` | dourada, robalo, sargo — Início + Comunidade demo |
| `assets/data/species_ibero.json` | Compliance espécies PT/ES |
| `assets/icons/fish_silhouette.svg` | UI |

> `assets/images/login_bg.jpg` — **eliminado** (stub corrompido); fallback = gradiente Midnight Deep Sea.

---

## 6. App Flutter — Navegação e módulos (Jun 2026)

| Tab | Índice | Ecrã | Notas |
|-----|--------|------|-------|
| Início | 0 | `inicio_dashboard_screen.dart` | GPS pull-to-refresh · spots→mapa · comunidade→tab 6 |
| Oráculo | 1 | `oraculo.dart` | Open-Meteo · Nominatim · CTAs Comunidade (tab 6) |
| Mapa | 2 | `mapa.dart` | `flutter_map` · pendingMapFocus |
| Vision | 3 | `vision.dart` | OpenAI directo (roadmap Edge Function) |
| Log | 4 | `logbook.dart` | Capturas + sub-tab COMUNIDADE legado |
| Perfil | 5 | `perfil.dart` | Planos · logout reset GPS |
| **Comunidade** | **6** | `comunidade.dart` | Feed Ghost · sheet perfil · demo offline |

**GPS:** `gps_access.dart` + `gps_bootstrap.dart` — partilhado Início/Oráculo/Mapa.

---

## 7. Acoplamentos conhecidos

| Problema | Impacto | Acção |
|----------|---------|-------|
| Site V2 protótipos (`app-5screens.html`) ainda 5/6 ecrãs | Marketing desalinhado com app 7 tabs | Actualizar só com AUTORIZO design |
| Token Mapbox em `index.html` | Risco se sem restrição domínio | Restringir a `aquanautix.vercel.app` |
| Migrations rate limits + Edge Functions ausentes | Checklist segurança incompleto | Versionar ou documentar no dashboard |
| Supabase remoto vs repo | Feed real Comunidade | Correr `supabase db push` |
| RevenueCat parcial | Gates PRO/ELITE | Ver `REVENUECAT_SETUP.md` |

---

## 8. RevenueCat — Passos Manuais no Dashboard

URL: https://app.revenuecat.com

### 7a. Produtos a criar (Google Play / App Store)

| Produto | Tipo | ID sugerido | Preço |
|---------|------|-------------|-------|
| PRO mensal | Subscrição | `aquanautix_pro_monthly` | €7.99/mês |
| PRO anual | Subscrição | `aquanautix_pro_yearly` | €59/ano |
| ELITE anual | Subscrição | `aquanautix_elite_yearly` | €79/ano |

### 7b. Entitlements

Criar entitlement com ID: **`pro`** (já configurado no `.env`)
- Associar produtos PRO mensal + anual ao entitlement `pro`

### 7c. Offerings

Criar offering `default` com os packages:
- `$rc_monthly` → aquanautix_pro_monthly
- `$rc_annual` → aquanautix_pro_yearly

### 7d. API Keys

| Plataforma | Variável .env | Onde obter |
|------------|---------------|------------|
| Android | `REVENUECAT_API_KEY_ANDROID` ✅ já preenchida | Dashboard → Apps → Android → API Key |
| iOS | `REVENUECAT_API_KEY_IOS` ⚠️ vazia | Dashboard → Apps → iOS → API Key |

### 7e. Testar antes de lançar

1. No `.env`, manter `FORCE_PRO_ENTITLEMENT=true` (debug, PRO grátis para testar UI)
2. Ao submeter para lojas: `FORCE_PRO_ENTITLEMENT=false` (ou remover a linha)
3. Usar "Sandbox" da Google Play / TestFlight para testar compras reais sem custo

---

## 9. Fluxo de Deploy

```
App Flutter:  .\tools\run_dev.ps1  ·  flutter build apk
Site:         editar Site V2/ → vercel --prod (só Site V2/)
Supabase:     supabase link && supabase db push
Git:          main → origin/main (GitHub: henriques-code/AQUANAUTIX)
```

### Matriz de sincronização (11 Jun 2026)

| Artefacto | Versão / estado | Sincronizado? |
|-----------|-----------------|---------------|
| `lib/` (app) | `da3ca79` | ✅ GitHub |
| Docs (CONTEXT, CLAUDE, HANDOFF, README, ECOSYSTEM) | 11 Jun 2026 | ✅ Repo |
| Site V2 produção | último deploy Vercel (sem alterações recentes) | ⏸️ Estável |
| Protótipos HTML | 5–6 ecrãs | ⚠️ Desalinhados (intencional) |
| Supabase remoto | 8 migrations aplicadas (`db push` 11 Jun) | ✅ Sincronizado |
| Edge Functions | — | ❌ Pendente |
| Play Store / App Store | debug builds | ❌ Não publicado |

---

## 10. Próximas Acções Prioritárias

1. 🟡 **`supabase db push`** — garantir remoto = repo (8 migrations).
2. 🟡 **RevenueCat** — produtos + gates (`REVENUECAT_SETUP.md`).
3. 🟡 **Edge Functions** — versionar `vision-identify`, `oracle` no repo.
4. 🟢 **Restringir token Mapbox** no dashboard a `aquanautix.vercel.app`.
5. 🟢 **Preencher** `GOOGLE_PLACES_API_KEY` (lojas de isco).
6. 🟢 **Sprint C** — assets spots (`cabo_espichel.jpg`), manifest JSON.
